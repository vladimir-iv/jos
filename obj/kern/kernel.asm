
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in i386_vm_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 40 1a 10 f0 	movl   $0xf0101a40,(%esp)
f0100055:	e8 cc 08 00 00       	call   f0100926 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 fe 06 00 00       	call   f0100785 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 5c 1a 10 f0 	movl   $0xf0101a5c,(%esp)
f0100092:	e8 8f 08 00 00       	call   f0100926 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 60 29 11 f0       	mov    $0xf0112960,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 3f 14 00 00       	call   f0101504 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 9f 04 00 00       	call   f0100569 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 77 1a 10 f0 	movl   $0xf0101a77,(%esp)
f01000d9:	e8 48 08 00 00       	call   f0100926 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 99 06 00 00       	call   f010078f <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 92 1a 10 f0 	movl   $0xf0101a92,(%esp)
f010012c:	e8 f5 07 00 00       	call   f0100926 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 b6 07 00 00       	call   f01008f3 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 ce 1a 10 f0 	movl   $0xf0101ace,(%esp)
f0100144:	e8 dd 07 00 00       	call   f0100926 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 3a 06 00 00       	call   f010078f <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 aa 1a 10 f0 	movl   $0xf0101aaa,(%esp)
f0100176:	e8 ab 07 00 00       	call   f0100926 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 69 07 00 00       	call   f01008f3 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 ce 1a 10 f0 	movl   $0xf0101ace,(%esp)
f0100191:	e8 90 07 00 00       	call   f0100926 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	00 00                	add    %al,(%eax)
	...

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001b7:	a8 01                	test   $0x1,%al
f01001b9:	74 08                	je     f01001c3 <serial_proc_data+0x15>
f01001bb:	b2 f8                	mov    $0xf8,%dl
f01001bd:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001be:	0f b6 c0             	movzbl %al,%eax
f01001c1:	eb 05                	jmp    f01001c8 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001c8:	5d                   	pop    %ebp
f01001c9:	c3                   	ret    

f01001ca <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	53                   	push   %ebx
f01001ce:	83 ec 04             	sub    $0x4,%esp
f01001d1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001d3:	eb 29                	jmp    f01001fe <cons_intr+0x34>
		if (c == 0)
f01001d5:	85 d2                	test   %edx,%edx
f01001d7:	74 25                	je     f01001fe <cons_intr+0x34>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f01001de:	88 90 40 23 11 f0    	mov    %dl,-0xfeedcc0(%eax)
f01001e4:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f01001e7:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001ed:	0f 94 c0             	sete   %al
f01001f0:	0f b6 c0             	movzbl %al,%eax
f01001f3:	83 e8 01             	sub    $0x1,%eax
f01001f6:	21 c2                	and    %eax,%edx
f01001f8:	89 15 44 25 11 f0    	mov    %edx,0xf0112544
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001fe:	ff d3                	call   *%ebx
f0100200:	89 c2                	mov    %eax,%edx
f0100202:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100205:	75 ce                	jne    f01001d5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100207:	83 c4 04             	add    $0x4,%esp
f010020a:	5b                   	pop    %ebx
f010020b:	5d                   	pop    %ebp
f010020c:	c3                   	ret    

f010020d <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010020d:	55                   	push   %ebp
f010020e:	89 e5                	mov    %esp,%ebp
f0100210:	57                   	push   %edi
f0100211:	56                   	push   %esi
f0100212:	53                   	push   %ebx
f0100213:	83 ec 2c             	sub    $0x2c,%esp
f0100216:	89 c7                	mov    %eax,%edi
f0100218:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010021d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f010021e:	a8 20                	test   $0x20,%al
f0100220:	75 1b                	jne    f010023d <cons_putc+0x30>
f0100222:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100227:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f010022c:	e8 6f ff ff ff       	call   f01001a0 <delay>
f0100231:	89 f2                	mov    %esi,%edx
f0100233:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f0100234:	a8 20                	test   $0x20,%al
f0100236:	75 05                	jne    f010023d <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100238:	83 eb 01             	sub    $0x1,%ebx
f010023b:	75 ef                	jne    f010022c <cons_putc+0x1f>
f010023d:	89 fa                	mov    %edi,%edx
f010023f:	89 f8                	mov    %edi,%eax
f0100241:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100244:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100249:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010024a:	b2 79                	mov    $0x79,%dl
f010024c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010024d:	84 c0                	test   %al,%al
f010024f:	78 1b                	js     f010026c <cons_putc+0x5f>
f0100251:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100256:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f010025b:	e8 40 ff ff ff       	call   f01001a0 <delay>
f0100260:	89 f2                	mov    %esi,%edx
f0100262:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100263:	84 c0                	test   %al,%al
f0100265:	78 05                	js     f010026c <cons_putc+0x5f>
f0100267:	83 eb 01             	sub    $0x1,%ebx
f010026a:	75 ef                	jne    f010025b <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010026c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100271:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100275:	ee                   	out    %al,(%dx)
f0100276:	b2 7a                	mov    $0x7a,%dl
f0100278:	b8 0d 00 00 00       	mov    $0xd,%eax
f010027d:	ee                   	out    %al,(%dx)
f010027e:	b8 08 00 00 00       	mov    $0x8,%eax
f0100283:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100284:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f010028a:	75 06                	jne    f0100292 <cons_putc+0x85>
		c |= 0x0700;
f010028c:	81 cf 00 07 00 00    	or     $0x700,%edi

	switch (c & 0xff) {
f0100292:	89 f8                	mov    %edi,%eax
f0100294:	25 ff 00 00 00       	and    $0xff,%eax
f0100299:	83 f8 09             	cmp    $0x9,%eax
f010029c:	74 7b                	je     f0100319 <cons_putc+0x10c>
f010029e:	83 f8 09             	cmp    $0x9,%eax
f01002a1:	7f 0f                	jg     f01002b2 <cons_putc+0xa5>
f01002a3:	83 f8 08             	cmp    $0x8,%eax
f01002a6:	0f 85 a1 00 00 00    	jne    f010034d <cons_putc+0x140>
f01002ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01002b0:	eb 10                	jmp    f01002c2 <cons_putc+0xb5>
f01002b2:	83 f8 0a             	cmp    $0xa,%eax
f01002b5:	74 3c                	je     f01002f3 <cons_putc+0xe6>
f01002b7:	83 f8 0d             	cmp    $0xd,%eax
f01002ba:	0f 85 8d 00 00 00    	jne    f010034d <cons_putc+0x140>
f01002c0:	eb 39                	jmp    f01002fb <cons_putc+0xee>
	case '\b':
		if (crt_pos > 0) {
f01002c2:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f01002c9:	66 85 c0             	test   %ax,%ax
f01002cc:	0f 84 e5 00 00 00    	je     f01003b7 <cons_putc+0x1aa>
			crt_pos--;
f01002d2:	83 e8 01             	sub    $0x1,%eax
f01002d5:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002db:	0f b7 c0             	movzwl %ax,%eax
f01002de:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f01002e4:	83 cf 20             	or     $0x20,%edi
f01002e7:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
f01002ed:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002f1:	eb 77                	jmp    f010036a <cons_putc+0x15d>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002f3:	66 83 05 54 25 11 f0 	addw   $0x50,0xf0112554
f01002fa:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002fb:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f0100302:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100308:	c1 e8 16             	shr    $0x16,%eax
f010030b:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010030e:	c1 e0 04             	shl    $0x4,%eax
f0100311:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
f0100317:	eb 51                	jmp    f010036a <cons_putc+0x15d>
		break;
	case '\t':
		cons_putc(' ');
f0100319:	b8 20 00 00 00       	mov    $0x20,%eax
f010031e:	e8 ea fe ff ff       	call   f010020d <cons_putc>
		cons_putc(' ');
f0100323:	b8 20 00 00 00       	mov    $0x20,%eax
f0100328:	e8 e0 fe ff ff       	call   f010020d <cons_putc>
		cons_putc(' ');
f010032d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100332:	e8 d6 fe ff ff       	call   f010020d <cons_putc>
		cons_putc(' ');
f0100337:	b8 20 00 00 00       	mov    $0x20,%eax
f010033c:	e8 cc fe ff ff       	call   f010020d <cons_putc>
		cons_putc(' ');
f0100341:	b8 20 00 00 00       	mov    $0x20,%eax
f0100346:	e8 c2 fe ff ff       	call   f010020d <cons_putc>
f010034b:	eb 1d                	jmp    f010036a <cons_putc+0x15d>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010034d:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f0100354:	0f b7 c8             	movzwl %ax,%ecx
f0100357:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
f010035d:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100361:	83 c0 01             	add    $0x1,%eax
f0100364:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010036a:	66 81 3d 54 25 11 f0 	cmpw   $0x7cf,0xf0112554
f0100371:	cf 07 
f0100373:	76 42                	jbe    f01003b7 <cons_putc+0x1aa>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100375:	a1 50 25 11 f0       	mov    0xf0112550,%eax
f010037a:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100381:	00 
f0100382:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100388:	89 54 24 04          	mov    %edx,0x4(%esp)
f010038c:	89 04 24             	mov    %eax,(%esp)
f010038f:	e8 ce 11 00 00       	call   f0101562 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100394:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010039a:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010039f:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01003a5:	83 c0 01             	add    $0x1,%eax
f01003a8:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01003ad:	75 f0                	jne    f010039f <cons_putc+0x192>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01003af:	66 83 2d 54 25 11 f0 	subw   $0x50,0xf0112554
f01003b6:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003b7:	8b 0d 4c 25 11 f0    	mov    0xf011254c,%ecx
f01003bd:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003c2:	89 ca                	mov    %ecx,%edx
f01003c4:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003c5:	0f b7 1d 54 25 11 f0 	movzwl 0xf0112554,%ebx
f01003cc:	8d 71 01             	lea    0x1(%ecx),%esi
f01003cf:	89 d8                	mov    %ebx,%eax
f01003d1:	66 c1 e8 08          	shr    $0x8,%ax
f01003d5:	89 f2                	mov    %esi,%edx
f01003d7:	ee                   	out    %al,(%dx)
f01003d8:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003dd:	89 ca                	mov    %ecx,%edx
f01003df:	ee                   	out    %al,(%dx)
f01003e0:	89 d8                	mov    %ebx,%eax
f01003e2:	89 f2                	mov    %esi,%edx
f01003e4:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003e5:	83 c4 2c             	add    $0x2c,%esp
f01003e8:	5b                   	pop    %ebx
f01003e9:	5e                   	pop    %esi
f01003ea:	5f                   	pop    %edi
f01003eb:	5d                   	pop    %ebp
f01003ec:	c3                   	ret    

f01003ed <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003ed:	55                   	push   %ebp
f01003ee:	89 e5                	mov    %esp,%ebp
f01003f0:	53                   	push   %ebx
f01003f1:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003f4:	ba 64 00 00 00       	mov    $0x64,%edx
f01003f9:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003fa:	a8 01                	test   $0x1,%al
f01003fc:	0f 84 e4 00 00 00    	je     f01004e6 <kbd_proc_data+0xf9>
f0100402:	b2 60                	mov    $0x60,%dl
f0100404:	ec                   	in     (%dx),%al
f0100405:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100407:	3c e0                	cmp    $0xe0,%al
f0100409:	75 11                	jne    f010041c <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f010040b:	83 0d 48 25 11 f0 40 	orl    $0x40,0xf0112548
		return 0;
f0100412:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100417:	e9 cf 00 00 00       	jmp    f01004eb <kbd_proc_data+0xfe>
	} else if (data & 0x80) {
f010041c:	84 c0                	test   %al,%al
f010041e:	79 34                	jns    f0100454 <kbd_proc_data+0x67>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100420:	8b 0d 48 25 11 f0    	mov    0xf0112548,%ecx
f0100426:	f6 c1 40             	test   $0x40,%cl
f0100429:	75 05                	jne    f0100430 <kbd_proc_data+0x43>
f010042b:	89 c2                	mov    %eax,%edx
f010042d:	83 e2 7f             	and    $0x7f,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100430:	0f b6 d2             	movzbl %dl,%edx
f0100433:	0f b6 82 00 1b 10 f0 	movzbl -0xfefe500(%edx),%eax
f010043a:	83 c8 40             	or     $0x40,%eax
f010043d:	0f b6 c0             	movzbl %al,%eax
f0100440:	f7 d0                	not    %eax
f0100442:	21 c1                	and    %eax,%ecx
f0100444:	89 0d 48 25 11 f0    	mov    %ecx,0xf0112548
		return 0;
f010044a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010044f:	e9 97 00 00 00       	jmp    f01004eb <kbd_proc_data+0xfe>
	} else if (shift & E0ESC) {
f0100454:	8b 0d 48 25 11 f0    	mov    0xf0112548,%ecx
f010045a:	f6 c1 40             	test   $0x40,%cl
f010045d:	74 0e                	je     f010046d <kbd_proc_data+0x80>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010045f:	89 c2                	mov    %eax,%edx
f0100461:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100464:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100467:	89 0d 48 25 11 f0    	mov    %ecx,0xf0112548
	}

	shift |= shiftcode[data];
f010046d:	0f b6 c2             	movzbl %dl,%eax
f0100470:	0f b6 90 00 1b 10 f0 	movzbl -0xfefe500(%eax),%edx
f0100477:	0b 15 48 25 11 f0    	or     0xf0112548,%edx
	shift ^= togglecode[data];
f010047d:	0f b6 88 00 1c 10 f0 	movzbl -0xfefe400(%eax),%ecx
f0100484:	31 ca                	xor    %ecx,%edx
f0100486:	89 15 48 25 11 f0    	mov    %edx,0xf0112548

	c = charcode[shift & (CTL | SHIFT)][data];
f010048c:	89 d1                	mov    %edx,%ecx
f010048e:	83 e1 03             	and    $0x3,%ecx
f0100491:	8b 0c 8d 00 1d 10 f0 	mov    -0xfefe300(,%ecx,4),%ecx
f0100498:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f010049c:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f010049f:	f6 c2 08             	test   $0x8,%dl
f01004a2:	74 1a                	je     f01004be <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f01004a4:	89 d8                	mov    %ebx,%eax
f01004a6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01004a9:	83 f9 19             	cmp    $0x19,%ecx
f01004ac:	77 05                	ja     f01004b3 <kbd_proc_data+0xc6>
			c += 'A' - 'a';
f01004ae:	83 eb 20             	sub    $0x20,%ebx
f01004b1:	eb 0b                	jmp    f01004be <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f01004b3:	83 e8 41             	sub    $0x41,%eax
f01004b6:	83 f8 19             	cmp    $0x19,%eax
f01004b9:	77 03                	ja     f01004be <kbd_proc_data+0xd1>
			c += 'a' - 'A';
f01004bb:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004be:	f7 d2                	not    %edx
f01004c0:	f6 c2 06             	test   $0x6,%dl
f01004c3:	75 26                	jne    f01004eb <kbd_proc_data+0xfe>
f01004c5:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004cb:	75 1e                	jne    f01004eb <kbd_proc_data+0xfe>
		cprintf("Rebooting!\n");
f01004cd:	c7 04 24 c4 1a 10 f0 	movl   $0xf0101ac4,(%esp)
f01004d4:	e8 4d 04 00 00       	call   f0100926 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004d9:	ba 92 00 00 00       	mov    $0x92,%edx
f01004de:	b8 03 00 00 00       	mov    $0x3,%eax
f01004e3:	ee                   	out    %al,(%dx)
f01004e4:	eb 05                	jmp    f01004eb <kbd_proc_data+0xfe>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01004e6:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004eb:	89 d8                	mov    %ebx,%eax
f01004ed:	83 c4 14             	add    $0x14,%esp
f01004f0:	5b                   	pop    %ebx
f01004f1:	5d                   	pop    %ebp
f01004f2:	c3                   	ret    

f01004f3 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004f3:	83 3d 20 23 11 f0 00 	cmpl   $0x0,0xf0112320
f01004fa:	74 11                	je     f010050d <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004fc:	55                   	push   %ebp
f01004fd:	89 e5                	mov    %esp,%ebp
f01004ff:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100502:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f0100507:	e8 be fc ff ff       	call   f01001ca <cons_intr>
}
f010050c:	c9                   	leave  
f010050d:	f3 c3                	repz ret 

