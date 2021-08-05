
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
f0100056:	c7 c0 14 f0 18 f0    	mov    $0xf018f014,%eax
f010005c:	c7 c2 00 e1 18 f0    	mov    $0xf018e100,%edx
f0100062:	29 d0                	sub    %edx,%eax
f0100064:	50                   	push   %eax
f0100065:	6a 00                	push   $0x0
f0100067:	52                   	push   %edx
f0100068:	e8 b2 46 00 00       	call   f010471f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010006d:	e8 5c 05 00 00       	call   f01005ce <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	68 ac 1a 00 00       	push   $0x1aac
f010007a:	8d 83 84 8b f7 ff    	lea    -0x8747c(%ebx),%eax
f0100080:	50                   	push   %eax
f0100081:	e8 f3 35 00 00       	call   f0103679 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100086:	e8 11 13 00 00       	call   f010139c <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f010008b:	e8 7f 30 00 00       	call   f010310f <env_init>
	trap_init();
f0100090:	e8 9f 36 00 00       	call   f0103734 <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100095:	83 c4 08             	add    $0x8,%esp
f0100098:	6a 00                	push   $0x0
f010009a:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f01000a0:	e8 7c 32 00 00       	call   f0103321 <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a5:	83 c4 04             	add    $0x4,%esp
f01000a8:	c7 c0 48 e3 18 f0    	mov    $0xf018e348,%eax
f01000ae:	ff 30                	pushl  (%eax)
f01000b0:	e8 ff 34 00 00       	call   f01035b4 <env_run>

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
f01000d0:	c7 c0 04 f0 18 f0    	mov    $0xf018f004,%eax
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
f01000fa:	8d 83 9f 8b f7 ff    	lea    -0x87461(%ebx),%eax
f0100100:	50                   	push   %eax
f0100101:	e8 73 35 00 00       	call   f0103679 <cprintf>
	vcprintf(fmt, ap);
f0100106:	83 c4 08             	add    $0x8,%esp
f0100109:	56                   	push   %esi
f010010a:	57                   	push   %edi
f010010b:	e8 2e 35 00 00       	call   f010363e <vcprintf>
	cprintf("\n");
f0100110:	8d 83 02 9b f7 ff    	lea    -0x864fe(%ebx),%eax
f0100116:	89 04 24             	mov    %eax,(%esp)
f0100119:	e8 5b 35 00 00       	call   f0103679 <cprintf>
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
f0100143:	8d 83 b7 8b f7 ff    	lea    -0x87449(%ebx),%eax
f0100149:	50                   	push   %eax
f010014a:	e8 2a 35 00 00       	call   f0103679 <cprintf>
	vcprintf(fmt, ap);
f010014f:	83 c4 08             	add    $0x8,%esp
f0100152:	56                   	push   %esi
f0100153:	ff 75 10             	pushl  0x10(%ebp)
f0100156:	e8 e3 34 00 00       	call   f010363e <vcprintf>
	cprintf("\n");
f010015b:	8d 83 02 9b f7 ff    	lea    -0x864fe(%ebx),%eax
f0100161:	89 04 24             	mov    %eax,(%esp)
f0100164:	e8 10 35 00 00       	call   f0103679 <cprintf>
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
f010024d:	0f b6 84 13 04 8d f7 	movzbl -0x872fc(%ebx,%edx,1),%eax
f0100254:	ff 
f0100255:	0b 83 e4 20 00 00    	or     0x20e4(%ebx),%eax
	shift ^= togglecode[data];
f010025b:	0f b6 8c 13 04 8c f7 	movzbl -0x873fc(%ebx,%edx,1),%ecx
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
f01002bc:	0f b6 84 13 04 8d f7 	movzbl -0x872fc(%ebx,%edx,1),%eax
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
f01002f8:	8d 83 d1 8b f7 ff    	lea    -0x8742f(%ebx),%eax
f01002fe:	50                   	push   %eax
f01002ff:	e8 75 33 00 00       	call   f0103679 <cprintf>
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
f01004f5:	e8 71 42 00 00       	call   f010476b <memmove>
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
f0100531:	05 eb ba 08 00       	add    $0x8baeb,%eax
	if (serial_exists)
f0100536:	80 b8 18 23 00 00 00 	cmpb   $0x0,0x2318(%eax)
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
f01006e3:	8d 83 dd 8b f7 ff    	lea    -0x87423(%ebx),%eax
f01006e9:	50                   	push   %eax
f01006ea:	e8 8a 2f 00 00       	call   f0103679 <cprintf>
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
f0100746:	8d 83 04 8e f7 ff    	lea    -0x871fc(%ebx),%eax
f010074c:	50                   	push   %eax
f010074d:	8d 83 22 8e f7 ff    	lea    -0x871de(%ebx),%eax
f0100753:	50                   	push   %eax
f0100754:	8d b3 27 8e f7 ff    	lea    -0x871d9(%ebx),%esi
f010075a:	56                   	push   %esi
f010075b:	e8 19 2f 00 00       	call   f0103679 <cprintf>
f0100760:	83 c4 0c             	add    $0xc,%esp
f0100763:	8d 83 e0 8e f7 ff    	lea    -0x87120(%ebx),%eax
f0100769:	50                   	push   %eax
f010076a:	8d 83 30 8e f7 ff    	lea    -0x871d0(%ebx),%eax
f0100770:	50                   	push   %eax
f0100771:	56                   	push   %esi
f0100772:	e8 02 2f 00 00       	call   f0103679 <cprintf>
f0100777:	83 c4 0c             	add    $0xc,%esp
f010077a:	8d 83 39 8e f7 ff    	lea    -0x871c7(%ebx),%eax
f0100780:	50                   	push   %eax
f0100781:	8d 83 4f 8e f7 ff    	lea    -0x871b1(%ebx),%eax
f0100787:	50                   	push   %eax
f0100788:	56                   	push   %esi
f0100789:	e8 eb 2e 00 00       	call   f0103679 <cprintf>
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
f01007ac:	81 c3 70 b8 08 00    	add    $0x8b870,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007b2:	8d 83 59 8e f7 ff    	lea    -0x871a7(%ebx),%eax
f01007b8:	50                   	push   %eax
f01007b9:	e8 bb 2e 00 00       	call   f0103679 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007be:	83 c4 08             	add    $0x8,%esp
f01007c1:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f01007c7:	8d 83 08 8f f7 ff    	lea    -0x870f8(%ebx),%eax
f01007cd:	50                   	push   %eax
f01007ce:	e8 a6 2e 00 00       	call   f0103679 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007d3:	83 c4 0c             	add    $0xc,%esp
f01007d6:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f01007dc:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007e2:	50                   	push   %eax
f01007e3:	57                   	push   %edi
f01007e4:	8d 83 30 8f f7 ff    	lea    -0x870d0(%ebx),%eax
f01007ea:	50                   	push   %eax
f01007eb:	e8 89 2e 00 00       	call   f0103679 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007f0:	83 c4 0c             	add    $0xc,%esp
f01007f3:	c7 c0 8d 4b 10 f0    	mov    $0xf0104b8d,%eax
f01007f9:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007ff:	52                   	push   %edx
f0100800:	50                   	push   %eax
f0100801:	8d 83 54 8f f7 ff    	lea    -0x870ac(%ebx),%eax
f0100807:	50                   	push   %eax
f0100808:	e8 6c 2e 00 00       	call   f0103679 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010080d:	83 c4 0c             	add    $0xc,%esp
f0100810:	c7 c0 00 e1 18 f0    	mov    $0xf018e100,%eax
f0100816:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010081c:	52                   	push   %edx
f010081d:	50                   	push   %eax
f010081e:	8d 83 78 8f f7 ff    	lea    -0x87088(%ebx),%eax
f0100824:	50                   	push   %eax
f0100825:	e8 4f 2e 00 00       	call   f0103679 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010082a:	83 c4 0c             	add    $0xc,%esp
f010082d:	c7 c6 14 f0 18 f0    	mov    $0xf018f014,%esi
f0100833:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0100839:	50                   	push   %eax
f010083a:	56                   	push   %esi
f010083b:	8d 83 9c 8f f7 ff    	lea    -0x87064(%ebx),%eax
f0100841:	50                   	push   %eax
f0100842:	e8 32 2e 00 00       	call   f0103679 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100847:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010084a:	29 fe                	sub    %edi,%esi
f010084c:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100852:	c1 fe 0a             	sar    $0xa,%esi
f0100855:	56                   	push   %esi
f0100856:	8d 83 c0 8f f7 ff    	lea    -0x87040(%ebx),%eax
f010085c:	50                   	push   %eax
f010085d:	e8 17 2e 00 00       	call   f0103679 <cprintf>
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
f0100881:	81 c3 9b b7 08 00    	add    $0x8b79b,%ebx

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
f0100894:	8d 93 72 8e f7 ff    	lea    -0x8718e(%ebx),%edx
f010089a:	89 55 b8             	mov    %edx,-0x48(%ebp)

        int *args = ebp_base_ptr + 2;

        for (int i = 0; i < 5; ++i) {
            cprintf("%x ", args[i]);
f010089d:	8d 93 88 8e f7 ff    	lea    -0x87178(%ebx),%edx
f01008a3:	89 55 c4             	mov    %edx,-0x3c(%ebp)
        cprintf("ebp %x, eip %x, args ", ebp, eip);
f01008a6:	83 ec 04             	sub    $0x4,%esp
f01008a9:	ff 75 c0             	pushl  -0x40(%ebp)
f01008ac:	50                   	push   %eax
f01008ad:	ff 75 b8             	pushl  -0x48(%ebp)
f01008b0:	e8 c4 2d 00 00       	call   f0103679 <cprintf>
f01008b5:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01008b8:	8d 70 08             	lea    0x8(%eax),%esi
f01008bb:	8d 78 1c             	lea    0x1c(%eax),%edi
f01008be:	83 c4 10             	add    $0x10,%esp
            cprintf("%x ", args[i]);
f01008c1:	83 ec 08             	sub    $0x8,%esp
f01008c4:	ff 36                	pushl  (%esi)
f01008c6:	ff 75 c4             	pushl  -0x3c(%ebp)
f01008c9:	e8 ab 2d 00 00       	call   f0103679 <cprintf>
f01008ce:	83 c6 04             	add    $0x4,%esi
        for (int i = 0; i < 5; ++i) {
f01008d1:	83 c4 10             	add    $0x10,%esp
f01008d4:	39 fe                	cmp    %edi,%esi
f01008d6:	75 e9                	jne    f01008c1 <mon_backtrace+0x52>
        }
        cprintf("\n");
f01008d8:	83 ec 0c             	sub    $0xc,%esp
f01008db:	8d 83 02 9b f7 ff    	lea    -0x864fe(%ebx),%eax
f01008e1:	50                   	push   %eax
f01008e2:	e8 92 2d 00 00       	call   f0103679 <cprintf>
        
        // print file line info 
        struct Eipdebuginfo info;
        int ret = debuginfo_eip(eip, &info);
f01008e7:	83 c4 08             	add    $0x8,%esp
f01008ea:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01008ed:	50                   	push   %eax
f01008ee:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01008f1:	57                   	push   %edi
f01008f2:	e8 4d 33 00 00       	call   f0103c44 <debuginfo_eip>
f01008f7:	89 c6                	mov    %eax,%esi
        cprintf("    at %s: %d: %.*s+%d\n",
f01008f9:	83 c4 08             	add    $0x8,%esp
f01008fc:	89 f8                	mov    %edi,%eax
f01008fe:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100901:	50                   	push   %eax
f0100902:	ff 75 d8             	pushl  -0x28(%ebp)
f0100905:	ff 75 dc             	pushl  -0x24(%ebp)
f0100908:	ff 75 d4             	pushl  -0x2c(%ebp)
f010090b:	ff 75 d0             	pushl  -0x30(%ebp)
f010090e:	8d 83 8c 8e f7 ff    	lea    -0x87174(%ebx),%eax
f0100914:	50                   	push   %eax
f0100915:	e8 5f 2d 00 00       	call   f0103679 <cprintf>
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
f0100953:	81 c3 c9 b6 08 00    	add    $0x8b6c9,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100959:	8d 83 ec 8f f7 ff    	lea    -0x87014(%ebx),%eax
f010095f:	50                   	push   %eax
f0100960:	e8 14 2d 00 00       	call   f0103679 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100965:	8d 83 10 90 f7 ff    	lea    -0x86ff0(%ebx),%eax
f010096b:	89 04 24             	mov    %eax,(%esp)
f010096e:	e8 06 2d 00 00       	call   f0103679 <cprintf>

	if (tf != NULL)
f0100973:	83 c4 10             	add    $0x10,%esp
f0100976:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010097a:	74 0e                	je     f010098a <monitor+0x49>
		print_trapframe(tf);
f010097c:	83 ec 0c             	sub    $0xc,%esp
f010097f:	ff 75 08             	pushl  0x8(%ebp)
f0100982:	e8 6b 2e 00 00       	call   f01037f2 <print_trapframe>
f0100987:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f010098a:	8d 83 a8 8e f7 ff    	lea    -0x87158(%ebx),%eax
f0100990:	89 45 a0             	mov    %eax,-0x60(%ebp)
f0100993:	e9 d1 00 00 00       	jmp    f0100a69 <monitor+0x128>
f0100998:	83 ec 08             	sub    $0x8,%esp
f010099b:	0f be c0             	movsbl %al,%eax
f010099e:	50                   	push   %eax
f010099f:	ff 75 a0             	pushl  -0x60(%ebp)
f01009a2:	e8 33 3d 00 00       	call   f01046da <strchr>
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
f01009e9:	e8 86 3c 00 00       	call   f0104674 <strcmp>
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
f0100a0a:	8d 83 ca 8e f7 ff    	lea    -0x87136(%ebx),%eax
f0100a10:	50                   	push   %eax
f0100a11:	e8 63 2c 00 00       	call   f0103679 <cprintf>
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
f0100a40:	e8 95 3c 00 00       	call   f01046da <strchr>
f0100a45:	83 c4 10             	add    $0x10,%esp
f0100a48:	85 c0                	test   %eax,%eax
f0100a4a:	0f 85 67 ff ff ff    	jne    f01009b7 <monitor+0x76>
			buf++;
f0100a50:	83 c6 01             	add    $0x1,%esi
f0100a53:	eb da                	jmp    f0100a2f <monitor+0xee>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a55:	83 ec 08             	sub    $0x8,%esp
f0100a58:	6a 10                	push   $0x10
f0100a5a:	8d 83 ad 8e f7 ff    	lea    -0x87153(%ebx),%eax
f0100a60:	50                   	push   %eax
f0100a61:	e8 13 2c 00 00       	call   f0103679 <cprintf>
			return 0;
f0100a66:	83 c4 10             	add    $0x10,%esp
	// cprintf("x %d, y %x, z %d\n", x, y, z);
	// unsigned int i = 0x00646c72;
 	// cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100a69:	8d bb a4 8e f7 ff    	lea    -0x8715c(%ebx),%edi
f0100a6f:	83 ec 0c             	sub    $0xc,%esp
f0100a72:	57                   	push   %edi
f0100a73:	e8 f1 39 00 00       	call   f0104469 <readline>
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
f0100ac9:	81 c3 53 b5 08 00    	add    $0x8b553,%ebx
f0100acf:	89 c6                	mov    %eax,%esi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100ad1:	50                   	push   %eax
f0100ad2:	e8 0b 2b 00 00       	call   f01035e2 <mc146818_read>
f0100ad7:	89 c7                	mov    %eax,%edi
f0100ad9:	83 c6 01             	add    $0x1,%esi
f0100adc:	89 34 24             	mov    %esi,(%esp)
f0100adf:	e8 fe 2a 00 00       	call   f01035e2 <mc146818_read>
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
f0100af1:	e8 46 25 00 00       	call   f010303c <__x86.get_pc_thunk.dx>
f0100af6:	81 c2 26 b5 08 00    	add    $0x8b526,%edx
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
f0100b2d:	c7 c3 08 f0 18 f0    	mov    $0xf018f008,%ebx
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
f0100b43:	c7 c1 14 f0 18 f0    	mov    $0xf018f014,%ecx
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
f0100b69:	8d 82 38 90 f7 ff    	lea    -0x86fc8(%edx),%eax
f0100b6f:	50                   	push   %eax
f0100b70:	6a 78                	push   $0x78
f0100b72:	8d 82 51 98 f7 ff    	lea    -0x867af(%edx),%eax
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
f0100b85:	e8 b6 24 00 00       	call   f0103040 <__x86.get_pc_thunk.cx>
f0100b8a:	81 c1 92 b4 08 00    	add    $0x8b492,%ecx
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
f0100ba7:	c7 c6 08 f0 18 f0    	mov    $0xf018f008,%esi
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
f0100bdb:	8d 81 60 90 f7 ff    	lea    -0x86fa0(%ecx),%eax
f0100be1:	50                   	push   %eax
f0100be2:	68 77 03 00 00       	push   $0x377
f0100be7:	8d 81 51 98 f7 ff    	lea    -0x867af(%ecx),%eax
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
f0100c0a:	81 c6 12 b4 08 00    	add    $0x8b412,%esi
f0100c10:	89 75 c8             	mov    %esi,-0x38(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c13:	84 c0                	test   %al,%al
f0100c15:	0f 85 ec 02 00 00    	jne    f0100f07 <check_page_free_list+0x30b>
	if (!page_free_list)
f0100c1b:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100c1e:	83 b8 20 23 00 00 00 	cmpl   $0x0,0x2320(%eax)
f0100c25:	74 21                	je     f0100c48 <check_page_free_list+0x4c>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c27:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c2e:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100c31:	8b b0 20 23 00 00    	mov    0x2320(%eax),%esi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c37:	c7 c7 10 f0 18 f0    	mov    $0xf018f010,%edi
	if (PGNUM(pa) >= npages)
f0100c3d:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0100c43:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100c46:	eb 39                	jmp    f0100c81 <check_page_free_list+0x85>
		panic("'page_free_list' is a null pointer!");
f0100c48:	83 ec 04             	sub    $0x4,%esp
f0100c4b:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100c4e:	8d 83 84 90 f7 ff    	lea    -0x86f7c(%ebx),%eax
f0100c54:	50                   	push   %eax
f0100c55:	68 b3 02 00 00       	push   $0x2b3
f0100c5a:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0100c60:	50                   	push   %eax
f0100c61:	e8 4f f4 ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c66:	50                   	push   %eax
f0100c67:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100c6a:	8d 83 60 90 f7 ff    	lea    -0x86fa0(%ebx),%eax
f0100c70:	50                   	push   %eax
f0100c71:	6a 56                	push   $0x56
f0100c73:	8d 83 5d 98 f7 ff    	lea    -0x867a3(%ebx),%eax
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
f0100cbb:	e8 5f 3a 00 00       	call   f010471f <memset>
f0100cc0:	83 c4 10             	add    $0x10,%esp
f0100cc3:	eb ba                	jmp    f0100c7f <check_page_free_list+0x83>
	first_free_page = (char *) boot_alloc(0);
f0100cc5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cca:	e8 22 fe ff ff       	call   f0100af1 <boot_alloc>
f0100ccf:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cd2:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0100cd5:	8b 97 20 23 00 00    	mov    0x2320(%edi),%edx
		assert(pp >= pages);
f0100cdb:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f0100ce1:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100ce3:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
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
f0100d01:	8d 83 6b 98 f7 ff    	lea    -0x86795(%ebx),%eax
f0100d07:	50                   	push   %eax
f0100d08:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0100d0e:	50                   	push   %eax
f0100d0f:	68 cd 02 00 00       	push   $0x2cd
f0100d14:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0100d1a:	50                   	push   %eax
f0100d1b:	e8 95 f3 ff ff       	call   f01000b5 <_panic>
		assert(pp < pages + npages);
f0100d20:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100d23:	8d 83 8c 98 f7 ff    	lea    -0x86774(%ebx),%eax
f0100d29:	50                   	push   %eax
f0100d2a:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0100d30:	50                   	push   %eax
f0100d31:	68 ce 02 00 00       	push   $0x2ce
f0100d36:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0100d3c:	50                   	push   %eax
f0100d3d:	e8 73 f3 ff ff       	call   f01000b5 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d42:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100d45:	8d 83 a8 90 f7 ff    	lea    -0x86f58(%ebx),%eax
f0100d4b:	50                   	push   %eax
f0100d4c:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0100d52:	50                   	push   %eax
f0100d53:	68 cf 02 00 00       	push   $0x2cf
f0100d58:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0100d5e:	50                   	push   %eax
f0100d5f:	e8 51 f3 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) != 0);
f0100d64:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100d67:	8d 83 a0 98 f7 ff    	lea    -0x86760(%ebx),%eax
f0100d6d:	50                   	push   %eax
f0100d6e:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0100d74:	50                   	push   %eax
f0100d75:	68 d2 02 00 00       	push   $0x2d2
f0100d7a:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0100d80:	50                   	push   %eax
f0100d81:	e8 2f f3 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d86:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100d89:	8d 83 b1 98 f7 ff    	lea    -0x8674f(%ebx),%eax
f0100d8f:	50                   	push   %eax
f0100d90:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0100d96:	50                   	push   %eax
f0100d97:	68 d3 02 00 00       	push   $0x2d3
f0100d9c:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0100da2:	50                   	push   %eax
f0100da3:	e8 0d f3 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100da8:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100dab:	8d 83 dc 90 f7 ff    	lea    -0x86f24(%ebx),%eax
f0100db1:	50                   	push   %eax
f0100db2:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0100db8:	50                   	push   %eax
f0100db9:	68 d4 02 00 00       	push   $0x2d4
f0100dbe:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0100dc4:	50                   	push   %eax
f0100dc5:	e8 eb f2 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100dca:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100dcd:	8d 83 ca 98 f7 ff    	lea    -0x86736(%ebx),%eax
f0100dd3:	50                   	push   %eax
f0100dd4:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0100dda:	50                   	push   %eax
f0100ddb:	68 d5 02 00 00       	push   $0x2d5
f0100de0:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
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
f0100e67:	8d 83 60 90 f7 ff    	lea    -0x86fa0(%ebx),%eax
f0100e6d:	50                   	push   %eax
f0100e6e:	6a 56                	push   $0x56
f0100e70:	8d 83 5d 98 f7 ff    	lea    -0x867a3(%ebx),%eax
f0100e76:	50                   	push   %eax
f0100e77:	e8 39 f2 ff ff       	call   f01000b5 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e7c:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100e7f:	8d 83 00 91 f7 ff    	lea    -0x86f00(%ebx),%eax
f0100e85:	50                   	push   %eax
f0100e86:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0100e8c:	50                   	push   %eax
f0100e8d:	68 d6 02 00 00       	push   $0x2d6
f0100e92:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
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
f0100eaf:	8d 83 48 91 f7 ff    	lea    -0x86eb8(%ebx),%eax
f0100eb5:	50                   	push   %eax
f0100eb6:	e8 be 27 00 00       	call   f0103679 <cprintf>
}
f0100ebb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ebe:	5b                   	pop    %ebx
f0100ebf:	5e                   	pop    %esi
f0100ec0:	5f                   	pop    %edi
f0100ec1:	5d                   	pop    %ebp
f0100ec2:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100ec3:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100ec6:	8d 83 e4 98 f7 ff    	lea    -0x8671c(%ebx),%eax
f0100ecc:	50                   	push   %eax
f0100ecd:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0100ed3:	50                   	push   %eax
f0100ed4:	68 de 02 00 00       	push   $0x2de
f0100ed9:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0100edf:	50                   	push   %eax
f0100ee0:	e8 d0 f1 ff ff       	call   f01000b5 <_panic>
	assert(nfree_extmem > 0);
f0100ee5:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100ee8:	8d 83 f6 98 f7 ff    	lea    -0x8670a(%ebx),%eax
f0100eee:	50                   	push   %eax
f0100eef:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0100ef5:	50                   	push   %eax
f0100ef6:	68 df 02 00 00       	push   $0x2df
f0100efb:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0100f01:	50                   	push   %eax
f0100f02:	e8 ae f1 ff ff       	call   f01000b5 <_panic>
	if (!page_free_list)
f0100f07:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100f0a:	8b 80 20 23 00 00    	mov    0x2320(%eax),%eax
f0100f10:	85 c0                	test   %eax,%eax
f0100f12:	0f 84 30 fd ff ff    	je     f0100c48 <check_page_free_list+0x4c>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100f18:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100f1b:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100f1e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100f21:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100f24:	8b 75 c8             	mov    -0x38(%ebp),%esi
f0100f27:	c7 c3 10 f0 18 f0    	mov    $0xf018f010,%ebx
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
f0100f64:	89 86 20 23 00 00    	mov    %eax,0x2320(%esi)
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
f0100f83:	e8 b4 20 00 00       	call   f010303c <__x86.get_pc_thunk.dx>
f0100f88:	81 c2 94 b0 08 00    	add    $0x8b094,%edx
f0100f8e:	89 d7                	mov    %edx,%edi
f0100f90:	89 55 d0             	mov    %edx,-0x30(%ebp)
	size_t num_used = ((uint32_t)boot_alloc(0)-EXTPHYSMEM-KERNBASE)/PGSIZE;
f0100f93:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f98:	e8 54 fb ff ff       	call   f0100af1 <boot_alloc>
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100f9d:	8b 8f 24 23 00 00    	mov    0x2324(%edi),%ecx
f0100fa3:	89 4d e0             	mov    %ecx,-0x20(%ebp)
	size_t num_used = ((uint32_t)boot_alloc(0)-EXTPHYSMEM-KERNBASE)/PGSIZE;
f0100fa6:	05 00 00 f0 0f       	add    $0xff00000,%eax
f0100fab:	c1 e8 0c             	shr    $0xc,%eax
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100fae:	8d 44 01 60          	lea    0x60(%ecx,%eax,1),%eax
f0100fb2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100fb5:	8b b7 20 23 00 00    	mov    0x2320(%edi),%esi
	for(size_t i = 0;i<npages;i++)
f0100fbb:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100fc0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fc5:	c7 c2 08 f0 18 f0    	mov    $0xf018f008,%edx
			pages[i].pp_ref = 0;
f0100fcb:	c7 c1 10 f0 18 f0    	mov    $0xf018f010,%ecx
f0100fd1:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
			pages[i].pp_ref = 1;
f0100fd4:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
			pages[i].pp_ref = 1;
f0100fd7:	89 4d dc             	mov    %ecx,-0x24(%ebp)
	for(size_t i = 0;i<npages;i++)
f0100fda:	eb 3d                	jmp    f0101019 <page_init+0xa3>
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100fdc:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f0100fdf:	77 13                	ja     f0100ff4 <page_init+0x7e>
f0100fe1:	39 45 d8             	cmp    %eax,-0x28(%ebp)
f0100fe4:	76 0e                	jbe    f0100ff4 <page_init+0x7e>
			pages[i].pp_ref = 1;
f0100fe6:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100fe9:	8b 09                	mov    (%ecx),%ecx
f0100feb:	66 c7 44 c1 04 01 00 	movw   $0x1,0x4(%ecx,%eax,8)
f0100ff2:	eb 22                	jmp    f0101016 <page_init+0xa0>
f0100ff4:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
			pages[i].pp_ref = 0;
f0100ffb:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100ffe:	89 cf                	mov    %ecx,%edi
f0101000:	03 3b                	add    (%ebx),%edi
f0101002:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
			pages[i].pp_link = page_free_list;
f0101008:	89 37                	mov    %esi,(%edi)
			page_free_list = &pages[i];
f010100a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010100d:	89 ce                	mov    %ecx,%esi
f010100f:	03 33                	add    (%ebx),%esi
f0101011:	bb 01 00 00 00       	mov    $0x1,%ebx
	for(size_t i = 0;i<npages;i++)
f0101016:	83 c0 01             	add    $0x1,%eax
f0101019:	39 02                	cmp    %eax,(%edx)
f010101b:	76 11                	jbe    f010102e <page_init+0xb8>
		if(i == 0)
f010101d:	85 c0                	test   %eax,%eax
f010101f:	75 bb                	jne    f0100fdc <page_init+0x66>
			pages[i].pp_ref = 1;
f0101021:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0101024:	8b 0f                	mov    (%edi),%ecx
f0101026:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
f010102c:	eb e8                	jmp    f0101016 <page_init+0xa0>
f010102e:	84 db                	test   %bl,%bl
f0101030:	74 09                	je     f010103b <page_init+0xc5>
f0101032:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101035:	89 b0 20 23 00 00    	mov    %esi,0x2320(%eax)
}
f010103b:	83 c4 2c             	add    $0x2c,%esp
f010103e:	5b                   	pop    %ebx
f010103f:	5e                   	pop    %esi
f0101040:	5f                   	pop    %edi
f0101041:	5d                   	pop    %ebp
f0101042:	c3                   	ret    

f0101043 <page_alloc>:
{
f0101043:	f3 0f 1e fb          	endbr32 
f0101047:	55                   	push   %ebp
f0101048:	89 e5                	mov    %esp,%ebp
f010104a:	56                   	push   %esi
f010104b:	53                   	push   %ebx
f010104c:	e8 22 f1 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0101051:	81 c3 cb af 08 00    	add    $0x8afcb,%ebx
	if(page_free_list == NULL)
f0101057:	8b b3 20 23 00 00    	mov    0x2320(%ebx),%esi
f010105d:	85 f6                	test   %esi,%esi
f010105f:	74 37                	je     f0101098 <page_alloc+0x55>
	page_free_list = page_free_list->pp_link;
f0101061:	8b 06                	mov    (%esi),%eax
f0101063:	89 83 20 23 00 00    	mov    %eax,0x2320(%ebx)
	alloc->pp_link = NULL;
f0101069:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
f010106f:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f0101075:	89 f1                	mov    %esi,%ecx
f0101077:	2b 08                	sub    (%eax),%ecx
f0101079:	89 c8                	mov    %ecx,%eax
f010107b:	c1 f8 03             	sar    $0x3,%eax
f010107e:	89 c1                	mov    %eax,%ecx
f0101080:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f0101083:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101088:	c7 c2 08 f0 18 f0    	mov    $0xf018f008,%edx
f010108e:	3b 02                	cmp    (%edx),%eax
f0101090:	73 0f                	jae    f01010a1 <page_alloc+0x5e>
	if(alloc_flags & ALLOC_ZERO)
f0101092:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101096:	75 1f                	jne    f01010b7 <page_alloc+0x74>
}
f0101098:	89 f0                	mov    %esi,%eax
f010109a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010109d:	5b                   	pop    %ebx
f010109e:	5e                   	pop    %esi
f010109f:	5d                   	pop    %ebp
f01010a0:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010a1:	51                   	push   %ecx
f01010a2:	8d 83 60 90 f7 ff    	lea    -0x86fa0(%ebx),%eax
f01010a8:	50                   	push   %eax
f01010a9:	6a 56                	push   $0x56
f01010ab:	8d 83 5d 98 f7 ff    	lea    -0x867a3(%ebx),%eax
f01010b1:	50                   	push   %eax
f01010b2:	e8 fe ef ff ff       	call   f01000b5 <_panic>
		memset(head,0,PGSIZE);
f01010b7:	83 ec 04             	sub    $0x4,%esp
f01010ba:	68 00 10 00 00       	push   $0x1000
f01010bf:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f01010c1:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f01010c7:	51                   	push   %ecx
f01010c8:	e8 52 36 00 00       	call   f010471f <memset>
f01010cd:	83 c4 10             	add    $0x10,%esp
f01010d0:	eb c6                	jmp    f0101098 <page_alloc+0x55>

f01010d2 <page_free>:
{
f01010d2:	f3 0f 1e fb          	endbr32 
f01010d6:	55                   	push   %ebp
f01010d7:	89 e5                	mov    %esp,%ebp
f01010d9:	53                   	push   %ebx
f01010da:	83 ec 04             	sub    $0x4,%esp
f01010dd:	e8 91 f0 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01010e2:	81 c3 3a af 08 00    	add    $0x8af3a,%ebx
f01010e8:	8b 45 08             	mov    0x8(%ebp),%eax
	if((pp->pp_ref != 0) | (pp->pp_link != NULL))  // referenced or freed
f01010eb:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01010f0:	75 18                	jne    f010110a <page_free+0x38>
f01010f2:	83 38 00             	cmpl   $0x0,(%eax)
f01010f5:	75 13                	jne    f010110a <page_free+0x38>
	pp->pp_link = page_free_list;
f01010f7:	8b 8b 20 23 00 00    	mov    0x2320(%ebx),%ecx
f01010fd:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f01010ff:	89 83 20 23 00 00    	mov    %eax,0x2320(%ebx)
}
f0101105:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101108:	c9                   	leave  
f0101109:	c3                   	ret    
		panic("at pmap.c:page_free(): Page double free or freeing a referenced page");
f010110a:	83 ec 04             	sub    $0x4,%esp
f010110d:	8d 83 6c 91 f7 ff    	lea    -0x86e94(%ebx),%eax
f0101113:	50                   	push   %eax
f0101114:	68 7a 01 00 00       	push   $0x17a
f0101119:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010111f:	50                   	push   %eax
f0101120:	e8 90 ef ff ff       	call   f01000b5 <_panic>

f0101125 <page_decref>:
{
f0101125:	f3 0f 1e fb          	endbr32 
f0101129:	55                   	push   %ebp
f010112a:	89 e5                	mov    %esp,%ebp
f010112c:	83 ec 08             	sub    $0x8,%esp
f010112f:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101132:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101136:	83 e8 01             	sub    $0x1,%eax
f0101139:	66 89 42 04          	mov    %ax,0x4(%edx)
f010113d:	66 85 c0             	test   %ax,%ax
f0101140:	74 02                	je     f0101144 <page_decref+0x1f>
}
f0101142:	c9                   	leave  
f0101143:	c3                   	ret    
		page_free(pp);
f0101144:	83 ec 0c             	sub    $0xc,%esp
f0101147:	52                   	push   %edx
f0101148:	e8 85 ff ff ff       	call   f01010d2 <page_free>
f010114d:	83 c4 10             	add    $0x10,%esp
}
f0101150:	eb f0                	jmp    f0101142 <page_decref+0x1d>

f0101152 <pgdir_walk>:
{
f0101152:	f3 0f 1e fb          	endbr32 
f0101156:	55                   	push   %ebp
f0101157:	89 e5                	mov    %esp,%ebp
f0101159:	57                   	push   %edi
f010115a:	56                   	push   %esi
f010115b:	53                   	push   %ebx
f010115c:	83 ec 0c             	sub    $0xc,%esp
f010115f:	e8 e0 1e 00 00       	call   f0103044 <__x86.get_pc_thunk.di>
f0101164:	81 c7 b8 ae 08 00    	add    $0x8aeb8,%edi
f010116a:	8b 75 0c             	mov    0xc(%ebp),%esi
	unsigned int dir_offset = PDX(va);
f010116d:	89 f3                	mov    %esi,%ebx
f010116f:	c1 eb 16             	shr    $0x16,%ebx
	pde_t* entry = pgdir+dir_offset;
f0101172:	c1 e3 02             	shl    $0x2,%ebx
f0101175:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*entry & PTE_P))
f0101178:	f6 03 01             	testb  $0x1,(%ebx)
f010117b:	75 2f                	jne    f01011ac <pgdir_walk+0x5a>
		if(create)
f010117d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101181:	74 73                	je     f01011f6 <pgdir_walk+0xa4>
			new_page = page_alloc(1);
f0101183:	83 ec 0c             	sub    $0xc,%esp
f0101186:	6a 01                	push   $0x1
f0101188:	e8 b6 fe ff ff       	call   f0101043 <page_alloc>
			if(new_page == NULL)
f010118d:	83 c4 10             	add    $0x10,%esp
f0101190:	85 c0                	test   %eax,%eax
f0101192:	74 3f                	je     f01011d3 <pgdir_walk+0x81>
			new_page->pp_ref++;
f0101194:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0101199:	c7 c2 10 f0 18 f0    	mov    $0xf018f010,%edx
f010119f:	2b 02                	sub    (%edx),%eax
f01011a1:	c1 f8 03             	sar    $0x3,%eax
f01011a4:	c1 e0 0c             	shl    $0xc,%eax
			*entry = ((page2pa(new_page))|PTE_P|PTE_W|PTE_U);
f01011a7:	83 c8 07             	or     $0x7,%eax
f01011aa:	89 03                	mov    %eax,(%ebx)
	page_base = (pte_t*)KADDR(PTE_ADDR(*entry));
f01011ac:	8b 03                	mov    (%ebx),%eax
f01011ae:	89 c2                	mov    %eax,%edx
f01011b0:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f01011b6:	c1 e8 0c             	shr    $0xc,%eax
f01011b9:	c7 c1 08 f0 18 f0    	mov    $0xf018f008,%ecx
f01011bf:	3b 01                	cmp    (%ecx),%eax
f01011c1:	73 18                	jae    f01011db <pgdir_walk+0x89>
	page_offset = PTX(va);
f01011c3:	c1 ee 0a             	shr    $0xa,%esi
	return &page_base[page_offset];
