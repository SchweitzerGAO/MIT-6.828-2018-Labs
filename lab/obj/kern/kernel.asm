
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
f010006f:	e8 ba 60 00 00       	call   f010612e <cpunum>
f0100074:	ff 75 0c             	pushl  0xc(%ebp)
f0100077:	ff 75 08             	pushl  0x8(%ebp)
f010007a:	50                   	push   %eax
f010007b:	68 a0 67 10 f0       	push   $0xf01067a0
f0100080:	e8 3c 39 00 00       	call   f01039c1 <cprintf>
	vcprintf(fmt, ap);
f0100085:	83 c4 08             	add    $0x8,%esp
f0100088:	53                   	push   %ebx
f0100089:	56                   	push   %esi
f010008a:	e8 08 39 00 00       	call   f0103997 <vcprintf>
	cprintf("\n");
f010008f:	c7 04 24 e1 79 10 f0 	movl   $0xf01079e1,(%esp)
f0100096:	e8 26 39 00 00       	call   f01039c1 <cprintf>
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
f01000b8:	68 0c 68 10 f0       	push   $0xf010680c
f01000bd:	e8 ff 38 00 00       	call   f01039c1 <cprintf>
	mem_init();
f01000c2:	e8 be 12 00 00       	call   f0101385 <mem_init>
	env_init();
f01000c7:	e8 01 31 00 00       	call   f01031cd <env_init>
	trap_init();
f01000cc:	e8 ec 39 00 00       	call   f0103abd <trap_init>
	mp_init();
f01000d1:	e8 59 5d 00 00       	call   f0105e2f <mp_init>
	lapic_init();
f01000d6:	e8 6d 60 00 00       	call   f0106148 <lapic_init>
	pic_init();
f01000db:	e8 f6 37 00 00       	call   f01038d6 <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000e0:	c7 04 24 c0 33 12 f0 	movl   $0xf01233c0,(%esp)
f01000e7:	e8 ca 62 00 00       	call   f01063b6 <spin_lock>
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
f01000fb:	b8 92 5d 10 f0       	mov    $0xf0105d92,%eax
f0100100:	2d 18 5d 10 f0       	sub    $0xf0105d18,%eax
f0100105:	50                   	push   %eax
f0100106:	68 18 5d 10 f0       	push   $0xf0105d18
f010010b:	68 00 70 00 f0       	push   $0xf0007000
f0100110:	e8 47 5a 00 00       	call   f0105b5c <memmove>
	for (c = cpus; c < cpus + ncpu; c++) {
f0100115:	83 c4 10             	add    $0x10,%esp
f0100118:	bb 20 80 21 f0       	mov    $0xf0218020,%ebx
f010011d:	eb 53                	jmp    f0100172 <i386_init+0xd2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010011f:	68 00 70 00 00       	push   $0x7000
f0100124:	68 c4 67 10 f0       	push   $0xf01067c4
f0100129:	6a 52                	push   $0x52
f010012b:	68 27 68 10 f0       	push   $0xf0106827
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
f010015f:	e8 3e 61 00 00       	call   f01062a2 <lapic_startap>
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
f0100182:	e8 a7 5f 00 00       	call   f010612e <cpunum>
f0100187:	6b c0 74             	imul   $0x74,%eax,%eax
f010018a:	05 20 80 21 f0       	add    $0xf0218020,%eax
f010018f:	39 c3                	cmp    %eax,%ebx
f0100191:	74 dc                	je     f010016f <i386_init+0xcf>
f0100193:	eb a0                	jmp    f0100135 <i386_init+0x95>
	ENV_CREATE(fs_fs, ENV_TYPE_FS);
f0100195:	83 ec 08             	sub    $0x8,%esp
f0100198:	6a 01                	push   $0x1
f010019a:	68 a8 38 1d f0       	push   $0xf01d38a8
f010019f:	e8 f0 31 00 00       	call   f0103394 <env_create>
	ENV_CREATE(TEST, ENV_TYPE_USER);
f01001a4:	83 c4 08             	add    $0x8,%esp
f01001a7:	6a 00                	push   $0x0
f01001a9:	68 00 cd 1e f0       	push   $0xf01ecd00
f01001ae:	e8 e1 31 00 00       	call   f0103394 <env_create>
	kbd_intr();
f01001b3:	e8 5a 04 00 00       	call   f0100612 <kbd_intr>
	sched_yield();
f01001b8:	e8 a6 46 00 00       	call   f0104863 <sched_yield>

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
f01001db:	e8 4e 5f 00 00       	call   f010612e <cpunum>
f01001e0:	83 ec 08             	sub    $0x8,%esp
f01001e3:	50                   	push   %eax
f01001e4:	68 33 68 10 f0       	push   $0xf0106833
f01001e9:	e8 d3 37 00 00       	call   f01039c1 <cprintf>
	lapic_init();
f01001ee:	e8 55 5f 00 00       	call   f0106148 <lapic_init>
	env_init_percpu();
f01001f3:	e8 a5 2f 00 00       	call   f010319d <env_init_percpu>
	trap_init_percpu();
f01001f8:	e8 dc 37 00 00       	call   f01039d9 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f01001fd:	e8 2c 5f 00 00       	call   f010612e <cpunum>
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
f010021b:	e8 96 61 00 00       	call   f01063b6 <spin_lock>
	sched_yield();
f0100220:	e8 3e 46 00 00       	call   f0104863 <sched_yield>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100225:	50                   	push   %eax
f0100226:	68 e8 67 10 f0       	push   $0xf01067e8
f010022b:	6a 69                	push   $0x69
f010022d:	68 27 68 10 f0       	push   $0xf0106827
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
f010024b:	68 49 68 10 f0       	push   $0xf0106849
f0100250:	e8 6c 37 00 00       	call   f01039c1 <cprintf>
	vcprintf(fmt, ap);
f0100255:	83 c4 08             	add    $0x8,%esp
f0100258:	53                   	push   %ebx
f0100259:	ff 75 10             	pushl  0x10(%ebp)
f010025c:	e8 36 37 00 00       	call   f0103997 <vcprintf>
	cprintf("\n");
f0100261:	c7 04 24 e1 79 10 f0 	movl   $0xf01079e1,(%esp)
f0100268:	e8 54 37 00 00       	call   f01039c1 <cprintf>
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
f010031f:	0f b6 82 c0 69 10 f0 	movzbl -0xfef9640(%edx),%eax
f0100326:	0b 05 00 70 21 f0    	or     0xf0217000,%eax
	shift ^= togglecode[data];
f010032c:	0f b6 8a c0 68 10 f0 	movzbl -0xfef9740(%edx),%ecx
f0100333:	31 c8                	xor    %ecx,%eax
f0100335:	a3 00 70 21 f0       	mov    %eax,0xf0217000
	c = charcode[shift & (CTL | SHIFT)][data];
f010033a:	89 c1                	mov    %eax,%ecx
f010033c:	83 e1 03             	and    $0x3,%ecx
f010033f:	8b 0c 8d a0 68 10 f0 	mov    -0xfef9760(,%ecx,4),%ecx
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
f0100389:	0f b6 82 c0 69 10 f0 	movzbl -0xfef9640(%edx),%eax
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
f01003c3:	68 63 68 10 f0       	push   $0xf0106863
f01003c8:	e8 f4 35 00 00       	call   f01039c1 <cprintf>
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
f01005bf:	e8 98 55 00 00       	call   f0105b5c <memmove>
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
f01006f8:	e8 57 31 00 00       	call   f0103854 <irq_setmask_8259A>
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
f010076b:	68 6f 68 10 f0       	push   $0xf010686f
f0100770:	e8 4c 32 00 00       	call   f01039c1 <cprintf>
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
f01007a5:	e8 aa 30 00 00       	call   f0103854 <irq_setmask_8259A>
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
f01007fb:	68 c0 6a 10 f0       	push   $0xf0106ac0
f0100800:	68 de 6a 10 f0       	push   $0xf0106ade
f0100805:	68 e3 6a 10 f0       	push   $0xf0106ae3
f010080a:	e8 b2 31 00 00       	call   f01039c1 <cprintf>
f010080f:	83 c4 0c             	add    $0xc,%esp
f0100812:	68 b0 6b 10 f0       	push   $0xf0106bb0
f0100817:	68 ec 6a 10 f0       	push   $0xf0106aec
f010081c:	68 e3 6a 10 f0       	push   $0xf0106ae3
f0100821:	e8 9b 31 00 00       	call   f01039c1 <cprintf>
f0100826:	83 c4 0c             	add    $0xc,%esp
f0100829:	68 f5 6a 10 f0       	push   $0xf0106af5
f010082e:	68 0b 6b 10 f0       	push   $0xf0106b0b
f0100833:	68 e3 6a 10 f0       	push   $0xf0106ae3
f0100838:	e8 84 31 00 00       	call   f01039c1 <cprintf>
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
f010084e:	68 15 6b 10 f0       	push   $0xf0106b15
f0100853:	e8 69 31 00 00       	call   f01039c1 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100858:	83 c4 08             	add    $0x8,%esp
f010085b:	68 0c 00 10 00       	push   $0x10000c
f0100860:	68 d8 6b 10 f0       	push   $0xf0106bd8
f0100865:	e8 57 31 00 00       	call   f01039c1 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010086a:	83 c4 0c             	add    $0xc,%esp
f010086d:	68 0c 00 10 00       	push   $0x10000c
f0100872:	68 0c 00 10 f0       	push   $0xf010000c
f0100877:	68 00 6c 10 f0       	push   $0xf0106c00
f010087c:	e8 40 31 00 00       	call   f01039c1 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100881:	83 c4 0c             	add    $0xc,%esp
f0100884:	68 9d 67 10 00       	push   $0x10679d
f0100889:	68 9d 67 10 f0       	push   $0xf010679d
f010088e:	68 24 6c 10 f0       	push   $0xf0106c24
f0100893:	e8 29 31 00 00       	call   f01039c1 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100898:	83 c4 0c             	add    $0xc,%esp
f010089b:	68 00 70 21 00       	push   $0x217000
f01008a0:	68 00 70 21 f0       	push   $0xf0217000
f01008a5:	68 48 6c 10 f0       	push   $0xf0106c48
f01008aa:	e8 12 31 00 00       	call   f01039c1 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01008af:	83 c4 0c             	add    $0xc,%esp
f01008b2:	68 09 90 25 00       	push   $0x259009
f01008b7:	68 09 90 25 f0       	push   $0xf0259009
f01008bc:	68 6c 6c 10 f0       	push   $0xf0106c6c
f01008c1:	e8 fb 30 00 00       	call   f01039c1 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008c6:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01008c9:	b8 09 90 25 f0       	mov    $0xf0259009,%eax
f01008ce:	2d 0d fc 0f f0       	sub    $0xf00ffc0d,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008d3:	c1 f8 0a             	sar    $0xa,%eax
f01008d6:	50                   	push   %eax
f01008d7:	68 90 6c 10 f0       	push   $0xf0106c90
f01008dc:	e8 e0 30 00 00       	call   f01039c1 <cprintf>
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
f0100901:	68 2e 6b 10 f0       	push   $0xf0106b2e
f0100906:	e8 b6 30 00 00       	call   f01039c1 <cprintf>
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
f0100925:	68 40 6b 10 f0       	push   $0xf0106b40
f010092a:	e8 92 30 00 00       	call   f01039c1 <cprintf>
f010092f:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100932:	8d 7e 1c             	lea    0x1c(%esi),%edi
f0100935:	83 c4 10             	add    $0x10,%esp
            cprintf("%08x ", args[i]);
f0100938:	83 ec 08             	sub    $0x8,%esp
f010093b:	ff 33                	pushl  (%ebx)
f010093d:	68 5b 6b 10 f0       	push   $0xf0106b5b
f0100942:	e8 7a 30 00 00       	call   f01039c1 <cprintf>
f0100947:	83 c3 04             	add    $0x4,%ebx
        for (int i = 0; i < 5; ++i) {
f010094a:	83 c4 10             	add    $0x10,%esp
f010094d:	39 fb                	cmp    %edi,%ebx
f010094f:	75 e7                	jne    f0100938 <mon_backtrace+0x50>
        cprintf("\n");
f0100951:	83 ec 0c             	sub    $0xc,%esp
f0100954:	68 e1 79 10 f0       	push   $0xf01079e1
f0100959:	e8 63 30 00 00       	call   f01039c1 <cprintf>
        if(debuginfo_eip(eip,&info) == 0)
f010095e:	83 c4 08             	add    $0x8,%esp
f0100961:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100964:	50                   	push   %eax
f0100965:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100968:	e8 5e 46 00 00       	call   f0104fcb <debuginfo_eip>
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
f010098a:	68 61 6b 10 f0       	push   $0xf0106b61
f010098f:	e8 2d 30 00 00       	call   f01039c1 <cprintf>
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
f01009b6:	68 bc 6c 10 f0       	push   $0xf0106cbc
f01009bb:	e8 01 30 00 00       	call   f01039c1 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009c0:	c7 04 24 e0 6c 10 f0 	movl   $0xf0106ce0,(%esp)
f01009c7:	e8 f5 2f 00 00       	call   f01039c1 <cprintf>

	if (tf != NULL)
f01009cc:	83 c4 10             	add    $0x10,%esp
f01009cf:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01009d3:	0f 84 d9 00 00 00    	je     f0100ab2 <monitor+0x109>
		print_trapframe(tf);
f01009d9:	83 ec 0c             	sub    $0xc,%esp
f01009dc:	ff 75 08             	pushl  0x8(%ebp)
f01009df:	e8 88 37 00 00       	call   f010416c <print_trapframe>
f01009e4:	83 c4 10             	add    $0x10,%esp
f01009e7:	e9 c6 00 00 00       	jmp    f0100ab2 <monitor+0x109>
		while (*buf && strchr(WHITESPACE, *buf))
f01009ec:	83 ec 08             	sub    $0x8,%esp
f01009ef:	0f be c0             	movsbl %al,%eax
f01009f2:	50                   	push   %eax
f01009f3:	68 77 6b 10 f0       	push   $0xf0106b77
f01009f8:	e8 ce 50 00 00       	call   f0105acb <strchr>
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
f0100a30:	ff 34 85 20 6d 10 f0 	pushl  -0xfef92e0(,%eax,4)
f0100a37:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a3a:	e8 26 50 00 00       	call   f0105a65 <strcmp>
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
f0100a58:	68 99 6b 10 f0       	push   $0xf0106b99
f0100a5d:	e8 5f 2f 00 00       	call   f01039c1 <cprintf>
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
f0100a86:	68 77 6b 10 f0       	push   $0xf0106b77
f0100a8b:	e8 3b 50 00 00       	call   f0105acb <strchr>
f0100a90:	83 c4 10             	add    $0x10,%esp
f0100a93:	85 c0                	test   %eax,%eax
f0100a95:	0f 85 71 ff ff ff    	jne    f0100a0c <monitor+0x63>
			buf++;
f0100a9b:	83 c3 01             	add    $0x1,%ebx
f0100a9e:	eb d8                	jmp    f0100a78 <monitor+0xcf>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100aa0:	83 ec 08             	sub    $0x8,%esp
f0100aa3:	6a 10                	push   $0x10
f0100aa5:	68 7c 6b 10 f0       	push   $0xf0106b7c
f0100aaa:	e8 12 2f 00 00       	call   f01039c1 <cprintf>
			return 0;
f0100aaf:	83 c4 10             	add    $0x10,%esp
	// cprintf("x %d, y %x, z %d\n", x, y, z);
	// unsigned int i = 0x00646c72;
 	// cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100ab2:	83 ec 0c             	sub    $0xc,%esp
f0100ab5:	68 73 6b 10 f0       	push   $0xf0106b73
f0100aba:	e8 b2 4d 00 00       	call   f0105871 <readline>
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
f0100ae7:	ff 14 85 28 6d 10 f0 	call   *-0xfef92d8(,%eax,4)
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
f0100b08:	e8 11 2d 00 00       	call   f010381e <mc146818_read>
f0100b0d:	89 c6                	mov    %eax,%esi
f0100b0f:	83 c3 01             	add    $0x1,%ebx
f0100b12:	89 1c 24             	mov    %ebx,(%esp)
f0100b15:	e8 04 2d 00 00       	call   f010381e <mc146818_read>
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
f0100b7e:	68 44 6d 10 f0       	push   $0xf0106d44
f0100b83:	6a 7c                	push   $0x7c
f0100b85:	68 01 77 10 f0       	push   $0xf0107701
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
f0100bd8:	68 c4 67 10 f0       	push   $0xf01067c4
f0100bdd:	68 10 04 00 00       	push   $0x410
f0100be2:	68 01 77 10 f0       	push   $0xf0107701
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
f0100c19:	68 6c 6d 10 f0       	push   $0xf0106d6c
f0100c1e:	68 43 03 00 00       	push   $0x343
f0100c23:	68 01 77 10 f0       	push   $0xf0107701
f0100c28:	e8 13 f4 ff ff       	call   f0100040 <_panic>
f0100c2d:	50                   	push   %eax
f0100c2e:	68 c4 67 10 f0       	push   $0xf01067c4
f0100c33:	6a 58                	push   $0x58
f0100c35:	68 0d 77 10 f0       	push   $0xf010770d
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
f0100c7c:	e8 8f 4e 00 00       	call   f0105b10 <memset>
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
f0100cb7:	68 1b 77 10 f0       	push   $0xf010771b
f0100cbc:	68 27 77 10 f0       	push   $0xf0107727
f0100cc1:	68 5d 03 00 00       	push   $0x35d
f0100cc6:	68 01 77 10 f0       	push   $0xf0107701
f0100ccb:	e8 70 f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100cd0:	68 3c 77 10 f0       	push   $0xf010773c
f0100cd5:	68 27 77 10 f0       	push   $0xf0107727
f0100cda:	68 5e 03 00 00       	push   $0x35e
f0100cdf:	68 01 77 10 f0       	push   $0xf0107701
f0100ce4:	e8 57 f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ce9:	68 90 6d 10 f0       	push   $0xf0106d90
f0100cee:	68 27 77 10 f0       	push   $0xf0107727
f0100cf3:	68 5f 03 00 00       	push   $0x35f
f0100cf8:	68 01 77 10 f0       	push   $0xf0107701
f0100cfd:	e8 3e f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != 0);
f0100d02:	68 50 77 10 f0       	push   $0xf0107750
f0100d07:	68 27 77 10 f0       	push   $0xf0107727
f0100d0c:	68 62 03 00 00       	push   $0x362
f0100d11:	68 01 77 10 f0       	push   $0xf0107701
f0100d16:	e8 25 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d1b:	68 61 77 10 f0       	push   $0xf0107761
f0100d20:	68 27 77 10 f0       	push   $0xf0107727
f0100d25:	68 63 03 00 00       	push   $0x363
f0100d2a:	68 01 77 10 f0       	push   $0xf0107701
f0100d2f:	e8 0c f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d34:	68 c4 6d 10 f0       	push   $0xf0106dc4
f0100d39:	68 27 77 10 f0       	push   $0xf0107727
f0100d3e:	68 64 03 00 00       	push   $0x364
f0100d43:	68 01 77 10 f0       	push   $0xf0107701
f0100d48:	e8 f3 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d4d:	68 7a 77 10 f0       	push   $0xf010777a
f0100d52:	68 27 77 10 f0       	push   $0xf0107727
f0100d57:	68 65 03 00 00       	push   $0x365
f0100d5c:	68 01 77 10 f0       	push   $0xf0107701
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
f0100d80:	68 c4 67 10 f0       	push   $0xf01067c4
f0100d85:	6a 58                	push   $0x58
f0100d87:	68 0d 77 10 f0       	push   $0xf010770d
f0100d8c:	e8 af f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d91:	68 e8 6d 10 f0       	push   $0xf0106de8
f0100d96:	68 27 77 10 f0       	push   $0xf0107727
f0100d9b:	68 66 03 00 00       	push   $0x366
f0100da0:	68 01 77 10 f0       	push   $0xf0107701
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
f0100e0f:	68 94 77 10 f0       	push   $0xf0107794
f0100e14:	68 27 77 10 f0       	push   $0xf0107727
f0100e19:	68 68 03 00 00       	push   $0x368
f0100e1e:	68 01 77 10 f0       	push   $0xf0107701
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
f0100e36:	68 30 6e 10 f0       	push   $0xf0106e30
f0100e3b:	e8 81 2b 00 00       	call   f01039c1 <cprintf>
}
f0100e40:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e43:	5b                   	pop    %ebx
f0100e44:	5e                   	pop    %esi
f0100e45:	5f                   	pop    %edi
f0100e46:	5d                   	pop    %ebp
f0100e47:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e48:	68 b1 77 10 f0       	push   $0xf01077b1
f0100e4d:	68 27 77 10 f0       	push   $0xf0107727
f0100e52:	68 70 03 00 00       	push   $0x370
f0100e57:	68 01 77 10 f0       	push   $0xf0107701
f0100e5c:	e8 df f1 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100e61:	68 c3 77 10 f0       	push   $0xf01077c3
f0100e66:	68 27 77 10 f0       	push   $0xf0107727
f0100e6b:	68 71 03 00 00       	push   $0x371
f0100e70:	68 01 77 10 f0       	push   $0xf0107701
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
f0100f23:	68 e8 67 10 f0       	push   $0xf01067e8
f0100f28:	68 4f 01 00 00       	push   $0x14f
f0100f2d:	68 01 77 10 f0       	push   $0xf0107701
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
f0101018:	68 c4 67 10 f0       	push   $0xf01067c4
f010101d:	6a 58                	push   $0x58
f010101f:	68 0d 77 10 f0       	push   $0xf010770d
f0101024:	e8 17 f0 ff ff       	call   f0100040 <_panic>
		memset(head,0,PGSIZE);
f0101029:	83 ec 04             	sub    $0x4,%esp
f010102c:	68 00 10 00 00       	push   $0x1000
f0101031:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0101033:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101039:	52                   	push   %edx
f010103a:	e8 d1 4a 00 00       	call   f0105b10 <memset>
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
f010106f:	68 54 6e 10 f0       	push   $0xf0106e54
f0101074:	68 b0 01 00 00       	push   $0x1b0
f0101079:	68 01 77 10 f0       	push   $0xf0107701
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
f0101126:	68 c4 67 10 f0       	push   $0xf01067c4
f010112b:	68 fd 01 00 00       	push   $0x1fd
f0101130:	68 01 77 10 f0       	push   $0xf0107701
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
f01011da:	68 9c 6e 10 f0       	push   $0xf0106e9c
f01011df:	6a 51                	push   $0x51
f01011e1:	68 0d 77 10 f0       	push   $0xf010770d
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
f0101200:	e8 29 4f 00 00       	call   f010612e <cpunum>
f0101205:	6b c0 74             	imul   $0x74,%eax,%eax
f0101208:	83 b8 28 80 21 f0 00 	cmpl   $0x0,-0xfde7fd8(%eax)
f010120f:	74 16                	je     f0101227 <tlb_invalidate+0x31>
f0101211:	e8 18 4f 00 00       	call   f010612e <cpunum>
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
f0101309:	56                   	push   %esi
f010130a:	53                   	push   %ebx
f010130b:	8b 45 0c             	mov    0xc(%ebp),%eax
	uintptr_t oldbase=base;
f010130e:	8b 35 00 33 12 f0    	mov    0xf0123300,%esi
	if(size % PGSIZE != 0)
f0101314:	89 c3                	mov    %eax,%ebx
f0101316:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
		len = size / PGSIZE +1;
f010131c:	89 c2                	mov    %eax,%edx
f010131e:	c1 ea 0c             	shr    $0xc,%edx
f0101321:	8d 4a 01             	lea    0x1(%edx),%ecx
f0101324:	89 c2                	mov    %eax,%edx
f0101326:	c1 ea 0c             	shr    $0xc,%edx
f0101329:	85 db                	test   %ebx,%ebx
f010132b:	0f 45 d1             	cmovne %ecx,%edx
	if(base + len * PGSIZE > MMIOLIM || base + len * PGSIZE < base)
f010132e:	c1 e2 0c             	shl    $0xc,%edx
f0101331:	01 f2                	add    %esi,%edx
f0101333:	72 39                	jb     f010136e <mmio_map_region+0x6c>
f0101335:	81 fa 00 00 c0 ef    	cmp    $0xefc00000,%edx
f010133b:	77 31                	ja     f010136e <mmio_map_region+0x6c>
	boot_map_region(kern_pgdir,base,ROUNDUP(size, PGSIZE),pa, PTE_PCD|PTE_PWT|PTE_W);
f010133d:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f0101343:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0101349:	83 ec 08             	sub    $0x8,%esp
f010134c:	6a 1a                	push   $0x1a
f010134e:	ff 75 08             	pushl  0x8(%ebp)
f0101351:	89 d9                	mov    %ebx,%ecx
f0101353:	89 f2                	mov    %esi,%edx
f0101355:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f010135a:	e8 e2 fd ff ff       	call   f0101141 <boot_map_region>
	base += ROUNDUP(size, PGSIZE); //just like nextfree in boot_alloc!
f010135f:	01 1d 00 33 12 f0    	add    %ebx,0xf0123300
}
f0101365:	89 f0                	mov    %esi,%eax
f0101367:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010136a:	5b                   	pop    %ebx
f010136b:	5e                   	pop    %esi
f010136c:	5d                   	pop    %ebp
f010136d:	c3                   	ret    
		panic("this reservation have overflowed MMIOLIM!\n");
f010136e:	83 ec 04             	sub    $0x4,%esp
f0101371:	68 bc 6e 10 f0       	push   $0xf0106ebc
f0101376:	68 dd 02 00 00       	push   $0x2dd
f010137b:	68 01 77 10 f0       	push   $0xf0107701
f0101380:	e8 bb ec ff ff       	call   f0100040 <_panic>

f0101385 <mem_init>:
{
f0101385:	f3 0f 1e fb          	endbr32 
f0101389:	55                   	push   %ebp
f010138a:	89 e5                	mov    %esp,%ebp
f010138c:	57                   	push   %edi
f010138d:	56                   	push   %esi
f010138e:	53                   	push   %ebx
f010138f:	83 ec 3c             	sub    $0x3c,%esp
	basemem = nvram_read(NVRAM_BASELO);
f0101392:	b8 15 00 00 00       	mov    $0x15,%eax
f0101397:	e8 61 f7 ff ff       	call   f0100afd <nvram_read>
f010139c:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f010139e:	b8 17 00 00 00       	mov    $0x17,%eax
f01013a3:	e8 55 f7 ff ff       	call   f0100afd <nvram_read>
f01013a8:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01013aa:	b8 34 00 00 00       	mov    $0x34,%eax
f01013af:	e8 49 f7 ff ff       	call   f0100afd <nvram_read>
	if (ext16mem)
f01013b4:	c1 e0 06             	shl    $0x6,%eax
f01013b7:	0f 84 ea 00 00 00    	je     f01014a7 <mem_init+0x122>
		totalmem = 16 * 1024 + ext16mem;
f01013bd:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f01013c2:	89 c2                	mov    %eax,%edx
f01013c4:	c1 ea 02             	shr    $0x2,%edx
f01013c7:	89 15 88 7e 21 f0    	mov    %edx,0xf0217e88
	npages_basemem = basemem / (PGSIZE / 1024);
f01013cd:	89 da                	mov    %ebx,%edx
f01013cf:	c1 ea 02             	shr    $0x2,%edx
f01013d2:	89 15 44 72 21 f0    	mov    %edx,0xf0217244
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013d8:	89 c2                	mov    %eax,%edx
f01013da:	29 da                	sub    %ebx,%edx
f01013dc:	52                   	push   %edx
f01013dd:	53                   	push   %ebx
f01013de:	50                   	push   %eax
f01013df:	68 e8 6e 10 f0       	push   $0xf0106ee8
f01013e4:	e8 d8 25 00 00       	call   f01039c1 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01013e9:	b8 00 10 00 00       	mov    $0x1000,%eax
f01013ee:	e8 33 f7 ff ff       	call   f0100b26 <boot_alloc>
f01013f3:	a3 8c 7e 21 f0       	mov    %eax,0xf0217e8c
	memset(kern_pgdir, 0, PGSIZE);
f01013f8:	83 c4 0c             	add    $0xc,%esp
f01013fb:	68 00 10 00 00       	push   $0x1000
f0101400:	6a 00                	push   $0x0
f0101402:	50                   	push   %eax
f0101403:	e8 08 47 00 00       	call   f0105b10 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101408:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f010140d:	83 c4 10             	add    $0x10,%esp
f0101410:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101415:	0f 86 9c 00 00 00    	jbe    f01014b7 <mem_init+0x132>
	return (physaddr_t)kva - KERNBASE;
f010141b:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101421:	83 ca 05             	or     $0x5,%edx
f0101424:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages*sizeof(struct PageInfo));
f010142a:	a1 88 7e 21 f0       	mov    0xf0217e88,%eax
f010142f:	c1 e0 03             	shl    $0x3,%eax
f0101432:	e8 ef f6 ff ff       	call   f0100b26 <boot_alloc>
f0101437:	a3 90 7e 21 f0       	mov    %eax,0xf0217e90
	memset(pages,0,npages*sizeof(struct PageInfo));
f010143c:	83 ec 04             	sub    $0x4,%esp
f010143f:	8b 0d 88 7e 21 f0    	mov    0xf0217e88,%ecx
f0101445:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f010144c:	52                   	push   %edx
f010144d:	6a 00                	push   $0x0
f010144f:	50                   	push   %eax
f0101450:	e8 bb 46 00 00       	call   f0105b10 <memset>
	envs = (struct Env*)boot_alloc(NENV*sizeof(struct Env));
f0101455:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f010145a:	e8 c7 f6 ff ff       	call   f0100b26 <boot_alloc>
f010145f:	a3 48 72 21 f0       	mov    %eax,0xf0217248
	memset(envs,0,NENV*sizeof(struct Env));
f0101464:	83 c4 0c             	add    $0xc,%esp
f0101467:	68 00 f0 01 00       	push   $0x1f000
f010146c:	6a 00                	push   $0x0
f010146e:	50                   	push   %eax
f010146f:	e8 9c 46 00 00       	call   f0105b10 <memset>
	page_init();
f0101474:	e8 67 fa ff ff       	call   f0100ee0 <page_init>
	check_page_free_list(1);
f0101479:	b8 01 00 00 00       	mov    $0x1,%eax
f010147e:	e8 6f f7 ff ff       	call   f0100bf2 <check_page_free_list>
	if (!pages)
f0101483:	83 c4 10             	add    $0x10,%esp
f0101486:	83 3d 90 7e 21 f0 00 	cmpl   $0x0,0xf0217e90
f010148d:	74 3d                	je     f01014cc <mem_init+0x147>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010148f:	a1 40 72 21 f0       	mov    0xf0217240,%eax
f0101494:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f010149b:	85 c0                	test   %eax,%eax
f010149d:	74 44                	je     f01014e3 <mem_init+0x15e>
		++nfree;
f010149f:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014a3:	8b 00                	mov    (%eax),%eax
f01014a5:	eb f4                	jmp    f010149b <mem_init+0x116>
		totalmem = 1 * 1024 + extmem;
f01014a7:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01014ad:	85 f6                	test   %esi,%esi
f01014af:	0f 44 c3             	cmove  %ebx,%eax
f01014b2:	e9 0b ff ff ff       	jmp    f01013c2 <mem_init+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01014b7:	50                   	push   %eax
f01014b8:	68 e8 67 10 f0       	push   $0xf01067e8
f01014bd:	68 a6 00 00 00       	push   $0xa6
f01014c2:	68 01 77 10 f0       	push   $0xf0107701
f01014c7:	e8 74 eb ff ff       	call   f0100040 <_panic>
		panic("'pages' is a null pointer!");
f01014cc:	83 ec 04             	sub    $0x4,%esp
f01014cf:	68 d4 77 10 f0       	push   $0xf01077d4
f01014d4:	68 84 03 00 00       	push   $0x384
f01014d9:	68 01 77 10 f0       	push   $0xf0107701
f01014de:	e8 5d eb ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f01014e3:	83 ec 0c             	sub    $0xc,%esp
f01014e6:	6a 00                	push   $0x0
f01014e8:	e8 de fa ff ff       	call   f0100fcb <page_alloc>
f01014ed:	89 c3                	mov    %eax,%ebx
f01014ef:	83 c4 10             	add    $0x10,%esp
f01014f2:	85 c0                	test   %eax,%eax
f01014f4:	0f 84 11 02 00 00    	je     f010170b <mem_init+0x386>
	assert((pp1 = page_alloc(0)));
f01014fa:	83 ec 0c             	sub    $0xc,%esp
f01014fd:	6a 00                	push   $0x0
f01014ff:	e8 c7 fa ff ff       	call   f0100fcb <page_alloc>
f0101504:	89 c6                	mov    %eax,%esi
f0101506:	83 c4 10             	add    $0x10,%esp
f0101509:	85 c0                	test   %eax,%eax
f010150b:	0f 84 13 02 00 00    	je     f0101724 <mem_init+0x39f>
	assert((pp2 = page_alloc(0)));
f0101511:	83 ec 0c             	sub    $0xc,%esp
f0101514:	6a 00                	push   $0x0
f0101516:	e8 b0 fa ff ff       	call   f0100fcb <page_alloc>
f010151b:	89 c7                	mov    %eax,%edi
f010151d:	83 c4 10             	add    $0x10,%esp
f0101520:	85 c0                	test   %eax,%eax
f0101522:	0f 84 15 02 00 00    	je     f010173d <mem_init+0x3b8>
	assert(pp1 && pp1 != pp0);
f0101528:	39 f3                	cmp    %esi,%ebx
f010152a:	0f 84 26 02 00 00    	je     f0101756 <mem_init+0x3d1>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101530:	39 c6                	cmp    %eax,%esi
f0101532:	0f 84 37 02 00 00    	je     f010176f <mem_init+0x3ea>
f0101538:	39 c3                	cmp    %eax,%ebx
f010153a:	0f 84 2f 02 00 00    	je     f010176f <mem_init+0x3ea>
	return (pp - pages) << PGSHIFT;
f0101540:	8b 0d 90 7e 21 f0    	mov    0xf0217e90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101546:	8b 15 88 7e 21 f0    	mov    0xf0217e88,%edx
f010154c:	c1 e2 0c             	shl    $0xc,%edx
f010154f:	89 d8                	mov    %ebx,%eax
f0101551:	29 c8                	sub    %ecx,%eax
f0101553:	c1 f8 03             	sar    $0x3,%eax
f0101556:	c1 e0 0c             	shl    $0xc,%eax
f0101559:	39 d0                	cmp    %edx,%eax
f010155b:	0f 83 27 02 00 00    	jae    f0101788 <mem_init+0x403>
f0101561:	89 f0                	mov    %esi,%eax
f0101563:	29 c8                	sub    %ecx,%eax
f0101565:	c1 f8 03             	sar    $0x3,%eax
f0101568:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f010156b:	39 c2                	cmp    %eax,%edx
f010156d:	0f 86 2e 02 00 00    	jbe    f01017a1 <mem_init+0x41c>
f0101573:	89 f8                	mov    %edi,%eax
f0101575:	29 c8                	sub    %ecx,%eax
f0101577:	c1 f8 03             	sar    $0x3,%eax
f010157a:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010157d:	39 c2                	cmp    %eax,%edx
f010157f:	0f 86 35 02 00 00    	jbe    f01017ba <mem_init+0x435>
	fl = page_free_list;
f0101585:	a1 40 72 21 f0       	mov    0xf0217240,%eax
f010158a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010158d:	c7 05 40 72 21 f0 00 	movl   $0x0,0xf0217240
f0101594:	00 00 00 
	assert(!page_alloc(0));
f0101597:	83 ec 0c             	sub    $0xc,%esp
f010159a:	6a 00                	push   $0x0
f010159c:	e8 2a fa ff ff       	call   f0100fcb <page_alloc>
f01015a1:	83 c4 10             	add    $0x10,%esp
f01015a4:	85 c0                	test   %eax,%eax
f01015a6:	0f 85 27 02 00 00    	jne    f01017d3 <mem_init+0x44e>
	page_free(pp0);
f01015ac:	83 ec 0c             	sub    $0xc,%esp
f01015af:	53                   	push   %ebx
f01015b0:	e8 8f fa ff ff       	call   f0101044 <page_free>
	page_free(pp1);
f01015b5:	89 34 24             	mov    %esi,(%esp)
f01015b8:	e8 87 fa ff ff       	call   f0101044 <page_free>
	page_free(pp2);
f01015bd:	89 3c 24             	mov    %edi,(%esp)
f01015c0:	e8 7f fa ff ff       	call   f0101044 <page_free>
	assert((pp0 = page_alloc(0)));
f01015c5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015cc:	e8 fa f9 ff ff       	call   f0100fcb <page_alloc>
f01015d1:	89 c3                	mov    %eax,%ebx
f01015d3:	83 c4 10             	add    $0x10,%esp
f01015d6:	85 c0                	test   %eax,%eax
f01015d8:	0f 84 0e 02 00 00    	je     f01017ec <mem_init+0x467>
	assert((pp1 = page_alloc(0)));
f01015de:	83 ec 0c             	sub    $0xc,%esp
f01015e1:	6a 00                	push   $0x0
f01015e3:	e8 e3 f9 ff ff       	call   f0100fcb <page_alloc>
f01015e8:	89 c6                	mov    %eax,%esi
f01015ea:	83 c4 10             	add    $0x10,%esp
f01015ed:	85 c0                	test   %eax,%eax
f01015ef:	0f 84 10 02 00 00    	je     f0101805 <mem_init+0x480>
	assert((pp2 = page_alloc(0)));
f01015f5:	83 ec 0c             	sub    $0xc,%esp
f01015f8:	6a 00                	push   $0x0
f01015fa:	e8 cc f9 ff ff       	call   f0100fcb <page_alloc>
f01015ff:	89 c7                	mov    %eax,%edi
f0101601:	83 c4 10             	add    $0x10,%esp
f0101604:	85 c0                	test   %eax,%eax
f0101606:	0f 84 12 02 00 00    	je     f010181e <mem_init+0x499>
	assert(pp1 && pp1 != pp0);
f010160c:	39 f3                	cmp    %esi,%ebx
f010160e:	0f 84 23 02 00 00    	je     f0101837 <mem_init+0x4b2>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101614:	39 c3                	cmp    %eax,%ebx
f0101616:	0f 84 34 02 00 00    	je     f0101850 <mem_init+0x4cb>
f010161c:	39 c6                	cmp    %eax,%esi
f010161e:	0f 84 2c 02 00 00    	je     f0101850 <mem_init+0x4cb>
	assert(!page_alloc(0));
f0101624:	83 ec 0c             	sub    $0xc,%esp
f0101627:	6a 00                	push   $0x0
f0101629:	e8 9d f9 ff ff       	call   f0100fcb <page_alloc>
f010162e:	83 c4 10             	add    $0x10,%esp
f0101631:	85 c0                	test   %eax,%eax
f0101633:	0f 85 30 02 00 00    	jne    f0101869 <mem_init+0x4e4>
f0101639:	89 d8                	mov    %ebx,%eax
f010163b:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101641:	c1 f8 03             	sar    $0x3,%eax
f0101644:	89 c2                	mov    %eax,%edx
f0101646:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101649:	25 ff ff 0f 00       	and    $0xfffff,%eax
f010164e:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0101654:	0f 83 28 02 00 00    	jae    f0101882 <mem_init+0x4fd>
	memset(page2kva(pp0), 1, PGSIZE);
f010165a:	83 ec 04             	sub    $0x4,%esp
f010165d:	68 00 10 00 00       	push   $0x1000
f0101662:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101664:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f010166a:	52                   	push   %edx
f010166b:	e8 a0 44 00 00       	call   f0105b10 <memset>
	page_free(pp0);
f0101670:	89 1c 24             	mov    %ebx,(%esp)
f0101673:	e8 cc f9 ff ff       	call   f0101044 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101678:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010167f:	e8 47 f9 ff ff       	call   f0100fcb <page_alloc>
f0101684:	83 c4 10             	add    $0x10,%esp
f0101687:	85 c0                	test   %eax,%eax
f0101689:	0f 84 05 02 00 00    	je     f0101894 <mem_init+0x50f>
	assert(pp && pp0 == pp);
f010168f:	39 c3                	cmp    %eax,%ebx
f0101691:	0f 85 16 02 00 00    	jne    f01018ad <mem_init+0x528>
	return (pp - pages) << PGSHIFT;
f0101697:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f010169d:	c1 f8 03             	sar    $0x3,%eax
f01016a0:	89 c2                	mov    %eax,%edx
f01016a2:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01016a5:	25 ff ff 0f 00       	and    $0xfffff,%eax
f01016aa:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f01016b0:	0f 83 10 02 00 00    	jae    f01018c6 <mem_init+0x541>
	return (void *)(pa + KERNBASE);
f01016b6:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f01016bc:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f01016c2:	80 38 00             	cmpb   $0x0,(%eax)
f01016c5:	0f 85 0d 02 00 00    	jne    f01018d8 <mem_init+0x553>
f01016cb:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01016ce:	39 d0                	cmp    %edx,%eax
f01016d0:	75 f0                	jne    f01016c2 <mem_init+0x33d>
	page_free_list = fl;
f01016d2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01016d5:	a3 40 72 21 f0       	mov    %eax,0xf0217240
	page_free(pp0);
f01016da:	83 ec 0c             	sub    $0xc,%esp
f01016dd:	53                   	push   %ebx
f01016de:	e8 61 f9 ff ff       	call   f0101044 <page_free>
	page_free(pp1);
f01016e3:	89 34 24             	mov    %esi,(%esp)
f01016e6:	e8 59 f9 ff ff       	call   f0101044 <page_free>
	page_free(pp2);
f01016eb:	89 3c 24             	mov    %edi,(%esp)
f01016ee:	e8 51 f9 ff ff       	call   f0101044 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016f3:	a1 40 72 21 f0       	mov    0xf0217240,%eax
f01016f8:	83 c4 10             	add    $0x10,%esp
f01016fb:	85 c0                	test   %eax,%eax
f01016fd:	0f 84 ee 01 00 00    	je     f01018f1 <mem_init+0x56c>
		--nfree;
f0101703:	83 6d d4 01          	subl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101707:	8b 00                	mov    (%eax),%eax
f0101709:	eb f0                	jmp    f01016fb <mem_init+0x376>
	assert((pp0 = page_alloc(0)));
f010170b:	68 ef 77 10 f0       	push   $0xf01077ef
f0101710:	68 27 77 10 f0       	push   $0xf0107727
f0101715:	68 8c 03 00 00       	push   $0x38c
f010171a:	68 01 77 10 f0       	push   $0xf0107701
f010171f:	e8 1c e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101724:	68 05 78 10 f0       	push   $0xf0107805
f0101729:	68 27 77 10 f0       	push   $0xf0107727
f010172e:	68 8d 03 00 00       	push   $0x38d
f0101733:	68 01 77 10 f0       	push   $0xf0107701
f0101738:	e8 03 e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010173d:	68 1b 78 10 f0       	push   $0xf010781b
f0101742:	68 27 77 10 f0       	push   $0xf0107727
f0101747:	68 8e 03 00 00       	push   $0x38e
f010174c:	68 01 77 10 f0       	push   $0xf0107701
f0101751:	e8 ea e8 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f0101756:	68 31 78 10 f0       	push   $0xf0107831
f010175b:	68 27 77 10 f0       	push   $0xf0107727
f0101760:	68 91 03 00 00       	push   $0x391
f0101765:	68 01 77 10 f0       	push   $0xf0107701
f010176a:	e8 d1 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010176f:	68 24 6f 10 f0       	push   $0xf0106f24
f0101774:	68 27 77 10 f0       	push   $0xf0107727
f0101779:	68 92 03 00 00       	push   $0x392
f010177e:	68 01 77 10 f0       	push   $0xf0107701
f0101783:	e8 b8 e8 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101788:	68 43 78 10 f0       	push   $0xf0107843
f010178d:	68 27 77 10 f0       	push   $0xf0107727
f0101792:	68 93 03 00 00       	push   $0x393
f0101797:	68 01 77 10 f0       	push   $0xf0107701
f010179c:	e8 9f e8 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01017a1:	68 60 78 10 f0       	push   $0xf0107860
f01017a6:	68 27 77 10 f0       	push   $0xf0107727
f01017ab:	68 94 03 00 00       	push   $0x394
f01017b0:	68 01 77 10 f0       	push   $0xf0107701
f01017b5:	e8 86 e8 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01017ba:	68 7d 78 10 f0       	push   $0xf010787d
f01017bf:	68 27 77 10 f0       	push   $0xf0107727
f01017c4:	68 95 03 00 00       	push   $0x395
f01017c9:	68 01 77 10 f0       	push   $0xf0107701
f01017ce:	e8 6d e8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01017d3:	68 9a 78 10 f0       	push   $0xf010789a
f01017d8:	68 27 77 10 f0       	push   $0xf0107727
f01017dd:	68 9c 03 00 00       	push   $0x39c
f01017e2:	68 01 77 10 f0       	push   $0xf0107701
f01017e7:	e8 54 e8 ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f01017ec:	68 ef 77 10 f0       	push   $0xf01077ef
f01017f1:	68 27 77 10 f0       	push   $0xf0107727
f01017f6:	68 a3 03 00 00       	push   $0x3a3
f01017fb:	68 01 77 10 f0       	push   $0xf0107701
f0101800:	e8 3b e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101805:	68 05 78 10 f0       	push   $0xf0107805
f010180a:	68 27 77 10 f0       	push   $0xf0107727
f010180f:	68 a4 03 00 00       	push   $0x3a4
f0101814:	68 01 77 10 f0       	push   $0xf0107701
f0101819:	e8 22 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010181e:	68 1b 78 10 f0       	push   $0xf010781b
f0101823:	68 27 77 10 f0       	push   $0xf0107727
f0101828:	68 a5 03 00 00       	push   $0x3a5
f010182d:	68 01 77 10 f0       	push   $0xf0107701
f0101832:	e8 09 e8 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f0101837:	68 31 78 10 f0       	push   $0xf0107831
f010183c:	68 27 77 10 f0       	push   $0xf0107727
f0101841:	68 a7 03 00 00       	push   $0x3a7
f0101846:	68 01 77 10 f0       	push   $0xf0107701
f010184b:	e8 f0 e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101850:	68 24 6f 10 f0       	push   $0xf0106f24
f0101855:	68 27 77 10 f0       	push   $0xf0107727
f010185a:	68 a8 03 00 00       	push   $0x3a8
f010185f:	68 01 77 10 f0       	push   $0xf0107701
f0101864:	e8 d7 e7 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101869:	68 9a 78 10 f0       	push   $0xf010789a
f010186e:	68 27 77 10 f0       	push   $0xf0107727
f0101873:	68 a9 03 00 00       	push   $0x3a9
f0101878:	68 01 77 10 f0       	push   $0xf0107701
f010187d:	e8 be e7 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101882:	52                   	push   %edx
f0101883:	68 c4 67 10 f0       	push   $0xf01067c4
f0101888:	6a 58                	push   $0x58
f010188a:	68 0d 77 10 f0       	push   $0xf010770d
f010188f:	e8 ac e7 ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101894:	68 a9 78 10 f0       	push   $0xf01078a9
f0101899:	68 27 77 10 f0       	push   $0xf0107727
f010189e:	68 ae 03 00 00       	push   $0x3ae
f01018a3:	68 01 77 10 f0       	push   $0xf0107701
f01018a8:	e8 93 e7 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f01018ad:	68 c7 78 10 f0       	push   $0xf01078c7
f01018b2:	68 27 77 10 f0       	push   $0xf0107727
f01018b7:	68 af 03 00 00       	push   $0x3af
f01018bc:	68 01 77 10 f0       	push   $0xf0107701
f01018c1:	e8 7a e7 ff ff       	call   f0100040 <_panic>
f01018c6:	52                   	push   %edx
f01018c7:	68 c4 67 10 f0       	push   $0xf01067c4
f01018cc:	6a 58                	push   $0x58
f01018ce:	68 0d 77 10 f0       	push   $0xf010770d
f01018d3:	e8 68 e7 ff ff       	call   f0100040 <_panic>
		assert(c[i] == 0);
f01018d8:	68 d7 78 10 f0       	push   $0xf01078d7
f01018dd:	68 27 77 10 f0       	push   $0xf0107727
f01018e2:	68 b2 03 00 00       	push   $0x3b2
f01018e7:	68 01 77 10 f0       	push   $0xf0107701
f01018ec:	e8 4f e7 ff ff       	call   f0100040 <_panic>
	assert(nfree == 0);
f01018f1:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01018f5:	0f 85 46 09 00 00    	jne    f0102241 <mem_init+0xebc>
	cprintf("check_page_alloc() succeeded!\n");
f01018fb:	83 ec 0c             	sub    $0xc,%esp
f01018fe:	68 44 6f 10 f0       	push   $0xf0106f44
f0101903:	e8 b9 20 00 00       	call   f01039c1 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101908:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010190f:	e8 b7 f6 ff ff       	call   f0100fcb <page_alloc>
f0101914:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101917:	83 c4 10             	add    $0x10,%esp
f010191a:	85 c0                	test   %eax,%eax
f010191c:	0f 84 38 09 00 00    	je     f010225a <mem_init+0xed5>
	assert((pp1 = page_alloc(0)));
f0101922:	83 ec 0c             	sub    $0xc,%esp
f0101925:	6a 00                	push   $0x0
f0101927:	e8 9f f6 ff ff       	call   f0100fcb <page_alloc>
f010192c:	89 c7                	mov    %eax,%edi
f010192e:	83 c4 10             	add    $0x10,%esp
f0101931:	85 c0                	test   %eax,%eax
f0101933:	0f 84 3a 09 00 00    	je     f0102273 <mem_init+0xeee>
	assert((pp2 = page_alloc(0)));
f0101939:	83 ec 0c             	sub    $0xc,%esp
f010193c:	6a 00                	push   $0x0
f010193e:	e8 88 f6 ff ff       	call   f0100fcb <page_alloc>
f0101943:	89 c3                	mov    %eax,%ebx
f0101945:	83 c4 10             	add    $0x10,%esp
f0101948:	85 c0                	test   %eax,%eax
f010194a:	0f 84 3c 09 00 00    	je     f010228c <mem_init+0xf07>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101950:	39 7d d4             	cmp    %edi,-0x2c(%ebp)
f0101953:	0f 84 4c 09 00 00    	je     f01022a5 <mem_init+0xf20>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101959:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010195c:	0f 84 5c 09 00 00    	je     f01022be <mem_init+0xf39>
f0101962:	39 c7                	cmp    %eax,%edi
f0101964:	0f 84 54 09 00 00    	je     f01022be <mem_init+0xf39>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010196a:	a1 40 72 21 f0       	mov    0xf0217240,%eax
f010196f:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f0101972:	c7 05 40 72 21 f0 00 	movl   $0x0,0xf0217240
f0101979:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010197c:	83 ec 0c             	sub    $0xc,%esp
f010197f:	6a 00                	push   $0x0
f0101981:	e8 45 f6 ff ff       	call   f0100fcb <page_alloc>
f0101986:	83 c4 10             	add    $0x10,%esp
f0101989:	85 c0                	test   %eax,%eax
f010198b:	0f 85 46 09 00 00    	jne    f01022d7 <mem_init+0xf52>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101991:	83 ec 04             	sub    $0x4,%esp
f0101994:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101997:	50                   	push   %eax
f0101998:	6a 00                	push   $0x0
f010199a:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f01019a0:	e8 e8 f7 ff ff       	call   f010118d <page_lookup>
f01019a5:	83 c4 10             	add    $0x10,%esp
f01019a8:	85 c0                	test   %eax,%eax
f01019aa:	0f 85 40 09 00 00    	jne    f01022f0 <mem_init+0xf6b>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019b0:	6a 02                	push   $0x2
f01019b2:	6a 00                	push   $0x0
f01019b4:	57                   	push   %edi
f01019b5:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f01019bb:	e8 c0 f8 ff ff       	call   f0101280 <page_insert>
f01019c0:	83 c4 10             	add    $0x10,%esp
f01019c3:	85 c0                	test   %eax,%eax
f01019c5:	0f 89 3e 09 00 00    	jns    f0102309 <mem_init+0xf84>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019cb:	83 ec 0c             	sub    $0xc,%esp
f01019ce:	ff 75 d4             	pushl  -0x2c(%ebp)
f01019d1:	e8 6e f6 ff ff       	call   f0101044 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019d6:	6a 02                	push   $0x2
f01019d8:	6a 00                	push   $0x0
f01019da:	57                   	push   %edi
f01019db:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f01019e1:	e8 9a f8 ff ff       	call   f0101280 <page_insert>
f01019e6:	83 c4 20             	add    $0x20,%esp
f01019e9:	85 c0                	test   %eax,%eax
f01019eb:	0f 85 31 09 00 00    	jne    f0102322 <mem_init+0xf9d>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01019f1:	8b 35 8c 7e 21 f0    	mov    0xf0217e8c,%esi
	return (pp - pages) << PGSHIFT;
f01019f7:	8b 0d 90 7e 21 f0    	mov    0xf0217e90,%ecx
f01019fd:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0101a00:	8b 16                	mov    (%esi),%edx
f0101a02:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a08:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a0b:	29 c8                	sub    %ecx,%eax
f0101a0d:	c1 f8 03             	sar    $0x3,%eax
f0101a10:	c1 e0 0c             	shl    $0xc,%eax
f0101a13:	39 c2                	cmp    %eax,%edx
f0101a15:	0f 85 20 09 00 00    	jne    f010233b <mem_init+0xfb6>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a1b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a20:	89 f0                	mov    %esi,%eax
f0101a22:	e8 68 f1 ff ff       	call   f0100b8f <check_va2pa>
f0101a27:	89 c2                	mov    %eax,%edx
f0101a29:	89 f8                	mov    %edi,%eax
f0101a2b:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101a2e:	c1 f8 03             	sar    $0x3,%eax
f0101a31:	c1 e0 0c             	shl    $0xc,%eax
f0101a34:	39 c2                	cmp    %eax,%edx
f0101a36:	0f 85 18 09 00 00    	jne    f0102354 <mem_init+0xfcf>
	assert(pp1->pp_ref == 1);
f0101a3c:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101a41:	0f 85 26 09 00 00    	jne    f010236d <mem_init+0xfe8>
	assert(pp0->pp_ref == 1);
f0101a47:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a4a:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a4f:	0f 85 31 09 00 00    	jne    f0102386 <mem_init+0x1001>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a55:	6a 02                	push   $0x2
f0101a57:	68 00 10 00 00       	push   $0x1000
f0101a5c:	53                   	push   %ebx
f0101a5d:	56                   	push   %esi
f0101a5e:	e8 1d f8 ff ff       	call   f0101280 <page_insert>
f0101a63:	83 c4 10             	add    $0x10,%esp
f0101a66:	85 c0                	test   %eax,%eax
f0101a68:	0f 85 31 09 00 00    	jne    f010239f <mem_init+0x101a>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a6e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a73:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0101a78:	e8 12 f1 ff ff       	call   f0100b8f <check_va2pa>
f0101a7d:	89 c2                	mov    %eax,%edx
f0101a7f:	89 d8                	mov    %ebx,%eax
f0101a81:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101a87:	c1 f8 03             	sar    $0x3,%eax
f0101a8a:	c1 e0 0c             	shl    $0xc,%eax
f0101a8d:	39 c2                	cmp    %eax,%edx
f0101a8f:	0f 85 23 09 00 00    	jne    f01023b8 <mem_init+0x1033>
	assert(pp2->pp_ref == 1);
f0101a95:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a9a:	0f 85 31 09 00 00    	jne    f01023d1 <mem_init+0x104c>

	// should be no free memory
	assert(!page_alloc(0));
f0101aa0:	83 ec 0c             	sub    $0xc,%esp
f0101aa3:	6a 00                	push   $0x0
f0101aa5:	e8 21 f5 ff ff       	call   f0100fcb <page_alloc>
f0101aaa:	83 c4 10             	add    $0x10,%esp
f0101aad:	85 c0                	test   %eax,%eax
f0101aaf:	0f 85 35 09 00 00    	jne    f01023ea <mem_init+0x1065>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ab5:	6a 02                	push   $0x2
f0101ab7:	68 00 10 00 00       	push   $0x1000
f0101abc:	53                   	push   %ebx
f0101abd:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101ac3:	e8 b8 f7 ff ff       	call   f0101280 <page_insert>
f0101ac8:	83 c4 10             	add    $0x10,%esp
f0101acb:	85 c0                	test   %eax,%eax
f0101acd:	0f 85 30 09 00 00    	jne    f0102403 <mem_init+0x107e>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ad3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ad8:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0101add:	e8 ad f0 ff ff       	call   f0100b8f <check_va2pa>
f0101ae2:	89 c2                	mov    %eax,%edx
f0101ae4:	89 d8                	mov    %ebx,%eax
f0101ae6:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101aec:	c1 f8 03             	sar    $0x3,%eax
f0101aef:	c1 e0 0c             	shl    $0xc,%eax
f0101af2:	39 c2                	cmp    %eax,%edx
f0101af4:	0f 85 22 09 00 00    	jne    f010241c <mem_init+0x1097>
	assert(pp2->pp_ref == 1);
f0101afa:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101aff:	0f 85 30 09 00 00    	jne    f0102435 <mem_init+0x10b0>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b05:	83 ec 0c             	sub    $0xc,%esp
f0101b08:	6a 00                	push   $0x0
f0101b0a:	e8 bc f4 ff ff       	call   f0100fcb <page_alloc>
f0101b0f:	83 c4 10             	add    $0x10,%esp
f0101b12:	85 c0                	test   %eax,%eax
f0101b14:	0f 85 34 09 00 00    	jne    f010244e <mem_init+0x10c9>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101b1a:	8b 0d 8c 7e 21 f0    	mov    0xf0217e8c,%ecx
f0101b20:	8b 01                	mov    (%ecx),%eax
f0101b22:	89 c2                	mov    %eax,%edx
f0101b24:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101b2a:	c1 e8 0c             	shr    $0xc,%eax
f0101b2d:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0101b33:	0f 83 2e 09 00 00    	jae    f0102467 <mem_init+0x10e2>
	return (void *)(pa + KERNBASE);
f0101b39:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101b3f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101b42:	83 ec 04             	sub    $0x4,%esp
f0101b45:	6a 00                	push   $0x0
f0101b47:	68 00 10 00 00       	push   $0x1000
f0101b4c:	51                   	push   %ecx
f0101b4d:	e8 5e f5 ff ff       	call   f01010b0 <pgdir_walk>
f0101b52:	89 c2                	mov    %eax,%edx
f0101b54:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101b57:	83 c0 04             	add    $0x4,%eax
f0101b5a:	83 c4 10             	add    $0x10,%esp
f0101b5d:	39 d0                	cmp    %edx,%eax
f0101b5f:	0f 85 17 09 00 00    	jne    f010247c <mem_init+0x10f7>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101b65:	6a 06                	push   $0x6
f0101b67:	68 00 10 00 00       	push   $0x1000
f0101b6c:	53                   	push   %ebx
f0101b6d:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101b73:	e8 08 f7 ff ff       	call   f0101280 <page_insert>
f0101b78:	83 c4 10             	add    $0x10,%esp
f0101b7b:	85 c0                	test   %eax,%eax
f0101b7d:	0f 85 12 09 00 00    	jne    f0102495 <mem_init+0x1110>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b83:	8b 35 8c 7e 21 f0    	mov    0xf0217e8c,%esi
f0101b89:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b8e:	89 f0                	mov    %esi,%eax
f0101b90:	e8 fa ef ff ff       	call   f0100b8f <check_va2pa>
f0101b95:	89 c2                	mov    %eax,%edx
	return (pp - pages) << PGSHIFT;
f0101b97:	89 d8                	mov    %ebx,%eax
f0101b99:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101b9f:	c1 f8 03             	sar    $0x3,%eax
f0101ba2:	c1 e0 0c             	shl    $0xc,%eax
f0101ba5:	39 c2                	cmp    %eax,%edx
f0101ba7:	0f 85 01 09 00 00    	jne    f01024ae <mem_init+0x1129>
	assert(pp2->pp_ref == 1);
f0101bad:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101bb2:	0f 85 0f 09 00 00    	jne    f01024c7 <mem_init+0x1142>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101bb8:	83 ec 04             	sub    $0x4,%esp
f0101bbb:	6a 00                	push   $0x0
f0101bbd:	68 00 10 00 00       	push   $0x1000
f0101bc2:	56                   	push   %esi
f0101bc3:	e8 e8 f4 ff ff       	call   f01010b0 <pgdir_walk>
f0101bc8:	83 c4 10             	add    $0x10,%esp
f0101bcb:	f6 00 04             	testb  $0x4,(%eax)
f0101bce:	0f 84 0c 09 00 00    	je     f01024e0 <mem_init+0x115b>
	assert(kern_pgdir[0] & PTE_U);
f0101bd4:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0101bd9:	f6 00 04             	testb  $0x4,(%eax)
f0101bdc:	0f 84 17 09 00 00    	je     f01024f9 <mem_init+0x1174>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101be2:	6a 02                	push   $0x2
f0101be4:	68 00 10 00 00       	push   $0x1000
f0101be9:	53                   	push   %ebx
f0101bea:	50                   	push   %eax
f0101beb:	e8 90 f6 ff ff       	call   f0101280 <page_insert>
f0101bf0:	83 c4 10             	add    $0x10,%esp
f0101bf3:	85 c0                	test   %eax,%eax
f0101bf5:	0f 85 17 09 00 00    	jne    f0102512 <mem_init+0x118d>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101bfb:	83 ec 04             	sub    $0x4,%esp
f0101bfe:	6a 00                	push   $0x0
f0101c00:	68 00 10 00 00       	push   $0x1000
f0101c05:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101c0b:	e8 a0 f4 ff ff       	call   f01010b0 <pgdir_walk>
f0101c10:	83 c4 10             	add    $0x10,%esp
f0101c13:	f6 00 02             	testb  $0x2,(%eax)
f0101c16:	0f 84 0f 09 00 00    	je     f010252b <mem_init+0x11a6>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c1c:	83 ec 04             	sub    $0x4,%esp
f0101c1f:	6a 00                	push   $0x0
f0101c21:	68 00 10 00 00       	push   $0x1000
f0101c26:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101c2c:	e8 7f f4 ff ff       	call   f01010b0 <pgdir_walk>
f0101c31:	83 c4 10             	add    $0x10,%esp
f0101c34:	f6 00 04             	testb  $0x4,(%eax)
f0101c37:	0f 85 07 09 00 00    	jne    f0102544 <mem_init+0x11bf>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101c3d:	6a 02                	push   $0x2
f0101c3f:	68 00 00 40 00       	push   $0x400000
f0101c44:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c47:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101c4d:	e8 2e f6 ff ff       	call   f0101280 <page_insert>
f0101c52:	83 c4 10             	add    $0x10,%esp
f0101c55:	85 c0                	test   %eax,%eax
f0101c57:	0f 89 00 09 00 00    	jns    f010255d <mem_init+0x11d8>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c5d:	6a 02                	push   $0x2
f0101c5f:	68 00 10 00 00       	push   $0x1000
f0101c64:	57                   	push   %edi
f0101c65:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101c6b:	e8 10 f6 ff ff       	call   f0101280 <page_insert>
f0101c70:	83 c4 10             	add    $0x10,%esp
f0101c73:	85 c0                	test   %eax,%eax
f0101c75:	0f 85 fb 08 00 00    	jne    f0102576 <mem_init+0x11f1>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c7b:	83 ec 04             	sub    $0x4,%esp
f0101c7e:	6a 00                	push   $0x0
f0101c80:	68 00 10 00 00       	push   $0x1000
f0101c85:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101c8b:	e8 20 f4 ff ff       	call   f01010b0 <pgdir_walk>
f0101c90:	83 c4 10             	add    $0x10,%esp
f0101c93:	f6 00 04             	testb  $0x4,(%eax)
f0101c96:	0f 85 f3 08 00 00    	jne    f010258f <mem_init+0x120a>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c9c:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0101ca1:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ca4:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ca9:	e8 e1 ee ff ff       	call   f0100b8f <check_va2pa>
f0101cae:	89 fe                	mov    %edi,%esi
f0101cb0:	2b 35 90 7e 21 f0    	sub    0xf0217e90,%esi
f0101cb6:	c1 fe 03             	sar    $0x3,%esi
f0101cb9:	c1 e6 0c             	shl    $0xc,%esi
f0101cbc:	39 f0                	cmp    %esi,%eax
f0101cbe:	0f 85 e4 08 00 00    	jne    f01025a8 <mem_init+0x1223>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cc4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cc9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101ccc:	e8 be ee ff ff       	call   f0100b8f <check_va2pa>
f0101cd1:	39 c6                	cmp    %eax,%esi
f0101cd3:	0f 85 e8 08 00 00    	jne    f01025c1 <mem_init+0x123c>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101cd9:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101cde:	0f 85 f6 08 00 00    	jne    f01025da <mem_init+0x1255>
	assert(pp2->pp_ref == 0);
f0101ce4:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ce9:	0f 85 04 09 00 00    	jne    f01025f3 <mem_init+0x126e>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101cef:	83 ec 0c             	sub    $0xc,%esp
f0101cf2:	6a 00                	push   $0x0
f0101cf4:	e8 d2 f2 ff ff       	call   f0100fcb <page_alloc>
f0101cf9:	83 c4 10             	add    $0x10,%esp
f0101cfc:	85 c0                	test   %eax,%eax
f0101cfe:	0f 84 08 09 00 00    	je     f010260c <mem_init+0x1287>
f0101d04:	39 c3                	cmp    %eax,%ebx
f0101d06:	0f 85 00 09 00 00    	jne    f010260c <mem_init+0x1287>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d0c:	83 ec 08             	sub    $0x8,%esp
f0101d0f:	6a 00                	push   $0x0
f0101d11:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101d17:	e8 13 f5 ff ff       	call   f010122f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d1c:	8b 35 8c 7e 21 f0    	mov    0xf0217e8c,%esi
f0101d22:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d27:	89 f0                	mov    %esi,%eax
f0101d29:	e8 61 ee ff ff       	call   f0100b8f <check_va2pa>
f0101d2e:	83 c4 10             	add    $0x10,%esp
f0101d31:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d34:	0f 85 eb 08 00 00    	jne    f0102625 <mem_init+0x12a0>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d3a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d3f:	89 f0                	mov    %esi,%eax
f0101d41:	e8 49 ee ff ff       	call   f0100b8f <check_va2pa>
f0101d46:	89 c2                	mov    %eax,%edx
f0101d48:	89 f8                	mov    %edi,%eax
f0101d4a:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101d50:	c1 f8 03             	sar    $0x3,%eax
f0101d53:	c1 e0 0c             	shl    $0xc,%eax
f0101d56:	39 c2                	cmp    %eax,%edx
f0101d58:	0f 85 e0 08 00 00    	jne    f010263e <mem_init+0x12b9>
	assert(pp1->pp_ref == 1);
f0101d5e:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101d63:	0f 85 ee 08 00 00    	jne    f0102657 <mem_init+0x12d2>
	assert(pp2->pp_ref == 0);
f0101d69:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d6e:	0f 85 fc 08 00 00    	jne    f0102670 <mem_init+0x12eb>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d74:	6a 00                	push   $0x0
f0101d76:	68 00 10 00 00       	push   $0x1000
f0101d7b:	57                   	push   %edi
f0101d7c:	56                   	push   %esi
f0101d7d:	e8 fe f4 ff ff       	call   f0101280 <page_insert>
f0101d82:	83 c4 10             	add    $0x10,%esp
f0101d85:	85 c0                	test   %eax,%eax
f0101d87:	0f 85 fc 08 00 00    	jne    f0102689 <mem_init+0x1304>
	assert(pp1->pp_ref);
f0101d8d:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101d92:	0f 84 0a 09 00 00    	je     f01026a2 <mem_init+0x131d>
	assert(pp1->pp_link == NULL);
f0101d98:	83 3f 00             	cmpl   $0x0,(%edi)
f0101d9b:	0f 85 1a 09 00 00    	jne    f01026bb <mem_init+0x1336>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101da1:	83 ec 08             	sub    $0x8,%esp
f0101da4:	68 00 10 00 00       	push   $0x1000
f0101da9:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101daf:	e8 7b f4 ff ff       	call   f010122f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101db4:	8b 35 8c 7e 21 f0    	mov    0xf0217e8c,%esi
f0101dba:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dbf:	89 f0                	mov    %esi,%eax
f0101dc1:	e8 c9 ed ff ff       	call   f0100b8f <check_va2pa>
f0101dc6:	83 c4 10             	add    $0x10,%esp
f0101dc9:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dcc:	0f 85 02 09 00 00    	jne    f01026d4 <mem_init+0x134f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101dd2:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dd7:	89 f0                	mov    %esi,%eax
f0101dd9:	e8 b1 ed ff ff       	call   f0100b8f <check_va2pa>
f0101dde:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101de1:	0f 85 06 09 00 00    	jne    f01026ed <mem_init+0x1368>
	assert(pp1->pp_ref == 0);
f0101de7:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101dec:	0f 85 14 09 00 00    	jne    f0102706 <mem_init+0x1381>
	assert(pp2->pp_ref == 0);
f0101df2:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101df7:	0f 85 22 09 00 00    	jne    f010271f <mem_init+0x139a>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101dfd:	83 ec 0c             	sub    $0xc,%esp
f0101e00:	6a 00                	push   $0x0
f0101e02:	e8 c4 f1 ff ff       	call   f0100fcb <page_alloc>
f0101e07:	83 c4 10             	add    $0x10,%esp
f0101e0a:	39 c7                	cmp    %eax,%edi
f0101e0c:	0f 85 26 09 00 00    	jne    f0102738 <mem_init+0x13b3>
f0101e12:	85 c0                	test   %eax,%eax
f0101e14:	0f 84 1e 09 00 00    	je     f0102738 <mem_init+0x13b3>

	// should be no free memory
	assert(!page_alloc(0));
f0101e1a:	83 ec 0c             	sub    $0xc,%esp
f0101e1d:	6a 00                	push   $0x0
f0101e1f:	e8 a7 f1 ff ff       	call   f0100fcb <page_alloc>
f0101e24:	83 c4 10             	add    $0x10,%esp
f0101e27:	85 c0                	test   %eax,%eax
f0101e29:	0f 85 22 09 00 00    	jne    f0102751 <mem_init+0x13cc>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e2f:	8b 0d 8c 7e 21 f0    	mov    0xf0217e8c,%ecx
f0101e35:	8b 11                	mov    (%ecx),%edx
f0101e37:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e3d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e40:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101e46:	c1 f8 03             	sar    $0x3,%eax
f0101e49:	c1 e0 0c             	shl    $0xc,%eax
f0101e4c:	39 c2                	cmp    %eax,%edx
f0101e4e:	0f 85 16 09 00 00    	jne    f010276a <mem_init+0x13e5>
	kern_pgdir[0] = 0;
f0101e54:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101e5a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e5d:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e62:	0f 85 1b 09 00 00    	jne    f0102783 <mem_init+0x13fe>
	pp0->pp_ref = 0;
f0101e68:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e6b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101e71:	83 ec 0c             	sub    $0xc,%esp
f0101e74:	50                   	push   %eax
f0101e75:	e8 ca f1 ff ff       	call   f0101044 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101e7a:	83 c4 0c             	add    $0xc,%esp
f0101e7d:	6a 01                	push   $0x1
f0101e7f:	68 00 10 40 00       	push   $0x401000
f0101e84:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101e8a:	e8 21 f2 ff ff       	call   f01010b0 <pgdir_walk>
f0101e8f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101e92:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101e95:	8b 0d 8c 7e 21 f0    	mov    0xf0217e8c,%ecx
f0101e9b:	8b 41 04             	mov    0x4(%ecx),%eax
f0101e9e:	89 c6                	mov    %eax,%esi
f0101ea0:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	if (PGNUM(pa) >= npages)
f0101ea6:	8b 15 88 7e 21 f0    	mov    0xf0217e88,%edx
f0101eac:	c1 e8 0c             	shr    $0xc,%eax
f0101eaf:	83 c4 10             	add    $0x10,%esp
f0101eb2:	39 d0                	cmp    %edx,%eax
f0101eb4:	0f 83 e2 08 00 00    	jae    f010279c <mem_init+0x1417>
	assert(ptep == ptep1 + PTX(va));
f0101eba:	81 ee fc ff ff 0f    	sub    $0xffffffc,%esi
f0101ec0:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f0101ec3:	0f 85 e8 08 00 00    	jne    f01027b1 <mem_init+0x142c>
	kern_pgdir[PDX(va)] = 0;
f0101ec9:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0101ed0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ed3:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0101ed9:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101edf:	c1 f8 03             	sar    $0x3,%eax
f0101ee2:	89 c1                	mov    %eax,%ecx
f0101ee4:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f0101ee7:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101eec:	39 c2                	cmp    %eax,%edx
f0101eee:	0f 86 d6 08 00 00    	jbe    f01027ca <mem_init+0x1445>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101ef4:	83 ec 04             	sub    $0x4,%esp
f0101ef7:	68 00 10 00 00       	push   $0x1000
f0101efc:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0101f01:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0101f07:	51                   	push   %ecx
f0101f08:	e8 03 3c 00 00       	call   f0105b10 <memset>
	page_free(pp0);
f0101f0d:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101f10:	89 34 24             	mov    %esi,(%esp)
f0101f13:	e8 2c f1 ff ff       	call   f0101044 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101f18:	83 c4 0c             	add    $0xc,%esp
f0101f1b:	6a 01                	push   $0x1
f0101f1d:	6a 00                	push   $0x0
f0101f1f:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0101f25:	e8 86 f1 ff ff       	call   f01010b0 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0101f2a:	89 f0                	mov    %esi,%eax
f0101f2c:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0101f32:	c1 f8 03             	sar    $0x3,%eax
f0101f35:	89 c2                	mov    %eax,%edx
f0101f37:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101f3a:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101f3f:	83 c4 10             	add    $0x10,%esp
f0101f42:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0101f48:	0f 83 8e 08 00 00    	jae    f01027dc <mem_init+0x1457>
	return (void *)(pa + KERNBASE);
f0101f4e:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101f54:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101f57:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101f5d:	f6 00 01             	testb  $0x1,(%eax)
f0101f60:	0f 85 88 08 00 00    	jne    f01027ee <mem_init+0x1469>
f0101f66:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0101f69:	39 d0                	cmp    %edx,%eax
f0101f6b:	75 f0                	jne    f0101f5d <mem_init+0xbd8>
	kern_pgdir[0] = 0;
f0101f6d:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0101f72:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101f78:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f7b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0101f81:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101f84:	89 0d 40 72 21 f0    	mov    %ecx,0xf0217240

	// free the pages we took
	page_free(pp0);
f0101f8a:	83 ec 0c             	sub    $0xc,%esp
f0101f8d:	50                   	push   %eax
f0101f8e:	e8 b1 f0 ff ff       	call   f0101044 <page_free>
	page_free(pp1);
f0101f93:	89 3c 24             	mov    %edi,(%esp)
f0101f96:	e8 a9 f0 ff ff       	call   f0101044 <page_free>
	page_free(pp2);
f0101f9b:	89 1c 24             	mov    %ebx,(%esp)
f0101f9e:	e8 a1 f0 ff ff       	call   f0101044 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0101fa3:	83 c4 08             	add    $0x8,%esp
f0101fa6:	68 01 10 00 00       	push   $0x1001
f0101fab:	6a 00                	push   $0x0
f0101fad:	e8 50 f3 ff ff       	call   f0101302 <mmio_map_region>
f0101fb2:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0101fb4:	83 c4 08             	add    $0x8,%esp
f0101fb7:	68 00 10 00 00       	push   $0x1000
f0101fbc:	6a 00                	push   $0x0
f0101fbe:	e8 3f f3 ff ff       	call   f0101302 <mmio_map_region>
f0101fc3:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8192 < MMIOLIM);
f0101fc5:	8d 83 00 20 00 00    	lea    0x2000(%ebx),%eax
f0101fcb:	83 c4 10             	add    $0x10,%esp
f0101fce:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0101fd4:	0f 86 2d 08 00 00    	jbe    f0102807 <mem_init+0x1482>
f0101fda:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0101fdf:	0f 87 22 08 00 00    	ja     f0102807 <mem_init+0x1482>
	assert(mm2 >= MMIOBASE && mm2 + 8192 < MMIOLIM);
f0101fe5:	8d 96 00 20 00 00    	lea    0x2000(%esi),%edx
f0101feb:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0101ff1:	0f 87 29 08 00 00    	ja     f0102820 <mem_init+0x149b>
f0101ff7:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0101ffd:	0f 86 1d 08 00 00    	jbe    f0102820 <mem_init+0x149b>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102003:	89 da                	mov    %ebx,%edx
f0102005:	09 f2                	or     %esi,%edx
f0102007:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f010200d:	0f 85 26 08 00 00    	jne    f0102839 <mem_init+0x14b4>
	// check that they don't overlap
	assert(mm1 + 8192 <= mm2);
f0102013:	39 c6                	cmp    %eax,%esi
f0102015:	0f 82 37 08 00 00    	jb     f0102852 <mem_init+0x14cd>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f010201b:	8b 3d 8c 7e 21 f0    	mov    0xf0217e8c,%edi
f0102021:	89 da                	mov    %ebx,%edx
f0102023:	89 f8                	mov    %edi,%eax
f0102025:	e8 65 eb ff ff       	call   f0100b8f <check_va2pa>
f010202a:	85 c0                	test   %eax,%eax
f010202c:	0f 85 39 08 00 00    	jne    f010286b <mem_init+0x14e6>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102032:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102038:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010203b:	89 c2                	mov    %eax,%edx
f010203d:	89 f8                	mov    %edi,%eax
f010203f:	e8 4b eb ff ff       	call   f0100b8f <check_va2pa>
f0102044:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102049:	0f 85 35 08 00 00    	jne    f0102884 <mem_init+0x14ff>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f010204f:	89 f2                	mov    %esi,%edx
f0102051:	89 f8                	mov    %edi,%eax
f0102053:	e8 37 eb ff ff       	call   f0100b8f <check_va2pa>
f0102058:	85 c0                	test   %eax,%eax
f010205a:	0f 85 3d 08 00 00    	jne    f010289d <mem_init+0x1518>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102060:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102066:	89 f8                	mov    %edi,%eax
f0102068:	e8 22 eb ff ff       	call   f0100b8f <check_va2pa>
f010206d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102070:	0f 85 40 08 00 00    	jne    f01028b6 <mem_init+0x1531>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102076:	83 ec 04             	sub    $0x4,%esp
f0102079:	6a 00                	push   $0x0
f010207b:	53                   	push   %ebx
f010207c:	57                   	push   %edi
f010207d:	e8 2e f0 ff ff       	call   f01010b0 <pgdir_walk>
f0102082:	83 c4 10             	add    $0x10,%esp
f0102085:	f6 00 1a             	testb  $0x1a,(%eax)
f0102088:	0f 84 41 08 00 00    	je     f01028cf <mem_init+0x154a>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f010208e:	83 ec 04             	sub    $0x4,%esp
f0102091:	6a 00                	push   $0x0
f0102093:	53                   	push   %ebx
f0102094:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f010209a:	e8 11 f0 ff ff       	call   f01010b0 <pgdir_walk>
f010209f:	8b 00                	mov    (%eax),%eax
f01020a1:	83 c4 10             	add    $0x10,%esp
f01020a4:	83 e0 04             	and    $0x4,%eax
f01020a7:	89 c7                	mov    %eax,%edi
f01020a9:	0f 85 39 08 00 00    	jne    f01028e8 <mem_init+0x1563>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f01020af:	83 ec 04             	sub    $0x4,%esp
f01020b2:	6a 00                	push   $0x0
f01020b4:	53                   	push   %ebx
f01020b5:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f01020bb:	e8 f0 ef ff ff       	call   f01010b0 <pgdir_walk>
f01020c0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f01020c6:	83 c4 0c             	add    $0xc,%esp
f01020c9:	6a 00                	push   $0x0
f01020cb:	ff 75 d4             	pushl  -0x2c(%ebp)
f01020ce:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f01020d4:	e8 d7 ef ff ff       	call   f01010b0 <pgdir_walk>
f01020d9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f01020df:	83 c4 0c             	add    $0xc,%esp
f01020e2:	6a 00                	push   $0x0
f01020e4:	56                   	push   %esi
f01020e5:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f01020eb:	e8 c0 ef ff ff       	call   f01010b0 <pgdir_walk>
f01020f0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f01020f6:	c7 04 24 ca 79 10 f0 	movl   $0xf01079ca,(%esp)
f01020fd:	e8 bf 18 00 00       	call   f01039c1 <cprintf>
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U);
f0102102:	a1 90 7e 21 f0       	mov    0xf0217e90,%eax
	if ((uint32_t)kva < KERNBASE)
f0102107:	83 c4 10             	add    $0x10,%esp
f010210a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010210f:	0f 86 ec 07 00 00    	jbe    f0102901 <mem_init+0x157c>
f0102115:	83 ec 08             	sub    $0x8,%esp
f0102118:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f010211a:	05 00 00 00 10       	add    $0x10000000,%eax
f010211f:	50                   	push   %eax
f0102120:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102125:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010212a:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f010212f:	e8 0d f0 ff ff       	call   f0101141 <boot_map_region>
	boot_map_region(kern_pgdir,UENVS,PTSIZE,PADDR(envs),PTE_U);
f0102134:	a1 48 72 21 f0       	mov    0xf0217248,%eax
	if ((uint32_t)kva < KERNBASE)
f0102139:	83 c4 10             	add    $0x10,%esp
f010213c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102141:	0f 86 cf 07 00 00    	jbe    f0102916 <mem_init+0x1591>
f0102147:	83 ec 08             	sub    $0x8,%esp
f010214a:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f010214c:	05 00 00 00 10       	add    $0x10000000,%eax
f0102151:	50                   	push   %eax
f0102152:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102157:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010215c:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0102161:	e8 db ef ff ff       	call   f0101141 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f0102166:	83 c4 10             	add    $0x10,%esp
f0102169:	b8 00 90 11 f0       	mov    $0xf0119000,%eax
f010216e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102173:	0f 86 b2 07 00 00    	jbe    f010292b <mem_init+0x15a6>
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f0102179:	83 ec 08             	sub    $0x8,%esp
f010217c:	6a 02                	push   $0x2
f010217e:	68 00 90 11 00       	push   $0x119000
f0102183:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102188:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010218d:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0102192:	e8 aa ef ff ff       	call   f0101141 <boot_map_region>
f0102197:	c7 45 d0 00 90 21 f0 	movl   $0xf0219000,-0x30(%ebp)
f010219e:	83 c4 10             	add    $0x10,%esp
f01021a1:	bb 00 90 21 f0       	mov    $0xf0219000,%ebx
f01021a6:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f01021ab:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01021b1:	0f 86 89 07 00 00    	jbe    f0102940 <mem_init+0x15bb>
		boot_map_region(kern_pgdir,kstacktop_i,KSTKSIZE,pa,PTE_W|PTE_P);
f01021b7:	83 ec 08             	sub    $0x8,%esp
f01021ba:	6a 03                	push   $0x3
f01021bc:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f01021c2:	50                   	push   %eax
f01021c3:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021c8:	89 f2                	mov    %esi,%edx
f01021ca:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f01021cf:	e8 6d ef ff ff       	call   f0101141 <boot_map_region>
f01021d4:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f01021da:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	for(int i = 0;i<NCPU;i++)
f01021e0:	83 c4 10             	add    $0x10,%esp
f01021e3:	81 fb 00 90 25 f0    	cmp    $0xf0259000,%ebx
f01021e9:	75 c0                	jne    f01021ab <mem_init+0xe26>
	boot_map_region(kern_pgdir,KERNBASE,0xFFFFFFFF-KERNBASE,0,PTE_W);
f01021eb:	83 ec 08             	sub    $0x8,%esp
f01021ee:	6a 02                	push   $0x2
f01021f0:	6a 00                	push   $0x0
f01021f2:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01021f7:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021fc:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f0102201:	e8 3b ef ff ff       	call   f0101141 <boot_map_region>
	pgdir = kern_pgdir;
f0102206:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
f010220b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010220e:	a1 88 7e 21 f0       	mov    0xf0217e88,%eax
f0102213:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0102216:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010221d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102222:	89 45 cc             	mov    %eax,-0x34(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102225:	8b 35 90 7e 21 f0    	mov    0xf0217e90,%esi
f010222b:	89 75 c8             	mov    %esi,-0x38(%ebp)
	return (physaddr_t)kva - KERNBASE;
f010222e:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0102234:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f0102237:	83 c4 10             	add    $0x10,%esp
f010223a:	89 fb                	mov    %edi,%ebx
f010223c:	e9 2f 07 00 00       	jmp    f0102970 <mem_init+0x15eb>
	assert(nfree == 0);
f0102241:	68 e1 78 10 f0       	push   $0xf01078e1
f0102246:	68 27 77 10 f0       	push   $0xf0107727
f010224b:	68 bf 03 00 00       	push   $0x3bf
f0102250:	68 01 77 10 f0       	push   $0xf0107701
f0102255:	e8 e6 dd ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f010225a:	68 ef 77 10 f0       	push   $0xf01077ef
f010225f:	68 27 77 10 f0       	push   $0xf0107727
f0102264:	68 25 04 00 00       	push   $0x425
f0102269:	68 01 77 10 f0       	push   $0xf0107701
f010226e:	e8 cd dd ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102273:	68 05 78 10 f0       	push   $0xf0107805
f0102278:	68 27 77 10 f0       	push   $0xf0107727
f010227d:	68 26 04 00 00       	push   $0x426
f0102282:	68 01 77 10 f0       	push   $0xf0107701
f0102287:	e8 b4 dd ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010228c:	68 1b 78 10 f0       	push   $0xf010781b
f0102291:	68 27 77 10 f0       	push   $0xf0107727
f0102296:	68 27 04 00 00       	push   $0x427
f010229b:	68 01 77 10 f0       	push   $0xf0107701
f01022a0:	e8 9b dd ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f01022a5:	68 31 78 10 f0       	push   $0xf0107831
f01022aa:	68 27 77 10 f0       	push   $0xf0107727
f01022af:	68 2a 04 00 00       	push   $0x42a
f01022b4:	68 01 77 10 f0       	push   $0xf0107701
f01022b9:	e8 82 dd ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01022be:	68 24 6f 10 f0       	push   $0xf0106f24
f01022c3:	68 27 77 10 f0       	push   $0xf0107727
f01022c8:	68 2b 04 00 00       	push   $0x42b
f01022cd:	68 01 77 10 f0       	push   $0xf0107701
f01022d2:	e8 69 dd ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01022d7:	68 9a 78 10 f0       	push   $0xf010789a
f01022dc:	68 27 77 10 f0       	push   $0xf0107727
f01022e1:	68 32 04 00 00       	push   $0x432
f01022e6:	68 01 77 10 f0       	push   $0xf0107701
f01022eb:	e8 50 dd ff ff       	call   f0100040 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01022f0:	68 64 6f 10 f0       	push   $0xf0106f64
f01022f5:	68 27 77 10 f0       	push   $0xf0107727
f01022fa:	68 35 04 00 00       	push   $0x435
f01022ff:	68 01 77 10 f0       	push   $0xf0107701
f0102304:	e8 37 dd ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102309:	68 9c 6f 10 f0       	push   $0xf0106f9c
f010230e:	68 27 77 10 f0       	push   $0xf0107727
f0102313:	68 38 04 00 00       	push   $0x438
f0102318:	68 01 77 10 f0       	push   $0xf0107701
f010231d:	e8 1e dd ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102322:	68 cc 6f 10 f0       	push   $0xf0106fcc
f0102327:	68 27 77 10 f0       	push   $0xf0107727
f010232c:	68 3c 04 00 00       	push   $0x43c
f0102331:	68 01 77 10 f0       	push   $0xf0107701
f0102336:	e8 05 dd ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010233b:	68 fc 6f 10 f0       	push   $0xf0106ffc
f0102340:	68 27 77 10 f0       	push   $0xf0107727
f0102345:	68 3d 04 00 00       	push   $0x43d
f010234a:	68 01 77 10 f0       	push   $0xf0107701
f010234f:	e8 ec dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0102354:	68 24 70 10 f0       	push   $0xf0107024
f0102359:	68 27 77 10 f0       	push   $0xf0107727
f010235e:	68 3e 04 00 00       	push   $0x43e
f0102363:	68 01 77 10 f0       	push   $0xf0107701
f0102368:	e8 d3 dc ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f010236d:	68 ec 78 10 f0       	push   $0xf01078ec
f0102372:	68 27 77 10 f0       	push   $0xf0107727
f0102377:	68 3f 04 00 00       	push   $0x43f
f010237c:	68 01 77 10 f0       	push   $0xf0107701
f0102381:	e8 ba dc ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0102386:	68 fd 78 10 f0       	push   $0xf01078fd
f010238b:	68 27 77 10 f0       	push   $0xf0107727
f0102390:	68 40 04 00 00       	push   $0x440
f0102395:	68 01 77 10 f0       	push   $0xf0107701
f010239a:	e8 a1 dc ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010239f:	68 54 70 10 f0       	push   $0xf0107054
f01023a4:	68 27 77 10 f0       	push   $0xf0107727
f01023a9:	68 43 04 00 00       	push   $0x443
f01023ae:	68 01 77 10 f0       	push   $0xf0107701
f01023b3:	e8 88 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01023b8:	68 90 70 10 f0       	push   $0xf0107090
f01023bd:	68 27 77 10 f0       	push   $0xf0107727
f01023c2:	68 44 04 00 00       	push   $0x444
f01023c7:	68 01 77 10 f0       	push   $0xf0107701
f01023cc:	e8 6f dc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01023d1:	68 0e 79 10 f0       	push   $0xf010790e
f01023d6:	68 27 77 10 f0       	push   $0xf0107727
f01023db:	68 45 04 00 00       	push   $0x445
f01023e0:	68 01 77 10 f0       	push   $0xf0107701
f01023e5:	e8 56 dc ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01023ea:	68 9a 78 10 f0       	push   $0xf010789a
f01023ef:	68 27 77 10 f0       	push   $0xf0107727
f01023f4:	68 48 04 00 00       	push   $0x448
f01023f9:	68 01 77 10 f0       	push   $0xf0107701
f01023fe:	e8 3d dc ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102403:	68 54 70 10 f0       	push   $0xf0107054
f0102408:	68 27 77 10 f0       	push   $0xf0107727
f010240d:	68 4b 04 00 00       	push   $0x44b
f0102412:	68 01 77 10 f0       	push   $0xf0107701
f0102417:	e8 24 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010241c:	68 90 70 10 f0       	push   $0xf0107090
f0102421:	68 27 77 10 f0       	push   $0xf0107727
f0102426:	68 4c 04 00 00       	push   $0x44c
f010242b:	68 01 77 10 f0       	push   $0xf0107701
f0102430:	e8 0b dc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102435:	68 0e 79 10 f0       	push   $0xf010790e
f010243a:	68 27 77 10 f0       	push   $0xf0107727
f010243f:	68 4d 04 00 00       	push   $0x44d
f0102444:	68 01 77 10 f0       	push   $0xf0107701
f0102449:	e8 f2 db ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f010244e:	68 9a 78 10 f0       	push   $0xf010789a
f0102453:	68 27 77 10 f0       	push   $0xf0107727
f0102458:	68 51 04 00 00       	push   $0x451
f010245d:	68 01 77 10 f0       	push   $0xf0107701
f0102462:	e8 d9 db ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102467:	52                   	push   %edx
f0102468:	68 c4 67 10 f0       	push   $0xf01067c4
f010246d:	68 54 04 00 00       	push   $0x454
f0102472:	68 01 77 10 f0       	push   $0xf0107701
f0102477:	e8 c4 db ff ff       	call   f0100040 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010247c:	68 c0 70 10 f0       	push   $0xf01070c0
f0102481:	68 27 77 10 f0       	push   $0xf0107727
f0102486:	68 55 04 00 00       	push   $0x455
f010248b:	68 01 77 10 f0       	push   $0xf0107701
f0102490:	e8 ab db ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102495:	68 00 71 10 f0       	push   $0xf0107100
f010249a:	68 27 77 10 f0       	push   $0xf0107727
f010249f:	68 58 04 00 00       	push   $0x458
f01024a4:	68 01 77 10 f0       	push   $0xf0107701
f01024a9:	e8 92 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01024ae:	68 90 70 10 f0       	push   $0xf0107090
f01024b3:	68 27 77 10 f0       	push   $0xf0107727
f01024b8:	68 59 04 00 00       	push   $0x459
f01024bd:	68 01 77 10 f0       	push   $0xf0107701
f01024c2:	e8 79 db ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01024c7:	68 0e 79 10 f0       	push   $0xf010790e
f01024cc:	68 27 77 10 f0       	push   $0xf0107727
f01024d1:	68 5a 04 00 00       	push   $0x45a
f01024d6:	68 01 77 10 f0       	push   $0xf0107701
f01024db:	e8 60 db ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01024e0:	68 40 71 10 f0       	push   $0xf0107140
f01024e5:	68 27 77 10 f0       	push   $0xf0107727
f01024ea:	68 5b 04 00 00       	push   $0x45b
f01024ef:	68 01 77 10 f0       	push   $0xf0107701
f01024f4:	e8 47 db ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01024f9:	68 1f 79 10 f0       	push   $0xf010791f
f01024fe:	68 27 77 10 f0       	push   $0xf0107727
f0102503:	68 5c 04 00 00       	push   $0x45c
f0102508:	68 01 77 10 f0       	push   $0xf0107701
f010250d:	e8 2e db ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102512:	68 54 70 10 f0       	push   $0xf0107054
f0102517:	68 27 77 10 f0       	push   $0xf0107727
f010251c:	68 5f 04 00 00       	push   $0x45f
f0102521:	68 01 77 10 f0       	push   $0xf0107701
f0102526:	e8 15 db ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010252b:	68 74 71 10 f0       	push   $0xf0107174
f0102530:	68 27 77 10 f0       	push   $0xf0107727
f0102535:	68 60 04 00 00       	push   $0x460
f010253a:	68 01 77 10 f0       	push   $0xf0107701
f010253f:	e8 fc da ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102544:	68 a8 71 10 f0       	push   $0xf01071a8
f0102549:	68 27 77 10 f0       	push   $0xf0107727
f010254e:	68 61 04 00 00       	push   $0x461
f0102553:	68 01 77 10 f0       	push   $0xf0107701
f0102558:	e8 e3 da ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010255d:	68 e0 71 10 f0       	push   $0xf01071e0
f0102562:	68 27 77 10 f0       	push   $0xf0107727
f0102567:	68 64 04 00 00       	push   $0x464
f010256c:	68 01 77 10 f0       	push   $0xf0107701
f0102571:	e8 ca da ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102576:	68 18 72 10 f0       	push   $0xf0107218
f010257b:	68 27 77 10 f0       	push   $0xf0107727
f0102580:	68 67 04 00 00       	push   $0x467
f0102585:	68 01 77 10 f0       	push   $0xf0107701
f010258a:	e8 b1 da ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010258f:	68 a8 71 10 f0       	push   $0xf01071a8
f0102594:	68 27 77 10 f0       	push   $0xf0107727
f0102599:	68 68 04 00 00       	push   $0x468
f010259e:	68 01 77 10 f0       	push   $0xf0107701
f01025a3:	e8 98 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01025a8:	68 54 72 10 f0       	push   $0xf0107254
f01025ad:	68 27 77 10 f0       	push   $0xf0107727
f01025b2:	68 6b 04 00 00       	push   $0x46b
f01025b7:	68 01 77 10 f0       	push   $0xf0107701
f01025bc:	e8 7f da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01025c1:	68 80 72 10 f0       	push   $0xf0107280
f01025c6:	68 27 77 10 f0       	push   $0xf0107727
f01025cb:	68 6c 04 00 00       	push   $0x46c
f01025d0:	68 01 77 10 f0       	push   $0xf0107701
f01025d5:	e8 66 da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 2);
f01025da:	68 35 79 10 f0       	push   $0xf0107935
f01025df:	68 27 77 10 f0       	push   $0xf0107727
f01025e4:	68 6e 04 00 00       	push   $0x46e
f01025e9:	68 01 77 10 f0       	push   $0xf0107701
f01025ee:	e8 4d da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01025f3:	68 46 79 10 f0       	push   $0xf0107946
f01025f8:	68 27 77 10 f0       	push   $0xf0107727
f01025fd:	68 6f 04 00 00       	push   $0x46f
f0102602:	68 01 77 10 f0       	push   $0xf0107701
f0102607:	e8 34 da ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f010260c:	68 b0 72 10 f0       	push   $0xf01072b0
f0102611:	68 27 77 10 f0       	push   $0xf0107727
f0102616:	68 72 04 00 00       	push   $0x472
f010261b:	68 01 77 10 f0       	push   $0xf0107701
f0102620:	e8 1b da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102625:	68 d4 72 10 f0       	push   $0xf01072d4
f010262a:	68 27 77 10 f0       	push   $0xf0107727
f010262f:	68 76 04 00 00       	push   $0x476
f0102634:	68 01 77 10 f0       	push   $0xf0107701
f0102639:	e8 02 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010263e:	68 80 72 10 f0       	push   $0xf0107280
f0102643:	68 27 77 10 f0       	push   $0xf0107727
f0102648:	68 77 04 00 00       	push   $0x477
f010264d:	68 01 77 10 f0       	push   $0xf0107701
f0102652:	e8 e9 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102657:	68 ec 78 10 f0       	push   $0xf01078ec
f010265c:	68 27 77 10 f0       	push   $0xf0107727
f0102661:	68 78 04 00 00       	push   $0x478
f0102666:	68 01 77 10 f0       	push   $0xf0107701
f010266b:	e8 d0 d9 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102670:	68 46 79 10 f0       	push   $0xf0107946
f0102675:	68 27 77 10 f0       	push   $0xf0107727
f010267a:	68 79 04 00 00       	push   $0x479
f010267f:	68 01 77 10 f0       	push   $0xf0107701
f0102684:	e8 b7 d9 ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102689:	68 f8 72 10 f0       	push   $0xf01072f8
f010268e:	68 27 77 10 f0       	push   $0xf0107727
f0102693:	68 7c 04 00 00       	push   $0x47c
f0102698:	68 01 77 10 f0       	push   $0xf0107701
f010269d:	e8 9e d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f01026a2:	68 57 79 10 f0       	push   $0xf0107957
f01026a7:	68 27 77 10 f0       	push   $0xf0107727
f01026ac:	68 7d 04 00 00       	push   $0x47d
f01026b1:	68 01 77 10 f0       	push   $0xf0107701
f01026b6:	e8 85 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f01026bb:	68 63 79 10 f0       	push   $0xf0107963
f01026c0:	68 27 77 10 f0       	push   $0xf0107727
f01026c5:	68 7e 04 00 00       	push   $0x47e
f01026ca:	68 01 77 10 f0       	push   $0xf0107701
f01026cf:	e8 6c d9 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01026d4:	68 d4 72 10 f0       	push   $0xf01072d4
f01026d9:	68 27 77 10 f0       	push   $0xf0107727
f01026de:	68 82 04 00 00       	push   $0x482
f01026e3:	68 01 77 10 f0       	push   $0xf0107701
f01026e8:	e8 53 d9 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01026ed:	68 30 73 10 f0       	push   $0xf0107330
f01026f2:	68 27 77 10 f0       	push   $0xf0107727
f01026f7:	68 83 04 00 00       	push   $0x483
f01026fc:	68 01 77 10 f0       	push   $0xf0107701
f0102701:	e8 3a d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102706:	68 78 79 10 f0       	push   $0xf0107978
f010270b:	68 27 77 10 f0       	push   $0xf0107727
f0102710:	68 84 04 00 00       	push   $0x484
f0102715:	68 01 77 10 f0       	push   $0xf0107701
f010271a:	e8 21 d9 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010271f:	68 46 79 10 f0       	push   $0xf0107946
f0102724:	68 27 77 10 f0       	push   $0xf0107727
f0102729:	68 85 04 00 00       	push   $0x485
f010272e:	68 01 77 10 f0       	push   $0xf0107701
f0102733:	e8 08 d9 ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f0102738:	68 58 73 10 f0       	push   $0xf0107358
f010273d:	68 27 77 10 f0       	push   $0xf0107727
f0102742:	68 88 04 00 00       	push   $0x488
f0102747:	68 01 77 10 f0       	push   $0xf0107701
f010274c:	e8 ef d8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0102751:	68 9a 78 10 f0       	push   $0xf010789a
f0102756:	68 27 77 10 f0       	push   $0xf0107727
f010275b:	68 8b 04 00 00       	push   $0x48b
f0102760:	68 01 77 10 f0       	push   $0xf0107701
f0102765:	e8 d6 d8 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010276a:	68 fc 6f 10 f0       	push   $0xf0106ffc
f010276f:	68 27 77 10 f0       	push   $0xf0107727
f0102774:	68 8e 04 00 00       	push   $0x48e
f0102779:	68 01 77 10 f0       	push   $0xf0107701
f010277e:	e8 bd d8 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0102783:	68 fd 78 10 f0       	push   $0xf01078fd
f0102788:	68 27 77 10 f0       	push   $0xf0107727
f010278d:	68 90 04 00 00       	push   $0x490
f0102792:	68 01 77 10 f0       	push   $0xf0107701
f0102797:	e8 a4 d8 ff ff       	call   f0100040 <_panic>
f010279c:	56                   	push   %esi
f010279d:	68 c4 67 10 f0       	push   $0xf01067c4
f01027a2:	68 97 04 00 00       	push   $0x497
f01027a7:	68 01 77 10 f0       	push   $0xf0107701
f01027ac:	e8 8f d8 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01027b1:	68 89 79 10 f0       	push   $0xf0107989
f01027b6:	68 27 77 10 f0       	push   $0xf0107727
f01027bb:	68 98 04 00 00       	push   $0x498
f01027c0:	68 01 77 10 f0       	push   $0xf0107701
f01027c5:	e8 76 d8 ff ff       	call   f0100040 <_panic>
f01027ca:	51                   	push   %ecx
f01027cb:	68 c4 67 10 f0       	push   $0xf01067c4
f01027d0:	6a 58                	push   $0x58
f01027d2:	68 0d 77 10 f0       	push   $0xf010770d
f01027d7:	e8 64 d8 ff ff       	call   f0100040 <_panic>
f01027dc:	52                   	push   %edx
f01027dd:	68 c4 67 10 f0       	push   $0xf01067c4
f01027e2:	6a 58                	push   $0x58
f01027e4:	68 0d 77 10 f0       	push   $0xf010770d
f01027e9:	e8 52 d8 ff ff       	call   f0100040 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f01027ee:	68 a1 79 10 f0       	push   $0xf01079a1
f01027f3:	68 27 77 10 f0       	push   $0xf0107727
f01027f8:	68 a2 04 00 00       	push   $0x4a2
f01027fd:	68 01 77 10 f0       	push   $0xf0107701
f0102802:	e8 39 d8 ff ff       	call   f0100040 <_panic>
	assert(mm1 >= MMIOBASE && mm1 + 8192 < MMIOLIM);
f0102807:	68 7c 73 10 f0       	push   $0xf010737c
f010280c:	68 27 77 10 f0       	push   $0xf0107727
f0102811:	68 b2 04 00 00       	push   $0x4b2
f0102816:	68 01 77 10 f0       	push   $0xf0107701
f010281b:	e8 20 d8 ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8192 < MMIOLIM);
f0102820:	68 a4 73 10 f0       	push   $0xf01073a4
f0102825:	68 27 77 10 f0       	push   $0xf0107727
f010282a:	68 b3 04 00 00       	push   $0x4b3
f010282f:	68 01 77 10 f0       	push   $0xf0107701
f0102834:	e8 07 d8 ff ff       	call   f0100040 <_panic>
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102839:	68 cc 73 10 f0       	push   $0xf01073cc
f010283e:	68 27 77 10 f0       	push   $0xf0107727
f0102843:	68 b5 04 00 00       	push   $0x4b5
f0102848:	68 01 77 10 f0       	push   $0xf0107701
f010284d:	e8 ee d7 ff ff       	call   f0100040 <_panic>
	assert(mm1 + 8192 <= mm2);
f0102852:	68 b8 79 10 f0       	push   $0xf01079b8
f0102857:	68 27 77 10 f0       	push   $0xf0107727
f010285c:	68 b7 04 00 00       	push   $0x4b7
f0102861:	68 01 77 10 f0       	push   $0xf0107701
f0102866:	e8 d5 d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f010286b:	68 f4 73 10 f0       	push   $0xf01073f4
f0102870:	68 27 77 10 f0       	push   $0xf0107727
f0102875:	68 b9 04 00 00       	push   $0x4b9
f010287a:	68 01 77 10 f0       	push   $0xf0107701
f010287f:	e8 bc d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102884:	68 18 74 10 f0       	push   $0xf0107418
f0102889:	68 27 77 10 f0       	push   $0xf0107727
f010288e:	68 ba 04 00 00       	push   $0x4ba
f0102893:	68 01 77 10 f0       	push   $0xf0107701
f0102898:	e8 a3 d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f010289d:	68 48 74 10 f0       	push   $0xf0107448
f01028a2:	68 27 77 10 f0       	push   $0xf0107727
f01028a7:	68 bb 04 00 00       	push   $0x4bb
f01028ac:	68 01 77 10 f0       	push   $0xf0107701
f01028b1:	e8 8a d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f01028b6:	68 6c 74 10 f0       	push   $0xf010746c
f01028bb:	68 27 77 10 f0       	push   $0xf0107727
f01028c0:	68 bc 04 00 00       	push   $0x4bc
f01028c5:	68 01 77 10 f0       	push   $0xf0107701
f01028ca:	e8 71 d7 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f01028cf:	68 98 74 10 f0       	push   $0xf0107498
f01028d4:	68 27 77 10 f0       	push   $0xf0107727
f01028d9:	68 be 04 00 00       	push   $0x4be
f01028de:	68 01 77 10 f0       	push   $0xf0107701
f01028e3:	e8 58 d7 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f01028e8:	68 dc 74 10 f0       	push   $0xf01074dc
f01028ed:	68 27 77 10 f0       	push   $0xf0107727
f01028f2:	68 bf 04 00 00       	push   $0x4bf
f01028f7:	68 01 77 10 f0       	push   $0xf0107701
f01028fc:	e8 3f d7 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102901:	50                   	push   %eax
f0102902:	68 e8 67 10 f0       	push   $0xf01067e8
f0102907:	68 cd 00 00 00       	push   $0xcd
f010290c:	68 01 77 10 f0       	push   $0xf0107701
f0102911:	e8 2a d7 ff ff       	call   f0100040 <_panic>
f0102916:	50                   	push   %eax
f0102917:	68 e8 67 10 f0       	push   $0xf01067e8
f010291c:	68 d5 00 00 00       	push   $0xd5
f0102921:	68 01 77 10 f0       	push   $0xf0107701
f0102926:	e8 15 d7 ff ff       	call   f0100040 <_panic>
f010292b:	50                   	push   %eax
f010292c:	68 e8 67 10 f0       	push   $0xf01067e8
f0102931:	68 e1 00 00 00       	push   $0xe1
f0102936:	68 01 77 10 f0       	push   $0xf0107701
f010293b:	e8 00 d7 ff ff       	call   f0100040 <_panic>
f0102940:	53                   	push   %ebx
f0102941:	68 e8 67 10 f0       	push   $0xf01067e8
f0102946:	68 21 01 00 00       	push   $0x121
f010294b:	68 01 77 10 f0       	push   $0xf0107701
f0102950:	e8 eb d6 ff ff       	call   f0100040 <_panic>
f0102955:	56                   	push   %esi
f0102956:	68 e8 67 10 f0       	push   $0xf01067e8
f010295b:	68 d7 03 00 00       	push   $0x3d7
f0102960:	68 01 77 10 f0       	push   $0xf0107701
f0102965:	e8 d6 d6 ff ff       	call   f0100040 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f010296a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102970:	39 5d cc             	cmp    %ebx,-0x34(%ebp)
f0102973:	76 3a                	jbe    f01029af <mem_init+0x162a>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102975:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f010297b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010297e:	e8 0c e2 ff ff       	call   f0100b8f <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102983:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f010298a:	76 c9                	jbe    f0102955 <mem_init+0x15d0>
f010298c:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f010298f:	8d 14 0b             	lea    (%ebx,%ecx,1),%edx
f0102992:	39 d0                	cmp    %edx,%eax
f0102994:	74 d4                	je     f010296a <mem_init+0x15e5>
f0102996:	68 10 75 10 f0       	push   $0xf0107510
f010299b:	68 27 77 10 f0       	push   $0xf0107727
f01029a0:	68 d7 03 00 00       	push   $0x3d7
f01029a5:	68 01 77 10 f0       	push   $0xf0107701
f01029aa:	e8 91 d6 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01029af:	a1 48 72 21 f0       	mov    0xf0217248,%eax
f01029b4:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01029b7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01029ba:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f01029bf:	8d b0 00 00 40 21    	lea    0x21400000(%eax),%esi
f01029c5:	89 da                	mov    %ebx,%edx
f01029c7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029ca:	e8 c0 e1 ff ff       	call   f0100b8f <check_va2pa>
f01029cf:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f01029d6:	76 3b                	jbe    f0102a13 <mem_init+0x168e>
f01029d8:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f01029db:	39 d0                	cmp    %edx,%eax
f01029dd:	75 4b                	jne    f0102a2a <mem_init+0x16a5>
f01029df:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
f01029e5:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f01029eb:	75 d8                	jne    f01029c5 <mem_init+0x1640>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01029ed:	8b 75 c0             	mov    -0x40(%ebp),%esi
f01029f0:	c1 e6 0c             	shl    $0xc,%esi
f01029f3:	89 fb                	mov    %edi,%ebx
f01029f5:	39 f3                	cmp    %esi,%ebx
f01029f7:	73 63                	jae    f0102a5c <mem_init+0x16d7>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01029f9:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01029ff:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a02:	e8 88 e1 ff ff       	call   f0100b8f <check_va2pa>
f0102a07:	39 c3                	cmp    %eax,%ebx
f0102a09:	75 38                	jne    f0102a43 <mem_init+0x16be>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a0b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102a11:	eb e2                	jmp    f01029f5 <mem_init+0x1670>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a13:	ff 75 c8             	pushl  -0x38(%ebp)
f0102a16:	68 e8 67 10 f0       	push   $0xf01067e8
f0102a1b:	68 dc 03 00 00       	push   $0x3dc
f0102a20:	68 01 77 10 f0       	push   $0xf0107701
f0102a25:	e8 16 d6 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102a2a:	68 44 75 10 f0       	push   $0xf0107544
f0102a2f:	68 27 77 10 f0       	push   $0xf0107727
f0102a34:	68 dc 03 00 00       	push   $0x3dc
f0102a39:	68 01 77 10 f0       	push   $0xf0107701
f0102a3e:	e8 fd d5 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102a43:	68 78 75 10 f0       	push   $0xf0107578
f0102a48:	68 27 77 10 f0       	push   $0xf0107727
f0102a4d:	68 e0 03 00 00       	push   $0x3e0
f0102a52:	68 01 77 10 f0       	push   $0xf0107701
f0102a57:	e8 e4 d5 ff ff       	call   f0100040 <_panic>
f0102a5c:	c7 45 cc 00 90 22 00 	movl   $0x229000,-0x34(%ebp)
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a63:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
f0102a68:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0102a6b:	8d bb 00 80 ff ff    	lea    -0x8000(%ebx),%edi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102a71:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102a74:	89 45 bc             	mov    %eax,-0x44(%ebp)
f0102a77:	89 de                	mov    %ebx,%esi
f0102a79:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102a7c:	05 00 80 ff 0f       	add    $0xfff8000,%eax
f0102a81:	89 45 c8             	mov    %eax,-0x38(%ebp)
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102a84:	8d 83 00 80 00 00    	lea    0x8000(%ebx),%eax
f0102a8a:	89 45 c4             	mov    %eax,-0x3c(%ebp)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102a8d:	89 f2                	mov    %esi,%edx
f0102a8f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a92:	e8 f8 e0 ff ff       	call   f0100b8f <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102a97:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102a9e:	76 58                	jbe    f0102af8 <mem_init+0x1773>
f0102aa0:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102aa3:	8d 14 31             	lea    (%ecx,%esi,1),%edx
f0102aa6:	39 d0                	cmp    %edx,%eax
f0102aa8:	75 65                	jne    f0102b0f <mem_init+0x178a>
f0102aaa:	81 c6 00 10 00 00    	add    $0x1000,%esi
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102ab0:	3b 75 c4             	cmp    -0x3c(%ebp),%esi
f0102ab3:	75 d8                	jne    f0102a8d <mem_init+0x1708>
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102ab5:	89 fa                	mov    %edi,%edx
f0102ab7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102aba:	e8 d0 e0 ff ff       	call   f0100b8f <check_va2pa>
f0102abf:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102ac2:	75 64                	jne    f0102b28 <mem_init+0x17a3>
f0102ac4:	81 c7 00 10 00 00    	add    $0x1000,%edi
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102aca:	39 df                	cmp    %ebx,%edi
f0102acc:	75 e7                	jne    f0102ab5 <mem_init+0x1730>
f0102ace:	81 eb 00 00 01 00    	sub    $0x10000,%ebx
f0102ad4:	81 45 d0 00 80 00 00 	addl   $0x8000,-0x30(%ebp)
f0102adb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102ade:	81 45 cc 00 80 01 00 	addl   $0x18000,-0x34(%ebp)
	for (n = 0; n < NCPU; n++) {
f0102ae5:	3d 00 90 25 f0       	cmp    $0xf0259000,%eax
f0102aea:	0f 85 7b ff ff ff    	jne    f0102a6b <mem_init+0x16e6>
f0102af0:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0102af3:	e9 84 00 00 00       	jmp    f0102b7c <mem_init+0x17f7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102af8:	ff 75 bc             	pushl  -0x44(%ebp)
f0102afb:	68 e8 67 10 f0       	push   $0xf01067e8
f0102b00:	68 e8 03 00 00       	push   $0x3e8
f0102b05:	68 01 77 10 f0       	push   $0xf0107701
f0102b0a:	e8 31 d5 ff ff       	call   f0100040 <_panic>
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102b0f:	68 a0 75 10 f0       	push   $0xf01075a0
f0102b14:	68 27 77 10 f0       	push   $0xf0107727
f0102b19:	68 e7 03 00 00       	push   $0x3e7
f0102b1e:	68 01 77 10 f0       	push   $0xf0107701
f0102b23:	e8 18 d5 ff ff       	call   f0100040 <_panic>
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102b28:	68 e8 75 10 f0       	push   $0xf01075e8
f0102b2d:	68 27 77 10 f0       	push   $0xf0107727
f0102b32:	68 ea 03 00 00       	push   $0x3ea
f0102b37:	68 01 77 10 f0       	push   $0xf0107701
f0102b3c:	e8 ff d4 ff ff       	call   f0100040 <_panic>
			assert(pgdir[i] & PTE_P);
f0102b41:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b44:	f6 04 b8 01          	testb  $0x1,(%eax,%edi,4)
f0102b48:	75 4e                	jne    f0102b98 <mem_init+0x1813>
f0102b4a:	68 e3 79 10 f0       	push   $0xf01079e3
f0102b4f:	68 27 77 10 f0       	push   $0xf0107727
f0102b54:	68 f5 03 00 00       	push   $0x3f5
f0102b59:	68 01 77 10 f0       	push   $0xf0107701
f0102b5e:	e8 dd d4 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_P);
f0102b63:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b66:	8b 04 b8             	mov    (%eax,%edi,4),%eax
f0102b69:	a8 01                	test   $0x1,%al
f0102b6b:	74 30                	je     f0102b9d <mem_init+0x1818>
				assert(pgdir[i] & PTE_W);
f0102b6d:	a8 02                	test   $0x2,%al
f0102b6f:	74 45                	je     f0102bb6 <mem_init+0x1831>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b71:	83 c7 01             	add    $0x1,%edi
f0102b74:	81 ff 00 04 00 00    	cmp    $0x400,%edi
f0102b7a:	74 6c                	je     f0102be8 <mem_init+0x1863>
		switch (i) {
f0102b7c:	8d 87 45 fc ff ff    	lea    -0x3bb(%edi),%eax
f0102b82:	83 f8 04             	cmp    $0x4,%eax
f0102b85:	76 ba                	jbe    f0102b41 <mem_init+0x17bc>
			if (i >= PDX(KERNBASE)) {
f0102b87:	81 ff bf 03 00 00    	cmp    $0x3bf,%edi
f0102b8d:	77 d4                	ja     f0102b63 <mem_init+0x17de>
				assert(pgdir[i] == 0);
f0102b8f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b92:	83 3c b8 00          	cmpl   $0x0,(%eax,%edi,4)
f0102b96:	75 37                	jne    f0102bcf <mem_init+0x184a>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b98:	83 c7 01             	add    $0x1,%edi
f0102b9b:	eb df                	jmp    f0102b7c <mem_init+0x17f7>
				assert(pgdir[i] & PTE_P);
f0102b9d:	68 e3 79 10 f0       	push   $0xf01079e3
f0102ba2:	68 27 77 10 f0       	push   $0xf0107727
f0102ba7:	68 f9 03 00 00       	push   $0x3f9
f0102bac:	68 01 77 10 f0       	push   $0xf0107701
f0102bb1:	e8 8a d4 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102bb6:	68 f4 79 10 f0       	push   $0xf01079f4
f0102bbb:	68 27 77 10 f0       	push   $0xf0107727
f0102bc0:	68 fa 03 00 00       	push   $0x3fa
f0102bc5:	68 01 77 10 f0       	push   $0xf0107701
f0102bca:	e8 71 d4 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] == 0);
f0102bcf:	68 05 7a 10 f0       	push   $0xf0107a05
f0102bd4:	68 27 77 10 f0       	push   $0xf0107727
f0102bd9:	68 fc 03 00 00       	push   $0x3fc
f0102bde:	68 01 77 10 f0       	push   $0xf0107701
f0102be3:	e8 58 d4 ff ff       	call   f0100040 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102be8:	83 ec 0c             	sub    $0xc,%esp
f0102beb:	68 0c 76 10 f0       	push   $0xf010760c
f0102bf0:	e8 cc 0d 00 00       	call   f01039c1 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102bf5:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0102bfa:	83 c4 10             	add    $0x10,%esp
f0102bfd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c02:	0f 86 03 02 00 00    	jbe    f0102e0b <mem_init+0x1a86>
	return (physaddr_t)kva - KERNBASE;
f0102c08:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102c0d:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102c10:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c15:	e8 d8 df ff ff       	call   f0100bf2 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102c1a:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102c1d:	83 e0 f3             	and    $0xfffffff3,%eax
f0102c20:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102c25:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102c28:	83 ec 0c             	sub    $0xc,%esp
f0102c2b:	6a 00                	push   $0x0
f0102c2d:	e8 99 e3 ff ff       	call   f0100fcb <page_alloc>
f0102c32:	89 c6                	mov    %eax,%esi
f0102c34:	83 c4 10             	add    $0x10,%esp
f0102c37:	85 c0                	test   %eax,%eax
f0102c39:	0f 84 e1 01 00 00    	je     f0102e20 <mem_init+0x1a9b>
	assert((pp1 = page_alloc(0)));
f0102c3f:	83 ec 0c             	sub    $0xc,%esp
f0102c42:	6a 00                	push   $0x0
f0102c44:	e8 82 e3 ff ff       	call   f0100fcb <page_alloc>
f0102c49:	89 c7                	mov    %eax,%edi
f0102c4b:	83 c4 10             	add    $0x10,%esp
f0102c4e:	85 c0                	test   %eax,%eax
f0102c50:	0f 84 e3 01 00 00    	je     f0102e39 <mem_init+0x1ab4>
	assert((pp2 = page_alloc(0)));
f0102c56:	83 ec 0c             	sub    $0xc,%esp
f0102c59:	6a 00                	push   $0x0
f0102c5b:	e8 6b e3 ff ff       	call   f0100fcb <page_alloc>
f0102c60:	89 c3                	mov    %eax,%ebx
f0102c62:	83 c4 10             	add    $0x10,%esp
f0102c65:	85 c0                	test   %eax,%eax
f0102c67:	0f 84 e5 01 00 00    	je     f0102e52 <mem_init+0x1acd>
	page_free(pp0);
f0102c6d:	83 ec 0c             	sub    $0xc,%esp
f0102c70:	56                   	push   %esi
f0102c71:	e8 ce e3 ff ff       	call   f0101044 <page_free>
	return (pp - pages) << PGSHIFT;
f0102c76:	89 f8                	mov    %edi,%eax
f0102c78:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0102c7e:	c1 f8 03             	sar    $0x3,%eax
f0102c81:	89 c2                	mov    %eax,%edx
f0102c83:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102c86:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102c8b:	83 c4 10             	add    $0x10,%esp
f0102c8e:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0102c94:	0f 83 d1 01 00 00    	jae    f0102e6b <mem_init+0x1ae6>
	memset(page2kva(pp1), 1, PGSIZE);
f0102c9a:	83 ec 04             	sub    $0x4,%esp
f0102c9d:	68 00 10 00 00       	push   $0x1000
f0102ca2:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102ca4:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102caa:	52                   	push   %edx
f0102cab:	e8 60 2e 00 00       	call   f0105b10 <memset>
	return (pp - pages) << PGSHIFT;
f0102cb0:	89 d8                	mov    %ebx,%eax
f0102cb2:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0102cb8:	c1 f8 03             	sar    $0x3,%eax
f0102cbb:	89 c2                	mov    %eax,%edx
f0102cbd:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102cc0:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102cc5:	83 c4 10             	add    $0x10,%esp
f0102cc8:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0102cce:	0f 83 a9 01 00 00    	jae    f0102e7d <mem_init+0x1af8>
	memset(page2kva(pp2), 2, PGSIZE);
f0102cd4:	83 ec 04             	sub    $0x4,%esp
f0102cd7:	68 00 10 00 00       	push   $0x1000
f0102cdc:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102cde:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102ce4:	52                   	push   %edx
f0102ce5:	e8 26 2e 00 00       	call   f0105b10 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102cea:	6a 02                	push   $0x2
f0102cec:	68 00 10 00 00       	push   $0x1000
f0102cf1:	57                   	push   %edi
f0102cf2:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0102cf8:	e8 83 e5 ff ff       	call   f0101280 <page_insert>
	assert(pp1->pp_ref == 1);
f0102cfd:	83 c4 20             	add    $0x20,%esp
f0102d00:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102d05:	0f 85 84 01 00 00    	jne    f0102e8f <mem_init+0x1b0a>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102d0b:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102d12:	01 01 01 
f0102d15:	0f 85 8d 01 00 00    	jne    f0102ea8 <mem_init+0x1b23>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102d1b:	6a 02                	push   $0x2
f0102d1d:	68 00 10 00 00       	push   $0x1000
f0102d22:	53                   	push   %ebx
f0102d23:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0102d29:	e8 52 e5 ff ff       	call   f0101280 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102d2e:	83 c4 10             	add    $0x10,%esp
f0102d31:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102d38:	02 02 02 
f0102d3b:	0f 85 80 01 00 00    	jne    f0102ec1 <mem_init+0x1b3c>
	assert(pp2->pp_ref == 1);
f0102d41:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102d46:	0f 85 8e 01 00 00    	jne    f0102eda <mem_init+0x1b55>
	assert(pp1->pp_ref == 0);
f0102d4c:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102d51:	0f 85 9c 01 00 00    	jne    f0102ef3 <mem_init+0x1b6e>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d57:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d5e:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102d61:	89 d8                	mov    %ebx,%eax
f0102d63:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0102d69:	c1 f8 03             	sar    $0x3,%eax
f0102d6c:	89 c2                	mov    %eax,%edx
f0102d6e:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102d71:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102d76:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0102d7c:	0f 83 8a 01 00 00    	jae    f0102f0c <mem_init+0x1b87>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d82:	81 ba 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%edx)
f0102d89:	03 03 03 
f0102d8c:	0f 85 8c 01 00 00    	jne    f0102f1e <mem_init+0x1b99>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d92:	83 ec 08             	sub    $0x8,%esp
f0102d95:	68 00 10 00 00       	push   $0x1000
f0102d9a:	ff 35 8c 7e 21 f0    	pushl  0xf0217e8c
f0102da0:	e8 8a e4 ff ff       	call   f010122f <page_remove>
	assert(pp2->pp_ref == 0);
f0102da5:	83 c4 10             	add    $0x10,%esp
f0102da8:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102dad:	0f 85 84 01 00 00    	jne    f0102f37 <mem_init+0x1bb2>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102db3:	8b 0d 8c 7e 21 f0    	mov    0xf0217e8c,%ecx
f0102db9:	8b 11                	mov    (%ecx),%edx
f0102dbb:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102dc1:	89 f0                	mov    %esi,%eax
f0102dc3:	2b 05 90 7e 21 f0    	sub    0xf0217e90,%eax
f0102dc9:	c1 f8 03             	sar    $0x3,%eax
f0102dcc:	c1 e0 0c             	shl    $0xc,%eax
f0102dcf:	39 c2                	cmp    %eax,%edx
f0102dd1:	0f 85 79 01 00 00    	jne    f0102f50 <mem_init+0x1bcb>
	kern_pgdir[0] = 0;
f0102dd7:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102ddd:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102de2:	0f 85 81 01 00 00    	jne    f0102f69 <mem_init+0x1be4>
	pp0->pp_ref = 0;
f0102de8:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102dee:	83 ec 0c             	sub    $0xc,%esp
f0102df1:	56                   	push   %esi
f0102df2:	e8 4d e2 ff ff       	call   f0101044 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102df7:	c7 04 24 a0 76 10 f0 	movl   $0xf01076a0,(%esp)
f0102dfe:	e8 be 0b 00 00       	call   f01039c1 <cprintf>
}
f0102e03:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e06:	5b                   	pop    %ebx
f0102e07:	5e                   	pop    %esi
f0102e08:	5f                   	pop    %edi
f0102e09:	5d                   	pop    %ebp
f0102e0a:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e0b:	50                   	push   %eax
f0102e0c:	68 e8 67 10 f0       	push   $0xf01067e8
f0102e11:	68 f9 00 00 00       	push   $0xf9
f0102e16:	68 01 77 10 f0       	push   $0xf0107701
f0102e1b:	e8 20 d2 ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f0102e20:	68 ef 77 10 f0       	push   $0xf01077ef
f0102e25:	68 27 77 10 f0       	push   $0xf0107727
f0102e2a:	68 d4 04 00 00       	push   $0x4d4
f0102e2f:	68 01 77 10 f0       	push   $0xf0107701
f0102e34:	e8 07 d2 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102e39:	68 05 78 10 f0       	push   $0xf0107805
f0102e3e:	68 27 77 10 f0       	push   $0xf0107727
f0102e43:	68 d5 04 00 00       	push   $0x4d5
f0102e48:	68 01 77 10 f0       	push   $0xf0107701
f0102e4d:	e8 ee d1 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102e52:	68 1b 78 10 f0       	push   $0xf010781b
f0102e57:	68 27 77 10 f0       	push   $0xf0107727
f0102e5c:	68 d6 04 00 00       	push   $0x4d6
f0102e61:	68 01 77 10 f0       	push   $0xf0107701
f0102e66:	e8 d5 d1 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e6b:	52                   	push   %edx
f0102e6c:	68 c4 67 10 f0       	push   $0xf01067c4
f0102e71:	6a 58                	push   $0x58
f0102e73:	68 0d 77 10 f0       	push   $0xf010770d
f0102e78:	e8 c3 d1 ff ff       	call   f0100040 <_panic>
f0102e7d:	52                   	push   %edx
f0102e7e:	68 c4 67 10 f0       	push   $0xf01067c4
f0102e83:	6a 58                	push   $0x58
f0102e85:	68 0d 77 10 f0       	push   $0xf010770d
f0102e8a:	e8 b1 d1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102e8f:	68 ec 78 10 f0       	push   $0xf01078ec
f0102e94:	68 27 77 10 f0       	push   $0xf0107727
f0102e99:	68 db 04 00 00       	push   $0x4db
f0102e9e:	68 01 77 10 f0       	push   $0xf0107701
f0102ea3:	e8 98 d1 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ea8:	68 2c 76 10 f0       	push   $0xf010762c
f0102ead:	68 27 77 10 f0       	push   $0xf0107727
f0102eb2:	68 dc 04 00 00       	push   $0x4dc
f0102eb7:	68 01 77 10 f0       	push   $0xf0107701
f0102ebc:	e8 7f d1 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102ec1:	68 50 76 10 f0       	push   $0xf0107650
f0102ec6:	68 27 77 10 f0       	push   $0xf0107727
f0102ecb:	68 de 04 00 00       	push   $0x4de
f0102ed0:	68 01 77 10 f0       	push   $0xf0107701
f0102ed5:	e8 66 d1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102eda:	68 0e 79 10 f0       	push   $0xf010790e
f0102edf:	68 27 77 10 f0       	push   $0xf0107727
f0102ee4:	68 df 04 00 00       	push   $0x4df
f0102ee9:	68 01 77 10 f0       	push   $0xf0107701
f0102eee:	e8 4d d1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102ef3:	68 78 79 10 f0       	push   $0xf0107978
f0102ef8:	68 27 77 10 f0       	push   $0xf0107727
f0102efd:	68 e0 04 00 00       	push   $0x4e0
f0102f02:	68 01 77 10 f0       	push   $0xf0107701
f0102f07:	e8 34 d1 ff ff       	call   f0100040 <_panic>
f0102f0c:	52                   	push   %edx
f0102f0d:	68 c4 67 10 f0       	push   $0xf01067c4
f0102f12:	6a 58                	push   $0x58
f0102f14:	68 0d 77 10 f0       	push   $0xf010770d
f0102f19:	e8 22 d1 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102f1e:	68 74 76 10 f0       	push   $0xf0107674
f0102f23:	68 27 77 10 f0       	push   $0xf0107727
f0102f28:	68 e2 04 00 00       	push   $0x4e2
f0102f2d:	68 01 77 10 f0       	push   $0xf0107701
f0102f32:	e8 09 d1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102f37:	68 46 79 10 f0       	push   $0xf0107946
f0102f3c:	68 27 77 10 f0       	push   $0xf0107727
f0102f41:	68 e4 04 00 00       	push   $0x4e4
f0102f46:	68 01 77 10 f0       	push   $0xf0107701
f0102f4b:	e8 f0 d0 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102f50:	68 fc 6f 10 f0       	push   $0xf0106ffc
f0102f55:	68 27 77 10 f0       	push   $0xf0107727
f0102f5a:	68 e7 04 00 00       	push   $0x4e7
f0102f5f:	68 01 77 10 f0       	push   $0xf0107701
f0102f64:	e8 d7 d0 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0102f69:	68 fd 78 10 f0       	push   $0xf01078fd
f0102f6e:	68 27 77 10 f0       	push   $0xf0107727
f0102f73:	68 e9 04 00 00       	push   $0x4e9
f0102f78:	68 01 77 10 f0       	push   $0xf0107701
f0102f7d:	e8 be d0 ff ff       	call   f0100040 <_panic>

f0102f82 <user_mem_check>:
{
f0102f82:	f3 0f 1e fb          	endbr32 
f0102f86:	55                   	push   %ebp
f0102f87:	89 e5                	mov    %esp,%ebp
f0102f89:	57                   	push   %edi
f0102f8a:	56                   	push   %esi
f0102f8b:	53                   	push   %ebx
f0102f8c:	83 ec 2c             	sub    $0x2c,%esp
f0102f8f:	8b 45 0c             	mov    0xc(%ebp),%eax
	pde_t* pgdir = env->env_pgdir;
f0102f92:	8b 55 08             	mov    0x8(%ebp),%edx
f0102f95:	8b 7a 60             	mov    0x60(%edx),%edi
	uintptr_t address = (uintptr_t)ROUNDDOWN(va,PGSIZE);
f0102f98:	89 c3                	mov    %eax,%ebx
f0102f9a:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	perm = perm | PTE_U | PTE_P;
f0102fa0:	8b 55 14             	mov    0x14(%ebp),%edx
f0102fa3:	83 ca 05             	or     $0x5,%edx
f0102fa6:	89 55 d0             	mov    %edx,-0x30(%ebp)
	pte_t* entry = NULL;
f0102fa9:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	for(; address<(uintptr_t)ROUNDUP(va+len,PGSIZE);address+=PGSIZE)
f0102fb0:	03 45 10             	add    0x10(%ebp),%eax
f0102fb3:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102fb8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102fbd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		if(page_lookup(pgdir,(void*)address,&entry) == NULL)
f0102fc0:	8d 75 e4             	lea    -0x1c(%ebp),%esi
	for(; address<(uintptr_t)ROUNDUP(va+len,PGSIZE);address+=PGSIZE)
f0102fc3:	eb 06                	jmp    f0102fcb <user_mem_check+0x49>
f0102fc5:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102fcb:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0102fce:	73 31                	jae    f0103001 <user_mem_check+0x7f>
		if(address>=ULIM)
f0102fd0:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102fd6:	77 1c                	ja     f0102ff4 <user_mem_check+0x72>
		if(page_lookup(pgdir,(void*)address,&entry) == NULL)
f0102fd8:	83 ec 04             	sub    $0x4,%esp
f0102fdb:	56                   	push   %esi
f0102fdc:	53                   	push   %ebx
f0102fdd:	57                   	push   %edi
f0102fde:	e8 aa e1 ff ff       	call   f010118d <page_lookup>
f0102fe3:	83 c4 10             	add    $0x10,%esp
f0102fe6:	85 c0                	test   %eax,%eax
f0102fe8:	74 0a                	je     f0102ff4 <user_mem_check+0x72>
		if(!(*entry & perm))
f0102fea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102fed:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102ff0:	85 08                	test   %ecx,(%eax)
f0102ff2:	75 d1                	jne    f0102fc5 <user_mem_check+0x43>
		user_mem_check_addr = (address == (uintptr_t)va ? address : ROUNDDOWN(address,PGSIZE));
f0102ff4:	89 1d 3c 72 21 f0    	mov    %ebx,0xf021723c
		return -E_FAULT;
f0102ffa:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102fff:	eb 05                	jmp    f0103006 <user_mem_check+0x84>
	return 0;
f0103001:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103006:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103009:	5b                   	pop    %ebx
f010300a:	5e                   	pop    %esi
f010300b:	5f                   	pop    %edi
f010300c:	5d                   	pop    %ebp
f010300d:	c3                   	ret    

f010300e <user_mem_assert>:
{
f010300e:	f3 0f 1e fb          	endbr32 
f0103012:	55                   	push   %ebp
f0103013:	89 e5                	mov    %esp,%ebp
f0103015:	53                   	push   %ebx
f0103016:	83 ec 04             	sub    $0x4,%esp
f0103019:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f010301c:	8b 45 14             	mov    0x14(%ebp),%eax
f010301f:	83 c8 04             	or     $0x4,%eax
f0103022:	50                   	push   %eax
f0103023:	ff 75 10             	pushl  0x10(%ebp)
f0103026:	ff 75 0c             	pushl  0xc(%ebp)
f0103029:	53                   	push   %ebx
f010302a:	e8 53 ff ff ff       	call   f0102f82 <user_mem_check>
f010302f:	83 c4 10             	add    $0x10,%esp
f0103032:	85 c0                	test   %eax,%eax
f0103034:	78 05                	js     f010303b <user_mem_assert+0x2d>
}
f0103036:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103039:	c9                   	leave  
f010303a:	c3                   	ret    
		cprintf("[%08x] user_mem_check assertion failure for "
f010303b:	83 ec 04             	sub    $0x4,%esp
f010303e:	ff 35 3c 72 21 f0    	pushl  0xf021723c
f0103044:	ff 73 48             	pushl  0x48(%ebx)
f0103047:	68 cc 76 10 f0       	push   $0xf01076cc
f010304c:	e8 70 09 00 00       	call   f01039c1 <cprintf>
		env_destroy(env);	// may not return
f0103051:	89 1c 24             	mov    %ebx,(%esp)
f0103054:	e8 43 06 00 00       	call   f010369c <env_destroy>
f0103059:	83 c4 10             	add    $0x10,%esp
}
f010305c:	eb d8                	jmp    f0103036 <user_mem_assert+0x28>

f010305e <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f010305e:	55                   	push   %ebp
f010305f:	89 e5                	mov    %esp,%ebp
f0103061:	57                   	push   %edi
f0103062:	56                   	push   %esi
f0103063:	53                   	push   %ebx
f0103064:	83 ec 0c             	sub    $0xc,%esp
f0103067:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void* start = (void*)ROUNDDOWN((uint32_t)va,PGSIZE);
f0103069:	89 d3                	mov    %edx,%ebx
f010306b:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void* end = (void*)ROUNDUP((uint32_t)va+len,PGSIZE);
f0103071:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0103078:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

	// corner case 1: too large length
	if(start>end)
f010307e:	39 f3                	cmp    %esi,%ebx
f0103080:	77 30                	ja     f01030b2 <region_alloc+0x54>
		panic("At region_alloc: too large length\n");
	}
	struct PageInfo* p = NULL;

	// allocate PA by the size of a page
	for(void* v = start;v<end;v+=PGSIZE)
f0103082:	39 f3                	cmp    %esi,%ebx
f0103084:	73 71                	jae    f01030f7 <region_alloc+0x99>
	{
		p = page_alloc(0);
f0103086:	83 ec 0c             	sub    $0xc,%esp
f0103089:	6a 00                	push   $0x0
f010308b:	e8 3b df ff ff       	call   f0100fcb <page_alloc>
		// corner case 2: page allocation failed
		if(p == NULL)
f0103090:	83 c4 10             	add    $0x10,%esp
f0103093:	85 c0                	test   %eax,%eax
f0103095:	74 32                	je     f01030c9 <region_alloc+0x6b>
		{
			panic("At region_alloc: Page allocation failed");
		}

		// insert into page table
		int insert = page_insert(e->env_pgdir,p,v,PTE_W|PTE_U|PTE_P);
f0103097:	6a 07                	push   $0x7
f0103099:	53                   	push   %ebx
f010309a:	50                   	push   %eax
f010309b:	ff 77 60             	pushl  0x60(%edi)
f010309e:	e8 dd e1 ff ff       	call   f0101280 <page_insert>

		// corner case 3: insertion failed
		if(insert!=0)
f01030a3:	83 c4 10             	add    $0x10,%esp
f01030a6:	85 c0                	test   %eax,%eax
f01030a8:	75 36                	jne    f01030e0 <region_alloc+0x82>
	for(void* v = start;v<end;v+=PGSIZE)
f01030aa:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01030b0:	eb d0                	jmp    f0103082 <region_alloc+0x24>
		panic("At region_alloc: too large length\n");
f01030b2:	83 ec 04             	sub    $0x4,%esp
f01030b5:	68 14 7a 10 f0       	push   $0xf0107a14
f01030ba:	68 37 01 00 00       	push   $0x137
f01030bf:	68 09 7b 10 f0       	push   $0xf0107b09
f01030c4:	e8 77 cf ff ff       	call   f0100040 <_panic>
			panic("At region_alloc: Page allocation failed");
f01030c9:	83 ec 04             	sub    $0x4,%esp
f01030cc:	68 38 7a 10 f0       	push   $0xf0107a38
f01030d1:	68 42 01 00 00       	push   $0x142
f01030d6:	68 09 7b 10 f0       	push   $0xf0107b09
f01030db:	e8 60 cf ff ff       	call   f0100040 <_panic>
		{
			panic("At region_alloc: Page insertion failed");
f01030e0:	83 ec 04             	sub    $0x4,%esp
f01030e3:	68 60 7a 10 f0       	push   $0xf0107a60
f01030e8:	68 4b 01 00 00       	push   $0x14b
f01030ed:	68 09 7b 10 f0       	push   $0xf0107b09
f01030f2:	e8 49 cf ff ff       	call   f0100040 <_panic>
		}
	}
}
f01030f7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030fa:	5b                   	pop    %ebx
f01030fb:	5e                   	pop    %esi
f01030fc:	5f                   	pop    %edi
f01030fd:	5d                   	pop    %ebp
f01030fe:	c3                   	ret    

f01030ff <envid2env>:
{
f01030ff:	f3 0f 1e fb          	endbr32 
f0103103:	55                   	push   %ebp
f0103104:	89 e5                	mov    %esp,%ebp
f0103106:	56                   	push   %esi
f0103107:	53                   	push   %ebx
f0103108:	8b 75 08             	mov    0x8(%ebp),%esi
f010310b:	8b 45 10             	mov    0x10(%ebp),%eax
	if (envid == 0) {
f010310e:	85 f6                	test   %esi,%esi
f0103110:	74 2e                	je     f0103140 <envid2env+0x41>
	e = &envs[ENVX(envid)];
f0103112:	89 f3                	mov    %esi,%ebx
f0103114:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f010311a:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f010311d:	03 1d 48 72 21 f0    	add    0xf0217248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103123:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0103127:	74 2e                	je     f0103157 <envid2env+0x58>
f0103129:	39 73 48             	cmp    %esi,0x48(%ebx)
f010312c:	75 29                	jne    f0103157 <envid2env+0x58>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010312e:	84 c0                	test   %al,%al
f0103130:	75 35                	jne    f0103167 <envid2env+0x68>
	*env_store = e;
f0103132:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103135:	89 18                	mov    %ebx,(%eax)
	return 0;
f0103137:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010313c:	5b                   	pop    %ebx
f010313d:	5e                   	pop    %esi
f010313e:	5d                   	pop    %ebp
f010313f:	c3                   	ret    
		*env_store = curenv;
f0103140:	e8 e9 2f 00 00       	call   f010612e <cpunum>
f0103145:	6b c0 74             	imul   $0x74,%eax,%eax
f0103148:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f010314e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103151:	89 02                	mov    %eax,(%edx)
		return 0;
f0103153:	89 f0                	mov    %esi,%eax
f0103155:	eb e5                	jmp    f010313c <envid2env+0x3d>
		*env_store = 0;
f0103157:	8b 45 0c             	mov    0xc(%ebp),%eax
f010315a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103160:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103165:	eb d5                	jmp    f010313c <envid2env+0x3d>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103167:	e8 c2 2f 00 00       	call   f010612e <cpunum>
f010316c:	6b c0 74             	imul   $0x74,%eax,%eax
f010316f:	39 98 28 80 21 f0    	cmp    %ebx,-0xfde7fd8(%eax)
f0103175:	74 bb                	je     f0103132 <envid2env+0x33>
f0103177:	8b 73 4c             	mov    0x4c(%ebx),%esi
f010317a:	e8 af 2f 00 00       	call   f010612e <cpunum>
f010317f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103182:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0103188:	3b 70 48             	cmp    0x48(%eax),%esi
f010318b:	74 a5                	je     f0103132 <envid2env+0x33>
		*env_store = 0;
f010318d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103190:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103196:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010319b:	eb 9f                	jmp    f010313c <envid2env+0x3d>

f010319d <env_init_percpu>:
{
f010319d:	f3 0f 1e fb          	endbr32 
	asm volatile("lgdt (%0)" : : "r" (p));
f01031a1:	b8 20 33 12 f0       	mov    $0xf0123320,%eax
f01031a6:	0f 01 10             	lgdtl  (%eax)
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f01031a9:	b8 23 00 00 00       	mov    $0x23,%eax
f01031ae:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f01031b0:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f01031b2:	b8 10 00 00 00       	mov    $0x10,%eax
f01031b7:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f01031b9:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f01031bb:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f01031bd:	ea c4 31 10 f0 08 00 	ljmp   $0x8,$0xf01031c4
	asm volatile("lldt %0" : : "r" (sel));
f01031c4:	b8 00 00 00 00       	mov    $0x0,%eax
f01031c9:	0f 00 d0             	lldt   %ax
}
f01031cc:	c3                   	ret    

f01031cd <env_init>:
{
f01031cd:	f3 0f 1e fb          	endbr32 
f01031d1:	55                   	push   %ebp
f01031d2:	89 e5                	mov    %esp,%ebp
f01031d4:	56                   	push   %esi
f01031d5:	53                   	push   %ebx
		envs[i].env_id = 0;
f01031d6:	8b 35 48 72 21 f0    	mov    0xf0217248,%esi
f01031dc:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f01031e2:	89 f3                	mov    %esi,%ebx
f01031e4:	ba 00 00 00 00       	mov    $0x0,%edx
f01031e9:	89 d1                	mov    %edx,%ecx
f01031eb:	89 c2                	mov    %eax,%edx
f01031ed:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f01031f4:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f01031fb:	89 48 44             	mov    %ecx,0x44(%eax)
f01031fe:	83 e8 7c             	sub    $0x7c,%eax
	for(int i = NENV - 1; i>=0 ;i--)
f0103201:	39 da                	cmp    %ebx,%edx
f0103203:	75 e4                	jne    f01031e9 <env_init+0x1c>
f0103205:	89 35 4c 72 21 f0    	mov    %esi,0xf021724c
	env_init_percpu();
f010320b:	e8 8d ff ff ff       	call   f010319d <env_init_percpu>
}
f0103210:	5b                   	pop    %ebx
f0103211:	5e                   	pop    %esi
f0103212:	5d                   	pop    %ebp
f0103213:	c3                   	ret    

f0103214 <env_alloc>:
{
f0103214:	f3 0f 1e fb          	endbr32 
f0103218:	55                   	push   %ebp
f0103219:	89 e5                	mov    %esp,%ebp
f010321b:	53                   	push   %ebx
f010321c:	83 ec 04             	sub    $0x4,%esp
	if (!(e = env_free_list))
f010321f:	8b 1d 4c 72 21 f0    	mov    0xf021724c,%ebx
f0103225:	85 db                	test   %ebx,%ebx
f0103227:	0f 84 59 01 00 00    	je     f0103386 <env_alloc+0x172>
	if (!(p = page_alloc(ALLOC_ZERO)))
f010322d:	83 ec 0c             	sub    $0xc,%esp
f0103230:	6a 01                	push   $0x1
f0103232:	e8 94 dd ff ff       	call   f0100fcb <page_alloc>
f0103237:	83 c4 10             	add    $0x10,%esp
f010323a:	85 c0                	test   %eax,%eax
f010323c:	0f 84 4b 01 00 00    	je     f010338d <env_alloc+0x179>
	return (pp - pages) << PGSHIFT;
f0103242:	89 c2                	mov    %eax,%edx
f0103244:	2b 15 90 7e 21 f0    	sub    0xf0217e90,%edx
f010324a:	c1 fa 03             	sar    $0x3,%edx
f010324d:	89 d1                	mov    %edx,%ecx
f010324f:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f0103252:	81 e2 ff ff 0f 00    	and    $0xfffff,%edx
f0103258:	3b 15 88 7e 21 f0    	cmp    0xf0217e88,%edx
f010325e:	0f 83 fb 00 00 00    	jae    f010335f <env_alloc+0x14b>
	return (void *)(pa + KERNBASE);
f0103264:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f010326a:	89 4b 60             	mov    %ecx,0x60(%ebx)
	p->pp_ref++;
f010326d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f0103272:	b8 00 00 00 00       	mov    $0x0,%eax
		e->env_pgdir[i] = 0;
f0103277:	8b 53 60             	mov    0x60(%ebx),%edx
f010327a:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f0103281:	83 c0 04             	add    $0x4,%eax
	for(int i = 0;i<PDX(UTOP);i++)
f0103284:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f0103289:	75 ec                	jne    f0103277 <env_alloc+0x63>
		e->env_pgdir[i] = kern_pgdir[i];
f010328b:	8b 15 8c 7e 21 f0    	mov    0xf0217e8c,%edx
f0103291:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0103294:	8b 53 60             	mov    0x60(%ebx),%edx
f0103297:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f010329a:	83 c0 04             	add    $0x4,%eax
	for(int i = PDX(UTOP);i<NENV;i++)
f010329d:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01032a2:	75 e7                	jne    f010328b <env_alloc+0x77>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01032a4:	8b 43 60             	mov    0x60(%ebx),%eax
	if ((uint32_t)kva < KERNBASE)
f01032a7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01032ac:	0f 86 bf 00 00 00    	jbe    f0103371 <env_alloc+0x15d>
	return (physaddr_t)kva - KERNBASE;
f01032b2:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01032b8:	83 ca 05             	or     $0x5,%edx
f01032bb:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01032c1:	8b 43 48             	mov    0x48(%ebx),%eax
f01032c4:	05 00 10 00 00       	add    $0x1000,%eax
		generation = 1 << ENVGENSHIFT;
f01032c9:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01032ce:	ba 00 10 00 00       	mov    $0x1000,%edx
f01032d3:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01032d6:	89 da                	mov    %ebx,%edx
f01032d8:	2b 15 48 72 21 f0    	sub    0xf0217248,%edx
f01032de:	c1 fa 02             	sar    $0x2,%edx
f01032e1:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f01032e7:	09 d0                	or     %edx,%eax
f01032e9:	89 43 48             	mov    %eax,0x48(%ebx)
	e->env_parent_id = parent_id;
f01032ec:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032ef:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01032f2:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01032f9:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103300:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103307:	83 ec 04             	sub    $0x4,%esp
f010330a:	6a 44                	push   $0x44
f010330c:	6a 00                	push   $0x0
f010330e:	53                   	push   %ebx
f010330f:	e8 fc 27 00 00       	call   f0105b10 <memset>
	e->env_tf.tf_ds = GD_UD | 3;
f0103314:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f010331a:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103320:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103326:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f010332d:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	e->env_tf.tf_eflags |= FL_IF;
f0103333:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)
	e->env_pgfault_upcall = 0;
f010333a:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)
	e->env_ipc_recving = 0;
f0103341:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
	env_free_list = e->env_link;
f0103345:	8b 43 44             	mov    0x44(%ebx),%eax
f0103348:	a3 4c 72 21 f0       	mov    %eax,0xf021724c
	*newenv_store = e;
f010334d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103350:	89 18                	mov    %ebx,(%eax)
	return 0;
f0103352:	83 c4 10             	add    $0x10,%esp
f0103355:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010335a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010335d:	c9                   	leave  
f010335e:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010335f:	51                   	push   %ecx
f0103360:	68 c4 67 10 f0       	push   $0xf01067c4
f0103365:	6a 58                	push   $0x58
f0103367:	68 0d 77 10 f0       	push   $0xf010770d
f010336c:	e8 cf cc ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103371:	50                   	push   %eax
f0103372:	68 e8 67 10 f0       	push   $0xf01067e8
f0103377:	68 d3 00 00 00       	push   $0xd3
f010337c:	68 09 7b 10 f0       	push   $0xf0107b09
f0103381:	e8 ba cc ff ff       	call   f0100040 <_panic>
		return -E_NO_FREE_ENV;
f0103386:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010338b:	eb cd                	jmp    f010335a <env_alloc+0x146>
		return -E_NO_MEM;
f010338d:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0103392:	eb c6                	jmp    f010335a <env_alloc+0x146>

f0103394 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103394:	f3 0f 1e fb          	endbr32 
f0103398:	55                   	push   %ebp
f0103399:	89 e5                	mov    %esp,%ebp
f010339b:	57                   	push   %edi
f010339c:	56                   	push   %esi
f010339d:	53                   	push   %ebx
f010339e:	83 ec 34             	sub    $0x34,%esp
f01033a1:	8b 75 08             	mov    0x8(%ebp),%esi
	// LAB 3: Your code here.
	struct Env* e;
	int alloc = env_alloc(&e,0);
f01033a4:	6a 00                	push   $0x0
f01033a6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01033a9:	50                   	push   %eax
f01033aa:	e8 65 fe ff ff       	call   f0103214 <env_alloc>
	if(alloc != 0)
f01033af:	83 c4 10             	add    $0x10,%esp
f01033b2:	85 c0                	test   %eax,%eax
f01033b4:	75 30                	jne    f01033e6 <env_create+0x52>
	{
		panic("At env_create: env_alloc() failed");
	}
	load_icode(e,binary);
f01033b6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
	if(elfHeader->e_magic != ELF_MAGIC)
f01033b9:	81 3e 7f 45 4c 46    	cmpl   $0x464c457f,(%esi)
f01033bf:	75 3c                	jne    f01033fd <env_create+0x69>
	lcr3(PADDR(e->env_pgdir));
f01033c1:	8b 47 60             	mov    0x60(%edi),%eax
	if ((uint32_t)kva < KERNBASE)
f01033c4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033c9:	76 49                	jbe    f0103414 <env_create+0x80>
	return (physaddr_t)kva - KERNBASE;
f01033cb:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01033d0:	0f 22 d8             	mov    %eax,%cr3
	struct Proghdr* ph = (struct Proghdr*)(binary+elfHeader->e_phoff);
f01033d3:	89 f3                	mov    %esi,%ebx
f01033d5:	03 5e 1c             	add    0x1c(%esi),%ebx
	struct Proghdr* phEnd = ph+elfHeader->e_phnum;
f01033d8:	0f b7 46 2c          	movzwl 0x2c(%esi),%eax
f01033dc:	c1 e0 05             	shl    $0x5,%eax
f01033df:	01 d8                	add    %ebx,%eax
f01033e1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for(;ph<phEnd;ph++)
f01033e4:	eb 5d                	jmp    f0103443 <env_create+0xaf>
		panic("At env_create: env_alloc() failed");
f01033e6:	83 ec 04             	sub    $0x4,%esp
f01033e9:	68 88 7a 10 f0       	push   $0xf0107a88
f01033ee:	68 c5 01 00 00       	push   $0x1c5
f01033f3:	68 09 7b 10 f0       	push   $0xf0107b09
f01033f8:	e8 43 cc ff ff       	call   f0100040 <_panic>
		panic("At load_icode: Invalid head magic number");
f01033fd:	83 ec 04             	sub    $0x4,%esp
f0103400:	68 ac 7a 10 f0       	push   $0xf0107aac
f0103405:	68 8c 01 00 00       	push   $0x18c
f010340a:	68 09 7b 10 f0       	push   $0xf0107b09
f010340f:	e8 2c cc ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103414:	50                   	push   %eax
f0103415:	68 e8 67 10 f0       	push   $0xf01067e8
f010341a:	68 8f 01 00 00       	push   $0x18f
f010341f:	68 09 7b 10 f0       	push   $0xf0107b09
f0103424:	e8 17 cc ff ff       	call   f0100040 <_panic>
				panic("At load_icode: file size bigger than memory size");
f0103429:	83 ec 04             	sub    $0x4,%esp
f010342c:	68 d8 7a 10 f0       	push   $0xf0107ad8
f0103431:	68 9b 01 00 00       	push   $0x19b
f0103436:	68 09 7b 10 f0       	push   $0xf0107b09
f010343b:	e8 00 cc ff ff       	call   f0100040 <_panic>
	for(;ph<phEnd;ph++)
f0103440:	83 c3 20             	add    $0x20,%ebx
f0103443:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0103446:	76 40                	jbe    f0103488 <env_create+0xf4>
		if(ph->p_type == ELF_PROG_LOAD)
f0103448:	83 3b 01             	cmpl   $0x1,(%ebx)
f010344b:	75 f3                	jne    f0103440 <env_create+0xac>
			if(ph->p_filesz>ph->p_memsz)
f010344d:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103450:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f0103453:	77 d4                	ja     f0103429 <env_create+0x95>
			region_alloc(e,(void*) ph->p_va,ph->p_memsz);
f0103455:	8b 53 08             	mov    0x8(%ebx),%edx
f0103458:	89 f8                	mov    %edi,%eax
f010345a:	e8 ff fb ff ff       	call   f010305e <region_alloc>
			memset((void*)(ph->p_va),0,ph->p_memsz);
f010345f:	83 ec 04             	sub    $0x4,%esp
f0103462:	ff 73 14             	pushl  0x14(%ebx)
f0103465:	6a 00                	push   $0x0
f0103467:	ff 73 08             	pushl  0x8(%ebx)
f010346a:	e8 a1 26 00 00       	call   f0105b10 <memset>
			memcpy((void*)ph->p_va,binary+ph->p_offset,ph->p_filesz); 
f010346f:	83 c4 0c             	add    $0xc,%esp
f0103472:	ff 73 10             	pushl  0x10(%ebx)
f0103475:	89 f0                	mov    %esi,%eax
f0103477:	03 43 04             	add    0x4(%ebx),%eax
f010347a:	50                   	push   %eax
f010347b:	ff 73 08             	pushl  0x8(%ebx)
f010347e:	e8 3f 27 00 00       	call   f0105bc2 <memcpy>
f0103483:	83 c4 10             	add    $0x10,%esp
f0103486:	eb b8                	jmp    f0103440 <env_create+0xac>
	lcr3(PADDR(kern_pgdir));
f0103488:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f010348d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103492:	76 3c                	jbe    f01034d0 <env_create+0x13c>
	return (physaddr_t)kva - KERNBASE;
f0103494:	05 00 00 00 10       	add    $0x10000000,%eax
f0103499:	0f 22 d8             	mov    %eax,%cr3
	e->env_status = ENV_RUNNABLE;
f010349c:	c7 47 54 02 00 00 00 	movl   $0x2,0x54(%edi)
	e->env_tf.tf_eip = elfHeader->e_entry;
f01034a3:	8b 46 18             	mov    0x18(%esi),%eax
f01034a6:	89 47 30             	mov    %eax,0x30(%edi)
	region_alloc(e,(void*)(USTACKTOP-PGSIZE),PGSIZE);
f01034a9:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01034ae:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01034b3:	89 f8                	mov    %edi,%eax
f01034b5:	e8 a4 fb ff ff       	call   f010305e <region_alloc>
	
	// If this is the file server (type == ENV_TYPE_FS) give it I/O privileges.
	// LAB 5: Your code here.
	e->env_type = type;
f01034ba:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01034bd:	8b 55 0c             	mov    0xc(%ebp),%edx
f01034c0:	89 50 50             	mov    %edx,0x50(%eax)
	if(type == ENV_TYPE_FS)
f01034c3:	83 fa 01             	cmp    $0x1,%edx
f01034c6:	74 1d                	je     f01034e5 <env_create+0x151>
	{
		e->env_tf.tf_eflags |= FL_IOPL_MASK;
	}
}
f01034c8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01034cb:	5b                   	pop    %ebx
f01034cc:	5e                   	pop    %esi
f01034cd:	5f                   	pop    %edi
f01034ce:	5d                   	pop    %ebp
f01034cf:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034d0:	50                   	push   %eax
f01034d1:	68 e8 67 10 f0       	push   $0xf01067e8
f01034d6:	68 a9 01 00 00       	push   $0x1a9
f01034db:	68 09 7b 10 f0       	push   $0xf0107b09
f01034e0:	e8 5b cb ff ff       	call   f0100040 <_panic>
		e->env_tf.tf_eflags |= FL_IOPL_MASK;
f01034e5:	81 48 38 00 30 00 00 	orl    $0x3000,0x38(%eax)
}
f01034ec:	eb da                	jmp    f01034c8 <env_create+0x134>

f01034ee <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01034ee:	f3 0f 1e fb          	endbr32 
f01034f2:	55                   	push   %ebp
f01034f3:	89 e5                	mov    %esp,%ebp
f01034f5:	57                   	push   %edi
f01034f6:	56                   	push   %esi
f01034f7:	53                   	push   %ebx
f01034f8:	83 ec 1c             	sub    $0x1c,%esp
f01034fb:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01034fe:	e8 2b 2c 00 00       	call   f010612e <cpunum>
f0103503:	6b c0 74             	imul   $0x74,%eax,%eax
f0103506:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010350d:	39 b8 28 80 21 f0    	cmp    %edi,-0xfde7fd8(%eax)
f0103513:	0f 85 b3 00 00 00    	jne    f01035cc <env_free+0xde>
		lcr3(PADDR(kern_pgdir));
f0103519:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f010351e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103523:	76 14                	jbe    f0103539 <env_free+0x4b>
	return (physaddr_t)kva - KERNBASE;
f0103525:	05 00 00 00 10       	add    $0x10000000,%eax
f010352a:	0f 22 d8             	mov    %eax,%cr3
}
f010352d:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103534:	e9 93 00 00 00       	jmp    f01035cc <env_free+0xde>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103539:	50                   	push   %eax
f010353a:	68 e8 67 10 f0       	push   $0xf01067e8
f010353f:	68 e0 01 00 00       	push   $0x1e0
f0103544:	68 09 7b 10 f0       	push   $0xf0107b09
f0103549:	e8 f2 ca ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010354e:	56                   	push   %esi
f010354f:	68 c4 67 10 f0       	push   $0xf01067c4
f0103554:	68 ef 01 00 00       	push   $0x1ef
f0103559:	68 09 7b 10 f0       	push   $0xf0107b09
f010355e:	e8 dd ca ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103563:	83 ec 08             	sub    $0x8,%esp
f0103566:	89 d8                	mov    %ebx,%eax
f0103568:	c1 e0 0c             	shl    $0xc,%eax
f010356b:	0b 45 e4             	or     -0x1c(%ebp),%eax
f010356e:	50                   	push   %eax
f010356f:	ff 77 60             	pushl  0x60(%edi)
f0103572:	e8 b8 dc ff ff       	call   f010122f <page_remove>
f0103577:	83 c4 10             	add    $0x10,%esp
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010357a:	83 c3 01             	add    $0x1,%ebx
f010357d:	83 c6 04             	add    $0x4,%esi
f0103580:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103586:	74 07                	je     f010358f <env_free+0xa1>
			if (pt[pteno] & PTE_P)
f0103588:	f6 06 01             	testb  $0x1,(%esi)
f010358b:	74 ed                	je     f010357a <env_free+0x8c>
f010358d:	eb d4                	jmp    f0103563 <env_free+0x75>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f010358f:	8b 47 60             	mov    0x60(%edi),%eax
f0103592:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103595:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f010359c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010359f:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f01035a5:	73 65                	jae    f010360c <env_free+0x11e>
		page_decref(pa2page(pa));
f01035a7:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01035aa:	a1 90 7e 21 f0       	mov    0xf0217e90,%eax
f01035af:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01035b2:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01035b5:	50                   	push   %eax
f01035b6:	e8 c8 da ff ff       	call   f0101083 <page_decref>
f01035bb:	83 c4 10             	add    $0x10,%esp
f01035be:	83 45 e0 04          	addl   $0x4,-0x20(%ebp)
f01035c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01035c5:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f01035ca:	74 54                	je     f0103620 <env_free+0x132>
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01035cc:	8b 47 60             	mov    0x60(%edi),%eax
f01035cf:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01035d2:	8b 04 10             	mov    (%eax,%edx,1),%eax
f01035d5:	a8 01                	test   $0x1,%al
f01035d7:	74 e5                	je     f01035be <env_free+0xd0>
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01035d9:	89 c6                	mov    %eax,%esi
f01035db:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	if (PGNUM(pa) >= npages)
f01035e1:	c1 e8 0c             	shr    $0xc,%eax
f01035e4:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01035e7:	39 05 88 7e 21 f0    	cmp    %eax,0xf0217e88
f01035ed:	0f 86 5b ff ff ff    	jbe    f010354e <env_free+0x60>
	return (void *)(pa + KERNBASE);
f01035f3:	81 ee 00 00 00 10    	sub    $0x10000000,%esi
f01035f9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01035fc:	c1 e0 14             	shl    $0x14,%eax
f01035ff:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103602:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103607:	e9 7c ff ff ff       	jmp    f0103588 <env_free+0x9a>
		panic("pa2page called with invalid pa");
f010360c:	83 ec 04             	sub    $0x4,%esp
f010360f:	68 9c 6e 10 f0       	push   $0xf0106e9c
f0103614:	6a 51                	push   $0x51
f0103616:	68 0d 77 10 f0       	push   $0xf010770d
f010361b:	e8 20 ca ff ff       	call   f0100040 <_panic>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103620:	8b 47 60             	mov    0x60(%edi),%eax
	if ((uint32_t)kva < KERNBASE)
f0103623:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103628:	76 49                	jbe    f0103673 <env_free+0x185>
	e->env_pgdir = 0;
f010362a:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103631:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f0103636:	c1 e8 0c             	shr    $0xc,%eax
f0103639:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f010363f:	73 47                	jae    f0103688 <env_free+0x19a>
	page_decref(pa2page(pa));
f0103641:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103644:	8b 15 90 7e 21 f0    	mov    0xf0217e90,%edx
f010364a:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010364d:	50                   	push   %eax
f010364e:	e8 30 da ff ff       	call   f0101083 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103653:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f010365a:	a1 4c 72 21 f0       	mov    0xf021724c,%eax
f010365f:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103662:	89 3d 4c 72 21 f0    	mov    %edi,0xf021724c
}
f0103668:	83 c4 10             	add    $0x10,%esp
f010366b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010366e:	5b                   	pop    %ebx
f010366f:	5e                   	pop    %esi
f0103670:	5f                   	pop    %edi
f0103671:	5d                   	pop    %ebp
f0103672:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103673:	50                   	push   %eax
f0103674:	68 e8 67 10 f0       	push   $0xf01067e8
f0103679:	68 fd 01 00 00       	push   $0x1fd
f010367e:	68 09 7b 10 f0       	push   $0xf0107b09
f0103683:	e8 b8 c9 ff ff       	call   f0100040 <_panic>
		panic("pa2page called with invalid pa");
f0103688:	83 ec 04             	sub    $0x4,%esp
f010368b:	68 9c 6e 10 f0       	push   $0xf0106e9c
f0103690:	6a 51                	push   $0x51
f0103692:	68 0d 77 10 f0       	push   $0xf010770d
f0103697:	e8 a4 c9 ff ff       	call   f0100040 <_panic>

f010369c <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f010369c:	f3 0f 1e fb          	endbr32 
f01036a0:	55                   	push   %ebp
f01036a1:	89 e5                	mov    %esp,%ebp
f01036a3:	53                   	push   %ebx
f01036a4:	83 ec 04             	sub    $0x4,%esp
f01036a7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01036aa:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f01036ae:	74 21                	je     f01036d1 <env_destroy+0x35>
		e->env_status = ENV_DYING;
		return;
	}

	env_free(e);
f01036b0:	83 ec 0c             	sub    $0xc,%esp
f01036b3:	53                   	push   %ebx
f01036b4:	e8 35 fe ff ff       	call   f01034ee <env_free>

	if (curenv == e) {
f01036b9:	e8 70 2a 00 00       	call   f010612e <cpunum>
f01036be:	6b c0 74             	imul   $0x74,%eax,%eax
f01036c1:	83 c4 10             	add    $0x10,%esp
f01036c4:	39 98 28 80 21 f0    	cmp    %ebx,-0xfde7fd8(%eax)
f01036ca:	74 1e                	je     f01036ea <env_destroy+0x4e>
		curenv = NULL;
		sched_yield();
	}
}
f01036cc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01036cf:	c9                   	leave  
f01036d0:	c3                   	ret    
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01036d1:	e8 58 2a 00 00       	call   f010612e <cpunum>
f01036d6:	6b c0 74             	imul   $0x74,%eax,%eax
f01036d9:	39 98 28 80 21 f0    	cmp    %ebx,-0xfde7fd8(%eax)
f01036df:	74 cf                	je     f01036b0 <env_destroy+0x14>
		e->env_status = ENV_DYING;
f01036e1:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01036e8:	eb e2                	jmp    f01036cc <env_destroy+0x30>
		curenv = NULL;
f01036ea:	e8 3f 2a 00 00       	call   f010612e <cpunum>
f01036ef:	6b c0 74             	imul   $0x74,%eax,%eax
f01036f2:	c7 80 28 80 21 f0 00 	movl   $0x0,-0xfde7fd8(%eax)
f01036f9:	00 00 00 
		sched_yield();
f01036fc:	e8 62 11 00 00       	call   f0104863 <sched_yield>

f0103701 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103701:	f3 0f 1e fb          	endbr32 
f0103705:	55                   	push   %ebp
f0103706:	89 e5                	mov    %esp,%ebp
f0103708:	53                   	push   %ebx
f0103709:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f010370c:	e8 1d 2a 00 00       	call   f010612e <cpunum>
f0103711:	6b c0 74             	imul   $0x74,%eax,%eax
f0103714:	8b 98 28 80 21 f0    	mov    -0xfde7fd8(%eax),%ebx
f010371a:	e8 0f 2a 00 00       	call   f010612e <cpunum>
f010371f:	89 43 5c             	mov    %eax,0x5c(%ebx)
	asm volatile(
f0103722:	8b 65 08             	mov    0x8(%ebp),%esp
f0103725:	61                   	popa   
f0103726:	07                   	pop    %es
f0103727:	1f                   	pop    %ds
f0103728:	83 c4 08             	add    $0x8,%esp
f010372b:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f010372c:	83 ec 04             	sub    $0x4,%esp
f010372f:	68 14 7b 10 f0       	push   $0xf0107b14
f0103734:	68 2f 02 00 00       	push   $0x22f
f0103739:	68 09 7b 10 f0       	push   $0xf0107b09
f010373e:	e8 fd c8 ff ff       	call   f0100040 <_panic>

f0103743 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103743:	f3 0f 1e fb          	endbr32 
f0103747:	55                   	push   %ebp
f0103748:	89 e5                	mov    %esp,%ebp
f010374a:	83 ec 08             	sub    $0x8,%esp
	
	// panic("env_run not yet implemented");

	// step 1
	// set the env_status field
	if(curenv)
f010374d:	e8 dc 29 00 00       	call   f010612e <cpunum>
f0103752:	6b c0 74             	imul   $0x74,%eax,%eax
f0103755:	83 b8 28 80 21 f0 00 	cmpl   $0x0,-0xfde7fd8(%eax)
f010375c:	74 14                	je     f0103772 <env_run+0x2f>
	{
		if(curenv->env_status == ENV_RUNNING)
f010375e:	e8 cb 29 00 00       	call   f010612e <cpunum>
f0103763:	6b c0 74             	imul   $0x74,%eax,%eax
f0103766:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f010376c:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103770:	74 7d                	je     f01037ef <env_run+0xac>
			curenv->env_status = ENV_RUNNABLE;
		}
	}

	// switch to new environment
	curenv = e;
f0103772:	e8 b7 29 00 00       	call   f010612e <cpunum>
f0103777:	6b c0 74             	imul   $0x74,%eax,%eax
f010377a:	8b 55 08             	mov    0x8(%ebp),%edx
f010377d:	89 90 28 80 21 f0    	mov    %edx,-0xfde7fd8(%eax)
	curenv->env_status = ENV_RUNNING;
f0103783:	e8 a6 29 00 00       	call   f010612e <cpunum>
f0103788:	6b c0 74             	imul   $0x74,%eax,%eax
f010378b:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0103791:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0103798:	e8 91 29 00 00       	call   f010612e <cpunum>
f010379d:	6b c0 74             	imul   $0x74,%eax,%eax
f01037a0:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01037a6:	83 40 58 01          	addl   $0x1,0x58(%eax)
	// switch to user page directory
	lcr3(PADDR(curenv->env_pgdir));
f01037aa:	e8 7f 29 00 00       	call   f010612e <cpunum>
f01037af:	6b c0 74             	imul   $0x74,%eax,%eax
f01037b2:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01037b8:	8b 40 60             	mov    0x60(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01037bb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01037c0:	76 47                	jbe    f0103809 <env_run+0xc6>
	return (physaddr_t)kva - KERNBASE;
f01037c2:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01037c7:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01037ca:	83 ec 0c             	sub    $0xc,%esp
f01037cd:	68 c0 33 12 f0       	push   $0xf01233c0
f01037d2:	e8 7d 2c 00 00       	call   f0106454 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01037d7:	f3 90                	pause  
	unlock_kernel();
	// step 2
	env_pop_tf(&curenv->env_tf);
f01037d9:	e8 50 29 00 00       	call   f010612e <cpunum>
f01037de:	83 c4 04             	add    $0x4,%esp
f01037e1:	6b c0 74             	imul   $0x74,%eax,%eax
f01037e4:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f01037ea:	e8 12 ff ff ff       	call   f0103701 <env_pop_tf>
			curenv->env_status = ENV_RUNNABLE;
f01037ef:	e8 3a 29 00 00       	call   f010612e <cpunum>
f01037f4:	6b c0 74             	imul   $0x74,%eax,%eax
f01037f7:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01037fd:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
f0103804:	e9 69 ff ff ff       	jmp    f0103772 <env_run+0x2f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103809:	50                   	push   %eax
f010380a:	68 e8 67 10 f0       	push   $0xf01067e8
f010380f:	68 5f 02 00 00       	push   $0x25f
f0103814:	68 09 7b 10 f0       	push   $0xf0107b09
f0103819:	e8 22 c8 ff ff       	call   f0100040 <_panic>

f010381e <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010381e:	f3 0f 1e fb          	endbr32 
f0103822:	55                   	push   %ebp
f0103823:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103825:	8b 45 08             	mov    0x8(%ebp),%eax
f0103828:	ba 70 00 00 00       	mov    $0x70,%edx
f010382d:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010382e:	ba 71 00 00 00       	mov    $0x71,%edx
f0103833:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103834:	0f b6 c0             	movzbl %al,%eax
}
f0103837:	5d                   	pop    %ebp
f0103838:	c3                   	ret    

f0103839 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103839:	f3 0f 1e fb          	endbr32 
f010383d:	55                   	push   %ebp
f010383e:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103840:	8b 45 08             	mov    0x8(%ebp),%eax
f0103843:	ba 70 00 00 00       	mov    $0x70,%edx
f0103848:	ee                   	out    %al,(%dx)
f0103849:	8b 45 0c             	mov    0xc(%ebp),%eax
f010384c:	ba 71 00 00 00       	mov    $0x71,%edx
f0103851:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103852:	5d                   	pop    %ebp
f0103853:	c3                   	ret    

f0103854 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103854:	f3 0f 1e fb          	endbr32 
f0103858:	55                   	push   %ebp
f0103859:	89 e5                	mov    %esp,%ebp
f010385b:	56                   	push   %esi
f010385c:	53                   	push   %ebx
f010385d:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103860:	66 a3 a8 33 12 f0    	mov    %ax,0xf01233a8
	if (!didinit)
f0103866:	80 3d 50 72 21 f0 00 	cmpb   $0x0,0xf0217250
f010386d:	75 07                	jne    f0103876 <irq_setmask_8259A+0x22>
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
}
f010386f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103872:	5b                   	pop    %ebx
f0103873:	5e                   	pop    %esi
f0103874:	5d                   	pop    %ebp
f0103875:	c3                   	ret    
f0103876:	89 c6                	mov    %eax,%esi
f0103878:	ba 21 00 00 00       	mov    $0x21,%edx
f010387d:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
f010387e:	66 c1 e8 08          	shr    $0x8,%ax
f0103882:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103887:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0103888:	83 ec 0c             	sub    $0xc,%esp
f010388b:	68 20 7b 10 f0       	push   $0xf0107b20
f0103890:	e8 2c 01 00 00       	call   f01039c1 <cprintf>
f0103895:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0103898:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f010389d:	0f b7 f6             	movzwl %si,%esi
f01038a0:	f7 d6                	not    %esi
f01038a2:	eb 19                	jmp    f01038bd <irq_setmask_8259A+0x69>
			cprintf(" %d", i);
f01038a4:	83 ec 08             	sub    $0x8,%esp
f01038a7:	53                   	push   %ebx
f01038a8:	68 af 80 10 f0       	push   $0xf01080af
f01038ad:	e8 0f 01 00 00       	call   f01039c1 <cprintf>
f01038b2:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f01038b5:	83 c3 01             	add    $0x1,%ebx
f01038b8:	83 fb 10             	cmp    $0x10,%ebx
f01038bb:	74 07                	je     f01038c4 <irq_setmask_8259A+0x70>
		if (~mask & (1<<i))
f01038bd:	0f a3 de             	bt     %ebx,%esi
f01038c0:	73 f3                	jae    f01038b5 <irq_setmask_8259A+0x61>
f01038c2:	eb e0                	jmp    f01038a4 <irq_setmask_8259A+0x50>
	cprintf("\n");
f01038c4:	83 ec 0c             	sub    $0xc,%esp
f01038c7:	68 e1 79 10 f0       	push   $0xf01079e1
f01038cc:	e8 f0 00 00 00       	call   f01039c1 <cprintf>
f01038d1:	83 c4 10             	add    $0x10,%esp
f01038d4:	eb 99                	jmp    f010386f <irq_setmask_8259A+0x1b>

f01038d6 <pic_init>:
{
f01038d6:	f3 0f 1e fb          	endbr32 
f01038da:	55                   	push   %ebp
f01038db:	89 e5                	mov    %esp,%ebp
f01038dd:	57                   	push   %edi
f01038de:	56                   	push   %esi
f01038df:	53                   	push   %ebx
f01038e0:	83 ec 0c             	sub    $0xc,%esp
	didinit = 1;
f01038e3:	c6 05 50 72 21 f0 01 	movb   $0x1,0xf0217250
f01038ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01038ef:	bb 21 00 00 00       	mov    $0x21,%ebx
f01038f4:	89 da                	mov    %ebx,%edx
f01038f6:	ee                   	out    %al,(%dx)
f01038f7:	b9 a1 00 00 00       	mov    $0xa1,%ecx
f01038fc:	89 ca                	mov    %ecx,%edx
f01038fe:	ee                   	out    %al,(%dx)
f01038ff:	bf 11 00 00 00       	mov    $0x11,%edi
f0103904:	be 20 00 00 00       	mov    $0x20,%esi
f0103909:	89 f8                	mov    %edi,%eax
f010390b:	89 f2                	mov    %esi,%edx
f010390d:	ee                   	out    %al,(%dx)
f010390e:	b8 20 00 00 00       	mov    $0x20,%eax
f0103913:	89 da                	mov    %ebx,%edx
f0103915:	ee                   	out    %al,(%dx)
f0103916:	b8 04 00 00 00       	mov    $0x4,%eax
f010391b:	ee                   	out    %al,(%dx)
f010391c:	b8 03 00 00 00       	mov    $0x3,%eax
f0103921:	ee                   	out    %al,(%dx)
f0103922:	bb a0 00 00 00       	mov    $0xa0,%ebx
f0103927:	89 f8                	mov    %edi,%eax
f0103929:	89 da                	mov    %ebx,%edx
f010392b:	ee                   	out    %al,(%dx)
f010392c:	b8 28 00 00 00       	mov    $0x28,%eax
f0103931:	89 ca                	mov    %ecx,%edx
f0103933:	ee                   	out    %al,(%dx)
f0103934:	b8 02 00 00 00       	mov    $0x2,%eax
f0103939:	ee                   	out    %al,(%dx)
f010393a:	b8 01 00 00 00       	mov    $0x1,%eax
f010393f:	ee                   	out    %al,(%dx)
f0103940:	bf 68 00 00 00       	mov    $0x68,%edi
f0103945:	89 f8                	mov    %edi,%eax
f0103947:	89 f2                	mov    %esi,%edx
f0103949:	ee                   	out    %al,(%dx)
f010394a:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010394f:	89 c8                	mov    %ecx,%eax
f0103951:	ee                   	out    %al,(%dx)
f0103952:	89 f8                	mov    %edi,%eax
f0103954:	89 da                	mov    %ebx,%edx
f0103956:	ee                   	out    %al,(%dx)
f0103957:	89 c8                	mov    %ecx,%eax
f0103959:	ee                   	out    %al,(%dx)
	if (irq_mask_8259A != 0xFFFF)
f010395a:	0f b7 05 a8 33 12 f0 	movzwl 0xf01233a8,%eax
f0103961:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103965:	75 08                	jne    f010396f <pic_init+0x99>
}
f0103967:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010396a:	5b                   	pop    %ebx
f010396b:	5e                   	pop    %esi
f010396c:	5f                   	pop    %edi
f010396d:	5d                   	pop    %ebp
f010396e:	c3                   	ret    
		irq_setmask_8259A(irq_mask_8259A);
f010396f:	83 ec 0c             	sub    $0xc,%esp
f0103972:	0f b7 c0             	movzwl %ax,%eax
f0103975:	50                   	push   %eax
f0103976:	e8 d9 fe ff ff       	call   f0103854 <irq_setmask_8259A>
f010397b:	83 c4 10             	add    $0x10,%esp
}
f010397e:	eb e7                	jmp    f0103967 <pic_init+0x91>

f0103980 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103980:	f3 0f 1e fb          	endbr32 
f0103984:	55                   	push   %ebp
f0103985:	89 e5                	mov    %esp,%ebp
f0103987:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010398a:	ff 75 08             	pushl  0x8(%ebp)
f010398d:	e8 2c ce ff ff       	call   f01007be <cputchar>
	*cnt++;
}
f0103992:	83 c4 10             	add    $0x10,%esp
f0103995:	c9                   	leave  
f0103996:	c3                   	ret    

f0103997 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103997:	f3 0f 1e fb          	endbr32 
f010399b:	55                   	push   %ebp
f010399c:	89 e5                	mov    %esp,%ebp
f010399e:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01039a1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01039a8:	ff 75 0c             	pushl  0xc(%ebp)
f01039ab:	ff 75 08             	pushl  0x8(%ebp)
f01039ae:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01039b1:	50                   	push   %eax
f01039b2:	68 80 39 10 f0       	push   $0xf0103980
f01039b7:	e8 f1 19 00 00       	call   f01053ad <vprintfmt>
	return cnt;
}
f01039bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01039bf:	c9                   	leave  
f01039c0:	c3                   	ret    

f01039c1 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01039c1:	f3 0f 1e fb          	endbr32 
f01039c5:	55                   	push   %ebp
f01039c6:	89 e5                	mov    %esp,%ebp
f01039c8:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01039cb:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01039ce:	50                   	push   %eax
f01039cf:	ff 75 08             	pushl  0x8(%ebp)
f01039d2:	e8 c0 ff ff ff       	call   f0103997 <vcprintf>
	va_end(ap);

	return cnt;
}
f01039d7:	c9                   	leave  
f01039d8:	c3                   	ret    

f01039d9 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01039d9:	f3 0f 1e fb          	endbr32 
f01039dd:	55                   	push   %ebp
f01039de:	89 e5                	mov    %esp,%ebp
f01039e0:	57                   	push   %edi
f01039e1:	56                   	push   %esi
f01039e2:	53                   	push   %ebx
f01039e3:	83 ec 1c             	sub    $0x1c,%esp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	uint8_t id = thiscpu->cpu_id;
f01039e6:	e8 43 27 00 00       	call   f010612e <cpunum>
f01039eb:	6b c0 74             	imul   $0x74,%eax,%eax
f01039ee:	0f b6 b8 20 80 21 f0 	movzbl -0xfde7fe0(%eax),%edi
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP-id*(KSTKSIZE+KSTKGAP);
f01039f5:	89 f8                	mov    %edi,%eax
f01039f7:	0f b6 d8             	movzbl %al,%ebx
f01039fa:	e8 2f 27 00 00       	call   f010612e <cpunum>
f01039ff:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a02:	89 d9                	mov    %ebx,%ecx
f0103a04:	c1 e1 10             	shl    $0x10,%ecx
f0103a07:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0103a0c:	29 ca                	sub    %ecx,%edx
f0103a0e:	89 90 30 80 21 f0    	mov    %edx,-0xfde7fd0(%eax)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f0103a14:	e8 15 27 00 00       	call   f010612e <cpunum>
f0103a19:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a1c:	66 c7 80 34 80 21 f0 	movw   $0x10,-0xfde7fcc(%eax)
f0103a23:	10 00 
	thiscpu->cpu_ts.ts_iomb = sizeof(struct Taskstate);
f0103a25:	e8 04 27 00 00       	call   f010612e <cpunum>
f0103a2a:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a2d:	66 c7 80 92 80 21 f0 	movw   $0x68,-0xfde7f6e(%eax)
f0103a34:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+id] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
f0103a36:	83 c3 05             	add    $0x5,%ebx
f0103a39:	e8 f0 26 00 00       	call   f010612e <cpunum>
f0103a3e:	89 c6                	mov    %eax,%esi
f0103a40:	e8 e9 26 00 00       	call   f010612e <cpunum>
f0103a45:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103a48:	e8 e1 26 00 00       	call   f010612e <cpunum>
f0103a4d:	66 c7 04 dd 40 33 12 	movw   $0x67,-0xfedccc0(,%ebx,8)
f0103a54:	f0 67 00 
f0103a57:	6b f6 74             	imul   $0x74,%esi,%esi
f0103a5a:	81 c6 2c 80 21 f0    	add    $0xf021802c,%esi
f0103a60:	66 89 34 dd 42 33 12 	mov    %si,-0xfedccbe(,%ebx,8)
f0103a67:	f0 
f0103a68:	6b 55 e4 74          	imul   $0x74,-0x1c(%ebp),%edx
f0103a6c:	81 c2 2c 80 21 f0    	add    $0xf021802c,%edx
f0103a72:	c1 ea 10             	shr    $0x10,%edx
f0103a75:	88 14 dd 44 33 12 f0 	mov    %dl,-0xfedccbc(,%ebx,8)
f0103a7c:	c6 04 dd 46 33 12 f0 	movb   $0x40,-0xfedccba(,%ebx,8)
f0103a83:	40 
f0103a84:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a87:	05 2c 80 21 f0       	add    $0xf021802c,%eax
f0103a8c:	c1 e8 18             	shr    $0x18,%eax
f0103a8f:	88 04 dd 47 33 12 f0 	mov    %al,-0xfedccb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3)+id].sd_s = 0;
f0103a96:	c6 04 dd 45 33 12 f0 	movb   $0x89,-0xfedccbb(,%ebx,8)
f0103a9d:	89 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0+(id<<3));
f0103a9e:	89 f8                	mov    %edi,%eax
f0103aa0:	0f b6 f8             	movzbl %al,%edi
f0103aa3:	8d 3c fd 28 00 00 00 	lea    0x28(,%edi,8),%edi
	asm volatile("ltr %0" : : "r" (sel));
f0103aaa:	0f 00 df             	ltr    %di
	asm volatile("lidt (%0)" : : "r" (p));
f0103aad:	b8 ac 33 12 f0       	mov    $0xf01233ac,%eax
f0103ab2:	0f 01 18             	lidtl  (%eax)

	// Load the IDT
	lidt(&idt_pd);
}
f0103ab5:	83 c4 1c             	add    $0x1c,%esp
f0103ab8:	5b                   	pop    %ebx
f0103ab9:	5e                   	pop    %esi
f0103aba:	5f                   	pop    %edi
f0103abb:	5d                   	pop    %ebp
f0103abc:	c3                   	ret    

f0103abd <trap_init>:
{
f0103abd:	f3 0f 1e fb          	endbr32 
f0103ac1:	55                   	push   %ebp
f0103ac2:	89 e5                	mov    %esp,%ebp
f0103ac4:	83 ec 08             	sub    $0x8,%esp
    SETGATE(idt[T_DIVIDE], 0, GD_KT, DIVIDE, 0);
f0103ac7:	b8 70 46 10 f0       	mov    $0xf0104670,%eax
f0103acc:	66 a3 60 72 21 f0    	mov    %ax,0xf0217260
f0103ad2:	66 c7 05 62 72 21 f0 	movw   $0x8,0xf0217262
f0103ad9:	08 00 
f0103adb:	c6 05 64 72 21 f0 00 	movb   $0x0,0xf0217264
f0103ae2:	c6 05 65 72 21 f0 8e 	movb   $0x8e,0xf0217265
f0103ae9:	c1 e8 10             	shr    $0x10,%eax
f0103aec:	66 a3 66 72 21 f0    	mov    %ax,0xf0217266
	SETGATE(idt[T_DEBUG], 0, GD_KT, DEBUG, 0);
f0103af2:	b8 7a 46 10 f0       	mov    $0xf010467a,%eax
f0103af7:	66 a3 68 72 21 f0    	mov    %ax,0xf0217268
f0103afd:	66 c7 05 6a 72 21 f0 	movw   $0x8,0xf021726a
f0103b04:	08 00 
f0103b06:	c6 05 6c 72 21 f0 00 	movb   $0x0,0xf021726c
f0103b0d:	c6 05 6d 72 21 f0 8e 	movb   $0x8e,0xf021726d
f0103b14:	c1 e8 10             	shr    $0x10,%eax
f0103b17:	66 a3 6e 72 21 f0    	mov    %ax,0xf021726e
	SETGATE(idt[T_NMI], 0, GD_KT, NMI, 0);
f0103b1d:	b8 84 46 10 f0       	mov    $0xf0104684,%eax
f0103b22:	66 a3 70 72 21 f0    	mov    %ax,0xf0217270
f0103b28:	66 c7 05 72 72 21 f0 	movw   $0x8,0xf0217272
f0103b2f:	08 00 
f0103b31:	c6 05 74 72 21 f0 00 	movb   $0x0,0xf0217274
f0103b38:	c6 05 75 72 21 f0 8e 	movb   $0x8e,0xf0217275
f0103b3f:	c1 e8 10             	shr    $0x10,%eax
f0103b42:	66 a3 76 72 21 f0    	mov    %ax,0xf0217276
	SETGATE(idt[T_BRKPT], 0, GD_KT, BRKPT, 3);
f0103b48:	b8 8e 46 10 f0       	mov    $0xf010468e,%eax
f0103b4d:	66 a3 78 72 21 f0    	mov    %ax,0xf0217278
f0103b53:	66 c7 05 7a 72 21 f0 	movw   $0x8,0xf021727a
f0103b5a:	08 00 
f0103b5c:	c6 05 7c 72 21 f0 00 	movb   $0x0,0xf021727c
f0103b63:	c6 05 7d 72 21 f0 ee 	movb   $0xee,0xf021727d
f0103b6a:	c1 e8 10             	shr    $0x10,%eax
f0103b6d:	66 a3 7e 72 21 f0    	mov    %ax,0xf021727e
	SETGATE(idt[T_OFLOW], 0, GD_KT, OFLOW, 0);
f0103b73:	b8 98 46 10 f0       	mov    $0xf0104698,%eax
f0103b78:	66 a3 80 72 21 f0    	mov    %ax,0xf0217280
f0103b7e:	66 c7 05 82 72 21 f0 	movw   $0x8,0xf0217282
f0103b85:	08 00 
f0103b87:	c6 05 84 72 21 f0 00 	movb   $0x0,0xf0217284
f0103b8e:	c6 05 85 72 21 f0 8e 	movb   $0x8e,0xf0217285
f0103b95:	c1 e8 10             	shr    $0x10,%eax
f0103b98:	66 a3 86 72 21 f0    	mov    %ax,0xf0217286
	SETGATE(idt[T_BOUND], 0, GD_KT, BOUND, 0);
f0103b9e:	b8 a2 46 10 f0       	mov    $0xf01046a2,%eax
f0103ba3:	66 a3 88 72 21 f0    	mov    %ax,0xf0217288
f0103ba9:	66 c7 05 8a 72 21 f0 	movw   $0x8,0xf021728a
f0103bb0:	08 00 
f0103bb2:	c6 05 8c 72 21 f0 00 	movb   $0x0,0xf021728c
f0103bb9:	c6 05 8d 72 21 f0 8e 	movb   $0x8e,0xf021728d
f0103bc0:	c1 e8 10             	shr    $0x10,%eax
f0103bc3:	66 a3 8e 72 21 f0    	mov    %ax,0xf021728e
	SETGATE(idt[T_ILLOP], 0, GD_KT, ILLOP, 0);
f0103bc9:	b8 ac 46 10 f0       	mov    $0xf01046ac,%eax
f0103bce:	66 a3 90 72 21 f0    	mov    %ax,0xf0217290
f0103bd4:	66 c7 05 92 72 21 f0 	movw   $0x8,0xf0217292
f0103bdb:	08 00 
f0103bdd:	c6 05 94 72 21 f0 00 	movb   $0x0,0xf0217294
f0103be4:	c6 05 95 72 21 f0 8e 	movb   $0x8e,0xf0217295
f0103beb:	c1 e8 10             	shr    $0x10,%eax
f0103bee:	66 a3 96 72 21 f0    	mov    %ax,0xf0217296
	SETGATE(idt[T_DEVICE], 0, GD_KT, DEVICE, 0);
f0103bf4:	b8 b6 46 10 f0       	mov    $0xf01046b6,%eax
f0103bf9:	66 a3 98 72 21 f0    	mov    %ax,0xf0217298
f0103bff:	66 c7 05 9a 72 21 f0 	movw   $0x8,0xf021729a
f0103c06:	08 00 
f0103c08:	c6 05 9c 72 21 f0 00 	movb   $0x0,0xf021729c
f0103c0f:	c6 05 9d 72 21 f0 8e 	movb   $0x8e,0xf021729d
f0103c16:	c1 e8 10             	shr    $0x10,%eax
f0103c19:	66 a3 9e 72 21 f0    	mov    %ax,0xf021729e
	SETGATE(idt[T_DBLFLT], 0, GD_KT, DBLFLT, 0);
f0103c1f:	b8 c0 46 10 f0       	mov    $0xf01046c0,%eax
f0103c24:	66 a3 a0 72 21 f0    	mov    %ax,0xf02172a0
f0103c2a:	66 c7 05 a2 72 21 f0 	movw   $0x8,0xf02172a2
f0103c31:	08 00 
f0103c33:	c6 05 a4 72 21 f0 00 	movb   $0x0,0xf02172a4
f0103c3a:	c6 05 a5 72 21 f0 8e 	movb   $0x8e,0xf02172a5
f0103c41:	c1 e8 10             	shr    $0x10,%eax
f0103c44:	66 a3 a6 72 21 f0    	mov    %ax,0xf02172a6
	SETGATE(idt[T_TSS], 0, GD_KT, TSS, 0);
f0103c4a:	b8 c8 46 10 f0       	mov    $0xf01046c8,%eax
f0103c4f:	66 a3 b0 72 21 f0    	mov    %ax,0xf02172b0
f0103c55:	66 c7 05 b2 72 21 f0 	movw   $0x8,0xf02172b2
f0103c5c:	08 00 
f0103c5e:	c6 05 b4 72 21 f0 00 	movb   $0x0,0xf02172b4
f0103c65:	c6 05 b5 72 21 f0 8e 	movb   $0x8e,0xf02172b5
f0103c6c:	c1 e8 10             	shr    $0x10,%eax
f0103c6f:	66 a3 b6 72 21 f0    	mov    %ax,0xf02172b6
	SETGATE(idt[T_SEGNP], 0, GD_KT, SEGNP, 0);
f0103c75:	b8 d0 46 10 f0       	mov    $0xf01046d0,%eax
f0103c7a:	66 a3 b8 72 21 f0    	mov    %ax,0xf02172b8
f0103c80:	66 c7 05 ba 72 21 f0 	movw   $0x8,0xf02172ba
f0103c87:	08 00 
f0103c89:	c6 05 bc 72 21 f0 00 	movb   $0x0,0xf02172bc
f0103c90:	c6 05 bd 72 21 f0 8e 	movb   $0x8e,0xf02172bd
f0103c97:	c1 e8 10             	shr    $0x10,%eax
f0103c9a:	66 a3 be 72 21 f0    	mov    %ax,0xf02172be
	SETGATE(idt[T_STACK], 0, GD_KT, STACK, 0);
f0103ca0:	b8 d8 46 10 f0       	mov    $0xf01046d8,%eax
f0103ca5:	66 a3 c0 72 21 f0    	mov    %ax,0xf02172c0
f0103cab:	66 c7 05 c2 72 21 f0 	movw   $0x8,0xf02172c2
f0103cb2:	08 00 
f0103cb4:	c6 05 c4 72 21 f0 00 	movb   $0x0,0xf02172c4
f0103cbb:	c6 05 c5 72 21 f0 8e 	movb   $0x8e,0xf02172c5
f0103cc2:	c1 e8 10             	shr    $0x10,%eax
f0103cc5:	66 a3 c6 72 21 f0    	mov    %ax,0xf02172c6
	SETGATE(idt[T_GPFLT], 0, GD_KT, GPFLT, 0);
f0103ccb:	b8 e0 46 10 f0       	mov    $0xf01046e0,%eax
f0103cd0:	66 a3 c8 72 21 f0    	mov    %ax,0xf02172c8
f0103cd6:	66 c7 05 ca 72 21 f0 	movw   $0x8,0xf02172ca
f0103cdd:	08 00 
f0103cdf:	c6 05 cc 72 21 f0 00 	movb   $0x0,0xf02172cc
f0103ce6:	c6 05 cd 72 21 f0 8e 	movb   $0x8e,0xf02172cd
f0103ced:	c1 e8 10             	shr    $0x10,%eax
f0103cf0:	66 a3 ce 72 21 f0    	mov    %ax,0xf02172ce
	SETGATE(idt[T_PGFLT], 0, GD_KT, PGFLT, 0);
f0103cf6:	b8 e8 46 10 f0       	mov    $0xf01046e8,%eax
f0103cfb:	66 a3 d0 72 21 f0    	mov    %ax,0xf02172d0
f0103d01:	66 c7 05 d2 72 21 f0 	movw   $0x8,0xf02172d2
f0103d08:	08 00 
f0103d0a:	c6 05 d4 72 21 f0 00 	movb   $0x0,0xf02172d4
f0103d11:	c6 05 d5 72 21 f0 8e 	movb   $0x8e,0xf02172d5
f0103d18:	c1 e8 10             	shr    $0x10,%eax
f0103d1b:	66 a3 d6 72 21 f0    	mov    %ax,0xf02172d6
	SETGATE(idt[T_FPERR], 0, GD_KT, FPERR, 0);
f0103d21:	b8 f0 46 10 f0       	mov    $0xf01046f0,%eax
f0103d26:	66 a3 e0 72 21 f0    	mov    %ax,0xf02172e0
f0103d2c:	66 c7 05 e2 72 21 f0 	movw   $0x8,0xf02172e2
f0103d33:	08 00 
f0103d35:	c6 05 e4 72 21 f0 00 	movb   $0x0,0xf02172e4
f0103d3c:	c6 05 e5 72 21 f0 8e 	movb   $0x8e,0xf02172e5
f0103d43:	c1 e8 10             	shr    $0x10,%eax
f0103d46:	66 a3 e6 72 21 f0    	mov    %ax,0xf02172e6
	SETGATE(idt[T_ALIGN], 0, GD_KT, ALIGN, 0);
f0103d4c:	b8 fa 46 10 f0       	mov    $0xf01046fa,%eax
f0103d51:	66 a3 e8 72 21 f0    	mov    %ax,0xf02172e8
f0103d57:	66 c7 05 ea 72 21 f0 	movw   $0x8,0xf02172ea
f0103d5e:	08 00 
f0103d60:	c6 05 ec 72 21 f0 00 	movb   $0x0,0xf02172ec
f0103d67:	c6 05 ed 72 21 f0 8e 	movb   $0x8e,0xf02172ed
f0103d6e:	c1 e8 10             	shr    $0x10,%eax
f0103d71:	66 a3 ee 72 21 f0    	mov    %ax,0xf02172ee
	SETGATE(idt[T_MCHK], 0, GD_KT, MCHK, 0);
f0103d77:	b8 02 47 10 f0       	mov    $0xf0104702,%eax
f0103d7c:	66 a3 f0 72 21 f0    	mov    %ax,0xf02172f0
f0103d82:	66 c7 05 f2 72 21 f0 	movw   $0x8,0xf02172f2
f0103d89:	08 00 
f0103d8b:	c6 05 f4 72 21 f0 00 	movb   $0x0,0xf02172f4
f0103d92:	c6 05 f5 72 21 f0 8e 	movb   $0x8e,0xf02172f5
f0103d99:	c1 e8 10             	shr    $0x10,%eax
f0103d9c:	66 a3 f6 72 21 f0    	mov    %ax,0xf02172f6
	SETGATE(idt[T_SIMDERR], 0, GD_KT, SIMDERR, 0);
f0103da2:	b8 08 47 10 f0       	mov    $0xf0104708,%eax
f0103da7:	66 a3 f8 72 21 f0    	mov    %ax,0xf02172f8
f0103dad:	66 c7 05 fa 72 21 f0 	movw   $0x8,0xf02172fa
f0103db4:	08 00 
f0103db6:	c6 05 fc 72 21 f0 00 	movb   $0x0,0xf02172fc
f0103dbd:	c6 05 fd 72 21 f0 8e 	movb   $0x8e,0xf02172fd
f0103dc4:	c1 e8 10             	shr    $0x10,%eax
f0103dc7:	66 a3 fe 72 21 f0    	mov    %ax,0xf02172fe
	SETGATE(idt[T_SYSCALL], 0, GD_KT, SYSCALL, 3);
f0103dcd:	b8 0e 47 10 f0       	mov    $0xf010470e,%eax
f0103dd2:	66 a3 e0 73 21 f0    	mov    %ax,0xf02173e0
f0103dd8:	66 c7 05 e2 73 21 f0 	movw   $0x8,0xf02173e2
f0103ddf:	08 00 
f0103de1:	c6 05 e4 73 21 f0 00 	movb   $0x0,0xf02173e4
f0103de8:	c6 05 e5 73 21 f0 ee 	movb   $0xee,0xf02173e5
f0103def:	c1 e8 10             	shr    $0x10,%eax
f0103df2:	66 a3 e6 73 21 f0    	mov    %ax,0xf02173e6
	SETGATE(idt[T_DEFAULT], 0, GD_KT, DEFAULT, 0);
f0103df8:	b8 14 47 10 f0       	mov    $0xf0104714,%eax
f0103dfd:	66 a3 00 82 21 f0    	mov    %ax,0xf0218200
f0103e03:	66 c7 05 02 82 21 f0 	movw   $0x8,0xf0218202
f0103e0a:	08 00 
f0103e0c:	c6 05 04 82 21 f0 00 	movb   $0x0,0xf0218204
f0103e13:	c6 05 05 82 21 f0 8e 	movb   $0x8e,0xf0218205
f0103e1a:	c1 e8 10             	shr    $0x10,%eax
f0103e1d:	66 a3 06 82 21 f0    	mov    %ax,0xf0218206
	SETGATE(idt[IRQ_OFFSET+IRQ_TIMER],0,GD_KT,IRQsHandler0,0);
f0103e23:	b8 1e 47 10 f0       	mov    $0xf010471e,%eax
f0103e28:	66 a3 60 73 21 f0    	mov    %ax,0xf0217360
f0103e2e:	66 c7 05 62 73 21 f0 	movw   $0x8,0xf0217362
f0103e35:	08 00 
f0103e37:	c6 05 64 73 21 f0 00 	movb   $0x0,0xf0217364
f0103e3e:	c6 05 65 73 21 f0 8e 	movb   $0x8e,0xf0217365
f0103e45:	c1 e8 10             	shr    $0x10,%eax
f0103e48:	66 a3 66 73 21 f0    	mov    %ax,0xf0217366
	SETGATE(idt[IRQ_OFFSET+IRQ_KBD],0,GD_KT,IRQsHandler1,0);
f0103e4e:	b8 24 47 10 f0       	mov    $0xf0104724,%eax
f0103e53:	66 a3 68 73 21 f0    	mov    %ax,0xf0217368
f0103e59:	66 c7 05 6a 73 21 f0 	movw   $0x8,0xf021736a
f0103e60:	08 00 
f0103e62:	c6 05 6c 73 21 f0 00 	movb   $0x0,0xf021736c
f0103e69:	c6 05 6d 73 21 f0 8e 	movb   $0x8e,0xf021736d
f0103e70:	c1 e8 10             	shr    $0x10,%eax
f0103e73:	66 a3 6e 73 21 f0    	mov    %ax,0xf021736e
	SETGATE(idt[IRQ_OFFSET+2],0,GD_KT,IRQsHandler2,0);
f0103e79:	b8 2a 47 10 f0       	mov    $0xf010472a,%eax
f0103e7e:	66 a3 70 73 21 f0    	mov    %ax,0xf0217370
f0103e84:	66 c7 05 72 73 21 f0 	movw   $0x8,0xf0217372
f0103e8b:	08 00 
f0103e8d:	c6 05 74 73 21 f0 00 	movb   $0x0,0xf0217374
f0103e94:	c6 05 75 73 21 f0 8e 	movb   $0x8e,0xf0217375
f0103e9b:	c1 e8 10             	shr    $0x10,%eax
f0103e9e:	66 a3 76 73 21 f0    	mov    %ax,0xf0217376
	SETGATE(idt[IRQ_OFFSET+3],0,GD_KT,IRQsHandler3,0);
f0103ea4:	b8 30 47 10 f0       	mov    $0xf0104730,%eax
f0103ea9:	66 a3 78 73 21 f0    	mov    %ax,0xf0217378
f0103eaf:	66 c7 05 7a 73 21 f0 	movw   $0x8,0xf021737a
f0103eb6:	08 00 
f0103eb8:	c6 05 7c 73 21 f0 00 	movb   $0x0,0xf021737c
f0103ebf:	c6 05 7d 73 21 f0 8e 	movb   $0x8e,0xf021737d
f0103ec6:	c1 e8 10             	shr    $0x10,%eax
f0103ec9:	66 a3 7e 73 21 f0    	mov    %ax,0xf021737e
	SETGATE(idt[IRQ_OFFSET+IRQ_SERIAL],0,GD_KT,IRQsHandler4,0);
f0103ecf:	b8 36 47 10 f0       	mov    $0xf0104736,%eax
f0103ed4:	66 a3 80 73 21 f0    	mov    %ax,0xf0217380
f0103eda:	66 c7 05 82 73 21 f0 	movw   $0x8,0xf0217382
f0103ee1:	08 00 
f0103ee3:	c6 05 84 73 21 f0 00 	movb   $0x0,0xf0217384
f0103eea:	c6 05 85 73 21 f0 8e 	movb   $0x8e,0xf0217385
f0103ef1:	c1 e8 10             	shr    $0x10,%eax
f0103ef4:	66 a3 86 73 21 f0    	mov    %ax,0xf0217386
	SETGATE(idt[IRQ_OFFSET+5],0,GD_KT,IRQsHandler5,0);
f0103efa:	b8 3c 47 10 f0       	mov    $0xf010473c,%eax
f0103eff:	66 a3 88 73 21 f0    	mov    %ax,0xf0217388
f0103f05:	66 c7 05 8a 73 21 f0 	movw   $0x8,0xf021738a
f0103f0c:	08 00 
f0103f0e:	c6 05 8c 73 21 f0 00 	movb   $0x0,0xf021738c
f0103f15:	c6 05 8d 73 21 f0 8e 	movb   $0x8e,0xf021738d
f0103f1c:	c1 e8 10             	shr    $0x10,%eax
f0103f1f:	66 a3 8e 73 21 f0    	mov    %ax,0xf021738e
	SETGATE(idt[IRQ_OFFSET+6],0,GD_KT,IRQsHandler6,0);
f0103f25:	b8 42 47 10 f0       	mov    $0xf0104742,%eax
f0103f2a:	66 a3 90 73 21 f0    	mov    %ax,0xf0217390
f0103f30:	66 c7 05 92 73 21 f0 	movw   $0x8,0xf0217392
f0103f37:	08 00 
f0103f39:	c6 05 94 73 21 f0 00 	movb   $0x0,0xf0217394
f0103f40:	c6 05 95 73 21 f0 8e 	movb   $0x8e,0xf0217395
f0103f47:	c1 e8 10             	shr    $0x10,%eax
f0103f4a:	66 a3 96 73 21 f0    	mov    %ax,0xf0217396
	SETGATE(idt[IRQ_OFFSET+IRQ_SPURIOUS],0,GD_KT,IRQsHandler7,0);
f0103f50:	b8 48 47 10 f0       	mov    $0xf0104748,%eax
f0103f55:	66 a3 98 73 21 f0    	mov    %ax,0xf0217398
f0103f5b:	66 c7 05 9a 73 21 f0 	movw   $0x8,0xf021739a
f0103f62:	08 00 
f0103f64:	c6 05 9c 73 21 f0 00 	movb   $0x0,0xf021739c
f0103f6b:	c6 05 9d 73 21 f0 8e 	movb   $0x8e,0xf021739d
f0103f72:	c1 e8 10             	shr    $0x10,%eax
f0103f75:	66 a3 9e 73 21 f0    	mov    %ax,0xf021739e
	SETGATE(idt[IRQ_OFFSET+8],0,GD_KT,IRQsHandler8,0);
f0103f7b:	b8 4e 47 10 f0       	mov    $0xf010474e,%eax
f0103f80:	66 a3 a0 73 21 f0    	mov    %ax,0xf02173a0
f0103f86:	66 c7 05 a2 73 21 f0 	movw   $0x8,0xf02173a2
f0103f8d:	08 00 
f0103f8f:	c6 05 a4 73 21 f0 00 	movb   $0x0,0xf02173a4
f0103f96:	c6 05 a5 73 21 f0 8e 	movb   $0x8e,0xf02173a5
f0103f9d:	c1 e8 10             	shr    $0x10,%eax
f0103fa0:	66 a3 a6 73 21 f0    	mov    %ax,0xf02173a6
	SETGATE(idt[IRQ_OFFSET+9],0,GD_KT,IRQsHandler9,0);
f0103fa6:	b8 54 47 10 f0       	mov    $0xf0104754,%eax
f0103fab:	66 a3 a8 73 21 f0    	mov    %ax,0xf02173a8
f0103fb1:	66 c7 05 aa 73 21 f0 	movw   $0x8,0xf02173aa
f0103fb8:	08 00 
f0103fba:	c6 05 ac 73 21 f0 00 	movb   $0x0,0xf02173ac
f0103fc1:	c6 05 ad 73 21 f0 8e 	movb   $0x8e,0xf02173ad
f0103fc8:	c1 e8 10             	shr    $0x10,%eax
f0103fcb:	66 a3 ae 73 21 f0    	mov    %ax,0xf02173ae
	SETGATE(idt[IRQ_OFFSET+10],0,GD_KT,IRQsHandler10,0);
f0103fd1:	b8 5a 47 10 f0       	mov    $0xf010475a,%eax
f0103fd6:	66 a3 b0 73 21 f0    	mov    %ax,0xf02173b0
f0103fdc:	66 c7 05 b2 73 21 f0 	movw   $0x8,0xf02173b2
f0103fe3:	08 00 
f0103fe5:	c6 05 b4 73 21 f0 00 	movb   $0x0,0xf02173b4
f0103fec:	c6 05 b5 73 21 f0 8e 	movb   $0x8e,0xf02173b5
f0103ff3:	c1 e8 10             	shr    $0x10,%eax
f0103ff6:	66 a3 b6 73 21 f0    	mov    %ax,0xf02173b6
	SETGATE(idt[IRQ_OFFSET+11],0,GD_KT,IRQsHandler11,0);
f0103ffc:	b8 60 47 10 f0       	mov    $0xf0104760,%eax
f0104001:	66 a3 b8 73 21 f0    	mov    %ax,0xf02173b8
f0104007:	66 c7 05 ba 73 21 f0 	movw   $0x8,0xf02173ba
f010400e:	08 00 
f0104010:	c6 05 bc 73 21 f0 00 	movb   $0x0,0xf02173bc
f0104017:	c6 05 bd 73 21 f0 8e 	movb   $0x8e,0xf02173bd
f010401e:	c1 e8 10             	shr    $0x10,%eax
f0104021:	66 a3 be 73 21 f0    	mov    %ax,0xf02173be
	SETGATE(idt[IRQ_OFFSET+12],0,GD_KT,IRQsHandler12,0);
f0104027:	b8 66 47 10 f0       	mov    $0xf0104766,%eax
f010402c:	66 a3 c0 73 21 f0    	mov    %ax,0xf02173c0
f0104032:	66 c7 05 c2 73 21 f0 	movw   $0x8,0xf02173c2
f0104039:	08 00 
f010403b:	c6 05 c4 73 21 f0 00 	movb   $0x0,0xf02173c4
f0104042:	c6 05 c5 73 21 f0 8e 	movb   $0x8e,0xf02173c5
f0104049:	c1 e8 10             	shr    $0x10,%eax
f010404c:	66 a3 c6 73 21 f0    	mov    %ax,0xf02173c6
	SETGATE(idt[IRQ_OFFSET+13],0,GD_KT,IRQsHandler13,0);
f0104052:	b8 6c 47 10 f0       	mov    $0xf010476c,%eax
f0104057:	66 a3 c8 73 21 f0    	mov    %ax,0xf02173c8
f010405d:	66 c7 05 ca 73 21 f0 	movw   $0x8,0xf02173ca
f0104064:	08 00 
f0104066:	c6 05 cc 73 21 f0 00 	movb   $0x0,0xf02173cc
f010406d:	c6 05 cd 73 21 f0 8e 	movb   $0x8e,0xf02173cd
f0104074:	c1 e8 10             	shr    $0x10,%eax
f0104077:	66 a3 ce 73 21 f0    	mov    %ax,0xf02173ce
	SETGATE(idt[IRQ_OFFSET+IRQ_IDE],0,GD_KT,IRQsHandler14,0);
f010407d:	b8 72 47 10 f0       	mov    $0xf0104772,%eax
f0104082:	66 a3 d0 73 21 f0    	mov    %ax,0xf02173d0
f0104088:	66 c7 05 d2 73 21 f0 	movw   $0x8,0xf02173d2
f010408f:	08 00 
f0104091:	c6 05 d4 73 21 f0 00 	movb   $0x0,0xf02173d4
f0104098:	c6 05 d5 73 21 f0 8e 	movb   $0x8e,0xf02173d5
f010409f:	c1 e8 10             	shr    $0x10,%eax
f01040a2:	66 a3 d6 73 21 f0    	mov    %ax,0xf02173d6
	SETGATE(idt[IRQ_OFFSET+15],0,GD_KT,IRQsHandler15,0);
f01040a8:	b8 78 47 10 f0       	mov    $0xf0104778,%eax
f01040ad:	66 a3 d8 73 21 f0    	mov    %ax,0xf02173d8
f01040b3:	66 c7 05 da 73 21 f0 	movw   $0x8,0xf02173da
f01040ba:	08 00 
f01040bc:	c6 05 dc 73 21 f0 00 	movb   $0x0,0xf02173dc
f01040c3:	c6 05 dd 73 21 f0 8e 	movb   $0x8e,0xf02173dd
f01040ca:	c1 e8 10             	shr    $0x10,%eax
f01040cd:	66 a3 de 73 21 f0    	mov    %ax,0xf02173de
	trap_init_percpu();
f01040d3:	e8 01 f9 ff ff       	call   f01039d9 <trap_init_percpu>
}
f01040d8:	c9                   	leave  
f01040d9:	c3                   	ret    

f01040da <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01040da:	f3 0f 1e fb          	endbr32 
f01040de:	55                   	push   %ebp
f01040df:	89 e5                	mov    %esp,%ebp
f01040e1:	53                   	push   %ebx
f01040e2:	83 ec 0c             	sub    $0xc,%esp
f01040e5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01040e8:	ff 33                	pushl  (%ebx)
f01040ea:	68 34 7b 10 f0       	push   $0xf0107b34
f01040ef:	e8 cd f8 ff ff       	call   f01039c1 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01040f4:	83 c4 08             	add    $0x8,%esp
f01040f7:	ff 73 04             	pushl  0x4(%ebx)
f01040fa:	68 43 7b 10 f0       	push   $0xf0107b43
f01040ff:	e8 bd f8 ff ff       	call   f01039c1 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0104104:	83 c4 08             	add    $0x8,%esp
f0104107:	ff 73 08             	pushl  0x8(%ebx)
f010410a:	68 52 7b 10 f0       	push   $0xf0107b52
f010410f:	e8 ad f8 ff ff       	call   f01039c1 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0104114:	83 c4 08             	add    $0x8,%esp
f0104117:	ff 73 0c             	pushl  0xc(%ebx)
f010411a:	68 61 7b 10 f0       	push   $0xf0107b61
f010411f:	e8 9d f8 ff ff       	call   f01039c1 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0104124:	83 c4 08             	add    $0x8,%esp
f0104127:	ff 73 10             	pushl  0x10(%ebx)
f010412a:	68 70 7b 10 f0       	push   $0xf0107b70
f010412f:	e8 8d f8 ff ff       	call   f01039c1 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0104134:	83 c4 08             	add    $0x8,%esp
f0104137:	ff 73 14             	pushl  0x14(%ebx)
f010413a:	68 7f 7b 10 f0       	push   $0xf0107b7f
f010413f:	e8 7d f8 ff ff       	call   f01039c1 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0104144:	83 c4 08             	add    $0x8,%esp
f0104147:	ff 73 18             	pushl  0x18(%ebx)
f010414a:	68 8e 7b 10 f0       	push   $0xf0107b8e
f010414f:	e8 6d f8 ff ff       	call   f01039c1 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0104154:	83 c4 08             	add    $0x8,%esp
f0104157:	ff 73 1c             	pushl  0x1c(%ebx)
f010415a:	68 9d 7b 10 f0       	push   $0xf0107b9d
f010415f:	e8 5d f8 ff ff       	call   f01039c1 <cprintf>
}
f0104164:	83 c4 10             	add    $0x10,%esp
f0104167:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010416a:	c9                   	leave  
f010416b:	c3                   	ret    

f010416c <print_trapframe>:
{
f010416c:	f3 0f 1e fb          	endbr32 
f0104170:	55                   	push   %ebp
f0104171:	89 e5                	mov    %esp,%ebp
f0104173:	56                   	push   %esi
f0104174:	53                   	push   %ebx
f0104175:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0104178:	e8 b1 1f 00 00       	call   f010612e <cpunum>
f010417d:	83 ec 04             	sub    $0x4,%esp
f0104180:	50                   	push   %eax
f0104181:	53                   	push   %ebx
f0104182:	68 01 7c 10 f0       	push   $0xf0107c01
f0104187:	e8 35 f8 ff ff       	call   f01039c1 <cprintf>
	print_regs(&tf->tf_regs);
f010418c:	89 1c 24             	mov    %ebx,(%esp)
f010418f:	e8 46 ff ff ff       	call   f01040da <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0104194:	83 c4 08             	add    $0x8,%esp
f0104197:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f010419b:	50                   	push   %eax
f010419c:	68 1f 7c 10 f0       	push   $0xf0107c1f
f01041a1:	e8 1b f8 ff ff       	call   f01039c1 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01041a6:	83 c4 08             	add    $0x8,%esp
f01041a9:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01041ad:	50                   	push   %eax
f01041ae:	68 32 7c 10 f0       	push   $0xf0107c32
f01041b3:	e8 09 f8 ff ff       	call   f01039c1 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01041b8:	8b 43 28             	mov    0x28(%ebx),%eax
	if (trapno < ARRAY_SIZE(excnames))
f01041bb:	83 c4 10             	add    $0x10,%esp
f01041be:	83 f8 13             	cmp    $0x13,%eax
f01041c1:	0f 86 da 00 00 00    	jbe    f01042a1 <print_trapframe+0x135>
		return "System call";
f01041c7:	ba ac 7b 10 f0       	mov    $0xf0107bac,%edx
	if (trapno == T_SYSCALL)
f01041cc:	83 f8 30             	cmp    $0x30,%eax
f01041cf:	74 13                	je     f01041e4 <print_trapframe+0x78>
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f01041d1:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
f01041d4:	83 fa 0f             	cmp    $0xf,%edx
f01041d7:	ba b8 7b 10 f0       	mov    $0xf0107bb8,%edx
f01041dc:	b9 c7 7b 10 f0       	mov    $0xf0107bc7,%ecx
f01041e1:	0f 46 d1             	cmovbe %ecx,%edx
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01041e4:	83 ec 04             	sub    $0x4,%esp
f01041e7:	52                   	push   %edx
f01041e8:	50                   	push   %eax
f01041e9:	68 45 7c 10 f0       	push   $0xf0107c45
f01041ee:	e8 ce f7 ff ff       	call   f01039c1 <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01041f3:	83 c4 10             	add    $0x10,%esp
f01041f6:	39 1d 60 7a 21 f0    	cmp    %ebx,0xf0217a60
f01041fc:	0f 84 ab 00 00 00    	je     f01042ad <print_trapframe+0x141>
	cprintf("  err  0x%08x", tf->tf_err);
f0104202:	83 ec 08             	sub    $0x8,%esp
f0104205:	ff 73 2c             	pushl  0x2c(%ebx)
f0104208:	68 66 7c 10 f0       	push   $0xf0107c66
f010420d:	e8 af f7 ff ff       	call   f01039c1 <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f0104212:	83 c4 10             	add    $0x10,%esp
f0104215:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0104219:	0f 85 b1 00 00 00    	jne    f01042d0 <print_trapframe+0x164>
			tf->tf_err & 1 ? "protection" : "not-present");
f010421f:	8b 43 2c             	mov    0x2c(%ebx),%eax
		cprintf(" [%s, %s, %s]\n",
f0104222:	a8 01                	test   $0x1,%al
f0104224:	b9 da 7b 10 f0       	mov    $0xf0107bda,%ecx
f0104229:	ba e5 7b 10 f0       	mov    $0xf0107be5,%edx
f010422e:	0f 44 ca             	cmove  %edx,%ecx
f0104231:	a8 02                	test   $0x2,%al
f0104233:	be f1 7b 10 f0       	mov    $0xf0107bf1,%esi
f0104238:	ba f7 7b 10 f0       	mov    $0xf0107bf7,%edx
f010423d:	0f 45 d6             	cmovne %esi,%edx
f0104240:	a8 04                	test   $0x4,%al
f0104242:	b8 fc 7b 10 f0       	mov    $0xf0107bfc,%eax
f0104247:	be 31 7d 10 f0       	mov    $0xf0107d31,%esi
f010424c:	0f 44 c6             	cmove  %esi,%eax
f010424f:	51                   	push   %ecx
f0104250:	52                   	push   %edx
f0104251:	50                   	push   %eax
f0104252:	68 74 7c 10 f0       	push   $0xf0107c74
f0104257:	e8 65 f7 ff ff       	call   f01039c1 <cprintf>
f010425c:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010425f:	83 ec 08             	sub    $0x8,%esp
f0104262:	ff 73 30             	pushl  0x30(%ebx)
f0104265:	68 83 7c 10 f0       	push   $0xf0107c83
f010426a:	e8 52 f7 ff ff       	call   f01039c1 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f010426f:	83 c4 08             	add    $0x8,%esp
f0104272:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0104276:	50                   	push   %eax
f0104277:	68 92 7c 10 f0       	push   $0xf0107c92
f010427c:	e8 40 f7 ff ff       	call   f01039c1 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0104281:	83 c4 08             	add    $0x8,%esp
f0104284:	ff 73 38             	pushl  0x38(%ebx)
f0104287:	68 a5 7c 10 f0       	push   $0xf0107ca5
f010428c:	e8 30 f7 ff ff       	call   f01039c1 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0104291:	83 c4 10             	add    $0x10,%esp
f0104294:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0104298:	75 4b                	jne    f01042e5 <print_trapframe+0x179>
}
f010429a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010429d:	5b                   	pop    %ebx
f010429e:	5e                   	pop    %esi
f010429f:	5d                   	pop    %ebp
f01042a0:	c3                   	ret    
		return excnames[trapno];
f01042a1:	8b 14 85 c0 7f 10 f0 	mov    -0xfef8040(,%eax,4),%edx
f01042a8:	e9 37 ff ff ff       	jmp    f01041e4 <print_trapframe+0x78>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01042ad:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01042b1:	0f 85 4b ff ff ff    	jne    f0104202 <print_trapframe+0x96>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01042b7:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01042ba:	83 ec 08             	sub    $0x8,%esp
f01042bd:	50                   	push   %eax
f01042be:	68 57 7c 10 f0       	push   $0xf0107c57
f01042c3:	e8 f9 f6 ff ff       	call   f01039c1 <cprintf>
f01042c8:	83 c4 10             	add    $0x10,%esp
f01042cb:	e9 32 ff ff ff       	jmp    f0104202 <print_trapframe+0x96>
		cprintf("\n");
f01042d0:	83 ec 0c             	sub    $0xc,%esp
f01042d3:	68 e1 79 10 f0       	push   $0xf01079e1
f01042d8:	e8 e4 f6 ff ff       	call   f01039c1 <cprintf>
f01042dd:	83 c4 10             	add    $0x10,%esp
f01042e0:	e9 7a ff ff ff       	jmp    f010425f <print_trapframe+0xf3>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01042e5:	83 ec 08             	sub    $0x8,%esp
f01042e8:	ff 73 3c             	pushl  0x3c(%ebx)
f01042eb:	68 b4 7c 10 f0       	push   $0xf0107cb4
f01042f0:	e8 cc f6 ff ff       	call   f01039c1 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01042f5:	83 c4 08             	add    $0x8,%esp
f01042f8:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01042fc:	50                   	push   %eax
f01042fd:	68 c3 7c 10 f0       	push   $0xf0107cc3
f0104302:	e8 ba f6 ff ff       	call   f01039c1 <cprintf>
f0104307:	83 c4 10             	add    $0x10,%esp
}
f010430a:	eb 8e                	jmp    f010429a <print_trapframe+0x12e>

f010430c <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f010430c:	f3 0f 1e fb          	endbr32 
f0104310:	55                   	push   %ebp
f0104311:	89 e5                	mov    %esp,%ebp
f0104313:	57                   	push   %edi
f0104314:	56                   	push   %esi
f0104315:	53                   	push   %ebx
f0104316:	83 ec 1c             	sub    $0x1c,%esp
f0104319:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010431c:	0f 20 d6             	mov    %cr2,%esi

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	// check low-bits of tf_cs
	if((tf->tf_cs & 3) == 0)
f010431f:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0104323:	75 15                	jne    f010433a <page_fault_handler+0x2e>
	{
		panic("At page_fault_handler: page fault at %08x.\n",fault_va);
f0104325:	56                   	push   %esi
f0104326:	68 7c 7e 10 f0       	push   $0xf0107e7c
f010432b:	68 b4 01 00 00       	push   $0x1b4
f0104330:	68 d6 7c 10 f0       	push   $0xf0107cd6
f0104335:	e8 06 bd ff ff       	call   f0100040 <_panic>
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	// no self-defined pgfault_upcall function
	if(curenv->env_pgfault_upcall == NULL)
f010433a:	e8 ef 1d 00 00       	call   f010612e <cpunum>
f010433f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104342:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0104348:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f010434c:	0f 84 92 00 00 00    	je     f01043e4 <page_fault_handler+0xd8>
	
	struct UTrapframe* utf;
	uintptr_t addr;
	// determine utf address
	size_t size = sizeof(struct UTrapframe)+ sizeof(uint32_t);
	if (tf->tf_esp >= UXSTACKTOP-PGSIZE && tf->tf_esp < UXSTACKTOP)
f0104352:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0104355:	8d 90 00 10 40 11    	lea    0x11401000(%eax),%edx
	{
		addr = tf->tf_esp - size;
	}
	else
	{
		addr = UXSTACKTOP - size;
f010435b:	c7 45 e4 c8 ff bf ee 	movl   $0xeebfffc8,-0x1c(%ebp)
	if (tf->tf_esp >= UXSTACKTOP-PGSIZE && tf->tf_esp < UXSTACKTOP)
f0104362:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f0104368:	77 06                	ja     f0104370 <page_fault_handler+0x64>
		addr = tf->tf_esp - size;
f010436a:	83 e8 38             	sub    $0x38,%eax
f010436d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	}
	// check the permission
	user_mem_assert(curenv,(void*)addr,size,PTE_P|PTE_W|PTE_U);
f0104370:	e8 b9 1d 00 00       	call   f010612e <cpunum>
f0104375:	6a 07                	push   $0x7
f0104377:	6a 38                	push   $0x38
f0104379:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010437c:	57                   	push   %edi
f010437d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104380:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0104386:	e8 83 ec ff ff       	call   f010300e <user_mem_assert>

	// set the attributes
	utf = (struct UTrapframe*)addr;
	utf->utf_fault_va = fault_va;
f010438b:	89 37                	mov    %esi,(%edi)
	utf->utf_eflags = tf->tf_eflags;
f010438d:	8b 43 38             	mov    0x38(%ebx),%eax
f0104390:	89 47 2c             	mov    %eax,0x2c(%edi)
	utf->utf_err = tf->tf_err;
f0104393:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0104396:	89 47 04             	mov    %eax,0x4(%edi)
	utf->utf_esp = tf->tf_esp;
f0104399:	8b 43 3c             	mov    0x3c(%ebx),%eax
f010439c:	89 47 30             	mov    %eax,0x30(%edi)
	utf->utf_eip = tf->tf_eip;
f010439f:	8b 43 30             	mov    0x30(%ebx),%eax
f01043a2:	89 47 28             	mov    %eax,0x28(%edi)
	utf->utf_regs = tf->tf_regs;
f01043a5:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f01043a8:	8d 7f 08             	lea    0x8(%edi),%edi
f01043ab:	b9 08 00 00 00       	mov    $0x8,%ecx
f01043b0:	89 de                	mov    %ebx,%esi
f01043b2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	// change the value in eip field of tf
	tf->tf_eip = (uintptr_t)curenv->env_pgfault_upcall;
f01043b4:	e8 75 1d 00 00       	call   f010612e <cpunum>
f01043b9:	6b c0 74             	imul   $0x74,%eax,%eax
f01043bc:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01043c2:	8b 40 64             	mov    0x64(%eax),%eax
f01043c5:	89 43 30             	mov    %eax,0x30(%ebx)
	tf->tf_esp = (uintptr_t)utf;
f01043c8:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01043cb:	89 53 3c             	mov    %edx,0x3c(%ebx)
	env_run(curenv);
f01043ce:	e8 5b 1d 00 00       	call   f010612e <cpunum>
f01043d3:	83 c4 04             	add    $0x4,%esp
f01043d6:	6b c0 74             	imul   $0x74,%eax,%eax
f01043d9:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f01043df:	e8 5f f3 ff ff       	call   f0103743 <env_run>
		cprintf("[%08x] user fault va %08x ip %08x\n",
f01043e4:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f01043e7:	e8 42 1d 00 00       	call   f010612e <cpunum>
		cprintf("[%08x] user fault va %08x ip %08x\n",
f01043ec:	57                   	push   %edi
f01043ed:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f01043ee:	6b c0 74             	imul   $0x74,%eax,%eax
		cprintf("[%08x] user fault va %08x ip %08x\n",
f01043f1:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01043f7:	ff 70 48             	pushl  0x48(%eax)
f01043fa:	68 a8 7e 10 f0       	push   $0xf0107ea8
f01043ff:	e8 bd f5 ff ff       	call   f01039c1 <cprintf>
		print_trapframe(tf);
f0104404:	89 1c 24             	mov    %ebx,(%esp)
f0104407:	e8 60 fd ff ff       	call   f010416c <print_trapframe>
		env_destroy(curenv);
f010440c:	e8 1d 1d 00 00       	call   f010612e <cpunum>
f0104411:	83 c4 04             	add    $0x4,%esp
f0104414:	6b c0 74             	imul   $0x74,%eax,%eax
f0104417:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f010441d:	e8 7a f2 ff ff       	call   f010369c <env_destroy>
f0104422:	83 c4 10             	add    $0x10,%esp
f0104425:	e9 28 ff ff ff       	jmp    f0104352 <page_fault_handler+0x46>

f010442a <trap>:
{
f010442a:	f3 0f 1e fb          	endbr32 
f010442e:	55                   	push   %ebp
f010442f:	89 e5                	mov    %esp,%ebp
f0104431:	57                   	push   %edi
f0104432:	56                   	push   %esi
f0104433:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::: "cc");
f0104436:	fc                   	cld    
	if (panicstr)
f0104437:	83 3d 80 7e 21 f0 00 	cmpl   $0x0,0xf0217e80
f010443e:	74 01                	je     f0104441 <trap+0x17>
		asm volatile("hlt");
f0104440:	f4                   	hlt    
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0104441:	e8 e8 1c 00 00       	call   f010612e <cpunum>
f0104446:	6b d0 74             	imul   $0x74,%eax,%edx
f0104449:	83 c2 04             	add    $0x4,%edx
	asm volatile("lock; xchgl %0, %1"
f010444c:	b8 01 00 00 00       	mov    $0x1,%eax
f0104451:	f0 87 82 20 80 21 f0 	lock xchg %eax,-0xfde7fe0(%edx)
f0104458:	83 f8 02             	cmp    $0x2,%eax
f010445b:	74 37                	je     f0104494 <trap+0x6a>
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f010445d:	9c                   	pushf  
f010445e:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
f010445f:	f6 c4 02             	test   $0x2,%ah
f0104462:	75 42                	jne    f01044a6 <trap+0x7c>
	if ((tf->tf_cs & 3) == 3) {
f0104464:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104468:	83 e0 03             	and    $0x3,%eax
f010446b:	66 83 f8 03          	cmp    $0x3,%ax
f010446f:	74 4e                	je     f01044bf <trap+0x95>
	last_tf = tf;
f0104471:	89 35 60 7a 21 f0    	mov    %esi,0xf0217a60
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0104477:	8b 46 28             	mov    0x28(%esi),%eax
f010447a:	83 f8 27             	cmp    $0x27,%eax
f010447d:	0f 84 e1 00 00 00    	je     f0104564 <trap+0x13a>
f0104483:	83 f8 30             	cmp    $0x30,%eax
f0104486:	0f 87 86 01 00 00    	ja     f0104612 <trap+0x1e8>
f010448c:	3e ff 24 85 e0 7e 10 	notrack jmp *-0xfef8120(,%eax,4)
f0104493:	f0 
	spin_lock(&kernel_lock);
f0104494:	83 ec 0c             	sub    $0xc,%esp
f0104497:	68 c0 33 12 f0       	push   $0xf01233c0
f010449c:	e8 15 1f 00 00       	call   f01063b6 <spin_lock>
}
f01044a1:	83 c4 10             	add    $0x10,%esp
f01044a4:	eb b7                	jmp    f010445d <trap+0x33>
	assert(!(read_eflags() & FL_IF));
f01044a6:	68 e2 7c 10 f0       	push   $0xf0107ce2
f01044ab:	68 27 77 10 f0       	push   $0xf0107727
f01044b0:	68 7c 01 00 00       	push   $0x17c
f01044b5:	68 d6 7c 10 f0       	push   $0xf0107cd6
f01044ba:	e8 81 bb ff ff       	call   f0100040 <_panic>
	spin_lock(&kernel_lock);
f01044bf:	83 ec 0c             	sub    $0xc,%esp
f01044c2:	68 c0 33 12 f0       	push   $0xf01233c0
f01044c7:	e8 ea 1e 00 00       	call   f01063b6 <spin_lock>
		assert(curenv);
f01044cc:	e8 5d 1c 00 00       	call   f010612e <cpunum>
f01044d1:	6b c0 74             	imul   $0x74,%eax,%eax
f01044d4:	83 c4 10             	add    $0x10,%esp
f01044d7:	83 b8 28 80 21 f0 00 	cmpl   $0x0,-0xfde7fd8(%eax)
f01044de:	74 3e                	je     f010451e <trap+0xf4>
		if (curenv->env_status == ENV_DYING) {
f01044e0:	e8 49 1c 00 00       	call   f010612e <cpunum>
f01044e5:	6b c0 74             	imul   $0x74,%eax,%eax
f01044e8:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01044ee:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f01044f2:	74 43                	je     f0104537 <trap+0x10d>
		curenv->env_tf = *tf;
f01044f4:	e8 35 1c 00 00       	call   f010612e <cpunum>
f01044f9:	6b c0 74             	imul   $0x74,%eax,%eax
f01044fc:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0104502:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104507:	89 c7                	mov    %eax,%edi
f0104509:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &curenv->env_tf;
f010450b:	e8 1e 1c 00 00       	call   f010612e <cpunum>
f0104510:	6b c0 74             	imul   $0x74,%eax,%eax
f0104513:	8b b0 28 80 21 f0    	mov    -0xfde7fd8(%eax),%esi
f0104519:	e9 53 ff ff ff       	jmp    f0104471 <trap+0x47>
		assert(curenv);
f010451e:	68 fb 7c 10 f0       	push   $0xf0107cfb
f0104523:	68 27 77 10 f0       	push   $0xf0107727
f0104528:	68 84 01 00 00       	push   $0x184
f010452d:	68 d6 7c 10 f0       	push   $0xf0107cd6
f0104532:	e8 09 bb ff ff       	call   f0100040 <_panic>
			env_free(curenv);
f0104537:	e8 f2 1b 00 00       	call   f010612e <cpunum>
f010453c:	83 ec 0c             	sub    $0xc,%esp
f010453f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104542:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0104548:	e8 a1 ef ff ff       	call   f01034ee <env_free>
			curenv = NULL;
f010454d:	e8 dc 1b 00 00       	call   f010612e <cpunum>
f0104552:	6b c0 74             	imul   $0x74,%eax,%eax
f0104555:	c7 80 28 80 21 f0 00 	movl   $0x0,-0xfde7fd8(%eax)
f010455c:	00 00 00 
			sched_yield();
f010455f:	e8 ff 02 00 00       	call   f0104863 <sched_yield>
		cprintf("Spurious interrupt on irq 7\n");
f0104564:	83 ec 0c             	sub    $0xc,%esp
f0104567:	68 02 7d 10 f0       	push   $0xf0107d02
f010456c:	e8 50 f4 ff ff       	call   f01039c1 <cprintf>
		print_trapframe(tf);
f0104571:	89 34 24             	mov    %esi,(%esp)
f0104574:	e8 f3 fb ff ff       	call   f010416c <print_trapframe>
		return;
f0104579:	83 c4 10             	add    $0x10,%esp
f010457c:	eb 15                	jmp    f0104593 <trap+0x169>
			page_fault_handler(tf);
f010457e:	83 ec 0c             	sub    $0xc,%esp
f0104581:	56                   	push   %esi
f0104582:	e8 85 fd ff ff       	call   f010430c <page_fault_handler>
			monitor(tf);
f0104587:	83 ec 0c             	sub    $0xc,%esp
f010458a:	56                   	push   %esi
f010458b:	e8 19 c4 ff ff       	call   f01009a9 <monitor>
			return;
f0104590:	83 c4 10             	add    $0x10,%esp
	if (curenv && curenv->env_status == ENV_RUNNING)
f0104593:	e8 96 1b 00 00       	call   f010612e <cpunum>
f0104598:	6b c0 74             	imul   $0x74,%eax,%eax
f010459b:	83 b8 28 80 21 f0 00 	cmpl   $0x0,-0xfde7fd8(%eax)
f01045a2:	74 18                	je     f01045bc <trap+0x192>
f01045a4:	e8 85 1b 00 00       	call   f010612e <cpunum>
f01045a9:	6b c0 74             	imul   $0x74,%eax,%eax
f01045ac:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01045b2:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01045b6:	0f 84 9e 00 00 00    	je     f010465a <trap+0x230>
		sched_yield();
f01045bc:	e8 a2 02 00 00       	call   f0104863 <sched_yield>
			monitor(tf);
f01045c1:	83 ec 0c             	sub    $0xc,%esp
f01045c4:	56                   	push   %esi
f01045c5:	e8 df c3 ff ff       	call   f01009a9 <monitor>
			return;
f01045ca:	83 c4 10             	add    $0x10,%esp
f01045cd:	eb c4                	jmp    f0104593 <trap+0x169>
			int32_t ret = syscall(regs->reg_eax,regs->reg_edx,regs->reg_ecx,regs->reg_ebx,regs->reg_edi,regs->reg_esi);
f01045cf:	83 ec 08             	sub    $0x8,%esp
f01045d2:	ff 76 04             	pushl  0x4(%esi)
f01045d5:	ff 36                	pushl  (%esi)
f01045d7:	ff 76 10             	pushl  0x10(%esi)
f01045da:	ff 76 18             	pushl  0x18(%esi)
f01045dd:	ff 76 14             	pushl  0x14(%esi)
f01045e0:	ff 76 1c             	pushl  0x1c(%esi)
f01045e3:	e8 33 03 00 00       	call   f010491b <syscall>
			regs->reg_eax = (uint32_t)ret;
f01045e8:	89 46 1c             	mov    %eax,0x1c(%esi)
			return;
f01045eb:	83 c4 20             	add    $0x20,%esp
f01045ee:	eb a3                	jmp    f0104593 <trap+0x169>
			lapic_eoi();
f01045f0:	e8 88 1c 00 00       	call   f010627d <lapic_eoi>
			sched_yield();
f01045f5:	e8 69 02 00 00       	call   f0104863 <sched_yield>
			lapic_eoi();
f01045fa:	e8 7e 1c 00 00       	call   f010627d <lapic_eoi>
			kbd_intr();
f01045ff:	e8 0e c0 ff ff       	call   f0100612 <kbd_intr>
			return;
f0104604:	eb 8d                	jmp    f0104593 <trap+0x169>
			lapic_eoi();
f0104606:	e8 72 1c 00 00       	call   f010627d <lapic_eoi>
			serial_intr();
f010460b:	e8 e2 bf ff ff       	call   f01005f2 <serial_intr>
			return;
f0104610:	eb 81                	jmp    f0104593 <trap+0x169>
	print_trapframe(tf);
f0104612:	83 ec 0c             	sub    $0xc,%esp
f0104615:	56                   	push   %esi
f0104616:	e8 51 fb ff ff       	call   f010416c <print_trapframe>
	if (tf->tf_cs == GD_KT)
f010461b:	83 c4 10             	add    $0x10,%esp
f010461e:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0104623:	74 1e                	je     f0104643 <trap+0x219>
		env_destroy(curenv);
f0104625:	e8 04 1b 00 00       	call   f010612e <cpunum>
f010462a:	83 ec 0c             	sub    $0xc,%esp
f010462d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104630:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0104636:	e8 61 f0 ff ff       	call   f010369c <env_destroy>
		return;
f010463b:	83 c4 10             	add    $0x10,%esp
f010463e:	e9 50 ff ff ff       	jmp    f0104593 <trap+0x169>
		panic("unhandled trap in kernel");
f0104643:	83 ec 04             	sub    $0x4,%esp
f0104646:	68 1f 7d 10 f0       	push   $0xf0107d1f
f010464b:	68 62 01 00 00       	push   $0x162
f0104650:	68 d6 7c 10 f0       	push   $0xf0107cd6
f0104655:	e8 e6 b9 ff ff       	call   f0100040 <_panic>
		env_run(curenv);
f010465a:	e8 cf 1a 00 00       	call   f010612e <cpunum>
f010465f:	83 ec 0c             	sub    $0xc,%esp
f0104662:	6b c0 74             	imul   $0x74,%eax,%eax
f0104665:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f010466b:	e8 d3 f0 ff ff       	call   f0103743 <env_run>

f0104670 <DIVIDE>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
 # faults and interrupts
TRAPHANDLER_NOEC(DIVIDE,T_DIVIDE)
f0104670:	6a 00                	push   $0x0
f0104672:	6a 00                	push   $0x0
f0104674:	e9 0b 01 00 00       	jmp    f0104784 <_alltraps>
f0104679:	90                   	nop

f010467a <DEBUG>:
TRAPHANDLER_NOEC(DEBUG,T_DEBUG)
f010467a:	6a 00                	push   $0x0
f010467c:	6a 01                	push   $0x1
f010467e:	e9 01 01 00 00       	jmp    f0104784 <_alltraps>
f0104683:	90                   	nop

f0104684 <NMI>:
TRAPHANDLER_NOEC(NMI, T_NMI)
f0104684:	6a 00                	push   $0x0
f0104686:	6a 02                	push   $0x2
f0104688:	e9 f7 00 00 00       	jmp    f0104784 <_alltraps>
f010468d:	90                   	nop

f010468e <BRKPT>:
TRAPHANDLER_NOEC(BRKPT, T_BRKPT)
f010468e:	6a 00                	push   $0x0
f0104690:	6a 03                	push   $0x3
f0104692:	e9 ed 00 00 00       	jmp    f0104784 <_alltraps>
f0104697:	90                   	nop

f0104698 <OFLOW>:
TRAPHANDLER_NOEC(OFLOW, T_OFLOW)
f0104698:	6a 00                	push   $0x0
f010469a:	6a 04                	push   $0x4
f010469c:	e9 e3 00 00 00       	jmp    f0104784 <_alltraps>
f01046a1:	90                   	nop

f01046a2 <BOUND>:
TRAPHANDLER_NOEC(BOUND, T_BOUND)
f01046a2:	6a 00                	push   $0x0
f01046a4:	6a 05                	push   $0x5
f01046a6:	e9 d9 00 00 00       	jmp    f0104784 <_alltraps>
f01046ab:	90                   	nop

f01046ac <ILLOP>:
TRAPHANDLER_NOEC(ILLOP, T_ILLOP)
f01046ac:	6a 00                	push   $0x0
f01046ae:	6a 06                	push   $0x6
f01046b0:	e9 cf 00 00 00       	jmp    f0104784 <_alltraps>
f01046b5:	90                   	nop

f01046b6 <DEVICE>:
TRAPHANDLER_NOEC(DEVICE, T_DEVICE)
f01046b6:	6a 00                	push   $0x0
f01046b8:	6a 07                	push   $0x7
f01046ba:	e9 c5 00 00 00       	jmp    f0104784 <_alltraps>
f01046bf:	90                   	nop

f01046c0 <DBLFLT>:
TRAPHANDLER(DBLFLT, T_DBLFLT)
f01046c0:	6a 08                	push   $0x8
f01046c2:	e9 bd 00 00 00       	jmp    f0104784 <_alltraps>
f01046c7:	90                   	nop

f01046c8 <TSS>:
TRAPHANDLER(TSS, T_TSS)
f01046c8:	6a 0a                	push   $0xa
f01046ca:	e9 b5 00 00 00       	jmp    f0104784 <_alltraps>
f01046cf:	90                   	nop

f01046d0 <SEGNP>:
TRAPHANDLER(SEGNP, T_SEGNP)
f01046d0:	6a 0b                	push   $0xb
f01046d2:	e9 ad 00 00 00       	jmp    f0104784 <_alltraps>
f01046d7:	90                   	nop

f01046d8 <STACK>:
TRAPHANDLER(STACK, T_STACK)
f01046d8:	6a 0c                	push   $0xc
f01046da:	e9 a5 00 00 00       	jmp    f0104784 <_alltraps>
f01046df:	90                   	nop

f01046e0 <GPFLT>:
TRAPHANDLER(GPFLT, T_GPFLT)
f01046e0:	6a 0d                	push   $0xd
f01046e2:	e9 9d 00 00 00       	jmp    f0104784 <_alltraps>
f01046e7:	90                   	nop

f01046e8 <PGFLT>:
TRAPHANDLER(PGFLT, T_PGFLT)
f01046e8:	6a 0e                	push   $0xe
f01046ea:	e9 95 00 00 00       	jmp    f0104784 <_alltraps>
f01046ef:	90                   	nop

f01046f0 <FPERR>:
TRAPHANDLER_NOEC(FPERR, T_FPERR)
f01046f0:	6a 00                	push   $0x0
f01046f2:	6a 10                	push   $0x10
f01046f4:	e9 8b 00 00 00       	jmp    f0104784 <_alltraps>
f01046f9:	90                   	nop

f01046fa <ALIGN>:
TRAPHANDLER(ALIGN, T_ALIGN)
f01046fa:	6a 11                	push   $0x11
f01046fc:	e9 83 00 00 00       	jmp    f0104784 <_alltraps>
f0104701:	90                   	nop

f0104702 <MCHK>:
TRAPHANDLER_NOEC(MCHK, T_MCHK)
f0104702:	6a 00                	push   $0x0
f0104704:	6a 12                	push   $0x12
f0104706:	eb 7c                	jmp    f0104784 <_alltraps>

f0104708 <SIMDERR>:
TRAPHANDLER_NOEC(SIMDERR, T_SIMDERR)
f0104708:	6a 00                	push   $0x0
f010470a:	6a 13                	push   $0x13
f010470c:	eb 76                	jmp    f0104784 <_alltraps>

f010470e <SYSCALL>:
TRAPHANDLER_NOEC(SYSCALL, T_SYSCALL)
f010470e:	6a 00                	push   $0x0
f0104710:	6a 30                	push   $0x30
f0104712:	eb 70                	jmp    f0104784 <_alltraps>

f0104714 <DEFAULT>:
TRAPHANDLER_NOEC(DEFAULT, T_DEFAULT)
f0104714:	6a 00                	push   $0x0
f0104716:	68 f4 01 00 00       	push   $0x1f4
f010471b:	eb 67                	jmp    f0104784 <_alltraps>
f010471d:	90                   	nop

f010471e <IRQsHandler0>:
# IRQs
TRAPHANDLER_NOEC(IRQsHandler0, IRQ_OFFSET+IRQ_TIMER)
f010471e:	6a 00                	push   $0x0
f0104720:	6a 20                	push   $0x20
f0104722:	eb 60                	jmp    f0104784 <_alltraps>

f0104724 <IRQsHandler1>:
TRAPHANDLER_NOEC(IRQsHandler1, IRQ_OFFSET+IRQ_KBD)
f0104724:	6a 00                	push   $0x0
f0104726:	6a 21                	push   $0x21
f0104728:	eb 5a                	jmp    f0104784 <_alltraps>

f010472a <IRQsHandler2>:
TRAPHANDLER_NOEC(IRQsHandler2, IRQ_OFFSET+IRQ_SLAVE)
f010472a:	6a 00                	push   $0x0
f010472c:	6a 22                	push   $0x22
f010472e:	eb 54                	jmp    f0104784 <_alltraps>

f0104730 <IRQsHandler3>:
TRAPHANDLER_NOEC(IRQsHandler3, IRQ_OFFSET+3)
f0104730:	6a 00                	push   $0x0
f0104732:	6a 23                	push   $0x23
f0104734:	eb 4e                	jmp    f0104784 <_alltraps>

f0104736 <IRQsHandler4>:
TRAPHANDLER_NOEC(IRQsHandler4, IRQ_OFFSET+IRQ_SERIAL)
f0104736:	6a 00                	push   $0x0
f0104738:	6a 24                	push   $0x24
f010473a:	eb 48                	jmp    f0104784 <_alltraps>

f010473c <IRQsHandler5>:
TRAPHANDLER_NOEC(IRQsHandler5, IRQ_OFFSET+5)
f010473c:	6a 00                	push   $0x0
f010473e:	6a 25                	push   $0x25
f0104740:	eb 42                	jmp    f0104784 <_alltraps>

f0104742 <IRQsHandler6>:
TRAPHANDLER_NOEC(IRQsHandler6, IRQ_OFFSET+6)
f0104742:	6a 00                	push   $0x0
f0104744:	6a 26                	push   $0x26
f0104746:	eb 3c                	jmp    f0104784 <_alltraps>

f0104748 <IRQsHandler7>:
TRAPHANDLER_NOEC(IRQsHandler7, IRQ_OFFSET+IRQ_SPURIOUS)
f0104748:	6a 00                	push   $0x0
f010474a:	6a 27                	push   $0x27
f010474c:	eb 36                	jmp    f0104784 <_alltraps>

f010474e <IRQsHandler8>:
TRAPHANDLER_NOEC(IRQsHandler8, IRQ_OFFSET+8)
f010474e:	6a 00                	push   $0x0
f0104750:	6a 28                	push   $0x28
f0104752:	eb 30                	jmp    f0104784 <_alltraps>

f0104754 <IRQsHandler9>:
TRAPHANDLER_NOEC(IRQsHandler9, IRQ_OFFSET+9)
f0104754:	6a 00                	push   $0x0
f0104756:	6a 29                	push   $0x29
f0104758:	eb 2a                	jmp    f0104784 <_alltraps>

f010475a <IRQsHandler10>:
TRAPHANDLER_NOEC(IRQsHandler10, IRQ_OFFSET+10)
f010475a:	6a 00                	push   $0x0
f010475c:	6a 2a                	push   $0x2a
f010475e:	eb 24                	jmp    f0104784 <_alltraps>

f0104760 <IRQsHandler11>:
TRAPHANDLER_NOEC(IRQsHandler11, IRQ_OFFSET+11)
f0104760:	6a 00                	push   $0x0
f0104762:	6a 2b                	push   $0x2b
f0104764:	eb 1e                	jmp    f0104784 <_alltraps>

f0104766 <IRQsHandler12>:
TRAPHANDLER_NOEC(IRQsHandler12, IRQ_OFFSET+12)
f0104766:	6a 00                	push   $0x0
f0104768:	6a 2c                	push   $0x2c
f010476a:	eb 18                	jmp    f0104784 <_alltraps>

f010476c <IRQsHandler13>:
TRAPHANDLER_NOEC(IRQsHandler13, IRQ_OFFSET+13)
f010476c:	6a 00                	push   $0x0
f010476e:	6a 2d                	push   $0x2d
f0104770:	eb 12                	jmp    f0104784 <_alltraps>

f0104772 <IRQsHandler14>:
TRAPHANDLER_NOEC(IRQsHandler14, IRQ_OFFSET+IRQ_IDE)
f0104772:	6a 00                	push   $0x0
f0104774:	6a 2e                	push   $0x2e
f0104776:	eb 0c                	jmp    f0104784 <_alltraps>

f0104778 <IRQsHandler15>:
TRAPHANDLER_NOEC(IRQsHandler15, IRQ_OFFSET+15)
f0104778:	6a 00                	push   $0x0
f010477a:	6a 2f                	push   $0x2f
f010477c:	eb 06                	jmp    f0104784 <_alltraps>

f010477e <IRQsHandler19>:
; TRAPHANDLER_NOEC(IRQsHandler19, IRQ_OFFSET+IRQ_ERROR)
f010477e:	6a 00                	push   $0x0
f0104780:	6a 33                	push   $0x33
f0104782:	eb 00                	jmp    f0104784 <_alltraps>

f0104784 <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */
 .global _alltraps
 _alltraps:
 /* code below according to the guide */
pushl %ds
f0104784:	1e                   	push   %ds
pushl %es
f0104785:	06                   	push   %es
pushal
f0104786:	60                   	pusha  
movw $GD_KD, %ax
f0104787:	66 b8 10 00          	mov    $0x10,%ax
movw %ax, %ds
f010478b:	8e d8                	mov    %eax,%ds
movw %ax, %es
f010478d:	8e c0                	mov    %eax,%es
pushl %esp
f010478f:	54                   	push   %esp
call trap
f0104790:	e8 95 fc ff ff       	call   f010442a <trap>

f0104795 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104795:	f3 0f 1e fb          	endbr32 
f0104799:	55                   	push   %ebp
f010479a:	89 e5                	mov    %esp,%ebp
f010479c:	83 ec 08             	sub    $0x8,%esp
f010479f:	a1 48 72 21 f0       	mov    0xf0217248,%eax
f01047a4:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f01047a7:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f01047ac:	8b 02                	mov    (%edx),%eax
f01047ae:	83 e8 01             	sub    $0x1,%eax
		if ((envs[i].env_status == ENV_RUNNABLE ||
f01047b1:	83 f8 02             	cmp    $0x2,%eax
f01047b4:	76 2d                	jbe    f01047e3 <sched_halt+0x4e>
	for (i = 0; i < NENV; i++) {
f01047b6:	83 c1 01             	add    $0x1,%ecx
f01047b9:	83 c2 7c             	add    $0x7c,%edx
f01047bc:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f01047c2:	75 e8                	jne    f01047ac <sched_halt+0x17>
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
		cprintf("No runnable environments in the system!\n");
f01047c4:	83 ec 0c             	sub    $0xc,%esp
f01047c7:	68 10 80 10 f0       	push   $0xf0108010
f01047cc:	e8 f0 f1 ff ff       	call   f01039c1 <cprintf>
f01047d1:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f01047d4:	83 ec 0c             	sub    $0xc,%esp
f01047d7:	6a 00                	push   $0x0
f01047d9:	e8 cb c1 ff ff       	call   f01009a9 <monitor>
f01047de:	83 c4 10             	add    $0x10,%esp
f01047e1:	eb f1                	jmp    f01047d4 <sched_halt+0x3f>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f01047e3:	e8 46 19 00 00       	call   f010612e <cpunum>
f01047e8:	6b c0 74             	imul   $0x74,%eax,%eax
f01047eb:	c7 80 28 80 21 f0 00 	movl   $0x0,-0xfde7fd8(%eax)
f01047f2:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f01047f5:	a1 8c 7e 21 f0       	mov    0xf0217e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01047fa:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01047ff:	76 50                	jbe    f0104851 <sched_halt+0xbc>
	return (physaddr_t)kva - KERNBASE;
f0104801:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0104806:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0104809:	e8 20 19 00 00       	call   f010612e <cpunum>
f010480e:	6b d0 74             	imul   $0x74,%eax,%edx
f0104811:	83 c2 04             	add    $0x4,%edx
	asm volatile("lock; xchgl %0, %1"
f0104814:	b8 02 00 00 00       	mov    $0x2,%eax
f0104819:	f0 87 82 20 80 21 f0 	lock xchg %eax,-0xfde7fe0(%edx)
	spin_unlock(&kernel_lock);
f0104820:	83 ec 0c             	sub    $0xc,%esp
f0104823:	68 c0 33 12 f0       	push   $0xf01233c0
f0104828:	e8 27 1c 00 00       	call   f0106454 <spin_unlock>
	asm volatile("pause");
f010482d:	f3 90                	pause  
		// Uncomment the following line after completing exercise 13
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f010482f:	e8 fa 18 00 00       	call   f010612e <cpunum>
f0104834:	6b c0 74             	imul   $0x74,%eax,%eax
	asm volatile (
f0104837:	8b 80 30 80 21 f0    	mov    -0xfde7fd0(%eax),%eax
f010483d:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104842:	89 c4                	mov    %eax,%esp
f0104844:	6a 00                	push   $0x0
f0104846:	6a 00                	push   $0x0
f0104848:	fb                   	sti    
f0104849:	f4                   	hlt    
f010484a:	eb fd                	jmp    f0104849 <sched_halt+0xb4>
}
f010484c:	83 c4 10             	add    $0x10,%esp
f010484f:	c9                   	leave  
f0104850:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104851:	50                   	push   %eax
f0104852:	68 e8 67 10 f0       	push   $0xf01067e8
f0104857:	6a 56                	push   $0x56
f0104859:	68 39 80 10 f0       	push   $0xf0108039
f010485e:	e8 dd b7 ff ff       	call   f0100040 <_panic>

f0104863 <sched_yield>:
{
f0104863:	f3 0f 1e fb          	endbr32 
f0104867:	55                   	push   %ebp
f0104868:	89 e5                	mov    %esp,%ebp
f010486a:	56                   	push   %esi
f010486b:	53                   	push   %ebx
	if(curenv)
f010486c:	e8 bd 18 00 00       	call   f010612e <cpunum>
f0104871:	6b c0 74             	imul   $0x74,%eax,%eax
	int begin = 0;
f0104874:	b9 00 00 00 00       	mov    $0x0,%ecx
	if(curenv)
f0104879:	83 b8 28 80 21 f0 00 	cmpl   $0x0,-0xfde7fd8(%eax)
f0104880:	74 17                	je     f0104899 <sched_yield+0x36>
		begin = ENVX(curenv->env_id);
f0104882:	e8 a7 18 00 00       	call   f010612e <cpunum>
f0104887:	6b c0 74             	imul   $0x74,%eax,%eax
f010488a:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0104890:	8b 48 48             	mov    0x48(%eax),%ecx
f0104893:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
		idle = &envs[(i+begin)%NENV];
f0104899:	8b 1d 48 72 21 f0    	mov    0xf0217248,%ebx
f010489f:	89 ca                	mov    %ecx,%edx
f01048a1:	81 c1 00 04 00 00    	add    $0x400,%ecx
f01048a7:	89 d6                	mov    %edx,%esi
f01048a9:	c1 fe 1f             	sar    $0x1f,%esi
f01048ac:	c1 ee 16             	shr    $0x16,%esi
f01048af:	8d 04 32             	lea    (%edx,%esi,1),%eax
f01048b2:	25 ff 03 00 00       	and    $0x3ff,%eax
f01048b7:	29 f0                	sub    %esi,%eax
f01048b9:	6b c0 7c             	imul   $0x7c,%eax,%eax
f01048bc:	01 d8                	add    %ebx,%eax
		if(idle->env_status == ENV_RUNNABLE)
f01048be:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f01048c2:	74 38                	je     f01048fc <sched_yield+0x99>
f01048c4:	83 c2 01             	add    $0x1,%edx
	for(int i = 0;i<NENV;i++)
f01048c7:	39 ca                	cmp    %ecx,%edx
f01048c9:	75 dc                	jne    f01048a7 <sched_yield+0x44>
	if(!flag && curenv && curenv->env_status == ENV_RUNNING)
f01048cb:	e8 5e 18 00 00       	call   f010612e <cpunum>
f01048d0:	6b c0 74             	imul   $0x74,%eax,%eax
f01048d3:	83 b8 28 80 21 f0 00 	cmpl   $0x0,-0xfde7fd8(%eax)
f01048da:	74 14                	je     f01048f0 <sched_yield+0x8d>
f01048dc:	e8 4d 18 00 00       	call   f010612e <cpunum>
f01048e1:	6b c0 74             	imul   $0x74,%eax,%eax
f01048e4:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01048ea:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01048ee:	74 15                	je     f0104905 <sched_yield+0xa2>
		sched_halt();
f01048f0:	e8 a0 fe ff ff       	call   f0104795 <sched_halt>
}
f01048f5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01048f8:	5b                   	pop    %ebx
f01048f9:	5e                   	pop    %esi
f01048fa:	5d                   	pop    %ebp
f01048fb:	c3                   	ret    
			env_run(idle);
f01048fc:	83 ec 0c             	sub    $0xc,%esp
f01048ff:	50                   	push   %eax
f0104900:	e8 3e ee ff ff       	call   f0103743 <env_run>
		env_run(curenv);
f0104905:	e8 24 18 00 00       	call   f010612e <cpunum>
f010490a:	83 ec 0c             	sub    $0xc,%esp
f010490d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104910:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0104916:	e8 28 ee ff ff       	call   f0103743 <env_run>

f010491b <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f010491b:	f3 0f 1e fb          	endbr32 
f010491f:	55                   	push   %ebp
f0104920:	89 e5                	mov    %esp,%ebp
f0104922:	57                   	push   %edi
f0104923:	56                   	push   %esi
f0104924:	53                   	push   %ebx
f0104925:	83 ec 1c             	sub    $0x1c,%esp
f0104928:	8b 45 08             	mov    0x8(%ebp),%eax
f010492b:	8b 7d 10             	mov    0x10(%ebp),%edi
f010492e:	83 f8 0e             	cmp    $0xe,%eax
f0104931:	77 08                	ja     f010493b <syscall+0x20>
f0104933:	3e ff 24 85 4c 80 10 	notrack jmp *-0xfef7fb4(,%eax,4)
f010493a:	f0 
	switch (syscallno) 
	{
		case SYS_cputs:
		{
			sys_cputs((const char*)a1,(size_t)a2);
			return 0;
f010493b:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104940:	e9 87 05 00 00       	jmp    f0104ecc <syscall+0x5b1>
	user_mem_assert(curenv,s,len,0);
f0104945:	e8 e4 17 00 00       	call   f010612e <cpunum>
f010494a:	6a 00                	push   $0x0
f010494c:	57                   	push   %edi
f010494d:	ff 75 0c             	pushl  0xc(%ebp)
f0104950:	6b c0 74             	imul   $0x74,%eax,%eax
f0104953:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0104959:	e8 b0 e6 ff ff       	call   f010300e <user_mem_assert>
	cprintf("%.*s", len, s);
f010495e:	83 c4 0c             	add    $0xc,%esp
f0104961:	ff 75 0c             	pushl  0xc(%ebp)
f0104964:	57                   	push   %edi
f0104965:	68 46 80 10 f0       	push   $0xf0108046
f010496a:	e8 52 f0 ff ff       	call   f01039c1 <cprintf>
}
f010496f:	83 c4 10             	add    $0x10,%esp
			return 0;
f0104972:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0104977:	e9 50 05 00 00       	jmp    f0104ecc <syscall+0x5b1>
	return cons_getc();
f010497c:	e8 a7 bc ff ff       	call   f0100628 <cons_getc>
f0104981:	89 c3                	mov    %eax,%ebx
		}
		case SYS_cgetc:
		{
			return sys_cgetc();
f0104983:	e9 44 05 00 00       	jmp    f0104ecc <syscall+0x5b1>
	if ((r = envid2env(envid, &e, 1)) < 0)
f0104988:	83 ec 04             	sub    $0x4,%esp
f010498b:	6a 01                	push   $0x1
f010498d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104990:	50                   	push   %eax
f0104991:	ff 75 0c             	pushl  0xc(%ebp)
f0104994:	e8 66 e7 ff ff       	call   f01030ff <envid2env>
f0104999:	89 c3                	mov    %eax,%ebx
f010499b:	83 c4 10             	add    $0x10,%esp
f010499e:	85 c0                	test   %eax,%eax
f01049a0:	0f 88 26 05 00 00    	js     f0104ecc <syscall+0x5b1>
	env_destroy(e);
f01049a6:	83 ec 0c             	sub    $0xc,%esp
f01049a9:	ff 75 e4             	pushl  -0x1c(%ebp)
f01049ac:	e8 eb ec ff ff       	call   f010369c <env_destroy>
	return 0;
f01049b1:	83 c4 10             	add    $0x10,%esp
f01049b4:	bb 00 00 00 00       	mov    $0x0,%ebx
		}
		case SYS_env_destroy:
		{
			return sys_env_destroy((envid_t)a1);
f01049b9:	e9 0e 05 00 00       	jmp    f0104ecc <syscall+0x5b1>
	return curenv->env_id;
f01049be:	e8 6b 17 00 00       	call   f010612e <cpunum>
f01049c3:	6b c0 74             	imul   $0x74,%eax,%eax
f01049c6:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01049cc:	8b 58 48             	mov    0x48(%eax),%ebx
		{
			return 0;
		}
		case SYS_getenvid:
		{
			return sys_getenvid();
f01049cf:	e9 f8 04 00 00       	jmp    f0104ecc <syscall+0x5b1>
	sched_yield();
f01049d4:	e8 8a fe ff ff       	call   f0104863 <sched_yield>
	struct Env* store_env = NULL;
f01049d9:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = env_alloc(&store_env,curenv->env_id);
f01049e0:	e8 49 17 00 00       	call   f010612e <cpunum>
f01049e5:	83 ec 08             	sub    $0x8,%esp
f01049e8:	6b c0 74             	imul   $0x74,%eax,%eax
f01049eb:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f01049f1:	ff 70 48             	pushl  0x48(%eax)
f01049f4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01049f7:	50                   	push   %eax
f01049f8:	e8 17 e8 ff ff       	call   f0103214 <env_alloc>
f01049fd:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f01049ff:	83 c4 10             	add    $0x10,%esp
f0104a02:	85 c0                	test   %eax,%eax
f0104a04:	0f 88 c2 04 00 00    	js     f0104ecc <syscall+0x5b1>
	store_env->env_status = ENV_NOT_RUNNABLE;
f0104a0a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a0d:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	memmove(&store_env->env_tf,&curenv->env_tf,sizeof(curenv->env_tf));
f0104a14:	e8 15 17 00 00       	call   f010612e <cpunum>
f0104a19:	83 ec 04             	sub    $0x4,%esp
f0104a1c:	6a 44                	push   $0x44
f0104a1e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a21:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0104a27:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104a2a:	e8 2d 11 00 00       	call   f0105b5c <memmove>
	store_env->env_tf.tf_regs.reg_eax = 0;
f0104a2f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a32:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return store_env->env_id;
f0104a39:	8b 58 48             	mov    0x48(%eax),%ebx
f0104a3c:	83 c4 10             	add    $0x10,%esp
			sys_yield();
			return 0;
		}
		case SYS_exofork:
		{
			return sys_exofork();
f0104a3f:	e9 88 04 00 00       	jmp    f0104ecc <syscall+0x5b1>
	if(status != ENV_NOT_RUNNABLE && status!= ENV_RUNNABLE)
f0104a44:	8d 47 fe             	lea    -0x2(%edi),%eax
f0104a47:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f0104a4c:	75 35                	jne    f0104a83 <syscall+0x168>
	struct Env* e = NULL;
f0104a4e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f0104a55:	83 ec 04             	sub    $0x4,%esp
f0104a58:	6a 01                	push   $0x1
f0104a5a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104a5d:	50                   	push   %eax
f0104a5e:	ff 75 0c             	pushl  0xc(%ebp)
f0104a61:	e8 99 e6 ff ff       	call   f01030ff <envid2env>
f0104a66:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104a68:	83 c4 10             	add    $0x10,%esp
f0104a6b:	85 c0                	test   %eax,%eax
f0104a6d:	0f 88 59 04 00 00    	js     f0104ecc <syscall+0x5b1>
	e->env_status = status;
f0104a73:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a76:	89 78 54             	mov    %edi,0x54(%eax)
	return 0;
f0104a79:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104a7e:	e9 49 04 00 00       	jmp    f0104ecc <syscall+0x5b1>
		return -E_INVAL;
f0104a83:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		}
		case SYS_env_set_status:
		{
			return sys_env_set_status((envid_t)a1,(int)a2);
f0104a88:	e9 3f 04 00 00       	jmp    f0104ecc <syscall+0x5b1>
	if((uintptr_t)va >= UTOP || (uintptr_t)va % PGSIZE)
f0104a8d:	81 ff ff ff bf ee    	cmp    $0xeebfffff,%edi
f0104a93:	77 7c                	ja     f0104b11 <syscall+0x1f6>
f0104a95:	89 fb                	mov    %edi,%ebx
f0104a97:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
	if((perm & ~(PTE_SYSCALL)) || ((perm & needed_perm) == 0))
f0104a9d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104aa0:	25 f8 f1 ff ff       	and    $0xfffff1f8,%eax
f0104aa5:	09 c3                	or     %eax,%ebx
f0104aa7:	75 72                	jne    f0104b1b <syscall+0x200>
f0104aa9:	f6 45 14 05          	testb  $0x5,0x14(%ebp)
f0104aad:	74 76                	je     f0104b25 <syscall+0x20a>
	struct Env* e = NULL;
f0104aaf:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f0104ab6:	83 ec 04             	sub    $0x4,%esp
f0104ab9:	6a 01                	push   $0x1
f0104abb:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104abe:	50                   	push   %eax
f0104abf:	ff 75 0c             	pushl  0xc(%ebp)
f0104ac2:	e8 38 e6 ff ff       	call   f01030ff <envid2env>
	if(ret<0)
f0104ac7:	83 c4 10             	add    $0x10,%esp
f0104aca:	85 c0                	test   %eax,%eax
f0104acc:	78 61                	js     f0104b2f <syscall+0x214>
	struct PageInfo* pg = page_alloc(ALLOC_ZERO);
f0104ace:	83 ec 0c             	sub    $0xc,%esp
f0104ad1:	6a 01                	push   $0x1
f0104ad3:	e8 f3 c4 ff ff       	call   f0100fcb <page_alloc>
f0104ad8:	89 c6                	mov    %eax,%esi
	if(!pg)
f0104ada:	83 c4 10             	add    $0x10,%esp
f0104add:	85 c0                	test   %eax,%eax
f0104adf:	74 55                	je     f0104b36 <syscall+0x21b>
	ret = page_insert(e->env_pgdir,pg,va,perm);
f0104ae1:	ff 75 14             	pushl  0x14(%ebp)
f0104ae4:	57                   	push   %edi
f0104ae5:	50                   	push   %eax
f0104ae6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104ae9:	ff 70 60             	pushl  0x60(%eax)
f0104aec:	e8 8f c7 ff ff       	call   f0101280 <page_insert>
f0104af1:	89 c7                	mov    %eax,%edi
	if(ret < 0)
f0104af3:	83 c4 10             	add    $0x10,%esp
f0104af6:	85 c0                	test   %eax,%eax
f0104af8:	0f 89 ce 03 00 00    	jns    f0104ecc <syscall+0x5b1>
		page_free(pg);
f0104afe:	83 ec 0c             	sub    $0xc,%esp
f0104b01:	56                   	push   %esi
f0104b02:	e8 3d c5 ff ff       	call   f0101044 <page_free>
		return ret;
f0104b07:	83 c4 10             	add    $0x10,%esp
f0104b0a:	89 fb                	mov    %edi,%ebx
f0104b0c:	e9 bb 03 00 00       	jmp    f0104ecc <syscall+0x5b1>
		return -E_INVAL;
f0104b11:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104b16:	e9 b1 03 00 00       	jmp    f0104ecc <syscall+0x5b1>
		return -E_INVAL;
f0104b1b:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104b20:	e9 a7 03 00 00       	jmp    f0104ecc <syscall+0x5b1>
f0104b25:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104b2a:	e9 9d 03 00 00       	jmp    f0104ecc <syscall+0x5b1>
		return ret;
f0104b2f:	89 c3                	mov    %eax,%ebx
f0104b31:	e9 96 03 00 00       	jmp    f0104ecc <syscall+0x5b1>
		return -E_NO_MEM;
f0104b36:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
		}
		case SYS_page_alloc:
		{
			return sys_page_alloc((envid_t)a1,(void*)a2,(int)a3);
f0104b3b:	e9 8c 03 00 00       	jmp    f0104ecc <syscall+0x5b1>
	if((uintptr_t)srcva>=UTOP || (uintptr_t)srcva % PGSIZE 
f0104b40:	81 ff ff ff bf ee    	cmp    $0xeebfffff,%edi
f0104b46:	0f 87 cf 00 00 00    	ja     f0104c1b <syscall+0x300>
	|| (uintptr_t)dstva>=UTOP || (uintptr_t)dstva % PGSIZE)
f0104b4c:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104b53:	0f 87 cc 00 00 00    	ja     f0104c25 <syscall+0x30a>
	if((perm & ~(PTE_SYSCALL)) || ((perm & needed_perm) == 0))
f0104b59:	89 f8                	mov    %edi,%eax
f0104b5b:	0b 45 18             	or     0x18(%ebp),%eax
f0104b5e:	25 ff 0f 00 00       	and    $0xfff,%eax
f0104b63:	8b 55 1c             	mov    0x1c(%ebp),%edx
f0104b66:	81 e2 f8 f1 ff ff    	and    $0xfffff1f8,%edx
f0104b6c:	09 d0                	or     %edx,%eax
f0104b6e:	0f 85 bb 00 00 00    	jne    f0104c2f <syscall+0x314>
f0104b74:	f6 45 1c 05          	testb  $0x5,0x1c(%ebp)
f0104b78:	0f 84 bb 00 00 00    	je     f0104c39 <syscall+0x31e>
	struct Env* srce = NULL, *dste = NULL;
f0104b7e:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0104b85:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	int ret = envid2env(srcenvid,&srce,true);
f0104b8c:	83 ec 04             	sub    $0x4,%esp
f0104b8f:	6a 01                	push   $0x1
f0104b91:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0104b94:	50                   	push   %eax
f0104b95:	ff 75 0c             	pushl  0xc(%ebp)
f0104b98:	e8 62 e5 ff ff       	call   f01030ff <envid2env>
f0104b9d:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104b9f:	83 c4 10             	add    $0x10,%esp
f0104ba2:	85 c0                	test   %eax,%eax
f0104ba4:	0f 88 22 03 00 00    	js     f0104ecc <syscall+0x5b1>
	ret = envid2env(dstenvid,&dste,true);
f0104baa:	83 ec 04             	sub    $0x4,%esp
f0104bad:	6a 01                	push   $0x1
f0104baf:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104bb2:	50                   	push   %eax
f0104bb3:	ff 75 14             	pushl  0x14(%ebp)
f0104bb6:	e8 44 e5 ff ff       	call   f01030ff <envid2env>
f0104bbb:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104bbd:	83 c4 10             	add    $0x10,%esp
f0104bc0:	85 c0                	test   %eax,%eax
f0104bc2:	0f 88 04 03 00 00    	js     f0104ecc <syscall+0x5b1>
	pte_t* pte = NULL;
f0104bc8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	struct PageInfo* pg = page_lookup(srce->env_pgdir,srcva,&pte);
f0104bcf:	83 ec 04             	sub    $0x4,%esp
f0104bd2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104bd5:	50                   	push   %eax
f0104bd6:	57                   	push   %edi
f0104bd7:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104bda:	ff 70 60             	pushl  0x60(%eax)
f0104bdd:	e8 ab c5 ff ff       	call   f010118d <page_lookup>
	if(!pg)
f0104be2:	83 c4 10             	add    $0x10,%esp
f0104be5:	85 c0                	test   %eax,%eax
f0104be7:	74 5a                	je     f0104c43 <syscall+0x328>
	if(((*pte) & PTE_W) == 0 && (perm & PTE_W))
f0104be9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104bec:	f6 02 02             	testb  $0x2,(%edx)
f0104bef:	75 06                	jne    f0104bf7 <syscall+0x2dc>
f0104bf1:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104bf5:	75 56                	jne    f0104c4d <syscall+0x332>
	ret = page_insert(dste->env_pgdir,pg,dstva,perm);
f0104bf7:	ff 75 1c             	pushl  0x1c(%ebp)
f0104bfa:	ff 75 18             	pushl  0x18(%ebp)
f0104bfd:	50                   	push   %eax
f0104bfe:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104c01:	ff 70 60             	pushl  0x60(%eax)
f0104c04:	e8 77 c6 ff ff       	call   f0101280 <page_insert>
f0104c09:	83 c4 10             	add    $0x10,%esp
f0104c0c:	85 c0                	test   %eax,%eax
f0104c0e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104c13:	0f 4e d8             	cmovle %eax,%ebx
f0104c16:	e9 b1 02 00 00       	jmp    f0104ecc <syscall+0x5b1>
		return -E_INVAL;
f0104c1b:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104c20:	e9 a7 02 00 00       	jmp    f0104ecc <syscall+0x5b1>
f0104c25:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104c2a:	e9 9d 02 00 00       	jmp    f0104ecc <syscall+0x5b1>
		return -E_INVAL;
f0104c2f:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104c34:	e9 93 02 00 00       	jmp    f0104ecc <syscall+0x5b1>
f0104c39:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104c3e:	e9 89 02 00 00       	jmp    f0104ecc <syscall+0x5b1>
		return -E_INVAL;
f0104c43:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104c48:	e9 7f 02 00 00       	jmp    f0104ecc <syscall+0x5b1>
		return -E_INVAL;
f0104c4d:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		}
		case SYS_page_map:
		{
			return sys_page_map((envid_t)a1,(void*)a2,(envid_t)a3,(void*)a4,(int)a5);
f0104c52:	e9 75 02 00 00       	jmp    f0104ecc <syscall+0x5b1>
	if((uintptr_t)va >= UTOP || (uintptr_t)va % PGSIZE)
f0104c57:	81 ff ff ff bf ee    	cmp    $0xeebfffff,%edi
f0104c5d:	77 49                	ja     f0104ca8 <syscall+0x38d>
f0104c5f:	f7 c7 ff 0f 00 00    	test   $0xfff,%edi
f0104c65:	75 4b                	jne    f0104cb2 <syscall+0x397>
	struct Env* e = NULL;
f0104c67:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f0104c6e:	83 ec 04             	sub    $0x4,%esp
f0104c71:	6a 01                	push   $0x1
f0104c73:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104c76:	50                   	push   %eax
f0104c77:	ff 75 0c             	pushl  0xc(%ebp)
f0104c7a:	e8 80 e4 ff ff       	call   f01030ff <envid2env>
f0104c7f:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104c81:	83 c4 10             	add    $0x10,%esp
f0104c84:	85 c0                	test   %eax,%eax
f0104c86:	0f 88 40 02 00 00    	js     f0104ecc <syscall+0x5b1>
	page_remove(e->env_pgdir,va);
f0104c8c:	83 ec 08             	sub    $0x8,%esp
f0104c8f:	57                   	push   %edi
f0104c90:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104c93:	ff 70 60             	pushl  0x60(%eax)
f0104c96:	e8 94 c5 ff ff       	call   f010122f <page_remove>
	return 0;
f0104c9b:	83 c4 10             	add    $0x10,%esp
f0104c9e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104ca3:	e9 24 02 00 00       	jmp    f0104ecc <syscall+0x5b1>
		return -E_INVAL;
f0104ca8:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104cad:	e9 1a 02 00 00       	jmp    f0104ecc <syscall+0x5b1>
f0104cb2:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		}
		case SYS_page_unmap:
		{
			return sys_page_unmap((envid_t)a1,(void*)a2);
f0104cb7:	e9 10 02 00 00       	jmp    f0104ecc <syscall+0x5b1>
	struct Env* e = NULL;
f0104cbc:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f0104cc3:	83 ec 04             	sub    $0x4,%esp
f0104cc6:	6a 01                	push   $0x1
f0104cc8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104ccb:	50                   	push   %eax
f0104ccc:	ff 75 0c             	pushl  0xc(%ebp)
f0104ccf:	e8 2b e4 ff ff       	call   f01030ff <envid2env>
f0104cd4:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104cd6:	83 c4 10             	add    $0x10,%esp
f0104cd9:	85 c0                	test   %eax,%eax
f0104cdb:	0f 88 eb 01 00 00    	js     f0104ecc <syscall+0x5b1>
	e->env_pgfault_upcall = func;
f0104ce1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104ce4:	89 78 64             	mov    %edi,0x64(%eax)
	return 0;
f0104ce7:	bb 00 00 00 00       	mov    $0x0,%ebx
		}
		case SYS_env_set_pgfault_upcall:
		{
			return sys_env_set_pgfault_upcall((envid_t)a1,(void*)a2);
f0104cec:	e9 db 01 00 00       	jmp    f0104ecc <syscall+0x5b1>
	struct Env* dst = NULL;
f0104cf1:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	if((ret = envid2env(envid,&dst,false)) < 0)
f0104cf8:	83 ec 04             	sub    $0x4,%esp
f0104cfb:	6a 00                	push   $0x0
f0104cfd:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104d00:	50                   	push   %eax
f0104d01:	ff 75 0c             	pushl  0xc(%ebp)
f0104d04:	e8 f6 e3 ff ff       	call   f01030ff <envid2env>
f0104d09:	89 c3                	mov    %eax,%ebx
f0104d0b:	83 c4 10             	add    $0x10,%esp
f0104d0e:	85 c0                	test   %eax,%eax
f0104d10:	0f 88 b6 01 00 00    	js     f0104ecc <syscall+0x5b1>
	if(!dst->env_ipc_recving)
f0104d16:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104d19:	80 78 68 00          	cmpb   $0x0,0x68(%eax)
f0104d1d:	0f 84 e4 00 00 00    	je     f0104e07 <syscall+0x4ec>
	if((uintptr_t)srcva >=UTOP)
f0104d23:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f0104d2a:	0f 87 95 00 00 00    	ja     f0104dc5 <syscall+0x4aa>
			return -E_INVAL;
f0104d30:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		if(((perm_needed & perm) == 0) || (perm & (~PTE_SYSCALL)))
f0104d35:	f6 45 18 05          	testb  $0x5,0x18(%ebp)
f0104d39:	0f 84 8d 01 00 00    	je     f0104ecc <syscall+0x5b1>
		if((uintptr_t)srcva % PGSIZE)
f0104d3f:	8b 55 14             	mov    0x14(%ebp),%edx
f0104d42:	81 e2 ff 0f 00 00    	and    $0xfff,%edx
		if(((perm_needed & perm) == 0) || (perm & (~PTE_SYSCALL)))
f0104d48:	8b 45 18             	mov    0x18(%ebp),%eax
f0104d4b:	25 f8 f1 ff ff       	and    $0xfffff1f8,%eax
			return -E_INVAL;
f0104d50:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		if(((perm_needed & perm) == 0) || (perm & (~PTE_SYSCALL)))
f0104d55:	09 c2                	or     %eax,%edx
f0104d57:	0f 85 6f 01 00 00    	jne    f0104ecc <syscall+0x5b1>
		pte_t* pte = NULL;
f0104d5d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		struct PageInfo* pg = page_lookup(curenv->env_pgdir,srcva,&pte);
f0104d64:	e8 c5 13 00 00       	call   f010612e <cpunum>
f0104d69:	83 ec 04             	sub    $0x4,%esp
f0104d6c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104d6f:	52                   	push   %edx
f0104d70:	ff 75 14             	pushl  0x14(%ebp)
f0104d73:	6b c0 74             	imul   $0x74,%eax,%eax
f0104d76:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0104d7c:	ff 70 60             	pushl  0x60(%eax)
f0104d7f:	e8 09 c4 ff ff       	call   f010118d <page_lookup>
		if(!pg)
f0104d84:	83 c4 10             	add    $0x10,%esp
f0104d87:	85 c0                	test   %eax,%eax
f0104d89:	74 72                	je     f0104dfd <syscall+0x4e2>
		if((perm & PTE_W) && !(*pte & PTE_W))
f0104d8b:	f6 45 18 02          	testb  $0x2,0x18(%ebp)
f0104d8f:	74 0c                	je     f0104d9d <syscall+0x482>
f0104d91:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104d94:	f6 02 02             	testb  $0x2,(%edx)
f0104d97:	0f 84 2f 01 00 00    	je     f0104ecc <syscall+0x5b1>
		if((ret = page_insert(dst->env_pgdir,pg,dst->env_ipc_dstva,perm)) < 0)
f0104d9d:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0104da0:	ff 75 18             	pushl  0x18(%ebp)
f0104da3:	ff 72 6c             	pushl  0x6c(%edx)
f0104da6:	50                   	push   %eax
f0104da7:	ff 72 60             	pushl  0x60(%edx)
f0104daa:	e8 d1 c4 ff ff       	call   f0101280 <page_insert>
f0104daf:	89 c3                	mov    %eax,%ebx
f0104db1:	83 c4 10             	add    $0x10,%esp
f0104db4:	85 c0                	test   %eax,%eax
f0104db6:	0f 88 10 01 00 00    	js     f0104ecc <syscall+0x5b1>
		dst->env_ipc_perm = perm;
f0104dbc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104dbf:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0104dc2:	89 48 78             	mov    %ecx,0x78(%eax)
	dst->env_ipc_from = curenv->env_id;
f0104dc5:	e8 64 13 00 00       	call   f010612e <cpunum>
f0104dca:	89 c2                	mov    %eax,%edx
f0104dcc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104dcf:	6b d2 74             	imul   $0x74,%edx,%edx
f0104dd2:	8b 92 28 80 21 f0    	mov    -0xfde7fd8(%edx),%edx
f0104dd8:	8b 52 48             	mov    0x48(%edx),%edx
f0104ddb:	89 50 74             	mov    %edx,0x74(%eax)
	dst->env_ipc_value = value;
f0104dde:	89 78 70             	mov    %edi,0x70(%eax)
	dst->env_ipc_recving = 0;
f0104de1:	c6 40 68 00          	movb   $0x0,0x68(%eax)
	dst->env_status = ENV_RUNNABLE;
f0104de5:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	dst->env_tf.tf_regs.reg_eax = 0;
f0104dec:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return 0;
f0104df3:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104df8:	e9 cf 00 00 00       	jmp    f0104ecc <syscall+0x5b1>
			return -E_INVAL;
f0104dfd:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104e02:	e9 c5 00 00 00       	jmp    f0104ecc <syscall+0x5b1>
		return -E_IPC_NOT_RECV;
f0104e07:	bb f9 ff ff ff       	mov    $0xfffffff9,%ebx
		}
		case SYS_ipc_try_send:
		{
			return sys_ipc_try_send((envid_t)a1,(uint32_t)a2,(void*)a3,(unsigned int)a4);
f0104e0c:	e9 bb 00 00 00       	jmp    f0104ecc <syscall+0x5b1>
	if((uintptr_t)dstva<UTOP && (uintptr_t)dstva%PGSIZE)
f0104e11:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f0104e18:	77 13                	ja     f0104e2d <syscall+0x512>
f0104e1a:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
f0104e21:	74 0a                	je     f0104e2d <syscall+0x512>
		}
		case SYS_ipc_recv:
		{
			return sys_ipc_recv((void*)a1);
f0104e23:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104e28:	e9 9f 00 00 00       	jmp    f0104ecc <syscall+0x5b1>
	curenv->env_ipc_recving = 1;
f0104e2d:	e8 fc 12 00 00       	call   f010612e <cpunum>
f0104e32:	6b c0 74             	imul   $0x74,%eax,%eax
f0104e35:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0104e3b:	c6 40 68 01          	movb   $0x1,0x68(%eax)
	curenv->env_ipc_dstva = dstva;
f0104e3f:	e8 ea 12 00 00       	call   f010612e <cpunum>
f0104e44:	6b c0 74             	imul   $0x74,%eax,%eax
f0104e47:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0104e4d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104e50:	89 48 6c             	mov    %ecx,0x6c(%eax)
	curenv->env_status = ENV_NOT_RUNNABLE;
f0104e53:	e8 d6 12 00 00       	call   f010612e <cpunum>
f0104e58:	6b c0 74             	imul   $0x74,%eax,%eax
f0104e5b:	8b 80 28 80 21 f0    	mov    -0xfde7fd8(%eax),%eax
f0104e61:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	sched_yield();
f0104e68:	e8 f6 f9 ff ff       	call   f0104863 <sched_yield>
		}
		case SYS_env_set_trapframe:
		{
			return sys_env_set_trapframe((envid_t)a1,(struct Trapframe*)a2);
f0104e6d:	89 fe                	mov    %edi,%esi
	struct Env* e = NULL;
f0104e6f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	if(envid2env(envid,&e,1) < 0)
f0104e76:	83 ec 04             	sub    $0x4,%esp
f0104e79:	6a 01                	push   $0x1
f0104e7b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104e7e:	50                   	push   %eax
f0104e7f:	ff 75 0c             	pushl  0xc(%ebp)
f0104e82:	e8 78 e2 ff ff       	call   f01030ff <envid2env>
f0104e87:	83 c4 10             	add    $0x10,%esp
f0104e8a:	85 c0                	test   %eax,%eax
f0104e8c:	78 32                	js     f0104ec0 <syscall+0x5a5>
	user_mem_assert(e,(const void*)tf,sizeof(struct Trapframe),PTE_U|PTE_P);
f0104e8e:	6a 05                	push   $0x5
f0104e90:	6a 44                	push   $0x44
f0104e92:	57                   	push   %edi
f0104e93:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104e96:	e8 73 e1 ff ff       	call   f010300e <user_mem_assert>
	tf->tf_eflags &= ~FL_IOPL_MASK;
f0104e9b:	8b 47 38             	mov    0x38(%edi),%eax
f0104e9e:	80 e4 cf             	and    $0xcf,%ah
f0104ea1:	80 cc 02             	or     $0x2,%ah
f0104ea4:	89 47 38             	mov    %eax,0x38(%edi)
	tf->tf_cs |= 3;
f0104ea7:	66 83 4f 34 03       	orw    $0x3,0x34(%edi)
	e->env_tf = *tf;
f0104eac:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104eb1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104eb4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	return 0;
f0104eb6:	83 c4 10             	add    $0x10,%esp
f0104eb9:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104ebe:	eb 0c                	jmp    f0104ecc <syscall+0x5b1>
		return -E_BAD_ENV;
f0104ec0:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
			return sys_env_set_trapframe((envid_t)a1,(struct Trapframe*)a2);
f0104ec5:	eb 05                	jmp    f0104ecc <syscall+0x5b1>
			return 0;
f0104ec7:	bb 00 00 00 00       	mov    $0x0,%ebx
		}
		default:
			return -E_INVAL;
	}
}
f0104ecc:	89 d8                	mov    %ebx,%eax
f0104ece:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104ed1:	5b                   	pop    %ebx
f0104ed2:	5e                   	pop    %esi
f0104ed3:	5f                   	pop    %edi
f0104ed4:	5d                   	pop    %ebp
f0104ed5:	c3                   	ret    

f0104ed6 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104ed6:	55                   	push   %ebp
f0104ed7:	89 e5                	mov    %esp,%ebp
f0104ed9:	57                   	push   %edi
f0104eda:	56                   	push   %esi
f0104edb:	53                   	push   %ebx
f0104edc:	83 ec 14             	sub    $0x14,%esp
f0104edf:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104ee2:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104ee5:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104ee8:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104eeb:	8b 1a                	mov    (%edx),%ebx
f0104eed:	8b 01                	mov    (%ecx),%eax
f0104eef:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104ef2:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104ef9:	eb 23                	jmp    f0104f1e <stab_binsearch+0x48>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104efb:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0104efe:	eb 1e                	jmp    f0104f1e <stab_binsearch+0x48>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104f00:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104f03:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104f06:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104f0a:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104f0d:	73 46                	jae    f0104f55 <stab_binsearch+0x7f>
			*region_left = m;
f0104f0f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104f12:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104f14:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f0104f17:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0104f1e:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104f21:	7f 5f                	jg     f0104f82 <stab_binsearch+0xac>
		int true_m = (l + r) / 2, m = true_m;
f0104f23:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104f26:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f0104f29:	89 d0                	mov    %edx,%eax
f0104f2b:	c1 e8 1f             	shr    $0x1f,%eax
f0104f2e:	01 d0                	add    %edx,%eax
f0104f30:	89 c7                	mov    %eax,%edi
f0104f32:	d1 ff                	sar    %edi
f0104f34:	83 e0 fe             	and    $0xfffffffe,%eax
f0104f37:	01 f8                	add    %edi,%eax
f0104f39:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104f3c:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0104f40:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f0104f42:	39 c3                	cmp    %eax,%ebx
f0104f44:	7f b5                	jg     f0104efb <stab_binsearch+0x25>
f0104f46:	0f b6 0a             	movzbl (%edx),%ecx
f0104f49:	83 ea 0c             	sub    $0xc,%edx
f0104f4c:	39 f1                	cmp    %esi,%ecx
f0104f4e:	74 b0                	je     f0104f00 <stab_binsearch+0x2a>
			m--;
f0104f50:	83 e8 01             	sub    $0x1,%eax
f0104f53:	eb ed                	jmp    f0104f42 <stab_binsearch+0x6c>
		} else if (stabs[m].n_value > addr) {
f0104f55:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104f58:	76 14                	jbe    f0104f6e <stab_binsearch+0x98>
			*region_right = m - 1;
f0104f5a:	83 e8 01             	sub    $0x1,%eax
f0104f5d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104f60:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104f63:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f0104f65:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104f6c:	eb b0                	jmp    f0104f1e <stab_binsearch+0x48>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104f6e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104f71:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0104f73:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104f77:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f0104f79:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104f80:	eb 9c                	jmp    f0104f1e <stab_binsearch+0x48>
		}
	}

	if (!any_matches)
f0104f82:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104f86:	75 15                	jne    f0104f9d <stab_binsearch+0xc7>
		*region_right = *region_left - 1;
f0104f88:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104f8b:	8b 00                	mov    (%eax),%eax
f0104f8d:	83 e8 01             	sub    $0x1,%eax
f0104f90:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104f93:	89 07                	mov    %eax,(%edi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0104f95:	83 c4 14             	add    $0x14,%esp
f0104f98:	5b                   	pop    %ebx
f0104f99:	5e                   	pop    %esi
f0104f9a:	5f                   	pop    %edi
f0104f9b:	5d                   	pop    %ebp
f0104f9c:	c3                   	ret    
		for (l = *region_right;
f0104f9d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104fa0:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104fa2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104fa5:	8b 0f                	mov    (%edi),%ecx
f0104fa7:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104faa:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0104fad:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
		for (l = *region_right;
f0104fb1:	eb 03                	jmp    f0104fb6 <stab_binsearch+0xe0>
		     l--)
f0104fb3:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0104fb6:	39 c1                	cmp    %eax,%ecx
f0104fb8:	7d 0a                	jge    f0104fc4 <stab_binsearch+0xee>
		     l > *region_left && stabs[l].n_type != type;
f0104fba:	0f b6 1a             	movzbl (%edx),%ebx
f0104fbd:	83 ea 0c             	sub    $0xc,%edx
f0104fc0:	39 f3                	cmp    %esi,%ebx
f0104fc2:	75 ef                	jne    f0104fb3 <stab_binsearch+0xdd>
		*region_left = l;
f0104fc4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104fc7:	89 07                	mov    %eax,(%edi)
}
f0104fc9:	eb ca                	jmp    f0104f95 <stab_binsearch+0xbf>

f0104fcb <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104fcb:	f3 0f 1e fb          	endbr32 
f0104fcf:	55                   	push   %ebp
f0104fd0:	89 e5                	mov    %esp,%ebp
f0104fd2:	57                   	push   %edi
f0104fd3:	56                   	push   %esi
f0104fd4:	53                   	push   %ebx
f0104fd5:	83 ec 4c             	sub    $0x4c,%esp
f0104fd8:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104fdb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104fde:	c7 03 88 80 10 f0    	movl   $0xf0108088,(%ebx)
	info->eip_line = 0;
f0104fe4:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0104feb:	c7 43 08 88 80 10 f0 	movl   $0xf0108088,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0104ff2:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0104ff9:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0104ffc:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0105003:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0105009:	0f 86 32 01 00 00    	jbe    f0105141 <debuginfo_eip+0x176>
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010500f:	c7 45 b4 02 8c 11 f0 	movl   $0xf0118c02,-0x4c(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0105016:	c7 45 b8 99 53 11 f0 	movl   $0xf0115399,-0x48(%ebp)
		stab_end = __STAB_END__;
f010501d:	be 98 53 11 f0       	mov    $0xf0115398,%esi
		stabs = __STAB_BEGIN__;
f0105022:	c7 45 bc 30 86 10 f0 	movl   $0xf0108630,-0x44(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0105029:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f010502c:	39 4d b8             	cmp    %ecx,-0x48(%ebp)
f010502f:	0f 83 62 02 00 00    	jae    f0105297 <debuginfo_eip+0x2cc>
f0105035:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0105039:	0f 85 5f 02 00 00    	jne    f010529e <debuginfo_eip+0x2d3>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010503f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0105046:	2b 75 bc             	sub    -0x44(%ebp),%esi
f0105049:	c1 fe 02             	sar    $0x2,%esi
f010504c:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0105052:	83 e8 01             	sub    $0x1,%eax
f0105055:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0105058:	83 ec 08             	sub    $0x8,%esp
f010505b:	57                   	push   %edi
f010505c:	6a 64                	push   $0x64
f010505e:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0105061:	89 d1                	mov    %edx,%ecx
f0105063:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0105066:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0105069:	89 f0                	mov    %esi,%eax
f010506b:	e8 66 fe ff ff       	call   f0104ed6 <stab_binsearch>
	if (lfile == 0)
f0105070:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105073:	83 c4 10             	add    $0x10,%esp
f0105076:	85 c0                	test   %eax,%eax
f0105078:	0f 84 27 02 00 00    	je     f01052a5 <debuginfo_eip+0x2da>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010507e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0105081:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105084:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0105087:	83 ec 08             	sub    $0x8,%esp
f010508a:	57                   	push   %edi
f010508b:	6a 24                	push   $0x24
f010508d:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0105090:	89 d1                	mov    %edx,%ecx
f0105092:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0105095:	89 f0                	mov    %esi,%eax
f0105097:	e8 3a fe ff ff       	call   f0104ed6 <stab_binsearch>

	if (lfun <= rfun) {
f010509c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010509f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01050a2:	83 c4 10             	add    $0x10,%esp
f01050a5:	39 d0                	cmp    %edx,%eax
f01050a7:	0f 8f 34 01 00 00    	jg     f01051e1 <debuginfo_eip+0x216>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01050ad:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01050b0:	8d 34 8e             	lea    (%esi,%ecx,4),%esi
f01050b3:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f01050b6:	8b 36                	mov    (%esi),%esi
f01050b8:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f01050bb:	2b 4d b8             	sub    -0x48(%ebp),%ecx
f01050be:	39 ce                	cmp    %ecx,%esi
f01050c0:	73 06                	jae    f01050c8 <debuginfo_eip+0xfd>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01050c2:	03 75 b8             	add    -0x48(%ebp),%esi
f01050c5:	89 73 08             	mov    %esi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01050c8:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01050cb:	8b 4e 08             	mov    0x8(%esi),%ecx
f01050ce:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01050d1:	29 cf                	sub    %ecx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f01050d3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01050d6:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01050d9:	83 ec 08             	sub    $0x8,%esp
f01050dc:	6a 3a                	push   $0x3a
f01050de:	ff 73 08             	pushl  0x8(%ebx)
f01050e1:	e8 0a 0a 00 00       	call   f0105af0 <strfind>
f01050e6:	2b 43 08             	sub    0x8(%ebx),%eax
f01050e9:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	info->eip_file = stabstr +stabs[lfile].n_strx;
f01050ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01050ef:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01050f2:	8b 75 bc             	mov    -0x44(%ebp),%esi
f01050f5:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f01050f8:	03 0c 86             	add    (%esi,%eax,4),%ecx
f01050fb:	89 0b                	mov    %ecx,(%ebx)
	stab_binsearch(stabs, &lline, &rline,N_SLINE,addr);
f01050fd:	83 c4 08             	add    $0x8,%esp
f0105100:	57                   	push   %edi
f0105101:	6a 44                	push   $0x44
f0105103:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0105106:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0105109:	89 f0                	mov    %esi,%eax
f010510b:	e8 c6 fd ff ff       	call   f0104ed6 <stab_binsearch>
	if(lline>rline)
f0105110:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0105113:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0105116:	83 c4 10             	add    $0x10,%esp
f0105119:	39 c2                	cmp    %eax,%edx
f010511b:	0f 8f 8b 01 00 00    	jg     f01052ac <debuginfo_eip+0x2e1>
	{
		return -1;
	}
	else
	{
		info->eip_line = stabs[rline].n_desc;
f0105121:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0105124:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0105129:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010512c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010512f:	89 d0                	mov    %edx,%eax
f0105131:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0105134:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
f0105138:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f010513c:	e9 be 00 00 00       	jmp    f01051ff <debuginfo_eip+0x234>
		if(user_mem_check(curenv,usd,sizeof(struct UserStabData),PTE_P|PTE_U) != 0)
f0105141:	e8 e8 0f 00 00       	call   f010612e <cpunum>
f0105146:	6a 05                	push   $0x5
f0105148:	6a 10                	push   $0x10
f010514a:	68 00 00 20 00       	push   $0x200000
f010514f:	6b c0 74             	imul   $0x74,%eax,%eax
f0105152:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f0105158:	e8 25 de ff ff       	call   f0102f82 <user_mem_check>
f010515d:	83 c4 10             	add    $0x10,%esp
f0105160:	85 c0                	test   %eax,%eax
f0105162:	0f 85 21 01 00 00    	jne    f0105289 <debuginfo_eip+0x2be>
		stabs = usd->stabs;
f0105168:	a1 00 00 20 00       	mov    0x200000,%eax
f010516d:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stab_end = usd->stab_end;
f0105170:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f0105176:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f010517c:	89 4d b8             	mov    %ecx,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f010517f:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0105185:	89 55 b4             	mov    %edx,-0x4c(%ebp)
		if(user_mem_check(curenv,stabs,sizeof(struct Stab),PTE_P|PTE_U) != 0)
f0105188:	e8 a1 0f 00 00       	call   f010612e <cpunum>
f010518d:	6a 05                	push   $0x5
f010518f:	6a 0c                	push   $0xc
f0105191:	ff 75 bc             	pushl  -0x44(%ebp)
f0105194:	6b c0 74             	imul   $0x74,%eax,%eax
f0105197:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f010519d:	e8 e0 dd ff ff       	call   f0102f82 <user_mem_check>
f01051a2:	83 c4 10             	add    $0x10,%esp
f01051a5:	85 c0                	test   %eax,%eax
f01051a7:	0f 85 e3 00 00 00    	jne    f0105290 <debuginfo_eip+0x2c5>
		if(user_mem_check(curenv,stabstr,stabstr_end-stabstr,PTE_P|PTE_U) != 0)
f01051ad:	e8 7c 0f 00 00       	call   f010612e <cpunum>
f01051b2:	6a 05                	push   $0x5
f01051b4:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f01051b7:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f01051ba:	29 ca                	sub    %ecx,%edx
f01051bc:	52                   	push   %edx
f01051bd:	51                   	push   %ecx
f01051be:	6b c0 74             	imul   $0x74,%eax,%eax
f01051c1:	ff b0 28 80 21 f0    	pushl  -0xfde7fd8(%eax)
f01051c7:	e8 b6 dd ff ff       	call   f0102f82 <user_mem_check>
f01051cc:	83 c4 10             	add    $0x10,%esp
f01051cf:	85 c0                	test   %eax,%eax
f01051d1:	0f 84 52 fe ff ff    	je     f0105029 <debuginfo_eip+0x5e>
			return -1;
f01051d7:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01051dc:	e9 d7 00 00 00       	jmp    f01052b8 <debuginfo_eip+0x2ed>
		info->eip_fn_addr = addr;
f01051e1:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f01051e4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01051e7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01051ea:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01051ed:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01051f0:	e9 e4 fe ff ff       	jmp    f01050d9 <debuginfo_eip+0x10e>
f01051f5:	83 e8 01             	sub    $0x1,%eax
f01051f8:	83 ea 0c             	sub    $0xc,%edx
	while (lline >= lfile
f01051fb:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f01051ff:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0105202:	39 c7                	cmp    %eax,%edi
f0105204:	7f 43                	jg     f0105249 <debuginfo_eip+0x27e>
	       && stabs[lline].n_type != N_SOL
f0105206:	0f b6 0a             	movzbl (%edx),%ecx
f0105209:	80 f9 84             	cmp    $0x84,%cl
f010520c:	74 19                	je     f0105227 <debuginfo_eip+0x25c>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010520e:	80 f9 64             	cmp    $0x64,%cl
f0105211:	75 e2                	jne    f01051f5 <debuginfo_eip+0x22a>
f0105213:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0105217:	74 dc                	je     f01051f5 <debuginfo_eip+0x22a>
f0105219:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f010521d:	74 11                	je     f0105230 <debuginfo_eip+0x265>
f010521f:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0105222:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0105225:	eb 09                	jmp    f0105230 <debuginfo_eip+0x265>
f0105227:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f010522b:	74 03                	je     f0105230 <debuginfo_eip+0x265>
f010522d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0105230:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0105233:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0105236:	8b 04 87             	mov    (%edi,%eax,4),%eax
f0105239:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f010523c:	8b 7d b8             	mov    -0x48(%ebp),%edi
f010523f:	29 fa                	sub    %edi,%edx
f0105241:	39 d0                	cmp    %edx,%eax
f0105243:	73 04                	jae    f0105249 <debuginfo_eip+0x27e>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0105245:	01 f8                	add    %edi,%eax
f0105247:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0105249:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010524c:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010524f:	ba 00 00 00 00       	mov    $0x0,%edx
	if (lfun < rfun)
f0105254:	39 f0                	cmp    %esi,%eax
f0105256:	7d 60                	jge    f01052b8 <debuginfo_eip+0x2ed>
		for (lline = lfun + 1;
f0105258:	8d 50 01             	lea    0x1(%eax),%edx
f010525b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010525e:	89 d0                	mov    %edx,%eax
f0105260:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0105263:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0105266:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
f010526a:	eb 04                	jmp    f0105270 <debuginfo_eip+0x2a5>
			info->eip_fn_narg++;
f010526c:	83 43 14 01          	addl   $0x1,0x14(%ebx)
		for (lline = lfun + 1;
f0105270:	39 c6                	cmp    %eax,%esi
f0105272:	7e 3f                	jle    f01052b3 <debuginfo_eip+0x2e8>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0105274:	0f b6 0a             	movzbl (%edx),%ecx
f0105277:	83 c0 01             	add    $0x1,%eax
f010527a:	83 c2 0c             	add    $0xc,%edx
f010527d:	80 f9 a0             	cmp    $0xa0,%cl
f0105280:	74 ea                	je     f010526c <debuginfo_eip+0x2a1>
	return 0;
f0105282:	ba 00 00 00 00       	mov    $0x0,%edx
f0105287:	eb 2f                	jmp    f01052b8 <debuginfo_eip+0x2ed>
			return -1;
f0105289:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010528e:	eb 28                	jmp    f01052b8 <debuginfo_eip+0x2ed>
			return -1;
f0105290:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0105295:	eb 21                	jmp    f01052b8 <debuginfo_eip+0x2ed>
		return -1;
f0105297:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010529c:	eb 1a                	jmp    f01052b8 <debuginfo_eip+0x2ed>
f010529e:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052a3:	eb 13                	jmp    f01052b8 <debuginfo_eip+0x2ed>
		return -1;
f01052a5:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052aa:	eb 0c                	jmp    f01052b8 <debuginfo_eip+0x2ed>
		return -1;
f01052ac:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052b1:	eb 05                	jmp    f01052b8 <debuginfo_eip+0x2ed>
	return 0;
f01052b3:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01052b8:	89 d0                	mov    %edx,%eax
f01052ba:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01052bd:	5b                   	pop    %ebx
f01052be:	5e                   	pop    %esi
f01052bf:	5f                   	pop    %edi
f01052c0:	5d                   	pop    %ebp
f01052c1:	c3                   	ret    

f01052c2 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01052c2:	55                   	push   %ebp
f01052c3:	89 e5                	mov    %esp,%ebp
f01052c5:	57                   	push   %edi
f01052c6:	56                   	push   %esi
f01052c7:	53                   	push   %ebx
f01052c8:	83 ec 1c             	sub    $0x1c,%esp
f01052cb:	89 c7                	mov    %eax,%edi
f01052cd:	89 d6                	mov    %edx,%esi
f01052cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01052d2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01052d5:	89 d1                	mov    %edx,%ecx
f01052d7:	89 c2                	mov    %eax,%edx
f01052d9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01052dc:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01052df:	8b 45 10             	mov    0x10(%ebp),%eax
f01052e2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01052e5:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01052e8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01052ef:	39 c2                	cmp    %eax,%edx
f01052f1:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f01052f4:	72 3e                	jb     f0105334 <printnum+0x72>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01052f6:	83 ec 0c             	sub    $0xc,%esp
f01052f9:	ff 75 18             	pushl  0x18(%ebp)
f01052fc:	83 eb 01             	sub    $0x1,%ebx
f01052ff:	53                   	push   %ebx
f0105300:	50                   	push   %eax
f0105301:	83 ec 08             	sub    $0x8,%esp
f0105304:	ff 75 e4             	pushl  -0x1c(%ebp)
f0105307:	ff 75 e0             	pushl  -0x20(%ebp)
f010530a:	ff 75 dc             	pushl  -0x24(%ebp)
f010530d:	ff 75 d8             	pushl  -0x28(%ebp)
f0105310:	e8 2b 12 00 00       	call   f0106540 <__udivdi3>
f0105315:	83 c4 18             	add    $0x18,%esp
f0105318:	52                   	push   %edx
f0105319:	50                   	push   %eax
f010531a:	89 f2                	mov    %esi,%edx
f010531c:	89 f8                	mov    %edi,%eax
f010531e:	e8 9f ff ff ff       	call   f01052c2 <printnum>
f0105323:	83 c4 20             	add    $0x20,%esp
f0105326:	eb 13                	jmp    f010533b <printnum+0x79>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0105328:	83 ec 08             	sub    $0x8,%esp
f010532b:	56                   	push   %esi
f010532c:	ff 75 18             	pushl  0x18(%ebp)
f010532f:	ff d7                	call   *%edi
f0105331:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0105334:	83 eb 01             	sub    $0x1,%ebx
f0105337:	85 db                	test   %ebx,%ebx
f0105339:	7f ed                	jg     f0105328 <printnum+0x66>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010533b:	83 ec 08             	sub    $0x8,%esp
f010533e:	56                   	push   %esi
f010533f:	83 ec 04             	sub    $0x4,%esp
f0105342:	ff 75 e4             	pushl  -0x1c(%ebp)
f0105345:	ff 75 e0             	pushl  -0x20(%ebp)
f0105348:	ff 75 dc             	pushl  -0x24(%ebp)
f010534b:	ff 75 d8             	pushl  -0x28(%ebp)
f010534e:	e8 fd 12 00 00       	call   f0106650 <__umoddi3>
f0105353:	83 c4 14             	add    $0x14,%esp
f0105356:	0f be 80 92 80 10 f0 	movsbl -0xfef7f6e(%eax),%eax
f010535d:	50                   	push   %eax
f010535e:	ff d7                	call   *%edi
}
f0105360:	83 c4 10             	add    $0x10,%esp
f0105363:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105366:	5b                   	pop    %ebx
f0105367:	5e                   	pop    %esi
f0105368:	5f                   	pop    %edi
f0105369:	5d                   	pop    %ebp
f010536a:	c3                   	ret    

f010536b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010536b:	f3 0f 1e fb          	endbr32 
f010536f:	55                   	push   %ebp
f0105370:	89 e5                	mov    %esp,%ebp
f0105372:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0105375:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0105379:	8b 10                	mov    (%eax),%edx
f010537b:	3b 50 04             	cmp    0x4(%eax),%edx
f010537e:	73 0a                	jae    f010538a <sprintputch+0x1f>
		*b->buf++ = ch;
f0105380:	8d 4a 01             	lea    0x1(%edx),%ecx
f0105383:	89 08                	mov    %ecx,(%eax)
f0105385:	8b 45 08             	mov    0x8(%ebp),%eax
f0105388:	88 02                	mov    %al,(%edx)
}
f010538a:	5d                   	pop    %ebp
f010538b:	c3                   	ret    

f010538c <printfmt>:
{
f010538c:	f3 0f 1e fb          	endbr32 
f0105390:	55                   	push   %ebp
f0105391:	89 e5                	mov    %esp,%ebp
f0105393:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0105396:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0105399:	50                   	push   %eax
f010539a:	ff 75 10             	pushl  0x10(%ebp)
f010539d:	ff 75 0c             	pushl  0xc(%ebp)
f01053a0:	ff 75 08             	pushl  0x8(%ebp)
f01053a3:	e8 05 00 00 00       	call   f01053ad <vprintfmt>
}
f01053a8:	83 c4 10             	add    $0x10,%esp
f01053ab:	c9                   	leave  
f01053ac:	c3                   	ret    

f01053ad <vprintfmt>:
{
f01053ad:	f3 0f 1e fb          	endbr32 
f01053b1:	55                   	push   %ebp
f01053b2:	89 e5                	mov    %esp,%ebp
f01053b4:	57                   	push   %edi
f01053b5:	56                   	push   %esi
f01053b6:	53                   	push   %ebx
f01053b7:	83 ec 3c             	sub    $0x3c,%esp
f01053ba:	8b 75 08             	mov    0x8(%ebp),%esi
f01053bd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01053c0:	8b 7d 10             	mov    0x10(%ebp),%edi
f01053c3:	e9 8e 03 00 00       	jmp    f0105756 <vprintfmt+0x3a9>
		padc = ' ';
f01053c8:	c6 45 d3 20          	movb   $0x20,-0x2d(%ebp)
		altflag = 0;
f01053cc:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
		precision = -1;
f01053d3:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f01053da:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01053e1:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f01053e6:	8d 47 01             	lea    0x1(%edi),%eax
f01053e9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01053ec:	0f b6 17             	movzbl (%edi),%edx
f01053ef:	8d 42 dd             	lea    -0x23(%edx),%eax
f01053f2:	3c 55                	cmp    $0x55,%al
f01053f4:	0f 87 df 03 00 00    	ja     f01057d9 <vprintfmt+0x42c>
f01053fa:	0f b6 c0             	movzbl %al,%eax
f01053fd:	3e ff 24 85 e0 81 10 	notrack jmp *-0xfef7e20(,%eax,4)
f0105404:	f0 
f0105405:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0105408:	c6 45 d3 2d          	movb   $0x2d,-0x2d(%ebp)
f010540c:	eb d8                	jmp    f01053e6 <vprintfmt+0x39>
		switch (ch = *(unsigned char *) fmt++) {
f010540e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105411:	c6 45 d3 30          	movb   $0x30,-0x2d(%ebp)
f0105415:	eb cf                	jmp    f01053e6 <vprintfmt+0x39>
f0105417:	0f b6 d2             	movzbl %dl,%edx
f010541a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f010541d:	b8 00 00 00 00       	mov    $0x0,%eax
f0105422:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f0105425:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0105428:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f010542c:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f010542f:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0105432:	83 f9 09             	cmp    $0x9,%ecx
f0105435:	77 55                	ja     f010548c <vprintfmt+0xdf>
			for (precision = 0; ; ++fmt) {
f0105437:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f010543a:	eb e9                	jmp    f0105425 <vprintfmt+0x78>
			precision = va_arg(ap, int);
f010543c:	8b 45 14             	mov    0x14(%ebp),%eax
f010543f:	8b 00                	mov    (%eax),%eax
f0105441:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105444:	8b 45 14             	mov    0x14(%ebp),%eax
f0105447:	8d 40 04             	lea    0x4(%eax),%eax
f010544a:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010544d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0105450:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0105454:	79 90                	jns    f01053e6 <vprintfmt+0x39>
				width = precision, precision = -1;
f0105456:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105459:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010545c:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0105463:	eb 81                	jmp    f01053e6 <vprintfmt+0x39>
f0105465:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105468:	85 c0                	test   %eax,%eax
f010546a:	ba 00 00 00 00       	mov    $0x0,%edx
f010546f:	0f 49 d0             	cmovns %eax,%edx
f0105472:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0105475:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0105478:	e9 69 ff ff ff       	jmp    f01053e6 <vprintfmt+0x39>
		switch (ch = *(unsigned char *) fmt++) {
f010547d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0105480:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
			goto reswitch;
f0105487:	e9 5a ff ff ff       	jmp    f01053e6 <vprintfmt+0x39>
f010548c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010548f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105492:	eb bc                	jmp    f0105450 <vprintfmt+0xa3>
			lflag++;
f0105494:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0105497:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f010549a:	e9 47 ff ff ff       	jmp    f01053e6 <vprintfmt+0x39>
			putch(va_arg(ap, int), putdat);
f010549f:	8b 45 14             	mov    0x14(%ebp),%eax
f01054a2:	8d 78 04             	lea    0x4(%eax),%edi
f01054a5:	83 ec 08             	sub    $0x8,%esp
f01054a8:	53                   	push   %ebx
f01054a9:	ff 30                	pushl  (%eax)
f01054ab:	ff d6                	call   *%esi
			break;
f01054ad:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01054b0:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f01054b3:	e9 9b 02 00 00       	jmp    f0105753 <vprintfmt+0x3a6>
			err = va_arg(ap, int);
f01054b8:	8b 45 14             	mov    0x14(%ebp),%eax
f01054bb:	8d 78 04             	lea    0x4(%eax),%edi
f01054be:	8b 00                	mov    (%eax),%eax
f01054c0:	99                   	cltd   
f01054c1:	31 d0                	xor    %edx,%eax
f01054c3:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01054c5:	83 f8 0f             	cmp    $0xf,%eax
f01054c8:	7f 23                	jg     f01054ed <vprintfmt+0x140>
f01054ca:	8b 14 85 40 83 10 f0 	mov    -0xfef7cc0(,%eax,4),%edx
f01054d1:	85 d2                	test   %edx,%edx
f01054d3:	74 18                	je     f01054ed <vprintfmt+0x140>
				printfmt(putch, putdat, "%s", p);
f01054d5:	52                   	push   %edx
f01054d6:	68 39 77 10 f0       	push   $0xf0107739
f01054db:	53                   	push   %ebx
f01054dc:	56                   	push   %esi
f01054dd:	e8 aa fe ff ff       	call   f010538c <printfmt>
f01054e2:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01054e5:	89 7d 14             	mov    %edi,0x14(%ebp)
f01054e8:	e9 66 02 00 00       	jmp    f0105753 <vprintfmt+0x3a6>
				printfmt(putch, putdat, "error %d", err);
f01054ed:	50                   	push   %eax
f01054ee:	68 aa 80 10 f0       	push   $0xf01080aa
f01054f3:	53                   	push   %ebx
f01054f4:	56                   	push   %esi
f01054f5:	e8 92 fe ff ff       	call   f010538c <printfmt>
f01054fa:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01054fd:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0105500:	e9 4e 02 00 00       	jmp    f0105753 <vprintfmt+0x3a6>
			if ((p = va_arg(ap, char *)) == NULL)
f0105505:	8b 45 14             	mov    0x14(%ebp),%eax
f0105508:	83 c0 04             	add    $0x4,%eax
f010550b:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010550e:	8b 45 14             	mov    0x14(%ebp),%eax
f0105511:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f0105513:	85 d2                	test   %edx,%edx
f0105515:	b8 a3 80 10 f0       	mov    $0xf01080a3,%eax
f010551a:	0f 45 c2             	cmovne %edx,%eax
f010551d:	89 45 cc             	mov    %eax,-0x34(%ebp)
			if (width > 0 && padc != '-')
f0105520:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0105524:	7e 06                	jle    f010552c <vprintfmt+0x17f>
f0105526:	80 7d d3 2d          	cmpb   $0x2d,-0x2d(%ebp)
f010552a:	75 0d                	jne    f0105539 <vprintfmt+0x18c>
				for (width -= strnlen(p, precision); width > 0; width--)
f010552c:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010552f:	89 c7                	mov    %eax,%edi
f0105531:	03 45 e0             	add    -0x20(%ebp),%eax
f0105534:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105537:	eb 55                	jmp    f010558e <vprintfmt+0x1e1>
f0105539:	83 ec 08             	sub    $0x8,%esp
f010553c:	ff 75 d8             	pushl  -0x28(%ebp)
f010553f:	ff 75 cc             	pushl  -0x34(%ebp)
f0105542:	e8 38 04 00 00       	call   f010597f <strnlen>
f0105547:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010554a:	29 c2                	sub    %eax,%edx
f010554c:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f010554f:	83 c4 10             	add    $0x10,%esp
f0105552:	89 d7                	mov    %edx,%edi
					putch(padc, putdat);
f0105554:	0f be 45 d3          	movsbl -0x2d(%ebp),%eax
f0105558:	89 45 e0             	mov    %eax,-0x20(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f010555b:	85 ff                	test   %edi,%edi
f010555d:	7e 11                	jle    f0105570 <vprintfmt+0x1c3>
					putch(padc, putdat);
f010555f:	83 ec 08             	sub    $0x8,%esp
f0105562:	53                   	push   %ebx
f0105563:	ff 75 e0             	pushl  -0x20(%ebp)
f0105566:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0105568:	83 ef 01             	sub    $0x1,%edi
f010556b:	83 c4 10             	add    $0x10,%esp
f010556e:	eb eb                	jmp    f010555b <vprintfmt+0x1ae>
f0105570:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0105573:	85 d2                	test   %edx,%edx
f0105575:	b8 00 00 00 00       	mov    $0x0,%eax
f010557a:	0f 49 c2             	cmovns %edx,%eax
f010557d:	29 c2                	sub    %eax,%edx
f010557f:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0105582:	eb a8                	jmp    f010552c <vprintfmt+0x17f>
					putch(ch, putdat);
f0105584:	83 ec 08             	sub    $0x8,%esp
f0105587:	53                   	push   %ebx
f0105588:	52                   	push   %edx
f0105589:	ff d6                	call   *%esi
f010558b:	83 c4 10             	add    $0x10,%esp
f010558e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0105591:	29 f9                	sub    %edi,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0105593:	83 c7 01             	add    $0x1,%edi
f0105596:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010559a:	0f be d0             	movsbl %al,%edx
f010559d:	85 d2                	test   %edx,%edx
f010559f:	74 4b                	je     f01055ec <vprintfmt+0x23f>
f01055a1:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01055a5:	78 06                	js     f01055ad <vprintfmt+0x200>
f01055a7:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f01055ab:	78 1e                	js     f01055cb <vprintfmt+0x21e>
				if (altflag && (ch < ' ' || ch > '~'))
f01055ad:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01055b1:	74 d1                	je     f0105584 <vprintfmt+0x1d7>
f01055b3:	0f be c0             	movsbl %al,%eax
f01055b6:	83 e8 20             	sub    $0x20,%eax
f01055b9:	83 f8 5e             	cmp    $0x5e,%eax
f01055bc:	76 c6                	jbe    f0105584 <vprintfmt+0x1d7>
					putch('?', putdat);
f01055be:	83 ec 08             	sub    $0x8,%esp
f01055c1:	53                   	push   %ebx
f01055c2:	6a 3f                	push   $0x3f
f01055c4:	ff d6                	call   *%esi
f01055c6:	83 c4 10             	add    $0x10,%esp
f01055c9:	eb c3                	jmp    f010558e <vprintfmt+0x1e1>
f01055cb:	89 cf                	mov    %ecx,%edi
f01055cd:	eb 0e                	jmp    f01055dd <vprintfmt+0x230>
				putch(' ', putdat);
f01055cf:	83 ec 08             	sub    $0x8,%esp
f01055d2:	53                   	push   %ebx
f01055d3:	6a 20                	push   $0x20
f01055d5:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01055d7:	83 ef 01             	sub    $0x1,%edi
f01055da:	83 c4 10             	add    $0x10,%esp
f01055dd:	85 ff                	test   %edi,%edi
f01055df:	7f ee                	jg     f01055cf <vprintfmt+0x222>
			if ((p = va_arg(ap, char *)) == NULL)
f01055e1:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01055e4:	89 45 14             	mov    %eax,0x14(%ebp)
f01055e7:	e9 67 01 00 00       	jmp    f0105753 <vprintfmt+0x3a6>
f01055ec:	89 cf                	mov    %ecx,%edi
f01055ee:	eb ed                	jmp    f01055dd <vprintfmt+0x230>
	if (lflag >= 2)
f01055f0:	83 f9 01             	cmp    $0x1,%ecx
f01055f3:	7f 1b                	jg     f0105610 <vprintfmt+0x263>
	else if (lflag)
f01055f5:	85 c9                	test   %ecx,%ecx
f01055f7:	74 63                	je     f010565c <vprintfmt+0x2af>
		return va_arg(*ap, long);
f01055f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01055fc:	8b 00                	mov    (%eax),%eax
f01055fe:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105601:	99                   	cltd   
f0105602:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105605:	8b 45 14             	mov    0x14(%ebp),%eax
f0105608:	8d 40 04             	lea    0x4(%eax),%eax
f010560b:	89 45 14             	mov    %eax,0x14(%ebp)
f010560e:	eb 17                	jmp    f0105627 <vprintfmt+0x27a>
		return va_arg(*ap, long long);
f0105610:	8b 45 14             	mov    0x14(%ebp),%eax
f0105613:	8b 50 04             	mov    0x4(%eax),%edx
f0105616:	8b 00                	mov    (%eax),%eax
f0105618:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010561b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010561e:	8b 45 14             	mov    0x14(%ebp),%eax
f0105621:	8d 40 08             	lea    0x8(%eax),%eax
f0105624:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0105627:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010562a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f010562d:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f0105632:	85 c9                	test   %ecx,%ecx
f0105634:	0f 89 ff 00 00 00    	jns    f0105739 <vprintfmt+0x38c>
				putch('-', putdat);
f010563a:	83 ec 08             	sub    $0x8,%esp
f010563d:	53                   	push   %ebx
f010563e:	6a 2d                	push   $0x2d
f0105640:	ff d6                	call   *%esi
				num = -(long long) num;
f0105642:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0105645:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0105648:	f7 da                	neg    %edx
f010564a:	83 d1 00             	adc    $0x0,%ecx
f010564d:	f7 d9                	neg    %ecx
f010564f:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0105652:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105657:	e9 dd 00 00 00       	jmp    f0105739 <vprintfmt+0x38c>
		return va_arg(*ap, int);
f010565c:	8b 45 14             	mov    0x14(%ebp),%eax
f010565f:	8b 00                	mov    (%eax),%eax
f0105661:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105664:	99                   	cltd   
f0105665:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105668:	8b 45 14             	mov    0x14(%ebp),%eax
f010566b:	8d 40 04             	lea    0x4(%eax),%eax
f010566e:	89 45 14             	mov    %eax,0x14(%ebp)
f0105671:	eb b4                	jmp    f0105627 <vprintfmt+0x27a>
	if (lflag >= 2)
f0105673:	83 f9 01             	cmp    $0x1,%ecx
f0105676:	7f 1e                	jg     f0105696 <vprintfmt+0x2e9>
	else if (lflag)
f0105678:	85 c9                	test   %ecx,%ecx
f010567a:	74 32                	je     f01056ae <vprintfmt+0x301>
		return va_arg(*ap, unsigned long);
f010567c:	8b 45 14             	mov    0x14(%ebp),%eax
f010567f:	8b 10                	mov    (%eax),%edx
f0105681:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105686:	8d 40 04             	lea    0x4(%eax),%eax
f0105689:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010568c:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long);
f0105691:	e9 a3 00 00 00       	jmp    f0105739 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned long long);
f0105696:	8b 45 14             	mov    0x14(%ebp),%eax
f0105699:	8b 10                	mov    (%eax),%edx
f010569b:	8b 48 04             	mov    0x4(%eax),%ecx
f010569e:	8d 40 08             	lea    0x8(%eax),%eax
f01056a1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01056a4:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long long);
f01056a9:	e9 8b 00 00 00       	jmp    f0105739 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned int);
f01056ae:	8b 45 14             	mov    0x14(%ebp),%eax
f01056b1:	8b 10                	mov    (%eax),%edx
f01056b3:	b9 00 00 00 00       	mov    $0x0,%ecx
f01056b8:	8d 40 04             	lea    0x4(%eax),%eax
f01056bb:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01056be:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned int);
f01056c3:	eb 74                	jmp    f0105739 <vprintfmt+0x38c>
	if (lflag >= 2)
f01056c5:	83 f9 01             	cmp    $0x1,%ecx
f01056c8:	7f 1b                	jg     f01056e5 <vprintfmt+0x338>
	else if (lflag)
f01056ca:	85 c9                	test   %ecx,%ecx
f01056cc:	74 2c                	je     f01056fa <vprintfmt+0x34d>
		return va_arg(*ap, unsigned long);
f01056ce:	8b 45 14             	mov    0x14(%ebp),%eax
f01056d1:	8b 10                	mov    (%eax),%edx
f01056d3:	b9 00 00 00 00       	mov    $0x0,%ecx
f01056d8:	8d 40 04             	lea    0x4(%eax),%eax
f01056db:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01056de:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long);
f01056e3:	eb 54                	jmp    f0105739 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned long long);
f01056e5:	8b 45 14             	mov    0x14(%ebp),%eax
f01056e8:	8b 10                	mov    (%eax),%edx
f01056ea:	8b 48 04             	mov    0x4(%eax),%ecx
f01056ed:	8d 40 08             	lea    0x8(%eax),%eax
f01056f0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01056f3:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long long);
f01056f8:	eb 3f                	jmp    f0105739 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned int);
f01056fa:	8b 45 14             	mov    0x14(%ebp),%eax
f01056fd:	8b 10                	mov    (%eax),%edx
f01056ff:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105704:	8d 40 04             	lea    0x4(%eax),%eax
f0105707:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010570a:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned int);
f010570f:	eb 28                	jmp    f0105739 <vprintfmt+0x38c>
			putch('0', putdat);
f0105711:	83 ec 08             	sub    $0x8,%esp
f0105714:	53                   	push   %ebx
f0105715:	6a 30                	push   $0x30
f0105717:	ff d6                	call   *%esi
			putch('x', putdat);
f0105719:	83 c4 08             	add    $0x8,%esp
f010571c:	53                   	push   %ebx
f010571d:	6a 78                	push   $0x78
f010571f:	ff d6                	call   *%esi
			num = (unsigned long long)
f0105721:	8b 45 14             	mov    0x14(%ebp),%eax
f0105724:	8b 10                	mov    (%eax),%edx
f0105726:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010572b:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f010572e:	8d 40 04             	lea    0x4(%eax),%eax
f0105731:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0105734:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0105739:	83 ec 0c             	sub    $0xc,%esp
f010573c:	0f be 7d d3          	movsbl -0x2d(%ebp),%edi
f0105740:	57                   	push   %edi
f0105741:	ff 75 e0             	pushl  -0x20(%ebp)
f0105744:	50                   	push   %eax
f0105745:	51                   	push   %ecx
f0105746:	52                   	push   %edx
f0105747:	89 da                	mov    %ebx,%edx
f0105749:	89 f0                	mov    %esi,%eax
f010574b:	e8 72 fb ff ff       	call   f01052c2 <printnum>
			break;
f0105750:	83 c4 20             	add    $0x20,%esp
			if ((p = va_arg(ap, char *)) == NULL)
f0105753:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0105756:	83 c7 01             	add    $0x1,%edi
f0105759:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010575d:	83 f8 25             	cmp    $0x25,%eax
f0105760:	0f 84 62 fc ff ff    	je     f01053c8 <vprintfmt+0x1b>
			if (ch == '\0')
f0105766:	85 c0                	test   %eax,%eax
f0105768:	0f 84 8b 00 00 00    	je     f01057f9 <vprintfmt+0x44c>
			putch(ch, putdat);
f010576e:	83 ec 08             	sub    $0x8,%esp
f0105771:	53                   	push   %ebx
f0105772:	50                   	push   %eax
f0105773:	ff d6                	call   *%esi
f0105775:	83 c4 10             	add    $0x10,%esp
f0105778:	eb dc                	jmp    f0105756 <vprintfmt+0x3a9>
	if (lflag >= 2)
f010577a:	83 f9 01             	cmp    $0x1,%ecx
f010577d:	7f 1b                	jg     f010579a <vprintfmt+0x3ed>
	else if (lflag)
f010577f:	85 c9                	test   %ecx,%ecx
f0105781:	74 2c                	je     f01057af <vprintfmt+0x402>
		return va_arg(*ap, unsigned long);
f0105783:	8b 45 14             	mov    0x14(%ebp),%eax
f0105786:	8b 10                	mov    (%eax),%edx
f0105788:	b9 00 00 00 00       	mov    $0x0,%ecx
f010578d:	8d 40 04             	lea    0x4(%eax),%eax
f0105790:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0105793:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long);
f0105798:	eb 9f                	jmp    f0105739 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned long long);
f010579a:	8b 45 14             	mov    0x14(%ebp),%eax
f010579d:	8b 10                	mov    (%eax),%edx
f010579f:	8b 48 04             	mov    0x4(%eax),%ecx
f01057a2:	8d 40 08             	lea    0x8(%eax),%eax
f01057a5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01057a8:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long long);
f01057ad:	eb 8a                	jmp    f0105739 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned int);
f01057af:	8b 45 14             	mov    0x14(%ebp),%eax
f01057b2:	8b 10                	mov    (%eax),%edx
f01057b4:	b9 00 00 00 00       	mov    $0x0,%ecx
f01057b9:	8d 40 04             	lea    0x4(%eax),%eax
f01057bc:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01057bf:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned int);
f01057c4:	e9 70 ff ff ff       	jmp    f0105739 <vprintfmt+0x38c>
			putch(ch, putdat);
f01057c9:	83 ec 08             	sub    $0x8,%esp
f01057cc:	53                   	push   %ebx
f01057cd:	6a 25                	push   $0x25
f01057cf:	ff d6                	call   *%esi
			break;
f01057d1:	83 c4 10             	add    $0x10,%esp
f01057d4:	e9 7a ff ff ff       	jmp    f0105753 <vprintfmt+0x3a6>
			putch('%', putdat);
f01057d9:	83 ec 08             	sub    $0x8,%esp
f01057dc:	53                   	push   %ebx
f01057dd:	6a 25                	push   $0x25
f01057df:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01057e1:	83 c4 10             	add    $0x10,%esp
f01057e4:	89 f8                	mov    %edi,%eax
f01057e6:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01057ea:	74 05                	je     f01057f1 <vprintfmt+0x444>
f01057ec:	83 e8 01             	sub    $0x1,%eax
f01057ef:	eb f5                	jmp    f01057e6 <vprintfmt+0x439>
f01057f1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01057f4:	e9 5a ff ff ff       	jmp    f0105753 <vprintfmt+0x3a6>
}
f01057f9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01057fc:	5b                   	pop    %ebx
f01057fd:	5e                   	pop    %esi
f01057fe:	5f                   	pop    %edi
f01057ff:	5d                   	pop    %ebp
f0105800:	c3                   	ret    

f0105801 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105801:	f3 0f 1e fb          	endbr32 
f0105805:	55                   	push   %ebp
f0105806:	89 e5                	mov    %esp,%ebp
f0105808:	83 ec 18             	sub    $0x18,%esp
f010580b:	8b 45 08             	mov    0x8(%ebp),%eax
f010580e:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105811:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105814:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105818:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010581b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105822:	85 c0                	test   %eax,%eax
f0105824:	74 26                	je     f010584c <vsnprintf+0x4b>
f0105826:	85 d2                	test   %edx,%edx
f0105828:	7e 22                	jle    f010584c <vsnprintf+0x4b>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010582a:	ff 75 14             	pushl  0x14(%ebp)
f010582d:	ff 75 10             	pushl  0x10(%ebp)
f0105830:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105833:	50                   	push   %eax
f0105834:	68 6b 53 10 f0       	push   $0xf010536b
f0105839:	e8 6f fb ff ff       	call   f01053ad <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010583e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105841:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105844:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105847:	83 c4 10             	add    $0x10,%esp
}
f010584a:	c9                   	leave  
f010584b:	c3                   	ret    
		return -E_INVAL;
f010584c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105851:	eb f7                	jmp    f010584a <vsnprintf+0x49>

f0105853 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105853:	f3 0f 1e fb          	endbr32 
f0105857:	55                   	push   %ebp
f0105858:	89 e5                	mov    %esp,%ebp
f010585a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010585d:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0105860:	50                   	push   %eax
f0105861:	ff 75 10             	pushl  0x10(%ebp)
f0105864:	ff 75 0c             	pushl  0xc(%ebp)
f0105867:	ff 75 08             	pushl  0x8(%ebp)
f010586a:	e8 92 ff ff ff       	call   f0105801 <vsnprintf>
	va_end(ap);

	return rc;
}
f010586f:	c9                   	leave  
f0105870:	c3                   	ret    

f0105871 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0105871:	f3 0f 1e fb          	endbr32 
f0105875:	55                   	push   %ebp
f0105876:	89 e5                	mov    %esp,%ebp
f0105878:	57                   	push   %edi
f0105879:	56                   	push   %esi
f010587a:	53                   	push   %ebx
f010587b:	83 ec 0c             	sub    $0xc,%esp
f010587e:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

#if JOS_KERNEL
	if (prompt != NULL)
f0105881:	85 c0                	test   %eax,%eax
f0105883:	74 11                	je     f0105896 <readline+0x25>
		cprintf("%s", prompt);
f0105885:	83 ec 08             	sub    $0x8,%esp
f0105888:	50                   	push   %eax
f0105889:	68 39 77 10 f0       	push   $0xf0107739
f010588e:	e8 2e e1 ff ff       	call   f01039c1 <cprintf>
f0105893:	83 c4 10             	add    $0x10,%esp
	if (prompt != NULL)
		fprintf(1, "%s", prompt);
#endif

	i = 0;
	echoing = iscons(0);
f0105896:	83 ec 0c             	sub    $0xc,%esp
f0105899:	6a 00                	push   $0x0
f010589b:	e8 47 af ff ff       	call   f01007e7 <iscons>
f01058a0:	89 c7                	mov    %eax,%edi
f01058a2:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01058a5:	be 00 00 00 00       	mov    $0x0,%esi
f01058aa:	eb 57                	jmp    f0105903 <readline+0x92>
	while (1) {
		c = getchar();
		if (c < 0) {
			if (c != -E_EOF)
				cprintf("read error: %e\n", c);
			return NULL;
f01058ac:	b8 00 00 00 00       	mov    $0x0,%eax
			if (c != -E_EOF)
f01058b1:	83 fb f8             	cmp    $0xfffffff8,%ebx
f01058b4:	75 08                	jne    f01058be <readline+0x4d>
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01058b6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01058b9:	5b                   	pop    %ebx
f01058ba:	5e                   	pop    %esi
f01058bb:	5f                   	pop    %edi
f01058bc:	5d                   	pop    %ebp
f01058bd:	c3                   	ret    
				cprintf("read error: %e\n", c);
f01058be:	83 ec 08             	sub    $0x8,%esp
f01058c1:	53                   	push   %ebx
f01058c2:	68 9f 83 10 f0       	push   $0xf010839f
f01058c7:	e8 f5 e0 ff ff       	call   f01039c1 <cprintf>
f01058cc:	83 c4 10             	add    $0x10,%esp
			return NULL;
f01058cf:	b8 00 00 00 00       	mov    $0x0,%eax
f01058d4:	eb e0                	jmp    f01058b6 <readline+0x45>
			if (echoing)
f01058d6:	85 ff                	test   %edi,%edi
f01058d8:	75 05                	jne    f01058df <readline+0x6e>
			i--;
f01058da:	83 ee 01             	sub    $0x1,%esi
f01058dd:	eb 24                	jmp    f0105903 <readline+0x92>
				cputchar('\b');
f01058df:	83 ec 0c             	sub    $0xc,%esp
f01058e2:	6a 08                	push   $0x8
f01058e4:	e8 d5 ae ff ff       	call   f01007be <cputchar>
f01058e9:	83 c4 10             	add    $0x10,%esp
f01058ec:	eb ec                	jmp    f01058da <readline+0x69>
				cputchar(c);
f01058ee:	83 ec 0c             	sub    $0xc,%esp
f01058f1:	53                   	push   %ebx
f01058f2:	e8 c7 ae ff ff       	call   f01007be <cputchar>
f01058f7:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01058fa:	88 9e 80 7a 21 f0    	mov    %bl,-0xfde8580(%esi)
f0105900:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f0105903:	e8 ca ae ff ff       	call   f01007d2 <getchar>
f0105908:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010590a:	85 c0                	test   %eax,%eax
f010590c:	78 9e                	js     f01058ac <readline+0x3b>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010590e:	83 f8 08             	cmp    $0x8,%eax
f0105911:	0f 94 c2             	sete   %dl
f0105914:	83 f8 7f             	cmp    $0x7f,%eax
f0105917:	0f 94 c0             	sete   %al
f010591a:	08 c2                	or     %al,%dl
f010591c:	74 04                	je     f0105922 <readline+0xb1>
f010591e:	85 f6                	test   %esi,%esi
f0105920:	7f b4                	jg     f01058d6 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105922:	83 fb 1f             	cmp    $0x1f,%ebx
f0105925:	7e 0e                	jle    f0105935 <readline+0xc4>
f0105927:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010592d:	7f 06                	jg     f0105935 <readline+0xc4>
			if (echoing)
f010592f:	85 ff                	test   %edi,%edi
f0105931:	74 c7                	je     f01058fa <readline+0x89>
f0105933:	eb b9                	jmp    f01058ee <readline+0x7d>
		} else if (c == '\n' || c == '\r') {
f0105935:	83 fb 0a             	cmp    $0xa,%ebx
f0105938:	74 05                	je     f010593f <readline+0xce>
f010593a:	83 fb 0d             	cmp    $0xd,%ebx
f010593d:	75 c4                	jne    f0105903 <readline+0x92>
			if (echoing)
f010593f:	85 ff                	test   %edi,%edi
f0105941:	75 11                	jne    f0105954 <readline+0xe3>
			buf[i] = 0;
f0105943:	c6 86 80 7a 21 f0 00 	movb   $0x0,-0xfde8580(%esi)
			return buf;
f010594a:	b8 80 7a 21 f0       	mov    $0xf0217a80,%eax
f010594f:	e9 62 ff ff ff       	jmp    f01058b6 <readline+0x45>
				cputchar('\n');
f0105954:	83 ec 0c             	sub    $0xc,%esp
f0105957:	6a 0a                	push   $0xa
f0105959:	e8 60 ae ff ff       	call   f01007be <cputchar>
f010595e:	83 c4 10             	add    $0x10,%esp
f0105961:	eb e0                	jmp    f0105943 <readline+0xd2>

f0105963 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105963:	f3 0f 1e fb          	endbr32 
f0105967:	55                   	push   %ebp
f0105968:	89 e5                	mov    %esp,%ebp
f010596a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010596d:	b8 00 00 00 00       	mov    $0x0,%eax
f0105972:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105976:	74 05                	je     f010597d <strlen+0x1a>
		n++;
f0105978:	83 c0 01             	add    $0x1,%eax
f010597b:	eb f5                	jmp    f0105972 <strlen+0xf>
	return n;
}
f010597d:	5d                   	pop    %ebp
f010597e:	c3                   	ret    

f010597f <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010597f:	f3 0f 1e fb          	endbr32 
f0105983:	55                   	push   %ebp
f0105984:	89 e5                	mov    %esp,%ebp
f0105986:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105989:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010598c:	b8 00 00 00 00       	mov    $0x0,%eax
f0105991:	39 d0                	cmp    %edx,%eax
f0105993:	74 0d                	je     f01059a2 <strnlen+0x23>
f0105995:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0105999:	74 05                	je     f01059a0 <strnlen+0x21>
		n++;
f010599b:	83 c0 01             	add    $0x1,%eax
f010599e:	eb f1                	jmp    f0105991 <strnlen+0x12>
f01059a0:	89 c2                	mov    %eax,%edx
	return n;
}
f01059a2:	89 d0                	mov    %edx,%eax
f01059a4:	5d                   	pop    %ebp
f01059a5:	c3                   	ret    

f01059a6 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01059a6:	f3 0f 1e fb          	endbr32 
f01059aa:	55                   	push   %ebp
f01059ab:	89 e5                	mov    %esp,%ebp
f01059ad:	53                   	push   %ebx
f01059ae:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01059b1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01059b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01059b9:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f01059bd:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f01059c0:	83 c0 01             	add    $0x1,%eax
f01059c3:	84 d2                	test   %dl,%dl
f01059c5:	75 f2                	jne    f01059b9 <strcpy+0x13>
		/* do nothing */;
	return ret;
}
f01059c7:	89 c8                	mov    %ecx,%eax
f01059c9:	5b                   	pop    %ebx
f01059ca:	5d                   	pop    %ebp
f01059cb:	c3                   	ret    

f01059cc <strcat>:

char *
strcat(char *dst, const char *src)
{
f01059cc:	f3 0f 1e fb          	endbr32 
f01059d0:	55                   	push   %ebp
f01059d1:	89 e5                	mov    %esp,%ebp
f01059d3:	53                   	push   %ebx
f01059d4:	83 ec 10             	sub    $0x10,%esp
f01059d7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01059da:	53                   	push   %ebx
f01059db:	e8 83 ff ff ff       	call   f0105963 <strlen>
f01059e0:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f01059e3:	ff 75 0c             	pushl  0xc(%ebp)
f01059e6:	01 d8                	add    %ebx,%eax
f01059e8:	50                   	push   %eax
f01059e9:	e8 b8 ff ff ff       	call   f01059a6 <strcpy>
	return dst;
}
f01059ee:	89 d8                	mov    %ebx,%eax
f01059f0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01059f3:	c9                   	leave  
f01059f4:	c3                   	ret    

f01059f5 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01059f5:	f3 0f 1e fb          	endbr32 
f01059f9:	55                   	push   %ebp
f01059fa:	89 e5                	mov    %esp,%ebp
f01059fc:	56                   	push   %esi
f01059fd:	53                   	push   %ebx
f01059fe:	8b 75 08             	mov    0x8(%ebp),%esi
f0105a01:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105a04:	89 f3                	mov    %esi,%ebx
f0105a06:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105a09:	89 f0                	mov    %esi,%eax
f0105a0b:	39 d8                	cmp    %ebx,%eax
f0105a0d:	74 11                	je     f0105a20 <strncpy+0x2b>
		*dst++ = *src;
f0105a0f:	83 c0 01             	add    $0x1,%eax
f0105a12:	0f b6 0a             	movzbl (%edx),%ecx
f0105a15:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0105a18:	80 f9 01             	cmp    $0x1,%cl
f0105a1b:	83 da ff             	sbb    $0xffffffff,%edx
f0105a1e:	eb eb                	jmp    f0105a0b <strncpy+0x16>
	}
	return ret;
}
f0105a20:	89 f0                	mov    %esi,%eax
f0105a22:	5b                   	pop    %ebx
f0105a23:	5e                   	pop    %esi
f0105a24:	5d                   	pop    %ebp
f0105a25:	c3                   	ret    

f0105a26 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0105a26:	f3 0f 1e fb          	endbr32 
f0105a2a:	55                   	push   %ebp
f0105a2b:	89 e5                	mov    %esp,%ebp
f0105a2d:	56                   	push   %esi
f0105a2e:	53                   	push   %ebx
f0105a2f:	8b 75 08             	mov    0x8(%ebp),%esi
f0105a32:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105a35:	8b 55 10             	mov    0x10(%ebp),%edx
f0105a38:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105a3a:	85 d2                	test   %edx,%edx
f0105a3c:	74 21                	je     f0105a5f <strlcpy+0x39>
f0105a3e:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0105a42:	89 f2                	mov    %esi,%edx
		while (--size > 0 && *src != '\0')
f0105a44:	39 c2                	cmp    %eax,%edx
f0105a46:	74 14                	je     f0105a5c <strlcpy+0x36>
f0105a48:	0f b6 19             	movzbl (%ecx),%ebx
f0105a4b:	84 db                	test   %bl,%bl
f0105a4d:	74 0b                	je     f0105a5a <strlcpy+0x34>
			*dst++ = *src++;
f0105a4f:	83 c1 01             	add    $0x1,%ecx
f0105a52:	83 c2 01             	add    $0x1,%edx
f0105a55:	88 5a ff             	mov    %bl,-0x1(%edx)
f0105a58:	eb ea                	jmp    f0105a44 <strlcpy+0x1e>
f0105a5a:	89 d0                	mov    %edx,%eax
		*dst = '\0';
f0105a5c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105a5f:	29 f0                	sub    %esi,%eax
}
f0105a61:	5b                   	pop    %ebx
f0105a62:	5e                   	pop    %esi
f0105a63:	5d                   	pop    %ebp
f0105a64:	c3                   	ret    

f0105a65 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105a65:	f3 0f 1e fb          	endbr32 
f0105a69:	55                   	push   %ebp
f0105a6a:	89 e5                	mov    %esp,%ebp
f0105a6c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105a6f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105a72:	0f b6 01             	movzbl (%ecx),%eax
f0105a75:	84 c0                	test   %al,%al
f0105a77:	74 0c                	je     f0105a85 <strcmp+0x20>
f0105a79:	3a 02                	cmp    (%edx),%al
f0105a7b:	75 08                	jne    f0105a85 <strcmp+0x20>
		p++, q++;
f0105a7d:	83 c1 01             	add    $0x1,%ecx
f0105a80:	83 c2 01             	add    $0x1,%edx
f0105a83:	eb ed                	jmp    f0105a72 <strcmp+0xd>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105a85:	0f b6 c0             	movzbl %al,%eax
f0105a88:	0f b6 12             	movzbl (%edx),%edx
f0105a8b:	29 d0                	sub    %edx,%eax
}
f0105a8d:	5d                   	pop    %ebp
f0105a8e:	c3                   	ret    

f0105a8f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105a8f:	f3 0f 1e fb          	endbr32 
f0105a93:	55                   	push   %ebp
f0105a94:	89 e5                	mov    %esp,%ebp
f0105a96:	53                   	push   %ebx
f0105a97:	8b 45 08             	mov    0x8(%ebp),%eax
f0105a9a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105a9d:	89 c3                	mov    %eax,%ebx
f0105a9f:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0105aa2:	eb 06                	jmp    f0105aaa <strncmp+0x1b>
		n--, p++, q++;
f0105aa4:	83 c0 01             	add    $0x1,%eax
f0105aa7:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0105aaa:	39 d8                	cmp    %ebx,%eax
f0105aac:	74 16                	je     f0105ac4 <strncmp+0x35>
f0105aae:	0f b6 08             	movzbl (%eax),%ecx
f0105ab1:	84 c9                	test   %cl,%cl
f0105ab3:	74 04                	je     f0105ab9 <strncmp+0x2a>
f0105ab5:	3a 0a                	cmp    (%edx),%cl
f0105ab7:	74 eb                	je     f0105aa4 <strncmp+0x15>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105ab9:	0f b6 00             	movzbl (%eax),%eax
f0105abc:	0f b6 12             	movzbl (%edx),%edx
f0105abf:	29 d0                	sub    %edx,%eax
}
f0105ac1:	5b                   	pop    %ebx
f0105ac2:	5d                   	pop    %ebp
f0105ac3:	c3                   	ret    
		return 0;
f0105ac4:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ac9:	eb f6                	jmp    f0105ac1 <strncmp+0x32>

f0105acb <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105acb:	f3 0f 1e fb          	endbr32 
f0105acf:	55                   	push   %ebp
f0105ad0:	89 e5                	mov    %esp,%ebp
f0105ad2:	8b 45 08             	mov    0x8(%ebp),%eax
f0105ad5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105ad9:	0f b6 10             	movzbl (%eax),%edx
f0105adc:	84 d2                	test   %dl,%dl
f0105ade:	74 09                	je     f0105ae9 <strchr+0x1e>
		if (*s == c)
f0105ae0:	38 ca                	cmp    %cl,%dl
f0105ae2:	74 0a                	je     f0105aee <strchr+0x23>
	for (; *s; s++)
f0105ae4:	83 c0 01             	add    $0x1,%eax
f0105ae7:	eb f0                	jmp    f0105ad9 <strchr+0xe>
			return (char *) s;
	return 0;
f0105ae9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105aee:	5d                   	pop    %ebp
f0105aef:	c3                   	ret    

f0105af0 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105af0:	f3 0f 1e fb          	endbr32 
f0105af4:	55                   	push   %ebp
f0105af5:	89 e5                	mov    %esp,%ebp
f0105af7:	8b 45 08             	mov    0x8(%ebp),%eax
f0105afa:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105afe:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0105b01:	38 ca                	cmp    %cl,%dl
f0105b03:	74 09                	je     f0105b0e <strfind+0x1e>
f0105b05:	84 d2                	test   %dl,%dl
f0105b07:	74 05                	je     f0105b0e <strfind+0x1e>
	for (; *s; s++)
f0105b09:	83 c0 01             	add    $0x1,%eax
f0105b0c:	eb f0                	jmp    f0105afe <strfind+0xe>
			break;
	return (char *) s;
}
f0105b0e:	5d                   	pop    %ebp
f0105b0f:	c3                   	ret    

f0105b10 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105b10:	f3 0f 1e fb          	endbr32 
f0105b14:	55                   	push   %ebp
f0105b15:	89 e5                	mov    %esp,%ebp
f0105b17:	57                   	push   %edi
f0105b18:	56                   	push   %esi
f0105b19:	53                   	push   %ebx
f0105b1a:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105b1d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105b20:	85 c9                	test   %ecx,%ecx
f0105b22:	74 31                	je     f0105b55 <memset+0x45>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105b24:	89 f8                	mov    %edi,%eax
f0105b26:	09 c8                	or     %ecx,%eax
f0105b28:	a8 03                	test   $0x3,%al
f0105b2a:	75 23                	jne    f0105b4f <memset+0x3f>
		c &= 0xFF;
f0105b2c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105b30:	89 d3                	mov    %edx,%ebx
f0105b32:	c1 e3 08             	shl    $0x8,%ebx
f0105b35:	89 d0                	mov    %edx,%eax
f0105b37:	c1 e0 18             	shl    $0x18,%eax
f0105b3a:	89 d6                	mov    %edx,%esi
f0105b3c:	c1 e6 10             	shl    $0x10,%esi
f0105b3f:	09 f0                	or     %esi,%eax
f0105b41:	09 c2                	or     %eax,%edx
f0105b43:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0105b45:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0105b48:	89 d0                	mov    %edx,%eax
f0105b4a:	fc                   	cld    
f0105b4b:	f3 ab                	rep stos %eax,%es:(%edi)
f0105b4d:	eb 06                	jmp    f0105b55 <memset+0x45>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105b4f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105b52:	fc                   	cld    
f0105b53:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105b55:	89 f8                	mov    %edi,%eax
f0105b57:	5b                   	pop    %ebx
f0105b58:	5e                   	pop    %esi
f0105b59:	5f                   	pop    %edi
f0105b5a:	5d                   	pop    %ebp
f0105b5b:	c3                   	ret    

f0105b5c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105b5c:	f3 0f 1e fb          	endbr32 
f0105b60:	55                   	push   %ebp
f0105b61:	89 e5                	mov    %esp,%ebp
f0105b63:	57                   	push   %edi
f0105b64:	56                   	push   %esi
f0105b65:	8b 45 08             	mov    0x8(%ebp),%eax
f0105b68:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105b6b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105b6e:	39 c6                	cmp    %eax,%esi
f0105b70:	73 32                	jae    f0105ba4 <memmove+0x48>
f0105b72:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105b75:	39 c2                	cmp    %eax,%edx
f0105b77:	76 2b                	jbe    f0105ba4 <memmove+0x48>
		s += n;
		d += n;
f0105b79:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105b7c:	89 fe                	mov    %edi,%esi
f0105b7e:	09 ce                	or     %ecx,%esi
f0105b80:	09 d6                	or     %edx,%esi
f0105b82:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105b88:	75 0e                	jne    f0105b98 <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0105b8a:	83 ef 04             	sub    $0x4,%edi
f0105b8d:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105b90:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0105b93:	fd                   	std    
f0105b94:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105b96:	eb 09                	jmp    f0105ba1 <memmove+0x45>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0105b98:	83 ef 01             	sub    $0x1,%edi
f0105b9b:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0105b9e:	fd                   	std    
f0105b9f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105ba1:	fc                   	cld    
f0105ba2:	eb 1a                	jmp    f0105bbe <memmove+0x62>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105ba4:	89 c2                	mov    %eax,%edx
f0105ba6:	09 ca                	or     %ecx,%edx
f0105ba8:	09 f2                	or     %esi,%edx
f0105baa:	f6 c2 03             	test   $0x3,%dl
f0105bad:	75 0a                	jne    f0105bb9 <memmove+0x5d>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105baf:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0105bb2:	89 c7                	mov    %eax,%edi
f0105bb4:	fc                   	cld    
f0105bb5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105bb7:	eb 05                	jmp    f0105bbe <memmove+0x62>
		else
			asm volatile("cld; rep movsb\n"
f0105bb9:	89 c7                	mov    %eax,%edi
f0105bbb:	fc                   	cld    
f0105bbc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105bbe:	5e                   	pop    %esi
f0105bbf:	5f                   	pop    %edi
f0105bc0:	5d                   	pop    %ebp
f0105bc1:	c3                   	ret    

f0105bc2 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105bc2:	f3 0f 1e fb          	endbr32 
f0105bc6:	55                   	push   %ebp
f0105bc7:	89 e5                	mov    %esp,%ebp
f0105bc9:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0105bcc:	ff 75 10             	pushl  0x10(%ebp)
f0105bcf:	ff 75 0c             	pushl  0xc(%ebp)
f0105bd2:	ff 75 08             	pushl  0x8(%ebp)
f0105bd5:	e8 82 ff ff ff       	call   f0105b5c <memmove>
}
f0105bda:	c9                   	leave  
f0105bdb:	c3                   	ret    

f0105bdc <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105bdc:	f3 0f 1e fb          	endbr32 
f0105be0:	55                   	push   %ebp
f0105be1:	89 e5                	mov    %esp,%ebp
f0105be3:	56                   	push   %esi
f0105be4:	53                   	push   %ebx
f0105be5:	8b 45 08             	mov    0x8(%ebp),%eax
f0105be8:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105beb:	89 c6                	mov    %eax,%esi
f0105bed:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105bf0:	39 f0                	cmp    %esi,%eax
f0105bf2:	74 1c                	je     f0105c10 <memcmp+0x34>
		if (*s1 != *s2)
f0105bf4:	0f b6 08             	movzbl (%eax),%ecx
f0105bf7:	0f b6 1a             	movzbl (%edx),%ebx
f0105bfa:	38 d9                	cmp    %bl,%cl
f0105bfc:	75 08                	jne    f0105c06 <memcmp+0x2a>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0105bfe:	83 c0 01             	add    $0x1,%eax
f0105c01:	83 c2 01             	add    $0x1,%edx
f0105c04:	eb ea                	jmp    f0105bf0 <memcmp+0x14>
			return (int) *s1 - (int) *s2;
f0105c06:	0f b6 c1             	movzbl %cl,%eax
f0105c09:	0f b6 db             	movzbl %bl,%ebx
f0105c0c:	29 d8                	sub    %ebx,%eax
f0105c0e:	eb 05                	jmp    f0105c15 <memcmp+0x39>
	}

	return 0;
f0105c10:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105c15:	5b                   	pop    %ebx
f0105c16:	5e                   	pop    %esi
f0105c17:	5d                   	pop    %ebp
f0105c18:	c3                   	ret    

f0105c19 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105c19:	f3 0f 1e fb          	endbr32 
f0105c1d:	55                   	push   %ebp
f0105c1e:	89 e5                	mov    %esp,%ebp
f0105c20:	8b 45 08             	mov    0x8(%ebp),%eax
f0105c23:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0105c26:	89 c2                	mov    %eax,%edx
f0105c28:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105c2b:	39 d0                	cmp    %edx,%eax
f0105c2d:	73 09                	jae    f0105c38 <memfind+0x1f>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105c2f:	38 08                	cmp    %cl,(%eax)
f0105c31:	74 05                	je     f0105c38 <memfind+0x1f>
	for (; s < ends; s++)
f0105c33:	83 c0 01             	add    $0x1,%eax
f0105c36:	eb f3                	jmp    f0105c2b <memfind+0x12>
			break;
	return (void *) s;
}
f0105c38:	5d                   	pop    %ebp
f0105c39:	c3                   	ret    

f0105c3a <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105c3a:	f3 0f 1e fb          	endbr32 
f0105c3e:	55                   	push   %ebp
f0105c3f:	89 e5                	mov    %esp,%ebp
f0105c41:	57                   	push   %edi
f0105c42:	56                   	push   %esi
f0105c43:	53                   	push   %ebx
f0105c44:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105c47:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105c4a:	eb 03                	jmp    f0105c4f <strtol+0x15>
		s++;
f0105c4c:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0105c4f:	0f b6 01             	movzbl (%ecx),%eax
f0105c52:	3c 20                	cmp    $0x20,%al
f0105c54:	74 f6                	je     f0105c4c <strtol+0x12>
f0105c56:	3c 09                	cmp    $0x9,%al
f0105c58:	74 f2                	je     f0105c4c <strtol+0x12>

	// plus/minus sign
	if (*s == '+')
f0105c5a:	3c 2b                	cmp    $0x2b,%al
f0105c5c:	74 2a                	je     f0105c88 <strtol+0x4e>
	int neg = 0;
f0105c5e:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0105c63:	3c 2d                	cmp    $0x2d,%al
f0105c65:	74 2b                	je     f0105c92 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105c67:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0105c6d:	75 0f                	jne    f0105c7e <strtol+0x44>
f0105c6f:	80 39 30             	cmpb   $0x30,(%ecx)
f0105c72:	74 28                	je     f0105c9c <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105c74:	85 db                	test   %ebx,%ebx
f0105c76:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105c7b:	0f 44 d8             	cmove  %eax,%ebx
f0105c7e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105c83:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105c86:	eb 46                	jmp    f0105cce <strtol+0x94>
		s++;
f0105c88:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0105c8b:	bf 00 00 00 00       	mov    $0x0,%edi
f0105c90:	eb d5                	jmp    f0105c67 <strtol+0x2d>
		s++, neg = 1;
f0105c92:	83 c1 01             	add    $0x1,%ecx
f0105c95:	bf 01 00 00 00       	mov    $0x1,%edi
f0105c9a:	eb cb                	jmp    f0105c67 <strtol+0x2d>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105c9c:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105ca0:	74 0e                	je     f0105cb0 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0105ca2:	85 db                	test   %ebx,%ebx
f0105ca4:	75 d8                	jne    f0105c7e <strtol+0x44>
		s++, base = 8;
f0105ca6:	83 c1 01             	add    $0x1,%ecx
f0105ca9:	bb 08 00 00 00       	mov    $0x8,%ebx
f0105cae:	eb ce                	jmp    f0105c7e <strtol+0x44>
		s += 2, base = 16;
f0105cb0:	83 c1 02             	add    $0x2,%ecx
f0105cb3:	bb 10 00 00 00       	mov    $0x10,%ebx
f0105cb8:	eb c4                	jmp    f0105c7e <strtol+0x44>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f0105cba:	0f be d2             	movsbl %dl,%edx
f0105cbd:	83 ea 30             	sub    $0x30,%edx
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0105cc0:	3b 55 10             	cmp    0x10(%ebp),%edx
f0105cc3:	7d 3a                	jge    f0105cff <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0105cc5:	83 c1 01             	add    $0x1,%ecx
f0105cc8:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105ccc:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0105cce:	0f b6 11             	movzbl (%ecx),%edx
f0105cd1:	8d 72 d0             	lea    -0x30(%edx),%esi
f0105cd4:	89 f3                	mov    %esi,%ebx
f0105cd6:	80 fb 09             	cmp    $0x9,%bl
f0105cd9:	76 df                	jbe    f0105cba <strtol+0x80>
		else if (*s >= 'a' && *s <= 'z')
f0105cdb:	8d 72 9f             	lea    -0x61(%edx),%esi
f0105cde:	89 f3                	mov    %esi,%ebx
f0105ce0:	80 fb 19             	cmp    $0x19,%bl
f0105ce3:	77 08                	ja     f0105ced <strtol+0xb3>
			dig = *s - 'a' + 10;
f0105ce5:	0f be d2             	movsbl %dl,%edx
f0105ce8:	83 ea 57             	sub    $0x57,%edx
f0105ceb:	eb d3                	jmp    f0105cc0 <strtol+0x86>
		else if (*s >= 'A' && *s <= 'Z')
f0105ced:	8d 72 bf             	lea    -0x41(%edx),%esi
f0105cf0:	89 f3                	mov    %esi,%ebx
f0105cf2:	80 fb 19             	cmp    $0x19,%bl
f0105cf5:	77 08                	ja     f0105cff <strtol+0xc5>
			dig = *s - 'A' + 10;
f0105cf7:	0f be d2             	movsbl %dl,%edx
f0105cfa:	83 ea 37             	sub    $0x37,%edx
f0105cfd:	eb c1                	jmp    f0105cc0 <strtol+0x86>
		// we don't properly detect overflow!
	}

	if (endptr)
f0105cff:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105d03:	74 05                	je     f0105d0a <strtol+0xd0>
		*endptr = (char *) s;
f0105d05:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105d08:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0105d0a:	89 c2                	mov    %eax,%edx
f0105d0c:	f7 da                	neg    %edx
f0105d0e:	85 ff                	test   %edi,%edi
f0105d10:	0f 45 c2             	cmovne %edx,%eax
}
f0105d13:	5b                   	pop    %ebx
f0105d14:	5e                   	pop    %esi
f0105d15:	5f                   	pop    %edi
f0105d16:	5d                   	pop    %ebp
f0105d17:	c3                   	ret    

f0105d18 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0105d18:	fa                   	cli    

	xorw    %ax, %ax
f0105d19:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0105d1b:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105d1d:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105d1f:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105d21:	0f 01 16             	lgdtl  (%esi)
f0105d24:	74 70                	je     f0105d96 <mpsearch1+0x3>
	movl    %cr0, %eax
f0105d26:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0105d29:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105d2d:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105d30:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0105d36:	08 00                	or     %al,(%eax)

f0105d38 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0105d38:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105d3c:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105d3e:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105d40:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105d42:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0105d46:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0105d48:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0105d4a:	b8 00 10 12 00       	mov    $0x121000,%eax
	movl    %eax, %cr3
f0105d4f:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105d52:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105d55:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0105d5a:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0105d5d:	8b 25 84 7e 21 f0    	mov    0xf0217e84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105d63:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0105d68:	b8 bd 01 10 f0       	mov    $0xf01001bd,%eax
	call    *%eax
f0105d6d:	ff d0                	call   *%eax

f0105d6f <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105d6f:	eb fe                	jmp    f0105d6f <spin>
f0105d71:	8d 76 00             	lea    0x0(%esi),%esi

f0105d74 <gdt>:
	...
f0105d7c:	ff                   	(bad)  
f0105d7d:	ff 00                	incl   (%eax)
f0105d7f:	00 00                	add    %al,(%eax)
f0105d81:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105d88:	00                   	.byte 0x0
f0105d89:	92                   	xchg   %eax,%edx
f0105d8a:	cf                   	iret   
	...

f0105d8c <gdtdesc>:
f0105d8c:	17                   	pop    %ss
f0105d8d:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105d92 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105d92:	90                   	nop

f0105d93 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105d93:	55                   	push   %ebp
f0105d94:	89 e5                	mov    %esp,%ebp
f0105d96:	57                   	push   %edi
f0105d97:	56                   	push   %esi
f0105d98:	53                   	push   %ebx
f0105d99:	83 ec 0c             	sub    $0xc,%esp
f0105d9c:	89 c7                	mov    %eax,%edi
	if (PGNUM(pa) >= npages)
f0105d9e:	a1 88 7e 21 f0       	mov    0xf0217e88,%eax
f0105da3:	89 f9                	mov    %edi,%ecx
f0105da5:	c1 e9 0c             	shr    $0xc,%ecx
f0105da8:	39 c1                	cmp    %eax,%ecx
f0105daa:	73 19                	jae    f0105dc5 <mpsearch1+0x32>
	return (void *)(pa + KERNBASE);
f0105dac:	8d 9f 00 00 00 f0    	lea    -0x10000000(%edi),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105db2:	01 d7                	add    %edx,%edi
	if (PGNUM(pa) >= npages)
f0105db4:	89 fa                	mov    %edi,%edx
f0105db6:	c1 ea 0c             	shr    $0xc,%edx
f0105db9:	39 c2                	cmp    %eax,%edx
f0105dbb:	73 1a                	jae    f0105dd7 <mpsearch1+0x44>
	return (void *)(pa + KERNBASE);
f0105dbd:	81 ef 00 00 00 10    	sub    $0x10000000,%edi

	for (; mp < end; mp++)
f0105dc3:	eb 27                	jmp    f0105dec <mpsearch1+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105dc5:	57                   	push   %edi
f0105dc6:	68 c4 67 10 f0       	push   $0xf01067c4
f0105dcb:	6a 57                	push   $0x57
f0105dcd:	68 3d 85 10 f0       	push   $0xf010853d
f0105dd2:	e8 69 a2 ff ff       	call   f0100040 <_panic>
f0105dd7:	57                   	push   %edi
f0105dd8:	68 c4 67 10 f0       	push   $0xf01067c4
f0105ddd:	6a 57                	push   $0x57
f0105ddf:	68 3d 85 10 f0       	push   $0xf010853d
f0105de4:	e8 57 a2 ff ff       	call   f0100040 <_panic>
f0105de9:	83 c3 10             	add    $0x10,%ebx
f0105dec:	39 fb                	cmp    %edi,%ebx
f0105dee:	73 30                	jae    f0105e20 <mpsearch1+0x8d>
f0105df0:	89 de                	mov    %ebx,%esi
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105df2:	83 ec 04             	sub    $0x4,%esp
f0105df5:	6a 04                	push   $0x4
f0105df7:	68 4d 85 10 f0       	push   $0xf010854d
f0105dfc:	53                   	push   %ebx
f0105dfd:	e8 da fd ff ff       	call   f0105bdc <memcmp>
f0105e02:	83 c4 10             	add    $0x10,%esp
f0105e05:	85 c0                	test   %eax,%eax
f0105e07:	75 e0                	jne    f0105de9 <mpsearch1+0x56>
f0105e09:	89 da                	mov    %ebx,%edx
	for (i = 0; i < len; i++)
f0105e0b:	83 c6 10             	add    $0x10,%esi
		sum += ((uint8_t *)addr)[i];
f0105e0e:	0f b6 0a             	movzbl (%edx),%ecx
f0105e11:	01 c8                	add    %ecx,%eax
f0105e13:	83 c2 01             	add    $0x1,%edx
	for (i = 0; i < len; i++)
f0105e16:	39 f2                	cmp    %esi,%edx
f0105e18:	75 f4                	jne    f0105e0e <mpsearch1+0x7b>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105e1a:	84 c0                	test   %al,%al
f0105e1c:	75 cb                	jne    f0105de9 <mpsearch1+0x56>
f0105e1e:	eb 05                	jmp    f0105e25 <mpsearch1+0x92>
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0105e20:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0105e25:	89 d8                	mov    %ebx,%eax
f0105e27:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105e2a:	5b                   	pop    %ebx
f0105e2b:	5e                   	pop    %esi
f0105e2c:	5f                   	pop    %edi
f0105e2d:	5d                   	pop    %ebp
f0105e2e:	c3                   	ret    

f0105e2f <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105e2f:	f3 0f 1e fb          	endbr32 
f0105e33:	55                   	push   %ebp
f0105e34:	89 e5                	mov    %esp,%ebp
f0105e36:	57                   	push   %edi
f0105e37:	56                   	push   %esi
f0105e38:	53                   	push   %ebx
f0105e39:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105e3c:	c7 05 c0 83 21 f0 20 	movl   $0xf0218020,0xf02183c0
f0105e43:	80 21 f0 
	if (PGNUM(pa) >= npages)
f0105e46:	83 3d 88 7e 21 f0 00 	cmpl   $0x0,0xf0217e88
f0105e4d:	0f 84 a3 00 00 00    	je     f0105ef6 <mp_init+0xc7>
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105e53:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105e5a:	85 c0                	test   %eax,%eax
f0105e5c:	0f 84 aa 00 00 00    	je     f0105f0c <mp_init+0xdd>
		p <<= 4;	// Translate from segment to PA
f0105e62:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0105e65:	ba 00 04 00 00       	mov    $0x400,%edx
f0105e6a:	e8 24 ff ff ff       	call   f0105d93 <mpsearch1>
f0105e6f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105e72:	85 c0                	test   %eax,%eax
f0105e74:	75 1a                	jne    f0105e90 <mp_init+0x61>
	return mpsearch1(0xF0000, 0x10000);
f0105e76:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105e7b:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105e80:	e8 0e ff ff ff       	call   f0105d93 <mpsearch1>
f0105e85:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if ((mp = mpsearch()) == 0)
f0105e88:	85 c0                	test   %eax,%eax
f0105e8a:	0f 84 35 02 00 00    	je     f01060c5 <mp_init+0x296>
	if (mp->physaddr == 0 || mp->type != 0) {
f0105e90:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105e93:	8b 58 04             	mov    0x4(%eax),%ebx
f0105e96:	85 db                	test   %ebx,%ebx
f0105e98:	0f 84 97 00 00 00    	je     f0105f35 <mp_init+0x106>
f0105e9e:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0105ea2:	0f 85 8d 00 00 00    	jne    f0105f35 <mp_init+0x106>
f0105ea8:	89 d8                	mov    %ebx,%eax
f0105eaa:	c1 e8 0c             	shr    $0xc,%eax
f0105ead:	3b 05 88 7e 21 f0    	cmp    0xf0217e88,%eax
f0105eb3:	0f 83 91 00 00 00    	jae    f0105f4a <mp_init+0x11b>
	return (void *)(pa + KERNBASE);
f0105eb9:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
f0105ebf:	89 de                	mov    %ebx,%esi
	if (memcmp(conf, "PCMP", 4) != 0) {
f0105ec1:	83 ec 04             	sub    $0x4,%esp
f0105ec4:	6a 04                	push   $0x4
f0105ec6:	68 52 85 10 f0       	push   $0xf0108552
f0105ecb:	53                   	push   %ebx
f0105ecc:	e8 0b fd ff ff       	call   f0105bdc <memcmp>
f0105ed1:	83 c4 10             	add    $0x10,%esp
f0105ed4:	85 c0                	test   %eax,%eax
f0105ed6:	0f 85 83 00 00 00    	jne    f0105f5f <mp_init+0x130>
f0105edc:	0f b7 7b 04          	movzwl 0x4(%ebx),%edi
f0105ee0:	01 df                	add    %ebx,%edi
	sum = 0;
f0105ee2:	89 c2                	mov    %eax,%edx
	for (i = 0; i < len; i++)
f0105ee4:	39 fb                	cmp    %edi,%ebx
f0105ee6:	0f 84 88 00 00 00    	je     f0105f74 <mp_init+0x145>
		sum += ((uint8_t *)addr)[i];
f0105eec:	0f b6 0b             	movzbl (%ebx),%ecx
f0105eef:	01 ca                	add    %ecx,%edx
f0105ef1:	83 c3 01             	add    $0x1,%ebx
f0105ef4:	eb ee                	jmp    f0105ee4 <mp_init+0xb5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105ef6:	68 00 04 00 00       	push   $0x400
f0105efb:	68 c4 67 10 f0       	push   $0xf01067c4
f0105f00:	6a 6f                	push   $0x6f
f0105f02:	68 3d 85 10 f0       	push   $0xf010853d
f0105f07:	e8 34 a1 ff ff       	call   f0100040 <_panic>
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0105f0c:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105f13:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105f16:	2d 00 04 00 00       	sub    $0x400,%eax
f0105f1b:	ba 00 04 00 00       	mov    $0x400,%edx
f0105f20:	e8 6e fe ff ff       	call   f0105d93 <mpsearch1>
f0105f25:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105f28:	85 c0                	test   %eax,%eax
f0105f2a:	0f 85 60 ff ff ff    	jne    f0105e90 <mp_init+0x61>
f0105f30:	e9 41 ff ff ff       	jmp    f0105e76 <mp_init+0x47>
		cprintf("SMP: Default configurations not implemented\n");
f0105f35:	83 ec 0c             	sub    $0xc,%esp
f0105f38:	68 b0 83 10 f0       	push   $0xf01083b0
f0105f3d:	e8 7f da ff ff       	call   f01039c1 <cprintf>
		return NULL;
f0105f42:	83 c4 10             	add    $0x10,%esp
f0105f45:	e9 7b 01 00 00       	jmp    f01060c5 <mp_init+0x296>
f0105f4a:	53                   	push   %ebx
f0105f4b:	68 c4 67 10 f0       	push   $0xf01067c4
f0105f50:	68 90 00 00 00       	push   $0x90
f0105f55:	68 3d 85 10 f0       	push   $0xf010853d
f0105f5a:	e8 e1 a0 ff ff       	call   f0100040 <_panic>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105f5f:	83 ec 0c             	sub    $0xc,%esp
f0105f62:	68 e0 83 10 f0       	push   $0xf01083e0
f0105f67:	e8 55 da ff ff       	call   f01039c1 <cprintf>
		return NULL;
f0105f6c:	83 c4 10             	add    $0x10,%esp
f0105f6f:	e9 51 01 00 00       	jmp    f01060c5 <mp_init+0x296>
	if (sum(conf, conf->length) != 0) {
f0105f74:	84 d2                	test   %dl,%dl
f0105f76:	75 22                	jne    f0105f9a <mp_init+0x16b>
	if (conf->version != 1 && conf->version != 4) {
f0105f78:	0f b6 56 06          	movzbl 0x6(%esi),%edx
f0105f7c:	80 fa 01             	cmp    $0x1,%dl
f0105f7f:	74 05                	je     f0105f86 <mp_init+0x157>
f0105f81:	80 fa 04             	cmp    $0x4,%dl
f0105f84:	75 29                	jne    f0105faf <mp_init+0x180>
f0105f86:	0f b7 4e 28          	movzwl 0x28(%esi),%ecx
f0105f8a:	01 d9                	add    %ebx,%ecx
	for (i = 0; i < len; i++)
f0105f8c:	39 d9                	cmp    %ebx,%ecx
f0105f8e:	74 38                	je     f0105fc8 <mp_init+0x199>
		sum += ((uint8_t *)addr)[i];
f0105f90:	0f b6 13             	movzbl (%ebx),%edx
f0105f93:	01 d0                	add    %edx,%eax
f0105f95:	83 c3 01             	add    $0x1,%ebx
f0105f98:	eb f2                	jmp    f0105f8c <mp_init+0x15d>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105f9a:	83 ec 0c             	sub    $0xc,%esp
f0105f9d:	68 14 84 10 f0       	push   $0xf0108414
f0105fa2:	e8 1a da ff ff       	call   f01039c1 <cprintf>
		return NULL;
f0105fa7:	83 c4 10             	add    $0x10,%esp
f0105faa:	e9 16 01 00 00       	jmp    f01060c5 <mp_init+0x296>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105faf:	83 ec 08             	sub    $0x8,%esp
f0105fb2:	0f b6 d2             	movzbl %dl,%edx
f0105fb5:	52                   	push   %edx
f0105fb6:	68 38 84 10 f0       	push   $0xf0108438
f0105fbb:	e8 01 da ff ff       	call   f01039c1 <cprintf>
		return NULL;
f0105fc0:	83 c4 10             	add    $0x10,%esp
f0105fc3:	e9 fd 00 00 00       	jmp    f01060c5 <mp_init+0x296>
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105fc8:	02 46 2a             	add    0x2a(%esi),%al
f0105fcb:	75 1c                	jne    f0105fe9 <mp_init+0x1ba>
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
f0105fcd:	c7 05 00 80 21 f0 01 	movl   $0x1,0xf0218000
f0105fd4:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105fd7:	8b 46 24             	mov    0x24(%esi),%eax
f0105fda:	a3 00 90 25 f0       	mov    %eax,0xf0259000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105fdf:	8d 7e 2c             	lea    0x2c(%esi),%edi
f0105fe2:	bb 00 00 00 00       	mov    $0x0,%ebx
f0105fe7:	eb 4d                	jmp    f0106036 <mp_init+0x207>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105fe9:	83 ec 0c             	sub    $0xc,%esp
f0105fec:	68 58 84 10 f0       	push   $0xf0108458
f0105ff1:	e8 cb d9 ff ff       	call   f01039c1 <cprintf>
		return NULL;
f0105ff6:	83 c4 10             	add    $0x10,%esp
f0105ff9:	e9 c7 00 00 00       	jmp    f01060c5 <mp_init+0x296>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0105ffe:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0106002:	74 11                	je     f0106015 <mp_init+0x1e6>
				bootcpu = &cpus[ncpu];
f0106004:	6b 05 c4 83 21 f0 74 	imul   $0x74,0xf02183c4,%eax
f010600b:	05 20 80 21 f0       	add    $0xf0218020,%eax
f0106010:	a3 c0 83 21 f0       	mov    %eax,0xf02183c0
			if (ncpu < NCPU) {
f0106015:	a1 c4 83 21 f0       	mov    0xf02183c4,%eax
f010601a:	83 f8 07             	cmp    $0x7,%eax
f010601d:	7f 33                	jg     f0106052 <mp_init+0x223>
				cpus[ncpu].cpu_id = ncpu;
f010601f:	6b d0 74             	imul   $0x74,%eax,%edx
f0106022:	88 82 20 80 21 f0    	mov    %al,-0xfde7fe0(%edx)
				ncpu++;
f0106028:	83 c0 01             	add    $0x1,%eax
f010602b:	a3 c4 83 21 f0       	mov    %eax,0xf02183c4
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0106030:	83 c7 14             	add    $0x14,%edi
	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0106033:	83 c3 01             	add    $0x1,%ebx
f0106036:	0f b7 46 22          	movzwl 0x22(%esi),%eax
f010603a:	39 d8                	cmp    %ebx,%eax
f010603c:	76 4f                	jbe    f010608d <mp_init+0x25e>
		switch (*p) {
f010603e:	0f b6 07             	movzbl (%edi),%eax
f0106041:	84 c0                	test   %al,%al
f0106043:	74 b9                	je     f0105ffe <mp_init+0x1cf>
f0106045:	8d 50 ff             	lea    -0x1(%eax),%edx
f0106048:	80 fa 03             	cmp    $0x3,%dl
f010604b:	77 1c                	ja     f0106069 <mp_init+0x23a>
			continue;
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f010604d:	83 c7 08             	add    $0x8,%edi
			continue;
f0106050:	eb e1                	jmp    f0106033 <mp_init+0x204>
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0106052:	83 ec 08             	sub    $0x8,%esp
f0106055:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0106059:	50                   	push   %eax
f010605a:	68 88 84 10 f0       	push   $0xf0108488
f010605f:	e8 5d d9 ff ff       	call   f01039c1 <cprintf>
f0106064:	83 c4 10             	add    $0x10,%esp
f0106067:	eb c7                	jmp    f0106030 <mp_init+0x201>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0106069:	83 ec 08             	sub    $0x8,%esp
		switch (*p) {
f010606c:	0f b6 c0             	movzbl %al,%eax
			cprintf("mpinit: unknown config type %x\n", *p);
f010606f:	50                   	push   %eax
f0106070:	68 b0 84 10 f0       	push   $0xf01084b0
f0106075:	e8 47 d9 ff ff       	call   f01039c1 <cprintf>
			ismp = 0;
f010607a:	c7 05 00 80 21 f0 00 	movl   $0x0,0xf0218000
f0106081:	00 00 00 
			i = conf->entry;
f0106084:	0f b7 5e 22          	movzwl 0x22(%esi),%ebx
f0106088:	83 c4 10             	add    $0x10,%esp
f010608b:	eb a6                	jmp    f0106033 <mp_init+0x204>
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f010608d:	a1 c0 83 21 f0       	mov    0xf02183c0,%eax
f0106092:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0106099:	83 3d 00 80 21 f0 00 	cmpl   $0x0,0xf0218000
f01060a0:	74 2b                	je     f01060cd <mp_init+0x29e>
		ncpu = 1;
		lapicaddr = 0;
		cprintf("SMP: configuration not found, SMP disabled\n");
		return;
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f01060a2:	83 ec 04             	sub    $0x4,%esp
f01060a5:	ff 35 c4 83 21 f0    	pushl  0xf02183c4
f01060ab:	0f b6 00             	movzbl (%eax),%eax
f01060ae:	50                   	push   %eax
f01060af:	68 57 85 10 f0       	push   $0xf0108557
f01060b4:	e8 08 d9 ff ff       	call   f01039c1 <cprintf>

	if (mp->imcrp) {
f01060b9:	83 c4 10             	add    $0x10,%esp
f01060bc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01060bf:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f01060c3:	75 2e                	jne    f01060f3 <mp_init+0x2c4>
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f01060c5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01060c8:	5b                   	pop    %ebx
f01060c9:	5e                   	pop    %esi
f01060ca:	5f                   	pop    %edi
f01060cb:	5d                   	pop    %ebp
f01060cc:	c3                   	ret    
		ncpu = 1;
f01060cd:	c7 05 c4 83 21 f0 01 	movl   $0x1,0xf02183c4
f01060d4:	00 00 00 
		lapicaddr = 0;
f01060d7:	c7 05 00 90 25 f0 00 	movl   $0x0,0xf0259000
f01060de:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f01060e1:	83 ec 0c             	sub    $0xc,%esp
f01060e4:	68 d0 84 10 f0       	push   $0xf01084d0
f01060e9:	e8 d3 d8 ff ff       	call   f01039c1 <cprintf>
		return;
f01060ee:	83 c4 10             	add    $0x10,%esp
f01060f1:	eb d2                	jmp    f01060c5 <mp_init+0x296>
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f01060f3:	83 ec 0c             	sub    $0xc,%esp
f01060f6:	68 fc 84 10 f0       	push   $0xf01084fc
f01060fb:	e8 c1 d8 ff ff       	call   f01039c1 <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0106100:	b8 70 00 00 00       	mov    $0x70,%eax
f0106105:	ba 22 00 00 00       	mov    $0x22,%edx
f010610a:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010610b:	ba 23 00 00 00       	mov    $0x23,%edx
f0106110:	ec                   	in     (%dx),%al
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0106111:	83 c8 01             	or     $0x1,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0106114:	ee                   	out    %al,(%dx)
}
f0106115:	83 c4 10             	add    $0x10,%esp
f0106118:	eb ab                	jmp    f01060c5 <mp_init+0x296>

f010611a <lapicw>:
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
	lapic[index] = value;
f010611a:	8b 0d 04 90 25 f0    	mov    0xf0259004,%ecx
f0106120:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0106123:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0106125:	a1 04 90 25 f0       	mov    0xf0259004,%eax
f010612a:	8b 40 20             	mov    0x20(%eax),%eax
}
f010612d:	c3                   	ret    

f010612e <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f010612e:	f3 0f 1e fb          	endbr32 
	if (lapic)
f0106132:	8b 15 04 90 25 f0    	mov    0xf0259004,%edx
		return lapic[ID] >> 24;
	return 0;
f0106138:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lapic)
f010613d:	85 d2                	test   %edx,%edx
f010613f:	74 06                	je     f0106147 <cpunum+0x19>
		return lapic[ID] >> 24;
f0106141:	8b 42 20             	mov    0x20(%edx),%eax
f0106144:	c1 e8 18             	shr    $0x18,%eax
}
f0106147:	c3                   	ret    

f0106148 <lapic_init>:
{
f0106148:	f3 0f 1e fb          	endbr32 
	if (!lapicaddr)
f010614c:	a1 00 90 25 f0       	mov    0xf0259000,%eax
f0106151:	85 c0                	test   %eax,%eax
f0106153:	75 01                	jne    f0106156 <lapic_init+0xe>
f0106155:	c3                   	ret    
{
f0106156:	55                   	push   %ebp
f0106157:	89 e5                	mov    %esp,%ebp
f0106159:	83 ec 10             	sub    $0x10,%esp
	lapic = mmio_map_region(lapicaddr, 4096);
f010615c:	68 00 10 00 00       	push   $0x1000
f0106161:	50                   	push   %eax
f0106162:	e8 9b b1 ff ff       	call   f0101302 <mmio_map_region>
f0106167:	a3 04 90 25 f0       	mov    %eax,0xf0259004
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f010616c:	ba 27 01 00 00       	mov    $0x127,%edx
f0106171:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0106176:	e8 9f ff ff ff       	call   f010611a <lapicw>
	lapicw(TDCR, X1);
f010617b:	ba 0b 00 00 00       	mov    $0xb,%edx
f0106180:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0106185:	e8 90 ff ff ff       	call   f010611a <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f010618a:	ba 20 00 02 00       	mov    $0x20020,%edx
f010618f:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0106194:	e8 81 ff ff ff       	call   f010611a <lapicw>
	lapicw(TICR, 10000000); 
f0106199:	ba 80 96 98 00       	mov    $0x989680,%edx
f010619e:	b8 e0 00 00 00       	mov    $0xe0,%eax
f01061a3:	e8 72 ff ff ff       	call   f010611a <lapicw>
	if (thiscpu != bootcpu)
f01061a8:	e8 81 ff ff ff       	call   f010612e <cpunum>
f01061ad:	6b c0 74             	imul   $0x74,%eax,%eax
f01061b0:	05 20 80 21 f0       	add    $0xf0218020,%eax
f01061b5:	83 c4 10             	add    $0x10,%esp
f01061b8:	39 05 c0 83 21 f0    	cmp    %eax,0xf02183c0
f01061be:	74 0f                	je     f01061cf <lapic_init+0x87>
		lapicw(LINT0, MASKED);
f01061c0:	ba 00 00 01 00       	mov    $0x10000,%edx
f01061c5:	b8 d4 00 00 00       	mov    $0xd4,%eax
f01061ca:	e8 4b ff ff ff       	call   f010611a <lapicw>
	lapicw(LINT1, MASKED);
f01061cf:	ba 00 00 01 00       	mov    $0x10000,%edx
f01061d4:	b8 d8 00 00 00       	mov    $0xd8,%eax
f01061d9:	e8 3c ff ff ff       	call   f010611a <lapicw>
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f01061de:	a1 04 90 25 f0       	mov    0xf0259004,%eax
f01061e3:	8b 40 30             	mov    0x30(%eax),%eax
f01061e6:	c1 e8 10             	shr    $0x10,%eax
f01061e9:	a8 fc                	test   $0xfc,%al
f01061eb:	75 7c                	jne    f0106269 <lapic_init+0x121>
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f01061ed:	ba 33 00 00 00       	mov    $0x33,%edx
f01061f2:	b8 dc 00 00 00       	mov    $0xdc,%eax
f01061f7:	e8 1e ff ff ff       	call   f010611a <lapicw>
	lapicw(ESR, 0);
f01061fc:	ba 00 00 00 00       	mov    $0x0,%edx
f0106201:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0106206:	e8 0f ff ff ff       	call   f010611a <lapicw>
	lapicw(ESR, 0);
f010620b:	ba 00 00 00 00       	mov    $0x0,%edx
f0106210:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0106215:	e8 00 ff ff ff       	call   f010611a <lapicw>
	lapicw(EOI, 0);
f010621a:	ba 00 00 00 00       	mov    $0x0,%edx
f010621f:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0106224:	e8 f1 fe ff ff       	call   f010611a <lapicw>
	lapicw(ICRHI, 0);
f0106229:	ba 00 00 00 00       	mov    $0x0,%edx
f010622e:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106233:	e8 e2 fe ff ff       	call   f010611a <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0106238:	ba 00 85 08 00       	mov    $0x88500,%edx
f010623d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106242:	e8 d3 fe ff ff       	call   f010611a <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0106247:	8b 15 04 90 25 f0    	mov    0xf0259004,%edx
f010624d:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0106253:	f6 c4 10             	test   $0x10,%ah
f0106256:	75 f5                	jne    f010624d <lapic_init+0x105>
	lapicw(TPR, 0);
f0106258:	ba 00 00 00 00       	mov    $0x0,%edx
f010625d:	b8 20 00 00 00       	mov    $0x20,%eax
f0106262:	e8 b3 fe ff ff       	call   f010611a <lapicw>
}
f0106267:	c9                   	leave  
f0106268:	c3                   	ret    
		lapicw(PCINT, MASKED);
f0106269:	ba 00 00 01 00       	mov    $0x10000,%edx
f010626e:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0106273:	e8 a2 fe ff ff       	call   f010611a <lapicw>
f0106278:	e9 70 ff ff ff       	jmp    f01061ed <lapic_init+0xa5>

f010627d <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f010627d:	f3 0f 1e fb          	endbr32 
	if (lapic)
f0106281:	83 3d 04 90 25 f0 00 	cmpl   $0x0,0xf0259004
f0106288:	74 17                	je     f01062a1 <lapic_eoi+0x24>
{
f010628a:	55                   	push   %ebp
f010628b:	89 e5                	mov    %esp,%ebp
f010628d:	83 ec 08             	sub    $0x8,%esp
		lapicw(EOI, 0);
f0106290:	ba 00 00 00 00       	mov    $0x0,%edx
f0106295:	b8 2c 00 00 00       	mov    $0x2c,%eax
f010629a:	e8 7b fe ff ff       	call   f010611a <lapicw>
}
f010629f:	c9                   	leave  
f01062a0:	c3                   	ret    
f01062a1:	c3                   	ret    

f01062a2 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f01062a2:	f3 0f 1e fb          	endbr32 
f01062a6:	55                   	push   %ebp
f01062a7:	89 e5                	mov    %esp,%ebp
f01062a9:	56                   	push   %esi
f01062aa:	53                   	push   %ebx
f01062ab:	8b 75 08             	mov    0x8(%ebp),%esi
f01062ae:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01062b1:	b8 0f 00 00 00       	mov    $0xf,%eax
f01062b6:	ba 70 00 00 00       	mov    $0x70,%edx
f01062bb:	ee                   	out    %al,(%dx)
f01062bc:	b8 0a 00 00 00       	mov    $0xa,%eax
f01062c1:	ba 71 00 00 00       	mov    $0x71,%edx
f01062c6:	ee                   	out    %al,(%dx)
	if (PGNUM(pa) >= npages)
f01062c7:	83 3d 88 7e 21 f0 00 	cmpl   $0x0,0xf0217e88
f01062ce:	74 7e                	je     f010634e <lapic_startap+0xac>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f01062d0:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f01062d7:	00 00 
	wrv[1] = addr >> 4;
f01062d9:	89 d8                	mov    %ebx,%eax
f01062db:	c1 e8 04             	shr    $0x4,%eax
f01062de:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f01062e4:	c1 e6 18             	shl    $0x18,%esi
f01062e7:	89 f2                	mov    %esi,%edx
f01062e9:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01062ee:	e8 27 fe ff ff       	call   f010611a <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f01062f3:	ba 00 c5 00 00       	mov    $0xc500,%edx
f01062f8:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01062fd:	e8 18 fe ff ff       	call   f010611a <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0106302:	ba 00 85 00 00       	mov    $0x8500,%edx
f0106307:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010630c:	e8 09 fe ff ff       	call   f010611a <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106311:	c1 eb 0c             	shr    $0xc,%ebx
f0106314:	80 cf 06             	or     $0x6,%bh
		lapicw(ICRHI, apicid << 24);
f0106317:	89 f2                	mov    %esi,%edx
f0106319:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010631e:	e8 f7 fd ff ff       	call   f010611a <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106323:	89 da                	mov    %ebx,%edx
f0106325:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010632a:	e8 eb fd ff ff       	call   f010611a <lapicw>
		lapicw(ICRHI, apicid << 24);
f010632f:	89 f2                	mov    %esi,%edx
f0106331:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106336:	e8 df fd ff ff       	call   f010611a <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f010633b:	89 da                	mov    %ebx,%edx
f010633d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106342:	e8 d3 fd ff ff       	call   f010611a <lapicw>
		microdelay(200);
	}
}
f0106347:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010634a:	5b                   	pop    %ebx
f010634b:	5e                   	pop    %esi
f010634c:	5d                   	pop    %ebp
f010634d:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010634e:	68 67 04 00 00       	push   $0x467
f0106353:	68 c4 67 10 f0       	push   $0xf01067c4
f0106358:	68 98 00 00 00       	push   $0x98
f010635d:	68 74 85 10 f0       	push   $0xf0108574
f0106362:	e8 d9 9c ff ff       	call   f0100040 <_panic>

f0106367 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0106367:	f3 0f 1e fb          	endbr32 
f010636b:	55                   	push   %ebp
f010636c:	89 e5                	mov    %esp,%ebp
f010636e:	83 ec 08             	sub    $0x8,%esp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0106371:	8b 55 08             	mov    0x8(%ebp),%edx
f0106374:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f010637a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010637f:	e8 96 fd ff ff       	call   f010611a <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0106384:	8b 15 04 90 25 f0    	mov    0xf0259004,%edx
f010638a:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0106390:	f6 c4 10             	test   $0x10,%ah
f0106393:	75 f5                	jne    f010638a <lapic_ipi+0x23>
		;
}
f0106395:	c9                   	leave  
f0106396:	c3                   	ret    

f0106397 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0106397:	f3 0f 1e fb          	endbr32 
f010639b:	55                   	push   %ebp
f010639c:	89 e5                	mov    %esp,%ebp
f010639e:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f01063a1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f01063a7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01063aa:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f01063ad:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f01063b4:	5d                   	pop    %ebp
f01063b5:	c3                   	ret    

f01063b6 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f01063b6:	f3 0f 1e fb          	endbr32 
f01063ba:	55                   	push   %ebp
f01063bb:	89 e5                	mov    %esp,%ebp
f01063bd:	56                   	push   %esi
f01063be:	53                   	push   %ebx
f01063bf:	8b 5d 08             	mov    0x8(%ebp),%ebx
	return lock->locked && lock->cpu == thiscpu;
f01063c2:	83 3b 00             	cmpl   $0x0,(%ebx)
f01063c5:	75 07                	jne    f01063ce <spin_lock+0x18>
	asm volatile("lock; xchgl %0, %1"
f01063c7:	ba 01 00 00 00       	mov    $0x1,%edx
f01063cc:	eb 34                	jmp    f0106402 <spin_lock+0x4c>
f01063ce:	8b 73 08             	mov    0x8(%ebx),%esi
f01063d1:	e8 58 fd ff ff       	call   f010612e <cpunum>
f01063d6:	6b c0 74             	imul   $0x74,%eax,%eax
f01063d9:	05 20 80 21 f0       	add    $0xf0218020,%eax
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f01063de:	39 c6                	cmp    %eax,%esi
f01063e0:	75 e5                	jne    f01063c7 <spin_lock+0x11>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f01063e2:	8b 5b 04             	mov    0x4(%ebx),%ebx
f01063e5:	e8 44 fd ff ff       	call   f010612e <cpunum>
f01063ea:	83 ec 0c             	sub    $0xc,%esp
f01063ed:	53                   	push   %ebx
f01063ee:	50                   	push   %eax
f01063ef:	68 84 85 10 f0       	push   $0xf0108584
f01063f4:	6a 41                	push   $0x41
f01063f6:	68 e6 85 10 f0       	push   $0xf01085e6
f01063fb:	e8 40 9c ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0106400:	f3 90                	pause  
f0106402:	89 d0                	mov    %edx,%eax
f0106404:	f0 87 03             	lock xchg %eax,(%ebx)
	while (xchg(&lk->locked, 1) != 0)
f0106407:	85 c0                	test   %eax,%eax
f0106409:	75 f5                	jne    f0106400 <spin_lock+0x4a>

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f010640b:	e8 1e fd ff ff       	call   f010612e <cpunum>
f0106410:	6b c0 74             	imul   $0x74,%eax,%eax
f0106413:	05 20 80 21 f0       	add    $0xf0218020,%eax
f0106418:	89 43 08             	mov    %eax,0x8(%ebx)
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010641b:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f010641d:	b8 00 00 00 00       	mov    $0x0,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0106422:	83 f8 09             	cmp    $0x9,%eax
f0106425:	7f 21                	jg     f0106448 <spin_lock+0x92>
f0106427:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f010642d:	76 19                	jbe    f0106448 <spin_lock+0x92>
		pcs[i] = ebp[1];          // saved %eip
f010642f:	8b 4a 04             	mov    0x4(%edx),%ecx
f0106432:	89 4c 83 0c          	mov    %ecx,0xc(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0106436:	8b 12                	mov    (%edx),%edx
	for (i = 0; i < 10; i++){
f0106438:	83 c0 01             	add    $0x1,%eax
f010643b:	eb e5                	jmp    f0106422 <spin_lock+0x6c>
		pcs[i] = 0;
f010643d:	c7 44 83 0c 00 00 00 	movl   $0x0,0xc(%ebx,%eax,4)
f0106444:	00 
	for (; i < 10; i++)
f0106445:	83 c0 01             	add    $0x1,%eax
f0106448:	83 f8 09             	cmp    $0x9,%eax
f010644b:	7e f0                	jle    f010643d <spin_lock+0x87>
	get_caller_pcs(lk->pcs);
#endif
}
f010644d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0106450:	5b                   	pop    %ebx
f0106451:	5e                   	pop    %esi
f0106452:	5d                   	pop    %ebp
f0106453:	c3                   	ret    

f0106454 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0106454:	f3 0f 1e fb          	endbr32 
f0106458:	55                   	push   %ebp
f0106459:	89 e5                	mov    %esp,%ebp
f010645b:	57                   	push   %edi
f010645c:	56                   	push   %esi
f010645d:	53                   	push   %ebx
f010645e:	83 ec 4c             	sub    $0x4c,%esp
f0106461:	8b 75 08             	mov    0x8(%ebp),%esi
	return lock->locked && lock->cpu == thiscpu;
f0106464:	83 3e 00             	cmpl   $0x0,(%esi)
f0106467:	75 35                	jne    f010649e <spin_unlock+0x4a>
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0106469:	83 ec 04             	sub    $0x4,%esp
f010646c:	6a 28                	push   $0x28
f010646e:	8d 46 0c             	lea    0xc(%esi),%eax
f0106471:	50                   	push   %eax
f0106472:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0106475:	53                   	push   %ebx
f0106476:	e8 e1 f6 ff ff       	call   f0105b5c <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f010647b:	8b 46 08             	mov    0x8(%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f010647e:	0f b6 38             	movzbl (%eax),%edi
f0106481:	8b 76 04             	mov    0x4(%esi),%esi
f0106484:	e8 a5 fc ff ff       	call   f010612e <cpunum>
f0106489:	57                   	push   %edi
f010648a:	56                   	push   %esi
f010648b:	50                   	push   %eax
f010648c:	68 b0 85 10 f0       	push   $0xf01085b0
f0106491:	e8 2b d5 ff ff       	call   f01039c1 <cprintf>
f0106496:	83 c4 20             	add    $0x20,%esp
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0106499:	8d 7d a8             	lea    -0x58(%ebp),%edi
f010649c:	eb 4e                	jmp    f01064ec <spin_unlock+0x98>
	return lock->locked && lock->cpu == thiscpu;
f010649e:	8b 5e 08             	mov    0x8(%esi),%ebx
f01064a1:	e8 88 fc ff ff       	call   f010612e <cpunum>
f01064a6:	6b c0 74             	imul   $0x74,%eax,%eax
f01064a9:	05 20 80 21 f0       	add    $0xf0218020,%eax
	if (!holding(lk)) {
f01064ae:	39 c3                	cmp    %eax,%ebx
f01064b0:	75 b7                	jne    f0106469 <spin_unlock+0x15>
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
	}

	lk->pcs[0] = 0;
f01064b2:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f01064b9:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
	asm volatile("lock; xchgl %0, %1"
f01064c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01064c5:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f01064c8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01064cb:	5b                   	pop    %ebx
f01064cc:	5e                   	pop    %esi
f01064cd:	5f                   	pop    %edi
f01064ce:	5d                   	pop    %ebp
f01064cf:	c3                   	ret    
				cprintf("  %08x\n", pcs[i]);
f01064d0:	83 ec 08             	sub    $0x8,%esp
f01064d3:	ff 36                	pushl  (%esi)
f01064d5:	68 0d 86 10 f0       	push   $0xf010860d
f01064da:	e8 e2 d4 ff ff       	call   f01039c1 <cprintf>
f01064df:	83 c4 10             	add    $0x10,%esp
f01064e2:	83 c3 04             	add    $0x4,%ebx
		for (i = 0; i < 10 && pcs[i]; i++) {
f01064e5:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01064e8:	39 c3                	cmp    %eax,%ebx
f01064ea:	74 40                	je     f010652c <spin_unlock+0xd8>
f01064ec:	89 de                	mov    %ebx,%esi
f01064ee:	8b 03                	mov    (%ebx),%eax
f01064f0:	85 c0                	test   %eax,%eax
f01064f2:	74 38                	je     f010652c <spin_unlock+0xd8>
			if (debuginfo_eip(pcs[i], &info) >= 0)
f01064f4:	83 ec 08             	sub    $0x8,%esp
f01064f7:	57                   	push   %edi
f01064f8:	50                   	push   %eax
f01064f9:	e8 cd ea ff ff       	call   f0104fcb <debuginfo_eip>
f01064fe:	83 c4 10             	add    $0x10,%esp
f0106501:	85 c0                	test   %eax,%eax
f0106503:	78 cb                	js     f01064d0 <spin_unlock+0x7c>
					pcs[i] - info.eip_fn_addr);
f0106505:	8b 06                	mov    (%esi),%eax
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0106507:	83 ec 04             	sub    $0x4,%esp
f010650a:	89 c2                	mov    %eax,%edx
f010650c:	2b 55 b8             	sub    -0x48(%ebp),%edx
f010650f:	52                   	push   %edx
f0106510:	ff 75 b0             	pushl  -0x50(%ebp)
f0106513:	ff 75 b4             	pushl  -0x4c(%ebp)
f0106516:	ff 75 ac             	pushl  -0x54(%ebp)
f0106519:	ff 75 a8             	pushl  -0x58(%ebp)
f010651c:	50                   	push   %eax
f010651d:	68 f6 85 10 f0       	push   $0xf01085f6
f0106522:	e8 9a d4 ff ff       	call   f01039c1 <cprintf>
f0106527:	83 c4 20             	add    $0x20,%esp
f010652a:	eb b6                	jmp    f01064e2 <spin_unlock+0x8e>
		panic("spin_unlock");
f010652c:	83 ec 04             	sub    $0x4,%esp
f010652f:	68 15 86 10 f0       	push   $0xf0108615
f0106534:	6a 67                	push   $0x67
f0106536:	68 e6 85 10 f0       	push   $0xf01085e6
f010653b:	e8 00 9b ff ff       	call   f0100040 <_panic>

f0106540 <__udivdi3>:
f0106540:	f3 0f 1e fb          	endbr32 
f0106544:	55                   	push   %ebp
f0106545:	57                   	push   %edi
f0106546:	56                   	push   %esi
f0106547:	53                   	push   %ebx
f0106548:	83 ec 1c             	sub    $0x1c,%esp
f010654b:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010654f:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0106553:	8b 74 24 34          	mov    0x34(%esp),%esi
f0106557:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f010655b:	85 d2                	test   %edx,%edx
f010655d:	75 19                	jne    f0106578 <__udivdi3+0x38>
f010655f:	39 f3                	cmp    %esi,%ebx
f0106561:	76 4d                	jbe    f01065b0 <__udivdi3+0x70>
f0106563:	31 ff                	xor    %edi,%edi
f0106565:	89 e8                	mov    %ebp,%eax
f0106567:	89 f2                	mov    %esi,%edx
f0106569:	f7 f3                	div    %ebx
f010656b:	89 fa                	mov    %edi,%edx
f010656d:	83 c4 1c             	add    $0x1c,%esp
f0106570:	5b                   	pop    %ebx
f0106571:	5e                   	pop    %esi
f0106572:	5f                   	pop    %edi
f0106573:	5d                   	pop    %ebp
f0106574:	c3                   	ret    
f0106575:	8d 76 00             	lea    0x0(%esi),%esi
f0106578:	39 f2                	cmp    %esi,%edx
f010657a:	76 14                	jbe    f0106590 <__udivdi3+0x50>
f010657c:	31 ff                	xor    %edi,%edi
f010657e:	31 c0                	xor    %eax,%eax
f0106580:	89 fa                	mov    %edi,%edx
f0106582:	83 c4 1c             	add    $0x1c,%esp
f0106585:	5b                   	pop    %ebx
f0106586:	5e                   	pop    %esi
f0106587:	5f                   	pop    %edi
f0106588:	5d                   	pop    %ebp
f0106589:	c3                   	ret    
f010658a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0106590:	0f bd fa             	bsr    %edx,%edi
f0106593:	83 f7 1f             	xor    $0x1f,%edi
f0106596:	75 48                	jne    f01065e0 <__udivdi3+0xa0>
f0106598:	39 f2                	cmp    %esi,%edx
f010659a:	72 06                	jb     f01065a2 <__udivdi3+0x62>
f010659c:	31 c0                	xor    %eax,%eax
f010659e:	39 eb                	cmp    %ebp,%ebx
f01065a0:	77 de                	ja     f0106580 <__udivdi3+0x40>
f01065a2:	b8 01 00 00 00       	mov    $0x1,%eax
f01065a7:	eb d7                	jmp    f0106580 <__udivdi3+0x40>
f01065a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01065b0:	89 d9                	mov    %ebx,%ecx
f01065b2:	85 db                	test   %ebx,%ebx
f01065b4:	75 0b                	jne    f01065c1 <__udivdi3+0x81>
f01065b6:	b8 01 00 00 00       	mov    $0x1,%eax
f01065bb:	31 d2                	xor    %edx,%edx
f01065bd:	f7 f3                	div    %ebx
f01065bf:	89 c1                	mov    %eax,%ecx
f01065c1:	31 d2                	xor    %edx,%edx
f01065c3:	89 f0                	mov    %esi,%eax
f01065c5:	f7 f1                	div    %ecx
f01065c7:	89 c6                	mov    %eax,%esi
f01065c9:	89 e8                	mov    %ebp,%eax
f01065cb:	89 f7                	mov    %esi,%edi
f01065cd:	f7 f1                	div    %ecx
f01065cf:	89 fa                	mov    %edi,%edx
f01065d1:	83 c4 1c             	add    $0x1c,%esp
f01065d4:	5b                   	pop    %ebx
f01065d5:	5e                   	pop    %esi
f01065d6:	5f                   	pop    %edi
f01065d7:	5d                   	pop    %ebp
f01065d8:	c3                   	ret    
f01065d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01065e0:	89 f9                	mov    %edi,%ecx
f01065e2:	b8 20 00 00 00       	mov    $0x20,%eax
f01065e7:	29 f8                	sub    %edi,%eax
f01065e9:	d3 e2                	shl    %cl,%edx
f01065eb:	89 54 24 08          	mov    %edx,0x8(%esp)
f01065ef:	89 c1                	mov    %eax,%ecx
f01065f1:	89 da                	mov    %ebx,%edx
f01065f3:	d3 ea                	shr    %cl,%edx
f01065f5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f01065f9:	09 d1                	or     %edx,%ecx
f01065fb:	89 f2                	mov    %esi,%edx
f01065fd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106601:	89 f9                	mov    %edi,%ecx
f0106603:	d3 e3                	shl    %cl,%ebx
f0106605:	89 c1                	mov    %eax,%ecx
f0106607:	d3 ea                	shr    %cl,%edx
f0106609:	89 f9                	mov    %edi,%ecx
f010660b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010660f:	89 eb                	mov    %ebp,%ebx
f0106611:	d3 e6                	shl    %cl,%esi
f0106613:	89 c1                	mov    %eax,%ecx
f0106615:	d3 eb                	shr    %cl,%ebx
f0106617:	09 de                	or     %ebx,%esi
f0106619:	89 f0                	mov    %esi,%eax
f010661b:	f7 74 24 08          	divl   0x8(%esp)
f010661f:	89 d6                	mov    %edx,%esi
f0106621:	89 c3                	mov    %eax,%ebx
f0106623:	f7 64 24 0c          	mull   0xc(%esp)
f0106627:	39 d6                	cmp    %edx,%esi
f0106629:	72 15                	jb     f0106640 <__udivdi3+0x100>
f010662b:	89 f9                	mov    %edi,%ecx
f010662d:	d3 e5                	shl    %cl,%ebp
f010662f:	39 c5                	cmp    %eax,%ebp
f0106631:	73 04                	jae    f0106637 <__udivdi3+0xf7>
f0106633:	39 d6                	cmp    %edx,%esi
f0106635:	74 09                	je     f0106640 <__udivdi3+0x100>
f0106637:	89 d8                	mov    %ebx,%eax
f0106639:	31 ff                	xor    %edi,%edi
f010663b:	e9 40 ff ff ff       	jmp    f0106580 <__udivdi3+0x40>
f0106640:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0106643:	31 ff                	xor    %edi,%edi
f0106645:	e9 36 ff ff ff       	jmp    f0106580 <__udivdi3+0x40>
f010664a:	66 90                	xchg   %ax,%ax
f010664c:	66 90                	xchg   %ax,%ax
f010664e:	66 90                	xchg   %ax,%ax

f0106650 <__umoddi3>:
f0106650:	f3 0f 1e fb          	endbr32 
f0106654:	55                   	push   %ebp
f0106655:	57                   	push   %edi
f0106656:	56                   	push   %esi
f0106657:	53                   	push   %ebx
f0106658:	83 ec 1c             	sub    $0x1c,%esp
f010665b:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010665f:	8b 74 24 30          	mov    0x30(%esp),%esi
f0106663:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0106667:	8b 7c 24 38          	mov    0x38(%esp),%edi
f010666b:	85 c0                	test   %eax,%eax
f010666d:	75 19                	jne    f0106688 <__umoddi3+0x38>
f010666f:	39 df                	cmp    %ebx,%edi
f0106671:	76 5d                	jbe    f01066d0 <__umoddi3+0x80>
f0106673:	89 f0                	mov    %esi,%eax
f0106675:	89 da                	mov    %ebx,%edx
f0106677:	f7 f7                	div    %edi
f0106679:	89 d0                	mov    %edx,%eax
f010667b:	31 d2                	xor    %edx,%edx
f010667d:	83 c4 1c             	add    $0x1c,%esp
f0106680:	5b                   	pop    %ebx
f0106681:	5e                   	pop    %esi
f0106682:	5f                   	pop    %edi
f0106683:	5d                   	pop    %ebp
f0106684:	c3                   	ret    
f0106685:	8d 76 00             	lea    0x0(%esi),%esi
f0106688:	89 f2                	mov    %esi,%edx
f010668a:	39 d8                	cmp    %ebx,%eax
f010668c:	76 12                	jbe    f01066a0 <__umoddi3+0x50>
f010668e:	89 f0                	mov    %esi,%eax
f0106690:	89 da                	mov    %ebx,%edx
f0106692:	83 c4 1c             	add    $0x1c,%esp
f0106695:	5b                   	pop    %ebx
f0106696:	5e                   	pop    %esi
f0106697:	5f                   	pop    %edi
f0106698:	5d                   	pop    %ebp
f0106699:	c3                   	ret    
f010669a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01066a0:	0f bd e8             	bsr    %eax,%ebp
f01066a3:	83 f5 1f             	xor    $0x1f,%ebp
f01066a6:	75 50                	jne    f01066f8 <__umoddi3+0xa8>
f01066a8:	39 d8                	cmp    %ebx,%eax
f01066aa:	0f 82 e0 00 00 00    	jb     f0106790 <__umoddi3+0x140>
f01066b0:	89 d9                	mov    %ebx,%ecx
f01066b2:	39 f7                	cmp    %esi,%edi
f01066b4:	0f 86 d6 00 00 00    	jbe    f0106790 <__umoddi3+0x140>
f01066ba:	89 d0                	mov    %edx,%eax
f01066bc:	89 ca                	mov    %ecx,%edx
f01066be:	83 c4 1c             	add    $0x1c,%esp
f01066c1:	5b                   	pop    %ebx
f01066c2:	5e                   	pop    %esi
f01066c3:	5f                   	pop    %edi
f01066c4:	5d                   	pop    %ebp
f01066c5:	c3                   	ret    
f01066c6:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01066cd:	8d 76 00             	lea    0x0(%esi),%esi
f01066d0:	89 fd                	mov    %edi,%ebp
f01066d2:	85 ff                	test   %edi,%edi
f01066d4:	75 0b                	jne    f01066e1 <__umoddi3+0x91>
f01066d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01066db:	31 d2                	xor    %edx,%edx
f01066dd:	f7 f7                	div    %edi
f01066df:	89 c5                	mov    %eax,%ebp
f01066e1:	89 d8                	mov    %ebx,%eax
f01066e3:	31 d2                	xor    %edx,%edx
f01066e5:	f7 f5                	div    %ebp
f01066e7:	89 f0                	mov    %esi,%eax
f01066e9:	f7 f5                	div    %ebp
f01066eb:	89 d0                	mov    %edx,%eax
f01066ed:	31 d2                	xor    %edx,%edx
f01066ef:	eb 8c                	jmp    f010667d <__umoddi3+0x2d>
f01066f1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01066f8:	89 e9                	mov    %ebp,%ecx
f01066fa:	ba 20 00 00 00       	mov    $0x20,%edx
f01066ff:	29 ea                	sub    %ebp,%edx
f0106701:	d3 e0                	shl    %cl,%eax
f0106703:	89 44 24 08          	mov    %eax,0x8(%esp)
f0106707:	89 d1                	mov    %edx,%ecx
f0106709:	89 f8                	mov    %edi,%eax
f010670b:	d3 e8                	shr    %cl,%eax
f010670d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0106711:	89 54 24 04          	mov    %edx,0x4(%esp)
f0106715:	8b 54 24 04          	mov    0x4(%esp),%edx
f0106719:	09 c1                	or     %eax,%ecx
f010671b:	89 d8                	mov    %ebx,%eax
f010671d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106721:	89 e9                	mov    %ebp,%ecx
f0106723:	d3 e7                	shl    %cl,%edi
f0106725:	89 d1                	mov    %edx,%ecx
f0106727:	d3 e8                	shr    %cl,%eax
f0106729:	89 e9                	mov    %ebp,%ecx
f010672b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010672f:	d3 e3                	shl    %cl,%ebx
f0106731:	89 c7                	mov    %eax,%edi
f0106733:	89 d1                	mov    %edx,%ecx
f0106735:	89 f0                	mov    %esi,%eax
f0106737:	d3 e8                	shr    %cl,%eax
f0106739:	89 e9                	mov    %ebp,%ecx
f010673b:	89 fa                	mov    %edi,%edx
f010673d:	d3 e6                	shl    %cl,%esi
f010673f:	09 d8                	or     %ebx,%eax
f0106741:	f7 74 24 08          	divl   0x8(%esp)
f0106745:	89 d1                	mov    %edx,%ecx
f0106747:	89 f3                	mov    %esi,%ebx
f0106749:	f7 64 24 0c          	mull   0xc(%esp)
f010674d:	89 c6                	mov    %eax,%esi
f010674f:	89 d7                	mov    %edx,%edi
f0106751:	39 d1                	cmp    %edx,%ecx
f0106753:	72 06                	jb     f010675b <__umoddi3+0x10b>
f0106755:	75 10                	jne    f0106767 <__umoddi3+0x117>
f0106757:	39 c3                	cmp    %eax,%ebx
f0106759:	73 0c                	jae    f0106767 <__umoddi3+0x117>
f010675b:	2b 44 24 0c          	sub    0xc(%esp),%eax
f010675f:	1b 54 24 08          	sbb    0x8(%esp),%edx
f0106763:	89 d7                	mov    %edx,%edi
f0106765:	89 c6                	mov    %eax,%esi
f0106767:	89 ca                	mov    %ecx,%edx
f0106769:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010676e:	29 f3                	sub    %esi,%ebx
f0106770:	19 fa                	sbb    %edi,%edx
f0106772:	89 d0                	mov    %edx,%eax
f0106774:	d3 e0                	shl    %cl,%eax
f0106776:	89 e9                	mov    %ebp,%ecx
f0106778:	d3 eb                	shr    %cl,%ebx
f010677a:	d3 ea                	shr    %cl,%edx
f010677c:	09 d8                	or     %ebx,%eax
f010677e:	83 c4 1c             	add    $0x1c,%esp
f0106781:	5b                   	pop    %ebx
f0106782:	5e                   	pop    %esi
f0106783:	5f                   	pop    %edi
f0106784:	5d                   	pop    %ebp
f0106785:	c3                   	ret    
f0106786:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f010678d:	8d 76 00             	lea    0x0(%esi),%esi
f0106790:	29 fe                	sub    %edi,%esi
f0106792:	19 c3                	sbb    %eax,%ebx
f0106794:	89 f2                	mov    %esi,%edx
f0106796:	89 d9                	mov    %ebx,%ecx
f0106798:	e9 1d ff ff ff       	jmp    f01066ba <__umoddi3+0x6a>
