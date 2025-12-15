#include <vmm.h>
#include <sync.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <error.h>
#include <pmm.h>
#include <riscv.h>
#include <kmalloc.h>

/*
  vmm design include two parts: mm_struct (mm) & vma_struct (vma)
  mm is the memory manager for the set of continuous virtual memory
  area which have the same PDT. vma is a continuous virtual memory area.
  There a linear link list for vma & a redblack link list for vma in mm.
---------------
  mm related functions:
   golbal functions
     struct mm_struct * mm_create(void)
     void mm_destroy(struct mm_struct *mm)
     int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
--------------
  vma related functions:
   global functions
     struct vma_struct * vma_create (uintptr_t vm_start, uintptr_t vm_end,...)
     void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
     struct vma_struct * find_vma(struct mm_struct *mm, uintptr_t addr)
   local functions
     inline void check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
---------------
   check correctness functions
     void check_vmm(void);
     void check_vma_struct(void);
     void check_pgfault(void);
*/

volatile unsigned int pgfault_num = 0;

static void check_vmm(void);
static void check_vma_struct(void);

// mm_create -  alloc a mm_struct & initialize it.
struct mm_struct *
mm_create(void)
{
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));

    if (mm != NULL)
    {
        list_init(&(mm->mmap_list));
        mm->mmap_cache = NULL;
        mm->pgdir = NULL;
        mm->map_count = 0;

        mm->sm_priv = NULL;

        set_mm_count(mm, 0);
        lock_init(&(mm->mm_lock));
    }
    return mm;
}

// vma_create - alloc a vma_struct & initialize it. (addr range: vm_start~vm_end)
struct vma_struct *
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags)
{
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));

    if (vma != NULL)
    {
        vma->vm_start = vm_start;
        vma->vm_end = vm_end;
        vma->vm_flags = vm_flags;
    }
    return vma;
}

// find_vma - find a vma  (vma->vm_start <= addr <= vma_vm_end)
struct vma_struct *
find_vma(struct mm_struct *mm, uintptr_t addr)
{
    struct vma_struct *vma = NULL;
    if (mm != NULL)
    {
        vma = mm->mmap_cache;
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
        {
            bool found = 0;
            list_entry_t *list = &(mm->mmap_list), *le = list;
            while ((le = list_next(le)) != list)
            {
                vma = le2vma(le, list_link);
                if (vma->vm_start <= addr && addr < vma->vm_end)
                {
                    found = 1;
                    break;
                }
            }
            if (!found)
            {
                vma = NULL;
            }
        }
        if (vma != NULL)
        {
            mm->mmap_cache = vma;
        }
    }
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
    list_entry_t *list = &(mm->mmap_list);
    list_entry_t *le_prev = list, *le_next;

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
        {
            break;
        }
        le_prev = le;
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
    }
    if (le_next != list)
    {
        check_vma_overlap(vma, le2vma(le_next, list_link));
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
}

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
    }
    kfree(mm); // kfree mm
    mm = NULL;
}

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
    if (!USER_ACCESS(start, end))
    {
        return -E_INVAL;
    }

    assert(mm != NULL);

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
    {
        goto out;
    }
    ret = -E_NO_MEM;

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;

out:
    return ret;
}

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
    assert(to != NULL && from != NULL);
    list_entry_t *list = &(from->mmap_list), *le = list;
    while ((le = list_prev(le)) != list)
    {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}

void exit_mmap(struct mm_struct *mm)
{
    assert(mm != NULL && mm_count(mm) == 0);
    pde_t *pgdir = mm->pgdir;
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
    }
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
    }
}

bool copy_from_user(struct mm_struct *mm, void *dst, const void *src, size_t len, bool writable)
{
    if (!user_mem_check(mm, (uintptr_t)src, len, writable))
    {
        return 0;
    }
    memcpy(dst, src, len);
    return 1;
}

bool copy_to_user(struct mm_struct *mm, void *dst, const void *src, size_t len)
{
    if (!user_mem_check(mm, (uintptr_t)dst, len, 1))
    {
        return 0;
    }
    memcpy(dst, src, len);
    return 1;
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
    check_vmm();
}

// check_vmm - check correctness of vmm
static void
check_vmm(void)
{
    // size_t nr_free_pages_store = nr_free_pages();

    check_vma_struct();
    // check_pgfault();

    cprintf("check_vmm() succeeded.\n");
}

