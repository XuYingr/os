#ifndef BUDDY_MEMORY_ALLOCATION_H
#define BUDDY_MEMORY_ALLOCATION_H

#include <memlayout.h>

extern const struct pmm_manager buddy_pmm_manager;

// buddy system使用二叉树来管理内存块
struct buddy {
    unsigned size;          // 管理的总块数（必须是2的幂）
    unsigned longest[0];    // 柔性数组，记录子树中最大连续空闲块
};

// 计算buddy结构体需要的内存大小
#define BUDDY_STRUCT_SIZE(size) (sizeof(struct buddy) + sizeof(unsigned) * (2 * (size) - 2))

// 块数计算宏（1块 = 1页）
#define PAGES_TO_BLOCKS(pages) (pages)
#define BLOCKS_TO_PAGES(blocks) (blocks)

struct buddy* buddy_new(void* addr, unsigned blocks);
void buddy_destroy(struct buddy* self);
int buddy_alloc(struct buddy* self, unsigned blocks);
void buddy_free(struct buddy* self, int block_offset, unsigned block_size) ;
unsigned nr_free_blocks(struct buddy* self);

// 工具函数
static int is_pow_of_2(unsigned x) {
    return x && !(x & (x-1));
}

static unsigned next_pow_of_2(unsigned x) {
    if (is_pow_of_2(x)) return x;
    x |= x>>1;
    x |= x>>2;
    x |= x>>4;
    x |= x>>8;
    x |= x>>16;
    return x+1;
}

static inline int left_leaf(int idx) { return 2 * idx + 1; }
static inline int right_leaf(int idx) { return 2 * idx + 2; }
static inline int parent(int idx) { return (idx - 1) / 2; }
static inline int max(int a, int b) { return (a > b) ? a : b; }

#endif