f01011c6:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01011cc:	8d 84 32 00 00 00 f0 	lea    -0x10000000(%edx,%esi,1),%eax
}
f01011d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011d6:	5b                   	pop    %ebx
f01011d7:	5e                   	pop    %esi
f01011d8:	5f                   	pop    %edi
f01011d9:	5d                   	pop    %ebp
f01011da:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011db:	52                   	push   %edx
f01011dc:	8d 87 60 90 f7 ff    	lea    -0x86fa0(%edi),%eax
f01011e2:	50                   	push   %eax
f01011e3:	68 c7 01 00 00       	push   $0x1c7
f01011e8:	8d 87 51 98 f7 ff    	lea    -0x867af(%edi),%eax
f01011ee:	50                   	push   %eax
f01011ef:	89 fb                	mov    %edi,%ebx
f01011f1:	e8 bf ee ff ff       	call   f01000b5 <_panic>
			return NULL;
f01011f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01011fb:	eb d6                	jmp    f01011d3 <pgdir_walk+0x81>

f01011fd <boot_map_region>:
{
f01011fd:	55                   	push   %ebp
f01011fe:	89 e5                	mov    %esp,%ebp
f0101200:	57                   	push   %edi
f0101201:	56                   	push   %esi
f0101202:	53                   	push   %ebx
f0101203:	83 ec 1c             	sub    $0x1c,%esp
f0101206:	89 c7                	mov    %eax,%edi
f0101208:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010120b:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for(add = 0;add<size;add+=PGSIZE)
f010120e:	be 00 00 00 00       	mov    $0x0,%esi
f0101213:	89 f3                	mov    %esi,%ebx
f0101215:	03 5d 08             	add    0x8(%ebp),%ebx
f0101218:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f010121b:	76 24                	jbe    f0101241 <boot_map_region+0x44>
		entry = pgdir_walk(pgdir,(void*)va,1);  // get the entry of page table
f010121d:	83 ec 04             	sub    $0x4,%esp
f0101220:	6a 01                	push   $0x1
f0101222:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101225:	01 f0                	add    %esi,%eax
f0101227:	50                   	push   %eax
f0101228:	57                   	push   %edi
f0101229:	e8 24 ff ff ff       	call   f0101152 <pgdir_walk>
		*entry = (pa|perm|PTE_P);
f010122e:	0b 5d 0c             	or     0xc(%ebp),%ebx
f0101231:	83 cb 01             	or     $0x1,%ebx
f0101234:	89 18                	mov    %ebx,(%eax)
	for(add = 0;add<size;add+=PGSIZE)
f0101236:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010123c:	83 c4 10             	add    $0x10,%esp
f010123f:	eb d2                	jmp    f0101213 <boot_map_region+0x16>
}
f0101241:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101244:	5b                   	pop    %ebx
f0101245:	5e                   	pop    %esi
f0101246:	5f                   	pop    %edi
f0101247:	5d                   	pop    %ebp
f0101248:	c3                   	ret    

f0101249 <page_lookup>:
{
f0101249:	f3 0f 1e fb          	endbr32 
f010124d:	55                   	push   %ebp
f010124e:	89 e5                	mov    %esp,%ebp
f0101250:	56                   	push   %esi
f0101251:	53                   	push   %ebx
f0101252:	e8 1c ef ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0101257:	81 c3 c5 ad 08 00    	add    $0x8adc5,%ebx
f010125d:	8b 75 10             	mov    0x10(%ebp),%esi
	entry = pgdir_walk(pgdir,va,0);
f0101260:	83 ec 04             	sub    $0x4,%esp
f0101263:	6a 00                	push   $0x0
f0101265:	ff 75 0c             	pushl  0xc(%ebp)
f0101268:	ff 75 08             	pushl  0x8(%ebp)
f010126b:	e8 e2 fe ff ff       	call   f0101152 <pgdir_walk>
	if(entry == NULL)
f0101270:	83 c4 10             	add    $0x10,%esp
f0101273:	85 c0                	test   %eax,%eax
f0101275:	74 46                	je     f01012bd <page_lookup+0x74>
	if(!(*entry & PTE_P))
f0101277:	8b 10                	mov    (%eax),%edx
f0101279:	f6 c2 01             	test   $0x1,%dl
f010127c:	74 43                	je     f01012c1 <page_lookup+0x78>
f010127e:	c1 ea 0c             	shr    $0xc,%edx
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101281:	c7 c1 08 f0 18 f0    	mov    $0xf018f008,%ecx
f0101287:	39 11                	cmp    %edx,(%ecx)
f0101289:	76 1a                	jbe    f01012a5 <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f010128b:	c7 c1 10 f0 18 f0    	mov    $0xf018f010,%ecx
f0101291:	8b 09                	mov    (%ecx),%ecx
f0101293:	8d 14 d1             	lea    (%ecx,%edx,8),%edx
	if(pte_store != NULL)
f0101296:	85 f6                	test   %esi,%esi
f0101298:	74 02                	je     f010129c <page_lookup+0x53>
		*pte_store = entry;
f010129a:	89 06                	mov    %eax,(%esi)
}
f010129c:	89 d0                	mov    %edx,%eax
f010129e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01012a1:	5b                   	pop    %ebx
f01012a2:	5e                   	pop    %esi
f01012a3:	5d                   	pop    %ebp
f01012a4:	c3                   	ret    
		panic("pa2page called with invalid pa");
f01012a5:	83 ec 04             	sub    $0x4,%esp
f01012a8:	8d 83 b4 91 f7 ff    	lea    -0x86e4c(%ebx),%eax
f01012ae:	50                   	push   %eax
f01012af:	6a 4f                	push   $0x4f
f01012b1:	8d 83 5d 98 f7 ff    	lea    -0x867a3(%ebx),%eax
f01012b7:	50                   	push   %eax
f01012b8:	e8 f8 ed ff ff       	call   f01000b5 <_panic>
		return NULL;
f01012bd:	89 c2                	mov    %eax,%edx
f01012bf:	eb db                	jmp    f010129c <page_lookup+0x53>
		return NULL;
f01012c1:	ba 00 00 00 00       	mov    $0x0,%edx
f01012c6:	eb d4                	jmp    f010129c <page_lookup+0x53>

f01012c8 <page_remove>:
{
f01012c8:	f3 0f 1e fb          	endbr32 
f01012cc:	55                   	push   %ebp
f01012cd:	89 e5                	mov    %esp,%ebp
f01012cf:	53                   	push   %ebx
f01012d0:	83 ec 18             	sub    $0x18,%esp
f01012d3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t* pte = NULL;
f01012d6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo* page = page_lookup(pgdir,va,&pte);
f01012dd:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01012e0:	50                   	push   %eax
f01012e1:	53                   	push   %ebx
f01012e2:	ff 75 08             	pushl  0x8(%ebp)
f01012e5:	e8 5f ff ff ff       	call   f0101249 <page_lookup>
	if(page == NULL)
f01012ea:	83 c4 10             	add    $0x10,%esp
f01012ed:	85 c0                	test   %eax,%eax
f01012ef:	74 18                	je     f0101309 <page_remove+0x41>
	page_decref(page);
f01012f1:	83 ec 0c             	sub    $0xc,%esp
f01012f4:	50                   	push   %eax
f01012f5:	e8 2b fe ff ff       	call   f0101125 <page_decref>
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01012fa:	0f 01 3b             	invlpg (%ebx)
	*pte = 0;
f01012fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101300:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101306:	83 c4 10             	add    $0x10,%esp
}
f0101309:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010130c:	c9                   	leave  
f010130d:	c3                   	ret    

