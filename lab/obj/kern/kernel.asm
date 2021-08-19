
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
f0100015:	b8 00 10 12 00       	mov    $0x121000,%eax
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
f0100034:	bc 00 10 12 f0       	mov    $0xf0121000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 62 00 00 00       	call   f01000a0 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100040:	f3 0f 1e fb          	endbr32 
f0100044:	55                   	push   %ebp
f0100045:	89 e5                	mov    %esp,%ebp
f0100047:	56                   	push   %esi
f0100048:	53                   	push   %ebx
f0100049:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010004c:	83 3d 80 7e 21 f0 00 	cmpl   $0x0,0xf0217e80
f0100053:	74 0f                	je     f0100064 <_panic+0x24>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100055:	83 ec 0c             	sub    $0xc,%esp
f0100058:	6a 00                	push   $0x0
f010005a:	e8 4a 09 00 00       	call   f01009a9 <monitor>
f010005f:	83 c4 10             	add    $0x10,%esp
f0100062:	eb f1                	jmp    f0100055 <_panic+0x15>
	panicstr = fmt;
f0100064:	89 35 80 7e 21 f0    	mov    %esi,0xf0217e80
	asm volatile("cli; cld");
f010006a:	fa                   	cli    
f010006b:	fc                   	cld    
	va_start(ap, fmt);
f010006c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010006f:	e8 ca 60 00 00       	call   f010613e <cpunum>
f0100074:	ff 75 0c             	pushl  0xc(%ebp)
f0100077:	ff 75 08             	pushl  0x8(%ebp)
f010007a:	50                   	push   %eax
f010007b:	68 c0 67 10 f0       	push   $0xf01067c0
f0100080:	e8 35 39 00 00       	call   f01039ba <cprintf>
	vcprintf(fmt, ap);
f0100085:	83 c4 08             	add    $0x8,%esp
f0100088:	53                   	push   %ebx
f0100089:	56                   	push   %esi
f010008a:	e8 01 39 00 00       	call   f0103990 <vcprintf>
	cprintf("\n");
f010008f:	c7 04 24 fd 79 10 f0 	movl   $0xf01079fd,(%esp)
f0100096:	e8 1f 39 00 00       	call   f01039ba <cprintf>
f010009b:	83 c4 10             	add    $0x10,%esp
f010009e:	eb b5                	jmp    f0100055 <_panic+0x15>

f01000a0 <i386_init>:
{
f01000a0:	f3 0f 1e fb          	endbr32 
f01000a4:	55                   	push   %ebp
f01000a5:	89 e5                	mov    %esp,%ebp
f01000a7:	53                   	push   %ebx
f01000a8:	83 ec 04             	sub    $0x4,%esp
	cons_init();
f01000ab:	e8 be 05 00 00       	call   f010066e <cons_init>
	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b0:	83 ec 08             	sub    $0x8,%esp
f01000b3:	68 ac 1a 00 00       	push   $0x1aac
f01000b8:	68 2c 68 10 f0       	push   $0xf010682c
f01000bd:	e8 f8 38 00 00       	call   f01039ba <cprintf>
	mem_init();
f01000c2:	e8 b7 12 00 00       	call   f010137e <mem_init>
	env_init();
f01000c7:	e8 fa 30 00 00       	call   f01031c6 <env_init>
	trap_init();
f01000cc:	e8 e5 39 00 00       	call   f0103ab6 <trap_init>
	mp_init();
f01000d1:	e8 69 5d 00 00       	call   f0105e3f <mp_init>
	lapic_init();
f01000d6:	e8 7d 60 00 00       	call   f0106158 <lapic_init>
	pic_init();
f01000db:	e8 ef 37 00 00       	call   f01038cf <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000e0:	c7 04 24 c0 33 12 f0 	movl   $0xf01233c0,(%esp)
f01000e7:	e8 da 62 00 00       	call   f01063c6 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000ec:	83 c4 10             	add    $0x10,%esp
f01000ef:	83 3d 88 7e 21 f0 07 	cmpl   $0x7,0xf0217e88
f01000f6:	76 27                	jbe    f010011f <i386_init+0x7f>
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f01000f8:	83 ec 04             	sub    $0x4,%esp
f01000fb:	b8 a2 5d 10 f0       	mov    $0xf0105da2,%eax
f0100100:	2d 28 5d 10 f0       	sub    $0xf0105d28,%eax
f0100105:	50                   	push   %eax
f0100106:	68 28 5d 10 f0       	push   $0xf0105d28
f010010b:	68 00 70 00 f0       	push   $0xf0007000
f0100110:	e8 57 5a 00 00       	call   f0105b6c <memmove>
	for (c = cpus; c < cpus + ncpu; c++) {
f0100115:	83 c4 10             	add    $0x10,%esp
f0100118:	bb 20 80 21 f0       	mov    $0xf0218020,%ebx
f010011d:	eb 53                	jmp    f0100172 <i386_init+0xd2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010011f:	68 00 70 00 00       	push   $0x7000
f0100124:	68 e4 67 10 f0       	push   $0xf01067e4
f0100129:	6a 52                	push   $0x52
f010012b:	68 47 68 10 f0       	push   $0xf0106847
f0100130:	e8 0b ff ff ff       	call   f0100040 <_panic>
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100135:	89 d8                	mov    %ebx,%eax
f0100137:	2d 20 80 21 f0       	sub    $0xf0218020,%eax
f010013c:	c1 f8 02             	sar    $0x2,%eax
f010013f:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100145:	c1 e0 0f             	shl    $0xf,%eax
f0100148:	8d 80 00 10 22 f0    	lea    -0xfddf000(%eax),%eax
f010014e:	a3 84 7e 21 f0       	mov    %eax,0xf0217e84
		lapic_startap(c->cpu_id, PADDR(code));
f0100153:	83 ec 08             	sub    $0x8,%esp
f0100156:	68 00 70 00 00       	push   $0x7000
f010015b:	0f b6 03             	movzbl (%ebx),%eax
f010015e:	50                   	push   %eax
f010015f:	e8 4e 61 00 00       	call   f01062b2 <lapic_startap>
		while(c->cpu_status != CPU_STARTED)
f0100164:	83 c4 10             	add    $0x10,%esp
f0100167:	8b 43 04             	mov    0x4(%ebx),%eax
f010016a:	83 f8 01             	cmp    $0x1,%eax
f010016d:	75 f8                	jne    f0100167 <i386_init+0xc7>
	for (c = cpus; c < cpus + ncpu; c++) {
f010016f:	83 c3 74             	add    $0x74,%ebx
f0100172:	6b 05 c4 83 21 f0 74 	imul   $0x74,0xf02183c4,%eax
f0100179:	05 20 80 21 f0       	add    $0xf0218020,%eax
f010017e:	39 c3                	cmp    %eax,%ebx
f0100180:	73 13                	jae    f0100195 <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100182:	e8 b7 5f 00 00       	call   f010613e <cpunum>
f0100187:	6b c0 74             	imul   $0x74,%eax,%eax
f010018a:	05 20 80 21 f0       	add    $0xf0218020,%eax
f010018f:	39 c3                	cmp    %eax,%ebx
f0100191:	74 dc                	je     f010016f <i386_init+0xcf>
f0100193:	eb a0                	jmp    f0100135 <i386_init+0x95>
	ENV_CREATE(fs_fs, ENV_TYPE_FS);
f0100195:	83 ec 08             	sub    $0x8,%esp
f0100198:	6a 01                	push   $0x1
f010019a:	68 a8 38 1d f0       	push   $0xf01d38a8
f010019f:	e8 e9 31 00 00       	call   f010338d <env_create>
	ENV_CREATE(TEST, ENV_TYPE_USER);
f01001a4:	83 c4 08             	add    $0x8,%esp
f01001a7:	6a 00                	push   $0x0
f01001a9:	68 00 cd 1e f0       	push   $0xf01ecd00
f01001ae:	e8 da 31 00 00       	call   f010338d <env_create>
	kbd_intr();
f01001b3:	e8 5a 04 00 00       	call   f0100612 <kbd_intr>
	sched_yield();
f01001b8:	e8 a0 46 00 00       	call   f010485d <sched_yield>

f01001bd <mp_main>:
{
f01001bd:	f3 0f 1e fb          	endbr32 
f01001c1:	55                   	push   %ebp
f01001c2:	89 e5                	mov    %esp,%ebp
f01001c4:	83 ec 08             	sub    $0x8,%esp
	lcr3(PADDR(kern_pgdir));
f01001c7:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01001cc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001d1:	76 52                	jbe    f0100225 <mp_main+0x68>
	return (physaddr_t)kva - KERNBASE;
f01001d3:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01001d8:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001db:	e8 5e 5f 00 00       	call   f010613e <cpunum>
f01001e0:	83 ec 08             	sub    $0x8,%esp
f01001e3:	50                   	push   %eax
f01001e4:	68 53 68 10 f0       	push   $0xf0106853
f01001e9:	e8 cc 37 00 00       	call   f01039ba <cprintf>
	lapic_init();
f01001ee:	e8 65 5f 00 00       	call   f0106158 <lapic_init>
	env_init_percpu();
f01001f3:	e8 9e 2f 00 00       	call   f0103196 <env_init_percpu>
	trap_init_percpu();
f01001f8:	e8 d5 37 00 00       	call   f01039d2 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f01001fd:	e8 3c 5f 00 00       	call   f010613e <cpunum>
f0100202:	6b d0 74             	imul   $0x74,%eax,%edx
f0100205:	83 c2 04             	add    $0x4,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0100208:	b8 01 00 00 00       	mov    $0x1,%eax
f010020d:	f0 87 82 20 80 21 f0 	lock xchg %eax,-0xfde7fe0(%edx)
f0100214:	c7 04 24 c0 33 12 f0 	movl   $0xf01233c0,(%esp)
f010021b:	e8 a6 61 00 00       	call   f01063c6 <spin_lock>
	sched_yield();
f0100220:	e8 38 46 00 00       	call   f010485d <sched_yield>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100225:	50                   	push   %eax
f0100226:	68 08 68 10 f0       	push   $0xf0106808
f010022b:	6a 69                	push   $0x69
f010022d:	68 47 68 10 f0       	push   $0xf0106847
f0100232:	e8 09 fe ff ff       	call   f0100040 <_panic>

f0100237 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100237:	f3 0f 1e fb          	endbr32 
f010023b:	55                   	push   %ebp
f010023c:	89 e5                	mov    %esp,%ebp
f010023e:	53                   	push   %ebx
f010023f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100242:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100245:	ff 75 0c             	pushl  0xc(%ebp)
f0100248:	ff 75 08             	pushl  0x8(%ebp)
f010024b:	68 69 68 10 f0       	push   $0xf0106869
f0100250:	e8 65 37 00 00       	call   f01039ba <cprintf>
	vcprintf(fmt, ap);
f0100255:	83 c4 08             	add    $0x8,%esp
f0100258:	53                   	push   %ebx
f0100259:	ff 75 10             	pushl  0x10(%ebp)
f010025c:	e8 2f 37 00 00       	call   f0103990 <vcprintf>
	cprintf("\n");
f0100261:	c7 04 24 fd 79 10 f0 	movl   $0xf01079fd,(%esp)
f0100268:	e8 4d 37 00 00       	call   f01039ba <cprintf>
	va_end(ap);
}
f010026d:	83 c4 10             	add    $0x10,%esp
f0100270:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100273:	c9                   	leave  
f0100274:	c3                   	ret    

f0100275 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100275:	f3 0f 1e fb          	endbr32 
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100279:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010027e:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010027f:	a8 01                	test   $0x1,%al
f0100281:	74 0a                	je     f010028d <serial_proc_data+0x18>
f0100283:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100288:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100289:	0f b6 c0             	movzbl %al,%eax
f010028c:	c3                   	ret    
		return -1;
f010028d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0100292:	c3                   	ret    

f0100293 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100293:	55                   	push   %ebp
f0100294:	89 e5                	mov    %esp,%ebp
f0100296:	53                   	push   %ebx
f0100297:	83 ec 04             	sub    $0x4,%esp
f010029a:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010029c:	ff d3                	call   *%ebx
f010029e:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002a1:	74 29                	je     f01002cc <cons_intr+0x39>
		if (c == 0)
f01002a3:	85 c0                	test   %eax,%eax
f01002a5:	74 f5                	je     f010029c <cons_intr+0x9>
			continue;
		cons.buf[cons.wpos++] = c;
f01002a7:	8b 0d 24 72 21 f0    	mov    0xf0217224,%ecx
f01002ad:	8d 51 01             	lea    0x1(%ecx),%edx
f01002b0:	88 81 20 70 21 f0    	mov    %al,-0xfde8fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002b6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01002bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01002c1:	0f 44 d0             	cmove  %eax,%edx
f01002c4:	89 15 24 72 21 f0    	mov    %edx,0xf0217224
f01002ca:	eb d0                	jmp    f010029c <cons_intr+0x9>
	}
}
f01002cc:	83 c4 04             	add    $0x4,%esp
f01002cf:	5b                   	pop    %ebx
f01002d0:	5d                   	pop    %ebp
f01002d1:	c3                   	ret    

f01002d2 <kbd_proc_data>:
{
f01002d2:	f3 0f 1e fb          	endbr32 
f01002d6:	55                   	push   %ebp
f01002d7:	89 e5                	mov    %esp,%ebp
f01002d9:	53                   	push   %ebx
f01002da:	83 ec 04             	sub    $0x4,%esp
f01002dd:	ba 64 00 00 00       	mov    $0x64,%edx
f01002e2:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01002e3:	a8 01                	test   $0x1,%al
f01002e5:	0f 84 f2 00 00 00    	je     f01003dd <kbd_proc_data+0x10b>
	if (stat & KBS_TERR)
f01002eb:	a8 20                	test   $0x20,%al
f01002ed:	0f 85 f1 00 00 00    	jne    f01003e4 <kbd_proc_data+0x112>
f01002f3:	ba 60 00 00 00       	mov    $0x60,%edx
f01002f8:	ec                   	in     (%dx),%al
f01002f9:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01002fb:	3c e0                	cmp    $0xe0,%al
f01002fd:	74 61                	je     f0100360 <kbd_proc_data+0x8e>
	} else if (data & 0x80) {
f01002ff:	84 c0                	test   %al,%al
f0100301:	78 70                	js     f0100373 <kbd_proc_data+0xa1>
	} else if (shift & E0ESC) {
f0100303:	8b 0d 00 70 21 f0    	mov    0xf0217000,%ecx
f0100309:	f6 c1 40             	test   $0x40,%cl
f010030c:	74 0e                	je     f010031c <kbd_proc_data+0x4a>
		data |= 0x80;
f010030e:	83 c8 80             	or     $0xffffff80,%eax
f0100311:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100313:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100316:	89 0d 00 70 21 f0    	mov    %ecx,0xf0217000
	shift |= shiftcode[data];
f010031c:	0f b6 d2             	movzbl %dl,%edx
f010031f:	0f b6 82 e0 69 10 f0 	movzbl -0xfef9620(%edx),%eax
f0100326:	0b 05 00 70 21 f0    	or     0xf0217000,%eax
	shift ^= togglecode[data];
f010032c:	0f b6 8a e0 68 10 f0 	movzbl -0xfef9720(%edx),%ecx
f0100333:	31 c8                	xor    %ecx,%eax
f0100335:	a3 00 70 21 f0       	mov    %eax,0xf0217000
	c = charcode[shift & (CTL | SHIFT)][data];
f010033a:	89 c1                	mov    %eax,%ecx
f010033c:	83 e1 03             	and    $0x3,%ecx
f010033f:	8b 0c 8d c0 68 10 f0 	mov    -0xfef9740(,%ecx,4),%ecx
f0100346:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010034a:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010034d:	a8 08                	test   $0x8,%al
f010034f:	74 61                	je     f01003b2 <kbd_proc_data+0xe0>
		if ('a' <= c && c <= 'z')
f0100351:	89 da                	mov    %ebx,%edx
f0100353:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100356:	83 f9 19             	cmp    $0x19,%ecx
f0100359:	77 4b                	ja     f01003a6 <kbd_proc_data+0xd4>
			c += 'A' - 'a';
f010035b:	83 eb 20             	sub    $0x20,%ebx
f010035e:	eb 0c                	jmp    f010036c <kbd_proc_data+0x9a>
		shift |= E0ESC;
f0100360:	83 0d 00 70 21 f0 40 	orl    $0x40,0xf0217000
		return 0;
f0100367:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f010036c:	89 d8                	mov    %ebx,%eax
f010036e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100371:	c9                   	leave  
f0100372:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100373:	8b 0d 00 70 21 f0    	mov    0xf0217000,%ecx
f0100379:	89 cb                	mov    %ecx,%ebx
f010037b:	83 e3 40             	and    $0x40,%ebx
f010037e:	83 e0 7f             	and    $0x7f,%eax
f0100381:	85 db                	test   %ebx,%ebx
f0100383:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100386:	0f b6 d2             	movzbl %dl,%edx
f0100389:	0f b6 82 e0 69 10 f0 	movzbl -0xfef9620(%edx),%eax
f0100390:	83 c8 40             	or     $0x40,%eax
f0100393:	0f b6 c0             	movzbl %al,%eax
f0100396:	f7 d0                	not    %eax
f0100398:	21 c8                	and    %ecx,%eax
f010039a:	a3 00 70 21 f0       	mov    %eax,0xf0217000
		return 0;
f010039f:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003a4:	eb c6                	jmp    f010036c <kbd_proc_data+0x9a>
		else if ('A' <= c && c <= 'Z')
f01003a6:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01003a9:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003ac:	83 fa 1a             	cmp    $0x1a,%edx
f01003af:	0f 42 d9             	cmovb  %ecx,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003b2:	f7 d0                	not    %eax
f01003b4:	a8 06                	test   $0x6,%al
f01003b6:	75 b4                	jne    f010036c <kbd_proc_data+0x9a>
f01003b8:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003be:	75 ac                	jne    f010036c <kbd_proc_data+0x9a>
		cprintf("Rebooting!\n");
f01003c0:	83 ec 0c             	sub    $0xc,%esp
f01003c3:	68 83 68 10 f0       	push   $0xf0106883
f01003c8:	e8 ed 35 00 00       	call   f01039ba <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003cd:	b8 03 00 00 00       	mov    $0x3,%eax
f01003d2:	ba 92 00 00 00       	mov    $0x92,%edx
f01003d7:	ee                   	out    %al,(%dx)
}
f01003d8:	83 c4 10             	add    $0x10,%esp
f01003db:	eb 8f                	jmp    f010036c <kbd_proc_data+0x9a>
		return -1;
f01003dd:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01003e2:	eb 88                	jmp    f010036c <kbd_proc_data+0x9a>
		return -1;
f01003e4:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01003e9:	eb 81                	jmp    f010036c <kbd_proc_data+0x9a>

f01003eb <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003eb:	55                   	push   %ebp
f01003ec:	89 e5                	mov    %esp,%ebp
f01003ee:	57                   	push   %edi
f01003ef:	56                   	push   %esi
f01003f0:	53                   	push   %ebx
f01003f1:	83 ec 0c             	sub    $0xc,%esp
f01003f4:	89 c1                	mov    %eax,%ecx
	for (i = 0;
f01003f6:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003fb:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100400:	bb 84 00 00 00       	mov    $0x84,%ebx
f0100405:	89 fa                	mov    %edi,%edx
f0100407:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100408:	a8 20                	test   $0x20,%al
f010040a:	75 13                	jne    f010041f <cons_putc+0x34>
f010040c:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100412:	7f 0b                	jg     f010041f <cons_putc+0x34>
f0100414:	89 da                	mov    %ebx,%edx
f0100416:	ec                   	in     (%dx),%al
f0100417:	ec                   	in     (%dx),%al
f0100418:	ec                   	in     (%dx),%al
f0100419:	ec                   	in     (%dx),%al
	     i++)
f010041a:	83 c6 01             	add    $0x1,%esi
f010041d:	eb e6                	jmp    f0100405 <cons_putc+0x1a>
	outb(COM1 + COM_TX, c);
f010041f:	89 cf                	mov    %ecx,%edi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100421:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100426:	89 c8                	mov    %ecx,%eax
f0100428:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100429:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010042e:	bb 84 00 00 00       	mov    $0x84,%ebx
f0100433:	ba 79 03 00 00       	mov    $0x379,%edx
f0100438:	ec                   	in     (%dx),%al
f0100439:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010043f:	7f 0f                	jg     f0100450 <cons_putc+0x65>
f0100441:	84 c0                	test   %al,%al
f0100443:	78 0b                	js     f0100450 <cons_putc+0x65>
f0100445:	89 da                	mov    %ebx,%edx
f0100447:	ec                   	in     (%dx),%al
f0100448:	ec                   	in     (%dx),%al
f0100449:	ec                   	in     (%dx),%al
f010044a:	ec                   	in     (%dx),%al
f010044b:	83 c6 01             	add    $0x1,%esi
f010044e:	eb e3                	jmp    f0100433 <cons_putc+0x48>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100450:	ba 78 03 00 00       	mov    $0x378,%edx
f0100455:	89 f8                	mov    %edi,%eax
f0100457:	ee                   	out    %al,(%dx)
f0100458:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010045d:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100462:	ee                   	out    %al,(%dx)
f0100463:	b8 08 00 00 00       	mov    $0x8,%eax
f0100468:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100469:	f7 c1 00 ff ff ff    	test   $0xffffff00,%ecx
f010046f:	75 0a                	jne    f010047b <cons_putc+0x90>
		if(ch>47 && ch<58)
f0100471:	8d 47 d0             	lea    -0x30(%edi),%eax
f0100474:	3c 09                	cmp    $0x9,%al
f0100476:	77 5a                	ja     f01004d2 <cons_putc+0xe7>
			c |= 0x0200;
f0100478:	80 cd 02             	or     $0x2,%ch
	switch (c & 0xff) {
f010047b:	0f b6 c1             	movzbl %cl,%eax
f010047e:	80 f9 0a             	cmp    $0xa,%cl
f0100481:	0f 84 f3 00 00 00    	je     f010057a <cons_putc+0x18f>
f0100487:	83 f8 0a             	cmp    $0xa,%eax
f010048a:	7f 5c                	jg     f01004e8 <cons_putc+0xfd>
f010048c:	83 f8 08             	cmp    $0x8,%eax
f010048f:	0f 84 bd 00 00 00    	je     f0100552 <cons_putc+0x167>
f0100495:	83 f8 09             	cmp    $0x9,%eax
f0100498:	0f 85 e9 00 00 00    	jne    f0100587 <cons_putc+0x19c>
		cons_putc(' ');
f010049e:	b8 20 00 00 00       	mov    $0x20,%eax
f01004a3:	e8 43 ff ff ff       	call   f01003eb <cons_putc>
		cons_putc(' ');
f01004a8:	b8 20 00 00 00       	mov    $0x20,%eax
f01004ad:	e8 39 ff ff ff       	call   f01003eb <cons_putc>
		cons_putc(' ');
f01004b2:	b8 20 00 00 00       	mov    $0x20,%eax
f01004b7:	e8 2f ff ff ff       	call   f01003eb <cons_putc>
		cons_putc(' ');
f01004bc:	b8 20 00 00 00       	mov    $0x20,%eax
f01004c1:	e8 25 ff ff ff       	call   f01003eb <cons_putc>
		cons_putc(' ');
f01004c6:	b8 20 00 00 00       	mov    $0x20,%eax
f01004cb:	e8 1b ff ff ff       	call   f01003eb <cons_putc>
		break;
f01004d0:	eb 3b                	jmp    f010050d <cons_putc+0x122>
		else if((ch>64 && ch<91) || (ch>96 && ch<123))
f01004d2:	83 e7 df             	and    $0xffffffdf,%edi
f01004d5:	8d 57 bf             	lea    -0x41(%edi),%edx
			c |= 0x0700;
f01004d8:	89 cb                	mov    %ecx,%ebx
f01004da:	80 cf 07             	or     $0x7,%bh
f01004dd:	80 cd 04             	or     $0x4,%ch
f01004e0:	80 fa 19             	cmp    $0x19,%dl
f01004e3:	0f 46 cb             	cmovbe %ebx,%ecx
f01004e6:	eb 93                	jmp    f010047b <cons_putc+0x90>
	switch (c & 0xff) {
f01004e8:	83 f8 0d             	cmp    $0xd,%eax
f01004eb:	0f 85 96 00 00 00    	jne    f0100587 <cons_putc+0x19c>
		crt_pos -= (crt_pos % CRT_COLS);
f01004f1:	0f b7 05 28 72 21 f0 	movzwl 0xf0217228,%eax
f01004f8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004fe:	c1 e8 16             	shr    $0x16,%eax
f0100501:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100504:	c1 e0 04             	shl    $0x4,%eax
f0100507:	66 a3 28 72 21 f0    	mov    %ax,0xf0217228
	if (crt_pos >= CRT_SIZE) {
f010050d:	66 81 3d 28 72 21 f0 	cmpw   $0x7cf,0xf0217228
f0100514:	cf 07 
f0100516:	0f 87 8e 00 00 00    	ja     f01005aa <cons_putc+0x1bf>
	outb(addr_6845, 14);
f010051c:	8b 0d 30 72 21 f0    	mov    0xf0217230,%ecx
f0100522:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100527:	89 ca                	mov    %ecx,%edx
f0100529:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010052a:	0f b7 1d 28 72 21 f0 	movzwl 0xf0217228,%ebx
f0100531:	8d 71 01             	lea    0x1(%ecx),%esi
f0100534:	89 d8                	mov    %ebx,%eax
f0100536:	66 c1 e8 08          	shr    $0x8,%ax
f010053a:	89 f2                	mov    %esi,%edx
f010053c:	ee                   	out    %al,(%dx)
f010053d:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100542:	89 ca                	mov    %ecx,%edx
f0100544:	ee                   	out    %al,(%dx)
f0100545:	89 d8                	mov    %ebx,%eax
f0100547:	89 f2                	mov    %esi,%edx
f0100549:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010054a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010054d:	5b                   	pop    %ebx
f010054e:	5e                   	pop    %esi
f010054f:	5f                   	pop    %edi
f0100550:	5d                   	pop    %ebp
f0100551:	c3                   	ret    
		if (crt_pos > 0) {
f0100552:	0f b7 05 28 72 21 f0 	movzwl 0xf0217228,%eax
f0100559:	66 85 c0             	test   %ax,%ax
f010055c:	74 be                	je     f010051c <cons_putc+0x131>
			crt_pos--;
f010055e:	83 e8 01             	sub    $0x1,%eax
f0100561:	66 a3 28 72 21 f0    	mov    %ax,0xf0217228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100567:	0f b7 d0             	movzwl %ax,%edx
f010056a:	b1 00                	mov    $0x0,%cl
f010056c:	83 c9 20             	or     $0x20,%ecx
f010056f:	a1 2c 72 21 f0       	mov    0xf021722c,%eax
f0100574:	66 89 0c 50          	mov    %cx,(%eax,%edx,2)
f0100578:	eb 93                	jmp    f010050d <cons_putc+0x122>
		crt_pos += CRT_COLS;
f010057a:	66 83 05 28 72 21 f0 	addw   $0x50,0xf0217228
f0100581:	50 
f0100582:	e9 6a ff ff ff       	jmp    f01004f1 <cons_putc+0x106>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100587:	0f b7 05 28 72 21 f0 	movzwl 0xf0217228,%eax
f010058e:	8d 50 01             	lea    0x1(%eax),%edx
f0100591:	66 89 15 28 72 21 f0 	mov    %dx,0xf0217228
f0100598:	0f b7 c0             	movzwl %ax,%eax
f010059b:	8b 15 2c 72 21 f0    	mov    0xf021722c,%edx
f01005a1:	66 89 0c 42          	mov    %cx,(%edx,%eax,2)
		break;
f01005a5:	e9 63 ff ff ff       	jmp    f010050d <cons_putc+0x122>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005aa:	a1 2c 72 21 f0       	mov    0xf021722c,%eax
f01005af:	83 ec 04             	sub    $0x4,%esp
f01005b2:	68 00 0f 00 00       	push   $0xf00
f01005b7:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005bd:	52                   	push   %edx
f01005be:	50                   	push   %eax
f01005bf:	e8 a8 55 00 00       	call   f0105b6c <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01005c4:	8b 15 2c 72 21 f0    	mov    0xf021722c,%edx
f01005ca:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01005d0:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01005d6:	83 c4 10             	add    $0x10,%esp
f01005d9:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01005de:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005e1:	39 d0                	cmp    %edx,%eax
f01005e3:	75 f4                	jne    f01005d9 <cons_putc+0x1ee>
		crt_pos -= CRT_COLS;
f01005e5:	66 83 2d 28 72 21 f0 	subw   $0x50,0xf0217228
f01005ec:	50 
f01005ed:	e9 2a ff ff ff       	jmp    f010051c <cons_putc+0x131>

f01005f2 <serial_intr>:
{
f01005f2:	f3 0f 1e fb          	endbr32 
	if (serial_exists)
f01005f6:	80 3d 34 72 21 f0 00 	cmpb   $0x0,0xf0217234
f01005fd:	75 01                	jne    f0100600 <serial_intr+0xe>
f01005ff:	c3                   	ret    
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
f0100603:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100606:	b8 75 02 10 f0       	mov    $0xf0100275,%eax
f010060b:	e8 83 fc ff ff       	call   f0100293 <cons_intr>
}
f0100610:	c9                   	leave  
f0100611:	c3                   	ret    

f0100612 <kbd_intr>:
{
f0100612:	f3 0f 1e fb          	endbr32 
f0100616:	55                   	push   %ebp
f0100617:	89 e5                	mov    %esp,%ebp
f0100619:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010061c:	b8 d2 02 10 f0       	mov    $0xf01002d2,%eax
f0100621:	e8 6d fc ff ff       	call   f0100293 <cons_intr>
}
f0100626:	c9                   	leave  
f0100627:	c3                   	ret    

f0100628 <cons_getc>:
{
f0100628:	f3 0f 1e fb          	endbr32 
f010062c:	55                   	push   %ebp
f010062d:	89 e5                	mov    %esp,%ebp
f010062f:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f0100632:	e8 bb ff ff ff       	call   f01005f2 <serial_intr>
	kbd_intr();
f0100637:	e8 d6 ff ff ff       	call   f0100612 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f010063c:	a1 20 72 21 f0       	mov    0xf0217220,%eax
	return 0;
f0100641:	ba 00 00 00 00       	mov    $0x0,%edx
	if (cons.rpos != cons.wpos) {
f0100646:	3b 05 24 72 21 f0    	cmp    0xf0217224,%eax
f010064c:	74 1c                	je     f010066a <cons_getc+0x42>
		c = cons.buf[cons.rpos++];
f010064e:	8d 48 01             	lea    0x1(%eax),%ecx
f0100651:	0f b6 90 20 70 21 f0 	movzbl -0xfde8fe0(%eax),%edx
			cons.rpos = 0;
f0100658:	3d ff 01 00 00       	cmp    $0x1ff,%eax
f010065d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100662:	0f 45 c1             	cmovne %ecx,%eax
f0100665:	a3 20 72 21 f0       	mov    %eax,0xf0217220
}
f010066a:	89 d0                	mov    %edx,%eax
f010066c:	c9                   	leave  
f010066d:	c3                   	ret    

f010066e <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010066e:	f3 0f 1e fb          	endbr32 
f0100672:	55                   	push   %ebp
f0100673:	89 e5                	mov    %esp,%ebp
f0100675:	57                   	push   %edi
f0100676:	56                   	push   %esi
f0100677:	53                   	push   %ebx
f0100678:	83 ec 0c             	sub    $0xc,%esp
	was = *cp;
f010067b:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100682:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100689:	5a a5 
	if (*cp != 0xA55A) {
f010068b:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100692:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100696:	0f 84 de 00 00 00    	je     f010077a <cons_init+0x10c>
		addr_6845 = MONO_BASE;
f010069c:	c7 05 30 72 21 f0 b4 	movl   $0x3b4,0xf0217230
f01006a3:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01006a6:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
	outb(addr_6845, 14);
f01006ab:	8b 3d 30 72 21 f0    	mov    0xf0217230,%edi
f01006b1:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006b6:	89 fa                	mov    %edi,%edx
f01006b8:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006b9:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006bc:	89 ca                	mov    %ecx,%edx
f01006be:	ec                   	in     (%dx),%al
f01006bf:	0f b6 c0             	movzbl %al,%eax
f01006c2:	c1 e0 08             	shl    $0x8,%eax
f01006c5:	89 c3                	mov    %eax,%ebx
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006c7:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006cc:	89 fa                	mov    %edi,%edx
f01006ce:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006cf:	89 ca                	mov    %ecx,%edx
f01006d1:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f01006d2:	89 35 2c 72 21 f0    	mov    %esi,0xf021722c
	pos |= inb(addr_6845 + 1);
f01006d8:	0f b6 c0             	movzbl %al,%eax
f01006db:	09 d8                	or     %ebx,%eax
	crt_pos = pos;
f01006dd:	66 a3 28 72 21 f0    	mov    %ax,0xf0217228
	kbd_intr();
f01006e3:	e8 2a ff ff ff       	call   f0100612 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006e8:	83 ec 0c             	sub    $0xc,%esp
f01006eb:	0f b7 05 a8 33 12 f0 	movzwl 0xf01233a8,%eax
f01006f2:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006f7:	50                   	push   %eax
f01006f8:	e8 50 31 00 00       	call   f010384d <irq_setmask_8259A>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006fd:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100702:	b9 fa 03 00 00       	mov    $0x3fa,%ecx
f0100707:	89 d8                	mov    %ebx,%eax
f0100709:	89 ca                	mov    %ecx,%edx
f010070b:	ee                   	out    %al,(%dx)
f010070c:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100711:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100716:	89 fa                	mov    %edi,%edx
f0100718:	ee                   	out    %al,(%dx)
f0100719:	b8 0c 00 00 00       	mov    $0xc,%eax
f010071e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100723:	ee                   	out    %al,(%dx)
f0100724:	be f9 03 00 00       	mov    $0x3f9,%esi
f0100729:	89 d8                	mov    %ebx,%eax
f010072b:	89 f2                	mov    %esi,%edx
f010072d:	ee                   	out    %al,(%dx)
f010072e:	b8 03 00 00 00       	mov    $0x3,%eax
f0100733:	89 fa                	mov    %edi,%edx
f0100735:	ee                   	out    %al,(%dx)
f0100736:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010073b:	89 d8                	mov    %ebx,%eax
f010073d:	ee                   	out    %al,(%dx)
f010073e:	b8 01 00 00 00       	mov    $0x1,%eax
f0100743:	89 f2                	mov    %esi,%edx
f0100745:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100746:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010074b:	ec                   	in     (%dx),%al
f010074c:	89 c3                	mov    %eax,%ebx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010074e:	83 c4 10             	add    $0x10,%esp
f0100751:	3c ff                	cmp    $0xff,%al
f0100753:	0f 95 05 34 72 21 f0 	setne  0xf0217234
f010075a:	89 ca                	mov    %ecx,%edx
f010075c:	ec                   	in     (%dx),%al
f010075d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100762:	ec                   	in     (%dx),%al
	if (serial_exists)
f0100763:	80 fb ff             	cmp    $0xff,%bl
f0100766:	75 2d                	jne    f0100795 <cons_init+0x127>
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
		cprintf("Serial port does not exist!\n");
f0100768:	83 ec 0c             	sub    $0xc,%esp
f010076b:	68 8f 68 10 f0       	push   $0xf010688f
f0100770:	e8 45 32 00 00       	call   f01039ba <cprintf>
f0100775:	83 c4 10             	add    $0x10,%esp
}
f0100778:	eb 3c                	jmp    f01007b6 <cons_init+0x148>
		*cp = was;
f010077a:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100781:	c7 05 30 72 21 f0 d4 	movl   $0x3d4,0xf0217230
f0100788:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010078b:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f0100790:	e9 16 ff ff ff       	jmp    f01006ab <cons_init+0x3d>
		irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_SERIAL));
f0100795:	83 ec 0c             	sub    $0xc,%esp
f0100798:	0f b7 05 a8 33 12 f0 	movzwl 0xf01233a8,%eax
f010079f:	25 ef ff 00 00       	and    $0xffef,%eax
f01007a4:	50                   	push   %eax
f01007a5:	e8 a3 30 00 00       	call   f010384d <irq_setmask_8259A>
	if (!serial_exists)
f01007aa:	83 c4 10             	add    $0x10,%esp
f01007ad:	80 3d 34 72 21 f0 00 	cmpb   $0x0,0xf0217234
f01007b4:	74 b2                	je     f0100768 <cons_init+0xfa>
}
f01007b6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007b9:	5b                   	pop    %ebx
f01007ba:	5e                   	pop    %esi
f01007bb:	5f                   	pop    %edi
f01007bc:	5d                   	pop    %ebp
f01007bd:	c3                   	ret    

f01007be <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01007be:	f3 0f 1e fb          	endbr32 
f01007c2:	55                   	push   %ebp
f01007c3:	89 e5                	mov    %esp,%ebp
f01007c5:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01007c8:	8b 45 08             	mov    0x8(%ebp),%eax
f01007cb:	e8 1b fc ff ff       	call   f01003eb <cons_putc>
}
f01007d0:	c9                   	leave  
f01007d1:	c3                   	ret    

f01007d2 <getchar>:

int
getchar(void)
{
f01007d2:	f3 0f 1e fb          	endbr32 
f01007d6:	55                   	push   %ebp
f01007d7:	89 e5                	mov    %esp,%ebp
f01007d9:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01007dc:	e8 47 fe ff ff       	call   f0100628 <cons_getc>
f01007e1:	85 c0                	test   %eax,%eax
f01007e3:	74 f7                	je     f01007dc <getchar+0xa>
		/* do nothing */;
	return c;
}
f01007e5:	c9                   	leave  
f01007e6:	c3                   	ret    

f01007e7 <iscons>:

int
iscons(int fdnum)
{
f01007e7:	f3 0f 1e fb          	endbr32 
	// used by readline
	return 1;
}
f01007eb:	b8 01 00 00 00       	mov    $0x1,%eax
f01007f0:	c3                   	ret    

f01007f1 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007f1:	f3 0f 1e fb          	endbr32 
f01007f5:	55                   	push   %ebp
f01007f6:	89 e5                	mov    %esp,%ebp
f01007f8:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007fb:	68 e0 6a 10 f0       	push   $0xf0106ae0
f0100800:	68 fe 6a 10 f0       	push   $0xf0106afe
f0100805:	68 03 6b 10 f0       	push   $0xf0106b03
f010080a:	e8 ab 31 00 00       	call   f01039ba <cprintf>
f010080f:	83 c4 0c             	add    $0xc,%esp
f0100812:	68 d0 6b 10 f0       	push   $0xf0106bd0
f0100817:	68 0c 6b 10 f0       	push   $0xf0106b0c
f010081c:	68 03 6b 10 f0       	push   $0xf0106b03
f0100821:	e8 94 31 00 00       	call   f01039ba <cprintf>
f0100826:	83 c4 0c             	add    $0xc,%esp
f0100829:	68 15 6b 10 f0       	push   $0xf0106b15
f010082e:	68 2b 6b 10 f0       	push   $0xf0106b2b
f0100833:	68 03 6b 10 f0       	push   $0xf0106b03
f0100838:	e8 7d 31 00 00       	call   f01039ba <cprintf>
	return 0;
}
f010083d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100842:	c9                   	leave  
f0100843:	c3                   	ret    

f0100844 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100844:	f3 0f 1e fb          	endbr32 
f0100848:	55                   	push   %ebp
f0100849:	89 e5                	mov    %esp,%ebp
f010084b:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010084e:	68 35 6b 10 f0       	push   $0xf0106b35
f0100853:	e8 62 31 00 00       	call   f01039ba <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100858:	83 c4 08             	add    $0x8,%esp
f010085b:	68 0c 00 10 00       	push   $0x10000c
f0100860:	68 f8 6b 10 f0       	push   $0xf0106bf8
f0100865:	e8 50 31 00 00       	call   f01039ba <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010086a:	83 c4 0c             	add    $0xc,%esp
f010086d:	68 0c 00 10 00       	push   $0x10000c
f0100872:	68 0c 00 10 f0       	push   $0xf010000c
f0100877:	68 20 6c 10 f0       	push   $0xf0106c20
f010087c:	e8 39 31 00 00       	call   f01039ba <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100881:	83 c4 0c             	add    $0xc,%esp
f0100884:	68 ad 67 10 00       	push   $0x1067ad
f0100889:	68 ad 67 10 f0       	push   $0xf01067ad
f010088e:	68 44 6c 10 f0       	push   $0xf0106c44
f0100893:	e8 22 31 00 00       	call   f01039ba <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100898:	83 c4 0c             	add    $0xc,%esp
f010089b:	68 00 70 21 00       	push   $0x217000
f01008a0:	68 00 70 21 f0       	push   $0xf0217000
f01008a5:	68 68 6c 10 f0       	push   $0xf0106c68
f01008aa:	e8 0b 31 00 00       	call   f01039ba <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01008af:	83 c4 0c             	add    $0xc,%esp
f01008b2:	68 09 90 25 00       	push   $0x259009
f01008b7:	68 09 90 25 f0       	push   $0xf0259009
f01008bc:	68 8c 6c 10 f0       	push   $0xf0106c8c
f01008c1:	e8 f4 30 00 00       	call   f01039ba <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008c6:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01008c9:	b8 09 90 25 f0       	mov    $0xf0259009,%eax
f01008ce:	2d 0d fc 0f f0       	sub    $0xf00ffc0d,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008d3:	c1 f8 0a             	sar    $0xa,%eax
f01008d6:	50                   	push   %eax
f01008d7:	68 b0 6c 10 f0       	push   $0xf0106cb0
f01008dc:	e8 d9 30 00 00       	call   f01039ba <cprintf>
	return 0;
}
f01008e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01008e6:	c9                   	leave  
f01008e7:	c3                   	ret    

f01008e8 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008e8:	f3 0f 1e fb          	endbr32 
f01008ec:	55                   	push   %ebp
f01008ed:	89 e5                	mov    %esp,%ebp
f01008ef:	57                   	push   %edi
f01008f0:	56                   	push   %esi
f01008f1:	53                   	push   %ebx
f01008f2:	83 ec 48             	sub    $0x48,%esp
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008f5:	89 e8                	mov    %ebp,%eax
f01008f7:	89 c3                	mov    %eax,%ebx
	// Your code here.
	// typedef int (*this_func_type)(int, char **, struct Trapframe *);
	uint32_t ebp = read_ebp();
	uint32_t *ebp_base_ptr = (uint32_t*)ebp;           
f01008f9:	89 c6                	mov    %eax,%esi
	uint32_t eip = ebp_base_ptr[1];
f01008fb:	8b 40 04             	mov    0x4(%eax),%eax
f01008fe:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	cprintf("Stack backtrace:\n");
f0100901:	68 4e 6b 10 f0       	push   $0xf0106b4e
f0100906:	e8 af 30 00 00       	call   f01039ba <cprintf>
	while (ebp != 0) {
f010090b:	83 c4 10             	add    $0x10,%esp
f010090e:	eb 0a                	jmp    f010091a <mon_backtrace+0x32>
		{
			uint32_t offset = eip-info.eip_fn_addr;
			cprintf("\t\t%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,offset);
		}
        // update the values
        ebp = (uint32_t)*ebp_base_ptr;
f0100910:	8b 36                	mov    (%esi),%esi
		ebp_base_ptr = (uint32_t*)ebp;
f0100912:	89 f3                	mov    %esi,%ebx
        eip = ebp_base_ptr[1];
f0100914:	8b 46 04             	mov    0x4(%esi),%eax
f0100917:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	while (ebp != 0) {
f010091a:	85 db                	test   %ebx,%ebx
f010091c:	74 7e                	je     f010099c <mon_backtrace+0xb4>
        cprintf("\tebp %08x, eip %09x, args ", ebp, eip);
f010091e:	83 ec 04             	sub    $0x4,%esp
f0100921:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100924:	53                   	push   %ebx
f0100925:	68 60 6b 10 f0       	push   $0xf0106b60
f010092a:	e8 8b 30 00 00       	call   f01039ba <cprintf>
f010092f:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100932:	8d 7e 1c             	lea    0x1c(%esi),%edi
f0100935:	83 c4 10             	add    $0x10,%esp
            cprintf("%08x ", args[i]);
f0100938:	83 ec 08             	sub    $0x8,%esp
f010093b:	ff 33                	pushl  (%ebx)
f010093d:	68 7b 6b 10 f0       	push   $0xf0106b7b
f0100942:	e8 73 30 00 00       	call   f01039ba <cprintf>
f0100947:	83 c3 04             	add    $0x4,%ebx
        for (int i = 0; i < 5; ++i) {
f010094a:	83 c4 10             	add    $0x10,%esp
f010094d:	39 fb                	cmp    %edi,%ebx
f010094f:	75 e7                	jne    f0100938 <mon_backtrace+0x50>
        cprintf("\n");
f0100951:	83 ec 0c             	sub    $0xc,%esp
f0100954:	68 fd 79 10 f0       	push   $0xf01079fd
f0100959:	e8 5c 30 00 00       	call   f01039ba <cprintf>
        if(debuginfo_eip(eip,&info) == 0)
f010095e:	83 c4 08             	add    $0x8,%esp
f0100961:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100964:	50                   	push   %eax
f0100965:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100968:	e8 6e 46 00 00       	call   f0104fdb <debuginfo_eip>
f010096d:	83 c4 10             	add    $0x10,%esp
f0100970:	85 c0                	test   %eax,%eax
f0100972:	75 9c                	jne    f0100910 <mon_backtrace+0x28>
			cprintf("\t\t%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,offset);
f0100974:	83 ec 08             	sub    $0x8,%esp
			uint32_t offset = eip-info.eip_fn_addr;
f0100977:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010097a:	2b 45 e0             	sub    -0x20(%ebp),%eax
			cprintf("\t\t%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,offset);
f010097d:	50                   	push   %eax
f010097e:	ff 75 d8             	pushl  -0x28(%ebp)
f0100981:	ff 75 dc             	pushl  -0x24(%ebp)
f0100984:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100987:	ff 75 d0             	pushl  -0x30(%ebp)
f010098a:	68 81 6b 10 f0       	push   $0xf0106b81
f010098f:	e8 26 30 00 00       	call   f01039ba <cprintf>
f0100994:	83 c4 20             	add    $0x20,%esp
f0100997:	e9 74 ff ff ff       	jmp    f0100910 <mon_backtrace+0x28>
	}

	return 0;
}
f010099c:	b8 00 00 00 00       	mov    $0x0,%eax
f01009a1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009a4:	5b                   	pop    %ebx
f01009a5:	5e                   	pop    %esi
f01009a6:	5f                   	pop    %edi
f01009a7:	5d                   	pop    %ebp
f01009a8:	c3                   	ret    

f01009a9 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01009a9:	f3 0f 1e fb          	endbr32 
f01009ad:	55                   	push   %ebp
f01009ae:	89 e5                	mov    %esp,%ebp
f01009b0:	57                   	push   %edi
f01009b1:	56                   	push   %esi
f01009b2:	53                   	push   %ebx
f01009b3:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01009b6:	68 dc 6c 10 f0       	push   $0xf0106cdc
f01009bb:	e8 fa 2f 00 00       	call   f01039ba <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009c0:	c7 04 24 00 6d 10 f0 	movl   $0xf0106d00,(%esp)
f01009c7:	e8 ee 2f 00 00       	call   f01039ba <cprintf>

	if (tf != NULL)
f01009cc:	83 c4 10             	add    $0x10,%esp
f01009cf:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01009d3:	0f 84 d9 00 00 00    	je     f0100ab2 <monitor+0x109>
		print_trapframe(tf);
f01009d9:	83 ec 0c             	sub    $0xc,%esp
f01009dc:	ff 75 08             	pushl  0x8(%ebp)
f01009df:	e8 81 37 00 00       	call   f0104165 <print_trapframe>
f01009e4:	83 c4 10             	add    $0x10,%esp
f01009e7:	e9 c6 00 00 00       	jmp    f0100ab2 <monitor+0x109>
		while (*buf && strchr(WHITESPACE, *buf))
f01009ec:	83 ec 08             	sub    $0x8,%esp
f01009ef:	0f be c0             	movsbl %al,%eax
f01009f2:	50                   	push   %eax
f01009f3:	68 97 6b 10 f0       	push   $0xf0106b97
f01009f8:	e8 de 50 00 00       	call   f0105adb <strchr>
f01009fd:	83 c4 10             	add    $0x10,%esp
f0100a00:	85 c0                	test   %eax,%eax
f0100a02:	74 63                	je     f0100a67 <monitor+0xbe>
			*buf++ = 0;
f0100a04:	c6 03 00             	movb   $0x0,(%ebx)
f0100a07:	89 f7                	mov    %esi,%edi
f0100a09:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100a0c:	89 fe                	mov    %edi,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f0100a0e:	0f b6 03             	movzbl (%ebx),%eax
f0100a11:	84 c0                	test   %al,%al
f0100a13:	75 d7                	jne    f01009ec <monitor+0x43>
	argv[argc] = 0;
f0100a15:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100a1c:	00 
	if (argc == 0)
f0100a1d:	85 f6                	test   %esi,%esi
f0100a1f:	0f 84 8d 00 00 00    	je     f0100ab2 <monitor+0x109>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a25:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a2a:	83 ec 08             	sub    $0x8,%esp
f0100a2d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a30:	ff 34 85 40 6d 10 f0 	pushl  -0xfef92c0(,%eax,4)
f0100a37:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a3a:	e8 36 50 00 00       	call   f0105a75 <strcmp>
f0100a3f:	83 c4 10             	add    $0x10,%esp
f0100a42:	85 c0                	test   %eax,%eax
f0100a44:	0f 84 8f 00 00 00    	je     f0100ad9 <monitor+0x130>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a4a:	83 c3 01             	add    $0x1,%ebx
f0100a4d:	83 fb 03             	cmp    $0x3,%ebx
f0100a50:	75 d8                	jne    f0100a2a <monitor+0x81>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a52:	83 ec 08             	sub    $0x8,%esp
f0100a55:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a58:	68 b9 6b 10 f0       	push   $0xf0106bb9
f0100a5d:	e8 58 2f 00 00       	call   f01039ba <cprintf>
	return 0;
f0100a62:	83 c4 10             	add    $0x10,%esp
f0100a65:	eb 4b                	jmp    f0100ab2 <monitor+0x109>
		if (*buf == 0)
f0100a67:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100a6a:	74 a9                	je     f0100a15 <monitor+0x6c>
		if (argc == MAXARGS-1) {
f0100a6c:	83 fe 0f             	cmp    $0xf,%esi
f0100a6f:	74 2f                	je     f0100aa0 <monitor+0xf7>
		argv[argc++] = buf;
f0100a71:	8d 7e 01             	lea    0x1(%esi),%edi
f0100a74:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a78:	0f b6 03             	movzbl (%ebx),%eax
f0100a7b:	84 c0                	test   %al,%al
f0100a7d:	74 8d                	je     f0100a0c <monitor+0x63>
f0100a7f:	83 ec 08             	sub    $0x8,%esp
f0100a82:	0f be c0             	movsbl %al,%eax
f0100a85:	50                   	push   %eax
f0100a86:	68 97 6b 10 f0       	push   $0xf0106b97
f0100a8b:	e8 4b 50 00 00       	call   f0105adb <strchr>
f0100a90:	83 c4 10             	add    $0x10,%esp
f0100a93:	85 c0                	test   %eax,%eax
f0100a95:	0f 85 71 ff ff ff    	jne    f0100a0c <monitor+0x63>
			buf++;
f0100a9b:	83 c3 01             	add    $0x1,%ebx
f0100a9e:	eb d8                	jmp    f0100a78 <monitor+0xcf>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100aa0:	83 ec 08             	sub    $0x8,%esp
f0100aa3:	6a 10                	push   $0x10
f0100aa5:	68 9c 6b 10 f0       	push   $0xf0106b9c
f0100aaa:	e8 0b 2f 00 00       	call   f01039ba <cprintf>
			return 0;
f0100aaf:	83 c4 10             	add    $0x10,%esp
	// cprintf("x %d, y %x, z %d\n", x, y, z);
	// unsigned int i = 0x00646c72;
 	// cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100ab2:	83 ec 0c             	sub    $0xc,%esp
f0100ab5:	68 93 6b 10 f0       	push   $0xf0106b93
f0100aba:	e8 c2 4d 00 00       	call   f0105881 <readline>
f0100abf:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100ac1:	83 c4 10             	add    $0x10,%esp
f0100ac4:	85 c0                	test   %eax,%eax
f0100ac6:	74 ea                	je     f0100ab2 <monitor+0x109>
	argv[argc] = 0;
f0100ac8:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100acf:	be 00 00 00 00       	mov    $0x0,%esi
f0100ad4:	e9 35 ff ff ff       	jmp    f0100a0e <monitor+0x65>
			return commands[i].func(argc, argv, tf);
f0100ad9:	83 ec 04             	sub    $0x4,%esp
f0100adc:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100adf:	ff 75 08             	pushl  0x8(%ebp)
f0100ae2:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100ae5:	52                   	push   %edx
f0100ae6:	56                   	push   %esi
f0100ae7:	ff 14 85 48 6d 10 f0 	call   *-0xfef92b8(,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100aee:	83 c4 10             	add    $0x10,%esp
f0100af1:	85 c0                	test   %eax,%eax
f0100af3:	79 bd                	jns    f0100ab2 <monitor+0x109>
				break;
	}
}
f0100af5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100af8:	5b                   	pop    %ebx
f0100af9:	5e                   	pop    %esi
f0100afa:	5f                   	pop    %edi
f0100afb:	5d                   	pop    %ebp
f0100afc:	c3                   	ret    

f0100afd <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100afd:	55                   	push   %ebp
f0100afe:	89 e5                	mov    %esp,%ebp
f0100b00:	56                   	push   %esi
f0100b01:	53                   	push   %ebx
f0100b02:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100b04:	83 ec 0c             	sub    $0xc,%esp
f0100b07:	50                   	push   %eax
f0100b08:	e8 0a 2d 00 00       	call   f0103817 <mc146818_read>
f0100b0d:	89 c6                	mov    %eax,%esi
f0100b0f:	83 c3 01             	add    $0x1,%ebx
f0100b12:	89 1c 24             	mov    %ebx,(%esp)
f0100b15:	e8 fd 2c 00 00       	call   f0103817 <mc146818_read>
f0100b1a:	c1 e0 08             	shl    $0x8,%eax
f0100b1d:	09 f0                	or     %esi,%eax
}
f0100b1f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100b22:	5b                   	pop    %ebx
f0100b23:	5e                   	pop    %esi
f0100b24:	5d                   	pop    %ebp
f0100b25:	c3                   	ret    

f0100b26 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b26:	83 3d 38 72 21 f0 00 	cmpl   $0x0,0xf0217238
f0100b2d:	74 36                	je     f0100b65 <boot_alloc+0x3f>
	// LAB 2: Your code here.

	// special case
	if(n == 0)
	{
		return nextfree;
f0100b2f:	8b 15 38 72 21 f0    	mov    0xf0217238,%edx
	if(n == 0)
f0100b35:	85 c0                	test   %eax,%eax
f0100b37:	74 29                	je     f0100b62 <boot_alloc+0x3c>
	}

	// allocate memory 
	result = nextfree;
f0100b39:	8b 15 38 72 21 f0    	mov    0xf0217238,%edx
	nextfree = ROUNDUP(n,PGSIZE)+nextfree;
f0100b3f:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100b44:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b49:	01 d0                	add    %edx,%eax
f0100b4b:	a3 38 72 21 f0       	mov    %eax,0xf0217238

	// out of memory panic
	if((uint32_t)nextfree-KERNBASE>(npages*PGSIZE))
f0100b50:	05 00 00 00 10       	add    $0x10000000,%eax
f0100b55:	8b 0d 88 7e 21 f0    	mov    0xf0217e88,%ecx
f0100b5b:	c1 e1 0c             	shl    $0xc,%ecx
f0100b5e:	39 c8                	cmp    %ecx,%eax
f0100b60:	77 16                	ja     f0100b78 <boot_alloc+0x52>
		nextfree = result;
		return NULL;
	}
	return result;

}
f0100b62:	89 d0                	mov    %edx,%eax
f0100b64:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b65:	ba 08 a0 25 f0       	mov    $0xf025a008,%edx
f0100b6a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b70:	89 15 38 72 21 f0    	mov    %edx,0xf0217238
f0100b76:	eb b7                	jmp    f0100b2f <boot_alloc+0x9>
{
f0100b78:	55                   	push   %ebp
f0100b79:	89 e5                	mov    %esp,%ebp
f0100b7b:	83 ec 0c             	sub    $0xc,%esp
		panic("at pmap.c:boot_alloc(): out of memory");
f0100b7e:	68 64 6d 10 f0       	push   $0xf0106d64
f0100b83:	6a 7c                	push   $0x7c
f0100b85:	68 1d 77 10 f0       	push   $0xf010771d
f0100b8a:	e8 b1 f4 ff ff       	call   f0100040 <_panic>

f0100b8f <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b8f:	89 d1                	mov    %edx,%ecx
f0100b91:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100b94:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100b97:	a8 01                	test   $0x1,%al
f0100b99:	74 51                	je     f0100bec <check_va2pa+0x5d>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b9b:	89 c1                	mov    %eax,%ecx
f0100b9d:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	if (PGNUM(pa) >= npages)
f0100ba3:	c1 e8 0c             	shr    $0xc,%eax
f0100ba6:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0100bac:	73 23                	jae    f0100bd1 <check_va2pa+0x42>
	if (!(p[PTX(va)] & PTE_P))
f0100bae:	c1 ea 0c             	shr    $0xc,%edx
f0100bb1:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100bb7:	8b 94 91 00 00 00 f0 	mov    -0x10000000(%ecx,%edx,4),%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100bbe:	89 d0                	mov    %edx,%eax
f0100bc0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100bc5:	f6 c2 01             	test   $0x1,%dl
f0100bc8:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100bcd:	0f 44 c2             	cmove  %edx,%eax
f0100bd0:	c3                   	ret    
{
f0100bd1:	55                   	push   %ebp
f0100bd2:	89 e5                	mov    %esp,%ebp
f0100bd4:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bd7:	51                   	push   %ecx
f0100bd8:	68 e4 67 10 f0       	push   $0xf01067e4
f0100bdd:	68 05 04 00 00       	push   $0x405
f0100be2:	68 1d 77 10 f0       	push   $0xf010771d
f0100be7:	e8 54 f4 ff ff       	call   f0100040 <_panic>
		return ~0;
f0100bec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0100bf1:	c3                   	ret    

f0100bf2 <check_page_free_list>:
{
f0100bf2:	55                   	push   %ebp
f0100bf3:	89 e5                	mov    %esp,%ebp
f0100bf5:	57                   	push   %edi
f0100bf6:	56                   	push   %esi
f0100bf7:	53                   	push   %ebx
f0100bf8:	83 ec 2c             	sub    $0x2c,%esp
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bfb:	84 c0                	test   %al,%al
f0100bfd:	0f 85 77 02 00 00    	jne    f0100e7a <check_page_free_list+0x288>
	if (!page_free_list)
f0100c03:	83 3d 40 72 21 f0 00 	cmpl   $0x0,0xf0217240
f0100c0a:	74 0a                	je     f0100c16 <check_page_free_list+0x24>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c0c:	be 00 04 00 00       	mov    $0x400,%esi
f0100c11:	e9 bf 02 00 00       	jmp    f0100ed5 <check_page_free_list+0x2e3>
		panic("'page_free_list' is a null pointer!");
f0100c16:	83 ec 04             	sub    $0x4,%esp
f0100c19:	68 8c 6d 10 f0       	push   $0xf0106d8c
f0100c1e:	68 38 03 00 00       	push   $0x338
f0100c23:	68 1d 77 10 f0       	push   $0xf010771d
f0100c28:	e8 13 f4 ff ff       	call   f0100040 <_panic>
f0100c2d:	50                   	push   %eax
f0100c2e:	68 e4 67 10 f0       	push   $0xf01067e4
f0100c33:	6a 58                	push   $0x58
f0100c35:	68 29 77 10 f0       	push   $0xf0107729
f0100c3a:	e8 01 f4 ff ff       	call   f0100040 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c3f:	8b 1b                	mov    (%ebx),%ebx
f0100c41:	85 db                	test   %ebx,%ebx
f0100c43:	74 41                	je     f0100c86 <check_page_free_list+0x94>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c45:	89 d8                	mov    %ebx,%eax
f0100c47:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0100c4d:	c1 f8 03             	sar    $0x3,%eax
f0100c50:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c53:	89 c2                	mov    %eax,%edx
f0100c55:	c1 ea 16             	shr    $0x16,%edx
f0100c58:	39 f2                	cmp    %esi,%edx
f0100c5a:	73 e3                	jae    f0100c3f <check_page_free_list+0x4d>
	if (PGNUM(pa) >= npages)
f0100c5c:	89 c2                	mov    %eax,%edx
f0100c5e:	c1 ea 0c             	shr    $0xc,%edx
f0100c61:	3b 15 88 7e 21 f0    	cmp    0xf0217e88,%edx
f0100c67:	73 c4                	jae    f0100c2d <check_page_free_list+0x3b>
			memset(page2kva(pp), 0x97, 128);
f0100c69:	83 ec 04             	sub    $0x4,%esp
f0100c6c:	68 80 00 00 00       	push   $0x80
f0100c71:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100c76:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c7b:	50                   	push   %eax
f0100c7c:	e8 9f 4e 00 00       	call   f0105b20 <memset>
f0100c81:	83 c4 10             	add    $0x10,%esp
f0100c84:	eb b9                	jmp    f0100c3f <check_page_free_list+0x4d>
	first_free_page = (char *) boot_alloc(0);
f0100c86:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c8b:	e8 96 fe ff ff       	call   f0100b26 <boot_alloc>
f0100c90:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c93:	8b 15 40 72 21 f0    	mov    0xf0217240,%edx
		assert(pp >= pages);
f0100c99:	8b 0d 90 7e 21 f0    	mov    0xf0217e90,%ecx
		assert(pp < pages + npages);
f0100c9f:	a1 88 7e 21 f0       	mov    0xf0217e88,%eax
f0100ca4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100ca7:	8d 34 c1             	lea    (%ecx,%eax,8),%esi
	int nfree_basemem = 0, nfree_extmem = 0;
f0100caa:	bf 00 00 00 00       	mov    $0x0,%edi
f0100caf:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cb2:	e9 f9 00 00 00       	jmp    f0100db0 <check_page_free_list+0x1be>
		assert(pp >= pages);
f0100cb7:	68 37 77 10 f0       	push   $0xf0107737
f0100cbc:	68 43 77 10 f0       	push   $0xf0107743
f0100cc1:	68 52 03 00 00       	push   $0x352
f0100cc6:	68 1d 77 10 f0       	push   $0xf010771d
f0100ccb:	e8 70 f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100cd0:	68 58 77 10 f0       	push   $0xf0107758
f0100cd5:	68 43 77 10 f0       	push   $0xf0107743
f0100cda:	68 53 03 00 00       	push   $0x353
f0100cdf:	68 1d 77 10 f0       	push   $0xf010771d
f0100ce4:	e8 57 f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ce9:	68 b0 6d 10 f0       	push   $0xf0106db0
f0100cee:	68 43 77 10 f0       	push   $0xf0107743
f0100cf3:	68 54 03 00 00       	push   $0x354
f0100cf8:	68 1d 77 10 f0       	push   $0xf010771d
f0100cfd:	e8 3e f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != 0);
f0100d02:	68 6c 77 10 f0       	push   $0xf010776c
f0100d07:	68 43 77 10 f0       	push   $0xf0107743
f0100d0c:	68 57 03 00 00       	push   $0x357
f0100d11:	68 1d 77 10 f0       	push   $0xf010771d
f0100d16:	e8 25 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d1b:	68 7d 77 10 f0       	push   $0xf010777d
f0100d20:	68 43 77 10 f0       	push   $0xf0107743
f0100d25:	68 58 03 00 00       	push   $0x358
f0100d2a:	68 1d 77 10 f0       	push   $0xf010771d
f0100d2f:	e8 0c f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d34:	68 e4 6d 10 f0       	push   $0xf0106de4
f0100d39:	68 43 77 10 f0       	push   $0xf0107743
f0100d3e:	68 59 03 00 00       	push   $0x359
f0100d43:	68 1d 77 10 f0       	push   $0xf010771d
f0100d48:	e8 f3 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d4d:	68 96 77 10 f0       	push   $0xf0107796
f0100d52:	68 43 77 10 f0       	push   $0xf0107743
f0100d57:	68 5a 03 00 00       	push   $0x35a
f0100d5c:	68 1d 77 10 f0       	push   $0xf010771d
f0100d61:	e8 da f2 ff ff       	call   f0100040 <_panic>
	if (PGNUM(pa) >= npages)
f0100d66:	89 c3                	mov    %eax,%ebx
f0100d68:	c1 eb 0c             	shr    $0xc,%ebx
f0100d6b:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0100d6e:	76 0f                	jbe    f0100d7f <check_page_free_list+0x18d>
	return (void *)(pa + KERNBASE);
f0100d70:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d75:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100d78:	77 17                	ja     f0100d91 <check_page_free_list+0x19f>
			++nfree_extmem;
f0100d7a:	83 c7 01             	add    $0x1,%edi
f0100d7d:	eb 2f                	jmp    f0100dae <check_page_free_list+0x1bc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d7f:	50                   	push   %eax
f0100d80:	68 e4 67 10 f0       	push   $0xf01067e4
f0100d85:	6a 58                	push   $0x58
f0100d87:	68 29 77 10 f0       	push   $0xf0107729
f0100d8c:	e8 af f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d91:	68 08 6e 10 f0       	push   $0xf0106e08
f0100d96:	68 43 77 10 f0       	push   $0xf0107743
f0100d9b:	68 5b 03 00 00       	push   $0x35b
f0100da0:	68 1d 77 10 f0       	push   $0xf010771d
f0100da5:	e8 96 f2 ff ff       	call   f0100040 <_panic>
			++nfree_basemem;
f0100daa:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100dae:	8b 12                	mov    (%edx),%edx
f0100db0:	85 d2                	test   %edx,%edx
f0100db2:	74 74                	je     f0100e28 <check_page_free_list+0x236>
		assert(pp >= pages);
f0100db4:	39 d1                	cmp    %edx,%ecx
f0100db6:	0f 87 fb fe ff ff    	ja     f0100cb7 <check_page_free_list+0xc5>
		assert(pp < pages + npages);
f0100dbc:	39 d6                	cmp    %edx,%esi
f0100dbe:	0f 86 0c ff ff ff    	jbe    f0100cd0 <check_page_free_list+0xde>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100dc4:	89 d0                	mov    %edx,%eax
f0100dc6:	29 c8                	sub    %ecx,%eax
f0100dc8:	a8 07                	test   $0x7,%al
f0100dca:	0f 85 19 ff ff ff    	jne    f0100ce9 <check_page_free_list+0xf7>
	return (pp - pages) << PGSHIFT;
f0100dd0:	c1 f8 03             	sar    $0x3,%eax
		assert(page2pa(pp) != 0);
f0100dd3:	c1 e0 0c             	shl    $0xc,%eax
f0100dd6:	0f 84 26 ff ff ff    	je     f0100d02 <check_page_free_list+0x110>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ddc:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100de1:	0f 84 34 ff ff ff    	je     f0100d1b <check_page_free_list+0x129>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100de7:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100dec:	0f 84 42 ff ff ff    	je     f0100d34 <check_page_free_list+0x142>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100df2:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100df7:	0f 84 50 ff ff ff    	je     f0100d4d <check_page_free_list+0x15b>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100dfd:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100e02:	0f 87 5e ff ff ff    	ja     f0100d66 <check_page_free_list+0x174>
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100e08:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e0d:	75 9b                	jne    f0100daa <check_page_free_list+0x1b8>
f0100e0f:	68 b0 77 10 f0       	push   $0xf01077b0
f0100e14:	68 43 77 10 f0       	push   $0xf0107743
f0100e19:	68 5d 03 00 00       	push   $0x35d
f0100e1e:	68 1d 77 10 f0       	push   $0xf010771d
f0100e23:	e8 18 f2 ff ff       	call   f0100040 <_panic>
f0100e28:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
	assert(nfree_basemem > 0);
f0100e2b:	85 db                	test   %ebx,%ebx
f0100e2d:	7e 19                	jle    f0100e48 <check_page_free_list+0x256>
	assert(nfree_extmem > 0);
f0100e2f:	85 ff                	test   %edi,%edi
f0100e31:	7e 2e                	jle    f0100e61 <check_page_free_list+0x26f>
	cprintf("check_page_free_list() succeeded!\n");
f0100e33:	83 ec 0c             	sub    $0xc,%esp
f0100e36:	68 50 6e 10 f0       	push   $0xf0106e50
f0100e3b:	e8 7a 2b 00 00       	call   f01039ba <cprintf>
}
f0100e40:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e43:	5b                   	pop    %ebx
f0100e44:	5e                   	pop    %esi
f0100e45:	5f                   	pop    %edi
f0100e46:	5d                   	pop    %ebp
f0100e47:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e48:	68 cd 77 10 f0       	push   $0xf01077cd
f0100e4d:	68 43 77 10 f0       	push   $0xf0107743
f0100e52:	68 65 03 00 00       	push   $0x365
f0100e57:	68 1d 77 10 f0       	push   $0xf010771d
f0100e5c:	e8 df f1 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100e61:	68 df 77 10 f0       	push   $0xf01077df
f0100e66:	68 43 77 10 f0       	push   $0xf0107743
f0100e6b:	68 66 03 00 00       	push   $0x366
f0100e70:	68 1d 77 10 f0       	push   $0xf010771d
f0100e75:	e8 c6 f1 ff ff       	call   f0100040 <_panic>
	if (!page_free_list)
f0100e7a:	a1 40 72 21 f0       	mov    0xf0217240,%eax
f0100e7f:	85 c0                	test   %eax,%eax
f0100e81:	0f 84 8f fd ff ff    	je     f0100c16 <check_page_free_list+0x24>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100e87:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100e8a:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e8d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e90:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100e93:	89 c2                	mov    %eax,%edx
f0100e95:	2b 15 90 7e 21 f0    	sub    0xf0217e90,%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100e9b:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100ea1:	0f 95 c2             	setne  %dl
f0100ea4:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ea7:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100eab:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ead:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100eb1:	8b 00                	mov    (%eax),%eax
f0100eb3:	85 c0                	test   %eax,%eax
f0100eb5:	75 dc                	jne    f0100e93 <check_page_free_list+0x2a1>
		*tp[1] = 0;
f0100eb7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100eba:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100ec0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ec3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ec6:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ec8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ecb:	a3 40 72 21 f0       	mov    %eax,0xf0217240
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ed0:	be 01 00 00 00       	mov    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ed5:	8b 1d 40 72 21 f0    	mov    0xf0217240,%ebx
f0100edb:	e9 61 fd ff ff       	jmp    f0100c41 <check_page_free_list+0x4f>

f0100ee0 <page_init>:
{
f0100ee0:	f3 0f 1e fb          	endbr32 
f0100ee4:	55                   	push   %ebp
f0100ee5:	89 e5                	mov    %esp,%ebp
f0100ee7:	57                   	push   %edi
f0100ee8:	56                   	push   %esi
f0100ee9:	53                   	push   %ebx
f0100eea:	83 ec 0c             	sub    $0xc,%esp
	size_t num_used = (PADDR(boot_alloc(0))-EXTPHYSMEM)/PGSIZE;
f0100eed:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ef2:	e8 2f fc ff ff       	call   f0100b26 <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f0100ef7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100efc:	76 24                	jbe    f0100f22 <page_init+0x42>
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100efe:	8b 0d 44 72 21 f0    	mov    0xf0217244,%ecx
	size_t num_used = (PADDR(boot_alloc(0))-EXTPHYSMEM)/PGSIZE;
f0100f04:	05 00 00 f0 0f       	add    $0xff00000,%eax
f0100f09:	c1 e8 0c             	shr    $0xc,%eax
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100f0c:	8d 74 01 60          	lea    0x60(%ecx,%eax,1),%esi
f0100f10:	8b 1d 40 72 21 f0    	mov    0xf0217240,%ebx
	for(size_t i = 0;i<npages;i++)
f0100f16:	bf 00 00 00 00       	mov    $0x0,%edi
f0100f1b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f20:	eb 60                	jmp    f0100f82 <page_init+0xa2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100f22:	50                   	push   %eax
f0100f23:	68 08 68 10 f0       	push   $0xf0106808
f0100f28:	68 4f 01 00 00       	push   $0x14f
f0100f2d:	68 1d 77 10 f0       	push   $0xf010771d
f0100f32:	e8 09 f1 ff ff       	call   f0100040 <_panic>
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100f37:	39 c1                	cmp    %eax,%ecx
f0100f39:	77 1b                	ja     f0100f56 <page_init+0x76>
f0100f3b:	39 c6                	cmp    %eax,%esi
f0100f3d:	76 17                	jbe    f0100f56 <page_init+0x76>
			pages[i].pp_ref = 1;
f0100f3f:	8b 15 90 7e 21 f0    	mov    0xf0217e90,%edx
f0100f45:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100f48:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
			pages[i].pp_link = NULL;
f0100f4e:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
f0100f54:	eb 29                	jmp    f0100f7f <page_init+0x9f>
		else if(i == mpentry)
f0100f56:	83 f8 07             	cmp    $0x7,%eax
f0100f59:	74 47                	je     f0100fa2 <page_init+0xc2>
f0100f5b:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
			pages[i].pp_ref = 0;
f0100f62:	89 d7                	mov    %edx,%edi
f0100f64:	03 3d 90 7e 21 f0    	add    0xf0217e90,%edi
f0100f6a:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
			pages[i].pp_link = page_free_list;
f0100f70:	89 1f                	mov    %ebx,(%edi)
			page_free_list = &pages[i];
f0100f72:	89 d3                	mov    %edx,%ebx
f0100f74:	03 1d 90 7e 21 f0    	add    0xf0217e90,%ebx
f0100f7a:	bf 01 00 00 00       	mov    $0x1,%edi
	for(size_t i = 0;i<npages;i++)
f0100f7f:	83 c0 01             	add    $0x1,%eax
f0100f82:	39 05 88 7e 21 f0    	cmp    %eax,0xf0217e88
f0100f88:	76 2d                	jbe    f0100fb7 <page_init+0xd7>
		if(i == 0)
f0100f8a:	85 c0                	test   %eax,%eax
f0100f8c:	75 a9                	jne    f0100f37 <page_init+0x57>
			pages[i].pp_ref = 1;
f0100f8e:	8b 15 90 7e 21 f0    	mov    0xf0217e90,%edx
f0100f94:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
			pages[i].pp_link = NULL;
f0100f9a:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
f0100fa0:	eb dd                	jmp    f0100f7f <page_init+0x9f>
			pages[i].pp_ref = 1;
f0100fa2:	8b 15 90 7e 21 f0    	mov    0xf0217e90,%edx
f0100fa8:	66 c7 42 3c 01 00    	movw   $0x1,0x3c(%edx)
			pages[i].pp_link = NULL;
f0100fae:	c7 42 38 00 00 00 00 	movl   $0x0,0x38(%edx)
f0100fb5:	eb c8                	jmp    f0100f7f <page_init+0x9f>
f0100fb7:	89 f8                	mov    %edi,%eax
f0100fb9:	84 c0                	test   %al,%al
f0100fbb:	74 06                	je     f0100fc3 <page_init+0xe3>
f0100fbd:	89 1d 40 72 21 f0    	mov    %ebx,0xf0217240
}
f0100fc3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fc6:	5b                   	pop    %ebx
f0100fc7:	5e                   	pop    %esi
f0100fc8:	5f                   	pop    %edi
f0100fc9:	5d                   	pop    %ebp
f0100fca:	c3                   	ret    

f0100fcb <page_alloc>:
{
f0100fcb:	f3 0f 1e fb          	endbr32 
f0100fcf:	55                   	push   %ebp
f0100fd0:	89 e5                	mov    %esp,%ebp
f0100fd2:	53                   	push   %ebx
f0100fd3:	83 ec 04             	sub    $0x4,%esp
	if(page_free_list == NULL)
f0100fd6:	8b 1d 40 72 21 f0    	mov    0xf0217240,%ebx
f0100fdc:	85 db                	test   %ebx,%ebx
f0100fde:	74 30                	je     f0101010 <page_alloc+0x45>
	page_free_list = page_free_list->pp_link;
f0100fe0:	8b 03                	mov    (%ebx),%eax
f0100fe2:	a3 40 72 21 f0       	mov    %eax,0xf0217240
	alloc->pp_link = NULL;
f0100fe7:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	return (pp - pages) << PGSHIFT;
f0100fed:	89 d8                	mov    %ebx,%eax
f0100fef:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0100ff5:	c1 f8 03             	sar    $0x3,%eax
f0100ff8:	89 c2                	mov    %eax,%edx
f0100ffa:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0100ffd:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101002:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0101008:	73 0d                	jae    f0101017 <page_alloc+0x4c>
	if(alloc_flags & ALLOC_ZERO)
f010100a:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f010100e:	75 19                	jne    f0101029 <page_alloc+0x5e>
}
f0101010:	89 d8                	mov    %ebx,%eax
f0101012:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101015:	c9                   	leave  
f0101016:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101017:	52                   	push   %edx
f0101018:	68 e4 67 10 f0       	push   $0xf01067e4
f010101d:	6a 58                	push   $0x58
f010101f:	68 29 77 10 f0       	push   $0xf0107729
f0101024:	e8 17 f0 ff ff       	call   f0100040 <_panic>
		memset(head,0,PGSIZE);
f0101029:	83 ec 04             	sub    $0x4,%esp
f010102c:	68 00 10 00 00       	push   $0x1000
f0101031:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0101033:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101039:	52                   	push   %edx
f010103a:	e8 e1 4a 00 00       	call   f0105b20 <memset>
f010103f:	83 c4 10             	add    $0x10,%esp
f0101042:	eb cc                	jmp    f0101010 <page_alloc+0x45>

f0101044 <page_free>:
{
f0101044:	f3 0f 1e fb          	endbr32 
f0101048:	55                   	push   %ebp
f0101049:	89 e5                	mov    %esp,%ebp
f010104b:	83 ec 08             	sub    $0x8,%esp
f010104e:	8b 45 08             	mov    0x8(%ebp),%eax
	if((pp->pp_ref != 0) | (pp->pp_link != NULL))  // referenced or freed
f0101051:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101056:	75 14                	jne    f010106c <page_free+0x28>
f0101058:	83 38 00             	cmpl   $0x0,(%eax)
f010105b:	75 0f                	jne    f010106c <page_free+0x28>
	pp->pp_link = page_free_list;
f010105d:	8b 15 40 72 21 f0    	mov    0xf0217240,%edx
f0101063:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101065:	a3 40 72 21 f0       	mov    %eax,0xf0217240
}
f010106a:	c9                   	leave  
f010106b:	c3                   	ret    
		panic("at pmap.c:page_free(): Page double free or freeing a referenced page");
f010106c:	83 ec 04             	sub    $0x4,%esp
f010106f:	68 74 6e 10 f0       	push   $0xf0106e74
f0101074:	68 b0 01 00 00       	push   $0x1b0
f0101079:	68 1d 77 10 f0       	push   $0xf010771d
f010107e:	e8 bd ef ff ff       	call   f0100040 <_panic>

f0101083 <page_decref>:
{
f0101083:	f3 0f 1e fb          	endbr32 
f0101087:	55                   	push   %ebp
f0101088:	89 e5                	mov    %esp,%ebp
f010108a:	83 ec 08             	sub    $0x8,%esp
f010108d:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101090:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101094:	83 e8 01             	sub    $0x1,%eax
f0101097:	66 89 42 04          	mov    %ax,0x4(%edx)
f010109b:	66 85 c0             	test   %ax,%ax
f010109e:	74 02                	je     f01010a2 <page_decref+0x1f>
}
f01010a0:	c9                   	leave  
f01010a1:	c3                   	ret    
		page_free(pp);
f01010a2:	83 ec 0c             	sub    $0xc,%esp
f01010a5:	52                   	push   %edx
f01010a6:	e8 99 ff ff ff       	call   f0101044 <page_free>
f01010ab:	83 c4 10             	add    $0x10,%esp
}
f01010ae:	eb f0                	jmp    f01010a0 <page_decref+0x1d>

f01010b0 <pgdir_walk>:
{
f01010b0:	f3 0f 1e fb          	endbr32 
f01010b4:	55                   	push   %ebp
f01010b5:	89 e5                	mov    %esp,%ebp
f01010b7:	56                   	push   %esi
f01010b8:	53                   	push   %ebx
f01010b9:	8b 75 0c             	mov    0xc(%ebp),%esi
	unsigned int dir_offset = PDX(va);
f01010bc:	89 f3                	mov    %esi,%ebx
f01010be:	c1 eb 16             	shr    $0x16,%ebx
	pde_t* entry = pgdir+dir_offset;
f01010c1:	c1 e3 02             	shl    $0x2,%ebx
f01010c4:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*entry & PTE_P))
f01010c7:	f6 03 01             	testb  $0x1,(%ebx)
f01010ca:	75 2d                	jne    f01010f9 <pgdir_walk+0x49>
		if(create)
f01010cc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01010d0:	74 68                	je     f010113a <pgdir_walk+0x8a>
			new_page = page_alloc(1);
f01010d2:	83 ec 0c             	sub    $0xc,%esp
f01010d5:	6a 01                	push   $0x1
f01010d7:	e8 ef fe ff ff       	call   f0100fcb <page_alloc>
			if(new_page == NULL)
f01010dc:	83 c4 10             	add    $0x10,%esp
f01010df:	85 c0                	test   %eax,%eax
f01010e1:	74 3b                	je     f010111e <pgdir_walk+0x6e>
			new_page->pp_ref++;
f01010e3:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f01010e8:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f01010ee:	c1 f8 03             	sar    $0x3,%eax
f01010f1:	c1 e0 0c             	shl    $0xc,%eax
			*entry = ((page2pa(new_page))|PTE_P|PTE_W|PTE_U);
f01010f4:	83 c8 07             	or     $0x7,%eax
f01010f7:	89 03                	mov    %eax,(%ebx)
	page_base = (pte_t*)KADDR(PTE_ADDR(*entry));
f01010f9:	8b 03                	mov    (%ebx),%eax
f01010fb:	89 c2                	mov    %eax,%edx
f01010fd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101103:	c1 e8 0c             	shr    $0xc,%eax
f0101106:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f010110c:	73 17                	jae    f0101125 <pgdir_walk+0x75>
	page_offset = PTX(va);
f010110e:	c1 ee 0a             	shr    $0xa,%esi
	return &page_base[page_offset];
f0101111:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101117:	8d 84 32 00 00 00 f0 	lea    -0x10000000(%edx,%esi,1),%eax
}
f010111e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101121:	5b                   	pop    %ebx
f0101122:	5e                   	pop    %esi
f0101123:	5d                   	pop    %ebp
f0101124:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101125:	52                   	push   %edx
f0101126:	68 e4 67 10 f0       	push   $0xf01067e4
f010112b:	68 fd 01 00 00       	push   $0x1fd
f0101130:	68 1d 77 10 f0       	push   $0xf010771d
f0101135:	e8 06 ef ff ff       	call   f0100040 <_panic>
			return NULL;
f010113a:	b8 00 00 00 00       	mov    $0x0,%eax
f010113f:	eb dd                	jmp    f010111e <pgdir_walk+0x6e>

f0101141 <boot_map_region>:
{
f0101141:	55                   	push   %ebp
f0101142:	89 e5                	mov    %esp,%ebp
f0101144:	57                   	push   %edi
f0101145:	56                   	push   %esi
f0101146:	53                   	push   %ebx
f0101147:	83 ec 1c             	sub    $0x1c,%esp
f010114a:	89 c7                	mov    %eax,%edi
f010114c:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010114f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for(add = 0;add<size;add+=PGSIZE)
f0101152:	be 00 00 00 00       	mov    $0x0,%esi
f0101157:	89 f3                	mov    %esi,%ebx
f0101159:	03 5d 08             	add    0x8(%ebp),%ebx
f010115c:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f010115f:	76 24                	jbe    f0101185 <boot_map_region+0x44>
		entry = pgdir_walk(pgdir,(void*)va,1);  // get the entry of page table
f0101161:	83 ec 04             	sub    $0x4,%esp
f0101164:	6a 01                	push   $0x1
f0101166:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101169:	01 f0                	add    %esi,%eax
f010116b:	50                   	push   %eax
f010116c:	57                   	push   %edi
f010116d:	e8 3e ff ff ff       	call   f01010b0 <pgdir_walk>
		*entry = (pa|perm|PTE_P);
f0101172:	0b 5d 0c             	or     0xc(%ebp),%ebx
f0101175:	83 cb 01             	or     $0x1,%ebx
f0101178:	89 18                	mov    %ebx,(%eax)
	for(add = 0;add<size;add+=PGSIZE)
f010117a:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0101180:	83 c4 10             	add    $0x10,%esp
f0101183:	eb d2                	jmp    f0101157 <boot_map_region+0x16>
}
f0101185:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101188:	5b                   	pop    %ebx
f0101189:	5e                   	pop    %esi
f010118a:	5f                   	pop    %edi
f010118b:	5d                   	pop    %ebp
f010118c:	c3                   	ret    

f010118d <page_lookup>:
{
f010118d:	f3 0f 1e fb          	endbr32 
f0101191:	55                   	push   %ebp
f0101192:	89 e5                	mov    %esp,%ebp
f0101194:	53                   	push   %ebx
f0101195:	83 ec 08             	sub    $0x8,%esp
f0101198:	8b 5d 10             	mov    0x10(%ebp),%ebx
	entry = pgdir_walk(pgdir,va,0);
f010119b:	6a 00                	push   $0x0
f010119d:	ff 75 0c             	pushl  0xc(%ebp)
f01011a0:	ff 75 08             	pushl  0x8(%ebp)
f01011a3:	e8 08 ff ff ff       	call   f01010b0 <pgdir_walk>
	if(entry == NULL)
f01011a8:	83 c4 10             	add    $0x10,%esp
f01011ab:	85 c0                	test   %eax,%eax
f01011ad:	74 3c                	je     f01011eb <page_lookup+0x5e>
	if(!(*entry & PTE_P))
f01011af:	8b 10                	mov    (%eax),%edx
f01011b1:	f6 c2 01             	test   $0x1,%dl
f01011b4:	74 39                	je     f01011ef <page_lookup+0x62>
f01011b6:	c1 ea 0c             	shr    $0xc,%edx
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011b9:	39 15 88 7e 21 f0    	cmp    %edx,0xf0217e88
f01011bf:	76 16                	jbe    f01011d7 <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f01011c1:	8b 0d 90 7e 21 f0    	mov    0xf0217e90,%ecx
f01011c7:	8d 14 d1             	lea    (%ecx,%edx,8),%edx
	if(pte_store != NULL)
f01011ca:	85 db                	test   %ebx,%ebx
f01011cc:	74 02                	je     f01011d0 <page_lookup+0x43>
		*pte_store = entry;
f01011ce:	89 03                	mov    %eax,(%ebx)
}
f01011d0:	89 d0                	mov    %edx,%eax
f01011d2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01011d5:	c9                   	leave  
f01011d6:	c3                   	ret    
		panic("pa2page called with invalid pa");
f01011d7:	83 ec 04             	sub    $0x4,%esp
f01011da:	68 bc 6e 10 f0       	push   $0xf0106ebc
f01011df:	6a 51                	push   $0x51
f01011e1:	68 29 77 10 f0       	push   $0xf0107729
f01011e6:	e8 55 ee ff ff       	call   f0100040 <_panic>
		return NULL;
f01011eb:	89 c2                	mov    %eax,%edx
f01011ed:	eb e1                	jmp    f01011d0 <page_lookup+0x43>
		return NULL;
f01011ef:	ba 00 00 00 00       	mov    $0x0,%edx
f01011f4:	eb da                	jmp    f01011d0 <page_lookup+0x43>

f01011f6 <tlb_invalidate>:
{
f01011f6:	f3 0f 1e fb          	endbr32 
f01011fa:	55                   	push   %ebp
f01011fb:	89 e5                	mov    %esp,%ebp
f01011fd:	83 ec 08             	sub    $0x8,%esp
	if (!curenv || curenv->env_pgdir == pgdir)
f0101200:	e8 39 4f 00 00       	call   f010613e <cpunum>
f0101205:	6b c0 74             	imul   $0x74,%eax,%eax
f0101208:	83 b8 28 80 21 f0 00 	cmpl   $0x0,-0xfde7fd8(%eax)
f010120f:	74 16                	je     f0101227 <tlb_invalidate+0x31>
f0101211:	e8 28 4f 00 00       	call   f010613e <cpunum>
f0101216:	6b c0 74             	imul   $0x74,%eax,%eax
f0101219:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f010121f:	8b 55 08             	mov    0x8(%ebp),%edx
f0101222:	39 50 60             	cmp    %edx,0x60(%eax)
f0101225:	75 06                	jne    f010122d <tlb_invalidate+0x37>
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101227:	8b 45 0c             	mov    0xc(%ebp),%eax
f010122a:	0f 01 38             	invlpg (%eax)
}
f010122d:	c9                   	leave  
f010122e:	c3                   	ret    

f010122f <page_remove>:
{
f010122f:	f3 0f 1e fb          	endbr32 
f0101233:	55                   	push   %ebp
f0101234:	89 e5                	mov    %esp,%ebp
f0101236:	56                   	push   %esi
f0101237:	53                   	push   %ebx
f0101238:	83 ec 14             	sub    $0x14,%esp
f010123b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010123e:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t* pte = NULL;
f0101241:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo* page = page_lookup(pgdir,va,&pte);
f0101248:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010124b:	50                   	push   %eax
f010124c:	56                   	push   %esi
f010124d:	53                   	push   %ebx
f010124e:	e8 3a ff ff ff       	call   f010118d <page_lookup>
	if(page == NULL)
f0101253:	83 c4 10             	add    $0x10,%esp
f0101256:	85 c0                	test   %eax,%eax
f0101258:	74 1f                	je     f0101279 <page_remove+0x4a>
	page_decref(page);
f010125a:	83 ec 0c             	sub    $0xc,%esp
f010125d:	50                   	push   %eax
f010125e:	e8 20 fe ff ff       	call   f0101083 <page_decref>
	tlb_invalidate(pgdir,va);
f0101263:	83 c4 08             	add    $0x8,%esp
f0101266:	56                   	push   %esi
f0101267:	53                   	push   %ebx
f0101268:	e8 89 ff ff ff       	call   f01011f6 <tlb_invalidate>
	*pte = 0;
f010126d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101270:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101276:	83 c4 10             	add    $0x10,%esp
}
f0101279:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010127c:	5b                   	pop    %ebx
f010127d:	5e                   	pop    %esi
f010127e:	5d                   	pop    %ebp
f010127f:	c3                   	ret    

f0101280 <page_insert>:
{
f0101280:	f3 0f 1e fb          	endbr32 
f0101284:	55                   	push   %ebp
f0101285:	89 e5                	mov    %esp,%ebp
f0101287:	57                   	push   %edi
f0101288:	56                   	push   %esi
f0101289:	53                   	push   %ebx
f010128a:	83 ec 10             	sub    $0x10,%esp
f010128d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101290:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	entry = pgdir_walk(pgdir,va,1); // get the page table entry 
f0101293:	6a 01                	push   $0x1
f0101295:	ff 75 10             	pushl  0x10(%ebp)
f0101298:	57                   	push   %edi
f0101299:	e8 12 fe ff ff       	call   f01010b0 <pgdir_walk>
	if(entry == NULL)
f010129e:	83 c4 10             	add    $0x10,%esp
f01012a1:	85 c0                	test   %eax,%eax
f01012a3:	74 56                	je     f01012fb <page_insert+0x7b>
f01012a5:	89 c6                	mov    %eax,%esi
	pp->pp_ref++;
f01012a7:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if(*entry&PTE_P)
f01012ac:	f6 00 01             	testb  $0x1,(%eax)
f01012af:	75 2d                	jne    f01012de <page_insert+0x5e>
	return (pp - pages) << PGSHIFT;
f01012b1:	2b 1d 90 7e 21 f0    	sub    0xf0217e90,%ebx
f01012b7:	c1 fb 03             	sar    $0x3,%ebx
f01012ba:	c1 e3 0c             	shl    $0xc,%ebx
	*entry = ((page2pa(pp))|perm|PTE_P);
f01012bd:	0b 5d 14             	or     0x14(%ebp),%ebx
f01012c0:	83 cb 01             	or     $0x1,%ebx
f01012c3:	89 1e                	mov    %ebx,(%esi)
	pgdir[PDX(va)] |= perm;
f01012c5:	8b 45 10             	mov    0x10(%ebp),%eax
f01012c8:	c1 e8 16             	shr    $0x16,%eax
f01012cb:	8b 55 14             	mov    0x14(%ebp),%edx
f01012ce:	09 14 87             	or     %edx,(%edi,%eax,4)
	return 0;
f01012d1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01012d6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012d9:	5b                   	pop    %ebx
f01012da:	5e                   	pop    %esi
f01012db:	5f                   	pop    %edi
f01012dc:	5d                   	pop    %ebp
f01012dd:	c3                   	ret    
		tlb_invalidate(pgdir,va);
f01012de:	83 ec 08             	sub    $0x8,%esp
f01012e1:	ff 75 10             	pushl  0x10(%ebp)
f01012e4:	57                   	push   %edi
f01012e5:	e8 0c ff ff ff       	call   f01011f6 <tlb_invalidate>
		page_remove(pgdir,va);
f01012ea:	83 c4 08             	add    $0x8,%esp
f01012ed:	ff 75 10             	pushl  0x10(%ebp)
f01012f0:	57                   	push   %edi
f01012f1:	e8 39 ff ff ff       	call   f010122f <page_remove>
f01012f6:	83 c4 10             	add    $0x10,%esp
f01012f9:	eb b6                	jmp    f01012b1 <page_insert+0x31>
		return -E_NO_MEM;
f01012fb:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0101300:	eb d4                	jmp    f01012d6 <page_insert+0x56>

f0101302 <mmio_map_region>:
{
f0101302:	f3 0f 1e fb          	endbr32 
f0101306:	55                   	push   %ebp
f0101307:	89 e5                	mov    %esp,%ebp
f0101309:	57                   	push   %edi
f010130a:	56                   	push   %esi
f010130b:	53                   	push   %ebx
f010130c:	83 ec 0c             	sub    $0xc,%esp
f010130f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	size = ROUNDUP(pa+size,PGSIZE);
f0101312:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101315:	8d bc 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%edi
f010131c:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	pa = ROUNDDOWN(pa,PGSIZE);
f0101322:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	size-=pa;
f0101328:	89 fe                	mov    %edi,%esi
f010132a:	29 de                	sub    %ebx,%esi
	if(size+base>=MMIOLIM)
f010132c:	8b 15 00 33 12 f0    	mov    0xf0123300,%edx
f0101332:	8d 04 32             	lea    (%edx,%esi,1),%eax
f0101335:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f010133a:	77 2b                	ja     f0101367 <mmio_map_region+0x65>
	boot_map_region(kern_pgdir,base,size,pa,PTE_W|PTE_PCD|PTE_PWT);
f010133c:	83 ec 08             	sub    $0x8,%esp
f010133f:	6a 1a                	push   $0x1a
f0101341:	53                   	push   %ebx
f0101342:	89 f1                	mov    %esi,%ecx
f0101344:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0101349:	e8 f3 fd ff ff       	call   f0101141 <boot_map_region>
	base+=size;
f010134e:	89 f0                	mov    %esi,%eax
f0101350:	03 05 00 33 12 f0    	add    0xf0123300,%eax
f0101356:	a3 00 33 12 f0       	mov    %eax,0xf0123300
	return (void*)(base-size);
f010135b:	29 fb                	sub    %edi,%ebx
f010135d:	01 d8                	add    %ebx,%eax
}
f010135f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101362:	5b                   	pop    %ebx
f0101363:	5e                   	pop    %esi
f0101364:	5f                   	pop    %edi
f0101365:	5d                   	pop    %ebp
f0101366:	c3                   	ret    
		panic("At mmio_map_region(): overflow MMIOLIM");
f0101367:	83 ec 04             	sub    $0x4,%esp
f010136a:	68 dc 6e 10 f0       	push   $0xf0106edc
f010136f:	68 d1 02 00 00       	push   $0x2d1
f0101374:	68 1d 77 10 f0       	push   $0xf010771d
f0101379:	e8 c2 ec ff ff       	call   f0100040 <_panic>

f010137e <mem_init>:
{
f010137e:	f3 0f 1e fb          	endbr32 
f0101382:	55                   	push   %ebp
f0101383:	89 e5                	mov    %esp,%ebp
f0101385:	57                   	push   %edi
f0101386:	56                   	push   %esi
f0101387:	53                   	push   %ebx
f0101388:	83 ec 3c             	sub    $0x3c,%esp
	basemem = nvram_read(NVRAM_BASELO);
f010138b:	b8 15 00 00 00       	mov    $0x15,%eax
f0101390:	e8 68 f7 ff ff       	call   f0100afd <nvram_read>
f0101395:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101397:	b8 17 00 00 00       	mov    $0x17,%eax
f010139c:	e8 5c f7 ff ff       	call   f0100afd <nvram_read>
f01013a1:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01013a3:	b8 34 00 00 00       	mov    $0x34,%eax
f01013a8:	e8 50 f7 ff ff       	call   f0100afd <nvram_read>
	if (ext16mem)
f01013ad:	c1 e0 06             	shl    $0x6,%eax
f01013b0:	0f 84 ea 00 00 00    	je     f01014a0 <mem_init+0x122>
		totalmem = 16 * 1024 + ext16mem;
f01013b6:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f01013bb:	89 c2                	mov    %eax,%edx
f01013bd:	c1 ea 02             	shr    $0x2,%edx
f01013c0:	89 15 88 7e 21 f0    	mov    %edx,0xf0217e88
	npages_basemem = basemem / (PGSIZE / 1024);
f01013c6:	89 da                	mov    %ebx,%edx
f01013c8:	c1 ea 02             	shr    $0x2,%edx
f01013cb:	89 15 44 72 21 f0    	mov    %edx,0xf0217244
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013d1:	89 c2                	mov    %eax,%edx
f01013d3:	29 da                	sub    %ebx,%edx
f01013d5:	52                   	push   %edx
f01013d6:	53                   	push   %ebx
f01013d7:	50                   	push   %eax
f01013d8:	68 04 6f 10 f0       	push   $0xf0106f04
f01013dd:	e8 d8 25 00 00       	call   f01039ba <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01013e2:	b8 00 10 00 00       	mov    $0x1000,%eax
f01013e7:	e8 3a f7 ff ff       	call   f0100b26 <boot_alloc>
f01013ec:	a3 8c 7e 21 f0       	mov    %eax,0xf0217e8c
	memset(kern_pgdir, 0, PGSIZE);
f01013f1:	83 c4 0c             	add    $0xc,%esp
f01013f4:	68 00 10 00 00       	push   $0x1000
f01013f9:	6a 00                	push   $0x0
f01013fb:	50                   	push   %eax
f01013fc:	e8 1f 47 00 00       	call   f0105b20 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101401:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0101406:	83 c4 10             	add    $0x10,%esp
f0101409:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010140e:	0f 86 9c 00 00 00    	jbe    f01014b0 <mem_init+0x132>
	return (physaddr_t)kva - KERNBASE;
f0101414:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010141a:	83 ca 05             	or     $0x5,%edx
f010141d:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages*sizeof(struct PageInfo));
f0101423:	a1 88 7e 21 f0       	mov    0xf0217e88,%eax
f0101428:	c1 e0 03             	shl    $0x3,%eax
f010142b:	e8 f6 f6 ff ff       	call   f0100b26 <boot_alloc>
f0101430:	a3 90 7e 21 f0       	mov    %eax,0xf0217e90
	memset(pages,0,npages*sizeof(struct PageInfo));
f0101435:	83 ec 04             	sub    $0x4,%esp
f0101438:	8b 0d 88 7e 21 f0    	mov    0xf0217e88,%ecx
f010143e:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101445:	52                   	push   %edx
f0101446:	6a 00                	push   $0x0
f0101448:	50                   	push   %eax
f0101449:	e8 d2 46 00 00       	call   f0105b20 <memset>
	envs = (struct Env*)boot_alloc(NENV*sizeof(struct Env));
f010144e:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101453:	e8 ce f6 ff ff       	call   f0100b26 <boot_alloc>
f0101458:	a3 48 72 21 f0       	mov    %eax,0xf0217248
	memset(envs,0,NENV*sizeof(struct Env));
f010145d:	83 c4 0c             	add    $0xc,%esp
f0101460:	68 00 f0 01 00       	push   $0x1f000
f0101465:	6a 00                	push   $0x0
f0101467:	50                   	push   %eax
f0101468:	e8 b3 46 00 00       	call   f0105b20 <memset>
	page_init();
f010146d:	e8 6e fa ff ff       	call   f0100ee0 <page_init>
	check_page_free_list(1);
f0101472:	b8 01 00 00 00       	mov    $0x1,%eax
f0101477:	e8 76 f7 ff ff       	call   f0100bf2 <check_page_free_list>
	if (!pages)
f010147c:	83 c4 10             	add    $0x10,%esp
f010147f:	83 3d 90 7e 21 f0 00 	cmpl   $0x0,0xf0217e90
f0101486:	74 3d                	je     f01014c5 <mem_init+0x147>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101488:	a1 40 72 21 f0       	mov    0xf0217240,%eax
f010148d:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0101494:	85 c0                	test   %eax,%eax
f0101496:	74 44                	je     f01014dc <mem_init+0x15e>
		++nfree;
f0101498:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010149c:	8b 00                	mov    (%eax),%eax
f010149e:	eb f4                	jmp    f0101494 <mem_init+0x116>
		totalmem = 1 * 1024 + extmem;
f01014a0:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01014a6:	85 f6                	test   %esi,%esi
f01014a8:	0f 44 c3             	cmove  %ebx,%eax
f01014ab:	e9 0b ff ff ff       	jmp    f01013bb <mem_init+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01014b0:	50                   	push   %eax
f01014b1:	68 08 68 10 f0       	push   $0xf0106808
f01014b6:	68 a6 00 00 00       	push   $0xa6
f01014bb:	68 1d 77 10 f0       	push   $0xf010771d
f01014c0:	e8 7b eb ff ff       	call   f0100040 <_panic>
		panic("'pages' is a null pointer!");
f01014c5:	83 ec 04             	sub    $0x4,%esp
f01014c8:	68 f0 77 10 f0       	push   $0xf01077f0
f01014cd:	68 79 03 00 00       	push   $0x379
f01014d2:	68 1d 77 10 f0       	push   $0xf010771d
f01014d7:	e8 64 eb ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f01014dc:	83 ec 0c             	sub    $0xc,%esp
f01014df:	6a 00                	push   $0x0
f01014e1:	e8 e5 fa ff ff       	call   f0100fcb <page_alloc>
f01014e6:	89 c3                	mov    %eax,%ebx
f01014e8:	83 c4 10             	add    $0x10,%esp
f01014eb:	85 c0                	test   %eax,%eax
f01014ed:	0f 84 11 02 00 00    	je     f0101704 <mem_init+0x386>
	assert((pp1 = page_alloc(0)));
f01014f3:	83 ec 0c             	sub    $0xc,%esp
f01014f6:	6a 00                	push   $0x0
f01014f8:	e8 ce fa ff ff       	call   f0100fcb <page_alloc>
f01014fd:	89 c6                	mov    %eax,%esi
f01014ff:	83 c4 10             	add    $0x10,%esp
f0101502:	85 c0                	test   %eax,%eax
f0101504:	0f 84 13 02 00 00    	je     f010171d <mem_init+0x39f>
	assert((pp2 = page_alloc(0)));
f010150a:	83 ec 0c             	sub    $0xc,%esp
f010150d:	6a 00                	push   $0x0
f010150f:	e8 b7 fa ff ff       	call   f0100fcb <page_alloc>
f0101514:	89 c7                	mov    %eax,%edi
f0101516:	83 c4 10             	add    $0x10,%esp
f0101519:	85 c0                	test   %eax,%eax
f010151b:	0f 84 15 02 00 00    	je     f0101736 <mem_init+0x3b8>
	assert(pp1 && pp1 != pp0);
f0101521:	39 f3                	cmp    %esi,%ebx
f0101523:	0f 84 26 02 00 00    	je     f010174f <mem_init+0x3d1>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101529:	39 c6                	cmp    %eax,%esi
f010152b:	0f 84 37 02 00 00    	je     f0101768 <mem_init+0x3ea>
f0101531:	39 c3                	cmp    %eax,%ebx
f0101533:	0f 84 2f 02 00 00    	je     f0101768 <mem_init+0x3ea>
	return (pp - pages) << PGSHIFT;
f0101539:	8b 0d 90 7e 21 f0    	mov    0xf0217e90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010153f:	8b 15 88 7e 21 f0    	mov    0xf0217e88,%edx
f0101545:	c1 e2 0c             	shl    $0xc,%edx
f0101548:	89 d8                	mov    %ebx,%eax
f010154a:	29 c8                	sub    %ecx,%eax
f010154c:	c1 f8 03             	sar    $0x3,%eax
f010154f:	c1 e0 0c             	shl    $0xc,%eax
f0101552:	39 d0                	cmp    %edx,%eax
f0101554:	0f 83 27 02 00 00    	jae    f0101781 <mem_init+0x403>
f010155a:	89 f0                	mov    %esi,%eax
f010155c:	29 c8                	sub    %ecx,%eax
f010155e:	c1 f8 03             	sar    $0x3,%eax
f0101561:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101564:	39 c2                	cmp    %eax,%edx
f0101566:	0f 86 2e 02 00 00    	jbe    f010179a <mem_init+0x41c>
f010156c:	89 f8                	mov    %edi,%eax
f010156e:	29 c8                	sub    %ecx,%eax
f0101570:	c1 f8 03             	sar    $0x3,%eax
f0101573:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f0101576:	39 c2                	cmp    %eax,%edx
f0101578:	0f 86 35 02 00 00    	jbe    f01017b3 <mem_init+0x435>
	fl = page_free_list;
f010157e:	a1 40 72 21 f0       	mov    0xf0217240,%eax
f0101583:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101586:	c7 05 40 72 21 f0 00 	movl   $0x0,0xf0217240
f010158d:	00 00 00 
	assert(!page_alloc(0));
f0101590:	83 ec 0c             	sub    $0xc,%esp
f0101593:	6a 00                	push   $0x0
f0101595:	e8 31 fa ff ff       	call   f0100fcb <page_alloc>
f010159a:	83 c4 10             	add    $0x10,%esp
f010159d:	85 c0                	test   %eax,%eax
f010159f:	0f 85 27 02 00 00    	jne    f01017cc <mem_init+0x44e>
	page_free(pp0);
f01015a5:	83 ec 0c             	sub    $0xc,%esp
f01015a8:	53                   	push   %ebx
f01015a9:	e8 96 fa ff ff       	call   f0101044 <page_free>
	page_free(pp1);
f01015ae:	89 34 24             	mov    %esi,(%esp)
f01015b1:	e8 8e fa ff ff       	call   f0101044 <page_free>
	page_free(pp2);
f01015b6:	89 3c 24             	mov    %edi,(%esp)
f01015b9:	e8 86 fa ff ff       	call   f0101044 <page_free>
	assert((pp0 = page_alloc(0)));
f01015be:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015c5:	e8 01 fa ff ff       	call   f0100fcb <page_alloc>
f01015ca:	89 c3                	mov    %eax,%ebx
f01015cc:	83 c4 10             	add    $0x10,%esp
f01015cf:	85 c0                	test   %eax,%eax
f01015d1:	0f 84 0e 02 00 00    	je     f01017e5 <mem_init+0x467>
	assert((pp1 = page_alloc(0)));
f01015d7:	83 ec 0c             	sub    $0xc,%esp
f01015da:	6a 00                	push   $0x0
f01015dc:	e8 ea f9 ff ff       	call   f0100fcb <page_alloc>
f01015e1:	89 c6                	mov    %eax,%esi
f01015e3:	83 c4 10             	add    $0x10,%esp
f01015e6:	85 c0                	test   %eax,%eax
f01015e8:	0f 84 10 02 00 00    	je     f01017fe <mem_init+0x480>
	assert((pp2 = page_alloc(0)));
f01015ee:	83 ec 0c             	sub    $0xc,%esp
f01015f1:	6a 00                	push   $0x0
f01015f3:	e8 d3 f9 ff ff       	call   f0100fcb <page_alloc>
f01015f8:	89 c7                	mov    %eax,%edi
f01015fa:	83 c4 10             	add    $0x10,%esp
f01015fd:	85 c0                	test   %eax,%eax
f01015ff:	0f 84 12 02 00 00    	je     f0101817 <mem_init+0x499>
	assert(pp1 && pp1 != pp0);
f0101605:	39 f3                	cmp    %esi,%ebx
f0101607:	0f 84 23 02 00 00    	je     f0101830 <mem_init+0x4b2>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010160d:	39 c3                	cmp    %eax,%ebx
f010160f:	0f 84 34 02 00 00    	je     f0101849 <mem_init+0x4cb>
f0101615:	39 c6                	cmp    %eax,%esi
f0101617:	0f 84 2c 02 00 00    	je     f0101849 <mem_init+0x4cb>
	assert(!page_alloc(0));
f010161d:	83 ec 0c             	sub    $0xc,%esp
f0101620:	6a 00                	push   $0x0
f0101622:	e8 a4 f9 ff ff       	call   f0100fcb <page_alloc>
f0101627:	83 c4 10             	add    $0x10,%esp
f010162a:	85 c0                	test   %eax,%eax
f010162c:	0f 85 30 02 00 00    	jne    f0101862 <mem_init+0x4e4>
f0101632:	89 d8                	mov    %ebx,%eax
f0101634:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f010163a:	c1 f8 03             	sar    $0x3,%eax
f010163d:	89 c2                	mov    %eax,%edx
f010163f:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101642:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101647:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f010164d:	0f 83 28 02 00 00    	jae    f010187b <mem_init+0x4fd>
	memset(page2kva(pp0), 1, PGSIZE);
f0101653:	83 ec 04             	sub    $0x4,%esp
f0101656:	68 00 10 00 00       	push   $0x1000
f010165b:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f010165d:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101663:	52                   	push   %edx
f0101664:	e8 b7 44 00 00       	call   f0105b20 <memset>
	page_free(pp0);
f0101669:	89 1c 24             	mov    %ebx,(%esp)
f010166c:	e8 d3 f9 ff ff       	call   f0101044 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101671:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101678:	e8 4e f9 ff ff       	call   f0100fcb <page_alloc>
f010167d:	83 c4 10             	add    $0x10,%esp
f0101680:	85 c0                	test   %eax,%eax
f0101682:	0f 84 05 02 00 00    	je     f010188d <mem_init+0x50f>
	assert(pp && pp0 == pp);
f0101688:	39 c3                	cmp    %eax,%ebx
f010168a:	0f 85 16 02 00 00    	jne    f01018a6 <mem_init+0x528>
	return (pp - pages) << PGSHIFT;
f0101690:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101696:	c1 f8 03             	sar    $0x3,%eax
f0101699:	89 c2                	mov    %eax,%edx
f010169b:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010169e:	25 ff ff 0f 00       	and    $0xfffff,%eax
f01016a3:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f01016a9:	0f 83 10 02 00 00    	jae    f01018bf <mem_init+0x541>
	return (void *)(pa + KERNBASE);
f01016af:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f01016b5:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f01016bb:	80 38 00             	cmpb   $0x0,(%eax)
f01016be:	0f 85 0d 02 00 00    	jne    f01018d1 <mem_init+0x553>
f01016c4:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01016c7:	39 d0                	cmp    %edx,%eax
f01016c9:	75 f0                	jne    f01016bb <mem_init+0x33d>
	page_free_list = fl;
f01016cb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01016ce:	a3 40 72 21 f0       	mov    %eax,0xf0217240
	page_free(pp0);
f01016d3:	83 ec 0c             	sub    $0xc,%esp
f01016d6:	53                   	push   %ebx
f01016d7:	e8 68 f9 ff ff       	call   f0101044 <page_free>
	page_free(pp1);
f01016dc:	89 34 24             	mov    %esi,(%esp)
f01016df:	e8 60 f9 ff ff       	call   f0101044 <page_free>
	page_free(pp2);
f01016e4:	89 3c 24             	mov    %edi,(%esp)
f01016e7:	e8 58 f9 ff ff       	call   f0101044 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016ec:	a1 40 72 21 f0       	mov    0xf0217240,%eax
f01016f1:	83 c4 10             	add    $0x10,%esp
f01016f4:	85 c0                	test   %eax,%eax
f01016f6:	0f 84 ee 01 00 00    	je     f01018ea <mem_init+0x56c>
		--nfree;
f01016fc:	83 6d d4 01          	subl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101700:	8b 00                	mov    (%eax),%eax
f0101702:	eb f0                	jmp    f01016f4 <mem_init+0x376>
	assert((pp0 = page_alloc(0)));
f0101704:	68 0b 78 10 f0       	push   $0xf010780b
f0101709:	68 43 77 10 f0       	push   $0xf0107743
f010170e:	68 81 03 00 00       	push   $0x381
f0101713:	68 1d 77 10 f0       	push   $0xf010771d
f0101718:	e8 23 e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010171d:	68 21 78 10 f0       	push   $0xf0107821
f0101722:	68 43 77 10 f0       	push   $0xf0107743
f0101727:	68 82 03 00 00       	push   $0x382
f010172c:	68 1d 77 10 f0       	push   $0xf010771d
f0101731:	e8 0a e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101736:	68 37 78 10 f0       	push   $0xf0107837
f010173b:	68 43 77 10 f0       	push   $0xf0107743
f0101740:	68 83 03 00 00       	push   $0x383
f0101745:	68 1d 77 10 f0       	push   $0xf010771d
f010174a:	e8 f1 e8 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f010174f:	68 4d 78 10 f0       	push   $0xf010784d
f0101754:	68 43 77 10 f0       	push   $0xf0107743
f0101759:	68 86 03 00 00       	push   $0x386
f010175e:	68 1d 77 10 f0       	push   $0xf010771d
f0101763:	e8 d8 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101768:	68 40 6f 10 f0       	push   $0xf0106f40
f010176d:	68 43 77 10 f0       	push   $0xf0107743
f0101772:	68 87 03 00 00       	push   $0x387
f0101777:	68 1d 77 10 f0       	push   $0xf010771d
f010177c:	e8 bf e8 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101781:	68 5f 78 10 f0       	push   $0xf010785f
f0101786:	68 43 77 10 f0       	push   $0xf0107743
f010178b:	68 88 03 00 00       	push   $0x388
f0101790:	68 1d 77 10 f0       	push   $0xf010771d
f0101795:	e8 a6 e8 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010179a:	68 7c 78 10 f0       	push   $0xf010787c
f010179f:	68 43 77 10 f0       	push   $0xf0107743
f01017a4:	68 89 03 00 00       	push   $0x389
f01017a9:	68 1d 77 10 f0       	push   $0xf010771d
f01017ae:	e8 8d e8 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01017b3:	68 99 78 10 f0       	push   $0xf0107899
f01017b8:	68 43 77 10 f0       	push   $0xf0107743
f01017bd:	68 8a 03 00 00       	push   $0x38a
f01017c2:	68 1d 77 10 f0       	push   $0xf010771d
f01017c7:	e8 74 e8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01017cc:	68 b6 78 10 f0       	push   $0xf01078b6
f01017d1:	68 43 77 10 f0       	push   $0xf0107743
f01017d6:	68 91 03 00 00       	push   $0x391
f01017db:	68 1d 77 10 f0       	push   $0xf010771d
f01017e0:	e8 5b e8 ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f01017e5:	68 0b 78 10 f0       	push   $0xf010780b
f01017ea:	68 43 77 10 f0       	push   $0xf0107743
f01017ef:	68 98 03 00 00       	push   $0x398
f01017f4:	68 1d 77 10 f0       	push   $0xf010771d
f01017f9:	e8 42 e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01017fe:	68 21 78 10 f0       	push   $0xf0107821
f0101803:	68 43 77 10 f0       	push   $0xf0107743
f0101808:	68 99 03 00 00       	push   $0x399
f010180d:	68 1d 77 10 f0       	push   $0xf010771d
f0101812:	e8 29 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101817:	68 37 78 10 f0       	push   $0xf0107837
f010181c:	68 43 77 10 f0       	push   $0xf0107743
f0101821:	68 9a 03 00 00       	push   $0x39a
f0101826:	68 1d 77 10 f0       	push   $0xf010771d
f010182b:	e8 10 e8 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f0101830:	68 4d 78 10 f0       	push   $0xf010784d
f0101835:	68 43 77 10 f0       	push   $0xf0107743
f010183a:	68 9c 03 00 00       	push   $0x39c
f010183f:	68 1d 77 10 f0       	push   $0xf010771d
f0101844:	e8 f7 e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101849:	68 40 6f 10 f0       	push   $0xf0106f40
f010184e:	68 43 77 10 f0       	push   $0xf0107743
f0101853:	68 9d 03 00 00       	push   $0x39d
f0101858:	68 1d 77 10 f0       	push   $0xf010771d
f010185d:	e8 de e7 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101862:	68 b6 78 10 f0       	push   $0xf01078b6
f0101867:	68 43 77 10 f0       	push   $0xf0107743
f010186c:	68 9e 03 00 00       	push   $0x39e
f0101871:	68 1d 77 10 f0       	push   $0xf010771d
f0101876:	e8 c5 e7 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010187b:	52                   	push   %edx
f010187c:	68 e4 67 10 f0       	push   $0xf01067e4
f0101881:	6a 58                	push   $0x58
f0101883:	68 29 77 10 f0       	push   $0xf0107729
f0101888:	e8 b3 e7 ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010188d:	68 c5 78 10 f0       	push   $0xf01078c5
f0101892:	68 43 77 10 f0       	push   $0xf0107743
f0101897:	68 a3 03 00 00       	push   $0x3a3
f010189c:	68 1d 77 10 f0       	push   $0xf010771d
f01018a1:	e8 9a e7 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f01018a6:	68 e3 78 10 f0       	push   $0xf01078e3
f01018ab:	68 43 77 10 f0       	push   $0xf0107743
f01018b0:	68 a4 03 00 00       	push   $0x3a4
f01018b5:	68 1d 77 10 f0       	push   $0xf010771d
f01018ba:	e8 81 e7 ff ff       	call   f0100040 <_panic>
f01018bf:	52                   	push   %edx
f01018c0:	68 e4 67 10 f0       	push   $0xf01067e4
f01018c5:	6a 58                	push   $0x58
f01018c7:	68 29 77 10 f0       	push   $0xf0107729
f01018cc:	e8 6f e7 ff ff       	call   f0100040 <_panic>
		assert(c[i] == 0);
f01018d1:	68 f3 78 10 f0       	push   $0xf01078f3
f01018d6:	68 43 77 10 f0       	push   $0xf0107743
f01018db:	68 a7 03 00 00       	push   $0x3a7
f01018e0:	68 1d 77 10 f0       	push   $0xf010771d
f01018e5:	e8 56 e7 ff ff       	call   f0100040 <_panic>
	assert(nfree == 0);
f01018ea:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01018ee:	0f 85 46 09 00 00    	jne    f010223a <mem_init+0xebc>
	cprintf("check_page_alloc() succeeded!\n");
f01018f4:	83 ec 0c             	sub    $0xc,%esp
f01018f7:	68 60 6f 10 f0       	push   $0xf0106f60
f01018fc:	e8 b9 20 00 00       	call   f01039ba <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101901:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101908:	e8 be f6 ff ff       	call   f0100fcb <page_alloc>
f010190d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101910:	83 c4 10             	add    $0x10,%esp
f0101913:	85 c0                	test   %eax,%eax
f0101915:	0f 84 38 09 00 00    	je     f0102253 <mem_init+0xed5>
	assert((pp1 = page_alloc(0)));
f010191b:	83 ec 0c             	sub    $0xc,%esp
f010191e:	6a 00                	push   $0x0
f0101920:	e8 a6 f6 ff ff       	call   f0100fcb <page_alloc>
f0101925:	89 c7                	mov    %eax,%edi
f0101927:	83 c4 10             	add    $0x10,%esp
f010192a:	85 c0                	test   %eax,%eax
f010192c:	0f 84 3a 09 00 00    	je     f010226c <mem_init+0xeee>
	assert((pp2 = page_alloc(0)));
f0101932:	83 ec 0c             	sub    $0xc,%esp
f0101935:	6a 00                	push   $0x0
f0101937:	e8 8f f6 ff ff       	call   f0100fcb <page_alloc>
f010193c:	89 c3                	mov    %eax,%ebx
f010193e:	83 c4 10             	add    $0x10,%esp
f0101941:	85 c0                	test   %eax,%eax
f0101943:	0f 84 3c 09 00 00    	je     f0102285 <mem_init+0xf07>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101949:	39 7d d4             	cmp    %edi,-0x2c(%ebp)
f010194c:	0f 84 4c 09 00 00    	je     f010229e <mem_init+0xf20>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101952:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101955:	0f 84 5c 09 00 00    	je     f01022b7 <mem_init+0xf39>
f010195b:	39 c7                	cmp    %eax,%edi
f010195d:	0f 84 54 09 00 00    	je     f01022b7 <mem_init+0xf39>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101963:	a1 40 72 21 f0       	mov    0xf0217240,%eax
f0101968:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f010196b:	c7 05 40 72 21 f0 00 	movl   $0x0,0xf0217240
f0101972:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101975:	83 ec 0c             	sub    $0xc,%esp
f0101978:	6a 00                	push   $0x0
f010197a:	e8 4c f6 ff ff       	call   f0100fcb <page_alloc>
f010197f:	83 c4 10             	add    $0x10,%esp
f0101982:	85 c0                	test   %eax,%eax
f0101984:	0f 85 46 09 00 00    	jne    f01022d0 <mem_init+0xf52>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010198a:	83 ec 04             	sub    $0x4,%esp
f010198d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101990:	50                   	push   %eax
f0101991:	6a 00                	push   $0x0
f0101993:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101999:	e8 ef f7 ff ff       	call   f010118d <page_lookup>
f010199e:	83 c4 10             	add    $0x10,%esp
f01019a1:	85 c0                	test   %eax,%eax
f01019a3:	0f 85 40 09 00 00    	jne    f01022e9 <mem_init+0xf6b>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019a9:	6a 02                	push   $0x2
f01019ab:	6a 00                	push   $0x0
f01019ad:	57                   	push   %edi
f01019ae:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f01019b4:	e8 c7 f8 ff ff       	call   f0101280 <page_insert>
f01019b9:	83 c4 10             	add    $0x10,%esp
f01019bc:	85 c0                	test   %eax,%eax
f01019be:	0f 89 3e 09 00 00    	jns    f0102302 <mem_init+0xf84>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019c4:	83 ec 0c             	sub    $0xc,%esp
f01019c7:	ff 75 d4             	pushl  -0x2c(%ebp)
f01019ca:	e8 75 f6 ff ff       	call   f0101044 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019cf:	6a 02                	push   $0x2
f01019d1:	6a 00                	push   $0x0
f01019d3:	57                   	push   %edi
f01019d4:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f01019da:	e8 a1 f8 ff ff       	call   f0101280 <page_insert>
f01019df:	83 c4 20             	add    $0x20,%esp
f01019e2:	85 c0                	test   %eax,%eax
f01019e4:	0f 85 31 09 00 00    	jne    f010231b <mem_init+0xf9d>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01019ea:	8b 35 8c 7e 21 f0    	mov    0xf0217e8c,%esi
	return (pp - pages) << PGSHIFT;
f01019f0:	8b 0d 90 7e 21 f0    	mov    0xf0217e90,%ecx
f01019f6:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01019f9:	8b 16                	mov    (%esi),%edx
f01019fb:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a01:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a04:	29 c8                	sub    %ecx,%eax
f0101a06:	c1 f8 03             	sar    $0x3,%eax
f0101a09:	c1 e0 0c             	shl    $0xc,%eax
f0101a0c:	39 c2                	cmp    %eax,%edx
f0101a0e:	0f 85 20 09 00 00    	jne    f0102334 <mem_init+0xfb6>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a14:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a19:	89 f0                	mov    %esi,%eax
f0101a1b:	e8 6f f1 ff ff       	call   f0100b8f <check_va2pa>
f0101a20:	89 c2                	mov    %eax,%edx
f0101a22:	89 f8                	mov    %edi,%eax
f0101a24:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101a27:	c1 f8 03             	sar    $0x3,%eax
f0101a2a:	c1 e0 0c             	shl    $0xc,%eax
f0101a2d:	39 c2                	cmp    %eax,%edx
f0101a2f:	0f 85 18 09 00 00    	jne    f010234d <mem_init+0xfcf>
	assert(pp1->pp_ref == 1);
f0101a35:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101a3a:	0f 85 26 09 00 00    	jne    f0102366 <mem_init+0xfe8>
	assert(pp0->pp_ref == 1);
f0101a40:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a43:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a48:	0f 85 31 09 00 00    	jne    f010237f <mem_init+0x1001>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a4e:	6a 02                	push   $0x2
f0101a50:	68 00 10 00 00       	push   $0x1000
f0101a55:	53                   	push   %ebx
f0101a56:	56                   	push   %esi
f0101a57:	e8 24 f8 ff ff       	call   f0101280 <page_insert>
f0101a5c:	83 c4 10             	add    $0x10,%esp
f0101a5f:	85 c0                	test   %eax,%eax
f0101a61:	0f 85 31 09 00 00    	jne    f0102398 <mem_init+0x101a>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a67:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a6c:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0101a71:	e8 19 f1 ff ff       	call   f0100b8f <check_va2pa>
f0101a76:	89 c2                	mov    %eax,%edx
f0101a78:	89 d8                	mov    %ebx,%eax
f0101a7a:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101a80:	c1 f8 03             	sar    $0x3,%eax
f0101a83:	c1 e0 0c             	shl    $0xc,%eax
f0101a86:	39 c2                	cmp    %eax,%edx
f0101a88:	0f 85 23 09 00 00    	jne    f01023b1 <mem_init+0x1033>
	assert(pp2->pp_ref == 1);
f0101a8e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a93:	0f 85 31 09 00 00    	jne    f01023ca <mem_init+0x104c>

	// should be no free memory
	assert(!page_alloc(0));
f0101a99:	83 ec 0c             	sub    $0xc,%esp
f0101a9c:	6a 00                	push   $0x0
f0101a9e:	e8 28 f5 ff ff       	call   f0100fcb <page_alloc>
f0101aa3:	83 c4 10             	add    $0x10,%esp
f0101aa6:	85 c0                	test   %eax,%eax
f0101aa8:	0f 85 35 09 00 00    	jne    f01023e3 <mem_init+0x1065>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101aae:	6a 02                	push   $0x2
f0101ab0:	68 00 10 00 00       	push   $0x1000
f0101ab5:	53                   	push   %ebx
f0101ab6:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101abc:	e8 bf f7 ff ff       	call   f0101280 <page_insert>
f0101ac1:	83 c4 10             	add    $0x10,%esp
f0101ac4:	85 c0                	test   %eax,%eax
f0101ac6:	0f 85 30 09 00 00    	jne    f01023fc <mem_init+0x107e>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101acc:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ad1:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0101ad6:	e8 b4 f0 ff ff       	call   f0100b8f <check_va2pa>
f0101adb:	89 c2                	mov    %eax,%edx
f0101add:	89 d8                	mov    %ebx,%eax
f0101adf:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101ae5:	c1 f8 03             	sar    $0x3,%eax
f0101ae8:	c1 e0 0c             	shl    $0xc,%eax
f0101aeb:	39 c2                	cmp    %eax,%edx
f0101aed:	0f 85 22 09 00 00    	jne    f0102415 <mem_init+0x1097>
	assert(pp2->pp_ref == 1);
f0101af3:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101af8:	0f 85 30 09 00 00    	jne    f010242e <mem_init+0x10b0>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101afe:	83 ec 0c             	sub    $0xc,%esp
f0101b01:	6a 00                	push   $0x0
f0101b03:	e8 c3 f4 ff ff       	call   f0100fcb <page_alloc>
f0101b08:	83 c4 10             	add    $0x10,%esp
f0101b0b:	85 c0                	test   %eax,%eax
f0101b0d:	0f 85 34 09 00 00    	jne    f0102447 <mem_init+0x10c9>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101b13:	8b 0d 8c 7e 21 f0    	mov    0xf0217e8c,%ecx
f0101b19:	8b 01                	mov    (%ecx),%eax
f0101b1b:	89 c2                	mov    %eax,%edx
f0101b1d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101b23:	c1 e8 0c             	shr    $0xc,%eax
f0101b26:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0101b2c:	0f 83 2e 09 00 00    	jae    f0102460 <mem_init+0x10e2>
	return (void *)(pa + KERNBASE);
f0101b32:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101b38:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101b3b:	83 ec 04             	sub    $0x4,%esp
f0101b3e:	6a 00                	push   $0x0
f0101b40:	68 00 10 00 00       	push   $0x1000
f0101b45:	51                   	push   %ecx
f0101b46:	e8 65 f5 ff ff       	call   f01010b0 <pgdir_walk>
f0101b4b:	89 c2                	mov    %eax,%edx
f0101b4d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101b50:	83 c0 04             	add    $0x4,%eax
f0101b53:	83 c4 10             	add    $0x10,%esp
f0101b56:	39 d0                	cmp    %edx,%eax
f0101b58:	0f 85 17 09 00 00    	jne    f0102475 <mem_init+0x10f7>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101b5e:	6a 06                	push   $0x6
f0101b60:	68 00 10 00 00       	push   $0x1000
f0101b65:	53                   	push   %ebx
f0101b66:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101b6c:	e8 0f f7 ff ff       	call   f0101280 <page_insert>
f0101b71:	83 c4 10             	add    $0x10,%esp
f0101b74:	85 c0                	test   %eax,%eax
f0101b76:	0f 85 12 09 00 00    	jne    f010248e <mem_init+0x1110>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b7c:	8b 35 8c 7e 21 f0    	mov    0xf0217e8c,%esi
f0101b82:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b87:	89 f0                	mov    %esi,%eax
f0101b89:	e8 01 f0 ff ff       	call   f0100b8f <check_va2pa>
f0101b8e:	89 c2                	mov    %eax,%edx
	return (pp - pages) << PGSHIFT;
f0101b90:	89 d8                	mov    %ebx,%eax
f0101b92:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101b98:	c1 f8 03             	sar    $0x3,%eax
f0101b9b:	c1 e0 0c             	shl    $0xc,%eax
f0101b9e:	39 c2                	cmp    %eax,%edx
f0101ba0:	0f 85 01 09 00 00    	jne    f01024a7 <mem_init+0x1129>
	assert(pp2->pp_ref == 1);
f0101ba6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101bab:	0f 85 0f 09 00 00    	jne    f01024c0 <mem_init+0x1142>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101bb1:	83 ec 04             	sub    $0x4,%esp
f0101bb4:	6a 00                	push   $0x0
f0101bb6:	68 00 10 00 00       	push   $0x1000
f0101bbb:	56                   	push   %esi
f0101bbc:	e8 ef f4 ff ff       	call   f01010b0 <pgdir_walk>
f0101bc1:	83 c4 10             	add    $0x10,%esp
f0101bc4:	f6 00 04             	testb  $0x4,(%eax)
f0101bc7:	0f 84 0c 09 00 00    	je     f01024d9 <mem_init+0x115b>
	assert(kern_pgdir[0] & PTE_U);
f0101bcd:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0101bd2:	f6 00 04             	testb  $0x4,(%eax)
f0101bd5:	0f 84 17 09 00 00    	je     f01024f2 <mem_init+0x1174>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bdb:	6a 02                	push   $0x2
f0101bdd:	68 00 10 00 00       	push   $0x1000
f0101be2:	53                   	push   %ebx
f0101be3:	50                   	push   %eax
f0101be4:	e8 97 f6 ff ff       	call   f0101280 <page_insert>
f0101be9:	83 c4 10             	add    $0x10,%esp
f0101bec:	85 c0                	test   %eax,%eax
f0101bee:	0f 85 17 09 00 00    	jne    f010250b <mem_init+0x118d>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101bf4:	83 ec 04             	sub    $0x4,%esp
f0101bf7:	6a 00                	push   $0x0
f0101bf9:	68 00 10 00 00       	push   $0x1000
f0101bfe:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101c04:	e8 a7 f4 ff ff       	call   f01010b0 <pgdir_walk>
f0101c09:	83 c4 10             	add    $0x10,%esp
f0101c0c:	f6 00 02             	testb  $0x2,(%eax)
f0101c0f:	0f 84 0f 09 00 00    	je     f0102524 <mem_init+0x11a6>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c15:	83 ec 04             	sub    $0x4,%esp
f0101c18:	6a 00                	push   $0x0
f0101c1a:	68 00 10 00 00       	push   $0x1000
f0101c1f:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101c25:	e8 86 f4 ff ff       	call   f01010b0 <pgdir_walk>
f0101c2a:	83 c4 10             	add    $0x10,%esp
f0101c2d:	f6 00 04             	testb  $0x4,(%eax)
f0101c30:	0f 85 07 09 00 00    	jne    f010253d <mem_init+0x11bf>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101c36:	6a 02                	push   $0x2
f0101c38:	68 00 00 40 00       	push   $0x400000
f0101c3d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c40:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101c46:	e8 35 f6 ff ff       	call   f0101280 <page_insert>
f0101c4b:	83 c4 10             	add    $0x10,%esp
f0101c4e:	85 c0                	test   %eax,%eax
f0101c50:	0f 89 00 09 00 00    	jns    f0102556 <mem_init+0x11d8>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c56:	6a 02                	push   $0x2
f0101c58:	68 00 10 00 00       	push   $0x1000
f0101c5d:	57                   	push   %edi
f0101c5e:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101c64:	e8 17 f6 ff ff       	call   f0101280 <page_insert>
f0101c69:	83 c4 10             	add    $0x10,%esp
f0101c6c:	85 c0                	test   %eax,%eax
f0101c6e:	0f 85 fb 08 00 00    	jne    f010256f <mem_init+0x11f1>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c74:	83 ec 04             	sub    $0x4,%esp
f0101c77:	6a 00                	push   $0x0
f0101c79:	68 00 10 00 00       	push   $0x1000
f0101c7e:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101c84:	e8 27 f4 ff ff       	call   f01010b0 <pgdir_walk>
f0101c89:	83 c4 10             	add    $0x10,%esp
f0101c8c:	f6 00 04             	testb  $0x4,(%eax)
f0101c8f:	0f 85 f3 08 00 00    	jne    f0102588 <mem_init+0x120a>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c95:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0101c9a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101c9d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ca2:	e8 e8 ee ff ff       	call   f0100b8f <check_va2pa>
f0101ca7:	89 fe                	mov    %edi,%esi
f0101ca9:	2b 35 90 7e 21 f0    	sub    0xf0217e90,%esi
f0101caf:	c1 fe 03             	sar    $0x3,%esi
f0101cb2:	c1 e6 0c             	shl    $0xc,%esi
f0101cb5:	39 f0                	cmp    %esi,%eax
f0101cb7:	0f 85 e4 08 00 00    	jne    f01025a1 <mem_init+0x1223>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cbd:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cc2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101cc5:	e8 c5 ee ff ff       	call   f0100b8f <check_va2pa>
f0101cca:	39 c6                	cmp    %eax,%esi
f0101ccc:	0f 85 e8 08 00 00    	jne    f01025ba <mem_init+0x123c>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101cd2:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101cd7:	0f 85 f6 08 00 00    	jne    f01025d3 <mem_init+0x1255>
	assert(pp2->pp_ref == 0);
f0101cdd:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ce2:	0f 85 04 09 00 00    	jne    f01025ec <mem_init+0x126e>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101ce8:	83 ec 0c             	sub    $0xc,%esp
f0101ceb:	6a 00                	push   $0x0
f0101ced:	e8 d9 f2 ff ff       	call   f0100fcb <page_alloc>
f0101cf2:	83 c4 10             	add    $0x10,%esp
f0101cf5:	85 c0                	test   %eax,%eax
f0101cf7:	0f 84 08 09 00 00    	je     f0102605 <mem_init+0x1287>
f0101cfd:	39 c3                	cmp    %eax,%ebx
f0101cff:	0f 85 00 09 00 00    	jne    f0102605 <mem_init+0x1287>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d05:	83 ec 08             	sub    $0x8,%esp
f0101d08:	6a 00                	push   $0x0
f0101d0a:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101d10:	e8 1a f5 ff ff       	call   f010122f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d15:	8b 35 8c 7e 21 f0    	mov    0xf0217e8c,%esi
f0101d1b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d20:	89 f0                	mov    %esi,%eax
f0101d22:	e8 68 ee ff ff       	call   f0100b8f <check_va2pa>
f0101d27:	83 c4 10             	add    $0x10,%esp
f0101d2a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d2d:	0f 85 eb 08 00 00    	jne    f010261e <mem_init+0x12a0>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d33:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d38:	89 f0                	mov    %esi,%eax
f0101d3a:	e8 50 ee ff ff       	call   f0100b8f <check_va2pa>
f0101d3f:	89 c2                	mov    %eax,%edx
f0101d41:	89 f8                	mov    %edi,%eax
f0101d43:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101d49:	c1 f8 03             	sar    $0x3,%eax
f0101d4c:	c1 e0 0c             	shl    $0xc,%eax
f0101d4f:	39 c2                	cmp    %eax,%edx
f0101d51:	0f 85 e0 08 00 00    	jne    f0102637 <mem_init+0x12b9>
	assert(pp1->pp_ref == 1);
f0101d57:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101d5c:	0f 85 ee 08 00 00    	jne    f0102650 <mem_init+0x12d2>
	assert(pp2->pp_ref == 0);
f0101d62:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d67:	0f 85 fc 08 00 00    	jne    f0102669 <mem_init+0x12eb>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d6d:	6a 00                	push   $0x0
f0101d6f:	68 00 10 00 00       	push   $0x1000
f0101d74:	57                   	push   %edi
f0101d75:	56                   	push   %esi
f0101d76:	e8 05 f5 ff ff       	call   f0101280 <page_insert>
f0101d7b:	83 c4 10             	add    $0x10,%esp
f0101d7e:	85 c0                	test   %eax,%eax
f0101d80:	0f 85 fc 08 00 00    	jne    f0102682 <mem_init+0x1304>
	assert(pp1->pp_ref);
f0101d86:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101d8b:	0f 84 0a 09 00 00    	je     f010269b <mem_init+0x131d>
	assert(pp1->pp_link == NULL);
f0101d91:	83 3f 00             	cmpl   $0x0,(%edi)
f0101d94:	0f 85 1a 09 00 00    	jne    f01026b4 <mem_init+0x1336>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101d9a:	83 ec 08             	sub    $0x8,%esp
f0101d9d:	68 00 10 00 00       	push   $0x1000
f0101da2:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101da8:	e8 82 f4 ff ff       	call   f010122f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101dad:	8b 35 8c 7e 21 f0    	mov    0xf0217e8c,%esi
f0101db3:	ba 00 00 00 00       	mov    $0x0,%edx
f0101db8:	89 f0                	mov    %esi,%eax
f0101dba:	e8 d0 ed ff ff       	call   f0100b8f <check_va2pa>
f0101dbf:	83 c4 10             	add    $0x10,%esp
f0101dc2:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dc5:	0f 85 02 09 00 00    	jne    f01026cd <mem_init+0x134f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101dcb:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dd0:	89 f0                	mov    %esi,%eax
f0101dd2:	e8 b8 ed ff ff       	call   f0100b8f <check_va2pa>
f0101dd7:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dda:	0f 85 06 09 00 00    	jne    f01026e6 <mem_init+0x1368>
	assert(pp1->pp_ref == 0);
f0101de0:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101de5:	0f 85 14 09 00 00    	jne    f01026ff <mem_init+0x1381>
	assert(pp2->pp_ref == 0);
f0101deb:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101df0:	0f 85 22 09 00 00    	jne    f0102718 <mem_init+0x139a>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101df6:	83 ec 0c             	sub    $0xc,%esp
f0101df9:	6a 00                	push   $0x0
f0101dfb:	e8 cb f1 ff ff       	call   f0100fcb <page_alloc>
f0101e00:	83 c4 10             	add    $0x10,%esp
f0101e03:	39 c7                	cmp    %eax,%edi
f0101e05:	0f 85 26 09 00 00    	jne    f0102731 <mem_init+0x13b3>
f0101e0b:	85 c0                	test   %eax,%eax
f0101e0d:	0f 84 1e 09 00 00    	je     f0102731 <mem_init+0x13b3>

	// should be no free memory
	assert(!page_alloc(0));
f0101e13:	83 ec 0c             	sub    $0xc,%esp
f0101e16:	6a 00                	push   $0x0
f0101e18:	e8 ae f1 ff ff       	call   f0100fcb <page_alloc>
f0101e1d:	83 c4 10             	add    $0x10,%esp
f0101e20:	85 c0                	test   %eax,%eax
f0101e22:	0f 85 22 09 00 00    	jne    f010274a <mem_init+0x13cc>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e28:	8b 0d 8c 7e 21 f0    	mov    0xf0217e8c,%ecx
f0101e2e:	8b 11                	mov    (%ecx),%edx
f0101e30:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e36:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e39:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101e3f:	c1 f8 03             	sar    $0x3,%eax
f0101e42:	c1 e0 0c             	shl    $0xc,%eax
f0101e45:	39 c2                	cmp    %eax,%edx
f0101e47:	0f 85 16 09 00 00    	jne    f0102763 <mem_init+0x13e5>
	kern_pgdir[0] = 0;
f0101e4d:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101e53:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e56:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e5b:	0f 85 1b 09 00 00    	jne    f010277c <mem_init+0x13fe>
	pp0->pp_ref = 0;
f0101e61:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e64:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101e6a:	83 ec 0c             	sub    $0xc,%esp
f0101e6d:	50                   	push   %eax
f0101e6e:	e8 d1 f1 ff ff       	call   f0101044 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101e73:	83 c4 0c             	add    $0xc,%esp
f0101e76:	6a 01                	push   $0x1
f0101e78:	68 00 10 40 00       	push   $0x401000
f0101e7d:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101e83:	e8 28 f2 ff ff       	call   f01010b0 <pgdir_walk>
f0101e88:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101e8b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101e8e:	8b 0d 8c 7e 21 f0    	mov    0xf0217e8c,%ecx
f0101e94:	8b 41 04             	mov    0x4(%ecx),%eax
f0101e97:	89 c6                	mov    %eax,%esi
f0101e99:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	if (PGNUM(pa) >= npages)
f0101e9f:	8b 15 88 7e 21 f0    	mov    0xf0217e88,%edx
f0101ea5:	c1 e8 0c             	shr    $0xc,%eax
f0101ea8:	83 c4 10             	add    $0x10,%esp
f0101eab:	39 d0                	cmp    %edx,%eax
f0101ead:	0f 83 e2 08 00 00    	jae    f0102795 <mem_init+0x1417>
	assert(ptep == ptep1 + PTX(va));
f0101eb3:	81 ee fc ff ff 0f    	sub    $0xffffffc,%esi
f0101eb9:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f0101ebc:	0f 85 e8 08 00 00    	jne    f01027aa <mem_init+0x142c>
	kern_pgdir[PDX(va)] = 0;
f0101ec2:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0101ec9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ecc:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0101ed2:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101ed8:	c1 f8 03             	sar    $0x3,%eax
f0101edb:	89 c1                	mov    %eax,%ecx
f0101edd:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f0101ee0:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101ee5:	39 c2                	cmp    %eax,%edx
f0101ee7:	0f 86 d6 08 00 00    	jbe    f01027c3 <mem_init+0x1445>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101eed:	83 ec 04             	sub    $0x4,%esp
f0101ef0:	68 00 10 00 00       	push   $0x1000
f0101ef5:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0101efa:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0101f00:	51                   	push   %ecx
f0101f01:	e8 1a 3c 00 00       	call   f0105b20 <memset>
	page_free(pp0);
f0101f06:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101f09:	89 34 24             	mov    %esi,(%esp)
f0101f0c:	e8 33 f1 ff ff       	call   f0101044 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101f11:	83 c4 0c             	add    $0xc,%esp
f0101f14:	6a 01                	push   $0x1
f0101f16:	6a 00                	push   $0x0
f0101f18:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101f1e:	e8 8d f1 ff ff       	call   f01010b0 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0101f23:	89 f0                	mov    %esi,%eax
f0101f25:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101f2b:	c1 f8 03             	sar    $0x3,%eax
f0101f2e:	89 c2                	mov    %eax,%edx
f0101f30:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101f33:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101f38:	83 c4 10             	add    $0x10,%esp
f0101f3b:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0101f41:	0f 83 8e 08 00 00    	jae    f01027d5 <mem_init+0x1457>
	return (void *)(pa + KERNBASE);
f0101f47:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101f4d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101f50:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101f56:	f6 00 01             	testb  $0x1,(%eax)
f0101f59:	0f 85 88 08 00 00    	jne    f01027e7 <mem_init+0x1469>
f0101f5f:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0101f62:	39 d0                	cmp    %edx,%eax
f0101f64:	75 f0                	jne    f0101f56 <mem_init+0xbd8>
	kern_pgdir[0] = 0;
f0101f66:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0101f6b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101f71:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f74:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0101f7a:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101f7d:	89 0d 40 72 21 f0    	mov    %ecx,0xf0217240

	// free the pages we took
	page_free(pp0);
f0101f83:	83 ec 0c             	sub    $0xc,%esp
f0101f86:	50                   	push   %eax
f0101f87:	e8 b8 f0 ff ff       	call   f0101044 <page_free>
	page_free(pp1);
f0101f8c:	89 3c 24             	mov    %edi,(%esp)
f0101f8f:	e8 b0 f0 ff ff       	call   f0101044 <page_free>
	page_free(pp2);
f0101f94:	89 1c 24             	mov    %ebx,(%esp)
f0101f97:	e8 a8 f0 ff ff       	call   f0101044 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0101f9c:	83 c4 08             	add    $0x8,%esp
f0101f9f:	68 01 10 00 00       	push   $0x1001
f0101fa4:	6a 00                	push   $0x0
f0101fa6:	e8 57 f3 ff ff       	call   f0101302 <mmio_map_region>
f0101fab:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0101fad:	83 c4 08             	add    $0x8,%esp
f0101fb0:	68 00 10 00 00       	push   $0x1000
f0101fb5:	6a 00                	push   $0x0
f0101fb7:	e8 46 f3 ff ff       	call   f0101302 <mmio_map_region>
f0101fbc:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8192 < MMIOLIM);
f0101fbe:	8d 83 00 20 00 00    	lea    0x2000(%ebx),%eax
f0101fc4:	83 c4 10             	add    $0x10,%esp
f0101fc7:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0101fcd:	0f 86 2d 08 00 00    	jbe    f0102800 <mem_init+0x1482>
f0101fd3:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0101fd8:	0f 87 22 08 00 00    	ja     f0102800 <mem_init+0x1482>
	assert(mm2 >= MMIOBASE && mm2 + 8192 < MMIOLIM);
f0101fde:	8d 96 00 20 00 00    	lea    0x2000(%esi),%edx
f0101fe4:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0101fea:	0f 87 29 08 00 00    	ja     f0102819 <mem_init+0x149b>
f0101ff0:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0101ff6:	0f 86 1d 08 00 00    	jbe    f0102819 <mem_init+0x149b>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0101ffc:	89 da                	mov    %ebx,%edx
f0101ffe:	09 f2                	or     %esi,%edx
f0102000:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102006:	0f 85 26 08 00 00    	jne    f0102832 <mem_init+0x14b4>
	// check that they don't overlap
	assert(mm1 + 8192 <= mm2);
f010200c:	39 c6                	cmp    %eax,%esi
f010200e:	0f 82 37 08 00 00    	jb     f010284b <mem_init+0x14cd>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102014:	8b 3d 8c 7e 21 f0    	mov    0xf0217e8c,%edi
f010201a:	89 da                	mov    %ebx,%edx
f010201c:	89 f8                	mov    %edi,%eax
f010201e:	e8 6c eb ff ff       	call   f0100b8f <check_va2pa>
f0102023:	85 c0                	test   %eax,%eax
f0102025:	0f 85 39 08 00 00    	jne    f0102864 <mem_init+0x14e6>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f010202b:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102031:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102034:	89 c2                	mov    %eax,%edx
f0102036:	89 f8                	mov    %edi,%eax
f0102038:	e8 52 eb ff ff       	call   f0100b8f <check_va2pa>
f010203d:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102042:	0f 85 35 08 00 00    	jne    f010287d <mem_init+0x14ff>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102048:	89 f2                	mov    %esi,%edx
f010204a:	89 f8                	mov    %edi,%eax
f010204c:	e8 3e eb ff ff       	call   f0100b8f <check_va2pa>
f0102051:	85 c0                	test   %eax,%eax
f0102053:	0f 85 3d 08 00 00    	jne    f0102896 <mem_init+0x1518>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102059:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f010205f:	89 f8                	mov    %edi,%eax
f0102061:	e8 29 eb ff ff       	call   f0100b8f <check_va2pa>
f0102066:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102069:	0f 85 40 08 00 00    	jne    f01028af <mem_init+0x1531>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f010206f:	83 ec 04             	sub    $0x4,%esp
f0102072:	6a 00                	push   $0x0
f0102074:	53                   	push   %ebx
f0102075:	57                   	push   %edi
f0102076:	e8 35 f0 ff ff       	call   f01010b0 <pgdir_walk>
f010207b:	83 c4 10             	add    $0x10,%esp
f010207e:	f6 00 1a             	testb  $0x1a,(%eax)
f0102081:	0f 84 41 08 00 00    	je     f01028c8 <mem_init+0x154a>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102087:	83 ec 04             	sub    $0x4,%esp
f010208a:	6a 00                	push   $0x0
f010208c:	53                   	push   %ebx
f010208d:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0102093:	e8 18 f0 ff ff       	call   f01010b0 <pgdir_walk>
f0102098:	8b 00                	mov    (%eax),%eax
f010209a:	83 c4 10             	add    $0x10,%esp
f010209d:	83 e0 04             	and    $0x4,%eax
f01020a0:	89 c7                	mov    %eax,%edi
f01020a2:	0f 85 39 08 00 00    	jne    f01028e1 <mem_init+0x1563>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f01020a8:	83 ec 04             	sub    $0x4,%esp
f01020ab:	6a 00                	push   $0x0
f01020ad:	53                   	push   %ebx
f01020ae:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f01020b4:	e8 f7 ef ff ff       	call   f01010b0 <pgdir_walk>
f01020b9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f01020bf:	83 c4 0c             	add    $0xc,%esp
f01020c2:	6a 00                	push   $0x0
f01020c4:	ff 75 d4             	pushl  -0x2c(%ebp)
f01020c7:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f01020cd:	e8 de ef ff ff       	call   f01010b0 <pgdir_walk>
f01020d2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f01020d8:	83 c4 0c             	add    $0xc,%esp
f01020db:	6a 00                	push   $0x0
f01020dd:	56                   	push   %esi
f01020de:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f01020e4:	e8 c7 ef ff ff       	call   f01010b0 <pgdir_walk>
f01020e9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f01020ef:	c7 04 24 e6 79 10 f0 	movl   $0xf01079e6,(%esp)
f01020f6:	e8 bf 18 00 00       	call   f01039ba <cprintf>
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U);
f01020fb:	a1 90 7e 21 f0       	mov    0xf0217e90,%eax
	if ((uint32_t)kva < KERNBASE)
f0102100:	83 c4 10             	add    $0x10,%esp
f0102103:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102108:	0f 86 ec 07 00 00    	jbe    f01028fa <mem_init+0x157c>
f010210e:	83 ec 08             	sub    $0x8,%esp
f0102111:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102113:	05 00 00 00 10       	add    $0x10000000,%eax
f0102118:	50                   	push   %eax
f0102119:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010211e:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102123:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0102128:	e8 14 f0 ff ff       	call   f0101141 <boot_map_region>
	boot_map_region(kern_pgdir,UENVS,PTSIZE,PADDR(envs),PTE_U);
f010212d:	a1 48 72 21 f0       	mov    0xf0217248,%eax
	if ((uint32_t)kva < KERNBASE)
f0102132:	83 c4 10             	add    $0x10,%esp
f0102135:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010213a:	0f 86 cf 07 00 00    	jbe    f010290f <mem_init+0x1591>
f0102140:	83 ec 08             	sub    $0x8,%esp
f0102143:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102145:	05 00 00 00 10       	add    $0x10000000,%eax
f010214a:	50                   	push   %eax
f010214b:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102150:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102155:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f010215a:	e8 e2 ef ff ff       	call   f0101141 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f010215f:	83 c4 10             	add    $0x10,%esp
f0102162:	b8 00 90 11 f0       	mov    $0xf0119000,%eax
f0102167:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010216c:	0f 86 b2 07 00 00    	jbe    f0102924 <mem_init+0x15a6>
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f0102172:	83 ec 08             	sub    $0x8,%esp
f0102175:	6a 02                	push   $0x2
f0102177:	68 00 90 11 00       	push   $0x119000
f010217c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102181:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102186:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f010218b:	e8 b1 ef ff ff       	call   f0101141 <boot_map_region>
f0102190:	c7 45 d0 00 90 21 f0 	movl   $0xf0219000,-0x30(%ebp)
f0102197:	83 c4 10             	add    $0x10,%esp
f010219a:	bb 00 90 21 f0       	mov    $0xf0219000,%ebx
f010219f:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f01021a4:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01021aa:	0f 86 89 07 00 00    	jbe    f0102939 <mem_init+0x15bb>
		boot_map_region(kern_pgdir,kstacktop_i,KSTKSIZE,pa,PTE_W|PTE_P);
f01021b0:	83 ec 08             	sub    $0x8,%esp
f01021b3:	6a 03                	push   $0x3
f01021b5:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f01021bb:	50                   	push   %eax
f01021bc:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021c1:	89 f2                	mov    %esi,%edx
f01021c3:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f01021c8:	e8 74 ef ff ff       	call   f0101141 <boot_map_region>
f01021cd:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f01021d3:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	for(int i = 0;i<NCPU;i++)
f01021d9:	83 c4 10             	add    $0x10,%esp
f01021dc:	81 fb 00 90 25 f0    	cmp    $0xf0259000,%ebx
f01021e2:	75 c0                	jne    f01021a4 <mem_init+0xe26>
	boot_map_region(kern_pgdir,KERNBASE,0xFFFFFFFF-KERNBASE,0,PTE_W);
f01021e4:	83 ec 08             	sub    $0x8,%esp
f01021e7:	6a 02                	push   $0x2
f01021e9:	6a 00                	push   $0x0
f01021eb:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01021f0:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021f5:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f01021fa:	e8 42 ef ff ff       	call   f0101141 <boot_map_region>
	pgdir = kern_pgdir;
f01021ff:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0102204:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102207:	a1 88 7e 21 f0       	mov    0xf0217e88,%eax
f010220c:	89 45 c0             	mov    %eax,-0x40(%ebp)
f010220f:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102216:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010221b:	89 45 cc             	mov    %eax,-0x34(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010221e:	8b 35 90 7e 21 f0    	mov    0xf0217e90,%esi
f0102224:	89 75 c8             	mov    %esi,-0x38(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0102227:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f010222d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f0102230:	83 c4 10             	add    $0x10,%esp
f0102233:	89 fb                	mov    %edi,%ebx
f0102235:	e9 2f 07 00 00       	jmp    f0102969 <mem_init+0x15eb>
	assert(nfree == 0);
f010223a:	68 fd 78 10 f0       	push   $0xf01078fd
f010223f:	68 43 77 10 f0       	push   $0xf0107743
f0102244:	68 b4 03 00 00       	push   $0x3b4
f0102249:	68 1d 77 10 f0       	push   $0xf010771d
f010224e:	e8 ed dd ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f0102253:	68 0b 78 10 f0       	push   $0xf010780b
f0102258:	68 43 77 10 f0       	push   $0xf0107743
f010225d:	68 1a 04 00 00       	push   $0x41a
f0102262:	68 1d 77 10 f0       	push   $0xf010771d
f0102267:	e8 d4 dd ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010226c:	68 21 78 10 f0       	push   $0xf0107821
f0102271:	68 43 77 10 f0       	push   $0xf0107743
f0102276:	68 1b 04 00 00       	push   $0x41b
f010227b:	68 1d 77 10 f0       	push   $0xf010771d
f0102280:	e8 bb dd ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102285:	68 37 78 10 f0       	push   $0xf0107837
f010228a:	68 43 77 10 f0       	push   $0xf0107743
f010228f:	68 1c 04 00 00       	push   $0x41c
f0102294:	68 1d 77 10 f0       	push   $0xf010771d
f0102299:	e8 a2 dd ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f010229e:	68 4d 78 10 f0       	push   $0xf010784d
f01022a3:	68 43 77 10 f0       	push   $0xf0107743
f01022a8:	68 1f 04 00 00       	push   $0x41f
f01022ad:	68 1d 77 10 f0       	push   $0xf010771d
f01022b2:	e8 89 dd ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01022b7:	68 40 6f 10 f0       	push   $0xf0106f40
f01022bc:	68 43 77 10 f0       	push   $0xf0107743
f01022c1:	68 20 04 00 00       	push   $0x420
f01022c6:	68 1d 77 10 f0       	push   $0xf010771d
f01022cb:	e8 70 dd ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01022d0:	68 b6 78 10 f0       	push   $0xf01078b6
f01022d5:	68 43 77 10 f0       	push   $0xf0107743
f01022da:	68 27 04 00 00       	push   $0x427
f01022df:	68 1d 77 10 f0       	push   $0xf010771d
f01022e4:	e8 57 dd ff ff       	call   f0100040 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01022e9:	68 80 6f 10 f0       	push   $0xf0106f80
f01022ee:	68 43 77 10 f0       	push   $0xf0107743
f01022f3:	68 2a 04 00 00       	push   $0x42a
f01022f8:	68 1d 77 10 f0       	push   $0xf010771d
f01022fd:	e8 3e dd ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102302:	68 b8 6f 10 f0       	push   $0xf0106fb8
f0102307:	68 43 77 10 f0       	push   $0xf0107743
f010230c:	68 2d 04 00 00       	push   $0x42d
f0102311:	68 1d 77 10 f0       	push   $0xf010771d
f0102316:	e8 25 dd ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010231b:	68 e8 6f 10 f0       	push   $0xf0106fe8
f0102320:	68 43 77 10 f0       	push   $0xf0107743
f0102325:	68 31 04 00 00       	push   $0x431
f010232a:	68 1d 77 10 f0       	push   $0xf010771d
f010232f:	e8 0c dd ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102334:	68 18 70 10 f0       	push   $0xf0107018
f0102339:	68 43 77 10 f0       	push   $0xf0107743
f010233e:	68 32 04 00 00       	push   $0x432
f0102343:	68 1d 77 10 f0       	push   $0xf010771d
f0102348:	e8 f3 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010234d:	68 40 70 10 f0       	push   $0xf0107040
f0102352:	68 43 77 10 f0       	push   $0xf0107743
f0102357:	68 33 04 00 00       	push   $0x433
f010235c:	68 1d 77 10 f0       	push   $0xf010771d
f0102361:	e8 da dc ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102366:	68 08 79 10 f0       	push   $0xf0107908
f010236b:	68 43 77 10 f0       	push   $0xf0107743
f0102370:	68 34 04 00 00       	push   $0x434
f0102375:	68 1d 77 10 f0       	push   $0xf010771d
f010237a:	e8 c1 dc ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f010237f:	68 19 79 10 f0       	push   $0xf0107919
f0102384:	68 43 77 10 f0       	push   $0xf0107743
f0102389:	68 35 04 00 00       	push   $0x435
f010238e:	68 1d 77 10 f0       	push   $0xf010771d
f0102393:	e8 a8 dc ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102398:	68 70 70 10 f0       	push   $0xf0107070
f010239d:	68 43 77 10 f0       	push   $0xf0107743
f01023a2:	68 38 04 00 00       	push   $0x438
f01023a7:	68 1d 77 10 f0       	push   $0xf010771d
f01023ac:	e8 8f dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01023b1:	68 ac 70 10 f0       	push   $0xf01070ac
f01023b6:	68 43 77 10 f0       	push   $0xf0107743
f01023bb:	68 39 04 00 00       	push   $0x439
f01023c0:	68 1d 77 10 f0       	push   $0xf010771d
f01023c5:	e8 76 dc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01023ca:	68 2a 79 10 f0       	push   $0xf010792a
f01023cf:	68 43 77 10 f0       	push   $0xf0107743
f01023d4:	68 3a 04 00 00       	push   $0x43a
f01023d9:	68 1d 77 10 f0       	push   $0xf010771d
f01023de:	e8 5d dc ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01023e3:	68 b6 78 10 f0       	push   $0xf01078b6
f01023e8:	68 43 77 10 f0       	push   $0xf0107743
f01023ed:	68 3d 04 00 00       	push   $0x43d
f01023f2:	68 1d 77 10 f0       	push   $0xf010771d
f01023f7:	e8 44 dc ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023fc:	68 70 70 10 f0       	push   $0xf0107070
f0102401:	68 43 77 10 f0       	push   $0xf0107743
f0102406:	68 40 04 00 00       	push   $0x440
f010240b:	68 1d 77 10 f0       	push   $0xf010771d
f0102410:	e8 2b dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102415:	68 ac 70 10 f0       	push   $0xf01070ac
f010241a:	68 43 77 10 f0       	push   $0xf0107743
f010241f:	68 41 04 00 00       	push   $0x441
f0102424:	68 1d 77 10 f0       	push   $0xf010771d
f0102429:	e8 12 dc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f010242e:	68 2a 79 10 f0       	push   $0xf010792a
f0102433:	68 43 77 10 f0       	push   $0xf0107743
f0102438:	68 42 04 00 00       	push   $0x442
f010243d:	68 1d 77 10 f0       	push   $0xf010771d
f0102442:	e8 f9 db ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0102447:	68 b6 78 10 f0       	push   $0xf01078b6
f010244c:	68 43 77 10 f0       	push   $0xf0107743
f0102451:	68 46 04 00 00       	push   $0x446
f0102456:	68 1d 77 10 f0       	push   $0xf010771d
f010245b:	e8 e0 db ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102460:	52                   	push   %edx
f0102461:	68 e4 67 10 f0       	push   $0xf01067e4
f0102466:	68 49 04 00 00       	push   $0x449
f010246b:	68 1d 77 10 f0       	push   $0xf010771d
f0102470:	e8 cb db ff ff       	call   f0100040 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102475:	68 dc 70 10 f0       	push   $0xf01070dc
f010247a:	68 43 77 10 f0       	push   $0xf0107743
f010247f:	68 4a 04 00 00       	push   $0x44a
f0102484:	68 1d 77 10 f0       	push   $0xf010771d
f0102489:	e8 b2 db ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010248e:	68 1c 71 10 f0       	push   $0xf010711c
f0102493:	68 43 77 10 f0       	push   $0xf0107743
f0102498:	68 4d 04 00 00       	push   $0x44d
f010249d:	68 1d 77 10 f0       	push   $0xf010771d
f01024a2:	e8 99 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01024a7:	68 ac 70 10 f0       	push   $0xf01070ac
f01024ac:	68 43 77 10 f0       	push   $0xf0107743
f01024b1:	68 4e 04 00 00       	push   $0x44e
f01024b6:	68 1d 77 10 f0       	push   $0xf010771d
f01024bb:	e8 80 db ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01024c0:	68 2a 79 10 f0       	push   $0xf010792a
f01024c5:	68 43 77 10 f0       	push   $0xf0107743
f01024ca:	68 4f 04 00 00       	push   $0x44f
f01024cf:	68 1d 77 10 f0       	push   $0xf010771d
f01024d4:	e8 67 db ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01024d9:	68 5c 71 10 f0       	push   $0xf010715c
f01024de:	68 43 77 10 f0       	push   $0xf0107743
f01024e3:	68 50 04 00 00       	push   $0x450
f01024e8:	68 1d 77 10 f0       	push   $0xf010771d
f01024ed:	e8 4e db ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01024f2:	68 3b 79 10 f0       	push   $0xf010793b
f01024f7:	68 43 77 10 f0       	push   $0xf0107743
f01024fc:	68 51 04 00 00       	push   $0x451
f0102501:	68 1d 77 10 f0       	push   $0xf010771d
f0102506:	e8 35 db ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010250b:	68 70 70 10 f0       	push   $0xf0107070
f0102510:	68 43 77 10 f0       	push   $0xf0107743
f0102515:	68 54 04 00 00       	push   $0x454
f010251a:	68 1d 77 10 f0       	push   $0xf010771d
f010251f:	e8 1c db ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102524:	68 90 71 10 f0       	push   $0xf0107190
f0102529:	68 43 77 10 f0       	push   $0xf0107743
f010252e:	68 55 04 00 00       	push   $0x455
f0102533:	68 1d 77 10 f0       	push   $0xf010771d
f0102538:	e8 03 db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010253d:	68 c4 71 10 f0       	push   $0xf01071c4
f0102542:	68 43 77 10 f0       	push   $0xf0107743
f0102547:	68 56 04 00 00       	push   $0x456
f010254c:	68 1d 77 10 f0       	push   $0xf010771d
f0102551:	e8 ea da ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102556:	68 fc 71 10 f0       	push   $0xf01071fc
f010255b:	68 43 77 10 f0       	push   $0xf0107743
f0102560:	68 59 04 00 00       	push   $0x459
f0102565:	68 1d 77 10 f0       	push   $0xf010771d
f010256a:	e8 d1 da ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010256f:	68 34 72 10 f0       	push   $0xf0107234
f0102574:	68 43 77 10 f0       	push   $0xf0107743
f0102579:	68 5c 04 00 00       	push   $0x45c
f010257e:	68 1d 77 10 f0       	push   $0xf010771d
f0102583:	e8 b8 da ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102588:	68 c4 71 10 f0       	push   $0xf01071c4
f010258d:	68 43 77 10 f0       	push   $0xf0107743
f0102592:	68 5d 04 00 00       	push   $0x45d
f0102597:	68 1d 77 10 f0       	push   $0xf010771d
f010259c:	e8 9f da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01025a1:	68 70 72 10 f0       	push   $0xf0107270
f01025a6:	68 43 77 10 f0       	push   $0xf0107743
f01025ab:	68 60 04 00 00       	push   $0x460
f01025b0:	68 1d 77 10 f0       	push   $0xf010771d
f01025b5:	e8 86 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01025ba:	68 9c 72 10 f0       	push   $0xf010729c
f01025bf:	68 43 77 10 f0       	push   $0xf0107743
f01025c4:	68 61 04 00 00       	push   $0x461
f01025c9:	68 1d 77 10 f0       	push   $0xf010771d
f01025ce:	e8 6d da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 2);
f01025d3:	68 51 79 10 f0       	push   $0xf0107951
f01025d8:	68 43 77 10 f0       	push   $0xf0107743
f01025dd:	68 63 04 00 00       	push   $0x463
f01025e2:	68 1d 77 10 f0       	push   $0xf010771d
f01025e7:	e8 54 da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01025ec:	68 62 79 10 f0       	push   $0xf0107962
f01025f1:	68 43 77 10 f0       	push   $0xf0107743
f01025f6:	68 64 04 00 00       	push   $0x464
f01025fb:	68 1d 77 10 f0       	push   $0xf010771d
f0102600:	e8 3b da ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102605:	68 cc 72 10 f0       	push   $0xf01072cc
f010260a:	68 43 77 10 f0       	push   $0xf0107743
f010260f:	68 67 04 00 00       	push   $0x467
f0102614:	68 1d 77 10 f0       	push   $0xf010771d
f0102619:	e8 22 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010261e:	68 f0 72 10 f0       	push   $0xf01072f0
f0102623:	68 43 77 10 f0       	push   $0xf0107743
f0102628:	68 6b 04 00 00       	push   $0x46b
f010262d:	68 1d 77 10 f0       	push   $0xf010771d
f0102632:	e8 09 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102637:	68 9c 72 10 f0       	push   $0xf010729c
f010263c:	68 43 77 10 f0       	push   $0xf0107743
f0102641:	68 6c 04 00 00       	push   $0x46c
f0102646:	68 1d 77 10 f0       	push   $0xf010771d
f010264b:	e8 f0 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102650:	68 08 79 10 f0       	push   $0xf0107908
f0102655:	68 43 77 10 f0       	push   $0xf0107743
f010265a:	68 6d 04 00 00       	push   $0x46d
f010265f:	68 1d 77 10 f0       	push   $0xf010771d
f0102664:	e8 d7 d9 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102669:	68 62 79 10 f0       	push   $0xf0107962
f010266e:	68 43 77 10 f0       	push   $0xf0107743
f0102673:	68 6e 04 00 00       	push   $0x46e
f0102678:	68 1d 77 10 f0       	push   $0xf010771d
f010267d:	e8 be d9 ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102682:	68 14 73 10 f0       	push   $0xf0107314
f0102687:	68 43 77 10 f0       	push   $0xf0107743
f010268c:	68 71 04 00 00       	push   $0x471
f0102691:	68 1d 77 10 f0       	push   $0xf010771d
f0102696:	e8 a5 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f010269b:	68 73 79 10 f0       	push   $0xf0107973
f01026a0:	68 43 77 10 f0       	push   $0xf0107743
f01026a5:	68 72 04 00 00       	push   $0x472
f01026aa:	68 1d 77 10 f0       	push   $0xf010771d
f01026af:	e8 8c d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f01026b4:	68 7f 79 10 f0       	push   $0xf010797f
f01026b9:	68 43 77 10 f0       	push   $0xf0107743
f01026be:	68 73 04 00 00       	push   $0x473
f01026c3:	68 1d 77 10 f0       	push   $0xf010771d
f01026c8:	e8 73 d9 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01026cd:	68 f0 72 10 f0       	push   $0xf01072f0
f01026d2:	68 43 77 10 f0       	push   $0xf0107743
f01026d7:	68 77 04 00 00       	push   $0x477
f01026dc:	68 1d 77 10 f0       	push   $0xf010771d
f01026e1:	e8 5a d9 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01026e6:	68 4c 73 10 f0       	push   $0xf010734c
f01026eb:	68 43 77 10 f0       	push   $0xf0107743
f01026f0:	68 78 04 00 00       	push   $0x478
f01026f5:	68 1d 77 10 f0       	push   $0xf010771d
f01026fa:	e8 41 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01026ff:	68 94 79 10 f0       	push   $0xf0107994
f0102704:	68 43 77 10 f0       	push   $0xf0107743
f0102709:	68 79 04 00 00       	push   $0x479
f010270e:	68 1d 77 10 f0       	push   $0xf010771d
f0102713:	e8 28 d9 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102718:	68 62 79 10 f0       	push   $0xf0107962
f010271d:	68 43 77 10 f0       	push   $0xf0107743
f0102722:	68 7a 04 00 00       	push   $0x47a
f0102727:	68 1d 77 10 f0       	push   $0xf010771d
f010272c:	e8 0f d9 ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f0102731:	68 74 73 10 f0       	push   $0xf0107374
f0102736:	68 43 77 10 f0       	push   $0xf0107743
f010273b:	68 7d 04 00 00       	push   $0x47d
f0102740:	68 1d 77 10 f0       	push   $0xf010771d
f0102745:	e8 f6 d8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f010274a:	68 b6 78 10 f0       	push   $0xf01078b6
f010274f:	68 43 77 10 f0       	push   $0xf0107743
f0102754:	68 80 04 00 00       	push   $0x480
f0102759:	68 1d 77 10 f0       	push   $0xf010771d
f010275e:	e8 dd d8 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102763:	68 18 70 10 f0       	push   $0xf0107018
f0102768:	68 43 77 10 f0       	push   $0xf0107743
f010276d:	68 83 04 00 00       	push   $0x483
f0102772:	68 1d 77 10 f0       	push   $0xf010771d
f0102777:	e8 c4 d8 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f010277c:	68 19 79 10 f0       	push   $0xf0107919
f0102781:	68 43 77 10 f0       	push   $0xf0107743
f0102786:	68 85 04 00 00       	push   $0x485
f010278b:	68 1d 77 10 f0       	push   $0xf010771d
f0102790:	e8 ab d8 ff ff       	call   f0100040 <_panic>
f0102795:	56                   	push   %esi
f0102796:	68 e4 67 10 f0       	push   $0xf01067e4
f010279b:	68 8c 04 00 00       	push   $0x48c
f01027a0:	68 1d 77 10 f0       	push   $0xf010771d
f01027a5:	e8 96 d8 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01027aa:	68 a5 79 10 f0       	push   $0xf01079a5
f01027af:	68 43 77 10 f0       	push   $0xf0107743
f01027b4:	68 8d 04 00 00       	push   $0x48d
f01027b9:	68 1d 77 10 f0       	push   $0xf010771d
f01027be:	e8 7d d8 ff ff       	call   f0100040 <_panic>
f01027c3:	51                   	push   %ecx
f01027c4:	68 e4 67 10 f0       	push   $0xf01067e4
f01027c9:	6a 58                	push   $0x58
f01027cb:	68 29 77 10 f0       	push   $0xf0107729
f01027d0:	e8 6b d8 ff ff       	call   f0100040 <_panic>
f01027d5:	52                   	push   %edx
f01027d6:	68 e4 67 10 f0       	push   $0xf01067e4
f01027db:	6a 58                	push   $0x58
f01027dd:	68 29 77 10 f0       	push   $0xf0107729
f01027e2:	e8 59 d8 ff ff       	call   f0100040 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f01027e7:	68 bd 79 10 f0       	push   $0xf01079bd
f01027ec:	68 43 77 10 f0       	push   $0xf0107743
f01027f1:	68 97 04 00 00       	push   $0x497
f01027f6:	68 1d 77 10 f0       	push   $0xf010771d
f01027fb:	e8 40 d8 ff ff       	call   f0100040 <_panic>
	assert(mm1 >= MMIOBASE && mm1 + 8192 < MMIOLIM);
f0102800:	68 98 73 10 f0       	push   $0xf0107398
f0102805:	68 43 77 10 f0       	push   $0xf0107743
f010280a:	68 a7 04 00 00       	push   $0x4a7
f010280f:	68 1d 77 10 f0       	push   $0xf010771d
f0102814:	e8 27 d8 ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8192 < MMIOLIM);
f0102819:	68 c0 73 10 f0       	push   $0xf01073c0
f010281e:	68 43 77 10 f0       	push   $0xf0107743
f0102823:	68 a8 04 00 00       	push   $0x4a8
f0102828:	68 1d 77 10 f0       	push   $0xf010771d
f010282d:	e8 0e d8 ff ff       	call   f0100040 <_panic>
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102832:	68 e8 73 10 f0       	push   $0xf01073e8
f0102837:	68 43 77 10 f0       	push   $0xf0107743
f010283c:	68 aa 04 00 00       	push   $0x4aa
f0102841:	68 1d 77 10 f0       	push   $0xf010771d
f0102846:	e8 f5 d7 ff ff       	call   f0100040 <_panic>
	assert(mm1 + 8192 <= mm2);
f010284b:	68 d4 79 10 f0       	push   $0xf01079d4
f0102850:	68 43 77 10 f0       	push   $0xf0107743
f0102855:	68 ac 04 00 00       	push   $0x4ac
f010285a:	68 1d 77 10 f0       	push   $0xf010771d
f010285f:	e8 dc d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102864:	68 10 74 10 f0       	push   $0xf0107410
f0102869:	68 43 77 10 f0       	push   $0xf0107743
f010286e:	68 ae 04 00 00       	push   $0x4ae
f0102873:	68 1d 77 10 f0       	push   $0xf010771d
f0102878:	e8 c3 d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f010287d:	68 34 74 10 f0       	push   $0xf0107434
f0102882:	68 43 77 10 f0       	push   $0xf0107743
f0102887:	68 af 04 00 00       	push   $0x4af
f010288c:	68 1d 77 10 f0       	push   $0xf010771d
f0102891:	e8 aa d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102896:	68 64 74 10 f0       	push   $0xf0107464
f010289b:	68 43 77 10 f0       	push   $0xf0107743
f01028a0:	68 b0 04 00 00       	push   $0x4b0
f01028a5:	68 1d 77 10 f0       	push   $0xf010771d
f01028aa:	e8 91 d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f01028af:	68 88 74 10 f0       	push   $0xf0107488
f01028b4:	68 43 77 10 f0       	push   $0xf0107743
f01028b9:	68 b1 04 00 00       	push   $0x4b1
f01028be:	68 1d 77 10 f0       	push   $0xf010771d
f01028c3:	e8 78 d7 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f01028c8:	68 b4 74 10 f0       	push   $0xf01074b4
f01028cd:	68 43 77 10 f0       	push   $0xf0107743
f01028d2:	68 b3 04 00 00       	push   $0x4b3
f01028d7:	68 1d 77 10 f0       	push   $0xf010771d
f01028dc:	e8 5f d7 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f01028e1:	68 f8 74 10 f0       	push   $0xf01074f8
f01028e6:	68 43 77 10 f0       	push   $0xf0107743
f01028eb:	68 b4 04 00 00       	push   $0x4b4
f01028f0:	68 1d 77 10 f0       	push   $0xf010771d
f01028f5:	e8 46 d7 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028fa:	50                   	push   %eax
f01028fb:	68 08 68 10 f0       	push   $0xf0106808
f0102900:	68 cd 00 00 00       	push   $0xcd
f0102905:	68 1d 77 10 f0       	push   $0xf010771d
f010290a:	e8 31 d7 ff ff       	call   f0100040 <_panic>
f010290f:	50                   	push   %eax
f0102910:	68 08 68 10 f0       	push   $0xf0106808
f0102915:	68 d5 00 00 00       	push   $0xd5
f010291a:	68 1d 77 10 f0       	push   $0xf010771d
f010291f:	e8 1c d7 ff ff       	call   f0100040 <_panic>
f0102924:	50                   	push   %eax
f0102925:	68 08 68 10 f0       	push   $0xf0106808
f010292a:	68 e1 00 00 00       	push   $0xe1
f010292f:	68 1d 77 10 f0       	push   $0xf010771d
f0102934:	e8 07 d7 ff ff       	call   f0100040 <_panic>
f0102939:	53                   	push   %ebx
f010293a:	68 08 68 10 f0       	push   $0xf0106808
f010293f:	68 21 01 00 00       	push   $0x121
f0102944:	68 1d 77 10 f0       	push   $0xf010771d
f0102949:	e8 f2 d6 ff ff       	call   f0100040 <_panic>
f010294e:	56                   	push   %esi
f010294f:	68 08 68 10 f0       	push   $0xf0106808
f0102954:	68 cc 03 00 00       	push   $0x3cc
f0102959:	68 1d 77 10 f0       	push   $0xf010771d
f010295e:	e8 dd d6 ff ff       	call   f0100040 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f0102963:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102969:	39 5d cc             	cmp    %ebx,-0x34(%ebp)
f010296c:	76 3a                	jbe    f01029a8 <mem_init+0x162a>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010296e:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102974:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102977:	e8 13 e2 ff ff       	call   f0100b8f <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f010297c:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f0102983:	76 c9                	jbe    f010294e <mem_init+0x15d0>
f0102985:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102988:	8d 14 0b             	lea    (%ebx,%ecx,1),%edx
f010298b:	39 d0                	cmp    %edx,%eax
f010298d:	74 d4                	je     f0102963 <mem_init+0x15e5>
f010298f:	68 2c 75 10 f0       	push   $0xf010752c
f0102994:	68 43 77 10 f0       	push   $0xf0107743
f0102999:	68 cc 03 00 00       	push   $0x3cc
f010299e:	68 1d 77 10 f0       	push   $0xf010771d
f01029a3:	e8 98 d6 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01029a8:	a1 48 72 21 f0       	mov    0xf0217248,%eax
f01029ad:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01029b0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01029b3:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f01029b8:	8d b0 00 00 40 21    	lea    0x21400000(%eax),%esi
f01029be:	89 da                	mov    %ebx,%edx
f01029c0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029c3:	e8 c7 e1 ff ff       	call   f0100b8f <check_va2pa>
f01029c8:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f01029cf:	76 3b                	jbe    f0102a0c <mem_init+0x168e>
f01029d1:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f01029d4:	39 d0                	cmp    %edx,%eax
f01029d6:	75 4b                	jne    f0102a23 <mem_init+0x16a5>
f01029d8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
f01029de:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f01029e4:	75 d8                	jne    f01029be <mem_init+0x1640>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01029e6:	8b 75 c0             	mov    -0x40(%ebp),%esi
f01029e9:	c1 e6 0c             	shl    $0xc,%esi
f01029ec:	89 fb                	mov    %edi,%ebx
f01029ee:	39 f3                	cmp    %esi,%ebx
f01029f0:	73 63                	jae    f0102a55 <mem_init+0x16d7>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01029f2:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01029f8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029fb:	e8 8f e1 ff ff       	call   f0100b8f <check_va2pa>
f0102a00:	39 c3                	cmp    %eax,%ebx
f0102a02:	75 38                	jne    f0102a3c <mem_init+0x16be>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a04:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102a0a:	eb e2                	jmp    f01029ee <mem_init+0x1670>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a0c:	ff 75 c8             	pushl  -0x38(%ebp)
f0102a0f:	68 08 68 10 f0       	push   $0xf0106808
f0102a14:	68 d1 03 00 00       	push   $0x3d1
f0102a19:	68 1d 77 10 f0       	push   $0xf010771d
f0102a1e:	e8 1d d6 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102a23:	68 60 75 10 f0       	push   $0xf0107560
f0102a28:	68 43 77 10 f0       	push   $0xf0107743
f0102a2d:	68 d1 03 00 00       	push   $0x3d1
f0102a32:	68 1d 77 10 f0       	push   $0xf010771d
f0102a37:	e8 04 d6 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102a3c:	68 94 75 10 f0       	push   $0xf0107594
f0102a41:	68 43 77 10 f0       	push   $0xf0107743
f0102a46:	68 d5 03 00 00       	push   $0x3d5
f0102a4b:	68 1d 77 10 f0       	push   $0xf010771d
f0102a50:	e8 eb d5 ff ff       	call   f0100040 <_panic>
f0102a55:	c7 45 cc 00 90 22 00 	movl   $0x229000,-0x34(%ebp)
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a5c:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
f0102a61:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0102a64:	8d bb 00 80 ff ff    	lea    -0x8000(%ebx),%edi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102a6a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102a6d:	89 45 bc             	mov    %eax,-0x44(%ebp)
f0102a70:	89 de                	mov    %ebx,%esi
f0102a72:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102a75:	05 00 80 ff 0f       	add    $0xfff8000,%eax
f0102a7a:	89 45 c8             	mov    %eax,-0x38(%ebp)
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102a7d:	8d 83 00 80 00 00    	lea    0x8000(%ebx),%eax
f0102a83:	89 45 c4             	mov    %eax,-0x3c(%ebp)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102a86:	89 f2                	mov    %esi,%edx
f0102a88:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a8b:	e8 ff e0 ff ff       	call   f0100b8f <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102a90:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102a97:	76 58                	jbe    f0102af1 <mem_init+0x1773>
f0102a99:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102a9c:	8d 14 31             	lea    (%ecx,%esi,1),%edx
f0102a9f:	39 d0                	cmp    %edx,%eax
f0102aa1:	75 65                	jne    f0102b08 <mem_init+0x178a>
f0102aa3:	81 c6 00 10 00 00    	add    $0x1000,%esi
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102aa9:	3b 75 c4             	cmp    -0x3c(%ebp),%esi
f0102aac:	75 d8                	jne    f0102a86 <mem_init+0x1708>
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102aae:	89 fa                	mov    %edi,%edx
f0102ab0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ab3:	e8 d7 e0 ff ff       	call   f0100b8f <check_va2pa>
f0102ab8:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102abb:	75 64                	jne    f0102b21 <mem_init+0x17a3>
f0102abd:	81 c7 00 10 00 00    	add    $0x1000,%edi
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102ac3:	39 df                	cmp    %ebx,%edi
f0102ac5:	75 e7                	jne    f0102aae <mem_init+0x1730>
f0102ac7:	81 eb 00 00 01 00    	sub    $0x10000,%ebx
f0102acd:	81 45 d0 00 80 00 00 	addl   $0x8000,-0x30(%ebp)
f0102ad4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102ad7:	81 45 cc 00 80 01 00 	addl   $0x18000,-0x34(%ebp)
	for (n = 0; n < NCPU; n++) {
f0102ade:	3d 00 90 25 f0       	cmp    $0xf0259000,%eax
f0102ae3:	0f 85 7b ff ff ff    	jne    f0102a64 <mem_init+0x16e6>
f0102ae9:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0102aec:	e9 84 00 00 00       	jmp    f0102b75 <mem_init+0x17f7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102af1:	ff 75 bc             	pushl  -0x44(%ebp)
f0102af4:	68 08 68 10 f0       	push   $0xf0106808
f0102af9:	68 dd 03 00 00       	push   $0x3dd
f0102afe:	68 1d 77 10 f0       	push   $0xf010771d
f0102b03:	e8 38 d5 ff ff       	call   f0100040 <_panic>
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102b08:	68 bc 75 10 f0       	push   $0xf01075bc
f0102b0d:	68 43 77 10 f0       	push   $0xf0107743
f0102b12:	68 dc 03 00 00       	push   $0x3dc
f0102b17:	68 1d 77 10 f0       	push   $0xf010771d
f0102b1c:	e8 1f d5 ff ff       	call   f0100040 <_panic>
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102b21:	68 04 76 10 f0       	push   $0xf0107604
f0102b26:	68 43 77 10 f0       	push   $0xf0107743
f0102b2b:	68 df 03 00 00       	push   $0x3df
f0102b30:	68 1d 77 10 f0       	push   $0xf010771d
f0102b35:	e8 06 d5 ff ff       	call   f0100040 <_panic>
			assert(pgdir[i] & PTE_P);
f0102b3a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b3d:	f6 04 b8 01          	testb  $0x1,(%eax,%edi,4)
f0102b41:	75 4e                	jne    f0102b91 <mem_init+0x1813>
f0102b43:	68 ff 79 10 f0       	push   $0xf01079ff
f0102b48:	68 43 77 10 f0       	push   $0xf0107743
f0102b4d:	68 ea 03 00 00       	push   $0x3ea
f0102b52:	68 1d 77 10 f0       	push   $0xf010771d
f0102b57:	e8 e4 d4 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_P);
f0102b5c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b5f:	8b 04 b8             	mov    (%eax,%edi,4),%eax
f0102b62:	a8 01                	test   $0x1,%al
f0102b64:	74 30                	je     f0102b96 <mem_init+0x1818>
				assert(pgdir[i] & PTE_W);
f0102b66:	a8 02                	test   $0x2,%al
f0102b68:	74 45                	je     f0102baf <mem_init+0x1831>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b6a:	83 c7 01             	add    $0x1,%edi
f0102b6d:	81 ff 00 04 00 00    	cmp    $0x400,%edi
f0102b73:	74 6c                	je     f0102be1 <mem_init+0x1863>
		switch (i) {
f0102b75:	8d 87 45 fc ff ff    	lea    -0x3bb(%edi),%eax
f0102b7b:	83 f8 04             	cmp    $0x4,%eax
f0102b7e:	76 ba                	jbe    f0102b3a <mem_init+0x17bc>
			if (i >= PDX(KERNBASE)) {
f0102b80:	81 ff bf 03 00 00    	cmp    $0x3bf,%edi
f0102b86:	77 d4                	ja     f0102b5c <mem_init+0x17de>
				assert(pgdir[i] == 0);
f0102b88:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b8b:	83 3c b8 00          	cmpl   $0x0,(%eax,%edi,4)
f0102b8f:	75 37                	jne    f0102bc8 <mem_init+0x184a>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b91:	83 c7 01             	add    $0x1,%edi
f0102b94:	eb df                	jmp    f0102b75 <mem_init+0x17f7>
				assert(pgdir[i] & PTE_P);
f0102b96:	68 ff 79 10 f0       	push   $0xf01079ff
f0102b9b:	68 43 77 10 f0       	push   $0xf0107743
f0102ba0:	68 ee 03 00 00       	push   $0x3ee
f0102ba5:	68 1d 77 10 f0       	push   $0xf010771d
f0102baa:	e8 91 d4 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102baf:	68 10 7a 10 f0       	push   $0xf0107a10
f0102bb4:	68 43 77 10 f0       	push   $0xf0107743
f0102bb9:	68 ef 03 00 00       	push   $0x3ef
f0102bbe:	68 1d 77 10 f0       	push   $0xf010771d
f0102bc3:	e8 78 d4 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] == 0);
f0102bc8:	68 21 7a 10 f0       	push   $0xf0107a21
f0102bcd:	68 43 77 10 f0       	push   $0xf0107743
f0102bd2:	68 f1 03 00 00       	push   $0x3f1
f0102bd7:	68 1d 77 10 f0       	push   $0xf010771d
f0102bdc:	e8 5f d4 ff ff       	call   f0100040 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102be1:	83 ec 0c             	sub    $0xc,%esp
f0102be4:	68 28 76 10 f0       	push   $0xf0107628
f0102be9:	e8 cc 0d 00 00       	call   f01039ba <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102bee:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0102bf3:	83 c4 10             	add    $0x10,%esp
f0102bf6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102bfb:	0f 86 03 02 00 00    	jbe    f0102e04 <mem_init+0x1a86>
	return (physaddr_t)kva - KERNBASE;
f0102c01:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102c06:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102c09:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c0e:	e8 df df ff ff       	call   f0100bf2 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102c13:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102c16:	83 e0 f3             	and    $0xfffffff3,%eax
f0102c19:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102c1e:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102c21:	83 ec 0c             	sub    $0xc,%esp
f0102c24:	6a 00                	push   $0x0
f0102c26:	e8 a0 e3 ff ff       	call   f0100fcb <page_alloc>
f0102c2b:	89 c6                	mov    %eax,%esi
f0102c2d:	83 c4 10             	add    $0x10,%esp
f0102c30:	85 c0                	test   %eax,%eax
f0102c32:	0f 84 e1 01 00 00    	je     f0102e19 <mem_init+0x1a9b>
	assert((pp1 = page_alloc(0)));
f0102c38:	83 ec 0c             	sub    $0xc,%esp
f0102c3b:	6a 00                	push   $0x0
f0102c3d:	e8 89 e3 ff ff       	call   f0100fcb <page_alloc>
f0102c42:	89 c7                	mov    %eax,%edi
f0102c44:	83 c4 10             	add    $0x10,%esp
f0102c47:	85 c0                	test   %eax,%eax
f0102c49:	0f 84 e3 01 00 00    	je     f0102e32 <mem_init+0x1ab4>
	assert((pp2 = page_alloc(0)));
f0102c4f:	83 ec 0c             	sub    $0xc,%esp
f0102c52:	6a 00                	push   $0x0
f0102c54:	e8 72 e3 ff ff       	call   f0100fcb <page_alloc>
f0102c59:	89 c3                	mov    %eax,%ebx
f0102c5b:	83 c4 10             	add    $0x10,%esp
f0102c5e:	85 c0                	test   %eax,%eax
f0102c60:	0f 84 e5 01 00 00    	je     f0102e4b <mem_init+0x1acd>
	page_free(pp0);
f0102c66:	83 ec 0c             	sub    $0xc,%esp
f0102c69:	56                   	push   %esi
f0102c6a:	e8 d5 e3 ff ff       	call   f0101044 <page_free>
	return (pp - pages) << PGSHIFT;
f0102c6f:	89 f8                	mov    %edi,%eax
f0102c71:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0102c77:	c1 f8 03             	sar    $0x3,%eax
f0102c7a:	89 c2                	mov    %eax,%edx
f0102c7c:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102c7f:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102c84:	83 c4 10             	add    $0x10,%esp
f0102c87:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0102c8d:	0f 83 d1 01 00 00    	jae    f0102e64 <mem_init+0x1ae6>
	memset(page2kva(pp1), 1, PGSIZE);
f0102c93:	83 ec 04             	sub    $0x4,%esp
f0102c96:	68 00 10 00 00       	push   $0x1000
f0102c9b:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102c9d:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102ca3:	52                   	push   %edx
f0102ca4:	e8 77 2e 00 00       	call   f0105b20 <memset>
	return (pp - pages) << PGSHIFT;
f0102ca9:	89 d8                	mov    %ebx,%eax
f0102cab:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0102cb1:	c1 f8 03             	sar    $0x3,%eax
f0102cb4:	89 c2                	mov    %eax,%edx
f0102cb6:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102cb9:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102cbe:	83 c4 10             	add    $0x10,%esp
f0102cc1:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0102cc7:	0f 83 a9 01 00 00    	jae    f0102e76 <mem_init+0x1af8>
	memset(page2kva(pp2), 2, PGSIZE);
f0102ccd:	83 ec 04             	sub    $0x4,%esp
f0102cd0:	68 00 10 00 00       	push   $0x1000
f0102cd5:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102cd7:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102cdd:	52                   	push   %edx
f0102cde:	e8 3d 2e 00 00       	call   f0105b20 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102ce3:	6a 02                	push   $0x2
f0102ce5:	68 00 10 00 00       	push   $0x1000
f0102cea:	57                   	push   %edi
f0102ceb:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0102cf1:	e8 8a e5 ff ff       	call   f0101280 <page_insert>
	assert(pp1->pp_ref == 1);
f0102cf6:	83 c4 20             	add    $0x20,%esp
f0102cf9:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102cfe:	0f 85 84 01 00 00    	jne    f0102e88 <mem_init+0x1b0a>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102d04:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102d0b:	01 01 01 
f0102d0e:	0f 85 8d 01 00 00    	jne    f0102ea1 <mem_init+0x1b23>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102d14:	6a 02                	push   $0x2
f0102d16:	68 00 10 00 00       	push   $0x1000
f0102d1b:	53                   	push   %ebx
f0102d1c:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0102d22:	e8 59 e5 ff ff       	call   f0101280 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102d27:	83 c4 10             	add    $0x10,%esp
f0102d2a:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102d31:	02 02 02 
f0102d34:	0f 85 80 01 00 00    	jne    f0102eba <mem_init+0x1b3c>
	assert(pp2->pp_ref == 1);
f0102d3a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102d3f:	0f 85 8e 01 00 00    	jne    f0102ed3 <mem_init+0x1b55>
	assert(pp1->pp_ref == 0);
f0102d45:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102d4a:	0f 85 9c 01 00 00    	jne    f0102eec <mem_init+0x1b6e>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d50:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d57:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102d5a:	89 d8                	mov    %ebx,%eax
f0102d5c:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0102d62:	c1 f8 03             	sar    $0x3,%eax
f0102d65:	89 c2                	mov    %eax,%edx
f0102d67:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102d6a:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102d6f:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0102d75:	0f 83 8a 01 00 00    	jae    f0102f05 <mem_init+0x1b87>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d7b:	81 ba 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%edx)
f0102d82:	03 03 03 
f0102d85:	0f 85 8c 01 00 00    	jne    f0102f17 <mem_init+0x1b99>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d8b:	83 ec 08             	sub    $0x8,%esp
f0102d8e:	68 00 10 00 00       	push   $0x1000
f0102d93:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0102d99:	e8 91 e4 ff ff       	call   f010122f <page_remove>
	assert(pp2->pp_ref == 0);
f0102d9e:	83 c4 10             	add    $0x10,%esp
f0102da1:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102da6:	0f 85 84 01 00 00    	jne    f0102f30 <mem_init+0x1bb2>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102dac:	8b 0d 8c 7e 21 f0    	mov    0xf0217e8c,%ecx
f0102db2:	8b 11                	mov    (%ecx),%edx
f0102db4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102dba:	89 f0                	mov    %esi,%eax
f0102dbc:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0102dc2:	c1 f8 03             	sar    $0x3,%eax
f0102dc5:	c1 e0 0c             	shl    $0xc,%eax
f0102dc8:	39 c2                	cmp    %eax,%edx
f0102dca:	0f 85 79 01 00 00    	jne    f0102f49 <mem_init+0x1bcb>
	kern_pgdir[0] = 0;
f0102dd0:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102dd6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102ddb:	0f 85 81 01 00 00    	jne    f0102f62 <mem_init+0x1be4>
	pp0->pp_ref = 0;
f0102de1:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102de7:	83 ec 0c             	sub    $0xc,%esp
f0102dea:	56                   	push   %esi
f0102deb:	e8 54 e2 ff ff       	call   f0101044 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102df0:	c7 04 24 bc 76 10 f0 	movl   $0xf01076bc,(%esp)
f0102df7:	e8 be 0b 00 00       	call   f01039ba <cprintf>
}
f0102dfc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102dff:	5b                   	pop    %ebx
f0102e00:	5e                   	pop    %esi
f0102e01:	5f                   	pop    %edi
f0102e02:	5d                   	pop    %ebp
f0102e03:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e04:	50                   	push   %eax
f0102e05:	68 08 68 10 f0       	push   $0xf0106808
f0102e0a:	68 f9 00 00 00       	push   $0xf9
f0102e0f:	68 1d 77 10 f0       	push   $0xf010771d
f0102e14:	e8 27 d2 ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f0102e19:	68 0b 78 10 f0       	push   $0xf010780b
f0102e1e:	68 43 77 10 f0       	push   $0xf0107743
f0102e23:	68 c9 04 00 00       	push   $0x4c9
f0102e28:	68 1d 77 10 f0       	push   $0xf010771d
f0102e2d:	e8 0e d2 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102e32:	68 21 78 10 f0       	push   $0xf0107821
f0102e37:	68 43 77 10 f0       	push   $0xf0107743
f0102e3c:	68 ca 04 00 00       	push   $0x4ca
f0102e41:	68 1d 77 10 f0       	push   $0xf010771d
f0102e46:	e8 f5 d1 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102e4b:	68 37 78 10 f0       	push   $0xf0107837
f0102e50:	68 43 77 10 f0       	push   $0xf0107743
f0102e55:	68 cb 04 00 00       	push   $0x4cb
f0102e5a:	68 1d 77 10 f0       	push   $0xf010771d
f0102e5f:	e8 dc d1 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e64:	52                   	push   %edx
f0102e65:	68 e4 67 10 f0       	push   $0xf01067e4
f0102e6a:	6a 58                	push   $0x58
f0102e6c:	68 29 77 10 f0       	push   $0xf0107729
f0102e71:	e8 ca d1 ff ff       	call   f0100040 <_panic>
f0102e76:	52                   	push   %edx
f0102e77:	68 e4 67 10 f0       	push   $0xf01067e4
f0102e7c:	6a 58                	push   $0x58
f0102e7e:	68 29 77 10 f0       	push   $0xf0107729
f0102e83:	e8 b8 d1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102e88:	68 08 79 10 f0       	push   $0xf0107908
f0102e8d:	68 43 77 10 f0       	push   $0xf0107743
f0102e92:	68 d0 04 00 00       	push   $0x4d0
f0102e97:	68 1d 77 10 f0       	push   $0xf010771d
f0102e9c:	e8 9f d1 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ea1:	68 48 76 10 f0       	push   $0xf0107648
f0102ea6:	68 43 77 10 f0       	push   $0xf0107743
f0102eab:	68 d1 04 00 00       	push   $0x4d1
f0102eb0:	68 1d 77 10 f0       	push   $0xf010771d
f0102eb5:	e8 86 d1 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102eba:	68 6c 76 10 f0       	push   $0xf010766c
f0102ebf:	68 43 77 10 f0       	push   $0xf0107743
f0102ec4:	68 d3 04 00 00       	push   $0x4d3
f0102ec9:	68 1d 77 10 f0       	push   $0xf010771d
f0102ece:	e8 6d d1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102ed3:	68 2a 79 10 f0       	push   $0xf010792a
f0102ed8:	68 43 77 10 f0       	push   $0xf0107743
f0102edd:	68 d4 04 00 00       	push   $0x4d4
f0102ee2:	68 1d 77 10 f0       	push   $0xf010771d
f0102ee7:	e8 54 d1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102eec:	68 94 79 10 f0       	push   $0xf0107994
f0102ef1:	68 43 77 10 f0       	push   $0xf0107743
f0102ef6:	68 d5 04 00 00       	push   $0x4d5
f0102efb:	68 1d 77 10 f0       	push   $0xf010771d
f0102f00:	e8 3b d1 ff ff       	call   f0100040 <_panic>
f0102f05:	52                   	push   %edx
f0102f06:	68 e4 67 10 f0       	push   $0xf01067e4
f0102f0b:	6a 58                	push   $0x58
f0102f0d:	68 29 77 10 f0       	push   $0xf0107729
f0102f12:	e8 29 d1 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102f17:	68 90 76 10 f0       	push   $0xf0107690
f0102f1c:	68 43 77 10 f0       	push   $0xf0107743
f0102f21:	68 d7 04 00 00       	push   $0x4d7
f0102f26:	68 1d 77 10 f0       	push   $0xf010771d
f0102f2b:	e8 10 d1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102f30:	68 62 79 10 f0       	push   $0xf0107962
f0102f35:	68 43 77 10 f0       	push   $0xf0107743
f0102f3a:	68 d9 04 00 00       	push   $0x4d9
f0102f3f:	68 1d 77 10 f0       	push   $0xf010771d
f0102f44:	e8 f7 d0 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102f49:	68 18 70 10 f0       	push   $0xf0107018
f0102f4e:	68 43 77 10 f0       	push   $0xf0107743
f0102f53:	68 dc 04 00 00       	push   $0x4dc
f0102f58:	68 1d 77 10 f0       	push   $0xf010771d
f0102f5d:	e8 de d0 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0102f62:	68 19 79 10 f0       	push   $0xf0107919
f0102f67:	68 43 77 10 f0       	push   $0xf0107743
f0102f6c:	68 de 04 00 00       	push   $0x4de
f0102f71:	68 1d 77 10 f0       	push   $0xf010771d
f0102f76:	e8 c5 d0 ff ff       	call   f0100040 <_panic>

f0102f7b <user_mem_check>:
{
f0102f7b:	f3 0f 1e fb          	endbr32 
f0102f7f:	55                   	push   %ebp
f0102f80:	89 e5                	mov    %esp,%ebp
f0102f82:	57                   	push   %edi
f0102f83:	56                   	push   %esi
f0102f84:	53                   	push   %ebx
f0102f85:	83 ec 2c             	sub    $0x2c,%esp
f0102f88:	8b 45 0c             	mov    0xc(%ebp),%eax
	pde_t* pgdir = env->env_pgdir;
f0102f8b:	8b 55 08             	mov    0x8(%ebp),%edx
f0102f8e:	8b 7a 60             	mov    0x60(%edx),%edi
	uintptr_t address = (uintptr_t)ROUNDDOWN(va,PGSIZE);
f0102f91:	89 c3                	mov    %eax,%ebx
f0102f93:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	perm = perm | PTE_U | PTE_P;
f0102f99:	8b 55 14             	mov    0x14(%ebp),%edx
f0102f9c:	83 ca 05             	or     $0x5,%edx
f0102f9f:	89 55 d0             	mov    %edx,-0x30(%ebp)
	pte_t* entry = NULL;
f0102fa2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	for(; address<(uintptr_t)ROUNDUP(va+len,PGSIZE);address+=PGSIZE)
f0102fa9:	03 45 10             	add    0x10(%ebp),%eax
f0102fac:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102fb1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102fb6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		if(page_lookup(pgdir,(void*)address,&entry) == NULL)
f0102fb9:	8d 75 e4             	lea    -0x1c(%ebp),%esi
	for(; address<(uintptr_t)ROUNDUP(va+len,PGSIZE);address+=PGSIZE)
f0102fbc:	eb 06                	jmp    f0102fc4 <user_mem_check+0x49>
f0102fbe:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102fc4:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0102fc7:	73 31                	jae    f0102ffa <user_mem_check+0x7f>
		if(address>=ULIM)
f0102fc9:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102fcf:	77 1c                	ja     f0102fed <user_mem_check+0x72>
		if(page_lookup(pgdir,(void*)address,&entry) == NULL)
f0102fd1:	83 ec 04             	sub    $0x4,%esp
f0102fd4:	56                   	push   %esi
f0102fd5:	53                   	push   %ebx
f0102fd6:	57                   	push   %edi
f0102fd7:	e8 b1 e1 ff ff       	call   f010118d <page_lookup>
f0102fdc:	83 c4 10             	add    $0x10,%esp
f0102fdf:	85 c0                	test   %eax,%eax
f0102fe1:	74 0a                	je     f0102fed <user_mem_check+0x72>
		if(!(*entry & perm))
f0102fe3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102fe6:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102fe9:	85 08                	test   %ecx,(%eax)
f0102feb:	75 d1                	jne    f0102fbe <user_mem_check+0x43>
		user_mem_check_addr = (address == (uintptr_t)va ? address : ROUNDDOWN(address,PGSIZE));
f0102fed:	89 1d 3c 72 21 f0    	mov    %ebx,0xf021723c
		return -E_FAULT;
f0102ff3:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102ff8:	eb 05                	jmp    f0102fff <user_mem_check+0x84>
	return 0;
f0102ffa:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102fff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103002:	5b                   	pop    %ebx
f0103003:	5e                   	pop    %esi
f0103004:	5f                   	pop    %edi
f0103005:	5d                   	pop    %ebp
f0103006:	c3                   	ret    

f0103007 <user_mem_assert>:
{
f0103007:	f3 0f 1e fb          	endbr32 
f010300b:	55                   	push   %ebp
f010300c:	89 e5                	mov    %esp,%ebp
f010300e:	53                   	push   %ebx
f010300f:	83 ec 04             	sub    $0x4,%esp
f0103012:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0103015:	8b 45 14             	mov    0x14(%ebp),%eax
f0103018:	83 c8 04             	or     $0x4,%eax
f010301b:	50                   	push   %eax
f010301c:	ff 75 10             	pushl  0x10(%ebp)
f010301f:	ff 75 0c             	pushl  0xc(%ebp)
f0103022:	53                   	push   %ebx
f0103023:	e8 53 ff ff ff       	call   f0102f7b <user_mem_check>
f0103028:	83 c4 10             	add    $0x10,%esp
f010302b:	85 c0                	test   %eax,%eax
f010302d:	78 05                	js     f0103034 <user_mem_assert+0x2d>
}
f010302f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103032:	c9                   	leave  
f0103033:	c3                   	ret    
		cprintf("[%08x] user_mem_check assertion failure for "
f0103034:	83 ec 04             	sub    $0x4,%esp
f0103037:	ff 35 3c 72 21 f0    	pushl  0xf021723c
f010303d:	ff 73 48             	pushl  0x48(%ebx)
f0103040:	68 e8 76 10 f0       	push   $0xf01076e8
f0103045:	e8 70 09 00 00       	call   f01039ba <cprintf>
		env_destroy(env);	// may not return
f010304a:	89 1c 24             	mov    %ebx,(%esp)
f010304d:	e8 43 06 00 00       	call   f0103695 <env_destroy>
f0103052:	83 c4 10             	add    $0x10,%esp
}
f0103055:	eb d8                	jmp    f010302f <user_mem_assert+0x28>

f0103057 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0103057:	55                   	push   %ebp
f0103058:	89 e5                	mov    %esp,%ebp
f010305a:	57                   	push   %edi
f010305b:	56                   	push   %esi
f010305c:	53                   	push   %ebx
f010305d:	83 ec 0c             	sub    $0xc,%esp
f0103060:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void* start = (void*)ROUNDDOWN((uint32_t)va,PGSIZE);
f0103062:	89 d3                	mov    %edx,%ebx
f0103064:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void* end = (void*)ROUNDUP((uint32_t)va+len,PGSIZE);
f010306a:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0103071:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

	// corner case 1: too large length
	if(start>end)
f0103077:	39 f3                	cmp    %esi,%ebx
f0103079:	77 30                	ja     f01030ab <region_alloc+0x54>
		panic("At region_alloc: too large length\n");
	}
	struct PageInfo* p = NULL;

	// allocate PA by the size of a page
	for(void* v = start;v<end;v+=PGSIZE)
f010307b:	39 f3                	cmp    %esi,%ebx
f010307d:	73 71                	jae    f01030f0 <region_alloc+0x99>
	{
		p = page_alloc(0);
f010307f:	83 ec 0c             	sub    $0xc,%esp
f0103082:	6a 00                	push   $0x0
f0103084:	e8 42 df ff ff       	call   f0100fcb <page_alloc>
		// corner case 2: page allocation failed
		if(p == NULL)
f0103089:	83 c4 10             	add    $0x10,%esp
f010308c:	85 c0                	test   %eax,%eax
f010308e:	74 32                	je     f01030c2 <region_alloc+0x6b>
		{
			panic("At region_alloc: Page allocation failed");
		}

		// insert into page table
		int insert = page_insert(e->env_pgdir,p,v,PTE_W|PTE_U);
f0103090:	6a 06                	push   $0x6
f0103092:	53                   	push   %ebx
f0103093:	50                   	push   %eax
f0103094:	ff 77 60             	pushl  0x60(%edi)
f0103097:	e8 e4 e1 ff ff       	call   f0101280 <page_insert>

		// corner case 3: insertion failed
		if(insert!=0)
f010309c:	83 c4 10             	add    $0x10,%esp
f010309f:	85 c0                	test   %eax,%eax
f01030a1:	75 36                	jne    f01030d9 <region_alloc+0x82>
	for(void* v = start;v<end;v+=PGSIZE)
f01030a3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01030a9:	eb d0                	jmp    f010307b <region_alloc+0x24>
		panic("At region_alloc: too large length\n");
f01030ab:	83 ec 04             	sub    $0x4,%esp
f01030ae:	68 30 7a 10 f0       	push   $0xf0107a30
f01030b3:	68 37 01 00 00       	push   $0x137
f01030b8:	68 25 7b 10 f0       	push   $0xf0107b25
f01030bd:	e8 7e cf ff ff       	call   f0100040 <_panic>
			panic("At region_alloc: Page allocation failed");
f01030c2:	83 ec 04             	sub    $0x4,%esp
f01030c5:	68 54 7a 10 f0       	push   $0xf0107a54
f01030ca:	68 42 01 00 00       	push   $0x142
f01030cf:	68 25 7b 10 f0       	push   $0xf0107b25
f01030d4:	e8 67 cf ff ff       	call   f0100040 <_panic>
		{
			panic("At region_alloc: Page insertion failed");
f01030d9:	83 ec 04             	sub    $0x4,%esp
f01030dc:	68 7c 7a 10 f0       	push   $0xf0107a7c
f01030e1:	68 4b 01 00 00       	push   $0x14b
f01030e6:	68 25 7b 10 f0       	push   $0xf0107b25
f01030eb:	e8 50 cf ff ff       	call   f0100040 <_panic>
		}
	}
}
f01030f0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030f3:	5b                   	pop    %ebx
f01030f4:	5e                   	pop    %esi
f01030f5:	5f                   	pop    %edi
f01030f6:	5d                   	pop    %ebp
f01030f7:	c3                   	ret    

f01030f8 <envid2env>:
{
f01030f8:	f3 0f 1e fb          	endbr32 
f01030fc:	55                   	push   %ebp
f01030fd:	89 e5                	mov    %esp,%ebp
f01030ff:	56                   	push   %esi
f0103100:	53                   	push   %ebx
f0103101:	8b 75 08             	mov    0x8(%ebp),%esi
f0103104:	8b 45 10             	mov    0x10(%ebp),%eax
	if (envid == 0) {
f0103107:	85 f6                	test   %esi,%esi
f0103109:	74 2e                	je     f0103139 <envid2env+0x41>
	e = &envs[ENVX(envid)];
f010310b:	89 f3                	mov    %esi,%ebx
f010310d:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0103113:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0103116:	03 1d 48 72 21 f0    	add    0xf0217248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f010311c:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0103120:	74 2e                	je     f0103150 <envid2env+0x58>
f0103122:	39 73 48             	cmp    %esi,0x48(%ebx)
f0103125:	75 29                	jne    f0103150 <envid2env+0x58>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103127:	84 c0                	test   %al,%al
f0103129:	75 35                	jne    f0103160 <envid2env+0x68>
	*env_store = e;
f010312b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010312e:	89 18                	mov    %ebx,(%eax)
	return 0;
f0103130:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103135:	5b                   	pop    %ebx
f0103136:	5e                   	pop    %esi
f0103137:	5d                   	pop    %ebp
f0103138:	c3                   	ret    
		*env_store = curenv;
f0103139:	e8 00 30 00 00       	call   f010613e <cpunum>
f010313e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103141:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0103147:	8b 55 0c             	mov    0xc(%ebp),%edx
f010314a:	89 02                	mov    %eax,(%edx)
		return 0;
f010314c:	89 f0                	mov    %esi,%eax
f010314e:	eb e5                	jmp    f0103135 <envid2env+0x3d>
		*env_store = 0;
f0103150:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103153:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103159:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010315e:	eb d5                	jmp    f0103135 <envid2env+0x3d>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103160:	e8 d9 2f 00 00       	call   f010613e <cpunum>
f0103165:	6b c0 74             	imul   $0x74,%eax,%eax
f0103168:	39 98 28 80 21 f0    	cmp    %ebx,-0xfde7fd8(%eax)
f010316e:	74 bb                	je     f010312b <envid2env+0x33>
f0103170:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0103173:	e8 c6 2f 00 00       	call   f010613e <cpunum>
f0103178:	6b c0 74             	imul   $0x74,%eax,%eax
f010317b:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0103181:	3b 70 48             	cmp    0x48(%eax),%esi
f0103184:	74 a5                	je     f010312b <envid2env+0x33>
		*env_store = 0;
f0103186:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103189:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010318f:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103194:	eb 9f                	jmp    f0103135 <envid2env+0x3d>

f0103196 <env_init_percpu>:
{
f0103196:	f3 0f 1e fb          	endbr32 
	asm volatile("lgdt (%0)" : : "r" (p));
f010319a:	b8 20 33 12 f0       	mov    $0xf0123320,%eax
f010319f:	0f 01 10             	lgdtl  (%eax)
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f01031a2:	b8 23 00 00 00       	mov    $0x23,%eax
f01031a7:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f01031a9:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f01031ab:	b8 10 00 00 00       	mov    $0x10,%eax
f01031b0:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f01031b2:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f01031b4:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f01031b6:	ea bd 31 10 f0 08 00 	ljmp   $0x8,$0xf01031bd
	asm volatile("lldt %0" : : "r" (sel));
f01031bd:	b8 00 00 00 00       	mov    $0x0,%eax
f01031c2:	0f 00 d0             	lldt   %ax
}
f01031c5:	c3                   	ret    

f01031c6 <env_init>:
{
f01031c6:	f3 0f 1e fb          	endbr32 
f01031ca:	55                   	push   %ebp
f01031cb:	89 e5                	mov    %esp,%ebp
f01031cd:	56                   	push   %esi
f01031ce:	53                   	push   %ebx
		envs[i].env_id = 0;
f01031cf:	8b 35 48 72 21 f0    	mov    0xf0217248,%esi
f01031d5:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f01031db:	89 f3                	mov    %esi,%ebx
f01031dd:	ba 00 00 00 00       	mov    $0x0,%edx
f01031e2:	89 d1                	mov    %edx,%ecx
f01031e4:	89 c2                	mov    %eax,%edx
f01031e6:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f01031ed:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f01031f4:	89 48 44             	mov    %ecx,0x44(%eax)
f01031f7:	83 e8 7c             	sub    $0x7c,%eax
	for(int i = NENV - 1; i>=0 ;i--)
f01031fa:	39 da                	cmp    %ebx,%edx
f01031fc:	75 e4                	jne    f01031e2 <env_init+0x1c>
f01031fe:	89 35 4c 72 21 f0    	mov    %esi,0xf021724c
	env_init_percpu();
f0103204:	e8 8d ff ff ff       	call   f0103196 <env_init_percpu>
}
f0103209:	5b                   	pop    %ebx
f010320a:	5e                   	pop    %esi
f010320b:	5d                   	pop    %ebp
f010320c:	c3                   	ret    

f010320d <env_alloc>:
{
f010320d:	f3 0f 1e fb          	endbr32 
f0103211:	55                   	push   %ebp
f0103212:	89 e5                	mov    %esp,%ebp
f0103214:	53                   	push   %ebx
f0103215:	83 ec 04             	sub    $0x4,%esp
	if (!(e = env_free_list))
f0103218:	8b 1d 4c 72 21 f0    	mov    0xf021724c,%ebx
f010321e:	85 db                	test   %ebx,%ebx
f0103220:	0f 84 59 01 00 00    	je     f010337f <env_alloc+0x172>
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103226:	83 ec 0c             	sub    $0xc,%esp
f0103229:	6a 01                	push   $0x1
f010322b:	e8 9b dd ff ff       	call   f0100fcb <page_alloc>
f0103230:	83 c4 10             	add    $0x10,%esp
f0103233:	85 c0                	test   %eax,%eax
f0103235:	0f 84 4b 01 00 00    	je     f0103386 <env_alloc+0x179>
	return (pp - pages) << PGSHIFT;
f010323b:	89 c2                	mov    %eax,%edx
f010323d:	2b 15 90 7e 21 f0    	sub    0xf0217e90,%edx
f0103243:	c1 fa 03             	sar    $0x3,%edx
f0103246:	89 d1                	mov    %edx,%ecx
f0103248:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f010324b:	81 e2 ff ff 0f 00    	and    $0xfffff,%edx
f0103251:	3b 15 88 7e 21 f0    	cmp    0xf0217e88,%edx
f0103257:	0f 83 fb 00 00 00    	jae    f0103358 <env_alloc+0x14b>
	return (void *)(pa + KERNBASE);
f010325d:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0103263:	89 4b 60             	mov    %ecx,0x60(%ebx)
	p->pp_ref++;
f0103266:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f010326b:	b8 00 00 00 00       	mov    $0x0,%eax
		e->env_pgdir[i] = 0;
f0103270:	8b 53 60             	mov    0x60(%ebx),%edx
f0103273:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f010327a:	83 c0 04             	add    $0x4,%eax
	for(int i = 0;i<PDX(UTOP);i++)
f010327d:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f0103282:	75 ec                	jne    f0103270 <env_alloc+0x63>
		e->env_pgdir[i] = kern_pgdir[i];
f0103284:	8b 15 8c 7e 21 f0    	mov    0xf0217e8c,%edx
f010328a:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f010328d:	8b 53 60             	mov    0x60(%ebx),%edx
f0103290:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0103293:	83 c0 04             	add    $0x4,%eax
	for(int i = PDX(UTOP);i<NENV;i++)
f0103296:	3d 00 10 00 00       	cmp    $0x1000,%eax
f010329b:	75 e7                	jne    f0103284 <env_alloc+0x77>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f010329d:	8b 43 60             	mov    0x60(%ebx),%eax
	if ((uint32_t)kva < KERNBASE)
f01032a0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01032a5:	0f 86 bf 00 00 00    	jbe    f010336a <env_alloc+0x15d>
	return (physaddr_t)kva - KERNBASE;
f01032ab:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01032b1:	83 ca 05             	or     $0x5,%edx
f01032b4:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01032ba:	8b 43 48             	mov    0x48(%ebx),%eax
f01032bd:	05 00 10 00 00       	add    $0x1000,%eax
		generation = 1 << ENVGENSHIFT;
f01032c2:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01032c7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01032cc:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01032cf:	89 da                	mov    %ebx,%edx
f01032d1:	2b 15 48 72 21 f0    	sub    0xf0217248,%edx
f01032d7:	c1 fa 02             	sar    $0x2,%edx
f01032da:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f01032e0:	09 d0                	or     %edx,%eax
f01032e2:	89 43 48             	mov    %eax,0x48(%ebx)
	e->env_parent_id = parent_id;
f01032e5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032e8:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01032eb:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01032f2:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01032f9:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103300:	83 ec 04             	sub    $0x4,%esp
f0103303:	6a 44                	push   $0x44
f0103305:	6a 00                	push   $0x0
f0103307:	53                   	push   %ebx
f0103308:	e8 13 28 00 00       	call   f0105b20 <memset>
	e->env_tf.tf_ds = GD_UD | 3;
f010330d:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103313:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103319:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f010331f:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103326:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	e->env_tf.tf_eflags |= FL_IF;
f010332c:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)
	e->env_pgfault_upcall = 0;
f0103333:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)
	e->env_ipc_recving = 0;
f010333a:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
	env_free_list = e->env_link;
f010333e:	8b 43 44             	mov    0x44(%ebx),%eax
f0103341:	a3 4c 72 21 f0       	mov    %eax,0xf021724c
	*newenv_store = e;
f0103346:	8b 45 08             	mov    0x8(%ebp),%eax
f0103349:	89 18                	mov    %ebx,(%eax)
	return 0;
f010334b:	83 c4 10             	add    $0x10,%esp
f010334e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103353:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103356:	c9                   	leave  
f0103357:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103358:	51                   	push   %ecx
f0103359:	68 e4 67 10 f0       	push   $0xf01067e4
f010335e:	6a 58                	push   $0x58
f0103360:	68 29 77 10 f0       	push   $0xf0107729
f0103365:	e8 d6 cc ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010336a:	50                   	push   %eax
f010336b:	68 08 68 10 f0       	push   $0xf0106808
f0103370:	68 d3 00 00 00       	push   $0xd3
f0103375:	68 25 7b 10 f0       	push   $0xf0107b25
f010337a:	e8 c1 cc ff ff       	call   f0100040 <_panic>
		return -E_NO_FREE_ENV;
f010337f:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103384:	eb cd                	jmp    f0103353 <env_alloc+0x146>
		return -E_NO_MEM;
f0103386:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010338b:	eb c6                	jmp    f0103353 <env_alloc+0x146>

f010338d <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010338d:	f3 0f 1e fb          	endbr32 
f0103391:	55                   	push   %ebp
f0103392:	89 e5                	mov    %esp,%ebp
f0103394:	57                   	push   %edi
f0103395:	56                   	push   %esi
f0103396:	53                   	push   %ebx
f0103397:	83 ec 34             	sub    $0x34,%esp
f010339a:	8b 75 08             	mov    0x8(%ebp),%esi
	// LAB 3: Your code here.
	struct Env* e;
	int alloc = env_alloc(&e,0);
f010339d:	6a 00                	push   $0x0
f010339f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01033a2:	50                   	push   %eax
f01033a3:	e8 65 fe ff ff       	call   f010320d <env_alloc>
	if(alloc != 0)
f01033a8:	83 c4 10             	add    $0x10,%esp
f01033ab:	85 c0                	test   %eax,%eax
f01033ad:	75 30                	jne    f01033df <env_create+0x52>
	{
		panic("At env_create: env_alloc() failed");
	}
	load_icode(e,binary);
f01033af:	8b 7d e4             	mov    -0x1c(%ebp),%edi
	if(elfHeader->e_magic != ELF_MAGIC)
f01033b2:	81 3e 7f 45 4c 46    	cmpl   $0x464c457f,(%esi)
f01033b8:	75 3c                	jne    f01033f6 <env_create+0x69>
	lcr3(PADDR(e->env_pgdir));
f01033ba:	8b 47 60             	mov    0x60(%edi),%eax
	if ((uint32_t)kva < KERNBASE)
f01033bd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033c2:	76 49                	jbe    f010340d <env_create+0x80>
	return (physaddr_t)kva - KERNBASE;
f01033c4:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01033c9:	0f 22 d8             	mov    %eax,%cr3
	struct Proghdr* ph = (struct Proghdr*)(binary+elfHeader->e_phoff);
f01033cc:	89 f3                	mov    %esi,%ebx
f01033ce:	03 5e 1c             	add    0x1c(%esi),%ebx
	struct Proghdr* phEnd = ph+elfHeader->e_phnum;
f01033d1:	0f b7 46 2c          	movzwl 0x2c(%esi),%eax
f01033d5:	c1 e0 05             	shl    $0x5,%eax
f01033d8:	01 d8                	add    %ebx,%eax
f01033da:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for(;ph<phEnd;ph++)
f01033dd:	eb 5d                	jmp    f010343c <env_create+0xaf>
		panic("At env_create: env_alloc() failed");
f01033df:	83 ec 04             	sub    $0x4,%esp
f01033e2:	68 a4 7a 10 f0       	push   $0xf0107aa4
f01033e7:	68 c5 01 00 00       	push   $0x1c5
f01033ec:	68 25 7b 10 f0       	push   $0xf0107b25
f01033f1:	e8 4a cc ff ff       	call   f0100040 <_panic>
		panic("At load_icode: Invalid head magic number");
f01033f6:	83 ec 04             	sub    $0x4,%esp
f01033f9:	68 c8 7a 10 f0       	push   $0xf0107ac8
f01033fe:	68 8c 01 00 00       	push   $0x18c
f0103403:	68 25 7b 10 f0       	push   $0xf0107b25
f0103408:	e8 33 cc ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010340d:	50                   	push   %eax
f010340e:	68 08 68 10 f0       	push   $0xf0106808
f0103413:	68 8f 01 00 00       	push   $0x18f
f0103418:	68 25 7b 10 f0       	push   $0xf0107b25
f010341d:	e8 1e cc ff ff       	call   f0100040 <_panic>
				panic("At load_icode: file size bigger than memory size");
f0103422:	83 ec 04             	sub    $0x4,%esp
f0103425:	68 f4 7a 10 f0       	push   $0xf0107af4
f010342a:	68 9b 01 00 00       	push   $0x19b
f010342f:	68 25 7b 10 f0       	push   $0xf0107b25
f0103434:	e8 07 cc ff ff       	call   f0100040 <_panic>
	for(;ph<phEnd;ph++)
f0103439:	83 c3 20             	add    $0x20,%ebx
f010343c:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010343f:	76 40                	jbe    f0103481 <env_create+0xf4>
		if(ph->p_type == ELF_PROG_LOAD)
f0103441:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103444:	75 f3                	jne    f0103439 <env_create+0xac>
			if(ph->p_filesz>ph->p_memsz)
f0103446:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103449:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f010344c:	77 d4                	ja     f0103422 <env_create+0x95>
			region_alloc(e,(void*) ph->p_va,ph->p_memsz);
f010344e:	8b 53 08             	mov    0x8(%ebx),%edx
f0103451:	89 f8                	mov    %edi,%eax
f0103453:	e8 ff fb ff ff       	call   f0103057 <region_alloc>
			memset((void*)(ph->p_va),0,ph->p_memsz);
f0103458:	83 ec 04             	sub    $0x4,%esp
f010345b:	ff 73 14             	pushl  0x14(%ebx)
f010345e:	6a 00                	push   $0x0
f0103460:	ff 73 08             	pushl  0x8(%ebx)
f0103463:	e8 b8 26 00 00       	call   f0105b20 <memset>
			memcpy((void*)ph->p_va,binary+ph->p_offset,ph->p_filesz); 
f0103468:	83 c4 0c             	add    $0xc,%esp
f010346b:	ff 73 10             	pushl  0x10(%ebx)
f010346e:	89 f0                	mov    %esi,%eax
f0103470:	03 43 04             	add    0x4(%ebx),%eax
f0103473:	50                   	push   %eax
f0103474:	ff 73 08             	pushl  0x8(%ebx)
f0103477:	e8 56 27 00 00       	call   f0105bd2 <memcpy>
f010347c:	83 c4 10             	add    $0x10,%esp
f010347f:	eb b8                	jmp    f0103439 <env_create+0xac>
	lcr3(PADDR(kern_pgdir));
f0103481:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0103486:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010348b:	76 3c                	jbe    f01034c9 <env_create+0x13c>
	return (physaddr_t)kva - KERNBASE;
f010348d:	05 00 00 00 10       	add    $0x10000000,%eax
f0103492:	0f 22 d8             	mov    %eax,%cr3
	e->env_status = ENV_RUNNABLE;
f0103495:	c7 47 54 02 00 00 00 	movl   $0x2,0x54(%edi)
	e->env_tf.tf_eip = elfHeader->e_entry;
f010349c:	8b 46 18             	mov    0x18(%esi),%eax
f010349f:	89 47 30             	mov    %eax,0x30(%edi)
	region_alloc(e,(void*)(USTACKTOP-PGSIZE),PGSIZE);
f01034a2:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01034a7:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01034ac:	89 f8                	mov    %edi,%eax
f01034ae:	e8 a4 fb ff ff       	call   f0103057 <region_alloc>
	
	// If this is the file server (type == ENV_TYPE_FS) give it I/O privileges.
	// LAB 5: Your code here.
	e->env_type = type;
f01034b3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01034b6:	8b 55 0c             	mov    0xc(%ebp),%edx
f01034b9:	89 50 50             	mov    %edx,0x50(%eax)
	if(type == ENV_TYPE_FS)
f01034bc:	83 fa 01             	cmp    $0x1,%edx
f01034bf:	74 1d                	je     f01034de <env_create+0x151>
	{
		e->env_tf.tf_eflags |= FL_IOPL_MASK;
	}
}
f01034c1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01034c4:	5b                   	pop    %ebx
f01034c5:	5e                   	pop    %esi
f01034c6:	5f                   	pop    %edi
f01034c7:	5d                   	pop    %ebp
f01034c8:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034c9:	50                   	push   %eax
f01034ca:	68 08 68 10 f0       	push   $0xf0106808
f01034cf:	68 a9 01 00 00       	push   $0x1a9
f01034d4:	68 25 7b 10 f0       	push   $0xf0107b25
f01034d9:	e8 62 cb ff ff       	call   f0100040 <_panic>
		e->env_tf.tf_eflags |= FL_IOPL_MASK;
f01034de:	81 48 38 00 30 00 00 	orl    $0x3000,0x38(%eax)
}
f01034e5:	eb da                	jmp    f01034c1 <env_create+0x134>

f01034e7 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01034e7:	f3 0f 1e fb          	endbr32 
f01034eb:	55                   	push   %ebp
f01034ec:	89 e5                	mov    %esp,%ebp
f01034ee:	57                   	push   %edi
f01034ef:	56                   	push   %esi
f01034f0:	53                   	push   %ebx
f01034f1:	83 ec 1c             	sub    $0x1c,%esp
f01034f4:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01034f7:	e8 42 2c 00 00       	call   f010613e <cpunum>
f01034fc:	6b c0 74             	imul   $0x74,%eax,%eax
f01034ff:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103506:	39 b8 28 80 21 f0    	cmp    %edi,-0xfde7fd8(%eax)
f010350c:	0f 85 b3 00 00 00    	jne    f01035c5 <env_free+0xde>
		lcr3(PADDR(kern_pgdir));
f0103512:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0103517:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010351c:	76 14                	jbe    f0103532 <env_free+0x4b>
	return (physaddr_t)kva - KERNBASE;
f010351e:	05 00 00 00 10       	add    $0x10000000,%eax
f0103523:	0f 22 d8             	mov    %eax,%cr3
}
f0103526:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010352d:	e9 93 00 00 00       	jmp    f01035c5 <env_free+0xde>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103532:	50                   	push   %eax
f0103533:	68 08 68 10 f0       	push   $0xf0106808
f0103538:	68 e0 01 00 00       	push   $0x1e0
f010353d:	68 25 7b 10 f0       	push   $0xf0107b25
f0103542:	e8 f9 ca ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103547:	56                   	push   %esi
f0103548:	68 e4 67 10 f0       	push   $0xf01067e4
f010354d:	68 ef 01 00 00       	push   $0x1ef
f0103552:	68 25 7b 10 f0       	push   $0xf0107b25
f0103557:	e8 e4 ca ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010355c:	83 ec 08             	sub    $0x8,%esp
f010355f:	89 d8                	mov    %ebx,%eax
f0103561:	c1 e0 0c             	shl    $0xc,%eax
f0103564:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103567:	50                   	push   %eax
f0103568:	ff 77 60             	pushl  0x60(%edi)
f010356b:	e8 bf dc ff ff       	call   f010122f <page_remove>
f0103570:	83 c4 10             	add    $0x10,%esp
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103573:	83 c3 01             	add    $0x1,%ebx
f0103576:	83 c6 04             	add    $0x4,%esi
f0103579:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f010357f:	74 07                	je     f0103588 <env_free+0xa1>
			if (pt[pteno] & PTE_P)
f0103581:	f6 06 01             	testb  $0x1,(%esi)
f0103584:	74 ed                	je     f0103573 <env_free+0x8c>
f0103586:	eb d4                	jmp    f010355c <env_free+0x75>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103588:	8b 47 60             	mov    0x60(%edi),%eax
f010358b:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010358e:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f0103595:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103598:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f010359e:	73 65                	jae    f0103605 <env_free+0x11e>
		page_decref(pa2page(pa));
f01035a0:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01035a3:	a1 90 7e 21 f0       	mov    0xf0217e90,%eax
f01035a8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01035ab:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01035ae:	50                   	push   %eax
f01035af:	e8 cf da ff ff       	call   f0101083 <page_decref>
f01035b4:	83 c4 10             	add    $0x10,%esp
f01035b7:	83 45 e0 04          	addl   $0x4,-0x20(%ebp)
f01035bb:	8b 45 e0             	mov    -0x20(%ebp),%eax
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01035be:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f01035c3:	74 54                	je     f0103619 <env_free+0x132>
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01035c5:	8b 47 60             	mov    0x60(%edi),%eax
f01035c8:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01035cb:	8b 04 10             	mov    (%eax,%edx,1),%eax
f01035ce:	a8 01                	test   $0x1,%al
f01035d0:	74 e5                	je     f01035b7 <env_free+0xd0>
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01035d2:	89 c6                	mov    %eax,%esi
f01035d4:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	if (PGNUM(pa) >= npages)
f01035da:	c1 e8 0c             	shr    $0xc,%eax
f01035dd:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01035e0:	39 05 88 7e 21 f0    	cmp    %eax,0xf0217e88
f01035e6:	0f 86 5b ff ff ff    	jbe    f0103547 <env_free+0x60>
	return (void *)(pa + KERNBASE);
f01035ec:	81 ee 00 00 00 10    	sub    $0x10000000,%esi
f01035f2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01035f5:	c1 e0 14             	shl    $0x14,%eax
f01035f8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01035fb:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103600:	e9 7c ff ff ff       	jmp    f0103581 <env_free+0x9a>
		panic("pa2page called with invalid pa");
f0103605:	83 ec 04             	sub    $0x4,%esp
f0103608:	68 bc 6e 10 f0       	push   $0xf0106ebc
f010360d:	6a 51                	push   $0x51
f010360f:	68 29 77 10 f0       	push   $0xf0107729
f0103614:	e8 27 ca ff ff       	call   f0100040 <_panic>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103619:	8b 47 60             	mov    0x60(%edi),%eax
	if ((uint32_t)kva < KERNBASE)
f010361c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103621:	76 49                	jbe    f010366c <env_free+0x185>
	e->env_pgdir = 0;
f0103623:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f010362a:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f010362f:	c1 e8 0c             	shr    $0xc,%eax
f0103632:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0103638:	73 47                	jae    f0103681 <env_free+0x19a>
	page_decref(pa2page(pa));
f010363a:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f010363d:	8b 15 90 7e 21 f0    	mov    0xf0217e90,%edx
f0103643:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103646:	50                   	push   %eax
f0103647:	e8 37 da ff ff       	call   f0101083 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f010364c:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103653:	a1 4c 72 21 f0       	mov    0xf021724c,%eax
f0103658:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f010365b:	89 3d 4c 72 21 f0    	mov    %edi,0xf021724c
}
f0103661:	83 c4 10             	add    $0x10,%esp
f0103664:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103667:	5b                   	pop    %ebx
f0103668:	5e                   	pop    %esi
f0103669:	5f                   	pop    %edi
f010366a:	5d                   	pop    %ebp
f010366b:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010366c:	50                   	push   %eax
f010366d:	68 08 68 10 f0       	push   $0xf0106808
f0103672:	68 fd 01 00 00       	push   $0x1fd
f0103677:	68 25 7b 10 f0       	push   $0xf0107b25
f010367c:	e8 bf c9 ff ff       	call   f0100040 <_panic>
		panic("pa2page called with invalid pa");
f0103681:	83 ec 04             	sub    $0x4,%esp
f0103684:	68 bc 6e 10 f0       	push   $0xf0106ebc
f0103689:	6a 51                	push   $0x51
f010368b:	68 29 77 10 f0       	push   $0xf0107729
f0103690:	e8 ab c9 ff ff       	call   f0100040 <_panic>

f0103695 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103695:	f3 0f 1e fb          	endbr32 
f0103699:	55                   	push   %ebp
f010369a:	89 e5                	mov    %esp,%ebp
f010369c:	53                   	push   %ebx
f010369d:	83 ec 04             	sub    $0x4,%esp
f01036a0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01036a3:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f01036a7:	74 21                	je     f01036ca <env_destroy+0x35>
		e->env_status = ENV_DYING;
		return;
	}

	env_free(e);
f01036a9:	83 ec 0c             	sub    $0xc,%esp
f01036ac:	53                   	push   %ebx
f01036ad:	e8 35 fe ff ff       	call   f01034e7 <env_free>

	if (curenv == e) {
f01036b2:	e8 87 2a 00 00       	call   f010613e <cpunum>
f01036b7:	6b c0 74             	imul   $0x74,%eax,%eax
f01036ba:	83 c4 10             	add    $0x10,%esp
f01036bd:	39 98 28 80 21 f0    	cmp    %ebx,-0xfde7fd8(%eax)
f01036c3:	74 1e                	je     f01036e3 <env_destroy+0x4e>
		curenv = NULL;
		sched_yield();
	}
}
f01036c5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01036c8:	c9                   	leave  
f01036c9:	c3                   	ret    
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01036ca:	e8 6f 2a 00 00       	call   f010613e <cpunum>
f01036cf:	6b c0 74             	imul   $0x74,%eax,%eax
f01036d2:	39 98 28 80 21 f0    	cmp    %ebx,-0xfde7fd8(%eax)
f01036d8:	74 cf                	je     f01036a9 <env_destroy+0x14>
		e->env_status = ENV_DYING;
f01036da:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01036e1:	eb e2                	jmp    f01036c5 <env_destroy+0x30>
		curenv = NULL;
f01036e3:	e8 56 2a 00 00       	call   f010613e <cpunum>
f01036e8:	6b c0 74             	imul   $0x74,%eax,%eax
f01036eb:	c7 80 28 80 21 f0 00 	movl   $0x0,-0xfde7fd8(%eax)
f01036f2:	00 00 00 
		sched_yield();
f01036f5:	e8 63 11 00 00       	call   f010485d <sched_yield>

f01036fa <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01036fa:	f3 0f 1e fb          	endbr32 
f01036fe:	55                   	push   %ebp
f01036ff:	89 e5                	mov    %esp,%ebp
f0103701:	53                   	push   %ebx
f0103702:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103705:	e8 34 2a 00 00       	call   f010613e <cpunum>
f010370a:	6b c0 74             	imul   $0x74,%eax,%eax
f010370d:	8b 98 28 80 21 f0    	mov    -0xfde7fd8(%eax),%ebx
f0103713:	e8 26 2a 00 00       	call   f010613e <cpunum>
f0103718:	89 43 5c             	mov    %eax,0x5c(%ebx)
	asm volatile(
f010371b:	8b 65 08             	mov    0x8(%ebp),%esp
f010371e:	61                   	popa   
f010371f:	07                   	pop    %es
f0103720:	1f                   	pop    %ds
f0103721:	83 c4 08             	add    $0x8,%esp
f0103724:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103725:	83 ec 04             	sub    $0x4,%esp
f0103728:	68 30 7b 10 f0       	push   $0xf0107b30
f010372d:	68 2f 02 00 00       	push   $0x22f
f0103732:	68 25 7b 10 f0       	push   $0xf0107b25
f0103737:	e8 04 c9 ff ff       	call   f0100040 <_panic>

f010373c <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010373c:	f3 0f 1e fb          	endbr32 
f0103740:	55                   	push   %ebp
f0103741:	89 e5                	mov    %esp,%ebp
f0103743:	83 ec 08             	sub    $0x8,%esp
	
	// panic("env_run not yet implemented");

	// step 1
	// set the env_status field
	if(curenv)
f0103746:	e8 f3 29 00 00       	call   f010613e <cpunum>
f010374b:	6b c0 74             	imul   $0x74,%eax,%eax
f010374e:	83 b8 28 80 21 f0 00 	cmpl   $0x0,-0xfde7fd8(%eax)
f0103755:	74 14                	je     f010376b <env_run+0x2f>
	{
		if(curenv->env_status == ENV_RUNNING)
f0103757:	e8 e2 29 00 00       	call   f010613e <cpunum>
f010375c:	6b c0 74             	imul   $0x74,%eax,%eax
f010375f:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0103765:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103769:	74 7d                	je     f01037e8 <env_run+0xac>
			curenv->env_status = ENV_RUNNABLE;
		}
	}

	// switch to new environment
	curenv = e;
f010376b:	e8 ce 29 00 00       	call   f010613e <cpunum>
f0103770:	6b c0 74             	imul   $0x74,%eax,%eax
f0103773:	8b 55 08             	mov    0x8(%ebp),%edx
f0103776:	89 90 28 80 21 f0    	mov    %edx,-0xfde7fd8(%eax)
	curenv->env_status = ENV_RUNNING;
f010377c:	e8 bd 29 00 00       	call   f010613e <cpunum>
f0103781:	6b c0 74             	imul   $0x74,%eax,%eax
f0103784:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f010378a:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0103791:	e8 a8 29 00 00       	call   f010613e <cpunum>
f0103796:	6b c0 74             	imul   $0x74,%eax,%eax
f0103799:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f010379f:	83 40 58 01          	addl   $0x1,0x58(%eax)
	// switch to user page directory
	lcr3(PADDR(curenv->env_pgdir));
f01037a3:	e8 96 29 00 00       	call   f010613e <cpunum>
f01037a8:	6b c0 74             	imul   $0x74,%eax,%eax
f01037ab:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01037b1:	8b 40 60             	mov    0x60(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01037b4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01037b9:	76 47                	jbe    f0103802 <env_run+0xc6>
	return (physaddr_t)kva - KERNBASE;
f01037bb:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01037c0:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01037c3:	83 ec 0c             	sub    $0xc,%esp
f01037c6:	68 c0 33 12 f0       	push   $0xf01233c0
f01037cb:	e8 94 2c 00 00       	call   f0106464 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01037d0:	f3 90                	pause  
	unlock_kernel();
	// step 2
	env_pop_tf(&curenv->env_tf);
f01037d2:	e8 67 29 00 00       	call   f010613e <cpunum>
f01037d7:	83 c4 04             	add    $0x4,%esp
f01037da:	6b c0 74             	imul   $0x74,%eax,%eax
f01037dd:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f01037e3:	e8 12 ff ff ff       	call   f01036fa <env_pop_tf>
			curenv->env_status = ENV_RUNNABLE;
f01037e8:	e8 51 29 00 00       	call   f010613e <cpunum>
f01037ed:	6b c0 74             	imul   $0x74,%eax,%eax
f01037f0:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01037f6:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
f01037fd:	e9 69 ff ff ff       	jmp    f010376b <env_run+0x2f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103802:	50                   	push   %eax
f0103803:	68 08 68 10 f0       	push   $0xf0106808
f0103808:	68 5f 02 00 00       	push   $0x25f
f010380d:	68 25 7b 10 f0       	push   $0xf0107b25
f0103812:	e8 29 c8 ff ff       	call   f0100040 <_panic>

f0103817 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103817:	f3 0f 1e fb          	endbr32 
f010381b:	55                   	push   %ebp
f010381c:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010381e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103821:	ba 70 00 00 00       	mov    $0x70,%edx
f0103826:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103827:	ba 71 00 00 00       	mov    $0x71,%edx
f010382c:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010382d:	0f b6 c0             	movzbl %al,%eax
}
f0103830:	5d                   	pop    %ebp
f0103831:	c3                   	ret    

f0103832 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103832:	f3 0f 1e fb          	endbr32 
f0103836:	55                   	push   %ebp
f0103837:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103839:	8b 45 08             	mov    0x8(%ebp),%eax
f010383c:	ba 70 00 00 00       	mov    $0x70,%edx
f0103841:	ee                   	out    %al,(%dx)
f0103842:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103845:	ba 71 00 00 00       	mov    $0x71,%edx
f010384a:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010384b:	5d                   	pop    %ebp
f010384c:	c3                   	ret    

f010384d <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f010384d:	f3 0f 1e fb          	endbr32 
f0103851:	55                   	push   %ebp
f0103852:	89 e5                	mov    %esp,%ebp
f0103854:	56                   	push   %esi
f0103855:	53                   	push   %ebx
f0103856:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103859:	66 a3 a8 33 12 f0    	mov    %ax,0xf01233a8
	if (!didinit)
f010385f:	80 3d 50 72 21 f0 00 	cmpb   $0x0,0xf0217250
f0103866:	75 07                	jne    f010386f <irq_setmask_8259A+0x22>
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
}
f0103868:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010386b:	5b                   	pop    %ebx
f010386c:	5e                   	pop    %esi
f010386d:	5d                   	pop    %ebp
f010386e:	c3                   	ret    
f010386f:	89 c6                	mov    %eax,%esi
f0103871:	ba 21 00 00 00       	mov    $0x21,%edx
f0103876:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
f0103877:	66 c1 e8 08          	shr    $0x8,%ax
f010387b:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103880:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0103881:	83 ec 0c             	sub    $0xc,%esp
f0103884:	68 3c 7b 10 f0       	push   $0xf0107b3c
f0103889:	e8 2c 01 00 00       	call   f01039ba <cprintf>
f010388e:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0103891:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103896:	0f b7 f6             	movzwl %si,%esi
f0103899:	f7 d6                	not    %esi
f010389b:	eb 19                	jmp    f01038b6 <irq_setmask_8259A+0x69>
			cprintf(" %d", i);
f010389d:	83 ec 08             	sub    $0x8,%esp
f01038a0:	53                   	push   %ebx
f01038a1:	68 cf 80 10 f0       	push   $0xf01080cf
f01038a6:	e8 0f 01 00 00       	call   f01039ba <cprintf>
f01038ab:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f01038ae:	83 c3 01             	add    $0x1,%ebx
f01038b1:	83 fb 10             	cmp    $0x10,%ebx
f01038b4:	74 07                	je     f01038bd <irq_setmask_8259A+0x70>
		if (~mask & (1<<i))
f01038b6:	0f a3 de             	bt     %ebx,%esi
f01038b9:	73 f3                	jae    f01038ae <irq_setmask_8259A+0x61>
f01038bb:	eb e0                	jmp    f010389d <irq_setmask_8259A+0x50>
	cprintf("\n");
f01038bd:	83 ec 0c             	sub    $0xc,%esp
f01038c0:	68 fd 79 10 f0       	push   $0xf01079fd
f01038c5:	e8 f0 00 00 00       	call   f01039ba <cprintf>
f01038ca:	83 c4 10             	add    $0x10,%esp
f01038cd:	eb 99                	jmp    f0103868 <irq_setmask_8259A+0x1b>

f01038cf <pic_init>:
{
f01038cf:	f3 0f 1e fb          	endbr32 
f01038d3:	55                   	push   %ebp
f01038d4:	89 e5                	mov    %esp,%ebp
f01038d6:	57                   	push   %edi
f01038d7:	56                   	push   %esi
f01038d8:	53                   	push   %ebx
f01038d9:	83 ec 0c             	sub    $0xc,%esp
	didinit = 1;
f01038dc:	c6 05 50 72 21 f0 01 	movb   $0x1,0xf0217250
f01038e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01038e8:	bb 21 00 00 00       	mov    $0x21,%ebx
f01038ed:	89 da                	mov    %ebx,%edx
f01038ef:	ee                   	out    %al,(%dx)
f01038f0:	b9 a1 00 00 00       	mov    $0xa1,%ecx
f01038f5:	89 ca                	mov    %ecx,%edx
f01038f7:	ee                   	out    %al,(%dx)
f01038f8:	bf 11 00 00 00       	mov    $0x11,%edi
f01038fd:	be 20 00 00 00       	mov    $0x20,%esi
f0103902:	89 f8                	mov    %edi,%eax
f0103904:	89 f2                	mov    %esi,%edx
f0103906:	ee                   	out    %al,(%dx)
f0103907:	b8 20 00 00 00       	mov    $0x20,%eax
f010390c:	89 da                	mov    %ebx,%edx
f010390e:	ee                   	out    %al,(%dx)
f010390f:	b8 04 00 00 00       	mov    $0x4,%eax
f0103914:	ee                   	out    %al,(%dx)
f0103915:	b8 03 00 00 00       	mov    $0x3,%eax
f010391a:	ee                   	out    %al,(%dx)
f010391b:	bb a0 00 00 00       	mov    $0xa0,%ebx
f0103920:	89 f8                	mov    %edi,%eax
f0103922:	89 da                	mov    %ebx,%edx
f0103924:	ee                   	out    %al,(%dx)
f0103925:	b8 28 00 00 00       	mov    $0x28,%eax
f010392a:	89 ca                	mov    %ecx,%edx
f010392c:	ee                   	out    %al,(%dx)
f010392d:	b8 02 00 00 00       	mov    $0x2,%eax
f0103932:	ee                   	out    %al,(%dx)
f0103933:	b8 01 00 00 00       	mov    $0x1,%eax
f0103938:	ee                   	out    %al,(%dx)
f0103939:	bf 68 00 00 00       	mov    $0x68,%edi
f010393e:	89 f8                	mov    %edi,%eax
f0103940:	89 f2                	mov    %esi,%edx
f0103942:	ee                   	out    %al,(%dx)
f0103943:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103948:	89 c8                	mov    %ecx,%eax
f010394a:	ee                   	out    %al,(%dx)
f010394b:	89 f8                	mov    %edi,%eax
f010394d:	89 da                	mov    %ebx,%edx
f010394f:	ee                   	out    %al,(%dx)
f0103950:	89 c8                	mov    %ecx,%eax
f0103952:	ee                   	out    %al,(%dx)
	if (irq_mask_8259A != 0xFFFF)
f0103953:	0f b7 05 a8 33 12 f0 	movzwl 0xf01233a8,%eax
f010395a:	66 83 f8 ff          	cmp    $0xffff,%ax
f010395e:	75 08                	jne    f0103968 <pic_init+0x99>
}
f0103960:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103963:	5b                   	pop    %ebx
f0103964:	5e                   	pop    %esi
f0103965:	5f                   	pop    %edi
f0103966:	5d                   	pop    %ebp
f0103967:	c3                   	ret    
		irq_setmask_8259A(irq_mask_8259A);
f0103968:	83 ec 0c             	sub    $0xc,%esp
f010396b:	0f b7 c0             	movzwl %ax,%eax
f010396e:	50                   	push   %eax
f010396f:	e8 d9 fe ff ff       	call   f010384d <irq_setmask_8259A>
f0103974:	83 c4 10             	add    $0x10,%esp
}
f0103977:	eb e7                	jmp    f0103960 <pic_init+0x91>

f0103979 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103979:	f3 0f 1e fb          	endbr32 
f010397d:	55                   	push   %ebp
f010397e:	89 e5                	mov    %esp,%ebp
f0103980:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103983:	ff 75 08             	pushl  0x8(%ebp)
f0103986:	e8 33 ce ff ff       	call   f01007be <cputchar>
	*cnt++;
}
f010398b:	83 c4 10             	add    $0x10,%esp
f010398e:	c9                   	leave  
f010398f:	c3                   	ret    

f0103990 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103990:	f3 0f 1e fb          	endbr32 
f0103994:	55                   	push   %ebp
f0103995:	89 e5                	mov    %esp,%ebp
f0103997:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010399a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01039a1:	ff 75 0c             	pushl  0xc(%ebp)
f01039a4:	ff 75 08             	pushl  0x8(%ebp)
f01039a7:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01039aa:	50                   	push   %eax
f01039ab:	68 79 39 10 f0       	push   $0xf0103979
f01039b0:	e8 08 1a 00 00       	call   f01053bd <vprintfmt>
	return cnt;
}
f01039b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01039b8:	c9                   	leave  
f01039b9:	c3                   	ret    

f01039ba <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01039ba:	f3 0f 1e fb          	endbr32 
f01039be:	55                   	push   %ebp
f01039bf:	89 e5                	mov    %esp,%ebp
f01039c1:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01039c4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01039c7:	50                   	push   %eax
f01039c8:	ff 75 08             	pushl  0x8(%ebp)
f01039cb:	e8 c0 ff ff ff       	call   f0103990 <vcprintf>
	va_end(ap);

	return cnt;
}
f01039d0:	c9                   	leave  
f01039d1:	c3                   	ret    

f01039d2 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01039d2:	f3 0f 1e fb          	endbr32 
f01039d6:	55                   	push   %ebp
f01039d7:	89 e5                	mov    %esp,%ebp
f01039d9:	57                   	push   %edi
f01039da:	56                   	push   %esi
f01039db:	53                   	push   %ebx
f01039dc:	83 ec 1c             	sub    $0x1c,%esp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	uint8_t id = thiscpu->cpu_id;
f01039df:	e8 5a 27 00 00       	call   f010613e <cpunum>
f01039e4:	6b c0 74             	imul   $0x74,%eax,%eax
f01039e7:	0f b6 b8 20 80 21 f0 	movzbl -0xfde7fe0(%eax),%edi
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP-id*(KSTKSIZE+KSTKGAP);
f01039ee:	89 f8                	mov    %edi,%eax
f01039f0:	0f b6 d8             	movzbl %al,%ebx
f01039f3:	e8 46 27 00 00       	call   f010613e <cpunum>
f01039f8:	6b c0 74             	imul   $0x74,%eax,%eax
f01039fb:	89 d9                	mov    %ebx,%ecx
f01039fd:	c1 e1 10             	shl    $0x10,%ecx
f0103a00:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0103a05:	29 ca                	sub    %ecx,%edx
f0103a07:	89 90 30 80 21 f0    	mov    %edx,-0xfde7fd0(%eax)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f0103a0d:	e8 2c 27 00 00       	call   f010613e <cpunum>
f0103a12:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a15:	66 c7 80 34 80 21 f0 	movw   $0x10,-0xfde7fcc(%eax)
f0103a1c:	10 00 
	thiscpu->cpu_ts.ts_iomb = sizeof(struct Taskstate);
f0103a1e:	e8 1b 27 00 00       	call   f010613e <cpunum>
f0103a23:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a26:	66 c7 80 92 80 21 f0 	movw   $0x68,-0xfde7f6e(%eax)
f0103a2d:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+id] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
f0103a2f:	83 c3 05             	add    $0x5,%ebx
f0103a32:	e8 07 27 00 00       	call   f010613e <cpunum>
f0103a37:	89 c6                	mov    %eax,%esi
f0103a39:	e8 00 27 00 00       	call   f010613e <cpunum>
f0103a3e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103a41:	e8 f8 26 00 00       	call   f010613e <cpunum>
f0103a46:	66 c7 04 dd 40 33 12 	movw   $0x67,-0xfedccc0(,%ebx,8)
f0103a4d:	f0 67 00 
f0103a50:	6b f6 74             	imul   $0x74,%esi,%esi
f0103a53:	81 c6 2c 80 21 f0    	add    $0xf021802c,%esi
f0103a59:	66 89 34 dd 42 33 12 	mov    %si,-0xfedccbe(,%ebx,8)
f0103a60:	f0 
f0103a61:	6b 55 e4 74          	imul   $0x74,-0x1c(%ebp),%edx
f0103a65:	81 c2 2c 80 21 f0    	add    $0xf021802c,%edx
f0103a6b:	c1 ea 10             	shr    $0x10,%edx
f0103a6e:	88 14 dd 44 33 12 f0 	mov    %dl,-0xfedccbc(,%ebx,8)
f0103a75:	c6 04 dd 46 33 12 f0 	movb   $0x40,-0xfedccba(,%ebx,8)
f0103a7c:	40 
f0103a7d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a80:	05 2c 80 21 f0       	add    $0xf021802c,%eax
f0103a85:	c1 e8 18             	shr    $0x18,%eax
f0103a88:	88 04 dd 47 33 12 f0 	mov    %al,-0xfedccb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3)+id].sd_s = 0;
f0103a8f:	c6 04 dd 45 33 12 f0 	movb   $0x89,-0xfedccbb(,%ebx,8)
f0103a96:	89 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0+(id<<3));
f0103a97:	89 f8                	mov    %edi,%eax
f0103a99:	0f b6 f8             	movzbl %al,%edi
f0103a9c:	8d 3c fd 28 00 00 00 	lea    0x28(,%edi,8),%edi
	asm volatile("ltr %0" : : "r" (sel));
f0103aa3:	0f 00 df             	ltr    %di
	asm volatile("lidt (%0)" : : "r" (p));
f0103aa6:	b8 ac 33 12 f0       	mov    $0xf01233ac,%eax
f0103aab:	0f 01 18             	lidtl  (%eax)

	// Load the IDT
	lidt(&idt_pd);
}
f0103aae:	83 c4 1c             	add    $0x1c,%esp
f0103ab1:	5b                   	pop    %ebx
f0103ab2:	5e                   	pop    %esi
f0103ab3:	5f                   	pop    %edi
f0103ab4:	5d                   	pop    %ebp
f0103ab5:	c3                   	ret    

f0103ab6 <trap_init>:
{
f0103ab6:	f3 0f 1e fb          	endbr32 
f0103aba:	55                   	push   %ebp
f0103abb:	89 e5                	mov    %esp,%ebp
f0103abd:	83 ec 08             	sub    $0x8,%esp
    SETGATE(idt[T_DIVIDE], 0, GD_KT, DIVIDE, 0);
f0103ac0:	b8 6a 46 10 f0       	mov    $0xf010466a,%eax
f0103ac5:	66 a3 60 72 21 f0    	mov    %ax,0xf0217260
f0103acb:	66 c7 05 62 72 21 f0 	movw   $0x8,0xf0217262
f0103ad2:	08 00 
f0103ad4:	c6 05 64 72 21 f0 00 	movb   $0x0,0xf0217264
f0103adb:	c6 05 65 72 21 f0 8e 	movb   $0x8e,0xf0217265
f0103ae2:	c1 e8 10             	shr    $0x10,%eax
f0103ae5:	66 a3 66 72 21 f0    	mov    %ax,0xf0217266
	SETGATE(idt[T_DEBUG], 0, GD_KT, DEBUG, 0);
f0103aeb:	b8 74 46 10 f0       	mov    $0xf0104674,%eax
f0103af0:	66 a3 68 72 21 f0    	mov    %ax,0xf0217268
f0103af6:	66 c7 05 6a 72 21 f0 	movw   $0x8,0xf021726a
f0103afd:	08 00 
f0103aff:	c6 05 6c 72 21 f0 00 	movb   $0x0,0xf021726c
f0103b06:	c6 05 6d 72 21 f0 8e 	movb   $0x8e,0xf021726d
f0103b0d:	c1 e8 10             	shr    $0x10,%eax
f0103b10:	66 a3 6e 72 21 f0    	mov    %ax,0xf021726e
	SETGATE(idt[T_NMI], 0, GD_KT, NMI, 0);
f0103b16:	b8 7e 46 10 f0       	mov    $0xf010467e,%eax
f0103b1b:	66 a3 70 72 21 f0    	mov    %ax,0xf0217270
f0103b21:	66 c7 05 72 72 21 f0 	movw   $0x8,0xf0217272
f0103b28:	08 00 
f0103b2a:	c6 05 74 72 21 f0 00 	movb   $0x0,0xf0217274
f0103b31:	c6 05 75 72 21 f0 8e 	movb   $0x8e,0xf0217275
f0103b38:	c1 e8 10             	shr    $0x10,%eax
f0103b3b:	66 a3 76 72 21 f0    	mov    %ax,0xf0217276
	SETGATE(idt[T_BRKPT], 0, GD_KT, BRKPT, 3);
f0103b41:	b8 88 46 10 f0       	mov    $0xf0104688,%eax
f0103b46:	66 a3 78 72 21 f0    	mov    %ax,0xf0217278
f0103b4c:	66 c7 05 7a 72 21 f0 	movw   $0x8,0xf021727a
f0103b53:	08 00 
f0103b55:	c6 05 7c 72 21 f0 00 	movb   $0x0,0xf021727c
f0103b5c:	c6 05 7d 72 21 f0 ee 	movb   $0xee,0xf021727d
f0103b63:	c1 e8 10             	shr    $0x10,%eax
f0103b66:	66 a3 7e 72 21 f0    	mov    %ax,0xf021727e
	SETGATE(idt[T_OFLOW], 0, GD_KT, OFLOW, 0);
f0103b6c:	b8 92 46 10 f0       	mov    $0xf0104692,%eax
f0103b71:	66 a3 80 72 21 f0    	mov    %ax,0xf0217280
f0103b77:	66 c7 05 82 72 21 f0 	movw   $0x8,0xf0217282
f0103b7e:	08 00 
f0103b80:	c6 05 84 72 21 f0 00 	movb   $0x0,0xf0217284
f0103b87:	c6 05 85 72 21 f0 8e 	movb   $0x8e,0xf0217285
f0103b8e:	c1 e8 10             	shr    $0x10,%eax
f0103b91:	66 a3 86 72 21 f0    	mov    %ax,0xf0217286
	SETGATE(idt[T_BOUND], 0, GD_KT, BOUND, 0);
f0103b97:	b8 9c 46 10 f0       	mov    $0xf010469c,%eax
f0103b9c:	66 a3 88 72 21 f0    	mov    %ax,0xf0217288
f0103ba2:	66 c7 05 8a 72 21 f0 	movw   $0x8,0xf021728a
f0103ba9:	08 00 
f0103bab:	c6 05 8c 72 21 f0 00 	movb   $0x0,0xf021728c
f0103bb2:	c6 05 8d 72 21 f0 8e 	movb   $0x8e,0xf021728d
f0103bb9:	c1 e8 10             	shr    $0x10,%eax
f0103bbc:	66 a3 8e 72 21 f0    	mov    %ax,0xf021728e
	SETGATE(idt[T_ILLOP], 0, GD_KT, ILLOP, 0);
f0103bc2:	b8 a6 46 10 f0       	mov    $0xf01046a6,%eax
f0103bc7:	66 a3 90 72 21 f0    	mov    %ax,0xf0217290
f0103bcd:	66 c7 05 92 72 21 f0 	movw   $0x8,0xf0217292
f0103bd4:	08 00 
f0103bd6:	c6 05 94 72 21 f0 00 	movb   $0x0,0xf0217294
f0103bdd:	c6 05 95 72 21 f0 8e 	movb   $0x8e,0xf0217295
f0103be4:	c1 e8 10             	shr    $0x10,%eax
f0103be7:	66 a3 96 72 21 f0    	mov    %ax,0xf0217296
	SETGATE(idt[T_DEVICE], 0, GD_KT, DEVICE, 0);
f0103bed:	b8 b0 46 10 f0       	mov    $0xf01046b0,%eax
f0103bf2:	66 a3 98 72 21 f0    	mov    %ax,0xf0217298
f0103bf8:	66 c7 05 9a 72 21 f0 	movw   $0x8,0xf021729a
f0103bff:	08 00 
f0103c01:	c6 05 9c 72 21 f0 00 	movb   $0x0,0xf021729c
f0103c08:	c6 05 9d 72 21 f0 8e 	movb   $0x8e,0xf021729d
f0103c0f:	c1 e8 10             	shr    $0x10,%eax
f0103c12:	66 a3 9e 72 21 f0    	mov    %ax,0xf021729e
	SETGATE(idt[T_DBLFLT], 0, GD_KT, DBLFLT, 0);
f0103c18:	b8 ba 46 10 f0       	mov    $0xf01046ba,%eax
f0103c1d:	66 a3 a0 72 21 f0    	mov    %ax,0xf02172a0
f0103c23:	66 c7 05 a2 72 21 f0 	movw   $0x8,0xf02172a2
f0103c2a:	08 00 
f0103c2c:	c6 05 a4 72 21 f0 00 	movb   $0x0,0xf02172a4
f0103c33:	c6 05 a5 72 21 f0 8e 	movb   $0x8e,0xf02172a5
f0103c3a:	c1 e8 10             	shr    $0x10,%eax
f0103c3d:	66 a3 a6 72 21 f0    	mov    %ax,0xf02172a6
	SETGATE(idt[T_TSS], 0, GD_KT, TSS, 0);
f0103c43:	b8 c2 46 10 f0       	mov    $0xf01046c2,%eax
f0103c48:	66 a3 b0 72 21 f0    	mov    %ax,0xf02172b0
f0103c4e:	66 c7 05 b2 72 21 f0 	movw   $0x8,0xf02172b2
f0103c55:	08 00 
f0103c57:	c6 05 b4 72 21 f0 00 	movb   $0x0,0xf02172b4
f0103c5e:	c6 05 b5 72 21 f0 8e 	movb   $0x8e,0xf02172b5
f0103c65:	c1 e8 10             	shr    $0x10,%eax
f0103c68:	66 a3 b6 72 21 f0    	mov    %ax,0xf02172b6
	SETGATE(idt[T_SEGNP], 0, GD_KT, SEGNP, 0);
f0103c6e:	b8 ca 46 10 f0       	mov    $0xf01046ca,%eax
f0103c73:	66 a3 b8 72 21 f0    	mov    %ax,0xf02172b8
f0103c79:	66 c7 05 ba 72 21 f0 	movw   $0x8,0xf02172ba
f0103c80:	08 00 
f0103c82:	c6 05 bc 72 21 f0 00 	movb   $0x0,0xf02172bc
f0103c89:	c6 05 bd 72 21 f0 8e 	movb   $0x8e,0xf02172bd
f0103c90:	c1 e8 10             	shr    $0x10,%eax
f0103c93:	66 a3 be 72 21 f0    	mov    %ax,0xf02172be
	SETGATE(idt[T_STACK], 0, GD_KT, STACK, 0);
f0103c99:	b8 d2 46 10 f0       	mov    $0xf01046d2,%eax
f0103c9e:	66 a3 c0 72 21 f0    	mov    %ax,0xf02172c0
f0103ca4:	66 c7 05 c2 72 21 f0 	movw   $0x8,0xf02172c2
f0103cab:	08 00 
f0103cad:	c6 05 c4 72 21 f0 00 	movb   $0x0,0xf02172c4
f0103cb4:	c6 05 c5 72 21 f0 8e 	movb   $0x8e,0xf02172c5
f0103cbb:	c1 e8 10             	shr    $0x10,%eax
f0103cbe:	66 a3 c6 72 21 f0    	mov    %ax,0xf02172c6
	SETGATE(idt[T_GPFLT], 0, GD_KT, GPFLT, 0);
f0103cc4:	b8 da 46 10 f0       	mov    $0xf01046da,%eax
f0103cc9:	66 a3 c8 72 21 f0    	mov    %ax,0xf02172c8
f0103ccf:	66 c7 05 ca 72 21 f0 	movw   $0x8,0xf02172ca
f0103cd6:	08 00 
f0103cd8:	c6 05 cc 72 21 f0 00 	movb   $0x0,0xf02172cc
f0103cdf:	c6 05 cd 72 21 f0 8e 	movb   $0x8e,0xf02172cd
f0103ce6:	c1 e8 10             	shr    $0x10,%eax
f0103ce9:	66 a3 ce 72 21 f0    	mov    %ax,0xf02172ce
	SETGATE(idt[T_PGFLT], 0, GD_KT, PGFLT, 0);
f0103cef:	b8 e2 46 10 f0       	mov    $0xf01046e2,%eax
f0103cf4:	66 a3 d0 72 21 f0    	mov    %ax,0xf02172d0
f0103cfa:	66 c7 05 d2 72 21 f0 	movw   $0x8,0xf02172d2
f0103d01:	08 00 
f0103d03:	c6 05 d4 72 21 f0 00 	movb   $0x0,0xf02172d4
f0103d0a:	c6 05 d5 72 21 f0 8e 	movb   $0x8e,0xf02172d5
f0103d11:	c1 e8 10             	shr    $0x10,%eax
f0103d14:	66 a3 d6 72 21 f0    	mov    %ax,0xf02172d6
	SETGATE(idt[T_FPERR], 0, GD_KT, FPERR, 0);
f0103d1a:	b8 ea 46 10 f0       	mov    $0xf01046ea,%eax
f0103d1f:	66 a3 e0 72 21 f0    	mov    %ax,0xf02172e0
f0103d25:	66 c7 05 e2 72 21 f0 	movw   $0x8,0xf02172e2
f0103d2c:	08 00 
f0103d2e:	c6 05 e4 72 21 f0 00 	movb   $0x0,0xf02172e4
f0103d35:	c6 05 e5 72 21 f0 8e 	movb   $0x8e,0xf02172e5
f0103d3c:	c1 e8 10             	shr    $0x10,%eax
f0103d3f:	66 a3 e6 72 21 f0    	mov    %ax,0xf02172e6
	SETGATE(idt[T_ALIGN], 0, GD_KT, ALIGN, 0);
f0103d45:	b8 f4 46 10 f0       	mov    $0xf01046f4,%eax
f0103d4a:	66 a3 e8 72 21 f0    	mov    %ax,0xf02172e8
f0103d50:	66 c7 05 ea 72 21 f0 	movw   $0x8,0xf02172ea
f0103d57:	08 00 
f0103d59:	c6 05 ec 72 21 f0 00 	movb   $0x0,0xf02172ec
f0103d60:	c6 05 ed 72 21 f0 8e 	movb   $0x8e,0xf02172ed
f0103d67:	c1 e8 10             	shr    $0x10,%eax
f0103d6a:	66 a3 ee 72 21 f0    	mov    %ax,0xf02172ee
	SETGATE(idt[T_MCHK], 0, GD_KT, MCHK, 0);
f0103d70:	b8 fc 46 10 f0       	mov    $0xf01046fc,%eax
f0103d75:	66 a3 f0 72 21 f0    	mov    %ax,0xf02172f0
f0103d7b:	66 c7 05 f2 72 21 f0 	movw   $0x8,0xf02172f2
f0103d82:	08 00 
f0103d84:	c6 05 f4 72 21 f0 00 	movb   $0x0,0xf02172f4
f0103d8b:	c6 05 f5 72 21 f0 8e 	movb   $0x8e,0xf02172f5
f0103d92:	c1 e8 10             	shr    $0x10,%eax
f0103d95:	66 a3 f6 72 21 f0    	mov    %ax,0xf02172f6
	SETGATE(idt[T_SIMDERR], 0, GD_KT, SIMDERR, 0);
f0103d9b:	b8 02 47 10 f0       	mov    $0xf0104702,%eax
f0103da0:	66 a3 f8 72 21 f0    	mov    %ax,0xf02172f8
f0103da6:	66 c7 05 fa 72 21 f0 	movw   $0x8,0xf02172fa
f0103dad:	08 00 
f0103daf:	c6 05 fc 72 21 f0 00 	movb   $0x0,0xf02172fc
f0103db6:	c6 05 fd 72 21 f0 8e 	movb   $0x8e,0xf02172fd
f0103dbd:	c1 e8 10             	shr    $0x10,%eax
f0103dc0:	66 a3 fe 72 21 f0    	mov    %ax,0xf02172fe
	SETGATE(idt[T_SYSCALL], 0, GD_KT, SYSCALL, 3);
f0103dc6:	b8 08 47 10 f0       	mov    $0xf0104708,%eax
f0103dcb:	66 a3 e0 73 21 f0    	mov    %ax,0xf02173e0
f0103dd1:	66 c7 05 e2 73 21 f0 	movw   $0x8,0xf02173e2
f0103dd8:	08 00 
f0103dda:	c6 05 e4 73 21 f0 00 	movb   $0x0,0xf02173e4
f0103de1:	c6 05 e5 73 21 f0 ee 	movb   $0xee,0xf02173e5
f0103de8:	c1 e8 10             	shr    $0x10,%eax
f0103deb:	66 a3 e6 73 21 f0    	mov    %ax,0xf02173e6
	SETGATE(idt[T_DEFAULT], 0, GD_KT, DEFAULT, 0);
f0103df1:	b8 0e 47 10 f0       	mov    $0xf010470e,%eax
f0103df6:	66 a3 00 82 21 f0    	mov    %ax,0xf0218200
f0103dfc:	66 c7 05 02 82 21 f0 	movw   $0x8,0xf0218202
f0103e03:	08 00 
f0103e05:	c6 05 04 82 21 f0 00 	movb   $0x0,0xf0218204
f0103e0c:	c6 05 05 82 21 f0 8e 	movb   $0x8e,0xf0218205
f0103e13:	c1 e8 10             	shr    $0x10,%eax
f0103e16:	66 a3 06 82 21 f0    	mov    %ax,0xf0218206
	SETGATE(idt[IRQ_OFFSET+IRQ_TIMER],0,GD_KT,IRQsHandler0,0);
f0103e1c:	b8 18 47 10 f0       	mov    $0xf0104718,%eax
f0103e21:	66 a3 60 73 21 f0    	mov    %ax,0xf0217360
f0103e27:	66 c7 05 62 73 21 f0 	movw   $0x8,0xf0217362
f0103e2e:	08 00 
f0103e30:	c6 05 64 73 21 f0 00 	movb   $0x0,0xf0217364
f0103e37:	c6 05 65 73 21 f0 8e 	movb   $0x8e,0xf0217365
f0103e3e:	c1 e8 10             	shr    $0x10,%eax
f0103e41:	66 a3 66 73 21 f0    	mov    %ax,0xf0217366
	SETGATE(idt[IRQ_OFFSET+IRQ_KBD],0,GD_KT,IRQsHandler1,0);
f0103e47:	b8 1e 47 10 f0       	mov    $0xf010471e,%eax
f0103e4c:	66 a3 68 73 21 f0    	mov    %ax,0xf0217368
f0103e52:	66 c7 05 6a 73 21 f0 	movw   $0x8,0xf021736a
f0103e59:	08 00 
f0103e5b:	c6 05 6c 73 21 f0 00 	movb   $0x0,0xf021736c
f0103e62:	c6 05 6d 73 21 f0 8e 	movb   $0x8e,0xf021736d
f0103e69:	c1 e8 10             	shr    $0x10,%eax
f0103e6c:	66 a3 6e 73 21 f0    	mov    %ax,0xf021736e
	SETGATE(idt[IRQ_OFFSET+2],0,GD_KT,IRQsHandler2,0);
f0103e72:	b8 24 47 10 f0       	mov    $0xf0104724,%eax
f0103e77:	66 a3 70 73 21 f0    	mov    %ax,0xf0217370
f0103e7d:	66 c7 05 72 73 21 f0 	movw   $0x8,0xf0217372
f0103e84:	08 00 
f0103e86:	c6 05 74 73 21 f0 00 	movb   $0x0,0xf0217374
f0103e8d:	c6 05 75 73 21 f0 8e 	movb   $0x8e,0xf0217375
f0103e94:	c1 e8 10             	shr    $0x10,%eax
f0103e97:	66 a3 76 73 21 f0    	mov    %ax,0xf0217376
	SETGATE(idt[IRQ_OFFSET+3],0,GD_KT,IRQsHandler3,0);
f0103e9d:	b8 2a 47 10 f0       	mov    $0xf010472a,%eax
f0103ea2:	66 a3 78 73 21 f0    	mov    %ax,0xf0217378
f0103ea8:	66 c7 05 7a 73 21 f0 	movw   $0x8,0xf021737a
f0103eaf:	08 00 
f0103eb1:	c6 05 7c 73 21 f0 00 	movb   $0x0,0xf021737c
f0103eb8:	c6 05 7d 73 21 f0 8e 	movb   $0x8e,0xf021737d
f0103ebf:	c1 e8 10             	shr    $0x10,%eax
f0103ec2:	66 a3 7e 73 21 f0    	mov    %ax,0xf021737e
	SETGATE(idt[IRQ_OFFSET+IRQ_SERIAL],0,GD_KT,IRQsHandler4,0);
f0103ec8:	b8 30 47 10 f0       	mov    $0xf0104730,%eax
f0103ecd:	66 a3 80 73 21 f0    	mov    %ax,0xf0217380
f0103ed3:	66 c7 05 82 73 21 f0 	movw   $0x8,0xf0217382
f0103eda:	08 00 
f0103edc:	c6 05 84 73 21 f0 00 	movb   $0x0,0xf0217384
f0103ee3:	c6 05 85 73 21 f0 8e 	movb   $0x8e,0xf0217385
f0103eea:	c1 e8 10             	shr    $0x10,%eax
f0103eed:	66 a3 86 73 21 f0    	mov    %ax,0xf0217386
	SETGATE(idt[IRQ_OFFSET+5],0,GD_KT,IRQsHandler5,0);
f0103ef3:	b8 36 47 10 f0       	mov    $0xf0104736,%eax
f0103ef8:	66 a3 88 73 21 f0    	mov    %ax,0xf0217388
f0103efe:	66 c7 05 8a 73 21 f0 	movw   $0x8,0xf021738a
f0103f05:	08 00 
f0103f07:	c6 05 8c 73 21 f0 00 	movb   $0x0,0xf021738c
f0103f0e:	c6 05 8d 73 21 f0 8e 	movb   $0x8e,0xf021738d
f0103f15:	c1 e8 10             	shr    $0x10,%eax
f0103f18:	66 a3 8e 73 21 f0    	mov    %ax,0xf021738e
	SETGATE(idt[IRQ_OFFSET+6],0,GD_KT,IRQsHandler6,0);
f0103f1e:	b8 3c 47 10 f0       	mov    $0xf010473c,%eax
f0103f23:	66 a3 90 73 21 f0    	mov    %ax,0xf0217390
f0103f29:	66 c7 05 92 73 21 f0 	movw   $0x8,0xf0217392
f0103f30:	08 00 
f0103f32:	c6 05 94 73 21 f0 00 	movb   $0x0,0xf0217394
f0103f39:	c6 05 95 73 21 f0 8e 	movb   $0x8e,0xf0217395
f0103f40:	c1 e8 10             	shr    $0x10,%eax
f0103f43:	66 a3 96 73 21 f0    	mov    %ax,0xf0217396
	SETGATE(idt[IRQ_OFFSET+IRQ_SPURIOUS],0,GD_KT,IRQsHandler7,0);
f0103f49:	b8 42 47 10 f0       	mov    $0xf0104742,%eax
f0103f4e:	66 a3 98 73 21 f0    	mov    %ax,0xf0217398
f0103f54:	66 c7 05 9a 73 21 f0 	movw   $0x8,0xf021739a
f0103f5b:	08 00 
f0103f5d:	c6 05 9c 73 21 f0 00 	movb   $0x0,0xf021739c
f0103f64:	c6 05 9d 73 21 f0 8e 	movb   $0x8e,0xf021739d
f0103f6b:	c1 e8 10             	shr    $0x10,%eax
f0103f6e:	66 a3 9e 73 21 f0    	mov    %ax,0xf021739e
	SETGATE(idt[IRQ_OFFSET+8],0,GD_KT,IRQsHandler8,0);
f0103f74:	b8 48 47 10 f0       	mov    $0xf0104748,%eax
f0103f79:	66 a3 a0 73 21 f0    	mov    %ax,0xf02173a0
f0103f7f:	66 c7 05 a2 73 21 f0 	movw   $0x8,0xf02173a2
f0103f86:	08 00 
f0103f88:	c6 05 a4 73 21 f0 00 	movb   $0x0,0xf02173a4
f0103f8f:	c6 05 a5 73 21 f0 8e 	movb   $0x8e,0xf02173a5
f0103f96:	c1 e8 10             	shr    $0x10,%eax
f0103f99:	66 a3 a6 73 21 f0    	mov    %ax,0xf02173a6
	SETGATE(idt[IRQ_OFFSET+9],0,GD_KT,IRQsHandler9,0);
f0103f9f:	b8 4e 47 10 f0       	mov    $0xf010474e,%eax
f0103fa4:	66 a3 a8 73 21 f0    	mov    %ax,0xf02173a8
f0103faa:	66 c7 05 aa 73 21 f0 	movw   $0x8,0xf02173aa
f0103fb1:	08 00 
f0103fb3:	c6 05 ac 73 21 f0 00 	movb   $0x0,0xf02173ac
f0103fba:	c6 05 ad 73 21 f0 8e 	movb   $0x8e,0xf02173ad
f0103fc1:	c1 e8 10             	shr    $0x10,%eax
f0103fc4:	66 a3 ae 73 21 f0    	mov    %ax,0xf02173ae
	SETGATE(idt[IRQ_OFFSET+10],0,GD_KT,IRQsHandler10,0);
f0103fca:	b8 54 47 10 f0       	mov    $0xf0104754,%eax
f0103fcf:	66 a3 b0 73 21 f0    	mov    %ax,0xf02173b0
f0103fd5:	66 c7 05 b2 73 21 f0 	movw   $0x8,0xf02173b2
f0103fdc:	08 00 
f0103fde:	c6 05 b4 73 21 f0 00 	movb   $0x0,0xf02173b4
f0103fe5:	c6 05 b5 73 21 f0 8e 	movb   $0x8e,0xf02173b5
f0103fec:	c1 e8 10             	shr    $0x10,%eax
f0103fef:	66 a3 b6 73 21 f0    	mov    %ax,0xf02173b6
	SETGATE(idt[IRQ_OFFSET+11],0,GD_KT,IRQsHandler11,0);
f0103ff5:	b8 5a 47 10 f0       	mov    $0xf010475a,%eax
f0103ffa:	66 a3 b8 73 21 f0    	mov    %ax,0xf02173b8
f0104000:	66 c7 05 ba 73 21 f0 	movw   $0x8,0xf02173ba
f0104007:	08 00 
f0104009:	c6 05 bc 73 21 f0 00 	movb   $0x0,0xf02173bc
f0104010:	c6 05 bd 73 21 f0 8e 	movb   $0x8e,0xf02173bd
f0104017:	c1 e8 10             	shr    $0x10,%eax
f010401a:	66 a3 be 73 21 f0    	mov    %ax,0xf02173be
	SETGATE(idt[IRQ_OFFSET+12],0,GD_KT,IRQsHandler12,0);
f0104020:	b8 60 47 10 f0       	mov    $0xf0104760,%eax
f0104025:	66 a3 c0 73 21 f0    	mov    %ax,0xf02173c0
f010402b:	66 c7 05 c2 73 21 f0 	movw   $0x8,0xf02173c2
f0104032:	08 00 
f0104034:	c6 05 c4 73 21 f0 00 	movb   $0x0,0xf02173c4
f010403b:	c6 05 c5 73 21 f0 8e 	movb   $0x8e,0xf02173c5
f0104042:	c1 e8 10             	shr    $0x10,%eax
f0104045:	66 a3 c6 73 21 f0    	mov    %ax,0xf02173c6
	SETGATE(idt[IRQ_OFFSET+13],0,GD_KT,IRQsHandler13,0);
f010404b:	b8 66 47 10 f0       	mov    $0xf0104766,%eax
f0104050:	66 a3 c8 73 21 f0    	mov    %ax,0xf02173c8
f0104056:	66 c7 05 ca 73 21 f0 	movw   $0x8,0xf02173ca
f010405d:	08 00 
f010405f:	c6 05 cc 73 21 f0 00 	movb   $0x0,0xf02173cc
f0104066:	c6 05 cd 73 21 f0 8e 	movb   $0x8e,0xf02173cd
f010406d:	c1 e8 10             	shr    $0x10,%eax
f0104070:	66 a3 ce 73 21 f0    	mov    %ax,0xf02173ce
	SETGATE(idt[IRQ_OFFSET+IRQ_IDE],0,GD_KT,IRQsHandler14,0);
f0104076:	b8 6c 47 10 f0       	mov    $0xf010476c,%eax
f010407b:	66 a3 d0 73 21 f0    	mov    %ax,0xf02173d0
f0104081:	66 c7 05 d2 73 21 f0 	movw   $0x8,0xf02173d2
f0104088:	08 00 
f010408a:	c6 05 d4 73 21 f0 00 	movb   $0x0,0xf02173d4
f0104091:	c6 05 d5 73 21 f0 8e 	movb   $0x8e,0xf02173d5
f0104098:	c1 e8 10             	shr    $0x10,%eax
f010409b:	66 a3 d6 73 21 f0    	mov    %ax,0xf02173d6
	SETGATE(idt[IRQ_OFFSET+15],0,GD_KT,IRQsHandler15,0);
f01040a1:	b8 72 47 10 f0       	mov    $0xf0104772,%eax
f01040a6:	66 a3 d8 73 21 f0    	mov    %ax,0xf02173d8
f01040ac:	66 c7 05 da 73 21 f0 	movw   $0x8,0xf02173da
f01040b3:	08 00 
f01040b5:	c6 05 dc 73 21 f0 00 	movb   $0x0,0xf02173dc
f01040bc:	c6 05 dd 73 21 f0 8e 	movb   $0x8e,0xf02173dd
f01040c3:	c1 e8 10             	shr    $0x10,%eax
f01040c6:	66 a3 de 73 21 f0    	mov    %ax,0xf02173de
	trap_init_percpu();
f01040cc:	e8 01 f9 ff ff       	call   f01039d2 <trap_init_percpu>
}
f01040d1:	c9                   	leave  
f01040d2:	c3                   	ret    

f01040d3 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01040d3:	f3 0f 1e fb          	endbr32 
f01040d7:	55                   	push   %ebp
f01040d8:	89 e5                	mov    %esp,%ebp
f01040da:	53                   	push   %ebx
f01040db:	83 ec 0c             	sub    $0xc,%esp
f01040de:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01040e1:	ff 33                	pushl  (%ebx)
f01040e3:	68 50 7b 10 f0       	push   $0xf0107b50
f01040e8:	e8 cd f8 ff ff       	call   f01039ba <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01040ed:	83 c4 08             	add    $0x8,%esp
f01040f0:	ff 73 04             	pushl  0x4(%ebx)
f01040f3:	68 5f 7b 10 f0       	push   $0xf0107b5f
f01040f8:	e8 bd f8 ff ff       	call   f01039ba <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01040fd:	83 c4 08             	add    $0x8,%esp
f0104100:	ff 73 08             	pushl  0x8(%ebx)
f0104103:	68 6e 7b 10 f0       	push   $0xf0107b6e
f0104108:	e8 ad f8 ff ff       	call   f01039ba <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f010410d:	83 c4 08             	add    $0x8,%esp
f0104110:	ff 73 0c             	pushl  0xc(%ebx)
f0104113:	68 7d 7b 10 f0       	push   $0xf0107b7d
f0104118:	e8 9d f8 ff ff       	call   f01039ba <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f010411d:	83 c4 08             	add    $0x8,%esp
f0104120:	ff 73 10             	pushl  0x10(%ebx)
f0104123:	68 8c 7b 10 f0       	push   $0xf0107b8c
f0104128:	e8 8d f8 ff ff       	call   f01039ba <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f010412d:	83 c4 08             	add    $0x8,%esp
f0104130:	ff 73 14             	pushl  0x14(%ebx)
f0104133:	68 9b 7b 10 f0       	push   $0xf0107b9b
f0104138:	e8 7d f8 ff ff       	call   f01039ba <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f010413d:	83 c4 08             	add    $0x8,%esp
f0104140:	ff 73 18             	pushl  0x18(%ebx)
f0104143:	68 aa 7b 10 f0       	push   $0xf0107baa
f0104148:	e8 6d f8 ff ff       	call   f01039ba <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f010414d:	83 c4 08             	add    $0x8,%esp
f0104150:	ff 73 1c             	pushl  0x1c(%ebx)
f0104153:	68 b9 7b 10 f0       	push   $0xf0107bb9
f0104158:	e8 5d f8 ff ff       	call   f01039ba <cprintf>
}
f010415d:	83 c4 10             	add    $0x10,%esp
f0104160:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104163:	c9                   	leave  
f0104164:	c3                   	ret    

f0104165 <print_trapframe>:
{
f0104165:	f3 0f 1e fb          	endbr32 
f0104169:	55                   	push   %ebp
f010416a:	89 e5                	mov    %esp,%ebp
f010416c:	56                   	push   %esi
f010416d:	53                   	push   %ebx
f010416e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0104171:	e8 c8 1f 00 00       	call   f010613e <cpunum>
f0104176:	83 ec 04             	sub    $0x4,%esp
f0104179:	50                   	push   %eax
f010417a:	53                   	push   %ebx
f010417b:	68 1d 7c 10 f0       	push   $0xf0107c1d
f0104180:	e8 35 f8 ff ff       	call   f01039ba <cprintf>
	print_regs(&tf->tf_regs);
f0104185:	89 1c 24             	mov    %ebx,(%esp)
f0104188:	e8 46 ff ff ff       	call   f01040d3 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f010418d:	83 c4 08             	add    $0x8,%esp
f0104190:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0104194:	50                   	push   %eax
f0104195:	68 3b 7c 10 f0       	push   $0xf0107c3b
f010419a:	e8 1b f8 ff ff       	call   f01039ba <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f010419f:	83 c4 08             	add    $0x8,%esp
f01041a2:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01041a6:	50                   	push   %eax
f01041a7:	68 4e 7c 10 f0       	push   $0xf0107c4e
f01041ac:	e8 09 f8 ff ff       	call   f01039ba <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01041b1:	8b 43 28             	mov    0x28(%ebx),%eax
	if (trapno < ARRAY_SIZE(excnames))
f01041b4:	83 c4 10             	add    $0x10,%esp
f01041b7:	83 f8 13             	cmp    $0x13,%eax
f01041ba:	0f 86 da 00 00 00    	jbe    f010429a <print_trapframe+0x135>
		return "System call";
f01041c0:	ba c8 7b 10 f0       	mov    $0xf0107bc8,%edx
	if (trapno == T_SYSCALL)
f01041c5:	83 f8 30             	cmp    $0x30,%eax
f01041c8:	74 13                	je     f01041dd <print_trapframe+0x78>
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f01041ca:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
f01041cd:	83 fa 0f             	cmp    $0xf,%edx
f01041d0:	ba d4 7b 10 f0       	mov    $0xf0107bd4,%edx
f01041d5:	b9 e3 7b 10 f0       	mov    $0xf0107be3,%ecx
f01041da:	0f 46 d1             	cmovbe %ecx,%edx
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01041dd:	83 ec 04             	sub    $0x4,%esp
f01041e0:	52                   	push   %edx
f01041e1:	50                   	push   %eax
f01041e2:	68 61 7c 10 f0       	push   $0xf0107c61
f01041e7:	e8 ce f7 ff ff       	call   f01039ba <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01041ec:	83 c4 10             	add    $0x10,%esp
f01041ef:	39 1d 60 7a 21 f0    	cmp    %ebx,0xf0217a60
f01041f5:	0f 84 ab 00 00 00    	je     f01042a6 <print_trapframe+0x141>
	cprintf("  err  0x%08x", tf->tf_err);
f01041fb:	83 ec 08             	sub    $0x8,%esp
f01041fe:	ff 73 2c             	pushl  0x2c(%ebx)
f0104201:	68 82 7c 10 f0       	push   $0xf0107c82
f0104206:	e8 af f7 ff ff       	call   f01039ba <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f010420b:	83 c4 10             	add    $0x10,%esp
f010420e:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0104212:	0f 85 b1 00 00 00    	jne    f01042c9 <print_trapframe+0x164>
			tf->tf_err & 1 ? "protection" : "not-present");
f0104218:	8b 43 2c             	mov    0x2c(%ebx),%eax
		cprintf(" [%s, %s, %s]\n",
f010421b:	a8 01                	test   $0x1,%al
f010421d:	b9 f6 7b 10 f0       	mov    $0xf0107bf6,%ecx
f0104222:	ba 01 7c 10 f0       	mov    $0xf0107c01,%edx
f0104227:	0f 44 ca             	cmove  %edx,%ecx
f010422a:	a8 02                	test   $0x2,%al
f010422c:	be 0d 7c 10 f0       	mov    $0xf0107c0d,%esi
f0104231:	ba 13 7c 10 f0       	mov    $0xf0107c13,%edx
f0104236:	0f 45 d6             	cmovne %esi,%edx
f0104239:	a8 04                	test   $0x4,%al
f010423b:	b8 18 7c 10 f0       	mov    $0xf0107c18,%eax
f0104240:	be 4d 7d 10 f0       	mov    $0xf0107d4d,%esi
f0104245:	0f 44 c6             	cmove  %esi,%eax
f0104248:	51                   	push   %ecx
f0104249:	52                   	push   %edx
f010424a:	50                   	push   %eax
f010424b:	68 90 7c 10 f0       	push   $0xf0107c90
f0104250:	e8 65 f7 ff ff       	call   f01039ba <cprintf>
f0104255:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0104258:	83 ec 08             	sub    $0x8,%esp
f010425b:	ff 73 30             	pushl  0x30(%ebx)
f010425e:	68 9f 7c 10 f0       	push   $0xf0107c9f
f0104263:	e8 52 f7 ff ff       	call   f01039ba <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0104268:	83 c4 08             	add    $0x8,%esp
f010426b:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f010426f:	50                   	push   %eax
f0104270:	68 ae 7c 10 f0       	push   $0xf0107cae
f0104275:	e8 40 f7 ff ff       	call   f01039ba <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010427a:	83 c4 08             	add    $0x8,%esp
f010427d:	ff 73 38             	pushl  0x38(%ebx)
f0104280:	68 c1 7c 10 f0       	push   $0xf0107cc1
f0104285:	e8 30 f7 ff ff       	call   f01039ba <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010428a:	83 c4 10             	add    $0x10,%esp
f010428d:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0104291:	75 4b                	jne    f01042de <print_trapframe+0x179>
}
f0104293:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0104296:	5b                   	pop    %ebx
f0104297:	5e                   	pop    %esi
f0104298:	5d                   	pop    %ebp
f0104299:	c3                   	ret    
		return excnames[trapno];
f010429a:	8b 14 85 e0 7f 10 f0 	mov    -0xfef8020(,%eax,4),%edx
f01042a1:	e9 37 ff ff ff       	jmp    f01041dd <print_trapframe+0x78>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01042a6:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01042aa:	0f 85 4b ff ff ff    	jne    f01041fb <print_trapframe+0x96>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01042b0:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01042b3:	83 ec 08             	sub    $0x8,%esp
f01042b6:	50                   	push   %eax
f01042b7:	68 73 7c 10 f0       	push   $0xf0107c73
f01042bc:	e8 f9 f6 ff ff       	call   f01039ba <cprintf>
f01042c1:	83 c4 10             	add    $0x10,%esp
f01042c4:	e9 32 ff ff ff       	jmp    f01041fb <print_trapframe+0x96>
		cprintf("\n");
f01042c9:	83 ec 0c             	sub    $0xc,%esp
f01042cc:	68 fd 79 10 f0       	push   $0xf01079fd
f01042d1:	e8 e4 f6 ff ff       	call   f01039ba <cprintf>
f01042d6:	83 c4 10             	add    $0x10,%esp
f01042d9:	e9 7a ff ff ff       	jmp    f0104258 <print_trapframe+0xf3>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01042de:	83 ec 08             	sub    $0x8,%esp
f01042e1:	ff 73 3c             	pushl  0x3c(%ebx)
f01042e4:	68 d0 7c 10 f0       	push   $0xf0107cd0
f01042e9:	e8 cc f6 ff ff       	call   f01039ba <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01042ee:	83 c4 08             	add    $0x8,%esp
f01042f1:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01042f5:	50                   	push   %eax
f01042f6:	68 df 7c 10 f0       	push   $0xf0107cdf
f01042fb:	e8 ba f6 ff ff       	call   f01039ba <cprintf>
f0104300:	83 c4 10             	add    $0x10,%esp
}
f0104303:	eb 8e                	jmp    f0104293 <print_trapframe+0x12e>

f0104305 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0104305:	f3 0f 1e fb          	endbr32 
f0104309:	55                   	push   %ebp
f010430a:	89 e5                	mov    %esp,%ebp
f010430c:	57                   	push   %edi
f010430d:	56                   	push   %esi
f010430e:	53                   	push   %ebx
f010430f:	83 ec 1c             	sub    $0x1c,%esp
f0104312:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104315:	0f 20 d6             	mov    %cr2,%esi

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	// check low-bits of tf_cs
	if((tf->tf_cs & 3) == 0)
f0104318:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f010431c:	75 15                	jne    f0104333 <page_fault_handler+0x2e>
	{
		panic("At page_fault_handler: page fault at %08x.\n",fault_va);
f010431e:	56                   	push   %esi
f010431f:	68 98 7e 10 f0       	push   $0xf0107e98
f0104324:	68 b4 01 00 00       	push   $0x1b4
f0104329:	68 f2 7c 10 f0       	push   $0xf0107cf2
f010432e:	e8 0d bd ff ff       	call   f0100040 <_panic>
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	// no self-defined pgfault_upcall function
	if(curenv->env_pgfault_upcall == NULL)
f0104333:	e8 06 1e 00 00       	call   f010613e <cpunum>
f0104338:	6b c0 74             	imul   $0x74,%eax,%eax
f010433b:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0104341:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0104345:	0f 84 92 00 00 00    	je     f01043dd <page_fault_handler+0xd8>
	
	struct UTrapframe* utf;
	uintptr_t addr;
	// determine utf address
	size_t size = sizeof(struct UTrapframe)+ sizeof(uint32_t);
	if (tf->tf_esp >= UXSTACKTOP-PGSIZE && tf->tf_esp < UXSTACKTOP)
f010434b:	8b 43 3c             	mov    0x3c(%ebx),%eax
f010434e:	8d 90 00 10 40 11    	lea    0x11401000(%eax),%edx
	{
		addr = tf->tf_esp - size;
	}
	else
	{
		addr = UXSTACKTOP - size;
f0104354:	c7 45 e4 c8 ff bf ee 	movl   $0xeebfffc8,-0x1c(%ebp)
	if (tf->tf_esp >= UXSTACKTOP-PGSIZE && tf->tf_esp < UXSTACKTOP)
f010435b:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f0104361:	77 06                	ja     f0104369 <page_fault_handler+0x64>
		addr = tf->tf_esp - size;
f0104363:	83 e8 38             	sub    $0x38,%eax
f0104366:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	}
	// check the permission
	user_mem_assert(curenv,(void*)addr,size,PTE_P|PTE_W|PTE_U);
f0104369:	e8 d0 1d 00 00       	call   f010613e <cpunum>
f010436e:	6a 07                	push   $0x7
f0104370:	6a 38                	push   $0x38
f0104372:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104375:	57                   	push   %edi
f0104376:	6b c0 74             	imul   $0x74,%eax,%eax
f0104379:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f010437f:	e8 83 ec ff ff       	call   f0103007 <user_mem_assert>

	// set the attributes
	utf = (struct UTrapframe*)addr;
	utf->utf_fault_va = fault_va;
f0104384:	89 37                	mov    %esi,(%edi)
	utf->utf_eflags = tf->tf_eflags;
f0104386:	8b 43 38             	mov    0x38(%ebx),%eax
f0104389:	89 47 2c             	mov    %eax,0x2c(%edi)
	utf->utf_err = tf->tf_err;
f010438c:	8b 43 2c             	mov    0x2c(%ebx),%eax
f010438f:	89 47 04             	mov    %eax,0x4(%edi)
	utf->utf_esp = tf->tf_esp;
f0104392:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0104395:	89 47 30             	mov    %eax,0x30(%edi)
	utf->utf_eip = tf->tf_eip;
f0104398:	8b 43 30             	mov    0x30(%ebx),%eax
f010439b:	89 47 28             	mov    %eax,0x28(%edi)
	utf->utf_regs = tf->tf_regs;
f010439e:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f01043a1:	8d 7f 08             	lea    0x8(%edi),%edi
f01043a4:	b9 08 00 00 00       	mov    $0x8,%ecx
f01043a9:	89 de                	mov    %ebx,%esi
f01043ab:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	// change the value in eip field of tf
	tf->tf_eip = (uintptr_t)curenv->env_pgfault_upcall;
f01043ad:	e8 8c 1d 00 00       	call   f010613e <cpunum>
f01043b2:	6b c0 74             	imul   $0x74,%eax,%eax
f01043b5:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01043bb:	8b 40 64             	mov    0x64(%eax),%eax
f01043be:	89 43 30             	mov    %eax,0x30(%ebx)
	tf->tf_esp = (uintptr_t)utf;
f01043c1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01043c4:	89 53 3c             	mov    %edx,0x3c(%ebx)
	env_run(curenv);
f01043c7:	e8 72 1d 00 00       	call   f010613e <cpunum>
f01043cc:	83 c4 04             	add    $0x4,%esp
f01043cf:	6b c0 74             	imul   $0x74,%eax,%eax
f01043d2:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f01043d8:	e8 5f f3 ff ff       	call   f010373c <env_run>
		cprintf("[%08x] user fault va %08x ip %08x\n",
f01043dd:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f01043e0:	e8 59 1d 00 00       	call   f010613e <cpunum>
		cprintf("[%08x] user fault va %08x ip %08x\n",
f01043e5:	57                   	push   %edi
f01043e6:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f01043e7:	6b c0 74             	imul   $0x74,%eax,%eax
		cprintf("[%08x] user fault va %08x ip %08x\n",
f01043ea:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01043f0:	ff 70 48             	pushl  0x48(%eax)
f01043f3:	68 c4 7e 10 f0       	push   $0xf0107ec4
f01043f8:	e8 bd f5 ff ff       	call   f01039ba <cprintf>
		print_trapframe(tf);
f01043fd:	89 1c 24             	mov    %ebx,(%esp)
f0104400:	e8 60 fd ff ff       	call   f0104165 <print_trapframe>
		env_destroy(curenv);
f0104405:	e8 34 1d 00 00       	call   f010613e <cpunum>
f010440a:	83 c4 04             	add    $0x4,%esp
f010440d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104410:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0104416:	e8 7a f2 ff ff       	call   f0103695 <env_destroy>
f010441b:	83 c4 10             	add    $0x10,%esp
f010441e:	e9 28 ff ff ff       	jmp    f010434b <page_fault_handler+0x46>

f0104423 <trap>:
{
f0104423:	f3 0f 1e fb          	endbr32 
f0104427:	55                   	push   %ebp
f0104428:	89 e5                	mov    %esp,%ebp
f010442a:	57                   	push   %edi
f010442b:	56                   	push   %esi
f010442c:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::: "cc");
f010442f:	fc                   	cld    
	if (panicstr)
f0104430:	83 3d 80 7e 21 f0 00 	cmpl   $0x0,0xf0217e80
f0104437:	74 01                	je     f010443a <trap+0x17>
		asm volatile("hlt");
f0104439:	f4                   	hlt    
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f010443a:	e8 ff 1c 00 00       	call   f010613e <cpunum>
f010443f:	6b d0 74             	imul   $0x74,%eax,%edx
f0104442:	83 c2 04             	add    $0x4,%edx
	asm volatile("lock; xchgl %0, %1"
f0104445:	b8 01 00 00 00       	mov    $0x1,%eax
f010444a:	f0 87 82 20 80 21 f0 	lock xchg %eax,-0xfde7fe0(%edx)
f0104451:	83 f8 02             	cmp    $0x2,%eax
f0104454:	74 37                	je     f010448d <trap+0x6a>
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0104456:	9c                   	pushf  
f0104457:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
f0104458:	f6 c4 02             	test   $0x2,%ah
f010445b:	75 42                	jne    f010449f <trap+0x7c>
	if ((tf->tf_cs & 3) == 3) {
f010445d:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104461:	83 e0 03             	and    $0x3,%eax
f0104464:	66 83 f8 03          	cmp    $0x3,%ax
f0104468:	74 4e                	je     f01044b8 <trap+0x95>
	last_tf = tf;
f010446a:	89 35 60 7a 21 f0    	mov    %esi,0xf0217a60
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0104470:	8b 46 28             	mov    0x28(%esi),%eax
f0104473:	83 f8 27             	cmp    $0x27,%eax
f0104476:	0f 84 e1 00 00 00    	je     f010455d <trap+0x13a>
f010447c:	83 f8 30             	cmp    $0x30,%eax
f010447f:	0f 87 86 01 00 00    	ja     f010460b <trap+0x1e8>
f0104485:	3e ff 24 85 00 7f 10 	notrack jmp *-0xfef8100(,%eax,4)
f010448c:	f0 
	spin_lock(&kernel_lock);
f010448d:	83 ec 0c             	sub    $0xc,%esp
f0104490:	68 c0 33 12 f0       	push   $0xf01233c0
f0104495:	e8 2c 1f 00 00       	call   f01063c6 <spin_lock>
}
f010449a:	83 c4 10             	add    $0x10,%esp
f010449d:	eb b7                	jmp    f0104456 <trap+0x33>
	assert(!(read_eflags() & FL_IF));
f010449f:	68 fe 7c 10 f0       	push   $0xf0107cfe
f01044a4:	68 43 77 10 f0       	push   $0xf0107743
f01044a9:	68 7c 01 00 00       	push   $0x17c
f01044ae:	68 f2 7c 10 f0       	push   $0xf0107cf2
f01044b3:	e8 88 bb ff ff       	call   f0100040 <_panic>
	spin_lock(&kernel_lock);
f01044b8:	83 ec 0c             	sub    $0xc,%esp
f01044bb:	68 c0 33 12 f0       	push   $0xf01233c0
f01044c0:	e8 01 1f 00 00       	call   f01063c6 <spin_lock>
		assert(curenv);
f01044c5:	e8 74 1c 00 00       	call   f010613e <cpunum>
f01044ca:	6b c0 74             	imul   $0x74,%eax,%eax
f01044cd:	83 c4 10             	add    $0x10,%esp
f01044d0:	83 b8 28 80 21 f0 00 	cmpl   $0x0,-0xfde7fd8(%eax)
f01044d7:	74 3e                	je     f0104517 <trap+0xf4>
		if (curenv->env_status == ENV_DYING) {
f01044d9:	e8 60 1c 00 00       	call   f010613e <cpunum>
f01044de:	6b c0 74             	imul   $0x74,%eax,%eax
f01044e1:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01044e7:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f01044eb:	74 43                	je     f0104530 <trap+0x10d>
		curenv->env_tf = *tf;
f01044ed:	e8 4c 1c 00 00       	call   f010613e <cpunum>
f01044f2:	6b c0 74             	imul   $0x74,%eax,%eax
f01044f5:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01044fb:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104500:	89 c7                	mov    %eax,%edi
f0104502:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &curenv->env_tf;
f0104504:	e8 35 1c 00 00       	call   f010613e <cpunum>
f0104509:	6b c0 74             	imul   $0x74,%eax,%eax
f010450c:	8b b0 28 80 21 f0    	mov    -0xfde7fd8(%eax),%esi
f0104512:	e9 53 ff ff ff       	jmp    f010446a <trap+0x47>
		assert(curenv);
f0104517:	68 17 7d 10 f0       	push   $0xf0107d17
f010451c:	68 43 77 10 f0       	push   $0xf0107743
f0104521:	68 84 01 00 00       	push   $0x184
f0104526:	68 f2 7c 10 f0       	push   $0xf0107cf2
f010452b:	e8 10 bb ff ff       	call   f0100040 <_panic>
			env_free(curenv);
f0104530:	e8 09 1c 00 00       	call   f010613e <cpunum>
f0104535:	83 ec 0c             	sub    $0xc,%esp
f0104538:	6b c0 74             	imul   $0x74,%eax,%eax
f010453b:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0104541:	e8 a1 ef ff ff       	call   f01034e7 <env_free>
			curenv = NULL;
f0104546:	e8 f3 1b 00 00       	call   f010613e <cpunum>
f010454b:	6b c0 74             	imul   $0x74,%eax,%eax
f010454e:	c7 80 28 80 21 f0 00 	movl   $0x0,-0xfde7fd8(%eax)
f0104555:	00 00 00 
			sched_yield();
f0104558:	e8 00 03 00 00       	call   f010485d <sched_yield>
		cprintf("Spurious interrupt on irq 7\n");
f010455d:	83 ec 0c             	sub    $0xc,%esp
f0104560:	68 1e 7d 10 f0       	push   $0xf0107d1e
f0104565:	e8 50 f4 ff ff       	call   f01039ba <cprintf>
		print_trapframe(tf);
f010456a:	89 34 24             	mov    %esi,(%esp)
f010456d:	e8 f3 fb ff ff       	call   f0104165 <print_trapframe>
		return;
f0104572:	83 c4 10             	add    $0x10,%esp
f0104575:	eb 15                	jmp    f010458c <trap+0x169>
			page_fault_handler(tf);
f0104577:	83 ec 0c             	sub    $0xc,%esp
f010457a:	56                   	push   %esi
f010457b:	e8 85 fd ff ff       	call   f0104305 <page_fault_handler>
			monitor(tf);
f0104580:	83 ec 0c             	sub    $0xc,%esp
f0104583:	56                   	push   %esi
f0104584:	e8 20 c4 ff ff       	call   f01009a9 <monitor>
			return;
f0104589:	83 c4 10             	add    $0x10,%esp
	if (curenv && curenv->env_status == ENV_RUNNING)
f010458c:	e8 ad 1b 00 00       	call   f010613e <cpunum>
f0104591:	6b c0 74             	imul   $0x74,%eax,%eax
f0104594:	83 b8 28 80 21 f0 00 	cmpl   $0x0,-0xfde7fd8(%eax)
f010459b:	74 18                	je     f01045b5 <trap+0x192>
f010459d:	e8 9c 1b 00 00       	call   f010613e <cpunum>
f01045a2:	6b c0 74             	imul   $0x74,%eax,%eax
f01045a5:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01045ab:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01045af:	0f 84 9e 00 00 00    	je     f0104653 <trap+0x230>
		sched_yield();
f01045b5:	e8 a3 02 00 00       	call   f010485d <sched_yield>
			monitor(tf);
f01045ba:	83 ec 0c             	sub    $0xc,%esp
f01045bd:	56                   	push   %esi
f01045be:	e8 e6 c3 ff ff       	call   f01009a9 <monitor>
			return;
f01045c3:	83 c4 10             	add    $0x10,%esp
f01045c6:	eb c4                	jmp    f010458c <trap+0x169>
			int32_t ret = syscall(regs->reg_eax,regs->reg_edx,regs->reg_ecx,regs->reg_ebx,regs->reg_edi,regs->reg_esi);
f01045c8:	83 ec 08             	sub    $0x8,%esp
f01045cb:	ff 76 04             	pushl  0x4(%esi)
f01045ce:	ff 36                	pushl  (%esi)
f01045d0:	ff 76 10             	pushl  0x10(%esi)
f01045d3:	ff 76 18             	pushl  0x18(%esi)
f01045d6:	ff 76 14             	pushl  0x14(%esi)
f01045d9:	ff 76 1c             	pushl  0x1c(%esi)
f01045dc:	e8 34 03 00 00       	call   f0104915 <syscall>
			regs->reg_eax = (uint32_t)ret;
f01045e1:	89 46 1c             	mov    %eax,0x1c(%esi)
			return;
f01045e4:	83 c4 20             	add    $0x20,%esp
f01045e7:	eb a3                	jmp    f010458c <trap+0x169>
			lapic_eoi();
f01045e9:	e8 9f 1c 00 00       	call   f010628d <lapic_eoi>
			sched_yield();
f01045ee:	e8 6a 02 00 00       	call   f010485d <sched_yield>
			lapic_eoi();
f01045f3:	e8 95 1c 00 00       	call   f010628d <lapic_eoi>
			kbd_intr();
f01045f8:	e8 15 c0 ff ff       	call   f0100612 <kbd_intr>
			return;
f01045fd:	eb 8d                	jmp    f010458c <trap+0x169>
			lapic_eoi();
f01045ff:	e8 89 1c 00 00       	call   f010628d <lapic_eoi>
			serial_intr();
f0104604:	e8 e9 bf ff ff       	call   f01005f2 <serial_intr>
			return;
f0104609:	eb 81                	jmp    f010458c <trap+0x169>
	print_trapframe(tf);
f010460b:	83 ec 0c             	sub    $0xc,%esp
f010460e:	56                   	push   %esi
f010460f:	e8 51 fb ff ff       	call   f0104165 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0104614:	83 c4 10             	add    $0x10,%esp
f0104617:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f010461c:	74 1e                	je     f010463c <trap+0x219>
		env_destroy(curenv);
f010461e:	e8 1b 1b 00 00       	call   f010613e <cpunum>
f0104623:	83 ec 0c             	sub    $0xc,%esp
f0104626:	6b c0 74             	imul   $0x74,%eax,%eax
f0104629:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f010462f:	e8 61 f0 ff ff       	call   f0103695 <env_destroy>
		return;
f0104634:	83 c4 10             	add    $0x10,%esp
f0104637:	e9 50 ff ff ff       	jmp    f010458c <trap+0x169>
		panic("unhandled trap in kernel");
f010463c:	83 ec 04             	sub    $0x4,%esp
f010463f:	68 3b 7d 10 f0       	push   $0xf0107d3b
f0104644:	68 62 01 00 00       	push   $0x162
f0104649:	68 f2 7c 10 f0       	push   $0xf0107cf2
f010464e:	e8 ed b9 ff ff       	call   f0100040 <_panic>
		env_run(curenv);
f0104653:	e8 e6 1a 00 00       	call   f010613e <cpunum>
f0104658:	83 ec 0c             	sub    $0xc,%esp
f010465b:	6b c0 74             	imul   $0x74,%eax,%eax
f010465e:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0104664:	e8 d3 f0 ff ff       	call   f010373c <env_run>
f0104669:	90                   	nop

f010466a <DIVIDE>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
 # faults and interrupts
TRAPHANDLER_NOEC(DIVIDE,T_DIVIDE)
f010466a:	6a 00                	push   $0x0
f010466c:	6a 00                	push   $0x0
f010466e:	e9 0b 01 00 00       	jmp    f010477e <_alltraps>
f0104673:	90                   	nop

f0104674 <DEBUG>:
TRAPHANDLER_NOEC(DEBUG,T_DEBUG)
f0104674:	6a 00                	push   $0x0
f0104676:	6a 01                	push   $0x1
f0104678:	e9 01 01 00 00       	jmp    f010477e <_alltraps>
f010467d:	90                   	nop

f010467e <NMI>:
TRAPHANDLER_NOEC(NMI, T_NMI)
f010467e:	6a 00                	push   $0x0
f0104680:	6a 02                	push   $0x2
f0104682:	e9 f7 00 00 00       	jmp    f010477e <_alltraps>
f0104687:	90                   	nop

f0104688 <BRKPT>:
TRAPHANDLER_NOEC(BRKPT, T_BRKPT)
f0104688:	6a 00                	push   $0x0
f010468a:	6a 03                	push   $0x3
f010468c:	e9 ed 00 00 00       	jmp    f010477e <_alltraps>
f0104691:	90                   	nop

f0104692 <OFLOW>:
TRAPHANDLER_NOEC(OFLOW, T_OFLOW)
f0104692:	6a 00                	push   $0x0
f0104694:	6a 04                	push   $0x4
f0104696:	e9 e3 00 00 00       	jmp    f010477e <_alltraps>
f010469b:	90                   	nop

f010469c <BOUND>:
TRAPHANDLER_NOEC(BOUND, T_BOUND)
f010469c:	6a 00                	push   $0x0
f010469e:	6a 05                	push   $0x5
f01046a0:	e9 d9 00 00 00       	jmp    f010477e <_alltraps>
f01046a5:	90                   	nop

f01046a6 <ILLOP>:
TRAPHANDLER_NOEC(ILLOP, T_ILLOP)
f01046a6:	6a 00                	push   $0x0
f01046a8:	6a 06                	push   $0x6
f01046aa:	e9 cf 00 00 00       	jmp    f010477e <_alltraps>
f01046af:	90                   	nop

f01046b0 <DEVICE>:
TRAPHANDLER_NOEC(DEVICE, T_DEVICE)
f01046b0:	6a 00                	push   $0x0
f01046b2:	6a 07                	push   $0x7
f01046b4:	e9 c5 00 00 00       	jmp    f010477e <_alltraps>
f01046b9:	90                   	nop

f01046ba <DBLFLT>:
TRAPHANDLER(DBLFLT, T_DBLFLT)
f01046ba:	6a 08                	push   $0x8
f01046bc:	e9 bd 00 00 00       	jmp    f010477e <_alltraps>
f01046c1:	90                   	nop

f01046c2 <TSS>:
TRAPHANDLER(TSS, T_TSS)
f01046c2:	6a 0a                	push   $0xa
f01046c4:	e9 b5 00 00 00       	jmp    f010477e <_alltraps>
f01046c9:	90                   	nop

f01046ca <SEGNP>:
TRAPHANDLER(SEGNP, T_SEGNP)
f01046ca:	6a 0b                	push   $0xb
f01046cc:	e9 ad 00 00 00       	jmp    f010477e <_alltraps>
f01046d1:	90                   	nop

f01046d2 <STACK>:
TRAPHANDLER(STACK, T_STACK)
f01046d2:	6a 0c                	push   $0xc
f01046d4:	e9 a5 00 00 00       	jmp    f010477e <_alltraps>
f01046d9:	90                   	nop

f01046da <GPFLT>:
TRAPHANDLER(GPFLT, T_GPFLT)
f01046da:	6a 0d                	push   $0xd
f01046dc:	e9 9d 00 00 00       	jmp    f010477e <_alltraps>
f01046e1:	90                   	nop

f01046e2 <PGFLT>:
TRAPHANDLER(PGFLT, T_PGFLT)
f01046e2:	6a 0e                	push   $0xe
f01046e4:	e9 95 00 00 00       	jmp    f010477e <_alltraps>
f01046e9:	90                   	nop

f01046ea <FPERR>:
TRAPHANDLER_NOEC(FPERR, T_FPERR)
f01046ea:	6a 00                	push   $0x0
f01046ec:	6a 10                	push   $0x10
f01046ee:	e9 8b 00 00 00       	jmp    f010477e <_alltraps>
f01046f3:	90                   	nop

f01046f4 <ALIGN>:
TRAPHANDLER(ALIGN, T_ALIGN)
f01046f4:	6a 11                	push   $0x11
f01046f6:	e9 83 00 00 00       	jmp    f010477e <_alltraps>
f01046fb:	90                   	nop

f01046fc <MCHK>:
TRAPHANDLER_NOEC(MCHK, T_MCHK)
f01046fc:	6a 00                	push   $0x0
f01046fe:	6a 12                	push   $0x12
f0104700:	eb 7c                	jmp    f010477e <_alltraps>

f0104702 <SIMDERR>:
TRAPHANDLER_NOEC(SIMDERR, T_SIMDERR)
f0104702:	6a 00                	push   $0x0
f0104704:	6a 13                	push   $0x13
f0104706:	eb 76                	jmp    f010477e <_alltraps>

f0104708 <SYSCALL>:
TRAPHANDLER_NOEC(SYSCALL, T_SYSCALL)
f0104708:	6a 00                	push   $0x0
f010470a:	6a 30                	push   $0x30
f010470c:	eb 70                	jmp    f010477e <_alltraps>

f010470e <DEFAULT>:
TRAPHANDLER_NOEC(DEFAULT, T_DEFAULT)
f010470e:	6a 00                	push   $0x0
f0104710:	68 f4 01 00 00       	push   $0x1f4
f0104715:	eb 67                	jmp    f010477e <_alltraps>
f0104717:	90                   	nop

f0104718 <IRQsHandler0>:
# IRQs
TRAPHANDLER_NOEC(IRQsHandler0, IRQ_OFFSET+IRQ_TIMER)
f0104718:	6a 00                	push   $0x0
f010471a:	6a 20                	push   $0x20
f010471c:	eb 60                	jmp    f010477e <_alltraps>

f010471e <IRQsHandler1>:
TRAPHANDLER_NOEC(IRQsHandler1, IRQ_OFFSET+IRQ_KBD)
f010471e:	6a 00                	push   $0x0
f0104720:	6a 21                	push   $0x21
f0104722:	eb 5a                	jmp    f010477e <_alltraps>

f0104724 <IRQsHandler2>:
TRAPHANDLER_NOEC(IRQsHandler2, IRQ_OFFSET+IRQ_SLAVE)
f0104724:	6a 00                	push   $0x0
f0104726:	6a 22                	push   $0x22
f0104728:	eb 54                	jmp    f010477e <_alltraps>

f010472a <IRQsHandler3>:
TRAPHANDLER_NOEC(IRQsHandler3, IRQ_OFFSET+3)
f010472a:	6a 00                	push   $0x0
f010472c:	6a 23                	push   $0x23
f010472e:	eb 4e                	jmp    f010477e <_alltraps>

f0104730 <IRQsHandler4>:
TRAPHANDLER_NOEC(IRQsHandler4, IRQ_OFFSET+IRQ_SERIAL)
f0104730:	6a 00                	push   $0x0
f0104732:	6a 24                	push   $0x24
f0104734:	eb 48                	jmp    f010477e <_alltraps>

f0104736 <IRQsHandler5>:
TRAPHANDLER_NOEC(IRQsHandler5, IRQ_OFFSET+5)
f0104736:	6a 00                	push   $0x0
f0104738:	6a 25                	push   $0x25
f010473a:	eb 42                	jmp    f010477e <_alltraps>

f010473c <IRQsHandler6>:
TRAPHANDLER_NOEC(IRQsHandler6, IRQ_OFFSET+6)
f010473c:	6a 00                	push   $0x0
f010473e:	6a 26                	push   $0x26
f0104740:	eb 3c                	jmp    f010477e <_alltraps>

f0104742 <IRQsHandler7>:
TRAPHANDLER_NOEC(IRQsHandler7, IRQ_OFFSET+IRQ_SPURIOUS)
f0104742:	6a 00                	push   $0x0
f0104744:	6a 27                	push   $0x27
f0104746:	eb 36                	jmp    f010477e <_alltraps>

f0104748 <IRQsHandler8>:
TRAPHANDLER_NOEC(IRQsHandler8, IRQ_OFFSET+8)
f0104748:	6a 00                	push   $0x0
f010474a:	6a 28                	push   $0x28
f010474c:	eb 30                	jmp    f010477e <_alltraps>

f010474e <IRQsHandler9>:
TRAPHANDLER_NOEC(IRQsHandler9, IRQ_OFFSET+9)
f010474e:	6a 00                	push   $0x0
f0104750:	6a 29                	push   $0x29
f0104752:	eb 2a                	jmp    f010477e <_alltraps>

f0104754 <IRQsHandler10>:
TRAPHANDLER_NOEC(IRQsHandler10, IRQ_OFFSET+10)
f0104754:	6a 00                	push   $0x0
f0104756:	6a 2a                	push   $0x2a
f0104758:	eb 24                	jmp    f010477e <_alltraps>

f010475a <IRQsHandler11>:
TRAPHANDLER_NOEC(IRQsHandler11, IRQ_OFFSET+11)
f010475a:	6a 00                	push   $0x0
f010475c:	6a 2b                	push   $0x2b
f010475e:	eb 1e                	jmp    f010477e <_alltraps>

f0104760 <IRQsHandler12>:
TRAPHANDLER_NOEC(IRQsHandler12, IRQ_OFFSET+12)
f0104760:	6a 00                	push   $0x0
f0104762:	6a 2c                	push   $0x2c
f0104764:	eb 18                	jmp    f010477e <_alltraps>

f0104766 <IRQsHandler13>:
TRAPHANDLER_NOEC(IRQsHandler13, IRQ_OFFSET+13)
f0104766:	6a 00                	push   $0x0
f0104768:	6a 2d                	push   $0x2d
f010476a:	eb 12                	jmp    f010477e <_alltraps>

f010476c <IRQsHandler14>:
TRAPHANDLER_NOEC(IRQsHandler14, IRQ_OFFSET+IRQ_IDE)
f010476c:	6a 00                	push   $0x0
f010476e:	6a 2e                	push   $0x2e
f0104770:	eb 0c                	jmp    f010477e <_alltraps>

f0104772 <IRQsHandler15>:
TRAPHANDLER_NOEC(IRQsHandler15, IRQ_OFFSET+15)
f0104772:	6a 00                	push   $0x0
f0104774:	6a 2f                	push   $0x2f
f0104776:	eb 06                	jmp    f010477e <_alltraps>

f0104778 <IRQsHandler19>:
; TRAPHANDLER_NOEC(IRQsHandler19, IRQ_OFFSET+IRQ_ERROR)
f0104778:	6a 00                	push   $0x0
f010477a:	6a 33                	push   $0x33
f010477c:	eb 00                	jmp    f010477e <_alltraps>

f010477e <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */
 .global _alltraps
 _alltraps:
 /* code below according to the guide */
pushl %ds
f010477e:	1e                   	push   %ds
pushl %es
f010477f:	06                   	push   %es
pushal
f0104780:	60                   	pusha  
movw $GD_KD, %ax
f0104781:	66 b8 10 00          	mov    $0x10,%ax
movw %ax, %ds
f0104785:	8e d8                	mov    %eax,%ds
movw %ax, %es
f0104787:	8e c0                	mov    %eax,%es
pushl %esp
f0104789:	54                   	push   %esp
call trap
f010478a:	e8 94 fc ff ff       	call   f0104423 <trap>

f010478f <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f010478f:	f3 0f 1e fb          	endbr32 
f0104793:	55                   	push   %ebp
f0104794:	89 e5                	mov    %esp,%ebp
f0104796:	83 ec 08             	sub    $0x8,%esp
f0104799:	a1 48 72 21 f0       	mov    0xf0217248,%eax
f010479e:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f01047a1:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f01047a6:	8b 02                	mov    (%edx),%eax
f01047a8:	83 e8 01             	sub    $0x1,%eax
		if ((envs[i].env_status == ENV_RUNNABLE ||
f01047ab:	83 f8 02             	cmp    $0x2,%eax
f01047ae:	76 2d                	jbe    f01047dd <sched_halt+0x4e>
	for (i = 0; i < NENV; i++) {
f01047b0:	83 c1 01             	add    $0x1,%ecx
f01047b3:	83 c2 7c             	add    $0x7c,%edx
f01047b6:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f01047bc:	75 e8                	jne    f01047a6 <sched_halt+0x17>
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
		cprintf("No runnable environments in the system!\n");
f01047be:	83 ec 0c             	sub    $0xc,%esp
f01047c1:	68 30 80 10 f0       	push   $0xf0108030
f01047c6:	e8 ef f1 ff ff       	call   f01039ba <cprintf>
f01047cb:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f01047ce:	83 ec 0c             	sub    $0xc,%esp
f01047d1:	6a 00                	push   $0x0
f01047d3:	e8 d1 c1 ff ff       	call   f01009a9 <monitor>
f01047d8:	83 c4 10             	add    $0x10,%esp
f01047db:	eb f1                	jmp    f01047ce <sched_halt+0x3f>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f01047dd:	e8 5c 19 00 00       	call   f010613e <cpunum>
f01047e2:	6b c0 74             	imul   $0x74,%eax,%eax
f01047e5:	c7 80 28 80 21 f0 00 	movl   $0x0,-0xfde7fd8(%eax)
f01047ec:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f01047ef:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01047f4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01047f9:	76 50                	jbe    f010484b <sched_halt+0xbc>
	return (physaddr_t)kva - KERNBASE;
f01047fb:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0104800:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0104803:	e8 36 19 00 00       	call   f010613e <cpunum>
f0104808:	6b d0 74             	imul   $0x74,%eax,%edx
f010480b:	83 c2 04             	add    $0x4,%edx
	asm volatile("lock; xchgl %0, %1"
f010480e:	b8 02 00 00 00       	mov    $0x2,%eax
f0104813:	f0 87 82 20 80 21 f0 	lock xchg %eax,-0xfde7fe0(%edx)
	spin_unlock(&kernel_lock);
f010481a:	83 ec 0c             	sub    $0xc,%esp
f010481d:	68 c0 33 12 f0       	push   $0xf01233c0
f0104822:	e8 3d 1c 00 00       	call   f0106464 <spin_unlock>
	asm volatile("pause");
f0104827:	f3 90                	pause  
		// Uncomment the following line after completing exercise 13
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104829:	e8 10 19 00 00       	call   f010613e <cpunum>
f010482e:	6b c0 74             	imul   $0x74,%eax,%eax
	asm volatile (
f0104831:	8b 80 30 80 21 f0    	mov    -0xfde7fd0(%eax),%eax
f0104837:	bd 00 00 00 00       	mov    $0x0,%ebp
f010483c:	89 c4                	mov    %eax,%esp
f010483e:	6a 00                	push   $0x0
f0104840:	6a 00                	push   $0x0
f0104842:	fb                   	sti    
f0104843:	f4                   	hlt    
f0104844:	eb fd                	jmp    f0104843 <sched_halt+0xb4>
}
f0104846:	83 c4 10             	add    $0x10,%esp
f0104849:	c9                   	leave  
f010484a:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010484b:	50                   	push   %eax
f010484c:	68 08 68 10 f0       	push   $0xf0106808
f0104851:	6a 56                	push   $0x56
f0104853:	68 59 80 10 f0       	push   $0xf0108059
f0104858:	e8 e3 b7 ff ff       	call   f0100040 <_panic>

f010485d <sched_yield>:
{
f010485d:	f3 0f 1e fb          	endbr32 
f0104861:	55                   	push   %ebp
f0104862:	89 e5                	mov    %esp,%ebp
f0104864:	56                   	push   %esi
f0104865:	53                   	push   %ebx
	if(curenv)
f0104866:	e8 d3 18 00 00       	call   f010613e <cpunum>
f010486b:	6b c0 74             	imul   $0x74,%eax,%eax
	int begin = 0;
f010486e:	b9 00 00 00 00       	mov    $0x0,%ecx
	if(curenv)
f0104873:	83 b8 28 80 21 f0 00 	cmpl   $0x0,-0xfde7fd8(%eax)
f010487a:	74 17                	je     f0104893 <sched_yield+0x36>
		begin = ENVX(curenv->env_id);
f010487c:	e8 bd 18 00 00       	call   f010613e <cpunum>
f0104881:	6b c0 74             	imul   $0x74,%eax,%eax
f0104884:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f010488a:	8b 48 48             	mov    0x48(%eax),%ecx
f010488d:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
		idle = &envs[(i+begin)%NENV];
f0104893:	8b 1d 48 72 21 f0    	mov    0xf0217248,%ebx
f0104899:	89 ca                	mov    %ecx,%edx
f010489b:	81 c1 00 04 00 00    	add    $0x400,%ecx
f01048a1:	89 d6                	mov    %edx,%esi
f01048a3:	c1 fe 1f             	sar    $0x1f,%esi
f01048a6:	c1 ee 16             	shr    $0x16,%esi
f01048a9:	8d 04 32             	lea    (%edx,%esi,1),%eax
f01048ac:	25 ff 03 00 00       	and    $0x3ff,%eax
f01048b1:	29 f0                	sub    %esi,%eax
f01048b3:	6b c0 7c             	imul   $0x7c,%eax,%eax
f01048b6:	01 d8                	add    %ebx,%eax
		if(idle->env_status == ENV_RUNNABLE)
f01048b8:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f01048bc:	74 38                	je     f01048f6 <sched_yield+0x99>
f01048be:	83 c2 01             	add    $0x1,%edx
	for(int i = 0;i<NENV;i++)
f01048c1:	39 ca                	cmp    %ecx,%edx
f01048c3:	75 dc                	jne    f01048a1 <sched_yield+0x44>
	if(!flag && curenv && curenv->env_status == ENV_RUNNING)
f01048c5:	e8 74 18 00 00       	call   f010613e <cpunum>
f01048ca:	6b c0 74             	imul   $0x74,%eax,%eax
f01048cd:	83 b8 28 80 21 f0 00 	cmpl   $0x0,-0xfde7fd8(%eax)
f01048d4:	74 14                	je     f01048ea <sched_yield+0x8d>
f01048d6:	e8 63 18 00 00       	call   f010613e <cpunum>
f01048db:	6b c0 74             	imul   $0x74,%eax,%eax
f01048de:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01048e4:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01048e8:	74 15                	je     f01048ff <sched_yield+0xa2>
		sched_halt();
f01048ea:	e8 a0 fe ff ff       	call   f010478f <sched_halt>
}
f01048ef:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01048f2:	5b                   	pop    %ebx
f01048f3:	5e                   	pop    %esi
f01048f4:	5d                   	pop    %ebp
f01048f5:	c3                   	ret    
			env_run(idle);
f01048f6:	83 ec 0c             	sub    $0xc,%esp
f01048f9:	50                   	push   %eax
f01048fa:	e8 3d ee ff ff       	call   f010373c <env_run>
		env_run(curenv);
f01048ff:	e8 3a 18 00 00       	call   f010613e <cpunum>
f0104904:	83 ec 0c             	sub    $0xc,%esp
f0104907:	6b c0 74             	imul   $0x74,%eax,%eax
f010490a:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0104910:	e8 27 ee ff ff       	call   f010373c <env_run>

f0104915 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104915:	f3 0f 1e fb          	endbr32 
f0104919:	55                   	push   %ebp
f010491a:	89 e5                	mov    %esp,%ebp
f010491c:	57                   	push   %edi
f010491d:	56                   	push   %esi
f010491e:	53                   	push   %ebx
f010491f:	83 ec 1c             	sub    $0x1c,%esp
f0104922:	8b 45 08             	mov    0x8(%ebp),%eax
f0104925:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104928:	83 f8 0e             	cmp    $0xe,%eax
f010492b:	77 08                	ja     f0104935 <syscall+0x20>
f010492d:	3e ff 24 85 6c 80 10 	notrack jmp *-0xfef7f94(,%eax,4)
f0104934:	f0 
	switch (syscallno) 
	{
		case SYS_cputs:
		{
			sys_cputs((const char*)a1,(size_t)a2);
			return 0;
f0104935:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010493a:	e9 9d 05 00 00       	jmp    f0104edc <syscall+0x5c7>
	user_mem_assert(curenv,s,len,0);
f010493f:	e8 fa 17 00 00       	call   f010613e <cpunum>
f0104944:	6a 00                	push   $0x0
f0104946:	57                   	push   %edi
f0104947:	ff 75 0c             	pushl  0xc(%ebp)
f010494a:	6b c0 74             	imul   $0x74,%eax,%eax
f010494d:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0104953:	e8 af e6 ff ff       	call   f0103007 <user_mem_assert>
	cprintf("%.*s", len, s);
f0104958:	83 c4 0c             	add    $0xc,%esp
f010495b:	ff 75 0c             	pushl  0xc(%ebp)
f010495e:	57                   	push   %edi
f010495f:	68 66 80 10 f0       	push   $0xf0108066
f0104964:	e8 51 f0 ff ff       	call   f01039ba <cprintf>
}
f0104969:	83 c4 10             	add    $0x10,%esp
			return 0;
f010496c:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0104971:	e9 66 05 00 00       	jmp    f0104edc <syscall+0x5c7>
	return cons_getc();
f0104976:	e8 ad bc ff ff       	call   f0100628 <cons_getc>
f010497b:	89 c3                	mov    %eax,%ebx
		}
		case SYS_cgetc:
		{
			return sys_cgetc();
f010497d:	e9 5a 05 00 00       	jmp    f0104edc <syscall+0x5c7>
	if ((r = envid2env(envid, &e, 1)) < 0)
f0104982:	83 ec 04             	sub    $0x4,%esp
f0104985:	6a 01                	push   $0x1
f0104987:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010498a:	50                   	push   %eax
f010498b:	ff 75 0c             	pushl  0xc(%ebp)
f010498e:	e8 65 e7 ff ff       	call   f01030f8 <envid2env>
f0104993:	89 c3                	mov    %eax,%ebx
f0104995:	83 c4 10             	add    $0x10,%esp
f0104998:	85 c0                	test   %eax,%eax
f010499a:	0f 88 3c 05 00 00    	js     f0104edc <syscall+0x5c7>
	env_destroy(e);
f01049a0:	83 ec 0c             	sub    $0xc,%esp
f01049a3:	ff 75 e4             	pushl  -0x1c(%ebp)
f01049a6:	e8 ea ec ff ff       	call   f0103695 <env_destroy>
	return 0;
f01049ab:	83 c4 10             	add    $0x10,%esp
f01049ae:	bb 00 00 00 00       	mov    $0x0,%ebx
		}
		case SYS_env_destroy:
		{
			return sys_env_destroy((envid_t)a1);
f01049b3:	e9 24 05 00 00       	jmp    f0104edc <syscall+0x5c7>
	return curenv->env_id;
f01049b8:	e8 81 17 00 00       	call   f010613e <cpunum>
f01049bd:	6b c0 74             	imul   $0x74,%eax,%eax
f01049c0:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01049c6:	8b 58 48             	mov    0x48(%eax),%ebx
		{
			return 0;
		}
		case SYS_getenvid:
		{
			return sys_getenvid();
f01049c9:	e9 0e 05 00 00       	jmp    f0104edc <syscall+0x5c7>
	sched_yield();
f01049ce:	e8 8a fe ff ff       	call   f010485d <sched_yield>
	struct Env* store_env = NULL;
f01049d3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = env_alloc(&store_env,curenv->env_id);
f01049da:	e8 5f 17 00 00       	call   f010613e <cpunum>
f01049df:	83 ec 08             	sub    $0x8,%esp
f01049e2:	6b c0 74             	imul   $0x74,%eax,%eax
f01049e5:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01049eb:	ff 70 48             	pushl  0x48(%eax)
f01049ee:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01049f1:	50                   	push   %eax
f01049f2:	e8 16 e8 ff ff       	call   f010320d <env_alloc>
f01049f7:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f01049f9:	83 c4 10             	add    $0x10,%esp
f01049fc:	85 c0                	test   %eax,%eax
f01049fe:	0f 88 d8 04 00 00    	js     f0104edc <syscall+0x5c7>
	store_env->env_status = ENV_NOT_RUNNABLE;
f0104a04:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a07:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	memmove(&store_env->env_tf,&curenv->env_tf,sizeof(curenv->env_tf));
f0104a0e:	e8 2b 17 00 00       	call   f010613e <cpunum>
f0104a13:	83 ec 04             	sub    $0x4,%esp
f0104a16:	6a 44                	push   $0x44
f0104a18:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a1b:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0104a21:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104a24:	e8 43 11 00 00       	call   f0105b6c <memmove>
	store_env->env_tf.tf_regs.reg_eax = 0;
f0104a29:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a2c:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return store_env->env_id;
f0104a33:	8b 58 48             	mov    0x48(%eax),%ebx
f0104a36:	83 c4 10             	add    $0x10,%esp
			sys_yield();
			return 0;
		}
		case SYS_exofork:
		{
			return sys_exofork();
f0104a39:	e9 9e 04 00 00       	jmp    f0104edc <syscall+0x5c7>
	if(status != ENV_NOT_RUNNABLE && status!= ENV_RUNNABLE)
f0104a3e:	8d 47 fe             	lea    -0x2(%edi),%eax
f0104a41:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f0104a46:	75 35                	jne    f0104a7d <syscall+0x168>
	struct Env* e = NULL;
f0104a48:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f0104a4f:	83 ec 04             	sub    $0x4,%esp
f0104a52:	6a 01                	push   $0x1
f0104a54:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104a57:	50                   	push   %eax
f0104a58:	ff 75 0c             	pushl  0xc(%ebp)
f0104a5b:	e8 98 e6 ff ff       	call   f01030f8 <envid2env>
f0104a60:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104a62:	83 c4 10             	add    $0x10,%esp
f0104a65:	85 c0                	test   %eax,%eax
f0104a67:	0f 88 6f 04 00 00    	js     f0104edc <syscall+0x5c7>
	e->env_status = status;
f0104a6d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a70:	89 78 54             	mov    %edi,0x54(%eax)
	return 0;
f0104a73:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104a78:	e9 5f 04 00 00       	jmp    f0104edc <syscall+0x5c7>
		return -E_INVAL;
f0104a7d:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		}
		case SYS_env_set_status:
		{
			return sys_env_set_status((envid_t)a1,(int)a2);
f0104a82:	e9 55 04 00 00       	jmp    f0104edc <syscall+0x5c7>
	if((uintptr_t)va >= UTOP || (uintptr_t)va % PGSIZE)
f0104a87:	81 ff ff ff bf ee    	cmp    $0xeebfffff,%edi
f0104a8d:	0f 87 81 00 00 00    	ja     f0104b14 <syscall+0x1ff>
f0104a93:	89 fb                	mov    %edi,%ebx
f0104a95:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
	if((perm & ~(PTE_SYSCALL)) || ((perm & needed_perm) != needed_perm))
f0104a9b:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a9e:	25 f8 f1 ff ff       	and    $0xfffff1f8,%eax
f0104aa3:	09 c3                	or     %eax,%ebx
f0104aa5:	75 77                	jne    f0104b1e <syscall+0x209>
f0104aa7:	8b 45 14             	mov    0x14(%ebp),%eax
f0104aaa:	83 e0 05             	and    $0x5,%eax
f0104aad:	83 f8 05             	cmp    $0x5,%eax
f0104ab0:	75 76                	jne    f0104b28 <syscall+0x213>
	struct Env* e = NULL;
f0104ab2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f0104ab9:	83 ec 04             	sub    $0x4,%esp
f0104abc:	6a 01                	push   $0x1
f0104abe:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104ac1:	50                   	push   %eax
f0104ac2:	ff 75 0c             	pushl  0xc(%ebp)
f0104ac5:	e8 2e e6 ff ff       	call   f01030f8 <envid2env>
	if(ret<0)
f0104aca:	83 c4 10             	add    $0x10,%esp
f0104acd:	85 c0                	test   %eax,%eax
f0104acf:	78 61                	js     f0104b32 <syscall+0x21d>
	struct PageInfo* pg = page_alloc(ALLOC_ZERO);
f0104ad1:	83 ec 0c             	sub    $0xc,%esp
f0104ad4:	6a 01                	push   $0x1
f0104ad6:	e8 f0 c4 ff ff       	call   f0100fcb <page_alloc>
f0104adb:	89 c6                	mov    %eax,%esi
	if(!pg)
f0104add:	83 c4 10             	add    $0x10,%esp
f0104ae0:	85 c0                	test   %eax,%eax
f0104ae2:	74 55                	je     f0104b39 <syscall+0x224>
	ret = page_insert(e->env_pgdir,pg,va,perm);
f0104ae4:	ff 75 14             	pushl  0x14(%ebp)
f0104ae7:	57                   	push   %edi
f0104ae8:	50                   	push   %eax
f0104ae9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104aec:	ff 70 60             	pushl  0x60(%eax)
f0104aef:	e8 8c c7 ff ff       	call   f0101280 <page_insert>
f0104af4:	89 c7                	mov    %eax,%edi
	if(ret < 0)
f0104af6:	83 c4 10             	add    $0x10,%esp
f0104af9:	85 c0                	test   %eax,%eax
f0104afb:	0f 89 db 03 00 00    	jns    f0104edc <syscall+0x5c7>
		page_free(pg);
f0104b01:	83 ec 0c             	sub    $0xc,%esp
f0104b04:	56                   	push   %esi
f0104b05:	e8 3a c5 ff ff       	call   f0101044 <page_free>
		return ret;
f0104b0a:	83 c4 10             	add    $0x10,%esp
f0104b0d:	89 fb                	mov    %edi,%ebx
f0104b0f:	e9 c8 03 00 00       	jmp    f0104edc <syscall+0x5c7>
		return -E_INVAL;
f0104b14:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104b19:	e9 be 03 00 00       	jmp    f0104edc <syscall+0x5c7>
		return -E_INVAL;
f0104b1e:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104b23:	e9 b4 03 00 00       	jmp    f0104edc <syscall+0x5c7>
f0104b28:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104b2d:	e9 aa 03 00 00       	jmp    f0104edc <syscall+0x5c7>
		return ret;
f0104b32:	89 c3                	mov    %eax,%ebx
f0104b34:	e9 a3 03 00 00       	jmp    f0104edc <syscall+0x5c7>
		return -E_NO_MEM;
f0104b39:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
		}
		case SYS_page_alloc:
		{
			return sys_page_alloc((envid_t)a1,(void*)a2,(int)a3);
f0104b3e:	e9 99 03 00 00       	jmp    f0104edc <syscall+0x5c7>
	if((uintptr_t)srcva>=UTOP || (uintptr_t)srcva % PGSIZE 
f0104b43:	81 ff ff ff bf ee    	cmp    $0xeebfffff,%edi
f0104b49:	0f 87 cf 00 00 00    	ja     f0104c1e <syscall+0x309>
	|| (uintptr_t)dstva>=UTOP || (uintptr_t)dstva % PGSIZE)
f0104b4f:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104b56:	0f 87 cc 00 00 00    	ja     f0104c28 <syscall+0x313>
	if((perm & ~(PTE_SYSCALL)) || ((perm & needed_perm) == 0))
f0104b5c:	89 f8                	mov    %edi,%eax
f0104b5e:	0b 45 18             	or     0x18(%ebp),%eax
f0104b61:	25 ff 0f 00 00       	and    $0xfff,%eax
f0104b66:	8b 55 1c             	mov    0x1c(%ebp),%edx
f0104b69:	81 e2 f8 f1 ff ff    	and    $0xfffff1f8,%edx
f0104b6f:	09 d0                	or     %edx,%eax
f0104b71:	0f 85 bb 00 00 00    	jne    f0104c32 <syscall+0x31d>
f0104b77:	f6 45 1c 05          	testb  $0x5,0x1c(%ebp)
f0104b7b:	0f 84 bb 00 00 00    	je     f0104c3c <syscall+0x327>
	struct Env* srce = NULL, *dste = NULL;
f0104b81:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0104b88:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	int ret = envid2env(srcenvid,&srce,true);
f0104b8f:	83 ec 04             	sub    $0x4,%esp
f0104b92:	6a 01                	push   $0x1
f0104b94:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0104b97:	50                   	push   %eax
f0104b98:	ff 75 0c             	pushl  0xc(%ebp)
f0104b9b:	e8 58 e5 ff ff       	call   f01030f8 <envid2env>
f0104ba0:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104ba2:	83 c4 10             	add    $0x10,%esp
f0104ba5:	85 c0                	test   %eax,%eax
f0104ba7:	0f 88 2f 03 00 00    	js     f0104edc <syscall+0x5c7>
	ret = envid2env(dstenvid,&dste,true);
f0104bad:	83 ec 04             	sub    $0x4,%esp
f0104bb0:	6a 01                	push   $0x1
f0104bb2:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104bb5:	50                   	push   %eax
f0104bb6:	ff 75 14             	pushl  0x14(%ebp)
f0104bb9:	e8 3a e5 ff ff       	call   f01030f8 <envid2env>
f0104bbe:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104bc0:	83 c4 10             	add    $0x10,%esp
f0104bc3:	85 c0                	test   %eax,%eax
f0104bc5:	0f 88 11 03 00 00    	js     f0104edc <syscall+0x5c7>
	pte_t* pte = NULL;
f0104bcb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	struct PageInfo* pg = page_lookup(srce->env_pgdir,srcva,&pte);
f0104bd2:	83 ec 04             	sub    $0x4,%esp
f0104bd5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104bd8:	50                   	push   %eax
f0104bd9:	57                   	push   %edi
f0104bda:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104bdd:	ff 70 60             	pushl  0x60(%eax)
f0104be0:	e8 a8 c5 ff ff       	call   f010118d <page_lookup>
	if(!pg)
f0104be5:	83 c4 10             	add    $0x10,%esp
f0104be8:	85 c0                	test   %eax,%eax
f0104bea:	74 5a                	je     f0104c46 <syscall+0x331>
	if(((*pte) & PTE_W) == 0 && (perm & PTE_W))
f0104bec:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104bef:	f6 02 02             	testb  $0x2,(%edx)
f0104bf2:	75 06                	jne    f0104bfa <syscall+0x2e5>
f0104bf4:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104bf8:	75 56                	jne    f0104c50 <syscall+0x33b>
	ret = page_insert(dste->env_pgdir,pg,dstva,perm);
f0104bfa:	ff 75 1c             	pushl  0x1c(%ebp)
f0104bfd:	ff 75 18             	pushl  0x18(%ebp)
f0104c00:	50                   	push   %eax
f0104c01:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104c04:	ff 70 60             	pushl  0x60(%eax)
f0104c07:	e8 74 c6 ff ff       	call   f0101280 <page_insert>
f0104c0c:	83 c4 10             	add    $0x10,%esp
f0104c0f:	85 c0                	test   %eax,%eax
f0104c11:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104c16:	0f 4e d8             	cmovle %eax,%ebx
f0104c19:	e9 be 02 00 00       	jmp    f0104edc <syscall+0x5c7>
		return -E_INVAL;
f0104c1e:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104c23:	e9 b4 02 00 00       	jmp    f0104edc <syscall+0x5c7>
f0104c28:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104c2d:	e9 aa 02 00 00       	jmp    f0104edc <syscall+0x5c7>
		return -E_INVAL;
f0104c32:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104c37:	e9 a0 02 00 00       	jmp    f0104edc <syscall+0x5c7>
f0104c3c:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104c41:	e9 96 02 00 00       	jmp    f0104edc <syscall+0x5c7>
		return -E_INVAL;
f0104c46:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104c4b:	e9 8c 02 00 00       	jmp    f0104edc <syscall+0x5c7>
		return -E_INVAL;
f0104c50:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		}
		case SYS_page_map:
		{
			return sys_page_map((envid_t)a1,(void*)a2,(envid_t)a3,(void*)a4,(int)a5);
f0104c55:	e9 82 02 00 00       	jmp    f0104edc <syscall+0x5c7>
	if((uintptr_t)va >= UTOP || (uintptr_t)va % PGSIZE)
f0104c5a:	81 ff ff ff bf ee    	cmp    $0xeebfffff,%edi
f0104c60:	77 49                	ja     f0104cab <syscall+0x396>
f0104c62:	f7 c7 ff 0f 00 00    	test   $0xfff,%edi
f0104c68:	75 4b                	jne    f0104cb5 <syscall+0x3a0>
	struct Env* e = NULL;
f0104c6a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f0104c71:	83 ec 04             	sub    $0x4,%esp
f0104c74:	6a 01                	push   $0x1
f0104c76:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104c79:	50                   	push   %eax
f0104c7a:	ff 75 0c             	pushl  0xc(%ebp)
f0104c7d:	e8 76 e4 ff ff       	call   f01030f8 <envid2env>
f0104c82:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104c84:	83 c4 10             	add    $0x10,%esp
f0104c87:	85 c0                	test   %eax,%eax
f0104c89:	0f 88 4d 02 00 00    	js     f0104edc <syscall+0x5c7>
	page_remove(e->env_pgdir,va);
f0104c8f:	83 ec 08             	sub    $0x8,%esp
f0104c92:	57                   	push   %edi
f0104c93:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104c96:	ff 70 60             	pushl  0x60(%eax)
f0104c99:	e8 91 c5 ff ff       	call   f010122f <page_remove>
	return 0;
f0104c9e:	83 c4 10             	add    $0x10,%esp
f0104ca1:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104ca6:	e9 31 02 00 00       	jmp    f0104edc <syscall+0x5c7>
		return -E_INVAL;
f0104cab:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104cb0:	e9 27 02 00 00       	jmp    f0104edc <syscall+0x5c7>
f0104cb5:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		}
		case SYS_page_unmap:
		{
			return sys_page_unmap((envid_t)a1,(void*)a2);
f0104cba:	e9 1d 02 00 00       	jmp    f0104edc <syscall+0x5c7>
	struct Env* e = NULL;
f0104cbf:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f0104cc6:	83 ec 04             	sub    $0x4,%esp
f0104cc9:	6a 01                	push   $0x1
f0104ccb:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104cce:	50                   	push   %eax
f0104ccf:	ff 75 0c             	pushl  0xc(%ebp)
f0104cd2:	e8 21 e4 ff ff       	call   f01030f8 <envid2env>
f0104cd7:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104cd9:	83 c4 10             	add    $0x10,%esp
f0104cdc:	85 c0                	test   %eax,%eax
f0104cde:	0f 88 f8 01 00 00    	js     f0104edc <syscall+0x5c7>
	e->env_pgfault_upcall = func;
f0104ce4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104ce7:	89 78 64             	mov    %edi,0x64(%eax)
	return 0;
f0104cea:	bb 00 00 00 00       	mov    $0x0,%ebx
		}
		case SYS_env_set_pgfault_upcall:
		{
			return sys_env_set_pgfault_upcall((envid_t)a1,(void*)a2);
f0104cef:	e9 e8 01 00 00       	jmp    f0104edc <syscall+0x5c7>
	struct Env* dst = NULL;
f0104cf4:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	if((ret = envid2env(envid,&dst,false)) < 0)
f0104cfb:	83 ec 04             	sub    $0x4,%esp
f0104cfe:	6a 00                	push   $0x0
f0104d00:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104d03:	50                   	push   %eax
f0104d04:	ff 75 0c             	pushl  0xc(%ebp)
f0104d07:	e8 ec e3 ff ff       	call   f01030f8 <envid2env>
f0104d0c:	89 c3                	mov    %eax,%ebx
f0104d0e:	83 c4 10             	add    $0x10,%esp
f0104d11:	85 c0                	test   %eax,%eax
f0104d13:	0f 88 c3 01 00 00    	js     f0104edc <syscall+0x5c7>
	if(!dst->env_ipc_recving)
f0104d19:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104d1c:	80 78 68 00          	cmpb   $0x0,0x68(%eax)
f0104d20:	0f 84 f1 00 00 00    	je     f0104e17 <syscall+0x502>
	dst->env_ipc_perm = 0;
f0104d26:	c7 40 78 00 00 00 00 	movl   $0x0,0x78(%eax)
	if((uintptr_t)srcva < UTOP)
f0104d2d:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f0104d34:	0f 87 9b 00 00 00    	ja     f0104dd5 <syscall+0x4c0>
		if(((perm_needed & perm) != perm_needed) || (perm & (~PTE_SYSCALL)))
f0104d3a:	8b 45 18             	mov    0x18(%ebp),%eax
f0104d3d:	83 e0 05             	and    $0x5,%eax
			return -E_INVAL;
f0104d40:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		if(((perm_needed & perm) != perm_needed) || (perm & (~PTE_SYSCALL)))
f0104d45:	83 f8 05             	cmp    $0x5,%eax
f0104d48:	0f 85 8e 01 00 00    	jne    f0104edc <syscall+0x5c7>
		if((uintptr_t)srcva % PGSIZE)
f0104d4e:	8b 55 14             	mov    0x14(%ebp),%edx
f0104d51:	81 e2 ff 0f 00 00    	and    $0xfff,%edx
		if(((perm_needed & perm) != perm_needed) || (perm & (~PTE_SYSCALL)))
f0104d57:	8b 45 18             	mov    0x18(%ebp),%eax
f0104d5a:	25 f8 f1 ff ff       	and    $0xfffff1f8,%eax
f0104d5f:	09 c2                	or     %eax,%edx
f0104d61:	0f 85 75 01 00 00    	jne    f0104edc <syscall+0x5c7>
		pte_t* pte = NULL;
f0104d67:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		struct PageInfo* pg = page_lookup(curenv->env_pgdir,srcva,&pte);
f0104d6e:	e8 cb 13 00 00       	call   f010613e <cpunum>
f0104d73:	83 ec 04             	sub    $0x4,%esp
f0104d76:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104d79:	52                   	push   %edx
f0104d7a:	ff 75 14             	pushl  0x14(%ebp)
f0104d7d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104d80:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0104d86:	ff 70 60             	pushl  0x60(%eax)
f0104d89:	e8 ff c3 ff ff       	call   f010118d <page_lookup>
		if(!pg)
f0104d8e:	83 c4 10             	add    $0x10,%esp
f0104d91:	85 c0                	test   %eax,%eax
f0104d93:	74 78                	je     f0104e0d <syscall+0x4f8>
		if((perm & PTE_W) && !(*pte & PTE_W))
f0104d95:	f6 45 18 02          	testb  $0x2,0x18(%ebp)
f0104d99:	74 0c                	je     f0104da7 <syscall+0x492>
f0104d9b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104d9e:	f6 02 02             	testb  $0x2,(%edx)
f0104da1:	0f 84 35 01 00 00    	je     f0104edc <syscall+0x5c7>
		if((uintptr_t)(dst->env_ipc_dstva)<UTOP)
f0104da7:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0104daa:	8b 4a 6c             	mov    0x6c(%edx),%ecx
f0104dad:	81 f9 ff ff bf ee    	cmp    $0xeebfffff,%ecx
f0104db3:	77 06                	ja     f0104dbb <syscall+0x4a6>
			dst->env_ipc_perm = perm;
f0104db5:	8b 75 18             	mov    0x18(%ebp),%esi
f0104db8:	89 72 78             	mov    %esi,0x78(%edx)
		if((ret = page_insert(dst->env_pgdir,pg,dst->env_ipc_dstva,perm)) < 0)
f0104dbb:	ff 75 18             	pushl  0x18(%ebp)
f0104dbe:	51                   	push   %ecx
f0104dbf:	50                   	push   %eax
f0104dc0:	ff 72 60             	pushl  0x60(%edx)
f0104dc3:	e8 b8 c4 ff ff       	call   f0101280 <page_insert>
f0104dc8:	89 c3                	mov    %eax,%ebx
f0104dca:	83 c4 10             	add    $0x10,%esp
f0104dcd:	85 c0                	test   %eax,%eax
f0104dcf:	0f 88 07 01 00 00    	js     f0104edc <syscall+0x5c7>
	dst->env_ipc_from = curenv->env_id;
f0104dd5:	e8 64 13 00 00       	call   f010613e <cpunum>
f0104dda:	89 c2                	mov    %eax,%edx
f0104ddc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104ddf:	6b d2 74             	imul   $0x74,%edx,%edx
f0104de2:	8b 92 28 80 21 f0    	mov    -0xfde7fd8(%edx),%edx
f0104de8:	8b 52 48             	mov    0x48(%edx),%edx
f0104deb:	89 50 74             	mov    %edx,0x74(%eax)
	dst->env_ipc_value = value;
f0104dee:	89 78 70             	mov    %edi,0x70(%eax)
	dst->env_ipc_recving = 0;
f0104df1:	c6 40 68 00          	movb   $0x0,0x68(%eax)
	dst->env_status = ENV_RUNNABLE;
f0104df5:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	dst->env_tf.tf_regs.reg_eax = 0;
f0104dfc:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return 0;
f0104e03:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104e08:	e9 cf 00 00 00       	jmp    f0104edc <syscall+0x5c7>
			return -E_INVAL;
f0104e0d:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104e12:	e9 c5 00 00 00       	jmp    f0104edc <syscall+0x5c7>
		return -E_IPC_NOT_RECV;
f0104e17:	bb f9 ff ff ff       	mov    $0xfffffff9,%ebx
		}
		case SYS_ipc_try_send:
		{
			return sys_ipc_try_send((envid_t)a1,(uint32_t)a2,(void*)a3,(unsigned int)a4);
f0104e1c:	e9 bb 00 00 00       	jmp    f0104edc <syscall+0x5c7>
	if((uintptr_t)dstva<UTOP && (uintptr_t)dstva%PGSIZE)
f0104e21:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f0104e28:	77 13                	ja     f0104e3d <syscall+0x528>
f0104e2a:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
f0104e31:	74 0a                	je     f0104e3d <syscall+0x528>
		}
		case SYS_ipc_recv:
		{
			return sys_ipc_recv((void*)a1);
f0104e33:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104e38:	e9 9f 00 00 00       	jmp    f0104edc <syscall+0x5c7>
	curenv->env_ipc_recving = 1;
f0104e3d:	e8 fc 12 00 00       	call   f010613e <cpunum>
f0104e42:	6b c0 74             	imul   $0x74,%eax,%eax
f0104e45:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0104e4b:	c6 40 68 01          	movb   $0x1,0x68(%eax)
	curenv->env_ipc_dstva = dstva;
f0104e4f:	e8 ea 12 00 00       	call   f010613e <cpunum>
f0104e54:	6b c0 74             	imul   $0x74,%eax,%eax
f0104e57:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0104e5d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104e60:	89 48 6c             	mov    %ecx,0x6c(%eax)
	curenv->env_status = ENV_NOT_RUNNABLE;
f0104e63:	e8 d6 12 00 00       	call   f010613e <cpunum>
f0104e68:	6b c0 74             	imul   $0x74,%eax,%eax
f0104e6b:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0104e71:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	sched_yield();
f0104e78:	e8 e0 f9 ff ff       	call   f010485d <sched_yield>
		}
		case SYS_env_set_trapframe:
		{
			return sys_env_set_trapframe((envid_t)a1,(struct Trapframe*)a2);
f0104e7d:	89 fe                	mov    %edi,%esi
	struct Env* e = NULL;
f0104e7f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	if(envid2env(envid,&e,1) < 0)
f0104e86:	83 ec 04             	sub    $0x4,%esp
f0104e89:	6a 01                	push   $0x1
f0104e8b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104e8e:	50                   	push   %eax
f0104e8f:	ff 75 0c             	pushl  0xc(%ebp)
f0104e92:	e8 61 e2 ff ff       	call   f01030f8 <envid2env>
f0104e97:	83 c4 10             	add    $0x10,%esp
f0104e9a:	85 c0                	test   %eax,%eax
f0104e9c:	78 32                	js     f0104ed0 <syscall+0x5bb>
	user_mem_assert(e,(const void*)tf,sizeof(struct Trapframe),PTE_U|PTE_P);
f0104e9e:	6a 05                	push   $0x5
f0104ea0:	6a 44                	push   $0x44
f0104ea2:	57                   	push   %edi
f0104ea3:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104ea6:	e8 5c e1 ff ff       	call   f0103007 <user_mem_assert>
	tf->tf_eflags &= ~FL_IOPL_MASK;
f0104eab:	8b 47 38             	mov    0x38(%edi),%eax
f0104eae:	80 e4 cf             	and    $0xcf,%ah
f0104eb1:	80 cc 02             	or     $0x2,%ah
f0104eb4:	89 47 38             	mov    %eax,0x38(%edi)
	tf->tf_cs |= 3;
f0104eb7:	66 83 4f 34 03       	orw    $0x3,0x34(%edi)
	e->env_tf = *tf;
f0104ebc:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104ec1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104ec4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	return 0;
f0104ec6:	83 c4 10             	add    $0x10,%esp
f0104ec9:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104ece:	eb 0c                	jmp    f0104edc <syscall+0x5c7>
		return -E_BAD_ENV;
f0104ed0:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
			return sys_env_set_trapframe((envid_t)a1,(struct Trapframe*)a2);
f0104ed5:	eb 05                	jmp    f0104edc <syscall+0x5c7>
			return 0;
f0104ed7:	bb 00 00 00 00       	mov    $0x0,%ebx
		}
		default:
			return -E_INVAL;
	}
}
f0104edc:	89 d8                	mov    %ebx,%eax
f0104ede:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104ee1:	5b                   	pop    %ebx
f0104ee2:	5e                   	pop    %esi
f0104ee3:	5f                   	pop    %edi
f0104ee4:	5d                   	pop    %ebp
f0104ee5:	c3                   	ret    

f0104ee6 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104ee6:	55                   	push   %ebp
f0104ee7:	89 e5                	mov    %esp,%ebp
f0104ee9:	57                   	push   %edi
f0104eea:	56                   	push   %esi
f0104eeb:	53                   	push   %ebx
f0104eec:	83 ec 14             	sub    $0x14,%esp
f0104eef:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104ef2:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104ef5:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104ef8:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104efb:	8b 1a                	mov    (%edx),%ebx
f0104efd:	8b 01                	mov    (%ecx),%eax
f0104eff:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104f02:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104f09:	eb 23                	jmp    f0104f2e <stab_binsearch+0x48>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104f0b:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0104f0e:	eb 1e                	jmp    f0104f2e <stab_binsearch+0x48>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104f10:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104f13:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104f16:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104f1a:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104f1d:	73 46                	jae    f0104f65 <stab_binsearch+0x7f>
			*region_left = m;
f0104f1f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104f22:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104f24:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f0104f27:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0104f2e:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104f31:	7f 5f                	jg     f0104f92 <stab_binsearch+0xac>
		int true_m = (l + r) / 2, m = true_m;
f0104f33:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104f36:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f0104f39:	89 d0                	mov    %edx,%eax
f0104f3b:	c1 e8 1f             	shr    $0x1f,%eax
f0104f3e:	01 d0                	add    %edx,%eax
f0104f40:	89 c7                	mov    %eax,%edi
f0104f42:	d1 ff                	sar    %edi
f0104f44:	83 e0 fe             	and    $0xfffffffe,%eax
f0104f47:	01 f8                	add    %edi,%eax
f0104f49:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104f4c:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0104f50:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f0104f52:	39 c3                	cmp    %eax,%ebx
f0104f54:	7f b5                	jg     f0104f0b <stab_binsearch+0x25>
f0104f56:	0f b6 0a             	movzbl (%edx),%ecx
f0104f59:	83 ea 0c             	sub    $0xc,%edx
f0104f5c:	39 f1                	cmp    %esi,%ecx
f0104f5e:	74 b0                	je     f0104f10 <stab_binsearch+0x2a>
			m--;
f0104f60:	83 e8 01             	sub    $0x1,%eax
f0104f63:	eb ed                	jmp    f0104f52 <stab_binsearch+0x6c>
		} else if (stabs[m].n_value > addr) {
f0104f65:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104f68:	76 14                	jbe    f0104f7e <stab_binsearch+0x98>
			*region_right = m - 1;
f0104f6a:	83 e8 01             	sub    $0x1,%eax
f0104f6d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104f70:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104f73:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f0104f75:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104f7c:	eb b0                	jmp    f0104f2e <stab_binsearch+0x48>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104f7e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104f81:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0104f83:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104f87:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f0104f89:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104f90:	eb 9c                	jmp    f0104f2e <stab_binsearch+0x48>
		}
	}

	if (!any_matches)
f0104f92:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104f96:	75 15                	jne    f0104fad <stab_binsearch+0xc7>
		*region_right = *region_left - 1;
f0104f98:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104f9b:	8b 00                	mov    (%eax),%eax
f0104f9d:	83 e8 01             	sub    $0x1,%eax
f0104fa0:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104fa3:	89 07                	mov    %eax,(%edi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0104fa5:	83 c4 14             	add    $0x14,%esp
f0104fa8:	5b                   	pop    %ebx
f0104fa9:	5e                   	pop    %esi
f0104faa:	5f                   	pop    %edi
f0104fab:	5d                   	pop    %ebp
f0104fac:	c3                   	ret    
		for (l = *region_right;
f0104fad:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104fb0:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104fb2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104fb5:	8b 0f                	mov    (%edi),%ecx
f0104fb7:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104fba:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0104fbd:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
		for (l = *region_right;
f0104fc1:	eb 03                	jmp    f0104fc6 <stab_binsearch+0xe0>
		     l--)
f0104fc3:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0104fc6:	39 c1                	cmp    %eax,%ecx
f0104fc8:	7d 0a                	jge    f0104fd4 <stab_binsearch+0xee>
		     l > *region_left && stabs[l].n_type != type;
f0104fca:	0f b6 1a             	movzbl (%edx),%ebx
f0104fcd:	83 ea 0c             	sub    $0xc,%edx
f0104fd0:	39 f3                	cmp    %esi,%ebx
f0104fd2:	75 ef                	jne    f0104fc3 <stab_binsearch+0xdd>
		*region_left = l;
f0104fd4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104fd7:	89 07                	mov    %eax,(%edi)
}
f0104fd9:	eb ca                	jmp    f0104fa5 <stab_binsearch+0xbf>

f0104fdb <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104fdb:	f3 0f 1e fb          	endbr32 
f0104fdf:	55                   	push   %ebp
f0104fe0:	89 e5                	mov    %esp,%ebp
f0104fe2:	57                   	push   %edi
f0104fe3:	56                   	push   %esi
f0104fe4:	53                   	push   %ebx
f0104fe5:	83 ec 4c             	sub    $0x4c,%esp
f0104fe8:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104feb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104fee:	c7 03 a8 80 10 f0    	movl   $0xf01080a8,(%ebx)
	info->eip_line = 0;
f0104ff4:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0104ffb:	c7 43 08 a8 80 10 f0 	movl   $0xf01080a8,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0105002:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0105009:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010500c:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0105013:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0105019:	0f 86 32 01 00 00    	jbe    f0105151 <debuginfo_eip+0x176>
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010501f:	c7 45 b4 1f 8c 11 f0 	movl   $0xf0118c1f,-0x4c(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0105026:	c7 45 b8 d1 53 11 f0 	movl   $0xf01153d1,-0x48(%ebp)
		stab_end = __STAB_END__;
f010502d:	be d0 53 11 f0       	mov    $0xf01153d0,%esi
		stabs = __STAB_BEGIN__;
f0105032:	c7 45 bc 50 86 10 f0 	movl   $0xf0108650,-0x44(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0105039:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f010503c:	39 4d b8             	cmp    %ecx,-0x48(%ebp)
f010503f:	0f 83 62 02 00 00    	jae    f01052a7 <debuginfo_eip+0x2cc>
f0105045:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0105049:	0f 85 5f 02 00 00    	jne    f01052ae <debuginfo_eip+0x2d3>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010504f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0105056:	2b 75 bc             	sub    -0x44(%ebp),%esi
f0105059:	c1 fe 02             	sar    $0x2,%esi
f010505c:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0105062:	83 e8 01             	sub    $0x1,%eax
f0105065:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0105068:	83 ec 08             	sub    $0x8,%esp
f010506b:	57                   	push   %edi
f010506c:	6a 64                	push   $0x64
f010506e:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0105071:	89 d1                	mov    %edx,%ecx
f0105073:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0105076:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0105079:	89 f0                	mov    %esi,%eax
f010507b:	e8 66 fe ff ff       	call   f0104ee6 <stab_binsearch>
	if (lfile == 0)
f0105080:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105083:	83 c4 10             	add    $0x10,%esp
f0105086:	85 c0                	test   %eax,%eax
f0105088:	0f 84 27 02 00 00    	je     f01052b5 <debuginfo_eip+0x2da>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010508e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0105091:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105094:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0105097:	83 ec 08             	sub    $0x8,%esp
f010509a:	57                   	push   %edi
f010509b:	6a 24                	push   $0x24
f010509d:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01050a0:	89 d1                	mov    %edx,%ecx
f01050a2:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01050a5:	89 f0                	mov    %esi,%eax
f01050a7:	e8 3a fe ff ff       	call   f0104ee6 <stab_binsearch>

	if (lfun <= rfun) {
f01050ac:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01050af:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01050b2:	83 c4 10             	add    $0x10,%esp
f01050b5:	39 d0                	cmp    %edx,%eax
f01050b7:	0f 8f 34 01 00 00    	jg     f01051f1 <debuginfo_eip+0x216>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01050bd:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01050c0:	8d 34 8e             	lea    (%esi,%ecx,4),%esi
f01050c3:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f01050c6:	8b 36                	mov    (%esi),%esi
f01050c8:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f01050cb:	2b 4d b8             	sub    -0x48(%ebp),%ecx
f01050ce:	39 ce                	cmp    %ecx,%esi
f01050d0:	73 06                	jae    f01050d8 <debuginfo_eip+0xfd>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01050d2:	03 75 b8             	add    -0x48(%ebp),%esi
f01050d5:	89 73 08             	mov    %esi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01050d8:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01050db:	8b 4e 08             	mov    0x8(%esi),%ecx
f01050de:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01050e1:	29 cf                	sub    %ecx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f01050e3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01050e6:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01050e9:	83 ec 08             	sub    $0x8,%esp
f01050ec:	6a 3a                	push   $0x3a
f01050ee:	ff 73 08             	pushl  0x8(%ebx)
f01050f1:	e8 0a 0a 00 00       	call   f0105b00 <strfind>
f01050f6:	2b 43 08             	sub    0x8(%ebx),%eax
f01050f9:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	info->eip_file = stabstr +stabs[lfile].n_strx;
f01050fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01050ff:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0105102:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0105105:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0105108:	03 0c 86             	add    (%esi,%eax,4),%ecx
f010510b:	89 0b                	mov    %ecx,(%ebx)
	stab_binsearch(stabs, &lline, &rline,N_SLINE,addr);
f010510d:	83 c4 08             	add    $0x8,%esp
f0105110:	57                   	push   %edi
f0105111:	6a 44                	push   $0x44
f0105113:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0105116:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0105119:	89 f0                	mov    %esi,%eax
f010511b:	e8 c6 fd ff ff       	call   f0104ee6 <stab_binsearch>
	if(lline>rline)
f0105120:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0105123:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0105126:	83 c4 10             	add    $0x10,%esp
f0105129:	39 c2                	cmp    %eax,%edx
f010512b:	0f 8f 8b 01 00 00    	jg     f01052bc <debuginfo_eip+0x2e1>
	{
		return -1;
	}
	else
	{
		info->eip_line = stabs[rline].n_desc;
f0105131:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0105134:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0105139:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010513c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010513f:	89 d0                	mov    %edx,%eax
f0105141:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0105144:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
f0105148:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f010514c:	e9 be 00 00 00       	jmp    f010520f <debuginfo_eip+0x234>
		if(user_mem_check(curenv,usd,sizeof(struct UserStabData),PTE_P|PTE_U) != 0)
f0105151:	e8 e8 0f 00 00       	call   f010613e <cpunum>
f0105156:	6a 05                	push   $0x5
f0105158:	6a 10                	push   $0x10
f010515a:	68 00 00 20 00       	push   $0x200000
f010515f:	6b c0 74             	imul   $0x74,%eax,%eax
f0105162:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0105168:	e8 0e de ff ff       	call   f0102f7b <user_mem_check>
f010516d:	83 c4 10             	add    $0x10,%esp
f0105170:	85 c0                	test   %eax,%eax
f0105172:	0f 85 21 01 00 00    	jne    f0105299 <debuginfo_eip+0x2be>
		stabs = usd->stabs;
f0105178:	a1 00 00 20 00       	mov    0x200000,%eax
f010517d:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stab_end = usd->stab_end;
f0105180:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f0105186:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f010518c:	89 4d b8             	mov    %ecx,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f010518f:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0105195:	89 55 b4             	mov    %edx,-0x4c(%ebp)
		if(user_mem_check(curenv,stabs,sizeof(struct Stab),PTE_P|PTE_U) != 0)
f0105198:	e8 a1 0f 00 00       	call   f010613e <cpunum>
f010519d:	6a 05                	push   $0x5
f010519f:	6a 0c                	push   $0xc
f01051a1:	ff 75 bc             	pushl  -0x44(%ebp)
f01051a4:	6b c0 74             	imul   $0x74,%eax,%eax
f01051a7:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f01051ad:	e8 c9 dd ff ff       	call   f0102f7b <user_mem_check>
f01051b2:	83 c4 10             	add    $0x10,%esp
f01051b5:	85 c0                	test   %eax,%eax
f01051b7:	0f 85 e3 00 00 00    	jne    f01052a0 <debuginfo_eip+0x2c5>
		if(user_mem_check(curenv,stabstr,stabstr_end-stabstr,PTE_P|PTE_U) != 0)
f01051bd:	e8 7c 0f 00 00       	call   f010613e <cpunum>
f01051c2:	6a 05                	push   $0x5
f01051c4:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f01051c7:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f01051ca:	29 ca                	sub    %ecx,%edx
f01051cc:	52                   	push   %edx
f01051cd:	51                   	push   %ecx
f01051ce:	6b c0 74             	imul   $0x74,%eax,%eax
f01051d1:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f01051d7:	e8 9f dd ff ff       	call   f0102f7b <user_mem_check>
f01051dc:	83 c4 10             	add    $0x10,%esp
f01051df:	85 c0                	test   %eax,%eax
f01051e1:	0f 84 52 fe ff ff    	je     f0105039 <debuginfo_eip+0x5e>
			return -1;
f01051e7:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01051ec:	e9 d7 00 00 00       	jmp    f01052c8 <debuginfo_eip+0x2ed>
		info->eip_fn_addr = addr;
f01051f1:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f01051f4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01051f7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01051fa:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01051fd:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0105200:	e9 e4 fe ff ff       	jmp    f01050e9 <debuginfo_eip+0x10e>
f0105205:	83 e8 01             	sub    $0x1,%eax
f0105208:	83 ea 0c             	sub    $0xc,%edx
	while (lline >= lfile
f010520b:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f010520f:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0105212:	39 c7                	cmp    %eax,%edi
f0105214:	7f 43                	jg     f0105259 <debuginfo_eip+0x27e>
	       && stabs[lline].n_type != N_SOL
f0105216:	0f b6 0a             	movzbl (%edx),%ecx
f0105219:	80 f9 84             	cmp    $0x84,%cl
f010521c:	74 19                	je     f0105237 <debuginfo_eip+0x25c>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010521e:	80 f9 64             	cmp    $0x64,%cl
f0105221:	75 e2                	jne    f0105205 <debuginfo_eip+0x22a>
f0105223:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0105227:	74 dc                	je     f0105205 <debuginfo_eip+0x22a>
f0105229:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f010522d:	74 11                	je     f0105240 <debuginfo_eip+0x265>
f010522f:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0105232:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0105235:	eb 09                	jmp    f0105240 <debuginfo_eip+0x265>
f0105237:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f010523b:	74 03                	je     f0105240 <debuginfo_eip+0x265>
f010523d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0105240:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0105243:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0105246:	8b 04 87             	mov    (%edi,%eax,4),%eax
f0105249:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f010524c:	8b 7d b8             	mov    -0x48(%ebp),%edi
f010524f:	29 fa                	sub    %edi,%edx
f0105251:	39 d0                	cmp    %edx,%eax
f0105253:	73 04                	jae    f0105259 <debuginfo_eip+0x27e>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0105255:	01 f8                	add    %edi,%eax
f0105257:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0105259:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010525c:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010525f:	ba 00 00 00 00       	mov    $0x0,%edx
	if (lfun < rfun)
f0105264:	39 f0                	cmp    %esi,%eax
f0105266:	7d 60                	jge    f01052c8 <debuginfo_eip+0x2ed>
		for (lline = lfun + 1;
f0105268:	8d 50 01             	lea    0x1(%eax),%edx
f010526b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010526e:	89 d0                	mov    %edx,%eax
f0105270:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0105273:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0105276:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
f010527a:	eb 04                	jmp    f0105280 <debuginfo_eip+0x2a5>
			info->eip_fn_narg++;
f010527c:	83 43 14 01          	addl   $0x1,0x14(%ebx)
		for (lline = lfun + 1;
f0105280:	39 c6                	cmp    %eax,%esi
f0105282:	7e 3f                	jle    f01052c3 <debuginfo_eip+0x2e8>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0105284:	0f b6 0a             	movzbl (%edx),%ecx
f0105287:	83 c0 01             	add    $0x1,%eax
f010528a:	83 c2 0c             	add    $0xc,%edx
f010528d:	80 f9 a0             	cmp    $0xa0,%cl
f0105290:	74 ea                	je     f010527c <debuginfo_eip+0x2a1>
	return 0;
f0105292:	ba 00 00 00 00       	mov    $0x0,%edx
f0105297:	eb 2f                	jmp    f01052c8 <debuginfo_eip+0x2ed>
			return -1;
f0105299:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010529e:	eb 28                	jmp    f01052c8 <debuginfo_eip+0x2ed>
			return -1;
f01052a0:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052a5:	eb 21                	jmp    f01052c8 <debuginfo_eip+0x2ed>
		return -1;
f01052a7:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052ac:	eb 1a                	jmp    f01052c8 <debuginfo_eip+0x2ed>
f01052ae:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052b3:	eb 13                	jmp    f01052c8 <debuginfo_eip+0x2ed>
		return -1;
f01052b5:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052ba:	eb 0c                	jmp    f01052c8 <debuginfo_eip+0x2ed>
		return -1;
f01052bc:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052c1:	eb 05                	jmp    f01052c8 <debuginfo_eip+0x2ed>
	return 0;
f01052c3:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01052c8:	89 d0                	mov    %edx,%eax
f01052ca:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01052cd:	5b                   	pop    %ebx
f01052ce:	5e                   	pop    %esi
f01052cf:	5f                   	pop    %edi
f01052d0:	5d                   	pop    %ebp
f01052d1:	c3                   	ret    

f01052d2 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01052d2:	55                   	push   %ebp
f01052d3:	89 e5                	mov    %esp,%ebp
f01052d5:	57                   	push   %edi
f01052d6:	56                   	push   %esi
f01052d7:	53                   	push   %ebx
f01052d8:	83 ec 1c             	sub    $0x1c,%esp
f01052db:	89 c7                	mov    %eax,%edi
f01052dd:	89 d6                	mov    %edx,%esi
f01052df:	8b 45 08             	mov    0x8(%ebp),%eax
f01052e2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01052e5:	89 d1                	mov    %edx,%ecx
f01052e7:	89 c2                	mov    %eax,%edx
f01052e9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01052ec:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01052ef:	8b 45 10             	mov    0x10(%ebp),%eax
f01052f2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01052f5:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01052f8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01052ff:	39 c2                	cmp    %eax,%edx
f0105301:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f0105304:	72 3e                	jb     f0105344 <printnum+0x72>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0105306:	83 ec 0c             	sub    $0xc,%esp
f0105309:	ff 75 18             	pushl  0x18(%ebp)
f010530c:	83 eb 01             	sub    $0x1,%ebx
f010530f:	53                   	push   %ebx
f0105310:	50                   	push   %eax
f0105311:	83 ec 08             	sub    $0x8,%esp
f0105314:	ff 75 e4             	pushl  -0x1c(%ebp)
f0105317:	ff 75 e0             	pushl  -0x20(%ebp)
f010531a:	ff 75 dc             	pushl  -0x24(%ebp)
f010531d:	ff 75 d8             	pushl  -0x28(%ebp)
f0105320:	e8 2b 12 00 00       	call   f0106550 <__udivdi3>
f0105325:	83 c4 18             	add    $0x18,%esp
f0105328:	52                   	push   %edx
f0105329:	50                   	push   %eax
f010532a:	89 f2                	mov    %esi,%edx
f010532c:	89 f8                	mov    %edi,%eax
f010532e:	e8 9f ff ff ff       	call   f01052d2 <printnum>
f0105333:	83 c4 20             	add    $0x20,%esp
f0105336:	eb 13                	jmp    f010534b <printnum+0x79>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0105338:	83 ec 08             	sub    $0x8,%esp
f010533b:	56                   	push   %esi
f010533c:	ff 75 18             	pushl  0x18(%ebp)
f010533f:	ff d7                	call   *%edi
f0105341:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0105344:	83 eb 01             	sub    $0x1,%ebx
f0105347:	85 db                	test   %ebx,%ebx
f0105349:	7f ed                	jg     f0105338 <printnum+0x66>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010534b:	83 ec 08             	sub    $0x8,%esp
f010534e:	56                   	push   %esi
f010534f:	83 ec 04             	sub    $0x4,%esp
f0105352:	ff 75 e4             	pushl  -0x1c(%ebp)
f0105355:	ff 75 e0             	pushl  -0x20(%ebp)
f0105358:	ff 75 dc             	pushl  -0x24(%ebp)
f010535b:	ff 75 d8             	pushl  -0x28(%ebp)
f010535e:	e8 fd 12 00 00       	call   f0106660 <__umoddi3>
f0105363:	83 c4 14             	add    $0x14,%esp
f0105366:	0f be 80 b2 80 10 f0 	movsbl -0xfef7f4e(%eax),%eax
f010536d:	50                   	push   %eax
f010536e:	ff d7                	call   *%edi
}
f0105370:	83 c4 10             	add    $0x10,%esp
f0105373:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105376:	5b                   	pop    %ebx
f0105377:	5e                   	pop    %esi
f0105378:	5f                   	pop    %edi
f0105379:	5d                   	pop    %ebp
f010537a:	c3                   	ret    

f010537b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010537b:	f3 0f 1e fb          	endbr32 
f010537f:	55                   	push   %ebp
f0105380:	89 e5                	mov    %esp,%ebp
f0105382:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0105385:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0105389:	8b 10                	mov    (%eax),%edx
f010538b:	3b 50 04             	cmp    0x4(%eax),%edx
f010538e:	73 0a                	jae    f010539a <sprintputch+0x1f>
		*b->buf++ = ch;
f0105390:	8d 4a 01             	lea    0x1(%edx),%ecx
f0105393:	89 08                	mov    %ecx,(%eax)
f0105395:	8b 45 08             	mov    0x8(%ebp),%eax
f0105398:	88 02                	mov    %al,(%edx)
}
f010539a:	5d                   	pop    %ebp
f010539b:	c3                   	ret    

f010539c <printfmt>:
{
f010539c:	f3 0f 1e fb          	endbr32 
f01053a0:	55                   	push   %ebp
f01053a1:	89 e5                	mov    %esp,%ebp
f01053a3:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f01053a6:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01053a9:	50                   	push   %eax
f01053aa:	ff 75 10             	pushl  0x10(%ebp)
f01053ad:	ff 75 0c             	pushl  0xc(%ebp)
f01053b0:	ff 75 08             	pushl  0x8(%ebp)
f01053b3:	e8 05 00 00 00       	call   f01053bd <vprintfmt>
}
f01053b8:	83 c4 10             	add    $0x10,%esp
f01053bb:	c9                   	leave  
f01053bc:	c3                   	ret    

f01053bd <vprintfmt>:
{
f01053bd:	f3 0f 1e fb          	endbr32 
f01053c1:	55                   	push   %ebp
f01053c2:	89 e5                	mov    %esp,%ebp
f01053c4:	57                   	push   %edi
f01053c5:	56                   	push   %esi
f01053c6:	53                   	push   %ebx
f01053c7:	83 ec 3c             	sub    $0x3c,%esp
f01053ca:	8b 75 08             	mov    0x8(%ebp),%esi
f01053cd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01053d0:	8b 7d 10             	mov    0x10(%ebp),%edi
f01053d3:	e9 8e 03 00 00       	jmp    f0105766 <vprintfmt+0x3a9>
		padc = ' ';
f01053d8:	c6 45 d3 20          	movb   $0x20,-0x2d(%ebp)
		altflag = 0;
f01053dc:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
		precision = -1;
f01053e3:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f01053ea:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01053f1:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f01053f6:	8d 47 01             	lea    0x1(%edi),%eax
f01053f9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01053fc:	0f b6 17             	movzbl (%edi),%edx
f01053ff:	8d 42 dd             	lea    -0x23(%edx),%eax
f0105402:	3c 55                	cmp    $0x55,%al
f0105404:	0f 87 df 03 00 00    	ja     f01057e9 <vprintfmt+0x42c>
f010540a:	0f b6 c0             	movzbl %al,%eax
f010540d:	3e ff 24 85 00 82 10 	notrack jmp *-0xfef7e00(,%eax,4)
f0105414:	f0 
f0105415:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0105418:	c6 45 d3 2d          	movb   $0x2d,-0x2d(%ebp)
f010541c:	eb d8                	jmp    f01053f6 <vprintfmt+0x39>
		switch (ch = *(unsigned char *) fmt++) {
f010541e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105421:	c6 45 d3 30          	movb   $0x30,-0x2d(%ebp)
f0105425:	eb cf                	jmp    f01053f6 <vprintfmt+0x39>
f0105427:	0f b6 d2             	movzbl %dl,%edx
f010542a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f010542d:	b8 00 00 00 00       	mov    $0x0,%eax
f0105432:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f0105435:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0105438:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f010543c:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f010543f:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0105442:	83 f9 09             	cmp    $0x9,%ecx
f0105445:	77 55                	ja     f010549c <vprintfmt+0xdf>
			for (precision = 0; ; ++fmt) {
f0105447:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f010544a:	eb e9                	jmp    f0105435 <vprintfmt+0x78>
			precision = va_arg(ap, int);
f010544c:	8b 45 14             	mov    0x14(%ebp),%eax
f010544f:	8b 00                	mov    (%eax),%eax
f0105451:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105454:	8b 45 14             	mov    0x14(%ebp),%eax
f0105457:	8d 40 04             	lea    0x4(%eax),%eax
f010545a:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010545d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0105460:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0105464:	79 90                	jns    f01053f6 <vprintfmt+0x39>
				width = precision, precision = -1;
f0105466:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105469:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010546c:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0105473:	eb 81                	jmp    f01053f6 <vprintfmt+0x39>
f0105475:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105478:	85 c0                	test   %eax,%eax
f010547a:	ba 00 00 00 00       	mov    $0x0,%edx
f010547f:	0f 49 d0             	cmovns %eax,%edx
f0105482:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0105485:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0105488:	e9 69 ff ff ff       	jmp    f01053f6 <vprintfmt+0x39>
		switch (ch = *(unsigned char *) fmt++) {
f010548d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0105490:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
			goto reswitch;
f0105497:	e9 5a ff ff ff       	jmp    f01053f6 <vprintfmt+0x39>
f010549c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010549f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01054a2:	eb bc                	jmp    f0105460 <vprintfmt+0xa3>
			lflag++;
f01054a4:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f01054a7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f01054aa:	e9 47 ff ff ff       	jmp    f01053f6 <vprintfmt+0x39>
			putch(va_arg(ap, int), putdat);
f01054af:	8b 45 14             	mov    0x14(%ebp),%eax
f01054b2:	8d 78 04             	lea    0x4(%eax),%edi
f01054b5:	83 ec 08             	sub    $0x8,%esp
f01054b8:	53                   	push   %ebx
f01054b9:	ff 30                	pushl  (%eax)
f01054bb:	ff d6                	call   *%esi
			break;
f01054bd:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01054c0:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f01054c3:	e9 9b 02 00 00       	jmp    f0105763 <vprintfmt+0x3a6>
			err = va_arg(ap, int);
f01054c8:	8b 45 14             	mov    0x14(%ebp),%eax
f01054cb:	8d 78 04             	lea    0x4(%eax),%edi
f01054ce:	8b 00                	mov    (%eax),%eax
f01054d0:	99                   	cltd   
f01054d1:	31 d0                	xor    %edx,%eax
f01054d3:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01054d5:	83 f8 0f             	cmp    $0xf,%eax
f01054d8:	7f 23                	jg     f01054fd <vprintfmt+0x140>
f01054da:	8b 14 85 60 83 10 f0 	mov    -0xfef7ca0(,%eax,4),%edx
f01054e1:	85 d2                	test   %edx,%edx
f01054e3:	74 18                	je     f01054fd <vprintfmt+0x140>
				printfmt(putch, putdat, "%s", p);
f01054e5:	52                   	push   %edx
f01054e6:	68 55 77 10 f0       	push   $0xf0107755
f01054eb:	53                   	push   %ebx
f01054ec:	56                   	push   %esi
f01054ed:	e8 aa fe ff ff       	call   f010539c <printfmt>
f01054f2:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01054f5:	89 7d 14             	mov    %edi,0x14(%ebp)
f01054f8:	e9 66 02 00 00       	jmp    f0105763 <vprintfmt+0x3a6>
				printfmt(putch, putdat, "error %d", err);
f01054fd:	50                   	push   %eax
f01054fe:	68 ca 80 10 f0       	push   $0xf01080ca
f0105503:	53                   	push   %ebx
f0105504:	56                   	push   %esi
f0105505:	e8 92 fe ff ff       	call   f010539c <printfmt>
f010550a:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010550d:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0105510:	e9 4e 02 00 00       	jmp    f0105763 <vprintfmt+0x3a6>
			if ((p = va_arg(ap, char *)) == NULL)
f0105515:	8b 45 14             	mov    0x14(%ebp),%eax
f0105518:	83 c0 04             	add    $0x4,%eax
f010551b:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010551e:	8b 45 14             	mov    0x14(%ebp),%eax
f0105521:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f0105523:	85 d2                	test   %edx,%edx
f0105525:	b8 c3 80 10 f0       	mov    $0xf01080c3,%eax
f010552a:	0f 45 c2             	cmovne %edx,%eax
f010552d:	89 45 cc             	mov    %eax,-0x34(%ebp)
			if (width > 0 && padc != '-')
f0105530:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0105534:	7e 06                	jle    f010553c <vprintfmt+0x17f>
f0105536:	80 7d d3 2d          	cmpb   $0x2d,-0x2d(%ebp)
f010553a:	75 0d                	jne    f0105549 <vprintfmt+0x18c>
				for (width -= strnlen(p, precision); width > 0; width--)
f010553c:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010553f:	89 c7                	mov    %eax,%edi
f0105541:	03 45 e0             	add    -0x20(%ebp),%eax
f0105544:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105547:	eb 55                	jmp    f010559e <vprintfmt+0x1e1>
f0105549:	83 ec 08             	sub    $0x8,%esp
f010554c:	ff 75 d8             	pushl  -0x28(%ebp)
f010554f:	ff 75 cc             	pushl  -0x34(%ebp)
f0105552:	e8 38 04 00 00       	call   f010598f <strnlen>
f0105557:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010555a:	29 c2                	sub    %eax,%edx
f010555c:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f010555f:	83 c4 10             	add    $0x10,%esp
f0105562:	89 d7                	mov    %edx,%edi
					putch(padc, putdat);
f0105564:	0f be 45 d3          	movsbl -0x2d(%ebp),%eax
f0105568:	89 45 e0             	mov    %eax,-0x20(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f010556b:	85 ff                	test   %edi,%edi
f010556d:	7e 11                	jle    f0105580 <vprintfmt+0x1c3>
					putch(padc, putdat);
f010556f:	83 ec 08             	sub    $0x8,%esp
f0105572:	53                   	push   %ebx
f0105573:	ff 75 e0             	pushl  -0x20(%ebp)
f0105576:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0105578:	83 ef 01             	sub    $0x1,%edi
f010557b:	83 c4 10             	add    $0x10,%esp
f010557e:	eb eb                	jmp    f010556b <vprintfmt+0x1ae>
f0105580:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0105583:	85 d2                	test   %edx,%edx
f0105585:	b8 00 00 00 00       	mov    $0x0,%eax
f010558a:	0f 49 c2             	cmovns %edx,%eax
f010558d:	29 c2                	sub    %eax,%edx
f010558f:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0105592:	eb a8                	jmp    f010553c <vprintfmt+0x17f>
					putch(ch, putdat);
f0105594:	83 ec 08             	sub    $0x8,%esp
f0105597:	53                   	push   %ebx
f0105598:	52                   	push   %edx
f0105599:	ff d6                	call   *%esi
f010559b:	83 c4 10             	add    $0x10,%esp
f010559e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01055a1:	29 f9                	sub    %edi,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01055a3:	83 c7 01             	add    $0x1,%edi
f01055a6:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01055aa:	0f be d0             	movsbl %al,%edx
f01055ad:	85 d2                	test   %edx,%edx
f01055af:	74 4b                	je     f01055fc <vprintfmt+0x23f>
f01055b1:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01055b5:	78 06                	js     f01055bd <vprintfmt+0x200>
f01055b7:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f01055bb:	78 1e                	js     f01055db <vprintfmt+0x21e>
				if (altflag && (ch < ' ' || ch > '~'))
f01055bd:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01055c1:	74 d1                	je     f0105594 <vprintfmt+0x1d7>
f01055c3:	0f be c0             	movsbl %al,%eax
f01055c6:	83 e8 20             	sub    $0x20,%eax
f01055c9:	83 f8 5e             	cmp    $0x5e,%eax
f01055cc:	76 c6                	jbe    f0105594 <vprintfmt+0x1d7>
					putch('?', putdat);
f01055ce:	83 ec 08             	sub    $0x8,%esp
f01055d1:	53                   	push   %ebx
f01055d2:	6a 3f                	push   $0x3f
f01055d4:	ff d6                	call   *%esi
f01055d6:	83 c4 10             	add    $0x10,%esp
f01055d9:	eb c3                	jmp    f010559e <vprintfmt+0x1e1>
f01055db:	89 cf                	mov    %ecx,%edi
f01055dd:	eb 0e                	jmp    f01055ed <vprintfmt+0x230>
				putch(' ', putdat);
f01055df:	83 ec 08             	sub    $0x8,%esp
f01055e2:	53                   	push   %ebx
f01055e3:	6a 20                	push   $0x20
f01055e5:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01055e7:	83 ef 01             	sub    $0x1,%edi
f01055ea:	83 c4 10             	add    $0x10,%esp
f01055ed:	85 ff                	test   %edi,%edi
f01055ef:	7f ee                	jg     f01055df <vprintfmt+0x222>
			if ((p = va_arg(ap, char *)) == NULL)
f01055f1:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01055f4:	89 45 14             	mov    %eax,0x14(%ebp)
f01055f7:	e9 67 01 00 00       	jmp    f0105763 <vprintfmt+0x3a6>
f01055fc:	89 cf                	mov    %ecx,%edi
f01055fe:	eb ed                	jmp    f01055ed <vprintfmt+0x230>
	if (lflag >= 2)
f0105600:	83 f9 01             	cmp    $0x1,%ecx
f0105603:	7f 1b                	jg     f0105620 <vprintfmt+0x263>
	else if (lflag)
f0105605:	85 c9                	test   %ecx,%ecx
f0105607:	74 63                	je     f010566c <vprintfmt+0x2af>
		return va_arg(*ap, long);
f0105609:	8b 45 14             	mov    0x14(%ebp),%eax
f010560c:	8b 00                	mov    (%eax),%eax
f010560e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105611:	99                   	cltd   
f0105612:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105615:	8b 45 14             	mov    0x14(%ebp),%eax
f0105618:	8d 40 04             	lea    0x4(%eax),%eax
f010561b:	89 45 14             	mov    %eax,0x14(%ebp)
f010561e:	eb 17                	jmp    f0105637 <vprintfmt+0x27a>
		return va_arg(*ap, long long);
f0105620:	8b 45 14             	mov    0x14(%ebp),%eax
f0105623:	8b 50 04             	mov    0x4(%eax),%edx
f0105626:	8b 00                	mov    (%eax),%eax
f0105628:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010562b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010562e:	8b 45 14             	mov    0x14(%ebp),%eax
f0105631:	8d 40 08             	lea    0x8(%eax),%eax
f0105634:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0105637:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010563a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f010563d:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f0105642:	85 c9                	test   %ecx,%ecx
f0105644:	0f 89 ff 00 00 00    	jns    f0105749 <vprintfmt+0x38c>
				putch('-', putdat);
f010564a:	83 ec 08             	sub    $0x8,%esp
f010564d:	53                   	push   %ebx
f010564e:	6a 2d                	push   $0x2d
f0105650:	ff d6                	call   *%esi
				num = -(long long) num;
f0105652:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0105655:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0105658:	f7 da                	neg    %edx
f010565a:	83 d1 00             	adc    $0x0,%ecx
f010565d:	f7 d9                	neg    %ecx
f010565f:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0105662:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105667:	e9 dd 00 00 00       	jmp    f0105749 <vprintfmt+0x38c>
		return va_arg(*ap, int);
f010566c:	8b 45 14             	mov    0x14(%ebp),%eax
f010566f:	8b 00                	mov    (%eax),%eax
f0105671:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105674:	99                   	cltd   
f0105675:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105678:	8b 45 14             	mov    0x14(%ebp),%eax
f010567b:	8d 40 04             	lea    0x4(%eax),%eax
f010567e:	89 45 14             	mov    %eax,0x14(%ebp)
f0105681:	eb b4                	jmp    f0105637 <vprintfmt+0x27a>
	if (lflag >= 2)
f0105683:	83 f9 01             	cmp    $0x1,%ecx
f0105686:	7f 1e                	jg     f01056a6 <vprintfmt+0x2e9>
	else if (lflag)
f0105688:	85 c9                	test   %ecx,%ecx
f010568a:	74 32                	je     f01056be <vprintfmt+0x301>
		return va_arg(*ap, unsigned long);
f010568c:	8b 45 14             	mov    0x14(%ebp),%eax
f010568f:	8b 10                	mov    (%eax),%edx
f0105691:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105696:	8d 40 04             	lea    0x4(%eax),%eax
f0105699:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010569c:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long);
f01056a1:	e9 a3 00 00 00       	jmp    f0105749 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned long long);
f01056a6:	8b 45 14             	mov    0x14(%ebp),%eax
f01056a9:	8b 10                	mov    (%eax),%edx
f01056ab:	8b 48 04             	mov    0x4(%eax),%ecx
f01056ae:	8d 40 08             	lea    0x8(%eax),%eax
f01056b1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01056b4:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long long);
f01056b9:	e9 8b 00 00 00       	jmp    f0105749 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned int);
f01056be:	8b 45 14             	mov    0x14(%ebp),%eax
f01056c1:	8b 10                	mov    (%eax),%edx
f01056c3:	b9 00 00 00 00       	mov    $0x0,%ecx
f01056c8:	8d 40 04             	lea    0x4(%eax),%eax
f01056cb:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01056ce:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned int);
f01056d3:	eb 74                	jmp    f0105749 <vprintfmt+0x38c>
	if (lflag >= 2)
f01056d5:	83 f9 01             	cmp    $0x1,%ecx
f01056d8:	7f 1b                	jg     f01056f5 <vprintfmt+0x338>
	else if (lflag)
f01056da:	85 c9                	test   %ecx,%ecx
f01056dc:	74 2c                	je     f010570a <vprintfmt+0x34d>
		return va_arg(*ap, unsigned long);
f01056de:	8b 45 14             	mov    0x14(%ebp),%eax
f01056e1:	8b 10                	mov    (%eax),%edx
f01056e3:	b9 00 00 00 00       	mov    $0x0,%ecx
f01056e8:	8d 40 04             	lea    0x4(%eax),%eax
f01056eb:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01056ee:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long);
f01056f3:	eb 54                	jmp    f0105749 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned long long);
f01056f5:	8b 45 14             	mov    0x14(%ebp),%eax
f01056f8:	8b 10                	mov    (%eax),%edx
f01056fa:	8b 48 04             	mov    0x4(%eax),%ecx
f01056fd:	8d 40 08             	lea    0x8(%eax),%eax
f0105700:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0105703:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long long);
f0105708:	eb 3f                	jmp    f0105749 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned int);
f010570a:	8b 45 14             	mov    0x14(%ebp),%eax
f010570d:	8b 10                	mov    (%eax),%edx
f010570f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105714:	8d 40 04             	lea    0x4(%eax),%eax
f0105717:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010571a:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned int);
f010571f:	eb 28                	jmp    f0105749 <vprintfmt+0x38c>
			putch('0', putdat);
f0105721:	83 ec 08             	sub    $0x8,%esp
f0105724:	53                   	push   %ebx
f0105725:	6a 30                	push   $0x30
f0105727:	ff d6                	call   *%esi
			putch('x', putdat);
f0105729:	83 c4 08             	add    $0x8,%esp
f010572c:	53                   	push   %ebx
f010572d:	6a 78                	push   $0x78
f010572f:	ff d6                	call   *%esi
			num = (unsigned long long)
f0105731:	8b 45 14             	mov    0x14(%ebp),%eax
f0105734:	8b 10                	mov    (%eax),%edx
f0105736:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010573b:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f010573e:	8d 40 04             	lea    0x4(%eax),%eax
f0105741:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0105744:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0105749:	83 ec 0c             	sub    $0xc,%esp
f010574c:	0f be 7d d3          	movsbl -0x2d(%ebp),%edi
f0105750:	57                   	push   %edi
f0105751:	ff 75 e0             	pushl  -0x20(%ebp)
f0105754:	50                   	push   %eax
f0105755:	51                   	push   %ecx
f0105756:	52                   	push   %edx
f0105757:	89 da                	mov    %ebx,%edx
f0105759:	89 f0                	mov    %esi,%eax
f010575b:	e8 72 fb ff ff       	call   f01052d2 <printnum>
			break;
f0105760:	83 c4 20             	add    $0x20,%esp
			if ((p = va_arg(ap, char *)) == NULL)
f0105763:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0105766:	83 c7 01             	add    $0x1,%edi
f0105769:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010576d:	83 f8 25             	cmp    $0x25,%eax
f0105770:	0f 84 62 fc ff ff    	je     f01053d8 <vprintfmt+0x1b>
			if (ch == '\0')
f0105776:	85 c0                	test   %eax,%eax
f0105778:	0f 84 8b 00 00 00    	je     f0105809 <vprintfmt+0x44c>
			putch(ch, putdat);
f010577e:	83 ec 08             	sub    $0x8,%esp
f0105781:	53                   	push   %ebx
f0105782:	50                   	push   %eax
f0105783:	ff d6                	call   *%esi
f0105785:	83 c4 10             	add    $0x10,%esp
f0105788:	eb dc                	jmp    f0105766 <vprintfmt+0x3a9>
	if (lflag >= 2)
f010578a:	83 f9 01             	cmp    $0x1,%ecx
f010578d:	7f 1b                	jg     f01057aa <vprintfmt+0x3ed>
	else if (lflag)
f010578f:	85 c9                	test   %ecx,%ecx
f0105791:	74 2c                	je     f01057bf <vprintfmt+0x402>
		return va_arg(*ap, unsigned long);
f0105793:	8b 45 14             	mov    0x14(%ebp),%eax
f0105796:	8b 10                	mov    (%eax),%edx
f0105798:	b9 00 00 00 00       	mov    $0x0,%ecx
f010579d:	8d 40 04             	lea    0x4(%eax),%eax
f01057a0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01057a3:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long);
f01057a8:	eb 9f                	jmp    f0105749 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned long long);
f01057aa:	8b 45 14             	mov    0x14(%ebp),%eax
f01057ad:	8b 10                	mov    (%eax),%edx
f01057af:	8b 48 04             	mov    0x4(%eax),%ecx
f01057b2:	8d 40 08             	lea    0x8(%eax),%eax
f01057b5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01057b8:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long long);
f01057bd:	eb 8a                	jmp    f0105749 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned int);
f01057bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01057c2:	8b 10                	mov    (%eax),%edx
f01057c4:	b9 00 00 00 00       	mov    $0x0,%ecx
f01057c9:	8d 40 04             	lea    0x4(%eax),%eax
f01057cc:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01057cf:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned int);
f01057d4:	e9 70 ff ff ff       	jmp    f0105749 <vprintfmt+0x38c>
			putch(ch, putdat);
f01057d9:	83 ec 08             	sub    $0x8,%esp
f01057dc:	53                   	push   %ebx
f01057dd:	6a 25                	push   $0x25
f01057df:	ff d6                	call   *%esi
			break;
f01057e1:	83 c4 10             	add    $0x10,%esp
f01057e4:	e9 7a ff ff ff       	jmp    f0105763 <vprintfmt+0x3a6>
			putch('%', putdat);
f01057e9:	83 ec 08             	sub    $0x8,%esp
f01057ec:	53                   	push   %ebx
f01057ed:	6a 25                	push   $0x25
f01057ef:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01057f1:	83 c4 10             	add    $0x10,%esp
f01057f4:	89 f8                	mov    %edi,%eax
f01057f6:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01057fa:	74 05                	je     f0105801 <vprintfmt+0x444>
f01057fc:	83 e8 01             	sub    $0x1,%eax
f01057ff:	eb f5                	jmp    f01057f6 <vprintfmt+0x439>
f0105801:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105804:	e9 5a ff ff ff       	jmp    f0105763 <vprintfmt+0x3a6>
}
f0105809:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010580c:	5b                   	pop    %ebx
f010580d:	5e                   	pop    %esi
f010580e:	5f                   	pop    %edi
f010580f:	5d                   	pop    %ebp
f0105810:	c3                   	ret    

f0105811 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105811:	f3 0f 1e fb          	endbr32 
f0105815:	55                   	push   %ebp
f0105816:	89 e5                	mov    %esp,%ebp
f0105818:	83 ec 18             	sub    $0x18,%esp
f010581b:	8b 45 08             	mov    0x8(%ebp),%eax
f010581e:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105821:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105824:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105828:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010582b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105832:	85 c0                	test   %eax,%eax
f0105834:	74 26                	je     f010585c <vsnprintf+0x4b>
f0105836:	85 d2                	test   %edx,%edx
f0105838:	7e 22                	jle    f010585c <vsnprintf+0x4b>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010583a:	ff 75 14             	pushl  0x14(%ebp)
f010583d:	ff 75 10             	pushl  0x10(%ebp)
f0105840:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105843:	50                   	push   %eax
f0105844:	68 7b 53 10 f0       	push   $0xf010537b
f0105849:	e8 6f fb ff ff       	call   f01053bd <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010584e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105851:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105854:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105857:	83 c4 10             	add    $0x10,%esp
}
f010585a:	c9                   	leave  
f010585b:	c3                   	ret    
		return -E_INVAL;
f010585c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105861:	eb f7                	jmp    f010585a <vsnprintf+0x49>

f0105863 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105863:	f3 0f 1e fb          	endbr32 
f0105867:	55                   	push   %ebp
f0105868:	89 e5                	mov    %esp,%ebp
f010586a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010586d:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0105870:	50                   	push   %eax
f0105871:	ff 75 10             	pushl  0x10(%ebp)
f0105874:	ff 75 0c             	pushl  0xc(%ebp)
f0105877:	ff 75 08             	pushl  0x8(%ebp)
f010587a:	e8 92 ff ff ff       	call   f0105811 <vsnprintf>
	va_end(ap);

	return rc;
}
f010587f:	c9                   	leave  
f0105880:	c3                   	ret    

f0105881 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0105881:	f3 0f 1e fb          	endbr32 
f0105885:	55                   	push   %ebp
f0105886:	89 e5                	mov    %esp,%ebp
f0105888:	57                   	push   %edi
f0105889:	56                   	push   %esi
f010588a:	53                   	push   %ebx
f010588b:	83 ec 0c             	sub    $0xc,%esp
f010588e:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

#if JOS_KERNEL
	if (prompt != NULL)
f0105891:	85 c0                	test   %eax,%eax
f0105893:	74 11                	je     f01058a6 <readline+0x25>
		cprintf("%s", prompt);
f0105895:	83 ec 08             	sub    $0x8,%esp
f0105898:	50                   	push   %eax
f0105899:	68 55 77 10 f0       	push   $0xf0107755
f010589e:	e8 17 e1 ff ff       	call   f01039ba <cprintf>
f01058a3:	83 c4 10             	add    $0x10,%esp
	if (prompt != NULL)
		fprintf(1, "%s", prompt);
#endif

	i = 0;
	echoing = iscons(0);
f01058a6:	83 ec 0c             	sub    $0xc,%esp
f01058a9:	6a 00                	push   $0x0
f01058ab:	e8 37 af ff ff       	call   f01007e7 <iscons>
f01058b0:	89 c7                	mov    %eax,%edi
f01058b2:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01058b5:	be 00 00 00 00       	mov    $0x0,%esi
f01058ba:	eb 57                	jmp    f0105913 <readline+0x92>
	while (1) {
		c = getchar();
		if (c < 0) {
			if (c != -E_EOF)
				cprintf("read error: %e\n", c);
			return NULL;
f01058bc:	b8 00 00 00 00       	mov    $0x0,%eax
			if (c != -E_EOF)
f01058c1:	83 fb f8             	cmp    $0xfffffff8,%ebx
f01058c4:	75 08                	jne    f01058ce <readline+0x4d>
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01058c6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01058c9:	5b                   	pop    %ebx
f01058ca:	5e                   	pop    %esi
f01058cb:	5f                   	pop    %edi
f01058cc:	5d                   	pop    %ebp
f01058cd:	c3                   	ret    
				cprintf("read error: %e\n", c);
f01058ce:	83 ec 08             	sub    $0x8,%esp
f01058d1:	53                   	push   %ebx
f01058d2:	68 bf 83 10 f0       	push   $0xf01083bf
f01058d7:	e8 de e0 ff ff       	call   f01039ba <cprintf>
f01058dc:	83 c4 10             	add    $0x10,%esp
			return NULL;
f01058df:	b8 00 00 00 00       	mov    $0x0,%eax
f01058e4:	eb e0                	jmp    f01058c6 <readline+0x45>
			if (echoing)
f01058e6:	85 ff                	test   %edi,%edi
f01058e8:	75 05                	jne    f01058ef <readline+0x6e>
			i--;
f01058ea:	83 ee 01             	sub    $0x1,%esi
f01058ed:	eb 24                	jmp    f0105913 <readline+0x92>
				cputchar('\b');
f01058ef:	83 ec 0c             	sub    $0xc,%esp
f01058f2:	6a 08                	push   $0x8
f01058f4:	e8 c5 ae ff ff       	call   f01007be <cputchar>
f01058f9:	83 c4 10             	add    $0x10,%esp
f01058fc:	eb ec                	jmp    f01058ea <readline+0x69>
				cputchar(c);
f01058fe:	83 ec 0c             	sub    $0xc,%esp
f0105901:	53                   	push   %ebx
f0105902:	e8 b7 ae ff ff       	call   f01007be <cputchar>
f0105907:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010590a:	88 9e 80 7a 21 f0    	mov    %bl,-0xfde8580(%esi)
f0105910:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f0105913:	e8 ba ae ff ff       	call   f01007d2 <getchar>
f0105918:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010591a:	85 c0                	test   %eax,%eax
f010591c:	78 9e                	js     f01058bc <readline+0x3b>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010591e:	83 f8 08             	cmp    $0x8,%eax
f0105921:	0f 94 c2             	sete   %dl
f0105924:	83 f8 7f             	cmp    $0x7f,%eax
f0105927:	0f 94 c0             	sete   %al
f010592a:	08 c2                	or     %al,%dl
f010592c:	74 04                	je     f0105932 <readline+0xb1>
f010592e:	85 f6                	test   %esi,%esi
f0105930:	7f b4                	jg     f01058e6 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105932:	83 fb 1f             	cmp    $0x1f,%ebx
f0105935:	7e 0e                	jle    f0105945 <readline+0xc4>
f0105937:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010593d:	7f 06                	jg     f0105945 <readline+0xc4>
			if (echoing)
f010593f:	85 ff                	test   %edi,%edi
f0105941:	74 c7                	je     f010590a <readline+0x89>
f0105943:	eb b9                	jmp    f01058fe <readline+0x7d>
		} else if (c == '\n' || c == '\r') {
f0105945:	83 fb 0a             	cmp    $0xa,%ebx
f0105948:	74 05                	je     f010594f <readline+0xce>
f010594a:	83 fb 0d             	cmp    $0xd,%ebx
f010594d:	75 c4                	jne    f0105913 <readline+0x92>
			if (echoing)
f010594f:	85 ff                	test   %edi,%edi
f0105951:	75 11                	jne    f0105964 <readline+0xe3>
			buf[i] = 0;
f0105953:	c6 86 80 7a 21 f0 00 	movb   $0x0,-0xfde8580(%esi)
			return buf;
f010595a:	b8 80 7a 21 f0       	mov    $0xf0217a80,%eax
f010595f:	e9 62 ff ff ff       	jmp    f01058c6 <readline+0x45>
				cputchar('\n');
f0105964:	83 ec 0c             	sub    $0xc,%esp
f0105967:	6a 0a                	push   $0xa
f0105969:	e8 50 ae ff ff       	call   f01007be <cputchar>
f010596e:	83 c4 10             	add    $0x10,%esp
f0105971:	eb e0                	jmp    f0105953 <readline+0xd2>

f0105973 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105973:	f3 0f 1e fb          	endbr32 
f0105977:	55                   	push   %ebp
f0105978:	89 e5                	mov    %esp,%ebp
f010597a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010597d:	b8 00 00 00 00       	mov    $0x0,%eax
f0105982:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105986:	74 05                	je     f010598d <strlen+0x1a>
		n++;
f0105988:	83 c0 01             	add    $0x1,%eax
f010598b:	eb f5                	jmp    f0105982 <strlen+0xf>
	return n;
}
f010598d:	5d                   	pop    %ebp
f010598e:	c3                   	ret    

f010598f <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010598f:	f3 0f 1e fb          	endbr32 
f0105993:	55                   	push   %ebp
f0105994:	89 e5                	mov    %esp,%ebp
f0105996:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105999:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010599c:	b8 00 00 00 00       	mov    $0x0,%eax
f01059a1:	39 d0                	cmp    %edx,%eax
f01059a3:	74 0d                	je     f01059b2 <strnlen+0x23>
f01059a5:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01059a9:	74 05                	je     f01059b0 <strnlen+0x21>
		n++;
f01059ab:	83 c0 01             	add    $0x1,%eax
f01059ae:	eb f1                	jmp    f01059a1 <strnlen+0x12>
f01059b0:	89 c2                	mov    %eax,%edx
	return n;
}
f01059b2:	89 d0                	mov    %edx,%eax
f01059b4:	5d                   	pop    %ebp
f01059b5:	c3                   	ret    

f01059b6 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01059b6:	f3 0f 1e fb          	endbr32 
f01059ba:	55                   	push   %ebp
f01059bb:	89 e5                	mov    %esp,%ebp
f01059bd:	53                   	push   %ebx
f01059be:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01059c1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01059c4:	b8 00 00 00 00       	mov    $0x0,%eax
f01059c9:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f01059cd:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f01059d0:	83 c0 01             	add    $0x1,%eax
f01059d3:	84 d2                	test   %dl,%dl
f01059d5:	75 f2                	jne    f01059c9 <strcpy+0x13>
		/* do nothing */;
	return ret;
}
f01059d7:	89 c8                	mov    %ecx,%eax
f01059d9:	5b                   	pop    %ebx
f01059da:	5d                   	pop    %ebp
f01059db:	c3                   	ret    

f01059dc <strcat>:

char *
strcat(char *dst, const char *src)
{
f01059dc:	f3 0f 1e fb          	endbr32 
f01059e0:	55                   	push   %ebp
f01059e1:	89 e5                	mov    %esp,%ebp
f01059e3:	53                   	push   %ebx
f01059e4:	83 ec 10             	sub    $0x10,%esp
f01059e7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01059ea:	53                   	push   %ebx
f01059eb:	e8 83 ff ff ff       	call   f0105973 <strlen>
f01059f0:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f01059f3:	ff 75 0c             	pushl  0xc(%ebp)
f01059f6:	01 d8                	add    %ebx,%eax
f01059f8:	50                   	push   %eax
f01059f9:	e8 b8 ff ff ff       	call   f01059b6 <strcpy>
	return dst;
}
f01059fe:	89 d8                	mov    %ebx,%eax
f0105a00:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0105a03:	c9                   	leave  
f0105a04:	c3                   	ret    

f0105a05 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105a05:	f3 0f 1e fb          	endbr32 
f0105a09:	55                   	push   %ebp
f0105a0a:	89 e5                	mov    %esp,%ebp
f0105a0c:	56                   	push   %esi
f0105a0d:	53                   	push   %ebx
f0105a0e:	8b 75 08             	mov    0x8(%ebp),%esi
f0105a11:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105a14:	89 f3                	mov    %esi,%ebx
f0105a16:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105a19:	89 f0                	mov    %esi,%eax
f0105a1b:	39 d8                	cmp    %ebx,%eax
f0105a1d:	74 11                	je     f0105a30 <strncpy+0x2b>
		*dst++ = *src;
f0105a1f:	83 c0 01             	add    $0x1,%eax
f0105a22:	0f b6 0a             	movzbl (%edx),%ecx
f0105a25:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0105a28:	80 f9 01             	cmp    $0x1,%cl
f0105a2b:	83 da ff             	sbb    $0xffffffff,%edx
f0105a2e:	eb eb                	jmp    f0105a1b <strncpy+0x16>
	}
	return ret;
}
f0105a30:	89 f0                	mov    %esi,%eax
f0105a32:	5b                   	pop    %ebx
f0105a33:	5e                   	pop    %esi
f0105a34:	5d                   	pop    %ebp
f0105a35:	c3                   	ret    

f0105a36 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0105a36:	f3 0f 1e fb          	endbr32 
f0105a3a:	55                   	push   %ebp
f0105a3b:	89 e5                	mov    %esp,%ebp
f0105a3d:	56                   	push   %esi
f0105a3e:	53                   	push   %ebx
f0105a3f:	8b 75 08             	mov    0x8(%ebp),%esi
f0105a42:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105a45:	8b 55 10             	mov    0x10(%ebp),%edx
f0105a48:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105a4a:	85 d2                	test   %edx,%edx
f0105a4c:	74 21                	je     f0105a6f <strlcpy+0x39>
f0105a4e:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0105a52:	89 f2                	mov    %esi,%edx
		while (--size > 0 && *src != '\0')
f0105a54:	39 c2                	cmp    %eax,%edx
f0105a56:	74 14                	je     f0105a6c <strlcpy+0x36>
f0105a58:	0f b6 19             	movzbl (%ecx),%ebx
f0105a5b:	84 db                	test   %bl,%bl
f0105a5d:	74 0b                	je     f0105a6a <strlcpy+0x34>
			*dst++ = *src++;
f0105a5f:	83 c1 01             	add    $0x1,%ecx
f0105a62:	83 c2 01             	add    $0x1,%edx
f0105a65:	88 5a ff             	mov    %bl,-0x1(%edx)
f0105a68:	eb ea                	jmp    f0105a54 <strlcpy+0x1e>
f0105a6a:	89 d0                	mov    %edx,%eax
		*dst = '\0';
f0105a6c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105a6f:	29 f0                	sub    %esi,%eax
}
f0105a71:	5b                   	pop    %ebx
f0105a72:	5e                   	pop    %esi
f0105a73:	5d                   	pop    %ebp
f0105a74:	c3                   	ret    

f0105a75 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105a75:	f3 0f 1e fb          	endbr32 
f0105a79:	55                   	push   %ebp
f0105a7a:	89 e5                	mov    %esp,%ebp
f0105a7c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105a7f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105a82:	0f b6 01             	movzbl (%ecx),%eax
f0105a85:	84 c0                	test   %al,%al
f0105a87:	74 0c                	je     f0105a95 <strcmp+0x20>
f0105a89:	3a 02                	cmp    (%edx),%al
f0105a8b:	75 08                	jne    f0105a95 <strcmp+0x20>
		p++, q++;
f0105a8d:	83 c1 01             	add    $0x1,%ecx
f0105a90:	83 c2 01             	add    $0x1,%edx
f0105a93:	eb ed                	jmp    f0105a82 <strcmp+0xd>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105a95:	0f b6 c0             	movzbl %al,%eax
f0105a98:	0f b6 12             	movzbl (%edx),%edx
f0105a9b:	29 d0                	sub    %edx,%eax
}
f0105a9d:	5d                   	pop    %ebp
f0105a9e:	c3                   	ret    

f0105a9f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105a9f:	f3 0f 1e fb          	endbr32 
f0105aa3:	55                   	push   %ebp
f0105aa4:	89 e5                	mov    %esp,%ebp
f0105aa6:	53                   	push   %ebx
f0105aa7:	8b 45 08             	mov    0x8(%ebp),%eax
f0105aaa:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105aad:	89 c3                	mov    %eax,%ebx
f0105aaf:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0105ab2:	eb 06                	jmp    f0105aba <strncmp+0x1b>
		n--, p++, q++;
f0105ab4:	83 c0 01             	add    $0x1,%eax
f0105ab7:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0105aba:	39 d8                	cmp    %ebx,%eax
f0105abc:	74 16                	je     f0105ad4 <strncmp+0x35>
f0105abe:	0f b6 08             	movzbl (%eax),%ecx
f0105ac1:	84 c9                	test   %cl,%cl
f0105ac3:	74 04                	je     f0105ac9 <strncmp+0x2a>
f0105ac5:	3a 0a                	cmp    (%edx),%cl
f0105ac7:	74 eb                	je     f0105ab4 <strncmp+0x15>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105ac9:	0f b6 00             	movzbl (%eax),%eax
f0105acc:	0f b6 12             	movzbl (%edx),%edx
f0105acf:	29 d0                	sub    %edx,%eax
}
f0105ad1:	5b                   	pop    %ebx
f0105ad2:	5d                   	pop    %ebp
f0105ad3:	c3                   	ret    
		return 0;
f0105ad4:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ad9:	eb f6                	jmp    f0105ad1 <strncmp+0x32>

f0105adb <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105adb:	f3 0f 1e fb          	endbr32 
f0105adf:	55                   	push   %ebp
f0105ae0:	89 e5                	mov    %esp,%ebp
f0105ae2:	8b 45 08             	mov    0x8(%ebp),%eax
f0105ae5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105ae9:	0f b6 10             	movzbl (%eax),%edx
f0105aec:	84 d2                	test   %dl,%dl
f0105aee:	74 09                	je     f0105af9 <strchr+0x1e>
		if (*s == c)
f0105af0:	38 ca                	cmp    %cl,%dl
f0105af2:	74 0a                	je     f0105afe <strchr+0x23>
	for (; *s; s++)
f0105af4:	83 c0 01             	add    $0x1,%eax
f0105af7:	eb f0                	jmp    f0105ae9 <strchr+0xe>
			return (char *) s;
	return 0;
f0105af9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105afe:	5d                   	pop    %ebp
f0105aff:	c3                   	ret    

f0105b00 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105b00:	f3 0f 1e fb          	endbr32 
f0105b04:	55                   	push   %ebp
f0105b05:	89 e5                	mov    %esp,%ebp
f0105b07:	8b 45 08             	mov    0x8(%ebp),%eax
f0105b0a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105b0e:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0105b11:	38 ca                	cmp    %cl,%dl
f0105b13:	74 09                	je     f0105b1e <strfind+0x1e>
f0105b15:	84 d2                	test   %dl,%dl
f0105b17:	74 05                	je     f0105b1e <strfind+0x1e>
	for (; *s; s++)
f0105b19:	83 c0 01             	add    $0x1,%eax
f0105b1c:	eb f0                	jmp    f0105b0e <strfind+0xe>
			break;
	return (char *) s;
}
f0105b1e:	5d                   	pop    %ebp
f0105b1f:	c3                   	ret    

f0105b20 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105b20:	f3 0f 1e fb          	endbr32 
f0105b24:	55                   	push   %ebp
f0105b25:	89 e5                	mov    %esp,%ebp
f0105b27:	57                   	push   %edi
f0105b28:	56                   	push   %esi
f0105b29:	53                   	push   %ebx
f0105b2a:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105b2d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105b30:	85 c9                	test   %ecx,%ecx
f0105b32:	74 31                	je     f0105b65 <memset+0x45>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105b34:	89 f8                	mov    %edi,%eax
f0105b36:	09 c8                	or     %ecx,%eax
f0105b38:	a8 03                	test   $0x3,%al
f0105b3a:	75 23                	jne    f0105b5f <memset+0x3f>
		c &= 0xFF;
f0105b3c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105b40:	89 d3                	mov    %edx,%ebx
f0105b42:	c1 e3 08             	shl    $0x8,%ebx
f0105b45:	89 d0                	mov    %edx,%eax
f0105b47:	c1 e0 18             	shl    $0x18,%eax
f0105b4a:	89 d6                	mov    %edx,%esi
f0105b4c:	c1 e6 10             	shl    $0x10,%esi
f0105b4f:	09 f0                	or     %esi,%eax
f0105b51:	09 c2                	or     %eax,%edx
f0105b53:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0105b55:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0105b58:	89 d0                	mov    %edx,%eax
f0105b5a:	fc                   	cld    
f0105b5b:	f3 ab                	rep stos %eax,%es:(%edi)
f0105b5d:	eb 06                	jmp    f0105b65 <memset+0x45>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105b5f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105b62:	fc                   	cld    
f0105b63:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105b65:	89 f8                	mov    %edi,%eax
f0105b67:	5b                   	pop    %ebx
f0105b68:	5e                   	pop    %esi
f0105b69:	5f                   	pop    %edi
f0105b6a:	5d                   	pop    %ebp
f0105b6b:	c3                   	ret    

f0105b6c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105b6c:	f3 0f 1e fb          	endbr32 
f0105b70:	55                   	push   %ebp
f0105b71:	89 e5                	mov    %esp,%ebp
f0105b73:	57                   	push   %edi
f0105b74:	56                   	push   %esi
f0105b75:	8b 45 08             	mov    0x8(%ebp),%eax
f0105b78:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105b7b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105b7e:	39 c6                	cmp    %eax,%esi
f0105b80:	73 32                	jae    f0105bb4 <memmove+0x48>
f0105b82:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105b85:	39 c2                	cmp    %eax,%edx
f0105b87:	76 2b                	jbe    f0105bb4 <memmove+0x48>
		s += n;
		d += n;
f0105b89:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105b8c:	89 fe                	mov    %edi,%esi
f0105b8e:	09 ce                	or     %ecx,%esi
f0105b90:	09 d6                	or     %edx,%esi
f0105b92:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105b98:	75 0e                	jne    f0105ba8 <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0105b9a:	83 ef 04             	sub    $0x4,%edi
f0105b9d:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105ba0:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0105ba3:	fd                   	std    
f0105ba4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105ba6:	eb 09                	jmp    f0105bb1 <memmove+0x45>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0105ba8:	83 ef 01             	sub    $0x1,%edi
f0105bab:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0105bae:	fd                   	std    
f0105baf:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105bb1:	fc                   	cld    
f0105bb2:	eb 1a                	jmp    f0105bce <memmove+0x62>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105bb4:	89 c2                	mov    %eax,%edx
f0105bb6:	09 ca                	or     %ecx,%edx
f0105bb8:	09 f2                	or     %esi,%edx
f0105bba:	f6 c2 03             	test   $0x3,%dl
f0105bbd:	75 0a                	jne    f0105bc9 <memmove+0x5d>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105bbf:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0105bc2:	89 c7                	mov    %eax,%edi
f0105bc4:	fc                   	cld    
f0105bc5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105bc7:	eb 05                	jmp    f0105bce <memmove+0x62>
		else
			asm volatile("cld; rep movsb\n"
f0105bc9:	89 c7                	mov    %eax,%edi
f0105bcb:	fc                   	cld    
f0105bcc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105bce:	5e                   	pop    %esi
f0105bcf:	5f                   	pop    %edi
f0105bd0:	5d                   	pop    %ebp
f0105bd1:	c3                   	ret    

f0105bd2 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105bd2:	f3 0f 1e fb          	endbr32 
f0105bd6:	55                   	push   %ebp
f0105bd7:	89 e5                	mov    %esp,%ebp
f0105bd9:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0105bdc:	ff 75 10             	pushl  0x10(%ebp)
f0105bdf:	ff 75 0c             	pushl  0xc(%ebp)
f0105be2:	ff 75 08             	pushl  0x8(%ebp)
f0105be5:	e8 82 ff ff ff       	call   f0105b6c <memmove>
}
f0105bea:	c9                   	leave  
f0105beb:	c3                   	ret    

f0105bec <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105bec:	f3 0f 1e fb          	endbr32 
f0105bf0:	55                   	push   %ebp
f0105bf1:	89 e5                	mov    %esp,%ebp
f0105bf3:	56                   	push   %esi
f0105bf4:	53                   	push   %ebx
f0105bf5:	8b 45 08             	mov    0x8(%ebp),%eax
f0105bf8:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105bfb:	89 c6                	mov    %eax,%esi
f0105bfd:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105c00:	39 f0                	cmp    %esi,%eax
f0105c02:	74 1c                	je     f0105c20 <memcmp+0x34>
		if (*s1 != *s2)
f0105c04:	0f b6 08             	movzbl (%eax),%ecx
f0105c07:	0f b6 1a             	movzbl (%edx),%ebx
f0105c0a:	38 d9                	cmp    %bl,%cl
f0105c0c:	75 08                	jne    f0105c16 <memcmp+0x2a>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0105c0e:	83 c0 01             	add    $0x1,%eax
f0105c11:	83 c2 01             	add    $0x1,%edx
f0105c14:	eb ea                	jmp    f0105c00 <memcmp+0x14>
			return (int) *s1 - (int) *s2;
f0105c16:	0f b6 c1             	movzbl %cl,%eax
f0105c19:	0f b6 db             	movzbl %bl,%ebx
f0105c1c:	29 d8                	sub    %ebx,%eax
f0105c1e:	eb 05                	jmp    f0105c25 <memcmp+0x39>
	}

	return 0;
f0105c20:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105c25:	5b                   	pop    %ebx
f0105c26:	5e                   	pop    %esi
f0105c27:	5d                   	pop    %ebp
f0105c28:	c3                   	ret    

f0105c29 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105c29:	f3 0f 1e fb          	endbr32 
f0105c2d:	55                   	push   %ebp
f0105c2e:	89 e5                	mov    %esp,%ebp
f0105c30:	8b 45 08             	mov    0x8(%ebp),%eax
f0105c33:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0105c36:	89 c2                	mov    %eax,%edx
f0105c38:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105c3b:	39 d0                	cmp    %edx,%eax
f0105c3d:	73 09                	jae    f0105c48 <memfind+0x1f>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105c3f:	38 08                	cmp    %cl,(%eax)
f0105c41:	74 05                	je     f0105c48 <memfind+0x1f>
	for (; s < ends; s++)
f0105c43:	83 c0 01             	add    $0x1,%eax
f0105c46:	eb f3                	jmp    f0105c3b <memfind+0x12>
			break;
	return (void *) s;
}
f0105c48:	5d                   	pop    %ebp
f0105c49:	c3                   	ret    

f0105c4a <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105c4a:	f3 0f 1e fb          	endbr32 
f0105c4e:	55                   	push   %ebp
f0105c4f:	89 e5                	mov    %esp,%ebp
f0105c51:	57                   	push   %edi
f0105c52:	56                   	push   %esi
f0105c53:	53                   	push   %ebx
f0105c54:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105c57:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105c5a:	eb 03                	jmp    f0105c5f <strtol+0x15>
		s++;
f0105c5c:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0105c5f:	0f b6 01             	movzbl (%ecx),%eax
f0105c62:	3c 20                	cmp    $0x20,%al
f0105c64:	74 f6                	je     f0105c5c <strtol+0x12>
f0105c66:	3c 09                	cmp    $0x9,%al
f0105c68:	74 f2                	je     f0105c5c <strtol+0x12>

	// plus/minus sign
	if (*s == '+')
f0105c6a:	3c 2b                	cmp    $0x2b,%al
f0105c6c:	74 2a                	je     f0105c98 <strtol+0x4e>
	int neg = 0;
f0105c6e:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0105c73:	3c 2d                	cmp    $0x2d,%al
f0105c75:	74 2b                	je     f0105ca2 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105c77:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0105c7d:	75 0f                	jne    f0105c8e <strtol+0x44>
f0105c7f:	80 39 30             	cmpb   $0x30,(%ecx)
f0105c82:	74 28                	je     f0105cac <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105c84:	85 db                	test   %ebx,%ebx
f0105c86:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105c8b:	0f 44 d8             	cmove  %eax,%ebx
f0105c8e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105c93:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105c96:	eb 46                	jmp    f0105cde <strtol+0x94>
		s++;
f0105c98:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0105c9b:	bf 00 00 00 00       	mov    $0x0,%edi
f0105ca0:	eb d5                	jmp    f0105c77 <strtol+0x2d>
		s++, neg = 1;
f0105ca2:	83 c1 01             	add    $0x1,%ecx
f0105ca5:	bf 01 00 00 00       	mov    $0x1,%edi
f0105caa:	eb cb                	jmp    f0105c77 <strtol+0x2d>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105cac:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105cb0:	74 0e                	je     f0105cc0 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0105cb2:	85 db                	test   %ebx,%ebx
f0105cb4:	75 d8                	jne    f0105c8e <strtol+0x44>
		s++, base = 8;
f0105cb6:	83 c1 01             	add    $0x1,%ecx
f0105cb9:	bb 08 00 00 00       	mov    $0x8,%ebx
f0105cbe:	eb ce                	jmp    f0105c8e <strtol+0x44>
		s += 2, base = 16;
f0105cc0:	83 c1 02             	add    $0x2,%ecx
f0105cc3:	bb 10 00 00 00       	mov    $0x10,%ebx
f0105cc8:	eb c4                	jmp    f0105c8e <strtol+0x44>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f0105cca:	0f be d2             	movsbl %dl,%edx
f0105ccd:	83 ea 30             	sub    $0x30,%edx
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0105cd0:	3b 55 10             	cmp    0x10(%ebp),%edx
f0105cd3:	7d 3a                	jge    f0105d0f <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0105cd5:	83 c1 01             	add    $0x1,%ecx
f0105cd8:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105cdc:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0105cde:	0f b6 11             	movzbl (%ecx),%edx
f0105ce1:	8d 72 d0             	lea    -0x30(%edx),%esi
f0105ce4:	89 f3                	mov    %esi,%ebx
f0105ce6:	80 fb 09             	cmp    $0x9,%bl
f0105ce9:	76 df                	jbe    f0105cca <strtol+0x80>
		else if (*s >= 'a' && *s <= 'z')
f0105ceb:	8d 72 9f             	lea    -0x61(%edx),%esi
f0105cee:	89 f3                	mov    %esi,%ebx
f0105cf0:	80 fb 19             	cmp    $0x19,%bl
f0105cf3:	77 08                	ja     f0105cfd <strtol+0xb3>
			dig = *s - 'a' + 10;
f0105cf5:	0f be d2             	movsbl %dl,%edx
f0105cf8:	83 ea 57             	sub    $0x57,%edx
f0105cfb:	eb d3                	jmp    f0105cd0 <strtol+0x86>
		else if (*s >= 'A' && *s <= 'Z')
f0105cfd:	8d 72 bf             	lea    -0x41(%edx),%esi
f0105d00:	89 f3                	mov    %esi,%ebx
f0105d02:	80 fb 19             	cmp    $0x19,%bl
f0105d05:	77 08                	ja     f0105d0f <strtol+0xc5>
			dig = *s - 'A' + 10;
f0105d07:	0f be d2             	movsbl %dl,%edx
f0105d0a:	83 ea 37             	sub    $0x37,%edx
f0105d0d:	eb c1                	jmp    f0105cd0 <strtol+0x86>
		// we don't properly detect overflow!
	}

	if (endptr)
f0105d0f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105d13:	74 05                	je     f0105d1a <strtol+0xd0>
		*endptr = (char *) s;
f0105d15:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105d18:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0105d1a:	89 c2                	mov    %eax,%edx
f0105d1c:	f7 da                	neg    %edx
f0105d1e:	85 ff                	test   %edi,%edi
f0105d20:	0f 45 c2             	cmovne %edx,%eax
}
f0105d23:	5b                   	pop    %ebx
f0105d24:	5e                   	pop    %esi
f0105d25:	5f                   	pop    %edi
f0105d26:	5d                   	pop    %ebp
f0105d27:	c3                   	ret    

f0105d28 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0105d28:	fa                   	cli    

	xorw    %ax, %ax
f0105d29:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0105d2b:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105d2d:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105d2f:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105d31:	0f 01 16             	lgdtl  (%esi)
f0105d34:	74 70                	je     f0105da6 <mpsearch1+0x3>
	movl    %cr0, %eax
f0105d36:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0105d39:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105d3d:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105d40:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0105d46:	08 00                	or     %al,(%eax)

f0105d48 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0105d48:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105d4c:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105d4e:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105d50:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105d52:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0105d56:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0105d58:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0105d5a:	b8 00 10 12 00       	mov    $0x121000,%eax
	movl    %eax, %cr3
f0105d5f:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105d62:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105d65:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0105d6a:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0105d6d:	8b 25 84 7e 21 f0    	mov    0xf0217e84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105d73:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0105d78:	b8 bd 01 10 f0       	mov    $0xf01001bd,%eax
	call    *%eax
f0105d7d:	ff d0                	call   *%eax

f0105d7f <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105d7f:	eb fe                	jmp    f0105d7f <spin>
f0105d81:	8d 76 00             	lea    0x0(%esi),%esi

f0105d84 <gdt>:
	...
f0105d8c:	ff                   	(bad)  
f0105d8d:	ff 00                	incl   (%eax)
f0105d8f:	00 00                	add    %al,(%eax)
f0105d91:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105d98:	00                   	.byte 0x0
f0105d99:	92                   	xchg   %eax,%edx
f0105d9a:	cf                   	iret   
	...

f0105d9c <gdtdesc>:
f0105d9c:	17                   	pop    %ss
f0105d9d:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105da2 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105da2:	90                   	nop

f0105da3 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105da3:	55                   	push   %ebp
f0105da4:	89 e5                	mov    %esp,%ebp
f0105da6:	57                   	push   %edi
f0105da7:	56                   	push   %esi
f0105da8:	53                   	push   %ebx
f0105da9:	83 ec 0c             	sub    $0xc,%esp
f0105dac:	89 c7                	mov    %eax,%edi
	if (PGNUM(pa) >= npages)
f0105dae:	a1 88 7e 21 f0       	mov    0xf0217e88,%eax
f0105db3:	89 f9                	mov    %edi,%ecx
f0105db5:	c1 e9 0c             	shr    $0xc,%ecx
f0105db8:	39 c1                	cmp    %eax,%ecx
f0105dba:	73 19                	jae    f0105dd5 <mpsearch1+0x32>
	return (void *)(pa + KERNBASE);
f0105dbc:	8d 9f 00 00 00 f0    	lea    -0x10000000(%edi),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105dc2:	01 d7                	add    %edx,%edi
	if (PGNUM(pa) >= npages)
f0105dc4:	89 fa                	mov    %edi,%edx
f0105dc6:	c1 ea 0c             	shr    $0xc,%edx
f0105dc9:	39 c2                	cmp    %eax,%edx
f0105dcb:	73 1a                	jae    f0105de7 <mpsearch1+0x44>
	return (void *)(pa + KERNBASE);
f0105dcd:	81 ef 00 00 00 10    	sub    $0x10000000,%edi

	for (; mp < end; mp++)
f0105dd3:	eb 27                	jmp    f0105dfc <mpsearch1+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105dd5:	57                   	push   %edi
f0105dd6:	68 e4 67 10 f0       	push   $0xf01067e4
f0105ddb:	6a 57                	push   $0x57
f0105ddd:	68 5d 85 10 f0       	push   $0xf010855d
f0105de2:	e8 59 a2 ff ff       	call   f0100040 <_panic>
f0105de7:	57                   	push   %edi
f0105de8:	68 e4 67 10 f0       	push   $0xf01067e4
f0105ded:	6a 57                	push   $0x57
f0105def:	68 5d 85 10 f0       	push   $0xf010855d
f0105df4:	e8 47 a2 ff ff       	call   f0100040 <_panic>
f0105df9:	83 c3 10             	add    $0x10,%ebx
f0105dfc:	39 fb                	cmp    %edi,%ebx
f0105dfe:	73 30                	jae    f0105e30 <mpsearch1+0x8d>
f0105e00:	89 de                	mov    %ebx,%esi
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105e02:	83 ec 04             	sub    $0x4,%esp
f0105e05:	6a 04                	push   $0x4
f0105e07:	68 6d 85 10 f0       	push   $0xf010856d
f0105e0c:	53                   	push   %ebx
f0105e0d:	e8 da fd ff ff       	call   f0105bec <memcmp>
f0105e12:	83 c4 10             	add    $0x10,%esp
f0105e15:	85 c0                	test   %eax,%eax
f0105e17:	75 e0                	jne    f0105df9 <mpsearch1+0x56>
f0105e19:	89 da                	mov    %ebx,%edx
	for (i = 0; i < len; i++)
f0105e1b:	83 c6 10             	add    $0x10,%esi
		sum += ((uint8_t *)addr)[i];
f0105e1e:	0f b6 0a             	movzbl (%edx),%ecx
f0105e21:	01 c8                	add    %ecx,%eax
f0105e23:	83 c2 01             	add    $0x1,%edx
	for (i = 0; i < len; i++)
f0105e26:	39 f2                	cmp    %esi,%edx
f0105e28:	75 f4                	jne    f0105e1e <mpsearch1+0x7b>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105e2a:	84 c0                	test   %al,%al
f0105e2c:	75 cb                	jne    f0105df9 <mpsearch1+0x56>
f0105e2e:	eb 05                	jmp    f0105e35 <mpsearch1+0x92>
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0105e30:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0105e35:	89 d8                	mov    %ebx,%eax
f0105e37:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105e3a:	5b                   	pop    %ebx
f0105e3b:	5e                   	pop    %esi
f0105e3c:	5f                   	pop    %edi
f0105e3d:	5d                   	pop    %ebp
f0105e3e:	c3                   	ret    

f0105e3f <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105e3f:	f3 0f 1e fb          	endbr32 
f0105e43:	55                   	push   %ebp
f0105e44:	89 e5                	mov    %esp,%ebp
f0105e46:	57                   	push   %edi
f0105e47:	56                   	push   %esi
f0105e48:	53                   	push   %ebx
f0105e49:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105e4c:	c7 05 c0 83 21 f0 20 	movl   $0xf0218020,0xf02183c0
f0105e53:	80 21 f0 
	if (PGNUM(pa) >= npages)
f0105e56:	83 3d 88 7e 21 f0 00 	cmpl   $0x0,0xf0217e88
f0105e5d:	0f 84 a3 00 00 00    	je     f0105f06 <mp_init+0xc7>
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105e63:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105e6a:	85 c0                	test   %eax,%eax
f0105e6c:	0f 84 aa 00 00 00    	je     f0105f1c <mp_init+0xdd>
		p <<= 4;	// Translate from segment to PA
f0105e72:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0105e75:	ba 00 04 00 00       	mov    $0x400,%edx
f0105e7a:	e8 24 ff ff ff       	call   f0105da3 <mpsearch1>
f0105e7f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105e82:	85 c0                	test   %eax,%eax
f0105e84:	75 1a                	jne    f0105ea0 <mp_init+0x61>
	return mpsearch1(0xF0000, 0x10000);
f0105e86:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105e8b:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105e90:	e8 0e ff ff ff       	call   f0105da3 <mpsearch1>
f0105e95:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if ((mp = mpsearch()) == 0)
f0105e98:	85 c0                	test   %eax,%eax
f0105e9a:	0f 84 35 02 00 00    	je     f01060d5 <mp_init+0x296>
	if (mp->physaddr == 0 || mp->type != 0) {
f0105ea0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105ea3:	8b 58 04             	mov    0x4(%eax),%ebx
f0105ea6:	85 db                	test   %ebx,%ebx
f0105ea8:	0f 84 97 00 00 00    	je     f0105f45 <mp_init+0x106>
f0105eae:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0105eb2:	0f 85 8d 00 00 00    	jne    f0105f45 <mp_init+0x106>
f0105eb8:	89 d8                	mov    %ebx,%eax
f0105eba:	c1 e8 0c             	shr    $0xc,%eax
f0105ebd:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0105ec3:	0f 83 91 00 00 00    	jae    f0105f5a <mp_init+0x11b>
	return (void *)(pa + KERNBASE);
f0105ec9:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
f0105ecf:	89 de                	mov    %ebx,%esi
	if (memcmp(conf, "PCMP", 4) != 0) {
f0105ed1:	83 ec 04             	sub    $0x4,%esp
f0105ed4:	6a 04                	push   $0x4
f0105ed6:	68 72 85 10 f0       	push   $0xf0108572
f0105edb:	53                   	push   %ebx
f0105edc:	e8 0b fd ff ff       	call   f0105bec <memcmp>
f0105ee1:	83 c4 10             	add    $0x10,%esp
f0105ee4:	85 c0                	test   %eax,%eax
f0105ee6:	0f 85 83 00 00 00    	jne    f0105f6f <mp_init+0x130>
f0105eec:	0f b7 7b 04          	movzwl 0x4(%ebx),%edi
f0105ef0:	01 df                	add    %ebx,%edi
	sum = 0;
f0105ef2:	89 c2                	mov    %eax,%edx
	for (i = 0; i < len; i++)
f0105ef4:	39 fb                	cmp    %edi,%ebx
f0105ef6:	0f 84 88 00 00 00    	je     f0105f84 <mp_init+0x145>
		sum += ((uint8_t *)addr)[i];
f0105efc:	0f b6 0b             	movzbl (%ebx),%ecx
f0105eff:	01 ca                	add    %ecx,%edx
f0105f01:	83 c3 01             	add    $0x1,%ebx
f0105f04:	eb ee                	jmp    f0105ef4 <mp_init+0xb5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105f06:	68 00 04 00 00       	push   $0x400
f0105f0b:	68 e4 67 10 f0       	push   $0xf01067e4
f0105f10:	6a 6f                	push   $0x6f
f0105f12:	68 5d 85 10 f0       	push   $0xf010855d
f0105f17:	e8 24 a1 ff ff       	call   f0100040 <_panic>
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0105f1c:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105f23:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105f26:	2d 00 04 00 00       	sub    $0x400,%eax
f0105f2b:	ba 00 04 00 00       	mov    $0x400,%edx
f0105f30:	e8 6e fe ff ff       	call   f0105da3 <mpsearch1>
f0105f35:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105f38:	85 c0                	test   %eax,%eax
f0105f3a:	0f 85 60 ff ff ff    	jne    f0105ea0 <mp_init+0x61>
f0105f40:	e9 41 ff ff ff       	jmp    f0105e86 <mp_init+0x47>
		cprintf("SMP: Default configurations not implemented\n");
f0105f45:	83 ec 0c             	sub    $0xc,%esp
f0105f48:	68 d0 83 10 f0       	push   $0xf01083d0
f0105f4d:	e8 68 da ff ff       	call   f01039ba <cprintf>
		return NULL;
f0105f52:	83 c4 10             	add    $0x10,%esp
f0105f55:	e9 7b 01 00 00       	jmp    f01060d5 <mp_init+0x296>
f0105f5a:	53                   	push   %ebx
f0105f5b:	68 e4 67 10 f0       	push   $0xf01067e4
f0105f60:	68 90 00 00 00       	push   $0x90
f0105f65:	68 5d 85 10 f0       	push   $0xf010855d
f0105f6a:	e8 d1 a0 ff ff       	call   f0100040 <_panic>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105f6f:	83 ec 0c             	sub    $0xc,%esp
f0105f72:	68 00 84 10 f0       	push   $0xf0108400
f0105f77:	e8 3e da ff ff       	call   f01039ba <cprintf>
		return NULL;
f0105f7c:	83 c4 10             	add    $0x10,%esp
f0105f7f:	e9 51 01 00 00       	jmp    f01060d5 <mp_init+0x296>
	if (sum(conf, conf->length) != 0) {
f0105f84:	84 d2                	test   %dl,%dl
f0105f86:	75 22                	jne    f0105faa <mp_init+0x16b>
	if (conf->version != 1 && conf->version != 4) {
f0105f88:	0f b6 56 06          	movzbl 0x6(%esi),%edx
f0105f8c:	80 fa 01             	cmp    $0x1,%dl
f0105f8f:	74 05                	je     f0105f96 <mp_init+0x157>
f0105f91:	80 fa 04             	cmp    $0x4,%dl
f0105f94:	75 29                	jne    f0105fbf <mp_init+0x180>
f0105f96:	0f b7 4e 28          	movzwl 0x28(%esi),%ecx
f0105f9a:	01 d9                	add    %ebx,%ecx
	for (i = 0; i < len; i++)
f0105f9c:	39 d9                	cmp    %ebx,%ecx
f0105f9e:	74 38                	je     f0105fd8 <mp_init+0x199>
		sum += ((uint8_t *)addr)[i];
f0105fa0:	0f b6 13             	movzbl (%ebx),%edx
f0105fa3:	01 d0                	add    %edx,%eax
f0105fa5:	83 c3 01             	add    $0x1,%ebx
f0105fa8:	eb f2                	jmp    f0105f9c <mp_init+0x15d>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105faa:	83 ec 0c             	sub    $0xc,%esp
f0105fad:	68 34 84 10 f0       	push   $0xf0108434
f0105fb2:	e8 03 da ff ff       	call   f01039ba <cprintf>
		return NULL;
f0105fb7:	83 c4 10             	add    $0x10,%esp
f0105fba:	e9 16 01 00 00       	jmp    f01060d5 <mp_init+0x296>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105fbf:	83 ec 08             	sub    $0x8,%esp
f0105fc2:	0f b6 d2             	movzbl %dl,%edx
f0105fc5:	52                   	push   %edx
f0105fc6:	68 58 84 10 f0       	push   $0xf0108458
f0105fcb:	e8 ea d9 ff ff       	call   f01039ba <cprintf>
		return NULL;
f0105fd0:	83 c4 10             	add    $0x10,%esp
f0105fd3:	e9 fd 00 00 00       	jmp    f01060d5 <mp_init+0x296>
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105fd8:	02 46 2a             	add    0x2a(%esi),%al
f0105fdb:	75 1c                	jne    f0105ff9 <mp_init+0x1ba>
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
f0105fdd:	c7 05 00 80 21 f0 01 	movl   $0x1,0xf0218000
f0105fe4:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105fe7:	8b 46 24             	mov    0x24(%esi),%eax
f0105fea:	a3 00 90 25 f0       	mov    %eax,0xf0259000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105fef:	8d 7e 2c             	lea    0x2c(%esi),%edi
f0105ff2:	bb 00 00 00 00       	mov    $0x0,%ebx
f0105ff7:	eb 4d                	jmp    f0106046 <mp_init+0x207>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105ff9:	83 ec 0c             	sub    $0xc,%esp
f0105ffc:	68 78 84 10 f0       	push   $0xf0108478
f0106001:	e8 b4 d9 ff ff       	call   f01039ba <cprintf>
		return NULL;
f0106006:	83 c4 10             	add    $0x10,%esp
f0106009:	e9 c7 00 00 00       	jmp    f01060d5 <mp_init+0x296>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f010600e:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0106012:	74 11                	je     f0106025 <mp_init+0x1e6>
				bootcpu = &cpus[ncpu];
f0106014:	6b 05 c4 83 21 f0 74 	imul   $0x74,0xf02183c4,%eax
f010601b:	05 20 80 21 f0       	add    $0xf0218020,%eax
f0106020:	a3 c0 83 21 f0       	mov    %eax,0xf02183c0
			if (ncpu < NCPU) {
f0106025:	a1 c4 83 21 f0       	mov    0xf02183c4,%eax
f010602a:	83 f8 07             	cmp    $0x7,%eax
f010602d:	7f 33                	jg     f0106062 <mp_init+0x223>
				cpus[ncpu].cpu_id = ncpu;
f010602f:	6b d0 74             	imul   $0x74,%eax,%edx
f0106032:	88 82 20 80 21 f0    	mov    %al,-0xfde7fe0(%edx)
				ncpu++;
f0106038:	83 c0 01             	add    $0x1,%eax
f010603b:	a3 c4 83 21 f0       	mov    %eax,0xf02183c4
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0106040:	83 c7 14             	add    $0x14,%edi
	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0106043:	83 c3 01             	add    $0x1,%ebx
f0106046:	0f b7 46 22          	movzwl 0x22(%esi),%eax
f010604a:	39 d8                	cmp    %ebx,%eax
f010604c:	76 4f                	jbe    f010609d <mp_init+0x25e>
		switch (*p) {
f010604e:	0f b6 07             	movzbl (%edi),%eax
f0106051:	84 c0                	test   %al,%al
f0106053:	74 b9                	je     f010600e <mp_init+0x1cf>
f0106055:	8d 50 ff             	lea    -0x1(%eax),%edx
f0106058:	80 fa 03             	cmp    $0x3,%dl
f010605b:	77 1c                	ja     f0106079 <mp_init+0x23a>
			continue;
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f010605d:	83 c7 08             	add    $0x8,%edi
			continue;
f0106060:	eb e1                	jmp    f0106043 <mp_init+0x204>
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0106062:	83 ec 08             	sub    $0x8,%esp
f0106065:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0106069:	50                   	push   %eax
f010606a:	68 a8 84 10 f0       	push   $0xf01084a8
f010606f:	e8 46 d9 ff ff       	call   f01039ba <cprintf>
f0106074:	83 c4 10             	add    $0x10,%esp
f0106077:	eb c7                	jmp    f0106040 <mp_init+0x201>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0106079:	83 ec 08             	sub    $0x8,%esp
		switch (*p) {
f010607c:	0f b6 c0             	movzbl %al,%eax
			cprintf("mpinit: unknown config type %x\n", *p);
f010607f:	50                   	push   %eax
f0106080:	68 d0 84 10 f0       	push   $0xf01084d0
f0106085:	e8 30 d9 ff ff       	call   f01039ba <cprintf>
			ismp = 0;
f010608a:	c7 05 00 80 21 f0 00 	movl   $0x0,0xf0218000
f0106091:	00 00 00 
			i = conf->entry;
f0106094:	0f b7 5e 22          	movzwl 0x22(%esi),%ebx
f0106098:	83 c4 10             	add    $0x10,%esp
f010609b:	eb a6                	jmp    f0106043 <mp_init+0x204>
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f010609d:	a1 c0 83 21 f0       	mov    0xf02183c0,%eax
f01060a2:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f01060a9:	83 3d 00 80 21 f0 00 	cmpl   $0x0,0xf0218000
f01060b0:	74 2b                	je     f01060dd <mp_init+0x29e>
		ncpu = 1;
		lapicaddr = 0;
		cprintf("SMP: configuration not found, SMP disabled\n");
		return;
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f01060b2:	83 ec 04             	sub    $0x4,%esp
f01060b5:	ff 35 c4 83 21 f0    	pushl  0xf02183c4
f01060bb:	0f b6 00             	movzbl (%eax),%eax
f01060be:	50                   	push   %eax
f01060bf:	68 77 85 10 f0       	push   $0xf0108577
f01060c4:	e8 f1 d8 ff ff       	call   f01039ba <cprintf>

	if (mp->imcrp) {
f01060c9:	83 c4 10             	add    $0x10,%esp
f01060cc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01060cf:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f01060d3:	75 2e                	jne    f0106103 <mp_init+0x2c4>
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f01060d5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01060d8:	5b                   	pop    %ebx
f01060d9:	5e                   	pop    %esi
f01060da:	5f                   	pop    %edi
f01060db:	5d                   	pop    %ebp
f01060dc:	c3                   	ret    
		ncpu = 1;
f01060dd:	c7 05 c4 83 21 f0 01 	movl   $0x1,0xf02183c4
f01060e4:	00 00 00 
		lapicaddr = 0;
f01060e7:	c7 05 00 90 25 f0 00 	movl   $0x0,0xf0259000
f01060ee:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f01060f1:	83 ec 0c             	sub    $0xc,%esp
f01060f4:	68 f0 84 10 f0       	push   $0xf01084f0
f01060f9:	e8 bc d8 ff ff       	call   f01039ba <cprintf>
		return;
f01060fe:	83 c4 10             	add    $0x10,%esp
f0106101:	eb d2                	jmp    f01060d5 <mp_init+0x296>
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0106103:	83 ec 0c             	sub    $0xc,%esp
f0106106:	68 1c 85 10 f0       	push   $0xf010851c
f010610b:	e8 aa d8 ff ff       	call   f01039ba <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0106110:	b8 70 00 00 00       	mov    $0x70,%eax
f0106115:	ba 22 00 00 00       	mov    $0x22,%edx
f010611a:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010611b:	ba 23 00 00 00       	mov    $0x23,%edx
f0106120:	ec                   	in     (%dx),%al
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0106121:	83 c8 01             	or     $0x1,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0106124:	ee                   	out    %al,(%dx)
}
f0106125:	83 c4 10             	add    $0x10,%esp
f0106128:	eb ab                	jmp    f01060d5 <mp_init+0x296>

f010612a <lapicw>:
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
	lapic[index] = value;
f010612a:	8b 0d 04 90 25 f0    	mov    0xf0259004,%ecx
f0106130:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0106133:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0106135:	a1 04 90 25 f0       	mov    0xf0259004,%eax
f010613a:	8b 40 20             	mov    0x20(%eax),%eax
}
f010613d:	c3                   	ret    

f010613e <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f010613e:	f3 0f 1e fb          	endbr32 
	if (lapic)
f0106142:	8b 15 04 90 25 f0    	mov    0xf0259004,%edx
		return lapic[ID] >> 24;
	return 0;
f0106148:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lapic)
f010614d:	85 d2                	test   %edx,%edx
f010614f:	74 06                	je     f0106157 <cpunum+0x19>
		return lapic[ID] >> 24;
f0106151:	8b 42 20             	mov    0x20(%edx),%eax
f0106154:	c1 e8 18             	shr    $0x18,%eax
}
f0106157:	c3                   	ret    

f0106158 <lapic_init>:
{
f0106158:	f3 0f 1e fb          	endbr32 
	if (!lapicaddr)
f010615c:	a1 00 90 25 f0       	mov    0xf0259000,%eax
f0106161:	85 c0                	test   %eax,%eax
f0106163:	75 01                	jne    f0106166 <lapic_init+0xe>
f0106165:	c3                   	ret    
{
f0106166:	55                   	push   %ebp
f0106167:	89 e5                	mov    %esp,%ebp
f0106169:	83 ec 10             	sub    $0x10,%esp
	lapic = mmio_map_region(lapicaddr, 4096);
f010616c:	68 00 10 00 00       	push   $0x1000
f0106171:	50                   	push   %eax
f0106172:	e8 8b b1 ff ff       	call   f0101302 <mmio_map_region>
f0106177:	a3 04 90 25 f0       	mov    %eax,0xf0259004
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f010617c:	ba 27 01 00 00       	mov    $0x127,%edx
f0106181:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0106186:	e8 9f ff ff ff       	call   f010612a <lapicw>
	lapicw(TDCR, X1);
f010618b:	ba 0b 00 00 00       	mov    $0xb,%edx
f0106190:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0106195:	e8 90 ff ff ff       	call   f010612a <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f010619a:	ba 20 00 02 00       	mov    $0x20020,%edx
f010619f:	b8 c8 00 00 00       	mov    $0xc8,%eax
f01061a4:	e8 81 ff ff ff       	call   f010612a <lapicw>
	lapicw(TICR, 10000000); 
f01061a9:	ba 80 96 98 00       	mov    $0x989680,%edx
f01061ae:	b8 e0 00 00 00       	mov    $0xe0,%eax
f01061b3:	e8 72 ff ff ff       	call   f010612a <lapicw>
	if (thiscpu != bootcpu)
f01061b8:	e8 81 ff ff ff       	call   f010613e <cpunum>
f01061bd:	6b c0 74             	imul   $0x74,%eax,%eax
f01061c0:	05 20 80 21 f0       	add    $0xf0218020,%eax
f01061c5:	83 c4 10             	add    $0x10,%esp
f01061c8:	39 05 c0 83 21 f0    	cmp    %eax,0xf02183c0
f01061ce:	74 0f                	je     f01061df <lapic_init+0x87>
		lapicw(LINT0, MASKED);
f01061d0:	ba 00 00 01 00       	mov    $0x10000,%edx
f01061d5:	b8 d4 00 00 00       	mov    $0xd4,%eax
f01061da:	e8 4b ff ff ff       	call   f010612a <lapicw>
	lapicw(LINT1, MASKED);
f01061df:	ba 00 00 01 00       	mov    $0x10000,%edx
f01061e4:	b8 d8 00 00 00       	mov    $0xd8,%eax
f01061e9:	e8 3c ff ff ff       	call   f010612a <lapicw>
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f01061ee:	a1 04 90 25 f0       	mov    0xf0259004,%eax
f01061f3:	8b 40 30             	mov    0x30(%eax),%eax
f01061f6:	c1 e8 10             	shr    $0x10,%eax
f01061f9:	a8 fc                	test   $0xfc,%al
f01061fb:	75 7c                	jne    f0106279 <lapic_init+0x121>
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f01061fd:	ba 33 00 00 00       	mov    $0x33,%edx
f0106202:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0106207:	e8 1e ff ff ff       	call   f010612a <lapicw>
	lapicw(ESR, 0);
f010620c:	ba 00 00 00 00       	mov    $0x0,%edx
f0106211:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0106216:	e8 0f ff ff ff       	call   f010612a <lapicw>
	lapicw(ESR, 0);
f010621b:	ba 00 00 00 00       	mov    $0x0,%edx
f0106220:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0106225:	e8 00 ff ff ff       	call   f010612a <lapicw>
	lapicw(EOI, 0);
f010622a:	ba 00 00 00 00       	mov    $0x0,%edx
f010622f:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0106234:	e8 f1 fe ff ff       	call   f010612a <lapicw>
	lapicw(ICRHI, 0);
f0106239:	ba 00 00 00 00       	mov    $0x0,%edx
f010623e:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106243:	e8 e2 fe ff ff       	call   f010612a <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0106248:	ba 00 85 08 00       	mov    $0x88500,%edx
f010624d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106252:	e8 d3 fe ff ff       	call   f010612a <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0106257:	8b 15 04 90 25 f0    	mov    0xf0259004,%edx
f010625d:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0106263:	f6 c4 10             	test   $0x10,%ah
f0106266:	75 f5                	jne    f010625d <lapic_init+0x105>
	lapicw(TPR, 0);
f0106268:	ba 00 00 00 00       	mov    $0x0,%edx
f010626d:	b8 20 00 00 00       	mov    $0x20,%eax
f0106272:	e8 b3 fe ff ff       	call   f010612a <lapicw>
}
f0106277:	c9                   	leave  
f0106278:	c3                   	ret    
		lapicw(PCINT, MASKED);
f0106279:	ba 00 00 01 00       	mov    $0x10000,%edx
f010627e:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0106283:	e8 a2 fe ff ff       	call   f010612a <lapicw>
f0106288:	e9 70 ff ff ff       	jmp    f01061fd <lapic_init+0xa5>

f010628d <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f010628d:	f3 0f 1e fb          	endbr32 
	if (lapic)
f0106291:	83 3d 04 90 25 f0 00 	cmpl   $0x0,0xf0259004
f0106298:	74 17                	je     f01062b1 <lapic_eoi+0x24>
{
f010629a:	55                   	push   %ebp
f010629b:	89 e5                	mov    %esp,%ebp
f010629d:	83 ec 08             	sub    $0x8,%esp
		lapicw(EOI, 0);
f01062a0:	ba 00 00 00 00       	mov    $0x0,%edx
f01062a5:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01062aa:	e8 7b fe ff ff       	call   f010612a <lapicw>
}
f01062af:	c9                   	leave  
f01062b0:	c3                   	ret    
f01062b1:	c3                   	ret    

f01062b2 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f01062b2:	f3 0f 1e fb          	endbr32 
f01062b6:	55                   	push   %ebp
f01062b7:	89 e5                	mov    %esp,%ebp
f01062b9:	56                   	push   %esi
f01062ba:	53                   	push   %ebx
f01062bb:	8b 75 08             	mov    0x8(%ebp),%esi
f01062be:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01062c1:	b8 0f 00 00 00       	mov    $0xf,%eax
f01062c6:	ba 70 00 00 00       	mov    $0x70,%edx
f01062cb:	ee                   	out    %al,(%dx)
f01062cc:	b8 0a 00 00 00       	mov    $0xa,%eax
f01062d1:	ba 71 00 00 00       	mov    $0x71,%edx
f01062d6:	ee                   	out    %al,(%dx)
	if (PGNUM(pa) >= npages)
f01062d7:	83 3d 88 7e 21 f0 00 	cmpl   $0x0,0xf0217e88
f01062de:	74 7e                	je     f010635e <lapic_startap+0xac>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f01062e0:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f01062e7:	00 00 
	wrv[1] = addr >> 4;
f01062e9:	89 d8                	mov    %ebx,%eax
f01062eb:	c1 e8 04             	shr    $0x4,%eax
f01062ee:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f01062f4:	c1 e6 18             	shl    $0x18,%esi
f01062f7:	89 f2                	mov    %esi,%edx
f01062f9:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01062fe:	e8 27 fe ff ff       	call   f010612a <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0106303:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0106308:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010630d:	e8 18 fe ff ff       	call   f010612a <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0106312:	ba 00 85 00 00       	mov    $0x8500,%edx
f0106317:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010631c:	e8 09 fe ff ff       	call   f010612a <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106321:	c1 eb 0c             	shr    $0xc,%ebx
f0106324:	80 cf 06             	or     $0x6,%bh
		lapicw(ICRHI, apicid << 24);
f0106327:	89 f2                	mov    %esi,%edx
f0106329:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010632e:	e8 f7 fd ff ff       	call   f010612a <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106333:	89 da                	mov    %ebx,%edx
f0106335:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010633a:	e8 eb fd ff ff       	call   f010612a <lapicw>
		lapicw(ICRHI, apicid << 24);
f010633f:	89 f2                	mov    %esi,%edx
f0106341:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106346:	e8 df fd ff ff       	call   f010612a <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f010634b:	89 da                	mov    %ebx,%edx
f010634d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106352:	e8 d3 fd ff ff       	call   f010612a <lapicw>
		microdelay(200);
	}
}
f0106357:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010635a:	5b                   	pop    %ebx
f010635b:	5e                   	pop    %esi
f010635c:	5d                   	pop    %ebp
f010635d:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010635e:	68 67 04 00 00       	push   $0x467
f0106363:	68 e4 67 10 f0       	push   $0xf01067e4
f0106368:	68 98 00 00 00       	push   $0x98
f010636d:	68 94 85 10 f0       	push   $0xf0108594
f0106372:	e8 c9 9c ff ff       	call   f0100040 <_panic>

f0106377 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0106377:	f3 0f 1e fb          	endbr32 
f010637b:	55                   	push   %ebp
f010637c:	89 e5                	mov    %esp,%ebp
f010637e:	83 ec 08             	sub    $0x8,%esp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0106381:	8b 55 08             	mov    0x8(%ebp),%edx
f0106384:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f010638a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010638f:	e8 96 fd ff ff       	call   f010612a <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0106394:	8b 15 04 90 25 f0    	mov    0xf0259004,%edx
f010639a:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f01063a0:	f6 c4 10             	test   $0x10,%ah
f01063a3:	75 f5                	jne    f010639a <lapic_ipi+0x23>
		;
}
f01063a5:	c9                   	leave  
f01063a6:	c3                   	ret    

f01063a7 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f01063a7:	f3 0f 1e fb          	endbr32 
f01063ab:	55                   	push   %ebp
f01063ac:	89 e5                	mov    %esp,%ebp
f01063ae:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f01063b1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f01063b7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01063ba:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f01063bd:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f01063c4:	5d                   	pop    %ebp
f01063c5:	c3                   	ret    

f01063c6 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f01063c6:	f3 0f 1e fb          	endbr32 
f01063ca:	55                   	push   %ebp
f01063cb:	89 e5                	mov    %esp,%ebp
f01063cd:	56                   	push   %esi
f01063ce:	53                   	push   %ebx
f01063cf:	8b 5d 08             	mov    0x8(%ebp),%ebx
	return lock->locked && lock->cpu == thiscpu;
f01063d2:	83 3b 00             	cmpl   $0x0,(%ebx)
f01063d5:	75 07                	jne    f01063de <spin_lock+0x18>
	asm volatile("lock; xchgl %0, %1"
f01063d7:	ba 01 00 00 00       	mov    $0x1,%edx
f01063dc:	eb 34                	jmp    f0106412 <spin_lock+0x4c>
f01063de:	8b 73 08             	mov    0x8(%ebx),%esi
f01063e1:	e8 58 fd ff ff       	call   f010613e <cpunum>
f01063e6:	6b c0 74             	imul   $0x74,%eax,%eax
f01063e9:	05 20 80 21 f0       	add    $0xf0218020,%eax
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f01063ee:	39 c6                	cmp    %eax,%esi
f01063f0:	75 e5                	jne    f01063d7 <spin_lock+0x11>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f01063f2:	8b 5b 04             	mov    0x4(%ebx),%ebx
f01063f5:	e8 44 fd ff ff       	call   f010613e <cpunum>
f01063fa:	83 ec 0c             	sub    $0xc,%esp
f01063fd:	53                   	push   %ebx
f01063fe:	50                   	push   %eax
f01063ff:	68 a4 85 10 f0       	push   $0xf01085a4
f0106404:	6a 41                	push   $0x41
f0106406:	68 06 86 10 f0       	push   $0xf0108606
f010640b:	e8 30 9c ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0106410:	f3 90                	pause  
f0106412:	89 d0                	mov    %edx,%eax
f0106414:	f0 87 03             	lock xchg %eax,(%ebx)
	while (xchg(&lk->locked, 1) != 0)
f0106417:	85 c0                	test   %eax,%eax
f0106419:	75 f5                	jne    f0106410 <spin_lock+0x4a>

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f010641b:	e8 1e fd ff ff       	call   f010613e <cpunum>
f0106420:	6b c0 74             	imul   $0x74,%eax,%eax
f0106423:	05 20 80 21 f0       	add    $0xf0218020,%eax
f0106428:	89 43 08             	mov    %eax,0x8(%ebx)
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010642b:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f010642d:	b8 00 00 00 00       	mov    $0x0,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0106432:	83 f8 09             	cmp    $0x9,%eax
f0106435:	7f 21                	jg     f0106458 <spin_lock+0x92>
f0106437:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f010643d:	76 19                	jbe    f0106458 <spin_lock+0x92>
		pcs[i] = ebp[1];          // saved %eip
f010643f:	8b 4a 04             	mov    0x4(%edx),%ecx
f0106442:	89 4c 83 0c          	mov    %ecx,0xc(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0106446:	8b 12                	mov    (%edx),%edx
	for (i = 0; i < 10; i++){
f0106448:	83 c0 01             	add    $0x1,%eax
f010644b:	eb e5                	jmp    f0106432 <spin_lock+0x6c>
		pcs[i] = 0;
f010644d:	c7 44 83 0c 00 00 00 	movl   $0x0,0xc(%ebx,%eax,4)
f0106454:	00 
	for (; i < 10; i++)
f0106455:	83 c0 01             	add    $0x1,%eax
f0106458:	83 f8 09             	cmp    $0x9,%eax
f010645b:	7e f0                	jle    f010644d <spin_lock+0x87>
	get_caller_pcs(lk->pcs);
#endif
}
f010645d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0106460:	5b                   	pop    %ebx
f0106461:	5e                   	pop    %esi
f0106462:	5d                   	pop    %ebp
f0106463:	c3                   	ret    

f0106464 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0106464:	f3 0f 1e fb          	endbr32 
f0106468:	55                   	push   %ebp
f0106469:	89 e5                	mov    %esp,%ebp
f010646b:	57                   	push   %edi
f010646c:	56                   	push   %esi
f010646d:	53                   	push   %ebx
f010646e:	83 ec 4c             	sub    $0x4c,%esp
f0106471:	8b 75 08             	mov    0x8(%ebp),%esi
	return lock->locked && lock->cpu == thiscpu;
f0106474:	83 3e 00             	cmpl   $0x0,(%esi)
f0106477:	75 35                	jne    f01064ae <spin_unlock+0x4a>
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0106479:	83 ec 04             	sub    $0x4,%esp
f010647c:	6a 28                	push   $0x28
f010647e:	8d 46 0c             	lea    0xc(%esi),%eax
f0106481:	50                   	push   %eax
f0106482:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0106485:	53                   	push   %ebx
f0106486:	e8 e1 f6 ff ff       	call   f0105b6c <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f010648b:	8b 46 08             	mov    0x8(%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f010648e:	0f b6 38             	movzbl (%eax),%edi
f0106491:	8b 76 04             	mov    0x4(%esi),%esi
f0106494:	e8 a5 fc ff ff       	call   f010613e <cpunum>
f0106499:	57                   	push   %edi
f010649a:	56                   	push   %esi
f010649b:	50                   	push   %eax
f010649c:	68 d0 85 10 f0       	push   $0xf01085d0
f01064a1:	e8 14 d5 ff ff       	call   f01039ba <cprintf>
f01064a6:	83 c4 20             	add    $0x20,%esp
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f01064a9:	8d 7d a8             	lea    -0x58(%ebp),%edi
f01064ac:	eb 4e                	jmp    f01064fc <spin_unlock+0x98>
	return lock->locked && lock->cpu == thiscpu;
f01064ae:	8b 5e 08             	mov    0x8(%esi),%ebx
f01064b1:	e8 88 fc ff ff       	call   f010613e <cpunum>
f01064b6:	6b c0 74             	imul   $0x74,%eax,%eax
f01064b9:	05 20 80 21 f0       	add    $0xf0218020,%eax
	if (!holding(lk)) {
f01064be:	39 c3                	cmp    %eax,%ebx
f01064c0:	75 b7                	jne    f0106479 <spin_unlock+0x15>
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
	}

	lk->pcs[0] = 0;
f01064c2:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f01064c9:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
	asm volatile("lock; xchgl %0, %1"
f01064d0:	b8 00 00 00 00       	mov    $0x0,%eax
f01064d5:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f01064d8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01064db:	5b                   	pop    %ebx
f01064dc:	5e                   	pop    %esi
f01064dd:	5f                   	pop    %edi
f01064de:	5d                   	pop    %ebp
f01064df:	c3                   	ret    
				cprintf("  %08x\n", pcs[i]);
f01064e0:	83 ec 08             	sub    $0x8,%esp
f01064e3:	ff 36                	pushl  (%esi)
f01064e5:	68 2d 86 10 f0       	push   $0xf010862d
f01064ea:	e8 cb d4 ff ff       	call   f01039ba <cprintf>
f01064ef:	83 c4 10             	add    $0x10,%esp
f01064f2:	83 c3 04             	add    $0x4,%ebx
		for (i = 0; i < 10 && pcs[i]; i++) {
f01064f5:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01064f8:	39 c3                	cmp    %eax,%ebx
f01064fa:	74 40                	je     f010653c <spin_unlock+0xd8>
f01064fc:	89 de                	mov    %ebx,%esi
f01064fe:	8b 03                	mov    (%ebx),%eax
f0106500:	85 c0                	test   %eax,%eax
f0106502:	74 38                	je     f010653c <spin_unlock+0xd8>
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0106504:	83 ec 08             	sub    $0x8,%esp
f0106507:	57                   	push   %edi
f0106508:	50                   	push   %eax
f0106509:	e8 cd ea ff ff       	call   f0104fdb <debuginfo_eip>
f010650e:	83 c4 10             	add    $0x10,%esp
f0106511:	85 c0                	test   %eax,%eax
f0106513:	78 cb                	js     f01064e0 <spin_unlock+0x7c>
					pcs[i] - info.eip_fn_addr);
f0106515:	8b 06                	mov    (%esi),%eax
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0106517:	83 ec 04             	sub    $0x4,%esp
f010651a:	89 c2                	mov    %eax,%edx
f010651c:	2b 55 b8             	sub    -0x48(%ebp),%edx
f010651f:	52                   	push   %edx
f0106520:	ff 75 b0             	pushl  -0x50(%ebp)
f0106523:	ff 75 b4             	pushl  -0x4c(%ebp)
f0106526:	ff 75 ac             	pushl  -0x54(%ebp)
f0106529:	ff 75 a8             	pushl  -0x58(%ebp)
f010652c:	50                   	push   %eax
f010652d:	68 16 86 10 f0       	push   $0xf0108616
f0106532:	e8 83 d4 ff ff       	call   f01039ba <cprintf>
f0106537:	83 c4 20             	add    $0x20,%esp
f010653a:	eb b6                	jmp    f01064f2 <spin_unlock+0x8e>
		panic("spin_unlock");
f010653c:	83 ec 04             	sub    $0x4,%esp
f010653f:	68 35 86 10 f0       	push   $0xf0108635
f0106544:	6a 67                	push   $0x67
f0106546:	68 06 86 10 f0       	push   $0xf0108606
f010654b:	e8 f0 9a ff ff       	call   f0100040 <_panic>

f0106550 <__udivdi3>:
f0106550:	f3 0f 1e fb          	endbr32 
f0106554:	55                   	push   %ebp
f0106555:	57                   	push   %edi
f0106556:	56                   	push   %esi
f0106557:	53                   	push   %ebx
f0106558:	83 ec 1c             	sub    $0x1c,%esp
f010655b:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010655f:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0106563:	8b 74 24 34          	mov    0x34(%esp),%esi
f0106567:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f010656b:	85 d2                	test   %edx,%edx
f010656d:	75 19                	jne    f0106588 <__udivdi3+0x38>
f010656f:	39 f3                	cmp    %esi,%ebx
f0106571:	76 4d                	jbe    f01065c0 <__udivdi3+0x70>
f0106573:	31 ff                	xor    %edi,%edi
f0106575:	89 e8                	mov    %ebp,%eax
f0106577:	89 f2                	mov    %esi,%edx
f0106579:	f7 f3                	div    %ebx
f010657b:	89 fa                	mov    %edi,%edx
f010657d:	83 c4 1c             	add    $0x1c,%esp
f0106580:	5b                   	pop    %ebx
f0106581:	5e                   	pop    %esi
f0106582:	5f                   	pop    %edi
f0106583:	5d                   	pop    %ebp
f0106584:	c3                   	ret    
f0106585:	8d 76 00             	lea    0x0(%esi),%esi
f0106588:	39 f2                	cmp    %esi,%edx
f010658a:	76 14                	jbe    f01065a0 <__udivdi3+0x50>
f010658c:	31 ff                	xor    %edi,%edi
f010658e:	31 c0                	xor    %eax,%eax
f0106590:	89 fa                	mov    %edi,%edx
f0106592:	83 c4 1c             	add    $0x1c,%esp
f0106595:	5b                   	pop    %ebx
f0106596:	5e                   	pop    %esi
f0106597:	5f                   	pop    %edi
f0106598:	5d                   	pop    %ebp
f0106599:	c3                   	ret    
f010659a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01065a0:	0f bd fa             	bsr    %edx,%edi
f01065a3:	83 f7 1f             	xor    $0x1f,%edi
f01065a6:	75 48                	jne    f01065f0 <__udivdi3+0xa0>
f01065a8:	39 f2                	cmp    %esi,%edx
f01065aa:	72 06                	jb     f01065b2 <__udivdi3+0x62>
f01065ac:	31 c0                	xor    %eax,%eax
f01065ae:	39 eb                	cmp    %ebp,%ebx
f01065b0:	77 de                	ja     f0106590 <__udivdi3+0x40>
f01065b2:	b8 01 00 00 00       	mov    $0x1,%eax
f01065b7:	eb d7                	jmp    f0106590 <__udivdi3+0x40>
f01065b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01065c0:	89 d9                	mov    %ebx,%ecx
f01065c2:	85 db                	test   %ebx,%ebx
f01065c4:	75 0b                	jne    f01065d1 <__udivdi3+0x81>
f01065c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01065cb:	31 d2                	xor    %edx,%edx
f01065cd:	f7 f3                	div    %ebx
f01065cf:	89 c1                	mov    %eax,%ecx
f01065d1:	31 d2                	xor    %edx,%edx
f01065d3:	89 f0                	mov    %esi,%eax
f01065d5:	f7 f1                	div    %ecx
f01065d7:	89 c6                	mov    %eax,%esi
f01065d9:	89 e8                	mov    %ebp,%eax
f01065db:	89 f7                	mov    %esi,%edi
f01065dd:	f7 f1                	div    %ecx
f01065df:	89 fa                	mov    %edi,%edx
f01065e1:	83 c4 1c             	add    $0x1c,%esp
f01065e4:	5b                   	pop    %ebx
f01065e5:	5e                   	pop    %esi
f01065e6:	5f                   	pop    %edi
f01065e7:	5d                   	pop    %ebp
f01065e8:	c3                   	ret    
f01065e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01065f0:	89 f9                	mov    %edi,%ecx
f01065f2:	b8 20 00 00 00       	mov    $0x20,%eax
f01065f7:	29 f8                	sub    %edi,%eax
f01065f9:	d3 e2                	shl    %cl,%edx
f01065fb:	89 54 24 08          	mov    %edx,0x8(%esp)
f01065ff:	89 c1                	mov    %eax,%ecx
f0106601:	89 da                	mov    %ebx,%edx
f0106603:	d3 ea                	shr    %cl,%edx
f0106605:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0106609:	09 d1                	or     %edx,%ecx
f010660b:	89 f2                	mov    %esi,%edx
f010660d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106611:	89 f9                	mov    %edi,%ecx
f0106613:	d3 e3                	shl    %cl,%ebx
f0106615:	89 c1                	mov    %eax,%ecx
f0106617:	d3 ea                	shr    %cl,%edx
f0106619:	89 f9                	mov    %edi,%ecx
f010661b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010661f:	89 eb                	mov    %ebp,%ebx
f0106621:	d3 e6                	shl    %cl,%esi
f0106623:	89 c1                	mov    %eax,%ecx
f0106625:	d3 eb                	shr    %cl,%ebx
f0106627:	09 de                	or     %ebx,%esi
f0106629:	89 f0                	mov    %esi,%eax
f010662b:	f7 74 24 08          	divl   0x8(%esp)
f010662f:	89 d6                	mov    %edx,%esi
f0106631:	89 c3                	mov    %eax,%ebx
f0106633:	f7 64 24 0c          	mull   0xc(%esp)
f0106637:	39 d6                	cmp    %edx,%esi
f0106639:	72 15                	jb     f0106650 <__udivdi3+0x100>
f010663b:	89 f9                	mov    %edi,%ecx
f010663d:	d3 e5                	shl    %cl,%ebp
f010663f:	39 c5                	cmp    %eax,%ebp
f0106641:	73 04                	jae    f0106647 <__udivdi3+0xf7>
f0106643:	39 d6                	cmp    %edx,%esi
f0106645:	74 09                	je     f0106650 <__udivdi3+0x100>
f0106647:	89 d8                	mov    %ebx,%eax
f0106649:	31 ff                	xor    %edi,%edi
f010664b:	e9 40 ff ff ff       	jmp    f0106590 <__udivdi3+0x40>
f0106650:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0106653:	31 ff                	xor    %edi,%edi
f0106655:	e9 36 ff ff ff       	jmp    f0106590 <__udivdi3+0x40>
f010665a:	66 90                	xchg   %ax,%ax
f010665c:	66 90                	xchg   %ax,%ax
f010665e:	66 90                	xchg   %ax,%ax

f0106660 <__umoddi3>:
f0106660:	f3 0f 1e fb          	endbr32 
f0106664:	55                   	push   %ebp
f0106665:	57                   	push   %edi
f0106666:	56                   	push   %esi
f0106667:	53                   	push   %ebx
f0106668:	83 ec 1c             	sub    $0x1c,%esp
f010666b:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010666f:	8b 74 24 30          	mov    0x30(%esp),%esi
f0106673:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0106677:	8b 7c 24 38          	mov    0x38(%esp),%edi
f010667b:	85 c0                	test   %eax,%eax
f010667d:	75 19                	jne    f0106698 <__umoddi3+0x38>
f010667f:	39 df                	cmp    %ebx,%edi
f0106681:	76 5d                	jbe    f01066e0 <__umoddi3+0x80>
f0106683:	89 f0                	mov    %esi,%eax
f0106685:	89 da                	mov    %ebx,%edx
f0106687:	f7 f7                	div    %edi
f0106689:	89 d0                	mov    %edx,%eax
f010668b:	31 d2                	xor    %edx,%edx
f010668d:	83 c4 1c             	add    $0x1c,%esp
f0106690:	5b                   	pop    %ebx
f0106691:	5e                   	pop    %esi
f0106692:	5f                   	pop    %edi
f0106693:	5d                   	pop    %ebp
f0106694:	c3                   	ret    
f0106695:	8d 76 00             	lea    0x0(%esi),%esi
f0106698:	89 f2                	mov    %esi,%edx
f010669a:	39 d8                	cmp    %ebx,%eax
f010669c:	76 12                	jbe    f01066b0 <__umoddi3+0x50>
f010669e:	89 f0                	mov    %esi,%eax
f01066a0:	89 da                	mov    %ebx,%edx
f01066a2:	83 c4 1c             	add    $0x1c,%esp
f01066a5:	5b                   	pop    %ebx
f01066a6:	5e                   	pop    %esi
f01066a7:	5f                   	pop    %edi
f01066a8:	5d                   	pop    %ebp
f01066a9:	c3                   	ret    
f01066aa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01066b0:	0f bd e8             	bsr    %eax,%ebp
f01066b3:	83 f5 1f             	xor    $0x1f,%ebp
f01066b6:	75 50                	jne    f0106708 <__umoddi3+0xa8>
f01066b8:	39 d8                	cmp    %ebx,%eax
f01066ba:	0f 82 e0 00 00 00    	jb     f01067a0 <__umoddi3+0x140>
f01066c0:	89 d9                	mov    %ebx,%ecx
f01066c2:	39 f7                	cmp    %esi,%edi
f01066c4:	0f 86 d6 00 00 00    	jbe    f01067a0 <__umoddi3+0x140>
f01066ca:	89 d0                	mov    %edx,%eax
f01066cc:	89 ca                	mov    %ecx,%edx
f01066ce:	83 c4 1c             	add    $0x1c,%esp
f01066d1:	5b                   	pop    %ebx
f01066d2:	5e                   	pop    %esi
f01066d3:	5f                   	pop    %edi
f01066d4:	5d                   	pop    %ebp
f01066d5:	c3                   	ret    
f01066d6:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01066dd:	8d 76 00             	lea    0x0(%esi),%esi
f01066e0:	89 fd                	mov    %edi,%ebp
f01066e2:	85 ff                	test   %edi,%edi
f01066e4:	75 0b                	jne    f01066f1 <__umoddi3+0x91>
f01066e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01066eb:	31 d2                	xor    %edx,%edx
f01066ed:	f7 f7                	div    %edi
f01066ef:	89 c5                	mov    %eax,%ebp
f01066f1:	89 d8                	mov    %ebx,%eax
f01066f3:	31 d2                	xor    %edx,%edx
f01066f5:	f7 f5                	div    %ebp
f01066f7:	89 f0                	mov    %esi,%eax
f01066f9:	f7 f5                	div    %ebp
f01066fb:	89 d0                	mov    %edx,%eax
f01066fd:	31 d2                	xor    %edx,%edx
f01066ff:	eb 8c                	jmp    f010668d <__umoddi3+0x2d>
f0106701:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106708:	89 e9                	mov    %ebp,%ecx
f010670a:	ba 20 00 00 00       	mov    $0x20,%edx
f010670f:	29 ea                	sub    %ebp,%edx
f0106711:	d3 e0                	shl    %cl,%eax
f0106713:	89 44 24 08          	mov    %eax,0x8(%esp)
f0106717:	89 d1                	mov    %edx,%ecx
f0106719:	89 f8                	mov    %edi,%eax
f010671b:	d3 e8                	shr    %cl,%eax
f010671d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0106721:	89 54 24 04          	mov    %edx,0x4(%esp)
f0106725:	8b 54 24 04          	mov    0x4(%esp),%edx
f0106729:	09 c1                	or     %eax,%ecx
f010672b:	89 d8                	mov    %ebx,%eax
f010672d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106731:	89 e9                	mov    %ebp,%ecx
f0106733:	d3 e7                	shl    %cl,%edi
f0106735:	89 d1                	mov    %edx,%ecx
f0106737:	d3 e8                	shr    %cl,%eax
f0106739:	89 e9                	mov    %ebp,%ecx
f010673b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010673f:	d3 e3                	shl    %cl,%ebx
f0106741:	89 c7                	mov    %eax,%edi
f0106743:	89 d1                	mov    %edx,%ecx
f0106745:	89 f0                	mov    %esi,%eax
f0106747:	d3 e8                	shr    %cl,%eax
f0106749:	89 e9                	mov    %ebp,%ecx
f010674b:	89 fa                	mov    %edi,%edx
f010674d:	d3 e6                	shl    %cl,%esi
f010674f:	09 d8                	or     %ebx,%eax
f0106751:	f7 74 24 08          	divl   0x8(%esp)
f0106755:	89 d1                	mov    %edx,%ecx
f0106757:	89 f3                	mov    %esi,%ebx
f0106759:	f7 64 24 0c          	mull   0xc(%esp)
f010675d:	89 c6                	mov    %eax,%esi
f010675f:	89 d7                	mov    %edx,%edi
f0106761:	39 d1                	cmp    %edx,%ecx
f0106763:	72 06                	jb     f010676b <__umoddi3+0x10b>
f0106765:	75 10                	jne    f0106777 <__umoddi3+0x117>
f0106767:	39 c3                	cmp    %eax,%ebx
f0106769:	73 0c                	jae    f0106777 <__umoddi3+0x117>
f010676b:	2b 44 24 0c          	sub    0xc(%esp),%eax
f010676f:	1b 54 24 08          	sbb    0x8(%esp),%edx
f0106773:	89 d7                	mov    %edx,%edi
f0106775:	89 c6                	mov    %eax,%esi
f0106777:	89 ca                	mov    %ecx,%edx
f0106779:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010677e:	29 f3                	sub    %esi,%ebx
f0106780:	19 fa                	sbb    %edi,%edx
f0106782:	89 d0                	mov    %edx,%eax
f0106784:	d3 e0                	shl    %cl,%eax
f0106786:	89 e9                	mov    %ebp,%ecx
f0106788:	d3 eb                	shr    %cl,%ebx
f010678a:	d3 ea                	shr    %cl,%edx
f010678c:	09 d8                	or     %ebx,%eax
f010678e:	83 c4 1c             	add    $0x1c,%esp
f0106791:	5b                   	pop    %ebx
f0106792:	5e                   	pop    %esi
f0106793:	5f                   	pop    %edi
f0106794:	5d                   	pop    %ebp
f0106795:	c3                   	ret    
f0106796:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f010679d:	8d 76 00             	lea    0x0(%esi),%esi
f01067a0:	29 fe                	sub    %edi,%esi
f01067a2:	19 c3                	sbb    %eax,%ebx
f01067a4:	89 f2                	mov    %esi,%edx
f01067a6:	89 d9                	mov    %ebx,%ecx
f01067a8:	e9 1d ff ff ff       	jmp    f01066ca <__umoddi3+0x6a>