f010050f <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010050f:	55                   	push   %ebp
f0100510:	89 e5                	mov    %esp,%ebp
f0100512:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100515:	b8 ed 03 10 f0       	mov    $0xf01003ed,%eax
f010051a:	e8 ab fc ff ff       	call   f01001ca <cons_intr>
}
f010051f:	c9                   	leave  
f0100520:	c3                   	ret    

f0100521 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100521:	55                   	push   %ebp
f0100522:	89 e5                	mov    %esp,%ebp
f0100524:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100527:	e8 c7 ff ff ff       	call   f01004f3 <serial_intr>
	kbd_intr();
f010052c:	e8 de ff ff ff       	call   f010050f <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100531:	8b 15 40 25 11 f0    	mov    0xf0112540,%edx
f0100537:	3b 15 44 25 11 f0    	cmp    0xf0112544,%edx
f010053d:	74 23                	je     f0100562 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f010053f:	0f b6 82 40 23 11 f0 	movzbl -0xfeedcc0(%edx),%eax
f0100546:	83 c2 01             	add    $0x1,%edx
f0100549:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010054f:	0f 94 c1             	sete   %cl
f0100552:	0f b6 c9             	movzbl %cl,%ecx
f0100555:	83 e9 01             	sub    $0x1,%ecx
f0100558:	21 ca                	and    %ecx,%edx
f010055a:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
f0100560:	eb 05                	jmp    f0100567 <cons_getc+0x46>
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f0100562:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100567:	c9                   	leave  
f0100568:	c3                   	ret    

f0100569 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100569:	55                   	push   %ebp
f010056a:	89 e5                	mov    %esp,%ebp
f010056c:	57                   	push   %edi
f010056d:	56                   	push   %esi
f010056e:	53                   	push   %ebx
f010056f:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100572:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100579:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100580:	5a a5 
	if (*cp != 0xA55A) {
f0100582:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100589:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010058d:	74 11                	je     f01005a0 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010058f:	c7 05 4c 25 11 f0 b4 	movl   $0x3b4,0xf011254c
f0100596:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100599:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f010059e:	eb 16                	jmp    f01005b6 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005a0:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005a7:	c7 05 4c 25 11 f0 d4 	movl   $0x3d4,0xf011254c
f01005ae:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b1:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01005b6:	8b 0d 4c 25 11 f0    	mov    0xf011254c,%ecx
f01005bc:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c1:	89 ca                	mov    %ecx,%edx
f01005c3:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005c4:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c7:	89 da                	mov    %ebx,%edx
f01005c9:	ec                   	in     (%dx),%al
f01005ca:	0f b6 f0             	movzbl %al,%esi
f01005cd:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d0:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005d5:	89 ca                	mov    %ecx,%edx
f01005d7:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d8:	89 da                	mov    %ebx,%edx
f01005da:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005db:	89 3d 50 25 11 f0    	mov    %edi,0xf0112550
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005e1:	0f b6 d8             	movzbl %al,%ebx
f01005e4:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005e6:	66 89 35 54 25 11 f0 	mov    %si,0xf0112554
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ed:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f7:	89 f2                	mov    %esi,%edx
f01005f9:	ee                   	out    %al,(%dx)
f01005fa:	b2 fb                	mov    $0xfb,%dl
f01005fc:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100601:	ee                   	out    %al,(%dx)
f0100602:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100607:	b8 0c 00 00 00       	mov    $0xc,%eax
f010060c:	89 da                	mov    %ebx,%edx
f010060e:	ee                   	out    %al,(%dx)
f010060f:	b2 f9                	mov    $0xf9,%dl
f0100611:	b8 00 00 00 00       	mov    $0x0,%eax
f0100616:	ee                   	out    %al,(%dx)
f0100617:	b2 fb                	mov    $0xfb,%dl
f0100619:	b8 03 00 00 00       	mov    $0x3,%eax
f010061e:	ee                   	out    %al,(%dx)
f010061f:	b2 fc                	mov    $0xfc,%dl
f0100621:	b8 00 00 00 00       	mov    $0x0,%eax
f0100626:	ee                   	out    %al,(%dx)
f0100627:	b2 f9                	mov    $0xf9,%dl
f0100629:	b8 01 00 00 00       	mov    $0x1,%eax
f010062e:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010062f:	b2 fd                	mov    $0xfd,%dl
f0100631:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100632:	3c ff                	cmp    $0xff,%al
f0100634:	0f 95 c1             	setne  %cl
f0100637:	0f b6 c9             	movzbl %cl,%ecx
f010063a:	89 0d 20 23 11 f0    	mov    %ecx,0xf0112320
f0100640:	89 f2                	mov    %esi,%edx
f0100642:	ec                   	in     (%dx),%al
f0100643:	89 da                	mov    %ebx,%edx
f0100645:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100646:	85 c9                	test   %ecx,%ecx
f0100648:	75 0c                	jne    f0100656 <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f010064a:	c7 04 24 d0 1a 10 f0 	movl   $0xf0101ad0,(%esp)
f0100651:	e8 d0 02 00 00       	call   f0100926 <cprintf>
}
f0100656:	83 c4 1c             	add    $0x1c,%esp
f0100659:	5b                   	pop    %ebx
f010065a:	5e                   	pop    %esi
f010065b:	5f                   	pop    %edi
f010065c:	5d                   	pop    %ebp
f010065d:	c3                   	ret    

f010065e <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010065e:	55                   	push   %ebp
f010065f:	89 e5                	mov    %esp,%ebp
f0100661:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100664:	8b 45 08             	mov    0x8(%ebp),%eax
f0100667:	e8 a1 fb ff ff       	call   f010020d <cons_putc>
}
f010066c:	c9                   	leave  
f010066d:	c3                   	ret    

f010066e <getchar>:

int
getchar(void)
{
f010066e:	55                   	push   %ebp
f010066f:	89 e5                	mov    %esp,%ebp
f0100671:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100674:	e8 a8 fe ff ff       	call   f0100521 <cons_getc>
f0100679:	85 c0                	test   %eax,%eax
f010067b:	74 f7                	je     f0100674 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010067d:	c9                   	leave  
f010067e:	c3                   	ret    

f010067f <iscons>:

int
iscons(int fdnum)
{
f010067f:	55                   	push   %ebp
f0100680:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100682:	b8 01 00 00 00       	mov    $0x1,%eax
f0100687:	5d                   	pop    %ebp
f0100688:	c3                   	ret    
f0100689:	00 00                	add    %al,(%eax)
f010068b:	00 00                	add    %al,(%eax)
f010068d:	00 00                	add    %al,(%eax)
	...

f0100690 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100696:	c7 04 24 10 1d 10 f0 	movl   $0xf0101d10,(%esp)
f010069d:	e8 84 02 00 00       	call   f0100926 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006a2:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006a9:	00 
f01006aa:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006b1:	f0 
f01006b2:	c7 04 24 9c 1d 10 f0 	movl   $0xf0101d9c,(%esp)
f01006b9:	e8 68 02 00 00       	call   f0100926 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006be:	c7 44 24 08 3d 1a 10 	movl   $0x101a3d,0x8(%esp)
f01006c5:	00 
f01006c6:	c7 44 24 04 3d 1a 10 	movl   $0xf0101a3d,0x4(%esp)
f01006cd:	f0 
f01006ce:	c7 04 24 c0 1d 10 f0 	movl   $0xf0101dc0,(%esp)
f01006d5:	e8 4c 02 00 00       	call   f0100926 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006da:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f01006e1:	00 
f01006e2:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f01006e9:	f0 
f01006ea:	c7 04 24 e4 1d 10 f0 	movl   $0xf0101de4,(%esp)
f01006f1:	e8 30 02 00 00       	call   f0100926 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006f6:	c7 44 24 08 60 29 11 	movl   $0x112960,0x8(%esp)
f01006fd:	00 
f01006fe:	c7 44 24 04 60 29 11 	movl   $0xf0112960,0x4(%esp)
f0100705:	f0 
f0100706:	c7 04 24 08 1e 10 f0 	movl   $0xf0101e08,(%esp)
f010070d:	e8 14 02 00 00       	call   f0100926 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f0100712:	b8 5f 2d 11 f0       	mov    $0xf0112d5f,%eax
f0100717:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010071c:	89 c2                	mov    %eax,%edx
f010071e:	c1 fa 1f             	sar    $0x1f,%edx
f0100721:	c1 ea 16             	shr    $0x16,%edx
f0100724:	01 d0                	add    %edx,%eax
f0100726:	c1 f8 0a             	sar    $0xa,%eax
f0100729:	89 44 24 04          	mov    %eax,0x4(%esp)
f010072d:	c7 04 24 2c 1e 10 f0 	movl   $0xf0101e2c,(%esp)
f0100734:	e8 ed 01 00 00       	call   f0100926 <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f0100739:	b8 00 00 00 00       	mov    $0x0,%eax
f010073e:	c9                   	leave  
f010073f:	c3                   	ret    

f0100740 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100740:	55                   	push   %ebp
f0100741:	89 e5                	mov    %esp,%ebp
f0100743:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100746:	c7 44 24 08 29 1d 10 	movl   $0xf0101d29,0x8(%esp)
f010074d:	f0 
f010074e:	c7 44 24 04 47 1d 10 	movl   $0xf0101d47,0x4(%esp)
f0100755:	f0 
f0100756:	c7 04 24 4c 1d 10 f0 	movl   $0xf0101d4c,(%esp)
f010075d:	e8 c4 01 00 00       	call   f0100926 <cprintf>
f0100762:	c7 44 24 08 58 1e 10 	movl   $0xf0101e58,0x8(%esp)
f0100769:	f0 
f010076a:	c7 44 24 04 55 1d 10 	movl   $0xf0101d55,0x4(%esp)
f0100771:	f0 
f0100772:	c7 04 24 4c 1d 10 f0 	movl   $0xf0101d4c,(%esp)
f0100779:	e8 a8 01 00 00       	call   f0100926 <cprintf>
	return 0;
}
f010077e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100783:	c9                   	leave  
f0100784:	c3                   	ret    

f0100785 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100785:	55                   	push   %ebp
f0100786:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100788:	b8 00 00 00 00       	mov    $0x0,%eax
f010078d:	5d                   	pop    %ebp
f010078e:	c3                   	ret    

f010078f <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010078f:	55                   	push   %ebp
f0100790:	89 e5                	mov    %esp,%ebp
f0100792:	57                   	push   %edi
f0100793:	56                   	push   %esi
f0100794:	53                   	push   %ebx
f0100795:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100798:	c7 04 24 80 1e 10 f0 	movl   $0xf0101e80,(%esp)
f010079f:	e8 82 01 00 00       	call   f0100926 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007a4:	c7 04 24 a4 1e 10 f0 	movl   $0xf0101ea4,(%esp)
f01007ab:	e8 76 01 00 00       	call   f0100926 <cprintf>
	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
f01007b0:	8d 7d a8             	lea    -0x58(%ebp),%edi
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f01007b3:	c7 04 24 5e 1d 10 f0 	movl   $0xf0101d5e,(%esp)
f01007ba:	e8 a1 0a 00 00       	call   f0101260 <readline>
f01007bf:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007c1:	85 c0                	test   %eax,%eax
f01007c3:	74 ee                	je     f01007b3 <monitor+0x24>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007c5:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007cc:	be 00 00 00 00       	mov    $0x0,%esi
f01007d1:	eb 06                	jmp    f01007d9 <monitor+0x4a>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007d3:	c6 03 00             	movb   $0x0,(%ebx)
f01007d6:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007d9:	0f b6 03             	movzbl (%ebx),%eax
f01007dc:	84 c0                	test   %al,%al
f01007de:	74 6b                	je     f010084b <monitor+0xbc>
f01007e0:	0f be c0             	movsbl %al,%eax
f01007e3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007e7:	c7 04 24 62 1d 10 f0 	movl   $0xf0101d62,(%esp)
f01007ee:	e8 b7 0c 00 00       	call   f01014aa <strchr>
f01007f3:	85 c0                	test   %eax,%eax
f01007f5:	75 dc                	jne    f01007d3 <monitor+0x44>
			*buf++ = 0;
		if (*buf == 0)
f01007f7:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007fa:	74 4f                	je     f010084b <monitor+0xbc>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007fc:	83 fe 0f             	cmp    $0xf,%esi
f01007ff:	90                   	nop
f0100800:	75 16                	jne    f0100818 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100802:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100809:	00 
f010080a:	c7 04 24 67 1d 10 f0 	movl   $0xf0101d67,(%esp)
f0100811:	e8 10 01 00 00       	call   f0100926 <cprintf>
f0100816:	eb 9b                	jmp    f01007b3 <monitor+0x24>
			return 0;
		}
		argv[argc++] = buf;
