#include <buddy_pmm.h>
#include <pmm.h>
#include <list.h>
#include <assert.h>
#include <string.h>
#include <stdio.h>

// 全局变量
static struct buddy* buddy_system = NULL;
static struct Page* buddy_page_base = NULL;
static size_t total_blocks = 0;
static size_t total_pages = 0;
static size_t buddy_struct_pages = 0;

// 初始化buddy system
struct buddy* buddy_new(void* addr, unsigned blocks) {
    if (!addr || blocks < 1 || !is_pow_of_2(blocks))
        return NULL;

    struct buddy* self = (struct buddy*)addr;
    self->size = blocks;
    
    // 初始化二叉树
    unsigned node_size = blocks;
    for (int i = 0; i < 2 * blocks - 1; ++i) {
        if (i == 0) {
            // 根节点
            self->longest[i] = blocks;
        } else {
            if (is_pow_of_2(i + 1))
                node_size /= 2;
            self->longest[i] = node_size;
        }
    }
    
    return self;
}

void buddy_destroy(struct buddy* self) {
    // 静态分配，不需要释放
}

int buddy_alloc(struct buddy* self, unsigned required_blocks) {
    if (!self || required_blocks == 0) {
        return -1;
    }
    
    // 调整到最近的2的幂
    if (!is_pow_of_2(required_blocks)) {
        unsigned old_blocks = required_blocks;
        required_blocks = next_pow_of_2(required_blocks);
    }
    
    cprintf("buddy_alloc: starting allocation for %u blocks\n", required_blocks);
    cprintf("buddy_alloc: root node has %u free blocks\n", self->longest[0]);
    
    if (self->longest[0] < required_blocks) {
        cprintf("buddy_alloc: insufficient memory! root has %u, need %u\n", 
                self->longest[0], required_blocks);
        return -1;
    }
    
    unsigned idx = 0;
    unsigned node_size = self->size;
    unsigned depth = 0;
    
    cprintf("buddy_alloc: starting search from root (idx=0, size=%u)\n", node_size);
    
    // 寻找合适的节点
    for (; node_size != required_blocks; node_size /= 2) {
        depth++;
        unsigned left_idx = left_leaf(idx);
        unsigned right_idx = right_leaf(idx);
        unsigned left_free = self->longest[left_idx];
        unsigned right_free = self->longest[right_idx];
        
        cprintf("buddy_alloc: depth=%u, current node idx=%u, size=%u\n", 
                depth, idx, node_size);
        cprintf("buddy_alloc:   left child idx=%u, free=%u\n", left_idx, left_free);
        cprintf("buddy_alloc:   right child idx=%u, free=%u\n", right_idx, right_free);
        
        if (left_free >= required_blocks) {
            idx = left_idx;
            cprintf("buddy_alloc:   -> choosing LEFT child (idx=%u)\n", idx);
        } else {
            idx = right_idx;
            cprintf("buddy_alloc:   -> choosing RIGHT child (idx=%u)\n", idx);
        }
    }
    
    cprintf("buddy_alloc: found target node! idx=%u, size=%u\n", idx, node_size);
    
    // 分配节点
    self->longest[idx] = 0;
    int block_offset = (idx + 1) * node_size - self->size;
    
    cprintf("buddy_alloc: allocated node idx=%u, block_offset=%d\n", idx, block_offset);
    cprintf("buddy_alloc: updating parent nodes...\n");
    
    // 更新父节点
    unsigned update_idx = idx;
    while (update_idx > 0) {
        unsigned parent_idx = parent(update_idx);
        unsigned left = self->longest[left_leaf(parent_idx)];
        unsigned right = self->longest[right_leaf(parent_idx)];
        unsigned new_value = max(left, right);
        
        cprintf("buddy_alloc:   parent idx=%u, left=%u, right=%u, new_value=%u\n", 
                parent_idx, left, right, new_value);
        
        self->longest[parent_idx] = new_value;
        update_idx = parent_idx;
    }
    
    cprintf("buddy_alloc: allocation completed! block_offset=%d\n", block_offset);
    return block_offset;
}

