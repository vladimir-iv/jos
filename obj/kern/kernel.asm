
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
f010004e:	c7 04 24 60 1b 10 f0 	movl   $0xf0101b60,(%esp)
f0100055:	e8 a0 09 00 00       	call   f01009fa <cprintf>
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
f0100082:	e8 f7 06 00 00       	call   f010077e <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 7c 1b 10 f0 	movl   $0xf0101b7c,(%esp)
f0100092:	e8 63 09 00 00       	call   f01009fa <cprintf>
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
f01000c0:	e8 4f 15 00 00       	call   f0101614 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 9f 04 00 00       	call   f0100569 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 97 1b 10 f0 	movl   $0xf0101b97,(%esp)
f01000d9:	e8 1c 09 00 00       	call   f01009fa <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 80 07 00 00       	call   f0100876 <monitor>
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
f0100125:	c7 04 24 b2 1b 10 f0 	movl   $0xf0101bb2,(%esp)
f010012c:	e8 c9 08 00 00       	call   f01009fa <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 8a 08 00 00       	call   f01009c7 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 ee 1b 10 f0 	movl   $0xf0101bee,(%esp)
f0100144:	e8 b1 08 00 00       	call   f01009fa <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 21 07 00 00       	call   f0100876 <monitor>
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
f010016f:	c7 04 24 ca 1b 10 f0 	movl   $0xf0101bca,(%esp)
f0100176:	e8 7f 08 00 00       	call   f01009fa <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 3d 08 00 00       	call   f01009c7 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 ee 1b 10 f0 	movl   $0xf0101bee,(%esp)
f0100191:	e8 64 08 00 00       	call   f01009fa <cprintf>
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
f010038f:	e8 de 12 00 00       	call   f0101672 <memmove>
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
f0100433:	0f b6 82 20 1c 10 f0 	movzbl -0xfefe3e0(%edx),%eax
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
f0100470:	0f b6 90 20 1c 10 f0 	movzbl -0xfefe3e0(%eax),%edx
f0100477:	0b 15 48 25 11 f0    	or     0xf0112548,%edx
	shift ^= togglecode[data];
f010047d:	0f b6 88 20 1d 10 f0 	movzbl -0xfefe2e0(%eax),%ecx
f0100484:	31 ca                	xor    %ecx,%edx
f0100486:	89 15 48 25 11 f0    	mov    %edx,0xf0112548

	c = charcode[shift & (CTL | SHIFT)][data];
f010048c:	89 d1                	mov    %edx,%ecx
f010048e:	83 e1 03             	and    $0x3,%ecx
f0100491:	8b 0c 8d 20 1e 10 f0 	mov    -0xfefe1e0(,%ecx,4),%ecx
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
f01004cd:	c7 04 24 e4 1b 10 f0 	movl   $0xf0101be4,(%esp)
f01004d4:	e8 21 05 00 00       	call   f01009fa <cprintf>
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
f010064a:	c7 04 24 f0 1b 10 f0 	movl   $0xf0101bf0,(%esp)
f0100651:	e8 a4 03 00 00       	call   f01009fa <cprintf>
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
f0100696:	c7 04 24 30 1e 10 f0 	movl   $0xf0101e30,(%esp)
f010069d:	e8 58 03 00 00       	call   f01009fa <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006a2:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006a9:	00 
f01006aa:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006b1:	f0 
f01006b2:	c7 04 24 24 1f 10 f0 	movl   $0xf0101f24,(%esp)
f01006b9:	e8 3c 03 00 00       	call   f01009fa <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006be:	c7 44 24 08 4d 1b 10 	movl   $0x101b4d,0x8(%esp)
f01006c5:	00 
f01006c6:	c7 44 24 04 4d 1b 10 	movl   $0xf0101b4d,0x4(%esp)
f01006cd:	f0 
f01006ce:	c7 04 24 48 1f 10 f0 	movl   $0xf0101f48,(%esp)
f01006d5:	e8 20 03 00 00       	call   f01009fa <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006da:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f01006e1:	00 
f01006e2:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f01006e9:	f0 
f01006ea:	c7 04 24 6c 1f 10 f0 	movl   $0xf0101f6c,(%esp)
f01006f1:	e8 04 03 00 00       	call   f01009fa <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006f6:	c7 44 24 08 60 29 11 	movl   $0x112960,0x8(%esp)
f01006fd:	00 
f01006fe:	c7 44 24 04 60 29 11 	movl   $0xf0112960,0x4(%esp)
f0100705:	f0 
f0100706:	c7 04 24 90 1f 10 f0 	movl   $0xf0101f90,(%esp)
f010070d:	e8 e8 02 00 00       	call   f01009fa <cprintf>
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
f010072d:	c7 04 24 b4 1f 10 f0 	movl   $0xf0101fb4,(%esp)
f0100734:	e8 c1 02 00 00       	call   f01009fa <cprintf>
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
f0100743:	56                   	push   %esi
f0100744:	53                   	push   %ebx
f0100745:	83 ec 10             	sub    $0x10,%esp
f0100748:	bb 84 20 10 f0       	mov    $0xf0102084,%ebx
unsigned read_eip();

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
f010074d:	be a8 20 10 f0       	mov    $0xf01020a8,%esi
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100752:	8b 03                	mov    (%ebx),%eax
f0100754:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100758:	8b 43 fc             	mov    -0x4(%ebx),%eax
f010075b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010075f:	c7 04 24 49 1e 10 f0 	movl   $0xf0101e49,(%esp)
f0100766:	e8 8f 02 00 00       	call   f01009fa <cprintf>
f010076b:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f010076e:	39 f3                	cmp    %esi,%ebx
f0100770:	75 e0                	jne    f0100752 <mon_help+0x12>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100772:	b8 00 00 00 00       	mov    $0x0,%eax
f0100777:	83 c4 10             	add    $0x10,%esp
f010077a:	5b                   	pop    %ebx
f010077b:	5e                   	pop    %esi
f010077c:	5d                   	pop    %ebp
f010077d:	c3                   	ret    

f010077e <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010077e:	55                   	push   %ebp
f010077f:	89 e5                	mov    %esp,%ebp
f0100781:	57                   	push   %edi
f0100782:	56                   	push   %esi
f0100783:	53                   	push   %ebx
f0100784:	83 ec 5c             	sub    $0x5c,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100787:	89 ef                	mov    %ebp,%edi

	uint32_t ebp_x = read_ebp();
	struct Eipdebuginfo info;
	
	cprintf("Stack backtrace:\n");
f0100789:	c7 04 24 52 1e 10 f0 	movl   $0xf0101e52,(%esp)
f0100790:	e8 65 02 00 00       	call   f01009fa <cprintf>
	
	do
	{
		
		uint32_t eip_x = *((uint32_t*)(ebp_x + 4));
f0100795:	8b 5f 04             	mov    0x4(%edi),%ebx
		uint32_t arg_1 = *((uint32_t*)(ebp_x + 8));
f0100798:	8b 47 08             	mov    0x8(%edi),%eax
f010079b:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		uint32_t arg_2 = *((uint32_t*)(ebp_x + 12));
f010079e:	8b 47 0c             	mov    0xc(%edi),%eax
f01007a1:	89 45 c0             	mov    %eax,-0x40(%ebp)
		uint32_t arg_3 = *((uint32_t*)(ebp_x + 16));
f01007a4:	8b 47 10             	mov    0x10(%edi),%eax
f01007a7:	89 45 bc             	mov    %eax,-0x44(%ebp)
		uint32_t arg_4 = *((uint32_t*)(ebp_x + 20));
f01007aa:	8b 47 14             	mov    0x14(%edi),%eax
f01007ad:	89 45 b8             	mov    %eax,-0x48(%ebp)
		uint32_t arg_5 = *((uint32_t*)(ebp_x + 24));
f01007b0:	8b 77 18             	mov    0x18(%edi),%esi
		
		debuginfo_eip((uintptr_t)eip_x, &info);
f01007b3:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007b6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007ba:	89 1c 24             	mov    %ebx,(%esp)
f01007bd:	e8 3b 03 00 00       	call   f0100afd <debuginfo_eip>
		
		
		
		cprintf("  ebp %08x  eip %08x  ", ebp_x, eip_x);
f01007c2:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01007c6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007ca:	c7 04 24 64 1e 10 f0 	movl   $0xf0101e64,(%esp)
f01007d1:	e8 24 02 00 00       	call   f01009fa <cprintf>
	    cprintf("args %08x %08x %08x %08x %08x\n", arg_1, arg_2, arg_3, arg_4, arg_5);
f01007d6:	89 74 24 14          	mov    %esi,0x14(%esp)
f01007da:	8b 45 b8             	mov    -0x48(%ebp),%eax
f01007dd:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007e1:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01007e4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007e8:	8b 45 c0             	mov    -0x40(%ebp),%eax
f01007eb:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007ef:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01007f2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007f6:	c7 04 24 e0 1f 10 f0 	movl   $0xf0101fe0,(%esp)
f01007fd:	e8 f8 01 00 00       	call   f01009fa <cprintf>
	   
	    cprintf("         %s:%d: ", info.eip_file, info.eip_line);
f0100802:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100805:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100809:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010080c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100810:	c7 04 24 7b 1e 10 f0 	movl   $0xf0101e7b,(%esp)
f0100817:	e8 de 01 00 00       	call   f01009fa <cprintf>
	    
	    int i;
	    for(i = 0; i < info.eip_fn_namelen; i++)
f010081c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100820:	7e 24                	jle    f0100846 <mon_backtrace+0xc8>
f0100822:	be 00 00 00 00       	mov    $0x0,%esi
			cprintf("%c", info.eip_fn_name[i]);
f0100827:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010082a:	0f be 04 30          	movsbl (%eax,%esi,1),%eax
f010082e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100832:	c7 04 24 8c 1e 10 f0 	movl   $0xf0101e8c,(%esp)
f0100839:	e8 bc 01 00 00       	call   f01009fa <cprintf>
	    cprintf("args %08x %08x %08x %08x %08x\n", arg_1, arg_2, arg_3, arg_4, arg_5);
	   
	    cprintf("         %s:%d: ", info.eip_file, info.eip_line);
	    
	    int i;
	    for(i = 0; i < info.eip_fn_namelen; i++)
f010083e:	83 c6 01             	add    $0x1,%esi
f0100841:	39 75 dc             	cmp    %esi,-0x24(%ebp)
f0100844:	7f e1                	jg     f0100827 <mon_backtrace+0xa9>
			cprintf("%c", info.eip_fn_name[i]);
			
		uintptr_t offs = (uintptr_t)eip_x - info.eip_fn_addr;	
f0100846:	2b 5d e0             	sub    -0x20(%ebp),%ebx
		cprintf("+%d\n", (int)offs);
f0100849:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010084d:	c7 04 24 8f 1e 10 f0 	movl   $0xf0101e8f,(%esp)
f0100854:	e8 a1 01 00 00       	call   f01009fa <cprintf>
	    
		ebp_x = *((uint32_t*)ebp_x);
f0100859:	8b 3f                	mov    (%edi),%edi
	} 
	while((ebp_x <= 0xf0110000) && (ebp_x != 0x0));
f010085b:	8d 47 ff             	lea    -0x1(%edi),%eax
f010085e:	3d ff ff 10 f0       	cmp    $0xf010ffff,%eax
f0100863:	0f 86 2c ff ff ff    	jbe    f0100795 <mon_backtrace+0x17>
	
	return 0;
}
f0100869:	b8 00 00 00 00       	mov    $0x0,%eax
f010086e:	83 c4 5c             	add    $0x5c,%esp
f0100871:	5b                   	pop    %ebx
f0100872:	5e                   	pop    %esi
f0100873:	5f                   	pop    %edi
f0100874:	5d                   	pop    %ebp
f0100875:	c3                   	ret    

