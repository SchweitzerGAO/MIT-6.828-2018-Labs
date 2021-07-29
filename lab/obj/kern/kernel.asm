
obj/kern/kernel：     文件格式 elf32-i386


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
f0100040:	f3 0f 1e fb          	endbr32 
f0100044:	55                   	push   %ebp
f0100045:	89 e5                	mov    %esp,%ebp
f0100047:	53                   	push   %ebx
f0100048:	83 ec 08             	sub    $0x8,%esp
f010004b:	e8 0b 01 00 00       	call   f010015b <__x86.get_pc_thunk.bx>
f0100050:	81 c3 b8 82 01 00    	add    $0x182b8,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100056:	c7 c2 60 a0 11 f0    	mov    $0xf011a060,%edx
f010005c:	c7 c0 c0 a6 11 f0    	mov    $0xf011a6c0,%eax
f0100062:	29 d0                	sub    %edx,%eax
f0100064:	50                   	push   %eax
f0100065:	6a 00                	push   $0x0
f0100067:	52                   	push   %edx
f0100068:	e8 44 3b 00 00       	call   f0103bb1 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010006d:	e8 44 05 00 00       	call   f01005b6 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	68 ac 1a 00 00       	push   $0x1aac
f010007a:	8d 83 18 bd fe ff    	lea    -0x142e8(%ebx),%eax
f0100080:	50                   	push   %eax
f0100081:	e8 26 2f 00 00       	call   f0102fac <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100086:	e8 e5 12 00 00       	call   f0101370 <mem_init>
f010008b:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010008e:	83 ec 0c             	sub    $0xc,%esp
f0100091:	6a 00                	push   $0x0
f0100093:	e8 91 08 00 00       	call   f0100929 <monitor>
f0100098:	83 c4 10             	add    $0x10,%esp
f010009b:	eb f1                	jmp    f010008e <i386_init+0x4e>

f010009d <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010009d:	f3 0f 1e fb          	endbr32 
f01000a1:	55                   	push   %ebp
f01000a2:	89 e5                	mov    %esp,%ebp
f01000a4:	57                   	push   %edi
f01000a5:	56                   	push   %esi
f01000a6:	53                   	push   %ebx
f01000a7:	83 ec 0c             	sub    $0xc,%esp
f01000aa:	e8 ac 00 00 00       	call   f010015b <__x86.get_pc_thunk.bx>
f01000af:	81 c3 59 82 01 00    	add    $0x18259,%ebx
f01000b5:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000b8:	c7 c0 c4 a6 11 f0    	mov    $0xf011a6c4,%eax
f01000be:	83 38 00             	cmpl   $0x0,(%eax)
f01000c1:	74 0f                	je     f01000d2 <_panic+0x35>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000c3:	83 ec 0c             	sub    $0xc,%esp
f01000c6:	6a 00                	push   $0x0
f01000c8:	e8 5c 08 00 00       	call   f0100929 <monitor>
f01000cd:	83 c4 10             	add    $0x10,%esp
f01000d0:	eb f1                	jmp    f01000c3 <_panic+0x26>
	panicstr = fmt;
f01000d2:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f01000d4:	fa                   	cli    
f01000d5:	fc                   	cld    
	va_start(ap, fmt);
f01000d6:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d9:	83 ec 04             	sub    $0x4,%esp
f01000dc:	ff 75 0c             	pushl  0xc(%ebp)
f01000df:	ff 75 08             	pushl  0x8(%ebp)
f01000e2:	8d 83 33 bd fe ff    	lea    -0x142cd(%ebx),%eax
f01000e8:	50                   	push   %eax
f01000e9:	e8 be 2e 00 00       	call   f0102fac <cprintf>
	vcprintf(fmt, ap);
f01000ee:	83 c4 08             	add    $0x8,%esp
f01000f1:	56                   	push   %esi
f01000f2:	57                   	push   %edi
f01000f3:	e8 79 2e 00 00       	call   f0102f71 <vcprintf>
	cprintf("\n");
f01000f8:	8d 83 66 cc fe ff    	lea    -0x1339a(%ebx),%eax
f01000fe:	89 04 24             	mov    %eax,(%esp)
f0100101:	e8 a6 2e 00 00       	call   f0102fac <cprintf>
f0100106:	83 c4 10             	add    $0x10,%esp
f0100109:	eb b8                	jmp    f01000c3 <_panic+0x26>

f010010b <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010010b:	f3 0f 1e fb          	endbr32 
f010010f:	55                   	push   %ebp
f0100110:	89 e5                	mov    %esp,%ebp
f0100112:	56                   	push   %esi
f0100113:	53                   	push   %ebx
f0100114:	e8 42 00 00 00       	call   f010015b <__x86.get_pc_thunk.bx>
f0100119:	81 c3 ef 81 01 00    	add    $0x181ef,%ebx
	va_list ap;

	va_start(ap, fmt);
f010011f:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100122:	83 ec 04             	sub    $0x4,%esp
f0100125:	ff 75 0c             	pushl  0xc(%ebp)
f0100128:	ff 75 08             	pushl  0x8(%ebp)
f010012b:	8d 83 4b bd fe ff    	lea    -0x142b5(%ebx),%eax
f0100131:	50                   	push   %eax
f0100132:	e8 75 2e 00 00       	call   f0102fac <cprintf>
	vcprintf(fmt, ap);
f0100137:	83 c4 08             	add    $0x8,%esp
f010013a:	56                   	push   %esi
f010013b:	ff 75 10             	pushl  0x10(%ebp)
f010013e:	e8 2e 2e 00 00       	call   f0102f71 <vcprintf>
	cprintf("\n");
f0100143:	8d 83 66 cc fe ff    	lea    -0x1339a(%ebx),%eax
f0100149:	89 04 24             	mov    %eax,(%esp)
f010014c:	e8 5b 2e 00 00       	call   f0102fac <cprintf>
	va_end(ap);
}
f0100151:	83 c4 10             	add    $0x10,%esp
f0100154:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100157:	5b                   	pop    %ebx
f0100158:	5e                   	pop    %esi
f0100159:	5d                   	pop    %ebp
f010015a:	c3                   	ret    

f010015b <__x86.get_pc_thunk.bx>:
f010015b:	8b 1c 24             	mov    (%esp),%ebx
f010015e:	c3                   	ret    

f010015f <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010015f:	f3 0f 1e fb          	endbr32 

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100163:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100168:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100169:	a8 01                	test   $0x1,%al
f010016b:	74 0a                	je     f0100177 <serial_proc_data+0x18>
f010016d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100172:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100173:	0f b6 c0             	movzbl %al,%eax
f0100176:	c3                   	ret    
		return -1;
f0100177:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f010017c:	c3                   	ret    

f010017d <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010017d:	55                   	push   %ebp
f010017e:	89 e5                	mov    %esp,%ebp
f0100180:	57                   	push   %edi
f0100181:	56                   	push   %esi
f0100182:	53                   	push   %ebx
f0100183:	83 ec 1c             	sub    $0x1c,%esp
f0100186:	e8 88 05 00 00       	call   f0100713 <__x86.get_pc_thunk.si>
f010018b:	81 c6 7d 81 01 00    	add    $0x1817d,%esi
f0100191:	89 c7                	mov    %eax,%edi
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
		cons.buf[cons.wpos++] = c;
f0100193:	8d 1d 78 1d 00 00    	lea    0x1d78,%ebx
f0100199:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
f010019c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010019f:	89 7d e4             	mov    %edi,-0x1c(%ebp)
	while ((c = (*proc)()) != -1) {
f01001a2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01001a5:	ff d0                	call   *%eax
f01001a7:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001aa:	74 2b                	je     f01001d7 <cons_intr+0x5a>
		if (c == 0)
f01001ac:	85 c0                	test   %eax,%eax
f01001ae:	74 f2                	je     f01001a2 <cons_intr+0x25>
		cons.buf[cons.wpos++] = c;
f01001b0:	8b 8c 1e 04 02 00 00 	mov    0x204(%esi,%ebx,1),%ecx
f01001b7:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ba:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01001bd:	88 04 0f             	mov    %al,(%edi,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001c0:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01001cb:	0f 44 d0             	cmove  %eax,%edx
f01001ce:	89 94 1e 04 02 00 00 	mov    %edx,0x204(%esi,%ebx,1)
f01001d5:	eb cb                	jmp    f01001a2 <cons_intr+0x25>
	}
}
f01001d7:	83 c4 1c             	add    $0x1c,%esp
f01001da:	5b                   	pop    %ebx
f01001db:	5e                   	pop    %esi
f01001dc:	5f                   	pop    %edi
f01001dd:	5d                   	pop    %ebp
f01001de:	c3                   	ret    

f01001df <kbd_proc_data>:
{
f01001df:	f3 0f 1e fb          	endbr32 
f01001e3:	55                   	push   %ebp
f01001e4:	89 e5                	mov    %esp,%ebp
f01001e6:	56                   	push   %esi
f01001e7:	53                   	push   %ebx
f01001e8:	e8 6e ff ff ff       	call   f010015b <__x86.get_pc_thunk.bx>
f01001ed:	81 c3 1b 81 01 00    	add    $0x1811b,%ebx
f01001f3:	ba 64 00 00 00       	mov    $0x64,%edx
f01001f8:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001f9:	a8 01                	test   $0x1,%al
f01001fb:	0f 84 fb 00 00 00    	je     f01002fc <kbd_proc_data+0x11d>
	if (stat & KBS_TERR)
f0100201:	a8 20                	test   $0x20,%al
f0100203:	0f 85 fa 00 00 00    	jne    f0100303 <kbd_proc_data+0x124>
f0100209:	ba 60 00 00 00       	mov    $0x60,%edx
f010020e:	ec                   	in     (%dx),%al
f010020f:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f0100211:	3c e0                	cmp    $0xe0,%al
f0100213:	74 64                	je     f0100279 <kbd_proc_data+0x9a>
	} else if (data & 0x80) {
f0100215:	84 c0                	test   %al,%al
f0100217:	78 75                	js     f010028e <kbd_proc_data+0xaf>
	} else if (shift & E0ESC) {
f0100219:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f010021f:	f6 c1 40             	test   $0x40,%cl
f0100222:	74 0e                	je     f0100232 <kbd_proc_data+0x53>
		data |= 0x80;
f0100224:	83 c8 80             	or     $0xffffff80,%eax
f0100227:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100229:	83 e1 bf             	and    $0xffffffbf,%ecx
f010022c:	89 8b 58 1d 00 00    	mov    %ecx,0x1d58(%ebx)
	shift |= shiftcode[data];
f0100232:	0f b6 d2             	movzbl %dl,%edx
f0100235:	0f b6 84 13 98 be fe 	movzbl -0x14168(%ebx,%edx,1),%eax
f010023c:	ff 
f010023d:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f0100243:	0f b6 8c 13 98 bd fe 	movzbl -0x14268(%ebx,%edx,1),%ecx
f010024a:	ff 
f010024b:	31 c8                	xor    %ecx,%eax
f010024d:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f0100253:	89 c1                	mov    %eax,%ecx
f0100255:	83 e1 03             	and    $0x3,%ecx
f0100258:	8b 8c 8b f8 1c 00 00 	mov    0x1cf8(%ebx,%ecx,4),%ecx
f010025f:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100263:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100266:	a8 08                	test   $0x8,%al
f0100268:	74 65                	je     f01002cf <kbd_proc_data+0xf0>
		if ('a' <= c && c <= 'z')
f010026a:	89 f2                	mov    %esi,%edx
f010026c:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f010026f:	83 f9 19             	cmp    $0x19,%ecx
f0100272:	77 4f                	ja     f01002c3 <kbd_proc_data+0xe4>
			c += 'A' - 'a';
f0100274:	83 ee 20             	sub    $0x20,%esi
f0100277:	eb 0c                	jmp    f0100285 <kbd_proc_data+0xa6>
		shift |= E0ESC;
f0100279:	83 8b 58 1d 00 00 40 	orl    $0x40,0x1d58(%ebx)
		return 0;
f0100280:	be 00 00 00 00       	mov    $0x0,%esi
}
f0100285:	89 f0                	mov    %esi,%eax
f0100287:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010028a:	5b                   	pop    %ebx
f010028b:	5e                   	pop    %esi
f010028c:	5d                   	pop    %ebp
f010028d:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010028e:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f0100294:	89 ce                	mov    %ecx,%esi
f0100296:	83 e6 40             	and    $0x40,%esi
f0100299:	83 e0 7f             	and    $0x7f,%eax
f010029c:	85 f6                	test   %esi,%esi
f010029e:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002a1:	0f b6 d2             	movzbl %dl,%edx
f01002a4:	0f b6 84 13 98 be fe 	movzbl -0x14168(%ebx,%edx,1),%eax
f01002ab:	ff 
f01002ac:	83 c8 40             	or     $0x40,%eax
f01002af:	0f b6 c0             	movzbl %al,%eax
f01002b2:	f7 d0                	not    %eax
f01002b4:	21 c8                	and    %ecx,%eax
f01002b6:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
		return 0;
f01002bc:	be 00 00 00 00       	mov    $0x0,%esi
f01002c1:	eb c2                	jmp    f0100285 <kbd_proc_data+0xa6>
		else if ('A' <= c && c <= 'Z')
f01002c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c6:	8d 4e 20             	lea    0x20(%esi),%ecx
f01002c9:	83 fa 1a             	cmp    $0x1a,%edx
f01002cc:	0f 42 f1             	cmovb  %ecx,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	a8 06                	test   $0x6,%al
f01002d3:	75 b0                	jne    f0100285 <kbd_proc_data+0xa6>
f01002d5:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f01002db:	75 a8                	jne    f0100285 <kbd_proc_data+0xa6>
		cprintf("Rebooting!\n");
f01002dd:	83 ec 0c             	sub    $0xc,%esp
f01002e0:	8d 83 65 bd fe ff    	lea    -0x1429b(%ebx),%eax
f01002e6:	50                   	push   %eax
f01002e7:	e8 c0 2c 00 00       	call   f0102fac <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ec:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f1:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f6:	ee                   	out    %al,(%dx)
}
f01002f7:	83 c4 10             	add    $0x10,%esp
f01002fa:	eb 89                	jmp    f0100285 <kbd_proc_data+0xa6>
		return -1;
f01002fc:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100301:	eb 82                	jmp    f0100285 <kbd_proc_data+0xa6>
		return -1;
f0100303:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100308:	e9 78 ff ff ff       	jmp    f0100285 <kbd_proc_data+0xa6>

f010030d <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010030d:	55                   	push   %ebp
f010030e:	89 e5                	mov    %esp,%ebp
f0100310:	57                   	push   %edi
f0100311:	56                   	push   %esi
f0100312:	53                   	push   %ebx
f0100313:	83 ec 1c             	sub    $0x1c,%esp
f0100316:	e8 40 fe ff ff       	call   f010015b <__x86.get_pc_thunk.bx>
f010031b:	81 c3 ed 7f 01 00    	add    $0x17fed,%ebx
f0100321:	89 c7                	mov    %eax,%edi
	for (i = 0;
f0100323:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100328:	b9 84 00 00 00       	mov    $0x84,%ecx
f010032d:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100332:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100333:	a8 20                	test   $0x20,%al
f0100335:	75 13                	jne    f010034a <cons_putc+0x3d>
f0100337:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010033d:	7f 0b                	jg     f010034a <cons_putc+0x3d>
f010033f:	89 ca                	mov    %ecx,%edx
f0100341:	ec                   	in     (%dx),%al
f0100342:	ec                   	in     (%dx),%al
f0100343:	ec                   	in     (%dx),%al
f0100344:	ec                   	in     (%dx),%al
	     i++)
f0100345:	83 c6 01             	add    $0x1,%esi
f0100348:	eb e3                	jmp    f010032d <cons_putc+0x20>
	outb(COM1 + COM_TX, c);