// 修改后的buddy_free函数
void buddy_free(struct buddy* self, int block_offset, unsigned block_size) {
    if (!self || block_offset < 0 || block_offset >= (int)self->size) {
        return;
    }
    
    cprintf("buddy_free: starting free process for offset=%d, size=%u\n", 
            block_offset, block_size);
    
    // 找到要释放的节点
    unsigned idx = 0;
    unsigned node_size = self->size;
    int offset = block_offset;
    unsigned depth = 0;
    
    cprintf("buddy_free: searching for target node from root (idx=0, size=%u)\n", node_size);
    
    // 从根节点向下，找到对应的节点
    while (node_size != block_size) {
        depth++;
        node_size /= 2;
        cprintf("buddy_free: depth=%u, current node idx=%u, size=%u, offset=%d\n", 
                depth, idx, node_size, offset);
        
        if (offset < node_size) {
            idx = left_leaf(idx);
            cprintf("buddy_free:   -> going LEFT (idx=%u), offset remains %d\n", idx, offset);
        } else {
            idx = right_leaf(idx);
            offset -= node_size;
            cprintf("buddy_free:   -> going RIGHT (idx=%u), new offset=%d\n", idx, offset);
        }
    }
    
    cprintf("buddy_free: found target node! idx=%u, size=%u\n", idx, node_size);
    
    // 释放该节点
    self->longest[idx] = node_size;
    cprintf("buddy_free: set node idx=%u to free (size=%u)\n", idx, node_size);
    
    // 合并伙伴块
    cprintf("buddy_free: starting buddy merging process...\n");
    
    unsigned merge_idx = idx;
    unsigned merge_size = node_size;
    
    while (merge_idx > 0) {
        unsigned parent_idx = parent(merge_idx);
        merge_size *= 2;
        
        unsigned left_idx = left_leaf(parent_idx);
        unsigned right_idx = right_leaf(parent_idx);
        unsigned left_free = self->longest[left_idx];
        unsigned right_free = self->longest[right_idx];
        
        cprintf("buddy_free:   parent idx=%u, size=%u\n", parent_idx, merge_size);
        cprintf("buddy_free:     left child idx=%u, free=%u\n", left_idx, left_free);
        cprintf("buddy_free:     right child idx=%u, free=%u\n", right_idx, right_free);
        
        if (left_free + right_free == merge_size) {
            // 可以合并
            self->longest[parent_idx] = merge_size;
            cprintf("buddy_free:     -> MERGED! parent set to %u\n", merge_size);
        } else {
            // 不能合并，取最大值
            unsigned new_value = max(left_free, right_free);
            self->longest[parent_idx] = new_value;
            cprintf("buddy_free:     -> NOT merged, parent set to %u\n", new_value);
        }
        
        merge_idx = parent_idx;
    }
    
    cprintf("buddy_free: free process completed! root now has %u free blocks\n", 
            self->longest[0]);
}

unsigned nr_free_blocks(struct buddy* self) {
    return self ? self->longest[0] : 0;
}

// pmm接口实现
static void buddy_init(void) {
    // 空实现，初始化在init_memmap中完成
}

