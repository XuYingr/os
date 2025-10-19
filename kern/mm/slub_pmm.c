#include <pmm.h>
#include <list.h>
#include <string.h>
#include <slub_pmm.h>
#include <stdio.h>
#include <assert.h>
#include <memlayout.h>

// ========== 第一层：页分配器 ==========

typedef struct slub_free_area {
    list_entry_t free_list;
    size_t nr_free;
} slub_free_area_t;

static slub_free_area_t slub_free_area;

#define slub_free_area_list (slub_free_area.free_list)
#define slub_free_area_nr   (slub_free_area.nr_free)

static void slub_init(void) {
    list_init(&slub_free_area_list);
    slub_free_area_nr = 0;
}

static void slub_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    slub_free_area_nr += n;
    if (list_empty(&slub_free_area_list)) {
        list_add(&slub_free_area_list, &(base->page_link));
    } else {
        list_entry_t* le = &slub_free_area_list;
        while ((le = list_next(le)) != &slub_free_area_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &slub_free_area_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
}

static struct Page *slub_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > slub_free_area_nr) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &slub_free_area_list;
    while ((le = list_next(le)) != &slub_free_area_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        slub_free_area_nr -= n;
        ClearPageProperty(page);
    }
    return page;
}

static void slub_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    slub_free_area_nr += n;

    if (list_empty(&slub_free_area_list)) {
        list_add(&slub_free_area_list, &(base->page_link));
    } else {
        list_entry_t* le = &slub_free_area_list;
        while ((le = list_next(le)) != &slub_free_area_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &slub_free_area_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &slub_free_area_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }

    le = list_next(&(base->page_link));
    if (le != &slub_free_area_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}

static size_t slub_nr_free_pages(void) {
    return slub_free_area_nr;
}

// ========== 第二层：对象分配器 ==========

// slab结构体，代表一个slab页（通常是一页，切分成多个对象）
typedef struct slub_slab {
    list_entry_t list;      // 用于将slab挂到partial/full链表
    void *free_list;        // 指向slab中空闲对象的单链表头
    size_t free_count;      // 当前slab中空闲对象数量
    struct Page *page;      // 该slab对应的物理页
} slub_slab_t;

// slab缓存结构体，描述一种对象大小的slab管理
typedef struct slub_cache {
    size_t obj_size;            // 单个对象的大小
    size_t objs_per_slab;       // 一个slab页可容纳多少个对象
    list_entry_t slabs_partial; // 部分空闲slab链表（有空闲对象可分配）
    list_entry_t slabs_full;    // 已满slab链表（无空闲对象）
} slub_cache_t;

// 全局只实现一个slub_cache（只支持一种对象大小）
static slub_cache_t global_slub_cache;

// 辅助宏：通过链表节点指针le和成员名member，获得slub_slab_t结构体指针
#define le2slub_slab(le, member) \
    ((slub_slab_t *)((char *)(le) - offsetof(slub_slab_t, member)))

// 初始化slub对象分配器
static void slub_obj_init(size_t obj_size) {
    global_slub_cache.obj_size = obj_size;                 // 设置对象大小
    global_slub_cache.objs_per_slab = PGSIZE / obj_size;   // 计算每页可容纳对象数
    list_init(&(global_slub_cache.slabs_partial));         // 初始化部分空闲slab链表
    list_init(&(global_slub_cache.slabs_full));            // 初始化已满slab链表
}

// slab页初始化：将一页切分为多个对象，建立空闲对象链表
static void slub_slab_init(slub_cache_t *cache, slub_slab_t *slab, struct Page *page) {
    slab->page = page;                         // 记录物理页
    slab->free_count = cache->objs_per_slab;   // 初始空闲对象数=总对象数
    slab->free_list = NULL;                    // 空闲链表头置空
    void *page_addr = (void *)page2kva(page);  // 获得该页的虚拟地址
    for (size_t i = 0; i < cache->objs_per_slab; i++) {
        void *obj = (char *)page_addr + i * cache->obj_size; // 计算每个对象的地址
        *(void **)obj = slab->free_list;                     // 单链表头插法
        slab->free_list = obj;                               // 更新链表头
    }
}

// 分配一个对象
void *slub_obj_alloc(void) {
    slub_slab_t *slab = NULL;
    slub_cache_t *cache = &global_slub_cache;
    if (!list_empty(&(cache->slabs_partial))) {
        // 如果有部分空闲slab，从第一个slab分配
        slab = le2slub_slab(list_next(&(cache->slabs_partial)), list);
    } else {
        // 没有空闲slab，分配新页并初始化为slab
        struct Page *page = slub_alloc_pages(1);
        if (page == NULL) return NULL; // 分配失败
        slab = (slub_slab_t *)page2kva(page); // slab头部放在页头
        slub_slab_init(cache, slab, page);    // 初始化slab
        list_add(&(cache->slabs_partial), &(slab->list)); // 加入partial链表
    }
    void *obj = slab->free_list;              // 取出链表头对象
    slab->free_list = *(void **)obj;          // 链表头后移
    slab->free_count--;                       // 空闲数减一
    if (slab->free_count == 0) {
        // 如果slab已满，从partial链表移到full链表
        list_del(&(slab->list));
        list_add(&(cache->slabs_full), &(slab->list));
    }
    return obj;                               // 返回分配到的对象
}

// 释放一个对象
void slub_obj_free(void *obj) {
    // 先找到该对象所在的物理页和slab头
    struct Page *page = kva2page((void *)((uintptr_t)obj & ~(PGSIZE - 1)));
    slub_slab_t *slab = (slub_slab_t *)page2kva(page);
    // 头插法回收到slab的空闲对象链表
    *(void **)obj = slab->free_list;
    slab->free_list = obj;
    slab->free_count++;
    if (slab->free_count == 1) {
        // 如果原来是full，现在有空闲对象了，移回partial链表
        list_del(&(slab->list));
        list_add(&(global_slub_cache.slabs_partial), &(slab->list));
    }
    // 如果slab全部空闲，归还物理页
    if (slab->free_count == global_slub_cache.objs_per_slab) {
        list_del(&(slab->list));
        slub_free_pages(page, 1);
    }
}

// 查询当前空闲对象数（只统计partial链表）
size_t slub_obj_nr_free(void) {
    size_t total = 0;
    slub_cache_t *cache = &global_slub_cache;
    list_entry_t *le = &(cache->slabs_partial);
    while ((le = list_next(le)) != &(cache->slabs_partial)) {
        slub_slab_t *slab = le2slub_slab(le, list);
        total += slab->free_count;
    }
    return total;
}

static void slub_check(void) {

    cprintf("==== SLUB OBJ CHECK BEGIN ====\n");
    slub_obj_init(32); // 初始化对象大小为32字节

    void *objs[8];
    for (int i = 0; i < 8; i++) {
        objs[i] = slub_obj_alloc();
        cprintf("slub_obj_alloc[%d]=%p\n", i, objs[i]);
        assert(objs[i] != NULL);
    }

    // 记录归还前空闲页数
    size_t pages_before = slub_nr_free_pages();

    cprintf("before free 8 objs, free obj count=%d\n", (int)slub_obj_nr_free());
    
    for (int i = 0; i < 8; i++) {
        slub_obj_free(objs[i]);
        cprintf("when free 8 objs, free obj count=%d\n", (int)slub_obj_nr_free());
    }
    cprintf("after free 8 objs, free obj count=%d\n", (int)slub_obj_nr_free());
    // assert(slub_obj_nr_free() >= 8);
    assert(slub_obj_nr_free() == 0); // slab已被释放，空闲对象数应为0
    
    // 检查物理页是否归还
    size_t pages_after = slub_nr_free_pages();
    cprintf("pages before=%d, pages after=%d\n", (int)pages_before, (int)pages_after);
    assert(pages_after > pages_before);
    
    cprintf("==== SLUB OBJ CHECK END ====\n");
}

// ========== SLUB分配器管理结构体 ==========
const struct pmm_manager slub_pmm_manager = {
    .name = "slub_pmm_manager",
    .init = slub_init,
    .init_memmap = slub_init_memmap,
    .alloc_pages = slub_alloc_pages,
    .free_pages = slub_free_pages,
    .nr_free_pages = slub_nr_free_pages,
    .check = slub_check,
};