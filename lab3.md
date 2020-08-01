1. 内存问题：kernel panic at kern/pmap.c:147: PADDR called with invalid kva 00000000

   ```asm
   /* @ kern/kernel.ld */
   .bss : {
   	PROVIDE(edata = .);
   	*(.bss)
   	*(COMMON)				/* + */
   	PROVIDE(end = .);
   	BYTE(0)
   }
   ```

   > 参考链接：
   >
   > 1. [解决方法](https://www.cnblogs.com/wevolf/p/12740793.html)
   >
   > 2. [简单的ld链接脚本学习](https://www.jianshu.com/p/42823b3b7c8e)
   > 3. [[转]Linux下的lds链接脚本详解](https://www.cnblogs.com/li-hao/p/4107964.html)
   > 4. [bss段和common段的区别](https://blog.csdn.net/lk07828/article/details/42393643)

   > 对于全局变量来说，如果初始化了不为0的值，那么该全局变量则被保存在data段，
   >
   > 如果初始化的值为0，那么将其保存在bss段，
   >
   > 如果没有初始化，则将其保存在common段，等到链接时再将其放入到BSS段。
   >
   > 关于第三点不同编译器行为会不同，有的编译器会把没有初始化的全局变量直接放到BSS段。
   
2. 参考链接：

   - https://wenku.baidu.com/view/cfb66b3410661ed9ad51f39e.html
   - https://www.cnblogs.com/wevolf/p/12740793.html
   - Exercise13: https://github.com/chenlighten/JOS
   - 知乎总结：https://zhuanlan.zhihu.com/p/74028717
   - 好看的界面：https://www.xsegment.cn/2020/01/07/MIT6-828-OS-lab3/#system-call
   - JOS学习笔记：https://wizardforcel.gitbooks.io/jos-lab/content/9.html



## Exercises

### Exercise 1

> **Exercise 1.** Modify `mem_init()` in `kern/pmap.c` to allocate and map the `envs` array.
> This array consists of exactly `NENV` instances of the `Env` structure allocated much
> like how you allocated the `pages` array. Also like the `pages` array, the memory
> backing `envs` should also be mapped user read-only at `UENVS` (defined in
> `inc/memlayout.h` ) so user processes can read from this array.
>
> You should run your code and make sure `check_kern_pgdir()` succeeds.

```c
//////////////////////////////////////////////////////////////////////
// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
// LAB 3: Your code here.
envs = (struct Env*)boot_alloc(sizeof(struct Env) * NENV);
memset(pages, 0, sizeof(struct Env) * NENV);


//////////////////////////////////////////////////////////////////////
// Map the 'envs' array read-only by the user at linear address UENVS
// (ie. perm = PTE_U | PTE_P).
// Permissions:
//    - the new image at UENVS  -- kernel R, user R
//    - envs itself -- kernel RW, user NONE
// LAB 3: Your code here.
boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);
```



### Exercise 2

> **Exercise 2.** In the file `env.c` , finish coding the following functions:
>
> `env_init()`
>
> Initialize all of the `Env` structures in the `envs` array and add them to the `env_free_list` . Also calls `env_init_percpu` , which configures the segmentation hardware with separate segments for privilege level 0 (kernel) and privilege level 3 (user).
>
> `env_setup_vm()`
>
> Allocate a page directory for a new environment and initialize the kernel portion of the new environment's address space.
>
> `region_alloc()`
>
> Allocates and maps physical memory for an environment
>
> `load_icode()`
>
> You will need to parse an ELF binary image, much like the boot loader already does, and load its contents into the user address space of a new environment.
>
> `env_create()`
>
> Allocate an environment with `env_alloc` and call `load_icode` to load an ELF binary into it.
>
> `env_run()`
>
> Start a given environment running in user mode.
>
> As you write these functions, you might find the new cprintf verb `%e` useful -- it prints a description corresponding to an error code. For example,
>
> ```c
> r = -E_NO_MEM;
> panic("env_alloc: %e", r);
> ```
>
> will panic with the message "env_alloc: out of memory".

> 参考链接：
>
> [1]：https://blog.csdn.net/yeruby/article/details/39718119?depth_1-utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromBaidu-1&utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromBaidu-1
>
> [2]：https://www.cnblogs.com/flatcc/p/11613649.html



#### 2.1 env_init()

```c
void env_init(void) {
    // Set up envs array
    // LAB 3: Your code here.
	int i;
    for (i = NENV -1; i >= 0; i--){
        envs[i].env_status = ENV_FREE;
        envs[i].env_id = 0;
        envs[i].env_link = env_free_list;
        env_free_list = envs + i;
    }
    
    // Per-CPU part of the initialization
    env_init_percpu();
}
```



#### 2.2 env_setup_vm()

```c
static int env_setup_vm(struct Env *e) {
    int i;
    struct PageInfo *p = NULL;
    
    // Allocate a page for the page directory
    if (!(p = page_alloc(ALLOC_ZERO)))
        return -E_NO_MEM;
    
    // Now, set e->env_pgdir and initialize the page directory.
 	// LAB 3: Your code here.
	e->env_pgdir = page2kva(p);
    p->pp_ref++;
    
    
    /* memcpy(e->env_pgdir, kern_pgdir, NPDENTRIES * sizeof(pde_t)); */
    memmove(e->env_pgdir, kern_pgdir, NPDENTRIES * sizeof(pde_t));
    memset(e->env_pgdir, 0, PDX(UTOP) * sizeof(pde_t));
    
    // UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
    e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
    return 0;
}
```

>`memmove` vs. `memcpy`: https://www.cnblogs.com/luoquan/p/5265273.html
>
>他们的作用是一样的，唯一的区别是，当内存发生局部重叠的时候，memmove保证拷贝的结果是正确的，memcpy不保证拷贝的结果的正确。



#### 2.3 region_alloc()

```c
static void region_alloc(struct Env *e, void *va, size_t len) {
    // LAB 3: Your code here.
	struct PageInfo *pp;
    va = ROUNDDOWN(va, PGSIZE);
    int i, r, n = (ROUNDUP(va + len, PGSIZE) - va) / PGSIZE;
    
    for (i = 0; i < n; i++){
        pp = page_alloc(ALLOC_ZERO);
        if (pp == NULL){
            panic("region_alloc: alloc page failed");
        }
        r = page_insert(e->env_pgdir, pp, va, PTE_U | PTE_W);
        if (r != 0){
            panic("region_alloc: %e", r);
        }
        va += PGSIZE;
    }
}
```



#### 2.4 load_icode()

```c
static void load_icode(struct Env *e, uint8_t *binary) {
    // LAB 3: Your code here.
	struct Proghdr *ph, *eph;
    void *va;
    struct Elf *ELFHDR = (struct Elf *)binary;
    if (ELFHDR->e_magic != ELF_MAGIC)
        panic("load_icode: e_magic != ELF_MAGIC");
    ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    eph = ph + ELFHDR->e_phnum;
    for (; ph < eph; ph++){
        if (ph->p_type != ELF_PROG_LOAD){
            continue;
        }
        if (ph->p_filesz > ph->p_memsz){
            panic("load_icode: filesz > memsz");
        }
        va = (void *)ph->p_va;
        region_alloc(e, va, ph->p_memsz);
        memset(va, 0, ph->p_memsz);
        memmove(va, binary + ph->p_offset, ph->p_filesz);
    }
    e->env_tf.tf_eip = ELFHDR->e_entry;
    
    // Now map one page for the program's initial stack
    // at virtual address USTACKTOP - PGSIZE.
    
 	// LAB 3: Your code here.
	region_alloc(e, (void *)(USTACKTOP - PGSIZE), PGSIZE);
}
```



#### 2.5 env_create()

```c
void env_create(uint8_t *binary, enum EnvType type) {
    // LAB 3: Your code here.
	struct Env *e; 	int res;
    if ((res = env_alloc(&e, 0)) < 0){
        panic("env_create: %e", res);
    }
    e->env_type = type;
    lcr3(PADDR(e->env_pgdir));
    load_icode(e, binary);
    lcr3(PADDR(kern_pgdir));
}
```



#### 2.6 env_run()

```c
void env_run(struct Env *e) {
 	// LAB 3: Your code here.
	if (e != curenv){
        if (curenv && curenv->env_status == ENV_RUNNING){
            curenv->env_status = ENV_RUNNABLE;
        }
        
        curenv = e;
        curenv->env_status = ENV_RUNNING;
        curenv->env_runs++;
        lcr3(PADDR(curenv->env_pgdir));
    }
    env_pop_tf(&(curenv->env_tf));
    panic("env_run not yet implemented");
}
```



### Exercise 3

> **Exercise 3.** Read Chapter 9, Exceptions and Interrupts in the 80386 Programmer's Manual (or Chapter 5 of the IA-32 Developer's Manual), if you haven't already.



### Exercise 4

> **Exercise 4.** Edit `trapentry.S` and `trap.c` and implement the features described above. The macros `TRAPHANDLER` and `TRAPHANDLER_NOEC` in `trapentry.S` should help you, as well as the T_* defines in `inc/trap.h` . You will need to add an entry point in `trapentry.S` (using those macros) for each trap defined in inc/trap.h , and you'll have to provide ` _alltraps` which the `TRAPHANDLER` macros refer to. You will also need to modify `trap_init()` to initialize the idt to point to each of these entry points defined in `trapentry.S` ; the `SETGATE` macro will be helpful here.
>
> Your `_alltraps` should: 
>
> 1. push values to make the stack look like a struct Trapframe
> 2. load `GD_KD` into `%ds` and `%es`
> 3. `pushl %esp` to pass a pointer to the Trapframe as an argument to trap()
> 4. `call trap` (can `trap` ever return?)
>
> Consider using the `pushal` instruction; it fits nicely with the layout of the `struct Trapframe` .
>
> Test your trap handling code using some of the test programs in the `user` directory that cause exceptions before making any system calls, such as `user/divzero` . You should be able to get make grade to succeed on the `divzero` , `softint` , and `badsegment` tests at this point.



#### 4.1 trapentry.S

> 参考链接：
>
> 错误码：https://blog.csdn.net/zhangyang249/article/details/78305788

```asm
/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(ENTRY_DIVIDE, T_DIVIDE)
TRAPHANDLER_NOEC(ENTRY_DEBUG, T_DEBUG)
TRAPHANDLER_NOEC(ENTRY_NMI, T_NMI)
TRAPHANDLER_NOEC(ENTRY_BRKPT, T_BRKPT)
TRAPHANDLER_NOEC(ENTRY_OFLOW, T_OFLOW)
TRAPHANDLER_NOEC(ENTRY_BOUND, T_BOUND)
TRAPHANDLER_NOEC(ENTRY_ILLOP, T_ILLOP)
TRAPHANDLER_NOEC(ENTRY_DEVICE, T_DEVICE)
TRAPHANDLER(ENTRY_DBLFLT, T_DBLFLT)
/* TRAPHANDLER_NOEC(ENTRY_COPROC, T_COPROC) */
TRAPHANDLER(ENTRY_TSS, T_TSS)
TRAPHANDLER(ENTRY_SEGNP, T_SEGNP)
TRAPHANDLER(ENTRY_STACK, T_STACK)
TRAPHANDLER(ENTRY_GPFLT, T_GPFLT)
TRAPHANDLER(ENTRY_PGFLT, T_PGFLT)
/* TRAPHANDLER_NOEC(ENTRY_RES, T_RES) */
TRAPHANDLER_NOEC(ENTRY_FPERR, T_FPERR)
TRAPHANDLER_NOEC(ENTRY_ALIGN, T_ALIGN)
TRAPHANDLER_NOEC(ENTRY_MCHK, T_MCHK)
TRAPHANDLER_NOEC(ENTRY_SIMDERR, T_SIMDERR)
```

```asm
/*
 * Lab 3: Your code here for _alltraps
 */
.global _alltraps
_alltraps:
	pushw	$0x0
	pushw	%ds
	pushw	$0x0
    pushw	%es
    pushal
    
    movl	$GD_KD, %eax
    movw	%ax, %ds
    movw	%ax, %es
    
    pushl	%esp
    call	trap
```



#### 4.2 trap_init()

```c
void trap_init(void) {
    extern struct Segdesc gdt[];
    
    /* TODO: privilege */
    // LAB 3: Your code here.
	SETGATE(idt[T_DIVIDE], 1, GD_KT, ENTRY_DIVIDE, 0);
    SETGATE(idt[T_DEBUG], 1, GD_KT, ENTRY_DEBUG, 0);
    SETGATE(idt[T_NMI], 0, GD_KT, ENTRY_NMI, 0);
    SETGATE(idt[T_BRKPT], 1, GD_KT, ENTRY_BRKPT, 0);
    SETGATE(idt[T_OFLOW], 1, GD_KT, ENTRY_OFLOW, 0);
    SETGATE(idt[T_BOUND], 1, GD_KT, ENTRY_BOUND, 0);
    SETGATE(idt[T_ILLOP], 1, GD_KT, ENTRY_ILLOP, 0);
    SETGATE(idt[T_DEVICE], 1, GD_KT, ENTRY_DEVICE, 0);
    SETGATE(idt[T_DBLFLT], 1, GD_KT, ENTRY_DBLFLT, 0);
    /* SETGATE(idt[T_COPROC], 1, GD_KT, ENTRY_COPROC, 0); */
    SETGATE(idt[T_TSS], 1, GD_KT, ENTRY_TSS, 0);
    SETGATE(idt[T_SEGNP], 1, GD_KT, ENTRY_SEGNP, 0);
    SETGATE(idt[T_STACK], 1, GD_KT, ENTRY_STACK, 0);
    SETGATE(idt[T_GPFLT], 1, GD_KT, ENTRY_GPFLT, 0);
    SETGATE(idt[T_PGFLT], 1, GD_KT, ENTRY_PGFLT, 0);
    /* SETGATE(idt[T_RES], 0, GD_KT, ENTRY_RES, 0); */
    SETGATE(idt[T_FPERR], 1, GD_KT, ENTRY_FPERR, 0);
    SETGATE(idt[T_ALIGN], 1, GD_KT, ENTRY_ALIGN, 0);
    SETGATE(idt[T_MCHK], 1, GD_KT, ENTRY_MCHK, 0);
    SETGATE(idt[T_SIMDERR], 1, GD_KT, ENTRY_SIMDERR, 0);
    
    // Per-CPU setup
    trap_init_percpu();
}
```



### Exercise 5 & 6

> **Exercise 5.** Modify `trap_dispatch()` to dispatch page fault exceptions to `page_fault_handler()` . You should now be able to get `make grade` to succeed on the `faultread` , `faultreadkernel` , `faultwrite` , and `faultwritekernel` tests. If any of them don't work, figure out why and fix them. Remember that you can boot JOS into a particular user program using `make run-x` or `make run-x-nox`. For instance, `make run-hello-nox` runs the hello user program.
>
> **Exercise 6.** Modify `trap_dispatch()` to make breakpoint exceptions invoke the kernel monitor. You should now be able to get `make grade` to succeed on the `breakpoint` test.



```c
static void trap_dispatch(struct Trapframe *tf) {
    // Handle processor exceptions.
	// LAB 3: Your code here.
	if(tf->tf_trapno == T_PGFLT){
        page_fault_handler(tf);
    } else if(tf->tf_trapno == T_BRKPT){
        monitor(tf);
    }
    
    // Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
    
    if (tf->tf_cs == GD_KT)
        panic("unhandled trap in kernel");
    else {
        env_destroy(curenv);
        return;
    }
}
```



### Exercise 7

> **Exercise 7.** Add a handler in the kernel for interrupt vector `T_SYSCALL` . You will have to edit `kern/trapentry.S` and `kern/trap.c` 's `trap_init()` . You also need to change `trap_dispatch()` to handle the system call interrupt by calling `syscall()` (defined in `kern/syscall.c` ) with the appropriate arguments, and then arranging for the return value to be passed back to the user process in `%eax` . Finally, you need to implement `syscall()` in `kern/syscall.c` . Make sure `syscall()` returns `-E_INVAL` if the system call number is invalid. You should read and understand `lib/syscall.c` (especially the inline assembly routine) in order to confirm your understanding of the system call interface. Handle all the system calls listed in `inc/syscall.h` by invoking the corresponding kernel function for each call.
>
> Run the `user/hello` program under your kernel (`make run-hello`). It should print " `hello, world` " on the console and then cause a page fault in user mode. If this does not happen, it probably means your system call handler isn't quite right. You should also now be able to get `make grade` to succeed on the `testbss` test.



> 发生 sys_cputs 系统调用时：
>
> 用户程序
>
> └── sys_cputs()											/* lib/printf.c */
>
> ​     └── syscall()											/* lib/syscall.c */
>
> ​         └── trap()
>
> ​             └── trap_dispatch()
>
> ​                 └── syscall()								/* kern/printf.c */
>
> ​                     └── sys_cputs()						/* kern/printf.c */
>
> ​                         └── cprtinf()						/* kern/syscall.c */



#### 7.1 trapentry.S

```asm
TRAPHANDLER_NOEC(ENTRY_SYSCALL, T_SYSCALL)
```



#### 7.2 trap_init()

```c
extern void ENTRY_SYSCALL();		// system call

SETGATE(idt[T_SYSCALL], 0, GD_KT, ENTRY_SYSCALL, 3);
```



#### 7.3 trap_dispatch()

```c
 else if (tf->tf_trapno == T_SYSCALL){
     tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx,
                                   tf->tf_regs.reg_ecx, tf->tf_regs.reg_ebx,
                                   tf->tf_regs.reg_edi, tf->tf_regs.reg_esi); 		
     return;		/* 此处需要return */
 }
```



### Exercise 8

> **Exercise 8.** Implement system calls using the `sysenter` and `sysexit` instructions instead of using `int 0x30` and `iret` .
>
> The `sysenter/sysexit` instructions were designed by Intel to be faster than `int/iret` .
> They do this by using registers instead of the stack and by making assumptions
> about how the segmentation registers are used. The exact details of these
> instructions can be found in Volume 2B of the Intel reference manuals.
>
> The easiest way to add support for these instructions in JOS is to add a
> `sysenter_handler` in `kern/trapentry.S` that saves enough information about the user
> environment to return to it, sets up the kernel environment, pushes the arguments to
> `syscall()` and calls `syscall()` directly. Once `syscall()` returns, set everything up
> for and execute the `sysexit` instruction. You will also need to add code to
> `kern/init.c` to set up the necessary model specific registers (MSRs). Section 6.1.2
> in Volume 2 of the AMD Architecture Programmer's Manual and the reference on SYSENTER in Volume 2B of the Intel reference manuals give good descriptions of the relevant MSRs. You can find an implementation of `wrmsr` to add to `inc/x86.h` for writing to these MSRs here.
>
> Finally, `lib/syscall.c` must be changed to support making a system call with
> `sysenter` . Here is a possible register layout for the `sysenter` instruction:
>
> ```asm
>     eax - syscall number
>     edx, ecx, ebx, edi - arg1, arg2, arg3, arg4
>     esi - return pc
>     ebp - return esp
>     esp - trashed by sysenter
> ```
>
> GCC's inline assembler will automatically save registers that you tell it to load values directly into. Don't forget to either save (push) and restore (pop) other registers that you clobber, or tell the inline assembler that you're clobbering them. The inline assembler doesn't support saving `%ebp` , so you will need to add code to save and restore it yourself. The return address can be put into `%esi` by using an instruction like `leal after_sysenter_label, %%esi` .
>
> Note that this only supports 4 arguments, so you will need to leave the old method of doing system calls around to support 5 argument system calls. Furthermore, because this fast path doesn't update the current environment's trap frame, it won't be suitable for some of the system calls we add in later labs.
>
> You may have to revisit your code once we enable asynchronous interrupts in the
> next lab. Specifically, you'll need to enable interrupts when returning to the user
> process, which sysexit doesn't do for you.



#### 8.1 trapentry.S

```asm
.global sysenter_handler
sysenter_handler:
	pushl %esi
	pushl %edi
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %eax
	call syscall
	movl %esi, %edx
	movl %ebp, %ecx
	sysexit
```



#### 8.2 x86.h

```c
/*
 * 每个MSR是64位宽的,每个MSR都有它的的地址值(编号).
 * 对MSR操作使用两个指令进行读写,
 * 由ecx寄存器提供需要访问的MSR地址值,EDX:EAX提供64位值(EAX表示低32位,EDX表示高32位)
 */

#define rdmsr(msr,val1,val2) \
__asm__ __volatile__("rdmsr" \
: "=a" (val1), "=d" (val2) \
: "c" (msr))

#define wrmsr(msr,val1,val2) \
__asm__ __volatile__("wrmsr" \
: /* no outputs */ \
: "c" (msr), "a" (val1), "d" (val2))
```



#### 8.3 trap_init()

```c
extern void sysenter_handler();

wrmsr(0x174, GD_KT, 0);           /* SYSENTER_CS_MSR */
wrmsr(0x175, KSTACKTOP, 0);       /* SYSENTER_ESP_MSR */
wrmsr(0x176, sysenter_handler, 0);/* SYSENTER_EIP_MSR */
```



#### 8.4 lib/syscall.c

```c
static inline int32_t syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5) {
    int32_t ret;

/*
   	asm volatile("int %1\n"
                 : "=a" (ret)
                 : "i" (T_SYSCALL),
                 "a" (num),
                 "d" (a1),
                 "c" (a2),
                 "b" (a3),
                 "D" (a4),
                 "S" (a5)
                 : "cc", "memory");
*/
        
    asm volatile(
        // Store return %esp to %ebp, store return pc to %esi
        "pushl %%esp\n\t"
        "popl %%ebp\n\t"
        "leal after_sysenter_label%=, %%esi\n\t"	// Use "%=" to generate a unique label number.
		"sysenter\n\t"
        "after_sysenter_label%=:\n\t"
        : "=a" (ret)
        : "a" (num),
        "d" (a1),
        "c" (a2),
        "b" (a3),
        "D" (a4),
        "S" (a5)
        : "cc", "memory");
    
    if(check && ret > 0)
        panic("syscall %d returned %d (> 0)", num, ret);
    
    return ret;
}
```



### Exercise 9

> **Exercise 9.** Add the required code to the user library, then boot your kernel. You
> should see `user/hello` print " `hello, world` " and then print
> " `i am environment 00001000` ". `user/hello` then attempts to "exit" by calling
> `sys_env_destroy()` (see `lib/libmain.c` and `lib/exit.c` ). Since the kernel currently
> only supports one user environment, it should report that it has destroyed the only
> environment and then drop into the kernel monitor. You should be able to get `make grade` to succeed on the `hello` test.

```c
thisenv = envs + ENVX(sys_getenvid());
```



### Exercise 10

> **Exercise 10.** You need to write syscall `sbrk`. The `sbrk()`, as described in the manual
> page `(man sbrk)` , extends the size of a process's data segment (heap). It
> dynamically allocates memory for a program. Actually, the famous malloc allocates
> memory in the heap using this syscall.
> As
>
> ```c
> int sys_sbrk(uint32_t increment);
> ```
>
> shows, `sbrk()` increase current program' data space by `increment` bytes. On
> success, `sbrk()` returns the current program 's break after being increased. **NOTE: it**
> **is different from the standard behavior of `sbrk()`.**
>
> For the implementation, you just need to allocate multiple pages and insert them into
> the correct positions in page table, growing the heap higher. The `load_icode()` may
> act as a hint. You also might need to modify `struct Env` to record the current
> program's break and update them accordingly in `sbrk()`.
>
> After you finish this part, you can expect `make grade` to succeed on the `sbrktest` test.



#### 10.1 struct Env

```c
	uintptr_t env_brk;		// sbrk()
```



#### 10.2 load_icode()

```c
    lcr3(PADDR(e->env_pgdir));
    e->env_brk = (uintptr_t)ROUNDUP(UTEXT, PGSIZE);				/* + */
    for (; ph < eph; ph++){
        if (ph->p_type != ELF_PROG_LOAD){
            continue;
        }
        if (ph->p_filesz > ph->p_memsz){
            panic("load_icode: filesz > memsz");
        }
        va = (void *)ph->p_va;
        region_alloc(e, va, ph->p_memsz);
        memset(va, 0, ph->p_memsz);
        memmove(va, binary + ph->p_offset, ph->p_filesz);
        if(ph->p_va + ph->p_memsz > e->env_brk){								/* + */
            e->env_brk = (uintptr_t)ROUNDUP(ph->p_va + ph->p_memsz, PGSIZE);
        }
    }
    lcr3(PADDR(kern_pgdir));
```



#### 10.3 kern/syscall.c

```c
//
// Allocate len bytes of physical memory for environment env,
// and map it at virtual address va in the environment's address space.
// Does not zero or otherwise initialize the mapped pages in any way.
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	struct PageInfo *pp;
	va = ROUNDDOWN(va, PGSIZE);
	int i, r, n = (ROUNDUP(va + len, PGSIZE) - va) / PGSIZE;

	for (i = 0; i < n; i++){
		pp = page_alloc(ALLOC_ZERO);
		if (pp == NULL){
			panic("region_alloc: alloc page failed");
		}
		r = page_insert(e->env_pgdir, pp, va, PTE_U | PTE_W);
		if (r != 0){
			panic("region_alloc: %e", r);
		}
		va += PGSIZE;
	}
}

static int
sys_sbrk(uint32_t inc)
{
    // LAB3: your code here.
	region_alloc(curenv, (void*)curenv->env_brk, inc);
	curenv->env_brk = (uintptr_t)ROUNDUP(curenv->env_brk + inc, PGSIZE);
	
    return curenv->env_brk;
}
```



### Exercise 11

> **Exercise 11.** Change `kern/trap.c` to panic if a page fault happens in kernel mode.
>
> Hint: to determine whether a fault happened in user mode or in kernel mode, check
> the low bits of the `tf_cs` .
>
> Read `user_mem_assert` in `kern/pmap.c` and implement `user_mem_check` in that same
> file.
>
> Change `kern/syscall.c` to sanity check arguments to system calls.
>
> Boot your kernel, running `user/buggyhello` . The environment should be destroyed,
> and the kernel should not panic. You should see:
>
> ```sh
> [00001000] user_mem_check assertion failure for va 00000001
> [00001000] free env 00001000
> Destroyed the only environment - nothing more to do!
> ```
>
> Finally, change `debuginfo_eip` in `kern/kdebug.c` to call `user_mem_check` on `usd` ,
> `stabs` , and `stabstr` . If you now run `user/breakpoint` , you should be able to run
> `backtrace` from the kernel monitor and see the backtrace traverse into `lib/libmain.c`
> before the kernel panics with a page fault. What causes this page fault? You don't
> need to fix it, but you should understand why it happens.



#### 11.1 page_fault_handler()

```c
    // LAB 3: Your code here.
    if ((tf->tf_cs & 3) == 0){
        panic("page_fault_handler: kernel-mode page faults");
    }
```



#### 11.2 user_mem_check()

```c
int user_mem_check(struct Env *env, const void *va, size_t len, int perm) {
    // LAB 3: Your code here.
    pte_t *pte;
    uintptr_t start, cur, end;
    start = (uintptr_t)va; 	end = (uintptr_t)va + len;
    perm |= PTE_P;
    for (cur = start; cur < end; cur += PGSIZE) {
        pte = pgdir_walk(env->env_pgdir, (void *)cur, 0);
        if (cur >= ULIM || pte == NULL || (*pte & perm) != perm) {
            user_mem_check_addr = cur;
            return -E_FAULT;
        }
        cur = ROUNDDOWN(cur, PGSIZE);
    }
    return 0;
}
```



#### 11.3 kern/system.c

```c
static void sys_cputs(const char *s, size_t len) {
 	// LAB 3: Your code here.
	user_mem_assert(curenv, (void *)s, len, PTE_U);
    
    // Print the string supplied by the user.
	cprintf("%.*s", len, s);
}
```



#### 11.4 debuginfo_eip()

```c
    // LAB 3: Your code here.
    if (user_mem_check(curenv, (void *)USTABDATA, sizeof(struct UserStabData), PTE_U) < 0) 				return -1;

    /* ... */

    // LAB 3: Your code here.
    if (user_mem_check(curenv, (void *)stabs, stab_end - stabs, PTE_U) < 0)
        return -1;
    if (user_mem_check(curenv, (void *)stabstr, stabstr_end - stabstr, PTE_U) < 0)
        return -1;
```



### Exercise 12

> **Exercise 12.** Boot your kernel, running `user/evilhello` . The environment should be destroyed, and the kernel should not panic. You should see: 
>
> ```sh
>     [00000000] new env 00001000 ...
>     [00001000] user_mem_check assertion failure for va f010000c
>     [00001000] free env 00001000
> ```



### Exercise 13

> **Exercise 13.** `evilhello2.c` want to perform some privileged operations in function `evil()` . Function `ring0_call()` takes an function pointer as argument. It calls the provided function pointer with ring0 privilege and then return to ring3. There's few ways to achieve it. You should follow the instructions in the comments to enter ring0.
>
> sgdt is an unprivileged instruction in x86 architecture. It stores the GDT descripter into a provided memory location. After mapping the page contains GDT into user space, we could setup an callgate in GDT. Callgate is one of the cross-privilege level control transfer mechanisms in x86 architecture. After setting up the call gate.
> Applications may use lcall (far call) instruction to call into the segment specified in callgate entry (For example, kernel code segment). After that, lret instruction could be used to return to the original segment. For more information on Callgate. Please refer to intel documents.
>
> Finish `ring0_call()` and run `evilhello2.c` , you should see IN RING0!!! followed by a page fault. (the function `evil()` is called twice, one in ring0 and one in ring3).
>
> To make your life easier, some utility macros and data structure are provided in `mmu.h` . (SETCALLGATE, SEG, struct Pseudodesc, struct Gatedesc ...) You could use them to manage GDT.
>
> Note: If you overwrite some GDT entry while setting up the callgate. Please recover them before return to ring3, or your system may not work properly after then.



> `callgate`机制，使得用户程序可以在自身的代码区将权限暂时提高，执行一些原本只有内核有权限执行的指令，而不必使用系统调用。



#### 13.1 ring0_call()

```c
    asm volatile("lcall $0x20, $0");
    // asm volatile(
    //    "lcall %0, $0"
    //    :
    //    :"i"(GD_UD)
    // );
```



#### 13.2 call_fun_ptr()

```c
    // asm volatile("popl %ebp");
    asm volatile("leave");

	/* or */

	asm volatile("popl %ebx");
	asm volatile("popl %ebp");
```

> `leave` 指令：http://c.biancheng.net/view/3638.html



## Questions

> **Question 1.** What is the purpose of having an individual handler function for each exception/interrupt? (i.e., if all exceptions/interrupts were delivered to the same handler, what feature that exists in the current implementation could not be provided?)

- 无法区分是从哪个中断进来的，也就无法设置中断号
- 区分不同的优先级
- 一些终端/异常需要push error code，另外一些不需要



> **Question 2.** Did you have to do anything to make the `user/softint` program behave correctly? The grade script expects it to produce a general protection fault (trap 13), but `softint` 's code says `int $14` . Why should this produce interrupt vector 13? What happens if the kernel actually allows `softint` 's `int $14` instruction to invoke the kernel's page fault handler (which is interrupt vector 14)?

```c
SETGATE(idt[T_PGFLT], 1, GD_KT, ENTRY_PGFLT, 0);	/* dpl = 0 */
```

原因：Page Fault 的权限位设为0，只能由内核抛出，所以调用 `int $14` 会发生 Protection Fault

如果允许  `int $14` ，那么因为 `int` 指令不会将错误码压栈，但是 Page Fault 的中断向量有错误码压栈，会出现栈溢出；如下图所示，`err` 所对应的值“顺补”成了 `eip` 寄存器的值，那么 `ss` 寄存器的值是从 `KSTACKTOP` 处读出的(栈溢出)；

![image-20200731100923065](upload/image-20200731100923065.png)



> **Questions 3.** The break point test case will either generate a break point exception or a general protection fault depending on how you initialized the break point entry in the IDT (i.e., your call to `SETGATE` from `trap_init` ). Why? How do you need to set it up in order to get the breakpoint exception to work as specified above and what incorrect setup would cause it to trigger a general protection fault?

```c
SETGATE(idt[T_BRKPT], 1, GD_KT, ENTRY_BRKPT, 3);	/* dpl = 3 */
```

`dpl` 设为 0，触发 Protection Fault ；设为 1，触发 Breakpoint Exception



>  **Question 4.** What do you think is the point of these mechanisms, particularly in light of what the `user/softint` test program does?

创建该机制是出于安全考虑，只有特权用户（在内核模式下）才能执行敏感操作，例如内存分配。 对于用户模式，可以允许风险较低并且可以由较高特权用户很好地恢复的一些其他操作。