f010130e <page_insert>:
{
f010130e:	f3 0f 1e fb          	endbr32 
f0101312:	55                   	push   %ebp
f0101313:	89 e5                	mov    %esp,%ebp
f0101315:	57                   	push   %edi
f0101316:	56                   	push   %esi
f0101317:	53                   	push   %ebx
f0101318:	83 ec 10             	sub    $0x10,%esp
f010131b:	e8 24 1d 00 00       	call   f0103044 <__x86.get_pc_thunk.di>
f0101320:	81 c7 fc ac 08 00    	add    $0x8acfc,%edi
f0101326:	8b 75 08             	mov    0x8(%ebp),%esi
	entry = pgdir_walk(pgdir,va,1); // get the page table entry 
f0101329:	6a 01                	push   $0x1
f010132b:	ff 75 10             	pushl  0x10(%ebp)
f010132e:	56                   	push   %esi
f010132f:	e8 1e fe ff ff       	call   f0101152 <pgdir_walk>
	if(entry == NULL)
f0101334:	83 c4 10             	add    $0x10,%esp
f0101337:	85 c0                	test   %eax,%eax
f0101339:	74 5a                	je     f0101395 <page_insert+0x87>
f010133b:	89 c3                	mov    %eax,%ebx
	pp->pp_ref++;
f010133d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101340:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	if(*entry&PTE_P)
f0101345:	f6 03 01             	testb  $0x1,(%ebx)
f0101348:	75 34                	jne    f010137e <page_insert+0x70>
	return (pp - pages) << PGSHIFT;
f010134a:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f0101350:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101353:	2b 10                	sub    (%eax),%edx
f0101355:	89 d0                	mov    %edx,%eax
f0101357:	c1 f8 03             	sar    $0x3,%eax
f010135a:	c1 e0 0c             	shl    $0xc,%eax
	*entry = ((page2pa(pp))|perm|PTE_P);
f010135d:	0b 45 14             	or     0x14(%ebp),%eax
f0101360:	83 c8 01             	or     $0x1,%eax
f0101363:	89 03                	mov    %eax,(%ebx)
	pgdir[PDX(va)] |= perm;
f0101365:	8b 45 10             	mov    0x10(%ebp),%eax
f0101368:	c1 e8 16             	shr    $0x16,%eax
f010136b:	8b 4d 14             	mov    0x14(%ebp),%ecx
f010136e:	09 0c 86             	or     %ecx,(%esi,%eax,4)
	return 0;
f0101371:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101376:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101379:	5b                   	pop    %ebx
f010137a:	5e                   	pop    %esi
f010137b:	5f                   	pop    %edi
f010137c:	5d                   	pop    %ebp
f010137d:	c3                   	ret    
f010137e:	8b 45 10             	mov    0x10(%ebp),%eax
f0101381:	0f 01 38             	invlpg (%eax)
		page_remove(pgdir,va);
f0101384:	83 ec 08             	sub    $0x8,%esp
f0101387:	ff 75 10             	pushl  0x10(%ebp)
f010138a:	56                   	push   %esi
f010138b:	e8 38 ff ff ff       	call   f01012c8 <page_remove>
f0101390:	83 c4 10             	add    $0x10,%esp
f0101393:	eb b5                	jmp    f010134a <page_insert+0x3c>
		return -E_NO_MEM;
f0101395:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010139a:	eb da                	jmp    f0101376 <page_insert+0x68>

f010139c <mem_init>:
{
f010139c:	f3 0f 1e fb          	endbr32 
f01013a0:	55                   	push   %ebp
f01013a1:	89 e5                	mov    %esp,%ebp
f01013a3:	57                   	push   %edi
f01013a4:	56                   	push   %esi
f01013a5:	53                   	push   %ebx
f01013a6:	83 ec 3c             	sub    $0x3c,%esp
f01013a9:	e8 c5 ed ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01013ae:	81 c3 6e ac 08 00    	add    $0x8ac6e,%ebx
	basemem = nvram_read(NVRAM_BASELO);
f01013b4:	b8 15 00 00 00       	mov    $0x15,%eax
f01013b9:	e8 fd f6 ff ff       	call   f0100abb <nvram_read>
f01013be:	89 c6                	mov    %eax,%esi
	extmem = nvram_read(NVRAM_EXTLO);
f01013c0:	b8 17 00 00 00       	mov    $0x17,%eax
f01013c5:	e8 f1 f6 ff ff       	call   f0100abb <nvram_read>
f01013ca:	89 c7                	mov    %eax,%edi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01013cc:	b8 34 00 00 00       	mov    $0x34,%eax
f01013d1:	e8 e5 f6 ff ff       	call   f0100abb <nvram_read>
	if (ext16mem)
f01013d6:	c1 e0 06             	shl    $0x6,%eax
f01013d9:	0f 84 ec 00 00 00    	je     f01014cb <mem_init+0x12f>
		totalmem = 16 * 1024 + ext16mem;
f01013df:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f01013e4:	89 c1                	mov    %eax,%ecx
f01013e6:	c1 e9 02             	shr    $0x2,%ecx
f01013e9:	c7 c2 08 f0 18 f0    	mov    $0xf018f008,%edx
f01013ef:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f01013f1:	89 f2                	mov    %esi,%edx
f01013f3:	c1 ea 02             	shr    $0x2,%edx
f01013f6:	89 93 24 23 00 00    	mov    %edx,0x2324(%ebx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013fc:	89 c2                	mov    %eax,%edx
f01013fe:	29 f2                	sub    %esi,%edx
f0101400:	52                   	push   %edx
f0101401:	56                   	push   %esi
f0101402:	50                   	push   %eax
f0101403:	8d 83 d4 91 f7 ff    	lea    -0x86e2c(%ebx),%eax
f0101409:	50                   	push   %eax
f010140a:	e8 6a 22 00 00       	call   f0103679 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010140f:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101414:	e8 d8 f6 ff ff       	call   f0100af1 <boot_alloc>
f0101419:	c7 c6 0c f0 18 f0    	mov    $0xf018f00c,%esi
f010141f:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f0101421:	83 c4 0c             	add    $0xc,%esp
f0101424:	68 00 10 00 00       	push   $0x1000
f0101429:	6a 00                	push   $0x0
f010142b:	50                   	push   %eax
f010142c:	e8 ee 32 00 00       	call   f010471f <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101431:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f0101433:	83 c4 10             	add    $0x10,%esp
f0101436:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010143b:	0f 86 9a 00 00 00    	jbe    f01014db <mem_init+0x13f>
	return (physaddr_t)kva - KERNBASE;
f0101441:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101447:	83 ca 05             	or     $0x5,%edx
f010144a:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages*sizeof(struct PageInfo));
f0101450:	c7 c7 08 f0 18 f0    	mov    $0xf018f008,%edi
f0101456:	8b 07                	mov    (%edi),%eax
f0101458:	c1 e0 03             	shl    $0x3,%eax
f010145b:	e8 91 f6 ff ff       	call   f0100af1 <boot_alloc>
f0101460:	c7 c6 10 f0 18 f0    	mov    $0xf018f010,%esi
f0101466:	89 06                	mov    %eax,(%esi)
	memset(pages,0,npages*sizeof(struct PageInfo));
f0101468:	83 ec 04             	sub    $0x4,%esp
f010146b:	8b 17                	mov    (%edi),%edx
f010146d:	c1 e2 03             	shl    $0x3,%edx
f0101470:	52                   	push   %edx
f0101471:	6a 00                	push   $0x0
f0101473:	50                   	push   %eax
f0101474:	e8 a6 32 00 00       	call   f010471f <memset>
	envs = (struct Env*)boot_alloc(NENV*sizeof(struct Env));
f0101479:	b8 00 80 01 00       	mov    $0x18000,%eax
f010147e:	e8 6e f6 ff ff       	call   f0100af1 <boot_alloc>
f0101483:	c7 c2 48 e3 18 f0    	mov    $0xf018e348,%edx
f0101489:	89 02                	mov    %eax,(%edx)
	memset(envs,0,NENV*sizeof(struct Env));
f010148b:	83 c4 0c             	add    $0xc,%esp
f010148e:	68 00 80 01 00       	push   $0x18000
f0101493:	6a 00                	push   $0x0
f0101495:	50                   	push   %eax
f0101496:	e8 84 32 00 00       	call   f010471f <memset>
	page_init();
f010149b:	e8 d6 fa ff ff       	call   f0100f76 <page_init>
	check_page_free_list(1);
f01014a0:	b8 01 00 00 00       	mov    $0x1,%eax
f01014a5:	e8 52 f7 ff ff       	call   f0100bfc <check_page_free_list>
	if (!pages)
f01014aa:	83 c4 10             	add    $0x10,%esp
f01014ad:	83 3e 00             	cmpl   $0x0,(%esi)
f01014b0:	74 42                	je     f01014f4 <mem_init+0x158>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014b2:	8b 83 20 23 00 00    	mov    0x2320(%ebx),%eax
f01014b8:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f01014bf:	85 c0                	test   %eax,%eax
f01014c1:	74 4c                	je     f010150f <mem_init+0x173>
		++nfree;
f01014c3:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014c7:	8b 00                	mov    (%eax),%eax
f01014c9:	eb f4                	jmp    f01014bf <mem_init+0x123>
		totalmem = 1 * 1024 + extmem;
f01014cb:	8d 87 00 04 00 00    	lea    0x400(%edi),%eax
f01014d1:	85 ff                	test   %edi,%edi
f01014d3:	0f 44 c6             	cmove  %esi,%eax
f01014d6:	e9 09 ff ff ff       	jmp    f01013e4 <mem_init+0x48>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01014db:	50                   	push   %eax
f01014dc:	8d 83 10 92 f7 ff    	lea    -0x86df0(%ebx),%eax
f01014e2:	50                   	push   %eax
f01014e3:	68 a2 00 00 00       	push   $0xa2
f01014e8:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01014ee:	50                   	push   %eax
f01014ef:	e8 c1 eb ff ff       	call   f01000b5 <_panic>
		panic("'pages' is a null pointer!");
f01014f4:	83 ec 04             	sub    $0x4,%esp
f01014f7:	8d 83 07 99 f7 ff    	lea    -0x866f9(%ebx),%eax
f01014fd:	50                   	push   %eax
f01014fe:	68 f2 02 00 00       	push   $0x2f2
f0101503:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0101509:	50                   	push   %eax
f010150a:	e8 a6 eb ff ff       	call   f01000b5 <_panic>
	assert((pp0 = page_alloc(0)));
f010150f:	83 ec 0c             	sub    $0xc,%esp
f0101512:	6a 00                	push   $0x0
f0101514:	e8 2a fb ff ff       	call   f0101043 <page_alloc>
f0101519:	89 c6                	mov    %eax,%esi
f010151b:	83 c4 10             	add    $0x10,%esp
f010151e:	85 c0                	test   %eax,%eax
f0101520:	0f 84 31 02 00 00    	je     f0101757 <mem_init+0x3bb>
	assert((pp1 = page_alloc(0)));
f0101526:	83 ec 0c             	sub    $0xc,%esp
f0101529:	6a 00                	push   $0x0
f010152b:	e8 13 fb ff ff       	call   f0101043 <page_alloc>
f0101530:	89 c7                	mov    %eax,%edi
f0101532:	83 c4 10             	add    $0x10,%esp
f0101535:	85 c0                	test   %eax,%eax
f0101537:	0f 84 39 02 00 00    	je     f0101776 <mem_init+0x3da>
	assert((pp2 = page_alloc(0)));
f010153d:	83 ec 0c             	sub    $0xc,%esp
f0101540:	6a 00                	push   $0x0
f0101542:	e8 fc fa ff ff       	call   f0101043 <page_alloc>
f0101547:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010154a:	83 c4 10             	add    $0x10,%esp
f010154d:	85 c0                	test   %eax,%eax
f010154f:	0f 84 40 02 00 00    	je     f0101795 <mem_init+0x3f9>
	assert(pp1 && pp1 != pp0);
f0101555:	39 fe                	cmp    %edi,%esi
f0101557:	0f 84 57 02 00 00    	je     f01017b4 <mem_init+0x418>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010155d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101560:	39 c7                	cmp    %eax,%edi
f0101562:	0f 84 6b 02 00 00    	je     f01017d3 <mem_init+0x437>
f0101568:	39 c6                	cmp    %eax,%esi
f010156a:	0f 84 63 02 00 00    	je     f01017d3 <mem_init+0x437>
	return (pp - pages) << PGSHIFT;
f0101570:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f0101576:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101578:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f010157e:	8b 10                	mov    (%eax),%edx
f0101580:	c1 e2 0c             	shl    $0xc,%edx
f0101583:	89 f0                	mov    %esi,%eax
f0101585:	29 c8                	sub    %ecx,%eax
f0101587:	c1 f8 03             	sar    $0x3,%eax
f010158a:	c1 e0 0c             	shl    $0xc,%eax
f010158d:	39 d0                	cmp    %edx,%eax
f010158f:	0f 83 5d 02 00 00    	jae    f01017f2 <mem_init+0x456>
f0101595:	89 f8                	mov    %edi,%eax
f0101597:	29 c8                	sub    %ecx,%eax
f0101599:	c1 f8 03             	sar    $0x3,%eax
f010159c:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f010159f:	39 c2                	cmp    %eax,%edx
f01015a1:	0f 86 6a 02 00 00    	jbe    f0101811 <mem_init+0x475>
f01015a7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015aa:	29 c8                	sub    %ecx,%eax
f01015ac:	c1 f8 03             	sar    $0x3,%eax
f01015af:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01015b2:	39 c2                	cmp    %eax,%edx
f01015b4:	0f 86 76 02 00 00    	jbe    f0101830 <mem_init+0x494>
	fl = page_free_list;
f01015ba:	8b 83 20 23 00 00    	mov    0x2320(%ebx),%eax
f01015c0:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f01015c3:	c7 83 20 23 00 00 00 	movl   $0x0,0x2320(%ebx)
f01015ca:	00 00 00 
	assert(!page_alloc(0));
f01015cd:	83 ec 0c             	sub    $0xc,%esp
f01015d0:	6a 00                	push   $0x0
f01015d2:	e8 6c fa ff ff       	call   f0101043 <page_alloc>
f01015d7:	83 c4 10             	add    $0x10,%esp
f01015da:	85 c0                	test   %eax,%eax
f01015dc:	0f 85 6d 02 00 00    	jne    f010184f <mem_init+0x4b3>
	page_free(pp0);
f01015e2:	83 ec 0c             	sub    $0xc,%esp
f01015e5:	56                   	push   %esi
f01015e6:	e8 e7 fa ff ff       	call   f01010d2 <page_free>
	page_free(pp1);
f01015eb:	89 3c 24             	mov    %edi,(%esp)
f01015ee:	e8 df fa ff ff       	call   f01010d2 <page_free>
	page_free(pp2);
f01015f3:	83 c4 04             	add    $0x4,%esp
f01015f6:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015f9:	e8 d4 fa ff ff       	call   f01010d2 <page_free>
	assert((pp0 = page_alloc(0)));
f01015fe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101605:	e8 39 fa ff ff       	call   f0101043 <page_alloc>
f010160a:	89 c6                	mov    %eax,%esi
f010160c:	83 c4 10             	add    $0x10,%esp
f010160f:	85 c0                	test   %eax,%eax
f0101611:	0f 84 57 02 00 00    	je     f010186e <mem_init+0x4d2>
	assert((pp1 = page_alloc(0)));
f0101617:	83 ec 0c             	sub    $0xc,%esp
f010161a:	6a 00                	push   $0x0
f010161c:	e8 22 fa ff ff       	call   f0101043 <page_alloc>
f0101621:	89 c7                	mov    %eax,%edi
f0101623:	83 c4 10             	add    $0x10,%esp
f0101626:	85 c0                	test   %eax,%eax
f0101628:	0f 84 5f 02 00 00    	je     f010188d <mem_init+0x4f1>
	assert((pp2 = page_alloc(0)));
f010162e:	83 ec 0c             	sub    $0xc,%esp
f0101631:	6a 00                	push   $0x0
f0101633:	e8 0b fa ff ff       	call   f0101043 <page_alloc>
f0101638:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010163b:	83 c4 10             	add    $0x10,%esp
f010163e:	85 c0                	test   %eax,%eax
f0101640:	0f 84 66 02 00 00    	je     f01018ac <mem_init+0x510>
	assert(pp1 && pp1 != pp0);
f0101646:	39 fe                	cmp    %edi,%esi
f0101648:	0f 84 7d 02 00 00    	je     f01018cb <mem_init+0x52f>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010164e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101651:	39 c7                	cmp    %eax,%edi
f0101653:	0f 84 91 02 00 00    	je     f01018ea <mem_init+0x54e>
f0101659:	39 c6                	cmp    %eax,%esi
f010165b:	0f 84 89 02 00 00    	je     f01018ea <mem_init+0x54e>
	assert(!page_alloc(0));
f0101661:	83 ec 0c             	sub    $0xc,%esp
f0101664:	6a 00                	push   $0x0
f0101666:	e8 d8 f9 ff ff       	call   f0101043 <page_alloc>
f010166b:	83 c4 10             	add    $0x10,%esp
f010166e:	85 c0                	test   %eax,%eax
f0101670:	0f 85 93 02 00 00    	jne    f0101909 <mem_init+0x56d>
f0101676:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f010167c:	89 f1                	mov    %esi,%ecx
f010167e:	2b 08                	sub    (%eax),%ecx
f0101680:	89 c8                	mov    %ecx,%eax
f0101682:	c1 f8 03             	sar    $0x3,%eax
f0101685:	89 c2                	mov    %eax,%edx
f0101687:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010168a:	25 ff ff 0f 00       	and    $0xfffff,%eax
f010168f:	c7 c1 08 f0 18 f0    	mov    $0xf018f008,%ecx
f0101695:	3b 01                	cmp    (%ecx),%eax
f0101697:	0f 83 8b 02 00 00    	jae    f0101928 <mem_init+0x58c>
	memset(page2kva(pp0), 1, PGSIZE);
f010169d:	83 ec 04             	sub    $0x4,%esp
f01016a0:	68 00 10 00 00       	push   $0x1000
f01016a5:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01016a7:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f01016ad:	52                   	push   %edx
f01016ae:	e8 6c 30 00 00       	call   f010471f <memset>
	page_free(pp0);
f01016b3:	89 34 24             	mov    %esi,(%esp)
f01016b6:	e8 17 fa ff ff       	call   f01010d2 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016bb:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016c2:	e8 7c f9 ff ff       	call   f0101043 <page_alloc>
f01016c7:	83 c4 10             	add    $0x10,%esp
f01016ca:	85 c0                	test   %eax,%eax
f01016cc:	0f 84 6c 02 00 00    	je     f010193e <mem_init+0x5a2>
	assert(pp && pp0 == pp);
f01016d2:	39 c6                	cmp    %eax,%esi
f01016d4:	0f 85 83 02 00 00    	jne    f010195d <mem_init+0x5c1>
	return (pp - pages) << PGSHIFT;
f01016da:	c7 c2 10 f0 18 f0    	mov    $0xf018f010,%edx
f01016e0:	2b 02                	sub    (%edx),%eax
f01016e2:	c1 f8 03             	sar    $0x3,%eax
f01016e5:	89 c2                	mov    %eax,%edx
f01016e7:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01016ea:	25 ff ff 0f 00       	and    $0xfffff,%eax
f01016ef:	c7 c1 08 f0 18 f0    	mov    $0xf018f008,%ecx
f01016f5:	3b 01                	cmp    (%ecx),%eax
f01016f7:	0f 83 7f 02 00 00    	jae    f010197c <mem_init+0x5e0>
	return (void *)(pa + KERNBASE);
f01016fd:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f0101703:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f0101709:	80 38 00             	cmpb   $0x0,(%eax)
f010170c:	0f 85 80 02 00 00    	jne    f0101992 <mem_init+0x5f6>
f0101712:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f0101715:	39 d0                	cmp    %edx,%eax
f0101717:	75 f0                	jne    f0101709 <mem_init+0x36d>
	page_free_list = fl;
f0101719:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010171c:	89 83 20 23 00 00    	mov    %eax,0x2320(%ebx)
	page_free(pp0);
f0101722:	83 ec 0c             	sub    $0xc,%esp
f0101725:	56                   	push   %esi
f0101726:	e8 a7 f9 ff ff       	call   f01010d2 <page_free>
	page_free(pp1);
f010172b:	89 3c 24             	mov    %edi,(%esp)
f010172e:	e8 9f f9 ff ff       	call   f01010d2 <page_free>
	page_free(pp2);
f0101733:	83 c4 04             	add    $0x4,%esp
f0101736:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101739:	e8 94 f9 ff ff       	call   f01010d2 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010173e:	8b 83 20 23 00 00    	mov    0x2320(%ebx),%eax
f0101744:	83 c4 10             	add    $0x10,%esp
f0101747:	85 c0                	test   %eax,%eax
f0101749:	0f 84 62 02 00 00    	je     f01019b1 <mem_init+0x615>
		--nfree;
f010174f:	83 6d d0 01          	subl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101753:	8b 00                	mov    (%eax),%eax
f0101755:	eb f0                	jmp    f0101747 <mem_init+0x3ab>
	assert((pp0 = page_alloc(0)));
f0101757:	8d 83 22 99 f7 ff    	lea    -0x866de(%ebx),%eax
f010175d:	50                   	push   %eax
f010175e:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0101764:	50                   	push   %eax
f0101765:	68 fa 02 00 00       	push   $0x2fa
f010176a:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0101770:	50                   	push   %eax
f0101771:	e8 3f e9 ff ff       	call   f01000b5 <_panic>
	assert((pp1 = page_alloc(0)));
f0101776:	8d 83 38 99 f7 ff    	lea    -0x866c8(%ebx),%eax
f010177c:	50                   	push   %eax
f010177d:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0101783:	50                   	push   %eax
f0101784:	68 fb 02 00 00       	push   $0x2fb
f0101789:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010178f:	50                   	push   %eax
f0101790:	e8 20 e9 ff ff       	call   f01000b5 <_panic>
	assert((pp2 = page_alloc(0)));
f0101795:	8d 83 4e 99 f7 ff    	lea    -0x866b2(%ebx),%eax
f010179b:	50                   	push   %eax
f010179c:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01017a2:	50                   	push   %eax
f01017a3:	68 fc 02 00 00       	push   $0x2fc
f01017a8:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01017ae:	50                   	push   %eax
f01017af:	e8 01 e9 ff ff       	call   f01000b5 <_panic>
	assert(pp1 && pp1 != pp0);
f01017b4:	8d 83 64 99 f7 ff    	lea    -0x8669c(%ebx),%eax
f01017ba:	50                   	push   %eax
f01017bb:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01017c1:	50                   	push   %eax
f01017c2:	68 ff 02 00 00       	push   $0x2ff
f01017c7:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01017cd:	50                   	push   %eax
f01017ce:	e8 e2 e8 ff ff       	call   f01000b5 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017d3:	8d 83 34 92 f7 ff    	lea    -0x86dcc(%ebx),%eax
f01017d9:	50                   	push   %eax
f01017da:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01017e0:	50                   	push   %eax
f01017e1:	68 00 03 00 00       	push   $0x300
f01017e6:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01017ec:	50                   	push   %eax
f01017ed:	e8 c3 e8 ff ff       	call   f01000b5 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f01017f2:	8d 83 76 99 f7 ff    	lea    -0x8668a(%ebx),%eax
f01017f8:	50                   	push   %eax
f01017f9:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01017ff:	50                   	push   %eax
f0101800:	68 01 03 00 00       	push   $0x301
f0101805:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010180b:	50                   	push   %eax
f010180c:	e8 a4 e8 ff ff       	call   f01000b5 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101811:	8d 83 93 99 f7 ff    	lea    -0x8666d(%ebx),%eax
f0101817:	50                   	push   %eax
f0101818:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010181e:	50                   	push   %eax
f010181f:	68 02 03 00 00       	push   $0x302
f0101824:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010182a:	50                   	push   %eax
f010182b:	e8 85 e8 ff ff       	call   f01000b5 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101830:	8d 83 b0 99 f7 ff    	lea    -0x86650(%ebx),%eax
f0101836:	50                   	push   %eax
f0101837:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010183d:	50                   	push   %eax
f010183e:	68 03 03 00 00       	push   $0x303
f0101843:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0101849:	50                   	push   %eax
f010184a:	e8 66 e8 ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f010184f:	8d 83 cd 99 f7 ff    	lea    -0x86633(%ebx),%eax
f0101855:	50                   	push   %eax
f0101856:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010185c:	50                   	push   %eax
f010185d:	68 0a 03 00 00       	push   $0x30a
f0101862:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0101868:	50                   	push   %eax
f0101869:	e8 47 e8 ff ff       	call   f01000b5 <_panic>
	assert((pp0 = page_alloc(0)));
f010186e:	8d 83 22 99 f7 ff    	lea    -0x866de(%ebx),%eax
f0101874:	50                   	push   %eax
f0101875:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010187b:	50                   	push   %eax
f010187c:	68 11 03 00 00       	push   $0x311
f0101881:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0101887:	50                   	push   %eax
f0101888:	e8 28 e8 ff ff       	call   f01000b5 <_panic>
	assert((pp1 = page_alloc(0)));
f010188d:	8d 83 38 99 f7 ff    	lea    -0x866c8(%ebx),%eax
f0101893:	50                   	push   %eax
f0101894:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010189a:	50                   	push   %eax
f010189b:	68 12 03 00 00       	push   $0x312
f01018a0:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01018a6:	50                   	push   %eax
f01018a7:	e8 09 e8 ff ff       	call   f01000b5 <_panic>
	assert((pp2 = page_alloc(0)));
f01018ac:	8d 83 4e 99 f7 ff    	lea    -0x866b2(%ebx),%eax
f01018b2:	50                   	push   %eax
f01018b3:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01018b9:	50                   	push   %eax
f01018ba:	68 13 03 00 00       	push   $0x313
f01018bf:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01018c5:	50                   	push   %eax
f01018c6:	e8 ea e7 ff ff       	call   f01000b5 <_panic>
	assert(pp1 && pp1 != pp0);
f01018cb:	8d 83 64 99 f7 ff    	lea    -0x8669c(%ebx),%eax
f01018d1:	50                   	push   %eax
f01018d2:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01018d8:	50                   	push   %eax
f01018d9:	68 15 03 00 00       	push   $0x315
f01018de:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01018e4:	50                   	push   %eax
f01018e5:	e8 cb e7 ff ff       	call   f01000b5 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018ea:	8d 83 34 92 f7 ff    	lea    -0x86dcc(%ebx),%eax
f01018f0:	50                   	push   %eax
f01018f1:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01018f7:	50                   	push   %eax
f01018f8:	68 16 03 00 00       	push   $0x316
f01018fd:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0101903:	50                   	push   %eax
f0101904:	e8 ac e7 ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f0101909:	8d 83 cd 99 f7 ff    	lea    -0x86633(%ebx),%eax
f010190f:	50                   	push   %eax
f0101910:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0101916:	50                   	push   %eax
f0101917:	68 17 03 00 00       	push   $0x317
f010191c:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0101922:	50                   	push   %eax
f0101923:	e8 8d e7 ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101928:	52                   	push   %edx
f0101929:	8d 83 60 90 f7 ff    	lea    -0x86fa0(%ebx),%eax
f010192f:	50                   	push   %eax
f0101930:	6a 56                	push   $0x56
f0101932:	8d 83 5d 98 f7 ff    	lea    -0x867a3(%ebx),%eax
f0101938:	50                   	push   %eax
f0101939:	e8 77 e7 ff ff       	call   f01000b5 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010193e:	8d 83 dc 99 f7 ff    	lea    -0x86624(%ebx),%eax
f0101944:	50                   	push   %eax
f0101945:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010194b:	50                   	push   %eax
f010194c:	68 1c 03 00 00       	push   $0x31c
f0101951:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0101957:	50                   	push   %eax
f0101958:	e8 58 e7 ff ff       	call   f01000b5 <_panic>
	assert(pp && pp0 == pp);
f010195d:	8d 83 fa 99 f7 ff    	lea    -0x86606(%ebx),%eax
f0101963:	50                   	push   %eax
f0101964:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010196a:	50                   	push   %eax
f010196b:	68 1d 03 00 00       	push   $0x31d
f0101970:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0101976:	50                   	push   %eax
f0101977:	e8 39 e7 ff ff       	call   f01000b5 <_panic>
f010197c:	52                   	push   %edx
f010197d:	8d 83 60 90 f7 ff    	lea    -0x86fa0(%ebx),%eax
f0101983:	50                   	push   %eax
f0101984:	6a 56                	push   $0x56
f0101986:	8d 83 5d 98 f7 ff    	lea    -0x867a3(%ebx),%eax
f010198c:	50                   	push   %eax
f010198d:	e8 23 e7 ff ff       	call   f01000b5 <_panic>
		assert(c[i] == 0);
f0101992:	8d 83 0a 9a f7 ff    	lea    -0x865f6(%ebx),%eax
f0101998:	50                   	push   %eax
f0101999:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010199f:	50                   	push   %eax
f01019a0:	68 20 03 00 00       	push   $0x320
f01019a5:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01019ab:	50                   	push   %eax
f01019ac:	e8 04 e7 ff ff       	call   f01000b5 <_panic>
	assert(nfree == 0);
f01019b1:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01019b5:	0f 85 7f 08 00 00    	jne    f010223a <mem_init+0xe9e>
	cprintf("check_page_alloc() succeeded!\n");
f01019bb:	83 ec 0c             	sub    $0xc,%esp
f01019be:	8d 83 54 92 f7 ff    	lea    -0x86dac(%ebx),%eax
f01019c4:	50                   	push   %eax
f01019c5:	e8 af 1c 00 00       	call   f0103679 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01019ca:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019d1:	e8 6d f6 ff ff       	call   f0101043 <page_alloc>
f01019d6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01019d9:	83 c4 10             	add    $0x10,%esp
f01019dc:	85 c0                	test   %eax,%eax
f01019de:	0f 84 75 08 00 00    	je     f0102259 <mem_init+0xebd>
	assert((pp1 = page_alloc(0)));
f01019e4:	83 ec 0c             	sub    $0xc,%esp
f01019e7:	6a 00                	push   $0x0
f01019e9:	e8 55 f6 ff ff       	call   f0101043 <page_alloc>
f01019ee:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01019f1:	83 c4 10             	add    $0x10,%esp
f01019f4:	85 c0                	test   %eax,%eax
f01019f6:	0f 84 7c 08 00 00    	je     f0102278 <mem_init+0xedc>
	assert((pp2 = page_alloc(0)));
f01019fc:	83 ec 0c             	sub    $0xc,%esp
f01019ff:	6a 00                	push   $0x0
f0101a01:	e8 3d f6 ff ff       	call   f0101043 <page_alloc>
f0101a06:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101a09:	83 c4 10             	add    $0x10,%esp
f0101a0c:	85 c0                	test   %eax,%eax
f0101a0e:	0f 84 83 08 00 00    	je     f0102297 <mem_init+0xefb>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a14:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101a17:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0101a1a:	0f 84 96 08 00 00    	je     f01022b6 <mem_init+0xf1a>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a20:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a23:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101a26:	0f 84 a9 08 00 00    	je     f01022d5 <mem_init+0xf39>
f0101a2c:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101a2f:	0f 84 a0 08 00 00    	je     f01022d5 <mem_init+0xf39>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a35:	8b 83 20 23 00 00    	mov    0x2320(%ebx),%eax
f0101a3b:	89 45 c8             	mov    %eax,-0x38(%ebp)
	page_free_list = 0;
f0101a3e:	c7 83 20 23 00 00 00 	movl   $0x0,0x2320(%ebx)
f0101a45:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a48:	83 ec 0c             	sub    $0xc,%esp
f0101a4b:	6a 00                	push   $0x0
f0101a4d:	e8 f1 f5 ff ff       	call   f0101043 <page_alloc>
f0101a52:	83 c4 10             	add    $0x10,%esp
f0101a55:	85 c0                	test   %eax,%eax
f0101a57:	0f 85 97 08 00 00    	jne    f01022f4 <mem_init+0xf58>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a5d:	83 ec 04             	sub    $0x4,%esp
f0101a60:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a63:	50                   	push   %eax
f0101a64:	6a 00                	push   $0x0
f0101a66:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101a6c:	ff 30                	pushl  (%eax)
f0101a6e:	e8 d6 f7 ff ff       	call   f0101249 <page_lookup>
f0101a73:	83 c4 10             	add    $0x10,%esp
f0101a76:	85 c0                	test   %eax,%eax
f0101a78:	0f 85 95 08 00 00    	jne    f0102313 <mem_init+0xf77>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a7e:	6a 02                	push   $0x2
f0101a80:	6a 00                	push   $0x0
f0101a82:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a85:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101a8b:	ff 30                	pushl  (%eax)
f0101a8d:	e8 7c f8 ff ff       	call   f010130e <page_insert>
f0101a92:	83 c4 10             	add    $0x10,%esp
f0101a95:	85 c0                	test   %eax,%eax
f0101a97:	0f 89 95 08 00 00    	jns    f0102332 <mem_init+0xf96>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a9d:	83 ec 0c             	sub    $0xc,%esp
f0101aa0:	ff 75 cc             	pushl  -0x34(%ebp)
f0101aa3:	e8 2a f6 ff ff       	call   f01010d2 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101aa8:	6a 02                	push   $0x2
f0101aaa:	6a 00                	push   $0x0
f0101aac:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101aaf:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101ab5:	ff 30                	pushl  (%eax)
f0101ab7:	e8 52 f8 ff ff       	call   f010130e <page_insert>
f0101abc:	83 c4 20             	add    $0x20,%esp
f0101abf:	85 c0                	test   %eax,%eax
f0101ac1:	0f 85 8a 08 00 00    	jne    f0102351 <mem_init+0xfb5>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ac7:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101acd:	8b 30                	mov    (%eax),%esi
	return (pp - pages) << PGSHIFT;
f0101acf:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f0101ad5:	8b 38                	mov    (%eax),%edi
f0101ad7:	8b 16                	mov    (%esi),%edx
f0101ad9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101adf:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101ae2:	29 f8                	sub    %edi,%eax
f0101ae4:	c1 f8 03             	sar    $0x3,%eax
f0101ae7:	c1 e0 0c             	shl    $0xc,%eax
f0101aea:	39 c2                	cmp    %eax,%edx
f0101aec:	0f 85 7e 08 00 00    	jne    f0102370 <mem_init+0xfd4>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101af2:	ba 00 00 00 00       	mov    $0x0,%edx
f0101af7:	89 f0                	mov    %esi,%eax
f0101af9:	e8 82 f0 ff ff       	call   f0100b80 <check_va2pa>
f0101afe:	89 c2                	mov    %eax,%edx
f0101b00:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b03:	29 f8                	sub    %edi,%eax
f0101b05:	c1 f8 03             	sar    $0x3,%eax
f0101b08:	c1 e0 0c             	shl    $0xc,%eax
f0101b0b:	39 c2                	cmp    %eax,%edx
f0101b0d:	0f 85 7c 08 00 00    	jne    f010238f <mem_init+0xff3>
	assert(pp1->pp_ref == 1);
f0101b13:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b16:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b1b:	0f 85 8d 08 00 00    	jne    f01023ae <mem_init+0x1012>
	assert(pp0->pp_ref == 1);
f0101b21:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101b24:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b29:	0f 85 9e 08 00 00    	jne    f01023cd <mem_init+0x1031>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b2f:	6a 02                	push   $0x2
f0101b31:	68 00 10 00 00       	push   $0x1000
f0101b36:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b39:	56                   	push   %esi
f0101b3a:	e8 cf f7 ff ff       	call   f010130e <page_insert>
f0101b3f:	83 c4 10             	add    $0x10,%esp
f0101b42:	85 c0                	test   %eax,%eax
f0101b44:	0f 85 a2 08 00 00    	jne    f01023ec <mem_init+0x1050>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b4a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b4f:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101b55:	8b 00                	mov    (%eax),%eax
f0101b57:	e8 24 f0 ff ff       	call   f0100b80 <check_va2pa>
f0101b5c:	89 c2                	mov    %eax,%edx
f0101b5e:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f0101b64:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101b67:	2b 08                	sub    (%eax),%ecx
f0101b69:	89 c8                	mov    %ecx,%eax
f0101b6b:	c1 f8 03             	sar    $0x3,%eax
f0101b6e:	c1 e0 0c             	shl    $0xc,%eax
f0101b71:	39 c2                	cmp    %eax,%edx
f0101b73:	0f 85 92 08 00 00    	jne    f010240b <mem_init+0x106f>
	assert(pp2->pp_ref == 1);
f0101b79:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b7c:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b81:	0f 85 a3 08 00 00    	jne    f010242a <mem_init+0x108e>

	// should be no free memory
	assert(!page_alloc(0));
f0101b87:	83 ec 0c             	sub    $0xc,%esp
f0101b8a:	6a 00                	push   $0x0
f0101b8c:	e8 b2 f4 ff ff       	call   f0101043 <page_alloc>
f0101b91:	83 c4 10             	add    $0x10,%esp
f0101b94:	85 c0                	test   %eax,%eax
f0101b96:	0f 85 ad 08 00 00    	jne    f0102449 <mem_init+0x10ad>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b9c:	6a 02                	push   $0x2
f0101b9e:	68 00 10 00 00       	push   $0x1000
f0101ba3:	ff 75 d0             	pushl  -0x30(%ebp)
f0101ba6:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101bac:	ff 30                	pushl  (%eax)
f0101bae:	e8 5b f7 ff ff       	call   f010130e <page_insert>
f0101bb3:	83 c4 10             	add    $0x10,%esp
f0101bb6:	85 c0                	test   %eax,%eax
f0101bb8:	0f 85 aa 08 00 00    	jne    f0102468 <mem_init+0x10cc>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bbe:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bc3:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101bc9:	8b 00                	mov    (%eax),%eax
f0101bcb:	e8 b0 ef ff ff       	call   f0100b80 <check_va2pa>
f0101bd0:	89 c2                	mov    %eax,%edx
f0101bd2:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f0101bd8:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101bdb:	2b 08                	sub    (%eax),%ecx
f0101bdd:	89 c8                	mov    %ecx,%eax
f0101bdf:	c1 f8 03             	sar    $0x3,%eax
f0101be2:	c1 e0 0c             	shl    $0xc,%eax
f0101be5:	39 c2                	cmp    %eax,%edx
f0101be7:	0f 85 9a 08 00 00    	jne    f0102487 <mem_init+0x10eb>
	assert(pp2->pp_ref == 1);
f0101bed:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101bf0:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101bf5:	0f 85 ab 08 00 00    	jne    f01024a6 <mem_init+0x110a>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101bfb:	83 ec 0c             	sub    $0xc,%esp
f0101bfe:	6a 00                	push   $0x0
f0101c00:	e8 3e f4 ff ff       	call   f0101043 <page_alloc>
f0101c05:	83 c4 10             	add    $0x10,%esp
f0101c08:	85 c0                	test   %eax,%eax
f0101c0a:	0f 85 b5 08 00 00    	jne    f01024c5 <mem_init+0x1129>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c10:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101c16:	8b 08                	mov    (%eax),%ecx
f0101c18:	8b 01                	mov    (%ecx),%eax
f0101c1a:	89 c2                	mov    %eax,%edx
f0101c1c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101c22:	c1 e8 0c             	shr    $0xc,%eax
f0101c25:	c7 c6 08 f0 18 f0    	mov    $0xf018f008,%esi
f0101c2b:	3b 06                	cmp    (%esi),%eax
f0101c2d:	0f 83 b1 08 00 00    	jae    f01024e4 <mem_init+0x1148>
	return (void *)(pa + KERNBASE);
f0101c33:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101c39:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c3c:	83 ec 04             	sub    $0x4,%esp
f0101c3f:	6a 00                	push   $0x0
f0101c41:	68 00 10 00 00       	push   $0x1000
f0101c46:	51                   	push   %ecx
f0101c47:	e8 06 f5 ff ff       	call   f0101152 <pgdir_walk>
f0101c4c:	89 c2                	mov    %eax,%edx
f0101c4e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101c51:	83 c0 04             	add    $0x4,%eax
f0101c54:	83 c4 10             	add    $0x10,%esp
f0101c57:	39 d0                	cmp    %edx,%eax
f0101c59:	0f 85 9e 08 00 00    	jne    f01024fd <mem_init+0x1161>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c5f:	6a 06                	push   $0x6
f0101c61:	68 00 10 00 00       	push   $0x1000
f0101c66:	ff 75 d0             	pushl  -0x30(%ebp)
f0101c69:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101c6f:	ff 30                	pushl  (%eax)
f0101c71:	e8 98 f6 ff ff       	call   f010130e <page_insert>
f0101c76:	83 c4 10             	add    $0x10,%esp
f0101c79:	85 c0                	test   %eax,%eax
f0101c7b:	0f 85 9b 08 00 00    	jne    f010251c <mem_init+0x1180>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c81:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101c87:	8b 30                	mov    (%eax),%esi
f0101c89:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c8e:	89 f0                	mov    %esi,%eax
f0101c90:	e8 eb ee ff ff       	call   f0100b80 <check_va2pa>
f0101c95:	89 c2                	mov    %eax,%edx
	return (pp - pages) << PGSHIFT;
f0101c97:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f0101c9d:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101ca0:	2b 08                	sub    (%eax),%ecx
f0101ca2:	89 c8                	mov    %ecx,%eax
f0101ca4:	c1 f8 03             	sar    $0x3,%eax
f0101ca7:	c1 e0 0c             	shl    $0xc,%eax
f0101caa:	39 c2                	cmp    %eax,%edx
f0101cac:	0f 85 89 08 00 00    	jne    f010253b <mem_init+0x119f>
	assert(pp2->pp_ref == 1);
f0101cb2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101cb5:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101cba:	0f 85 9a 08 00 00    	jne    f010255a <mem_init+0x11be>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101cc0:	83 ec 04             	sub    $0x4,%esp
f0101cc3:	6a 00                	push   $0x0
f0101cc5:	68 00 10 00 00       	push   $0x1000
f0101cca:	56                   	push   %esi
f0101ccb:	e8 82 f4 ff ff       	call   f0101152 <pgdir_walk>
f0101cd0:	83 c4 10             	add    $0x10,%esp
f0101cd3:	f6 00 04             	testb  $0x4,(%eax)
f0101cd6:	0f 84 9d 08 00 00    	je     f0102579 <mem_init+0x11dd>
	assert(kern_pgdir[0] & PTE_U);
f0101cdc:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101ce2:	8b 00                	mov    (%eax),%eax
f0101ce4:	f6 00 04             	testb  $0x4,(%eax)
f0101ce7:	0f 84 ab 08 00 00    	je     f0102598 <mem_init+0x11fc>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ced:	6a 02                	push   $0x2
f0101cef:	68 00 10 00 00       	push   $0x1000
f0101cf4:	ff 75 d0             	pushl  -0x30(%ebp)
f0101cf7:	50                   	push   %eax
f0101cf8:	e8 11 f6 ff ff       	call   f010130e <page_insert>
f0101cfd:	83 c4 10             	add    $0x10,%esp
f0101d00:	85 c0                	test   %eax,%eax
f0101d02:	0f 85 af 08 00 00    	jne    f01025b7 <mem_init+0x121b>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d08:	83 ec 04             	sub    $0x4,%esp
f0101d0b:	6a 00                	push   $0x0
f0101d0d:	68 00 10 00 00       	push   $0x1000
f0101d12:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101d18:	ff 30                	pushl  (%eax)
f0101d1a:	e8 33 f4 ff ff       	call   f0101152 <pgdir_walk>
f0101d1f:	83 c4 10             	add    $0x10,%esp
f0101d22:	f6 00 02             	testb  $0x2,(%eax)
f0101d25:	0f 84 ab 08 00 00    	je     f01025d6 <mem_init+0x123a>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d2b:	83 ec 04             	sub    $0x4,%esp
f0101d2e:	6a 00                	push   $0x0
f0101d30:	68 00 10 00 00       	push   $0x1000
f0101d35:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101d3b:	ff 30                	pushl  (%eax)
f0101d3d:	e8 10 f4 ff ff       	call   f0101152 <pgdir_walk>
f0101d42:	83 c4 10             	add    $0x10,%esp
f0101d45:	f6 00 04             	testb  $0x4,(%eax)
f0101d48:	0f 85 a7 08 00 00    	jne    f01025f5 <mem_init+0x1259>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101d4e:	6a 02                	push   $0x2
f0101d50:	68 00 00 40 00       	push   $0x400000
f0101d55:	ff 75 cc             	pushl  -0x34(%ebp)
f0101d58:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101d5e:	ff 30                	pushl  (%eax)
f0101d60:	e8 a9 f5 ff ff       	call   f010130e <page_insert>
f0101d65:	83 c4 10             	add    $0x10,%esp
f0101d68:	85 c0                	test   %eax,%eax
f0101d6a:	0f 89 a4 08 00 00    	jns    f0102614 <mem_init+0x1278>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d70:	6a 02                	push   $0x2
f0101d72:	68 00 10 00 00       	push   $0x1000
f0101d77:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101d7a:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101d80:	ff 30                	pushl  (%eax)
f0101d82:	e8 87 f5 ff ff       	call   f010130e <page_insert>
f0101d87:	83 c4 10             	add    $0x10,%esp
f0101d8a:	85 c0                	test   %eax,%eax
f0101d8c:	0f 85 a1 08 00 00    	jne    f0102633 <mem_init+0x1297>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d92:	83 ec 04             	sub    $0x4,%esp
f0101d95:	6a 00                	push   $0x0
f0101d97:	68 00 10 00 00       	push   $0x1000
f0101d9c:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101da2:	ff 30                	pushl  (%eax)
f0101da4:	e8 a9 f3 ff ff       	call   f0101152 <pgdir_walk>
f0101da9:	83 c4 10             	add    $0x10,%esp
f0101dac:	f6 00 04             	testb  $0x4,(%eax)
f0101daf:	0f 85 9d 08 00 00    	jne    f0102652 <mem_init+0x12b6>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101db5:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101dbb:	8b 38                	mov    (%eax),%edi
f0101dbd:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dc2:	89 f8                	mov    %edi,%eax
f0101dc4:	e8 b7 ed ff ff       	call   f0100b80 <check_va2pa>
f0101dc9:	c7 c2 10 f0 18 f0    	mov    $0xf018f010,%edx
f0101dcf:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101dd2:	2b 32                	sub    (%edx),%esi
f0101dd4:	c1 fe 03             	sar    $0x3,%esi
f0101dd7:	c1 e6 0c             	shl    $0xc,%esi
f0101dda:	39 f0                	cmp    %esi,%eax
f0101ddc:	0f 85 8f 08 00 00    	jne    f0102671 <mem_init+0x12d5>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101de2:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101de7:	89 f8                	mov    %edi,%eax
f0101de9:	e8 92 ed ff ff       	call   f0100b80 <check_va2pa>
f0101dee:	39 c6                	cmp    %eax,%esi
f0101df0:	0f 85 9a 08 00 00    	jne    f0102690 <mem_init+0x12f4>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101df6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101df9:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f0101dfe:	0f 85 ab 08 00 00    	jne    f01026af <mem_init+0x1313>
	assert(pp2->pp_ref == 0);
f0101e04:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101e07:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e0c:	0f 85 bc 08 00 00    	jne    f01026ce <mem_init+0x1332>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e12:	83 ec 0c             	sub    $0xc,%esp
f0101e15:	6a 00                	push   $0x0
f0101e17:	e8 27 f2 ff ff       	call   f0101043 <page_alloc>
f0101e1c:	83 c4 10             	add    $0x10,%esp
f0101e1f:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101e22:	0f 85 c5 08 00 00    	jne    f01026ed <mem_init+0x1351>
f0101e28:	85 c0                	test   %eax,%eax
f0101e2a:	0f 84 bd 08 00 00    	je     f01026ed <mem_init+0x1351>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e30:	83 ec 08             	sub    $0x8,%esp
f0101e33:	6a 00                	push   $0x0
f0101e35:	c7 c6 0c f0 18 f0    	mov    $0xf018f00c,%esi
f0101e3b:	ff 36                	pushl  (%esi)
f0101e3d:	e8 86 f4 ff ff       	call   f01012c8 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e42:	8b 36                	mov    (%esi),%esi
f0101e44:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e49:	89 f0                	mov    %esi,%eax
f0101e4b:	e8 30 ed ff ff       	call   f0100b80 <check_va2pa>
f0101e50:	83 c4 10             	add    $0x10,%esp
f0101e53:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e56:	0f 85 b0 08 00 00    	jne    f010270c <mem_init+0x1370>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e5c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e61:	89 f0                	mov    %esi,%eax
f0101e63:	e8 18 ed ff ff       	call   f0100b80 <check_va2pa>
f0101e68:	89 c2                	mov    %eax,%edx
f0101e6a:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f0101e70:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101e73:	2b 08                	sub    (%eax),%ecx
f0101e75:	89 c8                	mov    %ecx,%eax
f0101e77:	c1 f8 03             	sar    $0x3,%eax
f0101e7a:	c1 e0 0c             	shl    $0xc,%eax
f0101e7d:	39 c2                	cmp    %eax,%edx
f0101e7f:	0f 85 a6 08 00 00    	jne    f010272b <mem_init+0x138f>
	assert(pp1->pp_ref == 1);
f0101e85:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e88:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e8d:	0f 85 b7 08 00 00    	jne    f010274a <mem_init+0x13ae>
	assert(pp2->pp_ref == 0);
f0101e93:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101e96:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e9b:	0f 85 c8 08 00 00    	jne    f0102769 <mem_init+0x13cd>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101ea1:	6a 00                	push   $0x0
f0101ea3:	68 00 10 00 00       	push   $0x1000
f0101ea8:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101eab:	56                   	push   %esi
f0101eac:	e8 5d f4 ff ff       	call   f010130e <page_insert>
f0101eb1:	83 c4 10             	add    $0x10,%esp
f0101eb4:	85 c0                	test   %eax,%eax
f0101eb6:	0f 85 cc 08 00 00    	jne    f0102788 <mem_init+0x13ec>
	assert(pp1->pp_ref);
f0101ebc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ebf:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101ec4:	0f 84 dd 08 00 00    	je     f01027a7 <mem_init+0x140b>
	assert(pp1->pp_link == NULL);
f0101eca:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ecd:	83 38 00             	cmpl   $0x0,(%eax)
f0101ed0:	0f 85 f0 08 00 00    	jne    f01027c6 <mem_init+0x142a>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101ed6:	83 ec 08             	sub    $0x8,%esp
f0101ed9:	68 00 10 00 00       	push   $0x1000
f0101ede:	c7 c6 0c f0 18 f0    	mov    $0xf018f00c,%esi
f0101ee4:	ff 36                	pushl  (%esi)
f0101ee6:	e8 dd f3 ff ff       	call   f01012c8 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101eeb:	8b 36                	mov    (%esi),%esi
f0101eed:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ef2:	89 f0                	mov    %esi,%eax
f0101ef4:	e8 87 ec ff ff       	call   f0100b80 <check_va2pa>
f0101ef9:	83 c4 10             	add    $0x10,%esp
f0101efc:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101eff:	0f 85 e0 08 00 00    	jne    f01027e5 <mem_init+0x1449>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f05:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f0a:	89 f0                	mov    %esi,%eax
f0101f0c:	e8 6f ec ff ff       	call   f0100b80 <check_va2pa>
f0101f11:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f14:	0f 85 ea 08 00 00    	jne    f0102804 <mem_init+0x1468>
	assert(pp1->pp_ref == 0);
f0101f1a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f1d:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101f22:	0f 85 fb 08 00 00    	jne    f0102823 <mem_init+0x1487>
	assert(pp2->pp_ref == 0);
f0101f28:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101f2b:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101f30:	0f 85 0c 09 00 00    	jne    f0102842 <mem_init+0x14a6>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f36:	83 ec 0c             	sub    $0xc,%esp
f0101f39:	6a 00                	push   $0x0
f0101f3b:	e8 03 f1 ff ff       	call   f0101043 <page_alloc>
f0101f40:	83 c4 10             	add    $0x10,%esp
f0101f43:	85 c0                	test   %eax,%eax
f0101f45:	0f 84 16 09 00 00    	je     f0102861 <mem_init+0x14c5>
f0101f4b:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101f4e:	0f 85 0d 09 00 00    	jne    f0102861 <mem_init+0x14c5>

	// should be no free memory
	assert(!page_alloc(0));
f0101f54:	83 ec 0c             	sub    $0xc,%esp
f0101f57:	6a 00                	push   $0x0
f0101f59:	e8 e5 f0 ff ff       	call   f0101043 <page_alloc>
f0101f5e:	83 c4 10             	add    $0x10,%esp
f0101f61:	85 c0                	test   %eax,%eax
f0101f63:	0f 85 17 09 00 00    	jne    f0102880 <mem_init+0x14e4>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f69:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101f6f:	8b 08                	mov    (%eax),%ecx
f0101f71:	8b 11                	mov    (%ecx),%edx
f0101f73:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f79:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f0101f7f:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0101f82:	2b 38                	sub    (%eax),%edi
f0101f84:	89 f8                	mov    %edi,%eax
f0101f86:	c1 f8 03             	sar    $0x3,%eax
f0101f89:	c1 e0 0c             	shl    $0xc,%eax
f0101f8c:	39 c2                	cmp    %eax,%edx
f0101f8e:	0f 85 0b 09 00 00    	jne    f010289f <mem_init+0x1503>
	kern_pgdir[0] = 0;
f0101f94:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f9a:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f9d:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101fa2:	0f 85 16 09 00 00    	jne    f01028be <mem_init+0x1522>
	pp0->pp_ref = 0;
f0101fa8:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101fab:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101fb1:	83 ec 0c             	sub    $0xc,%esp
f0101fb4:	50                   	push   %eax
f0101fb5:	e8 18 f1 ff ff       	call   f01010d2 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101fba:	83 c4 0c             	add    $0xc,%esp
f0101fbd:	6a 01                	push   $0x1
f0101fbf:	68 00 10 40 00       	push   $0x401000
f0101fc4:	c7 c6 0c f0 18 f0    	mov    $0xf018f00c,%esi
f0101fca:	ff 36                	pushl  (%esi)
f0101fcc:	e8 81 f1 ff ff       	call   f0101152 <pgdir_walk>
f0101fd1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fd4:	8b 3e                	mov    (%esi),%edi
f0101fd6:	8b 57 04             	mov    0x4(%edi),%edx
f0101fd9:	89 d1                	mov    %edx,%ecx
f0101fdb:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	if (PGNUM(pa) >= npages)
f0101fe1:	c7 c6 08 f0 18 f0    	mov    $0xf018f008,%esi
f0101fe7:	8b 36                	mov    (%esi),%esi
f0101fe9:	c1 ea 0c             	shr    $0xc,%edx
f0101fec:	83 c4 10             	add    $0x10,%esp
f0101fef:	39 f2                	cmp    %esi,%edx
f0101ff1:	0f 83 e6 08 00 00    	jae    f01028dd <mem_init+0x1541>
	assert(ptep == ptep1 + PTX(va));
f0101ff7:	81 e9 fc ff ff 0f    	sub    $0xffffffc,%ecx
f0101ffd:	39 c8                	cmp    %ecx,%eax
f0101fff:	0f 85 f1 08 00 00    	jne    f01028f6 <mem_init+0x155a>
	kern_pgdir[PDX(va)] = 0;
f0102005:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	pp0->pp_ref = 0;
f010200c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010200f:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
	return (pp - pages) << PGSHIFT;
f0102015:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f010201b:	2b 08                	sub    (%eax),%ecx
f010201d:	89 c8                	mov    %ecx,%eax
f010201f:	c1 f8 03             	sar    $0x3,%eax
f0102022:	89 c2                	mov    %eax,%edx
f0102024:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102027:	25 ff ff 0f 00       	and    $0xfffff,%eax
f010202c:	39 c6                	cmp    %eax,%esi
f010202e:	0f 86 e1 08 00 00    	jbe    f0102915 <mem_init+0x1579>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102034:	83 ec 04             	sub    $0x4,%esp
f0102037:	68 00 10 00 00       	push   $0x1000
f010203c:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0102041:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102047:	52                   	push   %edx
f0102048:	e8 d2 26 00 00       	call   f010471f <memset>
	page_free(pp0);
f010204d:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102050:	89 3c 24             	mov    %edi,(%esp)
f0102053:	e8 7a f0 ff ff       	call   f01010d2 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102058:	83 c4 0c             	add    $0xc,%esp
f010205b:	6a 01                	push   $0x1
f010205d:	6a 00                	push   $0x0
f010205f:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0102065:	ff 30                	pushl  (%eax)
f0102067:	e8 e6 f0 ff ff       	call   f0101152 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f010206c:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f0102072:	2b 38                	sub    (%eax),%edi
f0102074:	89 f8                	mov    %edi,%eax
f0102076:	c1 f8 03             	sar    $0x3,%eax
f0102079:	89 c2                	mov    %eax,%edx
f010207b:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010207e:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102083:	83 c4 10             	add    $0x10,%esp
f0102086:	c7 c1 08 f0 18 f0    	mov    $0xf018f008,%ecx
f010208c:	3b 01                	cmp    (%ecx),%eax
f010208e:	0f 83 97 08 00 00    	jae    f010292b <mem_init+0x158f>
	return (void *)(pa + KERNBASE);
f0102094:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010209a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010209d:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020a3:	8b 38                	mov    (%eax),%edi
f01020a5:	83 e7 01             	and    $0x1,%edi
f01020a8:	0f 85 93 08 00 00    	jne    f0102941 <mem_init+0x15a5>
f01020ae:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f01020b1:	39 d0                	cmp    %edx,%eax
f01020b3:	75 ee                	jne    f01020a3 <mem_init+0xd07>
	kern_pgdir[0] = 0;
f01020b5:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f01020bb:	8b 00                	mov    (%eax),%eax
f01020bd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020c3:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01020c6:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020cc:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01020cf:	89 8b 20 23 00 00    	mov    %ecx,0x2320(%ebx)

	// free the pages we took
	page_free(pp0);
f01020d5:	83 ec 0c             	sub    $0xc,%esp
f01020d8:	50                   	push   %eax
f01020d9:	e8 f4 ef ff ff       	call   f01010d2 <page_free>
	page_free(pp1);
f01020de:	83 c4 04             	add    $0x4,%esp
f01020e1:	ff 75 d4             	pushl  -0x2c(%ebp)
f01020e4:	e8 e9 ef ff ff       	call   f01010d2 <page_free>
	page_free(pp2);
f01020e9:	83 c4 04             	add    $0x4,%esp
f01020ec:	ff 75 d0             	pushl  -0x30(%ebp)
f01020ef:	e8 de ef ff ff       	call   f01010d2 <page_free>

	cprintf("check_page() succeeded!\n");
f01020f4:	8d 83 eb 9a f7 ff    	lea    -0x86515(%ebx),%eax
f01020fa:	89 04 24             	mov    %eax,(%esp)
f01020fd:	e8 77 15 00 00       	call   f0103679 <cprintf>
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U);
f0102102:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f0102108:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010210a:	83 c4 10             	add    $0x10,%esp
f010210d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102112:	0f 86 48 08 00 00    	jbe    f0102960 <mem_init+0x15c4>
f0102118:	83 ec 08             	sub    $0x8,%esp
f010211b:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f010211d:	05 00 00 00 10       	add    $0x10000000,%eax
f0102122:	50                   	push   %eax
f0102123:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102128:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010212d:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0102133:	8b 00                	mov    (%eax),%eax
f0102135:	e8 c3 f0 ff ff       	call   f01011fd <boot_map_region>
	boot_map_region(kern_pgdir,UENVS,PTSIZE,PADDR(envs),PTE_U);
f010213a:	c7 c0 48 e3 18 f0    	mov    $0xf018e348,%eax
f0102140:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102142:	83 c4 10             	add    $0x10,%esp
f0102145:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010214a:	0f 86 29 08 00 00    	jbe    f0102979 <mem_init+0x15dd>
f0102150:	83 ec 08             	sub    $0x8,%esp
f0102153:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102155:	05 00 00 00 10       	add    $0x10000000,%eax
f010215a:	50                   	push   %eax
f010215b:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102160:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102165:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f010216b:	8b 00                	mov    (%eax),%eax
f010216d:	e8 8b f0 ff ff       	call   f01011fd <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f0102172:	c7 c0 00 20 11 f0    	mov    $0xf0112000,%eax
f0102178:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010217b:	83 c4 10             	add    $0x10,%esp
f010217e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102183:	0f 86 09 08 00 00    	jbe    f0102992 <mem_init+0x15f6>
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f0102189:	c7 c6 0c f0 18 f0    	mov    $0xf018f00c,%esi
f010218f:	83 ec 08             	sub    $0x8,%esp
f0102192:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f0102194:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102197:	05 00 00 00 10       	add    $0x10000000,%eax
f010219c:	50                   	push   %eax
f010219d:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021a2:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021a7:	8b 06                	mov    (%esi),%eax
f01021a9:	e8 4f f0 ff ff       	call   f01011fd <boot_map_region>
	boot_map_region(kern_pgdir,KERNBASE,0xFFFFFFFF-KERNBASE,0,PTE_W);
f01021ae:	83 c4 08             	add    $0x8,%esp
f01021b1:	6a 02                	push   $0x2
f01021b3:	6a 00                	push   $0x0
f01021b5:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01021ba:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021bf:	8b 06                	mov    (%esi),%eax
f01021c1:	e8 37 f0 ff ff       	call   f01011fd <boot_map_region>
	pgdir = kern_pgdir;
f01021c6:	8b 06                	mov    (%esi),%eax
f01021c8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021cb:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f01021d1:	8b 00                	mov    (%eax),%eax
f01021d3:	89 45 c0             	mov    %eax,-0x40(%ebp)
f01021d6:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021dd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021e2:	89 45 cc             	mov    %eax,-0x34(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021e5:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f01021eb:	8b 00                	mov    (%eax),%eax
f01021ed:	89 45 bc             	mov    %eax,-0x44(%ebp)
	if ((uint32_t)kva < KERNBASE)
f01021f0:	89 45 c8             	mov    %eax,-0x38(%ebp)
	return (physaddr_t)kva - KERNBASE;
f01021f3:	05 00 00 00 10       	add    $0x10000000,%eax
f01021f8:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f01021fb:	83 c4 10             	add    $0x10,%esp
f01021fe:	89 fe                	mov    %edi,%esi
f0102200:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0102203:	0f 86 dc 07 00 00    	jbe    f01029e5 <mem_init+0x1649>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102209:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f010220f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102212:	e8 69 e9 ff ff       	call   f0100b80 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102217:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f010221e:	0f 86 87 07 00 00    	jbe    f01029ab <mem_init+0x160f>
f0102224:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102227:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010222a:	39 d0                	cmp    %edx,%eax
f010222c:	0f 85 94 07 00 00    	jne    f01029c6 <mem_init+0x162a>
	for (i = 0; i < n; i += PGSIZE)
f0102232:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102238:	eb c6                	jmp    f0102200 <mem_init+0xe64>
	assert(nfree == 0);
f010223a:	8d 83 14 9a f7 ff    	lea    -0x865ec(%ebx),%eax
f0102240:	50                   	push   %eax
f0102241:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102247:	50                   	push   %eax
f0102248:	68 2d 03 00 00       	push   $0x32d
f010224d:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102253:	50                   	push   %eax
f0102254:	e8 5c de ff ff       	call   f01000b5 <_panic>
	assert((pp0 = page_alloc(0)));
f0102259:	8d 83 22 99 f7 ff    	lea    -0x866de(%ebx),%eax
f010225f:	50                   	push   %eax
f0102260:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102266:	50                   	push   %eax
f0102267:	68 8b 03 00 00       	push   $0x38b
f010226c:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102272:	50                   	push   %eax
f0102273:	e8 3d de ff ff       	call   f01000b5 <_panic>
	assert((pp1 = page_alloc(0)));
f0102278:	8d 83 38 99 f7 ff    	lea    -0x866c8(%ebx),%eax
f010227e:	50                   	push   %eax
f010227f:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102285:	50                   	push   %eax
f0102286:	68 8c 03 00 00       	push   $0x38c
f010228b:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102291:	50                   	push   %eax
f0102292:	e8 1e de ff ff       	call   f01000b5 <_panic>
	assert((pp2 = page_alloc(0)));
f0102297:	8d 83 4e 99 f7 ff    	lea    -0x866b2(%ebx),%eax
f010229d:	50                   	push   %eax
f010229e:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01022a4:	50                   	push   %eax
f01022a5:	68 8d 03 00 00       	push   $0x38d
f01022aa:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01022b0:	50                   	push   %eax
f01022b1:	e8 ff dd ff ff       	call   f01000b5 <_panic>
	assert(pp1 && pp1 != pp0);
f01022b6:	8d 83 64 99 f7 ff    	lea    -0x8669c(%ebx),%eax
f01022bc:	50                   	push   %eax
f01022bd:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01022c3:	50                   	push   %eax
f01022c4:	68 90 03 00 00       	push   $0x390
f01022c9:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01022cf:	50                   	push   %eax
f01022d0:	e8 e0 dd ff ff       	call   f01000b5 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01022d5:	8d 83 34 92 f7 ff    	lea    -0x86dcc(%ebx),%eax
f01022db:	50                   	push   %eax
f01022dc:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01022e2:	50                   	push   %eax
f01022e3:	68 91 03 00 00       	push   $0x391
f01022e8:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01022ee:	50                   	push   %eax
f01022ef:	e8 c1 dd ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f01022f4:	8d 83 cd 99 f7 ff    	lea    -0x86633(%ebx),%eax
f01022fa:	50                   	push   %eax
f01022fb:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102301:	50                   	push   %eax
f0102302:	68 98 03 00 00       	push   $0x398
f0102307:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010230d:	50                   	push   %eax
f010230e:	e8 a2 dd ff ff       	call   f01000b5 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102313:	8d 83 74 92 f7 ff    	lea    -0x86d8c(%ebx),%eax
f0102319:	50                   	push   %eax
f010231a:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102320:	50                   	push   %eax
f0102321:	68 9b 03 00 00       	push   $0x39b
f0102326:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010232c:	50                   	push   %eax
f010232d:	e8 83 dd ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102332:	8d 83 ac 92 f7 ff    	lea    -0x86d54(%ebx),%eax
f0102338:	50                   	push   %eax
f0102339:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010233f:	50                   	push   %eax
f0102340:	68 9e 03 00 00       	push   $0x39e
f0102345:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010234b:	50                   	push   %eax
f010234c:	e8 64 dd ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102351:	8d 83 dc 92 f7 ff    	lea    -0x86d24(%ebx),%eax
f0102357:	50                   	push   %eax
f0102358:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010235e:	50                   	push   %eax
f010235f:	68 a2 03 00 00       	push   $0x3a2
f0102364:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010236a:	50                   	push   %eax
f010236b:	e8 45 dd ff ff       	call   f01000b5 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102370:	8d 83 0c 93 f7 ff    	lea    -0x86cf4(%ebx),%eax
f0102376:	50                   	push   %eax
f0102377:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010237d:	50                   	push   %eax
f010237e:	68 a3 03 00 00       	push   $0x3a3
f0102383:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102389:	50                   	push   %eax
f010238a:	e8 26 dd ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010238f:	8d 83 34 93 f7 ff    	lea    -0x86ccc(%ebx),%eax
f0102395:	50                   	push   %eax
f0102396:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010239c:	50                   	push   %eax
f010239d:	68 a4 03 00 00       	push   $0x3a4
f01023a2:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01023a8:	50                   	push   %eax
f01023a9:	e8 07 dd ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 1);
f01023ae:	8d 83 1f 9a f7 ff    	lea    -0x865e1(%ebx),%eax
f01023b4:	50                   	push   %eax
f01023b5:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01023bb:	50                   	push   %eax
f01023bc:	68 a5 03 00 00       	push   $0x3a5
f01023c1:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01023c7:	50                   	push   %eax
f01023c8:	e8 e8 dc ff ff       	call   f01000b5 <_panic>
	assert(pp0->pp_ref == 1);
f01023cd:	8d 83 30 9a f7 ff    	lea    -0x865d0(%ebx),%eax
f01023d3:	50                   	push   %eax
f01023d4:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01023da:	50                   	push   %eax
f01023db:	68 a6 03 00 00       	push   $0x3a6
f01023e0:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01023e6:	50                   	push   %eax
f01023e7:	e8 c9 dc ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023ec:	8d 83 64 93 f7 ff    	lea    -0x86c9c(%ebx),%eax
f01023f2:	50                   	push   %eax
f01023f3:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01023f9:	50                   	push   %eax
f01023fa:	68 a9 03 00 00       	push   $0x3a9
f01023ff:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102405:	50                   	push   %eax
f0102406:	e8 aa dc ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010240b:	8d 83 a0 93 f7 ff    	lea    -0x86c60(%ebx),%eax
f0102411:	50                   	push   %eax
f0102412:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102418:	50                   	push   %eax
f0102419:	68 aa 03 00 00       	push   $0x3aa
f010241e:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102424:	50                   	push   %eax
f0102425:	e8 8b dc ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 1);
f010242a:	8d 83 41 9a f7 ff    	lea    -0x865bf(%ebx),%eax
f0102430:	50                   	push   %eax
f0102431:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102437:	50                   	push   %eax
f0102438:	68 ab 03 00 00       	push   $0x3ab
f010243d:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102443:	50                   	push   %eax
f0102444:	e8 6c dc ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f0102449:	8d 83 cd 99 f7 ff    	lea    -0x86633(%ebx),%eax
f010244f:	50                   	push   %eax
f0102450:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102456:	50                   	push   %eax
f0102457:	68 ae 03 00 00       	push   $0x3ae
f010245c:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102462:	50                   	push   %eax
f0102463:	e8 4d dc ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102468:	8d 83 64 93 f7 ff    	lea    -0x86c9c(%ebx),%eax
f010246e:	50                   	push   %eax
f010246f:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102475:	50                   	push   %eax
f0102476:	68 b1 03 00 00       	push   $0x3b1
f010247b:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102481:	50                   	push   %eax
f0102482:	e8 2e dc ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102487:	8d 83 a0 93 f7 ff    	lea    -0x86c60(%ebx),%eax
f010248d:	50                   	push   %eax
f010248e:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102494:	50                   	push   %eax
f0102495:	68 b2 03 00 00       	push   $0x3b2
f010249a:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01024a0:	50                   	push   %eax
f01024a1:	e8 0f dc ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 1);
f01024a6:	8d 83 41 9a f7 ff    	lea    -0x865bf(%ebx),%eax
f01024ac:	50                   	push   %eax
f01024ad:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01024b3:	50                   	push   %eax
f01024b4:	68 b3 03 00 00       	push   $0x3b3
f01024b9:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01024bf:	50                   	push   %eax
f01024c0:	e8 f0 db ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f01024c5:	8d 83 cd 99 f7 ff    	lea    -0x86633(%ebx),%eax
f01024cb:	50                   	push   %eax
f01024cc:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01024d2:	50                   	push   %eax
f01024d3:	68 b7 03 00 00       	push   $0x3b7
f01024d8:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01024de:	50                   	push   %eax
f01024df:	e8 d1 db ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024e4:	52                   	push   %edx
f01024e5:	8d 83 60 90 f7 ff    	lea    -0x86fa0(%ebx),%eax
f01024eb:	50                   	push   %eax
f01024ec:	68 ba 03 00 00       	push   $0x3ba
f01024f1:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01024f7:	50                   	push   %eax
f01024f8:	e8 b8 db ff ff       	call   f01000b5 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01024fd:	8d 83 d0 93 f7 ff    	lea    -0x86c30(%ebx),%eax
f0102503:	50                   	push   %eax
f0102504:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010250a:	50                   	push   %eax
f010250b:	68 bb 03 00 00       	push   $0x3bb
f0102510:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102516:	50                   	push   %eax
f0102517:	e8 99 db ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010251c:	8d 83 10 94 f7 ff    	lea    -0x86bf0(%ebx),%eax
f0102522:	50                   	push   %eax
f0102523:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102529:	50                   	push   %eax
f010252a:	68 be 03 00 00       	push   $0x3be
f010252f:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102535:	50                   	push   %eax
f0102536:	e8 7a db ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010253b:	8d 83 a0 93 f7 ff    	lea    -0x86c60(%ebx),%eax
f0102541:	50                   	push   %eax
f0102542:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102548:	50                   	push   %eax
f0102549:	68 bf 03 00 00       	push   $0x3bf
f010254e:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102554:	50                   	push   %eax
f0102555:	e8 5b db ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 1);
f010255a:	8d 83 41 9a f7 ff    	lea    -0x865bf(%ebx),%eax
f0102560:	50                   	push   %eax
f0102561:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102567:	50                   	push   %eax
f0102568:	68 c0 03 00 00       	push   $0x3c0
f010256d:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102573:	50                   	push   %eax
f0102574:	e8 3c db ff ff       	call   f01000b5 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102579:	8d 83 50 94 f7 ff    	lea    -0x86bb0(%ebx),%eax
f010257f:	50                   	push   %eax
f0102580:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102586:	50                   	push   %eax
f0102587:	68 c1 03 00 00       	push   $0x3c1
f010258c:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102592:	50                   	push   %eax
f0102593:	e8 1d db ff ff       	call   f01000b5 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102598:	8d 83 52 9a f7 ff    	lea    -0x865ae(%ebx),%eax
f010259e:	50                   	push   %eax
f010259f:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01025a5:	50                   	push   %eax
f01025a6:	68 c2 03 00 00       	push   $0x3c2
f01025ab:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01025b1:	50                   	push   %eax
f01025b2:	e8 fe da ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01025b7:	8d 83 64 93 f7 ff    	lea    -0x86c9c(%ebx),%eax
f01025bd:	50                   	push   %eax
f01025be:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01025c4:	50                   	push   %eax
f01025c5:	68 c5 03 00 00       	push   $0x3c5
f01025ca:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01025d0:	50                   	push   %eax
f01025d1:	e8 df da ff ff       	call   f01000b5 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01025d6:	8d 83 84 94 f7 ff    	lea    -0x86b7c(%ebx),%eax
f01025dc:	50                   	push   %eax
f01025dd:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01025e3:	50                   	push   %eax
f01025e4:	68 c6 03 00 00       	push   $0x3c6
f01025e9:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01025ef:	50                   	push   %eax
f01025f0:	e8 c0 da ff ff       	call   f01000b5 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01025f5:	8d 83 b8 94 f7 ff    	lea    -0x86b48(%ebx),%eax
f01025fb:	50                   	push   %eax
f01025fc:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102602:	50                   	push   %eax
f0102603:	68 c7 03 00 00       	push   $0x3c7
f0102608:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010260e:	50                   	push   %eax
f010260f:	e8 a1 da ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102614:	8d 83 f0 94 f7 ff    	lea    -0x86b10(%ebx),%eax
f010261a:	50                   	push   %eax
f010261b:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102621:	50                   	push   %eax
f0102622:	68 ca 03 00 00       	push   $0x3ca
f0102627:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010262d:	50                   	push   %eax
f010262e:	e8 82 da ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102633:	8d 83 28 95 f7 ff    	lea    -0x86ad8(%ebx),%eax
f0102639:	50                   	push   %eax
f010263a:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102640:	50                   	push   %eax
f0102641:	68 cd 03 00 00       	push   $0x3cd
f0102646:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010264c:	50                   	push   %eax
f010264d:	e8 63 da ff ff       	call   f01000b5 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102652:	8d 83 b8 94 f7 ff    	lea    -0x86b48(%ebx),%eax
f0102658:	50                   	push   %eax
f0102659:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010265f:	50                   	push   %eax
f0102660:	68 ce 03 00 00       	push   $0x3ce
f0102665:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010266b:	50                   	push   %eax
f010266c:	e8 44 da ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102671:	8d 83 64 95 f7 ff    	lea    -0x86a9c(%ebx),%eax
f0102677:	50                   	push   %eax
f0102678:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010267e:	50                   	push   %eax
f010267f:	68 d1 03 00 00       	push   $0x3d1
f0102684:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010268a:	50                   	push   %eax
f010268b:	e8 25 da ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102690:	8d 83 90 95 f7 ff    	lea    -0x86a70(%ebx),%eax
f0102696:	50                   	push   %eax
f0102697:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010269d:	50                   	push   %eax
f010269e:	68 d2 03 00 00       	push   $0x3d2
f01026a3:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01026a9:	50                   	push   %eax
f01026aa:	e8 06 da ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 2);
f01026af:	8d 83 68 9a f7 ff    	lea    -0x86598(%ebx),%eax
f01026b5:	50                   	push   %eax
f01026b6:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01026bc:	50                   	push   %eax
f01026bd:	68 d4 03 00 00       	push   $0x3d4
f01026c2:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01026c8:	50                   	push   %eax
f01026c9:	e8 e7 d9 ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 0);
f01026ce:	8d 83 79 9a f7 ff    	lea    -0x86587(%ebx),%eax
f01026d4:	50                   	push   %eax
f01026d5:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01026db:	50                   	push   %eax
f01026dc:	68 d5 03 00 00       	push   $0x3d5
f01026e1:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01026e7:	50                   	push   %eax
f01026e8:	e8 c8 d9 ff ff       	call   f01000b5 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f01026ed:	8d 83 c0 95 f7 ff    	lea    -0x86a40(%ebx),%eax
f01026f3:	50                   	push   %eax
f01026f4:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01026fa:	50                   	push   %eax
f01026fb:	68 d8 03 00 00       	push   $0x3d8
f0102700:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102706:	50                   	push   %eax
f0102707:	e8 a9 d9 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010270c:	8d 83 e4 95 f7 ff    	lea    -0x86a1c(%ebx),%eax
f0102712:	50                   	push   %eax
f0102713:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102719:	50                   	push   %eax
f010271a:	68 dc 03 00 00       	push   $0x3dc
f010271f:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102725:	50                   	push   %eax
f0102726:	e8 8a d9 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010272b:	8d 83 90 95 f7 ff    	lea    -0x86a70(%ebx),%eax
f0102731:	50                   	push   %eax
f0102732:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102738:	50                   	push   %eax
f0102739:	68 dd 03 00 00       	push   $0x3dd
f010273e:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102744:	50                   	push   %eax
f0102745:	e8 6b d9 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 1);
f010274a:	8d 83 1f 9a f7 ff    	lea    -0x865e1(%ebx),%eax
f0102750:	50                   	push   %eax
f0102751:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102757:	50                   	push   %eax
f0102758:	68 de 03 00 00       	push   $0x3de
f010275d:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102763:	50                   	push   %eax
f0102764:	e8 4c d9 ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 0);
f0102769:	8d 83 79 9a f7 ff    	lea    -0x86587(%ebx),%eax
f010276f:	50                   	push   %eax
f0102770:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102776:	50                   	push   %eax
f0102777:	68 df 03 00 00       	push   $0x3df
f010277c:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102782:	50                   	push   %eax
f0102783:	e8 2d d9 ff ff       	call   f01000b5 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102788:	8d 83 08 96 f7 ff    	lea    -0x869f8(%ebx),%eax
f010278e:	50                   	push   %eax
f010278f:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102795:	50                   	push   %eax
f0102796:	68 e2 03 00 00       	push   $0x3e2
f010279b:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01027a1:	50                   	push   %eax
f01027a2:	e8 0e d9 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref);
f01027a7:	8d 83 8a 9a f7 ff    	lea    -0x86576(%ebx),%eax
f01027ad:	50                   	push   %eax
f01027ae:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01027b4:	50                   	push   %eax
f01027b5:	68 e3 03 00 00       	push   $0x3e3
f01027ba:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01027c0:	50                   	push   %eax
f01027c1:	e8 ef d8 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_link == NULL);
f01027c6:	8d 83 96 9a f7 ff    	lea    -0x8656a(%ebx),%eax
f01027cc:	50                   	push   %eax
f01027cd:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01027d3:	50                   	push   %eax
f01027d4:	68 e4 03 00 00       	push   $0x3e4
f01027d9:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01027df:	50                   	push   %eax
f01027e0:	e8 d0 d8 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01027e5:	8d 83 e4 95 f7 ff    	lea    -0x86a1c(%ebx),%eax
f01027eb:	50                   	push   %eax
f01027ec:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01027f2:	50                   	push   %eax
f01027f3:	68 e8 03 00 00       	push   $0x3e8
f01027f8:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01027fe:	50                   	push   %eax
f01027ff:	e8 b1 d8 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102804:	8d 83 40 96 f7 ff    	lea    -0x869c0(%ebx),%eax
f010280a:	50                   	push   %eax
f010280b:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102811:	50                   	push   %eax
f0102812:	68 e9 03 00 00       	push   $0x3e9
f0102817:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010281d:	50                   	push   %eax
f010281e:	e8 92 d8 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 0);
f0102823:	8d 83 ab 9a f7 ff    	lea    -0x86555(%ebx),%eax
f0102829:	50                   	push   %eax
f010282a:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102830:	50                   	push   %eax
f0102831:	68 ea 03 00 00       	push   $0x3ea
f0102836:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010283c:	50                   	push   %eax
f010283d:	e8 73 d8 ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 0);
f0102842:	8d 83 79 9a f7 ff    	lea    -0x86587(%ebx),%eax
f0102848:	50                   	push   %eax
f0102849:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010284f:	50                   	push   %eax
f0102850:	68 eb 03 00 00       	push   $0x3eb
f0102855:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010285b:	50                   	push   %eax
f010285c:	e8 54 d8 ff ff       	call   f01000b5 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f0102861:	8d 83 68 96 f7 ff    	lea    -0x86998(%ebx),%eax
f0102867:	50                   	push   %eax
f0102868:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010286e:	50                   	push   %eax
f010286f:	68 ee 03 00 00       	push   $0x3ee
f0102874:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010287a:	50                   	push   %eax
f010287b:	e8 35 d8 ff ff       	call   f01000b5 <_panic>
	assert(!page_alloc(0));