f0100818:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010081c:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010081f:	0f b6 03             	movzbl (%ebx),%eax
f0100822:	84 c0                	test   %al,%al
f0100824:	75 0c                	jne    f0100832 <monitor+0xa3>
f0100826:	eb b1                	jmp    f01007d9 <monitor+0x4a>
			buf++;
f0100828:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010082b:	0f b6 03             	movzbl (%ebx),%eax
f010082e:	84 c0                	test   %al,%al
f0100830:	74 a7                	je     f01007d9 <monitor+0x4a>
f0100832:	0f be c0             	movsbl %al,%eax
f0100835:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100839:	c7 04 24 62 1d 10 f0 	movl   $0xf0101d62,(%esp)
f0100840:	e8 65 0c 00 00       	call   f01014aa <strchr>
f0100845:	85 c0                	test   %eax,%eax
f0100847:	74 df                	je     f0100828 <monitor+0x99>
f0100849:	eb 8e                	jmp    f01007d9 <monitor+0x4a>
			buf++;
	}
	argv[argc] = 0;
f010084b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100852:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100853:	85 f6                	test   %esi,%esi
f0100855:	0f 84 58 ff ff ff    	je     f01007b3 <monitor+0x24>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010085b:	c7 44 24 04 47 1d 10 	movl   $0xf0101d47,0x4(%esp)
f0100862:	f0 
f0100863:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100866:	89 04 24             	mov    %eax,(%esp)
f0100869:	e8 b8 0b 00 00       	call   f0101426 <strcmp>
f010086e:	85 c0                	test   %eax,%eax
f0100870:	74 1b                	je     f010088d <monitor+0xfe>
f0100872:	c7 44 24 04 55 1d 10 	movl   $0xf0101d55,0x4(%esp)
f0100879:	f0 
f010087a:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010087d:	89 04 24             	mov    %eax,(%esp)
f0100880:	e8 a1 0b 00 00       	call   f0101426 <strcmp>
f0100885:	85 c0                	test   %eax,%eax
f0100887:	75 2c                	jne    f01008b5 <monitor+0x126>
f0100889:	b0 01                	mov    $0x1,%al
f010088b:	eb 05                	jmp    f0100892 <monitor+0x103>
f010088d:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100892:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100895:	01 d0                	add    %edx,%eax
f0100897:	8b 55 08             	mov    0x8(%ebp),%edx
f010089a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010089e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01008a2:	89 34 24             	mov    %esi,(%esp)
f01008a5:	ff 14 85 d4 1e 10 f0 	call   *-0xfefe12c(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008ac:	85 c0                	test   %eax,%eax
f01008ae:	78 1d                	js     f01008cd <monitor+0x13e>
f01008b0:	e9 fe fe ff ff       	jmp    f01007b3 <monitor+0x24>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008b5:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008b8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008bc:	c7 04 24 84 1d 10 f0 	movl   $0xf0101d84,(%esp)
f01008c3:	e8 5e 00 00 00       	call   f0100926 <cprintf>
f01008c8:	e9 e6 fe ff ff       	jmp    f01007b3 <monitor+0x24>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008cd:	83 c4 5c             	add    $0x5c,%esp
f01008d0:	5b                   	pop    %ebx
f01008d1:	5e                   	pop    %esi
f01008d2:	5f                   	pop    %edi
f01008d3:	5d                   	pop    %ebp
f01008d4:	c3                   	ret    

f01008d5 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f01008d5:	55                   	push   %ebp
f01008d6:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01008d8:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01008db:	5d                   	pop    %ebp
f01008dc:	c3                   	ret    
f01008dd:	00 00                	add    %al,(%eax)
	...

f01008e0 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008e0:	55                   	push   %ebp
f01008e1:	89 e5                	mov    %esp,%ebp
f01008e3:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01008e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01008e9:	89 04 24             	mov    %eax,(%esp)
f01008ec:	e8 6d fd ff ff       	call   f010065e <cputchar>
	*cnt++;
}
f01008f1:	c9                   	leave  
f01008f2:	c3                   	ret    

f01008f3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008f3:	55                   	push   %ebp
f01008f4:	89 e5                	mov    %esp,%ebp
f01008f6:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01008f9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100900:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100903:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100907:	8b 45 08             	mov    0x8(%ebp),%eax
f010090a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010090e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100911:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100915:	c7 04 24 e0 08 10 f0 	movl   $0xf01008e0,(%esp)
f010091c:	e8 91 04 00 00       	call   f0100db2 <vprintfmt>
	return cnt;
}
f0100921:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100924:	c9                   	leave  
f0100925:	c3                   	ret    

f0100926 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100926:	55                   	push   %ebp
f0100927:	89 e5                	mov    %esp,%ebp
f0100929:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010092c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010092f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100933:	8b 45 08             	mov    0x8(%ebp),%eax
f0100936:	89 04 24             	mov    %eax,(%esp)
f0100939:	e8 b5 ff ff ff       	call   f01008f3 <vcprintf>
	va_end(ap);

	return cnt;
}
f010093e:	c9                   	leave  
f010093f:	c3                   	ret    

f0100940 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100940:	55                   	push   %ebp
f0100941:	89 e5                	mov    %esp,%ebp
f0100943:	57                   	push   %edi
f0100944:	56                   	push   %esi
f0100945:	53                   	push   %ebx
f0100946:	83 ec 10             	sub    $0x10,%esp
f0100949:	89 c6                	mov    %eax,%esi
f010094b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f010094e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100951:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100954:	8b 1a                	mov    (%edx),%ebx
f0100956:	8b 09                	mov    (%ecx),%ecx
f0100958:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010095b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0100962:	eb 77                	jmp    f01009db <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100964:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100967:	01 d8                	add    %ebx,%eax
f0100969:	b9 02 00 00 00       	mov    $0x2,%ecx
f010096e:	99                   	cltd   
f010096f:	f7 f9                	idiv   %ecx
f0100971:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100973:	eb 01                	jmp    f0100976 <stab_binsearch+0x36>
			m--;
f0100975:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100976:	39 d9                	cmp    %ebx,%ecx
f0100978:	7c 1d                	jl     f0100997 <stab_binsearch+0x57>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f010097a:	6b d1 0c             	imul   $0xc,%ecx,%edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010097d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100982:	39 fa                	cmp    %edi,%edx
f0100984:	75 ef                	jne    f0100975 <stab_binsearch+0x35>
f0100986:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100989:	6b d1 0c             	imul   $0xc,%ecx,%edx
f010098c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100990:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100993:	73 18                	jae    f01009ad <stab_binsearch+0x6d>
f0100995:	eb 05                	jmp    f010099c <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100997:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f010099a:	eb 3f                	jmp    f01009db <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f010099c:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010099f:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f01009a1:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009a4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009ab:	eb 2e                	jmp    f01009db <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009ad:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009b0:	73 15                	jae    f01009c7 <stab_binsearch+0x87>
			*region_right = m - 1;
f01009b2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009b5:	49                   	dec    %ecx
f01009b6:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01009b9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009bc:	89 08                	mov    %ecx,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009be:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009c5:	eb 14                	jmp    f01009db <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01009ca:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01009cd:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f01009cf:	ff 45 0c             	incl   0xc(%ebp)
f01009d2:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009d4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f01009db:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01009de:	7e 84                	jle    f0100964 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01009e0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01009e4:	75 0d                	jne    f01009f3 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f01009e6:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01009e9:	8b 02                	mov    (%edx),%eax
f01009eb:	48                   	dec    %eax
f01009ec:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009ef:	89 01                	mov    %eax,(%ecx)
f01009f1:	eb 22                	jmp    f0100a15 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009f3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009f6:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f01009f8:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01009fb:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009fd:	eb 01                	jmp    f0100a00 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01009ff:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a00:	39 c1                	cmp    %eax,%ecx
f0100a02:	7d 0c                	jge    f0100a10 <stab_binsearch+0xd0>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100a04:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100a07:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a0c:	39 fa                	cmp    %edi,%edx
f0100a0e:	75 ef                	jne    f01009ff <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a10:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a13:	89 02                	mov    %eax,(%edx)
	}
}
f0100a15:	83 c4 10             	add    $0x10,%esp
f0100a18:	5b                   	pop    %ebx
f0100a19:	5e                   	pop    %esi
f0100a1a:	5f                   	pop    %edi
f0100a1b:	5d                   	pop    %ebp
f0100a1c:	c3                   	ret    

f0100a1d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a1d:	55                   	push   %ebp
f0100a1e:	89 e5                	mov    %esp,%ebp
f0100a20:	83 ec 38             	sub    $0x38,%esp
f0100a23:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100a26:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100a29:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100a2c:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a2f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a32:	c7 03 e4 1e 10 f0    	movl   $0xf0101ee4,(%ebx)
	info->eip_line = 0;
f0100a38:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a3f:	c7 43 08 e4 1e 10 f0 	movl   $0xf0101ee4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100a46:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100a4d:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100a50:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a57:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100a5d:	76 12                	jbe    f0100a71 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a5f:	b8 6a 75 10 f0       	mov    $0xf010756a,%eax
f0100a64:	3d e5 5b 10 f0       	cmp    $0xf0105be5,%eax
f0100a69:	0f 86 99 01 00 00    	jbe    f0100c08 <debuginfo_eip+0x1eb>
f0100a6f:	eb 1c                	jmp    f0100a8d <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a71:	c7 44 24 08 ee 1e 10 	movl   $0xf0101eee,0x8(%esp)
f0100a78:	f0 
f0100a79:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100a80:	00 
f0100a81:	c7 04 24 fb 1e 10 f0 	movl   $0xf0101efb,(%esp)
f0100a88:	e8 6b f6 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a8d:	80 3d 69 75 10 f0 00 	cmpb   $0x0,0xf0107569
f0100a94:	0f 85 75 01 00 00    	jne    f0100c0f <debuginfo_eip+0x1f2>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a9a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100aa1:	b8 e4 5b 10 f0       	mov    $0xf0105be4,%eax
f0100aa6:	2d 1c 21 10 f0       	sub    $0xf010211c,%eax
f0100aab:	c1 f8 02             	sar    $0x2,%eax
f0100aae:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100ab4:	83 e8 01             	sub    $0x1,%eax
f0100ab7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100aba:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100abe:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100ac5:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100ac8:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100acb:	b8 1c 21 10 f0       	mov    $0xf010211c,%eax
f0100ad0:	e8 6b fe ff ff       	call   f0100940 <stab_binsearch>
	if (lfile == 0)
