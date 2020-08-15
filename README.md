## 参考链接

>  [1] MP初始化：https://blog.csdn.net/zenny_chen/article/details/6060253
>
>  [2] Linux SMP 启动过程：https://www.linuxidc.com/Linux/2011-10/44532.htm
>
>  [3] <u>LAB4</u>：https://raymo.top/6-828-lab-4/
>
>  [4] <u>LAB4</u>：https://blog.dingbiao.top/2020/07/28/31.html
>
>  [5] LAB4：https://blog.csdn.net/u011368821/article/details/43875961
>
>  [6] LAB4 用户程序分析：https://blog.csdn.net/cinmyheart/article/details/45197685
>
>  [7] JOS 用户态page fault保护处理机制分析：https://blog.csdn.net/cinmyheart/article/details/45271455
>
>  [8] JOS fork函数 实现机制分析：https://blog.csdn.net/cinmyheart/article/details/45342007
>
>  [9] LAB4：https://blog.csdn.net/hjw199666/article/details/103286130
>
>  [10] <u>clever mapping trick</u>： https://pdos.csail.mit.edu/6.828/2018/labs/lab4/uvpt.html
>
>  [11] LAB4：https://www.bbsmax.com/A/LPdoA32BJ3/
>
>  [12] LAB4：https://blog.csdn.net/codes_first/article/details/86558770
>
>  [13] kernel panic on CPU 0 at kern/trap.c:313: assertion failed: !(read_eflags() & FL_IF)：https://www.jianshu.com/p/8d8425e45c49



## 写在前面

> 以下是对lab3的几处修改：

#### mem_init()

```c
/* @ pmap.c */
void mem_init(void) {
	/* ... */

	//////////////////////////////////////////////////////////////////////
	// Map all of physical memory at KERNBASE.
	// Ie.  the VA range [KERNBASE, 2^32) should map to
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
    
	// uint32_t cr4 = rcr4();
	// cr4 |= CR4_PSE;
	// lcr4(cr4);
	// boot_map_region_large(kern_pgdir, KERNBASE, (uint32_t)-1 - KERNBASE, 0, PTE_W);
	
    boot_map_region(kern_pgdir, KERNBASE, ROUNDUP(0x100000000 - KERNBASE, PTSIZE),
						0, PTE_W);

	// Initialize the SMP-related parts of the memory map
	mem_init_mp();

	// Check that the initial page directory has been set up correctly.
	check_kern_pgdir();

	// activate the CR4 register
    uint32_t cr4 = rcr4();
    cr4 = cr4 | CR4_PSE;
    lcr4(cr4);

	/* ... */
}
```



#### syscall()

```c
static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
    int32_t ret;
    
    // Generic system call: pass system call number in AX,
    // up to five parameters in DX, CX, BX, DI, SI.
	// Interrupt kernel with T_SYSCALL.
	//
    // The "volatile" tells the assembler not to optimize
    // this instruction away just because we don't use the
    // return value.
	//
    // The last clause tells the assembler that this can
    // potentially change the condition codes and arbitrary
    // memory locations.
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

/*
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
*/

    if(check && ret > 0)
        panic("syscall %d returned %d (> 0)", num, ret);
    
    return ret;
}
```



#### trap_init()

```c
/* 参考链接：https://www.jianshu.com/p/8d8425e45c49
 * 根据对注释的理解，把 SETGATE 的第二个参数都写成了 1。主要是被注释中的 istrap: 1 for a trap (= exception) gate, 0 for an interrupt gate. 误导。
 * 但是，根据 SETGATE 的注释，其真实的区别在于，设为 1 就会在开始处理中断时将 FL_IF 位重新置1，而设为 0 则保持 FL_IF 位不变。根据这里的需求，显然应该置0。
 */
 void
trap_init(void)
{
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	SETGATE(idt[T_DIVIDE], 0, GD_KT, ENTRY_DIVIDE, 0);
	SETGATE(idt[T_DEBUG], 0, GD_KT, ENTRY_DEBUG, 0);
	SETGATE(idt[T_NMI], 0, GD_KT, ENTRY_NMI, 0);
	SETGATE(idt[T_BRKPT], 0, GD_KT, ENTRY_BRKPT, 3);
	SETGATE(idt[T_OFLOW], 0, GD_KT, ENTRY_OFLOW, 0);
	SETGATE(idt[T_BOUND], 0, GD_KT, ENTRY_BOUND, 0);
	SETGATE(idt[T_ILLOP], 0, GD_KT, ENTRY_ILLOP, 0);
	SETGATE(idt[T_DEVICE], 0, GD_KT, ENTRY_DEVICE, 0);
	SETGATE(idt[T_DBLFLT], 0, GD_KT, ENTRY_DBLFLT, 0);
	/* SETGATE(idt[T_COPROC], 1, GD_KT, ENTRY_COPROC, 0); */
	SETGATE(idt[T_TSS], 0, GD_KT, ENTRY_TSS, 0);
	SETGATE(idt[T_SEGNP], 0, GD_KT, ENTRY_SEGNP, 0);
	SETGATE(idt[T_STACK], 0, GD_KT, ENTRY_STACK, 0);
	SETGATE(idt[T_GPFLT], 0, GD_KT, ENTRY_GPFLT, 0);
	SETGATE(idt[T_PGFLT], 0, GD_KT, ENTRY_PGFLT, 0);
	/* SETGATE(idt[T_RES], 0, GD_KT, ENTRY_RES, 0); */
	SETGATE(idt[T_FPERR], 0, GD_KT, ENTRY_FPERR, 0);
	SETGATE(idt[T_ALIGN], 0, GD_KT, ENTRY_ALIGN, 0);
	SETGATE(idt[T_MCHK], 0, GD_KT, ENTRY_MCHK, 0);
	SETGATE(idt[T_SIMDERR], 0, GD_KT, ENTRY_SIMDERR, 0);

	SETGATE(idt[T_SYSCALL], 0, GD_KT, ENTRY_SYSCALL, 3);

	// Per-CPU setup 
	trap_init_percpu();
}
```



