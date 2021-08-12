
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
f010004c:	83 3d 80 9e 23 f0 00 	cmpl   $0x0,0xf0239e80
f0100053:	74 0f                	je     f0100064 <_panic+0x24>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100055:	83 ec 0c             	sub    $0xc,%esp
f0100058:	6a 00                	push   $0x0
f010005a:	e8 15 09 00 00       	call   f0100974 <monitor>
f010005f:	83 c4 10             	add    $0x10,%esp
f0100062:	eb f1                	jmp    f0100055 <_panic+0x15>
	panicstr = fmt;
f0100064:	89 35 80 9e 23 f0    	mov    %esi,0xf0239e80
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
f0100080:	e8 4f 39 00 00       	call   f01039d4 <cprintf>
	vcprintf(fmt, ap);
f0100085:	83 c4 08             	add    $0x8,%esp
f0100088:	53                   	push   %ebx
f0100089:	56                   	push   %esi
f010008a:	e8 1b 39 00 00       	call   f01039aa <vcprintf>
	cprintf("\n");
f010008f:	c7 04 24 fd 79 10 f0 	movl   $0xf01079fd,(%esp)
f0100096:	e8 39 39 00 00       	call   f01039d4 <cprintf>
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
f01000ab:	e8 aa 05 00 00       	call   f010065a <cons_init>
	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b0:	83 ec 08             	sub    $0x8,%esp
f01000b3:	68 ac 1a 00 00       	push   $0x1aac
f01000b8:	68 2c 68 10 f0       	push   $0xf010682c
f01000bd:	e8 12 39 00 00       	call   f01039d4 <cprintf>
	mem_init();
f01000c2:	e8 66 12 00 00       	call   f010132d <mem_init>
	env_init();
f01000c7:	e8 ac 30 00 00       	call   f0103178 <env_init>
	trap_init();
f01000cc:	e8 ff 39 00 00       	call   f0103ad0 <trap_init>
	mp_init();
f01000d1:	e8 79 5d 00 00       	call   f0105e4f <mp_init>
	lapic_init();
f01000d6:	e8 8d 60 00 00       	call   f0106168 <lapic_init>
	pic_init();
f01000db:	e8 09 38 00 00       	call   f01038e9 <pic_init>
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
f01000ef:	83 3d 88 9e 23 f0 07 	cmpl   $0x7,0xf0239e88
f01000f6:	76 27                	jbe    f010011f <i386_init+0x7f>
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f01000f8:	83 ec 04             	sub    $0x4,%esp
f01000fb:	b8 b2 5d 10 f0       	mov    $0xf0105db2,%eax
f0100100:	2d 38 5d 10 f0       	sub    $0xf0105d38,%eax
f0100105:	50                   	push   %eax
f0100106:	68 38 5d 10 f0       	push   $0xf0105d38
f010010b:	68 00 70 00 f0       	push   $0xf0007000
f0100110:	e8 67 5a 00 00       	call   f0105b7c <memmove>
	for (c = cpus; c < cpus + ncpu; c++) {
f0100115:	83 c4 10             	add    $0x10,%esp
f0100118:	bb 20 a0 23 f0       	mov    $0xf023a020,%ebx
f010011d:	eb 53                	jmp    f0100172 <i386_init+0xd2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010011f:	68 00 70 00 00       	push   $0x7000
f0100124:	68 e4 67 10 f0       	push   $0xf01067e4
f0100129:	6a 4e                	push   $0x4e
f010012b:	68 47 68 10 f0       	push   $0xf0106847
f0100130:	e8 0b ff ff ff       	call   f0100040 <_panic>
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100135:	89 d8                	mov    %ebx,%eax
f0100137:	2d 20 a0 23 f0       	sub    $0xf023a020,%eax
f010013c:	c1 f8 02             	sar    $0x2,%eax
f010013f:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100145:	c1 e0 0f             	shl    $0xf,%eax
f0100148:	8d 80 00 30 24 f0    	lea    -0xfdbd000(%eax),%eax
f010014e:	a3 84 9e 23 f0       	mov    %eax,0xf0239e84
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
f0100172:	6b 05 c4 a3 23 f0 74 	imul   $0x74,0xf023a3c4,%eax
f0100179:	05 20 a0 23 f0       	add    $0xf023a020,%eax
f010017e:	39 c3                	cmp    %eax,%ebx
f0100180:	73 13                	jae    f0100195 <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100182:	e8 c7 5f 00 00       	call   f010614e <cpunum>
f0100187:	6b c0 74             	imul   $0x74,%eax,%eax
f010018a:	05 20 a0 23 f0       	add    $0xf023a020,%eax
f010018f:	39 c3                	cmp    %eax,%ebx
f0100191:	74 dc                	je     f010016f <i386_init+0xcf>
f0100193:	eb a0                	jmp    f0100135 <i386_init+0x95>
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100195:	83 ec 08             	sub    $0x8,%esp
f0100198:	6a 00                	push   $0x0
f010019a:	68 c0 b7 21 f0       	push   $0xf021b7c0
f010019f:	e8 d7 31 00 00       	call   f010337b <env_create>
	sched_yield();
f01001a4:	e8 c8 46 00 00       	call   f0104871 <sched_yield>

f01001a9 <mp_main>:
{
f01001a9:	f3 0f 1e fb          	endbr32 
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	83 ec 08             	sub    $0x8,%esp
	lcr3(PADDR(kern_pgdir));
f01001b3:	a1 8c 9e 23 f0       	mov    0xf0239e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01001b8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001bd:	76 52                	jbe    f0100211 <mp_main+0x68>
	return (physaddr_t)kva - KERNBASE;
f01001bf:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01001c4:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001c7:	e8 82 5f 00 00       	call   f010614e <cpunum>
f01001cc:	83 ec 08             	sub    $0x8,%esp
f01001cf:	50                   	push   %eax
f01001d0:	68 53 68 10 f0       	push   $0xf0106853
f01001d5:	e8 fa 37 00 00       	call   f01039d4 <cprintf>
	lapic_init();
f01001da:	e8 89 5f 00 00       	call   f0106168 <lapic_init>
	env_init_percpu();
f01001df:	e8 64 2f 00 00       	call   f0103148 <env_init_percpu>
	trap_init_percpu();
f01001e4:	e8 03 38 00 00       	call   f01039ec <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f01001e9:	e8 60 5f 00 00       	call   f010614e <cpunum>
f01001ee:	6b d0 74             	imul   $0x74,%eax,%edx
f01001f1:	83 c2 04             	add    $0x4,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f01001f4:	b8 01 00 00 00       	mov    $0x1,%eax
f01001f9:	f0 87 82 20 a0 23 f0 	lock xchg %eax,-0xfdc5fe0(%edx)
f0100200:	c7 04 24 c0 33 12 f0 	movl   $0xf01233c0,(%esp)
f0100207:	e8 ca 61 00 00       	call   f01063d6 <spin_lock>
	sched_yield();
f010020c:	e8 60 46 00 00       	call   f0104871 <sched_yield>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100211:	50                   	push   %eax
f0100212:	68 08 68 10 f0       	push   $0xf0106808
f0100217:	6a 65                	push   $0x65
f0100219:	68 47 68 10 f0       	push   $0xf0106847
f010021e:	e8 1d fe ff ff       	call   f0100040 <_panic>

f0100223 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100223:	f3 0f 1e fb          	endbr32 
f0100227:	55                   	push   %ebp
f0100228:	89 e5                	mov    %esp,%ebp
f010022a:	53                   	push   %ebx
f010022b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010022e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100231:	ff 75 0c             	pushl  0xc(%ebp)
f0100234:	ff 75 08             	pushl  0x8(%ebp)
f0100237:	68 69 68 10 f0       	push   $0xf0106869
f010023c:	e8 93 37 00 00       	call   f01039d4 <cprintf>
	vcprintf(fmt, ap);
f0100241:	83 c4 08             	add    $0x8,%esp
f0100244:	53                   	push   %ebx
f0100245:	ff 75 10             	pushl  0x10(%ebp)
f0100248:	e8 5d 37 00 00       	call   f01039aa <vcprintf>
	cprintf("\n");
f010024d:	c7 04 24 fd 79 10 f0 	movl   $0xf01079fd,(%esp)
f0100254:	e8 7b 37 00 00       	call   f01039d4 <cprintf>
	va_end(ap);
}
f0100259:	83 c4 10             	add    $0x10,%esp
f010025c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010025f:	c9                   	leave  
f0100260:	c3                   	ret    

f0100261 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100261:	f3 0f 1e fb          	endbr32 
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100265:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010026a:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010026b:	a8 01                	test   $0x1,%al
f010026d:	74 0a                	je     f0100279 <serial_proc_data+0x18>
f010026f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100274:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100275:	0f b6 c0             	movzbl %al,%eax
f0100278:	c3                   	ret    
		return -1;
f0100279:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f010027e:	c3                   	ret    

f010027f <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010027f:	55                   	push   %ebp
f0100280:	89 e5                	mov    %esp,%ebp
f0100282:	53                   	push   %ebx
f0100283:	83 ec 04             	sub    $0x4,%esp
f0100286:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100288:	ff d3                	call   *%ebx
f010028a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010028d:	74 29                	je     f01002b8 <cons_intr+0x39>
		if (c == 0)
f010028f:	85 c0                	test   %eax,%eax
f0100291:	74 f5                	je     f0100288 <cons_intr+0x9>
			continue;
		cons.buf[cons.wpos++] = c;
f0100293:	8b 0d 24 92 23 f0    	mov    0xf0239224,%ecx
f0100299:	8d 51 01             	lea    0x1(%ecx),%edx
f010029c:	88 81 20 90 23 f0    	mov    %al,-0xfdc6fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002a2:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01002a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01002ad:	0f 44 d0             	cmove  %eax,%edx
f01002b0:	89 15 24 92 23 f0    	mov    %edx,0xf0239224
f01002b6:	eb d0                	jmp    f0100288 <cons_intr+0x9>
	}
}
f01002b8:	83 c4 04             	add    $0x4,%esp
f01002bb:	5b                   	pop    %ebx
f01002bc:	5d                   	pop    %ebp
f01002bd:	c3                   	ret    

f01002be <kbd_proc_data>:
{
f01002be:	f3 0f 1e fb          	endbr32 
f01002c2:	55                   	push   %ebp
f01002c3:	89 e5                	mov    %esp,%ebp
f01002c5:	53                   	push   %ebx
f01002c6:	83 ec 04             	sub    $0x4,%esp
f01002c9:	ba 64 00 00 00       	mov    $0x64,%edx
f01002ce:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01002cf:	a8 01                	test   $0x1,%al
f01002d1:	0f 84 f2 00 00 00    	je     f01003c9 <kbd_proc_data+0x10b>
	if (stat & KBS_TERR)
f01002d7:	a8 20                	test   $0x20,%al
f01002d9:	0f 85 f1 00 00 00    	jne    f01003d0 <kbd_proc_data+0x112>
f01002df:	ba 60 00 00 00       	mov    $0x60,%edx
f01002e4:	ec                   	in     (%dx),%al
f01002e5:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01002e7:	3c e0                	cmp    $0xe0,%al
f01002e9:	74 61                	je     f010034c <kbd_proc_data+0x8e>
	} else if (data & 0x80) {
f01002eb:	84 c0                	test   %al,%al
f01002ed:	78 70                	js     f010035f <kbd_proc_data+0xa1>
	} else if (shift & E0ESC) {
f01002ef:	8b 0d 00 90 23 f0    	mov    0xf0239000,%ecx
f01002f5:	f6 c1 40             	test   $0x40,%cl
f01002f8:	74 0e                	je     f0100308 <kbd_proc_data+0x4a>
		data |= 0x80;
f01002fa:	83 c8 80             	or     $0xffffff80,%eax
f01002fd:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01002ff:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100302:	89 0d 00 90 23 f0    	mov    %ecx,0xf0239000
	shift |= shiftcode[data];
f0100308:	0f b6 d2             	movzbl %dl,%edx
f010030b:	0f b6 82 e0 69 10 f0 	movzbl -0xfef9620(%edx),%eax
f0100312:	0b 05 00 90 23 f0    	or     0xf0239000,%eax
	shift ^= togglecode[data];
f0100318:	0f b6 8a e0 68 10 f0 	movzbl -0xfef9720(%edx),%ecx
f010031f:	31 c8                	xor    %ecx,%eax
f0100321:	a3 00 90 23 f0       	mov    %eax,0xf0239000
	c = charcode[shift & (CTL | SHIFT)][data];
f0100326:	89 c1                	mov    %eax,%ecx
f0100328:	83 e1 03             	and    $0x3,%ecx
f010032b:	8b 0c 8d c0 68 10 f0 	mov    -0xfef9740(,%ecx,4),%ecx
f0100332:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100336:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100339:	a8 08                	test   $0x8,%al
f010033b:	74 61                	je     f010039e <kbd_proc_data+0xe0>
		if ('a' <= c && c <= 'z')
f010033d:	89 da                	mov    %ebx,%edx
f010033f:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100342:	83 f9 19             	cmp    $0x19,%ecx
f0100345:	77 4b                	ja     f0100392 <kbd_proc_data+0xd4>
			c += 'A' - 'a';
f0100347:	83 eb 20             	sub    $0x20,%ebx
f010034a:	eb 0c                	jmp    f0100358 <kbd_proc_data+0x9a>
		shift |= E0ESC;
f010034c:	83 0d 00 90 23 f0 40 	orl    $0x40,0xf0239000
		return 0;
f0100353:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0100358:	89 d8                	mov    %ebx,%eax
f010035a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010035d:	c9                   	leave  
f010035e:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010035f:	8b 0d 00 90 23 f0    	mov    0xf0239000,%ecx
f0100365:	89 cb                	mov    %ecx,%ebx
f0100367:	83 e3 40             	and    $0x40,%ebx
f010036a:	83 e0 7f             	and    $0x7f,%eax
f010036d:	85 db                	test   %ebx,%ebx
f010036f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100372:	0f b6 d2             	movzbl %dl,%edx
f0100375:	0f b6 82 e0 69 10 f0 	movzbl -0xfef9620(%edx),%eax
f010037c:	83 c8 40             	or     $0x40,%eax
f010037f:	0f b6 c0             	movzbl %al,%eax
f0100382:	f7 d0                	not    %eax
f0100384:	21 c8                	and    %ecx,%eax
f0100386:	a3 00 90 23 f0       	mov    %eax,0xf0239000
		return 0;
f010038b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100390:	eb c6                	jmp    f0100358 <kbd_proc_data+0x9a>
		else if ('A' <= c && c <= 'Z')
f0100392:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100395:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100398:	83 fa 1a             	cmp    $0x1a,%edx
f010039b:	0f 42 d9             	cmovb  %ecx,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010039e:	f7 d0                	not    %eax
f01003a0:	a8 06                	test   $0x6,%al
f01003a2:	75 b4                	jne    f0100358 <kbd_proc_data+0x9a>
f01003a4:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003aa:	75 ac                	jne    f0100358 <kbd_proc_data+0x9a>
		cprintf("Rebooting!\n");
f01003ac:	83 ec 0c             	sub    $0xc,%esp
f01003af:	68 83 68 10 f0       	push   $0xf0106883
f01003b4:	e8 1b 36 00 00       	call   f01039d4 <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003b9:	b8 03 00 00 00       	mov    $0x3,%eax
f01003be:	ba 92 00 00 00       	mov    $0x92,%edx
f01003c3:	ee                   	out    %al,(%dx)
}
f01003c4:	83 c4 10             	add    $0x10,%esp
f01003c7:	eb 8f                	jmp    f0100358 <kbd_proc_data+0x9a>
		return -1;
f01003c9:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01003ce:	eb 88                	jmp    f0100358 <kbd_proc_data+0x9a>
		return -1;
f01003d0:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01003d5:	eb 81                	jmp    f0100358 <kbd_proc_data+0x9a>

f01003d7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003d7:	55                   	push   %ebp
f01003d8:	89 e5                	mov    %esp,%ebp
f01003da:	57                   	push   %edi
f01003db:	56                   	push   %esi
f01003dc:	53                   	push   %ebx
f01003dd:	83 ec 0c             	sub    $0xc,%esp
f01003e0:	89 c1                	mov    %eax,%ecx
	for (i = 0;
f01003e2:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003e7:	bf fd 03 00 00       	mov    $0x3fd,%edi
f01003ec:	bb 84 00 00 00       	mov    $0x84,%ebx
f01003f1:	89 fa                	mov    %edi,%edx
f01003f3:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01003f4:	a8 20                	test   $0x20,%al
f01003f6:	75 13                	jne    f010040b <cons_putc+0x34>
f01003f8:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f01003fe:	7f 0b                	jg     f010040b <cons_putc+0x34>
f0100400:	89 da                	mov    %ebx,%edx
f0100402:	ec                   	in     (%dx),%al
f0100403:	ec                   	in     (%dx),%al
f0100404:	ec                   	in     (%dx),%al
f0100405:	ec                   	in     (%dx),%al
	     i++)
f0100406:	83 c6 01             	add    $0x1,%esi
f0100409:	eb e6                	jmp    f01003f1 <cons_putc+0x1a>
	outb(COM1 + COM_TX, c);
f010040b:	89 cf                	mov    %ecx,%edi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010040d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100412:	89 c8                	mov    %ecx,%eax
f0100414:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100415:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010041a:	bb 84 00 00 00       	mov    $0x84,%ebx
f010041f:	ba 79 03 00 00       	mov    $0x379,%edx
f0100424:	ec                   	in     (%dx),%al
f0100425:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010042b:	7f 0f                	jg     f010043c <cons_putc+0x65>
f010042d:	84 c0                	test   %al,%al
f010042f:	78 0b                	js     f010043c <cons_putc+0x65>
f0100431:	89 da                	mov    %ebx,%edx
f0100433:	ec                   	in     (%dx),%al
f0100434:	ec                   	in     (%dx),%al
f0100435:	ec                   	in     (%dx),%al
f0100436:	ec                   	in     (%dx),%al
f0100437:	83 c6 01             	add    $0x1,%esi
f010043a:	eb e3                	jmp    f010041f <cons_putc+0x48>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010043c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100441:	89 f8                	mov    %edi,%eax
f0100443:	ee                   	out    %al,(%dx)
f0100444:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100449:	b8 0d 00 00 00       	mov    $0xd,%eax
f010044e:	ee                   	out    %al,(%dx)
f010044f:	b8 08 00 00 00       	mov    $0x8,%eax
f0100454:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100455:	f7 c1 00 ff ff ff    	test   $0xffffff00,%ecx
f010045b:	75 0a                	jne    f0100467 <cons_putc+0x90>
		if(ch>47 && ch<58)
f010045d:	8d 47 d0             	lea    -0x30(%edi),%eax
f0100460:	3c 09                	cmp    $0x9,%al
f0100462:	77 5a                	ja     f01004be <cons_putc+0xe7>
			c |= 0x0200;
f0100464:	80 cd 02             	or     $0x2,%ch
	switch (c & 0xff) {
f0100467:	0f b6 c1             	movzbl %cl,%eax
f010046a:	80 f9 0a             	cmp    $0xa,%cl
f010046d:	0f 84 f3 00 00 00    	je     f0100566 <cons_putc+0x18f>
f0100473:	83 f8 0a             	cmp    $0xa,%eax
f0100476:	7f 5c                	jg     f01004d4 <cons_putc+0xfd>
f0100478:	83 f8 08             	cmp    $0x8,%eax
f010047b:	0f 84 bd 00 00 00    	je     f010053e <cons_putc+0x167>
f0100481:	83 f8 09             	cmp    $0x9,%eax
f0100484:	0f 85 e9 00 00 00    	jne    f0100573 <cons_putc+0x19c>
		cons_putc(' ');
f010048a:	b8 20 00 00 00       	mov    $0x20,%eax
f010048f:	e8 43 ff ff ff       	call   f01003d7 <cons_putc>
		cons_putc(' ');
f0100494:	b8 20 00 00 00       	mov    $0x20,%eax
f0100499:	e8 39 ff ff ff       	call   f01003d7 <cons_putc>
		cons_putc(' ');
f010049e:	b8 20 00 00 00       	mov    $0x20,%eax
f01004a3:	e8 2f ff ff ff       	call   f01003d7 <cons_putc>
		cons_putc(' ');
f01004a8:	b8 20 00 00 00       	mov    $0x20,%eax
f01004ad:	e8 25 ff ff ff       	call   f01003d7 <cons_putc>
		cons_putc(' ');
f01004b2:	b8 20 00 00 00       	mov    $0x20,%eax
f01004b7:	e8 1b ff ff ff       	call   f01003d7 <cons_putc>
		break;
f01004bc:	eb 3b                	jmp    f01004f9 <cons_putc+0x122>
		else if((ch>64 && ch<91) || (ch>96 && ch<123))
f01004be:	83 e7 df             	and    $0xffffffdf,%edi
f01004c1:	8d 57 bf             	lea    -0x41(%edi),%edx
			c |= 0x0700;
f01004c4:	89 cb                	mov    %ecx,%ebx
f01004c6:	80 cf 07             	or     $0x7,%bh
f01004c9:	80 cd 04             	or     $0x4,%ch
f01004cc:	80 fa 19             	cmp    $0x19,%dl
f01004cf:	0f 46 cb             	cmovbe %ebx,%ecx
f01004d2:	eb 93                	jmp    f0100467 <cons_putc+0x90>
	switch (c & 0xff) {
f01004d4:	83 f8 0d             	cmp    $0xd,%eax
f01004d7:	0f 85 96 00 00 00    	jne    f0100573 <cons_putc+0x19c>
		crt_pos -= (crt_pos % CRT_COLS);
f01004dd:	0f b7 05 28 92 23 f0 	movzwl 0xf0239228,%eax
f01004e4:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004ea:	c1 e8 16             	shr    $0x16,%eax
f01004ed:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004f0:	c1 e0 04             	shl    $0x4,%eax
f01004f3:	66 a3 28 92 23 f0    	mov    %ax,0xf0239228
	if (crt_pos >= CRT_SIZE) {
f01004f9:	66 81 3d 28 92 23 f0 	cmpw   $0x7cf,0xf0239228
f0100500:	cf 07 
f0100502:	0f 87 8e 00 00 00    	ja     f0100596 <cons_putc+0x1bf>
	outb(addr_6845, 14);
f0100508:	8b 0d 30 92 23 f0    	mov    0xf0239230,%ecx
f010050e:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100513:	89 ca                	mov    %ecx,%edx
f0100515:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100516:	0f b7 1d 28 92 23 f0 	movzwl 0xf0239228,%ebx
f010051d:	8d 71 01             	lea    0x1(%ecx),%esi
f0100520:	89 d8                	mov    %ebx,%eax
f0100522:	66 c1 e8 08          	shr    $0x8,%ax
f0100526:	89 f2                	mov    %esi,%edx
f0100528:	ee                   	out    %al,(%dx)
f0100529:	b8 0f 00 00 00       	mov    $0xf,%eax
f010052e:	89 ca                	mov    %ecx,%edx
f0100530:	ee                   	out    %al,(%dx)
f0100531:	89 d8                	mov    %ebx,%eax
f0100533:	89 f2                	mov    %esi,%edx
f0100535:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100536:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100539:	5b                   	pop    %ebx
f010053a:	5e                   	pop    %esi
f010053b:	5f                   	pop    %edi
f010053c:	5d                   	pop    %ebp
f010053d:	c3                   	ret    
		if (crt_pos > 0) {
f010053e:	0f b7 05 28 92 23 f0 	movzwl 0xf0239228,%eax
f0100545:	66 85 c0             	test   %ax,%ax
f0100548:	74 be                	je     f0100508 <cons_putc+0x131>
			crt_pos--;
f010054a:	83 e8 01             	sub    $0x1,%eax
f010054d:	66 a3 28 92 23 f0    	mov    %ax,0xf0239228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100553:	0f b7 d0             	movzwl %ax,%edx
f0100556:	b1 00                	mov    $0x0,%cl
f0100558:	83 c9 20             	or     $0x20,%ecx
f010055b:	a1 2c 92 23 f0       	mov    0xf023922c,%eax
f0100560:	66 89 0c 50          	mov    %cx,(%eax,%edx,2)
f0100564:	eb 93                	jmp    f01004f9 <cons_putc+0x122>
		crt_pos += CRT_COLS;
f0100566:	66 83 05 28 92 23 f0 	addw   $0x50,0xf0239228
f010056d:	50 
f010056e:	e9 6a ff ff ff       	jmp    f01004dd <cons_putc+0x106>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100573:	0f b7 05 28 92 23 f0 	movzwl 0xf0239228,%eax
f010057a:	8d 50 01             	lea    0x1(%eax),%edx
f010057d:	66 89 15 28 92 23 f0 	mov    %dx,0xf0239228
f0100584:	0f b7 c0             	movzwl %ax,%eax
f0100587:	8b 15 2c 92 23 f0    	mov    0xf023922c,%edx
f010058d:	66 89 0c 42          	mov    %cx,(%edx,%eax,2)
		break;
f0100591:	e9 63 ff ff ff       	jmp    f01004f9 <cons_putc+0x122>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100596:	a1 2c 92 23 f0       	mov    0xf023922c,%eax
f010059b:	83 ec 04             	sub    $0x4,%esp
f010059e:	68 00 0f 00 00       	push   $0xf00
f01005a3:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005a9:	52                   	push   %edx
f01005aa:	50                   	push   %eax
f01005ab:	e8 cc 55 00 00       	call   f0105b7c <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01005b0:	8b 15 2c 92 23 f0    	mov    0xf023922c,%edx
f01005b6:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01005bc:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01005c2:	83 c4 10             	add    $0x10,%esp
f01005c5:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01005ca:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005cd:	39 d0                	cmp    %edx,%eax
f01005cf:	75 f4                	jne    f01005c5 <cons_putc+0x1ee>
		crt_pos -= CRT_COLS;
f01005d1:	66 83 2d 28 92 23 f0 	subw   $0x50,0xf0239228
f01005d8:	50 
f01005d9:	e9 2a ff ff ff       	jmp    f0100508 <cons_putc+0x131>

f01005de <serial_intr>:
{
f01005de:	f3 0f 1e fb          	endbr32 
	if (serial_exists)
f01005e2:	80 3d 34 92 23 f0 00 	cmpb   $0x0,0xf0239234
f01005e9:	75 01                	jne    f01005ec <serial_intr+0xe>
f01005eb:	c3                   	ret    
{
f01005ec:	55                   	push   %ebp
f01005ed:	89 e5                	mov    %esp,%ebp
f01005ef:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01005f2:	b8 61 02 10 f0       	mov    $0xf0100261,%eax
f01005f7:	e8 83 fc ff ff       	call   f010027f <cons_intr>
}
f01005fc:	c9                   	leave  
f01005fd:	c3                   	ret    

f01005fe <kbd_intr>:
{
f01005fe:	f3 0f 1e fb          	endbr32 
f0100602:	55                   	push   %ebp
f0100603:	89 e5                	mov    %esp,%ebp
f0100605:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100608:	b8 be 02 10 f0       	mov    $0xf01002be,%eax
f010060d:	e8 6d fc ff ff       	call   f010027f <cons_intr>
}
f0100612:	c9                   	leave  
f0100613:	c3                   	ret    

f0100614 <cons_getc>:
{
f0100614:	f3 0f 1e fb          	endbr32 
f0100618:	55                   	push   %ebp
f0100619:	89 e5                	mov    %esp,%ebp
f010061b:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f010061e:	e8 bb ff ff ff       	call   f01005de <serial_intr>
	kbd_intr();
f0100623:	e8 d6 ff ff ff       	call   f01005fe <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100628:	a1 20 92 23 f0       	mov    0xf0239220,%eax
	return 0;
f010062d:	ba 00 00 00 00       	mov    $0x0,%edx
	if (cons.rpos != cons.wpos) {
f0100632:	3b 05 24 92 23 f0    	cmp    0xf0239224,%eax
f0100638:	74 1c                	je     f0100656 <cons_getc+0x42>
		c = cons.buf[cons.rpos++];
f010063a:	8d 48 01             	lea    0x1(%eax),%ecx
f010063d:	0f b6 90 20 90 23 f0 	movzbl -0xfdc6fe0(%eax),%edx
			cons.rpos = 0;
f0100644:	3d ff 01 00 00       	cmp    $0x1ff,%eax
f0100649:	b8 00 00 00 00       	mov    $0x0,%eax
f010064e:	0f 45 c1             	cmovne %ecx,%eax
f0100651:	a3 20 92 23 f0       	mov    %eax,0xf0239220
}
f0100656:	89 d0                	mov    %edx,%eax
f0100658:	c9                   	leave  
f0100659:	c3                   	ret    

f010065a <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010065a:	f3 0f 1e fb          	endbr32 
f010065e:	55                   	push   %ebp
f010065f:	89 e5                	mov    %esp,%ebp
f0100661:	57                   	push   %edi
f0100662:	56                   	push   %esi
f0100663:	53                   	push   %ebx
f0100664:	83 ec 0c             	sub    $0xc,%esp
	was = *cp;
f0100667:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010066e:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100675:	5a a5 
	if (*cp != 0xA55A) {
f0100677:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010067e:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100682:	0f 84 d4 00 00 00    	je     f010075c <cons_init+0x102>
		addr_6845 = MONO_BASE;
f0100688:	c7 05 30 92 23 f0 b4 	movl   $0x3b4,0xf0239230
f010068f:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100692:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
	outb(addr_6845, 14);
f0100697:	8b 3d 30 92 23 f0    	mov    0xf0239230,%edi
f010069d:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006a2:	89 fa                	mov    %edi,%edx
f01006a4:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006a5:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006a8:	89 ca                	mov    %ecx,%edx
f01006aa:	ec                   	in     (%dx),%al
f01006ab:	0f b6 c0             	movzbl %al,%eax
f01006ae:	c1 e0 08             	shl    $0x8,%eax
f01006b1:	89 c3                	mov    %eax,%ebx
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006b3:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006b8:	89 fa                	mov    %edi,%edx
f01006ba:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006bb:	89 ca                	mov    %ecx,%edx
f01006bd:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f01006be:	89 35 2c 92 23 f0    	mov    %esi,0xf023922c
	pos |= inb(addr_6845 + 1);
f01006c4:	0f b6 c0             	movzbl %al,%eax
f01006c7:	09 d8                	or     %ebx,%eax
	crt_pos = pos;
f01006c9:	66 a3 28 92 23 f0    	mov    %ax,0xf0239228
	kbd_intr();
f01006cf:	e8 2a ff ff ff       	call   f01005fe <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006d4:	83 ec 0c             	sub    $0xc,%esp
f01006d7:	0f b7 05 a8 33 12 f0 	movzwl 0xf01233a8,%eax
f01006de:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006e3:	50                   	push   %eax
f01006e4:	e8 7e 31 00 00       	call   f0103867 <irq_setmask_8259A>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006e9:	bb 00 00 00 00       	mov    $0x0,%ebx
f01006ee:	b9 fa 03 00 00       	mov    $0x3fa,%ecx
f01006f3:	89 d8                	mov    %ebx,%eax
f01006f5:	89 ca                	mov    %ecx,%edx
f01006f7:	ee                   	out    %al,(%dx)
f01006f8:	bf fb 03 00 00       	mov    $0x3fb,%edi
f01006fd:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100702:	89 fa                	mov    %edi,%edx
f0100704:	ee                   	out    %al,(%dx)
f0100705:	b8 0c 00 00 00       	mov    $0xc,%eax
f010070a:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010070f:	ee                   	out    %al,(%dx)
f0100710:	be f9 03 00 00       	mov    $0x3f9,%esi
f0100715:	89 d8                	mov    %ebx,%eax
f0100717:	89 f2                	mov    %esi,%edx
f0100719:	ee                   	out    %al,(%dx)
f010071a:	b8 03 00 00 00       	mov    $0x3,%eax
f010071f:	89 fa                	mov    %edi,%edx
f0100721:	ee                   	out    %al,(%dx)
f0100722:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100727:	89 d8                	mov    %ebx,%eax
f0100729:	ee                   	out    %al,(%dx)
f010072a:	b8 01 00 00 00       	mov    $0x1,%eax
f010072f:	89 f2                	mov    %esi,%edx
f0100731:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100732:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100737:	ec                   	in     (%dx),%al
f0100738:	89 c3                	mov    %eax,%ebx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010073a:	83 c4 10             	add    $0x10,%esp
f010073d:	3c ff                	cmp    $0xff,%al
f010073f:	0f 95 05 34 92 23 f0 	setne  0xf0239234
f0100746:	89 ca                	mov    %ecx,%edx
f0100748:	ec                   	in     (%dx),%al
f0100749:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010074e:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010074f:	80 fb ff             	cmp    $0xff,%bl
f0100752:	74 23                	je     f0100777 <cons_init+0x11d>
		cprintf("Serial port does not exist!\n");
}
f0100754:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100757:	5b                   	pop    %ebx
f0100758:	5e                   	pop    %esi
f0100759:	5f                   	pop    %edi
f010075a:	5d                   	pop    %ebp
f010075b:	c3                   	ret    
		*cp = was;
f010075c:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100763:	c7 05 30 92 23 f0 d4 	movl   $0x3d4,0xf0239230
f010076a:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010076d:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f0100772:	e9 20 ff ff ff       	jmp    f0100697 <cons_init+0x3d>
		cprintf("Serial port does not exist!\n");
f0100777:	83 ec 0c             	sub    $0xc,%esp
f010077a:	68 8f 68 10 f0       	push   $0xf010688f
f010077f:	e8 50 32 00 00       	call   f01039d4 <cprintf>
f0100784:	83 c4 10             	add    $0x10,%esp
}
f0100787:	eb cb                	jmp    f0100754 <cons_init+0xfa>

f0100789 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100789:	f3 0f 1e fb          	endbr32 
f010078d:	55                   	push   %ebp
f010078e:	89 e5                	mov    %esp,%ebp
f0100790:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100793:	8b 45 08             	mov    0x8(%ebp),%eax
f0100796:	e8 3c fc ff ff       	call   f01003d7 <cons_putc>
}
f010079b:	c9                   	leave  
f010079c:	c3                   	ret    

f010079d <getchar>:

int
getchar(void)
{
f010079d:	f3 0f 1e fb          	endbr32 
f01007a1:	55                   	push   %ebp
f01007a2:	89 e5                	mov    %esp,%ebp
f01007a4:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01007a7:	e8 68 fe ff ff       	call   f0100614 <cons_getc>
f01007ac:	85 c0                	test   %eax,%eax
f01007ae:	74 f7                	je     f01007a7 <getchar+0xa>
		/* do nothing */;
	return c;
}
f01007b0:	c9                   	leave  
f01007b1:	c3                   	ret    

f01007b2 <iscons>:

int
iscons(int fdnum)
{
f01007b2:	f3 0f 1e fb          	endbr32 
	// used by readline
	return 1;
}
f01007b6:	b8 01 00 00 00       	mov    $0x1,%eax
f01007bb:	c3                   	ret    

f01007bc <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007bc:	f3 0f 1e fb          	endbr32 
f01007c0:	55                   	push   %ebp
f01007c1:	89 e5                	mov    %esp,%ebp
f01007c3:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007c6:	68 e0 6a 10 f0       	push   $0xf0106ae0
f01007cb:	68 fe 6a 10 f0       	push   $0xf0106afe
f01007d0:	68 03 6b 10 f0       	push   $0xf0106b03
f01007d5:	e8 fa 31 00 00       	call   f01039d4 <cprintf>
f01007da:	83 c4 0c             	add    $0xc,%esp
f01007dd:	68 d0 6b 10 f0       	push   $0xf0106bd0
f01007e2:	68 0c 6b 10 f0       	push   $0xf0106b0c
f01007e7:	68 03 6b 10 f0       	push   $0xf0106b03
f01007ec:	e8 e3 31 00 00       	call   f01039d4 <cprintf>
f01007f1:	83 c4 0c             	add    $0xc,%esp
f01007f4:	68 15 6b 10 f0       	push   $0xf0106b15
f01007f9:	68 2b 6b 10 f0       	push   $0xf0106b2b
f01007fe:	68 03 6b 10 f0       	push   $0xf0106b03
f0100803:	e8 cc 31 00 00       	call   f01039d4 <cprintf>
	return 0;
}
f0100808:	b8 00 00 00 00       	mov    $0x0,%eax
f010080d:	c9                   	leave  
f010080e:	c3                   	ret    

f010080f <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010080f:	f3 0f 1e fb          	endbr32 
f0100813:	55                   	push   %ebp
f0100814:	89 e5                	mov    %esp,%ebp
f0100816:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100819:	68 35 6b 10 f0       	push   $0xf0106b35
f010081e:	e8 b1 31 00 00       	call   f01039d4 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100823:	83 c4 08             	add    $0x8,%esp
f0100826:	68 0c 00 10 00       	push   $0x10000c
f010082b:	68 f8 6b 10 f0       	push   $0xf0106bf8
f0100830:	e8 9f 31 00 00       	call   f01039d4 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100835:	83 c4 0c             	add    $0xc,%esp
f0100838:	68 0c 00 10 00       	push   $0x10000c
f010083d:	68 0c 00 10 f0       	push   $0xf010000c
f0100842:	68 20 6c 10 f0       	push   $0xf0106c20
f0100847:	e8 88 31 00 00       	call   f01039d4 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010084c:	83 c4 0c             	add    $0xc,%esp
f010084f:	68 bd 67 10 00       	push   $0x1067bd
f0100854:	68 bd 67 10 f0       	push   $0xf01067bd
f0100859:	68 44 6c 10 f0       	push   $0xf0106c44
f010085e:	e8 71 31 00 00       	call   f01039d4 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100863:	83 c4 0c             	add    $0xc,%esp
f0100866:	68 00 90 23 00       	push   $0x239000
f010086b:	68 00 90 23 f0       	push   $0xf0239000
f0100870:	68 68 6c 10 f0       	push   $0xf0106c68
f0100875:	e8 5a 31 00 00       	call   f01039d4 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010087a:	83 c4 0c             	add    $0xc,%esp
f010087d:	68 09 b0 27 00       	push   $0x27b009
f0100882:	68 09 b0 27 f0       	push   $0xf027b009
f0100887:	68 8c 6c 10 f0       	push   $0xf0106c8c
f010088c:	e8 43 31 00 00       	call   f01039d4 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100891:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100894:	b8 09 b0 27 f0       	mov    $0xf027b009,%eax
f0100899:	2d 0d fc 0f f0       	sub    $0xf00ffc0d,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f010089e:	c1 f8 0a             	sar    $0xa,%eax
f01008a1:	50                   	push   %eax
f01008a2:	68 b0 6c 10 f0       	push   $0xf0106cb0
f01008a7:	e8 28 31 00 00       	call   f01039d4 <cprintf>
	return 0;
}
f01008ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01008b1:	c9                   	leave  
f01008b2:	c3                   	ret    

f01008b3 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008b3:	f3 0f 1e fb          	endbr32 
f01008b7:	55                   	push   %ebp
f01008b8:	89 e5                	mov    %esp,%ebp
f01008ba:	57                   	push   %edi
f01008bb:	56                   	push   %esi
f01008bc:	53                   	push   %ebx
f01008bd:	83 ec 48             	sub    $0x48,%esp
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008c0:	89 e8                	mov    %ebp,%eax
f01008c2:	89 c3                	mov    %eax,%ebx
	// Your code here.
	// typedef int (*this_func_type)(int, char **, struct Trapframe *);
	uint32_t ebp = read_ebp();
	uint32_t *ebp_base_ptr = (uint32_t*)ebp;           
f01008c4:	89 c6                	mov    %eax,%esi
	uint32_t eip = ebp_base_ptr[1];
f01008c6:	8b 40 04             	mov    0x4(%eax),%eax
f01008c9:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	cprintf("Stack backtrace:\n");
f01008cc:	68 4e 6b 10 f0       	push   $0xf0106b4e
f01008d1:	e8 fe 30 00 00       	call   f01039d4 <cprintf>
	while (ebp != 0) {
f01008d6:	83 c4 10             	add    $0x10,%esp
f01008d9:	eb 0a                	jmp    f01008e5 <mon_backtrace+0x32>
		{
			uint32_t offset = eip-info.eip_fn_addr;
			cprintf("\t\t%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,offset);
		}
        // update the values
        ebp = (uint32_t)*ebp_base_ptr;
f01008db:	8b 36                	mov    (%esi),%esi
		ebp_base_ptr = (uint32_t*)ebp;
f01008dd:	89 f3                	mov    %esi,%ebx
        eip = ebp_base_ptr[1];
f01008df:	8b 46 04             	mov    0x4(%esi),%eax
f01008e2:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	while (ebp != 0) {
f01008e5:	85 db                	test   %ebx,%ebx
f01008e7:	74 7e                	je     f0100967 <mon_backtrace+0xb4>
        cprintf("\tebp %08x, eip %09x, args ", ebp, eip);
f01008e9:	83 ec 04             	sub    $0x4,%esp
f01008ec:	ff 75 c4             	pushl  -0x3c(%ebp)
f01008ef:	53                   	push   %ebx
f01008f0:	68 60 6b 10 f0       	push   $0xf0106b60
f01008f5:	e8 da 30 00 00       	call   f01039d4 <cprintf>
f01008fa:	8d 5e 08             	lea    0x8(%esi),%ebx
f01008fd:	8d 7e 1c             	lea    0x1c(%esi),%edi
f0100900:	83 c4 10             	add    $0x10,%esp
            cprintf("%08x ", args[i]);
f0100903:	83 ec 08             	sub    $0x8,%esp
f0100906:	ff 33                	pushl  (%ebx)
f0100908:	68 7b 6b 10 f0       	push   $0xf0106b7b
f010090d:	e8 c2 30 00 00       	call   f01039d4 <cprintf>
f0100912:	83 c3 04             	add    $0x4,%ebx
        for (int i = 0; i < 5; ++i) {
f0100915:	83 c4 10             	add    $0x10,%esp
f0100918:	39 fb                	cmp    %edi,%ebx
f010091a:	75 e7                	jne    f0100903 <mon_backtrace+0x50>
        cprintf("\n");
f010091c:	83 ec 0c             	sub    $0xc,%esp
f010091f:	68 fd 79 10 f0       	push   $0xf01079fd
f0100924:	e8 ab 30 00 00       	call   f01039d4 <cprintf>
        if(debuginfo_eip(eip,&info) == 0)
f0100929:	83 c4 08             	add    $0x8,%esp
f010092c:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010092f:	50                   	push   %eax
f0100930:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100933:	e8 bf 46 00 00       	call   f0104ff7 <debuginfo_eip>
f0100938:	83 c4 10             	add    $0x10,%esp
f010093b:	85 c0                	test   %eax,%eax
f010093d:	75 9c                	jne    f01008db <mon_backtrace+0x28>
			cprintf("\t\t%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,offset);
f010093f:	83 ec 08             	sub    $0x8,%esp
			uint32_t offset = eip-info.eip_fn_addr;
f0100942:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100945:	2b 45 e0             	sub    -0x20(%ebp),%eax
			cprintf("\t\t%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,offset);
f0100948:	50                   	push   %eax
f0100949:	ff 75 d8             	pushl  -0x28(%ebp)
f010094c:	ff 75 dc             	pushl  -0x24(%ebp)
f010094f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100952:	ff 75 d0             	pushl  -0x30(%ebp)
f0100955:	68 81 6b 10 f0       	push   $0xf0106b81
f010095a:	e8 75 30 00 00       	call   f01039d4 <cprintf>
f010095f:	83 c4 20             	add    $0x20,%esp
f0100962:	e9 74 ff ff ff       	jmp    f01008db <mon_backtrace+0x28>
	}

	return 0;
}
f0100967:	b8 00 00 00 00       	mov    $0x0,%eax
f010096c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010096f:	5b                   	pop    %ebx
f0100970:	5e                   	pop    %esi
f0100971:	5f                   	pop    %edi
f0100972:	5d                   	pop    %ebp
f0100973:	c3                   	ret    

f0100974 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100974:	f3 0f 1e fb          	endbr32 
f0100978:	55                   	push   %ebp
f0100979:	89 e5                	mov    %esp,%ebp
f010097b:	57                   	push   %edi
f010097c:	56                   	push   %esi
f010097d:	53                   	push   %ebx
f010097e:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100981:	68 dc 6c 10 f0       	push   $0xf0106cdc
f0100986:	e8 49 30 00 00       	call   f01039d4 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010098b:	c7 04 24 00 6d 10 f0 	movl   $0xf0106d00,(%esp)
f0100992:	e8 3d 30 00 00       	call   f01039d4 <cprintf>

	if (tf != NULL)
f0100997:	83 c4 10             	add    $0x10,%esp
f010099a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010099e:	0f 84 d9 00 00 00    	je     f0100a7d <monitor+0x109>
		print_trapframe(tf);
f01009a4:	83 ec 0c             	sub    $0xc,%esp
f01009a7:	ff 75 08             	pushl  0x8(%ebp)
f01009aa:	e8 ce 37 00 00       	call   f010417d <print_trapframe>
f01009af:	83 c4 10             	add    $0x10,%esp
f01009b2:	e9 c6 00 00 00       	jmp    f0100a7d <monitor+0x109>
		while (*buf && strchr(WHITESPACE, *buf))
f01009b7:	83 ec 08             	sub    $0x8,%esp
f01009ba:	0f be c0             	movsbl %al,%eax
f01009bd:	50                   	push   %eax
f01009be:	68 97 6b 10 f0       	push   $0xf0106b97
f01009c3:	e8 23 51 00 00       	call   f0105aeb <strchr>
f01009c8:	83 c4 10             	add    $0x10,%esp
f01009cb:	85 c0                	test   %eax,%eax
f01009cd:	74 63                	je     f0100a32 <monitor+0xbe>
			*buf++ = 0;
f01009cf:	c6 03 00             	movb   $0x0,(%ebx)
f01009d2:	89 f7                	mov    %esi,%edi
f01009d4:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01009d7:	89 fe                	mov    %edi,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f01009d9:	0f b6 03             	movzbl (%ebx),%eax
f01009dc:	84 c0                	test   %al,%al
f01009de:	75 d7                	jne    f01009b7 <monitor+0x43>
	argv[argc] = 0;
f01009e0:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009e7:	00 
	if (argc == 0)
f01009e8:	85 f6                	test   %esi,%esi
f01009ea:	0f 84 8d 00 00 00    	je     f0100a7d <monitor+0x109>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009f0:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (strcmp(argv[0], commands[i].name) == 0)
f01009f5:	83 ec 08             	sub    $0x8,%esp
f01009f8:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009fb:	ff 34 85 40 6d 10 f0 	pushl  -0xfef92c0(,%eax,4)
f0100a02:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a05:	e8 7b 50 00 00       	call   f0105a85 <strcmp>
f0100a0a:	83 c4 10             	add    $0x10,%esp
f0100a0d:	85 c0                	test   %eax,%eax
f0100a0f:	0f 84 8f 00 00 00    	je     f0100aa4 <monitor+0x130>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a15:	83 c3 01             	add    $0x1,%ebx
f0100a18:	83 fb 03             	cmp    $0x3,%ebx
f0100a1b:	75 d8                	jne    f01009f5 <monitor+0x81>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a1d:	83 ec 08             	sub    $0x8,%esp
f0100a20:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a23:	68 b9 6b 10 f0       	push   $0xf0106bb9
f0100a28:	e8 a7 2f 00 00       	call   f01039d4 <cprintf>
	return 0;
f0100a2d:	83 c4 10             	add    $0x10,%esp
f0100a30:	eb 4b                	jmp    f0100a7d <monitor+0x109>
		if (*buf == 0)
f0100a32:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100a35:	74 a9                	je     f01009e0 <monitor+0x6c>
		if (argc == MAXARGS-1) {
f0100a37:	83 fe 0f             	cmp    $0xf,%esi
f0100a3a:	74 2f                	je     f0100a6b <monitor+0xf7>
		argv[argc++] = buf;
f0100a3c:	8d 7e 01             	lea    0x1(%esi),%edi
f0100a3f:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a43:	0f b6 03             	movzbl (%ebx),%eax
f0100a46:	84 c0                	test   %al,%al
f0100a48:	74 8d                	je     f01009d7 <monitor+0x63>
f0100a4a:	83 ec 08             	sub    $0x8,%esp
f0100a4d:	0f be c0             	movsbl %al,%eax
f0100a50:	50                   	push   %eax
f0100a51:	68 97 6b 10 f0       	push   $0xf0106b97
f0100a56:	e8 90 50 00 00       	call   f0105aeb <strchr>
f0100a5b:	83 c4 10             	add    $0x10,%esp
f0100a5e:	85 c0                	test   %eax,%eax
f0100a60:	0f 85 71 ff ff ff    	jne    f01009d7 <monitor+0x63>
			buf++;
f0100a66:	83 c3 01             	add    $0x1,%ebx
f0100a69:	eb d8                	jmp    f0100a43 <monitor+0xcf>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a6b:	83 ec 08             	sub    $0x8,%esp
f0100a6e:	6a 10                	push   $0x10
f0100a70:	68 9c 6b 10 f0       	push   $0xf0106b9c
f0100a75:	e8 5a 2f 00 00       	call   f01039d4 <cprintf>
			return 0;
f0100a7a:	83 c4 10             	add    $0x10,%esp
	// cprintf("x %d, y %x, z %d\n", x, y, z);
	// unsigned int i = 0x00646c72;
 	// cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100a7d:	83 ec 0c             	sub    $0xc,%esp
f0100a80:	68 93 6b 10 f0       	push   $0xf0106b93
f0100a85:	e8 13 4e 00 00       	call   f010589d <readline>
f0100a8a:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100a8c:	83 c4 10             	add    $0x10,%esp
f0100a8f:	85 c0                	test   %eax,%eax
f0100a91:	74 ea                	je     f0100a7d <monitor+0x109>
	argv[argc] = 0;
f0100a93:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100a9a:	be 00 00 00 00       	mov    $0x0,%esi
f0100a9f:	e9 35 ff ff ff       	jmp    f01009d9 <monitor+0x65>
			return commands[i].func(argc, argv, tf);
f0100aa4:	83 ec 04             	sub    $0x4,%esp
f0100aa7:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100aaa:	ff 75 08             	pushl  0x8(%ebp)
f0100aad:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100ab0:	52                   	push   %edx
f0100ab1:	56                   	push   %esi
f0100ab2:	ff 14 85 48 6d 10 f0 	call   *-0xfef92b8(,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100ab9:	83 c4 10             	add    $0x10,%esp
f0100abc:	85 c0                	test   %eax,%eax
f0100abe:	79 bd                	jns    f0100a7d <monitor+0x109>
				break;
	}
}
f0100ac0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ac3:	5b                   	pop    %ebx
f0100ac4:	5e                   	pop    %esi
f0100ac5:	5f                   	pop    %edi
f0100ac6:	5d                   	pop    %ebp
f0100ac7:	c3                   	ret    

f0100ac8 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100ac8:	55                   	push   %ebp
f0100ac9:	89 e5                	mov    %esp,%ebp
f0100acb:	56                   	push   %esi
f0100acc:	53                   	push   %ebx
f0100acd:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100acf:	83 ec 0c             	sub    $0xc,%esp
f0100ad2:	50                   	push   %eax
f0100ad3:	e8 59 2d 00 00       	call   f0103831 <mc146818_read>
f0100ad8:	89 c6                	mov    %eax,%esi
f0100ada:	83 c3 01             	add    $0x1,%ebx
f0100add:	89 1c 24             	mov    %ebx,(%esp)
f0100ae0:	e8 4c 2d 00 00       	call   f0103831 <mc146818_read>
f0100ae5:	c1 e0 08             	shl    $0x8,%eax
f0100ae8:	09 f0                	or     %esi,%eax
}
f0100aea:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100aed:	5b                   	pop    %ebx
f0100aee:	5e                   	pop    %esi
f0100aef:	5d                   	pop    %ebp
f0100af0:	c3                   	ret    

f0100af1 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100af1:	83 3d 38 92 23 f0 00 	cmpl   $0x0,0xf0239238
f0100af8:	74 36                	je     f0100b30 <boot_alloc+0x3f>
	// LAB 2: Your code here.

	// special case
	if(n == 0)
	{
		return nextfree;
f0100afa:	8b 15 38 92 23 f0    	mov    0xf0239238,%edx
	if(n == 0)
f0100b00:	85 c0                	test   %eax,%eax
f0100b02:	74 29                	je     f0100b2d <boot_alloc+0x3c>
	}

	// allocate memory 
	result = nextfree;
f0100b04:	8b 15 38 92 23 f0    	mov    0xf0239238,%edx
	nextfree = ROUNDUP(n,PGSIZE)+nextfree;
f0100b0a:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100b0f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b14:	01 d0                	add    %edx,%eax
f0100b16:	a3 38 92 23 f0       	mov    %eax,0xf0239238

	// out of memory panic
	if((uint32_t)nextfree-KERNBASE>(npages*PGSIZE))
f0100b1b:	05 00 00 00 10       	add    $0x10000000,%eax
f0100b20:	8b 0d 88 9e 23 f0    	mov    0xf0239e88,%ecx
f0100b26:	c1 e1 0c             	shl    $0xc,%ecx
f0100b29:	39 c8                	cmp    %ecx,%eax
f0100b2b:	77 16                	ja     f0100b43 <boot_alloc+0x52>
		nextfree = result;
		return NULL;
	}
	return result;

}
f0100b2d:	89 d0                	mov    %edx,%eax
f0100b2f:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b30:	ba 08 c0 27 f0       	mov    $0xf027c008,%edx
f0100b35:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b3b:	89 15 38 92 23 f0    	mov    %edx,0xf0239238
f0100b41:	eb b7                	jmp    f0100afa <boot_alloc+0x9>
{
f0100b43:	55                   	push   %ebp
f0100b44:	89 e5                	mov    %esp,%ebp
f0100b46:	83 ec 0c             	sub    $0xc,%esp
		panic("at pmap.c:boot_alloc(): out of memory");
f0100b49:	68 64 6d 10 f0       	push   $0xf0106d64
f0100b4e:	6a 7a                	push   $0x7a
f0100b50:	68 1d 77 10 f0       	push   $0xf010771d
f0100b55:	e8 e6 f4 ff ff       	call   f0100040 <_panic>

f0100b5a <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b5a:	89 d1                	mov    %edx,%ecx
f0100b5c:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100b5f:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100b62:	a8 01                	test   $0x1,%al
f0100b64:	74 51                	je     f0100bb7 <check_va2pa+0x5d>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b66:	89 c1                	mov    %eax,%ecx
f0100b68:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	if (PGNUM(pa) >= npages)
f0100b6e:	c1 e8 0c             	shr    $0xc,%eax
f0100b71:	3b 05 88 9e 23 f0    	cmp    0xf0239e88,%eax
f0100b77:	73 23                	jae    f0100b9c <check_va2pa+0x42>
	if (!(p[PTX(va)] & PTE_P))
f0100b79:	c1 ea 0c             	shr    $0xc,%edx
f0100b7c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b82:	8b 94 91 00 00 00 f0 	mov    -0x10000000(%ecx,%edx,4),%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b89:	89 d0                	mov    %edx,%eax
f0100b8b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b90:	f6 c2 01             	test   $0x1,%dl
f0100b93:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b98:	0f 44 c2             	cmove  %edx,%eax
f0100b9b:	c3                   	ret    
{
f0100b9c:	55                   	push   %ebp
f0100b9d:	89 e5                	mov    %esp,%ebp
f0100b9f:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ba2:	51                   	push   %ecx
f0100ba3:	68 e4 67 10 f0       	push   $0xf01067e4
f0100ba8:	68 03 04 00 00       	push   $0x403
f0100bad:	68 1d 77 10 f0       	push   $0xf010771d
f0100bb2:	e8 89 f4 ff ff       	call   f0100040 <_panic>
		return ~0;
f0100bb7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0100bbc:	c3                   	ret    

f0100bbd <check_page_free_list>:
{
f0100bbd:	55                   	push   %ebp
f0100bbe:	89 e5                	mov    %esp,%ebp
f0100bc0:	57                   	push   %edi
f0100bc1:	56                   	push   %esi
f0100bc2:	53                   	push   %ebx
f0100bc3:	83 ec 2c             	sub    $0x2c,%esp
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bc6:	84 c0                	test   %al,%al
f0100bc8:	0f 85 77 02 00 00    	jne    f0100e45 <check_page_free_list+0x288>
	if (!page_free_list)
f0100bce:	83 3d 40 92 23 f0 00 	cmpl   $0x0,0xf0239240
f0100bd5:	74 0a                	je     f0100be1 <check_page_free_list+0x24>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bd7:	be 00 04 00 00       	mov    $0x400,%esi
f0100bdc:	e9 bf 02 00 00       	jmp    f0100ea0 <check_page_free_list+0x2e3>
		panic("'page_free_list' is a null pointer!");
f0100be1:	83 ec 04             	sub    $0x4,%esp
f0100be4:	68 8c 6d 10 f0       	push   $0xf0106d8c
f0100be9:	68 36 03 00 00       	push   $0x336
f0100bee:	68 1d 77 10 f0       	push   $0xf010771d
f0100bf3:	e8 48 f4 ff ff       	call   f0100040 <_panic>
f0100bf8:	50                   	push   %eax
f0100bf9:	68 e4 67 10 f0       	push   $0xf01067e4
f0100bfe:	6a 58                	push   $0x58
f0100c00:	68 29 77 10 f0       	push   $0xf0107729
f0100c05:	e8 36 f4 ff ff       	call   f0100040 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c0a:	8b 1b                	mov    (%ebx),%ebx
f0100c0c:	85 db                	test   %ebx,%ebx
f0100c0e:	74 41                	je     f0100c51 <check_page_free_list+0x94>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c10:	89 d8                	mov    %ebx,%eax
f0100c12:	2b 05 90 9e 23 f0    	sub    0xf0239e90,%eax
f0100c18:	c1 f8 03             	sar    $0x3,%eax
f0100c1b:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c1e:	89 c2                	mov    %eax,%edx
f0100c20:	c1 ea 16             	shr    $0x16,%edx
f0100c23:	39 f2                	cmp    %esi,%edx
f0100c25:	73 e3                	jae    f0100c0a <check_page_free_list+0x4d>
	if (PGNUM(pa) >= npages)
f0100c27:	89 c2                	mov    %eax,%edx
f0100c29:	c1 ea 0c             	shr    $0xc,%edx
f0100c2c:	3b 15 88 9e 23 f0    	cmp    0xf0239e88,%edx
f0100c32:	73 c4                	jae    f0100bf8 <check_page_free_list+0x3b>
			memset(page2kva(pp), 0x97, 128);
f0100c34:	83 ec 04             	sub    $0x4,%esp
f0100c37:	68 80 00 00 00       	push   $0x80
f0100c3c:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100c41:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c46:	50                   	push   %eax
f0100c47:	e8 e4 4e 00 00       	call   f0105b30 <memset>
f0100c4c:	83 c4 10             	add    $0x10,%esp
f0100c4f:	eb b9                	jmp    f0100c0a <check_page_free_list+0x4d>
	first_free_page = (char *) boot_alloc(0);
f0100c51:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c56:	e8 96 fe ff ff       	call   f0100af1 <boot_alloc>
f0100c5b:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c5e:	8b 15 40 92 23 f0    	mov    0xf0239240,%edx
		assert(pp >= pages);
f0100c64:	8b 0d 90 9e 23 f0    	mov    0xf0239e90,%ecx
		assert(pp < pages + npages);
f0100c6a:	a1 88 9e 23 f0       	mov    0xf0239e88,%eax
f0100c6f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100c72:	8d 34 c1             	lea    (%ecx,%eax,8),%esi
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c75:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c7a:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c7d:	e9 f9 00 00 00       	jmp    f0100d7b <check_page_free_list+0x1be>
		assert(pp >= pages);
f0100c82:	68 37 77 10 f0       	push   $0xf0107737
f0100c87:	68 43 77 10 f0       	push   $0xf0107743
f0100c8c:	68 50 03 00 00       	push   $0x350
f0100c91:	68 1d 77 10 f0       	push   $0xf010771d
f0100c96:	e8 a5 f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100c9b:	68 58 77 10 f0       	push   $0xf0107758
f0100ca0:	68 43 77 10 f0       	push   $0xf0107743
f0100ca5:	68 51 03 00 00       	push   $0x351
f0100caa:	68 1d 77 10 f0       	push   $0xf010771d
f0100caf:	e8 8c f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cb4:	68 b0 6d 10 f0       	push   $0xf0106db0
f0100cb9:	68 43 77 10 f0       	push   $0xf0107743
f0100cbe:	68 52 03 00 00       	push   $0x352
f0100cc3:	68 1d 77 10 f0       	push   $0xf010771d
f0100cc8:	e8 73 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != 0);
f0100ccd:	68 6c 77 10 f0       	push   $0xf010776c
f0100cd2:	68 43 77 10 f0       	push   $0xf0107743
f0100cd7:	68 55 03 00 00       	push   $0x355
f0100cdc:	68 1d 77 10 f0       	push   $0xf010771d
f0100ce1:	e8 5a f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ce6:	68 7d 77 10 f0       	push   $0xf010777d
f0100ceb:	68 43 77 10 f0       	push   $0xf0107743
f0100cf0:	68 56 03 00 00       	push   $0x356
f0100cf5:	68 1d 77 10 f0       	push   $0xf010771d
f0100cfa:	e8 41 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cff:	68 e4 6d 10 f0       	push   $0xf0106de4
f0100d04:	68 43 77 10 f0       	push   $0xf0107743
f0100d09:	68 57 03 00 00       	push   $0x357
f0100d0e:	68 1d 77 10 f0       	push   $0xf010771d
f0100d13:	e8 28 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d18:	68 96 77 10 f0       	push   $0xf0107796
f0100d1d:	68 43 77 10 f0       	push   $0xf0107743
f0100d22:	68 58 03 00 00       	push   $0x358
f0100d27:	68 1d 77 10 f0       	push   $0xf010771d
f0100d2c:	e8 0f f3 ff ff       	call   f0100040 <_panic>
	if (PGNUM(pa) >= npages)
f0100d31:	89 c3                	mov    %eax,%ebx
f0100d33:	c1 eb 0c             	shr    $0xc,%ebx
f0100d36:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0100d39:	76 0f                	jbe    f0100d4a <check_page_free_list+0x18d>
	return (void *)(pa + KERNBASE);
f0100d3b:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d40:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100d43:	77 17                	ja     f0100d5c <check_page_free_list+0x19f>
			++nfree_extmem;
f0100d45:	83 c7 01             	add    $0x1,%edi
f0100d48:	eb 2f                	jmp    f0100d79 <check_page_free_list+0x1bc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d4a:	50                   	push   %eax
f0100d4b:	68 e4 67 10 f0       	push   $0xf01067e4
f0100d50:	6a 58                	push   $0x58
f0100d52:	68 29 77 10 f0       	push   $0xf0107729
f0100d57:	e8 e4 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d5c:	68 08 6e 10 f0       	push   $0xf0106e08
f0100d61:	68 43 77 10 f0       	push   $0xf0107743
f0100d66:	68 59 03 00 00       	push   $0x359
f0100d6b:	68 1d 77 10 f0       	push   $0xf010771d
f0100d70:	e8 cb f2 ff ff       	call   f0100040 <_panic>
			++nfree_basemem;
f0100d75:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d79:	8b 12                	mov    (%edx),%edx
f0100d7b:	85 d2                	test   %edx,%edx
f0100d7d:	74 74                	je     f0100df3 <check_page_free_list+0x236>
		assert(pp >= pages);
f0100d7f:	39 d1                	cmp    %edx,%ecx
f0100d81:	0f 87 fb fe ff ff    	ja     f0100c82 <check_page_free_list+0xc5>
		assert(pp < pages + npages);
f0100d87:	39 d6                	cmp    %edx,%esi
f0100d89:	0f 86 0c ff ff ff    	jbe    f0100c9b <check_page_free_list+0xde>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d8f:	89 d0                	mov    %edx,%eax
f0100d91:	29 c8                	sub    %ecx,%eax
f0100d93:	a8 07                	test   $0x7,%al
f0100d95:	0f 85 19 ff ff ff    	jne    f0100cb4 <check_page_free_list+0xf7>
	return (pp - pages) << PGSHIFT;
f0100d9b:	c1 f8 03             	sar    $0x3,%eax
		assert(page2pa(pp) != 0);
f0100d9e:	c1 e0 0c             	shl    $0xc,%eax
f0100da1:	0f 84 26 ff ff ff    	je     f0100ccd <check_page_free_list+0x110>
		assert(page2pa(pp) != IOPHYSMEM);
f0100da7:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100dac:	0f 84 34 ff ff ff    	je     f0100ce6 <check_page_free_list+0x129>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100db2:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100db7:	0f 84 42 ff ff ff    	je     f0100cff <check_page_free_list+0x142>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100dbd:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100dc2:	0f 84 50 ff ff ff    	je     f0100d18 <check_page_free_list+0x15b>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100dc8:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100dcd:	0f 87 5e ff ff ff    	ja     f0100d31 <check_page_free_list+0x174>
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100dd3:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100dd8:	75 9b                	jne    f0100d75 <check_page_free_list+0x1b8>
f0100dda:	68 b0 77 10 f0       	push   $0xf01077b0
f0100ddf:	68 43 77 10 f0       	push   $0xf0107743
f0100de4:	68 5b 03 00 00       	push   $0x35b
f0100de9:	68 1d 77 10 f0       	push   $0xf010771d
f0100dee:	e8 4d f2 ff ff       	call   f0100040 <_panic>
f0100df3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
	assert(nfree_basemem > 0);
f0100df6:	85 db                	test   %ebx,%ebx
f0100df8:	7e 19                	jle    f0100e13 <check_page_free_list+0x256>
	assert(nfree_extmem > 0);
f0100dfa:	85 ff                	test   %edi,%edi
f0100dfc:	7e 2e                	jle    f0100e2c <check_page_free_list+0x26f>
	cprintf("check_page_free_list() succeeded!\n");
f0100dfe:	83 ec 0c             	sub    $0xc,%esp
f0100e01:	68 50 6e 10 f0       	push   $0xf0106e50
f0100e06:	e8 c9 2b 00 00       	call   f01039d4 <cprintf>
}
f0100e0b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e0e:	5b                   	pop    %ebx
f0100e0f:	5e                   	pop    %esi
f0100e10:	5f                   	pop    %edi
f0100e11:	5d                   	pop    %ebp
f0100e12:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e13:	68 cd 77 10 f0       	push   $0xf01077cd
f0100e18:	68 43 77 10 f0       	push   $0xf0107743
f0100e1d:	68 63 03 00 00       	push   $0x363
f0100e22:	68 1d 77 10 f0       	push   $0xf010771d
f0100e27:	e8 14 f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100e2c:	68 df 77 10 f0       	push   $0xf01077df
f0100e31:	68 43 77 10 f0       	push   $0xf0107743
f0100e36:	68 64 03 00 00       	push   $0x364
f0100e3b:	68 1d 77 10 f0       	push   $0xf010771d
f0100e40:	e8 fb f1 ff ff       	call   f0100040 <_panic>
	if (!page_free_list)
f0100e45:	a1 40 92 23 f0       	mov    0xf0239240,%eax
f0100e4a:	85 c0                	test   %eax,%eax
f0100e4c:	0f 84 8f fd ff ff    	je     f0100be1 <check_page_free_list+0x24>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100e52:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100e55:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e58:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e5b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100e5e:	89 c2                	mov    %eax,%edx
f0100e60:	2b 15 90 9e 23 f0    	sub    0xf0239e90,%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100e66:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100e6c:	0f 95 c2             	setne  %dl
f0100e6f:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100e72:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100e76:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100e78:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e7c:	8b 00                	mov    (%eax),%eax
f0100e7e:	85 c0                	test   %eax,%eax
f0100e80:	75 dc                	jne    f0100e5e <check_page_free_list+0x2a1>
		*tp[1] = 0;
f0100e82:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e85:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100e8b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e8e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e91:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100e93:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100e96:	a3 40 92 23 f0       	mov    %eax,0xf0239240
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e9b:	be 01 00 00 00       	mov    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ea0:	8b 1d 40 92 23 f0    	mov    0xf0239240,%ebx
f0100ea6:	e9 61 fd ff ff       	jmp    f0100c0c <check_page_free_list+0x4f>

f0100eab <page_init>:
{
f0100eab:	f3 0f 1e fb          	endbr32 
f0100eaf:	55                   	push   %ebp
f0100eb0:	89 e5                	mov    %esp,%ebp
f0100eb2:	57                   	push   %edi
f0100eb3:	56                   	push   %esi
f0100eb4:	53                   	push   %ebx
f0100eb5:	83 ec 0c             	sub    $0xc,%esp
	size_t num_used = ((uint32_t)boot_alloc(0)-EXTPHYSMEM-KERNBASE)/PGSIZE;
f0100eb8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ebd:	e8 2f fc ff ff       	call   f0100af1 <boot_alloc>
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100ec2:	8b 0d 44 92 23 f0    	mov    0xf0239244,%ecx
	size_t num_used = ((uint32_t)boot_alloc(0)-EXTPHYSMEM-KERNBASE)/PGSIZE;
f0100ec8:	05 00 00 f0 0f       	add    $0xff00000,%eax
f0100ecd:	c1 e8 0c             	shr    $0xc,%eax
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100ed0:	8d 74 01 60          	lea    0x60(%ecx,%eax,1),%esi
f0100ed4:	8b 1d 40 92 23 f0    	mov    0xf0239240,%ebx
	for(size_t i = 0;i<npages;i++)
f0100eda:	bf 00 00 00 00       	mov    $0x0,%edi
f0100edf:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ee4:	eb 4b                	jmp    f0100f31 <page_init+0x86>
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100ee6:	39 c1                	cmp    %eax,%ecx
f0100ee8:	77 1b                	ja     f0100f05 <page_init+0x5a>
f0100eea:	39 c6                	cmp    %eax,%esi
f0100eec:	76 17                	jbe    f0100f05 <page_init+0x5a>
			pages[i].pp_ref = 1;
f0100eee:	8b 15 90 9e 23 f0    	mov    0xf0239e90,%edx
f0100ef4:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100ef7:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
			pages[i].pp_link = NULL;
f0100efd:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
f0100f03:	eb 29                	jmp    f0100f2e <page_init+0x83>
		else if(i == mpentry)
f0100f05:	83 f8 07             	cmp    $0x7,%eax
f0100f08:	74 47                	je     f0100f51 <page_init+0xa6>
f0100f0a:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
			pages[i].pp_ref = 0;
f0100f11:	89 d7                	mov    %edx,%edi
f0100f13:	03 3d 90 9e 23 f0    	add    0xf0239e90,%edi
f0100f19:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
			pages[i].pp_link = page_free_list;
f0100f1f:	89 1f                	mov    %ebx,(%edi)
			page_free_list = &pages[i];
f0100f21:	89 d3                	mov    %edx,%ebx
f0100f23:	03 1d 90 9e 23 f0    	add    0xf0239e90,%ebx
f0100f29:	bf 01 00 00 00       	mov    $0x1,%edi
	for(size_t i = 0;i<npages;i++)
f0100f2e:	83 c0 01             	add    $0x1,%eax
f0100f31:	39 05 88 9e 23 f0    	cmp    %eax,0xf0239e88
f0100f37:	76 2d                	jbe    f0100f66 <page_init+0xbb>
		if(i == 0)
f0100f39:	85 c0                	test   %eax,%eax
f0100f3b:	75 a9                	jne    f0100ee6 <page_init+0x3b>
			pages[i].pp_ref = 1;
f0100f3d:	8b 15 90 9e 23 f0    	mov    0xf0239e90,%edx
f0100f43:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
			pages[i].pp_link = NULL;
f0100f49:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
f0100f4f:	eb dd                	jmp    f0100f2e <page_init+0x83>
			pages[i].pp_ref = 1;
f0100f51:	8b 15 90 9e 23 f0    	mov    0xf0239e90,%edx
f0100f57:	66 c7 42 3c 01 00    	movw   $0x1,0x3c(%edx)
			pages[i].pp_link = NULL;
f0100f5d:	c7 42 38 00 00 00 00 	movl   $0x0,0x38(%edx)
f0100f64:	eb c8                	jmp    f0100f2e <page_init+0x83>
f0100f66:	89 f8                	mov    %edi,%eax
f0100f68:	84 c0                	test   %al,%al
f0100f6a:	74 06                	je     f0100f72 <page_init+0xc7>
f0100f6c:	89 1d 40 92 23 f0    	mov    %ebx,0xf0239240
}
f0100f72:	83 c4 0c             	add    $0xc,%esp
f0100f75:	5b                   	pop    %ebx
f0100f76:	5e                   	pop    %esi
f0100f77:	5f                   	pop    %edi
f0100f78:	5d                   	pop    %ebp
f0100f79:	c3                   	ret    

f0100f7a <page_alloc>:
{
f0100f7a:	f3 0f 1e fb          	endbr32 
f0100f7e:	55                   	push   %ebp
f0100f7f:	89 e5                	mov    %esp,%ebp
f0100f81:	53                   	push   %ebx
f0100f82:	83 ec 04             	sub    $0x4,%esp
	if(page_free_list == NULL)
f0100f85:	8b 1d 40 92 23 f0    	mov    0xf0239240,%ebx
f0100f8b:	85 db                	test   %ebx,%ebx
f0100f8d:	74 30                	je     f0100fbf <page_alloc+0x45>
	page_free_list = page_free_list->pp_link;
f0100f8f:	8b 03                	mov    (%ebx),%eax
f0100f91:	a3 40 92 23 f0       	mov    %eax,0xf0239240
	alloc->pp_link = NULL;
f0100f96:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
f0100f9c:	89 d8                	mov    %ebx,%eax
f0100f9e:	2b 05 90 9e 23 f0    	sub    0xf0239e90,%eax
f0100fa4:	c1 f8 03             	sar    $0x3,%eax
f0100fa7:	89 c2                	mov    %eax,%edx
f0100fa9:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0100fac:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0100fb1:	3b 05 88 9e 23 f0    	cmp    0xf0239e88,%eax
f0100fb7:	73 0d                	jae    f0100fc6 <page_alloc+0x4c>
	if(alloc_flags & ALLOC_ZERO)
f0100fb9:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100fbd:	75 19                	jne    f0100fd8 <page_alloc+0x5e>
}
f0100fbf:	89 d8                	mov    %ebx,%eax
f0100fc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fc4:	c9                   	leave  
f0100fc5:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fc6:	52                   	push   %edx
f0100fc7:	68 e4 67 10 f0       	push   $0xf01067e4
f0100fcc:	6a 58                	push   $0x58
f0100fce:	68 29 77 10 f0       	push   $0xf0107729
f0100fd3:	e8 68 f0 ff ff       	call   f0100040 <_panic>
		memset(head,0,PGSIZE);
f0100fd8:	83 ec 04             	sub    $0x4,%esp
f0100fdb:	68 00 10 00 00       	push   $0x1000
f0100fe0:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100fe2:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0100fe8:	52                   	push   %edx
f0100fe9:	e8 42 4b 00 00       	call   f0105b30 <memset>
f0100fee:	83 c4 10             	add    $0x10,%esp
f0100ff1:	eb cc                	jmp    f0100fbf <page_alloc+0x45>

f0100ff3 <page_free>:
{
f0100ff3:	f3 0f 1e fb          	endbr32 
f0100ff7:	55                   	push   %ebp
f0100ff8:	89 e5                	mov    %esp,%ebp
f0100ffa:	83 ec 08             	sub    $0x8,%esp
f0100ffd:	8b 45 08             	mov    0x8(%ebp),%eax
	if((pp->pp_ref != 0) | (pp->pp_link != NULL))  // referenced or freed
f0101000:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101005:	75 14                	jne    f010101b <page_free+0x28>
f0101007:	83 38 00             	cmpl   $0x0,(%eax)
f010100a:	75 0f                	jne    f010101b <page_free+0x28>
	pp->pp_link = page_free_list;
f010100c:	8b 15 40 92 23 f0    	mov    0xf0239240,%edx
f0101012:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101014:	a3 40 92 23 f0       	mov    %eax,0xf0239240
}
f0101019:	c9                   	leave  
f010101a:	c3                   	ret    
		panic("at pmap.c:page_free(): Page double free or freeing a referenced page");
f010101b:	83 ec 04             	sub    $0x4,%esp
f010101e:	68 74 6e 10 f0       	push   $0xf0106e74
f0101023:	68 ae 01 00 00       	push   $0x1ae
f0101028:	68 1d 77 10 f0       	push   $0xf010771d
f010102d:	e8 0e f0 ff ff       	call   f0100040 <_panic>

f0101032 <page_decref>:
{
f0101032:	f3 0f 1e fb          	endbr32 
f0101036:	55                   	push   %ebp
f0101037:	89 e5                	mov    %esp,%ebp
f0101039:	83 ec 08             	sub    $0x8,%esp
f010103c:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f010103f:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101043:	83 e8 01             	sub    $0x1,%eax
f0101046:	66 89 42 04          	mov    %ax,0x4(%edx)
f010104a:	66 85 c0             	test   %ax,%ax
f010104d:	74 02                	je     f0101051 <page_decref+0x1f>
}
f010104f:	c9                   	leave  
f0101050:	c3                   	ret    
		page_free(pp);
f0101051:	83 ec 0c             	sub    $0xc,%esp
f0101054:	52                   	push   %edx
f0101055:	e8 99 ff ff ff       	call   f0100ff3 <page_free>
f010105a:	83 c4 10             	add    $0x10,%esp
}
f010105d:	eb f0                	jmp    f010104f <page_decref+0x1d>

f010105f <pgdir_walk>:
{
f010105f:	f3 0f 1e fb          	endbr32 
f0101063:	55                   	push   %ebp
f0101064:	89 e5                	mov    %esp,%ebp
f0101066:	56                   	push   %esi
f0101067:	53                   	push   %ebx
f0101068:	8b 75 0c             	mov    0xc(%ebp),%esi
	unsigned int dir_offset = PDX(va);
f010106b:	89 f3                	mov    %esi,%ebx
f010106d:	c1 eb 16             	shr    $0x16,%ebx
	pde_t* entry = pgdir+dir_offset;
f0101070:	c1 e3 02             	shl    $0x2,%ebx
f0101073:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*entry & PTE_P))
f0101076:	f6 03 01             	testb  $0x1,(%ebx)
f0101079:	75 2d                	jne    f01010a8 <pgdir_walk+0x49>
		if(create)
f010107b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010107f:	74 68                	je     f01010e9 <pgdir_walk+0x8a>
			new_page = page_alloc(1);
f0101081:	83 ec 0c             	sub    $0xc,%esp
f0101084:	6a 01                	push   $0x1
f0101086:	e8 ef fe ff ff       	call   f0100f7a <page_alloc>
			if(new_page == NULL)
f010108b:	83 c4 10             	add    $0x10,%esp
f010108e:	85 c0                	test   %eax,%eax
f0101090:	74 3b                	je     f01010cd <pgdir_walk+0x6e>
			new_page->pp_ref++;
f0101092:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0101097:	2b 05 90 9e 23 f0    	sub    0xf0239e90,%eax
f010109d:	c1 f8 03             	sar    $0x3,%eax
f01010a0:	c1 e0 0c             	shl    $0xc,%eax
			*entry = ((page2pa(new_page))|PTE_P|PTE_W|PTE_U);
f01010a3:	83 c8 07             	or     $0x7,%eax
f01010a6:	89 03                	mov    %eax,(%ebx)
	page_base = (pte_t*)KADDR(PTE_ADDR(*entry));
f01010a8:	8b 03                	mov    (%ebx),%eax
f01010aa:	89 c2                	mov    %eax,%edx
f01010ac:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f01010b2:	c1 e8 0c             	shr    $0xc,%eax
f01010b5:	3b 05 88 9e 23 f0    	cmp    0xf0239e88,%eax
f01010bb:	73 17                	jae    f01010d4 <pgdir_walk+0x75>
	page_offset = PTX(va);
f01010bd:	c1 ee 0a             	shr    $0xa,%esi
	return &page_base[page_offset];
f01010c0:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01010c6:	8d 84 32 00 00 00 f0 	lea    -0x10000000(%edx,%esi,1),%eax
}
f01010cd:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01010d0:	5b                   	pop    %ebx
f01010d1:	5e                   	pop    %esi
f01010d2:	5d                   	pop    %ebp
f01010d3:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010d4:	52                   	push   %edx
f01010d5:	68 e4 67 10 f0       	push   $0xf01067e4
f01010da:	68 fb 01 00 00       	push   $0x1fb
f01010df:	68 1d 77 10 f0       	push   $0xf010771d
f01010e4:	e8 57 ef ff ff       	call   f0100040 <_panic>
			return NULL;
f01010e9:	b8 00 00 00 00       	mov    $0x0,%eax
f01010ee:	eb dd                	jmp    f01010cd <pgdir_walk+0x6e>

f01010f0 <boot_map_region>:
{
f01010f0:	55                   	push   %ebp
f01010f1:	89 e5                	mov    %esp,%ebp
f01010f3:	57                   	push   %edi
f01010f4:	56                   	push   %esi
f01010f5:	53                   	push   %ebx
f01010f6:	83 ec 1c             	sub    $0x1c,%esp
f01010f9:	89 c7                	mov    %eax,%edi
f01010fb:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01010fe:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for(add = 0;add<size;add+=PGSIZE)
f0101101:	be 00 00 00 00       	mov    $0x0,%esi
f0101106:	89 f3                	mov    %esi,%ebx
f0101108:	03 5d 08             	add    0x8(%ebp),%ebx
f010110b:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f010110e:	76 24                	jbe    f0101134 <boot_map_region+0x44>
		entry = pgdir_walk(pgdir,(void*)va,1);  // get the entry of page table
f0101110:	83 ec 04             	sub    $0x4,%esp
f0101113:	6a 01                	push   $0x1
f0101115:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101118:	01 f0                	add    %esi,%eax
f010111a:	50                   	push   %eax
f010111b:	57                   	push   %edi
f010111c:	e8 3e ff ff ff       	call   f010105f <pgdir_walk>
		*entry = (pa|perm|PTE_P);
f0101121:	0b 5d 0c             	or     0xc(%ebp),%ebx
f0101124:	83 cb 01             	or     $0x1,%ebx
f0101127:	89 18                	mov    %ebx,(%eax)
	for(add = 0;add<size;add+=PGSIZE)
f0101129:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010112f:	83 c4 10             	add    $0x10,%esp
f0101132:	eb d2                	jmp    f0101106 <boot_map_region+0x16>
}
f0101134:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101137:	5b                   	pop    %ebx
f0101138:	5e                   	pop    %esi
f0101139:	5f                   	pop    %edi
f010113a:	5d                   	pop    %ebp
f010113b:	c3                   	ret    

f010113c <page_lookup>:
{
f010113c:	f3 0f 1e fb          	endbr32 
f0101140:	55                   	push   %ebp
f0101141:	89 e5                	mov    %esp,%ebp
f0101143:	53                   	push   %ebx
f0101144:	83 ec 08             	sub    $0x8,%esp
f0101147:	8b 5d 10             	mov    0x10(%ebp),%ebx
	entry = pgdir_walk(pgdir,va,0);
f010114a:	6a 00                	push   $0x0
f010114c:	ff 75 0c             	pushl  0xc(%ebp)
f010114f:	ff 75 08             	pushl  0x8(%ebp)
f0101152:	e8 08 ff ff ff       	call   f010105f <pgdir_walk>
	if(entry == NULL)
f0101157:	83 c4 10             	add    $0x10,%esp
f010115a:	85 c0                	test   %eax,%eax
f010115c:	74 3c                	je     f010119a <page_lookup+0x5e>
	if(!(*entry & PTE_P))
f010115e:	8b 10                	mov    (%eax),%edx
f0101160:	f6 c2 01             	test   $0x1,%dl
f0101163:	74 39                	je     f010119e <page_lookup+0x62>
f0101165:	c1 ea 0c             	shr    $0xc,%edx
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101168:	39 15 88 9e 23 f0    	cmp    %edx,0xf0239e88
f010116e:	76 16                	jbe    f0101186 <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f0101170:	8b 0d 90 9e 23 f0    	mov    0xf0239e90,%ecx
f0101176:	8d 14 d1             	lea    (%ecx,%edx,8),%edx
	if(pte_store != NULL)
f0101179:	85 db                	test   %ebx,%ebx
f010117b:	74 02                	je     f010117f <page_lookup+0x43>
		*pte_store = entry;
f010117d:	89 03                	mov    %eax,(%ebx)
}
f010117f:	89 d0                	mov    %edx,%eax
f0101181:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101184:	c9                   	leave  
f0101185:	c3                   	ret    
		panic("pa2page called with invalid pa");
f0101186:	83 ec 04             	sub    $0x4,%esp
f0101189:	68 bc 6e 10 f0       	push   $0xf0106ebc
f010118e:	6a 51                	push   $0x51
f0101190:	68 29 77 10 f0       	push   $0xf0107729
f0101195:	e8 a6 ee ff ff       	call   f0100040 <_panic>
		return NULL;
f010119a:	89 c2                	mov    %eax,%edx
f010119c:	eb e1                	jmp    f010117f <page_lookup+0x43>
		return NULL;
f010119e:	ba 00 00 00 00       	mov    $0x0,%edx
f01011a3:	eb da                	jmp    f010117f <page_lookup+0x43>

f01011a5 <tlb_invalidate>:
{
f01011a5:	f3 0f 1e fb          	endbr32 
f01011a9:	55                   	push   %ebp
f01011aa:	89 e5                	mov    %esp,%ebp
f01011ac:	83 ec 08             	sub    $0x8,%esp
	if (!curenv || curenv->env_pgdir == pgdir)
f01011af:	e8 9a 4f 00 00       	call   f010614e <cpunum>
f01011b4:	6b c0 74             	imul   $0x74,%eax,%eax
f01011b7:	83 b8 28 a0 23 f0 00 	cmpl   $0x0,-0xfdc5fd8(%eax)
f01011be:	74 16                	je     f01011d6 <tlb_invalidate+0x31>
f01011c0:	e8 89 4f 00 00       	call   f010614e <cpunum>
f01011c5:	6b c0 74             	imul   $0x74,%eax,%eax
f01011c8:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f01011ce:	8b 55 08             	mov    0x8(%ebp),%edx
f01011d1:	39 50 60             	cmp    %edx,0x60(%eax)
f01011d4:	75 06                	jne    f01011dc <tlb_invalidate+0x37>
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01011d6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011d9:	0f 01 38             	invlpg (%eax)
}
f01011dc:	c9                   	leave  
f01011dd:	c3                   	ret    

f01011de <page_remove>:
{
f01011de:	f3 0f 1e fb          	endbr32 
f01011e2:	55                   	push   %ebp
f01011e3:	89 e5                	mov    %esp,%ebp
f01011e5:	56                   	push   %esi
f01011e6:	53                   	push   %ebx
f01011e7:	83 ec 14             	sub    $0x14,%esp
f01011ea:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01011ed:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t* pte = NULL;
f01011f0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo* page = page_lookup(pgdir,va,&pte);
f01011f7:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01011fa:	50                   	push   %eax
f01011fb:	56                   	push   %esi
f01011fc:	53                   	push   %ebx
f01011fd:	e8 3a ff ff ff       	call   f010113c <page_lookup>
	if(page == NULL)
f0101202:	83 c4 10             	add    $0x10,%esp
f0101205:	85 c0                	test   %eax,%eax
f0101207:	74 1f                	je     f0101228 <page_remove+0x4a>
	page_decref(page);
f0101209:	83 ec 0c             	sub    $0xc,%esp
f010120c:	50                   	push   %eax
f010120d:	e8 20 fe ff ff       	call   f0101032 <page_decref>
	tlb_invalidate(pgdir,va);
f0101212:	83 c4 08             	add    $0x8,%esp
f0101215:	56                   	push   %esi
f0101216:	53                   	push   %ebx
f0101217:	e8 89 ff ff ff       	call   f01011a5 <tlb_invalidate>
	*pte = 0;
f010121c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010121f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101225:	83 c4 10             	add    $0x10,%esp
}
f0101228:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010122b:	5b                   	pop    %ebx
f010122c:	5e                   	pop    %esi
f010122d:	5d                   	pop    %ebp
f010122e:	c3                   	ret    

f010122f <page_insert>:
{
f010122f:	f3 0f 1e fb          	endbr32 
f0101233:	55                   	push   %ebp
f0101234:	89 e5                	mov    %esp,%ebp
f0101236:	57                   	push   %edi
f0101237:	56                   	push   %esi
f0101238:	53                   	push   %ebx
f0101239:	83 ec 10             	sub    $0x10,%esp
f010123c:	8b 7d 08             	mov    0x8(%ebp),%edi
f010123f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	entry = pgdir_walk(pgdir,va,1); // get the page table entry 
f0101242:	6a 01                	push   $0x1
f0101244:	ff 75 10             	pushl  0x10(%ebp)
f0101247:	57                   	push   %edi
f0101248:	e8 12 fe ff ff       	call   f010105f <pgdir_walk>
	if(entry == NULL)
f010124d:	83 c4 10             	add    $0x10,%esp
f0101250:	85 c0                	test   %eax,%eax
f0101252:	74 56                	je     f01012aa <page_insert+0x7b>
f0101254:	89 c6                	mov    %eax,%esi
	pp->pp_ref++;
f0101256:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if(*entry&PTE_P)
f010125b:	f6 00 01             	testb  $0x1,(%eax)
f010125e:	75 2d                	jne    f010128d <page_insert+0x5e>
	return (pp - pages) << PGSHIFT;
f0101260:	2b 1d 90 9e 23 f0    	sub    0xf0239e90,%ebx
f0101266:	c1 fb 03             	sar    $0x3,%ebx
f0101269:	c1 e3 0c             	shl    $0xc,%ebx
	*entry = ((page2pa(pp))|perm|PTE_P);
f010126c:	0b 5d 14             	or     0x14(%ebp),%ebx
f010126f:	83 cb 01             	or     $0x1,%ebx
f0101272:	89 1e                	mov    %ebx,(%esi)
	pgdir[PDX(va)] |= perm;
f0101274:	8b 45 10             	mov    0x10(%ebp),%eax
f0101277:	c1 e8 16             	shr    $0x16,%eax
f010127a:	8b 55 14             	mov    0x14(%ebp),%edx
f010127d:	09 14 87             	or     %edx,(%edi,%eax,4)
	return 0;
f0101280:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101285:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101288:	5b                   	pop    %ebx
f0101289:	5e                   	pop    %esi
f010128a:	5f                   	pop    %edi
f010128b:	5d                   	pop    %ebp
f010128c:	c3                   	ret    
		tlb_invalidate(pgdir,va);
f010128d:	83 ec 08             	sub    $0x8,%esp
f0101290:	ff 75 10             	pushl  0x10(%ebp)
f0101293:	57                   	push   %edi
f0101294:	e8 0c ff ff ff       	call   f01011a5 <tlb_invalidate>
		page_remove(pgdir,va);
f0101299:	83 c4 08             	add    $0x8,%esp
f010129c:	ff 75 10             	pushl  0x10(%ebp)
f010129f:	57                   	push   %edi
f01012a0:	e8 39 ff ff ff       	call   f01011de <page_remove>
f01012a5:	83 c4 10             	add    $0x10,%esp
f01012a8:	eb b6                	jmp    f0101260 <page_insert+0x31>
		return -E_NO_MEM;
f01012aa:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01012af:	eb d4                	jmp    f0101285 <page_insert+0x56>

f01012b1 <mmio_map_region>:
{
f01012b1:	f3 0f 1e fb          	endbr32 
f01012b5:	55                   	push   %ebp
f01012b6:	89 e5                	mov    %esp,%ebp
f01012b8:	57                   	push   %edi
f01012b9:	56                   	push   %esi
f01012ba:	53                   	push   %ebx
f01012bb:	83 ec 0c             	sub    $0xc,%esp
f01012be:	8b 5d 08             	mov    0x8(%ebp),%ebx
	size = ROUNDUP(pa+size,PGSIZE);
f01012c1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012c4:	8d bc 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%edi
f01012cb:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	pa = ROUNDDOWN(pa,PGSIZE);
f01012d1:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	size-=pa;
f01012d7:	89 fe                	mov    %edi,%esi
f01012d9:	29 de                	sub    %ebx,%esi
	if(size+base>=MMIOLIM)
f01012db:	8b 15 00 33 12 f0    	mov    0xf0123300,%edx
f01012e1:	8d 04 32             	lea    (%edx,%esi,1),%eax
f01012e4:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f01012e9:	77 2b                	ja     f0101316 <mmio_map_region+0x65>
	boot_map_region(kern_pgdir,base,size,pa,PTE_W|PTE_PCD|PTE_PWT);
f01012eb:	83 ec 08             	sub    $0x8,%esp
f01012ee:	6a 1a                	push   $0x1a
f01012f0:	53                   	push   %ebx
f01012f1:	89 f1                	mov    %esi,%ecx
f01012f3:	a1 8c 9e 23 f0       	mov    0xf0239e8c,%eax
f01012f8:	e8 f3 fd ff ff       	call   f01010f0 <boot_map_region>
	base+=size;
f01012fd:	89 f0                	mov    %esi,%eax
f01012ff:	03 05 00 33 12 f0    	add    0xf0123300,%eax
f0101305:	a3 00 33 12 f0       	mov    %eax,0xf0123300
	return (void*)(base-size);
f010130a:	29 fb                	sub    %edi,%ebx
f010130c:	01 d8                	add    %ebx,%eax
}
f010130e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101311:	5b                   	pop    %ebx
f0101312:	5e                   	pop    %esi
f0101313:	5f                   	pop    %edi
f0101314:	5d                   	pop    %ebp
f0101315:	c3                   	ret    
		panic("At mmio_map_region(): overflow MMIOLIM");
f0101316:	83 ec 04             	sub    $0x4,%esp
f0101319:	68 dc 6e 10 f0       	push   $0xf0106edc
f010131e:	68 cf 02 00 00       	push   $0x2cf
f0101323:	68 1d 77 10 f0       	push   $0xf010771d
f0101328:	e8 13 ed ff ff       	call   f0100040 <_panic>

f010132d <mem_init>:
{
f010132d:	f3 0f 1e fb          	endbr32 
f0101331:	55                   	push   %ebp
f0101332:	89 e5                	mov    %esp,%ebp
f0101334:	57                   	push   %edi
f0101335:	56                   	push   %esi
f0101336:	53                   	push   %ebx
f0101337:	83 ec 3c             	sub    $0x3c,%esp
	basemem = nvram_read(NVRAM_BASELO);
f010133a:	b8 15 00 00 00       	mov    $0x15,%eax
f010133f:	e8 84 f7 ff ff       	call   f0100ac8 <nvram_read>
f0101344:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101346:	b8 17 00 00 00       	mov    $0x17,%eax
f010134b:	e8 78 f7 ff ff       	call   f0100ac8 <nvram_read>
f0101350:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101352:	b8 34 00 00 00       	mov    $0x34,%eax
f0101357:	e8 6c f7 ff ff       	call   f0100ac8 <nvram_read>
	if (ext16mem)
f010135c:	c1 e0 06             	shl    $0x6,%eax
f010135f:	0f 84 ea 00 00 00    	je     f010144f <mem_init+0x122>
		totalmem = 16 * 1024 + ext16mem;
f0101365:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f010136a:	89 c2                	mov    %eax,%edx
f010136c:	c1 ea 02             	shr    $0x2,%edx
f010136f:	89 15 88 9e 23 f0    	mov    %edx,0xf0239e88
	npages_basemem = basemem / (PGSIZE / 1024);
f0101375:	89 da                	mov    %ebx,%edx
f0101377:	c1 ea 02             	shr    $0x2,%edx
f010137a:	89 15 44 92 23 f0    	mov    %edx,0xf0239244
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101380:	89 c2                	mov    %eax,%edx
f0101382:	29 da                	sub    %ebx,%edx
f0101384:	52                   	push   %edx
f0101385:	53                   	push   %ebx
f0101386:	50                   	push   %eax
f0101387:	68 04 6f 10 f0       	push   $0xf0106f04
f010138c:	e8 43 26 00 00       	call   f01039d4 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101391:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101396:	e8 56 f7 ff ff       	call   f0100af1 <boot_alloc>
f010139b:	a3 8c 9e 23 f0       	mov    %eax,0xf0239e8c
	memset(kern_pgdir, 0, PGSIZE);
f01013a0:	83 c4 0c             	add    $0xc,%esp
f01013a3:	68 00 10 00 00       	push   $0x1000
f01013a8:	6a 00                	push   $0x0
f01013aa:	50                   	push   %eax
f01013ab:	e8 80 47 00 00       	call   f0105b30 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01013b0:	a1 8c 9e 23 f0       	mov    0xf0239e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01013b5:	83 c4 10             	add    $0x10,%esp
f01013b8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013bd:	0f 86 9c 00 00 00    	jbe    f010145f <mem_init+0x132>
	return (physaddr_t)kva - KERNBASE;
f01013c3:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01013c9:	83 ca 05             	or     $0x5,%edx
f01013cc:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages*sizeof(struct PageInfo));
f01013d2:	a1 88 9e 23 f0       	mov    0xf0239e88,%eax
f01013d7:	c1 e0 03             	shl    $0x3,%eax
f01013da:	e8 12 f7 ff ff       	call   f0100af1 <boot_alloc>
f01013df:	a3 90 9e 23 f0       	mov    %eax,0xf0239e90
	memset(pages,0,npages*sizeof(struct PageInfo));
f01013e4:	83 ec 04             	sub    $0x4,%esp
f01013e7:	8b 0d 88 9e 23 f0    	mov    0xf0239e88,%ecx
f01013ed:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01013f4:	52                   	push   %edx
f01013f5:	6a 00                	push   $0x0
f01013f7:	50                   	push   %eax
f01013f8:	e8 33 47 00 00       	call   f0105b30 <memset>
	envs = (struct Env*)boot_alloc(NENV*sizeof(struct Env));
f01013fd:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101402:	e8 ea f6 ff ff       	call   f0100af1 <boot_alloc>
f0101407:	a3 48 92 23 f0       	mov    %eax,0xf0239248
	memset(envs,0,NENV*sizeof(struct Env));
f010140c:	83 c4 0c             	add    $0xc,%esp
f010140f:	68 00 f0 01 00       	push   $0x1f000
f0101414:	6a 00                	push   $0x0
f0101416:	50                   	push   %eax
f0101417:	e8 14 47 00 00       	call   f0105b30 <memset>
	page_init();
f010141c:	e8 8a fa ff ff       	call   f0100eab <page_init>
	check_page_free_list(1);
f0101421:	b8 01 00 00 00       	mov    $0x1,%eax
f0101426:	e8 92 f7 ff ff       	call   f0100bbd <check_page_free_list>
	if (!pages)
f010142b:	83 c4 10             	add    $0x10,%esp
f010142e:	83 3d 90 9e 23 f0 00 	cmpl   $0x0,0xf0239e90
f0101435:	74 3d                	je     f0101474 <mem_init+0x147>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101437:	a1 40 92 23 f0       	mov    0xf0239240,%eax
f010143c:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0101443:	85 c0                	test   %eax,%eax
f0101445:	74 44                	je     f010148b <mem_init+0x15e>
		++nfree;
f0101447:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010144b:	8b 00                	mov    (%eax),%eax
f010144d:	eb f4                	jmp    f0101443 <mem_init+0x116>
		totalmem = 1 * 1024 + extmem;
f010144f:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101455:	85 f6                	test   %esi,%esi
f0101457:	0f 44 c3             	cmove  %ebx,%eax
f010145a:	e9 0b ff ff ff       	jmp    f010136a <mem_init+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010145f:	50                   	push   %eax
f0101460:	68 08 68 10 f0       	push   $0xf0106808
f0101465:	68 a4 00 00 00       	push   $0xa4
f010146a:	68 1d 77 10 f0       	push   $0xf010771d
f010146f:	e8 cc eb ff ff       	call   f0100040 <_panic>
		panic("'pages' is a null pointer!");
f0101474:	83 ec 04             	sub    $0x4,%esp
f0101477:	68 f0 77 10 f0       	push   $0xf01077f0
f010147c:	68 77 03 00 00       	push   $0x377
f0101481:	68 1d 77 10 f0       	push   $0xf010771d
f0101486:	e8 b5 eb ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f010148b:	83 ec 0c             	sub    $0xc,%esp
f010148e:	6a 00                	push   $0x0
f0101490:	e8 e5 fa ff ff       	call   f0100f7a <page_alloc>
f0101495:	89 c3                	mov    %eax,%ebx
f0101497:	83 c4 10             	add    $0x10,%esp
f010149a:	85 c0                	test   %eax,%eax
f010149c:	0f 84 11 02 00 00    	je     f01016b3 <mem_init+0x386>
	assert((pp1 = page_alloc(0)));
f01014a2:	83 ec 0c             	sub    $0xc,%esp
f01014a5:	6a 00                	push   $0x0
f01014a7:	e8 ce fa ff ff       	call   f0100f7a <page_alloc>
f01014ac:	89 c6                	mov    %eax,%esi
f01014ae:	83 c4 10             	add    $0x10,%esp
f01014b1:	85 c0                	test   %eax,%eax
f01014b3:	0f 84 13 02 00 00    	je     f01016cc <mem_init+0x39f>
	assert((pp2 = page_alloc(0)));
f01014b9:	83 ec 0c             	sub    $0xc,%esp
f01014bc:	6a 00                	push   $0x0
f01014be:	e8 b7 fa ff ff       	call   f0100f7a <page_alloc>
f01014c3:	89 c7                	mov    %eax,%edi
f01014c5:	83 c4 10             	add    $0x10,%esp
f01014c8:	85 c0                	test   %eax,%eax
f01014ca:	0f 84 15 02 00 00    	je     f01016e5 <mem_init+0x3b8>
	assert(pp1 && pp1 != pp0);
f01014d0:	39 f3                	cmp    %esi,%ebx
f01014d2:	0f 84 26 02 00 00    	je     f01016fe <mem_init+0x3d1>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014d8:	39 c6                	cmp    %eax,%esi
f01014da:	0f 84 37 02 00 00    	je     f0101717 <mem_init+0x3ea>
f01014e0:	39 c3                	cmp    %eax,%ebx
f01014e2:	0f 84 2f 02 00 00    	je     f0101717 <mem_init+0x3ea>
	return (pp - pages) << PGSHIFT;
f01014e8:	8b 0d 90 9e 23 f0    	mov    0xf0239e90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014ee:	8b 15 88 9e 23 f0    	mov    0xf0239e88,%edx
f01014f4:	c1 e2 0c             	shl    $0xc,%edx
f01014f7:	89 d8                	mov    %ebx,%eax
f01014f9:	29 c8                	sub    %ecx,%eax
f01014fb:	c1 f8 03             	sar    $0x3,%eax
f01014fe:	c1 e0 0c             	shl    $0xc,%eax
f0101501:	39 d0                	cmp    %edx,%eax
f0101503:	0f 83 27 02 00 00    	jae    f0101730 <mem_init+0x403>
f0101509:	89 f0                	mov    %esi,%eax
f010150b:	29 c8                	sub    %ecx,%eax
f010150d:	c1 f8 03             	sar    $0x3,%eax
f0101510:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101513:	39 c2                	cmp    %eax,%edx
f0101515:	0f 86 2e 02 00 00    	jbe    f0101749 <mem_init+0x41c>
f010151b:	89 f8                	mov    %edi,%eax
f010151d:	29 c8                	sub    %ecx,%eax
f010151f:	c1 f8 03             	sar    $0x3,%eax
f0101522:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f0101525:	39 c2                	cmp    %eax,%edx
f0101527:	0f 86 35 02 00 00    	jbe    f0101762 <mem_init+0x435>
	fl = page_free_list;
f010152d:	a1 40 92 23 f0       	mov    0xf0239240,%eax
f0101532:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101535:	c7 05 40 92 23 f0 00 	movl   $0x0,0xf0239240
f010153c:	00 00 00 
	assert(!page_alloc(0));
f010153f:	83 ec 0c             	sub    $0xc,%esp
f0101542:	6a 00                	push   $0x0
f0101544:	e8 31 fa ff ff       	call   f0100f7a <page_alloc>
f0101549:	83 c4 10             	add    $0x10,%esp
f010154c:	85 c0                	test   %eax,%eax
f010154e:	0f 85 27 02 00 00    	jne    f010177b <mem_init+0x44e>
	page_free(pp0);
f0101554:	83 ec 0c             	sub    $0xc,%esp
f0101557:	53                   	push   %ebx
f0101558:	e8 96 fa ff ff       	call   f0100ff3 <page_free>
	page_free(pp1);
f010155d:	89 34 24             	mov    %esi,(%esp)
f0101560:	e8 8e fa ff ff       	call   f0100ff3 <page_free>
	page_free(pp2);
f0101565:	89 3c 24             	mov    %edi,(%esp)
f0101568:	e8 86 fa ff ff       	call   f0100ff3 <page_free>
	assert((pp0 = page_alloc(0)));
f010156d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101574:	e8 01 fa ff ff       	call   f0100f7a <page_alloc>
f0101579:	89 c3                	mov    %eax,%ebx
f010157b:	83 c4 10             	add    $0x10,%esp
f010157e:	85 c0                	test   %eax,%eax
f0101580:	0f 84 0e 02 00 00    	je     f0101794 <mem_init+0x467>
	assert((pp1 = page_alloc(0)));
f0101586:	83 ec 0c             	sub    $0xc,%esp
f0101589:	6a 00                	push   $0x0
f010158b:	e8 ea f9 ff ff       	call   f0100f7a <page_alloc>
f0101590:	89 c6                	mov    %eax,%esi
f0101592:	83 c4 10             	add    $0x10,%esp
f0101595:	85 c0                	test   %eax,%eax
f0101597:	0f 84 10 02 00 00    	je     f01017ad <mem_init+0x480>
	assert((pp2 = page_alloc(0)));
f010159d:	83 ec 0c             	sub    $0xc,%esp
f01015a0:	6a 00                	push   $0x0
f01015a2:	e8 d3 f9 ff ff       	call   f0100f7a <page_alloc>
f01015a7:	89 c7                	mov    %eax,%edi
f01015a9:	83 c4 10             	add    $0x10,%esp
f01015ac:	85 c0                	test   %eax,%eax
f01015ae:	0f 84 12 02 00 00    	je     f01017c6 <mem_init+0x499>
	assert(pp1 && pp1 != pp0);
f01015b4:	39 f3                	cmp    %esi,%ebx
f01015b6:	0f 84 23 02 00 00    	je     f01017df <mem_init+0x4b2>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015bc:	39 c3                	cmp    %eax,%ebx
f01015be:	0f 84 34 02 00 00    	je     f01017f8 <mem_init+0x4cb>
f01015c4:	39 c6                	cmp    %eax,%esi
f01015c6:	0f 84 2c 02 00 00    	je     f01017f8 <mem_init+0x4cb>
	assert(!page_alloc(0));
f01015cc:	83 ec 0c             	sub    $0xc,%esp
f01015cf:	6a 00                	push   $0x0
f01015d1:	e8 a4 f9 ff ff       	call   f0100f7a <page_alloc>
f01015d6:	83 c4 10             	add    $0x10,%esp
f01015d9:	85 c0                	test   %eax,%eax
f01015db:	0f 85 30 02 00 00    	jne    f0101811 <mem_init+0x4e4>
f01015e1:	89 d8                	mov    %ebx,%eax
f01015e3:	2b 05 90 9e 23 f0    	sub    0xf0239e90,%eax
f01015e9:	c1 f8 03             	sar    $0x3,%eax
f01015ec:	89 c2                	mov    %eax,%edx
f01015ee:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01015f1:	25 ff ff 0f 00       	and    $0xfffff,%eax
f01015f6:	3b 05 88 9e 23 f0    	cmp    0xf0239e88,%eax
f01015fc:	0f 83 28 02 00 00    	jae    f010182a <mem_init+0x4fd>
	memset(page2kva(pp0), 1, PGSIZE);
f0101602:	83 ec 04             	sub    $0x4,%esp
f0101605:	68 00 10 00 00       	push   $0x1000
f010160a:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f010160c:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101612:	52                   	push   %edx
f0101613:	e8 18 45 00 00       	call   f0105b30 <memset>
	page_free(pp0);
f0101618:	89 1c 24             	mov    %ebx,(%esp)
f010161b:	e8 d3 f9 ff ff       	call   f0100ff3 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101620:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101627:	e8 4e f9 ff ff       	call   f0100f7a <page_alloc>
f010162c:	83 c4 10             	add    $0x10,%esp
f010162f:	85 c0                	test   %eax,%eax
f0101631:	0f 84 05 02 00 00    	je     f010183c <mem_init+0x50f>
	assert(pp && pp0 == pp);
f0101637:	39 c3                	cmp    %eax,%ebx
f0101639:	0f 85 16 02 00 00    	jne    f0101855 <mem_init+0x528>
	return (pp - pages) << PGSHIFT;
f010163f:	2b 05 90 9e 23 f0    	sub    0xf0239e90,%eax
f0101645:	c1 f8 03             	sar    $0x3,%eax
f0101648:	89 c2                	mov    %eax,%edx
f010164a:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010164d:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101652:	3b 05 88 9e 23 f0    	cmp    0xf0239e88,%eax
f0101658:	0f 83 10 02 00 00    	jae    f010186e <mem_init+0x541>
	return (void *)(pa + KERNBASE);
f010165e:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f0101664:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f010166a:	80 38 00             	cmpb   $0x0,(%eax)
f010166d:	0f 85 0d 02 00 00    	jne    f0101880 <mem_init+0x553>
f0101673:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f0101676:	39 d0                	cmp    %edx,%eax
f0101678:	75 f0                	jne    f010166a <mem_init+0x33d>
	page_free_list = fl;
f010167a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010167d:	a3 40 92 23 f0       	mov    %eax,0xf0239240
	page_free(pp0);
f0101682:	83 ec 0c             	sub    $0xc,%esp
f0101685:	53                   	push   %ebx
f0101686:	e8 68 f9 ff ff       	call   f0100ff3 <page_free>
	page_free(pp1);
f010168b:	89 34 24             	mov    %esi,(%esp)
f010168e:	e8 60 f9 ff ff       	call   f0100ff3 <page_free>
	page_free(pp2);
f0101693:	89 3c 24             	mov    %edi,(%esp)
f0101696:	e8 58 f9 ff ff       	call   f0100ff3 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010169b:	a1 40 92 23 f0       	mov    0xf0239240,%eax
f01016a0:	83 c4 10             	add    $0x10,%esp
f01016a3:	85 c0                	test   %eax,%eax
f01016a5:	0f 84 ee 01 00 00    	je     f0101899 <mem_init+0x56c>
		--nfree;
f01016ab:	83 6d d4 01          	subl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016af:	8b 00                	mov    (%eax),%eax
f01016b1:	eb f0                	jmp    f01016a3 <mem_init+0x376>
	assert((pp0 = page_alloc(0)));
f01016b3:	68 0b 78 10 f0       	push   $0xf010780b
f01016b8:	68 43 77 10 f0       	push   $0xf0107743
f01016bd:	68 7f 03 00 00       	push   $0x37f
f01016c2:	68 1d 77 10 f0       	push   $0xf010771d
f01016c7:	e8 74 e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01016cc:	68 21 78 10 f0       	push   $0xf0107821
f01016d1:	68 43 77 10 f0       	push   $0xf0107743
f01016d6:	68 80 03 00 00       	push   $0x380
f01016db:	68 1d 77 10 f0       	push   $0xf010771d
f01016e0:	e8 5b e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01016e5:	68 37 78 10 f0       	push   $0xf0107837
f01016ea:	68 43 77 10 f0       	push   $0xf0107743
f01016ef:	68 81 03 00 00       	push   $0x381
f01016f4:	68 1d 77 10 f0       	push   $0xf010771d
f01016f9:	e8 42 e9 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f01016fe:	68 4d 78 10 f0       	push   $0xf010784d
f0101703:	68 43 77 10 f0       	push   $0xf0107743
f0101708:	68 84 03 00 00       	push   $0x384
f010170d:	68 1d 77 10 f0       	push   $0xf010771d
f0101712:	e8 29 e9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101717:	68 40 6f 10 f0       	push   $0xf0106f40
f010171c:	68 43 77 10 f0       	push   $0xf0107743
f0101721:	68 85 03 00 00       	push   $0x385
f0101726:	68 1d 77 10 f0       	push   $0xf010771d
f010172b:	e8 10 e9 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101730:	68 5f 78 10 f0       	push   $0xf010785f
f0101735:	68 43 77 10 f0       	push   $0xf0107743
f010173a:	68 86 03 00 00       	push   $0x386
f010173f:	68 1d 77 10 f0       	push   $0xf010771d
f0101744:	e8 f7 e8 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101749:	68 7c 78 10 f0       	push   $0xf010787c
f010174e:	68 43 77 10 f0       	push   $0xf0107743
f0101753:	68 87 03 00 00       	push   $0x387
f0101758:	68 1d 77 10 f0       	push   $0xf010771d
f010175d:	e8 de e8 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101762:	68 99 78 10 f0       	push   $0xf0107899
f0101767:	68 43 77 10 f0       	push   $0xf0107743
f010176c:	68 88 03 00 00       	push   $0x388
f0101771:	68 1d 77 10 f0       	push   $0xf010771d
f0101776:	e8 c5 e8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f010177b:	68 b6 78 10 f0       	push   $0xf01078b6
f0101780:	68 43 77 10 f0       	push   $0xf0107743
f0101785:	68 8f 03 00 00       	push   $0x38f
f010178a:	68 1d 77 10 f0       	push   $0xf010771d
f010178f:	e8 ac e8 ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f0101794:	68 0b 78 10 f0       	push   $0xf010780b
f0101799:	68 43 77 10 f0       	push   $0xf0107743
f010179e:	68 96 03 00 00       	push   $0x396
f01017a3:	68 1d 77 10 f0       	push   $0xf010771d
f01017a8:	e8 93 e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01017ad:	68 21 78 10 f0       	push   $0xf0107821
f01017b2:	68 43 77 10 f0       	push   $0xf0107743
f01017b7:	68 97 03 00 00       	push   $0x397
f01017bc:	68 1d 77 10 f0       	push   $0xf010771d
f01017c1:	e8 7a e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01017c6:	68 37 78 10 f0       	push   $0xf0107837
f01017cb:	68 43 77 10 f0       	push   $0xf0107743
f01017d0:	68 98 03 00 00       	push   $0x398
f01017d5:	68 1d 77 10 f0       	push   $0xf010771d
f01017da:	e8 61 e8 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f01017df:	68 4d 78 10 f0       	push   $0xf010784d
f01017e4:	68 43 77 10 f0       	push   $0xf0107743
f01017e9:	68 9a 03 00 00       	push   $0x39a
f01017ee:	68 1d 77 10 f0       	push   $0xf010771d
f01017f3:	e8 48 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017f8:	68 40 6f 10 f0       	push   $0xf0106f40
f01017fd:	68 43 77 10 f0       	push   $0xf0107743
f0101802:	68 9b 03 00 00       	push   $0x39b
f0101807:	68 1d 77 10 f0       	push   $0xf010771d
f010180c:	e8 2f e8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101811:	68 b6 78 10 f0       	push   $0xf01078b6
f0101816:	68 43 77 10 f0       	push   $0xf0107743
f010181b:	68 9c 03 00 00       	push   $0x39c
f0101820:	68 1d 77 10 f0       	push   $0xf010771d
f0101825:	e8 16 e8 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010182a:	52                   	push   %edx
f010182b:	68 e4 67 10 f0       	push   $0xf01067e4
f0101830:	6a 58                	push   $0x58
f0101832:	68 29 77 10 f0       	push   $0xf0107729
f0101837:	e8 04 e8 ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010183c:	68 c5 78 10 f0       	push   $0xf01078c5
f0101841:	68 43 77 10 f0       	push   $0xf0107743
f0101846:	68 a1 03 00 00       	push   $0x3a1
f010184b:	68 1d 77 10 f0       	push   $0xf010771d
f0101850:	e8 eb e7 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101855:	68 e3 78 10 f0       	push   $0xf01078e3
f010185a:	68 43 77 10 f0       	push   $0xf0107743
f010185f:	68 a2 03 00 00       	push   $0x3a2
f0101864:	68 1d 77 10 f0       	push   $0xf010771d
f0101869:	e8 d2 e7 ff ff       	call   f0100040 <_panic>
f010186e:	52                   	push   %edx
f010186f:	68 e4 67 10 f0       	push   $0xf01067e4
f0101874:	6a 58                	push   $0x58
f0101876:	68 29 77 10 f0       	push   $0xf0107729
f010187b:	e8 c0 e7 ff ff       	call   f0100040 <_panic>
		assert(c[i] == 0);
f0101880:	68 f3 78 10 f0       	push   $0xf01078f3
f0101885:	68 43 77 10 f0       	push   $0xf0107743
f010188a:	68 a5 03 00 00       	push   $0x3a5
f010188f:	68 1d 77 10 f0       	push   $0xf010771d
f0101894:	e8 a7 e7 ff ff       	call   f0100040 <_panic>
	assert(nfree == 0);
f0101899:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f010189d:	0f 85 46 09 00 00    	jne    f01021e9 <mem_init+0xebc>
	cprintf("check_page_alloc() succeeded!\n");
f01018a3:	83 ec 0c             	sub    $0xc,%esp
f01018a6:	68 60 6f 10 f0       	push   $0xf0106f60
f01018ab:	e8 24 21 00 00       	call   f01039d4 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01018b0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018b7:	e8 be f6 ff ff       	call   f0100f7a <page_alloc>
f01018bc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01018bf:	83 c4 10             	add    $0x10,%esp
f01018c2:	85 c0                	test   %eax,%eax
f01018c4:	0f 84 38 09 00 00    	je     f0102202 <mem_init+0xed5>
	assert((pp1 = page_alloc(0)));
f01018ca:	83 ec 0c             	sub    $0xc,%esp
f01018cd:	6a 00                	push   $0x0
f01018cf:	e8 a6 f6 ff ff       	call   f0100f7a <page_alloc>
f01018d4:	89 c7                	mov    %eax,%edi
f01018d6:	83 c4 10             	add    $0x10,%esp
f01018d9:	85 c0                	test   %eax,%eax
f01018db:	0f 84 3a 09 00 00    	je     f010221b <mem_init+0xeee>
	assert((pp2 = page_alloc(0)));
f01018e1:	83 ec 0c             	sub    $0xc,%esp
f01018e4:	6a 00                	push   $0x0
f01018e6:	e8 8f f6 ff ff       	call   f0100f7a <page_alloc>
f01018eb:	89 c3                	mov    %eax,%ebx
f01018ed:	83 c4 10             	add    $0x10,%esp
f01018f0:	85 c0                	test   %eax,%eax
f01018f2:	0f 84 3c 09 00 00    	je     f0102234 <mem_init+0xf07>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018f8:	39 7d d4             	cmp    %edi,-0x2c(%ebp)
f01018fb:	0f 84 4c 09 00 00    	je     f010224d <mem_init+0xf20>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101901:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101904:	0f 84 5c 09 00 00    	je     f0102266 <mem_init+0xf39>
f010190a:	39 c7                	cmp    %eax,%edi
f010190c:	0f 84 54 09 00 00    	je     f0102266 <mem_init+0xf39>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101912:	a1 40 92 23 f0       	mov    0xf0239240,%eax
f0101917:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f010191a:	c7 05 40 92 23 f0 00 	movl   $0x0,0xf0239240
f0101921:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101924:	83 ec 0c             	sub    $0xc,%esp
f0101927:	6a 00                	push   $0x0
f0101929:	e8 4c f6 ff ff       	call   f0100f7a <page_alloc>
f010192e:	83 c4 10             	add    $0x10,%esp
f0101931:	85 c0                	test   %eax,%eax
f0101933:	0f 85 46 09 00 00    	jne    f010227f <mem_init+0xf52>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101939:	83 ec 04             	sub    $0x4,%esp
f010193c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010193f:	50                   	push   %eax
f0101940:	6a 00                	push   $0x0
f0101942:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0101948:	e8 ef f7 ff ff       	call   f010113c <page_lookup>
f010194d:	83 c4 10             	add    $0x10,%esp
f0101950:	85 c0                	test   %eax,%eax
f0101952:	0f 85 40 09 00 00    	jne    f0102298 <mem_init+0xf6b>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101958:	6a 02                	push   $0x2
f010195a:	6a 00                	push   $0x0
f010195c:	57                   	push   %edi
f010195d:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0101963:	e8 c7 f8 ff ff       	call   f010122f <page_insert>
f0101968:	83 c4 10             	add    $0x10,%esp
f010196b:	85 c0                	test   %eax,%eax
f010196d:	0f 89 3e 09 00 00    	jns    f01022b1 <mem_init+0xf84>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101973:	83 ec 0c             	sub    $0xc,%esp
f0101976:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101979:	e8 75 f6 ff ff       	call   f0100ff3 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010197e:	6a 02                	push   $0x2
f0101980:	6a 00                	push   $0x0
f0101982:	57                   	push   %edi
f0101983:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0101989:	e8 a1 f8 ff ff       	call   f010122f <page_insert>
f010198e:	83 c4 20             	add    $0x20,%esp
f0101991:	85 c0                	test   %eax,%eax
f0101993:	0f 85 31 09 00 00    	jne    f01022ca <mem_init+0xf9d>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101999:	8b 35 8c 9e 23 f0    	mov    0xf0239e8c,%esi
	return (pp - pages) << PGSHIFT;
f010199f:	8b 0d 90 9e 23 f0    	mov    0xf0239e90,%ecx
f01019a5:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01019a8:	8b 16                	mov    (%esi),%edx
f01019aa:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01019b0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019b3:	29 c8                	sub    %ecx,%eax
f01019b5:	c1 f8 03             	sar    $0x3,%eax
f01019b8:	c1 e0 0c             	shl    $0xc,%eax
f01019bb:	39 c2                	cmp    %eax,%edx
f01019bd:	0f 85 20 09 00 00    	jne    f01022e3 <mem_init+0xfb6>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01019c3:	ba 00 00 00 00       	mov    $0x0,%edx
f01019c8:	89 f0                	mov    %esi,%eax
f01019ca:	e8 8b f1 ff ff       	call   f0100b5a <check_va2pa>
f01019cf:	89 c2                	mov    %eax,%edx
f01019d1:	89 f8                	mov    %edi,%eax
f01019d3:	2b 45 d0             	sub    -0x30(%ebp),%eax
f01019d6:	c1 f8 03             	sar    $0x3,%eax
f01019d9:	c1 e0 0c             	shl    $0xc,%eax
f01019dc:	39 c2                	cmp    %eax,%edx
f01019de:	0f 85 18 09 00 00    	jne    f01022fc <mem_init+0xfcf>
	assert(pp1->pp_ref == 1);
f01019e4:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01019e9:	0f 85 26 09 00 00    	jne    f0102315 <mem_init+0xfe8>
	assert(pp0->pp_ref == 1);
f01019ef:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019f2:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01019f7:	0f 85 31 09 00 00    	jne    f010232e <mem_init+0x1001>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01019fd:	6a 02                	push   $0x2
f01019ff:	68 00 10 00 00       	push   $0x1000
f0101a04:	53                   	push   %ebx
f0101a05:	56                   	push   %esi
f0101a06:	e8 24 f8 ff ff       	call   f010122f <page_insert>
f0101a0b:	83 c4 10             	add    $0x10,%esp
f0101a0e:	85 c0                	test   %eax,%eax
f0101a10:	0f 85 31 09 00 00    	jne    f0102347 <mem_init+0x101a>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a16:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a1b:	a1 8c 9e 23 f0       	mov    0xf0239e8c,%eax
f0101a20:	e8 35 f1 ff ff       	call   f0100b5a <check_va2pa>
f0101a25:	89 c2                	mov    %eax,%edx
f0101a27:	89 d8                	mov    %ebx,%eax
f0101a29:	2b 05 90 9e 23 f0    	sub    0xf0239e90,%eax
f0101a2f:	c1 f8 03             	sar    $0x3,%eax
f0101a32:	c1 e0 0c             	shl    $0xc,%eax
f0101a35:	39 c2                	cmp    %eax,%edx
f0101a37:	0f 85 23 09 00 00    	jne    f0102360 <mem_init+0x1033>
	assert(pp2->pp_ref == 1);
f0101a3d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a42:	0f 85 31 09 00 00    	jne    f0102379 <mem_init+0x104c>

	// should be no free memory
	assert(!page_alloc(0));
f0101a48:	83 ec 0c             	sub    $0xc,%esp
f0101a4b:	6a 00                	push   $0x0
f0101a4d:	e8 28 f5 ff ff       	call   f0100f7a <page_alloc>
f0101a52:	83 c4 10             	add    $0x10,%esp
f0101a55:	85 c0                	test   %eax,%eax
f0101a57:	0f 85 35 09 00 00    	jne    f0102392 <mem_init+0x1065>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a5d:	6a 02                	push   $0x2
f0101a5f:	68 00 10 00 00       	push   $0x1000
f0101a64:	53                   	push   %ebx
f0101a65:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0101a6b:	e8 bf f7 ff ff       	call   f010122f <page_insert>
f0101a70:	83 c4 10             	add    $0x10,%esp
f0101a73:	85 c0                	test   %eax,%eax
f0101a75:	0f 85 30 09 00 00    	jne    f01023ab <mem_init+0x107e>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a7b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a80:	a1 8c 9e 23 f0       	mov    0xf0239e8c,%eax
f0101a85:	e8 d0 f0 ff ff       	call   f0100b5a <check_va2pa>
f0101a8a:	89 c2                	mov    %eax,%edx
f0101a8c:	89 d8                	mov    %ebx,%eax
f0101a8e:	2b 05 90 9e 23 f0    	sub    0xf0239e90,%eax
f0101a94:	c1 f8 03             	sar    $0x3,%eax
f0101a97:	c1 e0 0c             	shl    $0xc,%eax
f0101a9a:	39 c2                	cmp    %eax,%edx
f0101a9c:	0f 85 22 09 00 00    	jne    f01023c4 <mem_init+0x1097>
	assert(pp2->pp_ref == 1);
f0101aa2:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101aa7:	0f 85 30 09 00 00    	jne    f01023dd <mem_init+0x10b0>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101aad:	83 ec 0c             	sub    $0xc,%esp
f0101ab0:	6a 00                	push   $0x0
f0101ab2:	e8 c3 f4 ff ff       	call   f0100f7a <page_alloc>
f0101ab7:	83 c4 10             	add    $0x10,%esp
f0101aba:	85 c0                	test   %eax,%eax
f0101abc:	0f 85 34 09 00 00    	jne    f01023f6 <mem_init+0x10c9>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101ac2:	8b 0d 8c 9e 23 f0    	mov    0xf0239e8c,%ecx
f0101ac8:	8b 01                	mov    (%ecx),%eax
f0101aca:	89 c2                	mov    %eax,%edx
f0101acc:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101ad2:	c1 e8 0c             	shr    $0xc,%eax
f0101ad5:	3b 05 88 9e 23 f0    	cmp    0xf0239e88,%eax
f0101adb:	0f 83 2e 09 00 00    	jae    f010240f <mem_init+0x10e2>
	return (void *)(pa + KERNBASE);
f0101ae1:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101ae7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101aea:	83 ec 04             	sub    $0x4,%esp
f0101aed:	6a 00                	push   $0x0
f0101aef:	68 00 10 00 00       	push   $0x1000
f0101af4:	51                   	push   %ecx
f0101af5:	e8 65 f5 ff ff       	call   f010105f <pgdir_walk>
f0101afa:	89 c2                	mov    %eax,%edx
f0101afc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101aff:	83 c0 04             	add    $0x4,%eax
f0101b02:	83 c4 10             	add    $0x10,%esp
f0101b05:	39 d0                	cmp    %edx,%eax
f0101b07:	0f 85 17 09 00 00    	jne    f0102424 <mem_init+0x10f7>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101b0d:	6a 06                	push   $0x6
f0101b0f:	68 00 10 00 00       	push   $0x1000
f0101b14:	53                   	push   %ebx
f0101b15:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0101b1b:	e8 0f f7 ff ff       	call   f010122f <page_insert>
f0101b20:	83 c4 10             	add    $0x10,%esp
f0101b23:	85 c0                	test   %eax,%eax
f0101b25:	0f 85 12 09 00 00    	jne    f010243d <mem_init+0x1110>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b2b:	8b 35 8c 9e 23 f0    	mov    0xf0239e8c,%esi
f0101b31:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b36:	89 f0                	mov    %esi,%eax
f0101b38:	e8 1d f0 ff ff       	call   f0100b5a <check_va2pa>
f0101b3d:	89 c2                	mov    %eax,%edx
	return (pp - pages) << PGSHIFT;
f0101b3f:	89 d8                	mov    %ebx,%eax
f0101b41:	2b 05 90 9e 23 f0    	sub    0xf0239e90,%eax
f0101b47:	c1 f8 03             	sar    $0x3,%eax
f0101b4a:	c1 e0 0c             	shl    $0xc,%eax
f0101b4d:	39 c2                	cmp    %eax,%edx
f0101b4f:	0f 85 01 09 00 00    	jne    f0102456 <mem_init+0x1129>
	assert(pp2->pp_ref == 1);
f0101b55:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b5a:	0f 85 0f 09 00 00    	jne    f010246f <mem_init+0x1142>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101b60:	83 ec 04             	sub    $0x4,%esp
f0101b63:	6a 00                	push   $0x0
f0101b65:	68 00 10 00 00       	push   $0x1000
f0101b6a:	56                   	push   %esi
f0101b6b:	e8 ef f4 ff ff       	call   f010105f <pgdir_walk>
f0101b70:	83 c4 10             	add    $0x10,%esp
f0101b73:	f6 00 04             	testb  $0x4,(%eax)
f0101b76:	0f 84 0c 09 00 00    	je     f0102488 <mem_init+0x115b>
	assert(kern_pgdir[0] & PTE_U);
f0101b7c:	a1 8c 9e 23 f0       	mov    0xf0239e8c,%eax
f0101b81:	f6 00 04             	testb  $0x4,(%eax)
f0101b84:	0f 84 17 09 00 00    	je     f01024a1 <mem_init+0x1174>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b8a:	6a 02                	push   $0x2
f0101b8c:	68 00 10 00 00       	push   $0x1000
f0101b91:	53                   	push   %ebx
f0101b92:	50                   	push   %eax
f0101b93:	e8 97 f6 ff ff       	call   f010122f <page_insert>
f0101b98:	83 c4 10             	add    $0x10,%esp
f0101b9b:	85 c0                	test   %eax,%eax
f0101b9d:	0f 85 17 09 00 00    	jne    f01024ba <mem_init+0x118d>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ba3:	83 ec 04             	sub    $0x4,%esp
f0101ba6:	6a 00                	push   $0x0
f0101ba8:	68 00 10 00 00       	push   $0x1000
f0101bad:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0101bb3:	e8 a7 f4 ff ff       	call   f010105f <pgdir_walk>
f0101bb8:	83 c4 10             	add    $0x10,%esp
f0101bbb:	f6 00 02             	testb  $0x2,(%eax)
f0101bbe:	0f 84 0f 09 00 00    	je     f01024d3 <mem_init+0x11a6>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bc4:	83 ec 04             	sub    $0x4,%esp
f0101bc7:	6a 00                	push   $0x0
f0101bc9:	68 00 10 00 00       	push   $0x1000
f0101bce:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0101bd4:	e8 86 f4 ff ff       	call   f010105f <pgdir_walk>
f0101bd9:	83 c4 10             	add    $0x10,%esp
f0101bdc:	f6 00 04             	testb  $0x4,(%eax)
f0101bdf:	0f 85 07 09 00 00    	jne    f01024ec <mem_init+0x11bf>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101be5:	6a 02                	push   $0x2
f0101be7:	68 00 00 40 00       	push   $0x400000
f0101bec:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101bef:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0101bf5:	e8 35 f6 ff ff       	call   f010122f <page_insert>
f0101bfa:	83 c4 10             	add    $0x10,%esp
f0101bfd:	85 c0                	test   %eax,%eax
f0101bff:	0f 89 00 09 00 00    	jns    f0102505 <mem_init+0x11d8>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c05:	6a 02                	push   $0x2
f0101c07:	68 00 10 00 00       	push   $0x1000
f0101c0c:	57                   	push   %edi
f0101c0d:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0101c13:	e8 17 f6 ff ff       	call   f010122f <page_insert>
f0101c18:	83 c4 10             	add    $0x10,%esp
f0101c1b:	85 c0                	test   %eax,%eax
f0101c1d:	0f 85 fb 08 00 00    	jne    f010251e <mem_init+0x11f1>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c23:	83 ec 04             	sub    $0x4,%esp
f0101c26:	6a 00                	push   $0x0
f0101c28:	68 00 10 00 00       	push   $0x1000
f0101c2d:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0101c33:	e8 27 f4 ff ff       	call   f010105f <pgdir_walk>
f0101c38:	83 c4 10             	add    $0x10,%esp
f0101c3b:	f6 00 04             	testb  $0x4,(%eax)
f0101c3e:	0f 85 f3 08 00 00    	jne    f0102537 <mem_init+0x120a>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c44:	a1 8c 9e 23 f0       	mov    0xf0239e8c,%eax
f0101c49:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101c4c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c51:	e8 04 ef ff ff       	call   f0100b5a <check_va2pa>
f0101c56:	89 fe                	mov    %edi,%esi
f0101c58:	2b 35 90 9e 23 f0    	sub    0xf0239e90,%esi
f0101c5e:	c1 fe 03             	sar    $0x3,%esi
f0101c61:	c1 e6 0c             	shl    $0xc,%esi
f0101c64:	39 f0                	cmp    %esi,%eax
f0101c66:	0f 85 e4 08 00 00    	jne    f0102550 <mem_init+0x1223>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c6c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c71:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c74:	e8 e1 ee ff ff       	call   f0100b5a <check_va2pa>
f0101c79:	39 c6                	cmp    %eax,%esi
f0101c7b:	0f 85 e8 08 00 00    	jne    f0102569 <mem_init+0x123c>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c81:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101c86:	0f 85 f6 08 00 00    	jne    f0102582 <mem_init+0x1255>
	assert(pp2->pp_ref == 0);
f0101c8c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101c91:	0f 85 04 09 00 00    	jne    f010259b <mem_init+0x126e>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c97:	83 ec 0c             	sub    $0xc,%esp
f0101c9a:	6a 00                	push   $0x0
f0101c9c:	e8 d9 f2 ff ff       	call   f0100f7a <page_alloc>
f0101ca1:	83 c4 10             	add    $0x10,%esp
f0101ca4:	85 c0                	test   %eax,%eax
f0101ca6:	0f 84 08 09 00 00    	je     f01025b4 <mem_init+0x1287>
f0101cac:	39 c3                	cmp    %eax,%ebx
f0101cae:	0f 85 00 09 00 00    	jne    f01025b4 <mem_init+0x1287>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101cb4:	83 ec 08             	sub    $0x8,%esp
f0101cb7:	6a 00                	push   $0x0
f0101cb9:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0101cbf:	e8 1a f5 ff ff       	call   f01011de <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cc4:	8b 35 8c 9e 23 f0    	mov    0xf0239e8c,%esi
f0101cca:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ccf:	89 f0                	mov    %esi,%eax
f0101cd1:	e8 84 ee ff ff       	call   f0100b5a <check_va2pa>
f0101cd6:	83 c4 10             	add    $0x10,%esp
f0101cd9:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101cdc:	0f 85 eb 08 00 00    	jne    f01025cd <mem_init+0x12a0>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ce2:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ce7:	89 f0                	mov    %esi,%eax
f0101ce9:	e8 6c ee ff ff       	call   f0100b5a <check_va2pa>
f0101cee:	89 c2                	mov    %eax,%edx
f0101cf0:	89 f8                	mov    %edi,%eax
f0101cf2:	2b 05 90 9e 23 f0    	sub    0xf0239e90,%eax
f0101cf8:	c1 f8 03             	sar    $0x3,%eax
f0101cfb:	c1 e0 0c             	shl    $0xc,%eax
f0101cfe:	39 c2                	cmp    %eax,%edx
f0101d00:	0f 85 e0 08 00 00    	jne    f01025e6 <mem_init+0x12b9>
	assert(pp1->pp_ref == 1);
f0101d06:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101d0b:	0f 85 ee 08 00 00    	jne    f01025ff <mem_init+0x12d2>
	assert(pp2->pp_ref == 0);
f0101d11:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d16:	0f 85 fc 08 00 00    	jne    f0102618 <mem_init+0x12eb>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d1c:	6a 00                	push   $0x0
f0101d1e:	68 00 10 00 00       	push   $0x1000
f0101d23:	57                   	push   %edi
f0101d24:	56                   	push   %esi
f0101d25:	e8 05 f5 ff ff       	call   f010122f <page_insert>
f0101d2a:	83 c4 10             	add    $0x10,%esp
f0101d2d:	85 c0                	test   %eax,%eax
f0101d2f:	0f 85 fc 08 00 00    	jne    f0102631 <mem_init+0x1304>
	assert(pp1->pp_ref);
f0101d35:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101d3a:	0f 84 0a 09 00 00    	je     f010264a <mem_init+0x131d>
	assert(pp1->pp_link == NULL);
f0101d40:	83 3f 00             	cmpl   $0x0,(%edi)
f0101d43:	0f 85 1a 09 00 00    	jne    f0102663 <mem_init+0x1336>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101d49:	83 ec 08             	sub    $0x8,%esp
f0101d4c:	68 00 10 00 00       	push   $0x1000
f0101d51:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0101d57:	e8 82 f4 ff ff       	call   f01011de <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d5c:	8b 35 8c 9e 23 f0    	mov    0xf0239e8c,%esi
f0101d62:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d67:	89 f0                	mov    %esi,%eax
f0101d69:	e8 ec ed ff ff       	call   f0100b5a <check_va2pa>
f0101d6e:	83 c4 10             	add    $0x10,%esp
f0101d71:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d74:	0f 85 02 09 00 00    	jne    f010267c <mem_init+0x134f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101d7a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d7f:	89 f0                	mov    %esi,%eax
f0101d81:	e8 d4 ed ff ff       	call   f0100b5a <check_va2pa>
f0101d86:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d89:	0f 85 06 09 00 00    	jne    f0102695 <mem_init+0x1368>
	assert(pp1->pp_ref == 0);
f0101d8f:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101d94:	0f 85 14 09 00 00    	jne    f01026ae <mem_init+0x1381>
	assert(pp2->pp_ref == 0);
f0101d9a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d9f:	0f 85 22 09 00 00    	jne    f01026c7 <mem_init+0x139a>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101da5:	83 ec 0c             	sub    $0xc,%esp
f0101da8:	6a 00                	push   $0x0
f0101daa:	e8 cb f1 ff ff       	call   f0100f7a <page_alloc>
f0101daf:	83 c4 10             	add    $0x10,%esp
f0101db2:	39 c7                	cmp    %eax,%edi
f0101db4:	0f 85 26 09 00 00    	jne    f01026e0 <mem_init+0x13b3>
f0101dba:	85 c0                	test   %eax,%eax
f0101dbc:	0f 84 1e 09 00 00    	je     f01026e0 <mem_init+0x13b3>

	// should be no free memory
	assert(!page_alloc(0));
f0101dc2:	83 ec 0c             	sub    $0xc,%esp
f0101dc5:	6a 00                	push   $0x0
f0101dc7:	e8 ae f1 ff ff       	call   f0100f7a <page_alloc>
f0101dcc:	83 c4 10             	add    $0x10,%esp
f0101dcf:	85 c0                	test   %eax,%eax
f0101dd1:	0f 85 22 09 00 00    	jne    f01026f9 <mem_init+0x13cc>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101dd7:	8b 0d 8c 9e 23 f0    	mov    0xf0239e8c,%ecx
f0101ddd:	8b 11                	mov    (%ecx),%edx
f0101ddf:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101de5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101de8:	2b 05 90 9e 23 f0    	sub    0xf0239e90,%eax
f0101dee:	c1 f8 03             	sar    $0x3,%eax
f0101df1:	c1 e0 0c             	shl    $0xc,%eax
f0101df4:	39 c2                	cmp    %eax,%edx
f0101df6:	0f 85 16 09 00 00    	jne    f0102712 <mem_init+0x13e5>
	kern_pgdir[0] = 0;
f0101dfc:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101e02:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e05:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e0a:	0f 85 1b 09 00 00    	jne    f010272b <mem_init+0x13fe>
	pp0->pp_ref = 0;
f0101e10:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e13:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101e19:	83 ec 0c             	sub    $0xc,%esp
f0101e1c:	50                   	push   %eax
f0101e1d:	e8 d1 f1 ff ff       	call   f0100ff3 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101e22:	83 c4 0c             	add    $0xc,%esp
f0101e25:	6a 01                	push   $0x1
f0101e27:	68 00 10 40 00       	push   $0x401000
f0101e2c:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0101e32:	e8 28 f2 ff ff       	call   f010105f <pgdir_walk>
f0101e37:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101e3a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101e3d:	8b 0d 8c 9e 23 f0    	mov    0xf0239e8c,%ecx
f0101e43:	8b 41 04             	mov    0x4(%ecx),%eax
f0101e46:	89 c6                	mov    %eax,%esi
f0101e48:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	if (PGNUM(pa) >= npages)
f0101e4e:	8b 15 88 9e 23 f0    	mov    0xf0239e88,%edx
f0101e54:	c1 e8 0c             	shr    $0xc,%eax
f0101e57:	83 c4 10             	add    $0x10,%esp
f0101e5a:	39 d0                	cmp    %edx,%eax
f0101e5c:	0f 83 e2 08 00 00    	jae    f0102744 <mem_init+0x1417>
	assert(ptep == ptep1 + PTX(va));
f0101e62:	81 ee fc ff ff 0f    	sub    $0xffffffc,%esi
f0101e68:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f0101e6b:	0f 85 e8 08 00 00    	jne    f0102759 <mem_init+0x142c>
	kern_pgdir[PDX(va)] = 0;
f0101e71:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0101e78:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e7b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0101e81:	2b 05 90 9e 23 f0    	sub    0xf0239e90,%eax
f0101e87:	c1 f8 03             	sar    $0x3,%eax
f0101e8a:	89 c1                	mov    %eax,%ecx
f0101e8c:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f0101e8f:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101e94:	39 c2                	cmp    %eax,%edx
f0101e96:	0f 86 d6 08 00 00    	jbe    f0102772 <mem_init+0x1445>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101e9c:	83 ec 04             	sub    $0x4,%esp
f0101e9f:	68 00 10 00 00       	push   $0x1000
f0101ea4:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0101ea9:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0101eaf:	51                   	push   %ecx
f0101eb0:	e8 7b 3c 00 00       	call   f0105b30 <memset>
	page_free(pp0);
f0101eb5:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101eb8:	89 34 24             	mov    %esi,(%esp)
f0101ebb:	e8 33 f1 ff ff       	call   f0100ff3 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101ec0:	83 c4 0c             	add    $0xc,%esp
f0101ec3:	6a 01                	push   $0x1
f0101ec5:	6a 00                	push   $0x0
f0101ec7:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0101ecd:	e8 8d f1 ff ff       	call   f010105f <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0101ed2:	89 f0                	mov    %esi,%eax
f0101ed4:	2b 05 90 9e 23 f0    	sub    0xf0239e90,%eax
f0101eda:	c1 f8 03             	sar    $0x3,%eax
f0101edd:	89 c2                	mov    %eax,%edx
f0101edf:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101ee2:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101ee7:	83 c4 10             	add    $0x10,%esp
f0101eea:	3b 05 88 9e 23 f0    	cmp    0xf0239e88,%eax
f0101ef0:	0f 83 8e 08 00 00    	jae    f0102784 <mem_init+0x1457>
	return (void *)(pa + KERNBASE);
f0101ef6:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101efc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101eff:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101f05:	f6 00 01             	testb  $0x1,(%eax)
f0101f08:	0f 85 88 08 00 00    	jne    f0102796 <mem_init+0x1469>
f0101f0e:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0101f11:	39 d0                	cmp    %edx,%eax
f0101f13:	75 f0                	jne    f0101f05 <mem_init+0xbd8>
	kern_pgdir[0] = 0;
f0101f15:	a1 8c 9e 23 f0       	mov    0xf0239e8c,%eax
f0101f1a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101f20:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f23:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0101f29:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101f2c:	89 0d 40 92 23 f0    	mov    %ecx,0xf0239240

	// free the pages we took
	page_free(pp0);
f0101f32:	83 ec 0c             	sub    $0xc,%esp
f0101f35:	50                   	push   %eax
f0101f36:	e8 b8 f0 ff ff       	call   f0100ff3 <page_free>
	page_free(pp1);
f0101f3b:	89 3c 24             	mov    %edi,(%esp)
f0101f3e:	e8 b0 f0 ff ff       	call   f0100ff3 <page_free>
	page_free(pp2);
f0101f43:	89 1c 24             	mov    %ebx,(%esp)
f0101f46:	e8 a8 f0 ff ff       	call   f0100ff3 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0101f4b:	83 c4 08             	add    $0x8,%esp
f0101f4e:	68 01 10 00 00       	push   $0x1001
f0101f53:	6a 00                	push   $0x0
f0101f55:	e8 57 f3 ff ff       	call   f01012b1 <mmio_map_region>
f0101f5a:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0101f5c:	83 c4 08             	add    $0x8,%esp
f0101f5f:	68 00 10 00 00       	push   $0x1000
f0101f64:	6a 00                	push   $0x0
f0101f66:	e8 46 f3 ff ff       	call   f01012b1 <mmio_map_region>
f0101f6b:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8192 < MMIOLIM);
f0101f6d:	8d 83 00 20 00 00    	lea    0x2000(%ebx),%eax
f0101f73:	83 c4 10             	add    $0x10,%esp
f0101f76:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0101f7c:	0f 86 2d 08 00 00    	jbe    f01027af <mem_init+0x1482>
f0101f82:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0101f87:	0f 87 22 08 00 00    	ja     f01027af <mem_init+0x1482>
	assert(mm2 >= MMIOBASE && mm2 + 8192 < MMIOLIM);
f0101f8d:	8d 96 00 20 00 00    	lea    0x2000(%esi),%edx
f0101f93:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0101f99:	0f 87 29 08 00 00    	ja     f01027c8 <mem_init+0x149b>
f0101f9f:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0101fa5:	0f 86 1d 08 00 00    	jbe    f01027c8 <mem_init+0x149b>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0101fab:	89 da                	mov    %ebx,%edx
f0101fad:	09 f2                	or     %esi,%edx
f0101faf:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0101fb5:	0f 85 26 08 00 00    	jne    f01027e1 <mem_init+0x14b4>
	// check that they don't overlap
	assert(mm1 + 8192 <= mm2);
f0101fbb:	39 c6                	cmp    %eax,%esi
f0101fbd:	0f 82 37 08 00 00    	jb     f01027fa <mem_init+0x14cd>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0101fc3:	8b 3d 8c 9e 23 f0    	mov    0xf0239e8c,%edi
f0101fc9:	89 da                	mov    %ebx,%edx
f0101fcb:	89 f8                	mov    %edi,%eax
f0101fcd:	e8 88 eb ff ff       	call   f0100b5a <check_va2pa>
f0101fd2:	85 c0                	test   %eax,%eax
f0101fd4:	0f 85 39 08 00 00    	jne    f0102813 <mem_init+0x14e6>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0101fda:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0101fe0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101fe3:	89 c2                	mov    %eax,%edx
f0101fe5:	89 f8                	mov    %edi,%eax
f0101fe7:	e8 6e eb ff ff       	call   f0100b5a <check_va2pa>
f0101fec:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0101ff1:	0f 85 35 08 00 00    	jne    f010282c <mem_init+0x14ff>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0101ff7:	89 f2                	mov    %esi,%edx
f0101ff9:	89 f8                	mov    %edi,%eax
f0101ffb:	e8 5a eb ff ff       	call   f0100b5a <check_va2pa>
f0102000:	85 c0                	test   %eax,%eax
f0102002:	0f 85 3d 08 00 00    	jne    f0102845 <mem_init+0x1518>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102008:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f010200e:	89 f8                	mov    %edi,%eax
f0102010:	e8 45 eb ff ff       	call   f0100b5a <check_va2pa>
f0102015:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102018:	0f 85 40 08 00 00    	jne    f010285e <mem_init+0x1531>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f010201e:	83 ec 04             	sub    $0x4,%esp
f0102021:	6a 00                	push   $0x0
f0102023:	53                   	push   %ebx
f0102024:	57                   	push   %edi
f0102025:	e8 35 f0 ff ff       	call   f010105f <pgdir_walk>
f010202a:	83 c4 10             	add    $0x10,%esp
f010202d:	f6 00 1a             	testb  $0x1a,(%eax)
f0102030:	0f 84 41 08 00 00    	je     f0102877 <mem_init+0x154a>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102036:	83 ec 04             	sub    $0x4,%esp
f0102039:	6a 00                	push   $0x0
f010203b:	53                   	push   %ebx
f010203c:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0102042:	e8 18 f0 ff ff       	call   f010105f <pgdir_walk>
f0102047:	8b 00                	mov    (%eax),%eax
f0102049:	83 c4 10             	add    $0x10,%esp
f010204c:	83 e0 04             	and    $0x4,%eax
f010204f:	89 c7                	mov    %eax,%edi
f0102051:	0f 85 39 08 00 00    	jne    f0102890 <mem_init+0x1563>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f0102057:	83 ec 04             	sub    $0x4,%esp
f010205a:	6a 00                	push   $0x0
f010205c:	53                   	push   %ebx
f010205d:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0102063:	e8 f7 ef ff ff       	call   f010105f <pgdir_walk>
f0102068:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f010206e:	83 c4 0c             	add    $0xc,%esp
f0102071:	6a 00                	push   $0x0
f0102073:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102076:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f010207c:	e8 de ef ff ff       	call   f010105f <pgdir_walk>
f0102081:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102087:	83 c4 0c             	add    $0xc,%esp
f010208a:	6a 00                	push   $0x0
f010208c:	56                   	push   %esi
f010208d:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0102093:	e8 c7 ef ff ff       	call   f010105f <pgdir_walk>
f0102098:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f010209e:	c7 04 24 e6 79 10 f0 	movl   $0xf01079e6,(%esp)
f01020a5:	e8 2a 19 00 00       	call   f01039d4 <cprintf>
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U);
f01020aa:	a1 90 9e 23 f0       	mov    0xf0239e90,%eax
	if ((uint32_t)kva < KERNBASE)
f01020af:	83 c4 10             	add    $0x10,%esp
f01020b2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020b7:	0f 86 ec 07 00 00    	jbe    f01028a9 <mem_init+0x157c>
f01020bd:	83 ec 08             	sub    $0x8,%esp
f01020c0:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f01020c2:	05 00 00 00 10       	add    $0x10000000,%eax
f01020c7:	50                   	push   %eax
f01020c8:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020cd:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01020d2:	a1 8c 9e 23 f0       	mov    0xf0239e8c,%eax
f01020d7:	e8 14 f0 ff ff       	call   f01010f0 <boot_map_region>
	boot_map_region(kern_pgdir,UENVS,PTSIZE,PADDR(envs),PTE_U);
f01020dc:	a1 48 92 23 f0       	mov    0xf0239248,%eax
	if ((uint32_t)kva < KERNBASE)
f01020e1:	83 c4 10             	add    $0x10,%esp
f01020e4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020e9:	0f 86 cf 07 00 00    	jbe    f01028be <mem_init+0x1591>
f01020ef:	83 ec 08             	sub    $0x8,%esp
f01020f2:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f01020f4:	05 00 00 00 10       	add    $0x10000000,%eax
f01020f9:	50                   	push   %eax
f01020fa:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020ff:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102104:	a1 8c 9e 23 f0       	mov    0xf0239e8c,%eax
f0102109:	e8 e2 ef ff ff       	call   f01010f0 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f010210e:	83 c4 10             	add    $0x10,%esp
f0102111:	b8 00 90 11 f0       	mov    $0xf0119000,%eax
f0102116:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010211b:	0f 86 b2 07 00 00    	jbe    f01028d3 <mem_init+0x15a6>
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f0102121:	83 ec 08             	sub    $0x8,%esp
f0102124:	6a 02                	push   $0x2
f0102126:	68 00 90 11 00       	push   $0x119000
f010212b:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102130:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102135:	a1 8c 9e 23 f0       	mov    0xf0239e8c,%eax
f010213a:	e8 b1 ef ff ff       	call   f01010f0 <boot_map_region>
f010213f:	c7 45 d0 00 b0 23 f0 	movl   $0xf023b000,-0x30(%ebp)
f0102146:	83 c4 10             	add    $0x10,%esp
f0102149:	bb 00 b0 23 f0       	mov    $0xf023b000,%ebx
f010214e:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102153:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102159:	0f 86 89 07 00 00    	jbe    f01028e8 <mem_init+0x15bb>
		boot_map_region(kern_pgdir,kstacktop_i,KSTKSIZE,pa,PTE_W|PTE_P);
f010215f:	83 ec 08             	sub    $0x8,%esp
f0102162:	6a 03                	push   $0x3
f0102164:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f010216a:	50                   	push   %eax
f010216b:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102170:	89 f2                	mov    %esi,%edx
f0102172:	a1 8c 9e 23 f0       	mov    0xf0239e8c,%eax
f0102177:	e8 74 ef ff ff       	call   f01010f0 <boot_map_region>
f010217c:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102182:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	for(int i = 0;i<NCPU;i++)
f0102188:	83 c4 10             	add    $0x10,%esp
f010218b:	81 fb 00 b0 27 f0    	cmp    $0xf027b000,%ebx
f0102191:	75 c0                	jne    f0102153 <mem_init+0xe26>
	boot_map_region(kern_pgdir,KERNBASE,0xFFFFFFFF-KERNBASE,0,PTE_W);
f0102193:	83 ec 08             	sub    $0x8,%esp
f0102196:	6a 02                	push   $0x2
f0102198:	6a 00                	push   $0x0
f010219a:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010219f:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021a4:	a1 8c 9e 23 f0       	mov    0xf0239e8c,%eax
f01021a9:	e8 42 ef ff ff       	call   f01010f0 <boot_map_region>
	pgdir = kern_pgdir;
f01021ae:	a1 8c 9e 23 f0       	mov    0xf0239e8c,%eax
f01021b3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021b6:	a1 88 9e 23 f0       	mov    0xf0239e88,%eax
f01021bb:	89 45 c0             	mov    %eax,-0x40(%ebp)
f01021be:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021c5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021ca:	89 45 cc             	mov    %eax,-0x34(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021cd:	8b 35 90 9e 23 f0    	mov    0xf0239e90,%esi
f01021d3:	89 75 c8             	mov    %esi,-0x38(%ebp)
	return (physaddr_t)kva - KERNBASE;
f01021d6:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01021dc:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f01021df:	83 c4 10             	add    $0x10,%esp
f01021e2:	89 fb                	mov    %edi,%ebx
f01021e4:	e9 2f 07 00 00       	jmp    f0102918 <mem_init+0x15eb>
	assert(nfree == 0);
f01021e9:	68 fd 78 10 f0       	push   $0xf01078fd
f01021ee:	68 43 77 10 f0       	push   $0xf0107743
f01021f3:	68 b2 03 00 00       	push   $0x3b2
f01021f8:	68 1d 77 10 f0       	push   $0xf010771d
f01021fd:	e8 3e de ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f0102202:	68 0b 78 10 f0       	push   $0xf010780b
f0102207:	68 43 77 10 f0       	push   $0xf0107743
f010220c:	68 18 04 00 00       	push   $0x418
f0102211:	68 1d 77 10 f0       	push   $0xf010771d
f0102216:	e8 25 de ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010221b:	68 21 78 10 f0       	push   $0xf0107821
f0102220:	68 43 77 10 f0       	push   $0xf0107743
f0102225:	68 19 04 00 00       	push   $0x419
f010222a:	68 1d 77 10 f0       	push   $0xf010771d
f010222f:	e8 0c de ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102234:	68 37 78 10 f0       	push   $0xf0107837
f0102239:	68 43 77 10 f0       	push   $0xf0107743
f010223e:	68 1a 04 00 00       	push   $0x41a
f0102243:	68 1d 77 10 f0       	push   $0xf010771d
f0102248:	e8 f3 dd ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f010224d:	68 4d 78 10 f0       	push   $0xf010784d
f0102252:	68 43 77 10 f0       	push   $0xf0107743
f0102257:	68 1d 04 00 00       	push   $0x41d
f010225c:	68 1d 77 10 f0       	push   $0xf010771d
f0102261:	e8 da dd ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0102266:	68 40 6f 10 f0       	push   $0xf0106f40
f010226b:	68 43 77 10 f0       	push   $0xf0107743
f0102270:	68 1e 04 00 00       	push   $0x41e
f0102275:	68 1d 77 10 f0       	push   $0xf010771d
f010227a:	e8 c1 dd ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f010227f:	68 b6 78 10 f0       	push   $0xf01078b6
f0102284:	68 43 77 10 f0       	push   $0xf0107743
f0102289:	68 25 04 00 00       	push   $0x425
f010228e:	68 1d 77 10 f0       	push   $0xf010771d
f0102293:	e8 a8 dd ff ff       	call   f0100040 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102298:	68 80 6f 10 f0       	push   $0xf0106f80
f010229d:	68 43 77 10 f0       	push   $0xf0107743
f01022a2:	68 28 04 00 00       	push   $0x428
f01022a7:	68 1d 77 10 f0       	push   $0xf010771d
f01022ac:	e8 8f dd ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01022b1:	68 b8 6f 10 f0       	push   $0xf0106fb8
f01022b6:	68 43 77 10 f0       	push   $0xf0107743
f01022bb:	68 2b 04 00 00       	push   $0x42b
f01022c0:	68 1d 77 10 f0       	push   $0xf010771d
f01022c5:	e8 76 dd ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01022ca:	68 e8 6f 10 f0       	push   $0xf0106fe8
f01022cf:	68 43 77 10 f0       	push   $0xf0107743
f01022d4:	68 2f 04 00 00       	push   $0x42f
f01022d9:	68 1d 77 10 f0       	push   $0xf010771d
f01022de:	e8 5d dd ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01022e3:	68 18 70 10 f0       	push   $0xf0107018
f01022e8:	68 43 77 10 f0       	push   $0xf0107743
f01022ed:	68 30 04 00 00       	push   $0x430
f01022f2:	68 1d 77 10 f0       	push   $0xf010771d
f01022f7:	e8 44 dd ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01022fc:	68 40 70 10 f0       	push   $0xf0107040
f0102301:	68 43 77 10 f0       	push   $0xf0107743
f0102306:	68 31 04 00 00       	push   $0x431
f010230b:	68 1d 77 10 f0       	push   $0xf010771d
f0102310:	e8 2b dd ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102315:	68 08 79 10 f0       	push   $0xf0107908
f010231a:	68 43 77 10 f0       	push   $0xf0107743
f010231f:	68 32 04 00 00       	push   $0x432
f0102324:	68 1d 77 10 f0       	push   $0xf010771d
f0102329:	e8 12 dd ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f010232e:	68 19 79 10 f0       	push   $0xf0107919
f0102333:	68 43 77 10 f0       	push   $0xf0107743
f0102338:	68 33 04 00 00       	push   $0x433
f010233d:	68 1d 77 10 f0       	push   $0xf010771d
f0102342:	e8 f9 dc ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102347:	68 70 70 10 f0       	push   $0xf0107070
f010234c:	68 43 77 10 f0       	push   $0xf0107743
f0102351:	68 36 04 00 00       	push   $0x436
f0102356:	68 1d 77 10 f0       	push   $0xf010771d
f010235b:	e8 e0 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102360:	68 ac 70 10 f0       	push   $0xf01070ac
f0102365:	68 43 77 10 f0       	push   $0xf0107743
f010236a:	68 37 04 00 00       	push   $0x437
f010236f:	68 1d 77 10 f0       	push   $0xf010771d
f0102374:	e8 c7 dc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102379:	68 2a 79 10 f0       	push   $0xf010792a
f010237e:	68 43 77 10 f0       	push   $0xf0107743
f0102383:	68 38 04 00 00       	push   $0x438
f0102388:	68 1d 77 10 f0       	push   $0xf010771d
f010238d:	e8 ae dc ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0102392:	68 b6 78 10 f0       	push   $0xf01078b6
f0102397:	68 43 77 10 f0       	push   $0xf0107743
f010239c:	68 3b 04 00 00       	push   $0x43b
f01023a1:	68 1d 77 10 f0       	push   $0xf010771d
f01023a6:	e8 95 dc ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023ab:	68 70 70 10 f0       	push   $0xf0107070
f01023b0:	68 43 77 10 f0       	push   $0xf0107743
f01023b5:	68 3e 04 00 00       	push   $0x43e
f01023ba:	68 1d 77 10 f0       	push   $0xf010771d
f01023bf:	e8 7c dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01023c4:	68 ac 70 10 f0       	push   $0xf01070ac
f01023c9:	68 43 77 10 f0       	push   $0xf0107743
f01023ce:	68 3f 04 00 00       	push   $0x43f
f01023d3:	68 1d 77 10 f0       	push   $0xf010771d
f01023d8:	e8 63 dc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01023dd:	68 2a 79 10 f0       	push   $0xf010792a
f01023e2:	68 43 77 10 f0       	push   $0xf0107743
f01023e7:	68 40 04 00 00       	push   $0x440
f01023ec:	68 1d 77 10 f0       	push   $0xf010771d
f01023f1:	e8 4a dc ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01023f6:	68 b6 78 10 f0       	push   $0xf01078b6
f01023fb:	68 43 77 10 f0       	push   $0xf0107743
f0102400:	68 44 04 00 00       	push   $0x444
f0102405:	68 1d 77 10 f0       	push   $0xf010771d
f010240a:	e8 31 dc ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010240f:	52                   	push   %edx
f0102410:	68 e4 67 10 f0       	push   $0xf01067e4
f0102415:	68 47 04 00 00       	push   $0x447
f010241a:	68 1d 77 10 f0       	push   $0xf010771d
f010241f:	e8 1c dc ff ff       	call   f0100040 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102424:	68 dc 70 10 f0       	push   $0xf01070dc
f0102429:	68 43 77 10 f0       	push   $0xf0107743
f010242e:	68 48 04 00 00       	push   $0x448
f0102433:	68 1d 77 10 f0       	push   $0xf010771d
f0102438:	e8 03 dc ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010243d:	68 1c 71 10 f0       	push   $0xf010711c
f0102442:	68 43 77 10 f0       	push   $0xf0107743
f0102447:	68 4b 04 00 00       	push   $0x44b
f010244c:	68 1d 77 10 f0       	push   $0xf010771d
f0102451:	e8 ea db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102456:	68 ac 70 10 f0       	push   $0xf01070ac
f010245b:	68 43 77 10 f0       	push   $0xf0107743
f0102460:	68 4c 04 00 00       	push   $0x44c
f0102465:	68 1d 77 10 f0       	push   $0xf010771d
f010246a:	e8 d1 db ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f010246f:	68 2a 79 10 f0       	push   $0xf010792a
f0102474:	68 43 77 10 f0       	push   $0xf0107743
f0102479:	68 4d 04 00 00       	push   $0x44d
f010247e:	68 1d 77 10 f0       	push   $0xf010771d
f0102483:	e8 b8 db ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102488:	68 5c 71 10 f0       	push   $0xf010715c
f010248d:	68 43 77 10 f0       	push   $0xf0107743
f0102492:	68 4e 04 00 00       	push   $0x44e
f0102497:	68 1d 77 10 f0       	push   $0xf010771d
f010249c:	e8 9f db ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01024a1:	68 3b 79 10 f0       	push   $0xf010793b
f01024a6:	68 43 77 10 f0       	push   $0xf0107743
f01024ab:	68 4f 04 00 00       	push   $0x44f
f01024b0:	68 1d 77 10 f0       	push   $0xf010771d
f01024b5:	e8 86 db ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01024ba:	68 70 70 10 f0       	push   $0xf0107070
f01024bf:	68 43 77 10 f0       	push   $0xf0107743
f01024c4:	68 52 04 00 00       	push   $0x452
f01024c9:	68 1d 77 10 f0       	push   $0xf010771d
f01024ce:	e8 6d db ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01024d3:	68 90 71 10 f0       	push   $0xf0107190
f01024d8:	68 43 77 10 f0       	push   $0xf0107743
f01024dd:	68 53 04 00 00       	push   $0x453
f01024e2:	68 1d 77 10 f0       	push   $0xf010771d
f01024e7:	e8 54 db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01024ec:	68 c4 71 10 f0       	push   $0xf01071c4
f01024f1:	68 43 77 10 f0       	push   $0xf0107743
f01024f6:	68 54 04 00 00       	push   $0x454
f01024fb:	68 1d 77 10 f0       	push   $0xf010771d
f0102500:	e8 3b db ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102505:	68 fc 71 10 f0       	push   $0xf01071fc
f010250a:	68 43 77 10 f0       	push   $0xf0107743
f010250f:	68 57 04 00 00       	push   $0x457
f0102514:	68 1d 77 10 f0       	push   $0xf010771d
f0102519:	e8 22 db ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010251e:	68 34 72 10 f0       	push   $0xf0107234
f0102523:	68 43 77 10 f0       	push   $0xf0107743
f0102528:	68 5a 04 00 00       	push   $0x45a
f010252d:	68 1d 77 10 f0       	push   $0xf010771d
f0102532:	e8 09 db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102537:	68 c4 71 10 f0       	push   $0xf01071c4
f010253c:	68 43 77 10 f0       	push   $0xf0107743
f0102541:	68 5b 04 00 00       	push   $0x45b
f0102546:	68 1d 77 10 f0       	push   $0xf010771d
f010254b:	e8 f0 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102550:	68 70 72 10 f0       	push   $0xf0107270
f0102555:	68 43 77 10 f0       	push   $0xf0107743
f010255a:	68 5e 04 00 00       	push   $0x45e
f010255f:	68 1d 77 10 f0       	push   $0xf010771d
f0102564:	e8 d7 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102569:	68 9c 72 10 f0       	push   $0xf010729c
f010256e:	68 43 77 10 f0       	push   $0xf0107743
f0102573:	68 5f 04 00 00       	push   $0x45f
f0102578:	68 1d 77 10 f0       	push   $0xf010771d
f010257d:	e8 be da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 2);
f0102582:	68 51 79 10 f0       	push   $0xf0107951
f0102587:	68 43 77 10 f0       	push   $0xf0107743
f010258c:	68 61 04 00 00       	push   $0x461
f0102591:	68 1d 77 10 f0       	push   $0xf010771d
f0102596:	e8 a5 da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010259b:	68 62 79 10 f0       	push   $0xf0107962
f01025a0:	68 43 77 10 f0       	push   $0xf0107743
f01025a5:	68 62 04 00 00       	push   $0x462
f01025aa:	68 1d 77 10 f0       	push   $0xf010771d
f01025af:	e8 8c da ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f01025b4:	68 cc 72 10 f0       	push   $0xf01072cc
f01025b9:	68 43 77 10 f0       	push   $0xf0107743
f01025be:	68 65 04 00 00       	push   $0x465
f01025c3:	68 1d 77 10 f0       	push   $0xf010771d
f01025c8:	e8 73 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01025cd:	68 f0 72 10 f0       	push   $0xf01072f0
f01025d2:	68 43 77 10 f0       	push   $0xf0107743
f01025d7:	68 69 04 00 00       	push   $0x469
f01025dc:	68 1d 77 10 f0       	push   $0xf010771d
f01025e1:	e8 5a da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01025e6:	68 9c 72 10 f0       	push   $0xf010729c
f01025eb:	68 43 77 10 f0       	push   $0xf0107743
f01025f0:	68 6a 04 00 00       	push   $0x46a
f01025f5:	68 1d 77 10 f0       	push   $0xf010771d
f01025fa:	e8 41 da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01025ff:	68 08 79 10 f0       	push   $0xf0107908
f0102604:	68 43 77 10 f0       	push   $0xf0107743
f0102609:	68 6b 04 00 00       	push   $0x46b
f010260e:	68 1d 77 10 f0       	push   $0xf010771d
f0102613:	e8 28 da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102618:	68 62 79 10 f0       	push   $0xf0107962
f010261d:	68 43 77 10 f0       	push   $0xf0107743
f0102622:	68 6c 04 00 00       	push   $0x46c
f0102627:	68 1d 77 10 f0       	push   $0xf010771d
f010262c:	e8 0f da ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102631:	68 14 73 10 f0       	push   $0xf0107314
f0102636:	68 43 77 10 f0       	push   $0xf0107743
f010263b:	68 6f 04 00 00       	push   $0x46f
f0102640:	68 1d 77 10 f0       	push   $0xf010771d
f0102645:	e8 f6 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f010264a:	68 73 79 10 f0       	push   $0xf0107973
f010264f:	68 43 77 10 f0       	push   $0xf0107743
f0102654:	68 70 04 00 00       	push   $0x470
f0102659:	68 1d 77 10 f0       	push   $0xf010771d
f010265e:	e8 dd d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0102663:	68 7f 79 10 f0       	push   $0xf010797f
f0102668:	68 43 77 10 f0       	push   $0xf0107743
f010266d:	68 71 04 00 00       	push   $0x471
f0102672:	68 1d 77 10 f0       	push   $0xf010771d
f0102677:	e8 c4 d9 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010267c:	68 f0 72 10 f0       	push   $0xf01072f0
f0102681:	68 43 77 10 f0       	push   $0xf0107743
f0102686:	68 75 04 00 00       	push   $0x475
f010268b:	68 1d 77 10 f0       	push   $0xf010771d
f0102690:	e8 ab d9 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102695:	68 4c 73 10 f0       	push   $0xf010734c
f010269a:	68 43 77 10 f0       	push   $0xf0107743
f010269f:	68 76 04 00 00       	push   $0x476
f01026a4:	68 1d 77 10 f0       	push   $0xf010771d
f01026a9:	e8 92 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01026ae:	68 94 79 10 f0       	push   $0xf0107994
f01026b3:	68 43 77 10 f0       	push   $0xf0107743
f01026b8:	68 77 04 00 00       	push   $0x477
f01026bd:	68 1d 77 10 f0       	push   $0xf010771d
f01026c2:	e8 79 d9 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01026c7:	68 62 79 10 f0       	push   $0xf0107962
f01026cc:	68 43 77 10 f0       	push   $0xf0107743
f01026d1:	68 78 04 00 00       	push   $0x478
f01026d6:	68 1d 77 10 f0       	push   $0xf010771d
f01026db:	e8 60 d9 ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f01026e0:	68 74 73 10 f0       	push   $0xf0107374
f01026e5:	68 43 77 10 f0       	push   $0xf0107743
f01026ea:	68 7b 04 00 00       	push   $0x47b
f01026ef:	68 1d 77 10 f0       	push   $0xf010771d
f01026f4:	e8 47 d9 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01026f9:	68 b6 78 10 f0       	push   $0xf01078b6
f01026fe:	68 43 77 10 f0       	push   $0xf0107743
f0102703:	68 7e 04 00 00       	push   $0x47e
f0102708:	68 1d 77 10 f0       	push   $0xf010771d
f010270d:	e8 2e d9 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102712:	68 18 70 10 f0       	push   $0xf0107018
f0102717:	68 43 77 10 f0       	push   $0xf0107743
f010271c:	68 81 04 00 00       	push   $0x481
f0102721:	68 1d 77 10 f0       	push   $0xf010771d
f0102726:	e8 15 d9 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f010272b:	68 19 79 10 f0       	push   $0xf0107919
f0102730:	68 43 77 10 f0       	push   $0xf0107743
f0102735:	68 83 04 00 00       	push   $0x483
f010273a:	68 1d 77 10 f0       	push   $0xf010771d
f010273f:	e8 fc d8 ff ff       	call   f0100040 <_panic>
f0102744:	56                   	push   %esi
f0102745:	68 e4 67 10 f0       	push   $0xf01067e4
f010274a:	68 8a 04 00 00       	push   $0x48a
f010274f:	68 1d 77 10 f0       	push   $0xf010771d
f0102754:	e8 e7 d8 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102759:	68 a5 79 10 f0       	push   $0xf01079a5
f010275e:	68 43 77 10 f0       	push   $0xf0107743
f0102763:	68 8b 04 00 00       	push   $0x48b
f0102768:	68 1d 77 10 f0       	push   $0xf010771d
f010276d:	e8 ce d8 ff ff       	call   f0100040 <_panic>
f0102772:	51                   	push   %ecx
f0102773:	68 e4 67 10 f0       	push   $0xf01067e4
f0102778:	6a 58                	push   $0x58
f010277a:	68 29 77 10 f0       	push   $0xf0107729
f010277f:	e8 bc d8 ff ff       	call   f0100040 <_panic>
f0102784:	52                   	push   %edx
f0102785:	68 e4 67 10 f0       	push   $0xf01067e4
f010278a:	6a 58                	push   $0x58
f010278c:	68 29 77 10 f0       	push   $0xf0107729
f0102791:	e8 aa d8 ff ff       	call   f0100040 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102796:	68 bd 79 10 f0       	push   $0xf01079bd
f010279b:	68 43 77 10 f0       	push   $0xf0107743
f01027a0:	68 95 04 00 00       	push   $0x495
f01027a5:	68 1d 77 10 f0       	push   $0xf010771d
f01027aa:	e8 91 d8 ff ff       	call   f0100040 <_panic>
	assert(mm1 >= MMIOBASE && mm1 + 8192 < MMIOLIM);
f01027af:	68 98 73 10 f0       	push   $0xf0107398
f01027b4:	68 43 77 10 f0       	push   $0xf0107743
f01027b9:	68 a5 04 00 00       	push   $0x4a5
f01027be:	68 1d 77 10 f0       	push   $0xf010771d
f01027c3:	e8 78 d8 ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8192 < MMIOLIM);
f01027c8:	68 c0 73 10 f0       	push   $0xf01073c0
f01027cd:	68 43 77 10 f0       	push   $0xf0107743
f01027d2:	68 a6 04 00 00       	push   $0x4a6
f01027d7:	68 1d 77 10 f0       	push   $0xf010771d
f01027dc:	e8 5f d8 ff ff       	call   f0100040 <_panic>
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f01027e1:	68 e8 73 10 f0       	push   $0xf01073e8
f01027e6:	68 43 77 10 f0       	push   $0xf0107743
f01027eb:	68 a8 04 00 00       	push   $0x4a8
f01027f0:	68 1d 77 10 f0       	push   $0xf010771d
f01027f5:	e8 46 d8 ff ff       	call   f0100040 <_panic>
	assert(mm1 + 8192 <= mm2);
f01027fa:	68 d4 79 10 f0       	push   $0xf01079d4
f01027ff:	68 43 77 10 f0       	push   $0xf0107743
f0102804:	68 aa 04 00 00       	push   $0x4aa
f0102809:	68 1d 77 10 f0       	push   $0xf010771d
f010280e:	e8 2d d8 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102813:	68 10 74 10 f0       	push   $0xf0107410
f0102818:	68 43 77 10 f0       	push   $0xf0107743
f010281d:	68 ac 04 00 00       	push   $0x4ac
f0102822:	68 1d 77 10 f0       	push   $0xf010771d
f0102827:	e8 14 d8 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f010282c:	68 34 74 10 f0       	push   $0xf0107434
f0102831:	68 43 77 10 f0       	push   $0xf0107743
f0102836:	68 ad 04 00 00       	push   $0x4ad
f010283b:	68 1d 77 10 f0       	push   $0xf010771d
f0102840:	e8 fb d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102845:	68 64 74 10 f0       	push   $0xf0107464
f010284a:	68 43 77 10 f0       	push   $0xf0107743
f010284f:	68 ae 04 00 00       	push   $0x4ae
f0102854:	68 1d 77 10 f0       	push   $0xf010771d
f0102859:	e8 e2 d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f010285e:	68 88 74 10 f0       	push   $0xf0107488
f0102863:	68 43 77 10 f0       	push   $0xf0107743
f0102868:	68 af 04 00 00       	push   $0x4af
f010286d:	68 1d 77 10 f0       	push   $0xf010771d
f0102872:	e8 c9 d7 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102877:	68 b4 74 10 f0       	push   $0xf01074b4
f010287c:	68 43 77 10 f0       	push   $0xf0107743
f0102881:	68 b1 04 00 00       	push   $0x4b1
f0102886:	68 1d 77 10 f0       	push   $0xf010771d
f010288b:	e8 b0 d7 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102890:	68 f8 74 10 f0       	push   $0xf01074f8
f0102895:	68 43 77 10 f0       	push   $0xf0107743
f010289a:	68 b2 04 00 00       	push   $0x4b2
f010289f:	68 1d 77 10 f0       	push   $0xf010771d
f01028a4:	e8 97 d7 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028a9:	50                   	push   %eax
f01028aa:	68 08 68 10 f0       	push   $0xf0106808
f01028af:	68 cb 00 00 00       	push   $0xcb
f01028b4:	68 1d 77 10 f0       	push   $0xf010771d
f01028b9:	e8 82 d7 ff ff       	call   f0100040 <_panic>
f01028be:	50                   	push   %eax
f01028bf:	68 08 68 10 f0       	push   $0xf0106808
f01028c4:	68 d3 00 00 00       	push   $0xd3
f01028c9:	68 1d 77 10 f0       	push   $0xf010771d
f01028ce:	e8 6d d7 ff ff       	call   f0100040 <_panic>
f01028d3:	50                   	push   %eax
f01028d4:	68 08 68 10 f0       	push   $0xf0106808
f01028d9:	68 df 00 00 00       	push   $0xdf
f01028de:	68 1d 77 10 f0       	push   $0xf010771d
f01028e3:	e8 58 d7 ff ff       	call   f0100040 <_panic>
f01028e8:	53                   	push   %ebx
f01028e9:	68 08 68 10 f0       	push   $0xf0106808
f01028ee:	68 1f 01 00 00       	push   $0x11f
f01028f3:	68 1d 77 10 f0       	push   $0xf010771d
f01028f8:	e8 43 d7 ff ff       	call   f0100040 <_panic>
f01028fd:	56                   	push   %esi
f01028fe:	68 08 68 10 f0       	push   $0xf0106808
f0102903:	68 ca 03 00 00       	push   $0x3ca
f0102908:	68 1d 77 10 f0       	push   $0xf010771d
f010290d:	e8 2e d7 ff ff       	call   f0100040 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f0102912:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102918:	39 5d cc             	cmp    %ebx,-0x34(%ebp)
f010291b:	76 3a                	jbe    f0102957 <mem_init+0x162a>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010291d:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102923:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102926:	e8 2f e2 ff ff       	call   f0100b5a <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f010292b:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f0102932:	76 c9                	jbe    f01028fd <mem_init+0x15d0>
f0102934:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102937:	8d 14 0b             	lea    (%ebx,%ecx,1),%edx
f010293a:	39 d0                	cmp    %edx,%eax
f010293c:	74 d4                	je     f0102912 <mem_init+0x15e5>
f010293e:	68 2c 75 10 f0       	push   $0xf010752c
f0102943:	68 43 77 10 f0       	push   $0xf0107743
f0102948:	68 ca 03 00 00       	push   $0x3ca
f010294d:	68 1d 77 10 f0       	push   $0xf010771d
f0102952:	e8 e9 d6 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102957:	a1 48 92 23 f0       	mov    0xf0239248,%eax
f010295c:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010295f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102962:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102967:	8d b0 00 00 40 21    	lea    0x21400000(%eax),%esi
f010296d:	89 da                	mov    %ebx,%edx
f010296f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102972:	e8 e3 e1 ff ff       	call   f0100b5a <check_va2pa>
f0102977:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f010297e:	76 3b                	jbe    f01029bb <mem_init+0x168e>
f0102980:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f0102983:	39 d0                	cmp    %edx,%eax
f0102985:	75 4b                	jne    f01029d2 <mem_init+0x16a5>
f0102987:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
f010298d:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f0102993:	75 d8                	jne    f010296d <mem_init+0x1640>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102995:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0102998:	c1 e6 0c             	shl    $0xc,%esi
f010299b:	89 fb                	mov    %edi,%ebx
f010299d:	39 f3                	cmp    %esi,%ebx
f010299f:	73 63                	jae    f0102a04 <mem_init+0x16d7>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01029a1:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01029a7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029aa:	e8 ab e1 ff ff       	call   f0100b5a <check_va2pa>
f01029af:	39 c3                	cmp    %eax,%ebx
f01029b1:	75 38                	jne    f01029eb <mem_init+0x16be>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01029b3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01029b9:	eb e2                	jmp    f010299d <mem_init+0x1670>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029bb:	ff 75 c8             	pushl  -0x38(%ebp)
f01029be:	68 08 68 10 f0       	push   $0xf0106808
f01029c3:	68 cf 03 00 00       	push   $0x3cf
f01029c8:	68 1d 77 10 f0       	push   $0xf010771d
f01029cd:	e8 6e d6 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01029d2:	68 60 75 10 f0       	push   $0xf0107560
f01029d7:	68 43 77 10 f0       	push   $0xf0107743
f01029dc:	68 cf 03 00 00       	push   $0x3cf
f01029e1:	68 1d 77 10 f0       	push   $0xf010771d
f01029e6:	e8 55 d6 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01029eb:	68 94 75 10 f0       	push   $0xf0107594
f01029f0:	68 43 77 10 f0       	push   $0xf0107743
f01029f5:	68 d3 03 00 00       	push   $0x3d3
f01029fa:	68 1d 77 10 f0       	push   $0xf010771d
f01029ff:	e8 3c d6 ff ff       	call   f0100040 <_panic>
f0102a04:	c7 45 cc 00 b0 24 00 	movl   $0x24b000,-0x34(%ebp)
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a0b:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
f0102a10:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0102a13:	8d bb 00 80 ff ff    	lea    -0x8000(%ebx),%edi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102a19:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102a1c:	89 45 bc             	mov    %eax,-0x44(%ebp)
f0102a1f:	89 de                	mov    %ebx,%esi
f0102a21:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102a24:	05 00 80 ff 0f       	add    $0xfff8000,%eax
f0102a29:	89 45 c8             	mov    %eax,-0x38(%ebp)
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102a2c:	8d 83 00 80 00 00    	lea    0x8000(%ebx),%eax
f0102a32:	89 45 c4             	mov    %eax,-0x3c(%ebp)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102a35:	89 f2                	mov    %esi,%edx
f0102a37:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a3a:	e8 1b e1 ff ff       	call   f0100b5a <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102a3f:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102a46:	76 58                	jbe    f0102aa0 <mem_init+0x1773>
f0102a48:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102a4b:	8d 14 31             	lea    (%ecx,%esi,1),%edx
f0102a4e:	39 d0                	cmp    %edx,%eax
f0102a50:	75 65                	jne    f0102ab7 <mem_init+0x178a>
f0102a52:	81 c6 00 10 00 00    	add    $0x1000,%esi
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102a58:	3b 75 c4             	cmp    -0x3c(%ebp),%esi
f0102a5b:	75 d8                	jne    f0102a35 <mem_init+0x1708>
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102a5d:	89 fa                	mov    %edi,%edx
f0102a5f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a62:	e8 f3 e0 ff ff       	call   f0100b5a <check_va2pa>
f0102a67:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a6a:	75 64                	jne    f0102ad0 <mem_init+0x17a3>
f0102a6c:	81 c7 00 10 00 00    	add    $0x1000,%edi
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102a72:	39 df                	cmp    %ebx,%edi
f0102a74:	75 e7                	jne    f0102a5d <mem_init+0x1730>
f0102a76:	81 eb 00 00 01 00    	sub    $0x10000,%ebx
f0102a7c:	81 45 d0 00 80 00 00 	addl   $0x8000,-0x30(%ebp)
f0102a83:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102a86:	81 45 cc 00 80 01 00 	addl   $0x18000,-0x34(%ebp)
	for (n = 0; n < NCPU; n++) {
f0102a8d:	3d 00 b0 27 f0       	cmp    $0xf027b000,%eax
f0102a92:	0f 85 7b ff ff ff    	jne    f0102a13 <mem_init+0x16e6>
f0102a98:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0102a9b:	e9 84 00 00 00       	jmp    f0102b24 <mem_init+0x17f7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102aa0:	ff 75 bc             	pushl  -0x44(%ebp)
f0102aa3:	68 08 68 10 f0       	push   $0xf0106808
f0102aa8:	68 db 03 00 00       	push   $0x3db
f0102aad:	68 1d 77 10 f0       	push   $0xf010771d
f0102ab2:	e8 89 d5 ff ff       	call   f0100040 <_panic>
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102ab7:	68 bc 75 10 f0       	push   $0xf01075bc
f0102abc:	68 43 77 10 f0       	push   $0xf0107743
f0102ac1:	68 da 03 00 00       	push   $0x3da
f0102ac6:	68 1d 77 10 f0       	push   $0xf010771d
f0102acb:	e8 70 d5 ff ff       	call   f0100040 <_panic>
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102ad0:	68 04 76 10 f0       	push   $0xf0107604
f0102ad5:	68 43 77 10 f0       	push   $0xf0107743
f0102ada:	68 dd 03 00 00       	push   $0x3dd
f0102adf:	68 1d 77 10 f0       	push   $0xf010771d
f0102ae4:	e8 57 d5 ff ff       	call   f0100040 <_panic>
			assert(pgdir[i] & PTE_P);
f0102ae9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102aec:	f6 04 b8 01          	testb  $0x1,(%eax,%edi,4)
f0102af0:	75 4e                	jne    f0102b40 <mem_init+0x1813>
f0102af2:	68 ff 79 10 f0       	push   $0xf01079ff
f0102af7:	68 43 77 10 f0       	push   $0xf0107743
f0102afc:	68 e8 03 00 00       	push   $0x3e8
f0102b01:	68 1d 77 10 f0       	push   $0xf010771d
f0102b06:	e8 35 d5 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_P);
f0102b0b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b0e:	8b 04 b8             	mov    (%eax,%edi,4),%eax
f0102b11:	a8 01                	test   $0x1,%al
f0102b13:	74 30                	je     f0102b45 <mem_init+0x1818>
				assert(pgdir[i] & PTE_W);
f0102b15:	a8 02                	test   $0x2,%al
f0102b17:	74 45                	je     f0102b5e <mem_init+0x1831>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b19:	83 c7 01             	add    $0x1,%edi
f0102b1c:	81 ff 00 04 00 00    	cmp    $0x400,%edi
f0102b22:	74 6c                	je     f0102b90 <mem_init+0x1863>
		switch (i) {
f0102b24:	8d 87 45 fc ff ff    	lea    -0x3bb(%edi),%eax
f0102b2a:	83 f8 04             	cmp    $0x4,%eax
f0102b2d:	76 ba                	jbe    f0102ae9 <mem_init+0x17bc>
			if (i >= PDX(KERNBASE)) {
f0102b2f:	81 ff bf 03 00 00    	cmp    $0x3bf,%edi
f0102b35:	77 d4                	ja     f0102b0b <mem_init+0x17de>
				assert(pgdir[i] == 0);
f0102b37:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b3a:	83 3c b8 00          	cmpl   $0x0,(%eax,%edi,4)
f0102b3e:	75 37                	jne    f0102b77 <mem_init+0x184a>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b40:	83 c7 01             	add    $0x1,%edi
f0102b43:	eb df                	jmp    f0102b24 <mem_init+0x17f7>
				assert(pgdir[i] & PTE_P);
f0102b45:	68 ff 79 10 f0       	push   $0xf01079ff
f0102b4a:	68 43 77 10 f0       	push   $0xf0107743
f0102b4f:	68 ec 03 00 00       	push   $0x3ec
f0102b54:	68 1d 77 10 f0       	push   $0xf010771d
f0102b59:	e8 e2 d4 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102b5e:	68 10 7a 10 f0       	push   $0xf0107a10
f0102b63:	68 43 77 10 f0       	push   $0xf0107743
f0102b68:	68 ed 03 00 00       	push   $0x3ed
f0102b6d:	68 1d 77 10 f0       	push   $0xf010771d
f0102b72:	e8 c9 d4 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] == 0);
f0102b77:	68 21 7a 10 f0       	push   $0xf0107a21
f0102b7c:	68 43 77 10 f0       	push   $0xf0107743
f0102b81:	68 ef 03 00 00       	push   $0x3ef
f0102b86:	68 1d 77 10 f0       	push   $0xf010771d
f0102b8b:	e8 b0 d4 ff ff       	call   f0100040 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102b90:	83 ec 0c             	sub    $0xc,%esp
f0102b93:	68 28 76 10 f0       	push   $0xf0107628
f0102b98:	e8 37 0e 00 00       	call   f01039d4 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102b9d:	a1 8c 9e 23 f0       	mov    0xf0239e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0102ba2:	83 c4 10             	add    $0x10,%esp
f0102ba5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102baa:	0f 86 03 02 00 00    	jbe    f0102db3 <mem_init+0x1a86>
	return (physaddr_t)kva - KERNBASE;
f0102bb0:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102bb5:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102bb8:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bbd:	e8 fb df ff ff       	call   f0100bbd <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102bc2:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102bc5:	83 e0 f3             	and    $0xfffffff3,%eax
f0102bc8:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102bcd:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102bd0:	83 ec 0c             	sub    $0xc,%esp
f0102bd3:	6a 00                	push   $0x0
f0102bd5:	e8 a0 e3 ff ff       	call   f0100f7a <page_alloc>
f0102bda:	89 c6                	mov    %eax,%esi
f0102bdc:	83 c4 10             	add    $0x10,%esp
f0102bdf:	85 c0                	test   %eax,%eax
f0102be1:	0f 84 e1 01 00 00    	je     f0102dc8 <mem_init+0x1a9b>
	assert((pp1 = page_alloc(0)));
f0102be7:	83 ec 0c             	sub    $0xc,%esp
f0102bea:	6a 00                	push   $0x0
f0102bec:	e8 89 e3 ff ff       	call   f0100f7a <page_alloc>
f0102bf1:	89 c7                	mov    %eax,%edi
f0102bf3:	83 c4 10             	add    $0x10,%esp
f0102bf6:	85 c0                	test   %eax,%eax
f0102bf8:	0f 84 e3 01 00 00    	je     f0102de1 <mem_init+0x1ab4>
	assert((pp2 = page_alloc(0)));
f0102bfe:	83 ec 0c             	sub    $0xc,%esp
f0102c01:	6a 00                	push   $0x0
f0102c03:	e8 72 e3 ff ff       	call   f0100f7a <page_alloc>
f0102c08:	89 c3                	mov    %eax,%ebx
f0102c0a:	83 c4 10             	add    $0x10,%esp
f0102c0d:	85 c0                	test   %eax,%eax
f0102c0f:	0f 84 e5 01 00 00    	je     f0102dfa <mem_init+0x1acd>
	page_free(pp0);
f0102c15:	83 ec 0c             	sub    $0xc,%esp
f0102c18:	56                   	push   %esi
f0102c19:	e8 d5 e3 ff ff       	call   f0100ff3 <page_free>
	return (pp - pages) << PGSHIFT;
f0102c1e:	89 f8                	mov    %edi,%eax
f0102c20:	2b 05 90 9e 23 f0    	sub    0xf0239e90,%eax
f0102c26:	c1 f8 03             	sar    $0x3,%eax
f0102c29:	89 c2                	mov    %eax,%edx
f0102c2b:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102c2e:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102c33:	83 c4 10             	add    $0x10,%esp
f0102c36:	3b 05 88 9e 23 f0    	cmp    0xf0239e88,%eax
f0102c3c:	0f 83 d1 01 00 00    	jae    f0102e13 <mem_init+0x1ae6>
	memset(page2kva(pp1), 1, PGSIZE);
f0102c42:	83 ec 04             	sub    $0x4,%esp
f0102c45:	68 00 10 00 00       	push   $0x1000
f0102c4a:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102c4c:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102c52:	52                   	push   %edx
f0102c53:	e8 d8 2e 00 00       	call   f0105b30 <memset>
	return (pp - pages) << PGSHIFT;
f0102c58:	89 d8                	mov    %ebx,%eax
f0102c5a:	2b 05 90 9e 23 f0    	sub    0xf0239e90,%eax
f0102c60:	c1 f8 03             	sar    $0x3,%eax
f0102c63:	89 c2                	mov    %eax,%edx
f0102c65:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102c68:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102c6d:	83 c4 10             	add    $0x10,%esp
f0102c70:	3b 05 88 9e 23 f0    	cmp    0xf0239e88,%eax
f0102c76:	0f 83 a9 01 00 00    	jae    f0102e25 <mem_init+0x1af8>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c7c:	83 ec 04             	sub    $0x4,%esp
f0102c7f:	68 00 10 00 00       	push   $0x1000
f0102c84:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102c86:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102c8c:	52                   	push   %edx
f0102c8d:	e8 9e 2e 00 00       	call   f0105b30 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c92:	6a 02                	push   $0x2
f0102c94:	68 00 10 00 00       	push   $0x1000
f0102c99:	57                   	push   %edi
f0102c9a:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0102ca0:	e8 8a e5 ff ff       	call   f010122f <page_insert>
	assert(pp1->pp_ref == 1);
f0102ca5:	83 c4 20             	add    $0x20,%esp
f0102ca8:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102cad:	0f 85 84 01 00 00    	jne    f0102e37 <mem_init+0x1b0a>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102cb3:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102cba:	01 01 01 
f0102cbd:	0f 85 8d 01 00 00    	jne    f0102e50 <mem_init+0x1b23>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102cc3:	6a 02                	push   $0x2
f0102cc5:	68 00 10 00 00       	push   $0x1000
f0102cca:	53                   	push   %ebx
f0102ccb:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0102cd1:	e8 59 e5 ff ff       	call   f010122f <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102cd6:	83 c4 10             	add    $0x10,%esp
f0102cd9:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102ce0:	02 02 02 
f0102ce3:	0f 85 80 01 00 00    	jne    f0102e69 <mem_init+0x1b3c>
	assert(pp2->pp_ref == 1);
f0102ce9:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102cee:	0f 85 8e 01 00 00    	jne    f0102e82 <mem_init+0x1b55>
	assert(pp1->pp_ref == 0);
f0102cf4:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102cf9:	0f 85 9c 01 00 00    	jne    f0102e9b <mem_init+0x1b6e>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102cff:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d06:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102d09:	89 d8                	mov    %ebx,%eax
f0102d0b:	2b 05 90 9e 23 f0    	sub    0xf0239e90,%eax
f0102d11:	c1 f8 03             	sar    $0x3,%eax
f0102d14:	89 c2                	mov    %eax,%edx
f0102d16:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102d19:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102d1e:	3b 05 88 9e 23 f0    	cmp    0xf0239e88,%eax
f0102d24:	0f 83 8a 01 00 00    	jae    f0102eb4 <mem_init+0x1b87>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d2a:	81 ba 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%edx)
f0102d31:	03 03 03 
f0102d34:	0f 85 8c 01 00 00    	jne    f0102ec6 <mem_init+0x1b99>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d3a:	83 ec 08             	sub    $0x8,%esp
f0102d3d:	68 00 10 00 00       	push   $0x1000
f0102d42:	ff 35 8c 9e 23 f0    	pushl  0xf0239e8c
f0102d48:	e8 91 e4 ff ff       	call   f01011de <page_remove>
	assert(pp2->pp_ref == 0);
f0102d4d:	83 c4 10             	add    $0x10,%esp
f0102d50:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102d55:	0f 85 84 01 00 00    	jne    f0102edf <mem_init+0x1bb2>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102d5b:	8b 0d 8c 9e 23 f0    	mov    0xf0239e8c,%ecx
f0102d61:	8b 11                	mov    (%ecx),%edx
f0102d63:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102d69:	89 f0                	mov    %esi,%eax
f0102d6b:	2b 05 90 9e 23 f0    	sub    0xf0239e90,%eax
f0102d71:	c1 f8 03             	sar    $0x3,%eax
f0102d74:	c1 e0 0c             	shl    $0xc,%eax
f0102d77:	39 c2                	cmp    %eax,%edx
f0102d79:	0f 85 79 01 00 00    	jne    f0102ef8 <mem_init+0x1bcb>
	kern_pgdir[0] = 0;
f0102d7f:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102d85:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102d8a:	0f 85 81 01 00 00    	jne    f0102f11 <mem_init+0x1be4>
	pp0->pp_ref = 0;
f0102d90:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102d96:	83 ec 0c             	sub    $0xc,%esp
f0102d99:	56                   	push   %esi
f0102d9a:	e8 54 e2 ff ff       	call   f0100ff3 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102d9f:	c7 04 24 bc 76 10 f0 	movl   $0xf01076bc,(%esp)
f0102da6:	e8 29 0c 00 00       	call   f01039d4 <cprintf>
}
f0102dab:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102dae:	5b                   	pop    %ebx
f0102daf:	5e                   	pop    %esi
f0102db0:	5f                   	pop    %edi
f0102db1:	5d                   	pop    %ebp
f0102db2:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102db3:	50                   	push   %eax
f0102db4:	68 08 68 10 f0       	push   $0xf0106808
f0102db9:	68 f7 00 00 00       	push   $0xf7
f0102dbe:	68 1d 77 10 f0       	push   $0xf010771d
f0102dc3:	e8 78 d2 ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f0102dc8:	68 0b 78 10 f0       	push   $0xf010780b
f0102dcd:	68 43 77 10 f0       	push   $0xf0107743
f0102dd2:	68 c7 04 00 00       	push   $0x4c7
f0102dd7:	68 1d 77 10 f0       	push   $0xf010771d
f0102ddc:	e8 5f d2 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102de1:	68 21 78 10 f0       	push   $0xf0107821
f0102de6:	68 43 77 10 f0       	push   $0xf0107743
f0102deb:	68 c8 04 00 00       	push   $0x4c8
f0102df0:	68 1d 77 10 f0       	push   $0xf010771d
f0102df5:	e8 46 d2 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102dfa:	68 37 78 10 f0       	push   $0xf0107837
f0102dff:	68 43 77 10 f0       	push   $0xf0107743
f0102e04:	68 c9 04 00 00       	push   $0x4c9
f0102e09:	68 1d 77 10 f0       	push   $0xf010771d
f0102e0e:	e8 2d d2 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e13:	52                   	push   %edx
f0102e14:	68 e4 67 10 f0       	push   $0xf01067e4
f0102e19:	6a 58                	push   $0x58
f0102e1b:	68 29 77 10 f0       	push   $0xf0107729
f0102e20:	e8 1b d2 ff ff       	call   f0100040 <_panic>
f0102e25:	52                   	push   %edx
f0102e26:	68 e4 67 10 f0       	push   $0xf01067e4
f0102e2b:	6a 58                	push   $0x58
f0102e2d:	68 29 77 10 f0       	push   $0xf0107729
f0102e32:	e8 09 d2 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102e37:	68 08 79 10 f0       	push   $0xf0107908
f0102e3c:	68 43 77 10 f0       	push   $0xf0107743
f0102e41:	68 ce 04 00 00       	push   $0x4ce
f0102e46:	68 1d 77 10 f0       	push   $0xf010771d
f0102e4b:	e8 f0 d1 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102e50:	68 48 76 10 f0       	push   $0xf0107648
f0102e55:	68 43 77 10 f0       	push   $0xf0107743
f0102e5a:	68 cf 04 00 00       	push   $0x4cf
f0102e5f:	68 1d 77 10 f0       	push   $0xf010771d
f0102e64:	e8 d7 d1 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102e69:	68 6c 76 10 f0       	push   $0xf010766c
f0102e6e:	68 43 77 10 f0       	push   $0xf0107743
f0102e73:	68 d1 04 00 00       	push   $0x4d1
f0102e78:	68 1d 77 10 f0       	push   $0xf010771d
f0102e7d:	e8 be d1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102e82:	68 2a 79 10 f0       	push   $0xf010792a
f0102e87:	68 43 77 10 f0       	push   $0xf0107743
f0102e8c:	68 d2 04 00 00       	push   $0x4d2
f0102e91:	68 1d 77 10 f0       	push   $0xf010771d
f0102e96:	e8 a5 d1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102e9b:	68 94 79 10 f0       	push   $0xf0107994
f0102ea0:	68 43 77 10 f0       	push   $0xf0107743
f0102ea5:	68 d3 04 00 00       	push   $0x4d3
f0102eaa:	68 1d 77 10 f0       	push   $0xf010771d
f0102eaf:	e8 8c d1 ff ff       	call   f0100040 <_panic>
f0102eb4:	52                   	push   %edx
f0102eb5:	68 e4 67 10 f0       	push   $0xf01067e4
f0102eba:	6a 58                	push   $0x58
f0102ebc:	68 29 77 10 f0       	push   $0xf0107729
f0102ec1:	e8 7a d1 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102ec6:	68 90 76 10 f0       	push   $0xf0107690
f0102ecb:	68 43 77 10 f0       	push   $0xf0107743
f0102ed0:	68 d5 04 00 00       	push   $0x4d5
f0102ed5:	68 1d 77 10 f0       	push   $0xf010771d
f0102eda:	e8 61 d1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102edf:	68 62 79 10 f0       	push   $0xf0107962
f0102ee4:	68 43 77 10 f0       	push   $0xf0107743
f0102ee9:	68 d7 04 00 00       	push   $0x4d7
f0102eee:	68 1d 77 10 f0       	push   $0xf010771d
f0102ef3:	e8 48 d1 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102ef8:	68 18 70 10 f0       	push   $0xf0107018
f0102efd:	68 43 77 10 f0       	push   $0xf0107743
f0102f02:	68 da 04 00 00       	push   $0x4da
f0102f07:	68 1d 77 10 f0       	push   $0xf010771d
f0102f0c:	e8 2f d1 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0102f11:	68 19 79 10 f0       	push   $0xf0107919
f0102f16:	68 43 77 10 f0       	push   $0xf0107743
f0102f1b:	68 dc 04 00 00       	push   $0x4dc
f0102f20:	68 1d 77 10 f0       	push   $0xf010771d
f0102f25:	e8 16 d1 ff ff       	call   f0100040 <_panic>

f0102f2a <user_mem_check>:
{
f0102f2a:	f3 0f 1e fb          	endbr32 
f0102f2e:	55                   	push   %ebp
f0102f2f:	89 e5                	mov    %esp,%ebp
f0102f31:	57                   	push   %edi
f0102f32:	56                   	push   %esi
f0102f33:	53                   	push   %ebx
f0102f34:	83 ec 2c             	sub    $0x2c,%esp
	pde_t* pgdir = env->env_pgdir;
f0102f37:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f3a:	8b 78 60             	mov    0x60(%eax),%edi
	uintptr_t address = (uintptr_t)va;
f0102f3d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f40:	89 45 cc             	mov    %eax,-0x34(%ebp)
	perm = perm | PTE_U | PTE_P;
f0102f43:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f46:	83 c8 05             	or     $0x5,%eax
f0102f49:	89 45 d0             	mov    %eax,-0x30(%ebp)
	pte_t* entry = NULL;
f0102f4c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	uintptr_t address = (uintptr_t)va;
f0102f53:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	for(; address<(uintptr_t)(va+len);address+=PGSIZE)
f0102f56:	89 d8                	mov    %ebx,%eax
f0102f58:	03 45 10             	add    0x10(%ebp),%eax
f0102f5b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		if(page_lookup(pgdir,(void*)address,&entry) == NULL)
f0102f5e:	8d 75 e4             	lea    -0x1c(%ebp),%esi
	for(; address<(uintptr_t)(va+len);address+=PGSIZE)
f0102f61:	eb 06                	jmp    f0102f69 <user_mem_check+0x3f>
f0102f63:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102f69:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102f6c:	76 3e                	jbe    f0102fac <user_mem_check+0x82>
		if(address>=ULIM)
f0102f6e:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102f74:	77 1c                	ja     f0102f92 <user_mem_check+0x68>
		if(page_lookup(pgdir,(void*)address,&entry) == NULL)
f0102f76:	83 ec 04             	sub    $0x4,%esp
f0102f79:	56                   	push   %esi
f0102f7a:	53                   	push   %ebx
f0102f7b:	57                   	push   %edi
f0102f7c:	e8 bb e1 ff ff       	call   f010113c <page_lookup>
f0102f81:	83 c4 10             	add    $0x10,%esp
f0102f84:	85 c0                	test   %eax,%eax
f0102f86:	74 0a                	je     f0102f92 <user_mem_check+0x68>
		if(!(*entry & perm))
f0102f88:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102f8b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0102f8e:	85 10                	test   %edx,(%eax)
f0102f90:	75 d1                	jne    f0102f63 <user_mem_check+0x39>
		user_mem_check_addr = (address == (uintptr_t)va ? address : ROUNDDOWN(address,PGSIZE));
f0102f92:	89 d8                	mov    %ebx,%eax
f0102f94:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102f99:	39 5d 0c             	cmp    %ebx,0xc(%ebp)
f0102f9c:	0f 44 45 cc          	cmove  -0x34(%ebp),%eax
f0102fa0:	a3 3c 92 23 f0       	mov    %eax,0xf023923c
		return -E_FAULT;
f0102fa5:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102faa:	eb 05                	jmp    f0102fb1 <user_mem_check+0x87>
	return 0;
f0102fac:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102fb1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102fb4:	5b                   	pop    %ebx
f0102fb5:	5e                   	pop    %esi
f0102fb6:	5f                   	pop    %edi
f0102fb7:	5d                   	pop    %ebp
f0102fb8:	c3                   	ret    

f0102fb9 <user_mem_assert>:
{
f0102fb9:	f3 0f 1e fb          	endbr32 
f0102fbd:	55                   	push   %ebp
f0102fbe:	89 e5                	mov    %esp,%ebp
f0102fc0:	53                   	push   %ebx
f0102fc1:	83 ec 04             	sub    $0x4,%esp
f0102fc4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102fc7:	8b 45 14             	mov    0x14(%ebp),%eax
f0102fca:	83 c8 04             	or     $0x4,%eax
f0102fcd:	50                   	push   %eax
f0102fce:	ff 75 10             	pushl  0x10(%ebp)
f0102fd1:	ff 75 0c             	pushl  0xc(%ebp)
f0102fd4:	53                   	push   %ebx
f0102fd5:	e8 50 ff ff ff       	call   f0102f2a <user_mem_check>
f0102fda:	83 c4 10             	add    $0x10,%esp
f0102fdd:	85 c0                	test   %eax,%eax
f0102fdf:	78 05                	js     f0102fe6 <user_mem_assert+0x2d>
}
f0102fe1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102fe4:	c9                   	leave  
f0102fe5:	c3                   	ret    
		cprintf("[%08x] user_mem_check assertion failure for "
f0102fe6:	83 ec 04             	sub    $0x4,%esp
f0102fe9:	ff 35 3c 92 23 f0    	pushl  0xf023923c
f0102fef:	ff 73 48             	pushl  0x48(%ebx)
f0102ff2:	68 e8 76 10 f0       	push   $0xf01076e8
f0102ff7:	e8 d8 09 00 00       	call   f01039d4 <cprintf>
		env_destroy(env);	// may not return
f0102ffc:	89 1c 24             	mov    %ebx,(%esp)
f0102fff:	e8 ab 06 00 00       	call   f01036af <env_destroy>
f0103004:	83 c4 10             	add    $0x10,%esp
}
f0103007:	eb d8                	jmp    f0102fe1 <user_mem_assert+0x28>

f0103009 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0103009:	55                   	push   %ebp
f010300a:	89 e5                	mov    %esp,%ebp
f010300c:	57                   	push   %edi
f010300d:	56                   	push   %esi
f010300e:	53                   	push   %ebx
f010300f:	83 ec 0c             	sub    $0xc,%esp
f0103012:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void* start = (void*)ROUNDDOWN((uint32_t)va,PGSIZE);
f0103014:	89 d3                	mov    %edx,%ebx
f0103016:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void* end = (void*)ROUNDUP((uint32_t)va+len,PGSIZE);
f010301c:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0103023:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

	// corner case 1: too large length
	if(start>end)
f0103029:	39 f3                	cmp    %esi,%ebx
f010302b:	77 30                	ja     f010305d <region_alloc+0x54>
		panic("At region_alloc: too large length\n");
	}
	struct PageInfo* p = NULL;

	// allocate PA by the size of a page
	for(void* v = start;v<end;v+=PGSIZE)
f010302d:	39 f3                	cmp    %esi,%ebx
f010302f:	73 71                	jae    f01030a2 <region_alloc+0x99>
	{
		p = page_alloc(0);
f0103031:	83 ec 0c             	sub    $0xc,%esp
f0103034:	6a 00                	push   $0x0
f0103036:	e8 3f df ff ff       	call   f0100f7a <page_alloc>
		// corner case 2: page allocation failed
		if(p == NULL)
f010303b:	83 c4 10             	add    $0x10,%esp
f010303e:	85 c0                	test   %eax,%eax
f0103040:	74 32                	je     f0103074 <region_alloc+0x6b>
		{
			panic("At region_alloc: Page allocation failed");
		}

		// insert into page table
		int insert = page_insert(e->env_pgdir,p,v,PTE_W|PTE_U);
f0103042:	6a 06                	push   $0x6
f0103044:	53                   	push   %ebx
f0103045:	50                   	push   %eax
f0103046:	ff 77 60             	pushl  0x60(%edi)
f0103049:	e8 e1 e1 ff ff       	call   f010122f <page_insert>

		// corner case 3: insertion failed
		if(insert!=0)
f010304e:	83 c4 10             	add    $0x10,%esp
f0103051:	85 c0                	test   %eax,%eax
f0103053:	75 36                	jne    f010308b <region_alloc+0x82>
	for(void* v = start;v<end;v+=PGSIZE)
f0103055:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010305b:	eb d0                	jmp    f010302d <region_alloc+0x24>
		panic("At region_alloc: too large length\n");
f010305d:	83 ec 04             	sub    $0x4,%esp
f0103060:	68 30 7a 10 f0       	push   $0xf0107a30
f0103065:	68 37 01 00 00       	push   $0x137
f010306a:	68 25 7b 10 f0       	push   $0xf0107b25
f010306f:	e8 cc cf ff ff       	call   f0100040 <_panic>
			panic("At region_alloc: Page allocation failed");
f0103074:	83 ec 04             	sub    $0x4,%esp
f0103077:	68 54 7a 10 f0       	push   $0xf0107a54
f010307c:	68 42 01 00 00       	push   $0x142
f0103081:	68 25 7b 10 f0       	push   $0xf0107b25
f0103086:	e8 b5 cf ff ff       	call   f0100040 <_panic>
		{
			panic("At region_alloc: Page insertion failed");
f010308b:	83 ec 04             	sub    $0x4,%esp
f010308e:	68 7c 7a 10 f0       	push   $0xf0107a7c
f0103093:	68 4b 01 00 00       	push   $0x14b
f0103098:	68 25 7b 10 f0       	push   $0xf0107b25
f010309d:	e8 9e cf ff ff       	call   f0100040 <_panic>
		}
	}
}
f01030a2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030a5:	5b                   	pop    %ebx
f01030a6:	5e                   	pop    %esi
f01030a7:	5f                   	pop    %edi
f01030a8:	5d                   	pop    %ebp
f01030a9:	c3                   	ret    

f01030aa <envid2env>:
{
f01030aa:	f3 0f 1e fb          	endbr32 
f01030ae:	55                   	push   %ebp
f01030af:	89 e5                	mov    %esp,%ebp
f01030b1:	56                   	push   %esi
f01030b2:	53                   	push   %ebx
f01030b3:	8b 75 08             	mov    0x8(%ebp),%esi
f01030b6:	8b 45 10             	mov    0x10(%ebp),%eax
	if (envid == 0) {
f01030b9:	85 f6                	test   %esi,%esi
f01030bb:	74 2e                	je     f01030eb <envid2env+0x41>
	e = &envs[ENVX(envid)];
f01030bd:	89 f3                	mov    %esi,%ebx
f01030bf:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f01030c5:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f01030c8:	03 1d 48 92 23 f0    	add    0xf0239248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01030ce:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f01030d2:	74 2e                	je     f0103102 <envid2env+0x58>
f01030d4:	39 73 48             	cmp    %esi,0x48(%ebx)
f01030d7:	75 29                	jne    f0103102 <envid2env+0x58>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01030d9:	84 c0                	test   %al,%al
f01030db:	75 35                	jne    f0103112 <envid2env+0x68>
	*env_store = e;
f01030dd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030e0:	89 18                	mov    %ebx,(%eax)
	return 0;
f01030e2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01030e7:	5b                   	pop    %ebx
f01030e8:	5e                   	pop    %esi
f01030e9:	5d                   	pop    %ebp
f01030ea:	c3                   	ret    
		*env_store = curenv;
f01030eb:	e8 5e 30 00 00       	call   f010614e <cpunum>
f01030f0:	6b c0 74             	imul   $0x74,%eax,%eax
f01030f3:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f01030f9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01030fc:	89 02                	mov    %eax,(%edx)
		return 0;
f01030fe:	89 f0                	mov    %esi,%eax
f0103100:	eb e5                	jmp    f01030e7 <envid2env+0x3d>
		*env_store = 0;
f0103102:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103105:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010310b:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103110:	eb d5                	jmp    f01030e7 <envid2env+0x3d>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103112:	e8 37 30 00 00       	call   f010614e <cpunum>
f0103117:	6b c0 74             	imul   $0x74,%eax,%eax
f010311a:	39 98 28 a0 23 f0    	cmp    %ebx,-0xfdc5fd8(%eax)
f0103120:	74 bb                	je     f01030dd <envid2env+0x33>
f0103122:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0103125:	e8 24 30 00 00       	call   f010614e <cpunum>
f010312a:	6b c0 74             	imul   $0x74,%eax,%eax
f010312d:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f0103133:	3b 70 48             	cmp    0x48(%eax),%esi
f0103136:	74 a5                	je     f01030dd <envid2env+0x33>
		*env_store = 0;
f0103138:	8b 45 0c             	mov    0xc(%ebp),%eax
f010313b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103141:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103146:	eb 9f                	jmp    f01030e7 <envid2env+0x3d>

f0103148 <env_init_percpu>:
{
f0103148:	f3 0f 1e fb          	endbr32 
	asm volatile("lgdt (%0)" : : "r" (p));
f010314c:	b8 20 33 12 f0       	mov    $0xf0123320,%eax
f0103151:	0f 01 10             	lgdtl  (%eax)
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0103154:	b8 23 00 00 00       	mov    $0x23,%eax
f0103159:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f010315b:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f010315d:	b8 10 00 00 00       	mov    $0x10,%eax
f0103162:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0103164:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0103166:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0103168:	ea 6f 31 10 f0 08 00 	ljmp   $0x8,$0xf010316f
	asm volatile("lldt %0" : : "r" (sel));
f010316f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103174:	0f 00 d0             	lldt   %ax
}
f0103177:	c3                   	ret    

f0103178 <env_init>:
{
f0103178:	f3 0f 1e fb          	endbr32 
f010317c:	55                   	push   %ebp
f010317d:	89 e5                	mov    %esp,%ebp
f010317f:	56                   	push   %esi
f0103180:	53                   	push   %ebx
		envs[i].env_id = 0;
f0103181:	8b 35 48 92 23 f0    	mov    0xf0239248,%esi
f0103187:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f010318d:	89 f3                	mov    %esi,%ebx
f010318f:	ba 00 00 00 00       	mov    $0x0,%edx
f0103194:	89 d1                	mov    %edx,%ecx
f0103196:	89 c2                	mov    %eax,%edx
f0103198:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f010319f:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f01031a6:	89 48 44             	mov    %ecx,0x44(%eax)
f01031a9:	83 e8 7c             	sub    $0x7c,%eax
	for(int i = NENV - 1; i>=0 ;i--)
f01031ac:	39 da                	cmp    %ebx,%edx
f01031ae:	75 e4                	jne    f0103194 <env_init+0x1c>
f01031b0:	89 35 4c 92 23 f0    	mov    %esi,0xf023924c
	env_init_percpu();
f01031b6:	e8 8d ff ff ff       	call   f0103148 <env_init_percpu>
}
f01031bb:	5b                   	pop    %ebx
f01031bc:	5e                   	pop    %esi
f01031bd:	5d                   	pop    %ebp
f01031be:	c3                   	ret    

f01031bf <env_alloc>:
{
f01031bf:	f3 0f 1e fb          	endbr32 
f01031c3:	55                   	push   %ebp
f01031c4:	89 e5                	mov    %esp,%ebp
f01031c6:	53                   	push   %ebx
f01031c7:	83 ec 04             	sub    $0x4,%esp
	if (!(e = env_free_list))
f01031ca:	8b 1d 4c 92 23 f0    	mov    0xf023924c,%ebx
f01031d0:	85 db                	test   %ebx,%ebx
f01031d2:	0f 84 95 01 00 00    	je     f010336d <env_alloc+0x1ae>
	if (!(p = page_alloc(ALLOC_ZERO)))
f01031d8:	83 ec 0c             	sub    $0xc,%esp
f01031db:	6a 01                	push   $0x1
f01031dd:	e8 98 dd ff ff       	call   f0100f7a <page_alloc>
f01031e2:	83 c4 10             	add    $0x10,%esp
f01031e5:	85 c0                	test   %eax,%eax
f01031e7:	0f 84 87 01 00 00    	je     f0103374 <env_alloc+0x1b5>
	return (pp - pages) << PGSHIFT;
f01031ed:	89 c2                	mov    %eax,%edx
f01031ef:	2b 15 90 9e 23 f0    	sub    0xf0239e90,%edx
f01031f5:	c1 fa 03             	sar    $0x3,%edx
f01031f8:	89 d1                	mov    %edx,%ecx
f01031fa:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f01031fd:	81 e2 ff ff 0f 00    	and    $0xfffff,%edx
f0103203:	3b 15 88 9e 23 f0    	cmp    0xf0239e88,%edx
f0103209:	0f 83 37 01 00 00    	jae    f0103346 <env_alloc+0x187>
	return (void *)(pa + KERNBASE);
f010320f:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0103215:	89 4b 60             	mov    %ecx,0x60(%ebx)
	p->pp_ref++;
f0103218:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f010321d:	b8 00 00 00 00       	mov    $0x0,%eax
		e->env_pgdir[i] = 0;
f0103222:	8b 53 60             	mov    0x60(%ebx),%edx
f0103225:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f010322c:	83 c0 04             	add    $0x4,%eax
	for(int i = 0;i<PDX(UTOP);i++)
f010322f:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f0103234:	75 ec                	jne    f0103222 <env_alloc+0x63>
		e->env_pgdir[i] = kern_pgdir[i];
f0103236:	8b 15 8c 9e 23 f0    	mov    0xf0239e8c,%edx
f010323c:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f010323f:	8b 53 60             	mov    0x60(%ebx),%edx
f0103242:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0103245:	83 c0 04             	add    $0x4,%eax
	for(int i = PDX(UTOP);i<NPDENTRIES;i++)
f0103248:	3d 00 10 00 00       	cmp    $0x1000,%eax
f010324d:	75 e7                	jne    f0103236 <env_alloc+0x77>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f010324f:	8b 43 60             	mov    0x60(%ebx),%eax
	if ((uint32_t)kva < KERNBASE)
f0103252:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103257:	0f 86 fb 00 00 00    	jbe    f0103358 <env_alloc+0x199>
	return (physaddr_t)kva - KERNBASE;
f010325d:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103263:	83 ca 05             	or     $0x5,%edx
f0103266:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f010326c:	8b 43 48             	mov    0x48(%ebx),%eax
f010326f:	05 00 10 00 00       	add    $0x1000,%eax
		generation = 1 << ENVGENSHIFT;
f0103274:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0103279:	ba 00 10 00 00       	mov    $0x1000,%edx
f010327e:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103281:	89 da                	mov    %ebx,%edx
f0103283:	2b 15 48 92 23 f0    	sub    0xf0239248,%edx
f0103289:	c1 fa 02             	sar    $0x2,%edx
f010328c:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0103292:	09 d0                	or     %edx,%eax
f0103294:	89 43 48             	mov    %eax,0x48(%ebx)
	e->env_parent_id = parent_id;
f0103297:	8b 45 0c             	mov    0xc(%ebp),%eax
f010329a:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f010329d:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01032a4:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01032ab:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01032b2:	83 ec 04             	sub    $0x4,%esp
f01032b5:	6a 44                	push   $0x44
f01032b7:	6a 00                	push   $0x0
f01032b9:	53                   	push   %ebx
f01032ba:	e8 71 28 00 00       	call   f0105b30 <memset>
	e->env_tf.tf_ds = GD_UD | 3;
f01032bf:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01032c5:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01032cb:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01032d1:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01032d8:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	e->env_tf.tf_eflags |= FL_IF;
f01032de:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)
	e->env_pgfault_upcall = 0;
f01032e5:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)
	e->env_ipc_recving = 0;
f01032ec:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
	env_free_list = e->env_link;
f01032f0:	8b 43 44             	mov    0x44(%ebx),%eax
f01032f3:	a3 4c 92 23 f0       	mov    %eax,0xf023924c
	*newenv_store = e;
f01032f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01032fb:	89 18                	mov    %ebx,(%eax)
	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01032fd:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0103300:	e8 49 2e 00 00       	call   f010614e <cpunum>
f0103305:	6b c0 74             	imul   $0x74,%eax,%eax
f0103308:	83 c4 10             	add    $0x10,%esp
f010330b:	ba 00 00 00 00       	mov    $0x0,%edx
f0103310:	83 b8 28 a0 23 f0 00 	cmpl   $0x0,-0xfdc5fd8(%eax)
f0103317:	74 11                	je     f010332a <env_alloc+0x16b>
f0103319:	e8 30 2e 00 00       	call   f010614e <cpunum>
f010331e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103321:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f0103327:	8b 50 48             	mov    0x48(%eax),%edx
f010332a:	83 ec 04             	sub    $0x4,%esp
f010332d:	53                   	push   %ebx
f010332e:	52                   	push   %edx
f010332f:	68 30 7b 10 f0       	push   $0xf0107b30
f0103334:	e8 9b 06 00 00       	call   f01039d4 <cprintf>
	return 0;
f0103339:	83 c4 10             	add    $0x10,%esp
f010333c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103341:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103344:	c9                   	leave  
f0103345:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103346:	51                   	push   %ecx
f0103347:	68 e4 67 10 f0       	push   $0xf01067e4
f010334c:	6a 58                	push   $0x58
f010334e:	68 29 77 10 f0       	push   $0xf0107729
f0103353:	e8 e8 cc ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103358:	50                   	push   %eax
f0103359:	68 08 68 10 f0       	push   $0xf0106808
f010335e:	68 d3 00 00 00       	push   $0xd3
f0103363:	68 25 7b 10 f0       	push   $0xf0107b25
f0103368:	e8 d3 cc ff ff       	call   f0100040 <_panic>
		return -E_NO_FREE_ENV;
f010336d:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103372:	eb cd                	jmp    f0103341 <env_alloc+0x182>
		return -E_NO_MEM;
f0103374:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0103379:	eb c6                	jmp    f0103341 <env_alloc+0x182>

f010337b <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010337b:	f3 0f 1e fb          	endbr32 
f010337f:	55                   	push   %ebp
f0103380:	89 e5                	mov    %esp,%ebp
f0103382:	57                   	push   %edi
f0103383:	56                   	push   %esi
f0103384:	53                   	push   %ebx
f0103385:	83 ec 34             	sub    $0x34,%esp
f0103388:	8b 75 08             	mov    0x8(%ebp),%esi
	// LAB 3: Your code here.
	struct Env* e;
	int alloc = env_alloc(&e,0);
f010338b:	6a 00                	push   $0x0
f010338d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103390:	50                   	push   %eax
f0103391:	e8 29 fe ff ff       	call   f01031bf <env_alloc>
	if(alloc != 0)
f0103396:	83 c4 10             	add    $0x10,%esp
f0103399:	85 c0                	test   %eax,%eax
f010339b:	75 30                	jne    f01033cd <env_create+0x52>
	{
		panic("At env_create: env_alloc() failed");
	}
	load_icode(e,binary);
f010339d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
	if(elfHeader->e_magic != ELF_MAGIC)
f01033a0:	81 3e 7f 45 4c 46    	cmpl   $0x464c457f,(%esi)
f01033a6:	75 3c                	jne    f01033e4 <env_create+0x69>
	lcr3(PADDR(e->env_pgdir));
f01033a8:	8b 47 60             	mov    0x60(%edi),%eax
	if ((uint32_t)kva < KERNBASE)
f01033ab:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033b0:	76 49                	jbe    f01033fb <env_create+0x80>
	return (physaddr_t)kva - KERNBASE;
f01033b2:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01033b7:	0f 22 d8             	mov    %eax,%cr3
	struct Proghdr* ph = (struct Proghdr*)(binary+elfHeader->e_phoff);
f01033ba:	89 f3                	mov    %esi,%ebx
f01033bc:	03 5e 1c             	add    0x1c(%esi),%ebx
	struct Proghdr* phEnd = ph+elfHeader->e_phnum;
f01033bf:	0f b7 46 2c          	movzwl 0x2c(%esi),%eax
f01033c3:	c1 e0 05             	shl    $0x5,%eax
f01033c6:	01 d8                	add    %ebx,%eax
f01033c8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for(;ph<phEnd;ph++)
f01033cb:	eb 5d                	jmp    f010342a <env_create+0xaf>
		panic("At env_create: env_alloc() failed");
f01033cd:	83 ec 04             	sub    $0x4,%esp
f01033d0:	68 a4 7a 10 f0       	push   $0xf0107aa4
f01033d5:	68 c4 01 00 00       	push   $0x1c4
f01033da:	68 25 7b 10 f0       	push   $0xf0107b25
f01033df:	e8 5c cc ff ff       	call   f0100040 <_panic>
		panic("At load_icode: Invalid head magic number");
f01033e4:	83 ec 04             	sub    $0x4,%esp
f01033e7:	68 c8 7a 10 f0       	push   $0xf0107ac8
f01033ec:	68 8c 01 00 00       	push   $0x18c
f01033f1:	68 25 7b 10 f0       	push   $0xf0107b25
f01033f6:	e8 45 cc ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033fb:	50                   	push   %eax
f01033fc:	68 08 68 10 f0       	push   $0xf0106808
f0103401:	68 8f 01 00 00       	push   $0x18f
f0103406:	68 25 7b 10 f0       	push   $0xf0107b25
f010340b:	e8 30 cc ff ff       	call   f0100040 <_panic>
				panic("At load_icode: file size bigger than memory size");
f0103410:	83 ec 04             	sub    $0x4,%esp
f0103413:	68 f4 7a 10 f0       	push   $0xf0107af4
f0103418:	68 9b 01 00 00       	push   $0x19b
f010341d:	68 25 7b 10 f0       	push   $0xf0107b25
f0103422:	e8 19 cc ff ff       	call   f0100040 <_panic>
	for(;ph<phEnd;ph++)
f0103427:	83 c3 20             	add    $0x20,%ebx
f010342a:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010342d:	76 47                	jbe    f0103476 <env_create+0xfb>
		if(ph->p_type == ELF_PROG_LOAD)
f010342f:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103432:	75 f3                	jne    f0103427 <env_create+0xac>
			if(ph->p_filesz>ph->p_memsz)
f0103434:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103437:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f010343a:	77 d4                	ja     f0103410 <env_create+0x95>
			region_alloc(e,(void*) ph->p_va,ph->p_memsz);
f010343c:	8b 53 08             	mov    0x8(%ebx),%edx
f010343f:	89 f8                	mov    %edi,%eax
f0103441:	e8 c3 fb ff ff       	call   f0103009 <region_alloc>
			memcpy((void*)ph->p_va,binary+ph->p_offset,ph->p_filesz);
f0103446:	83 ec 04             	sub    $0x4,%esp
f0103449:	ff 73 10             	pushl  0x10(%ebx)
f010344c:	89 f0                	mov    %esi,%eax
f010344e:	03 43 04             	add    0x4(%ebx),%eax
f0103451:	50                   	push   %eax
f0103452:	ff 73 08             	pushl  0x8(%ebx)
f0103455:	e8 88 27 00 00       	call   f0105be2 <memcpy>
			memset((void*)(ph->p_va+ph->p_filesz),0,ph->p_memsz-ph->p_filesz);
f010345a:	8b 43 10             	mov    0x10(%ebx),%eax
f010345d:	83 c4 0c             	add    $0xc,%esp
f0103460:	8b 53 14             	mov    0x14(%ebx),%edx
f0103463:	29 c2                	sub    %eax,%edx
f0103465:	52                   	push   %edx
f0103466:	6a 00                	push   $0x0
f0103468:	03 43 08             	add    0x8(%ebx),%eax
f010346b:	50                   	push   %eax
f010346c:	e8 bf 26 00 00       	call   f0105b30 <memset>
f0103471:	83 c4 10             	add    $0x10,%esp
f0103474:	eb b1                	jmp    f0103427 <env_create+0xac>
	lcr3(PADDR(kern_pgdir));
f0103476:	a1 8c 9e 23 f0       	mov    0xf0239e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f010347b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103480:	76 37                	jbe    f01034b9 <env_create+0x13e>
	return (physaddr_t)kva - KERNBASE;
f0103482:	05 00 00 00 10       	add    $0x10000000,%eax
f0103487:	0f 22 d8             	mov    %eax,%cr3
	e->env_status = ENV_RUNNABLE;
f010348a:	c7 47 54 02 00 00 00 	movl   $0x2,0x54(%edi)
	e->env_tf.tf_eip = elfHeader->e_entry;
f0103491:	8b 46 18             	mov    0x18(%esi),%eax
f0103494:	89 47 30             	mov    %eax,0x30(%edi)
	region_alloc(e,(void*)(USTACKTOP-PGSIZE),PGSIZE);
f0103497:	b9 00 10 00 00       	mov    $0x1000,%ecx
f010349c:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01034a1:	89 f8                	mov    %edi,%eax
f01034a3:	e8 61 fb ff ff       	call   f0103009 <region_alloc>
	e->env_type = type;
f01034a8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01034ab:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01034ae:	89 50 50             	mov    %edx,0x50(%eax)
}
f01034b1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01034b4:	5b                   	pop    %ebx
f01034b5:	5e                   	pop    %esi
f01034b6:	5f                   	pop    %edi
f01034b7:	5d                   	pop    %ebp
f01034b8:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034b9:	50                   	push   %eax
f01034ba:	68 08 68 10 f0       	push   $0xf0106808
f01034bf:	68 a8 01 00 00       	push   $0x1a8
f01034c4:	68 25 7b 10 f0       	push   $0xf0107b25
f01034c9:	e8 72 cb ff ff       	call   f0100040 <_panic>

f01034ce <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01034ce:	f3 0f 1e fb          	endbr32 
f01034d2:	55                   	push   %ebp
f01034d3:	89 e5                	mov    %esp,%ebp
f01034d5:	57                   	push   %edi
f01034d6:	56                   	push   %esi
f01034d7:	53                   	push   %ebx
f01034d8:	83 ec 1c             	sub    $0x1c,%esp
f01034db:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01034de:	e8 6b 2c 00 00       	call   f010614e <cpunum>
f01034e3:	6b c0 74             	imul   $0x74,%eax,%eax
f01034e6:	39 b8 28 a0 23 f0    	cmp    %edi,-0xfdc5fd8(%eax)
f01034ec:	74 48                	je     f0103536 <env_free+0x68>
		lcr3(PADDR(kern_pgdir));

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01034ee:	8b 5f 48             	mov    0x48(%edi),%ebx
f01034f1:	e8 58 2c 00 00       	call   f010614e <cpunum>
f01034f6:	6b c0 74             	imul   $0x74,%eax,%eax
f01034f9:	ba 00 00 00 00       	mov    $0x0,%edx
f01034fe:	83 b8 28 a0 23 f0 00 	cmpl   $0x0,-0xfdc5fd8(%eax)
f0103505:	74 11                	je     f0103518 <env_free+0x4a>
f0103507:	e8 42 2c 00 00       	call   f010614e <cpunum>
f010350c:	6b c0 74             	imul   $0x74,%eax,%eax
f010350f:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f0103515:	8b 50 48             	mov    0x48(%eax),%edx
f0103518:	83 ec 04             	sub    $0x4,%esp
f010351b:	53                   	push   %ebx
f010351c:	52                   	push   %edx
f010351d:	68 45 7b 10 f0       	push   $0xf0107b45
f0103522:	e8 ad 04 00 00       	call   f01039d4 <cprintf>
f0103527:	83 c4 10             	add    $0x10,%esp
f010352a:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103531:	e9 a9 00 00 00       	jmp    f01035df <env_free+0x111>
		lcr3(PADDR(kern_pgdir));
f0103536:	a1 8c 9e 23 f0       	mov    0xf0239e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f010353b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103540:	76 0a                	jbe    f010354c <env_free+0x7e>
	return (physaddr_t)kva - KERNBASE;
f0103542:	05 00 00 00 10       	add    $0x10000000,%eax
f0103547:	0f 22 d8             	mov    %eax,%cr3
}
f010354a:	eb a2                	jmp    f01034ee <env_free+0x20>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010354c:	50                   	push   %eax
f010354d:	68 08 68 10 f0       	push   $0xf0106808
f0103552:	68 d8 01 00 00       	push   $0x1d8
f0103557:	68 25 7b 10 f0       	push   $0xf0107b25
f010355c:	e8 df ca ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103561:	56                   	push   %esi
f0103562:	68 e4 67 10 f0       	push   $0xf01067e4
f0103567:	68 e7 01 00 00       	push   $0x1e7
f010356c:	68 25 7b 10 f0       	push   $0xf0107b25
f0103571:	e8 ca ca ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103576:	83 ec 08             	sub    $0x8,%esp
f0103579:	89 d8                	mov    %ebx,%eax
f010357b:	c1 e0 0c             	shl    $0xc,%eax
f010357e:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103581:	50                   	push   %eax
f0103582:	ff 77 60             	pushl  0x60(%edi)
f0103585:	e8 54 dc ff ff       	call   f01011de <page_remove>
f010358a:	83 c4 10             	add    $0x10,%esp
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010358d:	83 c3 01             	add    $0x1,%ebx
f0103590:	83 c6 04             	add    $0x4,%esi
f0103593:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103599:	74 07                	je     f01035a2 <env_free+0xd4>
			if (pt[pteno] & PTE_P)
f010359b:	f6 06 01             	testb  $0x1,(%esi)
f010359e:	74 ed                	je     f010358d <env_free+0xbf>
f01035a0:	eb d4                	jmp    f0103576 <env_free+0xa8>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01035a2:	8b 47 60             	mov    0x60(%edi),%eax
f01035a5:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01035a8:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f01035af:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01035b2:	3b 05 88 9e 23 f0    	cmp    0xf0239e88,%eax
f01035b8:	73 65                	jae    f010361f <env_free+0x151>
		page_decref(pa2page(pa));
f01035ba:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01035bd:	a1 90 9e 23 f0       	mov    0xf0239e90,%eax
f01035c2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01035c5:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01035c8:	50                   	push   %eax
f01035c9:	e8 64 da ff ff       	call   f0101032 <page_decref>
f01035ce:	83 c4 10             	add    $0x10,%esp
f01035d1:	83 45 e0 04          	addl   $0x4,-0x20(%ebp)
f01035d5:	8b 45 e0             	mov    -0x20(%ebp),%eax
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01035d8:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f01035dd:	74 54                	je     f0103633 <env_free+0x165>
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01035df:	8b 47 60             	mov    0x60(%edi),%eax
f01035e2:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01035e5:	8b 04 10             	mov    (%eax,%edx,1),%eax
f01035e8:	a8 01                	test   $0x1,%al
f01035ea:	74 e5                	je     f01035d1 <env_free+0x103>
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01035ec:	89 c6                	mov    %eax,%esi
f01035ee:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	if (PGNUM(pa) >= npages)
f01035f4:	c1 e8 0c             	shr    $0xc,%eax
f01035f7:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01035fa:	39 05 88 9e 23 f0    	cmp    %eax,0xf0239e88
f0103600:	0f 86 5b ff ff ff    	jbe    f0103561 <env_free+0x93>
	return (void *)(pa + KERNBASE);
f0103606:	81 ee 00 00 00 10    	sub    $0x10000000,%esi
f010360c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010360f:	c1 e0 14             	shl    $0x14,%eax
f0103612:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103615:	bb 00 00 00 00       	mov    $0x0,%ebx
f010361a:	e9 7c ff ff ff       	jmp    f010359b <env_free+0xcd>
		panic("pa2page called with invalid pa");
f010361f:	83 ec 04             	sub    $0x4,%esp
f0103622:	68 bc 6e 10 f0       	push   $0xf0106ebc
f0103627:	6a 51                	push   $0x51
f0103629:	68 29 77 10 f0       	push   $0xf0107729
f010362e:	e8 0d ca ff ff       	call   f0100040 <_panic>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103633:	8b 47 60             	mov    0x60(%edi),%eax
	if ((uint32_t)kva < KERNBASE)
f0103636:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010363b:	76 49                	jbe    f0103686 <env_free+0x1b8>
	e->env_pgdir = 0;
f010363d:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103644:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f0103649:	c1 e8 0c             	shr    $0xc,%eax
f010364c:	3b 05 88 9e 23 f0    	cmp    0xf0239e88,%eax
f0103652:	73 47                	jae    f010369b <env_free+0x1cd>
	page_decref(pa2page(pa));
f0103654:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103657:	8b 15 90 9e 23 f0    	mov    0xf0239e90,%edx
f010365d:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103660:	50                   	push   %eax
f0103661:	e8 cc d9 ff ff       	call   f0101032 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103666:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f010366d:	a1 4c 92 23 f0       	mov    0xf023924c,%eax
f0103672:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103675:	89 3d 4c 92 23 f0    	mov    %edi,0xf023924c
}
f010367b:	83 c4 10             	add    $0x10,%esp
f010367e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103681:	5b                   	pop    %ebx
f0103682:	5e                   	pop    %esi
f0103683:	5f                   	pop    %edi
f0103684:	5d                   	pop    %ebp
f0103685:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103686:	50                   	push   %eax
f0103687:	68 08 68 10 f0       	push   $0xf0106808
f010368c:	68 f5 01 00 00       	push   $0x1f5
f0103691:	68 25 7b 10 f0       	push   $0xf0107b25
f0103696:	e8 a5 c9 ff ff       	call   f0100040 <_panic>
		panic("pa2page called with invalid pa");
f010369b:	83 ec 04             	sub    $0x4,%esp
f010369e:	68 bc 6e 10 f0       	push   $0xf0106ebc
f01036a3:	6a 51                	push   $0x51
f01036a5:	68 29 77 10 f0       	push   $0xf0107729
f01036aa:	e8 91 c9 ff ff       	call   f0100040 <_panic>

f01036af <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f01036af:	f3 0f 1e fb          	endbr32 
f01036b3:	55                   	push   %ebp
f01036b4:	89 e5                	mov    %esp,%ebp
f01036b6:	53                   	push   %ebx
f01036b7:	83 ec 04             	sub    $0x4,%esp
f01036ba:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01036bd:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f01036c1:	74 21                	je     f01036e4 <env_destroy+0x35>
		e->env_status = ENV_DYING;
		return;
	}

	env_free(e);
f01036c3:	83 ec 0c             	sub    $0xc,%esp
f01036c6:	53                   	push   %ebx
f01036c7:	e8 02 fe ff ff       	call   f01034ce <env_free>

	if (curenv == e) {
f01036cc:	e8 7d 2a 00 00       	call   f010614e <cpunum>
f01036d1:	6b c0 74             	imul   $0x74,%eax,%eax
f01036d4:	83 c4 10             	add    $0x10,%esp
f01036d7:	39 98 28 a0 23 f0    	cmp    %ebx,-0xfdc5fd8(%eax)
f01036dd:	74 1e                	je     f01036fd <env_destroy+0x4e>
		curenv = NULL;
		sched_yield();
	}
}
f01036df:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01036e2:	c9                   	leave  
f01036e3:	c3                   	ret    
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01036e4:	e8 65 2a 00 00       	call   f010614e <cpunum>
f01036e9:	6b c0 74             	imul   $0x74,%eax,%eax
f01036ec:	39 98 28 a0 23 f0    	cmp    %ebx,-0xfdc5fd8(%eax)
f01036f2:	74 cf                	je     f01036c3 <env_destroy+0x14>
		e->env_status = ENV_DYING;
f01036f4:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01036fb:	eb e2                	jmp    f01036df <env_destroy+0x30>
		curenv = NULL;
f01036fd:	e8 4c 2a 00 00       	call   f010614e <cpunum>
f0103702:	6b c0 74             	imul   $0x74,%eax,%eax
f0103705:	c7 80 28 a0 23 f0 00 	movl   $0x0,-0xfdc5fd8(%eax)
f010370c:	00 00 00 
		sched_yield();
f010370f:	e8 5d 11 00 00       	call   f0104871 <sched_yield>

f0103714 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103714:	f3 0f 1e fb          	endbr32 
f0103718:	55                   	push   %ebp
f0103719:	89 e5                	mov    %esp,%ebp
f010371b:	53                   	push   %ebx
f010371c:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f010371f:	e8 2a 2a 00 00       	call   f010614e <cpunum>
f0103724:	6b c0 74             	imul   $0x74,%eax,%eax
f0103727:	8b 98 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%ebx
f010372d:	e8 1c 2a 00 00       	call   f010614e <cpunum>
f0103732:	89 43 5c             	mov    %eax,0x5c(%ebx)
	asm volatile(
f0103735:	8b 65 08             	mov    0x8(%ebp),%esp
f0103738:	61                   	popa   
f0103739:	07                   	pop    %es
f010373a:	1f                   	pop    %ds
f010373b:	83 c4 08             	add    $0x8,%esp
f010373e:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f010373f:	83 ec 04             	sub    $0x4,%esp
f0103742:	68 5b 7b 10 f0       	push   $0xf0107b5b
f0103747:	68 27 02 00 00       	push   $0x227
f010374c:	68 25 7b 10 f0       	push   $0xf0107b25
f0103751:	e8 ea c8 ff ff       	call   f0100040 <_panic>

f0103756 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103756:	f3 0f 1e fb          	endbr32 
f010375a:	55                   	push   %ebp
f010375b:	89 e5                	mov    %esp,%ebp
f010375d:	83 ec 08             	sub    $0x8,%esp
	
	// panic("env_run not yet implemented");

	// step 1
	// set the env_status field
	if(curenv)
f0103760:	e8 e9 29 00 00       	call   f010614e <cpunum>
f0103765:	6b c0 74             	imul   $0x74,%eax,%eax
f0103768:	83 b8 28 a0 23 f0 00 	cmpl   $0x0,-0xfdc5fd8(%eax)
f010376f:	74 14                	je     f0103785 <env_run+0x2f>
	{
		if(curenv->env_status == ENV_RUNNING)
f0103771:	e8 d8 29 00 00       	call   f010614e <cpunum>
f0103776:	6b c0 74             	imul   $0x74,%eax,%eax
f0103779:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f010377f:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103783:	74 7d                	je     f0103802 <env_run+0xac>
			curenv->env_status = ENV_RUNNABLE;
		}
	}

	// switch to new environment
	curenv = e;
f0103785:	e8 c4 29 00 00       	call   f010614e <cpunum>
f010378a:	6b c0 74             	imul   $0x74,%eax,%eax
f010378d:	8b 55 08             	mov    0x8(%ebp),%edx
f0103790:	89 90 28 a0 23 f0    	mov    %edx,-0xfdc5fd8(%eax)
	curenv->env_status = ENV_RUNNING;
f0103796:	e8 b3 29 00 00       	call   f010614e <cpunum>
f010379b:	6b c0 74             	imul   $0x74,%eax,%eax
f010379e:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f01037a4:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f01037ab:	e8 9e 29 00 00       	call   f010614e <cpunum>
f01037b0:	6b c0 74             	imul   $0x74,%eax,%eax
f01037b3:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f01037b9:	83 40 58 01          	addl   $0x1,0x58(%eax)
	// switch to user page directory
	lcr3(PADDR(curenv->env_pgdir));
f01037bd:	e8 8c 29 00 00       	call   f010614e <cpunum>
f01037c2:	6b c0 74             	imul   $0x74,%eax,%eax
f01037c5:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f01037cb:	8b 40 60             	mov    0x60(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01037ce:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01037d3:	76 47                	jbe    f010381c <env_run+0xc6>
	return (physaddr_t)kva - KERNBASE;
f01037d5:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01037da:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01037dd:	83 ec 0c             	sub    $0xc,%esp
f01037e0:	68 c0 33 12 f0       	push   $0xf01233c0
f01037e5:	e8 8a 2c 00 00       	call   f0106474 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01037ea:	f3 90                	pause  
	unlock_kernel();
	// step 2
	env_pop_tf(&curenv->env_tf);
f01037ec:	e8 5d 29 00 00       	call   f010614e <cpunum>
f01037f1:	83 c4 04             	add    $0x4,%esp
f01037f4:	6b c0 74             	imul   $0x74,%eax,%eax
f01037f7:	ff b0 28 a0 23 f0    	pushl  -0xfdc5fd8(%eax)
f01037fd:	e8 12 ff ff ff       	call   f0103714 <env_pop_tf>
			curenv->env_status = ENV_RUNNABLE;
f0103802:	e8 47 29 00 00       	call   f010614e <cpunum>
f0103807:	6b c0 74             	imul   $0x74,%eax,%eax
f010380a:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f0103810:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
f0103817:	e9 69 ff ff ff       	jmp    f0103785 <env_run+0x2f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010381c:	50                   	push   %eax
f010381d:	68 08 68 10 f0       	push   $0xf0106808
f0103822:	68 57 02 00 00       	push   $0x257
f0103827:	68 25 7b 10 f0       	push   $0xf0107b25
f010382c:	e8 0f c8 ff ff       	call   f0100040 <_panic>

f0103831 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103831:	f3 0f 1e fb          	endbr32 
f0103835:	55                   	push   %ebp
f0103836:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103838:	8b 45 08             	mov    0x8(%ebp),%eax
f010383b:	ba 70 00 00 00       	mov    $0x70,%edx
f0103840:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103841:	ba 71 00 00 00       	mov    $0x71,%edx
f0103846:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103847:	0f b6 c0             	movzbl %al,%eax
}
f010384a:	5d                   	pop    %ebp
f010384b:	c3                   	ret    

f010384c <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010384c:	f3 0f 1e fb          	endbr32 
f0103850:	55                   	push   %ebp
f0103851:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103853:	8b 45 08             	mov    0x8(%ebp),%eax
f0103856:	ba 70 00 00 00       	mov    $0x70,%edx
f010385b:	ee                   	out    %al,(%dx)
f010385c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010385f:	ba 71 00 00 00       	mov    $0x71,%edx
f0103864:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103865:	5d                   	pop    %ebp
f0103866:	c3                   	ret    

f0103867 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103867:	f3 0f 1e fb          	endbr32 
f010386b:	55                   	push   %ebp
f010386c:	89 e5                	mov    %esp,%ebp
f010386e:	56                   	push   %esi
f010386f:	53                   	push   %ebx
f0103870:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103873:	66 a3 a8 33 12 f0    	mov    %ax,0xf01233a8
	if (!didinit)
f0103879:	80 3d 50 92 23 f0 00 	cmpb   $0x0,0xf0239250
f0103880:	75 07                	jne    f0103889 <irq_setmask_8259A+0x22>
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
}
f0103882:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103885:	5b                   	pop    %ebx
f0103886:	5e                   	pop    %esi
f0103887:	5d                   	pop    %ebp
f0103888:	c3                   	ret    
f0103889:	89 c6                	mov    %eax,%esi
f010388b:	ba 21 00 00 00       	mov    $0x21,%edx
f0103890:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
f0103891:	66 c1 e8 08          	shr    $0x8,%ax
f0103895:	ba a1 00 00 00       	mov    $0xa1,%edx
f010389a:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f010389b:	83 ec 0c             	sub    $0xc,%esp
f010389e:	68 67 7b 10 f0       	push   $0xf0107b67
f01038a3:	e8 2c 01 00 00       	call   f01039d4 <cprintf>
f01038a8:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f01038ab:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f01038b0:	0f b7 f6             	movzwl %si,%esi
f01038b3:	f7 d6                	not    %esi
f01038b5:	eb 19                	jmp    f01038d0 <irq_setmask_8259A+0x69>
			cprintf(" %d", i);
f01038b7:	83 ec 08             	sub    $0x8,%esp
f01038ba:	53                   	push   %ebx
f01038bb:	68 3f 80 10 f0       	push   $0xf010803f
f01038c0:	e8 0f 01 00 00       	call   f01039d4 <cprintf>
f01038c5:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f01038c8:	83 c3 01             	add    $0x1,%ebx
f01038cb:	83 fb 10             	cmp    $0x10,%ebx
f01038ce:	74 07                	je     f01038d7 <irq_setmask_8259A+0x70>
		if (~mask & (1<<i))
f01038d0:	0f a3 de             	bt     %ebx,%esi
f01038d3:	73 f3                	jae    f01038c8 <irq_setmask_8259A+0x61>
f01038d5:	eb e0                	jmp    f01038b7 <irq_setmask_8259A+0x50>
	cprintf("\n");
f01038d7:	83 ec 0c             	sub    $0xc,%esp
f01038da:	68 fd 79 10 f0       	push   $0xf01079fd
f01038df:	e8 f0 00 00 00       	call   f01039d4 <cprintf>
f01038e4:	83 c4 10             	add    $0x10,%esp
f01038e7:	eb 99                	jmp    f0103882 <irq_setmask_8259A+0x1b>

f01038e9 <pic_init>:
{
f01038e9:	f3 0f 1e fb          	endbr32 
f01038ed:	55                   	push   %ebp
f01038ee:	89 e5                	mov    %esp,%ebp
f01038f0:	57                   	push   %edi
f01038f1:	56                   	push   %esi
f01038f2:	53                   	push   %ebx
f01038f3:	83 ec 0c             	sub    $0xc,%esp
	didinit = 1;
f01038f6:	c6 05 50 92 23 f0 01 	movb   $0x1,0xf0239250
f01038fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103902:	bb 21 00 00 00       	mov    $0x21,%ebx
f0103907:	89 da                	mov    %ebx,%edx
f0103909:	ee                   	out    %al,(%dx)
f010390a:	b9 a1 00 00 00       	mov    $0xa1,%ecx
f010390f:	89 ca                	mov    %ecx,%edx
f0103911:	ee                   	out    %al,(%dx)
f0103912:	bf 11 00 00 00       	mov    $0x11,%edi
f0103917:	be 20 00 00 00       	mov    $0x20,%esi
f010391c:	89 f8                	mov    %edi,%eax
f010391e:	89 f2                	mov    %esi,%edx
f0103920:	ee                   	out    %al,(%dx)
f0103921:	b8 20 00 00 00       	mov    $0x20,%eax
f0103926:	89 da                	mov    %ebx,%edx
f0103928:	ee                   	out    %al,(%dx)
f0103929:	b8 04 00 00 00       	mov    $0x4,%eax
f010392e:	ee                   	out    %al,(%dx)
f010392f:	b8 03 00 00 00       	mov    $0x3,%eax
f0103934:	ee                   	out    %al,(%dx)
f0103935:	bb a0 00 00 00       	mov    $0xa0,%ebx
f010393a:	89 f8                	mov    %edi,%eax
f010393c:	89 da                	mov    %ebx,%edx
f010393e:	ee                   	out    %al,(%dx)
f010393f:	b8 28 00 00 00       	mov    $0x28,%eax
f0103944:	89 ca                	mov    %ecx,%edx
f0103946:	ee                   	out    %al,(%dx)
f0103947:	b8 02 00 00 00       	mov    $0x2,%eax
f010394c:	ee                   	out    %al,(%dx)
f010394d:	b8 01 00 00 00       	mov    $0x1,%eax
f0103952:	ee                   	out    %al,(%dx)
f0103953:	bf 68 00 00 00       	mov    $0x68,%edi
f0103958:	89 f8                	mov    %edi,%eax
f010395a:	89 f2                	mov    %esi,%edx
f010395c:	ee                   	out    %al,(%dx)
f010395d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103962:	89 c8                	mov    %ecx,%eax
f0103964:	ee                   	out    %al,(%dx)
f0103965:	89 f8                	mov    %edi,%eax
f0103967:	89 da                	mov    %ebx,%edx
f0103969:	ee                   	out    %al,(%dx)
f010396a:	89 c8                	mov    %ecx,%eax
f010396c:	ee                   	out    %al,(%dx)
	if (irq_mask_8259A != 0xFFFF)
f010396d:	0f b7 05 a8 33 12 f0 	movzwl 0xf01233a8,%eax
f0103974:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103978:	75 08                	jne    f0103982 <pic_init+0x99>
}
f010397a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010397d:	5b                   	pop    %ebx
f010397e:	5e                   	pop    %esi
f010397f:	5f                   	pop    %edi
f0103980:	5d                   	pop    %ebp
f0103981:	c3                   	ret    
		irq_setmask_8259A(irq_mask_8259A);
f0103982:	83 ec 0c             	sub    $0xc,%esp
f0103985:	0f b7 c0             	movzwl %ax,%eax
f0103988:	50                   	push   %eax
f0103989:	e8 d9 fe ff ff       	call   f0103867 <irq_setmask_8259A>
f010398e:	83 c4 10             	add    $0x10,%esp
}
f0103991:	eb e7                	jmp    f010397a <pic_init+0x91>

f0103993 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103993:	f3 0f 1e fb          	endbr32 
f0103997:	55                   	push   %ebp
f0103998:	89 e5                	mov    %esp,%ebp
f010399a:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010399d:	ff 75 08             	pushl  0x8(%ebp)
f01039a0:	e8 e4 cd ff ff       	call   f0100789 <cputchar>
	*cnt++;
}
f01039a5:	83 c4 10             	add    $0x10,%esp
f01039a8:	c9                   	leave  
f01039a9:	c3                   	ret    

f01039aa <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01039aa:	f3 0f 1e fb          	endbr32 
f01039ae:	55                   	push   %ebp
f01039af:	89 e5                	mov    %esp,%ebp
f01039b1:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01039b4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01039bb:	ff 75 0c             	pushl  0xc(%ebp)
f01039be:	ff 75 08             	pushl  0x8(%ebp)
f01039c1:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01039c4:	50                   	push   %eax
f01039c5:	68 93 39 10 f0       	push   $0xf0103993
f01039ca:	e8 0a 1a 00 00       	call   f01053d9 <vprintfmt>
	return cnt;
}
f01039cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01039d2:	c9                   	leave  
f01039d3:	c3                   	ret    

f01039d4 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01039d4:	f3 0f 1e fb          	endbr32 
f01039d8:	55                   	push   %ebp
f01039d9:	89 e5                	mov    %esp,%ebp
f01039db:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01039de:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01039e1:	50                   	push   %eax
f01039e2:	ff 75 08             	pushl  0x8(%ebp)
f01039e5:	e8 c0 ff ff ff       	call   f01039aa <vcprintf>
	va_end(ap);

	return cnt;
}
f01039ea:	c9                   	leave  
f01039eb:	c3                   	ret    

f01039ec <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01039ec:	f3 0f 1e fb          	endbr32 
f01039f0:	55                   	push   %ebp
f01039f1:	89 e5                	mov    %esp,%ebp
f01039f3:	57                   	push   %edi
f01039f4:	56                   	push   %esi
f01039f5:	53                   	push   %ebx
f01039f6:	83 ec 1c             	sub    $0x1c,%esp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	uint8_t id = thiscpu->cpu_id;
f01039f9:	e8 50 27 00 00       	call   f010614e <cpunum>
f01039fe:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a01:	0f b6 b8 20 a0 23 f0 	movzbl -0xfdc5fe0(%eax),%edi
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP-id*(KSTKSIZE+KSTKGAP);
f0103a08:	89 f8                	mov    %edi,%eax
f0103a0a:	0f b6 d8             	movzbl %al,%ebx
f0103a0d:	e8 3c 27 00 00       	call   f010614e <cpunum>
f0103a12:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a15:	89 d9                	mov    %ebx,%ecx
f0103a17:	c1 e1 10             	shl    $0x10,%ecx
f0103a1a:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0103a1f:	29 ca                	sub    %ecx,%edx
f0103a21:	89 90 30 a0 23 f0    	mov    %edx,-0xfdc5fd0(%eax)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f0103a27:	e8 22 27 00 00       	call   f010614e <cpunum>
f0103a2c:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a2f:	66 c7 80 34 a0 23 f0 	movw   $0x10,-0xfdc5fcc(%eax)
f0103a36:	10 00 
	thiscpu->cpu_ts.ts_iomb = sizeof(struct Taskstate);
f0103a38:	e8 11 27 00 00       	call   f010614e <cpunum>
f0103a3d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a40:	66 c7 80 92 a0 23 f0 	movw   $0x68,-0xfdc5f6e(%eax)
f0103a47:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+id] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
f0103a49:	83 c3 05             	add    $0x5,%ebx
f0103a4c:	e8 fd 26 00 00       	call   f010614e <cpunum>
f0103a51:	89 c6                	mov    %eax,%esi
f0103a53:	e8 f6 26 00 00       	call   f010614e <cpunum>
f0103a58:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103a5b:	e8 ee 26 00 00       	call   f010614e <cpunum>
f0103a60:	66 c7 04 dd 40 33 12 	movw   $0x67,-0xfedccc0(,%ebx,8)
f0103a67:	f0 67 00 
f0103a6a:	6b f6 74             	imul   $0x74,%esi,%esi
f0103a6d:	81 c6 2c a0 23 f0    	add    $0xf023a02c,%esi
f0103a73:	66 89 34 dd 42 33 12 	mov    %si,-0xfedccbe(,%ebx,8)
f0103a7a:	f0 
f0103a7b:	6b 55 e4 74          	imul   $0x74,-0x1c(%ebp),%edx
f0103a7f:	81 c2 2c a0 23 f0    	add    $0xf023a02c,%edx
f0103a85:	c1 ea 10             	shr    $0x10,%edx
f0103a88:	88 14 dd 44 33 12 f0 	mov    %dl,-0xfedccbc(,%ebx,8)
f0103a8f:	c6 04 dd 46 33 12 f0 	movb   $0x40,-0xfedccba(,%ebx,8)
f0103a96:	40 
f0103a97:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a9a:	05 2c a0 23 f0       	add    $0xf023a02c,%eax
f0103a9f:	c1 e8 18             	shr    $0x18,%eax
f0103aa2:	88 04 dd 47 33 12 f0 	mov    %al,-0xfedccb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3)+id].sd_s = 0;
f0103aa9:	c6 04 dd 45 33 12 f0 	movb   $0x89,-0xfedccbb(,%ebx,8)
f0103ab0:	89 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0+(id<<3));
f0103ab1:	89 f8                	mov    %edi,%eax
f0103ab3:	0f b6 f8             	movzbl %al,%edi
f0103ab6:	8d 3c fd 28 00 00 00 	lea    0x28(,%edi,8),%edi
	asm volatile("ltr %0" : : "r" (sel));
f0103abd:	0f 00 df             	ltr    %di
	asm volatile("lidt (%0)" : : "r" (p));
f0103ac0:	b8 ac 33 12 f0       	mov    $0xf01233ac,%eax
f0103ac5:	0f 01 18             	lidtl  (%eax)

	// Load the IDT
	lidt(&idt_pd);
}
f0103ac8:	83 c4 1c             	add    $0x1c,%esp
f0103acb:	5b                   	pop    %ebx
f0103acc:	5e                   	pop    %esi
f0103acd:	5f                   	pop    %edi
f0103ace:	5d                   	pop    %ebp
f0103acf:	c3                   	ret    

f0103ad0 <trap_init>:
{
f0103ad0:	f3 0f 1e fb          	endbr32 
f0103ad4:	55                   	push   %ebp
f0103ad5:	89 e5                	mov    %esp,%ebp
f0103ad7:	83 ec 08             	sub    $0x8,%esp
    SETGATE(idt[T_DIVIDE], 0, GD_KT, DIVIDE, 0);
f0103ada:	b8 7e 46 10 f0       	mov    $0xf010467e,%eax
f0103adf:	66 a3 60 92 23 f0    	mov    %ax,0xf0239260
f0103ae5:	66 c7 05 62 92 23 f0 	movw   $0x8,0xf0239262
f0103aec:	08 00 
f0103aee:	c6 05 64 92 23 f0 00 	movb   $0x0,0xf0239264
f0103af5:	c6 05 65 92 23 f0 8e 	movb   $0x8e,0xf0239265
f0103afc:	c1 e8 10             	shr    $0x10,%eax
f0103aff:	66 a3 66 92 23 f0    	mov    %ax,0xf0239266
	SETGATE(idt[T_DEBUG], 0, GD_KT, DEBUG, 0);
f0103b05:	b8 88 46 10 f0       	mov    $0xf0104688,%eax
f0103b0a:	66 a3 68 92 23 f0    	mov    %ax,0xf0239268
f0103b10:	66 c7 05 6a 92 23 f0 	movw   $0x8,0xf023926a
f0103b17:	08 00 
f0103b19:	c6 05 6c 92 23 f0 00 	movb   $0x0,0xf023926c
f0103b20:	c6 05 6d 92 23 f0 8e 	movb   $0x8e,0xf023926d
f0103b27:	c1 e8 10             	shr    $0x10,%eax
f0103b2a:	66 a3 6e 92 23 f0    	mov    %ax,0xf023926e
	SETGATE(idt[T_NMI], 0, GD_KT, NMI, 0);
f0103b30:	b8 92 46 10 f0       	mov    $0xf0104692,%eax
f0103b35:	66 a3 70 92 23 f0    	mov    %ax,0xf0239270
f0103b3b:	66 c7 05 72 92 23 f0 	movw   $0x8,0xf0239272
f0103b42:	08 00 
f0103b44:	c6 05 74 92 23 f0 00 	movb   $0x0,0xf0239274
f0103b4b:	c6 05 75 92 23 f0 8e 	movb   $0x8e,0xf0239275
f0103b52:	c1 e8 10             	shr    $0x10,%eax
f0103b55:	66 a3 76 92 23 f0    	mov    %ax,0xf0239276
	SETGATE(idt[T_BRKPT], 0, GD_KT, BRKPT, 3);
f0103b5b:	b8 9c 46 10 f0       	mov    $0xf010469c,%eax
f0103b60:	66 a3 78 92 23 f0    	mov    %ax,0xf0239278
f0103b66:	66 c7 05 7a 92 23 f0 	movw   $0x8,0xf023927a
f0103b6d:	08 00 
f0103b6f:	c6 05 7c 92 23 f0 00 	movb   $0x0,0xf023927c
f0103b76:	c6 05 7d 92 23 f0 ee 	movb   $0xee,0xf023927d
f0103b7d:	c1 e8 10             	shr    $0x10,%eax
f0103b80:	66 a3 7e 92 23 f0    	mov    %ax,0xf023927e
	SETGATE(idt[T_OFLOW], 0, GD_KT, OFLOW, 0);
f0103b86:	b8 a6 46 10 f0       	mov    $0xf01046a6,%eax
f0103b8b:	66 a3 80 92 23 f0    	mov    %ax,0xf0239280
f0103b91:	66 c7 05 82 92 23 f0 	movw   $0x8,0xf0239282
f0103b98:	08 00 
f0103b9a:	c6 05 84 92 23 f0 00 	movb   $0x0,0xf0239284
f0103ba1:	c6 05 85 92 23 f0 8e 	movb   $0x8e,0xf0239285
f0103ba8:	c1 e8 10             	shr    $0x10,%eax
f0103bab:	66 a3 86 92 23 f0    	mov    %ax,0xf0239286
	SETGATE(idt[T_BOUND], 0, GD_KT, BOUND, 0);
f0103bb1:	b8 b0 46 10 f0       	mov    $0xf01046b0,%eax
f0103bb6:	66 a3 88 92 23 f0    	mov    %ax,0xf0239288
f0103bbc:	66 c7 05 8a 92 23 f0 	movw   $0x8,0xf023928a
f0103bc3:	08 00 
f0103bc5:	c6 05 8c 92 23 f0 00 	movb   $0x0,0xf023928c
f0103bcc:	c6 05 8d 92 23 f0 8e 	movb   $0x8e,0xf023928d
f0103bd3:	c1 e8 10             	shr    $0x10,%eax
f0103bd6:	66 a3 8e 92 23 f0    	mov    %ax,0xf023928e
	SETGATE(idt[T_ILLOP], 0, GD_KT, ILLOP, 0);
f0103bdc:	b8 ba 46 10 f0       	mov    $0xf01046ba,%eax
f0103be1:	66 a3 90 92 23 f0    	mov    %ax,0xf0239290
f0103be7:	66 c7 05 92 92 23 f0 	movw   $0x8,0xf0239292
f0103bee:	08 00 
f0103bf0:	c6 05 94 92 23 f0 00 	movb   $0x0,0xf0239294
f0103bf7:	c6 05 95 92 23 f0 8e 	movb   $0x8e,0xf0239295
f0103bfe:	c1 e8 10             	shr    $0x10,%eax
f0103c01:	66 a3 96 92 23 f0    	mov    %ax,0xf0239296
	SETGATE(idt[T_DEVICE], 0, GD_KT, DEVICE, 0);
f0103c07:	b8 c4 46 10 f0       	mov    $0xf01046c4,%eax
f0103c0c:	66 a3 98 92 23 f0    	mov    %ax,0xf0239298
f0103c12:	66 c7 05 9a 92 23 f0 	movw   $0x8,0xf023929a
f0103c19:	08 00 
f0103c1b:	c6 05 9c 92 23 f0 00 	movb   $0x0,0xf023929c
f0103c22:	c6 05 9d 92 23 f0 8e 	movb   $0x8e,0xf023929d
f0103c29:	c1 e8 10             	shr    $0x10,%eax
f0103c2c:	66 a3 9e 92 23 f0    	mov    %ax,0xf023929e
	SETGATE(idt[T_DBLFLT], 0, GD_KT, DBLFLT, 0);
f0103c32:	b8 ce 46 10 f0       	mov    $0xf01046ce,%eax
f0103c37:	66 a3 a0 92 23 f0    	mov    %ax,0xf02392a0
f0103c3d:	66 c7 05 a2 92 23 f0 	movw   $0x8,0xf02392a2
f0103c44:	08 00 
f0103c46:	c6 05 a4 92 23 f0 00 	movb   $0x0,0xf02392a4
f0103c4d:	c6 05 a5 92 23 f0 8e 	movb   $0x8e,0xf02392a5
f0103c54:	c1 e8 10             	shr    $0x10,%eax
f0103c57:	66 a3 a6 92 23 f0    	mov    %ax,0xf02392a6
	SETGATE(idt[T_TSS], 0, GD_KT, TSS, 0);
f0103c5d:	b8 d6 46 10 f0       	mov    $0xf01046d6,%eax
f0103c62:	66 a3 b0 92 23 f0    	mov    %ax,0xf02392b0
f0103c68:	66 c7 05 b2 92 23 f0 	movw   $0x8,0xf02392b2
f0103c6f:	08 00 
f0103c71:	c6 05 b4 92 23 f0 00 	movb   $0x0,0xf02392b4
f0103c78:	c6 05 b5 92 23 f0 8e 	movb   $0x8e,0xf02392b5
f0103c7f:	c1 e8 10             	shr    $0x10,%eax
f0103c82:	66 a3 b6 92 23 f0    	mov    %ax,0xf02392b6
	SETGATE(idt[T_SEGNP], 0, GD_KT, SEGNP, 0);
f0103c88:	b8 de 46 10 f0       	mov    $0xf01046de,%eax
f0103c8d:	66 a3 b8 92 23 f0    	mov    %ax,0xf02392b8
f0103c93:	66 c7 05 ba 92 23 f0 	movw   $0x8,0xf02392ba
f0103c9a:	08 00 
f0103c9c:	c6 05 bc 92 23 f0 00 	movb   $0x0,0xf02392bc
f0103ca3:	c6 05 bd 92 23 f0 8e 	movb   $0x8e,0xf02392bd
f0103caa:	c1 e8 10             	shr    $0x10,%eax
f0103cad:	66 a3 be 92 23 f0    	mov    %ax,0xf02392be
	SETGATE(idt[T_STACK], 0, GD_KT, STACK, 0);
f0103cb3:	b8 e6 46 10 f0       	mov    $0xf01046e6,%eax
f0103cb8:	66 a3 c0 92 23 f0    	mov    %ax,0xf02392c0
f0103cbe:	66 c7 05 c2 92 23 f0 	movw   $0x8,0xf02392c2
f0103cc5:	08 00 
f0103cc7:	c6 05 c4 92 23 f0 00 	movb   $0x0,0xf02392c4
f0103cce:	c6 05 c5 92 23 f0 8e 	movb   $0x8e,0xf02392c5
f0103cd5:	c1 e8 10             	shr    $0x10,%eax
f0103cd8:	66 a3 c6 92 23 f0    	mov    %ax,0xf02392c6
	SETGATE(idt[T_GPFLT], 0, GD_KT, GPFLT, 0);
f0103cde:	b8 ee 46 10 f0       	mov    $0xf01046ee,%eax
f0103ce3:	66 a3 c8 92 23 f0    	mov    %ax,0xf02392c8
f0103ce9:	66 c7 05 ca 92 23 f0 	movw   $0x8,0xf02392ca
f0103cf0:	08 00 
f0103cf2:	c6 05 cc 92 23 f0 00 	movb   $0x0,0xf02392cc
f0103cf9:	c6 05 cd 92 23 f0 8e 	movb   $0x8e,0xf02392cd
f0103d00:	c1 e8 10             	shr    $0x10,%eax
f0103d03:	66 a3 ce 92 23 f0    	mov    %ax,0xf02392ce
	SETGATE(idt[T_PGFLT], 0, GD_KT, PGFLT, 0);
f0103d09:	b8 f6 46 10 f0       	mov    $0xf01046f6,%eax
f0103d0e:	66 a3 d0 92 23 f0    	mov    %ax,0xf02392d0
f0103d14:	66 c7 05 d2 92 23 f0 	movw   $0x8,0xf02392d2
f0103d1b:	08 00 
f0103d1d:	c6 05 d4 92 23 f0 00 	movb   $0x0,0xf02392d4
f0103d24:	c6 05 d5 92 23 f0 8e 	movb   $0x8e,0xf02392d5
f0103d2b:	c1 e8 10             	shr    $0x10,%eax
f0103d2e:	66 a3 d6 92 23 f0    	mov    %ax,0xf02392d6
	SETGATE(idt[T_FPERR], 0, GD_KT, FPERR, 0);
f0103d34:	b8 fe 46 10 f0       	mov    $0xf01046fe,%eax
f0103d39:	66 a3 e0 92 23 f0    	mov    %ax,0xf02392e0
f0103d3f:	66 c7 05 e2 92 23 f0 	movw   $0x8,0xf02392e2
f0103d46:	08 00 
f0103d48:	c6 05 e4 92 23 f0 00 	movb   $0x0,0xf02392e4
f0103d4f:	c6 05 e5 92 23 f0 8e 	movb   $0x8e,0xf02392e5
f0103d56:	c1 e8 10             	shr    $0x10,%eax
f0103d59:	66 a3 e6 92 23 f0    	mov    %ax,0xf02392e6
	SETGATE(idt[T_ALIGN], 0, GD_KT, ALIGN, 0);
f0103d5f:	b8 08 47 10 f0       	mov    $0xf0104708,%eax
f0103d64:	66 a3 e8 92 23 f0    	mov    %ax,0xf02392e8
f0103d6a:	66 c7 05 ea 92 23 f0 	movw   $0x8,0xf02392ea
f0103d71:	08 00 
f0103d73:	c6 05 ec 92 23 f0 00 	movb   $0x0,0xf02392ec
f0103d7a:	c6 05 ed 92 23 f0 8e 	movb   $0x8e,0xf02392ed
f0103d81:	c1 e8 10             	shr    $0x10,%eax
f0103d84:	66 a3 ee 92 23 f0    	mov    %ax,0xf02392ee
	SETGATE(idt[T_MCHK], 0, GD_KT, MCHK, 0);
f0103d8a:	b8 10 47 10 f0       	mov    $0xf0104710,%eax
f0103d8f:	66 a3 f0 92 23 f0    	mov    %ax,0xf02392f0
f0103d95:	66 c7 05 f2 92 23 f0 	movw   $0x8,0xf02392f2
f0103d9c:	08 00 
f0103d9e:	c6 05 f4 92 23 f0 00 	movb   $0x0,0xf02392f4
f0103da5:	c6 05 f5 92 23 f0 8e 	movb   $0x8e,0xf02392f5
f0103dac:	c1 e8 10             	shr    $0x10,%eax
f0103daf:	66 a3 f6 92 23 f0    	mov    %ax,0xf02392f6
	SETGATE(idt[T_SIMDERR], 0, GD_KT, SIMDERR, 0);
f0103db5:	b8 16 47 10 f0       	mov    $0xf0104716,%eax
f0103dba:	66 a3 f8 92 23 f0    	mov    %ax,0xf02392f8
f0103dc0:	66 c7 05 fa 92 23 f0 	movw   $0x8,0xf02392fa
f0103dc7:	08 00 
f0103dc9:	c6 05 fc 92 23 f0 00 	movb   $0x0,0xf02392fc
f0103dd0:	c6 05 fd 92 23 f0 8e 	movb   $0x8e,0xf02392fd
f0103dd7:	c1 e8 10             	shr    $0x10,%eax
f0103dda:	66 a3 fe 92 23 f0    	mov    %ax,0xf02392fe
	SETGATE(idt[T_SYSCALL], 0, GD_KT, SYSCALL, 3);
f0103de0:	b8 1c 47 10 f0       	mov    $0xf010471c,%eax
f0103de5:	66 a3 e0 93 23 f0    	mov    %ax,0xf02393e0
f0103deb:	66 c7 05 e2 93 23 f0 	movw   $0x8,0xf02393e2
f0103df2:	08 00 
f0103df4:	c6 05 e4 93 23 f0 00 	movb   $0x0,0xf02393e4
f0103dfb:	c6 05 e5 93 23 f0 ee 	movb   $0xee,0xf02393e5
f0103e02:	c1 e8 10             	shr    $0x10,%eax
f0103e05:	66 a3 e6 93 23 f0    	mov    %ax,0xf02393e6
	SETGATE(idt[T_DEFAULT], 0, GD_KT, DEFAULT, 0);
f0103e0b:	b8 22 47 10 f0       	mov    $0xf0104722,%eax
f0103e10:	66 a3 00 a2 23 f0    	mov    %ax,0xf023a200
f0103e16:	66 c7 05 02 a2 23 f0 	movw   $0x8,0xf023a202
f0103e1d:	08 00 
f0103e1f:	c6 05 04 a2 23 f0 00 	movb   $0x0,0xf023a204
f0103e26:	c6 05 05 a2 23 f0 8e 	movb   $0x8e,0xf023a205
f0103e2d:	c1 e8 10             	shr    $0x10,%eax
f0103e30:	66 a3 06 a2 23 f0    	mov    %ax,0xf023a206
	SETGATE(idt[IRQ_OFFSET+IRQ_TIMER],0,GD_KT,IRQsHandler0,0);
f0103e36:	b8 2c 47 10 f0       	mov    $0xf010472c,%eax
f0103e3b:	66 a3 60 93 23 f0    	mov    %ax,0xf0239360
f0103e41:	66 c7 05 62 93 23 f0 	movw   $0x8,0xf0239362
f0103e48:	08 00 
f0103e4a:	c6 05 64 93 23 f0 00 	movb   $0x0,0xf0239364
f0103e51:	c6 05 65 93 23 f0 8e 	movb   $0x8e,0xf0239365
f0103e58:	c1 e8 10             	shr    $0x10,%eax
f0103e5b:	66 a3 66 93 23 f0    	mov    %ax,0xf0239366
	SETGATE(idt[IRQ_OFFSET+IRQ_KBD],0,GD_KT,IRQsHandler1,0);
f0103e61:	ba 32 47 10 f0       	mov    $0xf0104732,%edx
f0103e66:	66 89 15 68 93 23 f0 	mov    %dx,0xf0239368
f0103e6d:	66 c7 05 6a 93 23 f0 	movw   $0x8,0xf023936a
f0103e74:	08 00 
f0103e76:	c6 05 6c 93 23 f0 00 	movb   $0x0,0xf023936c
f0103e7d:	c6 05 6d 93 23 f0 8e 	movb   $0x8e,0xf023936d
f0103e84:	89 d1                	mov    %edx,%ecx
f0103e86:	c1 e9 10             	shr    $0x10,%ecx
f0103e89:	66 89 0d 6e 93 23 f0 	mov    %cx,0xf023936e
	SETGATE(idt[IRQ_OFFSET+IRQ_SLAVE],0,GD_KT,IRQsHandler2,0);
f0103e90:	b8 38 47 10 f0       	mov    $0xf0104738,%eax
f0103e95:	66 a3 70 93 23 f0    	mov    %ax,0xf0239370
f0103e9b:	66 c7 05 72 93 23 f0 	movw   $0x8,0xf0239372
f0103ea2:	08 00 
f0103ea4:	c6 05 74 93 23 f0 00 	movb   $0x0,0xf0239374
f0103eab:	c6 05 75 93 23 f0 8e 	movb   $0x8e,0xf0239375
f0103eb2:	c1 e8 10             	shr    $0x10,%eax
f0103eb5:	66 a3 76 93 23 f0    	mov    %ax,0xf0239376
	SETGATE(idt[IRQ_OFFSET+3],0,GD_KT,IRQsHandler1,0);
f0103ebb:	66 89 15 78 93 23 f0 	mov    %dx,0xf0239378
f0103ec2:	66 c7 05 7a 93 23 f0 	movw   $0x8,0xf023937a
f0103ec9:	08 00 
f0103ecb:	c6 05 7c 93 23 f0 00 	movb   $0x0,0xf023937c
f0103ed2:	c6 05 7d 93 23 f0 8e 	movb   $0x8e,0xf023937d
f0103ed9:	66 89 0d 7e 93 23 f0 	mov    %cx,0xf023937e
	SETGATE(idt[IRQ_OFFSET+IRQ_SERIAL],0,GD_KT,IRQsHandler4,0);
f0103ee0:	b8 44 47 10 f0       	mov    $0xf0104744,%eax
f0103ee5:	66 a3 80 93 23 f0    	mov    %ax,0xf0239380
f0103eeb:	66 c7 05 82 93 23 f0 	movw   $0x8,0xf0239382
f0103ef2:	08 00 
f0103ef4:	c6 05 84 93 23 f0 00 	movb   $0x0,0xf0239384
f0103efb:	c6 05 85 93 23 f0 8e 	movb   $0x8e,0xf0239385
f0103f02:	c1 e8 10             	shr    $0x10,%eax
f0103f05:	66 a3 86 93 23 f0    	mov    %ax,0xf0239386
	SETGATE(idt[IRQ_OFFSET+5],0,GD_KT,IRQsHandler5,0);
f0103f0b:	b8 4a 47 10 f0       	mov    $0xf010474a,%eax
f0103f10:	66 a3 88 93 23 f0    	mov    %ax,0xf0239388
f0103f16:	66 c7 05 8a 93 23 f0 	movw   $0x8,0xf023938a
f0103f1d:	08 00 
f0103f1f:	c6 05 8c 93 23 f0 00 	movb   $0x0,0xf023938c
f0103f26:	c6 05 8d 93 23 f0 8e 	movb   $0x8e,0xf023938d
f0103f2d:	c1 e8 10             	shr    $0x10,%eax
f0103f30:	66 a3 8e 93 23 f0    	mov    %ax,0xf023938e
	SETGATE(idt[IRQ_OFFSET+6],0,GD_KT,IRQsHandler6,0);
f0103f36:	b8 50 47 10 f0       	mov    $0xf0104750,%eax
f0103f3b:	66 a3 90 93 23 f0    	mov    %ax,0xf0239390
f0103f41:	66 c7 05 92 93 23 f0 	movw   $0x8,0xf0239392
f0103f48:	08 00 
f0103f4a:	c6 05 94 93 23 f0 00 	movb   $0x0,0xf0239394
f0103f51:	c6 05 95 93 23 f0 8e 	movb   $0x8e,0xf0239395
f0103f58:	c1 e8 10             	shr    $0x10,%eax
f0103f5b:	66 a3 96 93 23 f0    	mov    %ax,0xf0239396
	SETGATE(idt[IRQ_OFFSET+IRQ_SPURIOUS],0,GD_KT,IRQsHandler7,0);
f0103f61:	b8 56 47 10 f0       	mov    $0xf0104756,%eax
f0103f66:	66 a3 98 93 23 f0    	mov    %ax,0xf0239398
f0103f6c:	66 c7 05 9a 93 23 f0 	movw   $0x8,0xf023939a
f0103f73:	08 00 
f0103f75:	c6 05 9c 93 23 f0 00 	movb   $0x0,0xf023939c
f0103f7c:	c6 05 9d 93 23 f0 8e 	movb   $0x8e,0xf023939d
f0103f83:	c1 e8 10             	shr    $0x10,%eax
f0103f86:	66 a3 9e 93 23 f0    	mov    %ax,0xf023939e
	SETGATE(idt[IRQ_OFFSET+8],0,GD_KT,IRQsHandler8,0);
f0103f8c:	b8 5c 47 10 f0       	mov    $0xf010475c,%eax
f0103f91:	66 a3 a0 93 23 f0    	mov    %ax,0xf02393a0
f0103f97:	66 c7 05 a2 93 23 f0 	movw   $0x8,0xf02393a2
f0103f9e:	08 00 
f0103fa0:	c6 05 a4 93 23 f0 00 	movb   $0x0,0xf02393a4
f0103fa7:	c6 05 a5 93 23 f0 8e 	movb   $0x8e,0xf02393a5
f0103fae:	c1 e8 10             	shr    $0x10,%eax
f0103fb1:	66 a3 a6 93 23 f0    	mov    %ax,0xf02393a6
	SETGATE(idt[IRQ_OFFSET+9],0,GD_KT,IRQsHandler9,0);
f0103fb7:	b8 62 47 10 f0       	mov    $0xf0104762,%eax
f0103fbc:	66 a3 a8 93 23 f0    	mov    %ax,0xf02393a8
f0103fc2:	66 c7 05 aa 93 23 f0 	movw   $0x8,0xf02393aa
f0103fc9:	08 00 
f0103fcb:	c6 05 ac 93 23 f0 00 	movb   $0x0,0xf02393ac
f0103fd2:	c6 05 ad 93 23 f0 8e 	movb   $0x8e,0xf02393ad
f0103fd9:	c1 e8 10             	shr    $0x10,%eax
f0103fdc:	66 a3 ae 93 23 f0    	mov    %ax,0xf02393ae
	SETGATE(idt[IRQ_OFFSET+10],0,GD_KT,IRQsHandler10,0);
f0103fe2:	b8 68 47 10 f0       	mov    $0xf0104768,%eax
f0103fe7:	66 a3 b0 93 23 f0    	mov    %ax,0xf02393b0
f0103fed:	66 c7 05 b2 93 23 f0 	movw   $0x8,0xf02393b2
f0103ff4:	08 00 
f0103ff6:	c6 05 b4 93 23 f0 00 	movb   $0x0,0xf02393b4
f0103ffd:	c6 05 b5 93 23 f0 8e 	movb   $0x8e,0xf02393b5
f0104004:	c1 e8 10             	shr    $0x10,%eax
f0104007:	66 a3 b6 93 23 f0    	mov    %ax,0xf02393b6
	SETGATE(idt[IRQ_OFFSET+11],0,GD_KT,IRQsHandler11,0);
f010400d:	b8 6e 47 10 f0       	mov    $0xf010476e,%eax
f0104012:	66 a3 b8 93 23 f0    	mov    %ax,0xf02393b8
f0104018:	66 c7 05 ba 93 23 f0 	movw   $0x8,0xf02393ba
f010401f:	08 00 
f0104021:	c6 05 bc 93 23 f0 00 	movb   $0x0,0xf02393bc
f0104028:	c6 05 bd 93 23 f0 8e 	movb   $0x8e,0xf02393bd
f010402f:	c1 e8 10             	shr    $0x10,%eax
f0104032:	66 a3 be 93 23 f0    	mov    %ax,0xf02393be
	SETGATE(idt[IRQ_OFFSET+12],0,GD_KT,IRQsHandler12,0);
f0104038:	b8 74 47 10 f0       	mov    $0xf0104774,%eax
f010403d:	66 a3 c0 93 23 f0    	mov    %ax,0xf02393c0
f0104043:	66 c7 05 c2 93 23 f0 	movw   $0x8,0xf02393c2
f010404a:	08 00 
f010404c:	c6 05 c4 93 23 f0 00 	movb   $0x0,0xf02393c4
f0104053:	c6 05 c5 93 23 f0 8e 	movb   $0x8e,0xf02393c5
f010405a:	c1 e8 10             	shr    $0x10,%eax
f010405d:	66 a3 c6 93 23 f0    	mov    %ax,0xf02393c6
	SETGATE(idt[IRQ_OFFSET+13],0,GD_KT,IRQsHandler13,0);
f0104063:	b8 7a 47 10 f0       	mov    $0xf010477a,%eax
f0104068:	66 a3 c8 93 23 f0    	mov    %ax,0xf02393c8
f010406e:	66 c7 05 ca 93 23 f0 	movw   $0x8,0xf02393ca
f0104075:	08 00 
f0104077:	c6 05 cc 93 23 f0 00 	movb   $0x0,0xf02393cc
f010407e:	c6 05 cd 93 23 f0 8e 	movb   $0x8e,0xf02393cd
f0104085:	c1 e8 10             	shr    $0x10,%eax
f0104088:	66 a3 ce 93 23 f0    	mov    %ax,0xf02393ce
	SETGATE(idt[IRQ_OFFSET+IRQ_IDE],0,GD_KT,IRQsHandler14,0);
f010408e:	b8 80 47 10 f0       	mov    $0xf0104780,%eax
f0104093:	66 a3 d0 93 23 f0    	mov    %ax,0xf02393d0
f0104099:	66 c7 05 d2 93 23 f0 	movw   $0x8,0xf02393d2
f01040a0:	08 00 
f01040a2:	c6 05 d4 93 23 f0 00 	movb   $0x0,0xf02393d4
f01040a9:	c6 05 d5 93 23 f0 8e 	movb   $0x8e,0xf02393d5
f01040b0:	c1 e8 10             	shr    $0x10,%eax
f01040b3:	66 a3 d6 93 23 f0    	mov    %ax,0xf02393d6
	SETGATE(idt[IRQ_OFFSET+15],0,GD_KT,IRQsHandler15,0);
f01040b9:	b8 86 47 10 f0       	mov    $0xf0104786,%eax
f01040be:	66 a3 d8 93 23 f0    	mov    %ax,0xf02393d8
f01040c4:	66 c7 05 da 93 23 f0 	movw   $0x8,0xf02393da
f01040cb:	08 00 
f01040cd:	c6 05 dc 93 23 f0 00 	movb   $0x0,0xf02393dc
f01040d4:	c6 05 dd 93 23 f0 8e 	movb   $0x8e,0xf02393dd
f01040db:	c1 e8 10             	shr    $0x10,%eax
f01040de:	66 a3 de 93 23 f0    	mov    %ax,0xf02393de
	trap_init_percpu();
f01040e4:	e8 03 f9 ff ff       	call   f01039ec <trap_init_percpu>
}
f01040e9:	c9                   	leave  
f01040ea:	c3                   	ret    

f01040eb <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01040eb:	f3 0f 1e fb          	endbr32 
f01040ef:	55                   	push   %ebp
f01040f0:	89 e5                	mov    %esp,%ebp
f01040f2:	53                   	push   %ebx
f01040f3:	83 ec 0c             	sub    $0xc,%esp
f01040f6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01040f9:	ff 33                	pushl  (%ebx)
f01040fb:	68 7b 7b 10 f0       	push   $0xf0107b7b
f0104100:	e8 cf f8 ff ff       	call   f01039d4 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0104105:	83 c4 08             	add    $0x8,%esp
f0104108:	ff 73 04             	pushl  0x4(%ebx)
f010410b:	68 8a 7b 10 f0       	push   $0xf0107b8a
f0104110:	e8 bf f8 ff ff       	call   f01039d4 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0104115:	83 c4 08             	add    $0x8,%esp
f0104118:	ff 73 08             	pushl  0x8(%ebx)
f010411b:	68 99 7b 10 f0       	push   $0xf0107b99
f0104120:	e8 af f8 ff ff       	call   f01039d4 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0104125:	83 c4 08             	add    $0x8,%esp
f0104128:	ff 73 0c             	pushl  0xc(%ebx)
f010412b:	68 a8 7b 10 f0       	push   $0xf0107ba8
f0104130:	e8 9f f8 ff ff       	call   f01039d4 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0104135:	83 c4 08             	add    $0x8,%esp
f0104138:	ff 73 10             	pushl  0x10(%ebx)
f010413b:	68 b7 7b 10 f0       	push   $0xf0107bb7
f0104140:	e8 8f f8 ff ff       	call   f01039d4 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0104145:	83 c4 08             	add    $0x8,%esp
f0104148:	ff 73 14             	pushl  0x14(%ebx)
f010414b:	68 c6 7b 10 f0       	push   $0xf0107bc6
f0104150:	e8 7f f8 ff ff       	call   f01039d4 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0104155:	83 c4 08             	add    $0x8,%esp
f0104158:	ff 73 18             	pushl  0x18(%ebx)
f010415b:	68 d5 7b 10 f0       	push   $0xf0107bd5
f0104160:	e8 6f f8 ff ff       	call   f01039d4 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0104165:	83 c4 08             	add    $0x8,%esp
f0104168:	ff 73 1c             	pushl  0x1c(%ebx)
f010416b:	68 e4 7b 10 f0       	push   $0xf0107be4
f0104170:	e8 5f f8 ff ff       	call   f01039d4 <cprintf>
}
f0104175:	83 c4 10             	add    $0x10,%esp
f0104178:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010417b:	c9                   	leave  
f010417c:	c3                   	ret    

f010417d <print_trapframe>:
{
f010417d:	f3 0f 1e fb          	endbr32 
f0104181:	55                   	push   %ebp
f0104182:	89 e5                	mov    %esp,%ebp
f0104184:	56                   	push   %esi
f0104185:	53                   	push   %ebx
f0104186:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0104189:	e8 c0 1f 00 00       	call   f010614e <cpunum>
f010418e:	83 ec 04             	sub    $0x4,%esp
f0104191:	50                   	push   %eax
f0104192:	53                   	push   %ebx
f0104193:	68 48 7c 10 f0       	push   $0xf0107c48
f0104198:	e8 37 f8 ff ff       	call   f01039d4 <cprintf>
	print_regs(&tf->tf_regs);
f010419d:	89 1c 24             	mov    %ebx,(%esp)
f01041a0:	e8 46 ff ff ff       	call   f01040eb <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01041a5:	83 c4 08             	add    $0x8,%esp
f01041a8:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01041ac:	50                   	push   %eax
f01041ad:	68 66 7c 10 f0       	push   $0xf0107c66
f01041b2:	e8 1d f8 ff ff       	call   f01039d4 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01041b7:	83 c4 08             	add    $0x8,%esp
f01041ba:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01041be:	50                   	push   %eax
f01041bf:	68 79 7c 10 f0       	push   $0xf0107c79
f01041c4:	e8 0b f8 ff ff       	call   f01039d4 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01041c9:	8b 43 28             	mov    0x28(%ebx),%eax
	if (trapno < ARRAY_SIZE(excnames))
f01041cc:	83 c4 10             	add    $0x10,%esp
f01041cf:	83 f8 13             	cmp    $0x13,%eax
f01041d2:	0f 86 da 00 00 00    	jbe    f01042b2 <print_trapframe+0x135>
		return "System call";
f01041d8:	ba f3 7b 10 f0       	mov    $0xf0107bf3,%edx
	if (trapno == T_SYSCALL)
f01041dd:	83 f8 30             	cmp    $0x30,%eax
f01041e0:	74 13                	je     f01041f5 <print_trapframe+0x78>
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f01041e2:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
f01041e5:	83 fa 0f             	cmp    $0xf,%edx
f01041e8:	ba ff 7b 10 f0       	mov    $0xf0107bff,%edx
f01041ed:	b9 0e 7c 10 f0       	mov    $0xf0107c0e,%ecx
f01041f2:	0f 46 d1             	cmovbe %ecx,%edx
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01041f5:	83 ec 04             	sub    $0x4,%esp
f01041f8:	52                   	push   %edx
f01041f9:	50                   	push   %eax
f01041fa:	68 8c 7c 10 f0       	push   $0xf0107c8c
f01041ff:	e8 d0 f7 ff ff       	call   f01039d4 <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0104204:	83 c4 10             	add    $0x10,%esp
f0104207:	39 1d 60 9a 23 f0    	cmp    %ebx,0xf0239a60
f010420d:	0f 84 ab 00 00 00    	je     f01042be <print_trapframe+0x141>
	cprintf("  err  0x%08x", tf->tf_err);
f0104213:	83 ec 08             	sub    $0x8,%esp
f0104216:	ff 73 2c             	pushl  0x2c(%ebx)
f0104219:	68 ad 7c 10 f0       	push   $0xf0107cad
f010421e:	e8 b1 f7 ff ff       	call   f01039d4 <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f0104223:	83 c4 10             	add    $0x10,%esp
f0104226:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010422a:	0f 85 b1 00 00 00    	jne    f01042e1 <print_trapframe+0x164>
			tf->tf_err & 1 ? "protection" : "not-present");
f0104230:	8b 43 2c             	mov    0x2c(%ebx),%eax
		cprintf(" [%s, %s, %s]\n",
f0104233:	a8 01                	test   $0x1,%al
f0104235:	b9 21 7c 10 f0       	mov    $0xf0107c21,%ecx
f010423a:	ba 2c 7c 10 f0       	mov    $0xf0107c2c,%edx
f010423f:	0f 44 ca             	cmove  %edx,%ecx
f0104242:	a8 02                	test   $0x2,%al
f0104244:	be 38 7c 10 f0       	mov    $0xf0107c38,%esi
f0104249:	ba 3e 7c 10 f0       	mov    $0xf0107c3e,%edx
f010424e:	0f 45 d6             	cmovne %esi,%edx
f0104251:	a8 04                	test   $0x4,%al
f0104253:	b8 43 7c 10 f0       	mov    $0xf0107c43,%eax
f0104258:	be 78 7d 10 f0       	mov    $0xf0107d78,%esi
f010425d:	0f 44 c6             	cmove  %esi,%eax
f0104260:	51                   	push   %ecx
f0104261:	52                   	push   %edx
f0104262:	50                   	push   %eax
f0104263:	68 bb 7c 10 f0       	push   $0xf0107cbb
f0104268:	e8 67 f7 ff ff       	call   f01039d4 <cprintf>
f010426d:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0104270:	83 ec 08             	sub    $0x8,%esp
f0104273:	ff 73 30             	pushl  0x30(%ebx)
f0104276:	68 ca 7c 10 f0       	push   $0xf0107cca
f010427b:	e8 54 f7 ff ff       	call   f01039d4 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0104280:	83 c4 08             	add    $0x8,%esp
f0104283:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0104287:	50                   	push   %eax
f0104288:	68 d9 7c 10 f0       	push   $0xf0107cd9
f010428d:	e8 42 f7 ff ff       	call   f01039d4 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0104292:	83 c4 08             	add    $0x8,%esp
f0104295:	ff 73 38             	pushl  0x38(%ebx)
f0104298:	68 ec 7c 10 f0       	push   $0xf0107cec
f010429d:	e8 32 f7 ff ff       	call   f01039d4 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01042a2:	83 c4 10             	add    $0x10,%esp
f01042a5:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01042a9:	75 4b                	jne    f01042f6 <print_trapframe+0x179>
}
f01042ab:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01042ae:	5b                   	pop    %ebx
f01042af:	5e                   	pop    %esi
f01042b0:	5d                   	pop    %ebp
f01042b1:	c3                   	ret    
		return excnames[trapno];
f01042b2:	8b 14 85 20 7f 10 f0 	mov    -0xfef80e0(,%eax,4),%edx
f01042b9:	e9 37 ff ff ff       	jmp    f01041f5 <print_trapframe+0x78>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01042be:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01042c2:	0f 85 4b ff ff ff    	jne    f0104213 <print_trapframe+0x96>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01042c8:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01042cb:	83 ec 08             	sub    $0x8,%esp
f01042ce:	50                   	push   %eax
f01042cf:	68 9e 7c 10 f0       	push   $0xf0107c9e
f01042d4:	e8 fb f6 ff ff       	call   f01039d4 <cprintf>
f01042d9:	83 c4 10             	add    $0x10,%esp
f01042dc:	e9 32 ff ff ff       	jmp    f0104213 <print_trapframe+0x96>
		cprintf("\n");
f01042e1:	83 ec 0c             	sub    $0xc,%esp
f01042e4:	68 fd 79 10 f0       	push   $0xf01079fd
f01042e9:	e8 e6 f6 ff ff       	call   f01039d4 <cprintf>
f01042ee:	83 c4 10             	add    $0x10,%esp
f01042f1:	e9 7a ff ff ff       	jmp    f0104270 <print_trapframe+0xf3>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01042f6:	83 ec 08             	sub    $0x8,%esp
f01042f9:	ff 73 3c             	pushl  0x3c(%ebx)
f01042fc:	68 fb 7c 10 f0       	push   $0xf0107cfb
f0104301:	e8 ce f6 ff ff       	call   f01039d4 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0104306:	83 c4 08             	add    $0x8,%esp
f0104309:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f010430d:	50                   	push   %eax
f010430e:	68 0a 7d 10 f0       	push   $0xf0107d0a
f0104313:	e8 bc f6 ff ff       	call   f01039d4 <cprintf>
f0104318:	83 c4 10             	add    $0x10,%esp
}
f010431b:	eb 8e                	jmp    f01042ab <print_trapframe+0x12e>

f010431d <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f010431d:	f3 0f 1e fb          	endbr32 
f0104321:	55                   	push   %ebp
f0104322:	89 e5                	mov    %esp,%ebp
f0104324:	57                   	push   %edi
f0104325:	56                   	push   %esi
f0104326:	53                   	push   %ebx
f0104327:	83 ec 1c             	sub    $0x1c,%esp
f010432a:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010432d:	0f 20 d6             	mov    %cr2,%esi

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	// check low-bits of tf_cs
	if((tf->tf_cs & 3) == 0)
f0104330:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0104334:	75 15                	jne    f010434b <page_fault_handler+0x2e>
	{
		panic("At page_fault_handler: page fault at %08x.\n",fault_va);
f0104336:	56                   	push   %esi
f0104337:	68 c4 7e 10 f0       	push   $0xf0107ec4
f010433c:	68 a5 01 00 00       	push   $0x1a5
f0104341:	68 1d 7d 10 f0       	push   $0xf0107d1d
f0104346:	e8 f5 bc ff ff       	call   f0100040 <_panic>
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	// no self-defined pgfault_upcall function
	if(curenv->env_pgfault_upcall == NULL)
f010434b:	e8 fe 1d 00 00       	call   f010614e <cpunum>
f0104350:	6b c0 74             	imul   $0x74,%eax,%eax
f0104353:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f0104359:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f010435d:	0f 84 92 00 00 00    	je     f01043f5 <page_fault_handler+0xd8>
	
	struct UTrapframe* utf;
	uintptr_t addr;
	// determine utf address
	size_t size = sizeof(struct UTrapframe)+ sizeof(uint32_t);
	if (tf->tf_esp >= UXSTACKTOP-PGSIZE && tf->tf_esp < UXSTACKTOP)
f0104363:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0104366:	8d 90 00 10 40 11    	lea    0x11401000(%eax),%edx
	{
		addr = tf->tf_esp - size;
	}
	else
	{
		addr = UXSTACKTOP - size;
f010436c:	c7 45 e4 c8 ff bf ee 	movl   $0xeebfffc8,-0x1c(%ebp)
	if (tf->tf_esp >= UXSTACKTOP-PGSIZE && tf->tf_esp < UXSTACKTOP)
f0104373:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f0104379:	77 06                	ja     f0104381 <page_fault_handler+0x64>
		addr = tf->tf_esp - size;
f010437b:	83 e8 38             	sub    $0x38,%eax
f010437e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	}
	// check the permission
	user_mem_assert(curenv,(void*)addr,size,PTE_P|PTE_W|PTE_U);
f0104381:	e8 c8 1d 00 00       	call   f010614e <cpunum>
f0104386:	6a 07                	push   $0x7
f0104388:	6a 38                	push   $0x38
f010438a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010438d:	57                   	push   %edi
f010438e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104391:	ff b0 28 a0 23 f0    	pushl  -0xfdc5fd8(%eax)
f0104397:	e8 1d ec ff ff       	call   f0102fb9 <user_mem_assert>

	// set the attributes
	utf = (struct UTrapframe*)addr;
	utf->utf_fault_va = fault_va;
f010439c:	89 37                	mov    %esi,(%edi)
	utf->utf_eflags = tf->tf_eflags;
f010439e:	8b 43 38             	mov    0x38(%ebx),%eax
f01043a1:	89 47 2c             	mov    %eax,0x2c(%edi)
	utf->utf_err = tf->tf_err;
f01043a4:	8b 43 2c             	mov    0x2c(%ebx),%eax
f01043a7:	89 47 04             	mov    %eax,0x4(%edi)
	utf->utf_esp = tf->tf_esp;
f01043aa:	8b 43 3c             	mov    0x3c(%ebx),%eax
f01043ad:	89 47 30             	mov    %eax,0x30(%edi)
	utf->utf_eip = tf->tf_eip;
f01043b0:	8b 43 30             	mov    0x30(%ebx),%eax
f01043b3:	89 47 28             	mov    %eax,0x28(%edi)
	utf->utf_regs = tf->tf_regs;
f01043b6:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f01043b9:	8d 7f 08             	lea    0x8(%edi),%edi
f01043bc:	b9 08 00 00 00       	mov    $0x8,%ecx
f01043c1:	89 de                	mov    %ebx,%esi
f01043c3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	// change the value in eip field of tf
	tf->tf_eip = (uintptr_t)curenv->env_pgfault_upcall;
f01043c5:	e8 84 1d 00 00       	call   f010614e <cpunum>
f01043ca:	6b c0 74             	imul   $0x74,%eax,%eax
f01043cd:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f01043d3:	8b 40 64             	mov    0x64(%eax),%eax
f01043d6:	89 43 30             	mov    %eax,0x30(%ebx)
	tf->tf_esp = (uintptr_t)utf;
f01043d9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01043dc:	89 53 3c             	mov    %edx,0x3c(%ebx)
	env_run(curenv);
f01043df:	e8 6a 1d 00 00       	call   f010614e <cpunum>
f01043e4:	83 c4 04             	add    $0x4,%esp
f01043e7:	6b c0 74             	imul   $0x74,%eax,%eax
f01043ea:	ff b0 28 a0 23 f0    	pushl  -0xfdc5fd8(%eax)
f01043f0:	e8 61 f3 ff ff       	call   f0103756 <env_run>
		cprintf("[%08x] user fault va %08x ip %08x\n",
f01043f5:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f01043f8:	e8 51 1d 00 00       	call   f010614e <cpunum>
		cprintf("[%08x] user fault va %08x ip %08x\n",
f01043fd:	57                   	push   %edi
f01043fe:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f01043ff:	6b c0 74             	imul   $0x74,%eax,%eax
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0104402:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f0104408:	ff 70 48             	pushl  0x48(%eax)
f010440b:	68 f0 7e 10 f0       	push   $0xf0107ef0
f0104410:	e8 bf f5 ff ff       	call   f01039d4 <cprintf>
		print_trapframe(tf);
f0104415:	89 1c 24             	mov    %ebx,(%esp)
f0104418:	e8 60 fd ff ff       	call   f010417d <print_trapframe>
		env_destroy(curenv);
f010441d:	e8 2c 1d 00 00       	call   f010614e <cpunum>
f0104422:	83 c4 04             	add    $0x4,%esp
f0104425:	6b c0 74             	imul   $0x74,%eax,%eax
f0104428:	ff b0 28 a0 23 f0    	pushl  -0xfdc5fd8(%eax)
f010442e:	e8 7c f2 ff ff       	call   f01036af <env_destroy>
f0104433:	83 c4 10             	add    $0x10,%esp
f0104436:	e9 28 ff ff ff       	jmp    f0104363 <page_fault_handler+0x46>

f010443b <trap>:
{
f010443b:	f3 0f 1e fb          	endbr32 
f010443f:	55                   	push   %ebp
f0104440:	89 e5                	mov    %esp,%ebp
f0104442:	57                   	push   %edi
f0104443:	56                   	push   %esi
f0104444:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::: "cc");
f0104447:	fc                   	cld    
	if (panicstr)
f0104448:	83 3d 80 9e 23 f0 00 	cmpl   $0x0,0xf0239e80
f010444f:	74 01                	je     f0104452 <trap+0x17>
		asm volatile("hlt");
f0104451:	f4                   	hlt    
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0104452:	e8 f7 1c 00 00       	call   f010614e <cpunum>
f0104457:	6b d0 74             	imul   $0x74,%eax,%edx
f010445a:	83 c2 04             	add    $0x4,%edx
	asm volatile("lock; xchgl %0, %1"
f010445d:	b8 01 00 00 00       	mov    $0x1,%eax
f0104462:	f0 87 82 20 a0 23 f0 	lock xchg %eax,-0xfdc5fe0(%edx)
f0104469:	83 f8 02             	cmp    $0x2,%eax
f010446c:	74 62                	je     f01044d0 <trap+0x95>
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f010446e:	9c                   	pushf  
f010446f:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
f0104470:	f6 c4 02             	test   $0x2,%ah
f0104473:	75 6d                	jne    f01044e2 <trap+0xa7>
	if ((tf->tf_cs & 3) == 3) {
f0104475:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104479:	83 e0 03             	and    $0x3,%eax
f010447c:	66 83 f8 03          	cmp    $0x3,%ax
f0104480:	74 79                	je     f01044fb <trap+0xc0>
	last_tf = tf;
f0104482:	89 35 60 9a 23 f0    	mov    %esi,0xf0239a60
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0104488:	8b 46 28             	mov    0x28(%esi),%eax
f010448b:	83 f8 27             	cmp    $0x27,%eax
f010448e:	0f 84 0c 01 00 00    	je     f01045a0 <trap+0x165>
	switch(tf->tf_trapno)
f0104494:	83 f8 03             	cmp    $0x3,%eax
f0104497:	0f 84 73 01 00 00    	je     f0104610 <trap+0x1d5>
f010449d:	0f 86 17 01 00 00    	jbe    f01045ba <trap+0x17f>
f01044a3:	83 f8 30             	cmp    $0x30,%eax
f01044a6:	0f 85 21 01 00 00    	jne    f01045cd <trap+0x192>
			int32_t ret = syscall(regs->reg_eax,regs->reg_edx,regs->reg_ecx,regs->reg_ebx,regs->reg_edi,regs->reg_esi);
f01044ac:	83 ec 08             	sub    $0x8,%esp
f01044af:	ff 76 04             	pushl  0x4(%esi)
f01044b2:	ff 36                	pushl  (%esi)
f01044b4:	ff 76 10             	pushl  0x10(%esi)
f01044b7:	ff 76 18             	pushl  0x18(%esi)
f01044ba:	ff 76 14             	pushl  0x14(%esi)
f01044bd:	ff 76 1c             	pushl  0x1c(%esi)
f01044c0:	e8 64 04 00 00       	call   f0104929 <syscall>
			regs->reg_eax = (uint32_t)ret;
f01044c5:	89 46 1c             	mov    %eax,0x1c(%esi)
			return;
f01044c8:	83 c4 20             	add    $0x20,%esp
f01044cb:	e9 4c 01 00 00       	jmp    f010461c <trap+0x1e1>
	spin_lock(&kernel_lock);
f01044d0:	83 ec 0c             	sub    $0xc,%esp
f01044d3:	68 c0 33 12 f0       	push   $0xf01233c0
f01044d8:	e8 f9 1e 00 00       	call   f01063d6 <spin_lock>
}
f01044dd:	83 c4 10             	add    $0x10,%esp
f01044e0:	eb 8c                	jmp    f010446e <trap+0x33>
	assert(!(read_eflags() & FL_IF));
f01044e2:	68 29 7d 10 f0       	push   $0xf0107d29
f01044e7:	68 43 77 10 f0       	push   $0xf0107743
f01044ec:	68 6d 01 00 00       	push   $0x16d
f01044f1:	68 1d 7d 10 f0       	push   $0xf0107d1d
f01044f6:	e8 45 bb ff ff       	call   f0100040 <_panic>
	spin_lock(&kernel_lock);
f01044fb:	83 ec 0c             	sub    $0xc,%esp
f01044fe:	68 c0 33 12 f0       	push   $0xf01233c0
f0104503:	e8 ce 1e 00 00       	call   f01063d6 <spin_lock>
		assert(curenv);
f0104508:	e8 41 1c 00 00       	call   f010614e <cpunum>
f010450d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104510:	83 c4 10             	add    $0x10,%esp
f0104513:	83 b8 28 a0 23 f0 00 	cmpl   $0x0,-0xfdc5fd8(%eax)
f010451a:	74 3e                	je     f010455a <trap+0x11f>
		if (curenv->env_status == ENV_DYING) {
f010451c:	e8 2d 1c 00 00       	call   f010614e <cpunum>
f0104521:	6b c0 74             	imul   $0x74,%eax,%eax
f0104524:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f010452a:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f010452e:	74 43                	je     f0104573 <trap+0x138>
		curenv->env_tf = *tf;
f0104530:	e8 19 1c 00 00       	call   f010614e <cpunum>
f0104535:	6b c0 74             	imul   $0x74,%eax,%eax
f0104538:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f010453e:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104543:	89 c7                	mov    %eax,%edi
f0104545:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &curenv->env_tf;
f0104547:	e8 02 1c 00 00       	call   f010614e <cpunum>
f010454c:	6b c0 74             	imul   $0x74,%eax,%eax
f010454f:	8b b0 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%esi
f0104555:	e9 28 ff ff ff       	jmp    f0104482 <trap+0x47>
		assert(curenv);
f010455a:	68 42 7d 10 f0       	push   $0xf0107d42
f010455f:	68 43 77 10 f0       	push   $0xf0107743
f0104564:	68 75 01 00 00       	push   $0x175
f0104569:	68 1d 7d 10 f0       	push   $0xf0107d1d
f010456e:	e8 cd ba ff ff       	call   f0100040 <_panic>
			env_free(curenv);
f0104573:	e8 d6 1b 00 00       	call   f010614e <cpunum>
f0104578:	83 ec 0c             	sub    $0xc,%esp
f010457b:	6b c0 74             	imul   $0x74,%eax,%eax
f010457e:	ff b0 28 a0 23 f0    	pushl  -0xfdc5fd8(%eax)
f0104584:	e8 45 ef ff ff       	call   f01034ce <env_free>
			curenv = NULL;
f0104589:	e8 c0 1b 00 00       	call   f010614e <cpunum>
f010458e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104591:	c7 80 28 a0 23 f0 00 	movl   $0x0,-0xfdc5fd8(%eax)
f0104598:	00 00 00 
			sched_yield();
f010459b:	e8 d1 02 00 00       	call   f0104871 <sched_yield>
		cprintf("Spurious interrupt on irq 7\n");
f01045a0:	83 ec 0c             	sub    $0xc,%esp
f01045a3:	68 49 7d 10 f0       	push   $0xf0107d49
f01045a8:	e8 27 f4 ff ff       	call   f01039d4 <cprintf>
		print_trapframe(tf);
f01045ad:	89 34 24             	mov    %esi,(%esp)
f01045b0:	e8 c8 fb ff ff       	call   f010417d <print_trapframe>
		return;
f01045b5:	83 c4 10             	add    $0x10,%esp
f01045b8:	eb 62                	jmp    f010461c <trap+0x1e1>
	switch(tf->tf_trapno)
f01045ba:	83 f8 01             	cmp    $0x1,%eax
f01045bd:	75 1a                	jne    f01045d9 <trap+0x19e>
			monitor(tf);
f01045bf:	83 ec 0c             	sub    $0xc,%esp
f01045c2:	56                   	push   %esi
f01045c3:	e8 ac c3 ff ff       	call   f0100974 <monitor>
			return;
f01045c8:	83 c4 10             	add    $0x10,%esp
f01045cb:	eb 4f                	jmp    f010461c <trap+0x1e1>
	switch(tf->tf_trapno)
f01045cd:	77 0a                	ja     f01045d9 <trap+0x19e>
f01045cf:	83 f8 0e             	cmp    $0xe,%eax
f01045d2:	74 33                	je     f0104607 <trap+0x1cc>
f01045d4:	83 f8 20             	cmp    $0x20,%eax
f01045d7:	74 6d                	je     f0104646 <trap+0x20b>
	print_trapframe(tf);
f01045d9:	83 ec 0c             	sub    $0xc,%esp
f01045dc:	56                   	push   %esi
f01045dd:	e8 9b fb ff ff       	call   f010417d <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01045e2:	83 c4 10             	add    $0x10,%esp
f01045e5:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01045ea:	74 64                	je     f0104650 <trap+0x215>
		env_destroy(curenv);
f01045ec:	e8 5d 1b 00 00       	call   f010614e <cpunum>
f01045f1:	83 ec 0c             	sub    $0xc,%esp
f01045f4:	6b c0 74             	imul   $0x74,%eax,%eax
f01045f7:	ff b0 28 a0 23 f0    	pushl  -0xfdc5fd8(%eax)
f01045fd:	e8 ad f0 ff ff       	call   f01036af <env_destroy>
		return;
f0104602:	83 c4 10             	add    $0x10,%esp
f0104605:	eb 15                	jmp    f010461c <trap+0x1e1>
			page_fault_handler(tf);
f0104607:	83 ec 0c             	sub    $0xc,%esp
f010460a:	56                   	push   %esi
f010460b:	e8 0d fd ff ff       	call   f010431d <page_fault_handler>
			monitor(tf);
f0104610:	83 ec 0c             	sub    $0xc,%esp
f0104613:	56                   	push   %esi
f0104614:	e8 5b c3 ff ff       	call   f0100974 <monitor>
			return;
f0104619:	83 c4 10             	add    $0x10,%esp
	if (curenv && curenv->env_status == ENV_RUNNING)
f010461c:	e8 2d 1b 00 00       	call   f010614e <cpunum>
f0104621:	6b c0 74             	imul   $0x74,%eax,%eax
f0104624:	83 b8 28 a0 23 f0 00 	cmpl   $0x0,-0xfdc5fd8(%eax)
f010462b:	74 14                	je     f0104641 <trap+0x206>
f010462d:	e8 1c 1b 00 00       	call   f010614e <cpunum>
f0104632:	6b c0 74             	imul   $0x74,%eax,%eax
f0104635:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f010463b:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010463f:	74 26                	je     f0104667 <trap+0x22c>
		sched_yield();
f0104641:	e8 2b 02 00 00       	call   f0104871 <sched_yield>
			lapic_eoi();
f0104646:	e8 52 1c 00 00       	call   f010629d <lapic_eoi>
			sched_yield();
f010464b:	e8 21 02 00 00       	call   f0104871 <sched_yield>
		panic("unhandled trap in kernel");
f0104650:	83 ec 04             	sub    $0x4,%esp
f0104653:	68 66 7d 10 f0       	push   $0xf0107d66
f0104658:	68 53 01 00 00       	push   $0x153
f010465d:	68 1d 7d 10 f0       	push   $0xf0107d1d
f0104662:	e8 d9 b9 ff ff       	call   f0100040 <_panic>
		env_run(curenv);
f0104667:	e8 e2 1a 00 00       	call   f010614e <cpunum>
f010466c:	83 ec 0c             	sub    $0xc,%esp
f010466f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104672:	ff b0 28 a0 23 f0    	pushl  -0xfdc5fd8(%eax)
f0104678:	e8 d9 f0 ff ff       	call   f0103756 <env_run>
f010467d:	90                   	nop

f010467e <DIVIDE>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
 # faults and interrupts
TRAPHANDLER_NOEC(DIVIDE,T_DIVIDE)
f010467e:	6a 00                	push   $0x0
f0104680:	6a 00                	push   $0x0
f0104682:	e9 0b 01 00 00       	jmp    f0104792 <_alltraps>
f0104687:	90                   	nop

f0104688 <DEBUG>:
TRAPHANDLER_NOEC(DEBUG,T_DEBUG)
f0104688:	6a 00                	push   $0x0
f010468a:	6a 01                	push   $0x1
f010468c:	e9 01 01 00 00       	jmp    f0104792 <_alltraps>
f0104691:	90                   	nop

f0104692 <NMI>:
TRAPHANDLER_NOEC(NMI, T_NMI)
f0104692:	6a 00                	push   $0x0
f0104694:	6a 02                	push   $0x2
f0104696:	e9 f7 00 00 00       	jmp    f0104792 <_alltraps>
f010469b:	90                   	nop

f010469c <BRKPT>:
TRAPHANDLER_NOEC(BRKPT, T_BRKPT)
f010469c:	6a 00                	push   $0x0
f010469e:	6a 03                	push   $0x3
f01046a0:	e9 ed 00 00 00       	jmp    f0104792 <_alltraps>
f01046a5:	90                   	nop

f01046a6 <OFLOW>:
TRAPHANDLER_NOEC(OFLOW, T_OFLOW)
f01046a6:	6a 00                	push   $0x0
f01046a8:	6a 04                	push   $0x4
f01046aa:	e9 e3 00 00 00       	jmp    f0104792 <_alltraps>
f01046af:	90                   	nop

f01046b0 <BOUND>:
TRAPHANDLER_NOEC(BOUND, T_BOUND)
f01046b0:	6a 00                	push   $0x0
f01046b2:	6a 05                	push   $0x5
f01046b4:	e9 d9 00 00 00       	jmp    f0104792 <_alltraps>
f01046b9:	90                   	nop

f01046ba <ILLOP>:
TRAPHANDLER_NOEC(ILLOP, T_ILLOP)
f01046ba:	6a 00                	push   $0x0
f01046bc:	6a 06                	push   $0x6
f01046be:	e9 cf 00 00 00       	jmp    f0104792 <_alltraps>
f01046c3:	90                   	nop

f01046c4 <DEVICE>:
TRAPHANDLER_NOEC(DEVICE, T_DEVICE)
f01046c4:	6a 00                	push   $0x0
f01046c6:	6a 07                	push   $0x7
f01046c8:	e9 c5 00 00 00       	jmp    f0104792 <_alltraps>
f01046cd:	90                   	nop

f01046ce <DBLFLT>:
TRAPHANDLER(DBLFLT, T_DBLFLT)
f01046ce:	6a 08                	push   $0x8
f01046d0:	e9 bd 00 00 00       	jmp    f0104792 <_alltraps>
f01046d5:	90                   	nop

f01046d6 <TSS>:
TRAPHANDLER(TSS, T_TSS)
f01046d6:	6a 0a                	push   $0xa
f01046d8:	e9 b5 00 00 00       	jmp    f0104792 <_alltraps>
f01046dd:	90                   	nop

f01046de <SEGNP>:
TRAPHANDLER(SEGNP, T_SEGNP)
f01046de:	6a 0b                	push   $0xb
f01046e0:	e9 ad 00 00 00       	jmp    f0104792 <_alltraps>
f01046e5:	90                   	nop

f01046e6 <STACK>:
TRAPHANDLER(STACK, T_STACK)
f01046e6:	6a 0c                	push   $0xc
f01046e8:	e9 a5 00 00 00       	jmp    f0104792 <_alltraps>
f01046ed:	90                   	nop

f01046ee <GPFLT>:
TRAPHANDLER(GPFLT, T_GPFLT)
f01046ee:	6a 0d                	push   $0xd
f01046f0:	e9 9d 00 00 00       	jmp    f0104792 <_alltraps>
f01046f5:	90                   	nop

f01046f6 <PGFLT>:
TRAPHANDLER(PGFLT, T_PGFLT)
f01046f6:	6a 0e                	push   $0xe
f01046f8:	e9 95 00 00 00       	jmp    f0104792 <_alltraps>
f01046fd:	90                   	nop

f01046fe <FPERR>:
TRAPHANDLER_NOEC(FPERR, T_FPERR)
f01046fe:	6a 00                	push   $0x0
f0104700:	6a 10                	push   $0x10
f0104702:	e9 8b 00 00 00       	jmp    f0104792 <_alltraps>
f0104707:	90                   	nop

f0104708 <ALIGN>:
TRAPHANDLER(ALIGN, T_ALIGN)
f0104708:	6a 11                	push   $0x11
f010470a:	e9 83 00 00 00       	jmp    f0104792 <_alltraps>
f010470f:	90                   	nop

f0104710 <MCHK>:
TRAPHANDLER_NOEC(MCHK, T_MCHK)
f0104710:	6a 00                	push   $0x0
f0104712:	6a 12                	push   $0x12
f0104714:	eb 7c                	jmp    f0104792 <_alltraps>

f0104716 <SIMDERR>:
TRAPHANDLER_NOEC(SIMDERR, T_SIMDERR)
f0104716:	6a 00                	push   $0x0
f0104718:	6a 13                	push   $0x13
f010471a:	eb 76                	jmp    f0104792 <_alltraps>

f010471c <SYSCALL>:
TRAPHANDLER_NOEC(SYSCALL, T_SYSCALL)
f010471c:	6a 00                	push   $0x0
f010471e:	6a 30                	push   $0x30
f0104720:	eb 70                	jmp    f0104792 <_alltraps>

f0104722 <DEFAULT>:
TRAPHANDLER_NOEC(DEFAULT, T_DEFAULT)
f0104722:	6a 00                	push   $0x0
f0104724:	68 f4 01 00 00       	push   $0x1f4
f0104729:	eb 67                	jmp    f0104792 <_alltraps>
f010472b:	90                   	nop

f010472c <IRQsHandler0>:
# IRQs
TRAPHANDLER_NOEC(IRQsHandler0, IRQ_OFFSET+IRQ_TIMER)
f010472c:	6a 00                	push   $0x0
f010472e:	6a 20                	push   $0x20
f0104730:	eb 60                	jmp    f0104792 <_alltraps>

f0104732 <IRQsHandler1>:
TRAPHANDLER_NOEC(IRQsHandler1, IRQ_OFFSET+IRQ_KBD)
f0104732:	6a 00                	push   $0x0
f0104734:	6a 21                	push   $0x21
f0104736:	eb 5a                	jmp    f0104792 <_alltraps>

f0104738 <IRQsHandler2>:
TRAPHANDLER_NOEC(IRQsHandler2, IRQ_OFFSET+IRQ_SLAVE)
f0104738:	6a 00                	push   $0x0
f010473a:	6a 22                	push   $0x22
f010473c:	eb 54                	jmp    f0104792 <_alltraps>

f010473e <IRQsHandler3>:
TRAPHANDLER_NOEC(IRQsHandler3, IRQ_OFFSET+3)
f010473e:	6a 00                	push   $0x0
f0104740:	6a 23                	push   $0x23
f0104742:	eb 4e                	jmp    f0104792 <_alltraps>

f0104744 <IRQsHandler4>:
TRAPHANDLER_NOEC(IRQsHandler4, IRQ_OFFSET+IRQ_SERIAL)
f0104744:	6a 00                	push   $0x0
f0104746:	6a 24                	push   $0x24
f0104748:	eb 48                	jmp    f0104792 <_alltraps>

f010474a <IRQsHandler5>:
TRAPHANDLER_NOEC(IRQsHandler5, IRQ_OFFSET+5)
f010474a:	6a 00                	push   $0x0
f010474c:	6a 25                	push   $0x25
f010474e:	eb 42                	jmp    f0104792 <_alltraps>

f0104750 <IRQsHandler6>:
TRAPHANDLER_NOEC(IRQsHandler6, IRQ_OFFSET+6)
f0104750:	6a 00                	push   $0x0
f0104752:	6a 26                	push   $0x26
f0104754:	eb 3c                	jmp    f0104792 <_alltraps>

f0104756 <IRQsHandler7>:
TRAPHANDLER_NOEC(IRQsHandler7, IRQ_OFFSET+IRQ_SPURIOUS)
f0104756:	6a 00                	push   $0x0
f0104758:	6a 27                	push   $0x27
f010475a:	eb 36                	jmp    f0104792 <_alltraps>

f010475c <IRQsHandler8>:
TRAPHANDLER_NOEC(IRQsHandler8, IRQ_OFFSET+8)
f010475c:	6a 00                	push   $0x0
f010475e:	6a 28                	push   $0x28
f0104760:	eb 30                	jmp    f0104792 <_alltraps>

f0104762 <IRQsHandler9>:
TRAPHANDLER_NOEC(IRQsHandler9, IRQ_OFFSET+9)
f0104762:	6a 00                	push   $0x0
f0104764:	6a 29                	push   $0x29
f0104766:	eb 2a                	jmp    f0104792 <_alltraps>

f0104768 <IRQsHandler10>:
TRAPHANDLER_NOEC(IRQsHandler10, IRQ_OFFSET+10)
f0104768:	6a 00                	push   $0x0
f010476a:	6a 2a                	push   $0x2a
f010476c:	eb 24                	jmp    f0104792 <_alltraps>

f010476e <IRQsHandler11>:
TRAPHANDLER_NOEC(IRQsHandler11, IRQ_OFFSET+11)
f010476e:	6a 00                	push   $0x0
f0104770:	6a 2b                	push   $0x2b
f0104772:	eb 1e                	jmp    f0104792 <_alltraps>

f0104774 <IRQsHandler12>:
TRAPHANDLER_NOEC(IRQsHandler12, IRQ_OFFSET+12)
f0104774:	6a 00                	push   $0x0
f0104776:	6a 2c                	push   $0x2c
f0104778:	eb 18                	jmp    f0104792 <_alltraps>

f010477a <IRQsHandler13>:
TRAPHANDLER_NOEC(IRQsHandler13, IRQ_OFFSET+13)
f010477a:	6a 00                	push   $0x0
f010477c:	6a 2d                	push   $0x2d
f010477e:	eb 12                	jmp    f0104792 <_alltraps>

f0104780 <IRQsHandler14>:
TRAPHANDLER_NOEC(IRQsHandler14, IRQ_OFFSET+IRQ_IDE)
f0104780:	6a 00                	push   $0x0
f0104782:	6a 2e                	push   $0x2e
f0104784:	eb 0c                	jmp    f0104792 <_alltraps>

f0104786 <IRQsHandler15>:
TRAPHANDLER_NOEC(IRQsHandler15, IRQ_OFFSET+15)
f0104786:	6a 00                	push   $0x0
f0104788:	6a 2f                	push   $0x2f
f010478a:	eb 06                	jmp    f0104792 <_alltraps>

f010478c <IRQsHandler19>:
; TRAPHANDLER_NOEC(IRQsHandler19, IRQ_OFFSET+IRQ_ERROR)
f010478c:	6a 00                	push   $0x0
f010478e:	6a 33                	push   $0x33
f0104790:	eb 00                	jmp    f0104792 <_alltraps>

f0104792 <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */
 .global _alltraps
 _alltraps:
 /* code below according to the guide */
pushl %ds
f0104792:	1e                   	push   %ds
pushl %es
f0104793:	06                   	push   %es
pushal
f0104794:	60                   	pusha  
movw $GD_KD, %ax
f0104795:	66 b8 10 00          	mov    $0x10,%ax
movw %ax, %ds
f0104799:	8e d8                	mov    %eax,%ds
movw %ax, %es
f010479b:	8e c0                	mov    %eax,%es
pushl %esp
f010479d:	54                   	push   %esp
call trap
f010479e:	e8 98 fc ff ff       	call   f010443b <trap>

f01047a3 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f01047a3:	f3 0f 1e fb          	endbr32 
f01047a7:	55                   	push   %ebp
f01047a8:	89 e5                	mov    %esp,%ebp
f01047aa:	83 ec 08             	sub    $0x8,%esp
f01047ad:	a1 48 92 23 f0       	mov    0xf0239248,%eax
f01047b2:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f01047b5:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f01047ba:	8b 02                	mov    (%edx),%eax
f01047bc:	83 e8 01             	sub    $0x1,%eax
		if ((envs[i].env_status == ENV_RUNNABLE ||
f01047bf:	83 f8 02             	cmp    $0x2,%eax
f01047c2:	76 2d                	jbe    f01047f1 <sched_halt+0x4e>
	for (i = 0; i < NENV; i++) {
f01047c4:	83 c1 01             	add    $0x1,%ecx
f01047c7:	83 c2 7c             	add    $0x7c,%edx
f01047ca:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f01047d0:	75 e8                	jne    f01047ba <sched_halt+0x17>
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
		cprintf("No runnable environments in the system!\n");
f01047d2:	83 ec 0c             	sub    $0xc,%esp
f01047d5:	68 70 7f 10 f0       	push   $0xf0107f70
f01047da:	e8 f5 f1 ff ff       	call   f01039d4 <cprintf>
f01047df:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f01047e2:	83 ec 0c             	sub    $0xc,%esp
f01047e5:	6a 00                	push   $0x0
f01047e7:	e8 88 c1 ff ff       	call   f0100974 <monitor>
f01047ec:	83 c4 10             	add    $0x10,%esp
f01047ef:	eb f1                	jmp    f01047e2 <sched_halt+0x3f>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f01047f1:	e8 58 19 00 00       	call   f010614e <cpunum>
f01047f6:	6b c0 74             	imul   $0x74,%eax,%eax
f01047f9:	c7 80 28 a0 23 f0 00 	movl   $0x0,-0xfdc5fd8(%eax)
f0104800:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0104803:	a1 8c 9e 23 f0       	mov    0xf0239e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0104808:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010480d:	76 50                	jbe    f010485f <sched_halt+0xbc>
	return (physaddr_t)kva - KERNBASE;
f010480f:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0104814:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0104817:	e8 32 19 00 00       	call   f010614e <cpunum>
f010481c:	6b d0 74             	imul   $0x74,%eax,%edx
f010481f:	83 c2 04             	add    $0x4,%edx
	asm volatile("lock; xchgl %0, %1"
f0104822:	b8 02 00 00 00       	mov    $0x2,%eax
f0104827:	f0 87 82 20 a0 23 f0 	lock xchg %eax,-0xfdc5fe0(%edx)
	spin_unlock(&kernel_lock);
f010482e:	83 ec 0c             	sub    $0xc,%esp
f0104831:	68 c0 33 12 f0       	push   $0xf01233c0
f0104836:	e8 39 1c 00 00       	call   f0106474 <spin_unlock>
	asm volatile("pause");
f010483b:	f3 90                	pause  
		// Uncomment the following line after completing exercise 13
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f010483d:	e8 0c 19 00 00       	call   f010614e <cpunum>
f0104842:	6b c0 74             	imul   $0x74,%eax,%eax
	asm volatile (
f0104845:	8b 80 30 a0 23 f0    	mov    -0xfdc5fd0(%eax),%eax
f010484b:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104850:	89 c4                	mov    %eax,%esp
f0104852:	6a 00                	push   $0x0
f0104854:	6a 00                	push   $0x0
f0104856:	fb                   	sti    
f0104857:	f4                   	hlt    
f0104858:	eb fd                	jmp    f0104857 <sched_halt+0xb4>
}
f010485a:	83 c4 10             	add    $0x10,%esp
f010485d:	c9                   	leave  
f010485e:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010485f:	50                   	push   %eax
f0104860:	68 08 68 10 f0       	push   $0xf0106808
f0104865:	6a 55                	push   $0x55
f0104867:	68 99 7f 10 f0       	push   $0xf0107f99
f010486c:	e8 cf b7 ff ff       	call   f0100040 <_panic>

f0104871 <sched_yield>:
{
f0104871:	f3 0f 1e fb          	endbr32 
f0104875:	55                   	push   %ebp
f0104876:	89 e5                	mov    %esp,%ebp
f0104878:	56                   	push   %esi
f0104879:	53                   	push   %ebx
	if(curenv)
f010487a:	e8 cf 18 00 00       	call   f010614e <cpunum>
f010487f:	6b c0 74             	imul   $0x74,%eax,%eax
	int begin = 0;
f0104882:	b9 00 00 00 00       	mov    $0x0,%ecx
	if(curenv)
f0104887:	83 b8 28 a0 23 f0 00 	cmpl   $0x0,-0xfdc5fd8(%eax)
f010488e:	74 17                	je     f01048a7 <sched_yield+0x36>
		begin = ENVX(curenv->env_id);
f0104890:	e8 b9 18 00 00       	call   f010614e <cpunum>
f0104895:	6b c0 74             	imul   $0x74,%eax,%eax
f0104898:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f010489e:	8b 48 48             	mov    0x48(%eax),%ecx
f01048a1:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
		idle = &envs[(i+begin)%NENV];
f01048a7:	8b 1d 48 92 23 f0    	mov    0xf0239248,%ebx
f01048ad:	89 ca                	mov    %ecx,%edx
f01048af:	81 c1 00 04 00 00    	add    $0x400,%ecx
f01048b5:	89 d6                	mov    %edx,%esi
f01048b7:	c1 fe 1f             	sar    $0x1f,%esi
f01048ba:	c1 ee 16             	shr    $0x16,%esi
f01048bd:	8d 04 32             	lea    (%edx,%esi,1),%eax
f01048c0:	25 ff 03 00 00       	and    $0x3ff,%eax
f01048c5:	29 f0                	sub    %esi,%eax
f01048c7:	6b c0 7c             	imul   $0x7c,%eax,%eax
f01048ca:	01 d8                	add    %ebx,%eax
		if(idle->env_status == ENV_RUNNABLE)
f01048cc:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f01048d0:	74 38                	je     f010490a <sched_yield+0x99>
f01048d2:	83 c2 01             	add    $0x1,%edx
	for(int i = 0;i<NENV;i++)
f01048d5:	39 ca                	cmp    %ecx,%edx
f01048d7:	75 dc                	jne    f01048b5 <sched_yield+0x44>
	if(!flag && curenv && curenv->env_status == ENV_RUNNING)
f01048d9:	e8 70 18 00 00       	call   f010614e <cpunum>
f01048de:	6b c0 74             	imul   $0x74,%eax,%eax
f01048e1:	83 b8 28 a0 23 f0 00 	cmpl   $0x0,-0xfdc5fd8(%eax)
f01048e8:	74 14                	je     f01048fe <sched_yield+0x8d>
f01048ea:	e8 5f 18 00 00       	call   f010614e <cpunum>
f01048ef:	6b c0 74             	imul   $0x74,%eax,%eax
f01048f2:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f01048f8:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01048fc:	74 15                	je     f0104913 <sched_yield+0xa2>
		sched_halt();
f01048fe:	e8 a0 fe ff ff       	call   f01047a3 <sched_halt>
}
f0104903:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0104906:	5b                   	pop    %ebx
f0104907:	5e                   	pop    %esi
f0104908:	5d                   	pop    %ebp
f0104909:	c3                   	ret    
			env_run(idle);
f010490a:	83 ec 0c             	sub    $0xc,%esp
f010490d:	50                   	push   %eax
f010490e:	e8 43 ee ff ff       	call   f0103756 <env_run>
		env_run(curenv);
f0104913:	e8 36 18 00 00       	call   f010614e <cpunum>
f0104918:	83 ec 0c             	sub    $0xc,%esp
f010491b:	6b c0 74             	imul   $0x74,%eax,%eax
f010491e:	ff b0 28 a0 23 f0    	pushl  -0xfdc5fd8(%eax)
f0104924:	e8 2d ee ff ff       	call   f0103756 <env_run>

f0104929 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104929:	f3 0f 1e fb          	endbr32 
f010492d:	55                   	push   %ebp
f010492e:	89 e5                	mov    %esp,%ebp
f0104930:	57                   	push   %edi
f0104931:	56                   	push   %esi
f0104932:	53                   	push   %ebx
f0104933:	83 ec 1c             	sub    $0x1c,%esp
f0104936:	8b 45 08             	mov    0x8(%ebp),%eax
f0104939:	83 f8 0d             	cmp    $0xd,%eax
f010493c:	0f 87 aa 05 00 00    	ja     f0104eec <syscall+0x5c3>
f0104942:	3e ff 24 85 e0 7f 10 	notrack jmp *-0xfef8020(,%eax,4)
f0104949:	f0 
	user_mem_assert(curenv,s,len,0);
f010494a:	e8 ff 17 00 00       	call   f010614e <cpunum>
f010494f:	6a 00                	push   $0x0
f0104951:	ff 75 10             	pushl  0x10(%ebp)
f0104954:	ff 75 0c             	pushl  0xc(%ebp)
f0104957:	6b c0 74             	imul   $0x74,%eax,%eax
f010495a:	ff b0 28 a0 23 f0    	pushl  -0xfdc5fd8(%eax)
f0104960:	e8 54 e6 ff ff       	call   f0102fb9 <user_mem_assert>
	cprintf("%.*s", len, s);
f0104965:	83 c4 0c             	add    $0xc,%esp
f0104968:	ff 75 0c             	pushl  0xc(%ebp)
f010496b:	ff 75 10             	pushl  0x10(%ebp)
f010496e:	68 a6 7f 10 f0       	push   $0xf0107fa6
f0104973:	e8 5c f0 ff ff       	call   f01039d4 <cprintf>
}
f0104978:	83 c4 10             	add    $0x10,%esp
	switch (syscallno) 
	{
		case SYS_cputs:
		{
			sys_cputs((const char*)a1,(size_t)a2);
			return 0;
f010497b:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0104980:	e9 73 05 00 00       	jmp    f0104ef8 <syscall+0x5cf>
	return cons_getc();
f0104985:	e8 8a bc ff ff       	call   f0100614 <cons_getc>
f010498a:	89 c3                	mov    %eax,%ebx
		}
		case SYS_cgetc:
		{
			return sys_cgetc();
f010498c:	e9 67 05 00 00       	jmp    f0104ef8 <syscall+0x5cf>
	if ((r = envid2env(envid, &e, 1)) < 0)
f0104991:	83 ec 04             	sub    $0x4,%esp
f0104994:	6a 01                	push   $0x1
f0104996:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104999:	50                   	push   %eax
f010499a:	ff 75 0c             	pushl  0xc(%ebp)
f010499d:	e8 08 e7 ff ff       	call   f01030aa <envid2env>
f01049a2:	89 c3                	mov    %eax,%ebx
f01049a4:	83 c4 10             	add    $0x10,%esp
f01049a7:	85 c0                	test   %eax,%eax
f01049a9:	0f 88 49 05 00 00    	js     f0104ef8 <syscall+0x5cf>
	if (e == curenv)
f01049af:	e8 9a 17 00 00       	call   f010614e <cpunum>
f01049b4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01049b7:	6b c0 74             	imul   $0x74,%eax,%eax
f01049ba:	39 90 28 a0 23 f0    	cmp    %edx,-0xfdc5fd8(%eax)
f01049c0:	74 3d                	je     f01049ff <syscall+0xd6>
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f01049c2:	8b 5a 48             	mov    0x48(%edx),%ebx
f01049c5:	e8 84 17 00 00       	call   f010614e <cpunum>
f01049ca:	83 ec 04             	sub    $0x4,%esp
f01049cd:	53                   	push   %ebx
f01049ce:	6b c0 74             	imul   $0x74,%eax,%eax
f01049d1:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f01049d7:	ff 70 48             	pushl  0x48(%eax)
f01049da:	68 c6 7f 10 f0       	push   $0xf0107fc6
f01049df:	e8 f0 ef ff ff       	call   f01039d4 <cprintf>
f01049e4:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01049e7:	83 ec 0c             	sub    $0xc,%esp
f01049ea:	ff 75 e4             	pushl  -0x1c(%ebp)
f01049ed:	e8 bd ec ff ff       	call   f01036af <env_destroy>
	return 0;
f01049f2:	83 c4 10             	add    $0x10,%esp
f01049f5:	bb 00 00 00 00       	mov    $0x0,%ebx
		}
		case SYS_env_destroy:
		{
			return sys_env_destroy((envid_t)a1);
f01049fa:	e9 f9 04 00 00       	jmp    f0104ef8 <syscall+0x5cf>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f01049ff:	e8 4a 17 00 00       	call   f010614e <cpunum>
f0104a04:	83 ec 08             	sub    $0x8,%esp
f0104a07:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a0a:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f0104a10:	ff 70 48             	pushl  0x48(%eax)
f0104a13:	68 ab 7f 10 f0       	push   $0xf0107fab
f0104a18:	e8 b7 ef ff ff       	call   f01039d4 <cprintf>
f0104a1d:	83 c4 10             	add    $0x10,%esp
f0104a20:	eb c5                	jmp    f01049e7 <syscall+0xbe>
	return curenv->env_id;
f0104a22:	e8 27 17 00 00       	call   f010614e <cpunum>
f0104a27:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a2a:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f0104a30:	8b 58 48             	mov    0x48(%eax),%ebx
		{
			return 0;
		}
		case SYS_getenvid:
		{
			return sys_getenvid();
f0104a33:	e9 c0 04 00 00       	jmp    f0104ef8 <syscall+0x5cf>
	sched_yield();
f0104a38:	e8 34 fe ff ff       	call   f0104871 <sched_yield>
	struct Env* store_env = NULL;
f0104a3d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = env_alloc(&store_env,curenv->env_id);
f0104a44:	e8 05 17 00 00       	call   f010614e <cpunum>
f0104a49:	83 ec 08             	sub    $0x8,%esp
f0104a4c:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a4f:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f0104a55:	ff 70 48             	pushl  0x48(%eax)
f0104a58:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104a5b:	50                   	push   %eax
f0104a5c:	e8 5e e7 ff ff       	call   f01031bf <env_alloc>
f0104a61:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104a63:	83 c4 10             	add    $0x10,%esp
f0104a66:	85 c0                	test   %eax,%eax
f0104a68:	0f 88 8a 04 00 00    	js     f0104ef8 <syscall+0x5cf>
	store_env->env_status = ENV_NOT_RUNNABLE;
f0104a6e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a71:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	store_env->env_tf = curenv->env_tf;
f0104a78:	e8 d1 16 00 00       	call   f010614e <cpunum>
f0104a7d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a80:	8b b0 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%esi
f0104a86:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104a8b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104a8e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	store_env->env_tf.tf_regs.reg_eax = 0;
f0104a90:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a93:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return store_env->env_id;
f0104a9a:	8b 58 48             	mov    0x48(%eax),%ebx
			sys_yield();
			return 0;
		}
		case SYS_exofork:
		{
			return sys_exofork();
f0104a9d:	e9 56 04 00 00       	jmp    f0104ef8 <syscall+0x5cf>
	if(status != ENV_NOT_RUNNABLE && status!= ENV_RUNNABLE)
f0104aa2:	8b 45 10             	mov    0x10(%ebp),%eax
f0104aa5:	83 e8 02             	sub    $0x2,%eax
f0104aa8:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f0104aad:	75 38                	jne    f0104ae7 <syscall+0x1be>
	struct Env* e = NULL;
f0104aaf:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f0104ab6:	83 ec 04             	sub    $0x4,%esp
f0104ab9:	6a 01                	push   $0x1
f0104abb:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104abe:	50                   	push   %eax
f0104abf:	ff 75 0c             	pushl  0xc(%ebp)
f0104ac2:	e8 e3 e5 ff ff       	call   f01030aa <envid2env>
f0104ac7:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104ac9:	83 c4 10             	add    $0x10,%esp
f0104acc:	85 c0                	test   %eax,%eax
f0104ace:	0f 88 24 04 00 00    	js     f0104ef8 <syscall+0x5cf>
	e->env_status = status;
f0104ad4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104ad7:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104ada:	89 78 54             	mov    %edi,0x54(%eax)
	return 0;
f0104add:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104ae2:	e9 11 04 00 00       	jmp    f0104ef8 <syscall+0x5cf>
		return -E_INVAL;
f0104ae7:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		}
		case SYS_env_set_status:
		{
			return sys_env_set_status((envid_t)a1,(int)a2);
f0104aec:	e9 07 04 00 00       	jmp    f0104ef8 <syscall+0x5cf>
	if((uintptr_t)va >= UTOP || (uintptr_t)va % PGSIZE)
f0104af1:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104af8:	0f 87 84 00 00 00    	ja     f0104b82 <syscall+0x259>
f0104afe:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0104b01:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
	if((perm & ~(PTE_SYSCALL)) || ((perm & needed_perm) != needed_perm))
f0104b07:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b0a:	25 f8 f1 ff ff       	and    $0xfffff1f8,%eax
f0104b0f:	09 c3                	or     %eax,%ebx
f0104b11:	75 79                	jne    f0104b8c <syscall+0x263>
f0104b13:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b16:	83 e0 05             	and    $0x5,%eax
f0104b19:	83 f8 05             	cmp    $0x5,%eax
f0104b1c:	75 78                	jne    f0104b96 <syscall+0x26d>
	struct Env* e = NULL;
f0104b1e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f0104b25:	83 ec 04             	sub    $0x4,%esp
f0104b28:	6a 01                	push   $0x1
f0104b2a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104b2d:	50                   	push   %eax
f0104b2e:	ff 75 0c             	pushl  0xc(%ebp)
f0104b31:	e8 74 e5 ff ff       	call   f01030aa <envid2env>
	if(ret<0)
f0104b36:	83 c4 10             	add    $0x10,%esp
f0104b39:	85 c0                	test   %eax,%eax
f0104b3b:	78 63                	js     f0104ba0 <syscall+0x277>
	struct PageInfo* pg = page_alloc(ALLOC_ZERO);
f0104b3d:	83 ec 0c             	sub    $0xc,%esp
f0104b40:	6a 01                	push   $0x1
f0104b42:	e8 33 c4 ff ff       	call   f0100f7a <page_alloc>
f0104b47:	89 c6                	mov    %eax,%esi
	if(!pg)
f0104b49:	83 c4 10             	add    $0x10,%esp
f0104b4c:	85 c0                	test   %eax,%eax
f0104b4e:	74 57                	je     f0104ba7 <syscall+0x27e>
	ret = page_insert(e->env_pgdir,pg,va,perm);
f0104b50:	ff 75 14             	pushl  0x14(%ebp)
f0104b53:	ff 75 10             	pushl  0x10(%ebp)
f0104b56:	50                   	push   %eax
f0104b57:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104b5a:	ff 70 60             	pushl  0x60(%eax)
f0104b5d:	e8 cd c6 ff ff       	call   f010122f <page_insert>
f0104b62:	89 c7                	mov    %eax,%edi
	if(ret < 0)
f0104b64:	83 c4 10             	add    $0x10,%esp
f0104b67:	85 c0                	test   %eax,%eax
f0104b69:	0f 89 89 03 00 00    	jns    f0104ef8 <syscall+0x5cf>
		page_free(pg);
f0104b6f:	83 ec 0c             	sub    $0xc,%esp
f0104b72:	56                   	push   %esi
f0104b73:	e8 7b c4 ff ff       	call   f0100ff3 <page_free>
		return ret;
f0104b78:	83 c4 10             	add    $0x10,%esp
f0104b7b:	89 fb                	mov    %edi,%ebx
f0104b7d:	e9 76 03 00 00       	jmp    f0104ef8 <syscall+0x5cf>
		return -E_INVAL;
f0104b82:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104b87:	e9 6c 03 00 00       	jmp    f0104ef8 <syscall+0x5cf>
		return -E_INVAL;
f0104b8c:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104b91:	e9 62 03 00 00       	jmp    f0104ef8 <syscall+0x5cf>
f0104b96:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104b9b:	e9 58 03 00 00       	jmp    f0104ef8 <syscall+0x5cf>
		return ret;
f0104ba0:	89 c3                	mov    %eax,%ebx
f0104ba2:	e9 51 03 00 00       	jmp    f0104ef8 <syscall+0x5cf>
		return -E_NO_MEM;
f0104ba7:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
		}
		case SYS_page_alloc:
		{
			return sys_page_alloc((envid_t)a1,(void*)a2,(int)a3);
f0104bac:	e9 47 03 00 00       	jmp    f0104ef8 <syscall+0x5cf>
	if((uintptr_t)srcva>=UTOP || (uintptr_t)srcva % PGSIZE 
f0104bb1:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104bb8:	0f 87 d7 00 00 00    	ja     f0104c95 <syscall+0x36c>
	|| (uintptr_t)dstva>=UTOP || (uintptr_t)dstva % PGSIZE)
f0104bbe:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104bc5:	0f 87 d4 00 00 00    	ja     f0104c9f <syscall+0x376>
	if((perm & ~(PTE_SYSCALL)) || ((perm & needed_perm) != needed_perm))
f0104bcb:	8b 45 10             	mov    0x10(%ebp),%eax
f0104bce:	0b 45 18             	or     0x18(%ebp),%eax
f0104bd1:	25 ff 0f 00 00       	and    $0xfff,%eax
f0104bd6:	8b 55 1c             	mov    0x1c(%ebp),%edx
f0104bd9:	81 e2 f8 f1 ff ff    	and    $0xfffff1f8,%edx
f0104bdf:	09 d0                	or     %edx,%eax
f0104be1:	0f 85 c2 00 00 00    	jne    f0104ca9 <syscall+0x380>
f0104be7:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0104bea:	83 e0 05             	and    $0x5,%eax
f0104bed:	83 f8 05             	cmp    $0x5,%eax
f0104bf0:	0f 85 bd 00 00 00    	jne    f0104cb3 <syscall+0x38a>
	struct Env* srce = NULL, *dste = NULL;
f0104bf6:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0104bfd:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	int ret = envid2env(srcenvid,&srce,true);
f0104c04:	83 ec 04             	sub    $0x4,%esp
f0104c07:	6a 01                	push   $0x1
f0104c09:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0104c0c:	50                   	push   %eax
f0104c0d:	ff 75 0c             	pushl  0xc(%ebp)
f0104c10:	e8 95 e4 ff ff       	call   f01030aa <envid2env>
f0104c15:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104c17:	83 c4 10             	add    $0x10,%esp
f0104c1a:	85 c0                	test   %eax,%eax
f0104c1c:	0f 88 d6 02 00 00    	js     f0104ef8 <syscall+0x5cf>
	ret = envid2env(dstenvid,&dste,true);
f0104c22:	83 ec 04             	sub    $0x4,%esp
f0104c25:	6a 01                	push   $0x1
f0104c27:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104c2a:	50                   	push   %eax
f0104c2b:	ff 75 14             	pushl  0x14(%ebp)
f0104c2e:	e8 77 e4 ff ff       	call   f01030aa <envid2env>
f0104c33:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104c35:	83 c4 10             	add    $0x10,%esp
f0104c38:	85 c0                	test   %eax,%eax
f0104c3a:	0f 88 b8 02 00 00    	js     f0104ef8 <syscall+0x5cf>
	pte_t* pte = NULL;
f0104c40:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	struct PageInfo* pg = page_lookup(srce->env_pgdir,srcva,&pte);
f0104c47:	83 ec 04             	sub    $0x4,%esp
f0104c4a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104c4d:	50                   	push   %eax
f0104c4e:	ff 75 10             	pushl  0x10(%ebp)
f0104c51:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104c54:	ff 70 60             	pushl  0x60(%eax)
f0104c57:	e8 e0 c4 ff ff       	call   f010113c <page_lookup>
	if(!pg)
f0104c5c:	83 c4 10             	add    $0x10,%esp
f0104c5f:	85 c0                	test   %eax,%eax
f0104c61:	74 5a                	je     f0104cbd <syscall+0x394>
	if((!((*pte) & PTE_W)) && (perm & PTE_W))
f0104c63:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104c66:	f6 02 02             	testb  $0x2,(%edx)
f0104c69:	75 06                	jne    f0104c71 <syscall+0x348>
f0104c6b:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104c6f:	75 56                	jne    f0104cc7 <syscall+0x39e>
	ret = page_insert(dste->env_pgdir,pg,dstva,perm);
f0104c71:	ff 75 1c             	pushl  0x1c(%ebp)
f0104c74:	ff 75 18             	pushl  0x18(%ebp)
f0104c77:	50                   	push   %eax
f0104c78:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104c7b:	ff 70 60             	pushl  0x60(%eax)
f0104c7e:	e8 ac c5 ff ff       	call   f010122f <page_insert>
f0104c83:	83 c4 10             	add    $0x10,%esp
f0104c86:	85 c0                	test   %eax,%eax
f0104c88:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104c8d:	0f 4e d8             	cmovle %eax,%ebx
f0104c90:	e9 63 02 00 00       	jmp    f0104ef8 <syscall+0x5cf>
		return -E_INVAL;
f0104c95:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104c9a:	e9 59 02 00 00       	jmp    f0104ef8 <syscall+0x5cf>
f0104c9f:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104ca4:	e9 4f 02 00 00       	jmp    f0104ef8 <syscall+0x5cf>
		return -E_INVAL;
f0104ca9:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104cae:	e9 45 02 00 00       	jmp    f0104ef8 <syscall+0x5cf>
f0104cb3:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104cb8:	e9 3b 02 00 00       	jmp    f0104ef8 <syscall+0x5cf>
		return -E_INVAL;
f0104cbd:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104cc2:	e9 31 02 00 00       	jmp    f0104ef8 <syscall+0x5cf>
		return -E_INVAL;
f0104cc7:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		}
		case SYS_page_map:
		{
			return sys_page_map((envid_t)a1,(void*)a2,(envid_t)a3,(void*)a4,(int)a5);
f0104ccc:	e9 27 02 00 00       	jmp    f0104ef8 <syscall+0x5cf>
	if((uintptr_t)va >= UTOP || (uintptr_t)va % PGSIZE)
f0104cd1:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104cd8:	77 4c                	ja     f0104d26 <syscall+0x3fd>
f0104cda:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104ce1:	75 4d                	jne    f0104d30 <syscall+0x407>
	struct Env* e = NULL;
f0104ce3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f0104cea:	83 ec 04             	sub    $0x4,%esp
f0104ced:	6a 01                	push   $0x1
f0104cef:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104cf2:	50                   	push   %eax
f0104cf3:	ff 75 0c             	pushl  0xc(%ebp)
f0104cf6:	e8 af e3 ff ff       	call   f01030aa <envid2env>
f0104cfb:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104cfd:	83 c4 10             	add    $0x10,%esp
f0104d00:	85 c0                	test   %eax,%eax
f0104d02:	0f 88 f0 01 00 00    	js     f0104ef8 <syscall+0x5cf>
	page_remove(e->env_pgdir,va);
f0104d08:	83 ec 08             	sub    $0x8,%esp
f0104d0b:	ff 75 10             	pushl  0x10(%ebp)
f0104d0e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104d11:	ff 70 60             	pushl  0x60(%eax)
f0104d14:	e8 c5 c4 ff ff       	call   f01011de <page_remove>
	return 0;
f0104d19:	83 c4 10             	add    $0x10,%esp
f0104d1c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104d21:	e9 d2 01 00 00       	jmp    f0104ef8 <syscall+0x5cf>
		return -E_INVAL;
f0104d26:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104d2b:	e9 c8 01 00 00       	jmp    f0104ef8 <syscall+0x5cf>
f0104d30:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		}
		case SYS_page_unmap:
		{
			return sys_page_unmap((envid_t)a1,(void*)a2);
f0104d35:	e9 be 01 00 00       	jmp    f0104ef8 <syscall+0x5cf>
	struct Env* e = NULL;
f0104d3a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f0104d41:	83 ec 04             	sub    $0x4,%esp
f0104d44:	6a 01                	push   $0x1
f0104d46:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104d49:	50                   	push   %eax
f0104d4a:	ff 75 0c             	pushl  0xc(%ebp)
f0104d4d:	e8 58 e3 ff ff       	call   f01030aa <envid2env>
f0104d52:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104d54:	83 c4 10             	add    $0x10,%esp
f0104d57:	85 c0                	test   %eax,%eax
f0104d59:	0f 88 99 01 00 00    	js     f0104ef8 <syscall+0x5cf>
	e->env_pgfault_upcall = func;
f0104d5f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104d62:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104d65:	89 48 64             	mov    %ecx,0x64(%eax)
	return 0;
f0104d68:	bb 00 00 00 00       	mov    $0x0,%ebx
		}
		case SYS_env_set_pgfault_upcall:
		{
			return sys_env_set_pgfault_upcall((envid_t)a1,(void*)a2);
f0104d6d:	e9 86 01 00 00       	jmp    f0104ef8 <syscall+0x5cf>
	struct Env* dst = NULL;
f0104d72:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	if((ret = envid2env(envid,&dst,false)) < 0)
f0104d79:	83 ec 04             	sub    $0x4,%esp
f0104d7c:	6a 00                	push   $0x0
f0104d7e:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104d81:	50                   	push   %eax
f0104d82:	ff 75 0c             	pushl  0xc(%ebp)
f0104d85:	e8 20 e3 ff ff       	call   f01030aa <envid2env>
f0104d8a:	89 c3                	mov    %eax,%ebx
f0104d8c:	83 c4 10             	add    $0x10,%esp
f0104d8f:	85 c0                	test   %eax,%eax
f0104d91:	0f 88 61 01 00 00    	js     f0104ef8 <syscall+0x5cf>
	if(!dst->env_ipc_recving)
f0104d97:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104d9a:	80 78 68 00          	cmpb   $0x0,0x68(%eax)
f0104d9e:	0f 84 e8 00 00 00    	je     f0104e8c <syscall+0x563>
	if((uintptr_t)srcva < UTOP)
f0104da4:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f0104dab:	77 7b                	ja     f0104e28 <syscall+0x4ff>
		if(((perm_needed & perm) != perm_needed) || (perm & (~PTE_SYSCALL)))
f0104dad:	8b 45 18             	mov    0x18(%ebp),%eax
f0104db0:	83 e0 05             	and    $0x5,%eax
			return -E_INVAL;
f0104db3:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		if(((perm_needed & perm) != perm_needed) || (perm & (~PTE_SYSCALL)))
f0104db8:	83 f8 05             	cmp    $0x5,%eax
f0104dbb:	0f 85 37 01 00 00    	jne    f0104ef8 <syscall+0x5cf>
		if((uintptr_t)srcva % PGSIZE)
f0104dc1:	8b 55 14             	mov    0x14(%ebp),%edx
f0104dc4:	81 e2 ff 0f 00 00    	and    $0xfff,%edx
		if(((perm_needed & perm) != perm_needed) || (perm & (~PTE_SYSCALL)))
f0104dca:	8b 45 18             	mov    0x18(%ebp),%eax
f0104dcd:	25 f8 f1 ff ff       	and    $0xfffff1f8,%eax
f0104dd2:	09 c2                	or     %eax,%edx
f0104dd4:	0f 85 1e 01 00 00    	jne    f0104ef8 <syscall+0x5cf>
		pte_t* pte = NULL;
f0104dda:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		struct PageInfo* pg = page_lookup(curenv->env_pgdir,srcva,&pte);
f0104de1:	e8 68 13 00 00       	call   f010614e <cpunum>
f0104de6:	83 ec 04             	sub    $0x4,%esp
f0104de9:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104dec:	52                   	push   %edx
f0104ded:	ff 75 14             	pushl  0x14(%ebp)
f0104df0:	6b c0 74             	imul   $0x74,%eax,%eax
f0104df3:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f0104df9:	ff 70 60             	pushl  0x60(%eax)
f0104dfc:	e8 3b c3 ff ff       	call   f010113c <page_lookup>
		if(!pg)
f0104e01:	83 c4 10             	add    $0x10,%esp
f0104e04:	85 c0                	test   %eax,%eax
f0104e06:	74 7d                	je     f0104e85 <syscall+0x55c>
		if((perm & PTE_W) && !(*pte & PTE_W))
f0104e08:	f6 45 18 02          	testb  $0x2,0x18(%ebp)
f0104e0c:	74 0c                	je     f0104e1a <syscall+0x4f1>
f0104e0e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104e11:	f6 02 02             	testb  $0x2,(%edx)
f0104e14:	0f 84 de 00 00 00    	je     f0104ef8 <syscall+0x5cf>
		if((uintptr_t)dst->env_ipc_dstva<UTOP)
f0104e1a:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0104e1d:	8b 4a 6c             	mov    0x6c(%edx),%ecx
f0104e20:	81 f9 ff ff bf ee    	cmp    $0xeebfffff,%ecx
f0104e26:	76 45                	jbe    f0104e6d <syscall+0x544>
	dst->env_ipc_recving = 0;
f0104e28:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104e2b:	c6 40 68 00          	movb   $0x0,0x68(%eax)
	dst->env_ipc_from = curenv->env_id;
f0104e2f:	e8 1a 13 00 00       	call   f010614e <cpunum>
f0104e34:	89 c2                	mov    %eax,%edx
f0104e36:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104e39:	6b d2 74             	imul   $0x74,%edx,%edx
f0104e3c:	8b 92 28 a0 23 f0    	mov    -0xfdc5fd8(%edx),%edx
f0104e42:	8b 52 48             	mov    0x48(%edx),%edx
f0104e45:	89 50 74             	mov    %edx,0x74(%eax)
	dst->env_ipc_value = value;
f0104e48:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104e4b:	89 48 70             	mov    %ecx,0x70(%eax)
	dst->env_ipc_perm = perm;
f0104e4e:	c7 40 78 00 00 00 00 	movl   $0x0,0x78(%eax)
	dst->env_status = ENV_RUNNABLE;
f0104e55:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	dst->env_tf.tf_regs.reg_eax = 0;
f0104e5c:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return 0;
f0104e63:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104e68:	e9 8b 00 00 00       	jmp    f0104ef8 <syscall+0x5cf>
			if((ret = page_insert(dst->env_pgdir,pg,dst->env_ipc_dstva,perm)) < 0)
f0104e6d:	ff 75 18             	pushl  0x18(%ebp)
f0104e70:	51                   	push   %ecx
f0104e71:	50                   	push   %eax
f0104e72:	ff 72 60             	pushl  0x60(%edx)
f0104e75:	e8 b5 c3 ff ff       	call   f010122f <page_insert>
f0104e7a:	89 c3                	mov    %eax,%ebx
f0104e7c:	83 c4 10             	add    $0x10,%esp
f0104e7f:	85 c0                	test   %eax,%eax
f0104e81:	79 a5                	jns    f0104e28 <syscall+0x4ff>
f0104e83:	eb 73                	jmp    f0104ef8 <syscall+0x5cf>
			return -E_INVAL;
f0104e85:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104e8a:	eb 6c                	jmp    f0104ef8 <syscall+0x5cf>
		return -E_IPC_NOT_RECV;
f0104e8c:	bb f9 ff ff ff       	mov    $0xfffffff9,%ebx
		}
		case SYS_ipc_try_send:
		{
			return sys_ipc_try_send((envid_t)a1,(uint32_t)a2,(void*)a3,(unsigned int)a4);
f0104e91:	eb 65                	jmp    f0104ef8 <syscall+0x5cf>
	if((uintptr_t)dstva<UTOP && (uintptr_t)dstva%PGSIZE)
f0104e93:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f0104e9a:	77 10                	ja     f0104eac <syscall+0x583>
f0104e9c:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
f0104ea3:	74 07                	je     f0104eac <syscall+0x583>
		}
		case SYS_ipc_recv:
		{
			return sys_ipc_recv((void*)a1);
f0104ea5:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104eaa:	eb 4c                	jmp    f0104ef8 <syscall+0x5cf>
	curenv->env_ipc_recving = 1;
f0104eac:	e8 9d 12 00 00       	call   f010614e <cpunum>
f0104eb1:	6b c0 74             	imul   $0x74,%eax,%eax
f0104eb4:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f0104eba:	c6 40 68 01          	movb   $0x1,0x68(%eax)
	curenv->env_ipc_dstva = dstva;
f0104ebe:	e8 8b 12 00 00       	call   f010614e <cpunum>
f0104ec3:	6b c0 74             	imul   $0x74,%eax,%eax
f0104ec6:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f0104ecc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104ecf:	89 48 6c             	mov    %ecx,0x6c(%eax)
	curenv->env_status = ENV_NOT_RUNNABLE;
f0104ed2:	e8 77 12 00 00       	call   f010614e <cpunum>
f0104ed7:	6b c0 74             	imul   $0x74,%eax,%eax
f0104eda:	8b 80 28 a0 23 f0    	mov    -0xfdc5fd8(%eax),%eax
f0104ee0:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	sched_yield();
f0104ee7:	e8 85 f9 ff ff       	call   f0104871 <sched_yield>
			return 0;
f0104eec:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104ef1:	eb 05                	jmp    f0104ef8 <syscall+0x5cf>
f0104ef3:	bb 00 00 00 00       	mov    $0x0,%ebx
		}
		default:
			return -E_INVAL;
	}
}
f0104ef8:	89 d8                	mov    %ebx,%eax
f0104efa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104efd:	5b                   	pop    %ebx
f0104efe:	5e                   	pop    %esi
f0104eff:	5f                   	pop    %edi
f0104f00:	5d                   	pop    %ebp
f0104f01:	c3                   	ret    

f0104f02 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104f02:	55                   	push   %ebp
f0104f03:	89 e5                	mov    %esp,%ebp
f0104f05:	57                   	push   %edi
f0104f06:	56                   	push   %esi
f0104f07:	53                   	push   %ebx
f0104f08:	83 ec 14             	sub    $0x14,%esp
f0104f0b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104f0e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104f11:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104f14:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104f17:	8b 1a                	mov    (%edx),%ebx
f0104f19:	8b 01                	mov    (%ecx),%eax
f0104f1b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104f1e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104f25:	eb 23                	jmp    f0104f4a <stab_binsearch+0x48>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104f27:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0104f2a:	eb 1e                	jmp    f0104f4a <stab_binsearch+0x48>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104f2c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104f2f:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104f32:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104f36:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104f39:	73 46                	jae    f0104f81 <stab_binsearch+0x7f>
			*region_left = m;
f0104f3b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104f3e:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104f40:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f0104f43:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0104f4a:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104f4d:	7f 5f                	jg     f0104fae <stab_binsearch+0xac>
		int true_m = (l + r) / 2, m = true_m;
f0104f4f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104f52:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f0104f55:	89 d0                	mov    %edx,%eax
f0104f57:	c1 e8 1f             	shr    $0x1f,%eax
f0104f5a:	01 d0                	add    %edx,%eax
f0104f5c:	89 c7                	mov    %eax,%edi
f0104f5e:	d1 ff                	sar    %edi
f0104f60:	83 e0 fe             	and    $0xfffffffe,%eax
f0104f63:	01 f8                	add    %edi,%eax
f0104f65:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104f68:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0104f6c:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f0104f6e:	39 c3                	cmp    %eax,%ebx
f0104f70:	7f b5                	jg     f0104f27 <stab_binsearch+0x25>
f0104f72:	0f b6 0a             	movzbl (%edx),%ecx
f0104f75:	83 ea 0c             	sub    $0xc,%edx
f0104f78:	39 f1                	cmp    %esi,%ecx
f0104f7a:	74 b0                	je     f0104f2c <stab_binsearch+0x2a>
			m--;
f0104f7c:	83 e8 01             	sub    $0x1,%eax
f0104f7f:	eb ed                	jmp    f0104f6e <stab_binsearch+0x6c>
		} else if (stabs[m].n_value > addr) {
f0104f81:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104f84:	76 14                	jbe    f0104f9a <stab_binsearch+0x98>
			*region_right = m - 1;
f0104f86:	83 e8 01             	sub    $0x1,%eax
f0104f89:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104f8c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104f8f:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f0104f91:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104f98:	eb b0                	jmp    f0104f4a <stab_binsearch+0x48>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104f9a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104f9d:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0104f9f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104fa3:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f0104fa5:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104fac:	eb 9c                	jmp    f0104f4a <stab_binsearch+0x48>
		}
	}

	if (!any_matches)
f0104fae:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104fb2:	75 15                	jne    f0104fc9 <stab_binsearch+0xc7>
		*region_right = *region_left - 1;
f0104fb4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104fb7:	8b 00                	mov    (%eax),%eax
f0104fb9:	83 e8 01             	sub    $0x1,%eax
f0104fbc:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104fbf:	89 07                	mov    %eax,(%edi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0104fc1:	83 c4 14             	add    $0x14,%esp
f0104fc4:	5b                   	pop    %ebx
f0104fc5:	5e                   	pop    %esi
f0104fc6:	5f                   	pop    %edi
f0104fc7:	5d                   	pop    %ebp
f0104fc8:	c3                   	ret    
		for (l = *region_right;
f0104fc9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104fcc:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104fce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104fd1:	8b 0f                	mov    (%edi),%ecx
f0104fd3:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104fd6:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0104fd9:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
		for (l = *region_right;
f0104fdd:	eb 03                	jmp    f0104fe2 <stab_binsearch+0xe0>
		     l--)
f0104fdf:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0104fe2:	39 c1                	cmp    %eax,%ecx
f0104fe4:	7d 0a                	jge    f0104ff0 <stab_binsearch+0xee>
		     l > *region_left && stabs[l].n_type != type;
f0104fe6:	0f b6 1a             	movzbl (%edx),%ebx
f0104fe9:	83 ea 0c             	sub    $0xc,%edx
f0104fec:	39 f3                	cmp    %esi,%ebx
f0104fee:	75 ef                	jne    f0104fdf <stab_binsearch+0xdd>
		*region_left = l;
f0104ff0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104ff3:	89 07                	mov    %eax,(%edi)
}
f0104ff5:	eb ca                	jmp    f0104fc1 <stab_binsearch+0xbf>

f0104ff7 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104ff7:	f3 0f 1e fb          	endbr32 
f0104ffb:	55                   	push   %ebp
f0104ffc:	89 e5                	mov    %esp,%ebp
f0104ffe:	57                   	push   %edi
f0104fff:	56                   	push   %esi
f0105000:	53                   	push   %ebx
f0105001:	83 ec 4c             	sub    $0x4c,%esp
f0105004:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105007:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010500a:	c7 03 18 80 10 f0    	movl   $0xf0108018,(%ebx)
	info->eip_line = 0;
f0105010:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0105017:	c7 43 08 18 80 10 f0 	movl   $0xf0108018,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010501e:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0105025:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0105028:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010502f:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0105035:	0f 86 32 01 00 00    	jbe    f010516d <debuginfo_eip+0x176>
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010503b:	c7 45 b4 c9 89 11 f0 	movl   $0xf01189c9,-0x4c(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0105042:	c7 45 b8 15 52 11 f0 	movl   $0xf0115215,-0x48(%ebp)
		stab_end = __STAB_END__;
f0105049:	be 14 52 11 f0       	mov    $0xf0115214,%esi
		stabs = __STAB_BEGIN__;
f010504e:	c7 45 bc f4 84 10 f0 	movl   $0xf01084f4,-0x44(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0105055:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f0105058:	39 4d b8             	cmp    %ecx,-0x48(%ebp)
f010505b:	0f 83 62 02 00 00    	jae    f01052c3 <debuginfo_eip+0x2cc>
f0105061:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0105065:	0f 85 5f 02 00 00    	jne    f01052ca <debuginfo_eip+0x2d3>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010506b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0105072:	2b 75 bc             	sub    -0x44(%ebp),%esi
f0105075:	c1 fe 02             	sar    $0x2,%esi
f0105078:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f010507e:	83 e8 01             	sub    $0x1,%eax
f0105081:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0105084:	83 ec 08             	sub    $0x8,%esp
f0105087:	57                   	push   %edi
f0105088:	6a 64                	push   $0x64
f010508a:	8d 55 e0             	lea    -0x20(%ebp),%edx
f010508d:	89 d1                	mov    %edx,%ecx
f010508f:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0105092:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0105095:	89 f0                	mov    %esi,%eax
f0105097:	e8 66 fe ff ff       	call   f0104f02 <stab_binsearch>
	if (lfile == 0)
f010509c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010509f:	83 c4 10             	add    $0x10,%esp
f01050a2:	85 c0                	test   %eax,%eax
f01050a4:	0f 84 27 02 00 00    	je     f01052d1 <debuginfo_eip+0x2da>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01050aa:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01050ad:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01050b0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01050b3:	83 ec 08             	sub    $0x8,%esp
f01050b6:	57                   	push   %edi
f01050b7:	6a 24                	push   $0x24
f01050b9:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01050bc:	89 d1                	mov    %edx,%ecx
f01050be:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01050c1:	89 f0                	mov    %esi,%eax
f01050c3:	e8 3a fe ff ff       	call   f0104f02 <stab_binsearch>

	if (lfun <= rfun) {
f01050c8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01050cb:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01050ce:	83 c4 10             	add    $0x10,%esp
f01050d1:	39 d0                	cmp    %edx,%eax
f01050d3:	0f 8f 34 01 00 00    	jg     f010520d <debuginfo_eip+0x216>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01050d9:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01050dc:	8d 34 8e             	lea    (%esi,%ecx,4),%esi
f01050df:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f01050e2:	8b 36                	mov    (%esi),%esi
f01050e4:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f01050e7:	2b 4d b8             	sub    -0x48(%ebp),%ecx
f01050ea:	39 ce                	cmp    %ecx,%esi
f01050ec:	73 06                	jae    f01050f4 <debuginfo_eip+0xfd>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01050ee:	03 75 b8             	add    -0x48(%ebp),%esi
f01050f1:	89 73 08             	mov    %esi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01050f4:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01050f7:	8b 4e 08             	mov    0x8(%esi),%ecx
f01050fa:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01050fd:	29 cf                	sub    %ecx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f01050ff:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0105102:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0105105:	83 ec 08             	sub    $0x8,%esp
f0105108:	6a 3a                	push   $0x3a
f010510a:	ff 73 08             	pushl  0x8(%ebx)
f010510d:	e8 fe 09 00 00       	call   f0105b10 <strfind>
f0105112:	2b 43 08             	sub    0x8(%ebx),%eax
f0105115:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	info->eip_file = stabstr +stabs[lfile].n_strx;
f0105118:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010511b:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010511e:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0105121:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0105124:	03 0c 86             	add    (%esi,%eax,4),%ecx
f0105127:	89 0b                	mov    %ecx,(%ebx)
	stab_binsearch(stabs, &lline, &rline,N_SLINE,addr);
f0105129:	83 c4 08             	add    $0x8,%esp
f010512c:	57                   	push   %edi
f010512d:	6a 44                	push   $0x44
f010512f:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0105132:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0105135:	89 f0                	mov    %esi,%eax
f0105137:	e8 c6 fd ff ff       	call   f0104f02 <stab_binsearch>
	if(lline>rline)
f010513c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010513f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0105142:	83 c4 10             	add    $0x10,%esp
f0105145:	39 c2                	cmp    %eax,%edx
f0105147:	0f 8f 8b 01 00 00    	jg     f01052d8 <debuginfo_eip+0x2e1>
	{
		return -1;
	}
	else
	{
		info->eip_line = stabs[rline].n_desc;
f010514d:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0105150:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0105155:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0105158:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010515b:	89 d0                	mov    %edx,%eax
f010515d:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0105160:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
f0105164:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0105168:	e9 be 00 00 00       	jmp    f010522b <debuginfo_eip+0x234>
		if(user_mem_check(curenv,usd,sizeof(struct UserStabData),PTE_P|PTE_U) != 0)
f010516d:	e8 dc 0f 00 00       	call   f010614e <cpunum>
f0105172:	6a 05                	push   $0x5
f0105174:	6a 10                	push   $0x10
f0105176:	68 00 00 20 00       	push   $0x200000
f010517b:	6b c0 74             	imul   $0x74,%eax,%eax
f010517e:	ff b0 28 a0 23 f0    	pushl  -0xfdc5fd8(%eax)
f0105184:	e8 a1 dd ff ff       	call   f0102f2a <user_mem_check>
f0105189:	83 c4 10             	add    $0x10,%esp
f010518c:	85 c0                	test   %eax,%eax
f010518e:	0f 85 21 01 00 00    	jne    f01052b5 <debuginfo_eip+0x2be>
		stabs = usd->stabs;
f0105194:	a1 00 00 20 00       	mov    0x200000,%eax
f0105199:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stab_end = usd->stab_end;
f010519c:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f01051a2:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f01051a8:	89 4d b8             	mov    %ecx,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f01051ab:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f01051b1:	89 55 b4             	mov    %edx,-0x4c(%ebp)
		if(user_mem_check(curenv,stabs,sizeof(struct Stab),PTE_P|PTE_U) != 0)
f01051b4:	e8 95 0f 00 00       	call   f010614e <cpunum>
f01051b9:	6a 05                	push   $0x5
f01051bb:	6a 0c                	push   $0xc
f01051bd:	ff 75 bc             	pushl  -0x44(%ebp)
f01051c0:	6b c0 74             	imul   $0x74,%eax,%eax
f01051c3:	ff b0 28 a0 23 f0    	pushl  -0xfdc5fd8(%eax)
f01051c9:	e8 5c dd ff ff       	call   f0102f2a <user_mem_check>
f01051ce:	83 c4 10             	add    $0x10,%esp
f01051d1:	85 c0                	test   %eax,%eax
f01051d3:	0f 85 e3 00 00 00    	jne    f01052bc <debuginfo_eip+0x2c5>
		if(user_mem_check(curenv,stabstr,stabstr_end-stabstr,PTE_P|PTE_U) != 0)
f01051d9:	e8 70 0f 00 00       	call   f010614e <cpunum>
f01051de:	6a 05                	push   $0x5
f01051e0:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f01051e3:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f01051e6:	29 ca                	sub    %ecx,%edx
f01051e8:	52                   	push   %edx
f01051e9:	51                   	push   %ecx
f01051ea:	6b c0 74             	imul   $0x74,%eax,%eax
f01051ed:	ff b0 28 a0 23 f0    	pushl  -0xfdc5fd8(%eax)
f01051f3:	e8 32 dd ff ff       	call   f0102f2a <user_mem_check>
f01051f8:	83 c4 10             	add    $0x10,%esp
f01051fb:	85 c0                	test   %eax,%eax
f01051fd:	0f 84 52 fe ff ff    	je     f0105055 <debuginfo_eip+0x5e>
			return -1;
f0105203:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0105208:	e9 d7 00 00 00       	jmp    f01052e4 <debuginfo_eip+0x2ed>
		info->eip_fn_addr = addr;
f010520d:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f0105210:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105213:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0105216:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105219:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010521c:	e9 e4 fe ff ff       	jmp    f0105105 <debuginfo_eip+0x10e>
f0105221:	83 e8 01             	sub    $0x1,%eax
f0105224:	83 ea 0c             	sub    $0xc,%edx
	while (lline >= lfile
f0105227:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f010522b:	89 45 c0             	mov    %eax,-0x40(%ebp)
f010522e:	39 c7                	cmp    %eax,%edi
f0105230:	7f 43                	jg     f0105275 <debuginfo_eip+0x27e>
	       && stabs[lline].n_type != N_SOL
f0105232:	0f b6 0a             	movzbl (%edx),%ecx
f0105235:	80 f9 84             	cmp    $0x84,%cl
f0105238:	74 19                	je     f0105253 <debuginfo_eip+0x25c>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010523a:	80 f9 64             	cmp    $0x64,%cl
f010523d:	75 e2                	jne    f0105221 <debuginfo_eip+0x22a>
f010523f:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0105243:	74 dc                	je     f0105221 <debuginfo_eip+0x22a>
f0105245:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0105249:	74 11                	je     f010525c <debuginfo_eip+0x265>
f010524b:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010524e:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0105251:	eb 09                	jmp    f010525c <debuginfo_eip+0x265>
f0105253:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0105257:	74 03                	je     f010525c <debuginfo_eip+0x265>
f0105259:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010525c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010525f:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0105262:	8b 04 87             	mov    (%edi,%eax,4),%eax
f0105265:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f0105268:	8b 7d b8             	mov    -0x48(%ebp),%edi
f010526b:	29 fa                	sub    %edi,%edx
f010526d:	39 d0                	cmp    %edx,%eax
f010526f:	73 04                	jae    f0105275 <debuginfo_eip+0x27e>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0105271:	01 f8                	add    %edi,%eax
f0105273:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0105275:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0105278:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010527b:	ba 00 00 00 00       	mov    $0x0,%edx
	if (lfun < rfun)
f0105280:	39 f0                	cmp    %esi,%eax
f0105282:	7d 60                	jge    f01052e4 <debuginfo_eip+0x2ed>
		for (lline = lfun + 1;
f0105284:	8d 50 01             	lea    0x1(%eax),%edx
f0105287:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010528a:	89 d0                	mov    %edx,%eax
f010528c:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010528f:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0105292:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
f0105296:	eb 04                	jmp    f010529c <debuginfo_eip+0x2a5>
			info->eip_fn_narg++;
f0105298:	83 43 14 01          	addl   $0x1,0x14(%ebx)
		for (lline = lfun + 1;
f010529c:	39 c6                	cmp    %eax,%esi
f010529e:	7e 3f                	jle    f01052df <debuginfo_eip+0x2e8>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01052a0:	0f b6 0a             	movzbl (%edx),%ecx
f01052a3:	83 c0 01             	add    $0x1,%eax
f01052a6:	83 c2 0c             	add    $0xc,%edx
f01052a9:	80 f9 a0             	cmp    $0xa0,%cl
f01052ac:	74 ea                	je     f0105298 <debuginfo_eip+0x2a1>
	return 0;
f01052ae:	ba 00 00 00 00       	mov    $0x0,%edx
f01052b3:	eb 2f                	jmp    f01052e4 <debuginfo_eip+0x2ed>
			return -1;
f01052b5:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052ba:	eb 28                	jmp    f01052e4 <debuginfo_eip+0x2ed>
			return -1;
f01052bc:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052c1:	eb 21                	jmp    f01052e4 <debuginfo_eip+0x2ed>
		return -1;
f01052c3:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052c8:	eb 1a                	jmp    f01052e4 <debuginfo_eip+0x2ed>
f01052ca:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052cf:	eb 13                	jmp    f01052e4 <debuginfo_eip+0x2ed>
		return -1;
f01052d1:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052d6:	eb 0c                	jmp    f01052e4 <debuginfo_eip+0x2ed>
		return -1;
f01052d8:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01052dd:	eb 05                	jmp    f01052e4 <debuginfo_eip+0x2ed>
	return 0;
f01052df:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01052e4:	89 d0                	mov    %edx,%eax
f01052e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01052e9:	5b                   	pop    %ebx
f01052ea:	5e                   	pop    %esi
f01052eb:	5f                   	pop    %edi
f01052ec:	5d                   	pop    %ebp
f01052ed:	c3                   	ret    

f01052ee <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01052ee:	55                   	push   %ebp
f01052ef:	89 e5                	mov    %esp,%ebp
f01052f1:	57                   	push   %edi
f01052f2:	56                   	push   %esi
f01052f3:	53                   	push   %ebx
f01052f4:	83 ec 1c             	sub    $0x1c,%esp
f01052f7:	89 c7                	mov    %eax,%edi
f01052f9:	89 d6                	mov    %edx,%esi
f01052fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01052fe:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105301:	89 d1                	mov    %edx,%ecx
f0105303:	89 c2                	mov    %eax,%edx
f0105305:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105308:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010530b:	8b 45 10             	mov    0x10(%ebp),%eax
f010530e:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0105311:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105314:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f010531b:	39 c2                	cmp    %eax,%edx
f010531d:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f0105320:	72 3e                	jb     f0105360 <printnum+0x72>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0105322:	83 ec 0c             	sub    $0xc,%esp
f0105325:	ff 75 18             	pushl  0x18(%ebp)
f0105328:	83 eb 01             	sub    $0x1,%ebx
f010532b:	53                   	push   %ebx
f010532c:	50                   	push   %eax
f010532d:	83 ec 08             	sub    $0x8,%esp
f0105330:	ff 75 e4             	pushl  -0x1c(%ebp)
f0105333:	ff 75 e0             	pushl  -0x20(%ebp)
f0105336:	ff 75 dc             	pushl  -0x24(%ebp)
f0105339:	ff 75 d8             	pushl  -0x28(%ebp)
f010533c:	e8 1f 12 00 00       	call   f0106560 <__udivdi3>
f0105341:	83 c4 18             	add    $0x18,%esp
f0105344:	52                   	push   %edx
f0105345:	50                   	push   %eax
f0105346:	89 f2                	mov    %esi,%edx
f0105348:	89 f8                	mov    %edi,%eax
f010534a:	e8 9f ff ff ff       	call   f01052ee <printnum>
f010534f:	83 c4 20             	add    $0x20,%esp
f0105352:	eb 13                	jmp    f0105367 <printnum+0x79>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0105354:	83 ec 08             	sub    $0x8,%esp
f0105357:	56                   	push   %esi
f0105358:	ff 75 18             	pushl  0x18(%ebp)
f010535b:	ff d7                	call   *%edi
f010535d:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0105360:	83 eb 01             	sub    $0x1,%ebx
f0105363:	85 db                	test   %ebx,%ebx
f0105365:	7f ed                	jg     f0105354 <printnum+0x66>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0105367:	83 ec 08             	sub    $0x8,%esp
f010536a:	56                   	push   %esi
f010536b:	83 ec 04             	sub    $0x4,%esp
f010536e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0105371:	ff 75 e0             	pushl  -0x20(%ebp)
f0105374:	ff 75 dc             	pushl  -0x24(%ebp)
f0105377:	ff 75 d8             	pushl  -0x28(%ebp)
f010537a:	e8 f1 12 00 00       	call   f0106670 <__umoddi3>
f010537f:	83 c4 14             	add    $0x14,%esp
f0105382:	0f be 80 22 80 10 f0 	movsbl -0xfef7fde(%eax),%eax
f0105389:	50                   	push   %eax
f010538a:	ff d7                	call   *%edi
}
f010538c:	83 c4 10             	add    $0x10,%esp
f010538f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105392:	5b                   	pop    %ebx
f0105393:	5e                   	pop    %esi
f0105394:	5f                   	pop    %edi
f0105395:	5d                   	pop    %ebp
f0105396:	c3                   	ret    

f0105397 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0105397:	f3 0f 1e fb          	endbr32 
f010539b:	55                   	push   %ebp
f010539c:	89 e5                	mov    %esp,%ebp
f010539e:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01053a1:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01053a5:	8b 10                	mov    (%eax),%edx
f01053a7:	3b 50 04             	cmp    0x4(%eax),%edx
f01053aa:	73 0a                	jae    f01053b6 <sprintputch+0x1f>
		*b->buf++ = ch;
f01053ac:	8d 4a 01             	lea    0x1(%edx),%ecx
f01053af:	89 08                	mov    %ecx,(%eax)
f01053b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01053b4:	88 02                	mov    %al,(%edx)
}
f01053b6:	5d                   	pop    %ebp
f01053b7:	c3                   	ret    

f01053b8 <printfmt>:
{
f01053b8:	f3 0f 1e fb          	endbr32 
f01053bc:	55                   	push   %ebp
f01053bd:	89 e5                	mov    %esp,%ebp
f01053bf:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f01053c2:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01053c5:	50                   	push   %eax
f01053c6:	ff 75 10             	pushl  0x10(%ebp)
f01053c9:	ff 75 0c             	pushl  0xc(%ebp)
f01053cc:	ff 75 08             	pushl  0x8(%ebp)
f01053cf:	e8 05 00 00 00       	call   f01053d9 <vprintfmt>
}
f01053d4:	83 c4 10             	add    $0x10,%esp
f01053d7:	c9                   	leave  
f01053d8:	c3                   	ret    

f01053d9 <vprintfmt>:
{
f01053d9:	f3 0f 1e fb          	endbr32 
f01053dd:	55                   	push   %ebp
f01053de:	89 e5                	mov    %esp,%ebp
f01053e0:	57                   	push   %edi
f01053e1:	56                   	push   %esi
f01053e2:	53                   	push   %ebx
f01053e3:	83 ec 3c             	sub    $0x3c,%esp
f01053e6:	8b 75 08             	mov    0x8(%ebp),%esi
f01053e9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01053ec:	8b 7d 10             	mov    0x10(%ebp),%edi
f01053ef:	e9 8e 03 00 00       	jmp    f0105782 <vprintfmt+0x3a9>
		padc = ' ';
f01053f4:	c6 45 d3 20          	movb   $0x20,-0x2d(%ebp)
		altflag = 0;
f01053f8:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
		precision = -1;
f01053ff:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f0105406:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f010540d:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0105412:	8d 47 01             	lea    0x1(%edi),%eax
f0105415:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105418:	0f b6 17             	movzbl (%edi),%edx
f010541b:	8d 42 dd             	lea    -0x23(%edx),%eax
f010541e:	3c 55                	cmp    $0x55,%al
f0105420:	0f 87 df 03 00 00    	ja     f0105805 <vprintfmt+0x42c>
f0105426:	0f b6 c0             	movzbl %al,%eax
f0105429:	3e ff 24 85 e0 80 10 	notrack jmp *-0xfef7f20(,%eax,4)
f0105430:	f0 
f0105431:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0105434:	c6 45 d3 2d          	movb   $0x2d,-0x2d(%ebp)
f0105438:	eb d8                	jmp    f0105412 <vprintfmt+0x39>
		switch (ch = *(unsigned char *) fmt++) {
f010543a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010543d:	c6 45 d3 30          	movb   $0x30,-0x2d(%ebp)
f0105441:	eb cf                	jmp    f0105412 <vprintfmt+0x39>
f0105443:	0f b6 d2             	movzbl %dl,%edx
f0105446:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0105449:	b8 00 00 00 00       	mov    $0x0,%eax
f010544e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f0105451:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0105454:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0105458:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f010545b:	8d 4a d0             	lea    -0x30(%edx),%ecx
f010545e:	83 f9 09             	cmp    $0x9,%ecx
f0105461:	77 55                	ja     f01054b8 <vprintfmt+0xdf>
			for (precision = 0; ; ++fmt) {
f0105463:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0105466:	eb e9                	jmp    f0105451 <vprintfmt+0x78>
			precision = va_arg(ap, int);
f0105468:	8b 45 14             	mov    0x14(%ebp),%eax
f010546b:	8b 00                	mov    (%eax),%eax
f010546d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105470:	8b 45 14             	mov    0x14(%ebp),%eax
f0105473:	8d 40 04             	lea    0x4(%eax),%eax
f0105476:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0105479:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f010547c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0105480:	79 90                	jns    f0105412 <vprintfmt+0x39>
				width = precision, precision = -1;
f0105482:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105485:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105488:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f010548f:	eb 81                	jmp    f0105412 <vprintfmt+0x39>
f0105491:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105494:	85 c0                	test   %eax,%eax
f0105496:	ba 00 00 00 00       	mov    $0x0,%edx
f010549b:	0f 49 d0             	cmovns %eax,%edx
f010549e:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01054a1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f01054a4:	e9 69 ff ff ff       	jmp    f0105412 <vprintfmt+0x39>
		switch (ch = *(unsigned char *) fmt++) {
f01054a9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f01054ac:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
			goto reswitch;
f01054b3:	e9 5a ff ff ff       	jmp    f0105412 <vprintfmt+0x39>
f01054b8:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01054bb:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01054be:	eb bc                	jmp    f010547c <vprintfmt+0xa3>
			lflag++;
f01054c0:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f01054c3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f01054c6:	e9 47 ff ff ff       	jmp    f0105412 <vprintfmt+0x39>
			putch(va_arg(ap, int), putdat);
f01054cb:	8b 45 14             	mov    0x14(%ebp),%eax
f01054ce:	8d 78 04             	lea    0x4(%eax),%edi
f01054d1:	83 ec 08             	sub    $0x8,%esp
f01054d4:	53                   	push   %ebx
f01054d5:	ff 30                	pushl  (%eax)
f01054d7:	ff d6                	call   *%esi
			break;
f01054d9:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01054dc:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f01054df:	e9 9b 02 00 00       	jmp    f010577f <vprintfmt+0x3a6>
			err = va_arg(ap, int);
f01054e4:	8b 45 14             	mov    0x14(%ebp),%eax
f01054e7:	8d 78 04             	lea    0x4(%eax),%edi
f01054ea:	8b 00                	mov    (%eax),%eax
f01054ec:	99                   	cltd   
f01054ed:	31 d0                	xor    %edx,%eax
f01054ef:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01054f1:	83 f8 08             	cmp    $0x8,%eax
f01054f4:	7f 23                	jg     f0105519 <vprintfmt+0x140>
f01054f6:	8b 14 85 40 82 10 f0 	mov    -0xfef7dc0(,%eax,4),%edx
f01054fd:	85 d2                	test   %edx,%edx
f01054ff:	74 18                	je     f0105519 <vprintfmt+0x140>
				printfmt(putch, putdat, "%s", p);
f0105501:	52                   	push   %edx
f0105502:	68 55 77 10 f0       	push   $0xf0107755
f0105507:	53                   	push   %ebx
f0105508:	56                   	push   %esi
f0105509:	e8 aa fe ff ff       	call   f01053b8 <printfmt>
f010550e:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0105511:	89 7d 14             	mov    %edi,0x14(%ebp)
f0105514:	e9 66 02 00 00       	jmp    f010577f <vprintfmt+0x3a6>
				printfmt(putch, putdat, "error %d", err);
f0105519:	50                   	push   %eax
f010551a:	68 3a 80 10 f0       	push   $0xf010803a
f010551f:	53                   	push   %ebx
f0105520:	56                   	push   %esi
f0105521:	e8 92 fe ff ff       	call   f01053b8 <printfmt>
f0105526:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0105529:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f010552c:	e9 4e 02 00 00       	jmp    f010577f <vprintfmt+0x3a6>
			if ((p = va_arg(ap, char *)) == NULL)
f0105531:	8b 45 14             	mov    0x14(%ebp),%eax
f0105534:	83 c0 04             	add    $0x4,%eax
f0105537:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010553a:	8b 45 14             	mov    0x14(%ebp),%eax
f010553d:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f010553f:	85 d2                	test   %edx,%edx
f0105541:	b8 33 80 10 f0       	mov    $0xf0108033,%eax
f0105546:	0f 45 c2             	cmovne %edx,%eax
f0105549:	89 45 cc             	mov    %eax,-0x34(%ebp)
			if (width > 0 && padc != '-')
f010554c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0105550:	7e 06                	jle    f0105558 <vprintfmt+0x17f>
f0105552:	80 7d d3 2d          	cmpb   $0x2d,-0x2d(%ebp)
f0105556:	75 0d                	jne    f0105565 <vprintfmt+0x18c>
				for (width -= strnlen(p, precision); width > 0; width--)
f0105558:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010555b:	89 c7                	mov    %eax,%edi
f010555d:	03 45 e0             	add    -0x20(%ebp),%eax
f0105560:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105563:	eb 55                	jmp    f01055ba <vprintfmt+0x1e1>
f0105565:	83 ec 08             	sub    $0x8,%esp
f0105568:	ff 75 d8             	pushl  -0x28(%ebp)
f010556b:	ff 75 cc             	pushl  -0x34(%ebp)
f010556e:	e8 2c 04 00 00       	call   f010599f <strnlen>
f0105573:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0105576:	29 c2                	sub    %eax,%edx
f0105578:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f010557b:	83 c4 10             	add    $0x10,%esp
f010557e:	89 d7                	mov    %edx,%edi
					putch(padc, putdat);
f0105580:	0f be 45 d3          	movsbl -0x2d(%ebp),%eax
f0105584:	89 45 e0             	mov    %eax,-0x20(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0105587:	85 ff                	test   %edi,%edi
f0105589:	7e 11                	jle    f010559c <vprintfmt+0x1c3>
					putch(padc, putdat);
f010558b:	83 ec 08             	sub    $0x8,%esp
f010558e:	53                   	push   %ebx
f010558f:	ff 75 e0             	pushl  -0x20(%ebp)
f0105592:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0105594:	83 ef 01             	sub    $0x1,%edi
f0105597:	83 c4 10             	add    $0x10,%esp
f010559a:	eb eb                	jmp    f0105587 <vprintfmt+0x1ae>
f010559c:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f010559f:	85 d2                	test   %edx,%edx
f01055a1:	b8 00 00 00 00       	mov    $0x0,%eax
f01055a6:	0f 49 c2             	cmovns %edx,%eax
f01055a9:	29 c2                	sub    %eax,%edx
f01055ab:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01055ae:	eb a8                	jmp    f0105558 <vprintfmt+0x17f>
					putch(ch, putdat);
f01055b0:	83 ec 08             	sub    $0x8,%esp
f01055b3:	53                   	push   %ebx
f01055b4:	52                   	push   %edx
f01055b5:	ff d6                	call   *%esi
f01055b7:	83 c4 10             	add    $0x10,%esp
f01055ba:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01055bd:	29 f9                	sub    %edi,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01055bf:	83 c7 01             	add    $0x1,%edi
f01055c2:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01055c6:	0f be d0             	movsbl %al,%edx
f01055c9:	85 d2                	test   %edx,%edx
f01055cb:	74 4b                	je     f0105618 <vprintfmt+0x23f>
f01055cd:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01055d1:	78 06                	js     f01055d9 <vprintfmt+0x200>
f01055d3:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f01055d7:	78 1e                	js     f01055f7 <vprintfmt+0x21e>
				if (altflag && (ch < ' ' || ch > '~'))
f01055d9:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01055dd:	74 d1                	je     f01055b0 <vprintfmt+0x1d7>
f01055df:	0f be c0             	movsbl %al,%eax
f01055e2:	83 e8 20             	sub    $0x20,%eax
f01055e5:	83 f8 5e             	cmp    $0x5e,%eax
f01055e8:	76 c6                	jbe    f01055b0 <vprintfmt+0x1d7>
					putch('?', putdat);
f01055ea:	83 ec 08             	sub    $0x8,%esp
f01055ed:	53                   	push   %ebx
f01055ee:	6a 3f                	push   $0x3f
f01055f0:	ff d6                	call   *%esi
f01055f2:	83 c4 10             	add    $0x10,%esp
f01055f5:	eb c3                	jmp    f01055ba <vprintfmt+0x1e1>
f01055f7:	89 cf                	mov    %ecx,%edi
f01055f9:	eb 0e                	jmp    f0105609 <vprintfmt+0x230>
				putch(' ', putdat);
f01055fb:	83 ec 08             	sub    $0x8,%esp
f01055fe:	53                   	push   %ebx
f01055ff:	6a 20                	push   $0x20
f0105601:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0105603:	83 ef 01             	sub    $0x1,%edi
f0105606:	83 c4 10             	add    $0x10,%esp
f0105609:	85 ff                	test   %edi,%edi
f010560b:	7f ee                	jg     f01055fb <vprintfmt+0x222>
			if ((p = va_arg(ap, char *)) == NULL)
f010560d:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0105610:	89 45 14             	mov    %eax,0x14(%ebp)
f0105613:	e9 67 01 00 00       	jmp    f010577f <vprintfmt+0x3a6>
f0105618:	89 cf                	mov    %ecx,%edi
f010561a:	eb ed                	jmp    f0105609 <vprintfmt+0x230>
	if (lflag >= 2)
f010561c:	83 f9 01             	cmp    $0x1,%ecx
f010561f:	7f 1b                	jg     f010563c <vprintfmt+0x263>
	else if (lflag)
f0105621:	85 c9                	test   %ecx,%ecx
f0105623:	74 63                	je     f0105688 <vprintfmt+0x2af>
		return va_arg(*ap, long);
f0105625:	8b 45 14             	mov    0x14(%ebp),%eax
f0105628:	8b 00                	mov    (%eax),%eax
f010562a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010562d:	99                   	cltd   
f010562e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105631:	8b 45 14             	mov    0x14(%ebp),%eax
f0105634:	8d 40 04             	lea    0x4(%eax),%eax
f0105637:	89 45 14             	mov    %eax,0x14(%ebp)
f010563a:	eb 17                	jmp    f0105653 <vprintfmt+0x27a>
		return va_arg(*ap, long long);
f010563c:	8b 45 14             	mov    0x14(%ebp),%eax
f010563f:	8b 50 04             	mov    0x4(%eax),%edx
f0105642:	8b 00                	mov    (%eax),%eax
f0105644:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105647:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010564a:	8b 45 14             	mov    0x14(%ebp),%eax
f010564d:	8d 40 08             	lea    0x8(%eax),%eax
f0105650:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0105653:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0105656:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0105659:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f010565e:	85 c9                	test   %ecx,%ecx
f0105660:	0f 89 ff 00 00 00    	jns    f0105765 <vprintfmt+0x38c>
				putch('-', putdat);
f0105666:	83 ec 08             	sub    $0x8,%esp
f0105669:	53                   	push   %ebx
f010566a:	6a 2d                	push   $0x2d
f010566c:	ff d6                	call   *%esi
				num = -(long long) num;
f010566e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0105671:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0105674:	f7 da                	neg    %edx
f0105676:	83 d1 00             	adc    $0x0,%ecx
f0105679:	f7 d9                	neg    %ecx
f010567b:	83 c4 10             	add    $0x10,%esp
			base = 10;
f010567e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105683:	e9 dd 00 00 00       	jmp    f0105765 <vprintfmt+0x38c>
		return va_arg(*ap, int);
f0105688:	8b 45 14             	mov    0x14(%ebp),%eax
f010568b:	8b 00                	mov    (%eax),%eax
f010568d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105690:	99                   	cltd   
f0105691:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105694:	8b 45 14             	mov    0x14(%ebp),%eax
f0105697:	8d 40 04             	lea    0x4(%eax),%eax
f010569a:	89 45 14             	mov    %eax,0x14(%ebp)
f010569d:	eb b4                	jmp    f0105653 <vprintfmt+0x27a>
	if (lflag >= 2)
f010569f:	83 f9 01             	cmp    $0x1,%ecx
f01056a2:	7f 1e                	jg     f01056c2 <vprintfmt+0x2e9>
	else if (lflag)
f01056a4:	85 c9                	test   %ecx,%ecx
f01056a6:	74 32                	je     f01056da <vprintfmt+0x301>
		return va_arg(*ap, unsigned long);
f01056a8:	8b 45 14             	mov    0x14(%ebp),%eax
f01056ab:	8b 10                	mov    (%eax),%edx
f01056ad:	b9 00 00 00 00       	mov    $0x0,%ecx
f01056b2:	8d 40 04             	lea    0x4(%eax),%eax
f01056b5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01056b8:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long);
f01056bd:	e9 a3 00 00 00       	jmp    f0105765 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned long long);
f01056c2:	8b 45 14             	mov    0x14(%ebp),%eax
f01056c5:	8b 10                	mov    (%eax),%edx
f01056c7:	8b 48 04             	mov    0x4(%eax),%ecx
f01056ca:	8d 40 08             	lea    0x8(%eax),%eax
f01056cd:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01056d0:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long long);
f01056d5:	e9 8b 00 00 00       	jmp    f0105765 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned int);
f01056da:	8b 45 14             	mov    0x14(%ebp),%eax
f01056dd:	8b 10                	mov    (%eax),%edx
f01056df:	b9 00 00 00 00       	mov    $0x0,%ecx
f01056e4:	8d 40 04             	lea    0x4(%eax),%eax
f01056e7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01056ea:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned int);
f01056ef:	eb 74                	jmp    f0105765 <vprintfmt+0x38c>
	if (lflag >= 2)
f01056f1:	83 f9 01             	cmp    $0x1,%ecx
f01056f4:	7f 1b                	jg     f0105711 <vprintfmt+0x338>
	else if (lflag)
f01056f6:	85 c9                	test   %ecx,%ecx
f01056f8:	74 2c                	je     f0105726 <vprintfmt+0x34d>
		return va_arg(*ap, unsigned long);
f01056fa:	8b 45 14             	mov    0x14(%ebp),%eax
f01056fd:	8b 10                	mov    (%eax),%edx
f01056ff:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105704:	8d 40 04             	lea    0x4(%eax),%eax
f0105707:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010570a:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long);
f010570f:	eb 54                	jmp    f0105765 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned long long);
f0105711:	8b 45 14             	mov    0x14(%ebp),%eax
f0105714:	8b 10                	mov    (%eax),%edx
f0105716:	8b 48 04             	mov    0x4(%eax),%ecx
f0105719:	8d 40 08             	lea    0x8(%eax),%eax
f010571c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010571f:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long long);
f0105724:	eb 3f                	jmp    f0105765 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned int);
f0105726:	8b 45 14             	mov    0x14(%ebp),%eax
f0105729:	8b 10                	mov    (%eax),%edx
f010572b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105730:	8d 40 04             	lea    0x4(%eax),%eax
f0105733:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0105736:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned int);
f010573b:	eb 28                	jmp    f0105765 <vprintfmt+0x38c>
			putch('0', putdat);
f010573d:	83 ec 08             	sub    $0x8,%esp
f0105740:	53                   	push   %ebx
f0105741:	6a 30                	push   $0x30
f0105743:	ff d6                	call   *%esi
			putch('x', putdat);
f0105745:	83 c4 08             	add    $0x8,%esp
f0105748:	53                   	push   %ebx
f0105749:	6a 78                	push   $0x78
f010574b:	ff d6                	call   *%esi
			num = (unsigned long long)
f010574d:	8b 45 14             	mov    0x14(%ebp),%eax
f0105750:	8b 10                	mov    (%eax),%edx
f0105752:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0105757:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f010575a:	8d 40 04             	lea    0x4(%eax),%eax
f010575d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0105760:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0105765:	83 ec 0c             	sub    $0xc,%esp
f0105768:	0f be 7d d3          	movsbl -0x2d(%ebp),%edi
f010576c:	57                   	push   %edi
f010576d:	ff 75 e0             	pushl  -0x20(%ebp)
f0105770:	50                   	push   %eax
f0105771:	51                   	push   %ecx
f0105772:	52                   	push   %edx
f0105773:	89 da                	mov    %ebx,%edx
f0105775:	89 f0                	mov    %esi,%eax
f0105777:	e8 72 fb ff ff       	call   f01052ee <printnum>
			break;
f010577c:	83 c4 20             	add    $0x20,%esp
			if ((p = va_arg(ap, char *)) == NULL)
f010577f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0105782:	83 c7 01             	add    $0x1,%edi
f0105785:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0105789:	83 f8 25             	cmp    $0x25,%eax
f010578c:	0f 84 62 fc ff ff    	je     f01053f4 <vprintfmt+0x1b>
			if (ch == '\0')
f0105792:	85 c0                	test   %eax,%eax
f0105794:	0f 84 8b 00 00 00    	je     f0105825 <vprintfmt+0x44c>
			putch(ch, putdat);
f010579a:	83 ec 08             	sub    $0x8,%esp
f010579d:	53                   	push   %ebx
f010579e:	50                   	push   %eax
f010579f:	ff d6                	call   *%esi
f01057a1:	83 c4 10             	add    $0x10,%esp
f01057a4:	eb dc                	jmp    f0105782 <vprintfmt+0x3a9>
	if (lflag >= 2)
f01057a6:	83 f9 01             	cmp    $0x1,%ecx
f01057a9:	7f 1b                	jg     f01057c6 <vprintfmt+0x3ed>
	else if (lflag)
f01057ab:	85 c9                	test   %ecx,%ecx
f01057ad:	74 2c                	je     f01057db <vprintfmt+0x402>
		return va_arg(*ap, unsigned long);
f01057af:	8b 45 14             	mov    0x14(%ebp),%eax
f01057b2:	8b 10                	mov    (%eax),%edx
f01057b4:	b9 00 00 00 00       	mov    $0x0,%ecx
f01057b9:	8d 40 04             	lea    0x4(%eax),%eax
f01057bc:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01057bf:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long);
f01057c4:	eb 9f                	jmp    f0105765 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned long long);
f01057c6:	8b 45 14             	mov    0x14(%ebp),%eax
f01057c9:	8b 10                	mov    (%eax),%edx
f01057cb:	8b 48 04             	mov    0x4(%eax),%ecx
f01057ce:	8d 40 08             	lea    0x8(%eax),%eax
f01057d1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01057d4:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long long);
f01057d9:	eb 8a                	jmp    f0105765 <vprintfmt+0x38c>
		return va_arg(*ap, unsigned int);
f01057db:	8b 45 14             	mov    0x14(%ebp),%eax
f01057de:	8b 10                	mov    (%eax),%edx
f01057e0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01057e5:	8d 40 04             	lea    0x4(%eax),%eax
f01057e8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01057eb:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned int);
f01057f0:	e9 70 ff ff ff       	jmp    f0105765 <vprintfmt+0x38c>
			putch(ch, putdat);
f01057f5:	83 ec 08             	sub    $0x8,%esp
f01057f8:	53                   	push   %ebx
f01057f9:	6a 25                	push   $0x25
f01057fb:	ff d6                	call   *%esi
			break;
f01057fd:	83 c4 10             	add    $0x10,%esp
f0105800:	e9 7a ff ff ff       	jmp    f010577f <vprintfmt+0x3a6>
			putch('%', putdat);
f0105805:	83 ec 08             	sub    $0x8,%esp
f0105808:	53                   	push   %ebx
f0105809:	6a 25                	push   $0x25
f010580b:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010580d:	83 c4 10             	add    $0x10,%esp
f0105810:	89 f8                	mov    %edi,%eax
f0105812:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0105816:	74 05                	je     f010581d <vprintfmt+0x444>
f0105818:	83 e8 01             	sub    $0x1,%eax
f010581b:	eb f5                	jmp    f0105812 <vprintfmt+0x439>
f010581d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105820:	e9 5a ff ff ff       	jmp    f010577f <vprintfmt+0x3a6>
}
f0105825:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105828:	5b                   	pop    %ebx
f0105829:	5e                   	pop    %esi
f010582a:	5f                   	pop    %edi
f010582b:	5d                   	pop    %ebp
f010582c:	c3                   	ret    

f010582d <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010582d:	f3 0f 1e fb          	endbr32 
f0105831:	55                   	push   %ebp
f0105832:	89 e5                	mov    %esp,%ebp
f0105834:	83 ec 18             	sub    $0x18,%esp
f0105837:	8b 45 08             	mov    0x8(%ebp),%eax
f010583a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010583d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105840:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105844:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0105847:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010584e:	85 c0                	test   %eax,%eax
f0105850:	74 26                	je     f0105878 <vsnprintf+0x4b>
f0105852:	85 d2                	test   %edx,%edx
f0105854:	7e 22                	jle    f0105878 <vsnprintf+0x4b>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105856:	ff 75 14             	pushl  0x14(%ebp)
f0105859:	ff 75 10             	pushl  0x10(%ebp)
f010585c:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010585f:	50                   	push   %eax
f0105860:	68 97 53 10 f0       	push   $0xf0105397
f0105865:	e8 6f fb ff ff       	call   f01053d9 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010586a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010586d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105870:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105873:	83 c4 10             	add    $0x10,%esp
}
f0105876:	c9                   	leave  
f0105877:	c3                   	ret    
		return -E_INVAL;
f0105878:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010587d:	eb f7                	jmp    f0105876 <vsnprintf+0x49>

f010587f <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010587f:	f3 0f 1e fb          	endbr32 
f0105883:	55                   	push   %ebp
f0105884:	89 e5                	mov    %esp,%ebp
f0105886:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0105889:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010588c:	50                   	push   %eax
f010588d:	ff 75 10             	pushl  0x10(%ebp)
f0105890:	ff 75 0c             	pushl  0xc(%ebp)
f0105893:	ff 75 08             	pushl  0x8(%ebp)
f0105896:	e8 92 ff ff ff       	call   f010582d <vsnprintf>
	va_end(ap);

	return rc;
}
f010589b:	c9                   	leave  
f010589c:	c3                   	ret    

f010589d <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010589d:	f3 0f 1e fb          	endbr32 
f01058a1:	55                   	push   %ebp
f01058a2:	89 e5                	mov    %esp,%ebp
f01058a4:	57                   	push   %edi
f01058a5:	56                   	push   %esi
f01058a6:	53                   	push   %ebx
f01058a7:	83 ec 0c             	sub    $0xc,%esp
f01058aa:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01058ad:	85 c0                	test   %eax,%eax
f01058af:	74 11                	je     f01058c2 <readline+0x25>
		cprintf("%s", prompt);
f01058b1:	83 ec 08             	sub    $0x8,%esp
f01058b4:	50                   	push   %eax
f01058b5:	68 55 77 10 f0       	push   $0xf0107755
f01058ba:	e8 15 e1 ff ff       	call   f01039d4 <cprintf>
f01058bf:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01058c2:	83 ec 0c             	sub    $0xc,%esp
f01058c5:	6a 00                	push   $0x0
f01058c7:	e8 e6 ae ff ff       	call   f01007b2 <iscons>
f01058cc:	89 c7                	mov    %eax,%edi
f01058ce:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01058d1:	be 00 00 00 00       	mov    $0x0,%esi
f01058d6:	eb 4b                	jmp    f0105923 <readline+0x86>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01058d8:	83 ec 08             	sub    $0x8,%esp
f01058db:	50                   	push   %eax
f01058dc:	68 64 82 10 f0       	push   $0xf0108264
f01058e1:	e8 ee e0 ff ff       	call   f01039d4 <cprintf>
			return NULL;
f01058e6:	83 c4 10             	add    $0x10,%esp
f01058e9:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01058ee:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01058f1:	5b                   	pop    %ebx
f01058f2:	5e                   	pop    %esi
f01058f3:	5f                   	pop    %edi
f01058f4:	5d                   	pop    %ebp
f01058f5:	c3                   	ret    
			if (echoing)
f01058f6:	85 ff                	test   %edi,%edi
f01058f8:	75 05                	jne    f01058ff <readline+0x62>
			i--;
f01058fa:	83 ee 01             	sub    $0x1,%esi
f01058fd:	eb 24                	jmp    f0105923 <readline+0x86>
				cputchar('\b');
f01058ff:	83 ec 0c             	sub    $0xc,%esp
f0105902:	6a 08                	push   $0x8
f0105904:	e8 80 ae ff ff       	call   f0100789 <cputchar>
f0105909:	83 c4 10             	add    $0x10,%esp
f010590c:	eb ec                	jmp    f01058fa <readline+0x5d>
				cputchar(c);
f010590e:	83 ec 0c             	sub    $0xc,%esp
f0105911:	53                   	push   %ebx
f0105912:	e8 72 ae ff ff       	call   f0100789 <cputchar>
f0105917:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010591a:	88 9e 80 9a 23 f0    	mov    %bl,-0xfdc6580(%esi)
f0105920:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f0105923:	e8 75 ae ff ff       	call   f010079d <getchar>
f0105928:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010592a:	85 c0                	test   %eax,%eax
f010592c:	78 aa                	js     f01058d8 <readline+0x3b>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010592e:	83 f8 08             	cmp    $0x8,%eax
f0105931:	0f 94 c2             	sete   %dl
f0105934:	83 f8 7f             	cmp    $0x7f,%eax
f0105937:	0f 94 c0             	sete   %al
f010593a:	08 c2                	or     %al,%dl
f010593c:	74 04                	je     f0105942 <readline+0xa5>
f010593e:	85 f6                	test   %esi,%esi
f0105940:	7f b4                	jg     f01058f6 <readline+0x59>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105942:	83 fb 1f             	cmp    $0x1f,%ebx
f0105945:	7e 0e                	jle    f0105955 <readline+0xb8>
f0105947:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010594d:	7f 06                	jg     f0105955 <readline+0xb8>
			if (echoing)
f010594f:	85 ff                	test   %edi,%edi
f0105951:	74 c7                	je     f010591a <readline+0x7d>
f0105953:	eb b9                	jmp    f010590e <readline+0x71>
		} else if (c == '\n' || c == '\r') {
f0105955:	83 fb 0a             	cmp    $0xa,%ebx
f0105958:	74 05                	je     f010595f <readline+0xc2>
f010595a:	83 fb 0d             	cmp    $0xd,%ebx
f010595d:	75 c4                	jne    f0105923 <readline+0x86>
			if (echoing)
f010595f:	85 ff                	test   %edi,%edi
f0105961:	75 11                	jne    f0105974 <readline+0xd7>
			buf[i] = 0;
f0105963:	c6 86 80 9a 23 f0 00 	movb   $0x0,-0xfdc6580(%esi)
			return buf;
f010596a:	b8 80 9a 23 f0       	mov    $0xf0239a80,%eax
f010596f:	e9 7a ff ff ff       	jmp    f01058ee <readline+0x51>
				cputchar('\n');
f0105974:	83 ec 0c             	sub    $0xc,%esp
f0105977:	6a 0a                	push   $0xa
f0105979:	e8 0b ae ff ff       	call   f0100789 <cputchar>
f010597e:	83 c4 10             	add    $0x10,%esp
f0105981:	eb e0                	jmp    f0105963 <readline+0xc6>

f0105983 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105983:	f3 0f 1e fb          	endbr32 
f0105987:	55                   	push   %ebp
f0105988:	89 e5                	mov    %esp,%ebp
f010598a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010598d:	b8 00 00 00 00       	mov    $0x0,%eax
f0105992:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105996:	74 05                	je     f010599d <strlen+0x1a>
		n++;
f0105998:	83 c0 01             	add    $0x1,%eax
f010599b:	eb f5                	jmp    f0105992 <strlen+0xf>
	return n;
}
f010599d:	5d                   	pop    %ebp
f010599e:	c3                   	ret    

f010599f <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010599f:	f3 0f 1e fb          	endbr32 
f01059a3:	55                   	push   %ebp
f01059a4:	89 e5                	mov    %esp,%ebp
f01059a6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01059a9:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01059ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01059b1:	39 d0                	cmp    %edx,%eax
f01059b3:	74 0d                	je     f01059c2 <strnlen+0x23>
f01059b5:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01059b9:	74 05                	je     f01059c0 <strnlen+0x21>
		n++;
f01059bb:	83 c0 01             	add    $0x1,%eax
f01059be:	eb f1                	jmp    f01059b1 <strnlen+0x12>
f01059c0:	89 c2                	mov    %eax,%edx
	return n;
}
f01059c2:	89 d0                	mov    %edx,%eax
f01059c4:	5d                   	pop    %ebp
f01059c5:	c3                   	ret    

f01059c6 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01059c6:	f3 0f 1e fb          	endbr32 
f01059ca:	55                   	push   %ebp
f01059cb:	89 e5                	mov    %esp,%ebp
f01059cd:	53                   	push   %ebx
f01059ce:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01059d1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01059d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01059d9:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f01059dd:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f01059e0:	83 c0 01             	add    $0x1,%eax
f01059e3:	84 d2                	test   %dl,%dl
f01059e5:	75 f2                	jne    f01059d9 <strcpy+0x13>
		/* do nothing */;
	return ret;
}
f01059e7:	89 c8                	mov    %ecx,%eax
f01059e9:	5b                   	pop    %ebx
f01059ea:	5d                   	pop    %ebp
f01059eb:	c3                   	ret    

f01059ec <strcat>:

char *
strcat(char *dst, const char *src)
{
f01059ec:	f3 0f 1e fb          	endbr32 
f01059f0:	55                   	push   %ebp
f01059f1:	89 e5                	mov    %esp,%ebp
f01059f3:	53                   	push   %ebx
f01059f4:	83 ec 10             	sub    $0x10,%esp
f01059f7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01059fa:	53                   	push   %ebx
f01059fb:	e8 83 ff ff ff       	call   f0105983 <strlen>
f0105a00:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f0105a03:	ff 75 0c             	pushl  0xc(%ebp)
f0105a06:	01 d8                	add    %ebx,%eax
f0105a08:	50                   	push   %eax
f0105a09:	e8 b8 ff ff ff       	call   f01059c6 <strcpy>
	return dst;
}
f0105a0e:	89 d8                	mov    %ebx,%eax
f0105a10:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0105a13:	c9                   	leave  
f0105a14:	c3                   	ret    

f0105a15 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105a15:	f3 0f 1e fb          	endbr32 
f0105a19:	55                   	push   %ebp
f0105a1a:	89 e5                	mov    %esp,%ebp
f0105a1c:	56                   	push   %esi
f0105a1d:	53                   	push   %ebx
f0105a1e:	8b 75 08             	mov    0x8(%ebp),%esi
f0105a21:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105a24:	89 f3                	mov    %esi,%ebx
f0105a26:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105a29:	89 f0                	mov    %esi,%eax
f0105a2b:	39 d8                	cmp    %ebx,%eax
f0105a2d:	74 11                	je     f0105a40 <strncpy+0x2b>
		*dst++ = *src;
f0105a2f:	83 c0 01             	add    $0x1,%eax
f0105a32:	0f b6 0a             	movzbl (%edx),%ecx
f0105a35:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0105a38:	80 f9 01             	cmp    $0x1,%cl
f0105a3b:	83 da ff             	sbb    $0xffffffff,%edx
f0105a3e:	eb eb                	jmp    f0105a2b <strncpy+0x16>
	}
	return ret;
}
f0105a40:	89 f0                	mov    %esi,%eax
f0105a42:	5b                   	pop    %ebx
f0105a43:	5e                   	pop    %esi
f0105a44:	5d                   	pop    %ebp
f0105a45:	c3                   	ret    

f0105a46 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0105a46:	f3 0f 1e fb          	endbr32 
f0105a4a:	55                   	push   %ebp
f0105a4b:	89 e5                	mov    %esp,%ebp
f0105a4d:	56                   	push   %esi
f0105a4e:	53                   	push   %ebx
f0105a4f:	8b 75 08             	mov    0x8(%ebp),%esi
f0105a52:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105a55:	8b 55 10             	mov    0x10(%ebp),%edx
f0105a58:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105a5a:	85 d2                	test   %edx,%edx
f0105a5c:	74 21                	je     f0105a7f <strlcpy+0x39>
f0105a5e:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0105a62:	89 f2                	mov    %esi,%edx
		while (--size > 0 && *src != '\0')
f0105a64:	39 c2                	cmp    %eax,%edx
f0105a66:	74 14                	je     f0105a7c <strlcpy+0x36>
f0105a68:	0f b6 19             	movzbl (%ecx),%ebx
f0105a6b:	84 db                	test   %bl,%bl
f0105a6d:	74 0b                	je     f0105a7a <strlcpy+0x34>
			*dst++ = *src++;
f0105a6f:	83 c1 01             	add    $0x1,%ecx
f0105a72:	83 c2 01             	add    $0x1,%edx
f0105a75:	88 5a ff             	mov    %bl,-0x1(%edx)
f0105a78:	eb ea                	jmp    f0105a64 <strlcpy+0x1e>
f0105a7a:	89 d0                	mov    %edx,%eax
		*dst = '\0';
f0105a7c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105a7f:	29 f0                	sub    %esi,%eax
}
f0105a81:	5b                   	pop    %ebx
f0105a82:	5e                   	pop    %esi
f0105a83:	5d                   	pop    %ebp
f0105a84:	c3                   	ret    

f0105a85 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105a85:	f3 0f 1e fb          	endbr32 
f0105a89:	55                   	push   %ebp
f0105a8a:	89 e5                	mov    %esp,%ebp
f0105a8c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105a8f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105a92:	0f b6 01             	movzbl (%ecx),%eax
f0105a95:	84 c0                	test   %al,%al
f0105a97:	74 0c                	je     f0105aa5 <strcmp+0x20>
f0105a99:	3a 02                	cmp    (%edx),%al
f0105a9b:	75 08                	jne    f0105aa5 <strcmp+0x20>
		p++, q++;
f0105a9d:	83 c1 01             	add    $0x1,%ecx
f0105aa0:	83 c2 01             	add    $0x1,%edx
f0105aa3:	eb ed                	jmp    f0105a92 <strcmp+0xd>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105aa5:	0f b6 c0             	movzbl %al,%eax
f0105aa8:	0f b6 12             	movzbl (%edx),%edx
f0105aab:	29 d0                	sub    %edx,%eax
}
f0105aad:	5d                   	pop    %ebp
f0105aae:	c3                   	ret    

f0105aaf <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105aaf:	f3 0f 1e fb          	endbr32 
f0105ab3:	55                   	push   %ebp
f0105ab4:	89 e5                	mov    %esp,%ebp
f0105ab6:	53                   	push   %ebx
f0105ab7:	8b 45 08             	mov    0x8(%ebp),%eax
f0105aba:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105abd:	89 c3                	mov    %eax,%ebx
f0105abf:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0105ac2:	eb 06                	jmp    f0105aca <strncmp+0x1b>
		n--, p++, q++;
f0105ac4:	83 c0 01             	add    $0x1,%eax
f0105ac7:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0105aca:	39 d8                	cmp    %ebx,%eax
f0105acc:	74 16                	je     f0105ae4 <strncmp+0x35>
f0105ace:	0f b6 08             	movzbl (%eax),%ecx
f0105ad1:	84 c9                	test   %cl,%cl
f0105ad3:	74 04                	je     f0105ad9 <strncmp+0x2a>
f0105ad5:	3a 0a                	cmp    (%edx),%cl
f0105ad7:	74 eb                	je     f0105ac4 <strncmp+0x15>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105ad9:	0f b6 00             	movzbl (%eax),%eax
f0105adc:	0f b6 12             	movzbl (%edx),%edx
f0105adf:	29 d0                	sub    %edx,%eax
}
f0105ae1:	5b                   	pop    %ebx
f0105ae2:	5d                   	pop    %ebp
f0105ae3:	c3                   	ret    
		return 0;
f0105ae4:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ae9:	eb f6                	jmp    f0105ae1 <strncmp+0x32>

f0105aeb <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105aeb:	f3 0f 1e fb          	endbr32 
f0105aef:	55                   	push   %ebp
f0105af0:	89 e5                	mov    %esp,%ebp
f0105af2:	8b 45 08             	mov    0x8(%ebp),%eax
f0105af5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105af9:	0f b6 10             	movzbl (%eax),%edx
f0105afc:	84 d2                	test   %dl,%dl
f0105afe:	74 09                	je     f0105b09 <strchr+0x1e>
		if (*s == c)
f0105b00:	38 ca                	cmp    %cl,%dl
f0105b02:	74 0a                	je     f0105b0e <strchr+0x23>
	for (; *s; s++)
f0105b04:	83 c0 01             	add    $0x1,%eax
f0105b07:	eb f0                	jmp    f0105af9 <strchr+0xe>
			return (char *) s;
	return 0;
f0105b09:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105b0e:	5d                   	pop    %ebp
f0105b0f:	c3                   	ret    

f0105b10 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105b10:	f3 0f 1e fb          	endbr32 
f0105b14:	55                   	push   %ebp
f0105b15:	89 e5                	mov    %esp,%ebp
f0105b17:	8b 45 08             	mov    0x8(%ebp),%eax
f0105b1a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105b1e:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0105b21:	38 ca                	cmp    %cl,%dl
f0105b23:	74 09                	je     f0105b2e <strfind+0x1e>
f0105b25:	84 d2                	test   %dl,%dl
f0105b27:	74 05                	je     f0105b2e <strfind+0x1e>
	for (; *s; s++)
f0105b29:	83 c0 01             	add    $0x1,%eax
f0105b2c:	eb f0                	jmp    f0105b1e <strfind+0xe>
			break;
	return (char *) s;
}
f0105b2e:	5d                   	pop    %ebp
f0105b2f:	c3                   	ret    

f0105b30 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105b30:	f3 0f 1e fb          	endbr32 
f0105b34:	55                   	push   %ebp
f0105b35:	89 e5                	mov    %esp,%ebp
f0105b37:	57                   	push   %edi
f0105b38:	56                   	push   %esi
f0105b39:	53                   	push   %ebx
f0105b3a:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105b3d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105b40:	85 c9                	test   %ecx,%ecx
f0105b42:	74 31                	je     f0105b75 <memset+0x45>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105b44:	89 f8                	mov    %edi,%eax
f0105b46:	09 c8                	or     %ecx,%eax
f0105b48:	a8 03                	test   $0x3,%al
f0105b4a:	75 23                	jne    f0105b6f <memset+0x3f>
		c &= 0xFF;
f0105b4c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105b50:	89 d3                	mov    %edx,%ebx
f0105b52:	c1 e3 08             	shl    $0x8,%ebx
f0105b55:	89 d0                	mov    %edx,%eax
f0105b57:	c1 e0 18             	shl    $0x18,%eax
f0105b5a:	89 d6                	mov    %edx,%esi
f0105b5c:	c1 e6 10             	shl    $0x10,%esi
f0105b5f:	09 f0                	or     %esi,%eax
f0105b61:	09 c2                	or     %eax,%edx
f0105b63:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0105b65:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0105b68:	89 d0                	mov    %edx,%eax
f0105b6a:	fc                   	cld    
f0105b6b:	f3 ab                	rep stos %eax,%es:(%edi)
f0105b6d:	eb 06                	jmp    f0105b75 <memset+0x45>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105b6f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105b72:	fc                   	cld    
f0105b73:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105b75:	89 f8                	mov    %edi,%eax
f0105b77:	5b                   	pop    %ebx
f0105b78:	5e                   	pop    %esi
f0105b79:	5f                   	pop    %edi
f0105b7a:	5d                   	pop    %ebp
f0105b7b:	c3                   	ret    

f0105b7c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105b7c:	f3 0f 1e fb          	endbr32 
f0105b80:	55                   	push   %ebp
f0105b81:	89 e5                	mov    %esp,%ebp
f0105b83:	57                   	push   %edi
f0105b84:	56                   	push   %esi
f0105b85:	8b 45 08             	mov    0x8(%ebp),%eax
f0105b88:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105b8b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105b8e:	39 c6                	cmp    %eax,%esi
f0105b90:	73 32                	jae    f0105bc4 <memmove+0x48>
f0105b92:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105b95:	39 c2                	cmp    %eax,%edx
f0105b97:	76 2b                	jbe    f0105bc4 <memmove+0x48>
		s += n;
		d += n;
f0105b99:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105b9c:	89 fe                	mov    %edi,%esi
f0105b9e:	09 ce                	or     %ecx,%esi
f0105ba0:	09 d6                	or     %edx,%esi
f0105ba2:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105ba8:	75 0e                	jne    f0105bb8 <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0105baa:	83 ef 04             	sub    $0x4,%edi
f0105bad:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105bb0:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0105bb3:	fd                   	std    
f0105bb4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105bb6:	eb 09                	jmp    f0105bc1 <memmove+0x45>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0105bb8:	83 ef 01             	sub    $0x1,%edi
f0105bbb:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0105bbe:	fd                   	std    
f0105bbf:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105bc1:	fc                   	cld    
f0105bc2:	eb 1a                	jmp    f0105bde <memmove+0x62>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105bc4:	89 c2                	mov    %eax,%edx
f0105bc6:	09 ca                	or     %ecx,%edx
f0105bc8:	09 f2                	or     %esi,%edx
f0105bca:	f6 c2 03             	test   $0x3,%dl
f0105bcd:	75 0a                	jne    f0105bd9 <memmove+0x5d>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105bcf:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0105bd2:	89 c7                	mov    %eax,%edi
f0105bd4:	fc                   	cld    
f0105bd5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105bd7:	eb 05                	jmp    f0105bde <memmove+0x62>
		else
			asm volatile("cld; rep movsb\n"
f0105bd9:	89 c7                	mov    %eax,%edi
f0105bdb:	fc                   	cld    
f0105bdc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105bde:	5e                   	pop    %esi
f0105bdf:	5f                   	pop    %edi
f0105be0:	5d                   	pop    %ebp
f0105be1:	c3                   	ret    

f0105be2 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105be2:	f3 0f 1e fb          	endbr32 
f0105be6:	55                   	push   %ebp
f0105be7:	89 e5                	mov    %esp,%ebp
f0105be9:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0105bec:	ff 75 10             	pushl  0x10(%ebp)
f0105bef:	ff 75 0c             	pushl  0xc(%ebp)
f0105bf2:	ff 75 08             	pushl  0x8(%ebp)
f0105bf5:	e8 82 ff ff ff       	call   f0105b7c <memmove>
}
f0105bfa:	c9                   	leave  
f0105bfb:	c3                   	ret    

f0105bfc <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105bfc:	f3 0f 1e fb          	endbr32 
f0105c00:	55                   	push   %ebp
f0105c01:	89 e5                	mov    %esp,%ebp
f0105c03:	56                   	push   %esi
f0105c04:	53                   	push   %ebx
f0105c05:	8b 45 08             	mov    0x8(%ebp),%eax
f0105c08:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105c0b:	89 c6                	mov    %eax,%esi
f0105c0d:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105c10:	39 f0                	cmp    %esi,%eax
f0105c12:	74 1c                	je     f0105c30 <memcmp+0x34>
		if (*s1 != *s2)
f0105c14:	0f b6 08             	movzbl (%eax),%ecx
f0105c17:	0f b6 1a             	movzbl (%edx),%ebx
f0105c1a:	38 d9                	cmp    %bl,%cl
f0105c1c:	75 08                	jne    f0105c26 <memcmp+0x2a>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0105c1e:	83 c0 01             	add    $0x1,%eax
f0105c21:	83 c2 01             	add    $0x1,%edx
f0105c24:	eb ea                	jmp    f0105c10 <memcmp+0x14>
			return (int) *s1 - (int) *s2;
f0105c26:	0f b6 c1             	movzbl %cl,%eax
f0105c29:	0f b6 db             	movzbl %bl,%ebx
f0105c2c:	29 d8                	sub    %ebx,%eax
f0105c2e:	eb 05                	jmp    f0105c35 <memcmp+0x39>
	}

	return 0;
f0105c30:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105c35:	5b                   	pop    %ebx
f0105c36:	5e                   	pop    %esi
f0105c37:	5d                   	pop    %ebp
f0105c38:	c3                   	ret    

f0105c39 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105c39:	f3 0f 1e fb          	endbr32 
f0105c3d:	55                   	push   %ebp
f0105c3e:	89 e5                	mov    %esp,%ebp
f0105c40:	8b 45 08             	mov    0x8(%ebp),%eax
f0105c43:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0105c46:	89 c2                	mov    %eax,%edx
f0105c48:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105c4b:	39 d0                	cmp    %edx,%eax
f0105c4d:	73 09                	jae    f0105c58 <memfind+0x1f>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105c4f:	38 08                	cmp    %cl,(%eax)
f0105c51:	74 05                	je     f0105c58 <memfind+0x1f>
	for (; s < ends; s++)
f0105c53:	83 c0 01             	add    $0x1,%eax
f0105c56:	eb f3                	jmp    f0105c4b <memfind+0x12>
			break;
	return (void *) s;
}
f0105c58:	5d                   	pop    %ebp
f0105c59:	c3                   	ret    

f0105c5a <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105c5a:	f3 0f 1e fb          	endbr32 
f0105c5e:	55                   	push   %ebp
f0105c5f:	89 e5                	mov    %esp,%ebp
f0105c61:	57                   	push   %edi
f0105c62:	56                   	push   %esi
f0105c63:	53                   	push   %ebx
f0105c64:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105c67:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105c6a:	eb 03                	jmp    f0105c6f <strtol+0x15>
		s++;
f0105c6c:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0105c6f:	0f b6 01             	movzbl (%ecx),%eax
f0105c72:	3c 20                	cmp    $0x20,%al
f0105c74:	74 f6                	je     f0105c6c <strtol+0x12>
f0105c76:	3c 09                	cmp    $0x9,%al
f0105c78:	74 f2                	je     f0105c6c <strtol+0x12>

	// plus/minus sign
	if (*s == '+')
f0105c7a:	3c 2b                	cmp    $0x2b,%al
f0105c7c:	74 2a                	je     f0105ca8 <strtol+0x4e>
	int neg = 0;
f0105c7e:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0105c83:	3c 2d                	cmp    $0x2d,%al
f0105c85:	74 2b                	je     f0105cb2 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105c87:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0105c8d:	75 0f                	jne    f0105c9e <strtol+0x44>
f0105c8f:	80 39 30             	cmpb   $0x30,(%ecx)
f0105c92:	74 28                	je     f0105cbc <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105c94:	85 db                	test   %ebx,%ebx
f0105c96:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105c9b:	0f 44 d8             	cmove  %eax,%ebx
f0105c9e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ca3:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105ca6:	eb 46                	jmp    f0105cee <strtol+0x94>
		s++;
f0105ca8:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0105cab:	bf 00 00 00 00       	mov    $0x0,%edi
f0105cb0:	eb d5                	jmp    f0105c87 <strtol+0x2d>
		s++, neg = 1;
f0105cb2:	83 c1 01             	add    $0x1,%ecx
f0105cb5:	bf 01 00 00 00       	mov    $0x1,%edi
f0105cba:	eb cb                	jmp    f0105c87 <strtol+0x2d>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105cbc:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105cc0:	74 0e                	je     f0105cd0 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0105cc2:	85 db                	test   %ebx,%ebx
f0105cc4:	75 d8                	jne    f0105c9e <strtol+0x44>
		s++, base = 8;
f0105cc6:	83 c1 01             	add    $0x1,%ecx
f0105cc9:	bb 08 00 00 00       	mov    $0x8,%ebx
f0105cce:	eb ce                	jmp    f0105c9e <strtol+0x44>
		s += 2, base = 16;
f0105cd0:	83 c1 02             	add    $0x2,%ecx
f0105cd3:	bb 10 00 00 00       	mov    $0x10,%ebx
f0105cd8:	eb c4                	jmp    f0105c9e <strtol+0x44>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f0105cda:	0f be d2             	movsbl %dl,%edx
f0105cdd:	83 ea 30             	sub    $0x30,%edx
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0105ce0:	3b 55 10             	cmp    0x10(%ebp),%edx
f0105ce3:	7d 3a                	jge    f0105d1f <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0105ce5:	83 c1 01             	add    $0x1,%ecx
f0105ce8:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105cec:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0105cee:	0f b6 11             	movzbl (%ecx),%edx
f0105cf1:	8d 72 d0             	lea    -0x30(%edx),%esi
f0105cf4:	89 f3                	mov    %esi,%ebx
f0105cf6:	80 fb 09             	cmp    $0x9,%bl
f0105cf9:	76 df                	jbe    f0105cda <strtol+0x80>
		else if (*s >= 'a' && *s <= 'z')
f0105cfb:	8d 72 9f             	lea    -0x61(%edx),%esi
f0105cfe:	89 f3                	mov    %esi,%ebx
f0105d00:	80 fb 19             	cmp    $0x19,%bl
f0105d03:	77 08                	ja     f0105d0d <strtol+0xb3>
			dig = *s - 'a' + 10;
f0105d05:	0f be d2             	movsbl %dl,%edx
f0105d08:	83 ea 57             	sub    $0x57,%edx
f0105d0b:	eb d3                	jmp    f0105ce0 <strtol+0x86>
		else if (*s >= 'A' && *s <= 'Z')
f0105d0d:	8d 72 bf             	lea    -0x41(%edx),%esi
f0105d10:	89 f3                	mov    %esi,%ebx
f0105d12:	80 fb 19             	cmp    $0x19,%bl
f0105d15:	77 08                	ja     f0105d1f <strtol+0xc5>
			dig = *s - 'A' + 10;
f0105d17:	0f be d2             	movsbl %dl,%edx
f0105d1a:	83 ea 37             	sub    $0x37,%edx
f0105d1d:	eb c1                	jmp    f0105ce0 <strtol+0x86>
		// we don't properly detect overflow!
	}

	if (endptr)
f0105d1f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105d23:	74 05                	je     f0105d2a <strtol+0xd0>
		*endptr = (char *) s;
f0105d25:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105d28:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0105d2a:	89 c2                	mov    %eax,%edx
f0105d2c:	f7 da                	neg    %edx
f0105d2e:	85 ff                	test   %edi,%edi
f0105d30:	0f 45 c2             	cmovne %edx,%eax
}
f0105d33:	5b                   	pop    %ebx
f0105d34:	5e                   	pop    %esi
f0105d35:	5f                   	pop    %edi
f0105d36:	5d                   	pop    %ebp
f0105d37:	c3                   	ret    

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
f0105d7d:	8b 25 84 9e 23 f0    	mov    0xf0239e84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105d83:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0105d88:	b8 a9 01 10 f0       	mov    $0xf01001a9,%eax
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
f0105dbe:	a1 88 9e 23 f0       	mov    0xf0239e88,%eax
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
f0105ded:	68 01 84 10 f0       	push   $0xf0108401
f0105df2:	e8 49 a2 ff ff       	call   f0100040 <_panic>
f0105df7:	57                   	push   %edi
f0105df8:	68 e4 67 10 f0       	push   $0xf01067e4
f0105dfd:	6a 57                	push   $0x57
f0105dff:	68 01 84 10 f0       	push   $0xf0108401
f0105e04:	e8 37 a2 ff ff       	call   f0100040 <_panic>
f0105e09:	83 c3 10             	add    $0x10,%ebx
f0105e0c:	39 fb                	cmp    %edi,%ebx
f0105e0e:	73 30                	jae    f0105e40 <mpsearch1+0x8d>
f0105e10:	89 de                	mov    %ebx,%esi
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105e12:	83 ec 04             	sub    $0x4,%esp
f0105e15:	6a 04                	push   $0x4
f0105e17:	68 11 84 10 f0       	push   $0xf0108411
f0105e1c:	53                   	push   %ebx
f0105e1d:	e8 da fd ff ff       	call   f0105bfc <memcmp>
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
f0105e5c:	c7 05 c0 a3 23 f0 20 	movl   $0xf023a020,0xf023a3c0
f0105e63:	a0 23 f0 
	if (PGNUM(pa) >= npages)
f0105e66:	83 3d 88 9e 23 f0 00 	cmpl   $0x0,0xf0239e88
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
f0105ecd:	3b 05 88 9e 23 f0    	cmp    0xf0239e88,%eax
f0105ed3:	0f 83 91 00 00 00    	jae    f0105f6a <mp_init+0x11b>
	return (void *)(pa + KERNBASE);
f0105ed9:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
f0105edf:	89 de                	mov    %ebx,%esi
	if (memcmp(conf, "PCMP", 4) != 0) {
f0105ee1:	83 ec 04             	sub    $0x4,%esp
f0105ee4:	6a 04                	push   $0x4
f0105ee6:	68 16 84 10 f0       	push   $0xf0108416
f0105eeb:	53                   	push   %ebx
f0105eec:	e8 0b fd ff ff       	call   f0105bfc <memcmp>
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
f0105f22:	68 01 84 10 f0       	push   $0xf0108401
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
f0105f58:	68 74 82 10 f0       	push   $0xf0108274
f0105f5d:	e8 72 da ff ff       	call   f01039d4 <cprintf>
		return NULL;
f0105f62:	83 c4 10             	add    $0x10,%esp
f0105f65:	e9 7b 01 00 00       	jmp    f01060e5 <mp_init+0x296>
f0105f6a:	53                   	push   %ebx
f0105f6b:	68 e4 67 10 f0       	push   $0xf01067e4
f0105f70:	68 90 00 00 00       	push   $0x90
f0105f75:	68 01 84 10 f0       	push   $0xf0108401
f0105f7a:	e8 c1 a0 ff ff       	call   f0100040 <_panic>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105f7f:	83 ec 0c             	sub    $0xc,%esp
f0105f82:	68 a4 82 10 f0       	push   $0xf01082a4
f0105f87:	e8 48 da ff ff       	call   f01039d4 <cprintf>
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
f0105fbd:	68 d8 82 10 f0       	push   $0xf01082d8
f0105fc2:	e8 0d da ff ff       	call   f01039d4 <cprintf>
		return NULL;
f0105fc7:	83 c4 10             	add    $0x10,%esp
f0105fca:	e9 16 01 00 00       	jmp    f01060e5 <mp_init+0x296>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105fcf:	83 ec 08             	sub    $0x8,%esp
f0105fd2:	0f b6 d2             	movzbl %dl,%edx
f0105fd5:	52                   	push   %edx
f0105fd6:	68 fc 82 10 f0       	push   $0xf01082fc
f0105fdb:	e8 f4 d9 ff ff       	call   f01039d4 <cprintf>
		return NULL;
f0105fe0:	83 c4 10             	add    $0x10,%esp
f0105fe3:	e9 fd 00 00 00       	jmp    f01060e5 <mp_init+0x296>
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105fe8:	02 46 2a             	add    0x2a(%esi),%al
f0105feb:	75 1c                	jne    f0106009 <mp_init+0x1ba>
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
f0105fed:	c7 05 00 a0 23 f0 01 	movl   $0x1,0xf023a000
f0105ff4:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105ff7:	8b 46 24             	mov    0x24(%esi),%eax
f0105ffa:	a3 00 b0 27 f0       	mov    %eax,0xf027b000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105fff:	8d 7e 2c             	lea    0x2c(%esi),%edi
f0106002:	bb 00 00 00 00       	mov    $0x0,%ebx
f0106007:	eb 4d                	jmp    f0106056 <mp_init+0x207>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0106009:	83 ec 0c             	sub    $0xc,%esp
f010600c:	68 1c 83 10 f0       	push   $0xf010831c
f0106011:	e8 be d9 ff ff       	call   f01039d4 <cprintf>
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
f0106024:	6b 05 c4 a3 23 f0 74 	imul   $0x74,0xf023a3c4,%eax
f010602b:	05 20 a0 23 f0       	add    $0xf023a020,%eax
f0106030:	a3 c0 a3 23 f0       	mov    %eax,0xf023a3c0
			if (ncpu < NCPU) {
f0106035:	a1 c4 a3 23 f0       	mov    0xf023a3c4,%eax
f010603a:	83 f8 07             	cmp    $0x7,%eax
f010603d:	7f 33                	jg     f0106072 <mp_init+0x223>
				cpus[ncpu].cpu_id = ncpu;
f010603f:	6b d0 74             	imul   $0x74,%eax,%edx
f0106042:	88 82 20 a0 23 f0    	mov    %al,-0xfdc5fe0(%edx)
				ncpu++;
f0106048:	83 c0 01             	add    $0x1,%eax
f010604b:	a3 c4 a3 23 f0       	mov    %eax,0xf023a3c4
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
f010607a:	68 4c 83 10 f0       	push   $0xf010834c
f010607f:	e8 50 d9 ff ff       	call   f01039d4 <cprintf>
f0106084:	83 c4 10             	add    $0x10,%esp
f0106087:	eb c7                	jmp    f0106050 <mp_init+0x201>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0106089:	83 ec 08             	sub    $0x8,%esp
		switch (*p) {
f010608c:	0f b6 c0             	movzbl %al,%eax
			cprintf("mpinit: unknown config type %x\n", *p);
f010608f:	50                   	push   %eax
f0106090:	68 74 83 10 f0       	push   $0xf0108374
f0106095:	e8 3a d9 ff ff       	call   f01039d4 <cprintf>
			ismp = 0;
f010609a:	c7 05 00 a0 23 f0 00 	movl   $0x0,0xf023a000
f01060a1:	00 00 00 
			i = conf->entry;
f01060a4:	0f b7 5e 22          	movzwl 0x22(%esi),%ebx
f01060a8:	83 c4 10             	add    $0x10,%esp
f01060ab:	eb a6                	jmp    f0106053 <mp_init+0x204>
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f01060ad:	a1 c0 a3 23 f0       	mov    0xf023a3c0,%eax
f01060b2:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f01060b9:	83 3d 00 a0 23 f0 00 	cmpl   $0x0,0xf023a000
f01060c0:	74 2b                	je     f01060ed <mp_init+0x29e>
		ncpu = 1;
		lapicaddr = 0;
		cprintf("SMP: configuration not found, SMP disabled\n");
		return;
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f01060c2:	83 ec 04             	sub    $0x4,%esp
f01060c5:	ff 35 c4 a3 23 f0    	pushl  0xf023a3c4
f01060cb:	0f b6 00             	movzbl (%eax),%eax
f01060ce:	50                   	push   %eax
f01060cf:	68 1b 84 10 f0       	push   $0xf010841b
f01060d4:	e8 fb d8 ff ff       	call   f01039d4 <cprintf>

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
f01060ed:	c7 05 c4 a3 23 f0 01 	movl   $0x1,0xf023a3c4
f01060f4:	00 00 00 
		lapicaddr = 0;
f01060f7:	c7 05 00 b0 27 f0 00 	movl   $0x0,0xf027b000
f01060fe:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0106101:	83 ec 0c             	sub    $0xc,%esp
f0106104:	68 94 83 10 f0       	push   $0xf0108394
f0106109:	e8 c6 d8 ff ff       	call   f01039d4 <cprintf>
		return;
f010610e:	83 c4 10             	add    $0x10,%esp
f0106111:	eb d2                	jmp    f01060e5 <mp_init+0x296>
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0106113:	83 ec 0c             	sub    $0xc,%esp
f0106116:	68 c0 83 10 f0       	push   $0xf01083c0
f010611b:	e8 b4 d8 ff ff       	call   f01039d4 <cprintf>
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
f010613a:	8b 0d 04 b0 27 f0    	mov    0xf027b004,%ecx
f0106140:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0106143:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0106145:	a1 04 b0 27 f0       	mov    0xf027b004,%eax
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
f0106152:	8b 15 04 b0 27 f0    	mov    0xf027b004,%edx
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
f010616c:	a1 00 b0 27 f0       	mov    0xf027b000,%eax
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
f0106182:	e8 2a b1 ff ff       	call   f01012b1 <mmio_map_region>
f0106187:	a3 04 b0 27 f0       	mov    %eax,0xf027b004
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
f01061d0:	05 20 a0 23 f0       	add    $0xf023a020,%eax
f01061d5:	83 c4 10             	add    $0x10,%esp
f01061d8:	39 05 c0 a3 23 f0    	cmp    %eax,0xf023a3c0
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
f01061fe:	a1 04 b0 27 f0       	mov    0xf027b004,%eax
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
f0106267:	8b 15 04 b0 27 f0    	mov    0xf027b004,%edx
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
f01062a1:	83 3d 04 b0 27 f0 00 	cmpl   $0x0,0xf027b004
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
f01062e7:	83 3d 88 9e 23 f0 00 	cmpl   $0x0,0xf0239e88
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
f010637d:	68 38 84 10 f0       	push   $0xf0108438
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
f01063a4:	8b 15 04 b0 27 f0    	mov    0xf027b004,%edx
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
f01063f9:	05 20 a0 23 f0       	add    $0xf023a020,%eax
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
f010640f:	68 48 84 10 f0       	push   $0xf0108448
f0106414:	6a 41                	push   $0x41
f0106416:	68 aa 84 10 f0       	push   $0xf01084aa
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
f0106433:	05 20 a0 23 f0       	add    $0xf023a020,%eax
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
f0106496:	e8 e1 f6 ff ff       	call   f0105b7c <memmove>
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
f01064ac:	68 74 84 10 f0       	push   $0xf0108474
f01064b1:	e8 1e d5 ff ff       	call   f01039d4 <cprintf>
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
f01064c9:	05 20 a0 23 f0       	add    $0xf023a020,%eax
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
f01064f5:	68 d1 84 10 f0       	push   $0xf01084d1
f01064fa:	e8 d5 d4 ff ff       	call   f01039d4 <cprintf>
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
f0106519:	e8 d9 ea ff ff       	call   f0104ff7 <debuginfo_eip>
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
f010653d:	68 ba 84 10 f0       	push   $0xf01084ba
f0106542:	e8 8d d4 ff ff       	call   f01039d4 <cprintf>
f0106547:	83 c4 20             	add    $0x20,%esp
f010654a:	eb b6                	jmp    f0106502 <spin_unlock+0x8e>
		panic("spin_unlock");
f010654c:	83 ec 04             	sub    $0x4,%esp
f010654f:	68 d9 84 10 f0       	push   $0xf01084d9
f0106554:	6a 67                	push   $0x67
f0106556:	68 aa 84 10 f0       	push   $0xf01084aa
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