f0100876 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100876:	55                   	push   %ebp
f0100877:	89 e5                	mov    %esp,%ebp
f0100879:	57                   	push   %edi
f010087a:	56                   	push   %esi
f010087b:	53                   	push   %ebx
f010087c:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010087f:	c7 04 24 00 20 10 f0 	movl   $0xf0102000,(%esp)
f0100886:	e8 6f 01 00 00       	call   f01009fa <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010088b:	c7 04 24 24 20 10 f0 	movl   $0xf0102024,(%esp)
f0100892:	e8 63 01 00 00       	call   f01009fa <cprintf>


	while (1) {
		buf = readline("K> ");
f0100897:	c7 04 24 94 1e 10 f0 	movl   $0xf0101e94,(%esp)
f010089e:	e8 cd 0a 00 00       	call   f0101370 <readline>
f01008a3:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f01008a5:	85 c0                	test   %eax,%eax
f01008a7:	74 ee                	je     f0100897 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008a9:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008b0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01008b5:	eb 06                	jmp    f01008bd <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008b7:	c6 06 00             	movb   $0x0,(%esi)
f01008ba:	83 c6 01             	add    $0x1,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008bd:	0f b6 06             	movzbl (%esi),%eax
f01008c0:	84 c0                	test   %al,%al
f01008c2:	74 6a                	je     f010092e <monitor+0xb8>
f01008c4:	0f be c0             	movsbl %al,%eax
f01008c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008cb:	c7 04 24 98 1e 10 f0 	movl   $0xf0101e98,(%esp)
f01008d2:	e8 e3 0c 00 00       	call   f01015ba <strchr>
f01008d7:	85 c0                	test   %eax,%eax
f01008d9:	75 dc                	jne    f01008b7 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008db:	80 3e 00             	cmpb   $0x0,(%esi)
f01008de:	74 4e                	je     f010092e <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008e0:	83 fb 0f             	cmp    $0xf,%ebx
f01008e3:	75 16                	jne    f01008fb <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008e5:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008ec:	00 
f01008ed:	c7 04 24 9d 1e 10 f0 	movl   $0xf0101e9d,(%esp)
f01008f4:	e8 01 01 00 00       	call   f01009fa <cprintf>
f01008f9:	eb 9c                	jmp    f0100897 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008fb:	89 74 9d a8          	mov    %esi,-0x58(%ebp,%ebx,4)
f01008ff:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f0100902:	0f b6 06             	movzbl (%esi),%eax
f0100905:	84 c0                	test   %al,%al
f0100907:	75 0c                	jne    f0100915 <monitor+0x9f>
f0100909:	eb b2                	jmp    f01008bd <monitor+0x47>
			buf++;
f010090b:	83 c6 01             	add    $0x1,%esi
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010090e:	0f b6 06             	movzbl (%esi),%eax
f0100911:	84 c0                	test   %al,%al
f0100913:	74 a8                	je     f01008bd <monitor+0x47>
f0100915:	0f be c0             	movsbl %al,%eax
f0100918:	89 44 24 04          	mov    %eax,0x4(%esp)
f010091c:	c7 04 24 98 1e 10 f0 	movl   $0xf0101e98,(%esp)
f0100923:	e8 92 0c 00 00       	call   f01015ba <strchr>
f0100928:	85 c0                	test   %eax,%eax
f010092a:	74 df                	je     f010090b <monitor+0x95>
f010092c:	eb 8f                	jmp    f01008bd <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f010092e:	c7 44 9d a8 00 00 00 	movl   $0x0,-0x58(%ebp,%ebx,4)
f0100935:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100936:	85 db                	test   %ebx,%ebx
f0100938:	0f 84 59 ff ff ff    	je     f0100897 <monitor+0x21>
f010093e:	bf 80 20 10 f0       	mov    $0xf0102080,%edi
f0100943:	be 00 00 00 00       	mov    $0x0,%esi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100948:	8b 07                	mov    (%edi),%eax
f010094a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010094e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100951:	89 04 24             	mov    %eax,(%esp)
f0100954:	e8 dd 0b 00 00       	call   f0101536 <strcmp>
f0100959:	85 c0                	test   %eax,%eax
f010095b:	75 24                	jne    f0100981 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010095d:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100960:	8b 55 08             	mov    0x8(%ebp),%edx
f0100963:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100967:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010096a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010096e:	89 1c 24             	mov    %ebx,(%esp)
f0100971:	ff 14 85 88 20 10 f0 	call   *-0xfefdf78(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100978:	85 c0                	test   %eax,%eax
f010097a:	78 28                	js     f01009a4 <monitor+0x12e>
f010097c:	e9 16 ff ff ff       	jmp    f0100897 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100981:	83 c6 01             	add    $0x1,%esi
f0100984:	83 c7 0c             	add    $0xc,%edi
f0100987:	83 fe 03             	cmp    $0x3,%esi
f010098a:	75 bc                	jne    f0100948 <monitor+0xd2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010098c:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010098f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100993:	c7 04 24 ba 1e 10 f0 	movl   $0xf0101eba,(%esp)
f010099a:	e8 5b 00 00 00       	call   f01009fa <cprintf>
f010099f:	e9 f3 fe ff ff       	jmp    f0100897 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009a4:	83 c4 5c             	add    $0x5c,%esp
f01009a7:	5b                   	pop    %ebx
f01009a8:	5e                   	pop    %esi
f01009a9:	5f                   	pop    %edi
f01009aa:	5d                   	pop    %ebp
f01009ab:	c3                   	ret    

f01009ac <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f01009ac:	55                   	push   %ebp
f01009ad:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01009af:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01009b2:	5d                   	pop    %ebp
f01009b3:	c3                   	ret    

f01009b4 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009b4:	55                   	push   %ebp
f01009b5:	89 e5                	mov    %esp,%ebp
f01009b7:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01009ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01009bd:	89 04 24             	mov    %eax,(%esp)
f01009c0:	e8 99 fc ff ff       	call   f010065e <cputchar>
	*cnt++;
}
f01009c5:	c9                   	leave  
f01009c6:	c3                   	ret    

f01009c7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009c7:	55                   	push   %ebp
f01009c8:	89 e5                	mov    %esp,%ebp
f01009ca:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009cd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009d4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009d7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009db:	8b 45 08             	mov    0x8(%ebp),%eax
f01009de:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009e2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009e5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009e9:	c7 04 24 b4 09 10 f0 	movl   $0xf01009b4,(%esp)
f01009f0:	e8 fd 04 00 00       	call   f0100ef2 <vprintfmt>
	return cnt;
}
f01009f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009f8:	c9                   	leave  
f01009f9:	c3                   	ret    

f01009fa <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009fa:	55                   	push   %ebp
f01009fb:	89 e5                	mov    %esp,%ebp
f01009fd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a00:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a03:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a07:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a0a:	89 04 24             	mov    %eax,(%esp)
f0100a0d:	e8 b5 ff ff ff       	call   f01009c7 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a12:	c9                   	leave  
f0100a13:	c3                   	ret    
	...

f0100a20 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a20:	55                   	push   %ebp
f0100a21:	89 e5                	mov    %esp,%ebp
f0100a23:	57                   	push   %edi
f0100a24:	56                   	push   %esi
f0100a25:	53                   	push   %ebx
f0100a26:	83 ec 10             	sub    $0x10,%esp
f0100a29:	89 c6                	mov    %eax,%esi
f0100a2b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a2e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a31:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a34:	8b 1a                	mov    (%edx),%ebx
f0100a36:	8b 09                	mov    (%ecx),%ecx
f0100a38:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100a3b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0100a42:	eb 77                	jmp    f0100abb <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a44:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a47:	01 d8                	add    %ebx,%eax
f0100a49:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a4e:	99                   	cltd   
f0100a4f:	f7 f9                	idiv   %ecx
f0100a51:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a53:	eb 01                	jmp    f0100a56 <stab_binsearch+0x36>
			m--;
f0100a55:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a56:	39 d9                	cmp    %ebx,%ecx
f0100a58:	7c 1d                	jl     f0100a77 <stab_binsearch+0x57>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100a5a:	6b d1 0c             	imul   $0xc,%ecx,%edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a5d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a62:	39 fa                	cmp    %edi,%edx
f0100a64:	75 ef                	jne    f0100a55 <stab_binsearch+0x35>
f0100a66:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a69:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a6c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a70:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a73:	73 18                	jae    f0100a8d <stab_binsearch+0x6d>
f0100a75:	eb 05                	jmp    f0100a7c <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a77:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a7a:	eb 3f                	jmp    f0100abb <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a7c:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a7f:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f0100a81:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a84:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a8b:	eb 2e                	jmp    f0100abb <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a8d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a90:	73 15                	jae    f0100aa7 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a92:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a95:	49                   	dec    %ecx
f0100a96:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100a99:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a9c:	89 08                	mov    %ecx,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a9e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100aa5:	eb 14                	jmp    f0100abb <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100aa7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100aaa:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100aad:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0100aaf:	ff 45 0c             	incl   0xc(%ebp)
f0100ab2:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100ab4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100abb:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100abe:	7e 84                	jle    f0100a44 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100ac0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100ac4:	75 0d                	jne    f0100ad3 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100ac6:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100ac9:	8b 02                	mov    (%edx),%eax
f0100acb:	48                   	dec    %eax
f0100acc:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100acf:	89 01                	mov    %eax,(%ecx)
f0100ad1:	eb 22                	jmp    f0100af5 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ad3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100ad6:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100ad8:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100adb:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100add:	eb 01                	jmp    f0100ae0 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100adf:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ae0:	39 c1                	cmp    %eax,%ecx
f0100ae2:	7d 0c                	jge    f0100af0 <stab_binsearch+0xd0>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100ae4:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100ae7:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100aec:	39 fa                	cmp    %edi,%edx
f0100aee:	75 ef                	jne    f0100adf <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100af0:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100af3:	89 02                	mov    %eax,(%edx)
	}
}
f0100af5:	83 c4 10             	add    $0x10,%esp
f0100af8:	5b                   	pop    %ebx
f0100af9:	5e                   	pop    %esi
f0100afa:	5f                   	pop    %edi
f0100afb:	5d                   	pop    %ebp
f0100afc:	c3                   	ret    

f0100afd <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100afd:	55                   	push   %ebp
f0100afe:	89 e5                	mov    %esp,%ebp
f0100b00:	83 ec 58             	sub    $0x58,%esp
f0100b03:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100b06:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100b09:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100b0c:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b0f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b12:	c7 03 a4 20 10 f0    	movl   $0xf01020a4,(%ebx)
	info->eip_line = 0;
f0100b18:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b1f:	c7 43 08 a4 20 10 f0 	movl   $0xf01020a4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b26:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b2d:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b30:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b37:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b3d:	76 12                	jbe    f0100b51 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b3f:	b8 6c 79 10 f0       	mov    $0xf010796c,%eax
f0100b44:	3d 6d 5f 10 f0       	cmp    $0xf0105f6d,%eax
f0100b49:	0f 86 f5 01 00 00    	jbe    f0100d44 <debuginfo_eip+0x247>
f0100b4f:	eb 1c                	jmp    f0100b6d <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b51:	c7 44 24 08 ae 20 10 	movl   $0xf01020ae,0x8(%esp)
f0100b58:	f0 
f0100b59:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b60:	00 
f0100b61:	c7 04 24 bb 20 10 f0 	movl   $0xf01020bb,(%esp)
f0100b68:	e8 8b f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b6d:	80 3d 6b 79 10 f0 00 	cmpb   $0x0,0xf010796b
f0100b74:	0f 85 d1 01 00 00    	jne    f0100d4b <debuginfo_eip+0x24e>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b7a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b81:	b8 6c 5f 10 f0       	mov    $0xf0105f6c,%eax
f0100b86:	2d dc 22 10 f0       	sub    $0xf01022dc,%eax
f0100b8b:	c1 f8 02             	sar    $0x2,%eax
f0100b8e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b94:	83 e8 01             	sub    $0x1,%eax
f0100b97:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b9a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b9e:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100ba5:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100ba8:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100bab:	b8 dc 22 10 f0       	mov    $0xf01022dc,%eax
f0100bb0:	e8 6b fe ff ff       	call   f0100a20 <stab_binsearch>
	if (lfile == 0)