f010034a:	89 f8                	mov    %edi,%eax
f010034c:	88 45 e7             	mov    %al,-0x19(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100354:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100355:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010035a:	b9 84 00 00 00       	mov    $0x84,%ecx
f010035f:	ba 79 03 00 00       	mov    $0x379,%edx
f0100364:	ec                   	in     (%dx),%al
f0100365:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010036b:	7f 0f                	jg     f010037c <cons_putc+0x6f>
f010036d:	84 c0                	test   %al,%al
f010036f:	78 0b                	js     f010037c <cons_putc+0x6f>
f0100371:	89 ca                	mov    %ecx,%edx
f0100373:	ec                   	in     (%dx),%al
f0100374:	ec                   	in     (%dx),%al
f0100375:	ec                   	in     (%dx),%al
f0100376:	ec                   	in     (%dx),%al
f0100377:	83 c6 01             	add    $0x1,%esi
f010037a:	eb e3                	jmp    f010035f <cons_putc+0x52>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010037c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100381:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100385:	ee                   	out    %al,(%dx)
f0100386:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010038b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100390:	ee                   	out    %al,(%dx)
f0100391:	b8 08 00 00 00       	mov    $0x8,%eax
f0100396:	ee                   	out    %al,(%dx)
		c |= 0x0700;
f0100397:	89 f8                	mov    %edi,%eax
f0100399:	80 cc 07             	or     $0x7,%ah
f010039c:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f01003a2:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f01003a5:	89 f8                	mov    %edi,%eax
f01003a7:	0f b6 c0             	movzbl %al,%eax
f01003aa:	89 f9                	mov    %edi,%ecx
f01003ac:	80 f9 0a             	cmp    $0xa,%cl
f01003af:	0f 84 e2 00 00 00    	je     f0100497 <cons_putc+0x18a>
f01003b5:	83 f8 0a             	cmp    $0xa,%eax
f01003b8:	7f 46                	jg     f0100400 <cons_putc+0xf3>
f01003ba:	83 f8 08             	cmp    $0x8,%eax
f01003bd:	0f 84 a8 00 00 00    	je     f010046b <cons_putc+0x15e>
f01003c3:	83 f8 09             	cmp    $0x9,%eax
f01003c6:	0f 85 d8 00 00 00    	jne    f01004a4 <cons_putc+0x197>
		cons_putc(' ');
f01003cc:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d1:	e8 37 ff ff ff       	call   f010030d <cons_putc>
		cons_putc(' ');
f01003d6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003db:	e8 2d ff ff ff       	call   f010030d <cons_putc>
		cons_putc(' ');
f01003e0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e5:	e8 23 ff ff ff       	call   f010030d <cons_putc>
		cons_putc(' ');
f01003ea:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ef:	e8 19 ff ff ff       	call   f010030d <cons_putc>
		cons_putc(' ');
f01003f4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f9:	e8 0f ff ff ff       	call   f010030d <cons_putc>
		break;
f01003fe:	eb 26                	jmp    f0100426 <cons_putc+0x119>
	switch (c & 0xff) {
f0100400:	83 f8 0d             	cmp    $0xd,%eax
f0100403:	0f 85 9b 00 00 00    	jne    f01004a4 <cons_putc+0x197>
		crt_pos -= (crt_pos % CRT_COLS);
f0100409:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f0100410:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100416:	c1 e8 16             	shr    $0x16,%eax
f0100419:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010041c:	c1 e0 04             	shl    $0x4,%eax
f010041f:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
	if (crt_pos >= CRT_SIZE) {
f0100426:	66 81 bb 80 1f 00 00 	cmpw   $0x7cf,0x1f80(%ebx)
f010042d:	cf 07 
f010042f:	0f 87 92 00 00 00    	ja     f01004c7 <cons_putc+0x1ba>
	outb(addr_6845, 14);
f0100435:	8b 8b 88 1f 00 00    	mov    0x1f88(%ebx),%ecx
f010043b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100440:	89 ca                	mov    %ecx,%edx
f0100442:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100443:	0f b7 9b 80 1f 00 00 	movzwl 0x1f80(%ebx),%ebx
f010044a:	8d 71 01             	lea    0x1(%ecx),%esi
f010044d:	89 d8                	mov    %ebx,%eax
f010044f:	66 c1 e8 08          	shr    $0x8,%ax
f0100453:	89 f2                	mov    %esi,%edx
f0100455:	ee                   	out    %al,(%dx)
f0100456:	b8 0f 00 00 00       	mov    $0xf,%eax
f010045b:	89 ca                	mov    %ecx,%edx
f010045d:	ee                   	out    %al,(%dx)
f010045e:	89 d8                	mov    %ebx,%eax
f0100460:	89 f2                	mov    %esi,%edx
f0100462:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100463:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100466:	5b                   	pop    %ebx
f0100467:	5e                   	pop    %esi
f0100468:	5f                   	pop    %edi
f0100469:	5d                   	pop    %ebp
f010046a:	c3                   	ret    
		if (crt_pos > 0) {
f010046b:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f0100472:	66 85 c0             	test   %ax,%ax
f0100475:	74 be                	je     f0100435 <cons_putc+0x128>
			crt_pos--;
f0100477:	83 e8 01             	sub    $0x1,%eax
f010047a:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100481:	0f b7 c0             	movzwl %ax,%eax
f0100484:	89 fa                	mov    %edi,%edx
f0100486:	b2 00                	mov    $0x0,%dl
f0100488:	83 ca 20             	or     $0x20,%edx
f010048b:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f0100491:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f0100495:	eb 8f                	jmp    f0100426 <cons_putc+0x119>
		crt_pos += CRT_COLS;
f0100497:	66 83 83 80 1f 00 00 	addw   $0x50,0x1f80(%ebx)
f010049e:	50 
f010049f:	e9 65 ff ff ff       	jmp    f0100409 <cons_putc+0xfc>
		crt_buf[crt_pos++] = c;		/* write the character */
f01004a4:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f01004ab:	8d 50 01             	lea    0x1(%eax),%edx
f01004ae:	66 89 93 80 1f 00 00 	mov    %dx,0x1f80(%ebx)
f01004b5:	0f b7 c0             	movzwl %ax,%eax
f01004b8:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f01004be:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
f01004c2:	e9 5f ff ff ff       	jmp    f0100426 <cons_putc+0x119>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004c7:	8b 83 84 1f 00 00    	mov    0x1f84(%ebx),%eax
f01004cd:	83 ec 04             	sub    $0x4,%esp
f01004d0:	68 00 0f 00 00       	push   $0xf00
f01004d5:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004db:	52                   	push   %edx
f01004dc:	50                   	push   %eax
f01004dd:	e8 1b 37 00 00       	call   f0103bfd <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004e2:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f01004e8:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004ee:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004f4:	83 c4 10             	add    $0x10,%esp
f01004f7:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004fc:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004ff:	39 d0                	cmp    %edx,%eax
f0100501:	75 f4                	jne    f01004f7 <cons_putc+0x1ea>
		crt_pos -= CRT_COLS;
f0100503:	66 83 ab 80 1f 00 00 	subw   $0x50,0x1f80(%ebx)
f010050a:	50 
f010050b:	e9 25 ff ff ff       	jmp    f0100435 <cons_putc+0x128>

f0100510 <serial_intr>:
{
f0100510:	f3 0f 1e fb          	endbr32 
f0100514:	e8 f6 01 00 00       	call   f010070f <__x86.get_pc_thunk.ax>
f0100519:	05 ef 7d 01 00       	add    $0x17def,%eax
	if (serial_exists)
f010051e:	80 b8 8c 1f 00 00 00 	cmpb   $0x0,0x1f8c(%eax)
f0100525:	75 01                	jne    f0100528 <serial_intr+0x18>
f0100527:	c3                   	ret    
{
f0100528:	55                   	push   %ebp
f0100529:	89 e5                	mov    %esp,%ebp
f010052b:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f010052e:	8d 80 57 7e fe ff    	lea    -0x181a9(%eax),%eax
f0100534:	e8 44 fc ff ff       	call   f010017d <cons_intr>
}
f0100539:	c9                   	leave  
f010053a:	c3                   	ret    

f010053b <kbd_intr>:
{
f010053b:	f3 0f 1e fb          	endbr32 
f010053f:	55                   	push   %ebp
f0100540:	89 e5                	mov    %esp,%ebp
f0100542:	83 ec 08             	sub    $0x8,%esp
f0100545:	e8 c5 01 00 00       	call   f010070f <__x86.get_pc_thunk.ax>
f010054a:	05 be 7d 01 00       	add    $0x17dbe,%eax
	cons_intr(kbd_proc_data);
f010054f:	8d 80 d7 7e fe ff    	lea    -0x18129(%eax),%eax
f0100555:	e8 23 fc ff ff       	call   f010017d <cons_intr>
}
f010055a:	c9                   	leave  
f010055b:	c3                   	ret    

f010055c <cons_getc>:
{
f010055c:	f3 0f 1e fb          	endbr32 
f0100560:	55                   	push   %ebp
f0100561:	89 e5                	mov    %esp,%ebp
f0100563:	53                   	push   %ebx
f0100564:	83 ec 04             	sub    $0x4,%esp
f0100567:	e8 ef fb ff ff       	call   f010015b <__x86.get_pc_thunk.bx>
f010056c:	81 c3 9c 7d 01 00    	add    $0x17d9c,%ebx
	serial_intr();
f0100572:	e8 99 ff ff ff       	call   f0100510 <serial_intr>
	kbd_intr();
f0100577:	e8 bf ff ff ff       	call   f010053b <kbd_intr>
	if (cons.rpos != cons.wpos) {
f010057c:	8b 83 78 1f 00 00    	mov    0x1f78(%ebx),%eax
	return 0;
f0100582:	ba 00 00 00 00       	mov    $0x0,%edx
	if (cons.rpos != cons.wpos) {
f0100587:	3b 83 7c 1f 00 00    	cmp    0x1f7c(%ebx),%eax
f010058d:	74 1f                	je     f01005ae <cons_getc+0x52>
		c = cons.buf[cons.rpos++];
f010058f:	8d 48 01             	lea    0x1(%eax),%ecx
f0100592:	0f b6 94 03 78 1d 00 	movzbl 0x1d78(%ebx,%eax,1),%edx
f0100599:	00 
			cons.rpos = 0;
f010059a:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01005a0:	b8 00 00 00 00       	mov    $0x0,%eax
f01005a5:	0f 44 c8             	cmove  %eax,%ecx
f01005a8:	89 8b 78 1f 00 00    	mov    %ecx,0x1f78(%ebx)
}
f01005ae:	89 d0                	mov    %edx,%eax
f01005b0:	83 c4 04             	add    $0x4,%esp
f01005b3:	5b                   	pop    %ebx
f01005b4:	5d                   	pop    %ebp
f01005b5:	c3                   	ret    

f01005b6 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005b6:	f3 0f 1e fb          	endbr32 
f01005ba:	55                   	push   %ebp
f01005bb:	89 e5                	mov    %esp,%ebp
f01005bd:	57                   	push   %edi
f01005be:	56                   	push   %esi
f01005bf:	53                   	push   %ebx
f01005c0:	83 ec 1c             	sub    $0x1c,%esp
f01005c3:	e8 93 fb ff ff       	call   f010015b <__x86.get_pc_thunk.bx>
f01005c8:	81 c3 40 7d 01 00    	add    $0x17d40,%ebx
	was = *cp;
f01005ce:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01005d5:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005dc:	5a a5 
	if (*cp != 0xA55A) {
f01005de:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005e5:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005e9:	0f 84 bc 00 00 00    	je     f01006ab <cons_init+0xf5>
		addr_6845 = MONO_BASE;
f01005ef:	c7 83 88 1f 00 00 b4 	movl   $0x3b4,0x1f88(%ebx)
f01005f6:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005f9:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f0100600:	8b bb 88 1f 00 00    	mov    0x1f88(%ebx),%edi
f0100606:	b8 0e 00 00 00       	mov    $0xe,%eax
f010060b:	89 fa                	mov    %edi,%edx
f010060d:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010060e:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100611:	89 ca                	mov    %ecx,%edx
f0100613:	ec                   	in     (%dx),%al
f0100614:	0f b6 f0             	movzbl %al,%esi
f0100617:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010061a:	b8 0f 00 00 00       	mov    $0xf,%eax
f010061f:	89 fa                	mov    %edi,%edx
f0100621:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100622:	89 ca                	mov    %ecx,%edx
f0100624:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100625:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100628:	89 bb 84 1f 00 00    	mov    %edi,0x1f84(%ebx)
	pos |= inb(addr_6845 + 1);
f010062e:	0f b6 c0             	movzbl %al,%eax
f0100631:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f0100633:	66 89 b3 80 1f 00 00 	mov    %si,0x1f80(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010063a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010063f:	89 c8                	mov    %ecx,%eax
f0100641:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100646:	ee                   	out    %al,(%dx)
f0100647:	bf fb 03 00 00       	mov    $0x3fb,%edi
f010064c:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100651:	89 fa                	mov    %edi,%edx
f0100653:	ee                   	out    %al,(%dx)
f0100654:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100659:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010065e:	ee                   	out    %al,(%dx)
f010065f:	be f9 03 00 00       	mov    $0x3f9,%esi
f0100664:	89 c8                	mov    %ecx,%eax
f0100666:	89 f2                	mov    %esi,%edx
f0100668:	ee                   	out    %al,(%dx)
f0100669:	b8 03 00 00 00       	mov    $0x3,%eax
f010066e:	89 fa                	mov    %edi,%edx
f0100670:	ee                   	out    %al,(%dx)
f0100671:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100676:	89 c8                	mov    %ecx,%eax
f0100678:	ee                   	out    %al,(%dx)
f0100679:	b8 01 00 00 00       	mov    $0x1,%eax
f010067e:	89 f2                	mov    %esi,%edx
f0100680:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100681:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100686:	ec                   	in     (%dx),%al
f0100687:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100689:	3c ff                	cmp    $0xff,%al
f010068b:	0f 95 83 8c 1f 00 00 	setne  0x1f8c(%ebx)
f0100692:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100697:	ec                   	in     (%dx),%al
f0100698:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010069d:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010069e:	80 f9 ff             	cmp    $0xff,%cl
f01006a1:	74 25                	je     f01006c8 <cons_init+0x112>
		cprintf("Serial port does not exist!\n");
}
f01006a3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006a6:	5b                   	pop    %ebx
f01006a7:	5e                   	pop    %esi
f01006a8:	5f                   	pop    %edi
f01006a9:	5d                   	pop    %ebp
f01006aa:	c3                   	ret    
		*cp = was;
f01006ab:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006b2:	c7 83 88 1f 00 00 d4 	movl   $0x3d4,0x1f88(%ebx)
f01006b9:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006bc:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006c3:	e9 38 ff ff ff       	jmp    f0100600 <cons_init+0x4a>
		cprintf("Serial port does not exist!\n");
f01006c8:	83 ec 0c             	sub    $0xc,%esp
f01006cb:	8d 83 71 bd fe ff    	lea    -0x1428f(%ebx),%eax
f01006d1:	50                   	push   %eax
f01006d2:	e8 d5 28 00 00       	call   f0102fac <cprintf>
f01006d7:	83 c4 10             	add    $0x10,%esp
}
f01006da:	eb c7                	jmp    f01006a3 <cons_init+0xed>

f01006dc <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006dc:	f3 0f 1e fb          	endbr32 
f01006e0:	55                   	push   %ebp
f01006e1:	89 e5                	mov    %esp,%ebp
f01006e3:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01006e9:	e8 1f fc ff ff       	call   f010030d <cons_putc>
}
f01006ee:	c9                   	leave  
f01006ef:	c3                   	ret    

f01006f0 <getchar>:

int
getchar(void)
{
f01006f0:	f3 0f 1e fb          	endbr32 
f01006f4:	55                   	push   %ebp
f01006f5:	89 e5                	mov    %esp,%ebp
f01006f7:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006fa:	e8 5d fe ff ff       	call   f010055c <cons_getc>
f01006ff:	85 c0                	test   %eax,%eax
f0100701:	74 f7                	je     f01006fa <getchar+0xa>
		/* do nothing */;
	return c;
}
f0100703:	c9                   	leave  
f0100704:	c3                   	ret    

f0100705 <iscons>:

int
iscons(int fdnum)
{
f0100705:	f3 0f 1e fb          	endbr32 
	// used by readline
	return 1;
}
f0100709:	b8 01 00 00 00       	mov    $0x1,%eax
f010070e:	c3                   	ret    

f010070f <__x86.get_pc_thunk.ax>:
f010070f:	8b 04 24             	mov    (%esp),%eax
f0100712:	c3                   	ret    

f0100713 <__x86.get_pc_thunk.si>:
f0100713:	8b 34 24             	mov    (%esp),%esi
f0100716:	c3                   	ret    

f0100717 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100717:	f3 0f 1e fb          	endbr32 
f010071b:	55                   	push   %ebp
f010071c:	89 e5                	mov    %esp,%ebp
f010071e:	56                   	push   %esi
f010071f:	53                   	push   %ebx
f0100720:	e8 36 fa ff ff       	call   f010015b <__x86.get_pc_thunk.bx>
f0100725:	81 c3 e3 7b 01 00    	add    $0x17be3,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010072b:	83 ec 04             	sub    $0x4,%esp
f010072e:	8d 83 98 bf fe ff    	lea    -0x14068(%ebx),%eax
f0100734:	50                   	push   %eax
f0100735:	8d 83 b6 bf fe ff    	lea    -0x1404a(%ebx),%eax
f010073b:	50                   	push   %eax
f010073c:	8d b3 bb bf fe ff    	lea    -0x14045(%ebx),%esi
f0100742:	56                   	push   %esi
f0100743:	e8 64 28 00 00       	call   f0102fac <cprintf>
f0100748:	83 c4 0c             	add    $0xc,%esp
f010074b:	8d 83 74 c0 fe ff    	lea    -0x13f8c(%ebx),%eax
f0100751:	50                   	push   %eax
f0100752:	8d 83 c4 bf fe ff    	lea    -0x1403c(%ebx),%eax
f0100758:	50                   	push   %eax
f0100759:	56                   	push   %esi
f010075a:	e8 4d 28 00 00       	call   f0102fac <cprintf>
f010075f:	83 c4 0c             	add    $0xc,%esp
f0100762:	8d 83 cd bf fe ff    	lea    -0x14033(%ebx),%eax
f0100768:	50                   	push   %eax
f0100769:	8d 83 e3 bf fe ff    	lea    -0x1401d(%ebx),%eax
f010076f:	50                   	push   %eax
f0100770:	56                   	push   %esi
f0100771:	e8 36 28 00 00       	call   f0102fac <cprintf>
	return 0;
}
f0100776:	b8 00 00 00 00       	mov    $0x0,%eax
f010077b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010077e:	5b                   	pop    %ebx
f010077f:	5e                   	pop    %esi
f0100780:	5d                   	pop    %ebp
f0100781:	c3                   	ret    

f0100782 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100782:	f3 0f 1e fb          	endbr32 
f0100786:	55                   	push   %ebp
f0100787:	89 e5                	mov    %esp,%ebp
f0100789:	57                   	push   %edi
f010078a:	56                   	push   %esi
f010078b:	53                   	push   %ebx
f010078c:	83 ec 18             	sub    $0x18,%esp
f010078f:	e8 c7 f9 ff ff       	call   f010015b <__x86.get_pc_thunk.bx>
f0100794:	81 c3 74 7b 01 00    	add    $0x17b74,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010079a:	8d 83 ed bf fe ff    	lea    -0x14013(%ebx),%eax
f01007a0:	50                   	push   %eax
f01007a1:	e8 06 28 00 00       	call   f0102fac <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007a6:	83 c4 08             	add    $0x8,%esp
f01007a9:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f01007af:	8d 83 9c c0 fe ff    	lea    -0x13f64(%ebx),%eax
f01007b5:	50                   	push   %eax
f01007b6:	e8 f1 27 00 00       	call   f0102fac <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007bb:	83 c4 0c             	add    $0xc,%esp
f01007be:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f01007c4:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007ca:	50                   	push   %eax
f01007cb:	57                   	push   %edi
f01007cc:	8d 83 c4 c0 fe ff    	lea    -0x13f3c(%ebx),%eax
f01007d2:	50                   	push   %eax
f01007d3:	e8 d4 27 00 00       	call   f0102fac <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007d8:	83 c4 0c             	add    $0xc,%esp
f01007db:	c7 c0 1d 40 10 f0    	mov    $0xf010401d,%eax
f01007e1:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007e7:	52                   	push   %edx
f01007e8:	50                   	push   %eax
f01007e9:	8d 83 e8 c0 fe ff    	lea    -0x13f18(%ebx),%eax
f01007ef:	50                   	push   %eax
f01007f0:	e8 b7 27 00 00       	call   f0102fac <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007f5:	83 c4 0c             	add    $0xc,%esp
f01007f8:	c7 c0 60 a0 11 f0    	mov    $0xf011a060,%eax
f01007fe:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100804:	52                   	push   %edx
f0100805:	50                   	push   %eax
f0100806:	8d 83 0c c1 fe ff    	lea    -0x13ef4(%ebx),%eax
f010080c:	50                   	push   %eax
f010080d:	e8 9a 27 00 00       	call   f0102fac <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100812:	83 c4 0c             	add    $0xc,%esp
f0100815:	c7 c6 c0 a6 11 f0    	mov    $0xf011a6c0,%esi
f010081b:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0100821:	50                   	push   %eax
f0100822:	56                   	push   %esi
f0100823:	8d 83 30 c1 fe ff    	lea    -0x13ed0(%ebx),%eax
f0100829:	50                   	push   %eax
f010082a:	e8 7d 27 00 00       	call   f0102fac <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010082f:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100832:	29 fe                	sub    %edi,%esi
f0100834:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f010083a:	c1 fe 0a             	sar    $0xa,%esi
f010083d:	56                   	push   %esi
f010083e:	8d 83 54 c1 fe ff    	lea    -0x13eac(%ebx),%eax
f0100844:	50                   	push   %eax
f0100845:	e8 62 27 00 00       	call   f0102fac <cprintf>
	return 0;
}
f010084a:	b8 00 00 00 00       	mov    $0x0,%eax
f010084f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100852:	5b                   	pop    %ebx
f0100853:	5e                   	pop    %esi
f0100854:	5f                   	pop    %edi
f0100855:	5d                   	pop    %ebp
f0100856:	c3                   	ret    

f0100857 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100857:	f3 0f 1e fb          	endbr32 
f010085b:	55                   	push   %ebp
f010085c:	89 e5                	mov    %esp,%ebp
f010085e:	57                   	push   %edi
f010085f:	56                   	push   %esi
f0100860:	53                   	push   %ebx
f0100861:	83 ec 3c             	sub    $0x3c,%esp
f0100864:	e8 f2 f8 ff ff       	call   f010015b <__x86.get_pc_thunk.bx>
f0100869:	81 c3 9f 7a 01 00    	add    $0x17a9f,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010086f:	89 ea                	mov    %ebp,%edx
f0100871:	89 d0                	mov    %edx,%eax
    typedef int (*this_func_type)(int, char **, struct Trapframe *);
	// Your code here.
	uint32_t ebp = read_ebp();
	int *ebp_base_ptr = (int *)ebp;           
f0100873:	89 55 bc             	mov    %edx,-0x44(%ebp)
	uint32_t eip = ebp_base_ptr[1];   
f0100876:	8b 52 04             	mov    0x4(%edx),%edx
f0100879:	89 55 c0             	mov    %edx,-0x40(%ebp)
	while (1) {
        cprintf("ebp %x, eip %x, args ", ebp, eip);
f010087c:	8d 93 06 c0 fe ff    	lea    -0x13ffa(%ebx),%edx
f0100882:	89 55 b8             	mov    %edx,-0x48(%ebp)

        int *args = ebp_base_ptr + 2;

        for (int i = 0; i < 5; ++i) {
            cprintf("%x ", args[i]);
f0100885:	8d 93 1c c0 fe ff    	lea    -0x13fe4(%ebx),%edx
f010088b:	89 55 c4             	mov    %edx,-0x3c(%ebp)
        cprintf("ebp %x, eip %x, args ", ebp, eip);
f010088e:	83 ec 04             	sub    $0x4,%esp
f0100891:	ff 75 c0             	pushl  -0x40(%ebp)
f0100894:	50                   	push   %eax
f0100895:	ff 75 b8             	pushl  -0x48(%ebp)
f0100898:	e8 0f 27 00 00       	call   f0102fac <cprintf>
f010089d:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01008a0:	8d 70 08             	lea    0x8(%eax),%esi
f01008a3:	8d 78 1c             	lea    0x1c(%eax),%edi
f01008a6:	83 c4 10             	add    $0x10,%esp
            cprintf("%x ", args[i]);
f01008a9:	83 ec 08             	sub    $0x8,%esp
f01008ac:	ff 36                	pushl  (%esi)
f01008ae:	ff 75 c4             	pushl  -0x3c(%ebp)
f01008b1:	e8 f6 26 00 00       	call   f0102fac <cprintf>
f01008b6:	83 c6 04             	add    $0x4,%esi
        for (int i = 0; i < 5; ++i) {
f01008b9:	83 c4 10             	add    $0x10,%esp
f01008bc:	39 fe                	cmp    %edi,%esi
f01008be:	75 e9                	jne    f01008a9 <mon_backtrace+0x52>
        }
        cprintf("\n");
f01008c0:	83 ec 0c             	sub    $0xc,%esp
f01008c3:	8d 83 66 cc fe ff    	lea    -0x1339a(%ebx),%eax
f01008c9:	50                   	push   %eax
f01008ca:	e8 dd 26 00 00       	call   f0102fac <cprintf>
        struct Eipdebuginfo info;
        int ret = debuginfo_eip(eip, &info);
f01008cf:	83 c4 08             	add    $0x8,%esp
f01008d2:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01008d5:	50                   	push   %eax
f01008d6:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01008d9:	57                   	push   %edi
f01008da:	e8 da 27 00 00       	call   f01030b9 <debuginfo_eip>
f01008df:	89 c6                	mov    %eax,%esi
        cprintf("    at %s: %d: %.*s+%d\n",
f01008e1:	83 c4 08             	add    $0x8,%esp
f01008e4:	89 f8                	mov    %edi,%eax
f01008e6:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008e9:	50                   	push   %eax
f01008ea:	ff 75 d8             	pushl  -0x28(%ebp)
f01008ed:	ff 75 dc             	pushl  -0x24(%ebp)
f01008f0:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008f3:	ff 75 d0             	pushl  -0x30(%ebp)
f01008f6:	8d 83 20 c0 fe ff    	lea    -0x13fe0(%ebx),%eax
f01008fc:	50                   	push   %eax
f01008fd:	e8 aa 26 00 00       	call   f0102fac <cprintf>
                info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
        if (ret) {
f0100902:	83 c4 20             	add    $0x20,%esp
f0100905:	85 f6                	test   %esi,%esi
f0100907:	75 13                	jne    f010091c <mon_backtrace+0xc5>
            break;
        }
        ebp = *ebp_base_ptr;
f0100909:	8b 45 bc             	mov    -0x44(%ebp),%eax
f010090c:	8b 00                	mov    (%eax),%eax
        ebp_base_ptr = (int*)ebp;
f010090e:	89 45 bc             	mov    %eax,-0x44(%ebp)
        eip = ebp_base_ptr[1];
f0100911:	8b 48 04             	mov    0x4(%eax),%ecx
f0100914:	89 4d c0             	mov    %ecx,-0x40(%ebp)
	while (1) {
f0100917:	e9 72 ff ff ff       	jmp    f010088e <mon_backtrace+0x37>
	}

	return 0;
}
f010091c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100921:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100924:	5b                   	pop    %ebx
f0100925:	5e                   	pop    %esi
f0100926:	5f                   	pop    %edi
f0100927:	5d                   	pop    %ebp
f0100928:	c3                   	ret    

f0100929 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100929:	f3 0f 1e fb          	endbr32 
f010092d:	55                   	push   %ebp
f010092e:	89 e5                	mov    %esp,%ebp
f0100930:	57                   	push   %edi
f0100931:	56                   	push   %esi
f0100932:	53                   	push   %ebx
f0100933:	83 ec 68             	sub    $0x68,%esp
f0100936:	e8 20 f8 ff ff       	call   f010015b <__x86.get_pc_thunk.bx>
f010093b:	81 c3 cd 79 01 00    	add    $0x179cd,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100941:	8d 83 80 c1 fe ff    	lea    -0x13e80(%ebx),%eax
f0100947:	50                   	push   %eax
f0100948:	e8 5f 26 00 00       	call   f0102fac <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010094d:	8d 83 a4 c1 fe ff    	lea    -0x13e5c(%ebx),%eax
f0100953:	89 04 24             	mov    %eax,(%esp)
f0100956:	e8 51 26 00 00       	call   f0102fac <cprintf>
f010095b:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f010095e:	8d 83 3c c0 fe ff    	lea    -0x13fc4(%ebx),%eax
f0100964:	89 45 a0             	mov    %eax,-0x60(%ebp)
f0100967:	e9 d1 00 00 00       	jmp    f0100a3d <monitor+0x114>
f010096c:	83 ec 08             	sub    $0x8,%esp
f010096f:	0f be c0             	movsbl %al,%eax
f0100972:	50                   	push   %eax
f0100973:	ff 75 a0             	pushl  -0x60(%ebp)
f0100976:	e8 f1 31 00 00       	call   f0103b6c <strchr>
f010097b:	83 c4 10             	add    $0x10,%esp
f010097e:	85 c0                	test   %eax,%eax
f0100980:	74 6d                	je     f01009ef <monitor+0xc6>
			*buf++ = 0;
f0100982:	c6 06 00             	movb   $0x0,(%esi)
f0100985:	89 7d a4             	mov    %edi,-0x5c(%ebp)
f0100988:	8d 76 01             	lea    0x1(%esi),%esi
f010098b:	8b 7d a4             	mov    -0x5c(%ebp),%edi
		while (*buf && strchr(WHITESPACE, *buf))
f010098e:	0f b6 06             	movzbl (%esi),%eax
f0100991:	84 c0                	test   %al,%al
f0100993:	75 d7                	jne    f010096c <monitor+0x43>
	argv[argc] = 0;
f0100995:	c7 44 bd a8 00 00 00 	movl   $0x0,-0x58(%ebp,%edi,4)
f010099c:	00 
	if (argc == 0)
f010099d:	85 ff                	test   %edi,%edi
f010099f:	0f 84 98 00 00 00    	je     f0100a3d <monitor+0x114>
f01009a5:	8d b3 18 1d 00 00    	lea    0x1d18(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009ab:	b8 00 00 00 00       	mov    $0x0,%eax
f01009b0:	89 7d a4             	mov    %edi,-0x5c(%ebp)
f01009b3:	89 c7                	mov    %eax,%edi
		if (strcmp(argv[0], commands[i].name) == 0)
f01009b5:	83 ec 08             	sub    $0x8,%esp
f01009b8:	ff 36                	pushl  (%esi)
f01009ba:	ff 75 a8             	pushl  -0x58(%ebp)
f01009bd:	e8 44 31 00 00       	call   f0103b06 <strcmp>
f01009c2:	83 c4 10             	add    $0x10,%esp
f01009c5:	85 c0                	test   %eax,%eax
f01009c7:	0f 84 99 00 00 00    	je     f0100a66 <monitor+0x13d>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009cd:	83 c7 01             	add    $0x1,%edi
f01009d0:	83 c6 0c             	add    $0xc,%esi
f01009d3:	83 ff 03             	cmp    $0x3,%edi
f01009d6:	75 dd                	jne    f01009b5 <monitor+0x8c>
	cprintf("Unknown command '%s'\n", argv[0]);
f01009d8:	83 ec 08             	sub    $0x8,%esp
f01009db:	ff 75 a8             	pushl  -0x58(%ebp)
f01009de:	8d 83 5e c0 fe ff    	lea    -0x13fa2(%ebx),%eax
f01009e4:	50                   	push   %eax
f01009e5:	e8 c2 25 00 00       	call   f0102fac <cprintf>
	return 0;
f01009ea:	83 c4 10             	add    $0x10,%esp
f01009ed:	eb 4e                	jmp    f0100a3d <monitor+0x114>
		if (*buf == 0)
f01009ef:	80 3e 00             	cmpb   $0x0,(%esi)
f01009f2:	74 a1                	je     f0100995 <monitor+0x6c>
		if (argc == MAXARGS-1) {
f01009f4:	83 ff 0f             	cmp    $0xf,%edi
f01009f7:	74 30                	je     f0100a29 <monitor+0x100>
		argv[argc++] = buf;
f01009f9:	8d 47 01             	lea    0x1(%edi),%eax
f01009fc:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01009ff:	89 74 bd a8          	mov    %esi,-0x58(%ebp,%edi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a03:	0f b6 06             	movzbl (%esi),%eax
f0100a06:	84 c0                	test   %al,%al
f0100a08:	74 81                	je     f010098b <monitor+0x62>
f0100a0a:	83 ec 08             	sub    $0x8,%esp
f0100a0d:	0f be c0             	movsbl %al,%eax
f0100a10:	50                   	push   %eax
f0100a11:	ff 75 a0             	pushl  -0x60(%ebp)
f0100a14:	e8 53 31 00 00       	call   f0103b6c <strchr>
f0100a19:	83 c4 10             	add    $0x10,%esp
f0100a1c:	85 c0                	test   %eax,%eax
f0100a1e:	0f 85 67 ff ff ff    	jne    f010098b <monitor+0x62>
			buf++;
f0100a24:	83 c6 01             	add    $0x1,%esi
f0100a27:	eb da                	jmp    f0100a03 <monitor+0xda>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a29:	83 ec 08             	sub    $0x8,%esp
f0100a2c:	6a 10                	push   $0x10
f0100a2e:	8d 83 41 c0 fe ff    	lea    -0x13fbf(%ebx),%eax
f0100a34:	50                   	push   %eax
f0100a35:	e8 72 25 00 00       	call   f0102fac <cprintf>
			return 0;
f0100a3a:	83 c4 10             	add    $0x10,%esp
	cprintf("x %d, y %x, z %d\n", x, y, z);
	unsigned int i = 0x00646c72;
	cprintf("H%x Wo%s", 57616, &i);*/

	while (1) {
		buf = readline("K> ");
f0100a3d:	8d bb 38 c0 fe ff    	lea    -0x13fc8(%ebx),%edi
f0100a43:	83 ec 0c             	sub    $0xc,%esp
f0100a46:	57                   	push   %edi
f0100a47:	e8 af 2e 00 00       	call   f01038fb <readline>
		if (buf != NULL)
f0100a4c:	83 c4 10             	add    $0x10,%esp
f0100a4f:	85 c0                	test   %eax,%eax
f0100a51:	74 f0                	je     f0100a43 <monitor+0x11a>
f0100a53:	89 c6                	mov    %eax,%esi
	argv[argc] = 0;
f0100a55:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100a5c:	bf 00 00 00 00       	mov    $0x0,%edi
f0100a61:	e9 28 ff ff ff       	jmp    f010098e <monitor+0x65>
f0100a66:	89 f8                	mov    %edi,%eax
f0100a68:	8b 7d a4             	mov    -0x5c(%ebp),%edi
			return commands[i].func(argc, argv, tf);
f0100a6b:	83 ec 04             	sub    $0x4,%esp
f0100a6e:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100a71:	ff 75 08             	pushl  0x8(%ebp)
f0100a74:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a77:	52                   	push   %edx
f0100a78:	57                   	push   %edi
f0100a79:	ff 94 83 20 1d 00 00 	call   *0x1d20(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100a80:	83 c4 10             	add    $0x10,%esp
f0100a83:	85 c0                	test   %eax,%eax
f0100a85:	79 b6                	jns    f0100a3d <monitor+0x114>
				break;
	}
}
f0100a87:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a8a:	5b                   	pop    %ebx
f0100a8b:	5e                   	pop    %esi
f0100a8c:	5f                   	pop    %edi
f0100a8d:	5d                   	pop    %ebp
f0100a8e:	c3                   	ret    

f0100a8f <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a8f:	55                   	push   %ebp
f0100a90:	89 e5                	mov    %esp,%ebp
f0100a92:	57                   	push   %edi
f0100a93:	56                   	push   %esi
f0100a94:	53                   	push   %ebx
f0100a95:	83 ec 18             	sub    $0x18,%esp
f0100a98:	e8 be f6 ff ff       	call   f010015b <__x86.get_pc_thunk.bx>
f0100a9d:	81 c3 6b 78 01 00    	add    $0x1786b,%ebx
f0100aa3:	89 c6                	mov    %eax,%esi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100aa5:	50                   	push   %eax
f0100aa6:	e8 6a 24 00 00       	call   f0102f15 <mc146818_read>
f0100aab:	89 c7                	mov    %eax,%edi
f0100aad:	83 c6 01             	add    $0x1,%esi
f0100ab0:	89 34 24             	mov    %esi,(%esp)
f0100ab3:	e8 5d 24 00 00       	call   f0102f15 <mc146818_read>
f0100ab8:	c1 e0 08             	shl    $0x8,%eax
f0100abb:	09 f8                	or     %edi,%eax
}
f0100abd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ac0:	5b                   	pop    %ebx
f0100ac1:	5e                   	pop    %esi
f0100ac2:	5f                   	pop    %edi
f0100ac3:	5d                   	pop    %ebp
f0100ac4:	c3                   	ret    

f0100ac5 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100ac5:	e8 3f 24 00 00       	call   f0102f09 <__x86.get_pc_thunk.dx>
f0100aca:	81 c2 3e 78 01 00    	add    $0x1783e,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100ad0:	83 ba 90 1f 00 00 00 	cmpl   $0x0,0x1f90(%edx)
f0100ad7:	74 3e                	je     f0100b17 <boot_alloc+0x52>
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.

	// special case
	if(n == 0)
f0100ad9:	85 c0                	test   %eax,%eax
f0100adb:	74 54                	je     f0100b31 <boot_alloc+0x6c>
{
f0100add:	55                   	push   %ebp
f0100ade:	89 e5                	mov    %esp,%ebp
f0100ae0:	53                   	push   %ebx
f0100ae1:	83 ec 04             	sub    $0x4,%esp
	{
		return nextfree;
	}

	// allocate memory 
	result = nextfree;
f0100ae4:	8b 8a 90 1f 00 00    	mov    0x1f90(%edx),%ecx
	nextfree = ROUNDUP(n,PGSIZE)+nextfree;
f0100aea:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100aef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100af4:	01 c8                	add    %ecx,%eax
f0100af6:	89 82 90 1f 00 00    	mov    %eax,0x1f90(%edx)

	// out of memory panic
	if((uint32_t)nextfree-KERNBASE>(npages*PGSIZE))
f0100afc:	05 00 00 00 10       	add    $0x10000000,%eax
f0100b01:	c7 c3 c8 a6 11 f0    	mov    $0xf011a6c8,%ebx
f0100b07:	8b 1b                	mov    (%ebx),%ebx
f0100b09:	c1 e3 0c             	shl    $0xc,%ebx
f0100b0c:	39 d8                	cmp    %ebx,%eax
f0100b0e:	77 2a                	ja     f0100b3a <boot_alloc+0x75>
		// reset the nextfree
		nextfree = result;
		return NULL;
	}
	return result;
}
f0100b10:	89 c8                	mov    %ecx,%eax
f0100b12:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b15:	c9                   	leave  
f0100b16:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b17:	c7 c1 c0 a6 11 f0    	mov    $0xf011a6c0,%ecx
f0100b1d:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100b23:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100b29:	89 8a 90 1f 00 00    	mov    %ecx,0x1f90(%edx)
f0100b2f:	eb a8                	jmp    f0100ad9 <boot_alloc+0x14>
		return nextfree;
f0100b31:	8b 8a 90 1f 00 00    	mov    0x1f90(%edx),%ecx
}
f0100b37:	89 c8                	mov    %ecx,%eax
f0100b39:	c3                   	ret    
		panic("at pmap.c:boot_alloc():114 out of memory");
f0100b3a:	83 ec 04             	sub    $0x4,%esp
f0100b3d:	8d 82 cc c1 fe ff    	lea    -0x13e34(%edx),%eax
f0100b43:	50                   	push   %eax
f0100b44:	6a 77                	push   $0x77
f0100b46:	8d 82 b5 c9 fe ff    	lea    -0x1364b(%edx),%eax
f0100b4c:	50                   	push   %eax
f0100b4d:	89 d3                	mov    %edx,%ebx
f0100b4f:	e8 49 f5 ff ff       	call   f010009d <_panic>

f0100b54 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b54:	55                   	push   %ebp
f0100b55:	89 e5                	mov    %esp,%ebp
f0100b57:	56                   	push   %esi
f0100b58:	53                   	push   %ebx
f0100b59:	e8 af 23 00 00       	call   f0102f0d <__x86.get_pc_thunk.cx>
f0100b5e:	81 c1 aa 77 01 00    	add    $0x177aa,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b64:	89 d3                	mov    %edx,%ebx
f0100b66:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100b69:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100b6c:	a8 01                	test   $0x1,%al
f0100b6e:	74 59                	je     f0100bc9 <check_va2pa+0x75>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b70:	89 c3                	mov    %eax,%ebx
f0100b72:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b78:	c1 e8 0c             	shr    $0xc,%eax
f0100b7b:	c7 c6 c8 a6 11 f0    	mov    $0xf011a6c8,%esi
f0100b81:	3b 06                	cmp    (%esi),%eax
f0100b83:	73 29                	jae    f0100bae <check_va2pa+0x5a>
	if (!(p[PTX(va)] & PTE_P))
f0100b85:	c1 ea 0c             	shr    $0xc,%edx
f0100b88:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b8e:	8b 94 93 00 00 00 f0 	mov    -0x10000000(%ebx,%edx,4),%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b95:	89 d0                	mov    %edx,%eax
f0100b97:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b9c:	f6 c2 01             	test   $0x1,%dl
f0100b9f:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100ba4:	0f 44 c2             	cmove  %edx,%eax
}
f0100ba7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100baa:	5b                   	pop    %ebx
f0100bab:	5e                   	pop    %esi
f0100bac:	5d                   	pop    %ebp
f0100bad:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bae:	53                   	push   %ebx
f0100baf:	8d 81 f8 c1 fe ff    	lea    -0x13e08(%ecx),%eax
f0100bb5:	50                   	push   %eax
f0100bb6:	68 2d 03 00 00       	push   $0x32d
f0100bbb:	8d 81 b5 c9 fe ff    	lea    -0x1364b(%ecx),%eax
f0100bc1:	50                   	push   %eax
f0100bc2:	89 cb                	mov    %ecx,%ebx
f0100bc4:	e8 d4 f4 ff ff       	call   f010009d <_panic>
		return ~0;
f0100bc9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bce:	eb d7                	jmp    f0100ba7 <check_va2pa+0x53>

f0100bd0 <check_page_free_list>:
{
f0100bd0:	55                   	push   %ebp
f0100bd1:	89 e5                	mov    %esp,%ebp
f0100bd3:	57                   	push   %edi
f0100bd4:	56                   	push   %esi
f0100bd5:	53                   	push   %ebx
f0100bd6:	83 ec 2c             	sub    $0x2c,%esp
f0100bd9:	e8 35 fb ff ff       	call   f0100713 <__x86.get_pc_thunk.si>
f0100bde:	81 c6 2a 77 01 00    	add    $0x1772a,%esi
f0100be4:	89 75 c8             	mov    %esi,-0x38(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100be7:	84 c0                	test   %al,%al
f0100be9:	0f 85 ec 02 00 00    	jne    f0100edb <check_page_free_list+0x30b>
	if (!page_free_list)
f0100bef:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100bf2:	83 b8 94 1f 00 00 00 	cmpl   $0x0,0x1f94(%eax)
f0100bf9:	74 21                	je     f0100c1c <check_page_free_list+0x4c>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bfb:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c02:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100c05:	8b b0 94 1f 00 00    	mov    0x1f94(%eax),%esi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c0b:	c7 c7 d0 a6 11 f0    	mov    $0xf011a6d0,%edi
	if (PGNUM(pa) >= npages)
f0100c11:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f0100c17:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100c1a:	eb 39                	jmp    f0100c55 <check_page_free_list+0x85>
		panic("'page_free_list' is a null pointer!");
f0100c1c:	83 ec 04             	sub    $0x4,%esp
f0100c1f:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100c22:	8d 83 1c c2 fe ff    	lea    -0x13de4(%ebx),%eax
f0100c28:	50                   	push   %eax
f0100c29:	68 6e 02 00 00       	push   $0x26e
f0100c2e:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0100c34:	50                   	push   %eax
f0100c35:	e8 63 f4 ff ff       	call   f010009d <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c3a:	50                   	push   %eax
f0100c3b:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100c3e:	8d 83 f8 c1 fe ff    	lea    -0x13e08(%ebx),%eax
f0100c44:	50                   	push   %eax
f0100c45:	6a 52                	push   $0x52
f0100c47:	8d 83 c1 c9 fe ff    	lea    -0x1363f(%ebx),%eax
f0100c4d:	50                   	push   %eax
f0100c4e:	e8 4a f4 ff ff       	call   f010009d <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c53:	8b 36                	mov    (%esi),%esi
f0100c55:	85 f6                	test   %esi,%esi
f0100c57:	74 40                	je     f0100c99 <check_page_free_list+0xc9>
	return (pp - pages) << PGSHIFT;
f0100c59:	89 f0                	mov    %esi,%eax
f0100c5b:	2b 07                	sub    (%edi),%eax
f0100c5d:	c1 f8 03             	sar    $0x3,%eax
f0100c60:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c63:	89 c2                	mov    %eax,%edx
f0100c65:	c1 ea 16             	shr    $0x16,%edx
f0100c68:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c6b:	73 e6                	jae    f0100c53 <check_page_free_list+0x83>
	if (PGNUM(pa) >= npages)
f0100c6d:	89 c2                	mov    %eax,%edx
f0100c6f:	c1 ea 0c             	shr    $0xc,%edx
f0100c72:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100c75:	3b 11                	cmp    (%ecx),%edx
f0100c77:	73 c1                	jae    f0100c3a <check_page_free_list+0x6a>
			memset(page2kva(pp), 0x97, 128);
f0100c79:	83 ec 04             	sub    $0x4,%esp
f0100c7c:	68 80 00 00 00       	push   $0x80
f0100c81:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100c86:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c8b:	50                   	push   %eax
f0100c8c:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100c8f:	e8 1d 2f 00 00       	call   f0103bb1 <memset>
f0100c94:	83 c4 10             	add    $0x10,%esp
f0100c97:	eb ba                	jmp    f0100c53 <check_page_free_list+0x83>
	first_free_page = (char *) boot_alloc(0);
f0100c99:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c9e:	e8 22 fe ff ff       	call   f0100ac5 <boot_alloc>
f0100ca3:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ca6:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0100ca9:	8b 97 94 1f 00 00    	mov    0x1f94(%edi),%edx
		assert(pp >= pages);
f0100caf:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0100cb5:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100cb7:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f0100cbd:	8b 00                	mov    (%eax),%eax
f0100cbf:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100cc2:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
	int nfree_basemem = 0, nfree_extmem = 0;
f0100cc5:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cca:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ccd:	e9 08 01 00 00       	jmp    f0100dda <check_page_free_list+0x20a>
		assert(pp >= pages);
f0100cd2:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100cd5:	8d 83 cf c9 fe ff    	lea    -0x13631(%ebx),%eax
f0100cdb:	50                   	push   %eax
f0100cdc:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0100ce2:	50                   	push   %eax
f0100ce3:	68 88 02 00 00       	push   $0x288
f0100ce8:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0100cee:	50                   	push   %eax
f0100cef:	e8 a9 f3 ff ff       	call   f010009d <_panic>
		assert(pp < pages + npages);
f0100cf4:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100cf7:	8d 83 f0 c9 fe ff    	lea    -0x13610(%ebx),%eax
f0100cfd:	50                   	push   %eax
f0100cfe:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0100d04:	50                   	push   %eax
f0100d05:	68 89 02 00 00       	push   $0x289
f0100d0a:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0100d10:	50                   	push   %eax
f0100d11:	e8 87 f3 ff ff       	call   f010009d <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d16:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100d19:	8d 83 40 c2 fe ff    	lea    -0x13dc0(%ebx),%eax
f0100d1f:	50                   	push   %eax
f0100d20:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0100d26:	50                   	push   %eax
f0100d27:	68 8a 02 00 00       	push   $0x28a
f0100d2c:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0100d32:	50                   	push   %eax
f0100d33:	e8 65 f3 ff ff       	call   f010009d <_panic>
		assert(page2pa(pp) != 0);
f0100d38:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100d3b:	8d 83 04 ca fe ff    	lea    -0x135fc(%ebx),%eax
f0100d41:	50                   	push   %eax
f0100d42:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0100d48:	50                   	push   %eax
f0100d49:	68 8d 02 00 00       	push   $0x28d
f0100d4e:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0100d54:	50                   	push   %eax
f0100d55:	e8 43 f3 ff ff       	call   f010009d <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d5a:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100d5d:	8d 83 15 ca fe ff    	lea    -0x135eb(%ebx),%eax
f0100d63:	50                   	push   %eax
f0100d64:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0100d6a:	50                   	push   %eax
f0100d6b:	68 8e 02 00 00       	push   $0x28e
f0100d70:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0100d76:	50                   	push   %eax
f0100d77:	e8 21 f3 ff ff       	call   f010009d <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d7c:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100d7f:	8d 83 74 c2 fe ff    	lea    -0x13d8c(%ebx),%eax
f0100d85:	50                   	push   %eax
f0100d86:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0100d8c:	50                   	push   %eax
f0100d8d:	68 8f 02 00 00       	push   $0x28f
f0100d92:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0100d98:	50                   	push   %eax
f0100d99:	e8 ff f2 ff ff       	call   f010009d <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d9e:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100da1:	8d 83 2e ca fe ff    	lea    -0x135d2(%ebx),%eax
f0100da7:	50                   	push   %eax
f0100da8:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0100dae:	50                   	push   %eax
f0100daf:	68 90 02 00 00       	push   $0x290
f0100db4:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0100dba:	50                   	push   %eax
f0100dbb:	e8 dd f2 ff ff       	call   f010009d <_panic>
	if (PGNUM(pa) >= npages)
f0100dc0:	89 c3                	mov    %eax,%ebx
f0100dc2:	c1 eb 0c             	shr    $0xc,%ebx
f0100dc5:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0100dc8:	76 6d                	jbe    f0100e37 <check_page_free_list+0x267>
	return (void *)(pa + KERNBASE);
f0100dca:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100dcf:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100dd2:	77 7c                	ja     f0100e50 <check_page_free_list+0x280>
			++nfree_extmem;
f0100dd4:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100dd8:	8b 12                	mov    (%edx),%edx
f0100dda:	85 d2                	test   %edx,%edx
f0100ddc:	0f 84 90 00 00 00    	je     f0100e72 <check_page_free_list+0x2a2>
		assert(pp >= pages);
f0100de2:	39 d1                	cmp    %edx,%ecx
f0100de4:	0f 87 e8 fe ff ff    	ja     f0100cd2 <check_page_free_list+0x102>
		assert(pp < pages + npages);
f0100dea:	39 d7                	cmp    %edx,%edi
f0100dec:	0f 86 02 ff ff ff    	jbe    f0100cf4 <check_page_free_list+0x124>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100df2:	89 d0                	mov    %edx,%eax
f0100df4:	29 c8                	sub    %ecx,%eax
f0100df6:	a8 07                	test   $0x7,%al
f0100df8:	0f 85 18 ff ff ff    	jne    f0100d16 <check_page_free_list+0x146>
	return (pp - pages) << PGSHIFT;
f0100dfe:	c1 f8 03             	sar    $0x3,%eax
		assert(page2pa(pp) != 0);
f0100e01:	c1 e0 0c             	shl    $0xc,%eax
f0100e04:	0f 84 2e ff ff ff    	je     f0100d38 <check_page_free_list+0x168>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e0a:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e0f:	0f 84 45 ff ff ff    	je     f0100d5a <check_page_free_list+0x18a>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100e15:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100e1a:	0f 84 5c ff ff ff    	je     f0100d7c <check_page_free_list+0x1ac>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100e20:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100e25:	0f 84 73 ff ff ff    	je     f0100d9e <check_page_free_list+0x1ce>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e2b:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100e30:	77 8e                	ja     f0100dc0 <check_page_free_list+0x1f0>
			++nfree_basemem;
f0100e32:	83 c6 01             	add    $0x1,%esi
f0100e35:	eb a1                	jmp    f0100dd8 <check_page_free_list+0x208>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e37:	50                   	push   %eax
f0100e38:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100e3b:	8d 83 f8 c1 fe ff    	lea    -0x13e08(%ebx),%eax
f0100e41:	50                   	push   %eax
f0100e42:	6a 52                	push   $0x52
f0100e44:	8d 83 c1 c9 fe ff    	lea    -0x1363f(%ebx),%eax
f0100e4a:	50                   	push   %eax
f0100e4b:	e8 4d f2 ff ff       	call   f010009d <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e50:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100e53:	8d 83 98 c2 fe ff    	lea    -0x13d68(%ebx),%eax
f0100e59:	50                   	push   %eax
f0100e5a:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0100e60:	50                   	push   %eax
f0100e61:	68 91 02 00 00       	push   $0x291
f0100e66:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0100e6c:	50                   	push   %eax
f0100e6d:	e8 2b f2 ff ff       	call   f010009d <_panic>
f0100e72:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
	assert(nfree_basemem > 0);
f0100e75:	85 f6                	test   %esi,%esi
f0100e77:	7e 1e                	jle    f0100e97 <check_page_free_list+0x2c7>
	assert(nfree_extmem > 0);
f0100e79:	85 db                	test   %ebx,%ebx
f0100e7b:	7e 3c                	jle    f0100eb9 <check_page_free_list+0x2e9>
	cprintf("check_page_free_list() succeeded!\n");
f0100e7d:	83 ec 0c             	sub    $0xc,%esp
f0100e80:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100e83:	8d 83 e0 c2 fe ff    	lea    -0x13d20(%ebx),%eax
f0100e89:	50                   	push   %eax
f0100e8a:	e8 1d 21 00 00       	call   f0102fac <cprintf>
}
f0100e8f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e92:	5b                   	pop    %ebx
f0100e93:	5e                   	pop    %esi
f0100e94:	5f                   	pop    %edi
f0100e95:	5d                   	pop    %ebp
f0100e96:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e97:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100e9a:	8d 83 48 ca fe ff    	lea    -0x135b8(%ebx),%eax
f0100ea0:	50                   	push   %eax
f0100ea1:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0100ea7:	50                   	push   %eax
f0100ea8:	68 99 02 00 00       	push   $0x299
f0100ead:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0100eb3:	50                   	push   %eax
f0100eb4:	e8 e4 f1 ff ff       	call   f010009d <_panic>
	assert(nfree_extmem > 0);
f0100eb9:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100ebc:	8d 83 5a ca fe ff    	lea    -0x135a6(%ebx),%eax
f0100ec2:	50                   	push   %eax
f0100ec3:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0100ec9:	50                   	push   %eax
f0100eca:	68 9a 02 00 00       	push   $0x29a
f0100ecf:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0100ed5:	50                   	push   %eax
f0100ed6:	e8 c2 f1 ff ff       	call   f010009d <_panic>
	if (!page_free_list)
f0100edb:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100ede:	8b 80 94 1f 00 00    	mov    0x1f94(%eax),%eax
f0100ee4:	85 c0                	test   %eax,%eax
f0100ee6:	0f 84 30 fd ff ff    	je     f0100c1c <check_page_free_list+0x4c>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100eec:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100eef:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ef2:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ef5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100ef8:	8b 75 c8             	mov    -0x38(%ebp),%esi
f0100efb:	c7 c3 d0 a6 11 f0    	mov    $0xf011a6d0,%ebx
f0100f01:	89 c2                	mov    %eax,%edx
f0100f03:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100f05:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100f0b:	0f 95 c2             	setne  %dl
f0100f0e:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100f11:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100f15:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100f17:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f1b:	8b 00                	mov    (%eax),%eax
f0100f1d:	85 c0                	test   %eax,%eax
f0100f1f:	75 e0                	jne    f0100f01 <check_page_free_list+0x331>
		*tp[1] = 0;
f0100f21:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f24:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100f2a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f2d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f30:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100f32:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100f35:	8b 75 c8             	mov    -0x38(%ebp),%esi
f0100f38:	89 86 94 1f 00 00    	mov    %eax,0x1f94(%esi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f3e:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
f0100f45:	e9 b8 fc ff ff       	jmp    f0100c02 <check_page_free_list+0x32>

f0100f4a <page_init>:
{
f0100f4a:	f3 0f 1e fb          	endbr32 
f0100f4e:	55                   	push   %ebp
f0100f4f:	89 e5                	mov    %esp,%ebp
f0100f51:	57                   	push   %edi
f0100f52:	56                   	push   %esi
f0100f53:	53                   	push   %ebx
f0100f54:	83 ec 2c             	sub    $0x2c,%esp
f0100f57:	e8 ad 1f 00 00       	call   f0102f09 <__x86.get_pc_thunk.dx>
f0100f5c:	81 c2 ac 73 01 00    	add    $0x173ac,%edx
f0100f62:	89 d7                	mov    %edx,%edi
f0100f64:	89 55 d0             	mov    %edx,-0x30(%ebp)
	size_t num_used = ((uint32_t)boot_alloc(0)-EXTPHYSMEM-KERNBASE)/PGSIZE;
f0100f67:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f6c:	e8 54 fb ff ff       	call   f0100ac5 <boot_alloc>
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100f71:	8b 8f 98 1f 00 00    	mov    0x1f98(%edi),%ecx
f0100f77:	89 4d e0             	mov    %ecx,-0x20(%ebp)
	size_t num_used = ((uint32_t)boot_alloc(0)-EXTPHYSMEM-KERNBASE)/PGSIZE;
f0100f7a:	05 00 00 f0 0f       	add    $0xff00000,%eax
f0100f7f:	c1 e8 0c             	shr    $0xc,%eax
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100f82:	8d 44 01 60          	lea    0x60(%ecx,%eax,1),%eax
f0100f86:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f89:	8b b7 94 1f 00 00    	mov    0x1f94(%edi),%esi
	for(size_t i = 0;i<npages;i++)
f0100f8f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100f94:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f99:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
			pages[i].pp_ref = 0;
f0100f9f:	c7 c1 d0 a6 11 f0    	mov    $0xf011a6d0,%ecx
f0100fa5:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
			pages[i].pp_ref = 1;
f0100fa8:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
			pages[i].pp_ref = 1;
f0100fab:	89 4d dc             	mov    %ecx,-0x24(%ebp)
	for(size_t i = 0;i<npages;i++)
f0100fae:	eb 3d                	jmp    f0100fed <page_init+0xa3>
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100fb0:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f0100fb3:	77 13                	ja     f0100fc8 <page_init+0x7e>
f0100fb5:	39 45 d8             	cmp    %eax,-0x28(%ebp)
f0100fb8:	76 0e                	jbe    f0100fc8 <page_init+0x7e>
			pages[i].pp_ref = 1;
f0100fba:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100fbd:	8b 09                	mov    (%ecx),%ecx
f0100fbf:	66 c7 44 c1 04 01 00 	movw   $0x1,0x4(%ecx,%eax,8)
f0100fc6:	eb 22                	jmp    f0100fea <page_init+0xa0>
f0100fc8:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
			pages[i].pp_ref = 0;
f0100fcf:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100fd2:	89 cf                	mov    %ecx,%edi
f0100fd4:	03 3b                	add    (%ebx),%edi
f0100fd6:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
			pages[i].pp_link = page_free_list;
f0100fdc:	89 37                	mov    %esi,(%edi)
			page_free_list = &pages[i];
f0100fde:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100fe1:	89 ce                	mov    %ecx,%esi
f0100fe3:	03 33                	add    (%ebx),%esi
f0100fe5:	bb 01 00 00 00       	mov    $0x1,%ebx
	for(size_t i = 0;i<npages;i++)
f0100fea:	83 c0 01             	add    $0x1,%eax
f0100fed:	39 02                	cmp    %eax,(%edx)
f0100fef:	76 11                	jbe    f0101002 <page_init+0xb8>
		if(i == 0)
f0100ff1:	85 c0                	test   %eax,%eax
f0100ff3:	75 bb                	jne    f0100fb0 <page_init+0x66>
			pages[i].pp_ref = 1;
f0100ff5:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100ff8:	8b 0f                	mov    (%edi),%ecx
f0100ffa:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
f0101000:	eb e8                	jmp    f0100fea <page_init+0xa0>
f0101002:	84 db                	test   %bl,%bl
f0101004:	74 09                	je     f010100f <page_init+0xc5>
f0101006:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101009:	89 b0 94 1f 00 00    	mov    %esi,0x1f94(%eax)
}
f010100f:	83 c4 2c             	add    $0x2c,%esp
f0101012:	5b                   	pop    %ebx
f0101013:	5e                   	pop    %esi
f0101014:	5f                   	pop    %edi
f0101015:	5d                   	pop    %ebp
f0101016:	c3                   	ret    

f0101017 <page_alloc>:
{
f0101017:	f3 0f 1e fb          	endbr32 
f010101b:	55                   	push   %ebp
f010101c:	89 e5                	mov    %esp,%ebp
f010101e:	56                   	push   %esi
f010101f:	53                   	push   %ebx
f0101020:	e8 36 f1 ff ff       	call   f010015b <__x86.get_pc_thunk.bx>
f0101025:	81 c3 e3 72 01 00    	add    $0x172e3,%ebx
	if(page_free_list == NULL)
f010102b:	8b b3 94 1f 00 00    	mov    0x1f94(%ebx),%esi
f0101031:	85 f6                	test   %esi,%esi
f0101033:	74 37                	je     f010106c <page_alloc+0x55>
	page_free_list = page_free_list->pp_link;
f0101035:	8b 06                	mov    (%esi),%eax
f0101037:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
	alloc->pp_link = NULL;
f010103d:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
f0101043:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0101049:	89 f1                	mov    %esi,%ecx
f010104b:	2b 08                	sub    (%eax),%ecx
f010104d:	89 c8                	mov    %ecx,%eax
f010104f:	c1 f8 03             	sar    $0x3,%eax
f0101052:	89 c1                	mov    %eax,%ecx
f0101054:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f0101057:	25 ff ff 0f 00       	and    $0xfffff,%eax
f010105c:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
f0101062:	3b 02                	cmp    (%edx),%eax
f0101064:	73 0f                	jae    f0101075 <page_alloc+0x5e>
	if(alloc_flags & ALLOC_ZERO)
f0101066:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f010106a:	75 1f                	jne    f010108b <page_alloc+0x74>
}
f010106c:	89 f0                	mov    %esi,%eax
f010106e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101071:	5b                   	pop    %ebx
f0101072:	5e                   	pop    %esi
f0101073:	5d                   	pop    %ebp
f0101074:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101075:	51                   	push   %ecx
f0101076:	8d 83 f8 c1 fe ff    	lea    -0x13e08(%ebx),%eax
f010107c:	50                   	push   %eax
f010107d:	6a 52                	push   $0x52
f010107f:	8d 83 c1 c9 fe ff    	lea    -0x1363f(%ebx),%eax
f0101085:	50                   	push   %eax
f0101086:	e8 12 f0 ff ff       	call   f010009d <_panic>
		memset(head,0,PGSIZE);
f010108b:	83 ec 04             	sub    $0x4,%esp
f010108e:	68 00 10 00 00       	push   $0x1000
f0101093:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0101095:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f010109b:	51                   	push   %ecx
f010109c:	e8 10 2b 00 00       	call   f0103bb1 <memset>
f01010a1:	83 c4 10             	add    $0x10,%esp
f01010a4:	eb c6                	jmp    f010106c <page_alloc+0x55>

f01010a6 <page_free>:
{
f01010a6:	f3 0f 1e fb          	endbr32 
f01010aa:	55                   	push   %ebp
f01010ab:	89 e5                	mov    %esp,%ebp
f01010ad:	53                   	push   %ebx
f01010ae:	83 ec 04             	sub    $0x4,%esp
f01010b1:	e8 a5 f0 ff ff       	call   f010015b <__x86.get_pc_thunk.bx>
f01010b6:	81 c3 52 72 01 00    	add    $0x17252,%ebx
f01010bc:	8b 45 08             	mov    0x8(%ebp),%eax
	if((pp->pp_ref != 0) | (pp->pp_link!=NULL))
f01010bf:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01010c4:	75 18                	jne    f01010de <page_free+0x38>
f01010c6:	83 38 00             	cmpl   $0x0,(%eax)
f01010c9:	75 13                	jne    f01010de <page_free+0x38>
	pp->pp_link = page_free_list;
f01010cb:	8b 8b 94 1f 00 00    	mov    0x1f94(%ebx),%ecx
f01010d1:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f01010d3:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
}
f01010d9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010dc:	c9                   	leave  
f01010dd:	c3                   	ret    
		panic("at pmap.c:page_free():330 Page double free or freeing a referenced page");
f01010de:	83 ec 04             	sub    $0x4,%esp
f01010e1:	8d 83 04 c3 fe ff    	lea    -0x13cfc(%ebx),%eax
f01010e7:	50                   	push   %eax
f01010e8:	68 65 01 00 00       	push   $0x165
f01010ed:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01010f3:	50                   	push   %eax
f01010f4:	e8 a4 ef ff ff       	call   f010009d <_panic>

f01010f9 <page_decref>:
{
f01010f9:	f3 0f 1e fb          	endbr32 
f01010fd:	55                   	push   %ebp
f01010fe:	89 e5                	mov    %esp,%ebp
f0101100:	83 ec 08             	sub    $0x8,%esp
f0101103:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101106:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010110a:	83 e8 01             	sub    $0x1,%eax
f010110d:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101111:	66 85 c0             	test   %ax,%ax
f0101114:	74 02                	je     f0101118 <page_decref+0x1f>
}
f0101116:	c9                   	leave  
f0101117:	c3                   	ret    
		page_free(pp);
f0101118:	83 ec 0c             	sub    $0xc,%esp
f010111b:	52                   	push   %edx
f010111c:	e8 85 ff ff ff       	call   f01010a6 <page_free>
f0101121:	83 c4 10             	add    $0x10,%esp
}
f0101124:	eb f0                	jmp    f0101116 <page_decref+0x1d>

f0101126 <pgdir_walk>:
{
f0101126:	f3 0f 1e fb          	endbr32 
f010112a:	55                   	push   %ebp
f010112b:	89 e5                	mov    %esp,%ebp
f010112d:	57                   	push   %edi
f010112e:	56                   	push   %esi
f010112f:	53                   	push   %ebx
f0101130:	83 ec 0c             	sub    $0xc,%esp
f0101133:	e8 d9 1d 00 00       	call   f0102f11 <__x86.get_pc_thunk.di>
f0101138:	81 c7 d0 71 01 00    	add    $0x171d0,%edi
f010113e:	8b 75 0c             	mov    0xc(%ebp),%esi
	unsigned int dir_offset = PDX(va);
f0101141:	89 f3                	mov    %esi,%ebx
f0101143:	c1 eb 16             	shr    $0x16,%ebx
	pde_t* entry = pgdir+dir_offset;
f0101146:	c1 e3 02             	shl    $0x2,%ebx
f0101149:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*entry & PTE_P))
f010114c:	f6 03 01             	testb  $0x1,(%ebx)
f010114f:	75 2f                	jne    f0101180 <pgdir_walk+0x5a>
		if(create)
f0101151:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101155:	74 73                	je     f01011ca <pgdir_walk+0xa4>
			new_page = page_alloc(1);
f0101157:	83 ec 0c             	sub    $0xc,%esp
f010115a:	6a 01                	push   $0x1
f010115c:	e8 b6 fe ff ff       	call   f0101017 <page_alloc>
			if(new_page == NULL)
f0101161:	83 c4 10             	add    $0x10,%esp
f0101164:	85 c0                	test   %eax,%eax
f0101166:	74 3f                	je     f01011a7 <pgdir_walk+0x81>
			new_page->pp_ref++;
f0101168:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f010116d:	c7 c2 d0 a6 11 f0    	mov    $0xf011a6d0,%edx
f0101173:	2b 02                	sub    (%edx),%eax
f0101175:	c1 f8 03             	sar    $0x3,%eax
f0101178:	c1 e0 0c             	shl    $0xc,%eax
			*entry = ((page2pa(new_page))|PTE_P|PTE_W|PTE_U);
f010117b:	83 c8 07             	or     $0x7,%eax
f010117e:	89 03                	mov    %eax,(%ebx)
	page_base = (pte_t*)KADDR(PTE_ADDR(*entry));
f0101180:	8b 03                	mov    (%ebx),%eax
f0101182:	89 c2                	mov    %eax,%edx
f0101184:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f010118a:	c1 e8 0c             	shr    $0xc,%eax
f010118d:	c7 c1 c8 a6 11 f0    	mov    $0xf011a6c8,%ecx
f0101193:	3b 01                	cmp    (%ecx),%eax
f0101195:	73 18                	jae    f01011af <pgdir_walk+0x89>
	page_offset = PTX(va);
f0101197:	c1 ee 0a             	shr    $0xa,%esi
	return &page_base[page_offset];
f010119a:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01011a0:	8d 84 32 00 00 00 f0 	lea    -0x10000000(%edx,%esi,1),%eax
}
f01011a7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011aa:	5b                   	pop    %ebx
f01011ab:	5e                   	pop    %esi
f01011ac:	5f                   	pop    %edi
f01011ad:	5d                   	pop    %ebp
f01011ae:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011af:	52                   	push   %edx
f01011b0:	8d 87 f8 c1 fe ff    	lea    -0x13e08(%edi),%eax
f01011b6:	50                   	push   %eax
f01011b7:	68 af 01 00 00       	push   $0x1af
f01011bc:	8d 87 b5 c9 fe ff    	lea    -0x1364b(%edi),%eax
f01011c2:	50                   	push   %eax
f01011c3:	89 fb                	mov    %edi,%ebx
f01011c5:	e8 d3 ee ff ff       	call   f010009d <_panic>
			return NULL;
f01011ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01011cf:	eb d6                	jmp    f01011a7 <pgdir_walk+0x81>

f01011d1 <boot_map_region>:
{
f01011d1:	55                   	push   %ebp
f01011d2:	89 e5                	mov    %esp,%ebp
f01011d4:	57                   	push   %edi
f01011d5:	56                   	push   %esi
f01011d6:	53                   	push   %ebx
f01011d7:	83 ec 1c             	sub    $0x1c,%esp
f01011da:	89 c7                	mov    %eax,%edi
f01011dc:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01011df:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for(add = 0;add<size;add+=PGSIZE)
f01011e2:	be 00 00 00 00       	mov    $0x0,%esi
f01011e7:	89 f3                	mov    %esi,%ebx
f01011e9:	03 5d 08             	add    0x8(%ebp),%ebx
f01011ec:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f01011ef:	76 24                	jbe    f0101215 <boot_map_region+0x44>
		entry = pgdir_walk(pgdir,(void*)va,1);  // get the entry of page table
f01011f1:	83 ec 04             	sub    $0x4,%esp
f01011f4:	6a 01                	push   $0x1
f01011f6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01011f9:	01 f0                	add    %esi,%eax
f01011fb:	50                   	push   %eax
f01011fc:	57                   	push   %edi
f01011fd:	e8 24 ff ff ff       	call   f0101126 <pgdir_walk>
		*entry = (pa|perm|PTE_P);
f0101202:	0b 5d 0c             	or     0xc(%ebp),%ebx
f0101205:	83 cb 01             	or     $0x1,%ebx
f0101208:	89 18                	mov    %ebx,(%eax)
	for(add = 0;add<size;add+=PGSIZE)
f010120a:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0101210:	83 c4 10             	add    $0x10,%esp
f0101213:	eb d2                	jmp    f01011e7 <boot_map_region+0x16>
}
f0101215:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101218:	5b                   	pop    %ebx
f0101219:	5e                   	pop    %esi
f010121a:	5f                   	pop    %edi
f010121b:	5d                   	pop    %ebp
f010121c:	c3                   	ret    

f010121d <page_lookup>:
{
f010121d:	f3 0f 1e fb          	endbr32 
f0101221:	55                   	push   %ebp
f0101222:	89 e5                	mov    %esp,%ebp
f0101224:	56                   	push   %esi
f0101225:	53                   	push   %ebx
f0101226:	e8 30 ef ff ff       	call   f010015b <__x86.get_pc_thunk.bx>
f010122b:	81 c3 dd 70 01 00    	add    $0x170dd,%ebx
f0101231:	8b 75 10             	mov    0x10(%ebp),%esi
	entry = pgdir_walk(pgdir,va,0);
f0101234:	83 ec 04             	sub    $0x4,%esp
f0101237:	6a 00                	push   $0x0
f0101239:	ff 75 0c             	pushl  0xc(%ebp)
f010123c:	ff 75 08             	pushl  0x8(%ebp)
f010123f:	e8 e2 fe ff ff       	call   f0101126 <pgdir_walk>
	if(entry == NULL)
f0101244:	83 c4 10             	add    $0x10,%esp
f0101247:	85 c0                	test   %eax,%eax
f0101249:	74 46                	je     f0101291 <page_lookup+0x74>
	if(!(*entry & PTE_P))
f010124b:	8b 10                	mov    (%eax),%edx
f010124d:	f6 c2 01             	test   $0x1,%dl
f0101250:	74 43                	je     f0101295 <page_lookup+0x78>
f0101252:	c1 ea 0c             	shr    $0xc,%edx
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101255:	c7 c1 c8 a6 11 f0    	mov    $0xf011a6c8,%ecx
f010125b:	39 11                	cmp    %edx,(%ecx)
f010125d:	76 1a                	jbe    f0101279 <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f010125f:	c7 c1 d0 a6 11 f0    	mov    $0xf011a6d0,%ecx
f0101265:	8b 09                	mov    (%ecx),%ecx
f0101267:	8d 14 d1             	lea    (%ecx,%edx,8),%edx
	if(pte_store != NULL)
f010126a:	85 f6                	test   %esi,%esi
f010126c:	74 02                	je     f0101270 <page_lookup+0x53>
		*pte_store = entry;
f010126e:	89 06                	mov    %eax,(%esi)
}
f0101270:	89 d0                	mov    %edx,%eax
f0101272:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101275:	5b                   	pop    %ebx
f0101276:	5e                   	pop    %esi
f0101277:	5d                   	pop    %ebp
f0101278:	c3                   	ret    
		panic("pa2page called with invalid pa");
f0101279:	83 ec 04             	sub    $0x4,%esp
f010127c:	8d 83 4c c3 fe ff    	lea    -0x13cb4(%ebx),%eax
f0101282:	50                   	push   %eax
f0101283:	6a 4b                	push   $0x4b
f0101285:	8d 83 c1 c9 fe ff    	lea    -0x1363f(%ebx),%eax
f010128b:	50                   	push   %eax
f010128c:	e8 0c ee ff ff       	call   f010009d <_panic>
		return NULL;
f0101291:	89 c2                	mov    %eax,%edx
f0101293:	eb db                	jmp    f0101270 <page_lookup+0x53>
		return NULL;
f0101295:	ba 00 00 00 00       	mov    $0x0,%edx
f010129a:	eb d4                	jmp    f0101270 <page_lookup+0x53>

f010129c <page_remove>:
{
f010129c:	f3 0f 1e fb          	endbr32 
f01012a0:	55                   	push   %ebp
f01012a1:	89 e5                	mov    %esp,%ebp
f01012a3:	53                   	push   %ebx
f01012a4:	83 ec 18             	sub    $0x18,%esp
f01012a7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t* pte = NULL;
f01012aa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo* page = page_lookup(pgdir,va,&pte);
f01012b1:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01012b4:	50                   	push   %eax
f01012b5:	53                   	push   %ebx
f01012b6:	ff 75 08             	pushl  0x8(%ebp)
f01012b9:	e8 5f ff ff ff       	call   f010121d <page_lookup>
	if(page == NULL)
f01012be:	83 c4 10             	add    $0x10,%esp
f01012c1:	85 c0                	test   %eax,%eax
f01012c3:	74 18                	je     f01012dd <page_remove+0x41>
	page_decref(page);
f01012c5:	83 ec 0c             	sub    $0xc,%esp
f01012c8:	50                   	push   %eax
f01012c9:	e8 2b fe ff ff       	call   f01010f9 <page_decref>
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01012ce:	0f 01 3b             	invlpg (%ebx)
	*pte = 0;
f01012d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012d4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f01012da:	83 c4 10             	add    $0x10,%esp
}
f01012dd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01012e0:	c9                   	leave  
f01012e1:	c3                   	ret    

f01012e2 <page_insert>:
{
f01012e2:	f3 0f 1e fb          	endbr32 
f01012e6:	55                   	push   %ebp
f01012e7:	89 e5                	mov    %esp,%ebp
f01012e9:	57                   	push   %edi
f01012ea:	56                   	push   %esi
f01012eb:	53                   	push   %ebx
f01012ec:	83 ec 10             	sub    $0x10,%esp
f01012ef:	e8 1d 1c 00 00       	call   f0102f11 <__x86.get_pc_thunk.di>
f01012f4:	81 c7 14 70 01 00    	add    $0x17014,%edi
f01012fa:	8b 75 08             	mov    0x8(%ebp),%esi
	entry = pgdir_walk(pgdir,va,1); // get the page table entry 
f01012fd:	6a 01                	push   $0x1
f01012ff:	ff 75 10             	pushl  0x10(%ebp)
f0101302:	56                   	push   %esi
f0101303:	e8 1e fe ff ff       	call   f0101126 <pgdir_walk>
	if(entry == NULL)
f0101308:	83 c4 10             	add    $0x10,%esp
f010130b:	85 c0                	test   %eax,%eax
f010130d:	74 5a                	je     f0101369 <page_insert+0x87>
f010130f:	89 c3                	mov    %eax,%ebx
	pp->pp_ref++;
f0101311:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101314:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	if(*entry&PTE_P)
f0101319:	f6 03 01             	testb  $0x1,(%ebx)
f010131c:	75 34                	jne    f0101352 <page_insert+0x70>
	return (pp - pages) << PGSHIFT;
f010131e:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0101324:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101327:	2b 10                	sub    (%eax),%edx
f0101329:	89 d0                	mov    %edx,%eax
f010132b:	c1 f8 03             	sar    $0x3,%eax
f010132e:	c1 e0 0c             	shl    $0xc,%eax
	*entry = ((page2pa(pp))|perm|PTE_P);
f0101331:	0b 45 14             	or     0x14(%ebp),%eax
f0101334:	83 c8 01             	or     $0x1,%eax
f0101337:	89 03                	mov    %eax,(%ebx)
	pgdir[PDX(va)] |= perm;
f0101339:	8b 45 10             	mov    0x10(%ebp),%eax
f010133c:	c1 e8 16             	shr    $0x16,%eax
f010133f:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0101342:	09 0c 86             	or     %ecx,(%esi,%eax,4)
	return 0;
f0101345:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010134a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010134d:	5b                   	pop    %ebx
f010134e:	5e                   	pop    %esi
f010134f:	5f                   	pop    %edi
f0101350:	5d                   	pop    %ebp
f0101351:	c3                   	ret    
f0101352:	8b 45 10             	mov    0x10(%ebp),%eax
f0101355:	0f 01 38             	invlpg (%eax)
		page_remove(pgdir,va);
f0101358:	83 ec 08             	sub    $0x8,%esp
f010135b:	ff 75 10             	pushl  0x10(%ebp)
f010135e:	56                   	push   %esi
f010135f:	e8 38 ff ff ff       	call   f010129c <page_remove>
f0101364:	83 c4 10             	add    $0x10,%esp
f0101367:	eb b5                	jmp    f010131e <page_insert+0x3c>
		return -E_NO_MEM;
f0101369:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010136e:	eb da                	jmp    f010134a <page_insert+0x68>

f0101370 <mem_init>:
{
f0101370:	f3 0f 1e fb          	endbr32 
f0101374:	55                   	push   %ebp
f0101375:	89 e5                	mov    %esp,%ebp
f0101377:	57                   	push   %edi
f0101378:	56                   	push   %esi
f0101379:	53                   	push   %ebx
f010137a:	83 ec 3c             	sub    $0x3c,%esp
f010137d:	e8 d9 ed ff ff       	call   f010015b <__x86.get_pc_thunk.bx>
f0101382:	81 c3 86 6f 01 00    	add    $0x16f86,%ebx
	basemem = nvram_read(NVRAM_BASELO);
f0101388:	b8 15 00 00 00       	mov    $0x15,%eax
f010138d:	e8 fd f6 ff ff       	call   f0100a8f <nvram_read>
f0101392:	89 c6                	mov    %eax,%esi
	extmem = nvram_read(NVRAM_EXTLO);
f0101394:	b8 17 00 00 00       	mov    $0x17,%eax
f0101399:	e8 f1 f6 ff ff       	call   f0100a8f <nvram_read>
f010139e:	89 c7                	mov    %eax,%edi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01013a0:	b8 34 00 00 00       	mov    $0x34,%eax
f01013a5:	e8 e5 f6 ff ff       	call   f0100a8f <nvram_read>
	if (ext16mem)
f01013aa:	c1 e0 06             	shl    $0x6,%eax
f01013ad:	0f 84 c6 00 00 00    	je     f0101479 <mem_init+0x109>
		totalmem = 16 * 1024 + ext16mem;
f01013b3:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f01013b8:	89 c1                	mov    %eax,%ecx
f01013ba:	c1 e9 02             	shr    $0x2,%ecx
f01013bd:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
f01013c3:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f01013c5:	89 f2                	mov    %esi,%edx
f01013c7:	c1 ea 02             	shr    $0x2,%edx
f01013ca:	89 93 98 1f 00 00    	mov    %edx,0x1f98(%ebx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013d0:	89 c2                	mov    %eax,%edx
f01013d2:	29 f2                	sub    %esi,%edx
f01013d4:	52                   	push   %edx
f01013d5:	56                   	push   %esi
f01013d6:	50                   	push   %eax
f01013d7:	8d 83 6c c3 fe ff    	lea    -0x13c94(%ebx),%eax
f01013dd:	50                   	push   %eax
f01013de:	e8 c9 1b 00 00       	call   f0102fac <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01013e3:	b8 00 10 00 00       	mov    $0x1000,%eax
f01013e8:	e8 d8 f6 ff ff       	call   f0100ac5 <boot_alloc>
f01013ed:	c7 c6 cc a6 11 f0    	mov    $0xf011a6cc,%esi
f01013f3:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f01013f5:	83 c4 0c             	add    $0xc,%esp
f01013f8:	68 00 10 00 00       	push   $0x1000
f01013fd:	6a 00                	push   $0x0
f01013ff:	50                   	push   %eax
f0101400:	e8 ac 27 00 00       	call   f0103bb1 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101405:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f0101407:	83 c4 10             	add    $0x10,%esp
f010140a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010140f:	76 78                	jbe    f0101489 <mem_init+0x119>
	return (physaddr_t)kva - KERNBASE;
f0101411:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101417:	83 ca 05             	or     $0x5,%edx
f010141a:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages*sizeof(struct PageInfo));
f0101420:	c7 c7 c8 a6 11 f0    	mov    $0xf011a6c8,%edi
f0101426:	8b 07                	mov    (%edi),%eax
f0101428:	c1 e0 03             	shl    $0x3,%eax
f010142b:	e8 95 f6 ff ff       	call   f0100ac5 <boot_alloc>
f0101430:	c7 c6 d0 a6 11 f0    	mov    $0xf011a6d0,%esi
f0101436:	89 06                	mov    %eax,(%esi)
	memset(pages,0,npages*sizeof(struct PageInfo));
f0101438:	83 ec 04             	sub    $0x4,%esp
f010143b:	8b 17                	mov    (%edi),%edx
f010143d:	c1 e2 03             	shl    $0x3,%edx
f0101440:	52                   	push   %edx
f0101441:	6a 00                	push   $0x0
f0101443:	50                   	push   %eax
f0101444:	e8 68 27 00 00       	call   f0103bb1 <memset>
	page_init();
f0101449:	e8 fc fa ff ff       	call   f0100f4a <page_init>
	check_page_free_list(1);
f010144e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101453:	e8 78 f7 ff ff       	call   f0100bd0 <check_page_free_list>
	if (!pages)
f0101458:	83 c4 10             	add    $0x10,%esp
f010145b:	83 3e 00             	cmpl   $0x0,(%esi)
f010145e:	74 42                	je     f01014a2 <mem_init+0x132>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101460:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f0101466:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f010146d:	85 c0                	test   %eax,%eax
f010146f:	74 4c                	je     f01014bd <mem_init+0x14d>
		++nfree;
f0101471:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101475:	8b 00                	mov    (%eax),%eax
f0101477:	eb f4                	jmp    f010146d <mem_init+0xfd>
		totalmem = 1 * 1024 + extmem;
f0101479:	8d 87 00 04 00 00    	lea    0x400(%edi),%eax
f010147f:	85 ff                	test   %edi,%edi
f0101481:	0f 44 c6             	cmove  %esi,%eax
f0101484:	e9 2f ff ff ff       	jmp    f01013b8 <mem_init+0x48>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101489:	50                   	push   %eax
f010148a:	8d 83 a8 c3 fe ff    	lea    -0x13c58(%ebx),%eax
f0101490:	50                   	push   %eax
f0101491:	68 a0 00 00 00       	push   $0xa0
f0101496:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010149c:	50                   	push   %eax
f010149d:	e8 fb eb ff ff       	call   f010009d <_panic>
		panic("'pages' is a null pointer!");
f01014a2:	83 ec 04             	sub    $0x4,%esp
f01014a5:	8d 83 6b ca fe ff    	lea    -0x13595(%ebx),%eax
f01014ab:	50                   	push   %eax
f01014ac:	68 ad 02 00 00       	push   $0x2ad
f01014b1:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01014b7:	50                   	push   %eax
f01014b8:	e8 e0 eb ff ff       	call   f010009d <_panic>
	assert((pp0 = page_alloc(0)));
f01014bd:	83 ec 0c             	sub    $0xc,%esp
f01014c0:	6a 00                	push   $0x0
f01014c2:	e8 50 fb ff ff       	call   f0101017 <page_alloc>
f01014c7:	89 c6                	mov    %eax,%esi
f01014c9:	83 c4 10             	add    $0x10,%esp
f01014cc:	85 c0                	test   %eax,%eax
f01014ce:	0f 84 31 02 00 00    	je     f0101705 <mem_init+0x395>
	assert((pp1 = page_alloc(0)));
f01014d4:	83 ec 0c             	sub    $0xc,%esp
f01014d7:	6a 00                	push   $0x0
f01014d9:	e8 39 fb ff ff       	call   f0101017 <page_alloc>
f01014de:	89 c7                	mov    %eax,%edi
f01014e0:	83 c4 10             	add    $0x10,%esp
f01014e3:	85 c0                	test   %eax,%eax
f01014e5:	0f 84 39 02 00 00    	je     f0101724 <mem_init+0x3b4>
	assert((pp2 = page_alloc(0)));
f01014eb:	83 ec 0c             	sub    $0xc,%esp
f01014ee:	6a 00                	push   $0x0
f01014f0:	e8 22 fb ff ff       	call   f0101017 <page_alloc>
f01014f5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014f8:	83 c4 10             	add    $0x10,%esp
f01014fb:	85 c0                	test   %eax,%eax
f01014fd:	0f 84 40 02 00 00    	je     f0101743 <mem_init+0x3d3>
	assert(pp1 && pp1 != pp0);
f0101503:	39 fe                	cmp    %edi,%esi
f0101505:	0f 84 57 02 00 00    	je     f0101762 <mem_init+0x3f2>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010150b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010150e:	39 c7                	cmp    %eax,%edi
f0101510:	0f 84 6b 02 00 00    	je     f0101781 <mem_init+0x411>
f0101516:	39 c6                	cmp    %eax,%esi
f0101518:	0f 84 63 02 00 00    	je     f0101781 <mem_init+0x411>
	return (pp - pages) << PGSHIFT;
f010151e:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0101524:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101526:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f010152c:	8b 10                	mov    (%eax),%edx
f010152e:	c1 e2 0c             	shl    $0xc,%edx
f0101531:	89 f0                	mov    %esi,%eax
f0101533:	29 c8                	sub    %ecx,%eax
f0101535:	c1 f8 03             	sar    $0x3,%eax
f0101538:	c1 e0 0c             	shl    $0xc,%eax
f010153b:	39 d0                	cmp    %edx,%eax
f010153d:	0f 83 5d 02 00 00    	jae    f01017a0 <mem_init+0x430>
f0101543:	89 f8                	mov    %edi,%eax
f0101545:	29 c8                	sub    %ecx,%eax
f0101547:	c1 f8 03             	sar    $0x3,%eax
f010154a:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f010154d:	39 c2                	cmp    %eax,%edx
f010154f:	0f 86 6a 02 00 00    	jbe    f01017bf <mem_init+0x44f>
f0101555:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101558:	29 c8                	sub    %ecx,%eax
f010155a:	c1 f8 03             	sar    $0x3,%eax
f010155d:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f0101560:	39 c2                	cmp    %eax,%edx
f0101562:	0f 86 76 02 00 00    	jbe    f01017de <mem_init+0x46e>
	fl = page_free_list;
f0101568:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f010156e:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f0101571:	c7 83 94 1f 00 00 00 	movl   $0x0,0x1f94(%ebx)
f0101578:	00 00 00 
	assert(!page_alloc(0));
f010157b:	83 ec 0c             	sub    $0xc,%esp
f010157e:	6a 00                	push   $0x0
f0101580:	e8 92 fa ff ff       	call   f0101017 <page_alloc>
f0101585:	83 c4 10             	add    $0x10,%esp
f0101588:	85 c0                	test   %eax,%eax
f010158a:	0f 85 6d 02 00 00    	jne    f01017fd <mem_init+0x48d>
	page_free(pp0);
f0101590:	83 ec 0c             	sub    $0xc,%esp
f0101593:	56                   	push   %esi
f0101594:	e8 0d fb ff ff       	call   f01010a6 <page_free>
	page_free(pp1);
f0101599:	89 3c 24             	mov    %edi,(%esp)
f010159c:	e8 05 fb ff ff       	call   f01010a6 <page_free>
	page_free(pp2);
f01015a1:	83 c4 04             	add    $0x4,%esp
f01015a4:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015a7:	e8 fa fa ff ff       	call   f01010a6 <page_free>
	assert((pp0 = page_alloc(0)));
f01015ac:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015b3:	e8 5f fa ff ff       	call   f0101017 <page_alloc>
f01015b8:	89 c6                	mov    %eax,%esi
f01015ba:	83 c4 10             	add    $0x10,%esp
f01015bd:	85 c0                	test   %eax,%eax
f01015bf:	0f 84 57 02 00 00    	je     f010181c <mem_init+0x4ac>
	assert((pp1 = page_alloc(0)));
f01015c5:	83 ec 0c             	sub    $0xc,%esp
f01015c8:	6a 00                	push   $0x0
f01015ca:	e8 48 fa ff ff       	call   f0101017 <page_alloc>
f01015cf:	89 c7                	mov    %eax,%edi
f01015d1:	83 c4 10             	add    $0x10,%esp
f01015d4:	85 c0                	test   %eax,%eax
f01015d6:	0f 84 5f 02 00 00    	je     f010183b <mem_init+0x4cb>
	assert((pp2 = page_alloc(0)));
f01015dc:	83 ec 0c             	sub    $0xc,%esp
f01015df:	6a 00                	push   $0x0
f01015e1:	e8 31 fa ff ff       	call   f0101017 <page_alloc>
f01015e6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015e9:	83 c4 10             	add    $0x10,%esp
f01015ec:	85 c0                	test   %eax,%eax
f01015ee:	0f 84 66 02 00 00    	je     f010185a <mem_init+0x4ea>
	assert(pp1 && pp1 != pp0);
f01015f4:	39 fe                	cmp    %edi,%esi
f01015f6:	0f 84 7d 02 00 00    	je     f0101879 <mem_init+0x509>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015fc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015ff:	39 c7                	cmp    %eax,%edi
f0101601:	0f 84 91 02 00 00    	je     f0101898 <mem_init+0x528>
f0101607:	39 c6                	cmp    %eax,%esi
f0101609:	0f 84 89 02 00 00    	je     f0101898 <mem_init+0x528>
	assert(!page_alloc(0));
f010160f:	83 ec 0c             	sub    $0xc,%esp
f0101612:	6a 00                	push   $0x0
f0101614:	e8 fe f9 ff ff       	call   f0101017 <page_alloc>
f0101619:	83 c4 10             	add    $0x10,%esp
f010161c:	85 c0                	test   %eax,%eax
f010161e:	0f 85 93 02 00 00    	jne    f01018b7 <mem_init+0x547>
f0101624:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f010162a:	89 f1                	mov    %esi,%ecx
f010162c:	2b 08                	sub    (%eax),%ecx
f010162e:	89 c8                	mov    %ecx,%eax
f0101630:	c1 f8 03             	sar    $0x3,%eax
f0101633:	89 c2                	mov    %eax,%edx
f0101635:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101638:	25 ff ff 0f 00       	and    $0xfffff,%eax
f010163d:	c7 c1 c8 a6 11 f0    	mov    $0xf011a6c8,%ecx
f0101643:	3b 01                	cmp    (%ecx),%eax
f0101645:	0f 83 8b 02 00 00    	jae    f01018d6 <mem_init+0x566>
	memset(page2kva(pp0), 1, PGSIZE);
f010164b:	83 ec 04             	sub    $0x4,%esp
f010164e:	68 00 10 00 00       	push   $0x1000
f0101653:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101655:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f010165b:	52                   	push   %edx
f010165c:	e8 50 25 00 00       	call   f0103bb1 <memset>
	page_free(pp0);
f0101661:	89 34 24             	mov    %esi,(%esp)
f0101664:	e8 3d fa ff ff       	call   f01010a6 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101669:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101670:	e8 a2 f9 ff ff       	call   f0101017 <page_alloc>
f0101675:	83 c4 10             	add    $0x10,%esp
f0101678:	85 c0                	test   %eax,%eax
f010167a:	0f 84 6c 02 00 00    	je     f01018ec <mem_init+0x57c>
	assert(pp && pp0 == pp);
f0101680:	39 c6                	cmp    %eax,%esi
f0101682:	0f 85 83 02 00 00    	jne    f010190b <mem_init+0x59b>
	return (pp - pages) << PGSHIFT;
f0101688:	c7 c2 d0 a6 11 f0    	mov    $0xf011a6d0,%edx
f010168e:	2b 02                	sub    (%edx),%eax
f0101690:	c1 f8 03             	sar    $0x3,%eax
f0101693:	89 c2                	mov    %eax,%edx
f0101695:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101698:	25 ff ff 0f 00       	and    $0xfffff,%eax
f010169d:	c7 c1 c8 a6 11 f0    	mov    $0xf011a6c8,%ecx
f01016a3:	3b 01                	cmp    (%ecx),%eax
f01016a5:	0f 83 7f 02 00 00    	jae    f010192a <mem_init+0x5ba>
	return (void *)(pa + KERNBASE);
f01016ab:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f01016b1:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f01016b7:	80 38 00             	cmpb   $0x0,(%eax)
f01016ba:	0f 85 80 02 00 00    	jne    f0101940 <mem_init+0x5d0>
f01016c0:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01016c3:	39 d0                	cmp    %edx,%eax
f01016c5:	75 f0                	jne    f01016b7 <mem_init+0x347>
	page_free_list = fl;
f01016c7:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01016ca:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
	page_free(pp0);
f01016d0:	83 ec 0c             	sub    $0xc,%esp
f01016d3:	56                   	push   %esi
f01016d4:	e8 cd f9 ff ff       	call   f01010a6 <page_free>
	page_free(pp1);
f01016d9:	89 3c 24             	mov    %edi,(%esp)
f01016dc:	e8 c5 f9 ff ff       	call   f01010a6 <page_free>
	page_free(pp2);
f01016e1:	83 c4 04             	add    $0x4,%esp
f01016e4:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016e7:	e8 ba f9 ff ff       	call   f01010a6 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016ec:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f01016f2:	83 c4 10             	add    $0x10,%esp
f01016f5:	85 c0                	test   %eax,%eax
f01016f7:	0f 84 62 02 00 00    	je     f010195f <mem_init+0x5ef>
		--nfree;
f01016fd:	83 6d d0 01          	subl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101701:	8b 00                	mov    (%eax),%eax
f0101703:	eb f0                	jmp    f01016f5 <mem_init+0x385>
	assert((pp0 = page_alloc(0)));
f0101705:	8d 83 86 ca fe ff    	lea    -0x1357a(%ebx),%eax
f010170b:	50                   	push   %eax
f010170c:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0101712:	50                   	push   %eax
f0101713:	68 b5 02 00 00       	push   $0x2b5
f0101718:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010171e:	50                   	push   %eax
f010171f:	e8 79 e9 ff ff       	call   f010009d <_panic>
	assert((pp1 = page_alloc(0)));
f0101724:	8d 83 9c ca fe ff    	lea    -0x13564(%ebx),%eax
f010172a:	50                   	push   %eax
f010172b:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0101731:	50                   	push   %eax
f0101732:	68 b6 02 00 00       	push   $0x2b6
f0101737:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010173d:	50                   	push   %eax
f010173e:	e8 5a e9 ff ff       	call   f010009d <_panic>
	assert((pp2 = page_alloc(0)));
f0101743:	8d 83 b2 ca fe ff    	lea    -0x1354e(%ebx),%eax
f0101749:	50                   	push   %eax
f010174a:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0101750:	50                   	push   %eax
f0101751:	68 b7 02 00 00       	push   $0x2b7
f0101756:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010175c:	50                   	push   %eax
f010175d:	e8 3b e9 ff ff       	call   f010009d <_panic>
	assert(pp1 && pp1 != pp0);
f0101762:	8d 83 c8 ca fe ff    	lea    -0x13538(%ebx),%eax
f0101768:	50                   	push   %eax
f0101769:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f010176f:	50                   	push   %eax
f0101770:	68 ba 02 00 00       	push   $0x2ba
f0101775:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010177b:	50                   	push   %eax
f010177c:	e8 1c e9 ff ff       	call   f010009d <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101781:	8d 83 cc c3 fe ff    	lea    -0x13c34(%ebx),%eax
f0101787:	50                   	push   %eax
f0101788:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f010178e:	50                   	push   %eax
f010178f:	68 bb 02 00 00       	push   $0x2bb
f0101794:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010179a:	50                   	push   %eax
f010179b:	e8 fd e8 ff ff       	call   f010009d <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f01017a0:	8d 83 da ca fe ff    	lea    -0x13526(%ebx),%eax
f01017a6:	50                   	push   %eax
f01017a7:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01017ad:	50                   	push   %eax
f01017ae:	68 bc 02 00 00       	push   $0x2bc
f01017b3:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01017b9:	50                   	push   %eax
f01017ba:	e8 de e8 ff ff       	call   f010009d <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01017bf:	8d 83 f7 ca fe ff    	lea    -0x13509(%ebx),%eax
f01017c5:	50                   	push   %eax
f01017c6:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01017cc:	50                   	push   %eax
f01017cd:	68 bd 02 00 00       	push   $0x2bd
f01017d2:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01017d8:	50                   	push   %eax
f01017d9:	e8 bf e8 ff ff       	call   f010009d <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01017de:	8d 83 14 cb fe ff    	lea    -0x134ec(%ebx),%eax
f01017e4:	50                   	push   %eax
f01017e5:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01017eb:	50                   	push   %eax
f01017ec:	68 be 02 00 00       	push   $0x2be
f01017f1:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01017f7:	50                   	push   %eax
f01017f8:	e8 a0 e8 ff ff       	call   f010009d <_panic>
	assert(!page_alloc(0));
f01017fd:	8d 83 31 cb fe ff    	lea    -0x134cf(%ebx),%eax
f0101803:	50                   	push   %eax
f0101804:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f010180a:	50                   	push   %eax
f010180b:	68 c5 02 00 00       	push   $0x2c5
f0101810:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0101816:	50                   	push   %eax
f0101817:	e8 81 e8 ff ff       	call   f010009d <_panic>
	assert((pp0 = page_alloc(0)));
f010181c:	8d 83 86 ca fe ff    	lea    -0x1357a(%ebx),%eax
f0101822:	50                   	push   %eax
f0101823:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0101829:	50                   	push   %eax
f010182a:	68 cc 02 00 00       	push   $0x2cc
f010182f:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0101835:	50                   	push   %eax
f0101836:	e8 62 e8 ff ff       	call   f010009d <_panic>
	assert((pp1 = page_alloc(0)));
f010183b:	8d 83 9c ca fe ff    	lea    -0x13564(%ebx),%eax
f0101841:	50                   	push   %eax
f0101842:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0101848:	50                   	push   %eax
f0101849:	68 cd 02 00 00       	push   $0x2cd
f010184e:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0101854:	50                   	push   %eax
f0101855:	e8 43 e8 ff ff       	call   f010009d <_panic>
	assert((pp2 = page_alloc(0)));
f010185a:	8d 83 b2 ca fe ff    	lea    -0x1354e(%ebx),%eax
f0101860:	50                   	push   %eax
f0101861:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0101867:	50                   	push   %eax
f0101868:	68 ce 02 00 00       	push   $0x2ce
f010186d:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0101873:	50                   	push   %eax
f0101874:	e8 24 e8 ff ff       	call   f010009d <_panic>
	assert(pp1 && pp1 != pp0);
f0101879:	8d 83 c8 ca fe ff    	lea    -0x13538(%ebx),%eax
f010187f:	50                   	push   %eax
f0101880:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0101886:	50                   	push   %eax
f0101887:	68 d0 02 00 00       	push   $0x2d0
f010188c:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0101892:	50                   	push   %eax
f0101893:	e8 05 e8 ff ff       	call   f010009d <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101898:	8d 83 cc c3 fe ff    	lea    -0x13c34(%ebx),%eax
f010189e:	50                   	push   %eax
f010189f:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01018a5:	50                   	push   %eax
f01018a6:	68 d1 02 00 00       	push   $0x2d1
f01018ab:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01018b1:	50                   	push   %eax
f01018b2:	e8 e6 e7 ff ff       	call   f010009d <_panic>
	assert(!page_alloc(0));
f01018b7:	8d 83 31 cb fe ff    	lea    -0x134cf(%ebx),%eax
f01018bd:	50                   	push   %eax
f01018be:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01018c4:	50                   	push   %eax
f01018c5:	68 d2 02 00 00       	push   $0x2d2
f01018ca:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01018d0:	50                   	push   %eax
f01018d1:	e8 c7 e7 ff ff       	call   f010009d <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018d6:	52                   	push   %edx
f01018d7:	8d 83 f8 c1 fe ff    	lea    -0x13e08(%ebx),%eax
f01018dd:	50                   	push   %eax
f01018de:	6a 52                	push   $0x52
f01018e0:	8d 83 c1 c9 fe ff    	lea    -0x1363f(%ebx),%eax
f01018e6:	50                   	push   %eax
f01018e7:	e8 b1 e7 ff ff       	call   f010009d <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01018ec:	8d 83 40 cb fe ff    	lea    -0x134c0(%ebx),%eax
f01018f2:	50                   	push   %eax
f01018f3:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01018f9:	50                   	push   %eax
f01018fa:	68 d7 02 00 00       	push   $0x2d7
f01018ff:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0101905:	50                   	push   %eax
f0101906:	e8 92 e7 ff ff       	call   f010009d <_panic>
	assert(pp && pp0 == pp);
f010190b:	8d 83 5e cb fe ff    	lea    -0x134a2(%ebx),%eax
f0101911:	50                   	push   %eax
f0101912:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0101918:	50                   	push   %eax
f0101919:	68 d8 02 00 00       	push   $0x2d8
f010191e:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0101924:	50                   	push   %eax
f0101925:	e8 73 e7 ff ff       	call   f010009d <_panic>
f010192a:	52                   	push   %edx
f010192b:	8d 83 f8 c1 fe ff    	lea    -0x13e08(%ebx),%eax
f0101931:	50                   	push   %eax
f0101932:	6a 52                	push   $0x52
f0101934:	8d 83 c1 c9 fe ff    	lea    -0x1363f(%ebx),%eax
f010193a:	50                   	push   %eax
f010193b:	e8 5d e7 ff ff       	call   f010009d <_panic>
		assert(c[i] == 0);
f0101940:	8d 83 6e cb fe ff    	lea    -0x13492(%ebx),%eax
f0101946:	50                   	push   %eax
f0101947:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f010194d:	50                   	push   %eax
f010194e:	68 db 02 00 00       	push   $0x2db
f0101953:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0101959:	50                   	push   %eax
f010195a:	e8 3e e7 ff ff       	call   f010009d <_panic>
	assert(nfree == 0);
f010195f:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101963:	0f 85 47 08 00 00    	jne    f01021b0 <mem_init+0xe40>
	cprintf("check_page_alloc() succeeded!\n");
f0101969:	83 ec 0c             	sub    $0xc,%esp
f010196c:	8d 83 ec c3 fe ff    	lea    -0x13c14(%ebx),%eax
f0101972:	50                   	push   %eax
f0101973:	e8 34 16 00 00       	call   f0102fac <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101978:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010197f:	e8 93 f6 ff ff       	call   f0101017 <page_alloc>
f0101984:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101987:	83 c4 10             	add    $0x10,%esp
f010198a:	85 c0                	test   %eax,%eax
f010198c:	0f 84 3d 08 00 00    	je     f01021cf <mem_init+0xe5f>
	assert((pp1 = page_alloc(0)));
f0101992:	83 ec 0c             	sub    $0xc,%esp
f0101995:	6a 00                	push   $0x0
f0101997:	e8 7b f6 ff ff       	call   f0101017 <page_alloc>
f010199c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010199f:	83 c4 10             	add    $0x10,%esp
f01019a2:	85 c0                	test   %eax,%eax
f01019a4:	0f 84 44 08 00 00    	je     f01021ee <mem_init+0xe7e>
	assert((pp2 = page_alloc(0)));
f01019aa:	83 ec 0c             	sub    $0xc,%esp
f01019ad:	6a 00                	push   $0x0
f01019af:	e8 63 f6 ff ff       	call   f0101017 <page_alloc>
f01019b4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01019b7:	83 c4 10             	add    $0x10,%esp
f01019ba:	85 c0                	test   %eax,%eax
f01019bc:	0f 84 4b 08 00 00    	je     f010220d <mem_init+0xe9d>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019c2:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01019c5:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f01019c8:	0f 84 5e 08 00 00    	je     f010222c <mem_init+0xebc>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019ce:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01019d1:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01019d4:	0f 84 71 08 00 00    	je     f010224b <mem_init+0xedb>
f01019da:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01019dd:	0f 84 68 08 00 00    	je     f010224b <mem_init+0xedb>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01019e3:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f01019e9:	89 45 c8             	mov    %eax,-0x38(%ebp)
	page_free_list = 0;
f01019ec:	c7 83 94 1f 00 00 00 	movl   $0x0,0x1f94(%ebx)
f01019f3:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01019f6:	83 ec 0c             	sub    $0xc,%esp
f01019f9:	6a 00                	push   $0x0
f01019fb:	e8 17 f6 ff ff       	call   f0101017 <page_alloc>
f0101a00:	83 c4 10             	add    $0x10,%esp
f0101a03:	85 c0                	test   %eax,%eax
f0101a05:	0f 85 5f 08 00 00    	jne    f010226a <mem_init+0xefa>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a0b:	83 ec 04             	sub    $0x4,%esp
f0101a0e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a11:	50                   	push   %eax
f0101a12:	6a 00                	push   $0x0
f0101a14:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101a1a:	ff 30                	pushl  (%eax)
f0101a1c:	e8 fc f7 ff ff       	call   f010121d <page_lookup>
f0101a21:	83 c4 10             	add    $0x10,%esp
f0101a24:	85 c0                	test   %eax,%eax
f0101a26:	0f 85 5d 08 00 00    	jne    f0102289 <mem_init+0xf19>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a2c:	6a 02                	push   $0x2
f0101a2e:	6a 00                	push   $0x0
f0101a30:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a33:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101a39:	ff 30                	pushl  (%eax)
f0101a3b:	e8 a2 f8 ff ff       	call   f01012e2 <page_insert>
f0101a40:	83 c4 10             	add    $0x10,%esp
f0101a43:	85 c0                	test   %eax,%eax
f0101a45:	0f 89 5d 08 00 00    	jns    f01022a8 <mem_init+0xf38>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a4b:	83 ec 0c             	sub    $0xc,%esp
f0101a4e:	ff 75 cc             	pushl  -0x34(%ebp)
f0101a51:	e8 50 f6 ff ff       	call   f01010a6 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a56:	6a 02                	push   $0x2
f0101a58:	6a 00                	push   $0x0
f0101a5a:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a5d:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101a63:	ff 30                	pushl  (%eax)
f0101a65:	e8 78 f8 ff ff       	call   f01012e2 <page_insert>
f0101a6a:	83 c4 20             	add    $0x20,%esp
f0101a6d:	85 c0                	test   %eax,%eax
f0101a6f:	0f 85 52 08 00 00    	jne    f01022c7 <mem_init+0xf57>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a75:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101a7b:	8b 30                	mov    (%eax),%esi
	return (pp - pages) << PGSHIFT;
f0101a7d:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0101a83:	8b 38                	mov    (%eax),%edi
f0101a85:	8b 16                	mov    (%esi),%edx
f0101a87:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a8d:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101a90:	29 f8                	sub    %edi,%eax
f0101a92:	c1 f8 03             	sar    $0x3,%eax
f0101a95:	c1 e0 0c             	shl    $0xc,%eax
f0101a98:	39 c2                	cmp    %eax,%edx
f0101a9a:	0f 85 46 08 00 00    	jne    f01022e6 <mem_init+0xf76>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101aa0:	ba 00 00 00 00       	mov    $0x0,%edx
f0101aa5:	89 f0                	mov    %esi,%eax
f0101aa7:	e8 a8 f0 ff ff       	call   f0100b54 <check_va2pa>
f0101aac:	89 c2                	mov    %eax,%edx
f0101aae:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ab1:	29 f8                	sub    %edi,%eax
f0101ab3:	c1 f8 03             	sar    $0x3,%eax
f0101ab6:	c1 e0 0c             	shl    $0xc,%eax
f0101ab9:	39 c2                	cmp    %eax,%edx
f0101abb:	0f 85 44 08 00 00    	jne    f0102305 <mem_init+0xf95>
	assert(pp1->pp_ref == 1);
f0101ac1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ac4:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ac9:	0f 85 55 08 00 00    	jne    f0102324 <mem_init+0xfb4>
	assert(pp0->pp_ref == 1);
f0101acf:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101ad2:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ad7:	0f 85 66 08 00 00    	jne    f0102343 <mem_init+0xfd3>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101add:	6a 02                	push   $0x2
f0101adf:	68 00 10 00 00       	push   $0x1000
f0101ae4:	ff 75 d0             	pushl  -0x30(%ebp)
f0101ae7:	56                   	push   %esi
f0101ae8:	e8 f5 f7 ff ff       	call   f01012e2 <page_insert>
f0101aed:	83 c4 10             	add    $0x10,%esp
f0101af0:	85 c0                	test   %eax,%eax
f0101af2:	0f 85 6a 08 00 00    	jne    f0102362 <mem_init+0xff2>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101af8:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101afd:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101b03:	8b 00                	mov    (%eax),%eax
f0101b05:	e8 4a f0 ff ff       	call   f0100b54 <check_va2pa>
f0101b0a:	89 c2                	mov    %eax,%edx
f0101b0c:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0101b12:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101b15:	2b 08                	sub    (%eax),%ecx
f0101b17:	89 c8                	mov    %ecx,%eax
f0101b19:	c1 f8 03             	sar    $0x3,%eax
f0101b1c:	c1 e0 0c             	shl    $0xc,%eax
f0101b1f:	39 c2                	cmp    %eax,%edx
f0101b21:	0f 85 5a 08 00 00    	jne    f0102381 <mem_init+0x1011>
	assert(pp2->pp_ref == 1);
f0101b27:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b2a:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b2f:	0f 85 6b 08 00 00    	jne    f01023a0 <mem_init+0x1030>

	// should be no free memory
	assert(!page_alloc(0));
f0101b35:	83 ec 0c             	sub    $0xc,%esp
f0101b38:	6a 00                	push   $0x0
f0101b3a:	e8 d8 f4 ff ff       	call   f0101017 <page_alloc>
f0101b3f:	83 c4 10             	add    $0x10,%esp
f0101b42:	85 c0                	test   %eax,%eax
f0101b44:	0f 85 75 08 00 00    	jne    f01023bf <mem_init+0x104f>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b4a:	6a 02                	push   $0x2
f0101b4c:	68 00 10 00 00       	push   $0x1000
f0101b51:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b54:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101b5a:	ff 30                	pushl  (%eax)
f0101b5c:	e8 81 f7 ff ff       	call   f01012e2 <page_insert>
f0101b61:	83 c4 10             	add    $0x10,%esp
f0101b64:	85 c0                	test   %eax,%eax
f0101b66:	0f 85 72 08 00 00    	jne    f01023de <mem_init+0x106e>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b6c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b71:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101b77:	8b 00                	mov    (%eax),%eax
f0101b79:	e8 d6 ef ff ff       	call   f0100b54 <check_va2pa>
f0101b7e:	89 c2                	mov    %eax,%edx
f0101b80:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0101b86:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101b89:	2b 08                	sub    (%eax),%ecx
f0101b8b:	89 c8                	mov    %ecx,%eax
f0101b8d:	c1 f8 03             	sar    $0x3,%eax
f0101b90:	c1 e0 0c             	shl    $0xc,%eax
f0101b93:	39 c2                	cmp    %eax,%edx
f0101b95:	0f 85 62 08 00 00    	jne    f01023fd <mem_init+0x108d>
	assert(pp2->pp_ref == 1);
f0101b9b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b9e:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ba3:	0f 85 73 08 00 00    	jne    f010241c <mem_init+0x10ac>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101ba9:	83 ec 0c             	sub    $0xc,%esp
f0101bac:	6a 00                	push   $0x0
f0101bae:	e8 64 f4 ff ff       	call   f0101017 <page_alloc>
f0101bb3:	83 c4 10             	add    $0x10,%esp
f0101bb6:	85 c0                	test   %eax,%eax
f0101bb8:	0f 85 7d 08 00 00    	jne    f010243b <mem_init+0x10cb>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101bbe:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101bc4:	8b 08                	mov    (%eax),%ecx
f0101bc6:	8b 01                	mov    (%ecx),%eax
f0101bc8:	89 c2                	mov    %eax,%edx
f0101bca:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101bd0:	c1 e8 0c             	shr    $0xc,%eax
f0101bd3:	c7 c6 c8 a6 11 f0    	mov    $0xf011a6c8,%esi
f0101bd9:	3b 06                	cmp    (%esi),%eax
f0101bdb:	0f 83 79 08 00 00    	jae    f010245a <mem_init+0x10ea>
	return (void *)(pa + KERNBASE);
f0101be1:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101be7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101bea:	83 ec 04             	sub    $0x4,%esp
f0101bed:	6a 00                	push   $0x0
f0101bef:	68 00 10 00 00       	push   $0x1000
f0101bf4:	51                   	push   %ecx
f0101bf5:	e8 2c f5 ff ff       	call   f0101126 <pgdir_walk>
f0101bfa:	89 c2                	mov    %eax,%edx
f0101bfc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101bff:	83 c0 04             	add    $0x4,%eax
f0101c02:	83 c4 10             	add    $0x10,%esp
f0101c05:	39 d0                	cmp    %edx,%eax
f0101c07:	0f 85 66 08 00 00    	jne    f0102473 <mem_init+0x1103>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c0d:	6a 06                	push   $0x6
f0101c0f:	68 00 10 00 00       	push   $0x1000
f0101c14:	ff 75 d0             	pushl  -0x30(%ebp)
f0101c17:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101c1d:	ff 30                	pushl  (%eax)
f0101c1f:	e8 be f6 ff ff       	call   f01012e2 <page_insert>
f0101c24:	83 c4 10             	add    $0x10,%esp
f0101c27:	85 c0                	test   %eax,%eax
f0101c29:	0f 85 63 08 00 00    	jne    f0102492 <mem_init+0x1122>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c2f:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101c35:	8b 30                	mov    (%eax),%esi
f0101c37:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c3c:	89 f0                	mov    %esi,%eax
f0101c3e:	e8 11 ef ff ff       	call   f0100b54 <check_va2pa>
f0101c43:	89 c2                	mov    %eax,%edx
	return (pp - pages) << PGSHIFT;
f0101c45:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0101c4b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101c4e:	2b 08                	sub    (%eax),%ecx
f0101c50:	89 c8                	mov    %ecx,%eax
f0101c52:	c1 f8 03             	sar    $0x3,%eax
f0101c55:	c1 e0 0c             	shl    $0xc,%eax
f0101c58:	39 c2                	cmp    %eax,%edx
f0101c5a:	0f 85 51 08 00 00    	jne    f01024b1 <mem_init+0x1141>
	assert(pp2->pp_ref == 1);
f0101c60:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c63:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c68:	0f 85 62 08 00 00    	jne    f01024d0 <mem_init+0x1160>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101c6e:	83 ec 04             	sub    $0x4,%esp
f0101c71:	6a 00                	push   $0x0
f0101c73:	68 00 10 00 00       	push   $0x1000
f0101c78:	56                   	push   %esi
f0101c79:	e8 a8 f4 ff ff       	call   f0101126 <pgdir_walk>
f0101c7e:	83 c4 10             	add    $0x10,%esp
f0101c81:	f6 00 04             	testb  $0x4,(%eax)
f0101c84:	0f 84 65 08 00 00    	je     f01024ef <mem_init+0x117f>
	assert(kern_pgdir[0] & PTE_U);
f0101c8a:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101c90:	8b 00                	mov    (%eax),%eax
f0101c92:	f6 00 04             	testb  $0x4,(%eax)
f0101c95:	0f 84 73 08 00 00    	je     f010250e <mem_init+0x119e>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c9b:	6a 02                	push   $0x2
f0101c9d:	68 00 10 00 00       	push   $0x1000
f0101ca2:	ff 75 d0             	pushl  -0x30(%ebp)
f0101ca5:	50                   	push   %eax
f0101ca6:	e8 37 f6 ff ff       	call   f01012e2 <page_insert>
f0101cab:	83 c4 10             	add    $0x10,%esp
f0101cae:	85 c0                	test   %eax,%eax
f0101cb0:	0f 85 77 08 00 00    	jne    f010252d <mem_init+0x11bd>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101cb6:	83 ec 04             	sub    $0x4,%esp
f0101cb9:	6a 00                	push   $0x0
f0101cbb:	68 00 10 00 00       	push   $0x1000
f0101cc0:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101cc6:	ff 30                	pushl  (%eax)
f0101cc8:	e8 59 f4 ff ff       	call   f0101126 <pgdir_walk>
f0101ccd:	83 c4 10             	add    $0x10,%esp
f0101cd0:	f6 00 02             	testb  $0x2,(%eax)
f0101cd3:	0f 84 73 08 00 00    	je     f010254c <mem_init+0x11dc>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101cd9:	83 ec 04             	sub    $0x4,%esp
f0101cdc:	6a 00                	push   $0x0
f0101cde:	68 00 10 00 00       	push   $0x1000
f0101ce3:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101ce9:	ff 30                	pushl  (%eax)
f0101ceb:	e8 36 f4 ff ff       	call   f0101126 <pgdir_walk>
f0101cf0:	83 c4 10             	add    $0x10,%esp
f0101cf3:	f6 00 04             	testb  $0x4,(%eax)
f0101cf6:	0f 85 6f 08 00 00    	jne    f010256b <mem_init+0x11fb>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101cfc:	6a 02                	push   $0x2
f0101cfe:	68 00 00 40 00       	push   $0x400000
f0101d03:	ff 75 cc             	pushl  -0x34(%ebp)
f0101d06:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101d0c:	ff 30                	pushl  (%eax)
f0101d0e:	e8 cf f5 ff ff       	call   f01012e2 <page_insert>
f0101d13:	83 c4 10             	add    $0x10,%esp
f0101d16:	85 c0                	test   %eax,%eax
f0101d18:	0f 89 6c 08 00 00    	jns    f010258a <mem_init+0x121a>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d1e:	6a 02                	push   $0x2
f0101d20:	68 00 10 00 00       	push   $0x1000
f0101d25:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101d28:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101d2e:	ff 30                	pushl  (%eax)
f0101d30:	e8 ad f5 ff ff       	call   f01012e2 <page_insert>
f0101d35:	83 c4 10             	add    $0x10,%esp
f0101d38:	85 c0                	test   %eax,%eax
f0101d3a:	0f 85 69 08 00 00    	jne    f01025a9 <mem_init+0x1239>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d40:	83 ec 04             	sub    $0x4,%esp
f0101d43:	6a 00                	push   $0x0
f0101d45:	68 00 10 00 00       	push   $0x1000
f0101d4a:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101d50:	ff 30                	pushl  (%eax)
f0101d52:	e8 cf f3 ff ff       	call   f0101126 <pgdir_walk>
f0101d57:	83 c4 10             	add    $0x10,%esp
f0101d5a:	f6 00 04             	testb  $0x4,(%eax)
f0101d5d:	0f 85 65 08 00 00    	jne    f01025c8 <mem_init+0x1258>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d63:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101d69:	8b 38                	mov    (%eax),%edi
f0101d6b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d70:	89 f8                	mov    %edi,%eax
f0101d72:	e8 dd ed ff ff       	call   f0100b54 <check_va2pa>
f0101d77:	c7 c2 d0 a6 11 f0    	mov    $0xf011a6d0,%edx
f0101d7d:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101d80:	2b 32                	sub    (%edx),%esi
f0101d82:	c1 fe 03             	sar    $0x3,%esi
f0101d85:	c1 e6 0c             	shl    $0xc,%esi
f0101d88:	39 f0                	cmp    %esi,%eax
f0101d8a:	0f 85 57 08 00 00    	jne    f01025e7 <mem_init+0x1277>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d90:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d95:	89 f8                	mov    %edi,%eax
f0101d97:	e8 b8 ed ff ff       	call   f0100b54 <check_va2pa>
f0101d9c:	39 c6                	cmp    %eax,%esi
f0101d9e:	0f 85 62 08 00 00    	jne    f0102606 <mem_init+0x1296>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101da4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101da7:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f0101dac:	0f 85 73 08 00 00    	jne    f0102625 <mem_init+0x12b5>
	assert(pp2->pp_ref == 0);
f0101db2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101db5:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101dba:	0f 85 84 08 00 00    	jne    f0102644 <mem_init+0x12d4>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101dc0:	83 ec 0c             	sub    $0xc,%esp
f0101dc3:	6a 00                	push   $0x0
f0101dc5:	e8 4d f2 ff ff       	call   f0101017 <page_alloc>
f0101dca:	83 c4 10             	add    $0x10,%esp
f0101dcd:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101dd0:	0f 85 8d 08 00 00    	jne    f0102663 <mem_init+0x12f3>
f0101dd6:	85 c0                	test   %eax,%eax
f0101dd8:	0f 84 85 08 00 00    	je     f0102663 <mem_init+0x12f3>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101dde:	83 ec 08             	sub    $0x8,%esp
f0101de1:	6a 00                	push   $0x0
f0101de3:	c7 c6 cc a6 11 f0    	mov    $0xf011a6cc,%esi
f0101de9:	ff 36                	pushl  (%esi)
f0101deb:	e8 ac f4 ff ff       	call   f010129c <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101df0:	8b 36                	mov    (%esi),%esi
f0101df2:	ba 00 00 00 00       	mov    $0x0,%edx
f0101df7:	89 f0                	mov    %esi,%eax
f0101df9:	e8 56 ed ff ff       	call   f0100b54 <check_va2pa>
f0101dfe:	83 c4 10             	add    $0x10,%esp
f0101e01:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e04:	0f 85 78 08 00 00    	jne    f0102682 <mem_init+0x1312>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e0a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e0f:	89 f0                	mov    %esi,%eax
f0101e11:	e8 3e ed ff ff       	call   f0100b54 <check_va2pa>
f0101e16:	89 c2                	mov    %eax,%edx
f0101e18:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0101e1e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101e21:	2b 08                	sub    (%eax),%ecx
f0101e23:	89 c8                	mov    %ecx,%eax
f0101e25:	c1 f8 03             	sar    $0x3,%eax
f0101e28:	c1 e0 0c             	shl    $0xc,%eax
f0101e2b:	39 c2                	cmp    %eax,%edx
f0101e2d:	0f 85 6e 08 00 00    	jne    f01026a1 <mem_init+0x1331>
	assert(pp1->pp_ref == 1);
f0101e33:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e36:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e3b:	0f 85 7f 08 00 00    	jne    f01026c0 <mem_init+0x1350>
	assert(pp2->pp_ref == 0);
f0101e41:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101e44:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e49:	0f 85 90 08 00 00    	jne    f01026df <mem_init+0x136f>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101e4f:	6a 00                	push   $0x0
f0101e51:	68 00 10 00 00       	push   $0x1000
f0101e56:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101e59:	56                   	push   %esi
f0101e5a:	e8 83 f4 ff ff       	call   f01012e2 <page_insert>
f0101e5f:	83 c4 10             	add    $0x10,%esp
f0101e62:	85 c0                	test   %eax,%eax
f0101e64:	0f 85 94 08 00 00    	jne    f01026fe <mem_init+0x138e>
	assert(pp1->pp_ref);
f0101e6a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e6d:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e72:	0f 84 a5 08 00 00    	je     f010271d <mem_init+0x13ad>
	assert(pp1->pp_link == NULL);
f0101e78:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e7b:	83 38 00             	cmpl   $0x0,(%eax)
f0101e7e:	0f 85 b8 08 00 00    	jne    f010273c <mem_init+0x13cc>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e84:	83 ec 08             	sub    $0x8,%esp
f0101e87:	68 00 10 00 00       	push   $0x1000
f0101e8c:	c7 c6 cc a6 11 f0    	mov    $0xf011a6cc,%esi
f0101e92:	ff 36                	pushl  (%esi)
f0101e94:	e8 03 f4 ff ff       	call   f010129c <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e99:	8b 36                	mov    (%esi),%esi
f0101e9b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ea0:	89 f0                	mov    %esi,%eax
f0101ea2:	e8 ad ec ff ff       	call   f0100b54 <check_va2pa>
f0101ea7:	83 c4 10             	add    $0x10,%esp
f0101eaa:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ead:	0f 85 a8 08 00 00    	jne    f010275b <mem_init+0x13eb>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101eb3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101eb8:	89 f0                	mov    %esi,%eax
f0101eba:	e8 95 ec ff ff       	call   f0100b54 <check_va2pa>
f0101ebf:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ec2:	0f 85 b2 08 00 00    	jne    f010277a <mem_init+0x140a>
	assert(pp1->pp_ref == 0);
f0101ec8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ecb:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101ed0:	0f 85 c3 08 00 00    	jne    f0102799 <mem_init+0x1429>
	assert(pp2->pp_ref == 0);
f0101ed6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101ed9:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101ede:	0f 85 d4 08 00 00    	jne    f01027b8 <mem_init+0x1448>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ee4:	83 ec 0c             	sub    $0xc,%esp
f0101ee7:	6a 00                	push   $0x0
f0101ee9:	e8 29 f1 ff ff       	call   f0101017 <page_alloc>
f0101eee:	83 c4 10             	add    $0x10,%esp
f0101ef1:	85 c0                	test   %eax,%eax
f0101ef3:	0f 84 de 08 00 00    	je     f01027d7 <mem_init+0x1467>
f0101ef9:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101efc:	0f 85 d5 08 00 00    	jne    f01027d7 <mem_init+0x1467>

	// should be no free memory
	assert(!page_alloc(0));
f0101f02:	83 ec 0c             	sub    $0xc,%esp
f0101f05:	6a 00                	push   $0x0
f0101f07:	e8 0b f1 ff ff       	call   f0101017 <page_alloc>
f0101f0c:	83 c4 10             	add    $0x10,%esp
f0101f0f:	85 c0                	test   %eax,%eax
f0101f11:	0f 85 df 08 00 00    	jne    f01027f6 <mem_init+0x1486>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f17:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101f1d:	8b 08                	mov    (%eax),%ecx
f0101f1f:	8b 11                	mov    (%ecx),%edx
f0101f21:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f27:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0101f2d:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0101f30:	2b 38                	sub    (%eax),%edi
f0101f32:	89 f8                	mov    %edi,%eax
f0101f34:	c1 f8 03             	sar    $0x3,%eax
f0101f37:	c1 e0 0c             	shl    $0xc,%eax
f0101f3a:	39 c2                	cmp    %eax,%edx
f0101f3c:	0f 85 d3 08 00 00    	jne    f0102815 <mem_init+0x14a5>
	kern_pgdir[0] = 0;
f0101f42:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f48:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f4b:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f50:	0f 85 de 08 00 00    	jne    f0102834 <mem_init+0x14c4>
	pp0->pp_ref = 0;
f0101f56:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f59:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f5f:	83 ec 0c             	sub    $0xc,%esp
f0101f62:	50                   	push   %eax
f0101f63:	e8 3e f1 ff ff       	call   f01010a6 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f68:	83 c4 0c             	add    $0xc,%esp
f0101f6b:	6a 01                	push   $0x1
f0101f6d:	68 00 10 40 00       	push   $0x401000
f0101f72:	c7 c6 cc a6 11 f0    	mov    $0xf011a6cc,%esi
f0101f78:	ff 36                	pushl  (%esi)
f0101f7a:	e8 a7 f1 ff ff       	call   f0101126 <pgdir_walk>
f0101f7f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f82:	8b 3e                	mov    (%esi),%edi
f0101f84:	8b 57 04             	mov    0x4(%edi),%edx
f0101f87:	89 d1                	mov    %edx,%ecx
f0101f89:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	if (PGNUM(pa) >= npages)
f0101f8f:	c7 c6 c8 a6 11 f0    	mov    $0xf011a6c8,%esi
f0101f95:	8b 36                	mov    (%esi),%esi
f0101f97:	c1 ea 0c             	shr    $0xc,%edx
f0101f9a:	83 c4 10             	add    $0x10,%esp
f0101f9d:	39 f2                	cmp    %esi,%edx
f0101f9f:	0f 83 ae 08 00 00    	jae    f0102853 <mem_init+0x14e3>
	assert(ptep == ptep1 + PTX(va));
f0101fa5:	81 e9 fc ff ff 0f    	sub    $0xffffffc,%ecx
f0101fab:	39 c8                	cmp    %ecx,%eax
f0101fad:	0f 85 b9 08 00 00    	jne    f010286c <mem_init+0x14fc>
	kern_pgdir[PDX(va)] = 0;
f0101fb3:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	pp0->pp_ref = 0;
f0101fba:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101fbd:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
	return (pp - pages) << PGSHIFT;
f0101fc3:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0101fc9:	2b 08                	sub    (%eax),%ecx
f0101fcb:	89 c8                	mov    %ecx,%eax
f0101fcd:	c1 f8 03             	sar    $0x3,%eax
f0101fd0:	89 c2                	mov    %eax,%edx
f0101fd2:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101fd5:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101fda:	39 c6                	cmp    %eax,%esi
f0101fdc:	0f 86 a9 08 00 00    	jbe    f010288b <mem_init+0x151b>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101fe2:	83 ec 04             	sub    $0x4,%esp
f0101fe5:	68 00 10 00 00       	push   $0x1000
f0101fea:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0101fef:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101ff5:	52                   	push   %edx
f0101ff6:	e8 b6 1b 00 00       	call   f0103bb1 <memset>
	page_free(pp0);
f0101ffb:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0101ffe:	89 3c 24             	mov    %edi,(%esp)
f0102001:	e8 a0 f0 ff ff       	call   f01010a6 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102006:	83 c4 0c             	add    $0xc,%esp
f0102009:	6a 01                	push   $0x1
f010200b:	6a 00                	push   $0x0
f010200d:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102013:	ff 30                	pushl  (%eax)
f0102015:	e8 0c f1 ff ff       	call   f0101126 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f010201a:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0102020:	2b 38                	sub    (%eax),%edi
f0102022:	89 f8                	mov    %edi,%eax
f0102024:	c1 f8 03             	sar    $0x3,%eax
f0102027:	89 c2                	mov    %eax,%edx
f0102029:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010202c:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102031:	83 c4 10             	add    $0x10,%esp
f0102034:	c7 c1 c8 a6 11 f0    	mov    $0xf011a6c8,%ecx
f010203a:	3b 01                	cmp    (%ecx),%eax
f010203c:	0f 83 5f 08 00 00    	jae    f01028a1 <mem_init+0x1531>
	return (void *)(pa + KERNBASE);
f0102042:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102048:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010204b:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102051:	8b 38                	mov    (%eax),%edi
f0102053:	83 e7 01             	and    $0x1,%edi
f0102056:	0f 85 5b 08 00 00    	jne    f01028b7 <mem_init+0x1547>
f010205c:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f010205f:	39 d0                	cmp    %edx,%eax
f0102061:	75 ee                	jne    f0102051 <mem_init+0xce1>
	kern_pgdir[0] = 0;
f0102063:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102069:	8b 00                	mov    (%eax),%eax
f010206b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102071:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102074:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010207a:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f010207d:	89 8b 94 1f 00 00    	mov    %ecx,0x1f94(%ebx)

	// free the pages we took
	page_free(pp0);
f0102083:	83 ec 0c             	sub    $0xc,%esp
f0102086:	50                   	push   %eax
f0102087:	e8 1a f0 ff ff       	call   f01010a6 <page_free>
	page_free(pp1);
f010208c:	83 c4 04             	add    $0x4,%esp
f010208f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102092:	e8 0f f0 ff ff       	call   f01010a6 <page_free>
	page_free(pp2);
f0102097:	83 c4 04             	add    $0x4,%esp
f010209a:	ff 75 d0             	pushl  -0x30(%ebp)
f010209d:	e8 04 f0 ff ff       	call   f01010a6 <page_free>

	cprintf("check_page() succeeded!\n");
f01020a2:	8d 83 4f cc fe ff    	lea    -0x133b1(%ebx),%eax
f01020a8:	89 04 24             	mov    %eax,(%esp)
f01020ab:	e8 fc 0e 00 00       	call   f0102fac <cprintf>
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U);
f01020b0:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f01020b6:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01020b8:	83 c4 10             	add    $0x10,%esp
f01020bb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020c0:	0f 86 10 08 00 00    	jbe    f01028d6 <mem_init+0x1566>
f01020c6:	83 ec 08             	sub    $0x8,%esp
f01020c9:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f01020cb:	05 00 00 00 10       	add    $0x10000000,%eax
f01020d0:	50                   	push   %eax
f01020d1:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020d6:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01020db:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f01020e1:	8b 00                	mov    (%eax),%eax
f01020e3:	e8 e9 f0 ff ff       	call   f01011d1 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f01020e8:	c7 c0 00 f0 10 f0    	mov    $0xf010f000,%eax
f01020ee:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01020f1:	83 c4 10             	add    $0x10,%esp
f01020f4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020f9:	0f 86 f0 07 00 00    	jbe    f01028ef <mem_init+0x157f>
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f01020ff:	c7 c6 cc a6 11 f0    	mov    $0xf011a6cc,%esi
f0102105:	83 ec 08             	sub    $0x8,%esp
f0102108:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f010210a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010210d:	05 00 00 00 10       	add    $0x10000000,%eax
f0102112:	50                   	push   %eax
f0102113:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102118:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010211d:	8b 06                	mov    (%esi),%eax
f010211f:	e8 ad f0 ff ff       	call   f01011d1 <boot_map_region>
	boot_map_region(kern_pgdir,KERNBASE,0xFFFFFFFF-KERNBASE,0,PTE_W);
f0102124:	83 c4 08             	add    $0x8,%esp
f0102127:	6a 02                	push   $0x2
f0102129:	6a 00                	push   $0x0
f010212b:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102130:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102135:	8b 06                	mov    (%esi),%eax
f0102137:	e8 95 f0 ff ff       	call   f01011d1 <boot_map_region>
	pgdir = kern_pgdir;
f010213c:	8b 06                	mov    (%esi),%eax
f010213e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102141:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f0102147:	8b 00                	mov    (%eax),%eax
f0102149:	89 45 c0             	mov    %eax,-0x40(%ebp)
f010214c:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102153:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102158:	89 45 cc             	mov    %eax,-0x34(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010215b:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0102161:	8b 00                	mov    (%eax),%eax
f0102163:	89 45 bc             	mov    %eax,-0x44(%ebp)
	if ((uint32_t)kva < KERNBASE)
f0102166:	89 45 c8             	mov    %eax,-0x38(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0102169:	05 00 00 00 10       	add    $0x10000000,%eax
f010216e:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f0102171:	83 c4 10             	add    $0x10,%esp
f0102174:	89 fe                	mov    %edi,%esi
f0102176:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0102179:	0f 86 c3 07 00 00    	jbe    f0102942 <mem_init+0x15d2>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010217f:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0102185:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102188:	e8 c7 e9 ff ff       	call   f0100b54 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f010218d:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f0102194:	0f 86 6e 07 00 00    	jbe    f0102908 <mem_init+0x1598>
f010219a:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f010219d:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01021a0:	39 d0                	cmp    %edx,%eax
f01021a2:	0f 85 7b 07 00 00    	jne    f0102923 <mem_init+0x15b3>
	for (i = 0; i < n; i += PGSIZE)
f01021a8:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01021ae:	eb c6                	jmp    f0102176 <mem_init+0xe06>
	assert(nfree == 0);
f01021b0:	8d 83 78 cb fe ff    	lea    -0x13488(%ebx),%eax
f01021b6:	50                   	push   %eax
f01021b7:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01021bd:	50                   	push   %eax
f01021be:	68 e8 02 00 00       	push   $0x2e8
f01021c3:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01021c9:	50                   	push   %eax
f01021ca:	e8 ce de ff ff       	call   f010009d <_panic>
	assert((pp0 = page_alloc(0)));
f01021cf:	8d 83 86 ca fe ff    	lea    -0x1357a(%ebx),%eax
f01021d5:	50                   	push   %eax
f01021d6:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01021dc:	50                   	push   %eax
f01021dd:	68 41 03 00 00       	push   $0x341
f01021e2:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01021e8:	50                   	push   %eax
f01021e9:	e8 af de ff ff       	call   f010009d <_panic>
	assert((pp1 = page_alloc(0)));
f01021ee:	8d 83 9c ca fe ff    	lea    -0x13564(%ebx),%eax
f01021f4:	50                   	push   %eax
f01021f5:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01021fb:	50                   	push   %eax
f01021fc:	68 42 03 00 00       	push   $0x342
f0102201:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102207:	50                   	push   %eax
f0102208:	e8 90 de ff ff       	call   f010009d <_panic>
	assert((pp2 = page_alloc(0)));
f010220d:	8d 83 b2 ca fe ff    	lea    -0x1354e(%ebx),%eax
f0102213:	50                   	push   %eax
f0102214:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f010221a:	50                   	push   %eax
f010221b:	68 43 03 00 00       	push   $0x343
f0102220:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102226:	50                   	push   %eax
f0102227:	e8 71 de ff ff       	call   f010009d <_panic>
	assert(pp1 && pp1 != pp0);
f010222c:	8d 83 c8 ca fe ff    	lea    -0x13538(%ebx),%eax
f0102232:	50                   	push   %eax
f0102233:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102239:	50                   	push   %eax
f010223a:	68 46 03 00 00       	push   $0x346
f010223f:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102245:	50                   	push   %eax
f0102246:	e8 52 de ff ff       	call   f010009d <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010224b:	8d 83 cc c3 fe ff    	lea    -0x13c34(%ebx),%eax
f0102251:	50                   	push   %eax
f0102252:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102258:	50                   	push   %eax
f0102259:	68 47 03 00 00       	push   $0x347
f010225e:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102264:	50                   	push   %eax
f0102265:	e8 33 de ff ff       	call   f010009d <_panic>
	assert(!page_alloc(0));
f010226a:	8d 83 31 cb fe ff    	lea    -0x134cf(%ebx),%eax
f0102270:	50                   	push   %eax
f0102271:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102277:	50                   	push   %eax
f0102278:	68 4e 03 00 00       	push   $0x34e
f010227d:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102283:	50                   	push   %eax
f0102284:	e8 14 de ff ff       	call   f010009d <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102289:	8d 83 0c c4 fe ff    	lea    -0x13bf4(%ebx),%eax
f010228f:	50                   	push   %eax
f0102290:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102296:	50                   	push   %eax
f0102297:	68 51 03 00 00       	push   $0x351
f010229c:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01022a2:	50                   	push   %eax
f01022a3:	e8 f5 dd ff ff       	call   f010009d <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01022a8:	8d 83 44 c4 fe ff    	lea    -0x13bbc(%ebx),%eax
f01022ae:	50                   	push   %eax
f01022af:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01022b5:	50                   	push   %eax
f01022b6:	68 54 03 00 00       	push   $0x354
f01022bb:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01022c1:	50                   	push   %eax
f01022c2:	e8 d6 dd ff ff       	call   f010009d <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01022c7:	8d 83 74 c4 fe ff    	lea    -0x13b8c(%ebx),%eax
f01022cd:	50                   	push   %eax
f01022ce:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01022d4:	50                   	push   %eax
f01022d5:	68 58 03 00 00       	push   $0x358
f01022da:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01022e0:	50                   	push   %eax
f01022e1:	e8 b7 dd ff ff       	call   f010009d <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01022e6:	8d 83 a4 c4 fe ff    	lea    -0x13b5c(%ebx),%eax
f01022ec:	50                   	push   %eax
f01022ed:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01022f3:	50                   	push   %eax
f01022f4:	68 59 03 00 00       	push   $0x359
f01022f9:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01022ff:	50                   	push   %eax
f0102300:	e8 98 dd ff ff       	call   f010009d <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0102305:	8d 83 cc c4 fe ff    	lea    -0x13b34(%ebx),%eax
f010230b:	50                   	push   %eax
f010230c:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102312:	50                   	push   %eax
f0102313:	68 5a 03 00 00       	push   $0x35a
f0102318:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010231e:	50                   	push   %eax
f010231f:	e8 79 dd ff ff       	call   f010009d <_panic>
	assert(pp1->pp_ref == 1);
f0102324:	8d 83 83 cb fe ff    	lea    -0x1347d(%ebx),%eax
f010232a:	50                   	push   %eax
f010232b:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102331:	50                   	push   %eax
f0102332:	68 5b 03 00 00       	push   $0x35b
f0102337:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010233d:	50                   	push   %eax
f010233e:	e8 5a dd ff ff       	call   f010009d <_panic>
	assert(pp0->pp_ref == 1);
f0102343:	8d 83 94 cb fe ff    	lea    -0x1346c(%ebx),%eax
f0102349:	50                   	push   %eax
f010234a:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102350:	50                   	push   %eax
f0102351:	68 5c 03 00 00       	push   $0x35c
f0102356:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010235c:	50                   	push   %eax
f010235d:	e8 3b dd ff ff       	call   f010009d <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102362:	8d 83 fc c4 fe ff    	lea    -0x13b04(%ebx),%eax
f0102368:	50                   	push   %eax
f0102369:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f010236f:	50                   	push   %eax
f0102370:	68 5f 03 00 00       	push   $0x35f
f0102375:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010237b:	50                   	push   %eax
f010237c:	e8 1c dd ff ff       	call   f010009d <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102381:	8d 83 38 c5 fe ff    	lea    -0x13ac8(%ebx),%eax
f0102387:	50                   	push   %eax
f0102388:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f010238e:	50                   	push   %eax
f010238f:	68 60 03 00 00       	push   $0x360
f0102394:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010239a:	50                   	push   %eax
f010239b:	e8 fd dc ff ff       	call   f010009d <_panic>
	assert(pp2->pp_ref == 1);
f01023a0:	8d 83 a5 cb fe ff    	lea    -0x1345b(%ebx),%eax
f01023a6:	50                   	push   %eax
f01023a7:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01023ad:	50                   	push   %eax
f01023ae:	68 61 03 00 00       	push   $0x361
f01023b3:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01023b9:	50                   	push   %eax
f01023ba:	e8 de dc ff ff       	call   f010009d <_panic>
	assert(!page_alloc(0));
f01023bf:	8d 83 31 cb fe ff    	lea    -0x134cf(%ebx),%eax
f01023c5:	50                   	push   %eax
f01023c6:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01023cc:	50                   	push   %eax
f01023cd:	68 64 03 00 00       	push   $0x364
f01023d2:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01023d8:	50                   	push   %eax
f01023d9:	e8 bf dc ff ff       	call   f010009d <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023de:	8d 83 fc c4 fe ff    	lea    -0x13b04(%ebx),%eax
f01023e4:	50                   	push   %eax
f01023e5:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01023eb:	50                   	push   %eax
f01023ec:	68 67 03 00 00       	push   $0x367
f01023f1:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01023f7:	50                   	push   %eax
f01023f8:	e8 a0 dc ff ff       	call   f010009d <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01023fd:	8d 83 38 c5 fe ff    	lea    -0x13ac8(%ebx),%eax
f0102403:	50                   	push   %eax
f0102404:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f010240a:	50                   	push   %eax
f010240b:	68 68 03 00 00       	push   $0x368
f0102410:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102416:	50                   	push   %eax
f0102417:	e8 81 dc ff ff       	call   f010009d <_panic>
	assert(pp2->pp_ref == 1);
f010241c:	8d 83 a5 cb fe ff    	lea    -0x1345b(%ebx),%eax
f0102422:	50                   	push   %eax
f0102423:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102429:	50                   	push   %eax
f010242a:	68 69 03 00 00       	push   $0x369
f010242f:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102435:	50                   	push   %eax
f0102436:	e8 62 dc ff ff       	call   f010009d <_panic>
	assert(!page_alloc(0));
f010243b:	8d 83 31 cb fe ff    	lea    -0x134cf(%ebx),%eax
f0102441:	50                   	push   %eax
f0102442:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102448:	50                   	push   %eax
f0102449:	68 6d 03 00 00       	push   $0x36d
f010244e:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102454:	50                   	push   %eax
f0102455:	e8 43 dc ff ff       	call   f010009d <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010245a:	52                   	push   %edx
f010245b:	8d 83 f8 c1 fe ff    	lea    -0x13e08(%ebx),%eax
f0102461:	50                   	push   %eax
f0102462:	68 70 03 00 00       	push   $0x370
f0102467:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010246d:	50                   	push   %eax
f010246e:	e8 2a dc ff ff       	call   f010009d <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102473:	8d 83 68 c5 fe ff    	lea    -0x13a98(%ebx),%eax
f0102479:	50                   	push   %eax
f010247a:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102480:	50                   	push   %eax
f0102481:	68 71 03 00 00       	push   $0x371
f0102486:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010248c:	50                   	push   %eax
f010248d:	e8 0b dc ff ff       	call   f010009d <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102492:	8d 83 a8 c5 fe ff    	lea    -0x13a58(%ebx),%eax
f0102498:	50                   	push   %eax
f0102499:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f010249f:	50                   	push   %eax
f01024a0:	68 74 03 00 00       	push   $0x374
f01024a5:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01024ab:	50                   	push   %eax
f01024ac:	e8 ec db ff ff       	call   f010009d <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01024b1:	8d 83 38 c5 fe ff    	lea    -0x13ac8(%ebx),%eax
f01024b7:	50                   	push   %eax
f01024b8:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01024be:	50                   	push   %eax
f01024bf:	68 75 03 00 00       	push   $0x375
f01024c4:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01024ca:	50                   	push   %eax
f01024cb:	e8 cd db ff ff       	call   f010009d <_panic>
	assert(pp2->pp_ref == 1);
f01024d0:	8d 83 a5 cb fe ff    	lea    -0x1345b(%ebx),%eax
f01024d6:	50                   	push   %eax
f01024d7:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01024dd:	50                   	push   %eax
f01024de:	68 76 03 00 00       	push   $0x376
f01024e3:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01024e9:	50                   	push   %eax
f01024ea:	e8 ae db ff ff       	call   f010009d <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01024ef:	8d 83 e8 c5 fe ff    	lea    -0x13a18(%ebx),%eax
f01024f5:	50                   	push   %eax
f01024f6:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01024fc:	50                   	push   %eax
f01024fd:	68 77 03 00 00       	push   $0x377
f0102502:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102508:	50                   	push   %eax
f0102509:	e8 8f db ff ff       	call   f010009d <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010250e:	8d 83 b6 cb fe ff    	lea    -0x1344a(%ebx),%eax
f0102514:	50                   	push   %eax
f0102515:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f010251b:	50                   	push   %eax
f010251c:	68 78 03 00 00       	push   $0x378
f0102521:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102527:	50                   	push   %eax
f0102528:	e8 70 db ff ff       	call   f010009d <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010252d:	8d 83 fc c4 fe ff    	lea    -0x13b04(%ebx),%eax
f0102533:	50                   	push   %eax
f0102534:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f010253a:	50                   	push   %eax
f010253b:	68 7b 03 00 00       	push   $0x37b
f0102540:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102546:	50                   	push   %eax
f0102547:	e8 51 db ff ff       	call   f010009d <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010254c:	8d 83 1c c6 fe ff    	lea    -0x139e4(%ebx),%eax
f0102552:	50                   	push   %eax
f0102553:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102559:	50                   	push   %eax
f010255a:	68 7c 03 00 00       	push   $0x37c
f010255f:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102565:	50                   	push   %eax
f0102566:	e8 32 db ff ff       	call   f010009d <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010256b:	8d 83 50 c6 fe ff    	lea    -0x139b0(%ebx),%eax
f0102571:	50                   	push   %eax
f0102572:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102578:	50                   	push   %eax
f0102579:	68 7d 03 00 00       	push   $0x37d
f010257e:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102584:	50                   	push   %eax
f0102585:	e8 13 db ff ff       	call   f010009d <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010258a:	8d 83 88 c6 fe ff    	lea    -0x13978(%ebx),%eax
f0102590:	50                   	push   %eax
f0102591:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102597:	50                   	push   %eax
f0102598:	68 80 03 00 00       	push   $0x380
f010259d:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01025a3:	50                   	push   %eax
f01025a4:	e8 f4 da ff ff       	call   f010009d <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01025a9:	8d 83 c0 c6 fe ff    	lea    -0x13940(%ebx),%eax
f01025af:	50                   	push   %eax
f01025b0:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01025b6:	50                   	push   %eax
f01025b7:	68 83 03 00 00       	push   $0x383
f01025bc:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01025c2:	50                   	push   %eax
f01025c3:	e8 d5 da ff ff       	call   f010009d <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01025c8:	8d 83 50 c6 fe ff    	lea    -0x139b0(%ebx),%eax
f01025ce:	50                   	push   %eax
f01025cf:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01025d5:	50                   	push   %eax
f01025d6:	68 84 03 00 00       	push   $0x384
f01025db:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01025e1:	50                   	push   %eax
f01025e2:	e8 b6 da ff ff       	call   f010009d <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01025e7:	8d 83 fc c6 fe ff    	lea    -0x13904(%ebx),%eax
f01025ed:	50                   	push   %eax
f01025ee:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01025f4:	50                   	push   %eax
f01025f5:	68 87 03 00 00       	push   $0x387
f01025fa:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102600:	50                   	push   %eax
f0102601:	e8 97 da ff ff       	call   f010009d <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102606:	8d 83 28 c7 fe ff    	lea    -0x138d8(%ebx),%eax
f010260c:	50                   	push   %eax
f010260d:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102613:	50                   	push   %eax
f0102614:	68 88 03 00 00       	push   $0x388
f0102619:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010261f:	50                   	push   %eax
f0102620:	e8 78 da ff ff       	call   f010009d <_panic>
	assert(pp1->pp_ref == 2);
f0102625:	8d 83 cc cb fe ff    	lea    -0x13434(%ebx),%eax
f010262b:	50                   	push   %eax
f010262c:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102632:	50                   	push   %eax
f0102633:	68 8a 03 00 00       	push   $0x38a
f0102638:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010263e:	50                   	push   %eax
f010263f:	e8 59 da ff ff       	call   f010009d <_panic>
	assert(pp2->pp_ref == 0);
f0102644:	8d 83 dd cb fe ff    	lea    -0x13423(%ebx),%eax
f010264a:	50                   	push   %eax
f010264b:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102651:	50                   	push   %eax
f0102652:	68 8b 03 00 00       	push   $0x38b
f0102657:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010265d:	50                   	push   %eax
f010265e:	e8 3a da ff ff       	call   f010009d <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102663:	8d 83 58 c7 fe ff    	lea    -0x138a8(%ebx),%eax
f0102669:	50                   	push   %eax
f010266a:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102670:	50                   	push   %eax
f0102671:	68 8e 03 00 00       	push   $0x38e
f0102676:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010267c:	50                   	push   %eax
f010267d:	e8 1b da ff ff       	call   f010009d <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102682:	8d 83 7c c7 fe ff    	lea    -0x13884(%ebx),%eax
f0102688:	50                   	push   %eax
f0102689:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f010268f:	50                   	push   %eax
f0102690:	68 92 03 00 00       	push   $0x392
f0102695:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010269b:	50                   	push   %eax
f010269c:	e8 fc d9 ff ff       	call   f010009d <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01026a1:	8d 83 28 c7 fe ff    	lea    -0x138d8(%ebx),%eax
f01026a7:	50                   	push   %eax
f01026a8:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01026ae:	50                   	push   %eax
f01026af:	68 93 03 00 00       	push   $0x393
f01026b4:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01026ba:	50                   	push   %eax
f01026bb:	e8 dd d9 ff ff       	call   f010009d <_panic>
	assert(pp1->pp_ref == 1);
f01026c0:	8d 83 83 cb fe ff    	lea    -0x1347d(%ebx),%eax
f01026c6:	50                   	push   %eax
f01026c7:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01026cd:	50                   	push   %eax
f01026ce:	68 94 03 00 00       	push   $0x394
f01026d3:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01026d9:	50                   	push   %eax
f01026da:	e8 be d9 ff ff       	call   f010009d <_panic>
	assert(pp2->pp_ref == 0);
f01026df:	8d 83 dd cb fe ff    	lea    -0x13423(%ebx),%eax
f01026e5:	50                   	push   %eax
f01026e6:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01026ec:	50                   	push   %eax
f01026ed:	68 95 03 00 00       	push   $0x395
f01026f2:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01026f8:	50                   	push   %eax
f01026f9:	e8 9f d9 ff ff       	call   f010009d <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01026fe:	8d 83 a0 c7 fe ff    	lea    -0x13860(%ebx),%eax
f0102704:	50                   	push   %eax
f0102705:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f010270b:	50                   	push   %eax
f010270c:	68 98 03 00 00       	push   $0x398
f0102711:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102717:	50                   	push   %eax
f0102718:	e8 80 d9 ff ff       	call   f010009d <_panic>
	assert(pp1->pp_ref);
f010271d:	8d 83 ee cb fe ff    	lea    -0x13412(%ebx),%eax
f0102723:	50                   	push   %eax
f0102724:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f010272a:	50                   	push   %eax
f010272b:	68 99 03 00 00       	push   $0x399
f0102730:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102736:	50                   	push   %eax
f0102737:	e8 61 d9 ff ff       	call   f010009d <_panic>
	assert(pp1->pp_link == NULL);
f010273c:	8d 83 fa cb fe ff    	lea    -0x13406(%ebx),%eax
f0102742:	50                   	push   %eax
f0102743:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102749:	50                   	push   %eax
f010274a:	68 9a 03 00 00       	push   $0x39a
f010274f:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102755:	50                   	push   %eax
f0102756:	e8 42 d9 ff ff       	call   f010009d <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010275b:	8d 83 7c c7 fe ff    	lea    -0x13884(%ebx),%eax
f0102761:	50                   	push   %eax
f0102762:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102768:	50                   	push   %eax
f0102769:	68 9e 03 00 00       	push   $0x39e
f010276e:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102774:	50                   	push   %eax
f0102775:	e8 23 d9 ff ff       	call   f010009d <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010277a:	8d 83 d8 c7 fe ff    	lea    -0x13828(%ebx),%eax
f0102780:	50                   	push   %eax
f0102781:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102787:	50                   	push   %eax
f0102788:	68 9f 03 00 00       	push   $0x39f
f010278d:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102793:	50                   	push   %eax
f0102794:	e8 04 d9 ff ff       	call   f010009d <_panic>
	assert(pp1->pp_ref == 0);
f0102799:	8d 83 0f cc fe ff    	lea    -0x133f1(%ebx),%eax
f010279f:	50                   	push   %eax
f01027a0:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01027a6:	50                   	push   %eax
f01027a7:	68 a0 03 00 00       	push   $0x3a0
f01027ac:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01027b2:	50                   	push   %eax
f01027b3:	e8 e5 d8 ff ff       	call   f010009d <_panic>
	assert(pp2->pp_ref == 0);
f01027b8:	8d 83 dd cb fe ff    	lea    -0x13423(%ebx),%eax
f01027be:	50                   	push   %eax
f01027bf:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01027c5:	50                   	push   %eax
f01027c6:	68 a1 03 00 00       	push   $0x3a1
f01027cb:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01027d1:	50                   	push   %eax
f01027d2:	e8 c6 d8 ff ff       	call   f010009d <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f01027d7:	8d 83 00 c8 fe ff    	lea    -0x13800(%ebx),%eax
f01027dd:	50                   	push   %eax
f01027de:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01027e4:	50                   	push   %eax
f01027e5:	68 a4 03 00 00       	push   $0x3a4
f01027ea:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01027f0:	50                   	push   %eax
f01027f1:	e8 a7 d8 ff ff       	call   f010009d <_panic>
	assert(!page_alloc(0));
f01027f6:	8d 83 31 cb fe ff    	lea    -0x134cf(%ebx),%eax
f01027fc:	50                   	push   %eax
f01027fd:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102803:	50                   	push   %eax
f0102804:	68 a7 03 00 00       	push   $0x3a7
f0102809:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010280f:	50                   	push   %eax
f0102810:	e8 88 d8 ff ff       	call   f010009d <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102815:	8d 83 a4 c4 fe ff    	lea    -0x13b5c(%ebx),%eax
f010281b:	50                   	push   %eax
f010281c:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102822:	50                   	push   %eax
f0102823:	68 aa 03 00 00       	push   $0x3aa
f0102828:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010282e:	50                   	push   %eax
f010282f:	e8 69 d8 ff ff       	call   f010009d <_panic>
	assert(pp0->pp_ref == 1);
f0102834:	8d 83 94 cb fe ff    	lea    -0x1346c(%ebx),%eax
f010283a:	50                   	push   %eax
f010283b:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102841:	50                   	push   %eax
f0102842:	68 ac 03 00 00       	push   $0x3ac
f0102847:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010284d:	50                   	push   %eax
f010284e:	e8 4a d8 ff ff       	call   f010009d <_panic>
f0102853:	51                   	push   %ecx
f0102854:	8d 83 f8 c1 fe ff    	lea    -0x13e08(%ebx),%eax
f010285a:	50                   	push   %eax
f010285b:	68 b3 03 00 00       	push   $0x3b3
f0102860:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102866:	50                   	push   %eax
f0102867:	e8 31 d8 ff ff       	call   f010009d <_panic>
	assert(ptep == ptep1 + PTX(va));
f010286c:	8d 83 20 cc fe ff    	lea    -0x133e0(%ebx),%eax
f0102872:	50                   	push   %eax
f0102873:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102879:	50                   	push   %eax
f010287a:	68 b4 03 00 00       	push   $0x3b4
f010287f:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102885:	50                   	push   %eax
f0102886:	e8 12 d8 ff ff       	call   f010009d <_panic>
f010288b:	52                   	push   %edx
f010288c:	8d 83 f8 c1 fe ff    	lea    -0x13e08(%ebx),%eax
f0102892:	50                   	push   %eax
f0102893:	6a 52                	push   $0x52
f0102895:	8d 83 c1 c9 fe ff    	lea    -0x1363f(%ebx),%eax
f010289b:	50                   	push   %eax
f010289c:	e8 fc d7 ff ff       	call   f010009d <_panic>
f01028a1:	52                   	push   %edx
f01028a2:	8d 83 f8 c1 fe ff    	lea    -0x13e08(%ebx),%eax
f01028a8:	50                   	push   %eax
f01028a9:	6a 52                	push   $0x52
f01028ab:	8d 83 c1 c9 fe ff    	lea    -0x1363f(%ebx),%eax
f01028b1:	50                   	push   %eax
f01028b2:	e8 e6 d7 ff ff       	call   f010009d <_panic>
		assert((ptep[i] & PTE_P) == 0);
f01028b7:	8d 83 38 cc fe ff    	lea    -0x133c8(%ebx),%eax
f01028bd:	50                   	push   %eax
f01028be:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01028c4:	50                   	push   %eax
f01028c5:	68 be 03 00 00       	push   $0x3be
f01028ca:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01028d0:	50                   	push   %eax
f01028d1:	e8 c7 d7 ff ff       	call   f010009d <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028d6:	50                   	push   %eax
f01028d7:	8d 83 a8 c3 fe ff    	lea    -0x13c58(%ebx),%eax
f01028dd:	50                   	push   %eax
f01028de:	68 c2 00 00 00       	push   $0xc2
f01028e3:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01028e9:	50                   	push   %eax
f01028ea:	e8 ae d7 ff ff       	call   f010009d <_panic>
f01028ef:	50                   	push   %eax
f01028f0:	8d 83 a8 c3 fe ff    	lea    -0x13c58(%ebx),%eax
f01028f6:	50                   	push   %eax
f01028f7:	68 cf 00 00 00       	push   $0xcf
f01028fc:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102902:	50                   	push   %eax
f0102903:	e8 95 d7 ff ff       	call   f010009d <_panic>
f0102908:	ff 75 bc             	pushl  -0x44(%ebp)
f010290b:	8d 83 a8 c3 fe ff    	lea    -0x13c58(%ebx),%eax
f0102911:	50                   	push   %eax
f0102912:	68 00 03 00 00       	push   $0x300
f0102917:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010291d:	50                   	push   %eax
f010291e:	e8 7a d7 ff ff       	call   f010009d <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102923:	8d 83 24 c8 fe ff    	lea    -0x137dc(%ebx),%eax
f0102929:	50                   	push   %eax
f010292a:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102930:	50                   	push   %eax
f0102931:	68 00 03 00 00       	push   $0x300
f0102936:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f010293c:	50                   	push   %eax
f010293d:	e8 5b d7 ff ff       	call   f010009d <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102942:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0102945:	c1 e0 0c             	shl    $0xc,%eax
f0102948:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010294b:	89 fe                	mov    %edi,%esi
f010294d:	3b 75 cc             	cmp    -0x34(%ebp),%esi
f0102950:	73 39                	jae    f010298b <mem_init+0x161b>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102952:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0102958:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010295b:	e8 f4 e1 ff ff       	call   f0100b54 <check_va2pa>
f0102960:	39 c6                	cmp    %eax,%esi
f0102962:	75 08                	jne    f010296c <mem_init+0x15fc>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102964:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010296a:	eb e1                	jmp    f010294d <mem_init+0x15dd>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010296c:	8d 83 58 c8 fe ff    	lea    -0x137a8(%ebx),%eax
f0102972:	50                   	push   %eax
f0102973:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102979:	50                   	push   %eax
f010297a:	68 05 03 00 00       	push   $0x305
f010297f:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102985:	50                   	push   %eax
f0102986:	e8 12 d7 ff ff       	call   f010009d <_panic>
f010298b:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102990:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102993:	05 00 80 00 20       	add    $0x20008000,%eax
f0102998:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010299b:	89 f2                	mov    %esi,%edx
f010299d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029a0:	e8 af e1 ff ff       	call   f0100b54 <check_va2pa>
f01029a5:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01029a8:	8d 14 31             	lea    (%ecx,%esi,1),%edx
f01029ab:	39 c2                	cmp    %eax,%edx
f01029ad:	75 25                	jne    f01029d4 <mem_init+0x1664>
f01029af:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01029b5:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01029bb:	75 de                	jne    f010299b <mem_init+0x162b>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01029bd:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01029c2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029c5:	e8 8a e1 ff ff       	call   f0100b54 <check_va2pa>
f01029ca:	83 f8 ff             	cmp    $0xffffffff,%eax
f01029cd:	75 24                	jne    f01029f3 <mem_init+0x1683>
f01029cf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029d2:	eb 6b                	jmp    f0102a3f <mem_init+0x16cf>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01029d4:	8d 83 80 c8 fe ff    	lea    -0x13780(%ebx),%eax
f01029da:	50                   	push   %eax
f01029db:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f01029e1:	50                   	push   %eax
f01029e2:	68 09 03 00 00       	push   $0x309
f01029e7:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f01029ed:	50                   	push   %eax
f01029ee:	e8 aa d6 ff ff       	call   f010009d <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01029f3:	8d 83 c8 c8 fe ff    	lea    -0x13738(%ebx),%eax
f01029f9:	50                   	push   %eax
f01029fa:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102a00:	50                   	push   %eax
f0102a01:	68 0a 03 00 00       	push   $0x30a
f0102a06:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102a0c:	50                   	push   %eax
f0102a0d:	e8 8b d6 ff ff       	call   f010009d <_panic>
		switch (i) {
f0102a12:	81 ff bf 03 00 00    	cmp    $0x3bf,%edi
f0102a18:	75 25                	jne    f0102a3f <mem_init+0x16cf>
			assert(pgdir[i] & PTE_P);
f0102a1a:	f6 04 b8 01          	testb  $0x1,(%eax,%edi,4)
f0102a1e:	74 4c                	je     f0102a6c <mem_init+0x16fc>
	for (i = 0; i < NPDENTRIES; i++) {
f0102a20:	83 c7 01             	add    $0x1,%edi
f0102a23:	81 ff ff 03 00 00    	cmp    $0x3ff,%edi
f0102a29:	0f 87 a7 00 00 00    	ja     f0102ad6 <mem_init+0x1766>
		switch (i) {
f0102a2f:	81 ff bd 03 00 00    	cmp    $0x3bd,%edi
f0102a35:	77 db                	ja     f0102a12 <mem_init+0x16a2>
f0102a37:	81 ff bb 03 00 00    	cmp    $0x3bb,%edi
f0102a3d:	77 db                	ja     f0102a1a <mem_init+0x16aa>
			if (i >= PDX(KERNBASE)) {
f0102a3f:	81 ff bf 03 00 00    	cmp    $0x3bf,%edi
f0102a45:	77 44                	ja     f0102a8b <mem_init+0x171b>
				assert(pgdir[i] == 0);
f0102a47:	83 3c b8 00          	cmpl   $0x0,(%eax,%edi,4)
f0102a4b:	74 d3                	je     f0102a20 <mem_init+0x16b0>
f0102a4d:	8d 83 8a cc fe ff    	lea    -0x13376(%ebx),%eax
f0102a53:	50                   	push   %eax
f0102a54:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102a5a:	50                   	push   %eax
f0102a5b:	68 19 03 00 00       	push   $0x319
f0102a60:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102a66:	50                   	push   %eax
f0102a67:	e8 31 d6 ff ff       	call   f010009d <_panic>
			assert(pgdir[i] & PTE_P);
f0102a6c:	8d 83 68 cc fe ff    	lea    -0x13398(%ebx),%eax
f0102a72:	50                   	push   %eax
f0102a73:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102a79:	50                   	push   %eax
f0102a7a:	68 12 03 00 00       	push   $0x312
f0102a7f:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102a85:	50                   	push   %eax
f0102a86:	e8 12 d6 ff ff       	call   f010009d <_panic>
				assert(pgdir[i] & PTE_P);
f0102a8b:	8b 14 b8             	mov    (%eax,%edi,4),%edx
f0102a8e:	f6 c2 01             	test   $0x1,%dl
f0102a91:	74 24                	je     f0102ab7 <mem_init+0x1747>
				assert(pgdir[i] & PTE_W);
f0102a93:	f6 c2 02             	test   $0x2,%dl
f0102a96:	75 88                	jne    f0102a20 <mem_init+0x16b0>
f0102a98:	8d 83 79 cc fe ff    	lea    -0x13387(%ebx),%eax
f0102a9e:	50                   	push   %eax
f0102a9f:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102aa5:	50                   	push   %eax
f0102aa6:	68 17 03 00 00       	push   $0x317
f0102aab:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102ab1:	50                   	push   %eax
f0102ab2:	e8 e6 d5 ff ff       	call   f010009d <_panic>
				assert(pgdir[i] & PTE_P);
f0102ab7:	8d 83 68 cc fe ff    	lea    -0x13398(%ebx),%eax
f0102abd:	50                   	push   %eax
f0102abe:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102ac4:	50                   	push   %eax
f0102ac5:	68 16 03 00 00       	push   $0x316
f0102aca:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102ad0:	50                   	push   %eax
f0102ad1:	e8 c7 d5 ff ff       	call   f010009d <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102ad6:	83 ec 0c             	sub    $0xc,%esp
f0102ad9:	8d 83 f8 c8 fe ff    	lea    -0x13708(%ebx),%eax
f0102adf:	50                   	push   %eax
f0102ae0:	e8 c7 04 00 00       	call   f0102fac <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102ae5:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102aeb:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102aed:	83 c4 10             	add    $0x10,%esp
f0102af0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102af5:	0f 86 30 02 00 00    	jbe    f0102d2b <mem_init+0x19bb>
	return (physaddr_t)kva - KERNBASE;
f0102afb:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102b00:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102b03:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b08:	e8 c3 e0 ff ff       	call   f0100bd0 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102b0d:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102b10:	83 e0 f3             	and    $0xfffffff3,%eax
f0102b13:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102b18:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102b1b:	83 ec 0c             	sub    $0xc,%esp
f0102b1e:	6a 00                	push   $0x0
f0102b20:	e8 f2 e4 ff ff       	call   f0101017 <page_alloc>
f0102b25:	89 c7                	mov    %eax,%edi
f0102b27:	83 c4 10             	add    $0x10,%esp
f0102b2a:	85 c0                	test   %eax,%eax
f0102b2c:	0f 84 12 02 00 00    	je     f0102d44 <mem_init+0x19d4>
	assert((pp1 = page_alloc(0)));
f0102b32:	83 ec 0c             	sub    $0xc,%esp
f0102b35:	6a 00                	push   $0x0
f0102b37:	e8 db e4 ff ff       	call   f0101017 <page_alloc>
f0102b3c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102b3f:	83 c4 10             	add    $0x10,%esp
f0102b42:	85 c0                	test   %eax,%eax
f0102b44:	0f 84 19 02 00 00    	je     f0102d63 <mem_init+0x19f3>
	assert((pp2 = page_alloc(0)));
f0102b4a:	83 ec 0c             	sub    $0xc,%esp
f0102b4d:	6a 00                	push   $0x0
f0102b4f:	e8 c3 e4 ff ff       	call   f0101017 <page_alloc>
f0102b54:	89 c6                	mov    %eax,%esi
f0102b56:	83 c4 10             	add    $0x10,%esp
f0102b59:	85 c0                	test   %eax,%eax
f0102b5b:	0f 84 21 02 00 00    	je     f0102d82 <mem_init+0x1a12>
	page_free(pp0);
f0102b61:	83 ec 0c             	sub    $0xc,%esp
f0102b64:	57                   	push   %edi
f0102b65:	e8 3c e5 ff ff       	call   f01010a6 <page_free>
	return (pp - pages) << PGSHIFT;
f0102b6a:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0102b70:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102b73:	2b 08                	sub    (%eax),%ecx
f0102b75:	89 c8                	mov    %ecx,%eax
f0102b77:	c1 f8 03             	sar    $0x3,%eax
f0102b7a:	89 c2                	mov    %eax,%edx
f0102b7c:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102b7f:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102b84:	83 c4 10             	add    $0x10,%esp
f0102b87:	c7 c1 c8 a6 11 f0    	mov    $0xf011a6c8,%ecx
f0102b8d:	3b 01                	cmp    (%ecx),%eax
f0102b8f:	0f 83 0c 02 00 00    	jae    f0102da1 <mem_init+0x1a31>
	memset(page2kva(pp1), 1, PGSIZE);
f0102b95:	83 ec 04             	sub    $0x4,%esp
f0102b98:	68 00 10 00 00       	push   $0x1000
f0102b9d:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102b9f:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102ba5:	52                   	push   %edx
f0102ba6:	e8 06 10 00 00       	call   f0103bb1 <memset>
	return (pp - pages) << PGSHIFT;
f0102bab:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0102bb1:	89 f1                	mov    %esi,%ecx
f0102bb3:	2b 08                	sub    (%eax),%ecx
f0102bb5:	89 c8                	mov    %ecx,%eax
f0102bb7:	c1 f8 03             	sar    $0x3,%eax
f0102bba:	89 c2                	mov    %eax,%edx
f0102bbc:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102bbf:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102bc4:	83 c4 10             	add    $0x10,%esp
f0102bc7:	c7 c1 c8 a6 11 f0    	mov    $0xf011a6c8,%ecx
f0102bcd:	3b 01                	cmp    (%ecx),%eax
f0102bcf:	0f 83 e2 01 00 00    	jae    f0102db7 <mem_init+0x1a47>
	memset(page2kva(pp2), 2, PGSIZE);
f0102bd5:	83 ec 04             	sub    $0x4,%esp
f0102bd8:	68 00 10 00 00       	push   $0x1000
f0102bdd:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102bdf:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102be5:	52                   	push   %edx
f0102be6:	e8 c6 0f 00 00       	call   f0103bb1 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102beb:	6a 02                	push   $0x2
f0102bed:	68 00 10 00 00       	push   $0x1000
f0102bf2:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102bf5:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102bfb:	ff 30                	pushl  (%eax)
f0102bfd:	e8 e0 e6 ff ff       	call   f01012e2 <page_insert>
	assert(pp1->pp_ref == 1);
f0102c02:	83 c4 20             	add    $0x20,%esp
f0102c05:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c08:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102c0d:	0f 85 ba 01 00 00    	jne    f0102dcd <mem_init+0x1a5d>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102c13:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102c1a:	01 01 01 
f0102c1d:	0f 85 c9 01 00 00    	jne    f0102dec <mem_init+0x1a7c>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102c23:	6a 02                	push   $0x2
f0102c25:	68 00 10 00 00       	push   $0x1000
f0102c2a:	56                   	push   %esi
f0102c2b:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102c31:	ff 30                	pushl  (%eax)
f0102c33:	e8 aa e6 ff ff       	call   f01012e2 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102c38:	83 c4 10             	add    $0x10,%esp
f0102c3b:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102c42:	02 02 02 
f0102c45:	0f 85 c0 01 00 00    	jne    f0102e0b <mem_init+0x1a9b>
	assert(pp2->pp_ref == 1);
f0102c4b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102c50:	0f 85 d4 01 00 00    	jne    f0102e2a <mem_init+0x1aba>
	assert(pp1->pp_ref == 0);
f0102c56:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c59:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102c5e:	0f 85 e5 01 00 00    	jne    f0102e49 <mem_init+0x1ad9>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102c64:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102c6b:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102c6e:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0102c74:	89 f1                	mov    %esi,%ecx
f0102c76:	2b 08                	sub    (%eax),%ecx
f0102c78:	89 c8                	mov    %ecx,%eax
f0102c7a:	c1 f8 03             	sar    $0x3,%eax
f0102c7d:	89 c2                	mov    %eax,%edx
f0102c7f:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102c82:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102c87:	c7 c1 c8 a6 11 f0    	mov    $0xf011a6c8,%ecx
f0102c8d:	3b 01                	cmp    (%ecx),%eax
f0102c8f:	0f 83 d3 01 00 00    	jae    f0102e68 <mem_init+0x1af8>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c95:	81 ba 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%edx)
f0102c9c:	03 03 03 
f0102c9f:	0f 85 d9 01 00 00    	jne    f0102e7e <mem_init+0x1b0e>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102ca5:	83 ec 08             	sub    $0x8,%esp
f0102ca8:	68 00 10 00 00       	push   $0x1000
f0102cad:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102cb3:	ff 30                	pushl  (%eax)
f0102cb5:	e8 e2 e5 ff ff       	call   f010129c <page_remove>
	assert(pp2->pp_ref == 0);
f0102cba:	83 c4 10             	add    $0x10,%esp
f0102cbd:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102cc2:	0f 85 d5 01 00 00    	jne    f0102e9d <mem_init+0x1b2d>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102cc8:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102cce:	8b 08                	mov    (%eax),%ecx
f0102cd0:	8b 11                	mov    (%ecx),%edx
f0102cd2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102cd8:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0102cde:	89 fe                	mov    %edi,%esi
f0102ce0:	2b 30                	sub    (%eax),%esi
f0102ce2:	89 f0                	mov    %esi,%eax
f0102ce4:	c1 f8 03             	sar    $0x3,%eax
f0102ce7:	c1 e0 0c             	shl    $0xc,%eax
f0102cea:	39 c2                	cmp    %eax,%edx
f0102cec:	0f 85 ca 01 00 00    	jne    f0102ebc <mem_init+0x1b4c>
	kern_pgdir[0] = 0;
f0102cf2:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102cf8:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102cfd:	0f 85 d8 01 00 00    	jne    f0102edb <mem_init+0x1b6b>
	pp0->pp_ref = 0;
f0102d03:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// free the pages we took
	page_free(pp0);
f0102d09:	83 ec 0c             	sub    $0xc,%esp
f0102d0c:	57                   	push   %edi
f0102d0d:	e8 94 e3 ff ff       	call   f01010a6 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102d12:	8d 83 8c c9 fe ff    	lea    -0x13674(%ebx),%eax
f0102d18:	89 04 24             	mov    %eax,(%esp)
f0102d1b:	e8 8c 02 00 00       	call   f0102fac <cprintf>
}
f0102d20:	83 c4 10             	add    $0x10,%esp
f0102d23:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d26:	5b                   	pop    %ebx
f0102d27:	5e                   	pop    %esi
f0102d28:	5f                   	pop    %edi
f0102d29:	5d                   	pop    %ebp
f0102d2a:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d2b:	50                   	push   %eax
f0102d2c:	8d 83 a8 c3 fe ff    	lea    -0x13c58(%ebx),%eax
f0102d32:	50                   	push   %eax
f0102d33:	68 e3 00 00 00       	push   $0xe3
f0102d38:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102d3e:	50                   	push   %eax
f0102d3f:	e8 59 d3 ff ff       	call   f010009d <_panic>
	assert((pp0 = page_alloc(0)));
f0102d44:	8d 83 86 ca fe ff    	lea    -0x1357a(%ebx),%eax
f0102d4a:	50                   	push   %eax
f0102d4b:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102d51:	50                   	push   %eax
f0102d52:	68 d9 03 00 00       	push   $0x3d9
f0102d57:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102d5d:	50                   	push   %eax
f0102d5e:	e8 3a d3 ff ff       	call   f010009d <_panic>
	assert((pp1 = page_alloc(0)));
f0102d63:	8d 83 9c ca fe ff    	lea    -0x13564(%ebx),%eax
f0102d69:	50                   	push   %eax
f0102d6a:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102d70:	50                   	push   %eax
f0102d71:	68 da 03 00 00       	push   $0x3da
f0102d76:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102d7c:	50                   	push   %eax
f0102d7d:	e8 1b d3 ff ff       	call   f010009d <_panic>
	assert((pp2 = page_alloc(0)));
f0102d82:	8d 83 b2 ca fe ff    	lea    -0x1354e(%ebx),%eax
f0102d88:	50                   	push   %eax
f0102d89:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102d8f:	50                   	push   %eax
f0102d90:	68 db 03 00 00       	push   $0x3db
f0102d95:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102d9b:	50                   	push   %eax
f0102d9c:	e8 fc d2 ff ff       	call   f010009d <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102da1:	52                   	push   %edx
f0102da2:	8d 83 f8 c1 fe ff    	lea    -0x13e08(%ebx),%eax
f0102da8:	50                   	push   %eax
f0102da9:	6a 52                	push   $0x52
f0102dab:	8d 83 c1 c9 fe ff    	lea    -0x1363f(%ebx),%eax
f0102db1:	50                   	push   %eax
f0102db2:	e8 e6 d2 ff ff       	call   f010009d <_panic>
f0102db7:	52                   	push   %edx
f0102db8:	8d 83 f8 c1 fe ff    	lea    -0x13e08(%ebx),%eax
f0102dbe:	50                   	push   %eax
f0102dbf:	6a 52                	push   $0x52
f0102dc1:	8d 83 c1 c9 fe ff    	lea    -0x1363f(%ebx),%eax
f0102dc7:	50                   	push   %eax
f0102dc8:	e8 d0 d2 ff ff       	call   f010009d <_panic>
	assert(pp1->pp_ref == 1);
f0102dcd:	8d 83 83 cb fe ff    	lea    -0x1347d(%ebx),%eax
f0102dd3:	50                   	push   %eax
f0102dd4:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102dda:	50                   	push   %eax
f0102ddb:	68 e0 03 00 00       	push   $0x3e0
f0102de0:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102de6:	50                   	push   %eax
f0102de7:	e8 b1 d2 ff ff       	call   f010009d <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102dec:	8d 83 18 c9 fe ff    	lea    -0x136e8(%ebx),%eax
f0102df2:	50                   	push   %eax
f0102df3:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102df9:	50                   	push   %eax
f0102dfa:	68 e1 03 00 00       	push   $0x3e1
f0102dff:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102e05:	50                   	push   %eax
f0102e06:	e8 92 d2 ff ff       	call   f010009d <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102e0b:	8d 83 3c c9 fe ff    	lea    -0x136c4(%ebx),%eax
f0102e11:	50                   	push   %eax
f0102e12:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102e18:	50                   	push   %eax
f0102e19:	68 e3 03 00 00       	push   $0x3e3
f0102e1e:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102e24:	50                   	push   %eax
f0102e25:	e8 73 d2 ff ff       	call   f010009d <_panic>
	assert(pp2->pp_ref == 1);
f0102e2a:	8d 83 a5 cb fe ff    	lea    -0x1345b(%ebx),%eax
f0102e30:	50                   	push   %eax
f0102e31:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102e37:	50                   	push   %eax
f0102e38:	68 e4 03 00 00       	push   $0x3e4
f0102e3d:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102e43:	50                   	push   %eax
f0102e44:	e8 54 d2 ff ff       	call   f010009d <_panic>
	assert(pp1->pp_ref == 0);
f0102e49:	8d 83 0f cc fe ff    	lea    -0x133f1(%ebx),%eax
f0102e4f:	50                   	push   %eax
f0102e50:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102e56:	50                   	push   %eax
f0102e57:	68 e5 03 00 00       	push   $0x3e5
f0102e5c:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102e62:	50                   	push   %eax
f0102e63:	e8 35 d2 ff ff       	call   f010009d <_panic>
f0102e68:	52                   	push   %edx
f0102e69:	8d 83 f8 c1 fe ff    	lea    -0x13e08(%ebx),%eax
f0102e6f:	50                   	push   %eax
f0102e70:	6a 52                	push   $0x52
f0102e72:	8d 83 c1 c9 fe ff    	lea    -0x1363f(%ebx),%eax
f0102e78:	50                   	push   %eax
f0102e79:	e8 1f d2 ff ff       	call   f010009d <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102e7e:	8d 83 60 c9 fe ff    	lea    -0x136a0(%ebx),%eax
f0102e84:	50                   	push   %eax
f0102e85:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102e8b:	50                   	push   %eax
f0102e8c:	68 e7 03 00 00       	push   $0x3e7
f0102e91:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102e97:	50                   	push   %eax
f0102e98:	e8 00 d2 ff ff       	call   f010009d <_panic>
	assert(pp2->pp_ref == 0);
f0102e9d:	8d 83 dd cb fe ff    	lea    -0x13423(%ebx),%eax
f0102ea3:	50                   	push   %eax
f0102ea4:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102eaa:	50                   	push   %eax
f0102eab:	68 e9 03 00 00       	push   $0x3e9
f0102eb0:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102eb6:	50                   	push   %eax
f0102eb7:	e8 e1 d1 ff ff       	call   f010009d <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102ebc:	8d 83 a4 c4 fe ff    	lea    -0x13b5c(%ebx),%eax
f0102ec2:	50                   	push   %eax
f0102ec3:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102ec9:	50                   	push   %eax
f0102eca:	68 ec 03 00 00       	push   $0x3ec
f0102ecf:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102ed5:	50                   	push   %eax
f0102ed6:	e8 c2 d1 ff ff       	call   f010009d <_panic>
	assert(pp0->pp_ref == 1);
f0102edb:	8d 83 94 cb fe ff    	lea    -0x1346c(%ebx),%eax
f0102ee1:	50                   	push   %eax
f0102ee2:	8d 83 db c9 fe ff    	lea    -0x13625(%ebx),%eax
f0102ee8:	50                   	push   %eax
f0102ee9:	68 ee 03 00 00       	push   $0x3ee
f0102eee:	8d 83 b5 c9 fe ff    	lea    -0x1364b(%ebx),%eax
f0102ef4:	50                   	push   %eax
f0102ef5:	e8 a3 d1 ff ff       	call   f010009d <_panic>

f0102efa <tlb_invalidate>:
{
f0102efa:	f3 0f 1e fb          	endbr32 
f0102efe:	55                   	push   %ebp
f0102eff:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102f01:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f04:	0f 01 38             	invlpg (%eax)
}
f0102f07:	5d                   	pop    %ebp
f0102f08:	c3                   	ret    

f0102f09 <__x86.get_pc_thunk.dx>:
f0102f09:	8b 14 24             	mov    (%esp),%edx
f0102f0c:	c3                   	ret    

f0102f0d <__x86.get_pc_thunk.cx>:
f0102f0d:	8b 0c 24             	mov    (%esp),%ecx
f0102f10:	c3                   	ret    

f0102f11 <__x86.get_pc_thunk.di>:
f0102f11:	8b 3c 24             	mov    (%esp),%edi
f0102f14:	c3                   	ret    

f0102f15 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102f15:	f3 0f 1e fb          	endbr32 
f0102f19:	55                   	push   %ebp
f0102f1a:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f1c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f1f:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f24:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102f25:	ba 71 00 00 00       	mov    $0x71,%edx
f0102f2a:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102f2b:	0f b6 c0             	movzbl %al,%eax
}
f0102f2e:	5d                   	pop    %ebp
f0102f2f:	c3                   	ret    

f0102f30 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102f30:	f3 0f 1e fb          	endbr32 
f0102f34:	55                   	push   %ebp
f0102f35:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f37:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f3a:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f3f:	ee                   	out    %al,(%dx)
f0102f40:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f43:	ba 71 00 00 00       	mov    $0x71,%edx
f0102f48:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102f49:	5d                   	pop    %ebp
f0102f4a:	c3                   	ret    

f0102f4b <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102f4b:	f3 0f 1e fb          	endbr32 
f0102f4f:	55                   	push   %ebp
f0102f50:	89 e5                	mov    %esp,%ebp
f0102f52:	53                   	push   %ebx
f0102f53:	83 ec 10             	sub    $0x10,%esp
f0102f56:	e8 00 d2 ff ff       	call   f010015b <__x86.get_pc_thunk.bx>
f0102f5b:	81 c3 ad 53 01 00    	add    $0x153ad,%ebx
	cputchar(ch);
f0102f61:	ff 75 08             	pushl  0x8(%ebp)
f0102f64:	e8 73 d7 ff ff       	call   f01006dc <cputchar>
	*cnt++;
}
f0102f69:	83 c4 10             	add    $0x10,%esp
f0102f6c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102f6f:	c9                   	leave  
f0102f70:	c3                   	ret    

f0102f71 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102f71:	f3 0f 1e fb          	endbr32 
f0102f75:	55                   	push   %ebp
f0102f76:	89 e5                	mov    %esp,%ebp
f0102f78:	53                   	push   %ebx
f0102f79:	83 ec 14             	sub    $0x14,%esp
f0102f7c:	e8 da d1 ff ff       	call   f010015b <__x86.get_pc_thunk.bx>
f0102f81:	81 c3 87 53 01 00    	add    $0x15387,%ebx
	int cnt = 0;
f0102f87:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102f8e:	ff 75 0c             	pushl  0xc(%ebp)
f0102f91:	ff 75 08             	pushl  0x8(%ebp)
f0102f94:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102f97:	50                   	push   %eax
f0102f98:	8d 83 43 ac fe ff    	lea    -0x153bd(%ebx),%eax
f0102f9e:	50                   	push   %eax
f0102f9f:	e8 23 04 00 00       	call   f01033c7 <vprintfmt>
	return cnt;
}
f0102fa4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102fa7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102faa:	c9                   	leave  
f0102fab:	c3                   	ret    

f0102fac <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102fac:	f3 0f 1e fb          	endbr32 
f0102fb0:	55                   	push   %ebp
f0102fb1:	89 e5                	mov    %esp,%ebp
f0102fb3:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102fb6:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102fb9:	50                   	push   %eax
f0102fba:	ff 75 08             	pushl  0x8(%ebp)
f0102fbd:	e8 af ff ff ff       	call   f0102f71 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102fc2:	c9                   	leave  
f0102fc3:	c3                   	ret    

f0102fc4 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102fc4:	55                   	push   %ebp
f0102fc5:	89 e5                	mov    %esp,%ebp
f0102fc7:	57                   	push   %edi
f0102fc8:	56                   	push   %esi
f0102fc9:	53                   	push   %ebx
f0102fca:	83 ec 14             	sub    $0x14,%esp
f0102fcd:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102fd0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102fd3:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102fd6:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102fd9:	8b 1a                	mov    (%edx),%ebx
f0102fdb:	8b 01                	mov    (%ecx),%eax
f0102fdd:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102fe0:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102fe7:	eb 23                	jmp    f010300c <stab_binsearch+0x48>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102fe9:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0102fec:	eb 1e                	jmp    f010300c <stab_binsearch+0x48>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102fee:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102ff1:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102ff4:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102ff8:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102ffb:	73 46                	jae    f0103043 <stab_binsearch+0x7f>
			*region_left = m;
f0102ffd:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103000:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103002:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f0103005:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f010300c:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010300f:	7f 5f                	jg     f0103070 <stab_binsearch+0xac>
		int true_m = (l + r) / 2, m = true_m;
f0103011:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103014:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f0103017:	89 d0                	mov    %edx,%eax
f0103019:	c1 e8 1f             	shr    $0x1f,%eax
f010301c:	01 d0                	add    %edx,%eax
f010301e:	89 c7                	mov    %eax,%edi
f0103020:	d1 ff                	sar    %edi
f0103022:	83 e0 fe             	and    $0xfffffffe,%eax
f0103025:	01 f8                	add    %edi,%eax
f0103027:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010302a:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f010302e:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f0103030:	39 c3                	cmp    %eax,%ebx
f0103032:	7f b5                	jg     f0102fe9 <stab_binsearch+0x25>
f0103034:	0f b6 0a             	movzbl (%edx),%ecx
f0103037:	83 ea 0c             	sub    $0xc,%edx
f010303a:	39 f1                	cmp    %esi,%ecx
f010303c:	74 b0                	je     f0102fee <stab_binsearch+0x2a>
			m--;
f010303e:	83 e8 01             	sub    $0x1,%eax
f0103041:	eb ed                	jmp    f0103030 <stab_binsearch+0x6c>
		} else if (stabs[m].n_value > addr) {
f0103043:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103046:	76 14                	jbe    f010305c <stab_binsearch+0x98>
			*region_right = m - 1;
f0103048:	83 e8 01             	sub    $0x1,%eax
f010304b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010304e:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103051:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f0103053:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010305a:	eb b0                	jmp    f010300c <stab_binsearch+0x48>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010305c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010305f:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0103061:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103065:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f0103067:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010306e:	eb 9c                	jmp    f010300c <stab_binsearch+0x48>
		}
	}

	if (!any_matches)
f0103070:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103074:	75 15                	jne    f010308b <stab_binsearch+0xc7>
		*region_right = *region_left - 1;
f0103076:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103079:	8b 00                	mov    (%eax),%eax
f010307b:	83 e8 01             	sub    $0x1,%eax
f010307e:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103081:	89 07                	mov    %eax,(%edi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0103083:	83 c4 14             	add    $0x14,%esp
f0103086:	5b                   	pop    %ebx
f0103087:	5e                   	pop    %esi
f0103088:	5f                   	pop    %edi
f0103089:	5d                   	pop    %ebp
f010308a:	c3                   	ret    
		for (l = *region_right;
f010308b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010308e:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103090:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103093:	8b 0f                	mov    (%edi),%ecx
f0103095:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103098:	8b 7d ec             	mov    -0x14(%ebp),%edi
f010309b:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
		for (l = *region_right;
f010309f:	eb 03                	jmp    f01030a4 <stab_binsearch+0xe0>
		     l--)
f01030a1:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f01030a4:	39 c1                	cmp    %eax,%ecx
f01030a6:	7d 0a                	jge    f01030b2 <stab_binsearch+0xee>
		     l > *region_left && stabs[l].n_type != type;
f01030a8:	0f b6 1a             	movzbl (%edx),%ebx
f01030ab:	83 ea 0c             	sub    $0xc,%edx
f01030ae:	39 f3                	cmp    %esi,%ebx
f01030b0:	75 ef                	jne    f01030a1 <stab_binsearch+0xdd>
		*region_left = l;
f01030b2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01030b5:	89 07                	mov    %eax,(%edi)
}
f01030b7:	eb ca                	jmp    f0103083 <stab_binsearch+0xbf>

f01030b9 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01030b9:	f3 0f 1e fb          	endbr32 
f01030bd:	55                   	push   %ebp
f01030be:	89 e5                	mov    %esp,%ebp
f01030c0:	57                   	push   %edi
f01030c1:	56                   	push   %esi
f01030c2:	53                   	push   %ebx
f01030c3:	83 ec 2c             	sub    $0x2c,%esp
f01030c6:	e8 42 fe ff ff       	call   f0102f0d <__x86.get_pc_thunk.cx>
f01030cb:	81 c1 3d 52 01 00    	add    $0x1523d,%ecx
f01030d1:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01030d4:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01030d7:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01030da:	8d 81 98 cc fe ff    	lea    -0x13368(%ecx),%eax
f01030e0:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f01030e2:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f01030e9:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f01030ec:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f01030f3:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f01030f6:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01030fd:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0103103:	0f 86 f4 00 00 00    	jbe    f01031fd <debuginfo_eip+0x144>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103109:	c7 c0 c5 c3 10 f0    	mov    $0xf010c3c5,%eax
f010310f:	39 81 fc ff ff ff    	cmp    %eax,-0x4(%ecx)
f0103115:	0f 86 88 01 00 00    	jbe    f01032a3 <debuginfo_eip+0x1ea>
f010311b:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010311e:	c7 c0 2f e2 10 f0    	mov    $0xf010e22f,%eax
f0103124:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103128:	0f 85 7c 01 00 00    	jne    f01032aa <debuginfo_eip+0x1f1>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010312e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103135:	c7 c0 b8 51 10 f0    	mov    $0xf01051b8,%eax
f010313b:	c7 c2 c4 c3 10 f0    	mov    $0xf010c3c4,%edx
f0103141:	29 c2                	sub    %eax,%edx
f0103143:	c1 fa 02             	sar    $0x2,%edx
f0103146:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010314c:	83 ea 01             	sub    $0x1,%edx
f010314f:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103152:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103155:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103158:	83 ec 08             	sub    $0x8,%esp
f010315b:	53                   	push   %ebx
f010315c:	6a 64                	push   $0x64
f010315e:	e8 61 fe ff ff       	call   f0102fc4 <stab_binsearch>
	if (lfile == 0)
f0103163:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103166:	83 c4 10             	add    $0x10,%esp
f0103169:	85 c0                	test   %eax,%eax
f010316b:	0f 84 40 01 00 00    	je     f01032b1 <debuginfo_eip+0x1f8>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103171:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103174:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103177:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010317a:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010317d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103180:	83 ec 08             	sub    $0x8,%esp
f0103183:	53                   	push   %ebx
f0103184:	6a 24                	push   $0x24
f0103186:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0103189:	c7 c0 b8 51 10 f0    	mov    $0xf01051b8,%eax
f010318f:	e8 30 fe ff ff       	call   f0102fc4 <stab_binsearch>

	if (lfun <= rfun) {
f0103194:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0103197:	83 c4 10             	add    $0x10,%esp
f010319a:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f010319d:	7f 79                	jg     f0103218 <debuginfo_eip+0x15f>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010319f:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01031a2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01031a5:	c7 c2 b8 51 10 f0    	mov    $0xf01051b8,%edx
f01031ab:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f01031ae:	8b 11                	mov    (%ecx),%edx
f01031b0:	c7 c0 2f e2 10 f0    	mov    $0xf010e22f,%eax
f01031b6:	81 e8 c5 c3 10 f0    	sub    $0xf010c3c5,%eax
f01031bc:	39 c2                	cmp    %eax,%edx
f01031be:	73 09                	jae    f01031c9 <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01031c0:	81 c2 c5 c3 10 f0    	add    $0xf010c3c5,%edx
f01031c6:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01031c9:	8b 41 08             	mov    0x8(%ecx),%eax
f01031cc:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01031cf:	83 ec 08             	sub    $0x8,%esp
f01031d2:	6a 3a                	push   $0x3a
f01031d4:	ff 77 08             	pushl  0x8(%edi)
f01031d7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01031da:	e8 b2 09 00 00       	call   f0103b91 <strfind>
f01031df:	2b 47 08             	sub    0x8(%edi),%eax
f01031e2:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01031e5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01031e8:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01031eb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01031ee:	c7 c2 b8 51 10 f0    	mov    $0xf01051b8,%edx
f01031f4:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f01031f8:	83 c4 10             	add    $0x10,%esp
f01031fb:	eb 29                	jmp    f0103226 <debuginfo_eip+0x16d>
  	        panic("User address");
f01031fd:	83 ec 04             	sub    $0x4,%esp
f0103200:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103203:	8d 83 a2 cc fe ff    	lea    -0x1335e(%ebx),%eax
f0103209:	50                   	push   %eax
f010320a:	6a 7f                	push   $0x7f
f010320c:	8d 83 af cc fe ff    	lea    -0x13351(%ebx),%eax
f0103212:	50                   	push   %eax
f0103213:	e8 85 ce ff ff       	call   f010009d <_panic>
		info->eip_fn_addr = addr;
f0103218:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f010321b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010321e:	eb af                	jmp    f01031cf <debuginfo_eip+0x116>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103220:	83 ee 01             	sub    $0x1,%esi
f0103223:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0103226:	39 f3                	cmp    %esi,%ebx
f0103228:	7f 3a                	jg     f0103264 <debuginfo_eip+0x1ab>
	       && stabs[lline].n_type != N_SOL
f010322a:	0f b6 10             	movzbl (%eax),%edx
f010322d:	80 fa 84             	cmp    $0x84,%dl
f0103230:	74 0b                	je     f010323d <debuginfo_eip+0x184>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103232:	80 fa 64             	cmp    $0x64,%dl
f0103235:	75 e9                	jne    f0103220 <debuginfo_eip+0x167>
f0103237:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f010323b:	74 e3                	je     f0103220 <debuginfo_eip+0x167>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010323d:	8d 14 76             	lea    (%esi,%esi,2),%edx
f0103240:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103243:	c7 c0 b8 51 10 f0    	mov    $0xf01051b8,%eax
f0103249:	8b 14 90             	mov    (%eax,%edx,4),%edx
f010324c:	c7 c0 2f e2 10 f0    	mov    $0xf010e22f,%eax
f0103252:	81 e8 c5 c3 10 f0    	sub    $0xf010c3c5,%eax
f0103258:	39 c2                	cmp    %eax,%edx
f010325a:	73 08                	jae    f0103264 <debuginfo_eip+0x1ab>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010325c:	81 c2 c5 c3 10 f0    	add    $0xf010c3c5,%edx
f0103262:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103264:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103267:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010326a:	ba 00 00 00 00       	mov    $0x0,%edx
	if (lfun < rfun)
f010326f:	39 c8                	cmp    %ecx,%eax
f0103271:	7d 4a                	jge    f01032bd <debuginfo_eip+0x204>
		for (lline = lfun + 1;
f0103273:	8d 50 01             	lea    0x1(%eax),%edx
f0103276:	8d 1c 40             	lea    (%eax,%eax,2),%ebx
f0103279:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010327c:	c7 c0 b8 51 10 f0    	mov    $0xf01051b8,%eax
f0103282:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0103286:	eb 07                	jmp    f010328f <debuginfo_eip+0x1d6>
			info->eip_fn_narg++;
f0103288:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f010328c:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f010328f:	39 d1                	cmp    %edx,%ecx
f0103291:	74 25                	je     f01032b8 <debuginfo_eip+0x1ff>
f0103293:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103296:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f010329a:	74 ec                	je     f0103288 <debuginfo_eip+0x1cf>
	return 0;
f010329c:	ba 00 00 00 00       	mov    $0x0,%edx
f01032a1:	eb 1a                	jmp    f01032bd <debuginfo_eip+0x204>
		return -1;
f01032a3:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01032a8:	eb 13                	jmp    f01032bd <debuginfo_eip+0x204>
f01032aa:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01032af:	eb 0c                	jmp    f01032bd <debuginfo_eip+0x204>
		return -1;
f01032b1:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01032b6:	eb 05                	jmp    f01032bd <debuginfo_eip+0x204>
	return 0;
f01032b8:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01032bd:	89 d0                	mov    %edx,%eax
f01032bf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01032c2:	5b                   	pop    %ebx
f01032c3:	5e                   	pop    %esi
f01032c4:	5f                   	pop    %edi
f01032c5:	5d                   	pop    %ebp
f01032c6:	c3                   	ret    

f01032c7 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01032c7:	55                   	push   %ebp
f01032c8:	89 e5                	mov    %esp,%ebp
f01032ca:	57                   	push   %edi
f01032cb:	56                   	push   %esi
f01032cc:	53                   	push   %ebx
f01032cd:	83 ec 2c             	sub    $0x2c,%esp
f01032d0:	e8 38 fc ff ff       	call   f0102f0d <__x86.get_pc_thunk.cx>
f01032d5:	81 c1 33 50 01 00    	add    $0x15033,%ecx
f01032db:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01032de:	89 c7                	mov    %eax,%edi
f01032e0:	89 d6                	mov    %edx,%esi
f01032e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01032e5:	8b 55 0c             	mov    0xc(%ebp),%edx
f01032e8:	89 d1                	mov    %edx,%ecx
f01032ea:	89 c2                	mov    %eax,%edx
f01032ec:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01032ef:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01032f2:	8b 45 10             	mov    0x10(%ebp),%eax
f01032f5:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01032f8:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01032fb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0103302:	39 c2                	cmp    %eax,%edx
f0103304:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f0103307:	72 41                	jb     f010334a <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103309:	83 ec 0c             	sub    $0xc,%esp
f010330c:	ff 75 18             	pushl  0x18(%ebp)
f010330f:	83 eb 01             	sub    $0x1,%ebx
f0103312:	53                   	push   %ebx
f0103313:	50                   	push   %eax
f0103314:	83 ec 08             	sub    $0x8,%esp
f0103317:	ff 75 e4             	pushl  -0x1c(%ebp)
f010331a:	ff 75 e0             	pushl  -0x20(%ebp)
f010331d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103320:	ff 75 d0             	pushl  -0x30(%ebp)
f0103323:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103326:	e8 95 0a 00 00       	call   f0103dc0 <__udivdi3>
f010332b:	83 c4 18             	add    $0x18,%esp
f010332e:	52                   	push   %edx
f010332f:	50                   	push   %eax
f0103330:	89 f2                	mov    %esi,%edx
f0103332:	89 f8                	mov    %edi,%eax
f0103334:	e8 8e ff ff ff       	call   f01032c7 <printnum>
f0103339:	83 c4 20             	add    $0x20,%esp
f010333c:	eb 13                	jmp    f0103351 <printnum+0x8a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010333e:	83 ec 08             	sub    $0x8,%esp
f0103341:	56                   	push   %esi
f0103342:	ff 75 18             	pushl  0x18(%ebp)
f0103345:	ff d7                	call   *%edi
f0103347:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f010334a:	83 eb 01             	sub    $0x1,%ebx
f010334d:	85 db                	test   %ebx,%ebx
f010334f:	7f ed                	jg     f010333e <printnum+0x77>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103351:	83 ec 08             	sub    $0x8,%esp
f0103354:	56                   	push   %esi
f0103355:	83 ec 04             	sub    $0x4,%esp
f0103358:	ff 75 e4             	pushl  -0x1c(%ebp)
f010335b:	ff 75 e0             	pushl  -0x20(%ebp)
f010335e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103361:	ff 75 d0             	pushl  -0x30(%ebp)
f0103364:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103367:	e8 64 0b 00 00       	call   f0103ed0 <__umoddi3>
f010336c:	83 c4 14             	add    $0x14,%esp
f010336f:	0f be 84 03 bd cc fe 	movsbl -0x13343(%ebx,%eax,1),%eax
f0103376:	ff 
f0103377:	50                   	push   %eax
f0103378:	ff d7                	call   *%edi
}
f010337a:	83 c4 10             	add    $0x10,%esp
f010337d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103380:	5b                   	pop    %ebx
f0103381:	5e                   	pop    %esi
f0103382:	5f                   	pop    %edi
f0103383:	5d                   	pop    %ebp
f0103384:	c3                   	ret    

f0103385 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103385:	f3 0f 1e fb          	endbr32 
f0103389:	55                   	push   %ebp
f010338a:	89 e5                	mov    %esp,%ebp
f010338c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010338f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103393:	8b 10                	mov    (%eax),%edx
f0103395:	3b 50 04             	cmp    0x4(%eax),%edx
f0103398:	73 0a                	jae    f01033a4 <sprintputch+0x1f>
		*b->buf++ = ch;
f010339a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010339d:	89 08                	mov    %ecx,(%eax)
f010339f:	8b 45 08             	mov    0x8(%ebp),%eax
f01033a2:	88 02                	mov    %al,(%edx)
}
f01033a4:	5d                   	pop    %ebp
f01033a5:	c3                   	ret    

f01033a6 <printfmt>:
{
f01033a6:	f3 0f 1e fb          	endbr32 
f01033aa:	55                   	push   %ebp
f01033ab:	89 e5                	mov    %esp,%ebp
f01033ad:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f01033b0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01033b3:	50                   	push   %eax
f01033b4:	ff 75 10             	pushl  0x10(%ebp)
f01033b7:	ff 75 0c             	pushl  0xc(%ebp)
f01033ba:	ff 75 08             	pushl  0x8(%ebp)
f01033bd:	e8 05 00 00 00       	call   f01033c7 <vprintfmt>
}
f01033c2:	83 c4 10             	add    $0x10,%esp
f01033c5:	c9                   	leave  
f01033c6:	c3                   	ret    

f01033c7 <vprintfmt>:
{
f01033c7:	f3 0f 1e fb          	endbr32 
f01033cb:	55                   	push   %ebp
f01033cc:	89 e5                	mov    %esp,%ebp
f01033ce:	57                   	push   %edi
f01033cf:	56                   	push   %esi
f01033d0:	53                   	push   %ebx
f01033d1:	83 ec 3c             	sub    $0x3c,%esp
f01033d4:	e8 36 d3 ff ff       	call   f010070f <__x86.get_pc_thunk.ax>
f01033d9:	05 2f 4f 01 00       	add    $0x14f2f,%eax
f01033de:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01033e1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01033e4:	8b 7d 10             	mov    0x10(%ebp),%edi
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01033e7:	8d 80 3c 1d 00 00    	lea    0x1d3c(%eax),%eax
f01033ed:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01033f0:	e9 d4 03 00 00       	jmp    f01037c9 <.L25+0x48>
		padc = ' ';
f01033f5:	c6 45 cc 20          	movb   $0x20,-0x34(%ebp)
		altflag = 0;
f01033f9:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
		precision = -1;
f0103400:	c7 45 c8 ff ff ff ff 	movl   $0xffffffff,-0x38(%ebp)
		width = -1;
f0103407:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		lflag = 0;
f010340e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103413:	89 5d d8             	mov    %ebx,-0x28(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103416:	8d 47 01             	lea    0x1(%edi),%eax
f0103419:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010341c:	0f b6 17             	movzbl (%edi),%edx
f010341f:	8d 42 dd             	lea    -0x23(%edx),%eax
f0103422:	3c 55                	cmp    $0x55,%al
f0103424:	0f 87 27 04 00 00    	ja     f0103851 <.L20>
f010342a:	0f b6 c0             	movzbl %al,%eax
f010342d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103430:	89 cb                	mov    %ecx,%ebx
f0103432:	03 9c 81 48 cd fe ff 	add    -0x132b8(%ecx,%eax,4),%ebx
f0103439:	3e ff e3             	notrack jmp *%ebx

f010343c <.L68>:
f010343c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f010343f:	c6 45 cc 2d          	movb   $0x2d,-0x34(%ebp)
f0103443:	eb d1                	jmp    f0103416 <vprintfmt+0x4f>

f0103445 <.L32>:
		switch (ch = *(unsigned char *) fmt++) {
f0103445:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103448:	c6 45 cc 30          	movb   $0x30,-0x34(%ebp)
f010344c:	eb c8                	jmp    f0103416 <vprintfmt+0x4f>

f010344e <.L31>:
f010344e:	0f b6 d2             	movzbl %dl,%edx
f0103451:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0103454:	b8 00 00 00 00       	mov    $0x0,%eax
f0103459:	8b 4d d8             	mov    -0x28(%ebp),%ecx
				precision = precision * 10 + ch - '0';
f010345c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010345f:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103463:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103466:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0103469:	83 fb 09             	cmp    $0x9,%ebx
f010346c:	77 58                	ja     f01034c6 <.L36+0xf>
			for (precision = 0; ; ++fmt) {
f010346e:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0103471:	eb e9                	jmp    f010345c <.L31+0xe>

f0103473 <.L34>:
			precision = va_arg(ap, int);
f0103473:	8b 45 14             	mov    0x14(%ebp),%eax
f0103476:	8b 00                	mov    (%eax),%eax
f0103478:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010347b:	8b 45 14             	mov    0x14(%ebp),%eax
f010347e:	8d 40 04             	lea    0x4(%eax),%eax
f0103481:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103484:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0103487:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010348b:	79 89                	jns    f0103416 <vprintfmt+0x4f>
				width = precision, precision = -1;
f010348d:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0103490:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103493:	c7 45 c8 ff ff ff ff 	movl   $0xffffffff,-0x38(%ebp)
f010349a:	e9 77 ff ff ff       	jmp    f0103416 <vprintfmt+0x4f>

f010349f <.L33>:
f010349f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01034a2:	85 c0                	test   %eax,%eax
f01034a4:	ba 00 00 00 00       	mov    $0x0,%edx
f01034a9:	0f 49 d0             	cmovns %eax,%edx
f01034ac:	89 55 dc             	mov    %edx,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01034af:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f01034b2:	e9 5f ff ff ff       	jmp    f0103416 <vprintfmt+0x4f>

f01034b7 <.L36>:
		switch (ch = *(unsigned char *) fmt++) {
f01034b7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f01034ba:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f01034c1:	e9 50 ff ff ff       	jmp    f0103416 <vprintfmt+0x4f>
f01034c6:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f01034c9:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01034cc:	eb b9                	jmp    f0103487 <.L34+0x14>

f01034ce <.L27>:
			lflag++;
f01034ce:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01034d2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f01034d5:	e9 3c ff ff ff       	jmp    f0103416 <vprintfmt+0x4f>

f01034da <.L30>:
			putch(va_arg(ap, int), putdat);
f01034da:	8b 45 14             	mov    0x14(%ebp),%eax
f01034dd:	8d 58 04             	lea    0x4(%eax),%ebx
f01034e0:	83 ec 08             	sub    $0x8,%esp
f01034e3:	56                   	push   %esi
f01034e4:	ff 30                	pushl  (%eax)
f01034e6:	ff 55 08             	call   *0x8(%ebp)
			break;
f01034e9:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01034ec:	89 5d 14             	mov    %ebx,0x14(%ebp)
			break;
f01034ef:	e9 d2 02 00 00       	jmp    f01037c6 <.L25+0x45>

f01034f4 <.L28>:
			err = va_arg(ap, int);
f01034f4:	8b 45 14             	mov    0x14(%ebp),%eax
f01034f7:	8d 58 04             	lea    0x4(%eax),%ebx
f01034fa:	8b 00                	mov    (%eax),%eax
f01034fc:	99                   	cltd   
f01034fd:	31 d0                	xor    %edx,%eax
f01034ff:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103501:	83 f8 06             	cmp    $0x6,%eax
f0103504:	7f 29                	jg     f010352f <.L28+0x3b>
f0103506:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0103509:	8b 14 82             	mov    (%edx,%eax,4),%edx
f010350c:	85 d2                	test   %edx,%edx
f010350e:	74 1f                	je     f010352f <.L28+0x3b>
				printfmt(putch, putdat, "%s", p);
f0103510:	52                   	push   %edx
f0103511:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103514:	8d 80 ed c9 fe ff    	lea    -0x13613(%eax),%eax
f010351a:	50                   	push   %eax
f010351b:	56                   	push   %esi
f010351c:	ff 75 08             	pushl  0x8(%ebp)
f010351f:	e8 82 fe ff ff       	call   f01033a6 <printfmt>
f0103524:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103527:	89 5d 14             	mov    %ebx,0x14(%ebp)
f010352a:	e9 97 02 00 00       	jmp    f01037c6 <.L25+0x45>
				printfmt(putch, putdat, "error %d", err);
f010352f:	50                   	push   %eax
f0103530:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103533:	8d 80 d5 cc fe ff    	lea    -0x1332b(%eax),%eax
f0103539:	50                   	push   %eax
f010353a:	56                   	push   %esi
f010353b:	ff 75 08             	pushl  0x8(%ebp)
f010353e:	e8 63 fe ff ff       	call   f01033a6 <printfmt>
f0103543:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103546:	89 5d 14             	mov    %ebx,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0103549:	e9 78 02 00 00       	jmp    f01037c6 <.L25+0x45>

f010354e <.L24>:
			if ((p = va_arg(ap, char *)) == NULL)
f010354e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103551:	83 c0 04             	add    $0x4,%eax
f0103554:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103557:	8b 45 14             	mov    0x14(%ebp),%eax
f010355a:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010355c:	85 ff                	test   %edi,%edi
f010355e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103561:	8d 80 ce cc fe ff    	lea    -0x13332(%eax),%eax
f0103567:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010356a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010356e:	7e 06                	jle    f0103576 <.L24+0x28>
f0103570:	80 7d cc 2d          	cmpb   $0x2d,-0x34(%ebp)
f0103574:	75 0d                	jne    f0103583 <.L24+0x35>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103576:	89 fb                	mov    %edi,%ebx
f0103578:	03 7d dc             	add    -0x24(%ebp),%edi
f010357b:	89 7d dc             	mov    %edi,-0x24(%ebp)
f010357e:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0103581:	eb 5b                	jmp    f01035de <.L24+0x90>
f0103583:	83 ec 08             	sub    $0x8,%esp
f0103586:	ff 75 c8             	pushl  -0x38(%ebp)
f0103589:	57                   	push   %edi
f010358a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010358d:	e8 8e 04 00 00       	call   f0103a20 <strnlen>
f0103592:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103595:	29 c2                	sub    %eax,%edx
f0103597:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010359a:	83 c4 10             	add    $0x10,%esp
f010359d:	89 d3                	mov    %edx,%ebx
					putch(padc, putdat);
f010359f:	0f be 45 cc          	movsbl -0x34(%ebp),%eax
f01035a3:	89 7d cc             	mov    %edi,-0x34(%ebp)
f01035a6:	89 c7                	mov    %eax,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f01035a8:	85 db                	test   %ebx,%ebx
f01035aa:	7e 10                	jle    f01035bc <.L24+0x6e>
					putch(padc, putdat);
f01035ac:	83 ec 08             	sub    $0x8,%esp
f01035af:	56                   	push   %esi
f01035b0:	57                   	push   %edi
f01035b1:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f01035b4:	83 eb 01             	sub    $0x1,%ebx
f01035b7:	83 c4 10             	add    $0x10,%esp
f01035ba:	eb ec                	jmp    f01035a8 <.L24+0x5a>
f01035bc:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01035bf:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01035c2:	85 d2                	test   %edx,%edx
f01035c4:	b8 00 00 00 00       	mov    $0x0,%eax
f01035c9:	0f 49 c2             	cmovns %edx,%eax
f01035cc:	29 c2                	sub    %eax,%edx
f01035ce:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01035d1:	eb a3                	jmp    f0103576 <.L24+0x28>
					putch(ch, putdat);
f01035d3:	83 ec 08             	sub    $0x8,%esp
f01035d6:	56                   	push   %esi
f01035d7:	52                   	push   %edx
f01035d8:	ff 55 08             	call   *0x8(%ebp)
f01035db:	83 c4 10             	add    $0x10,%esp
f01035de:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01035e1:	29 d9                	sub    %ebx,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01035e3:	83 c3 01             	add    $0x1,%ebx
f01035e6:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f01035ea:	0f be d0             	movsbl %al,%edx
f01035ed:	85 d2                	test   %edx,%edx
f01035ef:	74 4f                	je     f0103640 <.L24+0xf2>
f01035f1:	85 ff                	test   %edi,%edi
f01035f3:	78 05                	js     f01035fa <.L24+0xac>
f01035f5:	83 ef 01             	sub    $0x1,%edi
f01035f8:	78 1f                	js     f0103619 <.L24+0xcb>
				if (altflag && (ch < ' ' || ch > '~'))
f01035fa:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01035fe:	74 d3                	je     f01035d3 <.L24+0x85>
f0103600:	0f be c0             	movsbl %al,%eax
f0103603:	83 e8 20             	sub    $0x20,%eax
f0103606:	83 f8 5e             	cmp    $0x5e,%eax
f0103609:	76 c8                	jbe    f01035d3 <.L24+0x85>
					putch('?', putdat);
f010360b:	83 ec 08             	sub    $0x8,%esp
f010360e:	56                   	push   %esi
f010360f:	6a 3f                	push   $0x3f
f0103611:	ff 55 08             	call   *0x8(%ebp)
f0103614:	83 c4 10             	add    $0x10,%esp
f0103617:	eb c5                	jmp    f01035de <.L24+0x90>
f0103619:	89 cf                	mov    %ecx,%edi
f010361b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010361e:	eb 0e                	jmp    f010362e <.L24+0xe0>
				putch(' ', putdat);
f0103620:	83 ec 08             	sub    $0x8,%esp
f0103623:	56                   	push   %esi
f0103624:	6a 20                	push   $0x20
f0103626:	ff d3                	call   *%ebx
			for (; width > 0; width--)
f0103628:	83 ef 01             	sub    $0x1,%edi
f010362b:	83 c4 10             	add    $0x10,%esp
f010362e:	85 ff                	test   %edi,%edi
f0103630:	7f ee                	jg     f0103620 <.L24+0xd2>
f0103632:	89 5d 08             	mov    %ebx,0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
f0103635:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103638:	89 45 14             	mov    %eax,0x14(%ebp)
f010363b:	e9 86 01 00 00       	jmp    f01037c6 <.L25+0x45>
f0103640:	89 cf                	mov    %ecx,%edi
f0103642:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103645:	eb e7                	jmp    f010362e <.L24+0xe0>

f0103647 <.L29>:
f0103647:	8b 5d d8             	mov    -0x28(%ebp),%ebx
	if (lflag >= 2)
f010364a:	83 fb 01             	cmp    $0x1,%ebx
f010364d:	7f 1b                	jg     f010366a <.L29+0x23>
	else if (lflag)
f010364f:	85 db                	test   %ebx,%ebx
f0103651:	74 64                	je     f01036b7 <.L29+0x70>
		return va_arg(*ap, long);
f0103653:	8b 45 14             	mov    0x14(%ebp),%eax
f0103656:	8b 00                	mov    (%eax),%eax
f0103658:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010365b:	99                   	cltd   
f010365c:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010365f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103662:	8d 40 04             	lea    0x4(%eax),%eax
f0103665:	89 45 14             	mov    %eax,0x14(%ebp)
f0103668:	eb 17                	jmp    f0103681 <.L29+0x3a>
		return va_arg(*ap, long long);
f010366a:	8b 45 14             	mov    0x14(%ebp),%eax
f010366d:	8b 50 04             	mov    0x4(%eax),%edx
f0103670:	8b 00                	mov    (%eax),%eax
f0103672:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103675:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103678:	8b 45 14             	mov    0x14(%ebp),%eax
f010367b:	8d 40 08             	lea    0x8(%eax),%eax
f010367e:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0103681:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0103684:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
			base = 10;
f0103687:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f010368c:	85 c9                	test   %ecx,%ecx
f010368e:	0f 89 17 01 00 00    	jns    f01037ab <.L25+0x2a>
				putch('-', putdat);
f0103694:	83 ec 08             	sub    $0x8,%esp
f0103697:	56                   	push   %esi
f0103698:	6a 2d                	push   $0x2d
f010369a:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010369d:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01036a0:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01036a3:	f7 da                	neg    %edx
f01036a5:	83 d1 00             	adc    $0x0,%ecx
f01036a8:	f7 d9                	neg    %ecx
f01036aa:	83 c4 10             	add    $0x10,%esp
			base = 10;
f01036ad:	b8 0a 00 00 00       	mov    $0xa,%eax
f01036b2:	e9 f4 00 00 00       	jmp    f01037ab <.L25+0x2a>
		return va_arg(*ap, int);
f01036b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01036ba:	8b 00                	mov    (%eax),%eax
f01036bc:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01036bf:	99                   	cltd   
f01036c0:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01036c3:	8b 45 14             	mov    0x14(%ebp),%eax
f01036c6:	8d 40 04             	lea    0x4(%eax),%eax
f01036c9:	89 45 14             	mov    %eax,0x14(%ebp)
f01036cc:	eb b3                	jmp    f0103681 <.L29+0x3a>

f01036ce <.L23>:
f01036ce:	8b 5d d8             	mov    -0x28(%ebp),%ebx
	if (lflag >= 2)
f01036d1:	83 fb 01             	cmp    $0x1,%ebx
f01036d4:	7f 1e                	jg     f01036f4 <.L23+0x26>
	else if (lflag)
f01036d6:	85 db                	test   %ebx,%ebx
f01036d8:	74 32                	je     f010370c <.L23+0x3e>
		return va_arg(*ap, unsigned long);
f01036da:	8b 45 14             	mov    0x14(%ebp),%eax
f01036dd:	8b 10                	mov    (%eax),%edx
f01036df:	b9 00 00 00 00       	mov    $0x0,%ecx
f01036e4:	8d 40 04             	lea    0x4(%eax),%eax
f01036e7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01036ea:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long);
f01036ef:	e9 b7 00 00 00       	jmp    f01037ab <.L25+0x2a>
		return va_arg(*ap, unsigned long long);
f01036f4:	8b 45 14             	mov    0x14(%ebp),%eax
f01036f7:	8b 10                	mov    (%eax),%edx
f01036f9:	8b 48 04             	mov    0x4(%eax),%ecx
f01036fc:	8d 40 08             	lea    0x8(%eax),%eax
f01036ff:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103702:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long long);
f0103707:	e9 9f 00 00 00       	jmp    f01037ab <.L25+0x2a>
		return va_arg(*ap, unsigned int);
f010370c:	8b 45 14             	mov    0x14(%ebp),%eax
f010370f:	8b 10                	mov    (%eax),%edx
f0103711:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103716:	8d 40 04             	lea    0x4(%eax),%eax
f0103719:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010371c:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned int);
f0103721:	e9 85 00 00 00       	jmp    f01037ab <.L25+0x2a>

f0103726 <.L26>:
f0103726:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			putch('0',putdat);
f0103729:	83 ec 08             	sub    $0x8,%esp
f010372c:	56                   	push   %esi
f010372d:	6a 30                	push   $0x30
f010372f:	ff 55 08             	call   *0x8(%ebp)
	if (lflag >= 2)
f0103732:	83 c4 10             	add    $0x10,%esp
f0103735:	83 fb 01             	cmp    $0x1,%ebx
f0103738:	7f 1b                	jg     f0103755 <.L26+0x2f>
	else if (lflag)
f010373a:	85 db                	test   %ebx,%ebx
f010373c:	74 2c                	je     f010376a <.L26+0x44>
		return va_arg(*ap, unsigned long);
f010373e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103741:	8b 10                	mov    (%eax),%edx
f0103743:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103748:	8d 40 04             	lea    0x4(%eax),%eax
f010374b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010374e:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long);
f0103753:	eb 56                	jmp    f01037ab <.L25+0x2a>
		return va_arg(*ap, unsigned long long);
f0103755:	8b 45 14             	mov    0x14(%ebp),%eax
f0103758:	8b 10                	mov    (%eax),%edx
f010375a:	8b 48 04             	mov    0x4(%eax),%ecx
f010375d:	8d 40 08             	lea    0x8(%eax),%eax
f0103760:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103763:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long long);
f0103768:	eb 41                	jmp    f01037ab <.L25+0x2a>
		return va_arg(*ap, unsigned int);
f010376a:	8b 45 14             	mov    0x14(%ebp),%eax
f010376d:	8b 10                	mov    (%eax),%edx
f010376f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103774:	8d 40 04             	lea    0x4(%eax),%eax
f0103777:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010377a:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned int);
f010377f:	eb 2a                	jmp    f01037ab <.L25+0x2a>

f0103781 <.L25>:
			putch('0', putdat);
f0103781:	83 ec 08             	sub    $0x8,%esp
f0103784:	56                   	push   %esi
f0103785:	6a 30                	push   $0x30
f0103787:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010378a:	83 c4 08             	add    $0x8,%esp
f010378d:	56                   	push   %esi
f010378e:	6a 78                	push   $0x78
f0103790:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0103793:	8b 45 14             	mov    0x14(%ebp),%eax
f0103796:	8b 10                	mov    (%eax),%edx
f0103798:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010379d:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f01037a0:	8d 40 04             	lea    0x4(%eax),%eax
f01037a3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01037a6:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f01037ab:	83 ec 0c             	sub    $0xc,%esp
f01037ae:	0f be 5d cc          	movsbl -0x34(%ebp),%ebx
f01037b2:	53                   	push   %ebx
f01037b3:	ff 75 dc             	pushl  -0x24(%ebp)
f01037b6:	50                   	push   %eax
f01037b7:	51                   	push   %ecx
f01037b8:	52                   	push   %edx
f01037b9:	89 f2                	mov    %esi,%edx
f01037bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01037be:	e8 04 fb ff ff       	call   f01032c7 <printnum>
			break;
f01037c3:	83 c4 20             	add    $0x20,%esp
			if ((p = va_arg(ap, char *)) == NULL)
f01037c6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01037c9:	83 c7 01             	add    $0x1,%edi
f01037cc:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01037d0:	83 f8 25             	cmp    $0x25,%eax
f01037d3:	0f 84 1c fc ff ff    	je     f01033f5 <vprintfmt+0x2e>
			if (ch == '\0')
f01037d9:	85 c0                	test   %eax,%eax
f01037db:	0f 84 91 00 00 00    	je     f0103872 <.L20+0x21>
			putch(ch, putdat);
f01037e1:	83 ec 08             	sub    $0x8,%esp
f01037e4:	56                   	push   %esi
f01037e5:	50                   	push   %eax
f01037e6:	ff 55 08             	call   *0x8(%ebp)
f01037e9:	83 c4 10             	add    $0x10,%esp
f01037ec:	eb db                	jmp    f01037c9 <.L25+0x48>

f01037ee <.L21>:
f01037ee:	8b 5d d8             	mov    -0x28(%ebp),%ebx
	if (lflag >= 2)
f01037f1:	83 fb 01             	cmp    $0x1,%ebx
f01037f4:	7f 1b                	jg     f0103811 <.L21+0x23>
	else if (lflag)
f01037f6:	85 db                	test   %ebx,%ebx
f01037f8:	74 2c                	je     f0103826 <.L21+0x38>
		return va_arg(*ap, unsigned long);
f01037fa:	8b 45 14             	mov    0x14(%ebp),%eax
f01037fd:	8b 10                	mov    (%eax),%edx
f01037ff:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103804:	8d 40 04             	lea    0x4(%eax),%eax
f0103807:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010380a:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long);
f010380f:	eb 9a                	jmp    f01037ab <.L25+0x2a>
		return va_arg(*ap, unsigned long long);
f0103811:	8b 45 14             	mov    0x14(%ebp),%eax
f0103814:	8b 10                	mov    (%eax),%edx
f0103816:	8b 48 04             	mov    0x4(%eax),%ecx
f0103819:	8d 40 08             	lea    0x8(%eax),%eax
f010381c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010381f:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long long);
f0103824:	eb 85                	jmp    f01037ab <.L25+0x2a>
		return va_arg(*ap, unsigned int);
f0103826:	8b 45 14             	mov    0x14(%ebp),%eax
f0103829:	8b 10                	mov    (%eax),%edx
f010382b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103830:	8d 40 04             	lea    0x4(%eax),%eax
f0103833:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103836:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned int);
f010383b:	e9 6b ff ff ff       	jmp    f01037ab <.L25+0x2a>

f0103840 <.L35>:
			putch(ch, putdat);
f0103840:	83 ec 08             	sub    $0x8,%esp
f0103843:	56                   	push   %esi
f0103844:	6a 25                	push   $0x25
f0103846:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103849:	83 c4 10             	add    $0x10,%esp
f010384c:	e9 75 ff ff ff       	jmp    f01037c6 <.L25+0x45>

f0103851 <.L20>:
			putch('%', putdat);
f0103851:	83 ec 08             	sub    $0x8,%esp
f0103854:	56                   	push   %esi
f0103855:	6a 25                	push   $0x25
f0103857:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010385a:	83 c4 10             	add    $0x10,%esp
f010385d:	89 f8                	mov    %edi,%eax
f010385f:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0103863:	74 05                	je     f010386a <.L20+0x19>
f0103865:	83 e8 01             	sub    $0x1,%eax
f0103868:	eb f5                	jmp    f010385f <.L20+0xe>
f010386a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010386d:	e9 54 ff ff ff       	jmp    f01037c6 <.L25+0x45>
}
f0103872:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103875:	5b                   	pop    %ebx
f0103876:	5e                   	pop    %esi
f0103877:	5f                   	pop    %edi
f0103878:	5d                   	pop    %ebp
f0103879:	c3                   	ret    