f0102880:	8d 83 cd 99 f7 ff    	lea    -0x86633(%ebx),%eax
f0102886:	50                   	push   %eax
f0102887:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010288d:	50                   	push   %eax
f010288e:	68 f1 03 00 00       	push   $0x3f1
f0102893:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102899:	50                   	push   %eax
f010289a:	e8 16 d8 ff ff       	call   f01000b5 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010289f:	8d 83 0c 93 f7 ff    	lea    -0x86cf4(%ebx),%eax
f01028a5:	50                   	push   %eax
f01028a6:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01028ac:	50                   	push   %eax
f01028ad:	68 f4 03 00 00       	push   $0x3f4
f01028b2:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01028b8:	50                   	push   %eax
f01028b9:	e8 f7 d7 ff ff       	call   f01000b5 <_panic>
	assert(pp0->pp_ref == 1);
f01028be:	8d 83 30 9a f7 ff    	lea    -0x865d0(%ebx),%eax
f01028c4:	50                   	push   %eax
f01028c5:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01028cb:	50                   	push   %eax
f01028cc:	68 f6 03 00 00       	push   $0x3f6
f01028d1:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01028d7:	50                   	push   %eax
f01028d8:	e8 d8 d7 ff ff       	call   f01000b5 <_panic>
f01028dd:	51                   	push   %ecx
f01028de:	8d 83 60 90 f7 ff    	lea    -0x86fa0(%ebx),%eax
f01028e4:	50                   	push   %eax
f01028e5:	68 fd 03 00 00       	push   $0x3fd
f01028ea:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01028f0:	50                   	push   %eax
f01028f1:	e8 bf d7 ff ff       	call   f01000b5 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01028f6:	8d 83 bc 9a f7 ff    	lea    -0x86544(%ebx),%eax
f01028fc:	50                   	push   %eax
f01028fd:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102903:	50                   	push   %eax
f0102904:	68 fe 03 00 00       	push   $0x3fe
f0102909:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010290f:	50                   	push   %eax
f0102910:	e8 a0 d7 ff ff       	call   f01000b5 <_panic>
f0102915:	52                   	push   %edx
f0102916:	8d 83 60 90 f7 ff    	lea    -0x86fa0(%ebx),%eax
f010291c:	50                   	push   %eax
f010291d:	6a 56                	push   $0x56
f010291f:	8d 83 5d 98 f7 ff    	lea    -0x867a3(%ebx),%eax
f0102925:	50                   	push   %eax
f0102926:	e8 8a d7 ff ff       	call   f01000b5 <_panic>
f010292b:	52                   	push   %edx
f010292c:	8d 83 60 90 f7 ff    	lea    -0x86fa0(%ebx),%eax
f0102932:	50                   	push   %eax
f0102933:	6a 56                	push   $0x56
f0102935:	8d 83 5d 98 f7 ff    	lea    -0x867a3(%ebx),%eax
f010293b:	50                   	push   %eax
f010293c:	e8 74 d7 ff ff       	call   f01000b5 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102941:	8d 83 d4 9a f7 ff    	lea    -0x8652c(%ebx),%eax
f0102947:	50                   	push   %eax
f0102948:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010294e:	50                   	push   %eax
f010294f:	68 08 04 00 00       	push   $0x408
f0102954:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010295a:	50                   	push   %eax
f010295b:	e8 55 d7 ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102960:	50                   	push   %eax
f0102961:	8d 83 10 92 f7 ff    	lea    -0x86df0(%ebx),%eax
f0102967:	50                   	push   %eax
f0102968:	68 c9 00 00 00       	push   $0xc9
f010296d:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102973:	50                   	push   %eax
f0102974:	e8 3c d7 ff ff       	call   f01000b5 <_panic>
f0102979:	50                   	push   %eax
f010297a:	8d 83 10 92 f7 ff    	lea    -0x86df0(%ebx),%eax
f0102980:	50                   	push   %eax
f0102981:	68 d1 00 00 00       	push   $0xd1
f0102986:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f010298c:	50                   	push   %eax
f010298d:	e8 23 d7 ff ff       	call   f01000b5 <_panic>
f0102992:	50                   	push   %eax
f0102993:	8d 83 10 92 f7 ff    	lea    -0x86df0(%ebx),%eax
f0102999:	50                   	push   %eax
f010299a:	68 dd 00 00 00       	push   $0xdd
f010299f:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01029a5:	50                   	push   %eax
f01029a6:	e8 0a d7 ff ff       	call   f01000b5 <_panic>
f01029ab:	ff 75 bc             	pushl  -0x44(%ebp)
f01029ae:	8d 83 10 92 f7 ff    	lea    -0x86df0(%ebx),%eax
f01029b4:	50                   	push   %eax
f01029b5:	68 45 03 00 00       	push   $0x345
f01029ba:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01029c0:	50                   	push   %eax
f01029c1:	e8 ef d6 ff ff       	call   f01000b5 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01029c6:	8d 83 8c 96 f7 ff    	lea    -0x86974(%ebx),%eax
f01029cc:	50                   	push   %eax
f01029cd:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01029d3:	50                   	push   %eax
f01029d4:	68 45 03 00 00       	push   $0x345
f01029d9:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f01029df:	50                   	push   %eax
f01029e0:	e8 d0 d6 ff ff       	call   f01000b5 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01029e5:	c7 c0 48 e3 18 f0    	mov    $0xf018e348,%eax
f01029eb:	8b 00                	mov    (%eax),%eax
f01029ed:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	if ((uint32_t)kva < KERNBASE)
f01029f0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01029f3:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f01029f8:	05 00 00 40 21       	add    $0x21400000,%eax
f01029fd:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102a00:	89 f2                	mov    %esi,%edx
f0102a02:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a05:	e8 76 e1 ff ff       	call   f0100b80 <check_va2pa>
f0102a0a:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102a11:	76 42                	jbe    f0102a55 <mem_init+0x16b9>
f0102a13:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102a16:	8d 14 31             	lea    (%ecx,%esi,1),%edx
f0102a19:	39 d0                	cmp    %edx,%eax
f0102a1b:	75 53                	jne    f0102a70 <mem_init+0x16d4>
f0102a1d:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
f0102a23:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102a29:	75 d5                	jne    f0102a00 <mem_init+0x1664>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a2b:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0102a2e:	c1 e0 0c             	shl    $0xc,%eax
f0102a31:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102a34:	89 fe                	mov    %edi,%esi
f0102a36:	3b 75 cc             	cmp    -0x34(%ebp),%esi
f0102a39:	73 73                	jae    f0102aae <mem_init+0x1712>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102a3b:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0102a41:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a44:	e8 37 e1 ff ff       	call   f0100b80 <check_va2pa>
f0102a49:	39 c6                	cmp    %eax,%esi
f0102a4b:	75 42                	jne    f0102a8f <mem_init+0x16f3>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a4d:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102a53:	eb e1                	jmp    f0102a36 <mem_init+0x169a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a55:	ff 75 c4             	pushl  -0x3c(%ebp)
f0102a58:	8d 83 10 92 f7 ff    	lea    -0x86df0(%ebx),%eax
f0102a5e:	50                   	push   %eax
f0102a5f:	68 4a 03 00 00       	push   $0x34a
f0102a64:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102a6a:	50                   	push   %eax
f0102a6b:	e8 45 d6 ff ff       	call   f01000b5 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102a70:	8d 83 c0 96 f7 ff    	lea    -0x86940(%ebx),%eax
f0102a76:	50                   	push   %eax
f0102a77:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102a7d:	50                   	push   %eax
f0102a7e:	68 4a 03 00 00       	push   $0x34a
f0102a83:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102a89:	50                   	push   %eax
f0102a8a:	e8 26 d6 ff ff       	call   f01000b5 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102a8f:	8d 83 f4 96 f7 ff    	lea    -0x8690c(%ebx),%eax
f0102a95:	50                   	push   %eax
f0102a96:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102a9c:	50                   	push   %eax
f0102a9d:	68 4e 03 00 00       	push   $0x34e
f0102aa2:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102aa8:	50                   	push   %eax
f0102aa9:	e8 07 d6 ff ff       	call   f01000b5 <_panic>
f0102aae:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102ab3:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102ab6:	05 00 80 00 20       	add    $0x20008000,%eax
f0102abb:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102abe:	89 f2                	mov    %esi,%edx
f0102ac0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ac3:	e8 b8 e0 ff ff       	call   f0100b80 <check_va2pa>
f0102ac8:	89 c2                	mov    %eax,%edx
f0102aca:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102acd:	01 f0                	add    %esi,%eax
f0102acf:	39 c2                	cmp    %eax,%edx
f0102ad1:	75 25                	jne    f0102af8 <mem_init+0x175c>
f0102ad3:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102ad9:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102adf:	75 dd                	jne    f0102abe <mem_init+0x1722>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102ae1:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102ae6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ae9:	e8 92 e0 ff ff       	call   f0100b80 <check_va2pa>
f0102aee:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102af1:	75 24                	jne    f0102b17 <mem_init+0x177b>
f0102af3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102af6:	eb 6b                	jmp    f0102b63 <mem_init+0x17c7>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102af8:	8d 83 1c 97 f7 ff    	lea    -0x868e4(%ebx),%eax
f0102afe:	50                   	push   %eax
f0102aff:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102b05:	50                   	push   %eax
f0102b06:	68 52 03 00 00       	push   $0x352
f0102b0b:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102b11:	50                   	push   %eax
f0102b12:	e8 9e d5 ff ff       	call   f01000b5 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102b17:	8d 83 64 97 f7 ff    	lea    -0x8689c(%ebx),%eax
f0102b1d:	50                   	push   %eax
f0102b1e:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102b24:	50                   	push   %eax
f0102b25:	68 53 03 00 00       	push   $0x353
f0102b2a:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102b30:	50                   	push   %eax
f0102b31:	e8 7f d5 ff ff       	call   f01000b5 <_panic>
		switch (i) {
f0102b36:	81 ff bf 03 00 00    	cmp    $0x3bf,%edi
f0102b3c:	75 25                	jne    f0102b63 <mem_init+0x17c7>
			assert(pgdir[i] & PTE_P);
f0102b3e:	f6 04 b8 01          	testb  $0x1,(%eax,%edi,4)
f0102b42:	74 4c                	je     f0102b90 <mem_init+0x17f4>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b44:	83 c7 01             	add    $0x1,%edi
f0102b47:	81 ff ff 03 00 00    	cmp    $0x3ff,%edi
f0102b4d:	0f 87 a7 00 00 00    	ja     f0102bfa <mem_init+0x185e>
		switch (i) {
f0102b53:	81 ff bd 03 00 00    	cmp    $0x3bd,%edi
f0102b59:	77 db                	ja     f0102b36 <mem_init+0x179a>
f0102b5b:	81 ff ba 03 00 00    	cmp    $0x3ba,%edi
f0102b61:	77 db                	ja     f0102b3e <mem_init+0x17a2>
			if (i >= PDX(KERNBASE)) {
f0102b63:	81 ff bf 03 00 00    	cmp    $0x3bf,%edi
f0102b69:	77 44                	ja     f0102baf <mem_init+0x1813>
				assert(pgdir[i] == 0);
f0102b6b:	83 3c b8 00          	cmpl   $0x0,(%eax,%edi,4)
f0102b6f:	74 d3                	je     f0102b44 <mem_init+0x17a8>
f0102b71:	8d 83 26 9b f7 ff    	lea    -0x864da(%ebx),%eax
f0102b77:	50                   	push   %eax
f0102b78:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102b7e:	50                   	push   %eax
f0102b7f:	68 63 03 00 00       	push   $0x363
f0102b84:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102b8a:	50                   	push   %eax
f0102b8b:	e8 25 d5 ff ff       	call   f01000b5 <_panic>
			assert(pgdir[i] & PTE_P);
f0102b90:	8d 83 04 9b f7 ff    	lea    -0x864fc(%ebx),%eax
f0102b96:	50                   	push   %eax
f0102b97:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102b9d:	50                   	push   %eax
f0102b9e:	68 5c 03 00 00       	push   $0x35c
f0102ba3:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102ba9:	50                   	push   %eax
f0102baa:	e8 06 d5 ff ff       	call   f01000b5 <_panic>
				assert(pgdir[i] & PTE_P);
f0102baf:	8b 14 b8             	mov    (%eax,%edi,4),%edx
f0102bb2:	f6 c2 01             	test   $0x1,%dl
f0102bb5:	74 24                	je     f0102bdb <mem_init+0x183f>
				assert(pgdir[i] & PTE_W);
f0102bb7:	f6 c2 02             	test   $0x2,%dl
f0102bba:	75 88                	jne    f0102b44 <mem_init+0x17a8>
f0102bbc:	8d 83 15 9b f7 ff    	lea    -0x864eb(%ebx),%eax
f0102bc2:	50                   	push   %eax
f0102bc3:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102bc9:	50                   	push   %eax
f0102bca:	68 61 03 00 00       	push   $0x361
f0102bcf:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102bd5:	50                   	push   %eax
f0102bd6:	e8 da d4 ff ff       	call   f01000b5 <_panic>
				assert(pgdir[i] & PTE_P);
f0102bdb:	8d 83 04 9b f7 ff    	lea    -0x864fc(%ebx),%eax
f0102be1:	50                   	push   %eax
f0102be2:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102be8:	50                   	push   %eax
f0102be9:	68 60 03 00 00       	push   $0x360
f0102bee:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102bf4:	50                   	push   %eax
f0102bf5:	e8 bb d4 ff ff       	call   f01000b5 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102bfa:	83 ec 0c             	sub    $0xc,%esp
f0102bfd:	8d 83 94 97 f7 ff    	lea    -0x8686c(%ebx),%eax
f0102c03:	50                   	push   %eax
f0102c04:	e8 70 0a 00 00       	call   f0103679 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102c09:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0102c0f:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102c11:	83 c4 10             	add    $0x10,%esp
f0102c14:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c19:	0f 86 30 02 00 00    	jbe    f0102e4f <mem_init+0x1ab3>
	return (physaddr_t)kva - KERNBASE;
f0102c1f:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102c24:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102c27:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c2c:	e8 cb df ff ff       	call   f0100bfc <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102c31:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102c34:	83 e0 f3             	and    $0xfffffff3,%eax
f0102c37:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102c3c:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102c3f:	83 ec 0c             	sub    $0xc,%esp
f0102c42:	6a 00                	push   $0x0
f0102c44:	e8 fa e3 ff ff       	call   f0101043 <page_alloc>
f0102c49:	89 c6                	mov    %eax,%esi
f0102c4b:	83 c4 10             	add    $0x10,%esp
f0102c4e:	85 c0                	test   %eax,%eax
f0102c50:	0f 84 12 02 00 00    	je     f0102e68 <mem_init+0x1acc>
	assert((pp1 = page_alloc(0)));
f0102c56:	83 ec 0c             	sub    $0xc,%esp
f0102c59:	6a 00                	push   $0x0
f0102c5b:	e8 e3 e3 ff ff       	call   f0101043 <page_alloc>
f0102c60:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102c63:	83 c4 10             	add    $0x10,%esp
f0102c66:	85 c0                	test   %eax,%eax
f0102c68:	0f 84 19 02 00 00    	je     f0102e87 <mem_init+0x1aeb>
	assert((pp2 = page_alloc(0)));
f0102c6e:	83 ec 0c             	sub    $0xc,%esp
f0102c71:	6a 00                	push   $0x0
f0102c73:	e8 cb e3 ff ff       	call   f0101043 <page_alloc>
f0102c78:	89 c7                	mov    %eax,%edi
f0102c7a:	83 c4 10             	add    $0x10,%esp
f0102c7d:	85 c0                	test   %eax,%eax
f0102c7f:	0f 84 21 02 00 00    	je     f0102ea6 <mem_init+0x1b0a>
	page_free(pp0);
f0102c85:	83 ec 0c             	sub    $0xc,%esp
f0102c88:	56                   	push   %esi
f0102c89:	e8 44 e4 ff ff       	call   f01010d2 <page_free>
	return (pp - pages) << PGSHIFT;
f0102c8e:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f0102c94:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102c97:	2b 08                	sub    (%eax),%ecx
f0102c99:	89 c8                	mov    %ecx,%eax
f0102c9b:	c1 f8 03             	sar    $0x3,%eax
f0102c9e:	89 c2                	mov    %eax,%edx
f0102ca0:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102ca3:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102ca8:	83 c4 10             	add    $0x10,%esp
f0102cab:	c7 c1 08 f0 18 f0    	mov    $0xf018f008,%ecx
f0102cb1:	3b 01                	cmp    (%ecx),%eax
f0102cb3:	0f 83 0c 02 00 00    	jae    f0102ec5 <mem_init+0x1b29>
	memset(page2kva(pp1), 1, PGSIZE);
f0102cb9:	83 ec 04             	sub    $0x4,%esp
f0102cbc:	68 00 10 00 00       	push   $0x1000
f0102cc1:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102cc3:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102cc9:	52                   	push   %edx
f0102cca:	e8 50 1a 00 00       	call   f010471f <memset>
	return (pp - pages) << PGSHIFT;
f0102ccf:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f0102cd5:	89 f9                	mov    %edi,%ecx
f0102cd7:	2b 08                	sub    (%eax),%ecx
f0102cd9:	89 c8                	mov    %ecx,%eax
f0102cdb:	c1 f8 03             	sar    $0x3,%eax
f0102cde:	89 c2                	mov    %eax,%edx
f0102ce0:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102ce3:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102ce8:	83 c4 10             	add    $0x10,%esp
f0102ceb:	c7 c1 08 f0 18 f0    	mov    $0xf018f008,%ecx
f0102cf1:	3b 01                	cmp    (%ecx),%eax
f0102cf3:	0f 83 e2 01 00 00    	jae    f0102edb <mem_init+0x1b3f>
	memset(page2kva(pp2), 2, PGSIZE);
f0102cf9:	83 ec 04             	sub    $0x4,%esp
f0102cfc:	68 00 10 00 00       	push   $0x1000
f0102d01:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102d03:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102d09:	52                   	push   %edx
f0102d0a:	e8 10 1a 00 00       	call   f010471f <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102d0f:	6a 02                	push   $0x2
f0102d11:	68 00 10 00 00       	push   $0x1000
f0102d16:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102d19:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0102d1f:	ff 30                	pushl  (%eax)
f0102d21:	e8 e8 e5 ff ff       	call   f010130e <page_insert>
	assert(pp1->pp_ref == 1);
f0102d26:	83 c4 20             	add    $0x20,%esp
f0102d29:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d2c:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102d31:	0f 85 ba 01 00 00    	jne    f0102ef1 <mem_init+0x1b55>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102d37:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102d3e:	01 01 01 
f0102d41:	0f 85 c9 01 00 00    	jne    f0102f10 <mem_init+0x1b74>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102d47:	6a 02                	push   $0x2
f0102d49:	68 00 10 00 00       	push   $0x1000
f0102d4e:	57                   	push   %edi
f0102d4f:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0102d55:	ff 30                	pushl  (%eax)
f0102d57:	e8 b2 e5 ff ff       	call   f010130e <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102d5c:	83 c4 10             	add    $0x10,%esp
f0102d5f:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102d66:	02 02 02 
f0102d69:	0f 85 c0 01 00 00    	jne    f0102f2f <mem_init+0x1b93>
	assert(pp2->pp_ref == 1);
f0102d6f:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102d74:	0f 85 d4 01 00 00    	jne    f0102f4e <mem_init+0x1bb2>
	assert(pp1->pp_ref == 0);
f0102d7a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d7d:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102d82:	0f 85 e5 01 00 00    	jne    f0102f6d <mem_init+0x1bd1>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d88:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d8f:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102d92:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f0102d98:	89 f9                	mov    %edi,%ecx
f0102d9a:	2b 08                	sub    (%eax),%ecx
f0102d9c:	89 c8                	mov    %ecx,%eax
f0102d9e:	c1 f8 03             	sar    $0x3,%eax
f0102da1:	89 c2                	mov    %eax,%edx
f0102da3:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102da6:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102dab:	c7 c1 08 f0 18 f0    	mov    $0xf018f008,%ecx
f0102db1:	3b 01                	cmp    (%ecx),%eax
f0102db3:	0f 83 d3 01 00 00    	jae    f0102f8c <mem_init+0x1bf0>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102db9:	81 ba 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%edx)
f0102dc0:	03 03 03 
f0102dc3:	0f 85 d9 01 00 00    	jne    f0102fa2 <mem_init+0x1c06>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102dc9:	83 ec 08             	sub    $0x8,%esp
f0102dcc:	68 00 10 00 00       	push   $0x1000
f0102dd1:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0102dd7:	ff 30                	pushl  (%eax)
f0102dd9:	e8 ea e4 ff ff       	call   f01012c8 <page_remove>
	assert(pp2->pp_ref == 0);
f0102dde:	83 c4 10             	add    $0x10,%esp
f0102de1:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102de6:	0f 85 d5 01 00 00    	jne    f0102fc1 <mem_init+0x1c25>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102dec:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0102df2:	8b 08                	mov    (%eax),%ecx
f0102df4:	8b 11                	mov    (%ecx),%edx
f0102df6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102dfc:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f0102e02:	89 f7                	mov    %esi,%edi
f0102e04:	2b 38                	sub    (%eax),%edi
f0102e06:	89 f8                	mov    %edi,%eax
f0102e08:	c1 f8 03             	sar    $0x3,%eax
f0102e0b:	c1 e0 0c             	shl    $0xc,%eax
f0102e0e:	39 c2                	cmp    %eax,%edx
f0102e10:	0f 85 ca 01 00 00    	jne    f0102fe0 <mem_init+0x1c44>
	kern_pgdir[0] = 0;
f0102e16:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102e1c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102e21:	0f 85 d8 01 00 00    	jne    f0102fff <mem_init+0x1c63>
	pp0->pp_ref = 0;
f0102e27:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102e2d:	83 ec 0c             	sub    $0xc,%esp
f0102e30:	56                   	push   %esi
f0102e31:	e8 9c e2 ff ff       	call   f01010d2 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e36:	8d 83 28 98 f7 ff    	lea    -0x867d8(%ebx),%eax
f0102e3c:	89 04 24             	mov    %eax,(%esp)
f0102e3f:	e8 35 08 00 00       	call   f0103679 <cprintf>
}
f0102e44:	83 c4 10             	add    $0x10,%esp
f0102e47:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e4a:	5b                   	pop    %ebx
f0102e4b:	5e                   	pop    %esi
f0102e4c:	5f                   	pop    %edi
f0102e4d:	5d                   	pop    %ebp
f0102e4e:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e4f:	50                   	push   %eax
f0102e50:	8d 83 10 92 f7 ff    	lea    -0x86df0(%ebx),%eax
f0102e56:	50                   	push   %eax
f0102e57:	68 f1 00 00 00       	push   $0xf1
f0102e5c:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102e62:	50                   	push   %eax
f0102e63:	e8 4d d2 ff ff       	call   f01000b5 <_panic>
	assert((pp0 = page_alloc(0)));
f0102e68:	8d 83 22 99 f7 ff    	lea    -0x866de(%ebx),%eax
f0102e6e:	50                   	push   %eax
f0102e6f:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102e75:	50                   	push   %eax
f0102e76:	68 23 04 00 00       	push   $0x423
f0102e7b:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102e81:	50                   	push   %eax
f0102e82:	e8 2e d2 ff ff       	call   f01000b5 <_panic>
	assert((pp1 = page_alloc(0)));
f0102e87:	8d 83 38 99 f7 ff    	lea    -0x866c8(%ebx),%eax
f0102e8d:	50                   	push   %eax
f0102e8e:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102e94:	50                   	push   %eax
f0102e95:	68 24 04 00 00       	push   $0x424
f0102e9a:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102ea0:	50                   	push   %eax
f0102ea1:	e8 0f d2 ff ff       	call   f01000b5 <_panic>
	assert((pp2 = page_alloc(0)));
f0102ea6:	8d 83 4e 99 f7 ff    	lea    -0x866b2(%ebx),%eax
f0102eac:	50                   	push   %eax
f0102ead:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102eb3:	50                   	push   %eax
f0102eb4:	68 25 04 00 00       	push   $0x425
f0102eb9:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102ebf:	50                   	push   %eax
f0102ec0:	e8 f0 d1 ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ec5:	52                   	push   %edx
f0102ec6:	8d 83 60 90 f7 ff    	lea    -0x86fa0(%ebx),%eax
f0102ecc:	50                   	push   %eax
f0102ecd:	6a 56                	push   $0x56
f0102ecf:	8d 83 5d 98 f7 ff    	lea    -0x867a3(%ebx),%eax
f0102ed5:	50                   	push   %eax
f0102ed6:	e8 da d1 ff ff       	call   f01000b5 <_panic>
f0102edb:	52                   	push   %edx
f0102edc:	8d 83 60 90 f7 ff    	lea    -0x86fa0(%ebx),%eax
f0102ee2:	50                   	push   %eax
f0102ee3:	6a 56                	push   $0x56
f0102ee5:	8d 83 5d 98 f7 ff    	lea    -0x867a3(%ebx),%eax
f0102eeb:	50                   	push   %eax
f0102eec:	e8 c4 d1 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 1);
f0102ef1:	8d 83 1f 9a f7 ff    	lea    -0x865e1(%ebx),%eax
f0102ef7:	50                   	push   %eax
f0102ef8:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102efe:	50                   	push   %eax
f0102eff:	68 2a 04 00 00       	push   $0x42a
f0102f04:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102f0a:	50                   	push   %eax
f0102f0b:	e8 a5 d1 ff ff       	call   f01000b5 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102f10:	8d 83 b4 97 f7 ff    	lea    -0x8684c(%ebx),%eax
f0102f16:	50                   	push   %eax
f0102f17:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102f1d:	50                   	push   %eax
f0102f1e:	68 2b 04 00 00       	push   $0x42b
f0102f23:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102f29:	50                   	push   %eax
f0102f2a:	e8 86 d1 ff ff       	call   f01000b5 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102f2f:	8d 83 d8 97 f7 ff    	lea    -0x86828(%ebx),%eax
f0102f35:	50                   	push   %eax
f0102f36:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102f3c:	50                   	push   %eax
f0102f3d:	68 2d 04 00 00       	push   $0x42d
f0102f42:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102f48:	50                   	push   %eax
f0102f49:	e8 67 d1 ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 1);
f0102f4e:	8d 83 41 9a f7 ff    	lea    -0x865bf(%ebx),%eax
f0102f54:	50                   	push   %eax
f0102f55:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102f5b:	50                   	push   %eax
f0102f5c:	68 2e 04 00 00       	push   $0x42e
f0102f61:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102f67:	50                   	push   %eax
f0102f68:	e8 48 d1 ff ff       	call   f01000b5 <_panic>
	assert(pp1->pp_ref == 0);