f0100bb5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bb8:	85 c0                	test   %eax,%eax
f0100bba:	0f 84 92 01 00 00    	je     f0100d52 <debuginfo_eip+0x255>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100bc0:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100bc3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bc6:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100bc9:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bcd:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100bd4:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100bd7:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bda:	b8 dc 22 10 f0       	mov    $0xf01022dc,%eax
f0100bdf:	e8 3c fe ff ff       	call   f0100a20 <stab_binsearch>

	if (lfun <= rfun) {
f0100be4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100be7:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100bea:	39 d0                	cmp    %edx,%eax
f0100bec:	7f 3d                	jg     f0100c2b <debuginfo_eip+0x12e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bee:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100bf1:	8d b9 dc 22 10 f0    	lea    -0xfefdd24(%ecx),%edi
f0100bf7:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0100bfa:	8b 89 dc 22 10 f0    	mov    -0xfefdd24(%ecx),%ecx
f0100c00:	bf 6c 79 10 f0       	mov    $0xf010796c,%edi
f0100c05:	81 ef 6d 5f 10 f0    	sub    $0xf0105f6d,%edi
f0100c0b:	39 f9                	cmp    %edi,%ecx
f0100c0d:	73 09                	jae    f0100c18 <debuginfo_eip+0x11b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c0f:	81 c1 6d 5f 10 f0    	add    $0xf0105f6d,%ecx
f0100c15:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c18:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100c1b:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100c1e:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100c21:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100c23:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c26:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100c29:	eb 0f                	jmp    f0100c3a <debuginfo_eip+0x13d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c2b:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c2e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c31:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c34:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c37:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c3a:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c41:	00 
f0100c42:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c45:	89 04 24             	mov    %eax,(%esp)
f0100c48:	e8 a0 09 00 00       	call   f01015ed <strfind>
f0100c4d:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c50:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100c53:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c57:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c5e:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c61:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c64:	b8 dc 22 10 f0       	mov    $0xf01022dc,%eax
f0100c69:	e8 b2 fd ff ff       	call   f0100a20 <stab_binsearch>
	
	if( lline <= rline ) {
f0100c6e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c71:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100c74:	0f 8f df 00 00 00    	jg     f0100d59 <debuginfo_eip+0x25c>
		info->eip_line = stabs[lline].n_desc;
f0100c7a:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c7d:	0f b7 80 e2 22 10 f0 	movzwl -0xfefdd1e(%eax),%eax
f0100c84:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c87:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c8a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100c8d:	39 f0                	cmp    %esi,%eax
f0100c8f:	7c 63                	jl     f0100cf4 <debuginfo_eip+0x1f7>
	       && stabs[lline].n_type != N_SOL
f0100c91:	6b f8 0c             	imul   $0xc,%eax,%edi
f0100c94:	81 c7 dc 22 10 f0    	add    $0xf01022dc,%edi
f0100c9a:	0f b6 4f 04          	movzbl 0x4(%edi),%ecx
f0100c9e:	80 f9 84             	cmp    $0x84,%cl
f0100ca1:	74 32                	je     f0100cd5 <debuginfo_eip+0x1d8>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100ca3:	8d 50 ff             	lea    -0x1(%eax),%edx
f0100ca6:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100ca9:	81 c2 dc 22 10 f0    	add    $0xf01022dc,%edx
f0100caf:	eb 15                	jmp    f0100cc6 <debuginfo_eip+0x1c9>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100cb1:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100cb4:	39 f0                	cmp    %esi,%eax
f0100cb6:	7c 3c                	jl     f0100cf4 <debuginfo_eip+0x1f7>
	       && stabs[lline].n_type != N_SOL
f0100cb8:	89 d7                	mov    %edx,%edi
f0100cba:	83 ea 0c             	sub    $0xc,%edx
f0100cbd:	0f b6 4a 10          	movzbl 0x10(%edx),%ecx
f0100cc1:	80 f9 84             	cmp    $0x84,%cl
f0100cc4:	74 0f                	je     f0100cd5 <debuginfo_eip+0x1d8>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cc6:	80 f9 64             	cmp    $0x64,%cl
f0100cc9:	75 e6                	jne    f0100cb1 <debuginfo_eip+0x1b4>
f0100ccb:	83 7f 08 00          	cmpl   $0x0,0x8(%edi)
f0100ccf:	74 e0                	je     f0100cb1 <debuginfo_eip+0x1b4>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cd1:	39 c6                	cmp    %eax,%esi
f0100cd3:	7f 1f                	jg     f0100cf4 <debuginfo_eip+0x1f7>
f0100cd5:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100cd8:	8b 80 dc 22 10 f0    	mov    -0xfefdd24(%eax),%eax
f0100cde:	ba 6c 79 10 f0       	mov    $0xf010796c,%edx
f0100ce3:	81 ea 6d 5f 10 f0    	sub    $0xf0105f6d,%edx
f0100ce9:	39 d0                	cmp    %edx,%eax
f0100ceb:	73 07                	jae    f0100cf4 <debuginfo_eip+0x1f7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100ced:	05 6d 5f 10 f0       	add    $0xf0105f6d,%eax
f0100cf2:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cf4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100cf7:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100cfa:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cff:	39 ca                	cmp    %ecx,%edx
f0100d01:	7d 70                	jge    f0100d73 <debuginfo_eip+0x276>
		for (lline = lfun + 1;
f0100d03:	8d 42 01             	lea    0x1(%edx),%eax
f0100d06:	39 c1                	cmp    %eax,%ecx
f0100d08:	7e 56                	jle    f0100d60 <debuginfo_eip+0x263>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d0a:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100d0d:	80 b8 e0 22 10 f0 a0 	cmpb   $0xa0,-0xfefdd20(%eax)
f0100d14:	75 51                	jne    f0100d67 <debuginfo_eip+0x26a>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100d16:	8d 42 02             	lea    0x2(%edx),%eax
f0100d19:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100d1c:	81 c2 dc 22 10 f0    	add    $0xf01022dc,%edx
f0100d22:	89 cf                	mov    %ecx,%edi
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100d24:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d28:	39 f8                	cmp    %edi,%eax
f0100d2a:	74 42                	je     f0100d6e <debuginfo_eip+0x271>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d2c:	0f b6 72 1c          	movzbl 0x1c(%edx),%esi
f0100d30:	83 c0 01             	add    $0x1,%eax
f0100d33:	83 c2 0c             	add    $0xc,%edx
f0100d36:	89 f1                	mov    %esi,%ecx
f0100d38:	80 f9 a0             	cmp    $0xa0,%cl
f0100d3b:	74 e7                	je     f0100d24 <debuginfo_eip+0x227>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100d3d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d42:	eb 2f                	jmp    f0100d73 <debuginfo_eip+0x276>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d44:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d49:	eb 28                	jmp    f0100d73 <debuginfo_eip+0x276>
f0100d4b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d50:	eb 21                	jmp    f0100d73 <debuginfo_eip+0x276>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100d52:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d57:	eb 1a                	jmp    f0100d73 <debuginfo_eip+0x276>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	
	if( lline <= rline ) {
		info->eip_line = stabs[lline].n_desc;
	} else {
		return -1;
f0100d59:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d5e:	eb 13                	jmp    f0100d73 <debuginfo_eip+0x276>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100d60:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d65:	eb 0c                	jmp    f0100d73 <debuginfo_eip+0x276>
f0100d67:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d6c:	eb 05                	jmp    f0100d73 <debuginfo_eip+0x276>
f0100d6e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d73:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100d76:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100d79:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100d7c:	89 ec                	mov    %ebp,%esp
f0100d7e:	5d                   	pop    %ebp
f0100d7f:	c3                   	ret    

f0100d80 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d80:	55                   	push   %ebp
f0100d81:	89 e5                	mov    %esp,%ebp
f0100d83:	57                   	push   %edi
f0100d84:	56                   	push   %esi
f0100d85:	53                   	push   %ebx
f0100d86:	83 ec 4c             	sub    $0x4c,%esp
f0100d89:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100d8c:	89 d7                	mov    %edx,%edi
f0100d8e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100d91:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0100d94:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d97:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d9a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d9f:	39 d8                	cmp    %ebx,%eax
f0100da1:	72 17                	jb     f0100dba <printnum+0x3a>
f0100da3:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100da6:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0100da9:	76 0f                	jbe    f0100dba <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100dab:	8b 75 14             	mov    0x14(%ebp),%esi
f0100dae:	83 ee 01             	sub    $0x1,%esi
f0100db1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100db4:	85 f6                	test   %esi,%esi
f0100db6:	7f 63                	jg     f0100e1b <printnum+0x9b>
f0100db8:	eb 75                	jmp    f0100e2f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100dba:	8b 5d 18             	mov    0x18(%ebp),%ebx
f0100dbd:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0100dc1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100dc4:	83 e8 01             	sub    $0x1,%eax
f0100dc7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100dcb:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100dce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100dd2:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100dd6:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100dda:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ddd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100de0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100de7:	00 
f0100de8:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100deb:	89 1c 24             	mov    %ebx,(%esp)
f0100dee:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100df1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100df5:	e8 76 0a 00 00       	call   f0101870 <__udivdi3>
f0100dfa:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100dfd:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100e00:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100e04:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100e08:	89 04 24             	mov    %eax,(%esp)
f0100e0b:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e0f:	89 fa                	mov    %edi,%edx
f0100e11:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e14:	e8 67 ff ff ff       	call   f0100d80 <printnum>
f0100e19:	eb 14                	jmp    f0100e2f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e1b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e1f:	8b 45 18             	mov    0x18(%ebp),%eax
f0100e22:	89 04 24             	mov    %eax,(%esp)
f0100e25:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e27:	83 ee 01             	sub    $0x1,%esi
f0100e2a:	75 ef                	jne    f0100e1b <printnum+0x9b>
f0100e2c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e2f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e33:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100e37:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100e3a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100e3e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100e45:	00 
f0100e46:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100e49:	89 1c 24             	mov    %ebx,(%esp)
f0100e4c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100e4f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e53:	e8 78 0b 00 00       	call   f01019d0 <__umoddi3>
f0100e58:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e5c:	0f be 80 c9 20 10 f0 	movsbl -0xfefdf37(%eax),%eax
f0100e63:	89 04 24             	mov    %eax,(%esp)
f0100e66:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e69:	ff d0                	call   *%eax
}
f0100e6b:	83 c4 4c             	add    $0x4c,%esp
f0100e6e:	5b                   	pop    %ebx
f0100e6f:	5e                   	pop    %esi
f0100e70:	5f                   	pop    %edi
f0100e71:	5d                   	pop    %ebp
f0100e72:	c3                   	ret    

f0100e73 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e73:	55                   	push   %ebp
f0100e74:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e76:	83 fa 01             	cmp    $0x1,%edx
f0100e79:	7e 0e                	jle    f0100e89 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e7b:	8b 10                	mov    (%eax),%edx
f0100e7d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e80:	89 08                	mov    %ecx,(%eax)
f0100e82:	8b 02                	mov    (%edx),%eax
f0100e84:	8b 52 04             	mov    0x4(%edx),%edx
f0100e87:	eb 22                	jmp    f0100eab <getuint+0x38>
	else if (lflag)
f0100e89:	85 d2                	test   %edx,%edx
f0100e8b:	74 10                	je     f0100e9d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e8d:	8b 10                	mov    (%eax),%edx
f0100e8f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e92:	89 08                	mov    %ecx,(%eax)
f0100e94:	8b 02                	mov    (%edx),%eax
f0100e96:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e9b:	eb 0e                	jmp    f0100eab <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e9d:	8b 10                	mov    (%eax),%edx
f0100e9f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100ea2:	89 08                	mov    %ecx,(%eax)
f0100ea4:	8b 02                	mov    (%edx),%eax
f0100ea6:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100eab:	5d                   	pop    %ebp
f0100eac:	c3                   	ret    

f0100ead <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100ead:	55                   	push   %ebp
f0100eae:	89 e5                	mov    %esp,%ebp
f0100eb0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100eb3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100eb7:	8b 10                	mov    (%eax),%edx
f0100eb9:	3b 50 04             	cmp    0x4(%eax),%edx
f0100ebc:	73 0a                	jae    f0100ec8 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100ebe:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100ec1:	88 0a                	mov    %cl,(%edx)
f0100ec3:	83 c2 01             	add    $0x1,%edx
f0100ec6:	89 10                	mov    %edx,(%eax)
}
f0100ec8:	5d                   	pop    %ebp
f0100ec9:	c3                   	ret    

f0100eca <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100eca:	55                   	push   %ebp
f0100ecb:	89 e5                	mov    %esp,%ebp
f0100ecd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100ed0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100ed3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ed7:	8b 45 10             	mov    0x10(%ebp),%eax
f0100eda:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ede:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ee1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ee5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ee8:	89 04 24             	mov    %eax,(%esp)
f0100eeb:	e8 02 00 00 00       	call   f0100ef2 <vprintfmt>
	va_end(ap);
}
f0100ef0:	c9                   	leave  
f0100ef1:	c3                   	ret    

f0100ef2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100ef2:	55                   	push   %ebp
f0100ef3:	89 e5                	mov    %esp,%ebp
f0100ef5:	57                   	push   %edi
f0100ef6:	56                   	push   %esi
f0100ef7:	53                   	push   %ebx
f0100ef8:	83 ec 4c             	sub    $0x4c,%esp
f0100efb:	8b 75 08             	mov    0x8(%ebp),%esi
f0100efe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f01:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100f04:	eb 11                	jmp    f0100f17 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100f06:	85 c0                	test   %eax,%eax
f0100f08:	0f 84 d8 03 00 00    	je     f01012e6 <vprintfmt+0x3f4>
				return;
			putch(ch, putdat);
f0100f0e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f12:	89 04 24             	mov    %eax,(%esp)
f0100f15:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100f17:	0f b6 07             	movzbl (%edi),%eax
f0100f1a:	83 c7 01             	add    $0x1,%edi
f0100f1d:	83 f8 25             	cmp    $0x25,%eax
f0100f20:	75 e4                	jne    f0100f06 <vprintfmt+0x14>
f0100f22:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f0100f26:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0100f2d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100f34:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0100f3b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f40:	eb 2b                	jmp    f0100f6d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f42:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100f45:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f0100f49:	eb 22                	jmp    f0100f6d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f4b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f4e:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f0100f52:	eb 19                	jmp    f0100f6d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f54:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100f57:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100f5e:	eb 0d                	jmp    f0100f6d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100f60:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100f63:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f66:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f6d:	0f b6 0f             	movzbl (%edi),%ecx
f0100f70:	8d 47 01             	lea    0x1(%edi),%eax
f0100f73:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f76:	0f b6 07             	movzbl (%edi),%eax
f0100f79:	83 e8 23             	sub    $0x23,%eax
f0100f7c:	3c 55                	cmp    $0x55,%al
f0100f7e:	0f 87 3d 03 00 00    	ja     f01012c1 <vprintfmt+0x3cf>
f0100f84:	0f b6 c0             	movzbl %al,%eax
f0100f87:	ff 24 85 58 21 10 f0 	jmp    *-0xfefdea8(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f8e:	83 e9 30             	sub    $0x30,%ecx
f0100f91:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
f0100f94:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
f0100f98:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100f9b:	83 f9 09             	cmp    $0x9,%ecx
f0100f9e:	77 57                	ja     f0100ff7 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fa0:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100fa3:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100fa6:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100fa9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0100fac:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100faf:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100fb3:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0100fb6:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100fb9:	83 f9 09             	cmp    $0x9,%ecx
f0100fbc:	76 eb                	jbe    f0100fa9 <vprintfmt+0xb7>
f0100fbe:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100fc1:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100fc4:	eb 34                	jmp    f0100ffa <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100fc6:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fc9:	8d 48 04             	lea    0x4(%eax),%ecx
f0100fcc:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100fcf:	8b 00                	mov    (%eax),%eax
f0100fd1:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fd4:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100fd7:	eb 21                	jmp    f0100ffa <vprintfmt+0x108>

		case '.':
			if (width < 0)
f0100fd9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100fdd:	0f 88 71 ff ff ff    	js     f0100f54 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fe3:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100fe6:	eb 85                	jmp    f0100f6d <vprintfmt+0x7b>
f0100fe8:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100feb:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0100ff2:	e9 76 ff ff ff       	jmp    f0100f6d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ff7:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100ffa:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100ffe:	0f 89 69 ff ff ff    	jns    f0100f6d <vprintfmt+0x7b>
f0101004:	e9 57 ff ff ff       	jmp    f0100f60 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101009:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010100c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010100f:	e9 59 ff ff ff       	jmp    f0100f6d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101014:	8b 45 14             	mov    0x14(%ebp),%eax
f0101017:	8d 50 04             	lea    0x4(%eax),%edx
f010101a:	89 55 14             	mov    %edx,0x14(%ebp)
f010101d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101021:	8b 00                	mov    (%eax),%eax
f0101023:	89 04 24             	mov    %eax,(%esp)
f0101026:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101028:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010102b:	e9 e7 fe ff ff       	jmp    f0100f17 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101030:	8b 45 14             	mov    0x14(%ebp),%eax
f0101033:	8d 50 04             	lea    0x4(%eax),%edx
f0101036:	89 55 14             	mov    %edx,0x14(%ebp)
f0101039:	8b 00                	mov    (%eax),%eax
f010103b:	89 c2                	mov    %eax,%edx
f010103d:	c1 fa 1f             	sar    $0x1f,%edx
f0101040:	31 d0                	xor    %edx,%eax
f0101042:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101044:	83 f8 06             	cmp    $0x6,%eax
f0101047:	7f 0b                	jg     f0101054 <vprintfmt+0x162>
f0101049:	8b 14 85 b0 22 10 f0 	mov    -0xfefdd50(,%eax,4),%edx
f0101050:	85 d2                	test   %edx,%edx
f0101052:	75 20                	jne    f0101074 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
f0101054:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101058:	c7 44 24 08 e1 20 10 	movl   $0xf01020e1,0x8(%esp)
f010105f:	f0 
f0101060:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101064:	89 34 24             	mov    %esi,(%esp)
f0101067:	e8 5e fe ff ff       	call   f0100eca <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010106c:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010106f:	e9 a3 fe ff ff       	jmp    f0100f17 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0101074:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101078:	c7 44 24 08 ea 20 10 	movl   $0xf01020ea,0x8(%esp)
f010107f:	f0 
f0101080:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101084:	89 34 24             	mov    %esi,(%esp)
f0101087:	e8 3e fe ff ff       	call   f0100eca <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010108c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010108f:	e9 83 fe ff ff       	jmp    f0100f17 <vprintfmt+0x25>
f0101094:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101097:	8b 7d d8             	mov    -0x28(%ebp),%edi
f010109a:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010109d:	8b 45 14             	mov    0x14(%ebp),%eax
f01010a0:	8d 50 04             	lea    0x4(%eax),%edx
f01010a3:	89 55 14             	mov    %edx,0x14(%ebp)
f01010a6:	8b 38                	mov    (%eax),%edi
f01010a8:	85 ff                	test   %edi,%edi
f01010aa:	75 05                	jne    f01010b1 <vprintfmt+0x1bf>
				p = "(null)";
f01010ac:	bf da 20 10 f0       	mov    $0xf01020da,%edi
			if (width > 0 && padc != '-')
f01010b1:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f01010b5:	74 06                	je     f01010bd <vprintfmt+0x1cb>
f01010b7:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f01010bb:	7f 16                	jg     f01010d3 <vprintfmt+0x1e1>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010bd:	0f b6 17             	movzbl (%edi),%edx
f01010c0:	0f be c2             	movsbl %dl,%eax
f01010c3:	83 c7 01             	add    $0x1,%edi
f01010c6:	85 c0                	test   %eax,%eax
f01010c8:	0f 85 9f 00 00 00    	jne    f010116d <vprintfmt+0x27b>
f01010ce:	e9 8b 00 00 00       	jmp    f010115e <vprintfmt+0x26c>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010d3:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01010d7:	89 3c 24             	mov    %edi,(%esp)
f01010da:	e8 83 03 00 00       	call   f0101462 <strnlen>
f01010df:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01010e2:	29 c2                	sub    %eax,%edx
f01010e4:	89 55 d8             	mov    %edx,-0x28(%ebp)
f01010e7:	85 d2                	test   %edx,%edx
f01010e9:	7e d2                	jle    f01010bd <vprintfmt+0x1cb>
					putch(padc, putdat);
f01010eb:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f01010ef:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01010f2:	89 7d cc             	mov    %edi,-0x34(%ebp)
f01010f5:	89 d7                	mov    %edx,%edi
f01010f7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010fe:	89 04 24             	mov    %eax,(%esp)
f0101101:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101103:	83 ef 01             	sub    $0x1,%edi
f0101106:	75 ef                	jne    f01010f7 <vprintfmt+0x205>
f0101108:	89 7d d8             	mov    %edi,-0x28(%ebp)
f010110b:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010110e:	eb ad                	jmp    f01010bd <vprintfmt+0x1cb>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101110:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101114:	74 20                	je     f0101136 <vprintfmt+0x244>
f0101116:	0f be d2             	movsbl %dl,%edx
f0101119:	83 ea 20             	sub    $0x20,%edx
f010111c:	83 fa 5e             	cmp    $0x5e,%edx
f010111f:	76 15                	jbe    f0101136 <vprintfmt+0x244>
					putch('?', putdat);
f0101121:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101124:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101128:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010112f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101132:	ff d1                	call   *%ecx
f0101134:	eb 0f                	jmp    f0101145 <vprintfmt+0x253>
				else
					putch(ch, putdat);
f0101136:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101139:	89 54 24 04          	mov    %edx,0x4(%esp)
f010113d:	89 04 24             	mov    %eax,(%esp)
f0101140:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101143:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101145:	83 eb 01             	sub    $0x1,%ebx
f0101148:	0f b6 17             	movzbl (%edi),%edx
f010114b:	0f be c2             	movsbl %dl,%eax
f010114e:	83 c7 01             	add    $0x1,%edi
f0101151:	85 c0                	test   %eax,%eax
f0101153:	75 24                	jne    f0101179 <vprintfmt+0x287>
f0101155:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0101158:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010115b:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010115e:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101161:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101165:	0f 8e ac fd ff ff    	jle    f0100f17 <vprintfmt+0x25>
f010116b:	eb 20                	jmp    f010118d <vprintfmt+0x29b>
f010116d:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101170:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0101173:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0101176:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101179:	85 f6                	test   %esi,%esi
f010117b:	78 93                	js     f0101110 <vprintfmt+0x21e>
f010117d:	83 ee 01             	sub    $0x1,%esi
f0101180:	79 8e                	jns    f0101110 <vprintfmt+0x21e>
f0101182:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0101185:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101188:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010118b:	eb d1                	jmp    f010115e <vprintfmt+0x26c>
f010118d:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101190:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101194:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010119b:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010119d:	83 ef 01             	sub    $0x1,%edi
f01011a0:	75 ee                	jne    f0101190 <vprintfmt+0x29e>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011a2:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01011a5:	e9 6d fd ff ff       	jmp    f0100f17 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01011aa:	83 fa 01             	cmp    $0x1,%edx
f01011ad:	7e 16                	jle    f01011c5 <vprintfmt+0x2d3>
		return va_arg(*ap, long long);
f01011af:	8b 45 14             	mov    0x14(%ebp),%eax
f01011b2:	8d 50 08             	lea    0x8(%eax),%edx
f01011b5:	89 55 14             	mov    %edx,0x14(%ebp)
f01011b8:	8b 10                	mov    (%eax),%edx
f01011ba:	8b 48 04             	mov    0x4(%eax),%ecx
f01011bd:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01011c0:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01011c3:	eb 32                	jmp    f01011f7 <vprintfmt+0x305>
	else if (lflag)
f01011c5:	85 d2                	test   %edx,%edx
f01011c7:	74 18                	je     f01011e1 <vprintfmt+0x2ef>
		return va_arg(*ap, long);
f01011c9:	8b 45 14             	mov    0x14(%ebp),%eax
f01011cc:	8d 50 04             	lea    0x4(%eax),%edx
f01011cf:	89 55 14             	mov    %edx,0x14(%ebp)
f01011d2:	8b 00                	mov    (%eax),%eax
f01011d4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01011d7:	89 c1                	mov    %eax,%ecx
f01011d9:	c1 f9 1f             	sar    $0x1f,%ecx
f01011dc:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01011df:	eb 16                	jmp    f01011f7 <vprintfmt+0x305>
	else
		return va_arg(*ap, int);
f01011e1:	8b 45 14             	mov    0x14(%ebp),%eax
f01011e4:	8d 50 04             	lea    0x4(%eax),%edx
f01011e7:	89 55 14             	mov    %edx,0x14(%ebp)
f01011ea:	8b 00                	mov    (%eax),%eax
f01011ec:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01011ef:	89 c7                	mov    %eax,%edi
f01011f1:	c1 ff 1f             	sar    $0x1f,%edi
f01011f4:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01011f7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01011fa:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01011fd:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101202:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101206:	79 7d                	jns    f0101285 <vprintfmt+0x393>
				putch('-', putdat);
f0101208:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010120c:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101213:	ff d6                	call   *%esi
				num = -(long long) num;
f0101215:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101218:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010121b:	f7 d8                	neg    %eax
f010121d:	83 d2 00             	adc    $0x0,%edx
f0101220:	f7 da                	neg    %edx
			}
			base = 10;
f0101222:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101227:	eb 5c                	jmp    f0101285 <vprintfmt+0x393>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101229:	8d 45 14             	lea    0x14(%ebp),%eax
f010122c:	e8 42 fc ff ff       	call   f0100e73 <getuint>
			base = 10;
f0101231:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101236:	eb 4d                	jmp    f0101285 <vprintfmt+0x393>
			// Replace this with your code.
			/*putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);*/
			/*putch('0', putdat);*/
			num = getuint(&ap, lflag);
f0101238:	8d 45 14             	lea    0x14(%ebp),%eax
f010123b:	e8 33 fc ff ff       	call   f0100e73 <getuint>
			base = 8;
f0101240:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101245:	eb 3e                	jmp    f0101285 <vprintfmt+0x393>
			/*break;*/

		// pointer
		case 'p':
			putch('0', putdat);
f0101247:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010124b:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101252:	ff d6                	call   *%esi
			putch('x', putdat);
f0101254:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101258:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010125f:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101261:	8b 45 14             	mov    0x14(%ebp),%eax
f0101264:	8d 50 04             	lea    0x4(%eax),%edx
f0101267:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010126a:	8b 00                	mov    (%eax),%eax
f010126c:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101271:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101276:	eb 0d                	jmp    f0101285 <vprintfmt+0x393>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101278:	8d 45 14             	lea    0x14(%ebp),%eax
f010127b:	e8 f3 fb ff ff       	call   f0100e73 <getuint>
			base = 16;
f0101280:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101285:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f0101289:	89 7c 24 10          	mov    %edi,0x10(%esp)
f010128d:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0101290:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101294:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101298:	89 04 24             	mov    %eax,(%esp)
f010129b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010129f:	89 da                	mov    %ebx,%edx
f01012a1:	89 f0                	mov    %esi,%eax
f01012a3:	e8 d8 fa ff ff       	call   f0100d80 <printnum>
			break;
f01012a8:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01012ab:	e9 67 fc ff ff       	jmp    f0100f17 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01012b0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012b4:	89 0c 24             	mov    %ecx,(%esp)
f01012b7:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012b9:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01012bc:	e9 56 fc ff ff       	jmp    f0100f17 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01012c1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012c5:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01012cc:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01012ce:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01012d2:	0f 84 3f fc ff ff    	je     f0100f17 <vprintfmt+0x25>
f01012d8:	83 ef 01             	sub    $0x1,%edi
f01012db:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01012df:	75 f7                	jne    f01012d8 <vprintfmt+0x3e6>
f01012e1:	e9 31 fc ff ff       	jmp    f0100f17 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01012e6:	83 c4 4c             	add    $0x4c,%esp
f01012e9:	5b                   	pop    %ebx
f01012ea:	5e                   	pop    %esi
f01012eb:	5f                   	pop    %edi
f01012ec:	5d                   	pop    %ebp
f01012ed:	c3                   	ret    

f01012ee <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01012ee:	55                   	push   %ebp
f01012ef:	89 e5                	mov    %esp,%ebp
f01012f1:	83 ec 28             	sub    $0x28,%esp
f01012f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01012f7:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01012fa:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01012fd:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101301:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101304:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010130b:	85 d2                	test   %edx,%edx
f010130d:	7e 30                	jle    f010133f <vsnprintf+0x51>
f010130f:	85 c0                	test   %eax,%eax
f0101311:	74 2c                	je     f010133f <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101313:	8b 45 14             	mov    0x14(%ebp),%eax
f0101316:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010131a:	8b 45 10             	mov    0x10(%ebp),%eax
f010131d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101321:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101324:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101328:	c7 04 24 ad 0e 10 f0 	movl   $0xf0100ead,(%esp)
f010132f:	e8 be fb ff ff       	call   f0100ef2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101334:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101337:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010133a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010133d:	eb 05                	jmp    f0101344 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010133f:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101344:	c9                   	leave  
f0101345:	c3                   	ret    

f0101346 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101346:	55                   	push   %ebp
f0101347:	89 e5                	mov    %esp,%ebp
f0101349:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010134c:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010134f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101353:	8b 45 10             	mov    0x10(%ebp),%eax
f0101356:	89 44 24 08          	mov    %eax,0x8(%esp)
f010135a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010135d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101361:	8b 45 08             	mov    0x8(%ebp),%eax
f0101364:	89 04 24             	mov    %eax,(%esp)
f0101367:	e8 82 ff ff ff       	call   f01012ee <vsnprintf>
	va_end(ap);

	return rc;
}
f010136c:	c9                   	leave  
f010136d:	c3                   	ret    
	...