## Part A: Multiprocessor Support and Cooperative Multitasking

### Exercise 1

> **Exercise 1.** Implement `mmio_map_region` in `kern/pmap.c` . To see how this is used, look at
> the beginning of `lapic_init` in `kern/lapic.c` . You'll have to do the next exercise, too,
> before the tests for `mmio_map_region` will run.

```c
void *mmio_map_region(physaddr_t pa, size_t size) {
	static uintptr_t base = MMIOBASE;

	// Your code here:
    // panic("mmio_map_region not implemented");
    
    size = ROUNDUP(pa + size, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    size = size - pa;
    if(base + size >= MMIOLIM){
        panic("mmio_map_region: overflow!");
    }
    boot_map_region(kern_pgdir, base, size, pa, PTE_PCD | PTE_PWT | PTE_W);
    uintptr_t res = base;
    base += size;
    return (void *)res;
}
```



### Exercise 2

> **Exercise 2.** Read `boot_aps()` and `mp_main()` in `kern/init.c` , and the assembly code in
> `kern/mpentry.S` . Make sure you understand the control flow transfer during the bootstrap
> of APs. Then modify your implementation of `page_init()` in `kern/pmap.c` to avoid adding
> the page at `MPENTRY_PADDR` to the free list, so that we can safely copy and run AP
> bootstrap code at that physical address. Your code should pass the updated
> `check_page_free_list()` test (but might fail the updated `check_kern_pgdir()` test, which
> we will fix soon).

```c
pages[PGNUM(MPENTRY_PADDR)].pp_ref = 1;
pages[PGNUM(MPENTRY_PADDR)].pp_link = NULL;

for (i = 1; i < npages; i++) {
    if (i == PGNUM(MPENTRY_PADDR)){
        continue;
    }
    /* ... */
}
```



### Question 1

> **Question 1.** Compare `kern/mpentry.S` side by side with `boot/boot.S` . Bearing in mind that
> `kern/mpentry.S` is compiled and linked to run above `KERNBASE` just like everything
> else in the kernel, what is the purpose of macro `MPBOOTPHYS` ? Why is it necessary in
> `kern/mpentry.S` but not in `boot/boot.S` ? In other words, what could go wrong if it
> were omitted in `kern/mpentry.S` ?
>
> Hint: recall the differences between the link address and the load address that we
> have discussed in Lab 1.

`kern/mpentry.S` 被链接到高位的虚拟地址，但是被加载到低位的物理地址：

```c
static void boot_aps(void) {
    /* ... */
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
    /* ... */
}
```

 `MPBOOTPHYS` 将高位地址转换位低位地址



### Exercise 3

> **Exercise 3.** Modify `mem_init_mp()` (in `kern/pmap.c` ) to map per-CPU stacks starting at
> `KSTACKTOP` , as shown in `inc/memlayout.h` . The size of each stack is `KSTKSIZE` bytes plus
> `KSTKGAP` bytes of unmapped guard pages. Your code should pass the new check in
> `check_kern_pgdir()` .

```c
static void mem_init_mp(void) {
    // LAB 4: Your code here:
    int i;
    uintptr_t kstacktop_i = KSTACKTOP - KSTKSIZE;
    for (i = 0; i < NCPU; i++){
        boot_map_region(kern_pgdir,
                        kstacktop_i,
                        KSTKSIZE,
                        PADDR(percpu_kstacks[i]),
                        PTE_W);
        kstacktop_i -= KSTKSIZE + KSTKGAP;
    }
}
```



### Exercise 4

> **Exercise 4.** The code in `trap_init_percpu()` ( `kern/trap.c` ) initializes the TSS and TSS
> descriptor for the BSP. It worked in Lab 3, but is incorrect when running on other CPUs.
> Change the code so that it can work on all CPUs. (Note: your new code should not use
> the global `ts` variable any more.)

```c
void trap_init_percpu(void) {
	// LAB 4: Your code here:
    
    // Setup a TSS so that we get the right stack
    // when we trap to the kernel.
	uint8_t cpuid = thiscpu->cpu_id;
    struct Taskstate *cputs = &(thiscpu->cpu_ts);
    
    // Setup a TSS so that we get the right stack
    // when we trap to the kernel.
	cputs->ts_esp0 = KSTACKTOP - cpuid * (KSTKGAP + KSTKSIZE);
    cputs->ts_ss0 = GD_KD; 	cputs->ts_iomb = sizeof(struct Taskstate);
    
    // Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + cpuid] = SEG16(STS_T32A, (uint32_t) (cputs), 					sizeof(struct Taskstate) - 1, 0);
    gdt[(GD_TSS0 >> 3) + cpuid].sd_s = 0;
    
    wrmsr(0x174, GD_KT, 0);				/* SYSENTER_CS_MSR */
    wrmsr(0x175, cputs->ts_esp0, 0);	/* SYSENTER_ESP_MSR */
    wrmsr(0x176, sysenter_handler, 0);	/* SYSENTER_EIP_MSR */
    
    // Load the TSS selector (like other segment selectors, the
    // bottom three bits are special; we leave them 0)
    ltr(GD_TSS0 + (cpuid << 3));
    
    // Load the IDT
    lidt(&idt_pd);
}
```