f0102f6d:	8d 83 ab 9a f7 ff    	lea    -0x86555(%ebx),%eax
f0102f73:	50                   	push   %eax
f0102f74:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102f7a:	50                   	push   %eax
f0102f7b:	68 2f 04 00 00       	push   $0x42f
f0102f80:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102f86:	50                   	push   %eax
f0102f87:	e8 29 d1 ff ff       	call   f01000b5 <_panic>
f0102f8c:	52                   	push   %edx
f0102f8d:	8d 83 60 90 f7 ff    	lea    -0x86fa0(%ebx),%eax
f0102f93:	50                   	push   %eax
f0102f94:	6a 56                	push   $0x56
f0102f96:	8d 83 5d 98 f7 ff    	lea    -0x867a3(%ebx),%eax
f0102f9c:	50                   	push   %eax
f0102f9d:	e8 13 d1 ff ff       	call   f01000b5 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102fa2:	8d 83 fc 97 f7 ff    	lea    -0x86804(%ebx),%eax
f0102fa8:	50                   	push   %eax
f0102fa9:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102faf:	50                   	push   %eax
f0102fb0:	68 31 04 00 00       	push   $0x431
f0102fb5:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102fbb:	50                   	push   %eax
f0102fbc:	e8 f4 d0 ff ff       	call   f01000b5 <_panic>
	assert(pp2->pp_ref == 0);
f0102fc1:	8d 83 79 9a f7 ff    	lea    -0x86587(%ebx),%eax
f0102fc7:	50                   	push   %eax
f0102fc8:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102fce:	50                   	push   %eax
f0102fcf:	68 33 04 00 00       	push   $0x433
f0102fd4:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102fda:	50                   	push   %eax
f0102fdb:	e8 d5 d0 ff ff       	call   f01000b5 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102fe0:	8d 83 0c 93 f7 ff    	lea    -0x86cf4(%ebx),%eax
f0102fe6:	50                   	push   %eax
f0102fe7:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0102fed:	50                   	push   %eax
f0102fee:	68 36 04 00 00       	push   $0x436
f0102ff3:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0102ff9:	50                   	push   %eax
f0102ffa:	e8 b6 d0 ff ff       	call   f01000b5 <_panic>
	assert(pp0->pp_ref == 1);
f0102fff:	8d 83 30 9a f7 ff    	lea    -0x865d0(%ebx),%eax
f0103005:	50                   	push   %eax
f0103006:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f010300c:	50                   	push   %eax
f010300d:	68 38 04 00 00       	push   $0x438
f0103012:	8d 83 51 98 f7 ff    	lea    -0x867af(%ebx),%eax
f0103018:	50                   	push   %eax
f0103019:	e8 97 d0 ff ff       	call   f01000b5 <_panic>

f010301e <tlb_invalidate>:
{
f010301e:	f3 0f 1e fb          	endbr32 
f0103022:	55                   	push   %ebp
f0103023:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0103025:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103028:	0f 01 38             	invlpg (%eax)
}
f010302b:	5d                   	pop    %ebp
f010302c:	c3                   	ret    

f010302d <user_mem_check>:
{
f010302d:	f3 0f 1e fb          	endbr32 
}
f0103031:	b8 00 00 00 00       	mov    $0x0,%eax
f0103036:	c3                   	ret    

f0103037 <user_mem_assert>:
{
f0103037:	f3 0f 1e fb          	endbr32 
}
f010303b:	c3                   	ret    

f010303c <__x86.get_pc_thunk.dx>:
f010303c:	8b 14 24             	mov    (%esp),%edx
f010303f:	c3                   	ret    

f0103040 <__x86.get_pc_thunk.cx>:
f0103040:	8b 0c 24             	mov    (%esp),%ecx
f0103043:	c3                   	ret    

f0103044 <__x86.get_pc_thunk.di>:
f0103044:	8b 3c 24             	mov    (%esp),%edi
f0103047:	c3                   	ret    

f0103048 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0103048:	f3 0f 1e fb          	endbr32 
f010304c:	55                   	push   %ebp
f010304d:	89 e5                	mov    %esp,%ebp
f010304f:	53                   	push   %ebx
f0103050:	e8 eb ff ff ff       	call   f0103040 <__x86.get_pc_thunk.cx>
f0103055:	81 c1 c7 8f 08 00    	add    $0x88fc7,%ecx
f010305b:	8b 45 08             	mov    0x8(%ebp),%eax
f010305e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0103061:	85 c0                	test   %eax,%eax
f0103063:	74 42                	je     f01030a7 <envid2env+0x5f>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103065:	89 c2                	mov    %eax,%edx
f0103067:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010306d:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103070:	c1 e2 05             	shl    $0x5,%edx
f0103073:	03 91 2c 23 00 00    	add    0x232c(%ecx),%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103079:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f010307d:	74 35                	je     f01030b4 <envid2env+0x6c>
f010307f:	39 42 48             	cmp    %eax,0x48(%edx)
f0103082:	75 30                	jne    f01030b4 <envid2env+0x6c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103084:	84 db                	test   %bl,%bl
f0103086:	74 12                	je     f010309a <envid2env+0x52>
f0103088:	8b 81 28 23 00 00    	mov    0x2328(%ecx),%eax
f010308e:	39 d0                	cmp    %edx,%eax
f0103090:	74 08                	je     f010309a <envid2env+0x52>
f0103092:	8b 40 48             	mov    0x48(%eax),%eax
f0103095:	39 42 4c             	cmp    %eax,0x4c(%edx)
f0103098:	75 2a                	jne    f01030c4 <envid2env+0x7c>
		*env_store = 0;
		return -E_BAD_ENV;
	}

	*env_store = e;
f010309a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010309d:	89 10                	mov    %edx,(%eax)
	return 0;
f010309f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01030a4:	5b                   	pop    %ebx
f01030a5:	5d                   	pop    %ebp
f01030a6:	c3                   	ret    
		*env_store = curenv;
f01030a7:	8b 91 28 23 00 00    	mov    0x2328(%ecx),%edx
f01030ad:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01030b0:	89 13                	mov    %edx,(%ebx)
		return 0;
f01030b2:	eb f0                	jmp    f01030a4 <envid2env+0x5c>
		*env_store = 0;
f01030b4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030b7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01030bd:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01030c2:	eb e0                	jmp    f01030a4 <envid2env+0x5c>
		*env_store = 0;
f01030c4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030c7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01030cd:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01030d2:	eb d0                	jmp    f01030a4 <envid2env+0x5c>

f01030d4 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01030d4:	f3 0f 1e fb          	endbr32 
f01030d8:	e8 4a d6 ff ff       	call   f0100727 <__x86.get_pc_thunk.ax>
f01030dd:	05 3f 8f 08 00       	add    $0x88f3f,%eax
	asm volatile("lgdt (%0)" : : "r" (p));
f01030e2:	8d 80 e4 1f 00 00    	lea    0x1fe4(%eax),%eax
f01030e8:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f01030eb:	b8 23 00 00 00       	mov    $0x23,%eax
f01030f0:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f01030f2:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f01030f4:	b8 10 00 00 00       	mov    $0x10,%eax
f01030f9:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f01030fb:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f01030fd:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f01030ff:	ea 06 31 10 f0 08 00 	ljmp   $0x8,$0xf0103106
	asm volatile("lldt %0" : : "r" (sel));
f0103106:	b8 00 00 00 00       	mov    $0x0,%eax
f010310b:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f010310e:	c3                   	ret    

f010310f <env_init>:
{
f010310f:	f3 0f 1e fb          	endbr32 
f0103113:	55                   	push   %ebp
f0103114:	89 e5                	mov    %esp,%ebp
f0103116:	57                   	push   %edi
f0103117:	56                   	push   %esi
f0103118:	53                   	push   %ebx
f0103119:	83 ec 0c             	sub    $0xc,%esp
f010311c:	e8 23 ff ff ff       	call   f0103044 <__x86.get_pc_thunk.di>
f0103121:	81 c7 fb 8e 08 00    	add    $0x88efb,%edi
		envs[i].env_id = 0;
f0103127:	8b b7 2c 23 00 00    	mov    0x232c(%edi),%esi
f010312d:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0103133:	89 f3                	mov    %esi,%ebx
f0103135:	ba 00 00 00 00       	mov    $0x0,%edx
f010313a:	89 d1                	mov    %edx,%ecx
f010313c:	89 c2                	mov    %eax,%edx
f010313e:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f0103145:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f010314c:	89 48 44             	mov    %ecx,0x44(%eax)
f010314f:	83 e8 60             	sub    $0x60,%eax
	for(int i = NENV - 1; i>=0 ;i--)
f0103152:	39 da                	cmp    %ebx,%edx
f0103154:	75 e4                	jne    f010313a <env_init+0x2b>
f0103156:	89 b7 30 23 00 00    	mov    %esi,0x2330(%edi)
	env_init_percpu();
f010315c:	e8 73 ff ff ff       	call   f01030d4 <env_init_percpu>
}
f0103161:	83 c4 0c             	add    $0xc,%esp
f0103164:	5b                   	pop    %ebx
f0103165:	5e                   	pop    %esi
f0103166:	5f                   	pop    %edi
f0103167:	5d                   	pop    %ebp
f0103168:	c3                   	ret    

f0103169 <env_alloc>:
//	-E_NO_FREE_ENV if all NENV environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0103169:	f3 0f 1e fb          	endbr32 
f010316d:	55                   	push   %ebp
f010316e:	89 e5                	mov    %esp,%ebp
f0103170:	57                   	push   %edi
f0103171:	56                   	push   %esi
f0103172:	53                   	push   %ebx
f0103173:	83 ec 0c             	sub    $0xc,%esp
f0103176:	e8 f8 cf ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f010317b:	81 c3 a1 8e 08 00    	add    $0x88ea1,%ebx
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103181:	8b b3 30 23 00 00    	mov    0x2330(%ebx),%esi
f0103187:	85 f6                	test   %esi,%esi
f0103189:	0f 84 84 01 00 00    	je     f0103313 <env_alloc+0x1aa>
	if (!(p = page_alloc(ALLOC_ZERO)))
f010318f:	83 ec 0c             	sub    $0xc,%esp
f0103192:	6a 01                	push   $0x1
f0103194:	e8 aa de ff ff       	call   f0101043 <page_alloc>
f0103199:	83 c4 10             	add    $0x10,%esp
f010319c:	85 c0                	test   %eax,%eax
f010319e:	0f 84 76 01 00 00    	je     f010331a <env_alloc+0x1b1>
	return (pp - pages) << PGSHIFT;
f01031a4:	c7 c2 10 f0 18 f0    	mov    $0xf018f010,%edx
f01031aa:	89 c7                	mov    %eax,%edi
f01031ac:	2b 3a                	sub    (%edx),%edi
f01031ae:	89 fa                	mov    %edi,%edx
f01031b0:	c1 fa 03             	sar    $0x3,%edx
f01031b3:	89 d1                	mov    %edx,%ecx
f01031b5:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f01031b8:	81 e2 ff ff 0f 00    	and    $0xfffff,%edx
f01031be:	c7 c7 08 f0 18 f0    	mov    $0xf018f008,%edi
f01031c4:	3b 17                	cmp    (%edi),%edx
f01031c6:	0f 83 18 01 00 00    	jae    f01032e4 <env_alloc+0x17b>
	return (void *)(pa + KERNBASE);
f01031cc:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f01031d2:	89 4e 5c             	mov    %ecx,0x5c(%esi)
	p->pp_ref++;
f01031d5:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f01031da:	b8 00 00 00 00       	mov    $0x0,%eax
		e->env_pgdir[i] = 0;
f01031df:	8b 56 5c             	mov    0x5c(%esi),%edx
f01031e2:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f01031e9:	83 c0 04             	add    $0x4,%eax
	for(int i = 0;i<PDX(UTOP);i++)
f01031ec:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f01031f1:	75 ec                	jne    f01031df <env_alloc+0x76>
		e->env_pgdir[i] = kern_pgdir[i];
f01031f3:	c7 c7 0c f0 18 f0    	mov    $0xf018f00c,%edi
f01031f9:	8b 17                	mov    (%edi),%edx
f01031fb:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f01031fe:	8b 56 5c             	mov    0x5c(%esi),%edx
f0103201:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0103204:	83 c0 04             	add    $0x4,%eax
	for(int i = PDX(UTOP);i<NPDENTRIES;i++)
f0103207:	3d 00 10 00 00       	cmp    $0x1000,%eax
f010320c:	75 eb                	jne    f01031f9 <env_alloc+0x90>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f010320e:	8b 46 5c             	mov    0x5c(%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f0103211:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103216:	0f 86 de 00 00 00    	jbe    f01032fa <env_alloc+0x191>
	return (physaddr_t)kva - KERNBASE;
f010321c:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103222:	83 ca 05             	or     $0x5,%edx
f0103225:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f010322b:	8b 46 48             	mov    0x48(%esi),%eax
f010322e:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
		generation = 1 << ENVGENSHIFT;
f0103233:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0103238:	ba 00 10 00 00       	mov    $0x1000,%edx
f010323d:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103240:	89 f2                	mov    %esi,%edx
f0103242:	2b 93 2c 23 00 00    	sub    0x232c(%ebx),%edx
f0103248:	c1 fa 05             	sar    $0x5,%edx
f010324b:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0103251:	09 d0                	or     %edx,%eax
f0103253:	89 46 48             	mov    %eax,0x48(%esi)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103256:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103259:	89 46 4c             	mov    %eax,0x4c(%esi)
	e->env_type = ENV_TYPE_USER;
f010325c:	c7 46 50 00 00 00 00 	movl   $0x0,0x50(%esi)
	e->env_status = ENV_RUNNABLE;
f0103263:	c7 46 54 02 00 00 00 	movl   $0x2,0x54(%esi)
	e->env_runs = 0;
f010326a:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103271:	83 ec 04             	sub    $0x4,%esp
f0103274:	6a 44                	push   $0x44
f0103276:	6a 00                	push   $0x0
f0103278:	56                   	push   %esi
f0103279:	e8 a1 14 00 00       	call   f010471f <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f010327e:	66 c7 46 24 23 00    	movw   $0x23,0x24(%esi)
	e->env_tf.tf_es = GD_UD | 3;
f0103284:	66 c7 46 20 23 00    	movw   $0x23,0x20(%esi)
	e->env_tf.tf_ss = GD_UD | 3;
f010328a:	66 c7 46 40 23 00    	movw   $0x23,0x40(%esi)
	e->env_tf.tf_esp = USTACKTOP;
f0103290:	c7 46 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%esi)
	e->env_tf.tf_cs = GD_UT | 3;
f0103297:	66 c7 46 34 1b 00    	movw   $0x1b,0x34(%esi)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f010329d:	8b 46 44             	mov    0x44(%esi),%eax
f01032a0:	89 83 30 23 00 00    	mov    %eax,0x2330(%ebx)
	*newenv_store = e;
f01032a6:	8b 45 08             	mov    0x8(%ebp),%eax
f01032a9:	89 30                	mov    %esi,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01032ab:	8b 4e 48             	mov    0x48(%esi),%ecx
f01032ae:	8b 83 28 23 00 00    	mov    0x2328(%ebx),%eax
f01032b4:	83 c4 10             	add    $0x10,%esp
f01032b7:	ba 00 00 00 00       	mov    $0x0,%edx
f01032bc:	85 c0                	test   %eax,%eax
f01032be:	74 03                	je     f01032c3 <env_alloc+0x15a>
f01032c0:	8b 50 48             	mov    0x48(%eax),%edx
f01032c3:	83 ec 04             	sub    $0x4,%esp
f01032c6:	51                   	push   %ecx
f01032c7:	52                   	push   %edx
f01032c8:	8d 83 75 9b f7 ff    	lea    -0x8648b(%ebx),%eax
f01032ce:	50                   	push   %eax
f01032cf:	e8 a5 03 00 00       	call   f0103679 <cprintf>
	return 0;
f01032d4:	83 c4 10             	add    $0x10,%esp
f01032d7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01032dc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01032df:	5b                   	pop    %ebx
f01032e0:	5e                   	pop    %esi
f01032e1:	5f                   	pop    %edi
f01032e2:	5d                   	pop    %ebp
f01032e3:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01032e4:	51                   	push   %ecx
f01032e5:	8d 83 60 90 f7 ff    	lea    -0x86fa0(%ebx),%eax
f01032eb:	50                   	push   %eax
f01032ec:	6a 56                	push   $0x56
f01032ee:	8d 83 5d 98 f7 ff    	lea    -0x867a3(%ebx),%eax
f01032f4:	50                   	push   %eax
f01032f5:	e8 bb cd ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01032fa:	50                   	push   %eax
f01032fb:	8d 83 10 92 f7 ff    	lea    -0x86df0(%ebx),%eax
f0103301:	50                   	push   %eax
f0103302:	68 d0 00 00 00       	push   $0xd0
f0103307:	8d 83 6a 9b f7 ff    	lea    -0x86496(%ebx),%eax
f010330d:	50                   	push   %eax
f010330e:	e8 a2 cd ff ff       	call   f01000b5 <_panic>
		return -E_NO_FREE_ENV;
f0103313:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103318:	eb c2                	jmp    f01032dc <env_alloc+0x173>
		return -E_NO_MEM;
f010331a:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010331f:	eb bb                	jmp    f01032dc <env_alloc+0x173>

f0103321 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103321:	f3 0f 1e fb          	endbr32 
	// LAB 3: Your code here.
}
f0103325:	c3                   	ret    

f0103326 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103326:	f3 0f 1e fb          	endbr32 
f010332a:	55                   	push   %ebp
f010332b:	89 e5                	mov    %esp,%ebp
f010332d:	57                   	push   %edi
f010332e:	56                   	push   %esi
f010332f:	53                   	push   %ebx
f0103330:	83 ec 2c             	sub    $0x2c,%esp
f0103333:	e8 3b ce ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103338:	81 c3 e4 8c 08 00    	add    $0x88ce4,%ebx
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f010333e:	8b 93 28 23 00 00    	mov    0x2328(%ebx),%edx
f0103344:	3b 55 08             	cmp    0x8(%ebp),%edx
f0103347:	74 47                	je     f0103390 <env_free+0x6a>
		lcr3(PADDR(kern_pgdir));

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103349:	8b 45 08             	mov    0x8(%ebp),%eax
f010334c:	8b 48 48             	mov    0x48(%eax),%ecx
f010334f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103354:	85 d2                	test   %edx,%edx
f0103356:	74 03                	je     f010335b <env_free+0x35>
f0103358:	8b 42 48             	mov    0x48(%edx),%eax
f010335b:	83 ec 04             	sub    $0x4,%esp
f010335e:	51                   	push   %ecx
f010335f:	50                   	push   %eax
f0103360:	8d 83 8a 9b f7 ff    	lea    -0x86476(%ebx),%eax
f0103366:	50                   	push   %eax
f0103367:	e8 0d 03 00 00       	call   f0103679 <cprintf>
f010336c:	83 c4 10             	add    $0x10,%esp
f010336f:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	if (PGNUM(pa) >= npages)
f0103376:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f010337c:	89 45 d8             	mov    %eax,-0x28(%ebp)
	if (PGNUM(pa) >= npages)
f010337f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	return &pages[PGNUM(pa)];
f0103382:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f0103388:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010338b:	e9 bf 00 00 00       	jmp    f010344f <env_free+0x129>
		lcr3(PADDR(kern_pgdir));
f0103390:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0103396:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103398:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010339d:	76 10                	jbe    f01033af <env_free+0x89>
	return (physaddr_t)kva - KERNBASE;
f010339f:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01033a4:	0f 22 d8             	mov    %eax,%cr3
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01033a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01033aa:	8b 48 48             	mov    0x48(%eax),%ecx
f01033ad:	eb a9                	jmp    f0103358 <env_free+0x32>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033af:	50                   	push   %eax
f01033b0:	8d 83 10 92 f7 ff    	lea    -0x86df0(%ebx),%eax
f01033b6:	50                   	push   %eax
f01033b7:	68 9c 01 00 00       	push   $0x19c
f01033bc:	8d 83 6a 9b f7 ff    	lea    -0x86496(%ebx),%eax
f01033c2:	50                   	push   %eax
f01033c3:	e8 ed cc ff ff       	call   f01000b5 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01033c8:	57                   	push   %edi
f01033c9:	8d 83 60 90 f7 ff    	lea    -0x86fa0(%ebx),%eax
f01033cf:	50                   	push   %eax
f01033d0:	68 ab 01 00 00       	push   $0x1ab
f01033d5:	8d 83 6a 9b f7 ff    	lea    -0x86496(%ebx),%eax
f01033db:	50                   	push   %eax
f01033dc:	e8 d4 cc ff ff       	call   f01000b5 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01033e1:	83 ec 08             	sub    $0x8,%esp
f01033e4:	89 f0                	mov    %esi,%eax
f01033e6:	c1 e0 0c             	shl    $0xc,%eax
f01033e9:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01033ec:	50                   	push   %eax
f01033ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01033f0:	ff 70 5c             	pushl  0x5c(%eax)
f01033f3:	e8 d0 de ff ff       	call   f01012c8 <page_remove>
f01033f8:	83 c4 10             	add    $0x10,%esp
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01033fb:	83 c6 01             	add    $0x1,%esi
f01033fe:	83 c7 04             	add    $0x4,%edi
f0103401:	81 fe 00 04 00 00    	cmp    $0x400,%esi
f0103407:	74 07                	je     f0103410 <env_free+0xea>
			if (pt[pteno] & PTE_P)
f0103409:	f6 07 01             	testb  $0x1,(%edi)
f010340c:	74 ed                	je     f01033fb <env_free+0xd5>
f010340e:	eb d1                	jmp    f01033e1 <env_free+0xbb>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103410:	8b 45 08             	mov    0x8(%ebp),%eax
f0103413:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103416:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103419:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f0103420:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103423:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103426:	3b 10                	cmp    (%eax),%edx
f0103428:	73 67                	jae    f0103491 <env_free+0x16b>
		page_decref(pa2page(pa));
f010342a:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f010342d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103430:	8b 00                	mov    (%eax),%eax
f0103432:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103435:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0103438:	50                   	push   %eax
f0103439:	e8 e7 dc ff ff       	call   f0101125 <page_decref>
f010343e:	83 c4 10             	add    $0x10,%esp
f0103441:	83 45 e0 04          	addl   $0x4,-0x20(%ebp)
f0103445:	8b 45 e0             	mov    -0x20(%ebp),%eax
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103448:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f010344d:	74 5a                	je     f01034a9 <env_free+0x183>
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010344f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103452:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103455:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103458:	8b 04 10             	mov    (%eax,%edx,1),%eax
f010345b:	a8 01                	test   $0x1,%al
f010345d:	74 e2                	je     f0103441 <env_free+0x11b>
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010345f:	89 c7                	mov    %eax,%edi
f0103461:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	if (PGNUM(pa) >= npages)
f0103467:	c1 e8 0c             	shr    $0xc,%eax
f010346a:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010346d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103470:	39 02                	cmp    %eax,(%edx)
f0103472:	0f 86 50 ff ff ff    	jbe    f01033c8 <env_free+0xa2>
	return (void *)(pa + KERNBASE);
f0103478:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
f010347e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103481:	c1 e0 14             	shl    $0x14,%eax
f0103484:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103487:	be 00 00 00 00       	mov    $0x0,%esi
f010348c:	e9 78 ff ff ff       	jmp    f0103409 <env_free+0xe3>
		panic("pa2page called with invalid pa");
f0103491:	83 ec 04             	sub    $0x4,%esp
f0103494:	8d 83 b4 91 f7 ff    	lea    -0x86e4c(%ebx),%eax
f010349a:	50                   	push   %eax
f010349b:	6a 4f                	push   $0x4f
f010349d:	8d 83 5d 98 f7 ff    	lea    -0x867a3(%ebx),%eax
f01034a3:	50                   	push   %eax
f01034a4:	e8 0c cc ff ff       	call   f01000b5 <_panic>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01034a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01034ac:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01034af:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034b4:	76 57                	jbe    f010350d <env_free+0x1e7>
	e->env_pgdir = 0;
f01034b6:	8b 55 08             	mov    0x8(%ebp),%edx
f01034b9:	c7 42 5c 00 00 00 00 	movl   $0x0,0x5c(%edx)
	return (physaddr_t)kva - KERNBASE;
f01034c0:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f01034c5:	c1 e8 0c             	shr    $0xc,%eax
f01034c8:	c7 c2 08 f0 18 f0    	mov    $0xf018f008,%edx
f01034ce:	3b 02                	cmp    (%edx),%eax
f01034d0:	73 54                	jae    f0103526 <env_free+0x200>
	page_decref(pa2page(pa));
f01034d2:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01034d5:	c7 c2 10 f0 18 f0    	mov    $0xf018f010,%edx
f01034db:	8b 12                	mov    (%edx),%edx
f01034dd:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01034e0:	50                   	push   %eax
f01034e1:	e8 3f dc ff ff       	call   f0101125 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01034e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01034e9:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	e->env_link = env_free_list;
f01034f0:	8b 83 30 23 00 00    	mov    0x2330(%ebx),%eax
f01034f6:	8b 55 08             	mov    0x8(%ebp),%edx
f01034f9:	89 42 44             	mov    %eax,0x44(%edx)
	env_free_list = e;
f01034fc:	89 93 30 23 00 00    	mov    %edx,0x2330(%ebx)
}
f0103502:	83 c4 10             	add    $0x10,%esp
f0103505:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103508:	5b                   	pop    %ebx
f0103509:	5e                   	pop    %esi
f010350a:	5f                   	pop    %edi
f010350b:	5d                   	pop    %ebp
f010350c:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010350d:	50                   	push   %eax
f010350e:	8d 83 10 92 f7 ff    	lea    -0x86df0(%ebx),%eax
f0103514:	50                   	push   %eax
f0103515:	68 b9 01 00 00       	push   $0x1b9
f010351a:	8d 83 6a 9b f7 ff    	lea    -0x86496(%ebx),%eax
f0103520:	50                   	push   %eax
f0103521:	e8 8f cb ff ff       	call   f01000b5 <_panic>
		panic("pa2page called with invalid pa");
f0103526:	83 ec 04             	sub    $0x4,%esp
f0103529:	8d 83 b4 91 f7 ff    	lea    -0x86e4c(%ebx),%eax
f010352f:	50                   	push   %eax
f0103530:	6a 4f                	push   $0x4f
f0103532:	8d 83 5d 98 f7 ff    	lea    -0x867a3(%ebx),%eax
f0103538:	50                   	push   %eax
f0103539:	e8 77 cb ff ff       	call   f01000b5 <_panic>

f010353e <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f010353e:	f3 0f 1e fb          	endbr32 
f0103542:	55                   	push   %ebp
f0103543:	89 e5                	mov    %esp,%ebp
f0103545:	53                   	push   %ebx
f0103546:	83 ec 10             	sub    $0x10,%esp
f0103549:	e8 25 cc ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f010354e:	81 c3 ce 8a 08 00    	add    $0x88ace,%ebx
	env_free(e);
f0103554:	ff 75 08             	pushl  0x8(%ebp)
f0103557:	e8 ca fd ff ff       	call   f0103326 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f010355c:	8d 83 34 9b f7 ff    	lea    -0x864cc(%ebx),%eax
f0103562:	89 04 24             	mov    %eax,(%esp)
f0103565:	e8 0f 01 00 00       	call   f0103679 <cprintf>
f010356a:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f010356d:	83 ec 0c             	sub    $0xc,%esp
f0103570:	6a 00                	push   $0x0
f0103572:	e8 ca d3 ff ff       	call   f0100941 <monitor>
f0103577:	83 c4 10             	add    $0x10,%esp
f010357a:	eb f1                	jmp    f010356d <env_destroy+0x2f>

f010357c <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f010357c:	f3 0f 1e fb          	endbr32 
f0103580:	55                   	push   %ebp
f0103581:	89 e5                	mov    %esp,%ebp
f0103583:	53                   	push   %ebx
f0103584:	83 ec 08             	sub    $0x8,%esp
f0103587:	e8 e7 cb ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f010358c:	81 c3 90 8a 08 00    	add    $0x88a90,%ebx
	asm volatile(
f0103592:	8b 65 08             	mov    0x8(%ebp),%esp
f0103595:	61                   	popa   
f0103596:	07                   	pop    %es
f0103597:	1f                   	pop    %ds
f0103598:	83 c4 08             	add    $0x8,%esp
f010359b:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f010359c:	8d 83 a0 9b f7 ff    	lea    -0x86460(%ebx),%eax
f01035a2:	50                   	push   %eax
f01035a3:	68 e2 01 00 00       	push   $0x1e2
f01035a8:	8d 83 6a 9b f7 ff    	lea    -0x86496(%ebx),%eax
f01035ae:	50                   	push   %eax
f01035af:	e8 01 cb ff ff       	call   f01000b5 <_panic>

f01035b4 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f01035b4:	f3 0f 1e fb          	endbr32 
f01035b8:	55                   	push   %ebp
f01035b9:	89 e5                	mov    %esp,%ebp
f01035bb:	53                   	push   %ebx
f01035bc:	83 ec 08             	sub    $0x8,%esp
f01035bf:	e8 af cb ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01035c4:	81 c3 58 8a 08 00    	add    $0x88a58,%ebx
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	panic("env_run not yet implemented");
f01035ca:	8d 83 ac 9b f7 ff    	lea    -0x86454(%ebx),%eax
f01035d0:	50                   	push   %eax
f01035d1:	68 01 02 00 00       	push   $0x201
f01035d6:	8d 83 6a 9b f7 ff    	lea    -0x86496(%ebx),%eax
f01035dc:	50                   	push   %eax
f01035dd:	e8 d3 ca ff ff       	call   f01000b5 <_panic>

f01035e2 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01035e2:	f3 0f 1e fb          	endbr32 
f01035e6:	55                   	push   %ebp
f01035e7:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01035e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01035ec:	ba 70 00 00 00       	mov    $0x70,%edx
f01035f1:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01035f2:	ba 71 00 00 00       	mov    $0x71,%edx
f01035f7:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01035f8:	0f b6 c0             	movzbl %al,%eax
}
f01035fb:	5d                   	pop    %ebp
f01035fc:	c3                   	ret    

f01035fd <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01035fd:	f3 0f 1e fb          	endbr32 
f0103601:	55                   	push   %ebp
f0103602:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103604:	8b 45 08             	mov    0x8(%ebp),%eax
f0103607:	ba 70 00 00 00       	mov    $0x70,%edx
f010360c:	ee                   	out    %al,(%dx)
f010360d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103610:	ba 71 00 00 00       	mov    $0x71,%edx
f0103615:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103616:	5d                   	pop    %ebp
f0103617:	c3                   	ret    

f0103618 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103618:	f3 0f 1e fb          	endbr32 
f010361c:	55                   	push   %ebp
f010361d:	89 e5                	mov    %esp,%ebp
f010361f:	53                   	push   %ebx
f0103620:	83 ec 10             	sub    $0x10,%esp
f0103623:	e8 4b cb ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103628:	81 c3 f4 89 08 00    	add    $0x889f4,%ebx
	cputchar(ch);
f010362e:	ff 75 08             	pushl  0x8(%ebp)
f0103631:	e8 be d0 ff ff       	call   f01006f4 <cputchar>
	*cnt++;
}
f0103636:	83 c4 10             	add    $0x10,%esp
f0103639:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010363c:	c9                   	leave  
f010363d:	c3                   	ret    

f010363e <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010363e:	f3 0f 1e fb          	endbr32 
f0103642:	55                   	push   %ebp
f0103643:	89 e5                	mov    %esp,%ebp
f0103645:	53                   	push   %ebx
f0103646:	83 ec 14             	sub    $0x14,%esp
f0103649:	e8 25 cb ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f010364e:	81 c3 ce 89 08 00    	add    $0x889ce,%ebx
	int cnt = 0;
f0103654:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010365b:	ff 75 0c             	pushl  0xc(%ebp)
f010365e:	ff 75 08             	pushl  0x8(%ebp)
f0103661:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103664:	50                   	push   %eax
f0103665:	8d 83 fc 75 f7 ff    	lea    -0x88a04(%ebx),%eax
f010366b:	50                   	push   %eax
f010366c:	e8 c4 08 00 00       	call   f0103f35 <vprintfmt>
	return cnt;
}
f0103671:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103674:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103677:	c9                   	leave  
f0103678:	c3                   	ret    

