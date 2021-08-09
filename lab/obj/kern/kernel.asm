
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
f0100015:	b8 00 f0 18 00       	mov    $0x18f000,%eax
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
f0100034:	bc 00 c0 11 f0       	mov    $0xf011c000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	f3 0f 1e fb          	endbr32 
f0100044:	55                   	push   %ebp
f0100045:	89 e5                	mov    %esp,%ebp
f0100047:	53                   	push   %ebx
f0100048:	83 ec 08             	sub    $0x8,%esp
f010004b:	e8 23 01 00 00       	call   f0100173 <__x86.get_pc_thunk.bx>
f0100050:	81 c3 cc df 08 00    	add    $0x8dfcc,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100056:	c7 c0 14 10 19 f0    	mov    $0xf0191014,%eax
f010005c:	c7 c2 00 01 19 f0    	mov    $0xf0190100,%edx
f0100062:	29 d0                	sub    %edx,%eax
f0100064:	50                   	push   %eax
f0100065:	6a 00                	push   $0x0
f0100067:	52                   	push   %edx
f0100068:	e8 f4 50 00 00       	call   f0105161 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010006d:	e8 85 05 00 00       	call   f01005f7 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	68 ac 1a 00 00       	push   $0x1aac
f010007a:	8d 83 c4 75 f7 ff    	lea    -0x88a3c(%ebx),%eax
f0100080:	50                   	push   %eax
f0100081:	e8 b2 39 00 00       	call   f0103a38 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100086:	e8 62 13 00 00       	call   f01013ed <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f010008b:	e8 79 32 00 00       	call   f0103309 <env_init>
	trap_init();
f0100090:	e8 5e 3a 00 00       	call   f0103af3 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100095:	83 c4 08             	add    $0x8,%esp
f0100098:	6a 00                	push   $0x0
f010009a:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f01000a0:	e8 76 34 00 00       	call   f010351b <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a5:	83 c4 04             	add    $0x4,%esp
f01000a8:	c7 c0 4c 03 19 f0    	mov    $0xf019034c,%eax
f01000ae:	ff 30                	pushl  (%eax)
f01000b0:	e8 73 38 00 00       	call   f0103928 <env_run>

f01000b5 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000b5:	f3 0f 1e fb          	endbr32 
f01000b9:	55                   	push   %ebp
f01000ba:	89 e5                	mov    %esp,%ebp
f01000bc:	57                   	push   %edi
f01000bd:	56                   	push   %esi
f01000be:	53                   	push   %ebx
f01000bf:	83 ec 0c             	sub    $0xc,%esp
f01000c2:	e8 ac 00 00 00       	call   f0100173 <__x86.get_pc_thunk.bx>
f01000c7:	81 c3 55 df 08 00    	add    $0x8df55,%ebx
f01000cd:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000d0:	c7 c0 04 10 19 f0    	mov    $0xf0191004,%eax
f01000d6:	83 38 00             	cmpl   $0x0,(%eax)
f01000d9:	74 0f                	je     f01000ea <_panic+0x35>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000db:	83 ec 0c             	sub    $0xc,%esp
f01000de:	6a 00                	push   $0x0
f01000e0:	e8 9f 08 00 00       	call   f0100984 <monitor>
f01000e5:	83 c4 10             	add    $0x10,%esp
f01000e8:	eb f1                	jmp    f01000db <_panic+0x26>
	panicstr = fmt;
f01000ea:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f01000ec:	fa                   	cli    
f01000ed:	fc                   	cld    
	va_start(ap, fmt);
f01000ee:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000f1:	83 ec 04             	sub    $0x4,%esp
f01000f4:	ff 75 0c             	pushl  0xc(%ebp)
f01000f7:	ff 75 08             	pushl  0x8(%ebp)
f01000fa:	8d 83 df 75 f7 ff    	lea    -0x88a21(%ebx),%eax
f0100100:	50                   	push   %eax
f0100101:	e8 32 39 00 00       	call   f0103a38 <cprintf>
	vcprintf(fmt, ap);
f0100106:	83 c4 08             	add    $0x8,%esp
f0100109:	56                   	push   %esi
f010010a:	57                   	push   %edi
f010010b:	e8 ed 38 00 00       	call   f01039fd <vcprintf>
	cprintf("\n");
f0100110:	8d 83 8e 85 f7 ff    	lea    -0x87a72(%ebx),%eax
f0100116:	89 04 24             	mov    %eax,(%esp)
f0100119:	e8 1a 39 00 00       	call   f0103a38 <cprintf>
f010011e:	83 c4 10             	add    $0x10,%esp
f0100121:	eb b8                	jmp    f01000db <_panic+0x26>

f0100123 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100123:	f3 0f 1e fb          	endbr32 
f0100127:	55                   	push   %ebp
f0100128:	89 e5                	mov    %esp,%ebp
f010012a:	56                   	push   %esi
f010012b:	53                   	push   %ebx
f010012c:	e8 42 00 00 00       	call   f0100173 <__x86.get_pc_thunk.bx>
f0100131:	81 c3 eb de 08 00    	add    $0x8deeb,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100137:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f010013a:	83 ec 04             	sub    $0x4,%esp
f010013d:	ff 75 0c             	pushl  0xc(%ebp)
f0100140:	ff 75 08             	pushl  0x8(%ebp)
f0100143:	8d 83 f7 75 f7 ff    	lea    -0x88a09(%ebx),%eax
f0100149:	50                   	push   %eax
f010014a:	e8 e9 38 00 00       	call   f0103a38 <cprintf>
	vcprintf(fmt, ap);
f010014f:	83 c4 08             	add    $0x8,%esp
f0100152:	56                   	push   %esi
f0100153:	ff 75 10             	pushl  0x10(%ebp)
f0100156:	e8 a2 38 00 00       	call   f01039fd <vcprintf>
	cprintf("\n");
f010015b:	8d 83 8e 85 f7 ff    	lea    -0x87a72(%ebx),%eax
f0100161:	89 04 24             	mov    %eax,(%esp)
f0100164:	e8 cf 38 00 00       	call   f0103a38 <cprintf>
	va_end(ap);
}
f0100169:	83 c4 10             	add    $0x10,%esp
f010016c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010016f:	5b                   	pop    %ebx
f0100170:	5e                   	pop    %esi
f0100171:	5d                   	pop    %ebp
f0100172:	c3                   	ret    

f0100173 <__x86.get_pc_thunk.bx>:
f0100173:	8b 1c 24             	mov    (%esp),%ebx
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	f3 0f 1e fb          	endbr32 

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017b:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100180:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100181:	a8 01                	test   $0x1,%al
f0100183:	74 0a                	je     f010018f <serial_proc_data+0x18>
f0100185:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010018a:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018b:	0f b6 c0             	movzbl %al,%eax
f010018e:	c3                   	ret    
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0100194:	c3                   	ret    

f0100195 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100195:	55                   	push   %ebp
f0100196:	89 e5                	mov    %esp,%ebp
f0100198:	57                   	push   %edi
f0100199:	56                   	push   %esi
f010019a:	53                   	push   %ebx
f010019b:	83 ec 1c             	sub    $0x1c,%esp
f010019e:	e8 b1 05 00 00       	call   f0100754 <__x86.get_pc_thunk.si>
f01001a3:	81 c6 79 de 08 00    	add    $0x8de79,%esi
f01001a9:	89 c7                	mov    %eax,%edi
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
		cons.buf[cons.wpos++] = c;
f01001ab:	8d 1d 04 21 00 00    	lea    0x2104,%ebx
f01001b1:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
f01001b4:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01001b7:	89 7d e4             	mov    %edi,-0x1c(%ebp)
	while ((c = (*proc)()) != -1) {
f01001ba:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01001bd:	ff d0                	call   *%eax
f01001bf:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001c2:	74 2b                	je     f01001ef <cons_intr+0x5a>
		if (c == 0)
f01001c4:	85 c0                	test   %eax,%eax
f01001c6:	74 f2                	je     f01001ba <cons_intr+0x25>
		cons.buf[cons.wpos++] = c;
f01001c8:	8b 8c 1e 04 02 00 00 	mov    0x204(%esi,%ebx,1),%ecx
f01001cf:	8d 51 01             	lea    0x1(%ecx),%edx
f01001d2:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01001d5:	88 04 0f             	mov    %al,(%edi,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001d8:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001de:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e3:	0f 44 d0             	cmove  %eax,%edx
f01001e6:	89 94 1e 04 02 00 00 	mov    %edx,0x204(%esi,%ebx,1)
f01001ed:	eb cb                	jmp    f01001ba <cons_intr+0x25>
	}
}
f01001ef:	83 c4 1c             	add    $0x1c,%esp
f01001f2:	5b                   	pop    %ebx
f01001f3:	5e                   	pop    %esi
f01001f4:	5f                   	pop    %edi
f01001f5:	5d                   	pop    %ebp
f01001f6:	c3                   	ret    

f01001f7 <kbd_proc_data>:
{
f01001f7:	f3 0f 1e fb          	endbr32 
f01001fb:	55                   	push   %ebp
f01001fc:	89 e5                	mov    %esp,%ebp
f01001fe:	56                   	push   %esi
f01001ff:	53                   	push   %ebx
f0100200:	e8 6e ff ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0100205:	81 c3 17 de 08 00    	add    $0x8de17,%ebx
f010020b:	ba 64 00 00 00       	mov    $0x64,%edx
f0100210:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f0100211:	a8 01                	test   $0x1,%al
f0100213:	0f 84 fb 00 00 00    	je     f0100314 <kbd_proc_data+0x11d>
	if (stat & KBS_TERR)
f0100219:	a8 20                	test   $0x20,%al
f010021b:	0f 85 fa 00 00 00    	jne    f010031b <kbd_proc_data+0x124>
f0100221:	ba 60 00 00 00       	mov    $0x60,%edx
f0100226:	ec                   	in     (%dx),%al
f0100227:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f0100229:	3c e0                	cmp    $0xe0,%al
f010022b:	74 64                	je     f0100291 <kbd_proc_data+0x9a>
	} else if (data & 0x80) {
f010022d:	84 c0                	test   %al,%al
f010022f:	78 75                	js     f01002a6 <kbd_proc_data+0xaf>
	} else if (shift & E0ESC) {
f0100231:	8b 8b e4 20 00 00    	mov    0x20e4(%ebx),%ecx
f0100237:	f6 c1 40             	test   $0x40,%cl
f010023a:	74 0e                	je     f010024a <kbd_proc_data+0x53>
		data |= 0x80;
f010023c:	83 c8 80             	or     $0xffffff80,%eax
f010023f:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100241:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100244:	89 8b e4 20 00 00    	mov    %ecx,0x20e4(%ebx)
	shift |= shiftcode[data];
f010024a:	0f b6 d2             	movzbl %dl,%edx
f010024d:	0f b6 84 13 44 77 f7 	movzbl -0x888bc(%ebx,%edx,1),%eax
f0100254:	ff 
f0100255:	0b 83 e4 20 00 00    	or     0x20e4(%ebx),%eax
	shift ^= togglecode[data];
f010025b:	0f b6 8c 13 44 76 f7 	movzbl -0x889bc(%ebx,%edx,1),%ecx
f0100262:	ff 
f0100263:	31 c8                	xor    %ecx,%eax
f0100265:	89 83 e4 20 00 00    	mov    %eax,0x20e4(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f010026b:	89 c1                	mov    %eax,%ecx
f010026d:	83 e1 03             	and    $0x3,%ecx
f0100270:	8b 8c 8b 04 20 00 00 	mov    0x2004(%ebx,%ecx,4),%ecx
f0100277:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010027b:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f010027e:	a8 08                	test   $0x8,%al
f0100280:	74 65                	je     f01002e7 <kbd_proc_data+0xf0>
		if ('a' <= c && c <= 'z')
f0100282:	89 f2                	mov    %esi,%edx
f0100284:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f0100287:	83 f9 19             	cmp    $0x19,%ecx
f010028a:	77 4f                	ja     f01002db <kbd_proc_data+0xe4>
			c += 'A' - 'a';
f010028c:	83 ee 20             	sub    $0x20,%esi
f010028f:	eb 0c                	jmp    f010029d <kbd_proc_data+0xa6>
		shift |= E0ESC;
f0100291:	83 8b e4 20 00 00 40 	orl    $0x40,0x20e4(%ebx)
		return 0;
f0100298:	be 00 00 00 00       	mov    $0x0,%esi
}
f010029d:	89 f0                	mov    %esi,%eax
f010029f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01002a2:	5b                   	pop    %ebx
f01002a3:	5e                   	pop    %esi
f01002a4:	5d                   	pop    %ebp
f01002a5:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f01002a6:	8b 8b e4 20 00 00    	mov    0x20e4(%ebx),%ecx
f01002ac:	89 ce                	mov    %ecx,%esi
f01002ae:	83 e6 40             	and    $0x40,%esi
f01002b1:	83 e0 7f             	and    $0x7f,%eax
f01002b4:	85 f6                	test   %esi,%esi
f01002b6:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002b9:	0f b6 d2             	movzbl %dl,%edx
f01002bc:	0f b6 84 13 44 77 f7 	movzbl -0x888bc(%ebx,%edx,1),%eax
f01002c3:	ff 
f01002c4:	83 c8 40             	or     $0x40,%eax
f01002c7:	0f b6 c0             	movzbl %al,%eax
f01002ca:	f7 d0                	not    %eax
f01002cc:	21 c8                	and    %ecx,%eax
f01002ce:	89 83 e4 20 00 00    	mov    %eax,0x20e4(%ebx)
		return 0;
f01002d4:	be 00 00 00 00       	mov    $0x0,%esi
f01002d9:	eb c2                	jmp    f010029d <kbd_proc_data+0xa6>
		else if ('A' <= c && c <= 'Z')
f01002db:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002de:	8d 4e 20             	lea    0x20(%esi),%ecx
f01002e1:	83 fa 1a             	cmp    $0x1a,%edx
f01002e4:	0f 42 f1             	cmovb  %ecx,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002e7:	f7 d0                	not    %eax
f01002e9:	a8 06                	test   $0x6,%al
f01002eb:	75 b0                	jne    f010029d <kbd_proc_data+0xa6>
f01002ed:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f01002f3:	75 a8                	jne    f010029d <kbd_proc_data+0xa6>
		cprintf("Rebooting!\n");
f01002f5:	83 ec 0c             	sub    $0xc,%esp
f01002f8:	8d 83 11 76 f7 ff    	lea    -0x889ef(%ebx),%eax
f01002fe:	50                   	push   %eax
f01002ff:	e8 34 37 00 00       	call   f0103a38 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100304:	b8 03 00 00 00       	mov    $0x3,%eax
f0100309:	ba 92 00 00 00       	mov    $0x92,%edx
f010030e:	ee                   	out    %al,(%dx)
}
f010030f:	83 c4 10             	add    $0x10,%esp
f0100312:	eb 89                	jmp    f010029d <kbd_proc_data+0xa6>
		return -1;
f0100314:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100319:	eb 82                	jmp    f010029d <kbd_proc_data+0xa6>
		return -1;
f010031b:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100320:	e9 78 ff ff ff       	jmp    f010029d <kbd_proc_data+0xa6>

f0100325 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100325:	55                   	push   %ebp
f0100326:	89 e5                	mov    %esp,%ebp
f0100328:	57                   	push   %edi
f0100329:	56                   	push   %esi
f010032a:	53                   	push   %ebx
f010032b:	83 ec 1c             	sub    $0x1c,%esp
f010032e:	e8 40 fe ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0100333:	81 c3 e9 dc 08 00    	add    $0x8dce9,%ebx
f0100339:	89 c7                	mov    %eax,%edi
	for (i = 0;
f010033b:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100340:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100345:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010034a:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010034b:	a8 20                	test   $0x20,%al
f010034d:	75 13                	jne    f0100362 <cons_putc+0x3d>
f010034f:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100355:	7f 0b                	jg     f0100362 <cons_putc+0x3d>
f0100357:	89 ca                	mov    %ecx,%edx
f0100359:	ec                   	in     (%dx),%al
f010035a:	ec                   	in     (%dx),%al
f010035b:	ec                   	in     (%dx),%al
f010035c:	ec                   	in     (%dx),%al
	     i++)
f010035d:	83 c6 01             	add    $0x1,%esi
f0100360:	eb e3                	jmp    f0100345 <cons_putc+0x20>
	outb(COM1 + COM_TX, c);
f0100362:	89 f8                	mov    %edi,%eax
f0100364:	88 45 e7             	mov    %al,-0x19(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100367:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010036c:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010036d:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100372:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100377:	ba 79 03 00 00       	mov    $0x379,%edx
f010037c:	ec                   	in     (%dx),%al
f010037d:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100383:	7f 0f                	jg     f0100394 <cons_putc+0x6f>
f0100385:	84 c0                	test   %al,%al
f0100387:	78 0b                	js     f0100394 <cons_putc+0x6f>
f0100389:	89 ca                	mov    %ecx,%edx
f010038b:	ec                   	in     (%dx),%al
f010038c:	ec                   	in     (%dx),%al
f010038d:	ec                   	in     (%dx),%al
f010038e:	ec                   	in     (%dx),%al
f010038f:	83 c6 01             	add    $0x1,%esi
f0100392:	eb e3                	jmp    f0100377 <cons_putc+0x52>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100394:	ba 78 03 00 00       	mov    $0x378,%edx
f0100399:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010039d:	ee                   	out    %al,(%dx)
f010039e:	ba 7a 03 00 00       	mov    $0x37a,%edx
f01003a3:	b8 0d 00 00 00       	mov    $0xd,%eax
f01003a8:	ee                   	out    %al,(%dx)
f01003a9:	b8 08 00 00 00       	mov    $0x8,%eax
f01003ae:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f01003af:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f01003b5:	75 11                	jne    f01003c8 <cons_putc+0xa3>
		if(ch>47 && ch<58)
f01003b7:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f01003bb:	83 e8 30             	sub    $0x30,%eax
f01003be:	3c 09                	cmp    $0x9,%al
f01003c0:	77 61                	ja     f0100423 <cons_putc+0xfe>
			c |= 0x0200;
f01003c2:	81 cf 00 02 00 00    	or     $0x200,%edi
	switch (c & 0xff) {
f01003c8:	89 f8                	mov    %edi,%eax
f01003ca:	0f b6 c0             	movzbl %al,%eax
f01003cd:	89 f9                	mov    %edi,%ecx
f01003cf:	80 f9 0a             	cmp    $0xa,%cl
f01003d2:	0f 84 00 01 00 00    	je     f01004d8 <cons_putc+0x1b3>
f01003d8:	83 f8 0a             	cmp    $0xa,%eax
f01003db:	7f 64                	jg     f0100441 <cons_putc+0x11c>
f01003dd:	83 f8 08             	cmp    $0x8,%eax
f01003e0:	0f 84 c6 00 00 00    	je     f01004ac <cons_putc+0x187>
f01003e6:	83 f8 09             	cmp    $0x9,%eax
f01003e9:	0f 85 f6 00 00 00    	jne    f01004e5 <cons_putc+0x1c0>
		cons_putc(' ');
f01003ef:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f4:	e8 2c ff ff ff       	call   f0100325 <cons_putc>
		cons_putc(' ');
f01003f9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fe:	e8 22 ff ff ff       	call   f0100325 <cons_putc>
		cons_putc(' ');
f0100403:	b8 20 00 00 00       	mov    $0x20,%eax
f0100408:	e8 18 ff ff ff       	call   f0100325 <cons_putc>
		cons_putc(' ');
f010040d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100412:	e8 0e ff ff ff       	call   f0100325 <cons_putc>
		cons_putc(' ');
f0100417:	b8 20 00 00 00       	mov    $0x20,%eax
f010041c:	e8 04 ff ff ff       	call   f0100325 <cons_putc>
		break;
f0100421:	eb 44                	jmp    f0100467 <cons_putc+0x142>
		else if((ch>64 && ch<91) || (ch>96 && ch<123))
f0100423:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100427:	83 e0 df             	and    $0xffffffdf,%eax
f010042a:	8d 50 bf             	lea    -0x41(%eax),%edx
			c |= 0x0700;
f010042d:	89 f9                	mov    %edi,%ecx
f010042f:	80 cd 07             	or     $0x7,%ch
f0100432:	89 f8                	mov    %edi,%eax
f0100434:	80 cc 04             	or     $0x4,%ah
f0100437:	80 fa 19             	cmp    $0x19,%dl
f010043a:	89 cf                	mov    %ecx,%edi
f010043c:	0f 47 f8             	cmova  %eax,%edi
f010043f:	eb 87                	jmp    f01003c8 <cons_putc+0xa3>
	switch (c & 0xff) {
f0100441:	83 f8 0d             	cmp    $0xd,%eax
f0100444:	0f 85 9b 00 00 00    	jne    f01004e5 <cons_putc+0x1c0>
		crt_pos -= (crt_pos % CRT_COLS);
f010044a:	0f b7 83 0c 23 00 00 	movzwl 0x230c(%ebx),%eax
f0100451:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100457:	c1 e8 16             	shr    $0x16,%eax
f010045a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010045d:	c1 e0 04             	shl    $0x4,%eax
f0100460:	66 89 83 0c 23 00 00 	mov    %ax,0x230c(%ebx)
	if (crt_pos >= CRT_SIZE) {
f0100467:	66 81 bb 0c 23 00 00 	cmpw   $0x7cf,0x230c(%ebx)
f010046e:	cf 07 
f0100470:	0f 87 92 00 00 00    	ja     f0100508 <cons_putc+0x1e3>
	outb(addr_6845, 14);
f0100476:	8b 8b 14 23 00 00    	mov    0x2314(%ebx),%ecx
f010047c:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100481:	89 ca                	mov    %ecx,%edx
f0100483:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100484:	0f b7 9b 0c 23 00 00 	movzwl 0x230c(%ebx),%ebx
f010048b:	8d 71 01             	lea    0x1(%ecx),%esi
f010048e:	89 d8                	mov    %ebx,%eax
f0100490:	66 c1 e8 08          	shr    $0x8,%ax
f0100494:	89 f2                	mov    %esi,%edx
f0100496:	ee                   	out    %al,(%dx)
f0100497:	b8 0f 00 00 00       	mov    $0xf,%eax
f010049c:	89 ca                	mov    %ecx,%edx
f010049e:	ee                   	out    %al,(%dx)
f010049f:	89 d8                	mov    %ebx,%eax
f01004a1:	89 f2                	mov    %esi,%edx
f01004a3:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004a4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004a7:	5b                   	pop    %ebx
f01004a8:	5e                   	pop    %esi
f01004a9:	5f                   	pop    %edi
f01004aa:	5d                   	pop    %ebp
f01004ab:	c3                   	ret    
		if (crt_pos > 0) {
f01004ac:	0f b7 83 0c 23 00 00 	movzwl 0x230c(%ebx),%eax
f01004b3:	66 85 c0             	test   %ax,%ax
f01004b6:	74 be                	je     f0100476 <cons_putc+0x151>
			crt_pos--;
f01004b8:	83 e8 01             	sub    $0x1,%eax
f01004bb:	66 89 83 0c 23 00 00 	mov    %ax,0x230c(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004c2:	0f b7 c0             	movzwl %ax,%eax
f01004c5:	89 fa                	mov    %edi,%edx
f01004c7:	b2 00                	mov    $0x0,%dl
f01004c9:	83 ca 20             	or     $0x20,%edx
f01004cc:	8b 8b 10 23 00 00    	mov    0x2310(%ebx),%ecx
f01004d2:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f01004d6:	eb 8f                	jmp    f0100467 <cons_putc+0x142>
		crt_pos += CRT_COLS;
f01004d8:	66 83 83 0c 23 00 00 	addw   $0x50,0x230c(%ebx)
f01004df:	50 
f01004e0:	e9 65 ff ff ff       	jmp    f010044a <cons_putc+0x125>
		crt_buf[crt_pos++] = c;		/* write the character */
f01004e5:	0f b7 83 0c 23 00 00 	movzwl 0x230c(%ebx),%eax
f01004ec:	8d 50 01             	lea    0x1(%eax),%edx
f01004ef:	66 89 93 0c 23 00 00 	mov    %dx,0x230c(%ebx)
f01004f6:	0f b7 c0             	movzwl %ax,%eax
f01004f9:	8b 93 10 23 00 00    	mov    0x2310(%ebx),%edx
f01004ff:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
f0100503:	e9 5f ff ff ff       	jmp    f0100467 <cons_putc+0x142>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100508:	8b 83 10 23 00 00    	mov    0x2310(%ebx),%eax
f010050e:	83 ec 04             	sub    $0x4,%esp
f0100511:	68 00 0f 00 00       	push   $0xf00
f0100516:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010051c:	52                   	push   %edx
f010051d:	50                   	push   %eax
f010051e:	e8 8a 4c 00 00       	call   f01051ad <memmove>
			crt_buf[i] = 0x0700 | ' ';
f0100523:	8b 93 10 23 00 00    	mov    0x2310(%ebx),%edx
f0100529:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010052f:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100535:	83 c4 10             	add    $0x10,%esp
f0100538:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010053d:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100540:	39 d0                	cmp    %edx,%eax
f0100542:	75 f4                	jne    f0100538 <cons_putc+0x213>
		crt_pos -= CRT_COLS;
f0100544:	66 83 ab 0c 23 00 00 	subw   $0x50,0x230c(%ebx)
f010054b:	50 
f010054c:	e9 25 ff ff ff       	jmp    f0100476 <cons_putc+0x151>

f0100551 <serial_intr>:
{
f0100551:	f3 0f 1e fb          	endbr32 
f0100555:	e8 f6 01 00 00       	call   f0100750 <__x86.get_pc_thunk.ax>
f010055a:	05 c2 da 08 00       	add    $0x8dac2,%eax
	if (serial_exists)
f010055f:	80 b8 18 23 00 00 00 	cmpb   $0x0,0x2318(%eax)
f0100566:	75 01                	jne    f0100569 <serial_intr+0x18>
f0100568:	c3                   	ret    
{
f0100569:	55                   	push   %ebp
f010056a:	89 e5                	mov    %esp,%ebp
f010056c:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f010056f:	8d 80 5b 21 f7 ff    	lea    -0x8dea5(%eax),%eax
f0100575:	e8 1b fc ff ff       	call   f0100195 <cons_intr>
}
f010057a:	c9                   	leave  
f010057b:	c3                   	ret    

f010057c <kbd_intr>:
{
f010057c:	f3 0f 1e fb          	endbr32 
f0100580:	55                   	push   %ebp
f0100581:	89 e5                	mov    %esp,%ebp
f0100583:	83 ec 08             	sub    $0x8,%esp
f0100586:	e8 c5 01 00 00       	call   f0100750 <__x86.get_pc_thunk.ax>
f010058b:	05 91 da 08 00       	add    $0x8da91,%eax
	cons_intr(kbd_proc_data);
f0100590:	8d 80 db 21 f7 ff    	lea    -0x8de25(%eax),%eax
f0100596:	e8 fa fb ff ff       	call   f0100195 <cons_intr>
}
f010059b:	c9                   	leave  
f010059c:	c3                   	ret    

f010059d <cons_getc>:
{
f010059d:	f3 0f 1e fb          	endbr32 
f01005a1:	55                   	push   %ebp
f01005a2:	89 e5                	mov    %esp,%ebp
f01005a4:	53                   	push   %ebx
f01005a5:	83 ec 04             	sub    $0x4,%esp
f01005a8:	e8 c6 fb ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01005ad:	81 c3 6f da 08 00    	add    $0x8da6f,%ebx
	serial_intr();
f01005b3:	e8 99 ff ff ff       	call   f0100551 <serial_intr>
	kbd_intr();
f01005b8:	e8 bf ff ff ff       	call   f010057c <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01005bd:	8b 83 04 23 00 00    	mov    0x2304(%ebx),%eax
	return 0;
f01005c3:	ba 00 00 00 00       	mov    $0x0,%edx
	if (cons.rpos != cons.wpos) {
f01005c8:	3b 83 08 23 00 00    	cmp    0x2308(%ebx),%eax
f01005ce:	74 1f                	je     f01005ef <cons_getc+0x52>
		c = cons.buf[cons.rpos++];
f01005d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01005d3:	0f b6 94 03 04 21 00 	movzbl 0x2104(%ebx,%eax,1),%edx
f01005da:	00 
			cons.rpos = 0;
f01005db:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01005e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e6:	0f 44 c8             	cmove  %eax,%ecx
f01005e9:	89 8b 04 23 00 00    	mov    %ecx,0x2304(%ebx)
}
f01005ef:	89 d0                	mov    %edx,%eax
f01005f1:	83 c4 04             	add    $0x4,%esp
f01005f4:	5b                   	pop    %ebx
f01005f5:	5d                   	pop    %ebp
f01005f6:	c3                   	ret    

f01005f7 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005f7:	f3 0f 1e fb          	endbr32 
f01005fb:	55                   	push   %ebp
f01005fc:	89 e5                	mov    %esp,%ebp
f01005fe:	57                   	push   %edi
f01005ff:	56                   	push   %esi
f0100600:	53                   	push   %ebx
f0100601:	83 ec 1c             	sub    $0x1c,%esp
f0100604:	e8 6a fb ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0100609:	81 c3 13 da 08 00    	add    $0x8da13,%ebx
	was = *cp;
f010060f:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100616:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010061d:	5a a5 
	if (*cp != 0xA55A) {
f010061f:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100626:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010062a:	0f 84 bc 00 00 00    	je     f01006ec <cons_init+0xf5>
		addr_6845 = MONO_BASE;
f0100630:	c7 83 14 23 00 00 b4 	movl   $0x3b4,0x2314(%ebx)
f0100637:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010063a:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f0100641:	8b bb 14 23 00 00    	mov    0x2314(%ebx),%edi
f0100647:	b8 0e 00 00 00       	mov    $0xe,%eax
f010064c:	89 fa                	mov    %edi,%edx
f010064e:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010064f:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100652:	89 ca                	mov    %ecx,%edx
f0100654:	ec                   	in     (%dx),%al
f0100655:	0f b6 f0             	movzbl %al,%esi
f0100658:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010065b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100660:	89 fa                	mov    %edi,%edx
f0100662:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100663:	89 ca                	mov    %ecx,%edx
f0100665:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100666:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100669:	89 bb 10 23 00 00    	mov    %edi,0x2310(%ebx)
	pos |= inb(addr_6845 + 1);
f010066f:	0f b6 c0             	movzbl %al,%eax
f0100672:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f0100674:	66 89 b3 0c 23 00 00 	mov    %si,0x230c(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010067b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100680:	89 c8                	mov    %ecx,%eax
f0100682:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100687:	ee                   	out    %al,(%dx)
f0100688:	bf fb 03 00 00       	mov    $0x3fb,%edi
f010068d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100692:	89 fa                	mov    %edi,%edx
f0100694:	ee                   	out    %al,(%dx)
f0100695:	b8 0c 00 00 00       	mov    $0xc,%eax
f010069a:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010069f:	ee                   	out    %al,(%dx)
f01006a0:	be f9 03 00 00       	mov    $0x3f9,%esi
f01006a5:	89 c8                	mov    %ecx,%eax
f01006a7:	89 f2                	mov    %esi,%edx
f01006a9:	ee                   	out    %al,(%dx)
f01006aa:	b8 03 00 00 00       	mov    $0x3,%eax
f01006af:	89 fa                	mov    %edi,%edx
f01006b1:	ee                   	out    %al,(%dx)
f01006b2:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01006b7:	89 c8                	mov    %ecx,%eax
f01006b9:	ee                   	out    %al,(%dx)
f01006ba:	b8 01 00 00 00       	mov    $0x1,%eax
f01006bf:	89 f2                	mov    %esi,%edx
f01006c1:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006c2:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01006c7:	ec                   	in     (%dx),%al
f01006c8:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01006ca:	3c ff                	cmp    $0xff,%al
f01006cc:	0f 95 83 18 23 00 00 	setne  0x2318(%ebx)
f01006d3:	ba fa 03 00 00       	mov    $0x3fa,%edx
f01006d8:	ec                   	in     (%dx),%al
f01006d9:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006de:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01006df:	80 f9 ff             	cmp    $0xff,%cl
f01006e2:	74 25                	je     f0100709 <cons_init+0x112>
		cprintf("Serial port does not exist!\n");
}
f01006e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006e7:	5b                   	pop    %ebx
f01006e8:	5e                   	pop    %esi
f01006e9:	5f                   	pop    %edi
f01006ea:	5d                   	pop    %ebp
f01006eb:	c3                   	ret    
		*cp = was;
f01006ec:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006f3:	c7 83 14 23 00 00 d4 	movl   $0x3d4,0x2314(%ebx)
f01006fa:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006fd:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f0100704:	e9 38 ff ff ff       	jmp    f0100641 <cons_init+0x4a>
		cprintf("Serial port does not exist!\n");
f0100709:	83 ec 0c             	sub    $0xc,%esp
f010070c:	8d 83 1d 76 f7 ff    	lea    -0x889e3(%ebx),%eax
f0100712:	50                   	push   %eax
f0100713:	e8 20 33 00 00       	call   f0103a38 <cprintf>
f0100718:	83 c4 10             	add    $0x10,%esp
}
f010071b:	eb c7                	jmp    f01006e4 <cons_init+0xed>

f010071d <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010071d:	f3 0f 1e fb          	endbr32 
f0100721:	55                   	push   %ebp
f0100722:	89 e5                	mov    %esp,%ebp
f0100724:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100727:	8b 45 08             	mov    0x8(%ebp),%eax
f010072a:	e8 f6 fb ff ff       	call   f0100325 <cons_putc>
}
f010072f:	c9                   	leave  
f0100730:	c3                   	ret    

f0100731 <getchar>:

int
getchar(void)
{
f0100731:	f3 0f 1e fb          	endbr32 
f0100735:	55                   	push   %ebp
f0100736:	89 e5                	mov    %esp,%ebp
f0100738:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010073b:	e8 5d fe ff ff       	call   f010059d <cons_getc>
f0100740:	85 c0                	test   %eax,%eax
f0100742:	74 f7                	je     f010073b <getchar+0xa>
		/* do nothing */;
	return c;
}
f0100744:	c9                   	leave  
f0100745:	c3                   	ret    

f0100746 <iscons>:

int
iscons(int fdnum)
{
f0100746:	f3 0f 1e fb          	endbr32 
	// used by readline
	return 1;
}
f010074a:	b8 01 00 00 00       	mov    $0x1,%eax
f010074f:	c3                   	ret    

f0100750 <__x86.get_pc_thunk.ax>:
f0100750:	8b 04 24             	mov    (%esp),%eax
f0100753:	c3                   	ret    

f0100754 <__x86.get_pc_thunk.si>:
f0100754:	8b 34 24             	mov    (%esp),%esi
f0100757:	c3                   	ret    

f0100758 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100758:	f3 0f 1e fb          	endbr32 
f010075c:	55                   	push   %ebp
f010075d:	89 e5                	mov    %esp,%ebp
f010075f:	56                   	push   %esi
f0100760:	53                   	push   %ebx
f0100761:	e8 0d fa ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0100766:	81 c3 b6 d8 08 00    	add    $0x8d8b6,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010076c:	83 ec 04             	sub    $0x4,%esp
f010076f:	8d 83 44 78 f7 ff    	lea    -0x887bc(%ebx),%eax
f0100775:	50                   	push   %eax
f0100776:	8d 83 62 78 f7 ff    	lea    -0x8879e(%ebx),%eax
f010077c:	50                   	push   %eax
f010077d:	8d b3 67 78 f7 ff    	lea    -0x88799(%ebx),%esi
f0100783:	56                   	push   %esi
f0100784:	e8 af 32 00 00       	call   f0103a38 <cprintf>
f0100789:	83 c4 0c             	add    $0xc,%esp
f010078c:	8d 83 34 79 f7 ff    	lea    -0x886cc(%ebx),%eax
f0100792:	50                   	push   %eax
f0100793:	8d 83 70 78 f7 ff    	lea    -0x88790(%ebx),%eax
f0100799:	50                   	push   %eax
f010079a:	56                   	push   %esi
f010079b:	e8 98 32 00 00       	call   f0103a38 <cprintf>
f01007a0:	83 c4 0c             	add    $0xc,%esp
f01007a3:	8d 83 79 78 f7 ff    	lea    -0x88787(%ebx),%eax
f01007a9:	50                   	push   %eax
f01007aa:	8d 83 8f 78 f7 ff    	lea    -0x88771(%ebx),%eax
f01007b0:	50                   	push   %eax
f01007b1:	56                   	push   %esi
f01007b2:	e8 81 32 00 00       	call   f0103a38 <cprintf>
	return 0;
}
f01007b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01007bc:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007bf:	5b                   	pop    %ebx
f01007c0:	5e                   	pop    %esi
f01007c1:	5d                   	pop    %ebp
f01007c2:	c3                   	ret    

f01007c3 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007c3:	f3 0f 1e fb          	endbr32 
f01007c7:	55                   	push   %ebp
f01007c8:	89 e5                	mov    %esp,%ebp
f01007ca:	57                   	push   %edi
f01007cb:	56                   	push   %esi
f01007cc:	53                   	push   %ebx
f01007cd:	83 ec 18             	sub    $0x18,%esp
f01007d0:	e8 9e f9 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01007d5:	81 c3 47 d8 08 00    	add    $0x8d847,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007db:	8d 83 99 78 f7 ff    	lea    -0x88767(%ebx),%eax
f01007e1:	50                   	push   %eax
f01007e2:	e8 51 32 00 00       	call   f0103a38 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007e7:	83 c4 08             	add    $0x8,%esp
f01007ea:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f01007f0:	8d 83 5c 79 f7 ff    	lea    -0x886a4(%ebx),%eax
f01007f6:	50                   	push   %eax
f01007f7:	e8 3c 32 00 00       	call   f0103a38 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007fc:	83 c4 0c             	add    $0xc,%esp
f01007ff:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100805:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f010080b:	50                   	push   %eax
f010080c:	57                   	push   %edi
f010080d:	8d 83 84 79 f7 ff    	lea    -0x8867c(%ebx),%eax
f0100813:	50                   	push   %eax
f0100814:	e8 1f 32 00 00       	call   f0103a38 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100819:	83 c4 0c             	add    $0xc,%esp
f010081c:	c7 c0 cd 55 10 f0    	mov    $0xf01055cd,%eax
f0100822:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100828:	52                   	push   %edx
f0100829:	50                   	push   %eax
f010082a:	8d 83 a8 79 f7 ff    	lea    -0x88658(%ebx),%eax
f0100830:	50                   	push   %eax
f0100831:	e8 02 32 00 00       	call   f0103a38 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100836:	83 c4 0c             	add    $0xc,%esp
f0100839:	c7 c0 00 01 19 f0    	mov    $0xf0190100,%eax
f010083f:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100845:	52                   	push   %edx
f0100846:	50                   	push   %eax
f0100847:	8d 83 cc 79 f7 ff    	lea    -0x88634(%ebx),%eax
f010084d:	50                   	push   %eax
f010084e:	e8 e5 31 00 00       	call   f0103a38 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100853:	83 c4 0c             	add    $0xc,%esp
f0100856:	c7 c6 14 10 19 f0    	mov    $0xf0191014,%esi
f010085c:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0100862:	50                   	push   %eax
f0100863:	56                   	push   %esi
f0100864:	8d 83 f0 79 f7 ff    	lea    -0x88610(%ebx),%eax
f010086a:	50                   	push   %eax
f010086b:	e8 c8 31 00 00       	call   f0103a38 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100870:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100873:	29 fe                	sub    %edi,%esi
f0100875:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f010087b:	c1 fe 0a             	sar    $0xa,%esi
f010087e:	56                   	push   %esi
f010087f:	8d 83 14 7a f7 ff    	lea    -0x885ec(%ebx),%eax
f0100885:	50                   	push   %eax
f0100886:	e8 ad 31 00 00       	call   f0103a38 <cprintf>
	return 0;
}
f010088b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100890:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100893:	5b                   	pop    %ebx
f0100894:	5e                   	pop    %esi
f0100895:	5f                   	pop    %edi
f0100896:	5d                   	pop    %ebp
f0100897:	c3                   	ret    

f0100898 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100898:	f3 0f 1e fb          	endbr32 
f010089c:	55                   	push   %ebp
f010089d:	89 e5                	mov    %esp,%ebp
f010089f:	57                   	push   %edi
f01008a0:	56                   	push   %esi
f01008a1:	53                   	push   %ebx
f01008a2:	83 ec 48             	sub    $0x48,%esp
f01008a5:	e8 c9 f8 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01008aa:	81 c3 72 d7 08 00    	add    $0x8d772,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008b0:	89 e8                	mov    %ebp,%eax
f01008b2:	89 c6                	mov    %eax,%esi
	// Your code here.
	// typedef int (*this_func_type)(int, char **, struct Trapframe *);
	uint32_t ebp = read_ebp();
	uint32_t *ebp_base_ptr = (uint32_t*)ebp;           
f01008b4:	89 c7                	mov    %eax,%edi
	uint32_t eip = ebp_base_ptr[1];
f01008b6:	8b 40 04             	mov    0x4(%eax),%eax
f01008b9:	89 45 c0             	mov    %eax,-0x40(%ebp)
	cprintf("Stack backtrace:\n");
f01008bc:	8d 83 b2 78 f7 ff    	lea    -0x8874e(%ebx),%eax
f01008c2:	50                   	push   %eax
f01008c3:	e8 70 31 00 00       	call   f0103a38 <cprintf>
	while (ebp != 0) {
f01008c8:	83 c4 10             	add    $0x10,%esp
        // print address and arguments info
        cprintf("\tebp %08x, eip %09x, args ", ebp, eip);
f01008cb:	8d 83 c4 78 f7 ff    	lea    -0x8873c(%ebx),%eax
f01008d1:	89 45 b8             	mov    %eax,-0x48(%ebp)

        uint32_t *args = ebp_base_ptr + 2;

        for (int i = 0; i < 5; ++i) {
            cprintf("%08x ", args[i]);
f01008d4:	8d 83 df 78 f7 ff    	lea    -0x88721(%ebx),%eax
f01008da:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	while (ebp != 0) {
f01008dd:	eb 0a                	jmp    f01008e9 <mon_backtrace+0x51>
		{
			uint32_t offset = eip-info.eip_fn_addr;
			cprintf("\t\t%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,offset);
		}
        // update the values
        ebp = (uint32_t)*ebp_base_ptr;
f01008df:	8b 3f                	mov    (%edi),%edi
		ebp_base_ptr = (uint32_t*)ebp;
f01008e1:	89 fe                	mov    %edi,%esi
        eip = ebp_base_ptr[1];
f01008e3:	8b 47 04             	mov    0x4(%edi),%eax
f01008e6:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (ebp != 0) {
f01008e9:	85 f6                	test   %esi,%esi
f01008eb:	0f 84 86 00 00 00    	je     f0100977 <mon_backtrace+0xdf>
        cprintf("\tebp %08x, eip %09x, args ", ebp, eip);
f01008f1:	83 ec 04             	sub    $0x4,%esp
f01008f4:	ff 75 c0             	pushl  -0x40(%ebp)
f01008f7:	56                   	push   %esi
f01008f8:	ff 75 b8             	pushl  -0x48(%ebp)
f01008fb:	e8 38 31 00 00       	call   f0103a38 <cprintf>
f0100900:	8d 77 08             	lea    0x8(%edi),%esi
f0100903:	8d 47 1c             	lea    0x1c(%edi),%eax
f0100906:	83 c4 10             	add    $0x10,%esp
f0100909:	89 7d bc             	mov    %edi,-0x44(%ebp)
f010090c:	89 c7                	mov    %eax,%edi
            cprintf("%08x ", args[i]);
f010090e:	83 ec 08             	sub    $0x8,%esp
f0100911:	ff 36                	pushl  (%esi)
f0100913:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100916:	e8 1d 31 00 00       	call   f0103a38 <cprintf>
f010091b:	83 c6 04             	add    $0x4,%esi
        for (int i = 0; i < 5; ++i) {
f010091e:	83 c4 10             	add    $0x10,%esp
f0100921:	39 fe                	cmp    %edi,%esi
f0100923:	75 e9                	jne    f010090e <mon_backtrace+0x76>
f0100925:	8b 7d bc             	mov    -0x44(%ebp),%edi
        cprintf("\n");
f0100928:	83 ec 0c             	sub    $0xc,%esp
f010092b:	8d 83 8e 85 f7 ff    	lea    -0x87a72(%ebx),%eax
f0100931:	50                   	push   %eax
f0100932:	e8 01 31 00 00       	call   f0103a38 <cprintf>
        if(debuginfo_eip(eip,&info) == 0)
f0100937:	83 c4 08             	add    $0x8,%esp
f010093a:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010093d:	50                   	push   %eax
f010093e:	ff 75 c0             	pushl  -0x40(%ebp)
f0100941:	e8 37 3c 00 00       	call   f010457d <debuginfo_eip>
f0100946:	83 c4 10             	add    $0x10,%esp
f0100949:	85 c0                	test   %eax,%eax
f010094b:	75 92                	jne    f01008df <mon_backtrace+0x47>
			cprintf("\t\t%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,offset);
f010094d:	83 ec 08             	sub    $0x8,%esp
			uint32_t offset = eip-info.eip_fn_addr;
f0100950:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0100953:	2b 45 e0             	sub    -0x20(%ebp),%eax
			cprintf("\t\t%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,offset);
f0100956:	50                   	push   %eax
f0100957:	ff 75 d8             	pushl  -0x28(%ebp)
f010095a:	ff 75 dc             	pushl  -0x24(%ebp)
f010095d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100960:	ff 75 d0             	pushl  -0x30(%ebp)
f0100963:	8d 83 e5 78 f7 ff    	lea    -0x8871b(%ebx),%eax
f0100969:	50                   	push   %eax
f010096a:	e8 c9 30 00 00       	call   f0103a38 <cprintf>
f010096f:	83 c4 20             	add    $0x20,%esp
f0100972:	e9 68 ff ff ff       	jmp    f01008df <mon_backtrace+0x47>
	}

	return 0;
}
f0100977:	b8 00 00 00 00       	mov    $0x0,%eax
f010097c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010097f:	5b                   	pop    %ebx
f0100980:	5e                   	pop    %esi
f0100981:	5f                   	pop    %edi
f0100982:	5d                   	pop    %ebp
f0100983:	c3                   	ret    

f0100984 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100984:	f3 0f 1e fb          	endbr32 
f0100988:	55                   	push   %ebp
f0100989:	89 e5                	mov    %esp,%ebp
f010098b:	57                   	push   %edi
f010098c:	56                   	push   %esi
f010098d:	53                   	push   %ebx
f010098e:	83 ec 68             	sub    $0x68,%esp
f0100991:	e8 dd f7 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0100996:	81 c3 86 d6 08 00    	add    $0x8d686,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010099c:	8d 83 40 7a f7 ff    	lea    -0x885c0(%ebx),%eax
f01009a2:	50                   	push   %eax
f01009a3:	e8 90 30 00 00       	call   f0103a38 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009a8:	8d 83 64 7a f7 ff    	lea    -0x8859c(%ebx),%eax
f01009ae:	89 04 24             	mov    %eax,(%esp)
f01009b1:	e8 82 30 00 00       	call   f0103a38 <cprintf>

	if (tf != NULL)
f01009b6:	83 c4 10             	add    $0x10,%esp
f01009b9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01009bd:	74 0e                	je     f01009cd <monitor+0x49>
		print_trapframe(tf);
f01009bf:	83 ec 0c             	sub    $0xc,%esp
f01009c2:	ff 75 08             	pushl  0x8(%ebp)
f01009c5:	e8 89 35 00 00       	call   f0103f53 <print_trapframe>
f01009ca:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f01009cd:	8d 83 fb 78 f7 ff    	lea    -0x88705(%ebx),%eax
f01009d3:	89 45 a0             	mov    %eax,-0x60(%ebp)
f01009d6:	e9 d1 00 00 00       	jmp    f0100aac <monitor+0x128>
f01009db:	83 ec 08             	sub    $0x8,%esp
f01009de:	0f be c0             	movsbl %al,%eax
f01009e1:	50                   	push   %eax
f01009e2:	ff 75 a0             	pushl  -0x60(%ebp)
f01009e5:	e8 32 47 00 00       	call   f010511c <strchr>
f01009ea:	83 c4 10             	add    $0x10,%esp
f01009ed:	85 c0                	test   %eax,%eax
f01009ef:	74 6d                	je     f0100a5e <monitor+0xda>
			*buf++ = 0;
f01009f1:	c6 06 00             	movb   $0x0,(%esi)
f01009f4:	89 7d a4             	mov    %edi,-0x5c(%ebp)
f01009f7:	8d 76 01             	lea    0x1(%esi),%esi
f01009fa:	8b 7d a4             	mov    -0x5c(%ebp),%edi
		while (*buf && strchr(WHITESPACE, *buf))
f01009fd:	0f b6 06             	movzbl (%esi),%eax
f0100a00:	84 c0                	test   %al,%al
f0100a02:	75 d7                	jne    f01009db <monitor+0x57>
	argv[argc] = 0;
f0100a04:	c7 44 bd a8 00 00 00 	movl   $0x0,-0x58(%ebp,%edi,4)
f0100a0b:	00 
	if (argc == 0)
f0100a0c:	85 ff                	test   %edi,%edi
f0100a0e:	0f 84 98 00 00 00    	je     f0100aac <monitor+0x128>
f0100a14:	8d b3 24 20 00 00    	lea    0x2024(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a1a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a1f:	89 7d a4             	mov    %edi,-0x5c(%ebp)
f0100a22:	89 c7                	mov    %eax,%edi
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a24:	83 ec 08             	sub    $0x8,%esp
f0100a27:	ff 36                	pushl  (%esi)
f0100a29:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a2c:	e8 85 46 00 00       	call   f01050b6 <strcmp>
f0100a31:	83 c4 10             	add    $0x10,%esp
f0100a34:	85 c0                	test   %eax,%eax
f0100a36:	0f 84 99 00 00 00    	je     f0100ad5 <monitor+0x151>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a3c:	83 c7 01             	add    $0x1,%edi
f0100a3f:	83 c6 0c             	add    $0xc,%esi
f0100a42:	83 ff 03             	cmp    $0x3,%edi
f0100a45:	75 dd                	jne    f0100a24 <monitor+0xa0>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a47:	83 ec 08             	sub    $0x8,%esp
f0100a4a:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a4d:	8d 83 1d 79 f7 ff    	lea    -0x886e3(%ebx),%eax
f0100a53:	50                   	push   %eax
f0100a54:	e8 df 2f 00 00       	call   f0103a38 <cprintf>
	return 0;
f0100a59:	83 c4 10             	add    $0x10,%esp
f0100a5c:	eb 4e                	jmp    f0100aac <monitor+0x128>
		if (*buf == 0)
f0100a5e:	80 3e 00             	cmpb   $0x0,(%esi)
f0100a61:	74 a1                	je     f0100a04 <monitor+0x80>
		if (argc == MAXARGS-1) {
f0100a63:	83 ff 0f             	cmp    $0xf,%edi
f0100a66:	74 30                	je     f0100a98 <monitor+0x114>
		argv[argc++] = buf;
f0100a68:	8d 47 01             	lea    0x1(%edi),%eax
f0100a6b:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100a6e:	89 74 bd a8          	mov    %esi,-0x58(%ebp,%edi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a72:	0f b6 06             	movzbl (%esi),%eax
f0100a75:	84 c0                	test   %al,%al
f0100a77:	74 81                	je     f01009fa <monitor+0x76>
f0100a79:	83 ec 08             	sub    $0x8,%esp
f0100a7c:	0f be c0             	movsbl %al,%eax
f0100a7f:	50                   	push   %eax
f0100a80:	ff 75 a0             	pushl  -0x60(%ebp)
f0100a83:	e8 94 46 00 00       	call   f010511c <strchr>
f0100a88:	83 c4 10             	add    $0x10,%esp
f0100a8b:	85 c0                	test   %eax,%eax
f0100a8d:	0f 85 67 ff ff ff    	jne    f01009fa <monitor+0x76>
			buf++;
f0100a93:	83 c6 01             	add    $0x1,%esi
f0100a96:	eb da                	jmp    f0100a72 <monitor+0xee>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a98:	83 ec 08             	sub    $0x8,%esp
f0100a9b:	6a 10                	push   $0x10
f0100a9d:	8d 83 00 79 f7 ff    	lea    -0x88700(%ebx),%eax
f0100aa3:	50                   	push   %eax
f0100aa4:	e8 8f 2f 00 00       	call   f0103a38 <cprintf>
			return 0;
f0100aa9:	83 c4 10             	add    $0x10,%esp
	// cprintf("x %d, y %x, z %d\n", x, y, z);
	// unsigned int i = 0x00646c72;
 	// cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100aac:	8d bb f7 78 f7 ff    	lea    -0x88709(%ebx),%edi
f0100ab2:	83 ec 0c             	sub    $0xc,%esp
f0100ab5:	57                   	push   %edi
f0100ab6:	e8 f0 43 00 00       	call   f0104eab <readline>
		if (buf != NULL)
f0100abb:	83 c4 10             	add    $0x10,%esp
f0100abe:	85 c0                	test   %eax,%eax
f0100ac0:	74 f0                	je     f0100ab2 <monitor+0x12e>
f0100ac2:	89 c6                	mov    %eax,%esi
	argv[argc] = 0;
f0100ac4:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100acb:	bf 00 00 00 00       	mov    $0x0,%edi
f0100ad0:	e9 28 ff ff ff       	jmp    f01009fd <monitor+0x79>
f0100ad5:	89 f8                	mov    %edi,%eax
f0100ad7:	8b 7d a4             	mov    -0x5c(%ebp),%edi
			return commands[i].func(argc, argv, tf);
f0100ada:	83 ec 04             	sub    $0x4,%esp
f0100add:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100ae0:	ff 75 08             	pushl  0x8(%ebp)
f0100ae3:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100ae6:	52                   	push   %edx
f0100ae7:	57                   	push   %edi
f0100ae8:	ff 94 83 2c 20 00 00 	call   *0x202c(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100aef:	83 c4 10             	add    $0x10,%esp
f0100af2:	85 c0                	test   %eax,%eax
f0100af4:	79 b6                	jns    f0100aac <monitor+0x128>
				break;
	}
}
f0100af6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100af9:	5b                   	pop    %ebx
f0100afa:	5e                   	pop    %esi
f0100afb:	5f                   	pop    %edi
f0100afc:	5d                   	pop    %ebp
f0100afd:	c3                   	ret    

f0100afe <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100afe:	55                   	push   %ebp
f0100aff:	89 e5                	mov    %esp,%ebp
f0100b01:	57                   	push   %edi
f0100b02:	56                   	push   %esi
f0100b03:	53                   	push   %ebx
f0100b04:	83 ec 18             	sub    $0x18,%esp
f0100b07:	e8 67 f6 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0100b0c:	81 c3 10 d5 08 00    	add    $0x8d510,%ebx
f0100b12:	89 c6                	mov    %eax,%esi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100b14:	50                   	push   %eax
f0100b15:	e8 87 2e 00 00       	call   f01039a1 <mc146818_read>
f0100b1a:	89 c7                	mov    %eax,%edi
f0100b1c:	83 c6 01             	add    $0x1,%esi
f0100b1f:	89 34 24             	mov    %esi,(%esp)
f0100b22:	e8 7a 2e 00 00       	call   f01039a1 <mc146818_read>
f0100b27:	c1 e0 08             	shl    $0x8,%eax
f0100b2a:	09 f8                	or     %edi,%eax
}
f0100b2c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100b2f:	5b                   	pop    %ebx
f0100b30:	5e                   	pop    %esi
f0100b31:	5f                   	pop    %edi
f0100b32:	5d                   	pop    %ebp
f0100b33:	c3                   	ret    

f0100b34 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b34:	e8 42 26 00 00       	call   f010317b <__x86.get_pc_thunk.dx>
f0100b39:	81 c2 e3 d4 08 00    	add    $0x8d4e3,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b3f:	83 ba 1c 23 00 00 00 	cmpl   $0x0,0x231c(%edx)
f0100b46:	74 3e                	je     f0100b86 <boot_alloc+0x52>
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.

	// special case
	if(n == 0)
f0100b48:	85 c0                	test   %eax,%eax
f0100b4a:	74 54                	je     f0100ba0 <boot_alloc+0x6c>
{
f0100b4c:	55                   	push   %ebp
f0100b4d:	89 e5                	mov    %esp,%ebp
f0100b4f:	53                   	push   %ebx
f0100b50:	83 ec 04             	sub    $0x4,%esp
	{
		return nextfree;
	}

	// allocate memory 
	result = nextfree;
f0100b53:	8b 8a 1c 23 00 00    	mov    0x231c(%edx),%ecx
	nextfree = ROUNDUP(n,PGSIZE)+nextfree;
f0100b59:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100b5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b63:	01 c8                	add    %ecx,%eax
f0100b65:	89 82 1c 23 00 00    	mov    %eax,0x231c(%edx)

	// out of memory panic
	if((uint32_t)nextfree-KERNBASE>(npages*PGSIZE))
f0100b6b:	05 00 00 00 10       	add    $0x10000000,%eax
f0100b70:	c7 c3 08 10 19 f0    	mov    $0xf0191008,%ebx
f0100b76:	8b 1b                	mov    (%ebx),%ebx
f0100b78:	c1 e3 0c             	shl    $0xc,%ebx
f0100b7b:	39 d8                	cmp    %ebx,%eax
f0100b7d:	77 2a                	ja     f0100ba9 <boot_alloc+0x75>
		nextfree = result;
		return NULL;
	}
	return result;

}
f0100b7f:	89 c8                	mov    %ecx,%eax
f0100b81:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b84:	c9                   	leave  
f0100b85:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b86:	c7 c1 14 10 19 f0    	mov    $0xf0191014,%ecx
f0100b8c:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100b92:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100b98:	89 8a 1c 23 00 00    	mov    %ecx,0x231c(%edx)
f0100b9e:	eb a8                	jmp    f0100b48 <boot_alloc+0x14>
		return nextfree;
f0100ba0:	8b 8a 1c 23 00 00    	mov    0x231c(%edx),%ecx
}
f0100ba6:	89 c8                	mov    %ecx,%eax
f0100ba8:	c3                   	ret    
		panic("at pmap.c:boot_alloc(): out of memory");
f0100ba9:	83 ec 04             	sub    $0x4,%esp
f0100bac:	8d 82 8c 7a f7 ff    	lea    -0x88574(%edx),%eax
f0100bb2:	50                   	push   %eax
f0100bb3:	6a 78                	push   $0x78
f0100bb5:	8d 82 dd 82 f7 ff    	lea    -0x87d23(%edx),%eax
f0100bbb:	50                   	push   %eax
f0100bbc:	89 d3                	mov    %edx,%ebx
f0100bbe:	e8 f2 f4 ff ff       	call   f01000b5 <_panic>

f0100bc3 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100bc3:	55                   	push   %ebp
f0100bc4:	89 e5                	mov    %esp,%ebp
f0100bc6:	56                   	push   %esi
f0100bc7:	53                   	push   %ebx
f0100bc8:	e8 b2 25 00 00       	call   f010317f <__x86.get_pc_thunk.cx>
f0100bcd:	81 c1 4f d4 08 00    	add    $0x8d44f,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100bd3:	89 d3                	mov    %edx,%ebx
f0100bd5:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100bd8:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100bdb:	a8 01                	test   $0x1,%al
f0100bdd:	74 59                	je     f0100c38 <check_va2pa+0x75>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100bdf:	89 c3                	mov    %eax,%ebx
f0100be1:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100be7:	c1 e8 0c             	shr    $0xc,%eax
f0100bea:	c7 c6 08 10 19 f0    	mov    $0xf0191008,%esi
f0100bf0:	3b 06                	cmp    (%esi),%eax
f0100bf2:	73 29                	jae    f0100c1d <check_va2pa+0x5a>
	if (!(p[PTX(va)] & PTE_P))
f0100bf4:	c1 ea 0c             	shr    $0xc,%edx
f0100bf7:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100bfd:	8b 94 93 00 00 00 f0 	mov    -0x10000000(%ebx,%edx,4),%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100c04:	89 d0                	mov    %edx,%eax
f0100c06:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c0b:	f6 c2 01             	test   $0x1,%dl
f0100c0e:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100c13:	0f 44 c2             	cmove  %edx,%eax
}
f0100c16:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100c19:	5b                   	pop    %ebx
f0100c1a:	5e                   	pop    %esi
f0100c1b:	5d                   	pop    %ebp
f0100c1c:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c1d:	53                   	push   %ebx
f0100c1e:	8d 81 b4 7a f7 ff    	lea    -0x8854c(%ecx),%eax
f0100c24:	50                   	push   %eax
f0100c25:	68 9b 03 00 00       	push   $0x39b
f0100c2a:	8d 81 dd 82 f7 ff    	lea    -0x87d23(%ecx),%eax
f0100c30:	50                   	push   %eax
f0100c31:	89 cb                	mov    %ecx,%ebx
f0100c33:	e8 7d f4 ff ff       	call   f01000b5 <_panic>
		return ~0;
f0100c38:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c3d:	eb d7                	jmp    f0100c16 <check_va2pa+0x53>

f0100c3f <check_page_free_list>:
{
f0100c3f:	55                   	push   %ebp
f0100c40:	89 e5                	mov    %esp,%ebp
f0100c42:	57                   	push   %edi
f0100c43:	56                   	push   %esi
f0100c44:	53                   	push   %ebx
f0100c45:	83 ec 2c             	sub    $0x2c,%esp
f0100c48:	e8 07 fb ff ff       	call   f0100754 <__x86.get_pc_thunk.si>
f0100c4d:	81 c6 cf d3 08 00    	add    $0x8d3cf,%esi
f0100c53:	89 75 c8             	mov    %esi,-0x38(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c56:	84 c0                	test   %al,%al
f0100c58:	0f 85 ec 02 00 00    	jne    f0100f4a <check_page_free_list+0x30b>
	if (!page_free_list)
f0100c5e:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100c61:	83 b8 24 23 00 00 00 	cmpl   $0x0,0x2324(%eax)
f0100c68:	74 21                	je     f0100c8b <check_page_free_list+0x4c>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c6a:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c71:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100c74:	8b b0 24 23 00 00    	mov    0x2324(%eax),%esi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c7a:	c7 c7 10 10 19 f0    	mov    $0xf0191010,%edi
	if (PGNUM(pa) >= npages)
f0100c80:	c7 c0 08 10 19 f0    	mov    $0xf0191008,%eax
f0100c86:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100c89:	eb 39                	jmp    f0100cc4 <check_page_free_list+0x85>
		panic("'page_free_list' is a null pointer!");
f0100c8b:	83 ec 04             	sub    $0x4,%esp
f0100c8e:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100c91:	8d 83 d8 7a f7 ff    	lea    -0x88528(%ebx),%eax
f0100c97:	50                   	push   %eax
f0100c98:	68 d7 02 00 00       	push   $0x2d7
f0100c9d:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0100ca3:	50                   	push   %eax
f0100ca4:	e8 0c f4 ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ca9:	50                   	push   %eax
f0100caa:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100cad:	8d 83 b4 7a f7 ff    	lea    -0x8854c(%ebx),%eax
f0100cb3:	50                   	push   %eax
f0100cb4:	6a 56                	push   $0x56
f0100cb6:	8d 83 e9 82 f7 ff    	lea    -0x87d17(%ebx),%eax
f0100cbc:	50                   	push   %eax
f0100cbd:	e8 f3 f3 ff ff       	call   f01000b5 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100cc2:	8b 36                	mov    (%esi),%esi
f0100cc4:	85 f6                	test   %esi,%esi
f0100cc6:	74 40                	je     f0100d08 <check_page_free_list+0xc9>
	return (pp - pages) << PGSHIFT;
f0100cc8:	89 f0                	mov    %esi,%eax
f0100cca:	2b 07                	sub    (%edi),%eax
f0100ccc:	c1 f8 03             	sar    $0x3,%eax
f0100ccf:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100cd2:	89 c2                	mov    %eax,%edx
f0100cd4:	c1 ea 16             	shr    $0x16,%edx
f0100cd7:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100cda:	73 e6                	jae    f0100cc2 <check_page_free_list+0x83>
	if (PGNUM(pa) >= npages)
f0100cdc:	89 c2                	mov    %eax,%edx
f0100cde:	c1 ea 0c             	shr    $0xc,%edx
f0100ce1:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100ce4:	3b 11                	cmp    (%ecx),%edx
f0100ce6:	73 c1                	jae    f0100ca9 <check_page_free_list+0x6a>
			memset(page2kva(pp), 0x97, 128);
f0100ce8:	83 ec 04             	sub    $0x4,%esp
f0100ceb:	68 80 00 00 00       	push   $0x80
f0100cf0:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100cf5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cfa:	50                   	push   %eax
f0100cfb:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100cfe:	e8 5e 44 00 00       	call   f0105161 <memset>
f0100d03:	83 c4 10             	add    $0x10,%esp
f0100d06:	eb ba                	jmp    f0100cc2 <check_page_free_list+0x83>
	first_free_page = (char *) boot_alloc(0);
f0100d08:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d0d:	e8 22 fe ff ff       	call   f0100b34 <boot_alloc>
f0100d12:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d15:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0100d18:	8b 97 24 23 00 00    	mov    0x2324(%edi),%edx
		assert(pp >= pages);
f0100d1e:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f0100d24:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100d26:	c7 c0 08 10 19 f0    	mov    $0xf0191008,%eax
f0100d2c:	8b 00                	mov    (%eax),%eax
f0100d2e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100d31:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
	int nfree_basemem = 0, nfree_extmem = 0;
f0100d34:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100d39:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d3c:	e9 08 01 00 00       	jmp    f0100e49 <check_page_free_list+0x20a>
		assert(pp >= pages);
f0100d41:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100d44:	8d 83 f7 82 f7 ff    	lea    -0x87d09(%ebx),%eax
f0100d4a:	50                   	push   %eax
f0100d4b:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0100d51:	50                   	push   %eax
f0100d52:	68 f1 02 00 00       	push   $0x2f1
f0100d57:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0100d5d:	50                   	push   %eax
f0100d5e:	e8 52 f3 ff ff       	call   f01000b5 <_panic>
		assert(pp < pages + npages);
f0100d63:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100d66:	8d 83 18 83 f7 ff    	lea    -0x87ce8(%ebx),%eax
f0100d6c:	50                   	push   %eax
f0100d6d:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0100d73:	50                   	push   %eax
f0100d74:	68 f2 02 00 00       	push   $0x2f2
f0100d79:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0100d7f:	50                   	push   %eax
f0100d80:	e8 30 f3 ff ff       	call   f01000b5 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d85:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100d88:	8d 83 fc 7a f7 ff    	lea    -0x88504(%ebx),%eax
f0100d8e:	50                   	push   %eax
f0100d8f:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0100d95:	50                   	push   %eax
f0100d96:	68 f3 02 00 00       	push   $0x2f3
f0100d9b:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0100da1:	50                   	push   %eax
f0100da2:	e8 0e f3 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) != 0);
f0100da7:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100daa:	8d 83 2c 83 f7 ff    	lea    -0x87cd4(%ebx),%eax
f0100db0:	50                   	push   %eax
f0100db1:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0100db7:	50                   	push   %eax
f0100db8:	68 f6 02 00 00       	push   $0x2f6
f0100dbd:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0100dc3:	50                   	push   %eax
f0100dc4:	e8 ec f2 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100dc9:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100dcc:	8d 83 3d 83 f7 ff    	lea    -0x87cc3(%ebx),%eax
f0100dd2:	50                   	push   %eax
f0100dd3:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0100dd9:	50                   	push   %eax
f0100dda:	68 f7 02 00 00       	push   $0x2f7
f0100ddf:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0100de5:	50                   	push   %eax
f0100de6:	e8 ca f2 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100deb:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100dee:	8d 83 30 7b f7 ff    	lea    -0x884d0(%ebx),%eax
f0100df4:	50                   	push   %eax
f0100df5:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0100dfb:	50                   	push   %eax
f0100dfc:	68 f8 02 00 00       	push   $0x2f8
f0100e01:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0100e07:	50                   	push   %eax
f0100e08:	e8 a8 f2 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100e0d:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100e10:	8d 83 56 83 f7 ff    	lea    -0x87caa(%ebx),%eax
f0100e16:	50                   	push   %eax
f0100e17:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0100e1d:	50                   	push   %eax
f0100e1e:	68 f9 02 00 00       	push   $0x2f9
f0100e23:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0100e29:	50                   	push   %eax
f0100e2a:	e8 86 f2 ff ff       	call   f01000b5 <_panic>
	if (PGNUM(pa) >= npages)
f0100e2f:	89 c3                	mov    %eax,%ebx
f0100e31:	c1 eb 0c             	shr    $0xc,%ebx
f0100e34:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0100e37:	76 6d                	jbe    f0100ea6 <check_page_free_list+0x267>
	return (void *)(pa + KERNBASE);
f0100e39:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e3e:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100e41:	77 7c                	ja     f0100ebf <check_page_free_list+0x280>
			++nfree_extmem;
f0100e43:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e47:	8b 12                	mov    (%edx),%edx
f0100e49:	85 d2                	test   %edx,%edx
f0100e4b:	0f 84 90 00 00 00    	je     f0100ee1 <check_page_free_list+0x2a2>
		assert(pp >= pages);
f0100e51:	39 d1                	cmp    %edx,%ecx
f0100e53:	0f 87 e8 fe ff ff    	ja     f0100d41 <check_page_free_list+0x102>
		assert(pp < pages + npages);
f0100e59:	39 d7                	cmp    %edx,%edi
f0100e5b:	0f 86 02 ff ff ff    	jbe    f0100d63 <check_page_free_list+0x124>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e61:	89 d0                	mov    %edx,%eax
f0100e63:	29 c8                	sub    %ecx,%eax
f0100e65:	a8 07                	test   $0x7,%al
f0100e67:	0f 85 18 ff ff ff    	jne    f0100d85 <check_page_free_list+0x146>
	return (pp - pages) << PGSHIFT;
f0100e6d:	c1 f8 03             	sar    $0x3,%eax
		assert(page2pa(pp) != 0);
f0100e70:	c1 e0 0c             	shl    $0xc,%eax
f0100e73:	0f 84 2e ff ff ff    	je     f0100da7 <check_page_free_list+0x168>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e79:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e7e:	0f 84 45 ff ff ff    	je     f0100dc9 <check_page_free_list+0x18a>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100e84:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100e89:	0f 84 5c ff ff ff    	je     f0100deb <check_page_free_list+0x1ac>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100e8f:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100e94:	0f 84 73 ff ff ff    	je     f0100e0d <check_page_free_list+0x1ce>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e9a:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100e9f:	77 8e                	ja     f0100e2f <check_page_free_list+0x1f0>
			++nfree_basemem;
f0100ea1:	83 c6 01             	add    $0x1,%esi
f0100ea4:	eb a1                	jmp    f0100e47 <check_page_free_list+0x208>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ea6:	50                   	push   %eax
f0100ea7:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100eaa:	8d 83 b4 7a f7 ff    	lea    -0x8854c(%ebx),%eax
f0100eb0:	50                   	push   %eax
f0100eb1:	6a 56                	push   $0x56
f0100eb3:	8d 83 e9 82 f7 ff    	lea    -0x87d17(%ebx),%eax
f0100eb9:	50                   	push   %eax
f0100eba:	e8 f6 f1 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100ebf:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100ec2:	8d 83 54 7b f7 ff    	lea    -0x884ac(%ebx),%eax
f0100ec8:	50                   	push   %eax
f0100ec9:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0100ecf:	50                   	push   %eax
f0100ed0:	68 fa 02 00 00       	push   $0x2fa
f0100ed5:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0100edb:	50                   	push   %eax
f0100edc:	e8 d4 f1 ff ff       	call   f01000b5 <_panic>
f0100ee1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
	assert(nfree_basemem > 0);
f0100ee4:	85 f6                	test   %esi,%esi
f0100ee6:	7e 1e                	jle    f0100f06 <check_page_free_list+0x2c7>
	assert(nfree_extmem > 0);
f0100ee8:	85 db                	test   %ebx,%ebx
f0100eea:	7e 3c                	jle    f0100f28 <check_page_free_list+0x2e9>
	cprintf("check_page_free_list() succeeded!\n");
f0100eec:	83 ec 0c             	sub    $0xc,%esp
f0100eef:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100ef2:	8d 83 9c 7b f7 ff    	lea    -0x88464(%ebx),%eax
f0100ef8:	50                   	push   %eax
f0100ef9:	e8 3a 2b 00 00       	call   f0103a38 <cprintf>
}
f0100efe:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f01:	5b                   	pop    %ebx
f0100f02:	5e                   	pop    %esi
f0100f03:	5f                   	pop    %edi
f0100f04:	5d                   	pop    %ebp
f0100f05:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100f06:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100f09:	8d 83 70 83 f7 ff    	lea    -0x87c90(%ebx),%eax
f0100f0f:	50                   	push   %eax
f0100f10:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0100f16:	50                   	push   %eax
f0100f17:	68 02 03 00 00       	push   $0x302
f0100f1c:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0100f22:	50                   	push   %eax
f0100f23:	e8 8d f1 ff ff       	call   f01000b5 <_panic>
	assert(nfree_extmem > 0);
f0100f28:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100f2b:	8d 83 82 83 f7 ff    	lea    -0x87c7e(%ebx),%eax
f0100f31:	50                   	push   %eax
f0100f32:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0100f38:	50                   	push   %eax
f0100f39:	68 03 03 00 00       	push   $0x303
f0100f3e:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0100f44:	50                   	push   %eax
f0100f45:	e8 6b f1 ff ff       	call   f01000b5 <_panic>
	if (!page_free_list)
f0100f4a:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100f4d:	8b 80 24 23 00 00    	mov    0x2324(%eax),%eax
f0100f53:	85 c0                	test   %eax,%eax
f0100f55:	0f 84 30 fd ff ff    	je     f0100c8b <check_page_free_list+0x4c>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100f5b:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100f5e:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100f61:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100f64:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100f67:	8b 75 c8             	mov    -0x38(%ebp),%esi
f0100f6a:	c7 c3 10 10 19 f0    	mov    $0xf0191010,%ebx
f0100f70:	89 c2                	mov    %eax,%edx
f0100f72:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100f74:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100f7a:	0f 95 c2             	setne  %dl
f0100f7d:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100f80:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100f84:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100f86:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f8a:	8b 00                	mov    (%eax),%eax
f0100f8c:	85 c0                	test   %eax,%eax
f0100f8e:	75 e0                	jne    f0100f70 <check_page_free_list+0x331>
		*tp[1] = 0;
f0100f90:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f93:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100f99:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f9c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f9f:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100fa1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100fa4:	8b 75 c8             	mov    -0x38(%ebp),%esi
f0100fa7:	89 86 24 23 00 00    	mov    %eax,0x2324(%esi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100fad:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
f0100fb4:	e9 b8 fc ff ff       	jmp    f0100c71 <check_page_free_list+0x32>

f0100fb9 <page_init>:
{
f0100fb9:	f3 0f 1e fb          	endbr32 
f0100fbd:	55                   	push   %ebp
f0100fbe:	89 e5                	mov    %esp,%ebp
f0100fc0:	57                   	push   %edi
f0100fc1:	56                   	push   %esi
f0100fc2:	53                   	push   %ebx
f0100fc3:	83 ec 2c             	sub    $0x2c,%esp
f0100fc6:	e8 b0 21 00 00       	call   f010317b <__x86.get_pc_thunk.dx>
f0100fcb:	81 c2 51 d0 08 00    	add    $0x8d051,%edx
f0100fd1:	89 d7                	mov    %edx,%edi
f0100fd3:	89 55 d0             	mov    %edx,-0x30(%ebp)
	size_t num_used = ((uint32_t)boot_alloc(0)-EXTPHYSMEM-KERNBASE)/PGSIZE;
f0100fd6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fdb:	e8 54 fb ff ff       	call   f0100b34 <boot_alloc>
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100fe0:	8b b7 28 23 00 00    	mov    0x2328(%edi),%esi
f0100fe6:	89 75 e0             	mov    %esi,-0x20(%ebp)
	size_t num_used = ((uint32_t)boot_alloc(0)-EXTPHYSMEM-KERNBASE)/PGSIZE;
f0100fe9:	05 00 00 f0 0f       	add    $0xff00000,%eax
f0100fee:	c1 e8 0c             	shr    $0xc,%eax
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100ff1:	8d 44 06 60          	lea    0x60(%esi,%eax,1),%eax
f0100ff5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100ff8:	8b b7 24 23 00 00    	mov    0x2324(%edi),%esi
	for(size_t i = 0;i<npages;i++)
f0100ffe:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101003:	b8 00 00 00 00       	mov    $0x0,%eax
f0101008:	c7 c2 08 10 19 f0    	mov    $0xf0191008,%edx
			pages[i].pp_ref = 0;
f010100e:	c7 c1 10 10 19 f0    	mov    $0xf0191010,%ecx
f0101014:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
			pages[i].pp_ref = 1;
f0101017:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
			pages[i].pp_ref = 1;
f010101a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
	for(size_t i = 0;i<npages;i++)
f010101d:	eb 45                	jmp    f0101064 <page_init+0xab>
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f010101f:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f0101022:	77 1b                	ja     f010103f <page_init+0x86>
f0101024:	39 45 d8             	cmp    %eax,-0x28(%ebp)
f0101027:	76 16                	jbe    f010103f <page_init+0x86>
			pages[i].pp_ref = 1;
f0101029:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010102c:	8b 09                	mov    (%ecx),%ecx
f010102e:	8d 0c c1             	lea    (%ecx,%eax,8),%ecx
f0101031:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f0101037:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f010103d:	eb 22                	jmp    f0101061 <page_init+0xa8>
f010103f:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
			pages[i].pp_ref = 0;
f0101046:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101049:	89 cf                	mov    %ecx,%edi
f010104b:	03 3b                	add    (%ebx),%edi
f010104d:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
			pages[i].pp_link = page_free_list;
f0101053:	89 37                	mov    %esi,(%edi)
			page_free_list = &pages[i];
f0101055:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101058:	89 ce                	mov    %ecx,%esi
f010105a:	03 33                	add    (%ebx),%esi
f010105c:	bb 01 00 00 00       	mov    $0x1,%ebx
	for(size_t i = 0;i<npages;i++)
f0101061:	83 c0 01             	add    $0x1,%eax
f0101064:	39 02                	cmp    %eax,(%edx)
f0101066:	76 17                	jbe    f010107f <page_init+0xc6>
		if(i == 0)
f0101068:	85 c0                	test   %eax,%eax
f010106a:	75 b3                	jne    f010101f <page_init+0x66>
			pages[i].pp_ref = 1;
f010106c:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010106f:	8b 0f                	mov    (%edi),%ecx
f0101071:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f0101077:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f010107d:	eb e2                	jmp    f0101061 <page_init+0xa8>
f010107f:	84 db                	test   %bl,%bl
f0101081:	74 09                	je     f010108c <page_init+0xd3>
f0101083:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101086:	89 b0 24 23 00 00    	mov    %esi,0x2324(%eax)
}
f010108c:	83 c4 2c             	add    $0x2c,%esp
f010108f:	5b                   	pop    %ebx
f0101090:	5e                   	pop    %esi
f0101091:	5f                   	pop    %edi
f0101092:	5d                   	pop    %ebp
f0101093:	c3                   	ret    

f0101094 <page_alloc>:
{
f0101094:	f3 0f 1e fb          	endbr32 
f0101098:	55                   	push   %ebp
f0101099:	89 e5                	mov    %esp,%ebp
f010109b:	56                   	push   %esi
f010109c:	53                   	push   %ebx
f010109d:	e8 d1 f0 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01010a2:	81 c3 7a cf 08 00    	add    $0x8cf7a,%ebx
	if(page_free_list == NULL)
f01010a8:	8b b3 24 23 00 00    	mov    0x2324(%ebx),%esi
f01010ae:	85 f6                	test   %esi,%esi
f01010b0:	74 37                	je     f01010e9 <page_alloc+0x55>
	page_free_list = page_free_list->pp_link;
f01010b2:	8b 06                	mov    (%esi),%eax
f01010b4:	89 83 24 23 00 00    	mov    %eax,0x2324(%ebx)
	alloc->pp_link = NULL;
f01010ba:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
f01010c0:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f01010c6:	89 f1                	mov    %esi,%ecx
f01010c8:	2b 08                	sub    (%eax),%ecx
f01010ca:	89 c8                	mov    %ecx,%eax
f01010cc:	c1 f8 03             	sar    $0x3,%eax
f01010cf:	89 c1                	mov    %eax,%ecx
f01010d1:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f01010d4:	25 ff ff 0f 00       	and    $0xfffff,%eax
f01010d9:	c7 c2 08 10 19 f0    	mov    $0xf0191008,%edx
f01010df:	3b 02                	cmp    (%edx),%eax
f01010e1:	73 0f                	jae    f01010f2 <page_alloc+0x5e>
	if(alloc_flags & ALLOC_ZERO)
f01010e3:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f01010e7:	75 1f                	jne    f0101108 <page_alloc+0x74>
}
f01010e9:	89 f0                	mov    %esi,%eax
f01010eb:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01010ee:	5b                   	pop    %ebx
f01010ef:	5e                   	pop    %esi
f01010f0:	5d                   	pop    %ebp
f01010f1:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010f2:	51                   	push   %ecx
f01010f3:	8d 83 b4 7a f7 ff    	lea    -0x8854c(%ebx),%eax
f01010f9:	50                   	push   %eax
f01010fa:	6a 56                	push   $0x56
f01010fc:	8d 83 e9 82 f7 ff    	lea    -0x87d17(%ebx),%eax
f0101102:	50                   	push   %eax
f0101103:	e8 ad ef ff ff       	call   f01000b5 <_panic>
		memset(head,0,PGSIZE);
f0101108:	83 ec 04             	sub    $0x4,%esp
f010110b:	68 00 10 00 00       	push   $0x1000
f0101110:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0101112:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0101118:	51                   	push   %ecx
f0101119:	e8 43 40 00 00       	call   f0105161 <memset>
f010111e:	83 c4 10             	add    $0x10,%esp
f0101121:	eb c6                	jmp    f01010e9 <page_alloc+0x55>

f0101123 <page_free>:
{
f0101123:	f3 0f 1e fb          	endbr32 
f0101127:	55                   	push   %ebp
f0101128:	89 e5                	mov    %esp,%ebp
f010112a:	53                   	push   %ebx
f010112b:	83 ec 04             	sub    $0x4,%esp
f010112e:	e8 40 f0 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0101133:	81 c3 e9 ce 08 00    	add    $0x8cee9,%ebx
f0101139:	8b 45 08             	mov    0x8(%ebp),%eax
	if((pp->pp_ref != 0) | (pp->pp_link != NULL))  // referenced or freed
f010113c:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101141:	75 18                	jne    f010115b <page_free+0x38>
f0101143:	83 38 00             	cmpl   $0x0,(%eax)
f0101146:	75 13                	jne    f010115b <page_free+0x38>
	pp->pp_link = page_free_list;
f0101148:	8b 8b 24 23 00 00    	mov    0x2324(%ebx),%ecx
f010114e:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f0101150:	89 83 24 23 00 00    	mov    %eax,0x2324(%ebx)
}
f0101156:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101159:	c9                   	leave  
f010115a:	c3                   	ret    
		panic("at pmap.c:page_free(): Page double free or freeing a referenced page");
f010115b:	83 ec 04             	sub    $0x4,%esp
f010115e:	8d 83 c0 7b f7 ff    	lea    -0x88440(%ebx),%eax
f0101164:	50                   	push   %eax
f0101165:	68 7c 01 00 00       	push   $0x17c
f010116a:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0101170:	50                   	push   %eax
f0101171:	e8 3f ef ff ff       	call   f01000b5 <_panic>

f0101176 <page_decref>:
{
f0101176:	f3 0f 1e fb          	endbr32 
f010117a:	55                   	push   %ebp
f010117b:	89 e5                	mov    %esp,%ebp
f010117d:	83 ec 08             	sub    $0x8,%esp
f0101180:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101183:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101187:	83 e8 01             	sub    $0x1,%eax
f010118a:	66 89 42 04          	mov    %ax,0x4(%edx)
f010118e:	66 85 c0             	test   %ax,%ax
f0101191:	74 02                	je     f0101195 <page_decref+0x1f>
}
f0101193:	c9                   	leave  
f0101194:	c3                   	ret    
		page_free(pp);
f0101195:	83 ec 0c             	sub    $0xc,%esp
f0101198:	52                   	push   %edx
f0101199:	e8 85 ff ff ff       	call   f0101123 <page_free>
f010119e:	83 c4 10             	add    $0x10,%esp
}
f01011a1:	eb f0                	jmp    f0101193 <page_decref+0x1d>

f01011a3 <pgdir_walk>:
{
f01011a3:	f3 0f 1e fb          	endbr32 
f01011a7:	55                   	push   %ebp
f01011a8:	89 e5                	mov    %esp,%ebp
f01011aa:	57                   	push   %edi
f01011ab:	56                   	push   %esi
f01011ac:	53                   	push   %ebx
f01011ad:	83 ec 0c             	sub    $0xc,%esp
f01011b0:	e8 ce 1f 00 00       	call   f0103183 <__x86.get_pc_thunk.di>
f01011b5:	81 c7 67 ce 08 00    	add    $0x8ce67,%edi
f01011bb:	8b 75 0c             	mov    0xc(%ebp),%esi
	unsigned int dir_offset = PDX(va);
f01011be:	89 f3                	mov    %esi,%ebx
f01011c0:	c1 eb 16             	shr    $0x16,%ebx
	pde_t* entry = pgdir+dir_offset;
f01011c3:	c1 e3 02             	shl    $0x2,%ebx
f01011c6:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*entry & PTE_P))
f01011c9:	f6 03 01             	testb  $0x1,(%ebx)
f01011cc:	75 2f                	jne    f01011fd <pgdir_walk+0x5a>
		if(create)
f01011ce:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01011d2:	74 73                	je     f0101247 <pgdir_walk+0xa4>
			new_page = page_alloc(1);
f01011d4:	83 ec 0c             	sub    $0xc,%esp
f01011d7:	6a 01                	push   $0x1
f01011d9:	e8 b6 fe ff ff       	call   f0101094 <page_alloc>
			if(new_page == NULL)
f01011de:	83 c4 10             	add    $0x10,%esp
f01011e1:	85 c0                	test   %eax,%eax
f01011e3:	74 3f                	je     f0101224 <pgdir_walk+0x81>
			new_page->pp_ref++;
f01011e5:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f01011ea:	c7 c2 10 10 19 f0    	mov    $0xf0191010,%edx
f01011f0:	2b 02                	sub    (%edx),%eax
f01011f2:	c1 f8 03             	sar    $0x3,%eax
f01011f5:	c1 e0 0c             	shl    $0xc,%eax
			*entry = ((page2pa(new_page))|PTE_P|PTE_W|PTE_U);
f01011f8:	83 c8 07             	or     $0x7,%eax
f01011fb:	89 03                	mov    %eax,(%ebx)
	page_base = (pte_t*)KADDR(PTE_ADDR(*entry));
f01011fd:	8b 03                	mov    (%ebx),%eax
f01011ff:	89 c2                	mov    %eax,%edx
f0101201:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101207:	c1 e8 0c             	shr    $0xc,%eax
f010120a:	c7 c1 08 10 19 f0    	mov    $0xf0191008,%ecx
f0101210:	3b 01                	cmp    (%ecx),%eax
f0101212:	73 18                	jae    f010122c <pgdir_walk+0x89>
	page_offset = PTX(va);
f0101214:	c1 ee 0a             	shr    $0xa,%esi
	return &page_base[page_offset];
f0101217:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f010121d:	8d 84 32 00 00 00 f0 	lea    -0x10000000(%edx,%esi,1),%eax
}
f0101224:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101227:	5b                   	pop    %ebx
f0101228:	5e                   	pop    %esi
f0101229:	5f                   	pop    %edi
f010122a:	5d                   	pop    %ebp
f010122b:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010122c:	52                   	push   %edx
f010122d:	8d 87 b4 7a f7 ff    	lea    -0x8854c(%edi),%eax
f0101233:	50                   	push   %eax
f0101234:	68 c9 01 00 00       	push   $0x1c9
f0101239:	8d 87 dd 82 f7 ff    	lea    -0x87d23(%edi),%eax
f010123f:	50                   	push   %eax
f0101240:	89 fb                	mov    %edi,%ebx
f0101242:	e8 6e ee ff ff       	call   f01000b5 <_panic>
			return NULL;
f0101247:	b8 00 00 00 00       	mov    $0x0,%eax
f010124c:	eb d6                	jmp    f0101224 <pgdir_walk+0x81>

f010124e <boot_map_region>:
{
f010124e:	55                   	push   %ebp
f010124f:	89 e5                	mov    %esp,%ebp
f0101251:	57                   	push   %edi
f0101252:	56                   	push   %esi
f0101253:	53                   	push   %ebx
f0101254:	83 ec 1c             	sub    $0x1c,%esp
f0101257:	89 c7                	mov    %eax,%edi
f0101259:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010125c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for(add = 0;add<size;add+=PGSIZE)
f010125f:	be 00 00 00 00       	mov    $0x0,%esi
f0101264:	89 f3                	mov    %esi,%ebx
f0101266:	03 5d 08             	add    0x8(%ebp),%ebx
f0101269:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f010126c:	76 24                	jbe    f0101292 <boot_map_region+0x44>
		entry = pgdir_walk(pgdir,(void*)va,1);  // get the entry of page table
f010126e:	83 ec 04             	sub    $0x4,%esp
f0101271:	6a 01                	push   $0x1
f0101273:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101276:	01 f0                	add    %esi,%eax
f0101278:	50                   	push   %eax
f0101279:	57                   	push   %edi
f010127a:	e8 24 ff ff ff       	call   f01011a3 <pgdir_walk>
		*entry = (pa|perm|PTE_P);
f010127f:	0b 5d 0c             	or     0xc(%ebp),%ebx
f0101282:	83 cb 01             	or     $0x1,%ebx
f0101285:	89 18                	mov    %ebx,(%eax)
	for(add = 0;add<size;add+=PGSIZE)
f0101287:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010128d:	83 c4 10             	add    $0x10,%esp
f0101290:	eb d2                	jmp    f0101264 <boot_map_region+0x16>
}
f0101292:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101295:	5b                   	pop    %ebx
f0101296:	5e                   	pop    %esi
f0101297:	5f                   	pop    %edi
f0101298:	5d                   	pop    %ebp
f0101299:	c3                   	ret    

f010129a <page_lookup>:
{
f010129a:	f3 0f 1e fb          	endbr32 
f010129e:	55                   	push   %ebp
f010129f:	89 e5                	mov    %esp,%ebp
f01012a1:	56                   	push   %esi
f01012a2:	53                   	push   %ebx
f01012a3:	e8 cb ee ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01012a8:	81 c3 74 cd 08 00    	add    $0x8cd74,%ebx
f01012ae:	8b 75 10             	mov    0x10(%ebp),%esi
	entry = pgdir_walk(pgdir,va,0);
f01012b1:	83 ec 04             	sub    $0x4,%esp
f01012b4:	6a 00                	push   $0x0
f01012b6:	ff 75 0c             	pushl  0xc(%ebp)
f01012b9:	ff 75 08             	pushl  0x8(%ebp)
f01012bc:	e8 e2 fe ff ff       	call   f01011a3 <pgdir_walk>
	if(entry == NULL)
f01012c1:	83 c4 10             	add    $0x10,%esp
f01012c4:	85 c0                	test   %eax,%eax
f01012c6:	74 46                	je     f010130e <page_lookup+0x74>
	if(!(*entry & PTE_P))
f01012c8:	8b 10                	mov    (%eax),%edx
f01012ca:	f6 c2 01             	test   $0x1,%dl
f01012cd:	74 43                	je     f0101312 <page_lookup+0x78>
f01012cf:	c1 ea 0c             	shr    $0xc,%edx
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012d2:	c7 c1 08 10 19 f0    	mov    $0xf0191008,%ecx
f01012d8:	39 11                	cmp    %edx,(%ecx)
f01012da:	76 1a                	jbe    f01012f6 <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f01012dc:	c7 c1 10 10 19 f0    	mov    $0xf0191010,%ecx
f01012e2:	8b 09                	mov    (%ecx),%ecx
f01012e4:	8d 14 d1             	lea    (%ecx,%edx,8),%edx
	if(pte_store != NULL)
f01012e7:	85 f6                	test   %esi,%esi
f01012e9:	74 02                	je     f01012ed <page_lookup+0x53>
		*pte_store = entry;
f01012eb:	89 06                	mov    %eax,(%esi)
}
f01012ed:	89 d0                	mov    %edx,%eax
f01012ef:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01012f2:	5b                   	pop    %ebx
f01012f3:	5e                   	pop    %esi
f01012f4:	5d                   	pop    %ebp
f01012f5:	c3                   	ret    
		panic("pa2page called with invalid pa");
f01012f6:	83 ec 04             	sub    $0x4,%esp
f01012f9:	8d 83 08 7c f7 ff    	lea    -0x883f8(%ebx),%eax
f01012ff:	50                   	push   %eax
f0101300:	6a 4f                	push   $0x4f
f0101302:	8d 83 e9 82 f7 ff    	lea    -0x87d17(%ebx),%eax
f0101308:	50                   	push   %eax
f0101309:	e8 a7 ed ff ff       	call   f01000b5 <_panic>
		return NULL;
f010130e:	89 c2                	mov    %eax,%edx
f0101310:	eb db                	jmp    f01012ed <page_lookup+0x53>
		return NULL;
f0101312:	ba 00 00 00 00       	mov    $0x0,%edx
f0101317:	eb d4                	jmp    f01012ed <page_lookup+0x53>

f0101319 <page_remove>:
{
f0101319:	f3 0f 1e fb          	endbr32 
f010131d:	55                   	push   %ebp
f010131e:	89 e5                	mov    %esp,%ebp
f0101320:	53                   	push   %ebx
f0101321:	83 ec 18             	sub    $0x18,%esp
f0101324:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t* pte = NULL;
f0101327:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo* page = page_lookup(pgdir,va,&pte);
f010132e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101331:	50                   	push   %eax
f0101332:	53                   	push   %ebx
f0101333:	ff 75 08             	pushl  0x8(%ebp)
f0101336:	e8 5f ff ff ff       	call   f010129a <page_lookup>
	if(page == NULL)
f010133b:	83 c4 10             	add    $0x10,%esp
f010133e:	85 c0                	test   %eax,%eax
f0101340:	74 18                	je     f010135a <page_remove+0x41>
	page_decref(page);
f0101342:	83 ec 0c             	sub    $0xc,%esp
f0101345:	50                   	push   %eax
f0101346:	e8 2b fe ff ff       	call   f0101176 <page_decref>
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010134b:	0f 01 3b             	invlpg (%ebx)
	*pte = 0;
f010134e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101351:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101357:	83 c4 10             	add    $0x10,%esp
}
f010135a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010135d:	c9                   	leave  
f010135e:	c3                   	ret    

f010135f <page_insert>:
{
f010135f:	f3 0f 1e fb          	endbr32 
f0101363:	55                   	push   %ebp
f0101364:	89 e5                	mov    %esp,%ebp
f0101366:	57                   	push   %edi
f0101367:	56                   	push   %esi
f0101368:	53                   	push   %ebx
f0101369:	83 ec 10             	sub    $0x10,%esp
f010136c:	e8 12 1e 00 00       	call   f0103183 <__x86.get_pc_thunk.di>
f0101371:	81 c7 ab cc 08 00    	add    $0x8ccab,%edi
f0101377:	8b 75 08             	mov    0x8(%ebp),%esi
	entry = pgdir_walk(pgdir,va,1); // get the page table entry 
f010137a:	6a 01                	push   $0x1
f010137c:	ff 75 10             	pushl  0x10(%ebp)
f010137f:	56                   	push   %esi
f0101380:	e8 1e fe ff ff       	call   f01011a3 <pgdir_walk>
	if(entry == NULL)
f0101385:	83 c4 10             	add    $0x10,%esp
f0101388:	85 c0                	test   %eax,%eax
f010138a:	74 5a                	je     f01013e6 <page_insert+0x87>
f010138c:	89 c3                	mov    %eax,%ebx
	pp->pp_ref++;
f010138e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101391:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	if(*entry&PTE_P)
f0101396:	f6 03 01             	testb  $0x1,(%ebx)
f0101399:	75 34                	jne    f01013cf <page_insert+0x70>
	return (pp - pages) << PGSHIFT;
f010139b:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f01013a1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013a4:	2b 10                	sub    (%eax),%edx
f01013a6:	89 d0                	mov    %edx,%eax
f01013a8:	c1 f8 03             	sar    $0x3,%eax
f01013ab:	c1 e0 0c             	shl    $0xc,%eax
	*entry = ((page2pa(pp))|perm|PTE_P);
f01013ae:	0b 45 14             	or     0x14(%ebp),%eax
f01013b1:	83 c8 01             	or     $0x1,%eax
f01013b4:	89 03                	mov    %eax,(%ebx)
	pgdir[PDX(va)] |= perm;
f01013b6:	8b 45 10             	mov    0x10(%ebp),%eax
f01013b9:	c1 e8 16             	shr    $0x16,%eax
f01013bc:	8b 4d 14             	mov    0x14(%ebp),%ecx
f01013bf:	09 0c 86             	or     %ecx,(%esi,%eax,4)
	return 0;
f01013c2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01013c7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01013ca:	5b                   	pop    %ebx
f01013cb:	5e                   	pop    %esi
f01013cc:	5f                   	pop    %edi
f01013cd:	5d                   	pop    %ebp
f01013ce:	c3                   	ret    
f01013cf:	8b 45 10             	mov    0x10(%ebp),%eax
f01013d2:	0f 01 38             	invlpg (%eax)
		page_remove(pgdir,va);
f01013d5:	83 ec 08             	sub    $0x8,%esp
f01013d8:	ff 75 10             	pushl  0x10(%ebp)
f01013db:	56                   	push   %esi
f01013dc:	e8 38 ff ff ff       	call   f0101319 <page_remove>
f01013e1:	83 c4 10             	add    $0x10,%esp
f01013e4:	eb b5                	jmp    f010139b <page_insert+0x3c>
		return -E_NO_MEM;
f01013e6:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01013eb:	eb da                	jmp    f01013c7 <page_insert+0x68>

f01013ed <mem_init>:
{
f01013ed:	f3 0f 1e fb          	endbr32 
f01013f1:	55                   	push   %ebp
f01013f2:	89 e5                	mov    %esp,%ebp
f01013f4:	57                   	push   %edi
f01013f5:	56                   	push   %esi
f01013f6:	53                   	push   %ebx
f01013f7:	83 ec 3c             	sub    $0x3c,%esp
f01013fa:	e8 74 ed ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01013ff:	81 c3 1d cc 08 00    	add    $0x8cc1d,%ebx
	basemem = nvram_read(NVRAM_BASELO);
f0101405:	b8 15 00 00 00       	mov    $0x15,%eax
f010140a:	e8 ef f6 ff ff       	call   f0100afe <nvram_read>
f010140f:	89 c6                	mov    %eax,%esi
	extmem = nvram_read(NVRAM_EXTLO);
f0101411:	b8 17 00 00 00       	mov    $0x17,%eax
f0101416:	e8 e3 f6 ff ff       	call   f0100afe <nvram_read>
f010141b:	89 c7                	mov    %eax,%edi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010141d:	b8 34 00 00 00       	mov    $0x34,%eax
f0101422:	e8 d7 f6 ff ff       	call   f0100afe <nvram_read>
	if (ext16mem)
f0101427:	c1 e0 06             	shl    $0x6,%eax
f010142a:	0f 84 ec 00 00 00    	je     f010151c <mem_init+0x12f>
		totalmem = 16 * 1024 + ext16mem;
f0101430:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f0101435:	89 c1                	mov    %eax,%ecx
f0101437:	c1 e9 02             	shr    $0x2,%ecx
f010143a:	c7 c2 08 10 19 f0    	mov    $0xf0191008,%edx
f0101440:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f0101442:	89 f2                	mov    %esi,%edx
f0101444:	c1 ea 02             	shr    $0x2,%edx
f0101447:	89 93 28 23 00 00    	mov    %edx,0x2328(%ebx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010144d:	89 c2                	mov    %eax,%edx
f010144f:	29 f2                	sub    %esi,%edx
f0101451:	52                   	push   %edx
f0101452:	56                   	push   %esi
f0101453:	50                   	push   %eax
f0101454:	8d 83 28 7c f7 ff    	lea    -0x883d8(%ebx),%eax
f010145a:	50                   	push   %eax
f010145b:	e8 d8 25 00 00       	call   f0103a38 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101460:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101465:	e8 ca f6 ff ff       	call   f0100b34 <boot_alloc>
f010146a:	c7 c6 0c 10 19 f0    	mov    $0xf019100c,%esi
f0101470:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f0101472:	83 c4 0c             	add    $0xc,%esp
f0101475:	68 00 10 00 00       	push   $0x1000
f010147a:	6a 00                	push   $0x0
f010147c:	50                   	push   %eax
f010147d:	e8 df 3c 00 00       	call   f0105161 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101482:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f0101484:	83 c4 10             	add    $0x10,%esp
f0101487:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010148c:	0f 86 9a 00 00 00    	jbe    f010152c <mem_init+0x13f>
	return (physaddr_t)kva - KERNBASE;
f0101492:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101498:	83 ca 05             	or     $0x5,%edx
f010149b:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages*sizeof(struct PageInfo));
f01014a1:	c7 c7 08 10 19 f0    	mov    $0xf0191008,%edi
f01014a7:	8b 07                	mov    (%edi),%eax
f01014a9:	c1 e0 03             	shl    $0x3,%eax
f01014ac:	e8 83 f6 ff ff       	call   f0100b34 <boot_alloc>
f01014b1:	c7 c6 10 10 19 f0    	mov    $0xf0191010,%esi
f01014b7:	89 06                	mov    %eax,(%esi)
	memset(pages,0,npages*sizeof(struct PageInfo));
f01014b9:	83 ec 04             	sub    $0x4,%esp
f01014bc:	8b 17                	mov    (%edi),%edx
f01014be:	c1 e2 03             	shl    $0x3,%edx
f01014c1:	52                   	push   %edx
f01014c2:	6a 00                	push   $0x0
f01014c4:	50                   	push   %eax
f01014c5:	e8 97 3c 00 00       	call   f0105161 <memset>
	envs = (struct Env*)boot_alloc(NENV*sizeof(struct Env));
f01014ca:	b8 00 80 01 00       	mov    $0x18000,%eax
f01014cf:	e8 60 f6 ff ff       	call   f0100b34 <boot_alloc>
f01014d4:	c7 c2 4c 03 19 f0    	mov    $0xf019034c,%edx
f01014da:	89 02                	mov    %eax,(%edx)
	memset(envs,0,NENV*sizeof(struct Env));
f01014dc:	83 c4 0c             	add    $0xc,%esp
f01014df:	68 00 80 01 00       	push   $0x18000
f01014e4:	6a 00                	push   $0x0
f01014e6:	50                   	push   %eax
f01014e7:	e8 75 3c 00 00       	call   f0105161 <memset>
	page_init();
f01014ec:	e8 c8 fa ff ff       	call   f0100fb9 <page_init>
	check_page_free_list(1);
f01014f1:	b8 01 00 00 00       	mov    $0x1,%eax
f01014f6:	e8 44 f7 ff ff       	call   f0100c3f <check_page_free_list>
	if (!pages)
f01014fb:	83 c4 10             	add    $0x10,%esp
f01014fe:	83 3e 00             	cmpl   $0x0,(%esi)
f0101501:	74 42                	je     f0101545 <mem_init+0x158>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101503:	8b 83 24 23 00 00    	mov    0x2324(%ebx),%eax
f0101509:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0101510:	85 c0                	test   %eax,%eax
f0101512:	74 4c                	je     f0101560 <mem_init+0x173>
		++nfree;
f0101514:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101518:	8b 00                	mov    (%eax),%eax
f010151a:	eb f4                	jmp    f0101510 <mem_init+0x123>
		totalmem = 1 * 1024 + extmem;
f010151c:	8d 87 00 04 00 00    	lea    0x400(%edi),%eax
f0101522:	85 ff                	test   %edi,%edi
f0101524:	0f 44 c6             	cmove  %esi,%eax
f0101527:	e9 09 ff ff ff       	jmp    f0101435 <mem_init+0x48>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010152c:	50                   	push   %eax
f010152d:	8d 83 64 7c f7 ff    	lea    -0x8839c(%ebx),%eax
f0101533:	50                   	push   %eax
f0101534:	68 a2 00 00 00       	push   $0xa2
f0101539:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010153f:	50                   	push   %eax
f0101540:	e8 70 eb ff ff       	call   f01000b5 <_panic>
		panic("'pages' is a null pointer!");
f0101545:	83 ec 04             	sub    $0x4,%esp
f0101548:	8d 83 93 83 f7 ff    	lea    -0x87c6d(%ebx),%eax
f010154e:	50                   	push   %eax
f010154f:	68 16 03 00 00       	push   $0x316
f0101554:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010155a:	50                   	push   %eax
f010155b:	e8 55 eb ff ff       	call   f01000b5 <_panic>
	assert((pp0 = page_alloc(0)));
f0101560:	83 ec 0c             	sub    $0xc,%esp
f0101563:	6a 00                	push   $0x0
f0101565:	e8 2a fb ff ff       	call   f0101094 <page_alloc>
f010156a:	89 c6                	mov    %eax,%esi
f010156c:	83 c4 10             	add    $0x10,%esp
f010156f:	85 c0                	test   %eax,%eax
f0101571:	0f 84 31 02 00 00    	je     f01017a8 <mem_init+0x3bb>
	assert((pp1 = page_alloc(0)));
f0101577:	83 ec 0c             	sub    $0xc,%esp
f010157a:	6a 00                	push   $0x0
f010157c:	e8 13 fb ff ff       	call   f0101094 <page_alloc>
f0101581:	89 c7                	mov    %eax,%edi
f0101583:	83 c4 10             	add    $0x10,%esp
f0101586:	85 c0                	test   %eax,%eax
f0101588:	0f 84 39 02 00 00    	je     f01017c7 <mem_init+0x3da>
	assert((pp2 = page_alloc(0)));
f010158e:	83 ec 0c             	sub    $0xc,%esp
f0101591:	6a 00                	push   $0x0
f0101593:	e8 fc fa ff ff       	call   f0101094 <page_alloc>
f0101598:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010159b:	83 c4 10             	add    $0x10,%esp
f010159e:	85 c0                	test   %eax,%eax
f01015a0:	0f 84 40 02 00 00    	je     f01017e6 <mem_init+0x3f9>
	assert(pp1 && pp1 != pp0);
f01015a6:	39 fe                	cmp    %edi,%esi
f01015a8:	0f 84 57 02 00 00    	je     f0101805 <mem_init+0x418>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015ae:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015b1:	39 c7                	cmp    %eax,%edi
f01015b3:	0f 84 6b 02 00 00    	je     f0101824 <mem_init+0x437>
f01015b9:	39 c6                	cmp    %eax,%esi
f01015bb:	0f 84 63 02 00 00    	je     f0101824 <mem_init+0x437>
	return (pp - pages) << PGSHIFT;
f01015c1:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f01015c7:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01015c9:	c7 c0 08 10 19 f0    	mov    $0xf0191008,%eax
f01015cf:	8b 10                	mov    (%eax),%edx
f01015d1:	c1 e2 0c             	shl    $0xc,%edx
f01015d4:	89 f0                	mov    %esi,%eax
f01015d6:	29 c8                	sub    %ecx,%eax
f01015d8:	c1 f8 03             	sar    $0x3,%eax
f01015db:	c1 e0 0c             	shl    $0xc,%eax
f01015de:	39 d0                	cmp    %edx,%eax
f01015e0:	0f 83 5d 02 00 00    	jae    f0101843 <mem_init+0x456>
f01015e6:	89 f8                	mov    %edi,%eax
f01015e8:	29 c8                	sub    %ecx,%eax
f01015ea:	c1 f8 03             	sar    $0x3,%eax
f01015ed:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f01015f0:	39 c2                	cmp    %eax,%edx
f01015f2:	0f 86 6a 02 00 00    	jbe    f0101862 <mem_init+0x475>
f01015f8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015fb:	29 c8                	sub    %ecx,%eax
f01015fd:	c1 f8 03             	sar    $0x3,%eax
f0101600:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f0101603:	39 c2                	cmp    %eax,%edx
f0101605:	0f 86 76 02 00 00    	jbe    f0101881 <mem_init+0x494>
	fl = page_free_list;
f010160b:	8b 83 24 23 00 00    	mov    0x2324(%ebx),%eax
f0101611:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f0101614:	c7 83 24 23 00 00 00 	movl   $0x0,0x2324(%ebx)
f010161b:	00 00 00 
	assert(!page_alloc(0));
f010161e:	83 ec 0c             	sub    $0xc,%esp
f0101621:	6a 00                	push   $0x0
f0101623:	e8 6c fa ff ff       	call   f0101094 <page_alloc>
f0101628:	83 c4 10             	add    $0x10,%esp
f010162b:	85 c0                	test   %eax,%eax
f010162d:	0f 85 6d 02 00 00    	jne    f01018a0 <mem_init+0x4b3>
	page_free(pp0);
f0101633:	83 ec 0c             	sub    $0xc,%esp
f0101636:	56                   	push   %esi
f0101637:	e8 e7 fa ff ff       	call   f0101123 <page_free>
	page_free(pp1);
f010163c:	89 3c 24             	mov    %edi,(%esp)
f010163f:	e8 df fa ff ff       	call   f0101123 <page_free>
	page_free(pp2);
f0101644:	83 c4 04             	add    $0x4,%esp
f0101647:	ff 75 d4             	pushl  -0x2c(%ebp)
f010164a:	e8 d4 fa ff ff       	call   f0101123 <page_free>
	assert((pp0 = page_alloc(0)));
f010164f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101656:	e8 39 fa ff ff       	call   f0101094 <page_alloc>
f010165b:	89 c6                	mov    %eax,%esi
f010165d:	83 c4 10             	add    $0x10,%esp
f0101660:	85 c0                	test   %eax,%eax
f0101662:	0f 84 57 02 00 00    	je     f01018bf <mem_init+0x4d2>
	assert((pp1 = page_alloc(0)));
f0101668:	83 ec 0c             	sub    $0xc,%esp
f010166b:	6a 00                	push   $0x0
f010166d:	e8 22 fa ff ff       	call   f0101094 <page_alloc>
f0101672:	89 c7                	mov    %eax,%edi
f0101674:	83 c4 10             	add    $0x10,%esp
f0101677:	85 c0                	test   %eax,%eax
f0101679:	0f 84 5f 02 00 00    	je     f01018de <mem_init+0x4f1>
	assert((pp2 = page_alloc(0)));
f010167f:	83 ec 0c             	sub    $0xc,%esp
f0101682:	6a 00                	push   $0x0
f0101684:	e8 0b fa ff ff       	call   f0101094 <page_alloc>
f0101689:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010168c:	83 c4 10             	add    $0x10,%esp
f010168f:	85 c0                	test   %eax,%eax
f0101691:	0f 84 66 02 00 00    	je     f01018fd <mem_init+0x510>
	assert(pp1 && pp1 != pp0);
f0101697:	39 fe                	cmp    %edi,%esi
f0101699:	0f 84 7d 02 00 00    	je     f010191c <mem_init+0x52f>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010169f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016a2:	39 c7                	cmp    %eax,%edi
f01016a4:	0f 84 91 02 00 00    	je     f010193b <mem_init+0x54e>
f01016aa:	39 c6                	cmp    %eax,%esi
f01016ac:	0f 84 89 02 00 00    	je     f010193b <mem_init+0x54e>
	assert(!page_alloc(0));
f01016b2:	83 ec 0c             	sub    $0xc,%esp
f01016b5:	6a 00                	push   $0x0
f01016b7:	e8 d8 f9 ff ff       	call   f0101094 <page_alloc>
f01016bc:	83 c4 10             	add    $0x10,%esp
f01016bf:	85 c0                	test   %eax,%eax
f01016c1:	0f 85 93 02 00 00    	jne    f010195a <mem_init+0x56d>
f01016c7:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f01016cd:	89 f1                	mov    %esi,%ecx
f01016cf:	2b 08                	sub    (%eax),%ecx
f01016d1:	89 c8                	mov    %ecx,%eax
f01016d3:	c1 f8 03             	sar    $0x3,%eax
f01016d6:	89 c2                	mov    %eax,%edx
f01016d8:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01016db:	25 ff ff 0f 00       	and    $0xfffff,%eax
f01016e0:	c7 c1 08 10 19 f0    	mov    $0xf0191008,%ecx
f01016e6:	3b 01                	cmp    (%ecx),%eax
f01016e8:	0f 83 8b 02 00 00    	jae    f0101979 <mem_init+0x58c>
	memset(page2kva(pp0), 1, PGSIZE);
f01016ee:	83 ec 04             	sub    $0x4,%esp
f01016f1:	68 00 10 00 00       	push   $0x1000
f01016f6:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01016f8:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f01016fe:	52                   	push   %edx
f01016ff:	e8 5d 3a 00 00       	call   f0105161 <memset>
	page_free(pp0);
f0101704:	89 34 24             	mov    %esi,(%esp)
f0101707:	e8 17 fa ff ff       	call   f0101123 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010170c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101713:	e8 7c f9 ff ff       	call   f0101094 <page_alloc>
f0101718:	83 c4 10             	add    $0x10,%esp
f010171b:	85 c0                	test   %eax,%eax
f010171d:	0f 84 6c 02 00 00    	je     f010198f <mem_init+0x5a2>
	assert(pp && pp0 == pp);
f0101723:	39 c6                	cmp    %eax,%esi
f0101725:	0f 85 83 02 00 00    	jne    f01019ae <mem_init+0x5c1>
	return (pp - pages) << PGSHIFT;
f010172b:	c7 c2 10 10 19 f0    	mov    $0xf0191010,%edx
f0101731:	2b 02                	sub    (%edx),%eax
f0101733:	c1 f8 03             	sar    $0x3,%eax
f0101736:	89 c2                	mov    %eax,%edx
f0101738:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010173b:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101740:	c7 c1 08 10 19 f0    	mov    $0xf0191008,%ecx
f0101746:	3b 01                	cmp    (%ecx),%eax
f0101748:	0f 83 7f 02 00 00    	jae    f01019cd <mem_init+0x5e0>
	return (void *)(pa + KERNBASE);
f010174e:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f0101754:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f010175a:	80 38 00             	cmpb   $0x0,(%eax)
f010175d:	0f 85 80 02 00 00    	jne    f01019e3 <mem_init+0x5f6>
f0101763:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f0101766:	39 d0                	cmp    %edx,%eax
f0101768:	75 f0                	jne    f010175a <mem_init+0x36d>
	page_free_list = fl;
f010176a:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010176d:	89 83 24 23 00 00    	mov    %eax,0x2324(%ebx)
	page_free(pp0);
f0101773:	83 ec 0c             	sub    $0xc,%esp
f0101776:	56                   	push   %esi
f0101777:	e8 a7 f9 ff ff       	call   f0101123 <page_free>
	page_free(pp1);
f010177c:	89 3c 24             	mov    %edi,(%esp)
f010177f:	e8 9f f9 ff ff       	call   f0101123 <page_free>
	page_free(pp2);
f0101784:	83 c4 04             	add    $0x4,%esp
f0101787:	ff 75 d4             	pushl  -0x2c(%ebp)
f010178a:	e8 94 f9 ff ff       	call   f0101123 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010178f:	8b 83 24 23 00 00    	mov    0x2324(%ebx),%eax
f0101795:	83 c4 10             	add    $0x10,%esp
f0101798:	85 c0                	test   %eax,%eax
f010179a:	0f 84 62 02 00 00    	je     f0101a02 <mem_init+0x615>
		--nfree;
f01017a0:	83 6d d0 01          	subl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017a4:	8b 00                	mov    (%eax),%eax
f01017a6:	eb f0                	jmp    f0101798 <mem_init+0x3ab>
	assert((pp0 = page_alloc(0)));
f01017a8:	8d 83 ae 83 f7 ff    	lea    -0x87c52(%ebx),%eax
f01017ae:	50                   	push   %eax
f01017af:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01017b5:	50                   	push   %eax
f01017b6:	68 1e 03 00 00       	push   $0x31e
f01017bb:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01017c1:	50                   	push   %eax
f01017c2:	e8 ee e8 ff ff       	call   f01000b5 <_panic>
	assert((pp1 = page_alloc(0)));
f01017c7:	8d 83 c4 83 f7 ff    	lea    -0x87c3c(%ebx),%eax
f01017cd:	50                   	push   %eax
f01017ce:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01017d4:	50                   	push   %eax
f01017d5:	68 1f 03 00 00       	push   $0x31f
f01017da:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01017e0:	50                   	push   %eax
f01017e1:	e8 cf e8 ff ff       	call   f01000b5 <_panic>
	assert((pp2 = page_alloc(0)));
f01017e6:	8d 83 da 83 f7 ff    	lea    -0x87c26(%ebx),%eax
f01017ec:	50                   	push   %eax
f01017ed:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01017f3:	50                   	push   %eax
f01017f4:	68 20 03 00 00       	push   $0x320
f01017f9:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01017ff:	50                   	push   %eax
f0101800:	e8 b0 e8 ff ff       	call   f01000b5 <_panic>
	assert(pp1 && pp1 != pp0);
f0101805:	8d 83 f0 83 f7 ff    	lea    -0x87c10(%ebx),%eax
f010180b:	50                   	push   %eax
f010180c:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0101812:	50                   	push   %eax
f0101813:	68 23 03 00 00       	push   $0x323
f0101818:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010181e:	50                   	push   %eax
f010181f:	e8 91 e8 ff ff       	call   f01000b5 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101824:	8d 83 88 7c f7 ff    	lea    -0x88378(%ebx),%eax
f010182a:	50                   	push   %eax
f010182b:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0101831:	50                   	push   %eax
f0101832:	68 24 03 00 00       	push   $0x324
f0101837:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010183d:	50                   	push   %eax
f010183e:	e8 72 e8 ff ff       	call   f01000b5 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101843:	8d 83 02 84 f7 ff    	lea    -0x87bfe(%ebx),%eax
f0101849:	50                   	push   %eax
f010184a:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0101850:	50                   	push   %eax
f0101851:	68 25 03 00 00       	push   $0x325
f0101856:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010185c:	50                   	push   %eax
f010185d:	e8 53 e8 ff ff       	call   f01000b5 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101862:	8d 83 1f 84 f7 ff    	lea    -0x87be1(%ebx),%eax
f0101868:	50                   	push   %eax
f0101869:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f010186f:	50                   	push   %eax
f0101870:	68 26 03 00 00       	push   $0x326
f0101875:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010187b:	50                   	push   %eax
f010187c:	e8 34 e8 ff ff       	call   f01000b5 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101881:	8d 83 3c 84 f7 ff    	lea    -0x87bc4(%ebx),%eax
f0101887:	50                   	push   %eax
f0101888:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f010188e:	50                   	push   %eax
f010188f:	68 27 03 00 00       	push   $0x327
f0101894:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010189a:	50                   	push   %eax
f010189b:	e8 15 e8 ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f01018a0:	8d 83 59 84 f7 ff    	lea    -0x87ba7(%ebx),%eax
f01018a6:	50                   	push   %eax
f01018a7:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01018ad:	50                   	push   %eax
f01018ae:	68 2e 03 00 00       	push   $0x32e
f01018b3:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01018b9:	50                   	push   %eax
f01018ba:	e8 f6 e7 ff ff       	call   f01000b5 <_panic>
	assert((pp0 = page_alloc(0)));
f01018bf:	8d 83 ae 83 f7 ff    	lea    -0x87c52(%ebx),%eax
f01018c5:	50                   	push   %eax
f01018c6:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01018cc:	50                   	push   %eax
f01018cd:	68 35 03 00 00       	push   $0x335
f01018d2:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01018d8:	50                   	push   %eax
f01018d9:	e8 d7 e7 ff ff       	call   f01000b5 <_panic>
	assert((pp1 = page_alloc(0)));
f01018de:	8d 83 c4 83 f7 ff    	lea    -0x87c3c(%ebx),%eax
f01018e4:	50                   	push   %eax
f01018e5:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01018eb:	50                   	push   %eax
f01018ec:	68 36 03 00 00       	push   $0x336
f01018f1:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01018f7:	50                   	push   %eax
f01018f8:	e8 b8 e7 ff ff       	call   f01000b5 <_panic>
	assert((pp2 = page_alloc(0)));
f01018fd:	8d 83 da 83 f7 ff    	lea    -0x87c26(%ebx),%eax
f0101903:	50                   	push   %eax
f0101904:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f010190a:	50                   	push   %eax
f010190b:	68 37 03 00 00       	push   $0x337
f0101910:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0101916:	50                   	push   %eax
f0101917:	e8 99 e7 ff ff       	call   f01000b5 <_panic>
	assert(pp1 && pp1 != pp0);
f010191c:	8d 83 f0 83 f7 ff    	lea    -0x87c10(%ebx),%eax
f0101922:	50                   	push   %eax
f0101923:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0101929:	50                   	push   %eax
f010192a:	68 39 03 00 00       	push   $0x339
f010192f:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0101935:	50                   	push   %eax
f0101936:	e8 7a e7 ff ff       	call   f01000b5 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010193b:	8d 83 88 7c f7 ff    	lea    -0x88378(%ebx),%eax
f0101941:	50                   	push   %eax
f0101942:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0101948:	50                   	push   %eax
f0101949:	68 3a 03 00 00       	push   $0x33a
f010194e:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0101954:	50                   	push   %eax
f0101955:	e8 5b e7 ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f010195a:	8d 83 59 84 f7 ff    	lea    -0x87ba7(%ebx),%eax
f0101960:	50                   	push   %eax
f0101961:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0101967:	50                   	push   %eax
f0101968:	68 3b 03 00 00       	push   $0x33b
f010196d:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0101973:	50                   	push   %eax
f0101974:	e8 3c e7 ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101979:	52                   	push   %edx
f010197a:	8d 83 b4 7a f7 ff    	lea    -0x8854c(%ebx),%eax
f0101980:	50                   	push   %eax
f0101981:	6a 56                	push   $0x56
f0101983:	8d 83 e9 82 f7 ff    	lea    -0x87d17(%ebx),%eax
f0101989:	50                   	push   %eax
f010198a:	e8 26 e7 ff ff       	call   f01000b5 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010198f:	8d 83 68 84 f7 ff    	lea    -0x87b98(%ebx),%eax
f0101995:	50                   	push   %eax
f0101996:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f010199c:	50                   	push   %eax
f010199d:	68 40 03 00 00       	push   $0x340
f01019a2:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01019a8:	50                   	push   %eax
f01019a9:	e8 07 e7 ff ff       	call   f01000b5 <_panic>
	assert(pp && pp0 == pp);
f01019ae:	8d 83 86 84 f7 ff    	lea    -0x87b7a(%ebx),%eax
f01019b4:	50                   	push   %eax
f01019b5:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01019bb:	50                   	push   %eax
f01019bc:	68 41 03 00 00       	push   $0x341
f01019c1:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01019c7:	50                   	push   %eax
f01019c8:	e8 e8 e6 ff ff       	call   f01000b5 <_panic>
f01019cd:	52                   	push   %edx
f01019ce:	8d 83 b4 7a f7 ff    	lea    -0x8854c(%ebx),%eax
f01019d4:	50                   	push   %eax
f01019d5:	6a 56                	push   $0x56
f01019d7:	8d 83 e9 82 f7 ff    	lea    -0x87d17(%ebx),%eax
f01019dd:	50                   	push   %eax
f01019de:	e8 d2 e6 ff ff       	call   f01000b5 <_panic>
		assert(c[i] == 0);
f01019e3:	8d 83 96 84 f7 ff    	lea    -0x87b6a(%ebx),%eax
f01019e9:	50                   	push   %eax
f01019ea:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01019f0:	50                   	push   %eax
f01019f1:	68 44 03 00 00       	push   $0x344
f01019f6:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01019fc:	50                   	push   %eax
f01019fd:	e8 b3 e6 ff ff       	call   f01000b5 <_panic>
	assert(nfree == 0);
f0101a02:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101a06:	0f 85 7f 08 00 00    	jne    f010228b <mem_init+0xe9e>
	cprintf("check_page_alloc() succeeded!\n");
f0101a0c:	83 ec 0c             	sub    $0xc,%esp
f0101a0f:	8d 83 a8 7c f7 ff    	lea    -0x88358(%ebx),%eax
f0101a15:	50                   	push   %eax
f0101a16:	e8 1d 20 00 00       	call   f0103a38 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101a1b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a22:	e8 6d f6 ff ff       	call   f0101094 <page_alloc>
f0101a27:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101a2a:	83 c4 10             	add    $0x10,%esp
f0101a2d:	85 c0                	test   %eax,%eax
f0101a2f:	0f 84 75 08 00 00    	je     f01022aa <mem_init+0xebd>
	assert((pp1 = page_alloc(0)));
f0101a35:	83 ec 0c             	sub    $0xc,%esp
f0101a38:	6a 00                	push   $0x0
f0101a3a:	e8 55 f6 ff ff       	call   f0101094 <page_alloc>
f0101a3f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101a42:	83 c4 10             	add    $0x10,%esp
f0101a45:	85 c0                	test   %eax,%eax
f0101a47:	0f 84 7c 08 00 00    	je     f01022c9 <mem_init+0xedc>
	assert((pp2 = page_alloc(0)));
f0101a4d:	83 ec 0c             	sub    $0xc,%esp
f0101a50:	6a 00                	push   $0x0
f0101a52:	e8 3d f6 ff ff       	call   f0101094 <page_alloc>
f0101a57:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101a5a:	83 c4 10             	add    $0x10,%esp
f0101a5d:	85 c0                	test   %eax,%eax
f0101a5f:	0f 84 83 08 00 00    	je     f01022e8 <mem_init+0xefb>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a65:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101a68:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0101a6b:	0f 84 96 08 00 00    	je     f0102307 <mem_init+0xf1a>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a71:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a74:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101a77:	0f 84 a9 08 00 00    	je     f0102326 <mem_init+0xf39>
f0101a7d:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101a80:	0f 84 a0 08 00 00    	je     f0102326 <mem_init+0xf39>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a86:	8b 83 24 23 00 00    	mov    0x2324(%ebx),%eax
f0101a8c:	89 45 c8             	mov    %eax,-0x38(%ebp)
	page_free_list = 0;
f0101a8f:	c7 83 24 23 00 00 00 	movl   $0x0,0x2324(%ebx)
f0101a96:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a99:	83 ec 0c             	sub    $0xc,%esp
f0101a9c:	6a 00                	push   $0x0
f0101a9e:	e8 f1 f5 ff ff       	call   f0101094 <page_alloc>
f0101aa3:	83 c4 10             	add    $0x10,%esp
f0101aa6:	85 c0                	test   %eax,%eax
f0101aa8:	0f 85 97 08 00 00    	jne    f0102345 <mem_init+0xf58>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101aae:	83 ec 04             	sub    $0x4,%esp
f0101ab1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101ab4:	50                   	push   %eax
f0101ab5:	6a 00                	push   $0x0
f0101ab7:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0101abd:	ff 30                	pushl  (%eax)
f0101abf:	e8 d6 f7 ff ff       	call   f010129a <page_lookup>
f0101ac4:	83 c4 10             	add    $0x10,%esp
f0101ac7:	85 c0                	test   %eax,%eax
f0101ac9:	0f 85 95 08 00 00    	jne    f0102364 <mem_init+0xf77>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101acf:	6a 02                	push   $0x2
f0101ad1:	6a 00                	push   $0x0
f0101ad3:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101ad6:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0101adc:	ff 30                	pushl  (%eax)
f0101ade:	e8 7c f8 ff ff       	call   f010135f <page_insert>
f0101ae3:	83 c4 10             	add    $0x10,%esp
f0101ae6:	85 c0                	test   %eax,%eax
f0101ae8:	0f 89 95 08 00 00    	jns    f0102383 <mem_init+0xf96>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101aee:	83 ec 0c             	sub    $0xc,%esp
f0101af1:	ff 75 cc             	pushl  -0x34(%ebp)
f0101af4:	e8 2a f6 ff ff       	call   f0101123 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101af9:	6a 02                	push   $0x2
f0101afb:	6a 00                	push   $0x0
f0101afd:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b00:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0101b06:	ff 30                	pushl  (%eax)
f0101b08:	e8 52 f8 ff ff       	call   f010135f <page_insert>
f0101b0d:	83 c4 20             	add    $0x20,%esp
f0101b10:	85 c0                	test   %eax,%eax
f0101b12:	0f 85 8a 08 00 00    	jne    f01023a2 <mem_init+0xfb5>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101b18:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0101b1e:	8b 30                	mov    (%eax),%esi
	return (pp - pages) << PGSHIFT;
f0101b20:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f0101b26:	8b 38                	mov    (%eax),%edi
f0101b28:	8b 16                	mov    (%esi),%edx
f0101b2a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101b30:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101b33:	29 f8                	sub    %edi,%eax
f0101b35:	c1 f8 03             	sar    $0x3,%eax
f0101b38:	c1 e0 0c             	shl    $0xc,%eax
f0101b3b:	39 c2                	cmp    %eax,%edx
f0101b3d:	0f 85 7e 08 00 00    	jne    f01023c1 <mem_init+0xfd4>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b43:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b48:	89 f0                	mov    %esi,%eax
f0101b4a:	e8 74 f0 ff ff       	call   f0100bc3 <check_va2pa>
f0101b4f:	89 c2                	mov    %eax,%edx
f0101b51:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b54:	29 f8                	sub    %edi,%eax
f0101b56:	c1 f8 03             	sar    $0x3,%eax
f0101b59:	c1 e0 0c             	shl    $0xc,%eax
f0101b5c:	39 c2                	cmp    %eax,%edx
f0101b5e:	0f 85 7c 08 00 00    	jne    f01023e0 <mem_init+0xff3>
	assert(pp1->pp_ref == 1);
f0101b64:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b67:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b6c:	0f 85 8d 08 00 00    	jne    f01023ff <mem_init+0x1012>
	assert(pp0->pp_ref == 1);
f0101b72:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101b75:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b7a:	0f 85 9e 08 00 00    	jne    f010241e <mem_init+0x1031>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b80:	6a 02                	push   $0x2
f0101b82:	68 00 10 00 00       	push   $0x1000
f0101b87:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b8a:	56                   	push   %esi
f0101b8b:	e8 cf f7 ff ff       	call   f010135f <page_insert>
f0101b90:	83 c4 10             	add    $0x10,%esp
f0101b93:	85 c0                	test   %eax,%eax
f0101b95:	0f 85 a2 08 00 00    	jne    f010243d <mem_init+0x1050>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b9b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ba0:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0101ba6:	8b 00                	mov    (%eax),%eax
f0101ba8:	e8 16 f0 ff ff       	call   f0100bc3 <check_va2pa>
f0101bad:	89 c2                	mov    %eax,%edx
f0101baf:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f0101bb5:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101bb8:	2b 08                	sub    (%eax),%ecx
f0101bba:	89 c8                	mov    %ecx,%eax
f0101bbc:	c1 f8 03             	sar    $0x3,%eax
f0101bbf:	c1 e0 0c             	shl    $0xc,%eax
f0101bc2:	39 c2                	cmp    %eax,%edx
f0101bc4:	0f 85 92 08 00 00    	jne    f010245c <mem_init+0x106f>
	assert(pp2->pp_ref == 1);
f0101bca:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101bcd:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101bd2:	0f 85 a3 08 00 00    	jne    f010247b <mem_init+0x108e>

	// should be no free memory
	assert(!page_alloc(0));
f0101bd8:	83 ec 0c             	sub    $0xc,%esp
f0101bdb:	6a 00                	push   $0x0
f0101bdd:	e8 b2 f4 ff ff       	call   f0101094 <page_alloc>
f0101be2:	83 c4 10             	add    $0x10,%esp
f0101be5:	85 c0                	test   %eax,%eax
f0101be7:	0f 85 ad 08 00 00    	jne    f010249a <mem_init+0x10ad>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bed:	6a 02                	push   $0x2
f0101bef:	68 00 10 00 00       	push   $0x1000
f0101bf4:	ff 75 d0             	pushl  -0x30(%ebp)
f0101bf7:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0101bfd:	ff 30                	pushl  (%eax)
f0101bff:	e8 5b f7 ff ff       	call   f010135f <page_insert>
f0101c04:	83 c4 10             	add    $0x10,%esp
f0101c07:	85 c0                	test   %eax,%eax
f0101c09:	0f 85 aa 08 00 00    	jne    f01024b9 <mem_init+0x10cc>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c0f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c14:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0101c1a:	8b 00                	mov    (%eax),%eax
f0101c1c:	e8 a2 ef ff ff       	call   f0100bc3 <check_va2pa>
f0101c21:	89 c2                	mov    %eax,%edx
f0101c23:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f0101c29:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101c2c:	2b 08                	sub    (%eax),%ecx
f0101c2e:	89 c8                	mov    %ecx,%eax
f0101c30:	c1 f8 03             	sar    $0x3,%eax
f0101c33:	c1 e0 0c             	shl    $0xc,%eax
f0101c36:	39 c2                	cmp    %eax,%edx
f0101c38:	0f 85 9a 08 00 00    	jne    f01024d8 <mem_init+0x10eb>
	assert(pp2->pp_ref == 1);
f0101c3e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c41:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c46:	0f 85 ab 08 00 00    	jne    f01024f7 <mem_init+0x110a>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c4c:	83 ec 0c             	sub    $0xc,%esp
f0101c4f:	6a 00                	push   $0x0
f0101c51:	e8 3e f4 ff ff       	call   f0101094 <page_alloc>
f0101c56:	83 c4 10             	add    $0x10,%esp
f0101c59:	85 c0                	test   %eax,%eax
f0101c5b:	0f 85 b5 08 00 00    	jne    f0102516 <mem_init+0x1129>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c61:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0101c67:	8b 08                	mov    (%eax),%ecx
f0101c69:	8b 01                	mov    (%ecx),%eax
f0101c6b:	89 c2                	mov    %eax,%edx
f0101c6d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101c73:	c1 e8 0c             	shr    $0xc,%eax
f0101c76:	c7 c6 08 10 19 f0    	mov    $0xf0191008,%esi
f0101c7c:	3b 06                	cmp    (%esi),%eax
f0101c7e:	0f 83 b1 08 00 00    	jae    f0102535 <mem_init+0x1148>
	return (void *)(pa + KERNBASE);
f0101c84:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101c8a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c8d:	83 ec 04             	sub    $0x4,%esp
f0101c90:	6a 00                	push   $0x0
f0101c92:	68 00 10 00 00       	push   $0x1000
f0101c97:	51                   	push   %ecx
f0101c98:	e8 06 f5 ff ff       	call   f01011a3 <pgdir_walk>
f0101c9d:	89 c2                	mov    %eax,%edx
f0101c9f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101ca2:	83 c0 04             	add    $0x4,%eax
f0101ca5:	83 c4 10             	add    $0x10,%esp
f0101ca8:	39 d0                	cmp    %edx,%eax
f0101caa:	0f 85 9e 08 00 00    	jne    f010254e <mem_init+0x1161>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101cb0:	6a 06                	push   $0x6
f0101cb2:	68 00 10 00 00       	push   $0x1000
f0101cb7:	ff 75 d0             	pushl  -0x30(%ebp)
f0101cba:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0101cc0:	ff 30                	pushl  (%eax)
f0101cc2:	e8 98 f6 ff ff       	call   f010135f <page_insert>
f0101cc7:	83 c4 10             	add    $0x10,%esp
f0101cca:	85 c0                	test   %eax,%eax
f0101ccc:	0f 85 9b 08 00 00    	jne    f010256d <mem_init+0x1180>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cd2:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0101cd8:	8b 30                	mov    (%eax),%esi
f0101cda:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cdf:	89 f0                	mov    %esi,%eax
f0101ce1:	e8 dd ee ff ff       	call   f0100bc3 <check_va2pa>
f0101ce6:	89 c2                	mov    %eax,%edx
	return (pp - pages) << PGSHIFT;
f0101ce8:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f0101cee:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101cf1:	2b 08                	sub    (%eax),%ecx
f0101cf3:	89 c8                	mov    %ecx,%eax
f0101cf5:	c1 f8 03             	sar    $0x3,%eax
f0101cf8:	c1 e0 0c             	shl    $0xc,%eax
f0101cfb:	39 c2                	cmp    %eax,%edx
f0101cfd:	0f 85 89 08 00 00    	jne    f010258c <mem_init+0x119f>
	assert(pp2->pp_ref == 1);
f0101d03:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101d06:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101d0b:	0f 85 9a 08 00 00    	jne    f01025ab <mem_init+0x11be>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d11:	83 ec 04             	sub    $0x4,%esp
f0101d14:	6a 00                	push   $0x0
f0101d16:	68 00 10 00 00       	push   $0x1000
f0101d1b:	56                   	push   %esi
f0101d1c:	e8 82 f4 ff ff       	call   f01011a3 <pgdir_walk>
f0101d21:	83 c4 10             	add    $0x10,%esp
f0101d24:	f6 00 04             	testb  $0x4,(%eax)
f0101d27:	0f 84 9d 08 00 00    	je     f01025ca <mem_init+0x11dd>
	assert(kern_pgdir[0] & PTE_U);
f0101d2d:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0101d33:	8b 00                	mov    (%eax),%eax
f0101d35:	f6 00 04             	testb  $0x4,(%eax)
f0101d38:	0f 84 ab 08 00 00    	je     f01025e9 <mem_init+0x11fc>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d3e:	6a 02                	push   $0x2
f0101d40:	68 00 10 00 00       	push   $0x1000
f0101d45:	ff 75 d0             	pushl  -0x30(%ebp)
f0101d48:	50                   	push   %eax
f0101d49:	e8 11 f6 ff ff       	call   f010135f <page_insert>
f0101d4e:	83 c4 10             	add    $0x10,%esp
f0101d51:	85 c0                	test   %eax,%eax
f0101d53:	0f 85 af 08 00 00    	jne    f0102608 <mem_init+0x121b>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d59:	83 ec 04             	sub    $0x4,%esp
f0101d5c:	6a 00                	push   $0x0
f0101d5e:	68 00 10 00 00       	push   $0x1000
f0101d63:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0101d69:	ff 30                	pushl  (%eax)
f0101d6b:	e8 33 f4 ff ff       	call   f01011a3 <pgdir_walk>
f0101d70:	83 c4 10             	add    $0x10,%esp
f0101d73:	f6 00 02             	testb  $0x2,(%eax)
f0101d76:	0f 84 ab 08 00 00    	je     f0102627 <mem_init+0x123a>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d7c:	83 ec 04             	sub    $0x4,%esp
f0101d7f:	6a 00                	push   $0x0
f0101d81:	68 00 10 00 00       	push   $0x1000
f0101d86:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0101d8c:	ff 30                	pushl  (%eax)
f0101d8e:	e8 10 f4 ff ff       	call   f01011a3 <pgdir_walk>
f0101d93:	83 c4 10             	add    $0x10,%esp
f0101d96:	f6 00 04             	testb  $0x4,(%eax)
f0101d99:	0f 85 a7 08 00 00    	jne    f0102646 <mem_init+0x1259>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101d9f:	6a 02                	push   $0x2
f0101da1:	68 00 00 40 00       	push   $0x400000
f0101da6:	ff 75 cc             	pushl  -0x34(%ebp)
f0101da9:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0101daf:	ff 30                	pushl  (%eax)
f0101db1:	e8 a9 f5 ff ff       	call   f010135f <page_insert>
f0101db6:	83 c4 10             	add    $0x10,%esp
f0101db9:	85 c0                	test   %eax,%eax
f0101dbb:	0f 89 a4 08 00 00    	jns    f0102665 <mem_init+0x1278>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101dc1:	6a 02                	push   $0x2
f0101dc3:	68 00 10 00 00       	push   $0x1000
f0101dc8:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101dcb:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0101dd1:	ff 30                	pushl  (%eax)
f0101dd3:	e8 87 f5 ff ff       	call   f010135f <page_insert>
f0101dd8:	83 c4 10             	add    $0x10,%esp
f0101ddb:	85 c0                	test   %eax,%eax
f0101ddd:	0f 85 a1 08 00 00    	jne    f0102684 <mem_init+0x1297>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101de3:	83 ec 04             	sub    $0x4,%esp
f0101de6:	6a 00                	push   $0x0
f0101de8:	68 00 10 00 00       	push   $0x1000
f0101ded:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0101df3:	ff 30                	pushl  (%eax)
f0101df5:	e8 a9 f3 ff ff       	call   f01011a3 <pgdir_walk>
f0101dfa:	83 c4 10             	add    $0x10,%esp
f0101dfd:	f6 00 04             	testb  $0x4,(%eax)
f0101e00:	0f 85 9d 08 00 00    	jne    f01026a3 <mem_init+0x12b6>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e06:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0101e0c:	8b 38                	mov    (%eax),%edi
f0101e0e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e13:	89 f8                	mov    %edi,%eax
f0101e15:	e8 a9 ed ff ff       	call   f0100bc3 <check_va2pa>
f0101e1a:	c7 c2 10 10 19 f0    	mov    $0xf0191010,%edx
f0101e20:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101e23:	2b 32                	sub    (%edx),%esi
f0101e25:	c1 fe 03             	sar    $0x3,%esi
f0101e28:	c1 e6 0c             	shl    $0xc,%esi
f0101e2b:	39 f0                	cmp    %esi,%eax
f0101e2d:	0f 85 8f 08 00 00    	jne    f01026c2 <mem_init+0x12d5>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e33:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e38:	89 f8                	mov    %edi,%eax
f0101e3a:	e8 84 ed ff ff       	call   f0100bc3 <check_va2pa>
f0101e3f:	39 c6                	cmp    %eax,%esi
f0101e41:	0f 85 9a 08 00 00    	jne    f01026e1 <mem_init+0x12f4>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e47:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e4a:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f0101e4f:	0f 85 ab 08 00 00    	jne    f0102700 <mem_init+0x1313>
	assert(pp2->pp_ref == 0);
f0101e55:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101e58:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e5d:	0f 85 bc 08 00 00    	jne    f010271f <mem_init+0x1332>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e63:	83 ec 0c             	sub    $0xc,%esp
f0101e66:	6a 00                	push   $0x0
f0101e68:	e8 27 f2 ff ff       	call   f0101094 <page_alloc>
f0101e6d:	83 c4 10             	add    $0x10,%esp
f0101e70:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101e73:	0f 85 c5 08 00 00    	jne    f010273e <mem_init+0x1351>
f0101e79:	85 c0                	test   %eax,%eax
f0101e7b:	0f 84 bd 08 00 00    	je     f010273e <mem_init+0x1351>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e81:	83 ec 08             	sub    $0x8,%esp
f0101e84:	6a 00                	push   $0x0
f0101e86:	c7 c6 0c 10 19 f0    	mov    $0xf019100c,%esi
f0101e8c:	ff 36                	pushl  (%esi)
f0101e8e:	e8 86 f4 ff ff       	call   f0101319 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e93:	8b 36                	mov    (%esi),%esi
f0101e95:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e9a:	89 f0                	mov    %esi,%eax
f0101e9c:	e8 22 ed ff ff       	call   f0100bc3 <check_va2pa>
f0101ea1:	83 c4 10             	add    $0x10,%esp
f0101ea4:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ea7:	0f 85 b0 08 00 00    	jne    f010275d <mem_init+0x1370>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ead:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101eb2:	89 f0                	mov    %esi,%eax
f0101eb4:	e8 0a ed ff ff       	call   f0100bc3 <check_va2pa>
f0101eb9:	89 c2                	mov    %eax,%edx
f0101ebb:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f0101ec1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ec4:	2b 08                	sub    (%eax),%ecx
f0101ec6:	89 c8                	mov    %ecx,%eax
f0101ec8:	c1 f8 03             	sar    $0x3,%eax
f0101ecb:	c1 e0 0c             	shl    $0xc,%eax
f0101ece:	39 c2                	cmp    %eax,%edx
f0101ed0:	0f 85 a6 08 00 00    	jne    f010277c <mem_init+0x138f>
	assert(pp1->pp_ref == 1);
f0101ed6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ed9:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ede:	0f 85 b7 08 00 00    	jne    f010279b <mem_init+0x13ae>
	assert(pp2->pp_ref == 0);
f0101ee4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101ee7:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101eec:	0f 85 c8 08 00 00    	jne    f01027ba <mem_init+0x13cd>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101ef2:	6a 00                	push   $0x0
f0101ef4:	68 00 10 00 00       	push   $0x1000
f0101ef9:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101efc:	56                   	push   %esi
f0101efd:	e8 5d f4 ff ff       	call   f010135f <page_insert>
f0101f02:	83 c4 10             	add    $0x10,%esp
f0101f05:	85 c0                	test   %eax,%eax
f0101f07:	0f 85 cc 08 00 00    	jne    f01027d9 <mem_init+0x13ec>
	assert(pp1->pp_ref);
f0101f0d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f10:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101f15:	0f 84 dd 08 00 00    	je     f01027f8 <mem_init+0x140b>
	assert(pp1->pp_link == NULL);
f0101f1b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f1e:	83 38 00             	cmpl   $0x0,(%eax)
f0101f21:	0f 85 f0 08 00 00    	jne    f0102817 <mem_init+0x142a>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101f27:	83 ec 08             	sub    $0x8,%esp
f0101f2a:	68 00 10 00 00       	push   $0x1000
f0101f2f:	c7 c6 0c 10 19 f0    	mov    $0xf019100c,%esi
f0101f35:	ff 36                	pushl  (%esi)
f0101f37:	e8 dd f3 ff ff       	call   f0101319 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f3c:	8b 36                	mov    (%esi),%esi
f0101f3e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f43:	89 f0                	mov    %esi,%eax
f0101f45:	e8 79 ec ff ff       	call   f0100bc3 <check_va2pa>
f0101f4a:	83 c4 10             	add    $0x10,%esp
f0101f4d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f50:	0f 85 e0 08 00 00    	jne    f0102836 <mem_init+0x1449>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f56:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f5b:	89 f0                	mov    %esi,%eax
f0101f5d:	e8 61 ec ff ff       	call   f0100bc3 <check_va2pa>
f0101f62:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f65:	0f 85 ea 08 00 00    	jne    f0102855 <mem_init+0x1468>
	assert(pp1->pp_ref == 0);
f0101f6b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f6e:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101f73:	0f 85 fb 08 00 00    	jne    f0102874 <mem_init+0x1487>
	assert(pp2->pp_ref == 0);
f0101f79:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101f7c:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101f81:	0f 85 0c 09 00 00    	jne    f0102893 <mem_init+0x14a6>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f87:	83 ec 0c             	sub    $0xc,%esp
f0101f8a:	6a 00                	push   $0x0
f0101f8c:	e8 03 f1 ff ff       	call   f0101094 <page_alloc>
f0101f91:	83 c4 10             	add    $0x10,%esp
f0101f94:	85 c0                	test   %eax,%eax
f0101f96:	0f 84 16 09 00 00    	je     f01028b2 <mem_init+0x14c5>
f0101f9c:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101f9f:	0f 85 0d 09 00 00    	jne    f01028b2 <mem_init+0x14c5>

	// should be no free memory
	assert(!page_alloc(0));
f0101fa5:	83 ec 0c             	sub    $0xc,%esp
f0101fa8:	6a 00                	push   $0x0
f0101faa:	e8 e5 f0 ff ff       	call   f0101094 <page_alloc>
f0101faf:	83 c4 10             	add    $0x10,%esp
f0101fb2:	85 c0                	test   %eax,%eax
f0101fb4:	0f 85 17 09 00 00    	jne    f01028d1 <mem_init+0x14e4>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101fba:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0101fc0:	8b 08                	mov    (%eax),%ecx
f0101fc2:	8b 11                	mov    (%ecx),%edx
f0101fc4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101fca:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f0101fd0:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0101fd3:	2b 38                	sub    (%eax),%edi
f0101fd5:	89 f8                	mov    %edi,%eax
f0101fd7:	c1 f8 03             	sar    $0x3,%eax
f0101fda:	c1 e0 0c             	shl    $0xc,%eax
f0101fdd:	39 c2                	cmp    %eax,%edx
f0101fdf:	0f 85 0b 09 00 00    	jne    f01028f0 <mem_init+0x1503>
	kern_pgdir[0] = 0;
f0101fe5:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101feb:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101fee:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ff3:	0f 85 16 09 00 00    	jne    f010290f <mem_init+0x1522>
	pp0->pp_ref = 0;
f0101ff9:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101ffc:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102002:	83 ec 0c             	sub    $0xc,%esp
f0102005:	50                   	push   %eax
f0102006:	e8 18 f1 ff ff       	call   f0101123 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010200b:	83 c4 0c             	add    $0xc,%esp
f010200e:	6a 01                	push   $0x1
f0102010:	68 00 10 40 00       	push   $0x401000
f0102015:	c7 c6 0c 10 19 f0    	mov    $0xf019100c,%esi
f010201b:	ff 36                	pushl  (%esi)
f010201d:	e8 81 f1 ff ff       	call   f01011a3 <pgdir_walk>
f0102022:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102025:	8b 3e                	mov    (%esi),%edi
f0102027:	8b 57 04             	mov    0x4(%edi),%edx
f010202a:	89 d1                	mov    %edx,%ecx
f010202c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	if (PGNUM(pa) >= npages)
f0102032:	c7 c6 08 10 19 f0    	mov    $0xf0191008,%esi
f0102038:	8b 36                	mov    (%esi),%esi
f010203a:	c1 ea 0c             	shr    $0xc,%edx
f010203d:	83 c4 10             	add    $0x10,%esp
f0102040:	39 f2                	cmp    %esi,%edx
f0102042:	0f 83 e6 08 00 00    	jae    f010292e <mem_init+0x1541>
	assert(ptep == ptep1 + PTX(va));
f0102048:	81 e9 fc ff ff 0f    	sub    $0xffffffc,%ecx
f010204e:	39 c8                	cmp    %ecx,%eax
f0102050:	0f 85 f1 08 00 00    	jne    f0102947 <mem_init+0x155a>
	kern_pgdir[PDX(va)] = 0;
f0102056:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	pp0->pp_ref = 0;
f010205d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102060:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
	return (pp - pages) << PGSHIFT;
f0102066:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f010206c:	2b 08                	sub    (%eax),%ecx
f010206e:	89 c8                	mov    %ecx,%eax
f0102070:	c1 f8 03             	sar    $0x3,%eax
f0102073:	89 c2                	mov    %eax,%edx
f0102075:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102078:	25 ff ff 0f 00       	and    $0xfffff,%eax
f010207d:	39 c6                	cmp    %eax,%esi
f010207f:	0f 86 e1 08 00 00    	jbe    f0102966 <mem_init+0x1579>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102085:	83 ec 04             	sub    $0x4,%esp
f0102088:	68 00 10 00 00       	push   $0x1000
f010208d:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0102092:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102098:	52                   	push   %edx
f0102099:	e8 c3 30 00 00       	call   f0105161 <memset>
	page_free(pp0);
f010209e:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01020a1:	89 3c 24             	mov    %edi,(%esp)
f01020a4:	e8 7a f0 ff ff       	call   f0101123 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01020a9:	83 c4 0c             	add    $0xc,%esp
f01020ac:	6a 01                	push   $0x1
f01020ae:	6a 00                	push   $0x0
f01020b0:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f01020b6:	ff 30                	pushl  (%eax)
f01020b8:	e8 e6 f0 ff ff       	call   f01011a3 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f01020bd:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f01020c3:	2b 38                	sub    (%eax),%edi
f01020c5:	89 f8                	mov    %edi,%eax
f01020c7:	c1 f8 03             	sar    $0x3,%eax
f01020ca:	89 c2                	mov    %eax,%edx
f01020cc:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01020cf:	25 ff ff 0f 00       	and    $0xfffff,%eax
f01020d4:	83 c4 10             	add    $0x10,%esp
f01020d7:	c7 c1 08 10 19 f0    	mov    $0xf0191008,%ecx
f01020dd:	3b 01                	cmp    (%ecx),%eax
f01020df:	0f 83 97 08 00 00    	jae    f010297c <mem_init+0x158f>
	return (void *)(pa + KERNBASE);
f01020e5:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020eb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020ee:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020f4:	8b 38                	mov    (%eax),%edi
f01020f6:	83 e7 01             	and    $0x1,%edi
f01020f9:	0f 85 93 08 00 00    	jne    f0102992 <mem_init+0x15a5>
f01020ff:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0102102:	39 d0                	cmp    %edx,%eax
f0102104:	75 ee                	jne    f01020f4 <mem_init+0xd07>
	kern_pgdir[0] = 0;
f0102106:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f010210c:	8b 00                	mov    (%eax),%eax
f010210e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102114:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102117:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010211d:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102120:	89 8b 24 23 00 00    	mov    %ecx,0x2324(%ebx)

	// free the pages we took
	page_free(pp0);
f0102126:	83 ec 0c             	sub    $0xc,%esp
f0102129:	50                   	push   %eax
f010212a:	e8 f4 ef ff ff       	call   f0101123 <page_free>
	page_free(pp1);
f010212f:	83 c4 04             	add    $0x4,%esp
f0102132:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102135:	e8 e9 ef ff ff       	call   f0101123 <page_free>
	page_free(pp2);
f010213a:	83 c4 04             	add    $0x4,%esp
f010213d:	ff 75 d0             	pushl  -0x30(%ebp)
f0102140:	e8 de ef ff ff       	call   f0101123 <page_free>

	cprintf("check_page() succeeded!\n");
f0102145:	8d 83 77 85 f7 ff    	lea    -0x87a89(%ebx),%eax
f010214b:	89 04 24             	mov    %eax,(%esp)
f010214e:	e8 e5 18 00 00       	call   f0103a38 <cprintf>
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U);
f0102153:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f0102159:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010215b:	83 c4 10             	add    $0x10,%esp
f010215e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102163:	0f 86 48 08 00 00    	jbe    f01029b1 <mem_init+0x15c4>
f0102169:	83 ec 08             	sub    $0x8,%esp
f010216c:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f010216e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102173:	50                   	push   %eax
f0102174:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102179:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010217e:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0102184:	8b 00                	mov    (%eax),%eax
f0102186:	e8 c3 f0 ff ff       	call   f010124e <boot_map_region>
	boot_map_region(kern_pgdir,UENVS,PTSIZE,PADDR(envs),PTE_U);
f010218b:	c7 c0 4c 03 19 f0    	mov    $0xf019034c,%eax
f0102191:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102193:	83 c4 10             	add    $0x10,%esp
f0102196:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010219b:	0f 86 29 08 00 00    	jbe    f01029ca <mem_init+0x15dd>
f01021a1:	83 ec 08             	sub    $0x8,%esp
f01021a4:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f01021a6:	05 00 00 00 10       	add    $0x10000000,%eax
f01021ab:	50                   	push   %eax
f01021ac:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01021b1:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01021b6:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f01021bc:	8b 00                	mov    (%eax),%eax
f01021be:	e8 8b f0 ff ff       	call   f010124e <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f01021c3:	c7 c0 00 40 11 f0    	mov    $0xf0114000,%eax
f01021c9:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01021cc:	83 c4 10             	add    $0x10,%esp
f01021cf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021d4:	0f 86 09 08 00 00    	jbe    f01029e3 <mem_init+0x15f6>
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f01021da:	c7 c6 0c 10 19 f0    	mov    $0xf019100c,%esi
f01021e0:	83 ec 08             	sub    $0x8,%esp
f01021e3:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f01021e5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01021e8:	05 00 00 00 10       	add    $0x10000000,%eax
f01021ed:	50                   	push   %eax
f01021ee:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021f3:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021f8:	8b 06                	mov    (%esi),%eax
f01021fa:	e8 4f f0 ff ff       	call   f010124e <boot_map_region>
	boot_map_region(kern_pgdir,KERNBASE,0xFFFFFFFF-KERNBASE,0,PTE_W);
f01021ff:	83 c4 08             	add    $0x8,%esp
f0102202:	6a 02                	push   $0x2
f0102204:	6a 00                	push   $0x0
f0102206:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010220b:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102210:	8b 06                	mov    (%esi),%eax
f0102212:	e8 37 f0 ff ff       	call   f010124e <boot_map_region>
	pgdir = kern_pgdir;
f0102217:	8b 06                	mov    (%esi),%eax
f0102219:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010221c:	c7 c0 08 10 19 f0    	mov    $0xf0191008,%eax
f0102222:	8b 00                	mov    (%eax),%eax
f0102224:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0102227:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010222e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102233:	89 45 cc             	mov    %eax,-0x34(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102236:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f010223c:	8b 00                	mov    (%eax),%eax
f010223e:	89 45 bc             	mov    %eax,-0x44(%ebp)
	if ((uint32_t)kva < KERNBASE)
f0102241:	89 45 c8             	mov    %eax,-0x38(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0102244:	05 00 00 00 10       	add    $0x10000000,%eax
f0102249:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f010224c:	83 c4 10             	add    $0x10,%esp
f010224f:	89 fe                	mov    %edi,%esi
f0102251:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0102254:	0f 86 dc 07 00 00    	jbe    f0102a36 <mem_init+0x1649>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010225a:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0102260:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102263:	e8 5b e9 ff ff       	call   f0100bc3 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102268:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f010226f:	0f 86 87 07 00 00    	jbe    f01029fc <mem_init+0x160f>
f0102275:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102278:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010227b:	39 d0                	cmp    %edx,%eax
f010227d:	0f 85 94 07 00 00    	jne    f0102a17 <mem_init+0x162a>
	for (i = 0; i < n; i += PGSIZE)
f0102283:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102289:	eb c6                	jmp    f0102251 <mem_init+0xe64>
	assert(nfree == 0);
f010228b:	8d 83 a0 84 f7 ff    	lea    -0x87b60(%ebx),%eax
f0102291:	50                   	push   %eax
f0102292:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102298:	50                   	push   %eax
f0102299:	68 51 03 00 00       	push   $0x351
f010229e:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01022a4:	50                   	push   %eax
f01022a5:	e8 0b de ff ff       	call   f01000b5 <_panic>
	assert((pp0 = page_alloc(0)));
f01022aa:	8d 83 ae 83 f7 ff    	lea    -0x87c52(%ebx),%eax
f01022b0:	50                   	push   %eax
f01022b1:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01022b7:	50                   	push   %eax
f01022b8:	68 af 03 00 00       	push   $0x3af
f01022bd:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01022c3:	50                   	push   %eax
f01022c4:	e8 ec dd ff ff       	call   f01000b5 <_panic>
	assert((pp1 = page_alloc(0)));
f01022c9:	8d 83 c4 83 f7 ff    	lea    -0x87c3c(%ebx),%eax
f01022cf:	50                   	push   %eax
f01022d0:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01022d6:	50                   	push   %eax
f01022d7:	68 b0 03 00 00       	push   $0x3b0
f01022dc:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01022e2:	50                   	push   %eax
f01022e3:	e8 cd dd ff ff       	call   f01000b5 <_panic>
	assert((pp2 = page_alloc(0)));
f01022e8:	8d 83 da 83 f7 ff    	lea    -0x87c26(%ebx),%eax
f01022ee:	50                   	push   %eax
f01022ef:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01022f5:	50                   	push   %eax
f01022f6:	68 b1 03 00 00       	push   $0x3b1
f01022fb:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102301:	50                   	push   %eax
f0102302:	e8 ae dd ff ff       	call   f01000b5 <_panic>
	assert(pp1 && pp1 != pp0);
f0102307:	8d 83 f0 83 f7 ff    	lea    -0x87c10(%ebx),%eax
f010230d:	50                   	push   %eax
f010230e:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102314:	50                   	push   %eax
f0102315:	68 b4 03 00 00       	push   $0x3b4
f010231a:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102320:	50                   	push   %eax
f0102321:	e8 8f dd ff ff       	call   f01000b5 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0102326:	8d 83 88 7c f7 ff    	lea    -0x88378(%ebx),%eax
f010232c:	50                   	push   %eax
f010232d:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102333:	50                   	push   %eax
f0102334:	68 b5 03 00 00       	push   $0x3b5
f0102339:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010233f:	50                   	push   %eax
f0102340:	e8 70 dd ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f0102345:	8d 83 59 84 f7 ff    	lea    -0x87ba7(%ebx),%eax
f010234b:	50                   	push   %eax
f010234c:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102352:	50                   	push   %eax
f0102353:	68 bc 03 00 00       	push   $0x3bc
f0102358:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010235e:	50                   	push   %eax
f010235f:	e8 51 dd ff ff       	call   f01000b5 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102364:	8d 83 c8 7c f7 ff    	lea    -0x88338(%ebx),%eax
f010236a:	50                   	push   %eax
f010236b:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102371:	50                   	push   %eax
f0102372:	68 bf 03 00 00       	push   $0x3bf
f0102377:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010237d:	50                   	push   %eax
f010237e:	e8 32 dd ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102383:	8d 83 00 7d f7 ff    	lea    -0x88300(%ebx),%eax
f0102389:	50                   	push   %eax
f010238a:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102390:	50                   	push   %eax
f0102391:	68 c2 03 00 00       	push   $0x3c2
f0102396:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010239c:	50                   	push   %eax
f010239d:	e8 13 dd ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01023a2:	8d 83 30 7d f7 ff    	lea    -0x882d0(%ebx),%eax
f01023a8:	50                   	push   %eax
f01023a9:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01023af:	50                   	push   %eax
f01023b0:	68 c6 03 00 00       	push   $0x3c6
f01023b5:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01023bb:	50                   	push   %eax
f01023bc:	e8 f4 dc ff ff       	call   f01000b5 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01023c1:	8d 83 60 7d f7 ff    	lea    -0x882a0(%ebx),%eax
f01023c7:	50                   	push   %eax
f01023c8:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01023ce:	50                   	push   %eax
f01023cf:	68 c7 03 00 00       	push   $0x3c7
f01023d4:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01023da:	50                   	push   %eax
f01023db:	e8 d5 dc ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01023e0:	8d 83 88 7d f7 ff    	lea    -0x88278(%ebx),%eax
f01023e6:	50                   	push   %eax
f01023e7:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01023ed:	50                   	push   %eax
f01023ee:	68 c8 03 00 00       	push   $0x3c8
f01023f3:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01023f9:	50                   	push   %eax
f01023fa:	e8 b6 dc ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 1);
f01023ff:	8d 83 ab 84 f7 ff    	lea    -0x87b55(%ebx),%eax
f0102405:	50                   	push   %eax
f0102406:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f010240c:	50                   	push   %eax
f010240d:	68 c9 03 00 00       	push   $0x3c9
f0102412:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102418:	50                   	push   %eax
f0102419:	e8 97 dc ff ff       	call   f01000b5 <_panic>
	assert(pp0->pp_ref == 1);
f010241e:	8d 83 bc 84 f7 ff    	lea    -0x87b44(%ebx),%eax
f0102424:	50                   	push   %eax
f0102425:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f010242b:	50                   	push   %eax
f010242c:	68 ca 03 00 00       	push   $0x3ca
f0102431:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102437:	50                   	push   %eax
f0102438:	e8 78 dc ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010243d:	8d 83 b8 7d f7 ff    	lea    -0x88248(%ebx),%eax
f0102443:	50                   	push   %eax
f0102444:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f010244a:	50                   	push   %eax
f010244b:	68 cd 03 00 00       	push   $0x3cd
f0102450:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102456:	50                   	push   %eax
f0102457:	e8 59 dc ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010245c:	8d 83 f4 7d f7 ff    	lea    -0x8820c(%ebx),%eax
f0102462:	50                   	push   %eax
f0102463:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102469:	50                   	push   %eax
f010246a:	68 ce 03 00 00       	push   $0x3ce
f010246f:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102475:	50                   	push   %eax
f0102476:	e8 3a dc ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 1);
f010247b:	8d 83 cd 84 f7 ff    	lea    -0x87b33(%ebx),%eax
f0102481:	50                   	push   %eax
f0102482:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102488:	50                   	push   %eax
f0102489:	68 cf 03 00 00       	push   $0x3cf
f010248e:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102494:	50                   	push   %eax
f0102495:	e8 1b dc ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f010249a:	8d 83 59 84 f7 ff    	lea    -0x87ba7(%ebx),%eax
f01024a0:	50                   	push   %eax
f01024a1:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01024a7:	50                   	push   %eax
f01024a8:	68 d2 03 00 00       	push   $0x3d2
f01024ad:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01024b3:	50                   	push   %eax
f01024b4:	e8 fc db ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01024b9:	8d 83 b8 7d f7 ff    	lea    -0x88248(%ebx),%eax
f01024bf:	50                   	push   %eax
f01024c0:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01024c6:	50                   	push   %eax
f01024c7:	68 d5 03 00 00       	push   $0x3d5
f01024cc:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01024d2:	50                   	push   %eax
f01024d3:	e8 dd db ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01024d8:	8d 83 f4 7d f7 ff    	lea    -0x8820c(%ebx),%eax
f01024de:	50                   	push   %eax
f01024df:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01024e5:	50                   	push   %eax
f01024e6:	68 d6 03 00 00       	push   $0x3d6
f01024eb:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01024f1:	50                   	push   %eax
f01024f2:	e8 be db ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 1);
f01024f7:	8d 83 cd 84 f7 ff    	lea    -0x87b33(%ebx),%eax
f01024fd:	50                   	push   %eax
f01024fe:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102504:	50                   	push   %eax
f0102505:	68 d7 03 00 00       	push   $0x3d7
f010250a:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102510:	50                   	push   %eax
f0102511:	e8 9f db ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f0102516:	8d 83 59 84 f7 ff    	lea    -0x87ba7(%ebx),%eax
f010251c:	50                   	push   %eax
f010251d:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102523:	50                   	push   %eax
f0102524:	68 db 03 00 00       	push   $0x3db
f0102529:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010252f:	50                   	push   %eax
f0102530:	e8 80 db ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102535:	52                   	push   %edx
f0102536:	8d 83 b4 7a f7 ff    	lea    -0x8854c(%ebx),%eax
f010253c:	50                   	push   %eax
f010253d:	68 de 03 00 00       	push   $0x3de
f0102542:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102548:	50                   	push   %eax
f0102549:	e8 67 db ff ff       	call   f01000b5 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010254e:	8d 83 24 7e f7 ff    	lea    -0x881dc(%ebx),%eax
f0102554:	50                   	push   %eax
f0102555:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f010255b:	50                   	push   %eax
f010255c:	68 df 03 00 00       	push   $0x3df
f0102561:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102567:	50                   	push   %eax
f0102568:	e8 48 db ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010256d:	8d 83 64 7e f7 ff    	lea    -0x8819c(%ebx),%eax
f0102573:	50                   	push   %eax
f0102574:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f010257a:	50                   	push   %eax
f010257b:	68 e2 03 00 00       	push   $0x3e2
f0102580:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102586:	50                   	push   %eax
f0102587:	e8 29 db ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010258c:	8d 83 f4 7d f7 ff    	lea    -0x8820c(%ebx),%eax
f0102592:	50                   	push   %eax
f0102593:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102599:	50                   	push   %eax
f010259a:	68 e3 03 00 00       	push   $0x3e3
f010259f:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01025a5:	50                   	push   %eax
f01025a6:	e8 0a db ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 1);
f01025ab:	8d 83 cd 84 f7 ff    	lea    -0x87b33(%ebx),%eax
f01025b1:	50                   	push   %eax
f01025b2:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01025b8:	50                   	push   %eax
f01025b9:	68 e4 03 00 00       	push   $0x3e4
f01025be:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01025c4:	50                   	push   %eax
f01025c5:	e8 eb da ff ff       	call   f01000b5 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01025ca:	8d 83 a4 7e f7 ff    	lea    -0x8815c(%ebx),%eax
f01025d0:	50                   	push   %eax
f01025d1:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01025d7:	50                   	push   %eax
f01025d8:	68 e5 03 00 00       	push   $0x3e5
f01025dd:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01025e3:	50                   	push   %eax
f01025e4:	e8 cc da ff ff       	call   f01000b5 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01025e9:	8d 83 de 84 f7 ff    	lea    -0x87b22(%ebx),%eax
f01025ef:	50                   	push   %eax
f01025f0:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01025f6:	50                   	push   %eax
f01025f7:	68 e6 03 00 00       	push   $0x3e6
f01025fc:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102602:	50                   	push   %eax
f0102603:	e8 ad da ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102608:	8d 83 b8 7d f7 ff    	lea    -0x88248(%ebx),%eax
f010260e:	50                   	push   %eax
f010260f:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102615:	50                   	push   %eax
f0102616:	68 e9 03 00 00       	push   $0x3e9
f010261b:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102621:	50                   	push   %eax
f0102622:	e8 8e da ff ff       	call   f01000b5 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102627:	8d 83 d8 7e f7 ff    	lea    -0x88128(%ebx),%eax
f010262d:	50                   	push   %eax
f010262e:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102634:	50                   	push   %eax
f0102635:	68 ea 03 00 00       	push   $0x3ea
f010263a:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102640:	50                   	push   %eax
f0102641:	e8 6f da ff ff       	call   f01000b5 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102646:	8d 83 0c 7f f7 ff    	lea    -0x880f4(%ebx),%eax
f010264c:	50                   	push   %eax
f010264d:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102653:	50                   	push   %eax
f0102654:	68 eb 03 00 00       	push   $0x3eb
f0102659:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010265f:	50                   	push   %eax
f0102660:	e8 50 da ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102665:	8d 83 44 7f f7 ff    	lea    -0x880bc(%ebx),%eax
f010266b:	50                   	push   %eax
f010266c:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102672:	50                   	push   %eax
f0102673:	68 ee 03 00 00       	push   $0x3ee
f0102678:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010267e:	50                   	push   %eax
f010267f:	e8 31 da ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102684:	8d 83 7c 7f f7 ff    	lea    -0x88084(%ebx),%eax
f010268a:	50                   	push   %eax
f010268b:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102691:	50                   	push   %eax
f0102692:	68 f1 03 00 00       	push   $0x3f1
f0102697:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010269d:	50                   	push   %eax
f010269e:	e8 12 da ff ff       	call   f01000b5 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01026a3:	8d 83 0c 7f f7 ff    	lea    -0x880f4(%ebx),%eax
f01026a9:	50                   	push   %eax
f01026aa:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01026b0:	50                   	push   %eax
f01026b1:	68 f2 03 00 00       	push   $0x3f2
f01026b6:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01026bc:	50                   	push   %eax
f01026bd:	e8 f3 d9 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01026c2:	8d 83 b8 7f f7 ff    	lea    -0x88048(%ebx),%eax
f01026c8:	50                   	push   %eax
f01026c9:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01026cf:	50                   	push   %eax
f01026d0:	68 f5 03 00 00       	push   $0x3f5
f01026d5:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01026db:	50                   	push   %eax
f01026dc:	e8 d4 d9 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01026e1:	8d 83 e4 7f f7 ff    	lea    -0x8801c(%ebx),%eax
f01026e7:	50                   	push   %eax
f01026e8:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01026ee:	50                   	push   %eax
f01026ef:	68 f6 03 00 00       	push   $0x3f6
f01026f4:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01026fa:	50                   	push   %eax
f01026fb:	e8 b5 d9 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 2);
f0102700:	8d 83 f4 84 f7 ff    	lea    -0x87b0c(%ebx),%eax
f0102706:	50                   	push   %eax
f0102707:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f010270d:	50                   	push   %eax
f010270e:	68 f8 03 00 00       	push   $0x3f8
f0102713:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102719:	50                   	push   %eax
f010271a:	e8 96 d9 ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 0);
f010271f:	8d 83 05 85 f7 ff    	lea    -0x87afb(%ebx),%eax
f0102725:	50                   	push   %eax
f0102726:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f010272c:	50                   	push   %eax
f010272d:	68 f9 03 00 00       	push   $0x3f9
f0102732:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102738:	50                   	push   %eax
f0102739:	e8 77 d9 ff ff       	call   f01000b5 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f010273e:	8d 83 14 80 f7 ff    	lea    -0x87fec(%ebx),%eax
f0102744:	50                   	push   %eax
f0102745:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f010274b:	50                   	push   %eax
f010274c:	68 fc 03 00 00       	push   $0x3fc
f0102751:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102757:	50                   	push   %eax
f0102758:	e8 58 d9 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010275d:	8d 83 38 80 f7 ff    	lea    -0x87fc8(%ebx),%eax
f0102763:	50                   	push   %eax
f0102764:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f010276a:	50                   	push   %eax
f010276b:	68 00 04 00 00       	push   $0x400
f0102770:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102776:	50                   	push   %eax
f0102777:	e8 39 d9 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010277c:	8d 83 e4 7f f7 ff    	lea    -0x8801c(%ebx),%eax
f0102782:	50                   	push   %eax
f0102783:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102789:	50                   	push   %eax
f010278a:	68 01 04 00 00       	push   $0x401
f010278f:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102795:	50                   	push   %eax
f0102796:	e8 1a d9 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 1);
f010279b:	8d 83 ab 84 f7 ff    	lea    -0x87b55(%ebx),%eax
f01027a1:	50                   	push   %eax
f01027a2:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01027a8:	50                   	push   %eax
f01027a9:	68 02 04 00 00       	push   $0x402
f01027ae:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01027b4:	50                   	push   %eax
f01027b5:	e8 fb d8 ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 0);
f01027ba:	8d 83 05 85 f7 ff    	lea    -0x87afb(%ebx),%eax
f01027c0:	50                   	push   %eax
f01027c1:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01027c7:	50                   	push   %eax
f01027c8:	68 03 04 00 00       	push   $0x403
f01027cd:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01027d3:	50                   	push   %eax
f01027d4:	e8 dc d8 ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01027d9:	8d 83 5c 80 f7 ff    	lea    -0x87fa4(%ebx),%eax
f01027df:	50                   	push   %eax
f01027e0:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01027e6:	50                   	push   %eax
f01027e7:	68 06 04 00 00       	push   $0x406
f01027ec:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01027f2:	50                   	push   %eax
f01027f3:	e8 bd d8 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref);
f01027f8:	8d 83 16 85 f7 ff    	lea    -0x87aea(%ebx),%eax
f01027fe:	50                   	push   %eax
f01027ff:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102805:	50                   	push   %eax
f0102806:	68 07 04 00 00       	push   $0x407
f010280b:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102811:	50                   	push   %eax
f0102812:	e8 9e d8 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_link == NULL);
f0102817:	8d 83 22 85 f7 ff    	lea    -0x87ade(%ebx),%eax
f010281d:	50                   	push   %eax
f010281e:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102824:	50                   	push   %eax
f0102825:	68 08 04 00 00       	push   $0x408
f010282a:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102830:	50                   	push   %eax
f0102831:	e8 7f d8 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102836:	8d 83 38 80 f7 ff    	lea    -0x87fc8(%ebx),%eax
f010283c:	50                   	push   %eax
f010283d:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102843:	50                   	push   %eax
f0102844:	68 0c 04 00 00       	push   $0x40c
f0102849:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010284f:	50                   	push   %eax
f0102850:	e8 60 d8 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102855:	8d 83 94 80 f7 ff    	lea    -0x87f6c(%ebx),%eax
f010285b:	50                   	push   %eax
f010285c:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102862:	50                   	push   %eax
f0102863:	68 0d 04 00 00       	push   $0x40d
f0102868:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010286e:	50                   	push   %eax
f010286f:	e8 41 d8 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 0);
f0102874:	8d 83 37 85 f7 ff    	lea    -0x87ac9(%ebx),%eax
f010287a:	50                   	push   %eax
f010287b:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102881:	50                   	push   %eax
f0102882:	68 0e 04 00 00       	push   $0x40e
f0102887:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010288d:	50                   	push   %eax
f010288e:	e8 22 d8 ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 0);
f0102893:	8d 83 05 85 f7 ff    	lea    -0x87afb(%ebx),%eax
f0102899:	50                   	push   %eax
f010289a:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01028a0:	50                   	push   %eax
f01028a1:	68 0f 04 00 00       	push   $0x40f
f01028a6:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01028ac:	50                   	push   %eax
f01028ad:	e8 03 d8 ff ff       	call   f01000b5 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f01028b2:	8d 83 bc 80 f7 ff    	lea    -0x87f44(%ebx),%eax
f01028b8:	50                   	push   %eax
f01028b9:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01028bf:	50                   	push   %eax
f01028c0:	68 12 04 00 00       	push   $0x412
f01028c5:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01028cb:	50                   	push   %eax
f01028cc:	e8 e4 d7 ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f01028d1:	8d 83 59 84 f7 ff    	lea    -0x87ba7(%ebx),%eax
f01028d7:	50                   	push   %eax
f01028d8:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01028de:	50                   	push   %eax
f01028df:	68 15 04 00 00       	push   $0x415
f01028e4:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01028ea:	50                   	push   %eax
f01028eb:	e8 c5 d7 ff ff       	call   f01000b5 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01028f0:	8d 83 60 7d f7 ff    	lea    -0x882a0(%ebx),%eax
f01028f6:	50                   	push   %eax
f01028f7:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01028fd:	50                   	push   %eax
f01028fe:	68 18 04 00 00       	push   $0x418
f0102903:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102909:	50                   	push   %eax
f010290a:	e8 a6 d7 ff ff       	call   f01000b5 <_panic>
	assert(pp0->pp_ref == 1);
f010290f:	8d 83 bc 84 f7 ff    	lea    -0x87b44(%ebx),%eax
f0102915:	50                   	push   %eax
f0102916:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f010291c:	50                   	push   %eax
f010291d:	68 1a 04 00 00       	push   $0x41a
f0102922:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102928:	50                   	push   %eax
f0102929:	e8 87 d7 ff ff       	call   f01000b5 <_panic>
f010292e:	51                   	push   %ecx
f010292f:	8d 83 b4 7a f7 ff    	lea    -0x8854c(%ebx),%eax
f0102935:	50                   	push   %eax
f0102936:	68 21 04 00 00       	push   $0x421
f010293b:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102941:	50                   	push   %eax
f0102942:	e8 6e d7 ff ff       	call   f01000b5 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102947:	8d 83 48 85 f7 ff    	lea    -0x87ab8(%ebx),%eax
f010294d:	50                   	push   %eax
f010294e:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102954:	50                   	push   %eax
f0102955:	68 22 04 00 00       	push   $0x422
f010295a:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102960:	50                   	push   %eax
f0102961:	e8 4f d7 ff ff       	call   f01000b5 <_panic>
f0102966:	52                   	push   %edx
f0102967:	8d 83 b4 7a f7 ff    	lea    -0x8854c(%ebx),%eax
f010296d:	50                   	push   %eax
f010296e:	6a 56                	push   $0x56
f0102970:	8d 83 e9 82 f7 ff    	lea    -0x87d17(%ebx),%eax
f0102976:	50                   	push   %eax
f0102977:	e8 39 d7 ff ff       	call   f01000b5 <_panic>
f010297c:	52                   	push   %edx
f010297d:	8d 83 b4 7a f7 ff    	lea    -0x8854c(%ebx),%eax
f0102983:	50                   	push   %eax
f0102984:	6a 56                	push   $0x56
f0102986:	8d 83 e9 82 f7 ff    	lea    -0x87d17(%ebx),%eax
f010298c:	50                   	push   %eax
f010298d:	e8 23 d7 ff ff       	call   f01000b5 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102992:	8d 83 60 85 f7 ff    	lea    -0x87aa0(%ebx),%eax
f0102998:	50                   	push   %eax
f0102999:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f010299f:	50                   	push   %eax
f01029a0:	68 2c 04 00 00       	push   $0x42c
f01029a5:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01029ab:	50                   	push   %eax
f01029ac:	e8 04 d7 ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029b1:	50                   	push   %eax
f01029b2:	8d 83 64 7c f7 ff    	lea    -0x8839c(%ebx),%eax
f01029b8:	50                   	push   %eax
f01029b9:	68 c9 00 00 00       	push   $0xc9
f01029be:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01029c4:	50                   	push   %eax
f01029c5:	e8 eb d6 ff ff       	call   f01000b5 <_panic>
f01029ca:	50                   	push   %eax
f01029cb:	8d 83 64 7c f7 ff    	lea    -0x8839c(%ebx),%eax
f01029d1:	50                   	push   %eax
f01029d2:	68 d1 00 00 00       	push   $0xd1
f01029d7:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01029dd:	50                   	push   %eax
f01029de:	e8 d2 d6 ff ff       	call   f01000b5 <_panic>
f01029e3:	50                   	push   %eax
f01029e4:	8d 83 64 7c f7 ff    	lea    -0x8839c(%ebx),%eax
f01029ea:	50                   	push   %eax
f01029eb:	68 dd 00 00 00       	push   $0xdd
f01029f0:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f01029f6:	50                   	push   %eax
f01029f7:	e8 b9 d6 ff ff       	call   f01000b5 <_panic>
f01029fc:	ff 75 bc             	pushl  -0x44(%ebp)
f01029ff:	8d 83 64 7c f7 ff    	lea    -0x8839c(%ebx),%eax
f0102a05:	50                   	push   %eax
f0102a06:	68 69 03 00 00       	push   $0x369
f0102a0b:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102a11:	50                   	push   %eax
f0102a12:	e8 9e d6 ff ff       	call   f01000b5 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102a17:	8d 83 e0 80 f7 ff    	lea    -0x87f20(%ebx),%eax
f0102a1d:	50                   	push   %eax
f0102a1e:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102a24:	50                   	push   %eax
f0102a25:	68 69 03 00 00       	push   $0x369
f0102a2a:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102a30:	50                   	push   %eax
f0102a31:	e8 7f d6 ff ff       	call   f01000b5 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102a36:	c7 c0 4c 03 19 f0    	mov    $0xf019034c,%eax
f0102a3c:	8b 00                	mov    (%eax),%eax
f0102a3e:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	if ((uint32_t)kva < KERNBASE)
f0102a41:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102a44:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f0102a49:	05 00 00 40 21       	add    $0x21400000,%eax
f0102a4e:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102a51:	89 f2                	mov    %esi,%edx
f0102a53:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a56:	e8 68 e1 ff ff       	call   f0100bc3 <check_va2pa>
f0102a5b:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102a62:	76 42                	jbe    f0102aa6 <mem_init+0x16b9>
f0102a64:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102a67:	8d 14 31             	lea    (%ecx,%esi,1),%edx
f0102a6a:	39 d0                	cmp    %edx,%eax
f0102a6c:	75 53                	jne    f0102ac1 <mem_init+0x16d4>
f0102a6e:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
f0102a74:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102a7a:	75 d5                	jne    f0102a51 <mem_init+0x1664>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a7c:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0102a7f:	c1 e0 0c             	shl    $0xc,%eax
f0102a82:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102a85:	89 fe                	mov    %edi,%esi
f0102a87:	3b 75 cc             	cmp    -0x34(%ebp),%esi
f0102a8a:	73 73                	jae    f0102aff <mem_init+0x1712>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102a8c:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0102a92:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a95:	e8 29 e1 ff ff       	call   f0100bc3 <check_va2pa>
f0102a9a:	39 c6                	cmp    %eax,%esi
f0102a9c:	75 42                	jne    f0102ae0 <mem_init+0x16f3>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a9e:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102aa4:	eb e1                	jmp    f0102a87 <mem_init+0x169a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102aa6:	ff 75 c4             	pushl  -0x3c(%ebp)
f0102aa9:	8d 83 64 7c f7 ff    	lea    -0x8839c(%ebx),%eax
f0102aaf:	50                   	push   %eax
f0102ab0:	68 6e 03 00 00       	push   $0x36e
f0102ab5:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102abb:	50                   	push   %eax
f0102abc:	e8 f4 d5 ff ff       	call   f01000b5 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102ac1:	8d 83 14 81 f7 ff    	lea    -0x87eec(%ebx),%eax
f0102ac7:	50                   	push   %eax
f0102ac8:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102ace:	50                   	push   %eax
f0102acf:	68 6e 03 00 00       	push   $0x36e
f0102ad4:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102ada:	50                   	push   %eax
f0102adb:	e8 d5 d5 ff ff       	call   f01000b5 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102ae0:	8d 83 48 81 f7 ff    	lea    -0x87eb8(%ebx),%eax
f0102ae6:	50                   	push   %eax
f0102ae7:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102aed:	50                   	push   %eax
f0102aee:	68 72 03 00 00       	push   $0x372
f0102af3:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102af9:	50                   	push   %eax
f0102afa:	e8 b6 d5 ff ff       	call   f01000b5 <_panic>
f0102aff:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102b04:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102b07:	05 00 80 00 20       	add    $0x20008000,%eax
f0102b0c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102b0f:	89 f2                	mov    %esi,%edx
f0102b11:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b14:	e8 aa e0 ff ff       	call   f0100bc3 <check_va2pa>
f0102b19:	89 c2                	mov    %eax,%edx
f0102b1b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102b1e:	01 f0                	add    %esi,%eax
f0102b20:	39 c2                	cmp    %eax,%edx
f0102b22:	75 25                	jne    f0102b49 <mem_init+0x175c>
f0102b24:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102b2a:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102b30:	75 dd                	jne    f0102b0f <mem_init+0x1722>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102b32:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102b37:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b3a:	e8 84 e0 ff ff       	call   f0100bc3 <check_va2pa>
f0102b3f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102b42:	75 24                	jne    f0102b68 <mem_init+0x177b>
f0102b44:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b47:	eb 6b                	jmp    f0102bb4 <mem_init+0x17c7>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102b49:	8d 83 70 81 f7 ff    	lea    -0x87e90(%ebx),%eax
f0102b4f:	50                   	push   %eax
f0102b50:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102b56:	50                   	push   %eax
f0102b57:	68 76 03 00 00       	push   $0x376
f0102b5c:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102b62:	50                   	push   %eax
f0102b63:	e8 4d d5 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102b68:	8d 83 b8 81 f7 ff    	lea    -0x87e48(%ebx),%eax
f0102b6e:	50                   	push   %eax
f0102b6f:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102b75:	50                   	push   %eax
f0102b76:	68 77 03 00 00       	push   $0x377
f0102b7b:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102b81:	50                   	push   %eax
f0102b82:	e8 2e d5 ff ff       	call   f01000b5 <_panic>
		switch (i) {
f0102b87:	81 ff bf 03 00 00    	cmp    $0x3bf,%edi
f0102b8d:	75 25                	jne    f0102bb4 <mem_init+0x17c7>
			assert(pgdir[i] & PTE_P);
f0102b8f:	f6 04 b8 01          	testb  $0x1,(%eax,%edi,4)
f0102b93:	74 4c                	je     f0102be1 <mem_init+0x17f4>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b95:	83 c7 01             	add    $0x1,%edi
f0102b98:	81 ff ff 03 00 00    	cmp    $0x3ff,%edi
f0102b9e:	0f 87 a7 00 00 00    	ja     f0102c4b <mem_init+0x185e>
		switch (i) {
f0102ba4:	81 ff bd 03 00 00    	cmp    $0x3bd,%edi
f0102baa:	77 db                	ja     f0102b87 <mem_init+0x179a>
f0102bac:	81 ff ba 03 00 00    	cmp    $0x3ba,%edi
f0102bb2:	77 db                	ja     f0102b8f <mem_init+0x17a2>
			if (i >= PDX(KERNBASE)) {
f0102bb4:	81 ff bf 03 00 00    	cmp    $0x3bf,%edi
f0102bba:	77 44                	ja     f0102c00 <mem_init+0x1813>
				assert(pgdir[i] == 0);
f0102bbc:	83 3c b8 00          	cmpl   $0x0,(%eax,%edi,4)
f0102bc0:	74 d3                	je     f0102b95 <mem_init+0x17a8>
f0102bc2:	8d 83 b2 85 f7 ff    	lea    -0x87a4e(%ebx),%eax
f0102bc8:	50                   	push   %eax
f0102bc9:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102bcf:	50                   	push   %eax
f0102bd0:	68 87 03 00 00       	push   $0x387
f0102bd5:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102bdb:	50                   	push   %eax
f0102bdc:	e8 d4 d4 ff ff       	call   f01000b5 <_panic>
			assert(pgdir[i] & PTE_P);
f0102be1:	8d 83 90 85 f7 ff    	lea    -0x87a70(%ebx),%eax
f0102be7:	50                   	push   %eax
f0102be8:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102bee:	50                   	push   %eax
f0102bef:	68 80 03 00 00       	push   $0x380
f0102bf4:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102bfa:	50                   	push   %eax
f0102bfb:	e8 b5 d4 ff ff       	call   f01000b5 <_panic>
				assert(pgdir[i] & PTE_P);
f0102c00:	8b 14 b8             	mov    (%eax,%edi,4),%edx
f0102c03:	f6 c2 01             	test   $0x1,%dl
f0102c06:	74 24                	je     f0102c2c <mem_init+0x183f>
				assert(pgdir[i] & PTE_W);
f0102c08:	f6 c2 02             	test   $0x2,%dl
f0102c0b:	75 88                	jne    f0102b95 <mem_init+0x17a8>
f0102c0d:	8d 83 a1 85 f7 ff    	lea    -0x87a5f(%ebx),%eax
f0102c13:	50                   	push   %eax
f0102c14:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102c1a:	50                   	push   %eax
f0102c1b:	68 85 03 00 00       	push   $0x385
f0102c20:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102c26:	50                   	push   %eax
f0102c27:	e8 89 d4 ff ff       	call   f01000b5 <_panic>
				assert(pgdir[i] & PTE_P);
f0102c2c:	8d 83 90 85 f7 ff    	lea    -0x87a70(%ebx),%eax
f0102c32:	50                   	push   %eax
f0102c33:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102c39:	50                   	push   %eax
f0102c3a:	68 84 03 00 00       	push   $0x384
f0102c3f:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102c45:	50                   	push   %eax
f0102c46:	e8 6a d4 ff ff       	call   f01000b5 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102c4b:	83 ec 0c             	sub    $0xc,%esp
f0102c4e:	8d 83 e8 81 f7 ff    	lea    -0x87e18(%ebx),%eax
f0102c54:	50                   	push   %eax
f0102c55:	e8 de 0d 00 00       	call   f0103a38 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102c5a:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0102c60:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102c62:	83 c4 10             	add    $0x10,%esp
f0102c65:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c6a:	0f 86 30 02 00 00    	jbe    f0102ea0 <mem_init+0x1ab3>
	return (physaddr_t)kva - KERNBASE;
f0102c70:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102c75:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102c78:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c7d:	e8 bd df ff ff       	call   f0100c3f <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102c82:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102c85:	83 e0 f3             	and    $0xfffffff3,%eax
f0102c88:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102c8d:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102c90:	83 ec 0c             	sub    $0xc,%esp
f0102c93:	6a 00                	push   $0x0
f0102c95:	e8 fa e3 ff ff       	call   f0101094 <page_alloc>
f0102c9a:	89 c6                	mov    %eax,%esi
f0102c9c:	83 c4 10             	add    $0x10,%esp
f0102c9f:	85 c0                	test   %eax,%eax
f0102ca1:	0f 84 12 02 00 00    	je     f0102eb9 <mem_init+0x1acc>
	assert((pp1 = page_alloc(0)));
f0102ca7:	83 ec 0c             	sub    $0xc,%esp
f0102caa:	6a 00                	push   $0x0
f0102cac:	e8 e3 e3 ff ff       	call   f0101094 <page_alloc>
f0102cb1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102cb4:	83 c4 10             	add    $0x10,%esp
f0102cb7:	85 c0                	test   %eax,%eax
f0102cb9:	0f 84 19 02 00 00    	je     f0102ed8 <mem_init+0x1aeb>
	assert((pp2 = page_alloc(0)));
f0102cbf:	83 ec 0c             	sub    $0xc,%esp
f0102cc2:	6a 00                	push   $0x0
f0102cc4:	e8 cb e3 ff ff       	call   f0101094 <page_alloc>
f0102cc9:	89 c7                	mov    %eax,%edi
f0102ccb:	83 c4 10             	add    $0x10,%esp
f0102cce:	85 c0                	test   %eax,%eax
f0102cd0:	0f 84 21 02 00 00    	je     f0102ef7 <mem_init+0x1b0a>
	page_free(pp0);
f0102cd6:	83 ec 0c             	sub    $0xc,%esp
f0102cd9:	56                   	push   %esi
f0102cda:	e8 44 e4 ff ff       	call   f0101123 <page_free>
	return (pp - pages) << PGSHIFT;
f0102cdf:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f0102ce5:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102ce8:	2b 08                	sub    (%eax),%ecx
f0102cea:	89 c8                	mov    %ecx,%eax
f0102cec:	c1 f8 03             	sar    $0x3,%eax
f0102cef:	89 c2                	mov    %eax,%edx
f0102cf1:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102cf4:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102cf9:	83 c4 10             	add    $0x10,%esp
f0102cfc:	c7 c1 08 10 19 f0    	mov    $0xf0191008,%ecx
f0102d02:	3b 01                	cmp    (%ecx),%eax
f0102d04:	0f 83 0c 02 00 00    	jae    f0102f16 <mem_init+0x1b29>
	memset(page2kva(pp1), 1, PGSIZE);
f0102d0a:	83 ec 04             	sub    $0x4,%esp
f0102d0d:	68 00 10 00 00       	push   $0x1000
f0102d12:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102d14:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102d1a:	52                   	push   %edx
f0102d1b:	e8 41 24 00 00       	call   f0105161 <memset>
	return (pp - pages) << PGSHIFT;
f0102d20:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f0102d26:	89 f9                	mov    %edi,%ecx
f0102d28:	2b 08                	sub    (%eax),%ecx
f0102d2a:	89 c8                	mov    %ecx,%eax
f0102d2c:	c1 f8 03             	sar    $0x3,%eax
f0102d2f:	89 c2                	mov    %eax,%edx
f0102d31:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102d34:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102d39:	83 c4 10             	add    $0x10,%esp
f0102d3c:	c7 c1 08 10 19 f0    	mov    $0xf0191008,%ecx
f0102d42:	3b 01                	cmp    (%ecx),%eax
f0102d44:	0f 83 e2 01 00 00    	jae    f0102f2c <mem_init+0x1b3f>
	memset(page2kva(pp2), 2, PGSIZE);
f0102d4a:	83 ec 04             	sub    $0x4,%esp
f0102d4d:	68 00 10 00 00       	push   $0x1000
f0102d52:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102d54:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102d5a:	52                   	push   %edx
f0102d5b:	e8 01 24 00 00       	call   f0105161 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102d60:	6a 02                	push   $0x2
f0102d62:	68 00 10 00 00       	push   $0x1000
f0102d67:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102d6a:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0102d70:	ff 30                	pushl  (%eax)
f0102d72:	e8 e8 e5 ff ff       	call   f010135f <page_insert>
	assert(pp1->pp_ref == 1);
f0102d77:	83 c4 20             	add    $0x20,%esp
f0102d7a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d7d:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102d82:	0f 85 ba 01 00 00    	jne    f0102f42 <mem_init+0x1b55>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102d88:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102d8f:	01 01 01 
f0102d92:	0f 85 c9 01 00 00    	jne    f0102f61 <mem_init+0x1b74>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102d98:	6a 02                	push   $0x2
f0102d9a:	68 00 10 00 00       	push   $0x1000
f0102d9f:	57                   	push   %edi
f0102da0:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0102da6:	ff 30                	pushl  (%eax)
f0102da8:	e8 b2 e5 ff ff       	call   f010135f <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102dad:	83 c4 10             	add    $0x10,%esp
f0102db0:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102db7:	02 02 02 
f0102dba:	0f 85 c0 01 00 00    	jne    f0102f80 <mem_init+0x1b93>
	assert(pp2->pp_ref == 1);
f0102dc0:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102dc5:	0f 85 d4 01 00 00    	jne    f0102f9f <mem_init+0x1bb2>
	assert(pp1->pp_ref == 0);
f0102dcb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102dce:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102dd3:	0f 85 e5 01 00 00    	jne    f0102fbe <mem_init+0x1bd1>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102dd9:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102de0:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102de3:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f0102de9:	89 f9                	mov    %edi,%ecx
f0102deb:	2b 08                	sub    (%eax),%ecx
f0102ded:	89 c8                	mov    %ecx,%eax
f0102def:	c1 f8 03             	sar    $0x3,%eax
f0102df2:	89 c2                	mov    %eax,%edx
f0102df4:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102df7:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102dfc:	c7 c1 08 10 19 f0    	mov    $0xf0191008,%ecx
f0102e02:	3b 01                	cmp    (%ecx),%eax
f0102e04:	0f 83 d3 01 00 00    	jae    f0102fdd <mem_init+0x1bf0>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102e0a:	81 ba 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%edx)
f0102e11:	03 03 03 
f0102e14:	0f 85 d9 01 00 00    	jne    f0102ff3 <mem_init+0x1c06>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102e1a:	83 ec 08             	sub    $0x8,%esp
f0102e1d:	68 00 10 00 00       	push   $0x1000
f0102e22:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0102e28:	ff 30                	pushl  (%eax)
f0102e2a:	e8 ea e4 ff ff       	call   f0101319 <page_remove>
	assert(pp2->pp_ref == 0);
f0102e2f:	83 c4 10             	add    $0x10,%esp
f0102e32:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102e37:	0f 85 d5 01 00 00    	jne    f0103012 <mem_init+0x1c25>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102e3d:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f0102e43:	8b 08                	mov    (%eax),%ecx
f0102e45:	8b 11                	mov    (%ecx),%edx
f0102e47:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102e4d:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f0102e53:	89 f7                	mov    %esi,%edi
f0102e55:	2b 38                	sub    (%eax),%edi
f0102e57:	89 f8                	mov    %edi,%eax
f0102e59:	c1 f8 03             	sar    $0x3,%eax
f0102e5c:	c1 e0 0c             	shl    $0xc,%eax
f0102e5f:	39 c2                	cmp    %eax,%edx
f0102e61:	0f 85 ca 01 00 00    	jne    f0103031 <mem_init+0x1c44>
	kern_pgdir[0] = 0;
f0102e67:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102e6d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102e72:	0f 85 d8 01 00 00    	jne    f0103050 <mem_init+0x1c63>
	pp0->pp_ref = 0;
f0102e78:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102e7e:	83 ec 0c             	sub    $0xc,%esp
f0102e81:	56                   	push   %esi
f0102e82:	e8 9c e2 ff ff       	call   f0101123 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e87:	8d 83 7c 82 f7 ff    	lea    -0x87d84(%ebx),%eax
f0102e8d:	89 04 24             	mov    %eax,(%esp)
f0102e90:	e8 a3 0b 00 00       	call   f0103a38 <cprintf>
}
f0102e95:	83 c4 10             	add    $0x10,%esp
f0102e98:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e9b:	5b                   	pop    %ebx
f0102e9c:	5e                   	pop    %esi
f0102e9d:	5f                   	pop    %edi
f0102e9e:	5d                   	pop    %ebp
f0102e9f:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ea0:	50                   	push   %eax
f0102ea1:	8d 83 64 7c f7 ff    	lea    -0x8839c(%ebx),%eax
f0102ea7:	50                   	push   %eax
f0102ea8:	68 f1 00 00 00       	push   $0xf1
f0102ead:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102eb3:	50                   	push   %eax
f0102eb4:	e8 fc d1 ff ff       	call   f01000b5 <_panic>
	assert((pp0 = page_alloc(0)));
f0102eb9:	8d 83 ae 83 f7 ff    	lea    -0x87c52(%ebx),%eax
f0102ebf:	50                   	push   %eax
f0102ec0:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102ec6:	50                   	push   %eax
f0102ec7:	68 47 04 00 00       	push   $0x447
f0102ecc:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102ed2:	50                   	push   %eax
f0102ed3:	e8 dd d1 ff ff       	call   f01000b5 <_panic>
	assert((pp1 = page_alloc(0)));
f0102ed8:	8d 83 c4 83 f7 ff    	lea    -0x87c3c(%ebx),%eax
f0102ede:	50                   	push   %eax
f0102edf:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102ee5:	50                   	push   %eax
f0102ee6:	68 48 04 00 00       	push   $0x448
f0102eeb:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102ef1:	50                   	push   %eax
f0102ef2:	e8 be d1 ff ff       	call   f01000b5 <_panic>
	assert((pp2 = page_alloc(0)));
f0102ef7:	8d 83 da 83 f7 ff    	lea    -0x87c26(%ebx),%eax
f0102efd:	50                   	push   %eax
f0102efe:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102f04:	50                   	push   %eax
f0102f05:	68 49 04 00 00       	push   $0x449
f0102f0a:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102f10:	50                   	push   %eax
f0102f11:	e8 9f d1 ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f16:	52                   	push   %edx
f0102f17:	8d 83 b4 7a f7 ff    	lea    -0x8854c(%ebx),%eax
f0102f1d:	50                   	push   %eax
f0102f1e:	6a 56                	push   $0x56
f0102f20:	8d 83 e9 82 f7 ff    	lea    -0x87d17(%ebx),%eax
f0102f26:	50                   	push   %eax
f0102f27:	e8 89 d1 ff ff       	call   f01000b5 <_panic>
f0102f2c:	52                   	push   %edx
f0102f2d:	8d 83 b4 7a f7 ff    	lea    -0x8854c(%ebx),%eax
f0102f33:	50                   	push   %eax
f0102f34:	6a 56                	push   $0x56
f0102f36:	8d 83 e9 82 f7 ff    	lea    -0x87d17(%ebx),%eax
f0102f3c:	50                   	push   %eax
f0102f3d:	e8 73 d1 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 1);
f0102f42:	8d 83 ab 84 f7 ff    	lea    -0x87b55(%ebx),%eax
f0102f48:	50                   	push   %eax
f0102f49:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102f4f:	50                   	push   %eax
f0102f50:	68 4e 04 00 00       	push   $0x44e
f0102f55:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102f5b:	50                   	push   %eax
f0102f5c:	e8 54 d1 ff ff       	call   f01000b5 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102f61:	8d 83 08 82 f7 ff    	lea    -0x87df8(%ebx),%eax
f0102f67:	50                   	push   %eax
f0102f68:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102f6e:	50                   	push   %eax
f0102f6f:	68 4f 04 00 00       	push   $0x44f
f0102f74:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102f7a:	50                   	push   %eax
f0102f7b:	e8 35 d1 ff ff       	call   f01000b5 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102f80:	8d 83 2c 82 f7 ff    	lea    -0x87dd4(%ebx),%eax
f0102f86:	50                   	push   %eax
f0102f87:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102f8d:	50                   	push   %eax
f0102f8e:	68 51 04 00 00       	push   $0x451
f0102f93:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102f99:	50                   	push   %eax
f0102f9a:	e8 16 d1 ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 1);
f0102f9f:	8d 83 cd 84 f7 ff    	lea    -0x87b33(%ebx),%eax
f0102fa5:	50                   	push   %eax
f0102fa6:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102fac:	50                   	push   %eax
f0102fad:	68 52 04 00 00       	push   $0x452
f0102fb2:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102fb8:	50                   	push   %eax
f0102fb9:	e8 f7 d0 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 0);
f0102fbe:	8d 83 37 85 f7 ff    	lea    -0x87ac9(%ebx),%eax
f0102fc4:	50                   	push   %eax
f0102fc5:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0102fcb:	50                   	push   %eax
f0102fcc:	68 53 04 00 00       	push   $0x453
f0102fd1:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0102fd7:	50                   	push   %eax
f0102fd8:	e8 d8 d0 ff ff       	call   f01000b5 <_panic>
f0102fdd:	52                   	push   %edx
f0102fde:	8d 83 b4 7a f7 ff    	lea    -0x8854c(%ebx),%eax
f0102fe4:	50                   	push   %eax
f0102fe5:	6a 56                	push   $0x56
f0102fe7:	8d 83 e9 82 f7 ff    	lea    -0x87d17(%ebx),%eax
f0102fed:	50                   	push   %eax
f0102fee:	e8 c2 d0 ff ff       	call   f01000b5 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102ff3:	8d 83 50 82 f7 ff    	lea    -0x87db0(%ebx),%eax
f0102ff9:	50                   	push   %eax
f0102ffa:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0103000:	50                   	push   %eax
f0103001:	68 55 04 00 00       	push   $0x455
f0103006:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010300c:	50                   	push   %eax
f010300d:	e8 a3 d0 ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 0);
f0103012:	8d 83 05 85 f7 ff    	lea    -0x87afb(%ebx),%eax
f0103018:	50                   	push   %eax
f0103019:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f010301f:	50                   	push   %eax
f0103020:	68 57 04 00 00       	push   $0x457
f0103025:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010302b:	50                   	push   %eax
f010302c:	e8 84 d0 ff ff       	call   f01000b5 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103031:	8d 83 60 7d f7 ff    	lea    -0x882a0(%ebx),%eax
f0103037:	50                   	push   %eax
f0103038:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f010303e:	50                   	push   %eax
f010303f:	68 5a 04 00 00       	push   $0x45a
f0103044:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f010304a:	50                   	push   %eax
f010304b:	e8 65 d0 ff ff       	call   f01000b5 <_panic>
	assert(pp0->pp_ref == 1);
f0103050:	8d 83 bc 84 f7 ff    	lea    -0x87b44(%ebx),%eax
f0103056:	50                   	push   %eax
f0103057:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f010305d:	50                   	push   %eax
f010305e:	68 5c 04 00 00       	push   $0x45c
f0103063:	8d 83 dd 82 f7 ff    	lea    -0x87d23(%ebx),%eax
f0103069:	50                   	push   %eax
f010306a:	e8 46 d0 ff ff       	call   f01000b5 <_panic>

f010306f <tlb_invalidate>:
{
f010306f:	f3 0f 1e fb          	endbr32 
f0103073:	55                   	push   %ebp
f0103074:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0103076:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103079:	0f 01 38             	invlpg (%eax)
}
f010307c:	5d                   	pop    %ebp
f010307d:	c3                   	ret    

f010307e <user_mem_check>:
{
f010307e:	f3 0f 1e fb          	endbr32 
f0103082:	55                   	push   %ebp
f0103083:	89 e5                	mov    %esp,%ebp
f0103085:	57                   	push   %edi
f0103086:	56                   	push   %esi
f0103087:	53                   	push   %ebx
f0103088:	83 ec 2c             	sub    $0x2c,%esp
f010308b:	e8 c0 d6 ff ff       	call   f0100750 <__x86.get_pc_thunk.ax>
f0103090:	05 8c af 08 00       	add    $0x8af8c,%eax
f0103095:	89 45 cc             	mov    %eax,-0x34(%ebp)
	pde_t* pgdir = env->env_pgdir;
f0103098:	8b 45 08             	mov    0x8(%ebp),%eax
f010309b:	8b 78 5c             	mov    0x5c(%eax),%edi
	uintptr_t address = (uintptr_t)va;
f010309e:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030a1:	89 45 c8             	mov    %eax,-0x38(%ebp)
	perm = perm | PTE_U | PTE_P;
f01030a4:	8b 45 14             	mov    0x14(%ebp),%eax
f01030a7:	83 c8 05             	or     $0x5,%eax
f01030aa:	89 45 d0             	mov    %eax,-0x30(%ebp)
	pte_t* entry = NULL;
f01030ad:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	uintptr_t address = (uintptr_t)va;
f01030b4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	for(; address<(uintptr_t)(va+len);address+=PGSIZE)
f01030b7:	89 d8                	mov    %ebx,%eax
f01030b9:	03 45 10             	add    0x10(%ebp),%eax
f01030bc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		if(page_lookup(pgdir,(void*)address,&entry) == NULL)
f01030bf:	8d 75 e4             	lea    -0x1c(%ebp),%esi
	for(; address<(uintptr_t)(va+len);address+=PGSIZE)
f01030c2:	eb 06                	jmp    f01030ca <user_mem_check+0x4c>
f01030c4:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01030ca:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01030cd:	76 42                	jbe    f0103111 <user_mem_check+0x93>
		if(address>=ULIM)
f01030cf:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01030d5:	77 1c                	ja     f01030f3 <user_mem_check+0x75>
		if(page_lookup(pgdir,(void*)address,&entry) == NULL)
f01030d7:	83 ec 04             	sub    $0x4,%esp
f01030da:	56                   	push   %esi
f01030db:	53                   	push   %ebx
f01030dc:	57                   	push   %edi
f01030dd:	e8 b8 e1 ff ff       	call   f010129a <page_lookup>
f01030e2:	83 c4 10             	add    $0x10,%esp
f01030e5:	85 c0                	test   %eax,%eax
f01030e7:	74 0a                	je     f01030f3 <user_mem_check+0x75>
		if(!(*entry & perm))
f01030e9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030ec:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01030ef:	85 10                	test   %edx,(%eax)
f01030f1:	75 d1                	jne    f01030c4 <user_mem_check+0x46>
		user_mem_check_addr = (address == (uintptr_t)va ? address : ROUNDDOWN(address,PGSIZE));
f01030f3:	89 d8                	mov    %ebx,%eax
f01030f5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01030fa:	39 5d 0c             	cmp    %ebx,0xc(%ebp)
f01030fd:	0f 44 45 c8          	cmove  -0x38(%ebp),%eax
f0103101:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103104:	89 81 20 23 00 00    	mov    %eax,0x2320(%ecx)
		return -E_FAULT;
f010310a:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f010310f:	eb 05                	jmp    f0103116 <user_mem_check+0x98>
	return 0;
f0103111:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103116:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103119:	5b                   	pop    %ebx
f010311a:	5e                   	pop    %esi
f010311b:	5f                   	pop    %edi
f010311c:	5d                   	pop    %ebp
f010311d:	c3                   	ret    

f010311e <user_mem_assert>:
{
f010311e:	f3 0f 1e fb          	endbr32 
f0103122:	55                   	push   %ebp
f0103123:	89 e5                	mov    %esp,%ebp
f0103125:	56                   	push   %esi
f0103126:	53                   	push   %ebx
f0103127:	e8 47 d0 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f010312c:	81 c3 f0 ae 08 00    	add    $0x8aef0,%ebx
f0103132:	8b 75 08             	mov    0x8(%ebp),%esi
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0103135:	8b 45 14             	mov    0x14(%ebp),%eax
f0103138:	83 c8 04             	or     $0x4,%eax
f010313b:	50                   	push   %eax
f010313c:	ff 75 10             	pushl  0x10(%ebp)
f010313f:	ff 75 0c             	pushl  0xc(%ebp)
f0103142:	56                   	push   %esi
f0103143:	e8 36 ff ff ff       	call   f010307e <user_mem_check>
f0103148:	83 c4 10             	add    $0x10,%esp
f010314b:	85 c0                	test   %eax,%eax
f010314d:	78 07                	js     f0103156 <user_mem_assert+0x38>
}
f010314f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103152:	5b                   	pop    %ebx
f0103153:	5e                   	pop    %esi
f0103154:	5d                   	pop    %ebp
f0103155:	c3                   	ret    
		cprintf("[%08x] user_mem_check assertion failure for "
f0103156:	83 ec 04             	sub    $0x4,%esp
f0103159:	ff b3 20 23 00 00    	pushl  0x2320(%ebx)
f010315f:	ff 76 48             	pushl  0x48(%esi)
f0103162:	8d 83 a8 82 f7 ff    	lea    -0x87d58(%ebx),%eax
f0103168:	50                   	push   %eax
f0103169:	e8 ca 08 00 00       	call   f0103a38 <cprintf>
		env_destroy(env);	// may not return
f010316e:	89 34 24             	mov    %esi,(%esp)
f0103171:	e8 3c 07 00 00       	call   f01038b2 <env_destroy>
f0103176:	83 c4 10             	add    $0x10,%esp
}
f0103179:	eb d4                	jmp    f010314f <user_mem_assert+0x31>

f010317b <__x86.get_pc_thunk.dx>:
f010317b:	8b 14 24             	mov    (%esp),%edx
f010317e:	c3                   	ret    

f010317f <__x86.get_pc_thunk.cx>:
f010317f:	8b 0c 24             	mov    (%esp),%ecx
f0103182:	c3                   	ret    

f0103183 <__x86.get_pc_thunk.di>:
f0103183:	8b 3c 24             	mov    (%esp),%edi
f0103186:	c3                   	ret    

f0103187 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0103187:	55                   	push   %ebp
f0103188:	89 e5                	mov    %esp,%ebp
f010318a:	57                   	push   %edi
f010318b:	56                   	push   %esi
f010318c:	53                   	push   %ebx
f010318d:	83 ec 1c             	sub    $0x1c,%esp
f0103190:	e8 de cf ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103195:	81 c3 87 ae 08 00    	add    $0x8ae87,%ebx
f010319b:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void* start = (void*)ROUNDDOWN((uint32_t)va,PGSIZE);
f010319d:	89 d6                	mov    %edx,%esi
f010319f:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	void* end = (void*)ROUNDUP((uint32_t)va+len,PGSIZE);
f01031a5:	8d 84 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%eax
f01031ac:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01031b1:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	// corner case 1: too large length
	if(start>end)
f01031b4:	39 c6                	cmp    %eax,%esi
f01031b6:	77 31                	ja     f01031e9 <region_alloc+0x62>
		panic("At region_alloc: too large length\n");
	}
	struct PageInfo* p = NULL;

	// allocate PA by the size of a page
	for(void* v = start;v<end;v+=PGSIZE)
f01031b8:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f01031bb:	73 7d                	jae    f010323a <region_alloc+0xb3>
	{
		p = page_alloc(0);
f01031bd:	83 ec 0c             	sub    $0xc,%esp
f01031c0:	6a 00                	push   $0x0
f01031c2:	e8 cd de ff ff       	call   f0101094 <page_alloc>
		// corner case 2: page allocation failed
		if(p == NULL)
f01031c7:	83 c4 10             	add    $0x10,%esp
f01031ca:	85 c0                	test   %eax,%eax
f01031cc:	74 36                	je     f0103204 <region_alloc+0x7d>
		{
			panic("At region_alloc: Page allocation failed");
		}

		// insert into page table
		int insert = page_insert(e->env_pgdir,p,v,PTE_W|PTE_U);
f01031ce:	6a 06                	push   $0x6
f01031d0:	56                   	push   %esi
f01031d1:	50                   	push   %eax
f01031d2:	ff 77 5c             	pushl  0x5c(%edi)
f01031d5:	e8 85 e1 ff ff       	call   f010135f <page_insert>

		// corner case 3: insertion failed
		if(insert!=0)
f01031da:	83 c4 10             	add    $0x10,%esp
f01031dd:	85 c0                	test   %eax,%eax
f01031df:	75 3e                	jne    f010321f <region_alloc+0x98>
	for(void* v = start;v<end;v+=PGSIZE)
f01031e1:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01031e7:	eb cf                	jmp    f01031b8 <region_alloc+0x31>
		panic("At region_alloc: too large length\n");
f01031e9:	83 ec 04             	sub    $0x4,%esp
f01031ec:	8d 83 c0 85 f7 ff    	lea    -0x87a40(%ebx),%eax
f01031f2:	50                   	push   %eax
f01031f3:	68 2b 01 00 00       	push   $0x12b
f01031f8:	8d 83 ee 86 f7 ff    	lea    -0x87912(%ebx),%eax
f01031fe:	50                   	push   %eax
f01031ff:	e8 b1 ce ff ff       	call   f01000b5 <_panic>
			panic("At region_alloc: Page allocation failed");
f0103204:	83 ec 04             	sub    $0x4,%esp
f0103207:	8d 83 e4 85 f7 ff    	lea    -0x87a1c(%ebx),%eax
f010320d:	50                   	push   %eax
f010320e:	68 36 01 00 00       	push   $0x136
f0103213:	8d 83 ee 86 f7 ff    	lea    -0x87912(%ebx),%eax
f0103219:	50                   	push   %eax
f010321a:	e8 96 ce ff ff       	call   f01000b5 <_panic>
		{
			panic("At region_alloc: Page insertion failed");
f010321f:	83 ec 04             	sub    $0x4,%esp
f0103222:	8d 83 0c 86 f7 ff    	lea    -0x879f4(%ebx),%eax
f0103228:	50                   	push   %eax
f0103229:	68 3f 01 00 00       	push   $0x13f
f010322e:	8d 83 ee 86 f7 ff    	lea    -0x87912(%ebx),%eax
f0103234:	50                   	push   %eax
f0103235:	e8 7b ce ff ff       	call   f01000b5 <_panic>
		}
	}
}
f010323a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010323d:	5b                   	pop    %ebx
f010323e:	5e                   	pop    %esi
f010323f:	5f                   	pop    %edi
f0103240:	5d                   	pop    %ebp
f0103241:	c3                   	ret    

f0103242 <envid2env>:
{
f0103242:	f3 0f 1e fb          	endbr32 
f0103246:	55                   	push   %ebp
f0103247:	89 e5                	mov    %esp,%ebp
f0103249:	53                   	push   %ebx
f010324a:	e8 30 ff ff ff       	call   f010317f <__x86.get_pc_thunk.cx>
f010324f:	81 c1 cd ad 08 00    	add    $0x8adcd,%ecx
f0103255:	8b 45 08             	mov    0x8(%ebp),%eax
f0103258:	8b 5d 10             	mov    0x10(%ebp),%ebx
	if (envid == 0) {
f010325b:	85 c0                	test   %eax,%eax
f010325d:	74 42                	je     f01032a1 <envid2env+0x5f>
	e = &envs[ENVX(envid)];
f010325f:	89 c2                	mov    %eax,%edx
f0103261:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0103267:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010326a:	c1 e2 05             	shl    $0x5,%edx
f010326d:	03 91 30 23 00 00    	add    0x2330(%ecx),%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103273:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0103277:	74 35                	je     f01032ae <envid2env+0x6c>
f0103279:	39 42 48             	cmp    %eax,0x48(%edx)
f010327c:	75 30                	jne    f01032ae <envid2env+0x6c>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010327e:	84 db                	test   %bl,%bl
f0103280:	74 12                	je     f0103294 <envid2env+0x52>
f0103282:	8b 81 2c 23 00 00    	mov    0x232c(%ecx),%eax
f0103288:	39 d0                	cmp    %edx,%eax
f010328a:	74 08                	je     f0103294 <envid2env+0x52>
f010328c:	8b 40 48             	mov    0x48(%eax),%eax
f010328f:	39 42 4c             	cmp    %eax,0x4c(%edx)
f0103292:	75 2a                	jne    f01032be <envid2env+0x7c>
	*env_store = e;
f0103294:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103297:	89 10                	mov    %edx,(%eax)
	return 0;
f0103299:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010329e:	5b                   	pop    %ebx
f010329f:	5d                   	pop    %ebp
f01032a0:	c3                   	ret    
		*env_store = curenv;
f01032a1:	8b 91 2c 23 00 00    	mov    0x232c(%ecx),%edx
f01032a7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01032aa:	89 13                	mov    %edx,(%ebx)
		return 0;
f01032ac:	eb f0                	jmp    f010329e <envid2env+0x5c>
		*env_store = 0;
f01032ae:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032b1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01032b7:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01032bc:	eb e0                	jmp    f010329e <envid2env+0x5c>
		*env_store = 0;
f01032be:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032c1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01032c7:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01032cc:	eb d0                	jmp    f010329e <envid2env+0x5c>

f01032ce <env_init_percpu>:
{
f01032ce:	f3 0f 1e fb          	endbr32 
f01032d2:	e8 79 d4 ff ff       	call   f0100750 <__x86.get_pc_thunk.ax>
f01032d7:	05 45 ad 08 00       	add    $0x8ad45,%eax
	asm volatile("lgdt (%0)" : : "r" (p));
f01032dc:	8d 80 e4 1f 00 00    	lea    0x1fe4(%eax),%eax
f01032e2:	0f 01 10             	lgdtl  (%eax)
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f01032e5:	b8 23 00 00 00       	mov    $0x23,%eax
f01032ea:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f01032ec:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f01032ee:	b8 10 00 00 00       	mov    $0x10,%eax
f01032f3:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f01032f5:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f01032f7:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f01032f9:	ea 00 33 10 f0 08 00 	ljmp   $0x8,$0xf0103300
	asm volatile("lldt %0" : : "r" (sel));
f0103300:	b8 00 00 00 00       	mov    $0x0,%eax
f0103305:	0f 00 d0             	lldt   %ax
}
f0103308:	c3                   	ret    

f0103309 <env_init>:
{
f0103309:	f3 0f 1e fb          	endbr32 
f010330d:	55                   	push   %ebp
f010330e:	89 e5                	mov    %esp,%ebp
f0103310:	57                   	push   %edi
f0103311:	56                   	push   %esi
f0103312:	53                   	push   %ebx
f0103313:	83 ec 0c             	sub    $0xc,%esp
f0103316:	e8 68 fe ff ff       	call   f0103183 <__x86.get_pc_thunk.di>
f010331b:	81 c7 01 ad 08 00    	add    $0x8ad01,%edi
		envs[i].env_id = 0;
f0103321:	8b b7 30 23 00 00    	mov    0x2330(%edi),%esi
f0103327:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f010332d:	89 f3                	mov    %esi,%ebx
f010332f:	ba 00 00 00 00       	mov    $0x0,%edx
f0103334:	89 d1                	mov    %edx,%ecx
f0103336:	89 c2                	mov    %eax,%edx
f0103338:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f010333f:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f0103346:	89 48 44             	mov    %ecx,0x44(%eax)
f0103349:	83 e8 60             	sub    $0x60,%eax
	for(int i = NENV - 1; i>=0 ;i--)
f010334c:	39 da                	cmp    %ebx,%edx
f010334e:	75 e4                	jne    f0103334 <env_init+0x2b>
f0103350:	89 b7 34 23 00 00    	mov    %esi,0x2334(%edi)
	env_init_percpu();
f0103356:	e8 73 ff ff ff       	call   f01032ce <env_init_percpu>
}
f010335b:	83 c4 0c             	add    $0xc,%esp
f010335e:	5b                   	pop    %ebx
f010335f:	5e                   	pop    %esi
f0103360:	5f                   	pop    %edi
f0103361:	5d                   	pop    %ebp
f0103362:	c3                   	ret    

f0103363 <env_alloc>:
{
f0103363:	f3 0f 1e fb          	endbr32 
f0103367:	55                   	push   %ebp
f0103368:	89 e5                	mov    %esp,%ebp
f010336a:	57                   	push   %edi
f010336b:	56                   	push   %esi
f010336c:	53                   	push   %ebx
f010336d:	83 ec 0c             	sub    $0xc,%esp
f0103370:	e8 fe cd ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103375:	81 c3 a7 ac 08 00    	add    $0x8aca7,%ebx
	if (!(e = env_free_list))
f010337b:	8b b3 34 23 00 00    	mov    0x2334(%ebx),%esi
f0103381:	85 f6                	test   %esi,%esi
f0103383:	0f 84 84 01 00 00    	je     f010350d <env_alloc+0x1aa>
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103389:	83 ec 0c             	sub    $0xc,%esp
f010338c:	6a 01                	push   $0x1
f010338e:	e8 01 dd ff ff       	call   f0101094 <page_alloc>
f0103393:	83 c4 10             	add    $0x10,%esp
f0103396:	85 c0                	test   %eax,%eax
f0103398:	0f 84 76 01 00 00    	je     f0103514 <env_alloc+0x1b1>
	return (pp - pages) << PGSHIFT;
f010339e:	c7 c2 10 10 19 f0    	mov    $0xf0191010,%edx
f01033a4:	89 c7                	mov    %eax,%edi
f01033a6:	2b 3a                	sub    (%edx),%edi
f01033a8:	89 fa                	mov    %edi,%edx
f01033aa:	c1 fa 03             	sar    $0x3,%edx
f01033ad:	89 d1                	mov    %edx,%ecx
f01033af:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f01033b2:	81 e2 ff ff 0f 00    	and    $0xfffff,%edx
f01033b8:	c7 c7 08 10 19 f0    	mov    $0xf0191008,%edi
f01033be:	3b 17                	cmp    (%edi),%edx
f01033c0:	0f 83 18 01 00 00    	jae    f01034de <env_alloc+0x17b>
	return (void *)(pa + KERNBASE);
f01033c6:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f01033cc:	89 4e 5c             	mov    %ecx,0x5c(%esi)
	p->pp_ref++;
f01033cf:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f01033d4:	b8 00 00 00 00       	mov    $0x0,%eax
		e->env_pgdir[i] = 0;
f01033d9:	8b 56 5c             	mov    0x5c(%esi),%edx
f01033dc:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f01033e3:	83 c0 04             	add    $0x4,%eax
	for(int i = 0;i<PDX(UTOP);i++)
f01033e6:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f01033eb:	75 ec                	jne    f01033d9 <env_alloc+0x76>
		e->env_pgdir[i] = kern_pgdir[i];
f01033ed:	c7 c7 0c 10 19 f0    	mov    $0xf019100c,%edi
f01033f3:	8b 17                	mov    (%edi),%edx
f01033f5:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f01033f8:	8b 56 5c             	mov    0x5c(%esi),%edx
f01033fb:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f01033fe:	83 c0 04             	add    $0x4,%eax
	for(int i = PDX(UTOP);i<NPDENTRIES;i++)
f0103401:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0103406:	75 eb                	jne    f01033f3 <env_alloc+0x90>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103408:	8b 46 5c             	mov    0x5c(%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f010340b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103410:	0f 86 de 00 00 00    	jbe    f01034f4 <env_alloc+0x191>
	return (physaddr_t)kva - KERNBASE;
f0103416:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010341c:	83 ca 05             	or     $0x5,%edx
f010341f:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0103425:	8b 46 48             	mov    0x48(%esi),%eax
f0103428:	05 00 10 00 00       	add    $0x1000,%eax
		generation = 1 << ENVGENSHIFT;
f010342d:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0103432:	ba 00 10 00 00       	mov    $0x1000,%edx
f0103437:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f010343a:	89 f2                	mov    %esi,%edx
f010343c:	2b 93 30 23 00 00    	sub    0x2330(%ebx),%edx
f0103442:	c1 fa 05             	sar    $0x5,%edx
f0103445:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010344b:	09 d0                	or     %edx,%eax
f010344d:	89 46 48             	mov    %eax,0x48(%esi)
	e->env_parent_id = parent_id;
f0103450:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103453:	89 46 4c             	mov    %eax,0x4c(%esi)
	e->env_type = ENV_TYPE_USER;
f0103456:	c7 46 50 00 00 00 00 	movl   $0x0,0x50(%esi)
	e->env_status = ENV_RUNNABLE;
f010345d:	c7 46 54 02 00 00 00 	movl   $0x2,0x54(%esi)
	e->env_runs = 0;
f0103464:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010346b:	83 ec 04             	sub    $0x4,%esp
f010346e:	6a 44                	push   $0x44
f0103470:	6a 00                	push   $0x0
f0103472:	56                   	push   %esi
f0103473:	e8 e9 1c 00 00       	call   f0105161 <memset>
	e->env_tf.tf_ds = GD_UD | 3;
f0103478:	66 c7 46 24 23 00    	movw   $0x23,0x24(%esi)
	e->env_tf.tf_es = GD_UD | 3;
f010347e:	66 c7 46 20 23 00    	movw   $0x23,0x20(%esi)
	e->env_tf.tf_ss = GD_UD | 3;
f0103484:	66 c7 46 40 23 00    	movw   $0x23,0x40(%esi)
	e->env_tf.tf_esp = USTACKTOP;
f010348a:	c7 46 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%esi)
	e->env_tf.tf_cs = GD_UT | 3;
f0103491:	66 c7 46 34 1b 00    	movw   $0x1b,0x34(%esi)
	env_free_list = e->env_link;
f0103497:	8b 46 44             	mov    0x44(%esi),%eax
f010349a:	89 83 34 23 00 00    	mov    %eax,0x2334(%ebx)
	*newenv_store = e;
f01034a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01034a3:	89 30                	mov    %esi,(%eax)
	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01034a5:	8b 4e 48             	mov    0x48(%esi),%ecx
f01034a8:	8b 83 2c 23 00 00    	mov    0x232c(%ebx),%eax
f01034ae:	83 c4 10             	add    $0x10,%esp
f01034b1:	ba 00 00 00 00       	mov    $0x0,%edx
f01034b6:	85 c0                	test   %eax,%eax
f01034b8:	74 03                	je     f01034bd <env_alloc+0x15a>
f01034ba:	8b 50 48             	mov    0x48(%eax),%edx
f01034bd:	83 ec 04             	sub    $0x4,%esp
f01034c0:	51                   	push   %ecx
f01034c1:	52                   	push   %edx
f01034c2:	8d 83 f9 86 f7 ff    	lea    -0x87907(%ebx),%eax
f01034c8:	50                   	push   %eax
f01034c9:	e8 6a 05 00 00       	call   f0103a38 <cprintf>
	return 0;
f01034ce:	83 c4 10             	add    $0x10,%esp
f01034d1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01034d6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01034d9:	5b                   	pop    %ebx
f01034da:	5e                   	pop    %esi
f01034db:	5f                   	pop    %edi
f01034dc:	5d                   	pop    %ebp
f01034dd:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01034de:	51                   	push   %ecx
f01034df:	8d 83 b4 7a f7 ff    	lea    -0x8854c(%ebx),%eax
f01034e5:	50                   	push   %eax
f01034e6:	6a 56                	push   $0x56
f01034e8:	8d 83 e9 82 f7 ff    	lea    -0x87d17(%ebx),%eax
f01034ee:	50                   	push   %eax
f01034ef:	e8 c1 cb ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034f4:	50                   	push   %eax
f01034f5:	8d 83 64 7c f7 ff    	lea    -0x8839c(%ebx),%eax
f01034fb:	50                   	push   %eax
f01034fc:	68 d0 00 00 00       	push   $0xd0
f0103501:	8d 83 ee 86 f7 ff    	lea    -0x87912(%ebx),%eax
f0103507:	50                   	push   %eax
f0103508:	e8 a8 cb ff ff       	call   f01000b5 <_panic>
		return -E_NO_FREE_ENV;
f010350d:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103512:	eb c2                	jmp    f01034d6 <env_alloc+0x173>
		return -E_NO_MEM;
f0103514:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0103519:	eb bb                	jmp    f01034d6 <env_alloc+0x173>

f010351b <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010351b:	f3 0f 1e fb          	endbr32 
f010351f:	55                   	push   %ebp
f0103520:	89 e5                	mov    %esp,%ebp
f0103522:	57                   	push   %edi
f0103523:	56                   	push   %esi
f0103524:	53                   	push   %ebx
f0103525:	83 ec 34             	sub    $0x34,%esp
f0103528:	e8 46 cc ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f010352d:	81 c3 ef aa 08 00    	add    $0x8aaef,%ebx
f0103533:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env* e;
	int alloc = env_alloc(&e,0);
f0103536:	6a 00                	push   $0x0
f0103538:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010353b:	50                   	push   %eax
f010353c:	e8 22 fe ff ff       	call   f0103363 <env_alloc>
	if(alloc != 0)
f0103541:	83 c4 10             	add    $0x10,%esp
f0103544:	85 c0                	test   %eax,%eax
f0103546:	75 36                	jne    f010357e <env_create+0x63>
	{
		panic("At env_create: env_alloc() failed");
	}
	load_icode(e,binary);
f0103548:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010354b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if(elfHeader->e_magic != ELF_MAGIC)
f010354e:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103554:	75 43                	jne    f0103599 <env_create+0x7e>
	lcr3(PADDR(e->env_pgdir));
f0103556:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103559:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010355c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103561:	76 51                	jbe    f01035b4 <env_create+0x99>
	return (physaddr_t)kva - KERNBASE;
f0103563:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103568:	0f 22 d8             	mov    %eax,%cr3
	struct Proghdr* ph = (struct Proghdr*)(binary+elfHeader->e_phoff);
f010356b:	89 fe                	mov    %edi,%esi
f010356d:	03 77 1c             	add    0x1c(%edi),%esi
	struct Proghdr* phEnd = ph+elfHeader->e_phnum;
f0103570:	0f b7 47 2c          	movzwl 0x2c(%edi),%eax
f0103574:	c1 e0 05             	shl    $0x5,%eax
f0103577:	01 f0                	add    %esi,%eax
f0103579:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for(;ph<phEnd;ph++)
f010357c:	eb 6d                	jmp    f01035eb <env_create+0xd0>
		panic("At env_create: env_alloc() failed");
f010357e:	83 ec 04             	sub    $0x4,%esp
f0103581:	8d 83 34 86 f7 ff    	lea    -0x879cc(%ebx),%eax
f0103587:	50                   	push   %eax
f0103588:	68 b8 01 00 00       	push   $0x1b8
f010358d:	8d 83 ee 86 f7 ff    	lea    -0x87912(%ebx),%eax
f0103593:	50                   	push   %eax
f0103594:	e8 1c cb ff ff       	call   f01000b5 <_panic>
		panic("At load_icode: Invalid head magic number");
f0103599:	83 ec 04             	sub    $0x4,%esp
f010359c:	8d 83 58 86 f7 ff    	lea    -0x879a8(%ebx),%eax
f01035a2:	50                   	push   %eax
f01035a3:	68 80 01 00 00       	push   $0x180
f01035a8:	8d 83 ee 86 f7 ff    	lea    -0x87912(%ebx),%eax
f01035ae:	50                   	push   %eax
f01035af:	e8 01 cb ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01035b4:	50                   	push   %eax
f01035b5:	8d 83 64 7c f7 ff    	lea    -0x8839c(%ebx),%eax
f01035bb:	50                   	push   %eax
f01035bc:	68 83 01 00 00       	push   $0x183
f01035c1:	8d 83 ee 86 f7 ff    	lea    -0x87912(%ebx),%eax
f01035c7:	50                   	push   %eax
f01035c8:	e8 e8 ca ff ff       	call   f01000b5 <_panic>
				panic("At load_icode: file size bigger than memory size");
f01035cd:	83 ec 04             	sub    $0x4,%esp
f01035d0:	8d 83 84 86 f7 ff    	lea    -0x8797c(%ebx),%eax
f01035d6:	50                   	push   %eax
f01035d7:	68 8f 01 00 00       	push   $0x18f
f01035dc:	8d 83 ee 86 f7 ff    	lea    -0x87912(%ebx),%eax
f01035e2:	50                   	push   %eax
f01035e3:	e8 cd ca ff ff       	call   f01000b5 <_panic>
	for(;ph<phEnd;ph++)
f01035e8:	83 c6 20             	add    $0x20,%esi
f01035eb:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f01035ee:	76 48                	jbe    f0103638 <env_create+0x11d>
		if(ph->p_type == ELF_PROG_LOAD)
f01035f0:	83 3e 01             	cmpl   $0x1,(%esi)
f01035f3:	75 f3                	jne    f01035e8 <env_create+0xcd>
			if(ph->p_filesz>ph->p_memsz)
f01035f5:	8b 4e 14             	mov    0x14(%esi),%ecx
f01035f8:	39 4e 10             	cmp    %ecx,0x10(%esi)
f01035fb:	77 d0                	ja     f01035cd <env_create+0xb2>
			region_alloc(e,(void*) ph->p_va,ph->p_memsz);
f01035fd:	8b 56 08             	mov    0x8(%esi),%edx
f0103600:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103603:	e8 7f fb ff ff       	call   f0103187 <region_alloc>
			memcpy((void*)ph->p_va,binary+ph->p_offset,ph->p_filesz);
f0103608:	83 ec 04             	sub    $0x4,%esp
f010360b:	ff 76 10             	pushl  0x10(%esi)
f010360e:	89 f8                	mov    %edi,%eax
f0103610:	03 46 04             	add    0x4(%esi),%eax
f0103613:	50                   	push   %eax
f0103614:	ff 76 08             	pushl  0x8(%esi)
f0103617:	e8 f7 1b 00 00       	call   f0105213 <memcpy>
			memset((void*)(ph->p_va+ph->p_filesz),0,ph->p_memsz-ph->p_filesz);
f010361c:	8b 46 10             	mov    0x10(%esi),%eax
f010361f:	83 c4 0c             	add    $0xc,%esp
f0103622:	8b 56 14             	mov    0x14(%esi),%edx
f0103625:	29 c2                	sub    %eax,%edx
f0103627:	52                   	push   %edx
f0103628:	6a 00                	push   $0x0
f010362a:	03 46 08             	add    0x8(%esi),%eax
f010362d:	50                   	push   %eax
f010362e:	e8 2e 1b 00 00       	call   f0105161 <memset>
f0103633:	83 c4 10             	add    $0x10,%esp
f0103636:	eb b0                	jmp    f01035e8 <env_create+0xcd>
	lcr3(PADDR(kern_pgdir));
f0103638:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f010363e:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103640:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103645:	76 3a                	jbe    f0103681 <env_create+0x166>
	return (physaddr_t)kva - KERNBASE;
f0103647:	05 00 00 00 10       	add    $0x10000000,%eax
f010364c:	0f 22 d8             	mov    %eax,%cr3
	e->env_status = ENV_RUNNABLE;
f010364f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103652:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_tf.tf_eip = elfHeader->e_entry;
f0103659:	8b 47 18             	mov    0x18(%edi),%eax
f010365c:	89 43 30             	mov    %eax,0x30(%ebx)
	region_alloc(e,(void*)(USTACKTOP-PGSIZE),PGSIZE);
f010365f:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103664:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103669:	89 d8                	mov    %ebx,%eax
f010366b:	e8 17 fb ff ff       	call   f0103187 <region_alloc>
	e->env_type = type;
f0103670:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103673:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103676:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103679:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010367c:	5b                   	pop    %ebx
f010367d:	5e                   	pop    %esi
f010367e:	5f                   	pop    %edi
f010367f:	5d                   	pop    %ebp
f0103680:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103681:	50                   	push   %eax
f0103682:	8d 83 64 7c f7 ff    	lea    -0x8839c(%ebx),%eax
f0103688:	50                   	push   %eax
f0103689:	68 9c 01 00 00       	push   $0x19c
f010368e:	8d 83 ee 86 f7 ff    	lea    -0x87912(%ebx),%eax
f0103694:	50                   	push   %eax
f0103695:	e8 1b ca ff ff       	call   f01000b5 <_panic>

f010369a <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f010369a:	f3 0f 1e fb          	endbr32 
f010369e:	55                   	push   %ebp
f010369f:	89 e5                	mov    %esp,%ebp
f01036a1:	57                   	push   %edi
f01036a2:	56                   	push   %esi
f01036a3:	53                   	push   %ebx
f01036a4:	83 ec 2c             	sub    $0x2c,%esp
f01036a7:	e8 c7 ca ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01036ac:	81 c3 70 a9 08 00    	add    $0x8a970,%ebx
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01036b2:	8b 93 2c 23 00 00    	mov    0x232c(%ebx),%edx
f01036b8:	3b 55 08             	cmp    0x8(%ebp),%edx
f01036bb:	74 47                	je     f0103704 <env_free+0x6a>
		lcr3(PADDR(kern_pgdir));

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01036bd:	8b 45 08             	mov    0x8(%ebp),%eax
f01036c0:	8b 48 48             	mov    0x48(%eax),%ecx
f01036c3:	b8 00 00 00 00       	mov    $0x0,%eax
f01036c8:	85 d2                	test   %edx,%edx
f01036ca:	74 03                	je     f01036cf <env_free+0x35>
f01036cc:	8b 42 48             	mov    0x48(%edx),%eax
f01036cf:	83 ec 04             	sub    $0x4,%esp
f01036d2:	51                   	push   %ecx
f01036d3:	50                   	push   %eax
f01036d4:	8d 83 0e 87 f7 ff    	lea    -0x878f2(%ebx),%eax
f01036da:	50                   	push   %eax
f01036db:	e8 58 03 00 00       	call   f0103a38 <cprintf>
f01036e0:	83 c4 10             	add    $0x10,%esp
f01036e3:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	if (PGNUM(pa) >= npages)
f01036ea:	c7 c0 08 10 19 f0    	mov    $0xf0191008,%eax
f01036f0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	if (PGNUM(pa) >= npages)
f01036f3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	return &pages[PGNUM(pa)];
f01036f6:	c7 c0 10 10 19 f0    	mov    $0xf0191010,%eax
f01036fc:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01036ff:	e9 bf 00 00 00       	jmp    f01037c3 <env_free+0x129>
		lcr3(PADDR(kern_pgdir));
f0103704:	c7 c0 0c 10 19 f0    	mov    $0xf019100c,%eax
f010370a:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010370c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103711:	76 10                	jbe    f0103723 <env_free+0x89>
	return (physaddr_t)kva - KERNBASE;
f0103713:	05 00 00 00 10       	add    $0x10000000,%eax
f0103718:	0f 22 d8             	mov    %eax,%cr3
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010371b:	8b 45 08             	mov    0x8(%ebp),%eax
f010371e:	8b 48 48             	mov    0x48(%eax),%ecx
f0103721:	eb a9                	jmp    f01036cc <env_free+0x32>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103723:	50                   	push   %eax
f0103724:	8d 83 64 7c f7 ff    	lea    -0x8839c(%ebx),%eax
f010372a:	50                   	push   %eax
f010372b:	68 cc 01 00 00       	push   $0x1cc
f0103730:	8d 83 ee 86 f7 ff    	lea    -0x87912(%ebx),%eax
f0103736:	50                   	push   %eax
f0103737:	e8 79 c9 ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010373c:	57                   	push   %edi
f010373d:	8d 83 b4 7a f7 ff    	lea    -0x8854c(%ebx),%eax
f0103743:	50                   	push   %eax
f0103744:	68 db 01 00 00       	push   $0x1db
f0103749:	8d 83 ee 86 f7 ff    	lea    -0x87912(%ebx),%eax
f010374f:	50                   	push   %eax
f0103750:	e8 60 c9 ff ff       	call   f01000b5 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103755:	83 ec 08             	sub    $0x8,%esp
f0103758:	89 f0                	mov    %esi,%eax
f010375a:	c1 e0 0c             	shl    $0xc,%eax
f010375d:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103760:	50                   	push   %eax
f0103761:	8b 45 08             	mov    0x8(%ebp),%eax
f0103764:	ff 70 5c             	pushl  0x5c(%eax)
f0103767:	e8 ad db ff ff       	call   f0101319 <page_remove>
f010376c:	83 c4 10             	add    $0x10,%esp
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010376f:	83 c6 01             	add    $0x1,%esi
f0103772:	83 c7 04             	add    $0x4,%edi
f0103775:	81 fe 00 04 00 00    	cmp    $0x400,%esi
f010377b:	74 07                	je     f0103784 <env_free+0xea>
			if (pt[pteno] & PTE_P)
f010377d:	f6 07 01             	testb  $0x1,(%edi)
f0103780:	74 ed                	je     f010376f <env_free+0xd5>
f0103782:	eb d1                	jmp    f0103755 <env_free+0xbb>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103784:	8b 45 08             	mov    0x8(%ebp),%eax
f0103787:	8b 40 5c             	mov    0x5c(%eax),%eax
f010378a:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010378d:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f0103794:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103797:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010379a:	3b 10                	cmp    (%eax),%edx
f010379c:	73 67                	jae    f0103805 <env_free+0x16b>
		page_decref(pa2page(pa));
f010379e:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01037a1:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01037a4:	8b 00                	mov    (%eax),%eax
f01037a6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01037a9:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01037ac:	50                   	push   %eax
f01037ad:	e8 c4 d9 ff ff       	call   f0101176 <page_decref>
f01037b2:	83 c4 10             	add    $0x10,%esp
f01037b5:	83 45 e0 04          	addl   $0x4,-0x20(%ebp)
f01037b9:	8b 45 e0             	mov    -0x20(%ebp),%eax
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01037bc:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f01037c1:	74 5a                	je     f010381d <env_free+0x183>
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01037c3:	8b 45 08             	mov    0x8(%ebp),%eax
f01037c6:	8b 40 5c             	mov    0x5c(%eax),%eax
f01037c9:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01037cc:	8b 04 10             	mov    (%eax,%edx,1),%eax
f01037cf:	a8 01                	test   $0x1,%al
f01037d1:	74 e2                	je     f01037b5 <env_free+0x11b>
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01037d3:	89 c7                	mov    %eax,%edi
f01037d5:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	if (PGNUM(pa) >= npages)
f01037db:	c1 e8 0c             	shr    $0xc,%eax
f01037de:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01037e1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01037e4:	39 02                	cmp    %eax,(%edx)
f01037e6:	0f 86 50 ff ff ff    	jbe    f010373c <env_free+0xa2>
	return (void *)(pa + KERNBASE);
f01037ec:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
f01037f2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01037f5:	c1 e0 14             	shl    $0x14,%eax
f01037f8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01037fb:	be 00 00 00 00       	mov    $0x0,%esi
f0103800:	e9 78 ff ff ff       	jmp    f010377d <env_free+0xe3>
		panic("pa2page called with invalid pa");
f0103805:	83 ec 04             	sub    $0x4,%esp
f0103808:	8d 83 08 7c f7 ff    	lea    -0x883f8(%ebx),%eax
f010380e:	50                   	push   %eax
f010380f:	6a 4f                	push   $0x4f
f0103811:	8d 83 e9 82 f7 ff    	lea    -0x87d17(%ebx),%eax
f0103817:	50                   	push   %eax
f0103818:	e8 98 c8 ff ff       	call   f01000b5 <_panic>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f010381d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103820:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103823:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103828:	76 57                	jbe    f0103881 <env_free+0x1e7>
	e->env_pgdir = 0;
f010382a:	8b 55 08             	mov    0x8(%ebp),%edx
f010382d:	c7 42 5c 00 00 00 00 	movl   $0x0,0x5c(%edx)
	return (physaddr_t)kva - KERNBASE;
f0103834:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f0103839:	c1 e8 0c             	shr    $0xc,%eax
f010383c:	c7 c2 08 10 19 f0    	mov    $0xf0191008,%edx
f0103842:	3b 02                	cmp    (%edx),%eax
f0103844:	73 54                	jae    f010389a <env_free+0x200>
	page_decref(pa2page(pa));
f0103846:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103849:	c7 c2 10 10 19 f0    	mov    $0xf0191010,%edx
f010384f:	8b 12                	mov    (%edx),%edx
f0103851:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103854:	50                   	push   %eax
f0103855:	e8 1c d9 ff ff       	call   f0101176 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f010385a:	8b 45 08             	mov    0x8(%ebp),%eax
f010385d:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	e->env_link = env_free_list;
f0103864:	8b 83 34 23 00 00    	mov    0x2334(%ebx),%eax
f010386a:	8b 55 08             	mov    0x8(%ebp),%edx
f010386d:	89 42 44             	mov    %eax,0x44(%edx)
	env_free_list = e;
f0103870:	89 93 34 23 00 00    	mov    %edx,0x2334(%ebx)
}
f0103876:	83 c4 10             	add    $0x10,%esp
f0103879:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010387c:	5b                   	pop    %ebx
f010387d:	5e                   	pop    %esi
f010387e:	5f                   	pop    %edi
f010387f:	5d                   	pop    %ebp
f0103880:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103881:	50                   	push   %eax
f0103882:	8d 83 64 7c f7 ff    	lea    -0x8839c(%ebx),%eax
f0103888:	50                   	push   %eax
f0103889:	68 e9 01 00 00       	push   $0x1e9
f010388e:	8d 83 ee 86 f7 ff    	lea    -0x87912(%ebx),%eax
f0103894:	50                   	push   %eax
f0103895:	e8 1b c8 ff ff       	call   f01000b5 <_panic>
		panic("pa2page called with invalid pa");
f010389a:	83 ec 04             	sub    $0x4,%esp
f010389d:	8d 83 08 7c f7 ff    	lea    -0x883f8(%ebx),%eax
f01038a3:	50                   	push   %eax
f01038a4:	6a 4f                	push   $0x4f
f01038a6:	8d 83 e9 82 f7 ff    	lea    -0x87d17(%ebx),%eax
f01038ac:	50                   	push   %eax
f01038ad:	e8 03 c8 ff ff       	call   f01000b5 <_panic>

f01038b2 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f01038b2:	f3 0f 1e fb          	endbr32 
f01038b6:	55                   	push   %ebp
f01038b7:	89 e5                	mov    %esp,%ebp
f01038b9:	53                   	push   %ebx
f01038ba:	83 ec 10             	sub    $0x10,%esp
f01038bd:	e8 b1 c8 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01038c2:	81 c3 5a a7 08 00    	add    $0x8a75a,%ebx
	env_free(e);
f01038c8:	ff 75 08             	pushl  0x8(%ebp)
f01038cb:	e8 ca fd ff ff       	call   f010369a <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f01038d0:	8d 83 b8 86 f7 ff    	lea    -0x87948(%ebx),%eax
f01038d6:	89 04 24             	mov    %eax,(%esp)
f01038d9:	e8 5a 01 00 00       	call   f0103a38 <cprintf>
f01038de:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f01038e1:	83 ec 0c             	sub    $0xc,%esp
f01038e4:	6a 00                	push   $0x0
f01038e6:	e8 99 d0 ff ff       	call   f0100984 <monitor>
f01038eb:	83 c4 10             	add    $0x10,%esp
f01038ee:	eb f1                	jmp    f01038e1 <env_destroy+0x2f>

f01038f0 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01038f0:	f3 0f 1e fb          	endbr32 
f01038f4:	55                   	push   %ebp
f01038f5:	89 e5                	mov    %esp,%ebp
f01038f7:	53                   	push   %ebx
f01038f8:	83 ec 08             	sub    $0x8,%esp
f01038fb:	e8 73 c8 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103900:	81 c3 1c a7 08 00    	add    $0x8a71c,%ebx
	asm volatile(
f0103906:	8b 65 08             	mov    0x8(%ebp),%esp
f0103909:	61                   	popa   
f010390a:	07                   	pop    %es
f010390b:	1f                   	pop    %ds
f010390c:	83 c4 08             	add    $0x8,%esp
f010390f:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103910:	8d 83 24 87 f7 ff    	lea    -0x878dc(%ebx),%eax
f0103916:	50                   	push   %eax
f0103917:	68 12 02 00 00       	push   $0x212
f010391c:	8d 83 ee 86 f7 ff    	lea    -0x87912(%ebx),%eax
f0103922:	50                   	push   %eax
f0103923:	e8 8d c7 ff ff       	call   f01000b5 <_panic>

f0103928 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103928:	f3 0f 1e fb          	endbr32 
f010392c:	55                   	push   %ebp
f010392d:	89 e5                	mov    %esp,%ebp
f010392f:	53                   	push   %ebx
f0103930:	83 ec 04             	sub    $0x4,%esp
f0103933:	e8 3b c8 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103938:	81 c3 e4 a6 08 00    	add    $0x8a6e4,%ebx
f010393e:	8b 45 08             	mov    0x8(%ebp),%eax
	
	// panic("env_run not yet implemented");

	// step 1
	// set the env_status field
	if(curenv)
f0103941:	8b 93 2c 23 00 00    	mov    0x232c(%ebx),%edx
f0103947:	85 d2                	test   %edx,%edx
f0103949:	74 06                	je     f0103951 <env_run+0x29>
	{
		if(curenv->env_status == ENV_RUNNING)
f010394b:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f010394f:	74 2e                	je     f010397f <env_run+0x57>
			curenv->env_status = ENV_RUNNABLE;
		}
	}

	// switch to new environment
	curenv = e;
f0103951:	89 83 2c 23 00 00    	mov    %eax,0x232c(%ebx)
	curenv->env_status = ENV_RUNNING;
f0103957:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f010395e:	83 40 58 01          	addl   $0x1,0x58(%eax)
	// switch to user page directory
	lcr3(PADDR(curenv->env_pgdir));
f0103962:	8b 50 5c             	mov    0x5c(%eax),%edx
	if ((uint32_t)kva < KERNBASE)
f0103965:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f010396b:	76 1b                	jbe    f0103988 <env_run+0x60>
	return (physaddr_t)kva - KERNBASE;
f010396d:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103973:	0f 22 da             	mov    %edx,%cr3

	// step 2
	env_pop_tf(&curenv->env_tf);
f0103976:	83 ec 0c             	sub    $0xc,%esp
f0103979:	50                   	push   %eax
f010397a:	e8 71 ff ff ff       	call   f01038f0 <env_pop_tf>
			curenv->env_status = ENV_RUNNABLE;
f010397f:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
f0103986:	eb c9                	jmp    f0103951 <env_run+0x29>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103988:	52                   	push   %edx
f0103989:	8d 83 64 7c f7 ff    	lea    -0x8839c(%ebx),%eax
f010398f:	50                   	push   %eax
f0103990:	68 42 02 00 00       	push   $0x242
f0103995:	8d 83 ee 86 f7 ff    	lea    -0x87912(%ebx),%eax
f010399b:	50                   	push   %eax
f010399c:	e8 14 c7 ff ff       	call   f01000b5 <_panic>

f01039a1 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01039a1:	f3 0f 1e fb          	endbr32 
f01039a5:	55                   	push   %ebp
f01039a6:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01039a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01039ab:	ba 70 00 00 00       	mov    $0x70,%edx
f01039b0:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01039b1:	ba 71 00 00 00       	mov    $0x71,%edx
f01039b6:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01039b7:	0f b6 c0             	movzbl %al,%eax
}
f01039ba:	5d                   	pop    %ebp
f01039bb:	c3                   	ret    

f01039bc <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01039bc:	f3 0f 1e fb          	endbr32 
f01039c0:	55                   	push   %ebp
f01039c1:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01039c3:	8b 45 08             	mov    0x8(%ebp),%eax
f01039c6:	ba 70 00 00 00       	mov    $0x70,%edx
f01039cb:	ee                   	out    %al,(%dx)
f01039cc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039cf:	ba 71 00 00 00       	mov    $0x71,%edx
f01039d4:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01039d5:	5d                   	pop    %ebp
f01039d6:	c3                   	ret    

f01039d7 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01039d7:	f3 0f 1e fb          	endbr32 
f01039db:	55                   	push   %ebp
f01039dc:	89 e5                	mov    %esp,%ebp
f01039de:	53                   	push   %ebx
f01039df:	83 ec 10             	sub    $0x10,%esp
f01039e2:	e8 8c c7 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01039e7:	81 c3 35 a6 08 00    	add    $0x8a635,%ebx
	cputchar(ch);
f01039ed:	ff 75 08             	pushl  0x8(%ebp)
f01039f0:	e8 28 cd ff ff       	call   f010071d <cputchar>
	*cnt++;
}
f01039f5:	83 c4 10             	add    $0x10,%esp
f01039f8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01039fb:	c9                   	leave  
f01039fc:	c3                   	ret    

f01039fd <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01039fd:	f3 0f 1e fb          	endbr32 
f0103a01:	55                   	push   %ebp
f0103a02:	89 e5                	mov    %esp,%ebp
f0103a04:	53                   	push   %ebx
f0103a05:	83 ec 14             	sub    $0x14,%esp
f0103a08:	e8 66 c7 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103a0d:	81 c3 0f a6 08 00    	add    $0x8a60f,%ebx
	int cnt = 0;
f0103a13:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103a1a:	ff 75 0c             	pushl  0xc(%ebp)
f0103a1d:	ff 75 08             	pushl  0x8(%ebp)
f0103a20:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103a23:	50                   	push   %eax
f0103a24:	8d 83 bb 59 f7 ff    	lea    -0x8a645(%ebx),%eax
f0103a2a:	50                   	push   %eax
f0103a2b:	e8 45 0f 00 00       	call   f0104975 <vprintfmt>
	return cnt;
}
f0103a30:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103a33:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a36:	c9                   	leave  
f0103a37:	c3                   	ret    

f0103a38 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103a38:	f3 0f 1e fb          	endbr32 
f0103a3c:	55                   	push   %ebp
f0103a3d:	89 e5                	mov    %esp,%ebp
f0103a3f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103a42:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103a45:	50                   	push   %eax
f0103a46:	ff 75 08             	pushl  0x8(%ebp)
f0103a49:	e8 af ff ff ff       	call   f01039fd <vcprintf>
	va_end(ap);

	return cnt;
}
f0103a4e:	c9                   	leave  
f0103a4f:	c3                   	ret    

f0103a50 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103a50:	f3 0f 1e fb          	endbr32 
f0103a54:	55                   	push   %ebp
f0103a55:	89 e5                	mov    %esp,%ebp
f0103a57:	57                   	push   %edi
f0103a58:	56                   	push   %esi
f0103a59:	53                   	push   %ebx
f0103a5a:	83 ec 04             	sub    $0x4,%esp
f0103a5d:	e8 11 c7 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103a62:	81 c3 ba a5 08 00    	add    $0x8a5ba,%ebx
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103a68:	c7 83 68 2b 00 00 00 	movl   $0xf0000000,0x2b68(%ebx)
f0103a6f:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0103a72:	66 c7 83 6c 2b 00 00 	movw   $0x10,0x2b6c(%ebx)
f0103a79:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f0103a7b:	66 c7 83 ca 2b 00 00 	movw   $0x68,0x2bca(%ebx)
f0103a82:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103a84:	c7 c0 00 d3 11 f0    	mov    $0xf011d300,%eax
f0103a8a:	66 c7 40 28 67 00    	movw   $0x67,0x28(%eax)
f0103a90:	8d b3 64 2b 00 00    	lea    0x2b64(%ebx),%esi
f0103a96:	66 89 70 2a          	mov    %si,0x2a(%eax)
f0103a9a:	89 f2                	mov    %esi,%edx
f0103a9c:	c1 ea 10             	shr    $0x10,%edx
f0103a9f:	88 50 2c             	mov    %dl,0x2c(%eax)
f0103aa2:	0f b6 50 2d          	movzbl 0x2d(%eax),%edx
f0103aa6:	83 e2 f0             	and    $0xfffffff0,%edx
f0103aa9:	83 ca 09             	or     $0x9,%edx
f0103aac:	83 e2 9f             	and    $0xffffff9f,%edx
f0103aaf:	83 ca 80             	or     $0xffffff80,%edx
f0103ab2:	88 55 f3             	mov    %dl,-0xd(%ebp)
f0103ab5:	88 50 2d             	mov    %dl,0x2d(%eax)
f0103ab8:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
f0103abc:	83 e1 c0             	and    $0xffffffc0,%ecx
f0103abf:	83 c9 40             	or     $0x40,%ecx
f0103ac2:	83 e1 7f             	and    $0x7f,%ecx
f0103ac5:	88 48 2e             	mov    %cl,0x2e(%eax)
f0103ac8:	c1 ee 18             	shr    $0x18,%esi
f0103acb:	89 f1                	mov    %esi,%ecx
f0103acd:	88 48 2f             	mov    %cl,0x2f(%eax)
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103ad0:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
f0103ad4:	83 e2 ef             	and    $0xffffffef,%edx
f0103ad7:	88 50 2d             	mov    %dl,0x2d(%eax)
	asm volatile("ltr %0" : : "r" (sel));
f0103ada:	b8 28 00 00 00       	mov    $0x28,%eax
f0103adf:	0f 00 d8             	ltr    %ax
	asm volatile("lidt (%0)" : : "r" (p));
f0103ae2:	8d 83 ec 1f 00 00    	lea    0x1fec(%ebx),%eax
f0103ae8:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0103aeb:	83 c4 04             	add    $0x4,%esp
f0103aee:	5b                   	pop    %ebx
f0103aef:	5e                   	pop    %esi
f0103af0:	5f                   	pop    %edi
f0103af1:	5d                   	pop    %ebp
f0103af2:	c3                   	ret    

f0103af3 <trap_init>:
{
f0103af3:	f3 0f 1e fb          	endbr32 
f0103af7:	55                   	push   %ebp
f0103af8:	89 e5                	mov    %esp,%ebp
f0103afa:	e8 51 cc ff ff       	call   f0100750 <__x86.get_pc_thunk.ax>
f0103aff:	05 1d a5 08 00       	add    $0x8a51d,%eax
    SETGATE(idt[T_DIVIDE], 0, GD_KT, DIVIDE, 0);
f0103b04:	c7 c2 16 43 10 f0    	mov    $0xf0104316,%edx
f0103b0a:	66 89 90 44 23 00 00 	mov    %dx,0x2344(%eax)
f0103b11:	66 c7 80 46 23 00 00 	movw   $0x8,0x2346(%eax)
f0103b18:	08 00 
f0103b1a:	c6 80 48 23 00 00 00 	movb   $0x0,0x2348(%eax)
f0103b21:	c6 80 49 23 00 00 8e 	movb   $0x8e,0x2349(%eax)
f0103b28:	c1 ea 10             	shr    $0x10,%edx
f0103b2b:	66 89 90 4a 23 00 00 	mov    %dx,0x234a(%eax)
	SETGATE(idt[T_DEBUG], 0, GD_KT, DEBUG, 0);
f0103b32:	c7 c2 1c 43 10 f0    	mov    $0xf010431c,%edx
f0103b38:	66 89 90 4c 23 00 00 	mov    %dx,0x234c(%eax)
f0103b3f:	66 c7 80 4e 23 00 00 	movw   $0x8,0x234e(%eax)
f0103b46:	08 00 
f0103b48:	c6 80 50 23 00 00 00 	movb   $0x0,0x2350(%eax)
f0103b4f:	c6 80 51 23 00 00 8e 	movb   $0x8e,0x2351(%eax)
f0103b56:	c1 ea 10             	shr    $0x10,%edx
f0103b59:	66 89 90 52 23 00 00 	mov    %dx,0x2352(%eax)
	SETGATE(idt[T_NMI], 0, GD_KT, NMI, 0);
f0103b60:	c7 c2 22 43 10 f0    	mov    $0xf0104322,%edx
f0103b66:	66 89 90 54 23 00 00 	mov    %dx,0x2354(%eax)
f0103b6d:	66 c7 80 56 23 00 00 	movw   $0x8,0x2356(%eax)
f0103b74:	08 00 
f0103b76:	c6 80 58 23 00 00 00 	movb   $0x0,0x2358(%eax)
f0103b7d:	c6 80 59 23 00 00 8e 	movb   $0x8e,0x2359(%eax)
f0103b84:	c1 ea 10             	shr    $0x10,%edx
f0103b87:	66 89 90 5a 23 00 00 	mov    %dx,0x235a(%eax)
	SETGATE(idt[T_BRKPT], 1, GD_KT, BRKPT, 3);
f0103b8e:	c7 c2 28 43 10 f0    	mov    $0xf0104328,%edx
f0103b94:	66 89 90 5c 23 00 00 	mov    %dx,0x235c(%eax)
f0103b9b:	66 c7 80 5e 23 00 00 	movw   $0x8,0x235e(%eax)
f0103ba2:	08 00 
f0103ba4:	c6 80 60 23 00 00 00 	movb   $0x0,0x2360(%eax)
f0103bab:	c6 80 61 23 00 00 ef 	movb   $0xef,0x2361(%eax)
f0103bb2:	c1 ea 10             	shr    $0x10,%edx
f0103bb5:	66 89 90 62 23 00 00 	mov    %dx,0x2362(%eax)
	SETGATE(idt[T_OFLOW], 0, GD_KT, OFLOW, 0);
f0103bbc:	c7 c2 2e 43 10 f0    	mov    $0xf010432e,%edx
f0103bc2:	66 89 90 64 23 00 00 	mov    %dx,0x2364(%eax)
f0103bc9:	66 c7 80 66 23 00 00 	movw   $0x8,0x2366(%eax)
f0103bd0:	08 00 
f0103bd2:	c6 80 68 23 00 00 00 	movb   $0x0,0x2368(%eax)
f0103bd9:	c6 80 69 23 00 00 8e 	movb   $0x8e,0x2369(%eax)
f0103be0:	c1 ea 10             	shr    $0x10,%edx
f0103be3:	66 89 90 6a 23 00 00 	mov    %dx,0x236a(%eax)
	SETGATE(idt[T_BOUND], 0, GD_KT, BOUND, 0);
f0103bea:	c7 c2 34 43 10 f0    	mov    $0xf0104334,%edx
f0103bf0:	66 89 90 6c 23 00 00 	mov    %dx,0x236c(%eax)
f0103bf7:	66 c7 80 6e 23 00 00 	movw   $0x8,0x236e(%eax)
f0103bfe:	08 00 
f0103c00:	c6 80 70 23 00 00 00 	movb   $0x0,0x2370(%eax)
f0103c07:	c6 80 71 23 00 00 8e 	movb   $0x8e,0x2371(%eax)
f0103c0e:	c1 ea 10             	shr    $0x10,%edx
f0103c11:	66 89 90 72 23 00 00 	mov    %dx,0x2372(%eax)
	SETGATE(idt[T_ILLOP], 0, GD_KT, ILLOP, 0);
f0103c18:	c7 c2 3a 43 10 f0    	mov    $0xf010433a,%edx
f0103c1e:	66 89 90 74 23 00 00 	mov    %dx,0x2374(%eax)
f0103c25:	66 c7 80 76 23 00 00 	movw   $0x8,0x2376(%eax)
f0103c2c:	08 00 
f0103c2e:	c6 80 78 23 00 00 00 	movb   $0x0,0x2378(%eax)
f0103c35:	c6 80 79 23 00 00 8e 	movb   $0x8e,0x2379(%eax)
f0103c3c:	c1 ea 10             	shr    $0x10,%edx
f0103c3f:	66 89 90 7a 23 00 00 	mov    %dx,0x237a(%eax)
	SETGATE(idt[T_DEVICE], 0, GD_KT, DEVICE, 0);
f0103c46:	c7 c2 40 43 10 f0    	mov    $0xf0104340,%edx
f0103c4c:	66 89 90 7c 23 00 00 	mov    %dx,0x237c(%eax)
f0103c53:	66 c7 80 7e 23 00 00 	movw   $0x8,0x237e(%eax)
f0103c5a:	08 00 
f0103c5c:	c6 80 80 23 00 00 00 	movb   $0x0,0x2380(%eax)
f0103c63:	c6 80 81 23 00 00 8e 	movb   $0x8e,0x2381(%eax)
f0103c6a:	c1 ea 10             	shr    $0x10,%edx
f0103c6d:	66 89 90 82 23 00 00 	mov    %dx,0x2382(%eax)
	SETGATE(idt[T_DBLFLT], 0, GD_KT, DBLFLT, 0);
f0103c74:	c7 c2 46 43 10 f0    	mov    $0xf0104346,%edx
f0103c7a:	66 89 90 84 23 00 00 	mov    %dx,0x2384(%eax)
f0103c81:	66 c7 80 86 23 00 00 	movw   $0x8,0x2386(%eax)
f0103c88:	08 00 
f0103c8a:	c6 80 88 23 00 00 00 	movb   $0x0,0x2388(%eax)
f0103c91:	c6 80 89 23 00 00 8e 	movb   $0x8e,0x2389(%eax)
f0103c98:	c1 ea 10             	shr    $0x10,%edx
f0103c9b:	66 89 90 8a 23 00 00 	mov    %dx,0x238a(%eax)
	SETGATE(idt[T_TSS], 0, GD_KT, TSS, 0);
f0103ca2:	c7 c2 4a 43 10 f0    	mov    $0xf010434a,%edx
f0103ca8:	66 89 90 94 23 00 00 	mov    %dx,0x2394(%eax)
f0103caf:	66 c7 80 96 23 00 00 	movw   $0x8,0x2396(%eax)
f0103cb6:	08 00 
f0103cb8:	c6 80 98 23 00 00 00 	movb   $0x0,0x2398(%eax)
f0103cbf:	c6 80 99 23 00 00 8e 	movb   $0x8e,0x2399(%eax)
f0103cc6:	c1 ea 10             	shr    $0x10,%edx
f0103cc9:	66 89 90 9a 23 00 00 	mov    %dx,0x239a(%eax)
	SETGATE(idt[T_SEGNP], 0, GD_KT, SEGNP, 0);
f0103cd0:	c7 c2 4e 43 10 f0    	mov    $0xf010434e,%edx
f0103cd6:	66 89 90 9c 23 00 00 	mov    %dx,0x239c(%eax)
f0103cdd:	66 c7 80 9e 23 00 00 	movw   $0x8,0x239e(%eax)
f0103ce4:	08 00 
f0103ce6:	c6 80 a0 23 00 00 00 	movb   $0x0,0x23a0(%eax)
f0103ced:	c6 80 a1 23 00 00 8e 	movb   $0x8e,0x23a1(%eax)
f0103cf4:	c1 ea 10             	shr    $0x10,%edx
f0103cf7:	66 89 90 a2 23 00 00 	mov    %dx,0x23a2(%eax)
	SETGATE(idt[T_STACK], 0, GD_KT, STACK, 0);
f0103cfe:	c7 c2 52 43 10 f0    	mov    $0xf0104352,%edx
f0103d04:	66 89 90 a4 23 00 00 	mov    %dx,0x23a4(%eax)
f0103d0b:	66 c7 80 a6 23 00 00 	movw   $0x8,0x23a6(%eax)
f0103d12:	08 00 
f0103d14:	c6 80 a8 23 00 00 00 	movb   $0x0,0x23a8(%eax)
f0103d1b:	c6 80 a9 23 00 00 8e 	movb   $0x8e,0x23a9(%eax)
f0103d22:	c1 ea 10             	shr    $0x10,%edx
f0103d25:	66 89 90 aa 23 00 00 	mov    %dx,0x23aa(%eax)
	SETGATE(idt[T_GPFLT], 0, GD_KT, GPFLT, 0);
f0103d2c:	c7 c2 56 43 10 f0    	mov    $0xf0104356,%edx
f0103d32:	66 89 90 ac 23 00 00 	mov    %dx,0x23ac(%eax)
f0103d39:	66 c7 80 ae 23 00 00 	movw   $0x8,0x23ae(%eax)
f0103d40:	08 00 
f0103d42:	c6 80 b0 23 00 00 00 	movb   $0x0,0x23b0(%eax)
f0103d49:	c6 80 b1 23 00 00 8e 	movb   $0x8e,0x23b1(%eax)
f0103d50:	c1 ea 10             	shr    $0x10,%edx
f0103d53:	66 89 90 b2 23 00 00 	mov    %dx,0x23b2(%eax)
	SETGATE(idt[T_PGFLT], 0, GD_KT, PGFLT, 0);
f0103d5a:	c7 c2 5a 43 10 f0    	mov    $0xf010435a,%edx
f0103d60:	66 89 90 b4 23 00 00 	mov    %dx,0x23b4(%eax)
f0103d67:	66 c7 80 b6 23 00 00 	movw   $0x8,0x23b6(%eax)
f0103d6e:	08 00 
f0103d70:	c6 80 b8 23 00 00 00 	movb   $0x0,0x23b8(%eax)
f0103d77:	c6 80 b9 23 00 00 8e 	movb   $0x8e,0x23b9(%eax)
f0103d7e:	c1 ea 10             	shr    $0x10,%edx
f0103d81:	66 89 90 ba 23 00 00 	mov    %dx,0x23ba(%eax)
	SETGATE(idt[T_FPERR], 0, GD_KT, FPERR, 0);
f0103d88:	c7 c2 5e 43 10 f0    	mov    $0xf010435e,%edx
f0103d8e:	66 89 90 c4 23 00 00 	mov    %dx,0x23c4(%eax)
f0103d95:	66 c7 80 c6 23 00 00 	movw   $0x8,0x23c6(%eax)
f0103d9c:	08 00 
f0103d9e:	c6 80 c8 23 00 00 00 	movb   $0x0,0x23c8(%eax)
f0103da5:	c6 80 c9 23 00 00 8e 	movb   $0x8e,0x23c9(%eax)
f0103dac:	c1 ea 10             	shr    $0x10,%edx
f0103daf:	66 89 90 ca 23 00 00 	mov    %dx,0x23ca(%eax)
	SETGATE(idt[T_ALIGN], 0, GD_KT, ALIGN, 0);
f0103db6:	c7 c2 64 43 10 f0    	mov    $0xf0104364,%edx
f0103dbc:	66 89 90 cc 23 00 00 	mov    %dx,0x23cc(%eax)
f0103dc3:	66 c7 80 ce 23 00 00 	movw   $0x8,0x23ce(%eax)
f0103dca:	08 00 
f0103dcc:	c6 80 d0 23 00 00 00 	movb   $0x0,0x23d0(%eax)
f0103dd3:	c6 80 d1 23 00 00 8e 	movb   $0x8e,0x23d1(%eax)
f0103dda:	c1 ea 10             	shr    $0x10,%edx
f0103ddd:	66 89 90 d2 23 00 00 	mov    %dx,0x23d2(%eax)
	SETGATE(idt[T_MCHK], 0, GD_KT, MCHK, 0);
f0103de4:	c7 c2 68 43 10 f0    	mov    $0xf0104368,%edx
f0103dea:	66 89 90 d4 23 00 00 	mov    %dx,0x23d4(%eax)
f0103df1:	66 c7 80 d6 23 00 00 	movw   $0x8,0x23d6(%eax)
f0103df8:	08 00 
f0103dfa:	c6 80 d8 23 00 00 00 	movb   $0x0,0x23d8(%eax)
f0103e01:	c6 80 d9 23 00 00 8e 	movb   $0x8e,0x23d9(%eax)
f0103e08:	c1 ea 10             	shr    $0x10,%edx
f0103e0b:	66 89 90 da 23 00 00 	mov    %dx,0x23da(%eax)
	SETGATE(idt[T_SIMDERR], 0, GD_KT, SIMDERR, 0);
f0103e12:	c7 c2 6e 43 10 f0    	mov    $0xf010436e,%edx
f0103e18:	66 89 90 dc 23 00 00 	mov    %dx,0x23dc(%eax)
f0103e1f:	66 c7 80 de 23 00 00 	movw   $0x8,0x23de(%eax)
f0103e26:	08 00 
f0103e28:	c6 80 e0 23 00 00 00 	movb   $0x0,0x23e0(%eax)
f0103e2f:	c6 80 e1 23 00 00 8e 	movb   $0x8e,0x23e1(%eax)
f0103e36:	c1 ea 10             	shr    $0x10,%edx
f0103e39:	66 89 90 e2 23 00 00 	mov    %dx,0x23e2(%eax)
	SETGATE(idt[T_SYSCALL], 1, GD_KT, SYSCALL, 3);
f0103e40:	c7 c2 74 43 10 f0    	mov    $0xf0104374,%edx
f0103e46:	66 89 90 c4 24 00 00 	mov    %dx,0x24c4(%eax)
f0103e4d:	66 c7 80 c6 24 00 00 	movw   $0x8,0x24c6(%eax)
f0103e54:	08 00 
f0103e56:	c6 80 c8 24 00 00 00 	movb   $0x0,0x24c8(%eax)
f0103e5d:	c6 80 c9 24 00 00 ef 	movb   $0xef,0x24c9(%eax)
f0103e64:	c1 ea 10             	shr    $0x10,%edx
f0103e67:	66 89 90 ca 24 00 00 	mov    %dx,0x24ca(%eax)
	SETGATE(idt[T_DEFAULT], 0, GD_KT, DEFAULT, 0);
f0103e6e:	c7 c2 7a 43 10 f0    	mov    $0xf010437a,%edx
f0103e74:	66 89 90 e4 32 00 00 	mov    %dx,0x32e4(%eax)
f0103e7b:	66 c7 80 e6 32 00 00 	movw   $0x8,0x32e6(%eax)
f0103e82:	08 00 
f0103e84:	c6 80 e8 32 00 00 00 	movb   $0x0,0x32e8(%eax)
f0103e8b:	c6 80 e9 32 00 00 8e 	movb   $0x8e,0x32e9(%eax)
f0103e92:	c1 ea 10             	shr    $0x10,%edx
f0103e95:	66 89 90 ea 32 00 00 	mov    %dx,0x32ea(%eax)
	trap_init_percpu();
f0103e9c:	e8 af fb ff ff       	call   f0103a50 <trap_init_percpu>
}
f0103ea1:	5d                   	pop    %ebp
f0103ea2:	c3                   	ret    

f0103ea3 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103ea3:	f3 0f 1e fb          	endbr32 
f0103ea7:	55                   	push   %ebp
f0103ea8:	89 e5                	mov    %esp,%ebp
f0103eaa:	56                   	push   %esi
f0103eab:	53                   	push   %ebx
f0103eac:	e8 c2 c2 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103eb1:	81 c3 6b a1 08 00    	add    $0x8a16b,%ebx
f0103eb7:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103eba:	83 ec 08             	sub    $0x8,%esp
f0103ebd:	ff 36                	pushl  (%esi)
f0103ebf:	8d 83 30 87 f7 ff    	lea    -0x878d0(%ebx),%eax
f0103ec5:	50                   	push   %eax
f0103ec6:	e8 6d fb ff ff       	call   f0103a38 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103ecb:	83 c4 08             	add    $0x8,%esp
f0103ece:	ff 76 04             	pushl  0x4(%esi)
f0103ed1:	8d 83 3f 87 f7 ff    	lea    -0x878c1(%ebx),%eax
f0103ed7:	50                   	push   %eax
f0103ed8:	e8 5b fb ff ff       	call   f0103a38 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103edd:	83 c4 08             	add    $0x8,%esp
f0103ee0:	ff 76 08             	pushl  0x8(%esi)
f0103ee3:	8d 83 4e 87 f7 ff    	lea    -0x878b2(%ebx),%eax
f0103ee9:	50                   	push   %eax
f0103eea:	e8 49 fb ff ff       	call   f0103a38 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103eef:	83 c4 08             	add    $0x8,%esp
f0103ef2:	ff 76 0c             	pushl  0xc(%esi)
f0103ef5:	8d 83 5d 87 f7 ff    	lea    -0x878a3(%ebx),%eax
f0103efb:	50                   	push   %eax
f0103efc:	e8 37 fb ff ff       	call   f0103a38 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103f01:	83 c4 08             	add    $0x8,%esp
f0103f04:	ff 76 10             	pushl  0x10(%esi)
f0103f07:	8d 83 6c 87 f7 ff    	lea    -0x87894(%ebx),%eax
f0103f0d:	50                   	push   %eax
f0103f0e:	e8 25 fb ff ff       	call   f0103a38 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103f13:	83 c4 08             	add    $0x8,%esp
f0103f16:	ff 76 14             	pushl  0x14(%esi)
f0103f19:	8d 83 7b 87 f7 ff    	lea    -0x87885(%ebx),%eax
f0103f1f:	50                   	push   %eax
f0103f20:	e8 13 fb ff ff       	call   f0103a38 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103f25:	83 c4 08             	add    $0x8,%esp
f0103f28:	ff 76 18             	pushl  0x18(%esi)
f0103f2b:	8d 83 8a 87 f7 ff    	lea    -0x87876(%ebx),%eax
f0103f31:	50                   	push   %eax
f0103f32:	e8 01 fb ff ff       	call   f0103a38 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103f37:	83 c4 08             	add    $0x8,%esp
f0103f3a:	ff 76 1c             	pushl  0x1c(%esi)
f0103f3d:	8d 83 99 87 f7 ff    	lea    -0x87867(%ebx),%eax
f0103f43:	50                   	push   %eax
f0103f44:	e8 ef fa ff ff       	call   f0103a38 <cprintf>
}
f0103f49:	83 c4 10             	add    $0x10,%esp
f0103f4c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103f4f:	5b                   	pop    %ebx
f0103f50:	5e                   	pop    %esi
f0103f51:	5d                   	pop    %ebp
f0103f52:	c3                   	ret    

f0103f53 <print_trapframe>:
{
f0103f53:	f3 0f 1e fb          	endbr32 
f0103f57:	55                   	push   %ebp
f0103f58:	89 e5                	mov    %esp,%ebp
f0103f5a:	57                   	push   %edi
f0103f5b:	56                   	push   %esi
f0103f5c:	53                   	push   %ebx
f0103f5d:	83 ec 14             	sub    $0x14,%esp
f0103f60:	e8 0e c2 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103f65:	81 c3 b7 a0 08 00    	add    $0x8a0b7,%ebx
f0103f6b:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("TRAP frame at %p\n", tf);
f0103f6e:	56                   	push   %esi
f0103f6f:	8d 83 cf 88 f7 ff    	lea    -0x87731(%ebx),%eax
f0103f75:	50                   	push   %eax
f0103f76:	e8 bd fa ff ff       	call   f0103a38 <cprintf>
	print_regs(&tf->tf_regs);
f0103f7b:	89 34 24             	mov    %esi,(%esp)
f0103f7e:	e8 20 ff ff ff       	call   f0103ea3 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103f83:	83 c4 08             	add    $0x8,%esp
f0103f86:	0f b7 46 20          	movzwl 0x20(%esi),%eax
f0103f8a:	50                   	push   %eax
f0103f8b:	8d 83 ea 87 f7 ff    	lea    -0x87816(%ebx),%eax
f0103f91:	50                   	push   %eax
f0103f92:	e8 a1 fa ff ff       	call   f0103a38 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103f97:	83 c4 08             	add    $0x8,%esp
f0103f9a:	0f b7 46 24          	movzwl 0x24(%esi),%eax
f0103f9e:	50                   	push   %eax
f0103f9f:	8d 83 fd 87 f7 ff    	lea    -0x87803(%ebx),%eax
f0103fa5:	50                   	push   %eax
f0103fa6:	e8 8d fa ff ff       	call   f0103a38 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103fab:	8b 56 28             	mov    0x28(%esi),%edx
	if (trapno < ARRAY_SIZE(excnames))
f0103fae:	83 c4 10             	add    $0x10,%esp
f0103fb1:	83 fa 13             	cmp    $0x13,%edx
f0103fb4:	0f 86 e9 00 00 00    	jbe    f01040a3 <print_trapframe+0x150>
		return "System call";
f0103fba:	83 fa 30             	cmp    $0x30,%edx
f0103fbd:	8d 83 a8 87 f7 ff    	lea    -0x87858(%ebx),%eax
f0103fc3:	8d 8b b7 87 f7 ff    	lea    -0x87849(%ebx),%ecx
f0103fc9:	0f 44 c1             	cmove  %ecx,%eax
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103fcc:	83 ec 04             	sub    $0x4,%esp
f0103fcf:	50                   	push   %eax
f0103fd0:	52                   	push   %edx
f0103fd1:	8d 83 10 88 f7 ff    	lea    -0x877f0(%ebx),%eax
f0103fd7:	50                   	push   %eax
f0103fd8:	e8 5b fa ff ff       	call   f0103a38 <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103fdd:	83 c4 10             	add    $0x10,%esp
f0103fe0:	39 b3 44 2b 00 00    	cmp    %esi,0x2b44(%ebx)
f0103fe6:	0f 84 c3 00 00 00    	je     f01040af <print_trapframe+0x15c>
	cprintf("  err  0x%08x", tf->tf_err);
f0103fec:	83 ec 08             	sub    $0x8,%esp
f0103fef:	ff 76 2c             	pushl  0x2c(%esi)
f0103ff2:	8d 83 31 88 f7 ff    	lea    -0x877cf(%ebx),%eax
f0103ff8:	50                   	push   %eax
f0103ff9:	e8 3a fa ff ff       	call   f0103a38 <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f0103ffe:	83 c4 10             	add    $0x10,%esp
f0104001:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f0104005:	0f 85 c9 00 00 00    	jne    f01040d4 <print_trapframe+0x181>
			tf->tf_err & 1 ? "protection" : "not-present");
f010400b:	8b 46 2c             	mov    0x2c(%esi),%eax
		cprintf(" [%s, %s, %s]\n",
f010400e:	89 c2                	mov    %eax,%edx
f0104010:	83 e2 01             	and    $0x1,%edx
f0104013:	8d 8b c3 87 f7 ff    	lea    -0x8783d(%ebx),%ecx
f0104019:	8d 93 ce 87 f7 ff    	lea    -0x87832(%ebx),%edx
f010401f:	0f 44 ca             	cmove  %edx,%ecx
f0104022:	89 c2                	mov    %eax,%edx
f0104024:	83 e2 02             	and    $0x2,%edx
f0104027:	8d 93 da 87 f7 ff    	lea    -0x87826(%ebx),%edx
f010402d:	8d bb e0 87 f7 ff    	lea    -0x87820(%ebx),%edi
f0104033:	0f 44 d7             	cmove  %edi,%edx
f0104036:	83 e0 04             	and    $0x4,%eax
f0104039:	8d 83 e5 87 f7 ff    	lea    -0x8781b(%ebx),%eax
f010403f:	8d bb fa 88 f7 ff    	lea    -0x87706(%ebx),%edi
f0104045:	0f 44 c7             	cmove  %edi,%eax
f0104048:	51                   	push   %ecx
f0104049:	52                   	push   %edx
f010404a:	50                   	push   %eax
f010404b:	8d 83 3f 88 f7 ff    	lea    -0x877c1(%ebx),%eax
f0104051:	50                   	push   %eax
f0104052:	e8 e1 f9 ff ff       	call   f0103a38 <cprintf>
f0104057:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010405a:	83 ec 08             	sub    $0x8,%esp
f010405d:	ff 76 30             	pushl  0x30(%esi)
f0104060:	8d 83 4e 88 f7 ff    	lea    -0x877b2(%ebx),%eax
f0104066:	50                   	push   %eax
f0104067:	e8 cc f9 ff ff       	call   f0103a38 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f010406c:	83 c4 08             	add    $0x8,%esp
f010406f:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104073:	50                   	push   %eax
f0104074:	8d 83 5d 88 f7 ff    	lea    -0x877a3(%ebx),%eax
f010407a:	50                   	push   %eax
f010407b:	e8 b8 f9 ff ff       	call   f0103a38 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0104080:	83 c4 08             	add    $0x8,%esp
f0104083:	ff 76 38             	pushl  0x38(%esi)
f0104086:	8d 83 70 88 f7 ff    	lea    -0x87790(%ebx),%eax
f010408c:	50                   	push   %eax
f010408d:	e8 a6 f9 ff ff       	call   f0103a38 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0104092:	83 c4 10             	add    $0x10,%esp
f0104095:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f0104099:	75 50                	jne    f01040eb <print_trapframe+0x198>
}
f010409b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010409e:	5b                   	pop    %ebx
f010409f:	5e                   	pop    %esi
f01040a0:	5f                   	pop    %edi
f01040a1:	5d                   	pop    %ebp
f01040a2:	c3                   	ret    
		return excnames[trapno];
f01040a3:	8b 84 93 64 20 00 00 	mov    0x2064(%ebx,%edx,4),%eax
f01040aa:	e9 1d ff ff ff       	jmp    f0103fcc <print_trapframe+0x79>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01040af:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f01040b3:	0f 85 33 ff ff ff    	jne    f0103fec <print_trapframe+0x99>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01040b9:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01040bc:	83 ec 08             	sub    $0x8,%esp
f01040bf:	50                   	push   %eax
f01040c0:	8d 83 22 88 f7 ff    	lea    -0x877de(%ebx),%eax
f01040c6:	50                   	push   %eax
f01040c7:	e8 6c f9 ff ff       	call   f0103a38 <cprintf>
f01040cc:	83 c4 10             	add    $0x10,%esp
f01040cf:	e9 18 ff ff ff       	jmp    f0103fec <print_trapframe+0x99>
		cprintf("\n");
f01040d4:	83 ec 0c             	sub    $0xc,%esp
f01040d7:	8d 83 8e 85 f7 ff    	lea    -0x87a72(%ebx),%eax
f01040dd:	50                   	push   %eax
f01040de:	e8 55 f9 ff ff       	call   f0103a38 <cprintf>
f01040e3:	83 c4 10             	add    $0x10,%esp
f01040e6:	e9 6f ff ff ff       	jmp    f010405a <print_trapframe+0x107>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01040eb:	83 ec 08             	sub    $0x8,%esp
f01040ee:	ff 76 3c             	pushl  0x3c(%esi)
f01040f1:	8d 83 7f 88 f7 ff    	lea    -0x87781(%ebx),%eax
f01040f7:	50                   	push   %eax
f01040f8:	e8 3b f9 ff ff       	call   f0103a38 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01040fd:	83 c4 08             	add    $0x8,%esp
f0104100:	0f b7 46 40          	movzwl 0x40(%esi),%eax
f0104104:	50                   	push   %eax
f0104105:	8d 83 8e 88 f7 ff    	lea    -0x87772(%ebx),%eax
f010410b:	50                   	push   %eax
f010410c:	e8 27 f9 ff ff       	call   f0103a38 <cprintf>
f0104111:	83 c4 10             	add    $0x10,%esp
}
f0104114:	eb 85                	jmp    f010409b <print_trapframe+0x148>

f0104116 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0104116:	f3 0f 1e fb          	endbr32 
f010411a:	55                   	push   %ebp
f010411b:	89 e5                	mov    %esp,%ebp
f010411d:	57                   	push   %edi
f010411e:	56                   	push   %esi
f010411f:	53                   	push   %ebx
f0104120:	83 ec 0c             	sub    $0xc,%esp
f0104123:	e8 4b c0 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0104128:	81 c3 f4 9e 08 00    	add    $0x89ef4,%ebx
f010412e:	8b 75 08             	mov    0x8(%ebp),%esi
f0104131:	0f 20 d0             	mov    %cr2,%eax

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	// check low-bits of tf_cs
	if((tf->tf_cs & 3) == 0)
f0104134:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f0104138:	74 38                	je     f0104172 <page_fault_handler+0x5c>
	}

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010413a:	ff 76 30             	pushl  0x30(%esi)
f010413d:	50                   	push   %eax
f010413e:	c7 c7 48 03 19 f0    	mov    $0xf0190348,%edi
f0104144:	8b 07                	mov    (%edi),%eax
f0104146:	ff 70 48             	pushl  0x48(%eax)
f0104149:	8d 83 70 8a f7 ff    	lea    -0x87590(%ebx),%eax
f010414f:	50                   	push   %eax
f0104150:	e8 e3 f8 ff ff       	call   f0103a38 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0104155:	89 34 24             	mov    %esi,(%esp)
f0104158:	e8 f6 fd ff ff       	call   f0103f53 <print_trapframe>
	env_destroy(curenv);
f010415d:	83 c4 04             	add    $0x4,%esp
f0104160:	ff 37                	pushl  (%edi)
f0104162:	e8 4b f7 ff ff       	call   f01038b2 <env_destroy>
}
f0104167:	83 c4 10             	add    $0x10,%esp
f010416a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010416d:	5b                   	pop    %ebx
f010416e:	5e                   	pop    %esi
f010416f:	5f                   	pop    %edi
f0104170:	5d                   	pop    %ebp
f0104171:	c3                   	ret    
		panic("At page_fault_handler: page fault at %08x.\n",fault_va);
f0104172:	50                   	push   %eax
f0104173:	8d 83 44 8a f7 ff    	lea    -0x875bc(%ebx),%eax
f0104179:	50                   	push   %eax
f010417a:	68 28 01 00 00       	push   $0x128
f010417f:	8d 83 a1 88 f7 ff    	lea    -0x8775f(%ebx),%eax
f0104185:	50                   	push   %eax
f0104186:	e8 2a bf ff ff       	call   f01000b5 <_panic>

f010418b <trap>:
{
f010418b:	f3 0f 1e fb          	endbr32 
f010418f:	55                   	push   %ebp
f0104190:	89 e5                	mov    %esp,%ebp
f0104192:	57                   	push   %edi
f0104193:	56                   	push   %esi
f0104194:	53                   	push   %ebx
f0104195:	83 ec 0c             	sub    $0xc,%esp
f0104198:	e8 d6 bf ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f010419d:	81 c3 7f 9e 08 00    	add    $0x89e7f,%ebx
f01041a3:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::: "cc");
f01041a6:	fc                   	cld    
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01041a7:	9c                   	pushf  
f01041a8:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
f01041a9:	f6 c4 02             	test   $0x2,%ah
f01041ac:	74 1f                	je     f01041cd <trap+0x42>
f01041ae:	8d 83 ad 88 f7 ff    	lea    -0x87753(%ebx),%eax
f01041b4:	50                   	push   %eax
f01041b5:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01041bb:	50                   	push   %eax
f01041bc:	68 fd 00 00 00       	push   $0xfd
f01041c1:	8d 83 a1 88 f7 ff    	lea    -0x8775f(%ebx),%eax
f01041c7:	50                   	push   %eax
f01041c8:	e8 e8 be ff ff       	call   f01000b5 <_panic>
	cprintf("Incoming TRAP frame at %p\n", tf);
f01041cd:	83 ec 08             	sub    $0x8,%esp
f01041d0:	56                   	push   %esi
f01041d1:	8d 83 c6 88 f7 ff    	lea    -0x8773a(%ebx),%eax
f01041d7:	50                   	push   %eax
f01041d8:	e8 5b f8 ff ff       	call   f0103a38 <cprintf>
	if ((tf->tf_cs & 3) == 3) {
f01041dd:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01041e1:	83 e0 03             	and    $0x3,%eax
f01041e4:	83 c4 10             	add    $0x10,%esp
f01041e7:	66 83 f8 03          	cmp    $0x3,%ax
f01041eb:	75 1d                	jne    f010420a <trap+0x7f>
		assert(curenv);
f01041ed:	c7 c0 48 03 19 f0    	mov    $0xf0190348,%eax
f01041f3:	8b 00                	mov    (%eax),%eax
f01041f5:	85 c0                	test   %eax,%eax
f01041f7:	74 41                	je     f010423a <trap+0xaf>
		curenv->env_tf = *tf;
f01041f9:	b9 11 00 00 00       	mov    $0x11,%ecx
f01041fe:	89 c7                	mov    %eax,%edi
f0104200:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &curenv->env_tf;
f0104202:	c7 c0 48 03 19 f0    	mov    $0xf0190348,%eax
f0104208:	8b 30                	mov    (%eax),%esi
	last_tf = tf;
f010420a:	89 b3 44 2b 00 00    	mov    %esi,0x2b44(%ebx)
	switch(tf->tf_trapno)
f0104210:	8b 46 28             	mov    0x28(%esi),%eax
f0104213:	83 f8 0e             	cmp    $0xe,%eax
f0104216:	74 67                	je     f010427f <trap+0xf4>
f0104218:	77 3f                	ja     f0104259 <trap+0xce>
f010421a:	83 f8 01             	cmp    $0x1,%eax
f010421d:	0f 84 99 00 00 00    	je     f01042bc <trap+0x131>
f0104223:	83 f8 03             	cmp    $0x3,%eax
f0104226:	0f 85 9e 00 00 00    	jne    f01042ca <trap+0x13f>
			monitor(tf);
f010422c:	83 ec 0c             	sub    $0xc,%esp
f010422f:	56                   	push   %esi
f0104230:	e8 4f c7 ff ff       	call   f0100984 <monitor>
			return;
f0104235:	83 c4 10             	add    $0x10,%esp
f0104238:	eb 51                	jmp    f010428b <trap+0x100>
		assert(curenv);
f010423a:	8d 83 e1 88 f7 ff    	lea    -0x8771f(%ebx),%eax
f0104240:	50                   	push   %eax
f0104241:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f0104247:	50                   	push   %eax
f0104248:	68 03 01 00 00       	push   $0x103
f010424d:	8d 83 a1 88 f7 ff    	lea    -0x8775f(%ebx),%eax
f0104253:	50                   	push   %eax
f0104254:	e8 5c be ff ff       	call   f01000b5 <_panic>
	switch(tf->tf_trapno)
f0104259:	83 f8 30             	cmp    $0x30,%eax
f010425c:	75 6c                	jne    f01042ca <trap+0x13f>
			int32_t ret = syscall(regs->reg_eax,regs->reg_edx,regs->reg_ecx,regs->reg_ebx,regs->reg_edi,regs->reg_esi);
f010425e:	83 ec 08             	sub    $0x8,%esp
f0104261:	ff 76 04             	pushl  0x4(%esi)
f0104264:	ff 36                	pushl  (%esi)
f0104266:	ff 76 10             	pushl  0x10(%esi)
f0104269:	ff 76 18             	pushl  0x18(%esi)
f010426c:	ff 76 14             	pushl  0x14(%esi)
f010426f:	ff 76 1c             	pushl  0x1c(%esi)
f0104272:	e8 1d 01 00 00       	call   f0104394 <syscall>
			regs->reg_eax = (uint32_t)ret;
f0104277:	89 46 1c             	mov    %eax,0x1c(%esi)
			return;
f010427a:	83 c4 20             	add    $0x20,%esp
f010427d:	eb 0c                	jmp    f010428b <trap+0x100>
			page_fault_handler(tf);
f010427f:	83 ec 0c             	sub    $0xc,%esp
f0104282:	56                   	push   %esi
f0104283:	e8 8e fe ff ff       	call   f0104116 <page_fault_handler>
			return;
f0104288:	83 c4 10             	add    $0x10,%esp
	assert(curenv && curenv->env_status == ENV_RUNNING);
f010428b:	c7 c0 48 03 19 f0    	mov    $0xf0190348,%eax
f0104291:	8b 00                	mov    (%eax),%eax
f0104293:	85 c0                	test   %eax,%eax
f0104295:	74 06                	je     f010429d <trap+0x112>
f0104297:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010429b:	74 70                	je     f010430d <trap+0x182>
f010429d:	8d 83 94 8a f7 ff    	lea    -0x8756c(%ebx),%eax
f01042a3:	50                   	push   %eax
f01042a4:	8d 83 03 83 f7 ff    	lea    -0x87cfd(%ebx),%eax
f01042aa:	50                   	push   %eax
f01042ab:	68 15 01 00 00       	push   $0x115
f01042b0:	8d 83 a1 88 f7 ff    	lea    -0x8775f(%ebx),%eax
f01042b6:	50                   	push   %eax
f01042b7:	e8 f9 bd ff ff       	call   f01000b5 <_panic>
			monitor(tf);
f01042bc:	83 ec 0c             	sub    $0xc,%esp
f01042bf:	56                   	push   %esi
f01042c0:	e8 bf c6 ff ff       	call   f0100984 <monitor>
			return;
f01042c5:	83 c4 10             	add    $0x10,%esp
f01042c8:	eb c1                	jmp    f010428b <trap+0x100>
	print_trapframe(tf);
f01042ca:	83 ec 0c             	sub    $0xc,%esp
f01042cd:	56                   	push   %esi
f01042ce:	e8 80 fc ff ff       	call   f0103f53 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01042d3:	83 c4 10             	add    $0x10,%esp
f01042d6:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01042db:	74 15                	je     f01042f2 <trap+0x167>
		env_destroy(curenv);
f01042dd:	83 ec 0c             	sub    $0xc,%esp
f01042e0:	c7 c0 48 03 19 f0    	mov    $0xf0190348,%eax
f01042e6:	ff 30                	pushl  (%eax)
f01042e8:	e8 c5 f5 ff ff       	call   f01038b2 <env_destroy>
		return;
f01042ed:	83 c4 10             	add    $0x10,%esp
f01042f0:	eb 99                	jmp    f010428b <trap+0x100>
		panic("unhandled trap in kernel");
f01042f2:	83 ec 04             	sub    $0x4,%esp
f01042f5:	8d 83 e8 88 f7 ff    	lea    -0x87718(%ebx),%eax
f01042fb:	50                   	push   %eax
f01042fc:	68 ec 00 00 00       	push   $0xec
f0104301:	8d 83 a1 88 f7 ff    	lea    -0x8775f(%ebx),%eax
f0104307:	50                   	push   %eax
f0104308:	e8 a8 bd ff ff       	call   f01000b5 <_panic>
	env_run(curenv);
f010430d:	83 ec 0c             	sub    $0xc,%esp
f0104310:	50                   	push   %eax
f0104311:	e8 12 f6 ff ff       	call   f0103928 <env_run>

f0104316 <DIVIDE>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(DIVIDE,T_DIVIDE)
f0104316:	6a 00                	push   $0x0
f0104318:	6a 00                	push   $0x0
f010431a:	eb 67                	jmp    f0104383 <_alltraps>

f010431c <DEBUG>:
TRAPHANDLER_NOEC(DEBUG,T_DEBUG)
f010431c:	6a 00                	push   $0x0
f010431e:	6a 01                	push   $0x1
f0104320:	eb 61                	jmp    f0104383 <_alltraps>

f0104322 <NMI>:
TRAPHANDLER_NOEC(NMI, T_NMI)
f0104322:	6a 00                	push   $0x0
f0104324:	6a 02                	push   $0x2
f0104326:	eb 5b                	jmp    f0104383 <_alltraps>

f0104328 <BRKPT>:
TRAPHANDLER_NOEC(BRKPT, T_BRKPT)
f0104328:	6a 00                	push   $0x0
f010432a:	6a 03                	push   $0x3
f010432c:	eb 55                	jmp    f0104383 <_alltraps>

f010432e <OFLOW>:
TRAPHANDLER_NOEC(OFLOW, T_OFLOW)
f010432e:	6a 00                	push   $0x0
f0104330:	6a 04                	push   $0x4
f0104332:	eb 4f                	jmp    f0104383 <_alltraps>

f0104334 <BOUND>:
TRAPHANDLER_NOEC(BOUND, T_BOUND)
f0104334:	6a 00                	push   $0x0
f0104336:	6a 05                	push   $0x5
f0104338:	eb 49                	jmp    f0104383 <_alltraps>

f010433a <ILLOP>:
TRAPHANDLER_NOEC(ILLOP, T_ILLOP)
f010433a:	6a 00                	push   $0x0
f010433c:	6a 06                	push   $0x6
f010433e:	eb 43                	jmp    f0104383 <_alltraps>

f0104340 <DEVICE>:
TRAPHANDLER_NOEC(DEVICE, T_DEVICE)
f0104340:	6a 00                	push   $0x0
f0104342:	6a 07                	push   $0x7
f0104344:	eb 3d                	jmp    f0104383 <_alltraps>

f0104346 <DBLFLT>:
TRAPHANDLER(DBLFLT, T_DBLFLT)
f0104346:	6a 08                	push   $0x8
f0104348:	eb 39                	jmp    f0104383 <_alltraps>

f010434a <TSS>:
TRAPHANDLER(TSS, T_TSS)
f010434a:	6a 0a                	push   $0xa
f010434c:	eb 35                	jmp    f0104383 <_alltraps>

f010434e <SEGNP>:
TRAPHANDLER(SEGNP, T_SEGNP)
f010434e:	6a 0b                	push   $0xb
f0104350:	eb 31                	jmp    f0104383 <_alltraps>

f0104352 <STACK>:
TRAPHANDLER(STACK, T_STACK)
f0104352:	6a 0c                	push   $0xc
f0104354:	eb 2d                	jmp    f0104383 <_alltraps>

f0104356 <GPFLT>:
TRAPHANDLER(GPFLT, T_GPFLT)
f0104356:	6a 0d                	push   $0xd
f0104358:	eb 29                	jmp    f0104383 <_alltraps>

f010435a <PGFLT>:
TRAPHANDLER(PGFLT, T_PGFLT)
f010435a:	6a 0e                	push   $0xe
f010435c:	eb 25                	jmp    f0104383 <_alltraps>

f010435e <FPERR>:
TRAPHANDLER_NOEC(FPERR, T_FPERR)
f010435e:	6a 00                	push   $0x0
f0104360:	6a 10                	push   $0x10
f0104362:	eb 1f                	jmp    f0104383 <_alltraps>

f0104364 <ALIGN>:
TRAPHANDLER(ALIGN, T_ALIGN)
f0104364:	6a 11                	push   $0x11
f0104366:	eb 1b                	jmp    f0104383 <_alltraps>

f0104368 <MCHK>:
TRAPHANDLER_NOEC(MCHK, T_MCHK)
f0104368:	6a 00                	push   $0x0
f010436a:	6a 12                	push   $0x12
f010436c:	eb 15                	jmp    f0104383 <_alltraps>

f010436e <SIMDERR>:
TRAPHANDLER_NOEC(SIMDERR, T_SIMDERR)
f010436e:	6a 00                	push   $0x0
f0104370:	6a 13                	push   $0x13
f0104372:	eb 0f                	jmp    f0104383 <_alltraps>

f0104374 <SYSCALL>:
TRAPHANDLER_NOEC(SYSCALL, T_SYSCALL)
f0104374:	6a 00                	push   $0x0
f0104376:	6a 30                	push   $0x30
f0104378:	eb 09                	jmp    f0104383 <_alltraps>

f010437a <DEFAULT>:
TRAPHANDLER_NOEC(DEFAULT, T_DEFAULT)
f010437a:	6a 00                	push   $0x0
f010437c:	68 f4 01 00 00       	push   $0x1f4
f0104381:	eb 00                	jmp    f0104383 <_alltraps>

f0104383 <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */
 .global _alltraps
 _alltraps:
 /* code below according to the guide */
pushl %ds
f0104383:	1e                   	push   %ds
pushl %es
f0104384:	06                   	push   %es
pushal
f0104385:	60                   	pusha  
movw $GD_KD, %ax
f0104386:	66 b8 10 00          	mov    $0x10,%ax
movw %ax, %ds
f010438a:	8e d8                	mov    %eax,%ds
movw %ax, %es
f010438c:	8e c0                	mov    %eax,%es
pushl %esp
f010438e:	54                   	push   %esp
call trap
f010438f:	e8 f7 fd ff ff       	call   f010418b <trap>

f0104394 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104394:	f3 0f 1e fb          	endbr32 
f0104398:	55                   	push   %ebp
f0104399:	89 e5                	mov    %esp,%ebp
f010439b:	53                   	push   %ebx
f010439c:	83 ec 14             	sub    $0x14,%esp
f010439f:	e8 cf bd ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01043a4:	81 c3 78 9c 08 00    	add    $0x89c78,%ebx
f01043aa:	8b 45 08             	mov    0x8(%ebp),%eax
f01043ad:	83 f8 04             	cmp    $0x4,%eax
f01043b0:	77 0c                	ja     f01043be <syscall+0x2a>
f01043b2:	89 d9                	mov    %ebx,%ecx
f01043b4:	03 8c 83 f8 8a f7 ff 	add    -0x87508(%ebx,%eax,4),%ecx
f01043bb:	3e ff e1             	notrack jmp *%ecx
		{
			return sys_env_destroy((envid_t)a1);
		}
		case NSYSCALLS:
		{
			return 0;
f01043be:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01043c3:	e9 bb 00 00 00       	jmp    f0104483 <.L12+0x5>

f01043c8 <.L8>:
	user_mem_assert(curenv,s,len,0);
f01043c8:	6a 00                	push   $0x0
f01043ca:	ff 75 10             	pushl  0x10(%ebp)
f01043cd:	ff 75 0c             	pushl  0xc(%ebp)
f01043d0:	c7 c0 48 03 19 f0    	mov    $0xf0190348,%eax
f01043d6:	ff 30                	pushl  (%eax)
f01043d8:	e8 41 ed ff ff       	call   f010311e <user_mem_assert>
	cprintf("%.*s", len, s);
f01043dd:	83 c4 0c             	add    $0xc,%esp
f01043e0:	ff 75 0c             	pushl  0xc(%ebp)
f01043e3:	ff 75 10             	pushl  0x10(%ebp)
f01043e6:	8d 83 c0 8a f7 ff    	lea    -0x87540(%ebx),%eax
f01043ec:	50                   	push   %eax
f01043ed:	e8 46 f6 ff ff       	call   f0103a38 <cprintf>
}
f01043f2:	83 c4 10             	add    $0x10,%esp
			return 0;
f01043f5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01043fa:	e9 84 00 00 00       	jmp    f0104483 <.L12+0x5>

f01043ff <.L7>:
	return cons_getc();
f01043ff:	e8 99 c1 ff ff       	call   f010059d <cons_getc>
			return sys_cgetc();
f0104404:	eb 7d                	jmp    f0104483 <.L12+0x5>

f0104406 <.L5>:
	if ((r = envid2env(envid, &e, 1)) < 0)
f0104406:	83 ec 04             	sub    $0x4,%esp
f0104409:	6a 01                	push   $0x1
f010440b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010440e:	50                   	push   %eax
f010440f:	ff 75 0c             	pushl  0xc(%ebp)
f0104412:	e8 2b ee ff ff       	call   f0103242 <envid2env>
f0104417:	83 c4 10             	add    $0x10,%esp
f010441a:	85 c0                	test   %eax,%eax
f010441c:	78 65                	js     f0104483 <.L12+0x5>
	if (e == curenv)
f010441e:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104421:	c7 c0 48 03 19 f0    	mov    $0xf0190348,%eax
f0104427:	8b 00                	mov    (%eax),%eax
f0104429:	39 c2                	cmp    %eax,%edx
f010442b:	74 2d                	je     f010445a <.L5+0x54>
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010442d:	83 ec 04             	sub    $0x4,%esp
f0104430:	ff 72 48             	pushl  0x48(%edx)
f0104433:	ff 70 48             	pushl  0x48(%eax)
f0104436:	8d 83 e0 8a f7 ff    	lea    -0x87520(%ebx),%eax
f010443c:	50                   	push   %eax
f010443d:	e8 f6 f5 ff ff       	call   f0103a38 <cprintf>
f0104442:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0104445:	83 ec 0c             	sub    $0xc,%esp
f0104448:	ff 75 f4             	pushl  -0xc(%ebp)
f010444b:	e8 62 f4 ff ff       	call   f01038b2 <env_destroy>
	return 0;
f0104450:	83 c4 10             	add    $0x10,%esp
f0104453:	b8 00 00 00 00       	mov    $0x0,%eax
			return sys_env_destroy((envid_t)a1);
f0104458:	eb 29                	jmp    f0104483 <.L12+0x5>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f010445a:	83 ec 08             	sub    $0x8,%esp
f010445d:	ff 70 48             	pushl  0x48(%eax)
f0104460:	8d 83 c5 8a f7 ff    	lea    -0x8753b(%ebx),%eax
f0104466:	50                   	push   %eax
f0104467:	e8 cc f5 ff ff       	call   f0103a38 <cprintf>
f010446c:	83 c4 10             	add    $0x10,%esp
f010446f:	eb d4                	jmp    f0104445 <.L5+0x3f>

f0104471 <.L6>:
	return curenv->env_id;
f0104471:	c7 c0 48 03 19 f0    	mov    $0xf0190348,%eax
f0104477:	8b 00                	mov    (%eax),%eax
f0104479:	8b 40 48             	mov    0x48(%eax),%eax
		}
		case SYS_getenvid:
		{
			return sys_getenvid();
f010447c:	eb 05                	jmp    f0104483 <.L12+0x5>

f010447e <.L12>:
			return 0;
f010447e:	b8 00 00 00 00       	mov    $0x0,%eax
		}
		default:
			return -E_INVAL;
	}
}
f0104483:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104486:	c9                   	leave  
f0104487:	c3                   	ret    

f0104488 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104488:	55                   	push   %ebp
f0104489:	89 e5                	mov    %esp,%ebp
f010448b:	57                   	push   %edi
f010448c:	56                   	push   %esi
f010448d:	53                   	push   %ebx
f010448e:	83 ec 14             	sub    $0x14,%esp
f0104491:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104494:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104497:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010449a:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f010449d:	8b 1a                	mov    (%edx),%ebx
f010449f:	8b 01                	mov    (%ecx),%eax
f01044a1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01044a4:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01044ab:	eb 23                	jmp    f01044d0 <stab_binsearch+0x48>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01044ad:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01044b0:	eb 1e                	jmp    f01044d0 <stab_binsearch+0x48>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01044b2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01044b5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01044b8:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01044bc:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01044bf:	73 46                	jae    f0104507 <stab_binsearch+0x7f>
			*region_left = m;
f01044c1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01044c4:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01044c6:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f01044c9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f01044d0:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01044d3:	7f 5f                	jg     f0104534 <stab_binsearch+0xac>
		int true_m = (l + r) / 2, m = true_m;
f01044d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01044d8:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f01044db:	89 d0                	mov    %edx,%eax
f01044dd:	c1 e8 1f             	shr    $0x1f,%eax
f01044e0:	01 d0                	add    %edx,%eax
f01044e2:	89 c7                	mov    %eax,%edi
f01044e4:	d1 ff                	sar    %edi
f01044e6:	83 e0 fe             	and    $0xfffffffe,%eax
f01044e9:	01 f8                	add    %edi,%eax
f01044eb:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01044ee:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01044f2:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f01044f4:	39 c3                	cmp    %eax,%ebx
f01044f6:	7f b5                	jg     f01044ad <stab_binsearch+0x25>
f01044f8:	0f b6 0a             	movzbl (%edx),%ecx
f01044fb:	83 ea 0c             	sub    $0xc,%edx
f01044fe:	39 f1                	cmp    %esi,%ecx
f0104500:	74 b0                	je     f01044b2 <stab_binsearch+0x2a>
			m--;
f0104502:	83 e8 01             	sub    $0x1,%eax
f0104505:	eb ed                	jmp    f01044f4 <stab_binsearch+0x6c>
		} else if (stabs[m].n_value > addr) {
f0104507:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010450a:	76 14                	jbe    f0104520 <stab_binsearch+0x98>
			*region_right = m - 1;
f010450c:	83 e8 01             	sub    $0x1,%eax
f010450f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104512:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104515:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f0104517:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010451e:	eb b0                	jmp    f01044d0 <stab_binsearch+0x48>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104520:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104523:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0104525:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104529:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f010452b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104532:	eb 9c                	jmp    f01044d0 <stab_binsearch+0x48>
		}
	}

	if (!any_matches)
f0104534:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104538:	75 15                	jne    f010454f <stab_binsearch+0xc7>
		*region_right = *region_left - 1;
f010453a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010453d:	8b 00                	mov    (%eax),%eax
f010453f:	83 e8 01             	sub    $0x1,%eax
f0104542:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104545:	89 07                	mov    %eax,(%edi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0104547:	83 c4 14             	add    $0x14,%esp
f010454a:	5b                   	pop    %ebx
f010454b:	5e                   	pop    %esi
f010454c:	5f                   	pop    %edi
f010454d:	5d                   	pop    %ebp
f010454e:	c3                   	ret    
		for (l = *region_right;
f010454f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104552:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104554:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104557:	8b 0f                	mov    (%edi),%ecx
f0104559:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010455c:	8b 7d ec             	mov    -0x14(%ebp),%edi
f010455f:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
		for (l = *region_right;
f0104563:	eb 03                	jmp    f0104568 <stab_binsearch+0xe0>
		     l--)
f0104565:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0104568:	39 c1                	cmp    %eax,%ecx
f010456a:	7d 0a                	jge    f0104576 <stab_binsearch+0xee>
		     l > *region_left && stabs[l].n_type != type;
f010456c:	0f b6 1a             	movzbl (%edx),%ebx
f010456f:	83 ea 0c             	sub    $0xc,%edx
f0104572:	39 f3                	cmp    %esi,%ebx
f0104574:	75 ef                	jne    f0104565 <stab_binsearch+0xdd>
		*region_left = l;
f0104576:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104579:	89 07                	mov    %eax,(%edi)
}
f010457b:	eb ca                	jmp    f0104547 <stab_binsearch+0xbf>

f010457d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010457d:	f3 0f 1e fb          	endbr32 
f0104581:	55                   	push   %ebp
f0104582:	89 e5                	mov    %esp,%ebp
f0104584:	57                   	push   %edi
f0104585:	56                   	push   %esi
f0104586:	53                   	push   %ebx
f0104587:	83 ec 4c             	sub    $0x4c,%esp
f010458a:	e8 e4 bb ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f010458f:	81 c3 8d 9a 08 00    	add    $0x89a8d,%ebx
f0104595:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104598:	8d 83 0c 8b f7 ff    	lea    -0x874f4(%ebx),%eax
f010459e:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f01045a0:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01045a7:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f01045aa:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01045b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01045b4:	89 46 10             	mov    %eax,0x10(%esi)
	info->eip_fn_narg = 0;
f01045b7:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01045be:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f01045c3:	0f 86 3c 01 00 00    	jbe    f0104705 <debuginfo_eip+0x188>
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01045c9:	c7 c0 56 31 11 f0    	mov    $0xf0113156,%eax
f01045cf:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		stabstr = __STABSTR_BEGIN__;
f01045d2:	c7 c0 25 06 11 f0    	mov    $0xf0110625,%eax
f01045d8:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stab_end = __STAB_END__;
f01045db:	c7 c7 24 06 11 f0    	mov    $0xf0110624,%edi
		stabs = __STAB_BEGIN__;
f01045e1:	c7 c0 24 6d 10 f0    	mov    $0xf0106d24,%eax
f01045e7:	89 45 bc             	mov    %eax,-0x44(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01045ea:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f01045ed:	39 4d b8             	cmp    %ecx,-0x48(%ebp)
f01045f0:	0f 83 54 02 00 00    	jae    f010484a <debuginfo_eip+0x2cd>
f01045f6:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f01045fa:	0f 85 51 02 00 00    	jne    f0104851 <debuginfo_eip+0x2d4>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104600:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104607:	2b 7d bc             	sub    -0x44(%ebp),%edi
f010460a:	c1 ff 02             	sar    $0x2,%edi
f010460d:	69 c7 ab aa aa aa    	imul   $0xaaaaaaab,%edi,%eax
f0104613:	83 e8 01             	sub    $0x1,%eax
f0104616:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104619:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010461c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010461f:	83 ec 08             	sub    $0x8,%esp
f0104622:	ff 75 08             	pushl  0x8(%ebp)
f0104625:	6a 64                	push   $0x64
f0104627:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010462a:	89 f8                	mov    %edi,%eax
f010462c:	e8 57 fe ff ff       	call   f0104488 <stab_binsearch>
	if (lfile == 0)
f0104631:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104634:	83 c4 10             	add    $0x10,%esp
f0104637:	85 c0                	test   %eax,%eax
f0104639:	0f 84 19 02 00 00    	je     f0104858 <debuginfo_eip+0x2db>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010463f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104642:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104645:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104648:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010464b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010464e:	83 ec 08             	sub    $0x8,%esp
f0104651:	ff 75 08             	pushl  0x8(%ebp)
f0104654:	6a 24                	push   $0x24
f0104656:	89 f8                	mov    %edi,%eax
f0104658:	e8 2b fe ff ff       	call   f0104488 <stab_binsearch>

	if (lfun <= rfun) {
f010465d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104660:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104663:	83 c4 10             	add    $0x10,%esp
f0104666:	39 d0                	cmp    %edx,%eax
f0104668:	0f 8f 23 01 00 00    	jg     f0104791 <debuginfo_eip+0x214>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010466e:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0104671:	8d 3c 8f             	lea    (%edi,%ecx,4),%edi
f0104674:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0104677:	8b 3f                	mov    (%edi),%edi
f0104679:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f010467c:	2b 4d b8             	sub    -0x48(%ebp),%ecx
f010467f:	39 cf                	cmp    %ecx,%edi
f0104681:	73 06                	jae    f0104689 <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104683:	03 7d b8             	add    -0x48(%ebp),%edi
f0104686:	89 7e 08             	mov    %edi,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104689:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010468c:	8b 4f 08             	mov    0x8(%edi),%ecx
f010468f:	89 4e 10             	mov    %ecx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0104692:	29 4d 08             	sub    %ecx,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f0104695:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104698:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010469b:	83 ec 08             	sub    $0x8,%esp
f010469e:	6a 3a                	push   $0x3a
f01046a0:	ff 76 08             	pushl  0x8(%esi)
f01046a3:	e8 99 0a 00 00       	call   f0105141 <strfind>
f01046a8:	2b 46 08             	sub    0x8(%esi),%eax
f01046ab:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	info->eip_file = stabstr +stabs[lfile].n_strx;
f01046ae:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01046b1:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01046b4:	8b 5d bc             	mov    -0x44(%ebp),%ebx
f01046b7:	8b 7d b8             	mov    -0x48(%ebp),%edi
f01046ba:	03 3c 83             	add    (%ebx,%eax,4),%edi
f01046bd:	89 3e                	mov    %edi,(%esi)
	stab_binsearch(stabs, &lline, &rline,N_SLINE,addr);
f01046bf:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01046c2:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01046c5:	83 c4 08             	add    $0x8,%esp
f01046c8:	ff 75 08             	pushl  0x8(%ebp)
f01046cb:	6a 44                	push   $0x44
f01046cd:	89 d8                	mov    %ebx,%eax
f01046cf:	e8 b4 fd ff ff       	call   f0104488 <stab_binsearch>
	if(lline>rline)
f01046d4:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01046d7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01046da:	83 c4 10             	add    $0x10,%esp
f01046dd:	39 c2                	cmp    %eax,%edx
f01046df:	0f 8f 7a 01 00 00    	jg     f010485f <debuginfo_eip+0x2e2>
	{
		return -1;
	}
	else
	{
		info->eip_line = stabs[rline].n_desc;
f01046e5:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01046e8:	0f b7 44 83 06       	movzwl 0x6(%ebx,%eax,4),%eax
f01046ed:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01046f0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01046f3:	89 d0                	mov    %edx,%eax
f01046f5:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01046f8:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
f01046fc:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0104700:	e9 ad 00 00 00       	jmp    f01047b2 <debuginfo_eip+0x235>
		if(user_mem_check(curenv,usd,sizeof(struct UserStabData),PTE_P|PTE_U) != 0)
f0104705:	6a 05                	push   $0x5
f0104707:	6a 10                	push   $0x10
f0104709:	68 00 00 20 00       	push   $0x200000
f010470e:	c7 c0 48 03 19 f0    	mov    $0xf0190348,%eax
f0104714:	ff 30                	pushl  (%eax)
f0104716:	e8 63 e9 ff ff       	call   f010307e <user_mem_check>
f010471b:	83 c4 10             	add    $0x10,%esp
f010471e:	85 c0                	test   %eax,%eax
f0104720:	0f 85 16 01 00 00    	jne    f010483c <debuginfo_eip+0x2bf>
		stabs = usd->stabs;
f0104726:	8b 15 00 00 20 00    	mov    0x200000,%edx
f010472c:	89 55 bc             	mov    %edx,-0x44(%ebp)
		stab_end = usd->stab_end;
f010472f:	8b 3d 04 00 20 00    	mov    0x200004,%edi
		stabstr = usd->stabstr;
f0104735:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f010473b:	89 4d b8             	mov    %ecx,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f010473e:	a1 0c 00 20 00       	mov    0x20000c,%eax
f0104743:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		if(user_mem_check(curenv,stabs,sizeof(struct Stab),PTE_P|PTE_U) != 0)
f0104746:	6a 05                	push   $0x5
f0104748:	6a 0c                	push   $0xc
f010474a:	52                   	push   %edx
f010474b:	c7 c0 48 03 19 f0    	mov    $0xf0190348,%eax
f0104751:	ff 30                	pushl  (%eax)
f0104753:	e8 26 e9 ff ff       	call   f010307e <user_mem_check>
f0104758:	83 c4 10             	add    $0x10,%esp
f010475b:	85 c0                	test   %eax,%eax
f010475d:	0f 85 e0 00 00 00    	jne    f0104843 <debuginfo_eip+0x2c6>
		if(user_mem_check(curenv,stabstr,stabstr_end-stabstr,PTE_P|PTE_U) != 0)
f0104763:	6a 05                	push   $0x5
f0104765:	8b 45 b4             	mov    -0x4c(%ebp),%eax
f0104768:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f010476b:	29 c8                	sub    %ecx,%eax
f010476d:	50                   	push   %eax
f010476e:	51                   	push   %ecx
f010476f:	c7 c0 48 03 19 f0    	mov    $0xf0190348,%eax
f0104775:	ff 30                	pushl  (%eax)
f0104777:	e8 02 e9 ff ff       	call   f010307e <user_mem_check>
f010477c:	83 c4 10             	add    $0x10,%esp
f010477f:	85 c0                	test   %eax,%eax
f0104781:	0f 84 63 fe ff ff    	je     f01045ea <debuginfo_eip+0x6d>
			return -1;
f0104787:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010478c:	e9 da 00 00 00       	jmp    f010486b <debuginfo_eip+0x2ee>
		info->eip_fn_addr = addr;
f0104791:	8b 45 08             	mov    0x8(%ebp),%eax
f0104794:	89 46 10             	mov    %eax,0x10(%esi)
		lline = lfile;
f0104797:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010479a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010479d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01047a0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01047a3:	e9 f3 fe ff ff       	jmp    f010469b <debuginfo_eip+0x11e>
f01047a8:	83 e8 01             	sub    $0x1,%eax
f01047ab:	83 ea 0c             	sub    $0xc,%edx
	while (lline >= lfile
f01047ae:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f01047b2:	89 45 c0             	mov    %eax,-0x40(%ebp)
f01047b5:	39 c7                	cmp    %eax,%edi
f01047b7:	7f 43                	jg     f01047fc <debuginfo_eip+0x27f>
	       && stabs[lline].n_type != N_SOL
f01047b9:	0f b6 0a             	movzbl (%edx),%ecx
f01047bc:	80 f9 84             	cmp    $0x84,%cl
f01047bf:	74 19                	je     f01047da <debuginfo_eip+0x25d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01047c1:	80 f9 64             	cmp    $0x64,%cl
f01047c4:	75 e2                	jne    f01047a8 <debuginfo_eip+0x22b>
f01047c6:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f01047ca:	74 dc                	je     f01047a8 <debuginfo_eip+0x22b>
f01047cc:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01047d0:	74 11                	je     f01047e3 <debuginfo_eip+0x266>
f01047d2:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01047d5:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01047d8:	eb 09                	jmp    f01047e3 <debuginfo_eip+0x266>
f01047da:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01047de:	74 03                	je     f01047e3 <debuginfo_eip+0x266>
f01047e0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01047e3:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01047e6:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01047e9:	8b 04 87             	mov    (%edi,%eax,4),%eax
f01047ec:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f01047ef:	8b 7d b8             	mov    -0x48(%ebp),%edi
f01047f2:	29 fa                	sub    %edi,%edx
f01047f4:	39 d0                	cmp    %edx,%eax
f01047f6:	73 04                	jae    f01047fc <debuginfo_eip+0x27f>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01047f8:	01 f8                	add    %edi,%eax
f01047fa:	89 06                	mov    %eax,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01047fc:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01047ff:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104802:	ba 00 00 00 00       	mov    $0x0,%edx
	if (lfun < rfun)
f0104807:	39 d8                	cmp    %ebx,%eax
f0104809:	7d 60                	jge    f010486b <debuginfo_eip+0x2ee>
		for (lline = lfun + 1;
f010480b:	8d 50 01             	lea    0x1(%eax),%edx
f010480e:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104811:	89 d0                	mov    %edx,%eax
f0104813:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104816:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0104819:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
f010481d:	eb 04                	jmp    f0104823 <debuginfo_eip+0x2a6>
			info->eip_fn_narg++;
f010481f:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0104823:	39 c3                	cmp    %eax,%ebx
f0104825:	7e 3f                	jle    f0104866 <debuginfo_eip+0x2e9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104827:	0f b6 0a             	movzbl (%edx),%ecx
f010482a:	83 c0 01             	add    $0x1,%eax
f010482d:	83 c2 0c             	add    $0xc,%edx
f0104830:	80 f9 a0             	cmp    $0xa0,%cl
f0104833:	74 ea                	je     f010481f <debuginfo_eip+0x2a2>
	return 0;
f0104835:	ba 00 00 00 00       	mov    $0x0,%edx
f010483a:	eb 2f                	jmp    f010486b <debuginfo_eip+0x2ee>
			return -1;
f010483c:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104841:	eb 28                	jmp    f010486b <debuginfo_eip+0x2ee>
			return -1;
f0104843:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104848:	eb 21                	jmp    f010486b <debuginfo_eip+0x2ee>
		return -1;
f010484a:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010484f:	eb 1a                	jmp    f010486b <debuginfo_eip+0x2ee>
f0104851:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104856:	eb 13                	jmp    f010486b <debuginfo_eip+0x2ee>
		return -1;
f0104858:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010485d:	eb 0c                	jmp    f010486b <debuginfo_eip+0x2ee>
		return -1;
f010485f:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104864:	eb 05                	jmp    f010486b <debuginfo_eip+0x2ee>
	return 0;
f0104866:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010486b:	89 d0                	mov    %edx,%eax
f010486d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104870:	5b                   	pop    %ebx
f0104871:	5e                   	pop    %esi
f0104872:	5f                   	pop    %edi
f0104873:	5d                   	pop    %ebp
f0104874:	c3                   	ret    

f0104875 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104875:	55                   	push   %ebp
f0104876:	89 e5                	mov    %esp,%ebp
f0104878:	57                   	push   %edi
f0104879:	56                   	push   %esi
f010487a:	53                   	push   %ebx
f010487b:	83 ec 2c             	sub    $0x2c,%esp
f010487e:	e8 fc e8 ff ff       	call   f010317f <__x86.get_pc_thunk.cx>
f0104883:	81 c1 99 97 08 00    	add    $0x89799,%ecx
f0104889:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010488c:	89 c7                	mov    %eax,%edi
f010488e:	89 d6                	mov    %edx,%esi
f0104890:	8b 45 08             	mov    0x8(%ebp),%eax
f0104893:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104896:	89 d1                	mov    %edx,%ecx
f0104898:	89 c2                	mov    %eax,%edx
f010489a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010489d:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01048a0:	8b 45 10             	mov    0x10(%ebp),%eax
f01048a3:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01048a6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01048a9:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01048b0:	39 c2                	cmp    %eax,%edx
f01048b2:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f01048b5:	72 41                	jb     f01048f8 <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01048b7:	83 ec 0c             	sub    $0xc,%esp
f01048ba:	ff 75 18             	pushl  0x18(%ebp)
f01048bd:	83 eb 01             	sub    $0x1,%ebx
f01048c0:	53                   	push   %ebx
f01048c1:	50                   	push   %eax
f01048c2:	83 ec 08             	sub    $0x8,%esp
f01048c5:	ff 75 e4             	pushl  -0x1c(%ebp)
f01048c8:	ff 75 e0             	pushl  -0x20(%ebp)
f01048cb:	ff 75 d4             	pushl  -0x2c(%ebp)
f01048ce:	ff 75 d0             	pushl  -0x30(%ebp)
f01048d1:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01048d4:	e8 97 0a 00 00       	call   f0105370 <__udivdi3>
f01048d9:	83 c4 18             	add    $0x18,%esp
f01048dc:	52                   	push   %edx
f01048dd:	50                   	push   %eax
f01048de:	89 f2                	mov    %esi,%edx
f01048e0:	89 f8                	mov    %edi,%eax
f01048e2:	e8 8e ff ff ff       	call   f0104875 <printnum>
f01048e7:	83 c4 20             	add    $0x20,%esp
f01048ea:	eb 13                	jmp    f01048ff <printnum+0x8a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01048ec:	83 ec 08             	sub    $0x8,%esp
f01048ef:	56                   	push   %esi
f01048f0:	ff 75 18             	pushl  0x18(%ebp)
f01048f3:	ff d7                	call   *%edi
f01048f5:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f01048f8:	83 eb 01             	sub    $0x1,%ebx
f01048fb:	85 db                	test   %ebx,%ebx
f01048fd:	7f ed                	jg     f01048ec <printnum+0x77>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01048ff:	83 ec 08             	sub    $0x8,%esp
f0104902:	56                   	push   %esi
f0104903:	83 ec 04             	sub    $0x4,%esp
f0104906:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104909:	ff 75 e0             	pushl  -0x20(%ebp)
f010490c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010490f:	ff 75 d0             	pushl  -0x30(%ebp)
f0104912:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104915:	e8 66 0b 00 00       	call   f0105480 <__umoddi3>
f010491a:	83 c4 14             	add    $0x14,%esp
f010491d:	0f be 84 03 16 8b f7 	movsbl -0x874ea(%ebx,%eax,1),%eax
f0104924:	ff 
f0104925:	50                   	push   %eax
f0104926:	ff d7                	call   *%edi
}
f0104928:	83 c4 10             	add    $0x10,%esp
f010492b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010492e:	5b                   	pop    %ebx
f010492f:	5e                   	pop    %esi
f0104930:	5f                   	pop    %edi
f0104931:	5d                   	pop    %ebp
f0104932:	c3                   	ret    

f0104933 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104933:	f3 0f 1e fb          	endbr32 
f0104937:	55                   	push   %ebp
f0104938:	89 e5                	mov    %esp,%ebp
f010493a:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010493d:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104941:	8b 10                	mov    (%eax),%edx
f0104943:	3b 50 04             	cmp    0x4(%eax),%edx
f0104946:	73 0a                	jae    f0104952 <sprintputch+0x1f>
		*b->buf++ = ch;
f0104948:	8d 4a 01             	lea    0x1(%edx),%ecx
f010494b:	89 08                	mov    %ecx,(%eax)
f010494d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104950:	88 02                	mov    %al,(%edx)
}
f0104952:	5d                   	pop    %ebp
f0104953:	c3                   	ret    

f0104954 <printfmt>:
{
f0104954:	f3 0f 1e fb          	endbr32 
f0104958:	55                   	push   %ebp
f0104959:	89 e5                	mov    %esp,%ebp
f010495b:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f010495e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104961:	50                   	push   %eax
f0104962:	ff 75 10             	pushl  0x10(%ebp)
f0104965:	ff 75 0c             	pushl  0xc(%ebp)
f0104968:	ff 75 08             	pushl  0x8(%ebp)
f010496b:	e8 05 00 00 00       	call   f0104975 <vprintfmt>
}
f0104970:	83 c4 10             	add    $0x10,%esp
f0104973:	c9                   	leave  
f0104974:	c3                   	ret    

f0104975 <vprintfmt>:
{
f0104975:	f3 0f 1e fb          	endbr32 
f0104979:	55                   	push   %ebp
f010497a:	89 e5                	mov    %esp,%ebp
f010497c:	57                   	push   %edi
f010497d:	56                   	push   %esi
f010497e:	53                   	push   %ebx
f010497f:	83 ec 3c             	sub    $0x3c,%esp
f0104982:	e8 c9 bd ff ff       	call   f0100750 <__x86.get_pc_thunk.ax>
f0104987:	05 95 96 08 00       	add    $0x89695,%eax
f010498c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010498f:	8b 75 08             	mov    0x8(%ebp),%esi
f0104992:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104995:	8b 5d 10             	mov    0x10(%ebp),%ebx
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104998:	8d 80 b4 20 00 00    	lea    0x20b4(%eax),%eax
f010499e:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01049a1:	e9 cd 03 00 00       	jmp    f0104d73 <.L25+0x48>
		padc = ' ';
f01049a6:	c6 45 cf 20          	movb   $0x20,-0x31(%ebp)
		altflag = 0;
f01049aa:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
		precision = -1;
f01049b1:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f01049b8:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		lflag = 0;
f01049bf:	b9 00 00 00 00       	mov    $0x0,%ecx
f01049c4:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f01049c7:	89 75 08             	mov    %esi,0x8(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01049ca:	8d 43 01             	lea    0x1(%ebx),%eax
f01049cd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01049d0:	0f b6 13             	movzbl (%ebx),%edx
f01049d3:	8d 42 dd             	lea    -0x23(%edx),%eax
f01049d6:	3c 55                	cmp    $0x55,%al
f01049d8:	0f 87 21 04 00 00    	ja     f0104dff <.L20>
f01049de:	0f b6 c0             	movzbl %al,%eax
f01049e1:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01049e4:	89 ce                	mov    %ecx,%esi
f01049e6:	03 b4 81 a0 8b f7 ff 	add    -0x87460(%ecx,%eax,4),%esi
f01049ed:	3e ff e6             	notrack jmp *%esi

f01049f0 <.L68>:
f01049f0:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '-';
f01049f3:	c6 45 cf 2d          	movb   $0x2d,-0x31(%ebp)
f01049f7:	eb d1                	jmp    f01049ca <vprintfmt+0x55>

f01049f9 <.L32>:
		switch (ch = *(unsigned char *) fmt++) {
f01049f9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01049fc:	c6 45 cf 30          	movb   $0x30,-0x31(%ebp)
f0104a00:	eb c8                	jmp    f01049ca <vprintfmt+0x55>

f0104a02 <.L31>:
f0104a02:	0f b6 d2             	movzbl %dl,%edx
f0104a05:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			for (precision = 0; ; ++fmt) {
f0104a08:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a0d:	8b 75 08             	mov    0x8(%ebp),%esi
				precision = precision * 10 + ch - '0';
f0104a10:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104a13:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0104a17:	0f be 13             	movsbl (%ebx),%edx
				if (ch < '0' || ch > '9')
f0104a1a:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0104a1d:	83 f9 09             	cmp    $0x9,%ecx
f0104a20:	77 58                	ja     f0104a7a <.L36+0xf>
			for (precision = 0; ; ++fmt) {
f0104a22:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f0104a25:	eb e9                	jmp    f0104a10 <.L31+0xe>

f0104a27 <.L34>:
			precision = va_arg(ap, int);
f0104a27:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a2a:	8b 00                	mov    (%eax),%eax
f0104a2c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104a2f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a32:	8d 40 04             	lea    0x4(%eax),%eax
f0104a35:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104a38:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if (width < 0)
f0104a3b:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0104a3f:	79 89                	jns    f01049ca <vprintfmt+0x55>
				width = precision, precision = -1;
f0104a41:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104a44:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104a47:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0104a4e:	e9 77 ff ff ff       	jmp    f01049ca <vprintfmt+0x55>

f0104a53 <.L33>:
f0104a53:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104a56:	85 c0                	test   %eax,%eax
f0104a58:	ba 00 00 00 00       	mov    $0x0,%edx
f0104a5d:	0f 49 d0             	cmovns %eax,%edx
f0104a60:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104a63:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f0104a66:	e9 5f ff ff ff       	jmp    f01049ca <vprintfmt+0x55>

f0104a6b <.L36>:
		switch (ch = *(unsigned char *) fmt++) {
f0104a6b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			altflag = 1;
f0104a6e:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0104a75:	e9 50 ff ff ff       	jmp    f01049ca <vprintfmt+0x55>
f0104a7a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104a7d:	89 75 08             	mov    %esi,0x8(%ebp)
f0104a80:	eb b9                	jmp    f0104a3b <.L34+0x14>

f0104a82 <.L27>:
			lflag++;
f0104a82:	83 45 c8 01          	addl   $0x1,-0x38(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104a86:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f0104a89:	e9 3c ff ff ff       	jmp    f01049ca <vprintfmt+0x55>

f0104a8e <.L30>:
f0104a8e:	8b 75 08             	mov    0x8(%ebp),%esi
			putch(va_arg(ap, int), putdat);
f0104a91:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a94:	8d 58 04             	lea    0x4(%eax),%ebx
f0104a97:	83 ec 08             	sub    $0x8,%esp
f0104a9a:	57                   	push   %edi
f0104a9b:	ff 30                	pushl  (%eax)
f0104a9d:	ff d6                	call   *%esi
			break;
f0104a9f:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0104aa2:	89 5d 14             	mov    %ebx,0x14(%ebp)
			break;
f0104aa5:	e9 c6 02 00 00       	jmp    f0104d70 <.L25+0x45>

f0104aaa <.L28>:
f0104aaa:	8b 75 08             	mov    0x8(%ebp),%esi
			err = va_arg(ap, int);
f0104aad:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ab0:	8d 58 04             	lea    0x4(%eax),%ebx
f0104ab3:	8b 00                	mov    (%eax),%eax
f0104ab5:	99                   	cltd   
f0104ab6:	31 d0                	xor    %edx,%eax
f0104ab8:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104aba:	83 f8 06             	cmp    $0x6,%eax
f0104abd:	7f 27                	jg     f0104ae6 <.L28+0x3c>
f0104abf:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0104ac2:	8b 14 82             	mov    (%edx,%eax,4),%edx
f0104ac5:	85 d2                	test   %edx,%edx
f0104ac7:	74 1d                	je     f0104ae6 <.L28+0x3c>
				printfmt(putch, putdat, "%s", p);
f0104ac9:	52                   	push   %edx
f0104aca:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104acd:	8d 80 15 83 f7 ff    	lea    -0x87ceb(%eax),%eax
f0104ad3:	50                   	push   %eax
f0104ad4:	57                   	push   %edi
f0104ad5:	56                   	push   %esi
f0104ad6:	e8 79 fe ff ff       	call   f0104954 <printfmt>
f0104adb:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0104ade:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0104ae1:	e9 8a 02 00 00       	jmp    f0104d70 <.L25+0x45>
				printfmt(putch, putdat, "error %d", err);
f0104ae6:	50                   	push   %eax
f0104ae7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104aea:	8d 80 2e 8b f7 ff    	lea    -0x874d2(%eax),%eax
f0104af0:	50                   	push   %eax
f0104af1:	57                   	push   %edi
f0104af2:	56                   	push   %esi
f0104af3:	e8 5c fe ff ff       	call   f0104954 <printfmt>
f0104af8:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0104afb:	89 5d 14             	mov    %ebx,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0104afe:	e9 6d 02 00 00       	jmp    f0104d70 <.L25+0x45>

f0104b03 <.L24>:
f0104b03:	8b 75 08             	mov    0x8(%ebp),%esi
			if ((p = va_arg(ap, char *)) == NULL)
f0104b06:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b09:	83 c0 04             	add    $0x4,%eax
f0104b0c:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0104b0f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b12:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f0104b14:	85 d2                	test   %edx,%edx
f0104b16:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104b19:	8d 80 27 8b f7 ff    	lea    -0x874d9(%eax),%eax
f0104b1f:	0f 45 c2             	cmovne %edx,%eax
f0104b22:	89 45 c8             	mov    %eax,-0x38(%ebp)
			if (width > 0 && padc != '-')
f0104b25:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0104b29:	7e 06                	jle    f0104b31 <.L24+0x2e>
f0104b2b:	80 7d cf 2d          	cmpb   $0x2d,-0x31(%ebp)
f0104b2f:	75 0d                	jne    f0104b3e <.L24+0x3b>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104b31:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0104b34:	89 c3                	mov    %eax,%ebx
f0104b36:	03 45 d4             	add    -0x2c(%ebp),%eax
f0104b39:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104b3c:	eb 58                	jmp    f0104b96 <.L24+0x93>
f0104b3e:	83 ec 08             	sub    $0x8,%esp
f0104b41:	ff 75 d8             	pushl  -0x28(%ebp)
f0104b44:	ff 75 c8             	pushl  -0x38(%ebp)
f0104b47:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104b4a:	e8 81 04 00 00       	call   f0104fd0 <strnlen>
f0104b4f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0104b52:	29 c2                	sub    %eax,%edx
f0104b54:	89 55 bc             	mov    %edx,-0x44(%ebp)
f0104b57:	83 c4 10             	add    $0x10,%esp
f0104b5a:	89 d3                	mov    %edx,%ebx
					putch(padc, putdat);
f0104b5c:	0f be 45 cf          	movsbl -0x31(%ebp),%eax
f0104b60:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0104b63:	85 db                	test   %ebx,%ebx
f0104b65:	7e 11                	jle    f0104b78 <.L24+0x75>
					putch(padc, putdat);
f0104b67:	83 ec 08             	sub    $0x8,%esp
f0104b6a:	57                   	push   %edi
f0104b6b:	ff 75 d4             	pushl  -0x2c(%ebp)
f0104b6e:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0104b70:	83 eb 01             	sub    $0x1,%ebx
f0104b73:	83 c4 10             	add    $0x10,%esp
f0104b76:	eb eb                	jmp    f0104b63 <.L24+0x60>
f0104b78:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104b7b:	85 d2                	test   %edx,%edx
f0104b7d:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b82:	0f 49 c2             	cmovns %edx,%eax
f0104b85:	29 c2                	sub    %eax,%edx
f0104b87:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104b8a:	eb a5                	jmp    f0104b31 <.L24+0x2e>
					putch(ch, putdat);
f0104b8c:	83 ec 08             	sub    $0x8,%esp
f0104b8f:	57                   	push   %edi
f0104b90:	52                   	push   %edx
f0104b91:	ff d6                	call   *%esi
f0104b93:	83 c4 10             	add    $0x10,%esp
f0104b96:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104b99:	29 d9                	sub    %ebx,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104b9b:	83 c3 01             	add    $0x1,%ebx
f0104b9e:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0104ba2:	0f be d0             	movsbl %al,%edx
f0104ba5:	85 d2                	test   %edx,%edx
f0104ba7:	74 4b                	je     f0104bf4 <.L24+0xf1>
f0104ba9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104bad:	78 06                	js     f0104bb5 <.L24+0xb2>
f0104baf:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f0104bb3:	78 1e                	js     f0104bd3 <.L24+0xd0>
				if (altflag && (ch < ' ' || ch > '~'))
f0104bb5:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0104bb9:	74 d1                	je     f0104b8c <.L24+0x89>
f0104bbb:	0f be c0             	movsbl %al,%eax
f0104bbe:	83 e8 20             	sub    $0x20,%eax
f0104bc1:	83 f8 5e             	cmp    $0x5e,%eax
f0104bc4:	76 c6                	jbe    f0104b8c <.L24+0x89>
					putch('?', putdat);
f0104bc6:	83 ec 08             	sub    $0x8,%esp
f0104bc9:	57                   	push   %edi
f0104bca:	6a 3f                	push   $0x3f
f0104bcc:	ff d6                	call   *%esi
f0104bce:	83 c4 10             	add    $0x10,%esp
f0104bd1:	eb c3                	jmp    f0104b96 <.L24+0x93>
f0104bd3:	89 cb                	mov    %ecx,%ebx
f0104bd5:	eb 0e                	jmp    f0104be5 <.L24+0xe2>
				putch(' ', putdat);
f0104bd7:	83 ec 08             	sub    $0x8,%esp
f0104bda:	57                   	push   %edi
f0104bdb:	6a 20                	push   $0x20
f0104bdd:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0104bdf:	83 eb 01             	sub    $0x1,%ebx
f0104be2:	83 c4 10             	add    $0x10,%esp
f0104be5:	85 db                	test   %ebx,%ebx
f0104be7:	7f ee                	jg     f0104bd7 <.L24+0xd4>
			if ((p = va_arg(ap, char *)) == NULL)
f0104be9:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0104bec:	89 45 14             	mov    %eax,0x14(%ebp)
f0104bef:	e9 7c 01 00 00       	jmp    f0104d70 <.L25+0x45>
f0104bf4:	89 cb                	mov    %ecx,%ebx
f0104bf6:	eb ed                	jmp    f0104be5 <.L24+0xe2>

f0104bf8 <.L29>:
f0104bf8:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0104bfb:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f0104bfe:	83 f9 01             	cmp    $0x1,%ecx
f0104c01:	7f 1b                	jg     f0104c1e <.L29+0x26>
	else if (lflag)
f0104c03:	85 c9                	test   %ecx,%ecx
f0104c05:	74 63                	je     f0104c6a <.L29+0x72>
		return va_arg(*ap, long);
f0104c07:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c0a:	8b 00                	mov    (%eax),%eax
f0104c0c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104c0f:	99                   	cltd   
f0104c10:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104c13:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c16:	8d 40 04             	lea    0x4(%eax),%eax
f0104c19:	89 45 14             	mov    %eax,0x14(%ebp)
f0104c1c:	eb 17                	jmp    f0104c35 <.L29+0x3d>
		return va_arg(*ap, long long);
f0104c1e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c21:	8b 50 04             	mov    0x4(%eax),%edx
f0104c24:	8b 00                	mov    (%eax),%eax
f0104c26:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104c29:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104c2c:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c2f:	8d 40 08             	lea    0x8(%eax),%eax
f0104c32:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0104c35:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104c38:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0104c3b:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f0104c40:	85 c9                	test   %ecx,%ecx
f0104c42:	0f 89 0e 01 00 00    	jns    f0104d56 <.L25+0x2b>
				putch('-', putdat);
f0104c48:	83 ec 08             	sub    $0x8,%esp
f0104c4b:	57                   	push   %edi
f0104c4c:	6a 2d                	push   $0x2d
f0104c4e:	ff d6                	call   *%esi
				num = -(long long) num;
f0104c50:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104c53:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104c56:	f7 da                	neg    %edx
f0104c58:	83 d1 00             	adc    $0x0,%ecx
f0104c5b:	f7 d9                	neg    %ecx
f0104c5d:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0104c60:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104c65:	e9 ec 00 00 00       	jmp    f0104d56 <.L25+0x2b>
		return va_arg(*ap, int);
f0104c6a:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c6d:	8b 00                	mov    (%eax),%eax
f0104c6f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104c72:	99                   	cltd   
f0104c73:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104c76:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c79:	8d 40 04             	lea    0x4(%eax),%eax
f0104c7c:	89 45 14             	mov    %eax,0x14(%ebp)
f0104c7f:	eb b4                	jmp    f0104c35 <.L29+0x3d>

f0104c81 <.L23>:
f0104c81:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0104c84:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f0104c87:	83 f9 01             	cmp    $0x1,%ecx
f0104c8a:	7f 1e                	jg     f0104caa <.L23+0x29>
	else if (lflag)
f0104c8c:	85 c9                	test   %ecx,%ecx
f0104c8e:	74 32                	je     f0104cc2 <.L23+0x41>
		return va_arg(*ap, unsigned long);
f0104c90:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c93:	8b 10                	mov    (%eax),%edx
f0104c95:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104c9a:	8d 40 04             	lea    0x4(%eax),%eax
f0104c9d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104ca0:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long);
f0104ca5:	e9 ac 00 00 00       	jmp    f0104d56 <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f0104caa:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cad:	8b 10                	mov    (%eax),%edx
f0104caf:	8b 48 04             	mov    0x4(%eax),%ecx
f0104cb2:	8d 40 08             	lea    0x8(%eax),%eax
f0104cb5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104cb8:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long long);
f0104cbd:	e9 94 00 00 00       	jmp    f0104d56 <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f0104cc2:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cc5:	8b 10                	mov    (%eax),%edx
f0104cc7:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104ccc:	8d 40 04             	lea    0x4(%eax),%eax
f0104ccf:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104cd2:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned int);
f0104cd7:	eb 7d                	jmp    f0104d56 <.L25+0x2b>

f0104cd9 <.L26>:
f0104cd9:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0104cdc:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f0104cdf:	83 f9 01             	cmp    $0x1,%ecx
f0104ce2:	7f 1b                	jg     f0104cff <.L26+0x26>
	else if (lflag)
f0104ce4:	85 c9                	test   %ecx,%ecx
f0104ce6:	74 2c                	je     f0104d14 <.L26+0x3b>
		return va_arg(*ap, unsigned long);
f0104ce8:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ceb:	8b 10                	mov    (%eax),%edx
f0104ced:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104cf2:	8d 40 04             	lea    0x4(%eax),%eax
f0104cf5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0104cf8:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long);
f0104cfd:	eb 57                	jmp    f0104d56 <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f0104cff:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d02:	8b 10                	mov    (%eax),%edx
f0104d04:	8b 48 04             	mov    0x4(%eax),%ecx
f0104d07:	8d 40 08             	lea    0x8(%eax),%eax
f0104d0a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0104d0d:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long long);
f0104d12:	eb 42                	jmp    f0104d56 <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f0104d14:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d17:	8b 10                	mov    (%eax),%edx
f0104d19:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104d1e:	8d 40 04             	lea    0x4(%eax),%eax
f0104d21:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0104d24:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned int);
f0104d29:	eb 2b                	jmp    f0104d56 <.L25+0x2b>

f0104d2b <.L25>:
f0104d2b:	8b 75 08             	mov    0x8(%ebp),%esi
			putch('0', putdat);
f0104d2e:	83 ec 08             	sub    $0x8,%esp
f0104d31:	57                   	push   %edi
f0104d32:	6a 30                	push   $0x30
f0104d34:	ff d6                	call   *%esi
			putch('x', putdat);
f0104d36:	83 c4 08             	add    $0x8,%esp
f0104d39:	57                   	push   %edi
f0104d3a:	6a 78                	push   $0x78
f0104d3c:	ff d6                	call   *%esi
			num = (unsigned long long)
f0104d3e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d41:	8b 10                	mov    (%eax),%edx
f0104d43:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0104d48:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0104d4b:	8d 40 04             	lea    0x4(%eax),%eax
f0104d4e:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104d51:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0104d56:	83 ec 0c             	sub    $0xc,%esp
f0104d59:	0f be 5d cf          	movsbl -0x31(%ebp),%ebx
f0104d5d:	53                   	push   %ebx
f0104d5e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0104d61:	50                   	push   %eax
f0104d62:	51                   	push   %ecx
f0104d63:	52                   	push   %edx
f0104d64:	89 fa                	mov    %edi,%edx
f0104d66:	89 f0                	mov    %esi,%eax
f0104d68:	e8 08 fb ff ff       	call   f0104875 <printnum>
			break;
f0104d6d:	83 c4 20             	add    $0x20,%esp
			if ((p = va_arg(ap, char *)) == NULL)
f0104d70:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104d73:	83 c3 01             	add    $0x1,%ebx
f0104d76:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0104d7a:	83 f8 25             	cmp    $0x25,%eax
f0104d7d:	0f 84 23 fc ff ff    	je     f01049a6 <vprintfmt+0x31>
			if (ch == '\0')
f0104d83:	85 c0                	test   %eax,%eax
f0104d85:	0f 84 97 00 00 00    	je     f0104e22 <.L20+0x23>
			putch(ch, putdat);
f0104d8b:	83 ec 08             	sub    $0x8,%esp
f0104d8e:	57                   	push   %edi
f0104d8f:	50                   	push   %eax
f0104d90:	ff d6                	call   *%esi
f0104d92:	83 c4 10             	add    $0x10,%esp
f0104d95:	eb dc                	jmp    f0104d73 <.L25+0x48>

f0104d97 <.L21>:
f0104d97:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0104d9a:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f0104d9d:	83 f9 01             	cmp    $0x1,%ecx
f0104da0:	7f 1b                	jg     f0104dbd <.L21+0x26>
	else if (lflag)
f0104da2:	85 c9                	test   %ecx,%ecx
f0104da4:	74 2c                	je     f0104dd2 <.L21+0x3b>
		return va_arg(*ap, unsigned long);
f0104da6:	8b 45 14             	mov    0x14(%ebp),%eax
f0104da9:	8b 10                	mov    (%eax),%edx
f0104dab:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104db0:	8d 40 04             	lea    0x4(%eax),%eax
f0104db3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104db6:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long);
f0104dbb:	eb 99                	jmp    f0104d56 <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f0104dbd:	8b 45 14             	mov    0x14(%ebp),%eax
f0104dc0:	8b 10                	mov    (%eax),%edx
f0104dc2:	8b 48 04             	mov    0x4(%eax),%ecx
f0104dc5:	8d 40 08             	lea    0x8(%eax),%eax
f0104dc8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104dcb:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long long);
f0104dd0:	eb 84                	jmp    f0104d56 <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f0104dd2:	8b 45 14             	mov    0x14(%ebp),%eax
f0104dd5:	8b 10                	mov    (%eax),%edx
f0104dd7:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104ddc:	8d 40 04             	lea    0x4(%eax),%eax
f0104ddf:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104de2:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned int);
f0104de7:	e9 6a ff ff ff       	jmp    f0104d56 <.L25+0x2b>

f0104dec <.L35>:
f0104dec:	8b 75 08             	mov    0x8(%ebp),%esi
			putch(ch, putdat);
f0104def:	83 ec 08             	sub    $0x8,%esp
f0104df2:	57                   	push   %edi
f0104df3:	6a 25                	push   $0x25
f0104df5:	ff d6                	call   *%esi
			break;
f0104df7:	83 c4 10             	add    $0x10,%esp
f0104dfa:	e9 71 ff ff ff       	jmp    f0104d70 <.L25+0x45>

f0104dff <.L20>:
f0104dff:	8b 75 08             	mov    0x8(%ebp),%esi
			putch('%', putdat);
f0104e02:	83 ec 08             	sub    $0x8,%esp
f0104e05:	57                   	push   %edi
f0104e06:	6a 25                	push   $0x25
f0104e08:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104e0a:	83 c4 10             	add    $0x10,%esp
f0104e0d:	89 d8                	mov    %ebx,%eax
f0104e0f:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0104e13:	74 05                	je     f0104e1a <.L20+0x1b>
f0104e15:	83 e8 01             	sub    $0x1,%eax
f0104e18:	eb f5                	jmp    f0104e0f <.L20+0x10>
f0104e1a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104e1d:	e9 4e ff ff ff       	jmp    f0104d70 <.L25+0x45>
}
f0104e22:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104e25:	5b                   	pop    %ebx
f0104e26:	5e                   	pop    %esi
f0104e27:	5f                   	pop    %edi
f0104e28:	5d                   	pop    %ebp
f0104e29:	c3                   	ret    

f0104e2a <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104e2a:	f3 0f 1e fb          	endbr32 
f0104e2e:	55                   	push   %ebp
f0104e2f:	89 e5                	mov    %esp,%ebp
f0104e31:	53                   	push   %ebx
f0104e32:	83 ec 14             	sub    $0x14,%esp
f0104e35:	e8 39 b3 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0104e3a:	81 c3 e2 91 08 00    	add    $0x891e2,%ebx
f0104e40:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e43:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104e46:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104e49:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104e4d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104e50:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104e57:	85 c0                	test   %eax,%eax
f0104e59:	74 2b                	je     f0104e86 <vsnprintf+0x5c>
f0104e5b:	85 d2                	test   %edx,%edx
f0104e5d:	7e 27                	jle    f0104e86 <vsnprintf+0x5c>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104e5f:	ff 75 14             	pushl  0x14(%ebp)
f0104e62:	ff 75 10             	pushl  0x10(%ebp)
f0104e65:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104e68:	50                   	push   %eax
f0104e69:	8d 83 17 69 f7 ff    	lea    -0x896e9(%ebx),%eax
f0104e6f:	50                   	push   %eax
f0104e70:	e8 00 fb ff ff       	call   f0104975 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104e75:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104e78:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104e7b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104e7e:	83 c4 10             	add    $0x10,%esp
}
f0104e81:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104e84:	c9                   	leave  
f0104e85:	c3                   	ret    
		return -E_INVAL;
f0104e86:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104e8b:	eb f4                	jmp    f0104e81 <vsnprintf+0x57>

f0104e8d <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104e8d:	f3 0f 1e fb          	endbr32 
f0104e91:	55                   	push   %ebp
f0104e92:	89 e5                	mov    %esp,%ebp
f0104e94:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104e97:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104e9a:	50                   	push   %eax
f0104e9b:	ff 75 10             	pushl  0x10(%ebp)
f0104e9e:	ff 75 0c             	pushl  0xc(%ebp)
f0104ea1:	ff 75 08             	pushl  0x8(%ebp)
f0104ea4:	e8 81 ff ff ff       	call   f0104e2a <vsnprintf>
	va_end(ap);

	return rc;
}
f0104ea9:	c9                   	leave  
f0104eaa:	c3                   	ret    

f0104eab <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104eab:	f3 0f 1e fb          	endbr32 
f0104eaf:	55                   	push   %ebp
f0104eb0:	89 e5                	mov    %esp,%ebp
f0104eb2:	57                   	push   %edi
f0104eb3:	56                   	push   %esi
f0104eb4:	53                   	push   %ebx
f0104eb5:	83 ec 1c             	sub    $0x1c,%esp
f0104eb8:	e8 b6 b2 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0104ebd:	81 c3 5f 91 08 00    	add    $0x8915f,%ebx
f0104ec3:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104ec6:	85 c0                	test   %eax,%eax
f0104ec8:	74 13                	je     f0104edd <readline+0x32>
		cprintf("%s", prompt);
f0104eca:	83 ec 08             	sub    $0x8,%esp
f0104ecd:	50                   	push   %eax
f0104ece:	8d 83 15 83 f7 ff    	lea    -0x87ceb(%ebx),%eax
f0104ed4:	50                   	push   %eax
f0104ed5:	e8 5e eb ff ff       	call   f0103a38 <cprintf>
f0104eda:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104edd:	83 ec 0c             	sub    $0xc,%esp
f0104ee0:	6a 00                	push   $0x0
f0104ee2:	e8 5f b8 ff ff       	call   f0100746 <iscons>
f0104ee7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104eea:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0104eed:	bf 00 00 00 00       	mov    $0x0,%edi
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
			if (echoing)
				cputchar(c);
			buf[i++] = c;
f0104ef2:	8d 83 e4 2b 00 00    	lea    0x2be4(%ebx),%eax
f0104ef8:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104efb:	eb 51                	jmp    f0104f4e <readline+0xa3>
			cprintf("read error: %e\n", c);
f0104efd:	83 ec 08             	sub    $0x8,%esp
f0104f00:	50                   	push   %eax
f0104f01:	8d 83 f8 8c f7 ff    	lea    -0x87308(%ebx),%eax
f0104f07:	50                   	push   %eax
f0104f08:	e8 2b eb ff ff       	call   f0103a38 <cprintf>
			return NULL;
f0104f0d:	83 c4 10             	add    $0x10,%esp
f0104f10:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0104f15:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104f18:	5b                   	pop    %ebx
f0104f19:	5e                   	pop    %esi
f0104f1a:	5f                   	pop    %edi
f0104f1b:	5d                   	pop    %ebp
f0104f1c:	c3                   	ret    
			if (echoing)
f0104f1d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104f21:	75 05                	jne    f0104f28 <readline+0x7d>
			i--;
f0104f23:	83 ef 01             	sub    $0x1,%edi
f0104f26:	eb 26                	jmp    f0104f4e <readline+0xa3>
				cputchar('\b');
f0104f28:	83 ec 0c             	sub    $0xc,%esp
f0104f2b:	6a 08                	push   $0x8
f0104f2d:	e8 eb b7 ff ff       	call   f010071d <cputchar>
f0104f32:	83 c4 10             	add    $0x10,%esp
f0104f35:	eb ec                	jmp    f0104f23 <readline+0x78>
				cputchar(c);
f0104f37:	83 ec 0c             	sub    $0xc,%esp
f0104f3a:	56                   	push   %esi
f0104f3b:	e8 dd b7 ff ff       	call   f010071d <cputchar>
f0104f40:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104f43:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104f46:	89 f0                	mov    %esi,%eax
f0104f48:	88 04 39             	mov    %al,(%ecx,%edi,1)
f0104f4b:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0104f4e:	e8 de b7 ff ff       	call   f0100731 <getchar>
f0104f53:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0104f55:	85 c0                	test   %eax,%eax
f0104f57:	78 a4                	js     f0104efd <readline+0x52>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104f59:	83 f8 08             	cmp    $0x8,%eax
f0104f5c:	0f 94 c2             	sete   %dl
f0104f5f:	83 f8 7f             	cmp    $0x7f,%eax
f0104f62:	0f 94 c0             	sete   %al
f0104f65:	08 c2                	or     %al,%dl
f0104f67:	74 04                	je     f0104f6d <readline+0xc2>
f0104f69:	85 ff                	test   %edi,%edi
f0104f6b:	7f b0                	jg     f0104f1d <readline+0x72>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104f6d:	83 fe 1f             	cmp    $0x1f,%esi
f0104f70:	7e 10                	jle    f0104f82 <readline+0xd7>
f0104f72:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0104f78:	7f 08                	jg     f0104f82 <readline+0xd7>
			if (echoing)
f0104f7a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104f7e:	74 c3                	je     f0104f43 <readline+0x98>
f0104f80:	eb b5                	jmp    f0104f37 <readline+0x8c>
		} else if (c == '\n' || c == '\r') {
f0104f82:	83 fe 0a             	cmp    $0xa,%esi
f0104f85:	74 05                	je     f0104f8c <readline+0xe1>
f0104f87:	83 fe 0d             	cmp    $0xd,%esi
f0104f8a:	75 c2                	jne    f0104f4e <readline+0xa3>
			if (echoing)
f0104f8c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104f90:	75 13                	jne    f0104fa5 <readline+0xfa>
			buf[i] = 0;
f0104f92:	c6 84 3b e4 2b 00 00 	movb   $0x0,0x2be4(%ebx,%edi,1)
f0104f99:	00 
			return buf;
f0104f9a:	8d 83 e4 2b 00 00    	lea    0x2be4(%ebx),%eax
f0104fa0:	e9 70 ff ff ff       	jmp    f0104f15 <readline+0x6a>
				cputchar('\n');
f0104fa5:	83 ec 0c             	sub    $0xc,%esp
f0104fa8:	6a 0a                	push   $0xa
f0104faa:	e8 6e b7 ff ff       	call   f010071d <cputchar>
f0104faf:	83 c4 10             	add    $0x10,%esp
f0104fb2:	eb de                	jmp    f0104f92 <readline+0xe7>

f0104fb4 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104fb4:	f3 0f 1e fb          	endbr32 
f0104fb8:	55                   	push   %ebp
f0104fb9:	89 e5                	mov    %esp,%ebp
f0104fbb:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104fbe:	b8 00 00 00 00       	mov    $0x0,%eax
f0104fc3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104fc7:	74 05                	je     f0104fce <strlen+0x1a>
		n++;
f0104fc9:	83 c0 01             	add    $0x1,%eax
f0104fcc:	eb f5                	jmp    f0104fc3 <strlen+0xf>
	return n;
}
f0104fce:	5d                   	pop    %ebp
f0104fcf:	c3                   	ret    

f0104fd0 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104fd0:	f3 0f 1e fb          	endbr32 
f0104fd4:	55                   	push   %ebp
f0104fd5:	89 e5                	mov    %esp,%ebp
f0104fd7:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104fda:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104fdd:	b8 00 00 00 00       	mov    $0x0,%eax
f0104fe2:	39 d0                	cmp    %edx,%eax
f0104fe4:	74 0d                	je     f0104ff3 <strnlen+0x23>
f0104fe6:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104fea:	74 05                	je     f0104ff1 <strnlen+0x21>
		n++;
f0104fec:	83 c0 01             	add    $0x1,%eax
f0104fef:	eb f1                	jmp    f0104fe2 <strnlen+0x12>
f0104ff1:	89 c2                	mov    %eax,%edx
	return n;
}
f0104ff3:	89 d0                	mov    %edx,%eax
f0104ff5:	5d                   	pop    %ebp
f0104ff6:	c3                   	ret    

f0104ff7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104ff7:	f3 0f 1e fb          	endbr32 
f0104ffb:	55                   	push   %ebp
f0104ffc:	89 e5                	mov    %esp,%ebp
f0104ffe:	53                   	push   %ebx
f0104fff:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105002:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0105005:	b8 00 00 00 00       	mov    $0x0,%eax
f010500a:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f010500e:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f0105011:	83 c0 01             	add    $0x1,%eax
f0105014:	84 d2                	test   %dl,%dl
f0105016:	75 f2                	jne    f010500a <strcpy+0x13>
		/* do nothing */;
	return ret;
}
f0105018:	89 c8                	mov    %ecx,%eax
f010501a:	5b                   	pop    %ebx
f010501b:	5d                   	pop    %ebp
f010501c:	c3                   	ret    

f010501d <strcat>:

char *
strcat(char *dst, const char *src)
{
f010501d:	f3 0f 1e fb          	endbr32 
f0105021:	55                   	push   %ebp
f0105022:	89 e5                	mov    %esp,%ebp
f0105024:	53                   	push   %ebx
f0105025:	83 ec 10             	sub    $0x10,%esp
f0105028:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010502b:	53                   	push   %ebx
f010502c:	e8 83 ff ff ff       	call   f0104fb4 <strlen>
f0105031:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f0105034:	ff 75 0c             	pushl  0xc(%ebp)
f0105037:	01 d8                	add    %ebx,%eax
f0105039:	50                   	push   %eax
f010503a:	e8 b8 ff ff ff       	call   f0104ff7 <strcpy>
	return dst;
}
f010503f:	89 d8                	mov    %ebx,%eax
f0105041:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0105044:	c9                   	leave  
f0105045:	c3                   	ret    

f0105046 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105046:	f3 0f 1e fb          	endbr32 
f010504a:	55                   	push   %ebp
f010504b:	89 e5                	mov    %esp,%ebp
f010504d:	56                   	push   %esi
f010504e:	53                   	push   %ebx
f010504f:	8b 75 08             	mov    0x8(%ebp),%esi
f0105052:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105055:	89 f3                	mov    %esi,%ebx
f0105057:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010505a:	89 f0                	mov    %esi,%eax
f010505c:	39 d8                	cmp    %ebx,%eax
f010505e:	74 11                	je     f0105071 <strncpy+0x2b>
		*dst++ = *src;
f0105060:	83 c0 01             	add    $0x1,%eax
f0105063:	0f b6 0a             	movzbl (%edx),%ecx
f0105066:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0105069:	80 f9 01             	cmp    $0x1,%cl
f010506c:	83 da ff             	sbb    $0xffffffff,%edx
f010506f:	eb eb                	jmp    f010505c <strncpy+0x16>
	}
	return ret;
}
f0105071:	89 f0                	mov    %esi,%eax
f0105073:	5b                   	pop    %ebx
f0105074:	5e                   	pop    %esi
f0105075:	5d                   	pop    %ebp
f0105076:	c3                   	ret    

f0105077 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0105077:	f3 0f 1e fb          	endbr32 
f010507b:	55                   	push   %ebp
f010507c:	89 e5                	mov    %esp,%ebp
f010507e:	56                   	push   %esi
f010507f:	53                   	push   %ebx
f0105080:	8b 75 08             	mov    0x8(%ebp),%esi
f0105083:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105086:	8b 55 10             	mov    0x10(%ebp),%edx
f0105089:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010508b:	85 d2                	test   %edx,%edx
f010508d:	74 21                	je     f01050b0 <strlcpy+0x39>
f010508f:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0105093:	89 f2                	mov    %esi,%edx
		while (--size > 0 && *src != '\0')
f0105095:	39 c2                	cmp    %eax,%edx
f0105097:	74 14                	je     f01050ad <strlcpy+0x36>
f0105099:	0f b6 19             	movzbl (%ecx),%ebx
f010509c:	84 db                	test   %bl,%bl
f010509e:	74 0b                	je     f01050ab <strlcpy+0x34>
			*dst++ = *src++;
f01050a0:	83 c1 01             	add    $0x1,%ecx
f01050a3:	83 c2 01             	add    $0x1,%edx
f01050a6:	88 5a ff             	mov    %bl,-0x1(%edx)
f01050a9:	eb ea                	jmp    f0105095 <strlcpy+0x1e>
f01050ab:	89 d0                	mov    %edx,%eax
		*dst = '\0';
f01050ad:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01050b0:	29 f0                	sub    %esi,%eax
}
f01050b2:	5b                   	pop    %ebx
f01050b3:	5e                   	pop    %esi
f01050b4:	5d                   	pop    %ebp
f01050b5:	c3                   	ret    

f01050b6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01050b6:	f3 0f 1e fb          	endbr32 
f01050ba:	55                   	push   %ebp
f01050bb:	89 e5                	mov    %esp,%ebp
f01050bd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01050c0:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01050c3:	0f b6 01             	movzbl (%ecx),%eax
f01050c6:	84 c0                	test   %al,%al
f01050c8:	74 0c                	je     f01050d6 <strcmp+0x20>
f01050ca:	3a 02                	cmp    (%edx),%al
f01050cc:	75 08                	jne    f01050d6 <strcmp+0x20>
		p++, q++;
f01050ce:	83 c1 01             	add    $0x1,%ecx
f01050d1:	83 c2 01             	add    $0x1,%edx
f01050d4:	eb ed                	jmp    f01050c3 <strcmp+0xd>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01050d6:	0f b6 c0             	movzbl %al,%eax
f01050d9:	0f b6 12             	movzbl (%edx),%edx
f01050dc:	29 d0                	sub    %edx,%eax
}
f01050de:	5d                   	pop    %ebp
f01050df:	c3                   	ret    

f01050e0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01050e0:	f3 0f 1e fb          	endbr32 
f01050e4:	55                   	push   %ebp
f01050e5:	89 e5                	mov    %esp,%ebp
f01050e7:	53                   	push   %ebx
f01050e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01050eb:	8b 55 0c             	mov    0xc(%ebp),%edx
f01050ee:	89 c3                	mov    %eax,%ebx
f01050f0:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01050f3:	eb 06                	jmp    f01050fb <strncmp+0x1b>
		n--, p++, q++;
f01050f5:	83 c0 01             	add    $0x1,%eax
f01050f8:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01050fb:	39 d8                	cmp    %ebx,%eax
f01050fd:	74 16                	je     f0105115 <strncmp+0x35>
f01050ff:	0f b6 08             	movzbl (%eax),%ecx
f0105102:	84 c9                	test   %cl,%cl
f0105104:	74 04                	je     f010510a <strncmp+0x2a>
f0105106:	3a 0a                	cmp    (%edx),%cl
f0105108:	74 eb                	je     f01050f5 <strncmp+0x15>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010510a:	0f b6 00             	movzbl (%eax),%eax
f010510d:	0f b6 12             	movzbl (%edx),%edx
f0105110:	29 d0                	sub    %edx,%eax
}
f0105112:	5b                   	pop    %ebx
f0105113:	5d                   	pop    %ebp
f0105114:	c3                   	ret    
		return 0;
f0105115:	b8 00 00 00 00       	mov    $0x0,%eax
f010511a:	eb f6                	jmp    f0105112 <strncmp+0x32>

f010511c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010511c:	f3 0f 1e fb          	endbr32 
f0105120:	55                   	push   %ebp
f0105121:	89 e5                	mov    %esp,%ebp
f0105123:	8b 45 08             	mov    0x8(%ebp),%eax
f0105126:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010512a:	0f b6 10             	movzbl (%eax),%edx
f010512d:	84 d2                	test   %dl,%dl
f010512f:	74 09                	je     f010513a <strchr+0x1e>
		if (*s == c)
f0105131:	38 ca                	cmp    %cl,%dl
f0105133:	74 0a                	je     f010513f <strchr+0x23>
	for (; *s; s++)
f0105135:	83 c0 01             	add    $0x1,%eax
f0105138:	eb f0                	jmp    f010512a <strchr+0xe>
			return (char *) s;
	return 0;
f010513a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010513f:	5d                   	pop    %ebp
f0105140:	c3                   	ret    

f0105141 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105141:	f3 0f 1e fb          	endbr32 
f0105145:	55                   	push   %ebp
f0105146:	89 e5                	mov    %esp,%ebp
f0105148:	8b 45 08             	mov    0x8(%ebp),%eax
f010514b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010514f:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0105152:	38 ca                	cmp    %cl,%dl
f0105154:	74 09                	je     f010515f <strfind+0x1e>
f0105156:	84 d2                	test   %dl,%dl
f0105158:	74 05                	je     f010515f <strfind+0x1e>
	for (; *s; s++)
f010515a:	83 c0 01             	add    $0x1,%eax
f010515d:	eb f0                	jmp    f010514f <strfind+0xe>
			break;
	return (char *) s;
}
f010515f:	5d                   	pop    %ebp
f0105160:	c3                   	ret    

f0105161 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105161:	f3 0f 1e fb          	endbr32 
f0105165:	55                   	push   %ebp
f0105166:	89 e5                	mov    %esp,%ebp
f0105168:	57                   	push   %edi
f0105169:	56                   	push   %esi
f010516a:	53                   	push   %ebx
f010516b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010516e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105171:	85 c9                	test   %ecx,%ecx
f0105173:	74 31                	je     f01051a6 <memset+0x45>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105175:	89 f8                	mov    %edi,%eax
f0105177:	09 c8                	or     %ecx,%eax
f0105179:	a8 03                	test   $0x3,%al
f010517b:	75 23                	jne    f01051a0 <memset+0x3f>
		c &= 0xFF;
f010517d:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105181:	89 d3                	mov    %edx,%ebx
f0105183:	c1 e3 08             	shl    $0x8,%ebx
f0105186:	89 d0                	mov    %edx,%eax
f0105188:	c1 e0 18             	shl    $0x18,%eax
f010518b:	89 d6                	mov    %edx,%esi
f010518d:	c1 e6 10             	shl    $0x10,%esi
f0105190:	09 f0                	or     %esi,%eax
f0105192:	09 c2                	or     %eax,%edx
f0105194:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0105196:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0105199:	89 d0                	mov    %edx,%eax
f010519b:	fc                   	cld    
f010519c:	f3 ab                	rep stos %eax,%es:(%edi)
f010519e:	eb 06                	jmp    f01051a6 <memset+0x45>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01051a0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01051a3:	fc                   	cld    
f01051a4:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01051a6:	89 f8                	mov    %edi,%eax
f01051a8:	5b                   	pop    %ebx
f01051a9:	5e                   	pop    %esi
f01051aa:	5f                   	pop    %edi
f01051ab:	5d                   	pop    %ebp
f01051ac:	c3                   	ret    

f01051ad <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01051ad:	f3 0f 1e fb          	endbr32 
f01051b1:	55                   	push   %ebp
f01051b2:	89 e5                	mov    %esp,%ebp
f01051b4:	57                   	push   %edi
f01051b5:	56                   	push   %esi
f01051b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01051b9:	8b 75 0c             	mov    0xc(%ebp),%esi
f01051bc:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01051bf:	39 c6                	cmp    %eax,%esi
f01051c1:	73 32                	jae    f01051f5 <memmove+0x48>
f01051c3:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01051c6:	39 c2                	cmp    %eax,%edx
f01051c8:	76 2b                	jbe    f01051f5 <memmove+0x48>
		s += n;
		d += n;
f01051ca:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01051cd:	89 fe                	mov    %edi,%esi
f01051cf:	09 ce                	or     %ecx,%esi
f01051d1:	09 d6                	or     %edx,%esi
f01051d3:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01051d9:	75 0e                	jne    f01051e9 <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01051db:	83 ef 04             	sub    $0x4,%edi
f01051de:	8d 72 fc             	lea    -0x4(%edx),%esi
f01051e1:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01051e4:	fd                   	std    
f01051e5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01051e7:	eb 09                	jmp    f01051f2 <memmove+0x45>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01051e9:	83 ef 01             	sub    $0x1,%edi
f01051ec:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01051ef:	fd                   	std    
f01051f0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01051f2:	fc                   	cld    
f01051f3:	eb 1a                	jmp    f010520f <memmove+0x62>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01051f5:	89 c2                	mov    %eax,%edx
f01051f7:	09 ca                	or     %ecx,%edx
f01051f9:	09 f2                	or     %esi,%edx
f01051fb:	f6 c2 03             	test   $0x3,%dl
f01051fe:	75 0a                	jne    f010520a <memmove+0x5d>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105200:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0105203:	89 c7                	mov    %eax,%edi
f0105205:	fc                   	cld    
f0105206:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105208:	eb 05                	jmp    f010520f <memmove+0x62>
		else
			asm volatile("cld; rep movsb\n"
f010520a:	89 c7                	mov    %eax,%edi
f010520c:	fc                   	cld    
f010520d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010520f:	5e                   	pop    %esi
f0105210:	5f                   	pop    %edi
f0105211:	5d                   	pop    %ebp
f0105212:	c3                   	ret    

f0105213 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105213:	f3 0f 1e fb          	endbr32 
f0105217:	55                   	push   %ebp
f0105218:	89 e5                	mov    %esp,%ebp
f010521a:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010521d:	ff 75 10             	pushl  0x10(%ebp)
f0105220:	ff 75 0c             	pushl  0xc(%ebp)
f0105223:	ff 75 08             	pushl  0x8(%ebp)
f0105226:	e8 82 ff ff ff       	call   f01051ad <memmove>
}
f010522b:	c9                   	leave  
f010522c:	c3                   	ret    

f010522d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010522d:	f3 0f 1e fb          	endbr32 
f0105231:	55                   	push   %ebp
f0105232:	89 e5                	mov    %esp,%ebp
f0105234:	56                   	push   %esi
f0105235:	53                   	push   %ebx
f0105236:	8b 45 08             	mov    0x8(%ebp),%eax
f0105239:	8b 55 0c             	mov    0xc(%ebp),%edx
f010523c:	89 c6                	mov    %eax,%esi
f010523e:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105241:	39 f0                	cmp    %esi,%eax
f0105243:	74 1c                	je     f0105261 <memcmp+0x34>
		if (*s1 != *s2)
f0105245:	0f b6 08             	movzbl (%eax),%ecx
f0105248:	0f b6 1a             	movzbl (%edx),%ebx
f010524b:	38 d9                	cmp    %bl,%cl
f010524d:	75 08                	jne    f0105257 <memcmp+0x2a>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f010524f:	83 c0 01             	add    $0x1,%eax
f0105252:	83 c2 01             	add    $0x1,%edx
f0105255:	eb ea                	jmp    f0105241 <memcmp+0x14>
			return (int) *s1 - (int) *s2;
f0105257:	0f b6 c1             	movzbl %cl,%eax
f010525a:	0f b6 db             	movzbl %bl,%ebx
f010525d:	29 d8                	sub    %ebx,%eax
f010525f:	eb 05                	jmp    f0105266 <memcmp+0x39>
	}

	return 0;
f0105261:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105266:	5b                   	pop    %ebx
f0105267:	5e                   	pop    %esi
f0105268:	5d                   	pop    %ebp
f0105269:	c3                   	ret    

f010526a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010526a:	f3 0f 1e fb          	endbr32 
f010526e:	55                   	push   %ebp
f010526f:	89 e5                	mov    %esp,%ebp
f0105271:	8b 45 08             	mov    0x8(%ebp),%eax
f0105274:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0105277:	89 c2                	mov    %eax,%edx
f0105279:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010527c:	39 d0                	cmp    %edx,%eax
f010527e:	73 09                	jae    f0105289 <memfind+0x1f>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105280:	38 08                	cmp    %cl,(%eax)
f0105282:	74 05                	je     f0105289 <memfind+0x1f>
	for (; s < ends; s++)
f0105284:	83 c0 01             	add    $0x1,%eax
f0105287:	eb f3                	jmp    f010527c <memfind+0x12>
			break;
	return (void *) s;
}
f0105289:	5d                   	pop    %ebp
f010528a:	c3                   	ret    

f010528b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010528b:	f3 0f 1e fb          	endbr32 
f010528f:	55                   	push   %ebp
f0105290:	89 e5                	mov    %esp,%ebp
f0105292:	57                   	push   %edi
f0105293:	56                   	push   %esi
f0105294:	53                   	push   %ebx
f0105295:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105298:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010529b:	eb 03                	jmp    f01052a0 <strtol+0x15>
		s++;
f010529d:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01052a0:	0f b6 01             	movzbl (%ecx),%eax
f01052a3:	3c 20                	cmp    $0x20,%al
f01052a5:	74 f6                	je     f010529d <strtol+0x12>
f01052a7:	3c 09                	cmp    $0x9,%al
f01052a9:	74 f2                	je     f010529d <strtol+0x12>

	// plus/minus sign
	if (*s == '+')
f01052ab:	3c 2b                	cmp    $0x2b,%al
f01052ad:	74 2a                	je     f01052d9 <strtol+0x4e>
	int neg = 0;
f01052af:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01052b4:	3c 2d                	cmp    $0x2d,%al
f01052b6:	74 2b                	je     f01052e3 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01052b8:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01052be:	75 0f                	jne    f01052cf <strtol+0x44>
f01052c0:	80 39 30             	cmpb   $0x30,(%ecx)
f01052c3:	74 28                	je     f01052ed <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01052c5:	85 db                	test   %ebx,%ebx
f01052c7:	b8 0a 00 00 00       	mov    $0xa,%eax
f01052cc:	0f 44 d8             	cmove  %eax,%ebx
f01052cf:	b8 00 00 00 00       	mov    $0x0,%eax
f01052d4:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01052d7:	eb 46                	jmp    f010531f <strtol+0x94>
		s++;
f01052d9:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f01052dc:	bf 00 00 00 00       	mov    $0x0,%edi
f01052e1:	eb d5                	jmp    f01052b8 <strtol+0x2d>
		s++, neg = 1;
f01052e3:	83 c1 01             	add    $0x1,%ecx
f01052e6:	bf 01 00 00 00       	mov    $0x1,%edi
f01052eb:	eb cb                	jmp    f01052b8 <strtol+0x2d>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01052ed:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01052f1:	74 0e                	je     f0105301 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01052f3:	85 db                	test   %ebx,%ebx
f01052f5:	75 d8                	jne    f01052cf <strtol+0x44>
		s++, base = 8;
f01052f7:	83 c1 01             	add    $0x1,%ecx
f01052fa:	bb 08 00 00 00       	mov    $0x8,%ebx
f01052ff:	eb ce                	jmp    f01052cf <strtol+0x44>
		s += 2, base = 16;
f0105301:	83 c1 02             	add    $0x2,%ecx
f0105304:	bb 10 00 00 00       	mov    $0x10,%ebx
f0105309:	eb c4                	jmp    f01052cf <strtol+0x44>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f010530b:	0f be d2             	movsbl %dl,%edx
f010530e:	83 ea 30             	sub    $0x30,%edx
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0105311:	3b 55 10             	cmp    0x10(%ebp),%edx
f0105314:	7d 3a                	jge    f0105350 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0105316:	83 c1 01             	add    $0x1,%ecx
f0105319:	0f af 45 10          	imul   0x10(%ebp),%eax
f010531d:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f010531f:	0f b6 11             	movzbl (%ecx),%edx
f0105322:	8d 72 d0             	lea    -0x30(%edx),%esi
f0105325:	89 f3                	mov    %esi,%ebx
f0105327:	80 fb 09             	cmp    $0x9,%bl
f010532a:	76 df                	jbe    f010530b <strtol+0x80>
		else if (*s >= 'a' && *s <= 'z')
f010532c:	8d 72 9f             	lea    -0x61(%edx),%esi
f010532f:	89 f3                	mov    %esi,%ebx
f0105331:	80 fb 19             	cmp    $0x19,%bl
f0105334:	77 08                	ja     f010533e <strtol+0xb3>
			dig = *s - 'a' + 10;
f0105336:	0f be d2             	movsbl %dl,%edx
f0105339:	83 ea 57             	sub    $0x57,%edx
f010533c:	eb d3                	jmp    f0105311 <strtol+0x86>
		else if (*s >= 'A' && *s <= 'Z')
f010533e:	8d 72 bf             	lea    -0x41(%edx),%esi
f0105341:	89 f3                	mov    %esi,%ebx
f0105343:	80 fb 19             	cmp    $0x19,%bl
f0105346:	77 08                	ja     f0105350 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0105348:	0f be d2             	movsbl %dl,%edx
f010534b:	83 ea 37             	sub    $0x37,%edx
f010534e:	eb c1                	jmp    f0105311 <strtol+0x86>
		// we don't properly detect overflow!
	}

	if (endptr)
f0105350:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105354:	74 05                	je     f010535b <strtol+0xd0>
		*endptr = (char *) s;
f0105356:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105359:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f010535b:	89 c2                	mov    %eax,%edx
f010535d:	f7 da                	neg    %edx
f010535f:	85 ff                	test   %edi,%edi
f0105361:	0f 45 c2             	cmovne %edx,%eax
}
f0105364:	5b                   	pop    %ebx
f0105365:	5e                   	pop    %esi
f0105366:	5f                   	pop    %edi
f0105367:	5d                   	pop    %ebp
f0105368:	c3                   	ret    
f0105369:	66 90                	xchg   %ax,%ax
f010536b:	66 90                	xchg   %ax,%ax
f010536d:	66 90                	xchg   %ax,%ax
f010536f:	90                   	nop

f0105370 <__udivdi3>:
f0105370:	f3 0f 1e fb          	endbr32 
f0105374:	55                   	push   %ebp
f0105375:	57                   	push   %edi
f0105376:	56                   	push   %esi
f0105377:	53                   	push   %ebx
f0105378:	83 ec 1c             	sub    $0x1c,%esp
f010537b:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010537f:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0105383:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105387:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f010538b:	85 d2                	test   %edx,%edx
f010538d:	75 19                	jne    f01053a8 <__udivdi3+0x38>
f010538f:	39 f3                	cmp    %esi,%ebx
f0105391:	76 4d                	jbe    f01053e0 <__udivdi3+0x70>
f0105393:	31 ff                	xor    %edi,%edi
f0105395:	89 e8                	mov    %ebp,%eax
f0105397:	89 f2                	mov    %esi,%edx
f0105399:	f7 f3                	div    %ebx
f010539b:	89 fa                	mov    %edi,%edx
f010539d:	83 c4 1c             	add    $0x1c,%esp
f01053a0:	5b                   	pop    %ebx
f01053a1:	5e                   	pop    %esi
f01053a2:	5f                   	pop    %edi
f01053a3:	5d                   	pop    %ebp
f01053a4:	c3                   	ret    
f01053a5:	8d 76 00             	lea    0x0(%esi),%esi
f01053a8:	39 f2                	cmp    %esi,%edx
f01053aa:	76 14                	jbe    f01053c0 <__udivdi3+0x50>
f01053ac:	31 ff                	xor    %edi,%edi
f01053ae:	31 c0                	xor    %eax,%eax
f01053b0:	89 fa                	mov    %edi,%edx
f01053b2:	83 c4 1c             	add    $0x1c,%esp
f01053b5:	5b                   	pop    %ebx
f01053b6:	5e                   	pop    %esi
f01053b7:	5f                   	pop    %edi
f01053b8:	5d                   	pop    %ebp
f01053b9:	c3                   	ret    
f01053ba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01053c0:	0f bd fa             	bsr    %edx,%edi
f01053c3:	83 f7 1f             	xor    $0x1f,%edi
f01053c6:	75 48                	jne    f0105410 <__udivdi3+0xa0>
f01053c8:	39 f2                	cmp    %esi,%edx
f01053ca:	72 06                	jb     f01053d2 <__udivdi3+0x62>
f01053cc:	31 c0                	xor    %eax,%eax
f01053ce:	39 eb                	cmp    %ebp,%ebx
f01053d0:	77 de                	ja     f01053b0 <__udivdi3+0x40>
f01053d2:	b8 01 00 00 00       	mov    $0x1,%eax
f01053d7:	eb d7                	jmp    f01053b0 <__udivdi3+0x40>
f01053d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01053e0:	89 d9                	mov    %ebx,%ecx
f01053e2:	85 db                	test   %ebx,%ebx
f01053e4:	75 0b                	jne    f01053f1 <__udivdi3+0x81>
f01053e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01053eb:	31 d2                	xor    %edx,%edx
f01053ed:	f7 f3                	div    %ebx
f01053ef:	89 c1                	mov    %eax,%ecx
f01053f1:	31 d2                	xor    %edx,%edx
f01053f3:	89 f0                	mov    %esi,%eax
f01053f5:	f7 f1                	div    %ecx
f01053f7:	89 c6                	mov    %eax,%esi
f01053f9:	89 e8                	mov    %ebp,%eax
f01053fb:	89 f7                	mov    %esi,%edi
f01053fd:	f7 f1                	div    %ecx
f01053ff:	89 fa                	mov    %edi,%edx
f0105401:	83 c4 1c             	add    $0x1c,%esp
f0105404:	5b                   	pop    %ebx
f0105405:	5e                   	pop    %esi
f0105406:	5f                   	pop    %edi
f0105407:	5d                   	pop    %ebp
f0105408:	c3                   	ret    
f0105409:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105410:	89 f9                	mov    %edi,%ecx
f0105412:	b8 20 00 00 00       	mov    $0x20,%eax
f0105417:	29 f8                	sub    %edi,%eax
f0105419:	d3 e2                	shl    %cl,%edx
f010541b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010541f:	89 c1                	mov    %eax,%ecx
f0105421:	89 da                	mov    %ebx,%edx
f0105423:	d3 ea                	shr    %cl,%edx
f0105425:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0105429:	09 d1                	or     %edx,%ecx
f010542b:	89 f2                	mov    %esi,%edx
f010542d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105431:	89 f9                	mov    %edi,%ecx
f0105433:	d3 e3                	shl    %cl,%ebx
f0105435:	89 c1                	mov    %eax,%ecx
f0105437:	d3 ea                	shr    %cl,%edx
f0105439:	89 f9                	mov    %edi,%ecx
f010543b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010543f:	89 eb                	mov    %ebp,%ebx
f0105441:	d3 e6                	shl    %cl,%esi
f0105443:	89 c1                	mov    %eax,%ecx
f0105445:	d3 eb                	shr    %cl,%ebx
f0105447:	09 de                	or     %ebx,%esi
f0105449:	89 f0                	mov    %esi,%eax
f010544b:	f7 74 24 08          	divl   0x8(%esp)
f010544f:	89 d6                	mov    %edx,%esi
f0105451:	89 c3                	mov    %eax,%ebx
f0105453:	f7 64 24 0c          	mull   0xc(%esp)
f0105457:	39 d6                	cmp    %edx,%esi
f0105459:	72 15                	jb     f0105470 <__udivdi3+0x100>
f010545b:	89 f9                	mov    %edi,%ecx
f010545d:	d3 e5                	shl    %cl,%ebp
f010545f:	39 c5                	cmp    %eax,%ebp
f0105461:	73 04                	jae    f0105467 <__udivdi3+0xf7>
f0105463:	39 d6                	cmp    %edx,%esi
f0105465:	74 09                	je     f0105470 <__udivdi3+0x100>
f0105467:	89 d8                	mov    %ebx,%eax
f0105469:	31 ff                	xor    %edi,%edi
f010546b:	e9 40 ff ff ff       	jmp    f01053b0 <__udivdi3+0x40>
f0105470:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0105473:	31 ff                	xor    %edi,%edi
f0105475:	e9 36 ff ff ff       	jmp    f01053b0 <__udivdi3+0x40>
f010547a:	66 90                	xchg   %ax,%ax
f010547c:	66 90                	xchg   %ax,%ax
f010547e:	66 90                	xchg   %ax,%ax

f0105480 <__umoddi3>:
f0105480:	f3 0f 1e fb          	endbr32 
f0105484:	55                   	push   %ebp
f0105485:	57                   	push   %edi
f0105486:	56                   	push   %esi
f0105487:	53                   	push   %ebx
f0105488:	83 ec 1c             	sub    $0x1c,%esp
f010548b:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010548f:	8b 74 24 30          	mov    0x30(%esp),%esi
f0105493:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0105497:	8b 7c 24 38          	mov    0x38(%esp),%edi
f010549b:	85 c0                	test   %eax,%eax
f010549d:	75 19                	jne    f01054b8 <__umoddi3+0x38>
f010549f:	39 df                	cmp    %ebx,%edi
f01054a1:	76 5d                	jbe    f0105500 <__umoddi3+0x80>
f01054a3:	89 f0                	mov    %esi,%eax
f01054a5:	89 da                	mov    %ebx,%edx
f01054a7:	f7 f7                	div    %edi
f01054a9:	89 d0                	mov    %edx,%eax
f01054ab:	31 d2                	xor    %edx,%edx
f01054ad:	83 c4 1c             	add    $0x1c,%esp
f01054b0:	5b                   	pop    %ebx
f01054b1:	5e                   	pop    %esi
f01054b2:	5f                   	pop    %edi
f01054b3:	5d                   	pop    %ebp
f01054b4:	c3                   	ret    
f01054b5:	8d 76 00             	lea    0x0(%esi),%esi
f01054b8:	89 f2                	mov    %esi,%edx
f01054ba:	39 d8                	cmp    %ebx,%eax
f01054bc:	76 12                	jbe    f01054d0 <__umoddi3+0x50>
f01054be:	89 f0                	mov    %esi,%eax
f01054c0:	89 da                	mov    %ebx,%edx
f01054c2:	83 c4 1c             	add    $0x1c,%esp
f01054c5:	5b                   	pop    %ebx
f01054c6:	5e                   	pop    %esi
f01054c7:	5f                   	pop    %edi
f01054c8:	5d                   	pop    %ebp
f01054c9:	c3                   	ret    
f01054ca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01054d0:	0f bd e8             	bsr    %eax,%ebp
f01054d3:	83 f5 1f             	xor    $0x1f,%ebp
f01054d6:	75 50                	jne    f0105528 <__umoddi3+0xa8>
f01054d8:	39 d8                	cmp    %ebx,%eax
f01054da:	0f 82 e0 00 00 00    	jb     f01055c0 <__umoddi3+0x140>
f01054e0:	89 d9                	mov    %ebx,%ecx
f01054e2:	39 f7                	cmp    %esi,%edi
f01054e4:	0f 86 d6 00 00 00    	jbe    f01055c0 <__umoddi3+0x140>
f01054ea:	89 d0                	mov    %edx,%eax
f01054ec:	89 ca                	mov    %ecx,%edx
f01054ee:	83 c4 1c             	add    $0x1c,%esp
f01054f1:	5b                   	pop    %ebx
f01054f2:	5e                   	pop    %esi
f01054f3:	5f                   	pop    %edi
f01054f4:	5d                   	pop    %ebp
f01054f5:	c3                   	ret    
f01054f6:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01054fd:	8d 76 00             	lea    0x0(%esi),%esi
f0105500:	89 fd                	mov    %edi,%ebp
f0105502:	85 ff                	test   %edi,%edi
f0105504:	75 0b                	jne    f0105511 <__umoddi3+0x91>
f0105506:	b8 01 00 00 00       	mov    $0x1,%eax
f010550b:	31 d2                	xor    %edx,%edx
f010550d:	f7 f7                	div    %edi
f010550f:	89 c5                	mov    %eax,%ebp
f0105511:	89 d8                	mov    %ebx,%eax
f0105513:	31 d2                	xor    %edx,%edx
f0105515:	f7 f5                	div    %ebp
f0105517:	89 f0                	mov    %esi,%eax
f0105519:	f7 f5                	div    %ebp
f010551b:	89 d0                	mov    %edx,%eax
f010551d:	31 d2                	xor    %edx,%edx
f010551f:	eb 8c                	jmp    f01054ad <__umoddi3+0x2d>
f0105521:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105528:	89 e9                	mov    %ebp,%ecx
f010552a:	ba 20 00 00 00       	mov    $0x20,%edx
f010552f:	29 ea                	sub    %ebp,%edx
f0105531:	d3 e0                	shl    %cl,%eax
f0105533:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105537:	89 d1                	mov    %edx,%ecx
f0105539:	89 f8                	mov    %edi,%eax
f010553b:	d3 e8                	shr    %cl,%eax
f010553d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0105541:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105545:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105549:	09 c1                	or     %eax,%ecx
f010554b:	89 d8                	mov    %ebx,%eax
f010554d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105551:	89 e9                	mov    %ebp,%ecx
f0105553:	d3 e7                	shl    %cl,%edi
f0105555:	89 d1                	mov    %edx,%ecx
f0105557:	d3 e8                	shr    %cl,%eax
f0105559:	89 e9                	mov    %ebp,%ecx
f010555b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010555f:	d3 e3                	shl    %cl,%ebx
f0105561:	89 c7                	mov    %eax,%edi
f0105563:	89 d1                	mov    %edx,%ecx
f0105565:	89 f0                	mov    %esi,%eax
f0105567:	d3 e8                	shr    %cl,%eax
f0105569:	89 e9                	mov    %ebp,%ecx
f010556b:	89 fa                	mov    %edi,%edx
f010556d:	d3 e6                	shl    %cl,%esi
f010556f:	09 d8                	or     %ebx,%eax
f0105571:	f7 74 24 08          	divl   0x8(%esp)
f0105575:	89 d1                	mov    %edx,%ecx
f0105577:	89 f3                	mov    %esi,%ebx
f0105579:	f7 64 24 0c          	mull   0xc(%esp)
f010557d:	89 c6                	mov    %eax,%esi
f010557f:	89 d7                	mov    %edx,%edi
f0105581:	39 d1                	cmp    %edx,%ecx
f0105583:	72 06                	jb     f010558b <__umoddi3+0x10b>
f0105585:	75 10                	jne    f0105597 <__umoddi3+0x117>
f0105587:	39 c3                	cmp    %eax,%ebx
f0105589:	73 0c                	jae    f0105597 <__umoddi3+0x117>
f010558b:	2b 44 24 0c          	sub    0xc(%esp),%eax
f010558f:	1b 54 24 08          	sbb    0x8(%esp),%edx
f0105593:	89 d7                	mov    %edx,%edi
f0105595:	89 c6                	mov    %eax,%esi
f0105597:	89 ca                	mov    %ecx,%edx
f0105599:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010559e:	29 f3                	sub    %esi,%ebx
f01055a0:	19 fa                	sbb    %edi,%edx
f01055a2:	89 d0                	mov    %edx,%eax
f01055a4:	d3 e0                	shl    %cl,%eax
f01055a6:	89 e9                	mov    %ebp,%ecx
f01055a8:	d3 eb                	shr    %cl,%ebx
f01055aa:	d3 ea                	shr    %cl,%edx
f01055ac:	09 d8                	or     %ebx,%eax
f01055ae:	83 c4 1c             	add    $0x1c,%esp
f01055b1:	5b                   	pop    %ebx
f01055b2:	5e                   	pop    %esi
f01055b3:	5f                   	pop    %edi
f01055b4:	5d                   	pop    %ebp
f01055b5:	c3                   	ret    
f01055b6:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01055bd:	8d 76 00             	lea    0x0(%esi),%esi
f01055c0:	29 fe                	sub    %edi,%esi
f01055c2:	19 c3                	sbb    %eax,%ebx
f01055c4:	89 f2                	mov    %esi,%edx
f01055c6:	89 d9                	mov    %ebx,%ecx
f01055c8:	e9 1d ff ff ff       	jmp    f01054ea <__umoddi3+0x6a>