### Exercise 5

> **Exercise 5.** Apply the big kernel lock as described above, by calling `lock_kernel()` and
> `unlock_kernel()` at the proper locations.



#### 5.1 i386_init()

```c
    // Acquire the big kernel lock before waking up APs
    // Your code here:
    lock_kernel();
```



#### 5.2 mp_main()

```c
    // Now that we have finished some basic setup, call sched_yield()
    // to start running processes on this CPU.  But make sure that
    // only one CPU can enter the scheduler at a time!
    //
    // Your code here:
    lock_kernel();
    sched_yield();
```



#### 5.3 trap()

```c
    // Trapped from user mode.
    // Acquire the big kernel lock before doing any
    // serious kernel work.
    // LAB 4: Your code here.
    lock_kernel();
    assert(curenv);
```



#### 5.4 env_run()

```c
    unlock_kernel();
    env_pop_tf(&(curenv->env_tf));
```



### Question 2

> **Question 2.** It seems that using the big kernel lock guarantees that only one CPU can run the
> kernel code at a time. Why do we still need separate kernel stacks for each CPU?
> Describe a scenario in which using a shared kernel stack will go wrong, even with the
> protection of the big kernel lock.

因为在 `_alltraps` 到 `lock_kernel()` 的过程中，进程已经切换到了内核态，但并没有上内核锁，此时如果有其他CPU进入内核，如果用同一个内核栈，则 `_alltraps` 中保存的上下文信息会被破坏，所以即使有大内核栈，CPU也不能用用同一个内核栈。同样的，解锁也是在内核态内解锁，在解锁到真正返回用户态这段过程中，也存在上述这种情况。



> *Challenge!* The big kernel lock is simple and easy to use. Nevertheless, it eliminates all
> concurrency in kernel mode. Most modern operating systems use different locks to protect
> different parts of their shared state, an approach called *fine-grained locking*. Fine-grained
> locking can increase performance significantly, but is more difficult to implement and errorprone.
> If you are brave enough, drop the big kernel lock and embrace concurrency in JOS!
>
> It is up to you to decide the locking granularity (the amount of data that a lock protects). As
> a hint, you may consider using spin locks to ensure exclusive access to these shared
> components in the JOS kernel:
>
> - The page allocator.
> - The console driver.
> - The scheduler.
> - The inter-process communication (IPC) state that you will implement in the part C.





### Exercise 6

> **Exercise 6.** Implement round-robin scheduling in `sched_yield()` as described above.
> Don't forget to modify `syscall()` to dispatch `sys_yield()` .
>
> Make sure to invoke `sched_yield()` in `mp_main` .
>
> Modify `kern/init.c` to create three (or more!) environments that all run the program
> `user/yield.c` .
>
> Run `make qemu`. You should see the environments switch back and forth between each
> other five times before terminating, like below.
>
> Test also with several CPUS: `make qemu CPUS=2`.
>
> ```sh
> ...
> Hello, I am environment 00001000.
> Hello, I am environment 00001001.
> Hello, I am environment 00001002.
> Back in environment 00001000, iteration 0.
> Back in environment 00001001, iteration 0.
> Back in environment 00001002, iteration 0.
> Back in environment 00001000, iteration 1.
> Back in environment 00001001, iteration 1.
> Back in environment 00001002, iteration 1.
> ...
> ```
>
> After the `yield` programs exit, there will be no runnable environment in the system, the
> scheduler should invoke the JOS kernel monitor. If any of this does not happen, then fix
> your code before proceeding.



#### 6.1 sched_yield()

```c
void sched_yield(void) {
    struct Env *idle;
    
 	// LAB 4: Your code here.
	idle = curenv; 	size_t i, index = curenv ? ENVX(idle->env_id) : -1;
    
    //从当前进程后一个开始
    for (i = 0; i < NENV; ++i){
        index = (index + 1) % NENV;
        if (envs[index].env_status == ENV_RUNNABLE){
            env_run(&envs[index]);
        }
    }
    
    //没有其他可运行进程，继续执行当前进程
    if(idle && idle->env_status == ENV_RUNNING){
        env_run(idle);
    }
    
    // sched_halt never returns
    sched_halt();
}
```



#### 6.2 kern/syscall()

```c
    /* ... */
    case SYS_yield:
        sys_yield();
        break;
    /* ... */
```



### Question 3

> **Question 3.** In your implementation of `env_run()` you should have called `lcr3()` . Before and
> after the call to `lcr3()` , your code makes references (at least it should) to the
> variable `e` , the argument to `env_run` . Upon loading the `%cr3` register, the
> addressing context used by the MMU is instantly changed. But a virtual address
> (namely `e` ) has meaning relative to a given address context--the address context specifies the physical address to which the virtual address maps. Why can the pointer
> `e` be dereferenced both before and after the addressing switch?

```c
static int env_setup_vm(struct Env *e) {
	/* ... */

	// Now, set e->env_pgdir and initialize the page directory.
	//
	// Hint:
	//    - The VA space of all envs is identical above UTOP
	//	(except at UVPT, which we've set below).
	//	See inc/memlayout.h for permissions and layout.
	//	Can you use kern_pgdir as a template?  Hint: Yes.
	//	(Make sure you got the permissions right in Lab 2.)
	//    - The initial VA below UTOP is empty.
	//    - You do not need to make any more calls to page_alloc.
	//    - Note: In general, pp_ref is not maintained for
	//	physical pages mapped only above UTOP, but env_pgdir
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	memmove(e->env_pgdir, kern_pgdir, NPDENTRIES * sizeof(pde_t));
	memset(e->env_pgdir, 0, PDX(UTOP) * sizeof(pde_t));

    // UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
    e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
    return 0;
}
```