f0101370 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101370:	55                   	push   %ebp
f0101371:	89 e5                	mov    %esp,%ebp
f0101373:	57                   	push   %edi
f0101374:	56                   	push   %esi
f0101375:	53                   	push   %ebx
f0101376:	83 ec 1c             	sub    $0x1c,%esp
f0101379:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010137c:	85 c0                	test   %eax,%eax
f010137e:	74 10                	je     f0101390 <readline+0x20>
		cprintf("%s", prompt);
f0101380:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101384:	c7 04 24 ea 20 10 f0 	movl   $0xf01020ea,(%esp)
f010138b:	e8 6a f6 ff ff       	call   f01009fa <cprintf>

	i = 0;
	echoing = iscons(0);
f0101390:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101397:	e8 e3 f2 ff ff       	call   f010067f <iscons>
f010139c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010139e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01013a3:	e8 c6 f2 ff ff       	call   f010066e <getchar>
f01013a8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01013aa:	85 c0                	test   %eax,%eax
f01013ac:	79 17                	jns    f01013c5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01013ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013b2:	c7 04 24 cc 22 10 f0 	movl   $0xf01022cc,(%esp)
f01013b9:	e8 3c f6 ff ff       	call   f01009fa <cprintf>
			return NULL;
f01013be:	b8 00 00 00 00       	mov    $0x0,%eax
f01013c3:	eb 6d                	jmp    f0101432 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01013c5:	83 f8 7f             	cmp    $0x7f,%eax
f01013c8:	74 05                	je     f01013cf <readline+0x5f>
f01013ca:	83 f8 08             	cmp    $0x8,%eax
f01013cd:	75 19                	jne    f01013e8 <readline+0x78>
f01013cf:	85 f6                	test   %esi,%esi
f01013d1:	7e 15                	jle    f01013e8 <readline+0x78>
			if (echoing)