static void buddy_init_memmap(struct Page* base, size_t n) {
    assert(n > 0);
    
    // 计算可管理的总页数，调整为2的幂
    total_pages = 1;
    while (total_pages * 2 <= n) {
        total_pages *= 2;
    }
    
    // 计算总块数（1块 = 1页）
    total_blocks = total_pages;
    
    cprintf("buddy: initializing with %lu pages (%lu MB)\n", 
            total_pages, total_pages * PGSIZE / 1024 / 1024);
    
    // 计算buddy结构体需要的内存
    size_t buddy_struct_size = BUDDY_STRUCT_SIZE(total_blocks);
    buddy_struct_pages = (buddy_struct_size + PGSIZE - 1) / PGSIZE;
    
    cprintf("buddy: structure needs %lu bytes (%lu pages)\n", 
            buddy_struct_size, buddy_struct_pages);

    // 验证不会超出可用内存
    if (buddy_struct_pages >= total_pages) {
        panic("buddy: structure too large for available memory\n");
    }

    // 计算实际可管理的页数（减去buddy结构体占用的页）
    size_t available_pages = total_pages - buddy_struct_pages;
    
    // 将available_pages调整为2的幂（因为buddy系统需要2的幂）
    size_t managed_pages = 1;
    while (managed_pages * 2 <= available_pages) {
        managed_pages *= 2;
    }
    
    total_blocks = managed_pages;
    
    // 初始化所有页面
    struct Page* p = base;
    for (; p != base + total_pages; p++) {
        assert(PageReserved(p));  // 检查页面确实是保留的
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
    }

    // 从内存开始处分配buddy结构体
    buddy_system = (struct buddy*)base;
    buddy_new(buddy_system, total_blocks);

    // 记录实际可分配内存的起始位置
    buddy_page_base = base + buddy_struct_pages;
    cprintf("buddy: start of allocatable pages at %p\n", buddy_page_base);
    
    // 记录实际可分配内存的起始位置
    buddy_page_base = base + buddy_struct_pages;
    
    cprintf("buddy: base=%p, buddy_page_base=%p\n", base, buddy_page_base);
    cprintf("buddy: total_blocks=%lu, memory initialization completed\n", total_blocks);
}

static struct Page* buddy_alloc_pages(size_t n) {
    if (!buddy_system || n == 0) return NULL;
    
    // 计算需要的块数（1页 = 1块）
    size_t required_blocks = PAGES_TO_BLOCKS(n);
    
    cprintf("buddy_alloc: requesting %lu pages (%lu blocks)\n", n, required_blocks);
    
    int block_offset = buddy_alloc(buddy_system, required_blocks);
    if (block_offset < 0) {
        cprintf("buddy_alloc: failed to allocate %lu blocks\n", required_blocks);
        return NULL;
    }
    
    // 计算对应的Page结构体
    // block_offset是块索引，对应页索引（需要跳过buddy结构体占用的页）
    struct Page* page = &buddy_page_base[block_offset];
    
    // 第一页设置property字段记录分配的页数
    page->property = n;
    SetPageProperty(page);
    
    cprintf("buddy_alloc: allocated %lu pages at block offset %d\n", n, block_offset);
    return page;
}

static void buddy_free_pages(struct Page* base, size_t n) {
    if (!buddy_system || !base || n == 0) return;
    
    // 计算块偏移（相对于可分配内存起始位置）
    size_t block_offset = base - buddy_page_base;
    size_t block_size = PAGES_TO_BLOCKS(n);

    cprintf("buddy_free: freeing %lu pages at block offset %lu\n", n, block_offset);
    
    // 验证传入的页面信息
    if (base->property != n) {
        cprintf("warning: base->property (%u) != n (%lu)\n", base->property, n);
    }
    
    // 恢复页面属性 - 设置保留状态，表示页面回到内核管理
    struct Page* p = base;
    for (; p != base + n; p++) {
        set_page_ref(p, 0);
        p->flags = 0;
    }
    
    // 第一页清除property标志
    ClearPageProperty(base);
    
    // 释放到buddy系统 - 这才是真正释放内存的操作
    buddy_free(buddy_system, block_offset, block_size);
}

static size_t buddy_nr_free_pages(void) {
    if (!buddy_system) return 0;
    unsigned free_blocks = nr_free_blocks(buddy_system);
    // 转换为页数（1块 = 1页）
    return free_blocks;
}

// 测试函数
// static void buddy_check(void) {
//     cprintf("\n=== Buddy System Check ===\n");
    
//     size_t initial_free = buddy_nr_free_pages();
//     cprintf("Initial free pages: %lu\n", initial_free);
    