根据上面的代码可知，除了 `UVPT` 之外，所有 `env` 在 `UTOP` 上的虚拟空间都是一样的，因此内核态的页表目录相同；对 `env_run()` 的调用发生在内核态，所以在切换 `%cr3` 前后，对 `e` 或者 `curenv` 的访问都会映射到同一物理地址



### Question 4

> **Question 4.** Whenever the kernel switches from one environment to another, it must ensure the
> old environment's registers are saved so they can be restored properly later. Why?
> Where does this happen?

保存是为了之后可以恢复到原来的环境；保存发生在 `kern/trapentry.S` 中 `_alltraps` 中，恢复发生在 `env_pop_tf()` 中



> *Challenge!* Add a less trivial scheduling policy to the kernel, such as a fixed-priority scheduler that allows each environment to be assigned a priority and ensures that higherpriority environments are always chosen in preference to lower-priority environments. If you're feeling really adventurous, try implementing a Unix-style adjustable-priority scheduler or even a lottery or stride scheduler. (Look up "lottery scheduling" and "stride scheduling" in Google.)  Write a test program or two that verifies that your scheduling algorithm is working correctly (i.e., the right environments get run in the right order). It may be easier to write these test programs once you have implemented `fork()` and IPC in parts B and C of this lab.



> *Challenge!* The JOS kernel currently does not allow applications to use the x86 processor's x87 floating-point unit (FPU), MMX instructions, or Streaming SIMD Extensions (SSE). Extend the `Env` structure to provide a save area for the processor's floating point state, and extend the context switching code to save and restore this state properly when switching from one environment to another. The `FXSAVE` and `FXRSTOR` instructions may be useful, but note that these are not in the old i386 user's manual because they were introduced in more recent processors. Write a user-level test program that does something cool with floating-point.



### Exercise 7

> **Exercise 7.** Implement the system calls described above in `kern/syscall.c` and make
> sure `syscall()` calls them. You will need to use various functions in `kern/pmap.c` and
> `kern/env.c` , particularly `envid2env()` . For now, whenever you call `envid2env()` , pass 1
> in the `checkperm` parameter. Be sure you check for any invalid system call arguments,
> returning `-E_INVAL` in that case. Test your JOS kernel with `user/dumbfork` and make sure
> it works before proceeding.



#### 7.1 sys_exofork()

```c
static envid_t sys_exofork(void) {
	// LAB 4: Your code here.
	// panic("sys_exofork not implemented");

	struct Env *e;
	int res = env_alloc(&e, curenv->env_id);
	if (res < 0){
		return res;
	}
	e->env_status = ENV_NOT_RUNNABLE;
	e->env_tf = curenv->env_tf;
	e->env_tf.tf_regs.reg_eax = 0;
	return e->env_id;
}
```



#### 7.2 sys_env_set_status()

```c
static int sys_env_set_status(envid_t envid, int status) {
	// LAB 4: Your code here.
	// panic("sys_env_set_status not implemented");
	
	struct Env *env_store;

	if (status != ENV_RUNNABLE && status != ENV_NOT_RUNNABLE)
		return -E_INVAL;

	if (envid2env(envid, &env_store, 1) < 0)
		return -E_BAD_ENV;

	env_store->env_status = status;
	return 0;
}
```



#### 7.3 sys_page_alloc()

```c
static int sys_page_alloc(envid_t envid, void *va, int perm) {
	// LAB 4: Your code here.
	// panic("sys_page_alloc not implemented");

	struct Env *env_store;
	struct PageInfo *pp;

	if (envid2env(envid, &env_store, 1) < 0)
		return -E_BAD_ENV;
	if ((uintptr_t)va >= UTOP || PGOFF(va) != 0)
		return -E_INVAL;
	if (~PTE_SYSCALL & perm)
		return -E_INVAL;
	
	pp = page_alloc(ALLOC_ZERO);

	if ((pp = page_alloc(ALLOC_ZERO)) == NULL)
		return -E_NO_MEM;

	if (page_insert(env_store->env_pgdir, pp, va, perm) < 0){
		page_free(pp);
		return -E_NO_MEM;
	}

	return 0;
}
```



#### 7.4 sys_page_map()

```c
static int sys_page_map(envid_t srcenvid, void *srcva,
                        envid_t dstenvid, void *dstva, int perm) {
	// LAB 4: Your code here.
	// panic("sys_page_map not implemented");

	struct Env *srcenv, *dstenv;
	struct PageInfo *pp;
	pte_t *pte_store;

	if ((uintptr_t)srcva >= UTOP || PGOFF(srcva) != 0 || (uintptr_t)dstva >= UTOP || PGOFF(dstva) != 0)
		return -E_INVAL;
	
	if (envid2env(srcenvid, &srcenv, 1) < 0 || envid2env(dstenvid, &dstenv, 1) < 0)
		return -E_BAD_ENV;

	if ((pp = page_lookup(srcenv->env_pgdir, srcva, &pte_store)) == NULL)
		return -E_INVAL;
	
	if (~PTE_SYSCALL & perm)
		return -E_INVAL;
	
	if ((perm & PTE_W) && !(*pte_store & PTE_W))
		return -E_INVAL;
	
	return page_insert(dstenv->env_pgdir, pp, dstva, perm);
}
```