f010387a <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010387a:	f3 0f 1e fb          	endbr32 
f010387e:	55                   	push   %ebp
f010387f:	89 e5                	mov    %esp,%ebp
f0103881:	53                   	push   %ebx
f0103882:	83 ec 14             	sub    $0x14,%esp
f0103885:	e8 d1 c8 ff ff       	call   f010015b <__x86.get_pc_thunk.bx>
f010388a:	81 c3 7e 4a 01 00    	add    $0x14a7e,%ebx
f0103890:	8b 45 08             	mov    0x8(%ebp),%eax
f0103893:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103896:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103899:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010389d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01038a0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01038a7:	85 c0                	test   %eax,%eax
f01038a9:	74 2b                	je     f01038d6 <vsnprintf+0x5c>
f01038ab:	85 d2                	test   %edx,%edx
f01038ad:	7e 27                	jle    f01038d6 <vsnprintf+0x5c>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01038af:	ff 75 14             	pushl  0x14(%ebp)
f01038b2:	ff 75 10             	pushl  0x10(%ebp)
f01038b5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01038b8:	50                   	push   %eax
f01038b9:	8d 83 7d b0 fe ff    	lea    -0x14f83(%ebx),%eax
f01038bf:	50                   	push   %eax
f01038c0:	e8 02 fb ff ff       	call   f01033c7 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01038c5:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01038c8:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01038cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01038ce:	83 c4 10             	add    $0x10,%esp
}
f01038d1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01038d4:	c9                   	leave  
f01038d5:	c3                   	ret    
		return -E_INVAL;
