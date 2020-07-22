> 参考链接：
>
> 1. https://www.jianshu.com/p/752b7735a65b
> 2. https://www.cnblogs.com/gatsby123/p/9832223.html
> 3. https://www.jianshu.com/p/3be92c8228b6



## Exercises

### Exercise 1

> **Exercise 1.** In the file `kern/pmap.c` , you must implement code for the following functions (probably in the order given).
>
> `boot_alloc()`
>
> `mem_init()` (only up to the call to `check_page_free_list(1)` ) 
>
> `page_init()`
>
> `page_alloc()`
>
> `page_free()`
>
> `check_page_free_list()` and `check_page_alloc()` test your physical page allocator. You should boot JOS and see whether `check_page_alloc()` reports success. Fix your code so that it passes. You may find it helpful to add your own `assert()` s to verify that your assumptions are correct.

```c
mem_init() -> boot_init();


void main(){
    struct PageInfo *pp1, *pp2;
    struct PageInfo **tp[2] = { &pp1, &pp2 };
    for (pp = page_free_list; pp; pp = pp->pp_link) {
        int pagetype = PDX(page2pa(pp)) >= pdx_limit;
        *tp[pagetype] = pp;
        tp[pagetype] = &pp->pp_link;
    }
    *tp[1] = 0;
    *tp[0] = pp2;
    page_free_list = pp1;
}
```



### Exercise 2

> **Exercise 2.** Look at chapters 5 and 6 of the Intel 80386 Reference Manual, if you haven't done so already. Read the sections about page translation and page-based protection closely (5.2 and 6.4). We recommend that you also skim the sections about segmentation; while JOS uses paging for virtual memory and protection, segment translation and segment-based protection cannot be disabled on the x86, so you will need a basic understanding of it.



### Exercise 3

> **Exercise 3.** While GDB can only access QEMU's memory by virtual address, it's often useful to be able to inspect physical memory while setting up virtual memory. Review the QEMU monitor commands from the lab tools guide, especially the `xp` command, which lets you inspect physical memory. To access the QEMU monitor, press `Ctrl-a c` in the terminal (the same binding returns to the serial console).
>
> Use the `xp` command in the QEMU monitor and the `x` command in GDB to inspect memory at corresponding physical and virtual addresses and make sure you see the same data.
>
> Our patched version of QEMU provides an `info pg` command that may also prove useful: it shows a compact but detailed representation of the current page tables, including all mapped memory ranges, permissions, and flags. Stock QEMU also provides an `info mem` command that shows an overview of which ranges of virtual memory are mapped and with what permissions.



### Exercise 4

> **Exercise 4.** In the file `kern/pmap.c` , you must implement code for the following functions.
>
> ```c
>     pgdir_walk()
>     boot_map_region()
>     boot_map_region_large() // Map all phy-mem at KERNBASE as large pages 
>     page_lookup()
>     page_remove()
>     page_insert()
> ```
>
> `check_page()` , called from `mem_init()` , tests your page table management routines. You should make sure it reports success before proceeding.



### Exercise 5

> **Exercise 5.** Fill in the missing code in `mem_init()` after the call to `check_page()` .
> Your code should now pass the `check_kern_pgdir()` and `check_page_installed_pgdir()` checks.

```c
/* 启用巨页模式 */
uint32_t cr4 = rcr4();
cr4 |= CR4_PSE;
lcr4(cr4);
boot_map_region_large(kern_pgdir, KERNBASE, (uint32_t)-1 - KERNBASE, 0, PTE_W);

// CR0 ~ CR4: https://blog.csdn.net/qq_37414405/article/details/84487591
```



## Questions

> **Question 1.** Assuming that the following JOS kernel code is correct, what type should variable x have, uintptr_t or physaddr_t ?
>
> ```c
> mystery_t x;
> char* value = return_a_pointer();
> *value = 10;
> x = (mystery_t) value; 
> ```

应该是 uintptr_t 类型



> **Question 2.** What entries (rows) in the page directory have been filled in at this point? What addresses do they map and where do they point? In other words, fill out this table as much as possible:
>
> | Entry | Base Virtual Address | Points to (logically):                        |
> | ----- | -------------------- | --------------------------------------------- |
> | 1023  | `0xffc00000`         | Page table for top 4 MB of phys memory        |
> | 1022  | `0xff8000000`        | `Page table for [248, 252) MB of phys memory` |
> | …     | …                    |                                               |
> | 960   | `0xf0000000`         | `Page table for [0, 4) MB of phys memory`     |
> | 959   | `0xefc00000`         | `CPU Kernel Stack`                            |
> | 958   | `0xef800000`         | `ULIM & Memory-mapped I/O`                    |
> | 957   | `0xef400000`         | `Current Page Table`                          |
> | 956   | `0xef000000`         | `Read-only Pages`                             |
> | 955   | `0xeec00000`         | `Read-only Environments`                      |
> | …     | …                    |                                               |
> | 0     | 0x00000000           | [see next question]                           |