#### 7.5 sys_page_unmap()

```c
static int sys_page_unmap(envid_t envid, void *va) {
	// LAB 4: Your code here.
	// panic("sys_page_unmap not implemented");

	struct Env *env_store;

	if ((uintptr_t)va >= UTOP || PGOFF(va) != 0)
		return -E_INVAL;

	if (envid2env(envid, &env_store, 1) < 0)
		return -E_BAD_ENV;
	
	page_remove(env_store->env_pgdir, va);
	return 0;
}
```



> *Challenge!* Add the additional system calls necessary to read all of the vital state of an existing environment as well as set it up. Then implement a user mode program that forks off a child environment, runs it for a while (e.g., a few iterations of `sys_yield()` ), then takes a complete snapshot or checkpoint of the child environment, runs the child for a while longer, and finally restores the child environment to the state it was in at the checkpoint and continues it from there. Thus, you are effectively "replaying" the execution of the child environment from an intermediate state. Make the child environment perform some interaction with the user using `sys_cgetc()` or `readline()` so that the user can view and mutate its internal state, and verify that with your checkpoint/restart you can give the child environment a case of selective amnesia, making it "forget" everything that happened beyond a certain point.



## Part B: Copy-on-Write Fork

### Exercise 8

> **Exercise 8.** Implement the `sys_env_set_pgfault_upcall` system call. Be sure to enable
> permission checking when looking up the environment ID of the target environment, since
> this is a "dangerous" system call.

```c
static int sys_env_set_pgfault_upcall(envid_t envid, void *func) {
	// LAB 4: Your code here.
	// panic("sys_env_set_pgfault_upcall not implemented");

	struct Env *e;
	if (envid2env(envid, &e, 1) < 0){
		return -E_BAD_ENV;
	}
	
	e->env_pgfault_upcall = func;
	return 0;
}

/* syscall() */
case SYS_env_set_pgfault_upcall:
	return sys_env_set_pgfault_upcall(a1, (void *)a2);
```



### Exercise 9

> **Exercise 9.** Implement the code in `page_fault_handler` in `kern/trap.c` required to
> dispatch page faults to the user-mode handler. Be sure to take appropriate precautions
> when writing into the exception stack. (What happens if the user environment runs out of
> space on the exception stack?)

> 为什么已经在异常栈时，需要下移 32-bit？

```c
void page_fault_handler(struct Trapframe *tf) {
	uint32_t fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs & 0x3) == 0){
		panic("page_fault_handler: kernel-mode page faults");
	}
    
    // LAB 4: Your code here.
	struct UTrapframe *utf;
	
	if (curenv->env_pgfault_upcall){
		if (tf->tf_esp >=  UXSTACKTOP - PGSIZE && tf->tf_esp <= UXSTACKTOP - 1){
			utf = (struct UTrapframe *)(tf->tf_esp - sizeof(struct UTrapframe) - 4);
		} else {
			utf = (struct UTrapframe *)(UXSTACKTOP - sizeof(struct UTrapframe));
		}
		user_mem_assert(curenv, (void *)utf, sizeof(struct UTrapframe), PTE_W);
		utf->utf_fault_va = fault_va;
		utf->utf_err = tf->tf_trapno;
		utf->utf_eip = tf->tf_eip;
		utf->utf_eflags = tf->tf_eflags;
		utf->utf_esp = tf->tf_esp;
		utf->utf_regs = tf->tf_regs;
		curenv->env_tf.tf_eip = (uint32_t)curenv->env_pgfault_upcall;
		curenv->env_tf.tf_esp = (uint32_t)utf;
		env_run(curenv);
	}

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
	env_destroy(curenv);
}    
```



### Exercise 10

> **Exercise 10.** Implement the `_pgfault_upcall` routine in `lib/pfentry.S` . The interesting
> part is returning to the original point in the user code that caused the page fault. You'll
> return directly there, without going back through the kernel. The hard part is
> simultaneously switching stacks and re-loading the EIP.

```assembly
	// LAB 4: Your code here.
	movl 0x28(%esp), %ebx	# trap-time eip
	subl $0x4, 0x30(%esp)	# trap-time esp minus 4
	movl 0x30(%esp), %eax
	movl %ebx, (%eax)		# trap-time esp store trap-time eip
	addl $0x8, %esp

	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	popal

	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
	addl $0x4, %esp
	popfl

	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
	popl %esp

	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
	ret
```



### Exercise 11

> **Exercise 11.** Finish `set_pgfault_handler()` in `lib/pgfault.c` .

```c
void set_pgfault_handler(void (*handler)(struct UTrapframe *utf)) {
	int r;

	if (_pgfault_handler == 0) {
		// First time through!
		// LAB 4: Your code here.
		// panic("set_pgfault_handler not implemented");

		sys_page_alloc(sys_getenvid(), (void *) (UXSTACKTOP - PGSIZE), PTE_SYSCALL);
		sys_env_set_pgfault_upcall(sys_getenvid(), _pgfault_upcall);
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
}
```



> *Challenge!* Extend your kernel so that not only page faults, but all types of processor
> exceptions that code running in user space can generate, can be redirected to a usermode
> exception handler. Write user-mode test programs to test user-mode handling of
> various exceptions such as divide-by-zero, general protection fault, and illegal opcode.



### Exercise 12

