/* See COPYRIGHT for copyright information. */

#include <inc/x86.h>
#include <inc/error.h>
#include <inc/string.h>
#include <inc/assert.h>

#include <kern/env.h>
#include <kern/pmap.h>
#include <kern/trap.h>
#include <kern/syscall.h>
#include <kern/console.h>

// Print a string to the system console.
// The string is exactly 'len' characters long.
// Destroys the environment on memory errors.
static void
sys_cputs(const char *s, size_t len)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, (void *)s, len, PTE_U);

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
}

// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
}

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
}

// Destroy a given environment (possibly the currently running environment).
//
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
static int
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
		return r;
	if (e == curenv)
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
	env_destroy(e);
	return 0;
}

static int
sys_map_kernel_page(void* kpage, void* va)
{
    int r;
    struct PageInfo* p = pa2page(PADDR(kpage));
    if (p == NULL)
        return E_INVAL;
    r = page_insert(curenv->env_pgdir, p, va, PTE_U | PTE_W);
    return r;
}

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

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	// panic("syscall not implemented");

	switch (syscallno) {
		case SYS_cputs:
			sys_cputs((char *)a1, (size_t)a2);
			break;
		case SYS_cgetc:
			return sys_cgetc();
		case SYS_getenvid:
			return sys_getenvid();
		case SYS_env_destroy:
			return sys_env_destroy((envid_t)a1);
    	case SYS_map_kernel_page:
			return sys_map_kernel_page((void *)a1, (void *)a2);
    	case SYS_sbrk:
			return sys_sbrk(a1);
	default:
		return -E_INVAL;
	}

	return 0;
}