f01013d3:	85 ff                	test   %edi,%edi
f01013d5:	74 0c                	je     f01013e3 <readline+0x73>
				cputchar('\b');
f01013d7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01013de:	e8 7b f2 ff ff       	call   f010065e <cputchar>
			i--;
f01013e3:	83 ee 01             	sub    $0x1,%esi
f01013e6:	eb bb                	jmp    f01013a3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01013e8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01013ee:	7f 1c                	jg     f010140c <readline+0x9c>
f01013f0:	83 fb 1f             	cmp    $0x1f,%ebx
f01013f3:	7e 17                	jle    f010140c <readline+0x9c>
			if (echoing)
f01013f5:	85 ff                	test   %edi,%edi
f01013f7:	74 08                	je     f0101401 <readline+0x91>
				cputchar(c);
f01013f9:	89 1c 24             	mov    %ebx,(%esp)
f01013fc:	e8 5d f2 ff ff       	call   f010065e <cputchar>
			buf[i++] = c;
f0101401:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101407:	83 c6 01             	add    $0x1,%esi
f010140a:	eb 97                	jmp    f01013a3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010140c:	83 fb 0d             	cmp    $0xd,%ebx
f010140f:	74 05                	je     f0101416 <readline+0xa6>
f0101411:	83 fb 0a             	cmp    $0xa,%ebx
f0101414:	75 8d                	jne    f01013a3 <readline+0x33>
			if (echoing)
f0101416:	85 ff                	test   %edi,%edi
f0101418:	74 0c                	je     f0101426 <readline+0xb6>
				cputchar('\n');
f010141a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101421:	e8 38 f2 ff ff       	call   f010065e <cputchar>
			buf[i] = 0;
f0101426:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f010142d:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f0101432:	83 c4 1c             	add    $0x1c,%esp
f0101435:	5b                   	pop    %ebx
f0101436:	5e                   	pop    %esi
f0101437:	5f                   	pop    %edi
f0101438:	5d                   	pop    %ebp
f0101439:	c3                   	ret    
f010143a:	00 00                	add    %al,(%eax)
f010143c:	00 00                	add    %al,(%eax)
	...

f0101440 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101440:	55                   	push   %ebp
f0101441:	89 e5                	mov    %esp,%ebp
f0101443:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101446:	80 3a 00             	cmpb   $0x0,(%edx)
f0101449:	74 10                	je     f010145b <strlen+0x1b>
f010144b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0101450:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101453:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101457:	75 f7                	jne    f0101450 <strlen+0x10>
f0101459:	eb 05                	jmp    f0101460 <strlen+0x20>
f010145b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101460:	5d                   	pop    %ebp
f0101461:	c3                   	ret    