f0103679 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103679:	f3 0f 1e fb          	endbr32 
f010367d:	55                   	push   %ebp
f010367e:	89 e5                	mov    %esp,%ebp
f0103680:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103683:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103686:	50                   	push   %eax
f0103687:	ff 75 08             	pushl  0x8(%ebp)
f010368a:	e8 af ff ff ff       	call   f010363e <vcprintf>
	va_end(ap);

	return cnt;
}
f010368f:	c9                   	leave  
f0103690:	c3                   	ret    

f0103691 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103691:	f3 0f 1e fb          	endbr32 
f0103695:	55                   	push   %ebp
f0103696:	89 e5                	mov    %esp,%ebp
f0103698:	57                   	push   %edi
f0103699:	56                   	push   %esi
f010369a:	53                   	push   %ebx
f010369b:	83 ec 04             	sub    $0x4,%esp
f010369e:	e8 d0 ca ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01036a3:	81 c3 79 89 08 00    	add    $0x88979,%ebx
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f01036a9:	c7 83 68 2b 00 00 00 	movl   $0xf0000000,0x2b68(%ebx)
f01036b0:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f01036b3:	66 c7 83 6c 2b 00 00 	movw   $0x10,0x2b6c(%ebx)
f01036ba:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f01036bc:	66 c7 83 ca 2b 00 00 	movw   $0x68,0x2bca(%ebx)
f01036c3:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f01036c5:	c7 c0 00 b3 11 f0    	mov    $0xf011b300,%eax
f01036cb:	66 c7 40 28 67 00    	movw   $0x67,0x28(%eax)
f01036d1:	8d b3 64 2b 00 00    	lea    0x2b64(%ebx),%esi
f01036d7:	66 89 70 2a          	mov    %si,0x2a(%eax)
f01036db:	89 f2                	mov    %esi,%edx
f01036dd:	c1 ea 10             	shr    $0x10,%edx
f01036e0:	88 50 2c             	mov    %dl,0x2c(%eax)
f01036e3:	0f b6 50 2d          	movzbl 0x2d(%eax),%edx
f01036e7:	83 e2 f0             	and    $0xfffffff0,%edx
f01036ea:	83 ca 09             	or     $0x9,%edx
f01036ed:	83 e2 9f             	and    $0xffffff9f,%edx
f01036f0:	83 ca 80             	or     $0xffffff80,%edx
f01036f3:	88 55 f3             	mov    %dl,-0xd(%ebp)
f01036f6:	88 50 2d             	mov    %dl,0x2d(%eax)
f01036f9:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
f01036fd:	83 e1 c0             	and    $0xffffffc0,%ecx
f0103700:	83 c9 40             	or     $0x40,%ecx
f0103703:	83 e1 7f             	and    $0x7f,%ecx
f0103706:	88 48 2e             	mov    %cl,0x2e(%eax)
f0103709:	c1 ee 18             	shr    $0x18,%esi
f010370c:	89 f1                	mov    %esi,%ecx
f010370e:	88 48 2f             	mov    %cl,0x2f(%eax)
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103711:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
f0103715:	83 e2 ef             	and    $0xffffffef,%edx
f0103718:	88 50 2d             	mov    %dl,0x2d(%eax)
	asm volatile("ltr %0" : : "r" (sel));
f010371b:	b8 28 00 00 00       	mov    $0x28,%eax
f0103720:	0f 00 d8             	ltr    %ax
	asm volatile("lidt (%0)" : : "r" (p));
f0103723:	8d 83 ec 1f 00 00    	lea    0x1fec(%ebx),%eax
f0103729:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f010372c:	83 c4 04             	add    $0x4,%esp
f010372f:	5b                   	pop    %ebx
f0103730:	5e                   	pop    %esi
f0103731:	5f                   	pop    %edi
f0103732:	5d                   	pop    %ebp
f0103733:	c3                   	ret    

f0103734 <trap_init>:
{
f0103734:	f3 0f 1e fb          	endbr32 
f0103738:	55                   	push   %ebp
f0103739:	89 e5                	mov    %esp,%ebp
	trap_init_percpu();
f010373b:	e8 51 ff ff ff       	call   f0103691 <trap_init_percpu>
}
f0103740:	5d                   	pop    %ebp
f0103741:	c3                   	ret    

f0103742 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103742:	f3 0f 1e fb          	endbr32 
f0103746:	55                   	push   %ebp
f0103747:	89 e5                	mov    %esp,%ebp
f0103749:	56                   	push   %esi
f010374a:	53                   	push   %ebx
f010374b:	e8 23 ca ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103750:	81 c3 cc 88 08 00    	add    $0x888cc,%ebx
f0103756:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103759:	83 ec 08             	sub    $0x8,%esp
f010375c:	ff 36                	pushl  (%esi)
f010375e:	8d 83 c8 9b f7 ff    	lea    -0x86438(%ebx),%eax
f0103764:	50                   	push   %eax
f0103765:	e8 0f ff ff ff       	call   f0103679 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f010376a:	83 c4 08             	add    $0x8,%esp
f010376d:	ff 76 04             	pushl  0x4(%esi)
f0103770:	8d 83 d7 9b f7 ff    	lea    -0x86429(%ebx),%eax
f0103776:	50                   	push   %eax
f0103777:	e8 fd fe ff ff       	call   f0103679 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f010377c:	83 c4 08             	add    $0x8,%esp
f010377f:	ff 76 08             	pushl  0x8(%esi)
f0103782:	8d 83 e6 9b f7 ff    	lea    -0x8641a(%ebx),%eax
f0103788:	50                   	push   %eax
f0103789:	e8 eb fe ff ff       	call   f0103679 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f010378e:	83 c4 08             	add    $0x8,%esp
f0103791:	ff 76 0c             	pushl  0xc(%esi)
f0103794:	8d 83 f5 9b f7 ff    	lea    -0x8640b(%ebx),%eax
f010379a:	50                   	push   %eax
f010379b:	e8 d9 fe ff ff       	call   f0103679 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01037a0:	83 c4 08             	add    $0x8,%esp
f01037a3:	ff 76 10             	pushl  0x10(%esi)
f01037a6:	8d 83 04 9c f7 ff    	lea    -0x863fc(%ebx),%eax
f01037ac:	50                   	push   %eax
f01037ad:	e8 c7 fe ff ff       	call   f0103679 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01037b2:	83 c4 08             	add    $0x8,%esp
f01037b5:	ff 76 14             	pushl  0x14(%esi)
f01037b8:	8d 83 13 9c f7 ff    	lea    -0x863ed(%ebx),%eax
f01037be:	50                   	push   %eax
f01037bf:	e8 b5 fe ff ff       	call   f0103679 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01037c4:	83 c4 08             	add    $0x8,%esp
f01037c7:	ff 76 18             	pushl  0x18(%esi)
f01037ca:	8d 83 22 9c f7 ff    	lea    -0x863de(%ebx),%eax
f01037d0:	50                   	push   %eax
f01037d1:	e8 a3 fe ff ff       	call   f0103679 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01037d6:	83 c4 08             	add    $0x8,%esp
f01037d9:	ff 76 1c             	pushl  0x1c(%esi)
f01037dc:	8d 83 31 9c f7 ff    	lea    -0x863cf(%ebx),%eax
f01037e2:	50                   	push   %eax
f01037e3:	e8 91 fe ff ff       	call   f0103679 <cprintf>
}
f01037e8:	83 c4 10             	add    $0x10,%esp
f01037eb:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01037ee:	5b                   	pop    %ebx
f01037ef:	5e                   	pop    %esi
f01037f0:	5d                   	pop    %ebp
f01037f1:	c3                   	ret    

f01037f2 <print_trapframe>:
{
f01037f2:	f3 0f 1e fb          	endbr32 
f01037f6:	55                   	push   %ebp
f01037f7:	89 e5                	mov    %esp,%ebp
f01037f9:	57                   	push   %edi
f01037fa:	56                   	push   %esi
f01037fb:	53                   	push   %ebx
f01037fc:	83 ec 14             	sub    $0x14,%esp
f01037ff:	e8 6f c9 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103804:	81 c3 18 88 08 00    	add    $0x88818,%ebx
f010380a:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("TRAP frame at %p\n", tf);
f010380d:	56                   	push   %esi
f010380e:	8d 83 67 9d f7 ff    	lea    -0x86299(%ebx),%eax
f0103814:	50                   	push   %eax
f0103815:	e8 5f fe ff ff       	call   f0103679 <cprintf>
	print_regs(&tf->tf_regs);
f010381a:	89 34 24             	mov    %esi,(%esp)
f010381d:	e8 20 ff ff ff       	call   f0103742 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103822:	83 c4 08             	add    $0x8,%esp
f0103825:	0f b7 46 20          	movzwl 0x20(%esi),%eax
f0103829:	50                   	push   %eax
f010382a:	8d 83 82 9c f7 ff    	lea    -0x8637e(%ebx),%eax
f0103830:	50                   	push   %eax
f0103831:	e8 43 fe ff ff       	call   f0103679 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103836:	83 c4 08             	add    $0x8,%esp
f0103839:	0f b7 46 24          	movzwl 0x24(%esi),%eax
f010383d:	50                   	push   %eax
f010383e:	8d 83 95 9c f7 ff    	lea    -0x8636b(%ebx),%eax
f0103844:	50                   	push   %eax
f0103845:	e8 2f fe ff ff       	call   f0103679 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010384a:	8b 56 28             	mov    0x28(%esi),%edx
	if (trapno < ARRAY_SIZE(excnames))
f010384d:	83 c4 10             	add    $0x10,%esp
f0103850:	83 fa 13             	cmp    $0x13,%edx
f0103853:	0f 86 e9 00 00 00    	jbe    f0103942 <print_trapframe+0x150>
		return "System call";
f0103859:	83 fa 30             	cmp    $0x30,%edx
f010385c:	8d 83 40 9c f7 ff    	lea    -0x863c0(%ebx),%eax
f0103862:	8d 8b 4f 9c f7 ff    	lea    -0x863b1(%ebx),%ecx
f0103868:	0f 44 c1             	cmove  %ecx,%eax
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010386b:	83 ec 04             	sub    $0x4,%esp
f010386e:	50                   	push   %eax
f010386f:	52                   	push   %edx
f0103870:	8d 83 a8 9c f7 ff    	lea    -0x86358(%ebx),%eax
f0103876:	50                   	push   %eax
f0103877:	e8 fd fd ff ff       	call   f0103679 <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f010387c:	83 c4 10             	add    $0x10,%esp
f010387f:	39 b3 44 2b 00 00    	cmp    %esi,0x2b44(%ebx)
f0103885:	0f 84 c3 00 00 00    	je     f010394e <print_trapframe+0x15c>
	cprintf("  err  0x%08x", tf->tf_err);
f010388b:	83 ec 08             	sub    $0x8,%esp
f010388e:	ff 76 2c             	pushl  0x2c(%esi)
f0103891:	8d 83 c9 9c f7 ff    	lea    -0x86337(%ebx),%eax
f0103897:	50                   	push   %eax
f0103898:	e8 dc fd ff ff       	call   f0103679 <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f010389d:	83 c4 10             	add    $0x10,%esp
f01038a0:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f01038a4:	0f 85 c9 00 00 00    	jne    f0103973 <print_trapframe+0x181>
			tf->tf_err & 1 ? "protection" : "not-present");
f01038aa:	8b 46 2c             	mov    0x2c(%esi),%eax
		cprintf(" [%s, %s, %s]\n",
f01038ad:	89 c2                	mov    %eax,%edx
f01038af:	83 e2 01             	and    $0x1,%edx
f01038b2:	8d 8b 5b 9c f7 ff    	lea    -0x863a5(%ebx),%ecx
f01038b8:	8d 93 66 9c f7 ff    	lea    -0x8639a(%ebx),%edx
f01038be:	0f 44 ca             	cmove  %edx,%ecx
f01038c1:	89 c2                	mov    %eax,%edx
f01038c3:	83 e2 02             	and    $0x2,%edx
f01038c6:	8d 93 72 9c f7 ff    	lea    -0x8638e(%ebx),%edx
f01038cc:	8d bb 78 9c f7 ff    	lea    -0x86388(%ebx),%edi
f01038d2:	0f 44 d7             	cmove  %edi,%edx
f01038d5:	83 e0 04             	and    $0x4,%eax
f01038d8:	8d 83 7d 9c f7 ff    	lea    -0x86383(%ebx),%eax
f01038de:	8d bb 92 9d f7 ff    	lea    -0x8626e(%ebx),%edi
f01038e4:	0f 44 c7             	cmove  %edi,%eax
f01038e7:	51                   	push   %ecx
f01038e8:	52                   	push   %edx
f01038e9:	50                   	push   %eax
f01038ea:	8d 83 d7 9c f7 ff    	lea    -0x86329(%ebx),%eax
f01038f0:	50                   	push   %eax
f01038f1:	e8 83 fd ff ff       	call   f0103679 <cprintf>
f01038f6:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01038f9:	83 ec 08             	sub    $0x8,%esp
f01038fc:	ff 76 30             	pushl  0x30(%esi)
f01038ff:	8d 83 e6 9c f7 ff    	lea    -0x8631a(%ebx),%eax
f0103905:	50                   	push   %eax
f0103906:	e8 6e fd ff ff       	call   f0103679 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f010390b:	83 c4 08             	add    $0x8,%esp
f010390e:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103912:	50                   	push   %eax
f0103913:	8d 83 f5 9c f7 ff    	lea    -0x8630b(%ebx),%eax
f0103919:	50                   	push   %eax
f010391a:	e8 5a fd ff ff       	call   f0103679 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010391f:	83 c4 08             	add    $0x8,%esp
f0103922:	ff 76 38             	pushl  0x38(%esi)
f0103925:	8d 83 08 9d f7 ff    	lea    -0x862f8(%ebx),%eax
f010392b:	50                   	push   %eax
f010392c:	e8 48 fd ff ff       	call   f0103679 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103931:	83 c4 10             	add    $0x10,%esp
f0103934:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f0103938:	75 50                	jne    f010398a <print_trapframe+0x198>
}
f010393a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010393d:	5b                   	pop    %ebx
f010393e:	5e                   	pop    %esi
f010393f:	5f                   	pop    %edi
f0103940:	5d                   	pop    %ebp
f0103941:	c3                   	ret    
		return excnames[trapno];
f0103942:	8b 84 93 64 20 00 00 	mov    0x2064(%ebx,%edx,4),%eax
f0103949:	e9 1d ff ff ff       	jmp    f010386b <print_trapframe+0x79>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f010394e:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f0103952:	0f 85 33 ff ff ff    	jne    f010388b <print_trapframe+0x99>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103958:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f010395b:	83 ec 08             	sub    $0x8,%esp
f010395e:	50                   	push   %eax
f010395f:	8d 83 ba 9c f7 ff    	lea    -0x86346(%ebx),%eax
f0103965:	50                   	push   %eax
f0103966:	e8 0e fd ff ff       	call   f0103679 <cprintf>
f010396b:	83 c4 10             	add    $0x10,%esp
f010396e:	e9 18 ff ff ff       	jmp    f010388b <print_trapframe+0x99>
		cprintf("\n");
f0103973:	83 ec 0c             	sub    $0xc,%esp
f0103976:	8d 83 02 9b f7 ff    	lea    -0x864fe(%ebx),%eax
f010397c:	50                   	push   %eax
f010397d:	e8 f7 fc ff ff       	call   f0103679 <cprintf>
f0103982:	83 c4 10             	add    $0x10,%esp
f0103985:	e9 6f ff ff ff       	jmp    f01038f9 <print_trapframe+0x107>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f010398a:	83 ec 08             	sub    $0x8,%esp
f010398d:	ff 76 3c             	pushl  0x3c(%esi)
f0103990:	8d 83 17 9d f7 ff    	lea    -0x862e9(%ebx),%eax
f0103996:	50                   	push   %eax
f0103997:	e8 dd fc ff ff       	call   f0103679 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f010399c:	83 c4 08             	add    $0x8,%esp
f010399f:	0f b7 46 40          	movzwl 0x40(%esi),%eax
f01039a3:	50                   	push   %eax
f01039a4:	8d 83 26 9d f7 ff    	lea    -0x862da(%ebx),%eax
f01039aa:	50                   	push   %eax
f01039ab:	e8 c9 fc ff ff       	call   f0103679 <cprintf>
f01039b0:	83 c4 10             	add    $0x10,%esp
}
f01039b3:	eb 85                	jmp    f010393a <print_trapframe+0x148>

f01039b5 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01039b5:	f3 0f 1e fb          	endbr32 
f01039b9:	55                   	push   %ebp
f01039ba:	89 e5                	mov    %esp,%ebp
f01039bc:	57                   	push   %edi
f01039bd:	56                   	push   %esi
f01039be:	53                   	push   %ebx
f01039bf:	83 ec 0c             	sub    $0xc,%esp
f01039c2:	e8 ac c7 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01039c7:	81 c3 55 86 08 00    	add    $0x88655,%ebx
f01039cd:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01039d0:	fc                   	cld    
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01039d1:	9c                   	pushf  
f01039d2:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01039d3:	f6 c4 02             	test   $0x2,%ah
f01039d6:	74 1f                	je     f01039f7 <trap+0x42>
f01039d8:	8d 83 39 9d f7 ff    	lea    -0x862c7(%ebx),%eax
f01039de:	50                   	push   %eax
f01039df:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f01039e5:	50                   	push   %eax
f01039e6:	68 a8 00 00 00       	push   $0xa8
f01039eb:	8d 83 52 9d f7 ff    	lea    -0x862ae(%ebx),%eax
f01039f1:	50                   	push   %eax
f01039f2:	e8 be c6 ff ff       	call   f01000b5 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f01039f7:	83 ec 08             	sub    $0x8,%esp
f01039fa:	56                   	push   %esi
f01039fb:	8d 83 5e 9d f7 ff    	lea    -0x862a2(%ebx),%eax
f0103a01:	50                   	push   %eax
f0103a02:	e8 72 fc ff ff       	call   f0103679 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103a07:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103a0b:	83 e0 03             	and    $0x3,%eax
f0103a0e:	83 c4 10             	add    $0x10,%esp
f0103a11:	66 83 f8 03          	cmp    $0x3,%ax
f0103a15:	75 1d                	jne    f0103a34 <trap+0x7f>
		// Trapped from user mode.
		assert(curenv);
f0103a17:	c7 c0 44 e3 18 f0    	mov    $0xf018e344,%eax
f0103a1d:	8b 00                	mov    (%eax),%eax
f0103a1f:	85 c0                	test   %eax,%eax
f0103a21:	74 68                	je     f0103a8b <trap+0xd6>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103a23:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103a28:	89 c7                	mov    %eax,%edi
f0103a2a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103a2c:	c7 c0 44 e3 18 f0    	mov    $0xf018e344,%eax
f0103a32:	8b 30                	mov    (%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103a34:	89 b3 44 2b 00 00    	mov    %esi,0x2b44(%ebx)
	print_trapframe(tf);
f0103a3a:	83 ec 0c             	sub    $0xc,%esp
f0103a3d:	56                   	push   %esi
f0103a3e:	e8 af fd ff ff       	call   f01037f2 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103a43:	83 c4 10             	add    $0x10,%esp
f0103a46:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103a4b:	74 5d                	je     f0103aaa <trap+0xf5>
		env_destroy(curenv);
f0103a4d:	83 ec 0c             	sub    $0xc,%esp
f0103a50:	c7 c6 44 e3 18 f0    	mov    $0xf018e344,%esi
f0103a56:	ff 36                	pushl  (%esi)
f0103a58:	e8 e1 fa ff ff       	call   f010353e <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103a5d:	8b 06                	mov    (%esi),%eax
f0103a5f:	83 c4 10             	add    $0x10,%esp
f0103a62:	85 c0                	test   %eax,%eax
f0103a64:	74 06                	je     f0103a6c <trap+0xb7>
f0103a66:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103a6a:	74 59                	je     f0103ac5 <trap+0x110>
f0103a6c:	8d 83 dc 9e f7 ff    	lea    -0x86124(%ebx),%eax
f0103a72:	50                   	push   %eax
f0103a73:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0103a79:	50                   	push   %eax
f0103a7a:	68 c0 00 00 00       	push   $0xc0
f0103a7f:	8d 83 52 9d f7 ff    	lea    -0x862ae(%ebx),%eax
f0103a85:	50                   	push   %eax
f0103a86:	e8 2a c6 ff ff       	call   f01000b5 <_panic>
		assert(curenv);
f0103a8b:	8d 83 79 9d f7 ff    	lea    -0x86287(%ebx),%eax
f0103a91:	50                   	push   %eax
f0103a92:	8d 83 77 98 f7 ff    	lea    -0x86789(%ebx),%eax
f0103a98:	50                   	push   %eax
f0103a99:	68 ae 00 00 00       	push   $0xae
f0103a9e:	8d 83 52 9d f7 ff    	lea    -0x862ae(%ebx),%eax
f0103aa4:	50                   	push   %eax
f0103aa5:	e8 0b c6 ff ff       	call   f01000b5 <_panic>
		panic("unhandled trap in kernel");
f0103aaa:	83 ec 04             	sub    $0x4,%esp
f0103aad:	8d 83 80 9d f7 ff    	lea    -0x86280(%ebx),%eax
f0103ab3:	50                   	push   %eax
f0103ab4:	68 97 00 00 00       	push   $0x97
f0103ab9:	8d 83 52 9d f7 ff    	lea    -0x862ae(%ebx),%eax
f0103abf:	50                   	push   %eax
f0103ac0:	e8 f0 c5 ff ff       	call   f01000b5 <_panic>
	env_run(curenv);
f0103ac5:	83 ec 0c             	sub    $0xc,%esp
f0103ac8:	50                   	push   %eax
f0103ac9:	e8 e6 fa ff ff       	call   f01035b4 <env_run>

f0103ace <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103ace:	f3 0f 1e fb          	endbr32 
f0103ad2:	55                   	push   %ebp
f0103ad3:	89 e5                	mov    %esp,%ebp
f0103ad5:	57                   	push   %edi
f0103ad6:	56                   	push   %esi
f0103ad7:	53                   	push   %ebx
f0103ad8:	83 ec 0c             	sub    $0xc,%esp
f0103adb:	e8 93 c6 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103ae0:	81 c3 3c 85 08 00    	add    $0x8853c,%ebx
f0103ae6:	8b 7d 08             	mov    0x8(%ebp),%edi
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103ae9:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103aec:	ff 77 30             	pushl  0x30(%edi)
f0103aef:	50                   	push   %eax
f0103af0:	c7 c6 44 e3 18 f0    	mov    $0xf018e344,%esi
f0103af6:	8b 06                	mov    (%esi),%eax
f0103af8:	ff 70 48             	pushl  0x48(%eax)
f0103afb:	8d 83 08 9f f7 ff    	lea    -0x860f8(%ebx),%eax
f0103b01:	50                   	push   %eax
f0103b02:	e8 72 fb ff ff       	call   f0103679 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103b07:	89 3c 24             	mov    %edi,(%esp)
f0103b0a:	e8 e3 fc ff ff       	call   f01037f2 <print_trapframe>
	env_destroy(curenv);
f0103b0f:	83 c4 04             	add    $0x4,%esp
f0103b12:	ff 36                	pushl  (%esi)
f0103b14:	e8 25 fa ff ff       	call   f010353e <env_destroy>
}
f0103b19:	83 c4 10             	add    $0x10,%esp
f0103b1c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b1f:	5b                   	pop    %ebx
f0103b20:	5e                   	pop    %esi
f0103b21:	5f                   	pop    %edi
f0103b22:	5d                   	pop    %ebp
f0103b23:	c3                   	ret    

f0103b24 <syscall>:
f0103b24:	f3 0f 1e fb          	endbr32 
f0103b28:	55                   	push   %ebp
f0103b29:	89 e5                	mov    %esp,%ebp
f0103b2b:	53                   	push   %ebx
f0103b2c:	83 ec 08             	sub    $0x8,%esp
f0103b2f:	e8 3f c6 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103b34:	81 c3 e8 84 08 00    	add    $0x884e8,%ebx
f0103b3a:	8d 83 2b 9f f7 ff    	lea    -0x860d5(%ebx),%eax
f0103b40:	50                   	push   %eax
f0103b41:	6a 49                	push   $0x49
f0103b43:	8d 83 43 9f f7 ff    	lea    -0x860bd(%ebx),%eax
f0103b49:	50                   	push   %eax
f0103b4a:	e8 66 c5 ff ff       	call   f01000b5 <_panic>

f0103b4f <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103b4f:	55                   	push   %ebp
f0103b50:	89 e5                	mov    %esp,%ebp
f0103b52:	57                   	push   %edi
f0103b53:	56                   	push   %esi
f0103b54:	53                   	push   %ebx
f0103b55:	83 ec 14             	sub    $0x14,%esp
f0103b58:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103b5b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103b5e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103b61:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103b64:	8b 1a                	mov    (%edx),%ebx
f0103b66:	8b 01                	mov    (%ecx),%eax
f0103b68:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103b6b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103b72:	eb 23                	jmp    f0103b97 <stab_binsearch+0x48>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103b74:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0103b77:	eb 1e                	jmp    f0103b97 <stab_binsearch+0x48>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103b79:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103b7c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103b7f:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103b83:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103b86:	73 46                	jae    f0103bce <stab_binsearch+0x7f>
			*region_left = m;
f0103b88:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103b8b:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103b8d:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f0103b90:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0103b97:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103b9a:	7f 5f                	jg     f0103bfb <stab_binsearch+0xac>
		int true_m = (l + r) / 2, m = true_m;
f0103b9c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103b9f:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f0103ba2:	89 d0                	mov    %edx,%eax
f0103ba4:	c1 e8 1f             	shr    $0x1f,%eax
f0103ba7:	01 d0                	add    %edx,%eax
f0103ba9:	89 c7                	mov    %eax,%edi
f0103bab:	d1 ff                	sar    %edi
f0103bad:	83 e0 fe             	and    $0xfffffffe,%eax
f0103bb0:	01 f8                	add    %edi,%eax
f0103bb2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103bb5:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0103bb9:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f0103bbb:	39 c3                	cmp    %eax,%ebx
f0103bbd:	7f b5                	jg     f0103b74 <stab_binsearch+0x25>
f0103bbf:	0f b6 0a             	movzbl (%edx),%ecx
f0103bc2:	83 ea 0c             	sub    $0xc,%edx
f0103bc5:	39 f1                	cmp    %esi,%ecx
f0103bc7:	74 b0                	je     f0103b79 <stab_binsearch+0x2a>
			m--;
f0103bc9:	83 e8 01             	sub    $0x1,%eax
f0103bcc:	eb ed                	jmp    f0103bbb <stab_binsearch+0x6c>
		} else if (stabs[m].n_value > addr) {
f0103bce:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103bd1:	76 14                	jbe    f0103be7 <stab_binsearch+0x98>
			*region_right = m - 1;
f0103bd3:	83 e8 01             	sub    $0x1,%eax
f0103bd6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103bd9:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103bdc:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f0103bde:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103be5:	eb b0                	jmp    f0103b97 <stab_binsearch+0x48>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103be7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103bea:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0103bec:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103bf0:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f0103bf2:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103bf9:	eb 9c                	jmp    f0103b97 <stab_binsearch+0x48>
		}
	}

	if (!any_matches)
f0103bfb:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103bff:	75 15                	jne    f0103c16 <stab_binsearch+0xc7>
		*region_right = *region_left - 1;