//     // 测试分配单个页
//     struct Page* p0 = buddy_alloc_pages(1);
//     assert(p0 != NULL);
//     cprintf("single page allocation: %p\n", p0);
    
//     // 测试分配多个页
//     struct Page* p1 = buddy_alloc_pages(2);
//     assert(p1 != NULL);
//     cprintf("2 pages allocation: %p\n", p1);
    
//     struct Page* p2 = buddy_alloc_pages(4);
//     assert(p2 != NULL);
//     cprintf("4 pages allocation: %p\n", p2);
    
//     size_t after_alloc = buddy_nr_free_pages();
//     cprintf("Free pages after allocation: %lu\n", after_alloc);
    
//     // 验证页面属性
//     assert(p0->property == 1);
//     assert(p1->property == 2);
//     assert(p2->property == 4);
//     assert(PageProperty(p0));
//     assert(PageProperty(p1));
//     assert(PageProperty(p2));
    
//     // 测试释放
//     buddy_free_pages(p0, 1);
//     cprintf("freed 1 page\n");
    
//     buddy_free_pages(p1, 2);
//     cprintf("freed 2 pages\n");
    
//     buddy_free_pages(p2, 4);
//     cprintf("freed 4 pages\n");
    
//     size_t after_free = buddy_nr_free_pages();
//     cprintf("Free pages after free: %lu\n", after_free);
    
//     // 验证内存完整性
//     assert(initial_free == after_free);
    
//     cprintf("buddy_check passed!\n");
// }