f0101462 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101462:	55                   	push   %ebp
f0101463:	89 e5                	mov    %esp,%ebp
f0101465:	53                   	push   %ebx
f0101466:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101469:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010146c:	85 c9                	test   %ecx,%ecx
f010146e:	74 1c                	je     f010148c <strnlen+0x2a>
f0101470:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101473:	74 1e                	je     f0101493 <strnlen+0x31>
f0101475:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f010147a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010147c:	39 ca                	cmp    %ecx,%edx
f010147e:	74 18                	je     f0101498 <strnlen+0x36>
f0101480:	83 c2 01             	add    $0x1,%edx
f0101483:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101488:	75 f0                	jne    f010147a <strnlen+0x18>
f010148a:	eb 0c                	jmp    f0101498 <strnlen+0x36>
f010148c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101491:	eb 05                	jmp    f0101498 <strnlen+0x36>
f0101493:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101498:	5b                   	pop    %ebx
f0101499:	5d                   	pop    %ebp
f010149a:	c3                   	ret    

f010149b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010149b:	55                   	push   %ebp
f010149c:	89 e5                	mov    %esp,%ebp
f010149e:	53                   	push   %ebx
f010149f:	8b 45 08             	mov    0x8(%ebp),%eax
f01014a2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01014a5:	89 c2                	mov    %eax,%edx
f01014a7:	0f b6 19             	movzbl (%ecx),%ebx
f01014aa:	88 1a                	mov    %bl,(%edx)
f01014ac:	83 c2 01             	add    $0x1,%edx
f01014af:	83 c1 01             	add    $0x1,%ecx
f01014b2:	84 db                	test   %bl,%bl
f01014b4:	75 f1                	jne    f01014a7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01014b6:	5b                   	pop    %ebx
f01014b7:	5d                   	pop    %ebp
f01014b8:	c3                   	ret    

f01014b9 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01014b9:	55                   	push   %ebp
f01014ba:	89 e5                	mov    %esp,%ebp
f01014bc:	56                   	push   %esi
f01014bd:	53                   	push   %ebx
f01014be:	8b 75 08             	mov    0x8(%ebp),%esi
f01014c1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014c4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014c7:	85 db                	test   %ebx,%ebx
f01014c9:	74 16                	je     f01014e1 <strncpy+0x28>
		/* do nothing */;
	return ret;
}

char *
strncpy(char *dst, const char *src, size_t size) {
f01014cb:	01 f3                	add    %esi,%ebx
f01014cd:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
f01014cf:	0f b6 02             	movzbl (%edx),%eax
f01014d2:	88 01                	mov    %al,(%ecx)
f01014d4:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01014d7:	80 3a 01             	cmpb   $0x1,(%edx)
f01014da:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014dd:	39 d9                	cmp    %ebx,%ecx
f01014df:	75 ee                	jne    f01014cf <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01014e1:	89 f0                	mov    %esi,%eax
f01014e3:	5b                   	pop    %ebx
f01014e4:	5e                   	pop    %esi
f01014e5:	5d                   	pop    %ebp
f01014e6:	c3                   	ret    

f01014e7 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01014e7:	55                   	push   %ebp
f01014e8:	89 e5                	mov    %esp,%ebp
f01014ea:	57                   	push   %edi
f01014eb:	56                   	push   %esi
f01014ec:	53                   	push   %ebx
f01014ed:	8b 7d 08             	mov    0x8(%ebp),%edi
f01014f0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01014f3:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01014f6:	89 f8                	mov    %edi,%eax
f01014f8:	85 f6                	test   %esi,%esi
f01014fa:	74 33                	je     f010152f <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
f01014fc:	83 fe 01             	cmp    $0x1,%esi
f01014ff:	74 25                	je     f0101526 <strlcpy+0x3f>
f0101501:	0f b6 0b             	movzbl (%ebx),%ecx
f0101504:	84 c9                	test   %cl,%cl
f0101506:	74 22                	je     f010152a <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0101508:	83 ee 02             	sub    $0x2,%esi
f010150b:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101510:	88 08                	mov    %cl,(%eax)
f0101512:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101515:	39 f2                	cmp    %esi,%edx
f0101517:	74 13                	je     f010152c <strlcpy+0x45>
f0101519:	83 c2 01             	add    $0x1,%edx
f010151c:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0101520:	84 c9                	test   %cl,%cl
f0101522:	75 ec                	jne    f0101510 <strlcpy+0x29>
f0101524:	eb 06                	jmp    f010152c <strlcpy+0x45>
f0101526:	89 f8                	mov    %edi,%eax
f0101528:	eb 02                	jmp    f010152c <strlcpy+0x45>
f010152a:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f010152c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010152f:	29 f8                	sub    %edi,%eax
}
f0101531:	5b                   	pop    %ebx
f0101532:	5e                   	pop    %esi
f0101533:	5f                   	pop    %edi
f0101534:	5d                   	pop    %ebp
f0101535:	c3                   	ret    

f0101536 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101536:	55                   	push   %ebp
f0101537:	89 e5                	mov    %esp,%ebp
f0101539:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010153c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010153f:	0f b6 01             	movzbl (%ecx),%eax
f0101542:	84 c0                	test   %al,%al
f0101544:	74 15                	je     f010155b <strcmp+0x25>
f0101546:	3a 02                	cmp    (%edx),%al
f0101548:	75 11                	jne    f010155b <strcmp+0x25>
		p++, q++;
f010154a:	83 c1 01             	add    $0x1,%ecx
f010154d:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101550:	0f b6 01             	movzbl (%ecx),%eax
f0101553:	84 c0                	test   %al,%al
f0101555:	74 04                	je     f010155b <strcmp+0x25>
f0101557:	3a 02                	cmp    (%edx),%al
f0101559:	74 ef                	je     f010154a <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010155b:	0f b6 c0             	movzbl %al,%eax
f010155e:	0f b6 12             	movzbl (%edx),%edx
f0101561:	29 d0                	sub    %edx,%eax
}
f0101563:	5d                   	pop    %ebp
f0101564:	c3                   	ret    

f0101565 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101565:	55                   	push   %ebp
f0101566:	89 e5                	mov    %esp,%ebp
f0101568:	56                   	push   %esi
f0101569:	53                   	push   %ebx
f010156a:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010156d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101570:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0101573:	85 f6                	test   %esi,%esi
f0101575:	74 29                	je     f01015a0 <strncmp+0x3b>
f0101577:	0f b6 03             	movzbl (%ebx),%eax
f010157a:	84 c0                	test   %al,%al
f010157c:	74 30                	je     f01015ae <strncmp+0x49>
f010157e:	3a 02                	cmp    (%edx),%al
f0101580:	75 2c                	jne    f01015ae <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f0101582:	8d 43 01             	lea    0x1(%ebx),%eax
f0101585:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
f0101587:	89 c3                	mov    %eax,%ebx
f0101589:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010158c:	39 f0                	cmp    %esi,%eax
f010158e:	74 17                	je     f01015a7 <strncmp+0x42>
f0101590:	0f b6 08             	movzbl (%eax),%ecx
f0101593:	84 c9                	test   %cl,%cl
f0101595:	74 17                	je     f01015ae <strncmp+0x49>
f0101597:	83 c0 01             	add    $0x1,%eax
f010159a:	3a 0a                	cmp    (%edx),%cl
f010159c:	74 e9                	je     f0101587 <strncmp+0x22>
f010159e:	eb 0e                	jmp    f01015ae <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01015a0:	b8 00 00 00 00       	mov    $0x0,%eax
f01015a5:	eb 0f                	jmp    f01015b6 <strncmp+0x51>
f01015a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01015ac:	eb 08                	jmp    f01015b6 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01015ae:	0f b6 03             	movzbl (%ebx),%eax
f01015b1:	0f b6 12             	movzbl (%edx),%edx
f01015b4:	29 d0                	sub    %edx,%eax
}
f01015b6:	5b                   	pop    %ebx
f01015b7:	5e                   	pop    %esi
f01015b8:	5d                   	pop    %ebp
f01015b9:	c3                   	ret    

f01015ba <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01015ba:	55                   	push   %ebp
f01015bb:	89 e5                	mov    %esp,%ebp
f01015bd:	8b 45 08             	mov    0x8(%ebp),%eax
f01015c0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015c4:	0f b6 10             	movzbl (%eax),%edx
f01015c7:	84 d2                	test   %dl,%dl
f01015c9:	74 1b                	je     f01015e6 <strchr+0x2c>
		if (*s == c)
f01015cb:	38 ca                	cmp    %cl,%dl
f01015cd:	75 06                	jne    f01015d5 <strchr+0x1b>
f01015cf:	eb 1a                	jmp    f01015eb <strchr+0x31>
f01015d1:	38 ca                	cmp    %cl,%dl
f01015d3:	74 16                	je     f01015eb <strchr+0x31>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01015d5:	83 c0 01             	add    $0x1,%eax
f01015d8:	0f b6 10             	movzbl (%eax),%edx
f01015db:	84 d2                	test   %dl,%dl
f01015dd:	75 f2                	jne    f01015d1 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f01015df:	b8 00 00 00 00       	mov    $0x0,%eax
f01015e4:	eb 05                	jmp    f01015eb <strchr+0x31>
f01015e6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015eb:	5d                   	pop    %ebp
f01015ec:	c3                   	ret    

f01015ed <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01015ed:	55                   	push   %ebp
f01015ee:	89 e5                	mov    %esp,%ebp
f01015f0:	8b 45 08             	mov    0x8(%ebp),%eax
f01015f3:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015f7:	0f b6 10             	movzbl (%eax),%edx
f01015fa:	84 d2                	test   %dl,%dl
f01015fc:	74 14                	je     f0101612 <strfind+0x25>
		if (*s == c)
f01015fe:	38 ca                	cmp    %cl,%dl
f0101600:	75 06                	jne    f0101608 <strfind+0x1b>
f0101602:	eb 0e                	jmp    f0101612 <strfind+0x25>
f0101604:	38 ca                	cmp    %cl,%dl
f0101606:	74 0a                	je     f0101612 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101608:	83 c0 01             	add    $0x1,%eax
f010160b:	0f b6 10             	movzbl (%eax),%edx
f010160e:	84 d2                	test   %dl,%dl
f0101610:	75 f2                	jne    f0101604 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0101612:	5d                   	pop    %ebp
f0101613:	c3                   	ret    

f0101614 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101614:	55                   	push   %ebp
f0101615:	89 e5                	mov    %esp,%ebp
f0101617:	83 ec 0c             	sub    $0xc,%esp
f010161a:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010161d:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101620:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101623:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101626:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101629:	85 c9                	test   %ecx,%ecx
f010162b:	74 36                	je     f0101663 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010162d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101633:	75 28                	jne    f010165d <memset+0x49>
f0101635:	f6 c1 03             	test   $0x3,%cl
f0101638:	75 23                	jne    f010165d <memset+0x49>
		c &= 0xFF;
f010163a:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010163e:	89 d3                	mov    %edx,%ebx
f0101640:	c1 e3 08             	shl    $0x8,%ebx
f0101643:	89 d6                	mov    %edx,%esi
f0101645:	c1 e6 18             	shl    $0x18,%esi
f0101648:	89 d0                	mov    %edx,%eax
f010164a:	c1 e0 10             	shl    $0x10,%eax
f010164d:	09 f0                	or     %esi,%eax
f010164f:	09 c2                	or     %eax,%edx
f0101651:	89 d0                	mov    %edx,%eax
f0101653:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101655:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101658:	fc                   	cld    
f0101659:	f3 ab                	rep stos %eax,%es:(%edi)
f010165b:	eb 06                	jmp    f0101663 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010165d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101660:	fc                   	cld    
f0101661:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101663:	89 f8                	mov    %edi,%eax
f0101665:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101668:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010166b:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010166e:	89 ec                	mov    %ebp,%esp
f0101670:	5d                   	pop    %ebp
f0101671:	c3                   	ret    