f0103c01:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103c04:	8b 00                	mov    (%eax),%eax
f0103c06:	83 e8 01             	sub    $0x1,%eax
f0103c09:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103c0c:	89 07                	mov    %eax,(%edi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0103c0e:	83 c4 14             	add    $0x14,%esp
f0103c11:	5b                   	pop    %ebx
f0103c12:	5e                   	pop    %esi
f0103c13:	5f                   	pop    %edi
f0103c14:	5d                   	pop    %ebp
f0103c15:	c3                   	ret    
		for (l = *region_right;
f0103c16:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103c19:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103c1b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c1e:	8b 0f                	mov    (%edi),%ecx
f0103c20:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103c23:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103c26:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
		for (l = *region_right;
f0103c2a:	eb 03                	jmp    f0103c2f <stab_binsearch+0xe0>
		     l--)
f0103c2c:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0103c2f:	39 c1                	cmp    %eax,%ecx
f0103c31:	7d 0a                	jge    f0103c3d <stab_binsearch+0xee>
		     l > *region_left && stabs[l].n_type != type;
f0103c33:	0f b6 1a             	movzbl (%edx),%ebx
f0103c36:	83 ea 0c             	sub    $0xc,%edx
f0103c39:	39 f3                	cmp    %esi,%ebx
f0103c3b:	75 ef                	jne    f0103c2c <stab_binsearch+0xdd>
		*region_left = l;
f0103c3d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c40:	89 07                	mov    %eax,(%edi)
}
f0103c42:	eb ca                	jmp    f0103c0e <stab_binsearch+0xbf>

f0103c44 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103c44:	f3 0f 1e fb          	endbr32 
f0103c48:	55                   	push   %ebp
f0103c49:	89 e5                	mov    %esp,%ebp
f0103c4b:	57                   	push   %edi
f0103c4c:	56                   	push   %esi
f0103c4d:	53                   	push   %ebx
f0103c4e:	83 ec 2c             	sub    $0x2c,%esp
f0103c51:	e8 1d c5 ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f0103c56:	81 c3 c6 83 08 00    	add    $0x883c6,%ebx
f0103c5c:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103c5f:	8d 83 52 9f f7 ff    	lea    -0x860ae(%ebx),%eax
f0103c65:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0103c67:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0103c6e:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f0103c71:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0103c78:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c7b:	89 47 10             	mov    %eax,0x10(%edi)
	info->eip_fn_narg = 0;
f0103c7e:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103c85:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0103c8a:	0f 87 df 00 00 00    	ja     f0103d6f <debuginfo_eip+0x12b>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103c90:	a1 00 00 20 00       	mov    0x200000,%eax
f0103c95:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f0103c98:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103c9d:	8b 35 08 00 20 00    	mov    0x200008,%esi
f0103ca3:	89 75 cc             	mov    %esi,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f0103ca6:	8b 35 0c 00 20 00    	mov    0x20000c,%esi
f0103cac:	89 75 d0             	mov    %esi,-0x30(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103caf:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103cb2:	39 4d cc             	cmp    %ecx,-0x34(%ebp)
f0103cb5:	0f 83 56 01 00 00    	jae    f0103e11 <debuginfo_eip+0x1cd>
f0103cbb:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0103cbf:	0f 85 53 01 00 00    	jne    f0103e18 <debuginfo_eip+0x1d4>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103cc5:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103ccc:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0103ccf:	29 f0                	sub    %esi,%eax
f0103cd1:	c1 f8 02             	sar    $0x2,%eax
f0103cd4:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103cda:	83 e8 01             	sub    $0x1,%eax
f0103cdd:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103ce0:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103ce3:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103ce6:	ff 75 08             	pushl  0x8(%ebp)
f0103ce9:	6a 64                	push   $0x64
f0103ceb:	89 f0                	mov    %esi,%eax
f0103ced:	e8 5d fe ff ff       	call   f0103b4f <stab_binsearch>
	if (lfile == 0)
f0103cf2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103cf5:	83 c4 08             	add    $0x8,%esp
f0103cf8:	85 c0                	test   %eax,%eax
f0103cfa:	0f 84 1f 01 00 00    	je     f0103e1f <debuginfo_eip+0x1db>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103d00:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103d03:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103d06:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103d09:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103d0c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103d0f:	ff 75 08             	pushl  0x8(%ebp)
f0103d12:	6a 24                	push   $0x24
f0103d14:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0103d17:	89 f0                	mov    %esi,%eax
f0103d19:	e8 31 fe ff ff       	call   f0103b4f <stab_binsearch>

	if (lfun <= rfun) {
f0103d1e:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0103d21:	83 c4 08             	add    $0x8,%esp
f0103d24:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f0103d27:	7f 6c                	jg     f0103d95 <debuginfo_eip+0x151>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103d29:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103d2c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103d2f:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103d32:	8b 02                	mov    (%edx),%eax
f0103d34:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103d37:	2b 4d cc             	sub    -0x34(%ebp),%ecx
f0103d3a:	39 c8                	cmp    %ecx,%eax
f0103d3c:	73 06                	jae    f0103d44 <debuginfo_eip+0x100>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103d3e:	03 45 cc             	add    -0x34(%ebp),%eax
f0103d41:	89 47 08             	mov    %eax,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103d44:	8b 42 08             	mov    0x8(%edx),%eax
f0103d47:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103d4a:	83 ec 08             	sub    $0x8,%esp
f0103d4d:	6a 3a                	push   $0x3a
f0103d4f:	ff 77 08             	pushl  0x8(%edi)
f0103d52:	e8 a8 09 00 00       	call   f01046ff <strfind>
f0103d57:	2b 47 08             	sub    0x8(%edi),%eax
f0103d5a:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103d5d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103d60:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103d63:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103d66:	8d 44 81 04          	lea    0x4(%ecx,%eax,4),%eax
f0103d6a:	83 c4 10             	add    $0x10,%esp
f0103d6d:	eb 37                	jmp    f0103da6 <debuginfo_eip+0x162>
		stabstr_end = __STABSTR_END__;
f0103d6f:	c7 c0 7d 17 11 f0    	mov    $0xf011177d,%eax
f0103d75:	89 45 d0             	mov    %eax,-0x30(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0103d78:	c7 c0 65 ed 10 f0    	mov    $0xf010ed65,%eax
f0103d7e:	89 45 cc             	mov    %eax,-0x34(%ebp)
		stab_end = __STAB_END__;
f0103d81:	c7 c0 64 ed 10 f0    	mov    $0xf010ed64,%eax
		stabs = __STAB_BEGIN__;
f0103d87:	c7 c1 6c 61 10 f0    	mov    $0xf010616c,%ecx
f0103d8d:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0103d90:	e9 1a ff ff ff       	jmp    f0103caf <debuginfo_eip+0x6b>
		info->eip_fn_addr = addr;
f0103d95:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d98:	89 47 10             	mov    %eax,0x10(%edi)
		lline = lfile;
f0103d9b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103d9e:	eb aa                	jmp    f0103d4a <debuginfo_eip+0x106>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103da0:	83 ee 01             	sub    $0x1,%esi
f0103da3:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0103da6:	39 f3                	cmp    %esi,%ebx
f0103da8:	7f 2e                	jg     f0103dd8 <debuginfo_eip+0x194>
	       && stabs[lline].n_type != N_SOL
f0103daa:	0f b6 10             	movzbl (%eax),%edx
f0103dad:	80 fa 84             	cmp    $0x84,%dl
f0103db0:	74 0b                	je     f0103dbd <debuginfo_eip+0x179>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103db2:	80 fa 64             	cmp    $0x64,%dl
f0103db5:	75 e9                	jne    f0103da0 <debuginfo_eip+0x15c>
f0103db7:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0103dbb:	74 e3                	je     f0103da0 <debuginfo_eip+0x15c>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103dbd:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103dc0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103dc3:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0103dc6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103dc9:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0103dcc:	29 d8                	sub    %ebx,%eax
f0103dce:	39 c2                	cmp    %eax,%edx
f0103dd0:	73 06                	jae    f0103dd8 <debuginfo_eip+0x194>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103dd2:	89 d8                	mov    %ebx,%eax
f0103dd4:	01 d0                	add    %edx,%eax
f0103dd6:	89 07                	mov    %eax,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103dd8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103ddb:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103dde:	ba 00 00 00 00       	mov    $0x0,%edx
	if (lfun < rfun)
f0103de3:	39 c8                	cmp    %ecx,%eax
f0103de5:	7d 44                	jge    f0103e2b <debuginfo_eip+0x1e7>
		for (lline = lfun + 1;
f0103de7:	8d 50 01             	lea    0x1(%eax),%edx
f0103dea:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103ded:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103df0:	8d 44 83 10          	lea    0x10(%ebx,%eax,4),%eax
f0103df4:	eb 07                	jmp    f0103dfd <debuginfo_eip+0x1b9>
			info->eip_fn_narg++;
f0103df6:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f0103dfa:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0103dfd:	39 d1                	cmp    %edx,%ecx
f0103dff:	74 25                	je     f0103e26 <debuginfo_eip+0x1e2>
f0103e01:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103e04:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0103e08:	74 ec                	je     f0103df6 <debuginfo_eip+0x1b2>
	return 0;
f0103e0a:	ba 00 00 00 00       	mov    $0x0,%edx
f0103e0f:	eb 1a                	jmp    f0103e2b <debuginfo_eip+0x1e7>
		return -1;
f0103e11:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0103e16:	eb 13                	jmp    f0103e2b <debuginfo_eip+0x1e7>
f0103e18:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0103e1d:	eb 0c                	jmp    f0103e2b <debuginfo_eip+0x1e7>
		return -1;
f0103e1f:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0103e24:	eb 05                	jmp    f0103e2b <debuginfo_eip+0x1e7>
	return 0;
f0103e26:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103e2b:	89 d0                	mov    %edx,%eax
f0103e2d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103e30:	5b                   	pop    %ebx
f0103e31:	5e                   	pop    %esi
f0103e32:	5f                   	pop    %edi
f0103e33:	5d                   	pop    %ebp
f0103e34:	c3                   	ret    

f0103e35 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103e35:	55                   	push   %ebp
f0103e36:	89 e5                	mov    %esp,%ebp
f0103e38:	57                   	push   %edi
f0103e39:	56                   	push   %esi
f0103e3a:	53                   	push   %ebx
f0103e3b:	83 ec 2c             	sub    $0x2c,%esp
f0103e3e:	e8 fd f1 ff ff       	call   f0103040 <__x86.get_pc_thunk.cx>
f0103e43:	81 c1 d9 81 08 00    	add    $0x881d9,%ecx
f0103e49:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103e4c:	89 c7                	mov    %eax,%edi
f0103e4e:	89 d6                	mov    %edx,%esi
f0103e50:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e53:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103e56:	89 d1                	mov    %edx,%ecx
f0103e58:	89 c2                	mov    %eax,%edx
f0103e5a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103e5d:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0103e60:	8b 45 10             	mov    0x10(%ebp),%eax
f0103e63:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103e66:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103e69:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0103e70:	39 c2                	cmp    %eax,%edx
f0103e72:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f0103e75:	72 41                	jb     f0103eb8 <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103e77:	83 ec 0c             	sub    $0xc,%esp
f0103e7a:	ff 75 18             	pushl  0x18(%ebp)
f0103e7d:	83 eb 01             	sub    $0x1,%ebx
f0103e80:	53                   	push   %ebx
f0103e81:	50                   	push   %eax
f0103e82:	83 ec 08             	sub    $0x8,%esp
f0103e85:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103e88:	ff 75 e0             	pushl  -0x20(%ebp)
f0103e8b:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103e8e:	ff 75 d0             	pushl  -0x30(%ebp)
f0103e91:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103e94:	e8 97 0a 00 00       	call   f0104930 <__udivdi3>
f0103e99:	83 c4 18             	add    $0x18,%esp
f0103e9c:	52                   	push   %edx
f0103e9d:	50                   	push   %eax
f0103e9e:	89 f2                	mov    %esi,%edx
f0103ea0:	89 f8                	mov    %edi,%eax
f0103ea2:	e8 8e ff ff ff       	call   f0103e35 <printnum>
f0103ea7:	83 c4 20             	add    $0x20,%esp
f0103eaa:	eb 13                	jmp    f0103ebf <printnum+0x8a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103eac:	83 ec 08             	sub    $0x8,%esp
f0103eaf:	56                   	push   %esi
f0103eb0:	ff 75 18             	pushl  0x18(%ebp)
f0103eb3:	ff d7                	call   *%edi
f0103eb5:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0103eb8:	83 eb 01             	sub    $0x1,%ebx
f0103ebb:	85 db                	test   %ebx,%ebx
f0103ebd:	7f ed                	jg     f0103eac <printnum+0x77>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103ebf:	83 ec 08             	sub    $0x8,%esp
f0103ec2:	56                   	push   %esi
f0103ec3:	83 ec 04             	sub    $0x4,%esp
f0103ec6:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103ec9:	ff 75 e0             	pushl  -0x20(%ebp)
f0103ecc:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103ecf:	ff 75 d0             	pushl  -0x30(%ebp)
f0103ed2:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103ed5:	e8 66 0b 00 00       	call   f0104a40 <__umoddi3>
f0103eda:	83 c4 14             	add    $0x14,%esp
f0103edd:	0f be 84 03 5c 9f f7 	movsbl -0x860a4(%ebx,%eax,1),%eax
f0103ee4:	ff 
f0103ee5:	50                   	push   %eax
f0103ee6:	ff d7                	call   *%edi
}
f0103ee8:	83 c4 10             	add    $0x10,%esp
f0103eeb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103eee:	5b                   	pop    %ebx
f0103eef:	5e                   	pop    %esi
f0103ef0:	5f                   	pop    %edi
f0103ef1:	5d                   	pop    %ebp
f0103ef2:	c3                   	ret    

f0103ef3 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103ef3:	f3 0f 1e fb          	endbr32 
f0103ef7:	55                   	push   %ebp
f0103ef8:	89 e5                	mov    %esp,%ebp
f0103efa:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103efd:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103f01:	8b 10                	mov    (%eax),%edx
f0103f03:	3b 50 04             	cmp    0x4(%eax),%edx
f0103f06:	73 0a                	jae    f0103f12 <sprintputch+0x1f>
		*b->buf++ = ch;
f0103f08:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103f0b:	89 08                	mov    %ecx,(%eax)
f0103f0d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f10:	88 02                	mov    %al,(%edx)
}
f0103f12:	5d                   	pop    %ebp
f0103f13:	c3                   	ret    

f0103f14 <printfmt>:
{
f0103f14:	f3 0f 1e fb          	endbr32 
f0103f18:	55                   	push   %ebp
f0103f19:	89 e5                	mov    %esp,%ebp
f0103f1b:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0103f1e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103f21:	50                   	push   %eax
f0103f22:	ff 75 10             	pushl  0x10(%ebp)
f0103f25:	ff 75 0c             	pushl  0xc(%ebp)
f0103f28:	ff 75 08             	pushl  0x8(%ebp)
f0103f2b:	e8 05 00 00 00       	call   f0103f35 <vprintfmt>
}
f0103f30:	83 c4 10             	add    $0x10,%esp
f0103f33:	c9                   	leave  
f0103f34:	c3                   	ret    

f0103f35 <vprintfmt>:
{
f0103f35:	f3 0f 1e fb          	endbr32 
f0103f39:	55                   	push   %ebp
f0103f3a:	89 e5                	mov    %esp,%ebp
f0103f3c:	57                   	push   %edi
f0103f3d:	56                   	push   %esi
f0103f3e:	53                   	push   %ebx
f0103f3f:	83 ec 3c             	sub    $0x3c,%esp
f0103f42:	e8 e0 c7 ff ff       	call   f0100727 <__x86.get_pc_thunk.ax>
f0103f47:	05 d5 80 08 00       	add    $0x880d5,%eax
f0103f4c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103f4f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103f52:	8b 7d 10             	mov    0x10(%ebp),%edi
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103f55:	8d 80 b4 20 00 00    	lea    0x20b4(%eax),%eax
f0103f5b:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0103f5e:	e9 d4 03 00 00       	jmp    f0104337 <.L25+0x48>
		padc = ' ';
f0103f63:	c6 45 cc 20          	movb   $0x20,-0x34(%ebp)
		altflag = 0;
f0103f67:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
		precision = -1;
f0103f6e:	c7 45 c8 ff ff ff ff 	movl   $0xffffffff,-0x38(%ebp)
		width = -1;
f0103f75:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		lflag = 0;
f0103f7c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103f81:	89 5d d8             	mov    %ebx,-0x28(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103f84:	8d 47 01             	lea    0x1(%edi),%eax
f0103f87:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103f8a:	0f b6 17             	movzbl (%edi),%edx
f0103f8d:	8d 42 dd             	lea    -0x23(%edx),%eax
f0103f90:	3c 55                	cmp    $0x55,%al
f0103f92:	0f 87 27 04 00 00    	ja     f01043bf <.L20>
f0103f98:	0f b6 c0             	movzbl %al,%eax
f0103f9b:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103f9e:	89 cb                	mov    %ecx,%ebx
f0103fa0:	03 9c 81 e8 9f f7 ff 	add    -0x86018(%ecx,%eax,4),%ebx
f0103fa7:	3e ff e3             	notrack jmp *%ebx

f0103faa <.L68>:
f0103faa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0103fad:	c6 45 cc 2d          	movb   $0x2d,-0x34(%ebp)
f0103fb1:	eb d1                	jmp    f0103f84 <vprintfmt+0x4f>

f0103fb3 <.L32>:
		switch (ch = *(unsigned char *) fmt++) {
f0103fb3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103fb6:	c6 45 cc 30          	movb   $0x30,-0x34(%ebp)
f0103fba:	eb c8                	jmp    f0103f84 <vprintfmt+0x4f>

f0103fbc <.L31>:
f0103fbc:	0f b6 d2             	movzbl %dl,%edx
f0103fbf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0103fc2:	b8 00 00 00 00       	mov    $0x0,%eax
f0103fc7:	8b 4d d8             	mov    -0x28(%ebp),%ecx
				precision = precision * 10 + ch - '0';
f0103fca:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103fcd:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103fd1:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103fd4:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0103fd7:	83 fb 09             	cmp    $0x9,%ebx
f0103fda:	77 58                	ja     f0104034 <.L36+0xf>
			for (precision = 0; ; ++fmt) {
f0103fdc:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0103fdf:	eb e9                	jmp    f0103fca <.L31+0xe>

f0103fe1 <.L34>:
			precision = va_arg(ap, int);
f0103fe1:	8b 45 14             	mov    0x14(%ebp),%eax
f0103fe4:	8b 00                	mov    (%eax),%eax
f0103fe6:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0103fe9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103fec:	8d 40 04             	lea    0x4(%eax),%eax
f0103fef:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103ff2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0103ff5:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103ff9:	79 89                	jns    f0103f84 <vprintfmt+0x4f>
				width = precision, precision = -1;
f0103ffb:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0103ffe:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104001:	c7 45 c8 ff ff ff ff 	movl   $0xffffffff,-0x38(%ebp)
f0104008:	e9 77 ff ff ff       	jmp    f0103f84 <vprintfmt+0x4f>

f010400d <.L33>:
f010400d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104010:	85 c0                	test   %eax,%eax
f0104012:	ba 00 00 00 00       	mov    $0x0,%edx
f0104017:	0f 49 d0             	cmovns %eax,%edx
f010401a:	89 55 dc             	mov    %edx,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010401d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0104020:	e9 5f ff ff ff       	jmp    f0103f84 <vprintfmt+0x4f>

f0104025 <.L36>:
		switch (ch = *(unsigned char *) fmt++) {
f0104025:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0104028:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f010402f:	e9 50 ff ff ff       	jmp    f0103f84 <vprintfmt+0x4f>
f0104034:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0104037:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010403a:	eb b9                	jmp    f0103ff5 <.L34+0x14>

f010403c <.L27>:
			lflag++;
f010403c:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104040:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0104043:	e9 3c ff ff ff       	jmp    f0103f84 <vprintfmt+0x4f>

f0104048 <.L30>:
			putch(va_arg(ap, int), putdat);
f0104048:	8b 45 14             	mov    0x14(%ebp),%eax
f010404b:	8d 58 04             	lea    0x4(%eax),%ebx
f010404e:	83 ec 08             	sub    $0x8,%esp
f0104051:	56                   	push   %esi
f0104052:	ff 30                	pushl  (%eax)
f0104054:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104057:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f010405a:	89 5d 14             	mov    %ebx,0x14(%ebp)
			break;
f010405d:	e9 d2 02 00 00       	jmp    f0104334 <.L25+0x45>

f0104062 <.L28>:
			err = va_arg(ap, int);
f0104062:	8b 45 14             	mov    0x14(%ebp),%eax
f0104065:	8d 58 04             	lea    0x4(%eax),%ebx
f0104068:	8b 00                	mov    (%eax),%eax
f010406a:	99                   	cltd   
f010406b:	31 d0                	xor    %edx,%eax
f010406d:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010406f:	83 f8 06             	cmp    $0x6,%eax
f0104072:	7f 29                	jg     f010409d <.L28+0x3b>
f0104074:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0104077:	8b 14 82             	mov    (%edx,%eax,4),%edx
f010407a:	85 d2                	test   %edx,%edx
f010407c:	74 1f                	je     f010409d <.L28+0x3b>
				printfmt(putch, putdat, "%s", p);
f010407e:	52                   	push   %edx
f010407f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104082:	8d 80 89 98 f7 ff    	lea    -0x86777(%eax),%eax
f0104088:	50                   	push   %eax
f0104089:	56                   	push   %esi
f010408a:	ff 75 08             	pushl  0x8(%ebp)
f010408d:	e8 82 fe ff ff       	call   f0103f14 <printfmt>
f0104092:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0104095:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0104098:	e9 97 02 00 00       	jmp    f0104334 <.L25+0x45>
				printfmt(putch, putdat, "error %d", err);
f010409d:	50                   	push   %eax
f010409e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01040a1:	8d 80 74 9f f7 ff    	lea    -0x8608c(%eax),%eax
f01040a7:	50                   	push   %eax
f01040a8:	56                   	push   %esi
f01040a9:	ff 75 08             	pushl  0x8(%ebp)
f01040ac:	e8 63 fe ff ff       	call   f0103f14 <printfmt>
f01040b1:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01040b4:	89 5d 14             	mov    %ebx,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01040b7:	e9 78 02 00 00       	jmp    f0104334 <.L25+0x45>

f01040bc <.L24>:
			if ((p = va_arg(ap, char *)) == NULL)
f01040bc:	8b 45 14             	mov    0x14(%ebp),%eax
f01040bf:	83 c0 04             	add    $0x4,%eax
f01040c2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01040c5:	8b 45 14             	mov    0x14(%ebp),%eax
f01040c8:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01040ca:	85 ff                	test   %edi,%edi
f01040cc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01040cf:	8d 80 6d 9f f7 ff    	lea    -0x86093(%eax),%eax
f01040d5:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01040d8:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01040dc:	7e 06                	jle    f01040e4 <.L24+0x28>
f01040de:	80 7d cc 2d          	cmpb   $0x2d,-0x34(%ebp)
f01040e2:	75 0d                	jne    f01040f1 <.L24+0x35>
				for (width -= strnlen(p, precision); width > 0; width--)
f01040e4:	89 fb                	mov    %edi,%ebx
f01040e6:	03 7d dc             	add    -0x24(%ebp),%edi
f01040e9:	89 7d dc             	mov    %edi,-0x24(%ebp)
f01040ec:	8b 7d c8             	mov    -0x38(%ebp),%edi
f01040ef:	eb 5b                	jmp    f010414c <.L24+0x90>
f01040f1:	83 ec 08             	sub    $0x8,%esp
f01040f4:	ff 75 c8             	pushl  -0x38(%ebp)
f01040f7:	57                   	push   %edi
f01040f8:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01040fb:	e8 8e 04 00 00       	call   f010458e <strnlen>
f0104100:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104103:	29 c2                	sub    %eax,%edx
f0104105:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104108:	83 c4 10             	add    $0x10,%esp
f010410b:	89 d3                	mov    %edx,%ebx
					putch(padc, putdat);
f010410d:	0f be 45 cc          	movsbl -0x34(%ebp),%eax
f0104111:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0104114:	89 c7                	mov    %eax,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0104116:	85 db                	test   %ebx,%ebx
f0104118:	7e 10                	jle    f010412a <.L24+0x6e>
					putch(padc, putdat);
f010411a:	83 ec 08             	sub    $0x8,%esp
f010411d:	56                   	push   %esi
f010411e:	57                   	push   %edi
f010411f:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0104122:	83 eb 01             	sub    $0x1,%ebx
f0104125:	83 c4 10             	add    $0x10,%esp
f0104128:	eb ec                	jmp    f0104116 <.L24+0x5a>
f010412a:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010412d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104130:	85 d2                	test   %edx,%edx
f0104132:	b8 00 00 00 00       	mov    $0x0,%eax
f0104137:	0f 49 c2             	cmovns %edx,%eax
f010413a:	29 c2                	sub    %eax,%edx
f010413c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010413f:	eb a3                	jmp    f01040e4 <.L24+0x28>
					putch(ch, putdat);
f0104141:	83 ec 08             	sub    $0x8,%esp
f0104144:	56                   	push   %esi
f0104145:	52                   	push   %edx
f0104146:	ff 55 08             	call   *0x8(%ebp)
f0104149:	83 c4 10             	add    $0x10,%esp
f010414c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010414f:	29 d9                	sub    %ebx,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104151:	83 c3 01             	add    $0x1,%ebx
f0104154:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0104158:	0f be d0             	movsbl %al,%edx
f010415b:	85 d2                	test   %edx,%edx
f010415d:	74 4f                	je     f01041ae <.L24+0xf2>
f010415f:	85 ff                	test   %edi,%edi
f0104161:	78 05                	js     f0104168 <.L24+0xac>
f0104163:	83 ef 01             	sub    $0x1,%edi
f0104166:	78 1f                	js     f0104187 <.L24+0xcb>
				if (altflag && (ch < ' ' || ch > '~'))
f0104168:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f010416c:	74 d3                	je     f0104141 <.L24+0x85>
f010416e:	0f be c0             	movsbl %al,%eax
f0104171:	83 e8 20             	sub    $0x20,%eax
f0104174:	83 f8 5e             	cmp    $0x5e,%eax
f0104177:	76 c8                	jbe    f0104141 <.L24+0x85>
					putch('?', putdat);
f0104179:	83 ec 08             	sub    $0x8,%esp
f010417c:	56                   	push   %esi
f010417d:	6a 3f                	push   $0x3f
f010417f:	ff 55 08             	call   *0x8(%ebp)
f0104182:	83 c4 10             	add    $0x10,%esp
f0104185:	eb c5                	jmp    f010414c <.L24+0x90>
f0104187:	89 cf                	mov    %ecx,%edi
f0104189:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010418c:	eb 0e                	jmp    f010419c <.L24+0xe0>
				putch(' ', putdat);
f010418e:	83 ec 08             	sub    $0x8,%esp
f0104191:	56                   	push   %esi
f0104192:	6a 20                	push   $0x20
f0104194:	ff d3                	call   *%ebx
			for (; width > 0; width--)
f0104196:	83 ef 01             	sub    $0x1,%edi
f0104199:	83 c4 10             	add    $0x10,%esp
f010419c:	85 ff                	test   %edi,%edi
f010419e:	7f ee                	jg     f010418e <.L24+0xd2>
f01041a0:	89 5d 08             	mov    %ebx,0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
f01041a3:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01041a6:	89 45 14             	mov    %eax,0x14(%ebp)
f01041a9:	e9 86 01 00 00       	jmp    f0104334 <.L25+0x45>
f01041ae:	89 cf                	mov    %ecx,%edi
f01041b0:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01041b3:	eb e7                	jmp    f010419c <.L24+0xe0>

f01041b5 <.L29>:
f01041b5:	8b 5d d8             	mov    -0x28(%ebp),%ebx
	if (lflag >= 2)
f01041b8:	83 fb 01             	cmp    $0x1,%ebx
f01041bb:	7f 1b                	jg     f01041d8 <.L29+0x23>
	else if (lflag)
f01041bd:	85 db                	test   %ebx,%ebx
f01041bf:	74 64                	je     f0104225 <.L29+0x70>
		return va_arg(*ap, long);
f01041c1:	8b 45 14             	mov    0x14(%ebp),%eax
f01041c4:	8b 00                	mov    (%eax),%eax
f01041c6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01041c9:	99                   	cltd   
f01041ca:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01041cd:	8b 45 14             	mov    0x14(%ebp),%eax
f01041d0:	8d 40 04             	lea    0x4(%eax),%eax
f01041d3:	89 45 14             	mov    %eax,0x14(%ebp)
f01041d6:	eb 17                	jmp    f01041ef <.L29+0x3a>
		return va_arg(*ap, long long);
f01041d8:	8b 45 14             	mov    0x14(%ebp),%eax
f01041db:	8b 50 04             	mov    0x4(%eax),%edx
f01041de:	8b 00                	mov    (%eax),%eax
f01041e0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01041e3:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01041e6:	8b 45 14             	mov    0x14(%ebp),%eax
f01041e9:	8d 40 08             	lea    0x8(%eax),%eax
f01041ec:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f01041ef:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01041f2:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
			base = 10;
f01041f5:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f01041fa:	85 c9                	test   %ecx,%ecx
f01041fc:	0f 89 17 01 00 00    	jns    f0104319 <.L25+0x2a>
				putch('-', putdat);
f0104202:	83 ec 08             	sub    $0x8,%esp
f0104205:	56                   	push   %esi
f0104206:	6a 2d                	push   $0x2d
f0104208:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010420b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010420e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104211:	f7 da                	neg    %edx
f0104213:	83 d1 00             	adc    $0x0,%ecx
f0104216:	f7 d9                	neg    %ecx
f0104218:	83 c4 10             	add    $0x10,%esp
			base = 10;
f010421b:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104220:	e9 f4 00 00 00       	jmp    f0104319 <.L25+0x2a>
		return va_arg(*ap, int);
f0104225:	8b 45 14             	mov    0x14(%ebp),%eax
f0104228:	8b 00                	mov    (%eax),%eax
f010422a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010422d:	99                   	cltd   
f010422e:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104231:	8b 45 14             	mov    0x14(%ebp),%eax
f0104234:	8d 40 04             	lea    0x4(%eax),%eax
f0104237:	89 45 14             	mov    %eax,0x14(%ebp)
f010423a:	eb b3                	jmp    f01041ef <.L29+0x3a>

f010423c <.L23>:
f010423c:	8b 5d d8             	mov    -0x28(%ebp),%ebx
	if (lflag >= 2)
f010423f:	83 fb 01             	cmp    $0x1,%ebx
f0104242:	7f 1e                	jg     f0104262 <.L23+0x26>
	else if (lflag)
f0104244:	85 db                	test   %ebx,%ebx
f0104246:	74 32                	je     f010427a <.L23+0x3e>
		return va_arg(*ap, unsigned long);
f0104248:	8b 45 14             	mov    0x14(%ebp),%eax
f010424b:	8b 10                	mov    (%eax),%edx
f010424d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104252:	8d 40 04             	lea    0x4(%eax),%eax
f0104255:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104258:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long);
f010425d:	e9 b7 00 00 00       	jmp    f0104319 <.L25+0x2a>
		return va_arg(*ap, unsigned long long);
f0104262:	8b 45 14             	mov    0x14(%ebp),%eax
f0104265:	8b 10                	mov    (%eax),%edx
f0104267:	8b 48 04             	mov    0x4(%eax),%ecx
f010426a:	8d 40 08             	lea    0x8(%eax),%eax
f010426d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104270:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long long);
f0104275:	e9 9f 00 00 00       	jmp    f0104319 <.L25+0x2a>
		return va_arg(*ap, unsigned int);
f010427a:	8b 45 14             	mov    0x14(%ebp),%eax
f010427d:	8b 10                	mov    (%eax),%edx
f010427f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104284:	8d 40 04             	lea    0x4(%eax),%eax
f0104287:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010428a:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned int);
f010428f:	e9 85 00 00 00       	jmp    f0104319 <.L25+0x2a>

f0104294 <.L26>:
f0104294:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			putch('0',putdat);
f0104297:	83 ec 08             	sub    $0x8,%esp
f010429a:	56                   	push   %esi
f010429b:	6a 30                	push   $0x30
f010429d:	ff 55 08             	call   *0x8(%ebp)
	if (lflag >= 2)
f01042a0:	83 c4 10             	add    $0x10,%esp
f01042a3:	83 fb 01             	cmp    $0x1,%ebx
f01042a6:	7f 1b                	jg     f01042c3 <.L26+0x2f>
	else if (lflag)
f01042a8:	85 db                	test   %ebx,%ebx
f01042aa:	74 2c                	je     f01042d8 <.L26+0x44>
		return va_arg(*ap, unsigned long);
f01042ac:	8b 45 14             	mov    0x14(%ebp),%eax
f01042af:	8b 10                	mov    (%eax),%edx
f01042b1:	b9 00 00 00 00       	mov    $0x0,%ecx
f01042b6:	8d 40 04             	lea    0x4(%eax),%eax
f01042b9:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01042bc:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long);
f01042c1:	eb 56                	jmp    f0104319 <.L25+0x2a>
		return va_arg(*ap, unsigned long long);
f01042c3:	8b 45 14             	mov    0x14(%ebp),%eax
f01042c6:	8b 10                	mov    (%eax),%edx
f01042c8:	8b 48 04             	mov    0x4(%eax),%ecx
f01042cb:	8d 40 08             	lea    0x8(%eax),%eax
f01042ce:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01042d1:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long long);
f01042d6:	eb 41                	jmp    f0104319 <.L25+0x2a>
		return va_arg(*ap, unsigned int);
f01042d8:	8b 45 14             	mov    0x14(%ebp),%eax
f01042db:	8b 10                	mov    (%eax),%edx
f01042dd:	b9 00 00 00 00       	mov    $0x0,%ecx
f01042e2:	8d 40 04             	lea    0x4(%eax),%eax
f01042e5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01042e8:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned int);
f01042ed:	eb 2a                	jmp    f0104319 <.L25+0x2a>

f01042ef <.L25>:
			putch('0', putdat);
f01042ef:	83 ec 08             	sub    $0x8,%esp
f01042f2:	56                   	push   %esi
f01042f3:	6a 30                	push   $0x30
f01042f5:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01042f8:	83 c4 08             	add    $0x8,%esp
f01042fb:	56                   	push   %esi
f01042fc:	6a 78                	push   $0x78
f01042fe:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0104301:	8b 45 14             	mov    0x14(%ebp),%eax
f0104304:	8b 10                	mov    (%eax),%edx
f0104306:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010430b:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f010430e:	8d 40 04             	lea    0x4(%eax),%eax
f0104311:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104314:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0104319:	83 ec 0c             	sub    $0xc,%esp
f010431c:	0f be 5d cc          	movsbl -0x34(%ebp),%ebx
f0104320:	53                   	push   %ebx
f0104321:	ff 75 dc             	pushl  -0x24(%ebp)
f0104324:	50                   	push   %eax
f0104325:	51                   	push   %ecx
f0104326:	52                   	push   %edx
f0104327:	89 f2                	mov    %esi,%edx
f0104329:	8b 45 08             	mov    0x8(%ebp),%eax
f010432c:	e8 04 fb ff ff       	call   f0103e35 <printnum>
			break;
f0104331:	83 c4 20             	add    $0x20,%esp
			if ((p = va_arg(ap, char *)) == NULL)
f0104334:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104337:	83 c7 01             	add    $0x1,%edi
f010433a:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010433e:	83 f8 25             	cmp    $0x25,%eax
f0104341:	0f 84 1c fc ff ff    	je     f0103f63 <vprintfmt+0x2e>
			if (ch == '\0')
f0104347:	85 c0                	test   %eax,%eax
f0104349:	0f 84 91 00 00 00    	je     f01043e0 <.L20+0x21>
			putch(ch, putdat);
f010434f:	83 ec 08             	sub    $0x8,%esp
f0104352:	56                   	push   %esi
f0104353:	50                   	push   %eax
f0104354:	ff 55 08             	call   *0x8(%ebp)
f0104357:	83 c4 10             	add    $0x10,%esp
f010435a:	eb db                	jmp    f0104337 <.L25+0x48>

f010435c <.L21>:
f010435c:	8b 5d d8             	mov    -0x28(%ebp),%ebx
	if (lflag >= 2)
f010435f:	83 fb 01             	cmp    $0x1,%ebx
f0104362:	7f 1b                	jg     f010437f <.L21+0x23>
	else if (lflag)
f0104364:	85 db                	test   %ebx,%ebx
f0104366:	74 2c                	je     f0104394 <.L21+0x38>
		return va_arg(*ap, unsigned long);
f0104368:	8b 45 14             	mov    0x14(%ebp),%eax
f010436b:	8b 10                	mov    (%eax),%edx
f010436d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104372:	8d 40 04             	lea    0x4(%eax),%eax
f0104375:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104378:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long);
f010437d:	eb 9a                	jmp    f0104319 <.L25+0x2a>
		return va_arg(*ap, unsigned long long);
f010437f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104382:	8b 10                	mov    (%eax),%edx
f0104384:	8b 48 04             	mov    0x4(%eax),%ecx
f0104387:	8d 40 08             	lea    0x8(%eax),%eax
f010438a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010438d:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long long);
f0104392:	eb 85                	jmp    f0104319 <.L25+0x2a>
		return va_arg(*ap, unsigned int);
f0104394:	8b 45 14             	mov    0x14(%ebp),%eax
f0104397:	8b 10                	mov    (%eax),%edx
f0104399:	b9 00 00 00 00       	mov    $0x0,%ecx
f010439e:	8d 40 04             	lea    0x4(%eax),%eax
f01043a1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01043a4:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned int);
f01043a9:	e9 6b ff ff ff       	jmp    f0104319 <.L25+0x2a>

f01043ae <.L35>:
			putch(ch, putdat);
f01043ae:	83 ec 08             	sub    $0x8,%esp
f01043b1:	56                   	push   %esi
f01043b2:	6a 25                	push   $0x25
f01043b4:	ff 55 08             	call   *0x8(%ebp)
			break;
f01043b7:	83 c4 10             	add    $0x10,%esp
f01043ba:	e9 75 ff ff ff       	jmp    f0104334 <.L25+0x45>

f01043bf <.L20>:
			putch('%', putdat);
f01043bf:	83 ec 08             	sub    $0x8,%esp
f01043c2:	56                   	push   %esi
f01043c3:	6a 25                	push   $0x25
f01043c5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01043c8:	83 c4 10             	add    $0x10,%esp
f01043cb:	89 f8                	mov    %edi,%eax
f01043cd:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01043d1:	74 05                	je     f01043d8 <.L20+0x19>
f01043d3:	83 e8 01             	sub    $0x1,%eax
f01043d6:	eb f5                	jmp    f01043cd <.L20+0xe>
f01043d8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01043db:	e9 54 ff ff ff       	jmp    f0104334 <.L25+0x45>
}
f01043e0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01043e3:	5b                   	pop    %ebx
f01043e4:	5e                   	pop    %esi
f01043e5:	5f                   	pop    %edi
f01043e6:	5d                   	pop    %ebp
f01043e7:	c3                   	ret    

f01043e8 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01043e8:	f3 0f 1e fb          	endbr32 
f01043ec:	55                   	push   %ebp
f01043ed:	89 e5                	mov    %esp,%ebp
f01043ef:	53                   	push   %ebx
f01043f0:	83 ec 14             	sub    $0x14,%esp
f01043f3:	e8 7b bd ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f01043f8:	81 c3 24 7c 08 00    	add    $0x87c24,%ebx
f01043fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0104401:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104404:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104407:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010440b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010440e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104415:	85 c0                	test   %eax,%eax
f0104417:	74 2b                	je     f0104444 <vsnprintf+0x5c>
f0104419:	85 d2                	test   %edx,%edx
f010441b:	7e 27                	jle    f0104444 <vsnprintf+0x5c>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010441d:	ff 75 14             	pushl  0x14(%ebp)
f0104420:	ff 75 10             	pushl  0x10(%ebp)
f0104423:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104426:	50                   	push   %eax
f0104427:	8d 83 d7 7e f7 ff    	lea    -0x88129(%ebx),%eax
f010442d:	50                   	push   %eax
f010442e:	e8 02 fb ff ff       	call   f0103f35 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104433:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104436:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104439:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010443c:	83 c4 10             	add    $0x10,%esp
}
f010443f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104442:	c9                   	leave  
f0104443:	c3                   	ret    
		return -E_INVAL;
f0104444:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104449:	eb f4                	jmp    f010443f <vsnprintf+0x57>

f010444b <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010444b:	f3 0f 1e fb          	endbr32 
f010444f:	55                   	push   %ebp
f0104450:	89 e5                	mov    %esp,%ebp
f0104452:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104455:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104458:	50                   	push   %eax
f0104459:	ff 75 10             	pushl  0x10(%ebp)
f010445c:	ff 75 0c             	pushl  0xc(%ebp)
f010445f:	ff 75 08             	pushl  0x8(%ebp)
f0104462:	e8 81 ff ff ff       	call   f01043e8 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104467:	c9                   	leave  
f0104468:	c3                   	ret    

f0104469 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104469:	f3 0f 1e fb          	endbr32 
f010446d:	55                   	push   %ebp
f010446e:	89 e5                	mov    %esp,%ebp
f0104470:	57                   	push   %edi
f0104471:	56                   	push   %esi
f0104472:	53                   	push   %ebx
f0104473:	83 ec 1c             	sub    $0x1c,%esp
f0104476:	e8 f8 bc ff ff       	call   f0100173 <__x86.get_pc_thunk.bx>
f010447b:	81 c3 a1 7b 08 00    	add    $0x87ba1,%ebx
f0104481:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104484:	85 c0                	test   %eax,%eax
f0104486:	74 13                	je     f010449b <readline+0x32>
		cprintf("%s", prompt);
f0104488:	83 ec 08             	sub    $0x8,%esp
f010448b:	50                   	push   %eax
f010448c:	8d 83 89 98 f7 ff    	lea    -0x86777(%ebx),%eax
f0104492:	50                   	push   %eax
f0104493:	e8 e1 f1 ff ff       	call   f0103679 <cprintf>
f0104498:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010449b:	83 ec 0c             	sub    $0xc,%esp
f010449e:	6a 00                	push   $0x0
f01044a0:	e8 78 c2 ff ff       	call   f010071d <iscons>
f01044a5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01044a8:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01044ab:	bf 00 00 00 00       	mov    $0x0,%edi
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
			if (echoing)
				cputchar(c);
			buf[i++] = c;
f01044b0:	8d 83 e4 2b 00 00    	lea    0x2be4(%ebx),%eax
f01044b6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01044b9:	eb 51                	jmp    f010450c <readline+0xa3>
			cprintf("read error: %e\n", c);
f01044bb:	83 ec 08             	sub    $0x8,%esp
f01044be:	50                   	push   %eax
f01044bf:	8d 83 40 a1 f7 ff    	lea    -0x85ec0(%ebx),%eax
f01044c5:	50                   	push   %eax
f01044c6:	e8 ae f1 ff ff       	call   f0103679 <cprintf>
			return NULL;
f01044cb:	83 c4 10             	add    $0x10,%esp
f01044ce:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01044d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01044d6:	5b                   	pop    %ebx
f01044d7:	5e                   	pop    %esi
f01044d8:	5f                   	pop    %edi
f01044d9:	5d                   	pop    %ebp
f01044da:	c3                   	ret    
			if (echoing)
f01044db:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01044df:	75 05                	jne    f01044e6 <readline+0x7d>
			i--;
f01044e1:	83 ef 01             	sub    $0x1,%edi
f01044e4:	eb 26                	jmp    f010450c <readline+0xa3>
				cputchar('\b');
f01044e6:	83 ec 0c             	sub    $0xc,%esp
f01044e9:	6a 08                	push   $0x8
f01044eb:	e8 04 c2 ff ff       	call   f01006f4 <cputchar>
f01044f0:	83 c4 10             	add    $0x10,%esp
f01044f3:	eb ec                	jmp    f01044e1 <readline+0x78>
				cputchar(c);
f01044f5:	83 ec 0c             	sub    $0xc,%esp
f01044f8:	56                   	push   %esi
f01044f9:	e8 f6 c1 ff ff       	call   f01006f4 <cputchar>
f01044fe:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104501:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104504:	89 f0                	mov    %esi,%eax
f0104506:	88 04 39             	mov    %al,(%ecx,%edi,1)
f0104509:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f010450c:	e8 f7 c1 ff ff       	call   f0100708 <getchar>
f0104511:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0104513:	85 c0                	test   %eax,%eax
f0104515:	78 a4                	js     f01044bb <readline+0x52>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104517:	83 f8 08             	cmp    $0x8,%eax
f010451a:	0f 94 c2             	sete   %dl
f010451d:	83 f8 7f             	cmp    $0x7f,%eax
f0104520:	0f 94 c0             	sete   %al
f0104523:	08 c2                	or     %al,%dl
f0104525:	74 04                	je     f010452b <readline+0xc2>
f0104527:	85 ff                	test   %edi,%edi
f0104529:	7f b0                	jg     f01044db <readline+0x72>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010452b:	83 fe 1f             	cmp    $0x1f,%esi
f010452e:	7e 10                	jle    f0104540 <readline+0xd7>
f0104530:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0104536:	7f 08                	jg     f0104540 <readline+0xd7>
			if (echoing)
f0104538:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010453c:	74 c3                	je     f0104501 <readline+0x98>
f010453e:	eb b5                	jmp    f01044f5 <readline+0x8c>
		} else if (c == '\n' || c == '\r') {
f0104540:	83 fe 0a             	cmp    $0xa,%esi
f0104543:	74 05                	je     f010454a <readline+0xe1>
f0104545:	83 fe 0d             	cmp    $0xd,%esi
f0104548:	75 c2                	jne    f010450c <readline+0xa3>
			if (echoing)
f010454a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010454e:	75 13                	jne    f0104563 <readline+0xfa>
			buf[i] = 0;
f0104550:	c6 84 3b e4 2b 00 00 	movb   $0x0,0x2be4(%ebx,%edi,1)
f0104557:	00 
			return buf;
f0104558:	8d 83 e4 2b 00 00    	lea    0x2be4(%ebx),%eax
f010455e:	e9 70 ff ff ff       	jmp    f01044d3 <readline+0x6a>
				cputchar('\n');
f0104563:	83 ec 0c             	sub    $0xc,%esp
f0104566:	6a 0a                	push   $0xa
f0104568:	e8 87 c1 ff ff       	call   f01006f4 <cputchar>
f010456d:	83 c4 10             	add    $0x10,%esp
f0104570:	eb de                	jmp    f0104550 <readline+0xe7>

f0104572 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104572:	f3 0f 1e fb          	endbr32 
f0104576:	55                   	push   %ebp
f0104577:	89 e5                	mov    %esp,%ebp
f0104579:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010457c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104581:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104585:	74 05                	je     f010458c <strlen+0x1a>
		n++;
f0104587:	83 c0 01             	add    $0x1,%eax
f010458a:	eb f5                	jmp    f0104581 <strlen+0xf>
	return n;
}
f010458c:	5d                   	pop    %ebp
f010458d:	c3                   	ret    