f01038d6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01038db:	eb f4                	jmp    f01038d1 <vsnprintf+0x57>

f01038dd <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01038dd:	f3 0f 1e fb          	endbr32 
f01038e1:	55                   	push   %ebp
f01038e2:	89 e5                	mov    %esp,%ebp
f01038e4:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01038e7:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01038ea:	50                   	push   %eax
f01038eb:	ff 75 10             	pushl  0x10(%ebp)
f01038ee:	ff 75 0c             	pushl  0xc(%ebp)
f01038f1:	ff 75 08             	pushl  0x8(%ebp)
f01038f4:	e8 81 ff ff ff       	call   f010387a <vsnprintf>
	va_end(ap);

	return rc;
}
f01038f9:	c9                   	leave  
f01038fa:	c3                   	ret    

f01038fb <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01038fb:	f3 0f 1e fb          	endbr32 
f01038ff:	55                   	push   %ebp
f0103900:	89 e5                	mov    %esp,%ebp
f0103902:	57                   	push   %edi
f0103903:	56                   	push   %esi
f0103904:	53                   	push   %ebx
f0103905:	83 ec 1c             	sub    $0x1c,%esp
f0103908:	e8 4e c8 ff ff       	call   f010015b <__x86.get_pc_thunk.bx>
f010390d:	81 c3 fb 49 01 00    	add    $0x149fb,%ebx
f0103913:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103916:	85 c0                	test   %eax,%eax
f0103918:	74 13                	je     f010392d <readline+0x32>
		cprintf("%s", prompt);
