
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
f010006f:	e8 da 60 00 00       	call   f010614e <cpunum>
f0100074:	ff 75 0c             	pushl  0xc(%ebp)
f0100077:	ff 75 08             	pushl  0x8(%ebp)
f010007a:	50                   	push   %eax
f010007b:	68 c0 67 10 f0       	push   $0xf01067c0
f0100080:	e8 27 39 00 00       	call   f01039ac <cprintf>
	vcprintf(fmt, ap);
f0100085:	83 c4 08             	add    $0x8,%esp
f0100088:	53                   	push   %ebx
f0100089:	56                   	push   %esi
f010008a:	e8 f3 38 00 00       	call   f0103982 <vcprintf>
	cprintf("\n");
f010008f:	c7 04 24 fd 79 10 f0 	movl   $0xf01079fd,(%esp)
f0100096:	e8 11 39 00 00       	call   f01039ac <cprintf>
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
f01000bd:	e8 ea 38 00 00       	call   f01039ac <cprintf>
	mem_init();
f01000c2:	e8 9b 12 00 00       	call   f0101362 <mem_init>
	env_init();
f01000c7:	e8 e1 30 00 00       	call   f01031ad <env_init>
	trap_init();
f01000cc:	e8 d7 39 00 00       	call   f0103aa8 <trap_init>
	mp_init();
f01000d1:	e8 79 5d 00 00       	call   f0105e4f <mp_init>
	lapic_init();
f01000d6:	e8 8d 60 00 00       	call   f0106168 <lapic_init>
	pic_init();
f01000db:	e8 e1 37 00 00       	call   f01038c1 <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000e0:	c7 04 24 c0 33 12 f0 	movl   $0xf01233c0,(%esp)
f01000e7:	e8 ea 62 00 00       	call   f01063d6 <spin_lock>
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
f01000fb:	b8 b2 5d 10 f0       	mov    $0xf0105db2,%eax
f0100100:	2d 38 5d 10 f0       	sub    $0xf0105d38,%eax
f0100105:	50                   	push   %eax
f0100106:	68 38 5d 10 f0       	push   $0xf0105d38
f010010b:	68 00 70 00 f0       	push   $0xf0007000
f0100110:	e8 66 5a 00 00       	call   f0105b7b <memmove>
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
f010015f:	e8 5e 61 00 00       	call   f01062c2 <lapic_startap>
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
f0100182:	e8 c7 5f 00 00       	call   f010614e <cpunum>
f0100187:	6b c0 74             	imul   $0x74,%eax,%eax
f010018a:	05 20 80 21 f0       	add    $0xf0218020,%eax
f010018f:	39 c3                	cmp    %eax,%ebx
f0100191:	74 dc                	je     f010016f <i386_init+0xcf>
f0100193:	eb a0                	jmp    f0100135 <i386_init+0x95>
	ENV_CREATE(fs_fs, ENV_TYPE_FS);
f0100195:	83 ec 08             	sub    $0x8,%esp
f0100198:	6a 01                	push   $0x1
f010019a:	68 a8 38 1d f0       	push   $0xf01d38a8
f010019f:	e8 d0 31 00 00       	call   f0103374 <env_create>
	ENV_CREATE(TEST, ENV_TYPE_USER);
f01001a4:	83 c4 08             	add    $0x8,%esp
f01001a7:	6a 00                	push   $0x0
f01001a9:	68 54 ea 1c f0       	push   $0xf01cea54
f01001ae:	e8 c1 31 00 00       	call   f0103374 <env_create>
	kbd_intr();
f01001b3:	e8 5a 04 00 00       	call   f0100612 <kbd_intr>
	sched_yield();
f01001b8:	e8 88 46 00 00       	call   f0104845 <sched_yield>

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
f01001db:	e8 6e 5f 00 00       	call   f010614e <cpunum>
f01001e0:	83 ec 08             	sub    $0x8,%esp
f01001e3:	50                   	push   %eax
f01001e4:	68 53 68 10 f0       	push   $0xf0106853
f01001e9:	e8 be 37 00 00       	call   f01039ac <cprintf>
	lapic_init();
f01001ee:	e8 75 5f 00 00       	call   f0106168 <lapic_init>
	env_init_percpu();
f01001f3:	e8 85 2f 00 00       	call   f010317d <env_init_percpu>
	trap_init_percpu();
f01001f8:	e8 c7 37 00 00       	call   f01039c4 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f01001fd:	e8 4c 5f 00 00       	call   f010614e <cpunum>
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
f010021b:	e8 b6 61 00 00       	call   f01063d6 <spin_lock>
	sched_yield();
f0100220:	e8 20 46 00 00       	call   f0104845 <sched_yield>
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
f0100250:	e8 57 37 00 00       	call   f01039ac <cprintf>
	vcprintf(fmt, ap);
f0100255:	83 c4 08             	add    $0x8,%esp
f0100258:	53                   	push   %ebx
f0100259:	ff 75 10             	pushl  0x10(%ebp)
f010025c:	e8 21 37 00 00       	call   f0103982 <vcprintf>
	cprintf("\n");
f0100261:	c7 04 24 fd 79 10 f0 	movl   $0xf01079fd,(%esp)
f0100268:	e8 3f 37 00 00       	call   f01039ac <cprintf>
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
f01003c8:	e8 df 35 00 00       	call   f01039ac <cprintf>
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
f01005bf:	e8 b7 55 00 00       	call   f0105b7b <memmove>
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
f01006f8:	e8 42 31 00 00       	call   f010383f <irq_setmask_8259A>
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
f0100770:	e8 37 32 00 00       	call   f01039ac <cprintf>
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
f01007a5:	e8 95 30 00 00       	call   f010383f <irq_setmask_8259A>
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
f010080a:	e8 9d 31 00 00       	call   f01039ac <cprintf>
f010080f:	83 c4 0c             	add    $0xc,%esp
f0100812:	68 d0 6b 10 f0       	push   $0xf0106bd0
f0100817:	68 0c 6b 10 f0       	push   $0xf0106b0c
f010081c:	68 03 6b 10 f0       	push   $0xf0106b03
f0100821:	e8 86 31 00 00       	call   f01039ac <cprintf>
f0100826:	83 c4 0c             	add    $0xc,%esp
f0100829:	68 15 6b 10 f0       	push   $0xf0106b15
f010082e:	68 2b 6b 10 f0       	push   $0xf0106b2b
f0100833:	68 03 6b 10 f0       	push   $0xf0106b03
f0100838:	e8 6f 31 00 00       	call   f01039ac <cprintf>
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
f0100853:	e8 54 31 00 00       	call   f01039ac <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100858:	83 c4 08             	add    $0x8,%esp
f010085b:	68 0c 00 10 00       	push   $0x10000c
f0100860:	68 f8 6b 10 f0       	push   $0xf0106bf8
f0100865:	e8 42 31 00 00       	call   f01039ac <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010086a:	83 c4 0c             	add    $0xc,%esp
f010086d:	68 0c 00 10 00       	push   $0x10000c
f0100872:	68 0c 00 10 f0       	push   $0xf010000c
f0100877:	68 20 6c 10 f0       	push   $0xf0106c20
f010087c:	e8 2b 31 00 00       	call   f01039ac <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100881:	83 c4 0c             	add    $0xc,%esp
f0100884:	68 bd 67 10 00       	push   $0x1067bd
f0100889:	68 bd 67 10 f0       	push   $0xf01067bd
f010088e:	68 44 6c 10 f0       	push   $0xf0106c44
f0100893:	e8 14 31 00 00       	call   f01039ac <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100898:	83 c4 0c             	add    $0xc,%esp
f010089b:	68 00 70 21 00       	push   $0x217000
f01008a0:	68 00 70 21 f0       	push   $0xf0217000
f01008a5:	68 68 6c 10 f0       	push   $0xf0106c68
f01008aa:	e8 fd 30 00 00       	call   f01039ac <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01008af:	83 c4 0c             	add    $0xc,%esp
f01008b2:	68 09 90 25 00       	push   $0x259009
f01008b7:	68 09 90 25 f0       	push   $0xf0259009
f01008bc:	68 8c 6c 10 f0       	push   $0xf0106c8c
f01008c1:	e8 e6 30 00 00       	call   f01039ac <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008c6:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01008c9:	b8 09 90 25 f0       	mov    $0xf0259009,%eax
f01008ce:	2d 0d fc 0f f0       	sub    $0xf00ffc0d,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008d3:	c1 f8 0a             	sar    $0xa,%eax
f01008d6:	50                   	push   %eax
f01008d7:	68 b0 6c 10 f0       	push   $0xf0106cb0
f01008dc:	e8 cb 30 00 00       	call   f01039ac <cprintf>
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
f0100906:	e8 a1 30 00 00       	call   f01039ac <cprintf>
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
f010092a:	e8 7d 30 00 00       	call   f01039ac <cprintf>
f010092f:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100932:	8d 7e 1c             	lea    0x1c(%esi),%edi
f0100935:	83 c4 10             	add    $0x10,%esp
            cprintf("%08x ", args[i]);
f0100938:	83 ec 08             	sub    $0x8,%esp
f010093b:	ff 33                	pushl  (%ebx)
f010093d:	68 7b 6b 10 f0       	push   $0xf0106b7b
f0100942:	e8 65 30 00 00       	call   f01039ac <cprintf>
f0100947:	83 c3 04             	add    $0x4,%ebx
        for (int i = 0; i < 5; ++i) {
f010094a:	83 c4 10             	add    $0x10,%esp
f010094d:	39 fb                	cmp    %edi,%ebx
f010094f:	75 e7                	jne    f0100938 <mon_backtrace+0x50>
        cprintf("\n");
f0100951:	83 ec 0c             	sub    $0xc,%esp
f0100954:	68 fd 79 10 f0       	push   $0xf01079fd
f0100959:	e8 4e 30 00 00       	call   f01039ac <cprintf>
        if(debuginfo_eip(eip,&info) == 0)
f010095e:	83 c4 08             	add    $0x8,%esp
f0100961:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100964:	50                   	push   %eax
f0100965:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100968:	e8 7d 46 00 00       	call   f0104fea <debuginfo_eip>
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
f010098f:	e8 18 30 00 00       	call   f01039ac <cprintf>
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
f01009bb:	e8 ec 2f 00 00       	call   f01039ac <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009c0:	c7 04 24 00 6d 10 f0 	movl   $0xf0106d00,(%esp)
f01009c7:	e8 e0 2f 00 00       	call   f01039ac <cprintf>

	if (tf != NULL)
f01009cc:	83 c4 10             	add    $0x10,%esp
f01009cf:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01009d3:	0f 84 d9 00 00 00    	je     f0100ab2 <monitor+0x109>
		print_trapframe(tf);
f01009d9:	83 ec 0c             	sub    $0xc,%esp
f01009dc:	ff 75 08             	pushl  0x8(%ebp)
f01009df:	e8 73 37 00 00       	call   f0104157 <print_trapframe>
f01009e4:	83 c4 10             	add    $0x10,%esp
f01009e7:	e9 c6 00 00 00       	jmp    f0100ab2 <monitor+0x109>
		while (*buf && strchr(WHITESPACE, *buf))
f01009ec:	83 ec 08             	sub    $0x8,%esp
f01009ef:	0f be c0             	movsbl %al,%eax
f01009f2:	50                   	push   %eax
f01009f3:	68 97 6b 10 f0       	push   $0xf0106b97
f01009f8:	e8 ed 50 00 00       	call   f0105aea <strchr>
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
f0100a3a:	e8 45 50 00 00       	call   f0105a84 <strcmp>
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
f0100a5d:	e8 4a 2f 00 00       	call   f01039ac <cprintf>
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
f0100a8b:	e8 5a 50 00 00       	call   f0105aea <strchr>
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
f0100aaa:	e8 fd 2e 00 00       	call   f01039ac <cprintf>
			return 0;
f0100aaf:	83 c4 10             	add    $0x10,%esp
	// cprintf("x %d, y %x, z %d\n", x, y, z);
	// unsigned int i = 0x00646c72;
 	// cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100ab2:	83 ec 0c             	sub    $0xc,%esp
f0100ab5:	68 93 6b 10 f0       	push   $0xf0106b93
f0100aba:	e8 d1 4d 00 00       	call   f0105890 <readline>
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
f0100b08:	e8 fc 2c 00 00       	call   f0103809 <mc146818_read>
f0100b0d:	89 c6                	mov    %eax,%esi
f0100b0f:	83 c3 01             	add    $0x1,%ebx
f0100b12:	89 1c 24             	mov    %ebx,(%esp)
f0100b15:	e8 ef 2c 00 00       	call   f0103809 <mc146818_read>
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
f0100c7c:	e8 ae 4e 00 00       	call   f0105b2f <memset>
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
f0100e3b:	e8 6c 2b 00 00       	call   f01039ac <cprintf>
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
	size_t num_used = ((uint32_t)boot_alloc(0)-EXTPHYSMEM-KERNBASE)/PGSIZE;
f0100eed:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ef2:	e8 2f fc ff ff       	call   f0100b26 <boot_alloc>
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100ef7:	8b 0d 44 72 21 f0    	mov    0xf0217244,%ecx
	size_t num_used = ((uint32_t)boot_alloc(0)-EXTPHYSMEM-KERNBASE)/PGSIZE;
f0100efd:	05 00 00 f0 0f       	add    $0xff00000,%eax
f0100f02:	c1 e8 0c             	shr    $0xc,%eax
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100f05:	8d 74 01 60          	lea    0x60(%ecx,%eax,1),%esi
f0100f09:	8b 1d 40 72 21 f0    	mov    0xf0217240,%ebx
	for(size_t i = 0;i<npages;i++)
f0100f0f:	bf 00 00 00 00       	mov    $0x0,%edi
f0100f14:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f19:	eb 4b                	jmp    f0100f66 <page_init+0x86>
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100f1b:	39 c1                	cmp    %eax,%ecx
f0100f1d:	77 1b                	ja     f0100f3a <page_init+0x5a>
f0100f1f:	39 c6                	cmp    %eax,%esi
f0100f21:	76 17                	jbe    f0100f3a <page_init+0x5a>
			pages[i].pp_ref = 1;
f0100f23:	8b 15 90 7e 21 f0    	mov    0xf0217e90,%edx
f0100f29:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100f2c:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
			pages[i].pp_link = NULL;
f0100f32:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
f0100f38:	eb 29                	jmp    f0100f63 <page_init+0x83>
		else if(i == mpentry)
f0100f3a:	83 f8 07             	cmp    $0x7,%eax
f0100f3d:	74 47                	je     f0100f86 <page_init+0xa6>
f0100f3f:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
			pages[i].pp_ref = 0;
f0100f46:	89 d7                	mov    %edx,%edi
f0100f48:	03 3d 90 7e 21 f0    	add    0xf0217e90,%edi
f0100f4e:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
			pages[i].pp_link = page_free_list;
f0100f54:	89 1f                	mov    %ebx,(%edi)
			page_free_list = &pages[i];
f0100f56:	89 d3                	mov    %edx,%ebx
f0100f58:	03 1d 90 7e 21 f0    	add    0xf0217e90,%ebx
f0100f5e:	bf 01 00 00 00       	mov    $0x1,%edi
	for(size_t i = 0;i<npages;i++)
f0100f63:	83 c0 01             	add    $0x1,%eax
f0100f66:	39 05 88 7e 21 f0    	cmp    %eax,0xf0217e88
f0100f6c:	76 2d                	jbe    f0100f9b <page_init+0xbb>
		if(i == 0)
f0100f6e:	85 c0                	test   %eax,%eax
f0100f70:	75 a9                	jne    f0100f1b <page_init+0x3b>
			pages[i].pp_ref = 1;
f0100f72:	8b 15 90 7e 21 f0    	mov    0xf0217e90,%edx
f0100f78:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
			pages[i].pp_link = NULL;
f0100f7e:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
f0100f84:	eb dd                	jmp    f0100f63 <page_init+0x83>
			pages[i].pp_ref = 1;
f0100f86:	8b 15 90 7e 21 f0    	mov    0xf0217e90,%edx
f0100f8c:	66 c7 42 3c 01 00    	movw   $0x1,0x3c(%edx)
			pages[i].pp_link = NULL;
f0100f92:	c7 42 38 00 00 00 00 	movl   $0x0,0x38(%edx)
f0100f99:	eb c8                	jmp    f0100f63 <page_init+0x83>
f0100f9b:	89 f8                	mov    %edi,%eax
f0100f9d:	84 c0                	test   %al,%al
f0100f9f:	74 06                	je     f0100fa7 <page_init+0xc7>
f0100fa1:	89 1d 40 72 21 f0    	mov    %ebx,0xf0217240
}
f0100fa7:	83 c4 0c             	add    $0xc,%esp
f0100faa:	5b                   	pop    %ebx
f0100fab:	5e                   	pop    %esi
f0100fac:	5f                   	pop    %edi
f0100fad:	5d                   	pop    %ebp
f0100fae:	c3                   	ret    

f0100faf <page_alloc>:
{
f0100faf:	f3 0f 1e fb          	endbr32 
f0100fb3:	55                   	push   %ebp
f0100fb4:	89 e5                	mov    %esp,%ebp
f0100fb6:	53                   	push   %ebx
f0100fb7:	83 ec 04             	sub    $0x4,%esp
	if(page_free_list == NULL)
f0100fba:	8b 1d 40 72 21 f0    	mov    0xf0217240,%ebx
f0100fc0:	85 db                	test   %ebx,%ebx
f0100fc2:	74 30                	je     f0100ff4 <page_alloc+0x45>
	page_free_list = page_free_list->pp_link;
f0100fc4:	8b 03                	mov    (%ebx),%eax
f0100fc6:	a3 40 72 21 f0       	mov    %eax,0xf0217240
	alloc->pp_link = NULL;
f0100fcb:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
f0100fd1:	89 d8                	mov    %ebx,%eax
f0100fd3:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0100fd9:	c1 f8 03             	sar    $0x3,%eax
f0100fdc:	89 c2                	mov    %eax,%edx
f0100fde:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0100fe1:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0100fe6:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0100fec:	73 0d                	jae    f0100ffb <page_alloc+0x4c>
	if(alloc_flags & ALLOC_ZERO)
f0100fee:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ff2:	75 19                	jne    f010100d <page_alloc+0x5e>
}
f0100ff4:	89 d8                	mov    %ebx,%eax
f0100ff6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ff9:	c9                   	leave  
f0100ffa:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ffb:	52                   	push   %edx
f0100ffc:	68 e4 67 10 f0       	push   $0xf01067e4
f0101001:	6a 58                	push   $0x58
f0101003:	68 29 77 10 f0       	push   $0xf0107729
f0101008:	e8 33 f0 ff ff       	call   f0100040 <_panic>
		memset(head,0,PGSIZE);
f010100d:	83 ec 04             	sub    $0x4,%esp
f0101010:	68 00 10 00 00       	push   $0x1000
f0101015:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0101017:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f010101d:	52                   	push   %edx
f010101e:	e8 0c 4b 00 00       	call   f0105b2f <memset>
f0101023:	83 c4 10             	add    $0x10,%esp
f0101026:	eb cc                	jmp    f0100ff4 <page_alloc+0x45>

f0101028 <page_free>:
{
f0101028:	f3 0f 1e fb          	endbr32 
f010102c:	55                   	push   %ebp
f010102d:	89 e5                	mov    %esp,%ebp
f010102f:	83 ec 08             	sub    $0x8,%esp
f0101032:	8b 45 08             	mov    0x8(%ebp),%eax
	if((pp->pp_ref != 0) | (pp->pp_link != NULL))  // referenced or freed
f0101035:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010103a:	75 14                	jne    f0101050 <page_free+0x28>
f010103c:	83 38 00             	cmpl   $0x0,(%eax)
f010103f:	75 0f                	jne    f0101050 <page_free+0x28>
	pp->pp_link = page_free_list;
f0101041:	8b 15 40 72 21 f0    	mov    0xf0217240,%edx
f0101047:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101049:	a3 40 72 21 f0       	mov    %eax,0xf0217240
}
f010104e:	c9                   	leave  
f010104f:	c3                   	ret    
		panic("at pmap.c:page_free(): Page double free or freeing a referenced page");
f0101050:	83 ec 04             	sub    $0x4,%esp
f0101053:	68 74 6e 10 f0       	push   $0xf0106e74
f0101058:	68 b0 01 00 00       	push   $0x1b0
f010105d:	68 1d 77 10 f0       	push   $0xf010771d
f0101062:	e8 d9 ef ff ff       	call   f0100040 <_panic>

f0101067 <page_decref>:
{
f0101067:	f3 0f 1e fb          	endbr32 
f010106b:	55                   	push   %ebp
f010106c:	89 e5                	mov    %esp,%ebp
f010106e:	83 ec 08             	sub    $0x8,%esp
f0101071:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101074:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101078:	83 e8 01             	sub    $0x1,%eax
f010107b:	66 89 42 04          	mov    %ax,0x4(%edx)
f010107f:	66 85 c0             	test   %ax,%ax
f0101082:	74 02                	je     f0101086 <page_decref+0x1f>
}
f0101084:	c9                   	leave  
f0101085:	c3                   	ret    
		page_free(pp);
f0101086:	83 ec 0c             	sub    $0xc,%esp
f0101089:	52                   	push   %edx
f010108a:	e8 99 ff ff ff       	call   f0101028 <page_free>
f010108f:	83 c4 10             	add    $0x10,%esp
}
f0101092:	eb f0                	jmp    f0101084 <page_decref+0x1d>

f0101094 <pgdir_walk>:
{
f0101094:	f3 0f 1e fb          	endbr32 
f0101098:	55                   	push   %ebp
f0101099:	89 e5                	mov    %esp,%ebp
f010109b:	56                   	push   %esi
f010109c:	53                   	push   %ebx
f010109d:	8b 75 0c             	mov    0xc(%ebp),%esi
	unsigned int dir_offset = PDX(va);
f01010a0:	89 f3                	mov    %esi,%ebx
f01010a2:	c1 eb 16             	shr    $0x16,%ebx
	pde_t* entry = pgdir+dir_offset;
f01010a5:	c1 e3 02             	shl    $0x2,%ebx
f01010a8:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*entry & PTE_P))
f01010ab:	f6 03 01             	testb  $0x1,(%ebx)
f01010ae:	75 2d                	jne    f01010dd <pgdir_walk+0x49>
		if(create)
f01010b0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01010b4:	74 68                	je     f010111e <pgdir_walk+0x8a>
			new_page = page_alloc(1);
f01010b6:	83 ec 0c             	sub    $0xc,%esp
f01010b9:	6a 01                	push   $0x1
f01010bb:	e8 ef fe ff ff       	call   f0100faf <page_alloc>
			if(new_page == NULL)
f01010c0:	83 c4 10             	add    $0x10,%esp
f01010c3:	85 c0                	test   %eax,%eax
f01010c5:	74 3b                	je     f0101102 <pgdir_walk+0x6e>
			new_page->pp_ref++;
f01010c7:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f01010cc:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f01010d2:	c1 f8 03             	sar    $0x3,%eax
f01010d5:	c1 e0 0c             	shl    $0xc,%eax
			*entry = ((page2pa(new_page))|PTE_P|PTE_W|PTE_U);
f01010d8:	83 c8 07             	or     $0x7,%eax
f01010db:	89 03                	mov    %eax,(%ebx)
	page_base = (pte_t*)KADDR(PTE_ADDR(*entry));
f01010dd:	8b 03                	mov    (%ebx),%eax
f01010df:	89 c2                	mov    %eax,%edx
f01010e1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f01010e7:	c1 e8 0c             	shr    $0xc,%eax
f01010ea:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f01010f0:	73 17                	jae    f0101109 <pgdir_walk+0x75>
	page_offset = PTX(va);
f01010f2:	c1 ee 0a             	shr    $0xa,%esi
	return &page_base[page_offset];
f01010f5:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01010fb:	8d 84 32 00 00 00 f0 	lea    -0x10000000(%edx,%esi,1),%eax
}
f0101102:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101105:	5b                   	pop    %ebx
f0101106:	5e                   	pop    %esi
f0101107:	5d                   	pop    %ebp
f0101108:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101109:	52                   	push   %edx
f010110a:	68 e4 67 10 f0       	push   $0xf01067e4
f010110f:	68 fd 01 00 00       	push   $0x1fd
f0101114:	68 1d 77 10 f0       	push   $0xf010771d
f0101119:	e8 22 ef ff ff       	call   f0100040 <_panic>
			return NULL;
f010111e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101123:	eb dd                	jmp    f0101102 <pgdir_walk+0x6e>

f0101125 <boot_map_region>:
{
f0101125:	55                   	push   %ebp
f0101126:	89 e5                	mov    %esp,%ebp
f0101128:	57                   	push   %edi
f0101129:	56                   	push   %esi
f010112a:	53                   	push   %ebx
f010112b:	83 ec 1c             	sub    $0x1c,%esp
f010112e:	89 c7                	mov    %eax,%edi
f0101130:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101133:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for(add = 0;add<size;add+=PGSIZE)
f0101136:	be 00 00 00 00       	mov    $0x0,%esi
f010113b:	89 f3                	mov    %esi,%ebx
f010113d:	03 5d 08             	add    0x8(%ebp),%ebx
f0101140:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f0101143:	76 24                	jbe    f0101169 <boot_map_region+0x44>
		entry = pgdir_walk(pgdir,(void*)va,1);  // get the entry of page table
f0101145:	83 ec 04             	sub    $0x4,%esp
f0101148:	6a 01                	push   $0x1
f010114a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010114d:	01 f0                	add    %esi,%eax
f010114f:	50                   	push   %eax
f0101150:	57                   	push   %edi
f0101151:	e8 3e ff ff ff       	call   f0101094 <pgdir_walk>
		*entry = (pa|perm|PTE_P);
f0101156:	0b 5d 0c             	or     0xc(%ebp),%ebx
f0101159:	83 cb 01             	or     $0x1,%ebx
f010115c:	89 18                	mov    %ebx,(%eax)
	for(add = 0;add<size;add+=PGSIZE)
f010115e:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0101164:	83 c4 10             	add    $0x10,%esp
f0101167:	eb d2                	jmp    f010113b <boot_map_region+0x16>
}
f0101169:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010116c:	5b                   	pop    %ebx
f010116d:	5e                   	pop    %esi
f010116e:	5f                   	pop    %edi
f010116f:	5d                   	pop    %ebp
f0101170:	c3                   	ret    

f0101171 <page_lookup>:
{
f0101171:	f3 0f 1e fb          	endbr32 
f0101175:	55                   	push   %ebp
f0101176:	89 e5                	mov    %esp,%ebp
f0101178:	53                   	push   %ebx
f0101179:	83 ec 08             	sub    $0x8,%esp
f010117c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	entry = pgdir_walk(pgdir,va,0);
f010117f:	6a 00                	push   $0x0
f0101181:	ff 75 0c             	pushl  0xc(%ebp)
f0101184:	ff 75 08             	pushl  0x8(%ebp)
f0101187:	e8 08 ff ff ff       	call   f0101094 <pgdir_walk>
	if(entry == NULL)
f010118c:	83 c4 10             	add    $0x10,%esp
f010118f:	85 c0                	test   %eax,%eax
f0101191:	74 3c                	je     f01011cf <page_lookup+0x5e>
	if(!(*entry & PTE_P))
f0101193:	8b 10                	mov    (%eax),%edx
f0101195:	f6 c2 01             	test   $0x1,%dl
f0101198:	74 39                	je     f01011d3 <page_lookup+0x62>
f010119a:	c1 ea 0c             	shr    $0xc,%edx
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010119d:	39 15 88 7e 21 f0    	cmp    %edx,0xf0217e88
f01011a3:	76 16                	jbe    f01011bb <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f01011a5:	8b 0d 90 7e 21 f0    	mov    0xf0217e90,%ecx
f01011ab:	8d 14 d1             	lea    (%ecx,%edx,8),%edx
	if(pte_store != NULL)
f01011ae:	85 db                	test   %ebx,%ebx
f01011b0:	74 02                	je     f01011b4 <page_lookup+0x43>
		*pte_store = entry;
f01011b2:	89 03                	mov    %eax,(%ebx)
}
f01011b4:	89 d0                	mov    %edx,%eax
f01011b6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01011b9:	c9                   	leave  
f01011ba:	c3                   	ret    
		panic("pa2page called with invalid pa");
f01011bb:	83 ec 04             	sub    $0x4,%esp
f01011be:	68 bc 6e 10 f0       	push   $0xf0106ebc
f01011c3:	6a 51                	push   $0x51
f01011c5:	68 29 77 10 f0       	push   $0xf0107729
f01011ca:	e8 71 ee ff ff       	call   f0100040 <_panic>
		return NULL;
f01011cf:	89 c2                	mov    %eax,%edx
f01011d1:	eb e1                	jmp    f01011b4 <page_lookup+0x43>
		return NULL;
f01011d3:	ba 00 00 00 00       	mov    $0x0,%edx
f01011d8:	eb da                	jmp    f01011b4 <page_lookup+0x43>

f01011da <tlb_invalidate>:
{
f01011da:	f3 0f 1e fb          	endbr32 
f01011de:	55                   	push   %ebp
f01011df:	89 e5                	mov    %esp,%ebp
f01011e1:	83 ec 08             	sub    $0x8,%esp
	if (!curenv || curenv->env_pgdir == pgdir)
f01011e4:	e8 65 4f 00 00       	call   f010614e <cpunum>
f01011e9:	6b c0 74             	imul   $0x74,%eax,%eax
f01011ec:	83 b8 28 80 21 f0 00 	cmpl   $0x0,-0xfde7fd8(%eax)
f01011f3:	74 16                	je     f010120b <tlb_invalidate+0x31>
f01011f5:	e8 54 4f 00 00       	call   f010614e <cpunum>
f01011fa:	6b c0 74             	imul   $0x74,%eax,%eax
f01011fd:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0101203:	8b 55 08             	mov    0x8(%ebp),%edx
f0101206:	39 50 60             	cmp    %edx,0x60(%eax)
f0101209:	75 06                	jne    f0101211 <tlb_invalidate+0x37>
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010120b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010120e:	0f 01 38             	invlpg (%eax)
}
f0101211:	c9                   	leave  
f0101212:	c3                   	ret    

f0101213 <page_remove>:
{
f0101213:	f3 0f 1e fb          	endbr32 
f0101217:	55                   	push   %ebp
f0101218:	89 e5                	mov    %esp,%ebp
f010121a:	56                   	push   %esi
f010121b:	53                   	push   %ebx
f010121c:	83 ec 14             	sub    $0x14,%esp
f010121f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101222:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t* pte = NULL;
f0101225:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo* page = page_lookup(pgdir,va,&pte);
f010122c:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010122f:	50                   	push   %eax
f0101230:	56                   	push   %esi
f0101231:	53                   	push   %ebx
f0101232:	e8 3a ff ff ff       	call   f0101171 <page_lookup>
	if(page == NULL)
f0101237:	83 c4 10             	add    $0x10,%esp
f010123a:	85 c0                	test   %eax,%eax
f010123c:	74 1f                	je     f010125d <page_remove+0x4a>
	page_decref(page);
f010123e:	83 ec 0c             	sub    $0xc,%esp
f0101241:	50                   	push   %eax
f0101242:	e8 20 fe ff ff       	call   f0101067 <page_decref>
	tlb_invalidate(pgdir,va);
f0101247:	83 c4 08             	add    $0x8,%esp
f010124a:	56                   	push   %esi
f010124b:	53                   	push   %ebx
f010124c:	e8 89 ff ff ff       	call   f01011da <tlb_invalidate>
	*pte = 0;
f0101251:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101254:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f010125a:	83 c4 10             	add    $0x10,%esp
}
f010125d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101260:	5b                   	pop    %ebx
f0101261:	5e                   	pop    %esi
f0101262:	5d                   	pop    %ebp
f0101263:	c3                   	ret    

f0101264 <page_insert>:
{
f0101264:	f3 0f 1e fb          	endbr32 
f0101268:	55                   	push   %ebp
f0101269:	89 e5                	mov    %esp,%ebp
f010126b:	57                   	push   %edi
f010126c:	56                   	push   %esi
f010126d:	53                   	push   %ebx
f010126e:	83 ec 10             	sub    $0x10,%esp
f0101271:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101274:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	entry = pgdir_walk(pgdir,va,1); // get the page table entry 
f0101277:	6a 01                	push   $0x1
f0101279:	ff 75 10             	pushl  0x10(%ebp)
f010127c:	57                   	push   %edi
f010127d:	e8 12 fe ff ff       	call   f0101094 <pgdir_walk>
	if(entry == NULL)
f0101282:	83 c4 10             	add    $0x10,%esp
f0101285:	85 c0                	test   %eax,%eax
f0101287:	74 56                	je     f01012df <page_insert+0x7b>
f0101289:	89 c6                	mov    %eax,%esi
	pp->pp_ref++;
f010128b:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if(*entry&PTE_P)
f0101290:	f6 00 01             	testb  $0x1,(%eax)
f0101293:	75 2d                	jne    f01012c2 <page_insert+0x5e>
	return (pp - pages) << PGSHIFT;
f0101295:	2b 1d 90 7e 21 f0    	sub    0xf0217e90,%ebx
f010129b:	c1 fb 03             	sar    $0x3,%ebx
f010129e:	c1 e3 0c             	shl    $0xc,%ebx
	*entry = ((page2pa(pp))|perm|PTE_P);
f01012a1:	0b 5d 14             	or     0x14(%ebp),%ebx
f01012a4:	83 cb 01             	or     $0x1,%ebx
f01012a7:	89 1e                	mov    %ebx,(%esi)
	pgdir[PDX(va)] |= perm;
f01012a9:	8b 45 10             	mov    0x10(%ebp),%eax
f01012ac:	c1 e8 16             	shr    $0x16,%eax
f01012af:	8b 55 14             	mov    0x14(%ebp),%edx
f01012b2:	09 14 87             	or     %edx,(%edi,%eax,4)
	return 0;
f01012b5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01012ba:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012bd:	5b                   	pop    %ebx
f01012be:	5e                   	pop    %esi
f01012bf:	5f                   	pop    %edi
f01012c0:	5d                   	pop    %ebp
f01012c1:	c3                   	ret    
		tlb_invalidate(pgdir,va);
f01012c2:	83 ec 08             	sub    $0x8,%esp
f01012c5:	ff 75 10             	pushl  0x10(%ebp)
f01012c8:	57                   	push   %edi
f01012c9:	e8 0c ff ff ff       	call   f01011da <tlb_invalidate>
		page_remove(pgdir,va);
f01012ce:	83 c4 08             	add    $0x8,%esp
f01012d1:	ff 75 10             	pushl  0x10(%ebp)
f01012d4:	57                   	push   %edi
f01012d5:	e8 39 ff ff ff       	call   f0101213 <page_remove>
f01012da:	83 c4 10             	add    $0x10,%esp
f01012dd:	eb b6                	jmp    f0101295 <page_insert+0x31>
		return -E_NO_MEM;
f01012df:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01012e4:	eb d4                	jmp    f01012ba <page_insert+0x56>

f01012e6 <mmio_map_region>:
{
f01012e6:	f3 0f 1e fb          	endbr32 
f01012ea:	55                   	push   %ebp
f01012eb:	89 e5                	mov    %esp,%ebp
f01012ed:	57                   	push   %edi
f01012ee:	56                   	push   %esi
f01012ef:	53                   	push   %ebx
f01012f0:	83 ec 0c             	sub    $0xc,%esp
f01012f3:	8b 5d 08             	mov    0x8(%ebp),%ebx
	size = ROUNDUP(pa+size,PGSIZE);
f01012f6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012f9:	8d bc 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%edi
f0101300:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	pa = ROUNDDOWN(pa,PGSIZE);
f0101306:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	size-=pa;
f010130c:	89 fe                	mov    %edi,%esi
f010130e:	29 de                	sub    %ebx,%esi
	if(size+base>=MMIOLIM)
f0101310:	8b 15 00 33 12 f0    	mov    0xf0123300,%edx
f0101316:	8d 04 32             	lea    (%edx,%esi,1),%eax
f0101319:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f010131e:	77 2b                	ja     f010134b <mmio_map_region+0x65>
	boot_map_region(kern_pgdir,base,size,pa,PTE_W|PTE_PCD|PTE_PWT);
f0101320:	83 ec 08             	sub    $0x8,%esp
f0101323:	6a 1a                	push   $0x1a
f0101325:	53                   	push   %ebx
f0101326:	89 f1                	mov    %esi,%ecx
f0101328:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f010132d:	e8 f3 fd ff ff       	call   f0101125 <boot_map_region>
	base+=size;
f0101332:	89 f0                	mov    %esi,%eax
f0101334:	03 05 00 33 12 f0    	add    0xf0123300,%eax
f010133a:	a3 00 33 12 f0       	mov    %eax,0xf0123300
	return (void*)(base-size);
f010133f:	29 fb                	sub    %edi,%ebx
f0101341:	01 d8                	add    %ebx,%eax
}
f0101343:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101346:	5b                   	pop    %ebx
f0101347:	5e                   	pop    %esi
f0101348:	5f                   	pop    %edi
f0101349:	5d                   	pop    %ebp
f010134a:	c3                   	ret    
		panic("At mmio_map_region(): overflow MMIOLIM");
f010134b:	83 ec 04             	sub    $0x4,%esp
f010134e:	68 dc 6e 10 f0       	push   $0xf0106edc
f0101353:	68 d1 02 00 00       	push   $0x2d1
f0101358:	68 1d 77 10 f0       	push   $0xf010771d
f010135d:	e8 de ec ff ff       	call   f0100040 <_panic>

f0101362 <mem_init>:
{
f0101362:	f3 0f 1e fb          	endbr32 
f0101366:	55                   	push   %ebp
f0101367:	89 e5                	mov    %esp,%ebp
f0101369:	57                   	push   %edi
f010136a:	56                   	push   %esi
f010136b:	53                   	push   %ebx
f010136c:	83 ec 3c             	sub    $0x3c,%esp
	basemem = nvram_read(NVRAM_BASELO);
f010136f:	b8 15 00 00 00       	mov    $0x15,%eax
f0101374:	e8 84 f7 ff ff       	call   f0100afd <nvram_read>
f0101379:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f010137b:	b8 17 00 00 00       	mov    $0x17,%eax
f0101380:	e8 78 f7 ff ff       	call   f0100afd <nvram_read>
f0101385:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101387:	b8 34 00 00 00       	mov    $0x34,%eax
f010138c:	e8 6c f7 ff ff       	call   f0100afd <nvram_read>
	if (ext16mem)
f0101391:	c1 e0 06             	shl    $0x6,%eax
f0101394:	0f 84 ea 00 00 00    	je     f0101484 <mem_init+0x122>
		totalmem = 16 * 1024 + ext16mem;
f010139a:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f010139f:	89 c2                	mov    %eax,%edx
f01013a1:	c1 ea 02             	shr    $0x2,%edx
f01013a4:	89 15 88 7e 21 f0    	mov    %edx,0xf0217e88
	npages_basemem = basemem / (PGSIZE / 1024);
f01013aa:	89 da                	mov    %ebx,%edx
f01013ac:	c1 ea 02             	shr    $0x2,%edx
f01013af:	89 15 44 72 21 f0    	mov    %edx,0xf0217244
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013b5:	89 c2                	mov    %eax,%edx
f01013b7:	29 da                	sub    %ebx,%edx
f01013b9:	52                   	push   %edx
f01013ba:	53                   	push   %ebx
f01013bb:	50                   	push   %eax
f01013bc:	68 04 6f 10 f0       	push   $0xf0106f04
f01013c1:	e8 e6 25 00 00       	call   f01039ac <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01013c6:	b8 00 10 00 00       	mov    $0x1000,%eax
f01013cb:	e8 56 f7 ff ff       	call   f0100b26 <boot_alloc>
f01013d0:	a3 8c 7e 21 f0       	mov    %eax,0xf0217e8c
	memset(kern_pgdir, 0, PGSIZE);
f01013d5:	83 c4 0c             	add    $0xc,%esp
f01013d8:	68 00 10 00 00       	push   $0x1000
f01013dd:	6a 00                	push   $0x0
f01013df:	50                   	push   %eax
f01013e0:	e8 4a 47 00 00       	call   f0105b2f <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01013e5:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01013ea:	83 c4 10             	add    $0x10,%esp
f01013ed:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013f2:	0f 86 9c 00 00 00    	jbe    f0101494 <mem_init+0x132>
	return (physaddr_t)kva - KERNBASE;
f01013f8:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01013fe:	83 ca 05             	or     $0x5,%edx
f0101401:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages*sizeof(struct PageInfo));
f0101407:	a1 88 7e 21 f0       	mov    0xf0217e88,%eax
f010140c:	c1 e0 03             	shl    $0x3,%eax
f010140f:	e8 12 f7 ff ff       	call   f0100b26 <boot_alloc>
f0101414:	a3 90 7e 21 f0       	mov    %eax,0xf0217e90
	memset(pages,0,npages*sizeof(struct PageInfo));
f0101419:	83 ec 04             	sub    $0x4,%esp
f010141c:	8b 0d 88 7e 21 f0    	mov    0xf0217e88,%ecx
f0101422:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101429:	52                   	push   %edx
f010142a:	6a 00                	push   $0x0
f010142c:	50                   	push   %eax
f010142d:	e8 fd 46 00 00       	call   f0105b2f <memset>
	envs = (struct Env*)boot_alloc(NENV*sizeof(struct Env));
f0101432:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101437:	e8 ea f6 ff ff       	call   f0100b26 <boot_alloc>
f010143c:	a3 48 72 21 f0       	mov    %eax,0xf0217248
	memset(envs,0,NENV*sizeof(struct Env));
f0101441:	83 c4 0c             	add    $0xc,%esp
f0101444:	68 00 f0 01 00       	push   $0x1f000
f0101449:	6a 00                	push   $0x0
f010144b:	50                   	push   %eax
f010144c:	e8 de 46 00 00       	call   f0105b2f <memset>
	page_init();
f0101451:	e8 8a fa ff ff       	call   f0100ee0 <page_init>
	check_page_free_list(1);
f0101456:	b8 01 00 00 00       	mov    $0x1,%eax
f010145b:	e8 92 f7 ff ff       	call   f0100bf2 <check_page_free_list>
	if (!pages)
f0101460:	83 c4 10             	add    $0x10,%esp
f0101463:	83 3d 90 7e 21 f0 00 	cmpl   $0x0,0xf0217e90
f010146a:	74 3d                	je     f01014a9 <mem_init+0x147>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010146c:	a1 40 72 21 f0       	mov    0xf0217240,%eax
f0101471:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0101478:	85 c0                	test   %eax,%eax
f010147a:	74 44                	je     f01014c0 <mem_init+0x15e>
		++nfree;
f010147c:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101480:	8b 00                	mov    (%eax),%eax
f0101482:	eb f4                	jmp    f0101478 <mem_init+0x116>
		totalmem = 1 * 1024 + extmem;
f0101484:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f010148a:	85 f6                	test   %esi,%esi
f010148c:	0f 44 c3             	cmove  %ebx,%eax
f010148f:	e9 0b ff ff ff       	jmp    f010139f <mem_init+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101494:	50                   	push   %eax
f0101495:	68 08 68 10 f0       	push   $0xf0106808
f010149a:	68 a6 00 00 00       	push   $0xa6
f010149f:	68 1d 77 10 f0       	push   $0xf010771d
f01014a4:	e8 97 eb ff ff       	call   f0100040 <_panic>
		panic("'pages' is a null pointer!");
f01014a9:	83 ec 04             	sub    $0x4,%esp
f01014ac:	68 f0 77 10 f0       	push   $0xf01077f0
f01014b1:	68 79 03 00 00       	push   $0x379
f01014b6:	68 1d 77 10 f0       	push   $0xf010771d
f01014bb:	e8 80 eb ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f01014c0:	83 ec 0c             	sub    $0xc,%esp
f01014c3:	6a 00                	push   $0x0
f01014c5:	e8 e5 fa ff ff       	call   f0100faf <page_alloc>
f01014ca:	89 c3                	mov    %eax,%ebx
f01014cc:	83 c4 10             	add    $0x10,%esp
f01014cf:	85 c0                	test   %eax,%eax
f01014d1:	0f 84 11 02 00 00    	je     f01016e8 <mem_init+0x386>
	assert((pp1 = page_alloc(0)));
f01014d7:	83 ec 0c             	sub    $0xc,%esp
f01014da:	6a 00                	push   $0x0
f01014dc:	e8 ce fa ff ff       	call   f0100faf <page_alloc>
f01014e1:	89 c6                	mov    %eax,%esi
f01014e3:	83 c4 10             	add    $0x10,%esp
f01014e6:	85 c0                	test   %eax,%eax
f01014e8:	0f 84 13 02 00 00    	je     f0101701 <mem_init+0x39f>
	assert((pp2 = page_alloc(0)));
f01014ee:	83 ec 0c             	sub    $0xc,%esp
f01014f1:	6a 00                	push   $0x0
f01014f3:	e8 b7 fa ff ff       	call   f0100faf <page_alloc>
f01014f8:	89 c7                	mov    %eax,%edi
f01014fa:	83 c4 10             	add    $0x10,%esp
f01014fd:	85 c0                	test   %eax,%eax
f01014ff:	0f 84 15 02 00 00    	je     f010171a <mem_init+0x3b8>
	assert(pp1 && pp1 != pp0);
f0101505:	39 f3                	cmp    %esi,%ebx
f0101507:	0f 84 26 02 00 00    	je     f0101733 <mem_init+0x3d1>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010150d:	39 c6                	cmp    %eax,%esi
f010150f:	0f 84 37 02 00 00    	je     f010174c <mem_init+0x3ea>
f0101515:	39 c3                	cmp    %eax,%ebx
f0101517:	0f 84 2f 02 00 00    	je     f010174c <mem_init+0x3ea>
	return (pp - pages) << PGSHIFT;
f010151d:	8b 0d 90 7e 21 f0    	mov    0xf0217e90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101523:	8b 15 88 7e 21 f0    	mov    0xf0217e88,%edx
f0101529:	c1 e2 0c             	shl    $0xc,%edx
f010152c:	89 d8                	mov    %ebx,%eax
f010152e:	29 c8                	sub    %ecx,%eax
f0101530:	c1 f8 03             	sar    $0x3,%eax
f0101533:	c1 e0 0c             	shl    $0xc,%eax
f0101536:	39 d0                	cmp    %edx,%eax
f0101538:	0f 83 27 02 00 00    	jae    f0101765 <mem_init+0x403>
f010153e:	89 f0                	mov    %esi,%eax
f0101540:	29 c8                	sub    %ecx,%eax
f0101542:	c1 f8 03             	sar    $0x3,%eax
f0101545:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101548:	39 c2                	cmp    %eax,%edx
f010154a:	0f 86 2e 02 00 00    	jbe    f010177e <mem_init+0x41c>
f0101550:	89 f8                	mov    %edi,%eax
f0101552:	29 c8                	sub    %ecx,%eax
f0101554:	c1 f8 03             	sar    $0x3,%eax
f0101557:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010155a:	39 c2                	cmp    %eax,%edx
f010155c:	0f 86 35 02 00 00    	jbe    f0101797 <mem_init+0x435>
	fl = page_free_list;
f0101562:	a1 40 72 21 f0       	mov    0xf0217240,%eax
f0101567:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010156a:	c7 05 40 72 21 f0 00 	movl   $0x0,0xf0217240
f0101571:	00 00 00 
	assert(!page_alloc(0));
f0101574:	83 ec 0c             	sub    $0xc,%esp
f0101577:	6a 00                	push   $0x0
f0101579:	e8 31 fa ff ff       	call   f0100faf <page_alloc>
f010157e:	83 c4 10             	add    $0x10,%esp
f0101581:	85 c0                	test   %eax,%eax
f0101583:	0f 85 27 02 00 00    	jne    f01017b0 <mem_init+0x44e>
	page_free(pp0);
f0101589:	83 ec 0c             	sub    $0xc,%esp
f010158c:	53                   	push   %ebx
f010158d:	e8 96 fa ff ff       	call   f0101028 <page_free>
	page_free(pp1);
f0101592:	89 34 24             	mov    %esi,(%esp)
f0101595:	e8 8e fa ff ff       	call   f0101028 <page_free>
	page_free(pp2);
f010159a:	89 3c 24             	mov    %edi,(%esp)
f010159d:	e8 86 fa ff ff       	call   f0101028 <page_free>
	assert((pp0 = page_alloc(0)));
f01015a2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015a9:	e8 01 fa ff ff       	call   f0100faf <page_alloc>
f01015ae:	89 c3                	mov    %eax,%ebx
f01015b0:	83 c4 10             	add    $0x10,%esp
f01015b3:	85 c0                	test   %eax,%eax
f01015b5:	0f 84 0e 02 00 00    	je     f01017c9 <mem_init+0x467>
	assert((pp1 = page_alloc(0)));
f01015bb:	83 ec 0c             	sub    $0xc,%esp
f01015be:	6a 00                	push   $0x0
f01015c0:	e8 ea f9 ff ff       	call   f0100faf <page_alloc>
f01015c5:	89 c6                	mov    %eax,%esi
f01015c7:	83 c4 10             	add    $0x10,%esp
f01015ca:	85 c0                	test   %eax,%eax
f01015cc:	0f 84 10 02 00 00    	je     f01017e2 <mem_init+0x480>
	assert((pp2 = page_alloc(0)));
f01015d2:	83 ec 0c             	sub    $0xc,%esp
f01015d5:	6a 00                	push   $0x0
f01015d7:	e8 d3 f9 ff ff       	call   f0100faf <page_alloc>
f01015dc:	89 c7                	mov    %eax,%edi
f01015de:	83 c4 10             	add    $0x10,%esp
f01015e1:	85 c0                	test   %eax,%eax
f01015e3:	0f 84 12 02 00 00    	je     f01017fb <mem_init+0x499>
	assert(pp1 && pp1 != pp0);
f01015e9:	39 f3                	cmp    %esi,%ebx
f01015eb:	0f 84 23 02 00 00    	je     f0101814 <mem_init+0x4b2>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015f1:	39 c3                	cmp    %eax,%ebx
f01015f3:	0f 84 34 02 00 00    	je     f010182d <mem_init+0x4cb>
f01015f9:	39 c6                	cmp    %eax,%esi
f01015fb:	0f 84 2c 02 00 00    	je     f010182d <mem_init+0x4cb>
	assert(!page_alloc(0));
f0101601:	83 ec 0c             	sub    $0xc,%esp
f0101604:	6a 00                	push   $0x0
f0101606:	e8 a4 f9 ff ff       	call   f0100faf <page_alloc>
f010160b:	83 c4 10             	add    $0x10,%esp
f010160e:	85 c0                	test   %eax,%eax
f0101610:	0f 85 30 02 00 00    	jne    f0101846 <mem_init+0x4e4>
f0101616:	89 d8                	mov    %ebx,%eax
f0101618:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f010161e:	c1 f8 03             	sar    $0x3,%eax
f0101621:	89 c2                	mov    %eax,%edx
f0101623:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101626:	25 ff ff 0f 00       	and    $0xfffff,%eax
f010162b:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0101631:	0f 83 28 02 00 00    	jae    f010185f <mem_init+0x4fd>
	memset(page2kva(pp0), 1, PGSIZE);
f0101637:	83 ec 04             	sub    $0x4,%esp
f010163a:	68 00 10 00 00       	push   $0x1000
f010163f:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101641:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101647:	52                   	push   %edx
f0101648:	e8 e2 44 00 00       	call   f0105b2f <memset>
	page_free(pp0);
f010164d:	89 1c 24             	mov    %ebx,(%esp)
f0101650:	e8 d3 f9 ff ff       	call   f0101028 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101655:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010165c:	e8 4e f9 ff ff       	call   f0100faf <page_alloc>
f0101661:	83 c4 10             	add    $0x10,%esp
f0101664:	85 c0                	test   %eax,%eax
f0101666:	0f 84 05 02 00 00    	je     f0101871 <mem_init+0x50f>
	assert(pp && pp0 == pp);
f010166c:	39 c3                	cmp    %eax,%ebx
f010166e:	0f 85 16 02 00 00    	jne    f010188a <mem_init+0x528>
	return (pp - pages) << PGSHIFT;
f0101674:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f010167a:	c1 f8 03             	sar    $0x3,%eax
f010167d:	89 c2                	mov    %eax,%edx
f010167f:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101682:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101687:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f010168d:	0f 83 10 02 00 00    	jae    f01018a3 <mem_init+0x541>
	return (void *)(pa + KERNBASE);
f0101693:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f0101699:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f010169f:	80 38 00             	cmpb   $0x0,(%eax)
f01016a2:	0f 85 0d 02 00 00    	jne    f01018b5 <mem_init+0x553>
f01016a8:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01016ab:	39 d0                	cmp    %edx,%eax
f01016ad:	75 f0                	jne    f010169f <mem_init+0x33d>
	page_free_list = fl;
f01016af:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01016b2:	a3 40 72 21 f0       	mov    %eax,0xf0217240
	page_free(pp0);
f01016b7:	83 ec 0c             	sub    $0xc,%esp
f01016ba:	53                   	push   %ebx
f01016bb:	e8 68 f9 ff ff       	call   f0101028 <page_free>
	page_free(pp1);
f01016c0:	89 34 24             	mov    %esi,(%esp)
f01016c3:	e8 60 f9 ff ff       	call   f0101028 <page_free>
	page_free(pp2);
f01016c8:	89 3c 24             	mov    %edi,(%esp)
f01016cb:	e8 58 f9 ff ff       	call   f0101028 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016d0:	a1 40 72 21 f0       	mov    0xf0217240,%eax
f01016d5:	83 c4 10             	add    $0x10,%esp
f01016d8:	85 c0                	test   %eax,%eax
f01016da:	0f 84 ee 01 00 00    	je     f01018ce <mem_init+0x56c>
		--nfree;
f01016e0:	83 6d d4 01          	subl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016e4:	8b 00                	mov    (%eax),%eax
f01016e6:	eb f0                	jmp    f01016d8 <mem_init+0x376>
	assert((pp0 = page_alloc(0)));
f01016e8:	68 0b 78 10 f0       	push   $0xf010780b
f01016ed:	68 43 77 10 f0       	push   $0xf0107743
f01016f2:	68 81 03 00 00       	push   $0x381
f01016f7:	68 1d 77 10 f0       	push   $0xf010771d
f01016fc:	e8 3f e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101701:	68 21 78 10 f0       	push   $0xf0107821
f0101706:	68 43 77 10 f0       	push   $0xf0107743
f010170b:	68 82 03 00 00       	push   $0x382
f0101710:	68 1d 77 10 f0       	push   $0xf010771d
f0101715:	e8 26 e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010171a:	68 37 78 10 f0       	push   $0xf0107837
f010171f:	68 43 77 10 f0       	push   $0xf0107743
f0101724:	68 83 03 00 00       	push   $0x383
f0101729:	68 1d 77 10 f0       	push   $0xf010771d
f010172e:	e8 0d e9 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f0101733:	68 4d 78 10 f0       	push   $0xf010784d
f0101738:	68 43 77 10 f0       	push   $0xf0107743
f010173d:	68 86 03 00 00       	push   $0x386
f0101742:	68 1d 77 10 f0       	push   $0xf010771d
f0101747:	e8 f4 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010174c:	68 40 6f 10 f0       	push   $0xf0106f40
f0101751:	68 43 77 10 f0       	push   $0xf0107743
f0101756:	68 87 03 00 00       	push   $0x387
f010175b:	68 1d 77 10 f0       	push   $0xf010771d
f0101760:	e8 db e8 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101765:	68 5f 78 10 f0       	push   $0xf010785f
f010176a:	68 43 77 10 f0       	push   $0xf0107743
f010176f:	68 88 03 00 00       	push   $0x388
f0101774:	68 1d 77 10 f0       	push   $0xf010771d
f0101779:	e8 c2 e8 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010177e:	68 7c 78 10 f0       	push   $0xf010787c
f0101783:	68 43 77 10 f0       	push   $0xf0107743
f0101788:	68 89 03 00 00       	push   $0x389
f010178d:	68 1d 77 10 f0       	push   $0xf010771d
f0101792:	e8 a9 e8 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101797:	68 99 78 10 f0       	push   $0xf0107899
f010179c:	68 43 77 10 f0       	push   $0xf0107743
f01017a1:	68 8a 03 00 00       	push   $0x38a
f01017a6:	68 1d 77 10 f0       	push   $0xf010771d
f01017ab:	e8 90 e8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01017b0:	68 b6 78 10 f0       	push   $0xf01078b6
f01017b5:	68 43 77 10 f0       	push   $0xf0107743
f01017ba:	68 91 03 00 00       	push   $0x391
f01017bf:	68 1d 77 10 f0       	push   $0xf010771d
f01017c4:	e8 77 e8 ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f01017c9:	68 0b 78 10 f0       	push   $0xf010780b
f01017ce:	68 43 77 10 f0       	push   $0xf0107743
f01017d3:	68 98 03 00 00       	push   $0x398
f01017d8:	68 1d 77 10 f0       	push   $0xf010771d
f01017dd:	e8 5e e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01017e2:	68 21 78 10 f0       	push   $0xf0107821
f01017e7:	68 43 77 10 f0       	push   $0xf0107743
f01017ec:	68 99 03 00 00       	push   $0x399
f01017f1:	68 1d 77 10 f0       	push   $0xf010771d
f01017f6:	e8 45 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01017fb:	68 37 78 10 f0       	push   $0xf0107837
f0101800:	68 43 77 10 f0       	push   $0xf0107743
f0101805:	68 9a 03 00 00       	push   $0x39a
f010180a:	68 1d 77 10 f0       	push   $0xf010771d
f010180f:	e8 2c e8 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f0101814:	68 4d 78 10 f0       	push   $0xf010784d
f0101819:	68 43 77 10 f0       	push   $0xf0107743
f010181e:	68 9c 03 00 00       	push   $0x39c
f0101823:	68 1d 77 10 f0       	push   $0xf010771d
f0101828:	e8 13 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010182d:	68 40 6f 10 f0       	push   $0xf0106f40
f0101832:	68 43 77 10 f0       	push   $0xf0107743
f0101837:	68 9d 03 00 00       	push   $0x39d
f010183c:	68 1d 77 10 f0       	push   $0xf010771d
f0101841:	e8 fa e7 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101846:	68 b6 78 10 f0       	push   $0xf01078b6
f010184b:	68 43 77 10 f0       	push   $0xf0107743
f0101850:	68 9e 03 00 00       	push   $0x39e
f0101855:	68 1d 77 10 f0       	push   $0xf010771d
f010185a:	e8 e1 e7 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010185f:	52                   	push   %edx
f0101860:	68 e4 67 10 f0       	push   $0xf01067e4
f0101865:	6a 58                	push   $0x58
f0101867:	68 29 77 10 f0       	push   $0xf0107729
f010186c:	e8 cf e7 ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101871:	68 c5 78 10 f0       	push   $0xf01078c5
f0101876:	68 43 77 10 f0       	push   $0xf0107743
f010187b:	68 a3 03 00 00       	push   $0x3a3
f0101880:	68 1d 77 10 f0       	push   $0xf010771d
f0101885:	e8 b6 e7 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f010188a:	68 e3 78 10 f0       	push   $0xf01078e3
f010188f:	68 43 77 10 f0       	push   $0xf0107743
f0101894:	68 a4 03 00 00       	push   $0x3a4
f0101899:	68 1d 77 10 f0       	push   $0xf010771d
f010189e:	e8 9d e7 ff ff       	call   f0100040 <_panic>
f01018a3:	52                   	push   %edx
f01018a4:	68 e4 67 10 f0       	push   $0xf01067e4
f01018a9:	6a 58                	push   $0x58
f01018ab:	68 29 77 10 f0       	push   $0xf0107729
f01018b0:	e8 8b e7 ff ff       	call   f0100040 <_panic>
		assert(c[i] == 0);
f01018b5:	68 f3 78 10 f0       	push   $0xf01078f3
f01018ba:	68 43 77 10 f0       	push   $0xf0107743
f01018bf:	68 a7 03 00 00       	push   $0x3a7
f01018c4:	68 1d 77 10 f0       	push   $0xf010771d
f01018c9:	e8 72 e7 ff ff       	call   f0100040 <_panic>
	assert(nfree == 0);
f01018ce:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01018d2:	0f 85 46 09 00 00    	jne    f010221e <mem_init+0xebc>
	cprintf("check_page_alloc() succeeded!\n");
f01018d8:	83 ec 0c             	sub    $0xc,%esp
f01018db:	68 60 6f 10 f0       	push   $0xf0106f60
f01018e0:	e8 c7 20 00 00       	call   f01039ac <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01018e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018ec:	e8 be f6 ff ff       	call   f0100faf <page_alloc>
f01018f1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01018f4:	83 c4 10             	add    $0x10,%esp
f01018f7:	85 c0                	test   %eax,%eax
f01018f9:	0f 84 38 09 00 00    	je     f0102237 <mem_init+0xed5>
	assert((pp1 = page_alloc(0)));
f01018ff:	83 ec 0c             	sub    $0xc,%esp
f0101902:	6a 00                	push   $0x0
f0101904:	e8 a6 f6 ff ff       	call   f0100faf <page_alloc>
f0101909:	89 c7                	mov    %eax,%edi
f010190b:	83 c4 10             	add    $0x10,%esp
f010190e:	85 c0                	test   %eax,%eax
f0101910:	0f 84 3a 09 00 00    	je     f0102250 <mem_init+0xeee>
	assert((pp2 = page_alloc(0)));
f0101916:	83 ec 0c             	sub    $0xc,%esp
f0101919:	6a 00                	push   $0x0
f010191b:	e8 8f f6 ff ff       	call   f0100faf <page_alloc>
f0101920:	89 c3                	mov    %eax,%ebx
f0101922:	83 c4 10             	add    $0x10,%esp
f0101925:	85 c0                	test   %eax,%eax
f0101927:	0f 84 3c 09 00 00    	je     f0102269 <mem_init+0xf07>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010192d:	39 7d d4             	cmp    %edi,-0x2c(%ebp)
f0101930:	0f 84 4c 09 00 00    	je     f0102282 <mem_init+0xf20>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101936:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101939:	0f 84 5c 09 00 00    	je     f010229b <mem_init+0xf39>
f010193f:	39 c7                	cmp    %eax,%edi
f0101941:	0f 84 54 09 00 00    	je     f010229b <mem_init+0xf39>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101947:	a1 40 72 21 f0       	mov    0xf0217240,%eax
f010194c:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f010194f:	c7 05 40 72 21 f0 00 	movl   $0x0,0xf0217240
f0101956:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101959:	83 ec 0c             	sub    $0xc,%esp
f010195c:	6a 00                	push   $0x0
f010195e:	e8 4c f6 ff ff       	call   f0100faf <page_alloc>
f0101963:	83 c4 10             	add    $0x10,%esp
f0101966:	85 c0                	test   %eax,%eax
f0101968:	0f 85 46 09 00 00    	jne    f01022b4 <mem_init+0xf52>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010196e:	83 ec 04             	sub    $0x4,%esp
f0101971:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101974:	50                   	push   %eax
f0101975:	6a 00                	push   $0x0
f0101977:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f010197d:	e8 ef f7 ff ff       	call   f0101171 <page_lookup>
f0101982:	83 c4 10             	add    $0x10,%esp
f0101985:	85 c0                	test   %eax,%eax
f0101987:	0f 85 40 09 00 00    	jne    f01022cd <mem_init+0xf6b>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010198d:	6a 02                	push   $0x2
f010198f:	6a 00                	push   $0x0
f0101991:	57                   	push   %edi
f0101992:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101998:	e8 c7 f8 ff ff       	call   f0101264 <page_insert>
f010199d:	83 c4 10             	add    $0x10,%esp
f01019a0:	85 c0                	test   %eax,%eax
f01019a2:	0f 89 3e 09 00 00    	jns    f01022e6 <mem_init+0xf84>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019a8:	83 ec 0c             	sub    $0xc,%esp
f01019ab:	ff 75 d4             	pushl  -0x2c(%ebp)
f01019ae:	e8 75 f6 ff ff       	call   f0101028 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019b3:	6a 02                	push   $0x2
f01019b5:	6a 00                	push   $0x0
f01019b7:	57                   	push   %edi
f01019b8:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f01019be:	e8 a1 f8 ff ff       	call   f0101264 <page_insert>
f01019c3:	83 c4 20             	add    $0x20,%esp
f01019c6:	85 c0                	test   %eax,%eax
f01019c8:	0f 85 31 09 00 00    	jne    f01022ff <mem_init+0xf9d>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01019ce:	8b 35 8c 7e 21 f0    	mov    0xf0217e8c,%esi
	return (pp - pages) << PGSHIFT;
f01019d4:	8b 0d 90 7e 21 f0    	mov    0xf0217e90,%ecx
f01019da:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01019dd:	8b 16                	mov    (%esi),%edx
f01019df:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01019e5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019e8:	29 c8                	sub    %ecx,%eax
f01019ea:	c1 f8 03             	sar    $0x3,%eax
f01019ed:	c1 e0 0c             	shl    $0xc,%eax
f01019f0:	39 c2                	cmp    %eax,%edx
f01019f2:	0f 85 20 09 00 00    	jne    f0102318 <mem_init+0xfb6>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01019f8:	ba 00 00 00 00       	mov    $0x0,%edx
f01019fd:	89 f0                	mov    %esi,%eax
f01019ff:	e8 8b f1 ff ff       	call   f0100b8f <check_va2pa>
f0101a04:	89 c2                	mov    %eax,%edx
f0101a06:	89 f8                	mov    %edi,%eax
f0101a08:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101a0b:	c1 f8 03             	sar    $0x3,%eax
f0101a0e:	c1 e0 0c             	shl    $0xc,%eax
f0101a11:	39 c2                	cmp    %eax,%edx
f0101a13:	0f 85 18 09 00 00    	jne    f0102331 <mem_init+0xfcf>
	assert(pp1->pp_ref == 1);
f0101a19:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101a1e:	0f 85 26 09 00 00    	jne    f010234a <mem_init+0xfe8>
	assert(pp0->pp_ref == 1);
f0101a24:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a27:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a2c:	0f 85 31 09 00 00    	jne    f0102363 <mem_init+0x1001>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a32:	6a 02                	push   $0x2
f0101a34:	68 00 10 00 00       	push   $0x1000
f0101a39:	53                   	push   %ebx
f0101a3a:	56                   	push   %esi
f0101a3b:	e8 24 f8 ff ff       	call   f0101264 <page_insert>
f0101a40:	83 c4 10             	add    $0x10,%esp
f0101a43:	85 c0                	test   %eax,%eax
f0101a45:	0f 85 31 09 00 00    	jne    f010237c <mem_init+0x101a>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a4b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a50:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0101a55:	e8 35 f1 ff ff       	call   f0100b8f <check_va2pa>
f0101a5a:	89 c2                	mov    %eax,%edx
f0101a5c:	89 d8                	mov    %ebx,%eax
f0101a5e:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101a64:	c1 f8 03             	sar    $0x3,%eax
f0101a67:	c1 e0 0c             	shl    $0xc,%eax
f0101a6a:	39 c2                	cmp    %eax,%edx
f0101a6c:	0f 85 23 09 00 00    	jne    f0102395 <mem_init+0x1033>
	assert(pp2->pp_ref == 1);
f0101a72:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a77:	0f 85 31 09 00 00    	jne    f01023ae <mem_init+0x104c>

	// should be no free memory
	assert(!page_alloc(0));
f0101a7d:	83 ec 0c             	sub    $0xc,%esp
f0101a80:	6a 00                	push   $0x0
f0101a82:	e8 28 f5 ff ff       	call   f0100faf <page_alloc>
f0101a87:	83 c4 10             	add    $0x10,%esp
f0101a8a:	85 c0                	test   %eax,%eax
f0101a8c:	0f 85 35 09 00 00    	jne    f01023c7 <mem_init+0x1065>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a92:	6a 02                	push   $0x2
f0101a94:	68 00 10 00 00       	push   $0x1000
f0101a99:	53                   	push   %ebx
f0101a9a:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101aa0:	e8 bf f7 ff ff       	call   f0101264 <page_insert>
f0101aa5:	83 c4 10             	add    $0x10,%esp
f0101aa8:	85 c0                	test   %eax,%eax
f0101aaa:	0f 85 30 09 00 00    	jne    f01023e0 <mem_init+0x107e>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ab0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ab5:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0101aba:	e8 d0 f0 ff ff       	call   f0100b8f <check_va2pa>
f0101abf:	89 c2                	mov    %eax,%edx
f0101ac1:	89 d8                	mov    %ebx,%eax
f0101ac3:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101ac9:	c1 f8 03             	sar    $0x3,%eax
f0101acc:	c1 e0 0c             	shl    $0xc,%eax
f0101acf:	39 c2                	cmp    %eax,%edx
f0101ad1:	0f 85 22 09 00 00    	jne    f01023f9 <mem_init+0x1097>
	assert(pp2->pp_ref == 1);
f0101ad7:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101adc:	0f 85 30 09 00 00    	jne    f0102412 <mem_init+0x10b0>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101ae2:	83 ec 0c             	sub    $0xc,%esp
f0101ae5:	6a 00                	push   $0x0
f0101ae7:	e8 c3 f4 ff ff       	call   f0100faf <page_alloc>
f0101aec:	83 c4 10             	add    $0x10,%esp
f0101aef:	85 c0                	test   %eax,%eax
f0101af1:	0f 85 34 09 00 00    	jne    f010242b <mem_init+0x10c9>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101af7:	8b 0d 8c 7e 21 f0    	mov    0xf0217e8c,%ecx
f0101afd:	8b 01                	mov    (%ecx),%eax
f0101aff:	89 c2                	mov    %eax,%edx
f0101b01:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101b07:	c1 e8 0c             	shr    $0xc,%eax
f0101b0a:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0101b10:	0f 83 2e 09 00 00    	jae    f0102444 <mem_init+0x10e2>
	return (void *)(pa + KERNBASE);
f0101b16:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101b1c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101b1f:	83 ec 04             	sub    $0x4,%esp
f0101b22:	6a 00                	push   $0x0
f0101b24:	68 00 10 00 00       	push   $0x1000
f0101b29:	51                   	push   %ecx
f0101b2a:	e8 65 f5 ff ff       	call   f0101094 <pgdir_walk>
f0101b2f:	89 c2                	mov    %eax,%edx
f0101b31:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101b34:	83 c0 04             	add    $0x4,%eax
f0101b37:	83 c4 10             	add    $0x10,%esp
f0101b3a:	39 d0                	cmp    %edx,%eax
f0101b3c:	0f 85 17 09 00 00    	jne    f0102459 <mem_init+0x10f7>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101b42:	6a 06                	push   $0x6
f0101b44:	68 00 10 00 00       	push   $0x1000
f0101b49:	53                   	push   %ebx
f0101b4a:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101b50:	e8 0f f7 ff ff       	call   f0101264 <page_insert>
f0101b55:	83 c4 10             	add    $0x10,%esp
f0101b58:	85 c0                	test   %eax,%eax
f0101b5a:	0f 85 12 09 00 00    	jne    f0102472 <mem_init+0x1110>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b60:	8b 35 8c 7e 21 f0    	mov    0xf0217e8c,%esi
f0101b66:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b6b:	89 f0                	mov    %esi,%eax
f0101b6d:	e8 1d f0 ff ff       	call   f0100b8f <check_va2pa>
f0101b72:	89 c2                	mov    %eax,%edx
	return (pp - pages) << PGSHIFT;
f0101b74:	89 d8                	mov    %ebx,%eax
f0101b76:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101b7c:	c1 f8 03             	sar    $0x3,%eax
f0101b7f:	c1 e0 0c             	shl    $0xc,%eax
f0101b82:	39 c2                	cmp    %eax,%edx
f0101b84:	0f 85 01 09 00 00    	jne    f010248b <mem_init+0x1129>
	assert(pp2->pp_ref == 1);
f0101b8a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b8f:	0f 85 0f 09 00 00    	jne    f01024a4 <mem_init+0x1142>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101b95:	83 ec 04             	sub    $0x4,%esp
f0101b98:	6a 00                	push   $0x0
f0101b9a:	68 00 10 00 00       	push   $0x1000
f0101b9f:	56                   	push   %esi
f0101ba0:	e8 ef f4 ff ff       	call   f0101094 <pgdir_walk>
f0101ba5:	83 c4 10             	add    $0x10,%esp
f0101ba8:	f6 00 04             	testb  $0x4,(%eax)
f0101bab:	0f 84 0c 09 00 00    	je     f01024bd <mem_init+0x115b>
	assert(kern_pgdir[0] & PTE_U);
f0101bb1:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0101bb6:	f6 00 04             	testb  $0x4,(%eax)
f0101bb9:	0f 84 17 09 00 00    	je     f01024d6 <mem_init+0x1174>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bbf:	6a 02                	push   $0x2
f0101bc1:	68 00 10 00 00       	push   $0x1000
f0101bc6:	53                   	push   %ebx
f0101bc7:	50                   	push   %eax
f0101bc8:	e8 97 f6 ff ff       	call   f0101264 <page_insert>
f0101bcd:	83 c4 10             	add    $0x10,%esp
f0101bd0:	85 c0                	test   %eax,%eax
f0101bd2:	0f 85 17 09 00 00    	jne    f01024ef <mem_init+0x118d>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101bd8:	83 ec 04             	sub    $0x4,%esp
f0101bdb:	6a 00                	push   $0x0
f0101bdd:	68 00 10 00 00       	push   $0x1000
f0101be2:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101be8:	e8 a7 f4 ff ff       	call   f0101094 <pgdir_walk>
f0101bed:	83 c4 10             	add    $0x10,%esp
f0101bf0:	f6 00 02             	testb  $0x2,(%eax)
f0101bf3:	0f 84 0f 09 00 00    	je     f0102508 <mem_init+0x11a6>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bf9:	83 ec 04             	sub    $0x4,%esp
f0101bfc:	6a 00                	push   $0x0
f0101bfe:	68 00 10 00 00       	push   $0x1000
f0101c03:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101c09:	e8 86 f4 ff ff       	call   f0101094 <pgdir_walk>
f0101c0e:	83 c4 10             	add    $0x10,%esp
f0101c11:	f6 00 04             	testb  $0x4,(%eax)
f0101c14:	0f 85 07 09 00 00    	jne    f0102521 <mem_init+0x11bf>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101c1a:	6a 02                	push   $0x2
f0101c1c:	68 00 00 40 00       	push   $0x400000
f0101c21:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c24:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101c2a:	e8 35 f6 ff ff       	call   f0101264 <page_insert>
f0101c2f:	83 c4 10             	add    $0x10,%esp
f0101c32:	85 c0                	test   %eax,%eax
f0101c34:	0f 89 00 09 00 00    	jns    f010253a <mem_init+0x11d8>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c3a:	6a 02                	push   $0x2
f0101c3c:	68 00 10 00 00       	push   $0x1000
f0101c41:	57                   	push   %edi
f0101c42:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101c48:	e8 17 f6 ff ff       	call   f0101264 <page_insert>
f0101c4d:	83 c4 10             	add    $0x10,%esp
f0101c50:	85 c0                	test   %eax,%eax
f0101c52:	0f 85 fb 08 00 00    	jne    f0102553 <mem_init+0x11f1>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c58:	83 ec 04             	sub    $0x4,%esp
f0101c5b:	6a 00                	push   $0x0
f0101c5d:	68 00 10 00 00       	push   $0x1000
f0101c62:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101c68:	e8 27 f4 ff ff       	call   f0101094 <pgdir_walk>
f0101c6d:	83 c4 10             	add    $0x10,%esp
f0101c70:	f6 00 04             	testb  $0x4,(%eax)
f0101c73:	0f 85 f3 08 00 00    	jne    f010256c <mem_init+0x120a>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c79:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0101c7e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101c81:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c86:	e8 04 ef ff ff       	call   f0100b8f <check_va2pa>
f0101c8b:	89 fe                	mov    %edi,%esi
f0101c8d:	2b 35 90 7e 21 f0    	sub    0xf0217e90,%esi
f0101c93:	c1 fe 03             	sar    $0x3,%esi
f0101c96:	c1 e6 0c             	shl    $0xc,%esi
f0101c99:	39 f0                	cmp    %esi,%eax
f0101c9b:	0f 85 e4 08 00 00    	jne    f0102585 <mem_init+0x1223>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ca1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ca6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101ca9:	e8 e1 ee ff ff       	call   f0100b8f <check_va2pa>
f0101cae:	39 c6                	cmp    %eax,%esi
f0101cb0:	0f 85 e8 08 00 00    	jne    f010259e <mem_init+0x123c>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101cb6:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101cbb:	0f 85 f6 08 00 00    	jne    f01025b7 <mem_init+0x1255>
	assert(pp2->pp_ref == 0);
f0101cc1:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101cc6:	0f 85 04 09 00 00    	jne    f01025d0 <mem_init+0x126e>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101ccc:	83 ec 0c             	sub    $0xc,%esp
f0101ccf:	6a 00                	push   $0x0
f0101cd1:	e8 d9 f2 ff ff       	call   f0100faf <page_alloc>
f0101cd6:	83 c4 10             	add    $0x10,%esp
f0101cd9:	85 c0                	test   %eax,%eax
f0101cdb:	0f 84 08 09 00 00    	je     f01025e9 <mem_init+0x1287>
f0101ce1:	39 c3                	cmp    %eax,%ebx
f0101ce3:	0f 85 00 09 00 00    	jne    f01025e9 <mem_init+0x1287>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ce9:	83 ec 08             	sub    $0x8,%esp
f0101cec:	6a 00                	push   $0x0
f0101cee:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101cf4:	e8 1a f5 ff ff       	call   f0101213 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cf9:	8b 35 8c 7e 21 f0    	mov    0xf0217e8c,%esi
f0101cff:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d04:	89 f0                	mov    %esi,%eax
f0101d06:	e8 84 ee ff ff       	call   f0100b8f <check_va2pa>
f0101d0b:	83 c4 10             	add    $0x10,%esp
f0101d0e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d11:	0f 85 eb 08 00 00    	jne    f0102602 <mem_init+0x12a0>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d17:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d1c:	89 f0                	mov    %esi,%eax
f0101d1e:	e8 6c ee ff ff       	call   f0100b8f <check_va2pa>
f0101d23:	89 c2                	mov    %eax,%edx
f0101d25:	89 f8                	mov    %edi,%eax
f0101d27:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101d2d:	c1 f8 03             	sar    $0x3,%eax
f0101d30:	c1 e0 0c             	shl    $0xc,%eax
f0101d33:	39 c2                	cmp    %eax,%edx
f0101d35:	0f 85 e0 08 00 00    	jne    f010261b <mem_init+0x12b9>
	assert(pp1->pp_ref == 1);
f0101d3b:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101d40:	0f 85 ee 08 00 00    	jne    f0102634 <mem_init+0x12d2>
	assert(pp2->pp_ref == 0);
f0101d46:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d4b:	0f 85 fc 08 00 00    	jne    f010264d <mem_init+0x12eb>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d51:	6a 00                	push   $0x0
f0101d53:	68 00 10 00 00       	push   $0x1000
f0101d58:	57                   	push   %edi
f0101d59:	56                   	push   %esi
f0101d5a:	e8 05 f5 ff ff       	call   f0101264 <page_insert>
f0101d5f:	83 c4 10             	add    $0x10,%esp
f0101d62:	85 c0                	test   %eax,%eax
f0101d64:	0f 85 fc 08 00 00    	jne    f0102666 <mem_init+0x1304>
	assert(pp1->pp_ref);
f0101d6a:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101d6f:	0f 84 0a 09 00 00    	je     f010267f <mem_init+0x131d>
	assert(pp1->pp_link == NULL);
f0101d75:	83 3f 00             	cmpl   $0x0,(%edi)
f0101d78:	0f 85 1a 09 00 00    	jne    f0102698 <mem_init+0x1336>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101d7e:	83 ec 08             	sub    $0x8,%esp
f0101d81:	68 00 10 00 00       	push   $0x1000
f0101d86:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101d8c:	e8 82 f4 ff ff       	call   f0101213 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d91:	8b 35 8c 7e 21 f0    	mov    0xf0217e8c,%esi
f0101d97:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d9c:	89 f0                	mov    %esi,%eax
f0101d9e:	e8 ec ed ff ff       	call   f0100b8f <check_va2pa>
f0101da3:	83 c4 10             	add    $0x10,%esp
f0101da6:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101da9:	0f 85 02 09 00 00    	jne    f01026b1 <mem_init+0x134f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101daf:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101db4:	89 f0                	mov    %esi,%eax
f0101db6:	e8 d4 ed ff ff       	call   f0100b8f <check_va2pa>
f0101dbb:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dbe:	0f 85 06 09 00 00    	jne    f01026ca <mem_init+0x1368>
	assert(pp1->pp_ref == 0);
f0101dc4:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101dc9:	0f 85 14 09 00 00    	jne    f01026e3 <mem_init+0x1381>
	assert(pp2->pp_ref == 0);
f0101dcf:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101dd4:	0f 85 22 09 00 00    	jne    f01026fc <mem_init+0x139a>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101dda:	83 ec 0c             	sub    $0xc,%esp
f0101ddd:	6a 00                	push   $0x0
f0101ddf:	e8 cb f1 ff ff       	call   f0100faf <page_alloc>
f0101de4:	83 c4 10             	add    $0x10,%esp
f0101de7:	39 c7                	cmp    %eax,%edi
f0101de9:	0f 85 26 09 00 00    	jne    f0102715 <mem_init+0x13b3>
f0101def:	85 c0                	test   %eax,%eax
f0101df1:	0f 84 1e 09 00 00    	je     f0102715 <mem_init+0x13b3>

	// should be no free memory
	assert(!page_alloc(0));
f0101df7:	83 ec 0c             	sub    $0xc,%esp
f0101dfa:	6a 00                	push   $0x0
f0101dfc:	e8 ae f1 ff ff       	call   f0100faf <page_alloc>
f0101e01:	83 c4 10             	add    $0x10,%esp
f0101e04:	85 c0                	test   %eax,%eax
f0101e06:	0f 85 22 09 00 00    	jne    f010272e <mem_init+0x13cc>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e0c:	8b 0d 8c 7e 21 f0    	mov    0xf0217e8c,%ecx
f0101e12:	8b 11                	mov    (%ecx),%edx
f0101e14:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e1a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e1d:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101e23:	c1 f8 03             	sar    $0x3,%eax
f0101e26:	c1 e0 0c             	shl    $0xc,%eax
f0101e29:	39 c2                	cmp    %eax,%edx
f0101e2b:	0f 85 16 09 00 00    	jne    f0102747 <mem_init+0x13e5>
	kern_pgdir[0] = 0;
f0101e31:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101e37:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e3a:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e3f:	0f 85 1b 09 00 00    	jne    f0102760 <mem_init+0x13fe>
	pp0->pp_ref = 0;
f0101e45:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e48:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101e4e:	83 ec 0c             	sub    $0xc,%esp
f0101e51:	50                   	push   %eax
f0101e52:	e8 d1 f1 ff ff       	call   f0101028 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101e57:	83 c4 0c             	add    $0xc,%esp
f0101e5a:	6a 01                	push   $0x1
f0101e5c:	68 00 10 40 00       	push   $0x401000
f0101e61:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101e67:	e8 28 f2 ff ff       	call   f0101094 <pgdir_walk>
f0101e6c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101e6f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101e72:	8b 0d 8c 7e 21 f0    	mov    0xf0217e8c,%ecx
f0101e78:	8b 41 04             	mov    0x4(%ecx),%eax
f0101e7b:	89 c6                	mov    %eax,%esi
f0101e7d:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	if (PGNUM(pa) >= npages)
f0101e83:	8b 15 88 7e 21 f0    	mov    0xf0217e88,%edx
f0101e89:	c1 e8 0c             	shr    $0xc,%eax
f0101e8c:	83 c4 10             	add    $0x10,%esp
f0101e8f:	39 d0                	cmp    %edx,%eax
f0101e91:	0f 83 e2 08 00 00    	jae    f0102779 <mem_init+0x1417>
	assert(ptep == ptep1 + PTX(va));
f0101e97:	81 ee fc ff ff 0f    	sub    $0xffffffc,%esi
f0101e9d:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f0101ea0:	0f 85 e8 08 00 00    	jne    f010278e <mem_init+0x142c>
	kern_pgdir[PDX(va)] = 0;
f0101ea6:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0101ead:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101eb0:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0101eb6:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101ebc:	c1 f8 03             	sar    $0x3,%eax
f0101ebf:	89 c1                	mov    %eax,%ecx
f0101ec1:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f0101ec4:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101ec9:	39 c2                	cmp    %eax,%edx
f0101ecb:	0f 86 d6 08 00 00    	jbe    f01027a7 <mem_init+0x1445>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101ed1:	83 ec 04             	sub    $0x4,%esp
f0101ed4:	68 00 10 00 00       	push   $0x1000
f0101ed9:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0101ede:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0101ee4:	51                   	push   %ecx
f0101ee5:	e8 45 3c 00 00       	call   f0105b2f <memset>
	page_free(pp0);
f0101eea:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101eed:	89 34 24             	mov    %esi,(%esp)
f0101ef0:	e8 33 f1 ff ff       	call   f0101028 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101ef5:	83 c4 0c             	add    $0xc,%esp
f0101ef8:	6a 01                	push   $0x1
f0101efa:	6a 00                	push   $0x0
f0101efc:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101f02:	e8 8d f1 ff ff       	call   f0101094 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0101f07:	89 f0                	mov    %esi,%eax
f0101f09:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101f0f:	c1 f8 03             	sar    $0x3,%eax
f0101f12:	89 c2                	mov    %eax,%edx
f0101f14:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101f17:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101f1c:	83 c4 10             	add    $0x10,%esp
f0101f1f:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0101f25:	0f 83 8e 08 00 00    	jae    f01027b9 <mem_init+0x1457>
	return (void *)(pa + KERNBASE);
f0101f2b:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101f31:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101f34:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101f3a:	f6 00 01             	testb  $0x1,(%eax)
f0101f3d:	0f 85 88 08 00 00    	jne    f01027cb <mem_init+0x1469>
f0101f43:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0101f46:	39 d0                	cmp    %edx,%eax
f0101f48:	75 f0                	jne    f0101f3a <mem_init+0xbd8>
	kern_pgdir[0] = 0;
f0101f4a:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0101f4f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101f55:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f58:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0101f5e:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101f61:	89 0d 40 72 21 f0    	mov    %ecx,0xf0217240

	// free the pages we took
	page_free(pp0);
f0101f67:	83 ec 0c             	sub    $0xc,%esp
f0101f6a:	50                   	push   %eax
f0101f6b:	e8 b8 f0 ff ff       	call   f0101028 <page_free>
	page_free(pp1);
f0101f70:	89 3c 24             	mov    %edi,(%esp)
f0101f73:	e8 b0 f0 ff ff       	call   f0101028 <page_free>
	page_free(pp2);
f0101f78:	89 1c 24             	mov    %ebx,(%esp)
f0101f7b:	e8 a8 f0 ff ff       	call   f0101028 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0101f80:	83 c4 08             	add    $0x8,%esp
f0101f83:	68 01 10 00 00       	push   $0x1001
f0101f88:	6a 00                	push   $0x0
f0101f8a:	e8 57 f3 ff ff       	call   f01012e6 <mmio_map_region>
f0101f8f:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0101f91:	83 c4 08             	add    $0x8,%esp
f0101f94:	68 00 10 00 00       	push   $0x1000
f0101f99:	6a 00                	push   $0x0
f0101f9b:	e8 46 f3 ff ff       	call   f01012e6 <mmio_map_region>
f0101fa0:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8192 < MMIOLIM);
f0101fa2:	8d 83 00 20 00 00    	lea    0x2000(%ebx),%eax
f0101fa8:	83 c4 10             	add    $0x10,%esp
f0101fab:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0101fb1:	0f 86 2d 08 00 00    	jbe    f01027e4 <mem_init+0x1482>
f0101fb7:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0101fbc:	0f 87 22 08 00 00    	ja     f01027e4 <mem_init+0x1482>
	assert(mm2 >= MMIOBASE && mm2 + 8192 < MMIOLIM);
f0101fc2:	8d 96 00 20 00 00    	lea    0x2000(%esi),%edx
f0101fc8:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0101fce:	0f 87 29 08 00 00    	ja     f01027fd <mem_init+0x149b>
f0101fd4:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0101fda:	0f 86 1d 08 00 00    	jbe    f01027fd <mem_init+0x149b>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0101fe0:	89 da                	mov    %ebx,%edx
f0101fe2:	09 f2                	or     %esi,%edx
f0101fe4:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0101fea:	0f 85 26 08 00 00    	jne    f0102816 <mem_init+0x14b4>
	// check that they don't overlap
	assert(mm1 + 8192 <= mm2);
f0101ff0:	39 c6                	cmp    %eax,%esi
f0101ff2:	0f 82 37 08 00 00    	jb     f010282f <mem_init+0x14cd>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0101ff8:	8b 3d 8c 7e 21 f0    	mov    0xf0217e8c,%edi
f0101ffe:	89 da                	mov    %ebx,%edx
f0102000:	89 f8                	mov    %edi,%eax
f0102002:	e8 88 eb ff ff       	call   f0100b8f <check_va2pa>
f0102007:	85 c0                	test   %eax,%eax
f0102009:	0f 85 39 08 00 00    	jne    f0102848 <mem_init+0x14e6>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f010200f:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102015:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102018:	89 c2                	mov    %eax,%edx
f010201a:	89 f8                	mov    %edi,%eax
f010201c:	e8 6e eb ff ff       	call   f0100b8f <check_va2pa>
f0102021:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102026:	0f 85 35 08 00 00    	jne    f0102861 <mem_init+0x14ff>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f010202c:	89 f2                	mov    %esi,%edx
f010202e:	89 f8                	mov    %edi,%eax
f0102030:	e8 5a eb ff ff       	call   f0100b8f <check_va2pa>
f0102035:	85 c0                	test   %eax,%eax
f0102037:	0f 85 3d 08 00 00    	jne    f010287a <mem_init+0x1518>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f010203d:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102043:	89 f8                	mov    %edi,%eax
f0102045:	e8 45 eb ff ff       	call   f0100b8f <check_va2pa>
f010204a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010204d:	0f 85 40 08 00 00    	jne    f0102893 <mem_init+0x1531>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102053:	83 ec 04             	sub    $0x4,%esp
f0102056:	6a 00                	push   $0x0
f0102058:	53                   	push   %ebx
f0102059:	57                   	push   %edi
f010205a:	e8 35 f0 ff ff       	call   f0101094 <pgdir_walk>
f010205f:	83 c4 10             	add    $0x10,%esp
f0102062:	f6 00 1a             	testb  $0x1a,(%eax)
f0102065:	0f 84 41 08 00 00    	je     f01028ac <mem_init+0x154a>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f010206b:	83 ec 04             	sub    $0x4,%esp
f010206e:	6a 00                	push   $0x0
f0102070:	53                   	push   %ebx
f0102071:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0102077:	e8 18 f0 ff ff       	call   f0101094 <pgdir_walk>
f010207c:	8b 00                	mov    (%eax),%eax
f010207e:	83 c4 10             	add    $0x10,%esp
f0102081:	83 e0 04             	and    $0x4,%eax
f0102084:	89 c7                	mov    %eax,%edi
f0102086:	0f 85 39 08 00 00    	jne    f01028c5 <mem_init+0x1563>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f010208c:	83 ec 04             	sub    $0x4,%esp
f010208f:	6a 00                	push   $0x0
f0102091:	53                   	push   %ebx
f0102092:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0102098:	e8 f7 ef ff ff       	call   f0101094 <pgdir_walk>
f010209d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f01020a3:	83 c4 0c             	add    $0xc,%esp
f01020a6:	6a 00                	push   $0x0
f01020a8:	ff 75 d4             	pushl  -0x2c(%ebp)
f01020ab:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f01020b1:	e8 de ef ff ff       	call   f0101094 <pgdir_walk>
f01020b6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f01020bc:	83 c4 0c             	add    $0xc,%esp
f01020bf:	6a 00                	push   $0x0
f01020c1:	56                   	push   %esi
f01020c2:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f01020c8:	e8 c7 ef ff ff       	call   f0101094 <pgdir_walk>
f01020cd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f01020d3:	c7 04 24 e6 79 10 f0 	movl   $0xf01079e6,(%esp)
f01020da:	e8 cd 18 00 00       	call   f01039ac <cprintf>
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U);
f01020df:	a1 90 7e 21 f0       	mov    0xf0217e90,%eax
	if ((uint32_t)kva < KERNBASE)
f01020e4:	83 c4 10             	add    $0x10,%esp
f01020e7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020ec:	0f 86 ec 07 00 00    	jbe    f01028de <mem_init+0x157c>
f01020f2:	83 ec 08             	sub    $0x8,%esp
f01020f5:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f01020f7:	05 00 00 00 10       	add    $0x10000000,%eax
f01020fc:	50                   	push   %eax
f01020fd:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102102:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102107:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f010210c:	e8 14 f0 ff ff       	call   f0101125 <boot_map_region>
	boot_map_region(kern_pgdir,UENVS,PTSIZE,PADDR(envs),PTE_U);
f0102111:	a1 48 72 21 f0       	mov    0xf0217248,%eax
	if ((uint32_t)kva < KERNBASE)
f0102116:	83 c4 10             	add    $0x10,%esp
f0102119:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010211e:	0f 86 cf 07 00 00    	jbe    f01028f3 <mem_init+0x1591>
f0102124:	83 ec 08             	sub    $0x8,%esp
f0102127:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102129:	05 00 00 00 10       	add    $0x10000000,%eax
f010212e:	50                   	push   %eax
f010212f:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102134:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102139:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f010213e:	e8 e2 ef ff ff       	call   f0101125 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f0102143:	83 c4 10             	add    $0x10,%esp
f0102146:	b8 00 90 11 f0       	mov    $0xf0119000,%eax
f010214b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102150:	0f 86 b2 07 00 00    	jbe    f0102908 <mem_init+0x15a6>
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f0102156:	83 ec 08             	sub    $0x8,%esp
f0102159:	6a 02                	push   $0x2
f010215b:	68 00 90 11 00       	push   $0x119000
f0102160:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102165:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010216a:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f010216f:	e8 b1 ef ff ff       	call   f0101125 <boot_map_region>
f0102174:	c7 45 d0 00 90 21 f0 	movl   $0xf0219000,-0x30(%ebp)
f010217b:	83 c4 10             	add    $0x10,%esp
f010217e:	bb 00 90 21 f0       	mov    $0xf0219000,%ebx
f0102183:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102188:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f010218e:	0f 86 89 07 00 00    	jbe    f010291d <mem_init+0x15bb>
		boot_map_region(kern_pgdir,kstacktop_i,KSTKSIZE,pa,PTE_W|PTE_P);
f0102194:	83 ec 08             	sub    $0x8,%esp
f0102197:	6a 03                	push   $0x3
f0102199:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f010219f:	50                   	push   %eax
f01021a0:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021a5:	89 f2                	mov    %esi,%edx
f01021a7:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f01021ac:	e8 74 ef ff ff       	call   f0101125 <boot_map_region>
f01021b1:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f01021b7:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	for(int i = 0;i<NCPU;i++)
f01021bd:	83 c4 10             	add    $0x10,%esp
f01021c0:	81 fb 00 90 25 f0    	cmp    $0xf0259000,%ebx
f01021c6:	75 c0                	jne    f0102188 <mem_init+0xe26>
	boot_map_region(kern_pgdir,KERNBASE,0xFFFFFFFF-KERNBASE,0,PTE_W);
f01021c8:	83 ec 08             	sub    $0x8,%esp
f01021cb:	6a 02                	push   $0x2
f01021cd:	6a 00                	push   $0x0
f01021cf:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01021d4:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021d9:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f01021de:	e8 42 ef ff ff       	call   f0101125 <boot_map_region>
	pgdir = kern_pgdir;
f01021e3:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f01021e8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021eb:	a1 88 7e 21 f0       	mov    0xf0217e88,%eax
f01021f0:	89 45 c0             	mov    %eax,-0x40(%ebp)
f01021f3:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021fa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021ff:	89 45 cc             	mov    %eax,-0x34(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102202:	8b 35 90 7e 21 f0    	mov    0xf0217e90,%esi
f0102208:	89 75 c8             	mov    %esi,-0x38(%ebp)
	return (physaddr_t)kva - KERNBASE;
f010220b:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0102211:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f0102214:	83 c4 10             	add    $0x10,%esp
f0102217:	89 fb                	mov    %edi,%ebx
f0102219:	e9 2f 07 00 00       	jmp    f010294d <mem_init+0x15eb>
	assert(nfree == 0);
f010221e:	68 fd 78 10 f0       	push   $0xf01078fd
f0102223:	68 43 77 10 f0       	push   $0xf0107743
f0102228:	68 b4 03 00 00       	push   $0x3b4
f010222d:	68 1d 77 10 f0       	push   $0xf010771d
f0102232:	e8 09 de ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f0102237:	68 0b 78 10 f0       	push   $0xf010780b
f010223c:	68 43 77 10 f0       	push   $0xf0107743
f0102241:	68 1a 04 00 00       	push   $0x41a
f0102246:	68 1d 77 10 f0       	push   $0xf010771d
f010224b:	e8 f0 dd ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102250:	68 21 78 10 f0       	push   $0xf0107821
f0102255:	68 43 77 10 f0       	push   $0xf0107743
f010225a:	68 1b 04 00 00       	push   $0x41b
f010225f:	68 1d 77 10 f0       	push   $0xf010771d
f0102264:	e8 d7 dd ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102269:	68 37 78 10 f0       	push   $0xf0107837
f010226e:	68 43 77 10 f0       	push   $0xf0107743
f0102273:	68 1c 04 00 00       	push   $0x41c
f0102278:	68 1d 77 10 f0       	push   $0xf010771d
f010227d:	e8 be dd ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f0102282:	68 4d 78 10 f0       	push   $0xf010784d
f0102287:	68 43 77 10 f0       	push   $0xf0107743
f010228c:	68 1f 04 00 00       	push   $0x41f
f0102291:	68 1d 77 10 f0       	push   $0xf010771d
f0102296:	e8 a5 dd ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010229b:	68 40 6f 10 f0       	push   $0xf0106f40
f01022a0:	68 43 77 10 f0       	push   $0xf0107743
f01022a5:	68 20 04 00 00       	push   $0x420
f01022aa:	68 1d 77 10 f0       	push   $0xf010771d
f01022af:	e8 8c dd ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01022b4:	68 b6 78 10 f0       	push   $0xf01078b6
f01022b9:	68 43 77 10 f0       	push   $0xf0107743
f01022be:	68 27 04 00 00       	push   $0x427
f01022c3:	68 1d 77 10 f0       	push   $0xf010771d
f01022c8:	e8 73 dd ff ff       	call   f0100040 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01022cd:	68 80 6f 10 f0       	push   $0xf0106f80
f01022d2:	68 43 77 10 f0       	push   $0xf0107743
f01022d7:	68 2a 04 00 00       	push   $0x42a
f01022dc:	68 1d 77 10 f0       	push   $0xf010771d
f01022e1:	e8 5a dd ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01022e6:	68 b8 6f 10 f0       	push   $0xf0106fb8
f01022eb:	68 43 77 10 f0       	push   $0xf0107743
f01022f0:	68 2d 04 00 00       	push   $0x42d
f01022f5:	68 1d 77 10 f0       	push   $0xf010771d
f01022fa:	e8 41 dd ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01022ff:	68 e8 6f 10 f0       	push   $0xf0106fe8
f0102304:	68 43 77 10 f0       	push   $0xf0107743
f0102309:	68 31 04 00 00       	push   $0x431
f010230e:	68 1d 77 10 f0       	push   $0xf010771d
f0102313:	e8 28 dd ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102318:	68 18 70 10 f0       	push   $0xf0107018
f010231d:	68 43 77 10 f0       	push   $0xf0107743
f0102322:	68 32 04 00 00       	push   $0x432
f0102327:	68 1d 77 10 f0       	push   $0xf010771d
f010232c:	e8 0f dd ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0102331:	68 40 70 10 f0       	push   $0xf0107040
f0102336:	68 43 77 10 f0       	push   $0xf0107743
f010233b:	68 33 04 00 00       	push   $0x433
f0102340:	68 1d 77 10 f0       	push   $0xf010771d
f0102345:	e8 f6 dc ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f010234a:	68 08 79 10 f0       	push   $0xf0107908
f010234f:	68 43 77 10 f0       	push   $0xf0107743
f0102354:	68 34 04 00 00       	push   $0x434
f0102359:	68 1d 77 10 f0       	push   $0xf010771d
f010235e:	e8 dd dc ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0102363:	68 19 79 10 f0       	push   $0xf0107919
f0102368:	68 43 77 10 f0       	push   $0xf0107743
f010236d:	68 35 04 00 00       	push   $0x435
f0102372:	68 1d 77 10 f0       	push   $0xf010771d
f0102377:	e8 c4 dc ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010237c:	68 70 70 10 f0       	push   $0xf0107070
f0102381:	68 43 77 10 f0       	push   $0xf0107743
f0102386:	68 38 04 00 00       	push   $0x438
f010238b:	68 1d 77 10 f0       	push   $0xf010771d
f0102390:	e8 ab dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102395:	68 ac 70 10 f0       	push   $0xf01070ac
f010239a:	68 43 77 10 f0       	push   $0xf0107743
f010239f:	68 39 04 00 00       	push   $0x439
f01023a4:	68 1d 77 10 f0       	push   $0xf010771d
f01023a9:	e8 92 dc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01023ae:	68 2a 79 10 f0       	push   $0xf010792a
f01023b3:	68 43 77 10 f0       	push   $0xf0107743
f01023b8:	68 3a 04 00 00       	push   $0x43a
f01023bd:	68 1d 77 10 f0       	push   $0xf010771d
f01023c2:	e8 79 dc ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01023c7:	68 b6 78 10 f0       	push   $0xf01078b6
f01023cc:	68 43 77 10 f0       	push   $0xf0107743
f01023d1:	68 3d 04 00 00       	push   $0x43d
f01023d6:	68 1d 77 10 f0       	push   $0xf010771d
f01023db:	e8 60 dc ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023e0:	68 70 70 10 f0       	push   $0xf0107070
f01023e5:	68 43 77 10 f0       	push   $0xf0107743
f01023ea:	68 40 04 00 00       	push   $0x440
f01023ef:	68 1d 77 10 f0       	push   $0xf010771d
f01023f4:	e8 47 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01023f9:	68 ac 70 10 f0       	push   $0xf01070ac
f01023fe:	68 43 77 10 f0       	push   $0xf0107743
f0102403:	68 41 04 00 00       	push   $0x441
f0102408:	68 1d 77 10 f0       	push   $0xf010771d
f010240d:	e8 2e dc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102412:	68 2a 79 10 f0       	push   $0xf010792a
f0102417:	68 43 77 10 f0       	push   $0xf0107743
f010241c:	68 42 04 00 00       	push   $0x442
f0102421:	68 1d 77 10 f0       	push   $0xf010771d
f0102426:	e8 15 dc ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f010242b:	68 b6 78 10 f0       	push   $0xf01078b6
f0102430:	68 43 77 10 f0       	push   $0xf0107743
f0102435:	68 46 04 00 00       	push   $0x446
f010243a:	68 1d 77 10 f0       	push   $0xf010771d
f010243f:	e8 fc db ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102444:	52                   	push   %edx
f0102445:	68 e4 67 10 f0       	push   $0xf01067e4
f010244a:	68 49 04 00 00       	push   $0x449
f010244f:	68 1d 77 10 f0       	push   $0xf010771d
f0102454:	e8 e7 db ff ff       	call   f0100040 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102459:	68 dc 70 10 f0       	push   $0xf01070dc
f010245e:	68 43 77 10 f0       	push   $0xf0107743
f0102463:	68 4a 04 00 00       	push   $0x44a
f0102468:	68 1d 77 10 f0       	push   $0xf010771d
f010246d:	e8 ce db ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102472:	68 1c 71 10 f0       	push   $0xf010711c
f0102477:	68 43 77 10 f0       	push   $0xf0107743
f010247c:	68 4d 04 00 00       	push   $0x44d
f0102481:	68 1d 77 10 f0       	push   $0xf010771d
f0102486:	e8 b5 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010248b:	68 ac 70 10 f0       	push   $0xf01070ac
f0102490:	68 43 77 10 f0       	push   $0xf0107743
f0102495:	68 4e 04 00 00       	push   $0x44e
f010249a:	68 1d 77 10 f0       	push   $0xf010771d
f010249f:	e8 9c db ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01024a4:	68 2a 79 10 f0       	push   $0xf010792a
f01024a9:	68 43 77 10 f0       	push   $0xf0107743
f01024ae:	68 4f 04 00 00       	push   $0x44f
f01024b3:	68 1d 77 10 f0       	push   $0xf010771d
f01024b8:	e8 83 db ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01024bd:	68 5c 71 10 f0       	push   $0xf010715c
f01024c2:	68 43 77 10 f0       	push   $0xf0107743
f01024c7:	68 50 04 00 00       	push   $0x450
f01024cc:	68 1d 77 10 f0       	push   $0xf010771d
f01024d1:	e8 6a db ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01024d6:	68 3b 79 10 f0       	push   $0xf010793b
f01024db:	68 43 77 10 f0       	push   $0xf0107743
f01024e0:	68 51 04 00 00       	push   $0x451
f01024e5:	68 1d 77 10 f0       	push   $0xf010771d
f01024ea:	e8 51 db ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01024ef:	68 70 70 10 f0       	push   $0xf0107070
f01024f4:	68 43 77 10 f0       	push   $0xf0107743
f01024f9:	68 54 04 00 00       	push   $0x454
f01024fe:	68 1d 77 10 f0       	push   $0xf010771d
f0102503:	e8 38 db ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102508:	68 90 71 10 f0       	push   $0xf0107190
f010250d:	68 43 77 10 f0       	push   $0xf0107743
f0102512:	68 55 04 00 00       	push   $0x455
f0102517:	68 1d 77 10 f0       	push   $0xf010771d
f010251c:	e8 1f db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102521:	68 c4 71 10 f0       	push   $0xf01071c4
f0102526:	68 43 77 10 f0       	push   $0xf0107743
f010252b:	68 56 04 00 00       	push   $0x456
f0102530:	68 1d 77 10 f0       	push   $0xf010771d
f0102535:	e8 06 db ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010253a:	68 fc 71 10 f0       	push   $0xf01071fc
f010253f:	68 43 77 10 f0       	push   $0xf0107743
f0102544:	68 59 04 00 00       	push   $0x459
f0102549:	68 1d 77 10 f0       	push   $0xf010771d
f010254e:	e8 ed da ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102553:	68 34 72 10 f0       	push   $0xf0107234
f0102558:	68 43 77 10 f0       	push   $0xf0107743
f010255d:	68 5c 04 00 00       	push   $0x45c
f0102562:	68 1d 77 10 f0       	push   $0xf010771d
f0102567:	e8 d4 da ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010256c:	68 c4 71 10 f0       	push   $0xf01071c4
f0102571:	68 43 77 10 f0       	push   $0xf0107743
f0102576:	68 5d 04 00 00       	push   $0x45d
f010257b:	68 1d 77 10 f0       	push   $0xf010771d
f0102580:	e8 bb da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102585:	68 70 72 10 f0       	push   $0xf0107270
f010258a:	68 43 77 10 f0       	push   $0xf0107743
f010258f:	68 60 04 00 00       	push   $0x460
f0102594:	68 1d 77 10 f0       	push   $0xf010771d
f0102599:	e8 a2 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010259e:	68 9c 72 10 f0       	push   $0xf010729c
f01025a3:	68 43 77 10 f0       	push   $0xf0107743
f01025a8:	68 61 04 00 00       	push   $0x461
f01025ad:	68 1d 77 10 f0       	push   $0xf010771d
f01025b2:	e8 89 da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 2);
f01025b7:	68 51 79 10 f0       	push   $0xf0107951
f01025bc:	68 43 77 10 f0       	push   $0xf0107743
f01025c1:	68 63 04 00 00       	push   $0x463
f01025c6:	68 1d 77 10 f0       	push   $0xf010771d
f01025cb:	e8 70 da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01025d0:	68 62 79 10 f0       	push   $0xf0107962
f01025d5:	68 43 77 10 f0       	push   $0xf0107743
f01025da:	68 64 04 00 00       	push   $0x464
f01025df:	68 1d 77 10 f0       	push   $0xf010771d
f01025e4:	e8 57 da ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f01025e9:	68 cc 72 10 f0       	push   $0xf01072cc
f01025ee:	68 43 77 10 f0       	push   $0xf0107743
f01025f3:	68 67 04 00 00       	push   $0x467
f01025f8:	68 1d 77 10 f0       	push   $0xf010771d
f01025fd:	e8 3e da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102602:	68 f0 72 10 f0       	push   $0xf01072f0
f0102607:	68 43 77 10 f0       	push   $0xf0107743
f010260c:	68 6b 04 00 00       	push   $0x46b
f0102611:	68 1d 77 10 f0       	push   $0xf010771d
f0102616:	e8 25 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010261b:	68 9c 72 10 f0       	push   $0xf010729c
f0102620:	68 43 77 10 f0       	push   $0xf0107743
f0102625:	68 6c 04 00 00       	push   $0x46c
f010262a:	68 1d 77 10 f0       	push   $0xf010771d
f010262f:	e8 0c da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102634:	68 08 79 10 f0       	push   $0xf0107908
f0102639:	68 43 77 10 f0       	push   $0xf0107743
f010263e:	68 6d 04 00 00       	push   $0x46d
f0102643:	68 1d 77 10 f0       	push   $0xf010771d
f0102648:	e8 f3 d9 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010264d:	68 62 79 10 f0       	push   $0xf0107962
f0102652:	68 43 77 10 f0       	push   $0xf0107743
f0102657:	68 6e 04 00 00       	push   $0x46e
f010265c:	68 1d 77 10 f0       	push   $0xf010771d
f0102661:	e8 da d9 ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102666:	68 14 73 10 f0       	push   $0xf0107314
f010266b:	68 43 77 10 f0       	push   $0xf0107743
f0102670:	68 71 04 00 00       	push   $0x471
f0102675:	68 1d 77 10 f0       	push   $0xf010771d
f010267a:	e8 c1 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f010267f:	68 73 79 10 f0       	push   $0xf0107973
f0102684:	68 43 77 10 f0       	push   $0xf0107743
f0102689:	68 72 04 00 00       	push   $0x472
f010268e:	68 1d 77 10 f0       	push   $0xf010771d
f0102693:	e8 a8 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0102698:	68 7f 79 10 f0       	push   $0xf010797f
f010269d:	68 43 77 10 f0       	push   $0xf0107743
f01026a2:	68 73 04 00 00       	push   $0x473
f01026a7:	68 1d 77 10 f0       	push   $0xf010771d
f01026ac:	e8 8f d9 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01026b1:	68 f0 72 10 f0       	push   $0xf01072f0
f01026b6:	68 43 77 10 f0       	push   $0xf0107743
f01026bb:	68 77 04 00 00       	push   $0x477
f01026c0:	68 1d 77 10 f0       	push   $0xf010771d
f01026c5:	e8 76 d9 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01026ca:	68 4c 73 10 f0       	push   $0xf010734c
f01026cf:	68 43 77 10 f0       	push   $0xf0107743
f01026d4:	68 78 04 00 00       	push   $0x478
f01026d9:	68 1d 77 10 f0       	push   $0xf010771d
f01026de:	e8 5d d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01026e3:	68 94 79 10 f0       	push   $0xf0107994
f01026e8:	68 43 77 10 f0       	push   $0xf0107743
f01026ed:	68 79 04 00 00       	push   $0x479
f01026f2:	68 1d 77 10 f0       	push   $0xf010771d
f01026f7:	e8 44 d9 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01026fc:	68 62 79 10 f0       	push   $0xf0107962
f0102701:	68 43 77 10 f0       	push   $0xf0107743
f0102706:	68 7a 04 00 00       	push   $0x47a
f010270b:	68 1d 77 10 f0       	push   $0xf010771d
f0102710:	e8 2b d9 ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f0102715:	68 74 73 10 f0       	push   $0xf0107374
f010271a:	68 43 77 10 f0       	push   $0xf0107743
f010271f:	68 7d 04 00 00       	push   $0x47d
f0102724:	68 1d 77 10 f0       	push   $0xf010771d
f0102729:	e8 12 d9 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f010272e:	68 b6 78 10 f0       	push   $0xf01078b6
f0102733:	68 43 77 10 f0       	push   $0xf0107743
f0102738:	68 80 04 00 00       	push   $0x480
f010273d:	68 1d 77 10 f0       	push   $0xf010771d
f0102742:	e8 f9 d8 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102747:	68 18 70 10 f0       	push   $0xf0107018
f010274c:	68 43 77 10 f0       	push   $0xf0107743
f0102751:	68 83 04 00 00       	push   $0x483
f0102756:	68 1d 77 10 f0       	push   $0xf010771d
f010275b:	e8 e0 d8 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0102760:	68 19 79 10 f0       	push   $0xf0107919
f0102765:	68 43 77 10 f0       	push   $0xf0107743
f010276a:	68 85 04 00 00       	push   $0x485
f010276f:	68 1d 77 10 f0       	push   $0xf010771d
f0102774:	e8 c7 d8 ff ff       	call   f0100040 <_panic>
f0102779:	56                   	push   %esi
f010277a:	68 e4 67 10 f0       	push   $0xf01067e4
f010277f:	68 8c 04 00 00       	push   $0x48c
f0102784:	68 1d 77 10 f0       	push   $0xf010771d
f0102789:	e8 b2 d8 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010278e:	68 a5 79 10 f0       	push   $0xf01079a5
f0102793:	68 43 77 10 f0       	push   $0xf0107743
f0102798:	68 8d 04 00 00       	push   $0x48d
f010279d:	68 1d 77 10 f0       	push   $0xf010771d
f01027a2:	e8 99 d8 ff ff       	call   f0100040 <_panic>
f01027a7:	51                   	push   %ecx
f01027a8:	68 e4 67 10 f0       	push   $0xf01067e4
f01027ad:	6a 58                	push   $0x58
f01027af:	68 29 77 10 f0       	push   $0xf0107729
f01027b4:	e8 87 d8 ff ff       	call   f0100040 <_panic>
f01027b9:	52                   	push   %edx
f01027ba:	68 e4 67 10 f0       	push   $0xf01067e4
f01027bf:	6a 58                	push   $0x58
f01027c1:	68 29 77 10 f0       	push   $0xf0107729
f01027c6:	e8 75 d8 ff ff       	call   f0100040 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f01027cb:	68 bd 79 10 f0       	push   $0xf01079bd
f01027d0:	68 43 77 10 f0       	push   $0xf0107743
f01027d5:	68 97 04 00 00       	push   $0x497
f01027da:	68 1d 77 10 f0       	push   $0xf010771d
f01027df:	e8 5c d8 ff ff       	call   f0100040 <_panic>
	assert(mm1 >= MMIOBASE && mm1 + 8192 < MMIOLIM);
f01027e4:	68 98 73 10 f0       	push   $0xf0107398
f01027e9:	68 43 77 10 f0       	push   $0xf0107743
f01027ee:	68 a7 04 00 00       	push   $0x4a7
f01027f3:	68 1d 77 10 f0       	push   $0xf010771d
f01027f8:	e8 43 d8 ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8192 < MMIOLIM);
f01027fd:	68 c0 73 10 f0       	push   $0xf01073c0
f0102802:	68 43 77 10 f0       	push   $0xf0107743
f0102807:	68 a8 04 00 00       	push   $0x4a8
f010280c:	68 1d 77 10 f0       	push   $0xf010771d
f0102811:	e8 2a d8 ff ff       	call   f0100040 <_panic>
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102816:	68 e8 73 10 f0       	push   $0xf01073e8
f010281b:	68 43 77 10 f0       	push   $0xf0107743
f0102820:	68 aa 04 00 00       	push   $0x4aa
f0102825:	68 1d 77 10 f0       	push   $0xf010771d
f010282a:	e8 11 d8 ff ff       	call   f0100040 <_panic>
	assert(mm1 + 8192 <= mm2);
f010282f:	68 d4 79 10 f0       	push   $0xf01079d4
f0102834:	68 43 77 10 f0       	push   $0xf0107743
f0102839:	68 ac 04 00 00       	push   $0x4ac
f010283e:	68 1d 77 10 f0       	push   $0xf010771d
f0102843:	e8 f8 d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102848:	68 10 74 10 f0       	push   $0xf0107410
f010284d:	68 43 77 10 f0       	push   $0xf0107743
f0102852:	68 ae 04 00 00       	push   $0x4ae
f0102857:	68 1d 77 10 f0       	push   $0xf010771d
f010285c:	e8 df d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102861:	68 34 74 10 f0       	push   $0xf0107434
f0102866:	68 43 77 10 f0       	push   $0xf0107743
f010286b:	68 af 04 00 00       	push   $0x4af
f0102870:	68 1d 77 10 f0       	push   $0xf010771d
f0102875:	e8 c6 d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f010287a:	68 64 74 10 f0       	push   $0xf0107464
f010287f:	68 43 77 10 f0       	push   $0xf0107743
f0102884:	68 b0 04 00 00       	push   $0x4b0
f0102889:	68 1d 77 10 f0       	push   $0xf010771d
f010288e:	e8 ad d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102893:	68 88 74 10 f0       	push   $0xf0107488
f0102898:	68 43 77 10 f0       	push   $0xf0107743
f010289d:	68 b1 04 00 00       	push   $0x4b1
f01028a2:	68 1d 77 10 f0       	push   $0xf010771d
f01028a7:	e8 94 d7 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f01028ac:	68 b4 74 10 f0       	push   $0xf01074b4
f01028b1:	68 43 77 10 f0       	push   $0xf0107743
f01028b6:	68 b3 04 00 00       	push   $0x4b3
f01028bb:	68 1d 77 10 f0       	push   $0xf010771d
f01028c0:	e8 7b d7 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f01028c5:	68 f8 74 10 f0       	push   $0xf01074f8
f01028ca:	68 43 77 10 f0       	push   $0xf0107743
f01028cf:	68 b4 04 00 00       	push   $0x4b4
f01028d4:	68 1d 77 10 f0       	push   $0xf010771d
f01028d9:	e8 62 d7 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028de:	50                   	push   %eax
f01028df:	68 08 68 10 f0       	push   $0xf0106808
f01028e4:	68 cd 00 00 00       	push   $0xcd
f01028e9:	68 1d 77 10 f0       	push   $0xf010771d
f01028ee:	e8 4d d7 ff ff       	call   f0100040 <_panic>
f01028f3:	50                   	push   %eax
f01028f4:	68 08 68 10 f0       	push   $0xf0106808
f01028f9:	68 d5 00 00 00       	push   $0xd5
f01028fe:	68 1d 77 10 f0       	push   $0xf010771d
f0102903:	e8 38 d7 ff ff       	call   f0100040 <_panic>
f0102908:	50                   	push   %eax
f0102909:	68 08 68 10 f0       	push   $0xf0106808
f010290e:	68 e1 00 00 00       	push   $0xe1
f0102913:	68 1d 77 10 f0       	push   $0xf010771d
f0102918:	e8 23 d7 ff ff       	call   f0100040 <_panic>
f010291d:	53                   	push   %ebx
f010291e:	68 08 68 10 f0       	push   $0xf0106808
f0102923:	68 21 01 00 00       	push   $0x121
f0102928:	68 1d 77 10 f0       	push   $0xf010771d
f010292d:	e8 0e d7 ff ff       	call   f0100040 <_panic>
f0102932:	56                   	push   %esi
f0102933:	68 08 68 10 f0       	push   $0xf0106808
f0102938:	68 cc 03 00 00       	push   $0x3cc
f010293d:	68 1d 77 10 f0       	push   $0xf010771d
f0102942:	e8 f9 d6 ff ff       	call   f0100040 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f0102947:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010294d:	39 5d cc             	cmp    %ebx,-0x34(%ebp)
f0102950:	76 3a                	jbe    f010298c <mem_init+0x162a>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102952:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102958:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010295b:	e8 2f e2 ff ff       	call   f0100b8f <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102960:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f0102967:	76 c9                	jbe    f0102932 <mem_init+0x15d0>
f0102969:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f010296c:	8d 14 0b             	lea    (%ebx,%ecx,1),%edx
f010296f:	39 d0                	cmp    %edx,%eax
f0102971:	74 d4                	je     f0102947 <mem_init+0x15e5>
f0102973:	68 2c 75 10 f0       	push   $0xf010752c
f0102978:	68 43 77 10 f0       	push   $0xf0107743
f010297d:	68 cc 03 00 00       	push   $0x3cc
f0102982:	68 1d 77 10 f0       	push   $0xf010771d
f0102987:	e8 b4 d6 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010298c:	a1 48 72 21 f0       	mov    0xf0217248,%eax
f0102991:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102994:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102997:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f010299c:	8d b0 00 00 40 21    	lea    0x21400000(%eax),%esi
f01029a2:	89 da                	mov    %ebx,%edx
f01029a4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029a7:	e8 e3 e1 ff ff       	call   f0100b8f <check_va2pa>
f01029ac:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f01029b3:	76 3b                	jbe    f01029f0 <mem_init+0x168e>
f01029b5:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f01029b8:	39 d0                	cmp    %edx,%eax
f01029ba:	75 4b                	jne    f0102a07 <mem_init+0x16a5>
f01029bc:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
f01029c2:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f01029c8:	75 d8                	jne    f01029a2 <mem_init+0x1640>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01029ca:	8b 75 c0             	mov    -0x40(%ebp),%esi
f01029cd:	c1 e6 0c             	shl    $0xc,%esi
f01029d0:	89 fb                	mov    %edi,%ebx
f01029d2:	39 f3                	cmp    %esi,%ebx
f01029d4:	73 63                	jae    f0102a39 <mem_init+0x16d7>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01029d6:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01029dc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029df:	e8 ab e1 ff ff       	call   f0100b8f <check_va2pa>
f01029e4:	39 c3                	cmp    %eax,%ebx
f01029e6:	75 38                	jne    f0102a20 <mem_init+0x16be>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01029e8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01029ee:	eb e2                	jmp    f01029d2 <mem_init+0x1670>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029f0:	ff 75 c8             	pushl  -0x38(%ebp)
f01029f3:	68 08 68 10 f0       	push   $0xf0106808
f01029f8:	68 d1 03 00 00       	push   $0x3d1
f01029fd:	68 1d 77 10 f0       	push   $0xf010771d
f0102a02:	e8 39 d6 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102a07:	68 60 75 10 f0       	push   $0xf0107560
f0102a0c:	68 43 77 10 f0       	push   $0xf0107743
f0102a11:	68 d1 03 00 00       	push   $0x3d1
f0102a16:	68 1d 77 10 f0       	push   $0xf010771d
f0102a1b:	e8 20 d6 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102a20:	68 94 75 10 f0       	push   $0xf0107594
f0102a25:	68 43 77 10 f0       	push   $0xf0107743
f0102a2a:	68 d5 03 00 00       	push   $0x3d5
f0102a2f:	68 1d 77 10 f0       	push   $0xf010771d
f0102a34:	e8 07 d6 ff ff       	call   f0100040 <_panic>
f0102a39:	c7 45 cc 00 90 22 00 	movl   $0x229000,-0x34(%ebp)
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a40:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
f0102a45:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0102a48:	8d bb 00 80 ff ff    	lea    -0x8000(%ebx),%edi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102a4e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102a51:	89 45 bc             	mov    %eax,-0x44(%ebp)
f0102a54:	89 de                	mov    %ebx,%esi
f0102a56:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102a59:	05 00 80 ff 0f       	add    $0xfff8000,%eax
f0102a5e:	89 45 c8             	mov    %eax,-0x38(%ebp)
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102a61:	8d 83 00 80 00 00    	lea    0x8000(%ebx),%eax
f0102a67:	89 45 c4             	mov    %eax,-0x3c(%ebp)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102a6a:	89 f2                	mov    %esi,%edx
f0102a6c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a6f:	e8 1b e1 ff ff       	call   f0100b8f <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102a74:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102a7b:	76 58                	jbe    f0102ad5 <mem_init+0x1773>
f0102a7d:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102a80:	8d 14 31             	lea    (%ecx,%esi,1),%edx
f0102a83:	39 d0                	cmp    %edx,%eax
f0102a85:	75 65                	jne    f0102aec <mem_init+0x178a>
f0102a87:	81 c6 00 10 00 00    	add    $0x1000,%esi
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102a8d:	3b 75 c4             	cmp    -0x3c(%ebp),%esi
f0102a90:	75 d8                	jne    f0102a6a <mem_init+0x1708>
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102a92:	89 fa                	mov    %edi,%edx
f0102a94:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a97:	e8 f3 e0 ff ff       	call   f0100b8f <check_va2pa>
f0102a9c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a9f:	75 64                	jne    f0102b05 <mem_init+0x17a3>
f0102aa1:	81 c7 00 10 00 00    	add    $0x1000,%edi
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102aa7:	39 df                	cmp    %ebx,%edi
f0102aa9:	75 e7                	jne    f0102a92 <mem_init+0x1730>
f0102aab:	81 eb 00 00 01 00    	sub    $0x10000,%ebx
f0102ab1:	81 45 d0 00 80 00 00 	addl   $0x8000,-0x30(%ebp)
f0102ab8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102abb:	81 45 cc 00 80 01 00 	addl   $0x18000,-0x34(%ebp)
	for (n = 0; n < NCPU; n++) {
f0102ac2:	3d 00 90 25 f0       	cmp    $0xf0259000,%eax
f0102ac7:	0f 85 7b ff ff ff    	jne    f0102a48 <mem_init+0x16e6>
f0102acd:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0102ad0:	e9 84 00 00 00       	jmp    f0102b59 <mem_init+0x17f7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ad5:	ff 75 bc             	pushl  -0x44(%ebp)
f0102ad8:	68 08 68 10 f0       	push   $0xf0106808
f0102add:	68 dd 03 00 00       	push   $0x3dd
f0102ae2:	68 1d 77 10 f0       	push   $0xf010771d
f0102ae7:	e8 54 d5 ff ff       	call   f0100040 <_panic>
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102aec:	68 bc 75 10 f0       	push   $0xf01075bc
f0102af1:	68 43 77 10 f0       	push   $0xf0107743
f0102af6:	68 dc 03 00 00       	push   $0x3dc
f0102afb:	68 1d 77 10 f0       	push   $0xf010771d
f0102b00:	e8 3b d5 ff ff       	call   f0100040 <_panic>
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102b05:	68 04 76 10 f0       	push   $0xf0107604
f0102b0a:	68 43 77 10 f0       	push   $0xf0107743
f0102b0f:	68 df 03 00 00       	push   $0x3df
f0102b14:	68 1d 77 10 f0       	push   $0xf010771d
f0102b19:	e8 22 d5 ff ff       	call   f0100040 <_panic>
			assert(pgdir[i] & PTE_P);
f0102b1e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b21:	f6 04 b8 01          	testb  $0x1,(%eax,%edi,4)
f0102b25:	75 4e                	jne    f0102b75 <mem_init+0x1813>
f0102b27:	68 ff 79 10 f0       	push   $0xf01079ff
f0102b2c:	68 43 77 10 f0       	push   $0xf0107743
f0102b31:	68 ea 03 00 00       	push   $0x3ea
f0102b36:	68 1d 77 10 f0       	push   $0xf010771d
f0102b3b:	e8 00 d5 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_P);
f0102b40:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b43:	8b 04 b8             	mov    (%eax,%edi,4),%eax
f0102b46:	a8 01                	test   $0x1,%al
f0102b48:	74 30                	je     f0102b7a <mem_init+0x1818>
				assert(pgdir[i] & PTE_W);
f0102b4a:	a8 02                	test   $0x2,%al
f0102b4c:	74 45                	je     f0102b93 <mem_init+0x1831>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b4e:	83 c7 01             	add    $0x1,%edi
f0102b51:	81 ff 00 04 00 00    	cmp    $0x400,%edi
f0102b57:	74 6c                	je     f0102bc5 <mem_init+0x1863>
		switch (i) {
f0102b59:	8d 87 45 fc ff ff    	lea    -0x3bb(%edi),%eax
f0102b5f:	83 f8 04             	cmp    $0x4,%eax
f0102b62:	76 ba                	jbe    f0102b1e <mem_init+0x17bc>
			if (i >= PDX(KERNBASE)) {
f0102b64:	81 ff bf 03 00 00    	cmp    $0x3bf,%edi
f0102b6a:	77 d4                	ja     f0102b40 <mem_init+0x17de>
				assert(pgdir[i] == 0);
f0102b6c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b6f:	83 3c b8 00          	cmpl   $0x0,(%eax,%edi,4)
f0102b73:	75 37                	jne    f0102bac <mem_init+0x184a>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b75:	83 c7 01             	add    $0x1,%edi
f0102b78:	eb df                	jmp    f0102b59 <mem_init+0x17f7>
				assert(pgdir[i] & PTE_P);
f0102b7a:	68 ff 79 10 f0       	push   $0xf01079ff
f0102b7f:	68 43 77 10 f0       	push   $0xf0107743
f0102b84:	68 ee 03 00 00       	push   $0x3ee
f0102b89:	68 1d 77 10 f0       	push   $0xf010771d
f0102b8e:	e8 ad d4 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102b93:	68 10 7a 10 f0       	push   $0xf0107a10
f0102b98:	68 43 77 10 f0       	push   $0xf0107743
f0102b9d:	68 ef 03 00 00       	push   $0x3ef
f0102ba2:	68 1d 77 10 f0       	push   $0xf010771d
f0102ba7:	e8 94 d4 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] == 0);
f0102bac:	68 21 7a 10 f0       	push   $0xf0107a21
f0102bb1:	68 43 77 10 f0       	push   $0xf0107743
f0102bb6:	68 f1 03 00 00       	push   $0x3f1
f0102bbb:	68 1d 77 10 f0       	push   $0xf010771d
f0102bc0:	e8 7b d4 ff ff       	call   f0100040 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102bc5:	83 ec 0c             	sub    $0xc,%esp
f0102bc8:	68 28 76 10 f0       	push   $0xf0107628
f0102bcd:	e8 da 0d 00 00       	call   f01039ac <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102bd2:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0102bd7:	83 c4 10             	add    $0x10,%esp
f0102bda:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102bdf:	0f 86 03 02 00 00    	jbe    f0102de8 <mem_init+0x1a86>
	return (physaddr_t)kva - KERNBASE;
f0102be5:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102bea:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102bed:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bf2:	e8 fb df ff ff       	call   f0100bf2 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102bf7:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102bfa:	83 e0 f3             	and    $0xfffffff3,%eax
f0102bfd:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102c02:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102c05:	83 ec 0c             	sub    $0xc,%esp
f0102c08:	6a 00                	push   $0x0
f0102c0a:	e8 a0 e3 ff ff       	call   f0100faf <page_alloc>
f0102c0f:	89 c6                	mov    %eax,%esi
f0102c11:	83 c4 10             	add    $0x10,%esp
f0102c14:	85 c0                	test   %eax,%eax
f0102c16:	0f 84 e1 01 00 00    	je     f0102dfd <mem_init+0x1a9b>
	assert((pp1 = page_alloc(0)));
f0102c1c:	83 ec 0c             	sub    $0xc,%esp
f0102c1f:	6a 00                	push   $0x0
f0102c21:	e8 89 e3 ff ff       	call   f0100faf <page_alloc>
f0102c26:	89 c7                	mov    %eax,%edi
f0102c28:	83 c4 10             	add    $0x10,%esp
f0102c2b:	85 c0                	test   %eax,%eax
f0102c2d:	0f 84 e3 01 00 00    	je     f0102e16 <mem_init+0x1ab4>
	assert((pp2 = page_alloc(0)));
f0102c33:	83 ec 0c             	sub    $0xc,%esp
f0102c36:	6a 00                	push   $0x0
f0102c38:	e8 72 e3 ff ff       	call   f0100faf <page_alloc>
f0102c3d:	89 c3                	mov    %eax,%ebx
f0102c3f:	83 c4 10             	add    $0x10,%esp
f0102c42:	85 c0                	test   %eax,%eax
f0102c44:	0f 84 e5 01 00 00    	je     f0102e2f <mem_init+0x1acd>
	page_free(pp0);
f0102c4a:	83 ec 0c             	sub    $0xc,%esp
f0102c4d:	56                   	push   %esi
f0102c4e:	e8 d5 e3 ff ff       	call   f0101028 <page_free>
	return (pp - pages) << PGSHIFT;
f0102c53:	89 f8                	mov    %edi,%eax
f0102c55:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0102c5b:	c1 f8 03             	sar    $0x3,%eax
f0102c5e:	89 c2                	mov    %eax,%edx
f0102c60:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102c63:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102c68:	83 c4 10             	add    $0x10,%esp
f0102c6b:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0102c71:	0f 83 d1 01 00 00    	jae    f0102e48 <mem_init+0x1ae6>
	memset(page2kva(pp1), 1, PGSIZE);
f0102c77:	83 ec 04             	sub    $0x4,%esp
f0102c7a:	68 00 10 00 00       	push   $0x1000
f0102c7f:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102c81:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102c87:	52                   	push   %edx
f0102c88:	e8 a2 2e 00 00       	call   f0105b2f <memset>
	return (pp - pages) << PGSHIFT;
f0102c8d:	89 d8                	mov    %ebx,%eax
f0102c8f:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0102c95:	c1 f8 03             	sar    $0x3,%eax
f0102c98:	89 c2                	mov    %eax,%edx
f0102c9a:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102c9d:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102ca2:	83 c4 10             	add    $0x10,%esp
f0102ca5:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0102cab:	0f 83 a9 01 00 00    	jae    f0102e5a <mem_init+0x1af8>
	memset(page2kva(pp2), 2, PGSIZE);
f0102cb1:	83 ec 04             	sub    $0x4,%esp
f0102cb4:	68 00 10 00 00       	push   $0x1000
f0102cb9:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102cbb:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102cc1:	52                   	push   %edx
f0102cc2:	e8 68 2e 00 00       	call   f0105b2f <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102cc7:	6a 02                	push   $0x2
f0102cc9:	68 00 10 00 00       	push   $0x1000
f0102cce:	57                   	push   %edi
f0102ccf:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0102cd5:	e8 8a e5 ff ff       	call   f0101264 <page_insert>
	assert(pp1->pp_ref == 1);
f0102cda:	83 c4 20             	add    $0x20,%esp
f0102cdd:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102ce2:	0f 85 84 01 00 00    	jne    f0102e6c <mem_init+0x1b0a>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ce8:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102cef:	01 01 01 
f0102cf2:	0f 85 8d 01 00 00    	jne    f0102e85 <mem_init+0x1b23>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102cf8:	6a 02                	push   $0x2
f0102cfa:	68 00 10 00 00       	push   $0x1000
f0102cff:	53                   	push   %ebx
f0102d00:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0102d06:	e8 59 e5 ff ff       	call   f0101264 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102d0b:	83 c4 10             	add    $0x10,%esp
f0102d0e:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102d15:	02 02 02 
f0102d18:	0f 85 80 01 00 00    	jne    f0102e9e <mem_init+0x1b3c>
	assert(pp2->pp_ref == 1);
f0102d1e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102d23:	0f 85 8e 01 00 00    	jne    f0102eb7 <mem_init+0x1b55>
	assert(pp1->pp_ref == 0);
f0102d29:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102d2e:	0f 85 9c 01 00 00    	jne    f0102ed0 <mem_init+0x1b6e>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d34:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d3b:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102d3e:	89 d8                	mov    %ebx,%eax
f0102d40:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0102d46:	c1 f8 03             	sar    $0x3,%eax
f0102d49:	89 c2                	mov    %eax,%edx
f0102d4b:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102d4e:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102d53:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0102d59:	0f 83 8a 01 00 00    	jae    f0102ee9 <mem_init+0x1b87>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d5f:	81 ba 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%edx)
f0102d66:	03 03 03 
f0102d69:	0f 85 8c 01 00 00    	jne    f0102efb <mem_init+0x1b99>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d6f:	83 ec 08             	sub    $0x8,%esp
f0102d72:	68 00 10 00 00       	push   $0x1000
f0102d77:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0102d7d:	e8 91 e4 ff ff       	call   f0101213 <page_remove>
	assert(pp2->pp_ref == 0);
f0102d82:	83 c4 10             	add    $0x10,%esp
f0102d85:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102d8a:	0f 85 84 01 00 00    	jne    f0102f14 <mem_init+0x1bb2>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102d90:	8b 0d 8c 7e 21 f0    	mov    0xf0217e8c,%ecx
f0102d96:	8b 11                	mov    (%ecx),%edx
f0102d98:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102d9e:	89 f0                	mov    %esi,%eax
f0102da0:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0102da6:	c1 f8 03             	sar    $0x3,%eax
f0102da9:	c1 e0 0c             	shl    $0xc,%eax
f0102dac:	39 c2                	cmp    %eax,%edx
f0102dae:	0f 85 79 01 00 00    	jne    f0102f2d <mem_init+0x1bcb>
	kern_pgdir[0] = 0;
f0102db4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102dba:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102dbf:	0f 85 81 01 00 00    	jne    f0102f46 <mem_init+0x1be4>
	pp0->pp_ref = 0;
f0102dc5:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102dcb:	83 ec 0c             	sub    $0xc,%esp
f0102dce:	56                   	push   %esi
f0102dcf:	e8 54 e2 ff ff       	call   f0101028 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102dd4:	c7 04 24 bc 76 10 f0 	movl   $0xf01076bc,(%esp)
f0102ddb:	e8 cc 0b 00 00       	call   f01039ac <cprintf>
}
f0102de0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102de3:	5b                   	pop    %ebx
f0102de4:	5e                   	pop    %esi
f0102de5:	5f                   	pop    %edi
f0102de6:	5d                   	pop    %ebp
f0102de7:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102de8:	50                   	push   %eax
f0102de9:	68 08 68 10 f0       	push   $0xf0106808
f0102dee:	68 f9 00 00 00       	push   $0xf9
f0102df3:	68 1d 77 10 f0       	push   $0xf010771d
f0102df8:	e8 43 d2 ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f0102dfd:	68 0b 78 10 f0       	push   $0xf010780b
f0102e02:	68 43 77 10 f0       	push   $0xf0107743
f0102e07:	68 c9 04 00 00       	push   $0x4c9
f0102e0c:	68 1d 77 10 f0       	push   $0xf010771d
f0102e11:	e8 2a d2 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102e16:	68 21 78 10 f0       	push   $0xf0107821
f0102e1b:	68 43 77 10 f0       	push   $0xf0107743
f0102e20:	68 ca 04 00 00       	push   $0x4ca
f0102e25:	68 1d 77 10 f0       	push   $0xf010771d
f0102e2a:	e8 11 d2 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102e2f:	68 37 78 10 f0       	push   $0xf0107837
f0102e34:	68 43 77 10 f0       	push   $0xf0107743
f0102e39:	68 cb 04 00 00       	push   $0x4cb
f0102e3e:	68 1d 77 10 f0       	push   $0xf010771d
f0102e43:	e8 f8 d1 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e48:	52                   	push   %edx
f0102e49:	68 e4 67 10 f0       	push   $0xf01067e4
f0102e4e:	6a 58                	push   $0x58
f0102e50:	68 29 77 10 f0       	push   $0xf0107729
f0102e55:	e8 e6 d1 ff ff       	call   f0100040 <_panic>
f0102e5a:	52                   	push   %edx
f0102e5b:	68 e4 67 10 f0       	push   $0xf01067e4
f0102e60:	6a 58                	push   $0x58
f0102e62:	68 29 77 10 f0       	push   $0xf0107729
f0102e67:	e8 d4 d1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102e6c:	68 08 79 10 f0       	push   $0xf0107908
f0102e71:	68 43 77 10 f0       	push   $0xf0107743
f0102e76:	68 d0 04 00 00       	push   $0x4d0
f0102e7b:	68 1d 77 10 f0       	push   $0xf010771d
f0102e80:	e8 bb d1 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102e85:	68 48 76 10 f0       	push   $0xf0107648
f0102e8a:	68 43 77 10 f0       	push   $0xf0107743
f0102e8f:	68 d1 04 00 00       	push   $0x4d1
f0102e94:	68 1d 77 10 f0       	push   $0xf010771d
f0102e99:	e8 a2 d1 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102e9e:	68 6c 76 10 f0       	push   $0xf010766c
f0102ea3:	68 43 77 10 f0       	push   $0xf0107743
f0102ea8:	68 d3 04 00 00       	push   $0x4d3
f0102ead:	68 1d 77 10 f0       	push   $0xf010771d
f0102eb2:	e8 89 d1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102eb7:	68 2a 79 10 f0       	push   $0xf010792a
f0102ebc:	68 43 77 10 f0       	push   $0xf0107743
f0102ec1:	68 d4 04 00 00       	push   $0x4d4
f0102ec6:	68 1d 77 10 f0       	push   $0xf010771d
f0102ecb:	e8 70 d1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102ed0:	68 94 79 10 f0       	push   $0xf0107994
f0102ed5:	68 43 77 10 f0       	push   $0xf0107743
f0102eda:	68 d5 04 00 00       	push   $0x4d5
f0102edf:	68 1d 77 10 f0       	push   $0xf010771d
f0102ee4:	e8 57 d1 ff ff       	call   f0100040 <_panic>
f0102ee9:	52                   	push   %edx
f0102eea:	68 e4 67 10 f0       	push   $0xf01067e4
f0102eef:	6a 58                	push   $0x58
f0102ef1:	68 29 77 10 f0       	push   $0xf0107729
f0102ef6:	e8 45 d1 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102efb:	68 90 76 10 f0       	push   $0xf0107690
f0102f00:	68 43 77 10 f0       	push   $0xf0107743
f0102f05:	68 d7 04 00 00       	push   $0x4d7
f0102f0a:	68 1d 77 10 f0       	push   $0xf010771d
f0102f0f:	e8 2c d1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102f14:	68 62 79 10 f0       	push   $0xf0107962
f0102f19:	68 43 77 10 f0       	push   $0xf0107743
f0102f1e:	68 d9 04 00 00       	push   $0x4d9
f0102f23:	68 1d 77 10 f0       	push   $0xf010771d
f0102f28:	e8 13 d1 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102f2d:	68 18 70 10 f0       	push   $0xf0107018
f0102f32:	68 43 77 10 f0       	push   $0xf0107743
f0102f37:	68 dc 04 00 00       	push   $0x4dc
f0102f3c:	68 1d 77 10 f0       	push   $0xf010771d
f0102f41:	e8 fa d0 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0102f46:	68 19 79 10 f0       	push   $0xf0107919
f0102f4b:	68 43 77 10 f0       	push   $0xf0107743
f0102f50:	68 de 04 00 00       	push   $0x4de
f0102f55:	68 1d 77 10 f0       	push   $0xf010771d
f0102f5a:	e8 e1 d0 ff ff       	call   f0100040 <_panic>

f0102f5f <user_mem_check>:
{
f0102f5f:	f3 0f 1e fb          	endbr32 
f0102f63:	55                   	push   %ebp
f0102f64:	89 e5                	mov    %esp,%ebp
f0102f66:	57                   	push   %edi
f0102f67:	56                   	push   %esi
f0102f68:	53                   	push   %ebx
f0102f69:	83 ec 2c             	sub    $0x2c,%esp
	pde_t* pgdir = env->env_pgdir;
f0102f6c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f6f:	8b 78 60             	mov    0x60(%eax),%edi
	uintptr_t address = (uintptr_t)va;
f0102f72:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f75:	89 45 cc             	mov    %eax,-0x34(%ebp)
	perm = perm | PTE_U | PTE_P;
f0102f78:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f7b:	83 c8 05             	or     $0x5,%eax
f0102f7e:	89 45 d0             	mov    %eax,-0x30(%ebp)
	pte_t* entry = NULL;
f0102f81:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	uintptr_t address = (uintptr_t)va;
f0102f88:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	for(; address<(uintptr_t)(va+len);address+=PGSIZE)
f0102f8b:	89 d8                	mov    %ebx,%eax
f0102f8d:	03 45 10             	add    0x10(%ebp),%eax
f0102f90:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		if(page_lookup(pgdir,(void*)address,&entry) == NULL)
f0102f93:	8d 75 e4             	lea    -0x1c(%ebp),%esi
	for(; address<(uintptr_t)(va+len);address+=PGSIZE)
f0102f96:	eb 06                	jmp    f0102f9e <user_mem_check+0x3f>
f0102f98:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102f9e:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102fa1:	76 3e                	jbe    f0102fe1 <user_mem_check+0x82>
		if(address>=ULIM)
f0102fa3:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102fa9:	77 1c                	ja     f0102fc7 <user_mem_check+0x68>
		if(page_lookup(pgdir,(void*)address,&entry) == NULL)
f0102fab:	83 ec 04             	sub    $0x4,%esp
f0102fae:	56                   	push   %esi
f0102faf:	53                   	push   %ebx
f0102fb0:	57                   	push   %edi
f0102fb1:	e8 bb e1 ff ff       	call   f0101171 <page_lookup>
f0102fb6:	83 c4 10             	add    $0x10,%esp
f0102fb9:	85 c0                	test   %eax,%eax
f0102fbb:	74 0a                	je     f0102fc7 <user_mem_check+0x68>
		if(!(*entry & perm))
f0102fbd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102fc0:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0102fc3:	85 10                	test   %edx,(%eax)
f0102fc5:	75 d1                	jne    f0102f98 <user_mem_check+0x39>
		user_mem_check_addr = (address == (uintptr_t)va ? address : ROUNDDOWN(address,PGSIZE));
f0102fc7:	89 d8                	mov    %ebx,%eax
f0102fc9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102fce:	39 5d 0c             	cmp    %ebx,0xc(%ebp)
f0102fd1:	0f 44 45 cc          	cmove  -0x34(%ebp),%eax
f0102fd5:	a3 3c 72 21 f0       	mov    %eax,0xf021723c
		return -E_FAULT;
f0102fda:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102fdf:	eb 05                	jmp    f0102fe6 <user_mem_check+0x87>
	return 0;
f0102fe1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102fe6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102fe9:	5b                   	pop    %ebx
f0102fea:	5e                   	pop    %esi
f0102feb:	5f                   	pop    %edi
f0102fec:	5d                   	pop    %ebp
f0102fed:	c3                   	ret    

f0102fee <user_mem_assert>:
{
f0102fee:	f3 0f 1e fb          	endbr32 
f0102ff2:	55                   	push   %ebp
f0102ff3:	89 e5                	mov    %esp,%ebp
f0102ff5:	53                   	push   %ebx
f0102ff6:	83 ec 04             	sub    $0x4,%esp
f0102ff9:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102ffc:	8b 45 14             	mov    0x14(%ebp),%eax
f0102fff:	83 c8 04             	or     $0x4,%eax
f0103002:	50                   	push   %eax
f0103003:	ff 75 10             	pushl  0x10(%ebp)
f0103006:	ff 75 0c             	pushl  0xc(%ebp)
f0103009:	53                   	push   %ebx
f010300a:	e8 50 ff ff ff       	call   f0102f5f <user_mem_check>
f010300f:	83 c4 10             	add    $0x10,%esp
f0103012:	85 c0                	test   %eax,%eax
f0103014:	78 05                	js     f010301b <user_mem_assert+0x2d>
}
f0103016:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103019:	c9                   	leave  
f010301a:	c3                   	ret    
		cprintf("[%08x] user_mem_check assertion failure for "
f010301b:	83 ec 04             	sub    $0x4,%esp
f010301e:	ff 35 3c 72 21 f0    	pushl  0xf021723c
f0103024:	ff 73 48             	pushl  0x48(%ebx)
f0103027:	68 e8 76 10 f0       	push   $0xf01076e8
f010302c:	e8 7b 09 00 00       	call   f01039ac <cprintf>
		env_destroy(env);	// may not return
f0103031:	89 1c 24             	mov    %ebx,(%esp)
f0103034:	e8 4e 06 00 00       	call   f0103687 <env_destroy>
f0103039:	83 c4 10             	add    $0x10,%esp
}
f010303c:	eb d8                	jmp    f0103016 <user_mem_assert+0x28>

f010303e <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f010303e:	55                   	push   %ebp
f010303f:	89 e5                	mov    %esp,%ebp
f0103041:	57                   	push   %edi
f0103042:	56                   	push   %esi
f0103043:	53                   	push   %ebx
f0103044:	83 ec 0c             	sub    $0xc,%esp
f0103047:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void* start = (void*)ROUNDDOWN((uint32_t)va,PGSIZE);
f0103049:	89 d3                	mov    %edx,%ebx
f010304b:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void* end = (void*)ROUNDUP((uint32_t)va+len,PGSIZE);
f0103051:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0103058:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

	// corner case 1: too large length
	if(start>end)
f010305e:	39 f3                	cmp    %esi,%ebx
f0103060:	77 30                	ja     f0103092 <region_alloc+0x54>
		panic("At region_alloc: too large length\n");
	}
	struct PageInfo* p = NULL;

	// allocate PA by the size of a page
	for(void* v = start;v<end;v+=PGSIZE)
f0103062:	39 f3                	cmp    %esi,%ebx
f0103064:	73 71                	jae    f01030d7 <region_alloc+0x99>
	{
		p = page_alloc(0);
f0103066:	83 ec 0c             	sub    $0xc,%esp
f0103069:	6a 00                	push   $0x0
f010306b:	e8 3f df ff ff       	call   f0100faf <page_alloc>
		// corner case 2: page allocation failed
		if(p == NULL)
f0103070:	83 c4 10             	add    $0x10,%esp
f0103073:	85 c0                	test   %eax,%eax
f0103075:	74 32                	je     f01030a9 <region_alloc+0x6b>
		{
			panic("At region_alloc: Page allocation failed");
		}

		// insert into page table
		int insert = page_insert(e->env_pgdir,p,v,PTE_W|PTE_U);
f0103077:	6a 06                	push   $0x6
f0103079:	53                   	push   %ebx
f010307a:	50                   	push   %eax
f010307b:	ff 77 60             	pushl  0x60(%edi)
f010307e:	e8 e1 e1 ff ff       	call   f0101264 <page_insert>

		// corner case 3: insertion failed
		if(insert!=0)
f0103083:	83 c4 10             	add    $0x10,%esp
f0103086:	85 c0                	test   %eax,%eax
f0103088:	75 36                	jne    f01030c0 <region_alloc+0x82>
	for(void* v = start;v<end;v+=PGSIZE)
f010308a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0103090:	eb d0                	jmp    f0103062 <region_alloc+0x24>
		panic("At region_alloc: too large length\n");
f0103092:	83 ec 04             	sub    $0x4,%esp
f0103095:	68 30 7a 10 f0       	push   $0xf0107a30
f010309a:	68 37 01 00 00       	push   $0x137
f010309f:	68 25 7b 10 f0       	push   $0xf0107b25
f01030a4:	e8 97 cf ff ff       	call   f0100040 <_panic>
			panic("At region_alloc: Page allocation failed");
f01030a9:	83 ec 04             	sub    $0x4,%esp
f01030ac:	68 54 7a 10 f0       	push   $0xf0107a54
f01030b1:	68 42 01 00 00       	push   $0x142
f01030b6:	68 25 7b 10 f0       	push   $0xf0107b25
f01030bb:	e8 80 cf ff ff       	call   f0100040 <_panic>
		{
			panic("At region_alloc: Page insertion failed");
f01030c0:	83 ec 04             	sub    $0x4,%esp
f01030c3:	68 7c 7a 10 f0       	push   $0xf0107a7c
f01030c8:	68 4b 01 00 00       	push   $0x14b
f01030cd:	68 25 7b 10 f0       	push   $0xf0107b25
f01030d2:	e8 69 cf ff ff       	call   f0100040 <_panic>
		}
	}
}
f01030d7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030da:	5b                   	pop    %ebx
f01030db:	5e                   	pop    %esi
f01030dc:	5f                   	pop    %edi
f01030dd:	5d                   	pop    %ebp
f01030de:	c3                   	ret    

f01030df <envid2env>:
{
f01030df:	f3 0f 1e fb          	endbr32 
f01030e3:	55                   	push   %ebp
f01030e4:	89 e5                	mov    %esp,%ebp
f01030e6:	56                   	push   %esi
f01030e7:	53                   	push   %ebx
f01030e8:	8b 75 08             	mov    0x8(%ebp),%esi
f01030eb:	8b 45 10             	mov    0x10(%ebp),%eax
	if (envid == 0) {
f01030ee:	85 f6                	test   %esi,%esi
f01030f0:	74 2e                	je     f0103120 <envid2env+0x41>
	e = &envs[ENVX(envid)];
f01030f2:	89 f3                	mov    %esi,%ebx
f01030f4:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f01030fa:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f01030fd:	03 1d 48 72 21 f0    	add    0xf0217248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103103:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0103107:	74 2e                	je     f0103137 <envid2env+0x58>
f0103109:	39 73 48             	cmp    %esi,0x48(%ebx)
f010310c:	75 29                	jne    f0103137 <envid2env+0x58>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010310e:	84 c0                	test   %al,%al
f0103110:	75 35                	jne    f0103147 <envid2env+0x68>
	*env_store = e;
f0103112:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103115:	89 18                	mov    %ebx,(%eax)
	return 0;
f0103117:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010311c:	5b                   	pop    %ebx
f010311d:	5e                   	pop    %esi
f010311e:	5d                   	pop    %ebp
f010311f:	c3                   	ret    
		*env_store = curenv;
f0103120:	e8 29 30 00 00       	call   f010614e <cpunum>
f0103125:	6b c0 74             	imul   $0x74,%eax,%eax
f0103128:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f010312e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103131:	89 02                	mov    %eax,(%edx)
		return 0;
f0103133:	89 f0                	mov    %esi,%eax
f0103135:	eb e5                	jmp    f010311c <envid2env+0x3d>
		*env_store = 0;
f0103137:	8b 45 0c             	mov    0xc(%ebp),%eax
f010313a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103140:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103145:	eb d5                	jmp    f010311c <envid2env+0x3d>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103147:	e8 02 30 00 00       	call   f010614e <cpunum>
f010314c:	6b c0 74             	imul   $0x74,%eax,%eax
f010314f:	39 98 28 80 21 f0    	cmp    %ebx,-0xfde7fd8(%eax)
f0103155:	74 bb                	je     f0103112 <envid2env+0x33>
f0103157:	8b 73 4c             	mov    0x4c(%ebx),%esi
f010315a:	e8 ef 2f 00 00       	call   f010614e <cpunum>
f010315f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103162:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0103168:	3b 70 48             	cmp    0x48(%eax),%esi
f010316b:	74 a5                	je     f0103112 <envid2env+0x33>
		*env_store = 0;
f010316d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103170:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103176:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010317b:	eb 9f                	jmp    f010311c <envid2env+0x3d>

f010317d <env_init_percpu>:
{
f010317d:	f3 0f 1e fb          	endbr32 
	asm volatile("lgdt (%0)" : : "r" (p));
f0103181:	b8 20 33 12 f0       	mov    $0xf0123320,%eax
f0103186:	0f 01 10             	lgdtl  (%eax)
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0103189:	b8 23 00 00 00       	mov    $0x23,%eax
f010318e:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0103190:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0103192:	b8 10 00 00 00       	mov    $0x10,%eax
f0103197:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0103199:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f010319b:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f010319d:	ea a4 31 10 f0 08 00 	ljmp   $0x8,$0xf01031a4
	asm volatile("lldt %0" : : "r" (sel));
f01031a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01031a9:	0f 00 d0             	lldt   %ax
}
f01031ac:	c3                   	ret    

f01031ad <env_init>:
{
f01031ad:	f3 0f 1e fb          	endbr32 
f01031b1:	55                   	push   %ebp
f01031b2:	89 e5                	mov    %esp,%ebp
f01031b4:	56                   	push   %esi
f01031b5:	53                   	push   %ebx
		envs[i].env_id = 0;
f01031b6:	8b 35 48 72 21 f0    	mov    0xf0217248,%esi
f01031bc:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f01031c2:	89 f3                	mov    %esi,%ebx
f01031c4:	ba 00 00 00 00       	mov    $0x0,%edx
f01031c9:	89 d1                	mov    %edx,%ecx
f01031cb:	89 c2                	mov    %eax,%edx
f01031cd:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f01031d4:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f01031db:	89 48 44             	mov    %ecx,0x44(%eax)
f01031de:	83 e8 7c             	sub    $0x7c,%eax
	for(int i = NENV - 1; i>=0 ;i--)
f01031e1:	39 da                	cmp    %ebx,%edx
f01031e3:	75 e4                	jne    f01031c9 <env_init+0x1c>
f01031e5:	89 35 4c 72 21 f0    	mov    %esi,0xf021724c
	env_init_percpu();
f01031eb:	e8 8d ff ff ff       	call   f010317d <env_init_percpu>
}
f01031f0:	5b                   	pop    %ebx
f01031f1:	5e                   	pop    %esi
f01031f2:	5d                   	pop    %ebp
f01031f3:	c3                   	ret    

f01031f4 <env_alloc>:
{
f01031f4:	f3 0f 1e fb          	endbr32 
f01031f8:	55                   	push   %ebp
f01031f9:	89 e5                	mov    %esp,%ebp
f01031fb:	53                   	push   %ebx
f01031fc:	83 ec 04             	sub    $0x4,%esp
	if (!(e = env_free_list))
f01031ff:	8b 1d 4c 72 21 f0    	mov    0xf021724c,%ebx
f0103205:	85 db                	test   %ebx,%ebx
f0103207:	0f 84 59 01 00 00    	je     f0103366 <env_alloc+0x172>
	if (!(p = page_alloc(ALLOC_ZERO)))
f010320d:	83 ec 0c             	sub    $0xc,%esp
f0103210:	6a 01                	push   $0x1
f0103212:	e8 98 dd ff ff       	call   f0100faf <page_alloc>
f0103217:	83 c4 10             	add    $0x10,%esp
f010321a:	85 c0                	test   %eax,%eax
f010321c:	0f 84 4b 01 00 00    	je     f010336d <env_alloc+0x179>
	return (pp - pages) << PGSHIFT;
f0103222:	89 c2                	mov    %eax,%edx
f0103224:	2b 15 90 7e 21 f0    	sub    0xf0217e90,%edx
f010322a:	c1 fa 03             	sar    $0x3,%edx
f010322d:	89 d1                	mov    %edx,%ecx
f010322f:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f0103232:	81 e2 ff ff 0f 00    	and    $0xfffff,%edx
f0103238:	3b 15 88 7e 21 f0    	cmp    0xf0217e88,%edx
f010323e:	0f 83 fb 00 00 00    	jae    f010333f <env_alloc+0x14b>
	return (void *)(pa + KERNBASE);
f0103244:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f010324a:	89 4b 60             	mov    %ecx,0x60(%ebx)
	p->pp_ref++;
f010324d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f0103252:	b8 00 00 00 00       	mov    $0x0,%eax
		e->env_pgdir[i] = 0;
f0103257:	8b 53 60             	mov    0x60(%ebx),%edx
f010325a:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f0103261:	83 c0 04             	add    $0x4,%eax
	for(int i = 0;i<PDX(UTOP);i++)
f0103264:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f0103269:	75 ec                	jne    f0103257 <env_alloc+0x63>
		e->env_pgdir[i] = kern_pgdir[i];
f010326b:	8b 15 8c 7e 21 f0    	mov    0xf0217e8c,%edx
f0103271:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0103274:	8b 53 60             	mov    0x60(%ebx),%edx
f0103277:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f010327a:	83 c0 04             	add    $0x4,%eax
	for(int i = PDX(UTOP);i<NPDENTRIES;i++)
f010327d:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0103282:	75 e7                	jne    f010326b <env_alloc+0x77>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103284:	8b 43 60             	mov    0x60(%ebx),%eax
	if ((uint32_t)kva < KERNBASE)
f0103287:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010328c:	0f 86 bf 00 00 00    	jbe    f0103351 <env_alloc+0x15d>
	return (physaddr_t)kva - KERNBASE;
f0103292:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103298:	83 ca 05             	or     $0x5,%edx
f010329b:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01032a1:	8b 43 48             	mov    0x48(%ebx),%eax
f01032a4:	05 00 10 00 00       	add    $0x1000,%eax
		generation = 1 << ENVGENSHIFT;
f01032a9:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01032ae:	ba 00 10 00 00       	mov    $0x1000,%edx
f01032b3:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01032b6:	89 da                	mov    %ebx,%edx
f01032b8:	2b 15 48 72 21 f0    	sub    0xf0217248,%edx
f01032be:	c1 fa 02             	sar    $0x2,%edx
f01032c1:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f01032c7:	09 d0                	or     %edx,%eax
f01032c9:	89 43 48             	mov    %eax,0x48(%ebx)
	e->env_parent_id = parent_id;
f01032cc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032cf:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01032d2:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01032d9:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01032e0:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01032e7:	83 ec 04             	sub    $0x4,%esp
f01032ea:	6a 44                	push   $0x44
f01032ec:	6a 00                	push   $0x0
f01032ee:	53                   	push   %ebx
f01032ef:	e8 3b 28 00 00       	call   f0105b2f <memset>
	e->env_tf.tf_ds = GD_UD | 3;
f01032f4:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01032fa:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103300:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103306:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f010330d:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	e->env_tf.tf_eflags |= FL_IF;
f0103313:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)
	e->env_pgfault_upcall = 0;
f010331a:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)
	e->env_ipc_recving = 0;
f0103321:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
	env_free_list = e->env_link;
f0103325:	8b 43 44             	mov    0x44(%ebx),%eax
f0103328:	a3 4c 72 21 f0       	mov    %eax,0xf021724c
	*newenv_store = e;
f010332d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103330:	89 18                	mov    %ebx,(%eax)
	return 0;
f0103332:	83 c4 10             	add    $0x10,%esp
f0103335:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010333a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010333d:	c9                   	leave  
f010333e:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010333f:	51                   	push   %ecx
f0103340:	68 e4 67 10 f0       	push   $0xf01067e4
f0103345:	6a 58                	push   $0x58
f0103347:	68 29 77 10 f0       	push   $0xf0107729
f010334c:	e8 ef cc ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103351:	50                   	push   %eax
f0103352:	68 08 68 10 f0       	push   $0xf0106808
f0103357:	68 d3 00 00 00       	push   $0xd3
f010335c:	68 25 7b 10 f0       	push   $0xf0107b25
f0103361:	e8 da cc ff ff       	call   f0100040 <_panic>
		return -E_NO_FREE_ENV;
f0103366:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010336b:	eb cd                	jmp    f010333a <env_alloc+0x146>
		return -E_NO_MEM;
f010336d:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0103372:	eb c6                	jmp    f010333a <env_alloc+0x146>

f0103374 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103374:	f3 0f 1e fb          	endbr32 
f0103378:	55                   	push   %ebp
f0103379:	89 e5                	mov    %esp,%ebp
f010337b:	57                   	push   %edi
f010337c:	56                   	push   %esi
f010337d:	53                   	push   %ebx
f010337e:	83 ec 34             	sub    $0x34,%esp
f0103381:	8b 75 08             	mov    0x8(%ebp),%esi
	// LAB 3: Your code here.
	struct Env* e;
	int alloc = env_alloc(&e,0);
f0103384:	6a 00                	push   $0x0
f0103386:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103389:	50                   	push   %eax
f010338a:	e8 65 fe ff ff       	call   f01031f4 <env_alloc>
	if(alloc != 0)
f010338f:	83 c4 10             	add    $0x10,%esp
f0103392:	85 c0                	test   %eax,%eax
f0103394:	75 30                	jne    f01033c6 <env_create+0x52>
	{
		panic("At env_create: env_alloc() failed");
	}
	load_icode(e,binary);
f0103396:	8b 7d e4             	mov    -0x1c(%ebp),%edi
	if(elfHeader->e_magic != ELF_MAGIC)
f0103399:	81 3e 7f 45 4c 46    	cmpl   $0x464c457f,(%esi)
f010339f:	75 3c                	jne    f01033dd <env_create+0x69>
	lcr3(PADDR(e->env_pgdir));
f01033a1:	8b 47 60             	mov    0x60(%edi),%eax
	if ((uint32_t)kva < KERNBASE)
f01033a4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033a9:	76 49                	jbe    f01033f4 <env_create+0x80>
	return (physaddr_t)kva - KERNBASE;
f01033ab:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01033b0:	0f 22 d8             	mov    %eax,%cr3
	struct Proghdr* ph = (struct Proghdr*)(binary+elfHeader->e_phoff);
f01033b3:	89 f3                	mov    %esi,%ebx
f01033b5:	03 5e 1c             	add    0x1c(%esi),%ebx
	struct Proghdr* phEnd = ph+elfHeader->e_phnum;
f01033b8:	0f b7 46 2c          	movzwl 0x2c(%esi),%eax
f01033bc:	c1 e0 05             	shl    $0x5,%eax
f01033bf:	01 d8                	add    %ebx,%eax
f01033c1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for(;ph<phEnd;ph++)
f01033c4:	eb 5d                	jmp    f0103423 <env_create+0xaf>
		panic("At env_create: env_alloc() failed");
f01033c6:	83 ec 04             	sub    $0x4,%esp
f01033c9:	68 a4 7a 10 f0       	push   $0xf0107aa4
f01033ce:	68 c4 01 00 00       	push   $0x1c4
f01033d3:	68 25 7b 10 f0       	push   $0xf0107b25
f01033d8:	e8 63 cc ff ff       	call   f0100040 <_panic>
		panic("At load_icode: Invalid head magic number");
f01033dd:	83 ec 04             	sub    $0x4,%esp
f01033e0:	68 c8 7a 10 f0       	push   $0xf0107ac8
f01033e5:	68 8c 01 00 00       	push   $0x18c
f01033ea:	68 25 7b 10 f0       	push   $0xf0107b25
f01033ef:	e8 4c cc ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033f4:	50                   	push   %eax
f01033f5:	68 08 68 10 f0       	push   $0xf0106808
f01033fa:	68 8f 01 00 00       	push   $0x18f
f01033ff:	68 25 7b 10 f0       	push   $0xf0107b25
f0103404:	e8 37 cc ff ff       	call   f0100040 <_panic>
				panic("At load_icode: file size bigger than memory size");
f0103409:	83 ec 04             	sub    $0x4,%esp
f010340c:	68 f4 7a 10 f0       	push   $0xf0107af4
f0103411:	68 9b 01 00 00       	push   $0x19b
f0103416:	68 25 7b 10 f0       	push   $0xf0107b25
f010341b:	e8 20 cc ff ff       	call   f0100040 <_panic>
	for(;ph<phEnd;ph++)
f0103420:	83 c3 20             	add    $0x20,%ebx
f0103423:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0103426:	76 47                	jbe    f010346f <env_create+0xfb>
		if(ph->p_type == ELF_PROG_LOAD)
f0103428:	83 3b 01             	cmpl   $0x1,(%ebx)
f010342b:	75 f3                	jne    f0103420 <env_create+0xac>
			if(ph->p_filesz>ph->p_memsz)
f010342d:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103430:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f0103433:	77 d4                	ja     f0103409 <env_create+0x95>
			region_alloc(e,(void*) ph->p_va,ph->p_memsz);
f0103435:	8b 53 08             	mov    0x8(%ebx),%edx
f0103438:	89 f8                	mov    %edi,%eax
f010343a:	e8 ff fb ff ff       	call   f010303e <region_alloc>
			memcpy((void*)ph->p_va,binary+ph->p_offset,ph->p_filesz);
f010343f:	83 ec 04             	sub    $0x4,%esp
f0103442:	ff 73 10             	pushl  0x10(%ebx)
f0103445:	89 f0                	mov    %esi,%eax
f0103447:	03 43 04             	add    0x4(%ebx),%eax
f010344a:	50                   	push   %eax
f010344b:	ff 73 08             	pushl  0x8(%ebx)
f010344e:	e8 8e 27 00 00       	call   f0105be1 <memcpy>
			memset((void*)(ph->p_va+ph->p_filesz),0,ph->p_memsz-ph->p_filesz);
f0103453:	8b 43 10             	mov    0x10(%ebx),%eax
f0103456:	83 c4 0c             	add    $0xc,%esp
f0103459:	8b 53 14             	mov    0x14(%ebx),%edx
f010345c:	29 c2                	sub    %eax,%edx
f010345e:	52                   	push   %edx
f010345f:	6a 00                	push   $0x0
f0103461:	03 43 08             	add    0x8(%ebx),%eax
f0103464:	50                   	push   %eax
f0103465:	e8 c5 26 00 00       	call   f0105b2f <memset>
f010346a:	83 c4 10             	add    $0x10,%esp
f010346d:	eb b1                	jmp    f0103420 <env_create+0xac>
	lcr3(PADDR(kern_pgdir));
f010346f:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0103474:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103479:	76 3d                	jbe    f01034b8 <env_create+0x144>
	return (physaddr_t)kva - KERNBASE;
f010347b:	05 00 00 00 10       	add    $0x10000000,%eax
f0103480:	0f 22 d8             	mov    %eax,%cr3
	e->env_status = ENV_RUNNABLE;
f0103483:	c7 47 54 02 00 00 00 	movl   $0x2,0x54(%edi)
	e->env_tf.tf_eip = elfHeader->e_entry;
f010348a:	8b 46 18             	mov    0x18(%esi),%eax
f010348d:	89 47 30             	mov    %eax,0x30(%edi)
	region_alloc(e,(void*)(USTACKTOP-PGSIZE),PGSIZE);
f0103490:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103495:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f010349a:	89 f8                	mov    %edi,%eax
f010349c:	e8 9d fb ff ff       	call   f010303e <region_alloc>
	
	// If this is the file server (type == ENV_TYPE_FS) give it I/O privileges.
	// LAB 5: Your code here.
	if(type == ENV_TYPE_FS)
f01034a1:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f01034a5:	74 26                	je     f01034cd <env_create+0x159>
	{
		e->env_tf.tf_eflags |= FL_IOPL_MASK;
	}
	e->env_type = type;
f01034a7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01034aa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01034ad:	89 48 50             	mov    %ecx,0x50(%eax)
}
f01034b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01034b3:	5b                   	pop    %ebx
f01034b4:	5e                   	pop    %esi
f01034b5:	5f                   	pop    %edi
f01034b6:	5d                   	pop    %ebp
f01034b7:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034b8:	50                   	push   %eax
f01034b9:	68 08 68 10 f0       	push   $0xf0106808
f01034be:	68 a8 01 00 00       	push   $0x1a8
f01034c3:	68 25 7b 10 f0       	push   $0xf0107b25
f01034c8:	e8 73 cb ff ff       	call   f0100040 <_panic>
		e->env_tf.tf_eflags |= FL_IOPL_MASK;
f01034cd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01034d0:	81 48 38 00 30 00 00 	orl    $0x3000,0x38(%eax)
f01034d7:	eb ce                	jmp    f01034a7 <env_create+0x133>

f01034d9 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01034d9:	f3 0f 1e fb          	endbr32 
f01034dd:	55                   	push   %ebp
f01034de:	89 e5                	mov    %esp,%ebp
f01034e0:	57                   	push   %edi
f01034e1:	56                   	push   %esi
f01034e2:	53                   	push   %ebx
f01034e3:	83 ec 1c             	sub    $0x1c,%esp
f01034e6:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01034e9:	e8 60 2c 00 00       	call   f010614e <cpunum>
f01034ee:	6b c0 74             	imul   $0x74,%eax,%eax
f01034f1:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01034f8:	39 b8 28 80 21 f0    	cmp    %edi,-0xfde7fd8(%eax)
f01034fe:	0f 85 b3 00 00 00    	jne    f01035b7 <env_free+0xde>
		lcr3(PADDR(kern_pgdir));
f0103504:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0103509:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010350e:	76 14                	jbe    f0103524 <env_free+0x4b>
	return (physaddr_t)kva - KERNBASE;
f0103510:	05 00 00 00 10       	add    $0x10000000,%eax
f0103515:	0f 22 d8             	mov    %eax,%cr3
}
f0103518:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010351f:	e9 93 00 00 00       	jmp    f01035b7 <env_free+0xde>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103524:	50                   	push   %eax
f0103525:	68 08 68 10 f0       	push   $0xf0106808
f010352a:	68 df 01 00 00       	push   $0x1df
f010352f:	68 25 7b 10 f0       	push   $0xf0107b25
f0103534:	e8 07 cb ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103539:	56                   	push   %esi
f010353a:	68 e4 67 10 f0       	push   $0xf01067e4
f010353f:	68 ee 01 00 00       	push   $0x1ee
f0103544:	68 25 7b 10 f0       	push   $0xf0107b25
f0103549:	e8 f2 ca ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010354e:	83 ec 08             	sub    $0x8,%esp
f0103551:	89 d8                	mov    %ebx,%eax
f0103553:	c1 e0 0c             	shl    $0xc,%eax
f0103556:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103559:	50                   	push   %eax
f010355a:	ff 77 60             	pushl  0x60(%edi)
f010355d:	e8 b1 dc ff ff       	call   f0101213 <page_remove>
f0103562:	83 c4 10             	add    $0x10,%esp
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103565:	83 c3 01             	add    $0x1,%ebx
f0103568:	83 c6 04             	add    $0x4,%esi
f010356b:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103571:	74 07                	je     f010357a <env_free+0xa1>
			if (pt[pteno] & PTE_P)
f0103573:	f6 06 01             	testb  $0x1,(%esi)
f0103576:	74 ed                	je     f0103565 <env_free+0x8c>
f0103578:	eb d4                	jmp    f010354e <env_free+0x75>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f010357a:	8b 47 60             	mov    0x60(%edi),%eax
f010357d:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103580:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f0103587:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010358a:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0103590:	73 65                	jae    f01035f7 <env_free+0x11e>
		page_decref(pa2page(pa));
f0103592:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103595:	a1 90 7e 21 f0       	mov    0xf0217e90,%eax
f010359a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010359d:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01035a0:	50                   	push   %eax
f01035a1:	e8 c1 da ff ff       	call   f0101067 <page_decref>
f01035a6:	83 c4 10             	add    $0x10,%esp
f01035a9:	83 45 e0 04          	addl   $0x4,-0x20(%ebp)
f01035ad:	8b 45 e0             	mov    -0x20(%ebp),%eax
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01035b0:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f01035b5:	74 54                	je     f010360b <env_free+0x132>
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01035b7:	8b 47 60             	mov    0x60(%edi),%eax
f01035ba:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01035bd:	8b 04 10             	mov    (%eax,%edx,1),%eax
f01035c0:	a8 01                	test   $0x1,%al
f01035c2:	74 e5                	je     f01035a9 <env_free+0xd0>
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01035c4:	89 c6                	mov    %eax,%esi
f01035c6:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	if (PGNUM(pa) >= npages)
f01035cc:	c1 e8 0c             	shr    $0xc,%eax
f01035cf:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01035d2:	39 05 88 7e 21 f0    	cmp    %eax,0xf0217e88
f01035d8:	0f 86 5b ff ff ff    	jbe    f0103539 <env_free+0x60>
	return (void *)(pa + KERNBASE);
f01035de:	81 ee 00 00 00 10    	sub    $0x10000000,%esi
f01035e4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01035e7:	c1 e0 14             	shl    $0x14,%eax
f01035ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01035ed:	bb 00 00 00 00       	mov    $0x0,%ebx
f01035f2:	e9 7c ff ff ff       	jmp    f0103573 <env_free+0x9a>
		panic("pa2page called with invalid pa");
f01035f7:	83 ec 04             	sub    $0x4,%esp
f01035fa:	68 bc 6e 10 f0       	push   $0xf0106ebc
f01035ff:	6a 51                	push   $0x51
f0103601:	68 29 77 10 f0       	push   $0xf0107729
f0103606:	e8 35 ca ff ff       	call   f0100040 <_panic>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f010360b:	8b 47 60             	mov    0x60(%edi),%eax
	if ((uint32_t)kva < KERNBASE)
f010360e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103613:	76 49                	jbe    f010365e <env_free+0x185>
	e->env_pgdir = 0;
f0103615:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f010361c:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f0103621:	c1 e8 0c             	shr    $0xc,%eax
f0103624:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f010362a:	73 47                	jae    f0103673 <env_free+0x19a>
	page_decref(pa2page(pa));
f010362c:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f010362f:	8b 15 90 7e 21 f0    	mov    0xf0217e90,%edx
f0103635:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103638:	50                   	push   %eax
f0103639:	e8 29 da ff ff       	call   f0101067 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f010363e:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103645:	a1 4c 72 21 f0       	mov    0xf021724c,%eax
f010364a:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f010364d:	89 3d 4c 72 21 f0    	mov    %edi,0xf021724c
}
f0103653:	83 c4 10             	add    $0x10,%esp
f0103656:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103659:	5b                   	pop    %ebx
f010365a:	5e                   	pop    %esi
f010365b:	5f                   	pop    %edi
f010365c:	5d                   	pop    %ebp
f010365d:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010365e:	50                   	push   %eax
f010365f:	68 08 68 10 f0       	push   $0xf0106808
f0103664:	68 fc 01 00 00       	push   $0x1fc
f0103669:	68 25 7b 10 f0       	push   $0xf0107b25
f010366e:	e8 cd c9 ff ff       	call   f0100040 <_panic>
		panic("pa2page called with invalid pa");
f0103673:	83 ec 04             	sub    $0x4,%esp
f0103676:	68 bc 6e 10 f0       	push   $0xf0106ebc
f010367b:	6a 51                	push   $0x51
f010367d:	68 29 77 10 f0       	push   $0xf0107729
f0103682:	e8 b9 c9 ff ff       	call   f0100040 <_panic>

f0103687 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103687:	f3 0f 1e fb          	endbr32 
f010368b:	55                   	push   %ebp
f010368c:	89 e5                	mov    %esp,%ebp
f010368e:	53                   	push   %ebx
f010368f:	83 ec 04             	sub    $0x4,%esp
f0103692:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103695:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103699:	74 21                	je     f01036bc <env_destroy+0x35>
		e->env_status = ENV_DYING;
		return;
	}

	env_free(e);
f010369b:	83 ec 0c             	sub    $0xc,%esp
f010369e:	53                   	push   %ebx
f010369f:	e8 35 fe ff ff       	call   f01034d9 <env_free>

	if (curenv == e) {
f01036a4:	e8 a5 2a 00 00       	call   f010614e <cpunum>
f01036a9:	6b c0 74             	imul   $0x74,%eax,%eax
f01036ac:	83 c4 10             	add    $0x10,%esp
f01036af:	39 98 28 80 21 f0    	cmp    %ebx,-0xfde7fd8(%eax)
f01036b5:	74 1e                	je     f01036d5 <env_destroy+0x4e>
		curenv = NULL;
		sched_yield();
	}
}
f01036b7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01036ba:	c9                   	leave  
f01036bb:	c3                   	ret    
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01036bc:	e8 8d 2a 00 00       	call   f010614e <cpunum>
f01036c1:	6b c0 74             	imul   $0x74,%eax,%eax
f01036c4:	39 98 28 80 21 f0    	cmp    %ebx,-0xfde7fd8(%eax)
f01036ca:	74 cf                	je     f010369b <env_destroy+0x14>
		e->env_status = ENV_DYING;
f01036cc:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01036d3:	eb e2                	jmp    f01036b7 <env_destroy+0x30>
		curenv = NULL;
f01036d5:	e8 74 2a 00 00       	call   f010614e <cpunum>
f01036da:	6b c0 74             	imul   $0x74,%eax,%eax
f01036dd:	c7 80 28 80 21 f0 00 	movl   $0x0,-0xfde7fd8(%eax)
f01036e4:	00 00 00 
		sched_yield();
f01036e7:	e8 59 11 00 00       	call   f0104845 <sched_yield>

f01036ec <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01036ec:	f3 0f 1e fb          	endbr32 
f01036f0:	55                   	push   %ebp
f01036f1:	89 e5                	mov    %esp,%ebp
f01036f3:	53                   	push   %ebx
f01036f4:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01036f7:	e8 52 2a 00 00       	call   f010614e <cpunum>
f01036fc:	6b c0 74             	imul   $0x74,%eax,%eax
f01036ff:	8b 98 28 80 21 f0    	mov    -0xfde7fd8(%eax),%ebx
f0103705:	e8 44 2a 00 00       	call   f010614e <cpunum>
f010370a:	89 43 5c             	mov    %eax,0x5c(%ebx)
	asm volatile(
f010370d:	8b 65 08             	mov    0x8(%ebp),%esp
f0103710:	61                   	popa   
f0103711:	07                   	pop    %es
f0103712:	1f                   	pop    %ds
f0103713:	83 c4 08             	add    $0x8,%esp
f0103716:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103717:	83 ec 04             	sub    $0x4,%esp
f010371a:	68 30 7b 10 f0       	push   $0xf0107b30
f010371f:	68 2e 02 00 00       	push   $0x22e
f0103724:	68 25 7b 10 f0       	push   $0xf0107b25
f0103729:	e8 12 c9 ff ff       	call   f0100040 <_panic>

f010372e <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010372e:	f3 0f 1e fb          	endbr32 
f0103732:	55                   	push   %ebp
f0103733:	89 e5                	mov    %esp,%ebp
f0103735:	83 ec 08             	sub    $0x8,%esp
	
	// panic("env_run not yet implemented");

	// step 1
	// set the env_status field
	if(curenv)
f0103738:	e8 11 2a 00 00       	call   f010614e <cpunum>
f010373d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103740:	83 b8 28 80 21 f0 00 	cmpl   $0x0,-0xfde7fd8(%eax)
f0103747:	74 14                	je     f010375d <env_run+0x2f>
	{
		if(curenv->env_status == ENV_RUNNING)
f0103749:	e8 00 2a 00 00       	call   f010614e <cpunum>
f010374e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103751:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0103757:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010375b:	74 7d                	je     f01037da <env_run+0xac>
			curenv->env_status = ENV_RUNNABLE;
		}
	}

	// switch to new environment
	curenv = e;
f010375d:	e8 ec 29 00 00       	call   f010614e <cpunum>
f0103762:	6b c0 74             	imul   $0x74,%eax,%eax
f0103765:	8b 55 08             	mov    0x8(%ebp),%edx
f0103768:	89 90 28 80 21 f0    	mov    %edx,-0xfde7fd8(%eax)
	curenv->env_status = ENV_RUNNING;
f010376e:	e8 db 29 00 00       	call   f010614e <cpunum>
f0103773:	6b c0 74             	imul   $0x74,%eax,%eax
f0103776:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f010377c:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0103783:	e8 c6 29 00 00       	call   f010614e <cpunum>
f0103788:	6b c0 74             	imul   $0x74,%eax,%eax
f010378b:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0103791:	83 40 58 01          	addl   $0x1,0x58(%eax)
	// switch to user page directory
	lcr3(PADDR(curenv->env_pgdir));
f0103795:	e8 b4 29 00 00       	call   f010614e <cpunum>
f010379a:	6b c0 74             	imul   $0x74,%eax,%eax
f010379d:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01037a3:	8b 40 60             	mov    0x60(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01037a6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01037ab:	76 47                	jbe    f01037f4 <env_run+0xc6>
	return (physaddr_t)kva - KERNBASE;
f01037ad:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01037b2:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01037b5:	83 ec 0c             	sub    $0xc,%esp
f01037b8:	68 c0 33 12 f0       	push   $0xf01233c0
f01037bd:	e8 b2 2c 00 00       	call   f0106474 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01037c2:	f3 90                	pause  
	unlock_kernel();
	// step 2
	env_pop_tf(&curenv->env_tf);
f01037c4:	e8 85 29 00 00       	call   f010614e <cpunum>
f01037c9:	83 c4 04             	add    $0x4,%esp
f01037cc:	6b c0 74             	imul   $0x74,%eax,%eax
f01037cf:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f01037d5:	e8 12 ff ff ff       	call   f01036ec <env_pop_tf>
			curenv->env_status = ENV_RUNNABLE;
f01037da:	e8 6f 29 00 00       	call   f010614e <cpunum>
f01037df:	6b c0 74             	imul   $0x74,%eax,%eax
f01037e2:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01037e8:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
f01037ef:	e9 69 ff ff ff       	jmp    f010375d <env_run+0x2f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01037f4:	50                   	push   %eax
f01037f5:	68 08 68 10 f0       	push   $0xf0106808
f01037fa:	68 5e 02 00 00       	push   $0x25e
f01037ff:	68 25 7b 10 f0       	push   $0xf0107b25
f0103804:	e8 37 c8 ff ff       	call   f0100040 <_panic>

f0103809 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103809:	f3 0f 1e fb          	endbr32 
f010380d:	55                   	push   %ebp
f010380e:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103810:	8b 45 08             	mov    0x8(%ebp),%eax
f0103813:	ba 70 00 00 00       	mov    $0x70,%edx
f0103818:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103819:	ba 71 00 00 00       	mov    $0x71,%edx
f010381e:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010381f:	0f b6 c0             	movzbl %al,%eax
}
f0103822:	5d                   	pop    %ebp
f0103823:	c3                   	ret    

f0103824 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103824:	f3 0f 1e fb          	endbr32 
f0103828:	55                   	push   %ebp
f0103829:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010382b:	8b 45 08             	mov    0x8(%ebp),%eax
f010382e:	ba 70 00 00 00       	mov    $0x70,%edx
f0103833:	ee                   	out    %al,(%dx)
f0103834:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103837:	ba 71 00 00 00       	mov    $0x71,%edx
f010383c:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010383d:	5d                   	pop    %ebp
f010383e:	c3                   	ret    

f010383f <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f010383f:	f3 0f 1e fb          	endbr32 
f0103843:	55                   	push   %ebp
f0103844:	89 e5                	mov    %esp,%ebp
f0103846:	56                   	push   %esi
f0103847:	53                   	push   %ebx
f0103848:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f010384b:	66 a3 a8 33 12 f0    	mov    %ax,0xf01233a8
	if (!didinit)
f0103851:	80 3d 50 72 21 f0 00 	cmpb   $0x0,0xf0217250
f0103858:	75 07                	jne    f0103861 <irq_setmask_8259A+0x22>
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
}
f010385a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010385d:	5b                   	pop    %ebx
f010385e:	5e                   	pop    %esi
f010385f:	5d                   	pop    %ebp
f0103860:	c3                   	ret    
f0103861:	89 c6                	mov    %eax,%esi
f0103863:	ba 21 00 00 00       	mov    $0x21,%edx
f0103868:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
f0103869:	66 c1 e8 08          	shr    $0x8,%ax
f010386d:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103872:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0103873:	83 ec 0c             	sub    $0xc,%esp
f0103876:	68 3c 7b 10 f0       	push   $0xf0107b3c
f010387b:	e8 2c 01 00 00       	call   f01039ac <cprintf>
f0103880:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0103883:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103888:	0f b7 f6             	movzwl %si,%esi
f010388b:	f7 d6                	not    %esi
f010388d:	eb 19                	jmp    f01038a8 <irq_setmask_8259A+0x69>
			cprintf(" %d", i);
f010388f:	83 ec 08             	sub    $0x8,%esp
f0103892:	53                   	push   %ebx
f0103893:	68 cf 80 10 f0       	push   $0xf01080cf
f0103898:	e8 0f 01 00 00       	call   f01039ac <cprintf>
f010389d:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f01038a0:	83 c3 01             	add    $0x1,%ebx
f01038a3:	83 fb 10             	cmp    $0x10,%ebx
f01038a6:	74 07                	je     f01038af <irq_setmask_8259A+0x70>
		if (~mask & (1<<i))
f01038a8:	0f a3 de             	bt     %ebx,%esi
f01038ab:	73 f3                	jae    f01038a0 <irq_setmask_8259A+0x61>
f01038ad:	eb e0                	jmp    f010388f <irq_setmask_8259A+0x50>
	cprintf("\n");
f01038af:	83 ec 0c             	sub    $0xc,%esp
f01038b2:	68 fd 79 10 f0       	push   $0xf01079fd
f01038b7:	e8 f0 00 00 00       	call   f01039ac <cprintf>
f01038bc:	83 c4 10             	add    $0x10,%esp
f01038bf:	eb 99                	jmp    f010385a <irq_setmask_8259A+0x1b>

f01038c1 <pic_init>:
{
f01038c1:	f3 0f 1e fb          	endbr32 
f01038c5:	55                   	push   %ebp
f01038c6:	89 e5                	mov    %esp,%ebp
f01038c8:	57                   	push   %edi
f01038c9:	56                   	push   %esi
f01038ca:	53                   	push   %ebx
f01038cb:	83 ec 0c             	sub    $0xc,%esp
	didinit = 1;
f01038ce:	c6 05 50 72 21 f0 01 	movb   $0x1,0xf0217250
f01038d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01038da:	bb 21 00 00 00       	mov    $0x21,%ebx
f01038df:	89 da                	mov    %ebx,%edx
f01038e1:	ee                   	out    %al,(%dx)
f01038e2:	b9 a1 00 00 00       	mov    $0xa1,%ecx
f01038e7:	89 ca                	mov    %ecx,%edx
f01038e9:	ee                   	out    %al,(%dx)
f01038ea:	bf 11 00 00 00       	mov    $0x11,%edi
f01038ef:	be 20 00 00 00       	mov    $0x20,%esi
f01038f4:	89 f8                	mov    %edi,%eax
f01038f6:	89 f2                	mov    %esi,%edx
f01038f8:	ee                   	out    %al,(%dx)
f01038f9:	b8 20 00 00 00       	mov    $0x20,%eax
f01038fe:	89 da                	mov    %ebx,%edx
f0103900:	ee                   	out    %al,(%dx)
f0103901:	b8 04 00 00 00       	mov    $0x4,%eax
f0103906:	ee                   	out    %al,(%dx)
f0103907:	b8 03 00 00 00       	mov    $0x3,%eax
f010390c:	ee                   	out    %al,(%dx)
f010390d:	bb a0 00 00 00       	mov    $0xa0,%ebx
f0103912:	89 f8                	mov    %edi,%eax
f0103914:	89 da                	mov    %ebx,%edx
f0103916:	ee                   	out    %al,(%dx)
f0103917:	b8 28 00 00 00       	mov    $0x28,%eax
f010391c:	89 ca                	mov    %ecx,%edx
f010391e:	ee                   	out    %al,(%dx)
f010391f:	b8 02 00 00 00       	mov    $0x2,%eax
f0103924:	ee                   	out    %al,(%dx)
f0103925:	b8 01 00 00 00       	mov    $0x1,%eax
f010392a:	ee                   	out    %al,(%dx)
f010392b:	bf 68 00 00 00       	mov    $0x68,%edi
f0103930:	89 f8                	mov    %edi,%eax
f0103932:	89 f2                	mov    %esi,%edx
f0103934:	ee                   	out    %al,(%dx)
f0103935:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010393a:	89 c8                	mov    %ecx,%eax
f010393c:	ee                   	out    %al,(%dx)
f010393d:	89 f8                	mov    %edi,%eax
f010393f:	89 da                	mov    %ebx,%edx
f0103941:	ee                   	out    %al,(%dx)
f0103942:	89 c8                	mov    %ecx,%eax
f0103944:	ee                   	out    %al,(%dx)
	if (irq_mask_8259A != 0xFFFF)
f0103945:	0f b7 05 a8 33 12 f0 	movzwl 0xf01233a8,%eax
f010394c:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103950:	75 08                	jne    f010395a <pic_init+0x99>
}
f0103952:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103955:	5b                   	pop    %ebx
f0103956:	5e                   	pop    %esi
f0103957:	5f                   	pop    %edi
f0103958:	5d                   	pop    %ebp
f0103959:	c3                   	ret    
		irq_setmask_8259A(irq_mask_8259A);
f010395a:	83 ec 0c             	sub    $0xc,%esp
f010395d:	0f b7 c0             	movzwl %ax,%eax
f0103960:	50                   	push   %eax
f0103961:	e8 d9 fe ff ff       	call   f010383f <irq_setmask_8259A>
f0103966:	83 c4 10             	add    $0x10,%esp
}
f0103969:	eb e7                	jmp    f0103952 <pic_init+0x91>

f010396b <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010396b:	f3 0f 1e fb          	endbr32 
f010396f:	55                   	push   %ebp
f0103970:	89 e5                	mov    %esp,%ebp
f0103972:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103975:	ff 75 08             	pushl  0x8(%ebp)
f0103978:	e8 41 ce ff ff       	call   f01007be <cputchar>
	*cnt++;
}
f010397d:	83 c4 10             	add    $0x10,%esp
f0103980:	c9                   	leave  
f0103981:	c3                   	ret    

f0103982 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103982:	f3 0f 1e fb          	endbr32 
f0103986:	55                   	push   %ebp
f0103987:	89 e5                	mov    %esp,%ebp
f0103989:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010398c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103993:	ff 75 0c             	pushl  0xc(%ebp)
f0103996:	ff 75 08             	pushl  0x8(%ebp)
f0103999:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010399c:	50                   	push   %eax
f010399d:	68 6b 39 10 f0       	push   $0xf010396b
f01039a2:	e8 25 1a 00 00       	call   f01053cc <vprintfmt>
	return cnt;
}
f01039a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01039aa:	c9                   	leave  
f01039ab:	c3                   	ret    

f01039ac <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01039ac:	f3 0f 1e fb          	endbr32 
f01039b0:	55                   	push   %ebp
f01039b1:	89 e5                	mov    %esp,%ebp
f01039b3:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01039b6:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01039b9:	50                   	push   %eax
f01039ba:	ff 75 08             	pushl  0x8(%ebp)
f01039bd:	e8 c0 ff ff ff       	call   f0103982 <vcprintf>
	va_end(ap);

	return cnt;
}
f01039c2:	c9                   	leave  
f01039c3:	c3                   	ret    

f01039c4 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01039c4:	f3 0f 1e fb          	endbr32 
f01039c8:	55                   	push   %ebp
f01039c9:	89 e5                	mov    %esp,%ebp
f01039cb:	57                   	push   %edi
f01039cc:	56                   	push   %esi
f01039cd:	53                   	push   %ebx
f01039ce:	83 ec 1c             	sub    $0x1c,%esp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	uint8_t id = thiscpu->cpu_id;
f01039d1:	e8 78 27 00 00       	call   f010614e <cpunum>
f01039d6:	6b c0 74             	imul   $0x74,%eax,%eax
f01039d9:	0f b6 b8 20 80 21 f0 	movzbl -0xfde7fe0(%eax),%edi
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP-id*(KSTKSIZE+KSTKGAP);
f01039e0:	89 f8                	mov    %edi,%eax
f01039e2:	0f b6 d8             	movzbl %al,%ebx
f01039e5:	e8 64 27 00 00       	call   f010614e <cpunum>
f01039ea:	6b c0 74             	imul   $0x74,%eax,%eax
f01039ed:	89 d9                	mov    %ebx,%ecx
f01039ef:	c1 e1 10             	shl    $0x10,%ecx
f01039f2:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01039f7:	29 ca                	sub    %ecx,%edx
f01039f9:	89 90 30 80 21 f0    	mov    %edx,-0xfde7fd0(%eax)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f01039ff:	e8 4a 27 00 00       	call   f010614e <cpunum>
f0103a04:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a07:	66 c7 80 34 80 21 f0 	movw   $0x10,-0xfde7fcc(%eax)
f0103a0e:	10 00 
	thiscpu->cpu_ts.ts_iomb = sizeof(struct Taskstate);
f0103a10:	e8 39 27 00 00       	call   f010614e <cpunum>
f0103a15:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a18:	66 c7 80 92 80 21 f0 	movw   $0x68,-0xfde7f6e(%eax)
f0103a1f:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+id] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
f0103a21:	83 c3 05             	add    $0x5,%ebx
f0103a24:	e8 25 27 00 00       	call   f010614e <cpunum>
f0103a29:	89 c6                	mov    %eax,%esi
f0103a2b:	e8 1e 27 00 00       	call   f010614e <cpunum>
f0103a30:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103a33:	e8 16 27 00 00       	call   f010614e <cpunum>
f0103a38:	66 c7 04 dd 40 33 12 	movw   $0x67,-0xfedccc0(,%ebx,8)
f0103a3f:	f0 67 00 
f0103a42:	6b f6 74             	imul   $0x74,%esi,%esi
f0103a45:	81 c6 2c 80 21 f0    	add    $0xf021802c,%esi
f0103a4b:	66 89 34 dd 42 33 12 	mov    %si,-0xfedccbe(,%ebx,8)
f0103a52:	f0 
f0103a53:	6b 55 e4 74          	imul   $0x74,-0x1c(%ebp),%edx
f0103a57:	81 c2 2c 80 21 f0    	add    $0xf021802c,%edx
f0103a5d:	c1 ea 10             	shr    $0x10,%edx
f0103a60:	88 14 dd 44 33 12 f0 	mov    %dl,-0xfedccbc(,%ebx,8)
f0103a67:	c6 04 dd 46 33 12 f0 	movb   $0x40,-0xfedccba(,%ebx,8)
f0103a6e:	40 
f0103a6f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a72:	05 2c 80 21 f0       	add    $0xf021802c,%eax
f0103a77:	c1 e8 18             	shr    $0x18,%eax
f0103a7a:	88 04 dd 47 33 12 f0 	mov    %al,-0xfedccb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3)+id].sd_s = 0;
f0103a81:	c6 04 dd 45 33 12 f0 	movb   $0x89,-0xfedccbb(,%ebx,8)
f0103a88:	89 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0+(id<<3));
f0103a89:	89 f8                	mov    %edi,%eax
f0103a8b:	0f b6 f8             	movzbl %al,%edi
f0103a8e:	8d 3c fd 28 00 00 00 	lea    0x28(,%edi,8),%edi
	asm volatile("ltr %0" : : "r" (sel));
f0103a95:	0f 00 df             	ltr    %di
	asm volatile("lidt (%0)" : : "r" (p));
f0103a98:	b8 ac 33 12 f0       	mov    $0xf01233ac,%eax
f0103a9d:	0f 01 18             	lidtl  (%eax)

	// Load the IDT
	lidt(&idt_pd);
}
f0103aa0:	83 c4 1c             	add    $0x1c,%esp
f0103aa3:	5b                   	pop    %ebx
f0103aa4:	5e                   	pop    %esi
f0103aa5:	5f                   	pop    %edi
f0103aa6:	5d                   	pop    %ebp
f0103aa7:	c3                   	ret    

f0103aa8 <trap_init>:
{
f0103aa8:	f3 0f 1e fb          	endbr32 
f0103aac:	55                   	push   %ebp
f0103aad:	89 e5                	mov    %esp,%ebp
f0103aaf:	83 ec 08             	sub    $0x8,%esp
    SETGATE(idt[T_DIVIDE], 0, GD_KT, DIVIDE, 0);
f0103ab2:	b8 52 46 10 f0       	mov    $0xf0104652,%eax
f0103ab7:	66 a3 60 72 21 f0    	mov    %ax,0xf0217260
f0103abd:	66 c7 05 62 72 21 f0 	movw   $0x8,0xf0217262
f0103ac4:	08 00 
f0103ac6:	c6 05 64 72 21 f0 00 	movb   $0x0,0xf0217264
f0103acd:	c6 05 65 72 21 f0 8e 	movb   $0x8e,0xf0217265
f0103ad4:	c1 e8 10             	shr    $0x10,%eax
f0103ad7:	66 a3 66 72 21 f0    	mov    %ax,0xf0217266
	SETGATE(idt[T_DEBUG], 0, GD_KT, DEBUG, 0);
f0103add:	b8 5c 46 10 f0       	mov    $0xf010465c,%eax
f0103ae2:	66 a3 68 72 21 f0    	mov    %ax,0xf0217268
f0103ae8:	66 c7 05 6a 72 21 f0 	movw   $0x8,0xf021726a
f0103aef:	08 00 
f0103af1:	c6 05 6c 72 21 f0 00 	movb   $0x0,0xf021726c
f0103af8:	c6 05 6d 72 21 f0 8e 	movb   $0x8e,0xf021726d
f0103aff:	c1 e8 10             	shr    $0x10,%eax
f0103b02:	66 a3 6e 72 21 f0    	mov    %ax,0xf021726e
	SETGATE(idt[T_NMI], 0, GD_KT, NMI, 0);
f0103b08:	b8 66 46 10 f0       	mov    $0xf0104666,%eax
f0103b0d:	66 a3 70 72 21 f0    	mov    %ax,0xf0217270
f0103b13:	66 c7 05 72 72 21 f0 	movw   $0x8,0xf0217272
f0103b1a:	08 00 
f0103b1c:	c6 05 74 72 21 f0 00 	movb   $0x0,0xf0217274
f0103b23:	c6 05 75 72 21 f0 8e 	movb   $0x8e,0xf0217275
f0103b2a:	c1 e8 10             	shr    $0x10,%eax
f0103b2d:	66 a3 76 72 21 f0    	mov    %ax,0xf0217276
	SETGATE(idt[T_BRKPT], 0, GD_KT, BRKPT, 3);
f0103b33:	b8 70 46 10 f0       	mov    $0xf0104670,%eax
f0103b38:	66 a3 78 72 21 f0    	mov    %ax,0xf0217278
f0103b3e:	66 c7 05 7a 72 21 f0 	movw   $0x8,0xf021727a
f0103b45:	08 00 
f0103b47:	c6 05 7c 72 21 f0 00 	movb   $0x0,0xf021727c
f0103b4e:	c6 05 7d 72 21 f0 ee 	movb   $0xee,0xf021727d
f0103b55:	c1 e8 10             	shr    $0x10,%eax
f0103b58:	66 a3 7e 72 21 f0    	mov    %ax,0xf021727e
	SETGATE(idt[T_OFLOW], 0, GD_KT, OFLOW, 0);
f0103b5e:	b8 7a 46 10 f0       	mov    $0xf010467a,%eax
f0103b63:	66 a3 80 72 21 f0    	mov    %ax,0xf0217280
f0103b69:	66 c7 05 82 72 21 f0 	movw   $0x8,0xf0217282
f0103b70:	08 00 
f0103b72:	c6 05 84 72 21 f0 00 	movb   $0x0,0xf0217284
f0103b79:	c6 05 85 72 21 f0 8e 	movb   $0x8e,0xf0217285
f0103b80:	c1 e8 10             	shr    $0x10,%eax
f0103b83:	66 a3 86 72 21 f0    	mov    %ax,0xf0217286
	SETGATE(idt[T_BOUND], 0, GD_KT, BOUND, 0);
f0103b89:	b8 84 46 10 f0       	mov    $0xf0104684,%eax
f0103b8e:	66 a3 88 72 21 f0    	mov    %ax,0xf0217288
f0103b94:	66 c7 05 8a 72 21 f0 	movw   $0x8,0xf021728a
f0103b9b:	08 00 
f0103b9d:	c6 05 8c 72 21 f0 00 	movb   $0x0,0xf021728c
f0103ba4:	c6 05 8d 72 21 f0 8e 	movb   $0x8e,0xf021728d
f0103bab:	c1 e8 10             	shr    $0x10,%eax
f0103bae:	66 a3 8e 72 21 f0    	mov    %ax,0xf021728e
	SETGATE(idt[T_ILLOP], 0, GD_KT, ILLOP, 0);
f0103bb4:	b8 8e 46 10 f0       	mov    $0xf010468e,%eax
f0103bb9:	66 a3 90 72 21 f0    	mov    %ax,0xf0217290
f0103bbf:	66 c7 05 92 72 21 f0 	movw   $0x8,0xf0217292
f0103bc6:	08 00 
f0103bc8:	c6 05 94 72 21 f0 00 	movb   $0x0,0xf0217294
f0103bcf:	c6 05 95 72 21 f0 8e 	movb   $0x8e,0xf0217295
f0103bd6:	c1 e8 10             	shr    $0x10,%eax
f0103bd9:	66 a3 96 72 21 f0    	mov    %ax,0xf0217296
	SETGATE(idt[T_DEVICE], 0, GD_KT, DEVICE, 0);
f0103bdf:	b8 98 46 10 f0       	mov    $0xf0104698,%eax
f0103be4:	66 a3 98 72 21 f0    	mov    %ax,0xf0217298
f0103bea:	66 c7 05 9a 72 21 f0 	movw   $0x8,0xf021729a
f0103bf1:	08 00 
f0103bf3:	c6 05 9c 72 21 f0 00 	movb   $0x0,0xf021729c
f0103bfa:	c6 05 9d 72 21 f0 8e 	movb   $0x8e,0xf021729d
f0103c01:	c1 e8 10             	shr    $0x10,%eax
f0103c04:	66 a3 9e 72 21 f0    	mov    %ax,0xf021729e
	SETGATE(idt[T_DBLFLT], 0, GD_KT, DBLFLT, 0);
f0103c0a:	b8 a2 46 10 f0       	mov    $0xf01046a2,%eax
f0103c0f:	66 a3 a0 72 21 f0    	mov    %ax,0xf02172a0
f0103c15:	66 c7 05 a2 72 21 f0 	movw   $0x8,0xf02172a2
f0103c1c:	08 00 
f0103c1e:	c6 05 a4 72 21 f0 00 	movb   $0x0,0xf02172a4
f0103c25:	c6 05 a5 72 21 f0 8e 	movb   $0x8e,0xf02172a5
f0103c2c:	c1 e8 10             	shr    $0x10,%eax
f0103c2f:	66 a3 a6 72 21 f0    	mov    %ax,0xf02172a6
	SETGATE(idt[T_TSS], 0, GD_KT, TSS, 0);
f0103c35:	b8 aa 46 10 f0       	mov    $0xf01046aa,%eax
f0103c3a:	66 a3 b0 72 21 f0    	mov    %ax,0xf02172b0
f0103c40:	66 c7 05 b2 72 21 f0 	movw   $0x8,0xf02172b2
f0103c47:	08 00 
f0103c49:	c6 05 b4 72 21 f0 00 	movb   $0x0,0xf02172b4
f0103c50:	c6 05 b5 72 21 f0 8e 	movb   $0x8e,0xf02172b5
f0103c57:	c1 e8 10             	shr    $0x10,%eax
f0103c5a:	66 a3 b6 72 21 f0    	mov    %ax,0xf02172b6
	SETGATE(idt[T_SEGNP], 0, GD_KT, SEGNP, 0);
f0103c60:	b8 b2 46 10 f0       	mov    $0xf01046b2,%eax
f0103c65:	66 a3 b8 72 21 f0    	mov    %ax,0xf02172b8
f0103c6b:	66 c7 05 ba 72 21 f0 	movw   $0x8,0xf02172ba
f0103c72:	08 00 
f0103c74:	c6 05 bc 72 21 f0 00 	movb   $0x0,0xf02172bc
f0103c7b:	c6 05 bd 72 21 f0 8e 	movb   $0x8e,0xf02172bd
f0103c82:	c1 e8 10             	shr    $0x10,%eax
f0103c85:	66 a3 be 72 21 f0    	mov    %ax,0xf02172be
	SETGATE(idt[T_STACK], 0, GD_KT, STACK, 0);
f0103c8b:	b8 ba 46 10 f0       	mov    $0xf01046ba,%eax
f0103c90:	66 a3 c0 72 21 f0    	mov    %ax,0xf02172c0
f0103c96:	66 c7 05 c2 72 21 f0 	movw   $0x8,0xf02172c2
f0103c9d:	08 00 
f0103c9f:	c6 05 c4 72 21 f0 00 	movb   $0x0,0xf02172c4
f0103ca6:	c6 05 c5 72 21 f0 8e 	movb   $0x8e,0xf02172c5
f0103cad:	c1 e8 10             	shr    $0x10,%eax
f0103cb0:	66 a3 c6 72 21 f0    	mov    %ax,0xf02172c6
	SETGATE(idt[T_GPFLT], 0, GD_KT, GPFLT, 0);
f0103cb6:	b8 c2 46 10 f0       	mov    $0xf01046c2,%eax
f0103cbb:	66 a3 c8 72 21 f0    	mov    %ax,0xf02172c8
f0103cc1:	66 c7 05 ca 72 21 f0 	movw   $0x8,0xf02172ca
f0103cc8:	08 00 
f0103cca:	c6 05 cc 72 21 f0 00 	movb   $0x0,0xf02172cc
f0103cd1:	c6 05 cd 72 21 f0 8e 	movb   $0x8e,0xf02172cd
f0103cd8:	c1 e8 10             	shr    $0x10,%eax
f0103cdb:	66 a3 ce 72 21 f0    	mov    %ax,0xf02172ce
	SETGATE(idt[T_PGFLT], 0, GD_KT, PGFLT, 0);
f0103ce1:	b8 ca 46 10 f0       	mov    $0xf01046ca,%eax
f0103ce6:	66 a3 d0 72 21 f0    	mov    %ax,0xf02172d0
f0103cec:	66 c7 05 d2 72 21 f0 	movw   $0x8,0xf02172d2
f0103cf3:	08 00 
f0103cf5:	c6 05 d4 72 21 f0 00 	movb   $0x0,0xf02172d4
f0103cfc:	c6 05 d5 72 21 f0 8e 	movb   $0x8e,0xf02172d5
f0103d03:	c1 e8 10             	shr    $0x10,%eax
f0103d06:	66 a3 d6 72 21 f0    	mov    %ax,0xf02172d6
	SETGATE(idt[T_FPERR], 0, GD_KT, FPERR, 0);
f0103d0c:	b8 d2 46 10 f0       	mov    $0xf01046d2,%eax
f0103d11:	66 a3 e0 72 21 f0    	mov    %ax,0xf02172e0
f0103d17:	66 c7 05 e2 72 21 f0 	movw   $0x8,0xf02172e2
f0103d1e:	08 00 
f0103d20:	c6 05 e4 72 21 f0 00 	movb   $0x0,0xf02172e4
f0103d27:	c6 05 e5 72 21 f0 8e 	movb   $0x8e,0xf02172e5
f0103d2e:	c1 e8 10             	shr    $0x10,%eax
f0103d31:	66 a3 e6 72 21 f0    	mov    %ax,0xf02172e6
	SETGATE(idt[T_ALIGN], 0, GD_KT, ALIGN, 0);
f0103d37:	b8 dc 46 10 f0       	mov    $0xf01046dc,%eax
f0103d3c:	66 a3 e8 72 21 f0    	mov    %ax,0xf02172e8
f0103d42:	66 c7 05 ea 72 21 f0 	movw   $0x8,0xf02172ea
f0103d49:	08 00 
f0103d4b:	c6 05 ec 72 21 f0 00 	movb   $0x0,0xf02172ec
f0103d52:	c6 05 ed 72 21 f0 8e 	movb   $0x8e,0xf02172ed
f0103d59:	c1 e8 10             	shr    $0x10,%eax
f0103d5c:	66 a3 ee 72 21 f0    	mov    %ax,0xf02172ee
	SETGATE(idt[T_MCHK], 0, GD_KT, MCHK, 0);
f0103d62:	b8 e4 46 10 f0       	mov    $0xf01046e4,%eax
f0103d67:	66 a3 f0 72 21 f0    	mov    %ax,0xf02172f0
f0103d6d:	66 c7 05 f2 72 21 f0 	movw   $0x8,0xf02172f2
f0103d74:	08 00 
f0103d76:	c6 05 f4 72 21 f0 00 	movb   $0x0,0xf02172f4
f0103d7d:	c6 05 f5 72 21 f0 8e 	movb   $0x8e,0xf02172f5
f0103d84:	c1 e8 10             	shr    $0x10,%eax
f0103d87:	66 a3 f6 72 21 f0    	mov    %ax,0xf02172f6
	SETGATE(idt[T_SIMDERR], 0, GD_KT, SIMDERR, 0);
f0103d8d:	b8 ea 46 10 f0       	mov    $0xf01046ea,%eax
f0103d92:	66 a3 f8 72 21 f0    	mov    %ax,0xf02172f8
f0103d98:	66 c7 05 fa 72 21 f0 	movw   $0x8,0xf02172fa
f0103d9f:	08 00 
f0103da1:	c6 05 fc 72 21 f0 00 	movb   $0x0,0xf02172fc
f0103da8:	c6 05 fd 72 21 f0 8e 	movb   $0x8e,0xf02172fd
f0103daf:	c1 e8 10             	shr    $0x10,%eax
f0103db2:	66 a3 fe 72 21 f0    	mov    %ax,0xf02172fe
	SETGATE(idt[T_SYSCALL], 0, GD_KT, SYSCALL, 3);
f0103db8:	b8 f0 46 10 f0       	mov    $0xf01046f0,%eax
f0103dbd:	66 a3 e0 73 21 f0    	mov    %ax,0xf02173e0
f0103dc3:	66 c7 05 e2 73 21 f0 	movw   $0x8,0xf02173e2
f0103dca:	08 00 
f0103dcc:	c6 05 e4 73 21 f0 00 	movb   $0x0,0xf02173e4
f0103dd3:	c6 05 e5 73 21 f0 ee 	movb   $0xee,0xf02173e5
f0103dda:	c1 e8 10             	shr    $0x10,%eax
f0103ddd:	66 a3 e6 73 21 f0    	mov    %ax,0xf02173e6
	SETGATE(idt[T_DEFAULT], 0, GD_KT, DEFAULT, 0);
f0103de3:	b8 f6 46 10 f0       	mov    $0xf01046f6,%eax
f0103de8:	66 a3 00 82 21 f0    	mov    %ax,0xf0218200
f0103dee:	66 c7 05 02 82 21 f0 	movw   $0x8,0xf0218202
f0103df5:	08 00 
f0103df7:	c6 05 04 82 21 f0 00 	movb   $0x0,0xf0218204
f0103dfe:	c6 05 05 82 21 f0 8e 	movb   $0x8e,0xf0218205
f0103e05:	c1 e8 10             	shr    $0x10,%eax
f0103e08:	66 a3 06 82 21 f0    	mov    %ax,0xf0218206
	SETGATE(idt[IRQ_OFFSET+IRQ_TIMER],0,GD_KT,IRQsHandler0,0);
f0103e0e:	b8 00 47 10 f0       	mov    $0xf0104700,%eax
f0103e13:	66 a3 60 73 21 f0    	mov    %ax,0xf0217360
f0103e19:	66 c7 05 62 73 21 f0 	movw   $0x8,0xf0217362
f0103e20:	08 00 
f0103e22:	c6 05 64 73 21 f0 00 	movb   $0x0,0xf0217364
f0103e29:	c6 05 65 73 21 f0 8e 	movb   $0x8e,0xf0217365
f0103e30:	c1 e8 10             	shr    $0x10,%eax
f0103e33:	66 a3 66 73 21 f0    	mov    %ax,0xf0217366
	SETGATE(idt[IRQ_OFFSET+IRQ_KBD],0,GD_KT,IRQsHandler1,0);
f0103e39:	b8 06 47 10 f0       	mov    $0xf0104706,%eax
f0103e3e:	66 a3 68 73 21 f0    	mov    %ax,0xf0217368
f0103e44:	66 c7 05 6a 73 21 f0 	movw   $0x8,0xf021736a
f0103e4b:	08 00 
f0103e4d:	c6 05 6c 73 21 f0 00 	movb   $0x0,0xf021736c
f0103e54:	c6 05 6d 73 21 f0 8e 	movb   $0x8e,0xf021736d
f0103e5b:	c1 e8 10             	shr    $0x10,%eax
f0103e5e:	66 a3 6e 73 21 f0    	mov    %ax,0xf021736e
	SETGATE(idt[IRQ_OFFSET+2],0,GD_KT,IRQsHandler2,0);
f0103e64:	b8 0c 47 10 f0       	mov    $0xf010470c,%eax
f0103e69:	66 a3 70 73 21 f0    	mov    %ax,0xf0217370
f0103e6f:	66 c7 05 72 73 21 f0 	movw   $0x8,0xf0217372
f0103e76:	08 00 
f0103e78:	c6 05 74 73 21 f0 00 	movb   $0x0,0xf0217374
f0103e7f:	c6 05 75 73 21 f0 8e 	movb   $0x8e,0xf0217375
f0103e86:	c1 e8 10             	shr    $0x10,%eax
f0103e89:	66 a3 76 73 21 f0    	mov    %ax,0xf0217376
	SETGATE(idt[IRQ_OFFSET+3],0,GD_KT,IRQsHandler3,0);
f0103e8f:	b8 12 47 10 f0       	mov    $0xf0104712,%eax
f0103e94:	66 a3 78 73 21 f0    	mov    %ax,0xf0217378
f0103e9a:	66 c7 05 7a 73 21 f0 	movw   $0x8,0xf021737a
f0103ea1:	08 00 
f0103ea3:	c6 05 7c 73 21 f0 00 	movb   $0x0,0xf021737c
f0103eaa:	c6 05 7d 73 21 f0 8e 	movb   $0x8e,0xf021737d
f0103eb1:	c1 e8 10             	shr    $0x10,%eax
f0103eb4:	66 a3 7e 73 21 f0    	mov    %ax,0xf021737e
	SETGATE(idt[IRQ_OFFSET+IRQ_SERIAL],0,GD_KT,IRQsHandler4,0);
f0103eba:	b8 18 47 10 f0       	mov    $0xf0104718,%eax
f0103ebf:	66 a3 80 73 21 f0    	mov    %ax,0xf0217380
f0103ec5:	66 c7 05 82 73 21 f0 	movw   $0x8,0xf0217382
f0103ecc:	08 00 
f0103ece:	c6 05 84 73 21 f0 00 	movb   $0x0,0xf0217384
f0103ed5:	c6 05 85 73 21 f0 8e 	movb   $0x8e,0xf0217385
f0103edc:	c1 e8 10             	shr    $0x10,%eax
f0103edf:	66 a3 86 73 21 f0    	mov    %ax,0xf0217386
	SETGATE(idt[IRQ_OFFSET+5],0,GD_KT,IRQsHandler5,0);
f0103ee5:	b8 1e 47 10 f0       	mov    $0xf010471e,%eax
f0103eea:	66 a3 88 73 21 f0    	mov    %ax,0xf0217388
f0103ef0:	66 c7 05 8a 73 21 f0 	movw   $0x8,0xf021738a
f0103ef7:	08 00 
f0103ef9:	c6 05 8c 73 21 f0 00 	movb   $0x0,0xf021738c
f0103f00:	c6 05 8d 73 21 f0 8e 	movb   $0x8e,0xf021738d
f0103f07:	c1 e8 10             	shr    $0x10,%eax
f0103f0a:	66 a3 8e 73 21 f0    	mov    %ax,0xf021738e
	SETGATE(idt[IRQ_OFFSET+6],0,GD_KT,IRQsHandler6,0);
f0103f10:	b8 24 47 10 f0       	mov    $0xf0104724,%eax
f0103f15:	66 a3 90 73 21 f0    	mov    %ax,0xf0217390
f0103f1b:	66 c7 05 92 73 21 f0 	movw   $0x8,0xf0217392
f0103f22:	08 00 
f0103f24:	c6 05 94 73 21 f0 00 	movb   $0x0,0xf0217394
f0103f2b:	c6 05 95 73 21 f0 8e 	movb   $0x8e,0xf0217395
f0103f32:	c1 e8 10             	shr    $0x10,%eax
f0103f35:	66 a3 96 73 21 f0    	mov    %ax,0xf0217396
	SETGATE(idt[IRQ_OFFSET+IRQ_SPURIOUS],0,GD_KT,IRQsHandler7,0);
f0103f3b:	b8 2a 47 10 f0       	mov    $0xf010472a,%eax
f0103f40:	66 a3 98 73 21 f0    	mov    %ax,0xf0217398
f0103f46:	66 c7 05 9a 73 21 f0 	movw   $0x8,0xf021739a
f0103f4d:	08 00 
f0103f4f:	c6 05 9c 73 21 f0 00 	movb   $0x0,0xf021739c
f0103f56:	c6 05 9d 73 21 f0 8e 	movb   $0x8e,0xf021739d
f0103f5d:	c1 e8 10             	shr    $0x10,%eax
f0103f60:	66 a3 9e 73 21 f0    	mov    %ax,0xf021739e
	SETGATE(idt[IRQ_OFFSET+8],0,GD_KT,IRQsHandler8,0);
f0103f66:	b8 30 47 10 f0       	mov    $0xf0104730,%eax
f0103f6b:	66 a3 a0 73 21 f0    	mov    %ax,0xf02173a0
f0103f71:	66 c7 05 a2 73 21 f0 	movw   $0x8,0xf02173a2
f0103f78:	08 00 
f0103f7a:	c6 05 a4 73 21 f0 00 	movb   $0x0,0xf02173a4
f0103f81:	c6 05 a5 73 21 f0 8e 	movb   $0x8e,0xf02173a5
f0103f88:	c1 e8 10             	shr    $0x10,%eax
f0103f8b:	66 a3 a6 73 21 f0    	mov    %ax,0xf02173a6
	SETGATE(idt[IRQ_OFFSET+9],0,GD_KT,IRQsHandler9,0);
f0103f91:	b8 36 47 10 f0       	mov    $0xf0104736,%eax
f0103f96:	66 a3 a8 73 21 f0    	mov    %ax,0xf02173a8
f0103f9c:	66 c7 05 aa 73 21 f0 	movw   $0x8,0xf02173aa
f0103fa3:	08 00 
f0103fa5:	c6 05 ac 73 21 f0 00 	movb   $0x0,0xf02173ac
f0103fac:	c6 05 ad 73 21 f0 8e 	movb   $0x8e,0xf02173ad
f0103fb3:	c1 e8 10             	shr    $0x10,%eax
f0103fb6:	66 a3 ae 73 21 f0    	mov    %ax,0xf02173ae
	SETGATE(idt[IRQ_OFFSET+10],0,GD_KT,IRQsHandler10,0);
f0103fbc:	b8 3c 47 10 f0       	mov    $0xf010473c,%eax
f0103fc1:	66 a3 b0 73 21 f0    	mov    %ax,0xf02173b0
f0103fc7:	66 c7 05 b2 73 21 f0 	movw   $0x8,0xf02173b2
f0103fce:	08 00 
f0103fd0:	c6 05 b4 73 21 f0 00 	movb   $0x0,0xf02173b4
f0103fd7:	c6 05 b5 73 21 f0 8e 	movb   $0x8e,0xf02173b5
f0103fde:	c1 e8 10             	shr    $0x10,%eax
f0103fe1:	66 a3 b6 73 21 f0    	mov    %ax,0xf02173b6
	SETGATE(idt[IRQ_OFFSET+11],0,GD_KT,IRQsHandler11,0);
f0103fe7:	b8 42 47 10 f0       	mov    $0xf0104742,%eax
f0103fec:	66 a3 b8 73 21 f0    	mov    %ax,0xf02173b8
f0103ff2:	66 c7 05 ba 73 21 f0 	movw   $0x8,0xf02173ba
f0103ff9:	08 00 
f0103ffb:	c6 05 bc 73 21 f0 00 	movb   $0x0,0xf02173bc
f0104002:	c6 05 bd 73 21 f0 8e 	movb   $0x8e,0xf02173bd
f0104009:	c1 e8 10             	shr    $0x10,%eax
f010400c:	66 a3 be 73 21 f0    	mov    %ax,0xf02173be
	SETGATE(idt[IRQ_OFFSET+12],0,GD_KT,IRQsHandler12,0);
f0104012:	b8 48 47 10 f0       	mov    $0xf0104748,%eax
f0104017:	66 a3 c0 73 21 f0    	mov    %ax,0xf02173c0
f010401d:	66 c7 05 c2 73 21 f0 	movw   $0x8,0xf02173c2
f0104024:	08 00 
f0104026:	c6 05 c4 73 21 f0 00 	movb   $0x0,0xf02173c4
f010402d:	c6 05 c5 73 21 f0 8e 	movb   $0x8e,0xf02173c5
f0104034:	c1 e8 10             	shr    $0x10,%eax
f0104037:	66 a3 c6 73 21 f0    	mov    %ax,0xf02173c6
	SETGATE(idt[IRQ_OFFSET+13],0,GD_KT,IRQsHandler13,0);
f010403d:	b8 4e 47 10 f0       	mov    $0xf010474e,%eax
f0104042:	66 a3 c8 73 21 f0    	mov    %ax,0xf02173c8
f0104048:	66 c7 05 ca 73 21 f0 	movw   $0x8,0xf02173ca
f010404f:	08 00 
f0104051:	c6 05 cc 73 21 f0 00 	movb   $0x0,0xf02173cc
f0104058:	c6 05 cd 73 21 f0 8e 	movb   $0x8e,0xf02173cd
f010405f:	c1 e8 10             	shr    $0x10,%eax
f0104062:	66 a3 ce 73 21 f0    	mov    %ax,0xf02173ce
	SETGATE(idt[IRQ_OFFSET+IRQ_IDE],0,GD_KT,IRQsHandler14,0);
f0104068:	b8 54 47 10 f0       	mov    $0xf0104754,%eax
f010406d:	66 a3 d0 73 21 f0    	mov    %ax,0xf02173d0
f0104073:	66 c7 05 d2 73 21 f0 	movw   $0x8,0xf02173d2
f010407a:	08 00 
f010407c:	c6 05 d4 73 21 f0 00 	movb   $0x0,0xf02173d4
f0104083:	c6 05 d5 73 21 f0 8e 	movb   $0x8e,0xf02173d5
f010408a:	c1 e8 10             	shr    $0x10,%eax
f010408d:	66 a3 d6 73 21 f0    	mov    %ax,0xf02173d6
	SETGATE(idt[IRQ_OFFSET+15],0,GD_KT,IRQsHandler15,0);
f0104093:	b8 5a 47 10 f0       	mov    $0xf010475a,%eax
f0104098:	66 a3 d8 73 21 f0    	mov    %ax,0xf02173d8
f010409e:	66 c7 05 da 73 21 f0 	movw   $0x8,0xf02173da
f01040a5:	08 00 
f01040a7:	c6 05 dc 73 21 f0 00 	movb   $0x0,0xf02173dc
f01040ae:	c6 05 dd 73 21 f0 8e 	movb   $0x8e,0xf02173dd
f01040b5:	c1 e8 10             	shr    $0x10,%eax
f01040b8:	66 a3 de 73 21 f0    	mov    %ax,0xf02173de
	trap_init_percpu();
f01040be:	e8 01 f9 ff ff       	call   f01039c4 <trap_init_percpu>
}
f01040c3:	c9                   	leave  
f01040c4:	c3                   	ret    

f01040c5 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01040c5:	f3 0f 1e fb          	endbr32 
f01040c9:	55                   	push   %ebp
f01040ca:	89 e5                	mov    %esp,%ebp
f01040cc:	53                   	push   %ebx
f01040cd:	83 ec 0c             	sub    $0xc,%esp
f01040d0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01040d3:	ff 33                	pushl  (%ebx)
f01040d5:	68 50 7b 10 f0       	push   $0xf0107b50
f01040da:	e8 cd f8 ff ff       	call   f01039ac <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01040df:	83 c4 08             	add    $0x8,%esp
f01040e2:	ff 73 04             	pushl  0x4(%ebx)
f01040e5:	68 5f 7b 10 f0       	push   $0xf0107b5f
f01040ea:	e8 bd f8 ff ff       	call   f01039ac <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01040ef:	83 c4 08             	add    $0x8,%esp
f01040f2:	ff 73 08             	pushl  0x8(%ebx)
f01040f5:	68 6e 7b 10 f0       	push   $0xf0107b6e
f01040fa:	e8 ad f8 ff ff       	call   f01039ac <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01040ff:	83 c4 08             	add    $0x8,%esp
f0104102:	ff 73 0c             	pushl  0xc(%ebx)
f0104105:	68 7d 7b 10 f0       	push   $0xf0107b7d
f010410a:	e8 9d f8 ff ff       	call   f01039ac <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f010410f:	83 c4 08             	add    $0x8,%esp
f0104112:	ff 73 10             	pushl  0x10(%ebx)
f0104115:	68 8c 7b 10 f0       	push   $0xf0107b8c
f010411a:	e8 8d f8 ff ff       	call   f01039ac <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f010411f:	83 c4 08             	add    $0x8,%esp
f0104122:	ff 73 14             	pushl  0x14(%ebx)
f0104125:	68 9b 7b 10 f0       	push   $0xf0107b9b
f010412a:	e8 7d f8 ff ff       	call   f01039ac <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f010412f:	83 c4 08             	add    $0x8,%esp
f0104132:	ff 73 18             	pushl  0x18(%ebx)
f0104135:	68 aa 7b 10 f0       	push   $0xf0107baa
f010413a:	e8 6d f8 ff ff       	call   f01039ac <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f010413f:	83 c4 08             	add    $0x8,%esp
f0104142:	ff 73 1c             	pushl  0x1c(%ebx)
f0104145:	68 b9 7b 10 f0       	push   $0xf0107bb9
f010414a:	e8 5d f8 ff ff       	call   f01039ac <cprintf>
}
f010414f:	83 c4 10             	add    $0x10,%esp
f0104152:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104155:	c9                   	leave  
f0104156:	c3                   	ret    

f0104157 <print_trapframe>:
{
f0104157:	f3 0f 1e fb          	endbr32 
f010415b:	55                   	push   %ebp
f010415c:	89 e5                	mov    %esp,%ebp
f010415e:	56                   	push   %esi
f010415f:	53                   	push   %ebx
f0104160:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0104163:	e8 e6 1f 00 00       	call   f010614e <cpunum>
f0104168:	83 ec 04             	sub    $0x4,%esp
f010416b:	50                   	push   %eax
f010416c:	53                   	push   %ebx
f010416d:	68 1d 7c 10 f0       	push   $0xf0107c1d
f0104172:	e8 35 f8 ff ff       	call   f01039ac <cprintf>
	print_regs(&tf->tf_regs);
f0104177:	89 1c 24             	mov    %ebx,(%esp)
f010417a:	e8 46 ff ff ff       	call   f01040c5 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f010417f:	83 c4 08             	add    $0x8,%esp
f0104182:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0104186:	50                   	push   %eax
f0104187:	68 3b 7c 10 f0       	push   $0xf0107c3b
f010418c:	e8 1b f8 ff ff       	call   f01039ac <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0104191:	83 c4 08             	add    $0x8,%esp
f0104194:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0104198:	50                   	push   %eax
f0104199:	68 4e 7c 10 f0       	push   $0xf0107c4e
f010419e:	e8 09 f8 ff ff       	call   f01039ac <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01041a3:	8b 43 28             	mov    0x28(%ebx),%eax
	if (trapno < ARRAY_SIZE(excnames))
f01041a6:	83 c4 10             	add    $0x10,%esp
f01041a9:	83 f8 13             	cmp    $0x13,%eax
f01041ac:	0f 86 da 00 00 00    	jbe    f010428c <print_trapframe+0x135>
		return "System call";
f01041b2:	ba c8 7b 10 f0       	mov    $0xf0107bc8,%edx
	if (trapno == T_SYSCALL)
f01041b7:	83 f8 30             	cmp    $0x30,%eax
f01041ba:	74 13                	je     f01041cf <print_trapframe+0x78>
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f01041bc:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
f01041bf:	83 fa 0f             	cmp    $0xf,%edx
f01041c2:	ba d4 7b 10 f0       	mov    $0xf0107bd4,%edx
f01041c7:	b9 e3 7b 10 f0       	mov    $0xf0107be3,%ecx
f01041cc:	0f 46 d1             	cmovbe %ecx,%edx
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01041cf:	83 ec 04             	sub    $0x4,%esp
f01041d2:	52                   	push   %edx
f01041d3:	50                   	push   %eax
f01041d4:	68 61 7c 10 f0       	push   $0xf0107c61
f01041d9:	e8 ce f7 ff ff       	call   f01039ac <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01041de:	83 c4 10             	add    $0x10,%esp
f01041e1:	39 1d 60 7a 21 f0    	cmp    %ebx,0xf0217a60
f01041e7:	0f 84 ab 00 00 00    	je     f0104298 <print_trapframe+0x141>
	cprintf("  err  0x%08x", tf->tf_err);
f01041ed:	83 ec 08             	sub    $0x8,%esp
f01041f0:	ff 73 2c             	pushl  0x2c(%ebx)
f01041f3:	68 82 7c 10 f0       	push   $0xf0107c82
f01041f8:	e8 af f7 ff ff       	call   f01039ac <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f01041fd:	83 c4 10             	add    $0x10,%esp
f0104200:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0104204:	0f 85 b1 00 00 00    	jne    f01042bb <print_trapframe+0x164>
			tf->tf_err & 1 ? "protection" : "not-present");
f010420a:	8b 43 2c             	mov    0x2c(%ebx),%eax
		cprintf(" [%s, %s, %s]\n",
f010420d:	a8 01                	test   $0x1,%al
f010420f:	b9 f6 7b 10 f0       	mov    $0xf0107bf6,%ecx
f0104214:	ba 01 7c 10 f0       	mov    $0xf0107c01,%edx
f0104219:	0f 44 ca             	cmove  %edx,%ecx
f010421c:	a8 02                	test   $0x2,%al
f010421e:	be 0d 7c 10 f0       	mov    $0xf0107c0d,%esi
f0104223:	ba 13 7c 10 f0       	mov    $0xf0107c13,%edx
f0104228:	0f 45 d6             	cmovne %esi,%edx
f010422b:	a8 04                	test   $0x4,%al
f010422d:	b8 18 7c 10 f0       	mov    $0xf0107c18,%eax
f0104232:	be 4d 7d 10 f0       	mov    $0xf0107d4d,%esi
f0104237:	0f 44 c6             	cmove  %esi,%eax
f010423a:	51                   	push   %ecx
f010423b:	52                   	push   %edx
f010423c:	50                   	push   %eax
f010423d:	68 90 7c 10 f0       	push   $0xf0107c90
f0104242:	e8 65 f7 ff ff       	call   f01039ac <cprintf>
f0104247:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010424a:	83 ec 08             	sub    $0x8,%esp
f010424d:	ff 73 30             	pushl  0x30(%ebx)
f0104250:	68 9f 7c 10 f0       	push   $0xf0107c9f
f0104255:	e8 52 f7 ff ff       	call   f01039ac <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f010425a:	83 c4 08             	add    $0x8,%esp
f010425d:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0104261:	50                   	push   %eax
f0104262:	68 ae 7c 10 f0       	push   $0xf0107cae
f0104267:	e8 40 f7 ff ff       	call   f01039ac <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010426c:	83 c4 08             	add    $0x8,%esp
f010426f:	ff 73 38             	pushl  0x38(%ebx)
f0104272:	68 c1 7c 10 f0       	push   $0xf0107cc1
f0104277:	e8 30 f7 ff ff       	call   f01039ac <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010427c:	83 c4 10             	add    $0x10,%esp
f010427f:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0104283:	75 4b                	jne    f01042d0 <print_trapframe+0x179>
}
f0104285:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0104288:	5b                   	pop    %ebx
f0104289:	5e                   	pop    %esi
f010428a:	5d                   	pop    %ebp
f010428b:	c3                   	ret    
		return excnames[trapno];
f010428c:	8b 14 85 e0 7f 10 f0 	mov    -0xfef8020(,%eax,4),%edx
f0104293:	e9 37 ff ff ff       	jmp    f01041cf <print_trapframe+0x78>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0104298:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010429c:	0f 85 4b ff ff ff    	jne    f01041ed <print_trapframe+0x96>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01042a2:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01042a5:	83 ec 08             	sub    $0x8,%esp
f01042a8:	50                   	push   %eax
f01042a9:	68 73 7c 10 f0       	push   $0xf0107c73
f01042ae:	e8 f9 f6 ff ff       	call   f01039ac <cprintf>
f01042b3:	83 c4 10             	add    $0x10,%esp
f01042b6:	e9 32 ff ff ff       	jmp    f01041ed <print_trapframe+0x96>
		cprintf("\n");
f01042bb:	83 ec 0c             	sub    $0xc,%esp
f01042be:	68 fd 79 10 f0       	push   $0xf01079fd
f01042c3:	e8 e4 f6 ff ff       	call   f01039ac <cprintf>
f01042c8:	83 c4 10             	add    $0x10,%esp
f01042cb:	e9 7a ff ff ff       	jmp    f010424a <print_trapframe+0xf3>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01042d0:	83 ec 08             	sub    $0x8,%esp
f01042d3:	ff 73 3c             	pushl  0x3c(%ebx)
f01042d6:	68 d0 7c 10 f0       	push   $0xf0107cd0
f01042db:	e8 cc f6 ff ff       	call   f01039ac <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01042e0:	83 c4 08             	add    $0x8,%esp
f01042e3:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01042e7:	50                   	push   %eax
f01042e8:	68 df 7c 10 f0       	push   $0xf0107cdf
f01042ed:	e8 ba f6 ff ff       	call   f01039ac <cprintf>
f01042f2:	83 c4 10             	add    $0x10,%esp
}
f01042f5:	eb 8e                	jmp    f0104285 <print_trapframe+0x12e>

f01042f7 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01042f7:	f3 0f 1e fb          	endbr32 
f01042fb:	55                   	push   %ebp
f01042fc:	89 e5                	mov    %esp,%ebp
f01042fe:	57                   	push   %edi
f01042ff:	56                   	push   %esi
f0104300:	53                   	push   %ebx
f0104301:	83 ec 1c             	sub    $0x1c,%esp
f0104304:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104307:	0f 20 d6             	mov    %cr2,%esi

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	// check low-bits of tf_cs
	if((tf->tf_cs & 3) == 0)
f010430a:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f010430e:	75 15                	jne    f0104325 <page_fault_handler+0x2e>
	{
		panic("At page_fault_handler: page fault at %08x.\n",fault_va);
f0104310:	56                   	push   %esi
f0104311:	68 98 7e 10 f0       	push   $0xf0107e98
f0104316:	68 b2 01 00 00       	push   $0x1b2
f010431b:	68 f2 7c 10 f0       	push   $0xf0107cf2
f0104320:	e8 1b bd ff ff       	call   f0100040 <_panic>
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	// no self-defined pgfault_upcall function
	if(curenv->env_pgfault_upcall == NULL)
f0104325:	e8 24 1e 00 00       	call   f010614e <cpunum>
f010432a:	6b c0 74             	imul   $0x74,%eax,%eax
f010432d:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0104333:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0104337:	0f 84 92 00 00 00    	je     f01043cf <page_fault_handler+0xd8>
	
	struct UTrapframe* utf;
	uintptr_t addr;
	// determine utf address
	size_t size = sizeof(struct UTrapframe)+ sizeof(uint32_t);
	if (tf->tf_esp >= UXSTACKTOP-PGSIZE && tf->tf_esp < UXSTACKTOP)
f010433d:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0104340:	8d 90 00 10 40 11    	lea    0x11401000(%eax),%edx
	{
		addr = tf->tf_esp - size;
	}
	else
	{
		addr = UXSTACKTOP - size;
f0104346:	c7 45 e4 c8 ff bf ee 	movl   $0xeebfffc8,-0x1c(%ebp)
	if (tf->tf_esp >= UXSTACKTOP-PGSIZE && tf->tf_esp < UXSTACKTOP)
f010434d:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f0104353:	77 06                	ja     f010435b <page_fault_handler+0x64>
		addr = tf->tf_esp - size;
f0104355:	83 e8 38             	sub    $0x38,%eax
f0104358:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	}
	// check the permission
	user_mem_assert(curenv,(void*)addr,size,PTE_P|PTE_W|PTE_U);
f010435b:	e8 ee 1d 00 00       	call   f010614e <cpunum>
f0104360:	6a 07                	push   $0x7
f0104362:	6a 38                	push   $0x38
f0104364:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104367:	57                   	push   %edi
f0104368:	6b c0 74             	imul   $0x74,%eax,%eax
f010436b:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0104371:	e8 78 ec ff ff       	call   f0102fee <user_mem_assert>

	// set the attributes
	utf = (struct UTrapframe*)addr;
	utf->utf_fault_va = fault_va;
f0104376:	89 37                	mov    %esi,(%edi)
	utf->utf_eflags = tf->tf_eflags;
f0104378:	8b 43 38             	mov    0x38(%ebx),%eax
f010437b:	89 47 2c             	mov    %eax,0x2c(%edi)
	utf->utf_err = tf->tf_err;
f010437e:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0104381:	89 47 04             	mov    %eax,0x4(%edi)
	utf->utf_esp = tf->tf_esp;
f0104384:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0104387:	89 47 30             	mov    %eax,0x30(%edi)
	utf->utf_eip = tf->tf_eip;
f010438a:	8b 43 30             	mov    0x30(%ebx),%eax
f010438d:	89 47 28             	mov    %eax,0x28(%edi)
	utf->utf_regs = tf->tf_regs;
f0104390:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0104393:	8d 7f 08             	lea    0x8(%edi),%edi
f0104396:	b9 08 00 00 00       	mov    $0x8,%ecx
f010439b:	89 de                	mov    %ebx,%esi
f010439d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	// change the value in eip field of tf
	tf->tf_eip = (uintptr_t)curenv->env_pgfault_upcall;
f010439f:	e8 aa 1d 00 00       	call   f010614e <cpunum>
f01043a4:	6b c0 74             	imul   $0x74,%eax,%eax
f01043a7:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01043ad:	8b 40 64             	mov    0x64(%eax),%eax
f01043b0:	89 43 30             	mov    %eax,0x30(%ebx)
	tf->tf_esp = (uintptr_t)utf;
f01043b3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01043b6:	89 53 3c             	mov    %edx,0x3c(%ebx)
	env_run(curenv);
f01043b9:	e8 90 1d 00 00       	call   f010614e <cpunum>
f01043be:	83 c4 04             	add    $0x4,%esp
f01043c1:	6b c0 74             	imul   $0x74,%eax,%eax
f01043c4:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f01043ca:	e8 5f f3 ff ff       	call   f010372e <env_run>
		cprintf("[%08x] user fault va %08x ip %08x\n",
f01043cf:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f01043d2:	e8 77 1d 00 00       	call   f010614e <cpunum>
		cprintf("[%08x] user fault va %08x ip %08x\n",
f01043d7:	57                   	push   %edi
f01043d8:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f01043d9:	6b c0 74             	imul   $0x74,%eax,%eax
		cprintf("[%08x] user fault va %08x ip %08x\n",
f01043dc:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01043e2:	ff 70 48             	pushl  0x48(%eax)
f01043e5:	68 c4 7e 10 f0       	push   $0xf0107ec4
f01043ea:	e8 bd f5 ff ff       	call   f01039ac <cprintf>
		print_trapframe(tf);
f01043ef:	89 1c 24             	mov    %ebx,(%esp)
f01043f2:	e8 60 fd ff ff       	call   f0104157 <print_trapframe>
		env_destroy(curenv);
f01043f7:	e8 52 1d 00 00       	call   f010614e <cpunum>
f01043fc:	83 c4 04             	add    $0x4,%esp
f01043ff:	6b c0 74             	imul   $0x74,%eax,%eax
f0104402:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0104408:	e8 7a f2 ff ff       	call   f0103687 <env_destroy>
f010440d:	83 c4 10             	add    $0x10,%esp
f0104410:	e9 28 ff ff ff       	jmp    f010433d <page_fault_handler+0x46>

f0104415 <trap>:
{
f0104415:	f3 0f 1e fb          	endbr32 
f0104419:	55                   	push   %ebp
f010441a:	89 e5                	mov    %esp,%ebp
f010441c:	57                   	push   %edi
f010441d:	56                   	push   %esi
f010441e:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::: "cc");
f0104421:	fc                   	cld    
	if (panicstr)
f0104422:	83 3d 80 7e 21 f0 00 	cmpl   $0x0,0xf0217e80
f0104429:	74 01                	je     f010442c <trap+0x17>
		asm volatile("hlt");
f010442b:	f4                   	hlt    
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f010442c:	e8 1d 1d 00 00       	call   f010614e <cpunum>
f0104431:	6b d0 74             	imul   $0x74,%eax,%edx
f0104434:	83 c2 04             	add    $0x4,%edx
	asm volatile("lock; xchgl %0, %1"
f0104437:	b8 01 00 00 00       	mov    $0x1,%eax
f010443c:	f0 87 82 20 80 21 f0 	lock xchg %eax,-0xfde7fe0(%edx)
f0104443:	83 f8 02             	cmp    $0x2,%eax
f0104446:	74 37                	je     f010447f <trap+0x6a>
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0104448:	9c                   	pushf  
f0104449:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
f010444a:	f6 c4 02             	test   $0x2,%ah
f010444d:	75 42                	jne    f0104491 <trap+0x7c>
	if ((tf->tf_cs & 3) == 3) {
f010444f:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104453:	83 e0 03             	and    $0x3,%eax
f0104456:	66 83 f8 03          	cmp    $0x3,%ax
f010445a:	74 4e                	je     f01044aa <trap+0x95>
	last_tf = tf;
f010445c:	89 35 60 7a 21 f0    	mov    %esi,0xf0217a60
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0104462:	8b 46 28             	mov    0x28(%esi),%eax
f0104465:	83 f8 27             	cmp    $0x27,%eax
f0104468:	0f 84 e1 00 00 00    	je     f010454f <trap+0x13a>
f010446e:	83 f8 30             	cmp    $0x30,%eax
f0104471:	0f 87 7c 01 00 00    	ja     f01045f3 <trap+0x1de>
f0104477:	3e ff 24 85 00 7f 10 	notrack jmp *-0xfef8100(,%eax,4)
f010447e:	f0 
	spin_lock(&kernel_lock);
f010447f:	83 ec 0c             	sub    $0xc,%esp
f0104482:	68 c0 33 12 f0       	push   $0xf01233c0
f0104487:	e8 4a 1f 00 00       	call   f01063d6 <spin_lock>
}
f010448c:	83 c4 10             	add    $0x10,%esp
f010448f:	eb b7                	jmp    f0104448 <trap+0x33>
	assert(!(read_eflags() & FL_IF));
f0104491:	68 fe 7c 10 f0       	push   $0xf0107cfe
f0104496:	68 43 77 10 f0       	push   $0xf0107743
f010449b:	68 7a 01 00 00       	push   $0x17a
f01044a0:	68 f2 7c 10 f0       	push   $0xf0107cf2
f01044a5:	e8 96 bb ff ff       	call   f0100040 <_panic>
	spin_lock(&kernel_lock);
f01044aa:	83 ec 0c             	sub    $0xc,%esp
f01044ad:	68 c0 33 12 f0       	push   $0xf01233c0
f01044b2:	e8 1f 1f 00 00       	call   f01063d6 <spin_lock>
		assert(curenv);
f01044b7:	e8 92 1c 00 00       	call   f010614e <cpunum>
f01044bc:	6b c0 74             	imul   $0x74,%eax,%eax
f01044bf:	83 c4 10             	add    $0x10,%esp
f01044c2:	83 b8 28 80 21 f0 00 	cmpl   $0x0,-0xfde7fd8(%eax)
f01044c9:	74 3e                	je     f0104509 <trap+0xf4>
		if (curenv->env_status == ENV_DYING) {
f01044cb:	e8 7e 1c 00 00       	call   f010614e <cpunum>
f01044d0:	6b c0 74             	imul   $0x74,%eax,%eax
f01044d3:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01044d9:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f01044dd:	74 43                	je     f0104522 <trap+0x10d>
		curenv->env_tf = *tf;
f01044df:	e8 6a 1c 00 00       	call   f010614e <cpunum>
f01044e4:	6b c0 74             	imul   $0x74,%eax,%eax
f01044e7:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01044ed:	b9 11 00 00 00       	mov    $0x11,%ecx
f01044f2:	89 c7                	mov    %eax,%edi
f01044f4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &curenv->env_tf;
f01044f6:	e8 53 1c 00 00       	call   f010614e <cpunum>
f01044fb:	6b c0 74             	imul   $0x74,%eax,%eax
f01044fe:	8b b0 28 80 21 f0    	mov    -0xfde7fd8(%eax),%esi
f0104504:	e9 53 ff ff ff       	jmp    f010445c <trap+0x47>
		assert(curenv);
f0104509:	68 17 7d 10 f0       	push   $0xf0107d17
f010450e:	68 43 77 10 f0       	push   $0xf0107743
f0104513:	68 82 01 00 00       	push   $0x182
f0104518:	68 f2 7c 10 f0       	push   $0xf0107cf2
f010451d:	e8 1e bb ff ff       	call   f0100040 <_panic>
			env_free(curenv);
f0104522:	e8 27 1c 00 00       	call   f010614e <cpunum>
f0104527:	83 ec 0c             	sub    $0xc,%esp
f010452a:	6b c0 74             	imul   $0x74,%eax,%eax
f010452d:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0104533:	e8 a1 ef ff ff       	call   f01034d9 <env_free>
			curenv = NULL;
f0104538:	e8 11 1c 00 00       	call   f010614e <cpunum>
f010453d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104540:	c7 80 28 80 21 f0 00 	movl   $0x0,-0xfde7fd8(%eax)
f0104547:	00 00 00 
			sched_yield();
f010454a:	e8 f6 02 00 00       	call   f0104845 <sched_yield>
		cprintf("Spurious interrupt on irq 7\n");
f010454f:	83 ec 0c             	sub    $0xc,%esp
f0104552:	68 1e 7d 10 f0       	push   $0xf0107d1e
f0104557:	e8 50 f4 ff ff       	call   f01039ac <cprintf>
		print_trapframe(tf);
f010455c:	89 34 24             	mov    %esi,(%esp)
f010455f:	e8 f3 fb ff ff       	call   f0104157 <print_trapframe>
		return;
f0104564:	83 c4 10             	add    $0x10,%esp
f0104567:	eb 15                	jmp    f010457e <trap+0x169>
			page_fault_handler(tf);
f0104569:	83 ec 0c             	sub    $0xc,%esp
f010456c:	56                   	push   %esi
f010456d:	e8 85 fd ff ff       	call   f01042f7 <page_fault_handler>
			monitor(tf);
f0104572:	83 ec 0c             	sub    $0xc,%esp
f0104575:	56                   	push   %esi
f0104576:	e8 2e c4 ff ff       	call   f01009a9 <monitor>
			return;
f010457b:	83 c4 10             	add    $0x10,%esp
	if (curenv && curenv->env_status == ENV_RUNNING)
f010457e:	e8 cb 1b 00 00       	call   f010614e <cpunum>
f0104583:	6b c0 74             	imul   $0x74,%eax,%eax
f0104586:	83 b8 28 80 21 f0 00 	cmpl   $0x0,-0xfde7fd8(%eax)
f010458d:	74 18                	je     f01045a7 <trap+0x192>
f010458f:	e8 ba 1b 00 00       	call   f010614e <cpunum>
f0104594:	6b c0 74             	imul   $0x74,%eax,%eax
f0104597:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f010459d:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01045a1:	0f 84 94 00 00 00    	je     f010463b <trap+0x226>
		sched_yield();
f01045a7:	e8 99 02 00 00       	call   f0104845 <sched_yield>
			monitor(tf);
f01045ac:	83 ec 0c             	sub    $0xc,%esp
f01045af:	56                   	push   %esi
f01045b0:	e8 f4 c3 ff ff       	call   f01009a9 <monitor>
			return;
f01045b5:	83 c4 10             	add    $0x10,%esp
f01045b8:	eb c4                	jmp    f010457e <trap+0x169>
			int32_t ret = syscall(regs->reg_eax,regs->reg_edx,regs->reg_ecx,regs->reg_ebx,regs->reg_edi,regs->reg_esi);
f01045ba:	83 ec 08             	sub    $0x8,%esp
f01045bd:	ff 76 04             	pushl  0x4(%esi)
f01045c0:	ff 36                	pushl  (%esi)
f01045c2:	ff 76 10             	pushl  0x10(%esi)
f01045c5:	ff 76 18             	pushl  0x18(%esi)
f01045c8:	ff 76 14             	pushl  0x14(%esi)
f01045cb:	ff 76 1c             	pushl  0x1c(%esi)
f01045ce:	e8 2a 03 00 00       	call   f01048fd <syscall>
			regs->reg_eax = (uint32_t)ret;
f01045d3:	89 46 1c             	mov    %eax,0x1c(%esi)
			return;
f01045d6:	83 c4 20             	add    $0x20,%esp
f01045d9:	eb a3                	jmp    f010457e <trap+0x169>
			lapic_eoi();
f01045db:	e8 bd 1c 00 00       	call   f010629d <lapic_eoi>
			sched_yield();
f01045e0:	e8 60 02 00 00       	call   f0104845 <sched_yield>
			kbd_intr();
f01045e5:	e8 28 c0 ff ff       	call   f0100612 <kbd_intr>
			return;
f01045ea:	eb 92                	jmp    f010457e <trap+0x169>
			serial_intr();
f01045ec:	e8 01 c0 ff ff       	call   f01005f2 <serial_intr>
			return;
f01045f1:	eb 8b                	jmp    f010457e <trap+0x169>
	print_trapframe(tf);
f01045f3:	83 ec 0c             	sub    $0xc,%esp
f01045f6:	56                   	push   %esi
f01045f7:	e8 5b fb ff ff       	call   f0104157 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01045fc:	83 c4 10             	add    $0x10,%esp
f01045ff:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0104604:	74 1e                	je     f0104624 <trap+0x20f>
		env_destroy(curenv);
f0104606:	e8 43 1b 00 00       	call   f010614e <cpunum>
f010460b:	83 ec 0c             	sub    $0xc,%esp
f010460e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104611:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0104617:	e8 6b f0 ff ff       	call   f0103687 <env_destroy>
		return;
f010461c:	83 c4 10             	add    $0x10,%esp
f010461f:	e9 5a ff ff ff       	jmp    f010457e <trap+0x169>
		panic("unhandled trap in kernel");
f0104624:	83 ec 04             	sub    $0x4,%esp
f0104627:	68 3b 7d 10 f0       	push   $0xf0107d3b
f010462c:	68 60 01 00 00       	push   $0x160
f0104631:	68 f2 7c 10 f0       	push   $0xf0107cf2
f0104636:	e8 05 ba ff ff       	call   f0100040 <_panic>
		env_run(curenv);
f010463b:	e8 0e 1b 00 00       	call   f010614e <cpunum>
f0104640:	83 ec 0c             	sub    $0xc,%esp
f0104643:	6b c0 74             	imul   $0x74,%eax,%eax
f0104646:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f010464c:	e8 dd f0 ff ff       	call   f010372e <env_run>
f0104651:	90                   	nop

f0104652 <DIVIDE>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
 # faults and interrupts
TRAPHANDLER_NOEC(DIVIDE,T_DIVIDE)
f0104652:	6a 00                	push   $0x0
f0104654:	6a 00                	push   $0x0
f0104656:	e9 0b 01 00 00       	jmp    f0104766 <_alltraps>
f010465b:	90                   	nop

f010465c <DEBUG>:
TRAPHANDLER_NOEC(DEBUG,T_DEBUG)
f010465c:	6a 00                	push   $0x0
f010465e:	6a 01                	push   $0x1
f0104660:	e9 01 01 00 00       	jmp    f0104766 <_alltraps>
f0104665:	90                   	nop

f0104666 <NMI>:
TRAPHANDLER_NOEC(NMI, T_NMI)
f0104666:	6a 00                	push   $0x0
f0104668:	6a 02                	push   $0x2
f010466a:	e9 f7 00 00 00       	jmp    f0104766 <_alltraps>
f010466f:	90                   	nop

f0104670 <BRKPT>:
TRAPHANDLER_NOEC(BRKPT, T_BRKPT)
f0104670:	6a 00                	push   $0x0
f0104672:	6a 03                	push   $0x3
f0104674:	e9 ed 00 00 00       	jmp    f0104766 <_alltraps>
f0104679:	90                   	nop

f010467a <OFLOW>:
TRAPHANDLER_NOEC(OFLOW, T_OFLOW)
f010467a:	6a 00                	push   $0x0
f010467c:	6a 04                	push   $0x4
f010467e:	e9 e3 00 00 00       	jmp    f0104766 <_alltraps>
f0104683:	90                   	nop

f0104684 <BOUND>:
TRAPHANDLER_NOEC(BOUND, T_BOUND)
f0104684:	6a 00                	push   $0x0
f0104686:	6a 05                	push   $0x5
f0104688:	e9 d9 00 00 00       	jmp    f0104766 <_alltraps>
f010468d:	90                   	nop

f010468e <ILLOP>:
TRAPHANDLER_NOEC(ILLOP, T_ILLOP)
f010468e:	6a 00                	push   $0x0
f0104690:	6a 06                	push   $0x6
f0104692:	e9 cf 00 00 00       	jmp    f0104766 <_alltraps>
f0104697:	90                   	nop

f0104698 <DEVICE>:
TRAPHANDLER_NOEC(DEVICE, T_DEVICE)
f0104698:	6a 00                	push   $0x0
f010469a:	6a 07                	push   $0x7
f010469c:	e9 c5 00 00 00       	jmp    f0104766 <_alltraps>
f01046a1:	90                   	nop

f01046a2 <DBLFLT>:
TRAPHANDLER(DBLFLT, T_DBLFLT)
f01046a2:	6a 08                	push   $0x8
f01046a4:	e9 bd 00 00 00       	jmp    f0104766 <_alltraps>
f01046a9:	90                   	nop

f01046aa <TSS>:
TRAPHANDLER(TSS, T_TSS)
f01046aa:	6a 0a                	push   $0xa
f01046ac:	e9 b5 00 00 00       	jmp    f0104766 <_alltraps>
f01046b1:	90                   	nop

f01046b2 <SEGNP>:
TRAPHANDLER(SEGNP, T_SEGNP)
f01046b2:	6a 0b                	push   $0xb
f01046b4:	e9 ad 00 00 00       	jmp    f0104766 <_alltraps>
f01046b9:	90                   	nop

f01046ba <STACK>:
TRAPHANDLER(STACK, T_STACK)
f01046ba:	6a 0c                	push   $0xc
f01046bc:	e9 a5 00 00 00       	jmp    f0104766 <_alltraps>
f01046c1:	90                   	nop

f01046c2 <GPFLT>:
TRAPHANDLER(GPFLT, T_GPFLT)
f01046c2:	6a 0d                	push   $0xd
f01046c4:	e9 9d 00 00 00       	jmp    f0104766 <_alltraps>
f01046c9:	90                   	nop

f01046ca <PGFLT>:
TRAPHANDLER(PGFLT, T_PGFLT)
f01046ca:	6a 0e                	push   $0xe
f01046cc:	e9 95 00 00 00       	jmp    f0104766 <_alltraps>
f01046d1:	90                   	nop

f01046d2 <FPERR>:
TRAPHANDLER_NOEC(FPERR, T_FPERR)
f01046d2:	6a 00                	push   $0x0
f01046d4:	6a 10                	push   $0x10
f01046d6:	e9 8b 00 00 00       	jmp    f0104766 <_alltraps>
f01046db:	90                   	nop

f01046dc <ALIGN>:
TRAPHANDLER(ALIGN, T_ALIGN)
f01046dc:	6a 11                	push   $0x11
f01046de:	e9 83 00 00 00       	jmp    f0104766 <_alltraps>
f01046e3:	90                   	nop

f01046e4 <MCHK>:
TRAPHANDLER_NOEC(MCHK, T_MCHK)
f01046e4:	6a 00                	push   $0x0
f01046e6:	6a 12                	push   $0x12
f01046e8:	eb 7c                	jmp    f0104766 <_alltraps>

f01046ea <SIMDERR>:
TRAPHANDLER_NOEC(SIMDERR, T_SIMDERR)
f01046ea:	6a 00                	push   $0x0
f01046ec:	6a 13                	push   $0x13
f01046ee:	eb 76                	jmp    f0104766 <_alltraps>

f01046f0 <SYSCALL>:
TRAPHANDLER_NOEC(SYSCALL, T_SYSCALL)
f01046f0:	6a 00                	push   $0x0
f01046f2:	6a 30                	push   $0x30
f01046f4:	eb 70                	jmp    f0104766 <_alltraps>

f01046f6 <DEFAULT>:
TRAPHANDLER_NOEC(DEFAULT, T_DEFAULT)
f01046f6:	6a 00                	push   $0x0
f01046f8:	68 f4 01 00 00       	push   $0x1f4
f01046fd:	eb 67                	jmp    f0104766 <_alltraps>
f01046ff:	90                   	nop

f0104700 <IRQsHandler0>:
# IRQs
TRAPHANDLER_NOEC(IRQsHandler0, IRQ_OFFSET+IRQ_TIMER)
f0104700:	6a 00                	push   $0x0
f0104702:	6a 20                	push   $0x20
f0104704:	eb 60                	jmp    f0104766 <_alltraps>

f0104706 <IRQsHandler1>:
TRAPHANDLER_NOEC(IRQsHandler1, IRQ_OFFSET+IRQ_KBD)
f0104706:	6a 00                	push   $0x0
f0104708:	6a 21                	push   $0x21
f010470a:	eb 5a                	jmp    f0104766 <_alltraps>

f010470c <IRQsHandler2>:
TRAPHANDLER_NOEC(IRQsHandler2, IRQ_OFFSET+IRQ_SLAVE)
f010470c:	6a 00                	push   $0x0
f010470e:	6a 22                	push   $0x22
f0104710:	eb 54                	jmp    f0104766 <_alltraps>

f0104712 <IRQsHandler3>:
TRAPHANDLER_NOEC(IRQsHandler3, IRQ_OFFSET+3)
f0104712:	6a 00                	push   $0x0
f0104714:	6a 23                	push   $0x23
f0104716:	eb 4e                	jmp    f0104766 <_alltraps>

f0104718 <IRQsHandler4>:
TRAPHANDLER_NOEC(IRQsHandler4, IRQ_OFFSET+IRQ_SERIAL)
f0104718:	6a 00                	push   $0x0
f010471a:	6a 24                	push   $0x24
f010471c:	eb 48                	jmp    f0104766 <_alltraps>

f010471e <IRQsHandler5>:
TRAPHANDLER_NOEC(IRQsHandler5, IRQ_OFFSET+5)
f010471e:	6a 00                	push   $0x0
f0104720:	6a 25                	push   $0x25
f0104722:	eb 42                	jmp    f0104766 <_alltraps>

f0104724 <IRQsHandler6>:
TRAPHANDLER_NOEC(IRQsHandler6, IRQ_OFFSET+6)
f0104724:	6a 00                	push   $0x0
f0104726:	6a 26                	push   $0x26
f0104728:	eb 3c                	jmp    f0104766 <_alltraps>

f010472a <IRQsHandler7>:
TRAPHANDLER_NOEC(IRQsHandler7, IRQ_OFFSET+IRQ_SPURIOUS)
f010472a:	6a 00                	push   $0x0
f010472c:	6a 27                	push   $0x27
f010472e:	eb 36                	jmp    f0104766 <_alltraps>

f0104730 <IRQsHandler8>:
TRAPHANDLER_NOEC(IRQsHandler8, IRQ_OFFSET+8)
f0104730:	6a 00                	push   $0x0
f0104732:	6a 28                	push   $0x28
f0104734:	eb 30                	jmp    f0104766 <_alltraps>

f0104736 <IRQsHandler9>:
TRAPHANDLER_NOEC(IRQsHandler9, IRQ_OFFSET+9)
f0104736:	6a 00                	push   $0x0
f0104738:	6a 29                	push   $0x29
f010473a:	eb 2a                	jmp    f0104766 <_alltraps>

f010473c <IRQsHandler10>:
TRAPHANDLER_NOEC(IRQsHandler10, IRQ_OFFSET+10)
f010473c:	6a 00                	push   $0x0
f010473e:	6a 2a                	push   $0x2a
f0104740:	eb 24                	jmp    f0104766 <_alltraps>

f0104742 <IRQsHandler11>:
TRAPHANDLER_NOEC(IRQsHandler11, IRQ_OFFSET+11)
f0104742:	6a 00                	push   $0x0
f0104744:	6a 2b                	push   $0x2b
f0104746:	eb 1e                	jmp    f0104766 <_alltraps>

f0104748 <IRQsHandler12>:
TRAPHANDLER_NOEC(IRQsHandler12, IRQ_OFFSET+12)
f0104748:	6a 00                	push   $0x0
f010474a:	6a 2c                	push   $0x2c
f010474c:	eb 18                	jmp    f0104766 <_alltraps>

f010474e <IRQsHandler13>:
TRAPHANDLER_NOEC(IRQsHandler13, IRQ_OFFSET+13)
f010474e:	6a 00                	push   $0x0
f0104750:	6a 2d                	push   $0x2d
f0104752:	eb 12                	jmp    f0104766 <_alltraps>

f0104754 <IRQsHandler14>:
TRAPHANDLER_NOEC(IRQsHandler14, IRQ_OFFSET+IRQ_IDE)
f0104754:	6a 00                	push   $0x0
f0104756:	6a 2e                	push   $0x2e
f0104758:	eb 0c                	jmp    f0104766 <_alltraps>

f010475a <IRQsHandler15>:
TRAPHANDLER_NOEC(IRQsHandler15, IRQ_OFFSET+15)
f010475a:	6a 00                	push   $0x0
f010475c:	6a 2f                	push   $0x2f
f010475e:	eb 06                	jmp    f0104766 <_alltraps>

f0104760 <IRQsHandler19>:
; TRAPHANDLER_NOEC(IRQsHandler19, IRQ_OFFSET+IRQ_ERROR)
f0104760:	6a 00                	push   $0x0
f0104762:	6a 33                	push   $0x33
f0104764:	eb 00                	jmp    f0104766 <_alltraps>

f0104766 <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */
 .global _alltraps
 _alltraps:
 /* code below according to the guide */
pushl %ds
f0104766:	1e                   	push   %ds
pushl %es
f0104767:	06                   	push   %es
pushal
f0104768:	60                   	pusha  
movw $GD_KD, %ax
f0104769:	66 b8 10 00          	mov    $0x10,%ax
movw %ax, %ds
f010476d:	8e d8                	mov    %eax,%ds
movw %ax, %es
f010476f:	8e c0                	mov    %eax,%es
pushl %esp
f0104771:	54                   	push   %esp
call trap
f0104772:	e8 9e fc ff ff       	call   f0104415 <trap>

f0104777 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104777:	f3 0f 1e fb          	endbr32 
f010477b:	55                   	push   %ebp
f010477c:	89 e5                	mov    %esp,%ebp
f010477e:	83 ec 08             	sub    $0x8,%esp
f0104781:	a1 48 72 21 f0       	mov    0xf0217248,%eax
f0104786:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104789:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f010478e:	8b 02                	mov    (%edx),%eax
f0104790:	83 e8 01             	sub    $0x1,%eax
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104793:	83 f8 02             	cmp    $0x2,%eax
f0104796:	76 2d                	jbe    f01047c5 <sched_halt+0x4e>
	for (i = 0; i < NENV; i++) {
f0104798:	83 c1 01             	add    $0x1,%ecx
f010479b:	83 c2 7c             	add    $0x7c,%edx
f010479e:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f01047a4:	75 e8                	jne    f010478e <sched_halt+0x17>
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
		cprintf("No runnable environments in the system!\n");
f01047a6:	83 ec 0c             	sub    $0xc,%esp
f01047a9:	68 30 80 10 f0       	push   $0xf0108030
f01047ae:	e8 f9 f1 ff ff       	call   f01039ac <cprintf>
f01047b3:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f01047b6:	83 ec 0c             	sub    $0xc,%esp
f01047b9:	6a 00                	push   $0x0
f01047bb:	e8 e9 c1 ff ff       	call   f01009a9 <monitor>
f01047c0:	83 c4 10             	add    $0x10,%esp
f01047c3:	eb f1                	jmp    f01047b6 <sched_halt+0x3f>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f01047c5:	e8 84 19 00 00       	call   f010614e <cpunum>
f01047ca:	6b c0 74             	imul   $0x74,%eax,%eax
f01047cd:	c7 80 28 80 21 f0 00 	movl   $0x0,-0xfde7fd8(%eax)
f01047d4:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f01047d7:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01047dc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01047e1:	76 50                	jbe    f0104833 <sched_halt+0xbc>
	return (physaddr_t)kva - KERNBASE;
f01047e3:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01047e8:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f01047eb:	e8 5e 19 00 00       	call   f010614e <cpunum>
f01047f0:	6b d0 74             	imul   $0x74,%eax,%edx
f01047f3:	83 c2 04             	add    $0x4,%edx
	asm volatile("lock; xchgl %0, %1"
f01047f6:	b8 02 00 00 00       	mov    $0x2,%eax
f01047fb:	f0 87 82 20 80 21 f0 	lock xchg %eax,-0xfde7fe0(%edx)
	spin_unlock(&kernel_lock);
f0104802:	83 ec 0c             	sub    $0xc,%esp
f0104805:	68 c0 33 12 f0       	push   $0xf01233c0
f010480a:	e8 65 1c 00 00       	call   f0106474 <spin_unlock>
	asm volatile("pause");
f010480f:	f3 90                	pause  
		// Uncomment the following line after completing exercise 13
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104811:	e8 38 19 00 00       	call   f010614e <cpunum>
f0104816:	6b c0 74             	imul   $0x74,%eax,%eax
	asm volatile (
f0104819:	8b 80 30 80 21 f0    	mov    -0xfde7fd0(%eax),%eax
f010481f:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104824:	89 c4                	mov    %eax,%esp
f0104826:	6a 00                	push   $0x0
f0104828:	6a 00                	push   $0x0
f010482a:	fb                   	sti    
f010482b:	f4                   	hlt    
f010482c:	eb fd                	jmp    f010482b <sched_halt+0xb4>
}
f010482e:	83 c4 10             	add    $0x10,%esp
f0104831:	c9                   	leave  
f0104832:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104833:	50                   	push   %eax
f0104834:	68 08 68 10 f0       	push   $0xf0106808
f0104839:	6a 56                	push   $0x56
f010483b:	68 59 80 10 f0       	push   $0xf0108059
f0104840:	e8 fb b7 ff ff       	call   f0100040 <_panic>

f0104845 <sched_yield>:
{
f0104845:	f3 0f 1e fb          	endbr32 
f0104849:	55                   	push   %ebp
f010484a:	89 e5                	mov    %esp,%ebp
f010484c:	56                   	push   %esi
f010484d:	53                   	push   %ebx
	if(curenv)
f010484e:	e8 fb 18 00 00       	call   f010614e <cpunum>
f0104853:	6b c0 74             	imul   $0x74,%eax,%eax
	int begin = 0;
f0104856:	b9 00 00 00 00       	mov    $0x0,%ecx
	if(curenv)
f010485b:	83 b8 28 80 21 f0 00 	cmpl   $0x0,-0xfde7fd8(%eax)
f0104862:	74 17                	je     f010487b <sched_yield+0x36>
		begin = ENVX(curenv->env_id);
f0104864:	e8 e5 18 00 00       	call   f010614e <cpunum>
f0104869:	6b c0 74             	imul   $0x74,%eax,%eax
f010486c:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0104872:	8b 48 48             	mov    0x48(%eax),%ecx
f0104875:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
		idle = &envs[(i+begin)%NENV];
f010487b:	8b 1d 48 72 21 f0    	mov    0xf0217248,%ebx
f0104881:	89 ca                	mov    %ecx,%edx
f0104883:	81 c1 00 04 00 00    	add    $0x400,%ecx
f0104889:	89 d6                	mov    %edx,%esi
f010488b:	c1 fe 1f             	sar    $0x1f,%esi
f010488e:	c1 ee 16             	shr    $0x16,%esi
f0104891:	8d 04 32             	lea    (%edx,%esi,1),%eax
f0104894:	25 ff 03 00 00       	and    $0x3ff,%eax
f0104899:	29 f0                	sub    %esi,%eax
f010489b:	6b c0 7c             	imul   $0x7c,%eax,%eax
f010489e:	01 d8                	add    %ebx,%eax
		if(idle->env_status == ENV_RUNNABLE)
f01048a0:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f01048a4:	74 38                	je     f01048de <sched_yield+0x99>
f01048a6:	83 c2 01             	add    $0x1,%edx
	for(int i = 0;i<NENV;i++)
f01048a9:	39 ca                	cmp    %ecx,%edx
f01048ab:	75 dc                	jne    f0104889 <sched_yield+0x44>
	if(!flag && curenv && curenv->env_status == ENV_RUNNING)
f01048ad:	e8 9c 18 00 00       	call   f010614e <cpunum>
f01048b2:	6b c0 74             	imul   $0x74,%eax,%eax
f01048b5:	83 b8 28 80 21 f0 00 	cmpl   $0x0,-0xfde7fd8(%eax)
f01048bc:	74 14                	je     f01048d2 <sched_yield+0x8d>
f01048be:	e8 8b 18 00 00       	call   f010614e <cpunum>
f01048c3:	6b c0 74             	imul   $0x74,%eax,%eax
f01048c6:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01048cc:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01048d0:	74 15                	je     f01048e7 <sched_yield+0xa2>
		sched_halt();
f01048d2:	e8 a0 fe ff ff       	call   f0104777 <sched_halt>
}
f01048d7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01048da:	5b                   	pop    %ebx
f01048db:	5e                   	pop    %esi
f01048dc:	5d                   	pop    %ebp
f01048dd:	c3                   	ret    
			env_run(idle);
f01048de:	83 ec 0c             	sub    $0xc,%esp
f01048e1:	50                   	push   %eax
f01048e2:	e8 47 ee ff ff       	call   f010372e <env_run>
		env_run(curenv);
f01048e7:	e8 62 18 00 00       	call   f010614e <cpunum>
f01048ec:	83 ec 0c             	sub    $0xc,%esp
f01048ef:	6b c0 74             	imul   $0x74,%eax,%eax
f01048f2:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f01048f8:	e8 31 ee ff ff       	call   f010372e <env_run>

f01048fd <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01048fd:	f3 0f 1e fb          	endbr32 
f0104901:	55                   	push   %ebp
f0104902:	89 e5                	mov    %esp,%ebp
f0104904:	57                   	push   %edi
f0104905:	56                   	push   %esi
f0104906:	53                   	push   %ebx
f0104907:	83 ec 1c             	sub    $0x1c,%esp
f010490a:	8b 45 08             	mov    0x8(%ebp),%eax
f010490d:	83 f8 0e             	cmp    $0xe,%eax
f0104910:	77 08                	ja     f010491a <syscall+0x1d>
f0104912:	3e ff 24 85 6c 80 10 	notrack jmp *-0xfef7f94(,%eax,4)
f0104919:	f0 
	switch (syscallno) 
	{
		case SYS_cputs:
		{
			sys_cputs((const char*)a1,(size_t)a2);
			return 0;
f010491a:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010491f:	e9 c7 05 00 00       	jmp    f0104eeb <syscall+0x5ee>
	user_mem_assert(curenv,s,len,0);
f0104924:	e8 25 18 00 00       	call   f010614e <cpunum>
f0104929:	6a 00                	push   $0x0
f010492b:	ff 75 10             	pushl  0x10(%ebp)
f010492e:	ff 75 0c             	pushl  0xc(%ebp)
f0104931:	6b c0 74             	imul   $0x74,%eax,%eax
f0104934:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f010493a:	e8 af e6 ff ff       	call   f0102fee <user_mem_assert>
	cprintf("%.*s", len, s);
f010493f:	83 c4 0c             	add    $0xc,%esp
f0104942:	ff 75 0c             	pushl  0xc(%ebp)
f0104945:	ff 75 10             	pushl  0x10(%ebp)
f0104948:	68 66 80 10 f0       	push   $0xf0108066
f010494d:	e8 5a f0 ff ff       	call   f01039ac <cprintf>
}
f0104952:	83 c4 10             	add    $0x10,%esp
			return 0;
f0104955:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f010495a:	e9 8c 05 00 00       	jmp    f0104eeb <syscall+0x5ee>
	return cons_getc();
f010495f:	e8 c4 bc ff ff       	call   f0100628 <cons_getc>
f0104964:	89 c3                	mov    %eax,%ebx
		}
		case SYS_cgetc:
		{
			return sys_cgetc();
f0104966:	e9 80 05 00 00       	jmp    f0104eeb <syscall+0x5ee>
	if ((r = envid2env(envid, &e, 1)) < 0)
f010496b:	83 ec 04             	sub    $0x4,%esp
f010496e:	6a 01                	push   $0x1
f0104970:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104973:	50                   	push   %eax
f0104974:	ff 75 0c             	pushl  0xc(%ebp)
f0104977:	e8 63 e7 ff ff       	call   f01030df <envid2env>
f010497c:	89 c3                	mov    %eax,%ebx
f010497e:	83 c4 10             	add    $0x10,%esp
f0104981:	85 c0                	test   %eax,%eax
f0104983:	0f 88 62 05 00 00    	js     f0104eeb <syscall+0x5ee>
	env_destroy(e);
f0104989:	83 ec 0c             	sub    $0xc,%esp
f010498c:	ff 75 e4             	pushl  -0x1c(%ebp)
f010498f:	e8 f3 ec ff ff       	call   f0103687 <env_destroy>
	return 0;
f0104994:	83 c4 10             	add    $0x10,%esp
f0104997:	bb 00 00 00 00       	mov    $0x0,%ebx
		}
		case SYS_env_destroy:
		{
			return sys_env_destroy((envid_t)a1);
f010499c:	e9 4a 05 00 00       	jmp    f0104eeb <syscall+0x5ee>
	return curenv->env_id;
f01049a1:	e8 a8 17 00 00       	call   f010614e <cpunum>
f01049a6:	6b c0 74             	imul   $0x74,%eax,%eax
f01049a9:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01049af:	8b 58 48             	mov    0x48(%eax),%ebx
		{
			return 0;
		}
		case SYS_getenvid:
		{
			return sys_getenvid();
f01049b2:	e9 34 05 00 00       	jmp    f0104eeb <syscall+0x5ee>
	sched_yield();
f01049b7:	e8 89 fe ff ff       	call   f0104845 <sched_yield>
	struct Env* store_env = NULL;
f01049bc:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = env_alloc(&store_env,curenv->env_id);
f01049c3:	e8 86 17 00 00       	call   f010614e <cpunum>
f01049c8:	83 ec 08             	sub    $0x8,%esp
f01049cb:	6b c0 74             	imul   $0x74,%eax,%eax
f01049ce:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01049d4:	ff 70 48             	pushl  0x48(%eax)
f01049d7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01049da:	50                   	push   %eax
f01049db:	e8 14 e8 ff ff       	call   f01031f4 <env_alloc>
f01049e0:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f01049e2:	83 c4 10             	add    $0x10,%esp
f01049e5:	85 c0                	test   %eax,%eax
f01049e7:	0f 88 fe 04 00 00    	js     f0104eeb <syscall+0x5ee>
	store_env->env_status = ENV_NOT_RUNNABLE;
f01049ed:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01049f0:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	store_env->env_tf = curenv->env_tf;
f01049f7:	e8 52 17 00 00       	call   f010614e <cpunum>
f01049fc:	6b c0 74             	imul   $0x74,%eax,%eax
f01049ff:	8b b0 28 80 21 f0    	mov    -0xfde7fd8(%eax),%esi
f0104a05:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104a0a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104a0d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	store_env->env_tf.tf_regs.reg_eax = 0;
f0104a0f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a12:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return store_env->env_id;
f0104a19:	8b 58 48             	mov    0x48(%eax),%ebx
			sys_yield();
			return 0;
		}
		case SYS_exofork:
		{
			return sys_exofork();
f0104a1c:	e9 ca 04 00 00       	jmp    f0104eeb <syscall+0x5ee>
	if(status != ENV_NOT_RUNNABLE && status!= ENV_RUNNABLE)
f0104a21:	8b 45 10             	mov    0x10(%ebp),%eax
f0104a24:	83 e8 02             	sub    $0x2,%eax
f0104a27:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f0104a2c:	75 38                	jne    f0104a66 <syscall+0x169>
	struct Env* e = NULL;
f0104a2e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f0104a35:	83 ec 04             	sub    $0x4,%esp
f0104a38:	6a 01                	push   $0x1
f0104a3a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104a3d:	50                   	push   %eax
f0104a3e:	ff 75 0c             	pushl  0xc(%ebp)
f0104a41:	e8 99 e6 ff ff       	call   f01030df <envid2env>
f0104a46:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104a48:	83 c4 10             	add    $0x10,%esp
f0104a4b:	85 c0                	test   %eax,%eax
f0104a4d:	0f 88 98 04 00 00    	js     f0104eeb <syscall+0x5ee>
	e->env_status = status;
f0104a53:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a56:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104a59:	89 78 54             	mov    %edi,0x54(%eax)
	return 0;
f0104a5c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104a61:	e9 85 04 00 00       	jmp    f0104eeb <syscall+0x5ee>
		return -E_INVAL;
f0104a66:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		}
		case SYS_env_set_status:
		{
			return sys_env_set_status((envid_t)a1,(int)a2);
f0104a6b:	e9 7b 04 00 00       	jmp    f0104eeb <syscall+0x5ee>
	if((uintptr_t)va >= UTOP || (uintptr_t)va % PGSIZE)
f0104a70:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104a77:	0f 87 84 00 00 00    	ja     f0104b01 <syscall+0x204>
	if((perm & ~(PTE_SYSCALL)) || ((perm & needed_perm) != needed_perm))
f0104a7d:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0104a80:	81 e3 f8 f1 ff ff    	and    $0xfffff1f8,%ebx
	if((uintptr_t)va >= UTOP || (uintptr_t)va % PGSIZE)
f0104a86:	8b 45 10             	mov    0x10(%ebp),%eax
f0104a89:	25 ff 0f 00 00       	and    $0xfff,%eax
	if((perm & ~(PTE_SYSCALL)) || ((perm & needed_perm) != needed_perm))
f0104a8e:	09 c3                	or     %eax,%ebx
f0104a90:	75 79                	jne    f0104b0b <syscall+0x20e>
f0104a92:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a95:	83 e0 05             	and    $0x5,%eax
f0104a98:	83 f8 05             	cmp    $0x5,%eax
f0104a9b:	75 78                	jne    f0104b15 <syscall+0x218>
	struct Env* e = NULL;
f0104a9d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f0104aa4:	83 ec 04             	sub    $0x4,%esp
f0104aa7:	6a 01                	push   $0x1
f0104aa9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104aac:	50                   	push   %eax
f0104aad:	ff 75 0c             	pushl  0xc(%ebp)
f0104ab0:	e8 2a e6 ff ff       	call   f01030df <envid2env>
	if(ret<0)
f0104ab5:	83 c4 10             	add    $0x10,%esp
f0104ab8:	85 c0                	test   %eax,%eax
f0104aba:	78 63                	js     f0104b1f <syscall+0x222>
	struct PageInfo* pg = page_alloc(ALLOC_ZERO);
f0104abc:	83 ec 0c             	sub    $0xc,%esp
f0104abf:	6a 01                	push   $0x1
f0104ac1:	e8 e9 c4 ff ff       	call   f0100faf <page_alloc>
f0104ac6:	89 c6                	mov    %eax,%esi
	if(!pg)
f0104ac8:	83 c4 10             	add    $0x10,%esp
f0104acb:	85 c0                	test   %eax,%eax
f0104acd:	74 57                	je     f0104b26 <syscall+0x229>
	ret = page_insert(e->env_pgdir,pg,va,perm);
f0104acf:	ff 75 14             	pushl  0x14(%ebp)
f0104ad2:	ff 75 10             	pushl  0x10(%ebp)
f0104ad5:	50                   	push   %eax
f0104ad6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104ad9:	ff 70 60             	pushl  0x60(%eax)
f0104adc:	e8 83 c7 ff ff       	call   f0101264 <page_insert>
f0104ae1:	89 c7                	mov    %eax,%edi
	if(ret < 0)
f0104ae3:	83 c4 10             	add    $0x10,%esp
f0104ae6:	85 c0                	test   %eax,%eax
f0104ae8:	0f 89 fd 03 00 00    	jns    f0104eeb <syscall+0x5ee>
		page_free(pg);
f0104aee:	83 ec 0c             	sub    $0xc,%esp
f0104af1:	56                   	push   %esi
f0104af2:	e8 31 c5 ff ff       	call   f0101028 <page_free>
		return ret;
f0104af7:	83 c4 10             	add    $0x10,%esp
f0104afa:	89 fb                	mov    %edi,%ebx
f0104afc:	e9 ea 03 00 00       	jmp    f0104eeb <syscall+0x5ee>
		return -E_INVAL;
f0104b01:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104b06:	e9 e0 03 00 00       	jmp    f0104eeb <syscall+0x5ee>
		return -E_INVAL;
f0104b0b:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104b10:	e9 d6 03 00 00       	jmp    f0104eeb <syscall+0x5ee>
f0104b15:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104b1a:	e9 cc 03 00 00       	jmp    f0104eeb <syscall+0x5ee>
		return ret;
f0104b1f:	89 c3                	mov    %eax,%ebx
f0104b21:	e9 c5 03 00 00       	jmp    f0104eeb <syscall+0x5ee>
		return -E_NO_MEM;
f0104b26:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
		}
		case SYS_page_alloc:
		{
			return sys_page_alloc((envid_t)a1,(void*)a2,(int)a3);
f0104b2b:	e9 bb 03 00 00       	jmp    f0104eeb <syscall+0x5ee>
	if((uintptr_t)srcva>=UTOP || (uintptr_t)srcva % PGSIZE 
f0104b30:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104b37:	0f 87 d7 00 00 00    	ja     f0104c14 <syscall+0x317>
	|| (uintptr_t)dstva>=UTOP || (uintptr_t)dstva % PGSIZE)
f0104b3d:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104b44:	0f 87 d4 00 00 00    	ja     f0104c1e <syscall+0x321>
	if((perm & ~(PTE_SYSCALL)) || ((perm & needed_perm) != needed_perm))
f0104b4a:	8b 45 10             	mov    0x10(%ebp),%eax
f0104b4d:	0b 45 18             	or     0x18(%ebp),%eax
f0104b50:	25 ff 0f 00 00       	and    $0xfff,%eax
f0104b55:	8b 55 1c             	mov    0x1c(%ebp),%edx
f0104b58:	81 e2 f8 f1 ff ff    	and    $0xfffff1f8,%edx
f0104b5e:	09 d0                	or     %edx,%eax
f0104b60:	0f 85 c2 00 00 00    	jne    f0104c28 <syscall+0x32b>
f0104b66:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0104b69:	83 e0 05             	and    $0x5,%eax
f0104b6c:	83 f8 05             	cmp    $0x5,%eax
f0104b6f:	0f 85 bd 00 00 00    	jne    f0104c32 <syscall+0x335>
	struct Env* srce = NULL, *dste = NULL;
f0104b75:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0104b7c:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	int ret = envid2env(srcenvid,&srce,true);
f0104b83:	83 ec 04             	sub    $0x4,%esp
f0104b86:	6a 01                	push   $0x1
f0104b88:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0104b8b:	50                   	push   %eax
f0104b8c:	ff 75 0c             	pushl  0xc(%ebp)
f0104b8f:	e8 4b e5 ff ff       	call   f01030df <envid2env>
f0104b94:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104b96:	83 c4 10             	add    $0x10,%esp
f0104b99:	85 c0                	test   %eax,%eax
f0104b9b:	0f 88 4a 03 00 00    	js     f0104eeb <syscall+0x5ee>
	ret = envid2env(dstenvid,&dste,true);
f0104ba1:	83 ec 04             	sub    $0x4,%esp
f0104ba4:	6a 01                	push   $0x1
f0104ba6:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104ba9:	50                   	push   %eax
f0104baa:	ff 75 14             	pushl  0x14(%ebp)
f0104bad:	e8 2d e5 ff ff       	call   f01030df <envid2env>
f0104bb2:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104bb4:	83 c4 10             	add    $0x10,%esp
f0104bb7:	85 c0                	test   %eax,%eax
f0104bb9:	0f 88 2c 03 00 00    	js     f0104eeb <syscall+0x5ee>
	pte_t* pte = NULL;
f0104bbf:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	struct PageInfo* pg = page_lookup(srce->env_pgdir,srcva,&pte);
f0104bc6:	83 ec 04             	sub    $0x4,%esp
f0104bc9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104bcc:	50                   	push   %eax
f0104bcd:	ff 75 10             	pushl  0x10(%ebp)
f0104bd0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104bd3:	ff 70 60             	pushl  0x60(%eax)
f0104bd6:	e8 96 c5 ff ff       	call   f0101171 <page_lookup>
	if(!pg)
f0104bdb:	83 c4 10             	add    $0x10,%esp
f0104bde:	85 c0                	test   %eax,%eax
f0104be0:	74 5a                	je     f0104c3c <syscall+0x33f>
	if((!((*pte) & PTE_W)) && (perm & PTE_W))
f0104be2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104be5:	f6 02 02             	testb  $0x2,(%edx)
f0104be8:	75 06                	jne    f0104bf0 <syscall+0x2f3>
f0104bea:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104bee:	75 56                	jne    f0104c46 <syscall+0x349>
	ret = page_insert(dste->env_pgdir,pg,dstva,perm);
f0104bf0:	ff 75 1c             	pushl  0x1c(%ebp)
f0104bf3:	ff 75 18             	pushl  0x18(%ebp)
f0104bf6:	50                   	push   %eax
f0104bf7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104bfa:	ff 70 60             	pushl  0x60(%eax)
f0104bfd:	e8 62 c6 ff ff       	call   f0101264 <page_insert>
f0104c02:	83 c4 10             	add    $0x10,%esp
f0104c05:	85 c0                	test   %eax,%eax
f0104c07:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104c0c:	0f 4e d8             	cmovle %eax,%ebx
f0104c0f:	e9 d7 02 00 00       	jmp    f0104eeb <syscall+0x5ee>
		return -E_INVAL;
f0104c14:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104c19:	e9 cd 02 00 00       	jmp    f0104eeb <syscall+0x5ee>
f0104c1e:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104c23:	e9 c3 02 00 00       	jmp    f0104eeb <syscall+0x5ee>
		return -E_INVAL;
f0104c28:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104c2d:	e9 b9 02 00 00       	jmp    f0104eeb <syscall+0x5ee>
f0104c32:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104c37:	e9 af 02 00 00       	jmp    f0104eeb <syscall+0x5ee>
		return -E_INVAL;
f0104c3c:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104c41:	e9 a5 02 00 00       	jmp    f0104eeb <syscall+0x5ee>
		return -E_INVAL;
f0104c46:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		}
		case SYS_page_map:
		{
			return sys_page_map((envid_t)a1,(void*)a2,(envid_t)a3,(void*)a4,(int)a5);
f0104c4b:	e9 9b 02 00 00       	jmp    f0104eeb <syscall+0x5ee>
	if((uintptr_t)va >= UTOP || (uintptr_t)va % PGSIZE)
f0104c50:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104c57:	77 4c                	ja     f0104ca5 <syscall+0x3a8>
f0104c59:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104c60:	75 4d                	jne    f0104caf <syscall+0x3b2>
	struct Env* e = NULL;
f0104c62:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f0104c69:	83 ec 04             	sub    $0x4,%esp
f0104c6c:	6a 01                	push   $0x1
f0104c6e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104c71:	50                   	push   %eax
f0104c72:	ff 75 0c             	pushl  0xc(%ebp)
f0104c75:	e8 65 e4 ff ff       	call   f01030df <envid2env>
f0104c7a:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104c7c:	83 c4 10             	add    $0x10,%esp
f0104c7f:	85 c0                	test   %eax,%eax
f0104c81:	0f 88 64 02 00 00    	js     f0104eeb <syscall+0x5ee>
	page_remove(e->env_pgdir,va);
f0104c87:	83 ec 08             	sub    $0x8,%esp
f0104c8a:	ff 75 10             	pushl  0x10(%ebp)
f0104c8d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104c90:	ff 70 60             	pushl  0x60(%eax)
f0104c93:	e8 7b c5 ff ff       	call   f0101213 <page_remove>
	return 0;
f0104c98:	83 c4 10             	add    $0x10,%esp
f0104c9b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104ca0:	e9 46 02 00 00       	jmp    f0104eeb <syscall+0x5ee>
		return -E_INVAL;
f0104ca5:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104caa:	e9 3c 02 00 00       	jmp    f0104eeb <syscall+0x5ee>
f0104caf:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		}
		case SYS_page_unmap:
		{
			return sys_page_unmap((envid_t)a1,(void*)a2);
f0104cb4:	e9 32 02 00 00       	jmp    f0104eeb <syscall+0x5ee>
	struct Env* e = NULL;
f0104cb9:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f0104cc0:	83 ec 04             	sub    $0x4,%esp
f0104cc3:	6a 01                	push   $0x1
f0104cc5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104cc8:	50                   	push   %eax
f0104cc9:	ff 75 0c             	pushl  0xc(%ebp)
f0104ccc:	e8 0e e4 ff ff       	call   f01030df <envid2env>
f0104cd1:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104cd3:	83 c4 10             	add    $0x10,%esp
f0104cd6:	85 c0                	test   %eax,%eax
f0104cd8:	0f 88 0d 02 00 00    	js     f0104eeb <syscall+0x5ee>
	e->env_pgfault_upcall = func;
f0104cde:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104ce1:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104ce4:	89 48 64             	mov    %ecx,0x64(%eax)
	return 0;
f0104ce7:	bb 00 00 00 00       	mov    $0x0,%ebx
		}
		case SYS_env_set_pgfault_upcall:
		{
			return sys_env_set_pgfault_upcall((envid_t)a1,(void*)a2);
f0104cec:	e9 fa 01 00 00       	jmp    f0104eeb <syscall+0x5ee>
	struct Env* dst = NULL;
f0104cf1:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	if((ret = envid2env(envid,&dst,false)) < 0)
f0104cf8:	83 ec 04             	sub    $0x4,%esp
f0104cfb:	6a 00                	push   $0x0
f0104cfd:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104d00:	50                   	push   %eax
f0104d01:	ff 75 0c             	pushl  0xc(%ebp)
f0104d04:	e8 d6 e3 ff ff       	call   f01030df <envid2env>
f0104d09:	89 c3                	mov    %eax,%ebx
f0104d0b:	83 c4 10             	add    $0x10,%esp
f0104d0e:	85 c0                	test   %eax,%eax
f0104d10:	0f 88 d5 01 00 00    	js     f0104eeb <syscall+0x5ee>
	if(!dst->env_ipc_recving)
f0104d16:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104d19:	80 78 68 00          	cmpb   $0x0,0x68(%eax)
f0104d1d:	0f 84 f1 00 00 00    	je     f0104e14 <syscall+0x517>
	if(perm)
f0104d23:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f0104d2a:	0f 87 9f 00 00 00    	ja     f0104dcf <syscall+0x4d2>
f0104d30:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
f0104d34:	0f 84 95 00 00 00    	je     f0104dcf <syscall+0x4d2>
		if(((perm_needed & perm) != perm_needed) || (perm & (~PTE_SYSCALL)))
f0104d3a:	8b 45 18             	mov    0x18(%ebp),%eax
f0104d3d:	83 e0 05             	and    $0x5,%eax
			return -E_INVAL;
f0104d40:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		if(((perm_needed & perm) != perm_needed) || (perm & (~PTE_SYSCALL)))
f0104d45:	83 f8 05             	cmp    $0x5,%eax
f0104d48:	0f 85 9d 01 00 00    	jne    f0104eeb <syscall+0x5ee>
		if((uintptr_t)srcva % PGSIZE)
f0104d4e:	8b 55 14             	mov    0x14(%ebp),%edx
f0104d51:	81 e2 ff 0f 00 00    	and    $0xfff,%edx
		if(((perm_needed & perm) != perm_needed) || (perm & (~PTE_SYSCALL)))
f0104d57:	8b 45 18             	mov    0x18(%ebp),%eax
f0104d5a:	25 f8 f1 ff ff       	and    $0xfffff1f8,%eax
f0104d5f:	09 c2                	or     %eax,%edx
f0104d61:	0f 85 84 01 00 00    	jne    f0104eeb <syscall+0x5ee>
		pte_t* pte = NULL;
f0104d67:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		struct PageInfo* pg = page_lookup(curenv->env_pgdir,srcva,&pte);
f0104d6e:	e8 db 13 00 00       	call   f010614e <cpunum>
f0104d73:	83 ec 04             	sub    $0x4,%esp
f0104d76:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104d79:	52                   	push   %edx
f0104d7a:	ff 75 14             	pushl  0x14(%ebp)
f0104d7d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104d80:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0104d86:	ff 70 60             	pushl  0x60(%eax)
f0104d89:	e8 e3 c3 ff ff       	call   f0101171 <page_lookup>
		if(!pg)
f0104d8e:	83 c4 10             	add    $0x10,%esp
f0104d91:	85 c0                	test   %eax,%eax
f0104d93:	74 75                	je     f0104e0a <syscall+0x50d>
		if((perm & PTE_W) && !(*pte & PTE_W))
f0104d95:	f6 45 18 02          	testb  $0x2,0x18(%ebp)
f0104d99:	74 0c                	je     f0104da7 <syscall+0x4aa>
f0104d9b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104d9e:	f6 02 02             	testb  $0x2,(%edx)
f0104da1:	0f 84 44 01 00 00    	je     f0104eeb <syscall+0x5ee>
		if((ret = page_insert(dst->env_pgdir,pg,dst->env_ipc_dstva,perm)) < 0)
f0104da7:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0104daa:	ff 75 18             	pushl  0x18(%ebp)
f0104dad:	ff 72 6c             	pushl  0x6c(%edx)
f0104db0:	50                   	push   %eax
f0104db1:	ff 72 60             	pushl  0x60(%edx)
f0104db4:	e8 ab c4 ff ff       	call   f0101264 <page_insert>
f0104db9:	89 c3                	mov    %eax,%ebx
f0104dbb:	83 c4 10             	add    $0x10,%esp
f0104dbe:	85 c0                	test   %eax,%eax
f0104dc0:	0f 88 25 01 00 00    	js     f0104eeb <syscall+0x5ee>
		dst->env_ipc_perm = perm;
f0104dc6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104dc9:	8b 75 18             	mov    0x18(%ebp),%esi
f0104dcc:	89 70 78             	mov    %esi,0x78(%eax)
	dst->env_ipc_from = curenv->env_id;
f0104dcf:	e8 7a 13 00 00       	call   f010614e <cpunum>
f0104dd4:	89 c2                	mov    %eax,%edx
f0104dd6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104dd9:	6b d2 74             	imul   $0x74,%edx,%edx
f0104ddc:	8b 92 28 80 21 f0    	mov    -0xfde7fd8(%edx),%edx
f0104de2:	8b 52 48             	mov    0x48(%edx),%edx
f0104de5:	89 50 74             	mov    %edx,0x74(%eax)
	dst->env_ipc_value = value;
f0104de8:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104deb:	89 48 70             	mov    %ecx,0x70(%eax)
	dst->env_ipc_recving = 0;
f0104dee:	c6 40 68 00          	movb   $0x0,0x68(%eax)
	dst->env_status = ENV_RUNNABLE;
f0104df2:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	dst->env_tf.tf_regs.reg_eax = 0;
f0104df9:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return 0;
f0104e00:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104e05:	e9 e1 00 00 00       	jmp    f0104eeb <syscall+0x5ee>
			return -E_INVAL;
f0104e0a:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104e0f:	e9 d7 00 00 00       	jmp    f0104eeb <syscall+0x5ee>
		return -E_IPC_NOT_RECV;
f0104e14:	bb f9 ff ff ff       	mov    $0xfffffff9,%ebx
		}
		case SYS_ipc_try_send:
		{
			return sys_ipc_try_send((envid_t)a1,(uint32_t)a2,(void*)a3,(unsigned int)a4);
f0104e19:	e9 cd 00 00 00       	jmp    f0104eeb <syscall+0x5ee>
	if((uintptr_t)dstva<UTOP && (uintptr_t)dstva%PGSIZE)
f0104e1e:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f0104e25:	77 13                	ja     f0104e3a <syscall+0x53d>
f0104e27:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
f0104e2e:	74 0a                	je     f0104e3a <syscall+0x53d>
		}
		case SYS_ipc_recv:
		{
			return sys_ipc_recv((void*)a1);
f0104e30:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104e35:	e9 b1 00 00 00       	jmp    f0104eeb <syscall+0x5ee>
	curenv->env_ipc_recving = 1;
f0104e3a:	e8 0f 13 00 00       	call   f010614e <cpunum>
f0104e3f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104e42:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0104e48:	c6 40 68 01          	movb   $0x1,0x68(%eax)
	curenv->env_ipc_dstva = dstva;
f0104e4c:	e8 fd 12 00 00       	call   f010614e <cpunum>
f0104e51:	6b c0 74             	imul   $0x74,%eax,%eax
f0104e54:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0104e5a:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104e5d:	89 70 6c             	mov    %esi,0x6c(%eax)
	curenv->env_status = ENV_NOT_RUNNABLE;
f0104e60:	e8 e9 12 00 00       	call   f010614e <cpunum>
f0104e65:	6b c0 74             	imul   $0x74,%eax,%eax
f0104e68:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0104e6e:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	sched_yield();
f0104e75:	e8 cb f9 ff ff       	call   f0104845 <sched_yield>
		}
		case SYS_env_set_trapframe:
		{
			return sys_env_set_trapframe((envid_t)a1,(struct Trapframe*)a2);
f0104e7a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	user_mem_assert(curenv,(const void*)tf,sizeof(struct Trapframe),PTE_U|PTE_P);
f0104e7d:	e8 cc 12 00 00       	call   f010614e <cpunum>
f0104e82:	6a 05                	push   $0x5
f0104e84:	6a 44                	push   $0x44
f0104e86:	ff 75 10             	pushl  0x10(%ebp)
f0104e89:	6b c0 74             	imul   $0x74,%eax,%eax
f0104e8c:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0104e92:	e8 57 e1 ff ff       	call   f0102fee <user_mem_assert>
	struct Env* e = NULL;
f0104e97:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	if(envid2env(envid,&e,1) < 0)
f0104e9e:	83 c4 0c             	add    $0xc,%esp
f0104ea1:	6a 01                	push   $0x1
f0104ea3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104ea6:	50                   	push   %eax
f0104ea7:	ff 75 0c             	pushl  0xc(%ebp)
f0104eaa:	e8 30 e2 ff ff       	call   f01030df <envid2env>
f0104eaf:	83 c4 10             	add    $0x10,%esp
f0104eb2:	85 c0                	test   %eax,%eax
f0104eb4:	78 29                	js     f0104edf <syscall+0x5e2>
	e->env_tf = *tf;
f0104eb6:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104ebb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104ebe:	89 de                	mov    %ebx,%esi
f0104ec0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	e->env_tf.tf_eflags |= FL_IF;
f0104ec2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104ec5:	81 48 38 00 02 00 00 	orl    $0x200,0x38(%eax)
	tf->tf_eflags &= ~FL_IOPL_MASK;
f0104ecc:	81 63 38 ff cf ff ff 	andl   $0xffffcfff,0x38(%ebx)
	e->env_tf.tf_cs |= 3;
f0104ed3:	66 83 48 34 03       	orw    $0x3,0x34(%eax)
	return 0;
f0104ed8:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104edd:	eb 0c                	jmp    f0104eeb <syscall+0x5ee>
		return -E_BAD_ENV;
f0104edf:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
			return sys_env_set_trapframe((envid_t)a1,(struct Trapframe*)a2);
f0104ee4:	eb 05                	jmp    f0104eeb <syscall+0x5ee>
			return 0;
f0104ee6:	bb 00 00 00 00       	mov    $0x0,%ebx
		}
		default:
			return -E_INVAL;
	}
}
f0104eeb:	89 d8                	mov    %ebx,%eax
f0104eed:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104ef0:	5b                   	pop    %ebx
f0104ef1:	5e                   	pop    %esi
f0104ef2:	5f                   	pop    %edi
f0104ef3:	5d                   	pop    %ebp
f0104ef4:	c3                   	ret    

f0104ef5 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104ef5:	55                   	push   %ebp
f0104ef6:	89 e5                	mov    %esp,%ebp
f0104ef8:	57                   	push   %edi
f0104ef9:	56                   	push   %esi
f0104efa:	53                   	push   %ebx
f0104efb:	83 ec 14             	sub    $0x14,%esp
f0104efe:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104f01:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104f04:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104f07:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104f0a:	8b 1a                	mov    (%edx),%ebx
f0104f0c:	8b 01                	mov    (%ecx),%eax
f0104f0e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104f11:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104f18:	eb 23                	jmp    f0104f3d <stab_binsearch+0x48>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104f1a:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0104f1d:	eb 1e                	jmp    f0104f3d <stab_binsearch+0x48>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104f1f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104f22:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104f25:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104f29:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104f2c:	73 46                	jae    f0104f74 <stab_binsearch+0x7f>
			*region_left = m;
f0104f2e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104f31:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104f33:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f0104f36:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0104f3d:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104f40:	7f 5f                	jg     f0104fa1 <stab_binsearch+0xac>
		int true_m = (l + r) / 2, m = true_m;
f0104f42:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104f45:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f0104f48:	89 d0                	mov    %edx,%eax
f0104f4a:	c1 e8 1f             	shr    $0x1f,%eax
f0104f4d:	01 d0                	add    %edx,%eax
f0104f4f:	89 c7                	mov    %eax,%edi
f0104f51:	d1 ff                	sar    %edi
f0104f53:	83 e0 fe             	and    $0xfffffffe,%eax
f0104f56:	01 f8                	add    %edi,%eax
f0104f58:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104f5b:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0104f5f:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f0104f61:	39 c3                	cmp    %eax,%ebx
f0104f63:	7f b5                	jg     f0104f1a <stab_binsearch+0x25>
f0104f65:	0f b6 0a             	movzbl (%edx),%ecx
f0104f68:	83 ea 0c             	sub    $0xc,%edx
f0104f6b:	39 f1                	cmp    %esi,%ecx
f0104f6d:	74 b0                	je     f0104f1f <stab_binsearch+0x2a>
			m--;
f0104f6f:	83 e8 01             	sub    $0x1,%eax
f0104f72:	eb ed                	jmp    f0104f61 <stab_binsearch+0x6c>
		} else if (stabs[m].n_value > addr) {
f0104f74:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104f77:	76 14                	jbe    f0104f8d <stab_binsearch+0x98>
			*region_right = m - 1;
f0104f79:	83 e8 01             	sub    $0x1,%eax
f0104f7c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104f7f:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104f82:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f0104f84:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104f8b:	eb b0                	jmp    f0104f3d <stab_binsearch+0x48>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104f8d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104f90:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0104f92:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104f96:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f0104f98:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104f9f:	eb 9c                	jmp    f0104f3d <stab_binsearch+0x48>
		}
	}

	if (!any_matches)
f0104fa1:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104fa5:	75 15                	jne    f0104fbc <stab_binsearch+0xc7>
		*region_right = *region_left - 1;
f0104fa7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104faa:	8b 00                	mov    (%eax),%eax
f0104fac:	83 e8 01             	sub    $0x1,%eax
f0104faf:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104fb2:	89 07                	mov    %eax,(%edi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0104fb4:	83 c4 14             	add    $0x14,%esp
f0104fb7:	5b                   	pop    %ebx
f0104fb8:	5e                   	pop    %esi
f0104fb9:	5f                   	pop    %edi
f0104fba:	5d                   	pop    %ebp
f0104fbb:	c3                   	ret    
		for (l = *region_right;
f0104fbc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104fbf:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104fc1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104fc4:	8b 0f                	mov    (%edi),%ecx
f0104fc6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104fc9:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0104fcc:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
		for (l = *region_right;
f0104fd0:	eb 03                	jmp    f0104fd5 <stab_binsearch+0xe0>
		     l--)
f0104fd2:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0104fd5:	39 c1                	cmp    %eax,%ecx
f0104fd7:	7d 0a                	jge    f0104fe3 <stab_binsearch+0xee>
		     l > *region_left && stabs[l].n_type != type;
f0104fd9:	0f b6 1a             	movzbl (%edx),%ebx
f0104fdc:	83 ea 0c             	sub    $0xc,%edx
f0104fdf:	39 f3                	cmp    %esi,%ebx
f0104fe1:	75 ef                	jne    f0104fd2 <stab_binsearch+0xdd>
		*region_left = l;
f0104fe3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104fe6:	89 07                	mov    %eax,(%edi)
}
f0104fe8:	eb ca                	jmp    f0104fb4 <stab_binsearch+0xbf>

f0104fea <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104fea:	f3 0f 1e fb          	endbr32 
f0104fee:	55                   	push   %ebp
f0104fef:	89 e5                	mov    %esp,%ebp
f0104ff1:	57                   	push   %edi
f0104ff2:	56                   	push   %esi
f0104ff3:	53                   	push   %ebx
f0104ff4:	83 ec 4c             	sub    $0x4c,%esp
f0104ff7:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104ffa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104ffd:	c7 03 a8 80 10 f0    	movl   $0xf01080a8,(%ebx)
	info->eip_line = 0;
f0105003:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010500a:	c7 43 08 a8 80 10 f0 	movl   $0xf01080a8,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0105011:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0105018:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010501b:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0105022:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0105028:	0f 86 32 01 00 00    	jbe    f0105160 <debuginfo_eip+0x176>
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010502e:	c7 45 b4 69 8b 11 f0 	movl   $0xf0118b69,-0x4c(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0105035:	c7 45 b8 35 53 11 f0 	movl   $0xf0115335,-0x48(%ebp)
		stab_end = __STAB_END__;
f010503c:	be 34 53 11 f0       	mov    $0xf0115334,%esi
		stabs = __STAB_BEGIN__;
f0105041:	c7 45 bc 50 86 10 f0 	movl   $0xf0108650,-0x44(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0105048:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f010504b:	39 4d b8             	cmp    %ecx,-0x48(%ebp)
f010504e:	0f 83 62 02 00 00    	jae    f01052b6 <debuginfo_eip+0x2cc>
f0105054:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0105058:	0f 85 5f 02 00 00    	jne    f01052bd <debuginfo_eip+0x2d3>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010505e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0105065:	2b 75 bc             	sub    -0x44(%ebp),%esi
f0105068:	c1 fe 02             	sar    $0x2,%esi
f010506b:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0105071:	83 e8 01             	sub    $0x1,%eax
f0105074:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0105077:	83 ec 08             	sub    $0x8,%esp
f010507a:	57                   	push   %edi
f010507b:	6a 64                	push   $0x64
f010507d:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0105080:	89 d1                	mov    %edx,%ecx
f0105082:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0105085:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0105088:	89 f0                	mov    %esi,%eax
f010508a:	e8 66 fe ff ff       	call   f0104ef5 <stab_binsearch>
	if (lfile == 0)
f010508f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105092:	83 c4 10             	add    $0x10,%esp
f0105095:	85 c0                	test   %eax,%eax
f0105097:	0f 84 27 02 00 00    	je     f01052c4 <debuginfo_eip+0x2da>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010509d:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01050a0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01050a3:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01050a6:	83 ec 08             	sub    $0x8,%esp
f01050a9:	57                   	push   %edi
f01050aa:	6a 24                	push   $0x24
f01050ac:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01050af:	89 d1                	mov    %edx,%ecx
f01050b1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01050b4:	89 f0                	mov    %esi,%eax
f01050b6:	e8 3a fe ff ff       	call   f0104ef5 <stab_binsearch>

	if (lfun <= rfun) {
f01050bb:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01050be:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01050c1:	83 c4 10             	add    $0x10,%esp
f01050c4:	39 d0                	cmp    %edx,%eax
f01050c6:	0f 8f 34 01 00 00    	jg     f0105200 <debuginfo_eip+0x216>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01050cc:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01050cf:	8d 34 8e             	lea    (%esi,%ecx,4),%esi
f01050d2:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f01050d5:	8b 36                	mov    (%esi),%esi
f01050d7:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f01050da:	2b 4d b8             	sub    -0x48(%ebp),%ecx
f01050dd:	39 ce                	cmp    %ecx,%esi
f01050df:	73 06                	jae    f01050e7 <debuginfo_eip+0xfd>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01050e1:	03 75 b8             	add    -0x48(%ebp),%esi
f01050e4:	89 73 08             	mov    %esi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01050e7:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01050ea:	8b 4e 08             	mov    0x8(%esi),%ecx
f01050ed:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01050f0:	29 cf                	sub    %ecx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f01050f2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01050f5:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01050f8:	83 ec 08             	sub    $0x8,%esp
f01050fb:	6a 3a                	push   $0x3a
f01050fd:	ff 73 08             	pushl  0x8(%ebx)
f0105100:	e8 0a 0a 00 00       	call   f0105b0f <strfind>
f0105105:	2b 43 08             	sub    0x8(%ebx),%eax
f0105108:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	info->eip_file = stabstr +stabs[lfile].n_strx;
f010510b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010510e:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0105111:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0105114:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0105117:	03 0c 86             	add    (%esi,%eax,4),%ecx
f010511a:	89 0b                	mov    %ecx,(%ebx)
	stab_binsearch(stabs, &lline, &rline,N_SLINE,addr);
f010511c:	83 c4 08             	add    $0x8,%esp
f010511f:	57                   	push   %edi
f0105120:	6a 44                	push   $0x44
f0105122:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0105125:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0105128:	89 f0                	mov    %esi,%eax
f010512a:	e8 c6 fd ff ff       	call   f0104ef5 <stab_binsearch>
	if(lline>rline)
f010512f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0105132:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0105135:	83 c4 10             	add    $0x10,%esp
f0105138:	39 c2                	cmp    %eax,%edx
f010513a:	0f 8f 8b 01 00 00    	jg     f01052cb <debuginfo_eip+0x2e1>
	{
		return -1;
	}
	else
	{
		info->eip_line = stabs[rline].n_desc;
f0105140:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0105143:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0105148:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010514b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010514e:	89 d0                	mov    %edx,%eax
f0105150:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0105153:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
f0105157:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f010515b:	e9 be 00 00 00       	jmp    f010521e <debuginfo_eip+0x234>
		if(user_mem_check(curenv,usd,sizeof(struct UserStabData),PTE_P|PTE_U) != 0)
f0105160:	e8 e9 0f 00 00       	call   f010614e <cpunum>
f0105165:	6a 05                	push   $0x5
f0105167:	6a 10                	push   $0x10
f0105169:	68 00 00 20 00       	push   $0x200000
f010516e:	6b c0 74             	imul   $0x74,%eax,%eax
f0105171:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0105177:	e8 e3 dd ff ff       	call   f0102f5f <user_mem_check>
f010517c:	83 c4 10             	add    $0x10,%esp
f010517f:	85 c0                	test   %eax,%eax
f0105181:	0f 85 21 01 00 00    	jne    f01052a8 <debuginfo_eip+0x2be>
		stabs = usd->stabs;
f0105187:	a1 00 00 20 00       	mov    0x200000,%eax
f010518c:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stab_end = usd->stab_end;
f010518f:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f0105195:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f010519b:	89 4d b8             	mov    %ecx,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f010519e:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f01051a4:	89 55 b4             	mov    %edx,-0x4c(%ebp)
		if(user_mem_check(curenv,stabs,sizeof(struct Stab),PTE_P|PTE_U) != 0)
f01051a7:	e8 a2 0f 00 00       	call   f010614e <cpunum>
f01051ac:	6a 05                	push   $0x5
f01051ae:	6a 0c                	push   $0xc
f01051b0:	ff 75 bc             	pushl  -0x44(%ebp)
f01051b3:	6b c0 74             	imul   $0x74,%eax,%eax
f01051b6:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f01051bc:	e8 9e dd ff ff       	call   f0102f5f <user_mem_check>
f01051c1:	83 c4 10             	add    $0x10,%esp
f01051c4:	85 c0                	test   %eax,%eax
f01051c6:	0f 85 e3 00 00 00    	jne    f01052af <debuginfo_eip+0x2c5>
		if(user_mem_check(curenv,stabstr,stabstr_end-stabstr,PTE_P|PTE_U) != 0)
f01051cc:	e8 7d 0f 00 00       	call   f010614e <cpunum>
f01051d1:	6a 05                	push   $0x5
f01051d3:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f01051d6:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f01051d9:	29 ca                	sub    %ecx,%edx
f01051db:	52                   	push   %edx
f01051dc:	51                   	push   %ecx
f01051dd:	6b c0 74             	imul   $0x74,%eax,%eax
f01051e0:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f01051e6:	e8 74 dd ff ff       	call   f0102f5f <user_mem_check>
f01051eb:	83 c4 10             	add    $0x10,%esp
f01051ee:	85 c0                	test   %eax,%eax
f01051f0:	0f 84 52 fe ff ff    	je     f0105048 <debuginfo_eip+0x5e>
			return -1;
f01051f6:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01051fb:	e9 d7 00 00 00       	jmp    f01052d7 <debuginfo_eip+0x2ed>
		info->eip_fn_addr = addr;
f0105200:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f0105203:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105206:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0105209:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010520c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010520f:	e9 e4 fe ff ff       	jmp    f01050f8 <debuginfo_eip+0x10e>
f0105214:	83 e8 01             	sub    $0x1,%eax
f0105217:	83 ea 0c             	sub    $0xc,%edx
	while (lline >= lfile
f010521a:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f010521e:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0105221:	39 c7                	cmp    %eax,%edi
f0105223:	7f 43                	jg     f0105268 <debuginfo_eip+0x27e>
	       && stabs[lline].n_type != N_SOL
f0105225:	0f b6 0a             	movzbl (%edx),%ecx
f0105228:	80 f9 84             	cmp    $0x84,%cl
f010522b:	74 19                	je     f0105246 <debuginfo_eip+0x25c>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010522d:	80 f9 64             	cmp    $0x64,%cl
f0105230:	75 e2                	jne    f0105214 <debuginfo_eip+0x22a>
f0105232:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0105236:	74 dc                	je     f0105214 <debuginfo_eip+0x22a>
f0105238:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f010523c:	74 11                	je     f010524f <debuginfo_eip+0x265>
f010523e:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0105241:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0105244:	eb 09                	jmp    f010524f <debuginfo_eip+0x265>
f0105246:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f010524a:	74 03                	je     f010524f <debuginfo_eip+0x265>
f010524c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010524f:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0105252:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0105255:	8b 04 87             	mov    (%edi,%eax,4),%eax
f0105258:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f010525b:	8b 7d b8             	mov    -0x48(%ebp),%edi
f010525e:	29 fa                	sub    %edi,%edx
f0105260:	39 d0                	cmp    %edx,%eax
f0105262:	73 04                	jae    f0105268 <debuginfo_eip+0x27e>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0105264:	01 f8                	add    %edi,%eax
f0105266:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0105268:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010526b:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010526e:	ba 00 00 00 00       	mov    $0x0,%edx
	if (lfun < rfun)
f0105273:	39 f0                	cmp    %esi,%eax
f0105275:	7d 60                	jge    f01052d7 <debuginfo_eip+0x2ed>
		for (lline = lfun + 1;
f0105277:	8d 50 01             	lea    0x1(%eax),%edx
f010527a:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010527d:	89 d0                	mov    %edx,%eax
f010527f:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0105282:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0105285:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
f0105289:	eb 04                	jmp    f010528f <debuginfo_eip+0x2a5>
			info->eip_fn_narg++;
f010528b:	83 43 14 01          	addl   $0x1,0x14(%ebx)
		for (lline = lfun + 1;
f010528f:	39 c6                	cmp    %eax,%esi
f0105291:	7e 3f                	jle    f01052d2 <debuginfo_eip+0x2e8>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0105293:	0f b6 0a             	movzbl (%edx),%ecx
f0105296:	83 c0 01             	add    $0x1,%eax
f0105299:	83 c2 0c             	add    $0xc,%edx
f010529c:	80 f9 a0             	cmp    $0xa0,%cl
f010529f:	74 ea                	je     f010528b <debuginfo_eip+0x2a1>
	return 0;
f01052a1:	ba 00 00 00 00       	mov    $0x0,%edx
f01052a6:	eb 2f                	jmp    f01052d7 <debuginfo_eip+0x2ed>
			return -1;
f01052a8:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052ad:	eb 28                	jmp    f01052d7 <debuginfo_eip+0x2ed>
			return -1;
f01052af:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052b4:	eb 21                	jmp    f01052d7 <debuginfo_eip+0x2ed>
		return -1;
f01052b6:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052bb:	eb 1a                	jmp    f01052d7 <debuginfo_eip+0x2ed>
f01052bd:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052c2:	eb 13                	jmp    f01052d7 <debuginfo_eip+0x2ed>
		return -1;
f01052c4:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052c9:	eb 0c                	jmp    f01052d7 <debuginfo_eip+0x2ed>
		return -1;
f01052cb:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052d0:	eb 05                	jmp    f01052d7 <debuginfo_eip+0x2ed>
	return 0;
f01052d2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01052d7:	89 d0                	mov    %edx,%eax
f01052d9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01052dc:	5b                   	pop    %ebx
f01052dd:	5e                   	pop    %esi
f01052de:	5f                   	pop    %edi
f01052df:	5d                   	pop    %ebp
f01052e0:	c3                   	ret    

f01052e1 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01052e1:	55                   	push   %ebp
f01052e2:	89 e5                	mov    %esp,%ebp
f01052e4:	57                   	push   %edi
f01052e5:	56                   	push   %esi
f01052e6:	53                   	push   %ebx
f01052e7:	83 ec 1c             	sub    $0x1c,%esp
f01052ea:	89 c7                	mov    %eax,%edi
f01052ec:	89 d6                	mov    %edx,%esi
f01052ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01052f1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01052f4:	89 d1                	mov    %edx,%ecx
f01052f6:	89 c2                	mov    %eax,%edx
f01052f8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01052fb:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01052fe:	8b 45 10             	mov    0x10(%ebp),%eax
f0105301:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0105304:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105307:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f010530e:	39 c2                	cmp    %eax,%edx
f0105310:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f0105313:	72 3e                	jb     f0105353 <printnum+0x72>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0105315:	83 ec 0c             	sub    $0xc,%esp
f0105318:	ff 75 18             	pushl  0x18(%ebp)
f010531b:	83 eb 01             	sub    $0x1,%ebx
f010531e:	53                   	push   %ebx
f010531f:	50                   	push   %eax
f0105320:	83 ec 08             	sub    $0x8,%esp
f0105323:	ff 75 e4             	pushl  -0x1c(%ebp)
f0105326:	ff 75 e0             	pushl  -0x20(%ebp)
f0105329:	ff 75 dc             	pushl  -0x24(%ebp)
f010532c:	ff 75 d8             	pushl  -0x28(%ebp)
f010532f:	e8 2c 12 00 00       	call   f0106560 <__udivdi3>
f0105334:	83 c4 18             	add    $0x18,%esp
f0105337:	52                   	push   %edx
f0105338:	50                   	push   %eax
f0105339:	89 f2                	mov    %esi,%edx
f010533b:	89 f8                	mov    %edi,%eax
f010533d:	e8 9f ff ff ff       	call   f01052e1 <printnum>
f0105342:	83 c4 20             	add    $0x20,%esp
f0105345:	eb 13                	jmp    f010535a <printnum+0x79>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0105347:	83 ec 08             	sub    $0x8,%esp
f010534a:	56                   	push   %esi
f010534b:	ff 75 18             	pushl  0x18(%ebp)
f010534e:	ff d7                	call   *%edi
f0105350:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0105353:	83 eb 01             	sub    $0x1,%ebx
f0105356:	85 db                	test   %ebx,%ebx
f0105358:	7f ed                	jg     f0105347 <printnum+0x66>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010535a:	83 ec 08             	sub    $0x8,%esp
f010535d:	56                   	push   %esi
f010535e:	83 ec 04             	sub    $0x4,%esp
f0105361:	ff 75 e4             	pushl  -0x1c(%ebp)
f0105364:	ff 75 e0             	pushl  -0x20(%ebp)
f0105367:	ff 75 dc             	pushl  -0x24(%ebp)
f010536a:	ff 75 d8             	pushl  -0x28(%ebp)
f010536d:	e8 fe 12 00 00       	call   f0106670 <__umoddi3>
f0105372:	83 c4 14             	add    $0x14,%esp
f0105375:	0f be 80 b2 80 10 f0 	movsbl -0xfef7f4e(%eax),%eax
f010537c:	50                   	push   %eax
f010537d:	ff d7                	call   *%edi
}
f010537f:	83 c4 10             	add    $0x10,%esp
f0105382:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105385:	5b                   	pop    %ebx
f0105386:	5e                   	pop    %esi
f0105387:	5f                   	pop    %edi
f0105388:	5d                   	pop    %ebp
f0105389:	c3                   	ret    

f010538a <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010538a:	f3 0f 1e fb          	endbr32 
f010538e:	55                   	push   %ebp
f010538f:	89 e5                	mov    %esp,%ebp
f0105391:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0105394:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0105398:	8b 10                	mov    (%eax),%edx
f010539a:	3b 50 04             	cmp    0x4(%eax),%edx
f010539d:	73 0a                	jae    f01053a9 <sprintputch+0x1f>
		*b->buf++ = ch;
f010539f:	8d 4a 01             	lea    0x1(%edx),%ecx
f01053a2:	89 08                	mov    %ecx,(%eax)
f01053a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01053a7:	88 02                	mov    %al,(%edx)
}
f01053a9:	5d                   	pop    %ebp
f01053aa:	c3                   	ret    

f01053ab <printfmt>:
{
f01053ab:	f3 0f 1e fb          	endbr32 
f01053af:	55                   	push   %ebp
f01053b0:	89 e5                	mov    %esp,%ebp
f01053b2:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f01053b5:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01053b8:	50                   	push   %eax
f01053b9:	ff 75 10             	pushl  0x10(%ebp)
f01053bc:	ff 75 0c             	pushl  0xc(%ebp)
f01053bf:	ff 75 08             	pushl  0x8(%ebp)
f01053c2:	e8 05 00 00 00       	call   f01053cc <vprintfmt>
}
f01053c7:	83 c4 10             	add    $0x10,%esp
f01053ca:	c9                   	leave  
f01053cb:	c3                   	ret    

f01053cc <vprintfmt>:
{
f01053cc:	f3 0f 1e fb          	endbr32 
f01053d0:	55                   	push   %ebp
f01053d1:	89 e5                	mov    %esp,%ebp
f01053d3:	57                   	push   %edi
f01053d4:	56                   	push   %esi
f01053d5:	53                   	push   %ebx
f01053d6:	83 ec 3c             	sub    $0x3c,%esp
f01053d9:	8b 75 08             	mov    0x8(%ebp),%esi
f01053dc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01053df:	8b 7d 10             	mov    0x10(%ebp),%edi
f01053e2:	e9 8e 03 00 00       	jmp    f0105775 <vprintfmt+0x3a9>
		padc = ' ';
f01053e7:	c6 45 d3 20          	movb   $0x20,-0x2d(%ebp)
		altflag = 0;
f01053eb:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
		precision = -1;
f01053f2:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f01053f9:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0105400:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0105405:	8d 47 01             	lea    0x1(%edi),%eax
f0105408:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010540b:	0f b6 17             	movzbl (%edi),%edx
f010540e:	8d 42 dd             	lea    -0x23(%edx),%eax
f0105411:	3c 55                	cmp    $0x55,%al
f0105413:	0f 87 df 03 00 00    	ja     f01057f8 <vprintfmt+0x42c>
f0105419:	0f b6 c0             	movzbl %al,%eax
f010541c:	3e ff 24 85 00 82 10 	notrack jmp *-0xfef7e00(,%eax,4)
f0105423:	f0 
f0105424:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0105427:	c6 45 d3 2d          	movb   $0x2d,-0x2d(%ebp)
f010542b:	eb d8                	jmp    f0105405 <vprintfmt+0x39>
		switch (ch = *(unsigned char *) fmt++) {
f010542d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105430:	c6 45 d3 30          	movb   $0x30,-0x2d(%ebp)
f0105434:	eb cf                	jmp    f0105405 <vprintfmt+0x39>
f0105436:	0f b6 d2             	movzbl %dl,%edx
f0105439:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f010543c:	b8 00 00 00 00       	mov    $0x0,%eax
f0105441:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f0105444:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0105447:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f010544b:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f010544e:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0105451:	83 f9 09             	cmp    $0x9,%ecx
f0105454:	77 55                	ja     f01054ab <vprintfmt+0xdf>
			for (precision = 0; ; ++fmt) {
f0105456:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0105459:	eb e9                	jmp    f0105444 <vprintfmt+0x78>
			precision = va_arg(ap, int);
f010545b:	8b 45 14             	mov    0x14(%ebp),%eax
f010545e:	8b 00                	mov    (%eax),%eax
f0105460:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105463:	8b 45 14             	mov    0x14(%ebp),%eax
f0105466:	8d 40 04             	lea    0x4(%eax),%eax
f0105469:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010546c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f010546f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0105473:	79 90                	jns    f0105405 <vprintfmt+0x39>
				width = precision, precision = -1;
f0105475:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105478:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010547b:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0105482:	eb 81                	jmp    f0105405 <vprintfmt+0x39>
f0105484:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105487:	85 c0                	test   %eax,%eax
f0105489:	ba 00 00 00 00       	mov    $0x0,%edx
f010548e:	0f 49 d0             	cmovns %eax,%edx
f0105491:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0105494:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0105497:	e9 69 ff ff ff       	jmp    f0105405 <vprintfmt+0x39>
		switch (ch = *(unsigned char *) fmt++) {
f010549c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f010549f:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
			goto reswitch;
f01054a6:	e9 5a ff ff ff       	jmp    f0105405 <vprintfmt+0x39>
f01054ab:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01054ae:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01054b1:	eb bc                	jmp    f010546f <vprintfmt+0xa3>
			lflag++;
f01054b3:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f01054b6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f01054b9:	e9 47 ff ff ff       	jmp    f0105405 <vprintfmt+0x39>
			putch(va_arg(ap, int), putdat);
f01054be:	8b 45 14             	mov    0x14(%ebp),%eax
f01054c1:	8d 78 04             	lea    0x4(%eax),%edi
f01054c4:	83 ec 08             	sub    $0x8,%esp
f01054c7:	53                   	push   %ebx
f01054c8:	ff 30                	pushl  (%eax)
f01054ca:	ff d6                	call   *%esi
			break;
f01054cc:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01054cf:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f01054d2:	e9 9b 02 00 00       	jmp    f0105772 <vprintfmt+0x3a6>
			err = va_arg(ap, int);
f01054d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01054da:	8d 78 04             	lea    0x4(%eax),%edi
f01054dd:	8b 00                	mov    (%eax),%eax
f01054df:	99                   	cltd   
f01054e0:	31 d0                	xor    %edx,%eax
f01054e2:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01054e4:	83 f8 0f             	cmp    $0xf,%eax
f01054e7:	7f 23                	jg     f010550c <vprintfmt+0x140>
f01054e9:	8b 14 85 60 83 10 f0 	mov    -0xfef7ca0(,%eax,4),%edx
f01054f0:	85 d2                	test   %edx,%edx
f01054f2:	74 18                	je     f010550c <vprintfmt+0x140>
				printfmt(putch, putdat, "%s", p);
f01054f4:	52                   	push   %edx
f01054f5:	68 55 77 10 f0       	push   $0xf0107755
f01054fa:	53                   	push   %ebx
f01054fb:	56                   	push   %esi
f01054fc:	e8 aa fe ff ff       	call   f01053ab <printfmt>
f0105501:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0105504:	89 7d 14             	mov    %edi,0x14(%ebp)
f0105507:	e9 66 02 00 00       	jmp    f0105772 <vprintfmt+0x3a6>
				printfmt(putch, putdat, "error %d", err);
f010550c:	50                   	push   %eax
f010550d:	68 ca 80 10 f0       	push   $0xf01080ca
f0105512:	53                   	push   %ebx
f0105513:	56                   	push   %esi
f0105514:	e8 92 fe ff ff       	call   f01053ab <printfmt>
f0105519:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010551c:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f010551f:	e9 4e 02 00 00       	jmp    f0105772 <vprintfmt+0x3a6>
			if ((p = va_arg(ap, char *)) == NULL)
f0105524:	8b 45 14             	mov    0x14(%ebp),%eax
f0105527:	83 c0 04             	add    $0x4,%eax
f010552a:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010552d:	8b 45 14             	mov    0x14(%ebp),%eax
f0105530:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f0105532:	85 d2                	test   %edx,%edx
f0105534:	b8 c3 80 10 f0       	mov    $0xf01080c3,%eax
f0105539:	0f 45 c2             	cmovne %edx,%eax
f010553c:	89 45 cc             	mov    %eax,-0x34(%ebp)
			if (width > 0 && padc != '-')
f010553f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0105543:	7e 06                	jle    f010554b <vprintfmt+0x17f>
f0105545:	80 7d d3 2d          	cmpb   $0x2d,-0x2d(%ebp)
f0105549:	75 0d                	jne    f0105558 <vprintfmt+0x18c>
				for (width -= strnlen(p, precision); width > 0; width--)
f010554b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010554e:	89 c7                	mov    %eax,%edi
f0105550:	03 45 e0             	add    -0x20(%ebp),%eax
f0105553:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105556:	eb 55                	jmp    f01055ad <vprintfmt+0x1e1>
f0105558:	83 ec 08             	sub    $0x8,%esp
f010555b:	ff 75 d8             	pushl  -0x28(%ebp)
f010555e:	ff 75 cc             	pushl  -0x34(%ebp)
f0105561:	e8 38 04 00 00       	call   f010599e <strnlen>
f0105566:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0105569:	29 c2                	sub    %eax,%edx
f010556b:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f010556e:	83 c4 10             	add    $0x10,%esp
f0105571:	89 d7                	mov    %edx,%edi
					putch(padc, putdat);
f0105573:	0f be 45 d3          	movsbl -0x2d(%ebp),%eax
f0105577:	89 45 e0             	mov    %eax,-0x20(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f010557a:	85 ff                	test   %edi,%edi
f010557c:	7e 11                	jle    f010558f <vprintfmt+0x1c3>
					putch(padc, putdat);
f010557e:	83 ec 08             	sub    $0x8,%esp
f0105581:	53                   	push   %ebx
f0105582:	ff 75 e0             	pushl  -0x20(%ebp)
f0105585:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0105587:	83 ef 01             	sub    $0x1,%edi
f010558a:	83 c4 10             	add    $0x10,%esp
f010558d:	eb eb                	jmp    f010557a <vprintfmt+0x1ae>
f010558f:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0105592:	85 d2                	test   %edx,%edx
f0105594:	b8 00 00 00 00       	mov    $0x0,%eax
f0105599:	0f 49 c2             	cmovns %edx,%eax
f010559c:	29 c2                	sub    %eax,%edx
f010559e:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01055a1:	eb a8                	jmp    f010554b <vprintfmt+0x17f>
					putch(ch, putdat);
f01055a3:	83 ec 08             	sub    $0x8,%esp
f01055a6:	53                   	push   %ebx
f01055a7:	52                   	push   %edx
f01055a8:	ff d6                	call   *%esi
f01055aa:	83 c4 10             	add    $0x10,%esp
f01055ad:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01055b0:	29 f9                	sub    %edi,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01055b2:	83 c7 01             	add    $0x1,%edi
f01055b5:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01055b9:	0f be d0             	movsbl %al,%edx
f01055bc:	85 d2                	test   %edx,%edx
f01055be:	74 4b                	je     f010560b <vprintfmt+0x23f>
f01055c0:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01055c4:	78 06                	js     f01055cc <vprintfmt+0x200>
f01055c6:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f01055ca:	78 1e                	js     f01055ea <vprintfmt+0x21e>
				if (altflag && (ch < ' ' || ch > '~'))
f01055cc:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01055d0:	74 d1                	je     f01055a3 <vprintfmt+0x1d7>
f01055d2:	0f be c0             	movsbl %al,%eax
f01055d5:	83 e8 20             	sub    $0x20,%eax
f01055d8:	83 f8 5e             	cmp    $0x5e,%eax
f01055db:	76 c6                	jbe    f01055a3 <vprintfmt+0x1d7>
					putch('?', putdat);
f01055dd:	83 ec 08             	sub    $0x8,%esp
f01055e0:	53                   	push   %ebx
f01055e1:	6a 3f                	push   $0x3f
f01055e3:	ff d6                	call   *%esi
f01055e5:	83 c4 10             	add    $0x10,%esp
f01055e8:	eb c3                	jmp    f01055ad <vprintfmt+0x1e1>
f01055ea:	89 cf                	mov    %ecx,%edi
f01055ec:	eb 0e                	jmp    f01055fc <vprintfmt+0x230>
				putch(' ', putdat);
f01055ee:	83 ec 08             	sub    $0x8,%esp
f01055f1:	53                   	push   %ebx
f01055f2:	6a 20                	push   $0x20
f01055f4:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01055f6:	83 ef 01             	sub    $0x1,%edi
f01055f9:	83 c4 10             	add    $0x10,%esp
f01055fc:	85 ff                	test   %edi,%edi
f01055fe:	7f ee                	jg     f01055ee <vprintfmt+0x222>
			if ((p = va_arg(ap, char *)) == NULL)
f0105600:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0105603:	89 45 14             	mov    %eax,0x14(%ebp)
f0105606:	e9 67 01 00 00       	jmp    f0105772 <vprintfmt+0x3a6>
f010560b:	89 cf                	mov    %ecx,%edi
f010560d:	eb ed                	jmp    f01055fc <vprintfmt+0x230>
	if (lflag >= 2)
f010560f:	83 f9 01             	cmp    $0x1,%ecx
f0105612:	7f 1b                	jg     f010562f <vprintfmt+0x263>
	else if (lflag)
f0105614:	85 c9                	test   %ecx,%ecx
f0105616:	74 63                	je     f010567b <vprintfmt+0x2af>
		return va_arg(*ap, long);
f0105618:	8b 45 14             	mov    0x14(%ebp),%eax
f010561b:	8b 00                	mov    (%eax),%eax
f010561d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105620:	99                   	cltd   
f0105621:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105624:	8b 45 14             	mov    0x14(%ebp),%eax
f0105627:	8d 40 04             	lea    0x4(%eax),%eax
f010562a:	89 45 14             	mov    %eax,0x14(%ebp)
f010562d:	eb 17                	jmp    f0105646 <vprintfmt+0x27a>
		return va_arg(*ap, long long);
f010562f:	8b 45 14             	mov    0x14(%ebp),%eax
f0105632:	8b 50 04             	mov    0x4(%eax),%edx
f0105635:	8b 00                	mov    (%eax),%eax
f0105637:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010563a:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010563d:	8b 45 14             	mov    0x14(%ebp),%eax
f0105640:	8d 40 08             	lea    0x8(%eax),%eax
f0105643:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0105646:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0105649:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f010564c:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f0105651:	85 c9                	test   %ecx,%ecx
f0105653:	0f 89 ff 00 00 00    	jns    f0105758 <vprintfmt+0x38c>
				putch('-', putdat);
f0105659:	83 ec 08             	sub    $0x8,%esp
f010565c:	53                   	push   %ebx
f010565d:	6a 2d                	push   $0x2d
f010565f:	ff d6                	call   *%esi
				num = -(long long) num;
f0105661:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0105664:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0105667:	f7 da                	neg    %edx
f0105669:	83 d1 00             	adc    $0x0,%ecx
f010566c:	f7 d9                	neg    %ecx
f010566e:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0105671:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105676:	e9 dd 00 00 00       	jmp    f0105758 <vprintfmt+0x38c>
		return va_arg(*ap, int);
f010567b:	8b 45 14             	mov    0x14(%ebp),%eax
f010567e:	8b 00                	mov    (%eax),%eax
f0105680:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105683:	99                   	cltd   
f0105684:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105687:	8b 45 14             	mov    0x14(%ebp),%eax
f010568a:	8d 40 04             	lea    0x4(%eax),%eax
f010568d:	89 45 14             	mov    %eax,0x14(%ebp)
f0105690:	eb b4                	jmp    f0105646 <vprintfmt+0x27a>
	if (lflag >= 2)
f0105692:	83 f9 01             	cmp    $0x1,%ecx
f0105695:	7f 1e                	jg     f01056b5 <vprintfmt+0x2e9>
	else if (lflag)
f0105697:	85 c9                	test   %ecx,%ecx
f0105699:	74 32                	je     f01056cd <vprintfmt+0x301>
		return va_arg(*ap, unsigned long);
f010569b:	8b 45 14             	mov    0x14(%ebp),%eax
f010569e:	8b 10                	mov    (%eax),%edx
f01056a0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01056a5:	8d 40 04             	lea    0x4(%eax),%eax
f01056a8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01056ab:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long);
f01056b0:	e9 a3 00 00 00       	jmp    f0105758 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned long long);
f01056b5:	8b 45 14             	mov    0x14(%ebp),%eax
f01056b8:	8b 10                	mov    (%eax),%edx
f01056ba:	8b 48 04             	mov    0x4(%eax),%ecx
f01056bd:	8d 40 08             	lea    0x8(%eax),%eax
f01056c0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01056c3:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long long);
f01056c8:	e9 8b 00 00 00       	jmp    f0105758 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned int);
f01056cd:	8b 45 14             	mov    0x14(%ebp),%eax
f01056d0:	8b 10                	mov    (%eax),%edx
f01056d2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01056d7:	8d 40 04             	lea    0x4(%eax),%eax
f01056da:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01056dd:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned int);
f01056e2:	eb 74                	jmp    f0105758 <vprintfmt+0x38c>
	if (lflag >= 2)
f01056e4:	83 f9 01             	cmp    $0x1,%ecx
f01056e7:	7f 1b                	jg     f0105704 <vprintfmt+0x338>
	else if (lflag)
f01056e9:	85 c9                	test   %ecx,%ecx
f01056eb:	74 2c                	je     f0105719 <vprintfmt+0x34d>
		return va_arg(*ap, unsigned long);
f01056ed:	8b 45 14             	mov    0x14(%ebp),%eax
f01056f0:	8b 10                	mov    (%eax),%edx
f01056f2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01056f7:	8d 40 04             	lea    0x4(%eax),%eax
f01056fa:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01056fd:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long);
f0105702:	eb 54                	jmp    f0105758 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned long long);
f0105704:	8b 45 14             	mov    0x14(%ebp),%eax
f0105707:	8b 10                	mov    (%eax),%edx
f0105709:	8b 48 04             	mov    0x4(%eax),%ecx
f010570c:	8d 40 08             	lea    0x8(%eax),%eax
f010570f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0105712:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long long);
f0105717:	eb 3f                	jmp    f0105758 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned int);
f0105719:	8b 45 14             	mov    0x14(%ebp),%eax
f010571c:	8b 10                	mov    (%eax),%edx
f010571e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105723:	8d 40 04             	lea    0x4(%eax),%eax
f0105726:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0105729:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned int);
f010572e:	eb 28                	jmp    f0105758 <vprintfmt+0x38c>
			putch('0', putdat);
f0105730:	83 ec 08             	sub    $0x8,%esp
f0105733:	53                   	push   %ebx
f0105734:	6a 30                	push   $0x30
f0105736:	ff d6                	call   *%esi
			putch('x', putdat);
f0105738:	83 c4 08             	add    $0x8,%esp
f010573b:	53                   	push   %ebx
f010573c:	6a 78                	push   $0x78
f010573e:	ff d6                	call   *%esi
			num = (unsigned long long)
f0105740:	8b 45 14             	mov    0x14(%ebp),%eax
f0105743:	8b 10                	mov    (%eax),%edx
f0105745:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010574a:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f010574d:	8d 40 04             	lea    0x4(%eax),%eax
f0105750:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0105753:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0105758:	83 ec 0c             	sub    $0xc,%esp
f010575b:	0f be 7d d3          	movsbl -0x2d(%ebp),%edi
f010575f:	57                   	push   %edi
f0105760:	ff 75 e0             	pushl  -0x20(%ebp)
f0105763:	50                   	push   %eax
f0105764:	51                   	push   %ecx
f0105765:	52                   	push   %edx
f0105766:	89 da                	mov    %ebx,%edx
f0105768:	89 f0                	mov    %esi,%eax
f010576a:	e8 72 fb ff ff       	call   f01052e1 <printnum>
			break;
f010576f:	83 c4 20             	add    $0x20,%esp
			if ((p = va_arg(ap, char *)) == NULL)
f0105772:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0105775:	83 c7 01             	add    $0x1,%edi
f0105778:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010577c:	83 f8 25             	cmp    $0x25,%eax
f010577f:	0f 84 62 fc ff ff    	je     f01053e7 <vprintfmt+0x1b>
			if (ch == '\0')
f0105785:	85 c0                	test   %eax,%eax
f0105787:	0f 84 8b 00 00 00    	je     f0105818 <vprintfmt+0x44c>
			putch(ch, putdat);
f010578d:	83 ec 08             	sub    $0x8,%esp
f0105790:	53                   	push   %ebx
f0105791:	50                   	push   %eax
f0105792:	ff d6                	call   *%esi
f0105794:	83 c4 10             	add    $0x10,%esp
f0105797:	eb dc                	jmp    f0105775 <vprintfmt+0x3a9>
	if (lflag >= 2)
f0105799:	83 f9 01             	cmp    $0x1,%ecx
f010579c:	7f 1b                	jg     f01057b9 <vprintfmt+0x3ed>
	else if (lflag)
f010579e:	85 c9                	test   %ecx,%ecx
f01057a0:	74 2c                	je     f01057ce <vprintfmt+0x402>
		return va_arg(*ap, unsigned long);
f01057a2:	8b 45 14             	mov    0x14(%ebp),%eax
f01057a5:	8b 10                	mov    (%eax),%edx
f01057a7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01057ac:	8d 40 04             	lea    0x4(%eax),%eax
f01057af:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01057b2:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long);
f01057b7:	eb 9f                	jmp    f0105758 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned long long);
f01057b9:	8b 45 14             	mov    0x14(%ebp),%eax
f01057bc:	8b 10                	mov    (%eax),%edx
f01057be:	8b 48 04             	mov    0x4(%eax),%ecx
f01057c1:	8d 40 08             	lea    0x8(%eax),%eax
f01057c4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01057c7:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long long);
f01057cc:	eb 8a                	jmp    f0105758 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned int);
f01057ce:	8b 45 14             	mov    0x14(%ebp),%eax
f01057d1:	8b 10                	mov    (%eax),%edx
f01057d3:	b9 00 00 00 00       	mov    $0x0,%ecx
f01057d8:	8d 40 04             	lea    0x4(%eax),%eax
f01057db:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01057de:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned int);
f01057e3:	e9 70 ff ff ff       	jmp    f0105758 <vprintfmt+0x38c>
			putch(ch, putdat);
f01057e8:	83 ec 08             	sub    $0x8,%esp
f01057eb:	53                   	push   %ebx
f01057ec:	6a 25                	push   $0x25
f01057ee:	ff d6                	call   *%esi
			break;
f01057f0:	83 c4 10             	add    $0x10,%esp
f01057f3:	e9 7a ff ff ff       	jmp    f0105772 <vprintfmt+0x3a6>
			putch('%', putdat);
f01057f8:	83 ec 08             	sub    $0x8,%esp
f01057fb:	53                   	push   %ebx
f01057fc:	6a 25                	push   $0x25
f01057fe:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105800:	83 c4 10             	add    $0x10,%esp
f0105803:	89 f8                	mov    %edi,%eax
f0105805:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0105809:	74 05                	je     f0105810 <vprintfmt+0x444>
f010580b:	83 e8 01             	sub    $0x1,%eax
f010580e:	eb f5                	jmp    f0105805 <vprintfmt+0x439>
f0105810:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105813:	e9 5a ff ff ff       	jmp    f0105772 <vprintfmt+0x3a6>
}
f0105818:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010581b:	5b                   	pop    %ebx
f010581c:	5e                   	pop    %esi
f010581d:	5f                   	pop    %edi
f010581e:	5d                   	pop    %ebp
f010581f:	c3                   	ret    

f0105820 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105820:	f3 0f 1e fb          	endbr32 
f0105824:	55                   	push   %ebp
f0105825:	89 e5                	mov    %esp,%ebp
f0105827:	83 ec 18             	sub    $0x18,%esp
f010582a:	8b 45 08             	mov    0x8(%ebp),%eax
f010582d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105830:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105833:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105837:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010583a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105841:	85 c0                	test   %eax,%eax
f0105843:	74 26                	je     f010586b <vsnprintf+0x4b>
f0105845:	85 d2                	test   %edx,%edx
f0105847:	7e 22                	jle    f010586b <vsnprintf+0x4b>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105849:	ff 75 14             	pushl  0x14(%ebp)
f010584c:	ff 75 10             	pushl  0x10(%ebp)
f010584f:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105852:	50                   	push   %eax
f0105853:	68 8a 53 10 f0       	push   $0xf010538a
f0105858:	e8 6f fb ff ff       	call   f01053cc <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010585d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105860:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105863:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105866:	83 c4 10             	add    $0x10,%esp
}
f0105869:	c9                   	leave  
f010586a:	c3                   	ret    
		return -E_INVAL;
f010586b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105870:	eb f7                	jmp    f0105869 <vsnprintf+0x49>

f0105872 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105872:	f3 0f 1e fb          	endbr32 
f0105876:	55                   	push   %ebp
f0105877:	89 e5                	mov    %esp,%ebp
f0105879:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010587c:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010587f:	50                   	push   %eax
f0105880:	ff 75 10             	pushl  0x10(%ebp)
f0105883:	ff 75 0c             	pushl  0xc(%ebp)
f0105886:	ff 75 08             	pushl  0x8(%ebp)
f0105889:	e8 92 ff ff ff       	call   f0105820 <vsnprintf>
	va_end(ap);

	return rc;
}
f010588e:	c9                   	leave  
f010588f:	c3                   	ret    

f0105890 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0105890:	f3 0f 1e fb          	endbr32 
f0105894:	55                   	push   %ebp
f0105895:	89 e5                	mov    %esp,%ebp
f0105897:	57                   	push   %edi
f0105898:	56                   	push   %esi
f0105899:	53                   	push   %ebx
f010589a:	83 ec 0c             	sub    $0xc,%esp
f010589d:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

#if JOS_KERNEL
	if (prompt != NULL)
f01058a0:	85 c0                	test   %eax,%eax
f01058a2:	74 11                	je     f01058b5 <readline+0x25>
		cprintf("%s", prompt);
f01058a4:	83 ec 08             	sub    $0x8,%esp
f01058a7:	50                   	push   %eax
f01058a8:	68 55 77 10 f0       	push   $0xf0107755
f01058ad:	e8 fa e0 ff ff       	call   f01039ac <cprintf>
f01058b2:	83 c4 10             	add    $0x10,%esp
	if (prompt != NULL)
		fprintf(1, "%s", prompt);
#endif

	i = 0;
	echoing = iscons(0);
f01058b5:	83 ec 0c             	sub    $0xc,%esp
f01058b8:	6a 00                	push   $0x0
f01058ba:	e8 28 af ff ff       	call   f01007e7 <iscons>
f01058bf:	89 c7                	mov    %eax,%edi
f01058c1:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01058c4:	be 00 00 00 00       	mov    $0x0,%esi
f01058c9:	eb 57                	jmp    f0105922 <readline+0x92>
	while (1) {
		c = getchar();
		if (c < 0) {
			if (c != -E_EOF)
				cprintf("read error: %e\n", c);
			return NULL;
f01058cb:	b8 00 00 00 00       	mov    $0x0,%eax
			if (c != -E_EOF)
f01058d0:	83 fb f8             	cmp    $0xfffffff8,%ebx
f01058d3:	75 08                	jne    f01058dd <readline+0x4d>
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01058d5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01058d8:	5b                   	pop    %ebx
f01058d9:	5e                   	pop    %esi
f01058da:	5f                   	pop    %edi
f01058db:	5d                   	pop    %ebp
f01058dc:	c3                   	ret    
				cprintf("read error: %e\n", c);
f01058dd:	83 ec 08             	sub    $0x8,%esp
f01058e0:	53                   	push   %ebx
f01058e1:	68 bf 83 10 f0       	push   $0xf01083bf
f01058e6:	e8 c1 e0 ff ff       	call   f01039ac <cprintf>
f01058eb:	83 c4 10             	add    $0x10,%esp
			return NULL;
f01058ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01058f3:	eb e0                	jmp    f01058d5 <readline+0x45>
			if (echoing)
f01058f5:	85 ff                	test   %edi,%edi
f01058f7:	75 05                	jne    f01058fe <readline+0x6e>
			i--;
f01058f9:	83 ee 01             	sub    $0x1,%esi
f01058fc:	eb 24                	jmp    f0105922 <readline+0x92>
				cputchar('\b');
f01058fe:	83 ec 0c             	sub    $0xc,%esp
f0105901:	6a 08                	push   $0x8
f0105903:	e8 b6 ae ff ff       	call   f01007be <cputchar>
f0105908:	83 c4 10             	add    $0x10,%esp
f010590b:	eb ec                	jmp    f01058f9 <readline+0x69>
				cputchar(c);
f010590d:	83 ec 0c             	sub    $0xc,%esp
f0105910:	53                   	push   %ebx
f0105911:	e8 a8 ae ff ff       	call   f01007be <cputchar>
f0105916:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0105919:	88 9e 80 7a 21 f0    	mov    %bl,-0xfde8580(%esi)
f010591f:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f0105922:	e8 ab ae ff ff       	call   f01007d2 <getchar>
f0105927:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0105929:	85 c0                	test   %eax,%eax
f010592b:	78 9e                	js     f01058cb <readline+0x3b>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010592d:	83 f8 08             	cmp    $0x8,%eax
f0105930:	0f 94 c2             	sete   %dl
f0105933:	83 f8 7f             	cmp    $0x7f,%eax
f0105936:	0f 94 c0             	sete   %al
f0105939:	08 c2                	or     %al,%dl
f010593b:	74 04                	je     f0105941 <readline+0xb1>
f010593d:	85 f6                	test   %esi,%esi
f010593f:	7f b4                	jg     f01058f5 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105941:	83 fb 1f             	cmp    $0x1f,%ebx
f0105944:	7e 0e                	jle    f0105954 <readline+0xc4>
f0105946:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010594c:	7f 06                	jg     f0105954 <readline+0xc4>
			if (echoing)
f010594e:	85 ff                	test   %edi,%edi
f0105950:	74 c7                	je     f0105919 <readline+0x89>
f0105952:	eb b9                	jmp    f010590d <readline+0x7d>
		} else if (c == '\n' || c == '\r') {
f0105954:	83 fb 0a             	cmp    $0xa,%ebx
f0105957:	74 05                	je     f010595e <readline+0xce>
f0105959:	83 fb 0d             	cmp    $0xd,%ebx
f010595c:	75 c4                	jne    f0105922 <readline+0x92>
			if (echoing)
f010595e:	85 ff                	test   %edi,%edi
f0105960:	75 11                	jne    f0105973 <readline+0xe3>
			buf[i] = 0;
f0105962:	c6 86 80 7a 21 f0 00 	movb   $0x0,-0xfde8580(%esi)
			return buf;
f0105969:	b8 80 7a 21 f0       	mov    $0xf0217a80,%eax
f010596e:	e9 62 ff ff ff       	jmp    f01058d5 <readline+0x45>
				cputchar('\n');
f0105973:	83 ec 0c             	sub    $0xc,%esp
f0105976:	6a 0a                	push   $0xa
f0105978:	e8 41 ae ff ff       	call   f01007be <cputchar>
f010597d:	83 c4 10             	add    $0x10,%esp
f0105980:	eb e0                	jmp    f0105962 <readline+0xd2>

f0105982 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105982:	f3 0f 1e fb          	endbr32 
f0105986:	55                   	push   %ebp
f0105987:	89 e5                	mov    %esp,%ebp
f0105989:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010598c:	b8 00 00 00 00       	mov    $0x0,%eax
f0105991:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105995:	74 05                	je     f010599c <strlen+0x1a>
		n++;
f0105997:	83 c0 01             	add    $0x1,%eax
f010599a:	eb f5                	jmp    f0105991 <strlen+0xf>
	return n;
}
f010599c:	5d                   	pop    %ebp
f010599d:	c3                   	ret    

f010599e <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010599e:	f3 0f 1e fb          	endbr32 
f01059a2:	55                   	push   %ebp
f01059a3:	89 e5                	mov    %esp,%ebp
f01059a5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01059a8:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01059ab:	b8 00 00 00 00       	mov    $0x0,%eax
f01059b0:	39 d0                	cmp    %edx,%eax
f01059b2:	74 0d                	je     f01059c1 <strnlen+0x23>
f01059b4:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01059b8:	74 05                	je     f01059bf <strnlen+0x21>
		n++;
f01059ba:	83 c0 01             	add    $0x1,%eax
f01059bd:	eb f1                	jmp    f01059b0 <strnlen+0x12>
f01059bf:	89 c2                	mov    %eax,%edx
	return n;
}
f01059c1:	89 d0                	mov    %edx,%eax
f01059c3:	5d                   	pop    %ebp
f01059c4:	c3                   	ret    

f01059c5 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01059c5:	f3 0f 1e fb          	endbr32 
f01059c9:	55                   	push   %ebp
f01059ca:	89 e5                	mov    %esp,%ebp
f01059cc:	53                   	push   %ebx
f01059cd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01059d0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01059d3:	b8 00 00 00 00       	mov    $0x0,%eax
f01059d8:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f01059dc:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f01059df:	83 c0 01             	add    $0x1,%eax
f01059e2:	84 d2                	test   %dl,%dl
f01059e4:	75 f2                	jne    f01059d8 <strcpy+0x13>
		/* do nothing */;
	return ret;
}
f01059e6:	89 c8                	mov    %ecx,%eax
f01059e8:	5b                   	pop    %ebx
f01059e9:	5d                   	pop    %ebp
f01059ea:	c3                   	ret    

f01059eb <strcat>:

char *
strcat(char *dst, const char *src)
{
f01059eb:	f3 0f 1e fb          	endbr32 
f01059ef:	55                   	push   %ebp
f01059f0:	89 e5                	mov    %esp,%ebp
f01059f2:	53                   	push   %ebx
f01059f3:	83 ec 10             	sub    $0x10,%esp
f01059f6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01059f9:	53                   	push   %ebx
f01059fa:	e8 83 ff ff ff       	call   f0105982 <strlen>
f01059ff:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f0105a02:	ff 75 0c             	pushl  0xc(%ebp)
f0105a05:	01 d8                	add    %ebx,%eax
f0105a07:	50                   	push   %eax
f0105a08:	e8 b8 ff ff ff       	call   f01059c5 <strcpy>
	return dst;
}
f0105a0d:	89 d8                	mov    %ebx,%eax
f0105a0f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0105a12:	c9                   	leave  
f0105a13:	c3                   	ret    

f0105a14 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105a14:	f3 0f 1e fb          	endbr32 
f0105a18:	55                   	push   %ebp
f0105a19:	89 e5                	mov    %esp,%ebp
f0105a1b:	56                   	push   %esi
f0105a1c:	53                   	push   %ebx
f0105a1d:	8b 75 08             	mov    0x8(%ebp),%esi
f0105a20:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105a23:	89 f3                	mov    %esi,%ebx
f0105a25:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105a28:	89 f0                	mov    %esi,%eax
f0105a2a:	39 d8                	cmp    %ebx,%eax
f0105a2c:	74 11                	je     f0105a3f <strncpy+0x2b>
		*dst++ = *src;
f0105a2e:	83 c0 01             	add    $0x1,%eax
f0105a31:	0f b6 0a             	movzbl (%edx),%ecx
f0105a34:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0105a37:	80 f9 01             	cmp    $0x1,%cl
f0105a3a:	83 da ff             	sbb    $0xffffffff,%edx
f0105a3d:	eb eb                	jmp    f0105a2a <strncpy+0x16>
	}
	return ret;
}
f0105a3f:	89 f0                	mov    %esi,%eax
f0105a41:	5b                   	pop    %ebx
f0105a42:	5e                   	pop    %esi
f0105a43:	5d                   	pop    %ebp
f0105a44:	c3                   	ret    

f0105a45 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0105a45:	f3 0f 1e fb          	endbr32 
f0105a49:	55                   	push   %ebp
f0105a4a:	89 e5                	mov    %esp,%ebp
f0105a4c:	56                   	push   %esi
f0105a4d:	53                   	push   %ebx
f0105a4e:	8b 75 08             	mov    0x8(%ebp),%esi
f0105a51:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105a54:	8b 55 10             	mov    0x10(%ebp),%edx
f0105a57:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105a59:	85 d2                	test   %edx,%edx
f0105a5b:	74 21                	je     f0105a7e <strlcpy+0x39>
f0105a5d:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0105a61:	89 f2                	mov    %esi,%edx
		while (--size > 0 && *src != '\0')
f0105a63:	39 c2                	cmp    %eax,%edx
f0105a65:	74 14                	je     f0105a7b <strlcpy+0x36>
f0105a67:	0f b6 19             	movzbl (%ecx),%ebx
f0105a6a:	84 db                	test   %bl,%bl
f0105a6c:	74 0b                	je     f0105a79 <strlcpy+0x34>
			*dst++ = *src++;
f0105a6e:	83 c1 01             	add    $0x1,%ecx
f0105a71:	83 c2 01             	add    $0x1,%edx
f0105a74:	88 5a ff             	mov    %bl,-0x1(%edx)
f0105a77:	eb ea                	jmp    f0105a63 <strlcpy+0x1e>
f0105a79:	89 d0                	mov    %edx,%eax
		*dst = '\0';
f0105a7b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105a7e:	29 f0                	sub    %esi,%eax
}
f0105a80:	5b                   	pop    %ebx
f0105a81:	5e                   	pop    %esi
f0105a82:	5d                   	pop    %ebp
f0105a83:	c3                   	ret    

f0105a84 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105a84:	f3 0f 1e fb          	endbr32 
f0105a88:	55                   	push   %ebp
f0105a89:	89 e5                	mov    %esp,%ebp
f0105a8b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105a8e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105a91:	0f b6 01             	movzbl (%ecx),%eax
f0105a94:	84 c0                	test   %al,%al
f0105a96:	74 0c                	je     f0105aa4 <strcmp+0x20>
f0105a98:	3a 02                	cmp    (%edx),%al
f0105a9a:	75 08                	jne    f0105aa4 <strcmp+0x20>
		p++, q++;
f0105a9c:	83 c1 01             	add    $0x1,%ecx
f0105a9f:	83 c2 01             	add    $0x1,%edx
f0105aa2:	eb ed                	jmp    f0105a91 <strcmp+0xd>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105aa4:	0f b6 c0             	movzbl %al,%eax
f0105aa7:	0f b6 12             	movzbl (%edx),%edx
f0105aaa:	29 d0                	sub    %edx,%eax
}
f0105aac:	5d                   	pop    %ebp
f0105aad:	c3                   	ret    

f0105aae <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105aae:	f3 0f 1e fb          	endbr32 
f0105ab2:	55                   	push   %ebp
f0105ab3:	89 e5                	mov    %esp,%ebp
f0105ab5:	53                   	push   %ebx
f0105ab6:	8b 45 08             	mov    0x8(%ebp),%eax
f0105ab9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105abc:	89 c3                	mov    %eax,%ebx
f0105abe:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0105ac1:	eb 06                	jmp    f0105ac9 <strncmp+0x1b>
		n--, p++, q++;
f0105ac3:	83 c0 01             	add    $0x1,%eax
f0105ac6:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0105ac9:	39 d8                	cmp    %ebx,%eax
f0105acb:	74 16                	je     f0105ae3 <strncmp+0x35>
f0105acd:	0f b6 08             	movzbl (%eax),%ecx
f0105ad0:	84 c9                	test   %cl,%cl
f0105ad2:	74 04                	je     f0105ad8 <strncmp+0x2a>
f0105ad4:	3a 0a                	cmp    (%edx),%cl
f0105ad6:	74 eb                	je     f0105ac3 <strncmp+0x15>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105ad8:	0f b6 00             	movzbl (%eax),%eax
f0105adb:	0f b6 12             	movzbl (%edx),%edx
f0105ade:	29 d0                	sub    %edx,%eax
}
f0105ae0:	5b                   	pop    %ebx
f0105ae1:	5d                   	pop    %ebp
f0105ae2:	c3                   	ret    
		return 0;
f0105ae3:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ae8:	eb f6                	jmp    f0105ae0 <strncmp+0x32>

f0105aea <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105aea:	f3 0f 1e fb          	endbr32 
f0105aee:	55                   	push   %ebp
f0105aef:	89 e5                	mov    %esp,%ebp
f0105af1:	8b 45 08             	mov    0x8(%ebp),%eax
f0105af4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105af8:	0f b6 10             	movzbl (%eax),%edx
f0105afb:	84 d2                	test   %dl,%dl
f0105afd:	74 09                	je     f0105b08 <strchr+0x1e>
		if (*s == c)
f0105aff:	38 ca                	cmp    %cl,%dl
f0105b01:	74 0a                	je     f0105b0d <strchr+0x23>
	for (; *s; s++)
f0105b03:	83 c0 01             	add    $0x1,%eax
f0105b06:	eb f0                	jmp    f0105af8 <strchr+0xe>
			return (char *) s;
	return 0;
f0105b08:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105b0d:	5d                   	pop    %ebp
f0105b0e:	c3                   	ret    

f0105b0f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105b0f:	f3 0f 1e fb          	endbr32 
f0105b13:	55                   	push   %ebp
f0105b14:	89 e5                	mov    %esp,%ebp
f0105b16:	8b 45 08             	mov    0x8(%ebp),%eax
f0105b19:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105b1d:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0105b20:	38 ca                	cmp    %cl,%dl
f0105b22:	74 09                	je     f0105b2d <strfind+0x1e>
f0105b24:	84 d2                	test   %dl,%dl
f0105b26:	74 05                	je     f0105b2d <strfind+0x1e>
	for (; *s; s++)
f0105b28:	83 c0 01             	add    $0x1,%eax
f0105b2b:	eb f0                	jmp    f0105b1d <strfind+0xe>
			break;
	return (char *) s;
}
f0105b2d:	5d                   	pop    %ebp
f0105b2e:	c3                   	ret    

f0105b2f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105b2f:	f3 0f 1e fb          	endbr32 
f0105b33:	55                   	push   %ebp
f0105b34:	89 e5                	mov    %esp,%ebp
f0105b36:	57                   	push   %edi
f0105b37:	56                   	push   %esi
f0105b38:	53                   	push   %ebx
f0105b39:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105b3c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105b3f:	85 c9                	test   %ecx,%ecx
f0105b41:	74 31                	je     f0105b74 <memset+0x45>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105b43:	89 f8                	mov    %edi,%eax
f0105b45:	09 c8                	or     %ecx,%eax
f0105b47:	a8 03                	test   $0x3,%al
f0105b49:	75 23                	jne    f0105b6e <memset+0x3f>
		c &= 0xFF;
f0105b4b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105b4f:	89 d3                	mov    %edx,%ebx
f0105b51:	c1 e3 08             	shl    $0x8,%ebx
f0105b54:	89 d0                	mov    %edx,%eax
f0105b56:	c1 e0 18             	shl    $0x18,%eax
f0105b59:	89 d6                	mov    %edx,%esi
f0105b5b:	c1 e6 10             	shl    $0x10,%esi
f0105b5e:	09 f0                	or     %esi,%eax
f0105b60:	09 c2                	or     %eax,%edx
f0105b62:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0105b64:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0105b67:	89 d0                	mov    %edx,%eax
f0105b69:	fc                   	cld    
f0105b6a:	f3 ab                	rep stos %eax,%es:(%edi)
f0105b6c:	eb 06                	jmp    f0105b74 <memset+0x45>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105b6e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105b71:	fc                   	cld    
f0105b72:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105b74:	89 f8                	mov    %edi,%eax
f0105b76:	5b                   	pop    %ebx
f0105b77:	5e                   	pop    %esi
f0105b78:	5f                   	pop    %edi
f0105b79:	5d                   	pop    %ebp
f0105b7a:	c3                   	ret    

f0105b7b <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105b7b:	f3 0f 1e fb          	endbr32 
f0105b7f:	55                   	push   %ebp
f0105b80:	89 e5                	mov    %esp,%ebp
f0105b82:	57                   	push   %edi
f0105b83:	56                   	push   %esi
f0105b84:	8b 45 08             	mov    0x8(%ebp),%eax
f0105b87:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105b8a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105b8d:	39 c6                	cmp    %eax,%esi
f0105b8f:	73 32                	jae    f0105bc3 <memmove+0x48>
f0105b91:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105b94:	39 c2                	cmp    %eax,%edx
f0105b96:	76 2b                	jbe    f0105bc3 <memmove+0x48>
		s += n;
		d += n;
f0105b98:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105b9b:	89 fe                	mov    %edi,%esi
f0105b9d:	09 ce                	or     %ecx,%esi
f0105b9f:	09 d6                	or     %edx,%esi
f0105ba1:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105ba7:	75 0e                	jne    f0105bb7 <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0105ba9:	83 ef 04             	sub    $0x4,%edi
f0105bac:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105baf:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0105bb2:	fd                   	std    
f0105bb3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105bb5:	eb 09                	jmp    f0105bc0 <memmove+0x45>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0105bb7:	83 ef 01             	sub    $0x1,%edi
f0105bba:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0105bbd:	fd                   	std    
f0105bbe:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105bc0:	fc                   	cld    
f0105bc1:	eb 1a                	jmp    f0105bdd <memmove+0x62>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105bc3:	89 c2                	mov    %eax,%edx
f0105bc5:	09 ca                	or     %ecx,%edx
f0105bc7:	09 f2                	or     %esi,%edx
f0105bc9:	f6 c2 03             	test   $0x3,%dl
f0105bcc:	75 0a                	jne    f0105bd8 <memmove+0x5d>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105bce:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0105bd1:	89 c7                	mov    %eax,%edi
f0105bd3:	fc                   	cld    
f0105bd4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105bd6:	eb 05                	jmp    f0105bdd <memmove+0x62>
		else
			asm volatile("cld; rep movsb\n"
f0105bd8:	89 c7                	mov    %eax,%edi
f0105bda:	fc                   	cld    
f0105bdb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105bdd:	5e                   	pop    %esi
f0105bde:	5f                   	pop    %edi
f0105bdf:	5d                   	pop    %ebp
f0105be0:	c3                   	ret    

f0105be1 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105be1:	f3 0f 1e fb          	endbr32 
f0105be5:	55                   	push   %ebp
f0105be6:	89 e5                	mov    %esp,%ebp
f0105be8:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0105beb:	ff 75 10             	pushl  0x10(%ebp)
f0105bee:	ff 75 0c             	pushl  0xc(%ebp)
f0105bf1:	ff 75 08             	pushl  0x8(%ebp)
f0105bf4:	e8 82 ff ff ff       	call   f0105b7b <memmove>
}
f0105bf9:	c9                   	leave  
f0105bfa:	c3                   	ret    

f0105bfb <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105bfb:	f3 0f 1e fb          	endbr32 
f0105bff:	55                   	push   %ebp
f0105c00:	89 e5                	mov    %esp,%ebp
f0105c02:	56                   	push   %esi
f0105c03:	53                   	push   %ebx
f0105c04:	8b 45 08             	mov    0x8(%ebp),%eax
f0105c07:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105c0a:	89 c6                	mov    %eax,%esi
f0105c0c:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105c0f:	39 f0                	cmp    %esi,%eax
f0105c11:	74 1c                	je     f0105c2f <memcmp+0x34>
		if (*s1 != *s2)
f0105c13:	0f b6 08             	movzbl (%eax),%ecx
f0105c16:	0f b6 1a             	movzbl (%edx),%ebx
f0105c19:	38 d9                	cmp    %bl,%cl
f0105c1b:	75 08                	jne    f0105c25 <memcmp+0x2a>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0105c1d:	83 c0 01             	add    $0x1,%eax
f0105c20:	83 c2 01             	add    $0x1,%edx
f0105c23:	eb ea                	jmp    f0105c0f <memcmp+0x14>
			return (int) *s1 - (int) *s2;
f0105c25:	0f b6 c1             	movzbl %cl,%eax
f0105c28:	0f b6 db             	movzbl %bl,%ebx
f0105c2b:	29 d8                	sub    %ebx,%eax
f0105c2d:	eb 05                	jmp    f0105c34 <memcmp+0x39>
	}

	return 0;
f0105c2f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105c34:	5b                   	pop    %ebx
f0105c35:	5e                   	pop    %esi
f0105c36:	5d                   	pop    %ebp
f0105c37:	c3                   	ret    

f0105c38 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105c38:	f3 0f 1e fb          	endbr32 
f0105c3c:	55                   	push   %ebp
f0105c3d:	89 e5                	mov    %esp,%ebp
f0105c3f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105c42:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0105c45:	89 c2                	mov    %eax,%edx
f0105c47:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105c4a:	39 d0                	cmp    %edx,%eax
f0105c4c:	73 09                	jae    f0105c57 <memfind+0x1f>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105c4e:	38 08                	cmp    %cl,(%eax)
f0105c50:	74 05                	je     f0105c57 <memfind+0x1f>
	for (; s < ends; s++)
f0105c52:	83 c0 01             	add    $0x1,%eax
f0105c55:	eb f3                	jmp    f0105c4a <memfind+0x12>
			break;
	return (void *) s;
}
f0105c57:	5d                   	pop    %ebp
f0105c58:	c3                   	ret    

f0105c59 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105c59:	f3 0f 1e fb          	endbr32 
f0105c5d:	55                   	push   %ebp
f0105c5e:	89 e5                	mov    %esp,%ebp
f0105c60:	57                   	push   %edi
f0105c61:	56                   	push   %esi
f0105c62:	53                   	push   %ebx
f0105c63:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105c66:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105c69:	eb 03                	jmp    f0105c6e <strtol+0x15>
		s++;
f0105c6b:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0105c6e:	0f b6 01             	movzbl (%ecx),%eax
f0105c71:	3c 20                	cmp    $0x20,%al
f0105c73:	74 f6                	je     f0105c6b <strtol+0x12>
f0105c75:	3c 09                	cmp    $0x9,%al
f0105c77:	74 f2                	je     f0105c6b <strtol+0x12>

	// plus/minus sign
	if (*s == '+')
f0105c79:	3c 2b                	cmp    $0x2b,%al
f0105c7b:	74 2a                	je     f0105ca7 <strtol+0x4e>
	int neg = 0;
f0105c7d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0105c82:	3c 2d                	cmp    $0x2d,%al
f0105c84:	74 2b                	je     f0105cb1 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105c86:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0105c8c:	75 0f                	jne    f0105c9d <strtol+0x44>
f0105c8e:	80 39 30             	cmpb   $0x30,(%ecx)
f0105c91:	74 28                	je     f0105cbb <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105c93:	85 db                	test   %ebx,%ebx
f0105c95:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105c9a:	0f 44 d8             	cmove  %eax,%ebx
f0105c9d:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ca2:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105ca5:	eb 46                	jmp    f0105ced <strtol+0x94>
		s++;
f0105ca7:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0105caa:	bf 00 00 00 00       	mov    $0x0,%edi
f0105caf:	eb d5                	jmp    f0105c86 <strtol+0x2d>
		s++, neg = 1;
f0105cb1:	83 c1 01             	add    $0x1,%ecx
f0105cb4:	bf 01 00 00 00       	mov    $0x1,%edi
f0105cb9:	eb cb                	jmp    f0105c86 <strtol+0x2d>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105cbb:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105cbf:	74 0e                	je     f0105ccf <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0105cc1:	85 db                	test   %ebx,%ebx
f0105cc3:	75 d8                	jne    f0105c9d <strtol+0x44>
		s++, base = 8;
f0105cc5:	83 c1 01             	add    $0x1,%ecx
f0105cc8:	bb 08 00 00 00       	mov    $0x8,%ebx
f0105ccd:	eb ce                	jmp    f0105c9d <strtol+0x44>
		s += 2, base = 16;
f0105ccf:	83 c1 02             	add    $0x2,%ecx
f0105cd2:	bb 10 00 00 00       	mov    $0x10,%ebx
f0105cd7:	eb c4                	jmp    f0105c9d <strtol+0x44>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f0105cd9:	0f be d2             	movsbl %dl,%edx
f0105cdc:	83 ea 30             	sub    $0x30,%edx
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0105cdf:	3b 55 10             	cmp    0x10(%ebp),%edx
f0105ce2:	7d 3a                	jge    f0105d1e <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0105ce4:	83 c1 01             	add    $0x1,%ecx
f0105ce7:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105ceb:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0105ced:	0f b6 11             	movzbl (%ecx),%edx
f0105cf0:	8d 72 d0             	lea    -0x30(%edx),%esi
f0105cf3:	89 f3                	mov    %esi,%ebx
f0105cf5:	80 fb 09             	cmp    $0x9,%bl
f0105cf8:	76 df                	jbe    f0105cd9 <strtol+0x80>
		else if (*s >= 'a' && *s <= 'z')
f0105cfa:	8d 72 9f             	lea    -0x61(%edx),%esi
f0105cfd:	89 f3                	mov    %esi,%ebx
f0105cff:	80 fb 19             	cmp    $0x19,%bl
f0105d02:	77 08                	ja     f0105d0c <strtol+0xb3>
			dig = *s - 'a' + 10;
f0105d04:	0f be d2             	movsbl %dl,%edx
f0105d07:	83 ea 57             	sub    $0x57,%edx
f0105d0a:	eb d3                	jmp    f0105cdf <strtol+0x86>
		else if (*s >= 'A' && *s <= 'Z')
f0105d0c:	8d 72 bf             	lea    -0x41(%edx),%esi
f0105d0f:	89 f3                	mov    %esi,%ebx
f0105d11:	80 fb 19             	cmp    $0x19,%bl
f0105d14:	77 08                	ja     f0105d1e <strtol+0xc5>
			dig = *s - 'A' + 10;
f0105d16:	0f be d2             	movsbl %dl,%edx
f0105d19:	83 ea 37             	sub    $0x37,%edx
f0105d1c:	eb c1                	jmp    f0105cdf <strtol+0x86>
		// we don't properly detect overflow!
	}

	if (endptr)
f0105d1e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105d22:	74 05                	je     f0105d29 <strtol+0xd0>
		*endptr = (char *) s;
f0105d24:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105d27:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0105d29:	89 c2                	mov    %eax,%edx
f0105d2b:	f7 da                	neg    %edx
f0105d2d:	85 ff                	test   %edi,%edi
f0105d2f:	0f 45 c2             	cmovne %edx,%eax
}
f0105d32:	5b                   	pop    %ebx
f0105d33:	5e                   	pop    %esi
f0105d34:	5f                   	pop    %edi
f0105d35:	5d                   	pop    %ebp
f0105d36:	c3                   	ret    
f0105d37:	90                   	nop

f0105d38 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0105d38:	fa                   	cli    

	xorw    %ax, %ax
f0105d39:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0105d3b:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105d3d:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105d3f:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105d41:	0f 01 16             	lgdtl  (%esi)
f0105d44:	74 70                	je     f0105db6 <mpsearch1+0x3>
	movl    %cr0, %eax
f0105d46:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0105d49:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105d4d:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105d50:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0105d56:	08 00                	or     %al,(%eax)

f0105d58 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0105d58:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105d5c:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105d5e:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105d60:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105d62:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0105d66:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0105d68:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0105d6a:	b8 00 10 12 00       	mov    $0x121000,%eax
	movl    %eax, %cr3
f0105d6f:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105d72:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105d75:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0105d7a:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0105d7d:	8b 25 84 7e 21 f0    	mov    0xf0217e84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105d83:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0105d88:	b8 bd 01 10 f0       	mov    $0xf01001bd,%eax
	call    *%eax
f0105d8d:	ff d0                	call   *%eax

f0105d8f <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105d8f:	eb fe                	jmp    f0105d8f <spin>
f0105d91:	8d 76 00             	lea    0x0(%esi),%esi

f0105d94 <gdt>:
	...
f0105d9c:	ff                   	(bad)  
f0105d9d:	ff 00                	incl   (%eax)
f0105d9f:	00 00                	add    %al,(%eax)
f0105da1:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105da8:	00                   	.byte 0x0
f0105da9:	92                   	xchg   %eax,%edx
f0105daa:	cf                   	iret   
	...

f0105dac <gdtdesc>:
f0105dac:	17                   	pop    %ss
f0105dad:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105db2 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105db2:	90                   	nop

f0105db3 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105db3:	55                   	push   %ebp
f0105db4:	89 e5                	mov    %esp,%ebp
f0105db6:	57                   	push   %edi
f0105db7:	56                   	push   %esi
f0105db8:	53                   	push   %ebx
f0105db9:	83 ec 0c             	sub    $0xc,%esp
f0105dbc:	89 c7                	mov    %eax,%edi
	if (PGNUM(pa) >= npages)
f0105dbe:	a1 88 7e 21 f0       	mov    0xf0217e88,%eax
f0105dc3:	89 f9                	mov    %edi,%ecx
f0105dc5:	c1 e9 0c             	shr    $0xc,%ecx
f0105dc8:	39 c1                	cmp    %eax,%ecx
f0105dca:	73 19                	jae    f0105de5 <mpsearch1+0x32>
	return (void *)(pa + KERNBASE);
f0105dcc:	8d 9f 00 00 00 f0    	lea    -0x10000000(%edi),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105dd2:	01 d7                	add    %edx,%edi
	if (PGNUM(pa) >= npages)
f0105dd4:	89 fa                	mov    %edi,%edx
f0105dd6:	c1 ea 0c             	shr    $0xc,%edx
f0105dd9:	39 c2                	cmp    %eax,%edx
f0105ddb:	73 1a                	jae    f0105df7 <mpsearch1+0x44>
	return (void *)(pa + KERNBASE);
f0105ddd:	81 ef 00 00 00 10    	sub    $0x10000000,%edi

	for (; mp < end; mp++)
f0105de3:	eb 27                	jmp    f0105e0c <mpsearch1+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105de5:	57                   	push   %edi
f0105de6:	68 e4 67 10 f0       	push   $0xf01067e4
f0105deb:	6a 57                	push   $0x57
f0105ded:	68 5d 85 10 f0       	push   $0xf010855d
f0105df2:	e8 49 a2 ff ff       	call   f0100040 <_panic>
f0105df7:	57                   	push   %edi
f0105df8:	68 e4 67 10 f0       	push   $0xf01067e4
f0105dfd:	6a 57                	push   $0x57
f0105dff:	68 5d 85 10 f0       	push   $0xf010855d
f0105e04:	e8 37 a2 ff ff       	call   f0100040 <_panic>
f0105e09:	83 c3 10             	add    $0x10,%ebx
f0105e0c:	39 fb                	cmp    %edi,%ebx
f0105e0e:	73 30                	jae    f0105e40 <mpsearch1+0x8d>
f0105e10:	89 de                	mov    %ebx,%esi
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105e12:	83 ec 04             	sub    $0x4,%esp
f0105e15:	6a 04                	push   $0x4
f0105e17:	68 6d 85 10 f0       	push   $0xf010856d
f0105e1c:	53                   	push   %ebx
f0105e1d:	e8 d9 fd ff ff       	call   f0105bfb <memcmp>
f0105e22:	83 c4 10             	add    $0x10,%esp
f0105e25:	85 c0                	test   %eax,%eax
f0105e27:	75 e0                	jne    f0105e09 <mpsearch1+0x56>
f0105e29:	89 da                	mov    %ebx,%edx
	for (i = 0; i < len; i++)
f0105e2b:	83 c6 10             	add    $0x10,%esi
		sum += ((uint8_t *)addr)[i];
f0105e2e:	0f b6 0a             	movzbl (%edx),%ecx
f0105e31:	01 c8                	add    %ecx,%eax
f0105e33:	83 c2 01             	add    $0x1,%edx
	for (i = 0; i < len; i++)
f0105e36:	39 f2                	cmp    %esi,%edx
f0105e38:	75 f4                	jne    f0105e2e <mpsearch1+0x7b>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105e3a:	84 c0                	test   %al,%al
f0105e3c:	75 cb                	jne    f0105e09 <mpsearch1+0x56>
f0105e3e:	eb 05                	jmp    f0105e45 <mpsearch1+0x92>
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0105e40:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0105e45:	89 d8                	mov    %ebx,%eax
f0105e47:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105e4a:	5b                   	pop    %ebx
f0105e4b:	5e                   	pop    %esi
f0105e4c:	5f                   	pop    %edi
f0105e4d:	5d                   	pop    %ebp
f0105e4e:	c3                   	ret    

f0105e4f <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105e4f:	f3 0f 1e fb          	endbr32 
f0105e53:	55                   	push   %ebp
f0105e54:	89 e5                	mov    %esp,%ebp
f0105e56:	57                   	push   %edi
f0105e57:	56                   	push   %esi
f0105e58:	53                   	push   %ebx
f0105e59:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105e5c:	c7 05 c0 83 21 f0 20 	movl   $0xf0218020,0xf02183c0
f0105e63:	80 21 f0 
	if (PGNUM(pa) >= npages)
f0105e66:	83 3d 88 7e 21 f0 00 	cmpl   $0x0,0xf0217e88
f0105e6d:	0f 84 a3 00 00 00    	je     f0105f16 <mp_init+0xc7>
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105e73:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105e7a:	85 c0                	test   %eax,%eax
f0105e7c:	0f 84 aa 00 00 00    	je     f0105f2c <mp_init+0xdd>
		p <<= 4;	// Translate from segment to PA
f0105e82:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0105e85:	ba 00 04 00 00       	mov    $0x400,%edx
f0105e8a:	e8 24 ff ff ff       	call   f0105db3 <mpsearch1>
f0105e8f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105e92:	85 c0                	test   %eax,%eax
f0105e94:	75 1a                	jne    f0105eb0 <mp_init+0x61>
	return mpsearch1(0xF0000, 0x10000);
f0105e96:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105e9b:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105ea0:	e8 0e ff ff ff       	call   f0105db3 <mpsearch1>
f0105ea5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if ((mp = mpsearch()) == 0)
f0105ea8:	85 c0                	test   %eax,%eax
f0105eaa:	0f 84 35 02 00 00    	je     f01060e5 <mp_init+0x296>
	if (mp->physaddr == 0 || mp->type != 0) {
f0105eb0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105eb3:	8b 58 04             	mov    0x4(%eax),%ebx
f0105eb6:	85 db                	test   %ebx,%ebx
f0105eb8:	0f 84 97 00 00 00    	je     f0105f55 <mp_init+0x106>
f0105ebe:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0105ec2:	0f 85 8d 00 00 00    	jne    f0105f55 <mp_init+0x106>
f0105ec8:	89 d8                	mov    %ebx,%eax
f0105eca:	c1 e8 0c             	shr    $0xc,%eax
f0105ecd:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0105ed3:	0f 83 91 00 00 00    	jae    f0105f6a <mp_init+0x11b>
	return (void *)(pa + KERNBASE);
f0105ed9:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
f0105edf:	89 de                	mov    %ebx,%esi
	if (memcmp(conf, "PCMP", 4) != 0) {
f0105ee1:	83 ec 04             	sub    $0x4,%esp
f0105ee4:	6a 04                	push   $0x4
f0105ee6:	68 72 85 10 f0       	push   $0xf0108572
f0105eeb:	53                   	push   %ebx
f0105eec:	e8 0a fd ff ff       	call   f0105bfb <memcmp>
f0105ef1:	83 c4 10             	add    $0x10,%esp
f0105ef4:	85 c0                	test   %eax,%eax
f0105ef6:	0f 85 83 00 00 00    	jne    f0105f7f <mp_init+0x130>
f0105efc:	0f b7 7b 04          	movzwl 0x4(%ebx),%edi
f0105f00:	01 df                	add    %ebx,%edi
	sum = 0;
f0105f02:	89 c2                	mov    %eax,%edx
	for (i = 0; i < len; i++)
f0105f04:	39 fb                	cmp    %edi,%ebx
f0105f06:	0f 84 88 00 00 00    	je     f0105f94 <mp_init+0x145>
		sum += ((uint8_t *)addr)[i];
f0105f0c:	0f b6 0b             	movzbl (%ebx),%ecx
f0105f0f:	01 ca                	add    %ecx,%edx
f0105f11:	83 c3 01             	add    $0x1,%ebx
f0105f14:	eb ee                	jmp    f0105f04 <mp_init+0xb5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105f16:	68 00 04 00 00       	push   $0x400
f0105f1b:	68 e4 67 10 f0       	push   $0xf01067e4
f0105f20:	6a 6f                	push   $0x6f
f0105f22:	68 5d 85 10 f0       	push   $0xf010855d
f0105f27:	e8 14 a1 ff ff       	call   f0100040 <_panic>
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0105f2c:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105f33:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105f36:	2d 00 04 00 00       	sub    $0x400,%eax
f0105f3b:	ba 00 04 00 00       	mov    $0x400,%edx
f0105f40:	e8 6e fe ff ff       	call   f0105db3 <mpsearch1>
f0105f45:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105f48:	85 c0                	test   %eax,%eax
f0105f4a:	0f 85 60 ff ff ff    	jne    f0105eb0 <mp_init+0x61>
f0105f50:	e9 41 ff ff ff       	jmp    f0105e96 <mp_init+0x47>
		cprintf("SMP: Default configurations not implemented\n");
f0105f55:	83 ec 0c             	sub    $0xc,%esp
f0105f58:	68 d0 83 10 f0       	push   $0xf01083d0
f0105f5d:	e8 4a da ff ff       	call   f01039ac <cprintf>
		return NULL;
f0105f62:	83 c4 10             	add    $0x10,%esp
f0105f65:	e9 7b 01 00 00       	jmp    f01060e5 <mp_init+0x296>
f0105f6a:	53                   	push   %ebx
f0105f6b:	68 e4 67 10 f0       	push   $0xf01067e4
f0105f70:	68 90 00 00 00       	push   $0x90
f0105f75:	68 5d 85 10 f0       	push   $0xf010855d
f0105f7a:	e8 c1 a0 ff ff       	call   f0100040 <_panic>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105f7f:	83 ec 0c             	sub    $0xc,%esp
f0105f82:	68 00 84 10 f0       	push   $0xf0108400
f0105f87:	e8 20 da ff ff       	call   f01039ac <cprintf>
		return NULL;
f0105f8c:	83 c4 10             	add    $0x10,%esp
f0105f8f:	e9 51 01 00 00       	jmp    f01060e5 <mp_init+0x296>
	if (sum(conf, conf->length) != 0) {
f0105f94:	84 d2                	test   %dl,%dl
f0105f96:	75 22                	jne    f0105fba <mp_init+0x16b>
	if (conf->version != 1 && conf->version != 4) {
f0105f98:	0f b6 56 06          	movzbl 0x6(%esi),%edx
f0105f9c:	80 fa 01             	cmp    $0x1,%dl
f0105f9f:	74 05                	je     f0105fa6 <mp_init+0x157>
f0105fa1:	80 fa 04             	cmp    $0x4,%dl
f0105fa4:	75 29                	jne    f0105fcf <mp_init+0x180>
f0105fa6:	0f b7 4e 28          	movzwl 0x28(%esi),%ecx
f0105faa:	01 d9                	add    %ebx,%ecx
	for (i = 0; i < len; i++)
f0105fac:	39 d9                	cmp    %ebx,%ecx
f0105fae:	74 38                	je     f0105fe8 <mp_init+0x199>
		sum += ((uint8_t *)addr)[i];
f0105fb0:	0f b6 13             	movzbl (%ebx),%edx
f0105fb3:	01 d0                	add    %edx,%eax
f0105fb5:	83 c3 01             	add    $0x1,%ebx
f0105fb8:	eb f2                	jmp    f0105fac <mp_init+0x15d>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105fba:	83 ec 0c             	sub    $0xc,%esp
f0105fbd:	68 34 84 10 f0       	push   $0xf0108434
f0105fc2:	e8 e5 d9 ff ff       	call   f01039ac <cprintf>
		return NULL;
f0105fc7:	83 c4 10             	add    $0x10,%esp
f0105fca:	e9 16 01 00 00       	jmp    f01060e5 <mp_init+0x296>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105fcf:	83 ec 08             	sub    $0x8,%esp
f0105fd2:	0f b6 d2             	movzbl %dl,%edx
f0105fd5:	52                   	push   %edx
f0105fd6:	68 58 84 10 f0       	push   $0xf0108458
f0105fdb:	e8 cc d9 ff ff       	call   f01039ac <cprintf>
		return NULL;
f0105fe0:	83 c4 10             	add    $0x10,%esp
f0105fe3:	e9 fd 00 00 00       	jmp    f01060e5 <mp_init+0x296>
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105fe8:	02 46 2a             	add    0x2a(%esi),%al
f0105feb:	75 1c                	jne    f0106009 <mp_init+0x1ba>
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
f0105fed:	c7 05 00 80 21 f0 01 	movl   $0x1,0xf0218000
f0105ff4:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105ff7:	8b 46 24             	mov    0x24(%esi),%eax
f0105ffa:	a3 00 90 25 f0       	mov    %eax,0xf0259000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105fff:	8d 7e 2c             	lea    0x2c(%esi),%edi
f0106002:	bb 00 00 00 00       	mov    $0x0,%ebx
f0106007:	eb 4d                	jmp    f0106056 <mp_init+0x207>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0106009:	83 ec 0c             	sub    $0xc,%esp
f010600c:	68 78 84 10 f0       	push   $0xf0108478
f0106011:	e8 96 d9 ff ff       	call   f01039ac <cprintf>
		return NULL;
f0106016:	83 c4 10             	add    $0x10,%esp
f0106019:	e9 c7 00 00 00       	jmp    f01060e5 <mp_init+0x296>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f010601e:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0106022:	74 11                	je     f0106035 <mp_init+0x1e6>
				bootcpu = &cpus[ncpu];
f0106024:	6b 05 c4 83 21 f0 74 	imul   $0x74,0xf02183c4,%eax
f010602b:	05 20 80 21 f0       	add    $0xf0218020,%eax
f0106030:	a3 c0 83 21 f0       	mov    %eax,0xf02183c0
			if (ncpu < NCPU) {
f0106035:	a1 c4 83 21 f0       	mov    0xf02183c4,%eax
f010603a:	83 f8 07             	cmp    $0x7,%eax
f010603d:	7f 33                	jg     f0106072 <mp_init+0x223>
				cpus[ncpu].cpu_id = ncpu;
f010603f:	6b d0 74             	imul   $0x74,%eax,%edx
f0106042:	88 82 20 80 21 f0    	mov    %al,-0xfde7fe0(%edx)
				ncpu++;
f0106048:	83 c0 01             	add    $0x1,%eax
f010604b:	a3 c4 83 21 f0       	mov    %eax,0xf02183c4
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0106050:	83 c7 14             	add    $0x14,%edi
	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0106053:	83 c3 01             	add    $0x1,%ebx
f0106056:	0f b7 46 22          	movzwl 0x22(%esi),%eax
f010605a:	39 d8                	cmp    %ebx,%eax
f010605c:	76 4f                	jbe    f01060ad <mp_init+0x25e>
		switch (*p) {
f010605e:	0f b6 07             	movzbl (%edi),%eax
f0106061:	84 c0                	test   %al,%al
f0106063:	74 b9                	je     f010601e <mp_init+0x1cf>
f0106065:	8d 50 ff             	lea    -0x1(%eax),%edx
f0106068:	80 fa 03             	cmp    $0x3,%dl
f010606b:	77 1c                	ja     f0106089 <mp_init+0x23a>
			continue;
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f010606d:	83 c7 08             	add    $0x8,%edi
			continue;
f0106070:	eb e1                	jmp    f0106053 <mp_init+0x204>
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0106072:	83 ec 08             	sub    $0x8,%esp
f0106075:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0106079:	50                   	push   %eax
f010607a:	68 a8 84 10 f0       	push   $0xf01084a8
f010607f:	e8 28 d9 ff ff       	call   f01039ac <cprintf>
f0106084:	83 c4 10             	add    $0x10,%esp
f0106087:	eb c7                	jmp    f0106050 <mp_init+0x201>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0106089:	83 ec 08             	sub    $0x8,%esp
		switch (*p) {
f010608c:	0f b6 c0             	movzbl %al,%eax
			cprintf("mpinit: unknown config type %x\n", *p);
f010608f:	50                   	push   %eax
f0106090:	68 d0 84 10 f0       	push   $0xf01084d0
f0106095:	e8 12 d9 ff ff       	call   f01039ac <cprintf>
			ismp = 0;
f010609a:	c7 05 00 80 21 f0 00 	movl   $0x0,0xf0218000
f01060a1:	00 00 00 
			i = conf->entry;
f01060a4:	0f b7 5e 22          	movzwl 0x22(%esi),%ebx
f01060a8:	83 c4 10             	add    $0x10,%esp
f01060ab:	eb a6                	jmp    f0106053 <mp_init+0x204>
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f01060ad:	a1 c0 83 21 f0       	mov    0xf02183c0,%eax
f01060b2:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f01060b9:	83 3d 00 80 21 f0 00 	cmpl   $0x0,0xf0218000
f01060c0:	74 2b                	je     f01060ed <mp_init+0x29e>
		ncpu = 1;
		lapicaddr = 0;
		cprintf("SMP: configuration not found, SMP disabled\n");
		return;
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f01060c2:	83 ec 04             	sub    $0x4,%esp
f01060c5:	ff 35 c4 83 21 f0    	pushl  0xf02183c4
f01060cb:	0f b6 00             	movzbl (%eax),%eax
f01060ce:	50                   	push   %eax
f01060cf:	68 77 85 10 f0       	push   $0xf0108577
f01060d4:	e8 d3 d8 ff ff       	call   f01039ac <cprintf>

	if (mp->imcrp) {
f01060d9:	83 c4 10             	add    $0x10,%esp
f01060dc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01060df:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f01060e3:	75 2e                	jne    f0106113 <mp_init+0x2c4>
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f01060e5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01060e8:	5b                   	pop    %ebx
f01060e9:	5e                   	pop    %esi
f01060ea:	5f                   	pop    %edi
f01060eb:	5d                   	pop    %ebp
f01060ec:	c3                   	ret    
		ncpu = 1;
f01060ed:	c7 05 c4 83 21 f0 01 	movl   $0x1,0xf02183c4
f01060f4:	00 00 00 
		lapicaddr = 0;
f01060f7:	c7 05 00 90 25 f0 00 	movl   $0x0,0xf0259000
f01060fe:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0106101:	83 ec 0c             	sub    $0xc,%esp
f0106104:	68 f0 84 10 f0       	push   $0xf01084f0
f0106109:	e8 9e d8 ff ff       	call   f01039ac <cprintf>
		return;
f010610e:	83 c4 10             	add    $0x10,%esp
f0106111:	eb d2                	jmp    f01060e5 <mp_init+0x296>
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0106113:	83 ec 0c             	sub    $0xc,%esp
f0106116:	68 1c 85 10 f0       	push   $0xf010851c
f010611b:	e8 8c d8 ff ff       	call   f01039ac <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0106120:	b8 70 00 00 00       	mov    $0x70,%eax
f0106125:	ba 22 00 00 00       	mov    $0x22,%edx
f010612a:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010612b:	ba 23 00 00 00       	mov    $0x23,%edx
f0106130:	ec                   	in     (%dx),%al
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0106131:	83 c8 01             	or     $0x1,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0106134:	ee                   	out    %al,(%dx)
}
f0106135:	83 c4 10             	add    $0x10,%esp
f0106138:	eb ab                	jmp    f01060e5 <mp_init+0x296>

f010613a <lapicw>:
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
	lapic[index] = value;
f010613a:	8b 0d 04 90 25 f0    	mov    0xf0259004,%ecx
f0106140:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0106143:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0106145:	a1 04 90 25 f0       	mov    0xf0259004,%eax
f010614a:	8b 40 20             	mov    0x20(%eax),%eax
}
f010614d:	c3                   	ret    

f010614e <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f010614e:	f3 0f 1e fb          	endbr32 
	if (lapic)
f0106152:	8b 15 04 90 25 f0    	mov    0xf0259004,%edx
		return lapic[ID] >> 24;
	return 0;
f0106158:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lapic)
f010615d:	85 d2                	test   %edx,%edx
f010615f:	74 06                	je     f0106167 <cpunum+0x19>
		return lapic[ID] >> 24;
f0106161:	8b 42 20             	mov    0x20(%edx),%eax
f0106164:	c1 e8 18             	shr    $0x18,%eax
}
f0106167:	c3                   	ret    

f0106168 <lapic_init>:
{
f0106168:	f3 0f 1e fb          	endbr32 
	if (!lapicaddr)
f010616c:	a1 00 90 25 f0       	mov    0xf0259000,%eax
f0106171:	85 c0                	test   %eax,%eax
f0106173:	75 01                	jne    f0106176 <lapic_init+0xe>
f0106175:	c3                   	ret    
{
f0106176:	55                   	push   %ebp
f0106177:	89 e5                	mov    %esp,%ebp
f0106179:	83 ec 10             	sub    $0x10,%esp
	lapic = mmio_map_region(lapicaddr, 4096);
f010617c:	68 00 10 00 00       	push   $0x1000
f0106181:	50                   	push   %eax
f0106182:	e8 5f b1 ff ff       	call   f01012e6 <mmio_map_region>
f0106187:	a3 04 90 25 f0       	mov    %eax,0xf0259004
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f010618c:	ba 27 01 00 00       	mov    $0x127,%edx
f0106191:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0106196:	e8 9f ff ff ff       	call   f010613a <lapicw>
	lapicw(TDCR, X1);
f010619b:	ba 0b 00 00 00       	mov    $0xb,%edx
f01061a0:	b8 f8 00 00 00       	mov    $0xf8,%eax
f01061a5:	e8 90 ff ff ff       	call   f010613a <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f01061aa:	ba 20 00 02 00       	mov    $0x20020,%edx
f01061af:	b8 c8 00 00 00       	mov    $0xc8,%eax
f01061b4:	e8 81 ff ff ff       	call   f010613a <lapicw>
	lapicw(TICR, 10000000); 
f01061b9:	ba 80 96 98 00       	mov    $0x989680,%edx
f01061be:	b8 e0 00 00 00       	mov    $0xe0,%eax
f01061c3:	e8 72 ff ff ff       	call   f010613a <lapicw>
	if (thiscpu != bootcpu)
f01061c8:	e8 81 ff ff ff       	call   f010614e <cpunum>
f01061cd:	6b c0 74             	imul   $0x74,%eax,%eax
f01061d0:	05 20 80 21 f0       	add    $0xf0218020,%eax
f01061d5:	83 c4 10             	add    $0x10,%esp
f01061d8:	39 05 c0 83 21 f0    	cmp    %eax,0xf02183c0
f01061de:	74 0f                	je     f01061ef <lapic_init+0x87>
		lapicw(LINT0, MASKED);
f01061e0:	ba 00 00 01 00       	mov    $0x10000,%edx
f01061e5:	b8 d4 00 00 00       	mov    $0xd4,%eax
f01061ea:	e8 4b ff ff ff       	call   f010613a <lapicw>
	lapicw(LINT1, MASKED);
f01061ef:	ba 00 00 01 00       	mov    $0x10000,%edx
f01061f4:	b8 d8 00 00 00       	mov    $0xd8,%eax
f01061f9:	e8 3c ff ff ff       	call   f010613a <lapicw>
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f01061fe:	a1 04 90 25 f0       	mov    0xf0259004,%eax
f0106203:	8b 40 30             	mov    0x30(%eax),%eax
f0106206:	c1 e8 10             	shr    $0x10,%eax
f0106209:	a8 fc                	test   $0xfc,%al
f010620b:	75 7c                	jne    f0106289 <lapic_init+0x121>
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f010620d:	ba 33 00 00 00       	mov    $0x33,%edx
f0106212:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0106217:	e8 1e ff ff ff       	call   f010613a <lapicw>
	lapicw(ESR, 0);
f010621c:	ba 00 00 00 00       	mov    $0x0,%edx
f0106221:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0106226:	e8 0f ff ff ff       	call   f010613a <lapicw>
	lapicw(ESR, 0);
f010622b:	ba 00 00 00 00       	mov    $0x0,%edx
f0106230:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0106235:	e8 00 ff ff ff       	call   f010613a <lapicw>
	lapicw(EOI, 0);
f010623a:	ba 00 00 00 00       	mov    $0x0,%edx
f010623f:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0106244:	e8 f1 fe ff ff       	call   f010613a <lapicw>
	lapicw(ICRHI, 0);
f0106249:	ba 00 00 00 00       	mov    $0x0,%edx
f010624e:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106253:	e8 e2 fe ff ff       	call   f010613a <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0106258:	ba 00 85 08 00       	mov    $0x88500,%edx
f010625d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106262:	e8 d3 fe ff ff       	call   f010613a <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0106267:	8b 15 04 90 25 f0    	mov    0xf0259004,%edx
f010626d:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0106273:	f6 c4 10             	test   $0x10,%ah
f0106276:	75 f5                	jne    f010626d <lapic_init+0x105>
	lapicw(TPR, 0);
f0106278:	ba 00 00 00 00       	mov    $0x0,%edx
f010627d:	b8 20 00 00 00       	mov    $0x20,%eax
f0106282:	e8 b3 fe ff ff       	call   f010613a <lapicw>
}
f0106287:	c9                   	leave  
f0106288:	c3                   	ret    
		lapicw(PCINT, MASKED);
f0106289:	ba 00 00 01 00       	mov    $0x10000,%edx
f010628e:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0106293:	e8 a2 fe ff ff       	call   f010613a <lapicw>
f0106298:	e9 70 ff ff ff       	jmp    f010620d <lapic_init+0xa5>

f010629d <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f010629d:	f3 0f 1e fb          	endbr32 
	if (lapic)
f01062a1:	83 3d 04 90 25 f0 00 	cmpl   $0x0,0xf0259004
f01062a8:	74 17                	je     f01062c1 <lapic_eoi+0x24>
{
f01062aa:	55                   	push   %ebp
f01062ab:	89 e5                	mov    %esp,%ebp
f01062ad:	83 ec 08             	sub    $0x8,%esp
		lapicw(EOI, 0);
f01062b0:	ba 00 00 00 00       	mov    $0x0,%edx
f01062b5:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01062ba:	e8 7b fe ff ff       	call   f010613a <lapicw>
}
f01062bf:	c9                   	leave  
f01062c0:	c3                   	ret    
f01062c1:	c3                   	ret    

f01062c2 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f01062c2:	f3 0f 1e fb          	endbr32 
f01062c6:	55                   	push   %ebp
f01062c7:	89 e5                	mov    %esp,%ebp
f01062c9:	56                   	push   %esi
f01062ca:	53                   	push   %ebx
f01062cb:	8b 75 08             	mov    0x8(%ebp),%esi
f01062ce:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01062d1:	b8 0f 00 00 00       	mov    $0xf,%eax
f01062d6:	ba 70 00 00 00       	mov    $0x70,%edx
f01062db:	ee                   	out    %al,(%dx)
f01062dc:	b8 0a 00 00 00       	mov    $0xa,%eax
f01062e1:	ba 71 00 00 00       	mov    $0x71,%edx
f01062e6:	ee                   	out    %al,(%dx)
	if (PGNUM(pa) >= npages)
f01062e7:	83 3d 88 7e 21 f0 00 	cmpl   $0x0,0xf0217e88
f01062ee:	74 7e                	je     f010636e <lapic_startap+0xac>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f01062f0:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f01062f7:	00 00 
	wrv[1] = addr >> 4;
f01062f9:	89 d8                	mov    %ebx,%eax
f01062fb:	c1 e8 04             	shr    $0x4,%eax
f01062fe:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0106304:	c1 e6 18             	shl    $0x18,%esi
f0106307:	89 f2                	mov    %esi,%edx
f0106309:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010630e:	e8 27 fe ff ff       	call   f010613a <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0106313:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0106318:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010631d:	e8 18 fe ff ff       	call   f010613a <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0106322:	ba 00 85 00 00       	mov    $0x8500,%edx
f0106327:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010632c:	e8 09 fe ff ff       	call   f010613a <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106331:	c1 eb 0c             	shr    $0xc,%ebx
f0106334:	80 cf 06             	or     $0x6,%bh
		lapicw(ICRHI, apicid << 24);
f0106337:	89 f2                	mov    %esi,%edx
f0106339:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010633e:	e8 f7 fd ff ff       	call   f010613a <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106343:	89 da                	mov    %ebx,%edx
f0106345:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010634a:	e8 eb fd ff ff       	call   f010613a <lapicw>
		lapicw(ICRHI, apicid << 24);
f010634f:	89 f2                	mov    %esi,%edx
f0106351:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106356:	e8 df fd ff ff       	call   f010613a <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f010635b:	89 da                	mov    %ebx,%edx
f010635d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106362:	e8 d3 fd ff ff       	call   f010613a <lapicw>
		microdelay(200);
	}
}
f0106367:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010636a:	5b                   	pop    %ebx
f010636b:	5e                   	pop    %esi
f010636c:	5d                   	pop    %ebp
f010636d:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010636e:	68 67 04 00 00       	push   $0x467
f0106373:	68 e4 67 10 f0       	push   $0xf01067e4
f0106378:	68 98 00 00 00       	push   $0x98
f010637d:	68 94 85 10 f0       	push   $0xf0108594
f0106382:	e8 b9 9c ff ff       	call   f0100040 <_panic>

f0106387 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0106387:	f3 0f 1e fb          	endbr32 
f010638b:	55                   	push   %ebp
f010638c:	89 e5                	mov    %esp,%ebp
f010638e:	83 ec 08             	sub    $0x8,%esp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0106391:	8b 55 08             	mov    0x8(%ebp),%edx
f0106394:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f010639a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010639f:	e8 96 fd ff ff       	call   f010613a <lapicw>
	while (lapic[ICRLO] & DELIVS)
f01063a4:	8b 15 04 90 25 f0    	mov    0xf0259004,%edx
f01063aa:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f01063b0:	f6 c4 10             	test   $0x10,%ah
f01063b3:	75 f5                	jne    f01063aa <lapic_ipi+0x23>
		;
}
f01063b5:	c9                   	leave  
f01063b6:	c3                   	ret    

f01063b7 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f01063b7:	f3 0f 1e fb          	endbr32 
f01063bb:	55                   	push   %ebp
f01063bc:	89 e5                	mov    %esp,%ebp
f01063be:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f01063c1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f01063c7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01063ca:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f01063cd:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f01063d4:	5d                   	pop    %ebp
f01063d5:	c3                   	ret    

f01063d6 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f01063d6:	f3 0f 1e fb          	endbr32 
f01063da:	55                   	push   %ebp
f01063db:	89 e5                	mov    %esp,%ebp
f01063dd:	56                   	push   %esi
f01063de:	53                   	push   %ebx
f01063df:	8b 5d 08             	mov    0x8(%ebp),%ebx
	return lock->locked && lock->cpu == thiscpu;
f01063e2:	83 3b 00             	cmpl   $0x0,(%ebx)
f01063e5:	75 07                	jne    f01063ee <spin_lock+0x18>
	asm volatile("lock; xchgl %0, %1"
f01063e7:	ba 01 00 00 00       	mov    $0x1,%edx
f01063ec:	eb 34                	jmp    f0106422 <spin_lock+0x4c>
f01063ee:	8b 73 08             	mov    0x8(%ebx),%esi
f01063f1:	e8 58 fd ff ff       	call   f010614e <cpunum>
f01063f6:	6b c0 74             	imul   $0x74,%eax,%eax
f01063f9:	05 20 80 21 f0       	add    $0xf0218020,%eax
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f01063fe:	39 c6                	cmp    %eax,%esi
f0106400:	75 e5                	jne    f01063e7 <spin_lock+0x11>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0106402:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0106405:	e8 44 fd ff ff       	call   f010614e <cpunum>
f010640a:	83 ec 0c             	sub    $0xc,%esp
f010640d:	53                   	push   %ebx
f010640e:	50                   	push   %eax
f010640f:	68 a4 85 10 f0       	push   $0xf01085a4
f0106414:	6a 41                	push   $0x41
f0106416:	68 06 86 10 f0       	push   $0xf0108606
f010641b:	e8 20 9c ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0106420:	f3 90                	pause  
f0106422:	89 d0                	mov    %edx,%eax
f0106424:	f0 87 03             	lock xchg %eax,(%ebx)
	while (xchg(&lk->locked, 1) != 0)
f0106427:	85 c0                	test   %eax,%eax
f0106429:	75 f5                	jne    f0106420 <spin_lock+0x4a>

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f010642b:	e8 1e fd ff ff       	call   f010614e <cpunum>
f0106430:	6b c0 74             	imul   $0x74,%eax,%eax
f0106433:	05 20 80 21 f0       	add    $0xf0218020,%eax
f0106438:	89 43 08             	mov    %eax,0x8(%ebx)
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010643b:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f010643d:	b8 00 00 00 00       	mov    $0x0,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0106442:	83 f8 09             	cmp    $0x9,%eax
f0106445:	7f 21                	jg     f0106468 <spin_lock+0x92>
f0106447:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f010644d:	76 19                	jbe    f0106468 <spin_lock+0x92>
		pcs[i] = ebp[1];          // saved %eip
f010644f:	8b 4a 04             	mov    0x4(%edx),%ecx
f0106452:	89 4c 83 0c          	mov    %ecx,0xc(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0106456:	8b 12                	mov    (%edx),%edx
	for (i = 0; i < 10; i++){
f0106458:	83 c0 01             	add    $0x1,%eax
f010645b:	eb e5                	jmp    f0106442 <spin_lock+0x6c>
		pcs[i] = 0;
f010645d:	c7 44 83 0c 00 00 00 	movl   $0x0,0xc(%ebx,%eax,4)
f0106464:	00 
	for (; i < 10; i++)
f0106465:	83 c0 01             	add    $0x1,%eax
f0106468:	83 f8 09             	cmp    $0x9,%eax
f010646b:	7e f0                	jle    f010645d <spin_lock+0x87>
	get_caller_pcs(lk->pcs);
#endif
}
f010646d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0106470:	5b                   	pop    %ebx
f0106471:	5e                   	pop    %esi
f0106472:	5d                   	pop    %ebp
f0106473:	c3                   	ret    

f0106474 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0106474:	f3 0f 1e fb          	endbr32 
f0106478:	55                   	push   %ebp
f0106479:	89 e5                	mov    %esp,%ebp
f010647b:	57                   	push   %edi
f010647c:	56                   	push   %esi
f010647d:	53                   	push   %ebx
f010647e:	83 ec 4c             	sub    $0x4c,%esp
f0106481:	8b 75 08             	mov    0x8(%ebp),%esi
	return lock->locked && lock->cpu == thiscpu;
f0106484:	83 3e 00             	cmpl   $0x0,(%esi)
f0106487:	75 35                	jne    f01064be <spin_unlock+0x4a>
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0106489:	83 ec 04             	sub    $0x4,%esp
f010648c:	6a 28                	push   $0x28
f010648e:	8d 46 0c             	lea    0xc(%esi),%eax
f0106491:	50                   	push   %eax
f0106492:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0106495:	53                   	push   %ebx
f0106496:	e8 e0 f6 ff ff       	call   f0105b7b <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f010649b:	8b 46 08             	mov    0x8(%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f010649e:	0f b6 38             	movzbl (%eax),%edi
f01064a1:	8b 76 04             	mov    0x4(%esi),%esi
f01064a4:	e8 a5 fc ff ff       	call   f010614e <cpunum>
f01064a9:	57                   	push   %edi
f01064aa:	56                   	push   %esi
f01064ab:	50                   	push   %eax
f01064ac:	68 d0 85 10 f0       	push   $0xf01085d0
f01064b1:	e8 f6 d4 ff ff       	call   f01039ac <cprintf>
f01064b6:	83 c4 20             	add    $0x20,%esp
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f01064b9:	8d 7d a8             	lea    -0x58(%ebp),%edi
f01064bc:	eb 4e                	jmp    f010650c <spin_unlock+0x98>
	return lock->locked && lock->cpu == thiscpu;
f01064be:	8b 5e 08             	mov    0x8(%esi),%ebx
f01064c1:	e8 88 fc ff ff       	call   f010614e <cpunum>
f01064c6:	6b c0 74             	imul   $0x74,%eax,%eax
f01064c9:	05 20 80 21 f0       	add    $0xf0218020,%eax
	if (!holding(lk)) {
f01064ce:	39 c3                	cmp    %eax,%ebx
f01064d0:	75 b7                	jne    f0106489 <spin_unlock+0x15>
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
	}

	lk->pcs[0] = 0;
f01064d2:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f01064d9:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
	asm volatile("lock; xchgl %0, %1"
f01064e0:	b8 00 00 00 00       	mov    $0x0,%eax
f01064e5:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f01064e8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01064eb:	5b                   	pop    %ebx
f01064ec:	5e                   	pop    %esi
f01064ed:	5f                   	pop    %edi
f01064ee:	5d                   	pop    %ebp
f01064ef:	c3                   	ret    
				cprintf("  %08x\n", pcs[i]);
f01064f0:	83 ec 08             	sub    $0x8,%esp
f01064f3:	ff 36                	pushl  (%esi)
f01064f5:	68 2d 86 10 f0       	push   $0xf010862d
f01064fa:	e8 ad d4 ff ff       	call   f01039ac <cprintf>
f01064ff:	83 c4 10             	add    $0x10,%esp
f0106502:	83 c3 04             	add    $0x4,%ebx
		for (i = 0; i < 10 && pcs[i]; i++) {
f0106505:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0106508:	39 c3                	cmp    %eax,%ebx
f010650a:	74 40                	je     f010654c <spin_unlock+0xd8>
f010650c:	89 de                	mov    %ebx,%esi
f010650e:	8b 03                	mov    (%ebx),%eax
f0106510:	85 c0                	test   %eax,%eax
f0106512:	74 38                	je     f010654c <spin_unlock+0xd8>
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0106514:	83 ec 08             	sub    $0x8,%esp
f0106517:	57                   	push   %edi
f0106518:	50                   	push   %eax
f0106519:	e8 cc ea ff ff       	call   f0104fea <debuginfo_eip>
f010651e:	83 c4 10             	add    $0x10,%esp
f0106521:	85 c0                	test   %eax,%eax
f0106523:	78 cb                	js     f01064f0 <spin_unlock+0x7c>
					pcs[i] - info.eip_fn_addr);
f0106525:	8b 06                	mov    (%esi),%eax
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0106527:	83 ec 04             	sub    $0x4,%esp
f010652a:	89 c2                	mov    %eax,%edx
f010652c:	2b 55 b8             	sub    -0x48(%ebp),%edx
f010652f:	52                   	push   %edx
f0106530:	ff 75 b0             	pushl  -0x50(%ebp)
f0106533:	ff 75 b4             	pushl  -0x4c(%ebp)
f0106536:	ff 75 ac             	pushl  -0x54(%ebp)
f0106539:	ff 75 a8             	pushl  -0x58(%ebp)
f010653c:	50                   	push   %eax
f010653d:	68 16 86 10 f0       	push   $0xf0108616
f0106542:	e8 65 d4 ff ff       	call   f01039ac <cprintf>
f0106547:	83 c4 20             	add    $0x20,%esp
f010654a:	eb b6                	jmp    f0106502 <spin_unlock+0x8e>
		panic("spin_unlock");
f010654c:	83 ec 04             	sub    $0x4,%esp
f010654f:	68 35 86 10 f0       	push   $0xf0108635
f0106554:	6a 67                	push   $0x67
f0106556:	68 06 86 10 f0       	push   $0xf0108606
f010655b:	e8 e0 9a ff ff       	call   f0100040 <_panic>

f0106560 <__udivdi3>:
f0106560:	f3 0f 1e fb          	endbr32 
f0106564:	55                   	push   %ebp
f0106565:	57                   	push   %edi
f0106566:	56                   	push   %esi
f0106567:	53                   	push   %ebx
f0106568:	83 ec 1c             	sub    $0x1c,%esp
f010656b:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010656f:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0106573:	8b 74 24 34          	mov    0x34(%esp),%esi
f0106577:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f010657b:	85 d2                	test   %edx,%edx
f010657d:	75 19                	jne    f0106598 <__udivdi3+0x38>
f010657f:	39 f3                	cmp    %esi,%ebx
f0106581:	76 4d                	jbe    f01065d0 <__udivdi3+0x70>
f0106583:	31 ff                	xor    %edi,%edi
f0106585:	89 e8                	mov    %ebp,%eax
f0106587:	89 f2                	mov    %esi,%edx
f0106589:	f7 f3                	div    %ebx
f010658b:	89 fa                	mov    %edi,%edx
f010658d:	83 c4 1c             	add    $0x1c,%esp
f0106590:	5b                   	pop    %ebx
f0106591:	5e                   	pop    %esi
f0106592:	5f                   	pop    %edi
f0106593:	5d                   	pop    %ebp
f0106594:	c3                   	ret    
f0106595:	8d 76 00             	lea    0x0(%esi),%esi
f0106598:	39 f2                	cmp    %esi,%edx
f010659a:	76 14                	jbe    f01065b0 <__udivdi3+0x50>
f010659c:	31 ff                	xor    %edi,%edi
f010659e:	31 c0                	xor    %eax,%eax
f01065a0:	89 fa                	mov    %edi,%edx
f01065a2:	83 c4 1c             	add    $0x1c,%esp
f01065a5:	5b                   	pop    %ebx
f01065a6:	5e                   	pop    %esi
f01065a7:	5f                   	pop    %edi
f01065a8:	5d                   	pop    %ebp
f01065a9:	c3                   	ret    
f01065aa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01065b0:	0f bd fa             	bsr    %edx,%edi
f01065b3:	83 f7 1f             	xor    $0x1f,%edi
f01065b6:	75 48                	jne    f0106600 <__udivdi3+0xa0>
f01065b8:	39 f2                	cmp    %esi,%edx
f01065ba:	72 06                	jb     f01065c2 <__udivdi3+0x62>
f01065bc:	31 c0                	xor    %eax,%eax
f01065be:	39 eb                	cmp    %ebp,%ebx
f01065c0:	77 de                	ja     f01065a0 <__udivdi3+0x40>
f01065c2:	b8 01 00 00 00       	mov    $0x1,%eax
f01065c7:	eb d7                	jmp    f01065a0 <__udivdi3+0x40>
f01065c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01065d0:	89 d9                	mov    %ebx,%ecx
f01065d2:	85 db                	test   %ebx,%ebx
f01065d4:	75 0b                	jne    f01065e1 <__udivdi3+0x81>
f01065d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01065db:	31 d2                	xor    %edx,%edx
f01065dd:	f7 f3                	div    %ebx
f01065df:	89 c1                	mov    %eax,%ecx
f01065e1:	31 d2                	xor    %edx,%edx
f01065e3:	89 f0                	mov    %esi,%eax
f01065e5:	f7 f1                	div    %ecx
f01065e7:	89 c6                	mov    %eax,%esi
f01065e9:	89 e8                	mov    %ebp,%eax
f01065eb:	89 f7                	mov    %esi,%edi
f01065ed:	f7 f1                	div    %ecx
f01065ef:	89 fa                	mov    %edi,%edx
f01065f1:	83 c4 1c             	add    $0x1c,%esp
f01065f4:	5b                   	pop    %ebx
f01065f5:	5e                   	pop    %esi
f01065f6:	5f                   	pop    %edi
f01065f7:	5d                   	pop    %ebp
f01065f8:	c3                   	ret    
f01065f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106600:	89 f9                	mov    %edi,%ecx
f0106602:	b8 20 00 00 00       	mov    $0x20,%eax
f0106607:	29 f8                	sub    %edi,%eax
f0106609:	d3 e2                	shl    %cl,%edx
f010660b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010660f:	89 c1                	mov    %eax,%ecx
f0106611:	89 da                	mov    %ebx,%edx
f0106613:	d3 ea                	shr    %cl,%edx
f0106615:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0106619:	09 d1                	or     %edx,%ecx
f010661b:	89 f2                	mov    %esi,%edx
f010661d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106621:	89 f9                	mov    %edi,%ecx
f0106623:	d3 e3                	shl    %cl,%ebx
f0106625:	89 c1                	mov    %eax,%ecx
f0106627:	d3 ea                	shr    %cl,%edx
f0106629:	89 f9                	mov    %edi,%ecx
f010662b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010662f:	89 eb                	mov    %ebp,%ebx
f0106631:	d3 e6                	shl    %cl,%esi
f0106633:	89 c1                	mov    %eax,%ecx
f0106635:	d3 eb                	shr    %cl,%ebx
f0106637:	09 de                	or     %ebx,%esi
f0106639:	89 f0                	mov    %esi,%eax
f010663b:	f7 74 24 08          	divl   0x8(%esp)
f010663f:	89 d6                	mov    %edx,%esi
f0106641:	89 c3                	mov    %eax,%ebx
f0106643:	f7 64 24 0c          	mull   0xc(%esp)
f0106647:	39 d6                	cmp    %edx,%esi
f0106649:	72 15                	jb     f0106660 <__udivdi3+0x100>
f010664b:	89 f9                	mov    %edi,%ecx
f010664d:	d3 e5                	shl    %cl,%ebp
f010664f:	39 c5                	cmp    %eax,%ebp
f0106651:	73 04                	jae    f0106657 <__udivdi3+0xf7>
f0106653:	39 d6                	cmp    %edx,%esi
f0106655:	74 09                	je     f0106660 <__udivdi3+0x100>
f0106657:	89 d8                	mov    %ebx,%eax
f0106659:	31 ff                	xor    %edi,%edi
f010665b:	e9 40 ff ff ff       	jmp    f01065a0 <__udivdi3+0x40>
f0106660:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0106663:	31 ff                	xor    %edi,%edi
f0106665:	e9 36 ff ff ff       	jmp    f01065a0 <__udivdi3+0x40>
f010666a:	66 90                	xchg   %ax,%ax
f010666c:	66 90                	xchg   %ax,%ax
f010666e:	66 90                	xchg   %ax,%ax

f0106670 <__umoddi3>:
f0106670:	f3 0f 1e fb          	endbr32 
f0106674:	55                   	push   %ebp
f0106675:	57                   	push   %edi
f0106676:	56                   	push   %esi
f0106677:	53                   	push   %ebx
f0106678:	83 ec 1c             	sub    $0x1c,%esp
f010667b:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010667f:	8b 74 24 30          	mov    0x30(%esp),%esi
f0106683:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0106687:	8b 7c 24 38          	mov    0x38(%esp),%edi
f010668b:	85 c0                	test   %eax,%eax
f010668d:	75 19                	jne    f01066a8 <__umoddi3+0x38>
f010668f:	39 df                	cmp    %ebx,%edi
f0106691:	76 5d                	jbe    f01066f0 <__umoddi3+0x80>
f0106693:	89 f0                	mov    %esi,%eax
f0106695:	89 da                	mov    %ebx,%edx
f0106697:	f7 f7                	div    %edi
f0106699:	89 d0                	mov    %edx,%eax
f010669b:	31 d2                	xor    %edx,%edx
f010669d:	83 c4 1c             	add    $0x1c,%esp
f01066a0:	5b                   	pop    %ebx
f01066a1:	5e                   	pop    %esi
f01066a2:	5f                   	pop    %edi
f01066a3:	5d                   	pop    %ebp
f01066a4:	c3                   	ret    
f01066a5:	8d 76 00             	lea    0x0(%esi),%esi
f01066a8:	89 f2                	mov    %esi,%edx
f01066aa:	39 d8                	cmp    %ebx,%eax
f01066ac:	76 12                	jbe    f01066c0 <__umoddi3+0x50>
f01066ae:	89 f0                	mov    %esi,%eax
f01066b0:	89 da                	mov    %ebx,%edx
f01066b2:	83 c4 1c             	add    $0x1c,%esp
f01066b5:	5b                   	pop    %ebx
f01066b6:	5e                   	pop    %esi
f01066b7:	5f                   	pop    %edi
f01066b8:	5d                   	pop    %ebp
f01066b9:	c3                   	ret    
f01066ba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01066c0:	0f bd e8             	bsr    %eax,%ebp
f01066c3:	83 f5 1f             	xor    $0x1f,%ebp
f01066c6:	75 50                	jne    f0106718 <__umoddi3+0xa8>
f01066c8:	39 d8                	cmp    %ebx,%eax
f01066ca:	0f 82 e0 00 00 00    	jb     f01067b0 <__umoddi3+0x140>
f01066d0:	89 d9                	mov    %ebx,%ecx
f01066d2:	39 f7                	cmp    %esi,%edi
f01066d4:	0f 86 d6 00 00 00    	jbe    f01067b0 <__umoddi3+0x140>
f01066da:	89 d0                	mov    %edx,%eax
f01066dc:	89 ca                	mov    %ecx,%edx
f01066de:	83 c4 1c             	add    $0x1c,%esp
f01066e1:	5b                   	pop    %ebx
f01066e2:	5e                   	pop    %esi
f01066e3:	5f                   	pop    %edi
f01066e4:	5d                   	pop    %ebp
f01066e5:	c3                   	ret    
f01066e6:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01066ed:	8d 76 00             	lea    0x0(%esi),%esi
f01066f0:	89 fd                	mov    %edi,%ebp
f01066f2:	85 ff                	test   %edi,%edi
f01066f4:	75 0b                	jne    f0106701 <__umoddi3+0x91>
f01066f6:	b8 01 00 00 00       	mov    $0x1,%eax
f01066fb:	31 d2                	xor    %edx,%edx
f01066fd:	f7 f7                	div    %edi
f01066ff:	89 c5                	mov    %eax,%ebp
f0106701:	89 d8                	mov    %ebx,%eax
f0106703:	31 d2                	xor    %edx,%edx
f0106705:	f7 f5                	div    %ebp
f0106707:	89 f0                	mov    %esi,%eax
f0106709:	f7 f5                	div    %ebp
f010670b:	89 d0                	mov    %edx,%eax
f010670d:	31 d2                	xor    %edx,%edx
f010670f:	eb 8c                	jmp    f010669d <__umoddi3+0x2d>
f0106711:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106718:	89 e9                	mov    %ebp,%ecx
f010671a:	ba 20 00 00 00       	mov    $0x20,%edx
f010671f:	29 ea                	sub    %ebp,%edx
f0106721:	d3 e0                	shl    %cl,%eax
f0106723:	89 44 24 08          	mov    %eax,0x8(%esp)
f0106727:	89 d1                	mov    %edx,%ecx
f0106729:	89 f8                	mov    %edi,%eax
f010672b:	d3 e8                	shr    %cl,%eax
f010672d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0106731:	89 54 24 04          	mov    %edx,0x4(%esp)
f0106735:	8b 54 24 04          	mov    0x4(%esp),%edx
f0106739:	09 c1                	or     %eax,%ecx
f010673b:	89 d8                	mov    %ebx,%eax
f010673d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106741:	89 e9                	mov    %ebp,%ecx
f0106743:	d3 e7                	shl    %cl,%edi
f0106745:	89 d1                	mov    %edx,%ecx
f0106747:	d3 e8                	shr    %cl,%eax
f0106749:	89 e9                	mov    %ebp,%ecx
f010674b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010674f:	d3 e3                	shl    %cl,%ebx
f0106751:	89 c7                	mov    %eax,%edi
f0106753:	89 d1                	mov    %edx,%ecx
f0106755:	89 f0                	mov    %esi,%eax
f0106757:	d3 e8                	shr    %cl,%eax
f0106759:	89 e9                	mov    %ebp,%ecx
f010675b:	89 fa                	mov    %edi,%edx
f010675d:	d3 e6                	shl    %cl,%esi
f010675f:	09 d8                	or     %ebx,%eax
f0106761:	f7 74 24 08          	divl   0x8(%esp)
f0106765:	89 d1                	mov    %edx,%ecx
f0106767:	89 f3                	mov    %esi,%ebx
f0106769:	f7 64 24 0c          	mull   0xc(%esp)
f010676d:	89 c6                	mov    %eax,%esi
f010676f:	89 d7                	mov    %edx,%edi
f0106771:	39 d1                	cmp    %edx,%ecx
f0106773:	72 06                	jb     f010677b <__umoddi3+0x10b>
f0106775:	75 10                	jne    f0106787 <__umoddi3+0x117>
f0106777:	39 c3                	cmp    %eax,%ebx
f0106779:	73 0c                	jae    f0106787 <__umoddi3+0x117>
f010677b:	2b 44 24 0c          	sub    0xc(%esp),%eax
f010677f:	1b 54 24 08          	sbb    0x8(%esp),%edx
f0106783:	89 d7                	mov    %edx,%edi
f0106785:	89 c6                	mov    %eax,%esi
f0106787:	89 ca                	mov    %ecx,%edx
f0106789:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010678e:	29 f3                	sub    %esi,%ebx
f0106790:	19 fa                	sbb    %edi,%edx
f0106792:	89 d0                	mov    %edx,%eax
f0106794:	d3 e0                	shl    %cl,%eax
f0106796:	89 e9                	mov    %ebp,%ecx
f0106798:	d3 eb                	shr    %cl,%ebx
f010679a:	d3 ea                	shr    %cl,%edx
f010679c:	09 d8                	or     %ebx,%eax
f010679e:	83 c4 1c             	add    $0x1c,%esp
f01067a1:	5b                   	pop    %ebx
f01067a2:	5e                   	pop    %esi
f01067a3:	5f                   	pop    %edi
f01067a4:	5d                   	pop    %ebp
f01067a5:	c3                   	ret    
f01067a6:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01067ad:	8d 76 00             	lea    0x0(%esi),%esi
f01067b0:	29 fe                	sub    %edi,%esi
f01067b2:	19 c3                	sbb    %eax,%ebx
f01067b4:	89 f2                	mov    %esi,%edx
f01067b6:	89 d9                	mov    %ebx,%ecx
f01067b8:	e9 1d ff ff ff       	jmp    f01066da <__umoddi3+0x6a>
