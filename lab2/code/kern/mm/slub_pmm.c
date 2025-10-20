#include <pmm.h>
#include <list.h>
#include <string.h>
#include <slub_pmm.h>
#include <stdio.h>

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
    list_entry_t list;      // 用于将slab挂到empty/partial/full链表
    void *free_list;        // 指向slab中空闲对象的单链表头
    size_t free_count;      // 当前slab中空闲对象数量
    struct Page *page;      // 该slab对应的物理页
} slub_slab_t;

// slab缓存结构体，描述一种对象大小的slab管理
typedef struct slub_cache {
    size_t obj_size;            // 单个对象的大小
    size_t objs_per_slab;       // 一个slab页可容纳多少个对象
    list_entry_t slabs_empty;   // 全空slab链表（所有对象空闲）
    list_entry_t slabs_partial; // 部分空闲slab链表（有空闲对象可分配）
    list_entry_t slabs_full;    // 已满slab链表（无空闲对象）
} slub_cache_t;

// 全局只实现一个slub_cache（只支持一种对象大小）
static slub_cache_t global_slub_cache;

// 辅助宏：通过链表节点指针le和成员名member，获得slub_slab_t结构体指针
#define le2slub_slab(le, member) \
    ((slub_slab_t *)((char *)(le) - offsetof(slub_slab_t, member)))

// 辅助：检查链表 head 中是否包含节点 node
static int list_contains(list_entry_t *head, list_entry_t *node) {
    list_entry_t *le = head;
    while ((le = list_next(le)) != head) {
        if (le == node) return 1;
    }
    return 0;
}

static void slub_obj_init(size_t obj_size) {
    assert(obj_size >= sizeof(void*)); // 必须能存放 next 指针
    global_slub_cache.obj_size = obj_size;

    // 为 slab 头部保留空间，并按 obj_size 对齐
    size_t header_size = ROUNDUP(sizeof(slub_slab_t), obj_size);
    if (header_size >= PGSIZE) {
        panic("slub: header too large for page");
    }
    global_slub_cache.objs_per_slab = (PGSIZE - header_size) / obj_size;
    assert(global_slub_cache.objs_per_slab > 0);

    // 初始化三条链表：全空 / 部分 / 已满
    list_init(&(global_slub_cache.slabs_empty));
    list_init(&(global_slub_cache.slabs_partial));
    list_init(&(global_slub_cache.slabs_full));
}

// slab页初始化：将一页切分为多个对象，建立空闲对象链表
static void slub_slab_init(slub_cache_t *cache, slub_slab_t *slab, struct Page *page) {
    slab->page = page;
    slab->free_count = cache->objs_per_slab;
    slab->free_list = NULL;
    list_init(&slab->list); // 初始化 slab 的链表节点

    // 对象区从页头之后开始，跳过 slab 头部（并按 obj_size 对齐）
    size_t header_size = ROUNDUP(sizeof(slub_slab_t), cache->obj_size);
    void *page_addr = (void *)((char *)page2kva(page) + header_size);

    for (size_t i = 0; i < cache->objs_per_slab; i++) {
        void *obj = (char *)page_addr + i * cache->obj_size;
        *(void **)obj = slab->free_list; // obj->next = old_head
        slab->free_list = obj;           // head = obj
    }

    // 新 slab 初始为“全空”，挂到 slabs_empty
    list_add(&cache->slabs_empty, &slab->list);
}

// 分配一个对象（优先 partial -> empty -> 申请新页）
void *slub_obj_alloc(void) {
    slub_slab_t *slab = NULL;
    slub_cache_t *cache = &global_slub_cache;
    if (!list_empty(&(cache->slabs_partial))) {
        // 从 partial 取
        slab = le2slub_slab(list_next(&(cache->slabs_partial)), list);
        list_del(&slab->list);
    } else if (!list_empty(&(cache->slabs_empty))) {
        // 从 empty 取
        slab = le2slub_slab(list_next(&(cache->slabs_empty)), list);
        list_del(&slab->list);
    } else {
        // 没有 slab，分配新页并初始化为 slab（会加入 empty），再取出
        struct Page *page = slub_alloc_pages(1);
        if (page == NULL) return NULL; // 分配失败
        slab = (slub_slab_t *)page2kva(page);
        slub_slab_init(cache, slab, page);    // 初始化slab（已加入 empty）
        // 从 empty 中取出
        list_del(&slab->list);
    }

    // 取对象
    void *obj = slab->free_list;
    slab->free_list = *(void **)obj;
    slab->free_count--;
    // 挂回 partial 或 full
    if (slab->free_count == 0) {
        list_add(&(cache->slabs_full), &(slab->list));
    } else {
        list_add(&(cache->slabs_partial), &(slab->list));
    }
    return obj;
}

