/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>

#include <kern/picirq.h>


###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

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
TRAPHANDLER(ENTRY_ALIGN, T_ALIGN)
TRAPHANDLER_NOEC(ENTRY_MCHK, T_MCHK)
TRAPHANDLER_NOEC(ENTRY_SIMDERR, T_SIMDERR)

TRAPHANDLER_NOEC(ENTRY_SYSCALL, T_SYSCALL)

/*
 * lab4
 */
TRAPHANDLER_NOEC(ENTRY_TIMER, IRQ_OFFSET + IRQ_TIMER)
TRAPHANDLER_NOEC(ENTRY_KBD, IRQ_OFFSET + IRQ_KBD)
TRAPHANDLER_NOEC(ENTRY_SERIAL, IRQ_OFFSET + IRQ_SERIAL)
TRAPHANDLER_NOEC(ENTRY_SPURIOUS, IRQ_OFFSET + IRQ_SPURIOUS)
TRAPHANDLER_NOEC(ENTRY_IDE, IRQ_OFFSET + IRQ_IDE)
TRAPHANDLER_NOEC(ENTRY_ERROR, IRQ_OFFSET + IRQ_ERROR)

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