f0100ad5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ad8:	85 c0                	test   %eax,%eax
f0100ada:	0f 84 36 01 00 00    	je     f0100c16 <debuginfo_eip+0x1f9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100ae0:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100ae3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ae6:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100ae9:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100aed:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100af4:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100af7:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100afa:	b8 1c 21 10 f0       	mov    $0xf010211c,%eax
f0100aff:	e8 3c fe ff ff       	call   f0100940 <stab_binsearch>

	if (lfun <= rfun) {
f0100b04:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100b07:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100b0a:	7f 2e                	jg     f0100b3a <debuginfo_eip+0x11d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b0c:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b0f:	8d 90 1c 21 10 f0    	lea    -0xfefdee4(%eax),%edx
f0100b15:	8b 80 1c 21 10 f0    	mov    -0xfefdee4(%eax),%eax
f0100b1b:	b9 6a 75 10 f0       	mov    $0xf010756a,%ecx
f0100b20:	81 e9 e5 5b 10 f0    	sub    $0xf0105be5,%ecx
f0100b26:	39 c8                	cmp    %ecx,%eax
f0100b28:	73 08                	jae    f0100b32 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b2a:	05 e5 5b 10 f0       	add    $0xf0105be5,%eax
f0100b2f:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b32:	8b 42 08             	mov    0x8(%edx),%eax
f0100b35:	89 43 10             	mov    %eax,0x10(%ebx)
f0100b38:	eb 06                	jmp    f0100b40 <debuginfo_eip+0x123>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b3a:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b3d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b40:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100b47:	00 
f0100b48:	8b 43 08             	mov    0x8(%ebx),%eax
f0100b4b:	89 04 24             	mov    %eax,(%esp)
f0100b4e:	e8 8a 09 00 00       	call   f01014dd <strfind>
f0100b53:	2b 43 08             	sub    0x8(%ebx),%eax
f0100b56:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b59:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b5c:	39 cf                	cmp    %ecx,%edi
f0100b5e:	7c 62                	jl     f0100bc2 <debuginfo_eip+0x1a5>
	       && stabs[lline].n_type != N_SOL
f0100b60:	6b f7 0c             	imul   $0xc,%edi,%esi
f0100b63:	81 c6 1c 21 10 f0    	add    $0xf010211c,%esi
f0100b69:	0f b6 56 04          	movzbl 0x4(%esi),%edx
f0100b6d:	80 fa 84             	cmp    $0x84,%dl
f0100b70:	74 31                	je     f0100ba3 <debuginfo_eip+0x186>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100b72:	8d 47 ff             	lea    -0x1(%edi),%eax
f0100b75:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100b78:	05 1c 21 10 f0       	add    $0xf010211c,%eax
f0100b7d:	eb 15                	jmp    f0100b94 <debuginfo_eip+0x177>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b7f:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b82:	39 cf                	cmp    %ecx,%edi
f0100b84:	7c 3c                	jl     f0100bc2 <debuginfo_eip+0x1a5>
	       && stabs[lline].n_type != N_SOL
f0100b86:	89 c6                	mov    %eax,%esi
f0100b88:	83 e8 0c             	sub    $0xc,%eax
f0100b8b:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f0100b8f:	80 fa 84             	cmp    $0x84,%dl
f0100b92:	74 0f                	je     f0100ba3 <debuginfo_eip+0x186>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b94:	80 fa 64             	cmp    $0x64,%dl
f0100b97:	75 e6                	jne    f0100b7f <debuginfo_eip+0x162>
f0100b99:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f0100b9d:	74 e0                	je     f0100b7f <debuginfo_eip+0x162>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b9f:	39 f9                	cmp    %edi,%ecx
f0100ba1:	7f 1f                	jg     f0100bc2 <debuginfo_eip+0x1a5>
f0100ba3:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100ba6:	8b 87 1c 21 10 f0    	mov    -0xfefdee4(%edi),%eax
f0100bac:	ba 6a 75 10 f0       	mov    $0xf010756a,%edx
f0100bb1:	81 ea e5 5b 10 f0    	sub    $0xf0105be5,%edx
f0100bb7:	39 d0                	cmp    %edx,%eax
f0100bb9:	73 07                	jae    f0100bc2 <debuginfo_eip+0x1a5>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100bbb:	05 e5 5b 10 f0       	add    $0xf0105be5,%eax
f0100bc0:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bc2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100bc5:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100bc8:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bcd:	39 ca                	cmp    %ecx,%edx
f0100bcf:	7d 5f                	jge    f0100c30 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
f0100bd1:	8d 42 01             	lea    0x1(%edx),%eax
f0100bd4:	39 c1                	cmp    %eax,%ecx
f0100bd6:	7e 45                	jle    f0100c1d <debuginfo_eip+0x200>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100bd8:	6b f0 0c             	imul   $0xc,%eax,%esi
f0100bdb:	80 be 20 21 10 f0 a0 	cmpb   $0xa0,-0xfefdee0(%esi)
f0100be2:	75 40                	jne    f0100c24 <debuginfo_eip+0x207>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100be4:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100be7:	81 c2 1c 21 10 f0    	add    $0xf010211c,%edx
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100bed:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100bf1:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100bf4:	39 c1                	cmp    %eax,%ecx
f0100bf6:	7e 33                	jle    f0100c2b <debuginfo_eip+0x20e>
f0100bf8:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100bfb:	80 7a 10 a0          	cmpb   $0xa0,0x10(%edx)
f0100bff:	74 ec                	je     f0100bed <debuginfo_eip+0x1d0>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100c01:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c06:	eb 28                	jmp    f0100c30 <debuginfo_eip+0x213>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c08:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c0d:	eb 21                	jmp    f0100c30 <debuginfo_eip+0x213>
f0100c0f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c14:	eb 1a                	jmp    f0100c30 <debuginfo_eip+0x213>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c16:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c1b:	eb 13                	jmp    f0100c30 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100c1d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c22:	eb 0c                	jmp    f0100c30 <debuginfo_eip+0x213>
f0100c24:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c29:	eb 05                	jmp    f0100c30 <debuginfo_eip+0x213>
f0100c2b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c30:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100c33:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100c36:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100c39:	89 ec                	mov    %ebp,%esp
f0100c3b:	5d                   	pop    %ebp
f0100c3c:	c3                   	ret    
f0100c3d:	00 00                	add    %al,(%eax)
	...

f0100c40 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c40:	55                   	push   %ebp
f0100c41:	89 e5                	mov    %esp,%ebp
f0100c43:	57                   	push   %edi
f0100c44:	56                   	push   %esi
f0100c45:	53                   	push   %ebx
f0100c46:	83 ec 4c             	sub    $0x4c,%esp
f0100c49:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100c4c:	89 d7                	mov    %edx,%edi
f0100c4e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100c51:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0100c54:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100c57:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c5a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c5f:	39 d8                	cmp    %ebx,%eax
f0100c61:	72 17                	jb     f0100c7a <printnum+0x3a>
f0100c63:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100c66:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0100c69:	76 0f                	jbe    f0100c7a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c6b:	8b 75 14             	mov    0x14(%ebp),%esi
f0100c6e:	83 ee 01             	sub    $0x1,%esi
f0100c71:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c74:	85 f6                	test   %esi,%esi
f0100c76:	7f 63                	jg     f0100cdb <printnum+0x9b>
f0100c78:	eb 75                	jmp    f0100cef <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c7a:	8b 5d 18             	mov    0x18(%ebp),%ebx
f0100c7d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0100c81:	8b 45 14             	mov    0x14(%ebp),%eax
f0100c84:	83 e8 01             	sub    $0x1,%eax
f0100c87:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c8b:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100c8e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100c92:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100c96:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100c9a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100c9d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100ca0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100ca7:	00 
f0100ca8:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100cab:	89 1c 24             	mov    %ebx,(%esp)
f0100cae:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100cb1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100cb5:	e8 a6 0a 00 00       	call   f0101760 <__udivdi3>
f0100cba:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100cbd:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100cc0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100cc4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100cc8:	89 04 24             	mov    %eax,(%esp)
f0100ccb:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100ccf:	89 fa                	mov    %edi,%edx
f0100cd1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100cd4:	e8 67 ff ff ff       	call   f0100c40 <printnum>
f0100cd9:	eb 14                	jmp    f0100cef <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100cdb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cdf:	8b 45 18             	mov    0x18(%ebp),%eax
f0100ce2:	89 04 24             	mov    %eax,(%esp)
f0100ce5:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100ce7:	83 ee 01             	sub    $0x1,%esi
f0100cea:	75 ef                	jne    f0100cdb <printnum+0x9b>
f0100cec:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100cef:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cf3:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100cf7:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100cfa:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100cfe:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100d05:	00 
f0100d06:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100d09:	89 1c 24             	mov    %ebx,(%esp)
f0100d0c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100d0f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100d13:	e8 a8 0b 00 00       	call   f01018c0 <__umoddi3>
f0100d18:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d1c:	0f be 80 09 1f 10 f0 	movsbl -0xfefe0f7(%eax),%eax
f0100d23:	89 04 24             	mov    %eax,(%esp)
f0100d26:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d29:	ff d0                	call   *%eax
}
f0100d2b:	83 c4 4c             	add    $0x4c,%esp
f0100d2e:	5b                   	pop    %ebx
f0100d2f:	5e                   	pop    %esi
f0100d30:	5f                   	pop    %edi
f0100d31:	5d                   	pop    %ebp
f0100d32:	c3                   	ret    

f0100d33 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d33:	55                   	push   %ebp
f0100d34:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d36:	83 fa 01             	cmp    $0x1,%edx
f0100d39:	7e 0e                	jle    f0100d49 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d3b:	8b 10                	mov    (%eax),%edx
f0100d3d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d40:	89 08                	mov    %ecx,(%eax)
f0100d42:	8b 02                	mov    (%edx),%eax
f0100d44:	8b 52 04             	mov    0x4(%edx),%edx
f0100d47:	eb 22                	jmp    f0100d6b <getuint+0x38>
	else if (lflag)
f0100d49:	85 d2                	test   %edx,%edx
f0100d4b:	74 10                	je     f0100d5d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d4d:	8b 10                	mov    (%eax),%edx
f0100d4f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d52:	89 08                	mov    %ecx,(%eax)
f0100d54:	8b 02                	mov    (%edx),%eax
f0100d56:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d5b:	eb 0e                	jmp    f0100d6b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d5d:	8b 10                	mov    (%eax),%edx
f0100d5f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d62:	89 08                	mov    %ecx,(%eax)
f0100d64:	8b 02                	mov    (%edx),%eax
f0100d66:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d6b:	5d                   	pop    %ebp
f0100d6c:	c3                   	ret    

f0100d6d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d6d:	55                   	push   %ebp
f0100d6e:	89 e5                	mov    %esp,%ebp
f0100d70:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d73:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d77:	8b 10                	mov    (%eax),%edx
f0100d79:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d7c:	73 0a                	jae    f0100d88 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d7e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100d81:	88 0a                	mov    %cl,(%edx)
f0100d83:	83 c2 01             	add    $0x1,%edx
f0100d86:	89 10                	mov    %edx,(%eax)
}
f0100d88:	5d                   	pop    %ebp
f0100d89:	c3                   	ret    

f0100d8a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d8a:	55                   	push   %ebp
f0100d8b:	89 e5                	mov    %esp,%ebp
f0100d8d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d90:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d93:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d97:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d9a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d9e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100da1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100da5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100da8:	89 04 24             	mov    %eax,(%esp)
f0100dab:	e8 02 00 00 00       	call   f0100db2 <vprintfmt>
	va_end(ap);
}
f0100db0:	c9                   	leave  
f0100db1:	c3                   	ret    

f0100db2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100db2:	55                   	push   %ebp
f0100db3:	89 e5                	mov    %esp,%ebp
f0100db5:	57                   	push   %edi
f0100db6:	56                   	push   %esi
f0100db7:	53                   	push   %ebx
f0100db8:	83 ec 4c             	sub    $0x4c,%esp
f0100dbb:	8b 75 08             	mov    0x8(%ebp),%esi
f0100dbe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100dc1:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100dc4:	eb 11                	jmp    f0100dd7 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100dc6:	85 c0                	test   %eax,%eax
f0100dc8:	0f 84 fc 03 00 00    	je     f01011ca <vprintfmt+0x418>
				return;
			putch(ch, putdat);