// 释放一个对象（将全空 slab 挂回 slabs_empty，但不立即回收页面）
// 页面回收在 check 中统一处理，以便观察三链表变化
void slub_obj_free(void *obj) {
    // 先找到该对象所在的物理页和slab头
    struct Page *page = kva2page((void *)((uintptr_t)obj & ~(PGSIZE - 1)));
    slub_slab_t *slab = (slub_slab_t *)page2kva(page);
    slub_cache_t *cache = &global_slub_cache;

    // 头插法回收到slab的空闲对象链表
    *(void **)obj = slab->free_list;
    slab->free_list = obj;
    slab->free_count++;

    // 如果当前 slab 在任意链表中，先移除
    if (list_contains(&cache->slabs_partial, &slab->list) ||
        list_contains(&cache->slabs_full, &slab->list) ||
        list_contains(&cache->slabs_empty, &slab->list)) {
        list_del(&slab->list);
    }

    // 更新链表位置：full -> partial；partial -> empty（暂不回收页）
    if (slab->free_count == 1) {
        // 原来是 full，现在回到 partial
        list_add(&(cache->slabs_partial), &(slab->list));
    } else if (slab->free_count == cache->objs_per_slab) {
        // 全空：挂到 empty（不立即回收页，这样 check 能看到 slabs_empty）
        list_add(&(cache->slabs_empty), &(slab->list));
    } else {
        // 部分空闲，挂回 partial
        list_add(&(cache->slabs_partial), &(slab->list));
    }
}

// 查询当前空闲对象数（统计 partial + empty）
size_t slub_obj_nr_free(void) {
    size_t total = 0;
    slub_cache_t *cache = &global_slub_cache;
    if (!cache) return 0;
    list_entry_t *le;

    le = &cache->slabs_partial;
    while ((le = list_next(le)) != &cache->slabs_partial) {
        slub_slab_t *slab = le2slub_slab(le, list);
        total += slab->free_count;
    }
    le = &cache->slabs_empty;
    while ((le = list_next(le)) != &cache->slabs_empty) {
        slub_slab_t *slab = le2slub_slab(le, list);
        total += slab->free_count; // 全空 slab 的 free_count = objs_per_slab
    }
    return total;
}

// 打印三条链表（供 check 使用）
static void slub_dump_lists(const char *tag) {
    slub_cache_t *cache = &global_slub_cache;
    cprintf("=== SLUB DUMP: %s (obj_size=%lu, objs_per_slab=%lu) ===\n",
            tag, (unsigned long)cache->obj_size, (unsigned long)cache->objs_per_slab);
    list_entry_t *le;

    cprintf(" EMPTY:\n");
    le = &cache->slabs_empty;
    while ((le = list_next(le)) != &cache->slabs_empty) {
        slub_slab_t *s = le2slub_slab(le, list);
        cprintf("   slab kva=%p free_count=%d page=%p\n", s, (int)s->free_count, (void *)s->page);
    }

    cprintf(" PARTIAL:\n");
    le = &cache->slabs_partial;
    while ((le = list_next(le)) != &cache->slabs_partial) {
        slub_slab_t *s = le2slub_slab(le, list);
        cprintf("   slab kva=%p free_count=%d page=%p\n", s, (int)s->free_count, (void *)s->page);
    }

    cprintf(" FULL:\n");
    le = &cache->slabs_full;
    while ((le = list_next(le)) != &cache->slabs_full) {
        slub_slab_t *s = le2slub_slab(le, list);
        cprintf("   slab kva=%p free_count=%d page=%p\n", s, (int)s->free_count, (void *)s->page);
    }
    cprintf("=== END SLUB DUMP ===\n");
}

static void slub_check(void) {

    cprintf("==== SLUB OBJ CHECK BEGIN ====\n");
    slub_obj_init(1024); // 初始化对象大小为1024字节

    slub_dump_lists("after init");

    void *objs[8];
    for (int i = 0; i < 8; i++) {
        objs[i] = slub_obj_alloc();
        cprintf("slub_obj_alloc[%d]=%p\n", i, objs[i]);
        slub_dump_lists("after alloc");
        assert(objs[i] != NULL);
    }

    // 记录归还前空闲页数
    size_t pages_before = slub_nr_free_pages();

    cprintf("before free 8 objs, free obj count=%d\n", (int)slub_obj_nr_free());
    slub_dump_lists("before free");
    
    for (int i = 0; i < 8; i++) {
        slub_obj_free(objs[i]);
        cprintf("when free %dth obj, free obj count=%d\n", i, (int)slub_obj_nr_free());
        slub_dump_lists("after free step");
    }
    cprintf("after free 8 objs, free obj count=%d\n", (int)slub_obj_nr_free());
    slub_dump_lists("after all free");

    // 现在回收所有 slabs_empty 对应的页，以恢复原来测试对页回收的期望
    slub_cache_t *cache = &global_slub_cache;
    while (!list_empty(&cache->slabs_empty)) {
        slub_slab_t *s = le2slub_slab(list_next(&cache->slabs_empty), list);
        list_del(&s->list);
        slub_free_pages(s->page, 1);
    }

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