> **Question 3.** (From Lecture 3) We have placed the kernel and user environment in the same address space. Why will user programs not be able to read or write the kernel's memory? What specific mechanisms protect the kernel memory?

通过 Permission bits，不允许用户访问的地址范围不设置 PTE_U 限制用户读写



> **Question 4.** What is the maximum amount of physical memory that this operating system can
> support? Why?

理论最大值：256 MB， 虚拟地址 KERNBASE 以上的范围映射到物理内存

JOS 实际值：128 MB，`Physical memory: 131072K available, base = 640K, extended = 130432K `



> **Question 5.** How much space overhead is there for managing memory, if we actually had the maximum amount of physical memory? How is this overhead broken down?

- Page directory:
  $$
  \frac{4MB}{4MB} = 1\ page \Rightarrow 4KB
  $$

- Page table:
  $$
  \frac{4\ KB}{4\ byte} = 1024\ pages \Rightarrow 4\ MB
  $$

- Pages(`PageInfo`):
  $$
  \frac{256\ MB}{4\ KB}\ *\ sizeof(PageInfo)  = 64\ K\ *\ 8\ B = 512\ KB
  $$
  
- Sum:
  $$
  sum\approx4.5\ MB
$$
  
- 巨页可以减小开销



> **Question 6.** Revisit the page table setup in `kern/entry.S` and `kern/entrypgdir.c` . Immediately after we turn on paging, EIP is still a low number (a little over 1MB). At what point do we transition to running at an EIP above KERNBASE? What makes it possible for us to continue executing at a low EIP between when we enable paging and when we begin running at an EIP above KERNBASE? Why is this transition necessary?

```asm
	mov	$relocated, %eax
    jmp	*%eax
```

将 [0, 4 MB) 物理地址空间，映射到虚拟地址 [0, 4 MB) 和 [KERNBASE, KERNBASE+4 MB) 范围，因此EIP在低地址依然可以正常工作

这么做的原因：在开启分页模式之后，仍然需要借助低地址的指令跳转到高地址运行



## Challenges

> **Challenge!** We consumed many physical pages to hold the page tables for the KERNBASE mapping. Do a more space-efficient job using the PTE_PS ("Page Size") bit in the page directory entries. This bit was not supported in the original 80386, but is supported on more recent x86 processors. You will therefore have to refer to [Volume 3 of the current Intel manuals](https://ipads.se.sjtu.edu.cn/courses/readings/ia32/IA32-3A.pdf). Make sure you design the kernel to use this optimization only on processors that support it!



> **Challenge!** Extend the JOS kernel monitor with commands to:
>
> - Display in a useful and easy-to-read format all of the physical page mappings (or lack thereof) that apply to a particular range of virtual/linear addresses in the currently active address space. For example, you might enter 'showmappings 0x3000 0x5000' to display the physical page mappings and corresponding permission bits that apply to the pages at virtual addresses 0x3000, 0x4000, and 0x5000.
> - Explicitly set, clear, or change the permissions of any mapping in the current address space.
> - Dump the contents of a range of memory given either a virtual or physical address range. Be sure the dump code behaves correctly when the range extends across page boundaries!
> - Do anything else that you think might be useful later for debugging the kernel.
>   (There's a good chance it will be!)



> **Challenge!** Write up an outline of how a kernel could be designed to allow user environments unrestricted use of the full 4GB virtual and linear address space. Hint: the technique is sometimes known as "follow the bouncing kernel." In your design, be sure to address exactly what has to happen when the processor transitions between kernel and user modes, and how the kernel would accomplish such transitions. Also describe how the kernel would access physical memory and I/O devices in this scheme, and how the kernel would access a user environment's virtual address space during system calls and the like.
> Finally, think about and describe the advantages and disadvantages of such a scheme in terms of flexibility, performance, kernel complexity, and other factors you can think of.



> **Challenge!** Since our JOS kernel's memory management system only allocates and frees memory on page granularity, we do not have anything comparable to a general-purpose `malloc / free` facility that we can use within the kernel. This could be a problem if we want to support certain types of I/O devices that require physically contiguous buffers larger than 4KB in size, or if we want user-level environments, and not just the kernel, to be able to allocate and map 4MB superpages for maximum processor efficiency. (See the earlier challenge problem about PTE_PS.)
>
> Generalize the kernel's memory allocation system to support pages of a variety of power-of-two allocation unit sizes from 4KB up to some reasonable maximum of your choice. Be sure you have some way to divide larger allocation units into smaller ones on demand, and to coalesce multiple small allocation units back into larger units when possible. Think about the issues that might arise in such a system.