f0100dce:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100dd2:	89 04 24             	mov    %eax,(%esp)
f0100dd5:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100dd7:	0f b6 07             	movzbl (%edi),%eax
f0100dda:	83 c7 01             	add    $0x1,%edi
f0100ddd:	83 f8 25             	cmp    $0x25,%eax
f0100de0:	75 e4                	jne    f0100dc6 <vprintfmt+0x14>
f0100de2:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f0100de6:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0100ded:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100df4:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0100dfb:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e00:	eb 2b                	jmp    f0100e2d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e02:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e05:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
f0100e09:	eb 22                	jmp    f0100e2d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e0b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e0e:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f0100e12:	eb 19                	jmp    f0100e2d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e14:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100e17:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100e1e:	eb 0d                	jmp    f0100e2d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100e20:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e23:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100e26:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e2d:	0f b6 0f             	movzbl (%edi),%ecx
f0100e30:	8d 47 01             	lea    0x1(%edi),%eax
f0100e33:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e36:	0f b6 07             	movzbl (%edi),%eax
f0100e39:	83 e8 23             	sub    $0x23,%eax
f0100e3c:	3c 55                	cmp    $0x55,%al
f0100e3e:	0f 87 61 03 00 00    	ja     f01011a5 <vprintfmt+0x3f3>
f0100e44:	0f b6 c0             	movzbl %al,%eax
f0100e47:	ff 24 85 98 1f 10 f0 	jmp    *-0xfefe068(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e4e:	83 e9 30             	sub    $0x30,%ecx
f0100e51:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
f0100e54:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
f0100e58:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100e5b:	83 f9 09             	cmp    $0x9,%ecx
f0100e5e:	77 57                	ja     f0100eb7 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e60:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e63:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100e66:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e69:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0100e6c:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100e6f:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100e73:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0100e76:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100e79:	83 f9 09             	cmp    $0x9,%ecx
f0100e7c:	76 eb                	jbe    f0100e69 <vprintfmt+0xb7>
f0100e7e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100e81:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100e84:	eb 34                	jmp    f0100eba <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e86:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e89:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e8c:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e8f:	8b 00                	mov    (%eax),%eax
f0100e91:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e94:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e97:	eb 21                	jmp    f0100eba <vprintfmt+0x108>

		case '.':
			if (width < 0)
f0100e99:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100e9d:	0f 88 71 ff ff ff    	js     f0100e14 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ea3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ea6:	eb 85                	jmp    f0100e2d <vprintfmt+0x7b>
f0100ea8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100eab:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0100eb2:	e9 76 ff ff ff       	jmp    f0100e2d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eb7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100eba:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100ebe:	0f 89 69 ff ff ff    	jns    f0100e2d <vprintfmt+0x7b>
f0100ec4:	e9 57 ff ff ff       	jmp    f0100e20 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100ec9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ecc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100ecf:	e9 59 ff ff ff       	jmp    f0100e2d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ed4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ed7:	8d 50 04             	lea    0x4(%eax),%edx
f0100eda:	89 55 14             	mov    %edx,0x14(%ebp)
f0100edd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ee1:	8b 00                	mov    (%eax),%eax
f0100ee3:	89 04 24             	mov    %eax,(%esp)
f0100ee6:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ee8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100eeb:	e9 e7 fe ff ff       	jmp    f0100dd7 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ef0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ef3:	8d 50 04             	lea    0x4(%eax),%edx
f0100ef6:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ef9:	8b 00                	mov    (%eax),%eax
f0100efb:	89 c2                	mov    %eax,%edx
f0100efd:	c1 fa 1f             	sar    $0x1f,%edx
f0100f00:	31 d0                	xor    %edx,%eax
f0100f02:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f04:	83 f8 06             	cmp    $0x6,%eax
f0100f07:	7f 0b                	jg     f0100f14 <vprintfmt+0x162>
f0100f09:	8b 14 85 f0 20 10 f0 	mov    -0xfefdf10(,%eax,4),%edx
f0100f10:	85 d2                	test   %edx,%edx
f0100f12:	75 20                	jne    f0100f34 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
f0100f14:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f18:	c7 44 24 08 21 1f 10 	movl   $0xf0101f21,0x8(%esp)
f0100f1f:	f0 
f0100f20:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f24:	89 34 24             	mov    %esi,(%esp)
f0100f27:	e8 5e fe ff ff       	call   f0100d8a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f2c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f2f:	e9 a3 fe ff ff       	jmp    f0100dd7 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0100f34:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100f38:	c7 44 24 08 2a 1f 10 	movl   $0xf0101f2a,0x8(%esp)
f0100f3f:	f0 
f0100f40:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f44:	89 34 24             	mov    %esi,(%esp)
f0100f47:	e8 3e fe ff ff       	call   f0100d8a <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f4c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f4f:	e9 83 fe ff ff       	jmp    f0100dd7 <vprintfmt+0x25>
f0100f54:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100f57:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0100f5a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f5d:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f60:	8d 50 04             	lea    0x4(%eax),%edx
f0100f63:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f66:	8b 38                	mov    (%eax),%edi
f0100f68:	85 ff                	test   %edi,%edi
f0100f6a:	75 05                	jne    f0100f71 <vprintfmt+0x1bf>
				p = "(null)";
f0100f6c:	bf 1a 1f 10 f0       	mov    $0xf0101f1a,%edi
			if (width > 0 && padc != '-')
f0100f71:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f0100f75:	74 06                	je     f0100f7d <vprintfmt+0x1cb>
f0100f77:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0100f7b:	7f 16                	jg     f0100f93 <vprintfmt+0x1e1>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f7d:	0f b6 17             	movzbl (%edi),%edx
f0100f80:	0f be c2             	movsbl %dl,%eax
f0100f83:	83 c7 01             	add    $0x1,%edi
f0100f86:	85 c0                	test   %eax,%eax
f0100f88:	0f 85 9f 00 00 00    	jne    f010102d <vprintfmt+0x27b>
f0100f8e:	e9 8b 00 00 00       	jmp    f010101e <vprintfmt+0x26c>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f93:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100f97:	89 3c 24             	mov    %edi,(%esp)
f0100f9a:	e8 b3 03 00 00       	call   f0101352 <strnlen>
f0100f9f:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0100fa2:	29 c2                	sub    %eax,%edx
f0100fa4:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0100fa7:	85 d2                	test   %edx,%edx
f0100fa9:	7e d2                	jle    f0100f7d <vprintfmt+0x1cb>
					putch(padc, putdat);
f0100fab:	0f be 4d e0          	movsbl -0x20(%ebp),%ecx
f0100faf:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100fb2:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0100fb5:	89 d7                	mov    %edx,%edi
f0100fb7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fbb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100fbe:	89 04 24             	mov    %eax,(%esp)
f0100fc1:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fc3:	83 ef 01             	sub    $0x1,%edi
f0100fc6:	75 ef                	jne    f0100fb7 <vprintfmt+0x205>
f0100fc8:	89 7d d8             	mov    %edi,-0x28(%ebp)
f0100fcb:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0100fce:	eb ad                	jmp    f0100f7d <vprintfmt+0x1cb>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fd0:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0100fd4:	74 20                	je     f0100ff6 <vprintfmt+0x244>
f0100fd6:	0f be d2             	movsbl %dl,%edx
f0100fd9:	83 ea 20             	sub    $0x20,%edx
f0100fdc:	83 fa 5e             	cmp    $0x5e,%edx
f0100fdf:	76 15                	jbe    f0100ff6 <vprintfmt+0x244>
					putch('?', putdat);
f0100fe1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100fe4:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100fe8:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100fef:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100ff2:	ff d1                	call   *%ecx
f0100ff4:	eb 0f                	jmp    f0101005 <vprintfmt+0x253>
				else
					putch(ch, putdat);
f0100ff6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ff9:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100ffd:	89 04 24             	mov    %eax,(%esp)
f0101000:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101003:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101005:	83 eb 01             	sub    $0x1,%ebx
f0101008:	0f b6 17             	movzbl (%edi),%edx
f010100b:	0f be c2             	movsbl %dl,%eax
f010100e:	83 c7 01             	add    $0x1,%edi
f0101011:	85 c0                	test   %eax,%eax
f0101013:	75 24                	jne    f0101039 <vprintfmt+0x287>
f0101015:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0101018:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010101b:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010101e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101021:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101025:	0f 8e ac fd ff ff    	jle    f0100dd7 <vprintfmt+0x25>
f010102b:	eb 20                	jmp    f010104d <vprintfmt+0x29b>
f010102d:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0101030:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0101033:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0101036:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101039:	85 f6                	test   %esi,%esi
f010103b:	78 93                	js     f0100fd0 <vprintfmt+0x21e>
f010103d:	83 ee 01             	sub    $0x1,%esi
f0101040:	79 8e                	jns    f0100fd0 <vprintfmt+0x21e>
f0101042:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0101045:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101048:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010104b:	eb d1                	jmp    f010101e <vprintfmt+0x26c>
f010104d:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101050:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101054:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010105b:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010105d:	83 ef 01             	sub    $0x1,%edi
f0101060:	75 ee                	jne    f0101050 <vprintfmt+0x29e>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101062:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101065:	e9 6d fd ff ff       	jmp    f0100dd7 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010106a:	83 fa 01             	cmp    $0x1,%edx
f010106d:	7e 16                	jle    f0101085 <vprintfmt+0x2d3>
		return va_arg(*ap, long long);
f010106f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101072:	8d 50 08             	lea    0x8(%eax),%edx
f0101075:	89 55 14             	mov    %edx,0x14(%ebp)
f0101078:	8b 10                	mov    (%eax),%edx
f010107a:	8b 48 04             	mov    0x4(%eax),%ecx
f010107d:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101080:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101083:	eb 32                	jmp    f01010b7 <vprintfmt+0x305>
	else if (lflag)
f0101085:	85 d2                	test   %edx,%edx
f0101087:	74 18                	je     f01010a1 <vprintfmt+0x2ef>
		return va_arg(*ap, long);
f0101089:	8b 45 14             	mov    0x14(%ebp),%eax
f010108c:	8d 50 04             	lea    0x4(%eax),%edx
f010108f:	89 55 14             	mov    %edx,0x14(%ebp)
f0101092:	8b 00                	mov    (%eax),%eax
f0101094:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101097:	89 c1                	mov    %eax,%ecx
f0101099:	c1 f9 1f             	sar    $0x1f,%ecx
f010109c:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f010109f:	eb 16                	jmp    f01010b7 <vprintfmt+0x305>
	else
		return va_arg(*ap, int);
f01010a1:	8b 45 14             	mov    0x14(%ebp),%eax
f01010a4:	8d 50 04             	lea    0x4(%eax),%edx
f01010a7:	89 55 14             	mov    %edx,0x14(%ebp)
f01010aa:	8b 00                	mov    (%eax),%eax
f01010ac:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01010af:	89 c7                	mov    %eax,%edi
f01010b1:	c1 ff 1f             	sar    $0x1f,%edi
f01010b4:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01010b7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01010ba:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01010bd:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01010c2:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01010c6:	0f 89 9d 00 00 00    	jns    f0101169 <vprintfmt+0x3b7>
				putch('-', putdat);
f01010cc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010d0:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01010d7:	ff d6                	call   *%esi
				num = -(long long) num;
f01010d9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01010dc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01010df:	f7 d8                	neg    %eax
f01010e1:	83 d2 00             	adc    $0x0,%edx
f01010e4:	f7 da                	neg    %edx
			}
			base = 10;
f01010e6:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01010eb:	eb 7c                	jmp    f0101169 <vprintfmt+0x3b7>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01010ed:	8d 45 14             	lea    0x14(%ebp),%eax
f01010f0:	e8 3e fc ff ff       	call   f0100d33 <getuint>
			base = 10;
f01010f5:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01010fa:	eb 6d                	jmp    f0101169 <vprintfmt+0x3b7>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f01010fc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101100:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101107:	ff d6                	call   *%esi
			putch('X', putdat);
f0101109:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010110d:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101114:	ff d6                	call   *%esi
			putch('X', putdat);
f0101116:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010111a:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101121:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101123:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0101126:	e9 ac fc ff ff       	jmp    f0100dd7 <vprintfmt+0x25>

		// pointer
		case 'p':
			putch('0', putdat);
f010112b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010112f:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101136:	ff d6                	call   *%esi
			putch('x', putdat);
f0101138:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010113c:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101143:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101145:	8b 45 14             	mov    0x14(%ebp),%eax
f0101148:	8d 50 04             	lea    0x4(%eax),%edx
f010114b:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010114e:	8b 00                	mov    (%eax),%eax
f0101150:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101155:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f010115a:	eb 0d                	jmp    f0101169 <vprintfmt+0x3b7>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010115c:	8d 45 14             	lea    0x14(%ebp),%eax
f010115f:	e8 cf fb ff ff       	call   f0100d33 <getuint>
			base = 16;
f0101164:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101169:	0f be 7d e0          	movsbl -0x20(%ebp),%edi
f010116d:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0101171:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0101174:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101178:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010117c:	89 04 24             	mov    %eax,(%esp)
f010117f:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101183:	89 da                	mov    %ebx,%edx
f0101185:	89 f0                	mov    %esi,%eax
f0101187:	e8 b4 fa ff ff       	call   f0100c40 <printnum>
			break;
f010118c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010118f:	e9 43 fc ff ff       	jmp    f0100dd7 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101194:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101198:	89 0c 24             	mov    %ecx,(%esp)
f010119b:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010119d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01011a0:	e9 32 fc ff ff       	jmp    f0100dd7 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01011a5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011a9:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01011b0:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01011b2:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01011b6:	0f 84 1b fc ff ff    	je     f0100dd7 <vprintfmt+0x25>
f01011bc:	83 ef 01             	sub    $0x1,%edi
f01011bf:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01011c3:	75 f7                	jne    f01011bc <vprintfmt+0x40a>
f01011c5:	e9 0d fc ff ff       	jmp    f0100dd7 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01011ca:	83 c4 4c             	add    $0x4c,%esp
f01011cd:	5b                   	pop    %ebx
f01011ce:	5e                   	pop    %esi
f01011cf:	5f                   	pop    %edi
f01011d0:	5d                   	pop    %ebp
f01011d1:	c3                   	ret    

f01011d2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011d2:	55                   	push   %ebp
f01011d3:	89 e5                	mov    %esp,%ebp
f01011d5:	83 ec 28             	sub    $0x28,%esp
f01011d8:	8b 45 08             	mov    0x8(%ebp),%eax
f01011db:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011de:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011e1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011e5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011e8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011ef:	85 d2                	test   %edx,%edx
f01011f1:	7e 30                	jle    f0101223 <vsnprintf+0x51>
f01011f3:	85 c0                	test   %eax,%eax
f01011f5:	74 2c                	je     f0101223 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011f7:	8b 45 14             	mov    0x14(%ebp),%eax
f01011fa:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011fe:	8b 45 10             	mov    0x10(%ebp),%eax
f0101201:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101205:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101208:	89 44 24 04          	mov    %eax,0x4(%esp)
f010120c:	c7 04 24 6d 0d 10 f0 	movl   $0xf0100d6d,(%esp)
f0101213:	e8 9a fb ff ff       	call   f0100db2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101218:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010121b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010121e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101221:	eb 05                	jmp    f0101228 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101223:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101228:	c9                   	leave  
f0101229:	c3                   	ret    