f010391a:	83 ec 08             	sub    $0x8,%esp
f010391d:	50                   	push   %eax
f010391e:	8d 83 ed c9 fe ff    	lea    -0x13613(%ebx),%eax
f0103924:	50                   	push   %eax
f0103925:	e8 82 f6 ff ff       	call   f0102fac <cprintf>
f010392a:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010392d:	83 ec 0c             	sub    $0xc,%esp
f0103930:	6a 00                	push   $0x0
f0103932:	e8 ce cd ff ff       	call   f0100705 <iscons>
f0103937:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010393a:	83 c4 10             	add    $0x10,%esp
	i = 0;
f010393d:	bf 00 00 00 00       	mov    $0x0,%edi
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
			if (echoing)
				cputchar(c);
			buf[i++] = c;
f0103942:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f0103948:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010394b:	eb 51                	jmp    f010399e <readline+0xa3>
			cprintf("read error: %e\n", c);
f010394d:	83 ec 08             	sub    $0x8,%esp
f0103950:	50                   	push   %eax
f0103951:	8d 83 a0 ce fe ff    	lea    -0x13160(%ebx),%eax
f0103957:	50                   	push   %eax
f0103958:	e8 4f f6 ff ff       	call   f0102fac <cprintf>
			return NULL;
f010395d:	83 c4 10             	add    $0x10,%esp
f0103960:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0103965:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103968:	5b                   	pop    %ebx
f0103969:	5e                   	pop    %esi
f010396a:	5f                   	pop    %edi
f010396b:	5d                   	pop    %ebp
f010396c:	c3                   	ret    
			if (echoing)