> **Exercise 12.** Implement `fork` , `duppage` and `pgfault` in `lib/fork.c` .
>
> Test your code with the `forktree` program. It should produce the following messages,
> with interspersed 'new env', 'free env', and 'exiting gracefully' messages. The messages
> may not appear in this order, and the environment IDs may be different.
>
> ```sh
> 1000: I am ''
> 1001: I am '0'
> 2000: I am '00'
> 2001: I am '000'
> 1002: I am '1'
> 3000: I am '11'
> 3001: I am '10'
> 4000: I am '100'
> 1003: I am '01'
> 5000: I am '010'
> 4001: I am '011'
> 2002: I am '110'
> 1004: I am '001'
> 1005: I am '111'
> 1006: I am '101'
> ```

> clever mapping trick： https://pdos.csail.mit.edu/6.828/2018/labs/lab4/uvpt.html
>
> ​	利用二级页表机制，通过插入no-op指针（其中一个页目录项指针指回页目录），使得我们可以直接通过虚拟地址访问到页目录和页表。COW的其他实现还是比较容易理解的。
>
> fork机制：https://blog.csdn.net/cinmyheart/article/details/45342007



>  https://raymo.top/6-828-lab-4/
>
> - 为什么父子env都要标记COW？因为如果父env不做标记，对页的内容进行了合法修改，子env一无所知，就会读取到错误信息。
> - 为什么在pgfault中不同时将父子env都标为PTE_W，取消PTE_COW呢？这是因为父env可能fork了很多子env，甚至还会嵌套，这就回到了上一个问题。
> - 那如果父子env都触发了页错误，都在新的物理地址存入了数据，那原来共享的那页不就成了垃圾内存？这种现象不会发生，因为在pgfault中，我们调用sys_page_map时需要调用page_insert，而如果当前有页的话会调用page_remove，在page_remove中，我们会调用page_decref，它不仅会将页的引用-1，也会在引用为0的时候调用page_free，所以如果真的出现上面的情况，我们是可以回收的。
> - 为什么先对子env进行COW标记再对父env进行COW标记？这是因为我们运行在父env下，如果在父env标记COW后子env标记COW前写这一页，就会导致页错误，父env的虚拟地址重新映射到了一个新的物理地址且是无COW标记的，这个时候再将子env映射到那里就会出现第一个问题。
> - 为什么某页已经是COW还要再次映射为COW呢？这和上一个问题类似，我们可能在完成操作前触发页错误，导致丢失COW标记。



#### 12.1 fork()

```c
envid_t fork(void) {
	// LAB 4: Your code here.
	// panic("fork not implemented");

	uintptr_t addr;
	envid_t envid;
	int r;

	set_pgfault_handler(pgfault);
	envid = sys_exofork();
	if (envid < 0)
		panic("fork: sys_exofork failed (%e)", envid);
	if (envid == 0){
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}

	for (addr = UTEXT; addr < USTACKTOP; addr += PGSIZE){
		if ((uvpd[PDX(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_P))
			duppage(envid, PGNUM(addr));
	}

	if ((r = sys_page_alloc(envid, (void *)(UXSTACKTOP - PGSIZE), PTE_U | PTE_W | PTE_P)) < 0)
		panic("fork: sys_page_alloc failed (%e)", r);
	
	extern void _pgfault_upcall();

	if ((r = sys_env_set_pgfault_upcall(envid, _pgfault_upcall)) < 0)
		panic("fork: set upcall for child fail (%e)", r);
	
	if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
		panic("sys_env_set_status: (%e)", r);

	return envid;
}
```



#### 12.2 duppage()

```c
static int
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	// panic("duppage not implemented");

	envid_t this_envid = sys_getenvid();
	void *va = (void *)(pn * PGSIZE);

	int perm = uvpt[pn] & 0xFFF;
	if ((perm & PTE_W) || (perm & PTE_COW)){
		perm |= PTE_COW;
		perm &= ~PTE_W;
	}
	perm &= PTE_SYSCALL;
	
	if ((r = sys_page_map(this_envid, va, envid, va, perm)) < 0)
		panic("sys_page_map: %e", r);
	if ((r = sys_page_map(this_envid, va, this_envid, va, perm)) < 0)
		panic("sys_page_map: %e", r);

	return 0;
}
```



#### 12.3 pagfault()

```c
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;

	// LAB 4: Your code here.
	if ((err & FEC_WR) == 0 || (uvpt[PGNUM(addr)] & PTE_COW) == 0)
		panic("pgfault: invalid user trap frame");

	// LAB 4: Your code here.

	// panic("pgfault not implemented");

	envid_t envid = sys_getenvid();
	if ((r = sys_page_alloc(envid, (void *)PFTEMP, PTE_P | PTE_W | PTE_U)) < 0)
		panic("pgfault: page allocation failed (%e)", r);

	addr = ROUNDDOWN(addr, PGSIZE);
	memmove(PFTEMP, addr, PGSIZE);
	// if ((r = sys_page_unmap(envid, addr)) < 0)
	// 	panic("pgfault: page unmap failed (%e)", r);
	if ((r = sys_page_map(envid, PFTEMP, envid, addr, PTE_P | PTE_W | PTE_U)) < 0)
		panic("pgfault: page map failed (%e)", r);
	if ((r = sys_page_unmap(envid, PFTEMP)) < 0)
		panic("pgfault: page unmap failed (%e)", r);
}
```



