
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
f0100015:	b8 00 d0 18 00       	mov    $0x18d000,%eax
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
f0100034:	bc 00 a0 11 f0       	mov    $0xf011a000,%esp

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
f0100050:	81 c3 cc bf 08 00    	add    $0x8bfcc,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100056:	c7 c0 e0 ef 18 f0    	mov    $0xf018efe0,%eax
f010005c:	c7 c2 e0 e0 18 f0    	mov    $0xf018e0e0,%edx
f0100062:	29 d0                	sub    %edx,%eax
f0100064:	50                   	push   %eax
f0100065:	6a 00                	push   $0x0
f0100067:	52                   	push   %edx
f0100068:	e8 da 44 00 00       	call   f0104547 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010006d:	e8 5c 05 00 00       	call   f01005ce <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	68 ac 1a 00 00       	push   $0x1aac
f010007a:	8d 83 a4 89 f7 ff    	lea    -0x8765c(%ebx),%eax
f0100080:	50                   	push   %eax
f0100081:	e8 51 34 00 00       	call   f01034d7 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100086:	e8 3d 12 00 00       	call   f01012c8 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f010008b:	e8 ab 2f 00 00       	call   f010303b <env_init>
	trap_init();
f0100090:	e8 fd 34 00 00       	call   f0103592 <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100095:	83 c4 08             	add    $0x8,%esp
f0100098:	6a 00                	push   $0x0
f010009a:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f01000a0:	e8 da 30 00 00       	call   f010317f <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a5:	83 c4 04             	add    $0x4,%esp
f01000a8:	c7 c0 28 e3 18 f0    	mov    $0xf018e328,%eax
f01000ae:	ff 30                	pushl  (%eax)
f01000b0:	e8 5d 33 00 00       	call   f0103412 <env_run>

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
f01000c7:	81 c3 55 bf 08 00    	add    $0x8bf55,%ebx
f01000cd:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000d0:	c7 c0 e4 ef 18 f0    	mov    $0xf018efe4,%eax
f01000d6:	83 38 00             	cmpl   $0x0,(%eax)
f01000d9:	74 0f                	je     f01000ea <_panic+0x35>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000db:	83 ec 0c             	sub    $0xc,%esp
f01000de:	6a 00                	push   $0x0
f01000e0:	e8 7d 07 00 00       	call   f0100862 <monitor>
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
f01000fa:	8d 83 bf 89 f7 ff    	lea    -0x87641(%ebx),%eax
f0100100:	50                   	push   %eax
f0100101:	e8 d1 33 00 00       	call   f01034d7 <cprintf>
	vcprintf(fmt, ap);
f0100106:	83 c4 08             	add    $0x8,%esp
f0100109:	56                   	push   %esi
f010010a:	57                   	push   %edi
f010010b:	e8 8c 33 00 00       	call   f010349c <vcprintf>
	cprintf("\n");
f0100110:	8d 83 d2 98 f7 ff    	lea    -0x8672e(%ebx),%eax
f0100116:	89 04 24             	mov    %eax,(%esp)
f0100119:	e8 b9 33 00 00       	call   f01034d7 <cprintf>
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
f0100131:	81 c3 eb be 08 00    	add    $0x8beeb,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100137:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f010013a:	83 ec 04             	sub    $0x4,%esp
f010013d:	ff 75 0c             	pushl  0xc(%ebp)
f0100140:	ff 75 08             	pushl  0x8(%ebp)
f0100143:	8d 83 d7 89 f7 ff    	lea    -0x87629(%ebx),%eax
f0100149:	50                   	push   %eax
f010014a:	e8 88 33 00 00       	call   f01034d7 <cprintf>
	vcprintf(fmt, ap);
f010014f:	83 c4 08             	add    $0x8,%esp
f0100152:	56                   	push   %esi
f0100153:	ff 75 10             	pushl  0x10(%ebp)
f0100156:	e8 41 33 00 00       	call   f010349c <vcprintf>
	cprintf("\n");
f010015b:	8d 83 d2 98 f7 ff    	lea    -0x8672e(%ebx),%eax
f0100161:	89 04 24             	mov    %eax,(%esp)
f0100164:	e8 6e 33 00 00       	call   f01034d7 <cprintf>
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
f010019e:	e8 88 05 00 00       	call   f010072b <__x86.get_pc_thunk.si>
f01001a3:	81 c6 79 be 08 00    	add    $0x8be79,%esi
f01001a9:	89 c7                	mov    %eax,%edi
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
		cons.buf[cons.wpos++] = c;
f01001ab:	8d 1d e4 20 00 00    	lea    0x20e4,%ebx
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
f0100205:	81 c3 17 be 08 00    	add    $0x8be17,%ebx
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
f0100231:	8b 8b c4 20 00 00    	mov    0x20c4(%ebx),%ecx
f0100237:	f6 c1 40             	test   $0x40,%cl
f010023a:	74 0e                	je     f010024a <kbd_proc_data+0x53>
		data |= 0x80;
f010023c:	83 c8 80             	or     $0xffffff80,%eax
f010023f:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100241:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100244:	89 8b c4 20 00 00    	mov    %ecx,0x20c4(%ebx)
	shift |= shiftcode[data];
f010024a:	0f b6 d2             	movzbl %dl,%edx
f010024d:	0f b6 84 13 24 8b f7 	movzbl -0x874dc(%ebx,%edx,1),%eax
f0100254:	ff 
f0100255:	0b 83 c4 20 00 00    	or     0x20c4(%ebx),%eax
	shift ^= togglecode[data];
f010025b:	0f b6 8c 13 24 8a f7 	movzbl -0x875dc(%ebx,%edx,1),%ecx
f0100262:	ff 
f0100263:	31 c8                	xor    %ecx,%eax
f0100265:	89 83 c4 20 00 00    	mov    %eax,0x20c4(%ebx)
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
f0100291:	83 8b c4 20 00 00 40 	orl    $0x40,0x20c4(%ebx)
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
f01002a6:	8b 8b c4 20 00 00    	mov    0x20c4(%ebx),%ecx
f01002ac:	89 ce                	mov    %ecx,%esi
f01002ae:	83 e6 40             	and    $0x40,%esi
f01002b1:	83 e0 7f             	and    $0x7f,%eax
f01002b4:	85 f6                	test   %esi,%esi
f01002b6:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002b9:	0f b6 d2             	movzbl %dl,%edx
f01002bc:	0f b6 84 13 24 8b f7 	movzbl -0x874dc(%ebx,%edx,1),%eax
f01002c3:	ff 
f01002c4:	83 c8 40             	or     $0x40,%eax
f01002c7:	0f b6 c0             	movzbl %al,%eax
f01002ca:	f7 d0                	not    %eax
f01002cc:	21 c8                	and    %ecx,%eax
f01002ce:	89 83 c4 20 00 00    	mov    %eax,0x20c4(%ebx)
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
f01002f8:	8d 83 f1 89 f7 ff    	lea    -0x8760f(%ebx),%eax
f01002fe:	50                   	push   %eax
f01002ff:	e8 d3 31 00 00       	call   f01034d7 <cprintf>
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
f0100333:	81 c3 e9 bc 08 00    	add    $0x8bce9,%ebx
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
		c |= 0x0700;
f01003af:	89 f8                	mov    %edi,%eax
f01003b1:	80 cc 07             	or     $0x7,%ah
f01003b4:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f01003ba:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f01003bd:	89 f8                	mov    %edi,%eax
f01003bf:	0f b6 c0             	movzbl %al,%eax
f01003c2:	89 f9                	mov    %edi,%ecx
f01003c4:	80 f9 0a             	cmp    $0xa,%cl
f01003c7:	0f 84 e2 00 00 00    	je     f01004af <cons_putc+0x18a>
f01003cd:	83 f8 0a             	cmp    $0xa,%eax
f01003d0:	7f 46                	jg     f0100418 <cons_putc+0xf3>
f01003d2:	83 f8 08             	cmp    $0x8,%eax
f01003d5:	0f 84 a8 00 00 00    	je     f0100483 <cons_putc+0x15e>
f01003db:	83 f8 09             	cmp    $0x9,%eax
f01003de:	0f 85 d8 00 00 00    	jne    f01004bc <cons_putc+0x197>
		cons_putc(' ');
f01003e4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e9:	e8 37 ff ff ff       	call   f0100325 <cons_putc>
		cons_putc(' ');
f01003ee:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f3:	e8 2d ff ff ff       	call   f0100325 <cons_putc>
		cons_putc(' ');
f01003f8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fd:	e8 23 ff ff ff       	call   f0100325 <cons_putc>
		cons_putc(' ');
f0100402:	b8 20 00 00 00       	mov    $0x20,%eax
f0100407:	e8 19 ff ff ff       	call   f0100325 <cons_putc>
		cons_putc(' ');
f010040c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100411:	e8 0f ff ff ff       	call   f0100325 <cons_putc>
		break;
f0100416:	eb 26                	jmp    f010043e <cons_putc+0x119>
	switch (c & 0xff) {
f0100418:	83 f8 0d             	cmp    $0xd,%eax
f010041b:	0f 85 9b 00 00 00    	jne    f01004bc <cons_putc+0x197>
		crt_pos -= (crt_pos % CRT_COLS);
f0100421:	0f b7 83 ec 22 00 00 	movzwl 0x22ec(%ebx),%eax
f0100428:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010042e:	c1 e8 16             	shr    $0x16,%eax
f0100431:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100434:	c1 e0 04             	shl    $0x4,%eax
f0100437:	66 89 83 ec 22 00 00 	mov    %ax,0x22ec(%ebx)
	if (crt_pos >= CRT_SIZE) {
f010043e:	66 81 bb ec 22 00 00 	cmpw   $0x7cf,0x22ec(%ebx)
f0100445:	cf 07 
f0100447:	0f 87 92 00 00 00    	ja     f01004df <cons_putc+0x1ba>
	outb(addr_6845, 14);
f010044d:	8b 8b f4 22 00 00    	mov    0x22f4(%ebx),%ecx
f0100453:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100458:	89 ca                	mov    %ecx,%edx
f010045a:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045b:	0f b7 9b ec 22 00 00 	movzwl 0x22ec(%ebx),%ebx
f0100462:	8d 71 01             	lea    0x1(%ecx),%esi
f0100465:	89 d8                	mov    %ebx,%eax
f0100467:	66 c1 e8 08          	shr    $0x8,%ax
f010046b:	89 f2                	mov    %esi,%edx
f010046d:	ee                   	out    %al,(%dx)
f010046e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100473:	89 ca                	mov    %ecx,%edx
f0100475:	ee                   	out    %al,(%dx)
f0100476:	89 d8                	mov    %ebx,%eax
f0100478:	89 f2                	mov    %esi,%edx
f010047a:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010047b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047e:	5b                   	pop    %ebx
f010047f:	5e                   	pop    %esi
f0100480:	5f                   	pop    %edi
f0100481:	5d                   	pop    %ebp
f0100482:	c3                   	ret    
		if (crt_pos > 0) {
f0100483:	0f b7 83 ec 22 00 00 	movzwl 0x22ec(%ebx),%eax
f010048a:	66 85 c0             	test   %ax,%ax
f010048d:	74 be                	je     f010044d <cons_putc+0x128>
			crt_pos--;
f010048f:	83 e8 01             	sub    $0x1,%eax
f0100492:	66 89 83 ec 22 00 00 	mov    %ax,0x22ec(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100499:	0f b7 c0             	movzwl %ax,%eax
f010049c:	89 fa                	mov    %edi,%edx
f010049e:	b2 00                	mov    $0x0,%dl
f01004a0:	83 ca 20             	or     $0x20,%edx
f01004a3:	8b 8b f0 22 00 00    	mov    0x22f0(%ebx),%ecx
f01004a9:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f01004ad:	eb 8f                	jmp    f010043e <cons_putc+0x119>
		crt_pos += CRT_COLS;
f01004af:	66 83 83 ec 22 00 00 	addw   $0x50,0x22ec(%ebx)
f01004b6:	50 
f01004b7:	e9 65 ff ff ff       	jmp    f0100421 <cons_putc+0xfc>
		crt_buf[crt_pos++] = c;		/* write the character */
f01004bc:	0f b7 83 ec 22 00 00 	movzwl 0x22ec(%ebx),%eax
f01004c3:	8d 50 01             	lea    0x1(%eax),%edx
f01004c6:	66 89 93 ec 22 00 00 	mov    %dx,0x22ec(%ebx)
f01004cd:	0f b7 c0             	movzwl %ax,%eax
f01004d0:	8b 93 f0 22 00 00    	mov    0x22f0(%ebx),%edx
f01004d6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
f01004da:	e9 5f ff ff ff       	jmp    f010043e <cons_putc+0x119>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004df:	8b 83 f0 22 00 00    	mov    0x22f0(%ebx),%eax
f01004e5:	83 ec 04             	sub    $0x4,%esp
f01004e8:	68 00 0f 00 00       	push   $0xf00
f01004ed:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004f3:	52                   	push   %edx
f01004f4:	50                   	push   %eax
f01004f5:	e8 99 40 00 00       	call   f0104593 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004fa:	8b 93 f0 22 00 00    	mov    0x22f0(%ebx),%edx
f0100500:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100506:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010050c:	83 c4 10             	add    $0x10,%esp
f010050f:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100514:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100517:	39 d0                	cmp    %edx,%eax
f0100519:	75 f4                	jne    f010050f <cons_putc+0x1ea>
		crt_pos -= CRT_COLS;
f010051b:	66 83 ab ec 22 00 00 	subw   $0x50,0x22ec(%ebx)
f0100522:	50 
f0100523:	e9 25 ff ff ff       	jmp    f010044d <cons_putc+0x128>

f0100528 <serial_intr>:
{
f0100528:	f3 0f 1e fb          	endbr32 
f010052c:	e8 f6 01 00 00       	call   f0100727 <__x86.get_pc_thunk.ax>
f0100531:	05 eb ba 08 00       	add    $0x8baeb,%eax
	if (serial_exists)
f0100536:	80 b8 f8 22 00 00 00 	cmpb   $0x0,0x22f8(%eax)
f010053d:	75 01                	jne    f0100540 <serial_intr+0x18>
f010053f:	c3                   	ret    
{
f0100540:	55                   	push   %ebp
f0100541:	89 e5                	mov    %esp,%ebp
f0100543:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100546:	8d 80 5b 41 f7 ff    	lea    -0x8bea5(%eax),%eax
f010054c:	e8 44 fc ff ff       	call   f0100195 <cons_intr>
}
f0100551:	c9                   	leave  
f0100552:	c3                   	ret    

f0100553 <kbd_intr>:
{
f0100553:	f3 0f 1e fb          	endbr32 
f0100557:	55                   	push   %ebp
f0100558:	89 e5                	mov    %esp,%ebp
f010055a:	83 ec 08             	sub    $0x8,%esp
f010055d:	e8 c5 01 00 00       	call   f0100727 <__x86.get_pc_thunk.ax>
f0100562:	05 ba ba 08 00       	add    $0x8baba,%eax
	cons_intr(kbd_proc_data);
f0100567:	8d 80 db 41 f7 ff    	lea    -0x8be25(%eax),%eax
f010056d:	e8 23 fc ff ff       	call   f0100195 <cons_intr>
}
f0100572:	c9                   	leave  
f0100573:	c3                   	ret    

f0100574 <cons_getc>:
{
f0100574:	f3 0f 1e fb          	endbr32 
f0100578:	55                   	push   %ebp
f0100579:	89 e5                	mov    %esp,%ebp
f010057b:	53                   	push   %ebx
f010057c:	83 ec 04             	sub    $0x4,%esp
f010057f:	e8 ef fb ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0100584:	81 c3 98 ba 08 00    	add    $0x8ba98,%ebx
	serial_intr();
f010058a:	e8 99 ff ff ff       	call   f0100528 <serial_intr>
	kbd_intr();
f010058f:	e8 bf ff ff ff       	call   f0100553 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100594:	8b 83 e4 22 00 00    	mov    0x22e4(%ebx),%eax
	return 0;
f010059a:	ba 00 00 00 00       	mov    $0x0,%edx
	if (cons.rpos != cons.wpos) {
f010059f:	3b 83 e8 22 00 00    	cmp    0x22e8(%ebx),%eax
f01005a5:	74 1f                	je     f01005c6 <cons_getc+0x52>
		c = cons.buf[cons.rpos++];
f01005a7:	8d 48 01             	lea    0x1(%eax),%ecx
f01005aa:	0f b6 94 03 e4 20 00 	movzbl 0x20e4(%ebx,%eax,1),%edx
f01005b1:	00 
			cons.rpos = 0;
f01005b2:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01005b8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bd:	0f 44 c8             	cmove  %eax,%ecx
f01005c0:	89 8b e4 22 00 00    	mov    %ecx,0x22e4(%ebx)
}
f01005c6:	89 d0                	mov    %edx,%eax
f01005c8:	83 c4 04             	add    $0x4,%esp
f01005cb:	5b                   	pop    %ebx
f01005cc:	5d                   	pop    %ebp
f01005cd:	c3                   	ret    

f01005ce <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005ce:	f3 0f 1e fb          	endbr32 
f01005d2:	55                   	push   %ebp
f01005d3:	89 e5                	mov    %esp,%ebp
f01005d5:	57                   	push   %edi
f01005d6:	56                   	push   %esi
f01005d7:	53                   	push   %ebx
f01005d8:	83 ec 1c             	sub    $0x1c,%esp
f01005db:	e8 93 fb ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01005e0:	81 c3 3c ba 08 00    	add    $0x8ba3c,%ebx
	was = *cp;
f01005e6:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01005ed:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005f4:	5a a5 
	if (*cp != 0xA55A) {
f01005f6:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005fd:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100601:	0f 84 bc 00 00 00    	je     f01006c3 <cons_init+0xf5>
		addr_6845 = MONO_BASE;
f0100607:	c7 83 f4 22 00 00 b4 	movl   $0x3b4,0x22f4(%ebx)
f010060e:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100611:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f0100618:	8b bb f4 22 00 00    	mov    0x22f4(%ebx),%edi
f010061e:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100623:	89 fa                	mov    %edi,%edx
f0100625:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100626:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100629:	89 ca                	mov    %ecx,%edx
f010062b:	ec                   	in     (%dx),%al
f010062c:	0f b6 f0             	movzbl %al,%esi
f010062f:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100632:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100637:	89 fa                	mov    %edi,%edx
f0100639:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010063a:	89 ca                	mov    %ecx,%edx
f010063c:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010063d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100640:	89 bb f0 22 00 00    	mov    %edi,0x22f0(%ebx)
	pos |= inb(addr_6845 + 1);
f0100646:	0f b6 c0             	movzbl %al,%eax
f0100649:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f010064b:	66 89 b3 ec 22 00 00 	mov    %si,0x22ec(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100652:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100657:	89 c8                	mov    %ecx,%eax
f0100659:	ba fa 03 00 00       	mov    $0x3fa,%edx
f010065e:	ee                   	out    %al,(%dx)
f010065f:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100664:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100669:	89 fa                	mov    %edi,%edx
f010066b:	ee                   	out    %al,(%dx)
f010066c:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100671:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100676:	ee                   	out    %al,(%dx)
f0100677:	be f9 03 00 00       	mov    $0x3f9,%esi
f010067c:	89 c8                	mov    %ecx,%eax
f010067e:	89 f2                	mov    %esi,%edx
f0100680:	ee                   	out    %al,(%dx)
f0100681:	b8 03 00 00 00       	mov    $0x3,%eax
f0100686:	89 fa                	mov    %edi,%edx
f0100688:	ee                   	out    %al,(%dx)
f0100689:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010068e:	89 c8                	mov    %ecx,%eax
f0100690:	ee                   	out    %al,(%dx)
f0100691:	b8 01 00 00 00       	mov    $0x1,%eax
f0100696:	89 f2                	mov    %esi,%edx
f0100698:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100699:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010069e:	ec                   	in     (%dx),%al
f010069f:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01006a1:	3c ff                	cmp    $0xff,%al
f01006a3:	0f 95 83 f8 22 00 00 	setne  0x22f8(%ebx)
f01006aa:	ba fa 03 00 00       	mov    $0x3fa,%edx
f01006af:	ec                   	in     (%dx),%al
f01006b0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006b5:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01006b6:	80 f9 ff             	cmp    $0xff,%cl
f01006b9:	74 25                	je     f01006e0 <cons_init+0x112>
		cprintf("Serial port does not exist!\n");
}
f01006bb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006be:	5b                   	pop    %ebx
f01006bf:	5e                   	pop    %esi
f01006c0:	5f                   	pop    %edi
f01006c1:	5d                   	pop    %ebp
f01006c2:	c3                   	ret    
		*cp = was;
f01006c3:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006ca:	c7 83 f4 22 00 00 d4 	movl   $0x3d4,0x22f4(%ebx)
f01006d1:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006d4:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006db:	e9 38 ff ff ff       	jmp    f0100618 <cons_init+0x4a>
		cprintf("Serial port does not exist!\n");
f01006e0:	83 ec 0c             	sub    $0xc,%esp
f01006e3:	8d 83 fd 89 f7 ff    	lea    -0x87603(%ebx),%eax
f01006e9:	50                   	push   %eax
f01006ea:	e8 e8 2d 00 00       	call   f01034d7 <cprintf>
f01006ef:	83 c4 10             	add    $0x10,%esp
}
f01006f2:	eb c7                	jmp    f01006bb <cons_init+0xed>

f01006f4 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006f4:	f3 0f 1e fb          	endbr32 
f01006f8:	55                   	push   %ebp
f01006f9:	89 e5                	mov    %esp,%ebp
f01006fb:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0100701:	e8 1f fc ff ff       	call   f0100325 <cons_putc>
}
f0100706:	c9                   	leave  
f0100707:	c3                   	ret    

f0100708 <getchar>:

int
getchar(void)
{
f0100708:	f3 0f 1e fb          	endbr32 
f010070c:	55                   	push   %ebp
f010070d:	89 e5                	mov    %esp,%ebp
f010070f:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100712:	e8 5d fe ff ff       	call   f0100574 <cons_getc>
f0100717:	85 c0                	test   %eax,%eax
f0100719:	74 f7                	je     f0100712 <getchar+0xa>
		/* do nothing */;
	return c;
}
f010071b:	c9                   	leave  
f010071c:	c3                   	ret    

f010071d <iscons>:

int
iscons(int fdnum)
{
f010071d:	f3 0f 1e fb          	endbr32 
	// used by readline
	return 1;
}
f0100721:	b8 01 00 00 00       	mov    $0x1,%eax
f0100726:	c3                   	ret    

f0100727 <__x86.get_pc_thunk.ax>:
f0100727:	8b 04 24             	mov    (%esp),%eax
f010072a:	c3                   	ret    

f010072b <__x86.get_pc_thunk.si>:
f010072b:	8b 34 24             	mov    (%esp),%esi
f010072e:	c3                   	ret    

f010072f <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010072f:	f3 0f 1e fb          	endbr32 
f0100733:	55                   	push   %ebp
f0100734:	89 e5                	mov    %esp,%ebp
f0100736:	56                   	push   %esi
f0100737:	53                   	push   %ebx
f0100738:	e8 36 fa ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f010073d:	81 c3 df b8 08 00    	add    $0x8b8df,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100743:	83 ec 04             	sub    $0x4,%esp
f0100746:	8d 83 24 8c f7 ff    	lea    -0x873dc(%ebx),%eax
f010074c:	50                   	push   %eax
f010074d:	8d 83 42 8c f7 ff    	lea    -0x873be(%ebx),%eax
f0100753:	50                   	push   %eax
f0100754:	8d b3 47 8c f7 ff    	lea    -0x873b9(%ebx),%esi
f010075a:	56                   	push   %esi
f010075b:	e8 77 2d 00 00       	call   f01034d7 <cprintf>
f0100760:	83 c4 0c             	add    $0xc,%esp
f0100763:	8d 83 b0 8c f7 ff    	lea    -0x87350(%ebx),%eax
f0100769:	50                   	push   %eax
f010076a:	8d 83 50 8c f7 ff    	lea    -0x873b0(%ebx),%eax
f0100770:	50                   	push   %eax
f0100771:	56                   	push   %esi
f0100772:	e8 60 2d 00 00       	call   f01034d7 <cprintf>
	return 0;
}
f0100777:	b8 00 00 00 00       	mov    $0x0,%eax
f010077c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010077f:	5b                   	pop    %ebx
f0100780:	5e                   	pop    %esi
f0100781:	5d                   	pop    %ebp
f0100782:	c3                   	ret    

f0100783 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100783:	f3 0f 1e fb          	endbr32 
f0100787:	55                   	push   %ebp
f0100788:	89 e5                	mov    %esp,%ebp
f010078a:	57                   	push   %edi
f010078b:	56                   	push   %esi
f010078c:	53                   	push   %ebx
f010078d:	83 ec 18             	sub    $0x18,%esp
f0100790:	e8 de f9 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0100795:	81 c3 87 b8 08 00    	add    $0x8b887,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010079b:	8d 83 59 8c f7 ff    	lea    -0x873a7(%ebx),%eax
f01007a1:	50                   	push   %eax
f01007a2:	e8 30 2d 00 00       	call   f01034d7 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007a7:	83 c4 08             	add    $0x8,%esp
f01007aa:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f01007b0:	8d 83 d8 8c f7 ff    	lea    -0x87328(%ebx),%eax
f01007b6:	50                   	push   %eax
f01007b7:	e8 1b 2d 00 00       	call   f01034d7 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007bc:	83 c4 0c             	add    $0xc,%esp
f01007bf:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f01007c5:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007cb:	50                   	push   %eax
f01007cc:	57                   	push   %edi
f01007cd:	8d 83 00 8d f7 ff    	lea    -0x87300(%ebx),%eax
f01007d3:	50                   	push   %eax
f01007d4:	e8 fe 2c 00 00       	call   f01034d7 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007d9:	83 c4 0c             	add    $0xc,%esp
f01007dc:	c7 c0 ad 49 10 f0    	mov    $0xf01049ad,%eax
f01007e2:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007e8:	52                   	push   %edx
f01007e9:	50                   	push   %eax
f01007ea:	8d 83 24 8d f7 ff    	lea    -0x872dc(%ebx),%eax
f01007f0:	50                   	push   %eax
f01007f1:	e8 e1 2c 00 00       	call   f01034d7 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007f6:	83 c4 0c             	add    $0xc,%esp
f01007f9:	c7 c0 e0 e0 18 f0    	mov    $0xf018e0e0,%eax
f01007ff:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100805:	52                   	push   %edx
f0100806:	50                   	push   %eax
f0100807:	8d 83 48 8d f7 ff    	lea    -0x872b8(%ebx),%eax
f010080d:	50                   	push   %eax
f010080e:	e8 c4 2c 00 00       	call   f01034d7 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100813:	83 c4 0c             	add    $0xc,%esp
f0100816:	c7 c6 e0 ef 18 f0    	mov    $0xf018efe0,%esi
f010081c:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0100822:	50                   	push   %eax
f0100823:	56                   	push   %esi
f0100824:	8d 83 6c 8d f7 ff    	lea    -0x87294(%ebx),%eax
f010082a:	50                   	push   %eax
f010082b:	e8 a7 2c 00 00       	call   f01034d7 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100830:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100833:	29 fe                	sub    %edi,%esi
f0100835:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f010083b:	c1 fe 0a             	sar    $0xa,%esi
f010083e:	56                   	push   %esi
f010083f:	8d 83 90 8d f7 ff    	lea    -0x87270(%ebx),%eax
f0100845:	50                   	push   %eax
f0100846:	e8 8c 2c 00 00       	call   f01034d7 <cprintf>
	return 0;
}
f010084b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100850:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100853:	5b                   	pop    %ebx
f0100854:	5e                   	pop    %esi
f0100855:	5f                   	pop    %edi
f0100856:	5d                   	pop    %ebp
f0100857:	c3                   	ret    

f0100858 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100858:	f3 0f 1e fb          	endbr32 
	// Your code here.
	return 0;
}
f010085c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100861:	c3                   	ret    

f0100862 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100862:	f3 0f 1e fb          	endbr32 
f0100866:	55                   	push   %ebp
f0100867:	89 e5                	mov    %esp,%ebp
f0100869:	57                   	push   %edi
f010086a:	56                   	push   %esi
f010086b:	53                   	push   %ebx
f010086c:	83 ec 68             	sub    $0x68,%esp
f010086f:	e8 ff f8 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0100874:	81 c3 a8 b7 08 00    	add    $0x8b7a8,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010087a:	8d 83 bc 8d f7 ff    	lea    -0x87244(%ebx),%eax
f0100880:	50                   	push   %eax
f0100881:	e8 51 2c 00 00       	call   f01034d7 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100886:	8d 83 e0 8d f7 ff    	lea    -0x87220(%ebx),%eax
f010088c:	89 04 24             	mov    %eax,(%esp)
f010088f:	e8 43 2c 00 00       	call   f01034d7 <cprintf>

	if (tf != NULL)
f0100894:	83 c4 10             	add    $0x10,%esp
f0100897:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010089b:	74 0e                	je     f01008ab <monitor+0x49>
		print_trapframe(tf);
f010089d:	83 ec 0c             	sub    $0xc,%esp
f01008a0:	ff 75 08             	pushl  0x8(%ebp)
f01008a3:	e8 a8 2d 00 00       	call   f0103650 <print_trapframe>
f01008a8:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f01008ab:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01008b1:	89 45 a0             	mov    %eax,-0x60(%ebp)
f01008b4:	e9 dc 00 00 00       	jmp    f0100995 <monitor+0x133>
f01008b9:	83 ec 08             	sub    $0x8,%esp
f01008bc:	0f be c0             	movsbl %al,%eax
f01008bf:	50                   	push   %eax
f01008c0:	ff 75 a0             	pushl  -0x60(%ebp)
f01008c3:	e8 3a 3c 00 00       	call   f0104502 <strchr>
f01008c8:	83 c4 10             	add    $0x10,%esp
f01008cb:	85 c0                	test   %eax,%eax
f01008cd:	74 74                	je     f0100943 <monitor+0xe1>
			*buf++ = 0;
f01008cf:	c6 06 00             	movb   $0x0,(%esi)
f01008d2:	89 7d a4             	mov    %edi,-0x5c(%ebp)
f01008d5:	8d 76 01             	lea    0x1(%esi),%esi
f01008d8:	8b 7d a4             	mov    -0x5c(%ebp),%edi
		while (*buf && strchr(WHITESPACE, *buf))
f01008db:	0f b6 06             	movzbl (%esi),%eax
f01008de:	84 c0                	test   %al,%al
f01008e0:	75 d7                	jne    f01008b9 <monitor+0x57>
	argv[argc] = 0;
f01008e2:	c7 44 bd a8 00 00 00 	movl   $0x0,-0x58(%ebp,%edi,4)
f01008e9:	00 
	if (argc == 0)
f01008ea:	85 ff                	test   %edi,%edi
f01008ec:	0f 84 a3 00 00 00    	je     f0100995 <monitor+0x133>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008f2:	83 ec 08             	sub    $0x8,%esp
f01008f5:	8d 83 42 8c f7 ff    	lea    -0x873be(%ebx),%eax
f01008fb:	50                   	push   %eax
f01008fc:	ff 75 a8             	pushl  -0x58(%ebp)
f01008ff:	e8 98 3b 00 00       	call   f010449c <strcmp>
f0100904:	83 c4 10             	add    $0x10,%esp
f0100907:	85 c0                	test   %eax,%eax
f0100909:	0f 84 b4 00 00 00    	je     f01009c3 <monitor+0x161>
f010090f:	83 ec 08             	sub    $0x8,%esp
f0100912:	8d 83 50 8c f7 ff    	lea    -0x873b0(%ebx),%eax
f0100918:	50                   	push   %eax
f0100919:	ff 75 a8             	pushl  -0x58(%ebp)
f010091c:	e8 7b 3b 00 00       	call   f010449c <strcmp>
f0100921:	83 c4 10             	add    $0x10,%esp
f0100924:	85 c0                	test   %eax,%eax
f0100926:	0f 84 92 00 00 00    	je     f01009be <monitor+0x15c>
	cprintf("Unknown command '%s'\n", argv[0]);
f010092c:	83 ec 08             	sub    $0x8,%esp
f010092f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100932:	8d 83 98 8c f7 ff    	lea    -0x87368(%ebx),%eax
f0100938:	50                   	push   %eax
f0100939:	e8 99 2b 00 00       	call   f01034d7 <cprintf>
	return 0;
f010093e:	83 c4 10             	add    $0x10,%esp
f0100941:	eb 52                	jmp    f0100995 <monitor+0x133>
		if (*buf == 0)
f0100943:	80 3e 00             	cmpb   $0x0,(%esi)
f0100946:	74 9a                	je     f01008e2 <monitor+0x80>
		if (argc == MAXARGS-1) {
f0100948:	83 ff 0f             	cmp    $0xf,%edi
f010094b:	74 34                	je     f0100981 <monitor+0x11f>
		argv[argc++] = buf;
f010094d:	8d 47 01             	lea    0x1(%edi),%eax
f0100950:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100953:	89 74 bd a8          	mov    %esi,-0x58(%ebp,%edi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100957:	0f b6 06             	movzbl (%esi),%eax
f010095a:	84 c0                	test   %al,%al
f010095c:	0f 84 76 ff ff ff    	je     f01008d8 <monitor+0x76>
f0100962:	83 ec 08             	sub    $0x8,%esp
f0100965:	0f be c0             	movsbl %al,%eax
f0100968:	50                   	push   %eax
f0100969:	ff 75 a0             	pushl  -0x60(%ebp)
f010096c:	e8 91 3b 00 00       	call   f0104502 <strchr>
f0100971:	83 c4 10             	add    $0x10,%esp
f0100974:	85 c0                	test   %eax,%eax
f0100976:	0f 85 5c ff ff ff    	jne    f01008d8 <monitor+0x76>
			buf++;
f010097c:	83 c6 01             	add    $0x1,%esi
f010097f:	eb d6                	jmp    f0100957 <monitor+0xf5>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100981:	83 ec 08             	sub    $0x8,%esp
f0100984:	6a 10                	push   $0x10
f0100986:	8d 83 7b 8c f7 ff    	lea    -0x87385(%ebx),%eax
f010098c:	50                   	push   %eax
f010098d:	e8 45 2b 00 00       	call   f01034d7 <cprintf>
			return 0;
f0100992:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100995:	8d bb 72 8c f7 ff    	lea    -0x8738e(%ebx),%edi
f010099b:	83 ec 0c             	sub    $0xc,%esp
f010099e:	57                   	push   %edi
f010099f:	e8 ed 38 00 00       	call   f0104291 <readline>
f01009a4:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f01009a6:	83 c4 10             	add    $0x10,%esp
f01009a9:	85 c0                	test   %eax,%eax
f01009ab:	74 ee                	je     f010099b <monitor+0x139>
	argv[argc] = 0;
f01009ad:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01009b4:	bf 00 00 00 00       	mov    $0x0,%edi
f01009b9:	e9 1d ff ff ff       	jmp    f01008db <monitor+0x79>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009be:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f01009c3:	83 ec 04             	sub    $0x4,%esp
f01009c6:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01009c9:	ff 75 08             	pushl  0x8(%ebp)
f01009cc:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01009cf:	52                   	push   %edx
f01009d0:	57                   	push   %edi
f01009d1:	ff 94 83 1c 20 00 00 	call   *0x201c(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f01009d8:	83 c4 10             	add    $0x10,%esp
f01009db:	85 c0                	test   %eax,%eax
f01009dd:	79 b6                	jns    f0100995 <monitor+0x133>
				break;
	}
}
f01009df:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009e2:	5b                   	pop    %ebx
f01009e3:	5e                   	pop    %esi
f01009e4:	5f                   	pop    %edi
f01009e5:	5d                   	pop    %ebp
f01009e6:	c3                   	ret    

f01009e7 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01009e7:	55                   	push   %ebp
f01009e8:	89 e5                	mov    %esp,%ebp
f01009ea:	57                   	push   %edi
f01009eb:	56                   	push   %esi
f01009ec:	53                   	push   %ebx
f01009ed:	83 ec 18             	sub    $0x18,%esp
f01009f0:	e8 7e f7 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01009f5:	81 c3 27 b6 08 00    	add    $0x8b627,%ebx
f01009fb:	89 c6                	mov    %eax,%esi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01009fd:	50                   	push   %eax
f01009fe:	e8 3d 2a 00 00       	call   f0103440 <mc146818_read>
f0100a03:	89 c7                	mov    %eax,%edi
f0100a05:	83 c6 01             	add    $0x1,%esi
f0100a08:	89 34 24             	mov    %esi,(%esp)
f0100a0b:	e8 30 2a 00 00       	call   f0103440 <mc146818_read>
f0100a10:	c1 e0 08             	shl    $0x8,%eax
f0100a13:	09 f8                	or     %edi,%eax
}
f0100a15:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a18:	5b                   	pop    %ebx
f0100a19:	5e                   	pop    %esi
f0100a1a:	5f                   	pop    %edi
f0100a1b:	5d                   	pop    %ebp
f0100a1c:	c3                   	ret    

f0100a1d <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a1d:	e8 46 25 00 00       	call   f0102f68 <__x86.get_pc_thunk.dx>
f0100a22:	81 c2 fa b5 08 00    	add    $0x8b5fa,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a28:	83 ba fc 22 00 00 00 	cmpl   $0x0,0x22fc(%edx)
f0100a2f:	74 3e                	je     f0100a6f <boot_alloc+0x52>
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.

	// special case
	if(n == 0)
f0100a31:	85 c0                	test   %eax,%eax
f0100a33:	74 54                	je     f0100a89 <boot_alloc+0x6c>
{
f0100a35:	55                   	push   %ebp
f0100a36:	89 e5                	mov    %esp,%ebp
f0100a38:	53                   	push   %ebx
f0100a39:	83 ec 04             	sub    $0x4,%esp
	{
		return nextfree;
	}

	// allocate memory 
	result = nextfree;
f0100a3c:	8b 8a fc 22 00 00    	mov    0x22fc(%edx),%ecx
	nextfree = ROUNDUP(n,PGSIZE)+nextfree;
f0100a42:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100a47:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a4c:	01 c8                	add    %ecx,%eax
f0100a4e:	89 82 fc 22 00 00    	mov    %eax,0x22fc(%edx)

	// out of memory panic
	if((uint32_t)nextfree-KERNBASE>(npages*PGSIZE))
f0100a54:	05 00 00 00 10       	add    $0x10000000,%eax
f0100a59:	c7 c3 e8 ef 18 f0    	mov    $0xf018efe8,%ebx
f0100a5f:	8b 1b                	mov    (%ebx),%ebx
f0100a61:	c1 e3 0c             	shl    $0xc,%ebx
f0100a64:	39 d8                	cmp    %ebx,%eax
f0100a66:	77 2a                	ja     f0100a92 <boot_alloc+0x75>
		// reset the nextfree
		nextfree = result;
		return NULL;
	}
	return result;
}
f0100a68:	89 c8                	mov    %ecx,%eax
f0100a6a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a6d:	c9                   	leave  
f0100a6e:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100a6f:	c7 c1 e0 ef 18 f0    	mov    $0xf018efe0,%ecx
f0100a75:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100a7b:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100a81:	89 8a fc 22 00 00    	mov    %ecx,0x22fc(%edx)
f0100a87:	eb a8                	jmp    f0100a31 <boot_alloc+0x14>
		return nextfree;
f0100a89:	8b 8a fc 22 00 00    	mov    0x22fc(%edx),%ecx
}
f0100a8f:	89 c8                	mov    %ecx,%eax
f0100a91:	c3                   	ret    
		panic("at pmap.c:boot_alloc(): out of memory");
f0100a92:	83 ec 04             	sub    $0x4,%esp
f0100a95:	8d 82 08 8e f7 ff    	lea    -0x871f8(%edx),%eax
f0100a9b:	50                   	push   %eax
f0100a9c:	6a 78                	push   $0x78
f0100a9e:	8d 82 21 96 f7 ff    	lea    -0x869df(%edx),%eax
f0100aa4:	50                   	push   %eax
f0100aa5:	89 d3                	mov    %edx,%ebx
f0100aa7:	e8 09 f6 ff ff       	call   f01000b5 <_panic>

f0100aac <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100aac:	55                   	push   %ebp
f0100aad:	89 e5                	mov    %esp,%ebp
f0100aaf:	56                   	push   %esi
f0100ab0:	53                   	push   %ebx
f0100ab1:	e8 b6 24 00 00       	call   f0102f6c <__x86.get_pc_thunk.cx>
f0100ab6:	81 c1 66 b5 08 00    	add    $0x8b566,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100abc:	89 d3                	mov    %edx,%ebx
f0100abe:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100ac1:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100ac4:	a8 01                	test   $0x1,%al
f0100ac6:	74 59                	je     f0100b21 <check_va2pa+0x75>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100ac8:	89 c3                	mov    %eax,%ebx
f0100aca:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ad0:	c1 e8 0c             	shr    $0xc,%eax
f0100ad3:	c7 c6 e8 ef 18 f0    	mov    $0xf018efe8,%esi
f0100ad9:	3b 06                	cmp    (%esi),%eax
f0100adb:	73 29                	jae    f0100b06 <check_va2pa+0x5a>
	if (!(p[PTX(va)] & PTE_P))
f0100add:	c1 ea 0c             	shr    $0xc,%edx
f0100ae0:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100ae6:	8b 94 93 00 00 00 f0 	mov    -0x10000000(%ebx,%edx,4),%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100aed:	89 d0                	mov    %edx,%eax
f0100aef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100af4:	f6 c2 01             	test   $0x1,%dl
f0100af7:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100afc:	0f 44 c2             	cmove  %edx,%eax
}
f0100aff:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100b02:	5b                   	pop    %ebx
f0100b03:	5e                   	pop    %esi
f0100b04:	5d                   	pop    %ebp
f0100b05:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b06:	53                   	push   %ebx
f0100b07:	8d 81 30 8e f7 ff    	lea    -0x871d0(%ecx),%eax
f0100b0d:	50                   	push   %eax
f0100b0e:	68 6c 03 00 00       	push   $0x36c
f0100b13:	8d 81 21 96 f7 ff    	lea    -0x869df(%ecx),%eax
f0100b19:	50                   	push   %eax
f0100b1a:	89 cb                	mov    %ecx,%ebx
f0100b1c:	e8 94 f5 ff ff       	call   f01000b5 <_panic>
		return ~0;
f0100b21:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b26:	eb d7                	jmp    f0100aff <check_va2pa+0x53>

f0100b28 <check_page_free_list>:
{
f0100b28:	55                   	push   %ebp
f0100b29:	89 e5                	mov    %esp,%ebp
f0100b2b:	57                   	push   %edi
f0100b2c:	56                   	push   %esi
f0100b2d:	53                   	push   %ebx
f0100b2e:	83 ec 2c             	sub    $0x2c,%esp
f0100b31:	e8 f5 fb ff ff       	call   f010072b <__x86.get_pc_thunk.si>
f0100b36:	81 c6 e6 b4 08 00    	add    $0x8b4e6,%esi
f0100b3c:	89 75 c8             	mov    %esi,-0x38(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b3f:	84 c0                	test   %al,%al
f0100b41:	0f 85 ec 02 00 00    	jne    f0100e33 <check_page_free_list+0x30b>
	if (!page_free_list)
f0100b47:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100b4a:	83 b8 00 23 00 00 00 	cmpl   $0x0,0x2300(%eax)
f0100b51:	74 21                	je     f0100b74 <check_page_free_list+0x4c>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b53:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b5a:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100b5d:	8b b0 00 23 00 00    	mov    0x2300(%eax),%esi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b63:	c7 c7 f0 ef 18 f0    	mov    $0xf018eff0,%edi
	if (PGNUM(pa) >= npages)
f0100b69:	c7 c0 e8 ef 18 f0    	mov    $0xf018efe8,%eax
f0100b6f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100b72:	eb 39                	jmp    f0100bad <check_page_free_list+0x85>
		panic("'page_free_list' is a null pointer!");
f0100b74:	83 ec 04             	sub    $0x4,%esp
f0100b77:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100b7a:	8d 83 54 8e f7 ff    	lea    -0x871ac(%ebx),%eax
f0100b80:	50                   	push   %eax
f0100b81:	68 a8 02 00 00       	push   $0x2a8
f0100b86:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0100b8c:	50                   	push   %eax
f0100b8d:	e8 23 f5 ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b92:	50                   	push   %eax
f0100b93:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100b96:	8d 83 30 8e f7 ff    	lea    -0x871d0(%ebx),%eax
f0100b9c:	50                   	push   %eax
f0100b9d:	6a 56                	push   $0x56
f0100b9f:	8d 83 2d 96 f7 ff    	lea    -0x869d3(%ebx),%eax
f0100ba5:	50                   	push   %eax
f0100ba6:	e8 0a f5 ff ff       	call   f01000b5 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bab:	8b 36                	mov    (%esi),%esi
f0100bad:	85 f6                	test   %esi,%esi
f0100baf:	74 40                	je     f0100bf1 <check_page_free_list+0xc9>
	return (pp - pages) << PGSHIFT;
f0100bb1:	89 f0                	mov    %esi,%eax
f0100bb3:	2b 07                	sub    (%edi),%eax
f0100bb5:	c1 f8 03             	sar    $0x3,%eax
f0100bb8:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100bbb:	89 c2                	mov    %eax,%edx
f0100bbd:	c1 ea 16             	shr    $0x16,%edx
f0100bc0:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bc3:	73 e6                	jae    f0100bab <check_page_free_list+0x83>
	if (PGNUM(pa) >= npages)
f0100bc5:	89 c2                	mov    %eax,%edx
f0100bc7:	c1 ea 0c             	shr    $0xc,%edx
f0100bca:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100bcd:	3b 11                	cmp    (%ecx),%edx
f0100bcf:	73 c1                	jae    f0100b92 <check_page_free_list+0x6a>
			memset(page2kva(pp), 0x97, 128);
f0100bd1:	83 ec 04             	sub    $0x4,%esp
f0100bd4:	68 80 00 00 00       	push   $0x80
f0100bd9:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100bde:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100be3:	50                   	push   %eax
f0100be4:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100be7:	e8 5b 39 00 00       	call   f0104547 <memset>
f0100bec:	83 c4 10             	add    $0x10,%esp
f0100bef:	eb ba                	jmp    f0100bab <check_page_free_list+0x83>
	first_free_page = (char *) boot_alloc(0);
f0100bf1:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bf6:	e8 22 fe ff ff       	call   f0100a1d <boot_alloc>
f0100bfb:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bfe:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0100c01:	8b 97 00 23 00 00    	mov    0x2300(%edi),%edx
		assert(pp >= pages);
f0100c07:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f0100c0d:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100c0f:	c7 c0 e8 ef 18 f0    	mov    $0xf018efe8,%eax
f0100c15:	8b 00                	mov    (%eax),%eax
f0100c17:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100c1a:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c1d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c22:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c25:	e9 08 01 00 00       	jmp    f0100d32 <check_page_free_list+0x20a>
		assert(pp >= pages);
f0100c2a:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100c2d:	8d 83 3b 96 f7 ff    	lea    -0x869c5(%ebx),%eax
f0100c33:	50                   	push   %eax
f0100c34:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0100c3a:	50                   	push   %eax
f0100c3b:	68 c2 02 00 00       	push   $0x2c2
f0100c40:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0100c46:	50                   	push   %eax
f0100c47:	e8 69 f4 ff ff       	call   f01000b5 <_panic>
		assert(pp < pages + npages);
f0100c4c:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100c4f:	8d 83 5c 96 f7 ff    	lea    -0x869a4(%ebx),%eax
f0100c55:	50                   	push   %eax
f0100c56:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0100c5c:	50                   	push   %eax
f0100c5d:	68 c3 02 00 00       	push   $0x2c3
f0100c62:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0100c68:	50                   	push   %eax
f0100c69:	e8 47 f4 ff ff       	call   f01000b5 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c6e:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100c71:	8d 83 78 8e f7 ff    	lea    -0x87188(%ebx),%eax
f0100c77:	50                   	push   %eax
f0100c78:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0100c7e:	50                   	push   %eax
f0100c7f:	68 c4 02 00 00       	push   $0x2c4
f0100c84:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0100c8a:	50                   	push   %eax
f0100c8b:	e8 25 f4 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) != 0);
f0100c90:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100c93:	8d 83 70 96 f7 ff    	lea    -0x86990(%ebx),%eax
f0100c99:	50                   	push   %eax
f0100c9a:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0100ca0:	50                   	push   %eax
f0100ca1:	68 c7 02 00 00       	push   $0x2c7
f0100ca6:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0100cac:	50                   	push   %eax
f0100cad:	e8 03 f4 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100cb2:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100cb5:	8d 83 81 96 f7 ff    	lea    -0x8697f(%ebx),%eax
f0100cbb:	50                   	push   %eax
f0100cbc:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0100cc2:	50                   	push   %eax
f0100cc3:	68 c8 02 00 00       	push   $0x2c8
f0100cc8:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0100cce:	50                   	push   %eax
f0100ccf:	e8 e1 f3 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cd4:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100cd7:	8d 83 ac 8e f7 ff    	lea    -0x87154(%ebx),%eax
f0100cdd:	50                   	push   %eax
f0100cde:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0100ce4:	50                   	push   %eax
f0100ce5:	68 c9 02 00 00       	push   $0x2c9
f0100cea:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0100cf0:	50                   	push   %eax
f0100cf1:	e8 bf f3 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cf6:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100cf9:	8d 83 9a 96 f7 ff    	lea    -0x86966(%ebx),%eax
f0100cff:	50                   	push   %eax
f0100d00:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0100d06:	50                   	push   %eax
f0100d07:	68 ca 02 00 00       	push   $0x2ca
f0100d0c:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0100d12:	50                   	push   %eax
f0100d13:	e8 9d f3 ff ff       	call   f01000b5 <_panic>
	if (PGNUM(pa) >= npages)
f0100d18:	89 c3                	mov    %eax,%ebx
f0100d1a:	c1 eb 0c             	shr    $0xc,%ebx
f0100d1d:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0100d20:	76 6d                	jbe    f0100d8f <check_page_free_list+0x267>
	return (void *)(pa + KERNBASE);
f0100d22:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d27:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100d2a:	77 7c                	ja     f0100da8 <check_page_free_list+0x280>
			++nfree_extmem;
f0100d2c:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d30:	8b 12                	mov    (%edx),%edx
f0100d32:	85 d2                	test   %edx,%edx
f0100d34:	0f 84 90 00 00 00    	je     f0100dca <check_page_free_list+0x2a2>
		assert(pp >= pages);
f0100d3a:	39 d1                	cmp    %edx,%ecx
f0100d3c:	0f 87 e8 fe ff ff    	ja     f0100c2a <check_page_free_list+0x102>
		assert(pp < pages + npages);
f0100d42:	39 d7                	cmp    %edx,%edi
f0100d44:	0f 86 02 ff ff ff    	jbe    f0100c4c <check_page_free_list+0x124>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d4a:	89 d0                	mov    %edx,%eax
f0100d4c:	29 c8                	sub    %ecx,%eax
f0100d4e:	a8 07                	test   $0x7,%al
f0100d50:	0f 85 18 ff ff ff    	jne    f0100c6e <check_page_free_list+0x146>
	return (pp - pages) << PGSHIFT;
f0100d56:	c1 f8 03             	sar    $0x3,%eax
		assert(page2pa(pp) != 0);
f0100d59:	c1 e0 0c             	shl    $0xc,%eax
f0100d5c:	0f 84 2e ff ff ff    	je     f0100c90 <check_page_free_list+0x168>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d62:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100d67:	0f 84 45 ff ff ff    	je     f0100cb2 <check_page_free_list+0x18a>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d6d:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100d72:	0f 84 5c ff ff ff    	je     f0100cd4 <check_page_free_list+0x1ac>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d78:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d7d:	0f 84 73 ff ff ff    	je     f0100cf6 <check_page_free_list+0x1ce>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d83:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d88:	77 8e                	ja     f0100d18 <check_page_free_list+0x1f0>
			++nfree_basemem;
f0100d8a:	83 c6 01             	add    $0x1,%esi
f0100d8d:	eb a1                	jmp    f0100d30 <check_page_free_list+0x208>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d8f:	50                   	push   %eax
f0100d90:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100d93:	8d 83 30 8e f7 ff    	lea    -0x871d0(%ebx),%eax
f0100d99:	50                   	push   %eax
f0100d9a:	6a 56                	push   $0x56
f0100d9c:	8d 83 2d 96 f7 ff    	lea    -0x869d3(%ebx),%eax
f0100da2:	50                   	push   %eax
f0100da3:	e8 0d f3 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100da8:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100dab:	8d 83 d0 8e f7 ff    	lea    -0x87130(%ebx),%eax
f0100db1:	50                   	push   %eax
f0100db2:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0100db8:	50                   	push   %eax
f0100db9:	68 cb 02 00 00       	push   $0x2cb
f0100dbe:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0100dc4:	50                   	push   %eax
f0100dc5:	e8 eb f2 ff ff       	call   f01000b5 <_panic>
f0100dca:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
	assert(nfree_basemem > 0);
f0100dcd:	85 f6                	test   %esi,%esi
f0100dcf:	7e 1e                	jle    f0100def <check_page_free_list+0x2c7>
	assert(nfree_extmem > 0);
f0100dd1:	85 db                	test   %ebx,%ebx
f0100dd3:	7e 3c                	jle    f0100e11 <check_page_free_list+0x2e9>
	cprintf("check_page_free_list() succeeded!\n");
f0100dd5:	83 ec 0c             	sub    $0xc,%esp
f0100dd8:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100ddb:	8d 83 18 8f f7 ff    	lea    -0x870e8(%ebx),%eax
f0100de1:	50                   	push   %eax
f0100de2:	e8 f0 26 00 00       	call   f01034d7 <cprintf>
}
f0100de7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100dea:	5b                   	pop    %ebx
f0100deb:	5e                   	pop    %esi
f0100dec:	5f                   	pop    %edi
f0100ded:	5d                   	pop    %ebp
f0100dee:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100def:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100df2:	8d 83 b4 96 f7 ff    	lea    -0x8694c(%ebx),%eax
f0100df8:	50                   	push   %eax
f0100df9:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0100dff:	50                   	push   %eax
f0100e00:	68 d3 02 00 00       	push   $0x2d3
f0100e05:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0100e0b:	50                   	push   %eax
f0100e0c:	e8 a4 f2 ff ff       	call   f01000b5 <_panic>
	assert(nfree_extmem > 0);
f0100e11:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100e14:	8d 83 c6 96 f7 ff    	lea    -0x8693a(%ebx),%eax
f0100e1a:	50                   	push   %eax
f0100e1b:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0100e21:	50                   	push   %eax
f0100e22:	68 d4 02 00 00       	push   $0x2d4
f0100e27:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0100e2d:	50                   	push   %eax
f0100e2e:	e8 82 f2 ff ff       	call   f01000b5 <_panic>
	if (!page_free_list)
f0100e33:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100e36:	8b 80 00 23 00 00    	mov    0x2300(%eax),%eax
f0100e3c:	85 c0                	test   %eax,%eax
f0100e3e:	0f 84 30 fd ff ff    	je     f0100b74 <check_page_free_list+0x4c>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100e44:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100e47:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e4a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e4d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100e50:	8b 75 c8             	mov    -0x38(%ebp),%esi
f0100e53:	c7 c3 f0 ef 18 f0    	mov    $0xf018eff0,%ebx
f0100e59:	89 c2                	mov    %eax,%edx
f0100e5b:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100e5d:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100e63:	0f 95 c2             	setne  %dl
f0100e66:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100e69:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100e6d:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100e6f:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e73:	8b 00                	mov    (%eax),%eax
f0100e75:	85 c0                	test   %eax,%eax
f0100e77:	75 e0                	jne    f0100e59 <check_page_free_list+0x331>
		*tp[1] = 0;
f0100e79:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e7c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100e82:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e85:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e88:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100e8a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100e8d:	8b 75 c8             	mov    -0x38(%ebp),%esi
f0100e90:	89 86 00 23 00 00    	mov    %eax,0x2300(%esi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e96:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
f0100e9d:	e9 b8 fc ff ff       	jmp    f0100b5a <check_page_free_list+0x32>

f0100ea2 <page_init>:
{
f0100ea2:	f3 0f 1e fb          	endbr32 
f0100ea6:	55                   	push   %ebp
f0100ea7:	89 e5                	mov    %esp,%ebp
f0100ea9:	57                   	push   %edi
f0100eaa:	56                   	push   %esi
f0100eab:	53                   	push   %ebx
f0100eac:	83 ec 2c             	sub    $0x2c,%esp
f0100eaf:	e8 b4 20 00 00       	call   f0102f68 <__x86.get_pc_thunk.dx>
f0100eb4:	81 c2 68 b1 08 00    	add    $0x8b168,%edx
f0100eba:	89 d7                	mov    %edx,%edi
f0100ebc:	89 55 d0             	mov    %edx,-0x30(%ebp)
	size_t num_used = ((uint32_t)boot_alloc(0)-EXTPHYSMEM-KERNBASE)/PGSIZE;
f0100ebf:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ec4:	e8 54 fb ff ff       	call   f0100a1d <boot_alloc>
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100ec9:	8b 8f 04 23 00 00    	mov    0x2304(%edi),%ecx
f0100ecf:	89 4d e0             	mov    %ecx,-0x20(%ebp)
	size_t num_used = ((uint32_t)boot_alloc(0)-EXTPHYSMEM-KERNBASE)/PGSIZE;
f0100ed2:	05 00 00 f0 0f       	add    $0xff00000,%eax
f0100ed7:	c1 e8 0c             	shr    $0xc,%eax
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100eda:	8d 44 01 60          	lea    0x60(%ecx,%eax,1),%eax
f0100ede:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100ee1:	8b b7 00 23 00 00    	mov    0x2300(%edi),%esi
	for(size_t i = 0;i<npages;i++)
f0100ee7:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100eec:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ef1:	c7 c2 e8 ef 18 f0    	mov    $0xf018efe8,%edx
			pages[i].pp_ref = 0;
f0100ef7:	c7 c1 f0 ef 18 f0    	mov    $0xf018eff0,%ecx
f0100efd:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
			pages[i].pp_ref = 1;
f0100f00:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
			pages[i].pp_ref = 1;
f0100f03:	89 4d dc             	mov    %ecx,-0x24(%ebp)
	for(size_t i = 0;i<npages;i++)
f0100f06:	eb 3d                	jmp    f0100f45 <page_init+0xa3>
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100f08:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f0100f0b:	77 13                	ja     f0100f20 <page_init+0x7e>
f0100f0d:	39 45 d8             	cmp    %eax,-0x28(%ebp)
f0100f10:	76 0e                	jbe    f0100f20 <page_init+0x7e>
			pages[i].pp_ref = 1;
f0100f12:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100f15:	8b 09                	mov    (%ecx),%ecx
f0100f17:	66 c7 44 c1 04 01 00 	movw   $0x1,0x4(%ecx,%eax,8)
f0100f1e:	eb 22                	jmp    f0100f42 <page_init+0xa0>
f0100f20:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
			pages[i].pp_ref = 0;
f0100f27:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100f2a:	89 cf                	mov    %ecx,%edi
f0100f2c:	03 3b                	add    (%ebx),%edi
f0100f2e:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
			pages[i].pp_link = page_free_list;
f0100f34:	89 37                	mov    %esi,(%edi)
			page_free_list = &pages[i];
f0100f36:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100f39:	89 ce                	mov    %ecx,%esi
f0100f3b:	03 33                	add    (%ebx),%esi
f0100f3d:	bb 01 00 00 00       	mov    $0x1,%ebx
	for(size_t i = 0;i<npages;i++)
f0100f42:	83 c0 01             	add    $0x1,%eax
f0100f45:	39 02                	cmp    %eax,(%edx)
f0100f47:	76 11                	jbe    f0100f5a <page_init+0xb8>
		if(i == 0)
f0100f49:	85 c0                	test   %eax,%eax
f0100f4b:	75 bb                	jne    f0100f08 <page_init+0x66>
			pages[i].pp_ref = 1;
f0100f4d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100f50:	8b 0f                	mov    (%edi),%ecx
f0100f52:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
f0100f58:	eb e8                	jmp    f0100f42 <page_init+0xa0>
f0100f5a:	84 db                	test   %bl,%bl
f0100f5c:	74 09                	je     f0100f67 <page_init+0xc5>
f0100f5e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100f61:	89 b0 00 23 00 00    	mov    %esi,0x2300(%eax)
}
f0100f67:	83 c4 2c             	add    $0x2c,%esp
f0100f6a:	5b                   	pop    %ebx
f0100f6b:	5e                   	pop    %esi
f0100f6c:	5f                   	pop    %edi
f0100f6d:	5d                   	pop    %ebp
f0100f6e:	c3                   	ret    

f0100f6f <page_alloc>:
{
f0100f6f:	f3 0f 1e fb          	endbr32 
f0100f73:	55                   	push   %ebp
f0100f74:	89 e5                	mov    %esp,%ebp
f0100f76:	56                   	push   %esi
f0100f77:	53                   	push   %ebx
f0100f78:	e8 f6 f1 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0100f7d:	81 c3 9f b0 08 00    	add    $0x8b09f,%ebx
	if(page_free_list == NULL)
f0100f83:	8b b3 00 23 00 00    	mov    0x2300(%ebx),%esi
f0100f89:	85 f6                	test   %esi,%esi
f0100f8b:	74 37                	je     f0100fc4 <page_alloc+0x55>
	page_free_list = page_free_list->pp_link;
f0100f8d:	8b 06                	mov    (%esi),%eax
f0100f8f:	89 83 00 23 00 00    	mov    %eax,0x2300(%ebx)
	alloc->pp_link = NULL;
f0100f95:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
f0100f9b:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f0100fa1:	89 f1                	mov    %esi,%ecx
f0100fa3:	2b 08                	sub    (%eax),%ecx
f0100fa5:	89 c8                	mov    %ecx,%eax
f0100fa7:	c1 f8 03             	sar    $0x3,%eax
f0100faa:	89 c1                	mov    %eax,%ecx
f0100fac:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f0100faf:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0100fb4:	c7 c2 e8 ef 18 f0    	mov    $0xf018efe8,%edx
f0100fba:	3b 02                	cmp    (%edx),%eax
f0100fbc:	73 0f                	jae    f0100fcd <page_alloc+0x5e>
	if(alloc_flags & ALLOC_ZERO)
f0100fbe:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100fc2:	75 1f                	jne    f0100fe3 <page_alloc+0x74>
}
f0100fc4:	89 f0                	mov    %esi,%eax
f0100fc6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100fc9:	5b                   	pop    %ebx
f0100fca:	5e                   	pop    %esi
f0100fcb:	5d                   	pop    %ebp
f0100fcc:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fcd:	51                   	push   %ecx
f0100fce:	8d 83 30 8e f7 ff    	lea    -0x871d0(%ebx),%eax
f0100fd4:	50                   	push   %eax
f0100fd5:	6a 56                	push   $0x56
f0100fd7:	8d 83 2d 96 f7 ff    	lea    -0x869d3(%ebx),%eax
f0100fdd:	50                   	push   %eax
f0100fde:	e8 d2 f0 ff ff       	call   f01000b5 <_panic>
		memset(head,0,PGSIZE);
f0100fe3:	83 ec 04             	sub    $0x4,%esp
f0100fe6:	68 00 10 00 00       	push   $0x1000
f0100feb:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100fed:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100ff3:	51                   	push   %ecx
f0100ff4:	e8 4e 35 00 00       	call   f0104547 <memset>
f0100ff9:	83 c4 10             	add    $0x10,%esp
f0100ffc:	eb c6                	jmp    f0100fc4 <page_alloc+0x55>

f0100ffe <page_free>:
{
f0100ffe:	f3 0f 1e fb          	endbr32 
f0101002:	55                   	push   %ebp
f0101003:	89 e5                	mov    %esp,%ebp
f0101005:	53                   	push   %ebx
f0101006:	83 ec 04             	sub    $0x4,%esp
f0101009:	e8 65 f1 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f010100e:	81 c3 0e b0 08 00    	add    $0x8b00e,%ebx
f0101014:	8b 45 08             	mov    0x8(%ebp),%eax
	if((pp->pp_ref != 0) | (pp->pp_link!=NULL))
f0101017:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010101c:	75 18                	jne    f0101036 <page_free+0x38>
f010101e:	83 38 00             	cmpl   $0x0,(%eax)
f0101021:	75 13                	jne    f0101036 <page_free+0x38>
	pp->pp_link = page_free_list;
f0101023:	8b 8b 00 23 00 00    	mov    0x2300(%ebx),%ecx
f0101029:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f010102b:	89 83 00 23 00 00    	mov    %eax,0x2300(%ebx)
}
f0101031:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101034:	c9                   	leave  
f0101035:	c3                   	ret    
		panic("at pmap.c:page_free():330 Page double free or freeing a referenced page");
f0101036:	83 ec 04             	sub    $0x4,%esp
f0101039:	8d 83 3c 8f f7 ff    	lea    -0x870c4(%ebx),%eax
f010103f:	50                   	push   %eax
f0101040:	68 71 01 00 00       	push   $0x171
f0101045:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010104b:	50                   	push   %eax
f010104c:	e8 64 f0 ff ff       	call   f01000b5 <_panic>

f0101051 <page_decref>:
{
f0101051:	f3 0f 1e fb          	endbr32 
f0101055:	55                   	push   %ebp
f0101056:	89 e5                	mov    %esp,%ebp
f0101058:	83 ec 08             	sub    $0x8,%esp
f010105b:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f010105e:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101062:	83 e8 01             	sub    $0x1,%eax
f0101065:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101069:	66 85 c0             	test   %ax,%ax
f010106c:	74 02                	je     f0101070 <page_decref+0x1f>
}
f010106e:	c9                   	leave  
f010106f:	c3                   	ret    
		page_free(pp);
f0101070:	83 ec 0c             	sub    $0xc,%esp
f0101073:	52                   	push   %edx
f0101074:	e8 85 ff ff ff       	call   f0100ffe <page_free>
f0101079:	83 c4 10             	add    $0x10,%esp
}
f010107c:	eb f0                	jmp    f010106e <page_decref+0x1d>

f010107e <pgdir_walk>:
{
f010107e:	f3 0f 1e fb          	endbr32 
f0101082:	55                   	push   %ebp
f0101083:	89 e5                	mov    %esp,%ebp
f0101085:	57                   	push   %edi
f0101086:	56                   	push   %esi
f0101087:	53                   	push   %ebx
f0101088:	83 ec 0c             	sub    $0xc,%esp
f010108b:	e8 e0 1e 00 00       	call   f0102f70 <__x86.get_pc_thunk.di>
f0101090:	81 c7 8c af 08 00    	add    $0x8af8c,%edi
f0101096:	8b 75 0c             	mov    0xc(%ebp),%esi
	unsigned int dir_offset = PDX(va);
f0101099:	89 f3                	mov    %esi,%ebx
f010109b:	c1 eb 16             	shr    $0x16,%ebx
	pde_t* entry = pgdir+dir_offset;
f010109e:	c1 e3 02             	shl    $0x2,%ebx
f01010a1:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*entry & PTE_P))
f01010a4:	f6 03 01             	testb  $0x1,(%ebx)
f01010a7:	75 2f                	jne    f01010d8 <pgdir_walk+0x5a>
		if(create)
f01010a9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01010ad:	74 73                	je     f0101122 <pgdir_walk+0xa4>
			new_page = page_alloc(1);
f01010af:	83 ec 0c             	sub    $0xc,%esp
f01010b2:	6a 01                	push   $0x1
f01010b4:	e8 b6 fe ff ff       	call   f0100f6f <page_alloc>
			if(new_page == NULL)
f01010b9:	83 c4 10             	add    $0x10,%esp
f01010bc:	85 c0                	test   %eax,%eax
f01010be:	74 3f                	je     f01010ff <pgdir_walk+0x81>
			new_page->pp_ref++;
f01010c0:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f01010c5:	c7 c2 f0 ef 18 f0    	mov    $0xf018eff0,%edx
f01010cb:	2b 02                	sub    (%edx),%eax
f01010cd:	c1 f8 03             	sar    $0x3,%eax
f01010d0:	c1 e0 0c             	shl    $0xc,%eax
			*entry = ((page2pa(new_page))|PTE_P|PTE_W|PTE_U);
f01010d3:	83 c8 07             	or     $0x7,%eax
f01010d6:	89 03                	mov    %eax,(%ebx)
	page_base = (pte_t*)KADDR(PTE_ADDR(*entry));
f01010d8:	8b 03                	mov    (%ebx),%eax
f01010da:	89 c2                	mov    %eax,%edx
f01010dc:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f01010e2:	c1 e8 0c             	shr    $0xc,%eax
f01010e5:	c7 c1 e8 ef 18 f0    	mov    $0xf018efe8,%ecx
f01010eb:	3b 01                	cmp    (%ecx),%eax
f01010ed:	73 18                	jae    f0101107 <pgdir_walk+0x89>
	page_offset = PTX(va);
f01010ef:	c1 ee 0a             	shr    $0xa,%esi
	return &page_base[page_offset];
f01010f2:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01010f8:	8d 84 32 00 00 00 f0 	lea    -0x10000000(%edx,%esi,1),%eax
}
f01010ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101102:	5b                   	pop    %ebx
f0101103:	5e                   	pop    %esi
f0101104:	5f                   	pop    %edi
f0101105:	5d                   	pop    %ebp
f0101106:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101107:	52                   	push   %edx
f0101108:	8d 87 30 8e f7 ff    	lea    -0x871d0(%edi),%eax
f010110e:	50                   	push   %eax
f010110f:	68 bb 01 00 00       	push   $0x1bb
f0101114:	8d 87 21 96 f7 ff    	lea    -0x869df(%edi),%eax
f010111a:	50                   	push   %eax
f010111b:	89 fb                	mov    %edi,%ebx
f010111d:	e8 93 ef ff ff       	call   f01000b5 <_panic>
			return NULL;
f0101122:	b8 00 00 00 00       	mov    $0x0,%eax
f0101127:	eb d6                	jmp    f01010ff <pgdir_walk+0x81>

f0101129 <boot_map_region>:
{
f0101129:	55                   	push   %ebp
f010112a:	89 e5                	mov    %esp,%ebp
f010112c:	57                   	push   %edi
f010112d:	56                   	push   %esi
f010112e:	53                   	push   %ebx
f010112f:	83 ec 1c             	sub    $0x1c,%esp
f0101132:	89 c7                	mov    %eax,%edi
f0101134:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101137:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for(add = 0;add<size;add+=PGSIZE)
f010113a:	be 00 00 00 00       	mov    $0x0,%esi
f010113f:	89 f3                	mov    %esi,%ebx
f0101141:	03 5d 08             	add    0x8(%ebp),%ebx
f0101144:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f0101147:	76 24                	jbe    f010116d <boot_map_region+0x44>
		entry = pgdir_walk(pgdir,(void*)va,1);  // get the entry of page table
f0101149:	83 ec 04             	sub    $0x4,%esp
f010114c:	6a 01                	push   $0x1
f010114e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101151:	01 f0                	add    %esi,%eax
f0101153:	50                   	push   %eax
f0101154:	57                   	push   %edi
f0101155:	e8 24 ff ff ff       	call   f010107e <pgdir_walk>
		*entry = (pa|perm|PTE_P);
f010115a:	0b 5d 0c             	or     0xc(%ebp),%ebx
f010115d:	83 cb 01             	or     $0x1,%ebx
f0101160:	89 18                	mov    %ebx,(%eax)
	for(add = 0;add<size;add+=PGSIZE)
f0101162:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0101168:	83 c4 10             	add    $0x10,%esp
f010116b:	eb d2                	jmp    f010113f <boot_map_region+0x16>
}
f010116d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101170:	5b                   	pop    %ebx
f0101171:	5e                   	pop    %esi
f0101172:	5f                   	pop    %edi
f0101173:	5d                   	pop    %ebp
f0101174:	c3                   	ret    

f0101175 <page_lookup>:
{
f0101175:	f3 0f 1e fb          	endbr32 
f0101179:	55                   	push   %ebp
f010117a:	89 e5                	mov    %esp,%ebp
f010117c:	56                   	push   %esi
f010117d:	53                   	push   %ebx
f010117e:	e8 f0 ef ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0101183:	81 c3 99 ae 08 00    	add    $0x8ae99,%ebx
f0101189:	8b 75 10             	mov    0x10(%ebp),%esi
	entry = pgdir_walk(pgdir,va,0);
f010118c:	83 ec 04             	sub    $0x4,%esp
f010118f:	6a 00                	push   $0x0
f0101191:	ff 75 0c             	pushl  0xc(%ebp)
f0101194:	ff 75 08             	pushl  0x8(%ebp)
f0101197:	e8 e2 fe ff ff       	call   f010107e <pgdir_walk>
	if(entry == NULL)
f010119c:	83 c4 10             	add    $0x10,%esp
f010119f:	85 c0                	test   %eax,%eax
f01011a1:	74 46                	je     f01011e9 <page_lookup+0x74>
	if(!(*entry & PTE_P))
f01011a3:	8b 10                	mov    (%eax),%edx
f01011a5:	f6 c2 01             	test   $0x1,%dl
f01011a8:	74 43                	je     f01011ed <page_lookup+0x78>
f01011aa:	c1 ea 0c             	shr    $0xc,%edx
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011ad:	c7 c1 e8 ef 18 f0    	mov    $0xf018efe8,%ecx
f01011b3:	39 11                	cmp    %edx,(%ecx)
f01011b5:	76 1a                	jbe    f01011d1 <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f01011b7:	c7 c1 f0 ef 18 f0    	mov    $0xf018eff0,%ecx
f01011bd:	8b 09                	mov    (%ecx),%ecx
f01011bf:	8d 14 d1             	lea    (%ecx,%edx,8),%edx
	if(pte_store != NULL)
f01011c2:	85 f6                	test   %esi,%esi
f01011c4:	74 02                	je     f01011c8 <page_lookup+0x53>
		*pte_store = entry;
f01011c6:	89 06                	mov    %eax,(%esi)
}
f01011c8:	89 d0                	mov    %edx,%eax
f01011ca:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01011cd:	5b                   	pop    %ebx
f01011ce:	5e                   	pop    %esi
f01011cf:	5d                   	pop    %ebp
f01011d0:	c3                   	ret    
		panic("pa2page called with invalid pa");
f01011d1:	83 ec 04             	sub    $0x4,%esp
f01011d4:	8d 83 84 8f f7 ff    	lea    -0x8707c(%ebx),%eax
f01011da:	50                   	push   %eax
f01011db:	6a 4f                	push   $0x4f
f01011dd:	8d 83 2d 96 f7 ff    	lea    -0x869d3(%ebx),%eax
f01011e3:	50                   	push   %eax
f01011e4:	e8 cc ee ff ff       	call   f01000b5 <_panic>
		return NULL;
f01011e9:	89 c2                	mov    %eax,%edx
f01011eb:	eb db                	jmp    f01011c8 <page_lookup+0x53>
		return NULL;
f01011ed:	ba 00 00 00 00       	mov    $0x0,%edx
f01011f2:	eb d4                	jmp    f01011c8 <page_lookup+0x53>

f01011f4 <page_remove>:
{
f01011f4:	f3 0f 1e fb          	endbr32 
f01011f8:	55                   	push   %ebp
f01011f9:	89 e5                	mov    %esp,%ebp
f01011fb:	53                   	push   %ebx
f01011fc:	83 ec 18             	sub    $0x18,%esp
f01011ff:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t* pte = NULL;
f0101202:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo* page = page_lookup(pgdir,va,&pte);
f0101209:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010120c:	50                   	push   %eax
f010120d:	53                   	push   %ebx
f010120e:	ff 75 08             	pushl  0x8(%ebp)
f0101211:	e8 5f ff ff ff       	call   f0101175 <page_lookup>
	if(page == NULL)
f0101216:	83 c4 10             	add    $0x10,%esp
f0101219:	85 c0                	test   %eax,%eax
f010121b:	74 18                	je     f0101235 <page_remove+0x41>
	page_decref(page);
f010121d:	83 ec 0c             	sub    $0xc,%esp
f0101220:	50                   	push   %eax
f0101221:	e8 2b fe ff ff       	call   f0101051 <page_decref>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101226:	0f 01 3b             	invlpg (%ebx)
	*pte = 0;
f0101229:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010122c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101232:	83 c4 10             	add    $0x10,%esp
}
f0101235:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101238:	c9                   	leave  
f0101239:	c3                   	ret    

f010123a <page_insert>:
{
f010123a:	f3 0f 1e fb          	endbr32 
f010123e:	55                   	push   %ebp
f010123f:	89 e5                	mov    %esp,%ebp
f0101241:	57                   	push   %edi
f0101242:	56                   	push   %esi
f0101243:	53                   	push   %ebx
f0101244:	83 ec 10             	sub    $0x10,%esp
f0101247:	e8 24 1d 00 00       	call   f0102f70 <__x86.get_pc_thunk.di>
f010124c:	81 c7 d0 ad 08 00    	add    $0x8add0,%edi
f0101252:	8b 75 08             	mov    0x8(%ebp),%esi
	entry = pgdir_walk(pgdir,va,1); // get the page table entry 
f0101255:	6a 01                	push   $0x1
f0101257:	ff 75 10             	pushl  0x10(%ebp)
f010125a:	56                   	push   %esi
f010125b:	e8 1e fe ff ff       	call   f010107e <pgdir_walk>
	if(entry == NULL)
f0101260:	83 c4 10             	add    $0x10,%esp
f0101263:	85 c0                	test   %eax,%eax
f0101265:	74 5a                	je     f01012c1 <page_insert+0x87>
f0101267:	89 c3                	mov    %eax,%ebx
	pp->pp_ref++;
f0101269:	8b 45 0c             	mov    0xc(%ebp),%eax
f010126c:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	if(*entry&PTE_P)
f0101271:	f6 03 01             	testb  $0x1,(%ebx)
f0101274:	75 34                	jne    f01012aa <page_insert+0x70>
	return (pp - pages) << PGSHIFT;
f0101276:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f010127c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010127f:	2b 10                	sub    (%eax),%edx
f0101281:	89 d0                	mov    %edx,%eax
f0101283:	c1 f8 03             	sar    $0x3,%eax
f0101286:	c1 e0 0c             	shl    $0xc,%eax
	*entry = ((page2pa(pp))|perm|PTE_P);
f0101289:	0b 45 14             	or     0x14(%ebp),%eax
f010128c:	83 c8 01             	or     $0x1,%eax
f010128f:	89 03                	mov    %eax,(%ebx)
	pgdir[PDX(va)] |= perm;
f0101291:	8b 45 10             	mov    0x10(%ebp),%eax
f0101294:	c1 e8 16             	shr    $0x16,%eax
f0101297:	8b 4d 14             	mov    0x14(%ebp),%ecx
f010129a:	09 0c 86             	or     %ecx,(%esi,%eax,4)
	return 0;
f010129d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01012a2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012a5:	5b                   	pop    %ebx
f01012a6:	5e                   	pop    %esi
f01012a7:	5f                   	pop    %edi
f01012a8:	5d                   	pop    %ebp
f01012a9:	c3                   	ret    
f01012aa:	8b 45 10             	mov    0x10(%ebp),%eax
f01012ad:	0f 01 38             	invlpg (%eax)
		page_remove(pgdir,va);
f01012b0:	83 ec 08             	sub    $0x8,%esp
f01012b3:	ff 75 10             	pushl  0x10(%ebp)
f01012b6:	56                   	push   %esi
f01012b7:	e8 38 ff ff ff       	call   f01011f4 <page_remove>
f01012bc:	83 c4 10             	add    $0x10,%esp
f01012bf:	eb b5                	jmp    f0101276 <page_insert+0x3c>
		return -E_NO_MEM;
f01012c1:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01012c6:	eb da                	jmp    f01012a2 <page_insert+0x68>

f01012c8 <mem_init>:
{
f01012c8:	f3 0f 1e fb          	endbr32 
f01012cc:	55                   	push   %ebp
f01012cd:	89 e5                	mov    %esp,%ebp
f01012cf:	57                   	push   %edi
f01012d0:	56                   	push   %esi
f01012d1:	53                   	push   %ebx
f01012d2:	83 ec 3c             	sub    $0x3c,%esp
f01012d5:	e8 99 ee ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01012da:	81 c3 42 ad 08 00    	add    $0x8ad42,%ebx
	basemem = nvram_read(NVRAM_BASELO);
f01012e0:	b8 15 00 00 00       	mov    $0x15,%eax
f01012e5:	e8 fd f6 ff ff       	call   f01009e7 <nvram_read>
f01012ea:	89 c6                	mov    %eax,%esi
	extmem = nvram_read(NVRAM_EXTLO);
f01012ec:	b8 17 00 00 00       	mov    $0x17,%eax
f01012f1:	e8 f1 f6 ff ff       	call   f01009e7 <nvram_read>
f01012f6:	89 c7                	mov    %eax,%edi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01012f8:	b8 34 00 00 00       	mov    $0x34,%eax
f01012fd:	e8 e5 f6 ff ff       	call   f01009e7 <nvram_read>
	if (ext16mem)
f0101302:	c1 e0 06             	shl    $0x6,%eax
f0101305:	0f 84 ec 00 00 00    	je     f01013f7 <mem_init+0x12f>
		totalmem = 16 * 1024 + ext16mem;
f010130b:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f0101310:	89 c1                	mov    %eax,%ecx
f0101312:	c1 e9 02             	shr    $0x2,%ecx
f0101315:	c7 c2 e8 ef 18 f0    	mov    $0xf018efe8,%edx
f010131b:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f010131d:	89 f2                	mov    %esi,%edx
f010131f:	c1 ea 02             	shr    $0x2,%edx
f0101322:	89 93 04 23 00 00    	mov    %edx,0x2304(%ebx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101328:	89 c2                	mov    %eax,%edx
f010132a:	29 f2                	sub    %esi,%edx
f010132c:	52                   	push   %edx
f010132d:	56                   	push   %esi
f010132e:	50                   	push   %eax
f010132f:	8d 83 a4 8f f7 ff    	lea    -0x8705c(%ebx),%eax
f0101335:	50                   	push   %eax
f0101336:	e8 9c 21 00 00       	call   f01034d7 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010133b:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101340:	e8 d8 f6 ff ff       	call   f0100a1d <boot_alloc>
f0101345:	c7 c6 ec ef 18 f0    	mov    $0xf018efec,%esi
f010134b:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f010134d:	83 c4 0c             	add    $0xc,%esp
f0101350:	68 00 10 00 00       	push   $0x1000
f0101355:	6a 00                	push   $0x0
f0101357:	50                   	push   %eax
f0101358:	e8 ea 31 00 00       	call   f0104547 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010135d:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f010135f:	83 c4 10             	add    $0x10,%esp
f0101362:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101367:	0f 86 9a 00 00 00    	jbe    f0101407 <mem_init+0x13f>
	return (physaddr_t)kva - KERNBASE;
f010136d:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101373:	83 ca 05             	or     $0x5,%edx
f0101376:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages*sizeof(struct PageInfo));
f010137c:	c7 c7 e8 ef 18 f0    	mov    $0xf018efe8,%edi
f0101382:	8b 07                	mov    (%edi),%eax
f0101384:	c1 e0 03             	shl    $0x3,%eax
f0101387:	e8 91 f6 ff ff       	call   f0100a1d <boot_alloc>
f010138c:	c7 c6 f0 ef 18 f0    	mov    $0xf018eff0,%esi
f0101392:	89 06                	mov    %eax,(%esi)
	memset(pages,0,npages*sizeof(struct PageInfo));
f0101394:	83 ec 04             	sub    $0x4,%esp
f0101397:	8b 17                	mov    (%edi),%edx
f0101399:	c1 e2 03             	shl    $0x3,%edx
f010139c:	52                   	push   %edx
f010139d:	6a 00                	push   $0x0
f010139f:	50                   	push   %eax
f01013a0:	e8 a2 31 00 00       	call   f0104547 <memset>
	envs = (struct Env*)boot_alloc(NENV*sizeof(struct Env));
f01013a5:	b8 00 80 01 00       	mov    $0x18000,%eax
f01013aa:	e8 6e f6 ff ff       	call   f0100a1d <boot_alloc>
f01013af:	c7 c2 28 e3 18 f0    	mov    $0xf018e328,%edx
f01013b5:	89 02                	mov    %eax,(%edx)
	memset(envs,0,NENV*sizeof(struct Env));
f01013b7:	83 c4 0c             	add    $0xc,%esp
f01013ba:	68 00 80 01 00       	push   $0x18000
f01013bf:	6a 00                	push   $0x0
f01013c1:	50                   	push   %eax
f01013c2:	e8 80 31 00 00       	call   f0104547 <memset>
	page_init();
f01013c7:	e8 d6 fa ff ff       	call   f0100ea2 <page_init>
	check_page_free_list(1);
f01013cc:	b8 01 00 00 00       	mov    $0x1,%eax
f01013d1:	e8 52 f7 ff ff       	call   f0100b28 <check_page_free_list>
	if (!pages)
f01013d6:	83 c4 10             	add    $0x10,%esp
f01013d9:	83 3e 00             	cmpl   $0x0,(%esi)
f01013dc:	74 42                	je     f0101420 <mem_init+0x158>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013de:	8b 83 00 23 00 00    	mov    0x2300(%ebx),%eax
f01013e4:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f01013eb:	85 c0                	test   %eax,%eax
f01013ed:	74 4c                	je     f010143b <mem_init+0x173>
		++nfree;
f01013ef:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013f3:	8b 00                	mov    (%eax),%eax
f01013f5:	eb f4                	jmp    f01013eb <mem_init+0x123>
		totalmem = 1 * 1024 + extmem;
f01013f7:	8d 87 00 04 00 00    	lea    0x400(%edi),%eax
f01013fd:	85 ff                	test   %edi,%edi
f01013ff:	0f 44 c6             	cmove  %esi,%eax
f0101402:	e9 09 ff ff ff       	jmp    f0101310 <mem_init+0x48>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101407:	50                   	push   %eax
f0101408:	8d 83 e0 8f f7 ff    	lea    -0x87020(%ebx),%eax
f010140e:	50                   	push   %eax
f010140f:	68 a1 00 00 00       	push   $0xa1
f0101414:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010141a:	50                   	push   %eax
f010141b:	e8 95 ec ff ff       	call   f01000b5 <_panic>
		panic("'pages' is a null pointer!");
f0101420:	83 ec 04             	sub    $0x4,%esp
f0101423:	8d 83 d7 96 f7 ff    	lea    -0x86929(%ebx),%eax
f0101429:	50                   	push   %eax
f010142a:	68 e7 02 00 00       	push   $0x2e7
f010142f:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0101435:	50                   	push   %eax
f0101436:	e8 7a ec ff ff       	call   f01000b5 <_panic>
	assert((pp0 = page_alloc(0)));
f010143b:	83 ec 0c             	sub    $0xc,%esp
f010143e:	6a 00                	push   $0x0
f0101440:	e8 2a fb ff ff       	call   f0100f6f <page_alloc>
f0101445:	89 c6                	mov    %eax,%esi
f0101447:	83 c4 10             	add    $0x10,%esp
f010144a:	85 c0                	test   %eax,%eax
f010144c:	0f 84 31 02 00 00    	je     f0101683 <mem_init+0x3bb>
	assert((pp1 = page_alloc(0)));
f0101452:	83 ec 0c             	sub    $0xc,%esp
f0101455:	6a 00                	push   $0x0
f0101457:	e8 13 fb ff ff       	call   f0100f6f <page_alloc>
f010145c:	89 c7                	mov    %eax,%edi
f010145e:	83 c4 10             	add    $0x10,%esp
f0101461:	85 c0                	test   %eax,%eax
f0101463:	0f 84 39 02 00 00    	je     f01016a2 <mem_init+0x3da>
	assert((pp2 = page_alloc(0)));
f0101469:	83 ec 0c             	sub    $0xc,%esp
f010146c:	6a 00                	push   $0x0
f010146e:	e8 fc fa ff ff       	call   f0100f6f <page_alloc>
f0101473:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101476:	83 c4 10             	add    $0x10,%esp
f0101479:	85 c0                	test   %eax,%eax
f010147b:	0f 84 40 02 00 00    	je     f01016c1 <mem_init+0x3f9>
	assert(pp1 && pp1 != pp0);
f0101481:	39 fe                	cmp    %edi,%esi
f0101483:	0f 84 57 02 00 00    	je     f01016e0 <mem_init+0x418>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101489:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010148c:	39 c7                	cmp    %eax,%edi
f010148e:	0f 84 6b 02 00 00    	je     f01016ff <mem_init+0x437>
f0101494:	39 c6                	cmp    %eax,%esi
f0101496:	0f 84 63 02 00 00    	je     f01016ff <mem_init+0x437>
	return (pp - pages) << PGSHIFT;
f010149c:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f01014a2:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014a4:	c7 c0 e8 ef 18 f0    	mov    $0xf018efe8,%eax
f01014aa:	8b 10                	mov    (%eax),%edx
f01014ac:	c1 e2 0c             	shl    $0xc,%edx
f01014af:	89 f0                	mov    %esi,%eax
f01014b1:	29 c8                	sub    %ecx,%eax
f01014b3:	c1 f8 03             	sar    $0x3,%eax
f01014b6:	c1 e0 0c             	shl    $0xc,%eax
f01014b9:	39 d0                	cmp    %edx,%eax
f01014bb:	0f 83 5d 02 00 00    	jae    f010171e <mem_init+0x456>
f01014c1:	89 f8                	mov    %edi,%eax
f01014c3:	29 c8                	sub    %ecx,%eax
f01014c5:	c1 f8 03             	sar    $0x3,%eax
f01014c8:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f01014cb:	39 c2                	cmp    %eax,%edx
f01014cd:	0f 86 6a 02 00 00    	jbe    f010173d <mem_init+0x475>
f01014d3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014d6:	29 c8                	sub    %ecx,%eax
f01014d8:	c1 f8 03             	sar    $0x3,%eax
f01014db:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01014de:	39 c2                	cmp    %eax,%edx
f01014e0:	0f 86 76 02 00 00    	jbe    f010175c <mem_init+0x494>
	fl = page_free_list;
f01014e6:	8b 83 00 23 00 00    	mov    0x2300(%ebx),%eax
f01014ec:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f01014ef:	c7 83 00 23 00 00 00 	movl   $0x0,0x2300(%ebx)
f01014f6:	00 00 00 
	assert(!page_alloc(0));
f01014f9:	83 ec 0c             	sub    $0xc,%esp
f01014fc:	6a 00                	push   $0x0
f01014fe:	e8 6c fa ff ff       	call   f0100f6f <page_alloc>
f0101503:	83 c4 10             	add    $0x10,%esp
f0101506:	85 c0                	test   %eax,%eax
f0101508:	0f 85 6d 02 00 00    	jne    f010177b <mem_init+0x4b3>
	page_free(pp0);
f010150e:	83 ec 0c             	sub    $0xc,%esp
f0101511:	56                   	push   %esi
f0101512:	e8 e7 fa ff ff       	call   f0100ffe <page_free>
	page_free(pp1);
f0101517:	89 3c 24             	mov    %edi,(%esp)
f010151a:	e8 df fa ff ff       	call   f0100ffe <page_free>
	page_free(pp2);
f010151f:	83 c4 04             	add    $0x4,%esp
f0101522:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101525:	e8 d4 fa ff ff       	call   f0100ffe <page_free>
	assert((pp0 = page_alloc(0)));
f010152a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101531:	e8 39 fa ff ff       	call   f0100f6f <page_alloc>
f0101536:	89 c6                	mov    %eax,%esi
f0101538:	83 c4 10             	add    $0x10,%esp
f010153b:	85 c0                	test   %eax,%eax
f010153d:	0f 84 57 02 00 00    	je     f010179a <mem_init+0x4d2>
	assert((pp1 = page_alloc(0)));
f0101543:	83 ec 0c             	sub    $0xc,%esp
f0101546:	6a 00                	push   $0x0
f0101548:	e8 22 fa ff ff       	call   f0100f6f <page_alloc>
f010154d:	89 c7                	mov    %eax,%edi
f010154f:	83 c4 10             	add    $0x10,%esp
f0101552:	85 c0                	test   %eax,%eax
f0101554:	0f 84 5f 02 00 00    	je     f01017b9 <mem_init+0x4f1>
	assert((pp2 = page_alloc(0)));
f010155a:	83 ec 0c             	sub    $0xc,%esp
f010155d:	6a 00                	push   $0x0
f010155f:	e8 0b fa ff ff       	call   f0100f6f <page_alloc>
f0101564:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101567:	83 c4 10             	add    $0x10,%esp
f010156a:	85 c0                	test   %eax,%eax
f010156c:	0f 84 66 02 00 00    	je     f01017d8 <mem_init+0x510>
	assert(pp1 && pp1 != pp0);
f0101572:	39 fe                	cmp    %edi,%esi
f0101574:	0f 84 7d 02 00 00    	je     f01017f7 <mem_init+0x52f>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010157a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010157d:	39 c7                	cmp    %eax,%edi
f010157f:	0f 84 91 02 00 00    	je     f0101816 <mem_init+0x54e>
f0101585:	39 c6                	cmp    %eax,%esi
f0101587:	0f 84 89 02 00 00    	je     f0101816 <mem_init+0x54e>
	assert(!page_alloc(0));
f010158d:	83 ec 0c             	sub    $0xc,%esp
f0101590:	6a 00                	push   $0x0
f0101592:	e8 d8 f9 ff ff       	call   f0100f6f <page_alloc>
f0101597:	83 c4 10             	add    $0x10,%esp
f010159a:	85 c0                	test   %eax,%eax
f010159c:	0f 85 93 02 00 00    	jne    f0101835 <mem_init+0x56d>
f01015a2:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f01015a8:	89 f1                	mov    %esi,%ecx
f01015aa:	2b 08                	sub    (%eax),%ecx
f01015ac:	89 c8                	mov    %ecx,%eax
f01015ae:	c1 f8 03             	sar    $0x3,%eax
f01015b1:	89 c2                	mov    %eax,%edx
f01015b3:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01015b6:	25 ff ff 0f 00       	and    $0xfffff,%eax
f01015bb:	c7 c1 e8 ef 18 f0    	mov    $0xf018efe8,%ecx
f01015c1:	3b 01                	cmp    (%ecx),%eax
f01015c3:	0f 83 8b 02 00 00    	jae    f0101854 <mem_init+0x58c>
	memset(page2kva(pp0), 1, PGSIZE);
f01015c9:	83 ec 04             	sub    $0x4,%esp
f01015cc:	68 00 10 00 00       	push   $0x1000
f01015d1:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01015d3:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f01015d9:	52                   	push   %edx
f01015da:	e8 68 2f 00 00       	call   f0104547 <memset>
	page_free(pp0);
f01015df:	89 34 24             	mov    %esi,(%esp)
f01015e2:	e8 17 fa ff ff       	call   f0100ffe <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01015e7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01015ee:	e8 7c f9 ff ff       	call   f0100f6f <page_alloc>
f01015f3:	83 c4 10             	add    $0x10,%esp
f01015f6:	85 c0                	test   %eax,%eax
f01015f8:	0f 84 6c 02 00 00    	je     f010186a <mem_init+0x5a2>
	assert(pp && pp0 == pp);
f01015fe:	39 c6                	cmp    %eax,%esi
f0101600:	0f 85 83 02 00 00    	jne    f0101889 <mem_init+0x5c1>
	return (pp - pages) << PGSHIFT;
f0101606:	c7 c2 f0 ef 18 f0    	mov    $0xf018eff0,%edx
f010160c:	2b 02                	sub    (%edx),%eax
f010160e:	c1 f8 03             	sar    $0x3,%eax
f0101611:	89 c2                	mov    %eax,%edx
f0101613:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101616:	25 ff ff 0f 00       	and    $0xfffff,%eax
f010161b:	c7 c1 e8 ef 18 f0    	mov    $0xf018efe8,%ecx
f0101621:	3b 01                	cmp    (%ecx),%eax
f0101623:	0f 83 7f 02 00 00    	jae    f01018a8 <mem_init+0x5e0>
	return (void *)(pa + KERNBASE);
f0101629:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f010162f:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f0101635:	80 38 00             	cmpb   $0x0,(%eax)
f0101638:	0f 85 80 02 00 00    	jne    f01018be <mem_init+0x5f6>
f010163e:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f0101641:	39 d0                	cmp    %edx,%eax
f0101643:	75 f0                	jne    f0101635 <mem_init+0x36d>
	page_free_list = fl;
f0101645:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101648:	89 83 00 23 00 00    	mov    %eax,0x2300(%ebx)
	page_free(pp0);
f010164e:	83 ec 0c             	sub    $0xc,%esp
f0101651:	56                   	push   %esi
f0101652:	e8 a7 f9 ff ff       	call   f0100ffe <page_free>
	page_free(pp1);
f0101657:	89 3c 24             	mov    %edi,(%esp)
f010165a:	e8 9f f9 ff ff       	call   f0100ffe <page_free>
	page_free(pp2);
f010165f:	83 c4 04             	add    $0x4,%esp
f0101662:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101665:	e8 94 f9 ff ff       	call   f0100ffe <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010166a:	8b 83 00 23 00 00    	mov    0x2300(%ebx),%eax
f0101670:	83 c4 10             	add    $0x10,%esp
f0101673:	85 c0                	test   %eax,%eax
f0101675:	0f 84 62 02 00 00    	je     f01018dd <mem_init+0x615>
		--nfree;
f010167b:	83 6d d0 01          	subl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010167f:	8b 00                	mov    (%eax),%eax
f0101681:	eb f0                	jmp    f0101673 <mem_init+0x3ab>
	assert((pp0 = page_alloc(0)));
f0101683:	8d 83 f2 96 f7 ff    	lea    -0x8690e(%ebx),%eax
f0101689:	50                   	push   %eax
f010168a:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0101690:	50                   	push   %eax
f0101691:	68 ef 02 00 00       	push   $0x2ef
f0101696:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010169c:	50                   	push   %eax
f010169d:	e8 13 ea ff ff       	call   f01000b5 <_panic>
	assert((pp1 = page_alloc(0)));
f01016a2:	8d 83 08 97 f7 ff    	lea    -0x868f8(%ebx),%eax
f01016a8:	50                   	push   %eax
f01016a9:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01016af:	50                   	push   %eax
f01016b0:	68 f0 02 00 00       	push   $0x2f0
f01016b5:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01016bb:	50                   	push   %eax
f01016bc:	e8 f4 e9 ff ff       	call   f01000b5 <_panic>
	assert((pp2 = page_alloc(0)));
f01016c1:	8d 83 1e 97 f7 ff    	lea    -0x868e2(%ebx),%eax
f01016c7:	50                   	push   %eax
f01016c8:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01016ce:	50                   	push   %eax
f01016cf:	68 f1 02 00 00       	push   $0x2f1
f01016d4:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01016da:	50                   	push   %eax
f01016db:	e8 d5 e9 ff ff       	call   f01000b5 <_panic>
	assert(pp1 && pp1 != pp0);
f01016e0:	8d 83 34 97 f7 ff    	lea    -0x868cc(%ebx),%eax
f01016e6:	50                   	push   %eax
f01016e7:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01016ed:	50                   	push   %eax
f01016ee:	68 f4 02 00 00       	push   $0x2f4
f01016f3:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01016f9:	50                   	push   %eax
f01016fa:	e8 b6 e9 ff ff       	call   f01000b5 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016ff:	8d 83 04 90 f7 ff    	lea    -0x86ffc(%ebx),%eax
f0101705:	50                   	push   %eax
f0101706:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010170c:	50                   	push   %eax
f010170d:	68 f5 02 00 00       	push   $0x2f5
f0101712:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0101718:	50                   	push   %eax
f0101719:	e8 97 e9 ff ff       	call   f01000b5 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f010171e:	8d 83 46 97 f7 ff    	lea    -0x868ba(%ebx),%eax
f0101724:	50                   	push   %eax
f0101725:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010172b:	50                   	push   %eax
f010172c:	68 f6 02 00 00       	push   $0x2f6
f0101731:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0101737:	50                   	push   %eax
f0101738:	e8 78 e9 ff ff       	call   f01000b5 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010173d:	8d 83 63 97 f7 ff    	lea    -0x8689d(%ebx),%eax
f0101743:	50                   	push   %eax
f0101744:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010174a:	50                   	push   %eax
f010174b:	68 f7 02 00 00       	push   $0x2f7
f0101750:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0101756:	50                   	push   %eax
f0101757:	e8 59 e9 ff ff       	call   f01000b5 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010175c:	8d 83 80 97 f7 ff    	lea    -0x86880(%ebx),%eax
f0101762:	50                   	push   %eax
f0101763:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0101769:	50                   	push   %eax
f010176a:	68 f8 02 00 00       	push   $0x2f8
f010176f:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0101775:	50                   	push   %eax
f0101776:	e8 3a e9 ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f010177b:	8d 83 9d 97 f7 ff    	lea    -0x86863(%ebx),%eax
f0101781:	50                   	push   %eax
f0101782:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0101788:	50                   	push   %eax
f0101789:	68 ff 02 00 00       	push   $0x2ff
f010178e:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0101794:	50                   	push   %eax
f0101795:	e8 1b e9 ff ff       	call   f01000b5 <_panic>
	assert((pp0 = page_alloc(0)));
f010179a:	8d 83 f2 96 f7 ff    	lea    -0x8690e(%ebx),%eax
f01017a0:	50                   	push   %eax
f01017a1:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01017a7:	50                   	push   %eax
f01017a8:	68 06 03 00 00       	push   $0x306
f01017ad:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01017b3:	50                   	push   %eax
f01017b4:	e8 fc e8 ff ff       	call   f01000b5 <_panic>
	assert((pp1 = page_alloc(0)));
f01017b9:	8d 83 08 97 f7 ff    	lea    -0x868f8(%ebx),%eax
f01017bf:	50                   	push   %eax
f01017c0:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01017c6:	50                   	push   %eax
f01017c7:	68 07 03 00 00       	push   $0x307
f01017cc:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01017d2:	50                   	push   %eax
f01017d3:	e8 dd e8 ff ff       	call   f01000b5 <_panic>
	assert((pp2 = page_alloc(0)));
f01017d8:	8d 83 1e 97 f7 ff    	lea    -0x868e2(%ebx),%eax
f01017de:	50                   	push   %eax
f01017df:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01017e5:	50                   	push   %eax
f01017e6:	68 08 03 00 00       	push   $0x308
f01017eb:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01017f1:	50                   	push   %eax
f01017f2:	e8 be e8 ff ff       	call   f01000b5 <_panic>
	assert(pp1 && pp1 != pp0);
f01017f7:	8d 83 34 97 f7 ff    	lea    -0x868cc(%ebx),%eax
f01017fd:	50                   	push   %eax
f01017fe:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0101804:	50                   	push   %eax
f0101805:	68 0a 03 00 00       	push   $0x30a
f010180a:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0101810:	50                   	push   %eax
f0101811:	e8 9f e8 ff ff       	call   f01000b5 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101816:	8d 83 04 90 f7 ff    	lea    -0x86ffc(%ebx),%eax
f010181c:	50                   	push   %eax
f010181d:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0101823:	50                   	push   %eax
f0101824:	68 0b 03 00 00       	push   $0x30b
f0101829:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010182f:	50                   	push   %eax
f0101830:	e8 80 e8 ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f0101835:	8d 83 9d 97 f7 ff    	lea    -0x86863(%ebx),%eax
f010183b:	50                   	push   %eax
f010183c:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0101842:	50                   	push   %eax
f0101843:	68 0c 03 00 00       	push   $0x30c
f0101848:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010184e:	50                   	push   %eax
f010184f:	e8 61 e8 ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101854:	52                   	push   %edx
f0101855:	8d 83 30 8e f7 ff    	lea    -0x871d0(%ebx),%eax
f010185b:	50                   	push   %eax
f010185c:	6a 56                	push   $0x56
f010185e:	8d 83 2d 96 f7 ff    	lea    -0x869d3(%ebx),%eax
f0101864:	50                   	push   %eax
f0101865:	e8 4b e8 ff ff       	call   f01000b5 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010186a:	8d 83 ac 97 f7 ff    	lea    -0x86854(%ebx),%eax
f0101870:	50                   	push   %eax
f0101871:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0101877:	50                   	push   %eax
f0101878:	68 11 03 00 00       	push   $0x311
f010187d:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0101883:	50                   	push   %eax
f0101884:	e8 2c e8 ff ff       	call   f01000b5 <_panic>
	assert(pp && pp0 == pp);
f0101889:	8d 83 ca 97 f7 ff    	lea    -0x86836(%ebx),%eax
f010188f:	50                   	push   %eax
f0101890:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0101896:	50                   	push   %eax
f0101897:	68 12 03 00 00       	push   $0x312
f010189c:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01018a2:	50                   	push   %eax
f01018a3:	e8 0d e8 ff ff       	call   f01000b5 <_panic>
f01018a8:	52                   	push   %edx
f01018a9:	8d 83 30 8e f7 ff    	lea    -0x871d0(%ebx),%eax
f01018af:	50                   	push   %eax
f01018b0:	6a 56                	push   $0x56
f01018b2:	8d 83 2d 96 f7 ff    	lea    -0x869d3(%ebx),%eax
f01018b8:	50                   	push   %eax
f01018b9:	e8 f7 e7 ff ff       	call   f01000b5 <_panic>
		assert(c[i] == 0);
f01018be:	8d 83 da 97 f7 ff    	lea    -0x86826(%ebx),%eax
f01018c4:	50                   	push   %eax
f01018c5:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01018cb:	50                   	push   %eax
f01018cc:	68 15 03 00 00       	push   $0x315
f01018d1:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01018d7:	50                   	push   %eax
f01018d8:	e8 d8 e7 ff ff       	call   f01000b5 <_panic>
	assert(nfree == 0);
f01018dd:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01018e1:	0f 85 7f 08 00 00    	jne    f0102166 <mem_init+0xe9e>
	cprintf("check_page_alloc() succeeded!\n");
f01018e7:	83 ec 0c             	sub    $0xc,%esp
f01018ea:	8d 83 24 90 f7 ff    	lea    -0x86fdc(%ebx),%eax
f01018f0:	50                   	push   %eax
f01018f1:	e8 e1 1b 00 00       	call   f01034d7 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01018f6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018fd:	e8 6d f6 ff ff       	call   f0100f6f <page_alloc>
f0101902:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101905:	83 c4 10             	add    $0x10,%esp
f0101908:	85 c0                	test   %eax,%eax
f010190a:	0f 84 75 08 00 00    	je     f0102185 <mem_init+0xebd>
	assert((pp1 = page_alloc(0)));
f0101910:	83 ec 0c             	sub    $0xc,%esp
f0101913:	6a 00                	push   $0x0
f0101915:	e8 55 f6 ff ff       	call   f0100f6f <page_alloc>
f010191a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010191d:	83 c4 10             	add    $0x10,%esp
f0101920:	85 c0                	test   %eax,%eax
f0101922:	0f 84 7c 08 00 00    	je     f01021a4 <mem_init+0xedc>
	assert((pp2 = page_alloc(0)));
f0101928:	83 ec 0c             	sub    $0xc,%esp
f010192b:	6a 00                	push   $0x0
f010192d:	e8 3d f6 ff ff       	call   f0100f6f <page_alloc>
f0101932:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101935:	83 c4 10             	add    $0x10,%esp
f0101938:	85 c0                	test   %eax,%eax
f010193a:	0f 84 83 08 00 00    	je     f01021c3 <mem_init+0xefb>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101940:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101943:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0101946:	0f 84 96 08 00 00    	je     f01021e2 <mem_init+0xf1a>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010194c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010194f:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101952:	0f 84 a9 08 00 00    	je     f0102201 <mem_init+0xf39>
f0101958:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f010195b:	0f 84 a0 08 00 00    	je     f0102201 <mem_init+0xf39>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101961:	8b 83 00 23 00 00    	mov    0x2300(%ebx),%eax
f0101967:	89 45 c8             	mov    %eax,-0x38(%ebp)
	page_free_list = 0;
f010196a:	c7 83 00 23 00 00 00 	movl   $0x0,0x2300(%ebx)
f0101971:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101974:	83 ec 0c             	sub    $0xc,%esp
f0101977:	6a 00                	push   $0x0
f0101979:	e8 f1 f5 ff ff       	call   f0100f6f <page_alloc>
f010197e:	83 c4 10             	add    $0x10,%esp
f0101981:	85 c0                	test   %eax,%eax
f0101983:	0f 85 97 08 00 00    	jne    f0102220 <mem_init+0xf58>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101989:	83 ec 04             	sub    $0x4,%esp
f010198c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010198f:	50                   	push   %eax
f0101990:	6a 00                	push   $0x0
f0101992:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0101998:	ff 30                	pushl  (%eax)
f010199a:	e8 d6 f7 ff ff       	call   f0101175 <page_lookup>
f010199f:	83 c4 10             	add    $0x10,%esp
f01019a2:	85 c0                	test   %eax,%eax
f01019a4:	0f 85 95 08 00 00    	jne    f010223f <mem_init+0xf77>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019aa:	6a 02                	push   $0x2
f01019ac:	6a 00                	push   $0x0
f01019ae:	ff 75 d4             	pushl  -0x2c(%ebp)
f01019b1:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f01019b7:	ff 30                	pushl  (%eax)
f01019b9:	e8 7c f8 ff ff       	call   f010123a <page_insert>
f01019be:	83 c4 10             	add    $0x10,%esp
f01019c1:	85 c0                	test   %eax,%eax
f01019c3:	0f 89 95 08 00 00    	jns    f010225e <mem_init+0xf96>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019c9:	83 ec 0c             	sub    $0xc,%esp
f01019cc:	ff 75 cc             	pushl  -0x34(%ebp)
f01019cf:	e8 2a f6 ff ff       	call   f0100ffe <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019d4:	6a 02                	push   $0x2
f01019d6:	6a 00                	push   $0x0
f01019d8:	ff 75 d4             	pushl  -0x2c(%ebp)
f01019db:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f01019e1:	ff 30                	pushl  (%eax)
f01019e3:	e8 52 f8 ff ff       	call   f010123a <page_insert>
f01019e8:	83 c4 20             	add    $0x20,%esp
f01019eb:	85 c0                	test   %eax,%eax
f01019ed:	0f 85 8a 08 00 00    	jne    f010227d <mem_init+0xfb5>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01019f3:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f01019f9:	8b 30                	mov    (%eax),%esi
	return (pp - pages) << PGSHIFT;
f01019fb:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f0101a01:	8b 38                	mov    (%eax),%edi
f0101a03:	8b 16                	mov    (%esi),%edx
f0101a05:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a0b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101a0e:	29 f8                	sub    %edi,%eax
f0101a10:	c1 f8 03             	sar    $0x3,%eax
f0101a13:	c1 e0 0c             	shl    $0xc,%eax
f0101a16:	39 c2                	cmp    %eax,%edx
f0101a18:	0f 85 7e 08 00 00    	jne    f010229c <mem_init+0xfd4>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a1e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a23:	89 f0                	mov    %esi,%eax
f0101a25:	e8 82 f0 ff ff       	call   f0100aac <check_va2pa>
f0101a2a:	89 c2                	mov    %eax,%edx
f0101a2c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a2f:	29 f8                	sub    %edi,%eax
f0101a31:	c1 f8 03             	sar    $0x3,%eax
f0101a34:	c1 e0 0c             	shl    $0xc,%eax
f0101a37:	39 c2                	cmp    %eax,%edx
f0101a39:	0f 85 7c 08 00 00    	jne    f01022bb <mem_init+0xff3>
	assert(pp1->pp_ref == 1);
f0101a3f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a42:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a47:	0f 85 8d 08 00 00    	jne    f01022da <mem_init+0x1012>
	assert(pp0->pp_ref == 1);
f0101a4d:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101a50:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a55:	0f 85 9e 08 00 00    	jne    f01022f9 <mem_init+0x1031>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a5b:	6a 02                	push   $0x2
f0101a5d:	68 00 10 00 00       	push   $0x1000
f0101a62:	ff 75 d0             	pushl  -0x30(%ebp)
f0101a65:	56                   	push   %esi
f0101a66:	e8 cf f7 ff ff       	call   f010123a <page_insert>
f0101a6b:	83 c4 10             	add    $0x10,%esp
f0101a6e:	85 c0                	test   %eax,%eax
f0101a70:	0f 85 a2 08 00 00    	jne    f0102318 <mem_init+0x1050>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a76:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a7b:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0101a81:	8b 00                	mov    (%eax),%eax
f0101a83:	e8 24 f0 ff ff       	call   f0100aac <check_va2pa>
f0101a88:	89 c2                	mov    %eax,%edx
f0101a8a:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f0101a90:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101a93:	2b 08                	sub    (%eax),%ecx
f0101a95:	89 c8                	mov    %ecx,%eax
f0101a97:	c1 f8 03             	sar    $0x3,%eax
f0101a9a:	c1 e0 0c             	shl    $0xc,%eax
f0101a9d:	39 c2                	cmp    %eax,%edx
f0101a9f:	0f 85 92 08 00 00    	jne    f0102337 <mem_init+0x106f>
	assert(pp2->pp_ref == 1);
f0101aa5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101aa8:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101aad:	0f 85 a3 08 00 00    	jne    f0102356 <mem_init+0x108e>

	// should be no free memory
	assert(!page_alloc(0));
f0101ab3:	83 ec 0c             	sub    $0xc,%esp
f0101ab6:	6a 00                	push   $0x0
f0101ab8:	e8 b2 f4 ff ff       	call   f0100f6f <page_alloc>
f0101abd:	83 c4 10             	add    $0x10,%esp
f0101ac0:	85 c0                	test   %eax,%eax
f0101ac2:	0f 85 ad 08 00 00    	jne    f0102375 <mem_init+0x10ad>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ac8:	6a 02                	push   $0x2
f0101aca:	68 00 10 00 00       	push   $0x1000
f0101acf:	ff 75 d0             	pushl  -0x30(%ebp)
f0101ad2:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0101ad8:	ff 30                	pushl  (%eax)
f0101ada:	e8 5b f7 ff ff       	call   f010123a <page_insert>
f0101adf:	83 c4 10             	add    $0x10,%esp
f0101ae2:	85 c0                	test   %eax,%eax
f0101ae4:	0f 85 aa 08 00 00    	jne    f0102394 <mem_init+0x10cc>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101aea:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101aef:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0101af5:	8b 00                	mov    (%eax),%eax
f0101af7:	e8 b0 ef ff ff       	call   f0100aac <check_va2pa>
f0101afc:	89 c2                	mov    %eax,%edx
f0101afe:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f0101b04:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101b07:	2b 08                	sub    (%eax),%ecx
f0101b09:	89 c8                	mov    %ecx,%eax
f0101b0b:	c1 f8 03             	sar    $0x3,%eax
f0101b0e:	c1 e0 0c             	shl    $0xc,%eax
f0101b11:	39 c2                	cmp    %eax,%edx
f0101b13:	0f 85 9a 08 00 00    	jne    f01023b3 <mem_init+0x10eb>
	assert(pp2->pp_ref == 1);
f0101b19:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b1c:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b21:	0f 85 ab 08 00 00    	jne    f01023d2 <mem_init+0x110a>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b27:	83 ec 0c             	sub    $0xc,%esp
f0101b2a:	6a 00                	push   $0x0
f0101b2c:	e8 3e f4 ff ff       	call   f0100f6f <page_alloc>
f0101b31:	83 c4 10             	add    $0x10,%esp
f0101b34:	85 c0                	test   %eax,%eax
f0101b36:	0f 85 b5 08 00 00    	jne    f01023f1 <mem_init+0x1129>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101b3c:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0101b42:	8b 08                	mov    (%eax),%ecx
f0101b44:	8b 01                	mov    (%ecx),%eax
f0101b46:	89 c2                	mov    %eax,%edx
f0101b48:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101b4e:	c1 e8 0c             	shr    $0xc,%eax
f0101b51:	c7 c6 e8 ef 18 f0    	mov    $0xf018efe8,%esi
f0101b57:	3b 06                	cmp    (%esi),%eax
f0101b59:	0f 83 b1 08 00 00    	jae    f0102410 <mem_init+0x1148>
	return (void *)(pa + KERNBASE);
f0101b5f:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101b65:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101b68:	83 ec 04             	sub    $0x4,%esp
f0101b6b:	6a 00                	push   $0x0
f0101b6d:	68 00 10 00 00       	push   $0x1000
f0101b72:	51                   	push   %ecx
f0101b73:	e8 06 f5 ff ff       	call   f010107e <pgdir_walk>
f0101b78:	89 c2                	mov    %eax,%edx
f0101b7a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101b7d:	83 c0 04             	add    $0x4,%eax
f0101b80:	83 c4 10             	add    $0x10,%esp
f0101b83:	39 d0                	cmp    %edx,%eax
f0101b85:	0f 85 9e 08 00 00    	jne    f0102429 <mem_init+0x1161>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101b8b:	6a 06                	push   $0x6
f0101b8d:	68 00 10 00 00       	push   $0x1000
f0101b92:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b95:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0101b9b:	ff 30                	pushl  (%eax)
f0101b9d:	e8 98 f6 ff ff       	call   f010123a <page_insert>
f0101ba2:	83 c4 10             	add    $0x10,%esp
f0101ba5:	85 c0                	test   %eax,%eax
f0101ba7:	0f 85 9b 08 00 00    	jne    f0102448 <mem_init+0x1180>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bad:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0101bb3:	8b 30                	mov    (%eax),%esi
f0101bb5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bba:	89 f0                	mov    %esi,%eax
f0101bbc:	e8 eb ee ff ff       	call   f0100aac <check_va2pa>
f0101bc1:	89 c2                	mov    %eax,%edx
	return (pp - pages) << PGSHIFT;
f0101bc3:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f0101bc9:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101bcc:	2b 08                	sub    (%eax),%ecx
f0101bce:	89 c8                	mov    %ecx,%eax
f0101bd0:	c1 f8 03             	sar    $0x3,%eax
f0101bd3:	c1 e0 0c             	shl    $0xc,%eax
f0101bd6:	39 c2                	cmp    %eax,%edx
f0101bd8:	0f 85 89 08 00 00    	jne    f0102467 <mem_init+0x119f>
	assert(pp2->pp_ref == 1);
f0101bde:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101be1:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101be6:	0f 85 9a 08 00 00    	jne    f0102486 <mem_init+0x11be>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101bec:	83 ec 04             	sub    $0x4,%esp
f0101bef:	6a 00                	push   $0x0
f0101bf1:	68 00 10 00 00       	push   $0x1000
f0101bf6:	56                   	push   %esi
f0101bf7:	e8 82 f4 ff ff       	call   f010107e <pgdir_walk>
f0101bfc:	83 c4 10             	add    $0x10,%esp
f0101bff:	f6 00 04             	testb  $0x4,(%eax)
f0101c02:	0f 84 9d 08 00 00    	je     f01024a5 <mem_init+0x11dd>
	assert(kern_pgdir[0] & PTE_U);
f0101c08:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0101c0e:	8b 00                	mov    (%eax),%eax
f0101c10:	f6 00 04             	testb  $0x4,(%eax)
f0101c13:	0f 84 ab 08 00 00    	je     f01024c4 <mem_init+0x11fc>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c19:	6a 02                	push   $0x2
f0101c1b:	68 00 10 00 00       	push   $0x1000
f0101c20:	ff 75 d0             	pushl  -0x30(%ebp)
f0101c23:	50                   	push   %eax
f0101c24:	e8 11 f6 ff ff       	call   f010123a <page_insert>
f0101c29:	83 c4 10             	add    $0x10,%esp
f0101c2c:	85 c0                	test   %eax,%eax
f0101c2e:	0f 85 af 08 00 00    	jne    f01024e3 <mem_init+0x121b>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101c34:	83 ec 04             	sub    $0x4,%esp
f0101c37:	6a 00                	push   $0x0
f0101c39:	68 00 10 00 00       	push   $0x1000
f0101c3e:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0101c44:	ff 30                	pushl  (%eax)
f0101c46:	e8 33 f4 ff ff       	call   f010107e <pgdir_walk>
f0101c4b:	83 c4 10             	add    $0x10,%esp
f0101c4e:	f6 00 02             	testb  $0x2,(%eax)
f0101c51:	0f 84 ab 08 00 00    	je     f0102502 <mem_init+0x123a>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c57:	83 ec 04             	sub    $0x4,%esp
f0101c5a:	6a 00                	push   $0x0
f0101c5c:	68 00 10 00 00       	push   $0x1000
f0101c61:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0101c67:	ff 30                	pushl  (%eax)
f0101c69:	e8 10 f4 ff ff       	call   f010107e <pgdir_walk>
f0101c6e:	83 c4 10             	add    $0x10,%esp
f0101c71:	f6 00 04             	testb  $0x4,(%eax)
f0101c74:	0f 85 a7 08 00 00    	jne    f0102521 <mem_init+0x1259>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101c7a:	6a 02                	push   $0x2
f0101c7c:	68 00 00 40 00       	push   $0x400000
f0101c81:	ff 75 cc             	pushl  -0x34(%ebp)
f0101c84:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0101c8a:	ff 30                	pushl  (%eax)
f0101c8c:	e8 a9 f5 ff ff       	call   f010123a <page_insert>
f0101c91:	83 c4 10             	add    $0x10,%esp
f0101c94:	85 c0                	test   %eax,%eax
f0101c96:	0f 89 a4 08 00 00    	jns    f0102540 <mem_init+0x1278>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c9c:	6a 02                	push   $0x2
f0101c9e:	68 00 10 00 00       	push   $0x1000
f0101ca3:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101ca6:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0101cac:	ff 30                	pushl  (%eax)
f0101cae:	e8 87 f5 ff ff       	call   f010123a <page_insert>
f0101cb3:	83 c4 10             	add    $0x10,%esp
f0101cb6:	85 c0                	test   %eax,%eax
f0101cb8:	0f 85 a1 08 00 00    	jne    f010255f <mem_init+0x1297>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101cbe:	83 ec 04             	sub    $0x4,%esp
f0101cc1:	6a 00                	push   $0x0
f0101cc3:	68 00 10 00 00       	push   $0x1000
f0101cc8:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0101cce:	ff 30                	pushl  (%eax)
f0101cd0:	e8 a9 f3 ff ff       	call   f010107e <pgdir_walk>
f0101cd5:	83 c4 10             	add    $0x10,%esp
f0101cd8:	f6 00 04             	testb  $0x4,(%eax)
f0101cdb:	0f 85 9d 08 00 00    	jne    f010257e <mem_init+0x12b6>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ce1:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0101ce7:	8b 38                	mov    (%eax),%edi
f0101ce9:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cee:	89 f8                	mov    %edi,%eax
f0101cf0:	e8 b7 ed ff ff       	call   f0100aac <check_va2pa>
f0101cf5:	c7 c2 f0 ef 18 f0    	mov    $0xf018eff0,%edx
f0101cfb:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101cfe:	2b 32                	sub    (%edx),%esi
f0101d00:	c1 fe 03             	sar    $0x3,%esi
f0101d03:	c1 e6 0c             	shl    $0xc,%esi
f0101d06:	39 f0                	cmp    %esi,%eax
f0101d08:	0f 85 8f 08 00 00    	jne    f010259d <mem_init+0x12d5>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d0e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d13:	89 f8                	mov    %edi,%eax
f0101d15:	e8 92 ed ff ff       	call   f0100aac <check_va2pa>
f0101d1a:	39 c6                	cmp    %eax,%esi
f0101d1c:	0f 85 9a 08 00 00    	jne    f01025bc <mem_init+0x12f4>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101d22:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d25:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f0101d2a:	0f 85 ab 08 00 00    	jne    f01025db <mem_init+0x1313>
	assert(pp2->pp_ref == 0);
f0101d30:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101d33:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101d38:	0f 85 bc 08 00 00    	jne    f01025fa <mem_init+0x1332>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101d3e:	83 ec 0c             	sub    $0xc,%esp
f0101d41:	6a 00                	push   $0x0
f0101d43:	e8 27 f2 ff ff       	call   f0100f6f <page_alloc>
f0101d48:	83 c4 10             	add    $0x10,%esp
f0101d4b:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101d4e:	0f 85 c5 08 00 00    	jne    f0102619 <mem_init+0x1351>
f0101d54:	85 c0                	test   %eax,%eax
f0101d56:	0f 84 bd 08 00 00    	je     f0102619 <mem_init+0x1351>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d5c:	83 ec 08             	sub    $0x8,%esp
f0101d5f:	6a 00                	push   $0x0
f0101d61:	c7 c6 ec ef 18 f0    	mov    $0xf018efec,%esi
f0101d67:	ff 36                	pushl  (%esi)
f0101d69:	e8 86 f4 ff ff       	call   f01011f4 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d6e:	8b 36                	mov    (%esi),%esi
f0101d70:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d75:	89 f0                	mov    %esi,%eax
f0101d77:	e8 30 ed ff ff       	call   f0100aac <check_va2pa>
f0101d7c:	83 c4 10             	add    $0x10,%esp
f0101d7f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d82:	0f 85 b0 08 00 00    	jne    f0102638 <mem_init+0x1370>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d88:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d8d:	89 f0                	mov    %esi,%eax
f0101d8f:	e8 18 ed ff ff       	call   f0100aac <check_va2pa>
f0101d94:	89 c2                	mov    %eax,%edx
f0101d96:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f0101d9c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101d9f:	2b 08                	sub    (%eax),%ecx
f0101da1:	89 c8                	mov    %ecx,%eax
f0101da3:	c1 f8 03             	sar    $0x3,%eax
f0101da6:	c1 e0 0c             	shl    $0xc,%eax
f0101da9:	39 c2                	cmp    %eax,%edx
f0101dab:	0f 85 a6 08 00 00    	jne    f0102657 <mem_init+0x138f>
	assert(pp1->pp_ref == 1);
f0101db1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101db4:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101db9:	0f 85 b7 08 00 00    	jne    f0102676 <mem_init+0x13ae>
	assert(pp2->pp_ref == 0);
f0101dbf:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101dc2:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101dc7:	0f 85 c8 08 00 00    	jne    f0102695 <mem_init+0x13cd>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101dcd:	6a 00                	push   $0x0
f0101dcf:	68 00 10 00 00       	push   $0x1000
f0101dd4:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101dd7:	56                   	push   %esi
f0101dd8:	e8 5d f4 ff ff       	call   f010123a <page_insert>
f0101ddd:	83 c4 10             	add    $0x10,%esp
f0101de0:	85 c0                	test   %eax,%eax
f0101de2:	0f 85 cc 08 00 00    	jne    f01026b4 <mem_init+0x13ec>
	assert(pp1->pp_ref);
f0101de8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101deb:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101df0:	0f 84 dd 08 00 00    	je     f01026d3 <mem_init+0x140b>
	assert(pp1->pp_link == NULL);
f0101df6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101df9:	83 38 00             	cmpl   $0x0,(%eax)
f0101dfc:	0f 85 f0 08 00 00    	jne    f01026f2 <mem_init+0x142a>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e02:	83 ec 08             	sub    $0x8,%esp
f0101e05:	68 00 10 00 00       	push   $0x1000
f0101e0a:	c7 c6 ec ef 18 f0    	mov    $0xf018efec,%esi
f0101e10:	ff 36                	pushl  (%esi)
f0101e12:	e8 dd f3 ff ff       	call   f01011f4 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e17:	8b 36                	mov    (%esi),%esi
f0101e19:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e1e:	89 f0                	mov    %esi,%eax
f0101e20:	e8 87 ec ff ff       	call   f0100aac <check_va2pa>
f0101e25:	83 c4 10             	add    $0x10,%esp
f0101e28:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e2b:	0f 85 e0 08 00 00    	jne    f0102711 <mem_init+0x1449>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e31:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e36:	89 f0                	mov    %esi,%eax
f0101e38:	e8 6f ec ff ff       	call   f0100aac <check_va2pa>
f0101e3d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e40:	0f 85 ea 08 00 00    	jne    f0102730 <mem_init+0x1468>
	assert(pp1->pp_ref == 0);
f0101e46:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e49:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e4e:	0f 85 fb 08 00 00    	jne    f010274f <mem_init+0x1487>
	assert(pp2->pp_ref == 0);
f0101e54:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101e57:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e5c:	0f 85 0c 09 00 00    	jne    f010276e <mem_init+0x14a6>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e62:	83 ec 0c             	sub    $0xc,%esp
f0101e65:	6a 00                	push   $0x0
f0101e67:	e8 03 f1 ff ff       	call   f0100f6f <page_alloc>
f0101e6c:	83 c4 10             	add    $0x10,%esp
f0101e6f:	85 c0                	test   %eax,%eax
f0101e71:	0f 84 16 09 00 00    	je     f010278d <mem_init+0x14c5>
f0101e77:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101e7a:	0f 85 0d 09 00 00    	jne    f010278d <mem_init+0x14c5>

	// should be no free memory
	assert(!page_alloc(0));
f0101e80:	83 ec 0c             	sub    $0xc,%esp
f0101e83:	6a 00                	push   $0x0
f0101e85:	e8 e5 f0 ff ff       	call   f0100f6f <page_alloc>
f0101e8a:	83 c4 10             	add    $0x10,%esp
f0101e8d:	85 c0                	test   %eax,%eax
f0101e8f:	0f 85 17 09 00 00    	jne    f01027ac <mem_init+0x14e4>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e95:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0101e9b:	8b 08                	mov    (%eax),%ecx
f0101e9d:	8b 11                	mov    (%ecx),%edx
f0101e9f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ea5:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f0101eab:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0101eae:	2b 38                	sub    (%eax),%edi
f0101eb0:	89 f8                	mov    %edi,%eax
f0101eb2:	c1 f8 03             	sar    $0x3,%eax
f0101eb5:	c1 e0 0c             	shl    $0xc,%eax
f0101eb8:	39 c2                	cmp    %eax,%edx
f0101eba:	0f 85 0b 09 00 00    	jne    f01027cb <mem_init+0x1503>
	kern_pgdir[0] = 0;
f0101ec0:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101ec6:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101ec9:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ece:	0f 85 16 09 00 00    	jne    f01027ea <mem_init+0x1522>
	pp0->pp_ref = 0;
f0101ed4:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101ed7:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101edd:	83 ec 0c             	sub    $0xc,%esp
f0101ee0:	50                   	push   %eax
f0101ee1:	e8 18 f1 ff ff       	call   f0100ffe <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101ee6:	83 c4 0c             	add    $0xc,%esp
f0101ee9:	6a 01                	push   $0x1
f0101eeb:	68 00 10 40 00       	push   $0x401000
f0101ef0:	c7 c6 ec ef 18 f0    	mov    $0xf018efec,%esi
f0101ef6:	ff 36                	pushl  (%esi)
f0101ef8:	e8 81 f1 ff ff       	call   f010107e <pgdir_walk>
f0101efd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f00:	8b 3e                	mov    (%esi),%edi
f0101f02:	8b 57 04             	mov    0x4(%edi),%edx
f0101f05:	89 d1                	mov    %edx,%ecx
f0101f07:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	if (PGNUM(pa) >= npages)
f0101f0d:	c7 c6 e8 ef 18 f0    	mov    $0xf018efe8,%esi
f0101f13:	8b 36                	mov    (%esi),%esi
f0101f15:	c1 ea 0c             	shr    $0xc,%edx
f0101f18:	83 c4 10             	add    $0x10,%esp
f0101f1b:	39 f2                	cmp    %esi,%edx
f0101f1d:	0f 83 e6 08 00 00    	jae    f0102809 <mem_init+0x1541>
	assert(ptep == ptep1 + PTX(va));
f0101f23:	81 e9 fc ff ff 0f    	sub    $0xffffffc,%ecx
f0101f29:	39 c8                	cmp    %ecx,%eax
f0101f2b:	0f 85 f1 08 00 00    	jne    f0102822 <mem_init+0x155a>
	kern_pgdir[PDX(va)] = 0;
f0101f31:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	pp0->pp_ref = 0;
f0101f38:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101f3b:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
	return (pp - pages) << PGSHIFT;
f0101f41:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f0101f47:	2b 08                	sub    (%eax),%ecx
f0101f49:	89 c8                	mov    %ecx,%eax
f0101f4b:	c1 f8 03             	sar    $0x3,%eax
f0101f4e:	89 c2                	mov    %eax,%edx
f0101f50:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101f53:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101f58:	39 c6                	cmp    %eax,%esi
f0101f5a:	0f 86 e1 08 00 00    	jbe    f0102841 <mem_init+0x1579>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101f60:	83 ec 04             	sub    $0x4,%esp
f0101f63:	68 00 10 00 00       	push   $0x1000
f0101f68:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0101f6d:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101f73:	52                   	push   %edx
f0101f74:	e8 ce 25 00 00       	call   f0104547 <memset>
	page_free(pp0);
f0101f79:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0101f7c:	89 3c 24             	mov    %edi,(%esp)
f0101f7f:	e8 7a f0 ff ff       	call   f0100ffe <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101f84:	83 c4 0c             	add    $0xc,%esp
f0101f87:	6a 01                	push   $0x1
f0101f89:	6a 00                	push   $0x0
f0101f8b:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0101f91:	ff 30                	pushl  (%eax)
f0101f93:	e8 e6 f0 ff ff       	call   f010107e <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0101f98:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f0101f9e:	2b 38                	sub    (%eax),%edi
f0101fa0:	89 f8                	mov    %edi,%eax
f0101fa2:	c1 f8 03             	sar    $0x3,%eax
f0101fa5:	89 c2                	mov    %eax,%edx
f0101fa7:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101faa:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101faf:	83 c4 10             	add    $0x10,%esp
f0101fb2:	c7 c1 e8 ef 18 f0    	mov    $0xf018efe8,%ecx
f0101fb8:	3b 01                	cmp    (%ecx),%eax
f0101fba:	0f 83 97 08 00 00    	jae    f0102857 <mem_init+0x158f>
	return (void *)(pa + KERNBASE);
f0101fc0:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101fc6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101fc9:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101fcf:	8b 38                	mov    (%eax),%edi
f0101fd1:	83 e7 01             	and    $0x1,%edi
f0101fd4:	0f 85 93 08 00 00    	jne    f010286d <mem_init+0x15a5>
f0101fda:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0101fdd:	39 d0                	cmp    %edx,%eax
f0101fdf:	75 ee                	jne    f0101fcf <mem_init+0xd07>
	kern_pgdir[0] = 0;
f0101fe1:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0101fe7:	8b 00                	mov    (%eax),%eax
f0101fe9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101fef:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101ff2:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0101ff8:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101ffb:	89 8b 00 23 00 00    	mov    %ecx,0x2300(%ebx)

	// free the pages we took
	page_free(pp0);
f0102001:	83 ec 0c             	sub    $0xc,%esp
f0102004:	50                   	push   %eax
f0102005:	e8 f4 ef ff ff       	call   f0100ffe <page_free>
	page_free(pp1);
f010200a:	83 c4 04             	add    $0x4,%esp
f010200d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102010:	e8 e9 ef ff ff       	call   f0100ffe <page_free>
	page_free(pp2);
f0102015:	83 c4 04             	add    $0x4,%esp
f0102018:	ff 75 d0             	pushl  -0x30(%ebp)
f010201b:	e8 de ef ff ff       	call   f0100ffe <page_free>

	cprintf("check_page() succeeded!\n");
f0102020:	8d 83 bb 98 f7 ff    	lea    -0x86745(%ebx),%eax
f0102026:	89 04 24             	mov    %eax,(%esp)
f0102029:	e8 a9 14 00 00       	call   f01034d7 <cprintf>
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U);
f010202e:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f0102034:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102036:	83 c4 10             	add    $0x10,%esp
f0102039:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010203e:	0f 86 48 08 00 00    	jbe    f010288c <mem_init+0x15c4>
f0102044:	83 ec 08             	sub    $0x8,%esp
f0102047:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102049:	05 00 00 00 10       	add    $0x10000000,%eax
f010204e:	50                   	push   %eax
f010204f:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102054:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102059:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f010205f:	8b 00                	mov    (%eax),%eax
f0102061:	e8 c3 f0 ff ff       	call   f0101129 <boot_map_region>
	boot_map_region(kern_pgdir,UENVS,PTSIZE,PADDR(envs),PTE_U);	
f0102066:	c7 c0 28 e3 18 f0    	mov    $0xf018e328,%eax
f010206c:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010206e:	83 c4 10             	add    $0x10,%esp
f0102071:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102076:	0f 86 29 08 00 00    	jbe    f01028a5 <mem_init+0x15dd>
f010207c:	83 ec 08             	sub    $0x8,%esp
f010207f:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102081:	05 00 00 00 10       	add    $0x10000000,%eax
f0102086:	50                   	push   %eax
f0102087:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010208c:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102091:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0102097:	8b 00                	mov    (%eax),%eax
f0102099:	e8 8b f0 ff ff       	call   f0101129 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f010209e:	c7 c0 00 20 11 f0    	mov    $0xf0112000,%eax
f01020a4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01020a7:	83 c4 10             	add    $0x10,%esp
f01020aa:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020af:	0f 86 09 08 00 00    	jbe    f01028be <mem_init+0x15f6>
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f01020b5:	c7 c6 ec ef 18 f0    	mov    $0xf018efec,%esi
f01020bb:	83 ec 08             	sub    $0x8,%esp
f01020be:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f01020c0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01020c3:	05 00 00 00 10       	add    $0x10000000,%eax
f01020c8:	50                   	push   %eax
f01020c9:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01020ce:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01020d3:	8b 06                	mov    (%esi),%eax
f01020d5:	e8 4f f0 ff ff       	call   f0101129 <boot_map_region>
	boot_map_region(kern_pgdir,KERNBASE,0xFFFFFFFF-KERNBASE,0,PTE_W);
f01020da:	83 c4 08             	add    $0x8,%esp
f01020dd:	6a 02                	push   $0x2
f01020df:	6a 00                	push   $0x0
f01020e1:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01020e6:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01020eb:	8b 06                	mov    (%esi),%eax
f01020ed:	e8 37 f0 ff ff       	call   f0101129 <boot_map_region>
	pgdir = kern_pgdir;
f01020f2:	8b 06                	mov    (%esi),%eax
f01020f4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01020f7:	c7 c0 e8 ef 18 f0    	mov    $0xf018efe8,%eax
f01020fd:	8b 00                	mov    (%eax),%eax
f01020ff:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0102102:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102109:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010210e:	89 45 cc             	mov    %eax,-0x34(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102111:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f0102117:	8b 00                	mov    (%eax),%eax
f0102119:	89 45 bc             	mov    %eax,-0x44(%ebp)
	if ((uint32_t)kva < KERNBASE)
f010211c:	89 45 c8             	mov    %eax,-0x38(%ebp)
	return (physaddr_t)kva - KERNBASE;
f010211f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102124:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f0102127:	83 c4 10             	add    $0x10,%esp
f010212a:	89 fe                	mov    %edi,%esi
f010212c:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f010212f:	0f 86 dc 07 00 00    	jbe    f0102911 <mem_init+0x1649>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102135:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f010213b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010213e:	e8 69 e9 ff ff       	call   f0100aac <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102143:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f010214a:	0f 86 87 07 00 00    	jbe    f01028d7 <mem_init+0x160f>
f0102150:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102153:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102156:	39 d0                	cmp    %edx,%eax
f0102158:	0f 85 94 07 00 00    	jne    f01028f2 <mem_init+0x162a>
	for (i = 0; i < n; i += PGSIZE)
f010215e:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102164:	eb c6                	jmp    f010212c <mem_init+0xe64>
	assert(nfree == 0);
f0102166:	8d 83 e4 97 f7 ff    	lea    -0x8681c(%ebx),%eax
f010216c:	50                   	push   %eax
f010216d:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102173:	50                   	push   %eax
f0102174:	68 22 03 00 00       	push   $0x322
f0102179:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010217f:	50                   	push   %eax
f0102180:	e8 30 df ff ff       	call   f01000b5 <_panic>
	assert((pp0 = page_alloc(0)));
f0102185:	8d 83 f2 96 f7 ff    	lea    -0x8690e(%ebx),%eax
f010218b:	50                   	push   %eax
f010218c:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102192:	50                   	push   %eax
f0102193:	68 80 03 00 00       	push   $0x380
f0102198:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010219e:	50                   	push   %eax
f010219f:	e8 11 df ff ff       	call   f01000b5 <_panic>
	assert((pp1 = page_alloc(0)));
f01021a4:	8d 83 08 97 f7 ff    	lea    -0x868f8(%ebx),%eax
f01021aa:	50                   	push   %eax
f01021ab:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01021b1:	50                   	push   %eax
f01021b2:	68 81 03 00 00       	push   $0x381
f01021b7:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01021bd:	50                   	push   %eax
f01021be:	e8 f2 de ff ff       	call   f01000b5 <_panic>
	assert((pp2 = page_alloc(0)));
f01021c3:	8d 83 1e 97 f7 ff    	lea    -0x868e2(%ebx),%eax
f01021c9:	50                   	push   %eax
f01021ca:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01021d0:	50                   	push   %eax
f01021d1:	68 82 03 00 00       	push   $0x382
f01021d6:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01021dc:	50                   	push   %eax
f01021dd:	e8 d3 de ff ff       	call   f01000b5 <_panic>
	assert(pp1 && pp1 != pp0);
f01021e2:	8d 83 34 97 f7 ff    	lea    -0x868cc(%ebx),%eax
f01021e8:	50                   	push   %eax
f01021e9:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01021ef:	50                   	push   %eax
f01021f0:	68 85 03 00 00       	push   $0x385
f01021f5:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01021fb:	50                   	push   %eax
f01021fc:	e8 b4 de ff ff       	call   f01000b5 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0102201:	8d 83 04 90 f7 ff    	lea    -0x86ffc(%ebx),%eax
f0102207:	50                   	push   %eax
f0102208:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010220e:	50                   	push   %eax
f010220f:	68 86 03 00 00       	push   $0x386
f0102214:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010221a:	50                   	push   %eax
f010221b:	e8 95 de ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f0102220:	8d 83 9d 97 f7 ff    	lea    -0x86863(%ebx),%eax
f0102226:	50                   	push   %eax
f0102227:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010222d:	50                   	push   %eax
f010222e:	68 8d 03 00 00       	push   $0x38d
f0102233:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102239:	50                   	push   %eax
f010223a:	e8 76 de ff ff       	call   f01000b5 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010223f:	8d 83 44 90 f7 ff    	lea    -0x86fbc(%ebx),%eax
f0102245:	50                   	push   %eax
f0102246:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010224c:	50                   	push   %eax
f010224d:	68 90 03 00 00       	push   $0x390
f0102252:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102258:	50                   	push   %eax
f0102259:	e8 57 de ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010225e:	8d 83 7c 90 f7 ff    	lea    -0x86f84(%ebx),%eax
f0102264:	50                   	push   %eax
f0102265:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010226b:	50                   	push   %eax
f010226c:	68 93 03 00 00       	push   $0x393
f0102271:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102277:	50                   	push   %eax
f0102278:	e8 38 de ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010227d:	8d 83 ac 90 f7 ff    	lea    -0x86f54(%ebx),%eax
f0102283:	50                   	push   %eax
f0102284:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010228a:	50                   	push   %eax
f010228b:	68 97 03 00 00       	push   $0x397
f0102290:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102296:	50                   	push   %eax
f0102297:	e8 19 de ff ff       	call   f01000b5 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010229c:	8d 83 dc 90 f7 ff    	lea    -0x86f24(%ebx),%eax
f01022a2:	50                   	push   %eax
f01022a3:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01022a9:	50                   	push   %eax
f01022aa:	68 98 03 00 00       	push   $0x398
f01022af:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01022b5:	50                   	push   %eax
f01022b6:	e8 fa dd ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01022bb:	8d 83 04 91 f7 ff    	lea    -0x86efc(%ebx),%eax
f01022c1:	50                   	push   %eax
f01022c2:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01022c8:	50                   	push   %eax
f01022c9:	68 99 03 00 00       	push   $0x399
f01022ce:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01022d4:	50                   	push   %eax
f01022d5:	e8 db dd ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 1);
f01022da:	8d 83 ef 97 f7 ff    	lea    -0x86811(%ebx),%eax
f01022e0:	50                   	push   %eax
f01022e1:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01022e7:	50                   	push   %eax
f01022e8:	68 9a 03 00 00       	push   $0x39a
f01022ed:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01022f3:	50                   	push   %eax
f01022f4:	e8 bc dd ff ff       	call   f01000b5 <_panic>
	assert(pp0->pp_ref == 1);
f01022f9:	8d 83 00 98 f7 ff    	lea    -0x86800(%ebx),%eax
f01022ff:	50                   	push   %eax
f0102300:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102306:	50                   	push   %eax
f0102307:	68 9b 03 00 00       	push   $0x39b
f010230c:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102312:	50                   	push   %eax
f0102313:	e8 9d dd ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102318:	8d 83 34 91 f7 ff    	lea    -0x86ecc(%ebx),%eax
f010231e:	50                   	push   %eax
f010231f:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102325:	50                   	push   %eax
f0102326:	68 9e 03 00 00       	push   $0x39e
f010232b:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102331:	50                   	push   %eax
f0102332:	e8 7e dd ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102337:	8d 83 70 91 f7 ff    	lea    -0x86e90(%ebx),%eax
f010233d:	50                   	push   %eax
f010233e:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102344:	50                   	push   %eax
f0102345:	68 9f 03 00 00       	push   $0x39f
f010234a:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102350:	50                   	push   %eax
f0102351:	e8 5f dd ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 1);
f0102356:	8d 83 11 98 f7 ff    	lea    -0x867ef(%ebx),%eax
f010235c:	50                   	push   %eax
f010235d:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102363:	50                   	push   %eax
f0102364:	68 a0 03 00 00       	push   $0x3a0
f0102369:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010236f:	50                   	push   %eax
f0102370:	e8 40 dd ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f0102375:	8d 83 9d 97 f7 ff    	lea    -0x86863(%ebx),%eax
f010237b:	50                   	push   %eax
f010237c:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102382:	50                   	push   %eax
f0102383:	68 a3 03 00 00       	push   $0x3a3
f0102388:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010238e:	50                   	push   %eax
f010238f:	e8 21 dd ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102394:	8d 83 34 91 f7 ff    	lea    -0x86ecc(%ebx),%eax
f010239a:	50                   	push   %eax
f010239b:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01023a1:	50                   	push   %eax
f01023a2:	68 a6 03 00 00       	push   $0x3a6
f01023a7:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01023ad:	50                   	push   %eax
f01023ae:	e8 02 dd ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01023b3:	8d 83 70 91 f7 ff    	lea    -0x86e90(%ebx),%eax
f01023b9:	50                   	push   %eax
f01023ba:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01023c0:	50                   	push   %eax
f01023c1:	68 a7 03 00 00       	push   $0x3a7
f01023c6:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01023cc:	50                   	push   %eax
f01023cd:	e8 e3 dc ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 1);
f01023d2:	8d 83 11 98 f7 ff    	lea    -0x867ef(%ebx),%eax
f01023d8:	50                   	push   %eax
f01023d9:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01023df:	50                   	push   %eax
f01023e0:	68 a8 03 00 00       	push   $0x3a8
f01023e5:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01023eb:	50                   	push   %eax
f01023ec:	e8 c4 dc ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f01023f1:	8d 83 9d 97 f7 ff    	lea    -0x86863(%ebx),%eax
f01023f7:	50                   	push   %eax
f01023f8:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01023fe:	50                   	push   %eax
f01023ff:	68 ac 03 00 00       	push   $0x3ac
f0102404:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010240a:	50                   	push   %eax
f010240b:	e8 a5 dc ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102410:	52                   	push   %edx
f0102411:	8d 83 30 8e f7 ff    	lea    -0x871d0(%ebx),%eax
f0102417:	50                   	push   %eax
f0102418:	68 af 03 00 00       	push   $0x3af
f010241d:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102423:	50                   	push   %eax
f0102424:	e8 8c dc ff ff       	call   f01000b5 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102429:	8d 83 a0 91 f7 ff    	lea    -0x86e60(%ebx),%eax
f010242f:	50                   	push   %eax
f0102430:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102436:	50                   	push   %eax
f0102437:	68 b0 03 00 00       	push   $0x3b0
f010243c:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102442:	50                   	push   %eax
f0102443:	e8 6d dc ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102448:	8d 83 e0 91 f7 ff    	lea    -0x86e20(%ebx),%eax
f010244e:	50                   	push   %eax
f010244f:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102455:	50                   	push   %eax
f0102456:	68 b3 03 00 00       	push   $0x3b3
f010245b:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102461:	50                   	push   %eax
f0102462:	e8 4e dc ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102467:	8d 83 70 91 f7 ff    	lea    -0x86e90(%ebx),%eax
f010246d:	50                   	push   %eax
f010246e:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102474:	50                   	push   %eax
f0102475:	68 b4 03 00 00       	push   $0x3b4
f010247a:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102480:	50                   	push   %eax
f0102481:	e8 2f dc ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 1);
f0102486:	8d 83 11 98 f7 ff    	lea    -0x867ef(%ebx),%eax
f010248c:	50                   	push   %eax
f010248d:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102493:	50                   	push   %eax
f0102494:	68 b5 03 00 00       	push   $0x3b5
f0102499:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010249f:	50                   	push   %eax
f01024a0:	e8 10 dc ff ff       	call   f01000b5 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01024a5:	8d 83 20 92 f7 ff    	lea    -0x86de0(%ebx),%eax
f01024ab:	50                   	push   %eax
f01024ac:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01024b2:	50                   	push   %eax
f01024b3:	68 b6 03 00 00       	push   $0x3b6
f01024b8:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01024be:	50                   	push   %eax
f01024bf:	e8 f1 db ff ff       	call   f01000b5 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01024c4:	8d 83 22 98 f7 ff    	lea    -0x867de(%ebx),%eax
f01024ca:	50                   	push   %eax
f01024cb:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01024d1:	50                   	push   %eax
f01024d2:	68 b7 03 00 00       	push   $0x3b7
f01024d7:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01024dd:	50                   	push   %eax
f01024de:	e8 d2 db ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01024e3:	8d 83 34 91 f7 ff    	lea    -0x86ecc(%ebx),%eax
f01024e9:	50                   	push   %eax
f01024ea:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01024f0:	50                   	push   %eax
f01024f1:	68 ba 03 00 00       	push   $0x3ba
f01024f6:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01024fc:	50                   	push   %eax
f01024fd:	e8 b3 db ff ff       	call   f01000b5 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102502:	8d 83 54 92 f7 ff    	lea    -0x86dac(%ebx),%eax
f0102508:	50                   	push   %eax
f0102509:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010250f:	50                   	push   %eax
f0102510:	68 bb 03 00 00       	push   $0x3bb
f0102515:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010251b:	50                   	push   %eax
f010251c:	e8 94 db ff ff       	call   f01000b5 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102521:	8d 83 88 92 f7 ff    	lea    -0x86d78(%ebx),%eax
f0102527:	50                   	push   %eax
f0102528:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010252e:	50                   	push   %eax
f010252f:	68 bc 03 00 00       	push   $0x3bc
f0102534:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010253a:	50                   	push   %eax
f010253b:	e8 75 db ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102540:	8d 83 c0 92 f7 ff    	lea    -0x86d40(%ebx),%eax
f0102546:	50                   	push   %eax
f0102547:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010254d:	50                   	push   %eax
f010254e:	68 bf 03 00 00       	push   $0x3bf
f0102553:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102559:	50                   	push   %eax
f010255a:	e8 56 db ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010255f:	8d 83 f8 92 f7 ff    	lea    -0x86d08(%ebx),%eax
f0102565:	50                   	push   %eax
f0102566:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010256c:	50                   	push   %eax
f010256d:	68 c2 03 00 00       	push   $0x3c2
f0102572:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102578:	50                   	push   %eax
f0102579:	e8 37 db ff ff       	call   f01000b5 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010257e:	8d 83 88 92 f7 ff    	lea    -0x86d78(%ebx),%eax
f0102584:	50                   	push   %eax
f0102585:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010258b:	50                   	push   %eax
f010258c:	68 c3 03 00 00       	push   $0x3c3
f0102591:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102597:	50                   	push   %eax
f0102598:	e8 18 db ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010259d:	8d 83 34 93 f7 ff    	lea    -0x86ccc(%ebx),%eax
f01025a3:	50                   	push   %eax
f01025a4:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01025aa:	50                   	push   %eax
f01025ab:	68 c6 03 00 00       	push   $0x3c6
f01025b0:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01025b6:	50                   	push   %eax
f01025b7:	e8 f9 da ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01025bc:	8d 83 60 93 f7 ff    	lea    -0x86ca0(%ebx),%eax
f01025c2:	50                   	push   %eax
f01025c3:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01025c9:	50                   	push   %eax
f01025ca:	68 c7 03 00 00       	push   $0x3c7
f01025cf:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01025d5:	50                   	push   %eax
f01025d6:	e8 da da ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 2);
f01025db:	8d 83 38 98 f7 ff    	lea    -0x867c8(%ebx),%eax
f01025e1:	50                   	push   %eax
f01025e2:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01025e8:	50                   	push   %eax
f01025e9:	68 c9 03 00 00       	push   $0x3c9
f01025ee:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01025f4:	50                   	push   %eax
f01025f5:	e8 bb da ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 0);
f01025fa:	8d 83 49 98 f7 ff    	lea    -0x867b7(%ebx),%eax
f0102600:	50                   	push   %eax
f0102601:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102607:	50                   	push   %eax
f0102608:	68 ca 03 00 00       	push   $0x3ca
f010260d:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102613:	50                   	push   %eax
f0102614:	e8 9c da ff ff       	call   f01000b5 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102619:	8d 83 90 93 f7 ff    	lea    -0x86c70(%ebx),%eax
f010261f:	50                   	push   %eax
f0102620:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102626:	50                   	push   %eax
f0102627:	68 cd 03 00 00       	push   $0x3cd
f010262c:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102632:	50                   	push   %eax
f0102633:	e8 7d da ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102638:	8d 83 b4 93 f7 ff    	lea    -0x86c4c(%ebx),%eax
f010263e:	50                   	push   %eax
f010263f:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102645:	50                   	push   %eax
f0102646:	68 d1 03 00 00       	push   $0x3d1
f010264b:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102651:	50                   	push   %eax
f0102652:	e8 5e da ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102657:	8d 83 60 93 f7 ff    	lea    -0x86ca0(%ebx),%eax
f010265d:	50                   	push   %eax
f010265e:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102664:	50                   	push   %eax
f0102665:	68 d2 03 00 00       	push   $0x3d2
f010266a:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102670:	50                   	push   %eax
f0102671:	e8 3f da ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 1);
f0102676:	8d 83 ef 97 f7 ff    	lea    -0x86811(%ebx),%eax
f010267c:	50                   	push   %eax
f010267d:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102683:	50                   	push   %eax
f0102684:	68 d3 03 00 00       	push   $0x3d3
f0102689:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010268f:	50                   	push   %eax
f0102690:	e8 20 da ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 0);
f0102695:	8d 83 49 98 f7 ff    	lea    -0x867b7(%ebx),%eax
f010269b:	50                   	push   %eax
f010269c:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01026a2:	50                   	push   %eax
f01026a3:	68 d4 03 00 00       	push   $0x3d4
f01026a8:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01026ae:	50                   	push   %eax
f01026af:	e8 01 da ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01026b4:	8d 83 d8 93 f7 ff    	lea    -0x86c28(%ebx),%eax
f01026ba:	50                   	push   %eax
f01026bb:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01026c1:	50                   	push   %eax
f01026c2:	68 d7 03 00 00       	push   $0x3d7
f01026c7:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01026cd:	50                   	push   %eax
f01026ce:	e8 e2 d9 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref);
f01026d3:	8d 83 5a 98 f7 ff    	lea    -0x867a6(%ebx),%eax
f01026d9:	50                   	push   %eax
f01026da:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01026e0:	50                   	push   %eax
f01026e1:	68 d8 03 00 00       	push   $0x3d8
f01026e6:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01026ec:	50                   	push   %eax
f01026ed:	e8 c3 d9 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_link == NULL);
f01026f2:	8d 83 66 98 f7 ff    	lea    -0x8679a(%ebx),%eax
f01026f8:	50                   	push   %eax
f01026f9:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01026ff:	50                   	push   %eax
f0102700:	68 d9 03 00 00       	push   $0x3d9
f0102705:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010270b:	50                   	push   %eax
f010270c:	e8 a4 d9 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102711:	8d 83 b4 93 f7 ff    	lea    -0x86c4c(%ebx),%eax
f0102717:	50                   	push   %eax
f0102718:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010271e:	50                   	push   %eax
f010271f:	68 dd 03 00 00       	push   $0x3dd
f0102724:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010272a:	50                   	push   %eax
f010272b:	e8 85 d9 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102730:	8d 83 10 94 f7 ff    	lea    -0x86bf0(%ebx),%eax
f0102736:	50                   	push   %eax
f0102737:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010273d:	50                   	push   %eax
f010273e:	68 de 03 00 00       	push   $0x3de
f0102743:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102749:	50                   	push   %eax
f010274a:	e8 66 d9 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 0);
f010274f:	8d 83 7b 98 f7 ff    	lea    -0x86785(%ebx),%eax
f0102755:	50                   	push   %eax
f0102756:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010275c:	50                   	push   %eax
f010275d:	68 df 03 00 00       	push   $0x3df
f0102762:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102768:	50                   	push   %eax
f0102769:	e8 47 d9 ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 0);
f010276e:	8d 83 49 98 f7 ff    	lea    -0x867b7(%ebx),%eax
f0102774:	50                   	push   %eax
f0102775:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010277b:	50                   	push   %eax
f010277c:	68 e0 03 00 00       	push   $0x3e0
f0102781:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102787:	50                   	push   %eax
f0102788:	e8 28 d9 ff ff       	call   f01000b5 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f010278d:	8d 83 38 94 f7 ff    	lea    -0x86bc8(%ebx),%eax
f0102793:	50                   	push   %eax
f0102794:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010279a:	50                   	push   %eax
f010279b:	68 e3 03 00 00       	push   $0x3e3
f01027a0:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01027a6:	50                   	push   %eax
f01027a7:	e8 09 d9 ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f01027ac:	8d 83 9d 97 f7 ff    	lea    -0x86863(%ebx),%eax
f01027b2:	50                   	push   %eax
f01027b3:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01027b9:	50                   	push   %eax
f01027ba:	68 e6 03 00 00       	push   $0x3e6
f01027bf:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01027c5:	50                   	push   %eax
f01027c6:	e8 ea d8 ff ff       	call   f01000b5 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01027cb:	8d 83 dc 90 f7 ff    	lea    -0x86f24(%ebx),%eax
f01027d1:	50                   	push   %eax
f01027d2:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01027d8:	50                   	push   %eax
f01027d9:	68 e9 03 00 00       	push   $0x3e9
f01027de:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01027e4:	50                   	push   %eax
f01027e5:	e8 cb d8 ff ff       	call   f01000b5 <_panic>
	assert(pp0->pp_ref == 1);
f01027ea:	8d 83 00 98 f7 ff    	lea    -0x86800(%ebx),%eax
f01027f0:	50                   	push   %eax
f01027f1:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01027f7:	50                   	push   %eax
f01027f8:	68 eb 03 00 00       	push   $0x3eb
f01027fd:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102803:	50                   	push   %eax
f0102804:	e8 ac d8 ff ff       	call   f01000b5 <_panic>
f0102809:	51                   	push   %ecx
f010280a:	8d 83 30 8e f7 ff    	lea    -0x871d0(%ebx),%eax
f0102810:	50                   	push   %eax
f0102811:	68 f2 03 00 00       	push   $0x3f2
f0102816:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010281c:	50                   	push   %eax
f010281d:	e8 93 d8 ff ff       	call   f01000b5 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102822:	8d 83 8c 98 f7 ff    	lea    -0x86774(%ebx),%eax
f0102828:	50                   	push   %eax
f0102829:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010282f:	50                   	push   %eax
f0102830:	68 f3 03 00 00       	push   $0x3f3
f0102835:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010283b:	50                   	push   %eax
f010283c:	e8 74 d8 ff ff       	call   f01000b5 <_panic>
f0102841:	52                   	push   %edx
f0102842:	8d 83 30 8e f7 ff    	lea    -0x871d0(%ebx),%eax
f0102848:	50                   	push   %eax
f0102849:	6a 56                	push   $0x56
f010284b:	8d 83 2d 96 f7 ff    	lea    -0x869d3(%ebx),%eax
f0102851:	50                   	push   %eax
f0102852:	e8 5e d8 ff ff       	call   f01000b5 <_panic>
f0102857:	52                   	push   %edx
f0102858:	8d 83 30 8e f7 ff    	lea    -0x871d0(%ebx),%eax
f010285e:	50                   	push   %eax
f010285f:	6a 56                	push   $0x56
f0102861:	8d 83 2d 96 f7 ff    	lea    -0x869d3(%ebx),%eax
f0102867:	50                   	push   %eax
f0102868:	e8 48 d8 ff ff       	call   f01000b5 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f010286d:	8d 83 a4 98 f7 ff    	lea    -0x8675c(%ebx),%eax
f0102873:	50                   	push   %eax
f0102874:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f010287a:	50                   	push   %eax
f010287b:	68 fd 03 00 00       	push   $0x3fd
f0102880:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102886:	50                   	push   %eax
f0102887:	e8 29 d8 ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010288c:	50                   	push   %eax
f010288d:	8d 83 e0 8f f7 ff    	lea    -0x87020(%ebx),%eax
f0102893:	50                   	push   %eax
f0102894:	68 c8 00 00 00       	push   $0xc8
f0102899:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010289f:	50                   	push   %eax
f01028a0:	e8 10 d8 ff ff       	call   f01000b5 <_panic>
f01028a5:	50                   	push   %eax
f01028a6:	8d 83 e0 8f f7 ff    	lea    -0x87020(%ebx),%eax
f01028ac:	50                   	push   %eax
f01028ad:	68 d0 00 00 00       	push   $0xd0
f01028b2:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01028b8:	50                   	push   %eax
f01028b9:	e8 f7 d7 ff ff       	call   f01000b5 <_panic>
f01028be:	50                   	push   %eax
f01028bf:	8d 83 e0 8f f7 ff    	lea    -0x87020(%ebx),%eax
f01028c5:	50                   	push   %eax
f01028c6:	68 dc 00 00 00       	push   $0xdc
f01028cb:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01028d1:	50                   	push   %eax
f01028d2:	e8 de d7 ff ff       	call   f01000b5 <_panic>
f01028d7:	ff 75 bc             	pushl  -0x44(%ebp)
f01028da:	8d 83 e0 8f f7 ff    	lea    -0x87020(%ebx),%eax
f01028e0:	50                   	push   %eax
f01028e1:	68 3a 03 00 00       	push   $0x33a
f01028e6:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01028ec:	50                   	push   %eax
f01028ed:	e8 c3 d7 ff ff       	call   f01000b5 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01028f2:	8d 83 5c 94 f7 ff    	lea    -0x86ba4(%ebx),%eax
f01028f8:	50                   	push   %eax
f01028f9:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01028ff:	50                   	push   %eax
f0102900:	68 3a 03 00 00       	push   $0x33a
f0102905:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f010290b:	50                   	push   %eax
f010290c:	e8 a4 d7 ff ff       	call   f01000b5 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102911:	c7 c0 28 e3 18 f0    	mov    $0xf018e328,%eax
f0102917:	8b 00                	mov    (%eax),%eax
f0102919:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	if ((uint32_t)kva < KERNBASE)
f010291c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010291f:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f0102924:	05 00 00 40 21       	add    $0x21400000,%eax
f0102929:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010292c:	89 f2                	mov    %esi,%edx
f010292e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102931:	e8 76 e1 ff ff       	call   f0100aac <check_va2pa>
f0102936:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f010293d:	76 42                	jbe    f0102981 <mem_init+0x16b9>
f010293f:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102942:	8d 14 31             	lea    (%ecx,%esi,1),%edx
f0102945:	39 d0                	cmp    %edx,%eax
f0102947:	75 53                	jne    f010299c <mem_init+0x16d4>
f0102949:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
f010294f:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102955:	75 d5                	jne    f010292c <mem_init+0x1664>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102957:	8b 45 c0             	mov    -0x40(%ebp),%eax
f010295a:	c1 e0 0c             	shl    $0xc,%eax
f010295d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102960:	89 fe                	mov    %edi,%esi
f0102962:	3b 75 cc             	cmp    -0x34(%ebp),%esi
f0102965:	73 73                	jae    f01029da <mem_init+0x1712>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102967:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f010296d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102970:	e8 37 e1 ff ff       	call   f0100aac <check_va2pa>
f0102975:	39 c6                	cmp    %eax,%esi
f0102977:	75 42                	jne    f01029bb <mem_init+0x16f3>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102979:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010297f:	eb e1                	jmp    f0102962 <mem_init+0x169a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102981:	ff 75 c4             	pushl  -0x3c(%ebp)
f0102984:	8d 83 e0 8f f7 ff    	lea    -0x87020(%ebx),%eax
f010298a:	50                   	push   %eax
f010298b:	68 3f 03 00 00       	push   $0x33f
f0102990:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102996:	50                   	push   %eax
f0102997:	e8 19 d7 ff ff       	call   f01000b5 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010299c:	8d 83 90 94 f7 ff    	lea    -0x86b70(%ebx),%eax
f01029a2:	50                   	push   %eax
f01029a3:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01029a9:	50                   	push   %eax
f01029aa:	68 3f 03 00 00       	push   $0x33f
f01029af:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01029b5:	50                   	push   %eax
f01029b6:	e8 fa d6 ff ff       	call   f01000b5 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01029bb:	8d 83 c4 94 f7 ff    	lea    -0x86b3c(%ebx),%eax
f01029c1:	50                   	push   %eax
f01029c2:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01029c8:	50                   	push   %eax
f01029c9:	68 43 03 00 00       	push   $0x343
f01029ce:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f01029d4:	50                   	push   %eax
f01029d5:	e8 db d6 ff ff       	call   f01000b5 <_panic>
f01029da:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01029df:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01029e2:	05 00 80 00 20       	add    $0x20008000,%eax
f01029e7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01029ea:	89 f2                	mov    %esi,%edx
f01029ec:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029ef:	e8 b8 e0 ff ff       	call   f0100aac <check_va2pa>
f01029f4:	89 c2                	mov    %eax,%edx
f01029f6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01029f9:	01 f0                	add    %esi,%eax
f01029fb:	39 c2                	cmp    %eax,%edx
f01029fd:	75 25                	jne    f0102a24 <mem_init+0x175c>
f01029ff:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102a05:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102a0b:	75 dd                	jne    f01029ea <mem_init+0x1722>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102a0d:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102a12:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a15:	e8 92 e0 ff ff       	call   f0100aac <check_va2pa>
f0102a1a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a1d:	75 24                	jne    f0102a43 <mem_init+0x177b>
f0102a1f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a22:	eb 6b                	jmp    f0102a8f <mem_init+0x17c7>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102a24:	8d 83 ec 94 f7 ff    	lea    -0x86b14(%ebx),%eax
f0102a2a:	50                   	push   %eax
f0102a2b:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102a31:	50                   	push   %eax
f0102a32:	68 47 03 00 00       	push   $0x347
f0102a37:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102a3d:	50                   	push   %eax
f0102a3e:	e8 72 d6 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102a43:	8d 83 34 95 f7 ff    	lea    -0x86acc(%ebx),%eax
f0102a49:	50                   	push   %eax
f0102a4a:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102a50:	50                   	push   %eax
f0102a51:	68 48 03 00 00       	push   $0x348
f0102a56:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102a5c:	50                   	push   %eax
f0102a5d:	e8 53 d6 ff ff       	call   f01000b5 <_panic>
		switch (i) {
f0102a62:	81 ff bf 03 00 00    	cmp    $0x3bf,%edi
f0102a68:	75 25                	jne    f0102a8f <mem_init+0x17c7>
			assert(pgdir[i] & PTE_P);
f0102a6a:	f6 04 b8 01          	testb  $0x1,(%eax,%edi,4)
f0102a6e:	74 4c                	je     f0102abc <mem_init+0x17f4>
	for (i = 0; i < NPDENTRIES; i++) {
f0102a70:	83 c7 01             	add    $0x1,%edi
f0102a73:	81 ff ff 03 00 00    	cmp    $0x3ff,%edi
f0102a79:	0f 87 a7 00 00 00    	ja     f0102b26 <mem_init+0x185e>
		switch (i) {
f0102a7f:	81 ff bd 03 00 00    	cmp    $0x3bd,%edi
f0102a85:	77 db                	ja     f0102a62 <mem_init+0x179a>
f0102a87:	81 ff ba 03 00 00    	cmp    $0x3ba,%edi
f0102a8d:	77 db                	ja     f0102a6a <mem_init+0x17a2>
			if (i >= PDX(KERNBASE)) {
f0102a8f:	81 ff bf 03 00 00    	cmp    $0x3bf,%edi
f0102a95:	77 44                	ja     f0102adb <mem_init+0x1813>
				assert(pgdir[i] == 0);
f0102a97:	83 3c b8 00          	cmpl   $0x0,(%eax,%edi,4)
f0102a9b:	74 d3                	je     f0102a70 <mem_init+0x17a8>
f0102a9d:	8d 83 f6 98 f7 ff    	lea    -0x8670a(%ebx),%eax
f0102aa3:	50                   	push   %eax
f0102aa4:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102aaa:	50                   	push   %eax
f0102aab:	68 58 03 00 00       	push   $0x358
f0102ab0:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102ab6:	50                   	push   %eax
f0102ab7:	e8 f9 d5 ff ff       	call   f01000b5 <_panic>
			assert(pgdir[i] & PTE_P);
f0102abc:	8d 83 d4 98 f7 ff    	lea    -0x8672c(%ebx),%eax
f0102ac2:	50                   	push   %eax
f0102ac3:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102ac9:	50                   	push   %eax
f0102aca:	68 51 03 00 00       	push   $0x351
f0102acf:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102ad5:	50                   	push   %eax
f0102ad6:	e8 da d5 ff ff       	call   f01000b5 <_panic>
				assert(pgdir[i] & PTE_P);
f0102adb:	8b 14 b8             	mov    (%eax,%edi,4),%edx
f0102ade:	f6 c2 01             	test   $0x1,%dl
f0102ae1:	74 24                	je     f0102b07 <mem_init+0x183f>
				assert(pgdir[i] & PTE_W);
f0102ae3:	f6 c2 02             	test   $0x2,%dl
f0102ae6:	75 88                	jne    f0102a70 <mem_init+0x17a8>
f0102ae8:	8d 83 e5 98 f7 ff    	lea    -0x8671b(%ebx),%eax
f0102aee:	50                   	push   %eax
f0102aef:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102af5:	50                   	push   %eax
f0102af6:	68 56 03 00 00       	push   $0x356
f0102afb:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102b01:	50                   	push   %eax
f0102b02:	e8 ae d5 ff ff       	call   f01000b5 <_panic>
				assert(pgdir[i] & PTE_P);
f0102b07:	8d 83 d4 98 f7 ff    	lea    -0x8672c(%ebx),%eax
f0102b0d:	50                   	push   %eax
f0102b0e:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102b14:	50                   	push   %eax
f0102b15:	68 55 03 00 00       	push   $0x355
f0102b1a:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102b20:	50                   	push   %eax
f0102b21:	e8 8f d5 ff ff       	call   f01000b5 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102b26:	83 ec 0c             	sub    $0xc,%esp
f0102b29:	8d 83 64 95 f7 ff    	lea    -0x86a9c(%ebx),%eax
f0102b2f:	50                   	push   %eax
f0102b30:	e8 a2 09 00 00       	call   f01034d7 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102b35:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0102b3b:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102b3d:	83 c4 10             	add    $0x10,%esp
f0102b40:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b45:	0f 86 30 02 00 00    	jbe    f0102d7b <mem_init+0x1ab3>
	return (physaddr_t)kva - KERNBASE;
f0102b4b:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102b50:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102b53:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b58:	e8 cb df ff ff       	call   f0100b28 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102b5d:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102b60:	83 e0 f3             	and    $0xfffffff3,%eax
f0102b63:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102b68:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102b6b:	83 ec 0c             	sub    $0xc,%esp
f0102b6e:	6a 00                	push   $0x0
f0102b70:	e8 fa e3 ff ff       	call   f0100f6f <page_alloc>
f0102b75:	89 c6                	mov    %eax,%esi
f0102b77:	83 c4 10             	add    $0x10,%esp
f0102b7a:	85 c0                	test   %eax,%eax
f0102b7c:	0f 84 12 02 00 00    	je     f0102d94 <mem_init+0x1acc>
	assert((pp1 = page_alloc(0)));
f0102b82:	83 ec 0c             	sub    $0xc,%esp
f0102b85:	6a 00                	push   $0x0
f0102b87:	e8 e3 e3 ff ff       	call   f0100f6f <page_alloc>
f0102b8c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102b8f:	83 c4 10             	add    $0x10,%esp
f0102b92:	85 c0                	test   %eax,%eax
f0102b94:	0f 84 19 02 00 00    	je     f0102db3 <mem_init+0x1aeb>
	assert((pp2 = page_alloc(0)));
f0102b9a:	83 ec 0c             	sub    $0xc,%esp
f0102b9d:	6a 00                	push   $0x0
f0102b9f:	e8 cb e3 ff ff       	call   f0100f6f <page_alloc>
f0102ba4:	89 c7                	mov    %eax,%edi
f0102ba6:	83 c4 10             	add    $0x10,%esp
f0102ba9:	85 c0                	test   %eax,%eax
f0102bab:	0f 84 21 02 00 00    	je     f0102dd2 <mem_init+0x1b0a>
	page_free(pp0);
f0102bb1:	83 ec 0c             	sub    $0xc,%esp
f0102bb4:	56                   	push   %esi
f0102bb5:	e8 44 e4 ff ff       	call   f0100ffe <page_free>
	return (pp - pages) << PGSHIFT;
f0102bba:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f0102bc0:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102bc3:	2b 08                	sub    (%eax),%ecx
f0102bc5:	89 c8                	mov    %ecx,%eax
f0102bc7:	c1 f8 03             	sar    $0x3,%eax
f0102bca:	89 c2                	mov    %eax,%edx
f0102bcc:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102bcf:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102bd4:	83 c4 10             	add    $0x10,%esp
f0102bd7:	c7 c1 e8 ef 18 f0    	mov    $0xf018efe8,%ecx
f0102bdd:	3b 01                	cmp    (%ecx),%eax
f0102bdf:	0f 83 0c 02 00 00    	jae    f0102df1 <mem_init+0x1b29>
	memset(page2kva(pp1), 1, PGSIZE);
f0102be5:	83 ec 04             	sub    $0x4,%esp
f0102be8:	68 00 10 00 00       	push   $0x1000
f0102bed:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102bef:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102bf5:	52                   	push   %edx
f0102bf6:	e8 4c 19 00 00       	call   f0104547 <memset>
	return (pp - pages) << PGSHIFT;
f0102bfb:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f0102c01:	89 f9                	mov    %edi,%ecx
f0102c03:	2b 08                	sub    (%eax),%ecx
f0102c05:	89 c8                	mov    %ecx,%eax
f0102c07:	c1 f8 03             	sar    $0x3,%eax
f0102c0a:	89 c2                	mov    %eax,%edx
f0102c0c:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102c0f:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102c14:	83 c4 10             	add    $0x10,%esp
f0102c17:	c7 c1 e8 ef 18 f0    	mov    $0xf018efe8,%ecx
f0102c1d:	3b 01                	cmp    (%ecx),%eax
f0102c1f:	0f 83 e2 01 00 00    	jae    f0102e07 <mem_init+0x1b3f>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c25:	83 ec 04             	sub    $0x4,%esp
f0102c28:	68 00 10 00 00       	push   $0x1000
f0102c2d:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102c2f:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102c35:	52                   	push   %edx
f0102c36:	e8 0c 19 00 00       	call   f0104547 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c3b:	6a 02                	push   $0x2
f0102c3d:	68 00 10 00 00       	push   $0x1000
f0102c42:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102c45:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0102c4b:	ff 30                	pushl  (%eax)
f0102c4d:	e8 e8 e5 ff ff       	call   f010123a <page_insert>
	assert(pp1->pp_ref == 1);
f0102c52:	83 c4 20             	add    $0x20,%esp
f0102c55:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c58:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102c5d:	0f 85 ba 01 00 00    	jne    f0102e1d <mem_init+0x1b55>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102c63:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102c6a:	01 01 01 
f0102c6d:	0f 85 c9 01 00 00    	jne    f0102e3c <mem_init+0x1b74>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102c73:	6a 02                	push   $0x2
f0102c75:	68 00 10 00 00       	push   $0x1000
f0102c7a:	57                   	push   %edi
f0102c7b:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0102c81:	ff 30                	pushl  (%eax)
f0102c83:	e8 b2 e5 ff ff       	call   f010123a <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102c88:	83 c4 10             	add    $0x10,%esp
f0102c8b:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102c92:	02 02 02 
f0102c95:	0f 85 c0 01 00 00    	jne    f0102e5b <mem_init+0x1b93>
	assert(pp2->pp_ref == 1);
f0102c9b:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102ca0:	0f 85 d4 01 00 00    	jne    f0102e7a <mem_init+0x1bb2>
	assert(pp1->pp_ref == 0);
f0102ca6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ca9:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102cae:	0f 85 e5 01 00 00    	jne    f0102e99 <mem_init+0x1bd1>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102cb4:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102cbb:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102cbe:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f0102cc4:	89 f9                	mov    %edi,%ecx
f0102cc6:	2b 08                	sub    (%eax),%ecx
f0102cc8:	89 c8                	mov    %ecx,%eax
f0102cca:	c1 f8 03             	sar    $0x3,%eax
f0102ccd:	89 c2                	mov    %eax,%edx
f0102ccf:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102cd2:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102cd7:	c7 c1 e8 ef 18 f0    	mov    $0xf018efe8,%ecx
f0102cdd:	3b 01                	cmp    (%ecx),%eax
f0102cdf:	0f 83 d3 01 00 00    	jae    f0102eb8 <mem_init+0x1bf0>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102ce5:	81 ba 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%edx)
f0102cec:	03 03 03 
f0102cef:	0f 85 d9 01 00 00    	jne    f0102ece <mem_init+0x1c06>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102cf5:	83 ec 08             	sub    $0x8,%esp
f0102cf8:	68 00 10 00 00       	push   $0x1000
f0102cfd:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0102d03:	ff 30                	pushl  (%eax)
f0102d05:	e8 ea e4 ff ff       	call   f01011f4 <page_remove>
	assert(pp2->pp_ref == 0);
f0102d0a:	83 c4 10             	add    $0x10,%esp
f0102d0d:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102d12:	0f 85 d5 01 00 00    	jne    f0102eed <mem_init+0x1c25>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102d18:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f0102d1e:	8b 08                	mov    (%eax),%ecx
f0102d20:	8b 11                	mov    (%ecx),%edx
f0102d22:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102d28:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f0102d2e:	89 f7                	mov    %esi,%edi
f0102d30:	2b 38                	sub    (%eax),%edi
f0102d32:	89 f8                	mov    %edi,%eax
f0102d34:	c1 f8 03             	sar    $0x3,%eax
f0102d37:	c1 e0 0c             	shl    $0xc,%eax
f0102d3a:	39 c2                	cmp    %eax,%edx
f0102d3c:	0f 85 ca 01 00 00    	jne    f0102f0c <mem_init+0x1c44>
	kern_pgdir[0] = 0;
f0102d42:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102d48:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102d4d:	0f 85 d8 01 00 00    	jne    f0102f2b <mem_init+0x1c63>
	pp0->pp_ref = 0;
f0102d53:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102d59:	83 ec 0c             	sub    $0xc,%esp
f0102d5c:	56                   	push   %esi
f0102d5d:	e8 9c e2 ff ff       	call   f0100ffe <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102d62:	8d 83 f8 95 f7 ff    	lea    -0x86a08(%ebx),%eax
f0102d68:	89 04 24             	mov    %eax,(%esp)
f0102d6b:	e8 67 07 00 00       	call   f01034d7 <cprintf>
}
f0102d70:	83 c4 10             	add    $0x10,%esp
f0102d73:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d76:	5b                   	pop    %ebx
f0102d77:	5e                   	pop    %esi
f0102d78:	5f                   	pop    %edi
f0102d79:	5d                   	pop    %ebp
f0102d7a:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d7b:	50                   	push   %eax
f0102d7c:	8d 83 e0 8f f7 ff    	lea    -0x87020(%ebx),%eax
f0102d82:	50                   	push   %eax
f0102d83:	68 f0 00 00 00       	push   $0xf0
f0102d88:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102d8e:	50                   	push   %eax
f0102d8f:	e8 21 d3 ff ff       	call   f01000b5 <_panic>
	assert((pp0 = page_alloc(0)));
f0102d94:	8d 83 f2 96 f7 ff    	lea    -0x8690e(%ebx),%eax
f0102d9a:	50                   	push   %eax
f0102d9b:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102da1:	50                   	push   %eax
f0102da2:	68 18 04 00 00       	push   $0x418
f0102da7:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102dad:	50                   	push   %eax
f0102dae:	e8 02 d3 ff ff       	call   f01000b5 <_panic>
	assert((pp1 = page_alloc(0)));
f0102db3:	8d 83 08 97 f7 ff    	lea    -0x868f8(%ebx),%eax
f0102db9:	50                   	push   %eax
f0102dba:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102dc0:	50                   	push   %eax
f0102dc1:	68 19 04 00 00       	push   $0x419
f0102dc6:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102dcc:	50                   	push   %eax
f0102dcd:	e8 e3 d2 ff ff       	call   f01000b5 <_panic>
	assert((pp2 = page_alloc(0)));
f0102dd2:	8d 83 1e 97 f7 ff    	lea    -0x868e2(%ebx),%eax
f0102dd8:	50                   	push   %eax
f0102dd9:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102ddf:	50                   	push   %eax
f0102de0:	68 1a 04 00 00       	push   $0x41a
f0102de5:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102deb:	50                   	push   %eax
f0102dec:	e8 c4 d2 ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102df1:	52                   	push   %edx
f0102df2:	8d 83 30 8e f7 ff    	lea    -0x871d0(%ebx),%eax
f0102df8:	50                   	push   %eax
f0102df9:	6a 56                	push   $0x56
f0102dfb:	8d 83 2d 96 f7 ff    	lea    -0x869d3(%ebx),%eax
f0102e01:	50                   	push   %eax
f0102e02:	e8 ae d2 ff ff       	call   f01000b5 <_panic>
f0102e07:	52                   	push   %edx
f0102e08:	8d 83 30 8e f7 ff    	lea    -0x871d0(%ebx),%eax
f0102e0e:	50                   	push   %eax
f0102e0f:	6a 56                	push   $0x56
f0102e11:	8d 83 2d 96 f7 ff    	lea    -0x869d3(%ebx),%eax
f0102e17:	50                   	push   %eax
f0102e18:	e8 98 d2 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 1);
f0102e1d:	8d 83 ef 97 f7 ff    	lea    -0x86811(%ebx),%eax
f0102e23:	50                   	push   %eax
f0102e24:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102e2a:	50                   	push   %eax
f0102e2b:	68 1f 04 00 00       	push   $0x41f
f0102e30:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102e36:	50                   	push   %eax
f0102e37:	e8 79 d2 ff ff       	call   f01000b5 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102e3c:	8d 83 84 95 f7 ff    	lea    -0x86a7c(%ebx),%eax
f0102e42:	50                   	push   %eax
f0102e43:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102e49:	50                   	push   %eax
f0102e4a:	68 20 04 00 00       	push   $0x420
f0102e4f:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102e55:	50                   	push   %eax
f0102e56:	e8 5a d2 ff ff       	call   f01000b5 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102e5b:	8d 83 a8 95 f7 ff    	lea    -0x86a58(%ebx),%eax
f0102e61:	50                   	push   %eax
f0102e62:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102e68:	50                   	push   %eax
f0102e69:	68 22 04 00 00       	push   $0x422
f0102e6e:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102e74:	50                   	push   %eax
f0102e75:	e8 3b d2 ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 1);
f0102e7a:	8d 83 11 98 f7 ff    	lea    -0x867ef(%ebx),%eax
f0102e80:	50                   	push   %eax
f0102e81:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102e87:	50                   	push   %eax
f0102e88:	68 23 04 00 00       	push   $0x423
f0102e8d:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102e93:	50                   	push   %eax
f0102e94:	e8 1c d2 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 0);
f0102e99:	8d 83 7b 98 f7 ff    	lea    -0x86785(%ebx),%eax
f0102e9f:	50                   	push   %eax
f0102ea0:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102ea6:	50                   	push   %eax
f0102ea7:	68 24 04 00 00       	push   $0x424
f0102eac:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102eb2:	50                   	push   %eax
f0102eb3:	e8 fd d1 ff ff       	call   f01000b5 <_panic>
f0102eb8:	52                   	push   %edx
f0102eb9:	8d 83 30 8e f7 ff    	lea    -0x871d0(%ebx),%eax
f0102ebf:	50                   	push   %eax
f0102ec0:	6a 56                	push   $0x56
f0102ec2:	8d 83 2d 96 f7 ff    	lea    -0x869d3(%ebx),%eax
f0102ec8:	50                   	push   %eax
f0102ec9:	e8 e7 d1 ff ff       	call   f01000b5 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102ece:	8d 83 cc 95 f7 ff    	lea    -0x86a34(%ebx),%eax
f0102ed4:	50                   	push   %eax
f0102ed5:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102edb:	50                   	push   %eax
f0102edc:	68 26 04 00 00       	push   $0x426
f0102ee1:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102ee7:	50                   	push   %eax
f0102ee8:	e8 c8 d1 ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 0);
f0102eed:	8d 83 49 98 f7 ff    	lea    -0x867b7(%ebx),%eax
f0102ef3:	50                   	push   %eax
f0102ef4:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102efa:	50                   	push   %eax
f0102efb:	68 28 04 00 00       	push   $0x428
f0102f00:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102f06:	50                   	push   %eax
f0102f07:	e8 a9 d1 ff ff       	call   f01000b5 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102f0c:	8d 83 dc 90 f7 ff    	lea    -0x86f24(%ebx),%eax
f0102f12:	50                   	push   %eax
f0102f13:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102f19:	50                   	push   %eax
f0102f1a:	68 2b 04 00 00       	push   $0x42b
f0102f1f:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102f25:	50                   	push   %eax
f0102f26:	e8 8a d1 ff ff       	call   f01000b5 <_panic>
	assert(pp0->pp_ref == 1);
f0102f2b:	8d 83 00 98 f7 ff    	lea    -0x86800(%ebx),%eax
f0102f31:	50                   	push   %eax
f0102f32:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0102f38:	50                   	push   %eax
f0102f39:	68 2d 04 00 00       	push   $0x42d
f0102f3e:	8d 83 21 96 f7 ff    	lea    -0x869df(%ebx),%eax
f0102f44:	50                   	push   %eax
f0102f45:	e8 6b d1 ff ff       	call   f01000b5 <_panic>

f0102f4a <tlb_invalidate>:
{
f0102f4a:	f3 0f 1e fb          	endbr32 
f0102f4e:	55                   	push   %ebp
f0102f4f:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102f51:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f54:	0f 01 38             	invlpg (%eax)
}
f0102f57:	5d                   	pop    %ebp
f0102f58:	c3                   	ret    

f0102f59 <user_mem_check>:
{
f0102f59:	f3 0f 1e fb          	endbr32 
}
f0102f5d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f62:	c3                   	ret    

f0102f63 <user_mem_assert>:
{
f0102f63:	f3 0f 1e fb          	endbr32 
}
f0102f67:	c3                   	ret    

f0102f68 <__x86.get_pc_thunk.dx>:
f0102f68:	8b 14 24             	mov    (%esp),%edx
f0102f6b:	c3                   	ret    

f0102f6c <__x86.get_pc_thunk.cx>:
f0102f6c:	8b 0c 24             	mov    (%esp),%ecx
f0102f6f:	c3                   	ret    

f0102f70 <__x86.get_pc_thunk.di>:
f0102f70:	8b 3c 24             	mov    (%esp),%edi
f0102f73:	c3                   	ret    

f0102f74 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102f74:	f3 0f 1e fb          	endbr32 
f0102f78:	55                   	push   %ebp
f0102f79:	89 e5                	mov    %esp,%ebp
f0102f7b:	53                   	push   %ebx
f0102f7c:	e8 eb ff ff ff       	call   f0102f6c <__x86.get_pc_thunk.cx>
f0102f81:	81 c1 9b 90 08 00    	add    $0x8909b,%ecx
f0102f87:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f8a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102f8d:	85 c0                	test   %eax,%eax
f0102f8f:	74 42                	je     f0102fd3 <envid2env+0x5f>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102f91:	89 c2                	mov    %eax,%edx
f0102f93:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0102f99:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102f9c:	c1 e2 05             	shl    $0x5,%edx
f0102f9f:	03 91 0c 23 00 00    	add    0x230c(%ecx),%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102fa5:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0102fa9:	74 35                	je     f0102fe0 <envid2env+0x6c>
f0102fab:	39 42 48             	cmp    %eax,0x48(%edx)
f0102fae:	75 30                	jne    f0102fe0 <envid2env+0x6c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102fb0:	84 db                	test   %bl,%bl
f0102fb2:	74 12                	je     f0102fc6 <envid2env+0x52>
f0102fb4:	8b 81 08 23 00 00    	mov    0x2308(%ecx),%eax
f0102fba:	39 d0                	cmp    %edx,%eax
f0102fbc:	74 08                	je     f0102fc6 <envid2env+0x52>
f0102fbe:	8b 40 48             	mov    0x48(%eax),%eax
f0102fc1:	39 42 4c             	cmp    %eax,0x4c(%edx)
f0102fc4:	75 2a                	jne    f0102ff0 <envid2env+0x7c>
		*env_store = 0;
		return -E_BAD_ENV;
	}

	*env_store = e;
f0102fc6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fc9:	89 10                	mov    %edx,(%eax)
	return 0;
f0102fcb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102fd0:	5b                   	pop    %ebx
f0102fd1:	5d                   	pop    %ebp
f0102fd2:	c3                   	ret    
		*env_store = curenv;
f0102fd3:	8b 91 08 23 00 00    	mov    0x2308(%ecx),%edx
f0102fd9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102fdc:	89 13                	mov    %edx,(%ebx)
		return 0;
f0102fde:	eb f0                	jmp    f0102fd0 <envid2env+0x5c>
		*env_store = 0;
f0102fe0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fe3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102fe9:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102fee:	eb e0                	jmp    f0102fd0 <envid2env+0x5c>
		*env_store = 0;
f0102ff0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ff3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102ff9:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102ffe:	eb d0                	jmp    f0102fd0 <envid2env+0x5c>

f0103000 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0103000:	f3 0f 1e fb          	endbr32 
f0103004:	e8 1e d7 ff ff       	call   f0100727 <__x86.get_pc_thunk.ax>
f0103009:	05 13 90 08 00       	add    $0x89013,%eax
	asm volatile("lgdt (%0)" : : "r" (p));
f010300e:	8d 80 e4 1f 00 00    	lea    0x1fe4(%eax),%eax
f0103014:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0103017:	b8 23 00 00 00       	mov    $0x23,%eax
f010301c:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f010301e:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0103020:	b8 10 00 00 00       	mov    $0x10,%eax
f0103025:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0103027:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0103029:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f010302b:	ea 32 30 10 f0 08 00 	ljmp   $0x8,$0xf0103032
	asm volatile("lldt %0" : : "r" (sel));
f0103032:	b8 00 00 00 00       	mov    $0x0,%eax
f0103037:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f010303a:	c3                   	ret    

f010303b <env_init>:
{
f010303b:	f3 0f 1e fb          	endbr32 
f010303f:	55                   	push   %ebp
f0103040:	89 e5                	mov    %esp,%ebp
f0103042:	83 ec 08             	sub    $0x8,%esp
	env_init_percpu();
f0103045:	e8 b6 ff ff ff       	call   f0103000 <env_init_percpu>
}
f010304a:	c9                   	leave  
f010304b:	c3                   	ret    

f010304c <env_alloc>:
//	-E_NO_FREE_ENV if all NENV environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f010304c:	f3 0f 1e fb          	endbr32 
f0103050:	55                   	push   %ebp
f0103051:	89 e5                	mov    %esp,%ebp
f0103053:	56                   	push   %esi
f0103054:	53                   	push   %ebx
f0103055:	e8 19 d1 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f010305a:	81 c3 c2 8f 08 00    	add    $0x88fc2,%ebx
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103060:	8b b3 10 23 00 00    	mov    0x2310(%ebx),%esi
f0103066:	85 f6                	test   %esi,%esi
f0103068:	0f 84 03 01 00 00    	je     f0103171 <env_alloc+0x125>
	if (!(p = page_alloc(ALLOC_ZERO)))
f010306e:	83 ec 0c             	sub    $0xc,%esp
f0103071:	6a 01                	push   $0x1
f0103073:	e8 f7 de ff ff       	call   f0100f6f <page_alloc>
f0103078:	83 c4 10             	add    $0x10,%esp
f010307b:	85 c0                	test   %eax,%eax
f010307d:	0f 84 f5 00 00 00    	je     f0103178 <env_alloc+0x12c>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103083:	8b 46 5c             	mov    0x5c(%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f0103086:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010308b:	0f 86 c7 00 00 00    	jbe    f0103158 <env_alloc+0x10c>
	return (physaddr_t)kva - KERNBASE;
f0103091:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103097:	83 ca 05             	or     $0x5,%edx
f010309a:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01030a0:	8b 46 48             	mov    0x48(%esi),%eax
f01030a3:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
		generation = 1 << ENVGENSHIFT;
f01030a8:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01030ad:	ba 00 10 00 00       	mov    $0x1000,%edx
f01030b2:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01030b5:	89 f2                	mov    %esi,%edx
f01030b7:	2b 93 0c 23 00 00    	sub    0x230c(%ebx),%edx
f01030bd:	c1 fa 05             	sar    $0x5,%edx
f01030c0:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01030c6:	09 d0                	or     %edx,%eax
f01030c8:	89 46 48             	mov    %eax,0x48(%esi)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01030cb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030ce:	89 46 4c             	mov    %eax,0x4c(%esi)
	e->env_type = ENV_TYPE_USER;
f01030d1:	c7 46 50 00 00 00 00 	movl   $0x0,0x50(%esi)
	e->env_status = ENV_RUNNABLE;
f01030d8:	c7 46 54 02 00 00 00 	movl   $0x2,0x54(%esi)
	e->env_runs = 0;
f01030df:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01030e6:	83 ec 04             	sub    $0x4,%esp
f01030e9:	6a 44                	push   $0x44
f01030eb:	6a 00                	push   $0x0
f01030ed:	56                   	push   %esi
f01030ee:	e8 54 14 00 00       	call   f0104547 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01030f3:	66 c7 46 24 23 00    	movw   $0x23,0x24(%esi)
	e->env_tf.tf_es = GD_UD | 3;
f01030f9:	66 c7 46 20 23 00    	movw   $0x23,0x20(%esi)
	e->env_tf.tf_ss = GD_UD | 3;
f01030ff:	66 c7 46 40 23 00    	movw   $0x23,0x40(%esi)
	e->env_tf.tf_esp = USTACKTOP;
f0103105:	c7 46 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%esi)
	e->env_tf.tf_cs = GD_UT | 3;
f010310c:	66 c7 46 34 1b 00    	movw   $0x1b,0x34(%esi)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0103112:	8b 46 44             	mov    0x44(%esi),%eax
f0103115:	89 83 10 23 00 00    	mov    %eax,0x2310(%ebx)
	*newenv_store = e;
f010311b:	8b 45 08             	mov    0x8(%ebp),%eax
f010311e:	89 30                	mov    %esi,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103120:	8b 4e 48             	mov    0x48(%esi),%ecx
f0103123:	8b 83 08 23 00 00    	mov    0x2308(%ebx),%eax
f0103129:	83 c4 10             	add    $0x10,%esp
f010312c:	ba 00 00 00 00       	mov    $0x0,%edx
f0103131:	85 c0                	test   %eax,%eax
f0103133:	74 03                	je     f0103138 <env_alloc+0xec>
f0103135:	8b 50 48             	mov    0x48(%eax),%edx
f0103138:	83 ec 04             	sub    $0x4,%esp
f010313b:	51                   	push   %ecx
f010313c:	52                   	push   %edx
f010313d:	8d 83 45 99 f7 ff    	lea    -0x866bb(%ebx),%eax
f0103143:	50                   	push   %eax
f0103144:	e8 8e 03 00 00       	call   f01034d7 <cprintf>
	return 0;
f0103149:	83 c4 10             	add    $0x10,%esp
f010314c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103151:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103154:	5b                   	pop    %ebx
f0103155:	5e                   	pop    %esi
f0103156:	5d                   	pop    %ebp
f0103157:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103158:	50                   	push   %eax
f0103159:	8d 83 e0 8f f7 ff    	lea    -0x87020(%ebx),%eax
f010315f:	50                   	push   %eax
f0103160:	68 b9 00 00 00       	push   $0xb9
f0103165:	8d 83 3a 99 f7 ff    	lea    -0x866c6(%ebx),%eax
f010316b:	50                   	push   %eax
f010316c:	e8 44 cf ff ff       	call   f01000b5 <_panic>
		return -E_NO_FREE_ENV;
f0103171:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103176:	eb d9                	jmp    f0103151 <env_alloc+0x105>
		return -E_NO_MEM;
f0103178:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010317d:	eb d2                	jmp    f0103151 <env_alloc+0x105>

f010317f <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010317f:	f3 0f 1e fb          	endbr32 
	// LAB 3: Your code here.
}
f0103183:	c3                   	ret    

f0103184 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103184:	f3 0f 1e fb          	endbr32 
f0103188:	55                   	push   %ebp
f0103189:	89 e5                	mov    %esp,%ebp
f010318b:	57                   	push   %edi
f010318c:	56                   	push   %esi
f010318d:	53                   	push   %ebx
f010318e:	83 ec 2c             	sub    $0x2c,%esp
f0103191:	e8 dd cf ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103196:	81 c3 86 8e 08 00    	add    $0x88e86,%ebx
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f010319c:	8b 93 08 23 00 00    	mov    0x2308(%ebx),%edx
f01031a2:	3b 55 08             	cmp    0x8(%ebp),%edx
f01031a5:	74 47                	je     f01031ee <env_free+0x6a>
		lcr3(PADDR(kern_pgdir));

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01031a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01031aa:	8b 48 48             	mov    0x48(%eax),%ecx
f01031ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01031b2:	85 d2                	test   %edx,%edx
f01031b4:	74 03                	je     f01031b9 <env_free+0x35>
f01031b6:	8b 42 48             	mov    0x48(%edx),%eax
f01031b9:	83 ec 04             	sub    $0x4,%esp
f01031bc:	51                   	push   %ecx
f01031bd:	50                   	push   %eax
f01031be:	8d 83 5a 99 f7 ff    	lea    -0x866a6(%ebx),%eax
f01031c4:	50                   	push   %eax
f01031c5:	e8 0d 03 00 00       	call   f01034d7 <cprintf>
f01031ca:	83 c4 10             	add    $0x10,%esp
f01031cd:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	if (PGNUM(pa) >= npages)
f01031d4:	c7 c0 e8 ef 18 f0    	mov    $0xf018efe8,%eax
f01031da:	89 45 d8             	mov    %eax,-0x28(%ebp)
	if (PGNUM(pa) >= npages)
f01031dd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	return &pages[PGNUM(pa)];
f01031e0:	c7 c0 f0 ef 18 f0    	mov    $0xf018eff0,%eax
f01031e6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01031e9:	e9 bf 00 00 00       	jmp    f01032ad <env_free+0x129>
		lcr3(PADDR(kern_pgdir));
f01031ee:	c7 c0 ec ef 18 f0    	mov    $0xf018efec,%eax
f01031f4:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01031f6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031fb:	76 10                	jbe    f010320d <env_free+0x89>
	return (physaddr_t)kva - KERNBASE;
f01031fd:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103202:	0f 22 d8             	mov    %eax,%cr3
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103205:	8b 45 08             	mov    0x8(%ebp),%eax
f0103208:	8b 48 48             	mov    0x48(%eax),%ecx
f010320b:	eb a9                	jmp    f01031b6 <env_free+0x32>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010320d:	50                   	push   %eax
f010320e:	8d 83 e0 8f f7 ff    	lea    -0x87020(%ebx),%eax
f0103214:	50                   	push   %eax
f0103215:	68 68 01 00 00       	push   $0x168
f010321a:	8d 83 3a 99 f7 ff    	lea    -0x866c6(%ebx),%eax
f0103220:	50                   	push   %eax
f0103221:	e8 8f ce ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103226:	57                   	push   %edi
f0103227:	8d 83 30 8e f7 ff    	lea    -0x871d0(%ebx),%eax
f010322d:	50                   	push   %eax
f010322e:	68 77 01 00 00       	push   $0x177
f0103233:	8d 83 3a 99 f7 ff    	lea    -0x866c6(%ebx),%eax
f0103239:	50                   	push   %eax
f010323a:	e8 76 ce ff ff       	call   f01000b5 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010323f:	83 ec 08             	sub    $0x8,%esp
f0103242:	89 f0                	mov    %esi,%eax
f0103244:	c1 e0 0c             	shl    $0xc,%eax
f0103247:	0b 45 e4             	or     -0x1c(%ebp),%eax
f010324a:	50                   	push   %eax
f010324b:	8b 45 08             	mov    0x8(%ebp),%eax
f010324e:	ff 70 5c             	pushl  0x5c(%eax)
f0103251:	e8 9e df ff ff       	call   f01011f4 <page_remove>
f0103256:	83 c4 10             	add    $0x10,%esp
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103259:	83 c6 01             	add    $0x1,%esi
f010325c:	83 c7 04             	add    $0x4,%edi
f010325f:	81 fe 00 04 00 00    	cmp    $0x400,%esi
f0103265:	74 07                	je     f010326e <env_free+0xea>
			if (pt[pteno] & PTE_P)
f0103267:	f6 07 01             	testb  $0x1,(%edi)
f010326a:	74 ed                	je     f0103259 <env_free+0xd5>
f010326c:	eb d1                	jmp    f010323f <env_free+0xbb>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f010326e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103271:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103274:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103277:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f010327e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103281:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103284:	3b 10                	cmp    (%eax),%edx
f0103286:	73 67                	jae    f01032ef <env_free+0x16b>
		page_decref(pa2page(pa));
f0103288:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f010328b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010328e:	8b 00                	mov    (%eax),%eax
f0103290:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103293:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0103296:	50                   	push   %eax
f0103297:	e8 b5 dd ff ff       	call   f0101051 <page_decref>
f010329c:	83 c4 10             	add    $0x10,%esp
f010329f:	83 45 e0 04          	addl   $0x4,-0x20(%ebp)
f01032a3:	8b 45 e0             	mov    -0x20(%ebp),%eax
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01032a6:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f01032ab:	74 5a                	je     f0103307 <env_free+0x183>
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01032ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01032b0:	8b 40 5c             	mov    0x5c(%eax),%eax
f01032b3:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01032b6:	8b 04 10             	mov    (%eax,%edx,1),%eax
f01032b9:	a8 01                	test   $0x1,%al
f01032bb:	74 e2                	je     f010329f <env_free+0x11b>
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01032bd:	89 c7                	mov    %eax,%edi
f01032bf:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	if (PGNUM(pa) >= npages)
f01032c5:	c1 e8 0c             	shr    $0xc,%eax
f01032c8:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01032cb:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01032ce:	39 02                	cmp    %eax,(%edx)
f01032d0:	0f 86 50 ff ff ff    	jbe    f0103226 <env_free+0xa2>
	return (void *)(pa + KERNBASE);
f01032d6:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
f01032dc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032df:	c1 e0 14             	shl    $0x14,%eax
f01032e2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01032e5:	be 00 00 00 00       	mov    $0x0,%esi
f01032ea:	e9 78 ff ff ff       	jmp    f0103267 <env_free+0xe3>
		panic("pa2page called with invalid pa");
f01032ef:	83 ec 04             	sub    $0x4,%esp
f01032f2:	8d 83 84 8f f7 ff    	lea    -0x8707c(%ebx),%eax
f01032f8:	50                   	push   %eax
f01032f9:	6a 4f                	push   $0x4f
f01032fb:	8d 83 2d 96 f7 ff    	lea    -0x869d3(%ebx),%eax
f0103301:	50                   	push   %eax
f0103302:	e8 ae cd ff ff       	call   f01000b5 <_panic>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103307:	8b 45 08             	mov    0x8(%ebp),%eax
f010330a:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010330d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103312:	76 57                	jbe    f010336b <env_free+0x1e7>
	e->env_pgdir = 0;
f0103314:	8b 55 08             	mov    0x8(%ebp),%edx
f0103317:	c7 42 5c 00 00 00 00 	movl   $0x0,0x5c(%edx)
	return (physaddr_t)kva - KERNBASE;
f010331e:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f0103323:	c1 e8 0c             	shr    $0xc,%eax
f0103326:	c7 c2 e8 ef 18 f0    	mov    $0xf018efe8,%edx
f010332c:	3b 02                	cmp    (%edx),%eax
f010332e:	73 54                	jae    f0103384 <env_free+0x200>
	page_decref(pa2page(pa));
f0103330:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103333:	c7 c2 f0 ef 18 f0    	mov    $0xf018eff0,%edx
f0103339:	8b 12                	mov    (%edx),%edx
f010333b:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010333e:	50                   	push   %eax
f010333f:	e8 0d dd ff ff       	call   f0101051 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103344:	8b 45 08             	mov    0x8(%ebp),%eax
f0103347:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	e->env_link = env_free_list;
f010334e:	8b 83 10 23 00 00    	mov    0x2310(%ebx),%eax
f0103354:	8b 55 08             	mov    0x8(%ebp),%edx
f0103357:	89 42 44             	mov    %eax,0x44(%edx)
	env_free_list = e;
f010335a:	89 93 10 23 00 00    	mov    %edx,0x2310(%ebx)
}
f0103360:	83 c4 10             	add    $0x10,%esp
f0103363:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103366:	5b                   	pop    %ebx
f0103367:	5e                   	pop    %esi
f0103368:	5f                   	pop    %edi
f0103369:	5d                   	pop    %ebp
f010336a:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010336b:	50                   	push   %eax
f010336c:	8d 83 e0 8f f7 ff    	lea    -0x87020(%ebx),%eax
f0103372:	50                   	push   %eax
f0103373:	68 85 01 00 00       	push   $0x185
f0103378:	8d 83 3a 99 f7 ff    	lea    -0x866c6(%ebx),%eax
f010337e:	50                   	push   %eax
f010337f:	e8 31 cd ff ff       	call   f01000b5 <_panic>
		panic("pa2page called with invalid pa");
f0103384:	83 ec 04             	sub    $0x4,%esp
f0103387:	8d 83 84 8f f7 ff    	lea    -0x8707c(%ebx),%eax
f010338d:	50                   	push   %eax
f010338e:	6a 4f                	push   $0x4f
f0103390:	8d 83 2d 96 f7 ff    	lea    -0x869d3(%ebx),%eax
f0103396:	50                   	push   %eax
f0103397:	e8 19 cd ff ff       	call   f01000b5 <_panic>

f010339c <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f010339c:	f3 0f 1e fb          	endbr32 
f01033a0:	55                   	push   %ebp
f01033a1:	89 e5                	mov    %esp,%ebp
f01033a3:	53                   	push   %ebx
f01033a4:	83 ec 10             	sub    $0x10,%esp
f01033a7:	e8 c7 cd ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01033ac:	81 c3 70 8c 08 00    	add    $0x88c70,%ebx
	env_free(e);
f01033b2:	ff 75 08             	pushl  0x8(%ebp)
f01033b5:	e8 ca fd ff ff       	call   f0103184 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f01033ba:	8d 83 04 99 f7 ff    	lea    -0x866fc(%ebx),%eax
f01033c0:	89 04 24             	mov    %eax,(%esp)
f01033c3:	e8 0f 01 00 00       	call   f01034d7 <cprintf>
f01033c8:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f01033cb:	83 ec 0c             	sub    $0xc,%esp
f01033ce:	6a 00                	push   $0x0
f01033d0:	e8 8d d4 ff ff       	call   f0100862 <monitor>
f01033d5:	83 c4 10             	add    $0x10,%esp
f01033d8:	eb f1                	jmp    f01033cb <env_destroy+0x2f>

f01033da <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01033da:	f3 0f 1e fb          	endbr32 
f01033de:	55                   	push   %ebp
f01033df:	89 e5                	mov    %esp,%ebp
f01033e1:	53                   	push   %ebx
f01033e2:	83 ec 08             	sub    $0x8,%esp
f01033e5:	e8 89 cd ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01033ea:	81 c3 32 8c 08 00    	add    $0x88c32,%ebx
	asm volatile(
f01033f0:	8b 65 08             	mov    0x8(%ebp),%esp
f01033f3:	61                   	popa   
f01033f4:	07                   	pop    %es
f01033f5:	1f                   	pop    %ds
f01033f6:	83 c4 08             	add    $0x8,%esp
f01033f9:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01033fa:	8d 83 70 99 f7 ff    	lea    -0x86690(%ebx),%eax
f0103400:	50                   	push   %eax
f0103401:	68 ae 01 00 00       	push   $0x1ae
f0103406:	8d 83 3a 99 f7 ff    	lea    -0x866c6(%ebx),%eax
f010340c:	50                   	push   %eax
f010340d:	e8 a3 cc ff ff       	call   f01000b5 <_panic>

f0103412 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103412:	f3 0f 1e fb          	endbr32 
f0103416:	55                   	push   %ebp
f0103417:	89 e5                	mov    %esp,%ebp
f0103419:	53                   	push   %ebx
f010341a:	83 ec 08             	sub    $0x8,%esp
f010341d:	e8 51 cd ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103422:	81 c3 fa 8b 08 00    	add    $0x88bfa,%ebx
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	panic("env_run not yet implemented");
f0103428:	8d 83 7c 99 f7 ff    	lea    -0x86684(%ebx),%eax
f010342e:	50                   	push   %eax
f010342f:	68 cd 01 00 00       	push   $0x1cd
f0103434:	8d 83 3a 99 f7 ff    	lea    -0x866c6(%ebx),%eax
f010343a:	50                   	push   %eax
f010343b:	e8 75 cc ff ff       	call   f01000b5 <_panic>

f0103440 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103440:	f3 0f 1e fb          	endbr32 
f0103444:	55                   	push   %ebp
f0103445:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103447:	8b 45 08             	mov    0x8(%ebp),%eax
f010344a:	ba 70 00 00 00       	mov    $0x70,%edx
f010344f:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103450:	ba 71 00 00 00       	mov    $0x71,%edx
f0103455:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103456:	0f b6 c0             	movzbl %al,%eax
}
f0103459:	5d                   	pop    %ebp
f010345a:	c3                   	ret    

f010345b <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010345b:	f3 0f 1e fb          	endbr32 
f010345f:	55                   	push   %ebp
f0103460:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103462:	8b 45 08             	mov    0x8(%ebp),%eax
f0103465:	ba 70 00 00 00       	mov    $0x70,%edx
f010346a:	ee                   	out    %al,(%dx)
f010346b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010346e:	ba 71 00 00 00       	mov    $0x71,%edx
f0103473:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103474:	5d                   	pop    %ebp
f0103475:	c3                   	ret    

f0103476 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103476:	f3 0f 1e fb          	endbr32 
f010347a:	55                   	push   %ebp
f010347b:	89 e5                	mov    %esp,%ebp
f010347d:	53                   	push   %ebx
f010347e:	83 ec 10             	sub    $0x10,%esp
f0103481:	e8 ed cc ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103486:	81 c3 96 8b 08 00    	add    $0x88b96,%ebx
	cputchar(ch);
f010348c:	ff 75 08             	pushl  0x8(%ebp)
f010348f:	e8 60 d2 ff ff       	call   f01006f4 <cputchar>
	*cnt++;
}
f0103494:	83 c4 10             	add    $0x10,%esp
f0103497:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010349a:	c9                   	leave  
f010349b:	c3                   	ret    

f010349c <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010349c:	f3 0f 1e fb          	endbr32 
f01034a0:	55                   	push   %ebp
f01034a1:	89 e5                	mov    %esp,%ebp
f01034a3:	53                   	push   %ebx
f01034a4:	83 ec 14             	sub    $0x14,%esp
f01034a7:	e8 c7 cc ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01034ac:	81 c3 70 8b 08 00    	add    $0x88b70,%ebx
	int cnt = 0;
f01034b2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01034b9:	ff 75 0c             	pushl  0xc(%ebp)
f01034bc:	ff 75 08             	pushl  0x8(%ebp)
f01034bf:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01034c2:	50                   	push   %eax
f01034c3:	8d 83 5a 74 f7 ff    	lea    -0x88ba6(%ebx),%eax
f01034c9:	50                   	push   %eax
f01034ca:	e8 c4 08 00 00       	call   f0103d93 <vprintfmt>
	return cnt;
}
f01034cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01034d2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01034d5:	c9                   	leave  
f01034d6:	c3                   	ret    

f01034d7 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01034d7:	f3 0f 1e fb          	endbr32 
f01034db:	55                   	push   %ebp
f01034dc:	89 e5                	mov    %esp,%ebp
f01034de:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01034e1:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01034e4:	50                   	push   %eax
f01034e5:	ff 75 08             	pushl  0x8(%ebp)
f01034e8:	e8 af ff ff ff       	call   f010349c <vcprintf>
	va_end(ap);

	return cnt;
}
f01034ed:	c9                   	leave  
f01034ee:	c3                   	ret    

f01034ef <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01034ef:	f3 0f 1e fb          	endbr32 
f01034f3:	55                   	push   %ebp
f01034f4:	89 e5                	mov    %esp,%ebp
f01034f6:	57                   	push   %edi
f01034f7:	56                   	push   %esi
f01034f8:	53                   	push   %ebx
f01034f9:	83 ec 04             	sub    $0x4,%esp
f01034fc:	e8 72 cc ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103501:	81 c3 1b 8b 08 00    	add    $0x88b1b,%ebx
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103507:	c7 83 48 2b 00 00 00 	movl   $0xf0000000,0x2b48(%ebx)
f010350e:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0103511:	66 c7 83 4c 2b 00 00 	movw   $0x10,0x2b4c(%ebx)
f0103518:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f010351a:	66 c7 83 aa 2b 00 00 	movw   $0x68,0x2baa(%ebx)
f0103521:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103523:	c7 c0 00 b3 11 f0    	mov    $0xf011b300,%eax
f0103529:	66 c7 40 28 67 00    	movw   $0x67,0x28(%eax)
f010352f:	8d b3 44 2b 00 00    	lea    0x2b44(%ebx),%esi
f0103535:	66 89 70 2a          	mov    %si,0x2a(%eax)
f0103539:	89 f2                	mov    %esi,%edx
f010353b:	c1 ea 10             	shr    $0x10,%edx
f010353e:	88 50 2c             	mov    %dl,0x2c(%eax)
f0103541:	0f b6 50 2d          	movzbl 0x2d(%eax),%edx
f0103545:	83 e2 f0             	and    $0xfffffff0,%edx
f0103548:	83 ca 09             	or     $0x9,%edx
f010354b:	83 e2 9f             	and    $0xffffff9f,%edx
f010354e:	83 ca 80             	or     $0xffffff80,%edx
f0103551:	88 55 f3             	mov    %dl,-0xd(%ebp)
f0103554:	88 50 2d             	mov    %dl,0x2d(%eax)
f0103557:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
f010355b:	83 e1 c0             	and    $0xffffffc0,%ecx
f010355e:	83 c9 40             	or     $0x40,%ecx
f0103561:	83 e1 7f             	and    $0x7f,%ecx
f0103564:	88 48 2e             	mov    %cl,0x2e(%eax)
f0103567:	c1 ee 18             	shr    $0x18,%esi
f010356a:	89 f1                	mov    %esi,%ecx
f010356c:	88 48 2f             	mov    %cl,0x2f(%eax)
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f010356f:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
f0103573:	83 e2 ef             	and    $0xffffffef,%edx
f0103576:	88 50 2d             	mov    %dl,0x2d(%eax)
	asm volatile("ltr %0" : : "r" (sel));
f0103579:	b8 28 00 00 00       	mov    $0x28,%eax
f010357e:	0f 00 d8             	ltr    %ax
	asm volatile("lidt (%0)" : : "r" (p));
f0103581:	8d 83 ec 1f 00 00    	lea    0x1fec(%ebx),%eax
f0103587:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f010358a:	83 c4 04             	add    $0x4,%esp
f010358d:	5b                   	pop    %ebx
f010358e:	5e                   	pop    %esi
f010358f:	5f                   	pop    %edi
f0103590:	5d                   	pop    %ebp
f0103591:	c3                   	ret    

f0103592 <trap_init>:
{
f0103592:	f3 0f 1e fb          	endbr32 
f0103596:	55                   	push   %ebp
f0103597:	89 e5                	mov    %esp,%ebp
	trap_init_percpu();
f0103599:	e8 51 ff ff ff       	call   f01034ef <trap_init_percpu>
}
f010359e:	5d                   	pop    %ebp
f010359f:	c3                   	ret    

f01035a0 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01035a0:	f3 0f 1e fb          	endbr32 
f01035a4:	55                   	push   %ebp
f01035a5:	89 e5                	mov    %esp,%ebp
f01035a7:	56                   	push   %esi
f01035a8:	53                   	push   %ebx
f01035a9:	e8 c5 cb ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01035ae:	81 c3 6e 8a 08 00    	add    $0x88a6e,%ebx
f01035b4:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01035b7:	83 ec 08             	sub    $0x8,%esp
f01035ba:	ff 36                	pushl  (%esi)
f01035bc:	8d 83 98 99 f7 ff    	lea    -0x86668(%ebx),%eax
f01035c2:	50                   	push   %eax
f01035c3:	e8 0f ff ff ff       	call   f01034d7 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01035c8:	83 c4 08             	add    $0x8,%esp
f01035cb:	ff 76 04             	pushl  0x4(%esi)
f01035ce:	8d 83 a7 99 f7 ff    	lea    -0x86659(%ebx),%eax
f01035d4:	50                   	push   %eax
f01035d5:	e8 fd fe ff ff       	call   f01034d7 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01035da:	83 c4 08             	add    $0x8,%esp
f01035dd:	ff 76 08             	pushl  0x8(%esi)
f01035e0:	8d 83 b6 99 f7 ff    	lea    -0x8664a(%ebx),%eax
f01035e6:	50                   	push   %eax
f01035e7:	e8 eb fe ff ff       	call   f01034d7 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01035ec:	83 c4 08             	add    $0x8,%esp
f01035ef:	ff 76 0c             	pushl  0xc(%esi)
f01035f2:	8d 83 c5 99 f7 ff    	lea    -0x8663b(%ebx),%eax
f01035f8:	50                   	push   %eax
f01035f9:	e8 d9 fe ff ff       	call   f01034d7 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01035fe:	83 c4 08             	add    $0x8,%esp
f0103601:	ff 76 10             	pushl  0x10(%esi)
f0103604:	8d 83 d4 99 f7 ff    	lea    -0x8662c(%ebx),%eax
f010360a:	50                   	push   %eax
f010360b:	e8 c7 fe ff ff       	call   f01034d7 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103610:	83 c4 08             	add    $0x8,%esp
f0103613:	ff 76 14             	pushl  0x14(%esi)
f0103616:	8d 83 e3 99 f7 ff    	lea    -0x8661d(%ebx),%eax
f010361c:	50                   	push   %eax
f010361d:	e8 b5 fe ff ff       	call   f01034d7 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103622:	83 c4 08             	add    $0x8,%esp
f0103625:	ff 76 18             	pushl  0x18(%esi)
f0103628:	8d 83 f2 99 f7 ff    	lea    -0x8660e(%ebx),%eax
f010362e:	50                   	push   %eax
f010362f:	e8 a3 fe ff ff       	call   f01034d7 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103634:	83 c4 08             	add    $0x8,%esp
f0103637:	ff 76 1c             	pushl  0x1c(%esi)
f010363a:	8d 83 01 9a f7 ff    	lea    -0x865ff(%ebx),%eax
f0103640:	50                   	push   %eax
f0103641:	e8 91 fe ff ff       	call   f01034d7 <cprintf>
}
f0103646:	83 c4 10             	add    $0x10,%esp
f0103649:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010364c:	5b                   	pop    %ebx
f010364d:	5e                   	pop    %esi
f010364e:	5d                   	pop    %ebp
f010364f:	c3                   	ret    

f0103650 <print_trapframe>:
{
f0103650:	f3 0f 1e fb          	endbr32 
f0103654:	55                   	push   %ebp
f0103655:	89 e5                	mov    %esp,%ebp
f0103657:	57                   	push   %edi
f0103658:	56                   	push   %esi
f0103659:	53                   	push   %ebx
f010365a:	83 ec 14             	sub    $0x14,%esp
f010365d:	e8 11 cb ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103662:	81 c3 ba 89 08 00    	add    $0x889ba,%ebx
f0103668:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("TRAP frame at %p\n", tf);
f010366b:	56                   	push   %esi
f010366c:	8d 83 37 9b f7 ff    	lea    -0x864c9(%ebx),%eax
f0103672:	50                   	push   %eax
f0103673:	e8 5f fe ff ff       	call   f01034d7 <cprintf>
	print_regs(&tf->tf_regs);
f0103678:	89 34 24             	mov    %esi,(%esp)
f010367b:	e8 20 ff ff ff       	call   f01035a0 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103680:	83 c4 08             	add    $0x8,%esp
f0103683:	0f b7 46 20          	movzwl 0x20(%esi),%eax
f0103687:	50                   	push   %eax
f0103688:	8d 83 52 9a f7 ff    	lea    -0x865ae(%ebx),%eax
f010368e:	50                   	push   %eax
f010368f:	e8 43 fe ff ff       	call   f01034d7 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103694:	83 c4 08             	add    $0x8,%esp
f0103697:	0f b7 46 24          	movzwl 0x24(%esi),%eax
f010369b:	50                   	push   %eax
f010369c:	8d 83 65 9a f7 ff    	lea    -0x8659b(%ebx),%eax
f01036a2:	50                   	push   %eax
f01036a3:	e8 2f fe ff ff       	call   f01034d7 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01036a8:	8b 56 28             	mov    0x28(%esi),%edx
	if (trapno < ARRAY_SIZE(excnames))
f01036ab:	83 c4 10             	add    $0x10,%esp
f01036ae:	83 fa 13             	cmp    $0x13,%edx
f01036b1:	0f 86 e9 00 00 00    	jbe    f01037a0 <print_trapframe+0x150>
		return "System call";
f01036b7:	83 fa 30             	cmp    $0x30,%edx
f01036ba:	8d 83 10 9a f7 ff    	lea    -0x865f0(%ebx),%eax
f01036c0:	8d 8b 1f 9a f7 ff    	lea    -0x865e1(%ebx),%ecx
f01036c6:	0f 44 c1             	cmove  %ecx,%eax
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01036c9:	83 ec 04             	sub    $0x4,%esp
f01036cc:	50                   	push   %eax
f01036cd:	52                   	push   %edx
f01036ce:	8d 83 78 9a f7 ff    	lea    -0x86588(%ebx),%eax
f01036d4:	50                   	push   %eax
f01036d5:	e8 fd fd ff ff       	call   f01034d7 <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01036da:	83 c4 10             	add    $0x10,%esp
f01036dd:	39 b3 24 2b 00 00    	cmp    %esi,0x2b24(%ebx)
f01036e3:	0f 84 c3 00 00 00    	je     f01037ac <print_trapframe+0x15c>
	cprintf("  err  0x%08x", tf->tf_err);
f01036e9:	83 ec 08             	sub    $0x8,%esp
f01036ec:	ff 76 2c             	pushl  0x2c(%esi)
f01036ef:	8d 83 99 9a f7 ff    	lea    -0x86567(%ebx),%eax
f01036f5:	50                   	push   %eax
f01036f6:	e8 dc fd ff ff       	call   f01034d7 <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f01036fb:	83 c4 10             	add    $0x10,%esp
f01036fe:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f0103702:	0f 85 c9 00 00 00    	jne    f01037d1 <print_trapframe+0x181>
			tf->tf_err & 1 ? "protection" : "not-present");
f0103708:	8b 46 2c             	mov    0x2c(%esi),%eax
		cprintf(" [%s, %s, %s]\n",
f010370b:	89 c2                	mov    %eax,%edx
f010370d:	83 e2 01             	and    $0x1,%edx
f0103710:	8d 8b 2b 9a f7 ff    	lea    -0x865d5(%ebx),%ecx
f0103716:	8d 93 36 9a f7 ff    	lea    -0x865ca(%ebx),%edx
f010371c:	0f 44 ca             	cmove  %edx,%ecx
f010371f:	89 c2                	mov    %eax,%edx
f0103721:	83 e2 02             	and    $0x2,%edx
f0103724:	8d 93 42 9a f7 ff    	lea    -0x865be(%ebx),%edx
f010372a:	8d bb 48 9a f7 ff    	lea    -0x865b8(%ebx),%edi
f0103730:	0f 44 d7             	cmove  %edi,%edx
f0103733:	83 e0 04             	and    $0x4,%eax
f0103736:	8d 83 4d 9a f7 ff    	lea    -0x865b3(%ebx),%eax
f010373c:	8d bb 62 9b f7 ff    	lea    -0x8649e(%ebx),%edi
f0103742:	0f 44 c7             	cmove  %edi,%eax
f0103745:	51                   	push   %ecx
f0103746:	52                   	push   %edx
f0103747:	50                   	push   %eax
f0103748:	8d 83 a7 9a f7 ff    	lea    -0x86559(%ebx),%eax
f010374e:	50                   	push   %eax
f010374f:	e8 83 fd ff ff       	call   f01034d7 <cprintf>
f0103754:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103757:	83 ec 08             	sub    $0x8,%esp
f010375a:	ff 76 30             	pushl  0x30(%esi)
f010375d:	8d 83 b6 9a f7 ff    	lea    -0x8654a(%ebx),%eax
f0103763:	50                   	push   %eax
f0103764:	e8 6e fd ff ff       	call   f01034d7 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103769:	83 c4 08             	add    $0x8,%esp
f010376c:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103770:	50                   	push   %eax
f0103771:	8d 83 c5 9a f7 ff    	lea    -0x8653b(%ebx),%eax
f0103777:	50                   	push   %eax
f0103778:	e8 5a fd ff ff       	call   f01034d7 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010377d:	83 c4 08             	add    $0x8,%esp
f0103780:	ff 76 38             	pushl  0x38(%esi)
f0103783:	8d 83 d8 9a f7 ff    	lea    -0x86528(%ebx),%eax
f0103789:	50                   	push   %eax
f010378a:	e8 48 fd ff ff       	call   f01034d7 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010378f:	83 c4 10             	add    $0x10,%esp
f0103792:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f0103796:	75 50                	jne    f01037e8 <print_trapframe+0x198>
}
f0103798:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010379b:	5b                   	pop    %ebx
f010379c:	5e                   	pop    %esi
f010379d:	5f                   	pop    %edi
f010379e:	5d                   	pop    %ebp
f010379f:	c3                   	ret    
		return excnames[trapno];
f01037a0:	8b 84 93 44 20 00 00 	mov    0x2044(%ebx,%edx,4),%eax
f01037a7:	e9 1d ff ff ff       	jmp    f01036c9 <print_trapframe+0x79>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01037ac:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f01037b0:	0f 85 33 ff ff ff    	jne    f01036e9 <print_trapframe+0x99>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01037b6:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01037b9:	83 ec 08             	sub    $0x8,%esp
f01037bc:	50                   	push   %eax
f01037bd:	8d 83 8a 9a f7 ff    	lea    -0x86576(%ebx),%eax
f01037c3:	50                   	push   %eax
f01037c4:	e8 0e fd ff ff       	call   f01034d7 <cprintf>
f01037c9:	83 c4 10             	add    $0x10,%esp
f01037cc:	e9 18 ff ff ff       	jmp    f01036e9 <print_trapframe+0x99>
		cprintf("\n");
f01037d1:	83 ec 0c             	sub    $0xc,%esp
f01037d4:	8d 83 d2 98 f7 ff    	lea    -0x8672e(%ebx),%eax
f01037da:	50                   	push   %eax
f01037db:	e8 f7 fc ff ff       	call   f01034d7 <cprintf>
f01037e0:	83 c4 10             	add    $0x10,%esp
f01037e3:	e9 6f ff ff ff       	jmp    f0103757 <print_trapframe+0x107>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01037e8:	83 ec 08             	sub    $0x8,%esp
f01037eb:	ff 76 3c             	pushl  0x3c(%esi)
f01037ee:	8d 83 e7 9a f7 ff    	lea    -0x86519(%ebx),%eax
f01037f4:	50                   	push   %eax
f01037f5:	e8 dd fc ff ff       	call   f01034d7 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01037fa:	83 c4 08             	add    $0x8,%esp
f01037fd:	0f b7 46 40          	movzwl 0x40(%esi),%eax
f0103801:	50                   	push   %eax
f0103802:	8d 83 f6 9a f7 ff    	lea    -0x8650a(%ebx),%eax
f0103808:	50                   	push   %eax
f0103809:	e8 c9 fc ff ff       	call   f01034d7 <cprintf>
f010380e:	83 c4 10             	add    $0x10,%esp
}
f0103811:	eb 85                	jmp    f0103798 <print_trapframe+0x148>

f0103813 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103813:	f3 0f 1e fb          	endbr32 
f0103817:	55                   	push   %ebp
f0103818:	89 e5                	mov    %esp,%ebp
f010381a:	57                   	push   %edi
f010381b:	56                   	push   %esi
f010381c:	53                   	push   %ebx
f010381d:	83 ec 0c             	sub    $0xc,%esp
f0103820:	e8 4e c9 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103825:	81 c3 f7 87 08 00    	add    $0x887f7,%ebx
f010382b:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f010382e:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f010382f:	9c                   	pushf  
f0103830:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103831:	f6 c4 02             	test   $0x2,%ah
f0103834:	74 1f                	je     f0103855 <trap+0x42>
f0103836:	8d 83 09 9b f7 ff    	lea    -0x864f7(%ebx),%eax
f010383c:	50                   	push   %eax
f010383d:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f0103843:	50                   	push   %eax
f0103844:	68 a8 00 00 00       	push   $0xa8
f0103849:	8d 83 22 9b f7 ff    	lea    -0x864de(%ebx),%eax
f010384f:	50                   	push   %eax
f0103850:	e8 60 c8 ff ff       	call   f01000b5 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103855:	83 ec 08             	sub    $0x8,%esp
f0103858:	56                   	push   %esi
f0103859:	8d 83 2e 9b f7 ff    	lea    -0x864d2(%ebx),%eax
f010385f:	50                   	push   %eax
f0103860:	e8 72 fc ff ff       	call   f01034d7 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103865:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103869:	83 e0 03             	and    $0x3,%eax
f010386c:	83 c4 10             	add    $0x10,%esp
f010386f:	66 83 f8 03          	cmp    $0x3,%ax
f0103873:	75 1d                	jne    f0103892 <trap+0x7f>
		// Trapped from user mode.
		assert(curenv);
f0103875:	c7 c0 24 e3 18 f0    	mov    $0xf018e324,%eax
f010387b:	8b 00                	mov    (%eax),%eax
f010387d:	85 c0                	test   %eax,%eax
f010387f:	74 68                	je     f01038e9 <trap+0xd6>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103881:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103886:	89 c7                	mov    %eax,%edi
f0103888:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f010388a:	c7 c0 24 e3 18 f0    	mov    $0xf018e324,%eax
f0103890:	8b 30                	mov    (%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103892:	89 b3 24 2b 00 00    	mov    %esi,0x2b24(%ebx)
	print_trapframe(tf);
f0103898:	83 ec 0c             	sub    $0xc,%esp
f010389b:	56                   	push   %esi
f010389c:	e8 af fd ff ff       	call   f0103650 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01038a1:	83 c4 10             	add    $0x10,%esp
f01038a4:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01038a9:	74 5d                	je     f0103908 <trap+0xf5>
		env_destroy(curenv);
f01038ab:	83 ec 0c             	sub    $0xc,%esp
f01038ae:	c7 c6 24 e3 18 f0    	mov    $0xf018e324,%esi
f01038b4:	ff 36                	pushl  (%esi)
f01038b6:	e8 e1 fa ff ff       	call   f010339c <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01038bb:	8b 06                	mov    (%esi),%eax
f01038bd:	83 c4 10             	add    $0x10,%esp
f01038c0:	85 c0                	test   %eax,%eax
f01038c2:	74 06                	je     f01038ca <trap+0xb7>
f01038c4:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01038c8:	74 59                	je     f0103923 <trap+0x110>
f01038ca:	8d 83 ac 9c f7 ff    	lea    -0x86354(%ebx),%eax
f01038d0:	50                   	push   %eax
f01038d1:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01038d7:	50                   	push   %eax
f01038d8:	68 c0 00 00 00       	push   $0xc0
f01038dd:	8d 83 22 9b f7 ff    	lea    -0x864de(%ebx),%eax
f01038e3:	50                   	push   %eax
f01038e4:	e8 cc c7 ff ff       	call   f01000b5 <_panic>
		assert(curenv);
f01038e9:	8d 83 49 9b f7 ff    	lea    -0x864b7(%ebx),%eax
f01038ef:	50                   	push   %eax
f01038f0:	8d 83 47 96 f7 ff    	lea    -0x869b9(%ebx),%eax
f01038f6:	50                   	push   %eax
f01038f7:	68 ae 00 00 00       	push   $0xae
f01038fc:	8d 83 22 9b f7 ff    	lea    -0x864de(%ebx),%eax
f0103902:	50                   	push   %eax
f0103903:	e8 ad c7 ff ff       	call   f01000b5 <_panic>
		panic("unhandled trap in kernel");
f0103908:	83 ec 04             	sub    $0x4,%esp
f010390b:	8d 83 50 9b f7 ff    	lea    -0x864b0(%ebx),%eax
f0103911:	50                   	push   %eax
f0103912:	68 97 00 00 00       	push   $0x97
f0103917:	8d 83 22 9b f7 ff    	lea    -0x864de(%ebx),%eax
f010391d:	50                   	push   %eax
f010391e:	e8 92 c7 ff ff       	call   f01000b5 <_panic>
	env_run(curenv);
f0103923:	83 ec 0c             	sub    $0xc,%esp
f0103926:	50                   	push   %eax
f0103927:	e8 e6 fa ff ff       	call   f0103412 <env_run>

f010392c <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f010392c:	f3 0f 1e fb          	endbr32 
f0103930:	55                   	push   %ebp
f0103931:	89 e5                	mov    %esp,%ebp
f0103933:	57                   	push   %edi
f0103934:	56                   	push   %esi
f0103935:	53                   	push   %ebx
f0103936:	83 ec 0c             	sub    $0xc,%esp
f0103939:	e8 35 c8 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f010393e:	81 c3 de 86 08 00    	add    $0x886de,%ebx
f0103944:	8b 7d 08             	mov    0x8(%ebp),%edi
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103947:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010394a:	ff 77 30             	pushl  0x30(%edi)
f010394d:	50                   	push   %eax
f010394e:	c7 c6 24 e3 18 f0    	mov    $0xf018e324,%esi
f0103954:	8b 06                	mov    (%esi),%eax
f0103956:	ff 70 48             	pushl  0x48(%eax)
f0103959:	8d 83 d8 9c f7 ff    	lea    -0x86328(%ebx),%eax
f010395f:	50                   	push   %eax
f0103960:	e8 72 fb ff ff       	call   f01034d7 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103965:	89 3c 24             	mov    %edi,(%esp)
f0103968:	e8 e3 fc ff ff       	call   f0103650 <print_trapframe>
	env_destroy(curenv);
f010396d:	83 c4 04             	add    $0x4,%esp
f0103970:	ff 36                	pushl  (%esi)
f0103972:	e8 25 fa ff ff       	call   f010339c <env_destroy>
}
f0103977:	83 c4 10             	add    $0x10,%esp
f010397a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010397d:	5b                   	pop    %ebx
f010397e:	5e                   	pop    %esi
f010397f:	5f                   	pop    %edi
f0103980:	5d                   	pop    %ebp
f0103981:	c3                   	ret    

f0103982 <syscall>:
f0103982:	f3 0f 1e fb          	endbr32 
f0103986:	55                   	push   %ebp
f0103987:	89 e5                	mov    %esp,%ebp
f0103989:	53                   	push   %ebx
f010398a:	83 ec 08             	sub    $0x8,%esp
f010398d:	e8 e1 c7 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103992:	81 c3 8a 86 08 00    	add    $0x8868a,%ebx
f0103998:	8d 83 fb 9c f7 ff    	lea    -0x86305(%ebx),%eax
f010399e:	50                   	push   %eax
f010399f:	6a 49                	push   $0x49
f01039a1:	8d 83 13 9d f7 ff    	lea    -0x862ed(%ebx),%eax
f01039a7:	50                   	push   %eax
f01039a8:	e8 08 c7 ff ff       	call   f01000b5 <_panic>

f01039ad <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01039ad:	55                   	push   %ebp
f01039ae:	89 e5                	mov    %esp,%ebp
f01039b0:	57                   	push   %edi
f01039b1:	56                   	push   %esi
f01039b2:	53                   	push   %ebx
f01039b3:	83 ec 14             	sub    $0x14,%esp
f01039b6:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01039b9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01039bc:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01039bf:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f01039c2:	8b 1a                	mov    (%edx),%ebx
f01039c4:	8b 01                	mov    (%ecx),%eax
f01039c6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01039c9:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01039d0:	eb 23                	jmp    f01039f5 <stab_binsearch+0x48>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01039d2:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01039d5:	eb 1e                	jmp    f01039f5 <stab_binsearch+0x48>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01039d7:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01039da:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01039dd:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01039e1:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01039e4:	73 46                	jae    f0103a2c <stab_binsearch+0x7f>
			*region_left = m;
f01039e6:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01039e9:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01039eb:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f01039ee:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f01039f5:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01039f8:	7f 5f                	jg     f0103a59 <stab_binsearch+0xac>
		int true_m = (l + r) / 2, m = true_m;
f01039fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01039fd:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f0103a00:	89 d0                	mov    %edx,%eax
f0103a02:	c1 e8 1f             	shr    $0x1f,%eax
f0103a05:	01 d0                	add    %edx,%eax
f0103a07:	89 c7                	mov    %eax,%edi
f0103a09:	d1 ff                	sar    %edi
f0103a0b:	83 e0 fe             	and    $0xfffffffe,%eax
f0103a0e:	01 f8                	add    %edi,%eax
f0103a10:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103a13:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0103a17:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f0103a19:	39 c3                	cmp    %eax,%ebx
f0103a1b:	7f b5                	jg     f01039d2 <stab_binsearch+0x25>
f0103a1d:	0f b6 0a             	movzbl (%edx),%ecx
f0103a20:	83 ea 0c             	sub    $0xc,%edx
f0103a23:	39 f1                	cmp    %esi,%ecx
f0103a25:	74 b0                	je     f01039d7 <stab_binsearch+0x2a>
			m--;
f0103a27:	83 e8 01             	sub    $0x1,%eax
f0103a2a:	eb ed                	jmp    f0103a19 <stab_binsearch+0x6c>
		} else if (stabs[m].n_value > addr) {
f0103a2c:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103a2f:	76 14                	jbe    f0103a45 <stab_binsearch+0x98>
			*region_right = m - 1;
f0103a31:	83 e8 01             	sub    $0x1,%eax
f0103a34:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103a37:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103a3a:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f0103a3c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103a43:	eb b0                	jmp    f01039f5 <stab_binsearch+0x48>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103a45:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103a48:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0103a4a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103a4e:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f0103a50:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103a57:	eb 9c                	jmp    f01039f5 <stab_binsearch+0x48>
		}
	}

	if (!any_matches)
f0103a59:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103a5d:	75 15                	jne    f0103a74 <stab_binsearch+0xc7>
		*region_right = *region_left - 1;
f0103a5f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a62:	8b 00                	mov    (%eax),%eax
f0103a64:	83 e8 01             	sub    $0x1,%eax
f0103a67:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103a6a:	89 07                	mov    %eax,(%edi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0103a6c:	83 c4 14             	add    $0x14,%esp
f0103a6f:	5b                   	pop    %ebx
f0103a70:	5e                   	pop    %esi
f0103a71:	5f                   	pop    %edi
f0103a72:	5d                   	pop    %ebp
f0103a73:	c3                   	ret    
		for (l = *region_right;
f0103a74:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a77:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103a79:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103a7c:	8b 0f                	mov    (%edi),%ecx
f0103a7e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103a81:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103a84:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
		for (l = *region_right;
f0103a88:	eb 03                	jmp    f0103a8d <stab_binsearch+0xe0>
		     l--)
f0103a8a:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0103a8d:	39 c1                	cmp    %eax,%ecx
f0103a8f:	7d 0a                	jge    f0103a9b <stab_binsearch+0xee>
		     l > *region_left && stabs[l].n_type != type;
f0103a91:	0f b6 1a             	movzbl (%edx),%ebx
f0103a94:	83 ea 0c             	sub    $0xc,%edx
f0103a97:	39 f3                	cmp    %esi,%ebx
f0103a99:	75 ef                	jne    f0103a8a <stab_binsearch+0xdd>
		*region_left = l;
f0103a9b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103a9e:	89 07                	mov    %eax,(%edi)
}
f0103aa0:	eb ca                	jmp    f0103a6c <stab_binsearch+0xbf>

f0103aa2 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103aa2:	f3 0f 1e fb          	endbr32 
f0103aa6:	55                   	push   %ebp
f0103aa7:	89 e5                	mov    %esp,%ebp
f0103aa9:	57                   	push   %edi
f0103aaa:	56                   	push   %esi
f0103aab:	53                   	push   %ebx
f0103aac:	83 ec 2c             	sub    $0x2c,%esp
f0103aaf:	e8 bf c6 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103ab4:	81 c3 68 85 08 00    	add    $0x88568,%ebx
f0103aba:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103abd:	8d 83 22 9d f7 ff    	lea    -0x862de(%ebx),%eax
f0103ac3:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0103ac5:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0103acc:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f0103acf:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0103ad6:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ad9:	89 47 10             	mov    %eax,0x10(%edi)
	info->eip_fn_narg = 0;
f0103adc:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103ae3:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0103ae8:	0f 87 df 00 00 00    	ja     f0103bcd <debuginfo_eip+0x12b>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103aee:	a1 00 00 20 00       	mov    0x200000,%eax
f0103af3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f0103af6:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103afb:	8b 35 08 00 20 00    	mov    0x200008,%esi
f0103b01:	89 75 cc             	mov    %esi,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f0103b04:	8b 35 0c 00 20 00    	mov    0x20000c,%esi
f0103b0a:	89 75 d0             	mov    %esi,-0x30(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103b0d:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103b10:	39 4d cc             	cmp    %ecx,-0x34(%ebp)
f0103b13:	0f 83 56 01 00 00    	jae    f0103c6f <debuginfo_eip+0x1cd>
f0103b19:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0103b1d:	0f 85 53 01 00 00    	jne    f0103c76 <debuginfo_eip+0x1d4>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103b23:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103b2a:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0103b2d:	29 f0                	sub    %esi,%eax
f0103b2f:	c1 f8 02             	sar    $0x2,%eax
f0103b32:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103b38:	83 e8 01             	sub    $0x1,%eax
f0103b3b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103b3e:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103b41:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103b44:	ff 75 08             	pushl  0x8(%ebp)
f0103b47:	6a 64                	push   $0x64
f0103b49:	89 f0                	mov    %esi,%eax
f0103b4b:	e8 5d fe ff ff       	call   f01039ad <stab_binsearch>
	if (lfile == 0)
f0103b50:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103b53:	83 c4 08             	add    $0x8,%esp
f0103b56:	85 c0                	test   %eax,%eax
f0103b58:	0f 84 1f 01 00 00    	je     f0103c7d <debuginfo_eip+0x1db>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103b5e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103b61:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103b64:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103b67:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103b6a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103b6d:	ff 75 08             	pushl  0x8(%ebp)
f0103b70:	6a 24                	push   $0x24
f0103b72:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0103b75:	89 f0                	mov    %esi,%eax
f0103b77:	e8 31 fe ff ff       	call   f01039ad <stab_binsearch>

	if (lfun <= rfun) {
f0103b7c:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0103b7f:	83 c4 08             	add    $0x8,%esp
f0103b82:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f0103b85:	7f 6c                	jg     f0103bf3 <debuginfo_eip+0x151>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103b87:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103b8a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103b8d:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103b90:	8b 02                	mov    (%edx),%eax
f0103b92:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103b95:	2b 4d cc             	sub    -0x34(%ebp),%ecx
f0103b98:	39 c8                	cmp    %ecx,%eax
f0103b9a:	73 06                	jae    f0103ba2 <debuginfo_eip+0x100>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103b9c:	03 45 cc             	add    -0x34(%ebp),%eax
f0103b9f:	89 47 08             	mov    %eax,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103ba2:	8b 42 08             	mov    0x8(%edx),%eax
f0103ba5:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103ba8:	83 ec 08             	sub    $0x8,%esp
f0103bab:	6a 3a                	push   $0x3a
f0103bad:	ff 77 08             	pushl  0x8(%edi)
f0103bb0:	e8 72 09 00 00       	call   f0104527 <strfind>
f0103bb5:	2b 47 08             	sub    0x8(%edi),%eax
f0103bb8:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103bbb:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103bbe:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103bc1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103bc4:	8d 44 81 04          	lea    0x4(%ecx,%eax,4),%eax
f0103bc8:	83 c4 10             	add    $0x10,%esp
f0103bcb:	eb 37                	jmp    f0103c04 <debuginfo_eip+0x162>
		stabstr_end = __STABSTR_END__;
f0103bcd:	c7 c0 12 12 11 f0    	mov    $0xf0111212,%eax
f0103bd3:	89 45 d0             	mov    %eax,-0x30(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0103bd6:	c7 c0 35 e8 10 f0    	mov    $0xf010e835,%eax
f0103bdc:	89 45 cc             	mov    %eax,-0x34(%ebp)
		stab_end = __STAB_END__;
f0103bdf:	c7 c0 34 e8 10 f0    	mov    $0xf010e834,%eax
		stabs = __STAB_BEGIN__;
f0103be5:	c7 c1 3c 5f 10 f0    	mov    $0xf0105f3c,%ecx
f0103beb:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0103bee:	e9 1a ff ff ff       	jmp    f0103b0d <debuginfo_eip+0x6b>
		info->eip_fn_addr = addr;
f0103bf3:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bf6:	89 47 10             	mov    %eax,0x10(%edi)
		lline = lfile;
f0103bf9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103bfc:	eb aa                	jmp    f0103ba8 <debuginfo_eip+0x106>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103bfe:	83 ee 01             	sub    $0x1,%esi
f0103c01:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0103c04:	39 f3                	cmp    %esi,%ebx
f0103c06:	7f 2e                	jg     f0103c36 <debuginfo_eip+0x194>
	       && stabs[lline].n_type != N_SOL
f0103c08:	0f b6 10             	movzbl (%eax),%edx
f0103c0b:	80 fa 84             	cmp    $0x84,%dl
f0103c0e:	74 0b                	je     f0103c1b <debuginfo_eip+0x179>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103c10:	80 fa 64             	cmp    $0x64,%dl
f0103c13:	75 e9                	jne    f0103bfe <debuginfo_eip+0x15c>
f0103c15:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0103c19:	74 e3                	je     f0103bfe <debuginfo_eip+0x15c>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103c1b:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103c1e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103c21:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0103c24:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103c27:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0103c2a:	29 d8                	sub    %ebx,%eax
f0103c2c:	39 c2                	cmp    %eax,%edx
f0103c2e:	73 06                	jae    f0103c36 <debuginfo_eip+0x194>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103c30:	89 d8                	mov    %ebx,%eax
f0103c32:	01 d0                	add    %edx,%eax
f0103c34:	89 07                	mov    %eax,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103c36:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103c39:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103c3c:	ba 00 00 00 00       	mov    $0x0,%edx
	if (lfun < rfun)
f0103c41:	39 c8                	cmp    %ecx,%eax
f0103c43:	7d 44                	jge    f0103c89 <debuginfo_eip+0x1e7>
		for (lline = lfun + 1;
f0103c45:	8d 50 01             	lea    0x1(%eax),%edx
f0103c48:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103c4b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103c4e:	8d 44 83 10          	lea    0x10(%ebx,%eax,4),%eax
f0103c52:	eb 07                	jmp    f0103c5b <debuginfo_eip+0x1b9>
			info->eip_fn_narg++;
f0103c54:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f0103c58:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0103c5b:	39 d1                	cmp    %edx,%ecx
f0103c5d:	74 25                	je     f0103c84 <debuginfo_eip+0x1e2>
f0103c5f:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103c62:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0103c66:	74 ec                	je     f0103c54 <debuginfo_eip+0x1b2>
	return 0;
f0103c68:	ba 00 00 00 00       	mov    $0x0,%edx
f0103c6d:	eb 1a                	jmp    f0103c89 <debuginfo_eip+0x1e7>
		return -1;
f0103c6f:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0103c74:	eb 13                	jmp    f0103c89 <debuginfo_eip+0x1e7>
f0103c76:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0103c7b:	eb 0c                	jmp    f0103c89 <debuginfo_eip+0x1e7>
		return -1;
f0103c7d:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0103c82:	eb 05                	jmp    f0103c89 <debuginfo_eip+0x1e7>
	return 0;
f0103c84:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103c89:	89 d0                	mov    %edx,%eax
f0103c8b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103c8e:	5b                   	pop    %ebx
f0103c8f:	5e                   	pop    %esi
f0103c90:	5f                   	pop    %edi
f0103c91:	5d                   	pop    %ebp
f0103c92:	c3                   	ret    

f0103c93 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103c93:	55                   	push   %ebp
f0103c94:	89 e5                	mov    %esp,%ebp
f0103c96:	57                   	push   %edi
f0103c97:	56                   	push   %esi
f0103c98:	53                   	push   %ebx
f0103c99:	83 ec 2c             	sub    $0x2c,%esp
f0103c9c:	e8 cb f2 ff ff       	call   f0102f6c <__x86.get_pc_thunk.cx>
f0103ca1:	81 c1 7b 83 08 00    	add    $0x8837b,%ecx
f0103ca7:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103caa:	89 c7                	mov    %eax,%edi
f0103cac:	89 d6                	mov    %edx,%esi
f0103cae:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cb1:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103cb4:	89 d1                	mov    %edx,%ecx
f0103cb6:	89 c2                	mov    %eax,%edx
f0103cb8:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103cbb:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0103cbe:	8b 45 10             	mov    0x10(%ebp),%eax
f0103cc1:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103cc4:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103cc7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0103cce:	39 c2                	cmp    %eax,%edx
f0103cd0:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f0103cd3:	72 41                	jb     f0103d16 <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103cd5:	83 ec 0c             	sub    $0xc,%esp
f0103cd8:	ff 75 18             	pushl  0x18(%ebp)
f0103cdb:	83 eb 01             	sub    $0x1,%ebx
f0103cde:	53                   	push   %ebx
f0103cdf:	50                   	push   %eax
f0103ce0:	83 ec 08             	sub    $0x8,%esp
f0103ce3:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103ce6:	ff 75 e0             	pushl  -0x20(%ebp)
f0103ce9:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103cec:	ff 75 d0             	pushl  -0x30(%ebp)
f0103cef:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103cf2:	e8 59 0a 00 00       	call   f0104750 <__udivdi3>
f0103cf7:	83 c4 18             	add    $0x18,%esp
f0103cfa:	52                   	push   %edx
f0103cfb:	50                   	push   %eax
f0103cfc:	89 f2                	mov    %esi,%edx
f0103cfe:	89 f8                	mov    %edi,%eax
f0103d00:	e8 8e ff ff ff       	call   f0103c93 <printnum>
f0103d05:	83 c4 20             	add    $0x20,%esp
f0103d08:	eb 13                	jmp    f0103d1d <printnum+0x8a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103d0a:	83 ec 08             	sub    $0x8,%esp
f0103d0d:	56                   	push   %esi
f0103d0e:	ff 75 18             	pushl  0x18(%ebp)
f0103d11:	ff d7                	call   *%edi
f0103d13:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0103d16:	83 eb 01             	sub    $0x1,%ebx
f0103d19:	85 db                	test   %ebx,%ebx
f0103d1b:	7f ed                	jg     f0103d0a <printnum+0x77>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103d1d:	83 ec 08             	sub    $0x8,%esp
f0103d20:	56                   	push   %esi
f0103d21:	83 ec 04             	sub    $0x4,%esp
f0103d24:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103d27:	ff 75 e0             	pushl  -0x20(%ebp)
f0103d2a:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103d2d:	ff 75 d0             	pushl  -0x30(%ebp)
f0103d30:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103d33:	e8 28 0b 00 00       	call   f0104860 <__umoddi3>
f0103d38:	83 c4 14             	add    $0x14,%esp
f0103d3b:	0f be 84 03 2c 9d f7 	movsbl -0x862d4(%ebx,%eax,1),%eax
f0103d42:	ff 
f0103d43:	50                   	push   %eax
f0103d44:	ff d7                	call   *%edi
}
f0103d46:	83 c4 10             	add    $0x10,%esp
f0103d49:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103d4c:	5b                   	pop    %ebx
f0103d4d:	5e                   	pop    %esi
f0103d4e:	5f                   	pop    %edi
f0103d4f:	5d                   	pop    %ebp
f0103d50:	c3                   	ret    

f0103d51 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103d51:	f3 0f 1e fb          	endbr32 
f0103d55:	55                   	push   %ebp
f0103d56:	89 e5                	mov    %esp,%ebp
f0103d58:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103d5b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103d5f:	8b 10                	mov    (%eax),%edx
f0103d61:	3b 50 04             	cmp    0x4(%eax),%edx
f0103d64:	73 0a                	jae    f0103d70 <sprintputch+0x1f>
		*b->buf++ = ch;
f0103d66:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103d69:	89 08                	mov    %ecx,(%eax)
f0103d6b:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d6e:	88 02                	mov    %al,(%edx)
}
f0103d70:	5d                   	pop    %ebp
f0103d71:	c3                   	ret    

f0103d72 <printfmt>:
{
f0103d72:	f3 0f 1e fb          	endbr32 
f0103d76:	55                   	push   %ebp
f0103d77:	89 e5                	mov    %esp,%ebp
f0103d79:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0103d7c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103d7f:	50                   	push   %eax
f0103d80:	ff 75 10             	pushl  0x10(%ebp)
f0103d83:	ff 75 0c             	pushl  0xc(%ebp)
f0103d86:	ff 75 08             	pushl  0x8(%ebp)
f0103d89:	e8 05 00 00 00       	call   f0103d93 <vprintfmt>
}
f0103d8e:	83 c4 10             	add    $0x10,%esp
f0103d91:	c9                   	leave  
f0103d92:	c3                   	ret    

f0103d93 <vprintfmt>:
{
f0103d93:	f3 0f 1e fb          	endbr32 
f0103d97:	55                   	push   %ebp
f0103d98:	89 e5                	mov    %esp,%ebp
f0103d9a:	57                   	push   %edi
f0103d9b:	56                   	push   %esi
f0103d9c:	53                   	push   %ebx
f0103d9d:	83 ec 3c             	sub    $0x3c,%esp
f0103da0:	e8 82 c9 ff ff       	call   f0100727 <__x86.get_pc_thunk.ax>
f0103da5:	05 77 82 08 00       	add    $0x88277,%eax
f0103daa:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103dad:	8b 75 08             	mov    0x8(%ebp),%esi
f0103db0:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103db3:	8b 5d 10             	mov    0x10(%ebp),%ebx
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103db6:	8d 80 94 20 00 00    	lea    0x2094(%eax),%eax
f0103dbc:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0103dbf:	e9 95 03 00 00       	jmp    f0104159 <.L25+0x48>
		padc = ' ';
f0103dc4:	c6 45 cf 20          	movb   $0x20,-0x31(%ebp)
		altflag = 0;
f0103dc8:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
		precision = -1;
f0103dcf:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f0103dd6:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		lflag = 0;
f0103ddd:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103de2:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0103de5:	89 75 08             	mov    %esi,0x8(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103de8:	8d 43 01             	lea    0x1(%ebx),%eax
f0103deb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103dee:	0f b6 13             	movzbl (%ebx),%edx
f0103df1:	8d 42 dd             	lea    -0x23(%edx),%eax
f0103df4:	3c 55                	cmp    $0x55,%al
f0103df6:	0f 87 e9 03 00 00    	ja     f01041e5 <.L20>
f0103dfc:	0f b6 c0             	movzbl %al,%eax
f0103dff:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103e02:	89 ce                	mov    %ecx,%esi
f0103e04:	03 b4 81 b8 9d f7 ff 	add    -0x86248(%ecx,%eax,4),%esi
f0103e0b:	3e ff e6             	notrack jmp *%esi

f0103e0e <.L66>:
f0103e0e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '-';
f0103e11:	c6 45 cf 2d          	movb   $0x2d,-0x31(%ebp)
f0103e15:	eb d1                	jmp    f0103de8 <vprintfmt+0x55>

f0103e17 <.L32>:
		switch (ch = *(unsigned char *) fmt++) {
f0103e17:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103e1a:	c6 45 cf 30          	movb   $0x30,-0x31(%ebp)
f0103e1e:	eb c8                	jmp    f0103de8 <vprintfmt+0x55>

f0103e20 <.L31>:
f0103e20:	0f b6 d2             	movzbl %dl,%edx
f0103e23:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			for (precision = 0; ; ++fmt) {
f0103e26:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e2b:	8b 75 08             	mov    0x8(%ebp),%esi
				precision = precision * 10 + ch - '0';
f0103e2e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103e31:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103e35:	0f be 13             	movsbl (%ebx),%edx
				if (ch < '0' || ch > '9')
f0103e38:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0103e3b:	83 f9 09             	cmp    $0x9,%ecx
f0103e3e:	77 58                	ja     f0103e98 <.L36+0xf>
			for (precision = 0; ; ++fmt) {
f0103e40:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f0103e43:	eb e9                	jmp    f0103e2e <.L31+0xe>

f0103e45 <.L34>:
			precision = va_arg(ap, int);
f0103e45:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e48:	8b 00                	mov    (%eax),%eax
f0103e4a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103e4d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e50:	8d 40 04             	lea    0x4(%eax),%eax
f0103e53:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103e56:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if (width < 0)
f0103e59:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0103e5d:	79 89                	jns    f0103de8 <vprintfmt+0x55>
				width = precision, precision = -1;
f0103e5f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103e62:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103e65:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0103e6c:	e9 77 ff ff ff       	jmp    f0103de8 <vprintfmt+0x55>

f0103e71 <.L33>:
f0103e71:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103e74:	85 c0                	test   %eax,%eax
f0103e76:	ba 00 00 00 00       	mov    $0x0,%edx
f0103e7b:	0f 49 d0             	cmovns %eax,%edx
f0103e7e:	89 55 d0             	mov    %edx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103e81:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f0103e84:	e9 5f ff ff ff       	jmp    f0103de8 <vprintfmt+0x55>

f0103e89 <.L36>:
		switch (ch = *(unsigned char *) fmt++) {
f0103e89:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			altflag = 1;
f0103e8c:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
			goto reswitch;
f0103e93:	e9 50 ff ff ff       	jmp    f0103de8 <vprintfmt+0x55>
f0103e98:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103e9b:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e9e:	eb b9                	jmp    f0103e59 <.L34+0x14>

f0103ea0 <.L27>:
			lflag++;
f0103ea0:	83 45 c8 01          	addl   $0x1,-0x38(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103ea4:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f0103ea7:	e9 3c ff ff ff       	jmp    f0103de8 <vprintfmt+0x55>

f0103eac <.L30>:
f0103eac:	8b 75 08             	mov    0x8(%ebp),%esi
			putch(va_arg(ap, int), putdat);
f0103eaf:	8b 45 14             	mov    0x14(%ebp),%eax
f0103eb2:	8d 58 04             	lea    0x4(%eax),%ebx
f0103eb5:	83 ec 08             	sub    $0x8,%esp
f0103eb8:	57                   	push   %edi
f0103eb9:	ff 30                	pushl  (%eax)
f0103ebb:	ff d6                	call   *%esi
			break;
f0103ebd:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0103ec0:	89 5d 14             	mov    %ebx,0x14(%ebp)
			break;
f0103ec3:	e9 8e 02 00 00       	jmp    f0104156 <.L25+0x45>

f0103ec8 <.L28>:
f0103ec8:	8b 75 08             	mov    0x8(%ebp),%esi
			err = va_arg(ap, int);
f0103ecb:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ece:	8d 58 04             	lea    0x4(%eax),%ebx
f0103ed1:	8b 00                	mov    (%eax),%eax
f0103ed3:	99                   	cltd   
f0103ed4:	31 d0                	xor    %edx,%eax
f0103ed6:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103ed8:	83 f8 06             	cmp    $0x6,%eax
f0103edb:	7f 27                	jg     f0103f04 <.L28+0x3c>
f0103edd:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0103ee0:	8b 14 82             	mov    (%edx,%eax,4),%edx
f0103ee3:	85 d2                	test   %edx,%edx
f0103ee5:	74 1d                	je     f0103f04 <.L28+0x3c>
				printfmt(putch, putdat, "%s", p);
f0103ee7:	52                   	push   %edx
f0103ee8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103eeb:	8d 80 59 96 f7 ff    	lea    -0x869a7(%eax),%eax
f0103ef1:	50                   	push   %eax
f0103ef2:	57                   	push   %edi
f0103ef3:	56                   	push   %esi
f0103ef4:	e8 79 fe ff ff       	call   f0103d72 <printfmt>
f0103ef9:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103efc:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0103eff:	e9 52 02 00 00       	jmp    f0104156 <.L25+0x45>
				printfmt(putch, putdat, "error %d", err);
f0103f04:	50                   	push   %eax
f0103f05:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103f08:	8d 80 44 9d f7 ff    	lea    -0x862bc(%eax),%eax
f0103f0e:	50                   	push   %eax
f0103f0f:	57                   	push   %edi
f0103f10:	56                   	push   %esi
f0103f11:	e8 5c fe ff ff       	call   f0103d72 <printfmt>
f0103f16:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103f19:	89 5d 14             	mov    %ebx,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0103f1c:	e9 35 02 00 00       	jmp    f0104156 <.L25+0x45>

f0103f21 <.L24>:
f0103f21:	8b 75 08             	mov    0x8(%ebp),%esi
			if ((p = va_arg(ap, char *)) == NULL)
f0103f24:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f27:	83 c0 04             	add    $0x4,%eax
f0103f2a:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0103f2d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f30:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f0103f32:	85 d2                	test   %edx,%edx
f0103f34:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103f37:	8d 80 3d 9d f7 ff    	lea    -0x862c3(%eax),%eax
f0103f3d:	0f 45 c2             	cmovne %edx,%eax
f0103f40:	89 45 c8             	mov    %eax,-0x38(%ebp)
			if (width > 0 && padc != '-')
f0103f43:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0103f47:	7e 06                	jle    f0103f4f <.L24+0x2e>
f0103f49:	80 7d cf 2d          	cmpb   $0x2d,-0x31(%ebp)
f0103f4d:	75 0d                	jne    f0103f5c <.L24+0x3b>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103f4f:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0103f52:	89 c3                	mov    %eax,%ebx
f0103f54:	03 45 d0             	add    -0x30(%ebp),%eax
f0103f57:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103f5a:	eb 58                	jmp    f0103fb4 <.L24+0x93>
f0103f5c:	83 ec 08             	sub    $0x8,%esp
f0103f5f:	ff 75 d8             	pushl  -0x28(%ebp)
f0103f62:	ff 75 c8             	pushl  -0x38(%ebp)
f0103f65:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103f68:	e8 49 04 00 00       	call   f01043b6 <strnlen>
f0103f6d:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0103f70:	29 c2                	sub    %eax,%edx
f0103f72:	89 55 bc             	mov    %edx,-0x44(%ebp)
f0103f75:	83 c4 10             	add    $0x10,%esp
f0103f78:	89 d3                	mov    %edx,%ebx
					putch(padc, putdat);
f0103f7a:	0f be 45 cf          	movsbl -0x31(%ebp),%eax
f0103f7e:	89 45 d0             	mov    %eax,-0x30(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0103f81:	85 db                	test   %ebx,%ebx
f0103f83:	7e 11                	jle    f0103f96 <.L24+0x75>
					putch(padc, putdat);
f0103f85:	83 ec 08             	sub    $0x8,%esp
f0103f88:	57                   	push   %edi
f0103f89:	ff 75 d0             	pushl  -0x30(%ebp)
f0103f8c:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103f8e:	83 eb 01             	sub    $0x1,%ebx
f0103f91:	83 c4 10             	add    $0x10,%esp
f0103f94:	eb eb                	jmp    f0103f81 <.L24+0x60>
f0103f96:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103f99:	85 d2                	test   %edx,%edx
f0103f9b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103fa0:	0f 49 c2             	cmovns %edx,%eax
f0103fa3:	29 c2                	sub    %eax,%edx
f0103fa5:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0103fa8:	eb a5                	jmp    f0103f4f <.L24+0x2e>
					putch(ch, putdat);
f0103faa:	83 ec 08             	sub    $0x8,%esp
f0103fad:	57                   	push   %edi
f0103fae:	52                   	push   %edx
f0103faf:	ff d6                	call   *%esi
f0103fb1:	83 c4 10             	add    $0x10,%esp
f0103fb4:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103fb7:	29 d9                	sub    %ebx,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103fb9:	83 c3 01             	add    $0x1,%ebx
f0103fbc:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0103fc0:	0f be d0             	movsbl %al,%edx
f0103fc3:	85 d2                	test   %edx,%edx
f0103fc5:	74 4b                	je     f0104012 <.L24+0xf1>
f0103fc7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103fcb:	78 06                	js     f0103fd3 <.L24+0xb2>
f0103fcd:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f0103fd1:	78 1e                	js     f0103ff1 <.L24+0xd0>
				if (altflag && (ch < ' ' || ch > '~'))
f0103fd3:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0103fd7:	74 d1                	je     f0103faa <.L24+0x89>
f0103fd9:	0f be c0             	movsbl %al,%eax
f0103fdc:	83 e8 20             	sub    $0x20,%eax
f0103fdf:	83 f8 5e             	cmp    $0x5e,%eax
f0103fe2:	76 c6                	jbe    f0103faa <.L24+0x89>
					putch('?', putdat);
f0103fe4:	83 ec 08             	sub    $0x8,%esp
f0103fe7:	57                   	push   %edi
f0103fe8:	6a 3f                	push   $0x3f
f0103fea:	ff d6                	call   *%esi
f0103fec:	83 c4 10             	add    $0x10,%esp
f0103fef:	eb c3                	jmp    f0103fb4 <.L24+0x93>
f0103ff1:	89 cb                	mov    %ecx,%ebx
f0103ff3:	eb 0e                	jmp    f0104003 <.L24+0xe2>
				putch(' ', putdat);
f0103ff5:	83 ec 08             	sub    $0x8,%esp
f0103ff8:	57                   	push   %edi
f0103ff9:	6a 20                	push   $0x20
f0103ffb:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0103ffd:	83 eb 01             	sub    $0x1,%ebx
f0104000:	83 c4 10             	add    $0x10,%esp
f0104003:	85 db                	test   %ebx,%ebx
f0104005:	7f ee                	jg     f0103ff5 <.L24+0xd4>
			if ((p = va_arg(ap, char *)) == NULL)
f0104007:	8b 45 c0             	mov    -0x40(%ebp),%eax
f010400a:	89 45 14             	mov    %eax,0x14(%ebp)
f010400d:	e9 44 01 00 00       	jmp    f0104156 <.L25+0x45>
f0104012:	89 cb                	mov    %ecx,%ebx
f0104014:	eb ed                	jmp    f0104003 <.L24+0xe2>

f0104016 <.L29>:
f0104016:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0104019:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f010401c:	83 f9 01             	cmp    $0x1,%ecx
f010401f:	7f 1b                	jg     f010403c <.L29+0x26>
	else if (lflag)
f0104021:	85 c9                	test   %ecx,%ecx
f0104023:	74 63                	je     f0104088 <.L29+0x72>
		return va_arg(*ap, long);
f0104025:	8b 45 14             	mov    0x14(%ebp),%eax
f0104028:	8b 00                	mov    (%eax),%eax
f010402a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010402d:	99                   	cltd   
f010402e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104031:	8b 45 14             	mov    0x14(%ebp),%eax
f0104034:	8d 40 04             	lea    0x4(%eax),%eax
f0104037:	89 45 14             	mov    %eax,0x14(%ebp)
f010403a:	eb 17                	jmp    f0104053 <.L29+0x3d>
		return va_arg(*ap, long long);
f010403c:	8b 45 14             	mov    0x14(%ebp),%eax
f010403f:	8b 50 04             	mov    0x4(%eax),%edx
f0104042:	8b 00                	mov    (%eax),%eax
f0104044:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104047:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010404a:	8b 45 14             	mov    0x14(%ebp),%eax
f010404d:	8d 40 08             	lea    0x8(%eax),%eax
f0104050:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0104053:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104056:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0104059:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f010405e:	85 c9                	test   %ecx,%ecx
f0104060:	0f 89 d6 00 00 00    	jns    f010413c <.L25+0x2b>
				putch('-', putdat);
f0104066:	83 ec 08             	sub    $0x8,%esp
f0104069:	57                   	push   %edi
f010406a:	6a 2d                	push   $0x2d
f010406c:	ff d6                	call   *%esi
				num = -(long long) num;
f010406e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104071:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104074:	f7 da                	neg    %edx
f0104076:	83 d1 00             	adc    $0x0,%ecx
f0104079:	f7 d9                	neg    %ecx
f010407b:	83 c4 10             	add    $0x10,%esp
			base = 10;
f010407e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104083:	e9 b4 00 00 00       	jmp    f010413c <.L25+0x2b>
		return va_arg(*ap, int);
f0104088:	8b 45 14             	mov    0x14(%ebp),%eax
f010408b:	8b 00                	mov    (%eax),%eax
f010408d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104090:	99                   	cltd   
f0104091:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104094:	8b 45 14             	mov    0x14(%ebp),%eax
f0104097:	8d 40 04             	lea    0x4(%eax),%eax
f010409a:	89 45 14             	mov    %eax,0x14(%ebp)
f010409d:	eb b4                	jmp    f0104053 <.L29+0x3d>

f010409f <.L23>:
f010409f:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01040a2:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f01040a5:	83 f9 01             	cmp    $0x1,%ecx
f01040a8:	7f 1b                	jg     f01040c5 <.L23+0x26>
	else if (lflag)
f01040aa:	85 c9                	test   %ecx,%ecx
f01040ac:	74 2c                	je     f01040da <.L23+0x3b>
		return va_arg(*ap, unsigned long);
f01040ae:	8b 45 14             	mov    0x14(%ebp),%eax
f01040b1:	8b 10                	mov    (%eax),%edx
f01040b3:	b9 00 00 00 00       	mov    $0x0,%ecx
f01040b8:	8d 40 04             	lea    0x4(%eax),%eax
f01040bb:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01040be:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long);
f01040c3:	eb 77                	jmp    f010413c <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f01040c5:	8b 45 14             	mov    0x14(%ebp),%eax
f01040c8:	8b 10                	mov    (%eax),%edx
f01040ca:	8b 48 04             	mov    0x4(%eax),%ecx
f01040cd:	8d 40 08             	lea    0x8(%eax),%eax
f01040d0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01040d3:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long long);
f01040d8:	eb 62                	jmp    f010413c <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f01040da:	8b 45 14             	mov    0x14(%ebp),%eax
f01040dd:	8b 10                	mov    (%eax),%edx
f01040df:	b9 00 00 00 00       	mov    $0x0,%ecx
f01040e4:	8d 40 04             	lea    0x4(%eax),%eax
f01040e7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01040ea:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned int);
f01040ef:	eb 4b                	jmp    f010413c <.L25+0x2b>

f01040f1 <.L26>:
f01040f1:	8b 75 08             	mov    0x8(%ebp),%esi
			putch('X', putdat);
f01040f4:	83 ec 08             	sub    $0x8,%esp
f01040f7:	57                   	push   %edi
f01040f8:	6a 58                	push   $0x58
f01040fa:	ff d6                	call   *%esi
			putch('X', putdat);
f01040fc:	83 c4 08             	add    $0x8,%esp
f01040ff:	57                   	push   %edi
f0104100:	6a 58                	push   $0x58
f0104102:	ff d6                	call   *%esi
			putch('X', putdat);
f0104104:	83 c4 08             	add    $0x8,%esp
f0104107:	57                   	push   %edi
f0104108:	6a 58                	push   $0x58
f010410a:	ff d6                	call   *%esi
			break;
f010410c:	83 c4 10             	add    $0x10,%esp
f010410f:	eb 45                	jmp    f0104156 <.L25+0x45>

f0104111 <.L25>:
f0104111:	8b 75 08             	mov    0x8(%ebp),%esi
			putch('0', putdat);
f0104114:	83 ec 08             	sub    $0x8,%esp
f0104117:	57                   	push   %edi
f0104118:	6a 30                	push   $0x30
f010411a:	ff d6                	call   *%esi
			putch('x', putdat);
f010411c:	83 c4 08             	add    $0x8,%esp
f010411f:	57                   	push   %edi
f0104120:	6a 78                	push   $0x78
f0104122:	ff d6                	call   *%esi
			num = (unsigned long long)
f0104124:	8b 45 14             	mov    0x14(%ebp),%eax
f0104127:	8b 10                	mov    (%eax),%edx
f0104129:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010412e:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0104131:	8d 40 04             	lea    0x4(%eax),%eax
f0104134:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104137:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f010413c:	83 ec 0c             	sub    $0xc,%esp
f010413f:	0f be 5d cf          	movsbl -0x31(%ebp),%ebx
f0104143:	53                   	push   %ebx
f0104144:	ff 75 d0             	pushl  -0x30(%ebp)
f0104147:	50                   	push   %eax
f0104148:	51                   	push   %ecx
f0104149:	52                   	push   %edx
f010414a:	89 fa                	mov    %edi,%edx
f010414c:	89 f0                	mov    %esi,%eax
f010414e:	e8 40 fb ff ff       	call   f0103c93 <printnum>
			break;
f0104153:	83 c4 20             	add    $0x20,%esp
			if ((p = va_arg(ap, char *)) == NULL)
f0104156:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104159:	83 c3 01             	add    $0x1,%ebx
f010415c:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0104160:	83 f8 25             	cmp    $0x25,%eax
f0104163:	0f 84 5b fc ff ff    	je     f0103dc4 <vprintfmt+0x31>
			if (ch == '\0')
f0104169:	85 c0                	test   %eax,%eax
f010416b:	0f 84 97 00 00 00    	je     f0104208 <.L20+0x23>
			putch(ch, putdat);
f0104171:	83 ec 08             	sub    $0x8,%esp
f0104174:	57                   	push   %edi
f0104175:	50                   	push   %eax
f0104176:	ff d6                	call   *%esi
f0104178:	83 c4 10             	add    $0x10,%esp
f010417b:	eb dc                	jmp    f0104159 <.L25+0x48>

f010417d <.L21>:
f010417d:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0104180:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f0104183:	83 f9 01             	cmp    $0x1,%ecx
f0104186:	7f 1b                	jg     f01041a3 <.L21+0x26>
	else if (lflag)
f0104188:	85 c9                	test   %ecx,%ecx
f010418a:	74 2c                	je     f01041b8 <.L21+0x3b>
		return va_arg(*ap, unsigned long);
f010418c:	8b 45 14             	mov    0x14(%ebp),%eax
f010418f:	8b 10                	mov    (%eax),%edx
f0104191:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104196:	8d 40 04             	lea    0x4(%eax),%eax
f0104199:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010419c:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long);
f01041a1:	eb 99                	jmp    f010413c <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f01041a3:	8b 45 14             	mov    0x14(%ebp),%eax
f01041a6:	8b 10                	mov    (%eax),%edx
f01041a8:	8b 48 04             	mov    0x4(%eax),%ecx
f01041ab:	8d 40 08             	lea    0x8(%eax),%eax
f01041ae:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01041b1:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long long);
f01041b6:	eb 84                	jmp    f010413c <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f01041b8:	8b 45 14             	mov    0x14(%ebp),%eax
f01041bb:	8b 10                	mov    (%eax),%edx
f01041bd:	b9 00 00 00 00       	mov    $0x0,%ecx
f01041c2:	8d 40 04             	lea    0x4(%eax),%eax
f01041c5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01041c8:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned int);
f01041cd:	e9 6a ff ff ff       	jmp    f010413c <.L25+0x2b>

f01041d2 <.L35>:
f01041d2:	8b 75 08             	mov    0x8(%ebp),%esi
			putch(ch, putdat);
f01041d5:	83 ec 08             	sub    $0x8,%esp
f01041d8:	57                   	push   %edi
f01041d9:	6a 25                	push   $0x25
f01041db:	ff d6                	call   *%esi
			break;
f01041dd:	83 c4 10             	add    $0x10,%esp
f01041e0:	e9 71 ff ff ff       	jmp    f0104156 <.L25+0x45>

f01041e5 <.L20>:
f01041e5:	8b 75 08             	mov    0x8(%ebp),%esi
			putch('%', putdat);
f01041e8:	83 ec 08             	sub    $0x8,%esp
f01041eb:	57                   	push   %edi
f01041ec:	6a 25                	push   $0x25
f01041ee:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01041f0:	83 c4 10             	add    $0x10,%esp
f01041f3:	89 d8                	mov    %ebx,%eax
f01041f5:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01041f9:	74 05                	je     f0104200 <.L20+0x1b>
f01041fb:	83 e8 01             	sub    $0x1,%eax
f01041fe:	eb f5                	jmp    f01041f5 <.L20+0x10>
f0104200:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104203:	e9 4e ff ff ff       	jmp    f0104156 <.L25+0x45>
}
f0104208:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010420b:	5b                   	pop    %ebx
f010420c:	5e                   	pop    %esi
f010420d:	5f                   	pop    %edi
f010420e:	5d                   	pop    %ebp
f010420f:	c3                   	ret    

f0104210 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104210:	f3 0f 1e fb          	endbr32 
f0104214:	55                   	push   %ebp
f0104215:	89 e5                	mov    %esp,%ebp
f0104217:	53                   	push   %ebx
f0104218:	83 ec 14             	sub    $0x14,%esp
f010421b:	e8 53 bf ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0104220:	81 c3 fc 7d 08 00    	add    $0x87dfc,%ebx
f0104226:	8b 45 08             	mov    0x8(%ebp),%eax
f0104229:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010422c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010422f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104233:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104236:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010423d:	85 c0                	test   %eax,%eax
f010423f:	74 2b                	je     f010426c <vsnprintf+0x5c>
f0104241:	85 d2                	test   %edx,%edx
f0104243:	7e 27                	jle    f010426c <vsnprintf+0x5c>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104245:	ff 75 14             	pushl  0x14(%ebp)
f0104248:	ff 75 10             	pushl  0x10(%ebp)
f010424b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010424e:	50                   	push   %eax
f010424f:	8d 83 35 7d f7 ff    	lea    -0x882cb(%ebx),%eax
f0104255:	50                   	push   %eax
f0104256:	e8 38 fb ff ff       	call   f0103d93 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010425b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010425e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104261:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104264:	83 c4 10             	add    $0x10,%esp
}
f0104267:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010426a:	c9                   	leave  
f010426b:	c3                   	ret    
		return -E_INVAL;
f010426c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104271:	eb f4                	jmp    f0104267 <vsnprintf+0x57>

f0104273 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104273:	f3 0f 1e fb          	endbr32 
f0104277:	55                   	push   %ebp
f0104278:	89 e5                	mov    %esp,%ebp
f010427a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010427d:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104280:	50                   	push   %eax
f0104281:	ff 75 10             	pushl  0x10(%ebp)
f0104284:	ff 75 0c             	pushl  0xc(%ebp)
f0104287:	ff 75 08             	pushl  0x8(%ebp)
f010428a:	e8 81 ff ff ff       	call   f0104210 <vsnprintf>
	va_end(ap);

	return rc;
}
f010428f:	c9                   	leave  
f0104290:	c3                   	ret    

f0104291 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104291:	f3 0f 1e fb          	endbr32 
f0104295:	55                   	push   %ebp
f0104296:	89 e5                	mov    %esp,%ebp
f0104298:	57                   	push   %edi
f0104299:	56                   	push   %esi
f010429a:	53                   	push   %ebx
f010429b:	83 ec 1c             	sub    $0x1c,%esp
f010429e:	e8 d0 be ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01042a3:	81 c3 79 7d 08 00    	add    $0x87d79,%ebx
f01042a9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01042ac:	85 c0                	test   %eax,%eax
f01042ae:	74 13                	je     f01042c3 <readline+0x32>
		cprintf("%s", prompt);
f01042b0:	83 ec 08             	sub    $0x8,%esp
f01042b3:	50                   	push   %eax
f01042b4:	8d 83 59 96 f7 ff    	lea    -0x869a7(%ebx),%eax
f01042ba:	50                   	push   %eax
f01042bb:	e8 17 f2 ff ff       	call   f01034d7 <cprintf>
f01042c0:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01042c3:	83 ec 0c             	sub    $0xc,%esp
f01042c6:	6a 00                	push   $0x0
f01042c8:	e8 50 c4 ff ff       	call   f010071d <iscons>
f01042cd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01042d0:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01042d3:	bf 00 00 00 00       	mov    $0x0,%edi
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
			if (echoing)
				cputchar(c);
			buf[i++] = c;
f01042d8:	8d 83 c4 2b 00 00    	lea    0x2bc4(%ebx),%eax
f01042de:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01042e1:	eb 51                	jmp    f0104334 <readline+0xa3>
			cprintf("read error: %e\n", c);
f01042e3:	83 ec 08             	sub    $0x8,%esp
f01042e6:	50                   	push   %eax
f01042e7:	8d 83 10 9f f7 ff    	lea    -0x860f0(%ebx),%eax
f01042ed:	50                   	push   %eax
f01042ee:	e8 e4 f1 ff ff       	call   f01034d7 <cprintf>
			return NULL;
f01042f3:	83 c4 10             	add    $0x10,%esp
f01042f6:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01042fb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01042fe:	5b                   	pop    %ebx
f01042ff:	5e                   	pop    %esi
f0104300:	5f                   	pop    %edi
f0104301:	5d                   	pop    %ebp
f0104302:	c3                   	ret    
			if (echoing)
f0104303:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104307:	75 05                	jne    f010430e <readline+0x7d>
			i--;
f0104309:	83 ef 01             	sub    $0x1,%edi
f010430c:	eb 26                	jmp    f0104334 <readline+0xa3>
				cputchar('\b');
f010430e:	83 ec 0c             	sub    $0xc,%esp
f0104311:	6a 08                	push   $0x8
f0104313:	e8 dc c3 ff ff       	call   f01006f4 <cputchar>
f0104318:	83 c4 10             	add    $0x10,%esp
f010431b:	eb ec                	jmp    f0104309 <readline+0x78>
				cputchar(c);
f010431d:	83 ec 0c             	sub    $0xc,%esp
f0104320:	56                   	push   %esi
f0104321:	e8 ce c3 ff ff       	call   f01006f4 <cputchar>
f0104326:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104329:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010432c:	89 f0                	mov    %esi,%eax
f010432e:	88 04 39             	mov    %al,(%ecx,%edi,1)
f0104331:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0104334:	e8 cf c3 ff ff       	call   f0100708 <getchar>
f0104339:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f010433b:	85 c0                	test   %eax,%eax
f010433d:	78 a4                	js     f01042e3 <readline+0x52>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010433f:	83 f8 08             	cmp    $0x8,%eax
f0104342:	0f 94 c2             	sete   %dl
f0104345:	83 f8 7f             	cmp    $0x7f,%eax
f0104348:	0f 94 c0             	sete   %al
f010434b:	08 c2                	or     %al,%dl
f010434d:	74 04                	je     f0104353 <readline+0xc2>
f010434f:	85 ff                	test   %edi,%edi
f0104351:	7f b0                	jg     f0104303 <readline+0x72>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104353:	83 fe 1f             	cmp    $0x1f,%esi
f0104356:	7e 10                	jle    f0104368 <readline+0xd7>
f0104358:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f010435e:	7f 08                	jg     f0104368 <readline+0xd7>
			if (echoing)
f0104360:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104364:	74 c3                	je     f0104329 <readline+0x98>
f0104366:	eb b5                	jmp    f010431d <readline+0x8c>
		} else if (c == '\n' || c == '\r') {
f0104368:	83 fe 0a             	cmp    $0xa,%esi
f010436b:	74 05                	je     f0104372 <readline+0xe1>
f010436d:	83 fe 0d             	cmp    $0xd,%esi
f0104370:	75 c2                	jne    f0104334 <readline+0xa3>
			if (echoing)
f0104372:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104376:	75 13                	jne    f010438b <readline+0xfa>
			buf[i] = 0;
f0104378:	c6 84 3b c4 2b 00 00 	movb   $0x0,0x2bc4(%ebx,%edi,1)
f010437f:	00 
			return buf;
f0104380:	8d 83 c4 2b 00 00    	lea    0x2bc4(%ebx),%eax
f0104386:	e9 70 ff ff ff       	jmp    f01042fb <readline+0x6a>
				cputchar('\n');
f010438b:	83 ec 0c             	sub    $0xc,%esp
f010438e:	6a 0a                	push   $0xa
f0104390:	e8 5f c3 ff ff       	call   f01006f4 <cputchar>
f0104395:	83 c4 10             	add    $0x10,%esp
f0104398:	eb de                	jmp    f0104378 <readline+0xe7>

f010439a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010439a:	f3 0f 1e fb          	endbr32 
f010439e:	55                   	push   %ebp
f010439f:	89 e5                	mov    %esp,%ebp
f01043a1:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01043a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01043a9:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01043ad:	74 05                	je     f01043b4 <strlen+0x1a>
		n++;
f01043af:	83 c0 01             	add    $0x1,%eax
f01043b2:	eb f5                	jmp    f01043a9 <strlen+0xf>
	return n;
}
f01043b4:	5d                   	pop    %ebp
f01043b5:	c3                   	ret    

f01043b6 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01043b6:	f3 0f 1e fb          	endbr32 
f01043ba:	55                   	push   %ebp
f01043bb:	89 e5                	mov    %esp,%ebp
f01043bd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01043c0:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01043c3:	b8 00 00 00 00       	mov    $0x0,%eax
f01043c8:	39 d0                	cmp    %edx,%eax
f01043ca:	74 0d                	je     f01043d9 <strnlen+0x23>
f01043cc:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01043d0:	74 05                	je     f01043d7 <strnlen+0x21>
		n++;
f01043d2:	83 c0 01             	add    $0x1,%eax
f01043d5:	eb f1                	jmp    f01043c8 <strnlen+0x12>
f01043d7:	89 c2                	mov    %eax,%edx
	return n;
}
f01043d9:	89 d0                	mov    %edx,%eax
f01043db:	5d                   	pop    %ebp
f01043dc:	c3                   	ret    

f01043dd <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01043dd:	f3 0f 1e fb          	endbr32 
f01043e1:	55                   	push   %ebp
f01043e2:	89 e5                	mov    %esp,%ebp
f01043e4:	53                   	push   %ebx
f01043e5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01043e8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01043eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01043f0:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f01043f4:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f01043f7:	83 c0 01             	add    $0x1,%eax
f01043fa:	84 d2                	test   %dl,%dl
f01043fc:	75 f2                	jne    f01043f0 <strcpy+0x13>
		/* do nothing */;
	return ret;
}
f01043fe:	89 c8                	mov    %ecx,%eax
f0104400:	5b                   	pop    %ebx
f0104401:	5d                   	pop    %ebp
f0104402:	c3                   	ret    

f0104403 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104403:	f3 0f 1e fb          	endbr32 
f0104407:	55                   	push   %ebp
f0104408:	89 e5                	mov    %esp,%ebp
f010440a:	53                   	push   %ebx
f010440b:	83 ec 10             	sub    $0x10,%esp
f010440e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104411:	53                   	push   %ebx
f0104412:	e8 83 ff ff ff       	call   f010439a <strlen>
f0104417:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f010441a:	ff 75 0c             	pushl  0xc(%ebp)
f010441d:	01 d8                	add    %ebx,%eax
f010441f:	50                   	push   %eax
f0104420:	e8 b8 ff ff ff       	call   f01043dd <strcpy>
	return dst;
}
f0104425:	89 d8                	mov    %ebx,%eax
f0104427:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010442a:	c9                   	leave  
f010442b:	c3                   	ret    

f010442c <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010442c:	f3 0f 1e fb          	endbr32 
f0104430:	55                   	push   %ebp
f0104431:	89 e5                	mov    %esp,%ebp
f0104433:	56                   	push   %esi
f0104434:	53                   	push   %ebx
f0104435:	8b 75 08             	mov    0x8(%ebp),%esi
f0104438:	8b 55 0c             	mov    0xc(%ebp),%edx
f010443b:	89 f3                	mov    %esi,%ebx
f010443d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104440:	89 f0                	mov    %esi,%eax
f0104442:	39 d8                	cmp    %ebx,%eax
f0104444:	74 11                	je     f0104457 <strncpy+0x2b>
		*dst++ = *src;
f0104446:	83 c0 01             	add    $0x1,%eax
f0104449:	0f b6 0a             	movzbl (%edx),%ecx
f010444c:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010444f:	80 f9 01             	cmp    $0x1,%cl
f0104452:	83 da ff             	sbb    $0xffffffff,%edx
f0104455:	eb eb                	jmp    f0104442 <strncpy+0x16>
	}
	return ret;
}
f0104457:	89 f0                	mov    %esi,%eax
f0104459:	5b                   	pop    %ebx
f010445a:	5e                   	pop    %esi
f010445b:	5d                   	pop    %ebp
f010445c:	c3                   	ret    

f010445d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010445d:	f3 0f 1e fb          	endbr32 
f0104461:	55                   	push   %ebp
f0104462:	89 e5                	mov    %esp,%ebp
f0104464:	56                   	push   %esi
f0104465:	53                   	push   %ebx
f0104466:	8b 75 08             	mov    0x8(%ebp),%esi
f0104469:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010446c:	8b 55 10             	mov    0x10(%ebp),%edx
f010446f:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104471:	85 d2                	test   %edx,%edx
f0104473:	74 21                	je     f0104496 <strlcpy+0x39>
f0104475:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104479:	89 f2                	mov    %esi,%edx
		while (--size > 0 && *src != '\0')
f010447b:	39 c2                	cmp    %eax,%edx
f010447d:	74 14                	je     f0104493 <strlcpy+0x36>
f010447f:	0f b6 19             	movzbl (%ecx),%ebx
f0104482:	84 db                	test   %bl,%bl
f0104484:	74 0b                	je     f0104491 <strlcpy+0x34>
			*dst++ = *src++;
f0104486:	83 c1 01             	add    $0x1,%ecx
f0104489:	83 c2 01             	add    $0x1,%edx
f010448c:	88 5a ff             	mov    %bl,-0x1(%edx)
f010448f:	eb ea                	jmp    f010447b <strlcpy+0x1e>
f0104491:	89 d0                	mov    %edx,%eax
		*dst = '\0';
f0104493:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104496:	29 f0                	sub    %esi,%eax
}
f0104498:	5b                   	pop    %ebx
f0104499:	5e                   	pop    %esi
f010449a:	5d                   	pop    %ebp
f010449b:	c3                   	ret    

f010449c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010449c:	f3 0f 1e fb          	endbr32 
f01044a0:	55                   	push   %ebp
f01044a1:	89 e5                	mov    %esp,%ebp
f01044a3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01044a6:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01044a9:	0f b6 01             	movzbl (%ecx),%eax
f01044ac:	84 c0                	test   %al,%al
f01044ae:	74 0c                	je     f01044bc <strcmp+0x20>
f01044b0:	3a 02                	cmp    (%edx),%al
f01044b2:	75 08                	jne    f01044bc <strcmp+0x20>
		p++, q++;
f01044b4:	83 c1 01             	add    $0x1,%ecx
f01044b7:	83 c2 01             	add    $0x1,%edx
f01044ba:	eb ed                	jmp    f01044a9 <strcmp+0xd>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01044bc:	0f b6 c0             	movzbl %al,%eax
f01044bf:	0f b6 12             	movzbl (%edx),%edx
f01044c2:	29 d0                	sub    %edx,%eax
}
f01044c4:	5d                   	pop    %ebp
f01044c5:	c3                   	ret    

f01044c6 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01044c6:	f3 0f 1e fb          	endbr32 
f01044ca:	55                   	push   %ebp
f01044cb:	89 e5                	mov    %esp,%ebp
f01044cd:	53                   	push   %ebx
f01044ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01044d1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01044d4:	89 c3                	mov    %eax,%ebx
f01044d6:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01044d9:	eb 06                	jmp    f01044e1 <strncmp+0x1b>
		n--, p++, q++;
f01044db:	83 c0 01             	add    $0x1,%eax
f01044de:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01044e1:	39 d8                	cmp    %ebx,%eax
f01044e3:	74 16                	je     f01044fb <strncmp+0x35>
f01044e5:	0f b6 08             	movzbl (%eax),%ecx
f01044e8:	84 c9                	test   %cl,%cl
f01044ea:	74 04                	je     f01044f0 <strncmp+0x2a>
f01044ec:	3a 0a                	cmp    (%edx),%cl
f01044ee:	74 eb                	je     f01044db <strncmp+0x15>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01044f0:	0f b6 00             	movzbl (%eax),%eax
f01044f3:	0f b6 12             	movzbl (%edx),%edx
f01044f6:	29 d0                	sub    %edx,%eax
}
f01044f8:	5b                   	pop    %ebx
f01044f9:	5d                   	pop    %ebp
f01044fa:	c3                   	ret    
		return 0;
f01044fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0104500:	eb f6                	jmp    f01044f8 <strncmp+0x32>

f0104502 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104502:	f3 0f 1e fb          	endbr32 
f0104506:	55                   	push   %ebp
f0104507:	89 e5                	mov    %esp,%ebp
f0104509:	8b 45 08             	mov    0x8(%ebp),%eax
f010450c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104510:	0f b6 10             	movzbl (%eax),%edx
f0104513:	84 d2                	test   %dl,%dl
f0104515:	74 09                	je     f0104520 <strchr+0x1e>
		if (*s == c)
f0104517:	38 ca                	cmp    %cl,%dl
f0104519:	74 0a                	je     f0104525 <strchr+0x23>
	for (; *s; s++)
f010451b:	83 c0 01             	add    $0x1,%eax
f010451e:	eb f0                	jmp    f0104510 <strchr+0xe>
			return (char *) s;
	return 0;
f0104520:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104525:	5d                   	pop    %ebp
f0104526:	c3                   	ret    

f0104527 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104527:	f3 0f 1e fb          	endbr32 
f010452b:	55                   	push   %ebp
f010452c:	89 e5                	mov    %esp,%ebp
f010452e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104531:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104535:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104538:	38 ca                	cmp    %cl,%dl
f010453a:	74 09                	je     f0104545 <strfind+0x1e>
f010453c:	84 d2                	test   %dl,%dl
f010453e:	74 05                	je     f0104545 <strfind+0x1e>
	for (; *s; s++)
f0104540:	83 c0 01             	add    $0x1,%eax
f0104543:	eb f0                	jmp    f0104535 <strfind+0xe>
			break;
	return (char *) s;
}
f0104545:	5d                   	pop    %ebp
f0104546:	c3                   	ret    

f0104547 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104547:	f3 0f 1e fb          	endbr32 
f010454b:	55                   	push   %ebp
f010454c:	89 e5                	mov    %esp,%ebp
f010454e:	57                   	push   %edi
f010454f:	56                   	push   %esi
f0104550:	53                   	push   %ebx
f0104551:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104554:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104557:	85 c9                	test   %ecx,%ecx
f0104559:	74 31                	je     f010458c <memset+0x45>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010455b:	89 f8                	mov    %edi,%eax
f010455d:	09 c8                	or     %ecx,%eax
f010455f:	a8 03                	test   $0x3,%al
f0104561:	75 23                	jne    f0104586 <memset+0x3f>
		c &= 0xFF;
f0104563:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104567:	89 d3                	mov    %edx,%ebx
f0104569:	c1 e3 08             	shl    $0x8,%ebx
f010456c:	89 d0                	mov    %edx,%eax
f010456e:	c1 e0 18             	shl    $0x18,%eax
f0104571:	89 d6                	mov    %edx,%esi
f0104573:	c1 e6 10             	shl    $0x10,%esi
f0104576:	09 f0                	or     %esi,%eax
f0104578:	09 c2                	or     %eax,%edx
f010457a:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010457c:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f010457f:	89 d0                	mov    %edx,%eax
f0104581:	fc                   	cld    
f0104582:	f3 ab                	rep stos %eax,%es:(%edi)
f0104584:	eb 06                	jmp    f010458c <memset+0x45>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104586:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104589:	fc                   	cld    
f010458a:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010458c:	89 f8                	mov    %edi,%eax
f010458e:	5b                   	pop    %ebx
f010458f:	5e                   	pop    %esi
f0104590:	5f                   	pop    %edi
f0104591:	5d                   	pop    %ebp
f0104592:	c3                   	ret    

f0104593 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104593:	f3 0f 1e fb          	endbr32 
f0104597:	55                   	push   %ebp
f0104598:	89 e5                	mov    %esp,%ebp
f010459a:	57                   	push   %edi
f010459b:	56                   	push   %esi
f010459c:	8b 45 08             	mov    0x8(%ebp),%eax
f010459f:	8b 75 0c             	mov    0xc(%ebp),%esi
f01045a2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01045a5:	39 c6                	cmp    %eax,%esi
f01045a7:	73 32                	jae    f01045db <memmove+0x48>
f01045a9:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01045ac:	39 c2                	cmp    %eax,%edx
f01045ae:	76 2b                	jbe    f01045db <memmove+0x48>
		s += n;
		d += n;
f01045b0:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01045b3:	89 fe                	mov    %edi,%esi
f01045b5:	09 ce                	or     %ecx,%esi
f01045b7:	09 d6                	or     %edx,%esi
f01045b9:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01045bf:	75 0e                	jne    f01045cf <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01045c1:	83 ef 04             	sub    $0x4,%edi
f01045c4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01045c7:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01045ca:	fd                   	std    
f01045cb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01045cd:	eb 09                	jmp    f01045d8 <memmove+0x45>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01045cf:	83 ef 01             	sub    $0x1,%edi
f01045d2:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01045d5:	fd                   	std    
f01045d6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01045d8:	fc                   	cld    
f01045d9:	eb 1a                	jmp    f01045f5 <memmove+0x62>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01045db:	89 c2                	mov    %eax,%edx
f01045dd:	09 ca                	or     %ecx,%edx
f01045df:	09 f2                	or     %esi,%edx
f01045e1:	f6 c2 03             	test   $0x3,%dl
f01045e4:	75 0a                	jne    f01045f0 <memmove+0x5d>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01045e6:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01045e9:	89 c7                	mov    %eax,%edi
f01045eb:	fc                   	cld    
f01045ec:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01045ee:	eb 05                	jmp    f01045f5 <memmove+0x62>
		else
			asm volatile("cld; rep movsb\n"
f01045f0:	89 c7                	mov    %eax,%edi
f01045f2:	fc                   	cld    
f01045f3:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01045f5:	5e                   	pop    %esi
f01045f6:	5f                   	pop    %edi
f01045f7:	5d                   	pop    %ebp
f01045f8:	c3                   	ret    

f01045f9 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01045f9:	f3 0f 1e fb          	endbr32 
f01045fd:	55                   	push   %ebp
f01045fe:	89 e5                	mov    %esp,%ebp
f0104600:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0104603:	ff 75 10             	pushl  0x10(%ebp)
f0104606:	ff 75 0c             	pushl  0xc(%ebp)
f0104609:	ff 75 08             	pushl  0x8(%ebp)
f010460c:	e8 82 ff ff ff       	call   f0104593 <memmove>
}
f0104611:	c9                   	leave  
f0104612:	c3                   	ret    

f0104613 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104613:	f3 0f 1e fb          	endbr32 
f0104617:	55                   	push   %ebp
f0104618:	89 e5                	mov    %esp,%ebp
f010461a:	56                   	push   %esi
f010461b:	53                   	push   %ebx
f010461c:	8b 45 08             	mov    0x8(%ebp),%eax
f010461f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104622:	89 c6                	mov    %eax,%esi
f0104624:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104627:	39 f0                	cmp    %esi,%eax
f0104629:	74 1c                	je     f0104647 <memcmp+0x34>
		if (*s1 != *s2)
f010462b:	0f b6 08             	movzbl (%eax),%ecx
f010462e:	0f b6 1a             	movzbl (%edx),%ebx
f0104631:	38 d9                	cmp    %bl,%cl
f0104633:	75 08                	jne    f010463d <memcmp+0x2a>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0104635:	83 c0 01             	add    $0x1,%eax
f0104638:	83 c2 01             	add    $0x1,%edx
f010463b:	eb ea                	jmp    f0104627 <memcmp+0x14>
			return (int) *s1 - (int) *s2;
f010463d:	0f b6 c1             	movzbl %cl,%eax
f0104640:	0f b6 db             	movzbl %bl,%ebx
f0104643:	29 d8                	sub    %ebx,%eax
f0104645:	eb 05                	jmp    f010464c <memcmp+0x39>
	}

	return 0;
f0104647:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010464c:	5b                   	pop    %ebx
f010464d:	5e                   	pop    %esi
f010464e:	5d                   	pop    %ebp
f010464f:	c3                   	ret    

f0104650 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104650:	f3 0f 1e fb          	endbr32 
f0104654:	55                   	push   %ebp
f0104655:	89 e5                	mov    %esp,%ebp
f0104657:	8b 45 08             	mov    0x8(%ebp),%eax
f010465a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010465d:	89 c2                	mov    %eax,%edx
f010465f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104662:	39 d0                	cmp    %edx,%eax
f0104664:	73 09                	jae    f010466f <memfind+0x1f>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104666:	38 08                	cmp    %cl,(%eax)
f0104668:	74 05                	je     f010466f <memfind+0x1f>
	for (; s < ends; s++)
f010466a:	83 c0 01             	add    $0x1,%eax
f010466d:	eb f3                	jmp    f0104662 <memfind+0x12>
			break;
	return (void *) s;
}
f010466f:	5d                   	pop    %ebp
f0104670:	c3                   	ret    

f0104671 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104671:	f3 0f 1e fb          	endbr32 
f0104675:	55                   	push   %ebp
f0104676:	89 e5                	mov    %esp,%ebp
f0104678:	57                   	push   %edi
f0104679:	56                   	push   %esi
f010467a:	53                   	push   %ebx
f010467b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010467e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104681:	eb 03                	jmp    f0104686 <strtol+0x15>
		s++;
f0104683:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0104686:	0f b6 01             	movzbl (%ecx),%eax
f0104689:	3c 20                	cmp    $0x20,%al
f010468b:	74 f6                	je     f0104683 <strtol+0x12>
f010468d:	3c 09                	cmp    $0x9,%al
f010468f:	74 f2                	je     f0104683 <strtol+0x12>

	// plus/minus sign
	if (*s == '+')
f0104691:	3c 2b                	cmp    $0x2b,%al
f0104693:	74 2a                	je     f01046bf <strtol+0x4e>
	int neg = 0;
f0104695:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f010469a:	3c 2d                	cmp    $0x2d,%al
f010469c:	74 2b                	je     f01046c9 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010469e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01046a4:	75 0f                	jne    f01046b5 <strtol+0x44>
f01046a6:	80 39 30             	cmpb   $0x30,(%ecx)
f01046a9:	74 28                	je     f01046d3 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01046ab:	85 db                	test   %ebx,%ebx
f01046ad:	b8 0a 00 00 00       	mov    $0xa,%eax
f01046b2:	0f 44 d8             	cmove  %eax,%ebx
f01046b5:	b8 00 00 00 00       	mov    $0x0,%eax
f01046ba:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01046bd:	eb 46                	jmp    f0104705 <strtol+0x94>
		s++;
f01046bf:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f01046c2:	bf 00 00 00 00       	mov    $0x0,%edi
f01046c7:	eb d5                	jmp    f010469e <strtol+0x2d>
		s++, neg = 1;
f01046c9:	83 c1 01             	add    $0x1,%ecx
f01046cc:	bf 01 00 00 00       	mov    $0x1,%edi
f01046d1:	eb cb                	jmp    f010469e <strtol+0x2d>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01046d3:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01046d7:	74 0e                	je     f01046e7 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01046d9:	85 db                	test   %ebx,%ebx
f01046db:	75 d8                	jne    f01046b5 <strtol+0x44>
		s++, base = 8;
f01046dd:	83 c1 01             	add    $0x1,%ecx
f01046e0:	bb 08 00 00 00       	mov    $0x8,%ebx
f01046e5:	eb ce                	jmp    f01046b5 <strtol+0x44>
		s += 2, base = 16;
f01046e7:	83 c1 02             	add    $0x2,%ecx
f01046ea:	bb 10 00 00 00       	mov    $0x10,%ebx
f01046ef:	eb c4                	jmp    f01046b5 <strtol+0x44>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f01046f1:	0f be d2             	movsbl %dl,%edx
f01046f4:	83 ea 30             	sub    $0x30,%edx
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01046f7:	3b 55 10             	cmp    0x10(%ebp),%edx
f01046fa:	7d 3a                	jge    f0104736 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01046fc:	83 c1 01             	add    $0x1,%ecx
f01046ff:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104703:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0104705:	0f b6 11             	movzbl (%ecx),%edx
f0104708:	8d 72 d0             	lea    -0x30(%edx),%esi
f010470b:	89 f3                	mov    %esi,%ebx
f010470d:	80 fb 09             	cmp    $0x9,%bl
f0104710:	76 df                	jbe    f01046f1 <strtol+0x80>
		else if (*s >= 'a' && *s <= 'z')
f0104712:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104715:	89 f3                	mov    %esi,%ebx
f0104717:	80 fb 19             	cmp    $0x19,%bl
f010471a:	77 08                	ja     f0104724 <strtol+0xb3>
			dig = *s - 'a' + 10;
f010471c:	0f be d2             	movsbl %dl,%edx
f010471f:	83 ea 57             	sub    $0x57,%edx
f0104722:	eb d3                	jmp    f01046f7 <strtol+0x86>
		else if (*s >= 'A' && *s <= 'Z')
f0104724:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104727:	89 f3                	mov    %esi,%ebx
f0104729:	80 fb 19             	cmp    $0x19,%bl
f010472c:	77 08                	ja     f0104736 <strtol+0xc5>
			dig = *s - 'A' + 10;
f010472e:	0f be d2             	movsbl %dl,%edx
f0104731:	83 ea 37             	sub    $0x37,%edx
f0104734:	eb c1                	jmp    f01046f7 <strtol+0x86>
		// we don't properly detect overflow!
	}

	if (endptr)
f0104736:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010473a:	74 05                	je     f0104741 <strtol+0xd0>
		*endptr = (char *) s;
f010473c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010473f:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0104741:	89 c2                	mov    %eax,%edx
f0104743:	f7 da                	neg    %edx
f0104745:	85 ff                	test   %edi,%edi
f0104747:	0f 45 c2             	cmovne %edx,%eax
}
f010474a:	5b                   	pop    %ebx
f010474b:	5e                   	pop    %esi
f010474c:	5f                   	pop    %edi
f010474d:	5d                   	pop    %ebp
f010474e:	c3                   	ret    
f010474f:	90                   	nop

f0104750 <__udivdi3>:
f0104750:	f3 0f 1e fb          	endbr32 
f0104754:	55                   	push   %ebp
f0104755:	57                   	push   %edi
f0104756:	56                   	push   %esi
f0104757:	53                   	push   %ebx
f0104758:	83 ec 1c             	sub    $0x1c,%esp
f010475b:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010475f:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0104763:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104767:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f010476b:	85 d2                	test   %edx,%edx
f010476d:	75 19                	jne    f0104788 <__udivdi3+0x38>
f010476f:	39 f3                	cmp    %esi,%ebx
f0104771:	76 4d                	jbe    f01047c0 <__udivdi3+0x70>
f0104773:	31 ff                	xor    %edi,%edi
f0104775:	89 e8                	mov    %ebp,%eax
f0104777:	89 f2                	mov    %esi,%edx
f0104779:	f7 f3                	div    %ebx
f010477b:	89 fa                	mov    %edi,%edx
f010477d:	83 c4 1c             	add    $0x1c,%esp
f0104780:	5b                   	pop    %ebx
f0104781:	5e                   	pop    %esi
f0104782:	5f                   	pop    %edi
f0104783:	5d                   	pop    %ebp
f0104784:	c3                   	ret    
f0104785:	8d 76 00             	lea    0x0(%esi),%esi
f0104788:	39 f2                	cmp    %esi,%edx
f010478a:	76 14                	jbe    f01047a0 <__udivdi3+0x50>
f010478c:	31 ff                	xor    %edi,%edi
f010478e:	31 c0                	xor    %eax,%eax
f0104790:	89 fa                	mov    %edi,%edx
f0104792:	83 c4 1c             	add    $0x1c,%esp
f0104795:	5b                   	pop    %ebx
f0104796:	5e                   	pop    %esi
f0104797:	5f                   	pop    %edi
f0104798:	5d                   	pop    %ebp
f0104799:	c3                   	ret    
f010479a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01047a0:	0f bd fa             	bsr    %edx,%edi
f01047a3:	83 f7 1f             	xor    $0x1f,%edi
f01047a6:	75 48                	jne    f01047f0 <__udivdi3+0xa0>
f01047a8:	39 f2                	cmp    %esi,%edx
f01047aa:	72 06                	jb     f01047b2 <__udivdi3+0x62>
f01047ac:	31 c0                	xor    %eax,%eax
f01047ae:	39 eb                	cmp    %ebp,%ebx
f01047b0:	77 de                	ja     f0104790 <__udivdi3+0x40>
f01047b2:	b8 01 00 00 00       	mov    $0x1,%eax
f01047b7:	eb d7                	jmp    f0104790 <__udivdi3+0x40>
f01047b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01047c0:	89 d9                	mov    %ebx,%ecx
f01047c2:	85 db                	test   %ebx,%ebx
f01047c4:	75 0b                	jne    f01047d1 <__udivdi3+0x81>
f01047c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01047cb:	31 d2                	xor    %edx,%edx
f01047cd:	f7 f3                	div    %ebx
f01047cf:	89 c1                	mov    %eax,%ecx
f01047d1:	31 d2                	xor    %edx,%edx
f01047d3:	89 f0                	mov    %esi,%eax
f01047d5:	f7 f1                	div    %ecx
f01047d7:	89 c6                	mov    %eax,%esi
f01047d9:	89 e8                	mov    %ebp,%eax
f01047db:	89 f7                	mov    %esi,%edi
f01047dd:	f7 f1                	div    %ecx
f01047df:	89 fa                	mov    %edi,%edx
f01047e1:	83 c4 1c             	add    $0x1c,%esp
f01047e4:	5b                   	pop    %ebx
f01047e5:	5e                   	pop    %esi
f01047e6:	5f                   	pop    %edi
f01047e7:	5d                   	pop    %ebp
f01047e8:	c3                   	ret    
f01047e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01047f0:	89 f9                	mov    %edi,%ecx
f01047f2:	b8 20 00 00 00       	mov    $0x20,%eax
f01047f7:	29 f8                	sub    %edi,%eax
f01047f9:	d3 e2                	shl    %cl,%edx
f01047fb:	89 54 24 08          	mov    %edx,0x8(%esp)
f01047ff:	89 c1                	mov    %eax,%ecx
f0104801:	89 da                	mov    %ebx,%edx
f0104803:	d3 ea                	shr    %cl,%edx
f0104805:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0104809:	09 d1                	or     %edx,%ecx
f010480b:	89 f2                	mov    %esi,%edx
f010480d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104811:	89 f9                	mov    %edi,%ecx
f0104813:	d3 e3                	shl    %cl,%ebx
f0104815:	89 c1                	mov    %eax,%ecx
f0104817:	d3 ea                	shr    %cl,%edx
f0104819:	89 f9                	mov    %edi,%ecx
f010481b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010481f:	89 eb                	mov    %ebp,%ebx
f0104821:	d3 e6                	shl    %cl,%esi
f0104823:	89 c1                	mov    %eax,%ecx
f0104825:	d3 eb                	shr    %cl,%ebx
f0104827:	09 de                	or     %ebx,%esi
f0104829:	89 f0                	mov    %esi,%eax
f010482b:	f7 74 24 08          	divl   0x8(%esp)
f010482f:	89 d6                	mov    %edx,%esi
f0104831:	89 c3                	mov    %eax,%ebx
f0104833:	f7 64 24 0c          	mull   0xc(%esp)
f0104837:	39 d6                	cmp    %edx,%esi
f0104839:	72 15                	jb     f0104850 <__udivdi3+0x100>
f010483b:	89 f9                	mov    %edi,%ecx
f010483d:	d3 e5                	shl    %cl,%ebp
f010483f:	39 c5                	cmp    %eax,%ebp
f0104841:	73 04                	jae    f0104847 <__udivdi3+0xf7>
f0104843:	39 d6                	cmp    %edx,%esi
f0104845:	74 09                	je     f0104850 <__udivdi3+0x100>
f0104847:	89 d8                	mov    %ebx,%eax
f0104849:	31 ff                	xor    %edi,%edi
f010484b:	e9 40 ff ff ff       	jmp    f0104790 <__udivdi3+0x40>
f0104850:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0104853:	31 ff                	xor    %edi,%edi
f0104855:	e9 36 ff ff ff       	jmp    f0104790 <__udivdi3+0x40>
f010485a:	66 90                	xchg   %ax,%ax
f010485c:	66 90                	xchg   %ax,%ax
f010485e:	66 90                	xchg   %ax,%ax

f0104860 <__umoddi3>:
f0104860:	f3 0f 1e fb          	endbr32 
f0104864:	55                   	push   %ebp
f0104865:	57                   	push   %edi
f0104866:	56                   	push   %esi
f0104867:	53                   	push   %ebx
f0104868:	83 ec 1c             	sub    $0x1c,%esp
f010486b:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010486f:	8b 74 24 30          	mov    0x30(%esp),%esi
f0104873:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0104877:	8b 7c 24 38          	mov    0x38(%esp),%edi
f010487b:	85 c0                	test   %eax,%eax
f010487d:	75 19                	jne    f0104898 <__umoddi3+0x38>
f010487f:	39 df                	cmp    %ebx,%edi
f0104881:	76 5d                	jbe    f01048e0 <__umoddi3+0x80>
f0104883:	89 f0                	mov    %esi,%eax
f0104885:	89 da                	mov    %ebx,%edx
f0104887:	f7 f7                	div    %edi
f0104889:	89 d0                	mov    %edx,%eax
f010488b:	31 d2                	xor    %edx,%edx
f010488d:	83 c4 1c             	add    $0x1c,%esp
f0104890:	5b                   	pop    %ebx
f0104891:	5e                   	pop    %esi
f0104892:	5f                   	pop    %edi
f0104893:	5d                   	pop    %ebp
f0104894:	c3                   	ret    
f0104895:	8d 76 00             	lea    0x0(%esi),%esi
f0104898:	89 f2                	mov    %esi,%edx
f010489a:	39 d8                	cmp    %ebx,%eax
f010489c:	76 12                	jbe    f01048b0 <__umoddi3+0x50>
f010489e:	89 f0                	mov    %esi,%eax
f01048a0:	89 da                	mov    %ebx,%edx
f01048a2:	83 c4 1c             	add    $0x1c,%esp
f01048a5:	5b                   	pop    %ebx
f01048a6:	5e                   	pop    %esi
f01048a7:	5f                   	pop    %edi
f01048a8:	5d                   	pop    %ebp
f01048a9:	c3                   	ret    
f01048aa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01048b0:	0f bd e8             	bsr    %eax,%ebp
f01048b3:	83 f5 1f             	xor    $0x1f,%ebp
f01048b6:	75 50                	jne    f0104908 <__umoddi3+0xa8>
f01048b8:	39 d8                	cmp    %ebx,%eax
f01048ba:	0f 82 e0 00 00 00    	jb     f01049a0 <__umoddi3+0x140>
f01048c0:	89 d9                	mov    %ebx,%ecx
f01048c2:	39 f7                	cmp    %esi,%edi
f01048c4:	0f 86 d6 00 00 00    	jbe    f01049a0 <__umoddi3+0x140>
f01048ca:	89 d0                	mov    %edx,%eax
f01048cc:	89 ca                	mov    %ecx,%edx
f01048ce:	83 c4 1c             	add    $0x1c,%esp
f01048d1:	5b                   	pop    %ebx
f01048d2:	5e                   	pop    %esi
f01048d3:	5f                   	pop    %edi
f01048d4:	5d                   	pop    %ebp
f01048d5:	c3                   	ret    
f01048d6:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01048dd:	8d 76 00             	lea    0x0(%esi),%esi
f01048e0:	89 fd                	mov    %edi,%ebp
f01048e2:	85 ff                	test   %edi,%edi
f01048e4:	75 0b                	jne    f01048f1 <__umoddi3+0x91>
f01048e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01048eb:	31 d2                	xor    %edx,%edx
f01048ed:	f7 f7                	div    %edi
f01048ef:	89 c5                	mov    %eax,%ebp
f01048f1:	89 d8                	mov    %ebx,%eax
f01048f3:	31 d2                	xor    %edx,%edx
f01048f5:	f7 f5                	div    %ebp
f01048f7:	89 f0                	mov    %esi,%eax
f01048f9:	f7 f5                	div    %ebp
f01048fb:	89 d0                	mov    %edx,%eax
f01048fd:	31 d2                	xor    %edx,%edx
f01048ff:	eb 8c                	jmp    f010488d <__umoddi3+0x2d>
f0104901:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104908:	89 e9                	mov    %ebp,%ecx
f010490a:	ba 20 00 00 00       	mov    $0x20,%edx
f010490f:	29 ea                	sub    %ebp,%edx
f0104911:	d3 e0                	shl    %cl,%eax
f0104913:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104917:	89 d1                	mov    %edx,%ecx
f0104919:	89 f8                	mov    %edi,%eax
f010491b:	d3 e8                	shr    %cl,%eax
f010491d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0104921:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104925:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104929:	09 c1                	or     %eax,%ecx
f010492b:	89 d8                	mov    %ebx,%eax
f010492d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104931:	89 e9                	mov    %ebp,%ecx
f0104933:	d3 e7                	shl    %cl,%edi
f0104935:	89 d1                	mov    %edx,%ecx
f0104937:	d3 e8                	shr    %cl,%eax
f0104939:	89 e9                	mov    %ebp,%ecx
f010493b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010493f:	d3 e3                	shl    %cl,%ebx
f0104941:	89 c7                	mov    %eax,%edi
f0104943:	89 d1                	mov    %edx,%ecx
f0104945:	89 f0                	mov    %esi,%eax
f0104947:	d3 e8                	shr    %cl,%eax
f0104949:	89 e9                	mov    %ebp,%ecx
f010494b:	89 fa                	mov    %edi,%edx
f010494d:	d3 e6                	shl    %cl,%esi
f010494f:	09 d8                	or     %ebx,%eax
f0104951:	f7 74 24 08          	divl   0x8(%esp)
f0104955:	89 d1                	mov    %edx,%ecx
f0104957:	89 f3                	mov    %esi,%ebx
f0104959:	f7 64 24 0c          	mull   0xc(%esp)
f010495d:	89 c6                	mov    %eax,%esi
f010495f:	89 d7                	mov    %edx,%edi
f0104961:	39 d1                	cmp    %edx,%ecx
f0104963:	72 06                	jb     f010496b <__umoddi3+0x10b>
f0104965:	75 10                	jne    f0104977 <__umoddi3+0x117>
f0104967:	39 c3                	cmp    %eax,%ebx
f0104969:	73 0c                	jae    f0104977 <__umoddi3+0x117>
f010496b:	2b 44 24 0c          	sub    0xc(%esp),%eax
f010496f:	1b 54 24 08          	sbb    0x8(%esp),%edx
f0104973:	89 d7                	mov    %edx,%edi
f0104975:	89 c6                	mov    %eax,%esi
f0104977:	89 ca                	mov    %ecx,%edx
f0104979:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010497e:	29 f3                	sub    %esi,%ebx
f0104980:	19 fa                	sbb    %edi,%edx
f0104982:	89 d0                	mov    %edx,%eax
f0104984:	d3 e0                	shl    %cl,%eax
f0104986:	89 e9                	mov    %ebp,%ecx
f0104988:	d3 eb                	shr    %cl,%ebx
f010498a:	d3 ea                	shr    %cl,%edx
f010498c:	09 d8                	or     %ebx,%eax
f010498e:	83 c4 1c             	add    $0x1c,%esp
f0104991:	5b                   	pop    %ebx
f0104992:	5e                   	pop    %esi
f0104993:	5f                   	pop    %edi
f0104994:	5d                   	pop    %ebp
f0104995:	c3                   	ret    
f0104996:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f010499d:	8d 76 00             	lea    0x0(%esi),%esi
f01049a0:	29 fe                	sub    %edi,%esi
f01049a2:	19 c3                	sbb    %eax,%ebx
f01049a4:	89 f2                	mov    %esi,%edx
f01049a6:	89 d9                	mov    %ebx,%ecx
f01049a8:	e9 1d ff ff ff       	jmp    f01048ca <__umoddi3+0x6a>