f010396d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103971:	75 05                	jne    f0103978 <readline+0x7d>
			i--;
f0103973:	83 ef 01             	sub    $0x1,%edi
f0103976:	eb 26                	jmp    f010399e <readline+0xa3>
				cputchar('\b');
f0103978:	83 ec 0c             	sub    $0xc,%esp
f010397b:	6a 08                	push   $0x8
f010397d:	e8 5a cd ff ff       	call   f01006dc <cputchar>
f0103982:	83 c4 10             	add    $0x10,%esp
f0103985:	eb ec                	jmp    f0103973 <readline+0x78>
				cputchar(c);
f0103987:	83 ec 0c             	sub    $0xc,%esp
f010398a:	56                   	push   %esi
f010398b:	e8 4c cd ff ff       	call   f01006dc <cputchar>
f0103990:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103993:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103996:	89 f0                	mov    %esi,%eax
f0103998:	88 04 39             	mov    %al,(%ecx,%edi,1)
f010399b:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f010399e:	e8 4d cd ff ff       	call   f01006f0 <getchar>
f01039a3:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f01039a5:	85 c0                	test   %eax,%eax
f01039a7:	78 a4                	js     f010394d <readline+0x52>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01039a9:	83 f8 08             	cmp    $0x8,%eax
f01039ac:	0f 94 c2             	sete   %dl
f01039af:	83 f8 7f             	cmp    $0x7f,%eax
f01039b2:	0f 94 c0             	sete   %al
f01039b5:	08 c2                	or     %al,%dl
f01039b7:	74 04                	je     f01039bd <readline+0xc2>
f01039b9:	85 ff                	test   %edi,%edi
f01039bb:	7f b0                	jg     f010396d <readline+0x72>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01039bd:	83 fe 1f             	cmp    $0x1f,%esi
f01039c0:	7e 10                	jle    f01039d2 <readline+0xd7>
f01039c2:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f01039c8:	7f 08                	jg     f01039d2 <readline+0xd7>
			if (echoing)