> *Challenge!* Implement a shared-memory `fork()` called `sfork()` . This version should
> have the parent and child share all their memory pages (so writes in one environment
> appear in the other) except for pages in the stack area, which should be treated in the
> usual copy-on-write manner. Modify `user/forktree.c` to use `sfork()` instead of regular
> `fork()` . Also, once you have finished implementing IPC in part C, use your `sfork()` to
> run `user/pingpongs` . You will have to find a new way to provide the functionality of the
> global `thisenv` pointer.



> *Challenge!* Your implementation of `fork` makes a huge number of system calls. On the
> x86, switching into the kernel using interrupts has non-trivial cost. Augment the system
> call interface so that it is possible to send a batch of system calls at once. Then change
> `fork` to use this interface.
>
> How much faster is your new `fork` ?
>
> You can answer this (roughly) by using analytical arguments to estimate how much of an
> improvement batching system calls will make to the performance of your `fork` : How
> expensive is an `int 0x30` instruction? How many times do you execute `int 0x30` in your
> `fork` ? Is accessing the `TSS` stack switch also expensive? And so on...
>
> Alternatively, you can boot your kernel on real hardware and really benchmark your code.
> See the `RDTSC` (read time-stamp counter) instruction, defined in the IA32 manual, which
> counts the number of clock cycles that have elapsed since the last processor reset.
> QEMU doesn't emulate this instruction faithfully (it can either count the number of virtual
> instructions executed or use the host TSC, neither of which reflects the number of cycles a
> real CPU would require).



## Part C: Preemptive Multitasking and Inter-Process communication(IPC)

### Exercise 13

> **Exercise 13.** Modify `kern/trapentry.S` and `kern/trap.c` to initialize the appropriate
> entries in the IDT and provide handlers for IRQs 0 through 15. Then modify the code in
> `env_alloc()` in `kern/env.c` to ensure that user environments are always run with
> interrupts enabled.
>
> Also uncomment the `sti` instruction in `sched_halt()` so that idle CPUs unmask
> interrupts.
>
> The processor never pushes an error code when invoking a hardware interrupt handler.
> You might want to re-read section 9.2 of the 80386 Reference Manual, or section 5.8 of
> the IA-32 Intel Architecture Software Developer's Manual, Volume 3 at this time.
>
> After doing this exercise, if you run your kernel with any test program that runs for a nontrivial
> length of time (e.g., `spin` ), you should see the kernel print trap frames for hardware
> interrupts. While interrupts are now enabled in the processor, JOS isn't yet handling them,
> so you should see it misattribute each interrupt to the currently running user environment
> and destroy it. Eventually it should run out of environments to destroy and drop into the
> monitor.



> IDT表项中的每一项都初始化为中断门，这样在发生任何中断/异常的时候，陷入内核态的时候，CPU都会将%eflags寄存器上的FL_IF标志位清0



#### 13.1 trapentry.S

```asm
TRAPHANDLER_NOEC(ENTRY_TIMER, IRQ_OFFSET + IRQ_TIMER)
TRAPHANDLER_NOEC(ENTRY_KBD, IRQ_OFFSET + IRQ_KBD)
TRAPHANDLER_NOEC(ENTRY_SERIAL, IRQ_OFFSET + IRQ_SERIAL)
TRAPHANDLER_NOEC(ENTRY_SPURIOUS, IRQ_OFFSET + IRQ_SPURIOUS)
TRAPHANDLER_NOEC(ENTRY_IDE, IRQ_OFFSET + IRQ_IDE)
TRAPHANDLER_NOEC(ENTRY_ERROR, IRQ_OFFSET + IRQ_ERROR)
```



#### 13.2 trap_init()

```c
extern void ENTRY_TIMER();
extern void ENTRY_KBD();
extern void ENTRY_SERIAL();
extern void ENTRY_SPURIOUS();
extern void ENTRY_IDE();
extern void ENTRY_ERROR();

void
trap_init(void)
{
	/* ... */
	SETGATE(idt[IRQ_OFFSET + IRQ_TIMER], 0, GD_KT, ENTRY_TIMER, 0);
	SETGATE(idt[IRQ_OFFSET + IRQ_KBD], 0, GD_KT, ENTRY_KBD, 0);
	SETGATE(idt[IRQ_OFFSET + IRQ_SERIAL], 0, GD_KT, ENTRY_SERIAL, 0);
	SETGATE(idt[IRQ_OFFSET + IRQ_SPURIOUS], 0, GD_KT, ENTRY_SPURIOUS, 0);
	SETGATE(idt[IRQ_OFFSET + IRQ_IDE], 0, GD_KT, ENTRY_IDE, 0);
	SETGATE(idt[IRQ_OFFSET + IRQ_ERROR], 0, GD_KT, ENTRY_ERROR, 0);

	/* ... */
}
```



#### 13.3 env_alloc()

```c
	// Enable interrupts while in user mode.
	// LAB 4: Your code here.
	e->env_tf.tf_eflags |= FL_IF;
```



#### 13.4 sched_halt()

```c
	// Uncomment the following line after completing exercise 13
	"sti\n"		/* cli禁止中断，sli允许中断 */
```



### Exercise 14

> **Exercise 14.** Modify the kernel's `trap_dispatch()` function so that it calls `sched_yield()`
> to find and run a different environment whenever a clock interrupt takes place.
>
> You should now be able to get the `user/spin` test to work: the parent environment should
> fork off the child, `sys_yield()` to it a couple times but in each case regain control of the
> CPU after one time slice, and finally kill the child environment and terminate gracefully.



```c
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_TIMER){
        // 回应8259A CPU已经收到中断
        lapic_eoi();
        sched_yield();
        return;
    }
```