f0101672 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101672:	55                   	push   %ebp
f0101673:	89 e5                	mov    %esp,%ebp
f0101675:	83 ec 08             	sub    $0x8,%esp
f0101678:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010167b:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010167e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101681:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101684:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101687:	39 c6                	cmp    %eax,%esi
f0101689:	73 36                	jae    f01016c1 <memmove+0x4f>
f010168b:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010168e:	39 d0                	cmp    %edx,%eax
f0101690:	73 2f                	jae    f01016c1 <memmove+0x4f>
		s += n;
		d += n;
f0101692:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101695:	f6 c2 03             	test   $0x3,%dl
f0101698:	75 1b                	jne    f01016b5 <memmove+0x43>
f010169a:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01016a0:	75 13                	jne    f01016b5 <memmove+0x43>
f01016a2:	f6 c1 03             	test   $0x3,%cl
f01016a5:	75 0e                	jne    f01016b5 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01016a7:	83 ef 04             	sub    $0x4,%edi
f01016aa:	8d 72 fc             	lea    -0x4(%edx),%esi
f01016ad:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01016b0:	fd                   	std    
f01016b1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016b3:	eb 09                	jmp    f01016be <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01016b5:	83 ef 01             	sub    $0x1,%edi
f01016b8:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01016bb:	fd                   	std    
f01016bc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01016be:	fc                   	cld    
f01016bf:	eb 20                	jmp    f01016e1 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016c1:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01016c7:	75 13                	jne    f01016dc <memmove+0x6a>
f01016c9:	a8 03                	test   $0x3,%al
f01016cb:	75 0f                	jne    f01016dc <memmove+0x6a>
f01016cd:	f6 c1 03             	test   $0x3,%cl
f01016d0:	75 0a                	jne    f01016dc <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01016d2:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01016d5:	89 c7                	mov    %eax,%edi
f01016d7:	fc                   	cld    
f01016d8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016da:	eb 05                	jmp    f01016e1 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01016dc:	89 c7                	mov    %eax,%edi
f01016de:	fc                   	cld    
f01016df:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01016e1:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01016e4:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01016e7:	89 ec                	mov    %ebp,%esp
f01016e9:	5d                   	pop    %ebp
f01016ea:	c3                   	ret    

f01016eb <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f01016eb:	55                   	push   %ebp
f01016ec:	89 e5                	mov    %esp,%ebp
f01016ee:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01016f1:	8b 45 10             	mov    0x10(%ebp),%eax
f01016f4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01016f8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016fb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01016ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0101702:	89 04 24             	mov    %eax,(%esp)
f0101705:	e8 68 ff ff ff       	call   f0101672 <memmove>
}
f010170a:	c9                   	leave  
f010170b:	c3                   	ret    

f010170c <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010170c:	55                   	push   %ebp
f010170d:	89 e5                	mov    %esp,%ebp
f010170f:	57                   	push   %edi
f0101710:	56                   	push   %esi
f0101711:	53                   	push   %ebx
f0101712:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101715:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101718:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010171b:	8d 78 ff             	lea    -0x1(%eax),%edi
f010171e:	85 c0                	test   %eax,%eax
f0101720:	74 36                	je     f0101758 <memcmp+0x4c>
		if (*s1 != *s2)
f0101722:	0f b6 03             	movzbl (%ebx),%eax
f0101725:	0f b6 0e             	movzbl (%esi),%ecx
f0101728:	38 c8                	cmp    %cl,%al
f010172a:	75 17                	jne    f0101743 <memcmp+0x37>
f010172c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101731:	eb 1a                	jmp    f010174d <memcmp+0x41>
f0101733:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0101738:	83 c2 01             	add    $0x1,%edx
f010173b:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f010173f:	38 c8                	cmp    %cl,%al
f0101741:	74 0a                	je     f010174d <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f0101743:	0f b6 c0             	movzbl %al,%eax
f0101746:	0f b6 c9             	movzbl %cl,%ecx
f0101749:	29 c8                	sub    %ecx,%eax
f010174b:	eb 10                	jmp    f010175d <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010174d:	39 fa                	cmp    %edi,%edx
f010174f:	75 e2                	jne    f0101733 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101751:	b8 00 00 00 00       	mov    $0x0,%eax
f0101756:	eb 05                	jmp    f010175d <memcmp+0x51>
f0101758:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010175d:	5b                   	pop    %ebx
f010175e:	5e                   	pop    %esi
f010175f:	5f                   	pop    %edi
f0101760:	5d                   	pop    %ebp
f0101761:	c3                   	ret    

f0101762 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101762:	55                   	push   %ebp
f0101763:	89 e5                	mov    %esp,%ebp
f0101765:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101768:	89 c2                	mov    %eax,%edx
f010176a:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010176d:	39 d0                	cmp    %edx,%eax
f010176f:	73 18                	jae    f0101789 <memfind+0x27>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101771:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0101775:	38 08                	cmp    %cl,(%eax)
f0101777:	75 09                	jne    f0101782 <memfind+0x20>
f0101779:	eb 0e                	jmp    f0101789 <memfind+0x27>
f010177b:	38 08                	cmp    %cl,(%eax)
f010177d:	8d 76 00             	lea    0x0(%esi),%esi
f0101780:	74 07                	je     f0101789 <memfind+0x27>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101782:	83 c0 01             	add    $0x1,%eax
f0101785:	39 d0                	cmp    %edx,%eax
f0101787:	75 f2                	jne    f010177b <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101789:	5d                   	pop    %ebp
f010178a:	c3                   	ret    

f010178b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010178b:	55                   	push   %ebp
f010178c:	89 e5                	mov    %esp,%ebp
f010178e:	57                   	push   %edi
f010178f:	56                   	push   %esi
f0101790:	53                   	push   %ebx
f0101791:	83 ec 04             	sub    $0x4,%esp
f0101794:	8b 55 08             	mov    0x8(%ebp),%edx
f0101797:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010179a:	0f b6 02             	movzbl (%edx),%eax
f010179d:	3c 09                	cmp    $0x9,%al
f010179f:	74 04                	je     f01017a5 <strtol+0x1a>
f01017a1:	3c 20                	cmp    $0x20,%al
f01017a3:	75 0e                	jne    f01017b3 <strtol+0x28>
		s++;
f01017a5:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01017a8:	0f b6 02             	movzbl (%edx),%eax
f01017ab:	3c 09                	cmp    $0x9,%al
f01017ad:	74 f6                	je     f01017a5 <strtol+0x1a>
f01017af:	3c 20                	cmp    $0x20,%al
f01017b1:	74 f2                	je     f01017a5 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f01017b3:	3c 2b                	cmp    $0x2b,%al
f01017b5:	75 0a                	jne    f01017c1 <strtol+0x36>
		s++;
f01017b7:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01017ba:	bf 00 00 00 00       	mov    $0x0,%edi
f01017bf:	eb 10                	jmp    f01017d1 <strtol+0x46>
f01017c1:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01017c6:	3c 2d                	cmp    $0x2d,%al
f01017c8:	75 07                	jne    f01017d1 <strtol+0x46>
		s++, neg = 1;
f01017ca:	83 c2 01             	add    $0x1,%edx
f01017cd:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01017d1:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01017d7:	75 15                	jne    f01017ee <strtol+0x63>
f01017d9:	80 3a 30             	cmpb   $0x30,(%edx)
f01017dc:	75 10                	jne    f01017ee <strtol+0x63>
f01017de:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01017e2:	75 0a                	jne    f01017ee <strtol+0x63>
		s += 2, base = 16;
f01017e4:	83 c2 02             	add    $0x2,%edx
f01017e7:	bb 10 00 00 00       	mov    $0x10,%ebx
f01017ec:	eb 10                	jmp    f01017fe <strtol+0x73>
	else if (base == 0 && s[0] == '0')
f01017ee:	85 db                	test   %ebx,%ebx
f01017f0:	75 0c                	jne    f01017fe <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01017f2:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01017f4:	80 3a 30             	cmpb   $0x30,(%edx)
f01017f7:	75 05                	jne    f01017fe <strtol+0x73>
		s++, base = 8;
f01017f9:	83 c2 01             	add    $0x1,%edx
f01017fc:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f01017fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0101803:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101806:	0f b6 0a             	movzbl (%edx),%ecx
f0101809:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010180c:	89 f3                	mov    %esi,%ebx
f010180e:	80 fb 09             	cmp    $0x9,%bl
f0101811:	77 08                	ja     f010181b <strtol+0x90>
			dig = *s - '0';
f0101813:	0f be c9             	movsbl %cl,%ecx
f0101816:	83 e9 30             	sub    $0x30,%ecx
f0101819:	eb 22                	jmp    f010183d <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
f010181b:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010181e:	89 f3                	mov    %esi,%ebx
f0101820:	80 fb 19             	cmp    $0x19,%bl
f0101823:	77 08                	ja     f010182d <strtol+0xa2>
			dig = *s - 'a' + 10;
f0101825:	0f be c9             	movsbl %cl,%ecx
f0101828:	83 e9 57             	sub    $0x57,%ecx
f010182b:	eb 10                	jmp    f010183d <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
f010182d:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0101830:	89 f3                	mov    %esi,%ebx
f0101832:	80 fb 19             	cmp    $0x19,%bl
f0101835:	77 16                	ja     f010184d <strtol+0xc2>
			dig = *s - 'A' + 10;
f0101837:	0f be c9             	movsbl %cl,%ecx
f010183a:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f010183d:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0101840:	7d 0f                	jge    f0101851 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
f0101842:	83 c2 01             	add    $0x1,%edx
f0101845:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0101849:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f010184b:	eb b9                	jmp    f0101806 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f010184d:	89 c1                	mov    %eax,%ecx
f010184f:	eb 02                	jmp    f0101853 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101851:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101853:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101857:	74 05                	je     f010185e <strtol+0xd3>
		*endptr = (char *) s;
f0101859:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010185c:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f010185e:	85 ff                	test   %edi,%edi
f0101860:	74 04                	je     f0101866 <strtol+0xdb>
f0101862:	89 c8                	mov    %ecx,%eax
f0101864:	f7 d8                	neg    %eax
}
f0101866:	83 c4 04             	add    $0x4,%esp
f0101869:	5b                   	pop    %ebx
f010186a:	5e                   	pop    %esi
f010186b:	5f                   	pop    %edi
f010186c:	5d                   	pop    %ebp
f010186d:	c3                   	ret    
	...