f010122a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010122a:	55                   	push   %ebp
f010122b:	89 e5                	mov    %esp,%ebp
f010122d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101230:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101233:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101237:	8b 45 10             	mov    0x10(%ebp),%eax
f010123a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010123e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101241:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101245:	8b 45 08             	mov    0x8(%ebp),%eax
f0101248:	89 04 24             	mov    %eax,(%esp)
f010124b:	e8 82 ff ff ff       	call   f01011d2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101250:	c9                   	leave  
f0101251:	c3                   	ret    
	...

f0101260 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101260:	55                   	push   %ebp
f0101261:	89 e5                	mov    %esp,%ebp
f0101263:	57                   	push   %edi
f0101264:	56                   	push   %esi
f0101265:	53                   	push   %ebx
f0101266:	83 ec 1c             	sub    $0x1c,%esp
f0101269:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010126c:	85 c0                	test   %eax,%eax
f010126e:	74 10                	je     f0101280 <readline+0x20>
		cprintf("%s", prompt);
f0101270:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101274:	c7 04 24 2a 1f 10 f0 	movl   $0xf0101f2a,(%esp)
f010127b:	e8 a6 f6 ff ff       	call   f0100926 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101280:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101287:	e8 f3 f3 ff ff       	call   f010067f <iscons>
f010128c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010128e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101293:	e8 d6 f3 ff ff       	call   f010066e <getchar>
f0101298:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010129a:	85 c0                	test   %eax,%eax
f010129c:	79 17                	jns    f01012b5 <readline+0x55>
			cprintf("read error: %e\n", c);
f010129e:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012a2:	c7 04 24 0c 21 10 f0 	movl   $0xf010210c,(%esp)
f01012a9:	e8 78 f6 ff ff       	call   f0100926 <cprintf>
			return NULL;
f01012ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01012b3:	eb 6d                	jmp    f0101322 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01012b5:	83 f8 7f             	cmp    $0x7f,%eax
f01012b8:	74 05                	je     f01012bf <readline+0x5f>
f01012ba:	83 f8 08             	cmp    $0x8,%eax
f01012bd:	75 19                	jne    f01012d8 <readline+0x78>
f01012bf:	85 f6                	test   %esi,%esi
f01012c1:	7e 15                	jle    f01012d8 <readline+0x78>
			if (echoing)
f01012c3:	85 ff                	test   %edi,%edi
f01012c5:	74 0c                	je     f01012d3 <readline+0x73>
				cputchar('\b');
f01012c7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01012ce:	e8 8b f3 ff ff       	call   f010065e <cputchar>
			i--;
f01012d3:	83 ee 01             	sub    $0x1,%esi
f01012d6:	eb bb                	jmp    f0101293 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012d8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012de:	7f 1c                	jg     f01012fc <readline+0x9c>
f01012e0:	83 fb 1f             	cmp    $0x1f,%ebx
f01012e3:	7e 17                	jle    f01012fc <readline+0x9c>
			if (echoing)
f01012e5:	85 ff                	test   %edi,%edi
f01012e7:	74 08                	je     f01012f1 <readline+0x91>
				cputchar(c);
f01012e9:	89 1c 24             	mov    %ebx,(%esp)
f01012ec:	e8 6d f3 ff ff       	call   f010065e <cputchar>
			buf[i++] = c;
f01012f1:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f01012f7:	83 c6 01             	add    $0x1,%esi
f01012fa:	eb 97                	jmp    f0101293 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01012fc:	83 fb 0d             	cmp    $0xd,%ebx
f01012ff:	74 05                	je     f0101306 <readline+0xa6>
f0101301:	83 fb 0a             	cmp    $0xa,%ebx
f0101304:	75 8d                	jne    f0101293 <readline+0x33>
			if (echoing)
f0101306:	85 ff                	test   %edi,%edi
f0101308:	74 0c                	je     f0101316 <readline+0xb6>
				cputchar('\n');
f010130a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101311:	e8 48 f3 ff ff       	call   f010065e <cputchar>
			buf[i] = 0;
f0101316:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f010131d:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f0101322:	83 c4 1c             	add    $0x1c,%esp
f0101325:	5b                   	pop    %ebx
f0101326:	5e                   	pop    %esi
f0101327:	5f                   	pop    %edi
f0101328:	5d                   	pop    %ebp
f0101329:	c3                   	ret    
f010132a:	00 00                	add    %al,(%eax)
f010132c:	00 00                	add    %al,(%eax)
	...

f0101330 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101330:	55                   	push   %ebp
f0101331:	89 e5                	mov    %esp,%ebp
f0101333:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101336:	80 3a 00             	cmpb   $0x0,(%edx)
f0101339:	74 10                	je     f010134b <strlen+0x1b>
f010133b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0101340:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101343:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101347:	75 f7                	jne    f0101340 <strlen+0x10>
f0101349:	eb 05                	jmp    f0101350 <strlen+0x20>
f010134b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101350:	5d                   	pop    %ebp
f0101351:	c3                   	ret    

f0101352 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101352:	55                   	push   %ebp
f0101353:	89 e5                	mov    %esp,%ebp
f0101355:	53                   	push   %ebx
f0101356:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101359:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010135c:	85 c9                	test   %ecx,%ecx
f010135e:	74 1c                	je     f010137c <strnlen+0x2a>
f0101360:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101363:	74 1e                	je     f0101383 <strnlen+0x31>
f0101365:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f010136a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010136c:	39 ca                	cmp    %ecx,%edx
f010136e:	74 18                	je     f0101388 <strnlen+0x36>
f0101370:	83 c2 01             	add    $0x1,%edx
f0101373:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101378:	75 f0                	jne    f010136a <strnlen+0x18>
f010137a:	eb 0c                	jmp    f0101388 <strnlen+0x36>
f010137c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101381:	eb 05                	jmp    f0101388 <strnlen+0x36>
f0101383:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101388:	5b                   	pop    %ebx
f0101389:	5d                   	pop    %ebp
f010138a:	c3                   	ret    

f010138b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010138b:	55                   	push   %ebp
f010138c:	89 e5                	mov    %esp,%ebp
f010138e:	53                   	push   %ebx
f010138f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101392:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101395:	89 c2                	mov    %eax,%edx
f0101397:	0f b6 19             	movzbl (%ecx),%ebx
f010139a:	88 1a                	mov    %bl,(%edx)
f010139c:	83 c2 01             	add    $0x1,%edx
f010139f:	83 c1 01             	add    $0x1,%ecx
f01013a2:	84 db                	test   %bl,%bl
f01013a4:	75 f1                	jne    f0101397 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01013a6:	5b                   	pop    %ebx
f01013a7:	5d                   	pop    %ebp
f01013a8:	c3                   	ret    

f01013a9 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01013a9:	55                   	push   %ebp
f01013aa:	89 e5                	mov    %esp,%ebp
f01013ac:	56                   	push   %esi
f01013ad:	53                   	push   %ebx
f01013ae:	8b 75 08             	mov    0x8(%ebp),%esi
f01013b1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013b4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013b7:	85 db                	test   %ebx,%ebx
f01013b9:	74 16                	je     f01013d1 <strncpy+0x28>
		/* do nothing */;
	return ret;
}

char *
strncpy(char *dst, const char *src, size_t size) {
f01013bb:	01 f3                	add    %esi,%ebx
f01013bd:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
f01013bf:	0f b6 02             	movzbl (%edx),%eax
f01013c2:	88 01                	mov    %al,(%ecx)
f01013c4:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01013c7:	80 3a 01             	cmpb   $0x1,(%edx)
f01013ca:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013cd:	39 d9                	cmp    %ebx,%ecx
f01013cf:	75 ee                	jne    f01013bf <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013d1:	89 f0                	mov    %esi,%eax
f01013d3:	5b                   	pop    %ebx
f01013d4:	5e                   	pop    %esi
f01013d5:	5d                   	pop    %ebp
f01013d6:	c3                   	ret    

f01013d7 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013d7:	55                   	push   %ebp
f01013d8:	89 e5                	mov    %esp,%ebp
f01013da:	57                   	push   %edi
f01013db:	56                   	push   %esi
f01013dc:	53                   	push   %ebx
f01013dd:	8b 7d 08             	mov    0x8(%ebp),%edi
f01013e0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01013e3:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013e6:	89 f8                	mov    %edi,%eax
f01013e8:	85 f6                	test   %esi,%esi
f01013ea:	74 33                	je     f010141f <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
f01013ec:	83 fe 01             	cmp    $0x1,%esi
f01013ef:	74 25                	je     f0101416 <strlcpy+0x3f>
f01013f1:	0f b6 0b             	movzbl (%ebx),%ecx
f01013f4:	84 c9                	test   %cl,%cl
f01013f6:	74 22                	je     f010141a <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f01013f8:	83 ee 02             	sub    $0x2,%esi
f01013fb:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101400:	88 08                	mov    %cl,(%eax)
f0101402:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101405:	39 f2                	cmp    %esi,%edx
f0101407:	74 13                	je     f010141c <strlcpy+0x45>
f0101409:	83 c2 01             	add    $0x1,%edx
f010140c:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0101410:	84 c9                	test   %cl,%cl
f0101412:	75 ec                	jne    f0101400 <strlcpy+0x29>
f0101414:	eb 06                	jmp    f010141c <strlcpy+0x45>
f0101416:	89 f8                	mov    %edi,%eax
f0101418:	eb 02                	jmp    f010141c <strlcpy+0x45>
f010141a:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f010141c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010141f:	29 f8                	sub    %edi,%eax
}
f0101421:	5b                   	pop    %ebx
f0101422:	5e                   	pop    %esi
f0101423:	5f                   	pop    %edi
f0101424:	5d                   	pop    %ebp
f0101425:	c3                   	ret    

f0101426 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101426:	55                   	push   %ebp
f0101427:	89 e5                	mov    %esp,%ebp
f0101429:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010142c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010142f:	0f b6 01             	movzbl (%ecx),%eax
f0101432:	84 c0                	test   %al,%al
f0101434:	74 15                	je     f010144b <strcmp+0x25>
f0101436:	3a 02                	cmp    (%edx),%al
f0101438:	75 11                	jne    f010144b <strcmp+0x25>
		p++, q++;
f010143a:	83 c1 01             	add    $0x1,%ecx
f010143d:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101440:	0f b6 01             	movzbl (%ecx),%eax
f0101443:	84 c0                	test   %al,%al
f0101445:	74 04                	je     f010144b <strcmp+0x25>
f0101447:	3a 02                	cmp    (%edx),%al
f0101449:	74 ef                	je     f010143a <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010144b:	0f b6 c0             	movzbl %al,%eax
f010144e:	0f b6 12             	movzbl (%edx),%edx
f0101451:	29 d0                	sub    %edx,%eax
}
f0101453:	5d                   	pop    %ebp
f0101454:	c3                   	ret    

f0101455 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101455:	55                   	push   %ebp
f0101456:	89 e5                	mov    %esp,%ebp
f0101458:	56                   	push   %esi
f0101459:	53                   	push   %ebx
f010145a:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010145d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101460:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0101463:	85 f6                	test   %esi,%esi
f0101465:	74 29                	je     f0101490 <strncmp+0x3b>
f0101467:	0f b6 03             	movzbl (%ebx),%eax
f010146a:	84 c0                	test   %al,%al
f010146c:	74 30                	je     f010149e <strncmp+0x49>
f010146e:	3a 02                	cmp    (%edx),%al
f0101470:	75 2c                	jne    f010149e <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f0101472:	8d 43 01             	lea    0x1(%ebx),%eax
f0101475:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
f0101477:	89 c3                	mov    %eax,%ebx
f0101479:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010147c:	39 f0                	cmp    %esi,%eax
f010147e:	74 17                	je     f0101497 <strncmp+0x42>
f0101480:	0f b6 08             	movzbl (%eax),%ecx
f0101483:	84 c9                	test   %cl,%cl
f0101485:	74 17                	je     f010149e <strncmp+0x49>
f0101487:	83 c0 01             	add    $0x1,%eax
f010148a:	3a 0a                	cmp    (%edx),%cl
f010148c:	74 e9                	je     f0101477 <strncmp+0x22>
f010148e:	eb 0e                	jmp    f010149e <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101490:	b8 00 00 00 00       	mov    $0x0,%eax
f0101495:	eb 0f                	jmp    f01014a6 <strncmp+0x51>
f0101497:	b8 00 00 00 00       	mov    $0x0,%eax
f010149c:	eb 08                	jmp    f01014a6 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010149e:	0f b6 03             	movzbl (%ebx),%eax
f01014a1:	0f b6 12             	movzbl (%edx),%edx
f01014a4:	29 d0                	sub    %edx,%eax
}
f01014a6:	5b                   	pop    %ebx
f01014a7:	5e                   	pop    %esi
f01014a8:	5d                   	pop    %ebp
f01014a9:	c3                   	ret    

f01014aa <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01014aa:	55                   	push   %ebp
f01014ab:	89 e5                	mov    %esp,%ebp
f01014ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01014b0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014b4:	0f b6 10             	movzbl (%eax),%edx
f01014b7:	84 d2                	test   %dl,%dl
f01014b9:	74 1b                	je     f01014d6 <strchr+0x2c>
		if (*s == c)