// 测试函数 - 更全面地测试buddy system特性
static void buddy_check(void) {
    cprintf("\n=== Buddy System Comprehensive Check ===\n");
    
    size_t initial_free = buddy_nr_free_pages();
    cprintf("Initial free pages: %lu\n", initial_free);
    
    // 测试1: 基本分配释放
    cprintf("\n--- Test 1: Basic Allocation/Free ---\n");
    struct Page* p1 = buddy_alloc_pages(1);
    assert(p1 != NULL);
    cprintf("allocated 1 page at %p\n", p1);
    
    struct Page* p2 = buddy_alloc_pages(2);
    assert(p2 != NULL);
    cprintf("allocated 2 pages at %p\n", p2);
    
    struct Page* p4 = buddy_alloc_pages(4);
    assert(p4 != NULL);
    cprintf("allocated 4 pages at %p\n", p4);
    
    size_t after_alloc1 = buddy_nr_free_pages();
    cprintf("Free pages after first allocation: %lu\n", after_alloc1);
    
    buddy_free_pages(p1, 1);
    cprintf("freed 1 page\n");
    
    buddy_free_pages(p2, 2);
    cprintf("freed 2 pages\n");
    
    buddy_free_pages(p4, 4);
    cprintf("freed 4 pages\n");
    
    // 验证测试1后的内存完整性
    size_t after_test1 = buddy_nr_free_pages();
    cprintf("Free pages after test 1: %lu (should be %lu)\n", after_test1, initial_free);
    assert(after_test1 == initial_free);
    
    // // 测试2: 伙伴合并特性
    // cprintf("\n--- Test 2: Buddy Merging ---\n");
    // struct Page* blocks[8];
    
    // // 分配8个单独的页，应该是连续的
    // for (int i = 0; i < 8; i++) {
    //     blocks[i] = buddy_alloc_pages(1);
    //     assert(blocks[i] != NULL);
    //     cprintf("allocated single page %d at %p\n", i, blocks[i]);
        
    //     // 验证连续性（除了第一页，其他应该连续）
    //     if (i > 0) {
    //         assert(blocks[i] == blocks[i-1] + 1);
    //     }
    // }
    
    // // 释放所有单页，应该合并成一个大块
    // for (int i = 0; i < 8; i++) {
    //     buddy_free_pages(blocks[i], 1);
    //     cprintf("freed single page %d\n", i);
    // }
    // size_t between_test2 = buddy_nr_free_pages();
    // cprintf("Free pages after freeing 8 pages: %lu\n", between_test2);

    
    // // 现在应该能分配一个8页的大块
    // struct Page* big_block = buddy_alloc_pages(8);
    // assert(big_block != NULL);
    // cprintf("allocated 8 pages after merging at %p\n", big_block);
    
    // // 验证测试2后的内存状态
    // size_t after_test2 = buddy_nr_free_pages();
    // cprintf("Free pages after test 2: %lu\n", after_test2);
    
    // // 测试3: 分配不同大小的块
    // cprintf("\n--- Test 3: Mixed Size Allocation ---\n");
    // struct Page* mixed_blocks[4];
    // mixed_blocks[0] = buddy_alloc_pages(1);  // 1页
    // mixed_blocks[1] = buddy_alloc_pages(2);  // 2页  
    // mixed_blocks[2] = buddy_alloc_pages(1);  // 1页
    // mixed_blocks[3] = buddy_alloc_pages(4);  // 4页
    
    // for (int i = 0; i < 4; i++) {
    //     assert(mixed_blocks[i] != NULL);
    //     cprintf("mixed allocation %d: %p\n", i, mixed_blocks[i]);
    // }
    
    // size_t after_mixed = buddy_nr_free_pages();
    // cprintf("Free pages after mixed allocation: %lu\n", after_mixed);
    
    // // 测试4: 释放并验证内存完整性
    // cprintf("\n--- Test 4: Free and Integrity Check ---\n");
    
    // // 先释放大块
    // buddy_free_pages(big_block, 8);
    // cprintf("freed 8-page block\n");
    
    // // 释放混合分配的块
    // buddy_free_pages(mixed_blocks[0], 1);
    // buddy_free_pages(mixed_blocks[1], 2);
    // buddy_free_pages(mixed_blocks[2], 1);
    // buddy_free_pages(mixed_blocks[3], 4);
    // cprintf("freed all mixed blocks\n");
    
    // size_t after_test4 = buddy_nr_free_pages();
    // cprintf("Free pages after test 4: %lu (should be %lu)\n", after_test4, initial_free);
    // assert(after_test4 == initial_free);
    
    // // 测试5: 边界情况测试
    // cprintf("\n--- Test 5: Edge Cases ---\n");
    
    // // 测试分配0页
    // struct Page* p0 = buddy_alloc_pages(0);
    // if (p0 == NULL) {
    //     cprintf("alloc_pages(0) correctly returned NULL\n");
    // }
    
    // // 测试分配超过可用内存
    // size_t current_free = buddy_nr_free_pages();
    // struct Page* huge = buddy_alloc_pages(current_free + 100);
    // if (huge == NULL) {
    //     cprintf("alloc_pages(too_large) correctly returned NULL\n");
    // }
    
    // // 测试精确分配所有可用内存
    // if (current_free > 0) {
    //     struct Page* all_pages = buddy_alloc_pages(current_free);
    //     if (all_pages != NULL) {
    //         cprintf("allocated all %lu available pages\n", current_free);
    //         buddy_free_pages(all_pages, current_free);
    //         cprintf("freed all pages\n");
    //     }
    // }
    
    // // 最终完整性检查
    // size_t final_free = buddy_nr_free_pages();
    // cprintf("\nFinal free pages: %lu\n", final_free);
    // cprintf("Initial free pages: %lu\n", initial_free);
    
    // // 最终断言 - 检查内存完整性
    // if (initial_free != final_free) {
    //     cprintf("ERROR: Memory leak detected! Initial: %lu, Final: %lu\n", 
    //             initial_free, final_free);
    //     panic("Buddy system memory integrity check failed");
    // }
    
    // cprintf("\n=== Buddy System Check Pass ===\n");
    // cprintf("✓ All tests passed! Buddy system is working correctly.\n");
    // cprintf("✓ Memory integrity verified: initial %lu = final %lu pages\n", 
    //         initial_free, final_free);
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};