f01039ca:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01039ce:	74 c3                	je     f0103993 <readline+0x98>
f01039d0:	eb b5                	jmp    f0103987 <readline+0x8c>
		} else if (c == '\n' || c == '\r') {
f01039d2:	83 fe 0a             	cmp    $0xa,%esi
f01039d5:	74 05                	je     f01039dc <readline+0xe1>
f01039d7:	83 fe 0d             	cmp    $0xd,%esi
f01039da:	75 c2                	jne    f010399e <readline+0xa3>
			if (echoing)
f01039dc:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01039e0:	75 13                	jne    f01039f5 <readline+0xfa>
			buf[i] = 0;
f01039e2:	c6 84 3b b8 1f 00 00 	movb   $0x0,0x1fb8(%ebx,%edi,1)
f01039e9:	00 
			return buf;
f01039ea:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f01039f0:	e9 70 ff ff ff       	jmp    f0103965 <readline+0x6a>
				cputchar('\n');
f01039f5:	83 ec 0c             	sub    $0xc,%esp
f01039f8:	6a 0a                	push   $0xa
f01039fa:	e8 dd cc ff ff       	call   f01006dc <cputchar>
f01039ff:	83 c4 10             	add    $0x10,%esp
f0103a02:	eb de                	jmp    f01039e2 <readline+0xe7>

f0103a04 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103a04:	f3 0f 1e fb          	endbr32 
f0103a08:	55                   	push   %ebp
f0103a09:	89 e5                	mov    %esp,%ebp
f0103a0b:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103a0e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a13:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103a17:	74 05                	je     f0103a1e <strlen+0x1a>
		n++;
f0103a19:	83 c0 01             	add    $0x1,%eax
f0103a1c:	eb f5                	jmp    f0103a13 <strlen+0xf>
	return n;
}
f0103a1e:	5d                   	pop    %ebp
f0103a1f:	c3                   	ret    