static void
check_vma_struct(void)
{
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    for (i = step1 + 1; i <= step2; i++)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
    {
        assert(le != &(mm->mmap_list));
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
        assert(vma1 != NULL);
        struct vma_struct *vma2 = find_vma(mm, i + 1);
        assert(vma2 != NULL);
        struct vma_struct *vma3 = find_vma(mm, i + 2);
        assert(vma3 == NULL);
        struct vma_struct *vma4 = find_vma(mm, i + 3);
        assert(vma4 == NULL);
        struct vma_struct *vma5 = find_vma(mm, i + 4);
        assert(vma5 == NULL);

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
    }

    for (i = 4; i >= 0; i--)
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
        if (vma_below_5 != NULL)
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
    if (mm != NULL)
    {
        if (!USER_ACCESS(addr, addr + len))
        {
            return 0;
        }
        struct vma_struct *vma;
        uintptr_t start = addr, end = addr + len;
        while (start < end)
        {
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
            {
                return 0;
            }
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}

// do_pgfault - handle page fault exception
// @mm: memory management struct
// @error_code: error code (1 for write, 0 for read)
// @addr: fault address
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
{
    int ret = -E_INVAL;
    // find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);

    pgfault_num++;
    
    // Check if address is in user space
    if (!USER_ACCESS(addr, addr + 1))
    {
        cprintf("do_pgfault: address 0x%08lx is not in user space\n", addr);
        goto failed;
    }
    
    // If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr)
    {
        cprintf("do_pgfault: not valid addr 0x%08lx, and can not find it in vma\n", addr);
        goto failed;
    }
    // Check if this is a write fault (error_code == 1 means write)
    bool is_write = (error_code == 1);
    if (is_write && !(vma->vm_flags & VM_WRITE))
    {
        cprintf("do_pgfault failed: write fault but vma is not writable\n");
        goto failed;
    }
    if (!is_write && !(vma->vm_flags & (VM_READ | VM_EXEC)))
    {
        cprintf("do_pgfault failed: read fault but vma is not readable/executable\n");
        goto failed;
    }
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE)
    {
        perm |= (PTE_R | PTE_W);
    }
    addr = ROUNDDOWN(addr, PGSIZE);

    ret = -E_NO_MEM;

    pte_t *ptep = NULL;
    /*
     * LAB3 EXERCISE 1: YOUR CODE
     * Maybe you want help comment, BELOW comments can help you finish the code
     *
     * Some Useful MACROs and DEFINEs, you can use them in below implementation.
     * MACROs or Functions:
     *   get_pte : get an pte and return the kernel virtual address of this pte for la
     *             if the PT contians this pte didn't exist, alloc a page for PT
     *             (notice the 3th parameter '1')
     *   pgdir_alloc_page : call alloc_page & page_insert functions to allocate a page size memory & setup
     *             an addr map pa<--->la with linear address la and the PDT pgdir
     *
     * (1) check if this pte is a COW page
     *     if (ptep != NULL && (*ptep & PTE_COW)) {
     *         // handle COW page fault
     *     }
     * (2) if the pte is NULL, we need to alloc a page
     *     if (ptep == NULL) {
     *         pgdir_alloc_page(mm->pgdir, addr, perm);
     *     }
     */
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL)
    {
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }

    // Check if this is a COW page fault
    if (*ptep & PTE_V && (*ptep & PTE_COW))
    {
        // This is a COW page fault - we need to copy the page
        struct Page *page = pte2page(*ptep);
        if (page == NULL)
        {
            cprintf("pte2page in do_pgfault failed\n");
            goto failed;
        }

        // This is a COW page fault - we need to copy the page if it's a write fault
        // For read/execute faults on COW pages, the page is already mapped and readable
        // so we can just return success (the page fault was likely due to other reasons)
        if (!is_write)
        {
            // Read/execute fault on COW page - page is already mapped, just return success
            ret = 0;
            goto out;
        }

        // Write fault on COW page - need to copy if multiple references exist
        // If page reference count > 1, we need to copy the page
        if (page_ref(page) > 1)
        {
            // Allocate a new page
            struct Page *npage = alloc_page();
            if (npage == NULL)
            {
                cprintf("alloc_page in do_pgfault failed\n");
                goto failed;
            }

            // Copy the content from old page to new page
            void *src_kvaddr = page2kva(page);
            void *dst_kvaddr = page2kva(npage);
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);

            // Decrement reference count of old page
            page_ref_dec(page);

            // Map the new page with write permission (remove COW flag)
            uint32_t new_perm = (perm | PTE_R | PTE_W) & ~PTE_COW;
            if (page_insert(mm->pgdir, npage, addr, new_perm) != 0)
            {
                free_page(npage);
                cprintf("page_insert in do_pgfault failed\n");
                goto failed;
            }
        }
        else
        {
            // Only one reference, we can just remove COW flag and add write permission
            uint32_t new_perm = (*ptep & PTE_USER) | PTE_R | PTE_W;
            new_perm &= ~PTE_COW;
            *ptep = pte_create(page2ppn(page), new_perm);
            tlb_invalidate(mm->pgdir, addr);
        }
        ret = 0;
    }
    else if (*ptep == 0)
    {
        // Page not present, allocate a new page
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL)
        {
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            goto failed;
        }
        ret = 0;
    }
    else
    {
        // Page is present and valid but not COW
        // This might be a legitimate page fault (e.g., page was swapped out)
        // For now, we'll treat it as an error
        cprintf("do_pgfault: page is present (0x%08lx) but not COW, unexpected state\n", *ptep);
        goto failed;
    }
out:
    return ret;
failed:
    return ret;
}