### Exercise 15

> **Exercise 15.** Implement `sys_ipc_recv` and `sys_ipc_try_send` in `kern/syscall.c` . Read
> the comments on both before implementing them, since they have to work together. When
> you call `envid2env` in these routines, you should set the `checkperm` flag to 0, meaning
> that any environment is allowed to send IPC messages to any other environment, and the
> kernel does no special permission checking other than verifying that the target envid is
> valid.
>
> Then implement the `ipc_recv` and `ipc_send` functions in `lib/ipc.c` .
>
> Use the `user/pingpong` and `user/primes` functions to test your IPC mechanism.
> user/primes will generate for each prime number a new environment until JOS runs out
> of environments. You might find it interesting to read `user/primes.c` to see all the forking
> and IPC going on behind the scenes.



#### 15.1 sys_ipc_recv()

```c
static int sys_ipc_recv(void *dstva) {
	// LAB 4: Your code here.
	// panic("sys_ipc_recv not implemented");

	if ((uint32_t) dstva < UTOP ) {
        if (PGOFF(dstva))
            return -E_INVAL;
    }
    // 大于小于都可以赋值为desva。
    curenv->env_ipc_dstva = dstva;
    curenv->env_status = ENV_NOT_RUNNABLE;
    curenv->env_ipc_recving = true;
    curenv->env_ipc_from = 0;
    sched_yield();
    return 0;
}
```



#### 15.2 sys_ipc_try_send()

```c
static int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, unsigned perm)
{
	// LAB 4: Your code here.
	// panic("sys_ipc_try_send not implemented");

	struct Env *dstenv;
    pte_t *pte;
    struct PageInfo *pp;
    int r;

    if ((r = envid2env(envid, &dstenv, 0)) < 0)
        return r;
    
    // 不处于等待接收状态， 或有进程已经请求发送数据
    if ((dstenv->env_ipc_recving != true)  || dstenv->env_ipc_from != 0)
        return -E_IPC_NOT_RECV;

    if ((uint32_t)srcva < UTOP){
        if (PGOFF(srcva))
            return -E_INVAL;
        if (!(perm & PTE_P) || !(perm & PTE_U))
            return -E_INVAL;
        if (perm & (~ PTE_SYSCALL))
            return -E_INVAL;
        
        if ((pp = page_lookup(curenv->env_pgdir, srcva, &pte)) == NULL )
            return -E_INVAL;
        
        if ((perm & PTE_W) && !(*pte & PTE_W) )
            return -E_INVAL;

        // 接收进程愿意接收一个页
        if (dstenv->env_ipc_dstva) {
            // 开始映射
            if( (r = page_insert(dstenv->env_pgdir, pp, dstenv->env_ipc_dstva,  perm)) < 0)
                return r;
            dstenv->env_ipc_perm = perm;
        }
    }
    
    dstenv->env_ipc_from = curenv->env_id;
    dstenv->env_ipc_recving = false;
    dstenv->env_ipc_value = value;
    dstenv->env_status = ENV_RUNNABLE;
    // 返回值
    dstenv->env_tf.tf_regs.reg_eax = 0;
    return 0;
}
```



#### 15.3 ipc_recv()

```c
int32_t ipc_recv(envid_t *from_env_store, void *pg, int *perm_store) {
	// LAB 4: Your code here.
	// panic("ipc_recv not implemented");

	int r;
    if (!pg)
        pg = (void *)UTOP;
    r = sys_ipc_recv(pg);

    if (from_env_store)
        *from_env_store = r < 0 ? 0 : thisenv->env_ipc_from;
    if (perm_store)
        *perm_store = r < 0 ? 0:thisenv->env_ipc_perm;
    if (r < 0)
        return r;
    else
        return thisenv->env_ipc_value;
}
```



#### 15.4 ipc_send()

```c
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
	// LAB 4: Your code here.
	// panic("ipc_send not implemented");
	
	int r;
    if (!pg)
        pg = (void *)UTOP;
    
    do {
        r = sys_ipc_try_send(to_env, val, pg, perm);
        if (r == -E_IPC_NOT_RECV){
            // 用户级程序不能直接调用 sched_yeild();
            sys_yield();
        } else if ((r != -E_IPC_NOT_RECV) && (r < 0)){
            panic("ipc_send failed (%e)\n", r);
        }
    } while (r < 0);
}
```





> *Challenge!* Why does `ipc_send` have to loop? Change the system call interface so it
> doesn't have to. Make sure you can handle multiple environments trying to send to one
> environment at the same time.



> *Challenge!* The prime sieve is only one neat use of message passing between a large
> number of concurrent programs. Read C. A. R. Hoare, ``Communicating Sequential
> Processes,'' *Communications of the ACM* 21(8) (August 1978), 666-667, and implement
> the matrix multiplication example.



> *Challenge!* One of the most impressive examples of the power of message passing is
> Doug McIlroy's power series calculator, described in [M. Douglas McIlroy, ``Squinting at
> Power Series,'' Software--Practice and Experience, 20(7) (July 1990), 661-683](https://swtch.com/~rsc/thread/squint.pdf). Implement
> his power series calculator and compute the power series for *sin(x+x^3)*.



> *Challenge!* Make JOS's IPC mechanism more efficient by applying some of the techniques
> from Liedtke's paper, [Improving IPC by Kernel Design](http://dl.acm.org/citation.cfm?id=168633), or any other tricks you may think
> of. Feel free to modify the kernel's system call API for this purpose, as long as your code
> is backwards compatible with what our grading scripts expect.