f0103a20 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103a20:	f3 0f 1e fb          	endbr32 
f0103a24:	55                   	push   %ebp
f0103a25:	89 e5                	mov    %esp,%ebp
f0103a27:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103a2a:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103a2d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a32:	39 d0                	cmp    %edx,%eax
f0103a34:	74 0d                	je     f0103a43 <strnlen+0x23>
f0103a36:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103a3a:	74 05                	je     f0103a41 <strnlen+0x21>
		n++;
f0103a3c:	83 c0 01             	add    $0x1,%eax
f0103a3f:	eb f1                	jmp    f0103a32 <strnlen+0x12>
f0103a41:	89 c2                	mov    %eax,%edx
	return n;
}
f0103a43:	89 d0                	mov    %edx,%eax
f0103a45:	5d                   	pop    %ebp
f0103a46:	c3                   	ret    

f0103a47 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103a47:	f3 0f 1e fb          	endbr32 
f0103a4b:	55                   	push   %ebp
f0103a4c:	89 e5                	mov    %esp,%ebp
f0103a4e:	53                   	push   %ebx
f0103a4f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103a52:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103a55:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a5a:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f0103a5e:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f0103a61:	83 c0 01             	add    $0x1,%eax
f0103a64:	84 d2                	test   %dl,%dl
f0103a66:	75 f2                	jne    f0103a5a <strcpy+0x13>
		/* do nothing */;
	return ret;
}
f0103a68:	89 c8                	mov    %ecx,%eax
f0103a6a:	5b                   	pop    %ebx
f0103a6b:	5d                   	pop    %ebp
f0103a6c:	c3                   	ret    

f0103a6d <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103a6d:	f3 0f 1e fb          	endbr32 
f0103a71:	55                   	push   %ebp
f0103a72:	89 e5                	mov    %esp,%ebp
f0103a74:	53                   	push   %ebx
f0103a75:	83 ec 10             	sub    $0x10,%esp
f0103a78:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103a7b:	53                   	push   %ebx
f0103a7c:	e8 83 ff ff ff       	call   f0103a04 <strlen>
f0103a81:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f0103a84:	ff 75 0c             	pushl  0xc(%ebp)
f0103a87:	01 d8                	add    %ebx,%eax
f0103a89:	50                   	push   %eax
f0103a8a:	e8 b8 ff ff ff       	call   f0103a47 <strcpy>
	return dst;
}
f0103a8f:	89 d8                	mov    %ebx,%eax
f0103a91:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a94:	c9                   	leave  
f0103a95:	c3                   	ret    

f0103a96 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103a96:	f3 0f 1e fb          	endbr32 
f0103a9a:	55                   	push   %ebp
f0103a9b:	89 e5                	mov    %esp,%ebp
f0103a9d:	56                   	push   %esi
f0103a9e:	53                   	push   %ebx
f0103a9f:	8b 75 08             	mov    0x8(%ebp),%esi
f0103aa2:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103aa5:	89 f3                	mov    %esi,%ebx
f0103aa7:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103aaa:	89 f0                	mov    %esi,%eax
f0103aac:	39 d8                	cmp    %ebx,%eax
f0103aae:	74 11                	je     f0103ac1 <strncpy+0x2b>
		*dst++ = *src;
f0103ab0:	83 c0 01             	add    $0x1,%eax
f0103ab3:	0f b6 0a             	movzbl (%edx),%ecx
f0103ab6:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103ab9:	80 f9 01             	cmp    $0x1,%cl
f0103abc:	83 da ff             	sbb    $0xffffffff,%edx
f0103abf:	eb eb                	jmp    f0103aac <strncpy+0x16>
	}
	return ret;
}
f0103ac1:	89 f0                	mov    %esi,%eax
f0103ac3:	5b                   	pop    %ebx
f0103ac4:	5e                   	pop    %esi
f0103ac5:	5d                   	pop    %ebp
f0103ac6:	c3                   	ret    

f0103ac7 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103ac7:	f3 0f 1e fb          	endbr32 
f0103acb:	55                   	push   %ebp
f0103acc:	89 e5                	mov    %esp,%ebp
f0103ace:	56                   	push   %esi
f0103acf:	53                   	push   %ebx
f0103ad0:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ad3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103ad6:	8b 55 10             	mov    0x10(%ebp),%edx
f0103ad9:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103adb:	85 d2                	test   %edx,%edx
f0103add:	74 21                	je     f0103b00 <strlcpy+0x39>
f0103adf:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103ae3:	89 f2                	mov    %esi,%edx
		while (--size > 0 && *src != '\0')
f0103ae5:	39 c2                	cmp    %eax,%edx
f0103ae7:	74 14                	je     f0103afd <strlcpy+0x36>
f0103ae9:	0f b6 19             	movzbl (%ecx),%ebx
f0103aec:	84 db                	test   %bl,%bl
f0103aee:	74 0b                	je     f0103afb <strlcpy+0x34>
			*dst++ = *src++;
f0103af0:	83 c1 01             	add    $0x1,%ecx
f0103af3:	83 c2 01             	add    $0x1,%edx
f0103af6:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103af9:	eb ea                	jmp    f0103ae5 <strlcpy+0x1e>
f0103afb:	89 d0                	mov    %edx,%eax
		*dst = '\0';
f0103afd:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103b00:	29 f0                	sub    %esi,%eax
}
f0103b02:	5b                   	pop    %ebx
f0103b03:	5e                   	pop    %esi
f0103b04:	5d                   	pop    %ebp
f0103b05:	c3                   	ret    

f0103b06 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103b06:	f3 0f 1e fb          	endbr32 
f0103b0a:	55                   	push   %ebp
f0103b0b:	89 e5                	mov    %esp,%ebp
f0103b0d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b10:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103b13:	0f b6 01             	movzbl (%ecx),%eax
f0103b16:	84 c0                	test   %al,%al
f0103b18:	74 0c                	je     f0103b26 <strcmp+0x20>
f0103b1a:	3a 02                	cmp    (%edx),%al
f0103b1c:	75 08                	jne    f0103b26 <strcmp+0x20>
		p++, q++;
f0103b1e:	83 c1 01             	add    $0x1,%ecx
f0103b21:	83 c2 01             	add    $0x1,%edx
f0103b24:	eb ed                	jmp    f0103b13 <strcmp+0xd>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103b26:	0f b6 c0             	movzbl %al,%eax
f0103b29:	0f b6 12             	movzbl (%edx),%edx
f0103b2c:	29 d0                	sub    %edx,%eax
}
f0103b2e:	5d                   	pop    %ebp
f0103b2f:	c3                   	ret    

f0103b30 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103b30:	f3 0f 1e fb          	endbr32 
f0103b34:	55                   	push   %ebp
f0103b35:	89 e5                	mov    %esp,%ebp
f0103b37:	53                   	push   %ebx
f0103b38:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b3b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b3e:	89 c3                	mov    %eax,%ebx
f0103b40:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103b43:	eb 06                	jmp    f0103b4b <strncmp+0x1b>
		n--, p++, q++;
f0103b45:	83 c0 01             	add    $0x1,%eax
f0103b48:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0103b4b:	39 d8                	cmp    %ebx,%eax
f0103b4d:	74 16                	je     f0103b65 <strncmp+0x35>
f0103b4f:	0f b6 08             	movzbl (%eax),%ecx
f0103b52:	84 c9                	test   %cl,%cl
f0103b54:	74 04                	je     f0103b5a <strncmp+0x2a>
f0103b56:	3a 0a                	cmp    (%edx),%cl
f0103b58:	74 eb                	je     f0103b45 <strncmp+0x15>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103b5a:	0f b6 00             	movzbl (%eax),%eax
f0103b5d:	0f b6 12             	movzbl (%edx),%edx
f0103b60:	29 d0                	sub    %edx,%eax
}
f0103b62:	5b                   	pop    %ebx
f0103b63:	5d                   	pop    %ebp
f0103b64:	c3                   	ret    
		return 0;
f0103b65:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b6a:	eb f6                	jmp    f0103b62 <strncmp+0x32>

f0103b6c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103b6c:	f3 0f 1e fb          	endbr32 
f0103b70:	55                   	push   %ebp
f0103b71:	89 e5                	mov    %esp,%ebp
f0103b73:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b76:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103b7a:	0f b6 10             	movzbl (%eax),%edx
f0103b7d:	84 d2                	test   %dl,%dl
f0103b7f:	74 09                	je     f0103b8a <strchr+0x1e>
		if (*s == c)
f0103b81:	38 ca                	cmp    %cl,%dl
f0103b83:	74 0a                	je     f0103b8f <strchr+0x23>
	for (; *s; s++)
f0103b85:	83 c0 01             	add    $0x1,%eax
f0103b88:	eb f0                	jmp    f0103b7a <strchr+0xe>
			return (char *) s;
	return 0;
f0103b8a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b8f:	5d                   	pop    %ebp
f0103b90:	c3                   	ret    

f0103b91 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103b91:	f3 0f 1e fb          	endbr32 
f0103b95:	55                   	push   %ebp
f0103b96:	89 e5                	mov    %esp,%ebp
f0103b98:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b9b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103b9f:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103ba2:	38 ca                	cmp    %cl,%dl
f0103ba4:	74 09                	je     f0103baf <strfind+0x1e>
f0103ba6:	84 d2                	test   %dl,%dl
f0103ba8:	74 05                	je     f0103baf <strfind+0x1e>
	for (; *s; s++)
f0103baa:	83 c0 01             	add    $0x1,%eax
f0103bad:	eb f0                	jmp    f0103b9f <strfind+0xe>
			break;
	return (char *) s;
}
f0103baf:	5d                   	pop    %ebp
f0103bb0:	c3                   	ret    

f0103bb1 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103bb1:	f3 0f 1e fb          	endbr32 
f0103bb5:	55                   	push   %ebp
f0103bb6:	89 e5                	mov    %esp,%ebp
f0103bb8:	57                   	push   %edi
f0103bb9:	56                   	push   %esi
f0103bba:	53                   	push   %ebx
f0103bbb:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103bbe:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103bc1:	85 c9                	test   %ecx,%ecx
f0103bc3:	74 31                	je     f0103bf6 <memset+0x45>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103bc5:	89 f8                	mov    %edi,%eax
f0103bc7:	09 c8                	or     %ecx,%eax
f0103bc9:	a8 03                	test   $0x3,%al
f0103bcb:	75 23                	jne    f0103bf0 <memset+0x3f>
		c &= 0xFF;
f0103bcd:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103bd1:	89 d3                	mov    %edx,%ebx
f0103bd3:	c1 e3 08             	shl    $0x8,%ebx
f0103bd6:	89 d0                	mov    %edx,%eax
f0103bd8:	c1 e0 18             	shl    $0x18,%eax
f0103bdb:	89 d6                	mov    %edx,%esi
f0103bdd:	c1 e6 10             	shl    $0x10,%esi
f0103be0:	09 f0                	or     %esi,%eax
f0103be2:	09 c2                	or     %eax,%edx
f0103be4:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103be6:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103be9:	89 d0                	mov    %edx,%eax
f0103beb:	fc                   	cld    
f0103bec:	f3 ab                	rep stos %eax,%es:(%edi)
f0103bee:	eb 06                	jmp    f0103bf6 <memset+0x45>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103bf0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103bf3:	fc                   	cld    
f0103bf4:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103bf6:	89 f8                	mov    %edi,%eax
f0103bf8:	5b                   	pop    %ebx
f0103bf9:	5e                   	pop    %esi
f0103bfa:	5f                   	pop    %edi
f0103bfb:	5d                   	pop    %ebp
f0103bfc:	c3                   	ret    

f0103bfd <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103bfd:	f3 0f 1e fb          	endbr32 
f0103c01:	55                   	push   %ebp
f0103c02:	89 e5                	mov    %esp,%ebp
f0103c04:	57                   	push   %edi
f0103c05:	56                   	push   %esi
f0103c06:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c09:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103c0c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103c0f:	39 c6                	cmp    %eax,%esi
f0103c11:	73 32                	jae    f0103c45 <memmove+0x48>
f0103c13:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103c16:	39 c2                	cmp    %eax,%edx
f0103c18:	76 2b                	jbe    f0103c45 <memmove+0x48>
		s += n;
		d += n;
f0103c1a:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c1d:	89 fe                	mov    %edi,%esi
f0103c1f:	09 ce                	or     %ecx,%esi
f0103c21:	09 d6                	or     %edx,%esi
f0103c23:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103c29:	75 0e                	jne    f0103c39 <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103c2b:	83 ef 04             	sub    $0x4,%edi
f0103c2e:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103c31:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0103c34:	fd                   	std    
f0103c35:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c37:	eb 09                	jmp    f0103c42 <memmove+0x45>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103c39:	83 ef 01             	sub    $0x1,%edi
f0103c3c:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103c3f:	fd                   	std    
f0103c40:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103c42:	fc                   	cld    
f0103c43:	eb 1a                	jmp    f0103c5f <memmove+0x62>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c45:	89 c2                	mov    %eax,%edx
f0103c47:	09 ca                	or     %ecx,%edx
f0103c49:	09 f2                	or     %esi,%edx
f0103c4b:	f6 c2 03             	test   $0x3,%dl
f0103c4e:	75 0a                	jne    f0103c5a <memmove+0x5d>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103c50:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103c53:	89 c7                	mov    %eax,%edi
f0103c55:	fc                   	cld    
f0103c56:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c58:	eb 05                	jmp    f0103c5f <memmove+0x62>
		else
			asm volatile("cld; rep movsb\n"
f0103c5a:	89 c7                	mov    %eax,%edi
f0103c5c:	fc                   	cld    
f0103c5d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103c5f:	5e                   	pop    %esi
f0103c60:	5f                   	pop    %edi
f0103c61:	5d                   	pop    %ebp
f0103c62:	c3                   	ret    

f0103c63 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103c63:	f3 0f 1e fb          	endbr32 
f0103c67:	55                   	push   %ebp
f0103c68:	89 e5                	mov    %esp,%ebp
f0103c6a:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103c6d:	ff 75 10             	pushl  0x10(%ebp)
f0103c70:	ff 75 0c             	pushl  0xc(%ebp)
f0103c73:	ff 75 08             	pushl  0x8(%ebp)
f0103c76:	e8 82 ff ff ff       	call   f0103bfd <memmove>
}
f0103c7b:	c9                   	leave  
f0103c7c:	c3                   	ret    

f0103c7d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103c7d:	f3 0f 1e fb          	endbr32 
f0103c81:	55                   	push   %ebp
f0103c82:	89 e5                	mov    %esp,%ebp
f0103c84:	56                   	push   %esi
f0103c85:	53                   	push   %ebx
f0103c86:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c89:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c8c:	89 c6                	mov    %eax,%esi
f0103c8e:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103c91:	39 f0                	cmp    %esi,%eax
f0103c93:	74 1c                	je     f0103cb1 <memcmp+0x34>
		if (*s1 != *s2)
f0103c95:	0f b6 08             	movzbl (%eax),%ecx
f0103c98:	0f b6 1a             	movzbl (%edx),%ebx
f0103c9b:	38 d9                	cmp    %bl,%cl
f0103c9d:	75 08                	jne    f0103ca7 <memcmp+0x2a>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0103c9f:	83 c0 01             	add    $0x1,%eax
f0103ca2:	83 c2 01             	add    $0x1,%edx
f0103ca5:	eb ea                	jmp    f0103c91 <memcmp+0x14>
			return (int) *s1 - (int) *s2;
f0103ca7:	0f b6 c1             	movzbl %cl,%eax
f0103caa:	0f b6 db             	movzbl %bl,%ebx
f0103cad:	29 d8                	sub    %ebx,%eax
f0103caf:	eb 05                	jmp    f0103cb6 <memcmp+0x39>
	}

	return 0;
f0103cb1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103cb6:	5b                   	pop    %ebx
f0103cb7:	5e                   	pop    %esi
f0103cb8:	5d                   	pop    %ebp
f0103cb9:	c3                   	ret    

f0103cba <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103cba:	f3 0f 1e fb          	endbr32 
f0103cbe:	55                   	push   %ebp
f0103cbf:	89 e5                	mov    %esp,%ebp
f0103cc1:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cc4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103cc7:	89 c2                	mov    %eax,%edx
f0103cc9:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103ccc:	39 d0                	cmp    %edx,%eax
f0103cce:	73 09                	jae    f0103cd9 <memfind+0x1f>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103cd0:	38 08                	cmp    %cl,(%eax)
f0103cd2:	74 05                	je     f0103cd9 <memfind+0x1f>
	for (; s < ends; s++)
f0103cd4:	83 c0 01             	add    $0x1,%eax
f0103cd7:	eb f3                	jmp    f0103ccc <memfind+0x12>
			break;
	return (void *) s;
}
f0103cd9:	5d                   	pop    %ebp
f0103cda:	c3                   	ret    

f0103cdb <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103cdb:	f3 0f 1e fb          	endbr32 
f0103cdf:	55                   	push   %ebp
f0103ce0:	89 e5                	mov    %esp,%ebp
f0103ce2:	57                   	push   %edi
f0103ce3:	56                   	push   %esi
f0103ce4:	53                   	push   %ebx
f0103ce5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103ce8:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103ceb:	eb 03                	jmp    f0103cf0 <strtol+0x15>
		s++;
f0103ced:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0103cf0:	0f b6 01             	movzbl (%ecx),%eax
f0103cf3:	3c 20                	cmp    $0x20,%al
f0103cf5:	74 f6                	je     f0103ced <strtol+0x12>
f0103cf7:	3c 09                	cmp    $0x9,%al
f0103cf9:	74 f2                	je     f0103ced <strtol+0x12>

	// plus/minus sign
	if (*s == '+')
f0103cfb:	3c 2b                	cmp    $0x2b,%al
f0103cfd:	74 2a                	je     f0103d29 <strtol+0x4e>
	int neg = 0;
f0103cff:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0103d04:	3c 2d                	cmp    $0x2d,%al
f0103d06:	74 2b                	je     f0103d33 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103d08:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103d0e:	75 0f                	jne    f0103d1f <strtol+0x44>
f0103d10:	80 39 30             	cmpb   $0x30,(%ecx)
f0103d13:	74 28                	je     f0103d3d <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103d15:	85 db                	test   %ebx,%ebx
f0103d17:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103d1c:	0f 44 d8             	cmove  %eax,%ebx
f0103d1f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d24:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103d27:	eb 46                	jmp    f0103d6f <strtol+0x94>
		s++;
f0103d29:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0103d2c:	bf 00 00 00 00       	mov    $0x0,%edi
f0103d31:	eb d5                	jmp    f0103d08 <strtol+0x2d>
		s++, neg = 1;
f0103d33:	83 c1 01             	add    $0x1,%ecx
f0103d36:	bf 01 00 00 00       	mov    $0x1,%edi
f0103d3b:	eb cb                	jmp    f0103d08 <strtol+0x2d>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103d3d:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103d41:	74 0e                	je     f0103d51 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0103d43:	85 db                	test   %ebx,%ebx
f0103d45:	75 d8                	jne    f0103d1f <strtol+0x44>
		s++, base = 8;
f0103d47:	83 c1 01             	add    $0x1,%ecx
f0103d4a:	bb 08 00 00 00       	mov    $0x8,%ebx
f0103d4f:	eb ce                	jmp    f0103d1f <strtol+0x44>
		s += 2, base = 16;
f0103d51:	83 c1 02             	add    $0x2,%ecx
f0103d54:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103d59:	eb c4                	jmp    f0103d1f <strtol+0x44>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f0103d5b:	0f be d2             	movsbl %dl,%edx
f0103d5e:	83 ea 30             	sub    $0x30,%edx
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103d61:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103d64:	7d 3a                	jge    f0103da0 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0103d66:	83 c1 01             	add    $0x1,%ecx
f0103d69:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103d6d:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0103d6f:	0f b6 11             	movzbl (%ecx),%edx
f0103d72:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103d75:	89 f3                	mov    %esi,%ebx
f0103d77:	80 fb 09             	cmp    $0x9,%bl
f0103d7a:	76 df                	jbe    f0103d5b <strtol+0x80>
		else if (*s >= 'a' && *s <= 'z')
f0103d7c:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103d7f:	89 f3                	mov    %esi,%ebx
f0103d81:	80 fb 19             	cmp    $0x19,%bl
f0103d84:	77 08                	ja     f0103d8e <strtol+0xb3>
			dig = *s - 'a' + 10;
f0103d86:	0f be d2             	movsbl %dl,%edx
f0103d89:	83 ea 57             	sub    $0x57,%edx
f0103d8c:	eb d3                	jmp    f0103d61 <strtol+0x86>
		else if (*s >= 'A' && *s <= 'Z')
f0103d8e:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103d91:	89 f3                	mov    %esi,%ebx
f0103d93:	80 fb 19             	cmp    $0x19,%bl
f0103d96:	77 08                	ja     f0103da0 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0103d98:	0f be d2             	movsbl %dl,%edx
f0103d9b:	83 ea 37             	sub    $0x37,%edx
f0103d9e:	eb c1                	jmp    f0103d61 <strtol+0x86>
		// we don't properly detect overflow!
	}

	if (endptr)
f0103da0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103da4:	74 05                	je     f0103dab <strtol+0xd0>
		*endptr = (char *) s;
f0103da6:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103da9:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0103dab:	89 c2                	mov    %eax,%edx
f0103dad:	f7 da                	neg    %edx
f0103daf:	85 ff                	test   %edi,%edi
f0103db1:	0f 45 c2             	cmovne %edx,%eax
}
f0103db4:	5b                   	pop    %ebx
f0103db5:	5e                   	pop    %esi
f0103db6:	5f                   	pop    %edi
f0103db7:	5d                   	pop    %ebp
f0103db8:	c3                   	ret    
f0103db9:	66 90                	xchg   %ax,%ax
f0103dbb:	66 90                	xchg   %ax,%ax
f0103dbd:	66 90                	xchg   %ax,%ax
f0103dbf:	90                   	nop

f0103dc0 <__udivdi3>:
f0103dc0:	f3 0f 1e fb          	endbr32 
f0103dc4:	55                   	push   %ebp
f0103dc5:	57                   	push   %edi
f0103dc6:	56                   	push   %esi
f0103dc7:	53                   	push   %ebx
f0103dc8:	83 ec 1c             	sub    $0x1c,%esp
f0103dcb:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103dcf:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0103dd3:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103dd7:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0103ddb:	85 d2                	test   %edx,%edx
f0103ddd:	75 19                	jne    f0103df8 <__udivdi3+0x38>
f0103ddf:	39 f3                	cmp    %esi,%ebx
f0103de1:	76 4d                	jbe    f0103e30 <__udivdi3+0x70>
f0103de3:	31 ff                	xor    %edi,%edi
f0103de5:	89 e8                	mov    %ebp,%eax
f0103de7:	89 f2                	mov    %esi,%edx
f0103de9:	f7 f3                	div    %ebx
f0103deb:	89 fa                	mov    %edi,%edx
f0103ded:	83 c4 1c             	add    $0x1c,%esp
f0103df0:	5b                   	pop    %ebx
f0103df1:	5e                   	pop    %esi
f0103df2:	5f                   	pop    %edi
f0103df3:	5d                   	pop    %ebp
f0103df4:	c3                   	ret    
f0103df5:	8d 76 00             	lea    0x0(%esi),%esi
f0103df8:	39 f2                	cmp    %esi,%edx
f0103dfa:	76 14                	jbe    f0103e10 <__udivdi3+0x50>
f0103dfc:	31 ff                	xor    %edi,%edi
f0103dfe:	31 c0                	xor    %eax,%eax
f0103e00:	89 fa                	mov    %edi,%edx
f0103e02:	83 c4 1c             	add    $0x1c,%esp
f0103e05:	5b                   	pop    %ebx
f0103e06:	5e                   	pop    %esi
f0103e07:	5f                   	pop    %edi
f0103e08:	5d                   	pop    %ebp
f0103e09:	c3                   	ret    
f0103e0a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103e10:	0f bd fa             	bsr    %edx,%edi
f0103e13:	83 f7 1f             	xor    $0x1f,%edi
f0103e16:	75 48                	jne    f0103e60 <__udivdi3+0xa0>
f0103e18:	39 f2                	cmp    %esi,%edx
f0103e1a:	72 06                	jb     f0103e22 <__udivdi3+0x62>
f0103e1c:	31 c0                	xor    %eax,%eax
f0103e1e:	39 eb                	cmp    %ebp,%ebx
f0103e20:	77 de                	ja     f0103e00 <__udivdi3+0x40>
f0103e22:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e27:	eb d7                	jmp    f0103e00 <__udivdi3+0x40>
f0103e29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103e30:	89 d9                	mov    %ebx,%ecx
f0103e32:	85 db                	test   %ebx,%ebx
f0103e34:	75 0b                	jne    f0103e41 <__udivdi3+0x81>
f0103e36:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e3b:	31 d2                	xor    %edx,%edx
f0103e3d:	f7 f3                	div    %ebx
f0103e3f:	89 c1                	mov    %eax,%ecx
f0103e41:	31 d2                	xor    %edx,%edx
f0103e43:	89 f0                	mov    %esi,%eax
f0103e45:	f7 f1                	div    %ecx
f0103e47:	89 c6                	mov    %eax,%esi
f0103e49:	89 e8                	mov    %ebp,%eax
f0103e4b:	89 f7                	mov    %esi,%edi
f0103e4d:	f7 f1                	div    %ecx
f0103e4f:	89 fa                	mov    %edi,%edx
f0103e51:	83 c4 1c             	add    $0x1c,%esp
f0103e54:	5b                   	pop    %ebx
f0103e55:	5e                   	pop    %esi
f0103e56:	5f                   	pop    %edi
f0103e57:	5d                   	pop    %ebp
f0103e58:	c3                   	ret    
f0103e59:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103e60:	89 f9                	mov    %edi,%ecx
f0103e62:	b8 20 00 00 00       	mov    $0x20,%eax
f0103e67:	29 f8                	sub    %edi,%eax
f0103e69:	d3 e2                	shl    %cl,%edx
f0103e6b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103e6f:	89 c1                	mov    %eax,%ecx
f0103e71:	89 da                	mov    %ebx,%edx
f0103e73:	d3 ea                	shr    %cl,%edx
f0103e75:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103e79:	09 d1                	or     %edx,%ecx
f0103e7b:	89 f2                	mov    %esi,%edx
f0103e7d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103e81:	89 f9                	mov    %edi,%ecx
f0103e83:	d3 e3                	shl    %cl,%ebx
f0103e85:	89 c1                	mov    %eax,%ecx
f0103e87:	d3 ea                	shr    %cl,%edx
f0103e89:	89 f9                	mov    %edi,%ecx
f0103e8b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103e8f:	89 eb                	mov    %ebp,%ebx
f0103e91:	d3 e6                	shl    %cl,%esi
f0103e93:	89 c1                	mov    %eax,%ecx
f0103e95:	d3 eb                	shr    %cl,%ebx
f0103e97:	09 de                	or     %ebx,%esi
f0103e99:	89 f0                	mov    %esi,%eax
f0103e9b:	f7 74 24 08          	divl   0x8(%esp)
f0103e9f:	89 d6                	mov    %edx,%esi
f0103ea1:	89 c3                	mov    %eax,%ebx
f0103ea3:	f7 64 24 0c          	mull   0xc(%esp)
f0103ea7:	39 d6                	cmp    %edx,%esi
f0103ea9:	72 15                	jb     f0103ec0 <__udivdi3+0x100>
f0103eab:	89 f9                	mov    %edi,%ecx
f0103ead:	d3 e5                	shl    %cl,%ebp
f0103eaf:	39 c5                	cmp    %eax,%ebp
f0103eb1:	73 04                	jae    f0103eb7 <__udivdi3+0xf7>
f0103eb3:	39 d6                	cmp    %edx,%esi
f0103eb5:	74 09                	je     f0103ec0 <__udivdi3+0x100>
f0103eb7:	89 d8                	mov    %ebx,%eax
f0103eb9:	31 ff                	xor    %edi,%edi
f0103ebb:	e9 40 ff ff ff       	jmp    f0103e00 <__udivdi3+0x40>
f0103ec0:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0103ec3:	31 ff                	xor    %edi,%edi
f0103ec5:	e9 36 ff ff ff       	jmp    f0103e00 <__udivdi3+0x40>
f0103eca:	66 90                	xchg   %ax,%ax
f0103ecc:	66 90                	xchg   %ax,%ax
f0103ece:	66 90                	xchg   %ax,%ax

f0103ed0 <__umoddi3>:
f0103ed0:	f3 0f 1e fb          	endbr32 
f0103ed4:	55                   	push   %ebp
f0103ed5:	57                   	push   %edi
f0103ed6:	56                   	push   %esi
f0103ed7:	53                   	push   %ebx
f0103ed8:	83 ec 1c             	sub    $0x1c,%esp
f0103edb:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0103edf:	8b 74 24 30          	mov    0x30(%esp),%esi
f0103ee3:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0103ee7:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103eeb:	85 c0                	test   %eax,%eax
f0103eed:	75 19                	jne    f0103f08 <__umoddi3+0x38>
f0103eef:	39 df                	cmp    %ebx,%edi
f0103ef1:	76 5d                	jbe    f0103f50 <__umoddi3+0x80>
f0103ef3:	89 f0                	mov    %esi,%eax
f0103ef5:	89 da                	mov    %ebx,%edx
f0103ef7:	f7 f7                	div    %edi
f0103ef9:	89 d0                	mov    %edx,%eax
f0103efb:	31 d2                	xor    %edx,%edx
f0103efd:	83 c4 1c             	add    $0x1c,%esp
f0103f00:	5b                   	pop    %ebx
f0103f01:	5e                   	pop    %esi
f0103f02:	5f                   	pop    %edi
f0103f03:	5d                   	pop    %ebp
f0103f04:	c3                   	ret    
f0103f05:	8d 76 00             	lea    0x0(%esi),%esi
f0103f08:	89 f2                	mov    %esi,%edx
f0103f0a:	39 d8                	cmp    %ebx,%eax
f0103f0c:	76 12                	jbe    f0103f20 <__umoddi3+0x50>
f0103f0e:	89 f0                	mov    %esi,%eax
f0103f10:	89 da                	mov    %ebx,%edx
f0103f12:	83 c4 1c             	add    $0x1c,%esp
f0103f15:	5b                   	pop    %ebx
f0103f16:	5e                   	pop    %esi
f0103f17:	5f                   	pop    %edi
f0103f18:	5d                   	pop    %ebp
f0103f19:	c3                   	ret    
f0103f1a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103f20:	0f bd e8             	bsr    %eax,%ebp
f0103f23:	83 f5 1f             	xor    $0x1f,%ebp
f0103f26:	75 50                	jne    f0103f78 <__umoddi3+0xa8>
f0103f28:	39 d8                	cmp    %ebx,%eax
f0103f2a:	0f 82 e0 00 00 00    	jb     f0104010 <__umoddi3+0x140>
f0103f30:	89 d9                	mov    %ebx,%ecx
f0103f32:	39 f7                	cmp    %esi,%edi
f0103f34:	0f 86 d6 00 00 00    	jbe    f0104010 <__umoddi3+0x140>
f0103f3a:	89 d0                	mov    %edx,%eax
f0103f3c:	89 ca                	mov    %ecx,%edx
f0103f3e:	83 c4 1c             	add    $0x1c,%esp
f0103f41:	5b                   	pop    %ebx
f0103f42:	5e                   	pop    %esi
f0103f43:	5f                   	pop    %edi
f0103f44:	5d                   	pop    %ebp
f0103f45:	c3                   	ret    
f0103f46:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103f4d:	8d 76 00             	lea    0x0(%esi),%esi
f0103f50:	89 fd                	mov    %edi,%ebp
f0103f52:	85 ff                	test   %edi,%edi
f0103f54:	75 0b                	jne    f0103f61 <__umoddi3+0x91>
f0103f56:	b8 01 00 00 00       	mov    $0x1,%eax
f0103f5b:	31 d2                	xor    %edx,%edx
f0103f5d:	f7 f7                	div    %edi
f0103f5f:	89 c5                	mov    %eax,%ebp
f0103f61:	89 d8                	mov    %ebx,%eax
f0103f63:	31 d2                	xor    %edx,%edx
f0103f65:	f7 f5                	div    %ebp
f0103f67:	89 f0                	mov    %esi,%eax
f0103f69:	f7 f5                	div    %ebp
f0103f6b:	89 d0                	mov    %edx,%eax
f0103f6d:	31 d2                	xor    %edx,%edx
f0103f6f:	eb 8c                	jmp    f0103efd <__umoddi3+0x2d>
f0103f71:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103f78:	89 e9                	mov    %ebp,%ecx
f0103f7a:	ba 20 00 00 00       	mov    $0x20,%edx
f0103f7f:	29 ea                	sub    %ebp,%edx
f0103f81:	d3 e0                	shl    %cl,%eax
f0103f83:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f87:	89 d1                	mov    %edx,%ecx
f0103f89:	89 f8                	mov    %edi,%eax
f0103f8b:	d3 e8                	shr    %cl,%eax
f0103f8d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103f91:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103f95:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103f99:	09 c1                	or     %eax,%ecx
f0103f9b:	89 d8                	mov    %ebx,%eax
f0103f9d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103fa1:	89 e9                	mov    %ebp,%ecx
f0103fa3:	d3 e7                	shl    %cl,%edi
f0103fa5:	89 d1                	mov    %edx,%ecx
f0103fa7:	d3 e8                	shr    %cl,%eax
f0103fa9:	89 e9                	mov    %ebp,%ecx
f0103fab:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103faf:	d3 e3                	shl    %cl,%ebx
f0103fb1:	89 c7                	mov    %eax,%edi
f0103fb3:	89 d1                	mov    %edx,%ecx
f0103fb5:	89 f0                	mov    %esi,%eax
f0103fb7:	d3 e8                	shr    %cl,%eax
f0103fb9:	89 e9                	mov    %ebp,%ecx
f0103fbb:	89 fa                	mov    %edi,%edx
f0103fbd:	d3 e6                	shl    %cl,%esi
f0103fbf:	09 d8                	or     %ebx,%eax
f0103fc1:	f7 74 24 08          	divl   0x8(%esp)
f0103fc5:	89 d1                	mov    %edx,%ecx
f0103fc7:	89 f3                	mov    %esi,%ebx
f0103fc9:	f7 64 24 0c          	mull   0xc(%esp)
f0103fcd:	89 c6                	mov    %eax,%esi
f0103fcf:	89 d7                	mov    %edx,%edi
f0103fd1:	39 d1                	cmp    %edx,%ecx
f0103fd3:	72 06                	jb     f0103fdb <__umoddi3+0x10b>
f0103fd5:	75 10                	jne    f0103fe7 <__umoddi3+0x117>
f0103fd7:	39 c3                	cmp    %eax,%ebx
f0103fd9:	73 0c                	jae    f0103fe7 <__umoddi3+0x117>
f0103fdb:	2b 44 24 0c          	sub    0xc(%esp),%eax
f0103fdf:	1b 54 24 08          	sbb    0x8(%esp),%edx
f0103fe3:	89 d7                	mov    %edx,%edi
f0103fe5:	89 c6                	mov    %eax,%esi
f0103fe7:	89 ca                	mov    %ecx,%edx
f0103fe9:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103fee:	29 f3                	sub    %esi,%ebx
f0103ff0:	19 fa                	sbb    %edi,%edx
f0103ff2:	89 d0                	mov    %edx,%eax
f0103ff4:	d3 e0                	shl    %cl,%eax
f0103ff6:	89 e9                	mov    %ebp,%ecx
f0103ff8:	d3 eb                	shr    %cl,%ebx
f0103ffa:	d3 ea                	shr    %cl,%edx
f0103ffc:	09 d8                	or     %ebx,%eax
f0103ffe:	83 c4 1c             	add    $0x1c,%esp
f0104001:	5b                   	pop    %ebx
f0104002:	5e                   	pop    %esi
f0104003:	5f                   	pop    %edi
f0104004:	5d                   	pop    %ebp
f0104005:	c3                   	ret    
f0104006:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f010400d:	8d 76 00             	lea    0x0(%esi),%esi
f0104010:	29 fe                	sub    %edi,%esi
f0104012:	19 c3                	sbb    %eax,%ebx
f0104014:	89 f2                	mov    %esi,%edx
f0104016:	89 d9                	mov    %ebx,%ecx
f0104018:	e9 1d ff ff ff       	jmp    f0103f3a <__umoddi3+0x6a>
