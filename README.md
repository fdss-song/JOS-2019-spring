### 测试 lab4

> 转自：https://cs.nyu.edu/~mwalfish/classes/15fa/labs/lab5.html
>
> You should run the pingpong, primes, and forktree test cases from lab 4 again after merging in the new lab 5 code. To do this, you will need to temporarily (1) comment out the `ENV_CREATE(fs_fs)` line in `kern/init.c` (because `fs/fs.c` tries to do some I/O, which JOS does not allow yet), (2) comment out the call to `close_all()` in `lib/exit.c` (this function calls subroutines that you will implement later in the lab, and therefore will panic if called), (3) undo the changes in `env.c` that are on the lab5 branch (specifically, *un*comment `cprintf` in both `env_alloc` (`kern/env.c`) and `env_free` (`kern/env.c`)), and (4) revert `sys_env_destroy` to the lab4 branch version (which means inserting deleted lines before the invocation to `'env_destroy(e);'`).
>
> If your lab 4 code doesn't contain any bugs, the test cases should run fine. Don't proceed until they work. Don't forget to restore the code (undoing (1)--(4)) when you start Exercise 1.
>
> If they don't work, use `git diff lab4` to review all the changes, making sure there isn't any code you wrote for lab4 (or before) missing from lab 5.



![Disk layout](https://pdos.csail.mit.edu/6.828/2016/labs/lab5/disk.png)



![File structure](https://pdos.csail.mit.edu/6.828/2016/labs/lab5/file.png)



### Exercise 1

> **Exercise 1.** `i386_init` identifies the file system environment by passing the type
> `ENV_TYPE_FS` to your environment creation function, `env_create` . Modify `env_create` in
> `env.c` , so that it gives the file system environment I/O privilege, but never gives that
> privilege to any other environment.
>
> Make sure you can start the file environment without causing a General Protection fault.
> You should pass the "fs i/o" test in `make grade`.

```c
	if (type == ENV_TYPE_FS)
		e->env_tf.tf_eflags |= FL_IOPL_MASK;
```



### Question 1

> **Question 1.** Do you have to do anything else to ensure that this I/O privilege setting is saved and restored properly when you subsequently switch from one environment to another?
> Why?

不需要，因为环境切换时，会保存 EFLAGS 设置，切换回时会调用 `env_pop_tf` 恢复



### Exercise 2

> **Exercise 2.** Implement the `bc_pgfault` and `flush_block` functions in `fs/bc.c` .
> `bc_pgfault` is a page fault handler, just like the one your wrote in the previous lab for
> copy-on-write fork, except that its job is to load pages in from the disk in response to a
> page fault. When writing this, keep in mind that (1) `addr` may not be aligned to a block
> boundary and (2) `ide_read` operates in sectors, not blocks.
>
> The `flush_block` function should write a block out to disk if necessary. `flush_block`
> shouldn't do anything if the block isn't even in the block cache (that is, the page isn't
> mapped) or if it's not dirty. We will use the VM hardware to keep track of whether a disk
> block has been modified since it was last read from or written to disk. To see whether a
> block needs writing, we can just look to see if the `PTE_D` "dirty" bit is set in the `uvpt`
> entry. (The `PTE_D` bit is set by the processor in response to a write to that page; see
> 5.2.4.3 in [chapter 5](http://pdos.csail.mit.edu/6.828/2011/readings/i386/s05_02.htm) of the 386 reference manual.) After writing the block to disk,
> `flush_block` should clear the `PTE_D` bit using `sys_page_map` .
>
> Use `make grade` to test your code. Your code should pass "check_bc", "check_super", and "check_bitmap".



#### 2.1 bc_pgfault()

```c
    // LAB 5: you code here:
	addr = ROUNDDOWN(addr, PGSIZE);

	if ((r = sys_page_alloc(0, addr, PTE_P | PTE_U | PTE_W)) < 0)
		panic("sys_page_alloc: %e", r);

	if ((r = ide_read(blockno * BLKSECTS, addr, BLKSECTS)) < 0)
		panic("ide_read: %e", r);
```



#### 2.2 flush_block()

```c
    // LAB 5: Your code here.
	// panic("flush_block not implemented");

	addr = ROUNDDOWN(addr, PGSIZE);
	if (!va_is_mapped(addr) || !va_is_dirty(addr))
		return;

	if ((r = ide_write(blockno * BLKSECTS, addr, BLKSECTS)) < 0)
		panic("ide_write: %e", r);
	
	if ((r = sys_page_map(0, addr, 0, addr, uvpt[PGNUM(addr)] & PTE_SYSCALL)) < 0)
		panic("sys_page_map: %e", r);
```



> *Challenge!* The block cache has no eviction policy. Once a block gets faulted in to it, it
> never gets removed and will remain in memory forevermore. Add eviction to the buffer
> cache. Using the `PTE_A` "accessed" bits in the page tables, which the hardware sets on
> any access to a page, you can track approximate usage of disk blocks without the need to
> modify every place in the code that accesses the disk map region. Be careful with dirty
> blocks.





### Exercise 3

> **Exercise 3.** Use `free_block` as a model to implement `alloc_block` in `fs/fs.c` , which
> should find a free disk block in the bitmap, mark it used, and return the number of that
> block. When you allocate a block, you should immediately flush the changed bitmap block
> to disk with `flush_block` , to help file system consistency.
>
> Use `make grade` to test your code. Your code should now pass "alloc_block".



```c
int alloc_block(void) {
	// LAB 5: Your code here.
	// panic("alloc_block not implemented");

	int blockno;
	for (blockno = 0; blockno < super->s_nblocks; blockno++){
		if (block_is_free(blockno)){
			bitmap[blockno/32] &= ~(1<<(blockno%32));
			flush_block(bitmap+blockno/32);
			return blockno;
		}
	}
	return -E_NO_DISK;
}
```



### Exercise 4

> **Exercise 4.** Implement `file_block_walk` and `file_get_block` . `file_block_walk` maps from a block offset within a file to the pointer for that block in the `struct File` or the indirect block, very much like what `pgdir_walk` did for page tables. `file_get_block` goes one step further and maps to the actual disk block, allocating a new one if necessary.
>
> Use `make grade` to test your code. Your code should pass "file_open", "file_get_block", and "file_flush/file_truncated/file rewrite", and "testfile".



#### 4.1 file_block_walk()

```c
static int
file_block_walk(struct File *f, uint32_t filebno, uint32_t **ppdiskbno, bool alloc)
{
       // LAB 5: Your code here.
       // panic("file_block_walk not implemented");

	int r;

	if (filebno >= NDIRECT + NPDENTRIES)
		return -E_INVAL;

	if (filebno < NDIRECT){
		if (ppdiskbno){
			*ppdiskbno = f->f_direct + filebno;
		}
		return 0;
	}

	if (!f->f_indirect){
		if (!alloc)	return -E_NOT_FOUND;
		if ((r = alloc_block()) < 0) return r;
		f->f_indirect = r;
		memset(diskaddr(r), 0, BLKSIZE);
		flush_block(diskaddr(r));
	}

	if (ppdiskbno)
		*ppdiskbno = (uint32_t *)diskaddr(f->f_indirect) + filebno - NDIRECT;
	
	return 0;
}
```



#### 4.2 file_get_block()

```c
int file_get_block(struct File *f, uint32_t filebno, char **blk) {
       // LAB 5: Your code here.
       // panic("file_get_block not implemented");
	
	uint32_t *ppdiskbno;
	int r;
	
	if ((r = file_block_walk(f, filebno, &ppdiskbno, 1)) < 0)
		return r;
	
	if (*ppdiskbno == 0){
		if ((r = alloc_block()) < 0)
			return r;
		*ppdiskbno = r;
		memset(diskaddr(r), 0, BLKSIZE);
		flush_block(diskaddr(r));
	}

	*blk = diskaddr(*ppdiskbno);
	return 0;
}
```



> *Challenge!* The file system is likely to be corrupted if it gets interrupted in the middle of an operation (for example, by a crash or a reboot). Implement soft updates or journalling to make the file system crash-resilient and demonstrate some situation where the old file system would get corrupted, but yours doesn't.





### Exercise 5

> **Exercise 5.** Implement `serve_read` in `fs/serv.c` .
>
> `serve_read` 's heavy lifting will be done by the already-implemented `file_read` in
> `fs/fs.c` (which, in turn, is just a bunch of calls to `file_get_block` ). `serve_read` just has
> to provide the RPC interface for file reading. Look at the comments and code in
> `serve_set_size` to get a general idea of how the server functions should be structured.
>
> Use `make grade` to test your code. Your code should pass "serve_open/file_stat/file_close"
> and "file_read" for a score of 70/150.



```c
int serve_read(envid_t envid, union Fsipc *ipc) {
	struct Fsreq_read *req = &ipc->read;
	struct Fsret_read *ret = &ipc->readRet;

	if (debug)
		cprintf("serve_read %08x %08x %08x\n", envid, req->req_fileid, req->req_n);

	// Lab 5: Your code here:
	struct OpenFile *po;
	int r;

    if((r = openfile_lookup(envid, req->req_fileid, &po)) < 0)
        return r;
 
    int req_n = req->req_n > PGSIZE ? PGSIZE : req->req_n; //because the max size of ret_buf is PGSIZE

    if((r = file_read(po->o_file, ret->ret_buf, req_n, po->o_fd->fd_offset)) < 0)
        return r;
 
    po->o_fd->fd_offset += r;
    return r;
}
```



### Exercise 6

> **Exercise 6.** Implement `serve_write` in `fs/serv.c` and `devfile_write` in `lib/file.c` .
>
> Use `make grade` to test your code. Your code should pass "file_write", "file_read after
> file_write", "open", and "large file" for a score of 90/150.



#### 6.1 serve_write()

```c
int serve_write(envid_t envid, struct Fsreq_write *req) {
	if (debug)
		cprintf("serve_write %08x %08x %08x\n", envid, req->req_fileid, req->req_n);

	// LAB 5: Your code here.
	// panic("serve_write not implemented");
	struct OpenFile *po;
    int r;

    if((r = openfile_lookup(envid, req->req_fileid, &po)) < 0)
        return r;
 
    int req_n = req->req_n > PGSIZE ? PGSIZE : req->req_n;

    if((r = file_write(po->o_file, req->req_buf, req_n, po->o_fd->fd_offset)) < 0)
        return r;
 
    po->o_fd->fd_offset += r;
    return r;
}
```



#### 6.2 devfile_write()

```c
	// LAB 5: Your code here
	// panic("devfile_write not implemented");
	int r;

	fsipcbuf.write.req_fileid = fd->fd_file.id;
	fsipcbuf.write.req_n = n;
	memmove(fsipcbuf.write.req_buf, buf, n);
	if ((r = fsipc(FSREQ_WRITE, NULL)) < 0)
		return r;
	assert(r <= n);
	assert(r <= PGSIZE);
	return r;
```



### Exercise 7

> **Exercise 7.** `spawn` relies on the new syscall `sys_env_set_trapframe` to initialize the state of the newly created environment. Implement `sys_env_set_trapframe` in `kern/syscall.c` (don't forget to dispatch the new system call in `syscall()` ).
>
> Test your code by running the `user/spawnhello` program from `kern/init.c` , which will attempt to spawn `/hello` from the file system.
> Use `make grade` to test your code.



```c
static int sys_env_set_trapframe(envid_t envid, struct Trapframe *tf) {
	// LAB 5: Your code here.
	// Remember to check whether the user has supplied us with a good
	// address!
	// panic("sys_env_set_trapframe not implemented");
	struct Env *e;
    int r;
 
    if ((r = envid2env(envid, &e, 1)) < 0)
        return r;
    user_mem_assert(e, tf, sizeof(struct Trapframe), 0);
 
    tf->tf_eflags |= FL_IF;
    tf->tf_eflags &= ~FL_IOPL_MASK;        
    tf->tf_cs |= 0x3;
    e->env_tf = *tf;
    return 0;
}

/* syscall() */
case SYS_env_set_trapframe:
	return sys_env_set_trapframe(a1, (struct Trapframe *)a2);
```



> *Challenge!* Implement Unix-style `exec` .



> *Challenge!* Implement `mmap` -style memory-mapped files and modify `spawn` to map pages directly from the ELF image when possible.



### Exercise 8

> **Exercise 8.** Change `duppage` in `lib/fork.c` to follow the new convention. If the page
> table entry has the `PTE_SHARE` bit set, just copy the mapping directly. (You should use
> `PTE_SYSCALL` , not `0xfff` , to mask out the relevant bits from the page table entry. `0xfff`
> picks up the accessed and dirty bits as well.)
>
> Likewise, implement `copy_shared_pages` in `lib/spawn.c` . It should loop through all page
> table entries in the current process (just like `fork` did), copying any page mappings that
> have the `PTE_SHARE` bit set into the child process.



#### 8.1 duppage()

```c
static int
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	// panic("duppage not implemented");

	envid_t this_envid = sys_getenvid();
	void *va = (void *)(pn * PGSIZE);
	
	if (uvpt[pn] & PTE_SHARE) {
        if((r = sys_page_map(thisenv->env_id, (void *) va, envid, (void * )va, uvpt[pn] & PTE_SYSCALL)) < 0) 
            return r;
    } else if ((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW)) {
        if ((r = sys_page_map(thisenv->env_id, (void *)va, envid, (void *)va, PTE_P | PTE_U | PTE_COW)) < 0)
            return r;
        if ((r = sys_page_map(thisenv->env_id, (void *)va, thisenv->env_id, (void *)va, PTE_P | PTE_U | PTE_COW)) < 0)
            return r;
    } else {
        if((r = sys_page_map(thisenv->env_id, (void *) va, envid, (void * )va, PTE_P | PTE_U)) <0 ) 
            return r;
    }

	return 0;
}
```



#### 8.2 copy_shared_pages()

```c
static int copy_shared_pages(envid_t child) {
	// LAB 5: Your code here.
	uint32_t addr;
    int r;
    for (addr = UTEXT; addr < USTACKTOP; addr += PGSIZE){
        if((uvpd[PDX(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_P)){
			if (uvpt[PGNUM(addr)] & PTE_SHARE){
            	if ((r = sys_page_map(0, (void *)addr, child, (void *)addr, uvpt[PGNUM(addr)] & PTE_SYSCALL)) < 0)
                	return r;
			}
		}
	}
	return 0;
}
```



### Exercise 9

> **Exercise 9.** In your `kern/trap.c` , call `kbd_intr` to handle trap `IRQ_OFFSET+IRQ_KBD` and
> `serial_intr` to handle trap `IRQ_OFFSET+IRQ_SERIAL` .



```c
    // Handle keyboard and serial interrupts.
	// LAB 5: Your code here.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_KBD){
		lapic_eoi();
		kbd_intr();
		return;
	}

	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SERIAL){
		lapic_eoi();
		serial_intr();
		return;
	}
```



### Exercise 10

> **Exercise 10.**
> The shell doesn't support I/O redirection. It would be nice to run `sh <script` instead of
> having to type in all the commands in the script by hand, as you did above. Add I/O
> redirection for < to `user/sh.c` .
>
> Test your implementation by typing `sh <script` into your shell
>
> Run make `run-testshell` to test your shell. `testshell` simply feeds the above commands
> (also found in `fs/testshell.sh` ) into the shell and then checks that the output matches
> `fs/testshell.key` .



```c
    case '<':	// Input redirection
			// Grab the filename from the argument list
			if (gettoken(0, &t) != 'w') {
				cprintf("syntax error: < not followed by word\n");
				exit();
			}

			// LAB 5: Your code here.
			// panic("< redirection not implemented");
			if ((fd = open(t, O_RDONLY)) < 0) {
				cprintf("open %s read: %e", t, fd);
				exit();
			}
			if (fd != 0) {
				dup(fd, 0);
				close(fd);
			}
			break;
```



> *Challenge!* Add more features to the shell. Possibilities include (a few require changes to
> the file system too):
>
> - backgrounding commands ( `ls &` )
> - multiple commands per line ( `ls; echo hi` )
> - command grouping ( `(ls; echo hi) | cat > out` )
> - environment variable expansion ( `echo $hello` )
> - quoting ( `echo "a | b"` )
> - command-line history and/or editing
> - tab completion
> -  directories, cd, and a PATH for command-lookup.
> - file creation
> -  ctl-c to kill the running environment
>
> but feel free to do something not on this list.