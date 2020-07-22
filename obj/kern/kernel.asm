
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
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0
	# Turn on page size extension.

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
f0100034:	bc 00 70 11 f0       	mov    $0xf0117000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 08             	sub    $0x8,%esp
f0100047:	e8 03 01 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010004c:	81 c3 bc 82 01 00    	add    $0x182bc,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 80 a0 11 f0    	mov    $0xf011a080,%edx
f0100058:	c7 c0 c0 a6 11 f0    	mov    $0xf011a6c0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 14 3f 00 00       	call   f0103f7d <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 b8 c0 fe ff    	lea    -0x13f48(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 47 31 00 00       	call   f01031c9 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 80 14 00 00       	call   f0101507 <mem_init>
f0100087:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010008a:	83 ec 0c             	sub    $0xc,%esp
f010008d:	6a 00                	push   $0x0
f010008f:	e8 0c 0a 00 00       	call   f0100aa0 <monitor>
f0100094:	83 c4 10             	add    $0x10,%esp
f0100097:	eb f1                	jmp    f010008a <i386_init+0x4a>

f0100099 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100099:	55                   	push   %ebp
f010009a:	89 e5                	mov    %esp,%ebp
f010009c:	57                   	push   %edi
f010009d:	56                   	push   %esi
f010009e:	53                   	push   %ebx
f010009f:	83 ec 0c             	sub    $0xc,%esp
f01000a2:	e8 a8 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f01000a7:	81 c3 61 82 01 00    	add    $0x18261,%ebx
f01000ad:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000b0:	c7 c0 c4 a6 11 f0    	mov    $0xf011a6c4,%eax
f01000b6:	83 38 00             	cmpl   $0x0,(%eax)
f01000b9:	74 0f                	je     f01000ca <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000bb:	83 ec 0c             	sub    $0xc,%esp
f01000be:	6a 00                	push   $0x0
f01000c0:	e8 db 09 00 00       	call   f0100aa0 <monitor>
f01000c5:	83 c4 10             	add    $0x10,%esp
f01000c8:	eb f1                	jmp    f01000bb <_panic+0x22>
	panicstr = fmt;
f01000ca:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f01000cc:	fa                   	cli    
f01000cd:	fc                   	cld    
	va_start(ap, fmt);
f01000ce:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d1:	83 ec 04             	sub    $0x4,%esp
f01000d4:	ff 75 0c             	pushl  0xc(%ebp)
f01000d7:	ff 75 08             	pushl  0x8(%ebp)
f01000da:	8d 83 d3 c0 fe ff    	lea    -0x13f2d(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 e3 30 00 00       	call   f01031c9 <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 a2 30 00 00       	call   f0103192 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 d7 d0 fe ff    	lea    -0x12f29(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 cb 30 00 00       	call   f01031c9 <cprintf>
f01000fe:	83 c4 10             	add    $0x10,%esp
f0100101:	eb b8                	jmp    f01000bb <_panic+0x22>

f0100103 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100103:	55                   	push   %ebp
f0100104:	89 e5                	mov    %esp,%ebp
f0100106:	56                   	push   %esi
f0100107:	53                   	push   %ebx
f0100108:	e8 42 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010010d:	81 c3 fb 81 01 00    	add    $0x181fb,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	pushl  0xc(%ebp)
f010011c:	ff 75 08             	pushl  0x8(%ebp)
f010011f:	8d 83 eb c0 fe ff    	lea    -0x13f15(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 9e 30 00 00       	call   f01031c9 <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 5b 30 00 00       	call   f0103192 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 d7 d0 fe ff    	lea    -0x12f29(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 84 30 00 00       	call   f01031c9 <cprintf>
	va_end(ap);
}
f0100145:	83 c4 10             	add    $0x10,%esp
f0100148:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010014b:	5b                   	pop    %ebx
f010014c:	5e                   	pop    %esi
f010014d:	5d                   	pop    %ebp
f010014e:	c3                   	ret    

f010014f <__x86.get_pc_thunk.bx>:
f010014f:	8b 1c 24             	mov    (%esp),%ebx
f0100152:	c3                   	ret    

f0100153 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100153:	55                   	push   %ebp
f0100154:	89 e5                	mov    %esp,%ebp
*/
static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100156:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010015b:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010015c:	a8 01                	test   $0x1,%al
f010015e:	74 0b                	je     f010016b <serial_proc_data+0x18>
f0100160:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100165:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100166:	0f b6 c0             	movzbl %al,%eax
}
f0100169:	5d                   	pop    %ebp
f010016a:	c3                   	ret    
		return -1;
f010016b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100170:	eb f7                	jmp    f0100169 <serial_proc_data+0x16>

f0100172 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100172:	55                   	push   %ebp
f0100173:	89 e5                	mov    %esp,%ebp
f0100175:	56                   	push   %esi
f0100176:	53                   	push   %ebx
f0100177:	e8 d3 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010017c:	81 c3 8c 81 01 00    	add    $0x1818c,%ebx
f0100182:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f0100184:	ff d6                	call   *%esi
f0100186:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100189:	74 2e                	je     f01001b9 <cons_intr+0x47>
		if (c == 0)
f010018b:	85 c0                	test   %eax,%eax
f010018d:	74 f5                	je     f0100184 <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f010018f:	8b 8b 9c 1f 00 00    	mov    0x1f9c(%ebx),%ecx
f0100195:	8d 51 01             	lea    0x1(%ecx),%edx
f0100198:	89 93 9c 1f 00 00    	mov    %edx,0x1f9c(%ebx)
f010019e:	88 84 0b 98 1d 00 00 	mov    %al,0x1d98(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001a5:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001ab:	75 d7                	jne    f0100184 <cons_intr+0x12>
			cons.wpos = 0;
f01001ad:	c7 83 9c 1f 00 00 00 	movl   $0x0,0x1f9c(%ebx)
f01001b4:	00 00 00 
f01001b7:	eb cb                	jmp    f0100184 <cons_intr+0x12>
	}
}
f01001b9:	5b                   	pop    %ebx
f01001ba:	5e                   	pop    %esi
f01001bb:	5d                   	pop    %ebp
f01001bc:	c3                   	ret    

f01001bd <kbd_proc_data>:
{
f01001bd:	55                   	push   %ebp
f01001be:	89 e5                	mov    %esp,%ebp
f01001c0:	56                   	push   %esi
f01001c1:	53                   	push   %ebx
f01001c2:	e8 88 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01001c7:	81 c3 41 81 01 00    	add    $0x18141,%ebx
f01001cd:	ba 64 00 00 00       	mov    $0x64,%edx
f01001d2:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001d3:	a8 01                	test   $0x1,%al
f01001d5:	0f 84 06 01 00 00    	je     f01002e1 <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f01001db:	a8 20                	test   $0x20,%al
f01001dd:	0f 85 05 01 00 00    	jne    f01002e8 <kbd_proc_data+0x12b>
f01001e3:	ba 60 00 00 00       	mov    $0x60,%edx
f01001e8:	ec                   	in     (%dx),%al
f01001e9:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001eb:	3c e0                	cmp    $0xe0,%al
f01001ed:	0f 84 93 00 00 00    	je     f0100286 <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f01001f3:	84 c0                	test   %al,%al
f01001f5:	0f 88 a0 00 00 00    	js     f010029b <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f01001fb:	8b 8b 78 1d 00 00    	mov    0x1d78(%ebx),%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x57>
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 8b 78 1d 00 00    	mov    %ecx,0x1d78(%ebx)
	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
f0100217:	0f b6 84 13 38 c2 fe 	movzbl -0x13dc8(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 78 1d 00 00    	or     0x1d78(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 38 c1 fe 	movzbl -0x13ec8(%ebx,%edx,1),%ecx
f010022c:	ff 
f010022d:	31 c8                	xor    %ecx,%eax
f010022f:	89 83 78 1d 00 00    	mov    %eax,0x1d78(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f0100235:	89 c1                	mov    %eax,%ecx
f0100237:	83 e1 03             	and    $0x3,%ecx
f010023a:	8b 8c 8b f8 1c 00 00 	mov    0x1cf8(%ebx,%ecx,4),%ecx
f0100241:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100245:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100248:	a8 08                	test   $0x8,%al
f010024a:	74 0d                	je     f0100259 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f010024c:	89 f2                	mov    %esi,%edx
f010024e:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f0100251:	83 f9 19             	cmp    $0x19,%ecx
f0100254:	77 7a                	ja     f01002d0 <kbd_proc_data+0x113>
			c += 'A' - 'a';
f0100256:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100259:	f7 d0                	not    %eax
f010025b:	a8 06                	test   $0x6,%al
f010025d:	75 33                	jne    f0100292 <kbd_proc_data+0xd5>
f010025f:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f0100265:	75 2b                	jne    f0100292 <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f0100267:	83 ec 0c             	sub    $0xc,%esp
f010026a:	8d 83 05 c1 fe ff    	lea    -0x13efb(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 53 2f 00 00       	call   f01031c9 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100276:	b8 03 00 00 00       	mov    $0x3,%eax
f010027b:	ba 92 00 00 00       	mov    $0x92,%edx
f0100280:	ee                   	out    %al,(%dx)
f0100281:	83 c4 10             	add    $0x10,%esp
f0100284:	eb 0c                	jmp    f0100292 <kbd_proc_data+0xd5>
		shift |= E0ESC;
f0100286:	83 8b 78 1d 00 00 40 	orl    $0x40,0x1d78(%ebx)
		return 0;
f010028d:	be 00 00 00 00       	mov    $0x0,%esi
}
f0100292:	89 f0                	mov    %esi,%eax
f0100294:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100297:	5b                   	pop    %ebx
f0100298:	5e                   	pop    %esi
f0100299:	5d                   	pop    %ebp
f010029a:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010029b:	8b 8b 78 1d 00 00    	mov    0x1d78(%ebx),%ecx
f01002a1:	89 ce                	mov    %ecx,%esi
f01002a3:	83 e6 40             	and    $0x40,%esi
f01002a6:	83 e0 7f             	and    $0x7f,%eax
f01002a9:	85 f6                	test   %esi,%esi
f01002ab:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002ae:	0f b6 d2             	movzbl %dl,%edx
f01002b1:	0f b6 84 13 38 c2 fe 	movzbl -0x13dc8(%ebx,%edx,1),%eax
f01002b8:	ff 
f01002b9:	83 c8 40             	or     $0x40,%eax
f01002bc:	0f b6 c0             	movzbl %al,%eax
f01002bf:	f7 d0                	not    %eax
f01002c1:	21 c8                	and    %ecx,%eax
f01002c3:	89 83 78 1d 00 00    	mov    %eax,0x1d78(%ebx)
		return 0;
f01002c9:	be 00 00 00 00       	mov    $0x0,%esi
f01002ce:	eb c2                	jmp    f0100292 <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f01002d0:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002d3:	8d 4e 20             	lea    0x20(%esi),%ecx
f01002d6:	83 fa 1a             	cmp    $0x1a,%edx
f01002d9:	0f 42 f1             	cmovb  %ecx,%esi
f01002dc:	e9 78 ff ff ff       	jmp    f0100259 <kbd_proc_data+0x9c>
		return -1;
f01002e1:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002e6:	eb aa                	jmp    f0100292 <kbd_proc_data+0xd5>
		return -1;
f01002e8:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002ed:	eb a3                	jmp    f0100292 <kbd_proc_data+0xd5>

f01002ef <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ef:	55                   	push   %ebp
f01002f0:	89 e5                	mov    %esp,%ebp
f01002f2:	57                   	push   %edi
f01002f3:	56                   	push   %esi
f01002f4:	53                   	push   %ebx
f01002f5:	83 ec 1c             	sub    $0x1c,%esp
f01002f8:	e8 52 fe ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01002fd:	81 c3 0b 80 01 00    	add    $0x1800b,%ebx
f0100303:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f0100306:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010030b:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100310:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100315:	eb 09                	jmp    f0100320 <cons_putc+0x31>
f0100317:	89 ca                	mov    %ecx,%edx
f0100319:	ec                   	in     (%dx),%al
f010031a:	ec                   	in     (%dx),%al
f010031b:	ec                   	in     (%dx),%al
f010031c:	ec                   	in     (%dx),%al
	     i++)
f010031d:	83 c6 01             	add    $0x1,%esi
f0100320:	89 fa                	mov    %edi,%edx
f0100322:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100323:	a8 20                	test   $0x20,%al
f0100325:	75 08                	jne    f010032f <cons_putc+0x40>
f0100327:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010032d:	7e e8                	jle    f0100317 <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f010032f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100332:	89 f8                	mov    %edi,%eax
f0100334:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100337:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010033c:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010033d:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100342:	bf 79 03 00 00       	mov    $0x379,%edi
f0100347:	b9 84 00 00 00       	mov    $0x84,%ecx
f010034c:	eb 09                	jmp    f0100357 <cons_putc+0x68>
f010034e:	89 ca                	mov    %ecx,%edx
f0100350:	ec                   	in     (%dx),%al
f0100351:	ec                   	in     (%dx),%al
f0100352:	ec                   	in     (%dx),%al
f0100353:	ec                   	in     (%dx),%al
f0100354:	83 c6 01             	add    $0x1,%esi
f0100357:	89 fa                	mov    %edi,%edx
f0100359:	ec                   	in     (%dx),%al
f010035a:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100360:	7f 04                	jg     f0100366 <cons_putc+0x77>
f0100362:	84 c0                	test   %al,%al
f0100364:	79 e8                	jns    f010034e <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100366:	ba 78 03 00 00       	mov    $0x378,%edx
f010036b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f010036f:	ee                   	out    %al,(%dx)
f0100370:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100375:	b8 0d 00 00 00       	mov    $0xd,%eax
f010037a:	ee                   	out    %al,(%dx)
f010037b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100380:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100381:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100384:	89 fa                	mov    %edi,%edx
f0100386:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010038c:	89 f8                	mov    %edi,%eax
f010038e:	80 cc 07             	or     $0x7,%ah
f0100391:	85 d2                	test   %edx,%edx
f0100393:	0f 45 c7             	cmovne %edi,%eax
f0100396:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f0100399:	0f b6 c0             	movzbl %al,%eax
f010039c:	83 f8 09             	cmp    $0x9,%eax
f010039f:	0f 84 b9 00 00 00    	je     f010045e <cons_putc+0x16f>
f01003a5:	83 f8 09             	cmp    $0x9,%eax
f01003a8:	7e 74                	jle    f010041e <cons_putc+0x12f>
f01003aa:	83 f8 0a             	cmp    $0xa,%eax
f01003ad:	0f 84 9e 00 00 00    	je     f0100451 <cons_putc+0x162>
f01003b3:	83 f8 0d             	cmp    $0xd,%eax
f01003b6:	0f 85 d9 00 00 00    	jne    f0100495 <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f01003bc:	0f b7 83 a0 1f 00 00 	movzwl 0x1fa0(%ebx),%eax
f01003c3:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c9:	c1 e8 16             	shr    $0x16,%eax
f01003cc:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003cf:	c1 e0 04             	shl    $0x4,%eax
f01003d2:	66 89 83 a0 1f 00 00 	mov    %ax,0x1fa0(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003d9:	66 81 bb a0 1f 00 00 	cmpw   $0x7cf,0x1fa0(%ebx)
f01003e0:	cf 07 
f01003e2:	0f 87 d4 00 00 00    	ja     f01004bc <cons_putc+0x1cd>
	outb(addr_6845, 14);
f01003e8:	8b 8b a8 1f 00 00    	mov    0x1fa8(%ebx),%ecx
f01003ee:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003f3:	89 ca                	mov    %ecx,%edx
f01003f5:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003f6:	0f b7 9b a0 1f 00 00 	movzwl 0x1fa0(%ebx),%ebx
f01003fd:	8d 71 01             	lea    0x1(%ecx),%esi
f0100400:	89 d8                	mov    %ebx,%eax
f0100402:	66 c1 e8 08          	shr    $0x8,%ax
f0100406:	89 f2                	mov    %esi,%edx
f0100408:	ee                   	out    %al,(%dx)
f0100409:	b8 0f 00 00 00       	mov    $0xf,%eax
f010040e:	89 ca                	mov    %ecx,%edx
f0100410:	ee                   	out    %al,(%dx)
f0100411:	89 d8                	mov    %ebx,%eax
f0100413:	89 f2                	mov    %esi,%edx
f0100415:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100416:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100419:	5b                   	pop    %ebx
f010041a:	5e                   	pop    %esi
f010041b:	5f                   	pop    %edi
f010041c:	5d                   	pop    %ebp
f010041d:	c3                   	ret    
	switch (c & 0xff) {
f010041e:	83 f8 08             	cmp    $0x8,%eax
f0100421:	75 72                	jne    f0100495 <cons_putc+0x1a6>
		if (crt_pos > 0) {
f0100423:	0f b7 83 a0 1f 00 00 	movzwl 0x1fa0(%ebx),%eax
f010042a:	66 85 c0             	test   %ax,%ax
f010042d:	74 b9                	je     f01003e8 <cons_putc+0xf9>
			crt_pos--;
f010042f:	83 e8 01             	sub    $0x1,%eax
f0100432:	66 89 83 a0 1f 00 00 	mov    %ax,0x1fa0(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100440:	b2 00                	mov    $0x0,%dl
f0100442:	83 ca 20             	or     $0x20,%edx
f0100445:	8b 8b a4 1f 00 00    	mov    0x1fa4(%ebx),%ecx
f010044b:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010044f:	eb 88                	jmp    f01003d9 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f0100451:	66 83 83 a0 1f 00 00 	addw   $0x50,0x1fa0(%ebx)
f0100458:	50 
f0100459:	e9 5e ff ff ff       	jmp    f01003bc <cons_putc+0xcd>
		cons_putc(' ');
f010045e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100463:	e8 87 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100468:	b8 20 00 00 00       	mov    $0x20,%eax
f010046d:	e8 7d fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100472:	b8 20 00 00 00       	mov    $0x20,%eax
f0100477:	e8 73 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f010047c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100481:	e8 69 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100486:	b8 20 00 00 00       	mov    $0x20,%eax
f010048b:	e8 5f fe ff ff       	call   f01002ef <cons_putc>
f0100490:	e9 44 ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100495:	0f b7 83 a0 1f 00 00 	movzwl 0x1fa0(%ebx),%eax
f010049c:	8d 50 01             	lea    0x1(%eax),%edx
f010049f:	66 89 93 a0 1f 00 00 	mov    %dx,0x1fa0(%ebx)
f01004a6:	0f b7 c0             	movzwl %ax,%eax
f01004a9:	8b 93 a4 1f 00 00    	mov    0x1fa4(%ebx),%edx
f01004af:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004b3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004b7:	e9 1d ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004bc:	8b 83 a4 1f 00 00    	mov    0x1fa4(%ebx),%eax
f01004c2:	83 ec 04             	sub    $0x4,%esp
f01004c5:	68 00 0f 00 00       	push   $0xf00
f01004ca:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004d0:	52                   	push   %edx
f01004d1:	50                   	push   %eax
f01004d2:	e8 f3 3a 00 00       	call   f0103fca <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004d7:	8b 93 a4 1f 00 00    	mov    0x1fa4(%ebx),%edx
f01004dd:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004e3:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004e9:	83 c4 10             	add    $0x10,%esp
f01004ec:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004f1:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004f4:	39 d0                	cmp    %edx,%eax
f01004f6:	75 f4                	jne    f01004ec <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f01004f8:	66 83 ab a0 1f 00 00 	subw   $0x50,0x1fa0(%ebx)
f01004ff:	50 
f0100500:	e9 e3 fe ff ff       	jmp    f01003e8 <cons_putc+0xf9>

f0100505 <serial_intr>:
{
f0100505:	e8 e7 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f010050a:	05 fe 7d 01 00       	add    $0x17dfe,%eax
	if (serial_exists)
f010050f:	80 b8 ac 1f 00 00 00 	cmpb   $0x0,0x1fac(%eax)
f0100516:	75 02                	jne    f010051a <serial_intr+0x15>
f0100518:	f3 c3                	repz ret 
{
f010051a:	55                   	push   %ebp
f010051b:	89 e5                	mov    %esp,%ebp
f010051d:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100520:	8d 80 4b 7e fe ff    	lea    -0x181b5(%eax),%eax
f0100526:	e8 47 fc ff ff       	call   f0100172 <cons_intr>
}
f010052b:	c9                   	leave  
f010052c:	c3                   	ret    

f010052d <kbd_intr>:
{
f010052d:	55                   	push   %ebp
f010052e:	89 e5                	mov    %esp,%ebp
f0100530:	83 ec 08             	sub    $0x8,%esp
f0100533:	e8 b9 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f0100538:	05 d0 7d 01 00       	add    $0x17dd0,%eax
	cons_intr(kbd_proc_data);
f010053d:	8d 80 b5 7e fe ff    	lea    -0x1814b(%eax),%eax
f0100543:	e8 2a fc ff ff       	call   f0100172 <cons_intr>
}
f0100548:	c9                   	leave  
f0100549:	c3                   	ret    

f010054a <cons_getc>:
{
f010054a:	55                   	push   %ebp
f010054b:	89 e5                	mov    %esp,%ebp
f010054d:	53                   	push   %ebx
f010054e:	83 ec 04             	sub    $0x4,%esp
f0100551:	e8 f9 fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100556:	81 c3 b2 7d 01 00    	add    $0x17db2,%ebx
	serial_intr();
f010055c:	e8 a4 ff ff ff       	call   f0100505 <serial_intr>
	kbd_intr();
f0100561:	e8 c7 ff ff ff       	call   f010052d <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100566:	8b 93 98 1f 00 00    	mov    0x1f98(%ebx),%edx
	return 0;
f010056c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100571:	3b 93 9c 1f 00 00    	cmp    0x1f9c(%ebx),%edx
f0100577:	74 19                	je     f0100592 <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100579:	8d 4a 01             	lea    0x1(%edx),%ecx
f010057c:	89 8b 98 1f 00 00    	mov    %ecx,0x1f98(%ebx)
f0100582:	0f b6 84 13 98 1d 00 	movzbl 0x1d98(%ebx,%edx,1),%eax
f0100589:	00 
		if (cons.rpos == CONSBUFSIZE)
f010058a:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100590:	74 06                	je     f0100598 <cons_getc+0x4e>
}
f0100592:	83 c4 04             	add    $0x4,%esp
f0100595:	5b                   	pop    %ebx
f0100596:	5d                   	pop    %ebp
f0100597:	c3                   	ret    
			cons.rpos = 0;
f0100598:	c7 83 98 1f 00 00 00 	movl   $0x0,0x1f98(%ebx)
f010059f:	00 00 00 
f01005a2:	eb ee                	jmp    f0100592 <cons_getc+0x48>

f01005a4 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005a4:	55                   	push   %ebp
f01005a5:	89 e5                	mov    %esp,%ebp
f01005a7:	57                   	push   %edi
f01005a8:	56                   	push   %esi
f01005a9:	53                   	push   %ebx
f01005aa:	83 ec 1c             	sub    $0x1c,%esp
f01005ad:	e8 9d fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01005b2:	81 c3 56 7d 01 00    	add    $0x17d56,%ebx
	was = *cp;
f01005b8:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01005bf:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005c6:	5a a5 
	if (*cp != 0xA55A) {
f01005c8:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005cf:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005d3:	0f 84 bc 00 00 00    	je     f0100695 <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f01005d9:	c7 83 a8 1f 00 00 b4 	movl   $0x3b4,0x1fa8(%ebx)
f01005e0:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005e3:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f01005ea:	8b bb a8 1f 00 00    	mov    0x1fa8(%ebx),%edi
f01005f0:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005f5:	89 fa                	mov    %edi,%edx
f01005f7:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005f8:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005fb:	89 ca                	mov    %ecx,%edx
f01005fd:	ec                   	in     (%dx),%al
f01005fe:	0f b6 f0             	movzbl %al,%esi
f0100601:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100604:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100609:	89 fa                	mov    %edi,%edx
f010060b:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010060c:	89 ca                	mov    %ecx,%edx
f010060e:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010060f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100612:	89 bb a4 1f 00 00    	mov    %edi,0x1fa4(%ebx)
	pos |= inb(addr_6845 + 1);
f0100618:	0f b6 c0             	movzbl %al,%eax
f010061b:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f010061d:	66 89 b3 a0 1f 00 00 	mov    %si,0x1fa0(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100624:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100629:	89 c8                	mov    %ecx,%eax
f010062b:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100630:	ee                   	out    %al,(%dx)
f0100631:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100636:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010063b:	89 fa                	mov    %edi,%edx
f010063d:	ee                   	out    %al,(%dx)
f010063e:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100643:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100648:	ee                   	out    %al,(%dx)
f0100649:	be f9 03 00 00       	mov    $0x3f9,%esi
f010064e:	89 c8                	mov    %ecx,%eax
f0100650:	89 f2                	mov    %esi,%edx
f0100652:	ee                   	out    %al,(%dx)
f0100653:	b8 03 00 00 00       	mov    $0x3,%eax
f0100658:	89 fa                	mov    %edi,%edx
f010065a:	ee                   	out    %al,(%dx)
f010065b:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100660:	89 c8                	mov    %ecx,%eax
f0100662:	ee                   	out    %al,(%dx)
f0100663:	b8 01 00 00 00       	mov    $0x1,%eax
f0100668:	89 f2                	mov    %esi,%edx
f010066a:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010066b:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100670:	ec                   	in     (%dx),%al
f0100671:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100673:	3c ff                	cmp    $0xff,%al
f0100675:	0f 95 83 ac 1f 00 00 	setne  0x1fac(%ebx)
f010067c:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100681:	ec                   	in     (%dx),%al
f0100682:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100687:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100688:	80 f9 ff             	cmp    $0xff,%cl
f010068b:	74 25                	je     f01006b2 <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f010068d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100690:	5b                   	pop    %ebx
f0100691:	5e                   	pop    %esi
f0100692:	5f                   	pop    %edi
f0100693:	5d                   	pop    %ebp
f0100694:	c3                   	ret    
		*cp = was;
f0100695:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010069c:	c7 83 a8 1f 00 00 d4 	movl   $0x3d4,0x1fa8(%ebx)
f01006a3:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006a6:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006ad:	e9 38 ff ff ff       	jmp    f01005ea <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006b2:	83 ec 0c             	sub    $0xc,%esp
f01006b5:	8d 83 11 c1 fe ff    	lea    -0x13eef(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 08 2b 00 00       	call   f01031c9 <cprintf>
f01006c1:	83 c4 10             	add    $0x10,%esp
}
f01006c4:	eb c7                	jmp    f010068d <cons_init+0xe9>

f01006c6 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006c6:	55                   	push   %ebp
f01006c7:	89 e5                	mov    %esp,%ebp
f01006c9:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01006cf:	e8 1b fc ff ff       	call   f01002ef <cons_putc>
}
f01006d4:	c9                   	leave  
f01006d5:	c3                   	ret    

f01006d6 <getchar>:

int
getchar(void)
{
f01006d6:	55                   	push   %ebp
f01006d7:	89 e5                	mov    %esp,%ebp
f01006d9:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006dc:	e8 69 fe ff ff       	call   f010054a <cons_getc>
f01006e1:	85 c0                	test   %eax,%eax
f01006e3:	74 f7                	je     f01006dc <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006e5:	c9                   	leave  
f01006e6:	c3                   	ret    

f01006e7 <iscons>:

int
iscons(int fdnum)
{
f01006e7:	55                   	push   %ebp
f01006e8:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01006ea:	b8 01 00 00 00       	mov    $0x1,%eax
f01006ef:	5d                   	pop    %ebp
f01006f0:	c3                   	ret    

f01006f1 <__x86.get_pc_thunk.ax>:
f01006f1:	8b 04 24             	mov    (%esp),%eax
f01006f4:	c3                   	ret    

f01006f5 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006f5:	55                   	push   %ebp
f01006f6:	89 e5                	mov    %esp,%ebp
f01006f8:	56                   	push   %esi
f01006f9:	53                   	push   %ebx
f01006fa:	e8 50 fa ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01006ff:	81 c3 09 7c 01 00    	add    $0x17c09,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100705:	83 ec 04             	sub    $0x4,%esp
f0100708:	8d 83 38 c3 fe ff    	lea    -0x13cc8(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 56 c3 fe ff    	lea    -0x13caa(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 5b c3 fe ff    	lea    -0x13ca5(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 a7 2a 00 00       	call   f01031c9 <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 a4 c4 fe ff    	lea    -0x13b5c(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 64 c3 fe ff    	lea    -0x13c9c(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 90 2a 00 00       	call   f01031c9 <cprintf>
f0100739:	83 c4 0c             	add    $0xc,%esp
f010073c:	8d 83 6d c3 fe ff    	lea    -0x13c93(%ebx),%eax
f0100742:	50                   	push   %eax
f0100743:	8d 83 84 c3 fe ff    	lea    -0x13c7c(%ebx),%eax
f0100749:	50                   	push   %eax
f010074a:	56                   	push   %esi
f010074b:	e8 79 2a 00 00       	call   f01031c9 <cprintf>
f0100750:	83 c4 0c             	add    $0xc,%esp
f0100753:	8d 83 8e c3 fe ff    	lea    -0x13c72(%ebx),%eax
f0100759:	50                   	push   %eax
f010075a:	8d 83 9d c3 fe ff    	lea    -0x13c63(%ebx),%eax
f0100760:	50                   	push   %eax
f0100761:	56                   	push   %esi
f0100762:	e8 62 2a 00 00       	call   f01031c9 <cprintf>
	return 0;
}
f0100767:	b8 00 00 00 00       	mov    $0x0,%eax
f010076c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010076f:	5b                   	pop    %ebx
f0100770:	5e                   	pop    %esi
f0100771:	5d                   	pop    %ebp
f0100772:	c3                   	ret    

f0100773 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100773:	55                   	push   %ebp
f0100774:	89 e5                	mov    %esp,%ebp
f0100776:	57                   	push   %edi
f0100777:	56                   	push   %esi
f0100778:	53                   	push   %ebx
f0100779:	83 ec 18             	sub    $0x18,%esp
f010077c:	e8 ce f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100781:	81 c3 87 7b 01 00    	add    $0x17b87,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100787:	8d 83 a2 c3 fe ff    	lea    -0x13c5e(%ebx),%eax
f010078d:	50                   	push   %eax
f010078e:	e8 36 2a 00 00       	call   f01031c9 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100793:	83 c4 08             	add    $0x8,%esp
f0100796:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f010079c:	8d 83 cc c4 fe ff    	lea    -0x13b34(%ebx),%eax
f01007a2:	50                   	push   %eax
f01007a3:	e8 21 2a 00 00       	call   f01031c9 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007a8:	83 c4 0c             	add    $0xc,%esp
f01007ab:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f01007b1:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007b7:	50                   	push   %eax
f01007b8:	57                   	push   %edi
f01007b9:	8d 83 f4 c4 fe ff    	lea    -0x13b0c(%ebx),%eax
f01007bf:	50                   	push   %eax
f01007c0:	e8 04 2a 00 00       	call   f01031c9 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007c5:	83 c4 0c             	add    $0xc,%esp
f01007c8:	c7 c0 b9 43 10 f0    	mov    $0xf01043b9,%eax
f01007ce:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007d4:	52                   	push   %edx
f01007d5:	50                   	push   %eax
f01007d6:	8d 83 18 c5 fe ff    	lea    -0x13ae8(%ebx),%eax
f01007dc:	50                   	push   %eax
f01007dd:	e8 e7 29 00 00       	call   f01031c9 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007e2:	83 c4 0c             	add    $0xc,%esp
f01007e5:	c7 c0 80 a0 11 f0    	mov    $0xf011a080,%eax
f01007eb:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007f1:	52                   	push   %edx
f01007f2:	50                   	push   %eax
f01007f3:	8d 83 3c c5 fe ff    	lea    -0x13ac4(%ebx),%eax
f01007f9:	50                   	push   %eax
f01007fa:	e8 ca 29 00 00       	call   f01031c9 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007ff:	83 c4 0c             	add    $0xc,%esp
f0100802:	c7 c6 c0 a6 11 f0    	mov    $0xf011a6c0,%esi
f0100808:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f010080e:	50                   	push   %eax
f010080f:	56                   	push   %esi
f0100810:	8d 83 60 c5 fe ff    	lea    -0x13aa0(%ebx),%eax
f0100816:	50                   	push   %eax
f0100817:	e8 ad 29 00 00       	call   f01031c9 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010081c:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010081f:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f0100825:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100827:	c1 fe 0a             	sar    $0xa,%esi
f010082a:	56                   	push   %esi
f010082b:	8d 83 84 c5 fe ff    	lea    -0x13a7c(%ebx),%eax
f0100831:	50                   	push   %eax
f0100832:	e8 92 29 00 00       	call   f01031c9 <cprintf>
	return 0;
}
f0100837:	b8 00 00 00 00       	mov    $0x0,%eax
f010083c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010083f:	5b                   	pop    %ebx
f0100840:	5e                   	pop    %esi
f0100841:	5f                   	pop    %edi
f0100842:	5d                   	pop    %ebp
f0100843:	c3                   	ret    

f0100844 <mon_time>:
mon_time(int argc, char **argv, struct Trapframe *tf) {
f0100844:	55                   	push   %ebp
f0100845:	89 e5                	mov    %esp,%ebp
f0100847:	57                   	push   %edi
f0100848:	56                   	push   %esi
f0100849:	53                   	push   %ebx
f010084a:	83 ec 1c             	sub    $0x1c,%esp
f010084d:	e8 fd f8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100852:	81 c3 b6 7a 01 00    	add    $0x17ab6,%ebx
	if (argc != 2)
f0100858:	83 7d 08 02          	cmpl   $0x2,0x8(%ebp)
f010085c:	0f 85 8f 00 00 00    	jne    f01008f1 <mon_time+0xad>
f0100862:	8d bb 18 1d 00 00    	lea    0x1d18(%ebx),%edi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100868:	be 00 00 00 00       	mov    $0x0,%esi
		if (strcmp(commands[i].name, argv[1]) == 0) {
f010086d:	83 ec 08             	sub    $0x8,%esp
f0100870:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100873:	ff 70 04             	pushl  0x4(%eax)
f0100876:	ff 37                	pushl  (%edi)
f0100878:	e8 65 36 00 00       	call   f0103ee2 <strcmp>
f010087d:	83 c4 10             	add    $0x10,%esp
f0100880:	85 c0                	test   %eax,%eax
f0100882:	74 14                	je     f0100898 <mon_time+0x54>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100884:	83 c6 01             	add    $0x1,%esi
f0100887:	83 c7 0c             	add    $0xc,%edi
f010088a:	83 fe 04             	cmp    $0x4,%esi
f010088d:	75 de                	jne    f010086d <mon_time+0x29>
        return -1;
f010088f:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100896:	eb 4e                	jmp    f01008e6 <mon_time+0xa2>
f0100898:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (i == ARRAY_SIZE(commands))
f010089b:	83 fe 04             	cmp    $0x4,%esi
f010089e:	74 5a                	je     f01008fa <mon_time+0xb6>

static inline uint64_t
read_tsc(void)
{
	uint64_t tsc;
	asm volatile("rdtsc" : "=A" (tsc));
f01008a0:	0f 31                	rdtsc  
f01008a2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01008a5:	89 55 dc             	mov    %edx,-0x24(%ebp)
	(commands[i].func)(1, argv+1, tf);
f01008a8:	83 ec 04             	sub    $0x4,%esp
f01008ab:	8d 3c 36             	lea    (%esi,%esi,1),%edi
f01008ae:	8d 14 37             	lea    (%edi,%esi,1),%edx
f01008b1:	ff 75 10             	pushl  0x10(%ebp)
f01008b4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01008b7:	8d 41 04             	lea    0x4(%ecx),%eax
f01008ba:	50                   	push   %eax
f01008bb:	6a 01                	push   $0x1
f01008bd:	ff 94 93 20 1d 00 00 	call   *0x1d20(%ebx,%edx,4)
f01008c4:	0f 31                	rdtsc  
	cprintf("%s cycles: %d\n", commands[i].name, after - before);
f01008c6:	2b 45 d8             	sub    -0x28(%ebp),%eax
f01008c9:	1b 55 dc             	sbb    -0x24(%ebp),%edx
f01008cc:	52                   	push   %edx
f01008cd:	50                   	push   %eax
f01008ce:	01 fe                	add    %edi,%esi
f01008d0:	ff b4 b3 18 1d 00 00 	pushl  0x1d18(%ebx,%esi,4)
f01008d7:	8d 83 bb c3 fe ff    	lea    -0x13c45(%ebx),%eax
f01008dd:	50                   	push   %eax
f01008de:	e8 e6 28 00 00       	call   f01031c9 <cprintf>
	return 0;
f01008e3:	83 c4 20             	add    $0x20,%esp
}
f01008e6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01008e9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008ec:	5b                   	pop    %ebx
f01008ed:	5e                   	pop    %esi
f01008ee:	5f                   	pop    %edi
f01008ef:	5d                   	pop    %ebp
f01008f0:	c3                   	ret    
		return -1;
f01008f1:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f01008f8:	eb ec                	jmp    f01008e6 <mon_time+0xa2>
        return -1;
f01008fa:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100901:	eb e3                	jmp    f01008e6 <mon_time+0xa2>

f0100903 <do_overflow>:
    return pretaddr;
}

void
do_overflow(void)
{
f0100903:	55                   	push   %ebp
f0100904:	89 e5                	mov    %esp,%ebp
f0100906:	53                   	push   %ebx
f0100907:	83 ec 10             	sub    $0x10,%esp
f010090a:	e8 40 f8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010090f:	81 c3 f9 79 01 00    	add    $0x179f9,%ebx
    cprintf("Overflow success\n");
f0100915:	8d 83 ca c3 fe ff    	lea    -0x13c36(%ebx),%eax
f010091b:	50                   	push   %eax
f010091c:	e8 a8 28 00 00       	call   f01031c9 <cprintf>
}
f0100921:	83 c4 10             	add    $0x10,%esp
f0100924:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100927:	c9                   	leave  
f0100928:	c3                   	ret    

f0100929 <start_overflow>:

void
start_overflow(void)
{
f0100929:	55                   	push   %ebp
f010092a:	89 e5                	mov    %esp,%ebp
f010092c:	56                   	push   %esi
f010092d:	53                   	push   %ebx
f010092e:	e8 1c f8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100933:	81 c3 d5 79 01 00    	add    $0x179d5,%ebx
    __asm __volatile("leal 4(%%ebp), %0" : "=r" (pretaddr)); 
f0100939:	8d 75 04             	lea    0x4(%ebp),%esi

	// Your code here.
    pret_addr = (char*)read_pretaddr();	// 读取eip所在的地址
    
    // 原本的ret addr：0xf0100ba8(overflow_me)
    cprintf("old rip: %lx\n", *(uint32_t*)pret_addr);	
f010093c:	83 ec 08             	sub    $0x8,%esp
f010093f:	ff 36                	pushl  (%esi)
f0100941:	8d 83 dc c3 fe ff    	lea    -0x13c24(%ebx),%eax
f0100947:	50                   	push   %eax
f0100948:	e8 7c 28 00 00       	call   f01031c9 <cprintf>
    cprintf("%52d%n\n",nstr, pret_addr);	// 更改 0xa8 -> 0x34
f010094d:	83 c4 0c             	add    $0xc,%esp
f0100950:	56                   	push   %esi
f0100951:	6a 00                	push   $0x0
f0100953:	8d 83 ea c3 fe ff    	lea    -0x13c16(%ebx),%eax
f0100959:	50                   	push   %eax
f010095a:	e8 6a 28 00 00       	call   f01031c9 <cprintf>
    cprintf("%10d%n\n",nstr, pret_addr+1);	// 更改 0x0b -> 0x0a 
f010095f:	83 c4 0c             	add    $0xc,%esp
f0100962:	8d 46 01             	lea    0x1(%esi),%eax
f0100965:	50                   	push   %eax
f0100966:	6a 00                	push   $0x0
f0100968:	8d 83 f2 c3 fe ff    	lea    -0x13c0e(%ebx),%eax
f010096e:	50                   	push   %eax
f010096f:	e8 55 28 00 00       	call   f01031c9 <cprintf>
    // 新的ret addr: 0xf0100a34(do_overflow)
    cprintf("new rip: %lx\n", *(uint32_t*)pret_addr);	
f0100974:	83 c4 08             	add    $0x8,%esp
f0100977:	ff 36                	pushl  (%esi)
f0100979:	8d 83 fa c3 fe ff    	lea    -0x13c06(%ebx),%eax
f010097f:	50                   	push   %eax
f0100980:	e8 44 28 00 00       	call   f01031c9 <cprintf>

    //	在8(%ebp)处填入原本的ret addr，这样do_overflow才能正常return
    cprintf("%168d%n\n",nstr, pret_addr+4);	// 填入0xa8
f0100985:	83 c4 0c             	add    $0xc,%esp
f0100988:	8d 46 04             	lea    0x4(%esi),%eax
f010098b:	50                   	push   %eax
f010098c:	6a 00                	push   $0x0
f010098e:	8d 83 08 c4 fe ff    	lea    -0x13bf8(%ebx),%eax
f0100994:	50                   	push   %eax
f0100995:	e8 2f 28 00 00       	call   f01031c9 <cprintf>
    cprintf("%11d%n\n", nstr, pret_addr+5);	// 填入0x0b
f010099a:	83 c4 0c             	add    $0xc,%esp
f010099d:	8d 46 05             	lea    0x5(%esi),%eax
f01009a0:	50                   	push   %eax
f01009a1:	6a 00                	push   $0x0
f01009a3:	8d 83 11 c4 fe ff    	lea    -0x13bef(%ebx),%eax
f01009a9:	50                   	push   %eax
f01009aa:	e8 1a 28 00 00       	call   f01031c9 <cprintf>
    cprintf("%16d%n\n",nstr, pret_addr+6);	// 填入0x10
f01009af:	83 c4 0c             	add    $0xc,%esp
f01009b2:	8d 46 06             	lea    0x6(%esi),%eax
f01009b5:	50                   	push   %eax
f01009b6:	6a 00                	push   $0x0
f01009b8:	8d 83 19 c4 fe ff    	lea    -0x13be7(%ebx),%eax
f01009be:	50                   	push   %eax
f01009bf:	e8 05 28 00 00       	call   f01031c9 <cprintf>
    cprintf("%240d%n\n",nstr, pret_addr+7);	// 填入0xf0
f01009c4:	83 c4 0c             	add    $0xc,%esp
f01009c7:	83 c6 07             	add    $0x7,%esi
f01009ca:	56                   	push   %esi
f01009cb:	6a 00                	push   $0x0
f01009cd:	8d 83 21 c4 fe ff    	lea    -0x13bdf(%ebx),%eax
f01009d3:	50                   	push   %eax
f01009d4:	e8 f0 27 00 00       	call   f01031c9 <cprintf>
}
f01009d9:	83 c4 10             	add    $0x10,%esp
f01009dc:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01009df:	5b                   	pop    %ebx
f01009e0:	5e                   	pop    %esi
f01009e1:	5d                   	pop    %ebp
f01009e2:	c3                   	ret    

f01009e3 <mon_backtrace>:
        start_overflow();
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01009e3:	55                   	push   %ebp
f01009e4:	89 e5                	mov    %esp,%ebp
f01009e6:	57                   	push   %edi
f01009e7:	56                   	push   %esi
f01009e8:	53                   	push   %ebx
f01009e9:	83 ec 48             	sub    $0x48,%esp
f01009ec:	e8 5e f7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01009f1:	81 c3 17 79 01 00    	add    $0x17917,%ebx
	// Your code here.
	cprintf("Stack backtrace:\n");
f01009f7:	8d 83 2a c4 fe ff    	lea    -0x13bd6(%ebx),%eax
f01009fd:	50                   	push   %eax
f01009fe:	e8 c6 27 00 00       	call   f01031c9 <cprintf>
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100a03:	89 ee                	mov    %ebp,%esi
	uint32_t ebp = read_ebp();
	// 读取%ebp寄存器中的值，%ebp指向当前帧，（%ebp）指向上一帧
	while(ebp != 0){	// %ebp为0时函数遍历到最外层，backtrace到达终点
f0100a05:	83 c4 10             	add    $0x10,%esp
		uint32_t eip = *(int*)(ebp + 4);	// 读取(4(%ebp))，即%eip的值
		cprintf("  eip %08x  ebp %08x  args %08x %08x %08x %08x %08x\n",
f0100a08:	8d 83 b0 c5 fe ff    	lea    -0x13a50(%ebx),%eax
f0100a0e:	89 45 c4             	mov    %eax,-0x3c(%ebp)
			eip, ebp,
			*(int*)(ebp+8),*(int*)(ebp+12),*(int*)(ebp+16),*(int*)(ebp+20),*(int*)(ebp+24));
		struct Eipdebuginfo info;
		if(debuginfo_eip(eip,&info) == 0){	// 查找%eip对应函数的相关信息
f0100a11:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100a14:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while(ebp != 0){	// %ebp为0时函数遍历到最外层，backtrace到达终点
f0100a17:	eb 02                	jmp    f0100a1b <mon_backtrace+0x38>
			cprintf("         %s:%d %.*s+%d\n",
				info.eip_file, info.eip_line,
				info.eip_fn_namelen, info.eip_fn_name, eip-info.eip_fn_addr);
		}
		ebp = *(int*)ebp;	// 更新ebp，下一轮循环将输出外一层函数的相关信息
f0100a19:	8b 36                	mov    (%esi),%esi
	while(ebp != 0){	// %ebp为0时函数遍历到最外层，backtrace到达终点
f0100a1b:	85 f6                	test   %esi,%esi
f0100a1d:	74 53                	je     f0100a72 <mon_backtrace+0x8f>
		uint32_t eip = *(int*)(ebp + 4);	// 读取(4(%ebp))，即%eip的值
f0100a1f:	8b 7e 04             	mov    0x4(%esi),%edi
		cprintf("  eip %08x  ebp %08x  args %08x %08x %08x %08x %08x\n",
f0100a22:	ff 76 18             	pushl  0x18(%esi)
f0100a25:	ff 76 14             	pushl  0x14(%esi)
f0100a28:	ff 76 10             	pushl  0x10(%esi)
f0100a2b:	ff 76 0c             	pushl  0xc(%esi)
f0100a2e:	ff 76 08             	pushl  0x8(%esi)
f0100a31:	56                   	push   %esi
f0100a32:	57                   	push   %edi
f0100a33:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100a36:	e8 8e 27 00 00       	call   f01031c9 <cprintf>
		if(debuginfo_eip(eip,&info) == 0){	// 查找%eip对应函数的相关信息
f0100a3b:	83 c4 18             	add    $0x18,%esp
f0100a3e:	ff 75 c0             	pushl  -0x40(%ebp)
f0100a41:	57                   	push   %edi
f0100a42:	e8 86 28 00 00       	call   f01032cd <debuginfo_eip>
f0100a47:	83 c4 10             	add    $0x10,%esp
f0100a4a:	85 c0                	test   %eax,%eax
f0100a4c:	75 cb                	jne    f0100a19 <mon_backtrace+0x36>
			cprintf("         %s:%d %.*s+%d\n",
f0100a4e:	83 ec 08             	sub    $0x8,%esp
f0100a51:	2b 7d e0             	sub    -0x20(%ebp),%edi
f0100a54:	57                   	push   %edi
f0100a55:	ff 75 d8             	pushl  -0x28(%ebp)
f0100a58:	ff 75 dc             	pushl  -0x24(%ebp)
f0100a5b:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100a5e:	ff 75 d0             	pushl  -0x30(%ebp)
f0100a61:	8d 83 3c c4 fe ff    	lea    -0x13bc4(%ebx),%eax
f0100a67:	50                   	push   %eax
f0100a68:	e8 5c 27 00 00       	call   f01031c9 <cprintf>
f0100a6d:	83 c4 20             	add    $0x20,%esp
f0100a70:	eb a7                	jmp    f0100a19 <mon_backtrace+0x36>
        start_overflow();
f0100a72:	e8 b2 fe ff ff       	call   f0100929 <start_overflow>
	}
	overflow_me();
    	cprintf("Backtrace success\n");
f0100a77:	83 ec 0c             	sub    $0xc,%esp
f0100a7a:	8d 83 54 c4 fe ff    	lea    -0x13bac(%ebx),%eax
f0100a80:	50                   	push   %eax
f0100a81:	e8 43 27 00 00       	call   f01031c9 <cprintf>
	return 0;
}
f0100a86:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a8b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a8e:	5b                   	pop    %ebx
f0100a8f:	5e                   	pop    %esi
f0100a90:	5f                   	pop    %edi
f0100a91:	5d                   	pop    %ebp
f0100a92:	c3                   	ret    

f0100a93 <overflow_me>:
{
f0100a93:	55                   	push   %ebp
f0100a94:	89 e5                	mov    %esp,%ebp
f0100a96:	83 ec 08             	sub    $0x8,%esp
        start_overflow();
f0100a99:	e8 8b fe ff ff       	call   f0100929 <start_overflow>
}
f0100a9e:	c9                   	leave  
f0100a9f:	c3                   	ret    

f0100aa0 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100aa0:	55                   	push   %ebp
f0100aa1:	89 e5                	mov    %esp,%ebp
f0100aa3:	57                   	push   %edi
f0100aa4:	56                   	push   %esi
f0100aa5:	53                   	push   %ebx
f0100aa6:	83 ec 68             	sub    $0x68,%esp
f0100aa9:	e8 a1 f6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100aae:	81 c3 5a 78 01 00    	add    $0x1785a,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100ab4:	8d 83 e8 c5 fe ff    	lea    -0x13a18(%ebx),%eax
f0100aba:	50                   	push   %eax
f0100abb:	e8 09 27 00 00       	call   f01031c9 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100ac0:	8d 83 0c c6 fe ff    	lea    -0x139f4(%ebx),%eax
f0100ac6:	89 04 24             	mov    %eax,(%esp)
f0100ac9:	e8 fb 26 00 00       	call   f01031c9 <cprintf>
f0100ace:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100ad1:	8d bb 6b c4 fe ff    	lea    -0x13b95(%ebx),%edi
f0100ad7:	eb 4a                	jmp    f0100b23 <monitor+0x83>
f0100ad9:	83 ec 08             	sub    $0x8,%esp
f0100adc:	0f be c0             	movsbl %al,%eax
f0100adf:	50                   	push   %eax
f0100ae0:	57                   	push   %edi
f0100ae1:	e8 5a 34 00 00       	call   f0103f40 <strchr>
f0100ae6:	83 c4 10             	add    $0x10,%esp
f0100ae9:	85 c0                	test   %eax,%eax
f0100aeb:	74 08                	je     f0100af5 <monitor+0x55>
			*buf++ = 0;
f0100aed:	c6 06 00             	movb   $0x0,(%esi)
f0100af0:	8d 76 01             	lea    0x1(%esi),%esi
f0100af3:	eb 79                	jmp    f0100b6e <monitor+0xce>
		if (*buf == 0)
f0100af5:	80 3e 00             	cmpb   $0x0,(%esi)
f0100af8:	74 7f                	je     f0100b79 <monitor+0xd9>
		if (argc == MAXARGS-1) {
f0100afa:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f0100afe:	74 0f                	je     f0100b0f <monitor+0x6f>
		argv[argc++] = buf;
f0100b00:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100b03:	8d 48 01             	lea    0x1(%eax),%ecx
f0100b06:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f0100b09:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f0100b0d:	eb 44                	jmp    f0100b53 <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100b0f:	83 ec 08             	sub    $0x8,%esp
f0100b12:	6a 10                	push   $0x10
f0100b14:	8d 83 70 c4 fe ff    	lea    -0x13b90(%ebx),%eax
f0100b1a:	50                   	push   %eax
f0100b1b:	e8 a9 26 00 00       	call   f01031c9 <cprintf>
f0100b20:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100b23:	8d 83 67 c4 fe ff    	lea    -0x13b99(%ebx),%eax
f0100b29:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100b2c:	83 ec 0c             	sub    $0xc,%esp
f0100b2f:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100b32:	e8 d1 31 00 00       	call   f0103d08 <readline>
f0100b37:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100b39:	83 c4 10             	add    $0x10,%esp
f0100b3c:	85 c0                	test   %eax,%eax
f0100b3e:	74 ec                	je     f0100b2c <monitor+0x8c>
	argv[argc] = 0;
f0100b40:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100b47:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f0100b4e:	eb 1e                	jmp    f0100b6e <monitor+0xce>
			buf++;
f0100b50:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100b53:	0f b6 06             	movzbl (%esi),%eax
f0100b56:	84 c0                	test   %al,%al
f0100b58:	74 14                	je     f0100b6e <monitor+0xce>
f0100b5a:	83 ec 08             	sub    $0x8,%esp
f0100b5d:	0f be c0             	movsbl %al,%eax
f0100b60:	50                   	push   %eax
f0100b61:	57                   	push   %edi
f0100b62:	e8 d9 33 00 00       	call   f0103f40 <strchr>
f0100b67:	83 c4 10             	add    $0x10,%esp
f0100b6a:	85 c0                	test   %eax,%eax
f0100b6c:	74 e2                	je     f0100b50 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f0100b6e:	0f b6 06             	movzbl (%esi),%eax
f0100b71:	84 c0                	test   %al,%al
f0100b73:	0f 85 60 ff ff ff    	jne    f0100ad9 <monitor+0x39>
	argv[argc] = 0;
f0100b79:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100b7c:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100b83:	00 
	if (argc == 0)
f0100b84:	85 c0                	test   %eax,%eax
f0100b86:	74 9b                	je     f0100b23 <monitor+0x83>
f0100b88:	8d b3 18 1d 00 00    	lea    0x1d18(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100b8e:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		if (strcmp(argv[0], commands[i].name) == 0)
f0100b95:	83 ec 08             	sub    $0x8,%esp
f0100b98:	ff 36                	pushl  (%esi)
f0100b9a:	ff 75 a8             	pushl  -0x58(%ebp)
f0100b9d:	e8 40 33 00 00       	call   f0103ee2 <strcmp>
f0100ba2:	83 c4 10             	add    $0x10,%esp
f0100ba5:	85 c0                	test   %eax,%eax
f0100ba7:	74 29                	je     f0100bd2 <monitor+0x132>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100ba9:	83 45 a0 01          	addl   $0x1,-0x60(%ebp)
f0100bad:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100bb0:	83 c6 0c             	add    $0xc,%esi
f0100bb3:	83 f8 04             	cmp    $0x4,%eax
f0100bb6:	75 dd                	jne    f0100b95 <monitor+0xf5>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100bb8:	83 ec 08             	sub    $0x8,%esp
f0100bbb:	ff 75 a8             	pushl  -0x58(%ebp)
f0100bbe:	8d 83 8d c4 fe ff    	lea    -0x13b73(%ebx),%eax
f0100bc4:	50                   	push   %eax
f0100bc5:	e8 ff 25 00 00       	call   f01031c9 <cprintf>
f0100bca:	83 c4 10             	add    $0x10,%esp
f0100bcd:	e9 51 ff ff ff       	jmp    f0100b23 <monitor+0x83>
			return commands[i].func(argc, argv, tf);
f0100bd2:	83 ec 04             	sub    $0x4,%esp
f0100bd5:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100bd8:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100bdb:	ff 75 08             	pushl  0x8(%ebp)
f0100bde:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100be1:	52                   	push   %edx
f0100be2:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100be5:	ff 94 83 20 1d 00 00 	call   *0x1d20(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100bec:	83 c4 10             	add    $0x10,%esp
f0100bef:	85 c0                	test   %eax,%eax
f0100bf1:	0f 89 2c ff ff ff    	jns    f0100b23 <monitor+0x83>
				break;
	}
f0100bf7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100bfa:	5b                   	pop    %ebx
f0100bfb:	5e                   	pop    %esi
f0100bfc:	5f                   	pop    %edi
f0100bfd:	5d                   	pop    %ebp
f0100bfe:	c3                   	ret    

f0100bff <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100bff:	55                   	push   %ebp
f0100c00:	89 e5                	mov    %esp,%ebp
f0100c02:	53                   	push   %ebx
f0100c03:	e8 25 25 00 00       	call   f010312d <__x86.get_pc_thunk.dx>
f0100c08:	81 c2 00 77 01 00    	add    $0x17700,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100c0e:	83 ba b0 1f 00 00 00 	cmpl   $0x0,0x1fb0(%edx)
f0100c15:	74 1e                	je     f0100c35 <boot_alloc+0x36>
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100c17:	8b 9a b0 1f 00 00    	mov    0x1fb0(%edx),%ebx
	nextfree = ROUNDUP(result + n, PGSIZE);
f0100c1d:	8d 8c 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%ecx
f0100c24:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100c2a:	89 8a b0 1f 00 00    	mov    %ecx,0x1fb0(%edx)

	return result;
}
f0100c30:	89 d8                	mov    %ebx,%eax
f0100c32:	5b                   	pop    %ebx
f0100c33:	5d                   	pop    %ebp
f0100c34:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100c35:	c7 c1 c0 a6 11 f0    	mov    $0xf011a6c0,%ecx
f0100c3b:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100c41:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100c47:	89 8a b0 1f 00 00    	mov    %ecx,0x1fb0(%edx)
f0100c4d:	eb c8                	jmp    f0100c17 <boot_alloc+0x18>

f0100c4f <nvram_read>:
{
f0100c4f:	55                   	push   %ebp
f0100c50:	89 e5                	mov    %esp,%ebp
f0100c52:	57                   	push   %edi
f0100c53:	56                   	push   %esi
f0100c54:	53                   	push   %ebx
f0100c55:	83 ec 18             	sub    $0x18,%esp
f0100c58:	e8 f2 f4 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100c5d:	81 c3 ab 76 01 00    	add    $0x176ab,%ebx
f0100c63:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100c65:	50                   	push   %eax
f0100c66:	e8 ce 24 00 00       	call   f0103139 <mc146818_read>
f0100c6b:	89 c6                	mov    %eax,%esi
f0100c6d:	83 c7 01             	add    $0x1,%edi
f0100c70:	89 3c 24             	mov    %edi,(%esp)
f0100c73:	e8 c1 24 00 00       	call   f0103139 <mc146818_read>
f0100c78:	c1 e0 08             	shl    $0x8,%eax
f0100c7b:	09 f0                	or     %esi,%eax
}
f0100c7d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c80:	5b                   	pop    %ebx
f0100c81:	5e                   	pop    %esi
f0100c82:	5f                   	pop    %edi
f0100c83:	5d                   	pop    %ebp
f0100c84:	c3                   	ret    

f0100c85 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100c85:	55                   	push   %ebp
f0100c86:	89 e5                	mov    %esp,%ebp
f0100c88:	56                   	push   %esi
f0100c89:	53                   	push   %ebx
f0100c8a:	e8 a2 24 00 00       	call   f0103131 <__x86.get_pc_thunk.cx>
f0100c8f:	81 c1 79 76 01 00    	add    $0x17679,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100c95:	89 d3                	mov    %edx,%ebx
f0100c97:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100c9a:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100c9d:	a8 01                	test   $0x1,%al
f0100c9f:	74 5a                	je     f0100cfb <check_va2pa+0x76>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100ca1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ca6:	89 c6                	mov    %eax,%esi
f0100ca8:	c1 ee 0c             	shr    $0xc,%esi
f0100cab:	c7 c3 c8 a6 11 f0    	mov    $0xf011a6c8,%ebx
f0100cb1:	3b 33                	cmp    (%ebx),%esi
f0100cb3:	73 2b                	jae    f0100ce0 <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100cb5:	c1 ea 0c             	shr    $0xc,%edx
f0100cb8:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100cbe:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100cc5:	89 c2                	mov    %eax,%edx
f0100cc7:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100cca:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ccf:	85 d2                	test   %edx,%edx
f0100cd1:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100cd6:	0f 44 c2             	cmove  %edx,%eax
}
f0100cd9:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100cdc:	5b                   	pop    %ebx
f0100cdd:	5e                   	pop    %esi
f0100cde:	5d                   	pop    %ebp
f0100cdf:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ce0:	50                   	push   %eax
f0100ce1:	8d 81 34 c6 fe ff    	lea    -0x139cc(%ecx),%eax
f0100ce7:	50                   	push   %eax
f0100ce8:	68 01 03 00 00       	push   $0x301
f0100ced:	8d 81 0d ce fe ff    	lea    -0x131f3(%ecx),%eax
f0100cf3:	50                   	push   %eax
f0100cf4:	89 cb                	mov    %ecx,%ebx
f0100cf6:	e8 9e f3 ff ff       	call   f0100099 <_panic>
		return ~0;
f0100cfb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d00:	eb d7                	jmp    f0100cd9 <check_va2pa+0x54>

f0100d02 <check_page_free_list>:
{
f0100d02:	55                   	push   %ebp
f0100d03:	89 e5                	mov    %esp,%ebp
f0100d05:	57                   	push   %edi
f0100d06:	56                   	push   %esi
f0100d07:	53                   	push   %ebx
f0100d08:	83 ec 3c             	sub    $0x3c,%esp
f0100d0b:	e8 25 24 00 00       	call   f0103135 <__x86.get_pc_thunk.di>
f0100d10:	81 c7 f8 75 01 00    	add    $0x175f8,%edi
f0100d16:	89 7d c4             	mov    %edi,-0x3c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d19:	84 c0                	test   %al,%al
f0100d1b:	0f 85 dd 02 00 00    	jne    f0100ffe <check_page_free_list+0x2fc>
	if (!page_free_list)
f0100d21:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100d24:	83 b8 b4 1f 00 00 00 	cmpl   $0x0,0x1fb4(%eax)
f0100d2b:	74 0c                	je     f0100d39 <check_page_free_list+0x37>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d2d:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
f0100d34:	e9 2f 03 00 00       	jmp    f0101068 <check_page_free_list+0x366>
		panic("'page_free_list' is a null pointer!");
f0100d39:	83 ec 04             	sub    $0x4,%esp
f0100d3c:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d3f:	8d 83 58 c6 fe ff    	lea    -0x139a8(%ebx),%eax
f0100d45:	50                   	push   %eax
f0100d46:	68 3b 02 00 00       	push   $0x23b
f0100d4b:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0100d51:	50                   	push   %eax
f0100d52:	e8 42 f3 ff ff       	call   f0100099 <_panic>
f0100d57:	50                   	push   %eax
f0100d58:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d5b:	8d 83 34 c6 fe ff    	lea    -0x139cc(%ebx),%eax
f0100d61:	50                   	push   %eax
f0100d62:	6a 52                	push   $0x52
f0100d64:	8d 83 19 ce fe ff    	lea    -0x131e7(%ebx),%eax
f0100d6a:	50                   	push   %eax
f0100d6b:	e8 29 f3 ff ff       	call   f0100099 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d70:	8b 36                	mov    (%esi),%esi
f0100d72:	85 f6                	test   %esi,%esi
f0100d74:	74 40                	je     f0100db6 <check_page_free_list+0xb4>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d76:	89 f0                	mov    %esi,%eax
f0100d78:	2b 07                	sub    (%edi),%eax
f0100d7a:	c1 f8 03             	sar    $0x3,%eax
f0100d7d:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100d80:	89 c2                	mov    %eax,%edx
f0100d82:	c1 ea 16             	shr    $0x16,%edx
f0100d85:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100d88:	73 e6                	jae    f0100d70 <check_page_free_list+0x6e>
	if (PGNUM(pa) >= npages)
f0100d8a:	89 c2                	mov    %eax,%edx
f0100d8c:	c1 ea 0c             	shr    $0xc,%edx
f0100d8f:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100d92:	3b 11                	cmp    (%ecx),%edx
f0100d94:	73 c1                	jae    f0100d57 <check_page_free_list+0x55>
			memset(page2kva(pp), 0x97, 128);
f0100d96:	83 ec 04             	sub    $0x4,%esp
f0100d99:	68 80 00 00 00       	push   $0x80
f0100d9e:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100da3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100da8:	50                   	push   %eax
f0100da9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100dac:	e8 cc 31 00 00       	call   f0103f7d <memset>
f0100db1:	83 c4 10             	add    $0x10,%esp
f0100db4:	eb ba                	jmp    f0100d70 <check_page_free_list+0x6e>
	first_free_page = (char *) boot_alloc(0);
f0100db6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dbb:	e8 3f fe ff ff       	call   f0100bff <boot_alloc>
f0100dc0:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100dc3:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100dc6:	8b 97 b4 1f 00 00    	mov    0x1fb4(%edi),%edx
		assert(pp >= pages);
f0100dcc:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0100dd2:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100dd4:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f0100dda:	8b 00                	mov    (%eax),%eax
f0100ddc:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100ddf:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100de2:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100de5:	bf 00 00 00 00       	mov    $0x0,%edi
f0100dea:	89 75 d0             	mov    %esi,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ded:	e9 08 01 00 00       	jmp    f0100efa <check_page_free_list+0x1f8>
		assert(pp >= pages);
f0100df2:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100df5:	8d 83 27 ce fe ff    	lea    -0x131d9(%ebx),%eax
f0100dfb:	50                   	push   %eax
f0100dfc:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0100e02:	50                   	push   %eax
f0100e03:	68 55 02 00 00       	push   $0x255
f0100e08:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0100e0e:	50                   	push   %eax
f0100e0f:	e8 85 f2 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100e14:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e17:	8d 83 48 ce fe ff    	lea    -0x131b8(%ebx),%eax
f0100e1d:	50                   	push   %eax
f0100e1e:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0100e24:	50                   	push   %eax
f0100e25:	68 56 02 00 00       	push   $0x256
f0100e2a:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0100e30:	50                   	push   %eax
f0100e31:	e8 63 f2 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e36:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e39:	8d 83 7c c6 fe ff    	lea    -0x13984(%ebx),%eax
f0100e3f:	50                   	push   %eax
f0100e40:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0100e46:	50                   	push   %eax
f0100e47:	68 57 02 00 00       	push   $0x257
f0100e4c:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0100e52:	50                   	push   %eax
f0100e53:	e8 41 f2 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100e58:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e5b:	8d 83 5c ce fe ff    	lea    -0x131a4(%ebx),%eax
f0100e61:	50                   	push   %eax
f0100e62:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0100e68:	50                   	push   %eax
f0100e69:	68 5a 02 00 00       	push   $0x25a
f0100e6e:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0100e74:	50                   	push   %eax
f0100e75:	e8 1f f2 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e7a:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e7d:	8d 83 6d ce fe ff    	lea    -0x13193(%ebx),%eax
f0100e83:	50                   	push   %eax
f0100e84:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0100e8a:	50                   	push   %eax
f0100e8b:	68 5b 02 00 00       	push   $0x25b
f0100e90:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0100e96:	50                   	push   %eax
f0100e97:	e8 fd f1 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100e9c:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e9f:	8d 83 b0 c6 fe ff    	lea    -0x13950(%ebx),%eax
f0100ea5:	50                   	push   %eax
f0100ea6:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0100eac:	50                   	push   %eax
f0100ead:	68 5c 02 00 00       	push   $0x25c
f0100eb2:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0100eb8:	50                   	push   %eax
f0100eb9:	e8 db f1 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100ebe:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ec1:	8d 83 86 ce fe ff    	lea    -0x1317a(%ebx),%eax
f0100ec7:	50                   	push   %eax
f0100ec8:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0100ece:	50                   	push   %eax
f0100ecf:	68 5d 02 00 00       	push   $0x25d
f0100ed4:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0100eda:	50                   	push   %eax
f0100edb:	e8 b9 f1 ff ff       	call   f0100099 <_panic>
	if (PGNUM(pa) >= npages)
f0100ee0:	89 c6                	mov    %eax,%esi
f0100ee2:	c1 ee 0c             	shr    $0xc,%esi
f0100ee5:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0100ee8:	76 70                	jbe    f0100f5a <check_page_free_list+0x258>
	return (void *)(pa + KERNBASE);
f0100eea:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100eef:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100ef2:	77 7f                	ja     f0100f73 <check_page_free_list+0x271>
			++nfree_extmem;
f0100ef4:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ef8:	8b 12                	mov    (%edx),%edx
f0100efa:	85 d2                	test   %edx,%edx
f0100efc:	0f 84 93 00 00 00    	je     f0100f95 <check_page_free_list+0x293>
		assert(pp >= pages);
f0100f02:	39 d1                	cmp    %edx,%ecx
f0100f04:	0f 87 e8 fe ff ff    	ja     f0100df2 <check_page_free_list+0xf0>
		assert(pp < pages + npages);
f0100f0a:	39 d3                	cmp    %edx,%ebx
f0100f0c:	0f 86 02 ff ff ff    	jbe    f0100e14 <check_page_free_list+0x112>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100f12:	89 d0                	mov    %edx,%eax
f0100f14:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100f17:	a8 07                	test   $0x7,%al
f0100f19:	0f 85 17 ff ff ff    	jne    f0100e36 <check_page_free_list+0x134>
	return (pp - pages) << PGSHIFT;
f0100f1f:	c1 f8 03             	sar    $0x3,%eax
f0100f22:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100f25:	85 c0                	test   %eax,%eax
f0100f27:	0f 84 2b ff ff ff    	je     f0100e58 <check_page_free_list+0x156>
		assert(page2pa(pp) != IOPHYSMEM);
f0100f2d:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100f32:	0f 84 42 ff ff ff    	je     f0100e7a <check_page_free_list+0x178>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100f38:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100f3d:	0f 84 59 ff ff ff    	je     f0100e9c <check_page_free_list+0x19a>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100f43:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100f48:	0f 84 70 ff ff ff    	je     f0100ebe <check_page_free_list+0x1bc>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100f4e:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100f53:	77 8b                	ja     f0100ee0 <check_page_free_list+0x1de>
			++nfree_basemem;
f0100f55:	83 c7 01             	add    $0x1,%edi
f0100f58:	eb 9e                	jmp    f0100ef8 <check_page_free_list+0x1f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f5a:	50                   	push   %eax
f0100f5b:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100f5e:	8d 83 34 c6 fe ff    	lea    -0x139cc(%ebx),%eax
f0100f64:	50                   	push   %eax
f0100f65:	6a 52                	push   $0x52
f0100f67:	8d 83 19 ce fe ff    	lea    -0x131e7(%ebx),%eax
f0100f6d:	50                   	push   %eax
f0100f6e:	e8 26 f1 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100f73:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100f76:	8d 83 d4 c6 fe ff    	lea    -0x1392c(%ebx),%eax
f0100f7c:	50                   	push   %eax
f0100f7d:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0100f83:	50                   	push   %eax
f0100f84:	68 5e 02 00 00       	push   $0x25e
f0100f89:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0100f8f:	50                   	push   %eax
f0100f90:	e8 04 f1 ff ff       	call   f0100099 <_panic>
f0100f95:	8b 75 d0             	mov    -0x30(%ebp),%esi
	assert(nfree_basemem > 0);
f0100f98:	85 ff                	test   %edi,%edi
f0100f9a:	7e 1e                	jle    f0100fba <check_page_free_list+0x2b8>
	assert(nfree_extmem > 0);
f0100f9c:	85 f6                	test   %esi,%esi
f0100f9e:	7e 3c                	jle    f0100fdc <check_page_free_list+0x2da>
	cprintf("check_page_free_list() succeeded!\n");
f0100fa0:	83 ec 0c             	sub    $0xc,%esp
f0100fa3:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100fa6:	8d 83 1c c7 fe ff    	lea    -0x138e4(%ebx),%eax
f0100fac:	50                   	push   %eax
f0100fad:	e8 17 22 00 00       	call   f01031c9 <cprintf>
}
f0100fb2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fb5:	5b                   	pop    %ebx
f0100fb6:	5e                   	pop    %esi
f0100fb7:	5f                   	pop    %edi
f0100fb8:	5d                   	pop    %ebp
f0100fb9:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100fba:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100fbd:	8d 83 a0 ce fe ff    	lea    -0x13160(%ebx),%eax
f0100fc3:	50                   	push   %eax
f0100fc4:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0100fca:	50                   	push   %eax
f0100fcb:	68 66 02 00 00       	push   $0x266
f0100fd0:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0100fd6:	50                   	push   %eax
f0100fd7:	e8 bd f0 ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0100fdc:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100fdf:	8d 83 b2 ce fe ff    	lea    -0x1314e(%ebx),%eax
f0100fe5:	50                   	push   %eax
f0100fe6:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0100fec:	50                   	push   %eax
f0100fed:	68 67 02 00 00       	push   $0x267
f0100ff2:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0100ff8:	50                   	push   %eax
f0100ff9:	e8 9b f0 ff ff       	call   f0100099 <_panic>
	if (!page_free_list)
f0100ffe:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0101001:	8b 80 b4 1f 00 00    	mov    0x1fb4(%eax),%eax
f0101007:	85 c0                	test   %eax,%eax
f0101009:	0f 84 2a fd ff ff    	je     f0100d39 <check_page_free_list+0x37>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f010100f:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0101012:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101015:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101018:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f010101b:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010101e:	c7 c3 d0 a6 11 f0    	mov    $0xf011a6d0,%ebx
f0101024:	89 c2                	mov    %eax,%edx
f0101026:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0101028:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f010102e:	0f 95 c2             	setne  %dl
f0101031:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0101034:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0101038:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f010103a:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f010103e:	8b 00                	mov    (%eax),%eax
f0101040:	85 c0                	test   %eax,%eax
f0101042:	75 e0                	jne    f0101024 <check_page_free_list+0x322>
		*tp[1] = 0;
f0101044:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101047:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f010104d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101050:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101053:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0101055:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101058:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010105b:	89 87 b4 1f 00 00    	mov    %eax,0x1fb4(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0101061:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101068:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010106b:	8b b0 b4 1f 00 00    	mov    0x1fb4(%eax),%esi
f0101071:	c7 c7 d0 a6 11 f0    	mov    $0xf011a6d0,%edi
	if (PGNUM(pa) >= npages)
f0101077:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f010107d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101080:	e9 ed fc ff ff       	jmp    f0100d72 <check_page_free_list+0x70>

f0101085 <page_init>:
{
f0101085:	55                   	push   %ebp
f0101086:	89 e5                	mov    %esp,%ebp
f0101088:	57                   	push   %edi
f0101089:	56                   	push   %esi
f010108a:	53                   	push   %ebx
f010108b:	83 ec 1c             	sub    $0x1c,%esp
f010108e:	e8 5e f6 ff ff       	call   f01006f1 <__x86.get_pc_thunk.ax>
f0101093:	05 75 72 01 00       	add    $0x17275,%eax
f0101098:	89 45 d8             	mov    %eax,-0x28(%ebp)
	size_t kern_end = PADDR(boot_alloc(0)) / PGSIZE;
f010109b:	b8 00 00 00 00       	mov    $0x0,%eax
f01010a0:	e8 5a fb ff ff       	call   f0100bff <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f01010a5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01010aa:	76 46                	jbe    f01010f2 <page_init+0x6d>
	return (physaddr_t)kva - KERNBASE;
f01010ac:	05 00 00 00 10       	add    $0x10000000,%eax
f01010b1:	c1 e8 0c             	shr    $0xc,%eax
f01010b4:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pages[0].pp_ref = 1;
f01010b7:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01010ba:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f01010c0:	8b 00                	mov    (%eax),%eax
f01010c2:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;
f01010c8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f01010ce:	8b b7 b4 1f 00 00    	mov    0x1fb4(%edi),%esi
	for (i = 1; i < npages; i++) {
f01010d4:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010d9:	b8 01 00 00 00       	mov    $0x1,%eax
f01010de:	c7 c3 c8 a6 11 f0    	mov    $0xf011a6c8,%ebx
			pages[i].pp_ref = 0;
f01010e4:	c7 c2 d0 a6 11 f0    	mov    $0xf011a6d0,%edx
f01010ea:	89 55 e4             	mov    %edx,-0x1c(%ebp)
			pages[i].pp_ref = 1;
f01010ed:	89 55 dc             	mov    %edx,-0x24(%ebp)
	for (i = 1; i < npages; i++) {
f01010f0:	eb 41                	jmp    f0101133 <page_init+0xae>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01010f2:	50                   	push   %eax
f01010f3:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01010f6:	8d 83 40 c7 fe ff    	lea    -0x138c0(%ebx),%eax
f01010fc:	50                   	push   %eax
f01010fd:	68 0c 01 00 00       	push   $0x10c
f0101102:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0101108:	50                   	push   %eax
f0101109:	e8 8b ef ff ff       	call   f0100099 <_panic>
			pages[i].pp_ref = 0;
f010110e:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0101115:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101118:	89 d7                	mov    %edx,%edi
f010111a:	03 39                	add    (%ecx),%edi
f010111c:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
			pages[i].pp_link = page_free_list;
f0101122:	89 37                	mov    %esi,(%edi)
			page_free_list = &pages[i];
f0101124:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101127:	89 d6                	mov    %edx,%esi
f0101129:	03 31                	add    (%ecx),%esi
f010112b:	b9 01 00 00 00       	mov    $0x1,%ecx
	for (i = 1; i < npages; i++) {
f0101130:	83 c0 01             	add    $0x1,%eax
f0101133:	39 03                	cmp    %eax,(%ebx)
f0101135:	76 22                	jbe    f0101159 <page_init+0xd4>
		if (i >= IOPHYSMEM / PGSIZE && i < kern_end){
f0101137:	3d 9f 00 00 00       	cmp    $0x9f,%eax
f010113c:	76 d0                	jbe    f010110e <page_init+0x89>
f010113e:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0101141:	73 cb                	jae    f010110e <page_init+0x89>
			pages[i].pp_ref = 1;
f0101143:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0101146:	8b 17                	mov    (%edi),%edx
f0101148:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f010114b:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
			pages[i].pp_link = NULL;
f0101151:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
f0101157:	eb d7                	jmp    f0101130 <page_init+0xab>
f0101159:	84 c9                	test   %cl,%cl
f010115b:	75 08                	jne    f0101165 <page_init+0xe0>
}
f010115d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101160:	5b                   	pop    %ebx
f0101161:	5e                   	pop    %esi
f0101162:	5f                   	pop    %edi
f0101163:	5d                   	pop    %ebp
f0101164:	c3                   	ret    
f0101165:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101168:	89 b0 b4 1f 00 00    	mov    %esi,0x1fb4(%eax)
f010116e:	eb ed                	jmp    f010115d <page_init+0xd8>

f0101170 <page_alloc>:
{
f0101170:	55                   	push   %ebp
f0101171:	89 e5                	mov    %esp,%ebp
f0101173:	56                   	push   %esi
f0101174:	53                   	push   %ebx
f0101175:	e8 d5 ef ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010117a:	81 c3 8e 71 01 00    	add    $0x1718e,%ebx
	struct PageInfo *result = page_free_list;
f0101180:	8b b3 b4 1f 00 00    	mov    0x1fb4(%ebx),%esi
	if(!page_free_list){
f0101186:	85 f6                	test   %esi,%esi
f0101188:	74 14                	je     f010119e <page_alloc+0x2e>
	if (alloc_flags & ALLOC_ZERO) {
f010118a:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f010118e:	75 17                	jne    f01011a7 <page_alloc+0x37>
	page_free_list = result->pp_link;
f0101190:	8b 06                	mov    (%esi),%eax
f0101192:	89 83 b4 1f 00 00    	mov    %eax,0x1fb4(%ebx)
	result->pp_link = NULL;
f0101198:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
}
f010119e:	89 f0                	mov    %esi,%eax
f01011a0:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01011a3:	5b                   	pop    %ebx
f01011a4:	5e                   	pop    %esi
f01011a5:	5d                   	pop    %ebp
f01011a6:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f01011a7:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f01011ad:	89 f2                	mov    %esi,%edx
f01011af:	2b 10                	sub    (%eax),%edx
f01011b1:	89 d0                	mov    %edx,%eax
f01011b3:	c1 f8 03             	sar    $0x3,%eax
f01011b6:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01011b9:	89 c1                	mov    %eax,%ecx
f01011bb:	c1 e9 0c             	shr    $0xc,%ecx
f01011be:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
f01011c4:	3b 0a                	cmp    (%edx),%ecx
f01011c6:	73 1a                	jae    f01011e2 <page_alloc+0x72>
		memset(page2kva(result), 0, PGSIZE);
f01011c8:	83 ec 04             	sub    $0x4,%esp
f01011cb:	68 00 10 00 00       	push   $0x1000
f01011d0:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f01011d2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01011d7:	50                   	push   %eax
f01011d8:	e8 a0 2d 00 00       	call   f0103f7d <memset>
f01011dd:	83 c4 10             	add    $0x10,%esp
f01011e0:	eb ae                	jmp    f0101190 <page_alloc+0x20>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011e2:	50                   	push   %eax
f01011e3:	8d 83 34 c6 fe ff    	lea    -0x139cc(%ebx),%eax
f01011e9:	50                   	push   %eax
f01011ea:	6a 52                	push   $0x52
f01011ec:	8d 83 19 ce fe ff    	lea    -0x131e7(%ebx),%eax
f01011f2:	50                   	push   %eax
f01011f3:	e8 a1 ee ff ff       	call   f0100099 <_panic>

f01011f8 <page_free>:
{
f01011f8:	55                   	push   %ebp
f01011f9:	89 e5                	mov    %esp,%ebp
f01011fb:	53                   	push   %ebx
f01011fc:	83 ec 04             	sub    $0x4,%esp
f01011ff:	e8 4b ef ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101204:	81 c3 04 71 01 00    	add    $0x17104,%ebx
f010120a:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_ref != 0 || pp->pp_link != NULL){
f010120d:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101212:	75 18                	jne    f010122c <page_free+0x34>
f0101214:	83 38 00             	cmpl   $0x0,(%eax)
f0101217:	75 13                	jne    f010122c <page_free+0x34>
	pp->pp_link = page_free_list;
f0101219:	8b 8b b4 1f 00 00    	mov    0x1fb4(%ebx),%ecx
f010121f:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f0101221:	89 83 b4 1f 00 00    	mov    %eax,0x1fb4(%ebx)
}
f0101227:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010122a:	c9                   	leave  
f010122b:	c3                   	ret    
		panic("'pp->pp_ref' is nonzero or 'pp->pp_link' is not NULL!");
f010122c:	83 ec 04             	sub    $0x4,%esp
f010122f:	8d 83 64 c7 fe ff    	lea    -0x1389c(%ebx),%eax
f0101235:	50                   	push   %eax
f0101236:	68 43 01 00 00       	push   $0x143
f010123b:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0101241:	50                   	push   %eax
f0101242:	e8 52 ee ff ff       	call   f0100099 <_panic>

f0101247 <page_decref>:
{
f0101247:	55                   	push   %ebp
f0101248:	89 e5                	mov    %esp,%ebp
f010124a:	83 ec 08             	sub    $0x8,%esp
f010124d:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101250:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101254:	83 e8 01             	sub    $0x1,%eax
f0101257:	66 89 42 04          	mov    %ax,0x4(%edx)
f010125b:	66 85 c0             	test   %ax,%ax
f010125e:	74 02                	je     f0101262 <page_decref+0x1b>
}
f0101260:	c9                   	leave  
f0101261:	c3                   	ret    
		page_free(pp);
f0101262:	83 ec 0c             	sub    $0xc,%esp
f0101265:	52                   	push   %edx
f0101266:	e8 8d ff ff ff       	call   f01011f8 <page_free>
f010126b:	83 c4 10             	add    $0x10,%esp
}
f010126e:	eb f0                	jmp    f0101260 <page_decref+0x19>

f0101270 <pgdir_walk>:
{
f0101270:	55                   	push   %ebp
f0101271:	89 e5                	mov    %esp,%ebp
f0101273:	57                   	push   %edi
f0101274:	56                   	push   %esi
f0101275:	53                   	push   %ebx
f0101276:	83 ec 0c             	sub    $0xc,%esp
f0101279:	e8 d1 ee ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010127e:	81 c3 8a 70 01 00    	add    $0x1708a,%ebx
f0101284:	8b 7d 0c             	mov    0xc(%ebp),%edi
	pde_t *pte_ptr = pgdir + PDX(va);
f0101287:	89 fe                	mov    %edi,%esi
f0101289:	c1 ee 16             	shr    $0x16,%esi
f010128c:	c1 e6 02             	shl    $0x2,%esi
f010128f:	03 75 08             	add    0x8(%ebp),%esi
	if (!(*pte_ptr & PTE_P)){
f0101292:	f6 06 01             	testb  $0x1,(%esi)
f0101295:	75 2f                	jne    f01012c6 <pgdir_walk+0x56>
		if (create){
f0101297:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010129b:	74 70                	je     f010130d <pgdir_walk+0x9d>
			struct PageInfo *pp = page_alloc(ALLOC_ZERO);
f010129d:	83 ec 0c             	sub    $0xc,%esp
f01012a0:	6a 01                	push   $0x1
f01012a2:	e8 c9 fe ff ff       	call   f0101170 <page_alloc>
			if (pp){
f01012a7:	83 c4 10             	add    $0x10,%esp
f01012aa:	85 c0                	test   %eax,%eax
f01012ac:	74 66                	je     f0101314 <pgdir_walk+0xa4>
				pp->pp_ref++;
f01012ae:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f01012b3:	c7 c2 d0 a6 11 f0    	mov    $0xf011a6d0,%edx
f01012b9:	2b 02                	sub    (%edx),%eax
f01012bb:	c1 f8 03             	sar    $0x3,%eax
f01012be:	c1 e0 0c             	shl    $0xc,%eax
				*pte_ptr = page2pa(pp) | PTE_P | PTE_U | PTE_W;
f01012c1:	83 c8 07             	or     $0x7,%eax
f01012c4:	89 06                	mov    %eax,(%esi)
	return (pte_t *)KADDR(PTE_ADDR(*pte_ptr)) + PTX(va);
f01012c6:	8b 06                	mov    (%esi),%eax
f01012c8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f01012cd:	89 c1                	mov    %eax,%ecx
f01012cf:	c1 e9 0c             	shr    $0xc,%ecx
f01012d2:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
f01012d8:	3b 0a                	cmp    (%edx),%ecx
f01012da:	73 18                	jae    f01012f4 <pgdir_walk+0x84>
f01012dc:	c1 ef 0a             	shr    $0xa,%edi
f01012df:	81 e7 fc 0f 00 00    	and    $0xffc,%edi
f01012e5:	8d 84 38 00 00 00 f0 	lea    -0x10000000(%eax,%edi,1),%eax
}
f01012ec:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012ef:	5b                   	pop    %ebx
f01012f0:	5e                   	pop    %esi
f01012f1:	5f                   	pop    %edi
f01012f2:	5d                   	pop    %ebp
f01012f3:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01012f4:	50                   	push   %eax
f01012f5:	8d 83 34 c6 fe ff    	lea    -0x139cc(%ebx),%eax
f01012fb:	50                   	push   %eax
f01012fc:	68 7d 01 00 00       	push   $0x17d
f0101301:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0101307:	50                   	push   %eax
f0101308:	e8 8c ed ff ff       	call   f0100099 <_panic>
			return NULL;
f010130d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101312:	eb d8                	jmp    f01012ec <pgdir_walk+0x7c>
				return NULL;
f0101314:	b8 00 00 00 00       	mov    $0x0,%eax
f0101319:	eb d1                	jmp    f01012ec <pgdir_walk+0x7c>

f010131b <boot_map_region>:
{
f010131b:	55                   	push   %ebp
f010131c:	89 e5                	mov    %esp,%ebp
f010131e:	57                   	push   %edi
f010131f:	56                   	push   %esi
f0101320:	53                   	push   %ebx
f0101321:	83 ec 1c             	sub    $0x1c,%esp
f0101324:	e8 0c 1e 00 00       	call   f0103135 <__x86.get_pc_thunk.di>
f0101329:	81 c7 df 6f 01 00    	add    $0x16fdf,%edi
f010132f:	89 7d d8             	mov    %edi,-0x28(%ebp)
f0101332:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101335:	8b 45 08             	mov    0x8(%ebp),%eax
	size_t i, pgs = size / PGSIZE;
f0101338:	c1 e9 0c             	shr    $0xc,%ecx
f010133b:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for (i = 0; i < pgs; i++){
f010133e:	89 c3                	mov    %eax,%ebx
f0101340:	be 00 00 00 00       	mov    $0x0,%esi
		pte = pgdir_walk(pgdir, (void *)va, 1);
f0101345:	89 d7                	mov    %edx,%edi
f0101347:	29 c7                	sub    %eax,%edi
		*pte = pa | perm | PTE_P;
f0101349:	8b 45 0c             	mov    0xc(%ebp),%eax
f010134c:	83 c8 01             	or     $0x1,%eax
f010134f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for (i = 0; i < pgs; i++){
f0101352:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0101355:	74 48                	je     f010139f <boot_map_region+0x84>
		pte = pgdir_walk(pgdir, (void *)va, 1);
f0101357:	83 ec 04             	sub    $0x4,%esp
f010135a:	6a 01                	push   $0x1
f010135c:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f010135f:	50                   	push   %eax
f0101360:	ff 75 e0             	pushl  -0x20(%ebp)
f0101363:	e8 08 ff ff ff       	call   f0101270 <pgdir_walk>
		if (pte == NULL){
f0101368:	83 c4 10             	add    $0x10,%esp
f010136b:	85 c0                	test   %eax,%eax
f010136d:	74 12                	je     f0101381 <boot_map_region+0x66>
		*pte = pa | perm | PTE_P;
f010136f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101372:	09 da                	or     %ebx,%edx
f0101374:	89 10                	mov    %edx,(%eax)
		pa += PGSIZE;
f0101376:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < pgs; i++){
f010137c:	83 c6 01             	add    $0x1,%esi
f010137f:	eb d1                	jmp    f0101352 <boot_map_region+0x37>
			panic("boot_map_region() fails!");
f0101381:	83 ec 04             	sub    $0x4,%esp
f0101384:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0101387:	8d 83 c3 ce fe ff    	lea    -0x1313d(%ebx),%eax
f010138d:	50                   	push   %eax
f010138e:	68 94 01 00 00       	push   $0x194
f0101393:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0101399:	50                   	push   %eax
f010139a:	e8 fa ec ff ff       	call   f0100099 <_panic>
}
f010139f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01013a2:	5b                   	pop    %ebx
f01013a3:	5e                   	pop    %esi
f01013a4:	5f                   	pop    %edi
f01013a5:	5d                   	pop    %ebp
f01013a6:	c3                   	ret    

f01013a7 <page_lookup>:
{
f01013a7:	55                   	push   %ebp
f01013a8:	89 e5                	mov    %esp,%ebp
f01013aa:	56                   	push   %esi
f01013ab:	53                   	push   %ebx
f01013ac:	e8 9e ed ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01013b1:	81 c3 57 6f 01 00    	add    $0x16f57,%ebx
f01013b7:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f01013ba:	83 ec 04             	sub    $0x4,%esp
f01013bd:	6a 00                	push   $0x0
f01013bf:	ff 75 0c             	pushl  0xc(%ebp)
f01013c2:	ff 75 08             	pushl  0x8(%ebp)
f01013c5:	e8 a6 fe ff ff       	call   f0101270 <pgdir_walk>
	if (pte == NULL){
f01013ca:	83 c4 10             	add    $0x10,%esp
f01013cd:	85 c0                	test   %eax,%eax
f01013cf:	74 44                	je     f0101415 <page_lookup+0x6e>
	if (!(*pte & PTE_P)){
f01013d1:	f6 00 01             	testb  $0x1,(%eax)
f01013d4:	74 46                	je     f010141c <page_lookup+0x75>
	if (pte_store != 0){
f01013d6:	85 f6                	test   %esi,%esi
f01013d8:	74 02                	je     f01013dc <page_lookup+0x35>
		*pte_store = pte;
f01013da:	89 06                	mov    %eax,(%esi)
f01013dc:	8b 00                	mov    (%eax),%eax
f01013de:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01013e1:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
f01013e7:	39 02                	cmp    %eax,(%edx)
f01013e9:	76 12                	jbe    f01013fd <page_lookup+0x56>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f01013eb:	c7 c2 d0 a6 11 f0    	mov    $0xf011a6d0,%edx
f01013f1:	8b 12                	mov    (%edx),%edx
f01013f3:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f01013f6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01013f9:	5b                   	pop    %ebx
f01013fa:	5e                   	pop    %esi
f01013fb:	5d                   	pop    %ebp
f01013fc:	c3                   	ret    
		panic("pa2page called with invalid pa");
f01013fd:	83 ec 04             	sub    $0x4,%esp
f0101400:	8d 83 9c c7 fe ff    	lea    -0x13864(%ebx),%eax
f0101406:	50                   	push   %eax
f0101407:	6a 4b                	push   $0x4b
f0101409:	8d 83 19 ce fe ff    	lea    -0x131e7(%ebx),%eax
f010140f:	50                   	push   %eax
f0101410:	e8 84 ec ff ff       	call   f0100099 <_panic>
		return NULL;
f0101415:	b8 00 00 00 00       	mov    $0x0,%eax
f010141a:	eb da                	jmp    f01013f6 <page_lookup+0x4f>
		return NULL;
f010141c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101421:	eb d3                	jmp    f01013f6 <page_lookup+0x4f>

f0101423 <page_remove>:
{
f0101423:	55                   	push   %ebp
f0101424:	89 e5                	mov    %esp,%ebp
f0101426:	53                   	push   %ebx
f0101427:	83 ec 18             	sub    $0x18,%esp
f010142a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *pp = page_lookup(pgdir, va, &pte_store);
f010142d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101430:	50                   	push   %eax
f0101431:	53                   	push   %ebx
f0101432:	ff 75 08             	pushl  0x8(%ebp)
f0101435:	e8 6d ff ff ff       	call   f01013a7 <page_lookup>
	if (pp == NULL){
f010143a:	83 c4 10             	add    $0x10,%esp
f010143d:	85 c0                	test   %eax,%eax
f010143f:	75 05                	jne    f0101446 <page_remove+0x23>
}
f0101441:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101444:	c9                   	leave  
f0101445:	c3                   	ret    
	page_decref(pp);
f0101446:	83 ec 0c             	sub    $0xc,%esp
f0101449:	50                   	push   %eax
f010144a:	e8 f8 fd ff ff       	call   f0101247 <page_decref>
	*pte_store = 0;
f010144f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101452:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101458:	0f 01 3b             	invlpg (%ebx)
f010145b:	83 c4 10             	add    $0x10,%esp
f010145e:	eb e1                	jmp    f0101441 <page_remove+0x1e>

f0101460 <page_insert>:
{
f0101460:	55                   	push   %ebp
f0101461:	89 e5                	mov    %esp,%ebp
f0101463:	57                   	push   %edi
f0101464:	56                   	push   %esi
f0101465:	53                   	push   %ebx
f0101466:	83 ec 1c             	sub    $0x1c,%esp
f0101469:	e8 83 f2 ff ff       	call   f01006f1 <__x86.get_pc_thunk.ax>
f010146e:	05 9a 6e 01 00       	add    $0x16e9a,%eax
f0101473:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101476:	8b 75 08             	mov    0x8(%ebp),%esi
f0101479:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	assert(pp);
f010147c:	85 db                	test   %ebx,%ebx
f010147e:	74 5f                	je     f01014df <page_insert+0x7f>
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f0101480:	83 ec 04             	sub    $0x4,%esp
f0101483:	6a 01                	push   $0x1
f0101485:	ff 75 10             	pushl  0x10(%ebp)
f0101488:	56                   	push   %esi
f0101489:	e8 e2 fd ff ff       	call   f0101270 <pgdir_walk>
f010148e:	89 c7                	mov    %eax,%edi
	if (pte == NULL){
f0101490:	83 c4 10             	add    $0x10,%esp
f0101493:	85 c0                	test   %eax,%eax
f0101495:	74 69                	je     f0101500 <page_insert+0xa0>
	pp->pp_ref++;
f0101497:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	page_remove(pgdir, va);
f010149c:	83 ec 08             	sub    $0x8,%esp
f010149f:	ff 75 10             	pushl  0x10(%ebp)
f01014a2:	56                   	push   %esi
f01014a3:	e8 7b ff ff ff       	call   f0101423 <page_remove>
	return (pp - pages) << PGSHIFT;
f01014a8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01014ab:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f01014b1:	2b 18                	sub    (%eax),%ebx
f01014b3:	c1 fb 03             	sar    $0x3,%ebx
f01014b6:	c1 e3 0c             	shl    $0xc,%ebx
	*pte = pa | perm | PTE_P;
f01014b9:	8b 45 14             	mov    0x14(%ebp),%eax
f01014bc:	83 c8 01             	or     $0x1,%eax
f01014bf:	09 c3                	or     %eax,%ebx
f01014c1:	89 1f                	mov    %ebx,(%edi)
	*(pgdir + PDX(va)) |= perm;
f01014c3:	8b 45 10             	mov    0x10(%ebp),%eax
f01014c6:	c1 e8 16             	shr    $0x16,%eax
f01014c9:	8b 55 14             	mov    0x14(%ebp),%edx
f01014cc:	09 14 86             	or     %edx,(%esi,%eax,4)
	return 0;
f01014cf:	83 c4 10             	add    $0x10,%esp
f01014d2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014d7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014da:	5b                   	pop    %ebx
f01014db:	5e                   	pop    %esi
f01014dc:	5f                   	pop    %edi
f01014dd:	5d                   	pop    %ebp
f01014de:	c3                   	ret    
	assert(pp);
f01014df:	89 c3                	mov    %eax,%ebx
f01014e1:	8d 80 dc cf fe ff    	lea    -0x13024(%eax),%eax
f01014e7:	50                   	push   %eax
f01014e8:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01014ee:	50                   	push   %eax
f01014ef:	68 d6 01 00 00       	push   $0x1d6
f01014f4:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01014fa:	50                   	push   %eax
f01014fb:	e8 99 eb ff ff       	call   f0100099 <_panic>
		return -E_NO_MEM;
f0101500:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0101505:	eb d0                	jmp    f01014d7 <page_insert+0x77>

f0101507 <mem_init>:
{
f0101507:	55                   	push   %ebp
f0101508:	89 e5                	mov    %esp,%ebp
f010150a:	57                   	push   %edi
f010150b:	56                   	push   %esi
f010150c:	53                   	push   %ebx
f010150d:	83 ec 3c             	sub    $0x3c,%esp
f0101510:	e8 3a ec ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101515:	81 c3 f3 6d 01 00    	add    $0x16df3,%ebx
	basemem = nvram_read(NVRAM_BASELO);
f010151b:	b8 15 00 00 00       	mov    $0x15,%eax
f0101520:	e8 2a f7 ff ff       	call   f0100c4f <nvram_read>
f0101525:	89 c7                	mov    %eax,%edi
	extmem = nvram_read(NVRAM_EXTLO);
f0101527:	b8 17 00 00 00       	mov    $0x17,%eax
f010152c:	e8 1e f7 ff ff       	call   f0100c4f <nvram_read>
f0101531:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101533:	b8 34 00 00 00       	mov    $0x34,%eax
f0101538:	e8 12 f7 ff ff       	call   f0100c4f <nvram_read>
f010153d:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f0101540:	85 c0                	test   %eax,%eax
f0101542:	0f 85 b5 00 00 00    	jne    f01015fd <mem_init+0xf6>
		totalmem = 1 * 1024 + extmem;
f0101548:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f010154e:	85 f6                	test   %esi,%esi
f0101550:	0f 44 c7             	cmove  %edi,%eax
	npages = totalmem / (PGSIZE / 1024);
f0101553:	89 c1                	mov    %eax,%ecx
f0101555:	c1 e9 02             	shr    $0x2,%ecx
f0101558:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
f010155e:	89 0a                	mov    %ecx,(%edx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101560:	89 c2                	mov    %eax,%edx
f0101562:	29 fa                	sub    %edi,%edx
f0101564:	52                   	push   %edx
f0101565:	57                   	push   %edi
f0101566:	50                   	push   %eax
f0101567:	8d 83 bc c7 fe ff    	lea    -0x13844(%ebx),%eax
f010156d:	50                   	push   %eax
f010156e:	e8 56 1c 00 00       	call   f01031c9 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101573:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101578:	e8 82 f6 ff ff       	call   f0100bff <boot_alloc>
f010157d:	c7 c6 cc a6 11 f0    	mov    $0xf011a6cc,%esi
f0101583:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f0101585:	83 c4 0c             	add    $0xc,%esp
f0101588:	68 00 10 00 00       	push   $0x1000
f010158d:	6a 00                	push   $0x0
f010158f:	50                   	push   %eax
f0101590:	e8 e8 29 00 00       	call   f0103f7d <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101595:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f0101597:	83 c4 10             	add    $0x10,%esp
f010159a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010159f:	76 66                	jbe    f0101607 <mem_init+0x100>
	return (physaddr_t)kva - KERNBASE;
f01015a1:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01015a7:	83 ca 05             	or     $0x5,%edx
f01015aa:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo*)boot_alloc(sizeof(struct PageInfo) * npages);
f01015b0:	c7 c7 c8 a6 11 f0    	mov    $0xf011a6c8,%edi
f01015b6:	8b 07                	mov    (%edi),%eax
f01015b8:	c1 e0 03             	shl    $0x3,%eax
f01015bb:	e8 3f f6 ff ff       	call   f0100bff <boot_alloc>
f01015c0:	c7 c6 d0 a6 11 f0    	mov    $0xf011a6d0,%esi
f01015c6:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, sizeof(struct PageInfo) * npages);
f01015c8:	83 ec 04             	sub    $0x4,%esp
f01015cb:	8b 17                	mov    (%edi),%edx
f01015cd:	c1 e2 03             	shl    $0x3,%edx
f01015d0:	52                   	push   %edx
f01015d1:	6a 00                	push   $0x0
f01015d3:	50                   	push   %eax
f01015d4:	e8 a4 29 00 00       	call   f0103f7d <memset>
	page_init();
f01015d9:	e8 a7 fa ff ff       	call   f0101085 <page_init>
	check_page_free_list(1);
f01015de:	b8 01 00 00 00       	mov    $0x1,%eax
f01015e3:	e8 1a f7 ff ff       	call   f0100d02 <check_page_free_list>
	if (!pages)
f01015e8:	83 c4 10             	add    $0x10,%esp
f01015eb:	83 3e 00             	cmpl   $0x0,(%esi)
f01015ee:	74 30                	je     f0101620 <mem_init+0x119>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01015f0:	8b 83 b4 1f 00 00    	mov    0x1fb4(%ebx),%eax
f01015f6:	be 00 00 00 00       	mov    $0x0,%esi
f01015fb:	eb 43                	jmp    f0101640 <mem_init+0x139>
		totalmem = 16 * 1024 + ext16mem;
f01015fd:	05 00 40 00 00       	add    $0x4000,%eax
f0101602:	e9 4c ff ff ff       	jmp    f0101553 <mem_init+0x4c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101607:	50                   	push   %eax
f0101608:	8d 83 40 c7 fe ff    	lea    -0x138c0(%ebx),%eax
f010160e:	50                   	push   %eax
f010160f:	68 93 00 00 00       	push   $0x93
f0101614:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010161a:	50                   	push   %eax
f010161b:	e8 79 ea ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f0101620:	83 ec 04             	sub    $0x4,%esp
f0101623:	8d 83 dc ce fe ff    	lea    -0x13124(%ebx),%eax
f0101629:	50                   	push   %eax
f010162a:	68 7a 02 00 00       	push   $0x27a
f010162f:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0101635:	50                   	push   %eax
f0101636:	e8 5e ea ff ff       	call   f0100099 <_panic>
		++nfree;
f010163b:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010163e:	8b 00                	mov    (%eax),%eax
f0101640:	85 c0                	test   %eax,%eax
f0101642:	75 f7                	jne    f010163b <mem_init+0x134>
	assert((pp0 = page_alloc(0)));
f0101644:	83 ec 0c             	sub    $0xc,%esp
f0101647:	6a 00                	push   $0x0
f0101649:	e8 22 fb ff ff       	call   f0101170 <page_alloc>
f010164e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101651:	83 c4 10             	add    $0x10,%esp
f0101654:	85 c0                	test   %eax,%eax
f0101656:	0f 84 2e 02 00 00    	je     f010188a <mem_init+0x383>
	assert((pp1 = page_alloc(0)));
f010165c:	83 ec 0c             	sub    $0xc,%esp
f010165f:	6a 00                	push   $0x0
f0101661:	e8 0a fb ff ff       	call   f0101170 <page_alloc>
f0101666:	89 c7                	mov    %eax,%edi
f0101668:	83 c4 10             	add    $0x10,%esp
f010166b:	85 c0                	test   %eax,%eax
f010166d:	0f 84 36 02 00 00    	je     f01018a9 <mem_init+0x3a2>
	assert((pp2 = page_alloc(0)));
f0101673:	83 ec 0c             	sub    $0xc,%esp
f0101676:	6a 00                	push   $0x0
f0101678:	e8 f3 fa ff ff       	call   f0101170 <page_alloc>
f010167d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101680:	83 c4 10             	add    $0x10,%esp
f0101683:	85 c0                	test   %eax,%eax
f0101685:	0f 84 3d 02 00 00    	je     f01018c8 <mem_init+0x3c1>
	assert(pp1 && pp1 != pp0);
f010168b:	39 7d d4             	cmp    %edi,-0x2c(%ebp)
f010168e:	0f 84 53 02 00 00    	je     f01018e7 <mem_init+0x3e0>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101694:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101697:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010169a:	0f 84 66 02 00 00    	je     f0101906 <mem_init+0x3ff>
f01016a0:	39 c7                	cmp    %eax,%edi
f01016a2:	0f 84 5e 02 00 00    	je     f0101906 <mem_init+0x3ff>
	return (pp - pages) << PGSHIFT;
f01016a8:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f01016ae:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01016b0:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f01016b6:	8b 10                	mov    (%eax),%edx
f01016b8:	c1 e2 0c             	shl    $0xc,%edx
f01016bb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016be:	29 c8                	sub    %ecx,%eax
f01016c0:	c1 f8 03             	sar    $0x3,%eax
f01016c3:	c1 e0 0c             	shl    $0xc,%eax
f01016c6:	39 d0                	cmp    %edx,%eax
f01016c8:	0f 83 57 02 00 00    	jae    f0101925 <mem_init+0x41e>
f01016ce:	89 f8                	mov    %edi,%eax
f01016d0:	29 c8                	sub    %ecx,%eax
f01016d2:	c1 f8 03             	sar    $0x3,%eax
f01016d5:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f01016d8:	39 c2                	cmp    %eax,%edx
f01016da:	0f 86 64 02 00 00    	jbe    f0101944 <mem_init+0x43d>
f01016e0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01016e3:	29 c8                	sub    %ecx,%eax
f01016e5:	c1 f8 03             	sar    $0x3,%eax
f01016e8:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01016eb:	39 c2                	cmp    %eax,%edx
f01016ed:	0f 86 70 02 00 00    	jbe    f0101963 <mem_init+0x45c>
	fl = page_free_list;
f01016f3:	8b 83 b4 1f 00 00    	mov    0x1fb4(%ebx),%eax
f01016f9:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f01016fc:	c7 83 b4 1f 00 00 00 	movl   $0x0,0x1fb4(%ebx)
f0101703:	00 00 00 
	assert(!page_alloc(0));
f0101706:	83 ec 0c             	sub    $0xc,%esp
f0101709:	6a 00                	push   $0x0
f010170b:	e8 60 fa ff ff       	call   f0101170 <page_alloc>
f0101710:	83 c4 10             	add    $0x10,%esp
f0101713:	85 c0                	test   %eax,%eax
f0101715:	0f 85 67 02 00 00    	jne    f0101982 <mem_init+0x47b>
	page_free(pp0);
f010171b:	83 ec 0c             	sub    $0xc,%esp
f010171e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101721:	e8 d2 fa ff ff       	call   f01011f8 <page_free>
	page_free(pp1);
f0101726:	89 3c 24             	mov    %edi,(%esp)
f0101729:	e8 ca fa ff ff       	call   f01011f8 <page_free>
	page_free(pp2);
f010172e:	83 c4 04             	add    $0x4,%esp
f0101731:	ff 75 d0             	pushl  -0x30(%ebp)
f0101734:	e8 bf fa ff ff       	call   f01011f8 <page_free>
	assert((pp0 = page_alloc(0)));
f0101739:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101740:	e8 2b fa ff ff       	call   f0101170 <page_alloc>
f0101745:	89 c7                	mov    %eax,%edi
f0101747:	83 c4 10             	add    $0x10,%esp
f010174a:	85 c0                	test   %eax,%eax
f010174c:	0f 84 4f 02 00 00    	je     f01019a1 <mem_init+0x49a>
	assert((pp1 = page_alloc(0)));
f0101752:	83 ec 0c             	sub    $0xc,%esp
f0101755:	6a 00                	push   $0x0
f0101757:	e8 14 fa ff ff       	call   f0101170 <page_alloc>
f010175c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010175f:	83 c4 10             	add    $0x10,%esp
f0101762:	85 c0                	test   %eax,%eax
f0101764:	0f 84 56 02 00 00    	je     f01019c0 <mem_init+0x4b9>
	assert((pp2 = page_alloc(0)));
f010176a:	83 ec 0c             	sub    $0xc,%esp
f010176d:	6a 00                	push   $0x0
f010176f:	e8 fc f9 ff ff       	call   f0101170 <page_alloc>
f0101774:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101777:	83 c4 10             	add    $0x10,%esp
f010177a:	85 c0                	test   %eax,%eax
f010177c:	0f 84 5d 02 00 00    	je     f01019df <mem_init+0x4d8>
	assert(pp1 && pp1 != pp0);
f0101782:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101785:	0f 84 73 02 00 00    	je     f01019fe <mem_init+0x4f7>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010178b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010178e:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101791:	0f 84 86 02 00 00    	je     f0101a1d <mem_init+0x516>
f0101797:	39 c7                	cmp    %eax,%edi
f0101799:	0f 84 7e 02 00 00    	je     f0101a1d <mem_init+0x516>
	assert(!page_alloc(0));
f010179f:	83 ec 0c             	sub    $0xc,%esp
f01017a2:	6a 00                	push   $0x0
f01017a4:	e8 c7 f9 ff ff       	call   f0101170 <page_alloc>
f01017a9:	83 c4 10             	add    $0x10,%esp
f01017ac:	85 c0                	test   %eax,%eax
f01017ae:	0f 85 88 02 00 00    	jne    f0101a3c <mem_init+0x535>
f01017b4:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f01017ba:	89 f9                	mov    %edi,%ecx
f01017bc:	2b 08                	sub    (%eax),%ecx
f01017be:	89 c8                	mov    %ecx,%eax
f01017c0:	c1 f8 03             	sar    $0x3,%eax
f01017c3:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01017c6:	89 c1                	mov    %eax,%ecx
f01017c8:	c1 e9 0c             	shr    $0xc,%ecx
f01017cb:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
f01017d1:	3b 0a                	cmp    (%edx),%ecx
f01017d3:	0f 83 82 02 00 00    	jae    f0101a5b <mem_init+0x554>
	memset(page2kva(pp0), 1, PGSIZE);
f01017d9:	83 ec 04             	sub    $0x4,%esp
f01017dc:	68 00 10 00 00       	push   $0x1000
f01017e1:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01017e3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01017e8:	50                   	push   %eax
f01017e9:	e8 8f 27 00 00       	call   f0103f7d <memset>
	page_free(pp0);
f01017ee:	89 3c 24             	mov    %edi,(%esp)
f01017f1:	e8 02 fa ff ff       	call   f01011f8 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01017f6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01017fd:	e8 6e f9 ff ff       	call   f0101170 <page_alloc>
f0101802:	83 c4 10             	add    $0x10,%esp
f0101805:	85 c0                	test   %eax,%eax
f0101807:	0f 84 64 02 00 00    	je     f0101a71 <mem_init+0x56a>
	assert(pp && pp0 == pp);
f010180d:	39 c7                	cmp    %eax,%edi
f010180f:	0f 85 7b 02 00 00    	jne    f0101a90 <mem_init+0x589>
	return (pp - pages) << PGSHIFT;
f0101815:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f010181b:	89 fa                	mov    %edi,%edx
f010181d:	2b 10                	sub    (%eax),%edx
f010181f:	c1 fa 03             	sar    $0x3,%edx
f0101822:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101825:	89 d1                	mov    %edx,%ecx
f0101827:	c1 e9 0c             	shr    $0xc,%ecx
f010182a:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f0101830:	3b 08                	cmp    (%eax),%ecx
f0101832:	0f 83 77 02 00 00    	jae    f0101aaf <mem_init+0x5a8>
	return (void *)(pa + KERNBASE);
f0101838:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f010183e:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f0101844:	80 38 00             	cmpb   $0x0,(%eax)
f0101847:	0f 85 78 02 00 00    	jne    f0101ac5 <mem_init+0x5be>
f010184d:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f0101850:	39 c2                	cmp    %eax,%edx
f0101852:	75 f0                	jne    f0101844 <mem_init+0x33d>
	page_free_list = fl;
f0101854:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101857:	89 83 b4 1f 00 00    	mov    %eax,0x1fb4(%ebx)
	page_free(pp0);
f010185d:	83 ec 0c             	sub    $0xc,%esp
f0101860:	57                   	push   %edi
f0101861:	e8 92 f9 ff ff       	call   f01011f8 <page_free>
	page_free(pp1);
f0101866:	83 c4 04             	add    $0x4,%esp
f0101869:	ff 75 d4             	pushl  -0x2c(%ebp)
f010186c:	e8 87 f9 ff ff       	call   f01011f8 <page_free>
	page_free(pp2);
f0101871:	83 c4 04             	add    $0x4,%esp
f0101874:	ff 75 d0             	pushl  -0x30(%ebp)
f0101877:	e8 7c f9 ff ff       	call   f01011f8 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010187c:	8b 83 b4 1f 00 00    	mov    0x1fb4(%ebx),%eax
f0101882:	83 c4 10             	add    $0x10,%esp
f0101885:	e9 5f 02 00 00       	jmp    f0101ae9 <mem_init+0x5e2>
	assert((pp0 = page_alloc(0)));
f010188a:	8d 83 f7 ce fe ff    	lea    -0x13109(%ebx),%eax
f0101890:	50                   	push   %eax
f0101891:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0101897:	50                   	push   %eax
f0101898:	68 82 02 00 00       	push   $0x282
f010189d:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01018a3:	50                   	push   %eax
f01018a4:	e8 f0 e7 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f01018a9:	8d 83 0d cf fe ff    	lea    -0x130f3(%ebx),%eax
f01018af:	50                   	push   %eax
f01018b0:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01018b6:	50                   	push   %eax
f01018b7:	68 83 02 00 00       	push   $0x283
f01018bc:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01018c2:	50                   	push   %eax
f01018c3:	e8 d1 e7 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01018c8:	8d 83 23 cf fe ff    	lea    -0x130dd(%ebx),%eax
f01018ce:	50                   	push   %eax
f01018cf:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01018d5:	50                   	push   %eax
f01018d6:	68 84 02 00 00       	push   $0x284
f01018db:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01018e1:	50                   	push   %eax
f01018e2:	e8 b2 e7 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01018e7:	8d 83 39 cf fe ff    	lea    -0x130c7(%ebx),%eax
f01018ed:	50                   	push   %eax
f01018ee:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01018f4:	50                   	push   %eax
f01018f5:	68 87 02 00 00       	push   $0x287
f01018fa:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0101900:	50                   	push   %eax
f0101901:	e8 93 e7 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101906:	8d 83 f8 c7 fe ff    	lea    -0x13808(%ebx),%eax
f010190c:	50                   	push   %eax
f010190d:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0101913:	50                   	push   %eax
f0101914:	68 88 02 00 00       	push   $0x288
f0101919:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010191f:	50                   	push   %eax
f0101920:	e8 74 e7 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101925:	8d 83 4b cf fe ff    	lea    -0x130b5(%ebx),%eax
f010192b:	50                   	push   %eax
f010192c:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0101932:	50                   	push   %eax
f0101933:	68 89 02 00 00       	push   $0x289
f0101938:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010193e:	50                   	push   %eax
f010193f:	e8 55 e7 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101944:	8d 83 68 cf fe ff    	lea    -0x13098(%ebx),%eax
f010194a:	50                   	push   %eax
f010194b:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0101951:	50                   	push   %eax
f0101952:	68 8a 02 00 00       	push   $0x28a
f0101957:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010195d:	50                   	push   %eax
f010195e:	e8 36 e7 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101963:	8d 83 85 cf fe ff    	lea    -0x1307b(%ebx),%eax
f0101969:	50                   	push   %eax
f010196a:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0101970:	50                   	push   %eax
f0101971:	68 8b 02 00 00       	push   $0x28b
f0101976:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010197c:	50                   	push   %eax
f010197d:	e8 17 e7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0101982:	8d 83 a2 cf fe ff    	lea    -0x1305e(%ebx),%eax
f0101988:	50                   	push   %eax
f0101989:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f010198f:	50                   	push   %eax
f0101990:	68 92 02 00 00       	push   $0x292
f0101995:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010199b:	50                   	push   %eax
f010199c:	e8 f8 e6 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f01019a1:	8d 83 f7 ce fe ff    	lea    -0x13109(%ebx),%eax
f01019a7:	50                   	push   %eax
f01019a8:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01019ae:	50                   	push   %eax
f01019af:	68 99 02 00 00       	push   $0x299
f01019b4:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01019ba:	50                   	push   %eax
f01019bb:	e8 d9 e6 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f01019c0:	8d 83 0d cf fe ff    	lea    -0x130f3(%ebx),%eax
f01019c6:	50                   	push   %eax
f01019c7:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01019cd:	50                   	push   %eax
f01019ce:	68 9a 02 00 00       	push   $0x29a
f01019d3:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01019d9:	50                   	push   %eax
f01019da:	e8 ba e6 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01019df:	8d 83 23 cf fe ff    	lea    -0x130dd(%ebx),%eax
f01019e5:	50                   	push   %eax
f01019e6:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01019ec:	50                   	push   %eax
f01019ed:	68 9b 02 00 00       	push   $0x29b
f01019f2:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01019f8:	50                   	push   %eax
f01019f9:	e8 9b e6 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01019fe:	8d 83 39 cf fe ff    	lea    -0x130c7(%ebx),%eax
f0101a04:	50                   	push   %eax
f0101a05:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0101a0b:	50                   	push   %eax
f0101a0c:	68 9d 02 00 00       	push   $0x29d
f0101a11:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0101a17:	50                   	push   %eax
f0101a18:	e8 7c e6 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a1d:	8d 83 f8 c7 fe ff    	lea    -0x13808(%ebx),%eax
f0101a23:	50                   	push   %eax
f0101a24:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0101a2a:	50                   	push   %eax
f0101a2b:	68 9e 02 00 00       	push   $0x29e
f0101a30:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0101a36:	50                   	push   %eax
f0101a37:	e8 5d e6 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0101a3c:	8d 83 a2 cf fe ff    	lea    -0x1305e(%ebx),%eax
f0101a42:	50                   	push   %eax
f0101a43:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0101a49:	50                   	push   %eax
f0101a4a:	68 9f 02 00 00       	push   $0x29f
f0101a4f:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0101a55:	50                   	push   %eax
f0101a56:	e8 3e e6 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a5b:	50                   	push   %eax
f0101a5c:	8d 83 34 c6 fe ff    	lea    -0x139cc(%ebx),%eax
f0101a62:	50                   	push   %eax
f0101a63:	6a 52                	push   $0x52
f0101a65:	8d 83 19 ce fe ff    	lea    -0x131e7(%ebx),%eax
f0101a6b:	50                   	push   %eax
f0101a6c:	e8 28 e6 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101a71:	8d 83 b1 cf fe ff    	lea    -0x1304f(%ebx),%eax
f0101a77:	50                   	push   %eax
f0101a78:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0101a7e:	50                   	push   %eax
f0101a7f:	68 a4 02 00 00       	push   $0x2a4
f0101a84:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0101a8a:	50                   	push   %eax
f0101a8b:	e8 09 e6 ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f0101a90:	8d 83 cf cf fe ff    	lea    -0x13031(%ebx),%eax
f0101a96:	50                   	push   %eax
f0101a97:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0101a9d:	50                   	push   %eax
f0101a9e:	68 a5 02 00 00       	push   $0x2a5
f0101aa3:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0101aa9:	50                   	push   %eax
f0101aaa:	e8 ea e5 ff ff       	call   f0100099 <_panic>
f0101aaf:	52                   	push   %edx
f0101ab0:	8d 83 34 c6 fe ff    	lea    -0x139cc(%ebx),%eax
f0101ab6:	50                   	push   %eax
f0101ab7:	6a 52                	push   $0x52
f0101ab9:	8d 83 19 ce fe ff    	lea    -0x131e7(%ebx),%eax
f0101abf:	50                   	push   %eax
f0101ac0:	e8 d4 e5 ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f0101ac5:	8d 83 df cf fe ff    	lea    -0x13021(%ebx),%eax
f0101acb:	50                   	push   %eax
f0101acc:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0101ad2:	50                   	push   %eax
f0101ad3:	68 a8 02 00 00       	push   $0x2a8
f0101ad8:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0101ade:	50                   	push   %eax
f0101adf:	e8 b5 e5 ff ff       	call   f0100099 <_panic>
		--nfree;
f0101ae4:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101ae7:	8b 00                	mov    (%eax),%eax
f0101ae9:	85 c0                	test   %eax,%eax
f0101aeb:	75 f7                	jne    f0101ae4 <mem_init+0x5dd>
	assert(nfree == 0);
f0101aed:	85 f6                	test   %esi,%esi
f0101aef:	0f 85 41 08 00 00    	jne    f0102336 <mem_init+0xe2f>
	cprintf("check_page_alloc() succeeded!\n");
f0101af5:	83 ec 0c             	sub    $0xc,%esp
f0101af8:	8d 83 18 c8 fe ff    	lea    -0x137e8(%ebx),%eax
f0101afe:	50                   	push   %eax
f0101aff:	e8 c5 16 00 00       	call   f01031c9 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101b04:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b0b:	e8 60 f6 ff ff       	call   f0101170 <page_alloc>
f0101b10:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101b13:	83 c4 10             	add    $0x10,%esp
f0101b16:	85 c0                	test   %eax,%eax
f0101b18:	0f 84 37 08 00 00    	je     f0102355 <mem_init+0xe4e>
	assert((pp1 = page_alloc(0)));
f0101b1e:	83 ec 0c             	sub    $0xc,%esp
f0101b21:	6a 00                	push   $0x0
f0101b23:	e8 48 f6 ff ff       	call   f0101170 <page_alloc>
f0101b28:	89 c7                	mov    %eax,%edi
f0101b2a:	83 c4 10             	add    $0x10,%esp
f0101b2d:	85 c0                	test   %eax,%eax
f0101b2f:	0f 84 3f 08 00 00    	je     f0102374 <mem_init+0xe6d>
	assert((pp2 = page_alloc(0)));
f0101b35:	83 ec 0c             	sub    $0xc,%esp
f0101b38:	6a 00                	push   $0x0
f0101b3a:	e8 31 f6 ff ff       	call   f0101170 <page_alloc>
f0101b3f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b42:	83 c4 10             	add    $0x10,%esp
f0101b45:	85 c0                	test   %eax,%eax
f0101b47:	0f 84 46 08 00 00    	je     f0102393 <mem_init+0xe8c>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101b4d:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f0101b50:	0f 84 5c 08 00 00    	je     f01023b2 <mem_init+0xeab>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101b56:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b59:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101b5c:	0f 84 6f 08 00 00    	je     f01023d1 <mem_init+0xeca>
f0101b62:	39 c7                	cmp    %eax,%edi
f0101b64:	0f 84 67 08 00 00    	je     f01023d1 <mem_init+0xeca>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101b6a:	8b 83 b4 1f 00 00    	mov    0x1fb4(%ebx),%eax
f0101b70:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	page_free_list = 0;
f0101b73:	c7 83 b4 1f 00 00 00 	movl   $0x0,0x1fb4(%ebx)
f0101b7a:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101b7d:	83 ec 0c             	sub    $0xc,%esp
f0101b80:	6a 00                	push   $0x0
f0101b82:	e8 e9 f5 ff ff       	call   f0101170 <page_alloc>
f0101b87:	83 c4 10             	add    $0x10,%esp
f0101b8a:	85 c0                	test   %eax,%eax
f0101b8c:	0f 85 5e 08 00 00    	jne    f01023f0 <mem_init+0xee9>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101b92:	83 ec 04             	sub    $0x4,%esp
f0101b95:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101b98:	50                   	push   %eax
f0101b99:	6a 00                	push   $0x0
f0101b9b:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101ba1:	ff 30                	pushl  (%eax)
f0101ba3:	e8 ff f7 ff ff       	call   f01013a7 <page_lookup>
f0101ba8:	83 c4 10             	add    $0x10,%esp
f0101bab:	85 c0                	test   %eax,%eax
f0101bad:	0f 85 5c 08 00 00    	jne    f010240f <mem_init+0xf08>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101bb3:	6a 02                	push   $0x2
f0101bb5:	6a 00                	push   $0x0
f0101bb7:	57                   	push   %edi
f0101bb8:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101bbe:	ff 30                	pushl  (%eax)
f0101bc0:	e8 9b f8 ff ff       	call   f0101460 <page_insert>
f0101bc5:	83 c4 10             	add    $0x10,%esp
f0101bc8:	85 c0                	test   %eax,%eax
f0101bca:	0f 89 5e 08 00 00    	jns    f010242e <mem_init+0xf27>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101bd0:	83 ec 0c             	sub    $0xc,%esp
f0101bd3:	ff 75 d0             	pushl  -0x30(%ebp)
f0101bd6:	e8 1d f6 ff ff       	call   f01011f8 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101bdb:	6a 02                	push   $0x2
f0101bdd:	6a 00                	push   $0x0
f0101bdf:	57                   	push   %edi
f0101be0:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101be6:	ff 30                	pushl  (%eax)
f0101be8:	e8 73 f8 ff ff       	call   f0101460 <page_insert>
f0101bed:	83 c4 20             	add    $0x20,%esp
f0101bf0:	85 c0                	test   %eax,%eax
f0101bf2:	0f 85 55 08 00 00    	jne    f010244d <mem_init+0xf46>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101bf8:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101bfe:	8b 08                	mov    (%eax),%ecx
f0101c00:	89 ce                	mov    %ecx,%esi
	return (pp - pages) << PGSHIFT;
f0101c02:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0101c08:	8b 00                	mov    (%eax),%eax
f0101c0a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c0d:	8b 09                	mov    (%ecx),%ecx
f0101c0f:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0101c12:	89 ca                	mov    %ecx,%edx
f0101c14:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101c1a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101c1d:	29 c1                	sub    %eax,%ecx
f0101c1f:	89 c8                	mov    %ecx,%eax
f0101c21:	c1 f8 03             	sar    $0x3,%eax
f0101c24:	c1 e0 0c             	shl    $0xc,%eax
f0101c27:	39 c2                	cmp    %eax,%edx
f0101c29:	0f 85 3d 08 00 00    	jne    f010246c <mem_init+0xf65>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101c2f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c34:	89 f0                	mov    %esi,%eax
f0101c36:	e8 4a f0 ff ff       	call   f0100c85 <check_va2pa>
f0101c3b:	89 fa                	mov    %edi,%edx
f0101c3d:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101c40:	c1 fa 03             	sar    $0x3,%edx
f0101c43:	c1 e2 0c             	shl    $0xc,%edx
f0101c46:	39 d0                	cmp    %edx,%eax
f0101c48:	0f 85 3d 08 00 00    	jne    f010248b <mem_init+0xf84>
	assert(pp1->pp_ref == 1);
f0101c4e:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101c53:	0f 85 51 08 00 00    	jne    f01024aa <mem_init+0xfa3>
	assert(pp0->pp_ref == 1);
f0101c59:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c5c:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c61:	0f 85 62 08 00 00    	jne    f01024c9 <mem_init+0xfc2>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c67:	6a 02                	push   $0x2
f0101c69:	68 00 10 00 00       	push   $0x1000
f0101c6e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c71:	56                   	push   %esi
f0101c72:	e8 e9 f7 ff ff       	call   f0101460 <page_insert>
f0101c77:	83 c4 10             	add    $0x10,%esp
f0101c7a:	85 c0                	test   %eax,%eax
f0101c7c:	0f 85 66 08 00 00    	jne    f01024e8 <mem_init+0xfe1>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c82:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c87:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101c8d:	8b 00                	mov    (%eax),%eax
f0101c8f:	e8 f1 ef ff ff       	call   f0100c85 <check_va2pa>
f0101c94:	c7 c2 d0 a6 11 f0    	mov    $0xf011a6d0,%edx
f0101c9a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101c9d:	2b 0a                	sub    (%edx),%ecx
f0101c9f:	89 ca                	mov    %ecx,%edx
f0101ca1:	c1 fa 03             	sar    $0x3,%edx
f0101ca4:	c1 e2 0c             	shl    $0xc,%edx
f0101ca7:	39 d0                	cmp    %edx,%eax
f0101ca9:	0f 85 58 08 00 00    	jne    f0102507 <mem_init+0x1000>
	assert(pp2->pp_ref == 1);
f0101caf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cb2:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101cb7:	0f 85 69 08 00 00    	jne    f0102526 <mem_init+0x101f>

	// should be no free memory
	assert(!page_alloc(0));
f0101cbd:	83 ec 0c             	sub    $0xc,%esp
f0101cc0:	6a 00                	push   $0x0
f0101cc2:	e8 a9 f4 ff ff       	call   f0101170 <page_alloc>
f0101cc7:	83 c4 10             	add    $0x10,%esp
f0101cca:	85 c0                	test   %eax,%eax
f0101ccc:	0f 85 73 08 00 00    	jne    f0102545 <mem_init+0x103e>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101cd2:	6a 02                	push   $0x2
f0101cd4:	68 00 10 00 00       	push   $0x1000
f0101cd9:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101cdc:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101ce2:	ff 30                	pushl  (%eax)
f0101ce4:	e8 77 f7 ff ff       	call   f0101460 <page_insert>
f0101ce9:	83 c4 10             	add    $0x10,%esp
f0101cec:	85 c0                	test   %eax,%eax
f0101cee:	0f 85 70 08 00 00    	jne    f0102564 <mem_init+0x105d>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cf4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cf9:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101cff:	8b 00                	mov    (%eax),%eax
f0101d01:	e8 7f ef ff ff       	call   f0100c85 <check_va2pa>
f0101d06:	c7 c2 d0 a6 11 f0    	mov    $0xf011a6d0,%edx
f0101d0c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101d0f:	2b 0a                	sub    (%edx),%ecx
f0101d11:	89 ca                	mov    %ecx,%edx
f0101d13:	c1 fa 03             	sar    $0x3,%edx
f0101d16:	c1 e2 0c             	shl    $0xc,%edx
f0101d19:	39 d0                	cmp    %edx,%eax
f0101d1b:	0f 85 62 08 00 00    	jne    f0102583 <mem_init+0x107c>
	assert(pp2->pp_ref == 1);
f0101d21:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d24:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101d29:	0f 85 73 08 00 00    	jne    f01025a2 <mem_init+0x109b>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101d2f:	83 ec 0c             	sub    $0xc,%esp
f0101d32:	6a 00                	push   $0x0
f0101d34:	e8 37 f4 ff ff       	call   f0101170 <page_alloc>
f0101d39:	83 c4 10             	add    $0x10,%esp
f0101d3c:	85 c0                	test   %eax,%eax
f0101d3e:	0f 85 7d 08 00 00    	jne    f01025c1 <mem_init+0x10ba>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d44:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101d4a:	8b 10                	mov    (%eax),%edx
f0101d4c:	8b 02                	mov    (%edx),%eax
f0101d4e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101d53:	89 c1                	mov    %eax,%ecx
f0101d55:	c1 e9 0c             	shr    $0xc,%ecx
f0101d58:	89 ce                	mov    %ecx,%esi
f0101d5a:	c7 c1 c8 a6 11 f0    	mov    $0xf011a6c8,%ecx
f0101d60:	3b 31                	cmp    (%ecx),%esi
f0101d62:	0f 83 78 08 00 00    	jae    f01025e0 <mem_init+0x10d9>
	return (void *)(pa + KERNBASE);
f0101d68:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d6d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d70:	83 ec 04             	sub    $0x4,%esp
f0101d73:	6a 00                	push   $0x0
f0101d75:	68 00 10 00 00       	push   $0x1000
f0101d7a:	52                   	push   %edx
f0101d7b:	e8 f0 f4 ff ff       	call   f0101270 <pgdir_walk>
f0101d80:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d83:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d86:	83 c4 10             	add    $0x10,%esp
f0101d89:	39 d0                	cmp    %edx,%eax
f0101d8b:	0f 85 68 08 00 00    	jne    f01025f9 <mem_init+0x10f2>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d91:	6a 06                	push   $0x6
f0101d93:	68 00 10 00 00       	push   $0x1000
f0101d98:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101d9b:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101da1:	ff 30                	pushl  (%eax)
f0101da3:	e8 b8 f6 ff ff       	call   f0101460 <page_insert>
f0101da8:	83 c4 10             	add    $0x10,%esp
f0101dab:	85 c0                	test   %eax,%eax
f0101dad:	0f 85 65 08 00 00    	jne    f0102618 <mem_init+0x1111>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101db3:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101db9:	8b 00                	mov    (%eax),%eax
f0101dbb:	89 c6                	mov    %eax,%esi
f0101dbd:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dc2:	e8 be ee ff ff       	call   f0100c85 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101dc7:	c7 c2 d0 a6 11 f0    	mov    $0xf011a6d0,%edx
f0101dcd:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101dd0:	2b 0a                	sub    (%edx),%ecx
f0101dd2:	89 ca                	mov    %ecx,%edx
f0101dd4:	c1 fa 03             	sar    $0x3,%edx
f0101dd7:	c1 e2 0c             	shl    $0xc,%edx
f0101dda:	39 d0                	cmp    %edx,%eax
f0101ddc:	0f 85 55 08 00 00    	jne    f0102637 <mem_init+0x1130>
	assert(pp2->pp_ref == 1);
f0101de2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101de5:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101dea:	0f 85 66 08 00 00    	jne    f0102656 <mem_init+0x114f>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101df0:	83 ec 04             	sub    $0x4,%esp
f0101df3:	6a 00                	push   $0x0
f0101df5:	68 00 10 00 00       	push   $0x1000
f0101dfa:	56                   	push   %esi
f0101dfb:	e8 70 f4 ff ff       	call   f0101270 <pgdir_walk>
f0101e00:	83 c4 10             	add    $0x10,%esp
f0101e03:	f6 00 04             	testb  $0x4,(%eax)
f0101e06:	0f 84 69 08 00 00    	je     f0102675 <mem_init+0x116e>
	assert(kern_pgdir[0] & PTE_U);
f0101e0c:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101e12:	8b 00                	mov    (%eax),%eax
f0101e14:	f6 00 04             	testb  $0x4,(%eax)
f0101e17:	0f 84 77 08 00 00    	je     f0102694 <mem_init+0x118d>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e1d:	6a 02                	push   $0x2
f0101e1f:	68 00 10 00 00       	push   $0x1000
f0101e24:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101e27:	50                   	push   %eax
f0101e28:	e8 33 f6 ff ff       	call   f0101460 <page_insert>
f0101e2d:	83 c4 10             	add    $0x10,%esp
f0101e30:	85 c0                	test   %eax,%eax
f0101e32:	0f 85 7b 08 00 00    	jne    f01026b3 <mem_init+0x11ac>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101e38:	83 ec 04             	sub    $0x4,%esp
f0101e3b:	6a 00                	push   $0x0
f0101e3d:	68 00 10 00 00       	push   $0x1000
f0101e42:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101e48:	ff 30                	pushl  (%eax)
f0101e4a:	e8 21 f4 ff ff       	call   f0101270 <pgdir_walk>
f0101e4f:	83 c4 10             	add    $0x10,%esp
f0101e52:	f6 00 02             	testb  $0x2,(%eax)
f0101e55:	0f 84 77 08 00 00    	je     f01026d2 <mem_init+0x11cb>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e5b:	83 ec 04             	sub    $0x4,%esp
f0101e5e:	6a 00                	push   $0x0
f0101e60:	68 00 10 00 00       	push   $0x1000
f0101e65:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101e6b:	ff 30                	pushl  (%eax)
f0101e6d:	e8 fe f3 ff ff       	call   f0101270 <pgdir_walk>
f0101e72:	83 c4 10             	add    $0x10,%esp
f0101e75:	f6 00 04             	testb  $0x4,(%eax)
f0101e78:	0f 85 73 08 00 00    	jne    f01026f1 <mem_init+0x11ea>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101e7e:	6a 02                	push   $0x2
f0101e80:	68 00 00 40 00       	push   $0x400000
f0101e85:	ff 75 d0             	pushl  -0x30(%ebp)
f0101e88:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101e8e:	ff 30                	pushl  (%eax)
f0101e90:	e8 cb f5 ff ff       	call   f0101460 <page_insert>
f0101e95:	83 c4 10             	add    $0x10,%esp
f0101e98:	85 c0                	test   %eax,%eax
f0101e9a:	0f 89 70 08 00 00    	jns    f0102710 <mem_init+0x1209>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101ea0:	6a 02                	push   $0x2
f0101ea2:	68 00 10 00 00       	push   $0x1000
f0101ea7:	57                   	push   %edi
f0101ea8:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101eae:	ff 30                	pushl  (%eax)
f0101eb0:	e8 ab f5 ff ff       	call   f0101460 <page_insert>
f0101eb5:	83 c4 10             	add    $0x10,%esp
f0101eb8:	85 c0                	test   %eax,%eax
f0101eba:	0f 85 6f 08 00 00    	jne    f010272f <mem_init+0x1228>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ec0:	83 ec 04             	sub    $0x4,%esp
f0101ec3:	6a 00                	push   $0x0
f0101ec5:	68 00 10 00 00       	push   $0x1000
f0101eca:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101ed0:	ff 30                	pushl  (%eax)
f0101ed2:	e8 99 f3 ff ff       	call   f0101270 <pgdir_walk>
f0101ed7:	83 c4 10             	add    $0x10,%esp
f0101eda:	f6 00 04             	testb  $0x4,(%eax)
f0101edd:	0f 85 6b 08 00 00    	jne    f010274e <mem_init+0x1247>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ee3:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101ee9:	8b 00                	mov    (%eax),%eax
f0101eeb:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101eee:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ef3:	e8 8d ed ff ff       	call   f0100c85 <check_va2pa>
f0101ef8:	89 c6                	mov    %eax,%esi
f0101efa:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0101f00:	89 f9                	mov    %edi,%ecx
f0101f02:	2b 08                	sub    (%eax),%ecx
f0101f04:	89 c8                	mov    %ecx,%eax
f0101f06:	c1 f8 03             	sar    $0x3,%eax
f0101f09:	c1 e0 0c             	shl    $0xc,%eax
f0101f0c:	39 c6                	cmp    %eax,%esi
f0101f0e:	0f 85 59 08 00 00    	jne    f010276d <mem_init+0x1266>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f14:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f19:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f1c:	e8 64 ed ff ff       	call   f0100c85 <check_va2pa>
f0101f21:	39 c6                	cmp    %eax,%esi
f0101f23:	0f 85 63 08 00 00    	jne    f010278c <mem_init+0x1285>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101f29:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101f2e:	0f 85 77 08 00 00    	jne    f01027ab <mem_init+0x12a4>
	assert(pp2->pp_ref == 0);
f0101f34:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f37:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101f3c:	0f 85 88 08 00 00    	jne    f01027ca <mem_init+0x12c3>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101f42:	83 ec 0c             	sub    $0xc,%esp
f0101f45:	6a 00                	push   $0x0
f0101f47:	e8 24 f2 ff ff       	call   f0101170 <page_alloc>
f0101f4c:	83 c4 10             	add    $0x10,%esp
f0101f4f:	85 c0                	test   %eax,%eax
f0101f51:	0f 84 92 08 00 00    	je     f01027e9 <mem_init+0x12e2>
f0101f57:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101f5a:	0f 85 89 08 00 00    	jne    f01027e9 <mem_init+0x12e2>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f60:	83 ec 08             	sub    $0x8,%esp
f0101f63:	6a 00                	push   $0x0
f0101f65:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101f6b:	89 c6                	mov    %eax,%esi
f0101f6d:	ff 30                	pushl  (%eax)
f0101f6f:	e8 af f4 ff ff       	call   f0101423 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f74:	8b 06                	mov    (%esi),%eax
f0101f76:	89 c6                	mov    %eax,%esi
f0101f78:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f7d:	e8 03 ed ff ff       	call   f0100c85 <check_va2pa>
f0101f82:	83 c4 10             	add    $0x10,%esp
f0101f85:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f88:	0f 85 7a 08 00 00    	jne    f0102808 <mem_init+0x1301>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f8e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f93:	89 f0                	mov    %esi,%eax
f0101f95:	e8 eb ec ff ff       	call   f0100c85 <check_va2pa>
f0101f9a:	c7 c2 d0 a6 11 f0    	mov    $0xf011a6d0,%edx
f0101fa0:	89 f9                	mov    %edi,%ecx
f0101fa2:	2b 0a                	sub    (%edx),%ecx
f0101fa4:	89 ca                	mov    %ecx,%edx
f0101fa6:	c1 fa 03             	sar    $0x3,%edx
f0101fa9:	c1 e2 0c             	shl    $0xc,%edx
f0101fac:	39 d0                	cmp    %edx,%eax
f0101fae:	0f 85 73 08 00 00    	jne    f0102827 <mem_init+0x1320>
	assert(pp1->pp_ref == 1);
f0101fb4:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101fb9:	0f 85 87 08 00 00    	jne    f0102846 <mem_init+0x133f>
	assert(pp2->pp_ref == 0);
f0101fbf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fc2:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101fc7:	0f 85 98 08 00 00    	jne    f0102865 <mem_init+0x135e>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101fcd:	6a 00                	push   $0x0
f0101fcf:	68 00 10 00 00       	push   $0x1000
f0101fd4:	57                   	push   %edi
f0101fd5:	56                   	push   %esi
f0101fd6:	e8 85 f4 ff ff       	call   f0101460 <page_insert>
f0101fdb:	83 c4 10             	add    $0x10,%esp
f0101fde:	85 c0                	test   %eax,%eax
f0101fe0:	0f 85 9e 08 00 00    	jne    f0102884 <mem_init+0x137d>
	assert(pp1->pp_ref);
f0101fe6:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101feb:	0f 84 b2 08 00 00    	je     f01028a3 <mem_init+0x139c>
	assert(pp1->pp_link == NULL);
f0101ff1:	83 3f 00             	cmpl   $0x0,(%edi)
f0101ff4:	0f 85 c8 08 00 00    	jne    f01028c2 <mem_init+0x13bb>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101ffa:	83 ec 08             	sub    $0x8,%esp
f0101ffd:	68 00 10 00 00       	push   $0x1000
f0102002:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102008:	89 c6                	mov    %eax,%esi
f010200a:	ff 30                	pushl  (%eax)
f010200c:	e8 12 f4 ff ff       	call   f0101423 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102011:	8b 06                	mov    (%esi),%eax
f0102013:	89 c6                	mov    %eax,%esi
f0102015:	ba 00 00 00 00       	mov    $0x0,%edx
f010201a:	e8 66 ec ff ff       	call   f0100c85 <check_va2pa>
f010201f:	83 c4 10             	add    $0x10,%esp
f0102022:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102025:	0f 85 b6 08 00 00    	jne    f01028e1 <mem_init+0x13da>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010202b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102030:	89 f0                	mov    %esi,%eax
f0102032:	e8 4e ec ff ff       	call   f0100c85 <check_va2pa>
f0102037:	89 45 c0             	mov    %eax,-0x40(%ebp)
f010203a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010203d:	0f 85 bd 08 00 00    	jne    f0102900 <mem_init+0x13f9>
	assert(pp1->pp_ref == 0);
f0102043:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102048:	0f 85 d1 08 00 00    	jne    f010291f <mem_init+0x1418>
	assert(pp2->pp_ref == 0);
f010204e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102051:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102056:	0f 85 e2 08 00 00    	jne    f010293e <mem_init+0x1437>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010205c:	83 ec 0c             	sub    $0xc,%esp
f010205f:	6a 00                	push   $0x0
f0102061:	e8 0a f1 ff ff       	call   f0101170 <page_alloc>
f0102066:	83 c4 10             	add    $0x10,%esp
f0102069:	85 c0                	test   %eax,%eax
f010206b:	0f 84 ec 08 00 00    	je     f010295d <mem_init+0x1456>
f0102071:	39 c7                	cmp    %eax,%edi
f0102073:	0f 85 e4 08 00 00    	jne    f010295d <mem_init+0x1456>

	// should be no free memory
	assert(!page_alloc(0));
f0102079:	83 ec 0c             	sub    $0xc,%esp
f010207c:	6a 00                	push   $0x0
f010207e:	e8 ed f0 ff ff       	call   f0101170 <page_alloc>
f0102083:	83 c4 10             	add    $0x10,%esp
f0102086:	85 c0                	test   %eax,%eax
f0102088:	0f 85 ee 08 00 00    	jne    f010297c <mem_init+0x1475>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010208e:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102094:	8b 08                	mov    (%eax),%ecx
f0102096:	8b 11                	mov    (%ecx),%edx
f0102098:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010209e:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f01020a4:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01020a7:	2b 30                	sub    (%eax),%esi
f01020a9:	89 f0                	mov    %esi,%eax
f01020ab:	c1 f8 03             	sar    $0x3,%eax
f01020ae:	c1 e0 0c             	shl    $0xc,%eax
f01020b1:	39 c2                	cmp    %eax,%edx
f01020b3:	0f 85 e2 08 00 00    	jne    f010299b <mem_init+0x1494>
	kern_pgdir[0] = 0;
f01020b9:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01020bf:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01020c2:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01020c7:	0f 85 ed 08 00 00    	jne    f01029ba <mem_init+0x14b3>
	pp0->pp_ref = 0;
f01020cd:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01020d0:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01020d6:	83 ec 0c             	sub    $0xc,%esp
f01020d9:	50                   	push   %eax
f01020da:	e8 19 f1 ff ff       	call   f01011f8 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01020df:	83 c4 0c             	add    $0xc,%esp
f01020e2:	6a 01                	push   $0x1
f01020e4:	68 00 10 40 00       	push   $0x401000
f01020e9:	c7 c6 cc a6 11 f0    	mov    $0xf011a6cc,%esi
f01020ef:	ff 36                	pushl  (%esi)
f01020f1:	e8 7a f1 ff ff       	call   f0101270 <pgdir_walk>
f01020f6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01020f9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01020fc:	8b 0e                	mov    (%esi),%ecx
f01020fe:	8b 51 04             	mov    0x4(%ecx),%edx
f0102101:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0102107:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f010210d:	8b 30                	mov    (%eax),%esi
f010210f:	89 d0                	mov    %edx,%eax
f0102111:	c1 e8 0c             	shr    $0xc,%eax
f0102114:	83 c4 10             	add    $0x10,%esp
f0102117:	39 f0                	cmp    %esi,%eax
f0102119:	0f 83 ba 08 00 00    	jae    f01029d9 <mem_init+0x14d2>
	assert(ptep == ptep1 + PTX(va));
f010211f:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102125:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f0102128:	0f 85 c4 08 00 00    	jne    f01029f2 <mem_init+0x14eb>
	kern_pgdir[PDX(va)] = 0;
f010212e:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0102135:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102138:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
	return (pp - pages) << PGSHIFT;
f010213e:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0102144:	2b 08                	sub    (%eax),%ecx
f0102146:	89 c8                	mov    %ecx,%eax
f0102148:	c1 f8 03             	sar    $0x3,%eax
f010214b:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010214e:	89 c2                	mov    %eax,%edx
f0102150:	c1 ea 0c             	shr    $0xc,%edx
f0102153:	39 d6                	cmp    %edx,%esi
f0102155:	0f 86 b6 08 00 00    	jbe    f0102a11 <mem_init+0x150a>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010215b:	83 ec 04             	sub    $0x4,%esp
f010215e:	68 00 10 00 00       	push   $0x1000
f0102163:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0102168:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010216d:	50                   	push   %eax
f010216e:	e8 0a 1e 00 00       	call   f0103f7d <memset>
	page_free(pp0);
f0102173:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102176:	89 34 24             	mov    %esi,(%esp)
f0102179:	e8 7a f0 ff ff       	call   f01011f8 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010217e:	83 c4 0c             	add    $0xc,%esp
f0102181:	6a 01                	push   $0x1
f0102183:	6a 00                	push   $0x0
f0102185:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f010218b:	ff 30                	pushl  (%eax)
f010218d:	e8 de f0 ff ff       	call   f0101270 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0102192:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0102198:	89 f2                	mov    %esi,%edx
f010219a:	2b 10                	sub    (%eax),%edx
f010219c:	c1 fa 03             	sar    $0x3,%edx
f010219f:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01021a2:	89 d1                	mov    %edx,%ecx
f01021a4:	c1 e9 0c             	shr    $0xc,%ecx
f01021a7:	83 c4 10             	add    $0x10,%esp
f01021aa:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f01021b0:	3b 08                	cmp    (%eax),%ecx
f01021b2:	0f 83 6f 08 00 00    	jae    f0102a27 <mem_init+0x1520>
	return (void *)(pa + KERNBASE);
f01021b8:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01021be:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01021c1:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
f01021c7:	8b 75 d4             	mov    -0x2c(%ebp),%esi
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01021ca:	f6 00 01             	testb  $0x1,(%eax)
f01021cd:	0f 85 6a 08 00 00    	jne    f0102a3d <mem_init+0x1536>
f01021d3:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f01021d6:	39 d0                	cmp    %edx,%eax
f01021d8:	75 f0                	jne    f01021ca <mem_init+0xcc3>
	kern_pgdir[0] = 0;
f01021da:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f01021e0:	8b 00                	mov    (%eax),%eax
f01021e2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01021e8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01021eb:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01021f1:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f01021f4:	89 8b b4 1f 00 00    	mov    %ecx,0x1fb4(%ebx)

	// free the pages we took
	page_free(pp0);
f01021fa:	83 ec 0c             	sub    $0xc,%esp
f01021fd:	50                   	push   %eax
f01021fe:	e8 f5 ef ff ff       	call   f01011f8 <page_free>
	page_free(pp1);
f0102203:	89 3c 24             	mov    %edi,(%esp)
f0102206:	e8 ed ef ff ff       	call   f01011f8 <page_free>
	page_free(pp2);
f010220b:	89 34 24             	mov    %esi,(%esp)
f010220e:	e8 e5 ef ff ff       	call   f01011f8 <page_free>

	cprintf("check_page() succeeded!\n");
f0102213:	8d 83 c0 d0 fe ff    	lea    -0x12f40(%ebx),%eax
f0102219:	89 04 24             	mov    %eax,(%esp)
f010221c:	e8 a8 0f 00 00       	call   f01031c9 <cprintf>
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f0102221:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0102227:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102229:	83 c4 10             	add    $0x10,%esp
f010222c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102231:	0f 86 25 08 00 00    	jbe    f0102a5c <mem_init+0x1555>
f0102237:	83 ec 08             	sub    $0x8,%esp
f010223a:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f010223c:	05 00 00 00 10       	add    $0x10000000,%eax
f0102241:	50                   	push   %eax
f0102242:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102247:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010224c:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102252:	8b 00                	mov    (%eax),%eax
f0102254:	e8 c2 f0 ff ff       	call   f010131b <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f0102259:	c7 c0 00 f0 10 f0    	mov    $0xf010f000,%eax
f010225f:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102262:	83 c4 10             	add    $0x10,%esp
f0102265:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010226a:	0f 86 05 08 00 00    	jbe    f0102a75 <mem_init+0x156e>
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102270:	c7 c6 cc a6 11 f0    	mov    $0xf011a6cc,%esi
f0102276:	83 ec 08             	sub    $0x8,%esp
f0102279:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f010227b:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010227e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102283:	50                   	push   %eax
f0102284:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102289:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010228e:	8b 06                	mov    (%esi),%eax
f0102290:	e8 86 f0 ff ff       	call   f010131b <boot_map_region>
	asm volatile("movl %%cr4,%0" : "=r" (cr4));
f0102295:	0f 20 e0             	mov    %cr4,%eax
	cr4 |= CR4_PSE;
f0102298:	83 c8 10             	or     $0x10,%eax
	asm volatile("movl %0,%%cr4" : : "r" (val));
f010229b:	0f 22 e0             	mov    %eax,%cr4
	boot_map_region_large(kern_pgdir, KERNBASE, (uint32_t)-1 - KERNBASE, 0, PTE_W);
f010229e:	8b 36                	mov    (%esi),%esi
f01022a0:	83 c4 10             	add    $0x10,%esp
	va = ROUNDDOWN(va, PTSIZE);
f01022a3:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
		pde_t *pte_ptr = pgdir + PDX(va);
f01022a8:	89 c1                	mov    %eax,%ecx
f01022aa:	c1 e9 16             	shr    $0x16,%ecx
		*pte_ptr = pa | perm | PTE_P | PTE_PS;
f01022ad:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01022b3:	80 ca 83             	or     $0x83,%dl
f01022b6:	89 14 8e             	mov    %edx,(%esi,%ecx,4)
	for (i = 0; i < pgs; i++){
f01022b9:	05 00 00 40 00       	add    $0x400000,%eax
f01022be:	75 e8                	jne    f01022a8 <mem_init+0xda1>
	pgdir = kern_pgdir;
f01022c0:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f01022c6:	8b 30                	mov    (%eax),%esi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01022c8:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f01022ce:	8b 00                	mov    (%eax),%eax
f01022d0:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01022d3:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01022da:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01022df:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01022e2:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f01022e8:	8b 00                	mov    (%eax),%eax
f01022ea:	89 45 bc             	mov    %eax,-0x44(%ebp)
	if ((uint32_t)kva < KERNBASE)
f01022ed:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f01022f0:	05 00 00 00 10       	add    $0x10000000,%eax
	for (i = 0; i < n; i += PGSIZE)
f01022f5:	bf 00 00 00 00       	mov    $0x0,%edi
f01022fa:	89 75 d0             	mov    %esi,-0x30(%ebp)
f01022fd:	89 c6                	mov    %eax,%esi
f01022ff:	39 7d d4             	cmp    %edi,-0x2c(%ebp)
f0102302:	0f 86 c0 07 00 00    	jbe    f0102ac8 <mem_init+0x15c1>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102308:	8d 97 00 00 00 ef    	lea    -0x11000000(%edi),%edx
f010230e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102311:	e8 6f e9 ff ff       	call   f0100c85 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102316:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f010231d:	0f 86 6b 07 00 00    	jbe    f0102a8e <mem_init+0x1587>
f0102323:	8d 14 37             	lea    (%edi,%esi,1),%edx
f0102326:	39 d0                	cmp    %edx,%eax
f0102328:	0f 85 7b 07 00 00    	jne    f0102aa9 <mem_init+0x15a2>
	for (i = 0; i < n; i += PGSIZE)
f010232e:	81 c7 00 10 00 00    	add    $0x1000,%edi
f0102334:	eb c9                	jmp    f01022ff <mem_init+0xdf8>
	assert(nfree == 0);
f0102336:	8d 83 e9 cf fe ff    	lea    -0x13017(%ebx),%eax
f010233c:	50                   	push   %eax
f010233d:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102343:	50                   	push   %eax
f0102344:	68 b5 02 00 00       	push   $0x2b5
f0102349:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010234f:	50                   	push   %eax
f0102350:	e8 44 dd ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102355:	8d 83 f7 ce fe ff    	lea    -0x13109(%ebx),%eax
f010235b:	50                   	push   %eax
f010235c:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102362:	50                   	push   %eax
f0102363:	68 1d 03 00 00       	push   $0x31d
f0102368:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010236e:	50                   	push   %eax
f010236f:	e8 25 dd ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102374:	8d 83 0d cf fe ff    	lea    -0x130f3(%ebx),%eax
f010237a:	50                   	push   %eax
f010237b:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102381:	50                   	push   %eax
f0102382:	68 1e 03 00 00       	push   $0x31e
f0102387:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010238d:	50                   	push   %eax
f010238e:	e8 06 dd ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0102393:	8d 83 23 cf fe ff    	lea    -0x130dd(%ebx),%eax
f0102399:	50                   	push   %eax
f010239a:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01023a0:	50                   	push   %eax
f01023a1:	68 1f 03 00 00       	push   $0x31f
f01023a6:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01023ac:	50                   	push   %eax
f01023ad:	e8 e7 dc ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01023b2:	8d 83 39 cf fe ff    	lea    -0x130c7(%ebx),%eax
f01023b8:	50                   	push   %eax
f01023b9:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01023bf:	50                   	push   %eax
f01023c0:	68 22 03 00 00       	push   $0x322
f01023c5:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01023cb:	50                   	push   %eax
f01023cc:	e8 c8 dc ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01023d1:	8d 83 f8 c7 fe ff    	lea    -0x13808(%ebx),%eax
f01023d7:	50                   	push   %eax
f01023d8:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01023de:	50                   	push   %eax
f01023df:	68 23 03 00 00       	push   $0x323
f01023e4:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01023ea:	50                   	push   %eax
f01023eb:	e8 a9 dc ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01023f0:	8d 83 a2 cf fe ff    	lea    -0x1305e(%ebx),%eax
f01023f6:	50                   	push   %eax
f01023f7:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01023fd:	50                   	push   %eax
f01023fe:	68 2a 03 00 00       	push   $0x32a
f0102403:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102409:	50                   	push   %eax
f010240a:	e8 8a dc ff ff       	call   f0100099 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010240f:	8d 83 38 c8 fe ff    	lea    -0x137c8(%ebx),%eax
f0102415:	50                   	push   %eax
f0102416:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f010241c:	50                   	push   %eax
f010241d:	68 2d 03 00 00       	push   $0x32d
f0102422:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102428:	50                   	push   %eax
f0102429:	e8 6b dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010242e:	8d 83 70 c8 fe ff    	lea    -0x13790(%ebx),%eax
f0102434:	50                   	push   %eax
f0102435:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f010243b:	50                   	push   %eax
f010243c:	68 30 03 00 00       	push   $0x330
f0102441:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102447:	50                   	push   %eax
f0102448:	e8 4c dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010244d:	8d 83 a0 c8 fe ff    	lea    -0x13760(%ebx),%eax
f0102453:	50                   	push   %eax
f0102454:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f010245a:	50                   	push   %eax
f010245b:	68 34 03 00 00       	push   $0x334
f0102460:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102466:	50                   	push   %eax
f0102467:	e8 2d dc ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010246c:	8d 83 d0 c8 fe ff    	lea    -0x13730(%ebx),%eax
f0102472:	50                   	push   %eax
f0102473:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102479:	50                   	push   %eax
f010247a:	68 35 03 00 00       	push   $0x335
f010247f:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102485:	50                   	push   %eax
f0102486:	e8 0e dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010248b:	8d 83 f8 c8 fe ff    	lea    -0x13708(%ebx),%eax
f0102491:	50                   	push   %eax
f0102492:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102498:	50                   	push   %eax
f0102499:	68 36 03 00 00       	push   $0x336
f010249e:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01024a4:	50                   	push   %eax
f01024a5:	e8 ef db ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01024aa:	8d 83 f4 cf fe ff    	lea    -0x1300c(%ebx),%eax
f01024b0:	50                   	push   %eax
f01024b1:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01024b7:	50                   	push   %eax
f01024b8:	68 37 03 00 00       	push   $0x337
f01024bd:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01024c3:	50                   	push   %eax
f01024c4:	e8 d0 db ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f01024c9:	8d 83 05 d0 fe ff    	lea    -0x12ffb(%ebx),%eax
f01024cf:	50                   	push   %eax
f01024d0:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01024d6:	50                   	push   %eax
f01024d7:	68 38 03 00 00       	push   $0x338
f01024dc:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01024e2:	50                   	push   %eax
f01024e3:	e8 b1 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01024e8:	8d 83 28 c9 fe ff    	lea    -0x136d8(%ebx),%eax
f01024ee:	50                   	push   %eax
f01024ef:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01024f5:	50                   	push   %eax
f01024f6:	68 3b 03 00 00       	push   $0x33b
f01024fb:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102501:	50                   	push   %eax
f0102502:	e8 92 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102507:	8d 83 64 c9 fe ff    	lea    -0x1369c(%ebx),%eax
f010250d:	50                   	push   %eax
f010250e:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102514:	50                   	push   %eax
f0102515:	68 3c 03 00 00       	push   $0x33c
f010251a:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102520:	50                   	push   %eax
f0102521:	e8 73 db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102526:	8d 83 16 d0 fe ff    	lea    -0x12fea(%ebx),%eax
f010252c:	50                   	push   %eax
f010252d:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102533:	50                   	push   %eax
f0102534:	68 3d 03 00 00       	push   $0x33d
f0102539:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010253f:	50                   	push   %eax
f0102540:	e8 54 db ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102545:	8d 83 a2 cf fe ff    	lea    -0x1305e(%ebx),%eax
f010254b:	50                   	push   %eax
f010254c:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102552:	50                   	push   %eax
f0102553:	68 40 03 00 00       	push   $0x340
f0102558:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010255e:	50                   	push   %eax
f010255f:	e8 35 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102564:	8d 83 28 c9 fe ff    	lea    -0x136d8(%ebx),%eax
f010256a:	50                   	push   %eax
f010256b:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102571:	50                   	push   %eax
f0102572:	68 43 03 00 00       	push   $0x343
f0102577:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010257d:	50                   	push   %eax
f010257e:	e8 16 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102583:	8d 83 64 c9 fe ff    	lea    -0x1369c(%ebx),%eax
f0102589:	50                   	push   %eax
f010258a:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102590:	50                   	push   %eax
f0102591:	68 44 03 00 00       	push   $0x344
f0102596:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010259c:	50                   	push   %eax
f010259d:	e8 f7 da ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01025a2:	8d 83 16 d0 fe ff    	lea    -0x12fea(%ebx),%eax
f01025a8:	50                   	push   %eax
f01025a9:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01025af:	50                   	push   %eax
f01025b0:	68 45 03 00 00       	push   $0x345
f01025b5:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01025bb:	50                   	push   %eax
f01025bc:	e8 d8 da ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01025c1:	8d 83 a2 cf fe ff    	lea    -0x1305e(%ebx),%eax
f01025c7:	50                   	push   %eax
f01025c8:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01025ce:	50                   	push   %eax
f01025cf:	68 49 03 00 00       	push   $0x349
f01025d4:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01025da:	50                   	push   %eax
f01025db:	e8 b9 da ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025e0:	50                   	push   %eax
f01025e1:	8d 83 34 c6 fe ff    	lea    -0x139cc(%ebx),%eax
f01025e7:	50                   	push   %eax
f01025e8:	68 4c 03 00 00       	push   $0x34c
f01025ed:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01025f3:	50                   	push   %eax
f01025f4:	e8 a0 da ff ff       	call   f0100099 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01025f9:	8d 83 94 c9 fe ff    	lea    -0x1366c(%ebx),%eax
f01025ff:	50                   	push   %eax
f0102600:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102606:	50                   	push   %eax
f0102607:	68 4d 03 00 00       	push   $0x34d
f010260c:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102612:	50                   	push   %eax
f0102613:	e8 81 da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102618:	8d 83 d4 c9 fe ff    	lea    -0x1362c(%ebx),%eax
f010261e:	50                   	push   %eax
f010261f:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102625:	50                   	push   %eax
f0102626:	68 50 03 00 00       	push   $0x350
f010262b:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102631:	50                   	push   %eax
f0102632:	e8 62 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102637:	8d 83 64 c9 fe ff    	lea    -0x1369c(%ebx),%eax
f010263d:	50                   	push   %eax
f010263e:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102644:	50                   	push   %eax
f0102645:	68 51 03 00 00       	push   $0x351
f010264a:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102650:	50                   	push   %eax
f0102651:	e8 43 da ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102656:	8d 83 16 d0 fe ff    	lea    -0x12fea(%ebx),%eax
f010265c:	50                   	push   %eax
f010265d:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102663:	50                   	push   %eax
f0102664:	68 52 03 00 00       	push   $0x352
f0102669:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010266f:	50                   	push   %eax
f0102670:	e8 24 da ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102675:	8d 83 14 ca fe ff    	lea    -0x135ec(%ebx),%eax
f010267b:	50                   	push   %eax
f010267c:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102682:	50                   	push   %eax
f0102683:	68 53 03 00 00       	push   $0x353
f0102688:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010268e:	50                   	push   %eax
f010268f:	e8 05 da ff ff       	call   f0100099 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102694:	8d 83 27 d0 fe ff    	lea    -0x12fd9(%ebx),%eax
f010269a:	50                   	push   %eax
f010269b:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01026a1:	50                   	push   %eax
f01026a2:	68 54 03 00 00       	push   $0x354
f01026a7:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01026ad:	50                   	push   %eax
f01026ae:	e8 e6 d9 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01026b3:	8d 83 28 c9 fe ff    	lea    -0x136d8(%ebx),%eax
f01026b9:	50                   	push   %eax
f01026ba:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01026c0:	50                   	push   %eax
f01026c1:	68 57 03 00 00       	push   $0x357
f01026c6:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01026cc:	50                   	push   %eax
f01026cd:	e8 c7 d9 ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01026d2:	8d 83 48 ca fe ff    	lea    -0x135b8(%ebx),%eax
f01026d8:	50                   	push   %eax
f01026d9:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01026df:	50                   	push   %eax
f01026e0:	68 58 03 00 00       	push   $0x358
f01026e5:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01026eb:	50                   	push   %eax
f01026ec:	e8 a8 d9 ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01026f1:	8d 83 7c ca fe ff    	lea    -0x13584(%ebx),%eax
f01026f7:	50                   	push   %eax
f01026f8:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01026fe:	50                   	push   %eax
f01026ff:	68 59 03 00 00       	push   $0x359
f0102704:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010270a:	50                   	push   %eax
f010270b:	e8 89 d9 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102710:	8d 83 b4 ca fe ff    	lea    -0x1354c(%ebx),%eax
f0102716:	50                   	push   %eax
f0102717:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f010271d:	50                   	push   %eax
f010271e:	68 5c 03 00 00       	push   $0x35c
f0102723:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102729:	50                   	push   %eax
f010272a:	e8 6a d9 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010272f:	8d 83 ec ca fe ff    	lea    -0x13514(%ebx),%eax
f0102735:	50                   	push   %eax
f0102736:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f010273c:	50                   	push   %eax
f010273d:	68 5f 03 00 00       	push   $0x35f
f0102742:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102748:	50                   	push   %eax
f0102749:	e8 4b d9 ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010274e:	8d 83 7c ca fe ff    	lea    -0x13584(%ebx),%eax
f0102754:	50                   	push   %eax
f0102755:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f010275b:	50                   	push   %eax
f010275c:	68 60 03 00 00       	push   $0x360
f0102761:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102767:	50                   	push   %eax
f0102768:	e8 2c d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010276d:	8d 83 28 cb fe ff    	lea    -0x134d8(%ebx),%eax
f0102773:	50                   	push   %eax
f0102774:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f010277a:	50                   	push   %eax
f010277b:	68 63 03 00 00       	push   $0x363
f0102780:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102786:	50                   	push   %eax
f0102787:	e8 0d d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010278c:	8d 83 54 cb fe ff    	lea    -0x134ac(%ebx),%eax
f0102792:	50                   	push   %eax
f0102793:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102799:	50                   	push   %eax
f010279a:	68 64 03 00 00       	push   $0x364
f010279f:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01027a5:	50                   	push   %eax
f01027a6:	e8 ee d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 2);
f01027ab:	8d 83 3d d0 fe ff    	lea    -0x12fc3(%ebx),%eax
f01027b1:	50                   	push   %eax
f01027b2:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01027b8:	50                   	push   %eax
f01027b9:	68 66 03 00 00       	push   $0x366
f01027be:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01027c4:	50                   	push   %eax
f01027c5:	e8 cf d8 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01027ca:	8d 83 4e d0 fe ff    	lea    -0x12fb2(%ebx),%eax
f01027d0:	50                   	push   %eax
f01027d1:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01027d7:	50                   	push   %eax
f01027d8:	68 67 03 00 00       	push   $0x367
f01027dd:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01027e3:	50                   	push   %eax
f01027e4:	e8 b0 d8 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f01027e9:	8d 83 84 cb fe ff    	lea    -0x1347c(%ebx),%eax
f01027ef:	50                   	push   %eax
f01027f0:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01027f6:	50                   	push   %eax
f01027f7:	68 6a 03 00 00       	push   $0x36a
f01027fc:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102802:	50                   	push   %eax
f0102803:	e8 91 d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102808:	8d 83 a8 cb fe ff    	lea    -0x13458(%ebx),%eax
f010280e:	50                   	push   %eax
f010280f:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102815:	50                   	push   %eax
f0102816:	68 6e 03 00 00       	push   $0x36e
f010281b:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102821:	50                   	push   %eax
f0102822:	e8 72 d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102827:	8d 83 54 cb fe ff    	lea    -0x134ac(%ebx),%eax
f010282d:	50                   	push   %eax
f010282e:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102834:	50                   	push   %eax
f0102835:	68 6f 03 00 00       	push   $0x36f
f010283a:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102840:	50                   	push   %eax
f0102841:	e8 53 d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102846:	8d 83 f4 cf fe ff    	lea    -0x1300c(%ebx),%eax
f010284c:	50                   	push   %eax
f010284d:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102853:	50                   	push   %eax
f0102854:	68 70 03 00 00       	push   $0x370
f0102859:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010285f:	50                   	push   %eax
f0102860:	e8 34 d8 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102865:	8d 83 4e d0 fe ff    	lea    -0x12fb2(%ebx),%eax
f010286b:	50                   	push   %eax
f010286c:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102872:	50                   	push   %eax
f0102873:	68 71 03 00 00       	push   $0x371
f0102878:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010287e:	50                   	push   %eax
f010287f:	e8 15 d8 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102884:	8d 83 cc cb fe ff    	lea    -0x13434(%ebx),%eax
f010288a:	50                   	push   %eax
f010288b:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102891:	50                   	push   %eax
f0102892:	68 74 03 00 00       	push   $0x374
f0102897:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010289d:	50                   	push   %eax
f010289e:	e8 f6 d7 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref);
f01028a3:	8d 83 5f d0 fe ff    	lea    -0x12fa1(%ebx),%eax
f01028a9:	50                   	push   %eax
f01028aa:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01028b0:	50                   	push   %eax
f01028b1:	68 75 03 00 00       	push   $0x375
f01028b6:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01028bc:	50                   	push   %eax
f01028bd:	e8 d7 d7 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_link == NULL);
f01028c2:	8d 83 6b d0 fe ff    	lea    -0x12f95(%ebx),%eax
f01028c8:	50                   	push   %eax
f01028c9:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01028cf:	50                   	push   %eax
f01028d0:	68 76 03 00 00       	push   $0x376
f01028d5:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01028db:	50                   	push   %eax
f01028dc:	e8 b8 d7 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01028e1:	8d 83 a8 cb fe ff    	lea    -0x13458(%ebx),%eax
f01028e7:	50                   	push   %eax
f01028e8:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01028ee:	50                   	push   %eax
f01028ef:	68 7a 03 00 00       	push   $0x37a
f01028f4:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01028fa:	50                   	push   %eax
f01028fb:	e8 99 d7 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102900:	8d 83 04 cc fe ff    	lea    -0x133fc(%ebx),%eax
f0102906:	50                   	push   %eax
f0102907:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f010290d:	50                   	push   %eax
f010290e:	68 7b 03 00 00       	push   $0x37b
f0102913:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102919:	50                   	push   %eax
f010291a:	e8 7a d7 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f010291f:	8d 83 80 d0 fe ff    	lea    -0x12f80(%ebx),%eax
f0102925:	50                   	push   %eax
f0102926:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f010292c:	50                   	push   %eax
f010292d:	68 7c 03 00 00       	push   $0x37c
f0102932:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102938:	50                   	push   %eax
f0102939:	e8 5b d7 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f010293e:	8d 83 4e d0 fe ff    	lea    -0x12fb2(%ebx),%eax
f0102944:	50                   	push   %eax
f0102945:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f010294b:	50                   	push   %eax
f010294c:	68 7d 03 00 00       	push   $0x37d
f0102951:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102957:	50                   	push   %eax
f0102958:	e8 3c d7 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f010295d:	8d 83 2c cc fe ff    	lea    -0x133d4(%ebx),%eax
f0102963:	50                   	push   %eax
f0102964:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f010296a:	50                   	push   %eax
f010296b:	68 80 03 00 00       	push   $0x380
f0102970:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102976:	50                   	push   %eax
f0102977:	e8 1d d7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010297c:	8d 83 a2 cf fe ff    	lea    -0x1305e(%ebx),%eax
f0102982:	50                   	push   %eax
f0102983:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102989:	50                   	push   %eax
f010298a:	68 83 03 00 00       	push   $0x383
f010298f:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102995:	50                   	push   %eax
f0102996:	e8 fe d6 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010299b:	8d 83 d0 c8 fe ff    	lea    -0x13730(%ebx),%eax
f01029a1:	50                   	push   %eax
f01029a2:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01029a8:	50                   	push   %eax
f01029a9:	68 86 03 00 00       	push   $0x386
f01029ae:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01029b4:	50                   	push   %eax
f01029b5:	e8 df d6 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f01029ba:	8d 83 05 d0 fe ff    	lea    -0x12ffb(%ebx),%eax
f01029c0:	50                   	push   %eax
f01029c1:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01029c7:	50                   	push   %eax
f01029c8:	68 88 03 00 00       	push   $0x388
f01029cd:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01029d3:	50                   	push   %eax
f01029d4:	e8 c0 d6 ff ff       	call   f0100099 <_panic>
f01029d9:	52                   	push   %edx
f01029da:	8d 83 34 c6 fe ff    	lea    -0x139cc(%ebx),%eax
f01029e0:	50                   	push   %eax
f01029e1:	68 8f 03 00 00       	push   $0x38f
f01029e6:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01029ec:	50                   	push   %eax
f01029ed:	e8 a7 d6 ff ff       	call   f0100099 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01029f2:	8d 83 91 d0 fe ff    	lea    -0x12f6f(%ebx),%eax
f01029f8:	50                   	push   %eax
f01029f9:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01029ff:	50                   	push   %eax
f0102a00:	68 90 03 00 00       	push   $0x390
f0102a05:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102a0b:	50                   	push   %eax
f0102a0c:	e8 88 d6 ff ff       	call   f0100099 <_panic>
f0102a11:	50                   	push   %eax
f0102a12:	8d 83 34 c6 fe ff    	lea    -0x139cc(%ebx),%eax
f0102a18:	50                   	push   %eax
f0102a19:	6a 52                	push   $0x52
f0102a1b:	8d 83 19 ce fe ff    	lea    -0x131e7(%ebx),%eax
f0102a21:	50                   	push   %eax
f0102a22:	e8 72 d6 ff ff       	call   f0100099 <_panic>
f0102a27:	52                   	push   %edx
f0102a28:	8d 83 34 c6 fe ff    	lea    -0x139cc(%ebx),%eax
f0102a2e:	50                   	push   %eax
f0102a2f:	6a 52                	push   $0x52
f0102a31:	8d 83 19 ce fe ff    	lea    -0x131e7(%ebx),%eax
f0102a37:	50                   	push   %eax
f0102a38:	e8 5c d6 ff ff       	call   f0100099 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102a3d:	8d 83 a9 d0 fe ff    	lea    -0x12f57(%ebx),%eax
f0102a43:	50                   	push   %eax
f0102a44:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102a4a:	50                   	push   %eax
f0102a4b:	68 9a 03 00 00       	push   $0x39a
f0102a50:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102a56:	50                   	push   %eax
f0102a57:	e8 3d d6 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a5c:	50                   	push   %eax
f0102a5d:	8d 83 40 c7 fe ff    	lea    -0x138c0(%ebx),%eax
f0102a63:	50                   	push   %eax
f0102a64:	68 b5 00 00 00       	push   $0xb5
f0102a69:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102a6f:	50                   	push   %eax
f0102a70:	e8 24 d6 ff ff       	call   f0100099 <_panic>
f0102a75:	50                   	push   %eax
f0102a76:	8d 83 40 c7 fe ff    	lea    -0x138c0(%ebx),%eax
f0102a7c:	50                   	push   %eax
f0102a7d:	68 c2 00 00 00       	push   $0xc2
f0102a82:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102a88:	50                   	push   %eax
f0102a89:	e8 0b d6 ff ff       	call   f0100099 <_panic>
f0102a8e:	ff 75 bc             	pushl  -0x44(%ebp)
f0102a91:	8d 83 40 c7 fe ff    	lea    -0x138c0(%ebx),%eax
f0102a97:	50                   	push   %eax
f0102a98:	68 cd 02 00 00       	push   $0x2cd
f0102a9d:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102aa3:	50                   	push   %eax
f0102aa4:	e8 f0 d5 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102aa9:	8d 83 50 cc fe ff    	lea    -0x133b0(%ebx),%eax
f0102aaf:	50                   	push   %eax
f0102ab0:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102ab6:	50                   	push   %eax
f0102ab7:	68 cd 02 00 00       	push   $0x2cd
f0102abc:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102ac2:	50                   	push   %eax
f0102ac3:	e8 d1 d5 ff ff       	call   f0100099 <_panic>
f0102ac8:	8b 75 d0             	mov    -0x30(%ebp),%esi
	if (!(*pgdir & PTE_P) | !(*pgdir & PTE_PS))
f0102acb:	8b 86 00 0f 00 00    	mov    0xf00(%esi),%eax
f0102ad1:	89 c2                	mov    %eax,%edx
f0102ad3:	81 e2 81 00 00 00    	and    $0x81,%edx
f0102ad9:	81 fa 81 00 00 00    	cmp    $0x81,%edx
f0102adf:	0f 85 14 01 00 00    	jne    f0102bf9 <mem_init+0x16f2>
	if (check_va2pa_large(pgdir, KERNBASE) == 0) {
f0102ae5:	a9 00 f0 ff ff       	test   $0xfffff000,%eax
f0102aea:	0f 85 09 01 00 00    	jne    f0102bf9 <mem_init+0x16f2>
		for (i = 0; i < npages * PGSIZE; i += PTSIZE)
f0102af0:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102af3:	c1 e7 0c             	shl    $0xc,%edi
f0102af6:	ba 00 00 00 00       	mov    $0x0,%edx
	return PTE_ADDR(*pgdir);
f0102afb:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0102afe:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102b01:	eb 2d                	jmp    f0102b30 <mem_init+0x1629>
	pgdir = &pgdir[PDX(va)];
f0102b03:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f0102b09:	c1 e8 16             	shr    $0x16,%eax
	if (!(*pgdir & PTE_P) | !(*pgdir & PTE_PS))
f0102b0c:	8b 04 86             	mov    (%esi,%eax,4),%eax
f0102b0f:	89 c1                	mov    %eax,%ecx
f0102b11:	81 e1 81 00 00 00    	and    $0x81,%ecx
	return PTE_ADDR(*pgdir);
f0102b17:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102b1c:	81 f9 81 00 00 00    	cmp    $0x81,%ecx
f0102b22:	0f 45 45 d4          	cmovne -0x2c(%ebp),%eax
			assert(check_va2pa_large(pgdir, KERNBASE + i) == i);
f0102b26:	39 c2                	cmp    %eax,%edx
f0102b28:	75 70                	jne    f0102b9a <mem_init+0x1693>
		for (i = 0; i < npages * PGSIZE; i += PTSIZE)
f0102b2a:	81 c2 00 00 40 00    	add    $0x400000,%edx
f0102b30:	39 fa                	cmp    %edi,%edx
f0102b32:	72 cf                	jb     f0102b03 <mem_init+0x15fc>
		cprintf("large page installed!\n");
f0102b34:	83 ec 0c             	sub    $0xc,%esp
f0102b37:	8d 83 d9 d0 fe ff    	lea    -0x12f27(%ebx),%eax
f0102b3d:	50                   	push   %eax
f0102b3e:	e8 86 06 00 00       	call   f01031c9 <cprintf>
f0102b43:	83 c4 10             	add    $0x10,%esp
        for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102b46:	bf 00 80 ff ef       	mov    $0xefff8000,%edi
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102b4b:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102b4e:	05 00 80 00 20       	add    $0x20008000,%eax
f0102b53:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102b56:	89 fa                	mov    %edi,%edx
f0102b58:	89 f0                	mov    %esi,%eax
f0102b5a:	e8 26 e1 ff ff       	call   f0100c85 <check_va2pa>
f0102b5f:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102b62:	8d 14 39             	lea    (%ecx,%edi,1),%edx
f0102b65:	39 d0                	cmp    %edx,%eax
f0102b67:	0f 85 9c 00 00 00    	jne    f0102c09 <mem_init+0x1702>
f0102b6d:	81 c7 00 10 00 00    	add    $0x1000,%edi
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102b73:	81 ff 00 00 00 f0    	cmp    $0xf0000000,%edi
f0102b79:	75 db                	jne    f0102b56 <mem_init+0x164f>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102b7b:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102b80:	89 f0                	mov    %esi,%eax
f0102b82:	e8 fe e0 ff ff       	call   f0100c85 <check_va2pa>
f0102b87:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102b8a:	0f 85 98 00 00 00    	jne    f0102c28 <mem_init+0x1721>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b90:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b95:	e9 d6 00 00 00       	jmp    f0102c70 <mem_init+0x1769>
			assert(check_va2pa_large(pgdir, KERNBASE + i) == i);
f0102b9a:	8d 83 84 cc fe ff    	lea    -0x1337c(%ebx),%eax
f0102ba0:	50                   	push   %eax
f0102ba1:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102ba7:	50                   	push   %eax
f0102ba8:	68 d3 02 00 00       	push   $0x2d3
f0102bad:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102bb3:	50                   	push   %eax
f0102bb4:	e8 e0 d4 ff ff       	call   f0100099 <_panic>
            assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102bb9:	8d 97 00 00 00 f0    	lea    -0x10000000(%edi),%edx
f0102bbf:	89 f0                	mov    %esi,%eax
f0102bc1:	e8 bf e0 ff ff       	call   f0100c85 <check_va2pa>
f0102bc6:	39 c7                	cmp    %eax,%edi
f0102bc8:	75 10                	jne    f0102bda <mem_init+0x16d3>
        for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102bca:	81 c7 00 10 00 00    	add    $0x1000,%edi
f0102bd0:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0102bd3:	72 e4                	jb     f0102bb9 <mem_init+0x16b2>
f0102bd5:	e9 6c ff ff ff       	jmp    f0102b46 <mem_init+0x163f>
            assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102bda:	8d 83 b0 cc fe ff    	lea    -0x13350(%ebx),%eax
f0102be0:	50                   	push   %eax
f0102be1:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102be7:	50                   	push   %eax
f0102be8:	68 d8 02 00 00       	push   $0x2d8
f0102bed:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102bf3:	50                   	push   %eax
f0102bf4:	e8 a0 d4 ff ff       	call   f0100099 <_panic>
        for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102bf9:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0102bfc:	c1 e0 0c             	shl    $0xc,%eax
f0102bff:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102c02:	bf 00 00 00 00       	mov    $0x0,%edi
f0102c07:	eb c7                	jmp    f0102bd0 <mem_init+0x16c9>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102c09:	8d 83 d8 cc fe ff    	lea    -0x13328(%ebx),%eax
f0102c0f:	50                   	push   %eax
f0102c10:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102c16:	50                   	push   %eax
f0102c17:	68 dd 02 00 00       	push   $0x2dd
f0102c1c:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102c22:	50                   	push   %eax
f0102c23:	e8 71 d4 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102c28:	8d 83 20 cd fe ff    	lea    -0x132e0(%ebx),%eax
f0102c2e:	50                   	push   %eax
f0102c2f:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102c35:	50                   	push   %eax
f0102c36:	68 de 02 00 00       	push   $0x2de
f0102c3b:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102c41:	50                   	push   %eax
f0102c42:	e8 52 d4 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102c47:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102c4b:	74 4f                	je     f0102c9c <mem_init+0x1795>
	for (i = 0; i < NPDENTRIES; i++) {
f0102c4d:	83 c0 01             	add    $0x1,%eax
f0102c50:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102c55:	0f 87 ab 00 00 00    	ja     f0102d06 <mem_init+0x17ff>
		switch (i) {
f0102c5b:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102c60:	72 0e                	jb     f0102c70 <mem_init+0x1769>
f0102c62:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102c67:	76 de                	jbe    f0102c47 <mem_init+0x1740>
f0102c69:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102c6e:	74 d7                	je     f0102c47 <mem_init+0x1740>
			if (i >= PDX(KERNBASE)) {
f0102c70:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102c75:	77 44                	ja     f0102cbb <mem_init+0x17b4>
				assert(pgdir[i] == 0);
f0102c77:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102c7b:	74 d0                	je     f0102c4d <mem_init+0x1746>
f0102c7d:	8d 83 12 d1 fe ff    	lea    -0x12eee(%ebx),%eax
f0102c83:	50                   	push   %eax
f0102c84:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102c8a:	50                   	push   %eax
f0102c8b:	68 ed 02 00 00       	push   $0x2ed
f0102c90:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102c96:	50                   	push   %eax
f0102c97:	e8 fd d3 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102c9c:	8d 83 f0 d0 fe ff    	lea    -0x12f10(%ebx),%eax
f0102ca2:	50                   	push   %eax
f0102ca3:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102ca9:	50                   	push   %eax
f0102caa:	68 e6 02 00 00       	push   $0x2e6
f0102caf:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102cb5:	50                   	push   %eax
f0102cb6:	e8 de d3 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102cbb:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102cbe:	f6 c2 01             	test   $0x1,%dl
f0102cc1:	74 24                	je     f0102ce7 <mem_init+0x17e0>
				assert(pgdir[i] & PTE_W);
f0102cc3:	f6 c2 02             	test   $0x2,%dl
f0102cc6:	75 85                	jne    f0102c4d <mem_init+0x1746>
f0102cc8:	8d 83 01 d1 fe ff    	lea    -0x12eff(%ebx),%eax
f0102cce:	50                   	push   %eax
f0102ccf:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102cd5:	50                   	push   %eax
f0102cd6:	68 eb 02 00 00       	push   $0x2eb
f0102cdb:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102ce1:	50                   	push   %eax
f0102ce2:	e8 b2 d3 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102ce7:	8d 83 f0 d0 fe ff    	lea    -0x12f10(%ebx),%eax
f0102ced:	50                   	push   %eax
f0102cee:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102cf4:	50                   	push   %eax
f0102cf5:	68 ea 02 00 00       	push   $0x2ea
f0102cfa:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102d00:	50                   	push   %eax
f0102d01:	e8 93 d3 ff ff       	call   f0100099 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102d06:	83 ec 0c             	sub    $0xc,%esp
f0102d09:	8d 83 50 cd fe ff    	lea    -0x132b0(%ebx),%eax
f0102d0f:	50                   	push   %eax
f0102d10:	e8 b4 04 00 00       	call   f01031c9 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102d15:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102d1b:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102d1d:	83 c4 10             	add    $0x10,%esp
f0102d20:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d25:	0f 86 28 02 00 00    	jbe    f0102f53 <mem_init+0x1a4c>
	return (physaddr_t)kva - KERNBASE;
f0102d2b:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102d30:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102d33:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d38:	e8 c5 df ff ff       	call   f0100d02 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102d3d:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102d40:	83 e0 f3             	and    $0xfffffff3,%eax
f0102d43:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102d48:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102d4b:	83 ec 0c             	sub    $0xc,%esp
f0102d4e:	6a 00                	push   $0x0
f0102d50:	e8 1b e4 ff ff       	call   f0101170 <page_alloc>
f0102d55:	89 c6                	mov    %eax,%esi
f0102d57:	83 c4 10             	add    $0x10,%esp
f0102d5a:	85 c0                	test   %eax,%eax
f0102d5c:	0f 84 0a 02 00 00    	je     f0102f6c <mem_init+0x1a65>
	assert((pp1 = page_alloc(0)));
f0102d62:	83 ec 0c             	sub    $0xc,%esp
f0102d65:	6a 00                	push   $0x0
f0102d67:	e8 04 e4 ff ff       	call   f0101170 <page_alloc>
f0102d6c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102d6f:	83 c4 10             	add    $0x10,%esp
f0102d72:	85 c0                	test   %eax,%eax
f0102d74:	0f 84 11 02 00 00    	je     f0102f8b <mem_init+0x1a84>
	assert((pp2 = page_alloc(0)));
f0102d7a:	83 ec 0c             	sub    $0xc,%esp
f0102d7d:	6a 00                	push   $0x0
f0102d7f:	e8 ec e3 ff ff       	call   f0101170 <page_alloc>
f0102d84:	89 c7                	mov    %eax,%edi
f0102d86:	83 c4 10             	add    $0x10,%esp
f0102d89:	85 c0                	test   %eax,%eax
f0102d8b:	0f 84 19 02 00 00    	je     f0102faa <mem_init+0x1aa3>
	page_free(pp0);
f0102d91:	83 ec 0c             	sub    $0xc,%esp
f0102d94:	56                   	push   %esi
f0102d95:	e8 5e e4 ff ff       	call   f01011f8 <page_free>
	return (pp - pages) << PGSHIFT;
f0102d9a:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0102da0:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102da3:	2b 08                	sub    (%eax),%ecx
f0102da5:	89 c8                	mov    %ecx,%eax
f0102da7:	c1 f8 03             	sar    $0x3,%eax
f0102daa:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102dad:	89 c1                	mov    %eax,%ecx
f0102daf:	c1 e9 0c             	shr    $0xc,%ecx
f0102db2:	83 c4 10             	add    $0x10,%esp
f0102db5:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
f0102dbb:	3b 0a                	cmp    (%edx),%ecx
f0102dbd:	0f 83 06 02 00 00    	jae    f0102fc9 <mem_init+0x1ac2>
	memset(page2kva(pp1), 1, PGSIZE);
f0102dc3:	83 ec 04             	sub    $0x4,%esp
f0102dc6:	68 00 10 00 00       	push   $0x1000
f0102dcb:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102dcd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102dd2:	50                   	push   %eax
f0102dd3:	e8 a5 11 00 00       	call   f0103f7d <memset>
	return (pp - pages) << PGSHIFT;
f0102dd8:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0102dde:	89 f9                	mov    %edi,%ecx
f0102de0:	2b 08                	sub    (%eax),%ecx
f0102de2:	89 c8                	mov    %ecx,%eax
f0102de4:	c1 f8 03             	sar    $0x3,%eax
f0102de7:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102dea:	89 c1                	mov    %eax,%ecx
f0102dec:	c1 e9 0c             	shr    $0xc,%ecx
f0102def:	83 c4 10             	add    $0x10,%esp
f0102df2:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
f0102df8:	3b 0a                	cmp    (%edx),%ecx
f0102dfa:	0f 83 df 01 00 00    	jae    f0102fdf <mem_init+0x1ad8>
	memset(page2kva(pp2), 2, PGSIZE);
f0102e00:	83 ec 04             	sub    $0x4,%esp
f0102e03:	68 00 10 00 00       	push   $0x1000
f0102e08:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102e0a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102e0f:	50                   	push   %eax
f0102e10:	e8 68 11 00 00       	call   f0103f7d <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102e15:	6a 02                	push   $0x2
f0102e17:	68 00 10 00 00       	push   $0x1000
f0102e1c:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102e1f:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102e25:	ff 30                	pushl  (%eax)
f0102e27:	e8 34 e6 ff ff       	call   f0101460 <page_insert>
	assert(pp1->pp_ref == 1);
f0102e2c:	83 c4 20             	add    $0x20,%esp
f0102e2f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e32:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102e37:	0f 85 b8 01 00 00    	jne    f0102ff5 <mem_init+0x1aee>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102e3d:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102e44:	01 01 01 
f0102e47:	0f 85 c7 01 00 00    	jne    f0103014 <mem_init+0x1b0d>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102e4d:	6a 02                	push   $0x2
f0102e4f:	68 00 10 00 00       	push   $0x1000
f0102e54:	57                   	push   %edi
f0102e55:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102e5b:	ff 30                	pushl  (%eax)
f0102e5d:	e8 fe e5 ff ff       	call   f0101460 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102e62:	83 c4 10             	add    $0x10,%esp
f0102e65:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102e6c:	02 02 02 
f0102e6f:	0f 85 be 01 00 00    	jne    f0103033 <mem_init+0x1b2c>
	assert(pp2->pp_ref == 1);
f0102e75:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102e7a:	0f 85 d2 01 00 00    	jne    f0103052 <mem_init+0x1b4b>
	assert(pp1->pp_ref == 0);
f0102e80:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e83:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102e88:	0f 85 e3 01 00 00    	jne    f0103071 <mem_init+0x1b6a>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102e8e:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102e95:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102e98:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0102e9e:	89 f9                	mov    %edi,%ecx
f0102ea0:	2b 08                	sub    (%eax),%ecx
f0102ea2:	89 c8                	mov    %ecx,%eax
f0102ea4:	c1 f8 03             	sar    $0x3,%eax
f0102ea7:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102eaa:	89 c1                	mov    %eax,%ecx
f0102eac:	c1 e9 0c             	shr    $0xc,%ecx
f0102eaf:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
f0102eb5:	3b 0a                	cmp    (%edx),%ecx
f0102eb7:	0f 83 d3 01 00 00    	jae    f0103090 <mem_init+0x1b89>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102ebd:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102ec4:	03 03 03 
f0102ec7:	0f 85 d9 01 00 00    	jne    f01030a6 <mem_init+0x1b9f>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102ecd:	83 ec 08             	sub    $0x8,%esp
f0102ed0:	68 00 10 00 00       	push   $0x1000
f0102ed5:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102edb:	ff 30                	pushl  (%eax)
f0102edd:	e8 41 e5 ff ff       	call   f0101423 <page_remove>
	assert(pp2->pp_ref == 0);
f0102ee2:	83 c4 10             	add    $0x10,%esp
f0102ee5:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102eea:	0f 85 d5 01 00 00    	jne    f01030c5 <mem_init+0x1bbe>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102ef0:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102ef6:	8b 08                	mov    (%eax),%ecx
f0102ef8:	8b 11                	mov    (%ecx),%edx
f0102efa:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102f00:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0102f06:	89 f7                	mov    %esi,%edi
f0102f08:	2b 38                	sub    (%eax),%edi
f0102f0a:	89 f8                	mov    %edi,%eax
f0102f0c:	c1 f8 03             	sar    $0x3,%eax
f0102f0f:	c1 e0 0c             	shl    $0xc,%eax
f0102f12:	39 c2                	cmp    %eax,%edx
f0102f14:	0f 85 ca 01 00 00    	jne    f01030e4 <mem_init+0x1bdd>
	kern_pgdir[0] = 0;
f0102f1a:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102f20:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102f25:	0f 85 d8 01 00 00    	jne    f0103103 <mem_init+0x1bfc>
	pp0->pp_ref = 0;
f0102f2b:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102f31:	83 ec 0c             	sub    $0xc,%esp
f0102f34:	56                   	push   %esi
f0102f35:	e8 be e2 ff ff       	call   f01011f8 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102f3a:	8d 83 e4 cd fe ff    	lea    -0x1321c(%ebx),%eax
f0102f40:	89 04 24             	mov    %eax,(%esp)
f0102f43:	e8 81 02 00 00       	call   f01031c9 <cprintf>
}
f0102f48:	83 c4 10             	add    $0x10,%esp
f0102f4b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f4e:	5b                   	pop    %ebx
f0102f4f:	5e                   	pop    %esi
f0102f50:	5f                   	pop    %edi
f0102f51:	5d                   	pop    %ebp
f0102f52:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f53:	50                   	push   %eax
f0102f54:	8d 83 40 c7 fe ff    	lea    -0x138c0(%ebx),%eax
f0102f5a:	50                   	push   %eax
f0102f5b:	68 dc 00 00 00       	push   $0xdc
f0102f60:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102f66:	50                   	push   %eax
f0102f67:	e8 2d d1 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102f6c:	8d 83 f7 ce fe ff    	lea    -0x13109(%ebx),%eax
f0102f72:	50                   	push   %eax
f0102f73:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102f79:	50                   	push   %eax
f0102f7a:	68 b5 03 00 00       	push   $0x3b5
f0102f7f:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102f85:	50                   	push   %eax
f0102f86:	e8 0e d1 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102f8b:	8d 83 0d cf fe ff    	lea    -0x130f3(%ebx),%eax
f0102f91:	50                   	push   %eax
f0102f92:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102f98:	50                   	push   %eax
f0102f99:	68 b6 03 00 00       	push   $0x3b6
f0102f9e:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102fa4:	50                   	push   %eax
f0102fa5:	e8 ef d0 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0102faa:	8d 83 23 cf fe ff    	lea    -0x130dd(%ebx),%eax
f0102fb0:	50                   	push   %eax
f0102fb1:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0102fb7:	50                   	push   %eax
f0102fb8:	68 b7 03 00 00       	push   $0x3b7
f0102fbd:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f0102fc3:	50                   	push   %eax
f0102fc4:	e8 d0 d0 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102fc9:	50                   	push   %eax
f0102fca:	8d 83 34 c6 fe ff    	lea    -0x139cc(%ebx),%eax
f0102fd0:	50                   	push   %eax
f0102fd1:	6a 52                	push   $0x52
f0102fd3:	8d 83 19 ce fe ff    	lea    -0x131e7(%ebx),%eax
f0102fd9:	50                   	push   %eax
f0102fda:	e8 ba d0 ff ff       	call   f0100099 <_panic>
f0102fdf:	50                   	push   %eax
f0102fe0:	8d 83 34 c6 fe ff    	lea    -0x139cc(%ebx),%eax
f0102fe6:	50                   	push   %eax
f0102fe7:	6a 52                	push   $0x52
f0102fe9:	8d 83 19 ce fe ff    	lea    -0x131e7(%ebx),%eax
f0102fef:	50                   	push   %eax
f0102ff0:	e8 a4 d0 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102ff5:	8d 83 f4 cf fe ff    	lea    -0x1300c(%ebx),%eax
f0102ffb:	50                   	push   %eax
f0102ffc:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0103002:	50                   	push   %eax
f0103003:	68 bc 03 00 00       	push   $0x3bc
f0103008:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010300e:	50                   	push   %eax
f010300f:	e8 85 d0 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0103014:	8d 83 70 cd fe ff    	lea    -0x13290(%ebx),%eax
f010301a:	50                   	push   %eax
f010301b:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0103021:	50                   	push   %eax
f0103022:	68 bd 03 00 00       	push   $0x3bd
f0103027:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010302d:	50                   	push   %eax
f010302e:	e8 66 d0 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0103033:	8d 83 94 cd fe ff    	lea    -0x1326c(%ebx),%eax
f0103039:	50                   	push   %eax
f010303a:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0103040:	50                   	push   %eax
f0103041:	68 bf 03 00 00       	push   $0x3bf
f0103046:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010304c:	50                   	push   %eax
f010304d:	e8 47 d0 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0103052:	8d 83 16 d0 fe ff    	lea    -0x12fea(%ebx),%eax
f0103058:	50                   	push   %eax
f0103059:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f010305f:	50                   	push   %eax
f0103060:	68 c0 03 00 00       	push   $0x3c0
f0103065:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010306b:	50                   	push   %eax
f010306c:	e8 28 d0 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0103071:	8d 83 80 d0 fe ff    	lea    -0x12f80(%ebx),%eax
f0103077:	50                   	push   %eax
f0103078:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f010307e:	50                   	push   %eax
f010307f:	68 c1 03 00 00       	push   $0x3c1
f0103084:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010308a:	50                   	push   %eax
f010308b:	e8 09 d0 ff ff       	call   f0100099 <_panic>
f0103090:	50                   	push   %eax
f0103091:	8d 83 34 c6 fe ff    	lea    -0x139cc(%ebx),%eax
f0103097:	50                   	push   %eax
f0103098:	6a 52                	push   $0x52
f010309a:	8d 83 19 ce fe ff    	lea    -0x131e7(%ebx),%eax
f01030a0:	50                   	push   %eax
f01030a1:	e8 f3 cf ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01030a6:	8d 83 b8 cd fe ff    	lea    -0x13248(%ebx),%eax
f01030ac:	50                   	push   %eax
f01030ad:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01030b3:	50                   	push   %eax
f01030b4:	68 c3 03 00 00       	push   $0x3c3
f01030b9:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01030bf:	50                   	push   %eax
f01030c0:	e8 d4 cf ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01030c5:	8d 83 4e d0 fe ff    	lea    -0x12fb2(%ebx),%eax
f01030cb:	50                   	push   %eax
f01030cc:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01030d2:	50                   	push   %eax
f01030d3:	68 c5 03 00 00       	push   $0x3c5
f01030d8:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01030de:	50                   	push   %eax
f01030df:	e8 b5 cf ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01030e4:	8d 83 d0 c8 fe ff    	lea    -0x13730(%ebx),%eax
f01030ea:	50                   	push   %eax
f01030eb:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f01030f1:	50                   	push   %eax
f01030f2:	68 c8 03 00 00       	push   $0x3c8
f01030f7:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01030fd:	50                   	push   %eax
f01030fe:	e8 96 cf ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0103103:	8d 83 05 d0 fe ff    	lea    -0x12ffb(%ebx),%eax
f0103109:	50                   	push   %eax
f010310a:	8d 83 33 ce fe ff    	lea    -0x131cd(%ebx),%eax
f0103110:	50                   	push   %eax
f0103111:	68 ca 03 00 00       	push   $0x3ca
f0103116:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f010311c:	50                   	push   %eax
f010311d:	e8 77 cf ff ff       	call   f0100099 <_panic>

f0103122 <tlb_invalidate>:
{
f0103122:	55                   	push   %ebp
f0103123:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0103125:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103128:	0f 01 38             	invlpg (%eax)
}
f010312b:	5d                   	pop    %ebp
f010312c:	c3                   	ret    

f010312d <__x86.get_pc_thunk.dx>:
f010312d:	8b 14 24             	mov    (%esp),%edx
f0103130:	c3                   	ret    

f0103131 <__x86.get_pc_thunk.cx>:
f0103131:	8b 0c 24             	mov    (%esp),%ecx
f0103134:	c3                   	ret    

f0103135 <__x86.get_pc_thunk.di>:
f0103135:	8b 3c 24             	mov    (%esp),%edi
f0103138:	c3                   	ret    

f0103139 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103139:	55                   	push   %ebp
f010313a:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010313c:	8b 45 08             	mov    0x8(%ebp),%eax
f010313f:	ba 70 00 00 00       	mov    $0x70,%edx
f0103144:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103145:	ba 71 00 00 00       	mov    $0x71,%edx
f010314a:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010314b:	0f b6 c0             	movzbl %al,%eax
}
f010314e:	5d                   	pop    %ebp
f010314f:	c3                   	ret    

f0103150 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103150:	55                   	push   %ebp
f0103151:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103153:	8b 45 08             	mov    0x8(%ebp),%eax
f0103156:	ba 70 00 00 00       	mov    $0x70,%edx
f010315b:	ee                   	out    %al,(%dx)
f010315c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010315f:	ba 71 00 00 00       	mov    $0x71,%edx
f0103164:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103165:	5d                   	pop    %ebp
f0103166:	c3                   	ret    

f0103167 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103167:	55                   	push   %ebp
f0103168:	89 e5                	mov    %esp,%ebp
f010316a:	56                   	push   %esi
f010316b:	53                   	push   %ebx
f010316c:	e8 de cf ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103171:	81 c3 97 51 01 00    	add    $0x15197,%ebx
f0103177:	8b 75 0c             	mov    0xc(%ebp),%esi
	cputchar(ch);
f010317a:	83 ec 0c             	sub    $0xc,%esp
f010317d:	ff 75 08             	pushl  0x8(%ebp)
f0103180:	e8 41 d5 ff ff       	call   f01006c6 <cputchar>
	(*cnt)++;
f0103185:	83 06 01             	addl   $0x1,(%esi)
}
f0103188:	83 c4 10             	add    $0x10,%esp
f010318b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010318e:	5b                   	pop    %ebx
f010318f:	5e                   	pop    %esi
f0103190:	5d                   	pop    %ebp
f0103191:	c3                   	ret    

f0103192 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103192:	55                   	push   %ebp
f0103193:	89 e5                	mov    %esp,%ebp
f0103195:	53                   	push   %ebx
f0103196:	83 ec 14             	sub    $0x14,%esp
f0103199:	e8 b1 cf ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010319e:	81 c3 6a 51 01 00    	add    $0x1516a,%ebx
	int cnt = 0;
f01031a4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01031ab:	ff 75 0c             	pushl  0xc(%ebp)
f01031ae:	ff 75 08             	pushl  0x8(%ebp)
f01031b1:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01031b4:	50                   	push   %eax
f01031b5:	8d 83 5f ae fe ff    	lea    -0x151a1(%ebx),%eax
f01031bb:	50                   	push   %eax
f01031bc:	e8 cb 04 00 00       	call   f010368c <vprintfmt>
	return cnt;
}
f01031c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01031c4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01031c7:	c9                   	leave  
f01031c8:	c3                   	ret    

f01031c9 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01031c9:	55                   	push   %ebp
f01031ca:	89 e5                	mov    %esp,%ebp
f01031cc:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01031cf:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01031d2:	50                   	push   %eax
f01031d3:	ff 75 08             	pushl  0x8(%ebp)
f01031d6:	e8 b7 ff ff ff       	call   f0103192 <vcprintf>
	va_end(ap);

	return cnt;
}
f01031db:	c9                   	leave  
f01031dc:	c3                   	ret    

f01031dd <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01031dd:	55                   	push   %ebp
f01031de:	89 e5                	mov    %esp,%ebp
f01031e0:	57                   	push   %edi
f01031e1:	56                   	push   %esi
f01031e2:	53                   	push   %ebx
f01031e3:	83 ec 14             	sub    $0x14,%esp
f01031e6:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01031e9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01031ec:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01031ef:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01031f2:	8b 32                	mov    (%edx),%esi
f01031f4:	8b 01                	mov    (%ecx),%eax
f01031f6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01031f9:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103200:	eb 2f                	jmp    f0103231 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0103202:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0103205:	39 c6                	cmp    %eax,%esi
f0103207:	7f 49                	jg     f0103252 <stab_binsearch+0x75>
f0103209:	0f b6 0a             	movzbl (%edx),%ecx
f010320c:	83 ea 0c             	sub    $0xc,%edx
f010320f:	39 f9                	cmp    %edi,%ecx
f0103211:	75 ef                	jne    f0103202 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103213:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103216:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103219:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010321d:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103220:	73 35                	jae    f0103257 <stab_binsearch+0x7a>
			*region_left = m;
f0103222:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103225:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0103227:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f010322a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0103231:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0103234:	7f 4e                	jg     f0103284 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0103236:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103239:	01 f0                	add    %esi,%eax
f010323b:	89 c3                	mov    %eax,%ebx
f010323d:	c1 eb 1f             	shr    $0x1f,%ebx
f0103240:	01 c3                	add    %eax,%ebx
f0103242:	d1 fb                	sar    %ebx
f0103244:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103247:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010324a:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f010324e:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0103250:	eb b3                	jmp    f0103205 <stab_binsearch+0x28>
			l = true_m + 1;
f0103252:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0103255:	eb da                	jmp    f0103231 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0103257:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010325a:	76 14                	jbe    f0103270 <stab_binsearch+0x93>
			*region_right = m - 1;
f010325c:	83 e8 01             	sub    $0x1,%eax
f010325f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103262:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103265:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0103267:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010326e:	eb c1                	jmp    f0103231 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103270:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103273:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103275:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103279:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f010327b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103282:	eb ad                	jmp    f0103231 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0103284:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103288:	74 16                	je     f01032a0 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010328a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010328d:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010328f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103292:	8b 0e                	mov    (%esi),%ecx
f0103294:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103297:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010329a:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f010329e:	eb 12                	jmp    f01032b2 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f01032a0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032a3:	8b 00                	mov    (%eax),%eax
f01032a5:	83 e8 01             	sub    $0x1,%eax
f01032a8:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01032ab:	89 07                	mov    %eax,(%edi)
f01032ad:	eb 16                	jmp    f01032c5 <stab_binsearch+0xe8>
		     l--)
f01032af:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f01032b2:	39 c1                	cmp    %eax,%ecx
f01032b4:	7d 0a                	jge    f01032c0 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f01032b6:	0f b6 1a             	movzbl (%edx),%ebx
f01032b9:	83 ea 0c             	sub    $0xc,%edx
f01032bc:	39 fb                	cmp    %edi,%ebx
f01032be:	75 ef                	jne    f01032af <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f01032c0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01032c3:	89 07                	mov    %eax,(%edi)
	}
}
f01032c5:	83 c4 14             	add    $0x14,%esp
f01032c8:	5b                   	pop    %ebx
f01032c9:	5e                   	pop    %esi
f01032ca:	5f                   	pop    %edi
f01032cb:	5d                   	pop    %ebp
f01032cc:	c3                   	ret    

f01032cd <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01032cd:	55                   	push   %ebp
f01032ce:	89 e5                	mov    %esp,%ebp
f01032d0:	57                   	push   %edi
f01032d1:	56                   	push   %esi
f01032d2:	53                   	push   %ebx
f01032d3:	83 ec 3c             	sub    $0x3c,%esp
f01032d6:	e8 74 ce ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01032db:	81 c3 2d 50 01 00    	add    $0x1502d,%ebx
f01032e1:	8b 7d 08             	mov    0x8(%ebp),%edi
f01032e4:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01032e7:	8d 83 20 d1 fe ff    	lea    -0x12ee0(%ebx),%eax
f01032ed:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f01032ef:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01032f6:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f01032f9:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0103300:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0103303:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010330a:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0103310:	0f 86 37 01 00 00    	jbe    f010344d <debuginfo_eip+0x180>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103316:	c7 c0 61 c4 10 f0    	mov    $0xf010c461,%eax
f010331c:	39 83 fc ff ff ff    	cmp    %eax,-0x4(%ebx)
f0103322:	0f 86 04 02 00 00    	jbe    f010352c <debuginfo_eip+0x25f>
f0103328:	c7 c0 1d e3 10 f0    	mov    $0xf010e31d,%eax
f010332e:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103332:	0f 85 fb 01 00 00    	jne    f0103533 <debuginfo_eip+0x266>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103338:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010333f:	c7 c0 bc 56 10 f0    	mov    $0xf01056bc,%eax
f0103345:	c7 c2 60 c4 10 f0    	mov    $0xf010c460,%edx
f010334b:	29 c2                	sub    %eax,%edx
f010334d:	c1 fa 02             	sar    $0x2,%edx
f0103350:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0103356:	83 ea 01             	sub    $0x1,%edx
f0103359:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010335c:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010335f:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103362:	83 ec 08             	sub    $0x8,%esp
f0103365:	57                   	push   %edi
f0103366:	6a 64                	push   $0x64
f0103368:	e8 70 fe ff ff       	call   f01031dd <stab_binsearch>
	if (lfile == 0)
f010336d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103370:	83 c4 10             	add    $0x10,%esp
f0103373:	85 c0                	test   %eax,%eax
f0103375:	0f 84 bf 01 00 00    	je     f010353a <debuginfo_eip+0x26d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010337b:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010337e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103381:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103384:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103387:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010338a:	83 ec 08             	sub    $0x8,%esp
f010338d:	57                   	push   %edi
f010338e:	6a 24                	push   $0x24
f0103390:	c7 c0 bc 56 10 f0    	mov    $0xf01056bc,%eax
f0103396:	e8 42 fe ff ff       	call   f01031dd <stab_binsearch>

	if (lfun <= rfun) {
f010339b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010339e:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01033a1:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f01033a4:	83 c4 10             	add    $0x10,%esp
f01033a7:	39 c8                	cmp    %ecx,%eax
f01033a9:	0f 8f b6 00 00 00    	jg     f0103465 <debuginfo_eip+0x198>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01033af:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01033b2:	c7 c1 bc 56 10 f0    	mov    $0xf01056bc,%ecx
f01033b8:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f01033bb:	8b 11                	mov    (%ecx),%edx
f01033bd:	89 55 c0             	mov    %edx,-0x40(%ebp)
f01033c0:	c7 c2 1d e3 10 f0    	mov    $0xf010e31d,%edx
f01033c6:	81 ea 61 c4 10 f0    	sub    $0xf010c461,%edx
f01033cc:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f01033cf:	73 0c                	jae    f01033dd <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01033d1:	8b 55 c0             	mov    -0x40(%ebp),%edx
f01033d4:	81 c2 61 c4 10 f0    	add    $0xf010c461,%edx
f01033da:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01033dd:	8b 51 08             	mov    0x8(%ecx),%edx
f01033e0:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f01033e3:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f01033e5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01033e8:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01033eb:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01033ee:	83 ec 08             	sub    $0x8,%esp
f01033f1:	6a 3a                	push   $0x3a
f01033f3:	ff 76 08             	pushl  0x8(%esi)
f01033f6:	e8 66 0b 00 00       	call   f0103f61 <strfind>
f01033fb:	2b 46 08             	sub    0x8(%esi),%eax
f01033fe:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103401:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103404:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103407:	83 c4 08             	add    $0x8,%esp
f010340a:	57                   	push   %edi
f010340b:	6a 44                	push   $0x44
f010340d:	c7 c0 bc 56 10 f0    	mov    $0xf01056bc,%eax
f0103413:	e8 c5 fd ff ff       	call   f01031dd <stab_binsearch>
	if(lline <= rline)
f0103418:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010341b:	83 c4 10             	add    $0x10,%esp
f010341e:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0103421:	0f 8f 1a 01 00 00    	jg     f0103541 <debuginfo_eip+0x274>
		info -> eip_line = stabs[lline].n_desc;
f0103427:	89 d0                	mov    %edx,%eax
f0103429:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010342c:	c1 e2 02             	shl    $0x2,%edx
f010342f:	c7 c1 bc 56 10 f0    	mov    $0xf01056bc,%ecx
f0103435:	0f b7 7c 0a 06       	movzwl 0x6(%edx,%ecx,1),%edi
f010343a:	89 7e 04             	mov    %edi,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010343d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103440:	8d 54 0a 04          	lea    0x4(%edx,%ecx,1),%edx
f0103444:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103448:	89 75 0c             	mov    %esi,0xc(%ebp)
f010344b:	eb 36                	jmp    f0103483 <debuginfo_eip+0x1b6>
  	        panic("User address");
f010344d:	83 ec 04             	sub    $0x4,%esp
f0103450:	8d 83 2a d1 fe ff    	lea    -0x12ed6(%ebx),%eax
f0103456:	50                   	push   %eax
f0103457:	6a 7f                	push   $0x7f
f0103459:	8d 83 37 d1 fe ff    	lea    -0x12ec9(%ebx),%eax
f010345f:	50                   	push   %eax
f0103460:	e8 34 cc ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f0103465:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0103468:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010346b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010346e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103471:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103474:	e9 75 ff ff ff       	jmp    f01033ee <debuginfo_eip+0x121>
f0103479:	83 e8 01             	sub    $0x1,%eax
f010347c:	83 ea 0c             	sub    $0xc,%edx
f010347f:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103483:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f0103486:	39 c7                	cmp    %eax,%edi
f0103488:	7f 24                	jg     f01034ae <debuginfo_eip+0x1e1>
	       && stabs[lline].n_type != N_SOL
f010348a:	0f b6 0a             	movzbl (%edx),%ecx
f010348d:	80 f9 84             	cmp    $0x84,%cl
f0103490:	74 46                	je     f01034d8 <debuginfo_eip+0x20b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103492:	80 f9 64             	cmp    $0x64,%cl
f0103495:	75 e2                	jne    f0103479 <debuginfo_eip+0x1ac>
f0103497:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f010349b:	74 dc                	je     f0103479 <debuginfo_eip+0x1ac>
f010349d:	8b 75 0c             	mov    0xc(%ebp),%esi
f01034a0:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01034a4:	74 3b                	je     f01034e1 <debuginfo_eip+0x214>
f01034a6:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01034a9:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01034ac:	eb 33                	jmp    f01034e1 <debuginfo_eip+0x214>
f01034ae:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01034b1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01034b4:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01034b7:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f01034bc:	39 fa                	cmp    %edi,%edx
f01034be:	0f 8d 89 00 00 00    	jge    f010354d <debuginfo_eip+0x280>
		for (lline = lfun + 1;
f01034c4:	83 c2 01             	add    $0x1,%edx
f01034c7:	89 d0                	mov    %edx,%eax
f01034c9:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f01034cc:	c7 c2 bc 56 10 f0    	mov    $0xf01056bc,%edx
f01034d2:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f01034d6:	eb 3b                	jmp    f0103513 <debuginfo_eip+0x246>
f01034d8:	8b 75 0c             	mov    0xc(%ebp),%esi
f01034db:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01034df:	75 26                	jne    f0103507 <debuginfo_eip+0x23a>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01034e1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01034e4:	c7 c0 bc 56 10 f0    	mov    $0xf01056bc,%eax
f01034ea:	8b 14 90             	mov    (%eax,%edx,4),%edx
f01034ed:	c7 c0 1d e3 10 f0    	mov    $0xf010e31d,%eax
f01034f3:	81 e8 61 c4 10 f0    	sub    $0xf010c461,%eax
f01034f9:	39 c2                	cmp    %eax,%edx
f01034fb:	73 b4                	jae    f01034b1 <debuginfo_eip+0x1e4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01034fd:	81 c2 61 c4 10 f0    	add    $0xf010c461,%edx
f0103503:	89 16                	mov    %edx,(%esi)
f0103505:	eb aa                	jmp    f01034b1 <debuginfo_eip+0x1e4>
f0103507:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010350a:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010350d:	eb d2                	jmp    f01034e1 <debuginfo_eip+0x214>
			info->eip_fn_narg++;
f010350f:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0103513:	39 c7                	cmp    %eax,%edi
f0103515:	7e 31                	jle    f0103548 <debuginfo_eip+0x27b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103517:	0f b6 0a             	movzbl (%edx),%ecx
f010351a:	83 c0 01             	add    $0x1,%eax
f010351d:	83 c2 0c             	add    $0xc,%edx
f0103520:	80 f9 a0             	cmp    $0xa0,%cl
f0103523:	74 ea                	je     f010350f <debuginfo_eip+0x242>
	return 0;
f0103525:	b8 00 00 00 00       	mov    $0x0,%eax
f010352a:	eb 21                	jmp    f010354d <debuginfo_eip+0x280>
		return -1;
f010352c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103531:	eb 1a                	jmp    f010354d <debuginfo_eip+0x280>
f0103533:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103538:	eb 13                	jmp    f010354d <debuginfo_eip+0x280>
		return -1;
f010353a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010353f:	eb 0c                	jmp    f010354d <debuginfo_eip+0x280>
		return -1;
f0103541:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103546:	eb 05                	jmp    f010354d <debuginfo_eip+0x280>
	return 0;
f0103548:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010354d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103550:	5b                   	pop    %ebx
f0103551:	5e                   	pop    %esi
f0103552:	5f                   	pop    %edi
f0103553:	5d                   	pop    %ebp
f0103554:	c3                   	ret    

f0103555 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103555:	55                   	push   %ebp
f0103556:	89 e5                	mov    %esp,%ebp
f0103558:	57                   	push   %edi
f0103559:	56                   	push   %esi
f010355a:	53                   	push   %ebx
f010355b:	83 ec 2c             	sub    $0x2c,%esp
f010355e:	e8 ce fb ff ff       	call   f0103131 <__x86.get_pc_thunk.cx>
f0103563:	81 c1 a5 4d 01 00    	add    $0x14da5,%ecx
f0103569:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010356c:	89 c7                	mov    %eax,%edi
f010356e:	89 d6                	mov    %edx,%esi
f0103570:	8b 45 08             	mov    0x8(%ebp),%eax
f0103573:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103576:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103579:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010357c:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// if cprintf'parameter includes pattern of the form "%-", padding
	// space on the right side if neccesary.
	// you can add helper function if needed.
	// your code here:
	if(padc == '-'){
f010357f:	83 7d 18 2d          	cmpl   $0x2d,0x18(%ebp)
f0103583:	74 56                	je     f01035db <printnum+0x86>
      putch(padc, putdat);
    return;
  }
	
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103585:	8b 45 10             	mov    0x10(%ebp),%eax
f0103588:	ba 00 00 00 00       	mov    $0x0,%edx
f010358d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103590:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103593:	89 d1                	mov    %edx,%ecx
f0103595:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103598:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010359b:	39 d1                	cmp    %edx,%ecx
f010359d:	72 05                	jb     f01035a4 <printnum+0x4f>
f010359f:	39 45 10             	cmp    %eax,0x10(%ebp)
f01035a2:	77 71                	ja     f0103615 <printnum+0xc0>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01035a4:	83 ec 0c             	sub    $0xc,%esp
f01035a7:	ff 75 18             	pushl  0x18(%ebp)
f01035aa:	83 eb 01             	sub    $0x1,%ebx
f01035ad:	53                   	push   %ebx
f01035ae:	ff 75 10             	pushl  0x10(%ebp)
f01035b1:	83 ec 08             	sub    $0x8,%esp
f01035b4:	ff 75 d4             	pushl  -0x2c(%ebp)
f01035b7:	ff 75 d0             	pushl  -0x30(%ebp)
f01035ba:	ff 75 e4             	pushl  -0x1c(%ebp)
f01035bd:	ff 75 e0             	pushl  -0x20(%ebp)
f01035c0:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01035c3:	e8 b8 0b 00 00       	call   f0104180 <__udivdi3>
f01035c8:	83 c4 18             	add    $0x18,%esp
f01035cb:	52                   	push   %edx
f01035cc:	50                   	push   %eax
f01035cd:	89 f2                	mov    %esi,%edx
f01035cf:	89 f8                	mov    %edi,%eax
f01035d1:	e8 7f ff ff ff       	call   f0103555 <printnum>
f01035d6:	83 c4 20             	add    $0x20,%esp
f01035d9:	eb 41                	jmp    f010361c <printnum+0xc7>
    printnum(putch,putdat,num,base,0,padc);
f01035db:	83 ec 0c             	sub    $0xc,%esp
f01035de:	6a 20                	push   $0x20
f01035e0:	6a 00                	push   $0x0
f01035e2:	ff 75 10             	pushl  0x10(%ebp)
f01035e5:	52                   	push   %edx
f01035e6:	50                   	push   %eax
f01035e7:	89 f2                	mov    %esi,%edx
f01035e9:	89 f8                	mov    %edi,%eax
f01035eb:	e8 65 ff ff ff       	call   f0103555 <printnum>
    while (--width > 0)
f01035f0:	83 c4 20             	add    $0x20,%esp
f01035f3:	eb 0b                	jmp    f0103600 <printnum+0xab>
      putch(padc, putdat);
f01035f5:	83 ec 08             	sub    $0x8,%esp
f01035f8:	56                   	push   %esi
f01035f9:	6a 20                	push   $0x20
f01035fb:	ff d7                	call   *%edi
f01035fd:	83 c4 10             	add    $0x10,%esp
    while (--width > 0)
f0103600:	83 eb 01             	sub    $0x1,%ebx
f0103603:	85 db                	test   %ebx,%ebx
f0103605:	7f ee                	jg     f01035f5 <printnum+0xa0>
f0103607:	eb 41                	jmp    f010364a <printnum+0xf5>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103609:	83 ec 08             	sub    $0x8,%esp
f010360c:	56                   	push   %esi
f010360d:	ff 75 18             	pushl  0x18(%ebp)
f0103610:	ff d7                	call   *%edi
f0103612:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0103615:	83 eb 01             	sub    $0x1,%ebx
f0103618:	85 db                	test   %ebx,%ebx
f010361a:	7f ed                	jg     f0103609 <printnum+0xb4>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010361c:	83 ec 08             	sub    $0x8,%esp
f010361f:	56                   	push   %esi
f0103620:	83 ec 04             	sub    $0x4,%esp
f0103623:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103626:	ff 75 d0             	pushl  -0x30(%ebp)
f0103629:	ff 75 e4             	pushl  -0x1c(%ebp)
f010362c:	ff 75 e0             	pushl  -0x20(%ebp)
f010362f:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0103632:	89 f3                	mov    %esi,%ebx
f0103634:	e8 67 0c 00 00       	call   f01042a0 <__umoddi3>
f0103639:	83 c4 14             	add    $0x14,%esp
f010363c:	0f be 84 06 45 d1 fe 	movsbl -0x12ebb(%esi,%eax,1),%eax
f0103643:	ff 
f0103644:	50                   	push   %eax
f0103645:	ff d7                	call   *%edi
f0103647:	83 c4 10             	add    $0x10,%esp
}
f010364a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010364d:	5b                   	pop    %ebx
f010364e:	5e                   	pop    %esi
f010364f:	5f                   	pop    %edi
f0103650:	5d                   	pop    %ebp
f0103651:	c3                   	ret    

f0103652 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103652:	55                   	push   %ebp
f0103653:	89 e5                	mov    %esp,%ebp
f0103655:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103658:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010365c:	8b 10                	mov    (%eax),%edx
f010365e:	3b 50 04             	cmp    0x4(%eax),%edx
f0103661:	73 0a                	jae    f010366d <sprintputch+0x1b>
		*b->buf++ = ch;
f0103663:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103666:	89 08                	mov    %ecx,(%eax)
f0103668:	8b 45 08             	mov    0x8(%ebp),%eax
f010366b:	88 02                	mov    %al,(%edx)
}
f010366d:	5d                   	pop    %ebp
f010366e:	c3                   	ret    

f010366f <printfmt>:
{
f010366f:	55                   	push   %ebp
f0103670:	89 e5                	mov    %esp,%ebp
f0103672:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0103675:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103678:	50                   	push   %eax
f0103679:	ff 75 10             	pushl  0x10(%ebp)
f010367c:	ff 75 0c             	pushl  0xc(%ebp)
f010367f:	ff 75 08             	pushl  0x8(%ebp)
f0103682:	e8 05 00 00 00       	call   f010368c <vprintfmt>
}
f0103687:	83 c4 10             	add    $0x10,%esp
f010368a:	c9                   	leave  
f010368b:	c3                   	ret    

f010368c <vprintfmt>:
{
f010368c:	55                   	push   %ebp
f010368d:	89 e5                	mov    %esp,%ebp
f010368f:	57                   	push   %edi
f0103690:	56                   	push   %esi
f0103691:	53                   	push   %ebx
f0103692:	83 ec 3c             	sub    $0x3c,%esp
f0103695:	e8 57 d0 ff ff       	call   f01006f1 <__x86.get_pc_thunk.ax>
f010369a:	05 6e 4c 01 00       	add    $0x14c6e,%eax
f010369f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01036a2:	8b 75 08             	mov    0x8(%ebp),%esi
f01036a5:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01036a8:	89 f7                	mov    %esi,%edi
f01036aa:	8b 75 0c             	mov    0xc(%ebp),%esi
f01036ad:	e9 98 04 00 00       	jmp    f0103b4a <.L42+0x55>
		padc = ' ';
f01036b2:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
    sign = 0;
f01036b6:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
		altflag = 0;
f01036bd:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
		precision = -1;
f01036c4:	c7 45 c4 ff ff ff ff 	movl   $0xffffffff,-0x3c(%ebp)
		width = -1;
f01036cb:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		lflag = 0;
f01036d2:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
f01036d9:	89 75 0c             	mov    %esi,0xc(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01036dc:	8d 43 01             	lea    0x1(%ebx),%eax
f01036df:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01036e2:	0f b6 13             	movzbl (%ebx),%edx
f01036e5:	8d 42 dd             	lea    -0x23(%edx),%eax
f01036e8:	3c 55                	cmp    $0x55,%al
f01036ea:	0f 87 74 05 00 00    	ja     f0103c64 <.L27>
f01036f0:	0f b6 c0             	movzbl %al,%eax
f01036f3:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01036f6:	89 ce                	mov    %ecx,%esi
f01036f8:	03 b4 81 4c d2 fe ff 	add    -0x12db4(%ecx,%eax,4),%esi
f01036ff:	ff e6                	jmp    *%esi

f0103701 <.L77>:
f0103701:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '-';
f0103704:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
f0103708:	eb d2                	jmp    f01036dc <vprintfmt+0x50>

f010370a <.L32>:
		switch (ch = *(unsigned char *) fmt++) {
f010370a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
      sign = 1;
f010370d:	c7 45 c0 01 00 00 00 	movl   $0x1,-0x40(%ebp)
f0103714:	eb c6                	jmp    f01036dc <vprintfmt+0x50>

f0103716 <.L35>:
		switch (ch = *(unsigned char *) fmt++) {
f0103716:	0f b6 d2             	movzbl %dl,%edx
f0103719:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			for (precision = 0; ; ++fmt) {
f010371c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103721:	89 7d 08             	mov    %edi,0x8(%ebp)
f0103724:	8b 75 0c             	mov    0xc(%ebp),%esi
				precision = precision * 10 + ch - '0';
f0103727:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010372a:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f010372e:	0f be 13             	movsbl (%ebx),%edx
				if (ch < '0' || ch > '9')
f0103731:	8d 7a d0             	lea    -0x30(%edx),%edi
f0103734:	83 ff 09             	cmp    $0x9,%edi
f0103737:	77 65                	ja     f010379e <.L28+0xf>
			for (precision = 0; ; ++fmt) {
f0103739:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f010373c:	eb e9                	jmp    f0103727 <.L35+0x11>

f010373e <.L34>:
		switch (ch = *(unsigned char *) fmt++) {
f010373e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '0';
f0103741:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
			goto reswitch;
f0103745:	eb 95                	jmp    f01036dc <vprintfmt+0x50>

f0103747 <.L31>:
			precision = va_arg(ap, int);
f0103747:	8b 45 14             	mov    0x14(%ebp),%eax
f010374a:	8b 00                	mov    (%eax),%eax
f010374c:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f010374f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103752:	8d 40 04             	lea    0x4(%eax),%eax
f0103755:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103758:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if (width < 0)
f010375b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010375f:	0f 89 77 ff ff ff    	jns    f01036dc <vprintfmt+0x50>
				width = precision, precision = -1;
f0103765:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103768:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010376b:	c7 45 c4 ff ff ff ff 	movl   $0xffffffff,-0x3c(%ebp)
f0103772:	e9 65 ff ff ff       	jmp    f01036dc <vprintfmt+0x50>

f0103777 <.L33>:
f0103777:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010377a:	85 c0                	test   %eax,%eax
f010377c:	ba 00 00 00 00       	mov    $0x0,%edx
f0103781:	0f 48 c2             	cmovs  %edx,%eax
f0103784:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103787:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010378a:	e9 4d ff ff ff       	jmp    f01036dc <vprintfmt+0x50>

f010378f <.L28>:
f010378f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			altflag = 1;
f0103792:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0103799:	e9 3e ff ff ff       	jmp    f01036dc <vprintfmt+0x50>
f010379e:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01037a1:	8b 7d 08             	mov    0x8(%ebp),%edi
f01037a4:	89 75 0c             	mov    %esi,0xc(%ebp)
f01037a7:	eb b2                	jmp    f010375b <.L31+0x14>

f01037a9 <.L39>:
			lflag++;
f01037a9:	83 45 c8 01          	addl   $0x1,-0x38(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01037ad:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f01037b0:	e9 27 ff ff ff       	jmp    f01036dc <vprintfmt+0x50>

f01037b5 <.L36>:
f01037b5:	8b 75 0c             	mov    0xc(%ebp),%esi
			putch(va_arg(ap, int), putdat);
f01037b8:	8b 45 14             	mov    0x14(%ebp),%eax
f01037bb:	8d 58 04             	lea    0x4(%eax),%ebx
f01037be:	83 ec 08             	sub    $0x8,%esp
f01037c1:	56                   	push   %esi
f01037c2:	ff 30                	pushl  (%eax)
f01037c4:	ff d7                	call   *%edi
			break;
f01037c6:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01037c9:	89 5d 14             	mov    %ebx,0x14(%ebp)
			break;
f01037cc:	e9 76 03 00 00       	jmp    f0103b47 <.L42+0x52>

f01037d1 <.L38>:
f01037d1:	8b 75 0c             	mov    0xc(%ebp),%esi
			err = va_arg(ap, int);
f01037d4:	8b 45 14             	mov    0x14(%ebp),%eax
f01037d7:	8d 58 04             	lea    0x4(%eax),%ebx
f01037da:	8b 00                	mov    (%eax),%eax
f01037dc:	99                   	cltd   
f01037dd:	31 d0                	xor    %edx,%eax
f01037df:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01037e1:	83 f8 06             	cmp    $0x6,%eax
f01037e4:	7f 2b                	jg     f0103811 <.L38+0x40>
f01037e6:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01037e9:	8b 94 81 48 1d 00 00 	mov    0x1d48(%ecx,%eax,4),%edx
f01037f0:	85 d2                	test   %edx,%edx
f01037f2:	74 1d                	je     f0103811 <.L38+0x40>
				printfmt(putch, putdat, "%s", p);
f01037f4:	52                   	push   %edx
f01037f5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01037f8:	8d 80 45 ce fe ff    	lea    -0x131bb(%eax),%eax
f01037fe:	50                   	push   %eax
f01037ff:	56                   	push   %esi
f0103800:	57                   	push   %edi
f0103801:	e8 69 fe ff ff       	call   f010366f <printfmt>
f0103806:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103809:	89 5d 14             	mov    %ebx,0x14(%ebp)
f010380c:	e9 36 03 00 00       	jmp    f0103b47 <.L42+0x52>
				printfmt(putch, putdat, "error %d", err);
f0103811:	50                   	push   %eax
f0103812:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103815:	8d 80 5d d1 fe ff    	lea    -0x12ea3(%eax),%eax
f010381b:	50                   	push   %eax
f010381c:	56                   	push   %esi
f010381d:	57                   	push   %edi
f010381e:	e8 4c fe ff ff       	call   f010366f <printfmt>
f0103823:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103826:	89 5d 14             	mov    %ebx,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0103829:	e9 19 03 00 00       	jmp    f0103b47 <.L42+0x52>

f010382e <.L43>:
f010382e:	8b 75 0c             	mov    0xc(%ebp),%esi
			if ((p = va_arg(ap, char *)) == NULL)
f0103831:	8b 45 14             	mov    0x14(%ebp),%eax
f0103834:	83 c0 04             	add    $0x4,%eax
f0103837:	89 45 c0             	mov    %eax,-0x40(%ebp)
f010383a:	8b 45 14             	mov    0x14(%ebp),%eax
f010383d:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f010383f:	85 d2                	test   %edx,%edx
f0103841:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103844:	8d 80 56 d1 fe ff    	lea    -0x12eaa(%eax),%eax
f010384a:	0f 45 c2             	cmovne %edx,%eax
f010384d:	89 45 c8             	mov    %eax,-0x38(%ebp)
			if (width > 0 && padc != '-')
f0103850:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103854:	0f 8e c0 00 00 00    	jle    f010391a <.L43+0xec>
f010385a:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
f010385e:	75 11                	jne    f0103871 <.L43+0x43>
f0103860:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0103863:	89 7d 08             	mov    %edi,0x8(%ebp)
f0103866:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103869:	89 75 0c             	mov    %esi,0xc(%ebp)
f010386c:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010386f:	eb 6d                	jmp    f01038de <.L43+0xb0>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103871:	83 ec 08             	sub    $0x8,%esp
f0103874:	ff 75 c4             	pushl  -0x3c(%ebp)
f0103877:	50                   	push   %eax
f0103878:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010387b:	e8 9d 05 00 00       	call   f0103e1d <strnlen>
f0103880:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103883:	29 c1                	sub    %eax,%ecx
f0103885:	89 4d bc             	mov    %ecx,-0x44(%ebp)
f0103888:	83 c4 10             	add    $0x10,%esp
f010388b:	89 cb                	mov    %ecx,%ebx
					putch(padc, putdat);
f010388d:	0f be 45 db          	movsbl -0x25(%ebp),%eax
f0103891:	89 45 dc             	mov    %eax,-0x24(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0103894:	eb 0f                	jmp    f01038a5 <.L43+0x77>
					putch(padc, putdat);
f0103896:	83 ec 08             	sub    $0x8,%esp
f0103899:	56                   	push   %esi
f010389a:	ff 75 dc             	pushl  -0x24(%ebp)
f010389d:	ff d7                	call   *%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f010389f:	83 eb 01             	sub    $0x1,%ebx
f01038a2:	83 c4 10             	add    $0x10,%esp
f01038a5:	85 db                	test   %ebx,%ebx
f01038a7:	7f ed                	jg     f0103896 <.L43+0x68>
f01038a9:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01038ac:	85 d2                	test   %edx,%edx
f01038ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01038b3:	0f 49 c2             	cmovns %edx,%eax
f01038b6:	29 c2                	sub    %eax,%edx
f01038b8:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f01038bb:	89 7d 08             	mov    %edi,0x8(%ebp)
f01038be:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01038c1:	89 75 0c             	mov    %esi,0xc(%ebp)
f01038c4:	89 d6                	mov    %edx,%esi
f01038c6:	eb 16                	jmp    f01038de <.L43+0xb0>
				if (altflag && (ch < ' ' || ch > '~'))
f01038c8:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01038cc:	75 31                	jne    f01038ff <.L43+0xd1>
					putch(ch, putdat);
f01038ce:	83 ec 08             	sub    $0x8,%esp
f01038d1:	ff 75 0c             	pushl  0xc(%ebp)
f01038d4:	50                   	push   %eax
f01038d5:	ff 55 08             	call   *0x8(%ebp)
f01038d8:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01038db:	83 ee 01             	sub    $0x1,%esi
f01038de:	83 c3 01             	add    $0x1,%ebx
f01038e1:	0f b6 53 ff          	movzbl -0x1(%ebx),%edx
f01038e5:	0f be c2             	movsbl %dl,%eax
f01038e8:	85 c0                	test   %eax,%eax
f01038ea:	74 5c                	je     f0103948 <.L43+0x11a>
f01038ec:	85 ff                	test   %edi,%edi
f01038ee:	78 d8                	js     f01038c8 <.L43+0x9a>
f01038f0:	83 ef 01             	sub    $0x1,%edi
f01038f3:	79 d3                	jns    f01038c8 <.L43+0x9a>
f01038f5:	89 f3                	mov    %esi,%ebx
f01038f7:	8b 7d 08             	mov    0x8(%ebp),%edi
f01038fa:	8b 75 0c             	mov    0xc(%ebp),%esi
f01038fd:	eb 3a                	jmp    f0103939 <.L43+0x10b>
				if (altflag && (ch < ' ' || ch > '~'))
f01038ff:	0f be d2             	movsbl %dl,%edx
f0103902:	83 ea 20             	sub    $0x20,%edx
f0103905:	83 fa 5e             	cmp    $0x5e,%edx
f0103908:	76 c4                	jbe    f01038ce <.L43+0xa0>
					putch('?', putdat);
f010390a:	83 ec 08             	sub    $0x8,%esp
f010390d:	ff 75 0c             	pushl  0xc(%ebp)
f0103910:	6a 3f                	push   $0x3f
f0103912:	ff 55 08             	call   *0x8(%ebp)
f0103915:	83 c4 10             	add    $0x10,%esp
f0103918:	eb c1                	jmp    f01038db <.L43+0xad>
f010391a:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f010391d:	89 7d 08             	mov    %edi,0x8(%ebp)
f0103920:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103923:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103926:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0103929:	eb b3                	jmp    f01038de <.L43+0xb0>
				putch(' ', putdat);
f010392b:	83 ec 08             	sub    $0x8,%esp
f010392e:	56                   	push   %esi
f010392f:	6a 20                	push   $0x20
f0103931:	ff d7                	call   *%edi
			for (; width > 0; width--)
f0103933:	83 eb 01             	sub    $0x1,%ebx
f0103936:	83 c4 10             	add    $0x10,%esp
f0103939:	85 db                	test   %ebx,%ebx
f010393b:	7f ee                	jg     f010392b <.L43+0xfd>
			if ((p = va_arg(ap, char *)) == NULL)
f010393d:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0103940:	89 45 14             	mov    %eax,0x14(%ebp)
f0103943:	e9 ff 01 00 00       	jmp    f0103b47 <.L42+0x52>
f0103948:	89 f3                	mov    %esi,%ebx
f010394a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010394d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103950:	eb e7                	jmp    f0103939 <.L43+0x10b>

f0103952 <.L37>:
f0103952:	8b 75 0c             	mov    0xc(%ebp),%esi
	if (lflag >= 2)
f0103955:	83 7d c8 01          	cmpl   $0x1,-0x38(%ebp)
f0103959:	7e 51                	jle    f01039ac <.L37+0x5a>
		return va_arg(*ap, long long);
f010395b:	8b 45 14             	mov    0x14(%ebp),%eax
f010395e:	8b 50 04             	mov    0x4(%eax),%edx
f0103961:	8b 00                	mov    (%eax),%eax
f0103963:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0103966:	89 55 cc             	mov    %edx,-0x34(%ebp)
f0103969:	8b 45 14             	mov    0x14(%ebp),%eax
f010396c:	8d 40 08             	lea    0x8(%eax),%eax
f010396f:	89 45 14             	mov    %eax,0x14(%ebp)
			num = getint(&ap, lflag);
f0103972:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0103975:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0103978:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010397b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
			if ((long long) num < 0) {
f010397e:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0103982:	79 64                	jns    f01039e8 <.L37+0x96>
				putch('-', putdat);
f0103984:	83 ec 08             	sub    $0x8,%esp
f0103987:	56                   	push   %esi
f0103988:	6a 2d                	push   $0x2d
f010398a:	ff d7                	call   *%edi
				num = -(long long) num;
f010398c:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010398f:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0103992:	f7 d8                	neg    %eax
f0103994:	83 d2 00             	adc    $0x0,%edx
f0103997:	f7 da                	neg    %edx
f0103999:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010399c:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010399f:	83 c4 10             	add    $0x10,%esp
			base = 10;
f01039a2:	b8 0a 00 00 00       	mov    $0xa,%eax
f01039a7:	e9 7d 01 00 00       	jmp    f0103b29 <.L42+0x34>
	else if (lflag)
f01039ac:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
f01039b0:	75 1b                	jne    f01039cd <.L37+0x7b>
		return va_arg(*ap, int);
f01039b2:	8b 45 14             	mov    0x14(%ebp),%eax
f01039b5:	8b 00                	mov    (%eax),%eax
f01039b7:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01039ba:	89 c1                	mov    %eax,%ecx
f01039bc:	c1 f9 1f             	sar    $0x1f,%ecx
f01039bf:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f01039c2:	8b 45 14             	mov    0x14(%ebp),%eax
f01039c5:	8d 40 04             	lea    0x4(%eax),%eax
f01039c8:	89 45 14             	mov    %eax,0x14(%ebp)
f01039cb:	eb a5                	jmp    f0103972 <.L37+0x20>
		return va_arg(*ap, long);
f01039cd:	8b 45 14             	mov    0x14(%ebp),%eax
f01039d0:	8b 00                	mov    (%eax),%eax
f01039d2:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01039d5:	89 c1                	mov    %eax,%ecx
f01039d7:	c1 f9 1f             	sar    $0x1f,%ecx
f01039da:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f01039dd:	8b 45 14             	mov    0x14(%ebp),%eax
f01039e0:	8d 40 04             	lea    0x4(%eax),%eax
f01039e3:	89 45 14             	mov    %eax,0x14(%ebp)
f01039e6:	eb 8a                	jmp    f0103972 <.L37+0x20>
			} else if(sign){
f01039e8:	83 7d c0 00          	cmpl   $0x0,-0x40(%ebp)
f01039ec:	0f 84 ef 01 00 00    	je     f0103be1 <.L45+0x73>
        putch('+', putdat);
f01039f2:	83 ec 08             	sub    $0x8,%esp
f01039f5:	56                   	push   %esi
f01039f6:	6a 2b                	push   $0x2b
f01039f8:	ff d7                	call   *%edi
f01039fa:	83 c4 10             	add    $0x10,%esp
			base = 10;
f01039fd:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103a02:	e9 22 01 00 00       	jmp    f0103b29 <.L42+0x34>

f0103a07 <.L44>:
f0103a07:	8b 75 0c             	mov    0xc(%ebp),%esi
	if (lflag >= 2)
f0103a0a:	83 7d c8 01          	cmpl   $0x1,-0x38(%ebp)
f0103a0e:	7e 21                	jle    f0103a31 <.L44+0x2a>
		return va_arg(*ap, unsigned long long);
f0103a10:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a13:	8b 50 04             	mov    0x4(%eax),%edx
f0103a16:	8b 00                	mov    (%eax),%eax
f0103a18:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103a1b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103a1e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a21:	8d 40 08             	lea    0x8(%eax),%eax
f0103a24:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103a27:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103a2c:	e9 f8 00 00 00       	jmp    f0103b29 <.L42+0x34>
	else if (lflag)
f0103a31:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
f0103a35:	75 23                	jne    f0103a5a <.L44+0x53>
		return va_arg(*ap, unsigned int);
f0103a37:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a3a:	8b 00                	mov    (%eax),%eax
f0103a3c:	ba 00 00 00 00       	mov    $0x0,%edx
f0103a41:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103a44:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103a47:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a4a:	8d 40 04             	lea    0x4(%eax),%eax
f0103a4d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103a50:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103a55:	e9 cf 00 00 00       	jmp    f0103b29 <.L42+0x34>
		return va_arg(*ap, unsigned long);
f0103a5a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a5d:	8b 00                	mov    (%eax),%eax
f0103a5f:	ba 00 00 00 00       	mov    $0x0,%edx
f0103a64:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103a67:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103a6a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a6d:	8d 40 04             	lea    0x4(%eax),%eax
f0103a70:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103a73:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103a78:	e9 ac 00 00 00       	jmp    f0103b29 <.L42+0x34>

f0103a7d <.L41>:
f0103a7d:	8b 75 0c             	mov    0xc(%ebp),%esi
			putch('0', putdat);
f0103a80:	83 ec 08             	sub    $0x8,%esp
f0103a83:	56                   	push   %esi
f0103a84:	6a 30                	push   $0x30
f0103a86:	ff d7                	call   *%edi
	if (lflag >= 2)
f0103a88:	83 c4 10             	add    $0x10,%esp
f0103a8b:	83 7d c8 01          	cmpl   $0x1,-0x38(%ebp)
f0103a8f:	7e 1e                	jle    f0103aaf <.L41+0x32>
		return va_arg(*ap, unsigned long long);
f0103a91:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a94:	8b 50 04             	mov    0x4(%eax),%edx
f0103a97:	8b 00                	mov    (%eax),%eax
f0103a99:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103a9c:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103a9f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103aa2:	8d 40 08             	lea    0x8(%eax),%eax
f0103aa5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103aa8:	b8 08 00 00 00       	mov    $0x8,%eax
f0103aad:	eb 7a                	jmp    f0103b29 <.L42+0x34>
	else if (lflag)
f0103aaf:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
f0103ab3:	75 20                	jne    f0103ad5 <.L41+0x58>
		return va_arg(*ap, unsigned int);
f0103ab5:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ab8:	8b 00                	mov    (%eax),%eax
f0103aba:	ba 00 00 00 00       	mov    $0x0,%edx
f0103abf:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103ac2:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103ac5:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ac8:	8d 40 04             	lea    0x4(%eax),%eax
f0103acb:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103ace:	b8 08 00 00 00       	mov    $0x8,%eax
f0103ad3:	eb 54                	jmp    f0103b29 <.L42+0x34>
		return va_arg(*ap, unsigned long);
f0103ad5:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ad8:	8b 00                	mov    (%eax),%eax
f0103ada:	ba 00 00 00 00       	mov    $0x0,%edx
f0103adf:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103ae2:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103ae5:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ae8:	8d 40 04             	lea    0x4(%eax),%eax
f0103aeb:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103aee:	b8 08 00 00 00       	mov    $0x8,%eax
f0103af3:	eb 34                	jmp    f0103b29 <.L42+0x34>

f0103af5 <.L42>:
f0103af5:	8b 75 0c             	mov    0xc(%ebp),%esi
			putch('0', putdat);
f0103af8:	83 ec 08             	sub    $0x8,%esp
f0103afb:	56                   	push   %esi
f0103afc:	6a 30                	push   $0x30
f0103afe:	ff d7                	call   *%edi
			putch('x', putdat);
f0103b00:	83 c4 08             	add    $0x8,%esp
f0103b03:	56                   	push   %esi
f0103b04:	6a 78                	push   $0x78
f0103b06:	ff d7                	call   *%edi
			num = (unsigned long long)
f0103b08:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b0b:	8b 00                	mov    (%eax),%eax
f0103b0d:	ba 00 00 00 00       	mov    $0x0,%edx
f0103b12:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103b15:	89 55 d4             	mov    %edx,-0x2c(%ebp)
			goto number;
f0103b18:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0103b1b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b1e:	8d 40 04             	lea    0x4(%eax),%eax
f0103b21:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103b24:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0103b29:	83 ec 0c             	sub    $0xc,%esp
f0103b2c:	0f be 5d db          	movsbl -0x25(%ebp),%ebx
f0103b30:	53                   	push   %ebx
f0103b31:	ff 75 dc             	pushl  -0x24(%ebp)
f0103b34:	50                   	push   %eax
f0103b35:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103b38:	ff 75 d0             	pushl  -0x30(%ebp)
f0103b3b:	89 f2                	mov    %esi,%edx
f0103b3d:	89 f8                	mov    %edi,%eax
f0103b3f:	e8 11 fa ff ff       	call   f0103555 <printnum>
			break;
f0103b44:	83 c4 20             	add    $0x20,%esp
		      signed* ptr = (signed*) va_arg(ap, void *);
f0103b47:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103b4a:	83 c3 01             	add    $0x1,%ebx
f0103b4d:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0103b51:	83 f8 25             	cmp    $0x25,%eax
f0103b54:	0f 84 58 fb ff ff    	je     f01036b2 <vprintfmt+0x26>
			if (ch == '\0')
f0103b5a:	85 c0                	test   %eax,%eax
f0103b5c:	0f 84 25 01 00 00    	je     f0103c87 <.L27+0x23>
			putch(ch, putdat);
f0103b62:	83 ec 08             	sub    $0x8,%esp
f0103b65:	56                   	push   %esi
f0103b66:	50                   	push   %eax
f0103b67:	ff d7                	call   *%edi
f0103b69:	83 c4 10             	add    $0x10,%esp
f0103b6c:	eb dc                	jmp    f0103b4a <.L42+0x55>

f0103b6e <.L45>:
f0103b6e:	8b 75 0c             	mov    0xc(%ebp),%esi
	if (lflag >= 2)
f0103b71:	83 7d c8 01          	cmpl   $0x1,-0x38(%ebp)
f0103b75:	7e 1e                	jle    f0103b95 <.L45+0x27>
		return va_arg(*ap, unsigned long long);
f0103b77:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b7a:	8b 50 04             	mov    0x4(%eax),%edx
f0103b7d:	8b 00                	mov    (%eax),%eax
f0103b7f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103b82:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103b85:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b88:	8d 40 08             	lea    0x8(%eax),%eax
f0103b8b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103b8e:	b8 10 00 00 00       	mov    $0x10,%eax
f0103b93:	eb 94                	jmp    f0103b29 <.L42+0x34>
	else if (lflag)
f0103b95:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
f0103b99:	75 23                	jne    f0103bbe <.L45+0x50>
		return va_arg(*ap, unsigned int);
f0103b9b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b9e:	8b 00                	mov    (%eax),%eax
f0103ba0:	ba 00 00 00 00       	mov    $0x0,%edx
f0103ba5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103ba8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103bab:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bae:	8d 40 04             	lea    0x4(%eax),%eax
f0103bb1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103bb4:	b8 10 00 00 00       	mov    $0x10,%eax
f0103bb9:	e9 6b ff ff ff       	jmp    f0103b29 <.L42+0x34>
		return va_arg(*ap, unsigned long);
f0103bbe:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bc1:	8b 00                	mov    (%eax),%eax
f0103bc3:	ba 00 00 00 00       	mov    $0x0,%edx
f0103bc8:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103bcb:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103bce:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bd1:	8d 40 04             	lea    0x4(%eax),%eax
f0103bd4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103bd7:	b8 10 00 00 00       	mov    $0x10,%eax
f0103bdc:	e9 48 ff ff ff       	jmp    f0103b29 <.L42+0x34>
			base = 10;
f0103be1:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103be6:	e9 3e ff ff ff       	jmp    f0103b29 <.L42+0x34>

f0103beb <.L40>:
f0103beb:	8b 75 0c             	mov    0xc(%ebp),%esi
		      signed* ptr = (signed*) va_arg(ap, void *);
f0103bee:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bf1:	8d 58 04             	lea    0x4(%eax),%ebx
f0103bf4:	8b 00                	mov    (%eax),%eax
          if(!ptr){	
f0103bf6:	85 c0                	test   %eax,%eax
f0103bf8:	74 34                	je     f0103c2e <.L40+0x43>
            *(signed char*)ptr = *(signed char*)putdat;
f0103bfa:	0f b6 16             	movzbl (%esi),%edx
f0103bfd:	88 10                	mov    %dl,(%eax)
		      signed* ptr = (signed*) va_arg(ap, void *);
f0103bff:	89 5d 14             	mov    %ebx,0x14(%ebp)
            if(*(int*)putdat > 0x7F){	
f0103c02:	83 3e 7f             	cmpl   $0x7f,(%esi)
f0103c05:	0f 8e 3c ff ff ff    	jle    f0103b47 <.L42+0x52>
              printfmt(putch, putdat, "%s", overflow_error);					  
f0103c0b:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103c0e:	8d 82 08 d2 fe ff    	lea    -0x12df8(%edx),%eax
f0103c14:	50                   	push   %eax
f0103c15:	8d 82 45 ce fe ff    	lea    -0x131bb(%edx),%eax
f0103c1b:	50                   	push   %eax
f0103c1c:	56                   	push   %esi
f0103c1d:	57                   	push   %edi
f0103c1e:	e8 4c fa ff ff       	call   f010366f <printfmt>
f0103c23:	83 c4 10             	add    $0x10,%esp
		      signed* ptr = (signed*) va_arg(ap, void *);
f0103c26:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0103c29:	e9 19 ff ff ff       	jmp    f0103b47 <.L42+0x52>
            printfmt(putch, putdat, "%s", null_error);
f0103c2e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103c31:	8d 81 d0 d1 fe ff    	lea    -0x12e30(%ecx),%eax
f0103c37:	50                   	push   %eax
f0103c38:	8d 81 45 ce fe ff    	lea    -0x131bb(%ecx),%eax
f0103c3e:	50                   	push   %eax
f0103c3f:	56                   	push   %esi
f0103c40:	57                   	push   %edi
f0103c41:	e8 29 fa ff ff       	call   f010366f <printfmt>
f0103c46:	83 c4 10             	add    $0x10,%esp
		      signed* ptr = (signed*) va_arg(ap, void *);
f0103c49:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0103c4c:	e9 f6 fe ff ff       	jmp    f0103b47 <.L42+0x52>

f0103c51 <.L30>:
f0103c51:	8b 75 0c             	mov    0xc(%ebp),%esi
			putch(ch, putdat);
f0103c54:	83 ec 08             	sub    $0x8,%esp
f0103c57:	56                   	push   %esi
f0103c58:	6a 25                	push   $0x25
f0103c5a:	ff d7                	call   *%edi
			break;
f0103c5c:	83 c4 10             	add    $0x10,%esp
f0103c5f:	e9 e3 fe ff ff       	jmp    f0103b47 <.L42+0x52>

f0103c64 <.L27>:
f0103c64:	8b 75 0c             	mov    0xc(%ebp),%esi
			putch('%', putdat);
f0103c67:	83 ec 08             	sub    $0x8,%esp
f0103c6a:	56                   	push   %esi
f0103c6b:	6a 25                	push   $0x25
f0103c6d:	ff d7                	call   *%edi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103c6f:	83 c4 10             	add    $0x10,%esp
f0103c72:	89 d8                	mov    %ebx,%eax
f0103c74:	eb 03                	jmp    f0103c79 <.L27+0x15>
f0103c76:	83 e8 01             	sub    $0x1,%eax
f0103c79:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0103c7d:	75 f7                	jne    f0103c76 <.L27+0x12>
f0103c7f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103c82:	e9 c0 fe ff ff       	jmp    f0103b47 <.L42+0x52>
}
f0103c87:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103c8a:	5b                   	pop    %ebx
f0103c8b:	5e                   	pop    %esi
f0103c8c:	5f                   	pop    %edi
f0103c8d:	5d                   	pop    %ebp
f0103c8e:	c3                   	ret    

f0103c8f <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103c8f:	55                   	push   %ebp
f0103c90:	89 e5                	mov    %esp,%ebp
f0103c92:	53                   	push   %ebx
f0103c93:	83 ec 14             	sub    $0x14,%esp
f0103c96:	e8 b4 c4 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103c9b:	81 c3 6d 46 01 00    	add    $0x1466d,%ebx
f0103ca1:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ca4:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103ca7:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103caa:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103cae:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103cb1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103cb8:	85 c0                	test   %eax,%eax
f0103cba:	74 2b                	je     f0103ce7 <vsnprintf+0x58>
f0103cbc:	85 d2                	test   %edx,%edx
f0103cbe:	7e 27                	jle    f0103ce7 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103cc0:	ff 75 14             	pushl  0x14(%ebp)
f0103cc3:	ff 75 10             	pushl  0x10(%ebp)
f0103cc6:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103cc9:	50                   	push   %eax
f0103cca:	8d 83 4a b3 fe ff    	lea    -0x14cb6(%ebx),%eax
f0103cd0:	50                   	push   %eax
f0103cd1:	e8 b6 f9 ff ff       	call   f010368c <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103cd6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103cd9:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103cdc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103cdf:	83 c4 10             	add    $0x10,%esp
}
f0103ce2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103ce5:	c9                   	leave  
f0103ce6:	c3                   	ret    
		return -E_INVAL;
f0103ce7:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103cec:	eb f4                	jmp    f0103ce2 <vsnprintf+0x53>

f0103cee <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103cee:	55                   	push   %ebp
f0103cef:	89 e5                	mov    %esp,%ebp
f0103cf1:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103cf4:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103cf7:	50                   	push   %eax
f0103cf8:	ff 75 10             	pushl  0x10(%ebp)
f0103cfb:	ff 75 0c             	pushl  0xc(%ebp)
f0103cfe:	ff 75 08             	pushl  0x8(%ebp)
f0103d01:	e8 89 ff ff ff       	call   f0103c8f <vsnprintf>
	va_end(ap);

	return rc;
}
f0103d06:	c9                   	leave  
f0103d07:	c3                   	ret    

f0103d08 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103d08:	55                   	push   %ebp
f0103d09:	89 e5                	mov    %esp,%ebp
f0103d0b:	57                   	push   %edi
f0103d0c:	56                   	push   %esi
f0103d0d:	53                   	push   %ebx
f0103d0e:	83 ec 1c             	sub    $0x1c,%esp
f0103d11:	e8 39 c4 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103d16:	81 c3 f2 45 01 00    	add    $0x145f2,%ebx
f0103d1c:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103d1f:	85 c0                	test   %eax,%eax
f0103d21:	74 13                	je     f0103d36 <readline+0x2e>
		cprintf("%s", prompt);
f0103d23:	83 ec 08             	sub    $0x8,%esp
f0103d26:	50                   	push   %eax
f0103d27:	8d 83 45 ce fe ff    	lea    -0x131bb(%ebx),%eax
f0103d2d:	50                   	push   %eax
f0103d2e:	e8 96 f4 ff ff       	call   f01031c9 <cprintf>
f0103d33:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103d36:	83 ec 0c             	sub    $0xc,%esp
f0103d39:	6a 00                	push   $0x0
f0103d3b:	e8 a7 c9 ff ff       	call   f01006e7 <iscons>
f0103d40:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103d43:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0103d46:	bf 00 00 00 00       	mov    $0x0,%edi
f0103d4b:	eb 46                	jmp    f0103d93 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0103d4d:	83 ec 08             	sub    $0x8,%esp
f0103d50:	50                   	push   %eax
f0103d51:	8d 83 a4 d3 fe ff    	lea    -0x12c5c(%ebx),%eax
f0103d57:	50                   	push   %eax
f0103d58:	e8 6c f4 ff ff       	call   f01031c9 <cprintf>
			return NULL;
f0103d5d:	83 c4 10             	add    $0x10,%esp
f0103d60:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0103d65:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103d68:	5b                   	pop    %ebx
f0103d69:	5e                   	pop    %esi
f0103d6a:	5f                   	pop    %edi
f0103d6b:	5d                   	pop    %ebp
f0103d6c:	c3                   	ret    
			if (echoing)
f0103d6d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103d71:	75 05                	jne    f0103d78 <readline+0x70>
			i--;
f0103d73:	83 ef 01             	sub    $0x1,%edi
f0103d76:	eb 1b                	jmp    f0103d93 <readline+0x8b>
				cputchar('\b');
f0103d78:	83 ec 0c             	sub    $0xc,%esp
f0103d7b:	6a 08                	push   $0x8
f0103d7d:	e8 44 c9 ff ff       	call   f01006c6 <cputchar>
f0103d82:	83 c4 10             	add    $0x10,%esp
f0103d85:	eb ec                	jmp    f0103d73 <readline+0x6b>
			buf[i++] = c;
f0103d87:	89 f0                	mov    %esi,%eax
f0103d89:	88 84 3b b8 1f 00 00 	mov    %al,0x1fb8(%ebx,%edi,1)
f0103d90:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0103d93:	e8 3e c9 ff ff       	call   f01006d6 <getchar>
f0103d98:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0103d9a:	85 c0                	test   %eax,%eax
f0103d9c:	78 af                	js     f0103d4d <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103d9e:	83 f8 08             	cmp    $0x8,%eax
f0103da1:	0f 94 c2             	sete   %dl
f0103da4:	83 f8 7f             	cmp    $0x7f,%eax
f0103da7:	0f 94 c0             	sete   %al
f0103daa:	08 c2                	or     %al,%dl
f0103dac:	74 04                	je     f0103db2 <readline+0xaa>
f0103dae:	85 ff                	test   %edi,%edi
f0103db0:	7f bb                	jg     f0103d6d <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103db2:	83 fe 1f             	cmp    $0x1f,%esi
f0103db5:	7e 1c                	jle    f0103dd3 <readline+0xcb>
f0103db7:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0103dbd:	7f 14                	jg     f0103dd3 <readline+0xcb>
			if (echoing)
f0103dbf:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103dc3:	74 c2                	je     f0103d87 <readline+0x7f>
				cputchar(c);
f0103dc5:	83 ec 0c             	sub    $0xc,%esp
f0103dc8:	56                   	push   %esi
f0103dc9:	e8 f8 c8 ff ff       	call   f01006c6 <cputchar>
f0103dce:	83 c4 10             	add    $0x10,%esp
f0103dd1:	eb b4                	jmp    f0103d87 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0103dd3:	83 fe 0a             	cmp    $0xa,%esi
f0103dd6:	74 05                	je     f0103ddd <readline+0xd5>
f0103dd8:	83 fe 0d             	cmp    $0xd,%esi
f0103ddb:	75 b6                	jne    f0103d93 <readline+0x8b>
			if (echoing)
f0103ddd:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103de1:	75 13                	jne    f0103df6 <readline+0xee>
			buf[i] = 0;
f0103de3:	c6 84 3b b8 1f 00 00 	movb   $0x0,0x1fb8(%ebx,%edi,1)
f0103dea:	00 
			return buf;
f0103deb:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f0103df1:	e9 6f ff ff ff       	jmp    f0103d65 <readline+0x5d>
				cputchar('\n');
f0103df6:	83 ec 0c             	sub    $0xc,%esp
f0103df9:	6a 0a                	push   $0xa
f0103dfb:	e8 c6 c8 ff ff       	call   f01006c6 <cputchar>
f0103e00:	83 c4 10             	add    $0x10,%esp
f0103e03:	eb de                	jmp    f0103de3 <readline+0xdb>

f0103e05 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103e05:	55                   	push   %ebp
f0103e06:	89 e5                	mov    %esp,%ebp
f0103e08:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103e0b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e10:	eb 03                	jmp    f0103e15 <strlen+0x10>
		n++;
f0103e12:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103e15:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103e19:	75 f7                	jne    f0103e12 <strlen+0xd>
	return n;
}
f0103e1b:	5d                   	pop    %ebp
f0103e1c:	c3                   	ret    

f0103e1d <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103e1d:	55                   	push   %ebp
f0103e1e:	89 e5                	mov    %esp,%ebp
f0103e20:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103e23:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103e26:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e2b:	eb 03                	jmp    f0103e30 <strnlen+0x13>
		n++;
f0103e2d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103e30:	39 d0                	cmp    %edx,%eax
f0103e32:	74 06                	je     f0103e3a <strnlen+0x1d>
f0103e34:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103e38:	75 f3                	jne    f0103e2d <strnlen+0x10>
	return n;
}
f0103e3a:	5d                   	pop    %ebp
f0103e3b:	c3                   	ret    

f0103e3c <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103e3c:	55                   	push   %ebp
f0103e3d:	89 e5                	mov    %esp,%ebp
f0103e3f:	53                   	push   %ebx
f0103e40:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e43:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103e46:	89 c2                	mov    %eax,%edx
f0103e48:	83 c1 01             	add    $0x1,%ecx
f0103e4b:	83 c2 01             	add    $0x1,%edx
f0103e4e:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103e52:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103e55:	84 db                	test   %bl,%bl
f0103e57:	75 ef                	jne    f0103e48 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103e59:	5b                   	pop    %ebx
f0103e5a:	5d                   	pop    %ebp
f0103e5b:	c3                   	ret    

f0103e5c <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103e5c:	55                   	push   %ebp
f0103e5d:	89 e5                	mov    %esp,%ebp
f0103e5f:	53                   	push   %ebx
f0103e60:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103e63:	53                   	push   %ebx
f0103e64:	e8 9c ff ff ff       	call   f0103e05 <strlen>
f0103e69:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103e6c:	ff 75 0c             	pushl  0xc(%ebp)
f0103e6f:	01 d8                	add    %ebx,%eax
f0103e71:	50                   	push   %eax
f0103e72:	e8 c5 ff ff ff       	call   f0103e3c <strcpy>
	return dst;
}
f0103e77:	89 d8                	mov    %ebx,%eax
f0103e79:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103e7c:	c9                   	leave  
f0103e7d:	c3                   	ret    

f0103e7e <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103e7e:	55                   	push   %ebp
f0103e7f:	89 e5                	mov    %esp,%ebp
f0103e81:	56                   	push   %esi
f0103e82:	53                   	push   %ebx
f0103e83:	8b 75 08             	mov    0x8(%ebp),%esi
f0103e86:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103e89:	89 f3                	mov    %esi,%ebx
f0103e8b:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103e8e:	89 f2                	mov    %esi,%edx
f0103e90:	eb 0f                	jmp    f0103ea1 <strncpy+0x23>
		*dst++ = *src;
f0103e92:	83 c2 01             	add    $0x1,%edx
f0103e95:	0f b6 01             	movzbl (%ecx),%eax
f0103e98:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103e9b:	80 39 01             	cmpb   $0x1,(%ecx)
f0103e9e:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0103ea1:	39 da                	cmp    %ebx,%edx
f0103ea3:	75 ed                	jne    f0103e92 <strncpy+0x14>
	}
	return ret;
}
f0103ea5:	89 f0                	mov    %esi,%eax
f0103ea7:	5b                   	pop    %ebx
f0103ea8:	5e                   	pop    %esi
f0103ea9:	5d                   	pop    %ebp
f0103eaa:	c3                   	ret    

f0103eab <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103eab:	55                   	push   %ebp
f0103eac:	89 e5                	mov    %esp,%ebp
f0103eae:	56                   	push   %esi
f0103eaf:	53                   	push   %ebx
f0103eb0:	8b 75 08             	mov    0x8(%ebp),%esi
f0103eb3:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103eb6:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103eb9:	89 f0                	mov    %esi,%eax
f0103ebb:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103ebf:	85 c9                	test   %ecx,%ecx
f0103ec1:	75 0b                	jne    f0103ece <strlcpy+0x23>
f0103ec3:	eb 17                	jmp    f0103edc <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103ec5:	83 c2 01             	add    $0x1,%edx
f0103ec8:	83 c0 01             	add    $0x1,%eax
f0103ecb:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0103ece:	39 d8                	cmp    %ebx,%eax
f0103ed0:	74 07                	je     f0103ed9 <strlcpy+0x2e>
f0103ed2:	0f b6 0a             	movzbl (%edx),%ecx
f0103ed5:	84 c9                	test   %cl,%cl
f0103ed7:	75 ec                	jne    f0103ec5 <strlcpy+0x1a>
		*dst = '\0';
f0103ed9:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103edc:	29 f0                	sub    %esi,%eax
}
f0103ede:	5b                   	pop    %ebx
f0103edf:	5e                   	pop    %esi
f0103ee0:	5d                   	pop    %ebp
f0103ee1:	c3                   	ret    

f0103ee2 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103ee2:	55                   	push   %ebp
f0103ee3:	89 e5                	mov    %esp,%ebp
f0103ee5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103ee8:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103eeb:	eb 06                	jmp    f0103ef3 <strcmp+0x11>
		p++, q++;
f0103eed:	83 c1 01             	add    $0x1,%ecx
f0103ef0:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0103ef3:	0f b6 01             	movzbl (%ecx),%eax
f0103ef6:	84 c0                	test   %al,%al
f0103ef8:	74 04                	je     f0103efe <strcmp+0x1c>
f0103efa:	3a 02                	cmp    (%edx),%al
f0103efc:	74 ef                	je     f0103eed <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103efe:	0f b6 c0             	movzbl %al,%eax
f0103f01:	0f b6 12             	movzbl (%edx),%edx
f0103f04:	29 d0                	sub    %edx,%eax
}
f0103f06:	5d                   	pop    %ebp
f0103f07:	c3                   	ret    

f0103f08 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103f08:	55                   	push   %ebp
f0103f09:	89 e5                	mov    %esp,%ebp
f0103f0b:	53                   	push   %ebx
f0103f0c:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f0f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103f12:	89 c3                	mov    %eax,%ebx
f0103f14:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103f17:	eb 06                	jmp    f0103f1f <strncmp+0x17>
		n--, p++, q++;
f0103f19:	83 c0 01             	add    $0x1,%eax
f0103f1c:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0103f1f:	39 d8                	cmp    %ebx,%eax
f0103f21:	74 16                	je     f0103f39 <strncmp+0x31>
f0103f23:	0f b6 08             	movzbl (%eax),%ecx
f0103f26:	84 c9                	test   %cl,%cl
f0103f28:	74 04                	je     f0103f2e <strncmp+0x26>
f0103f2a:	3a 0a                	cmp    (%edx),%cl
f0103f2c:	74 eb                	je     f0103f19 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103f2e:	0f b6 00             	movzbl (%eax),%eax
f0103f31:	0f b6 12             	movzbl (%edx),%edx
f0103f34:	29 d0                	sub    %edx,%eax
}
f0103f36:	5b                   	pop    %ebx
f0103f37:	5d                   	pop    %ebp
f0103f38:	c3                   	ret    
		return 0;
f0103f39:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f3e:	eb f6                	jmp    f0103f36 <strncmp+0x2e>

f0103f40 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103f40:	55                   	push   %ebp
f0103f41:	89 e5                	mov    %esp,%ebp
f0103f43:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f46:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103f4a:	0f b6 10             	movzbl (%eax),%edx
f0103f4d:	84 d2                	test   %dl,%dl
f0103f4f:	74 09                	je     f0103f5a <strchr+0x1a>
		if (*s == c)
f0103f51:	38 ca                	cmp    %cl,%dl
f0103f53:	74 0a                	je     f0103f5f <strchr+0x1f>
	for (; *s; s++)
f0103f55:	83 c0 01             	add    $0x1,%eax
f0103f58:	eb f0                	jmp    f0103f4a <strchr+0xa>
			return (char *) s;
	return 0;
f0103f5a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103f5f:	5d                   	pop    %ebp
f0103f60:	c3                   	ret    

f0103f61 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103f61:	55                   	push   %ebp
f0103f62:	89 e5                	mov    %esp,%ebp
f0103f64:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f67:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103f6b:	eb 03                	jmp    f0103f70 <strfind+0xf>
f0103f6d:	83 c0 01             	add    $0x1,%eax
f0103f70:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103f73:	38 ca                	cmp    %cl,%dl
f0103f75:	74 04                	je     f0103f7b <strfind+0x1a>
f0103f77:	84 d2                	test   %dl,%dl
f0103f79:	75 f2                	jne    f0103f6d <strfind+0xc>
			break;
	return (char *) s;
}
f0103f7b:	5d                   	pop    %ebp
f0103f7c:	c3                   	ret    

f0103f7d <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103f7d:	55                   	push   %ebp
f0103f7e:	89 e5                	mov    %esp,%ebp
f0103f80:	57                   	push   %edi
f0103f81:	56                   	push   %esi
f0103f82:	53                   	push   %ebx
f0103f83:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103f86:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103f89:	85 c9                	test   %ecx,%ecx
f0103f8b:	74 13                	je     f0103fa0 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103f8d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103f93:	75 05                	jne    f0103f9a <memset+0x1d>
f0103f95:	f6 c1 03             	test   $0x3,%cl
f0103f98:	74 0d                	je     f0103fa7 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103f9a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f9d:	fc                   	cld    
f0103f9e:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103fa0:	89 f8                	mov    %edi,%eax
f0103fa2:	5b                   	pop    %ebx
f0103fa3:	5e                   	pop    %esi
f0103fa4:	5f                   	pop    %edi
f0103fa5:	5d                   	pop    %ebp
f0103fa6:	c3                   	ret    
		c &= 0xFF;
f0103fa7:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103fab:	89 d3                	mov    %edx,%ebx
f0103fad:	c1 e3 08             	shl    $0x8,%ebx
f0103fb0:	89 d0                	mov    %edx,%eax
f0103fb2:	c1 e0 18             	shl    $0x18,%eax
f0103fb5:	89 d6                	mov    %edx,%esi
f0103fb7:	c1 e6 10             	shl    $0x10,%esi
f0103fba:	09 f0                	or     %esi,%eax
f0103fbc:	09 c2                	or     %eax,%edx
f0103fbe:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0103fc0:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103fc3:	89 d0                	mov    %edx,%eax
f0103fc5:	fc                   	cld    
f0103fc6:	f3 ab                	rep stos %eax,%es:(%edi)
f0103fc8:	eb d6                	jmp    f0103fa0 <memset+0x23>

f0103fca <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103fca:	55                   	push   %ebp
f0103fcb:	89 e5                	mov    %esp,%ebp
f0103fcd:	57                   	push   %edi
f0103fce:	56                   	push   %esi
f0103fcf:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fd2:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103fd5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103fd8:	39 c6                	cmp    %eax,%esi
f0103fda:	73 35                	jae    f0104011 <memmove+0x47>
f0103fdc:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103fdf:	39 c2                	cmp    %eax,%edx
f0103fe1:	76 2e                	jbe    f0104011 <memmove+0x47>
		s += n;
		d += n;
f0103fe3:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103fe6:	89 d6                	mov    %edx,%esi
f0103fe8:	09 fe                	or     %edi,%esi
f0103fea:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103ff0:	74 0c                	je     f0103ffe <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103ff2:	83 ef 01             	sub    $0x1,%edi
f0103ff5:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103ff8:	fd                   	std    
f0103ff9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103ffb:	fc                   	cld    
f0103ffc:	eb 21                	jmp    f010401f <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103ffe:	f6 c1 03             	test   $0x3,%cl
f0104001:	75 ef                	jne    f0103ff2 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104003:	83 ef 04             	sub    $0x4,%edi
f0104006:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104009:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f010400c:	fd                   	std    
f010400d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010400f:	eb ea                	jmp    f0103ffb <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104011:	89 f2                	mov    %esi,%edx
f0104013:	09 c2                	or     %eax,%edx
f0104015:	f6 c2 03             	test   $0x3,%dl
f0104018:	74 09                	je     f0104023 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010401a:	89 c7                	mov    %eax,%edi
f010401c:	fc                   	cld    
f010401d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010401f:	5e                   	pop    %esi
f0104020:	5f                   	pop    %edi
f0104021:	5d                   	pop    %ebp
f0104022:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104023:	f6 c1 03             	test   $0x3,%cl
f0104026:	75 f2                	jne    f010401a <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0104028:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f010402b:	89 c7                	mov    %eax,%edi
f010402d:	fc                   	cld    
f010402e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104030:	eb ed                	jmp    f010401f <memmove+0x55>

f0104032 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104032:	55                   	push   %ebp
f0104033:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104035:	ff 75 10             	pushl  0x10(%ebp)
f0104038:	ff 75 0c             	pushl  0xc(%ebp)
f010403b:	ff 75 08             	pushl  0x8(%ebp)
f010403e:	e8 87 ff ff ff       	call   f0103fca <memmove>
}
f0104043:	c9                   	leave  
f0104044:	c3                   	ret    

f0104045 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104045:	55                   	push   %ebp
f0104046:	89 e5                	mov    %esp,%ebp
f0104048:	56                   	push   %esi
f0104049:	53                   	push   %ebx
f010404a:	8b 45 08             	mov    0x8(%ebp),%eax
f010404d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104050:	89 c6                	mov    %eax,%esi
f0104052:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104055:	39 f0                	cmp    %esi,%eax
f0104057:	74 1c                	je     f0104075 <memcmp+0x30>
		if (*s1 != *s2)
f0104059:	0f b6 08             	movzbl (%eax),%ecx
f010405c:	0f b6 1a             	movzbl (%edx),%ebx
f010405f:	38 d9                	cmp    %bl,%cl
f0104061:	75 08                	jne    f010406b <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0104063:	83 c0 01             	add    $0x1,%eax
f0104066:	83 c2 01             	add    $0x1,%edx
f0104069:	eb ea                	jmp    f0104055 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f010406b:	0f b6 c1             	movzbl %cl,%eax
f010406e:	0f b6 db             	movzbl %bl,%ebx
f0104071:	29 d8                	sub    %ebx,%eax
f0104073:	eb 05                	jmp    f010407a <memcmp+0x35>
	}

	return 0;
f0104075:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010407a:	5b                   	pop    %ebx
f010407b:	5e                   	pop    %esi
f010407c:	5d                   	pop    %ebp
f010407d:	c3                   	ret    

f010407e <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010407e:	55                   	push   %ebp
f010407f:	89 e5                	mov    %esp,%ebp
f0104081:	8b 45 08             	mov    0x8(%ebp),%eax
f0104084:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104087:	89 c2                	mov    %eax,%edx
f0104089:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010408c:	39 d0                	cmp    %edx,%eax
f010408e:	73 09                	jae    f0104099 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104090:	38 08                	cmp    %cl,(%eax)
f0104092:	74 05                	je     f0104099 <memfind+0x1b>
	for (; s < ends; s++)
f0104094:	83 c0 01             	add    $0x1,%eax
f0104097:	eb f3                	jmp    f010408c <memfind+0xe>
			break;
	return (void *) s;
}
f0104099:	5d                   	pop    %ebp
f010409a:	c3                   	ret    

f010409b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010409b:	55                   	push   %ebp
f010409c:	89 e5                	mov    %esp,%ebp
f010409e:	57                   	push   %edi
f010409f:	56                   	push   %esi
f01040a0:	53                   	push   %ebx
f01040a1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01040a4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01040a7:	eb 03                	jmp    f01040ac <strtol+0x11>
		s++;
f01040a9:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01040ac:	0f b6 01             	movzbl (%ecx),%eax
f01040af:	3c 20                	cmp    $0x20,%al
f01040b1:	74 f6                	je     f01040a9 <strtol+0xe>
f01040b3:	3c 09                	cmp    $0x9,%al
f01040b5:	74 f2                	je     f01040a9 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f01040b7:	3c 2b                	cmp    $0x2b,%al
f01040b9:	74 2e                	je     f01040e9 <strtol+0x4e>
	int neg = 0;
f01040bb:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01040c0:	3c 2d                	cmp    $0x2d,%al
f01040c2:	74 2f                	je     f01040f3 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01040c4:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01040ca:	75 05                	jne    f01040d1 <strtol+0x36>
f01040cc:	80 39 30             	cmpb   $0x30,(%ecx)
f01040cf:	74 2c                	je     f01040fd <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01040d1:	85 db                	test   %ebx,%ebx
f01040d3:	75 0a                	jne    f01040df <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01040d5:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f01040da:	80 39 30             	cmpb   $0x30,(%ecx)
f01040dd:	74 28                	je     f0104107 <strtol+0x6c>
		base = 10;
f01040df:	b8 00 00 00 00       	mov    $0x0,%eax
f01040e4:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01040e7:	eb 50                	jmp    f0104139 <strtol+0x9e>
		s++;
f01040e9:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f01040ec:	bf 00 00 00 00       	mov    $0x0,%edi
f01040f1:	eb d1                	jmp    f01040c4 <strtol+0x29>
		s++, neg = 1;
f01040f3:	83 c1 01             	add    $0x1,%ecx
f01040f6:	bf 01 00 00 00       	mov    $0x1,%edi
f01040fb:	eb c7                	jmp    f01040c4 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01040fd:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104101:	74 0e                	je     f0104111 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0104103:	85 db                	test   %ebx,%ebx
f0104105:	75 d8                	jne    f01040df <strtol+0x44>
		s++, base = 8;
f0104107:	83 c1 01             	add    $0x1,%ecx
f010410a:	bb 08 00 00 00       	mov    $0x8,%ebx
f010410f:	eb ce                	jmp    f01040df <strtol+0x44>
		s += 2, base = 16;
f0104111:	83 c1 02             	add    $0x2,%ecx
f0104114:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104119:	eb c4                	jmp    f01040df <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f010411b:	8d 72 9f             	lea    -0x61(%edx),%esi
f010411e:	89 f3                	mov    %esi,%ebx
f0104120:	80 fb 19             	cmp    $0x19,%bl
f0104123:	77 29                	ja     f010414e <strtol+0xb3>
			dig = *s - 'a' + 10;
f0104125:	0f be d2             	movsbl %dl,%edx
f0104128:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010412b:	3b 55 10             	cmp    0x10(%ebp),%edx
f010412e:	7d 30                	jge    f0104160 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0104130:	83 c1 01             	add    $0x1,%ecx
f0104133:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104137:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0104139:	0f b6 11             	movzbl (%ecx),%edx
f010413c:	8d 72 d0             	lea    -0x30(%edx),%esi
f010413f:	89 f3                	mov    %esi,%ebx
f0104141:	80 fb 09             	cmp    $0x9,%bl
f0104144:	77 d5                	ja     f010411b <strtol+0x80>
			dig = *s - '0';
f0104146:	0f be d2             	movsbl %dl,%edx
f0104149:	83 ea 30             	sub    $0x30,%edx
f010414c:	eb dd                	jmp    f010412b <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f010414e:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104151:	89 f3                	mov    %esi,%ebx
f0104153:	80 fb 19             	cmp    $0x19,%bl
f0104156:	77 08                	ja     f0104160 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0104158:	0f be d2             	movsbl %dl,%edx
f010415b:	83 ea 37             	sub    $0x37,%edx
f010415e:	eb cb                	jmp    f010412b <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0104160:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104164:	74 05                	je     f010416b <strtol+0xd0>
		*endptr = (char *) s;
f0104166:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104169:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f010416b:	89 c2                	mov    %eax,%edx
f010416d:	f7 da                	neg    %edx
f010416f:	85 ff                	test   %edi,%edi
f0104171:	0f 45 c2             	cmovne %edx,%eax
}
f0104174:	5b                   	pop    %ebx
f0104175:	5e                   	pop    %esi
f0104176:	5f                   	pop    %edi
f0104177:	5d                   	pop    %ebp
f0104178:	c3                   	ret    
f0104179:	66 90                	xchg   %ax,%ax
f010417b:	66 90                	xchg   %ax,%ax
f010417d:	66 90                	xchg   %ax,%ax
f010417f:	90                   	nop

f0104180 <__udivdi3>:
f0104180:	55                   	push   %ebp
f0104181:	57                   	push   %edi
f0104182:	56                   	push   %esi
f0104183:	53                   	push   %ebx
f0104184:	83 ec 1c             	sub    $0x1c,%esp
f0104187:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010418b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f010418f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104193:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0104197:	85 d2                	test   %edx,%edx
f0104199:	75 35                	jne    f01041d0 <__udivdi3+0x50>
f010419b:	39 f3                	cmp    %esi,%ebx
f010419d:	0f 87 bd 00 00 00    	ja     f0104260 <__udivdi3+0xe0>
f01041a3:	85 db                	test   %ebx,%ebx
f01041a5:	89 d9                	mov    %ebx,%ecx
f01041a7:	75 0b                	jne    f01041b4 <__udivdi3+0x34>
f01041a9:	b8 01 00 00 00       	mov    $0x1,%eax
f01041ae:	31 d2                	xor    %edx,%edx
f01041b0:	f7 f3                	div    %ebx
f01041b2:	89 c1                	mov    %eax,%ecx
f01041b4:	31 d2                	xor    %edx,%edx
f01041b6:	89 f0                	mov    %esi,%eax
f01041b8:	f7 f1                	div    %ecx
f01041ba:	89 c6                	mov    %eax,%esi
f01041bc:	89 e8                	mov    %ebp,%eax
f01041be:	89 f7                	mov    %esi,%edi
f01041c0:	f7 f1                	div    %ecx
f01041c2:	89 fa                	mov    %edi,%edx
f01041c4:	83 c4 1c             	add    $0x1c,%esp
f01041c7:	5b                   	pop    %ebx
f01041c8:	5e                   	pop    %esi
f01041c9:	5f                   	pop    %edi
f01041ca:	5d                   	pop    %ebp
f01041cb:	c3                   	ret    
f01041cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01041d0:	39 f2                	cmp    %esi,%edx
f01041d2:	77 7c                	ja     f0104250 <__udivdi3+0xd0>
f01041d4:	0f bd fa             	bsr    %edx,%edi
f01041d7:	83 f7 1f             	xor    $0x1f,%edi
f01041da:	0f 84 98 00 00 00    	je     f0104278 <__udivdi3+0xf8>
f01041e0:	89 f9                	mov    %edi,%ecx
f01041e2:	b8 20 00 00 00       	mov    $0x20,%eax
f01041e7:	29 f8                	sub    %edi,%eax
f01041e9:	d3 e2                	shl    %cl,%edx
f01041eb:	89 54 24 08          	mov    %edx,0x8(%esp)
f01041ef:	89 c1                	mov    %eax,%ecx
f01041f1:	89 da                	mov    %ebx,%edx
f01041f3:	d3 ea                	shr    %cl,%edx
f01041f5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f01041f9:	09 d1                	or     %edx,%ecx
f01041fb:	89 f2                	mov    %esi,%edx
f01041fd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104201:	89 f9                	mov    %edi,%ecx
f0104203:	d3 e3                	shl    %cl,%ebx
f0104205:	89 c1                	mov    %eax,%ecx
f0104207:	d3 ea                	shr    %cl,%edx
f0104209:	89 f9                	mov    %edi,%ecx
f010420b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010420f:	d3 e6                	shl    %cl,%esi
f0104211:	89 eb                	mov    %ebp,%ebx
f0104213:	89 c1                	mov    %eax,%ecx
f0104215:	d3 eb                	shr    %cl,%ebx
f0104217:	09 de                	or     %ebx,%esi
f0104219:	89 f0                	mov    %esi,%eax
f010421b:	f7 74 24 08          	divl   0x8(%esp)
f010421f:	89 d6                	mov    %edx,%esi
f0104221:	89 c3                	mov    %eax,%ebx
f0104223:	f7 64 24 0c          	mull   0xc(%esp)
f0104227:	39 d6                	cmp    %edx,%esi
f0104229:	72 0c                	jb     f0104237 <__udivdi3+0xb7>
f010422b:	89 f9                	mov    %edi,%ecx
f010422d:	d3 e5                	shl    %cl,%ebp
f010422f:	39 c5                	cmp    %eax,%ebp
f0104231:	73 5d                	jae    f0104290 <__udivdi3+0x110>
f0104233:	39 d6                	cmp    %edx,%esi
f0104235:	75 59                	jne    f0104290 <__udivdi3+0x110>
f0104237:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010423a:	31 ff                	xor    %edi,%edi
f010423c:	89 fa                	mov    %edi,%edx
f010423e:	83 c4 1c             	add    $0x1c,%esp
f0104241:	5b                   	pop    %ebx
f0104242:	5e                   	pop    %esi
f0104243:	5f                   	pop    %edi
f0104244:	5d                   	pop    %ebp
f0104245:	c3                   	ret    
f0104246:	8d 76 00             	lea    0x0(%esi),%esi
f0104249:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0104250:	31 ff                	xor    %edi,%edi
f0104252:	31 c0                	xor    %eax,%eax
f0104254:	89 fa                	mov    %edi,%edx
f0104256:	83 c4 1c             	add    $0x1c,%esp
f0104259:	5b                   	pop    %ebx
f010425a:	5e                   	pop    %esi
f010425b:	5f                   	pop    %edi
f010425c:	5d                   	pop    %ebp
f010425d:	c3                   	ret    
f010425e:	66 90                	xchg   %ax,%ax
f0104260:	31 ff                	xor    %edi,%edi
f0104262:	89 e8                	mov    %ebp,%eax
f0104264:	89 f2                	mov    %esi,%edx
f0104266:	f7 f3                	div    %ebx
f0104268:	89 fa                	mov    %edi,%edx
f010426a:	83 c4 1c             	add    $0x1c,%esp
f010426d:	5b                   	pop    %ebx
f010426e:	5e                   	pop    %esi
f010426f:	5f                   	pop    %edi
f0104270:	5d                   	pop    %ebp
f0104271:	c3                   	ret    
f0104272:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104278:	39 f2                	cmp    %esi,%edx
f010427a:	72 06                	jb     f0104282 <__udivdi3+0x102>
f010427c:	31 c0                	xor    %eax,%eax
f010427e:	39 eb                	cmp    %ebp,%ebx
f0104280:	77 d2                	ja     f0104254 <__udivdi3+0xd4>
f0104282:	b8 01 00 00 00       	mov    $0x1,%eax
f0104287:	eb cb                	jmp    f0104254 <__udivdi3+0xd4>
f0104289:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104290:	89 d8                	mov    %ebx,%eax
f0104292:	31 ff                	xor    %edi,%edi
f0104294:	eb be                	jmp    f0104254 <__udivdi3+0xd4>
f0104296:	66 90                	xchg   %ax,%ax
f0104298:	66 90                	xchg   %ax,%ax
f010429a:	66 90                	xchg   %ax,%ax
f010429c:	66 90                	xchg   %ax,%ax
f010429e:	66 90                	xchg   %ax,%ax

f01042a0 <__umoddi3>:
f01042a0:	55                   	push   %ebp
f01042a1:	57                   	push   %edi
f01042a2:	56                   	push   %esi
f01042a3:	53                   	push   %ebx
f01042a4:	83 ec 1c             	sub    $0x1c,%esp
f01042a7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f01042ab:	8b 74 24 30          	mov    0x30(%esp),%esi
f01042af:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f01042b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01042b7:	85 ed                	test   %ebp,%ebp
f01042b9:	89 f0                	mov    %esi,%eax
f01042bb:	89 da                	mov    %ebx,%edx
f01042bd:	75 19                	jne    f01042d8 <__umoddi3+0x38>
f01042bf:	39 df                	cmp    %ebx,%edi
f01042c1:	0f 86 b1 00 00 00    	jbe    f0104378 <__umoddi3+0xd8>
f01042c7:	f7 f7                	div    %edi
f01042c9:	89 d0                	mov    %edx,%eax
f01042cb:	31 d2                	xor    %edx,%edx
f01042cd:	83 c4 1c             	add    $0x1c,%esp
f01042d0:	5b                   	pop    %ebx
f01042d1:	5e                   	pop    %esi
f01042d2:	5f                   	pop    %edi
f01042d3:	5d                   	pop    %ebp
f01042d4:	c3                   	ret    
f01042d5:	8d 76 00             	lea    0x0(%esi),%esi
f01042d8:	39 dd                	cmp    %ebx,%ebp
f01042da:	77 f1                	ja     f01042cd <__umoddi3+0x2d>
f01042dc:	0f bd cd             	bsr    %ebp,%ecx
f01042df:	83 f1 1f             	xor    $0x1f,%ecx
f01042e2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01042e6:	0f 84 b4 00 00 00    	je     f01043a0 <__umoddi3+0x100>
f01042ec:	b8 20 00 00 00       	mov    $0x20,%eax
f01042f1:	89 c2                	mov    %eax,%edx
f01042f3:	8b 44 24 04          	mov    0x4(%esp),%eax
f01042f7:	29 c2                	sub    %eax,%edx
f01042f9:	89 c1                	mov    %eax,%ecx
f01042fb:	89 f8                	mov    %edi,%eax
f01042fd:	d3 e5                	shl    %cl,%ebp
f01042ff:	89 d1                	mov    %edx,%ecx
f0104301:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104305:	d3 e8                	shr    %cl,%eax
f0104307:	09 c5                	or     %eax,%ebp
f0104309:	8b 44 24 04          	mov    0x4(%esp),%eax
f010430d:	89 c1                	mov    %eax,%ecx
f010430f:	d3 e7                	shl    %cl,%edi
f0104311:	89 d1                	mov    %edx,%ecx
f0104313:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104317:	89 df                	mov    %ebx,%edi
f0104319:	d3 ef                	shr    %cl,%edi
f010431b:	89 c1                	mov    %eax,%ecx
f010431d:	89 f0                	mov    %esi,%eax
f010431f:	d3 e3                	shl    %cl,%ebx
f0104321:	89 d1                	mov    %edx,%ecx
f0104323:	89 fa                	mov    %edi,%edx
f0104325:	d3 e8                	shr    %cl,%eax
f0104327:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010432c:	09 d8                	or     %ebx,%eax
f010432e:	f7 f5                	div    %ebp
f0104330:	d3 e6                	shl    %cl,%esi
f0104332:	89 d1                	mov    %edx,%ecx
f0104334:	f7 64 24 08          	mull   0x8(%esp)
f0104338:	39 d1                	cmp    %edx,%ecx
f010433a:	89 c3                	mov    %eax,%ebx
f010433c:	89 d7                	mov    %edx,%edi
f010433e:	72 06                	jb     f0104346 <__umoddi3+0xa6>
f0104340:	75 0e                	jne    f0104350 <__umoddi3+0xb0>
f0104342:	39 c6                	cmp    %eax,%esi
f0104344:	73 0a                	jae    f0104350 <__umoddi3+0xb0>
f0104346:	2b 44 24 08          	sub    0x8(%esp),%eax
f010434a:	19 ea                	sbb    %ebp,%edx
f010434c:	89 d7                	mov    %edx,%edi
f010434e:	89 c3                	mov    %eax,%ebx
f0104350:	89 ca                	mov    %ecx,%edx
f0104352:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0104357:	29 de                	sub    %ebx,%esi
f0104359:	19 fa                	sbb    %edi,%edx
f010435b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f010435f:	89 d0                	mov    %edx,%eax
f0104361:	d3 e0                	shl    %cl,%eax
f0104363:	89 d9                	mov    %ebx,%ecx
f0104365:	d3 ee                	shr    %cl,%esi
f0104367:	d3 ea                	shr    %cl,%edx
f0104369:	09 f0                	or     %esi,%eax
f010436b:	83 c4 1c             	add    $0x1c,%esp
f010436e:	5b                   	pop    %ebx
f010436f:	5e                   	pop    %esi
f0104370:	5f                   	pop    %edi
f0104371:	5d                   	pop    %ebp
f0104372:	c3                   	ret    
f0104373:	90                   	nop
f0104374:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104378:	85 ff                	test   %edi,%edi
f010437a:	89 f9                	mov    %edi,%ecx
f010437c:	75 0b                	jne    f0104389 <__umoddi3+0xe9>
f010437e:	b8 01 00 00 00       	mov    $0x1,%eax
f0104383:	31 d2                	xor    %edx,%edx
f0104385:	f7 f7                	div    %edi
f0104387:	89 c1                	mov    %eax,%ecx
f0104389:	89 d8                	mov    %ebx,%eax
f010438b:	31 d2                	xor    %edx,%edx
f010438d:	f7 f1                	div    %ecx
f010438f:	89 f0                	mov    %esi,%eax
f0104391:	f7 f1                	div    %ecx
f0104393:	e9 31 ff ff ff       	jmp    f01042c9 <__umoddi3+0x29>
f0104398:	90                   	nop
f0104399:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01043a0:	39 dd                	cmp    %ebx,%ebp
f01043a2:	72 08                	jb     f01043ac <__umoddi3+0x10c>
f01043a4:	39 f7                	cmp    %esi,%edi
f01043a6:	0f 87 21 ff ff ff    	ja     f01042cd <__umoddi3+0x2d>
f01043ac:	89 da                	mov    %ebx,%edx
f01043ae:	89 f0                	mov    %esi,%eax
f01043b0:	29 f8                	sub    %edi,%eax
f01043b2:	19 ea                	sbb    %ebp,%edx
f01043b4:	e9 14 ff ff ff       	jmp    f01042cd <__umoddi3+0x2d>
