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
 # faults and interrupts
TRAPHANDLER_NOEC(DIVIDE,T_DIVIDE)
TRAPHANDLER_NOEC(DEBUG,T_DEBUG)
TRAPHANDLER_NOEC(NMI, T_NMI)
TRAPHANDLER_NOEC(BRKPT, T_BRKPT)
TRAPHANDLER_NOEC(OFLOW, T_OFLOW)
TRAPHANDLER_NOEC(BOUND, T_BOUND)
TRAPHANDLER_NOEC(ILLOP, T_ILLOP)
TRAPHANDLER_NOEC(DEVICE, T_DEVICE)
TRAPHANDLER(DBLFLT, T_DBLFLT)
TRAPHANDLER(TSS, T_TSS)
TRAPHANDLER(SEGNP, T_SEGNP)
TRAPHANDLER(STACK, T_STACK)
TRAPHANDLER(GPFLT, T_GPFLT)
TRAPHANDLER(PGFLT, T_PGFLT)
TRAPHANDLER_NOEC(FPERR, T_FPERR)
TRAPHANDLER(ALIGN, T_ALIGN)
TRAPHANDLER_NOEC(MCHK, T_MCHK)
TRAPHANDLER_NOEC(SIMDERR, T_SIMDERR)
TRAPHANDLER_NOEC(SYSCALL, T_SYSCALL)
TRAPHANDLER_NOEC(DEFAULT, T_DEFAULT)
# IRQs
TRAPHANDLER_NOEC(IRQsHandler0, IRQ_OFFSET+IRQ_TIMER)
TRAPHANDLER_NOEC(IRQsHandler1, IRQ_OFFSET+IRQ_KBD)
TRAPHANDLER_NOEC(IRQsHandler2, IRQ_OFFSET+IRQ_SLAVE)
TRAPHANDLER_NOEC(IRQsHandler3, IRQ_OFFSET+3)
TRAPHANDLER_NOEC(IRQsHandler4, IRQ_OFFSET+IRQ_SERIAL)
TRAPHANDLER_NOEC(IRQsHandler5, IRQ_OFFSET+5)
TRAPHANDLER_NOEC(IRQsHandler6, IRQ_OFFSET+6)
TRAPHANDLER_NOEC(IRQsHandler7, IRQ_OFFSET+IRQ_SPURIOUS)
TRAPHANDLER_NOEC(IRQsHandler8, IRQ_OFFSET+8)
TRAPHANDLER_NOEC(IRQsHandler9, IRQ_OFFSET+9)
TRAPHANDLER_NOEC(IRQsHandler10, IRQ_OFFSET+10)
TRAPHANDLER_NOEC(IRQsHandler11, IRQ_OFFSET+11)
TRAPHANDLER_NOEC(IRQsHandler12, IRQ_OFFSET+12)
TRAPHANDLER_NOEC(IRQsHandler13, IRQ_OFFSET+13)
TRAPHANDLER_NOEC(IRQsHandler14, IRQ_OFFSET+IRQ_IDE)
TRAPHANDLER_NOEC(IRQsHandler15, IRQ_OFFSET+15)
; TRAPHANDLER_NOEC(IRQsHandler19, IRQ_OFFSET+IRQ_ERROR)






/*
 * Lab 3: Your code here for _alltraps
 */
 .global _alltraps
 _alltraps:
 /* code below according to the guide */
pushl %ds
pushl %es
pushal
movw $GD_KD, %ax
movw %ax, %ds
movw %ax, %es
pushl %esp
call trap