f01014bb:	38 ca                	cmp    %cl,%dl
f01014bd:	75 06                	jne    f01014c5 <strchr+0x1b>
f01014bf:	eb 1a                	jmp    f01014db <strchr+0x31>
f01014c1:	38 ca                	cmp    %cl,%dl
f01014c3:	74 16                	je     f01014db <strchr+0x31>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01014c5:	83 c0 01             	add    $0x1,%eax
f01014c8:	0f b6 10             	movzbl (%eax),%edx
f01014cb:	84 d2                	test   %dl,%dl
f01014cd:	75 f2                	jne    f01014c1 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f01014cf:	b8 00 00 00 00       	mov    $0x0,%eax
f01014d4:	eb 05                	jmp    f01014db <strchr+0x31>
f01014d6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014db:	5d                   	pop    %ebp
f01014dc:	c3                   	ret    

f01014dd <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01014dd:	55                   	push   %ebp
f01014de:	89 e5                	mov    %esp,%ebp
f01014e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e3:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014e7:	0f b6 10             	movzbl (%eax),%edx
f01014ea:	84 d2                	test   %dl,%dl
f01014ec:	74 14                	je     f0101502 <strfind+0x25>
		if (*s == c)
f01014ee:	38 ca                	cmp    %cl,%dl
f01014f0:	75 06                	jne    f01014f8 <strfind+0x1b>
f01014f2:	eb 0e                	jmp    f0101502 <strfind+0x25>
f01014f4:	38 ca                	cmp    %cl,%dl
f01014f6:	74 0a                	je     f0101502 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01014f8:	83 c0 01             	add    $0x1,%eax
f01014fb:	0f b6 10             	movzbl (%eax),%edx
f01014fe:	84 d2                	test   %dl,%dl
f0101500:	75 f2                	jne    f01014f4 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0101502:	5d                   	pop    %ebp
f0101503:	c3                   	ret    

f0101504 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101504:	55                   	push   %ebp
f0101505:	89 e5                	mov    %esp,%ebp
f0101507:	83 ec 0c             	sub    $0xc,%esp
f010150a:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010150d:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101510:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101513:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101516:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101519:	85 c9                	test   %ecx,%ecx
f010151b:	74 36                	je     f0101553 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010151d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101523:	75 28                	jne    f010154d <memset+0x49>
f0101525:	f6 c1 03             	test   $0x3,%cl
f0101528:	75 23                	jne    f010154d <memset+0x49>
		c &= 0xFF;
f010152a:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010152e:	89 d3                	mov    %edx,%ebx
f0101530:	c1 e3 08             	shl    $0x8,%ebx
f0101533:	89 d6                	mov    %edx,%esi
f0101535:	c1 e6 18             	shl    $0x18,%esi
f0101538:	89 d0                	mov    %edx,%eax
f010153a:	c1 e0 10             	shl    $0x10,%eax
f010153d:	09 f0                	or     %esi,%eax
f010153f:	09 c2                	or     %eax,%edx
f0101541:	89 d0                	mov    %edx,%eax
f0101543:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101545:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101548:	fc                   	cld    
f0101549:	f3 ab                	rep stos %eax,%es:(%edi)
f010154b:	eb 06                	jmp    f0101553 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010154d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101550:	fc                   	cld    
f0101551:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101553:	89 f8                	mov    %edi,%eax
f0101555:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101558:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010155b:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010155e:	89 ec                	mov    %ebp,%esp
f0101560:	5d                   	pop    %ebp
f0101561:	c3                   	ret    

f0101562 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101562:	55                   	push   %ebp
f0101563:	89 e5                	mov    %esp,%ebp
f0101565:	83 ec 08             	sub    $0x8,%esp
f0101568:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010156b:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010156e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101571:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101574:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101577:	39 c6                	cmp    %eax,%esi
f0101579:	73 36                	jae    f01015b1 <memmove+0x4f>
f010157b:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010157e:	39 d0                	cmp    %edx,%eax
f0101580:	73 2f                	jae    f01015b1 <memmove+0x4f>
		s += n;
		d += n;
f0101582:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101585:	f6 c2 03             	test   $0x3,%dl
f0101588:	75 1b                	jne    f01015a5 <memmove+0x43>
f010158a:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101590:	75 13                	jne    f01015a5 <memmove+0x43>
f0101592:	f6 c1 03             	test   $0x3,%cl
f0101595:	75 0e                	jne    f01015a5 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101597:	83 ef 04             	sub    $0x4,%edi
f010159a:	8d 72 fc             	lea    -0x4(%edx),%esi
f010159d:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01015a0:	fd                   	std    
f01015a1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015a3:	eb 09                	jmp    f01015ae <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01015a5:	83 ef 01             	sub    $0x1,%edi
f01015a8:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01015ab:	fd                   	std    
f01015ac:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01015ae:	fc                   	cld    
f01015af:	eb 20                	jmp    f01015d1 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015b1:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015b7:	75 13                	jne    f01015cc <memmove+0x6a>
f01015b9:	a8 03                	test   $0x3,%al
f01015bb:	75 0f                	jne    f01015cc <memmove+0x6a>
f01015bd:	f6 c1 03             	test   $0x3,%cl
f01015c0:	75 0a                	jne    f01015cc <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01015c2:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01015c5:	89 c7                	mov    %eax,%edi
f01015c7:	fc                   	cld    
f01015c8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015ca:	eb 05                	jmp    f01015d1 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01015cc:	89 c7                	mov    %eax,%edi
f01015ce:	fc                   	cld    
f01015cf:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01015d1:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01015d4:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01015d7:	89 ec                	mov    %ebp,%esp
f01015d9:	5d                   	pop    %ebp
f01015da:	c3                   	ret    

f01015db <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f01015db:	55                   	push   %ebp
f01015dc:	89 e5                	mov    %esp,%ebp
f01015de:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01015e1:	8b 45 10             	mov    0x10(%ebp),%eax
f01015e4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01015e8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015eb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01015f2:	89 04 24             	mov    %eax,(%esp)
f01015f5:	e8 68 ff ff ff       	call   f0101562 <memmove>
}
f01015fa:	c9                   	leave  
f01015fb:	c3                   	ret    

f01015fc <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01015fc:	55                   	push   %ebp
f01015fd:	89 e5                	mov    %esp,%ebp
f01015ff:	57                   	push   %edi
f0101600:	56                   	push   %esi
f0101601:	53                   	push   %ebx
f0101602:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101605:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101608:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010160b:	8d 78 ff             	lea    -0x1(%eax),%edi
f010160e:	85 c0                	test   %eax,%eax
f0101610:	74 36                	je     f0101648 <memcmp+0x4c>
		if (*s1 != *s2)
f0101612:	0f b6 03             	movzbl (%ebx),%eax
f0101615:	0f b6 0e             	movzbl (%esi),%ecx
f0101618:	38 c8                	cmp    %cl,%al
f010161a:	75 17                	jne    f0101633 <memcmp+0x37>
f010161c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101621:	eb 1a                	jmp    f010163d <memcmp+0x41>
f0101623:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0101628:	83 c2 01             	add    $0x1,%edx
f010162b:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f010162f:	38 c8                	cmp    %cl,%al
f0101631:	74 0a                	je     f010163d <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f0101633:	0f b6 c0             	movzbl %al,%eax
f0101636:	0f b6 c9             	movzbl %cl,%ecx
f0101639:	29 c8                	sub    %ecx,%eax
f010163b:	eb 10                	jmp    f010164d <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010163d:	39 fa                	cmp    %edi,%edx
f010163f:	75 e2                	jne    f0101623 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101641:	b8 00 00 00 00       	mov    $0x0,%eax
f0101646:	eb 05                	jmp    f010164d <memcmp+0x51>
f0101648:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010164d:	5b                   	pop    %ebx
f010164e:	5e                   	pop    %esi
f010164f:	5f                   	pop    %edi
f0101650:	5d                   	pop    %ebp
f0101651:	c3                   	ret    

f0101652 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101652:	55                   	push   %ebp
f0101653:	89 e5                	mov    %esp,%ebp
f0101655:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101658:	89 c2                	mov    %eax,%edx
f010165a:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010165d:	39 d0                	cmp    %edx,%eax
f010165f:	73 18                	jae    f0101679 <memfind+0x27>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101661:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0101665:	38 08                	cmp    %cl,(%eax)
f0101667:	75 09                	jne    f0101672 <memfind+0x20>
f0101669:	eb 0e                	jmp    f0101679 <memfind+0x27>
f010166b:	38 08                	cmp    %cl,(%eax)
f010166d:	8d 76 00             	lea    0x0(%esi),%esi
f0101670:	74 07                	je     f0101679 <memfind+0x27>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101672:	83 c0 01             	add    $0x1,%eax
f0101675:	39 d0                	cmp    %edx,%eax
f0101677:	75 f2                	jne    f010166b <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101679:	5d                   	pop    %ebp
f010167a:	c3                   	ret    

f010167b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010167b:	55                   	push   %ebp
f010167c:	89 e5                	mov    %esp,%ebp
f010167e:	57                   	push   %edi
f010167f:	56                   	push   %esi
f0101680:	53                   	push   %ebx
f0101681:	83 ec 04             	sub    $0x4,%esp
f0101684:	8b 55 08             	mov    0x8(%ebp),%edx
f0101687:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010168a:	0f b6 02             	movzbl (%edx),%eax
f010168d:	3c 09                	cmp    $0x9,%al
f010168f:	74 04                	je     f0101695 <strtol+0x1a>
f0101691:	3c 20                	cmp    $0x20,%al
f0101693:	75 0e                	jne    f01016a3 <strtol+0x28>
		s++;
f0101695:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101698:	0f b6 02             	movzbl (%edx),%eax
f010169b:	3c 09                	cmp    $0x9,%al
f010169d:	74 f6                	je     f0101695 <strtol+0x1a>
f010169f:	3c 20                	cmp    $0x20,%al
f01016a1:	74 f2                	je     f0101695 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f01016a3:	3c 2b                	cmp    $0x2b,%al
f01016a5:	75 0a                	jne    f01016b1 <strtol+0x36>
		s++;
f01016a7:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01016aa:	bf 00 00 00 00       	mov    $0x0,%edi
f01016af:	eb 10                	jmp    f01016c1 <strtol+0x46>
f01016b1:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01016b6:	3c 2d                	cmp    $0x2d,%al
f01016b8:	75 07                	jne    f01016c1 <strtol+0x46>
		s++, neg = 1;
f01016ba:	83 c2 01             	add    $0x1,%edx
f01016bd:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016c1:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01016c7:	75 15                	jne    f01016de <strtol+0x63>
f01016c9:	80 3a 30             	cmpb   $0x30,(%edx)
f01016cc:	75 10                	jne    f01016de <strtol+0x63>
f01016ce:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01016d2:	75 0a                	jne    f01016de <strtol+0x63>
		s += 2, base = 16;
f01016d4:	83 c2 02             	add    $0x2,%edx
f01016d7:	bb 10 00 00 00       	mov    $0x10,%ebx
f01016dc:	eb 10                	jmp    f01016ee <strtol+0x73>
	else if (base == 0 && s[0] == '0')
f01016de:	85 db                	test   %ebx,%ebx
f01016e0:	75 0c                	jne    f01016ee <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01016e2:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01016e4:	80 3a 30             	cmpb   $0x30,(%edx)
f01016e7:	75 05                	jne    f01016ee <strtol+0x73>
		s++, base = 8;
f01016e9:	83 c2 01             	add    $0x1,%edx
f01016ec:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f01016ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01016f3:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01016f6:	0f b6 0a             	movzbl (%edx),%ecx
f01016f9:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01016fc:	89 f3                	mov    %esi,%ebx
f01016fe:	80 fb 09             	cmp    $0x9,%bl
f0101701:	77 08                	ja     f010170b <strtol+0x90>
			dig = *s - '0';
f0101703:	0f be c9             	movsbl %cl,%ecx
f0101706:	83 e9 30             	sub    $0x30,%ecx
f0101709:	eb 22                	jmp    f010172d <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
f010170b:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010170e:	89 f3                	mov    %esi,%ebx
f0101710:	80 fb 19             	cmp    $0x19,%bl
f0101713:	77 08                	ja     f010171d <strtol+0xa2>
			dig = *s - 'a' + 10;
f0101715:	0f be c9             	movsbl %cl,%ecx
f0101718:	83 e9 57             	sub    $0x57,%ecx
f010171b:	eb 10                	jmp    f010172d <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
f010171d:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0101720:	89 f3                	mov    %esi,%ebx
f0101722:	80 fb 19             	cmp    $0x19,%bl
f0101725:	77 16                	ja     f010173d <strtol+0xc2>
			dig = *s - 'A' + 10;
f0101727:	0f be c9             	movsbl %cl,%ecx
f010172a:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f010172d:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0101730:	7d 0f                	jge    f0101741 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
f0101732:	83 c2 01             	add    $0x1,%edx
f0101735:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0101739:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f010173b:	eb b9                	jmp    f01016f6 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f010173d:	89 c1                	mov    %eax,%ecx
f010173f:	eb 02                	jmp    f0101743 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101741:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101743:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101747:	74 05                	je     f010174e <strtol+0xd3>
		*endptr = (char *) s;