f010458e <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010458e:	f3 0f 1e fb          	endbr32 
f0104592:	55                   	push   %ebp
f0104593:	89 e5                	mov    %esp,%ebp
f0104595:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104598:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010459b:	b8 00 00 00 00       	mov    $0x0,%eax
f01045a0:	39 d0                	cmp    %edx,%eax
f01045a2:	74 0d                	je     f01045b1 <strnlen+0x23>
f01045a4:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01045a8:	74 05                	je     f01045af <strnlen+0x21>
		n++;
f01045aa:	83 c0 01             	add    $0x1,%eax
f01045ad:	eb f1                	jmp    f01045a0 <strnlen+0x12>
f01045af:	89 c2                	mov    %eax,%edx
	return n;
}
f01045b1:	89 d0                	mov    %edx,%eax
f01045b3:	5d                   	pop    %ebp
f01045b4:	c3                   	ret    

f01045b5 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01045b5:	f3 0f 1e fb          	endbr32 
f01045b9:	55                   	push   %ebp
f01045ba:	89 e5                	mov    %esp,%ebp
f01045bc:	53                   	push   %ebx
f01045bd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01045c0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01045c3:	b8 00 00 00 00       	mov    $0x0,%eax
f01045c8:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f01045cc:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f01045cf:	83 c0 01             	add    $0x1,%eax
f01045d2:	84 d2                	test   %dl,%dl
f01045d4:	75 f2                	jne    f01045c8 <strcpy+0x13>
		/* do nothing */;
	return ret;
}
f01045d6:	89 c8                	mov    %ecx,%eax
f01045d8:	5b                   	pop    %ebx
f01045d9:	5d                   	pop    %ebp
f01045da:	c3                   	ret    

f01045db <strcat>:

char *
strcat(char *dst, const char *src)
{
f01045db:	f3 0f 1e fb          	endbr32 
f01045df:	55                   	push   %ebp
f01045e0:	89 e5                	mov    %esp,%ebp
f01045e2:	53                   	push   %ebx
f01045e3:	83 ec 10             	sub    $0x10,%esp
f01045e6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01045e9:	53                   	push   %ebx
f01045ea:	e8 83 ff ff ff       	call   f0104572 <strlen>
f01045ef:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f01045f2:	ff 75 0c             	pushl  0xc(%ebp)
f01045f5:	01 d8                	add    %ebx,%eax
f01045f7:	50                   	push   %eax
f01045f8:	e8 b8 ff ff ff       	call   f01045b5 <strcpy>
	return dst;
}
f01045fd:	89 d8                	mov    %ebx,%eax
f01045ff:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104602:	c9                   	leave  
f0104603:	c3                   	ret    

f0104604 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104604:	f3 0f 1e fb          	endbr32 
f0104608:	55                   	push   %ebp
f0104609:	89 e5                	mov    %esp,%ebp
f010460b:	56                   	push   %esi
f010460c:	53                   	push   %ebx
f010460d:	8b 75 08             	mov    0x8(%ebp),%esi
f0104610:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104613:	89 f3                	mov    %esi,%ebx
f0104615:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104618:	89 f0                	mov    %esi,%eax
f010461a:	39 d8                	cmp    %ebx,%eax
f010461c:	74 11                	je     f010462f <strncpy+0x2b>
		*dst++ = *src;
f010461e:	83 c0 01             	add    $0x1,%eax
f0104621:	0f b6 0a             	movzbl (%edx),%ecx
f0104624:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104627:	80 f9 01             	cmp    $0x1,%cl
f010462a:	83 da ff             	sbb    $0xffffffff,%edx
f010462d:	eb eb                	jmp    f010461a <strncpy+0x16>
	}
	return ret;
}
f010462f:	89 f0                	mov    %esi,%eax
f0104631:	5b                   	pop    %ebx
f0104632:	5e                   	pop    %esi
f0104633:	5d                   	pop    %ebp
f0104634:	c3                   	ret    

f0104635 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104635:	f3 0f 1e fb          	endbr32 
f0104639:	55                   	push   %ebp
f010463a:	89 e5                	mov    %esp,%ebp
f010463c:	56                   	push   %esi
f010463d:	53                   	push   %ebx
f010463e:	8b 75 08             	mov    0x8(%ebp),%esi
f0104641:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104644:	8b 55 10             	mov    0x10(%ebp),%edx
f0104647:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104649:	85 d2                	test   %edx,%edx
f010464b:	74 21                	je     f010466e <strlcpy+0x39>
f010464d:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104651:	89 f2                	mov    %esi,%edx
		while (--size > 0 && *src != '\0')
f0104653:	39 c2                	cmp    %eax,%edx
f0104655:	74 14                	je     f010466b <strlcpy+0x36>
f0104657:	0f b6 19             	movzbl (%ecx),%ebx
f010465a:	84 db                	test   %bl,%bl
f010465c:	74 0b                	je     f0104669 <strlcpy+0x34>
			*dst++ = *src++;
f010465e:	83 c1 01             	add    $0x1,%ecx
f0104661:	83 c2 01             	add    $0x1,%edx
f0104664:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104667:	eb ea                	jmp    f0104653 <strlcpy+0x1e>
f0104669:	89 d0                	mov    %edx,%eax
		*dst = '\0';
f010466b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010466e:	29 f0                	sub    %esi,%eax
}
f0104670:	5b                   	pop    %ebx
f0104671:	5e                   	pop    %esi
f0104672:	5d                   	pop    %ebp
f0104673:	c3                   	ret    

f0104674 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104674:	f3 0f 1e fb          	endbr32 
f0104678:	55                   	push   %ebp
f0104679:	89 e5                	mov    %esp,%ebp
f010467b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010467e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104681:	0f b6 01             	movzbl (%ecx),%eax
f0104684:	84 c0                	test   %al,%al
f0104686:	74 0c                	je     f0104694 <strcmp+0x20>
f0104688:	3a 02                	cmp    (%edx),%al
f010468a:	75 08                	jne    f0104694 <strcmp+0x20>
		p++, q++;
f010468c:	83 c1 01             	add    $0x1,%ecx
f010468f:	83 c2 01             	add    $0x1,%edx
f0104692:	eb ed                	jmp    f0104681 <strcmp+0xd>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104694:	0f b6 c0             	movzbl %al,%eax
f0104697:	0f b6 12             	movzbl (%edx),%edx
f010469a:	29 d0                	sub    %edx,%eax
}
f010469c:	5d                   	pop    %ebp
f010469d:	c3                   	ret    

f010469e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010469e:	f3 0f 1e fb          	endbr32 
f01046a2:	55                   	push   %ebp
f01046a3:	89 e5                	mov    %esp,%ebp
f01046a5:	53                   	push   %ebx
f01046a6:	8b 45 08             	mov    0x8(%ebp),%eax
f01046a9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01046ac:	89 c3                	mov    %eax,%ebx
f01046ae:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01046b1:	eb 06                	jmp    f01046b9 <strncmp+0x1b>
		n--, p++, q++;
f01046b3:	83 c0 01             	add    $0x1,%eax
f01046b6:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01046b9:	39 d8                	cmp    %ebx,%eax
f01046bb:	74 16                	je     f01046d3 <strncmp+0x35>
f01046bd:	0f b6 08             	movzbl (%eax),%ecx
f01046c0:	84 c9                	test   %cl,%cl
f01046c2:	74 04                	je     f01046c8 <strncmp+0x2a>
f01046c4:	3a 0a                	cmp    (%edx),%cl
f01046c6:	74 eb                	je     f01046b3 <strncmp+0x15>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01046c8:	0f b6 00             	movzbl (%eax),%eax
f01046cb:	0f b6 12             	movzbl (%edx),%edx
f01046ce:	29 d0                	sub    %edx,%eax
}
f01046d0:	5b                   	pop    %ebx
f01046d1:	5d                   	pop    %ebp
f01046d2:	c3                   	ret    
		return 0;
f01046d3:	b8 00 00 00 00       	mov    $0x0,%eax
f01046d8:	eb f6                	jmp    f01046d0 <strncmp+0x32>

f01046da <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01046da:	f3 0f 1e fb          	endbr32 
f01046de:	55                   	push   %ebp
f01046df:	89 e5                	mov    %esp,%ebp
f01046e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01046e4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01046e8:	0f b6 10             	movzbl (%eax),%edx
f01046eb:	84 d2                	test   %dl,%dl
f01046ed:	74 09                	je     f01046f8 <strchr+0x1e>
		if (*s == c)
f01046ef:	38 ca                	cmp    %cl,%dl
f01046f1:	74 0a                	je     f01046fd <strchr+0x23>
	for (; *s; s++)
f01046f3:	83 c0 01             	add    $0x1,%eax
f01046f6:	eb f0                	jmp    f01046e8 <strchr+0xe>
			return (char *) s;
	return 0;
f01046f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01046fd:	5d                   	pop    %ebp
f01046fe:	c3                   	ret    

f01046ff <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01046ff:	f3 0f 1e fb          	endbr32 
f0104703:	55                   	push   %ebp
f0104704:	89 e5                	mov    %esp,%ebp
f0104706:	8b 45 08             	mov    0x8(%ebp),%eax
f0104709:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010470d:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104710:	38 ca                	cmp    %cl,%dl
f0104712:	74 09                	je     f010471d <strfind+0x1e>
f0104714:	84 d2                	test   %dl,%dl
f0104716:	74 05                	je     f010471d <strfind+0x1e>
	for (; *s; s++)
f0104718:	83 c0 01             	add    $0x1,%eax
f010471b:	eb f0                	jmp    f010470d <strfind+0xe>
			break;
	return (char *) s;
}
f010471d:	5d                   	pop    %ebp
f010471e:	c3                   	ret    

f010471f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010471f:	f3 0f 1e fb          	endbr32 
f0104723:	55                   	push   %ebp
f0104724:	89 e5                	mov    %esp,%ebp
f0104726:	57                   	push   %edi
f0104727:	56                   	push   %esi
f0104728:	53                   	push   %ebx
f0104729:	8b 7d 08             	mov    0x8(%ebp),%edi
f010472c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010472f:	85 c9                	test   %ecx,%ecx
f0104731:	74 31                	je     f0104764 <memset+0x45>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104733:	89 f8                	mov    %edi,%eax
f0104735:	09 c8                	or     %ecx,%eax
f0104737:	a8 03                	test   $0x3,%al
f0104739:	75 23                	jne    f010475e <memset+0x3f>
		c &= 0xFF;
f010473b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010473f:	89 d3                	mov    %edx,%ebx
f0104741:	c1 e3 08             	shl    $0x8,%ebx
f0104744:	89 d0                	mov    %edx,%eax
f0104746:	c1 e0 18             	shl    $0x18,%eax
f0104749:	89 d6                	mov    %edx,%esi
f010474b:	c1 e6 10             	shl    $0x10,%esi
f010474e:	09 f0                	or     %esi,%eax
f0104750:	09 c2                	or     %eax,%edx
f0104752:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104754:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0104757:	89 d0                	mov    %edx,%eax
f0104759:	fc                   	cld    
f010475a:	f3 ab                	rep stos %eax,%es:(%edi)
f010475c:	eb 06                	jmp    f0104764 <memset+0x45>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010475e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104761:	fc                   	cld    
f0104762:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104764:	89 f8                	mov    %edi,%eax
f0104766:	5b                   	pop    %ebx
f0104767:	5e                   	pop    %esi
f0104768:	5f                   	pop    %edi
f0104769:	5d                   	pop    %ebp
f010476a:	c3                   	ret    

f010476b <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010476b:	f3 0f 1e fb          	endbr32 
f010476f:	55                   	push   %ebp
f0104770:	89 e5                	mov    %esp,%ebp
f0104772:	57                   	push   %edi
f0104773:	56                   	push   %esi
f0104774:	8b 45 08             	mov    0x8(%ebp),%eax
f0104777:	8b 75 0c             	mov    0xc(%ebp),%esi
f010477a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010477d:	39 c6                	cmp    %eax,%esi
f010477f:	73 32                	jae    f01047b3 <memmove+0x48>
f0104781:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104784:	39 c2                	cmp    %eax,%edx
f0104786:	76 2b                	jbe    f01047b3 <memmove+0x48>
		s += n;
		d += n;
f0104788:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010478b:	89 fe                	mov    %edi,%esi
f010478d:	09 ce                	or     %ecx,%esi
f010478f:	09 d6                	or     %edx,%esi
f0104791:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104797:	75 0e                	jne    f01047a7 <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104799:	83 ef 04             	sub    $0x4,%edi
f010479c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010479f:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01047a2:	fd                   	std    
f01047a3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01047a5:	eb 09                	jmp    f01047b0 <memmove+0x45>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01047a7:	83 ef 01             	sub    $0x1,%edi
f01047aa:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01047ad:	fd                   	std    
f01047ae:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01047b0:	fc                   	cld    
f01047b1:	eb 1a                	jmp    f01047cd <memmove+0x62>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01047b3:	89 c2                	mov    %eax,%edx
f01047b5:	09 ca                	or     %ecx,%edx
f01047b7:	09 f2                	or     %esi,%edx
f01047b9:	f6 c2 03             	test   $0x3,%dl
f01047bc:	75 0a                	jne    f01047c8 <memmove+0x5d>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01047be:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01047c1:	89 c7                	mov    %eax,%edi
f01047c3:	fc                   	cld    
f01047c4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01047c6:	eb 05                	jmp    f01047cd <memmove+0x62>
		else
			asm volatile("cld; rep movsb\n"
f01047c8:	89 c7                	mov    %eax,%edi
f01047ca:	fc                   	cld    
f01047cb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01047cd:	5e                   	pop    %esi
f01047ce:	5f                   	pop    %edi
f01047cf:	5d                   	pop    %ebp
f01047d0:	c3                   	ret    

f01047d1 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01047d1:	f3 0f 1e fb          	endbr32 
f01047d5:	55                   	push   %ebp
f01047d6:	89 e5                	mov    %esp,%ebp
f01047d8:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01047db:	ff 75 10             	pushl  0x10(%ebp)
f01047de:	ff 75 0c             	pushl  0xc(%ebp)
f01047e1:	ff 75 08             	pushl  0x8(%ebp)
f01047e4:	e8 82 ff ff ff       	call   f010476b <memmove>
}
f01047e9:	c9                   	leave  
f01047ea:	c3                   	ret    

f01047eb <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01047eb:	f3 0f 1e fb          	endbr32 
f01047ef:	55                   	push   %ebp
f01047f0:	89 e5                	mov    %esp,%ebp
f01047f2:	56                   	push   %esi
f01047f3:	53                   	push   %ebx
f01047f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01047f7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01047fa:	89 c6                	mov    %eax,%esi
f01047fc:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01047ff:	39 f0                	cmp    %esi,%eax
f0104801:	74 1c                	je     f010481f <memcmp+0x34>
		if (*s1 != *s2)
f0104803:	0f b6 08             	movzbl (%eax),%ecx
f0104806:	0f b6 1a             	movzbl (%edx),%ebx
f0104809:	38 d9                	cmp    %bl,%cl
f010480b:	75 08                	jne    f0104815 <memcmp+0x2a>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f010480d:	83 c0 01             	add    $0x1,%eax
f0104810:	83 c2 01             	add    $0x1,%edx
f0104813:	eb ea                	jmp    f01047ff <memcmp+0x14>
			return (int) *s1 - (int) *s2;
f0104815:	0f b6 c1             	movzbl %cl,%eax
f0104818:	0f b6 db             	movzbl %bl,%ebx
f010481b:	29 d8                	sub    %ebx,%eax
f010481d:	eb 05                	jmp    f0104824 <memcmp+0x39>
	}

	return 0;
f010481f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104824:	5b                   	pop    %ebx
f0104825:	5e                   	pop    %esi
f0104826:	5d                   	pop    %ebp
f0104827:	c3                   	ret    

f0104828 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104828:	f3 0f 1e fb          	endbr32 
f010482c:	55                   	push   %ebp
f010482d:	89 e5                	mov    %esp,%ebp
f010482f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104832:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104835:	89 c2                	mov    %eax,%edx
f0104837:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010483a:	39 d0                	cmp    %edx,%eax
f010483c:	73 09                	jae    f0104847 <memfind+0x1f>
		if (*(const unsigned char *) s == (unsigned char) c)
f010483e:	38 08                	cmp    %cl,(%eax)
f0104840:	74 05                	je     f0104847 <memfind+0x1f>
	for (; s < ends; s++)
f0104842:	83 c0 01             	add    $0x1,%eax
f0104845:	eb f3                	jmp    f010483a <memfind+0x12>
			break;
	return (void *) s;
}
f0104847:	5d                   	pop    %ebp
f0104848:	c3                   	ret    

f0104849 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104849:	f3 0f 1e fb          	endbr32 
f010484d:	55                   	push   %ebp
f010484e:	89 e5                	mov    %esp,%ebp
f0104850:	57                   	push   %edi
f0104851:	56                   	push   %esi
f0104852:	53                   	push   %ebx
f0104853:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104856:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104859:	eb 03                	jmp    f010485e <strtol+0x15>
		s++;
f010485b:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f010485e:	0f b6 01             	movzbl (%ecx),%eax
f0104861:	3c 20                	cmp    $0x20,%al
f0104863:	74 f6                	je     f010485b <strtol+0x12>
f0104865:	3c 09                	cmp    $0x9,%al
f0104867:	74 f2                	je     f010485b <strtol+0x12>

	// plus/minus sign
	if (*s == '+')
f0104869:	3c 2b                	cmp    $0x2b,%al
f010486b:	74 2a                	je     f0104897 <strtol+0x4e>
	int neg = 0;
f010486d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0104872:	3c 2d                	cmp    $0x2d,%al
f0104874:	74 2b                	je     f01048a1 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104876:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010487c:	75 0f                	jne    f010488d <strtol+0x44>
f010487e:	80 39 30             	cmpb   $0x30,(%ecx)
f0104881:	74 28                	je     f01048ab <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104883:	85 db                	test   %ebx,%ebx
f0104885:	b8 0a 00 00 00       	mov    $0xa,%eax
f010488a:	0f 44 d8             	cmove  %eax,%ebx
f010488d:	b8 00 00 00 00       	mov    $0x0,%eax
f0104892:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104895:	eb 46                	jmp    f01048dd <strtol+0x94>
		s++;
f0104897:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f010489a:	bf 00 00 00 00       	mov    $0x0,%edi
f010489f:	eb d5                	jmp    f0104876 <strtol+0x2d>
		s++, neg = 1;
f01048a1:	83 c1 01             	add    $0x1,%ecx
f01048a4:	bf 01 00 00 00       	mov    $0x1,%edi
f01048a9:	eb cb                	jmp    f0104876 <strtol+0x2d>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01048ab:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01048af:	74 0e                	je     f01048bf <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01048b1:	85 db                	test   %ebx,%ebx
f01048b3:	75 d8                	jne    f010488d <strtol+0x44>
		s++, base = 8;
f01048b5:	83 c1 01             	add    $0x1,%ecx
f01048b8:	bb 08 00 00 00       	mov    $0x8,%ebx
f01048bd:	eb ce                	jmp    f010488d <strtol+0x44>
		s += 2, base = 16;
f01048bf:	83 c1 02             	add    $0x2,%ecx
f01048c2:	bb 10 00 00 00       	mov    $0x10,%ebx
f01048c7:	eb c4                	jmp    f010488d <strtol+0x44>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f01048c9:	0f be d2             	movsbl %dl,%edx
f01048cc:	83 ea 30             	sub    $0x30,%edx
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01048cf:	3b 55 10             	cmp    0x10(%ebp),%edx
f01048d2:	7d 3a                	jge    f010490e <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01048d4:	83 c1 01             	add    $0x1,%ecx
f01048d7:	0f af 45 10          	imul   0x10(%ebp),%eax
f01048db:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f01048dd:	0f b6 11             	movzbl (%ecx),%edx
f01048e0:	8d 72 d0             	lea    -0x30(%edx),%esi
f01048e3:	89 f3                	mov    %esi,%ebx
f01048e5:	80 fb 09             	cmp    $0x9,%bl
f01048e8:	76 df                	jbe    f01048c9 <strtol+0x80>
		else if (*s >= 'a' && *s <= 'z')
f01048ea:	8d 72 9f             	lea    -0x61(%edx),%esi
f01048ed:	89 f3                	mov    %esi,%ebx
f01048ef:	80 fb 19             	cmp    $0x19,%bl
f01048f2:	77 08                	ja     f01048fc <strtol+0xb3>
			dig = *s - 'a' + 10;
f01048f4:	0f be d2             	movsbl %dl,%edx
f01048f7:	83 ea 57             	sub    $0x57,%edx
f01048fa:	eb d3                	jmp    f01048cf <strtol+0x86>
		else if (*s >= 'A' && *s <= 'Z')
f01048fc:	8d 72 bf             	lea    -0x41(%edx),%esi
f01048ff:	89 f3                	mov    %esi,%ebx
f0104901:	80 fb 19             	cmp    $0x19,%bl
f0104904:	77 08                	ja     f010490e <strtol+0xc5>
			dig = *s - 'A' + 10;
f0104906:	0f be d2             	movsbl %dl,%edx
f0104909:	83 ea 37             	sub    $0x37,%edx
f010490c:	eb c1                	jmp    f01048cf <strtol+0x86>
		// we don't properly detect overflow!
	}

	if (endptr)
f010490e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104912:	74 05                	je     f0104919 <strtol+0xd0>
		*endptr = (char *) s;
f0104914:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104917:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0104919:	89 c2                	mov    %eax,%edx
f010491b:	f7 da                	neg    %edx
f010491d:	85 ff                	test   %edi,%edi
f010491f:	0f 45 c2             	cmovne %edx,%eax
}
f0104922:	5b                   	pop    %ebx
f0104923:	5e                   	pop    %esi
f0104924:	5f                   	pop    %edi
f0104925:	5d                   	pop    %ebp
f0104926:	c3                   	ret    
f0104927:	66 90                	xchg   %ax,%ax
f0104929:	66 90                	xchg   %ax,%ax
f010492b:	66 90                	xchg   %ax,%ax
f010492d:	66 90                	xchg   %ax,%ax
f010492f:	90                   	nop

f0104930 <__udivdi3>:
f0104930:	f3 0f 1e fb          	endbr32 
f0104934:	55                   	push   %ebp
f0104935:	57                   	push   %edi
f0104936:	56                   	push   %esi
f0104937:	53                   	push   %ebx
f0104938:	83 ec 1c             	sub    $0x1c,%esp
f010493b:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010493f:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0104943:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104947:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f010494b:	85 d2                	test   %edx,%edx
f010494d:	75 19                	jne    f0104968 <__udivdi3+0x38>
f010494f:	39 f3                	cmp    %esi,%ebx
f0104951:	76 4d                	jbe    f01049a0 <__udivdi3+0x70>
f0104953:	31 ff                	xor    %edi,%edi
f0104955:	89 e8                	mov    %ebp,%eax
f0104957:	89 f2                	mov    %esi,%edx
f0104959:	f7 f3                	div    %ebx
f010495b:	89 fa                	mov    %edi,%edx
f010495d:	83 c4 1c             	add    $0x1c,%esp
f0104960:	5b                   	pop    %ebx
f0104961:	5e                   	pop    %esi
f0104962:	5f                   	pop    %edi
f0104963:	5d                   	pop    %ebp
f0104964:	c3                   	ret    
f0104965:	8d 76 00             	lea    0x0(%esi),%esi
f0104968:	39 f2                	cmp    %esi,%edx
f010496a:	76 14                	jbe    f0104980 <__udivdi3+0x50>
f010496c:	31 ff                	xor    %edi,%edi
f010496e:	31 c0                	xor    %eax,%eax
f0104970:	89 fa                	mov    %edi,%edx
f0104972:	83 c4 1c             	add    $0x1c,%esp
f0104975:	5b                   	pop    %ebx
f0104976:	5e                   	pop    %esi
f0104977:	5f                   	pop    %edi
f0104978:	5d                   	pop    %ebp
f0104979:	c3                   	ret    
f010497a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104980:	0f bd fa             	bsr    %edx,%edi
f0104983:	83 f7 1f             	xor    $0x1f,%edi
f0104986:	75 48                	jne    f01049d0 <__udivdi3+0xa0>
f0104988:	39 f2                	cmp    %esi,%edx
f010498a:	72 06                	jb     f0104992 <__udivdi3+0x62>
f010498c:	31 c0                	xor    %eax,%eax
f010498e:	39 eb                	cmp    %ebp,%ebx
f0104990:	77 de                	ja     f0104970 <__udivdi3+0x40>
f0104992:	b8 01 00 00 00       	mov    $0x1,%eax
f0104997:	eb d7                	jmp    f0104970 <__udivdi3+0x40>
f0104999:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01049a0:	89 d9                	mov    %ebx,%ecx
f01049a2:	85 db                	test   %ebx,%ebx
f01049a4:	75 0b                	jne    f01049b1 <__udivdi3+0x81>
f01049a6:	b8 01 00 00 00       	mov    $0x1,%eax
f01049ab:	31 d2                	xor    %edx,%edx
f01049ad:	f7 f3                	div    %ebx
f01049af:	89 c1                	mov    %eax,%ecx
f01049b1:	31 d2                	xor    %edx,%edx
f01049b3:	89 f0                	mov    %esi,%eax
f01049b5:	f7 f1                	div    %ecx
f01049b7:	89 c6                	mov    %eax,%esi
f01049b9:	89 e8                	mov    %ebp,%eax
f01049bb:	89 f7                	mov    %esi,%edi
f01049bd:	f7 f1                	div    %ecx
f01049bf:	89 fa                	mov    %edi,%edx
f01049c1:	83 c4 1c             	add    $0x1c,%esp
f01049c4:	5b                   	pop    %ebx
f01049c5:	5e                   	pop    %esi
f01049c6:	5f                   	pop    %edi
f01049c7:	5d                   	pop    %ebp
f01049c8:	c3                   	ret    
f01049c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01049d0:	89 f9                	mov    %edi,%ecx
f01049d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01049d7:	29 f8                	sub    %edi,%eax
f01049d9:	d3 e2                	shl    %cl,%edx
f01049db:	89 54 24 08          	mov    %edx,0x8(%esp)
f01049df:	89 c1                	mov    %eax,%ecx
f01049e1:	89 da                	mov    %ebx,%edx
f01049e3:	d3 ea                	shr    %cl,%edx
f01049e5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f01049e9:	09 d1                	or     %edx,%ecx
f01049eb:	89 f2                	mov    %esi,%edx
f01049ed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01049f1:	89 f9                	mov    %edi,%ecx
f01049f3:	d3 e3                	shl    %cl,%ebx
f01049f5:	89 c1                	mov    %eax,%ecx
f01049f7:	d3 ea                	shr    %cl,%edx
f01049f9:	89 f9                	mov    %edi,%ecx
f01049fb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01049ff:	89 eb                	mov    %ebp,%ebx
f0104a01:	d3 e6                	shl    %cl,%esi
f0104a03:	89 c1                	mov    %eax,%ecx
f0104a05:	d3 eb                	shr    %cl,%ebx
f0104a07:	09 de                	or     %ebx,%esi
f0104a09:	89 f0                	mov    %esi,%eax
f0104a0b:	f7 74 24 08          	divl   0x8(%esp)
f0104a0f:	89 d6                	mov    %edx,%esi
f0104a11:	89 c3                	mov    %eax,%ebx
f0104a13:	f7 64 24 0c          	mull   0xc(%esp)
f0104a17:	39 d6                	cmp    %edx,%esi
f0104a19:	72 15                	jb     f0104a30 <__udivdi3+0x100>
f0104a1b:	89 f9                	mov    %edi,%ecx
f0104a1d:	d3 e5                	shl    %cl,%ebp
f0104a1f:	39 c5                	cmp    %eax,%ebp
f0104a21:	73 04                	jae    f0104a27 <__udivdi3+0xf7>
f0104a23:	39 d6                	cmp    %edx,%esi
f0104a25:	74 09                	je     f0104a30 <__udivdi3+0x100>
f0104a27:	89 d8                	mov    %ebx,%eax
f0104a29:	31 ff                	xor    %edi,%edi
f0104a2b:	e9 40 ff ff ff       	jmp    f0104970 <__udivdi3+0x40>
f0104a30:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0104a33:	31 ff                	xor    %edi,%edi
f0104a35:	e9 36 ff ff ff       	jmp    f0104970 <__udivdi3+0x40>
f0104a3a:	66 90                	xchg   %ax,%ax
f0104a3c:	66 90                	xchg   %ax,%ax
f0104a3e:	66 90                	xchg   %ax,%ax

f0104a40 <__umoddi3>:
f0104a40:	f3 0f 1e fb          	endbr32 
f0104a44:	55                   	push   %ebp
f0104a45:	57                   	push   %edi
f0104a46:	56                   	push   %esi
f0104a47:	53                   	push   %ebx
f0104a48:	83 ec 1c             	sub    $0x1c,%esp
f0104a4b:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0104a4f:	8b 74 24 30          	mov    0x30(%esp),%esi
f0104a53:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0104a57:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104a5b:	85 c0                	test   %eax,%eax
f0104a5d:	75 19                	jne    f0104a78 <__umoddi3+0x38>
f0104a5f:	39 df                	cmp    %ebx,%edi
f0104a61:	76 5d                	jbe    f0104ac0 <__umoddi3+0x80>
f0104a63:	89 f0                	mov    %esi,%eax
f0104a65:	89 da                	mov    %ebx,%edx
f0104a67:	f7 f7                	div    %edi
f0104a69:	89 d0                	mov    %edx,%eax
f0104a6b:	31 d2                	xor    %edx,%edx
f0104a6d:	83 c4 1c             	add    $0x1c,%esp
f0104a70:	5b                   	pop    %ebx
f0104a71:	5e                   	pop    %esi
f0104a72:	5f                   	pop    %edi
f0104a73:	5d                   	pop    %ebp
f0104a74:	c3                   	ret    
f0104a75:	8d 76 00             	lea    0x0(%esi),%esi
f0104a78:	89 f2                	mov    %esi,%edx
f0104a7a:	39 d8                	cmp    %ebx,%eax
f0104a7c:	76 12                	jbe    f0104a90 <__umoddi3+0x50>
f0104a7e:	89 f0                	mov    %esi,%eax
f0104a80:	89 da                	mov    %ebx,%edx
f0104a82:	83 c4 1c             	add    $0x1c,%esp
f0104a85:	5b                   	pop    %ebx
f0104a86:	5e                   	pop    %esi
f0104a87:	5f                   	pop    %edi
f0104a88:	5d                   	pop    %ebp
f0104a89:	c3                   	ret    
f0104a8a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104a90:	0f bd e8             	bsr    %eax,%ebp
f0104a93:	83 f5 1f             	xor    $0x1f,%ebp
f0104a96:	75 50                	jne    f0104ae8 <__umoddi3+0xa8>
f0104a98:	39 d8                	cmp    %ebx,%eax
f0104a9a:	0f 82 e0 00 00 00    	jb     f0104b80 <__umoddi3+0x140>
f0104aa0:	89 d9                	mov    %ebx,%ecx
f0104aa2:	39 f7                	cmp    %esi,%edi
f0104aa4:	0f 86 d6 00 00 00    	jbe    f0104b80 <__umoddi3+0x140>
f0104aaa:	89 d0                	mov    %edx,%eax
f0104aac:	89 ca                	mov    %ecx,%edx
f0104aae:	83 c4 1c             	add    $0x1c,%esp
f0104ab1:	5b                   	pop    %ebx
f0104ab2:	5e                   	pop    %esi
f0104ab3:	5f                   	pop    %edi
f0104ab4:	5d                   	pop    %ebp
f0104ab5:	c3                   	ret    
f0104ab6:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104abd:	8d 76 00             	lea    0x0(%esi),%esi
f0104ac0:	89 fd                	mov    %edi,%ebp
f0104ac2:	85 ff                	test   %edi,%edi
f0104ac4:	75 0b                	jne    f0104ad1 <__umoddi3+0x91>
f0104ac6:	b8 01 00 00 00       	mov    $0x1,%eax
f0104acb:	31 d2                	xor    %edx,%edx
f0104acd:	f7 f7                	div    %edi
f0104acf:	89 c5                	mov    %eax,%ebp
f0104ad1:	89 d8                	mov    %ebx,%eax
f0104ad3:	31 d2                	xor    %edx,%edx
f0104ad5:	f7 f5                	div    %ebp
f0104ad7:	89 f0                	mov    %esi,%eax
f0104ad9:	f7 f5                	div    %ebp
f0104adb:	89 d0                	mov    %edx,%eax
f0104add:	31 d2                	xor    %edx,%edx
f0104adf:	eb 8c                	jmp    f0104a6d <__umoddi3+0x2d>
f0104ae1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104ae8:	89 e9                	mov    %ebp,%ecx
f0104aea:	ba 20 00 00 00       	mov    $0x20,%edx
f0104aef:	29 ea                	sub    %ebp,%edx
f0104af1:	d3 e0                	shl    %cl,%eax
f0104af3:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104af7:	89 d1                	mov    %edx,%ecx
f0104af9:	89 f8                	mov    %edi,%eax
f0104afb:	d3 e8                	shr    %cl,%eax
f0104afd:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0104b01:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104b05:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104b09:	09 c1                	or     %eax,%ecx
f0104b0b:	89 d8                	mov    %ebx,%eax
f0104b0d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104b11:	89 e9                	mov    %ebp,%ecx
f0104b13:	d3 e7                	shl    %cl,%edi
f0104b15:	89 d1                	mov    %edx,%ecx
f0104b17:	d3 e8                	shr    %cl,%eax
f0104b19:	89 e9                	mov    %ebp,%ecx
f0104b1b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104b1f:	d3 e3                	shl    %cl,%ebx
f0104b21:	89 c7                	mov    %eax,%edi
f0104b23:	89 d1                	mov    %edx,%ecx
f0104b25:	89 f0                	mov    %esi,%eax
f0104b27:	d3 e8                	shr    %cl,%eax
f0104b29:	89 e9                	mov    %ebp,%ecx
f0104b2b:	89 fa                	mov    %edi,%edx
f0104b2d:	d3 e6                	shl    %cl,%esi
f0104b2f:	09 d8                	or     %ebx,%eax
f0104b31:	f7 74 24 08          	divl   0x8(%esp)
f0104b35:	89 d1                	mov    %edx,%ecx
f0104b37:	89 f3                	mov    %esi,%ebx
f0104b39:	f7 64 24 0c          	mull   0xc(%esp)
f0104b3d:	89 c6                	mov    %eax,%esi
f0104b3f:	89 d7                	mov    %edx,%edi
f0104b41:	39 d1                	cmp    %edx,%ecx
f0104b43:	72 06                	jb     f0104b4b <__umoddi3+0x10b>
f0104b45:	75 10                	jne    f0104b57 <__umoddi3+0x117>
f0104b47:	39 c3                	cmp    %eax,%ebx
f0104b49:	73 0c                	jae    f0104b57 <__umoddi3+0x117>
f0104b4b:	2b 44 24 0c          	sub    0xc(%esp),%eax
f0104b4f:	1b 54 24 08          	sbb    0x8(%esp),%edx
f0104b53:	89 d7                	mov    %edx,%edi
f0104b55:	89 c6                	mov    %eax,%esi
f0104b57:	89 ca                	mov    %ecx,%edx
f0104b59:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104b5e:	29 f3                	sub    %esi,%ebx
f0104b60:	19 fa                	sbb    %edi,%edx
f0104b62:	89 d0                	mov    %edx,%eax
f0104b64:	d3 e0                	shl    %cl,%eax
f0104b66:	89 e9                	mov    %ebp,%ecx
f0104b68:	d3 eb                	shr    %cl,%ebx
f0104b6a:	d3 ea                	shr    %cl,%edx
f0104b6c:	09 d8                	or     %ebx,%eax
f0104b6e:	83 c4 1c             	add    $0x1c,%esp
f0104b71:	5b                   	pop    %ebx
f0104b72:	5e                   	pop    %esi
f0104b73:	5f                   	pop    %edi
f0104b74:	5d                   	pop    %ebp
f0104b75:	c3                   	ret    
f0104b76:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104b7d:	8d 76 00             	lea    0x0(%esi),%esi
f0104b80:	29 fe                	sub    %edi,%esi
f0104b82:	19 c3                	sbb    %eax,%ebx
f0104b84:	89 f2                	mov    %esi,%edx
f0104b86:	89 d9                	mov    %ebx,%ecx
f0104b88:	e9 1d ff ff ff       	jmp    f0104aaa <__umoddi3+0x6a>
