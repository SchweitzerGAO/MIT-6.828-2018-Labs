
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
f0100015:	b8 00 e0 18 00       	mov    $0x18e000,%eax
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
f0100034:	bc 00 b0 11 f0       	mov    $0xf011b000,%esp

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
f0100050:	81 c3 cc cf 08 00    	add    $0x8cfcc,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100056:	c7 c0 14 00 19 f0    	mov    $0xf0190014,%eax
f010005c:	c7 c2 00 f1 18 f0    	mov    $0xf018f100,%edx
f0100062:	29 d0                	sub    %edx,%eax
f0100064:	50                   	push   %eax
f0100065:	6a 00                	push   $0x0
f0100067:	52                   	push   %edx
f0100068:	e8 32 50 00 00       	call   f010509f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010006d:	e8 5c 05 00 00       	call   f01005ce <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	68 ac 1a 00 00       	push   $0x1aac
f010007a:	8d 83 04 85 f7 ff    	lea    -0x87afc(%ebx),%eax
f0100080:	50                   	push   %eax
f0100081:	e8 6f 39 00 00       	call   f01039f5 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100086:	e8 1f 13 00 00       	call   f01013aa <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f010008b:	e8 36 32 00 00       	call   f01032c6 <env_init>
	trap_init();
f0100090:	e8 1b 3a 00 00       	call   f0103ab0 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100095:	83 c4 08             	add    $0x8,%esp
f0100098:	6a 00                	push   $0x0
f010009a:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f01000a0:	e8 33 34 00 00       	call   f01034d8 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a5:	83 c4 04             	add    $0x4,%esp
f01000a8:	c7 c0 4c f3 18 f0    	mov    $0xf018f34c,%eax
f01000ae:	ff 30                	pushl  (%eax)
f01000b0:	e8 30 38 00 00       	call   f01038e5 <env_run>

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
f01000c7:	81 c3 55 cf 08 00    	add    $0x8cf55,%ebx
f01000cd:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000d0:	c7 c0 04 00 19 f0    	mov    $0xf0190004,%eax
f01000d6:	83 38 00             	cmpl   $0x0,(%eax)
f01000d9:	74 0f                	je     f01000ea <_panic+0x35>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000db:	83 ec 0c             	sub    $0xc,%esp
f01000de:	6a 00                	push   $0x0
f01000e0:	e8 5c 08 00 00       	call   f0100941 <monitor>
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
f01000fa:	8d 83 1f 85 f7 ff    	lea    -0x87ae1(%ebx),%eax
f0100100:	50                   	push   %eax
f0100101:	e8 ef 38 00 00       	call   f01039f5 <cprintf>
	vcprintf(fmt, ap);
f0100106:	83 c4 08             	add    $0x8,%esp
f0100109:	56                   	push   %esi
f010010a:	57                   	push   %edi
f010010b:	e8 aa 38 00 00       	call   f01039ba <vcprintf>
	cprintf("\n");
f0100110:	8d 83 be 94 f7 ff    	lea    -0x86b42(%ebx),%eax
f0100116:	89 04 24             	mov    %eax,(%esp)
f0100119:	e8 d7 38 00 00       	call   f01039f5 <cprintf>
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
f0100131:	81 c3 eb ce 08 00    	add    $0x8ceeb,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100137:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f010013a:	83 ec 04             	sub    $0x4,%esp
f010013d:	ff 75 0c             	pushl  0xc(%ebp)
f0100140:	ff 75 08             	pushl  0x8(%ebp)
f0100143:	8d 83 37 85 f7 ff    	lea    -0x87ac9(%ebx),%eax
f0100149:	50                   	push   %eax
f010014a:	e8 a6 38 00 00       	call   f01039f5 <cprintf>
	vcprintf(fmt, ap);
f010014f:	83 c4 08             	add    $0x8,%esp
f0100152:	56                   	push   %esi
f0100153:	ff 75 10             	pushl  0x10(%ebp)
f0100156:	e8 5f 38 00 00       	call   f01039ba <vcprintf>
	cprintf("\n");
f010015b:	8d 83 be 94 f7 ff    	lea    -0x86b42(%ebx),%eax
f0100161:	89 04 24             	mov    %eax,(%esp)
f0100164:	e8 8c 38 00 00       	call   f01039f5 <cprintf>
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
f01001a3:	81 c6 79 ce 08 00    	add    $0x8ce79,%esi
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
f0100205:	81 c3 17 ce 08 00    	add    $0x8ce17,%ebx
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
f010024d:	0f b6 84 13 84 86 f7 	movzbl -0x8797c(%ebx,%edx,1),%eax
f0100254:	ff 
f0100255:	0b 83 e4 20 00 00    	or     0x20e4(%ebx),%eax
	shift ^= togglecode[data];
f010025b:	0f b6 8c 13 84 85 f7 	movzbl -0x87a7c(%ebx,%edx,1),%ecx
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
f01002bc:	0f b6 84 13 84 86 f7 	movzbl -0x8797c(%ebx,%edx,1),%eax
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
f01002f8:	8d 83 51 85 f7 ff    	lea    -0x87aaf(%ebx),%eax
f01002fe:	50                   	push   %eax
f01002ff:	e8 f1 36 00 00       	call   f01039f5 <cprintf>
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
f0100333:	81 c3 e9 cc 08 00    	add    $0x8cce9,%ebx
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
f0100421:	0f b7 83 0c 23 00 00 	movzwl 0x230c(%ebx),%eax
f0100428:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010042e:	c1 e8 16             	shr    $0x16,%eax
f0100431:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100434:	c1 e0 04             	shl    $0x4,%eax
f0100437:	66 89 83 0c 23 00 00 	mov    %ax,0x230c(%ebx)
	if (crt_pos >= CRT_SIZE) {
f010043e:	66 81 bb 0c 23 00 00 	cmpw   $0x7cf,0x230c(%ebx)
f0100445:	cf 07 
f0100447:	0f 87 92 00 00 00    	ja     f01004df <cons_putc+0x1ba>
	outb(addr_6845, 14);
f010044d:	8b 8b 14 23 00 00    	mov    0x2314(%ebx),%ecx
f0100453:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100458:	89 ca                	mov    %ecx,%edx
f010045a:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045b:	0f b7 9b 0c 23 00 00 	movzwl 0x230c(%ebx),%ebx
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
f0100483:	0f b7 83 0c 23 00 00 	movzwl 0x230c(%ebx),%eax
f010048a:	66 85 c0             	test   %ax,%ax
f010048d:	74 be                	je     f010044d <cons_putc+0x128>
			crt_pos--;
f010048f:	83 e8 01             	sub    $0x1,%eax
f0100492:	66 89 83 0c 23 00 00 	mov    %ax,0x230c(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100499:	0f b7 c0             	movzwl %ax,%eax
f010049c:	89 fa                	mov    %edi,%edx
f010049e:	b2 00                	mov    $0x0,%dl
f01004a0:	83 ca 20             	or     $0x20,%edx
f01004a3:	8b 8b 10 23 00 00    	mov    0x2310(%ebx),%ecx
f01004a9:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f01004ad:	eb 8f                	jmp    f010043e <cons_putc+0x119>
		crt_pos += CRT_COLS;
f01004af:	66 83 83 0c 23 00 00 	addw   $0x50,0x230c(%ebx)
f01004b6:	50 
f01004b7:	e9 65 ff ff ff       	jmp    f0100421 <cons_putc+0xfc>
		crt_buf[crt_pos++] = c;		/* write the character */
f01004bc:	0f b7 83 0c 23 00 00 	movzwl 0x230c(%ebx),%eax
f01004c3:	8d 50 01             	lea    0x1(%eax),%edx
f01004c6:	66 89 93 0c 23 00 00 	mov    %dx,0x230c(%ebx)
f01004cd:	0f b7 c0             	movzwl %ax,%eax
f01004d0:	8b 93 10 23 00 00    	mov    0x2310(%ebx),%edx
f01004d6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
f01004da:	e9 5f ff ff ff       	jmp    f010043e <cons_putc+0x119>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004df:	8b 83 10 23 00 00    	mov    0x2310(%ebx),%eax
f01004e5:	83 ec 04             	sub    $0x4,%esp
f01004e8:	68 00 0f 00 00       	push   $0xf00
f01004ed:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004f3:	52                   	push   %edx
f01004f4:	50                   	push   %eax
f01004f5:	e8 f1 4b 00 00       	call   f01050eb <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004fa:	8b 93 10 23 00 00    	mov    0x2310(%ebx),%edx
f0100500:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100506:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010050c:	83 c4 10             	add    $0x10,%esp
f010050f:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100514:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100517:	39 d0                	cmp    %edx,%eax
f0100519:	75 f4                	jne    f010050f <cons_putc+0x1ea>
		crt_pos -= CRT_COLS;
f010051b:	66 83 ab 0c 23 00 00 	subw   $0x50,0x230c(%ebx)
f0100522:	50 
f0100523:	e9 25 ff ff ff       	jmp    f010044d <cons_putc+0x128>

f0100528 <serial_intr>:
{
f0100528:	f3 0f 1e fb          	endbr32 
f010052c:	e8 f6 01 00 00       	call   f0100727 <__x86.get_pc_thunk.ax>
f0100531:	05 eb ca 08 00       	add    $0x8caeb,%eax
	if (serial_exists)
f0100536:	80 b8 18 23 00 00 00 	cmpb   $0x0,0x2318(%eax)
f010053d:	75 01                	jne    f0100540 <serial_intr+0x18>
f010053f:	c3                   	ret    
{
f0100540:	55                   	push   %ebp
f0100541:	89 e5                	mov    %esp,%ebp
f0100543:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100546:	8d 80 5b 31 f7 ff    	lea    -0x8cea5(%eax),%eax
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
f0100562:	05 ba ca 08 00       	add    $0x8caba,%eax
	cons_intr(kbd_proc_data);
f0100567:	8d 80 db 31 f7 ff    	lea    -0x8ce25(%eax),%eax
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
f0100584:	81 c3 98 ca 08 00    	add    $0x8ca98,%ebx
	serial_intr();
f010058a:	e8 99 ff ff ff       	call   f0100528 <serial_intr>
	kbd_intr();
f010058f:	e8 bf ff ff ff       	call   f0100553 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100594:	8b 83 04 23 00 00    	mov    0x2304(%ebx),%eax
	return 0;
f010059a:	ba 00 00 00 00       	mov    $0x0,%edx
	if (cons.rpos != cons.wpos) {
f010059f:	3b 83 08 23 00 00    	cmp    0x2308(%ebx),%eax
f01005a5:	74 1f                	je     f01005c6 <cons_getc+0x52>
		c = cons.buf[cons.rpos++];
f01005a7:	8d 48 01             	lea    0x1(%eax),%ecx
f01005aa:	0f b6 94 03 04 21 00 	movzbl 0x2104(%ebx,%eax,1),%edx
f01005b1:	00 
			cons.rpos = 0;
f01005b2:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01005b8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bd:	0f 44 c8             	cmove  %eax,%ecx
f01005c0:	89 8b 04 23 00 00    	mov    %ecx,0x2304(%ebx)
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
f01005e0:	81 c3 3c ca 08 00    	add    $0x8ca3c,%ebx
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
f0100607:	c7 83 14 23 00 00 b4 	movl   $0x3b4,0x2314(%ebx)
f010060e:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100611:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f0100618:	8b bb 14 23 00 00    	mov    0x2314(%ebx),%edi
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
f0100640:	89 bb 10 23 00 00    	mov    %edi,0x2310(%ebx)
	pos |= inb(addr_6845 + 1);
f0100646:	0f b6 c0             	movzbl %al,%eax
f0100649:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f010064b:	66 89 b3 0c 23 00 00 	mov    %si,0x230c(%ebx)
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
f01006a3:	0f 95 83 18 23 00 00 	setne  0x2318(%ebx)
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
f01006ca:	c7 83 14 23 00 00 d4 	movl   $0x3d4,0x2314(%ebx)
f01006d1:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006d4:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006db:	e9 38 ff ff ff       	jmp    f0100618 <cons_init+0x4a>
		cprintf("Serial port does not exist!\n");
f01006e0:	83 ec 0c             	sub    $0xc,%esp
f01006e3:	8d 83 5d 85 f7 ff    	lea    -0x87aa3(%ebx),%eax
f01006e9:	50                   	push   %eax
f01006ea:	e8 06 33 00 00       	call   f01039f5 <cprintf>
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
f010073d:	81 c3 df c8 08 00    	add    $0x8c8df,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100743:	83 ec 04             	sub    $0x4,%esp
f0100746:	8d 83 84 87 f7 ff    	lea    -0x8787c(%ebx),%eax
f010074c:	50                   	push   %eax
f010074d:	8d 83 a2 87 f7 ff    	lea    -0x8785e(%ebx),%eax
f0100753:	50                   	push   %eax
f0100754:	8d b3 a7 87 f7 ff    	lea    -0x87859(%ebx),%esi
f010075a:	56                   	push   %esi
f010075b:	e8 95 32 00 00       	call   f01039f5 <cprintf>
f0100760:	83 c4 0c             	add    $0xc,%esp
f0100763:	8d 83 64 88 f7 ff    	lea    -0x8779c(%ebx),%eax
f0100769:	50                   	push   %eax
f010076a:	8d 83 b0 87 f7 ff    	lea    -0x87850(%ebx),%eax
f0100770:	50                   	push   %eax
f0100771:	56                   	push   %esi
f0100772:	e8 7e 32 00 00       	call   f01039f5 <cprintf>
f0100777:	83 c4 0c             	add    $0xc,%esp
f010077a:	8d 83 b9 87 f7 ff    	lea    -0x87847(%ebx),%eax
f0100780:	50                   	push   %eax
f0100781:	8d 83 cf 87 f7 ff    	lea    -0x87831(%ebx),%eax
f0100787:	50                   	push   %eax
f0100788:	56                   	push   %esi
f0100789:	e8 67 32 00 00       	call   f01039f5 <cprintf>
	return 0;
}
f010078e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100793:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100796:	5b                   	pop    %ebx
f0100797:	5e                   	pop    %esi
f0100798:	5d                   	pop    %ebp
f0100799:	c3                   	ret    

f010079a <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010079a:	f3 0f 1e fb          	endbr32 
f010079e:	55                   	push   %ebp
f010079f:	89 e5                	mov    %esp,%ebp
f01007a1:	57                   	push   %edi
f01007a2:	56                   	push   %esi
f01007a3:	53                   	push   %ebx
f01007a4:	83 ec 18             	sub    $0x18,%esp
f01007a7:	e8 c7 f9 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01007ac:	81 c3 70 c8 08 00    	add    $0x8c870,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007b2:	8d 83 d9 87 f7 ff    	lea    -0x87827(%ebx),%eax
f01007b8:	50                   	push   %eax
f01007b9:	e8 37 32 00 00       	call   f01039f5 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007be:	83 c4 08             	add    $0x8,%esp
f01007c1:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f01007c7:	8d 83 8c 88 f7 ff    	lea    -0x87774(%ebx),%eax
f01007cd:	50                   	push   %eax
f01007ce:	e8 22 32 00 00       	call   f01039f5 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007d3:	83 c4 0c             	add    $0xc,%esp
f01007d6:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f01007dc:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007e2:	50                   	push   %eax
f01007e3:	57                   	push   %edi
f01007e4:	8d 83 b4 88 f7 ff    	lea    -0x8774c(%ebx),%eax
f01007ea:	50                   	push   %eax
f01007eb:	e8 05 32 00 00       	call   f01039f5 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007f0:	83 c4 0c             	add    $0xc,%esp
f01007f3:	c7 c0 0d 55 10 f0    	mov    $0xf010550d,%eax
f01007f9:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007ff:	52                   	push   %edx
f0100800:	50                   	push   %eax
f0100801:	8d 83 d8 88 f7 ff    	lea    -0x87728(%ebx),%eax
f0100807:	50                   	push   %eax
f0100808:	e8 e8 31 00 00       	call   f01039f5 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010080d:	83 c4 0c             	add    $0xc,%esp
f0100810:	c7 c0 00 f1 18 f0    	mov    $0xf018f100,%eax
f0100816:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010081c:	52                   	push   %edx
f010081d:	50                   	push   %eax
f010081e:	8d 83 fc 88 f7 ff    	lea    -0x87704(%ebx),%eax
f0100824:	50                   	push   %eax
f0100825:	e8 cb 31 00 00       	call   f01039f5 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010082a:	83 c4 0c             	add    $0xc,%esp
f010082d:	c7 c6 14 00 19 f0    	mov    $0xf0190014,%esi
f0100833:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0100839:	50                   	push   %eax
f010083a:	56                   	push   %esi
f010083b:	8d 83 20 89 f7 ff    	lea    -0x876e0(%ebx),%eax
f0100841:	50                   	push   %eax
f0100842:	e8 ae 31 00 00       	call   f01039f5 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100847:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010084a:	29 fe                	sub    %edi,%esi
f010084c:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100852:	c1 fe 0a             	sar    $0xa,%esi
f0100855:	56                   	push   %esi
f0100856:	8d 83 44 89 f7 ff    	lea    -0x876bc(%ebx),%eax
f010085c:	50                   	push   %eax
f010085d:	e8 93 31 00 00       	call   f01039f5 <cprintf>
	return 0;
}
f0100862:	b8 00 00 00 00       	mov    $0x0,%eax
f0100867:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010086a:	5b                   	pop    %ebx
f010086b:	5e                   	pop    %esi
f010086c:	5f                   	pop    %edi
f010086d:	5d                   	pop    %ebp
f010086e:	c3                   	ret    

f010086f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010086f:	f3 0f 1e fb          	endbr32 
f0100873:	55                   	push   %ebp
f0100874:	89 e5                	mov    %esp,%ebp
f0100876:	57                   	push   %edi
f0100877:	56                   	push   %esi
f0100878:	53                   	push   %ebx
f0100879:	83 ec 3c             	sub    $0x3c,%esp
f010087c:	e8 f2 f8 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0100881:	81 c3 9b c7 08 00    	add    $0x8c79b,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100887:	89 ea                	mov    %ebp,%edx
f0100889:	89 d0                	mov    %edx,%eax
	// Your code here.
	typedef int (*this_func_type)(int, char **, struct Trapframe *);
	uint32_t ebp = read_ebp();
	int *ebp_base_ptr = (int *)ebp;           
f010088b:	89 55 bc             	mov    %edx,-0x44(%ebp)
	uint32_t eip = ebp_base_ptr[1];   
f010088e:	8b 52 04             	mov    0x4(%edx),%edx
f0100891:	89 55 c0             	mov    %edx,-0x40(%ebp)
	while (1) {
        // print address and arguments info
        cprintf("ebp %x, eip %x, args ", ebp, eip);
f0100894:	8d 93 f2 87 f7 ff    	lea    -0x8780e(%ebx),%edx
f010089a:	89 55 b8             	mov    %edx,-0x48(%ebp)

        int *args = ebp_base_ptr + 2;

        for (int i = 0; i < 5; ++i) {
            cprintf("%x ", args[i]);
f010089d:	8d 93 08 88 f7 ff    	lea    -0x877f8(%ebx),%edx
f01008a3:	89 55 c4             	mov    %edx,-0x3c(%ebp)
        cprintf("ebp %x, eip %x, args ", ebp, eip);
f01008a6:	83 ec 04             	sub    $0x4,%esp
f01008a9:	ff 75 c0             	pushl  -0x40(%ebp)
f01008ac:	50                   	push   %eax
f01008ad:	ff 75 b8             	pushl  -0x48(%ebp)
f01008b0:	e8 40 31 00 00       	call   f01039f5 <cprintf>
f01008b5:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01008b8:	8d 70 08             	lea    0x8(%eax),%esi
f01008bb:	8d 78 1c             	lea    0x1c(%eax),%edi
f01008be:	83 c4 10             	add    $0x10,%esp
            cprintf("%x ", args[i]);
f01008c1:	83 ec 08             	sub    $0x8,%esp
f01008c4:	ff 36                	pushl  (%esi)
f01008c6:	ff 75 c4             	pushl  -0x3c(%ebp)
f01008c9:	e8 27 31 00 00       	call   f01039f5 <cprintf>
f01008ce:	83 c6 04             	add    $0x4,%esi
        for (int i = 0; i < 5; ++i) {
f01008d1:	83 c4 10             	add    $0x10,%esp
f01008d4:	39 fe                	cmp    %edi,%esi
f01008d6:	75 e9                	jne    f01008c1 <mon_backtrace+0x52>
        }
        cprintf("\n");
f01008d8:	83 ec 0c             	sub    $0xc,%esp
f01008db:	8d 83 be 94 f7 ff    	lea    -0x86b42(%ebx),%eax
f01008e1:	50                   	push   %eax
f01008e2:	e8 0e 31 00 00       	call   f01039f5 <cprintf>
        
        // print file line info 
        struct Eipdebuginfo info;
        int ret = debuginfo_eip(eip, &info);
f01008e7:	83 c4 08             	add    $0x8,%esp
f01008ea:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01008ed:	50                   	push   %eax
f01008ee:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01008f1:	57                   	push   %edi
f01008f2:	e8 44 3c 00 00       	call   f010453b <debuginfo_eip>
f01008f7:	89 c6                	mov    %eax,%esi
        cprintf("     at %s: %d: %.*s+%d\n",
f01008f9:	83 c4 08             	add    $0x8,%esp
f01008fc:	89 f8                	mov    %edi,%eax
f01008fe:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100901:	50                   	push   %eax
f0100902:	ff 75 d8             	pushl  -0x28(%ebp)
f0100905:	ff 75 dc             	pushl  -0x24(%ebp)
f0100908:	ff 75 d4             	pushl  -0x2c(%ebp)
f010090b:	ff 75 d0             	pushl  -0x30(%ebp)
f010090e:	8d 83 0c 88 f7 ff    	lea    -0x877f4(%ebx),%eax
f0100914:	50                   	push   %eax
f0100915:	e8 db 30 00 00       	call   f01039f5 <cprintf>
                info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);

		// there aren't any info?
        if (ret) {
f010091a:	83 c4 20             	add    $0x20,%esp
f010091d:	85 f6                	test   %esi,%esi
f010091f:	75 13                	jne    f0100934 <mon_backtrace+0xc5>
            break;
        }
        // update the values
        ebp = *ebp_base_ptr;
f0100921:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0100924:	8b 00                	mov    (%eax),%eax
        ebp_base_ptr = (int*)ebp;
f0100926:	89 45 bc             	mov    %eax,-0x44(%ebp)
        eip = ebp_base_ptr[1];
f0100929:	8b 48 04             	mov    0x4(%eax),%ecx
f010092c:	89 4d c0             	mov    %ecx,-0x40(%ebp)
	while (1) {
f010092f:	e9 72 ff ff ff       	jmp    f01008a6 <mon_backtrace+0x37>
	}

	return 0;
}
f0100934:	b8 00 00 00 00       	mov    $0x0,%eax
f0100939:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010093c:	5b                   	pop    %ebx
f010093d:	5e                   	pop    %esi
f010093e:	5f                   	pop    %edi
f010093f:	5d                   	pop    %ebp
f0100940:	c3                   	ret    

f0100941 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100941:	f3 0f 1e fb          	endbr32 
f0100945:	55                   	push   %ebp
f0100946:	89 e5                	mov    %esp,%ebp
f0100948:	57                   	push   %edi
f0100949:	56                   	push   %esi
f010094a:	53                   	push   %ebx
f010094b:	83 ec 68             	sub    $0x68,%esp
f010094e:	e8 20 f8 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0100953:	81 c3 c9 c6 08 00    	add    $0x8c6c9,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100959:	8d 83 70 89 f7 ff    	lea    -0x87690(%ebx),%eax
f010095f:	50                   	push   %eax
f0100960:	e8 90 30 00 00       	call   f01039f5 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100965:	8d 83 94 89 f7 ff    	lea    -0x8766c(%ebx),%eax
f010096b:	89 04 24             	mov    %eax,(%esp)
f010096e:	e8 82 30 00 00       	call   f01039f5 <cprintf>

	if (tf != NULL)
f0100973:	83 c4 10             	add    $0x10,%esp
f0100976:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010097a:	74 0e                	je     f010098a <monitor+0x49>
		print_trapframe(tf);
f010097c:	83 ec 0c             	sub    $0xc,%esp
f010097f:	ff 75 08             	pushl  0x8(%ebp)
f0100982:	e8 89 35 00 00       	call   f0103f10 <print_trapframe>
f0100987:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f010098a:	8d 83 29 88 f7 ff    	lea    -0x877d7(%ebx),%eax
f0100990:	89 45 a0             	mov    %eax,-0x60(%ebp)
f0100993:	e9 d1 00 00 00       	jmp    f0100a69 <monitor+0x128>
f0100998:	83 ec 08             	sub    $0x8,%esp
f010099b:	0f be c0             	movsbl %al,%eax
f010099e:	50                   	push   %eax
f010099f:	ff 75 a0             	pushl  -0x60(%ebp)
f01009a2:	e8 b3 46 00 00       	call   f010505a <strchr>
f01009a7:	83 c4 10             	add    $0x10,%esp
f01009aa:	85 c0                	test   %eax,%eax
f01009ac:	74 6d                	je     f0100a1b <monitor+0xda>
			*buf++ = 0;
f01009ae:	c6 06 00             	movb   $0x0,(%esi)
f01009b1:	89 7d a4             	mov    %edi,-0x5c(%ebp)
f01009b4:	8d 76 01             	lea    0x1(%esi),%esi
f01009b7:	8b 7d a4             	mov    -0x5c(%ebp),%edi
		while (*buf && strchr(WHITESPACE, *buf))
f01009ba:	0f b6 06             	movzbl (%esi),%eax
f01009bd:	84 c0                	test   %al,%al
f01009bf:	75 d7                	jne    f0100998 <monitor+0x57>
	argv[argc] = 0;
f01009c1:	c7 44 bd a8 00 00 00 	movl   $0x0,-0x58(%ebp,%edi,4)
f01009c8:	00 
	if (argc == 0)
f01009c9:	85 ff                	test   %edi,%edi
f01009cb:	0f 84 98 00 00 00    	je     f0100a69 <monitor+0x128>
f01009d1:	8d b3 24 20 00 00    	lea    0x2024(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01009dc:	89 7d a4             	mov    %edi,-0x5c(%ebp)
f01009df:	89 c7                	mov    %eax,%edi
		if (strcmp(argv[0], commands[i].name) == 0)
f01009e1:	83 ec 08             	sub    $0x8,%esp
f01009e4:	ff 36                	pushl  (%esi)
f01009e6:	ff 75 a8             	pushl  -0x58(%ebp)
f01009e9:	e8 06 46 00 00       	call   f0104ff4 <strcmp>
f01009ee:	83 c4 10             	add    $0x10,%esp
f01009f1:	85 c0                	test   %eax,%eax
f01009f3:	0f 84 99 00 00 00    	je     f0100a92 <monitor+0x151>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009f9:	83 c7 01             	add    $0x1,%edi
f01009fc:	83 c6 0c             	add    $0xc,%esi
f01009ff:	83 ff 03             	cmp    $0x3,%edi
f0100a02:	75 dd                	jne    f01009e1 <monitor+0xa0>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a04:	83 ec 08             	sub    $0x8,%esp
f0100a07:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a0a:	8d 83 4b 88 f7 ff    	lea    -0x877b5(%ebx),%eax
f0100a10:	50                   	push   %eax
f0100a11:	e8 df 2f 00 00       	call   f01039f5 <cprintf>
	return 0;
f0100a16:	83 c4 10             	add    $0x10,%esp
f0100a19:	eb 4e                	jmp    f0100a69 <monitor+0x128>
		if (*buf == 0)
f0100a1b:	80 3e 00             	cmpb   $0x0,(%esi)
f0100a1e:	74 a1                	je     f01009c1 <monitor+0x80>
		if (argc == MAXARGS-1) {
f0100a20:	83 ff 0f             	cmp    $0xf,%edi
f0100a23:	74 30                	je     f0100a55 <monitor+0x114>
		argv[argc++] = buf;
f0100a25:	8d 47 01             	lea    0x1(%edi),%eax
f0100a28:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100a2b:	89 74 bd a8          	mov    %esi,-0x58(%ebp,%edi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a2f:	0f b6 06             	movzbl (%esi),%eax
f0100a32:	84 c0                	test   %al,%al
f0100a34:	74 81                	je     f01009b7 <monitor+0x76>
f0100a36:	83 ec 08             	sub    $0x8,%esp
f0100a39:	0f be c0             	movsbl %al,%eax
f0100a3c:	50                   	push   %eax
f0100a3d:	ff 75 a0             	pushl  -0x60(%ebp)
f0100a40:	e8 15 46 00 00       	call   f010505a <strchr>
f0100a45:	83 c4 10             	add    $0x10,%esp
f0100a48:	85 c0                	test   %eax,%eax
f0100a4a:	0f 85 67 ff ff ff    	jne    f01009b7 <monitor+0x76>
			buf++;
f0100a50:	83 c6 01             	add    $0x1,%esi
f0100a53:	eb da                	jmp    f0100a2f <monitor+0xee>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a55:	83 ec 08             	sub    $0x8,%esp
f0100a58:	6a 10                	push   $0x10
f0100a5a:	8d 83 2e 88 f7 ff    	lea    -0x877d2(%ebx),%eax
f0100a60:	50                   	push   %eax
f0100a61:	e8 8f 2f 00 00       	call   f01039f5 <cprintf>
			return 0;
f0100a66:	83 c4 10             	add    $0x10,%esp
	// cprintf("x %d, y %x, z %d\n", x, y, z);
	// unsigned int i = 0x00646c72;
 	// cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100a69:	8d bb 25 88 f7 ff    	lea    -0x877db(%ebx),%edi
f0100a6f:	83 ec 0c             	sub    $0xc,%esp
f0100a72:	57                   	push   %edi
f0100a73:	e8 71 43 00 00       	call   f0104de9 <readline>
		if (buf != NULL)
f0100a78:	83 c4 10             	add    $0x10,%esp
f0100a7b:	85 c0                	test   %eax,%eax
f0100a7d:	74 f0                	je     f0100a6f <monitor+0x12e>
f0100a7f:	89 c6                	mov    %eax,%esi
	argv[argc] = 0;
f0100a81:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100a88:	bf 00 00 00 00       	mov    $0x0,%edi
f0100a8d:	e9 28 ff ff ff       	jmp    f01009ba <monitor+0x79>
f0100a92:	89 f8                	mov    %edi,%eax
f0100a94:	8b 7d a4             	mov    -0x5c(%ebp),%edi
			return commands[i].func(argc, argv, tf);
f0100a97:	83 ec 04             	sub    $0x4,%esp
f0100a9a:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100a9d:	ff 75 08             	pushl  0x8(%ebp)
f0100aa0:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100aa3:	52                   	push   %edx
f0100aa4:	57                   	push   %edi
f0100aa5:	ff 94 83 2c 20 00 00 	call   *0x202c(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100aac:	83 c4 10             	add    $0x10,%esp
f0100aaf:	85 c0                	test   %eax,%eax
f0100ab1:	79 b6                	jns    f0100a69 <monitor+0x128>
				break;
	}
}
f0100ab3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ab6:	5b                   	pop    %ebx
f0100ab7:	5e                   	pop    %esi
f0100ab8:	5f                   	pop    %edi
f0100ab9:	5d                   	pop    %ebp
f0100aba:	c3                   	ret    

f0100abb <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100abb:	55                   	push   %ebp
f0100abc:	89 e5                	mov    %esp,%ebp
f0100abe:	57                   	push   %edi
f0100abf:	56                   	push   %esi
f0100ac0:	53                   	push   %ebx
f0100ac1:	83 ec 18             	sub    $0x18,%esp
f0100ac4:	e8 aa f6 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0100ac9:	81 c3 53 c5 08 00    	add    $0x8c553,%ebx
f0100acf:	89 c6                	mov    %eax,%esi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100ad1:	50                   	push   %eax
f0100ad2:	e8 87 2e 00 00       	call   f010395e <mc146818_read>
f0100ad7:	89 c7                	mov    %eax,%edi
f0100ad9:	83 c6 01             	add    $0x1,%esi
f0100adc:	89 34 24             	mov    %esi,(%esp)
f0100adf:	e8 7a 2e 00 00       	call   f010395e <mc146818_read>
f0100ae4:	c1 e0 08             	shl    $0x8,%eax
f0100ae7:	09 f8                	or     %edi,%eax
}
f0100ae9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100aec:	5b                   	pop    %ebx
f0100aed:	5e                   	pop    %esi
f0100aee:	5f                   	pop    %edi
f0100aef:	5d                   	pop    %ebp
f0100af0:	c3                   	ret    

f0100af1 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100af1:	e8 42 26 00 00       	call   f0103138 <__x86.get_pc_thunk.dx>
f0100af6:	81 c2 26 c5 08 00    	add    $0x8c526,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100afc:	83 ba 1c 23 00 00 00 	cmpl   $0x0,0x231c(%edx)
f0100b03:	74 3e                	je     f0100b43 <boot_alloc+0x52>
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.

	// special case
	if(n == 0)
f0100b05:	85 c0                	test   %eax,%eax
f0100b07:	74 54                	je     f0100b5d <boot_alloc+0x6c>
{
f0100b09:	55                   	push   %ebp
f0100b0a:	89 e5                	mov    %esp,%ebp
f0100b0c:	53                   	push   %ebx
f0100b0d:	83 ec 04             	sub    $0x4,%esp
	{
		return nextfree;
	}

	// allocate memory 
	result = nextfree;
f0100b10:	8b 8a 1c 23 00 00    	mov    0x231c(%edx),%ecx
	nextfree = ROUNDUP(n,PGSIZE)+nextfree;
f0100b16:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100b1b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b20:	01 c8                	add    %ecx,%eax
f0100b22:	89 82 1c 23 00 00    	mov    %eax,0x231c(%edx)

	// out of memory panic
	if((uint32_t)nextfree-KERNBASE>(npages*PGSIZE))
f0100b28:	05 00 00 00 10       	add    $0x10000000,%eax
f0100b2d:	c7 c3 08 00 19 f0    	mov    $0xf0190008,%ebx
f0100b33:	8b 1b                	mov    (%ebx),%ebx
f0100b35:	c1 e3 0c             	shl    $0xc,%ebx
f0100b38:	39 d8                	cmp    %ebx,%eax
f0100b3a:	77 2a                	ja     f0100b66 <boot_alloc+0x75>
		nextfree = result;
		return NULL;
	}
	return result;

}
f0100b3c:	89 c8                	mov    %ecx,%eax
f0100b3e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b41:	c9                   	leave  
f0100b42:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b43:	c7 c1 14 00 19 f0    	mov    $0xf0190014,%ecx
f0100b49:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100b4f:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100b55:	89 8a 1c 23 00 00    	mov    %ecx,0x231c(%edx)
f0100b5b:	eb a8                	jmp    f0100b05 <boot_alloc+0x14>
		return nextfree;
f0100b5d:	8b 8a 1c 23 00 00    	mov    0x231c(%edx),%ecx
}
f0100b63:	89 c8                	mov    %ecx,%eax
f0100b65:	c3                   	ret    
		panic("at pmap.c:boot_alloc(): out of memory");
f0100b66:	83 ec 04             	sub    $0x4,%esp
f0100b69:	8d 82 bc 89 f7 ff    	lea    -0x87644(%edx),%eax
f0100b6f:	50                   	push   %eax
f0100b70:	6a 78                	push   $0x78
f0100b72:	8d 82 0d 92 f7 ff    	lea    -0x86df3(%edx),%eax
f0100b78:	50                   	push   %eax
f0100b79:	89 d3                	mov    %edx,%ebx
f0100b7b:	e8 35 f5 ff ff       	call   f01000b5 <_panic>

f0100b80 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b80:	55                   	push   %ebp
f0100b81:	89 e5                	mov    %esp,%ebp
f0100b83:	56                   	push   %esi
f0100b84:	53                   	push   %ebx
f0100b85:	e8 b2 25 00 00       	call   f010313c <__x86.get_pc_thunk.cx>
f0100b8a:	81 c1 92 c4 08 00    	add    $0x8c492,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b90:	89 d3                	mov    %edx,%ebx
f0100b92:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100b95:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100b98:	a8 01                	test   $0x1,%al
f0100b9a:	74 59                	je     f0100bf5 <check_va2pa+0x75>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b9c:	89 c3                	mov    %eax,%ebx
f0100b9e:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ba4:	c1 e8 0c             	shr    $0xc,%eax
f0100ba7:	c7 c6 08 00 19 f0    	mov    $0xf0190008,%esi
f0100bad:	3b 06                	cmp    (%esi),%eax
f0100baf:	73 29                	jae    f0100bda <check_va2pa+0x5a>
	if (!(p[PTX(va)] & PTE_P))
f0100bb1:	c1 ea 0c             	shr    $0xc,%edx
f0100bb4:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100bba:	8b 94 93 00 00 00 f0 	mov    -0x10000000(%ebx,%edx,4),%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100bc1:	89 d0                	mov    %edx,%eax
f0100bc3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100bc8:	f6 c2 01             	test   $0x1,%dl
f0100bcb:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100bd0:	0f 44 c2             	cmove  %edx,%eax
}
f0100bd3:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100bd6:	5b                   	pop    %ebx
f0100bd7:	5e                   	pop    %esi
f0100bd8:	5d                   	pop    %ebp
f0100bd9:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bda:	53                   	push   %ebx
f0100bdb:	8d 81 e4 89 f7 ff    	lea    -0x8761c(%ecx),%eax
f0100be1:	50                   	push   %eax
f0100be2:	68 9b 03 00 00       	push   $0x39b
f0100be7:	8d 81 0d 92 f7 ff    	lea    -0x86df3(%ecx),%eax
f0100bed:	50                   	push   %eax
f0100bee:	89 cb                	mov    %ecx,%ebx
f0100bf0:	e8 c0 f4 ff ff       	call   f01000b5 <_panic>
		return ~0;
f0100bf5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bfa:	eb d7                	jmp    f0100bd3 <check_va2pa+0x53>

f0100bfc <check_page_free_list>:
{
f0100bfc:	55                   	push   %ebp
f0100bfd:	89 e5                	mov    %esp,%ebp
f0100bff:	57                   	push   %edi
f0100c00:	56                   	push   %esi
f0100c01:	53                   	push   %ebx
f0100c02:	83 ec 2c             	sub    $0x2c,%esp
f0100c05:	e8 21 fb ff ff       	call   f010072b <__x86.get_pc_thunk.si>
f0100c0a:	81 c6 12 c4 08 00    	add    $0x8c412,%esi
f0100c10:	89 75 c8             	mov    %esi,-0x38(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c13:	84 c0                	test   %al,%al
f0100c15:	0f 85 ec 02 00 00    	jne    f0100f07 <check_page_free_list+0x30b>
	if (!page_free_list)
f0100c1b:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100c1e:	83 b8 24 23 00 00 00 	cmpl   $0x0,0x2324(%eax)
f0100c25:	74 21                	je     f0100c48 <check_page_free_list+0x4c>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c27:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c2e:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100c31:	8b b0 24 23 00 00    	mov    0x2324(%eax),%esi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c37:	c7 c7 10 00 19 f0    	mov    $0xf0190010,%edi
	if (PGNUM(pa) >= npages)
f0100c3d:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0100c43:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100c46:	eb 39                	jmp    f0100c81 <check_page_free_list+0x85>
		panic("'page_free_list' is a null pointer!");
f0100c48:	83 ec 04             	sub    $0x4,%esp
f0100c4b:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100c4e:	8d 83 08 8a f7 ff    	lea    -0x875f8(%ebx),%eax
f0100c54:	50                   	push   %eax
f0100c55:	68 d7 02 00 00       	push   $0x2d7
f0100c5a:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0100c60:	50                   	push   %eax
f0100c61:	e8 4f f4 ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c66:	50                   	push   %eax
f0100c67:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100c6a:	8d 83 e4 89 f7 ff    	lea    -0x8761c(%ebx),%eax
f0100c70:	50                   	push   %eax
f0100c71:	6a 56                	push   $0x56
f0100c73:	8d 83 19 92 f7 ff    	lea    -0x86de7(%ebx),%eax
f0100c79:	50                   	push   %eax
f0100c7a:	e8 36 f4 ff ff       	call   f01000b5 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c7f:	8b 36                	mov    (%esi),%esi
f0100c81:	85 f6                	test   %esi,%esi
f0100c83:	74 40                	je     f0100cc5 <check_page_free_list+0xc9>
	return (pp - pages) << PGSHIFT;
f0100c85:	89 f0                	mov    %esi,%eax
f0100c87:	2b 07                	sub    (%edi),%eax
f0100c89:	c1 f8 03             	sar    $0x3,%eax
f0100c8c:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c8f:	89 c2                	mov    %eax,%edx
f0100c91:	c1 ea 16             	shr    $0x16,%edx
f0100c94:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c97:	73 e6                	jae    f0100c7f <check_page_free_list+0x83>
	if (PGNUM(pa) >= npages)
f0100c99:	89 c2                	mov    %eax,%edx
f0100c9b:	c1 ea 0c             	shr    $0xc,%edx
f0100c9e:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100ca1:	3b 11                	cmp    (%ecx),%edx
f0100ca3:	73 c1                	jae    f0100c66 <check_page_free_list+0x6a>
			memset(page2kva(pp), 0x97, 128);
f0100ca5:	83 ec 04             	sub    $0x4,%esp
f0100ca8:	68 80 00 00 00       	push   $0x80
f0100cad:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100cb2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cb7:	50                   	push   %eax
f0100cb8:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100cbb:	e8 df 43 00 00       	call   f010509f <memset>
f0100cc0:	83 c4 10             	add    $0x10,%esp
f0100cc3:	eb ba                	jmp    f0100c7f <check_page_free_list+0x83>
	first_free_page = (char *) boot_alloc(0);
f0100cc5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cca:	e8 22 fe ff ff       	call   f0100af1 <boot_alloc>
f0100ccf:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cd2:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0100cd5:	8b 97 24 23 00 00    	mov    0x2324(%edi),%edx
		assert(pp >= pages);
f0100cdb:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f0100ce1:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100ce3:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0100ce9:	8b 00                	mov    (%eax),%eax
f0100ceb:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100cee:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
	int nfree_basemem = 0, nfree_extmem = 0;
f0100cf1:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cf6:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cf9:	e9 08 01 00 00       	jmp    f0100e06 <check_page_free_list+0x20a>
		assert(pp >= pages);
f0100cfe:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100d01:	8d 83 27 92 f7 ff    	lea    -0x86dd9(%ebx),%eax
f0100d07:	50                   	push   %eax
f0100d08:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0100d0e:	50                   	push   %eax
f0100d0f:	68 f1 02 00 00       	push   $0x2f1
f0100d14:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0100d1a:	50                   	push   %eax
f0100d1b:	e8 95 f3 ff ff       	call   f01000b5 <_panic>
		assert(pp < pages + npages);
f0100d20:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100d23:	8d 83 48 92 f7 ff    	lea    -0x86db8(%ebx),%eax
f0100d29:	50                   	push   %eax
f0100d2a:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0100d30:	50                   	push   %eax
f0100d31:	68 f2 02 00 00       	push   $0x2f2
f0100d36:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0100d3c:	50                   	push   %eax
f0100d3d:	e8 73 f3 ff ff       	call   f01000b5 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d42:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100d45:	8d 83 2c 8a f7 ff    	lea    -0x875d4(%ebx),%eax
f0100d4b:	50                   	push   %eax
f0100d4c:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0100d52:	50                   	push   %eax
f0100d53:	68 f3 02 00 00       	push   $0x2f3
f0100d58:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0100d5e:	50                   	push   %eax
f0100d5f:	e8 51 f3 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) != 0);
f0100d64:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100d67:	8d 83 5c 92 f7 ff    	lea    -0x86da4(%ebx),%eax
f0100d6d:	50                   	push   %eax
f0100d6e:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0100d74:	50                   	push   %eax
f0100d75:	68 f6 02 00 00       	push   $0x2f6
f0100d7a:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0100d80:	50                   	push   %eax
f0100d81:	e8 2f f3 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d86:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100d89:	8d 83 6d 92 f7 ff    	lea    -0x86d93(%ebx),%eax
f0100d8f:	50                   	push   %eax
f0100d90:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0100d96:	50                   	push   %eax
f0100d97:	68 f7 02 00 00       	push   $0x2f7
f0100d9c:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0100da2:	50                   	push   %eax
f0100da3:	e8 0d f3 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100da8:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100dab:	8d 83 60 8a f7 ff    	lea    -0x875a0(%ebx),%eax
f0100db1:	50                   	push   %eax
f0100db2:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0100db8:	50                   	push   %eax
f0100db9:	68 f8 02 00 00       	push   $0x2f8
f0100dbe:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0100dc4:	50                   	push   %eax
f0100dc5:	e8 eb f2 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100dca:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100dcd:	8d 83 86 92 f7 ff    	lea    -0x86d7a(%ebx),%eax
f0100dd3:	50                   	push   %eax
f0100dd4:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0100dda:	50                   	push   %eax
f0100ddb:	68 f9 02 00 00       	push   $0x2f9
f0100de0:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0100de6:	50                   	push   %eax
f0100de7:	e8 c9 f2 ff ff       	call   f01000b5 <_panic>
	if (PGNUM(pa) >= npages)
f0100dec:	89 c3                	mov    %eax,%ebx
f0100dee:	c1 eb 0c             	shr    $0xc,%ebx
f0100df1:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0100df4:	76 6d                	jbe    f0100e63 <check_page_free_list+0x267>
	return (void *)(pa + KERNBASE);
f0100df6:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100dfb:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100dfe:	77 7c                	ja     f0100e7c <check_page_free_list+0x280>
			++nfree_extmem;
f0100e00:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e04:	8b 12                	mov    (%edx),%edx
f0100e06:	85 d2                	test   %edx,%edx
f0100e08:	0f 84 90 00 00 00    	je     f0100e9e <check_page_free_list+0x2a2>
		assert(pp >= pages);
f0100e0e:	39 d1                	cmp    %edx,%ecx
f0100e10:	0f 87 e8 fe ff ff    	ja     f0100cfe <check_page_free_list+0x102>
		assert(pp < pages + npages);
f0100e16:	39 d7                	cmp    %edx,%edi
f0100e18:	0f 86 02 ff ff ff    	jbe    f0100d20 <check_page_free_list+0x124>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e1e:	89 d0                	mov    %edx,%eax
f0100e20:	29 c8                	sub    %ecx,%eax
f0100e22:	a8 07                	test   $0x7,%al
f0100e24:	0f 85 18 ff ff ff    	jne    f0100d42 <check_page_free_list+0x146>
	return (pp - pages) << PGSHIFT;
f0100e2a:	c1 f8 03             	sar    $0x3,%eax
		assert(page2pa(pp) != 0);
f0100e2d:	c1 e0 0c             	shl    $0xc,%eax
f0100e30:	0f 84 2e ff ff ff    	je     f0100d64 <check_page_free_list+0x168>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e36:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e3b:	0f 84 45 ff ff ff    	je     f0100d86 <check_page_free_list+0x18a>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100e41:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100e46:	0f 84 5c ff ff ff    	je     f0100da8 <check_page_free_list+0x1ac>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100e4c:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100e51:	0f 84 73 ff ff ff    	je     f0100dca <check_page_free_list+0x1ce>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e57:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100e5c:	77 8e                	ja     f0100dec <check_page_free_list+0x1f0>
			++nfree_basemem;
f0100e5e:	83 c6 01             	add    $0x1,%esi
f0100e61:	eb a1                	jmp    f0100e04 <check_page_free_list+0x208>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e63:	50                   	push   %eax
f0100e64:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100e67:	8d 83 e4 89 f7 ff    	lea    -0x8761c(%ebx),%eax
f0100e6d:	50                   	push   %eax
f0100e6e:	6a 56                	push   $0x56
f0100e70:	8d 83 19 92 f7 ff    	lea    -0x86de7(%ebx),%eax
f0100e76:	50                   	push   %eax
f0100e77:	e8 39 f2 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e7c:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100e7f:	8d 83 84 8a f7 ff    	lea    -0x8757c(%ebx),%eax
f0100e85:	50                   	push   %eax
f0100e86:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0100e8c:	50                   	push   %eax
f0100e8d:	68 fa 02 00 00       	push   $0x2fa
f0100e92:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0100e98:	50                   	push   %eax
f0100e99:	e8 17 f2 ff ff       	call   f01000b5 <_panic>
f0100e9e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
	assert(nfree_basemem > 0);
f0100ea1:	85 f6                	test   %esi,%esi
f0100ea3:	7e 1e                	jle    f0100ec3 <check_page_free_list+0x2c7>
	assert(nfree_extmem > 0);
f0100ea5:	85 db                	test   %ebx,%ebx
f0100ea7:	7e 3c                	jle    f0100ee5 <check_page_free_list+0x2e9>
	cprintf("check_page_free_list() succeeded!\n");
f0100ea9:	83 ec 0c             	sub    $0xc,%esp
f0100eac:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100eaf:	8d 83 cc 8a f7 ff    	lea    -0x87534(%ebx),%eax
f0100eb5:	50                   	push   %eax
f0100eb6:	e8 3a 2b 00 00       	call   f01039f5 <cprintf>
}
f0100ebb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ebe:	5b                   	pop    %ebx
f0100ebf:	5e                   	pop    %esi
f0100ec0:	5f                   	pop    %edi
f0100ec1:	5d                   	pop    %ebp
f0100ec2:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100ec3:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100ec6:	8d 83 a0 92 f7 ff    	lea    -0x86d60(%ebx),%eax
f0100ecc:	50                   	push   %eax
f0100ecd:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0100ed3:	50                   	push   %eax
f0100ed4:	68 02 03 00 00       	push   $0x302
f0100ed9:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0100edf:	50                   	push   %eax
f0100ee0:	e8 d0 f1 ff ff       	call   f01000b5 <_panic>
	assert(nfree_extmem > 0);
f0100ee5:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100ee8:	8d 83 b2 92 f7 ff    	lea    -0x86d4e(%ebx),%eax
f0100eee:	50                   	push   %eax
f0100eef:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0100ef5:	50                   	push   %eax
f0100ef6:	68 03 03 00 00       	push   $0x303
f0100efb:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0100f01:	50                   	push   %eax
f0100f02:	e8 ae f1 ff ff       	call   f01000b5 <_panic>
	if (!page_free_list)
f0100f07:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100f0a:	8b 80 24 23 00 00    	mov    0x2324(%eax),%eax
f0100f10:	85 c0                	test   %eax,%eax
f0100f12:	0f 84 30 fd ff ff    	je     f0100c48 <check_page_free_list+0x4c>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100f18:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100f1b:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100f1e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100f21:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100f24:	8b 75 c8             	mov    -0x38(%ebp),%esi
f0100f27:	c7 c3 10 00 19 f0    	mov    $0xf0190010,%ebx
f0100f2d:	89 c2                	mov    %eax,%edx
f0100f2f:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100f31:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100f37:	0f 95 c2             	setne  %dl
f0100f3a:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100f3d:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100f41:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100f43:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f47:	8b 00                	mov    (%eax),%eax
f0100f49:	85 c0                	test   %eax,%eax
f0100f4b:	75 e0                	jne    f0100f2d <check_page_free_list+0x331>
		*tp[1] = 0;
f0100f4d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f50:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100f56:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f59:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f5c:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100f5e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100f61:	8b 75 c8             	mov    -0x38(%ebp),%esi
f0100f64:	89 86 24 23 00 00    	mov    %eax,0x2324(%esi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f6a:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
f0100f71:	e9 b8 fc ff ff       	jmp    f0100c2e <check_page_free_list+0x32>

f0100f76 <page_init>:
{
f0100f76:	f3 0f 1e fb          	endbr32 
f0100f7a:	55                   	push   %ebp
f0100f7b:	89 e5                	mov    %esp,%ebp
f0100f7d:	57                   	push   %edi
f0100f7e:	56                   	push   %esi
f0100f7f:	53                   	push   %ebx
f0100f80:	83 ec 2c             	sub    $0x2c,%esp
f0100f83:	e8 b0 21 00 00       	call   f0103138 <__x86.get_pc_thunk.dx>
f0100f88:	81 c2 94 c0 08 00    	add    $0x8c094,%edx
f0100f8e:	89 d7                	mov    %edx,%edi
f0100f90:	89 55 d0             	mov    %edx,-0x30(%ebp)
	size_t num_used = ((uint32_t)boot_alloc(0)-EXTPHYSMEM-KERNBASE)/PGSIZE;
f0100f93:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f98:	e8 54 fb ff ff       	call   f0100af1 <boot_alloc>
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100f9d:	8b b7 28 23 00 00    	mov    0x2328(%edi),%esi
f0100fa3:	89 75 e0             	mov    %esi,-0x20(%ebp)
	size_t num_used = ((uint32_t)boot_alloc(0)-EXTPHYSMEM-KERNBASE)/PGSIZE;
f0100fa6:	05 00 00 f0 0f       	add    $0xff00000,%eax
f0100fab:	c1 e8 0c             	shr    $0xc,%eax
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100fae:	8d 44 06 60          	lea    0x60(%esi,%eax,1),%eax
f0100fb2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100fb5:	8b b7 24 23 00 00    	mov    0x2324(%edi),%esi
	for(size_t i = 0;i<npages;i++)
f0100fbb:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100fc0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fc5:	c7 c2 08 00 19 f0    	mov    $0xf0190008,%edx
			pages[i].pp_ref = 0;
f0100fcb:	c7 c1 10 00 19 f0    	mov    $0xf0190010,%ecx
f0100fd1:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
			pages[i].pp_ref = 1;
f0100fd4:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
			pages[i].pp_ref = 1;
f0100fd7:	89 4d dc             	mov    %ecx,-0x24(%ebp)
	for(size_t i = 0;i<npages;i++)
f0100fda:	eb 45                	jmp    f0101021 <page_init+0xab>
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100fdc:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f0100fdf:	77 1b                	ja     f0100ffc <page_init+0x86>
f0100fe1:	39 45 d8             	cmp    %eax,-0x28(%ebp)
f0100fe4:	76 16                	jbe    f0100ffc <page_init+0x86>
			pages[i].pp_ref = 1;
f0100fe6:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100fe9:	8b 09                	mov    (%ecx),%ecx
f0100feb:	8d 0c c1             	lea    (%ecx,%eax,8),%ecx
f0100fee:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f0100ff4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100ffa:	eb 22                	jmp    f010101e <page_init+0xa8>
f0100ffc:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
			pages[i].pp_ref = 0;
f0101003:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101006:	89 cf                	mov    %ecx,%edi
f0101008:	03 3b                	add    (%ebx),%edi
f010100a:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
			pages[i].pp_link = page_free_list;
f0101010:	89 37                	mov    %esi,(%edi)
			page_free_list = &pages[i];
f0101012:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101015:	89 ce                	mov    %ecx,%esi
f0101017:	03 33                	add    (%ebx),%esi
f0101019:	bb 01 00 00 00       	mov    $0x1,%ebx
	for(size_t i = 0;i<npages;i++)
f010101e:	83 c0 01             	add    $0x1,%eax
f0101021:	39 02                	cmp    %eax,(%edx)
f0101023:	76 17                	jbe    f010103c <page_init+0xc6>
		if(i == 0)
f0101025:	85 c0                	test   %eax,%eax
f0101027:	75 b3                	jne    f0100fdc <page_init+0x66>
			pages[i].pp_ref = 1;
f0101029:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010102c:	8b 0f                	mov    (%edi),%ecx
f010102e:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f0101034:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f010103a:	eb e2                	jmp    f010101e <page_init+0xa8>
f010103c:	84 db                	test   %bl,%bl
f010103e:	74 09                	je     f0101049 <page_init+0xd3>
f0101040:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101043:	89 b0 24 23 00 00    	mov    %esi,0x2324(%eax)
}
f0101049:	83 c4 2c             	add    $0x2c,%esp
f010104c:	5b                   	pop    %ebx
f010104d:	5e                   	pop    %esi
f010104e:	5f                   	pop    %edi
f010104f:	5d                   	pop    %ebp
f0101050:	c3                   	ret    

f0101051 <page_alloc>:
{
f0101051:	f3 0f 1e fb          	endbr32 
f0101055:	55                   	push   %ebp
f0101056:	89 e5                	mov    %esp,%ebp
f0101058:	56                   	push   %esi
f0101059:	53                   	push   %ebx
f010105a:	e8 14 f1 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f010105f:	81 c3 bd bf 08 00    	add    $0x8bfbd,%ebx
	if(page_free_list == NULL)
f0101065:	8b b3 24 23 00 00    	mov    0x2324(%ebx),%esi
f010106b:	85 f6                	test   %esi,%esi
f010106d:	74 37                	je     f01010a6 <page_alloc+0x55>
	page_free_list = page_free_list->pp_link;
f010106f:	8b 06                	mov    (%esi),%eax
f0101071:	89 83 24 23 00 00    	mov    %eax,0x2324(%ebx)
	alloc->pp_link = NULL;
f0101077:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
f010107d:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f0101083:	89 f1                	mov    %esi,%ecx
f0101085:	2b 08                	sub    (%eax),%ecx
f0101087:	89 c8                	mov    %ecx,%eax
f0101089:	c1 f8 03             	sar    $0x3,%eax
f010108c:	89 c1                	mov    %eax,%ecx
f010108e:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f0101091:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101096:	c7 c2 08 00 19 f0    	mov    $0xf0190008,%edx
f010109c:	3b 02                	cmp    (%edx),%eax
f010109e:	73 0f                	jae    f01010af <page_alloc+0x5e>
	if(alloc_flags & ALLOC_ZERO)
f01010a0:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f01010a4:	75 1f                	jne    f01010c5 <page_alloc+0x74>
}
f01010a6:	89 f0                	mov    %esi,%eax
f01010a8:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01010ab:	5b                   	pop    %ebx
f01010ac:	5e                   	pop    %esi
f01010ad:	5d                   	pop    %ebp
f01010ae:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010af:	51                   	push   %ecx
f01010b0:	8d 83 e4 89 f7 ff    	lea    -0x8761c(%ebx),%eax
f01010b6:	50                   	push   %eax
f01010b7:	6a 56                	push   $0x56
f01010b9:	8d 83 19 92 f7 ff    	lea    -0x86de7(%ebx),%eax
f01010bf:	50                   	push   %eax
f01010c0:	e8 f0 ef ff ff       	call   f01000b5 <_panic>
		memset(head,0,PGSIZE);
f01010c5:	83 ec 04             	sub    $0x4,%esp
f01010c8:	68 00 10 00 00       	push   $0x1000
f01010cd:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f01010cf:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f01010d5:	51                   	push   %ecx
f01010d6:	e8 c4 3f 00 00       	call   f010509f <memset>
f01010db:	83 c4 10             	add    $0x10,%esp
f01010de:	eb c6                	jmp    f01010a6 <page_alloc+0x55>

f01010e0 <page_free>:
{
f01010e0:	f3 0f 1e fb          	endbr32 
f01010e4:	55                   	push   %ebp
f01010e5:	89 e5                	mov    %esp,%ebp
f01010e7:	53                   	push   %ebx
f01010e8:	83 ec 04             	sub    $0x4,%esp
f01010eb:	e8 83 f0 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01010f0:	81 c3 2c bf 08 00    	add    $0x8bf2c,%ebx
f01010f6:	8b 45 08             	mov    0x8(%ebp),%eax
	if((pp->pp_ref != 0) | (pp->pp_link != NULL))  // referenced or freed
f01010f9:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01010fe:	75 18                	jne    f0101118 <page_free+0x38>
f0101100:	83 38 00             	cmpl   $0x0,(%eax)
f0101103:	75 13                	jne    f0101118 <page_free+0x38>
	pp->pp_link = page_free_list;
f0101105:	8b 8b 24 23 00 00    	mov    0x2324(%ebx),%ecx
f010110b:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f010110d:	89 83 24 23 00 00    	mov    %eax,0x2324(%ebx)
}
f0101113:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101116:	c9                   	leave  
f0101117:	c3                   	ret    
		panic("at pmap.c:page_free(): Page double free or freeing a referenced page");
f0101118:	83 ec 04             	sub    $0x4,%esp
f010111b:	8d 83 f0 8a f7 ff    	lea    -0x87510(%ebx),%eax
f0101121:	50                   	push   %eax
f0101122:	68 7c 01 00 00       	push   $0x17c
f0101127:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f010112d:	50                   	push   %eax
f010112e:	e8 82 ef ff ff       	call   f01000b5 <_panic>

f0101133 <page_decref>:
{
f0101133:	f3 0f 1e fb          	endbr32 
f0101137:	55                   	push   %ebp
f0101138:	89 e5                	mov    %esp,%ebp
f010113a:	83 ec 08             	sub    $0x8,%esp
f010113d:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101140:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101144:	83 e8 01             	sub    $0x1,%eax
f0101147:	66 89 42 04          	mov    %ax,0x4(%edx)
f010114b:	66 85 c0             	test   %ax,%ax
f010114e:	74 02                	je     f0101152 <page_decref+0x1f>
}
f0101150:	c9                   	leave  
f0101151:	c3                   	ret    
		page_free(pp);
f0101152:	83 ec 0c             	sub    $0xc,%esp
f0101155:	52                   	push   %edx
f0101156:	e8 85 ff ff ff       	call   f01010e0 <page_free>
f010115b:	83 c4 10             	add    $0x10,%esp
}
f010115e:	eb f0                	jmp    f0101150 <page_decref+0x1d>

f0101160 <pgdir_walk>:
{
f0101160:	f3 0f 1e fb          	endbr32 
f0101164:	55                   	push   %ebp
f0101165:	89 e5                	mov    %esp,%ebp
f0101167:	57                   	push   %edi
f0101168:	56                   	push   %esi
f0101169:	53                   	push   %ebx
f010116a:	83 ec 0c             	sub    $0xc,%esp
f010116d:	e8 ce 1f 00 00       	call   f0103140 <__x86.get_pc_thunk.di>
f0101172:	81 c7 aa be 08 00    	add    $0x8beaa,%edi
f0101178:	8b 75 0c             	mov    0xc(%ebp),%esi
	unsigned int dir_offset = PDX(va);
f010117b:	89 f3                	mov    %esi,%ebx
f010117d:	c1 eb 16             	shr    $0x16,%ebx
	pde_t* entry = pgdir+dir_offset;
f0101180:	c1 e3 02             	shl    $0x2,%ebx
f0101183:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*entry & PTE_P))
f0101186:	f6 03 01             	testb  $0x1,(%ebx)
f0101189:	75 2f                	jne    f01011ba <pgdir_walk+0x5a>
		if(create)
f010118b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010118f:	74 73                	je     f0101204 <pgdir_walk+0xa4>
			new_page = page_alloc(1);
f0101191:	83 ec 0c             	sub    $0xc,%esp
f0101194:	6a 01                	push   $0x1
f0101196:	e8 b6 fe ff ff       	call   f0101051 <page_alloc>
			if(new_page == NULL)
f010119b:	83 c4 10             	add    $0x10,%esp
f010119e:	85 c0                	test   %eax,%eax
f01011a0:	74 3f                	je     f01011e1 <pgdir_walk+0x81>
			new_page->pp_ref++;
f01011a2:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f01011a7:	c7 c2 10 00 19 f0    	mov    $0xf0190010,%edx
f01011ad:	2b 02                	sub    (%edx),%eax
f01011af:	c1 f8 03             	sar    $0x3,%eax
f01011b2:	c1 e0 0c             	shl    $0xc,%eax
			*entry = ((page2pa(new_page))|PTE_P|PTE_W|PTE_U);
f01011b5:	83 c8 07             	or     $0x7,%eax
f01011b8:	89 03                	mov    %eax,(%ebx)
	page_base = (pte_t*)KADDR(PTE_ADDR(*entry));
f01011ba:	8b 03                	mov    (%ebx),%eax
f01011bc:	89 c2                	mov    %eax,%edx
f01011be:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f01011c4:	c1 e8 0c             	shr    $0xc,%eax
f01011c7:	c7 c1 08 00 19 f0    	mov    $0xf0190008,%ecx
f01011cd:	3b 01                	cmp    (%ecx),%eax
f01011cf:	73 18                	jae    f01011e9 <pgdir_walk+0x89>
	page_offset = PTX(va);
f01011d1:	c1 ee 0a             	shr    $0xa,%esi
	return &page_base[page_offset];
f01011d4:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01011da:	8d 84 32 00 00 00 f0 	lea    -0x10000000(%edx,%esi,1),%eax
}
f01011e1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011e4:	5b                   	pop    %ebx
f01011e5:	5e                   	pop    %esi
f01011e6:	5f                   	pop    %edi
f01011e7:	5d                   	pop    %ebp
f01011e8:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011e9:	52                   	push   %edx
f01011ea:	8d 87 e4 89 f7 ff    	lea    -0x8761c(%edi),%eax
f01011f0:	50                   	push   %eax
f01011f1:	68 c9 01 00 00       	push   $0x1c9
f01011f6:	8d 87 0d 92 f7 ff    	lea    -0x86df3(%edi),%eax
f01011fc:	50                   	push   %eax
f01011fd:	89 fb                	mov    %edi,%ebx
f01011ff:	e8 b1 ee ff ff       	call   f01000b5 <_panic>
			return NULL;
f0101204:	b8 00 00 00 00       	mov    $0x0,%eax
f0101209:	eb d6                	jmp    f01011e1 <pgdir_walk+0x81>

f010120b <boot_map_region>:
{
f010120b:	55                   	push   %ebp
f010120c:	89 e5                	mov    %esp,%ebp
f010120e:	57                   	push   %edi
f010120f:	56                   	push   %esi
f0101210:	53                   	push   %ebx
f0101211:	83 ec 1c             	sub    $0x1c,%esp
f0101214:	89 c7                	mov    %eax,%edi
f0101216:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101219:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for(add = 0;add<size;add+=PGSIZE)
f010121c:	be 00 00 00 00       	mov    $0x0,%esi
f0101221:	89 f3                	mov    %esi,%ebx
f0101223:	03 5d 08             	add    0x8(%ebp),%ebx
f0101226:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f0101229:	76 24                	jbe    f010124f <boot_map_region+0x44>
		entry = pgdir_walk(pgdir,(void*)va,1);  // get the entry of page table
f010122b:	83 ec 04             	sub    $0x4,%esp
f010122e:	6a 01                	push   $0x1
f0101230:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101233:	01 f0                	add    %esi,%eax
f0101235:	50                   	push   %eax
f0101236:	57                   	push   %edi
f0101237:	e8 24 ff ff ff       	call   f0101160 <pgdir_walk>
		*entry = (pa|perm|PTE_P);
f010123c:	0b 5d 0c             	or     0xc(%ebp),%ebx
f010123f:	83 cb 01             	or     $0x1,%ebx
f0101242:	89 18                	mov    %ebx,(%eax)
	for(add = 0;add<size;add+=PGSIZE)
f0101244:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010124a:	83 c4 10             	add    $0x10,%esp
f010124d:	eb d2                	jmp    f0101221 <boot_map_region+0x16>
}
f010124f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101252:	5b                   	pop    %ebx
f0101253:	5e                   	pop    %esi
f0101254:	5f                   	pop    %edi
f0101255:	5d                   	pop    %ebp
f0101256:	c3                   	ret    

f0101257 <page_lookup>:
{
f0101257:	f3 0f 1e fb          	endbr32 
f010125b:	55                   	push   %ebp
f010125c:	89 e5                	mov    %esp,%ebp
f010125e:	56                   	push   %esi
f010125f:	53                   	push   %ebx
f0101260:	e8 0e ef ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0101265:	81 c3 b7 bd 08 00    	add    $0x8bdb7,%ebx
f010126b:	8b 75 10             	mov    0x10(%ebp),%esi
	entry = pgdir_walk(pgdir,va,0);
f010126e:	83 ec 04             	sub    $0x4,%esp
f0101271:	6a 00                	push   $0x0
f0101273:	ff 75 0c             	pushl  0xc(%ebp)
f0101276:	ff 75 08             	pushl  0x8(%ebp)
f0101279:	e8 e2 fe ff ff       	call   f0101160 <pgdir_walk>
	if(entry == NULL)
f010127e:	83 c4 10             	add    $0x10,%esp
f0101281:	85 c0                	test   %eax,%eax
f0101283:	74 46                	je     f01012cb <page_lookup+0x74>
	if(!(*entry & PTE_P))
f0101285:	8b 10                	mov    (%eax),%edx
f0101287:	f6 c2 01             	test   $0x1,%dl
f010128a:	74 43                	je     f01012cf <page_lookup+0x78>
f010128c:	c1 ea 0c             	shr    $0xc,%edx
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010128f:	c7 c1 08 00 19 f0    	mov    $0xf0190008,%ecx
f0101295:	39 11                	cmp    %edx,(%ecx)
f0101297:	76 1a                	jbe    f01012b3 <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f0101299:	c7 c1 10 00 19 f0    	mov    $0xf0190010,%ecx
f010129f:	8b 09                	mov    (%ecx),%ecx
f01012a1:	8d 14 d1             	lea    (%ecx,%edx,8),%edx
	if(pte_store != NULL)
f01012a4:	85 f6                	test   %esi,%esi
f01012a6:	74 02                	je     f01012aa <page_lookup+0x53>
		*pte_store = entry;
f01012a8:	89 06                	mov    %eax,(%esi)
}
f01012aa:	89 d0                	mov    %edx,%eax
f01012ac:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01012af:	5b                   	pop    %ebx
f01012b0:	5e                   	pop    %esi
f01012b1:	5d                   	pop    %ebp
f01012b2:	c3                   	ret    
		panic("pa2page called with invalid pa");
f01012b3:	83 ec 04             	sub    $0x4,%esp
f01012b6:	8d 83 38 8b f7 ff    	lea    -0x874c8(%ebx),%eax
f01012bc:	50                   	push   %eax
f01012bd:	6a 4f                	push   $0x4f
f01012bf:	8d 83 19 92 f7 ff    	lea    -0x86de7(%ebx),%eax
f01012c5:	50                   	push   %eax
f01012c6:	e8 ea ed ff ff       	call   f01000b5 <_panic>
		return NULL;
f01012cb:	89 c2                	mov    %eax,%edx
f01012cd:	eb db                	jmp    f01012aa <page_lookup+0x53>
		return NULL;
f01012cf:	ba 00 00 00 00       	mov    $0x0,%edx
f01012d4:	eb d4                	jmp    f01012aa <page_lookup+0x53>

f01012d6 <page_remove>:
{
f01012d6:	f3 0f 1e fb          	endbr32 
f01012da:	55                   	push   %ebp
f01012db:	89 e5                	mov    %esp,%ebp
f01012dd:	53                   	push   %ebx
f01012de:	83 ec 18             	sub    $0x18,%esp
f01012e1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t* pte = NULL;
f01012e4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo* page = page_lookup(pgdir,va,&pte);
f01012eb:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01012ee:	50                   	push   %eax
f01012ef:	53                   	push   %ebx
f01012f0:	ff 75 08             	pushl  0x8(%ebp)
f01012f3:	e8 5f ff ff ff       	call   f0101257 <page_lookup>
	if(page == NULL)
f01012f8:	83 c4 10             	add    $0x10,%esp
f01012fb:	85 c0                	test   %eax,%eax
f01012fd:	74 18                	je     f0101317 <page_remove+0x41>
	page_decref(page);
f01012ff:	83 ec 0c             	sub    $0xc,%esp
f0101302:	50                   	push   %eax
f0101303:	e8 2b fe ff ff       	call   f0101133 <page_decref>
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101308:	0f 01 3b             	invlpg (%ebx)
	*pte = 0;
f010130b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010130e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101314:	83 c4 10             	add    $0x10,%esp
}
f0101317:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010131a:	c9                   	leave  
f010131b:	c3                   	ret    

f010131c <page_insert>:
{
f010131c:	f3 0f 1e fb          	endbr32 
f0101320:	55                   	push   %ebp
f0101321:	89 e5                	mov    %esp,%ebp
f0101323:	57                   	push   %edi
f0101324:	56                   	push   %esi
f0101325:	53                   	push   %ebx
f0101326:	83 ec 10             	sub    $0x10,%esp
f0101329:	e8 12 1e 00 00       	call   f0103140 <__x86.get_pc_thunk.di>
f010132e:	81 c7 ee bc 08 00    	add    $0x8bcee,%edi
f0101334:	8b 75 08             	mov    0x8(%ebp),%esi
	entry = pgdir_walk(pgdir,va,1); // get the page table entry 
f0101337:	6a 01                	push   $0x1
f0101339:	ff 75 10             	pushl  0x10(%ebp)
f010133c:	56                   	push   %esi
f010133d:	e8 1e fe ff ff       	call   f0101160 <pgdir_walk>
	if(entry == NULL)
f0101342:	83 c4 10             	add    $0x10,%esp
f0101345:	85 c0                	test   %eax,%eax
f0101347:	74 5a                	je     f01013a3 <page_insert+0x87>
f0101349:	89 c3                	mov    %eax,%ebx
	pp->pp_ref++;
f010134b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010134e:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	if(*entry&PTE_P)
f0101353:	f6 03 01             	testb  $0x1,(%ebx)
f0101356:	75 34                	jne    f010138c <page_insert+0x70>
	return (pp - pages) << PGSHIFT;
f0101358:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f010135e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101361:	2b 10                	sub    (%eax),%edx
f0101363:	89 d0                	mov    %edx,%eax
f0101365:	c1 f8 03             	sar    $0x3,%eax
f0101368:	c1 e0 0c             	shl    $0xc,%eax
	*entry = ((page2pa(pp))|perm|PTE_P);
f010136b:	0b 45 14             	or     0x14(%ebp),%eax
f010136e:	83 c8 01             	or     $0x1,%eax
f0101371:	89 03                	mov    %eax,(%ebx)
	pgdir[PDX(va)] |= perm;
f0101373:	8b 45 10             	mov    0x10(%ebp),%eax
f0101376:	c1 e8 16             	shr    $0x16,%eax
f0101379:	8b 4d 14             	mov    0x14(%ebp),%ecx
f010137c:	09 0c 86             	or     %ecx,(%esi,%eax,4)
	return 0;
f010137f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101384:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101387:	5b                   	pop    %ebx
f0101388:	5e                   	pop    %esi
f0101389:	5f                   	pop    %edi
f010138a:	5d                   	pop    %ebp
f010138b:	c3                   	ret    
f010138c:	8b 45 10             	mov    0x10(%ebp),%eax
f010138f:	0f 01 38             	invlpg (%eax)
		page_remove(pgdir,va);
f0101392:	83 ec 08             	sub    $0x8,%esp
f0101395:	ff 75 10             	pushl  0x10(%ebp)
f0101398:	56                   	push   %esi
f0101399:	e8 38 ff ff ff       	call   f01012d6 <page_remove>
f010139e:	83 c4 10             	add    $0x10,%esp
f01013a1:	eb b5                	jmp    f0101358 <page_insert+0x3c>
		return -E_NO_MEM;
f01013a3:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01013a8:	eb da                	jmp    f0101384 <page_insert+0x68>

f01013aa <mem_init>:
{
f01013aa:	f3 0f 1e fb          	endbr32 
f01013ae:	55                   	push   %ebp
f01013af:	89 e5                	mov    %esp,%ebp
f01013b1:	57                   	push   %edi
f01013b2:	56                   	push   %esi
f01013b3:	53                   	push   %ebx
f01013b4:	83 ec 3c             	sub    $0x3c,%esp
f01013b7:	e8 b7 ed ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01013bc:	81 c3 60 bc 08 00    	add    $0x8bc60,%ebx
	basemem = nvram_read(NVRAM_BASELO);
f01013c2:	b8 15 00 00 00       	mov    $0x15,%eax
f01013c7:	e8 ef f6 ff ff       	call   f0100abb <nvram_read>
f01013cc:	89 c6                	mov    %eax,%esi
	extmem = nvram_read(NVRAM_EXTLO);
f01013ce:	b8 17 00 00 00       	mov    $0x17,%eax
f01013d3:	e8 e3 f6 ff ff       	call   f0100abb <nvram_read>
f01013d8:	89 c7                	mov    %eax,%edi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01013da:	b8 34 00 00 00       	mov    $0x34,%eax
f01013df:	e8 d7 f6 ff ff       	call   f0100abb <nvram_read>
	if (ext16mem)
f01013e4:	c1 e0 06             	shl    $0x6,%eax
f01013e7:	0f 84 ec 00 00 00    	je     f01014d9 <mem_init+0x12f>
		totalmem = 16 * 1024 + ext16mem;
f01013ed:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f01013f2:	89 c1                	mov    %eax,%ecx
f01013f4:	c1 e9 02             	shr    $0x2,%ecx
f01013f7:	c7 c2 08 00 19 f0    	mov    $0xf0190008,%edx
f01013fd:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f01013ff:	89 f2                	mov    %esi,%edx
f0101401:	c1 ea 02             	shr    $0x2,%edx
f0101404:	89 93 28 23 00 00    	mov    %edx,0x2328(%ebx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010140a:	89 c2                	mov    %eax,%edx
f010140c:	29 f2                	sub    %esi,%edx
f010140e:	52                   	push   %edx
f010140f:	56                   	push   %esi
f0101410:	50                   	push   %eax
f0101411:	8d 83 58 8b f7 ff    	lea    -0x874a8(%ebx),%eax
f0101417:	50                   	push   %eax
f0101418:	e8 d8 25 00 00       	call   f01039f5 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010141d:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101422:	e8 ca f6 ff ff       	call   f0100af1 <boot_alloc>
f0101427:	c7 c6 0c 00 19 f0    	mov    $0xf019000c,%esi
f010142d:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f010142f:	83 c4 0c             	add    $0xc,%esp
f0101432:	68 00 10 00 00       	push   $0x1000
f0101437:	6a 00                	push   $0x0
f0101439:	50                   	push   %eax
f010143a:	e8 60 3c 00 00       	call   f010509f <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010143f:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f0101441:	83 c4 10             	add    $0x10,%esp
f0101444:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101449:	0f 86 9a 00 00 00    	jbe    f01014e9 <mem_init+0x13f>
	return (physaddr_t)kva - KERNBASE;
f010144f:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101455:	83 ca 05             	or     $0x5,%edx
f0101458:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages*sizeof(struct PageInfo));
f010145e:	c7 c7 08 00 19 f0    	mov    $0xf0190008,%edi
f0101464:	8b 07                	mov    (%edi),%eax
f0101466:	c1 e0 03             	shl    $0x3,%eax
f0101469:	e8 83 f6 ff ff       	call   f0100af1 <boot_alloc>
f010146e:	c7 c6 10 00 19 f0    	mov    $0xf0190010,%esi
f0101474:	89 06                	mov    %eax,(%esi)
	memset(pages,0,npages*sizeof(struct PageInfo));
f0101476:	83 ec 04             	sub    $0x4,%esp
f0101479:	8b 17                	mov    (%edi),%edx
f010147b:	c1 e2 03             	shl    $0x3,%edx
f010147e:	52                   	push   %edx
f010147f:	6a 00                	push   $0x0
f0101481:	50                   	push   %eax
f0101482:	e8 18 3c 00 00       	call   f010509f <memset>
	envs = (struct Env*)boot_alloc(NENV*sizeof(struct Env));
f0101487:	b8 00 80 01 00       	mov    $0x18000,%eax
f010148c:	e8 60 f6 ff ff       	call   f0100af1 <boot_alloc>
f0101491:	c7 c2 4c f3 18 f0    	mov    $0xf018f34c,%edx
f0101497:	89 02                	mov    %eax,(%edx)
	memset(envs,0,NENV*sizeof(struct Env));
f0101499:	83 c4 0c             	add    $0xc,%esp
f010149c:	68 00 80 01 00       	push   $0x18000
f01014a1:	6a 00                	push   $0x0
f01014a3:	50                   	push   %eax
f01014a4:	e8 f6 3b 00 00       	call   f010509f <memset>
	page_init();
f01014a9:	e8 c8 fa ff ff       	call   f0100f76 <page_init>
	check_page_free_list(1);
f01014ae:	b8 01 00 00 00       	mov    $0x1,%eax
f01014b3:	e8 44 f7 ff ff       	call   f0100bfc <check_page_free_list>
	if (!pages)
f01014b8:	83 c4 10             	add    $0x10,%esp
f01014bb:	83 3e 00             	cmpl   $0x0,(%esi)
f01014be:	74 42                	je     f0101502 <mem_init+0x158>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014c0:	8b 83 24 23 00 00    	mov    0x2324(%ebx),%eax
f01014c6:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f01014cd:	85 c0                	test   %eax,%eax
f01014cf:	74 4c                	je     f010151d <mem_init+0x173>
		++nfree;
f01014d1:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014d5:	8b 00                	mov    (%eax),%eax
f01014d7:	eb f4                	jmp    f01014cd <mem_init+0x123>
		totalmem = 1 * 1024 + extmem;
f01014d9:	8d 87 00 04 00 00    	lea    0x400(%edi),%eax
f01014df:	85 ff                	test   %edi,%edi
f01014e1:	0f 44 c6             	cmove  %esi,%eax
f01014e4:	e9 09 ff ff ff       	jmp    f01013f2 <mem_init+0x48>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01014e9:	50                   	push   %eax
f01014ea:	8d 83 94 8b f7 ff    	lea    -0x8746c(%ebx),%eax
f01014f0:	50                   	push   %eax
f01014f1:	68 a2 00 00 00       	push   $0xa2
f01014f6:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01014fc:	50                   	push   %eax
f01014fd:	e8 b3 eb ff ff       	call   f01000b5 <_panic>
		panic("'pages' is a null pointer!");
f0101502:	83 ec 04             	sub    $0x4,%esp
f0101505:	8d 83 c3 92 f7 ff    	lea    -0x86d3d(%ebx),%eax
f010150b:	50                   	push   %eax
f010150c:	68 16 03 00 00       	push   $0x316
f0101511:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0101517:	50                   	push   %eax
f0101518:	e8 98 eb ff ff       	call   f01000b5 <_panic>
	assert((pp0 = page_alloc(0)));
f010151d:	83 ec 0c             	sub    $0xc,%esp
f0101520:	6a 00                	push   $0x0
f0101522:	e8 2a fb ff ff       	call   f0101051 <page_alloc>
f0101527:	89 c6                	mov    %eax,%esi
f0101529:	83 c4 10             	add    $0x10,%esp
f010152c:	85 c0                	test   %eax,%eax
f010152e:	0f 84 31 02 00 00    	je     f0101765 <mem_init+0x3bb>
	assert((pp1 = page_alloc(0)));
f0101534:	83 ec 0c             	sub    $0xc,%esp
f0101537:	6a 00                	push   $0x0
f0101539:	e8 13 fb ff ff       	call   f0101051 <page_alloc>
f010153e:	89 c7                	mov    %eax,%edi
f0101540:	83 c4 10             	add    $0x10,%esp
f0101543:	85 c0                	test   %eax,%eax
f0101545:	0f 84 39 02 00 00    	je     f0101784 <mem_init+0x3da>
	assert((pp2 = page_alloc(0)));
f010154b:	83 ec 0c             	sub    $0xc,%esp
f010154e:	6a 00                	push   $0x0
f0101550:	e8 fc fa ff ff       	call   f0101051 <page_alloc>
f0101555:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101558:	83 c4 10             	add    $0x10,%esp
f010155b:	85 c0                	test   %eax,%eax
f010155d:	0f 84 40 02 00 00    	je     f01017a3 <mem_init+0x3f9>
	assert(pp1 && pp1 != pp0);
f0101563:	39 fe                	cmp    %edi,%esi
f0101565:	0f 84 57 02 00 00    	je     f01017c2 <mem_init+0x418>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010156b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010156e:	39 c7                	cmp    %eax,%edi
f0101570:	0f 84 6b 02 00 00    	je     f01017e1 <mem_init+0x437>
f0101576:	39 c6                	cmp    %eax,%esi
f0101578:	0f 84 63 02 00 00    	je     f01017e1 <mem_init+0x437>
	return (pp - pages) << PGSHIFT;
f010157e:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f0101584:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101586:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f010158c:	8b 10                	mov    (%eax),%edx
f010158e:	c1 e2 0c             	shl    $0xc,%edx
f0101591:	89 f0                	mov    %esi,%eax
f0101593:	29 c8                	sub    %ecx,%eax
f0101595:	c1 f8 03             	sar    $0x3,%eax
f0101598:	c1 e0 0c             	shl    $0xc,%eax
f010159b:	39 d0                	cmp    %edx,%eax
f010159d:	0f 83 5d 02 00 00    	jae    f0101800 <mem_init+0x456>
f01015a3:	89 f8                	mov    %edi,%eax
f01015a5:	29 c8                	sub    %ecx,%eax
f01015a7:	c1 f8 03             	sar    $0x3,%eax
f01015aa:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f01015ad:	39 c2                	cmp    %eax,%edx
f01015af:	0f 86 6a 02 00 00    	jbe    f010181f <mem_init+0x475>
f01015b5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015b8:	29 c8                	sub    %ecx,%eax
f01015ba:	c1 f8 03             	sar    $0x3,%eax
f01015bd:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01015c0:	39 c2                	cmp    %eax,%edx
f01015c2:	0f 86 76 02 00 00    	jbe    f010183e <mem_init+0x494>
	fl = page_free_list;
f01015c8:	8b 83 24 23 00 00    	mov    0x2324(%ebx),%eax
f01015ce:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f01015d1:	c7 83 24 23 00 00 00 	movl   $0x0,0x2324(%ebx)
f01015d8:	00 00 00 
	assert(!page_alloc(0));
f01015db:	83 ec 0c             	sub    $0xc,%esp
f01015de:	6a 00                	push   $0x0
f01015e0:	e8 6c fa ff ff       	call   f0101051 <page_alloc>
f01015e5:	83 c4 10             	add    $0x10,%esp
f01015e8:	85 c0                	test   %eax,%eax
f01015ea:	0f 85 6d 02 00 00    	jne    f010185d <mem_init+0x4b3>
	page_free(pp0);
f01015f0:	83 ec 0c             	sub    $0xc,%esp
f01015f3:	56                   	push   %esi
f01015f4:	e8 e7 fa ff ff       	call   f01010e0 <page_free>
	page_free(pp1);
f01015f9:	89 3c 24             	mov    %edi,(%esp)
f01015fc:	e8 df fa ff ff       	call   f01010e0 <page_free>
	page_free(pp2);
f0101601:	83 c4 04             	add    $0x4,%esp
f0101604:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101607:	e8 d4 fa ff ff       	call   f01010e0 <page_free>
	assert((pp0 = page_alloc(0)));
f010160c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101613:	e8 39 fa ff ff       	call   f0101051 <page_alloc>
f0101618:	89 c6                	mov    %eax,%esi
f010161a:	83 c4 10             	add    $0x10,%esp
f010161d:	85 c0                	test   %eax,%eax
f010161f:	0f 84 57 02 00 00    	je     f010187c <mem_init+0x4d2>
	assert((pp1 = page_alloc(0)));
f0101625:	83 ec 0c             	sub    $0xc,%esp
f0101628:	6a 00                	push   $0x0
f010162a:	e8 22 fa ff ff       	call   f0101051 <page_alloc>
f010162f:	89 c7                	mov    %eax,%edi
f0101631:	83 c4 10             	add    $0x10,%esp
f0101634:	85 c0                	test   %eax,%eax
f0101636:	0f 84 5f 02 00 00    	je     f010189b <mem_init+0x4f1>
	assert((pp2 = page_alloc(0)));
f010163c:	83 ec 0c             	sub    $0xc,%esp
f010163f:	6a 00                	push   $0x0
f0101641:	e8 0b fa ff ff       	call   f0101051 <page_alloc>
f0101646:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101649:	83 c4 10             	add    $0x10,%esp
f010164c:	85 c0                	test   %eax,%eax
f010164e:	0f 84 66 02 00 00    	je     f01018ba <mem_init+0x510>
	assert(pp1 && pp1 != pp0);
f0101654:	39 fe                	cmp    %edi,%esi
f0101656:	0f 84 7d 02 00 00    	je     f01018d9 <mem_init+0x52f>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010165c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010165f:	39 c7                	cmp    %eax,%edi
f0101661:	0f 84 91 02 00 00    	je     f01018f8 <mem_init+0x54e>
f0101667:	39 c6                	cmp    %eax,%esi
f0101669:	0f 84 89 02 00 00    	je     f01018f8 <mem_init+0x54e>
	assert(!page_alloc(0));
f010166f:	83 ec 0c             	sub    $0xc,%esp
f0101672:	6a 00                	push   $0x0
f0101674:	e8 d8 f9 ff ff       	call   f0101051 <page_alloc>
f0101679:	83 c4 10             	add    $0x10,%esp
f010167c:	85 c0                	test   %eax,%eax
f010167e:	0f 85 93 02 00 00    	jne    f0101917 <mem_init+0x56d>
f0101684:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f010168a:	89 f1                	mov    %esi,%ecx
f010168c:	2b 08                	sub    (%eax),%ecx
f010168e:	89 c8                	mov    %ecx,%eax
f0101690:	c1 f8 03             	sar    $0x3,%eax
f0101693:	89 c2                	mov    %eax,%edx
f0101695:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101698:	25 ff ff 0f 00       	and    $0xfffff,%eax
f010169d:	c7 c1 08 00 19 f0    	mov    $0xf0190008,%ecx
f01016a3:	3b 01                	cmp    (%ecx),%eax
f01016a5:	0f 83 8b 02 00 00    	jae    f0101936 <mem_init+0x58c>
	memset(page2kva(pp0), 1, PGSIZE);
f01016ab:	83 ec 04             	sub    $0x4,%esp
f01016ae:	68 00 10 00 00       	push   $0x1000
f01016b3:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01016b5:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f01016bb:	52                   	push   %edx
f01016bc:	e8 de 39 00 00       	call   f010509f <memset>
	page_free(pp0);
f01016c1:	89 34 24             	mov    %esi,(%esp)
f01016c4:	e8 17 fa ff ff       	call   f01010e0 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016c9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016d0:	e8 7c f9 ff ff       	call   f0101051 <page_alloc>
f01016d5:	83 c4 10             	add    $0x10,%esp
f01016d8:	85 c0                	test   %eax,%eax
f01016da:	0f 84 6c 02 00 00    	je     f010194c <mem_init+0x5a2>
	assert(pp && pp0 == pp);
f01016e0:	39 c6                	cmp    %eax,%esi
f01016e2:	0f 85 83 02 00 00    	jne    f010196b <mem_init+0x5c1>
	return (pp - pages) << PGSHIFT;
f01016e8:	c7 c2 10 00 19 f0    	mov    $0xf0190010,%edx
f01016ee:	2b 02                	sub    (%edx),%eax
f01016f0:	c1 f8 03             	sar    $0x3,%eax
f01016f3:	89 c2                	mov    %eax,%edx
f01016f5:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01016f8:	25 ff ff 0f 00       	and    $0xfffff,%eax
f01016fd:	c7 c1 08 00 19 f0    	mov    $0xf0190008,%ecx
f0101703:	3b 01                	cmp    (%ecx),%eax
f0101705:	0f 83 7f 02 00 00    	jae    f010198a <mem_init+0x5e0>
	return (void *)(pa + KERNBASE);
f010170b:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f0101711:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f0101717:	80 38 00             	cmpb   $0x0,(%eax)
f010171a:	0f 85 80 02 00 00    	jne    f01019a0 <mem_init+0x5f6>
f0101720:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f0101723:	39 d0                	cmp    %edx,%eax
f0101725:	75 f0                	jne    f0101717 <mem_init+0x36d>
	page_free_list = fl;
f0101727:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010172a:	89 83 24 23 00 00    	mov    %eax,0x2324(%ebx)
	page_free(pp0);
f0101730:	83 ec 0c             	sub    $0xc,%esp
f0101733:	56                   	push   %esi
f0101734:	e8 a7 f9 ff ff       	call   f01010e0 <page_free>
	page_free(pp1);
f0101739:	89 3c 24             	mov    %edi,(%esp)
f010173c:	e8 9f f9 ff ff       	call   f01010e0 <page_free>
	page_free(pp2);
f0101741:	83 c4 04             	add    $0x4,%esp
f0101744:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101747:	e8 94 f9 ff ff       	call   f01010e0 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010174c:	8b 83 24 23 00 00    	mov    0x2324(%ebx),%eax
f0101752:	83 c4 10             	add    $0x10,%esp
f0101755:	85 c0                	test   %eax,%eax
f0101757:	0f 84 62 02 00 00    	je     f01019bf <mem_init+0x615>
		--nfree;
f010175d:	83 6d d0 01          	subl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101761:	8b 00                	mov    (%eax),%eax
f0101763:	eb f0                	jmp    f0101755 <mem_init+0x3ab>
	assert((pp0 = page_alloc(0)));
f0101765:	8d 83 de 92 f7 ff    	lea    -0x86d22(%ebx),%eax
f010176b:	50                   	push   %eax
f010176c:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0101772:	50                   	push   %eax
f0101773:	68 1e 03 00 00       	push   $0x31e
f0101778:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f010177e:	50                   	push   %eax
f010177f:	e8 31 e9 ff ff       	call   f01000b5 <_panic>
	assert((pp1 = page_alloc(0)));
f0101784:	8d 83 f4 92 f7 ff    	lea    -0x86d0c(%ebx),%eax
f010178a:	50                   	push   %eax
f010178b:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0101791:	50                   	push   %eax
f0101792:	68 1f 03 00 00       	push   $0x31f
f0101797:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f010179d:	50                   	push   %eax
f010179e:	e8 12 e9 ff ff       	call   f01000b5 <_panic>
	assert((pp2 = page_alloc(0)));
f01017a3:	8d 83 0a 93 f7 ff    	lea    -0x86cf6(%ebx),%eax
f01017a9:	50                   	push   %eax
f01017aa:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01017b0:	50                   	push   %eax
f01017b1:	68 20 03 00 00       	push   $0x320
f01017b6:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01017bc:	50                   	push   %eax
f01017bd:	e8 f3 e8 ff ff       	call   f01000b5 <_panic>
	assert(pp1 && pp1 != pp0);
f01017c2:	8d 83 20 93 f7 ff    	lea    -0x86ce0(%ebx),%eax
f01017c8:	50                   	push   %eax
f01017c9:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01017cf:	50                   	push   %eax
f01017d0:	68 23 03 00 00       	push   $0x323
f01017d5:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01017db:	50                   	push   %eax
f01017dc:	e8 d4 e8 ff ff       	call   f01000b5 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017e1:	8d 83 b8 8b f7 ff    	lea    -0x87448(%ebx),%eax
f01017e7:	50                   	push   %eax
f01017e8:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01017ee:	50                   	push   %eax
f01017ef:	68 24 03 00 00       	push   $0x324
f01017f4:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01017fa:	50                   	push   %eax
f01017fb:	e8 b5 e8 ff ff       	call   f01000b5 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101800:	8d 83 32 93 f7 ff    	lea    -0x86cce(%ebx),%eax
f0101806:	50                   	push   %eax
f0101807:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010180d:	50                   	push   %eax
f010180e:	68 25 03 00 00       	push   $0x325
f0101813:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0101819:	50                   	push   %eax
f010181a:	e8 96 e8 ff ff       	call   f01000b5 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010181f:	8d 83 4f 93 f7 ff    	lea    -0x86cb1(%ebx),%eax
f0101825:	50                   	push   %eax
f0101826:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010182c:	50                   	push   %eax
f010182d:	68 26 03 00 00       	push   $0x326
f0101832:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0101838:	50                   	push   %eax
f0101839:	e8 77 e8 ff ff       	call   f01000b5 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010183e:	8d 83 6c 93 f7 ff    	lea    -0x86c94(%ebx),%eax
f0101844:	50                   	push   %eax
f0101845:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010184b:	50                   	push   %eax
f010184c:	68 27 03 00 00       	push   $0x327
f0101851:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0101857:	50                   	push   %eax
f0101858:	e8 58 e8 ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f010185d:	8d 83 89 93 f7 ff    	lea    -0x86c77(%ebx),%eax
f0101863:	50                   	push   %eax
f0101864:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010186a:	50                   	push   %eax
f010186b:	68 2e 03 00 00       	push   $0x32e
f0101870:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0101876:	50                   	push   %eax
f0101877:	e8 39 e8 ff ff       	call   f01000b5 <_panic>
	assert((pp0 = page_alloc(0)));
f010187c:	8d 83 de 92 f7 ff    	lea    -0x86d22(%ebx),%eax
f0101882:	50                   	push   %eax
f0101883:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0101889:	50                   	push   %eax
f010188a:	68 35 03 00 00       	push   $0x335
f010188f:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0101895:	50                   	push   %eax
f0101896:	e8 1a e8 ff ff       	call   f01000b5 <_panic>
	assert((pp1 = page_alloc(0)));
f010189b:	8d 83 f4 92 f7 ff    	lea    -0x86d0c(%ebx),%eax
f01018a1:	50                   	push   %eax
f01018a2:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01018a8:	50                   	push   %eax
f01018a9:	68 36 03 00 00       	push   $0x336
f01018ae:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01018b4:	50                   	push   %eax
f01018b5:	e8 fb e7 ff ff       	call   f01000b5 <_panic>
	assert((pp2 = page_alloc(0)));
f01018ba:	8d 83 0a 93 f7 ff    	lea    -0x86cf6(%ebx),%eax
f01018c0:	50                   	push   %eax
f01018c1:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01018c7:	50                   	push   %eax
f01018c8:	68 37 03 00 00       	push   $0x337
f01018cd:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01018d3:	50                   	push   %eax
f01018d4:	e8 dc e7 ff ff       	call   f01000b5 <_panic>
	assert(pp1 && pp1 != pp0);
f01018d9:	8d 83 20 93 f7 ff    	lea    -0x86ce0(%ebx),%eax
f01018df:	50                   	push   %eax
f01018e0:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01018e6:	50                   	push   %eax
f01018e7:	68 39 03 00 00       	push   $0x339
f01018ec:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01018f2:	50                   	push   %eax
f01018f3:	e8 bd e7 ff ff       	call   f01000b5 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018f8:	8d 83 b8 8b f7 ff    	lea    -0x87448(%ebx),%eax
f01018fe:	50                   	push   %eax
f01018ff:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0101905:	50                   	push   %eax
f0101906:	68 3a 03 00 00       	push   $0x33a
f010190b:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0101911:	50                   	push   %eax
f0101912:	e8 9e e7 ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f0101917:	8d 83 89 93 f7 ff    	lea    -0x86c77(%ebx),%eax
f010191d:	50                   	push   %eax
f010191e:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0101924:	50                   	push   %eax
f0101925:	68 3b 03 00 00       	push   $0x33b
f010192a:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0101930:	50                   	push   %eax
f0101931:	e8 7f e7 ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101936:	52                   	push   %edx
f0101937:	8d 83 e4 89 f7 ff    	lea    -0x8761c(%ebx),%eax
f010193d:	50                   	push   %eax
f010193e:	6a 56                	push   $0x56
f0101940:	8d 83 19 92 f7 ff    	lea    -0x86de7(%ebx),%eax
f0101946:	50                   	push   %eax
f0101947:	e8 69 e7 ff ff       	call   f01000b5 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010194c:	8d 83 98 93 f7 ff    	lea    -0x86c68(%ebx),%eax
f0101952:	50                   	push   %eax
f0101953:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0101959:	50                   	push   %eax
f010195a:	68 40 03 00 00       	push   $0x340
f010195f:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0101965:	50                   	push   %eax
f0101966:	e8 4a e7 ff ff       	call   f01000b5 <_panic>
	assert(pp && pp0 == pp);
f010196b:	8d 83 b6 93 f7 ff    	lea    -0x86c4a(%ebx),%eax
f0101971:	50                   	push   %eax
f0101972:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0101978:	50                   	push   %eax
f0101979:	68 41 03 00 00       	push   $0x341
f010197e:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0101984:	50                   	push   %eax
f0101985:	e8 2b e7 ff ff       	call   f01000b5 <_panic>
f010198a:	52                   	push   %edx
f010198b:	8d 83 e4 89 f7 ff    	lea    -0x8761c(%ebx),%eax
f0101991:	50                   	push   %eax
f0101992:	6a 56                	push   $0x56
f0101994:	8d 83 19 92 f7 ff    	lea    -0x86de7(%ebx),%eax
f010199a:	50                   	push   %eax
f010199b:	e8 15 e7 ff ff       	call   f01000b5 <_panic>
		assert(c[i] == 0);
f01019a0:	8d 83 c6 93 f7 ff    	lea    -0x86c3a(%ebx),%eax
f01019a6:	50                   	push   %eax
f01019a7:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01019ad:	50                   	push   %eax
f01019ae:	68 44 03 00 00       	push   $0x344
f01019b3:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01019b9:	50                   	push   %eax
f01019ba:	e8 f6 e6 ff ff       	call   f01000b5 <_panic>
	assert(nfree == 0);
f01019bf:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01019c3:	0f 85 7f 08 00 00    	jne    f0102248 <mem_init+0xe9e>
	cprintf("check_page_alloc() succeeded!\n");
f01019c9:	83 ec 0c             	sub    $0xc,%esp
f01019cc:	8d 83 d8 8b f7 ff    	lea    -0x87428(%ebx),%eax
f01019d2:	50                   	push   %eax
f01019d3:	e8 1d 20 00 00       	call   f01039f5 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01019d8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019df:	e8 6d f6 ff ff       	call   f0101051 <page_alloc>
f01019e4:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01019e7:	83 c4 10             	add    $0x10,%esp
f01019ea:	85 c0                	test   %eax,%eax
f01019ec:	0f 84 75 08 00 00    	je     f0102267 <mem_init+0xebd>
	assert((pp1 = page_alloc(0)));
f01019f2:	83 ec 0c             	sub    $0xc,%esp
f01019f5:	6a 00                	push   $0x0
f01019f7:	e8 55 f6 ff ff       	call   f0101051 <page_alloc>
f01019fc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01019ff:	83 c4 10             	add    $0x10,%esp
f0101a02:	85 c0                	test   %eax,%eax
f0101a04:	0f 84 7c 08 00 00    	je     f0102286 <mem_init+0xedc>
	assert((pp2 = page_alloc(0)));
f0101a0a:	83 ec 0c             	sub    $0xc,%esp
f0101a0d:	6a 00                	push   $0x0
f0101a0f:	e8 3d f6 ff ff       	call   f0101051 <page_alloc>
f0101a14:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101a17:	83 c4 10             	add    $0x10,%esp
f0101a1a:	85 c0                	test   %eax,%eax
f0101a1c:	0f 84 83 08 00 00    	je     f01022a5 <mem_init+0xefb>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a22:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101a25:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0101a28:	0f 84 96 08 00 00    	je     f01022c4 <mem_init+0xf1a>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a2e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a31:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101a34:	0f 84 a9 08 00 00    	je     f01022e3 <mem_init+0xf39>
f0101a3a:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101a3d:	0f 84 a0 08 00 00    	je     f01022e3 <mem_init+0xf39>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a43:	8b 83 24 23 00 00    	mov    0x2324(%ebx),%eax
f0101a49:	89 45 c8             	mov    %eax,-0x38(%ebp)
	page_free_list = 0;
f0101a4c:	c7 83 24 23 00 00 00 	movl   $0x0,0x2324(%ebx)
f0101a53:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a56:	83 ec 0c             	sub    $0xc,%esp
f0101a59:	6a 00                	push   $0x0
f0101a5b:	e8 f1 f5 ff ff       	call   f0101051 <page_alloc>
f0101a60:	83 c4 10             	add    $0x10,%esp
f0101a63:	85 c0                	test   %eax,%eax
f0101a65:	0f 85 97 08 00 00    	jne    f0102302 <mem_init+0xf58>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a6b:	83 ec 04             	sub    $0x4,%esp
f0101a6e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a71:	50                   	push   %eax
f0101a72:	6a 00                	push   $0x0
f0101a74:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101a7a:	ff 30                	pushl  (%eax)
f0101a7c:	e8 d6 f7 ff ff       	call   f0101257 <page_lookup>
f0101a81:	83 c4 10             	add    $0x10,%esp
f0101a84:	85 c0                	test   %eax,%eax
f0101a86:	0f 85 95 08 00 00    	jne    f0102321 <mem_init+0xf77>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a8c:	6a 02                	push   $0x2
f0101a8e:	6a 00                	push   $0x0
f0101a90:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a93:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101a99:	ff 30                	pushl  (%eax)
f0101a9b:	e8 7c f8 ff ff       	call   f010131c <page_insert>
f0101aa0:	83 c4 10             	add    $0x10,%esp
f0101aa3:	85 c0                	test   %eax,%eax
f0101aa5:	0f 89 95 08 00 00    	jns    f0102340 <mem_init+0xf96>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101aab:	83 ec 0c             	sub    $0xc,%esp
f0101aae:	ff 75 cc             	pushl  -0x34(%ebp)
f0101ab1:	e8 2a f6 ff ff       	call   f01010e0 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101ab6:	6a 02                	push   $0x2
f0101ab8:	6a 00                	push   $0x0
f0101aba:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101abd:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101ac3:	ff 30                	pushl  (%eax)
f0101ac5:	e8 52 f8 ff ff       	call   f010131c <page_insert>
f0101aca:	83 c4 20             	add    $0x20,%esp
f0101acd:	85 c0                	test   %eax,%eax
f0101acf:	0f 85 8a 08 00 00    	jne    f010235f <mem_init+0xfb5>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ad5:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101adb:	8b 30                	mov    (%eax),%esi
	return (pp - pages) << PGSHIFT;
f0101add:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f0101ae3:	8b 38                	mov    (%eax),%edi
f0101ae5:	8b 16                	mov    (%esi),%edx
f0101ae7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101aed:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101af0:	29 f8                	sub    %edi,%eax
f0101af2:	c1 f8 03             	sar    $0x3,%eax
f0101af5:	c1 e0 0c             	shl    $0xc,%eax
f0101af8:	39 c2                	cmp    %eax,%edx
f0101afa:	0f 85 7e 08 00 00    	jne    f010237e <mem_init+0xfd4>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b00:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b05:	89 f0                	mov    %esi,%eax
f0101b07:	e8 74 f0 ff ff       	call   f0100b80 <check_va2pa>
f0101b0c:	89 c2                	mov    %eax,%edx
f0101b0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b11:	29 f8                	sub    %edi,%eax
f0101b13:	c1 f8 03             	sar    $0x3,%eax
f0101b16:	c1 e0 0c             	shl    $0xc,%eax
f0101b19:	39 c2                	cmp    %eax,%edx
f0101b1b:	0f 85 7c 08 00 00    	jne    f010239d <mem_init+0xff3>
	assert(pp1->pp_ref == 1);
f0101b21:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b24:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b29:	0f 85 8d 08 00 00    	jne    f01023bc <mem_init+0x1012>
	assert(pp0->pp_ref == 1);
f0101b2f:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101b32:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b37:	0f 85 9e 08 00 00    	jne    f01023db <mem_init+0x1031>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b3d:	6a 02                	push   $0x2
f0101b3f:	68 00 10 00 00       	push   $0x1000
f0101b44:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b47:	56                   	push   %esi
f0101b48:	e8 cf f7 ff ff       	call   f010131c <page_insert>
f0101b4d:	83 c4 10             	add    $0x10,%esp
f0101b50:	85 c0                	test   %eax,%eax
f0101b52:	0f 85 a2 08 00 00    	jne    f01023fa <mem_init+0x1050>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b58:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b5d:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101b63:	8b 00                	mov    (%eax),%eax
f0101b65:	e8 16 f0 ff ff       	call   f0100b80 <check_va2pa>
f0101b6a:	89 c2                	mov    %eax,%edx
f0101b6c:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f0101b72:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101b75:	2b 08                	sub    (%eax),%ecx
f0101b77:	89 c8                	mov    %ecx,%eax
f0101b79:	c1 f8 03             	sar    $0x3,%eax
f0101b7c:	c1 e0 0c             	shl    $0xc,%eax
f0101b7f:	39 c2                	cmp    %eax,%edx
f0101b81:	0f 85 92 08 00 00    	jne    f0102419 <mem_init+0x106f>
	assert(pp2->pp_ref == 1);
f0101b87:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b8a:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b8f:	0f 85 a3 08 00 00    	jne    f0102438 <mem_init+0x108e>

	// should be no free memory
	assert(!page_alloc(0));
f0101b95:	83 ec 0c             	sub    $0xc,%esp
f0101b98:	6a 00                	push   $0x0
f0101b9a:	e8 b2 f4 ff ff       	call   f0101051 <page_alloc>
f0101b9f:	83 c4 10             	add    $0x10,%esp
f0101ba2:	85 c0                	test   %eax,%eax
f0101ba4:	0f 85 ad 08 00 00    	jne    f0102457 <mem_init+0x10ad>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101baa:	6a 02                	push   $0x2
f0101bac:	68 00 10 00 00       	push   $0x1000
f0101bb1:	ff 75 d0             	pushl  -0x30(%ebp)
f0101bb4:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101bba:	ff 30                	pushl  (%eax)
f0101bbc:	e8 5b f7 ff ff       	call   f010131c <page_insert>
f0101bc1:	83 c4 10             	add    $0x10,%esp
f0101bc4:	85 c0                	test   %eax,%eax
f0101bc6:	0f 85 aa 08 00 00    	jne    f0102476 <mem_init+0x10cc>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bcc:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bd1:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101bd7:	8b 00                	mov    (%eax),%eax
f0101bd9:	e8 a2 ef ff ff       	call   f0100b80 <check_va2pa>
f0101bde:	89 c2                	mov    %eax,%edx
f0101be0:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f0101be6:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101be9:	2b 08                	sub    (%eax),%ecx
f0101beb:	89 c8                	mov    %ecx,%eax
f0101bed:	c1 f8 03             	sar    $0x3,%eax
f0101bf0:	c1 e0 0c             	shl    $0xc,%eax
f0101bf3:	39 c2                	cmp    %eax,%edx
f0101bf5:	0f 85 9a 08 00 00    	jne    f0102495 <mem_init+0x10eb>
	assert(pp2->pp_ref == 1);
f0101bfb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101bfe:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c03:	0f 85 ab 08 00 00    	jne    f01024b4 <mem_init+0x110a>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c09:	83 ec 0c             	sub    $0xc,%esp
f0101c0c:	6a 00                	push   $0x0
f0101c0e:	e8 3e f4 ff ff       	call   f0101051 <page_alloc>
f0101c13:	83 c4 10             	add    $0x10,%esp
f0101c16:	85 c0                	test   %eax,%eax
f0101c18:	0f 85 b5 08 00 00    	jne    f01024d3 <mem_init+0x1129>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c1e:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101c24:	8b 08                	mov    (%eax),%ecx
f0101c26:	8b 01                	mov    (%ecx),%eax
f0101c28:	89 c2                	mov    %eax,%edx
f0101c2a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101c30:	c1 e8 0c             	shr    $0xc,%eax
f0101c33:	c7 c6 08 00 19 f0    	mov    $0xf0190008,%esi
f0101c39:	3b 06                	cmp    (%esi),%eax
f0101c3b:	0f 83 b1 08 00 00    	jae    f01024f2 <mem_init+0x1148>
	return (void *)(pa + KERNBASE);
f0101c41:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101c47:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c4a:	83 ec 04             	sub    $0x4,%esp
f0101c4d:	6a 00                	push   $0x0
f0101c4f:	68 00 10 00 00       	push   $0x1000
f0101c54:	51                   	push   %ecx
f0101c55:	e8 06 f5 ff ff       	call   f0101160 <pgdir_walk>
f0101c5a:	89 c2                	mov    %eax,%edx
f0101c5c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101c5f:	83 c0 04             	add    $0x4,%eax
f0101c62:	83 c4 10             	add    $0x10,%esp
f0101c65:	39 d0                	cmp    %edx,%eax
f0101c67:	0f 85 9e 08 00 00    	jne    f010250b <mem_init+0x1161>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c6d:	6a 06                	push   $0x6
f0101c6f:	68 00 10 00 00       	push   $0x1000
f0101c74:	ff 75 d0             	pushl  -0x30(%ebp)
f0101c77:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101c7d:	ff 30                	pushl  (%eax)
f0101c7f:	e8 98 f6 ff ff       	call   f010131c <page_insert>
f0101c84:	83 c4 10             	add    $0x10,%esp
f0101c87:	85 c0                	test   %eax,%eax
f0101c89:	0f 85 9b 08 00 00    	jne    f010252a <mem_init+0x1180>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c8f:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101c95:	8b 30                	mov    (%eax),%esi
f0101c97:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c9c:	89 f0                	mov    %esi,%eax
f0101c9e:	e8 dd ee ff ff       	call   f0100b80 <check_va2pa>
f0101ca3:	89 c2                	mov    %eax,%edx
	return (pp - pages) << PGSHIFT;
f0101ca5:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f0101cab:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101cae:	2b 08                	sub    (%eax),%ecx
f0101cb0:	89 c8                	mov    %ecx,%eax
f0101cb2:	c1 f8 03             	sar    $0x3,%eax
f0101cb5:	c1 e0 0c             	shl    $0xc,%eax
f0101cb8:	39 c2                	cmp    %eax,%edx
f0101cba:	0f 85 89 08 00 00    	jne    f0102549 <mem_init+0x119f>
	assert(pp2->pp_ref == 1);
f0101cc0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101cc3:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101cc8:	0f 85 9a 08 00 00    	jne    f0102568 <mem_init+0x11be>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101cce:	83 ec 04             	sub    $0x4,%esp
f0101cd1:	6a 00                	push   $0x0
f0101cd3:	68 00 10 00 00       	push   $0x1000
f0101cd8:	56                   	push   %esi
f0101cd9:	e8 82 f4 ff ff       	call   f0101160 <pgdir_walk>
f0101cde:	83 c4 10             	add    $0x10,%esp
f0101ce1:	f6 00 04             	testb  $0x4,(%eax)
f0101ce4:	0f 84 9d 08 00 00    	je     f0102587 <mem_init+0x11dd>
	assert(kern_pgdir[0] & PTE_U);
f0101cea:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101cf0:	8b 00                	mov    (%eax),%eax
f0101cf2:	f6 00 04             	testb  $0x4,(%eax)
f0101cf5:	0f 84 ab 08 00 00    	je     f01025a6 <mem_init+0x11fc>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101cfb:	6a 02                	push   $0x2
f0101cfd:	68 00 10 00 00       	push   $0x1000
f0101d02:	ff 75 d0             	pushl  -0x30(%ebp)
f0101d05:	50                   	push   %eax
f0101d06:	e8 11 f6 ff ff       	call   f010131c <page_insert>
f0101d0b:	83 c4 10             	add    $0x10,%esp
f0101d0e:	85 c0                	test   %eax,%eax
f0101d10:	0f 85 af 08 00 00    	jne    f01025c5 <mem_init+0x121b>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d16:	83 ec 04             	sub    $0x4,%esp
f0101d19:	6a 00                	push   $0x0
f0101d1b:	68 00 10 00 00       	push   $0x1000
f0101d20:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101d26:	ff 30                	pushl  (%eax)
f0101d28:	e8 33 f4 ff ff       	call   f0101160 <pgdir_walk>
f0101d2d:	83 c4 10             	add    $0x10,%esp
f0101d30:	f6 00 02             	testb  $0x2,(%eax)
f0101d33:	0f 84 ab 08 00 00    	je     f01025e4 <mem_init+0x123a>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d39:	83 ec 04             	sub    $0x4,%esp
f0101d3c:	6a 00                	push   $0x0
f0101d3e:	68 00 10 00 00       	push   $0x1000
f0101d43:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101d49:	ff 30                	pushl  (%eax)
f0101d4b:	e8 10 f4 ff ff       	call   f0101160 <pgdir_walk>
f0101d50:	83 c4 10             	add    $0x10,%esp
f0101d53:	f6 00 04             	testb  $0x4,(%eax)
f0101d56:	0f 85 a7 08 00 00    	jne    f0102603 <mem_init+0x1259>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101d5c:	6a 02                	push   $0x2
f0101d5e:	68 00 00 40 00       	push   $0x400000
f0101d63:	ff 75 cc             	pushl  -0x34(%ebp)
f0101d66:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101d6c:	ff 30                	pushl  (%eax)
f0101d6e:	e8 a9 f5 ff ff       	call   f010131c <page_insert>
f0101d73:	83 c4 10             	add    $0x10,%esp
f0101d76:	85 c0                	test   %eax,%eax
f0101d78:	0f 89 a4 08 00 00    	jns    f0102622 <mem_init+0x1278>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d7e:	6a 02                	push   $0x2
f0101d80:	68 00 10 00 00       	push   $0x1000
f0101d85:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101d88:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101d8e:	ff 30                	pushl  (%eax)
f0101d90:	e8 87 f5 ff ff       	call   f010131c <page_insert>
f0101d95:	83 c4 10             	add    $0x10,%esp
f0101d98:	85 c0                	test   %eax,%eax
f0101d9a:	0f 85 a1 08 00 00    	jne    f0102641 <mem_init+0x1297>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101da0:	83 ec 04             	sub    $0x4,%esp
f0101da3:	6a 00                	push   $0x0
f0101da5:	68 00 10 00 00       	push   $0x1000
f0101daa:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101db0:	ff 30                	pushl  (%eax)
f0101db2:	e8 a9 f3 ff ff       	call   f0101160 <pgdir_walk>
f0101db7:	83 c4 10             	add    $0x10,%esp
f0101dba:	f6 00 04             	testb  $0x4,(%eax)
f0101dbd:	0f 85 9d 08 00 00    	jne    f0102660 <mem_init+0x12b6>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101dc3:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101dc9:	8b 38                	mov    (%eax),%edi
f0101dcb:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dd0:	89 f8                	mov    %edi,%eax
f0101dd2:	e8 a9 ed ff ff       	call   f0100b80 <check_va2pa>
f0101dd7:	c7 c2 10 00 19 f0    	mov    $0xf0190010,%edx
f0101ddd:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101de0:	2b 32                	sub    (%edx),%esi
f0101de2:	c1 fe 03             	sar    $0x3,%esi
f0101de5:	c1 e6 0c             	shl    $0xc,%esi
f0101de8:	39 f0                	cmp    %esi,%eax
f0101dea:	0f 85 8f 08 00 00    	jne    f010267f <mem_init+0x12d5>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101df0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101df5:	89 f8                	mov    %edi,%eax
f0101df7:	e8 84 ed ff ff       	call   f0100b80 <check_va2pa>
f0101dfc:	39 c6                	cmp    %eax,%esi
f0101dfe:	0f 85 9a 08 00 00    	jne    f010269e <mem_init+0x12f4>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e04:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e07:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f0101e0c:	0f 85 ab 08 00 00    	jne    f01026bd <mem_init+0x1313>
	assert(pp2->pp_ref == 0);
f0101e12:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101e15:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e1a:	0f 85 bc 08 00 00    	jne    f01026dc <mem_init+0x1332>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e20:	83 ec 0c             	sub    $0xc,%esp
f0101e23:	6a 00                	push   $0x0
f0101e25:	e8 27 f2 ff ff       	call   f0101051 <page_alloc>
f0101e2a:	83 c4 10             	add    $0x10,%esp
f0101e2d:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101e30:	0f 85 c5 08 00 00    	jne    f01026fb <mem_init+0x1351>
f0101e36:	85 c0                	test   %eax,%eax
f0101e38:	0f 84 bd 08 00 00    	je     f01026fb <mem_init+0x1351>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e3e:	83 ec 08             	sub    $0x8,%esp
f0101e41:	6a 00                	push   $0x0
f0101e43:	c7 c6 0c 00 19 f0    	mov    $0xf019000c,%esi
f0101e49:	ff 36                	pushl  (%esi)
f0101e4b:	e8 86 f4 ff ff       	call   f01012d6 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e50:	8b 36                	mov    (%esi),%esi
f0101e52:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e57:	89 f0                	mov    %esi,%eax
f0101e59:	e8 22 ed ff ff       	call   f0100b80 <check_va2pa>
f0101e5e:	83 c4 10             	add    $0x10,%esp
f0101e61:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e64:	0f 85 b0 08 00 00    	jne    f010271a <mem_init+0x1370>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e6a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e6f:	89 f0                	mov    %esi,%eax
f0101e71:	e8 0a ed ff ff       	call   f0100b80 <check_va2pa>
f0101e76:	89 c2                	mov    %eax,%edx
f0101e78:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f0101e7e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101e81:	2b 08                	sub    (%eax),%ecx
f0101e83:	89 c8                	mov    %ecx,%eax
f0101e85:	c1 f8 03             	sar    $0x3,%eax
f0101e88:	c1 e0 0c             	shl    $0xc,%eax
f0101e8b:	39 c2                	cmp    %eax,%edx
f0101e8d:	0f 85 a6 08 00 00    	jne    f0102739 <mem_init+0x138f>
	assert(pp1->pp_ref == 1);
f0101e93:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e96:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e9b:	0f 85 b7 08 00 00    	jne    f0102758 <mem_init+0x13ae>
	assert(pp2->pp_ref == 0);
f0101ea1:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101ea4:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101ea9:	0f 85 c8 08 00 00    	jne    f0102777 <mem_init+0x13cd>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101eaf:	6a 00                	push   $0x0
f0101eb1:	68 00 10 00 00       	push   $0x1000
f0101eb6:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101eb9:	56                   	push   %esi
f0101eba:	e8 5d f4 ff ff       	call   f010131c <page_insert>
f0101ebf:	83 c4 10             	add    $0x10,%esp
f0101ec2:	85 c0                	test   %eax,%eax
f0101ec4:	0f 85 cc 08 00 00    	jne    f0102796 <mem_init+0x13ec>
	assert(pp1->pp_ref);
f0101eca:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ecd:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101ed2:	0f 84 dd 08 00 00    	je     f01027b5 <mem_init+0x140b>
	assert(pp1->pp_link == NULL);
f0101ed8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101edb:	83 38 00             	cmpl   $0x0,(%eax)
f0101ede:	0f 85 f0 08 00 00    	jne    f01027d4 <mem_init+0x142a>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101ee4:	83 ec 08             	sub    $0x8,%esp
f0101ee7:	68 00 10 00 00       	push   $0x1000
f0101eec:	c7 c6 0c 00 19 f0    	mov    $0xf019000c,%esi
f0101ef2:	ff 36                	pushl  (%esi)
f0101ef4:	e8 dd f3 ff ff       	call   f01012d6 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101ef9:	8b 36                	mov    (%esi),%esi
f0101efb:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f00:	89 f0                	mov    %esi,%eax
f0101f02:	e8 79 ec ff ff       	call   f0100b80 <check_va2pa>
f0101f07:	83 c4 10             	add    $0x10,%esp
f0101f0a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f0d:	0f 85 e0 08 00 00    	jne    f01027f3 <mem_init+0x1449>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f13:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f18:	89 f0                	mov    %esi,%eax
f0101f1a:	e8 61 ec ff ff       	call   f0100b80 <check_va2pa>
f0101f1f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f22:	0f 85 ea 08 00 00    	jne    f0102812 <mem_init+0x1468>
	assert(pp1->pp_ref == 0);
f0101f28:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f2b:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101f30:	0f 85 fb 08 00 00    	jne    f0102831 <mem_init+0x1487>
	assert(pp2->pp_ref == 0);
f0101f36:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101f39:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101f3e:	0f 85 0c 09 00 00    	jne    f0102850 <mem_init+0x14a6>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f44:	83 ec 0c             	sub    $0xc,%esp
f0101f47:	6a 00                	push   $0x0
f0101f49:	e8 03 f1 ff ff       	call   f0101051 <page_alloc>
f0101f4e:	83 c4 10             	add    $0x10,%esp
f0101f51:	85 c0                	test   %eax,%eax
f0101f53:	0f 84 16 09 00 00    	je     f010286f <mem_init+0x14c5>
f0101f59:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101f5c:	0f 85 0d 09 00 00    	jne    f010286f <mem_init+0x14c5>

	// should be no free memory
	assert(!page_alloc(0));
f0101f62:	83 ec 0c             	sub    $0xc,%esp
f0101f65:	6a 00                	push   $0x0
f0101f67:	e8 e5 f0 ff ff       	call   f0101051 <page_alloc>
f0101f6c:	83 c4 10             	add    $0x10,%esp
f0101f6f:	85 c0                	test   %eax,%eax
f0101f71:	0f 85 17 09 00 00    	jne    f010288e <mem_init+0x14e4>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f77:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101f7d:	8b 08                	mov    (%eax),%ecx
f0101f7f:	8b 11                	mov    (%ecx),%edx
f0101f81:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f87:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f0101f8d:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0101f90:	2b 38                	sub    (%eax),%edi
f0101f92:	89 f8                	mov    %edi,%eax
f0101f94:	c1 f8 03             	sar    $0x3,%eax
f0101f97:	c1 e0 0c             	shl    $0xc,%eax
f0101f9a:	39 c2                	cmp    %eax,%edx
f0101f9c:	0f 85 0b 09 00 00    	jne    f01028ad <mem_init+0x1503>
	kern_pgdir[0] = 0;
f0101fa2:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101fa8:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101fab:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101fb0:	0f 85 16 09 00 00    	jne    f01028cc <mem_init+0x1522>
	pp0->pp_ref = 0;
f0101fb6:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101fb9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101fbf:	83 ec 0c             	sub    $0xc,%esp
f0101fc2:	50                   	push   %eax
f0101fc3:	e8 18 f1 ff ff       	call   f01010e0 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101fc8:	83 c4 0c             	add    $0xc,%esp
f0101fcb:	6a 01                	push   $0x1
f0101fcd:	68 00 10 40 00       	push   $0x401000
f0101fd2:	c7 c6 0c 00 19 f0    	mov    $0xf019000c,%esi
f0101fd8:	ff 36                	pushl  (%esi)
f0101fda:	e8 81 f1 ff ff       	call   f0101160 <pgdir_walk>
f0101fdf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fe2:	8b 3e                	mov    (%esi),%edi
f0101fe4:	8b 57 04             	mov    0x4(%edi),%edx
f0101fe7:	89 d1                	mov    %edx,%ecx
f0101fe9:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	if (PGNUM(pa) >= npages)
f0101fef:	c7 c6 08 00 19 f0    	mov    $0xf0190008,%esi
f0101ff5:	8b 36                	mov    (%esi),%esi
f0101ff7:	c1 ea 0c             	shr    $0xc,%edx
f0101ffa:	83 c4 10             	add    $0x10,%esp
f0101ffd:	39 f2                	cmp    %esi,%edx
f0101fff:	0f 83 e6 08 00 00    	jae    f01028eb <mem_init+0x1541>
	assert(ptep == ptep1 + PTX(va));
f0102005:	81 e9 fc ff ff 0f    	sub    $0xffffffc,%ecx
f010200b:	39 c8                	cmp    %ecx,%eax
f010200d:	0f 85 f1 08 00 00    	jne    f0102904 <mem_init+0x155a>
	kern_pgdir[PDX(va)] = 0;
f0102013:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	pp0->pp_ref = 0;
f010201a:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010201d:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
	return (pp - pages) << PGSHIFT;
f0102023:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f0102029:	2b 08                	sub    (%eax),%ecx
f010202b:	89 c8                	mov    %ecx,%eax
f010202d:	c1 f8 03             	sar    $0x3,%eax
f0102030:	89 c2                	mov    %eax,%edx
f0102032:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102035:	25 ff ff 0f 00       	and    $0xfffff,%eax
f010203a:	39 c6                	cmp    %eax,%esi
f010203c:	0f 86 e1 08 00 00    	jbe    f0102923 <mem_init+0x1579>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102042:	83 ec 04             	sub    $0x4,%esp
f0102045:	68 00 10 00 00       	push   $0x1000
f010204a:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f010204f:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102055:	52                   	push   %edx
f0102056:	e8 44 30 00 00       	call   f010509f <memset>
	page_free(pp0);
f010205b:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010205e:	89 3c 24             	mov    %edi,(%esp)
f0102061:	e8 7a f0 ff ff       	call   f01010e0 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102066:	83 c4 0c             	add    $0xc,%esp
f0102069:	6a 01                	push   $0x1
f010206b:	6a 00                	push   $0x0
f010206d:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0102073:	ff 30                	pushl  (%eax)
f0102075:	e8 e6 f0 ff ff       	call   f0101160 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f010207a:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f0102080:	2b 38                	sub    (%eax),%edi
f0102082:	89 f8                	mov    %edi,%eax
f0102084:	c1 f8 03             	sar    $0x3,%eax
f0102087:	89 c2                	mov    %eax,%edx
f0102089:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010208c:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102091:	83 c4 10             	add    $0x10,%esp
f0102094:	c7 c1 08 00 19 f0    	mov    $0xf0190008,%ecx
f010209a:	3b 01                	cmp    (%ecx),%eax
f010209c:	0f 83 97 08 00 00    	jae    f0102939 <mem_init+0x158f>
	return (void *)(pa + KERNBASE);
f01020a2:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020a8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020ab:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020b1:	8b 38                	mov    (%eax),%edi
f01020b3:	83 e7 01             	and    $0x1,%edi
f01020b6:	0f 85 93 08 00 00    	jne    f010294f <mem_init+0x15a5>
f01020bc:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f01020bf:	39 d0                	cmp    %edx,%eax
f01020c1:	75 ee                	jne    f01020b1 <mem_init+0xd07>
	kern_pgdir[0] = 0;
f01020c3:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f01020c9:	8b 00                	mov    (%eax),%eax
f01020cb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020d1:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01020d4:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020da:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01020dd:	89 8b 24 23 00 00    	mov    %ecx,0x2324(%ebx)

	// free the pages we took
	page_free(pp0);
f01020e3:	83 ec 0c             	sub    $0xc,%esp
f01020e6:	50                   	push   %eax
f01020e7:	e8 f4 ef ff ff       	call   f01010e0 <page_free>
	page_free(pp1);
f01020ec:	83 c4 04             	add    $0x4,%esp
f01020ef:	ff 75 d4             	pushl  -0x2c(%ebp)
f01020f2:	e8 e9 ef ff ff       	call   f01010e0 <page_free>
	page_free(pp2);
f01020f7:	83 c4 04             	add    $0x4,%esp
f01020fa:	ff 75 d0             	pushl  -0x30(%ebp)
f01020fd:	e8 de ef ff ff       	call   f01010e0 <page_free>

	cprintf("check_page() succeeded!\n");
f0102102:	8d 83 a7 94 f7 ff    	lea    -0x86b59(%ebx),%eax
f0102108:	89 04 24             	mov    %eax,(%esp)
f010210b:	e8 e5 18 00 00       	call   f01039f5 <cprintf>
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U);
f0102110:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f0102116:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102118:	83 c4 10             	add    $0x10,%esp
f010211b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102120:	0f 86 48 08 00 00    	jbe    f010296e <mem_init+0x15c4>
f0102126:	83 ec 08             	sub    $0x8,%esp
f0102129:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f010212b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102130:	50                   	push   %eax
f0102131:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102136:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010213b:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0102141:	8b 00                	mov    (%eax),%eax
f0102143:	e8 c3 f0 ff ff       	call   f010120b <boot_map_region>
	boot_map_region(kern_pgdir,UENVS,PTSIZE,PADDR(envs),PTE_U);
f0102148:	c7 c0 4c f3 18 f0    	mov    $0xf018f34c,%eax
f010214e:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102150:	83 c4 10             	add    $0x10,%esp
f0102153:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102158:	0f 86 29 08 00 00    	jbe    f0102987 <mem_init+0x15dd>
f010215e:	83 ec 08             	sub    $0x8,%esp
f0102161:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102163:	05 00 00 00 10       	add    $0x10000000,%eax
f0102168:	50                   	push   %eax
f0102169:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010216e:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102173:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0102179:	8b 00                	mov    (%eax),%eax
f010217b:	e8 8b f0 ff ff       	call   f010120b <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f0102180:	c7 c0 00 30 11 f0    	mov    $0xf0113000,%eax
f0102186:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102189:	83 c4 10             	add    $0x10,%esp
f010218c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102191:	0f 86 09 08 00 00    	jbe    f01029a0 <mem_init+0x15f6>
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f0102197:	c7 c6 0c 00 19 f0    	mov    $0xf019000c,%esi
f010219d:	83 ec 08             	sub    $0x8,%esp
f01021a0:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f01021a2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01021a5:	05 00 00 00 10       	add    $0x10000000,%eax
f01021aa:	50                   	push   %eax
f01021ab:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021b0:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021b5:	8b 06                	mov    (%esi),%eax
f01021b7:	e8 4f f0 ff ff       	call   f010120b <boot_map_region>
	boot_map_region(kern_pgdir,KERNBASE,0xFFFFFFFF-KERNBASE,0,PTE_W);
f01021bc:	83 c4 08             	add    $0x8,%esp
f01021bf:	6a 02                	push   $0x2
f01021c1:	6a 00                	push   $0x0
f01021c3:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01021c8:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021cd:	8b 06                	mov    (%esi),%eax
f01021cf:	e8 37 f0 ff ff       	call   f010120b <boot_map_region>
	pgdir = kern_pgdir;
f01021d4:	8b 06                	mov    (%esi),%eax
f01021d6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021d9:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f01021df:	8b 00                	mov    (%eax),%eax
f01021e1:	89 45 c0             	mov    %eax,-0x40(%ebp)
f01021e4:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021eb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021f0:	89 45 cc             	mov    %eax,-0x34(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021f3:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f01021f9:	8b 00                	mov    (%eax),%eax
f01021fb:	89 45 bc             	mov    %eax,-0x44(%ebp)
	if ((uint32_t)kva < KERNBASE)
f01021fe:	89 45 c8             	mov    %eax,-0x38(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0102201:	05 00 00 00 10       	add    $0x10000000,%eax
f0102206:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f0102209:	83 c4 10             	add    $0x10,%esp
f010220c:	89 fe                	mov    %edi,%esi
f010220e:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0102211:	0f 86 dc 07 00 00    	jbe    f01029f3 <mem_init+0x1649>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102217:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f010221d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102220:	e8 5b e9 ff ff       	call   f0100b80 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102225:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f010222c:	0f 86 87 07 00 00    	jbe    f01029b9 <mem_init+0x160f>
f0102232:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102235:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102238:	39 d0                	cmp    %edx,%eax
f010223a:	0f 85 94 07 00 00    	jne    f01029d4 <mem_init+0x162a>
	for (i = 0; i < n; i += PGSIZE)
f0102240:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102246:	eb c6                	jmp    f010220e <mem_init+0xe64>
	assert(nfree == 0);
f0102248:	8d 83 d0 93 f7 ff    	lea    -0x86c30(%ebx),%eax
f010224e:	50                   	push   %eax
f010224f:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102255:	50                   	push   %eax
f0102256:	68 51 03 00 00       	push   $0x351
f010225b:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102261:	50                   	push   %eax
f0102262:	e8 4e de ff ff       	call   f01000b5 <_panic>
	assert((pp0 = page_alloc(0)));
f0102267:	8d 83 de 92 f7 ff    	lea    -0x86d22(%ebx),%eax
f010226d:	50                   	push   %eax
f010226e:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102274:	50                   	push   %eax
f0102275:	68 af 03 00 00       	push   $0x3af
f010227a:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102280:	50                   	push   %eax
f0102281:	e8 2f de ff ff       	call   f01000b5 <_panic>
	assert((pp1 = page_alloc(0)));
f0102286:	8d 83 f4 92 f7 ff    	lea    -0x86d0c(%ebx),%eax
f010228c:	50                   	push   %eax
f010228d:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102293:	50                   	push   %eax
f0102294:	68 b0 03 00 00       	push   $0x3b0
f0102299:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f010229f:	50                   	push   %eax
f01022a0:	e8 10 de ff ff       	call   f01000b5 <_panic>
	assert((pp2 = page_alloc(0)));
f01022a5:	8d 83 0a 93 f7 ff    	lea    -0x86cf6(%ebx),%eax
f01022ab:	50                   	push   %eax
f01022ac:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01022b2:	50                   	push   %eax
f01022b3:	68 b1 03 00 00       	push   $0x3b1
f01022b8:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01022be:	50                   	push   %eax
f01022bf:	e8 f1 dd ff ff       	call   f01000b5 <_panic>
	assert(pp1 && pp1 != pp0);
f01022c4:	8d 83 20 93 f7 ff    	lea    -0x86ce0(%ebx),%eax
f01022ca:	50                   	push   %eax
f01022cb:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01022d1:	50                   	push   %eax
f01022d2:	68 b4 03 00 00       	push   $0x3b4
f01022d7:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01022dd:	50                   	push   %eax
f01022de:	e8 d2 dd ff ff       	call   f01000b5 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01022e3:	8d 83 b8 8b f7 ff    	lea    -0x87448(%ebx),%eax
f01022e9:	50                   	push   %eax
f01022ea:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01022f0:	50                   	push   %eax
f01022f1:	68 b5 03 00 00       	push   $0x3b5
f01022f6:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01022fc:	50                   	push   %eax
f01022fd:	e8 b3 dd ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f0102302:	8d 83 89 93 f7 ff    	lea    -0x86c77(%ebx),%eax
f0102308:	50                   	push   %eax
f0102309:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010230f:	50                   	push   %eax
f0102310:	68 bc 03 00 00       	push   $0x3bc
f0102315:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f010231b:	50                   	push   %eax
f010231c:	e8 94 dd ff ff       	call   f01000b5 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102321:	8d 83 f8 8b f7 ff    	lea    -0x87408(%ebx),%eax
f0102327:	50                   	push   %eax
f0102328:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010232e:	50                   	push   %eax
f010232f:	68 bf 03 00 00       	push   $0x3bf
f0102334:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f010233a:	50                   	push   %eax
f010233b:	e8 75 dd ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102340:	8d 83 30 8c f7 ff    	lea    -0x873d0(%ebx),%eax
f0102346:	50                   	push   %eax
f0102347:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010234d:	50                   	push   %eax
f010234e:	68 c2 03 00 00       	push   $0x3c2
f0102353:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102359:	50                   	push   %eax
f010235a:	e8 56 dd ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010235f:	8d 83 60 8c f7 ff    	lea    -0x873a0(%ebx),%eax
f0102365:	50                   	push   %eax
f0102366:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010236c:	50                   	push   %eax
f010236d:	68 c6 03 00 00       	push   $0x3c6
f0102372:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102378:	50                   	push   %eax
f0102379:	e8 37 dd ff ff       	call   f01000b5 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010237e:	8d 83 90 8c f7 ff    	lea    -0x87370(%ebx),%eax
f0102384:	50                   	push   %eax
f0102385:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010238b:	50                   	push   %eax
f010238c:	68 c7 03 00 00       	push   $0x3c7
f0102391:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102397:	50                   	push   %eax
f0102398:	e8 18 dd ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010239d:	8d 83 b8 8c f7 ff    	lea    -0x87348(%ebx),%eax
f01023a3:	50                   	push   %eax
f01023a4:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01023aa:	50                   	push   %eax
f01023ab:	68 c8 03 00 00       	push   $0x3c8
f01023b0:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01023b6:	50                   	push   %eax
f01023b7:	e8 f9 dc ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 1);
f01023bc:	8d 83 db 93 f7 ff    	lea    -0x86c25(%ebx),%eax
f01023c2:	50                   	push   %eax
f01023c3:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01023c9:	50                   	push   %eax
f01023ca:	68 c9 03 00 00       	push   $0x3c9
f01023cf:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01023d5:	50                   	push   %eax
f01023d6:	e8 da dc ff ff       	call   f01000b5 <_panic>
	assert(pp0->pp_ref == 1);
f01023db:	8d 83 ec 93 f7 ff    	lea    -0x86c14(%ebx),%eax
f01023e1:	50                   	push   %eax
f01023e2:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01023e8:	50                   	push   %eax
f01023e9:	68 ca 03 00 00       	push   $0x3ca
f01023ee:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01023f4:	50                   	push   %eax
f01023f5:	e8 bb dc ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023fa:	8d 83 e8 8c f7 ff    	lea    -0x87318(%ebx),%eax
f0102400:	50                   	push   %eax
f0102401:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102407:	50                   	push   %eax
f0102408:	68 cd 03 00 00       	push   $0x3cd
f010240d:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102413:	50                   	push   %eax
f0102414:	e8 9c dc ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102419:	8d 83 24 8d f7 ff    	lea    -0x872dc(%ebx),%eax
f010241f:	50                   	push   %eax
f0102420:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102426:	50                   	push   %eax
f0102427:	68 ce 03 00 00       	push   $0x3ce
f010242c:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102432:	50                   	push   %eax
f0102433:	e8 7d dc ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 1);
f0102438:	8d 83 fd 93 f7 ff    	lea    -0x86c03(%ebx),%eax
f010243e:	50                   	push   %eax
f010243f:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102445:	50                   	push   %eax
f0102446:	68 cf 03 00 00       	push   $0x3cf
f010244b:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102451:	50                   	push   %eax
f0102452:	e8 5e dc ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f0102457:	8d 83 89 93 f7 ff    	lea    -0x86c77(%ebx),%eax
f010245d:	50                   	push   %eax
f010245e:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102464:	50                   	push   %eax
f0102465:	68 d2 03 00 00       	push   $0x3d2
f010246a:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102470:	50                   	push   %eax
f0102471:	e8 3f dc ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102476:	8d 83 e8 8c f7 ff    	lea    -0x87318(%ebx),%eax
f010247c:	50                   	push   %eax
f010247d:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102483:	50                   	push   %eax
f0102484:	68 d5 03 00 00       	push   $0x3d5
f0102489:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f010248f:	50                   	push   %eax
f0102490:	e8 20 dc ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102495:	8d 83 24 8d f7 ff    	lea    -0x872dc(%ebx),%eax
f010249b:	50                   	push   %eax
f010249c:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01024a2:	50                   	push   %eax
f01024a3:	68 d6 03 00 00       	push   $0x3d6
f01024a8:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01024ae:	50                   	push   %eax
f01024af:	e8 01 dc ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 1);
f01024b4:	8d 83 fd 93 f7 ff    	lea    -0x86c03(%ebx),%eax
f01024ba:	50                   	push   %eax
f01024bb:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01024c1:	50                   	push   %eax
f01024c2:	68 d7 03 00 00       	push   $0x3d7
f01024c7:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01024cd:	50                   	push   %eax
f01024ce:	e8 e2 db ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f01024d3:	8d 83 89 93 f7 ff    	lea    -0x86c77(%ebx),%eax
f01024d9:	50                   	push   %eax
f01024da:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01024e0:	50                   	push   %eax
f01024e1:	68 db 03 00 00       	push   $0x3db
f01024e6:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01024ec:	50                   	push   %eax
f01024ed:	e8 c3 db ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024f2:	52                   	push   %edx
f01024f3:	8d 83 e4 89 f7 ff    	lea    -0x8761c(%ebx),%eax
f01024f9:	50                   	push   %eax
f01024fa:	68 de 03 00 00       	push   $0x3de
f01024ff:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102505:	50                   	push   %eax
f0102506:	e8 aa db ff ff       	call   f01000b5 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010250b:	8d 83 54 8d f7 ff    	lea    -0x872ac(%ebx),%eax
f0102511:	50                   	push   %eax
f0102512:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102518:	50                   	push   %eax
f0102519:	68 df 03 00 00       	push   $0x3df
f010251e:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102524:	50                   	push   %eax
f0102525:	e8 8b db ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010252a:	8d 83 94 8d f7 ff    	lea    -0x8726c(%ebx),%eax
f0102530:	50                   	push   %eax
f0102531:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102537:	50                   	push   %eax
f0102538:	68 e2 03 00 00       	push   $0x3e2
f010253d:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102543:	50                   	push   %eax
f0102544:	e8 6c db ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102549:	8d 83 24 8d f7 ff    	lea    -0x872dc(%ebx),%eax
f010254f:	50                   	push   %eax
f0102550:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102556:	50                   	push   %eax
f0102557:	68 e3 03 00 00       	push   $0x3e3
f010255c:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102562:	50                   	push   %eax
f0102563:	e8 4d db ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 1);
f0102568:	8d 83 fd 93 f7 ff    	lea    -0x86c03(%ebx),%eax
f010256e:	50                   	push   %eax
f010256f:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102575:	50                   	push   %eax
f0102576:	68 e4 03 00 00       	push   $0x3e4
f010257b:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102581:	50                   	push   %eax
f0102582:	e8 2e db ff ff       	call   f01000b5 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102587:	8d 83 d4 8d f7 ff    	lea    -0x8722c(%ebx),%eax
f010258d:	50                   	push   %eax
f010258e:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102594:	50                   	push   %eax
f0102595:	68 e5 03 00 00       	push   $0x3e5
f010259a:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01025a0:	50                   	push   %eax
f01025a1:	e8 0f db ff ff       	call   f01000b5 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01025a6:	8d 83 0e 94 f7 ff    	lea    -0x86bf2(%ebx),%eax
f01025ac:	50                   	push   %eax
f01025ad:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01025b3:	50                   	push   %eax
f01025b4:	68 e6 03 00 00       	push   $0x3e6
f01025b9:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01025bf:	50                   	push   %eax
f01025c0:	e8 f0 da ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01025c5:	8d 83 e8 8c f7 ff    	lea    -0x87318(%ebx),%eax
f01025cb:	50                   	push   %eax
f01025cc:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01025d2:	50                   	push   %eax
f01025d3:	68 e9 03 00 00       	push   $0x3e9
f01025d8:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01025de:	50                   	push   %eax
f01025df:	e8 d1 da ff ff       	call   f01000b5 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01025e4:	8d 83 08 8e f7 ff    	lea    -0x871f8(%ebx),%eax
f01025ea:	50                   	push   %eax
f01025eb:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01025f1:	50                   	push   %eax
f01025f2:	68 ea 03 00 00       	push   $0x3ea
f01025f7:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01025fd:	50                   	push   %eax
f01025fe:	e8 b2 da ff ff       	call   f01000b5 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102603:	8d 83 3c 8e f7 ff    	lea    -0x871c4(%ebx),%eax
f0102609:	50                   	push   %eax
f010260a:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102610:	50                   	push   %eax
f0102611:	68 eb 03 00 00       	push   $0x3eb
f0102616:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f010261c:	50                   	push   %eax
f010261d:	e8 93 da ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102622:	8d 83 74 8e f7 ff    	lea    -0x8718c(%ebx),%eax
f0102628:	50                   	push   %eax
f0102629:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010262f:	50                   	push   %eax
f0102630:	68 ee 03 00 00       	push   $0x3ee
f0102635:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f010263b:	50                   	push   %eax
f010263c:	e8 74 da ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102641:	8d 83 ac 8e f7 ff    	lea    -0x87154(%ebx),%eax
f0102647:	50                   	push   %eax
f0102648:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010264e:	50                   	push   %eax
f010264f:	68 f1 03 00 00       	push   $0x3f1
f0102654:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f010265a:	50                   	push   %eax
f010265b:	e8 55 da ff ff       	call   f01000b5 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102660:	8d 83 3c 8e f7 ff    	lea    -0x871c4(%ebx),%eax
f0102666:	50                   	push   %eax
f0102667:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010266d:	50                   	push   %eax
f010266e:	68 f2 03 00 00       	push   $0x3f2
f0102673:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102679:	50                   	push   %eax
f010267a:	e8 36 da ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010267f:	8d 83 e8 8e f7 ff    	lea    -0x87118(%ebx),%eax
f0102685:	50                   	push   %eax
f0102686:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010268c:	50                   	push   %eax
f010268d:	68 f5 03 00 00       	push   $0x3f5
f0102692:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102698:	50                   	push   %eax
f0102699:	e8 17 da ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010269e:	8d 83 14 8f f7 ff    	lea    -0x870ec(%ebx),%eax
f01026a4:	50                   	push   %eax
f01026a5:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01026ab:	50                   	push   %eax
f01026ac:	68 f6 03 00 00       	push   $0x3f6
f01026b1:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01026b7:	50                   	push   %eax
f01026b8:	e8 f8 d9 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 2);
f01026bd:	8d 83 24 94 f7 ff    	lea    -0x86bdc(%ebx),%eax
f01026c3:	50                   	push   %eax
f01026c4:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01026ca:	50                   	push   %eax
f01026cb:	68 f8 03 00 00       	push   $0x3f8
f01026d0:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01026d6:	50                   	push   %eax
f01026d7:	e8 d9 d9 ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 0);
f01026dc:	8d 83 35 94 f7 ff    	lea    -0x86bcb(%ebx),%eax
f01026e2:	50                   	push   %eax
f01026e3:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01026e9:	50                   	push   %eax
f01026ea:	68 f9 03 00 00       	push   $0x3f9
f01026ef:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01026f5:	50                   	push   %eax
f01026f6:	e8 ba d9 ff ff       	call   f01000b5 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f01026fb:	8d 83 44 8f f7 ff    	lea    -0x870bc(%ebx),%eax
f0102701:	50                   	push   %eax
f0102702:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102708:	50                   	push   %eax
f0102709:	68 fc 03 00 00       	push   $0x3fc
f010270e:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102714:	50                   	push   %eax
f0102715:	e8 9b d9 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010271a:	8d 83 68 8f f7 ff    	lea    -0x87098(%ebx),%eax
f0102720:	50                   	push   %eax
f0102721:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102727:	50                   	push   %eax
f0102728:	68 00 04 00 00       	push   $0x400
f010272d:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102733:	50                   	push   %eax
f0102734:	e8 7c d9 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102739:	8d 83 14 8f f7 ff    	lea    -0x870ec(%ebx),%eax
f010273f:	50                   	push   %eax
f0102740:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102746:	50                   	push   %eax
f0102747:	68 01 04 00 00       	push   $0x401
f010274c:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102752:	50                   	push   %eax
f0102753:	e8 5d d9 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 1);
f0102758:	8d 83 db 93 f7 ff    	lea    -0x86c25(%ebx),%eax
f010275e:	50                   	push   %eax
f010275f:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102765:	50                   	push   %eax
f0102766:	68 02 04 00 00       	push   $0x402
f010276b:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102771:	50                   	push   %eax
f0102772:	e8 3e d9 ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 0);
f0102777:	8d 83 35 94 f7 ff    	lea    -0x86bcb(%ebx),%eax
f010277d:	50                   	push   %eax
f010277e:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102784:	50                   	push   %eax
f0102785:	68 03 04 00 00       	push   $0x403
f010278a:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102790:	50                   	push   %eax
f0102791:	e8 1f d9 ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102796:	8d 83 8c 8f f7 ff    	lea    -0x87074(%ebx),%eax
f010279c:	50                   	push   %eax
f010279d:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01027a3:	50                   	push   %eax
f01027a4:	68 06 04 00 00       	push   $0x406
f01027a9:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01027af:	50                   	push   %eax
f01027b0:	e8 00 d9 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref);
f01027b5:	8d 83 46 94 f7 ff    	lea    -0x86bba(%ebx),%eax
f01027bb:	50                   	push   %eax
f01027bc:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01027c2:	50                   	push   %eax
f01027c3:	68 07 04 00 00       	push   $0x407
f01027c8:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01027ce:	50                   	push   %eax
f01027cf:	e8 e1 d8 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_link == NULL);
f01027d4:	8d 83 52 94 f7 ff    	lea    -0x86bae(%ebx),%eax
f01027da:	50                   	push   %eax
f01027db:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01027e1:	50                   	push   %eax
f01027e2:	68 08 04 00 00       	push   $0x408
f01027e7:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01027ed:	50                   	push   %eax
f01027ee:	e8 c2 d8 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01027f3:	8d 83 68 8f f7 ff    	lea    -0x87098(%ebx),%eax
f01027f9:	50                   	push   %eax
f01027fa:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102800:	50                   	push   %eax
f0102801:	68 0c 04 00 00       	push   $0x40c
f0102806:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f010280c:	50                   	push   %eax
f010280d:	e8 a3 d8 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102812:	8d 83 c4 8f f7 ff    	lea    -0x8703c(%ebx),%eax
f0102818:	50                   	push   %eax
f0102819:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010281f:	50                   	push   %eax
f0102820:	68 0d 04 00 00       	push   $0x40d
f0102825:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f010282b:	50                   	push   %eax
f010282c:	e8 84 d8 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 0);
f0102831:	8d 83 67 94 f7 ff    	lea    -0x86b99(%ebx),%eax
f0102837:	50                   	push   %eax
f0102838:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010283e:	50                   	push   %eax
f010283f:	68 0e 04 00 00       	push   $0x40e
f0102844:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f010284a:	50                   	push   %eax
f010284b:	e8 65 d8 ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 0);
f0102850:	8d 83 35 94 f7 ff    	lea    -0x86bcb(%ebx),%eax
f0102856:	50                   	push   %eax
f0102857:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010285d:	50                   	push   %eax
f010285e:	68 0f 04 00 00       	push   $0x40f
f0102863:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102869:	50                   	push   %eax
f010286a:	e8 46 d8 ff ff       	call   f01000b5 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f010286f:	8d 83 ec 8f f7 ff    	lea    -0x87014(%ebx),%eax
f0102875:	50                   	push   %eax
f0102876:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010287c:	50                   	push   %eax
f010287d:	68 12 04 00 00       	push   $0x412
f0102882:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102888:	50                   	push   %eax
f0102889:	e8 27 d8 ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f010288e:	8d 83 89 93 f7 ff    	lea    -0x86c77(%ebx),%eax
f0102894:	50                   	push   %eax
f0102895:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010289b:	50                   	push   %eax
f010289c:	68 15 04 00 00       	push   $0x415
f01028a1:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01028a7:	50                   	push   %eax
f01028a8:	e8 08 d8 ff ff       	call   f01000b5 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01028ad:	8d 83 90 8c f7 ff    	lea    -0x87370(%ebx),%eax
f01028b3:	50                   	push   %eax
f01028b4:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01028ba:	50                   	push   %eax
f01028bb:	68 18 04 00 00       	push   $0x418
f01028c0:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01028c6:	50                   	push   %eax
f01028c7:	e8 e9 d7 ff ff       	call   f01000b5 <_panic>
	assert(pp0->pp_ref == 1);
f01028cc:	8d 83 ec 93 f7 ff    	lea    -0x86c14(%ebx),%eax
f01028d2:	50                   	push   %eax
f01028d3:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01028d9:	50                   	push   %eax
f01028da:	68 1a 04 00 00       	push   $0x41a
f01028df:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01028e5:	50                   	push   %eax
f01028e6:	e8 ca d7 ff ff       	call   f01000b5 <_panic>
f01028eb:	51                   	push   %ecx
f01028ec:	8d 83 e4 89 f7 ff    	lea    -0x8761c(%ebx),%eax
f01028f2:	50                   	push   %eax
f01028f3:	68 21 04 00 00       	push   $0x421
f01028f8:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01028fe:	50                   	push   %eax
f01028ff:	e8 b1 d7 ff ff       	call   f01000b5 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102904:	8d 83 78 94 f7 ff    	lea    -0x86b88(%ebx),%eax
f010290a:	50                   	push   %eax
f010290b:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102911:	50                   	push   %eax
f0102912:	68 22 04 00 00       	push   $0x422
f0102917:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f010291d:	50                   	push   %eax
f010291e:	e8 92 d7 ff ff       	call   f01000b5 <_panic>
f0102923:	52                   	push   %edx
f0102924:	8d 83 e4 89 f7 ff    	lea    -0x8761c(%ebx),%eax
f010292a:	50                   	push   %eax
f010292b:	6a 56                	push   $0x56
f010292d:	8d 83 19 92 f7 ff    	lea    -0x86de7(%ebx),%eax
f0102933:	50                   	push   %eax
f0102934:	e8 7c d7 ff ff       	call   f01000b5 <_panic>
f0102939:	52                   	push   %edx
f010293a:	8d 83 e4 89 f7 ff    	lea    -0x8761c(%ebx),%eax
f0102940:	50                   	push   %eax
f0102941:	6a 56                	push   $0x56
f0102943:	8d 83 19 92 f7 ff    	lea    -0x86de7(%ebx),%eax
f0102949:	50                   	push   %eax
f010294a:	e8 66 d7 ff ff       	call   f01000b5 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f010294f:	8d 83 90 94 f7 ff    	lea    -0x86b70(%ebx),%eax
f0102955:	50                   	push   %eax
f0102956:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010295c:	50                   	push   %eax
f010295d:	68 2c 04 00 00       	push   $0x42c
f0102962:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102968:	50                   	push   %eax
f0102969:	e8 47 d7 ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010296e:	50                   	push   %eax
f010296f:	8d 83 94 8b f7 ff    	lea    -0x8746c(%ebx),%eax
f0102975:	50                   	push   %eax
f0102976:	68 c9 00 00 00       	push   $0xc9
f010297b:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102981:	50                   	push   %eax
f0102982:	e8 2e d7 ff ff       	call   f01000b5 <_panic>
f0102987:	50                   	push   %eax
f0102988:	8d 83 94 8b f7 ff    	lea    -0x8746c(%ebx),%eax
f010298e:	50                   	push   %eax
f010298f:	68 d1 00 00 00       	push   $0xd1
f0102994:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f010299a:	50                   	push   %eax
f010299b:	e8 15 d7 ff ff       	call   f01000b5 <_panic>
f01029a0:	50                   	push   %eax
f01029a1:	8d 83 94 8b f7 ff    	lea    -0x8746c(%ebx),%eax
f01029a7:	50                   	push   %eax
f01029a8:	68 dd 00 00 00       	push   $0xdd
f01029ad:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01029b3:	50                   	push   %eax
f01029b4:	e8 fc d6 ff ff       	call   f01000b5 <_panic>
f01029b9:	ff 75 bc             	pushl  -0x44(%ebp)
f01029bc:	8d 83 94 8b f7 ff    	lea    -0x8746c(%ebx),%eax
f01029c2:	50                   	push   %eax
f01029c3:	68 69 03 00 00       	push   $0x369
f01029c8:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01029ce:	50                   	push   %eax
f01029cf:	e8 e1 d6 ff ff       	call   f01000b5 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01029d4:	8d 83 10 90 f7 ff    	lea    -0x86ff0(%ebx),%eax
f01029da:	50                   	push   %eax
f01029db:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f01029e1:	50                   	push   %eax
f01029e2:	68 69 03 00 00       	push   $0x369
f01029e7:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f01029ed:	50                   	push   %eax
f01029ee:	e8 c2 d6 ff ff       	call   f01000b5 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01029f3:	c7 c0 4c f3 18 f0    	mov    $0xf018f34c,%eax
f01029f9:	8b 00                	mov    (%eax),%eax
f01029fb:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	if ((uint32_t)kva < KERNBASE)
f01029fe:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102a01:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f0102a06:	05 00 00 40 21       	add    $0x21400000,%eax
f0102a0b:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102a0e:	89 f2                	mov    %esi,%edx
f0102a10:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a13:	e8 68 e1 ff ff       	call   f0100b80 <check_va2pa>
f0102a18:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102a1f:	76 42                	jbe    f0102a63 <mem_init+0x16b9>
f0102a21:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102a24:	8d 14 31             	lea    (%ecx,%esi,1),%edx
f0102a27:	39 d0                	cmp    %edx,%eax
f0102a29:	75 53                	jne    f0102a7e <mem_init+0x16d4>
f0102a2b:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
f0102a31:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102a37:	75 d5                	jne    f0102a0e <mem_init+0x1664>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a39:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0102a3c:	c1 e0 0c             	shl    $0xc,%eax
f0102a3f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102a42:	89 fe                	mov    %edi,%esi
f0102a44:	3b 75 cc             	cmp    -0x34(%ebp),%esi
f0102a47:	73 73                	jae    f0102abc <mem_init+0x1712>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102a49:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0102a4f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a52:	e8 29 e1 ff ff       	call   f0100b80 <check_va2pa>
f0102a57:	39 c6                	cmp    %eax,%esi
f0102a59:	75 42                	jne    f0102a9d <mem_init+0x16f3>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a5b:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102a61:	eb e1                	jmp    f0102a44 <mem_init+0x169a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a63:	ff 75 c4             	pushl  -0x3c(%ebp)
f0102a66:	8d 83 94 8b f7 ff    	lea    -0x8746c(%ebx),%eax
f0102a6c:	50                   	push   %eax
f0102a6d:	68 6e 03 00 00       	push   $0x36e
f0102a72:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102a78:	50                   	push   %eax
f0102a79:	e8 37 d6 ff ff       	call   f01000b5 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102a7e:	8d 83 44 90 f7 ff    	lea    -0x86fbc(%ebx),%eax
f0102a84:	50                   	push   %eax
f0102a85:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102a8b:	50                   	push   %eax
f0102a8c:	68 6e 03 00 00       	push   $0x36e
f0102a91:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102a97:	50                   	push   %eax
f0102a98:	e8 18 d6 ff ff       	call   f01000b5 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102a9d:	8d 83 78 90 f7 ff    	lea    -0x86f88(%ebx),%eax
f0102aa3:	50                   	push   %eax
f0102aa4:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102aaa:	50                   	push   %eax
f0102aab:	68 72 03 00 00       	push   $0x372
f0102ab0:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102ab6:	50                   	push   %eax
f0102ab7:	e8 f9 d5 ff ff       	call   f01000b5 <_panic>
f0102abc:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102ac1:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102ac4:	05 00 80 00 20       	add    $0x20008000,%eax
f0102ac9:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102acc:	89 f2                	mov    %esi,%edx
f0102ace:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ad1:	e8 aa e0 ff ff       	call   f0100b80 <check_va2pa>
f0102ad6:	89 c2                	mov    %eax,%edx
f0102ad8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102adb:	01 f0                	add    %esi,%eax
f0102add:	39 c2                	cmp    %eax,%edx
f0102adf:	75 25                	jne    f0102b06 <mem_init+0x175c>
f0102ae1:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102ae7:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102aed:	75 dd                	jne    f0102acc <mem_init+0x1722>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102aef:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102af4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102af7:	e8 84 e0 ff ff       	call   f0100b80 <check_va2pa>
f0102afc:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102aff:	75 24                	jne    f0102b25 <mem_init+0x177b>
f0102b01:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b04:	eb 6b                	jmp    f0102b71 <mem_init+0x17c7>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102b06:	8d 83 a0 90 f7 ff    	lea    -0x86f60(%ebx),%eax
f0102b0c:	50                   	push   %eax
f0102b0d:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102b13:	50                   	push   %eax
f0102b14:	68 76 03 00 00       	push   $0x376
f0102b19:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102b1f:	50                   	push   %eax
f0102b20:	e8 90 d5 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102b25:	8d 83 e8 90 f7 ff    	lea    -0x86f18(%ebx),%eax
f0102b2b:	50                   	push   %eax
f0102b2c:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102b32:	50                   	push   %eax
f0102b33:	68 77 03 00 00       	push   $0x377
f0102b38:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102b3e:	50                   	push   %eax
f0102b3f:	e8 71 d5 ff ff       	call   f01000b5 <_panic>
		switch (i) {
f0102b44:	81 ff bf 03 00 00    	cmp    $0x3bf,%edi
f0102b4a:	75 25                	jne    f0102b71 <mem_init+0x17c7>
			assert(pgdir[i] & PTE_P);
f0102b4c:	f6 04 b8 01          	testb  $0x1,(%eax,%edi,4)
f0102b50:	74 4c                	je     f0102b9e <mem_init+0x17f4>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b52:	83 c7 01             	add    $0x1,%edi
f0102b55:	81 ff ff 03 00 00    	cmp    $0x3ff,%edi
f0102b5b:	0f 87 a7 00 00 00    	ja     f0102c08 <mem_init+0x185e>
		switch (i) {
f0102b61:	81 ff bd 03 00 00    	cmp    $0x3bd,%edi
f0102b67:	77 db                	ja     f0102b44 <mem_init+0x179a>
f0102b69:	81 ff ba 03 00 00    	cmp    $0x3ba,%edi
f0102b6f:	77 db                	ja     f0102b4c <mem_init+0x17a2>
			if (i >= PDX(KERNBASE)) {
f0102b71:	81 ff bf 03 00 00    	cmp    $0x3bf,%edi
f0102b77:	77 44                	ja     f0102bbd <mem_init+0x1813>
				assert(pgdir[i] == 0);
f0102b79:	83 3c b8 00          	cmpl   $0x0,(%eax,%edi,4)
f0102b7d:	74 d3                	je     f0102b52 <mem_init+0x17a8>
f0102b7f:	8d 83 e2 94 f7 ff    	lea    -0x86b1e(%ebx),%eax
f0102b85:	50                   	push   %eax
f0102b86:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102b8c:	50                   	push   %eax
f0102b8d:	68 87 03 00 00       	push   $0x387
f0102b92:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102b98:	50                   	push   %eax
f0102b99:	e8 17 d5 ff ff       	call   f01000b5 <_panic>
			assert(pgdir[i] & PTE_P);
f0102b9e:	8d 83 c0 94 f7 ff    	lea    -0x86b40(%ebx),%eax
f0102ba4:	50                   	push   %eax
f0102ba5:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102bab:	50                   	push   %eax
f0102bac:	68 80 03 00 00       	push   $0x380
f0102bb1:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102bb7:	50                   	push   %eax
f0102bb8:	e8 f8 d4 ff ff       	call   f01000b5 <_panic>
				assert(pgdir[i] & PTE_P);
f0102bbd:	8b 14 b8             	mov    (%eax,%edi,4),%edx
f0102bc0:	f6 c2 01             	test   $0x1,%dl
f0102bc3:	74 24                	je     f0102be9 <mem_init+0x183f>
				assert(pgdir[i] & PTE_W);
f0102bc5:	f6 c2 02             	test   $0x2,%dl
f0102bc8:	75 88                	jne    f0102b52 <mem_init+0x17a8>
f0102bca:	8d 83 d1 94 f7 ff    	lea    -0x86b2f(%ebx),%eax
f0102bd0:	50                   	push   %eax
f0102bd1:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102bd7:	50                   	push   %eax
f0102bd8:	68 85 03 00 00       	push   $0x385
f0102bdd:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102be3:	50                   	push   %eax
f0102be4:	e8 cc d4 ff ff       	call   f01000b5 <_panic>
				assert(pgdir[i] & PTE_P);
f0102be9:	8d 83 c0 94 f7 ff    	lea    -0x86b40(%ebx),%eax
f0102bef:	50                   	push   %eax
f0102bf0:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102bf6:	50                   	push   %eax
f0102bf7:	68 84 03 00 00       	push   $0x384
f0102bfc:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102c02:	50                   	push   %eax
f0102c03:	e8 ad d4 ff ff       	call   f01000b5 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102c08:	83 ec 0c             	sub    $0xc,%esp
f0102c0b:	8d 83 18 91 f7 ff    	lea    -0x86ee8(%ebx),%eax
f0102c11:	50                   	push   %eax
f0102c12:	e8 de 0d 00 00       	call   f01039f5 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102c17:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0102c1d:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102c1f:	83 c4 10             	add    $0x10,%esp
f0102c22:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c27:	0f 86 30 02 00 00    	jbe    f0102e5d <mem_init+0x1ab3>
	return (physaddr_t)kva - KERNBASE;
f0102c2d:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102c32:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102c35:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c3a:	e8 bd df ff ff       	call   f0100bfc <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102c3f:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102c42:	83 e0 f3             	and    $0xfffffff3,%eax
f0102c45:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102c4a:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102c4d:	83 ec 0c             	sub    $0xc,%esp
f0102c50:	6a 00                	push   $0x0
f0102c52:	e8 fa e3 ff ff       	call   f0101051 <page_alloc>
f0102c57:	89 c6                	mov    %eax,%esi
f0102c59:	83 c4 10             	add    $0x10,%esp
f0102c5c:	85 c0                	test   %eax,%eax
f0102c5e:	0f 84 12 02 00 00    	je     f0102e76 <mem_init+0x1acc>
	assert((pp1 = page_alloc(0)));
f0102c64:	83 ec 0c             	sub    $0xc,%esp
f0102c67:	6a 00                	push   $0x0
f0102c69:	e8 e3 e3 ff ff       	call   f0101051 <page_alloc>
f0102c6e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102c71:	83 c4 10             	add    $0x10,%esp
f0102c74:	85 c0                	test   %eax,%eax
f0102c76:	0f 84 19 02 00 00    	je     f0102e95 <mem_init+0x1aeb>
	assert((pp2 = page_alloc(0)));
f0102c7c:	83 ec 0c             	sub    $0xc,%esp
f0102c7f:	6a 00                	push   $0x0
f0102c81:	e8 cb e3 ff ff       	call   f0101051 <page_alloc>
f0102c86:	89 c7                	mov    %eax,%edi
f0102c88:	83 c4 10             	add    $0x10,%esp
f0102c8b:	85 c0                	test   %eax,%eax
f0102c8d:	0f 84 21 02 00 00    	je     f0102eb4 <mem_init+0x1b0a>
	page_free(pp0);
f0102c93:	83 ec 0c             	sub    $0xc,%esp
f0102c96:	56                   	push   %esi
f0102c97:	e8 44 e4 ff ff       	call   f01010e0 <page_free>
	return (pp - pages) << PGSHIFT;
f0102c9c:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f0102ca2:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102ca5:	2b 08                	sub    (%eax),%ecx
f0102ca7:	89 c8                	mov    %ecx,%eax
f0102ca9:	c1 f8 03             	sar    $0x3,%eax
f0102cac:	89 c2                	mov    %eax,%edx
f0102cae:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102cb1:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102cb6:	83 c4 10             	add    $0x10,%esp
f0102cb9:	c7 c1 08 00 19 f0    	mov    $0xf0190008,%ecx
f0102cbf:	3b 01                	cmp    (%ecx),%eax
f0102cc1:	0f 83 0c 02 00 00    	jae    f0102ed3 <mem_init+0x1b29>
	memset(page2kva(pp1), 1, PGSIZE);
f0102cc7:	83 ec 04             	sub    $0x4,%esp
f0102cca:	68 00 10 00 00       	push   $0x1000
f0102ccf:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102cd1:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102cd7:	52                   	push   %edx
f0102cd8:	e8 c2 23 00 00       	call   f010509f <memset>
	return (pp - pages) << PGSHIFT;
f0102cdd:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f0102ce3:	89 f9                	mov    %edi,%ecx
f0102ce5:	2b 08                	sub    (%eax),%ecx
f0102ce7:	89 c8                	mov    %ecx,%eax
f0102ce9:	c1 f8 03             	sar    $0x3,%eax
f0102cec:	89 c2                	mov    %eax,%edx
f0102cee:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102cf1:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102cf6:	83 c4 10             	add    $0x10,%esp
f0102cf9:	c7 c1 08 00 19 f0    	mov    $0xf0190008,%ecx
f0102cff:	3b 01                	cmp    (%ecx),%eax
f0102d01:	0f 83 e2 01 00 00    	jae    f0102ee9 <mem_init+0x1b3f>
	memset(page2kva(pp2), 2, PGSIZE);
f0102d07:	83 ec 04             	sub    $0x4,%esp
f0102d0a:	68 00 10 00 00       	push   $0x1000
f0102d0f:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102d11:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102d17:	52                   	push   %edx
f0102d18:	e8 82 23 00 00       	call   f010509f <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102d1d:	6a 02                	push   $0x2
f0102d1f:	68 00 10 00 00       	push   $0x1000
f0102d24:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102d27:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0102d2d:	ff 30                	pushl  (%eax)
f0102d2f:	e8 e8 e5 ff ff       	call   f010131c <page_insert>
	assert(pp1->pp_ref == 1);
f0102d34:	83 c4 20             	add    $0x20,%esp
f0102d37:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d3a:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102d3f:	0f 85 ba 01 00 00    	jne    f0102eff <mem_init+0x1b55>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102d45:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102d4c:	01 01 01 
f0102d4f:	0f 85 c9 01 00 00    	jne    f0102f1e <mem_init+0x1b74>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102d55:	6a 02                	push   $0x2
f0102d57:	68 00 10 00 00       	push   $0x1000
f0102d5c:	57                   	push   %edi
f0102d5d:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0102d63:	ff 30                	pushl  (%eax)
f0102d65:	e8 b2 e5 ff ff       	call   f010131c <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102d6a:	83 c4 10             	add    $0x10,%esp
f0102d6d:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102d74:	02 02 02 
f0102d77:	0f 85 c0 01 00 00    	jne    f0102f3d <mem_init+0x1b93>
	assert(pp2->pp_ref == 1);
f0102d7d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102d82:	0f 85 d4 01 00 00    	jne    f0102f5c <mem_init+0x1bb2>
	assert(pp1->pp_ref == 0);
f0102d88:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d8b:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102d90:	0f 85 e5 01 00 00    	jne    f0102f7b <mem_init+0x1bd1>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d96:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d9d:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102da0:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f0102da6:	89 f9                	mov    %edi,%ecx
f0102da8:	2b 08                	sub    (%eax),%ecx
f0102daa:	89 c8                	mov    %ecx,%eax
f0102dac:	c1 f8 03             	sar    $0x3,%eax
f0102daf:	89 c2                	mov    %eax,%edx
f0102db1:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102db4:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102db9:	c7 c1 08 00 19 f0    	mov    $0xf0190008,%ecx
f0102dbf:	3b 01                	cmp    (%ecx),%eax
f0102dc1:	0f 83 d3 01 00 00    	jae    f0102f9a <mem_init+0x1bf0>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102dc7:	81 ba 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%edx)
f0102dce:	03 03 03 
f0102dd1:	0f 85 d9 01 00 00    	jne    f0102fb0 <mem_init+0x1c06>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102dd7:	83 ec 08             	sub    $0x8,%esp
f0102dda:	68 00 10 00 00       	push   $0x1000
f0102ddf:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0102de5:	ff 30                	pushl  (%eax)
f0102de7:	e8 ea e4 ff ff       	call   f01012d6 <page_remove>
	assert(pp2->pp_ref == 0);
f0102dec:	83 c4 10             	add    $0x10,%esp
f0102def:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102df4:	0f 85 d5 01 00 00    	jne    f0102fcf <mem_init+0x1c25>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102dfa:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0102e00:	8b 08                	mov    (%eax),%ecx
f0102e02:	8b 11                	mov    (%ecx),%edx
f0102e04:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102e0a:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f0102e10:	89 f7                	mov    %esi,%edi
f0102e12:	2b 38                	sub    (%eax),%edi
f0102e14:	89 f8                	mov    %edi,%eax
f0102e16:	c1 f8 03             	sar    $0x3,%eax
f0102e19:	c1 e0 0c             	shl    $0xc,%eax
f0102e1c:	39 c2                	cmp    %eax,%edx
f0102e1e:	0f 85 ca 01 00 00    	jne    f0102fee <mem_init+0x1c44>
	kern_pgdir[0] = 0;
f0102e24:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102e2a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102e2f:	0f 85 d8 01 00 00    	jne    f010300d <mem_init+0x1c63>
	pp0->pp_ref = 0;
f0102e35:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102e3b:	83 ec 0c             	sub    $0xc,%esp
f0102e3e:	56                   	push   %esi
f0102e3f:	e8 9c e2 ff ff       	call   f01010e0 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e44:	8d 83 ac 91 f7 ff    	lea    -0x86e54(%ebx),%eax
f0102e4a:	89 04 24             	mov    %eax,(%esp)
f0102e4d:	e8 a3 0b 00 00       	call   f01039f5 <cprintf>
}
f0102e52:	83 c4 10             	add    $0x10,%esp
f0102e55:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e58:	5b                   	pop    %ebx
f0102e59:	5e                   	pop    %esi
f0102e5a:	5f                   	pop    %edi
f0102e5b:	5d                   	pop    %ebp
f0102e5c:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e5d:	50                   	push   %eax
f0102e5e:	8d 83 94 8b f7 ff    	lea    -0x8746c(%ebx),%eax
f0102e64:	50                   	push   %eax
f0102e65:	68 f1 00 00 00       	push   $0xf1
f0102e6a:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102e70:	50                   	push   %eax
f0102e71:	e8 3f d2 ff ff       	call   f01000b5 <_panic>
	assert((pp0 = page_alloc(0)));
f0102e76:	8d 83 de 92 f7 ff    	lea    -0x86d22(%ebx),%eax
f0102e7c:	50                   	push   %eax
f0102e7d:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102e83:	50                   	push   %eax
f0102e84:	68 47 04 00 00       	push   $0x447
f0102e89:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102e8f:	50                   	push   %eax
f0102e90:	e8 20 d2 ff ff       	call   f01000b5 <_panic>
	assert((pp1 = page_alloc(0)));
f0102e95:	8d 83 f4 92 f7 ff    	lea    -0x86d0c(%ebx),%eax
f0102e9b:	50                   	push   %eax
f0102e9c:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102ea2:	50                   	push   %eax
f0102ea3:	68 48 04 00 00       	push   $0x448
f0102ea8:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102eae:	50                   	push   %eax
f0102eaf:	e8 01 d2 ff ff       	call   f01000b5 <_panic>
	assert((pp2 = page_alloc(0)));
f0102eb4:	8d 83 0a 93 f7 ff    	lea    -0x86cf6(%ebx),%eax
f0102eba:	50                   	push   %eax
f0102ebb:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102ec1:	50                   	push   %eax
f0102ec2:	68 49 04 00 00       	push   $0x449
f0102ec7:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102ecd:	50                   	push   %eax
f0102ece:	e8 e2 d1 ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ed3:	52                   	push   %edx
f0102ed4:	8d 83 e4 89 f7 ff    	lea    -0x8761c(%ebx),%eax
f0102eda:	50                   	push   %eax
f0102edb:	6a 56                	push   $0x56
f0102edd:	8d 83 19 92 f7 ff    	lea    -0x86de7(%ebx),%eax
f0102ee3:	50                   	push   %eax
f0102ee4:	e8 cc d1 ff ff       	call   f01000b5 <_panic>
f0102ee9:	52                   	push   %edx
f0102eea:	8d 83 e4 89 f7 ff    	lea    -0x8761c(%ebx),%eax
f0102ef0:	50                   	push   %eax
f0102ef1:	6a 56                	push   $0x56
f0102ef3:	8d 83 19 92 f7 ff    	lea    -0x86de7(%ebx),%eax
f0102ef9:	50                   	push   %eax
f0102efa:	e8 b6 d1 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 1);
f0102eff:	8d 83 db 93 f7 ff    	lea    -0x86c25(%ebx),%eax
f0102f05:	50                   	push   %eax
f0102f06:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102f0c:	50                   	push   %eax
f0102f0d:	68 4e 04 00 00       	push   $0x44e
f0102f12:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102f18:	50                   	push   %eax
f0102f19:	e8 97 d1 ff ff       	call   f01000b5 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102f1e:	8d 83 38 91 f7 ff    	lea    -0x86ec8(%ebx),%eax
f0102f24:	50                   	push   %eax
f0102f25:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102f2b:	50                   	push   %eax
f0102f2c:	68 4f 04 00 00       	push   $0x44f
f0102f31:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102f37:	50                   	push   %eax
f0102f38:	e8 78 d1 ff ff       	call   f01000b5 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102f3d:	8d 83 5c 91 f7 ff    	lea    -0x86ea4(%ebx),%eax
f0102f43:	50                   	push   %eax
f0102f44:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102f4a:	50                   	push   %eax
f0102f4b:	68 51 04 00 00       	push   $0x451
f0102f50:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102f56:	50                   	push   %eax
f0102f57:	e8 59 d1 ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 1);
f0102f5c:	8d 83 fd 93 f7 ff    	lea    -0x86c03(%ebx),%eax
f0102f62:	50                   	push   %eax
f0102f63:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102f69:	50                   	push   %eax
f0102f6a:	68 52 04 00 00       	push   $0x452
f0102f6f:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102f75:	50                   	push   %eax
f0102f76:	e8 3a d1 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 0);
f0102f7b:	8d 83 67 94 f7 ff    	lea    -0x86b99(%ebx),%eax
f0102f81:	50                   	push   %eax
f0102f82:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102f88:	50                   	push   %eax
f0102f89:	68 53 04 00 00       	push   $0x453
f0102f8e:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102f94:	50                   	push   %eax
f0102f95:	e8 1b d1 ff ff       	call   f01000b5 <_panic>
f0102f9a:	52                   	push   %edx
f0102f9b:	8d 83 e4 89 f7 ff    	lea    -0x8761c(%ebx),%eax
f0102fa1:	50                   	push   %eax
f0102fa2:	6a 56                	push   $0x56
f0102fa4:	8d 83 19 92 f7 ff    	lea    -0x86de7(%ebx),%eax
f0102faa:	50                   	push   %eax
f0102fab:	e8 05 d1 ff ff       	call   f01000b5 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102fb0:	8d 83 80 91 f7 ff    	lea    -0x86e80(%ebx),%eax
f0102fb6:	50                   	push   %eax
f0102fb7:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102fbd:	50                   	push   %eax
f0102fbe:	68 55 04 00 00       	push   $0x455
f0102fc3:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102fc9:	50                   	push   %eax
f0102fca:	e8 e6 d0 ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 0);
f0102fcf:	8d 83 35 94 f7 ff    	lea    -0x86bcb(%ebx),%eax
f0102fd5:	50                   	push   %eax
f0102fd6:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102fdc:	50                   	push   %eax
f0102fdd:	68 57 04 00 00       	push   $0x457
f0102fe2:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0102fe8:	50                   	push   %eax
f0102fe9:	e8 c7 d0 ff ff       	call   f01000b5 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102fee:	8d 83 90 8c f7 ff    	lea    -0x87370(%ebx),%eax
f0102ff4:	50                   	push   %eax
f0102ff5:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0102ffb:	50                   	push   %eax
f0102ffc:	68 5a 04 00 00       	push   $0x45a
f0103001:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0103007:	50                   	push   %eax
f0103008:	e8 a8 d0 ff ff       	call   f01000b5 <_panic>
	assert(pp0->pp_ref == 1);
f010300d:	8d 83 ec 93 f7 ff    	lea    -0x86c14(%ebx),%eax
f0103013:	50                   	push   %eax
f0103014:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f010301a:	50                   	push   %eax
f010301b:	68 5c 04 00 00       	push   $0x45c
f0103020:	8d 83 0d 92 f7 ff    	lea    -0x86df3(%ebx),%eax
f0103026:	50                   	push   %eax
f0103027:	e8 89 d0 ff ff       	call   f01000b5 <_panic>

f010302c <tlb_invalidate>:
{
f010302c:	f3 0f 1e fb          	endbr32 
f0103030:	55                   	push   %ebp
f0103031:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0103033:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103036:	0f 01 38             	invlpg (%eax)
}
f0103039:	5d                   	pop    %ebp
f010303a:	c3                   	ret    

f010303b <user_mem_check>:
{
f010303b:	f3 0f 1e fb          	endbr32 
f010303f:	55                   	push   %ebp
f0103040:	89 e5                	mov    %esp,%ebp
f0103042:	57                   	push   %edi
f0103043:	56                   	push   %esi
f0103044:	53                   	push   %ebx
f0103045:	83 ec 2c             	sub    $0x2c,%esp
f0103048:	e8 da d6 ff ff       	call   f0100727 <__x86.get_pc_thunk.ax>
f010304d:	05 cf 9f 08 00       	add    $0x89fcf,%eax
f0103052:	89 45 cc             	mov    %eax,-0x34(%ebp)
	pde_t* pgdir = env->env_pgdir;
f0103055:	8b 45 08             	mov    0x8(%ebp),%eax
f0103058:	8b 78 5c             	mov    0x5c(%eax),%edi
	uintptr_t address = (uintptr_t)va;
f010305b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010305e:	89 45 c8             	mov    %eax,-0x38(%ebp)
	perm = perm | PTE_U | PTE_P;
f0103061:	8b 45 14             	mov    0x14(%ebp),%eax
f0103064:	83 c8 05             	or     $0x5,%eax
f0103067:	89 45 d0             	mov    %eax,-0x30(%ebp)
	pte_t* entry = NULL;
f010306a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	uintptr_t address = (uintptr_t)va;
f0103071:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	for(; address<(uintptr_t)(va+len);address+=PGSIZE)
f0103074:	89 d8                	mov    %ebx,%eax
f0103076:	03 45 10             	add    0x10(%ebp),%eax
f0103079:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		if(page_lookup(pgdir,(void*)address,&entry) == NULL)
f010307c:	8d 75 e4             	lea    -0x1c(%ebp),%esi
	for(; address<(uintptr_t)(va+len);address+=PGSIZE)
f010307f:	eb 06                	jmp    f0103087 <user_mem_check+0x4c>
f0103081:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0103087:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010308a:	76 42                	jbe    f01030ce <user_mem_check+0x93>
		if(address>=ULIM)
f010308c:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0103092:	77 1c                	ja     f01030b0 <user_mem_check+0x75>
		if(page_lookup(pgdir,(void*)address,&entry) == NULL)
f0103094:	83 ec 04             	sub    $0x4,%esp
f0103097:	56                   	push   %esi
f0103098:	53                   	push   %ebx
f0103099:	57                   	push   %edi
f010309a:	e8 b8 e1 ff ff       	call   f0101257 <page_lookup>
f010309f:	83 c4 10             	add    $0x10,%esp
f01030a2:	85 c0                	test   %eax,%eax
f01030a4:	74 0a                	je     f01030b0 <user_mem_check+0x75>
		if(!(*entry & perm))
f01030a6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030a9:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01030ac:	85 10                	test   %edx,(%eax)
f01030ae:	75 d1                	jne    f0103081 <user_mem_check+0x46>
		user_mem_check_addr = (address == (uintptr_t)va ? address : ROUNDDOWN(address,PGSIZE));
f01030b0:	89 d8                	mov    %ebx,%eax
f01030b2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01030b7:	39 5d 0c             	cmp    %ebx,0xc(%ebp)
f01030ba:	0f 44 45 c8          	cmove  -0x38(%ebp),%eax
f01030be:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01030c1:	89 81 20 23 00 00    	mov    %eax,0x2320(%ecx)
		return -E_FAULT;
f01030c7:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01030cc:	eb 05                	jmp    f01030d3 <user_mem_check+0x98>
	return 0;
f01030ce:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01030d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030d6:	5b                   	pop    %ebx
f01030d7:	5e                   	pop    %esi
f01030d8:	5f                   	pop    %edi
f01030d9:	5d                   	pop    %ebp
f01030da:	c3                   	ret    

f01030db <user_mem_assert>:
{
f01030db:	f3 0f 1e fb          	endbr32 
f01030df:	55                   	push   %ebp
f01030e0:	89 e5                	mov    %esp,%ebp
f01030e2:	56                   	push   %esi
f01030e3:	53                   	push   %ebx
f01030e4:	e8 8a d0 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01030e9:	81 c3 33 9f 08 00    	add    $0x89f33,%ebx
f01030ef:	8b 75 08             	mov    0x8(%ebp),%esi
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f01030f2:	8b 45 14             	mov    0x14(%ebp),%eax
f01030f5:	83 c8 04             	or     $0x4,%eax
f01030f8:	50                   	push   %eax
f01030f9:	ff 75 10             	pushl  0x10(%ebp)
f01030fc:	ff 75 0c             	pushl  0xc(%ebp)
f01030ff:	56                   	push   %esi
f0103100:	e8 36 ff ff ff       	call   f010303b <user_mem_check>
f0103105:	83 c4 10             	add    $0x10,%esp
f0103108:	85 c0                	test   %eax,%eax
f010310a:	78 07                	js     f0103113 <user_mem_assert+0x38>
}
f010310c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010310f:	5b                   	pop    %ebx
f0103110:	5e                   	pop    %esi
f0103111:	5d                   	pop    %ebp
f0103112:	c3                   	ret    
		cprintf("[%08x] user_mem_check assertion failure for "
f0103113:	83 ec 04             	sub    $0x4,%esp
f0103116:	ff b3 20 23 00 00    	pushl  0x2320(%ebx)
f010311c:	ff 76 48             	pushl  0x48(%esi)
f010311f:	8d 83 d8 91 f7 ff    	lea    -0x86e28(%ebx),%eax
f0103125:	50                   	push   %eax
f0103126:	e8 ca 08 00 00       	call   f01039f5 <cprintf>
		env_destroy(env);	// may not return
f010312b:	89 34 24             	mov    %esi,(%esp)
f010312e:	e8 3c 07 00 00       	call   f010386f <env_destroy>
f0103133:	83 c4 10             	add    $0x10,%esp
}
f0103136:	eb d4                	jmp    f010310c <user_mem_assert+0x31>

f0103138 <__x86.get_pc_thunk.dx>:
f0103138:	8b 14 24             	mov    (%esp),%edx
f010313b:	c3                   	ret    

f010313c <__x86.get_pc_thunk.cx>:
f010313c:	8b 0c 24             	mov    (%esp),%ecx
f010313f:	c3                   	ret    

f0103140 <__x86.get_pc_thunk.di>:
f0103140:	8b 3c 24             	mov    (%esp),%edi
f0103143:	c3                   	ret    

f0103144 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0103144:	55                   	push   %ebp
f0103145:	89 e5                	mov    %esp,%ebp
f0103147:	57                   	push   %edi
f0103148:	56                   	push   %esi
f0103149:	53                   	push   %ebx
f010314a:	83 ec 1c             	sub    $0x1c,%esp
f010314d:	e8 21 d0 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103152:	81 c3 ca 9e 08 00    	add    $0x89eca,%ebx
f0103158:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void* start = (void*)ROUNDDOWN((uint32_t)va,PGSIZE);
f010315a:	89 d6                	mov    %edx,%esi
f010315c:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	void* end = (void*)ROUNDUP((uint32_t)va+len,PGSIZE);
f0103162:	8d 84 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%eax
f0103169:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010316e:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	// corner case 1: too large length
	if(start>end)
f0103171:	39 c6                	cmp    %eax,%esi
f0103173:	77 31                	ja     f01031a6 <region_alloc+0x62>
		panic("At region_alloc: too large length\n");
	}
	struct PageInfo* p = NULL;

	// allocate PA by the size of a page
	for(void* v = start;v<end;v+=PGSIZE)
f0103175:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0103178:	73 7d                	jae    f01031f7 <region_alloc+0xb3>
	{
		p = page_alloc(0);
f010317a:	83 ec 0c             	sub    $0xc,%esp
f010317d:	6a 00                	push   $0x0
f010317f:	e8 cd de ff ff       	call   f0101051 <page_alloc>
		// corner case 2: page allocation failed
		if(p == NULL)
f0103184:	83 c4 10             	add    $0x10,%esp
f0103187:	85 c0                	test   %eax,%eax
f0103189:	74 36                	je     f01031c1 <region_alloc+0x7d>
		{
			panic("At region_alloc: Page allocation failed");
		}

		// insert into page table
		int insert = page_insert(e->env_pgdir,p,v,PTE_W|PTE_U);
f010318b:	6a 06                	push   $0x6
f010318d:	56                   	push   %esi
f010318e:	50                   	push   %eax
f010318f:	ff 77 5c             	pushl  0x5c(%edi)
f0103192:	e8 85 e1 ff ff       	call   f010131c <page_insert>

		// corner case 3: insertion failed
		if(insert!=0)
f0103197:	83 c4 10             	add    $0x10,%esp
f010319a:	85 c0                	test   %eax,%eax
f010319c:	75 3e                	jne    f01031dc <region_alloc+0x98>
	for(void* v = start;v<end;v+=PGSIZE)
f010319e:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01031a4:	eb cf                	jmp    f0103175 <region_alloc+0x31>
		panic("At region_alloc: too large length\n");
f01031a6:	83 ec 04             	sub    $0x4,%esp
f01031a9:	8d 83 f0 94 f7 ff    	lea    -0x86b10(%ebx),%eax
f01031af:	50                   	push   %eax
f01031b0:	68 2b 01 00 00       	push   $0x12b
f01031b5:	8d 83 1e 96 f7 ff    	lea    -0x869e2(%ebx),%eax
f01031bb:	50                   	push   %eax
f01031bc:	e8 f4 ce ff ff       	call   f01000b5 <_panic>
			panic("At region_alloc: Page allocation failed");
f01031c1:	83 ec 04             	sub    $0x4,%esp
f01031c4:	8d 83 14 95 f7 ff    	lea    -0x86aec(%ebx),%eax
f01031ca:	50                   	push   %eax
f01031cb:	68 36 01 00 00       	push   $0x136
f01031d0:	8d 83 1e 96 f7 ff    	lea    -0x869e2(%ebx),%eax
f01031d6:	50                   	push   %eax
f01031d7:	e8 d9 ce ff ff       	call   f01000b5 <_panic>
		{
			panic("At region_alloc: Page insertion failed");
f01031dc:	83 ec 04             	sub    $0x4,%esp
f01031df:	8d 83 3c 95 f7 ff    	lea    -0x86ac4(%ebx),%eax
f01031e5:	50                   	push   %eax
f01031e6:	68 3f 01 00 00       	push   $0x13f
f01031eb:	8d 83 1e 96 f7 ff    	lea    -0x869e2(%ebx),%eax
f01031f1:	50                   	push   %eax
f01031f2:	e8 be ce ff ff       	call   f01000b5 <_panic>
		}
	}
}
f01031f7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01031fa:	5b                   	pop    %ebx
f01031fb:	5e                   	pop    %esi
f01031fc:	5f                   	pop    %edi
f01031fd:	5d                   	pop    %ebp
f01031fe:	c3                   	ret    

f01031ff <envid2env>:
{
f01031ff:	f3 0f 1e fb          	endbr32 
f0103203:	55                   	push   %ebp
f0103204:	89 e5                	mov    %esp,%ebp
f0103206:	53                   	push   %ebx
f0103207:	e8 30 ff ff ff       	call   f010313c <__x86.get_pc_thunk.cx>
f010320c:	81 c1 10 9e 08 00    	add    $0x89e10,%ecx
f0103212:	8b 45 08             	mov    0x8(%ebp),%eax
f0103215:	8b 5d 10             	mov    0x10(%ebp),%ebx
	if (envid == 0) {
f0103218:	85 c0                	test   %eax,%eax
f010321a:	74 42                	je     f010325e <envid2env+0x5f>
	e = &envs[ENVX(envid)];
f010321c:	89 c2                	mov    %eax,%edx
f010321e:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0103224:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103227:	c1 e2 05             	shl    $0x5,%edx
f010322a:	03 91 30 23 00 00    	add    0x2330(%ecx),%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103230:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0103234:	74 35                	je     f010326b <envid2env+0x6c>
f0103236:	39 42 48             	cmp    %eax,0x48(%edx)
f0103239:	75 30                	jne    f010326b <envid2env+0x6c>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010323b:	84 db                	test   %bl,%bl
f010323d:	74 12                	je     f0103251 <envid2env+0x52>
f010323f:	8b 81 2c 23 00 00    	mov    0x232c(%ecx),%eax
f0103245:	39 d0                	cmp    %edx,%eax
f0103247:	74 08                	je     f0103251 <envid2env+0x52>
f0103249:	8b 40 48             	mov    0x48(%eax),%eax
f010324c:	39 42 4c             	cmp    %eax,0x4c(%edx)
f010324f:	75 2a                	jne    f010327b <envid2env+0x7c>
	*env_store = e;
f0103251:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103254:	89 10                	mov    %edx,(%eax)
	return 0;
f0103256:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010325b:	5b                   	pop    %ebx
f010325c:	5d                   	pop    %ebp
f010325d:	c3                   	ret    
		*env_store = curenv;
f010325e:	8b 91 2c 23 00 00    	mov    0x232c(%ecx),%edx
f0103264:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103267:	89 13                	mov    %edx,(%ebx)
		return 0;
f0103269:	eb f0                	jmp    f010325b <envid2env+0x5c>
		*env_store = 0;
f010326b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010326e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103274:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103279:	eb e0                	jmp    f010325b <envid2env+0x5c>
		*env_store = 0;
f010327b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010327e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103284:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103289:	eb d0                	jmp    f010325b <envid2env+0x5c>

f010328b <env_init_percpu>:
{
f010328b:	f3 0f 1e fb          	endbr32 
f010328f:	e8 93 d4 ff ff       	call   f0100727 <__x86.get_pc_thunk.ax>
f0103294:	05 88 9d 08 00       	add    $0x89d88,%eax
	asm volatile("lgdt (%0)" : : "r" (p));
f0103299:	8d 80 e4 1f 00 00    	lea    0x1fe4(%eax),%eax
f010329f:	0f 01 10             	lgdtl  (%eax)
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f01032a2:	b8 23 00 00 00       	mov    $0x23,%eax
f01032a7:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f01032a9:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f01032ab:	b8 10 00 00 00       	mov    $0x10,%eax
f01032b0:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f01032b2:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f01032b4:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f01032b6:	ea bd 32 10 f0 08 00 	ljmp   $0x8,$0xf01032bd
	asm volatile("lldt %0" : : "r" (sel));
f01032bd:	b8 00 00 00 00       	mov    $0x0,%eax
f01032c2:	0f 00 d0             	lldt   %ax
}
f01032c5:	c3                   	ret    

f01032c6 <env_init>:
{
f01032c6:	f3 0f 1e fb          	endbr32 
f01032ca:	55                   	push   %ebp
f01032cb:	89 e5                	mov    %esp,%ebp
f01032cd:	57                   	push   %edi
f01032ce:	56                   	push   %esi
f01032cf:	53                   	push   %ebx
f01032d0:	83 ec 0c             	sub    $0xc,%esp
f01032d3:	e8 68 fe ff ff       	call   f0103140 <__x86.get_pc_thunk.di>
f01032d8:	81 c7 44 9d 08 00    	add    $0x89d44,%edi
		envs[i].env_id = 0;
f01032de:	8b b7 30 23 00 00    	mov    0x2330(%edi),%esi
f01032e4:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f01032ea:	89 f3                	mov    %esi,%ebx
f01032ec:	ba 00 00 00 00       	mov    $0x0,%edx
f01032f1:	89 d1                	mov    %edx,%ecx
f01032f3:	89 c2                	mov    %eax,%edx
f01032f5:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f01032fc:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f0103303:	89 48 44             	mov    %ecx,0x44(%eax)
f0103306:	83 e8 60             	sub    $0x60,%eax
	for(int i = NENV - 1; i>=0 ;i--)
f0103309:	39 da                	cmp    %ebx,%edx
f010330b:	75 e4                	jne    f01032f1 <env_init+0x2b>
f010330d:	89 b7 34 23 00 00    	mov    %esi,0x2334(%edi)
	env_init_percpu();
f0103313:	e8 73 ff ff ff       	call   f010328b <env_init_percpu>
}
f0103318:	83 c4 0c             	add    $0xc,%esp
f010331b:	5b                   	pop    %ebx
f010331c:	5e                   	pop    %esi
f010331d:	5f                   	pop    %edi
f010331e:	5d                   	pop    %ebp
f010331f:	c3                   	ret    

f0103320 <env_alloc>:
{
f0103320:	f3 0f 1e fb          	endbr32 
f0103324:	55                   	push   %ebp
f0103325:	89 e5                	mov    %esp,%ebp
f0103327:	57                   	push   %edi
f0103328:	56                   	push   %esi
f0103329:	53                   	push   %ebx
f010332a:	83 ec 0c             	sub    $0xc,%esp
f010332d:	e8 41 ce ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103332:	81 c3 ea 9c 08 00    	add    $0x89cea,%ebx
	if (!(e = env_free_list))
f0103338:	8b b3 34 23 00 00    	mov    0x2334(%ebx),%esi
f010333e:	85 f6                	test   %esi,%esi
f0103340:	0f 84 84 01 00 00    	je     f01034ca <env_alloc+0x1aa>
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103346:	83 ec 0c             	sub    $0xc,%esp
f0103349:	6a 01                	push   $0x1
f010334b:	e8 01 dd ff ff       	call   f0101051 <page_alloc>
f0103350:	83 c4 10             	add    $0x10,%esp
f0103353:	85 c0                	test   %eax,%eax
f0103355:	0f 84 76 01 00 00    	je     f01034d1 <env_alloc+0x1b1>
	return (pp - pages) << PGSHIFT;
f010335b:	c7 c2 10 00 19 f0    	mov    $0xf0190010,%edx
f0103361:	89 c7                	mov    %eax,%edi
f0103363:	2b 3a                	sub    (%edx),%edi
f0103365:	89 fa                	mov    %edi,%edx
f0103367:	c1 fa 03             	sar    $0x3,%edx
f010336a:	89 d1                	mov    %edx,%ecx
f010336c:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f010336f:	81 e2 ff ff 0f 00    	and    $0xfffff,%edx
f0103375:	c7 c7 08 00 19 f0    	mov    $0xf0190008,%edi
f010337b:	3b 17                	cmp    (%edi),%edx
f010337d:	0f 83 18 01 00 00    	jae    f010349b <env_alloc+0x17b>
	return (void *)(pa + KERNBASE);
f0103383:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0103389:	89 4e 5c             	mov    %ecx,0x5c(%esi)
	p->pp_ref++;
f010338c:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f0103391:	b8 00 00 00 00       	mov    $0x0,%eax
		e->env_pgdir[i] = 0;
f0103396:	8b 56 5c             	mov    0x5c(%esi),%edx
f0103399:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f01033a0:	83 c0 04             	add    $0x4,%eax
	for(int i = 0;i<PDX(UTOP);i++)
f01033a3:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f01033a8:	75 ec                	jne    f0103396 <env_alloc+0x76>
		e->env_pgdir[i] = kern_pgdir[i];
f01033aa:	c7 c7 0c 00 19 f0    	mov    $0xf019000c,%edi
f01033b0:	8b 17                	mov    (%edi),%edx
f01033b2:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f01033b5:	8b 56 5c             	mov    0x5c(%esi),%edx
f01033b8:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f01033bb:	83 c0 04             	add    $0x4,%eax
	for(int i = PDX(UTOP);i<NPDENTRIES;i++)
f01033be:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01033c3:	75 eb                	jne    f01033b0 <env_alloc+0x90>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01033c5:	8b 46 5c             	mov    0x5c(%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f01033c8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033cd:	0f 86 de 00 00 00    	jbe    f01034b1 <env_alloc+0x191>
	return (physaddr_t)kva - KERNBASE;
f01033d3:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01033d9:	83 ca 05             	or     $0x5,%edx
f01033dc:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01033e2:	8b 46 48             	mov    0x48(%esi),%eax
f01033e5:	05 00 10 00 00       	add    $0x1000,%eax
		generation = 1 << ENVGENSHIFT;
f01033ea:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01033ef:	ba 00 10 00 00       	mov    $0x1000,%edx
f01033f4:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01033f7:	89 f2                	mov    %esi,%edx
f01033f9:	2b 93 30 23 00 00    	sub    0x2330(%ebx),%edx
f01033ff:	c1 fa 05             	sar    $0x5,%edx
f0103402:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0103408:	09 d0                	or     %edx,%eax
f010340a:	89 46 48             	mov    %eax,0x48(%esi)
	e->env_parent_id = parent_id;
f010340d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103410:	89 46 4c             	mov    %eax,0x4c(%esi)
	e->env_type = ENV_TYPE_USER;
f0103413:	c7 46 50 00 00 00 00 	movl   $0x0,0x50(%esi)
	e->env_status = ENV_RUNNABLE;
f010341a:	c7 46 54 02 00 00 00 	movl   $0x2,0x54(%esi)
	e->env_runs = 0;
f0103421:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103428:	83 ec 04             	sub    $0x4,%esp
f010342b:	6a 44                	push   $0x44
f010342d:	6a 00                	push   $0x0
f010342f:	56                   	push   %esi
f0103430:	e8 6a 1c 00 00       	call   f010509f <memset>
	e->env_tf.tf_ds = GD_UD | 3;
f0103435:	66 c7 46 24 23 00    	movw   $0x23,0x24(%esi)
	e->env_tf.tf_es = GD_UD | 3;
f010343b:	66 c7 46 20 23 00    	movw   $0x23,0x20(%esi)
	e->env_tf.tf_ss = GD_UD | 3;
f0103441:	66 c7 46 40 23 00    	movw   $0x23,0x40(%esi)
	e->env_tf.tf_esp = USTACKTOP;
f0103447:	c7 46 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%esi)
	e->env_tf.tf_cs = GD_UT | 3;
f010344e:	66 c7 46 34 1b 00    	movw   $0x1b,0x34(%esi)
	env_free_list = e->env_link;
f0103454:	8b 46 44             	mov    0x44(%esi),%eax
f0103457:	89 83 34 23 00 00    	mov    %eax,0x2334(%ebx)
	*newenv_store = e;
f010345d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103460:	89 30                	mov    %esi,(%eax)
	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103462:	8b 4e 48             	mov    0x48(%esi),%ecx
f0103465:	8b 83 2c 23 00 00    	mov    0x232c(%ebx),%eax
f010346b:	83 c4 10             	add    $0x10,%esp
f010346e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103473:	85 c0                	test   %eax,%eax
f0103475:	74 03                	je     f010347a <env_alloc+0x15a>
f0103477:	8b 50 48             	mov    0x48(%eax),%edx
f010347a:	83 ec 04             	sub    $0x4,%esp
f010347d:	51                   	push   %ecx
f010347e:	52                   	push   %edx
f010347f:	8d 83 29 96 f7 ff    	lea    -0x869d7(%ebx),%eax
f0103485:	50                   	push   %eax
f0103486:	e8 6a 05 00 00       	call   f01039f5 <cprintf>
	return 0;
f010348b:	83 c4 10             	add    $0x10,%esp
f010348e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103493:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103496:	5b                   	pop    %ebx
f0103497:	5e                   	pop    %esi
f0103498:	5f                   	pop    %edi
f0103499:	5d                   	pop    %ebp
f010349a:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010349b:	51                   	push   %ecx
f010349c:	8d 83 e4 89 f7 ff    	lea    -0x8761c(%ebx),%eax
f01034a2:	50                   	push   %eax
f01034a3:	6a 56                	push   $0x56
f01034a5:	8d 83 19 92 f7 ff    	lea    -0x86de7(%ebx),%eax
f01034ab:	50                   	push   %eax
f01034ac:	e8 04 cc ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034b1:	50                   	push   %eax
f01034b2:	8d 83 94 8b f7 ff    	lea    -0x8746c(%ebx),%eax
f01034b8:	50                   	push   %eax
f01034b9:	68 d0 00 00 00       	push   $0xd0
f01034be:	8d 83 1e 96 f7 ff    	lea    -0x869e2(%ebx),%eax
f01034c4:	50                   	push   %eax
f01034c5:	e8 eb cb ff ff       	call   f01000b5 <_panic>
		return -E_NO_FREE_ENV;
f01034ca:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01034cf:	eb c2                	jmp    f0103493 <env_alloc+0x173>
		return -E_NO_MEM;
f01034d1:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01034d6:	eb bb                	jmp    f0103493 <env_alloc+0x173>

f01034d8 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01034d8:	f3 0f 1e fb          	endbr32 
f01034dc:	55                   	push   %ebp
f01034dd:	89 e5                	mov    %esp,%ebp
f01034df:	57                   	push   %edi
f01034e0:	56                   	push   %esi
f01034e1:	53                   	push   %ebx
f01034e2:	83 ec 34             	sub    $0x34,%esp
f01034e5:	e8 89 cc ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01034ea:	81 c3 32 9b 08 00    	add    $0x89b32,%ebx
f01034f0:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env* e;
	int alloc = env_alloc(&e,0);
f01034f3:	6a 00                	push   $0x0
f01034f5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01034f8:	50                   	push   %eax
f01034f9:	e8 22 fe ff ff       	call   f0103320 <env_alloc>
	if(alloc != 0)
f01034fe:	83 c4 10             	add    $0x10,%esp
f0103501:	85 c0                	test   %eax,%eax
f0103503:	75 36                	jne    f010353b <env_create+0x63>
	{
		panic("At env_create: env_alloc() failed");
	}
	load_icode(e,binary);
f0103505:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103508:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if(elfHeader->e_magic != ELF_MAGIC)
f010350b:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103511:	75 43                	jne    f0103556 <env_create+0x7e>
	lcr3(PADDR(e->env_pgdir));
f0103513:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103516:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103519:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010351e:	76 51                	jbe    f0103571 <env_create+0x99>
	return (physaddr_t)kva - KERNBASE;
f0103520:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103525:	0f 22 d8             	mov    %eax,%cr3
	struct Proghdr* ph = (struct Proghdr*)(binary+elfHeader->e_phoff);
f0103528:	89 fe                	mov    %edi,%esi
f010352a:	03 77 1c             	add    0x1c(%edi),%esi
	struct Proghdr* phEnd = ph+elfHeader->e_phnum;
f010352d:	0f b7 47 2c          	movzwl 0x2c(%edi),%eax
f0103531:	c1 e0 05             	shl    $0x5,%eax
f0103534:	01 f0                	add    %esi,%eax
f0103536:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for(;ph<phEnd;ph++)
f0103539:	eb 6d                	jmp    f01035a8 <env_create+0xd0>
		panic("At env_create: env_alloc() failed");
f010353b:	83 ec 04             	sub    $0x4,%esp
f010353e:	8d 83 64 95 f7 ff    	lea    -0x86a9c(%ebx),%eax
f0103544:	50                   	push   %eax
f0103545:	68 b8 01 00 00       	push   $0x1b8
f010354a:	8d 83 1e 96 f7 ff    	lea    -0x869e2(%ebx),%eax
f0103550:	50                   	push   %eax
f0103551:	e8 5f cb ff ff       	call   f01000b5 <_panic>
		panic("At load_icode: Invalid head magic number");
f0103556:	83 ec 04             	sub    $0x4,%esp
f0103559:	8d 83 88 95 f7 ff    	lea    -0x86a78(%ebx),%eax
f010355f:	50                   	push   %eax
f0103560:	68 80 01 00 00       	push   $0x180
f0103565:	8d 83 1e 96 f7 ff    	lea    -0x869e2(%ebx),%eax
f010356b:	50                   	push   %eax
f010356c:	e8 44 cb ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103571:	50                   	push   %eax
f0103572:	8d 83 94 8b f7 ff    	lea    -0x8746c(%ebx),%eax
f0103578:	50                   	push   %eax
f0103579:	68 83 01 00 00       	push   $0x183
f010357e:	8d 83 1e 96 f7 ff    	lea    -0x869e2(%ebx),%eax
f0103584:	50                   	push   %eax
f0103585:	e8 2b cb ff ff       	call   f01000b5 <_panic>
				panic("At load_icode: file size bigger than memory size");
f010358a:	83 ec 04             	sub    $0x4,%esp
f010358d:	8d 83 b4 95 f7 ff    	lea    -0x86a4c(%ebx),%eax
f0103593:	50                   	push   %eax
f0103594:	68 8f 01 00 00       	push   $0x18f
f0103599:	8d 83 1e 96 f7 ff    	lea    -0x869e2(%ebx),%eax
f010359f:	50                   	push   %eax
f01035a0:	e8 10 cb ff ff       	call   f01000b5 <_panic>
	for(;ph<phEnd;ph++)
f01035a5:	83 c6 20             	add    $0x20,%esi
f01035a8:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f01035ab:	76 48                	jbe    f01035f5 <env_create+0x11d>
		if(ph->p_type == ELF_PROG_LOAD)
f01035ad:	83 3e 01             	cmpl   $0x1,(%esi)
f01035b0:	75 f3                	jne    f01035a5 <env_create+0xcd>
			if(ph->p_filesz>ph->p_memsz)
f01035b2:	8b 4e 14             	mov    0x14(%esi),%ecx
f01035b5:	39 4e 10             	cmp    %ecx,0x10(%esi)
f01035b8:	77 d0                	ja     f010358a <env_create+0xb2>
			region_alloc(e,(void*) ph->p_va,ph->p_memsz);
f01035ba:	8b 56 08             	mov    0x8(%esi),%edx
f01035bd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01035c0:	e8 7f fb ff ff       	call   f0103144 <region_alloc>
			memcpy((void*)ph->p_va,binary+ph->p_offset,ph->p_filesz);
f01035c5:	83 ec 04             	sub    $0x4,%esp
f01035c8:	ff 76 10             	pushl  0x10(%esi)
f01035cb:	89 f8                	mov    %edi,%eax
f01035cd:	03 46 04             	add    0x4(%esi),%eax
f01035d0:	50                   	push   %eax
f01035d1:	ff 76 08             	pushl  0x8(%esi)
f01035d4:	e8 78 1b 00 00       	call   f0105151 <memcpy>
			memset((void*)(ph->p_va+ph->p_filesz),0,ph->p_memsz-ph->p_filesz);
f01035d9:	8b 46 10             	mov    0x10(%esi),%eax
f01035dc:	83 c4 0c             	add    $0xc,%esp
f01035df:	8b 56 14             	mov    0x14(%esi),%edx
f01035e2:	29 c2                	sub    %eax,%edx
f01035e4:	52                   	push   %edx
f01035e5:	6a 00                	push   $0x0
f01035e7:	03 46 08             	add    0x8(%esi),%eax
f01035ea:	50                   	push   %eax
f01035eb:	e8 af 1a 00 00       	call   f010509f <memset>
f01035f0:	83 c4 10             	add    $0x10,%esp
f01035f3:	eb b0                	jmp    f01035a5 <env_create+0xcd>
	lcr3(PADDR(kern_pgdir));
f01035f5:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f01035fb:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01035fd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103602:	76 3a                	jbe    f010363e <env_create+0x166>
	return (physaddr_t)kva - KERNBASE;
f0103604:	05 00 00 00 10       	add    $0x10000000,%eax
f0103609:	0f 22 d8             	mov    %eax,%cr3
	e->env_status = ENV_RUNNABLE;
f010360c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010360f:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_tf.tf_eip = elfHeader->e_entry;
f0103616:	8b 47 18             	mov    0x18(%edi),%eax
f0103619:	89 43 30             	mov    %eax,0x30(%ebx)
	region_alloc(e,(void*)(USTACKTOP-PGSIZE),PGSIZE);
f010361c:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103621:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103626:	89 d8                	mov    %ebx,%eax
f0103628:	e8 17 fb ff ff       	call   f0103144 <region_alloc>
	e->env_type = type;
f010362d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103630:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103633:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103636:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103639:	5b                   	pop    %ebx
f010363a:	5e                   	pop    %esi
f010363b:	5f                   	pop    %edi
f010363c:	5d                   	pop    %ebp
f010363d:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010363e:	50                   	push   %eax
f010363f:	8d 83 94 8b f7 ff    	lea    -0x8746c(%ebx),%eax
f0103645:	50                   	push   %eax
f0103646:	68 9c 01 00 00       	push   $0x19c
f010364b:	8d 83 1e 96 f7 ff    	lea    -0x869e2(%ebx),%eax
f0103651:	50                   	push   %eax
f0103652:	e8 5e ca ff ff       	call   f01000b5 <_panic>

f0103657 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103657:	f3 0f 1e fb          	endbr32 
f010365b:	55                   	push   %ebp
f010365c:	89 e5                	mov    %esp,%ebp
f010365e:	57                   	push   %edi
f010365f:	56                   	push   %esi
f0103660:	53                   	push   %ebx
f0103661:	83 ec 2c             	sub    $0x2c,%esp
f0103664:	e8 0a cb ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103669:	81 c3 b3 99 08 00    	add    $0x899b3,%ebx
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f010366f:	8b 93 2c 23 00 00    	mov    0x232c(%ebx),%edx
f0103675:	3b 55 08             	cmp    0x8(%ebp),%edx
f0103678:	74 47                	je     f01036c1 <env_free+0x6a>
		lcr3(PADDR(kern_pgdir));

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010367a:	8b 45 08             	mov    0x8(%ebp),%eax
f010367d:	8b 48 48             	mov    0x48(%eax),%ecx
f0103680:	b8 00 00 00 00       	mov    $0x0,%eax
f0103685:	85 d2                	test   %edx,%edx
f0103687:	74 03                	je     f010368c <env_free+0x35>
f0103689:	8b 42 48             	mov    0x48(%edx),%eax
f010368c:	83 ec 04             	sub    $0x4,%esp
f010368f:	51                   	push   %ecx
f0103690:	50                   	push   %eax
f0103691:	8d 83 3e 96 f7 ff    	lea    -0x869c2(%ebx),%eax
f0103697:	50                   	push   %eax
f0103698:	e8 58 03 00 00       	call   f01039f5 <cprintf>
f010369d:	83 c4 10             	add    $0x10,%esp
f01036a0:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	if (PGNUM(pa) >= npages)
f01036a7:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f01036ad:	89 45 d8             	mov    %eax,-0x28(%ebp)
	if (PGNUM(pa) >= npages)
f01036b0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	return &pages[PGNUM(pa)];
f01036b3:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f01036b9:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01036bc:	e9 bf 00 00 00       	jmp    f0103780 <env_free+0x129>
		lcr3(PADDR(kern_pgdir));
f01036c1:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f01036c7:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01036c9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01036ce:	76 10                	jbe    f01036e0 <env_free+0x89>
	return (physaddr_t)kva - KERNBASE;
f01036d0:	05 00 00 00 10       	add    $0x10000000,%eax
f01036d5:	0f 22 d8             	mov    %eax,%cr3
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01036d8:	8b 45 08             	mov    0x8(%ebp),%eax
f01036db:	8b 48 48             	mov    0x48(%eax),%ecx
f01036de:	eb a9                	jmp    f0103689 <env_free+0x32>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01036e0:	50                   	push   %eax
f01036e1:	8d 83 94 8b f7 ff    	lea    -0x8746c(%ebx),%eax
f01036e7:	50                   	push   %eax
f01036e8:	68 cc 01 00 00       	push   $0x1cc
f01036ed:	8d 83 1e 96 f7 ff    	lea    -0x869e2(%ebx),%eax
f01036f3:	50                   	push   %eax
f01036f4:	e8 bc c9 ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01036f9:	57                   	push   %edi
f01036fa:	8d 83 e4 89 f7 ff    	lea    -0x8761c(%ebx),%eax
f0103700:	50                   	push   %eax
f0103701:	68 db 01 00 00       	push   $0x1db
f0103706:	8d 83 1e 96 f7 ff    	lea    -0x869e2(%ebx),%eax
f010370c:	50                   	push   %eax
f010370d:	e8 a3 c9 ff ff       	call   f01000b5 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103712:	83 ec 08             	sub    $0x8,%esp
f0103715:	89 f0                	mov    %esi,%eax
f0103717:	c1 e0 0c             	shl    $0xc,%eax
f010371a:	0b 45 e4             	or     -0x1c(%ebp),%eax
f010371d:	50                   	push   %eax
f010371e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103721:	ff 70 5c             	pushl  0x5c(%eax)
f0103724:	e8 ad db ff ff       	call   f01012d6 <page_remove>
f0103729:	83 c4 10             	add    $0x10,%esp
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010372c:	83 c6 01             	add    $0x1,%esi
f010372f:	83 c7 04             	add    $0x4,%edi
f0103732:	81 fe 00 04 00 00    	cmp    $0x400,%esi
f0103738:	74 07                	je     f0103741 <env_free+0xea>
			if (pt[pteno] & PTE_P)
f010373a:	f6 07 01             	testb  $0x1,(%edi)
f010373d:	74 ed                	je     f010372c <env_free+0xd5>
f010373f:	eb d1                	jmp    f0103712 <env_free+0xbb>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103741:	8b 45 08             	mov    0x8(%ebp),%eax
f0103744:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103747:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010374a:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f0103751:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103754:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103757:	3b 10                	cmp    (%eax),%edx
f0103759:	73 67                	jae    f01037c2 <env_free+0x16b>
		page_decref(pa2page(pa));
f010375b:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f010375e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103761:	8b 00                	mov    (%eax),%eax
f0103763:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103766:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0103769:	50                   	push   %eax
f010376a:	e8 c4 d9 ff ff       	call   f0101133 <page_decref>
f010376f:	83 c4 10             	add    $0x10,%esp
f0103772:	83 45 e0 04          	addl   $0x4,-0x20(%ebp)
f0103776:	8b 45 e0             	mov    -0x20(%ebp),%eax
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103779:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f010377e:	74 5a                	je     f01037da <env_free+0x183>
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103780:	8b 45 08             	mov    0x8(%ebp),%eax
f0103783:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103786:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103789:	8b 04 10             	mov    (%eax,%edx,1),%eax
f010378c:	a8 01                	test   $0x1,%al
f010378e:	74 e2                	je     f0103772 <env_free+0x11b>
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103790:	89 c7                	mov    %eax,%edi
f0103792:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	if (PGNUM(pa) >= npages)
f0103798:	c1 e8 0c             	shr    $0xc,%eax
f010379b:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010379e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01037a1:	39 02                	cmp    %eax,(%edx)
f01037a3:	0f 86 50 ff ff ff    	jbe    f01036f9 <env_free+0xa2>
	return (void *)(pa + KERNBASE);
f01037a9:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
f01037af:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01037b2:	c1 e0 14             	shl    $0x14,%eax
f01037b5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01037b8:	be 00 00 00 00       	mov    $0x0,%esi
f01037bd:	e9 78 ff ff ff       	jmp    f010373a <env_free+0xe3>
		panic("pa2page called with invalid pa");
f01037c2:	83 ec 04             	sub    $0x4,%esp
f01037c5:	8d 83 38 8b f7 ff    	lea    -0x874c8(%ebx),%eax
f01037cb:	50                   	push   %eax
f01037cc:	6a 4f                	push   $0x4f
f01037ce:	8d 83 19 92 f7 ff    	lea    -0x86de7(%ebx),%eax
f01037d4:	50                   	push   %eax
f01037d5:	e8 db c8 ff ff       	call   f01000b5 <_panic>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01037da:	8b 45 08             	mov    0x8(%ebp),%eax
f01037dd:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01037e0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01037e5:	76 57                	jbe    f010383e <env_free+0x1e7>
	e->env_pgdir = 0;
f01037e7:	8b 55 08             	mov    0x8(%ebp),%edx
f01037ea:	c7 42 5c 00 00 00 00 	movl   $0x0,0x5c(%edx)
	return (physaddr_t)kva - KERNBASE;
f01037f1:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f01037f6:	c1 e8 0c             	shr    $0xc,%eax
f01037f9:	c7 c2 08 00 19 f0    	mov    $0xf0190008,%edx
f01037ff:	3b 02                	cmp    (%edx),%eax
f0103801:	73 54                	jae    f0103857 <env_free+0x200>
	page_decref(pa2page(pa));
f0103803:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103806:	c7 c2 10 00 19 f0    	mov    $0xf0190010,%edx
f010380c:	8b 12                	mov    (%edx),%edx
f010380e:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103811:	50                   	push   %eax
f0103812:	e8 1c d9 ff ff       	call   f0101133 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103817:	8b 45 08             	mov    0x8(%ebp),%eax
f010381a:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	e->env_link = env_free_list;
f0103821:	8b 83 34 23 00 00    	mov    0x2334(%ebx),%eax
f0103827:	8b 55 08             	mov    0x8(%ebp),%edx
f010382a:	89 42 44             	mov    %eax,0x44(%edx)
	env_free_list = e;
f010382d:	89 93 34 23 00 00    	mov    %edx,0x2334(%ebx)
}
f0103833:	83 c4 10             	add    $0x10,%esp
f0103836:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103839:	5b                   	pop    %ebx
f010383a:	5e                   	pop    %esi
f010383b:	5f                   	pop    %edi
f010383c:	5d                   	pop    %ebp
f010383d:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010383e:	50                   	push   %eax
f010383f:	8d 83 94 8b f7 ff    	lea    -0x8746c(%ebx),%eax
f0103845:	50                   	push   %eax
f0103846:	68 e9 01 00 00       	push   $0x1e9
f010384b:	8d 83 1e 96 f7 ff    	lea    -0x869e2(%ebx),%eax
f0103851:	50                   	push   %eax
f0103852:	e8 5e c8 ff ff       	call   f01000b5 <_panic>
		panic("pa2page called with invalid pa");
f0103857:	83 ec 04             	sub    $0x4,%esp
f010385a:	8d 83 38 8b f7 ff    	lea    -0x874c8(%ebx),%eax
f0103860:	50                   	push   %eax
f0103861:	6a 4f                	push   $0x4f
f0103863:	8d 83 19 92 f7 ff    	lea    -0x86de7(%ebx),%eax
f0103869:	50                   	push   %eax
f010386a:	e8 46 c8 ff ff       	call   f01000b5 <_panic>

f010386f <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f010386f:	f3 0f 1e fb          	endbr32 
f0103873:	55                   	push   %ebp
f0103874:	89 e5                	mov    %esp,%ebp
f0103876:	53                   	push   %ebx
f0103877:	83 ec 10             	sub    $0x10,%esp
f010387a:	e8 f4 c8 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f010387f:	81 c3 9d 97 08 00    	add    $0x8979d,%ebx
	env_free(e);
f0103885:	ff 75 08             	pushl  0x8(%ebp)
f0103888:	e8 ca fd ff ff       	call   f0103657 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f010388d:	8d 83 e8 95 f7 ff    	lea    -0x86a18(%ebx),%eax
f0103893:	89 04 24             	mov    %eax,(%esp)
f0103896:	e8 5a 01 00 00       	call   f01039f5 <cprintf>
f010389b:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f010389e:	83 ec 0c             	sub    $0xc,%esp
f01038a1:	6a 00                	push   $0x0
f01038a3:	e8 99 d0 ff ff       	call   f0100941 <monitor>
f01038a8:	83 c4 10             	add    $0x10,%esp
f01038ab:	eb f1                	jmp    f010389e <env_destroy+0x2f>

f01038ad <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01038ad:	f3 0f 1e fb          	endbr32 
f01038b1:	55                   	push   %ebp
f01038b2:	89 e5                	mov    %esp,%ebp
f01038b4:	53                   	push   %ebx
f01038b5:	83 ec 08             	sub    $0x8,%esp
f01038b8:	e8 b6 c8 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01038bd:	81 c3 5f 97 08 00    	add    $0x8975f,%ebx
	asm volatile(
f01038c3:	8b 65 08             	mov    0x8(%ebp),%esp
f01038c6:	61                   	popa   
f01038c7:	07                   	pop    %es
f01038c8:	1f                   	pop    %ds
f01038c9:	83 c4 08             	add    $0x8,%esp
f01038cc:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01038cd:	8d 83 54 96 f7 ff    	lea    -0x869ac(%ebx),%eax
f01038d3:	50                   	push   %eax
f01038d4:	68 12 02 00 00       	push   $0x212
f01038d9:	8d 83 1e 96 f7 ff    	lea    -0x869e2(%ebx),%eax
f01038df:	50                   	push   %eax
f01038e0:	e8 d0 c7 ff ff       	call   f01000b5 <_panic>

f01038e5 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f01038e5:	f3 0f 1e fb          	endbr32 
f01038e9:	55                   	push   %ebp
f01038ea:	89 e5                	mov    %esp,%ebp
f01038ec:	53                   	push   %ebx
f01038ed:	83 ec 04             	sub    $0x4,%esp
f01038f0:	e8 7e c8 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01038f5:	81 c3 27 97 08 00    	add    $0x89727,%ebx
f01038fb:	8b 45 08             	mov    0x8(%ebp),%eax
	
	// panic("env_run not yet implemented");

	// step 1
	// set the env_status field
	if(curenv)
f01038fe:	8b 93 2c 23 00 00    	mov    0x232c(%ebx),%edx
f0103904:	85 d2                	test   %edx,%edx
f0103906:	74 06                	je     f010390e <env_run+0x29>
	{
		if(curenv->env_status == ENV_RUNNING)
f0103908:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f010390c:	74 2e                	je     f010393c <env_run+0x57>
			curenv->env_status = ENV_RUNNABLE;
		}
	}

	// switch to new environment
	curenv = e;
f010390e:	89 83 2c 23 00 00    	mov    %eax,0x232c(%ebx)
	curenv->env_status = ENV_RUNNING;
f0103914:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f010391b:	83 40 58 01          	addl   $0x1,0x58(%eax)
	// switch to user page directory
	lcr3(PADDR(curenv->env_pgdir));
f010391f:	8b 50 5c             	mov    0x5c(%eax),%edx
	if ((uint32_t)kva < KERNBASE)
f0103922:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103928:	76 1b                	jbe    f0103945 <env_run+0x60>
	return (physaddr_t)kva - KERNBASE;
f010392a:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103930:	0f 22 da             	mov    %edx,%cr3

	// step 2
	env_pop_tf(&curenv->env_tf);
f0103933:	83 ec 0c             	sub    $0xc,%esp
f0103936:	50                   	push   %eax
f0103937:	e8 71 ff ff ff       	call   f01038ad <env_pop_tf>
			curenv->env_status = ENV_RUNNABLE;
f010393c:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
f0103943:	eb c9                	jmp    f010390e <env_run+0x29>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103945:	52                   	push   %edx
f0103946:	8d 83 94 8b f7 ff    	lea    -0x8746c(%ebx),%eax
f010394c:	50                   	push   %eax
f010394d:	68 42 02 00 00       	push   $0x242
f0103952:	8d 83 1e 96 f7 ff    	lea    -0x869e2(%ebx),%eax
f0103958:	50                   	push   %eax
f0103959:	e8 57 c7 ff ff       	call   f01000b5 <_panic>

f010395e <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010395e:	f3 0f 1e fb          	endbr32 
f0103962:	55                   	push   %ebp
f0103963:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103965:	8b 45 08             	mov    0x8(%ebp),%eax
f0103968:	ba 70 00 00 00       	mov    $0x70,%edx
f010396d:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010396e:	ba 71 00 00 00       	mov    $0x71,%edx
f0103973:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103974:	0f b6 c0             	movzbl %al,%eax
}
f0103977:	5d                   	pop    %ebp
f0103978:	c3                   	ret    

f0103979 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103979:	f3 0f 1e fb          	endbr32 
f010397d:	55                   	push   %ebp
f010397e:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103980:	8b 45 08             	mov    0x8(%ebp),%eax
f0103983:	ba 70 00 00 00       	mov    $0x70,%edx
f0103988:	ee                   	out    %al,(%dx)
f0103989:	8b 45 0c             	mov    0xc(%ebp),%eax
f010398c:	ba 71 00 00 00       	mov    $0x71,%edx
f0103991:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103992:	5d                   	pop    %ebp
f0103993:	c3                   	ret    

f0103994 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103994:	f3 0f 1e fb          	endbr32 
f0103998:	55                   	push   %ebp
f0103999:	89 e5                	mov    %esp,%ebp
f010399b:	53                   	push   %ebx
f010399c:	83 ec 10             	sub    $0x10,%esp
f010399f:	e8 cf c7 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01039a4:	81 c3 78 96 08 00    	add    $0x89678,%ebx
	cputchar(ch);
f01039aa:	ff 75 08             	pushl  0x8(%ebp)
f01039ad:	e8 42 cd ff ff       	call   f01006f4 <cputchar>
	*cnt++;
}
f01039b2:	83 c4 10             	add    $0x10,%esp
f01039b5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01039b8:	c9                   	leave  
f01039b9:	c3                   	ret    

f01039ba <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01039ba:	f3 0f 1e fb          	endbr32 
f01039be:	55                   	push   %ebp
f01039bf:	89 e5                	mov    %esp,%ebp
f01039c1:	53                   	push   %ebx
f01039c2:	83 ec 14             	sub    $0x14,%esp
f01039c5:	e8 a9 c7 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01039ca:	81 c3 52 96 08 00    	add    $0x89652,%ebx
	int cnt = 0;
f01039d0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01039d7:	ff 75 0c             	pushl  0xc(%ebp)
f01039da:	ff 75 08             	pushl  0x8(%ebp)
f01039dd:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01039e0:	50                   	push   %eax
f01039e1:	8d 83 78 69 f7 ff    	lea    -0x89688(%ebx),%eax
f01039e7:	50                   	push   %eax
f01039e8:	e8 c6 0e 00 00       	call   f01048b3 <vprintfmt>
	return cnt;
}
f01039ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01039f0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01039f3:	c9                   	leave  
f01039f4:	c3                   	ret    

f01039f5 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01039f5:	f3 0f 1e fb          	endbr32 
f01039f9:	55                   	push   %ebp
f01039fa:	89 e5                	mov    %esp,%ebp
f01039fc:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01039ff:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103a02:	50                   	push   %eax
f0103a03:	ff 75 08             	pushl  0x8(%ebp)
f0103a06:	e8 af ff ff ff       	call   f01039ba <vcprintf>
	va_end(ap);

	return cnt;
}
f0103a0b:	c9                   	leave  
f0103a0c:	c3                   	ret    

f0103a0d <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103a0d:	f3 0f 1e fb          	endbr32 
f0103a11:	55                   	push   %ebp
f0103a12:	89 e5                	mov    %esp,%ebp
f0103a14:	57                   	push   %edi
f0103a15:	56                   	push   %esi
f0103a16:	53                   	push   %ebx
f0103a17:	83 ec 04             	sub    $0x4,%esp
f0103a1a:	e8 54 c7 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103a1f:	81 c3 fd 95 08 00    	add    $0x895fd,%ebx
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103a25:	c7 83 68 2b 00 00 00 	movl   $0xf0000000,0x2b68(%ebx)
f0103a2c:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0103a2f:	66 c7 83 6c 2b 00 00 	movw   $0x10,0x2b6c(%ebx)
f0103a36:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f0103a38:	66 c7 83 ca 2b 00 00 	movw   $0x68,0x2bca(%ebx)
f0103a3f:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103a41:	c7 c0 00 c3 11 f0    	mov    $0xf011c300,%eax
f0103a47:	66 c7 40 28 67 00    	movw   $0x67,0x28(%eax)
f0103a4d:	8d b3 64 2b 00 00    	lea    0x2b64(%ebx),%esi
f0103a53:	66 89 70 2a          	mov    %si,0x2a(%eax)
f0103a57:	89 f2                	mov    %esi,%edx
f0103a59:	c1 ea 10             	shr    $0x10,%edx
f0103a5c:	88 50 2c             	mov    %dl,0x2c(%eax)
f0103a5f:	0f b6 50 2d          	movzbl 0x2d(%eax),%edx
f0103a63:	83 e2 f0             	and    $0xfffffff0,%edx
f0103a66:	83 ca 09             	or     $0x9,%edx
f0103a69:	83 e2 9f             	and    $0xffffff9f,%edx
f0103a6c:	83 ca 80             	or     $0xffffff80,%edx
f0103a6f:	88 55 f3             	mov    %dl,-0xd(%ebp)
f0103a72:	88 50 2d             	mov    %dl,0x2d(%eax)
f0103a75:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
f0103a79:	83 e1 c0             	and    $0xffffffc0,%ecx
f0103a7c:	83 c9 40             	or     $0x40,%ecx
f0103a7f:	83 e1 7f             	and    $0x7f,%ecx
f0103a82:	88 48 2e             	mov    %cl,0x2e(%eax)
f0103a85:	c1 ee 18             	shr    $0x18,%esi
f0103a88:	89 f1                	mov    %esi,%ecx
f0103a8a:	88 48 2f             	mov    %cl,0x2f(%eax)
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103a8d:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
f0103a91:	83 e2 ef             	and    $0xffffffef,%edx
f0103a94:	88 50 2d             	mov    %dl,0x2d(%eax)
	asm volatile("ltr %0" : : "r" (sel));
f0103a97:	b8 28 00 00 00       	mov    $0x28,%eax
f0103a9c:	0f 00 d8             	ltr    %ax
	asm volatile("lidt (%0)" : : "r" (p));
f0103a9f:	8d 83 ec 1f 00 00    	lea    0x1fec(%ebx),%eax
f0103aa5:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0103aa8:	83 c4 04             	add    $0x4,%esp
f0103aab:	5b                   	pop    %ebx
f0103aac:	5e                   	pop    %esi
f0103aad:	5f                   	pop    %edi
f0103aae:	5d                   	pop    %ebp
f0103aaf:	c3                   	ret    

f0103ab0 <trap_init>:
{
f0103ab0:	f3 0f 1e fb          	endbr32 
f0103ab4:	55                   	push   %ebp
f0103ab5:	89 e5                	mov    %esp,%ebp
f0103ab7:	e8 6b cc ff ff       	call   f0100727 <__x86.get_pc_thunk.ax>
f0103abc:	05 60 95 08 00       	add    $0x89560,%eax
    SETGATE(idt[T_DIVIDE], 0, GD_KT, DIVIDE, 0);
f0103ac1:	c7 c2 d4 42 10 f0    	mov    $0xf01042d4,%edx
f0103ac7:	66 89 90 44 23 00 00 	mov    %dx,0x2344(%eax)
f0103ace:	66 c7 80 46 23 00 00 	movw   $0x8,0x2346(%eax)
f0103ad5:	08 00 
f0103ad7:	c6 80 48 23 00 00 00 	movb   $0x0,0x2348(%eax)
f0103ade:	c6 80 49 23 00 00 8e 	movb   $0x8e,0x2349(%eax)
f0103ae5:	c1 ea 10             	shr    $0x10,%edx
f0103ae8:	66 89 90 4a 23 00 00 	mov    %dx,0x234a(%eax)
	SETGATE(idt[T_DEBUG], 0, GD_KT, DEBUG, 0);
f0103aef:	c7 c2 da 42 10 f0    	mov    $0xf01042da,%edx
f0103af5:	66 89 90 4c 23 00 00 	mov    %dx,0x234c(%eax)
f0103afc:	66 c7 80 4e 23 00 00 	movw   $0x8,0x234e(%eax)
f0103b03:	08 00 
f0103b05:	c6 80 50 23 00 00 00 	movb   $0x0,0x2350(%eax)
f0103b0c:	c6 80 51 23 00 00 8e 	movb   $0x8e,0x2351(%eax)
f0103b13:	c1 ea 10             	shr    $0x10,%edx
f0103b16:	66 89 90 52 23 00 00 	mov    %dx,0x2352(%eax)
	SETGATE(idt[T_NMI], 0, GD_KT, NMI, 0);
f0103b1d:	c7 c2 e0 42 10 f0    	mov    $0xf01042e0,%edx
f0103b23:	66 89 90 54 23 00 00 	mov    %dx,0x2354(%eax)
f0103b2a:	66 c7 80 56 23 00 00 	movw   $0x8,0x2356(%eax)
f0103b31:	08 00 
f0103b33:	c6 80 58 23 00 00 00 	movb   $0x0,0x2358(%eax)
f0103b3a:	c6 80 59 23 00 00 8e 	movb   $0x8e,0x2359(%eax)
f0103b41:	c1 ea 10             	shr    $0x10,%edx
f0103b44:	66 89 90 5a 23 00 00 	mov    %dx,0x235a(%eax)
	SETGATE(idt[T_BRKPT], 1, GD_KT, BRKPT, 3);
f0103b4b:	c7 c2 e6 42 10 f0    	mov    $0xf01042e6,%edx
f0103b51:	66 89 90 5c 23 00 00 	mov    %dx,0x235c(%eax)
f0103b58:	66 c7 80 5e 23 00 00 	movw   $0x8,0x235e(%eax)
f0103b5f:	08 00 
f0103b61:	c6 80 60 23 00 00 00 	movb   $0x0,0x2360(%eax)
f0103b68:	c6 80 61 23 00 00 ef 	movb   $0xef,0x2361(%eax)
f0103b6f:	c1 ea 10             	shr    $0x10,%edx
f0103b72:	66 89 90 62 23 00 00 	mov    %dx,0x2362(%eax)
	SETGATE(idt[T_OFLOW], 0, GD_KT, OFLOW, 0);
f0103b79:	c7 c2 ec 42 10 f0    	mov    $0xf01042ec,%edx
f0103b7f:	66 89 90 64 23 00 00 	mov    %dx,0x2364(%eax)
f0103b86:	66 c7 80 66 23 00 00 	movw   $0x8,0x2366(%eax)
f0103b8d:	08 00 
f0103b8f:	c6 80 68 23 00 00 00 	movb   $0x0,0x2368(%eax)
f0103b96:	c6 80 69 23 00 00 8e 	movb   $0x8e,0x2369(%eax)
f0103b9d:	c1 ea 10             	shr    $0x10,%edx
f0103ba0:	66 89 90 6a 23 00 00 	mov    %dx,0x236a(%eax)
	SETGATE(idt[T_BOUND], 0, GD_KT, BOUND, 0);
f0103ba7:	c7 c2 f2 42 10 f0    	mov    $0xf01042f2,%edx
f0103bad:	66 89 90 6c 23 00 00 	mov    %dx,0x236c(%eax)
f0103bb4:	66 c7 80 6e 23 00 00 	movw   $0x8,0x236e(%eax)
f0103bbb:	08 00 
f0103bbd:	c6 80 70 23 00 00 00 	movb   $0x0,0x2370(%eax)
f0103bc4:	c6 80 71 23 00 00 8e 	movb   $0x8e,0x2371(%eax)
f0103bcb:	c1 ea 10             	shr    $0x10,%edx
f0103bce:	66 89 90 72 23 00 00 	mov    %dx,0x2372(%eax)
	SETGATE(idt[T_ILLOP], 0, GD_KT, ILLOP, 0);
f0103bd5:	c7 c2 f8 42 10 f0    	mov    $0xf01042f8,%edx
f0103bdb:	66 89 90 74 23 00 00 	mov    %dx,0x2374(%eax)
f0103be2:	66 c7 80 76 23 00 00 	movw   $0x8,0x2376(%eax)
f0103be9:	08 00 
f0103beb:	c6 80 78 23 00 00 00 	movb   $0x0,0x2378(%eax)
f0103bf2:	c6 80 79 23 00 00 8e 	movb   $0x8e,0x2379(%eax)
f0103bf9:	c1 ea 10             	shr    $0x10,%edx
f0103bfc:	66 89 90 7a 23 00 00 	mov    %dx,0x237a(%eax)
	SETGATE(idt[T_DEVICE], 0, GD_KT, DEVICE, 0);
f0103c03:	c7 c2 fe 42 10 f0    	mov    $0xf01042fe,%edx
f0103c09:	66 89 90 7c 23 00 00 	mov    %dx,0x237c(%eax)
f0103c10:	66 c7 80 7e 23 00 00 	movw   $0x8,0x237e(%eax)
f0103c17:	08 00 
f0103c19:	c6 80 80 23 00 00 00 	movb   $0x0,0x2380(%eax)
f0103c20:	c6 80 81 23 00 00 8e 	movb   $0x8e,0x2381(%eax)
f0103c27:	c1 ea 10             	shr    $0x10,%edx
f0103c2a:	66 89 90 82 23 00 00 	mov    %dx,0x2382(%eax)
	SETGATE(idt[T_DBLFLT], 0, GD_KT, DBLFLT, 0);
f0103c31:	c7 c2 04 43 10 f0    	mov    $0xf0104304,%edx
f0103c37:	66 89 90 84 23 00 00 	mov    %dx,0x2384(%eax)
f0103c3e:	66 c7 80 86 23 00 00 	movw   $0x8,0x2386(%eax)
f0103c45:	08 00 
f0103c47:	c6 80 88 23 00 00 00 	movb   $0x0,0x2388(%eax)
f0103c4e:	c6 80 89 23 00 00 8e 	movb   $0x8e,0x2389(%eax)
f0103c55:	c1 ea 10             	shr    $0x10,%edx
f0103c58:	66 89 90 8a 23 00 00 	mov    %dx,0x238a(%eax)
	SETGATE(idt[T_TSS], 0, GD_KT, TSS, 0);
f0103c5f:	c7 c2 08 43 10 f0    	mov    $0xf0104308,%edx
f0103c65:	66 89 90 94 23 00 00 	mov    %dx,0x2394(%eax)
f0103c6c:	66 c7 80 96 23 00 00 	movw   $0x8,0x2396(%eax)
f0103c73:	08 00 
f0103c75:	c6 80 98 23 00 00 00 	movb   $0x0,0x2398(%eax)
f0103c7c:	c6 80 99 23 00 00 8e 	movb   $0x8e,0x2399(%eax)
f0103c83:	c1 ea 10             	shr    $0x10,%edx
f0103c86:	66 89 90 9a 23 00 00 	mov    %dx,0x239a(%eax)
	SETGATE(idt[T_SEGNP], 0, GD_KT, SEGNP, 0);
f0103c8d:	c7 c2 0c 43 10 f0    	mov    $0xf010430c,%edx
f0103c93:	66 89 90 9c 23 00 00 	mov    %dx,0x239c(%eax)
f0103c9a:	66 c7 80 9e 23 00 00 	movw   $0x8,0x239e(%eax)
f0103ca1:	08 00 
f0103ca3:	c6 80 a0 23 00 00 00 	movb   $0x0,0x23a0(%eax)
f0103caa:	c6 80 a1 23 00 00 8e 	movb   $0x8e,0x23a1(%eax)
f0103cb1:	c1 ea 10             	shr    $0x10,%edx
f0103cb4:	66 89 90 a2 23 00 00 	mov    %dx,0x23a2(%eax)
	SETGATE(idt[T_STACK], 0, GD_KT, STACK, 0);
f0103cbb:	c7 c2 10 43 10 f0    	mov    $0xf0104310,%edx
f0103cc1:	66 89 90 a4 23 00 00 	mov    %dx,0x23a4(%eax)
f0103cc8:	66 c7 80 a6 23 00 00 	movw   $0x8,0x23a6(%eax)
f0103ccf:	08 00 
f0103cd1:	c6 80 a8 23 00 00 00 	movb   $0x0,0x23a8(%eax)
f0103cd8:	c6 80 a9 23 00 00 8e 	movb   $0x8e,0x23a9(%eax)
f0103cdf:	c1 ea 10             	shr    $0x10,%edx
f0103ce2:	66 89 90 aa 23 00 00 	mov    %dx,0x23aa(%eax)
	SETGATE(idt[T_GPFLT], 0, GD_KT, GPFLT, 0);
f0103ce9:	c7 c2 14 43 10 f0    	mov    $0xf0104314,%edx
f0103cef:	66 89 90 ac 23 00 00 	mov    %dx,0x23ac(%eax)
f0103cf6:	66 c7 80 ae 23 00 00 	movw   $0x8,0x23ae(%eax)
f0103cfd:	08 00 
f0103cff:	c6 80 b0 23 00 00 00 	movb   $0x0,0x23b0(%eax)
f0103d06:	c6 80 b1 23 00 00 8e 	movb   $0x8e,0x23b1(%eax)
f0103d0d:	c1 ea 10             	shr    $0x10,%edx
f0103d10:	66 89 90 b2 23 00 00 	mov    %dx,0x23b2(%eax)
	SETGATE(idt[T_PGFLT], 0, GD_KT, PGFLT, 0);
f0103d17:	c7 c2 18 43 10 f0    	mov    $0xf0104318,%edx
f0103d1d:	66 89 90 b4 23 00 00 	mov    %dx,0x23b4(%eax)
f0103d24:	66 c7 80 b6 23 00 00 	movw   $0x8,0x23b6(%eax)
f0103d2b:	08 00 
f0103d2d:	c6 80 b8 23 00 00 00 	movb   $0x0,0x23b8(%eax)
f0103d34:	c6 80 b9 23 00 00 8e 	movb   $0x8e,0x23b9(%eax)
f0103d3b:	c1 ea 10             	shr    $0x10,%edx
f0103d3e:	66 89 90 ba 23 00 00 	mov    %dx,0x23ba(%eax)
	SETGATE(idt[T_FPERR], 0, GD_KT, FPERR, 0);
f0103d45:	c7 c2 1c 43 10 f0    	mov    $0xf010431c,%edx
f0103d4b:	66 89 90 c4 23 00 00 	mov    %dx,0x23c4(%eax)
f0103d52:	66 c7 80 c6 23 00 00 	movw   $0x8,0x23c6(%eax)
f0103d59:	08 00 
f0103d5b:	c6 80 c8 23 00 00 00 	movb   $0x0,0x23c8(%eax)
f0103d62:	c6 80 c9 23 00 00 8e 	movb   $0x8e,0x23c9(%eax)
f0103d69:	c1 ea 10             	shr    $0x10,%edx
f0103d6c:	66 89 90 ca 23 00 00 	mov    %dx,0x23ca(%eax)
	SETGATE(idt[T_ALIGN], 0, GD_KT, ALIGN, 0);
f0103d73:	c7 c2 22 43 10 f0    	mov    $0xf0104322,%edx
f0103d79:	66 89 90 cc 23 00 00 	mov    %dx,0x23cc(%eax)
f0103d80:	66 c7 80 ce 23 00 00 	movw   $0x8,0x23ce(%eax)
f0103d87:	08 00 
f0103d89:	c6 80 d0 23 00 00 00 	movb   $0x0,0x23d0(%eax)
f0103d90:	c6 80 d1 23 00 00 8e 	movb   $0x8e,0x23d1(%eax)
f0103d97:	c1 ea 10             	shr    $0x10,%edx
f0103d9a:	66 89 90 d2 23 00 00 	mov    %dx,0x23d2(%eax)
	SETGATE(idt[T_MCHK], 0, GD_KT, MCHK, 0);
f0103da1:	c7 c2 26 43 10 f0    	mov    $0xf0104326,%edx
f0103da7:	66 89 90 d4 23 00 00 	mov    %dx,0x23d4(%eax)
f0103dae:	66 c7 80 d6 23 00 00 	movw   $0x8,0x23d6(%eax)
f0103db5:	08 00 
f0103db7:	c6 80 d8 23 00 00 00 	movb   $0x0,0x23d8(%eax)
f0103dbe:	c6 80 d9 23 00 00 8e 	movb   $0x8e,0x23d9(%eax)
f0103dc5:	c1 ea 10             	shr    $0x10,%edx
f0103dc8:	66 89 90 da 23 00 00 	mov    %dx,0x23da(%eax)
	SETGATE(idt[T_SIMDERR], 0, GD_KT, SIMDERR, 0);
f0103dcf:	c7 c2 2c 43 10 f0    	mov    $0xf010432c,%edx
f0103dd5:	66 89 90 dc 23 00 00 	mov    %dx,0x23dc(%eax)
f0103ddc:	66 c7 80 de 23 00 00 	movw   $0x8,0x23de(%eax)
f0103de3:	08 00 
f0103de5:	c6 80 e0 23 00 00 00 	movb   $0x0,0x23e0(%eax)
f0103dec:	c6 80 e1 23 00 00 8e 	movb   $0x8e,0x23e1(%eax)
f0103df3:	c1 ea 10             	shr    $0x10,%edx
f0103df6:	66 89 90 e2 23 00 00 	mov    %dx,0x23e2(%eax)
	SETGATE(idt[T_SYSCALL], 1, GD_KT, SYSCALL, 3);
f0103dfd:	c7 c2 32 43 10 f0    	mov    $0xf0104332,%edx
f0103e03:	66 89 90 c4 24 00 00 	mov    %dx,0x24c4(%eax)
f0103e0a:	66 c7 80 c6 24 00 00 	movw   $0x8,0x24c6(%eax)
f0103e11:	08 00 
f0103e13:	c6 80 c8 24 00 00 00 	movb   $0x0,0x24c8(%eax)
f0103e1a:	c6 80 c9 24 00 00 ef 	movb   $0xef,0x24c9(%eax)
f0103e21:	c1 ea 10             	shr    $0x10,%edx
f0103e24:	66 89 90 ca 24 00 00 	mov    %dx,0x24ca(%eax)
	SETGATE(idt[T_DEFAULT], 0, GD_KT, DEFAULT, 0);
f0103e2b:	c7 c2 38 43 10 f0    	mov    $0xf0104338,%edx
f0103e31:	66 89 90 e4 32 00 00 	mov    %dx,0x32e4(%eax)
f0103e38:	66 c7 80 e6 32 00 00 	movw   $0x8,0x32e6(%eax)
f0103e3f:	08 00 
f0103e41:	c6 80 e8 32 00 00 00 	movb   $0x0,0x32e8(%eax)
f0103e48:	c6 80 e9 32 00 00 8e 	movb   $0x8e,0x32e9(%eax)
f0103e4f:	c1 ea 10             	shr    $0x10,%edx
f0103e52:	66 89 90 ea 32 00 00 	mov    %dx,0x32ea(%eax)
	trap_init_percpu();
f0103e59:	e8 af fb ff ff       	call   f0103a0d <trap_init_percpu>
}
f0103e5e:	5d                   	pop    %ebp
f0103e5f:	c3                   	ret    

f0103e60 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103e60:	f3 0f 1e fb          	endbr32 
f0103e64:	55                   	push   %ebp
f0103e65:	89 e5                	mov    %esp,%ebp
f0103e67:	56                   	push   %esi
f0103e68:	53                   	push   %ebx
f0103e69:	e8 05 c3 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103e6e:	81 c3 ae 91 08 00    	add    $0x891ae,%ebx
f0103e74:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103e77:	83 ec 08             	sub    $0x8,%esp
f0103e7a:	ff 36                	pushl  (%esi)
f0103e7c:	8d 83 60 96 f7 ff    	lea    -0x869a0(%ebx),%eax
f0103e82:	50                   	push   %eax
f0103e83:	e8 6d fb ff ff       	call   f01039f5 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103e88:	83 c4 08             	add    $0x8,%esp
f0103e8b:	ff 76 04             	pushl  0x4(%esi)
f0103e8e:	8d 83 6f 96 f7 ff    	lea    -0x86991(%ebx),%eax
f0103e94:	50                   	push   %eax
f0103e95:	e8 5b fb ff ff       	call   f01039f5 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103e9a:	83 c4 08             	add    $0x8,%esp
f0103e9d:	ff 76 08             	pushl  0x8(%esi)
f0103ea0:	8d 83 7e 96 f7 ff    	lea    -0x86982(%ebx),%eax
f0103ea6:	50                   	push   %eax
f0103ea7:	e8 49 fb ff ff       	call   f01039f5 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103eac:	83 c4 08             	add    $0x8,%esp
f0103eaf:	ff 76 0c             	pushl  0xc(%esi)
f0103eb2:	8d 83 8d 96 f7 ff    	lea    -0x86973(%ebx),%eax
f0103eb8:	50                   	push   %eax
f0103eb9:	e8 37 fb ff ff       	call   f01039f5 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103ebe:	83 c4 08             	add    $0x8,%esp
f0103ec1:	ff 76 10             	pushl  0x10(%esi)
f0103ec4:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0103eca:	50                   	push   %eax
f0103ecb:	e8 25 fb ff ff       	call   f01039f5 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103ed0:	83 c4 08             	add    $0x8,%esp
f0103ed3:	ff 76 14             	pushl  0x14(%esi)
f0103ed6:	8d 83 ab 96 f7 ff    	lea    -0x86955(%ebx),%eax
f0103edc:	50                   	push   %eax
f0103edd:	e8 13 fb ff ff       	call   f01039f5 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103ee2:	83 c4 08             	add    $0x8,%esp
f0103ee5:	ff 76 18             	pushl  0x18(%esi)
f0103ee8:	8d 83 ba 96 f7 ff    	lea    -0x86946(%ebx),%eax
f0103eee:	50                   	push   %eax
f0103eef:	e8 01 fb ff ff       	call   f01039f5 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103ef4:	83 c4 08             	add    $0x8,%esp
f0103ef7:	ff 76 1c             	pushl  0x1c(%esi)
f0103efa:	8d 83 c9 96 f7 ff    	lea    -0x86937(%ebx),%eax
f0103f00:	50                   	push   %eax
f0103f01:	e8 ef fa ff ff       	call   f01039f5 <cprintf>
}
f0103f06:	83 c4 10             	add    $0x10,%esp
f0103f09:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103f0c:	5b                   	pop    %ebx
f0103f0d:	5e                   	pop    %esi
f0103f0e:	5d                   	pop    %ebp
f0103f0f:	c3                   	ret    

f0103f10 <print_trapframe>:
{
f0103f10:	f3 0f 1e fb          	endbr32 
f0103f14:	55                   	push   %ebp
f0103f15:	89 e5                	mov    %esp,%ebp
f0103f17:	57                   	push   %edi
f0103f18:	56                   	push   %esi
f0103f19:	53                   	push   %ebx
f0103f1a:	83 ec 14             	sub    $0x14,%esp
f0103f1d:	e8 51 c2 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103f22:	81 c3 fa 90 08 00    	add    $0x890fa,%ebx
f0103f28:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("TRAP frame at %p\n", tf);
f0103f2b:	56                   	push   %esi
f0103f2c:	8d 83 ff 97 f7 ff    	lea    -0x86801(%ebx),%eax
f0103f32:	50                   	push   %eax
f0103f33:	e8 bd fa ff ff       	call   f01039f5 <cprintf>
	print_regs(&tf->tf_regs);
f0103f38:	89 34 24             	mov    %esi,(%esp)
f0103f3b:	e8 20 ff ff ff       	call   f0103e60 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103f40:	83 c4 08             	add    $0x8,%esp
f0103f43:	0f b7 46 20          	movzwl 0x20(%esi),%eax
f0103f47:	50                   	push   %eax
f0103f48:	8d 83 1a 97 f7 ff    	lea    -0x868e6(%ebx),%eax
f0103f4e:	50                   	push   %eax
f0103f4f:	e8 a1 fa ff ff       	call   f01039f5 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103f54:	83 c4 08             	add    $0x8,%esp
f0103f57:	0f b7 46 24          	movzwl 0x24(%esi),%eax
f0103f5b:	50                   	push   %eax
f0103f5c:	8d 83 2d 97 f7 ff    	lea    -0x868d3(%ebx),%eax
f0103f62:	50                   	push   %eax
f0103f63:	e8 8d fa ff ff       	call   f01039f5 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103f68:	8b 56 28             	mov    0x28(%esi),%edx
	if (trapno < ARRAY_SIZE(excnames))
f0103f6b:	83 c4 10             	add    $0x10,%esp
f0103f6e:	83 fa 13             	cmp    $0x13,%edx
f0103f71:	0f 86 e9 00 00 00    	jbe    f0104060 <print_trapframe+0x150>
		return "System call";
f0103f77:	83 fa 30             	cmp    $0x30,%edx
f0103f7a:	8d 83 d8 96 f7 ff    	lea    -0x86928(%ebx),%eax
f0103f80:	8d 8b e7 96 f7 ff    	lea    -0x86919(%ebx),%ecx
f0103f86:	0f 44 c1             	cmove  %ecx,%eax
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103f89:	83 ec 04             	sub    $0x4,%esp
f0103f8c:	50                   	push   %eax
f0103f8d:	52                   	push   %edx
f0103f8e:	8d 83 40 97 f7 ff    	lea    -0x868c0(%ebx),%eax
f0103f94:	50                   	push   %eax
f0103f95:	e8 5b fa ff ff       	call   f01039f5 <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103f9a:	83 c4 10             	add    $0x10,%esp
f0103f9d:	39 b3 44 2b 00 00    	cmp    %esi,0x2b44(%ebx)
f0103fa3:	0f 84 c3 00 00 00    	je     f010406c <print_trapframe+0x15c>
	cprintf("  err  0x%08x", tf->tf_err);
f0103fa9:	83 ec 08             	sub    $0x8,%esp
f0103fac:	ff 76 2c             	pushl  0x2c(%esi)
f0103faf:	8d 83 61 97 f7 ff    	lea    -0x8689f(%ebx),%eax
f0103fb5:	50                   	push   %eax
f0103fb6:	e8 3a fa ff ff       	call   f01039f5 <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f0103fbb:	83 c4 10             	add    $0x10,%esp
f0103fbe:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f0103fc2:	0f 85 c9 00 00 00    	jne    f0104091 <print_trapframe+0x181>
			tf->tf_err & 1 ? "protection" : "not-present");
f0103fc8:	8b 46 2c             	mov    0x2c(%esi),%eax
		cprintf(" [%s, %s, %s]\n",
f0103fcb:	89 c2                	mov    %eax,%edx
f0103fcd:	83 e2 01             	and    $0x1,%edx
f0103fd0:	8d 8b f3 96 f7 ff    	lea    -0x8690d(%ebx),%ecx
f0103fd6:	8d 93 fe 96 f7 ff    	lea    -0x86902(%ebx),%edx
f0103fdc:	0f 44 ca             	cmove  %edx,%ecx
f0103fdf:	89 c2                	mov    %eax,%edx
f0103fe1:	83 e2 02             	and    $0x2,%edx
f0103fe4:	8d 93 0a 97 f7 ff    	lea    -0x868f6(%ebx),%edx
f0103fea:	8d bb 10 97 f7 ff    	lea    -0x868f0(%ebx),%edi
f0103ff0:	0f 44 d7             	cmove  %edi,%edx
f0103ff3:	83 e0 04             	and    $0x4,%eax
f0103ff6:	8d 83 15 97 f7 ff    	lea    -0x868eb(%ebx),%eax
f0103ffc:	8d bb 2a 98 f7 ff    	lea    -0x867d6(%ebx),%edi
f0104002:	0f 44 c7             	cmove  %edi,%eax
f0104005:	51                   	push   %ecx
f0104006:	52                   	push   %edx
f0104007:	50                   	push   %eax
f0104008:	8d 83 6f 97 f7 ff    	lea    -0x86891(%ebx),%eax
f010400e:	50                   	push   %eax
f010400f:	e8 e1 f9 ff ff       	call   f01039f5 <cprintf>
f0104014:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0104017:	83 ec 08             	sub    $0x8,%esp
f010401a:	ff 76 30             	pushl  0x30(%esi)
f010401d:	8d 83 7e 97 f7 ff    	lea    -0x86882(%ebx),%eax
f0104023:	50                   	push   %eax
f0104024:	e8 cc f9 ff ff       	call   f01039f5 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0104029:	83 c4 08             	add    $0x8,%esp
f010402c:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104030:	50                   	push   %eax
f0104031:	8d 83 8d 97 f7 ff    	lea    -0x86873(%ebx),%eax
f0104037:	50                   	push   %eax
f0104038:	e8 b8 f9 ff ff       	call   f01039f5 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010403d:	83 c4 08             	add    $0x8,%esp
f0104040:	ff 76 38             	pushl  0x38(%esi)
f0104043:	8d 83 a0 97 f7 ff    	lea    -0x86860(%ebx),%eax
f0104049:	50                   	push   %eax
f010404a:	e8 a6 f9 ff ff       	call   f01039f5 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010404f:	83 c4 10             	add    $0x10,%esp
f0104052:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f0104056:	75 50                	jne    f01040a8 <print_trapframe+0x198>
}
f0104058:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010405b:	5b                   	pop    %ebx
f010405c:	5e                   	pop    %esi
f010405d:	5f                   	pop    %edi
f010405e:	5d                   	pop    %ebp
f010405f:	c3                   	ret    
		return excnames[trapno];
f0104060:	8b 84 93 64 20 00 00 	mov    0x2064(%ebx,%edx,4),%eax
f0104067:	e9 1d ff ff ff       	jmp    f0103f89 <print_trapframe+0x79>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f010406c:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f0104070:	0f 85 33 ff ff ff    	jne    f0103fa9 <print_trapframe+0x99>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0104076:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0104079:	83 ec 08             	sub    $0x8,%esp
f010407c:	50                   	push   %eax
f010407d:	8d 83 52 97 f7 ff    	lea    -0x868ae(%ebx),%eax
f0104083:	50                   	push   %eax
f0104084:	e8 6c f9 ff ff       	call   f01039f5 <cprintf>
f0104089:	83 c4 10             	add    $0x10,%esp
f010408c:	e9 18 ff ff ff       	jmp    f0103fa9 <print_trapframe+0x99>
		cprintf("\n");
f0104091:	83 ec 0c             	sub    $0xc,%esp
f0104094:	8d 83 be 94 f7 ff    	lea    -0x86b42(%ebx),%eax
f010409a:	50                   	push   %eax
f010409b:	e8 55 f9 ff ff       	call   f01039f5 <cprintf>
f01040a0:	83 c4 10             	add    $0x10,%esp
f01040a3:	e9 6f ff ff ff       	jmp    f0104017 <print_trapframe+0x107>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01040a8:	83 ec 08             	sub    $0x8,%esp
f01040ab:	ff 76 3c             	pushl  0x3c(%esi)
f01040ae:	8d 83 af 97 f7 ff    	lea    -0x86851(%ebx),%eax
f01040b4:	50                   	push   %eax
f01040b5:	e8 3b f9 ff ff       	call   f01039f5 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01040ba:	83 c4 08             	add    $0x8,%esp
f01040bd:	0f b7 46 40          	movzwl 0x40(%esi),%eax
f01040c1:	50                   	push   %eax
f01040c2:	8d 83 be 97 f7 ff    	lea    -0x86842(%ebx),%eax
f01040c8:	50                   	push   %eax
f01040c9:	e8 27 f9 ff ff       	call   f01039f5 <cprintf>
f01040ce:	83 c4 10             	add    $0x10,%esp
}
f01040d1:	eb 85                	jmp    f0104058 <print_trapframe+0x148>

f01040d3 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01040d3:	f3 0f 1e fb          	endbr32 
f01040d7:	55                   	push   %ebp
f01040d8:	89 e5                	mov    %esp,%ebp
f01040da:	57                   	push   %edi
f01040db:	56                   	push   %esi
f01040dc:	53                   	push   %ebx
f01040dd:	83 ec 0c             	sub    $0xc,%esp
f01040e0:	e8 8e c0 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01040e5:	81 c3 37 8f 08 00    	add    $0x88f37,%ebx
f01040eb:	8b 75 08             	mov    0x8(%ebp),%esi
f01040ee:	0f 20 d0             	mov    %cr2,%eax

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	// check low-bits of tf_cs
	if((tf->tf_cs & 3) == 0)
f01040f1:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f01040f5:	74 38                	je     f010412f <page_fault_handler+0x5c>
	}

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01040f7:	ff 76 30             	pushl  0x30(%esi)
f01040fa:	50                   	push   %eax
f01040fb:	c7 c7 48 f3 18 f0    	mov    $0xf018f348,%edi
f0104101:	8b 07                	mov    (%edi),%eax
f0104103:	ff 70 48             	pushl  0x48(%eax)
f0104106:	8d 83 a0 99 f7 ff    	lea    -0x86660(%ebx),%eax
f010410c:	50                   	push   %eax
f010410d:	e8 e3 f8 ff ff       	call   f01039f5 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0104112:	89 34 24             	mov    %esi,(%esp)
f0104115:	e8 f6 fd ff ff       	call   f0103f10 <print_trapframe>
	env_destroy(curenv);
f010411a:	83 c4 04             	add    $0x4,%esp
f010411d:	ff 37                	pushl  (%edi)
f010411f:	e8 4b f7 ff ff       	call   f010386f <env_destroy>
}
f0104124:	83 c4 10             	add    $0x10,%esp
f0104127:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010412a:	5b                   	pop    %ebx
f010412b:	5e                   	pop    %esi
f010412c:	5f                   	pop    %edi
f010412d:	5d                   	pop    %ebp
f010412e:	c3                   	ret    
		panic("At page_fault_handler: page fault at %08x.\n",fault_va);
f010412f:	50                   	push   %eax
f0104130:	8d 83 74 99 f7 ff    	lea    -0x8668c(%ebx),%eax
f0104136:	50                   	push   %eax
f0104137:	68 28 01 00 00       	push   $0x128
f010413c:	8d 83 d1 97 f7 ff    	lea    -0x8682f(%ebx),%eax
f0104142:	50                   	push   %eax
f0104143:	e8 6d bf ff ff       	call   f01000b5 <_panic>

f0104148 <trap>:
{
f0104148:	f3 0f 1e fb          	endbr32 
f010414c:	55                   	push   %ebp
f010414d:	89 e5                	mov    %esp,%ebp
f010414f:	57                   	push   %edi
f0104150:	56                   	push   %esi
f0104151:	53                   	push   %ebx
f0104152:	83 ec 0c             	sub    $0xc,%esp
f0104155:	e8 19 c0 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f010415a:	81 c3 c2 8e 08 00    	add    $0x88ec2,%ebx
f0104160:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::: "cc");
f0104163:	fc                   	cld    
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0104164:	9c                   	pushf  
f0104165:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
f0104166:	f6 c4 02             	test   $0x2,%ah
f0104169:	74 1f                	je     f010418a <trap+0x42>
f010416b:	8d 83 dd 97 f7 ff    	lea    -0x86823(%ebx),%eax
f0104171:	50                   	push   %eax
f0104172:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0104178:	50                   	push   %eax
f0104179:	68 fd 00 00 00       	push   $0xfd
f010417e:	8d 83 d1 97 f7 ff    	lea    -0x8682f(%ebx),%eax
f0104184:	50                   	push   %eax
f0104185:	e8 2b bf ff ff       	call   f01000b5 <_panic>
	cprintf("Incoming TRAP frame at %p\n", tf);
f010418a:	83 ec 08             	sub    $0x8,%esp
f010418d:	56                   	push   %esi
f010418e:	8d 83 f6 97 f7 ff    	lea    -0x8680a(%ebx),%eax
f0104194:	50                   	push   %eax
f0104195:	e8 5b f8 ff ff       	call   f01039f5 <cprintf>
	if ((tf->tf_cs & 3) == 3) {
f010419a:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f010419e:	83 e0 03             	and    $0x3,%eax
f01041a1:	83 c4 10             	add    $0x10,%esp
f01041a4:	66 83 f8 03          	cmp    $0x3,%ax
f01041a8:	75 1d                	jne    f01041c7 <trap+0x7f>
		assert(curenv);
f01041aa:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f01041b0:	8b 00                	mov    (%eax),%eax
f01041b2:	85 c0                	test   %eax,%eax
f01041b4:	74 41                	je     f01041f7 <trap+0xaf>
		curenv->env_tf = *tf;
f01041b6:	b9 11 00 00 00       	mov    $0x11,%ecx
f01041bb:	89 c7                	mov    %eax,%edi
f01041bd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &curenv->env_tf;
f01041bf:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f01041c5:	8b 30                	mov    (%eax),%esi
	last_tf = tf;
f01041c7:	89 b3 44 2b 00 00    	mov    %esi,0x2b44(%ebx)
	switch(tf->tf_trapno)
f01041cd:	8b 46 28             	mov    0x28(%esi),%eax
f01041d0:	83 f8 0e             	cmp    $0xe,%eax
f01041d3:	74 67                	je     f010423c <trap+0xf4>
f01041d5:	77 3f                	ja     f0104216 <trap+0xce>
f01041d7:	83 f8 01             	cmp    $0x1,%eax
f01041da:	0f 84 99 00 00 00    	je     f0104279 <trap+0x131>
f01041e0:	83 f8 03             	cmp    $0x3,%eax
f01041e3:	0f 85 9e 00 00 00    	jne    f0104287 <trap+0x13f>
			monitor(tf);
f01041e9:	83 ec 0c             	sub    $0xc,%esp
f01041ec:	56                   	push   %esi
f01041ed:	e8 4f c7 ff ff       	call   f0100941 <monitor>
			return;
f01041f2:	83 c4 10             	add    $0x10,%esp
f01041f5:	eb 51                	jmp    f0104248 <trap+0x100>
		assert(curenv);
f01041f7:	8d 83 11 98 f7 ff    	lea    -0x867ef(%ebx),%eax
f01041fd:	50                   	push   %eax
f01041fe:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0104204:	50                   	push   %eax
f0104205:	68 03 01 00 00       	push   $0x103
f010420a:	8d 83 d1 97 f7 ff    	lea    -0x8682f(%ebx),%eax
f0104210:	50                   	push   %eax
f0104211:	e8 9f be ff ff       	call   f01000b5 <_panic>
	switch(tf->tf_trapno)
f0104216:	83 f8 30             	cmp    $0x30,%eax
f0104219:	75 6c                	jne    f0104287 <trap+0x13f>
			int32_t ret = syscall(regs->reg_eax,regs->reg_edx,regs->reg_ecx,regs->reg_ebx,regs->reg_edi,regs->reg_esi);
f010421b:	83 ec 08             	sub    $0x8,%esp
f010421e:	ff 76 04             	pushl  0x4(%esi)
f0104221:	ff 36                	pushl  (%esi)
f0104223:	ff 76 10             	pushl  0x10(%esi)
f0104226:	ff 76 18             	pushl  0x18(%esi)
f0104229:	ff 76 14             	pushl  0x14(%esi)
f010422c:	ff 76 1c             	pushl  0x1c(%esi)
f010422f:	e8 1e 01 00 00       	call   f0104352 <syscall>
			regs->reg_eax = (uint32_t)ret;
f0104234:	89 46 1c             	mov    %eax,0x1c(%esi)
			return;
f0104237:	83 c4 20             	add    $0x20,%esp
f010423a:	eb 0c                	jmp    f0104248 <trap+0x100>
			page_fault_handler(tf);
f010423c:	83 ec 0c             	sub    $0xc,%esp
f010423f:	56                   	push   %esi
f0104240:	e8 8e fe ff ff       	call   f01040d3 <page_fault_handler>
			return;
f0104245:	83 c4 10             	add    $0x10,%esp
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0104248:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f010424e:	8b 00                	mov    (%eax),%eax
f0104250:	85 c0                	test   %eax,%eax
f0104252:	74 06                	je     f010425a <trap+0x112>
f0104254:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104258:	74 70                	je     f01042ca <trap+0x182>
f010425a:	8d 83 c4 99 f7 ff    	lea    -0x8663c(%ebx),%eax
f0104260:	50                   	push   %eax
f0104261:	8d 83 33 92 f7 ff    	lea    -0x86dcd(%ebx),%eax
f0104267:	50                   	push   %eax
f0104268:	68 15 01 00 00       	push   $0x115
f010426d:	8d 83 d1 97 f7 ff    	lea    -0x8682f(%ebx),%eax
f0104273:	50                   	push   %eax
f0104274:	e8 3c be ff ff       	call   f01000b5 <_panic>
			monitor(tf);
f0104279:	83 ec 0c             	sub    $0xc,%esp
f010427c:	56                   	push   %esi
f010427d:	e8 bf c6 ff ff       	call   f0100941 <monitor>
			return;
f0104282:	83 c4 10             	add    $0x10,%esp
f0104285:	eb c1                	jmp    f0104248 <trap+0x100>
	print_trapframe(tf);
f0104287:	83 ec 0c             	sub    $0xc,%esp
f010428a:	56                   	push   %esi
f010428b:	e8 80 fc ff ff       	call   f0103f10 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0104290:	83 c4 10             	add    $0x10,%esp
f0104293:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0104298:	74 15                	je     f01042af <trap+0x167>
		env_destroy(curenv);
f010429a:	83 ec 0c             	sub    $0xc,%esp
f010429d:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f01042a3:	ff 30                	pushl  (%eax)
f01042a5:	e8 c5 f5 ff ff       	call   f010386f <env_destroy>
		return;
f01042aa:	83 c4 10             	add    $0x10,%esp
f01042ad:	eb 99                	jmp    f0104248 <trap+0x100>
		panic("unhandled trap in kernel");
f01042af:	83 ec 04             	sub    $0x4,%esp
f01042b2:	8d 83 18 98 f7 ff    	lea    -0x867e8(%ebx),%eax
f01042b8:	50                   	push   %eax
f01042b9:	68 ec 00 00 00       	push   $0xec
f01042be:	8d 83 d1 97 f7 ff    	lea    -0x8682f(%ebx),%eax
f01042c4:	50                   	push   %eax
f01042c5:	e8 eb bd ff ff       	call   f01000b5 <_panic>
	env_run(curenv);
f01042ca:	83 ec 0c             	sub    $0xc,%esp
f01042cd:	50                   	push   %eax
f01042ce:	e8 12 f6 ff ff       	call   f01038e5 <env_run>
f01042d3:	90                   	nop

f01042d4 <DIVIDE>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(DIVIDE,T_DIVIDE)
f01042d4:	6a 00                	push   $0x0
f01042d6:	6a 00                	push   $0x0
f01042d8:	eb 67                	jmp    f0104341 <_alltraps>

f01042da <DEBUG>:
TRAPHANDLER_NOEC(DEBUG,T_DEBUG)
f01042da:	6a 00                	push   $0x0
f01042dc:	6a 01                	push   $0x1
f01042de:	eb 61                	jmp    f0104341 <_alltraps>

f01042e0 <NMI>:
TRAPHANDLER_NOEC(NMI, T_NMI)
f01042e0:	6a 00                	push   $0x0
f01042e2:	6a 02                	push   $0x2
f01042e4:	eb 5b                	jmp    f0104341 <_alltraps>

f01042e6 <BRKPT>:
TRAPHANDLER_NOEC(BRKPT, T_BRKPT)
f01042e6:	6a 00                	push   $0x0
f01042e8:	6a 03                	push   $0x3
f01042ea:	eb 55                	jmp    f0104341 <_alltraps>

f01042ec <OFLOW>:
TRAPHANDLER_NOEC(OFLOW, T_OFLOW)
f01042ec:	6a 00                	push   $0x0
f01042ee:	6a 04                	push   $0x4
f01042f0:	eb 4f                	jmp    f0104341 <_alltraps>

f01042f2 <BOUND>:
TRAPHANDLER_NOEC(BOUND, T_BOUND)
f01042f2:	6a 00                	push   $0x0
f01042f4:	6a 05                	push   $0x5
f01042f6:	eb 49                	jmp    f0104341 <_alltraps>

f01042f8 <ILLOP>:
TRAPHANDLER_NOEC(ILLOP, T_ILLOP)
f01042f8:	6a 00                	push   $0x0
f01042fa:	6a 06                	push   $0x6
f01042fc:	eb 43                	jmp    f0104341 <_alltraps>

f01042fe <DEVICE>:
TRAPHANDLER_NOEC(DEVICE, T_DEVICE)
f01042fe:	6a 00                	push   $0x0
f0104300:	6a 07                	push   $0x7
f0104302:	eb 3d                	jmp    f0104341 <_alltraps>

f0104304 <DBLFLT>:
TRAPHANDLER(DBLFLT, T_DBLFLT)
f0104304:	6a 08                	push   $0x8
f0104306:	eb 39                	jmp    f0104341 <_alltraps>

f0104308 <TSS>:
TRAPHANDLER(TSS, T_TSS)
f0104308:	6a 0a                	push   $0xa
f010430a:	eb 35                	jmp    f0104341 <_alltraps>

f010430c <SEGNP>:
TRAPHANDLER(SEGNP, T_SEGNP)
f010430c:	6a 0b                	push   $0xb
f010430e:	eb 31                	jmp    f0104341 <_alltraps>

f0104310 <STACK>:
TRAPHANDLER(STACK, T_STACK)
f0104310:	6a 0c                	push   $0xc
f0104312:	eb 2d                	jmp    f0104341 <_alltraps>

f0104314 <GPFLT>:
TRAPHANDLER(GPFLT, T_GPFLT)
f0104314:	6a 0d                	push   $0xd
f0104316:	eb 29                	jmp    f0104341 <_alltraps>

f0104318 <PGFLT>:
TRAPHANDLER(PGFLT, T_PGFLT)
f0104318:	6a 0e                	push   $0xe
f010431a:	eb 25                	jmp    f0104341 <_alltraps>

f010431c <FPERR>:
TRAPHANDLER_NOEC(FPERR, T_FPERR)
f010431c:	6a 00                	push   $0x0
f010431e:	6a 10                	push   $0x10
f0104320:	eb 1f                	jmp    f0104341 <_alltraps>

f0104322 <ALIGN>:
TRAPHANDLER(ALIGN, T_ALIGN)
f0104322:	6a 11                	push   $0x11
f0104324:	eb 1b                	jmp    f0104341 <_alltraps>

f0104326 <MCHK>:
TRAPHANDLER_NOEC(MCHK, T_MCHK)
f0104326:	6a 00                	push   $0x0
f0104328:	6a 12                	push   $0x12
f010432a:	eb 15                	jmp    f0104341 <_alltraps>

f010432c <SIMDERR>:
TRAPHANDLER_NOEC(SIMDERR, T_SIMDERR)
f010432c:	6a 00                	push   $0x0
f010432e:	6a 13                	push   $0x13
f0104330:	eb 0f                	jmp    f0104341 <_alltraps>

f0104332 <SYSCALL>:
TRAPHANDLER_NOEC(SYSCALL, T_SYSCALL)
f0104332:	6a 00                	push   $0x0
f0104334:	6a 30                	push   $0x30
f0104336:	eb 09                	jmp    f0104341 <_alltraps>

f0104338 <DEFAULT>:
TRAPHANDLER_NOEC(DEFAULT, T_DEFAULT)
f0104338:	6a 00                	push   $0x0
f010433a:	68 f4 01 00 00       	push   $0x1f4
f010433f:	eb 00                	jmp    f0104341 <_alltraps>

f0104341 <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */
 .global _alltraps
 _alltraps:
 /* code below according to the guide */
pushl %ds
f0104341:	1e                   	push   %ds
pushl %es
f0104342:	06                   	push   %es
pushal
f0104343:	60                   	pusha  
movw $GD_KD, %ax
f0104344:	66 b8 10 00          	mov    $0x10,%ax
movw %ax, %ds
f0104348:	8e d8                	mov    %eax,%ds
movw %ax, %es
f010434a:	8e c0                	mov    %eax,%es
pushl %esp
f010434c:	54                   	push   %esp
call trap
f010434d:	e8 f6 fd ff ff       	call   f0104148 <trap>

f0104352 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104352:	f3 0f 1e fb          	endbr32 
f0104356:	55                   	push   %ebp
f0104357:	89 e5                	mov    %esp,%ebp
f0104359:	53                   	push   %ebx
f010435a:	83 ec 14             	sub    $0x14,%esp
f010435d:	e8 11 be ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0104362:	81 c3 ba 8c 08 00    	add    $0x88cba,%ebx
f0104368:	8b 45 08             	mov    0x8(%ebp),%eax
f010436b:	83 f8 04             	cmp    $0x4,%eax
f010436e:	77 0c                	ja     f010437c <syscall+0x2a>
f0104370:	89 d9                	mov    %ebx,%ecx
f0104372:	03 8c 83 28 9a f7 ff 	add    -0x865d8(%ebx,%eax,4),%ecx
f0104379:	3e ff e1             	notrack jmp *%ecx
		{
			return sys_env_destroy((envid_t)a1);
		}
		case NSYSCALLS:
		{
			return 0;
f010437c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104381:	e9 bb 00 00 00       	jmp    f0104441 <.L12+0x5>

f0104386 <.L8>:
	user_mem_assert(curenv,s,len,0);
f0104386:	6a 00                	push   $0x0
f0104388:	ff 75 10             	pushl  0x10(%ebp)
f010438b:	ff 75 0c             	pushl  0xc(%ebp)
f010438e:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f0104394:	ff 30                	pushl  (%eax)
f0104396:	e8 40 ed ff ff       	call   f01030db <user_mem_assert>
	cprintf("%.*s", len, s);
f010439b:	83 c4 0c             	add    $0xc,%esp
f010439e:	ff 75 0c             	pushl  0xc(%ebp)
f01043a1:	ff 75 10             	pushl  0x10(%ebp)
f01043a4:	8d 83 f0 99 f7 ff    	lea    -0x86610(%ebx),%eax
f01043aa:	50                   	push   %eax
f01043ab:	e8 45 f6 ff ff       	call   f01039f5 <cprintf>
}
f01043b0:	83 c4 10             	add    $0x10,%esp
			return 0;
f01043b3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01043b8:	e9 84 00 00 00       	jmp    f0104441 <.L12+0x5>

f01043bd <.L7>:
	return cons_getc();
f01043bd:	e8 b2 c1 ff ff       	call   f0100574 <cons_getc>
			return sys_cgetc();
f01043c2:	eb 7d                	jmp    f0104441 <.L12+0x5>

f01043c4 <.L5>:
	if ((r = envid2env(envid, &e, 1)) < 0)
f01043c4:	83 ec 04             	sub    $0x4,%esp
f01043c7:	6a 01                	push   $0x1
f01043c9:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01043cc:	50                   	push   %eax
f01043cd:	ff 75 0c             	pushl  0xc(%ebp)
f01043d0:	e8 2a ee ff ff       	call   f01031ff <envid2env>
f01043d5:	83 c4 10             	add    $0x10,%esp
f01043d8:	85 c0                	test   %eax,%eax
f01043da:	78 65                	js     f0104441 <.L12+0x5>
	if (e == curenv)
f01043dc:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01043df:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f01043e5:	8b 00                	mov    (%eax),%eax
f01043e7:	39 c2                	cmp    %eax,%edx
f01043e9:	74 2d                	je     f0104418 <.L5+0x54>
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f01043eb:	83 ec 04             	sub    $0x4,%esp
f01043ee:	ff 72 48             	pushl  0x48(%edx)
f01043f1:	ff 70 48             	pushl  0x48(%eax)
f01043f4:	8d 83 10 9a f7 ff    	lea    -0x865f0(%ebx),%eax
f01043fa:	50                   	push   %eax
f01043fb:	e8 f5 f5 ff ff       	call   f01039f5 <cprintf>
f0104400:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0104403:	83 ec 0c             	sub    $0xc,%esp
f0104406:	ff 75 f4             	pushl  -0xc(%ebp)
f0104409:	e8 61 f4 ff ff       	call   f010386f <env_destroy>
	return 0;
f010440e:	83 c4 10             	add    $0x10,%esp
f0104411:	b8 00 00 00 00       	mov    $0x0,%eax
			return sys_env_destroy((envid_t)a1);
f0104416:	eb 29                	jmp    f0104441 <.L12+0x5>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104418:	83 ec 08             	sub    $0x8,%esp
f010441b:	ff 70 48             	pushl  0x48(%eax)
f010441e:	8d 83 f5 99 f7 ff    	lea    -0x8660b(%ebx),%eax
f0104424:	50                   	push   %eax
f0104425:	e8 cb f5 ff ff       	call   f01039f5 <cprintf>
f010442a:	83 c4 10             	add    $0x10,%esp
f010442d:	eb d4                	jmp    f0104403 <.L5+0x3f>

f010442f <.L6>:
	return curenv->env_id;
f010442f:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f0104435:	8b 00                	mov    (%eax),%eax
f0104437:	8b 40 48             	mov    0x48(%eax),%eax
		}
		case SYS_getenvid:
		{
			return sys_getenvid();
f010443a:	eb 05                	jmp    f0104441 <.L12+0x5>

f010443c <.L12>:
			return 0;
f010443c:	b8 00 00 00 00       	mov    $0x0,%eax
		}
		default:
			return -E_INVAL;
	}
}
f0104441:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104444:	c9                   	leave  
f0104445:	c3                   	ret    

f0104446 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104446:	55                   	push   %ebp
f0104447:	89 e5                	mov    %esp,%ebp
f0104449:	57                   	push   %edi
f010444a:	56                   	push   %esi
f010444b:	53                   	push   %ebx
f010444c:	83 ec 14             	sub    $0x14,%esp
f010444f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104452:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104455:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104458:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f010445b:	8b 1a                	mov    (%edx),%ebx
f010445d:	8b 01                	mov    (%ecx),%eax
f010445f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104462:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104469:	eb 23                	jmp    f010448e <stab_binsearch+0x48>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010446b:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f010446e:	eb 1e                	jmp    f010448e <stab_binsearch+0x48>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104470:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104473:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104476:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010447a:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010447d:	73 46                	jae    f01044c5 <stab_binsearch+0x7f>
			*region_left = m;
f010447f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104482:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104484:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f0104487:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f010448e:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104491:	7f 5f                	jg     f01044f2 <stab_binsearch+0xac>
		int true_m = (l + r) / 2, m = true_m;
f0104493:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104496:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f0104499:	89 d0                	mov    %edx,%eax
f010449b:	c1 e8 1f             	shr    $0x1f,%eax
f010449e:	01 d0                	add    %edx,%eax
f01044a0:	89 c7                	mov    %eax,%edi
f01044a2:	d1 ff                	sar    %edi
f01044a4:	83 e0 fe             	and    $0xfffffffe,%eax
f01044a7:	01 f8                	add    %edi,%eax
f01044a9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01044ac:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01044b0:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f01044b2:	39 c3                	cmp    %eax,%ebx
f01044b4:	7f b5                	jg     f010446b <stab_binsearch+0x25>
f01044b6:	0f b6 0a             	movzbl (%edx),%ecx
f01044b9:	83 ea 0c             	sub    $0xc,%edx
f01044bc:	39 f1                	cmp    %esi,%ecx
f01044be:	74 b0                	je     f0104470 <stab_binsearch+0x2a>
			m--;
f01044c0:	83 e8 01             	sub    $0x1,%eax
f01044c3:	eb ed                	jmp    f01044b2 <stab_binsearch+0x6c>
		} else if (stabs[m].n_value > addr) {
f01044c5:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01044c8:	76 14                	jbe    f01044de <stab_binsearch+0x98>
			*region_right = m - 1;
f01044ca:	83 e8 01             	sub    $0x1,%eax
f01044cd:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01044d0:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01044d3:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f01044d5:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01044dc:	eb b0                	jmp    f010448e <stab_binsearch+0x48>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01044de:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01044e1:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f01044e3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01044e7:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f01044e9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01044f0:	eb 9c                	jmp    f010448e <stab_binsearch+0x48>
		}
	}

	if (!any_matches)
f01044f2:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01044f6:	75 15                	jne    f010450d <stab_binsearch+0xc7>
		*region_right = *region_left - 1;
f01044f8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01044fb:	8b 00                	mov    (%eax),%eax
f01044fd:	83 e8 01             	sub    $0x1,%eax
f0104500:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104503:	89 07                	mov    %eax,(%edi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0104505:	83 c4 14             	add    $0x14,%esp
f0104508:	5b                   	pop    %ebx
f0104509:	5e                   	pop    %esi
f010450a:	5f                   	pop    %edi
f010450b:	5d                   	pop    %ebp
f010450c:	c3                   	ret    
		for (l = *region_right;
f010450d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104510:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104512:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104515:	8b 0f                	mov    (%edi),%ecx
f0104517:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010451a:	8b 7d ec             	mov    -0x14(%ebp),%edi
f010451d:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
		for (l = *region_right;
f0104521:	eb 03                	jmp    f0104526 <stab_binsearch+0xe0>
		     l--)
f0104523:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0104526:	39 c1                	cmp    %eax,%ecx
f0104528:	7d 0a                	jge    f0104534 <stab_binsearch+0xee>
		     l > *region_left && stabs[l].n_type != type;
f010452a:	0f b6 1a             	movzbl (%edx),%ebx
f010452d:	83 ea 0c             	sub    $0xc,%edx
f0104530:	39 f3                	cmp    %esi,%ebx
f0104532:	75 ef                	jne    f0104523 <stab_binsearch+0xdd>
		*region_left = l;
f0104534:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104537:	89 07                	mov    %eax,(%edi)
}
f0104539:	eb ca                	jmp    f0104505 <stab_binsearch+0xbf>

f010453b <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010453b:	f3 0f 1e fb          	endbr32 
f010453f:	55                   	push   %ebp
f0104540:	89 e5                	mov    %esp,%ebp
f0104542:	57                   	push   %edi
f0104543:	56                   	push   %esi
f0104544:	53                   	push   %ebx
f0104545:	83 ec 2c             	sub    $0x2c,%esp
f0104548:	e8 26 bc ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f010454d:	81 c3 cf 8a 08 00    	add    $0x88acf,%ebx
f0104553:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104556:	8d 83 3c 9a f7 ff    	lea    -0x865c4(%ebx),%eax
f010455c:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f010455e:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0104565:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f0104568:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f010456f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104572:	89 47 10             	mov    %eax,0x10(%edi)
	info->eip_fn_narg = 0;
f0104575:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010457c:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0104581:	0f 86 ef 00 00 00    	jbe    f0104676 <debuginfo_eip+0x13b>
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104587:	c7 c0 13 2f 11 f0    	mov    $0xf0112f13,%eax
f010458d:	89 45 d0             	mov    %eax,-0x30(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0104590:	c7 c0 ed 03 11 f0    	mov    $0xf01103ed,%eax
f0104596:	89 45 cc             	mov    %eax,-0x34(%ebp)
		stab_end = __STAB_END__;
f0104599:	c7 c6 ec 03 11 f0    	mov    $0xf01103ec,%esi
		stabs = __STAB_BEGIN__;
f010459f:	c7 c0 54 6c 10 f0    	mov    $0xf0106c54,%eax
f01045a5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01045a8:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01045ab:	39 4d cc             	cmp    %ecx,-0x34(%ebp)
f01045ae:	0f 83 db 01 00 00    	jae    f010478f <debuginfo_eip+0x254>
f01045b4:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f01045b8:	0f 85 d8 01 00 00    	jne    f0104796 <debuginfo_eip+0x25b>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01045be:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01045c5:	2b 75 d4             	sub    -0x2c(%ebp),%esi
f01045c8:	c1 fe 02             	sar    $0x2,%esi
f01045cb:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f01045d1:	83 e8 01             	sub    $0x1,%eax
f01045d4:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01045d7:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01045da:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01045dd:	83 ec 08             	sub    $0x8,%esp
f01045e0:	ff 75 08             	pushl  0x8(%ebp)
f01045e3:	6a 64                	push   $0x64
f01045e5:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01045e8:	89 f0                	mov    %esi,%eax
f01045ea:	e8 57 fe ff ff       	call   f0104446 <stab_binsearch>
	if (lfile == 0)
f01045ef:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01045f2:	83 c4 10             	add    $0x10,%esp
f01045f5:	85 c0                	test   %eax,%eax
f01045f7:	0f 84 a0 01 00 00    	je     f010479d <debuginfo_eip+0x262>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01045fd:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104600:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104603:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104606:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104609:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010460c:	83 ec 08             	sub    $0x8,%esp
f010460f:	ff 75 08             	pushl  0x8(%ebp)
f0104612:	6a 24                	push   $0x24
f0104614:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0104617:	89 f0                	mov    %esi,%eax
f0104619:	e8 28 fe ff ff       	call   f0104446 <stab_binsearch>

	if (lfun <= rfun) {
f010461e:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0104621:	83 c4 10             	add    $0x10,%esp
f0104624:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f0104627:	0f 8f d5 00 00 00    	jg     f0104702 <debuginfo_eip+0x1c7>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010462d:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104630:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104633:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104636:	8b 02                	mov    (%edx),%eax
f0104638:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010463b:	2b 4d cc             	sub    -0x34(%ebp),%ecx
f010463e:	39 c8                	cmp    %ecx,%eax
f0104640:	73 06                	jae    f0104648 <debuginfo_eip+0x10d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104642:	03 45 cc             	add    -0x34(%ebp),%eax
f0104645:	89 47 08             	mov    %eax,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104648:	8b 42 08             	mov    0x8(%edx),%eax
f010464b:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010464e:	83 ec 08             	sub    $0x8,%esp
f0104651:	6a 3a                	push   $0x3a
f0104653:	ff 77 08             	pushl  0x8(%edi)
f0104656:	e8 24 0a 00 00       	call   f010507f <strfind>
f010465b:	2b 47 08             	sub    0x8(%edi),%eax
f010465e:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104661:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104664:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104667:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010466a:	8d 44 81 04          	lea    0x4(%ecx,%eax,4),%eax
f010466e:	83 c4 10             	add    $0x10,%esp
f0104671:	e9 a0 00 00 00       	jmp    f0104716 <debuginfo_eip+0x1db>
		if(user_mem_check(curenv,usd,sizeof(struct UserStabData),PTE_P|PTE_U) != 0)
f0104676:	6a 05                	push   $0x5
f0104678:	6a 10                	push   $0x10
f010467a:	68 00 00 20 00       	push   $0x200000
f010467f:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f0104685:	ff 30                	pushl  (%eax)
f0104687:	e8 af e9 ff ff       	call   f010303b <user_mem_check>
f010468c:	83 c4 10             	add    $0x10,%esp
f010468f:	85 c0                	test   %eax,%eax
f0104691:	0f 85 ea 00 00 00    	jne    f0104781 <debuginfo_eip+0x246>
		stabs = usd->stabs;
f0104697:	8b 15 00 00 20 00    	mov    0x200000,%edx
f010469d:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		stab_end = usd->stab_end;
f01046a0:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f01046a6:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f01046ac:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f01046af:	a1 0c 00 20 00       	mov    0x20000c,%eax
f01046b4:	89 45 d0             	mov    %eax,-0x30(%ebp)
		if(user_mem_check(curenv,stabs,sizeof(struct Stab),PTE_P|PTE_U) != 0)
f01046b7:	6a 05                	push   $0x5
f01046b9:	6a 0c                	push   $0xc
f01046bb:	52                   	push   %edx
f01046bc:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f01046c2:	ff 30                	pushl  (%eax)
f01046c4:	e8 72 e9 ff ff       	call   f010303b <user_mem_check>
f01046c9:	83 c4 10             	add    $0x10,%esp
f01046cc:	85 c0                	test   %eax,%eax
f01046ce:	0f 85 b4 00 00 00    	jne    f0104788 <debuginfo_eip+0x24d>
		if(user_mem_check(curenv,stabstr,stabstr_end-stabstr,PTE_P|PTE_U) != 0)
f01046d4:	6a 05                	push   $0x5
f01046d6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01046d9:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01046dc:	29 c8                	sub    %ecx,%eax
f01046de:	50                   	push   %eax
f01046df:	51                   	push   %ecx
f01046e0:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f01046e6:	ff 30                	pushl  (%eax)
f01046e8:	e8 4e e9 ff ff       	call   f010303b <user_mem_check>
f01046ed:	83 c4 10             	add    $0x10,%esp
f01046f0:	85 c0                	test   %eax,%eax
f01046f2:	0f 84 b0 fe ff ff    	je     f01045a8 <debuginfo_eip+0x6d>
			return -1;
f01046f8:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01046fd:	e9 a7 00 00 00       	jmp    f01047a9 <debuginfo_eip+0x26e>
		info->eip_fn_addr = addr;
f0104702:	8b 45 08             	mov    0x8(%ebp),%eax
f0104705:	89 47 10             	mov    %eax,0x10(%edi)
		lline = lfile;
f0104708:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010470b:	e9 3e ff ff ff       	jmp    f010464e <debuginfo_eip+0x113>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0104710:	83 ee 01             	sub    $0x1,%esi
f0104713:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0104716:	39 f3                	cmp    %esi,%ebx
f0104718:	7f 2e                	jg     f0104748 <debuginfo_eip+0x20d>
	       && stabs[lline].n_type != N_SOL
f010471a:	0f b6 10             	movzbl (%eax),%edx
f010471d:	80 fa 84             	cmp    $0x84,%dl
f0104720:	74 0b                	je     f010472d <debuginfo_eip+0x1f2>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104722:	80 fa 64             	cmp    $0x64,%dl
f0104725:	75 e9                	jne    f0104710 <debuginfo_eip+0x1d5>
f0104727:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f010472b:	74 e3                	je     f0104710 <debuginfo_eip+0x1d5>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010472d:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104730:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104733:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0104736:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104739:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f010473c:	29 d8                	sub    %ebx,%eax
f010473e:	39 c2                	cmp    %eax,%edx
f0104740:	73 06                	jae    f0104748 <debuginfo_eip+0x20d>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104742:	89 d8                	mov    %ebx,%eax
f0104744:	01 d0                	add    %edx,%eax
f0104746:	89 07                	mov    %eax,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104748:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010474b:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010474e:	ba 00 00 00 00       	mov    $0x0,%edx
	if (lfun < rfun)
f0104753:	39 c8                	cmp    %ecx,%eax
f0104755:	7d 52                	jge    f01047a9 <debuginfo_eip+0x26e>
		for (lline = lfun + 1;
f0104757:	8d 50 01             	lea    0x1(%eax),%edx
f010475a:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010475d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104760:	8d 44 83 10          	lea    0x10(%ebx,%eax,4),%eax
f0104764:	eb 07                	jmp    f010476d <debuginfo_eip+0x232>
			info->eip_fn_narg++;
f0104766:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f010476a:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f010476d:	39 d1                	cmp    %edx,%ecx
f010476f:	74 33                	je     f01047a4 <debuginfo_eip+0x269>
f0104771:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104774:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0104778:	74 ec                	je     f0104766 <debuginfo_eip+0x22b>
	return 0;
f010477a:	ba 00 00 00 00       	mov    $0x0,%edx
f010477f:	eb 28                	jmp    f01047a9 <debuginfo_eip+0x26e>
			return -1;
f0104781:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104786:	eb 21                	jmp    f01047a9 <debuginfo_eip+0x26e>
			return -1;
f0104788:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010478d:	eb 1a                	jmp    f01047a9 <debuginfo_eip+0x26e>
		return -1;
f010478f:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104794:	eb 13                	jmp    f01047a9 <debuginfo_eip+0x26e>
f0104796:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010479b:	eb 0c                	jmp    f01047a9 <debuginfo_eip+0x26e>
		return -1;
f010479d:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01047a2:	eb 05                	jmp    f01047a9 <debuginfo_eip+0x26e>
	return 0;
f01047a4:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01047a9:	89 d0                	mov    %edx,%eax
f01047ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01047ae:	5b                   	pop    %ebx
f01047af:	5e                   	pop    %esi
f01047b0:	5f                   	pop    %edi
f01047b1:	5d                   	pop    %ebp
f01047b2:	c3                   	ret    

f01047b3 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01047b3:	55                   	push   %ebp
f01047b4:	89 e5                	mov    %esp,%ebp
f01047b6:	57                   	push   %edi
f01047b7:	56                   	push   %esi
f01047b8:	53                   	push   %ebx
f01047b9:	83 ec 2c             	sub    $0x2c,%esp
f01047bc:	e8 7b e9 ff ff       	call   f010313c <__x86.get_pc_thunk.cx>
f01047c1:	81 c1 5b 88 08 00    	add    $0x8885b,%ecx
f01047c7:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01047ca:	89 c7                	mov    %eax,%edi
f01047cc:	89 d6                	mov    %edx,%esi
f01047ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01047d1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01047d4:	89 d1                	mov    %edx,%ecx
f01047d6:	89 c2                	mov    %eax,%edx
f01047d8:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01047db:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01047de:	8b 45 10             	mov    0x10(%ebp),%eax
f01047e1:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01047e4:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01047e7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01047ee:	39 c2                	cmp    %eax,%edx
f01047f0:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f01047f3:	72 41                	jb     f0104836 <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01047f5:	83 ec 0c             	sub    $0xc,%esp
f01047f8:	ff 75 18             	pushl  0x18(%ebp)
f01047fb:	83 eb 01             	sub    $0x1,%ebx
f01047fe:	53                   	push   %ebx
f01047ff:	50                   	push   %eax
f0104800:	83 ec 08             	sub    $0x8,%esp
f0104803:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104806:	ff 75 e0             	pushl  -0x20(%ebp)
f0104809:	ff 75 d4             	pushl  -0x2c(%ebp)
f010480c:	ff 75 d0             	pushl  -0x30(%ebp)
f010480f:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104812:	e8 99 0a 00 00       	call   f01052b0 <__udivdi3>
f0104817:	83 c4 18             	add    $0x18,%esp
f010481a:	52                   	push   %edx
f010481b:	50                   	push   %eax
f010481c:	89 f2                	mov    %esi,%edx
f010481e:	89 f8                	mov    %edi,%eax
f0104820:	e8 8e ff ff ff       	call   f01047b3 <printnum>
f0104825:	83 c4 20             	add    $0x20,%esp
f0104828:	eb 13                	jmp    f010483d <printnum+0x8a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010482a:	83 ec 08             	sub    $0x8,%esp
f010482d:	56                   	push   %esi
f010482e:	ff 75 18             	pushl  0x18(%ebp)
f0104831:	ff d7                	call   *%edi
f0104833:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0104836:	83 eb 01             	sub    $0x1,%ebx
f0104839:	85 db                	test   %ebx,%ebx
f010483b:	7f ed                	jg     f010482a <printnum+0x77>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010483d:	83 ec 08             	sub    $0x8,%esp
f0104840:	56                   	push   %esi
f0104841:	83 ec 04             	sub    $0x4,%esp
f0104844:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104847:	ff 75 e0             	pushl  -0x20(%ebp)
f010484a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010484d:	ff 75 d0             	pushl  -0x30(%ebp)
f0104850:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104853:	e8 68 0b 00 00       	call   f01053c0 <__umoddi3>
f0104858:	83 c4 14             	add    $0x14,%esp
f010485b:	0f be 84 03 46 9a f7 	movsbl -0x865ba(%ebx,%eax,1),%eax
f0104862:	ff 
f0104863:	50                   	push   %eax
f0104864:	ff d7                	call   *%edi
}
f0104866:	83 c4 10             	add    $0x10,%esp
f0104869:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010486c:	5b                   	pop    %ebx
f010486d:	5e                   	pop    %esi
f010486e:	5f                   	pop    %edi
f010486f:	5d                   	pop    %ebp
f0104870:	c3                   	ret    

f0104871 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104871:	f3 0f 1e fb          	endbr32 
f0104875:	55                   	push   %ebp
f0104876:	89 e5                	mov    %esp,%ebp
f0104878:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010487b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010487f:	8b 10                	mov    (%eax),%edx
f0104881:	3b 50 04             	cmp    0x4(%eax),%edx
f0104884:	73 0a                	jae    f0104890 <sprintputch+0x1f>
		*b->buf++ = ch;
f0104886:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104889:	89 08                	mov    %ecx,(%eax)
f010488b:	8b 45 08             	mov    0x8(%ebp),%eax
f010488e:	88 02                	mov    %al,(%edx)
}
f0104890:	5d                   	pop    %ebp
f0104891:	c3                   	ret    

f0104892 <printfmt>:
{
f0104892:	f3 0f 1e fb          	endbr32 
f0104896:	55                   	push   %ebp
f0104897:	89 e5                	mov    %esp,%ebp
f0104899:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f010489c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010489f:	50                   	push   %eax
f01048a0:	ff 75 10             	pushl  0x10(%ebp)
f01048a3:	ff 75 0c             	pushl  0xc(%ebp)
f01048a6:	ff 75 08             	pushl  0x8(%ebp)
f01048a9:	e8 05 00 00 00       	call   f01048b3 <vprintfmt>
}
f01048ae:	83 c4 10             	add    $0x10,%esp
f01048b1:	c9                   	leave  
f01048b2:	c3                   	ret    

f01048b3 <vprintfmt>:
{
f01048b3:	f3 0f 1e fb          	endbr32 
f01048b7:	55                   	push   %ebp
f01048b8:	89 e5                	mov    %esp,%ebp
f01048ba:	57                   	push   %edi
f01048bb:	56                   	push   %esi
f01048bc:	53                   	push   %ebx
f01048bd:	83 ec 3c             	sub    $0x3c,%esp
f01048c0:	e8 62 be ff ff       	call   f0100727 <__x86.get_pc_thunk.ax>
f01048c5:	05 57 87 08 00       	add    $0x88757,%eax
f01048ca:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01048cd:	8b 75 08             	mov    0x8(%ebp),%esi
f01048d0:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01048d3:	8b 5d 10             	mov    0x10(%ebp),%ebx
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01048d6:	8d 80 b4 20 00 00    	lea    0x20b4(%eax),%eax
f01048dc:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01048df:	e9 cd 03 00 00       	jmp    f0104cb1 <.L25+0x48>
		padc = ' ';
f01048e4:	c6 45 cf 20          	movb   $0x20,-0x31(%ebp)
		altflag = 0;
f01048e8:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
		precision = -1;
f01048ef:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f01048f6:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		lflag = 0;
f01048fd:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104902:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0104905:	89 75 08             	mov    %esi,0x8(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104908:	8d 43 01             	lea    0x1(%ebx),%eax
f010490b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010490e:	0f b6 13             	movzbl (%ebx),%edx
f0104911:	8d 42 dd             	lea    -0x23(%edx),%eax
f0104914:	3c 55                	cmp    $0x55,%al
f0104916:	0f 87 21 04 00 00    	ja     f0104d3d <.L20>
f010491c:	0f b6 c0             	movzbl %al,%eax
f010491f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104922:	89 ce                	mov    %ecx,%esi
f0104924:	03 b4 81 d0 9a f7 ff 	add    -0x86530(%ecx,%eax,4),%esi
f010492b:	3e ff e6             	notrack jmp *%esi

f010492e <.L68>:
f010492e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '-';
f0104931:	c6 45 cf 2d          	movb   $0x2d,-0x31(%ebp)
f0104935:	eb d1                	jmp    f0104908 <vprintfmt+0x55>

f0104937 <.L32>:
		switch (ch = *(unsigned char *) fmt++) {
f0104937:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010493a:	c6 45 cf 30          	movb   $0x30,-0x31(%ebp)
f010493e:	eb c8                	jmp    f0104908 <vprintfmt+0x55>

f0104940 <.L31>:
f0104940:	0f b6 d2             	movzbl %dl,%edx
f0104943:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			for (precision = 0; ; ++fmt) {
f0104946:	b8 00 00 00 00       	mov    $0x0,%eax
f010494b:	8b 75 08             	mov    0x8(%ebp),%esi
				precision = precision * 10 + ch - '0';
f010494e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104951:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0104955:	0f be 13             	movsbl (%ebx),%edx
				if (ch < '0' || ch > '9')
f0104958:	8d 4a d0             	lea    -0x30(%edx),%ecx
f010495b:	83 f9 09             	cmp    $0x9,%ecx
f010495e:	77 58                	ja     f01049b8 <.L36+0xf>
			for (precision = 0; ; ++fmt) {
f0104960:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f0104963:	eb e9                	jmp    f010494e <.L31+0xe>

f0104965 <.L34>:
			precision = va_arg(ap, int);
f0104965:	8b 45 14             	mov    0x14(%ebp),%eax
f0104968:	8b 00                	mov    (%eax),%eax
f010496a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010496d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104970:	8d 40 04             	lea    0x4(%eax),%eax
f0104973:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104976:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if (width < 0)
f0104979:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f010497d:	79 89                	jns    f0104908 <vprintfmt+0x55>
				width = precision, precision = -1;
f010497f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104982:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104985:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f010498c:	e9 77 ff ff ff       	jmp    f0104908 <vprintfmt+0x55>

f0104991 <.L33>:
f0104991:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104994:	85 c0                	test   %eax,%eax
f0104996:	ba 00 00 00 00       	mov    $0x0,%edx
f010499b:	0f 49 d0             	cmovns %eax,%edx
f010499e:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01049a1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f01049a4:	e9 5f ff ff ff       	jmp    f0104908 <vprintfmt+0x55>

f01049a9 <.L36>:
		switch (ch = *(unsigned char *) fmt++) {
f01049a9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			altflag = 1;
f01049ac:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f01049b3:	e9 50 ff ff ff       	jmp    f0104908 <vprintfmt+0x55>
f01049b8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01049bb:	89 75 08             	mov    %esi,0x8(%ebp)
f01049be:	eb b9                	jmp    f0104979 <.L34+0x14>

f01049c0 <.L27>:
			lflag++;
f01049c0:	83 45 c8 01          	addl   $0x1,-0x38(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01049c4:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f01049c7:	e9 3c ff ff ff       	jmp    f0104908 <vprintfmt+0x55>

f01049cc <.L30>:
f01049cc:	8b 75 08             	mov    0x8(%ebp),%esi
			putch(va_arg(ap, int), putdat);
f01049cf:	8b 45 14             	mov    0x14(%ebp),%eax
f01049d2:	8d 58 04             	lea    0x4(%eax),%ebx
f01049d5:	83 ec 08             	sub    $0x8,%esp
f01049d8:	57                   	push   %edi
f01049d9:	ff 30                	pushl  (%eax)
f01049db:	ff d6                	call   *%esi
			break;
f01049dd:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01049e0:	89 5d 14             	mov    %ebx,0x14(%ebp)
			break;
f01049e3:	e9 c6 02 00 00       	jmp    f0104cae <.L25+0x45>

f01049e8 <.L28>:
f01049e8:	8b 75 08             	mov    0x8(%ebp),%esi
			err = va_arg(ap, int);
f01049eb:	8b 45 14             	mov    0x14(%ebp),%eax
f01049ee:	8d 58 04             	lea    0x4(%eax),%ebx
f01049f1:	8b 00                	mov    (%eax),%eax
f01049f3:	99                   	cltd   
f01049f4:	31 d0                	xor    %edx,%eax
f01049f6:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01049f8:	83 f8 06             	cmp    $0x6,%eax
f01049fb:	7f 27                	jg     f0104a24 <.L28+0x3c>
f01049fd:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0104a00:	8b 14 82             	mov    (%edx,%eax,4),%edx
f0104a03:	85 d2                	test   %edx,%edx
f0104a05:	74 1d                	je     f0104a24 <.L28+0x3c>
				printfmt(putch, putdat, "%s", p);
f0104a07:	52                   	push   %edx
f0104a08:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104a0b:	8d 80 45 92 f7 ff    	lea    -0x86dbb(%eax),%eax
f0104a11:	50                   	push   %eax
f0104a12:	57                   	push   %edi
f0104a13:	56                   	push   %esi
f0104a14:	e8 79 fe ff ff       	call   f0104892 <printfmt>
f0104a19:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0104a1c:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0104a1f:	e9 8a 02 00 00       	jmp    f0104cae <.L25+0x45>
				printfmt(putch, putdat, "error %d", err);
f0104a24:	50                   	push   %eax
f0104a25:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104a28:	8d 80 5e 9a f7 ff    	lea    -0x865a2(%eax),%eax
f0104a2e:	50                   	push   %eax
f0104a2f:	57                   	push   %edi
f0104a30:	56                   	push   %esi
f0104a31:	e8 5c fe ff ff       	call   f0104892 <printfmt>
f0104a36:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0104a39:	89 5d 14             	mov    %ebx,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0104a3c:	e9 6d 02 00 00       	jmp    f0104cae <.L25+0x45>

f0104a41 <.L24>:
f0104a41:	8b 75 08             	mov    0x8(%ebp),%esi
			if ((p = va_arg(ap, char *)) == NULL)
f0104a44:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a47:	83 c0 04             	add    $0x4,%eax
f0104a4a:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0104a4d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a50:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f0104a52:	85 d2                	test   %edx,%edx
f0104a54:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104a57:	8d 80 57 9a f7 ff    	lea    -0x865a9(%eax),%eax
f0104a5d:	0f 45 c2             	cmovne %edx,%eax
f0104a60:	89 45 c8             	mov    %eax,-0x38(%ebp)
			if (width > 0 && padc != '-')
f0104a63:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0104a67:	7e 06                	jle    f0104a6f <.L24+0x2e>
f0104a69:	80 7d cf 2d          	cmpb   $0x2d,-0x31(%ebp)
f0104a6d:	75 0d                	jne    f0104a7c <.L24+0x3b>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104a6f:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0104a72:	89 c3                	mov    %eax,%ebx
f0104a74:	03 45 d4             	add    -0x2c(%ebp),%eax
f0104a77:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104a7a:	eb 58                	jmp    f0104ad4 <.L24+0x93>
f0104a7c:	83 ec 08             	sub    $0x8,%esp
f0104a7f:	ff 75 d8             	pushl  -0x28(%ebp)
f0104a82:	ff 75 c8             	pushl  -0x38(%ebp)
f0104a85:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104a88:	e8 81 04 00 00       	call   f0104f0e <strnlen>
f0104a8d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0104a90:	29 c2                	sub    %eax,%edx
f0104a92:	89 55 bc             	mov    %edx,-0x44(%ebp)
f0104a95:	83 c4 10             	add    $0x10,%esp
f0104a98:	89 d3                	mov    %edx,%ebx
					putch(padc, putdat);
f0104a9a:	0f be 45 cf          	movsbl -0x31(%ebp),%eax
f0104a9e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0104aa1:	85 db                	test   %ebx,%ebx
f0104aa3:	7e 11                	jle    f0104ab6 <.L24+0x75>
					putch(padc, putdat);
f0104aa5:	83 ec 08             	sub    $0x8,%esp
f0104aa8:	57                   	push   %edi
f0104aa9:	ff 75 d4             	pushl  -0x2c(%ebp)
f0104aac:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0104aae:	83 eb 01             	sub    $0x1,%ebx
f0104ab1:	83 c4 10             	add    $0x10,%esp
f0104ab4:	eb eb                	jmp    f0104aa1 <.L24+0x60>
f0104ab6:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104ab9:	85 d2                	test   %edx,%edx
f0104abb:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ac0:	0f 49 c2             	cmovns %edx,%eax
f0104ac3:	29 c2                	sub    %eax,%edx
f0104ac5:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104ac8:	eb a5                	jmp    f0104a6f <.L24+0x2e>
					putch(ch, putdat);
f0104aca:	83 ec 08             	sub    $0x8,%esp
f0104acd:	57                   	push   %edi
f0104ace:	52                   	push   %edx
f0104acf:	ff d6                	call   *%esi
f0104ad1:	83 c4 10             	add    $0x10,%esp
f0104ad4:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104ad7:	29 d9                	sub    %ebx,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104ad9:	83 c3 01             	add    $0x1,%ebx
f0104adc:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0104ae0:	0f be d0             	movsbl %al,%edx
f0104ae3:	85 d2                	test   %edx,%edx
f0104ae5:	74 4b                	je     f0104b32 <.L24+0xf1>
f0104ae7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104aeb:	78 06                	js     f0104af3 <.L24+0xb2>
f0104aed:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f0104af1:	78 1e                	js     f0104b11 <.L24+0xd0>
				if (altflag && (ch < ' ' || ch > '~'))
f0104af3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0104af7:	74 d1                	je     f0104aca <.L24+0x89>
f0104af9:	0f be c0             	movsbl %al,%eax
f0104afc:	83 e8 20             	sub    $0x20,%eax
f0104aff:	83 f8 5e             	cmp    $0x5e,%eax
f0104b02:	76 c6                	jbe    f0104aca <.L24+0x89>
					putch('?', putdat);
f0104b04:	83 ec 08             	sub    $0x8,%esp
f0104b07:	57                   	push   %edi
f0104b08:	6a 3f                	push   $0x3f
f0104b0a:	ff d6                	call   *%esi
f0104b0c:	83 c4 10             	add    $0x10,%esp
f0104b0f:	eb c3                	jmp    f0104ad4 <.L24+0x93>
f0104b11:	89 cb                	mov    %ecx,%ebx
f0104b13:	eb 0e                	jmp    f0104b23 <.L24+0xe2>
				putch(' ', putdat);
f0104b15:	83 ec 08             	sub    $0x8,%esp
f0104b18:	57                   	push   %edi
f0104b19:	6a 20                	push   $0x20
f0104b1b:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0104b1d:	83 eb 01             	sub    $0x1,%ebx
f0104b20:	83 c4 10             	add    $0x10,%esp
f0104b23:	85 db                	test   %ebx,%ebx
f0104b25:	7f ee                	jg     f0104b15 <.L24+0xd4>
			if ((p = va_arg(ap, char *)) == NULL)
f0104b27:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0104b2a:	89 45 14             	mov    %eax,0x14(%ebp)
f0104b2d:	e9 7c 01 00 00       	jmp    f0104cae <.L25+0x45>
f0104b32:	89 cb                	mov    %ecx,%ebx
f0104b34:	eb ed                	jmp    f0104b23 <.L24+0xe2>

f0104b36 <.L29>:
f0104b36:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0104b39:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f0104b3c:	83 f9 01             	cmp    $0x1,%ecx
f0104b3f:	7f 1b                	jg     f0104b5c <.L29+0x26>
	else if (lflag)
f0104b41:	85 c9                	test   %ecx,%ecx
f0104b43:	74 63                	je     f0104ba8 <.L29+0x72>
		return va_arg(*ap, long);
f0104b45:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b48:	8b 00                	mov    (%eax),%eax
f0104b4a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104b4d:	99                   	cltd   
f0104b4e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104b51:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b54:	8d 40 04             	lea    0x4(%eax),%eax
f0104b57:	89 45 14             	mov    %eax,0x14(%ebp)
f0104b5a:	eb 17                	jmp    f0104b73 <.L29+0x3d>
		return va_arg(*ap, long long);
f0104b5c:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b5f:	8b 50 04             	mov    0x4(%eax),%edx
f0104b62:	8b 00                	mov    (%eax),%eax
f0104b64:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104b67:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104b6a:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b6d:	8d 40 08             	lea    0x8(%eax),%eax
f0104b70:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0104b73:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104b76:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0104b79:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f0104b7e:	85 c9                	test   %ecx,%ecx
f0104b80:	0f 89 0e 01 00 00    	jns    f0104c94 <.L25+0x2b>
				putch('-', putdat);
f0104b86:	83 ec 08             	sub    $0x8,%esp
f0104b89:	57                   	push   %edi
f0104b8a:	6a 2d                	push   $0x2d
f0104b8c:	ff d6                	call   *%esi
				num = -(long long) num;
f0104b8e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104b91:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104b94:	f7 da                	neg    %edx
f0104b96:	83 d1 00             	adc    $0x0,%ecx
f0104b99:	f7 d9                	neg    %ecx
f0104b9b:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0104b9e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104ba3:	e9 ec 00 00 00       	jmp    f0104c94 <.L25+0x2b>
		return va_arg(*ap, int);
f0104ba8:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bab:	8b 00                	mov    (%eax),%eax
f0104bad:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104bb0:	99                   	cltd   
f0104bb1:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104bb4:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bb7:	8d 40 04             	lea    0x4(%eax),%eax
f0104bba:	89 45 14             	mov    %eax,0x14(%ebp)
f0104bbd:	eb b4                	jmp    f0104b73 <.L29+0x3d>

f0104bbf <.L23>:
f0104bbf:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0104bc2:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f0104bc5:	83 f9 01             	cmp    $0x1,%ecx
f0104bc8:	7f 1e                	jg     f0104be8 <.L23+0x29>
	else if (lflag)
f0104bca:	85 c9                	test   %ecx,%ecx
f0104bcc:	74 32                	je     f0104c00 <.L23+0x41>
		return va_arg(*ap, unsigned long);
f0104bce:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bd1:	8b 10                	mov    (%eax),%edx
f0104bd3:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104bd8:	8d 40 04             	lea    0x4(%eax),%eax
f0104bdb:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104bde:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long);
f0104be3:	e9 ac 00 00 00       	jmp    f0104c94 <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f0104be8:	8b 45 14             	mov    0x14(%ebp),%eax
f0104beb:	8b 10                	mov    (%eax),%edx
f0104bed:	8b 48 04             	mov    0x4(%eax),%ecx
f0104bf0:	8d 40 08             	lea    0x8(%eax),%eax
f0104bf3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104bf6:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long long);
f0104bfb:	e9 94 00 00 00       	jmp    f0104c94 <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f0104c00:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c03:	8b 10                	mov    (%eax),%edx
f0104c05:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104c0a:	8d 40 04             	lea    0x4(%eax),%eax
f0104c0d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104c10:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned int);
f0104c15:	eb 7d                	jmp    f0104c94 <.L25+0x2b>

f0104c17 <.L26>:
f0104c17:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0104c1a:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f0104c1d:	83 f9 01             	cmp    $0x1,%ecx
f0104c20:	7f 1b                	jg     f0104c3d <.L26+0x26>
	else if (lflag)
f0104c22:	85 c9                	test   %ecx,%ecx
f0104c24:	74 2c                	je     f0104c52 <.L26+0x3b>
		return va_arg(*ap, unsigned long);
f0104c26:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c29:	8b 10                	mov    (%eax),%edx
f0104c2b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104c30:	8d 40 04             	lea    0x4(%eax),%eax
f0104c33:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0104c36:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long);
f0104c3b:	eb 57                	jmp    f0104c94 <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f0104c3d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c40:	8b 10                	mov    (%eax),%edx
f0104c42:	8b 48 04             	mov    0x4(%eax),%ecx
f0104c45:	8d 40 08             	lea    0x8(%eax),%eax
f0104c48:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0104c4b:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long long);
f0104c50:	eb 42                	jmp    f0104c94 <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f0104c52:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c55:	8b 10                	mov    (%eax),%edx
f0104c57:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104c5c:	8d 40 04             	lea    0x4(%eax),%eax
f0104c5f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0104c62:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned int);
f0104c67:	eb 2b                	jmp    f0104c94 <.L25+0x2b>

f0104c69 <.L25>:
f0104c69:	8b 75 08             	mov    0x8(%ebp),%esi
			putch('0', putdat);
f0104c6c:	83 ec 08             	sub    $0x8,%esp
f0104c6f:	57                   	push   %edi
f0104c70:	6a 30                	push   $0x30
f0104c72:	ff d6                	call   *%esi
			putch('x', putdat);
f0104c74:	83 c4 08             	add    $0x8,%esp
f0104c77:	57                   	push   %edi
f0104c78:	6a 78                	push   $0x78
f0104c7a:	ff d6                	call   *%esi
			num = (unsigned long long)
f0104c7c:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c7f:	8b 10                	mov    (%eax),%edx
f0104c81:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0104c86:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0104c89:	8d 40 04             	lea    0x4(%eax),%eax
f0104c8c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104c8f:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0104c94:	83 ec 0c             	sub    $0xc,%esp
f0104c97:	0f be 5d cf          	movsbl -0x31(%ebp),%ebx
f0104c9b:	53                   	push   %ebx
f0104c9c:	ff 75 d4             	pushl  -0x2c(%ebp)
f0104c9f:	50                   	push   %eax
f0104ca0:	51                   	push   %ecx
f0104ca1:	52                   	push   %edx
f0104ca2:	89 fa                	mov    %edi,%edx
f0104ca4:	89 f0                	mov    %esi,%eax
f0104ca6:	e8 08 fb ff ff       	call   f01047b3 <printnum>
			break;
f0104cab:	83 c4 20             	add    $0x20,%esp
			if ((p = va_arg(ap, char *)) == NULL)
f0104cae:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104cb1:	83 c3 01             	add    $0x1,%ebx
f0104cb4:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0104cb8:	83 f8 25             	cmp    $0x25,%eax
f0104cbb:	0f 84 23 fc ff ff    	je     f01048e4 <vprintfmt+0x31>
			if (ch == '\0')
f0104cc1:	85 c0                	test   %eax,%eax
f0104cc3:	0f 84 97 00 00 00    	je     f0104d60 <.L20+0x23>
			putch(ch, putdat);
f0104cc9:	83 ec 08             	sub    $0x8,%esp
f0104ccc:	57                   	push   %edi
f0104ccd:	50                   	push   %eax
f0104cce:	ff d6                	call   *%esi
f0104cd0:	83 c4 10             	add    $0x10,%esp
f0104cd3:	eb dc                	jmp    f0104cb1 <.L25+0x48>

f0104cd5 <.L21>:
f0104cd5:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0104cd8:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f0104cdb:	83 f9 01             	cmp    $0x1,%ecx
f0104cde:	7f 1b                	jg     f0104cfb <.L21+0x26>
	else if (lflag)
f0104ce0:	85 c9                	test   %ecx,%ecx
f0104ce2:	74 2c                	je     f0104d10 <.L21+0x3b>
		return va_arg(*ap, unsigned long);
f0104ce4:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ce7:	8b 10                	mov    (%eax),%edx
f0104ce9:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104cee:	8d 40 04             	lea    0x4(%eax),%eax
f0104cf1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104cf4:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long);
f0104cf9:	eb 99                	jmp    f0104c94 <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f0104cfb:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cfe:	8b 10                	mov    (%eax),%edx
f0104d00:	8b 48 04             	mov    0x4(%eax),%ecx
f0104d03:	8d 40 08             	lea    0x8(%eax),%eax
f0104d06:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104d09:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long long);
f0104d0e:	eb 84                	jmp    f0104c94 <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f0104d10:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d13:	8b 10                	mov    (%eax),%edx
f0104d15:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104d1a:	8d 40 04             	lea    0x4(%eax),%eax
f0104d1d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104d20:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned int);
f0104d25:	e9 6a ff ff ff       	jmp    f0104c94 <.L25+0x2b>

f0104d2a <.L35>:
f0104d2a:	8b 75 08             	mov    0x8(%ebp),%esi
			putch(ch, putdat);
f0104d2d:	83 ec 08             	sub    $0x8,%esp
f0104d30:	57                   	push   %edi
f0104d31:	6a 25                	push   $0x25
f0104d33:	ff d6                	call   *%esi
			break;
f0104d35:	83 c4 10             	add    $0x10,%esp
f0104d38:	e9 71 ff ff ff       	jmp    f0104cae <.L25+0x45>

f0104d3d <.L20>:
f0104d3d:	8b 75 08             	mov    0x8(%ebp),%esi
			putch('%', putdat);
f0104d40:	83 ec 08             	sub    $0x8,%esp
f0104d43:	57                   	push   %edi
f0104d44:	6a 25                	push   $0x25
f0104d46:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104d48:	83 c4 10             	add    $0x10,%esp
f0104d4b:	89 d8                	mov    %ebx,%eax
f0104d4d:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0104d51:	74 05                	je     f0104d58 <.L20+0x1b>
f0104d53:	83 e8 01             	sub    $0x1,%eax
f0104d56:	eb f5                	jmp    f0104d4d <.L20+0x10>
f0104d58:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104d5b:	e9 4e ff ff ff       	jmp    f0104cae <.L25+0x45>
}
f0104d60:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104d63:	5b                   	pop    %ebx
f0104d64:	5e                   	pop    %esi
f0104d65:	5f                   	pop    %edi
f0104d66:	5d                   	pop    %ebp
f0104d67:	c3                   	ret    

f0104d68 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104d68:	f3 0f 1e fb          	endbr32 
f0104d6c:	55                   	push   %ebp
f0104d6d:	89 e5                	mov    %esp,%ebp
f0104d6f:	53                   	push   %ebx
f0104d70:	83 ec 14             	sub    $0x14,%esp
f0104d73:	e8 fb b3 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0104d78:	81 c3 a4 82 08 00    	add    $0x882a4,%ebx
f0104d7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d81:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104d84:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104d87:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104d8b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104d8e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104d95:	85 c0                	test   %eax,%eax
f0104d97:	74 2b                	je     f0104dc4 <vsnprintf+0x5c>
f0104d99:	85 d2                	test   %edx,%edx
f0104d9b:	7e 27                	jle    f0104dc4 <vsnprintf+0x5c>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104d9d:	ff 75 14             	pushl  0x14(%ebp)
f0104da0:	ff 75 10             	pushl  0x10(%ebp)
f0104da3:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104da6:	50                   	push   %eax
f0104da7:	8d 83 55 78 f7 ff    	lea    -0x887ab(%ebx),%eax
f0104dad:	50                   	push   %eax
f0104dae:	e8 00 fb ff ff       	call   f01048b3 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104db3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104db6:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104db9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104dbc:	83 c4 10             	add    $0x10,%esp
}
f0104dbf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104dc2:	c9                   	leave  
f0104dc3:	c3                   	ret    
		return -E_INVAL;
f0104dc4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104dc9:	eb f4                	jmp    f0104dbf <vsnprintf+0x57>

f0104dcb <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104dcb:	f3 0f 1e fb          	endbr32 
f0104dcf:	55                   	push   %ebp
f0104dd0:	89 e5                	mov    %esp,%ebp
f0104dd2:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104dd5:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104dd8:	50                   	push   %eax
f0104dd9:	ff 75 10             	pushl  0x10(%ebp)
f0104ddc:	ff 75 0c             	pushl  0xc(%ebp)
f0104ddf:	ff 75 08             	pushl  0x8(%ebp)
f0104de2:	e8 81 ff ff ff       	call   f0104d68 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104de7:	c9                   	leave  
f0104de8:	c3                   	ret    

f0104de9 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104de9:	f3 0f 1e fb          	endbr32 
f0104ded:	55                   	push   %ebp
f0104dee:	89 e5                	mov    %esp,%ebp
f0104df0:	57                   	push   %edi
f0104df1:	56                   	push   %esi
f0104df2:	53                   	push   %ebx
f0104df3:	83 ec 1c             	sub    $0x1c,%esp
f0104df6:	e8 78 b3 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0104dfb:	81 c3 21 82 08 00    	add    $0x88221,%ebx
f0104e01:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104e04:	85 c0                	test   %eax,%eax
f0104e06:	74 13                	je     f0104e1b <readline+0x32>
		cprintf("%s", prompt);
f0104e08:	83 ec 08             	sub    $0x8,%esp
f0104e0b:	50                   	push   %eax
f0104e0c:	8d 83 45 92 f7 ff    	lea    -0x86dbb(%ebx),%eax
f0104e12:	50                   	push   %eax
f0104e13:	e8 dd eb ff ff       	call   f01039f5 <cprintf>
f0104e18:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104e1b:	83 ec 0c             	sub    $0xc,%esp
f0104e1e:	6a 00                	push   $0x0
f0104e20:	e8 f8 b8 ff ff       	call   f010071d <iscons>
f0104e25:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104e28:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0104e2b:	bf 00 00 00 00       	mov    $0x0,%edi
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
			if (echoing)
				cputchar(c);
			buf[i++] = c;
f0104e30:	8d 83 e4 2b 00 00    	lea    0x2be4(%ebx),%eax
f0104e36:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104e39:	eb 51                	jmp    f0104e8c <readline+0xa3>
			cprintf("read error: %e\n", c);
f0104e3b:	83 ec 08             	sub    $0x8,%esp
f0104e3e:	50                   	push   %eax
f0104e3f:	8d 83 28 9c f7 ff    	lea    -0x863d8(%ebx),%eax
f0104e45:	50                   	push   %eax
f0104e46:	e8 aa eb ff ff       	call   f01039f5 <cprintf>
			return NULL;
f0104e4b:	83 c4 10             	add    $0x10,%esp
f0104e4e:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0104e53:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104e56:	5b                   	pop    %ebx
f0104e57:	5e                   	pop    %esi
f0104e58:	5f                   	pop    %edi
f0104e59:	5d                   	pop    %ebp
f0104e5a:	c3                   	ret    
			if (echoing)
f0104e5b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104e5f:	75 05                	jne    f0104e66 <readline+0x7d>
			i--;
f0104e61:	83 ef 01             	sub    $0x1,%edi
f0104e64:	eb 26                	jmp    f0104e8c <readline+0xa3>
				cputchar('\b');
f0104e66:	83 ec 0c             	sub    $0xc,%esp
f0104e69:	6a 08                	push   $0x8
f0104e6b:	e8 84 b8 ff ff       	call   f01006f4 <cputchar>
f0104e70:	83 c4 10             	add    $0x10,%esp
f0104e73:	eb ec                	jmp    f0104e61 <readline+0x78>
				cputchar(c);
f0104e75:	83 ec 0c             	sub    $0xc,%esp
f0104e78:	56                   	push   %esi
f0104e79:	e8 76 b8 ff ff       	call   f01006f4 <cputchar>
f0104e7e:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104e81:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104e84:	89 f0                	mov    %esi,%eax
f0104e86:	88 04 39             	mov    %al,(%ecx,%edi,1)
f0104e89:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0104e8c:	e8 77 b8 ff ff       	call   f0100708 <getchar>
f0104e91:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0104e93:	85 c0                	test   %eax,%eax
f0104e95:	78 a4                	js     f0104e3b <readline+0x52>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104e97:	83 f8 08             	cmp    $0x8,%eax
f0104e9a:	0f 94 c2             	sete   %dl
f0104e9d:	83 f8 7f             	cmp    $0x7f,%eax
f0104ea0:	0f 94 c0             	sete   %al
f0104ea3:	08 c2                	or     %al,%dl
f0104ea5:	74 04                	je     f0104eab <readline+0xc2>
f0104ea7:	85 ff                	test   %edi,%edi
f0104ea9:	7f b0                	jg     f0104e5b <readline+0x72>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104eab:	83 fe 1f             	cmp    $0x1f,%esi
f0104eae:	7e 10                	jle    f0104ec0 <readline+0xd7>
f0104eb0:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0104eb6:	7f 08                	jg     f0104ec0 <readline+0xd7>
			if (echoing)
f0104eb8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104ebc:	74 c3                	je     f0104e81 <readline+0x98>
f0104ebe:	eb b5                	jmp    f0104e75 <readline+0x8c>
		} else if (c == '\n' || c == '\r') {
f0104ec0:	83 fe 0a             	cmp    $0xa,%esi
f0104ec3:	74 05                	je     f0104eca <readline+0xe1>
f0104ec5:	83 fe 0d             	cmp    $0xd,%esi
f0104ec8:	75 c2                	jne    f0104e8c <readline+0xa3>
			if (echoing)
f0104eca:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104ece:	75 13                	jne    f0104ee3 <readline+0xfa>
			buf[i] = 0;
f0104ed0:	c6 84 3b e4 2b 00 00 	movb   $0x0,0x2be4(%ebx,%edi,1)
f0104ed7:	00 
			return buf;
f0104ed8:	8d 83 e4 2b 00 00    	lea    0x2be4(%ebx),%eax
f0104ede:	e9 70 ff ff ff       	jmp    f0104e53 <readline+0x6a>
				cputchar('\n');
f0104ee3:	83 ec 0c             	sub    $0xc,%esp
f0104ee6:	6a 0a                	push   $0xa
f0104ee8:	e8 07 b8 ff ff       	call   f01006f4 <cputchar>
f0104eed:	83 c4 10             	add    $0x10,%esp
f0104ef0:	eb de                	jmp    f0104ed0 <readline+0xe7>

f0104ef2 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104ef2:	f3 0f 1e fb          	endbr32 
f0104ef6:	55                   	push   %ebp
f0104ef7:	89 e5                	mov    %esp,%ebp
f0104ef9:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104efc:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f01:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104f05:	74 05                	je     f0104f0c <strlen+0x1a>
		n++;
f0104f07:	83 c0 01             	add    $0x1,%eax
f0104f0a:	eb f5                	jmp    f0104f01 <strlen+0xf>
	return n;
}
f0104f0c:	5d                   	pop    %ebp
f0104f0d:	c3                   	ret    

f0104f0e <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104f0e:	f3 0f 1e fb          	endbr32 
f0104f12:	55                   	push   %ebp
f0104f13:	89 e5                	mov    %esp,%ebp
f0104f15:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104f18:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104f1b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f20:	39 d0                	cmp    %edx,%eax
f0104f22:	74 0d                	je     f0104f31 <strnlen+0x23>
f0104f24:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104f28:	74 05                	je     f0104f2f <strnlen+0x21>
		n++;
f0104f2a:	83 c0 01             	add    $0x1,%eax
f0104f2d:	eb f1                	jmp    f0104f20 <strnlen+0x12>
f0104f2f:	89 c2                	mov    %eax,%edx
	return n;
}
f0104f31:	89 d0                	mov    %edx,%eax
f0104f33:	5d                   	pop    %ebp
f0104f34:	c3                   	ret    

f0104f35 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104f35:	f3 0f 1e fb          	endbr32 
f0104f39:	55                   	push   %ebp
f0104f3a:	89 e5                	mov    %esp,%ebp
f0104f3c:	53                   	push   %ebx
f0104f3d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104f40:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104f43:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f48:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f0104f4c:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f0104f4f:	83 c0 01             	add    $0x1,%eax
f0104f52:	84 d2                	test   %dl,%dl
f0104f54:	75 f2                	jne    f0104f48 <strcpy+0x13>
		/* do nothing */;
	return ret;
}
f0104f56:	89 c8                	mov    %ecx,%eax
f0104f58:	5b                   	pop    %ebx
f0104f59:	5d                   	pop    %ebp
f0104f5a:	c3                   	ret    

f0104f5b <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104f5b:	f3 0f 1e fb          	endbr32 
f0104f5f:	55                   	push   %ebp
f0104f60:	89 e5                	mov    %esp,%ebp
f0104f62:	53                   	push   %ebx
f0104f63:	83 ec 10             	sub    $0x10,%esp
f0104f66:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104f69:	53                   	push   %ebx
f0104f6a:	e8 83 ff ff ff       	call   f0104ef2 <strlen>
f0104f6f:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f0104f72:	ff 75 0c             	pushl  0xc(%ebp)
f0104f75:	01 d8                	add    %ebx,%eax
f0104f77:	50                   	push   %eax
f0104f78:	e8 b8 ff ff ff       	call   f0104f35 <strcpy>
	return dst;
}
f0104f7d:	89 d8                	mov    %ebx,%eax
f0104f7f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104f82:	c9                   	leave  
f0104f83:	c3                   	ret    

f0104f84 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104f84:	f3 0f 1e fb          	endbr32 
f0104f88:	55                   	push   %ebp
f0104f89:	89 e5                	mov    %esp,%ebp
f0104f8b:	56                   	push   %esi
f0104f8c:	53                   	push   %ebx
f0104f8d:	8b 75 08             	mov    0x8(%ebp),%esi
f0104f90:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104f93:	89 f3                	mov    %esi,%ebx
f0104f95:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104f98:	89 f0                	mov    %esi,%eax
f0104f9a:	39 d8                	cmp    %ebx,%eax
f0104f9c:	74 11                	je     f0104faf <strncpy+0x2b>
		*dst++ = *src;
f0104f9e:	83 c0 01             	add    $0x1,%eax
f0104fa1:	0f b6 0a             	movzbl (%edx),%ecx
f0104fa4:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104fa7:	80 f9 01             	cmp    $0x1,%cl
f0104faa:	83 da ff             	sbb    $0xffffffff,%edx
f0104fad:	eb eb                	jmp    f0104f9a <strncpy+0x16>
	}
	return ret;
}
f0104faf:	89 f0                	mov    %esi,%eax
f0104fb1:	5b                   	pop    %ebx
f0104fb2:	5e                   	pop    %esi
f0104fb3:	5d                   	pop    %ebp
f0104fb4:	c3                   	ret    

f0104fb5 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104fb5:	f3 0f 1e fb          	endbr32 
f0104fb9:	55                   	push   %ebp
f0104fba:	89 e5                	mov    %esp,%ebp
f0104fbc:	56                   	push   %esi
f0104fbd:	53                   	push   %ebx
f0104fbe:	8b 75 08             	mov    0x8(%ebp),%esi
f0104fc1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104fc4:	8b 55 10             	mov    0x10(%ebp),%edx
f0104fc7:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104fc9:	85 d2                	test   %edx,%edx
f0104fcb:	74 21                	je     f0104fee <strlcpy+0x39>
f0104fcd:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104fd1:	89 f2                	mov    %esi,%edx
		while (--size > 0 && *src != '\0')
f0104fd3:	39 c2                	cmp    %eax,%edx
f0104fd5:	74 14                	je     f0104feb <strlcpy+0x36>
f0104fd7:	0f b6 19             	movzbl (%ecx),%ebx
f0104fda:	84 db                	test   %bl,%bl
f0104fdc:	74 0b                	je     f0104fe9 <strlcpy+0x34>
			*dst++ = *src++;
f0104fde:	83 c1 01             	add    $0x1,%ecx
f0104fe1:	83 c2 01             	add    $0x1,%edx
f0104fe4:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104fe7:	eb ea                	jmp    f0104fd3 <strlcpy+0x1e>
f0104fe9:	89 d0                	mov    %edx,%eax
		*dst = '\0';
f0104feb:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104fee:	29 f0                	sub    %esi,%eax
}
f0104ff0:	5b                   	pop    %ebx
f0104ff1:	5e                   	pop    %esi
f0104ff2:	5d                   	pop    %ebp
f0104ff3:	c3                   	ret    

f0104ff4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104ff4:	f3 0f 1e fb          	endbr32 
f0104ff8:	55                   	push   %ebp
f0104ff9:	89 e5                	mov    %esp,%ebp
f0104ffb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104ffe:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105001:	0f b6 01             	movzbl (%ecx),%eax
f0105004:	84 c0                	test   %al,%al
f0105006:	74 0c                	je     f0105014 <strcmp+0x20>
f0105008:	3a 02                	cmp    (%edx),%al
f010500a:	75 08                	jne    f0105014 <strcmp+0x20>
		p++, q++;
f010500c:	83 c1 01             	add    $0x1,%ecx
f010500f:	83 c2 01             	add    $0x1,%edx
f0105012:	eb ed                	jmp    f0105001 <strcmp+0xd>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105014:	0f b6 c0             	movzbl %al,%eax
f0105017:	0f b6 12             	movzbl (%edx),%edx
f010501a:	29 d0                	sub    %edx,%eax
}
f010501c:	5d                   	pop    %ebp
f010501d:	c3                   	ret    

f010501e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010501e:	f3 0f 1e fb          	endbr32 
f0105022:	55                   	push   %ebp
f0105023:	89 e5                	mov    %esp,%ebp
f0105025:	53                   	push   %ebx
f0105026:	8b 45 08             	mov    0x8(%ebp),%eax
f0105029:	8b 55 0c             	mov    0xc(%ebp),%edx
f010502c:	89 c3                	mov    %eax,%ebx
f010502e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0105031:	eb 06                	jmp    f0105039 <strncmp+0x1b>
		n--, p++, q++;
f0105033:	83 c0 01             	add    $0x1,%eax
f0105036:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0105039:	39 d8                	cmp    %ebx,%eax
f010503b:	74 16                	je     f0105053 <strncmp+0x35>
f010503d:	0f b6 08             	movzbl (%eax),%ecx
f0105040:	84 c9                	test   %cl,%cl
f0105042:	74 04                	je     f0105048 <strncmp+0x2a>
f0105044:	3a 0a                	cmp    (%edx),%cl
f0105046:	74 eb                	je     f0105033 <strncmp+0x15>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105048:	0f b6 00             	movzbl (%eax),%eax
f010504b:	0f b6 12             	movzbl (%edx),%edx
f010504e:	29 d0                	sub    %edx,%eax
}
f0105050:	5b                   	pop    %ebx
f0105051:	5d                   	pop    %ebp
f0105052:	c3                   	ret    
		return 0;
f0105053:	b8 00 00 00 00       	mov    $0x0,%eax
f0105058:	eb f6                	jmp    f0105050 <strncmp+0x32>

f010505a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010505a:	f3 0f 1e fb          	endbr32 
f010505e:	55                   	push   %ebp
f010505f:	89 e5                	mov    %esp,%ebp
f0105061:	8b 45 08             	mov    0x8(%ebp),%eax
f0105064:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105068:	0f b6 10             	movzbl (%eax),%edx
f010506b:	84 d2                	test   %dl,%dl
f010506d:	74 09                	je     f0105078 <strchr+0x1e>
		if (*s == c)
f010506f:	38 ca                	cmp    %cl,%dl
f0105071:	74 0a                	je     f010507d <strchr+0x23>
	for (; *s; s++)
f0105073:	83 c0 01             	add    $0x1,%eax
f0105076:	eb f0                	jmp    f0105068 <strchr+0xe>
			return (char *) s;
	return 0;
f0105078:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010507d:	5d                   	pop    %ebp
f010507e:	c3                   	ret    

f010507f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010507f:	f3 0f 1e fb          	endbr32 
f0105083:	55                   	push   %ebp
f0105084:	89 e5                	mov    %esp,%ebp
f0105086:	8b 45 08             	mov    0x8(%ebp),%eax
f0105089:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010508d:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0105090:	38 ca                	cmp    %cl,%dl
f0105092:	74 09                	je     f010509d <strfind+0x1e>
f0105094:	84 d2                	test   %dl,%dl
f0105096:	74 05                	je     f010509d <strfind+0x1e>
	for (; *s; s++)
f0105098:	83 c0 01             	add    $0x1,%eax
f010509b:	eb f0                	jmp    f010508d <strfind+0xe>
			break;
	return (char *) s;
}
f010509d:	5d                   	pop    %ebp
f010509e:	c3                   	ret    

f010509f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010509f:	f3 0f 1e fb          	endbr32 
f01050a3:	55                   	push   %ebp
f01050a4:	89 e5                	mov    %esp,%ebp
f01050a6:	57                   	push   %edi
f01050a7:	56                   	push   %esi
f01050a8:	53                   	push   %ebx
f01050a9:	8b 7d 08             	mov    0x8(%ebp),%edi
f01050ac:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01050af:	85 c9                	test   %ecx,%ecx
f01050b1:	74 31                	je     f01050e4 <memset+0x45>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01050b3:	89 f8                	mov    %edi,%eax
f01050b5:	09 c8                	or     %ecx,%eax
f01050b7:	a8 03                	test   $0x3,%al
f01050b9:	75 23                	jne    f01050de <memset+0x3f>
		c &= 0xFF;
f01050bb:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01050bf:	89 d3                	mov    %edx,%ebx
f01050c1:	c1 e3 08             	shl    $0x8,%ebx
f01050c4:	89 d0                	mov    %edx,%eax
f01050c6:	c1 e0 18             	shl    $0x18,%eax
f01050c9:	89 d6                	mov    %edx,%esi
f01050cb:	c1 e6 10             	shl    $0x10,%esi
f01050ce:	09 f0                	or     %esi,%eax
f01050d0:	09 c2                	or     %eax,%edx
f01050d2:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01050d4:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f01050d7:	89 d0                	mov    %edx,%eax
f01050d9:	fc                   	cld    
f01050da:	f3 ab                	rep stos %eax,%es:(%edi)
f01050dc:	eb 06                	jmp    f01050e4 <memset+0x45>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01050de:	8b 45 0c             	mov    0xc(%ebp),%eax
f01050e1:	fc                   	cld    
f01050e2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01050e4:	89 f8                	mov    %edi,%eax
f01050e6:	5b                   	pop    %ebx
f01050e7:	5e                   	pop    %esi
f01050e8:	5f                   	pop    %edi
f01050e9:	5d                   	pop    %ebp
f01050ea:	c3                   	ret    

f01050eb <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01050eb:	f3 0f 1e fb          	endbr32 
f01050ef:	55                   	push   %ebp
f01050f0:	89 e5                	mov    %esp,%ebp
f01050f2:	57                   	push   %edi
f01050f3:	56                   	push   %esi
f01050f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01050f7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01050fa:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01050fd:	39 c6                	cmp    %eax,%esi
f01050ff:	73 32                	jae    f0105133 <memmove+0x48>
f0105101:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105104:	39 c2                	cmp    %eax,%edx
f0105106:	76 2b                	jbe    f0105133 <memmove+0x48>
		s += n;
		d += n;
f0105108:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010510b:	89 fe                	mov    %edi,%esi
f010510d:	09 ce                	or     %ecx,%esi
f010510f:	09 d6                	or     %edx,%esi
f0105111:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105117:	75 0e                	jne    f0105127 <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0105119:	83 ef 04             	sub    $0x4,%edi
f010511c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010511f:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0105122:	fd                   	std    
f0105123:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105125:	eb 09                	jmp    f0105130 <memmove+0x45>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0105127:	83 ef 01             	sub    $0x1,%edi
f010512a:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f010512d:	fd                   	std    
f010512e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105130:	fc                   	cld    
f0105131:	eb 1a                	jmp    f010514d <memmove+0x62>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105133:	89 c2                	mov    %eax,%edx
f0105135:	09 ca                	or     %ecx,%edx
f0105137:	09 f2                	or     %esi,%edx
f0105139:	f6 c2 03             	test   $0x3,%dl
f010513c:	75 0a                	jne    f0105148 <memmove+0x5d>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010513e:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0105141:	89 c7                	mov    %eax,%edi
f0105143:	fc                   	cld    
f0105144:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105146:	eb 05                	jmp    f010514d <memmove+0x62>
		else
			asm volatile("cld; rep movsb\n"
f0105148:	89 c7                	mov    %eax,%edi
f010514a:	fc                   	cld    
f010514b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010514d:	5e                   	pop    %esi
f010514e:	5f                   	pop    %edi
f010514f:	5d                   	pop    %ebp
f0105150:	c3                   	ret    

f0105151 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105151:	f3 0f 1e fb          	endbr32 
f0105155:	55                   	push   %ebp
f0105156:	89 e5                	mov    %esp,%ebp
f0105158:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010515b:	ff 75 10             	pushl  0x10(%ebp)
f010515e:	ff 75 0c             	pushl  0xc(%ebp)
f0105161:	ff 75 08             	pushl  0x8(%ebp)
f0105164:	e8 82 ff ff ff       	call   f01050eb <memmove>
}
f0105169:	c9                   	leave  
f010516a:	c3                   	ret    

f010516b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010516b:	f3 0f 1e fb          	endbr32 
f010516f:	55                   	push   %ebp
f0105170:	89 e5                	mov    %esp,%ebp
f0105172:	56                   	push   %esi
f0105173:	53                   	push   %ebx
f0105174:	8b 45 08             	mov    0x8(%ebp),%eax
f0105177:	8b 55 0c             	mov    0xc(%ebp),%edx
f010517a:	89 c6                	mov    %eax,%esi
f010517c:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010517f:	39 f0                	cmp    %esi,%eax
f0105181:	74 1c                	je     f010519f <memcmp+0x34>
		if (*s1 != *s2)
f0105183:	0f b6 08             	movzbl (%eax),%ecx
f0105186:	0f b6 1a             	movzbl (%edx),%ebx
f0105189:	38 d9                	cmp    %bl,%cl
f010518b:	75 08                	jne    f0105195 <memcmp+0x2a>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f010518d:	83 c0 01             	add    $0x1,%eax
f0105190:	83 c2 01             	add    $0x1,%edx
f0105193:	eb ea                	jmp    f010517f <memcmp+0x14>
			return (int) *s1 - (int) *s2;
f0105195:	0f b6 c1             	movzbl %cl,%eax
f0105198:	0f b6 db             	movzbl %bl,%ebx
f010519b:	29 d8                	sub    %ebx,%eax
f010519d:	eb 05                	jmp    f01051a4 <memcmp+0x39>
	}

	return 0;
f010519f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01051a4:	5b                   	pop    %ebx
f01051a5:	5e                   	pop    %esi
f01051a6:	5d                   	pop    %ebp
f01051a7:	c3                   	ret    

f01051a8 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01051a8:	f3 0f 1e fb          	endbr32 
f01051ac:	55                   	push   %ebp
f01051ad:	89 e5                	mov    %esp,%ebp
f01051af:	8b 45 08             	mov    0x8(%ebp),%eax
f01051b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01051b5:	89 c2                	mov    %eax,%edx
f01051b7:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01051ba:	39 d0                	cmp    %edx,%eax
f01051bc:	73 09                	jae    f01051c7 <memfind+0x1f>
		if (*(const unsigned char *) s == (unsigned char) c)
f01051be:	38 08                	cmp    %cl,(%eax)
f01051c0:	74 05                	je     f01051c7 <memfind+0x1f>
	for (; s < ends; s++)
f01051c2:	83 c0 01             	add    $0x1,%eax
f01051c5:	eb f3                	jmp    f01051ba <memfind+0x12>
			break;
	return (void *) s;
}
f01051c7:	5d                   	pop    %ebp
f01051c8:	c3                   	ret    

f01051c9 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01051c9:	f3 0f 1e fb          	endbr32 
f01051cd:	55                   	push   %ebp
f01051ce:	89 e5                	mov    %esp,%ebp
f01051d0:	57                   	push   %edi
f01051d1:	56                   	push   %esi
f01051d2:	53                   	push   %ebx
f01051d3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01051d6:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01051d9:	eb 03                	jmp    f01051de <strtol+0x15>
		s++;
f01051db:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01051de:	0f b6 01             	movzbl (%ecx),%eax
f01051e1:	3c 20                	cmp    $0x20,%al
f01051e3:	74 f6                	je     f01051db <strtol+0x12>
f01051e5:	3c 09                	cmp    $0x9,%al
f01051e7:	74 f2                	je     f01051db <strtol+0x12>

	// plus/minus sign
	if (*s == '+')
f01051e9:	3c 2b                	cmp    $0x2b,%al
f01051eb:	74 2a                	je     f0105217 <strtol+0x4e>
	int neg = 0;
f01051ed:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01051f2:	3c 2d                	cmp    $0x2d,%al
f01051f4:	74 2b                	je     f0105221 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01051f6:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01051fc:	75 0f                	jne    f010520d <strtol+0x44>
f01051fe:	80 39 30             	cmpb   $0x30,(%ecx)
f0105201:	74 28                	je     f010522b <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105203:	85 db                	test   %ebx,%ebx
f0105205:	b8 0a 00 00 00       	mov    $0xa,%eax
f010520a:	0f 44 d8             	cmove  %eax,%ebx
f010520d:	b8 00 00 00 00       	mov    $0x0,%eax
f0105212:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105215:	eb 46                	jmp    f010525d <strtol+0x94>
		s++;
f0105217:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f010521a:	bf 00 00 00 00       	mov    $0x0,%edi
f010521f:	eb d5                	jmp    f01051f6 <strtol+0x2d>
		s++, neg = 1;
f0105221:	83 c1 01             	add    $0x1,%ecx
f0105224:	bf 01 00 00 00       	mov    $0x1,%edi
f0105229:	eb cb                	jmp    f01051f6 <strtol+0x2d>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010522b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010522f:	74 0e                	je     f010523f <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0105231:	85 db                	test   %ebx,%ebx
f0105233:	75 d8                	jne    f010520d <strtol+0x44>
		s++, base = 8;
f0105235:	83 c1 01             	add    $0x1,%ecx
f0105238:	bb 08 00 00 00       	mov    $0x8,%ebx
f010523d:	eb ce                	jmp    f010520d <strtol+0x44>
		s += 2, base = 16;
f010523f:	83 c1 02             	add    $0x2,%ecx
f0105242:	bb 10 00 00 00       	mov    $0x10,%ebx
f0105247:	eb c4                	jmp    f010520d <strtol+0x44>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f0105249:	0f be d2             	movsbl %dl,%edx
f010524c:	83 ea 30             	sub    $0x30,%edx
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010524f:	3b 55 10             	cmp    0x10(%ebp),%edx
f0105252:	7d 3a                	jge    f010528e <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0105254:	83 c1 01             	add    $0x1,%ecx
f0105257:	0f af 45 10          	imul   0x10(%ebp),%eax
f010525b:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f010525d:	0f b6 11             	movzbl (%ecx),%edx
f0105260:	8d 72 d0             	lea    -0x30(%edx),%esi
f0105263:	89 f3                	mov    %esi,%ebx
f0105265:	80 fb 09             	cmp    $0x9,%bl
f0105268:	76 df                	jbe    f0105249 <strtol+0x80>
		else if (*s >= 'a' && *s <= 'z')
f010526a:	8d 72 9f             	lea    -0x61(%edx),%esi
f010526d:	89 f3                	mov    %esi,%ebx
f010526f:	80 fb 19             	cmp    $0x19,%bl
f0105272:	77 08                	ja     f010527c <strtol+0xb3>
			dig = *s - 'a' + 10;
f0105274:	0f be d2             	movsbl %dl,%edx
f0105277:	83 ea 57             	sub    $0x57,%edx
f010527a:	eb d3                	jmp    f010524f <strtol+0x86>
		else if (*s >= 'A' && *s <= 'Z')
f010527c:	8d 72 bf             	lea    -0x41(%edx),%esi
f010527f:	89 f3                	mov    %esi,%ebx
f0105281:	80 fb 19             	cmp    $0x19,%bl
f0105284:	77 08                	ja     f010528e <strtol+0xc5>
			dig = *s - 'A' + 10;
f0105286:	0f be d2             	movsbl %dl,%edx
f0105289:	83 ea 37             	sub    $0x37,%edx
f010528c:	eb c1                	jmp    f010524f <strtol+0x86>
		// we don't properly detect overflow!
	}

	if (endptr)
f010528e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105292:	74 05                	je     f0105299 <strtol+0xd0>
		*endptr = (char *) s;
f0105294:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105297:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0105299:	89 c2                	mov    %eax,%edx
f010529b:	f7 da                	neg    %edx
f010529d:	85 ff                	test   %edi,%edi
f010529f:	0f 45 c2             	cmovne %edx,%eax
}
f01052a2:	5b                   	pop    %ebx
f01052a3:	5e                   	pop    %esi
f01052a4:	5f                   	pop    %edi
f01052a5:	5d                   	pop    %ebp
f01052a6:	c3                   	ret    
f01052a7:	66 90                	xchg   %ax,%ax
f01052a9:	66 90                	xchg   %ax,%ax
f01052ab:	66 90                	xchg   %ax,%ax
f01052ad:	66 90                	xchg   %ax,%ax
f01052af:	90                   	nop

f01052b0 <__udivdi3>:
f01052b0:	f3 0f 1e fb          	endbr32 
f01052b4:	55                   	push   %ebp
f01052b5:	57                   	push   %edi
f01052b6:	56                   	push   %esi
f01052b7:	53                   	push   %ebx
f01052b8:	83 ec 1c             	sub    $0x1c,%esp
f01052bb:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01052bf:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01052c3:	8b 74 24 34          	mov    0x34(%esp),%esi
f01052c7:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01052cb:	85 d2                	test   %edx,%edx
f01052cd:	75 19                	jne    f01052e8 <__udivdi3+0x38>
f01052cf:	39 f3                	cmp    %esi,%ebx
f01052d1:	76 4d                	jbe    f0105320 <__udivdi3+0x70>
f01052d3:	31 ff                	xor    %edi,%edi
f01052d5:	89 e8                	mov    %ebp,%eax
f01052d7:	89 f2                	mov    %esi,%edx
f01052d9:	f7 f3                	div    %ebx
f01052db:	89 fa                	mov    %edi,%edx
f01052dd:	83 c4 1c             	add    $0x1c,%esp
f01052e0:	5b                   	pop    %ebx
f01052e1:	5e                   	pop    %esi
f01052e2:	5f                   	pop    %edi
f01052e3:	5d                   	pop    %ebp
f01052e4:	c3                   	ret    
f01052e5:	8d 76 00             	lea    0x0(%esi),%esi
f01052e8:	39 f2                	cmp    %esi,%edx
f01052ea:	76 14                	jbe    f0105300 <__udivdi3+0x50>
f01052ec:	31 ff                	xor    %edi,%edi
f01052ee:	31 c0                	xor    %eax,%eax
f01052f0:	89 fa                	mov    %edi,%edx
f01052f2:	83 c4 1c             	add    $0x1c,%esp
f01052f5:	5b                   	pop    %ebx
f01052f6:	5e                   	pop    %esi
f01052f7:	5f                   	pop    %edi
f01052f8:	5d                   	pop    %ebp
f01052f9:	c3                   	ret    
f01052fa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105300:	0f bd fa             	bsr    %edx,%edi
f0105303:	83 f7 1f             	xor    $0x1f,%edi
f0105306:	75 48                	jne    f0105350 <__udivdi3+0xa0>
f0105308:	39 f2                	cmp    %esi,%edx
f010530a:	72 06                	jb     f0105312 <__udivdi3+0x62>
f010530c:	31 c0                	xor    %eax,%eax
f010530e:	39 eb                	cmp    %ebp,%ebx
f0105310:	77 de                	ja     f01052f0 <__udivdi3+0x40>
f0105312:	b8 01 00 00 00       	mov    $0x1,%eax
f0105317:	eb d7                	jmp    f01052f0 <__udivdi3+0x40>
f0105319:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105320:	89 d9                	mov    %ebx,%ecx
f0105322:	85 db                	test   %ebx,%ebx
f0105324:	75 0b                	jne    f0105331 <__udivdi3+0x81>
f0105326:	b8 01 00 00 00       	mov    $0x1,%eax
f010532b:	31 d2                	xor    %edx,%edx
f010532d:	f7 f3                	div    %ebx
f010532f:	89 c1                	mov    %eax,%ecx
f0105331:	31 d2                	xor    %edx,%edx
f0105333:	89 f0                	mov    %esi,%eax
f0105335:	f7 f1                	div    %ecx
f0105337:	89 c6                	mov    %eax,%esi
f0105339:	89 e8                	mov    %ebp,%eax
f010533b:	89 f7                	mov    %esi,%edi
f010533d:	f7 f1                	div    %ecx
f010533f:	89 fa                	mov    %edi,%edx
f0105341:	83 c4 1c             	add    $0x1c,%esp
f0105344:	5b                   	pop    %ebx
f0105345:	5e                   	pop    %esi
f0105346:	5f                   	pop    %edi
f0105347:	5d                   	pop    %ebp
f0105348:	c3                   	ret    
f0105349:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105350:	89 f9                	mov    %edi,%ecx
f0105352:	b8 20 00 00 00       	mov    $0x20,%eax
f0105357:	29 f8                	sub    %edi,%eax
f0105359:	d3 e2                	shl    %cl,%edx
f010535b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010535f:	89 c1                	mov    %eax,%ecx
f0105361:	89 da                	mov    %ebx,%edx
f0105363:	d3 ea                	shr    %cl,%edx
f0105365:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0105369:	09 d1                	or     %edx,%ecx
f010536b:	89 f2                	mov    %esi,%edx
f010536d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105371:	89 f9                	mov    %edi,%ecx
f0105373:	d3 e3                	shl    %cl,%ebx
f0105375:	89 c1                	mov    %eax,%ecx
f0105377:	d3 ea                	shr    %cl,%edx
f0105379:	89 f9                	mov    %edi,%ecx
f010537b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010537f:	89 eb                	mov    %ebp,%ebx
f0105381:	d3 e6                	shl    %cl,%esi
f0105383:	89 c1                	mov    %eax,%ecx
f0105385:	d3 eb                	shr    %cl,%ebx
f0105387:	09 de                	or     %ebx,%esi
f0105389:	89 f0                	mov    %esi,%eax
f010538b:	f7 74 24 08          	divl   0x8(%esp)
f010538f:	89 d6                	mov    %edx,%esi
f0105391:	89 c3                	mov    %eax,%ebx
f0105393:	f7 64 24 0c          	mull   0xc(%esp)
f0105397:	39 d6                	cmp    %edx,%esi
f0105399:	72 15                	jb     f01053b0 <__udivdi3+0x100>
f010539b:	89 f9                	mov    %edi,%ecx
f010539d:	d3 e5                	shl    %cl,%ebp
f010539f:	39 c5                	cmp    %eax,%ebp
f01053a1:	73 04                	jae    f01053a7 <__udivdi3+0xf7>
f01053a3:	39 d6                	cmp    %edx,%esi
f01053a5:	74 09                	je     f01053b0 <__udivdi3+0x100>
f01053a7:	89 d8                	mov    %ebx,%eax
f01053a9:	31 ff                	xor    %edi,%edi
f01053ab:	e9 40 ff ff ff       	jmp    f01052f0 <__udivdi3+0x40>
f01053b0:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01053b3:	31 ff                	xor    %edi,%edi
f01053b5:	e9 36 ff ff ff       	jmp    f01052f0 <__udivdi3+0x40>
f01053ba:	66 90                	xchg   %ax,%ax
f01053bc:	66 90                	xchg   %ax,%ax
f01053be:	66 90                	xchg   %ax,%ax

f01053c0 <__umoddi3>:
f01053c0:	f3 0f 1e fb          	endbr32 
f01053c4:	55                   	push   %ebp
f01053c5:	57                   	push   %edi
f01053c6:	56                   	push   %esi
f01053c7:	53                   	push   %ebx
f01053c8:	83 ec 1c             	sub    $0x1c,%esp
f01053cb:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f01053cf:	8b 74 24 30          	mov    0x30(%esp),%esi
f01053d3:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f01053d7:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01053db:	85 c0                	test   %eax,%eax
f01053dd:	75 19                	jne    f01053f8 <__umoddi3+0x38>
f01053df:	39 df                	cmp    %ebx,%edi
f01053e1:	76 5d                	jbe    f0105440 <__umoddi3+0x80>
f01053e3:	89 f0                	mov    %esi,%eax
f01053e5:	89 da                	mov    %ebx,%edx
f01053e7:	f7 f7                	div    %edi
f01053e9:	89 d0                	mov    %edx,%eax
f01053eb:	31 d2                	xor    %edx,%edx
f01053ed:	83 c4 1c             	add    $0x1c,%esp
f01053f0:	5b                   	pop    %ebx
f01053f1:	5e                   	pop    %esi
f01053f2:	5f                   	pop    %edi
f01053f3:	5d                   	pop    %ebp
f01053f4:	c3                   	ret    
f01053f5:	8d 76 00             	lea    0x0(%esi),%esi
f01053f8:	89 f2                	mov    %esi,%edx
f01053fa:	39 d8                	cmp    %ebx,%eax
f01053fc:	76 12                	jbe    f0105410 <__umoddi3+0x50>
f01053fe:	89 f0                	mov    %esi,%eax
f0105400:	89 da                	mov    %ebx,%edx
f0105402:	83 c4 1c             	add    $0x1c,%esp
f0105405:	5b                   	pop    %ebx
f0105406:	5e                   	pop    %esi
f0105407:	5f                   	pop    %edi
f0105408:	5d                   	pop    %ebp
f0105409:	c3                   	ret    
f010540a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105410:	0f bd e8             	bsr    %eax,%ebp
f0105413:	83 f5 1f             	xor    $0x1f,%ebp
f0105416:	75 50                	jne    f0105468 <__umoddi3+0xa8>
f0105418:	39 d8                	cmp    %ebx,%eax
f010541a:	0f 82 e0 00 00 00    	jb     f0105500 <__umoddi3+0x140>
f0105420:	89 d9                	mov    %ebx,%ecx
f0105422:	39 f7                	cmp    %esi,%edi
f0105424:	0f 86 d6 00 00 00    	jbe    f0105500 <__umoddi3+0x140>
f010542a:	89 d0                	mov    %edx,%eax
f010542c:	89 ca                	mov    %ecx,%edx
f010542e:	83 c4 1c             	add    $0x1c,%esp
f0105431:	5b                   	pop    %ebx
f0105432:	5e                   	pop    %esi
f0105433:	5f                   	pop    %edi
f0105434:	5d                   	pop    %ebp
f0105435:	c3                   	ret    
f0105436:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f010543d:	8d 76 00             	lea    0x0(%esi),%esi
f0105440:	89 fd                	mov    %edi,%ebp
f0105442:	85 ff                	test   %edi,%edi
f0105444:	75 0b                	jne    f0105451 <__umoddi3+0x91>
f0105446:	b8 01 00 00 00       	mov    $0x1,%eax
f010544b:	31 d2                	xor    %edx,%edx
f010544d:	f7 f7                	div    %edi
f010544f:	89 c5                	mov    %eax,%ebp
f0105451:	89 d8                	mov    %ebx,%eax
f0105453:	31 d2                	xor    %edx,%edx
f0105455:	f7 f5                	div    %ebp
f0105457:	89 f0                	mov    %esi,%eax
f0105459:	f7 f5                	div    %ebp
f010545b:	89 d0                	mov    %edx,%eax
f010545d:	31 d2                	xor    %edx,%edx
f010545f:	eb 8c                	jmp    f01053ed <__umoddi3+0x2d>
f0105461:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105468:	89 e9                	mov    %ebp,%ecx
f010546a:	ba 20 00 00 00       	mov    $0x20,%edx
f010546f:	29 ea                	sub    %ebp,%edx
f0105471:	d3 e0                	shl    %cl,%eax
f0105473:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105477:	89 d1                	mov    %edx,%ecx
f0105479:	89 f8                	mov    %edi,%eax
f010547b:	d3 e8                	shr    %cl,%eax
f010547d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0105481:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105485:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105489:	09 c1                	or     %eax,%ecx
f010548b:	89 d8                	mov    %ebx,%eax
f010548d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105491:	89 e9                	mov    %ebp,%ecx
f0105493:	d3 e7                	shl    %cl,%edi
f0105495:	89 d1                	mov    %edx,%ecx
f0105497:	d3 e8                	shr    %cl,%eax
f0105499:	89 e9                	mov    %ebp,%ecx
f010549b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010549f:	d3 e3                	shl    %cl,%ebx
f01054a1:	89 c7                	mov    %eax,%edi
f01054a3:	89 d1                	mov    %edx,%ecx
f01054a5:	89 f0                	mov    %esi,%eax
f01054a7:	d3 e8                	shr    %cl,%eax
f01054a9:	89 e9                	mov    %ebp,%ecx
f01054ab:	89 fa                	mov    %edi,%edx
f01054ad:	d3 e6                	shl    %cl,%esi
f01054af:	09 d8                	or     %ebx,%eax
f01054b1:	f7 74 24 08          	divl   0x8(%esp)
f01054b5:	89 d1                	mov    %edx,%ecx
f01054b7:	89 f3                	mov    %esi,%ebx
f01054b9:	f7 64 24 0c          	mull   0xc(%esp)
f01054bd:	89 c6                	mov    %eax,%esi
f01054bf:	89 d7                	mov    %edx,%edi
f01054c1:	39 d1                	cmp    %edx,%ecx
f01054c3:	72 06                	jb     f01054cb <__umoddi3+0x10b>
f01054c5:	75 10                	jne    f01054d7 <__umoddi3+0x117>
f01054c7:	39 c3                	cmp    %eax,%ebx
f01054c9:	73 0c                	jae    f01054d7 <__umoddi3+0x117>
f01054cb:	2b 44 24 0c          	sub    0xc(%esp),%eax
f01054cf:	1b 54 24 08          	sbb    0x8(%esp),%edx
f01054d3:	89 d7                	mov    %edx,%edi
f01054d5:	89 c6                	mov    %eax,%esi
f01054d7:	89 ca                	mov    %ecx,%edx
f01054d9:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01054de:	29 f3                	sub    %esi,%ebx
f01054e0:	19 fa                	sbb    %edi,%edx
f01054e2:	89 d0                	mov    %edx,%eax
f01054e4:	d3 e0                	shl    %cl,%eax
f01054e6:	89 e9                	mov    %ebp,%ecx
f01054e8:	d3 eb                	shr    %cl,%ebx
f01054ea:	d3 ea                	shr    %cl,%edx
f01054ec:	09 d8                	or     %ebx,%eax
f01054ee:	83 c4 1c             	add    $0x1c,%esp
f01054f1:	5b                   	pop    %ebx
f01054f2:	5e                   	pop    %esi
f01054f3:	5f                   	pop    %edi
f01054f4:	5d                   	pop    %ebp
f01054f5:	c3                   	ret    
f01054f6:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01054fd:	8d 76 00             	lea    0x0(%esi),%esi
f0105500:	29 fe                	sub    %edi,%esi
f0105502:	19 c3                	sbb    %eax,%ebx
f0105504:	89 f2                	mov    %esi,%edx
f0105506:	89 d9                	mov    %ebx,%ecx
f0105508:	e9 1d ff ff ff       	jmp    f010542a <__umoddi3+0x6a>