f0101870 <__udivdi3>:
f0101870:	83 ec 1c             	sub    $0x1c,%esp
f0101873:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0101877:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f010187b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f010187f:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101883:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101887:	8b 74 24 24          	mov    0x24(%esp),%esi
f010188b:	85 c0                	test   %eax,%eax
f010188d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101891:	89 cf                	mov    %ecx,%edi
f0101893:	89 6c 24 04          	mov    %ebp,0x4(%esp)
f0101897:	75 37                	jne    f01018d0 <__udivdi3+0x60>
f0101899:	39 f1                	cmp    %esi,%ecx
f010189b:	77 73                	ja     f0101910 <__udivdi3+0xa0>
f010189d:	85 c9                	test   %ecx,%ecx
f010189f:	75 0b                	jne    f01018ac <__udivdi3+0x3c>
f01018a1:	b8 01 00 00 00       	mov    $0x1,%eax
f01018a6:	31 d2                	xor    %edx,%edx
f01018a8:	f7 f1                	div    %ecx
f01018aa:	89 c1                	mov    %eax,%ecx
f01018ac:	89 f0                	mov    %esi,%eax
f01018ae:	31 d2                	xor    %edx,%edx
f01018b0:	f7 f1                	div    %ecx
f01018b2:	89 c6                	mov    %eax,%esi
f01018b4:	89 e8                	mov    %ebp,%eax
f01018b6:	f7 f1                	div    %ecx
f01018b8:	89 f2                	mov    %esi,%edx
f01018ba:	8b 74 24 10          	mov    0x10(%esp),%esi
f01018be:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01018c2:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01018c6:	83 c4 1c             	add    $0x1c,%esp
f01018c9:	c3                   	ret    
f01018ca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01018d0:	39 f0                	cmp    %esi,%eax
f01018d2:	77 24                	ja     f01018f8 <__udivdi3+0x88>
f01018d4:	0f bd e8             	bsr    %eax,%ebp
f01018d7:	83 f5 1f             	xor    $0x1f,%ebp
f01018da:	75 4c                	jne    f0101928 <__udivdi3+0xb8>
f01018dc:	31 d2                	xor    %edx,%edx
f01018de:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f01018e2:	0f 86 b0 00 00 00    	jbe    f0101998 <__udivdi3+0x128>
f01018e8:	39 f0                	cmp    %esi,%eax
f01018ea:	0f 82 a8 00 00 00    	jb     f0101998 <__udivdi3+0x128>
f01018f0:	31 c0                	xor    %eax,%eax
f01018f2:	eb c6                	jmp    f01018ba <__udivdi3+0x4a>
f01018f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018f8:	31 d2                	xor    %edx,%edx
f01018fa:	31 c0                	xor    %eax,%eax
f01018fc:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101900:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101904:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101908:	83 c4 1c             	add    $0x1c,%esp
f010190b:	c3                   	ret    
f010190c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101910:	89 e8                	mov    %ebp,%eax
f0101912:	89 f2                	mov    %esi,%edx
f0101914:	f7 f1                	div    %ecx
f0101916:	31 d2                	xor    %edx,%edx
f0101918:	8b 74 24 10          	mov    0x10(%esp),%esi
f010191c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101920:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101924:	83 c4 1c             	add    $0x1c,%esp
f0101927:	c3                   	ret    
f0101928:	89 e9                	mov    %ebp,%ecx
f010192a:	89 fa                	mov    %edi,%edx
f010192c:	d3 e0                	shl    %cl,%eax
f010192e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101932:	b8 20 00 00 00       	mov    $0x20,%eax
f0101937:	29 e8                	sub    %ebp,%eax
f0101939:	89 c1                	mov    %eax,%ecx
f010193b:	d3 ea                	shr    %cl,%edx
f010193d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101941:	09 ca                	or     %ecx,%edx
f0101943:	89 e9                	mov    %ebp,%ecx
f0101945:	d3 e7                	shl    %cl,%edi
f0101947:	89 c1                	mov    %eax,%ecx
f0101949:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010194d:	89 f2                	mov    %esi,%edx
f010194f:	d3 ea                	shr    %cl,%edx
f0101951:	89 e9                	mov    %ebp,%ecx
f0101953:	89 14 24             	mov    %edx,(%esp)
f0101956:	8b 54 24 04          	mov    0x4(%esp),%edx
f010195a:	d3 e6                	shl    %cl,%esi
f010195c:	89 c1                	mov    %eax,%ecx
f010195e:	d3 ea                	shr    %cl,%edx
f0101960:	89 d0                	mov    %edx,%eax
f0101962:	09 f0                	or     %esi,%eax
f0101964:	8b 34 24             	mov    (%esp),%esi
f0101967:	89 f2                	mov    %esi,%edx
f0101969:	f7 74 24 0c          	divl   0xc(%esp)
f010196d:	89 d6                	mov    %edx,%esi
f010196f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101973:	f7 e7                	mul    %edi
f0101975:	39 d6                	cmp    %edx,%esi
f0101977:	72 2f                	jb     f01019a8 <__udivdi3+0x138>
f0101979:	8b 7c 24 04          	mov    0x4(%esp),%edi
f010197d:	89 e9                	mov    %ebp,%ecx
f010197f:	d3 e7                	shl    %cl,%edi
f0101981:	39 c7                	cmp    %eax,%edi
f0101983:	73 04                	jae    f0101989 <__udivdi3+0x119>
f0101985:	39 d6                	cmp    %edx,%esi
f0101987:	74 1f                	je     f01019a8 <__udivdi3+0x138>
f0101989:	8b 44 24 08          	mov    0x8(%esp),%eax
f010198d:	31 d2                	xor    %edx,%edx
f010198f:	e9 26 ff ff ff       	jmp    f01018ba <__udivdi3+0x4a>
f0101994:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101998:	b8 01 00 00 00       	mov    $0x1,%eax
f010199d:	e9 18 ff ff ff       	jmp    f01018ba <__udivdi3+0x4a>
f01019a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01019a8:	8b 44 24 08          	mov    0x8(%esp),%eax
f01019ac:	31 d2                	xor    %edx,%edx
f01019ae:	83 e8 01             	sub    $0x1,%eax
f01019b1:	8b 74 24 10          	mov    0x10(%esp),%esi
f01019b5:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01019b9:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01019bd:	83 c4 1c             	add    $0x1c,%esp
f01019c0:	c3                   	ret    
	...

f01019d0 <__umoddi3>:
f01019d0:	83 ec 1c             	sub    $0x1c,%esp
f01019d3:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f01019d7:	8b 44 24 20          	mov    0x20(%esp),%eax
f01019db:	89 74 24 10          	mov    %esi,0x10(%esp)
f01019df:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01019e3:	8b 74 24 24          	mov    0x24(%esp),%esi
f01019e7:	85 d2                	test   %edx,%edx
f01019e9:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01019ed:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01019f1:	89 cf                	mov    %ecx,%edi
f01019f3:	89 c5                	mov    %eax,%ebp
f01019f5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019f9:	89 34 24             	mov    %esi,(%esp)
f01019fc:	75 22                	jne    f0101a20 <__umoddi3+0x50>
f01019fe:	39 f1                	cmp    %esi,%ecx
f0101a00:	76 56                	jbe    f0101a58 <__umoddi3+0x88>
f0101a02:	89 f2                	mov    %esi,%edx
f0101a04:	f7 f1                	div    %ecx
f0101a06:	89 d0                	mov    %edx,%eax
f0101a08:	31 d2                	xor    %edx,%edx
f0101a0a:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a0e:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a12:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a16:	83 c4 1c             	add    $0x1c,%esp
f0101a19:	c3                   	ret    
f0101a1a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101a20:	39 f2                	cmp    %esi,%edx
f0101a22:	77 54                	ja     f0101a78 <__umoddi3+0xa8>
f0101a24:	0f bd c2             	bsr    %edx,%eax
f0101a27:	83 f0 1f             	xor    $0x1f,%eax
f0101a2a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a2e:	75 60                	jne    f0101a90 <__umoddi3+0xc0>
f0101a30:	39 e9                	cmp    %ebp,%ecx
f0101a32:	0f 87 08 01 00 00    	ja     f0101b40 <__umoddi3+0x170>
f0101a38:	29 cd                	sub    %ecx,%ebp
f0101a3a:	19 d6                	sbb    %edx,%esi
f0101a3c:	89 34 24             	mov    %esi,(%esp)
f0101a3f:	8b 14 24             	mov    (%esp),%edx
f0101a42:	89 e8                	mov    %ebp,%eax
f0101a44:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a48:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a4c:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a50:	83 c4 1c             	add    $0x1c,%esp
f0101a53:	c3                   	ret    
f0101a54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a58:	85 c9                	test   %ecx,%ecx
f0101a5a:	75 0b                	jne    f0101a67 <__umoddi3+0x97>
f0101a5c:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a61:	31 d2                	xor    %edx,%edx
f0101a63:	f7 f1                	div    %ecx
f0101a65:	89 c1                	mov    %eax,%ecx
f0101a67:	89 f0                	mov    %esi,%eax
f0101a69:	31 d2                	xor    %edx,%edx
f0101a6b:	f7 f1                	div    %ecx
f0101a6d:	89 e8                	mov    %ebp,%eax
f0101a6f:	f7 f1                	div    %ecx
f0101a71:	eb 93                	jmp    f0101a06 <__umoddi3+0x36>
f0101a73:	90                   	nop
f0101a74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a78:	89 f2                	mov    %esi,%edx
f0101a7a:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a7e:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a82:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a86:	83 c4 1c             	add    $0x1c,%esp
f0101a89:	c3                   	ret    
f0101a8a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101a90:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a95:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101a9a:	89 f8                	mov    %edi,%eax
f0101a9c:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0101aa0:	d3 e2                	shl    %cl,%edx
f0101aa2:	89 e9                	mov    %ebp,%ecx
f0101aa4:	d3 e8                	shr    %cl,%eax
f0101aa6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101aab:	09 d0                	or     %edx,%eax
f0101aad:	89 f2                	mov    %esi,%edx
f0101aaf:	89 04 24             	mov    %eax,(%esp)
f0101ab2:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101ab6:	d3 e7                	shl    %cl,%edi
f0101ab8:	89 e9                	mov    %ebp,%ecx
f0101aba:	d3 ea                	shr    %cl,%edx
f0101abc:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101ac1:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101ac5:	d3 e6                	shl    %cl,%esi
f0101ac7:	89 e9                	mov    %ebp,%ecx
f0101ac9:	d3 e8                	shr    %cl,%eax
f0101acb:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101ad0:	09 f0                	or     %esi,%eax
f0101ad2:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101ad6:	f7 34 24             	divl   (%esp)
f0101ad9:	d3 e6                	shl    %cl,%esi
f0101adb:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101adf:	89 d6                	mov    %edx,%esi
f0101ae1:	f7 e7                	mul    %edi
f0101ae3:	39 d6                	cmp    %edx,%esi
f0101ae5:	89 c7                	mov    %eax,%edi
f0101ae7:	89 d1                	mov    %edx,%ecx
f0101ae9:	72 41                	jb     f0101b2c <__umoddi3+0x15c>
f0101aeb:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101aef:	72 37                	jb     f0101b28 <__umoddi3+0x158>
f0101af1:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101af5:	29 f8                	sub    %edi,%eax
f0101af7:	19 ce                	sbb    %ecx,%esi
f0101af9:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101afe:	89 f2                	mov    %esi,%edx
f0101b00:	d3 e8                	shr    %cl,%eax
f0101b02:	89 e9                	mov    %ebp,%ecx
f0101b04:	d3 e2                	shl    %cl,%edx
f0101b06:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b0b:	09 d0                	or     %edx,%eax
f0101b0d:	89 f2                	mov    %esi,%edx
f0101b0f:	d3 ea                	shr    %cl,%edx
f0101b11:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101b15:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101b19:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101b1d:	83 c4 1c             	add    $0x1c,%esp
f0101b20:	c3                   	ret    
f0101b21:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101b28:	39 d6                	cmp    %edx,%esi
f0101b2a:	75 c5                	jne    f0101af1 <__umoddi3+0x121>
f0101b2c:	89 d1                	mov    %edx,%ecx
f0101b2e:	89 c7                	mov    %eax,%edi
f0101b30:	2b 7c 24 0c          	sub    0xc(%esp),%edi
f0101b34:	1b 0c 24             	sbb    (%esp),%ecx
f0101b37:	eb b8                	jmp    f0101af1 <__umoddi3+0x121>
f0101b39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101b40:	39 f2                	cmp    %esi,%edx
f0101b42:	0f 82 f0 fe ff ff    	jb     f0101a38 <__umoddi3+0x68>
f0101b48:	e9 f2 fe ff ff       	jmp    f0101a3f <__umoddi3+0x6f>
