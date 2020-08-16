// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>
#include <kern/trap.h>

#define CMDBUF_SIZE	80	// enough for one VGA text line


struct Command {
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
	{ "backtrace", "Display backtrace info", mon_backtrace },
	{ "time", "Time [command]", mon_time },
};

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int
mon_time(int argc, char **argv, struct Trapframe *tf) {
	if (argc != 2)
		return -1;
	uint64_t before, after;
	int i;
	struct Command command;
	/* search */
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(commands[i].name, argv[1]) == 0) {
			break;
		}
	}
	if (i == ARRAY_SIZE(commands))
        return -1;
    /* run */
	before = read_tsc();
	(commands[i].func)(1, argv+1, tf);
	after = read_tsc();
	cprintf("%s cycles: %d\n", commands[i].name, after - before);
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

// Lab1 only
// read the pointer to the retaddr on the stack
static uint32_t
read_pretaddr() {
    uint32_t pretaddr;
    __asm __volatile("leal 4(%%ebp), %0" : "=r" (pretaddr)); 
    return pretaddr;
}

void
do_overflow(void)
{
    cprintf("Overflow success\n");
}

void
start_overflow(void)
{
	// You should use a techique similar to buffer overflow
	// to invoke the do_overflow function and
	// the procedure must return normally.

    // And you must use the "cprintf" function with %n specifier
    // you augmented in the "Exercise 9" to do this job.

    // hint: You can use the read_pretaddr function to retrieve 
    //       the pointer to the function call return address;

    char str[256] = {};
    int nstr = 0;
    char *pret_addr;

	// Your code here.
    pret_addr = (char*)read_pretaddr();	// 读取eip所在的地址
    
    // 原本的ret addr：0xf0100ba8(overflow_me)
    cprintf("old rip: %lx\n", *(uint32_t*)pret_addr);	
    cprintf("%52d%n\n",nstr, pret_addr);	// 更改 0xa8 -> 0x34
    cprintf("%10d%n\n",nstr, pret_addr+1);	// 更改 0x0b -> 0x0a 
    // 新的ret addr: 0xf0100a34(do_overflow)
    cprintf("new rip: %lx\n", *(uint32_t*)pret_addr);	

    //	在8(%ebp)处填入原本的ret addr，这样do_overflow才能正常return
    cprintf("%168d%n\n",nstr, pret_addr+4);	// 填入0xa8
    cprintf("%11d%n\n", nstr, pret_addr+5);	// 填入0x0b
    cprintf("%16d%n\n",nstr, pret_addr+6);	// 填入0x10
    cprintf("%240d%n\n",nstr, pret_addr+7);	// 填入0xf0
}

void
overflow_me(void)
{
        start_overflow();
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	cprintf("Stack backtrace:\n");
	uint32_t ebp = read_ebp();
	// 读取%ebp寄存器中的值，%ebp指向当前帧，（%ebp）指向上一帧
	while(ebp != 0){	// %ebp为0时函数遍历到最外层，backtrace到达终点
		uint32_t eip = *(int*)(ebp + 4);	// 读取(4(%ebp))，即%eip的值
		cprintf("  eip %08x  ebp %08x  args %08x %08x %08x %08x %08x\n",
			eip, ebp,
			*(int*)(ebp+8),*(int*)(ebp+12),*(int*)(ebp+16),*(int*)(ebp+20),*(int*)(ebp+24));
		struct Eipdebuginfo info;
		if(debuginfo_eip(eip,&info) == 0){	// 查找%eip对应函数的相关信息
			cprintf("         %s:%d %.*s+%d\n",
				info.eip_file, info.eip_line,
				info.eip_fn_namelen, info.eip_fn_name, eip-info.eip_fn_addr);
		}
		ebp = *(int*)ebp;	// 更新ebp，下一轮循环将输出外一层函数的相关信息
	}
	overflow_me();
    	cprintf("Backtrace success\n");
	return 0;
}



/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void
monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");

	if (tf != NULL)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}