f0101749:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010174c:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f010174e:	85 ff                	test   %edi,%edi
f0101750:	74 04                	je     f0101756 <strtol+0xdb>
f0101752:	89 c8                	mov    %ecx,%eax
f0101754:	f7 d8                	neg    %eax
}
f0101756:	83 c4 04             	add    $0x4,%esp
f0101759:	5b                   	pop    %ebx
f010175a:	5e                   	pop    %esi
f010175b:	5f                   	pop    %edi
f010175c:	5d                   	pop    %ebp
f010175d:	c3                   	ret    
	...

f0101760 <__udivdi3>:
f0101760:	83 ec 1c             	sub    $0x1c,%esp
f0101763:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0101767:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f010176b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f010176f:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101773:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101777:	8b 74 24 24          	mov    0x24(%esp),%esi
f010177b:	85 c0                	test   %eax,%eax
f010177d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101781:	89 cf                	mov    %ecx,%edi
f0101783:	89 6c 24 04          	mov    %ebp,0x4(%esp)
f0101787:	75 37                	jne    f01017c0 <__udivdi3+0x60>
f0101789:	39 f1                	cmp    %esi,%ecx
f010178b:	77 73                	ja     f0101800 <__udivdi3+0xa0>
f010178d:	85 c9                	test   %ecx,%ecx
f010178f:	75 0b                	jne    f010179c <__udivdi3+0x3c>
f0101791:	b8 01 00 00 00       	mov    $0x1,%eax
f0101796:	31 d2                	xor    %edx,%edx
f0101798:	f7 f1                	div    %ecx
f010179a:	89 c1                	mov    %eax,%ecx
f010179c:	89 f0                	mov    %esi,%eax
f010179e:	31 d2                	xor    %edx,%edx
f01017a0:	f7 f1                	div    %ecx
f01017a2:	89 c6                	mov    %eax,%esi
f01017a4:	89 e8                	mov    %ebp,%eax
f01017a6:	f7 f1                	div    %ecx
f01017a8:	89 f2                	mov    %esi,%edx
f01017aa:	8b 74 24 10          	mov    0x10(%esp),%esi
f01017ae:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01017b2:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01017b6:	83 c4 1c             	add    $0x1c,%esp
f01017b9:	c3                   	ret    
f01017ba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01017c0:	39 f0                	cmp    %esi,%eax
f01017c2:	77 24                	ja     f01017e8 <__udivdi3+0x88>
f01017c4:	0f bd e8             	bsr    %eax,%ebp
f01017c7:	83 f5 1f             	xor    $0x1f,%ebp
f01017ca:	75 4c                	jne    f0101818 <__udivdi3+0xb8>
f01017cc:	31 d2                	xor    %edx,%edx
f01017ce:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f01017d2:	0f 86 b0 00 00 00    	jbe    f0101888 <__udivdi3+0x128>
f01017d8:	39 f0                	cmp    %esi,%eax
f01017da:	0f 82 a8 00 00 00    	jb     f0101888 <__udivdi3+0x128>
f01017e0:	31 c0                	xor    %eax,%eax
f01017e2:	eb c6                	jmp    f01017aa <__udivdi3+0x4a>
f01017e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017e8:	31 d2                	xor    %edx,%edx
f01017ea:	31 c0                	xor    %eax,%eax
f01017ec:	8b 74 24 10          	mov    0x10(%esp),%esi
f01017f0:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01017f4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01017f8:	83 c4 1c             	add    $0x1c,%esp
f01017fb:	c3                   	ret    
f01017fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101800:	89 e8                	mov    %ebp,%eax
f0101802:	89 f2                	mov    %esi,%edx
f0101804:	f7 f1                	div    %ecx
f0101806:	31 d2                	xor    %edx,%edx
f0101808:	8b 74 24 10          	mov    0x10(%esp),%esi
f010180c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101810:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101814:	83 c4 1c             	add    $0x1c,%esp
f0101817:	c3                   	ret    
f0101818:	89 e9                	mov    %ebp,%ecx
f010181a:	89 fa                	mov    %edi,%edx
f010181c:	d3 e0                	shl    %cl,%eax
f010181e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101822:	b8 20 00 00 00       	mov    $0x20,%eax
f0101827:	29 e8                	sub    %ebp,%eax
f0101829:	89 c1                	mov    %eax,%ecx
f010182b:	d3 ea                	shr    %cl,%edx
f010182d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101831:	09 ca                	or     %ecx,%edx
f0101833:	89 e9                	mov    %ebp,%ecx
f0101835:	d3 e7                	shl    %cl,%edi
f0101837:	89 c1                	mov    %eax,%ecx
f0101839:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010183d:	89 f2                	mov    %esi,%edx
f010183f:	d3 ea                	shr    %cl,%edx
f0101841:	89 e9                	mov    %ebp,%ecx
f0101843:	89 14 24             	mov    %edx,(%esp)
f0101846:	8b 54 24 04          	mov    0x4(%esp),%edx
f010184a:	d3 e6                	shl    %cl,%esi
f010184c:	89 c1                	mov    %eax,%ecx
f010184e:	d3 ea                	shr    %cl,%edx
f0101850:	89 d0                	mov    %edx,%eax
f0101852:	09 f0                	or     %esi,%eax
f0101854:	8b 34 24             	mov    (%esp),%esi
f0101857:	89 f2                	mov    %esi,%edx
f0101859:	f7 74 24 0c          	divl   0xc(%esp)
f010185d:	89 d6                	mov    %edx,%esi
f010185f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101863:	f7 e7                	mul    %edi
f0101865:	39 d6                	cmp    %edx,%esi
f0101867:	72 2f                	jb     f0101898 <__udivdi3+0x138>
f0101869:	8b 7c 24 04          	mov    0x4(%esp),%edi
f010186d:	89 e9                	mov    %ebp,%ecx
f010186f:	d3 e7                	shl    %cl,%edi
f0101871:	39 c7                	cmp    %eax,%edi
f0101873:	73 04                	jae    f0101879 <__udivdi3+0x119>
f0101875:	39 d6                	cmp    %edx,%esi
f0101877:	74 1f                	je     f0101898 <__udivdi3+0x138>
f0101879:	8b 44 24 08          	mov    0x8(%esp),%eax
f010187d:	31 d2                	xor    %edx,%edx
f010187f:	e9 26 ff ff ff       	jmp    f01017aa <__udivdi3+0x4a>
f0101884:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101888:	b8 01 00 00 00       	mov    $0x1,%eax
f010188d:	e9 18 ff ff ff       	jmp    f01017aa <__udivdi3+0x4a>
f0101892:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101898:	8b 44 24 08          	mov    0x8(%esp),%eax
f010189c:	31 d2                	xor    %edx,%edx
f010189e:	83 e8 01             	sub    $0x1,%eax
f01018a1:	8b 74 24 10          	mov    0x10(%esp),%esi
f01018a5:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01018a9:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01018ad:	83 c4 1c             	add    $0x1c,%esp
f01018b0:	c3                   	ret    
	...

f01018c0 <__umoddi3>:
f01018c0:	83 ec 1c             	sub    $0x1c,%esp
f01018c3:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f01018c7:	8b 44 24 20          	mov    0x20(%esp),%eax
f01018cb:	89 74 24 10          	mov    %esi,0x10(%esp)
f01018cf:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01018d3:	8b 74 24 24          	mov    0x24(%esp),%esi
f01018d7:	85 d2                	test   %edx,%edx
f01018d9:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01018dd:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01018e1:	89 cf                	mov    %ecx,%edi
f01018e3:	89 c5                	mov    %eax,%ebp
f01018e5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01018e9:	89 34 24             	mov    %esi,(%esp)
f01018ec:	75 22                	jne    f0101910 <__umoddi3+0x50>
f01018ee:	39 f1                	cmp    %esi,%ecx
f01018f0:	76 56                	jbe    f0101948 <__umoddi3+0x88>
f01018f2:	89 f2                	mov    %esi,%edx
f01018f4:	f7 f1                	div    %ecx
f01018f6:	89 d0                	mov    %edx,%eax
f01018f8:	31 d2                	xor    %edx,%edx
f01018fa:	8b 74 24 10          	mov    0x10(%esp),%esi
f01018fe:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101902:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101906:	83 c4 1c             	add    $0x1c,%esp
f0101909:	c3                   	ret    
f010190a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101910:	39 f2                	cmp    %esi,%edx
f0101912:	77 54                	ja     f0101968 <__umoddi3+0xa8>
f0101914:	0f bd c2             	bsr    %edx,%eax
f0101917:	83 f0 1f             	xor    $0x1f,%eax
f010191a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010191e:	75 60                	jne    f0101980 <__umoddi3+0xc0>
f0101920:	39 e9                	cmp    %ebp,%ecx
f0101922:	0f 87 08 01 00 00    	ja     f0101a30 <__umoddi3+0x170>
f0101928:	29 cd                	sub    %ecx,%ebp
f010192a:	19 d6                	sbb    %edx,%esi
f010192c:	89 34 24             	mov    %esi,(%esp)
f010192f:	8b 14 24             	mov    (%esp),%edx
f0101932:	89 e8                	mov    %ebp,%eax
f0101934:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101938:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010193c:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101940:	83 c4 1c             	add    $0x1c,%esp
f0101943:	c3                   	ret    
f0101944:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101948:	85 c9                	test   %ecx,%ecx
f010194a:	75 0b                	jne    f0101957 <__umoddi3+0x97>
f010194c:	b8 01 00 00 00       	mov    $0x1,%eax
f0101951:	31 d2                	xor    %edx,%edx
f0101953:	f7 f1                	div    %ecx
f0101955:	89 c1                	mov    %eax,%ecx
f0101957:	89 f0                	mov    %esi,%eax
f0101959:	31 d2                	xor    %edx,%edx
f010195b:	f7 f1                	div    %ecx
f010195d:	89 e8                	mov    %ebp,%eax
f010195f:	f7 f1                	div    %ecx
f0101961:	eb 93                	jmp    f01018f6 <__umoddi3+0x36>
f0101963:	90                   	nop
f0101964:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101968:	89 f2                	mov    %esi,%edx
f010196a:	8b 74 24 10          	mov    0x10(%esp),%esi
f010196e:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101972:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101976:	83 c4 1c             	add    $0x1c,%esp
f0101979:	c3                   	ret    
f010197a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101980:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101985:	bd 20 00 00 00       	mov    $0x20,%ebp
f010198a:	89 f8                	mov    %edi,%eax
f010198c:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0101990:	d3 e2                	shl    %cl,%edx
f0101992:	89 e9                	mov    %ebp,%ecx
f0101994:	d3 e8                	shr    %cl,%eax
f0101996:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010199b:	09 d0                	or     %edx,%eax
f010199d:	89 f2                	mov    %esi,%edx
f010199f:	89 04 24             	mov    %eax,(%esp)
f01019a2:	8b 44 24 08          	mov    0x8(%esp),%eax
f01019a6:	d3 e7                	shl    %cl,%edi
f01019a8:	89 e9                	mov    %ebp,%ecx
f01019aa:	d3 ea                	shr    %cl,%edx
f01019ac:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019b1:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01019b5:	d3 e6                	shl    %cl,%esi
f01019b7:	89 e9                	mov    %ebp,%ecx
f01019b9:	d3 e8                	shr    %cl,%eax
f01019bb:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019c0:	09 f0                	or     %esi,%eax
f01019c2:	8b 74 24 08          	mov    0x8(%esp),%esi
f01019c6:	f7 34 24             	divl   (%esp)
f01019c9:	d3 e6                	shl    %cl,%esi
f01019cb:	89 74 24 08          	mov    %esi,0x8(%esp)
f01019cf:	89 d6                	mov    %edx,%esi
f01019d1:	f7 e7                	mul    %edi
f01019d3:	39 d6                	cmp    %edx,%esi
f01019d5:	89 c7                	mov    %eax,%edi
f01019d7:	89 d1                	mov    %edx,%ecx
f01019d9:	72 41                	jb     f0101a1c <__umoddi3+0x15c>
f01019db:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01019df:	72 37                	jb     f0101a18 <__umoddi3+0x158>
f01019e1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01019e5:	29 f8                	sub    %edi,%eax
f01019e7:	19 ce                	sbb    %ecx,%esi
f01019e9:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019ee:	89 f2                	mov    %esi,%edx
f01019f0:	d3 e8                	shr    %cl,%eax
f01019f2:	89 e9                	mov    %ebp,%ecx
f01019f4:	d3 e2                	shl    %cl,%edx
f01019f6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019fb:	09 d0                	or     %edx,%eax
f01019fd:	89 f2                	mov    %esi,%edx
f01019ff:	d3 ea                	shr    %cl,%edx
f0101a01:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a05:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a09:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a0d:	83 c4 1c             	add    $0x1c,%esp
f0101a10:	c3                   	ret    
f0101a11:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a18:	39 d6                	cmp    %edx,%esi
f0101a1a:	75 c5                	jne    f01019e1 <__umoddi3+0x121>
f0101a1c:	89 d1                	mov    %edx,%ecx
f0101a1e:	89 c7                	mov    %eax,%edi
f0101a20:	2b 7c 24 0c          	sub    0xc(%esp),%edi
f0101a24:	1b 0c 24             	sbb    (%esp),%ecx
f0101a27:	eb b8                	jmp    f01019e1 <__umoddi3+0x121>
f0101a29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a30:	39 f2                	cmp    %esi,%edx
f0101a32:	0f 82 f0 fe ff ff    	jb     f0101928 <__umoddi3+0x68>
f0101a38:	e9 f2 fe ff ff       	jmp    f010192f <__umoddi3+0x6f>
