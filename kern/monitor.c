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
#include <kern/pmap.h>

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
	{ "backtrace", "Backtrace all fun. callings", mon_backtrace },
	{ "showmap", "Show pages mapped between args", mon_showmap },
};
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

unsigned read_eip();

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{

	uint32_t ebp_x = read_ebp();
	struct Eipdebuginfo info;
	
	cprintf("Stack backtrace:\n");
	
	do
	{
		uint32_t eip_x = *((uint32_t*)(ebp_x + 4));
		uint32_t arg_1 = *((uint32_t*)(ebp_x + 8));
		uint32_t arg_2 = *((uint32_t*)(ebp_x + 12));
		uint32_t arg_3 = *((uint32_t*)(ebp_x + 16));
		uint32_t arg_4 = *((uint32_t*)(ebp_x + 20));
		uint32_t arg_5 = *((uint32_t*)(ebp_x + 24));
		
		debuginfo_eip((uintptr_t)eip_x, &info);
		
		cprintf("  ebp %08x  eip %08x  ", ebp_x, eip_x);
	    cprintf("args %08x %08x %08x %08x %08x\n", arg_1, arg_2, arg_3, arg_4, arg_5);
	   
	    cprintf("         %s:%d: ", info.eip_file, info.eip_line);
	    
	    int i;
	    for(i = 0; i < info.eip_fn_namelen; i++)
			cprintf("%c", info.eip_fn_name[i]);
			
		uintptr_t offs = (uintptr_t)eip_x - info.eip_fn_addr;	
		cprintf("+%d\n", (int)offs);
	    
		ebp_x = *((uint32_t*)ebp_x);
	} 
	while((ebp_x <= 0xf0110000) && (ebp_x != 0x0));
	
	return 0;
}

static int
show_flags(pde_t* entry)
{
	if( *entry | PTE_P )
		cprintf("P ");
	if( *entry | PTE_W )
		cprintf("W ");
	if( *entry | PTE_U )
		cprintf("U ");
	if( *entry | PTE_PWT )
		cprintf("PWT ");
	if( *entry | PTE_A )
		cprintf("A ");
	if( *entry | PTE_G )
		cprintf("G ");
		
	cprintf("\n");
	
	return 0;
}

int
mon_showmap(int argc, char** argv, struct Trapframe *tf)
{

	uintptr_t va;
	pde_t* pgdir = KADDR(rcr3());
	pde_t *pgdir_entry, *ptbl_entry, *page_entry;
	
	if( argc != 2 ) {
		cprintf("incorrect number of arguments\n");
		return 0;
	}
	
	va = strtol(argv[1], NULL, 16);
	
    pgdir_entry = pgdir + PDX(va);
	
	if( !( *pgdir_entry | PTE_P) ) {
		cprintf("Not mapped!\n");
		return 0;
	}
	cprintf("Dir.entry flags: ");
	show_flags(pgdir_entry);
	
	ptbl_entry = (pde_t*)KADDR(PTE_ADDR(*pgdir_entry)) + PTX(va) ; 
	
	if( !( *ptbl_entry | PTE_P) ) {
		cprintf("Not mapped!\n");
		return 0;
	}
	cprintf("Tbl.entry flags: ");
	show_flags(ptbl_entry);
	
	page_entry = (pde_t*)PTE_ADDR(*ptbl_entry) + PGOFF(va);
	
	cprintf("%p\n", page_entry);
	
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
	for (i = 0; i < NCOMMANDS; i++) {
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


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}

// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
	return callerpc;
}
