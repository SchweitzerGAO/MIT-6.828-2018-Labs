
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
f010004c:	83 3d 80 8e 23 f0 00 	cmpl   $0x0,0xf0238e80
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
f0100064:	89 35 80 8e 23 f0    	mov    %esi,0xf0238e80
	asm volatile("cli; cld");
f010006a:	fa                   	cli    
f010006b:	fc                   	cld    
	va_start(ap, fmt);
f010006c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010006f:	e8 f2 5b 00 00       	call   f0105c66 <cpunum>
f0100074:	ff 75 0c             	pushl  0xc(%ebp)
f0100077:	ff 75 08             	pushl  0x8(%ebp)
f010007a:	50                   	push   %eax
f010007b:	68 e0 62 10 f0       	push   $0xf01062e0
f0100080:	e8 48 39 00 00       	call   f01039cd <cprintf>
	vcprintf(fmt, ap);
f0100085:	83 c4 08             	add    $0x8,%esp
f0100088:	53                   	push   %ebx
f0100089:	56                   	push   %esi
f010008a:	e8 14 39 00 00       	call   f01039a3 <vcprintf>
	cprintf("\n");
f010008f:	c7 04 24 1d 75 10 f0 	movl   $0xf010751d,(%esp)
f0100096:	e8 32 39 00 00       	call   f01039cd <cprintf>
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
f01000b8:	68 4c 63 10 f0       	push   $0xf010634c
f01000bd:	e8 0b 39 00 00       	call   f01039cd <cprintf>
	mem_init();
f01000c2:	e8 66 12 00 00       	call   f010132d <mem_init>
	env_init();
f01000c7:	e8 ac 30 00 00       	call   f0103178 <env_init>
	trap_init();
f01000cc:	e8 f8 39 00 00       	call   f0103ac9 <trap_init>
	mp_init();
f01000d1:	e8 91 58 00 00       	call   f0105967 <mp_init>
	lapic_init();
f01000d6:	e8 a5 5b 00 00       	call   f0105c80 <lapic_init>
	pic_init();
f01000db:	e8 02 38 00 00       	call   f01038e2 <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000e0:	c7 04 24 c0 33 12 f0 	movl   $0xf01233c0,(%esp)
f01000e7:	e8 02 5e 00 00       	call   f0105eee <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000ec:	83 c4 10             	add    $0x10,%esp
f01000ef:	83 3d 88 8e 23 f0 07 	cmpl   $0x7,0xf0238e88
f01000f6:	76 27                	jbe    f010011f <i386_init+0x7f>
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f01000f8:	83 ec 04             	sub    $0x4,%esp
f01000fb:	b8 ca 58 10 f0       	mov    $0xf01058ca,%eax
f0100100:	2d 50 58 10 f0       	sub    $0xf0105850,%eax
f0100105:	50                   	push   %eax
f0100106:	68 50 58 10 f0       	push   $0xf0105850
f010010b:	68 00 70 00 f0       	push   $0xf0007000
f0100110:	e8 7e 55 00 00       	call   f0105693 <memmove>
	for (c = cpus; c < cpus + ncpu; c++) {
f0100115:	83 c4 10             	add    $0x10,%esp
f0100118:	bb 20 90 23 f0       	mov    $0xf0239020,%ebx
f010011d:	eb 53                	jmp    f0100172 <i386_init+0xd2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010011f:	68 00 70 00 00       	push   $0x7000
f0100124:	68 04 63 10 f0       	push   $0xf0106304
f0100129:	6a 4e                	push   $0x4e
f010012b:	68 67 63 10 f0       	push   $0xf0106367
f0100130:	e8 0b ff ff ff       	call   f0100040 <_panic>
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100135:	89 d8                	mov    %ebx,%eax
f0100137:	2d 20 90 23 f0       	sub    $0xf0239020,%eax
f010013c:	c1 f8 02             	sar    $0x2,%eax
f010013f:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100145:	c1 e0 0f             	shl    $0xf,%eax
f0100148:	8d 80 00 20 24 f0    	lea    -0xfdbe000(%eax),%eax
f010014e:	a3 84 8e 23 f0       	mov    %eax,0xf0238e84
		lapic_startap(c->cpu_id, PADDR(code));
f0100153:	83 ec 08             	sub    $0x8,%esp
f0100156:	68 00 70 00 00       	push   $0x7000
f010015b:	0f b6 03             	movzbl (%ebx),%eax
f010015e:	50                   	push   %eax
f010015f:	e8 76 5c 00 00       	call   f0105dda <lapic_startap>
		while(c->cpu_status != CPU_STARTED)
f0100164:	83 c4 10             	add    $0x10,%esp
f0100167:	8b 43 04             	mov    0x4(%ebx),%eax
f010016a:	83 f8 01             	cmp    $0x1,%eax
f010016d:	75 f8                	jne    f0100167 <i386_init+0xc7>
	for (c = cpus; c < cpus + ncpu; c++) {
f010016f:	83 c3 74             	add    $0x74,%ebx
f0100172:	6b 05 c4 93 23 f0 74 	imul   $0x74,0xf02393c4,%eax
f0100179:	05 20 90 23 f0       	add    $0xf0239020,%eax
f010017e:	39 c3                	cmp    %eax,%ebx
f0100180:	73 13                	jae    f0100195 <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100182:	e8 df 5a 00 00       	call   f0105c66 <cpunum>
f0100187:	6b c0 74             	imul   $0x74,%eax,%eax
f010018a:	05 20 90 23 f0       	add    $0xf0239020,%eax
f010018f:	39 c3                	cmp    %eax,%ebx
f0100191:	74 dc                	je     f010016f <i386_init+0xcf>
f0100193:	eb a0                	jmp    f0100135 <i386_init+0x95>
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100195:	83 ec 08             	sub    $0x8,%esp
f0100198:	6a 00                	push   $0x0
f010019a:	68 e8 c4 1a f0       	push   $0xf01ac4e8
f010019f:	e8 d0 31 00 00       	call   f0103374 <env_create>
	sched_yield();
f01001a4:	e8 64 43 00 00       	call   f010450d <sched_yield>

f01001a9 <mp_main>:
{
f01001a9:	f3 0f 1e fb          	endbr32 
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	83 ec 08             	sub    $0x8,%esp
	lcr3(PADDR(kern_pgdir));
f01001b3:	a1 8c 8e 23 f0       	mov    0xf0238e8c,%eax
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
f01001c7:	e8 9a 5a 00 00       	call   f0105c66 <cpunum>
f01001cc:	83 ec 08             	sub    $0x8,%esp
f01001cf:	50                   	push   %eax
f01001d0:	68 73 63 10 f0       	push   $0xf0106373
f01001d5:	e8 f3 37 00 00       	call   f01039cd <cprintf>
	lapic_init();
f01001da:	e8 a1 5a 00 00       	call   f0105c80 <lapic_init>
	env_init_percpu();
f01001df:	e8 64 2f 00 00       	call   f0103148 <env_init_percpu>
	trap_init_percpu();
f01001e4:	e8 fc 37 00 00       	call   f01039e5 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f01001e9:	e8 78 5a 00 00       	call   f0105c66 <cpunum>
f01001ee:	6b d0 74             	imul   $0x74,%eax,%edx
f01001f1:	83 c2 04             	add    $0x4,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f01001f4:	b8 01 00 00 00       	mov    $0x1,%eax
f01001f9:	f0 87 82 20 90 23 f0 	lock xchg %eax,-0xfdc6fe0(%edx)
f0100200:	c7 04 24 c0 33 12 f0 	movl   $0xf01233c0,(%esp)
f0100207:	e8 e2 5c 00 00       	call   f0105eee <spin_lock>
	sched_yield();
f010020c:	e8 fc 42 00 00       	call   f010450d <sched_yield>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100211:	50                   	push   %eax
f0100212:	68 28 63 10 f0       	push   $0xf0106328
f0100217:	6a 65                	push   $0x65
f0100219:	68 67 63 10 f0       	push   $0xf0106367
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
f0100237:	68 89 63 10 f0       	push   $0xf0106389
f010023c:	e8 8c 37 00 00       	call   f01039cd <cprintf>
	vcprintf(fmt, ap);
f0100241:	83 c4 08             	add    $0x8,%esp
f0100244:	53                   	push   %ebx
f0100245:	ff 75 10             	pushl  0x10(%ebp)
f0100248:	e8 56 37 00 00       	call   f01039a3 <vcprintf>
	cprintf("\n");
f010024d:	c7 04 24 1d 75 10 f0 	movl   $0xf010751d,(%esp)
f0100254:	e8 74 37 00 00       	call   f01039cd <cprintf>
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
f0100293:	8b 0d 24 82 23 f0    	mov    0xf0238224,%ecx
f0100299:	8d 51 01             	lea    0x1(%ecx),%edx
f010029c:	88 81 20 80 23 f0    	mov    %al,-0xfdc7fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002a2:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01002a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01002ad:	0f 44 d0             	cmove  %eax,%edx
f01002b0:	89 15 24 82 23 f0    	mov    %edx,0xf0238224
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
f01002ef:	8b 0d 00 80 23 f0    	mov    0xf0238000,%ecx
f01002f5:	f6 c1 40             	test   $0x40,%cl
f01002f8:	74 0e                	je     f0100308 <kbd_proc_data+0x4a>
		data |= 0x80;
f01002fa:	83 c8 80             	or     $0xffffff80,%eax
f01002fd:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01002ff:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100302:	89 0d 00 80 23 f0    	mov    %ecx,0xf0238000
	shift |= shiftcode[data];
f0100308:	0f b6 d2             	movzbl %dl,%edx
f010030b:	0f b6 82 00 65 10 f0 	movzbl -0xfef9b00(%edx),%eax
f0100312:	0b 05 00 80 23 f0    	or     0xf0238000,%eax
	shift ^= togglecode[data];
f0100318:	0f b6 8a 00 64 10 f0 	movzbl -0xfef9c00(%edx),%ecx
f010031f:	31 c8                	xor    %ecx,%eax
f0100321:	a3 00 80 23 f0       	mov    %eax,0xf0238000
	c = charcode[shift & (CTL | SHIFT)][data];
f0100326:	89 c1                	mov    %eax,%ecx
f0100328:	83 e1 03             	and    $0x3,%ecx
f010032b:	8b 0c 8d e0 63 10 f0 	mov    -0xfef9c20(,%ecx,4),%ecx
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
f010034c:	83 0d 00 80 23 f0 40 	orl    $0x40,0xf0238000
		return 0;
f0100353:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0100358:	89 d8                	mov    %ebx,%eax
f010035a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010035d:	c9                   	leave  
f010035e:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010035f:	8b 0d 00 80 23 f0    	mov    0xf0238000,%ecx
f0100365:	89 cb                	mov    %ecx,%ebx
f0100367:	83 e3 40             	and    $0x40,%ebx
f010036a:	83 e0 7f             	and    $0x7f,%eax
f010036d:	85 db                	test   %ebx,%ebx
f010036f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100372:	0f b6 d2             	movzbl %dl,%edx
f0100375:	0f b6 82 00 65 10 f0 	movzbl -0xfef9b00(%edx),%eax
f010037c:	83 c8 40             	or     $0x40,%eax
f010037f:	0f b6 c0             	movzbl %al,%eax
f0100382:	f7 d0                	not    %eax
f0100384:	21 c8                	and    %ecx,%eax
f0100386:	a3 00 80 23 f0       	mov    %eax,0xf0238000
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
f01003af:	68 a3 63 10 f0       	push   $0xf01063a3
f01003b4:	e8 14 36 00 00       	call   f01039cd <cprintf>
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
f01004dd:	0f b7 05 28 82 23 f0 	movzwl 0xf0238228,%eax
f01004e4:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004ea:	c1 e8 16             	shr    $0x16,%eax
f01004ed:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004f0:	c1 e0 04             	shl    $0x4,%eax
f01004f3:	66 a3 28 82 23 f0    	mov    %ax,0xf0238228
	if (crt_pos >= CRT_SIZE) {
f01004f9:	66 81 3d 28 82 23 f0 	cmpw   $0x7cf,0xf0238228
f0100500:	cf 07 
f0100502:	0f 87 8e 00 00 00    	ja     f0100596 <cons_putc+0x1bf>
	outb(addr_6845, 14);
f0100508:	8b 0d 30 82 23 f0    	mov    0xf0238230,%ecx
f010050e:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100513:	89 ca                	mov    %ecx,%edx
f0100515:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100516:	0f b7 1d 28 82 23 f0 	movzwl 0xf0238228,%ebx
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
f010053e:	0f b7 05 28 82 23 f0 	movzwl 0xf0238228,%eax
f0100545:	66 85 c0             	test   %ax,%ax
f0100548:	74 be                	je     f0100508 <cons_putc+0x131>
			crt_pos--;
f010054a:	83 e8 01             	sub    $0x1,%eax
f010054d:	66 a3 28 82 23 f0    	mov    %ax,0xf0238228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100553:	0f b7 d0             	movzwl %ax,%edx
f0100556:	b1 00                	mov    $0x0,%cl
f0100558:	83 c9 20             	or     $0x20,%ecx
f010055b:	a1 2c 82 23 f0       	mov    0xf023822c,%eax
f0100560:	66 89 0c 50          	mov    %cx,(%eax,%edx,2)
f0100564:	eb 93                	jmp    f01004f9 <cons_putc+0x122>
		crt_pos += CRT_COLS;
f0100566:	66 83 05 28 82 23 f0 	addw   $0x50,0xf0238228
f010056d:	50 
f010056e:	e9 6a ff ff ff       	jmp    f01004dd <cons_putc+0x106>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100573:	0f b7 05 28 82 23 f0 	movzwl 0xf0238228,%eax
f010057a:	8d 50 01             	lea    0x1(%eax),%edx
f010057d:	66 89 15 28 82 23 f0 	mov    %dx,0xf0238228
f0100584:	0f b7 c0             	movzwl %ax,%eax
f0100587:	8b 15 2c 82 23 f0    	mov    0xf023822c,%edx
f010058d:	66 89 0c 42          	mov    %cx,(%edx,%eax,2)
		break;
f0100591:	e9 63 ff ff ff       	jmp    f01004f9 <cons_putc+0x122>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100596:	a1 2c 82 23 f0       	mov    0xf023822c,%eax
f010059b:	83 ec 04             	sub    $0x4,%esp
f010059e:	68 00 0f 00 00       	push   $0xf00
f01005a3:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005a9:	52                   	push   %edx
f01005aa:	50                   	push   %eax
f01005ab:	e8 e3 50 00 00       	call   f0105693 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01005b0:	8b 15 2c 82 23 f0    	mov    0xf023822c,%edx
f01005b6:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01005bc:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01005c2:	83 c4 10             	add    $0x10,%esp
f01005c5:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01005ca:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005cd:	39 d0                	cmp    %edx,%eax
f01005cf:	75 f4                	jne    f01005c5 <cons_putc+0x1ee>
		crt_pos -= CRT_COLS;
f01005d1:	66 83 2d 28 82 23 f0 	subw   $0x50,0xf0238228
f01005d8:	50 
f01005d9:	e9 2a ff ff ff       	jmp    f0100508 <cons_putc+0x131>

f01005de <serial_intr>:
{
f01005de:	f3 0f 1e fb          	endbr32 
	if (serial_exists)
f01005e2:	80 3d 34 82 23 f0 00 	cmpb   $0x0,0xf0238234
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
f0100628:	a1 20 82 23 f0       	mov    0xf0238220,%eax
	return 0;
f010062d:	ba 00 00 00 00       	mov    $0x0,%edx
	if (cons.rpos != cons.wpos) {
f0100632:	3b 05 24 82 23 f0    	cmp    0xf0238224,%eax
f0100638:	74 1c                	je     f0100656 <cons_getc+0x42>
		c = cons.buf[cons.rpos++];
f010063a:	8d 48 01             	lea    0x1(%eax),%ecx
f010063d:	0f b6 90 20 80 23 f0 	movzbl -0xfdc7fe0(%eax),%edx
			cons.rpos = 0;
f0100644:	3d ff 01 00 00       	cmp    $0x1ff,%eax
f0100649:	b8 00 00 00 00       	mov    $0x0,%eax
f010064e:	0f 45 c1             	cmovne %ecx,%eax
f0100651:	a3 20 82 23 f0       	mov    %eax,0xf0238220
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
f0100688:	c7 05 30 82 23 f0 b4 	movl   $0x3b4,0xf0238230
f010068f:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100692:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
	outb(addr_6845, 14);
f0100697:	8b 3d 30 82 23 f0    	mov    0xf0238230,%edi
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
f01006be:	89 35 2c 82 23 f0    	mov    %esi,0xf023822c
	pos |= inb(addr_6845 + 1);
f01006c4:	0f b6 c0             	movzbl %al,%eax
f01006c7:	09 d8                	or     %ebx,%eax
	crt_pos = pos;
f01006c9:	66 a3 28 82 23 f0    	mov    %ax,0xf0238228
	kbd_intr();
f01006cf:	e8 2a ff ff ff       	call   f01005fe <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006d4:	83 ec 0c             	sub    $0xc,%esp
f01006d7:	0f b7 05 a8 33 12 f0 	movzwl 0xf01233a8,%eax
f01006de:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006e3:	50                   	push   %eax
f01006e4:	e8 77 31 00 00       	call   f0103860 <irq_setmask_8259A>
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
f010073f:	0f 95 05 34 82 23 f0 	setne  0xf0238234
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
f0100763:	c7 05 30 82 23 f0 d4 	movl   $0x3d4,0xf0238230
f010076a:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010076d:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f0100772:	e9 20 ff ff ff       	jmp    f0100697 <cons_init+0x3d>
		cprintf("Serial port does not exist!\n");
f0100777:	83 ec 0c             	sub    $0xc,%esp
f010077a:	68 af 63 10 f0       	push   $0xf01063af
f010077f:	e8 49 32 00 00       	call   f01039cd <cprintf>
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
f01007c6:	68 00 66 10 f0       	push   $0xf0106600
f01007cb:	68 1e 66 10 f0       	push   $0xf010661e
f01007d0:	68 23 66 10 f0       	push   $0xf0106623
f01007d5:	e8 f3 31 00 00       	call   f01039cd <cprintf>
f01007da:	83 c4 0c             	add    $0xc,%esp
f01007dd:	68 f0 66 10 f0       	push   $0xf01066f0
f01007e2:	68 2c 66 10 f0       	push   $0xf010662c
f01007e7:	68 23 66 10 f0       	push   $0xf0106623
f01007ec:	e8 dc 31 00 00       	call   f01039cd <cprintf>
f01007f1:	83 c4 0c             	add    $0xc,%esp
f01007f4:	68 35 66 10 f0       	push   $0xf0106635
f01007f9:	68 4b 66 10 f0       	push   $0xf010664b
f01007fe:	68 23 66 10 f0       	push   $0xf0106623
f0100803:	e8 c5 31 00 00       	call   f01039cd <cprintf>
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
f0100819:	68 55 66 10 f0       	push   $0xf0106655
f010081e:	e8 aa 31 00 00       	call   f01039cd <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100823:	83 c4 08             	add    $0x8,%esp
f0100826:	68 0c 00 10 00       	push   $0x10000c
f010082b:	68 18 67 10 f0       	push   $0xf0106718
f0100830:	e8 98 31 00 00       	call   f01039cd <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100835:	83 c4 0c             	add    $0xc,%esp
f0100838:	68 0c 00 10 00       	push   $0x10000c
f010083d:	68 0c 00 10 f0       	push   $0xf010000c
f0100842:	68 40 67 10 f0       	push   $0xf0106740
f0100847:	e8 81 31 00 00       	call   f01039cd <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010084c:	83 c4 0c             	add    $0xc,%esp
f010084f:	68 dd 62 10 00       	push   $0x1062dd
f0100854:	68 dd 62 10 f0       	push   $0xf01062dd
f0100859:	68 64 67 10 f0       	push   $0xf0106764
f010085e:	e8 6a 31 00 00       	call   f01039cd <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100863:	83 c4 0c             	add    $0xc,%esp
f0100866:	68 00 80 23 00       	push   $0x238000
f010086b:	68 00 80 23 f0       	push   $0xf0238000
f0100870:	68 88 67 10 f0       	push   $0xf0106788
f0100875:	e8 53 31 00 00       	call   f01039cd <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010087a:	83 c4 0c             	add    $0xc,%esp
f010087d:	68 09 a0 27 00       	push   $0x27a009
f0100882:	68 09 a0 27 f0       	push   $0xf027a009
f0100887:	68 ac 67 10 f0       	push   $0xf01067ac
f010088c:	e8 3c 31 00 00       	call   f01039cd <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100891:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100894:	b8 09 a0 27 f0       	mov    $0xf027a009,%eax
f0100899:	2d 0d fc 0f f0       	sub    $0xf00ffc0d,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f010089e:	c1 f8 0a             	sar    $0xa,%eax
f01008a1:	50                   	push   %eax
f01008a2:	68 d0 67 10 f0       	push   $0xf01067d0
f01008a7:	e8 21 31 00 00       	call   f01039cd <cprintf>
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
f01008cc:	68 6e 66 10 f0       	push   $0xf010666e
f01008d1:	e8 f7 30 00 00       	call   f01039cd <cprintf>
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
f01008f0:	68 80 66 10 f0       	push   $0xf0106680
f01008f5:	e8 d3 30 00 00       	call   f01039cd <cprintf>
f01008fa:	8d 5e 08             	lea    0x8(%esi),%ebx
f01008fd:	8d 7e 1c             	lea    0x1c(%esi),%edi
f0100900:	83 c4 10             	add    $0x10,%esp
            cprintf("%08x ", args[i]);
f0100903:	83 ec 08             	sub    $0x8,%esp
f0100906:	ff 33                	pushl  (%ebx)
f0100908:	68 9b 66 10 f0       	push   $0xf010669b
f010090d:	e8 bb 30 00 00       	call   f01039cd <cprintf>
f0100912:	83 c3 04             	add    $0x4,%ebx
        for (int i = 0; i < 5; ++i) {
f0100915:	83 c4 10             	add    $0x10,%esp
f0100918:	39 fb                	cmp    %edi,%ebx
f010091a:	75 e7                	jne    f0100903 <mon_backtrace+0x50>
        cprintf("\n");
f010091c:	83 ec 0c             	sub    $0xc,%esp
f010091f:	68 1d 75 10 f0       	push   $0xf010751d
f0100924:	e8 a4 30 00 00       	call   f01039cd <cprintf>
        if(debuginfo_eip(eip,&info) == 0)
f0100929:	83 c4 08             	add    $0x8,%esp
f010092c:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010092f:	50                   	push   %eax
f0100930:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100933:	e8 d6 41 00 00       	call   f0104b0e <debuginfo_eip>
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
f0100955:	68 a1 66 10 f0       	push   $0xf01066a1
f010095a:	e8 6e 30 00 00       	call   f01039cd <cprintf>
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
f0100981:	68 fc 67 10 f0       	push   $0xf01067fc
f0100986:	e8 42 30 00 00       	call   f01039cd <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010098b:	c7 04 24 20 68 10 f0 	movl   $0xf0106820,(%esp)
f0100992:	e8 36 30 00 00       	call   f01039cd <cprintf>

	if (tf != NULL)
f0100997:	83 c4 10             	add    $0x10,%esp
f010099a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010099e:	0f 84 d9 00 00 00    	je     f0100a7d <monitor+0x109>
		print_trapframe(tf);
f01009a4:	83 ec 0c             	sub    $0xc,%esp
f01009a7:	ff 75 08             	pushl  0x8(%ebp)
f01009aa:	e8 19 35 00 00       	call   f0103ec8 <print_trapframe>
f01009af:	83 c4 10             	add    $0x10,%esp
f01009b2:	e9 c6 00 00 00       	jmp    f0100a7d <monitor+0x109>
		while (*buf && strchr(WHITESPACE, *buf))
f01009b7:	83 ec 08             	sub    $0x8,%esp
f01009ba:	0f be c0             	movsbl %al,%eax
f01009bd:	50                   	push   %eax
f01009be:	68 b7 66 10 f0       	push   $0xf01066b7
f01009c3:	e8 3a 4c 00 00       	call   f0105602 <strchr>
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
f01009fb:	ff 34 85 60 68 10 f0 	pushl  -0xfef97a0(,%eax,4)
f0100a02:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a05:	e8 92 4b 00 00       	call   f010559c <strcmp>
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
f0100a23:	68 d9 66 10 f0       	push   $0xf01066d9
f0100a28:	e8 a0 2f 00 00       	call   f01039cd <cprintf>
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
f0100a51:	68 b7 66 10 f0       	push   $0xf01066b7
f0100a56:	e8 a7 4b 00 00       	call   f0105602 <strchr>
f0100a5b:	83 c4 10             	add    $0x10,%esp
f0100a5e:	85 c0                	test   %eax,%eax
f0100a60:	0f 85 71 ff ff ff    	jne    f01009d7 <monitor+0x63>
			buf++;
f0100a66:	83 c3 01             	add    $0x1,%ebx
f0100a69:	eb d8                	jmp    f0100a43 <monitor+0xcf>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a6b:	83 ec 08             	sub    $0x8,%esp
f0100a6e:	6a 10                	push   $0x10
f0100a70:	68 bc 66 10 f0       	push   $0xf01066bc
f0100a75:	e8 53 2f 00 00       	call   f01039cd <cprintf>
			return 0;
f0100a7a:	83 c4 10             	add    $0x10,%esp
	// cprintf("x %d, y %x, z %d\n", x, y, z);
	// unsigned int i = 0x00646c72;
 	// cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100a7d:	83 ec 0c             	sub    $0xc,%esp
f0100a80:	68 b3 66 10 f0       	push   $0xf01066b3
f0100a85:	e8 2a 49 00 00       	call   f01053b4 <readline>
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
f0100ab2:	ff 14 85 68 68 10 f0 	call   *-0xfef9798(,%eax,4)
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
f0100ad3:	e8 52 2d 00 00       	call   f010382a <mc146818_read>
f0100ad8:	89 c6                	mov    %eax,%esi
f0100ada:	83 c3 01             	add    $0x1,%ebx
f0100add:	89 1c 24             	mov    %ebx,(%esp)
f0100ae0:	e8 45 2d 00 00       	call   f010382a <mc146818_read>
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
f0100af1:	83 3d 38 82 23 f0 00 	cmpl   $0x0,0xf0238238
f0100af8:	74 36                	je     f0100b30 <boot_alloc+0x3f>
	// LAB 2: Your code here.

	// special case
	if(n == 0)
	{
		return nextfree;
f0100afa:	8b 15 38 82 23 f0    	mov    0xf0238238,%edx
	if(n == 0)
f0100b00:	85 c0                	test   %eax,%eax
f0100b02:	74 29                	je     f0100b2d <boot_alloc+0x3c>
	}

	// allocate memory 
	result = nextfree;
f0100b04:	8b 15 38 82 23 f0    	mov    0xf0238238,%edx
	nextfree = ROUNDUP(n,PGSIZE)+nextfree;
f0100b0a:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100b0f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b14:	01 d0                	add    %edx,%eax
f0100b16:	a3 38 82 23 f0       	mov    %eax,0xf0238238

	// out of memory panic
	if((uint32_t)nextfree-KERNBASE>(npages*PGSIZE))
f0100b1b:	05 00 00 00 10       	add    $0x10000000,%eax
f0100b20:	8b 0d 88 8e 23 f0    	mov    0xf0238e88,%ecx
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
f0100b30:	ba 08 b0 27 f0       	mov    $0xf027b008,%edx
f0100b35:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b3b:	89 15 38 82 23 f0    	mov    %edx,0xf0238238
f0100b41:	eb b7                	jmp    f0100afa <boot_alloc+0x9>
{
f0100b43:	55                   	push   %ebp
f0100b44:	89 e5                	mov    %esp,%ebp
f0100b46:	83 ec 0c             	sub    $0xc,%esp
		panic("at pmap.c:boot_alloc(): out of memory");
f0100b49:	68 84 68 10 f0       	push   $0xf0106884
f0100b4e:	6a 7a                	push   $0x7a
f0100b50:	68 3d 72 10 f0       	push   $0xf010723d
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
f0100b71:	3b 05 88 8e 23 f0    	cmp    0xf0238e88,%eax
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
f0100ba3:	68 04 63 10 f0       	push   $0xf0106304
f0100ba8:	68 03 04 00 00       	push   $0x403
f0100bad:	68 3d 72 10 f0       	push   $0xf010723d
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
f0100bce:	83 3d 40 82 23 f0 00 	cmpl   $0x0,0xf0238240
f0100bd5:	74 0a                	je     f0100be1 <check_page_free_list+0x24>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bd7:	be 00 04 00 00       	mov    $0x400,%esi
f0100bdc:	e9 bf 02 00 00       	jmp    f0100ea0 <check_page_free_list+0x2e3>
		panic("'page_free_list' is a null pointer!");
f0100be1:	83 ec 04             	sub    $0x4,%esp
f0100be4:	68 ac 68 10 f0       	push   $0xf01068ac
f0100be9:	68 36 03 00 00       	push   $0x336
f0100bee:	68 3d 72 10 f0       	push   $0xf010723d
f0100bf3:	e8 48 f4 ff ff       	call   f0100040 <_panic>
f0100bf8:	50                   	push   %eax
f0100bf9:	68 04 63 10 f0       	push   $0xf0106304
f0100bfe:	6a 58                	push   $0x58
f0100c00:	68 49 72 10 f0       	push   $0xf0107249
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
f0100c12:	2b 05 90 8e 23 f0    	sub    0xf0238e90,%eax
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
f0100c2c:	3b 15 88 8e 23 f0    	cmp    0xf0238e88,%edx
f0100c32:	73 c4                	jae    f0100bf8 <check_page_free_list+0x3b>
			memset(page2kva(pp), 0x97, 128);
f0100c34:	83 ec 04             	sub    $0x4,%esp
f0100c37:	68 80 00 00 00       	push   $0x80
f0100c3c:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100c41:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c46:	50                   	push   %eax
f0100c47:	e8 fb 49 00 00       	call   f0105647 <memset>
f0100c4c:	83 c4 10             	add    $0x10,%esp
f0100c4f:	eb b9                	jmp    f0100c0a <check_page_free_list+0x4d>
	first_free_page = (char *) boot_alloc(0);
f0100c51:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c56:	e8 96 fe ff ff       	call   f0100af1 <boot_alloc>
f0100c5b:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c5e:	8b 15 40 82 23 f0    	mov    0xf0238240,%edx
		assert(pp >= pages);
f0100c64:	8b 0d 90 8e 23 f0    	mov    0xf0238e90,%ecx
		assert(pp < pages + npages);
f0100c6a:	a1 88 8e 23 f0       	mov    0xf0238e88,%eax
f0100c6f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100c72:	8d 34 c1             	lea    (%ecx,%eax,8),%esi
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c75:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c7a:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c7d:	e9 f9 00 00 00       	jmp    f0100d7b <check_page_free_list+0x1be>
		assert(pp >= pages);
f0100c82:	68 57 72 10 f0       	push   $0xf0107257
f0100c87:	68 63 72 10 f0       	push   $0xf0107263
f0100c8c:	68 50 03 00 00       	push   $0x350
f0100c91:	68 3d 72 10 f0       	push   $0xf010723d
f0100c96:	e8 a5 f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100c9b:	68 78 72 10 f0       	push   $0xf0107278
f0100ca0:	68 63 72 10 f0       	push   $0xf0107263
f0100ca5:	68 51 03 00 00       	push   $0x351
f0100caa:	68 3d 72 10 f0       	push   $0xf010723d
f0100caf:	e8 8c f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cb4:	68 d0 68 10 f0       	push   $0xf01068d0
f0100cb9:	68 63 72 10 f0       	push   $0xf0107263
f0100cbe:	68 52 03 00 00       	push   $0x352
f0100cc3:	68 3d 72 10 f0       	push   $0xf010723d
f0100cc8:	e8 73 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != 0);
f0100ccd:	68 8c 72 10 f0       	push   $0xf010728c
f0100cd2:	68 63 72 10 f0       	push   $0xf0107263
f0100cd7:	68 55 03 00 00       	push   $0x355
f0100cdc:	68 3d 72 10 f0       	push   $0xf010723d
f0100ce1:	e8 5a f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ce6:	68 9d 72 10 f0       	push   $0xf010729d
f0100ceb:	68 63 72 10 f0       	push   $0xf0107263
f0100cf0:	68 56 03 00 00       	push   $0x356
f0100cf5:	68 3d 72 10 f0       	push   $0xf010723d
f0100cfa:	e8 41 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cff:	68 04 69 10 f0       	push   $0xf0106904
f0100d04:	68 63 72 10 f0       	push   $0xf0107263
f0100d09:	68 57 03 00 00       	push   $0x357
f0100d0e:	68 3d 72 10 f0       	push   $0xf010723d
f0100d13:	e8 28 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d18:	68 b6 72 10 f0       	push   $0xf01072b6
f0100d1d:	68 63 72 10 f0       	push   $0xf0107263
f0100d22:	68 58 03 00 00       	push   $0x358
f0100d27:	68 3d 72 10 f0       	push   $0xf010723d
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
f0100d4b:	68 04 63 10 f0       	push   $0xf0106304
f0100d50:	6a 58                	push   $0x58
f0100d52:	68 49 72 10 f0       	push   $0xf0107249
f0100d57:	e8 e4 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d5c:	68 28 69 10 f0       	push   $0xf0106928
f0100d61:	68 63 72 10 f0       	push   $0xf0107263
f0100d66:	68 59 03 00 00       	push   $0x359
f0100d6b:	68 3d 72 10 f0       	push   $0xf010723d
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
f0100dda:	68 d0 72 10 f0       	push   $0xf01072d0
f0100ddf:	68 63 72 10 f0       	push   $0xf0107263
f0100de4:	68 5b 03 00 00       	push   $0x35b
f0100de9:	68 3d 72 10 f0       	push   $0xf010723d
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
f0100e01:	68 70 69 10 f0       	push   $0xf0106970
f0100e06:	e8 c2 2b 00 00       	call   f01039cd <cprintf>
}
f0100e0b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e0e:	5b                   	pop    %ebx
f0100e0f:	5e                   	pop    %esi
f0100e10:	5f                   	pop    %edi
f0100e11:	5d                   	pop    %ebp
f0100e12:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e13:	68 ed 72 10 f0       	push   $0xf01072ed
f0100e18:	68 63 72 10 f0       	push   $0xf0107263
f0100e1d:	68 63 03 00 00       	push   $0x363
f0100e22:	68 3d 72 10 f0       	push   $0xf010723d
f0100e27:	e8 14 f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100e2c:	68 ff 72 10 f0       	push   $0xf01072ff
f0100e31:	68 63 72 10 f0       	push   $0xf0107263
f0100e36:	68 64 03 00 00       	push   $0x364
f0100e3b:	68 3d 72 10 f0       	push   $0xf010723d
f0100e40:	e8 fb f1 ff ff       	call   f0100040 <_panic>
	if (!page_free_list)
f0100e45:	a1 40 82 23 f0       	mov    0xf0238240,%eax
f0100e4a:	85 c0                	test   %eax,%eax
f0100e4c:	0f 84 8f fd ff ff    	je     f0100be1 <check_page_free_list+0x24>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100e52:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100e55:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e58:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e5b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100e5e:	89 c2                	mov    %eax,%edx
f0100e60:	2b 15 90 8e 23 f0    	sub    0xf0238e90,%edx
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
f0100e96:	a3 40 82 23 f0       	mov    %eax,0xf0238240
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e9b:	be 01 00 00 00       	mov    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ea0:	8b 1d 40 82 23 f0    	mov    0xf0238240,%ebx
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
f0100ec2:	8b 0d 44 82 23 f0    	mov    0xf0238244,%ecx
	size_t num_used = ((uint32_t)boot_alloc(0)-EXTPHYSMEM-KERNBASE)/PGSIZE;
f0100ec8:	05 00 00 f0 0f       	add    $0xff00000,%eax
f0100ecd:	c1 e8 0c             	shr    $0xc,%eax
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100ed0:	8d 74 01 60          	lea    0x60(%ecx,%eax,1),%esi
f0100ed4:	8b 1d 40 82 23 f0    	mov    0xf0238240,%ebx
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
f0100eee:	8b 15 90 8e 23 f0    	mov    0xf0238e90,%edx
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
f0100f13:	03 3d 90 8e 23 f0    	add    0xf0238e90,%edi
f0100f19:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
			pages[i].pp_link = page_free_list;
f0100f1f:	89 1f                	mov    %ebx,(%edi)
			page_free_list = &pages[i];
f0100f21:	89 d3                	mov    %edx,%ebx
f0100f23:	03 1d 90 8e 23 f0    	add    0xf0238e90,%ebx
f0100f29:	bf 01 00 00 00       	mov    $0x1,%edi
	for(size_t i = 0;i<npages;i++)
f0100f2e:	83 c0 01             	add    $0x1,%eax
f0100f31:	39 05 88 8e 23 f0    	cmp    %eax,0xf0238e88
f0100f37:	76 2d                	jbe    f0100f66 <page_init+0xbb>
		if(i == 0)
f0100f39:	85 c0                	test   %eax,%eax
f0100f3b:	75 a9                	jne    f0100ee6 <page_init+0x3b>
			pages[i].pp_ref = 1;
f0100f3d:	8b 15 90 8e 23 f0    	mov    0xf0238e90,%edx
f0100f43:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
			pages[i].pp_link = NULL;
f0100f49:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
f0100f4f:	eb dd                	jmp    f0100f2e <page_init+0x83>
			pages[i].pp_ref = 1;
f0100f51:	8b 15 90 8e 23 f0    	mov    0xf0238e90,%edx
f0100f57:	66 c7 42 3c 01 00    	movw   $0x1,0x3c(%edx)
			pages[i].pp_link = NULL;
f0100f5d:	c7 42 38 00 00 00 00 	movl   $0x0,0x38(%edx)
f0100f64:	eb c8                	jmp    f0100f2e <page_init+0x83>
f0100f66:	89 f8                	mov    %edi,%eax
f0100f68:	84 c0                	test   %al,%al
f0100f6a:	74 06                	je     f0100f72 <page_init+0xc7>
f0100f6c:	89 1d 40 82 23 f0    	mov    %ebx,0xf0238240
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
f0100f85:	8b 1d 40 82 23 f0    	mov    0xf0238240,%ebx
f0100f8b:	85 db                	test   %ebx,%ebx
f0100f8d:	74 30                	je     f0100fbf <page_alloc+0x45>
	page_free_list = page_free_list->pp_link;
f0100f8f:	8b 03                	mov    (%ebx),%eax
f0100f91:	a3 40 82 23 f0       	mov    %eax,0xf0238240
	alloc->pp_link = NULL;
f0100f96:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
f0100f9c:	89 d8                	mov    %ebx,%eax
f0100f9e:	2b 05 90 8e 23 f0    	sub    0xf0238e90,%eax
f0100fa4:	c1 f8 03             	sar    $0x3,%eax
f0100fa7:	89 c2                	mov    %eax,%edx
f0100fa9:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0100fac:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0100fb1:	3b 05 88 8e 23 f0    	cmp    0xf0238e88,%eax
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
f0100fc7:	68 04 63 10 f0       	push   $0xf0106304
f0100fcc:	6a 58                	push   $0x58
f0100fce:	68 49 72 10 f0       	push   $0xf0107249
f0100fd3:	e8 68 f0 ff ff       	call   f0100040 <_panic>
		memset(head,0,PGSIZE);
f0100fd8:	83 ec 04             	sub    $0x4,%esp
f0100fdb:	68 00 10 00 00       	push   $0x1000
f0100fe0:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100fe2:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0100fe8:	52                   	push   %edx
f0100fe9:	e8 59 46 00 00       	call   f0105647 <memset>
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
f010100c:	8b 15 40 82 23 f0    	mov    0xf0238240,%edx
f0101012:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101014:	a3 40 82 23 f0       	mov    %eax,0xf0238240
}
f0101019:	c9                   	leave  
f010101a:	c3                   	ret    
		panic("at pmap.c:page_free(): Page double free or freeing a referenced page");
f010101b:	83 ec 04             	sub    $0x4,%esp
f010101e:	68 94 69 10 f0       	push   $0xf0106994
f0101023:	68 ae 01 00 00       	push   $0x1ae
f0101028:	68 3d 72 10 f0       	push   $0xf010723d
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
f0101097:	2b 05 90 8e 23 f0    	sub    0xf0238e90,%eax
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
f01010b5:	3b 05 88 8e 23 f0    	cmp    0xf0238e88,%eax
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
f01010d5:	68 04 63 10 f0       	push   $0xf0106304
f01010da:	68 fb 01 00 00       	push   $0x1fb
f01010df:	68 3d 72 10 f0       	push   $0xf010723d
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
f0101168:	39 15 88 8e 23 f0    	cmp    %edx,0xf0238e88
f010116e:	76 16                	jbe    f0101186 <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f0101170:	8b 0d 90 8e 23 f0    	mov    0xf0238e90,%ecx
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
f0101189:	68 dc 69 10 f0       	push   $0xf01069dc
f010118e:	6a 51                	push   $0x51
f0101190:	68 49 72 10 f0       	push   $0xf0107249
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
f01011af:	e8 b2 4a 00 00       	call   f0105c66 <cpunum>
f01011b4:	6b c0 74             	imul   $0x74,%eax,%eax
f01011b7:	83 b8 28 90 23 f0 00 	cmpl   $0x0,-0xfdc6fd8(%eax)
f01011be:	74 16                	je     f01011d6 <tlb_invalidate+0x31>
f01011c0:	e8 a1 4a 00 00       	call   f0105c66 <cpunum>
f01011c5:	6b c0 74             	imul   $0x74,%eax,%eax
f01011c8:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
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
f0101260:	2b 1d 90 8e 23 f0    	sub    0xf0238e90,%ebx
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
f01012f3:	a1 8c 8e 23 f0       	mov    0xf0238e8c,%eax
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
f0101319:	68 fc 69 10 f0       	push   $0xf01069fc
f010131e:	68 cf 02 00 00       	push   $0x2cf
f0101323:	68 3d 72 10 f0       	push   $0xf010723d
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
f010136f:	89 15 88 8e 23 f0    	mov    %edx,0xf0238e88
	npages_basemem = basemem / (PGSIZE / 1024);
f0101375:	89 da                	mov    %ebx,%edx
f0101377:	c1 ea 02             	shr    $0x2,%edx
f010137a:	89 15 44 82 23 f0    	mov    %edx,0xf0238244
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101380:	89 c2                	mov    %eax,%edx
f0101382:	29 da                	sub    %ebx,%edx
f0101384:	52                   	push   %edx
f0101385:	53                   	push   %ebx
f0101386:	50                   	push   %eax
f0101387:	68 24 6a 10 f0       	push   $0xf0106a24
f010138c:	e8 3c 26 00 00       	call   f01039cd <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101391:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101396:	e8 56 f7 ff ff       	call   f0100af1 <boot_alloc>
f010139b:	a3 8c 8e 23 f0       	mov    %eax,0xf0238e8c
	memset(kern_pgdir, 0, PGSIZE);
f01013a0:	83 c4 0c             	add    $0xc,%esp
f01013a3:	68 00 10 00 00       	push   $0x1000
f01013a8:	6a 00                	push   $0x0
f01013aa:	50                   	push   %eax
f01013ab:	e8 97 42 00 00       	call   f0105647 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01013b0:	a1 8c 8e 23 f0       	mov    0xf0238e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01013b5:	83 c4 10             	add    $0x10,%esp
f01013b8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013bd:	0f 86 9c 00 00 00    	jbe    f010145f <mem_init+0x132>
	return (physaddr_t)kva - KERNBASE;
f01013c3:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01013c9:	83 ca 05             	or     $0x5,%edx
f01013cc:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages*sizeof(struct PageInfo));
f01013d2:	a1 88 8e 23 f0       	mov    0xf0238e88,%eax
f01013d7:	c1 e0 03             	shl    $0x3,%eax
f01013da:	e8 12 f7 ff ff       	call   f0100af1 <boot_alloc>
f01013df:	a3 90 8e 23 f0       	mov    %eax,0xf0238e90
	memset(pages,0,npages*sizeof(struct PageInfo));
f01013e4:	83 ec 04             	sub    $0x4,%esp
f01013e7:	8b 0d 88 8e 23 f0    	mov    0xf0238e88,%ecx
f01013ed:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01013f4:	52                   	push   %edx
f01013f5:	6a 00                	push   $0x0
f01013f7:	50                   	push   %eax
f01013f8:	e8 4a 42 00 00       	call   f0105647 <memset>
	envs = (struct Env*)boot_alloc(NENV*sizeof(struct Env));
f01013fd:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101402:	e8 ea f6 ff ff       	call   f0100af1 <boot_alloc>
f0101407:	a3 48 82 23 f0       	mov    %eax,0xf0238248
	memset(envs,0,NENV*sizeof(struct Env));
f010140c:	83 c4 0c             	add    $0xc,%esp
f010140f:	68 00 f0 01 00       	push   $0x1f000
f0101414:	6a 00                	push   $0x0
f0101416:	50                   	push   %eax
f0101417:	e8 2b 42 00 00       	call   f0105647 <memset>
	page_init();
f010141c:	e8 8a fa ff ff       	call   f0100eab <page_init>
	check_page_free_list(1);
f0101421:	b8 01 00 00 00       	mov    $0x1,%eax
f0101426:	e8 92 f7 ff ff       	call   f0100bbd <check_page_free_list>
	if (!pages)
f010142b:	83 c4 10             	add    $0x10,%esp
f010142e:	83 3d 90 8e 23 f0 00 	cmpl   $0x0,0xf0238e90
f0101435:	74 3d                	je     f0101474 <mem_init+0x147>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101437:	a1 40 82 23 f0       	mov    0xf0238240,%eax
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
f0101460:	68 28 63 10 f0       	push   $0xf0106328
f0101465:	68 a4 00 00 00       	push   $0xa4
f010146a:	68 3d 72 10 f0       	push   $0xf010723d
f010146f:	e8 cc eb ff ff       	call   f0100040 <_panic>
		panic("'pages' is a null pointer!");
f0101474:	83 ec 04             	sub    $0x4,%esp
f0101477:	68 10 73 10 f0       	push   $0xf0107310
f010147c:	68 77 03 00 00       	push   $0x377
f0101481:	68 3d 72 10 f0       	push   $0xf010723d
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
f01014e8:	8b 0d 90 8e 23 f0    	mov    0xf0238e90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014ee:	8b 15 88 8e 23 f0    	mov    0xf0238e88,%edx
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
f010152d:	a1 40 82 23 f0       	mov    0xf0238240,%eax
f0101532:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101535:	c7 05 40 82 23 f0 00 	movl   $0x0,0xf0238240
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
f01015e3:	2b 05 90 8e 23 f0    	sub    0xf0238e90,%eax
f01015e9:	c1 f8 03             	sar    $0x3,%eax
f01015ec:	89 c2                	mov    %eax,%edx
f01015ee:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01015f1:	25 ff ff 0f 00       	and    $0xfffff,%eax
f01015f6:	3b 05 88 8e 23 f0    	cmp    0xf0238e88,%eax
f01015fc:	0f 83 28 02 00 00    	jae    f010182a <mem_init+0x4fd>
	memset(page2kva(pp0), 1, PGSIZE);
f0101602:	83 ec 04             	sub    $0x4,%esp
f0101605:	68 00 10 00 00       	push   $0x1000
f010160a:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f010160c:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101612:	52                   	push   %edx
f0101613:	e8 2f 40 00 00       	call   f0105647 <memset>
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
f010163f:	2b 05 90 8e 23 f0    	sub    0xf0238e90,%eax
f0101645:	c1 f8 03             	sar    $0x3,%eax
f0101648:	89 c2                	mov    %eax,%edx
f010164a:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010164d:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101652:	3b 05 88 8e 23 f0    	cmp    0xf0238e88,%eax
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
f010167d:	a3 40 82 23 f0       	mov    %eax,0xf0238240
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
f010169b:	a1 40 82 23 f0       	mov    0xf0238240,%eax
f01016a0:	83 c4 10             	add    $0x10,%esp
f01016a3:	85 c0                	test   %eax,%eax
f01016a5:	0f 84 ee 01 00 00    	je     f0101899 <mem_init+0x56c>
		--nfree;
f01016ab:	83 6d d4 01          	subl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016af:	8b 00                	mov    (%eax),%eax
f01016b1:	eb f0                	jmp    f01016a3 <mem_init+0x376>
	assert((pp0 = page_alloc(0)));
f01016b3:	68 2b 73 10 f0       	push   $0xf010732b
f01016b8:	68 63 72 10 f0       	push   $0xf0107263
f01016bd:	68 7f 03 00 00       	push   $0x37f
f01016c2:	68 3d 72 10 f0       	push   $0xf010723d
f01016c7:	e8 74 e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01016cc:	68 41 73 10 f0       	push   $0xf0107341
f01016d1:	68 63 72 10 f0       	push   $0xf0107263
f01016d6:	68 80 03 00 00       	push   $0x380
f01016db:	68 3d 72 10 f0       	push   $0xf010723d
f01016e0:	e8 5b e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01016e5:	68 57 73 10 f0       	push   $0xf0107357
f01016ea:	68 63 72 10 f0       	push   $0xf0107263
f01016ef:	68 81 03 00 00       	push   $0x381
f01016f4:	68 3d 72 10 f0       	push   $0xf010723d
f01016f9:	e8 42 e9 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f01016fe:	68 6d 73 10 f0       	push   $0xf010736d
f0101703:	68 63 72 10 f0       	push   $0xf0107263
f0101708:	68 84 03 00 00       	push   $0x384
f010170d:	68 3d 72 10 f0       	push   $0xf010723d
f0101712:	e8 29 e9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101717:	68 60 6a 10 f0       	push   $0xf0106a60
f010171c:	68 63 72 10 f0       	push   $0xf0107263
f0101721:	68 85 03 00 00       	push   $0x385
f0101726:	68 3d 72 10 f0       	push   $0xf010723d
f010172b:	e8 10 e9 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101730:	68 7f 73 10 f0       	push   $0xf010737f
f0101735:	68 63 72 10 f0       	push   $0xf0107263
f010173a:	68 86 03 00 00       	push   $0x386
f010173f:	68 3d 72 10 f0       	push   $0xf010723d
f0101744:	e8 f7 e8 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101749:	68 9c 73 10 f0       	push   $0xf010739c
f010174e:	68 63 72 10 f0       	push   $0xf0107263
f0101753:	68 87 03 00 00       	push   $0x387
f0101758:	68 3d 72 10 f0       	push   $0xf010723d
f010175d:	e8 de e8 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101762:	68 b9 73 10 f0       	push   $0xf01073b9
f0101767:	68 63 72 10 f0       	push   $0xf0107263
f010176c:	68 88 03 00 00       	push   $0x388
f0101771:	68 3d 72 10 f0       	push   $0xf010723d
f0101776:	e8 c5 e8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f010177b:	68 d6 73 10 f0       	push   $0xf01073d6
f0101780:	68 63 72 10 f0       	push   $0xf0107263
f0101785:	68 8f 03 00 00       	push   $0x38f
f010178a:	68 3d 72 10 f0       	push   $0xf010723d
f010178f:	e8 ac e8 ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f0101794:	68 2b 73 10 f0       	push   $0xf010732b
f0101799:	68 63 72 10 f0       	push   $0xf0107263
f010179e:	68 96 03 00 00       	push   $0x396
f01017a3:	68 3d 72 10 f0       	push   $0xf010723d
f01017a8:	e8 93 e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01017ad:	68 41 73 10 f0       	push   $0xf0107341
f01017b2:	68 63 72 10 f0       	push   $0xf0107263
f01017b7:	68 97 03 00 00       	push   $0x397
f01017bc:	68 3d 72 10 f0       	push   $0xf010723d
f01017c1:	e8 7a e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01017c6:	68 57 73 10 f0       	push   $0xf0107357
f01017cb:	68 63 72 10 f0       	push   $0xf0107263
f01017d0:	68 98 03 00 00       	push   $0x398
f01017d5:	68 3d 72 10 f0       	push   $0xf010723d
f01017da:	e8 61 e8 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f01017df:	68 6d 73 10 f0       	push   $0xf010736d
f01017e4:	68 63 72 10 f0       	push   $0xf0107263
f01017e9:	68 9a 03 00 00       	push   $0x39a
f01017ee:	68 3d 72 10 f0       	push   $0xf010723d
f01017f3:	e8 48 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017f8:	68 60 6a 10 f0       	push   $0xf0106a60
f01017fd:	68 63 72 10 f0       	push   $0xf0107263
f0101802:	68 9b 03 00 00       	push   $0x39b
f0101807:	68 3d 72 10 f0       	push   $0xf010723d
f010180c:	e8 2f e8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101811:	68 d6 73 10 f0       	push   $0xf01073d6
f0101816:	68 63 72 10 f0       	push   $0xf0107263
f010181b:	68 9c 03 00 00       	push   $0x39c
f0101820:	68 3d 72 10 f0       	push   $0xf010723d
f0101825:	e8 16 e8 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010182a:	52                   	push   %edx
f010182b:	68 04 63 10 f0       	push   $0xf0106304
f0101830:	6a 58                	push   $0x58
f0101832:	68 49 72 10 f0       	push   $0xf0107249
f0101837:	e8 04 e8 ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010183c:	68 e5 73 10 f0       	push   $0xf01073e5
f0101841:	68 63 72 10 f0       	push   $0xf0107263
f0101846:	68 a1 03 00 00       	push   $0x3a1
f010184b:	68 3d 72 10 f0       	push   $0xf010723d
f0101850:	e8 eb e7 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101855:	68 03 74 10 f0       	push   $0xf0107403
f010185a:	68 63 72 10 f0       	push   $0xf0107263
f010185f:	68 a2 03 00 00       	push   $0x3a2
f0101864:	68 3d 72 10 f0       	push   $0xf010723d
f0101869:	e8 d2 e7 ff ff       	call   f0100040 <_panic>
f010186e:	52                   	push   %edx
f010186f:	68 04 63 10 f0       	push   $0xf0106304
f0101874:	6a 58                	push   $0x58
f0101876:	68 49 72 10 f0       	push   $0xf0107249
f010187b:	e8 c0 e7 ff ff       	call   f0100040 <_panic>
		assert(c[i] == 0);
f0101880:	68 13 74 10 f0       	push   $0xf0107413
f0101885:	68 63 72 10 f0       	push   $0xf0107263
f010188a:	68 a5 03 00 00       	push   $0x3a5
f010188f:	68 3d 72 10 f0       	push   $0xf010723d
f0101894:	e8 a7 e7 ff ff       	call   f0100040 <_panic>
	assert(nfree == 0);
f0101899:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f010189d:	0f 85 46 09 00 00    	jne    f01021e9 <mem_init+0xebc>
	cprintf("check_page_alloc() succeeded!\n");
f01018a3:	83 ec 0c             	sub    $0xc,%esp
f01018a6:	68 80 6a 10 f0       	push   $0xf0106a80
f01018ab:	e8 1d 21 00 00       	call   f01039cd <cprintf>
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
f0101912:	a1 40 82 23 f0       	mov    0xf0238240,%eax
f0101917:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f010191a:	c7 05 40 82 23 f0 00 	movl   $0x0,0xf0238240
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
f0101942:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
f0101948:	e8 ef f7 ff ff       	call   f010113c <page_lookup>
f010194d:	83 c4 10             	add    $0x10,%esp
f0101950:	85 c0                	test   %eax,%eax
f0101952:	0f 85 40 09 00 00    	jne    f0102298 <mem_init+0xf6b>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101958:	6a 02                	push   $0x2
f010195a:	6a 00                	push   $0x0
f010195c:	57                   	push   %edi
f010195d:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
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
f0101983:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
f0101989:	e8 a1 f8 ff ff       	call   f010122f <page_insert>
f010198e:	83 c4 20             	add    $0x20,%esp
f0101991:	85 c0                	test   %eax,%eax
f0101993:	0f 85 31 09 00 00    	jne    f01022ca <mem_init+0xf9d>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101999:	8b 35 8c 8e 23 f0    	mov    0xf0238e8c,%esi
	return (pp - pages) << PGSHIFT;
f010199f:	8b 0d 90 8e 23 f0    	mov    0xf0238e90,%ecx
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
f0101a1b:	a1 8c 8e 23 f0       	mov    0xf0238e8c,%eax
f0101a20:	e8 35 f1 ff ff       	call   f0100b5a <check_va2pa>
f0101a25:	89 c2                	mov    %eax,%edx
f0101a27:	89 d8                	mov    %ebx,%eax
f0101a29:	2b 05 90 8e 23 f0    	sub    0xf0238e90,%eax
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
f0101a65:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
f0101a6b:	e8 bf f7 ff ff       	call   f010122f <page_insert>
f0101a70:	83 c4 10             	add    $0x10,%esp
f0101a73:	85 c0                	test   %eax,%eax
f0101a75:	0f 85 30 09 00 00    	jne    f01023ab <mem_init+0x107e>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a7b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a80:	a1 8c 8e 23 f0       	mov    0xf0238e8c,%eax
f0101a85:	e8 d0 f0 ff ff       	call   f0100b5a <check_va2pa>
f0101a8a:	89 c2                	mov    %eax,%edx
f0101a8c:	89 d8                	mov    %ebx,%eax
f0101a8e:	2b 05 90 8e 23 f0    	sub    0xf0238e90,%eax
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
f0101ac2:	8b 0d 8c 8e 23 f0    	mov    0xf0238e8c,%ecx
f0101ac8:	8b 01                	mov    (%ecx),%eax
f0101aca:	89 c2                	mov    %eax,%edx
f0101acc:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101ad2:	c1 e8 0c             	shr    $0xc,%eax
f0101ad5:	3b 05 88 8e 23 f0    	cmp    0xf0238e88,%eax
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
f0101b15:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
f0101b1b:	e8 0f f7 ff ff       	call   f010122f <page_insert>
f0101b20:	83 c4 10             	add    $0x10,%esp
f0101b23:	85 c0                	test   %eax,%eax
f0101b25:	0f 85 12 09 00 00    	jne    f010243d <mem_init+0x1110>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b2b:	8b 35 8c 8e 23 f0    	mov    0xf0238e8c,%esi
f0101b31:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b36:	89 f0                	mov    %esi,%eax
f0101b38:	e8 1d f0 ff ff       	call   f0100b5a <check_va2pa>
f0101b3d:	89 c2                	mov    %eax,%edx
	return (pp - pages) << PGSHIFT;
f0101b3f:	89 d8                	mov    %ebx,%eax
f0101b41:	2b 05 90 8e 23 f0    	sub    0xf0238e90,%eax
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
f0101b7c:	a1 8c 8e 23 f0       	mov    0xf0238e8c,%eax
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
f0101bad:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
f0101bb3:	e8 a7 f4 ff ff       	call   f010105f <pgdir_walk>
f0101bb8:	83 c4 10             	add    $0x10,%esp
f0101bbb:	f6 00 02             	testb  $0x2,(%eax)
f0101bbe:	0f 84 0f 09 00 00    	je     f01024d3 <mem_init+0x11a6>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bc4:	83 ec 04             	sub    $0x4,%esp
f0101bc7:	6a 00                	push   $0x0
f0101bc9:	68 00 10 00 00       	push   $0x1000
f0101bce:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
f0101bd4:	e8 86 f4 ff ff       	call   f010105f <pgdir_walk>
f0101bd9:	83 c4 10             	add    $0x10,%esp
f0101bdc:	f6 00 04             	testb  $0x4,(%eax)
f0101bdf:	0f 85 07 09 00 00    	jne    f01024ec <mem_init+0x11bf>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101be5:	6a 02                	push   $0x2
f0101be7:	68 00 00 40 00       	push   $0x400000
f0101bec:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101bef:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
f0101bf5:	e8 35 f6 ff ff       	call   f010122f <page_insert>
f0101bfa:	83 c4 10             	add    $0x10,%esp
f0101bfd:	85 c0                	test   %eax,%eax
f0101bff:	0f 89 00 09 00 00    	jns    f0102505 <mem_init+0x11d8>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c05:	6a 02                	push   $0x2
f0101c07:	68 00 10 00 00       	push   $0x1000
f0101c0c:	57                   	push   %edi
f0101c0d:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
f0101c13:	e8 17 f6 ff ff       	call   f010122f <page_insert>
f0101c18:	83 c4 10             	add    $0x10,%esp
f0101c1b:	85 c0                	test   %eax,%eax
f0101c1d:	0f 85 fb 08 00 00    	jne    f010251e <mem_init+0x11f1>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c23:	83 ec 04             	sub    $0x4,%esp
f0101c26:	6a 00                	push   $0x0
f0101c28:	68 00 10 00 00       	push   $0x1000
f0101c2d:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
f0101c33:	e8 27 f4 ff ff       	call   f010105f <pgdir_walk>
f0101c38:	83 c4 10             	add    $0x10,%esp
f0101c3b:	f6 00 04             	testb  $0x4,(%eax)
f0101c3e:	0f 85 f3 08 00 00    	jne    f0102537 <mem_init+0x120a>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c44:	a1 8c 8e 23 f0       	mov    0xf0238e8c,%eax
f0101c49:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101c4c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c51:	e8 04 ef ff ff       	call   f0100b5a <check_va2pa>
f0101c56:	89 fe                	mov    %edi,%esi
f0101c58:	2b 35 90 8e 23 f0    	sub    0xf0238e90,%esi
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
f0101cb9:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
f0101cbf:	e8 1a f5 ff ff       	call   f01011de <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cc4:	8b 35 8c 8e 23 f0    	mov    0xf0238e8c,%esi
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
f0101cf2:	2b 05 90 8e 23 f0    	sub    0xf0238e90,%eax
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
f0101d51:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
f0101d57:	e8 82 f4 ff ff       	call   f01011de <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d5c:	8b 35 8c 8e 23 f0    	mov    0xf0238e8c,%esi
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
f0101dd7:	8b 0d 8c 8e 23 f0    	mov    0xf0238e8c,%ecx
f0101ddd:	8b 11                	mov    (%ecx),%edx
f0101ddf:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101de5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101de8:	2b 05 90 8e 23 f0    	sub    0xf0238e90,%eax
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
f0101e2c:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
f0101e32:	e8 28 f2 ff ff       	call   f010105f <pgdir_walk>
f0101e37:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101e3a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101e3d:	8b 0d 8c 8e 23 f0    	mov    0xf0238e8c,%ecx
f0101e43:	8b 41 04             	mov    0x4(%ecx),%eax
f0101e46:	89 c6                	mov    %eax,%esi
f0101e48:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	if (PGNUM(pa) >= npages)
f0101e4e:	8b 15 88 8e 23 f0    	mov    0xf0238e88,%edx
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
f0101e81:	2b 05 90 8e 23 f0    	sub    0xf0238e90,%eax
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
f0101eb0:	e8 92 37 00 00       	call   f0105647 <memset>
	page_free(pp0);
f0101eb5:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101eb8:	89 34 24             	mov    %esi,(%esp)
f0101ebb:	e8 33 f1 ff ff       	call   f0100ff3 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101ec0:	83 c4 0c             	add    $0xc,%esp
f0101ec3:	6a 01                	push   $0x1
f0101ec5:	6a 00                	push   $0x0
f0101ec7:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
f0101ecd:	e8 8d f1 ff ff       	call   f010105f <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0101ed2:	89 f0                	mov    %esi,%eax
f0101ed4:	2b 05 90 8e 23 f0    	sub    0xf0238e90,%eax
f0101eda:	c1 f8 03             	sar    $0x3,%eax
f0101edd:	89 c2                	mov    %eax,%edx
f0101edf:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101ee2:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101ee7:	83 c4 10             	add    $0x10,%esp
f0101eea:	3b 05 88 8e 23 f0    	cmp    0xf0238e88,%eax
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
f0101f15:	a1 8c 8e 23 f0       	mov    0xf0238e8c,%eax
f0101f1a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101f20:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f23:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0101f29:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101f2c:	89 0d 40 82 23 f0    	mov    %ecx,0xf0238240

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
f0101fc3:	8b 3d 8c 8e 23 f0    	mov    0xf0238e8c,%edi
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
f010203c:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
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
f010205d:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
f0102063:	e8 f7 ef ff ff       	call   f010105f <pgdir_walk>
f0102068:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f010206e:	83 c4 0c             	add    $0xc,%esp
f0102071:	6a 00                	push   $0x0
f0102073:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102076:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
f010207c:	e8 de ef ff ff       	call   f010105f <pgdir_walk>
f0102081:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102087:	83 c4 0c             	add    $0xc,%esp
f010208a:	6a 00                	push   $0x0
f010208c:	56                   	push   %esi
f010208d:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
f0102093:	e8 c7 ef ff ff       	call   f010105f <pgdir_walk>
f0102098:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f010209e:	c7 04 24 06 75 10 f0 	movl   $0xf0107506,(%esp)
f01020a5:	e8 23 19 00 00       	call   f01039cd <cprintf>
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U);
f01020aa:	a1 90 8e 23 f0       	mov    0xf0238e90,%eax
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
f01020d2:	a1 8c 8e 23 f0       	mov    0xf0238e8c,%eax
f01020d7:	e8 14 f0 ff ff       	call   f01010f0 <boot_map_region>
	boot_map_region(kern_pgdir,UENVS,PTSIZE,PADDR(envs),PTE_U);
f01020dc:	a1 48 82 23 f0       	mov    0xf0238248,%eax
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
f0102104:	a1 8c 8e 23 f0       	mov    0xf0238e8c,%eax
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
f0102135:	a1 8c 8e 23 f0       	mov    0xf0238e8c,%eax
f010213a:	e8 b1 ef ff ff       	call   f01010f0 <boot_map_region>
f010213f:	c7 45 d0 00 a0 23 f0 	movl   $0xf023a000,-0x30(%ebp)
f0102146:	83 c4 10             	add    $0x10,%esp
f0102149:	bb 00 a0 23 f0       	mov    $0xf023a000,%ebx
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
f0102172:	a1 8c 8e 23 f0       	mov    0xf0238e8c,%eax
f0102177:	e8 74 ef ff ff       	call   f01010f0 <boot_map_region>
f010217c:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102182:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	for(int i = 0;i<NCPU;i++)
f0102188:	83 c4 10             	add    $0x10,%esp
f010218b:	81 fb 00 a0 27 f0    	cmp    $0xf027a000,%ebx
f0102191:	75 c0                	jne    f0102153 <mem_init+0xe26>
	boot_map_region(kern_pgdir,KERNBASE,0xFFFFFFFF-KERNBASE,0,PTE_W);
f0102193:	83 ec 08             	sub    $0x8,%esp
f0102196:	6a 02                	push   $0x2
f0102198:	6a 00                	push   $0x0
f010219a:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010219f:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021a4:	a1 8c 8e 23 f0       	mov    0xf0238e8c,%eax
f01021a9:	e8 42 ef ff ff       	call   f01010f0 <boot_map_region>
	pgdir = kern_pgdir;
f01021ae:	a1 8c 8e 23 f0       	mov    0xf0238e8c,%eax
f01021b3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021b6:	a1 88 8e 23 f0       	mov    0xf0238e88,%eax
f01021bb:	89 45 c0             	mov    %eax,-0x40(%ebp)
f01021be:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021c5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021ca:	89 45 cc             	mov    %eax,-0x34(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021cd:	8b 35 90 8e 23 f0    	mov    0xf0238e90,%esi
f01021d3:	89 75 c8             	mov    %esi,-0x38(%ebp)
	return (physaddr_t)kva - KERNBASE;
f01021d6:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01021dc:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f01021df:	83 c4 10             	add    $0x10,%esp
f01021e2:	89 fb                	mov    %edi,%ebx
f01021e4:	e9 2f 07 00 00       	jmp    f0102918 <mem_init+0x15eb>
	assert(nfree == 0);
f01021e9:	68 1d 74 10 f0       	push   $0xf010741d
f01021ee:	68 63 72 10 f0       	push   $0xf0107263
f01021f3:	68 b2 03 00 00       	push   $0x3b2
f01021f8:	68 3d 72 10 f0       	push   $0xf010723d
f01021fd:	e8 3e de ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f0102202:	68 2b 73 10 f0       	push   $0xf010732b
f0102207:	68 63 72 10 f0       	push   $0xf0107263
f010220c:	68 18 04 00 00       	push   $0x418
f0102211:	68 3d 72 10 f0       	push   $0xf010723d
f0102216:	e8 25 de ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010221b:	68 41 73 10 f0       	push   $0xf0107341
f0102220:	68 63 72 10 f0       	push   $0xf0107263
f0102225:	68 19 04 00 00       	push   $0x419
f010222a:	68 3d 72 10 f0       	push   $0xf010723d
f010222f:	e8 0c de ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102234:	68 57 73 10 f0       	push   $0xf0107357
f0102239:	68 63 72 10 f0       	push   $0xf0107263
f010223e:	68 1a 04 00 00       	push   $0x41a
f0102243:	68 3d 72 10 f0       	push   $0xf010723d
f0102248:	e8 f3 dd ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f010224d:	68 6d 73 10 f0       	push   $0xf010736d
f0102252:	68 63 72 10 f0       	push   $0xf0107263
f0102257:	68 1d 04 00 00       	push   $0x41d
f010225c:	68 3d 72 10 f0       	push   $0xf010723d
f0102261:	e8 da dd ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0102266:	68 60 6a 10 f0       	push   $0xf0106a60
f010226b:	68 63 72 10 f0       	push   $0xf0107263
f0102270:	68 1e 04 00 00       	push   $0x41e
f0102275:	68 3d 72 10 f0       	push   $0xf010723d
f010227a:	e8 c1 dd ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f010227f:	68 d6 73 10 f0       	push   $0xf01073d6
f0102284:	68 63 72 10 f0       	push   $0xf0107263
f0102289:	68 25 04 00 00       	push   $0x425
f010228e:	68 3d 72 10 f0       	push   $0xf010723d
f0102293:	e8 a8 dd ff ff       	call   f0100040 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102298:	68 a0 6a 10 f0       	push   $0xf0106aa0
f010229d:	68 63 72 10 f0       	push   $0xf0107263
f01022a2:	68 28 04 00 00       	push   $0x428
f01022a7:	68 3d 72 10 f0       	push   $0xf010723d
f01022ac:	e8 8f dd ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01022b1:	68 d8 6a 10 f0       	push   $0xf0106ad8
f01022b6:	68 63 72 10 f0       	push   $0xf0107263
f01022bb:	68 2b 04 00 00       	push   $0x42b
f01022c0:	68 3d 72 10 f0       	push   $0xf010723d
f01022c5:	e8 76 dd ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01022ca:	68 08 6b 10 f0       	push   $0xf0106b08
f01022cf:	68 63 72 10 f0       	push   $0xf0107263
f01022d4:	68 2f 04 00 00       	push   $0x42f
f01022d9:	68 3d 72 10 f0       	push   $0xf010723d
f01022de:	e8 5d dd ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01022e3:	68 38 6b 10 f0       	push   $0xf0106b38
f01022e8:	68 63 72 10 f0       	push   $0xf0107263
f01022ed:	68 30 04 00 00       	push   $0x430
f01022f2:	68 3d 72 10 f0       	push   $0xf010723d
f01022f7:	e8 44 dd ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01022fc:	68 60 6b 10 f0       	push   $0xf0106b60
f0102301:	68 63 72 10 f0       	push   $0xf0107263
f0102306:	68 31 04 00 00       	push   $0x431
f010230b:	68 3d 72 10 f0       	push   $0xf010723d
f0102310:	e8 2b dd ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102315:	68 28 74 10 f0       	push   $0xf0107428
f010231a:	68 63 72 10 f0       	push   $0xf0107263
f010231f:	68 32 04 00 00       	push   $0x432
f0102324:	68 3d 72 10 f0       	push   $0xf010723d
f0102329:	e8 12 dd ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f010232e:	68 39 74 10 f0       	push   $0xf0107439
f0102333:	68 63 72 10 f0       	push   $0xf0107263
f0102338:	68 33 04 00 00       	push   $0x433
f010233d:	68 3d 72 10 f0       	push   $0xf010723d
f0102342:	e8 f9 dc ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102347:	68 90 6b 10 f0       	push   $0xf0106b90
f010234c:	68 63 72 10 f0       	push   $0xf0107263
f0102351:	68 36 04 00 00       	push   $0x436
f0102356:	68 3d 72 10 f0       	push   $0xf010723d
f010235b:	e8 e0 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102360:	68 cc 6b 10 f0       	push   $0xf0106bcc
f0102365:	68 63 72 10 f0       	push   $0xf0107263
f010236a:	68 37 04 00 00       	push   $0x437
f010236f:	68 3d 72 10 f0       	push   $0xf010723d
f0102374:	e8 c7 dc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102379:	68 4a 74 10 f0       	push   $0xf010744a
f010237e:	68 63 72 10 f0       	push   $0xf0107263
f0102383:	68 38 04 00 00       	push   $0x438
f0102388:	68 3d 72 10 f0       	push   $0xf010723d
f010238d:	e8 ae dc ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0102392:	68 d6 73 10 f0       	push   $0xf01073d6
f0102397:	68 63 72 10 f0       	push   $0xf0107263
f010239c:	68 3b 04 00 00       	push   $0x43b
f01023a1:	68 3d 72 10 f0       	push   $0xf010723d
f01023a6:	e8 95 dc ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023ab:	68 90 6b 10 f0       	push   $0xf0106b90
f01023b0:	68 63 72 10 f0       	push   $0xf0107263
f01023b5:	68 3e 04 00 00       	push   $0x43e
f01023ba:	68 3d 72 10 f0       	push   $0xf010723d
f01023bf:	e8 7c dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01023c4:	68 cc 6b 10 f0       	push   $0xf0106bcc
f01023c9:	68 63 72 10 f0       	push   $0xf0107263
f01023ce:	68 3f 04 00 00       	push   $0x43f
f01023d3:	68 3d 72 10 f0       	push   $0xf010723d
f01023d8:	e8 63 dc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01023dd:	68 4a 74 10 f0       	push   $0xf010744a
f01023e2:	68 63 72 10 f0       	push   $0xf0107263
f01023e7:	68 40 04 00 00       	push   $0x440
f01023ec:	68 3d 72 10 f0       	push   $0xf010723d
f01023f1:	e8 4a dc ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01023f6:	68 d6 73 10 f0       	push   $0xf01073d6
f01023fb:	68 63 72 10 f0       	push   $0xf0107263
f0102400:	68 44 04 00 00       	push   $0x444
f0102405:	68 3d 72 10 f0       	push   $0xf010723d
f010240a:	e8 31 dc ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010240f:	52                   	push   %edx
f0102410:	68 04 63 10 f0       	push   $0xf0106304
f0102415:	68 47 04 00 00       	push   $0x447
f010241a:	68 3d 72 10 f0       	push   $0xf010723d
f010241f:	e8 1c dc ff ff       	call   f0100040 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102424:	68 fc 6b 10 f0       	push   $0xf0106bfc
f0102429:	68 63 72 10 f0       	push   $0xf0107263
f010242e:	68 48 04 00 00       	push   $0x448
f0102433:	68 3d 72 10 f0       	push   $0xf010723d
f0102438:	e8 03 dc ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010243d:	68 3c 6c 10 f0       	push   $0xf0106c3c
f0102442:	68 63 72 10 f0       	push   $0xf0107263
f0102447:	68 4b 04 00 00       	push   $0x44b
f010244c:	68 3d 72 10 f0       	push   $0xf010723d
f0102451:	e8 ea db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102456:	68 cc 6b 10 f0       	push   $0xf0106bcc
f010245b:	68 63 72 10 f0       	push   $0xf0107263
f0102460:	68 4c 04 00 00       	push   $0x44c
f0102465:	68 3d 72 10 f0       	push   $0xf010723d
f010246a:	e8 d1 db ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f010246f:	68 4a 74 10 f0       	push   $0xf010744a
f0102474:	68 63 72 10 f0       	push   $0xf0107263
f0102479:	68 4d 04 00 00       	push   $0x44d
f010247e:	68 3d 72 10 f0       	push   $0xf010723d
f0102483:	e8 b8 db ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102488:	68 7c 6c 10 f0       	push   $0xf0106c7c
f010248d:	68 63 72 10 f0       	push   $0xf0107263
f0102492:	68 4e 04 00 00       	push   $0x44e
f0102497:	68 3d 72 10 f0       	push   $0xf010723d
f010249c:	e8 9f db ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01024a1:	68 5b 74 10 f0       	push   $0xf010745b
f01024a6:	68 63 72 10 f0       	push   $0xf0107263
f01024ab:	68 4f 04 00 00       	push   $0x44f
f01024b0:	68 3d 72 10 f0       	push   $0xf010723d
f01024b5:	e8 86 db ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01024ba:	68 90 6b 10 f0       	push   $0xf0106b90
f01024bf:	68 63 72 10 f0       	push   $0xf0107263
f01024c4:	68 52 04 00 00       	push   $0x452
f01024c9:	68 3d 72 10 f0       	push   $0xf010723d
f01024ce:	e8 6d db ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01024d3:	68 b0 6c 10 f0       	push   $0xf0106cb0
f01024d8:	68 63 72 10 f0       	push   $0xf0107263
f01024dd:	68 53 04 00 00       	push   $0x453
f01024e2:	68 3d 72 10 f0       	push   $0xf010723d
f01024e7:	e8 54 db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01024ec:	68 e4 6c 10 f0       	push   $0xf0106ce4
f01024f1:	68 63 72 10 f0       	push   $0xf0107263
f01024f6:	68 54 04 00 00       	push   $0x454
f01024fb:	68 3d 72 10 f0       	push   $0xf010723d
f0102500:	e8 3b db ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102505:	68 1c 6d 10 f0       	push   $0xf0106d1c
f010250a:	68 63 72 10 f0       	push   $0xf0107263
f010250f:	68 57 04 00 00       	push   $0x457
f0102514:	68 3d 72 10 f0       	push   $0xf010723d
f0102519:	e8 22 db ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010251e:	68 54 6d 10 f0       	push   $0xf0106d54
f0102523:	68 63 72 10 f0       	push   $0xf0107263
f0102528:	68 5a 04 00 00       	push   $0x45a
f010252d:	68 3d 72 10 f0       	push   $0xf010723d
f0102532:	e8 09 db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102537:	68 e4 6c 10 f0       	push   $0xf0106ce4
f010253c:	68 63 72 10 f0       	push   $0xf0107263
f0102541:	68 5b 04 00 00       	push   $0x45b
f0102546:	68 3d 72 10 f0       	push   $0xf010723d
f010254b:	e8 f0 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102550:	68 90 6d 10 f0       	push   $0xf0106d90
f0102555:	68 63 72 10 f0       	push   $0xf0107263
f010255a:	68 5e 04 00 00       	push   $0x45e
f010255f:	68 3d 72 10 f0       	push   $0xf010723d
f0102564:	e8 d7 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102569:	68 bc 6d 10 f0       	push   $0xf0106dbc
f010256e:	68 63 72 10 f0       	push   $0xf0107263
f0102573:	68 5f 04 00 00       	push   $0x45f
f0102578:	68 3d 72 10 f0       	push   $0xf010723d
f010257d:	e8 be da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 2);
f0102582:	68 71 74 10 f0       	push   $0xf0107471
f0102587:	68 63 72 10 f0       	push   $0xf0107263
f010258c:	68 61 04 00 00       	push   $0x461
f0102591:	68 3d 72 10 f0       	push   $0xf010723d
f0102596:	e8 a5 da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010259b:	68 82 74 10 f0       	push   $0xf0107482
f01025a0:	68 63 72 10 f0       	push   $0xf0107263
f01025a5:	68 62 04 00 00       	push   $0x462
f01025aa:	68 3d 72 10 f0       	push   $0xf010723d
f01025af:	e8 8c da ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f01025b4:	68 ec 6d 10 f0       	push   $0xf0106dec
f01025b9:	68 63 72 10 f0       	push   $0xf0107263
f01025be:	68 65 04 00 00       	push   $0x465
f01025c3:	68 3d 72 10 f0       	push   $0xf010723d
f01025c8:	e8 73 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01025cd:	68 10 6e 10 f0       	push   $0xf0106e10
f01025d2:	68 63 72 10 f0       	push   $0xf0107263
f01025d7:	68 69 04 00 00       	push   $0x469
f01025dc:	68 3d 72 10 f0       	push   $0xf010723d
f01025e1:	e8 5a da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01025e6:	68 bc 6d 10 f0       	push   $0xf0106dbc
f01025eb:	68 63 72 10 f0       	push   $0xf0107263
f01025f0:	68 6a 04 00 00       	push   $0x46a
f01025f5:	68 3d 72 10 f0       	push   $0xf010723d
f01025fa:	e8 41 da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01025ff:	68 28 74 10 f0       	push   $0xf0107428
f0102604:	68 63 72 10 f0       	push   $0xf0107263
f0102609:	68 6b 04 00 00       	push   $0x46b
f010260e:	68 3d 72 10 f0       	push   $0xf010723d
f0102613:	e8 28 da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102618:	68 82 74 10 f0       	push   $0xf0107482
f010261d:	68 63 72 10 f0       	push   $0xf0107263
f0102622:	68 6c 04 00 00       	push   $0x46c
f0102627:	68 3d 72 10 f0       	push   $0xf010723d
f010262c:	e8 0f da ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102631:	68 34 6e 10 f0       	push   $0xf0106e34
f0102636:	68 63 72 10 f0       	push   $0xf0107263
f010263b:	68 6f 04 00 00       	push   $0x46f
f0102640:	68 3d 72 10 f0       	push   $0xf010723d
f0102645:	e8 f6 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f010264a:	68 93 74 10 f0       	push   $0xf0107493
f010264f:	68 63 72 10 f0       	push   $0xf0107263
f0102654:	68 70 04 00 00       	push   $0x470
f0102659:	68 3d 72 10 f0       	push   $0xf010723d
f010265e:	e8 dd d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0102663:	68 9f 74 10 f0       	push   $0xf010749f
f0102668:	68 63 72 10 f0       	push   $0xf0107263
f010266d:	68 71 04 00 00       	push   $0x471
f0102672:	68 3d 72 10 f0       	push   $0xf010723d
f0102677:	e8 c4 d9 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010267c:	68 10 6e 10 f0       	push   $0xf0106e10
f0102681:	68 63 72 10 f0       	push   $0xf0107263
f0102686:	68 75 04 00 00       	push   $0x475
f010268b:	68 3d 72 10 f0       	push   $0xf010723d
f0102690:	e8 ab d9 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102695:	68 6c 6e 10 f0       	push   $0xf0106e6c
f010269a:	68 63 72 10 f0       	push   $0xf0107263
f010269f:	68 76 04 00 00       	push   $0x476
f01026a4:	68 3d 72 10 f0       	push   $0xf010723d
f01026a9:	e8 92 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01026ae:	68 b4 74 10 f0       	push   $0xf01074b4
f01026b3:	68 63 72 10 f0       	push   $0xf0107263
f01026b8:	68 77 04 00 00       	push   $0x477
f01026bd:	68 3d 72 10 f0       	push   $0xf010723d
f01026c2:	e8 79 d9 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01026c7:	68 82 74 10 f0       	push   $0xf0107482
f01026cc:	68 63 72 10 f0       	push   $0xf0107263
f01026d1:	68 78 04 00 00       	push   $0x478
f01026d6:	68 3d 72 10 f0       	push   $0xf010723d
f01026db:	e8 60 d9 ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f01026e0:	68 94 6e 10 f0       	push   $0xf0106e94
f01026e5:	68 63 72 10 f0       	push   $0xf0107263
f01026ea:	68 7b 04 00 00       	push   $0x47b
f01026ef:	68 3d 72 10 f0       	push   $0xf010723d
f01026f4:	e8 47 d9 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01026f9:	68 d6 73 10 f0       	push   $0xf01073d6
f01026fe:	68 63 72 10 f0       	push   $0xf0107263
f0102703:	68 7e 04 00 00       	push   $0x47e
f0102708:	68 3d 72 10 f0       	push   $0xf010723d
f010270d:	e8 2e d9 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102712:	68 38 6b 10 f0       	push   $0xf0106b38
f0102717:	68 63 72 10 f0       	push   $0xf0107263
f010271c:	68 81 04 00 00       	push   $0x481
f0102721:	68 3d 72 10 f0       	push   $0xf010723d
f0102726:	e8 15 d9 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f010272b:	68 39 74 10 f0       	push   $0xf0107439
f0102730:	68 63 72 10 f0       	push   $0xf0107263
f0102735:	68 83 04 00 00       	push   $0x483
f010273a:	68 3d 72 10 f0       	push   $0xf010723d
f010273f:	e8 fc d8 ff ff       	call   f0100040 <_panic>
f0102744:	56                   	push   %esi
f0102745:	68 04 63 10 f0       	push   $0xf0106304
f010274a:	68 8a 04 00 00       	push   $0x48a
f010274f:	68 3d 72 10 f0       	push   $0xf010723d
f0102754:	e8 e7 d8 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102759:	68 c5 74 10 f0       	push   $0xf01074c5
f010275e:	68 63 72 10 f0       	push   $0xf0107263
f0102763:	68 8b 04 00 00       	push   $0x48b
f0102768:	68 3d 72 10 f0       	push   $0xf010723d
f010276d:	e8 ce d8 ff ff       	call   f0100040 <_panic>
f0102772:	51                   	push   %ecx
f0102773:	68 04 63 10 f0       	push   $0xf0106304
f0102778:	6a 58                	push   $0x58
f010277a:	68 49 72 10 f0       	push   $0xf0107249
f010277f:	e8 bc d8 ff ff       	call   f0100040 <_panic>
f0102784:	52                   	push   %edx
f0102785:	68 04 63 10 f0       	push   $0xf0106304
f010278a:	6a 58                	push   $0x58
f010278c:	68 49 72 10 f0       	push   $0xf0107249
f0102791:	e8 aa d8 ff ff       	call   f0100040 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102796:	68 dd 74 10 f0       	push   $0xf01074dd
f010279b:	68 63 72 10 f0       	push   $0xf0107263
f01027a0:	68 95 04 00 00       	push   $0x495
f01027a5:	68 3d 72 10 f0       	push   $0xf010723d
f01027aa:	e8 91 d8 ff ff       	call   f0100040 <_panic>
	assert(mm1 >= MMIOBASE && mm1 + 8192 < MMIOLIM);
f01027af:	68 b8 6e 10 f0       	push   $0xf0106eb8
f01027b4:	68 63 72 10 f0       	push   $0xf0107263
f01027b9:	68 a5 04 00 00       	push   $0x4a5
f01027be:	68 3d 72 10 f0       	push   $0xf010723d
f01027c3:	e8 78 d8 ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8192 < MMIOLIM);
f01027c8:	68 e0 6e 10 f0       	push   $0xf0106ee0
f01027cd:	68 63 72 10 f0       	push   $0xf0107263
f01027d2:	68 a6 04 00 00       	push   $0x4a6
f01027d7:	68 3d 72 10 f0       	push   $0xf010723d
f01027dc:	e8 5f d8 ff ff       	call   f0100040 <_panic>
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f01027e1:	68 08 6f 10 f0       	push   $0xf0106f08
f01027e6:	68 63 72 10 f0       	push   $0xf0107263
f01027eb:	68 a8 04 00 00       	push   $0x4a8
f01027f0:	68 3d 72 10 f0       	push   $0xf010723d
f01027f5:	e8 46 d8 ff ff       	call   f0100040 <_panic>
	assert(mm1 + 8192 <= mm2);
f01027fa:	68 f4 74 10 f0       	push   $0xf01074f4
f01027ff:	68 63 72 10 f0       	push   $0xf0107263
f0102804:	68 aa 04 00 00       	push   $0x4aa
f0102809:	68 3d 72 10 f0       	push   $0xf010723d
f010280e:	e8 2d d8 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102813:	68 30 6f 10 f0       	push   $0xf0106f30
f0102818:	68 63 72 10 f0       	push   $0xf0107263
f010281d:	68 ac 04 00 00       	push   $0x4ac
f0102822:	68 3d 72 10 f0       	push   $0xf010723d
f0102827:	e8 14 d8 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f010282c:	68 54 6f 10 f0       	push   $0xf0106f54
f0102831:	68 63 72 10 f0       	push   $0xf0107263
f0102836:	68 ad 04 00 00       	push   $0x4ad
f010283b:	68 3d 72 10 f0       	push   $0xf010723d
f0102840:	e8 fb d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102845:	68 84 6f 10 f0       	push   $0xf0106f84
f010284a:	68 63 72 10 f0       	push   $0xf0107263
f010284f:	68 ae 04 00 00       	push   $0x4ae
f0102854:	68 3d 72 10 f0       	push   $0xf010723d
f0102859:	e8 e2 d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f010285e:	68 a8 6f 10 f0       	push   $0xf0106fa8
f0102863:	68 63 72 10 f0       	push   $0xf0107263
f0102868:	68 af 04 00 00       	push   $0x4af
f010286d:	68 3d 72 10 f0       	push   $0xf010723d
f0102872:	e8 c9 d7 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102877:	68 d4 6f 10 f0       	push   $0xf0106fd4
f010287c:	68 63 72 10 f0       	push   $0xf0107263
f0102881:	68 b1 04 00 00       	push   $0x4b1
f0102886:	68 3d 72 10 f0       	push   $0xf010723d
f010288b:	e8 b0 d7 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102890:	68 18 70 10 f0       	push   $0xf0107018
f0102895:	68 63 72 10 f0       	push   $0xf0107263
f010289a:	68 b2 04 00 00       	push   $0x4b2
f010289f:	68 3d 72 10 f0       	push   $0xf010723d
f01028a4:	e8 97 d7 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028a9:	50                   	push   %eax
f01028aa:	68 28 63 10 f0       	push   $0xf0106328
f01028af:	68 cb 00 00 00       	push   $0xcb
f01028b4:	68 3d 72 10 f0       	push   $0xf010723d
f01028b9:	e8 82 d7 ff ff       	call   f0100040 <_panic>
f01028be:	50                   	push   %eax
f01028bf:	68 28 63 10 f0       	push   $0xf0106328
f01028c4:	68 d3 00 00 00       	push   $0xd3
f01028c9:	68 3d 72 10 f0       	push   $0xf010723d
f01028ce:	e8 6d d7 ff ff       	call   f0100040 <_panic>
f01028d3:	50                   	push   %eax
f01028d4:	68 28 63 10 f0       	push   $0xf0106328
f01028d9:	68 df 00 00 00       	push   $0xdf
f01028de:	68 3d 72 10 f0       	push   $0xf010723d
f01028e3:	e8 58 d7 ff ff       	call   f0100040 <_panic>
f01028e8:	53                   	push   %ebx
f01028e9:	68 28 63 10 f0       	push   $0xf0106328
f01028ee:	68 1f 01 00 00       	push   $0x11f
f01028f3:	68 3d 72 10 f0       	push   $0xf010723d
f01028f8:	e8 43 d7 ff ff       	call   f0100040 <_panic>
f01028fd:	56                   	push   %esi
f01028fe:	68 28 63 10 f0       	push   $0xf0106328
f0102903:	68 ca 03 00 00       	push   $0x3ca
f0102908:	68 3d 72 10 f0       	push   $0xf010723d
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
f010293e:	68 4c 70 10 f0       	push   $0xf010704c
f0102943:	68 63 72 10 f0       	push   $0xf0107263
f0102948:	68 ca 03 00 00       	push   $0x3ca
f010294d:	68 3d 72 10 f0       	push   $0xf010723d
f0102952:	e8 e9 d6 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102957:	a1 48 82 23 f0       	mov    0xf0238248,%eax
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
f01029be:	68 28 63 10 f0       	push   $0xf0106328
f01029c3:	68 cf 03 00 00       	push   $0x3cf
f01029c8:	68 3d 72 10 f0       	push   $0xf010723d
f01029cd:	e8 6e d6 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01029d2:	68 80 70 10 f0       	push   $0xf0107080
f01029d7:	68 63 72 10 f0       	push   $0xf0107263
f01029dc:	68 cf 03 00 00       	push   $0x3cf
f01029e1:	68 3d 72 10 f0       	push   $0xf010723d
f01029e6:	e8 55 d6 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01029eb:	68 b4 70 10 f0       	push   $0xf01070b4
f01029f0:	68 63 72 10 f0       	push   $0xf0107263
f01029f5:	68 d3 03 00 00       	push   $0x3d3
f01029fa:	68 3d 72 10 f0       	push   $0xf010723d
f01029ff:	e8 3c d6 ff ff       	call   f0100040 <_panic>
f0102a04:	c7 45 cc 00 a0 24 00 	movl   $0x24a000,-0x34(%ebp)
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
f0102a8d:	3d 00 a0 27 f0       	cmp    $0xf027a000,%eax
f0102a92:	0f 85 7b ff ff ff    	jne    f0102a13 <mem_init+0x16e6>
f0102a98:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0102a9b:	e9 84 00 00 00       	jmp    f0102b24 <mem_init+0x17f7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102aa0:	ff 75 bc             	pushl  -0x44(%ebp)
f0102aa3:	68 28 63 10 f0       	push   $0xf0106328
f0102aa8:	68 db 03 00 00       	push   $0x3db
f0102aad:	68 3d 72 10 f0       	push   $0xf010723d
f0102ab2:	e8 89 d5 ff ff       	call   f0100040 <_panic>
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102ab7:	68 dc 70 10 f0       	push   $0xf01070dc
f0102abc:	68 63 72 10 f0       	push   $0xf0107263
f0102ac1:	68 da 03 00 00       	push   $0x3da
f0102ac6:	68 3d 72 10 f0       	push   $0xf010723d
f0102acb:	e8 70 d5 ff ff       	call   f0100040 <_panic>
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102ad0:	68 24 71 10 f0       	push   $0xf0107124
f0102ad5:	68 63 72 10 f0       	push   $0xf0107263
f0102ada:	68 dd 03 00 00       	push   $0x3dd
f0102adf:	68 3d 72 10 f0       	push   $0xf010723d
f0102ae4:	e8 57 d5 ff ff       	call   f0100040 <_panic>
			assert(pgdir[i] & PTE_P);
f0102ae9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102aec:	f6 04 b8 01          	testb  $0x1,(%eax,%edi,4)
f0102af0:	75 4e                	jne    f0102b40 <mem_init+0x1813>
f0102af2:	68 1f 75 10 f0       	push   $0xf010751f
f0102af7:	68 63 72 10 f0       	push   $0xf0107263
f0102afc:	68 e8 03 00 00       	push   $0x3e8
f0102b01:	68 3d 72 10 f0       	push   $0xf010723d
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
f0102b45:	68 1f 75 10 f0       	push   $0xf010751f
f0102b4a:	68 63 72 10 f0       	push   $0xf0107263
f0102b4f:	68 ec 03 00 00       	push   $0x3ec
f0102b54:	68 3d 72 10 f0       	push   $0xf010723d
f0102b59:	e8 e2 d4 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102b5e:	68 30 75 10 f0       	push   $0xf0107530
f0102b63:	68 63 72 10 f0       	push   $0xf0107263
f0102b68:	68 ed 03 00 00       	push   $0x3ed
f0102b6d:	68 3d 72 10 f0       	push   $0xf010723d
f0102b72:	e8 c9 d4 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] == 0);
f0102b77:	68 41 75 10 f0       	push   $0xf0107541
f0102b7c:	68 63 72 10 f0       	push   $0xf0107263
f0102b81:	68 ef 03 00 00       	push   $0x3ef
f0102b86:	68 3d 72 10 f0       	push   $0xf010723d
f0102b8b:	e8 b0 d4 ff ff       	call   f0100040 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102b90:	83 ec 0c             	sub    $0xc,%esp
f0102b93:	68 48 71 10 f0       	push   $0xf0107148
f0102b98:	e8 30 0e 00 00       	call   f01039cd <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102b9d:	a1 8c 8e 23 f0       	mov    0xf0238e8c,%eax
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
f0102c20:	2b 05 90 8e 23 f0    	sub    0xf0238e90,%eax
f0102c26:	c1 f8 03             	sar    $0x3,%eax
f0102c29:	89 c2                	mov    %eax,%edx
f0102c2b:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102c2e:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102c33:	83 c4 10             	add    $0x10,%esp
f0102c36:	3b 05 88 8e 23 f0    	cmp    0xf0238e88,%eax
f0102c3c:	0f 83 d1 01 00 00    	jae    f0102e13 <mem_init+0x1ae6>
	memset(page2kva(pp1), 1, PGSIZE);
f0102c42:	83 ec 04             	sub    $0x4,%esp
f0102c45:	68 00 10 00 00       	push   $0x1000
f0102c4a:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102c4c:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102c52:	52                   	push   %edx
f0102c53:	e8 ef 29 00 00       	call   f0105647 <memset>
	return (pp - pages) << PGSHIFT;
f0102c58:	89 d8                	mov    %ebx,%eax
f0102c5a:	2b 05 90 8e 23 f0    	sub    0xf0238e90,%eax
f0102c60:	c1 f8 03             	sar    $0x3,%eax
f0102c63:	89 c2                	mov    %eax,%edx
f0102c65:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102c68:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102c6d:	83 c4 10             	add    $0x10,%esp
f0102c70:	3b 05 88 8e 23 f0    	cmp    0xf0238e88,%eax
f0102c76:	0f 83 a9 01 00 00    	jae    f0102e25 <mem_init+0x1af8>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c7c:	83 ec 04             	sub    $0x4,%esp
f0102c7f:	68 00 10 00 00       	push   $0x1000
f0102c84:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102c86:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102c8c:	52                   	push   %edx
f0102c8d:	e8 b5 29 00 00       	call   f0105647 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c92:	6a 02                	push   $0x2
f0102c94:	68 00 10 00 00       	push   $0x1000
f0102c99:	57                   	push   %edi
f0102c9a:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
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
f0102ccb:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
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
f0102d0b:	2b 05 90 8e 23 f0    	sub    0xf0238e90,%eax
f0102d11:	c1 f8 03             	sar    $0x3,%eax
f0102d14:	89 c2                	mov    %eax,%edx
f0102d16:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102d19:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102d1e:	3b 05 88 8e 23 f0    	cmp    0xf0238e88,%eax
f0102d24:	0f 83 8a 01 00 00    	jae    f0102eb4 <mem_init+0x1b87>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d2a:	81 ba 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%edx)
f0102d31:	03 03 03 
f0102d34:	0f 85 8c 01 00 00    	jne    f0102ec6 <mem_init+0x1b99>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d3a:	83 ec 08             	sub    $0x8,%esp
f0102d3d:	68 00 10 00 00       	push   $0x1000
f0102d42:	ff 35 8c 8e 23 f0    	pushl  0xf0238e8c
f0102d48:	e8 91 e4 ff ff       	call   f01011de <page_remove>
	assert(pp2->pp_ref == 0);
f0102d4d:	83 c4 10             	add    $0x10,%esp
f0102d50:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102d55:	0f 85 84 01 00 00    	jne    f0102edf <mem_init+0x1bb2>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102d5b:	8b 0d 8c 8e 23 f0    	mov    0xf0238e8c,%ecx
f0102d61:	8b 11                	mov    (%ecx),%edx
f0102d63:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102d69:	89 f0                	mov    %esi,%eax
f0102d6b:	2b 05 90 8e 23 f0    	sub    0xf0238e90,%eax
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
f0102d9f:	c7 04 24 dc 71 10 f0 	movl   $0xf01071dc,(%esp)
f0102da6:	e8 22 0c 00 00       	call   f01039cd <cprintf>
}
f0102dab:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102dae:	5b                   	pop    %ebx
f0102daf:	5e                   	pop    %esi
f0102db0:	5f                   	pop    %edi
f0102db1:	5d                   	pop    %ebp
f0102db2:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102db3:	50                   	push   %eax
f0102db4:	68 28 63 10 f0       	push   $0xf0106328
f0102db9:	68 f7 00 00 00       	push   $0xf7
f0102dbe:	68 3d 72 10 f0       	push   $0xf010723d
f0102dc3:	e8 78 d2 ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f0102dc8:	68 2b 73 10 f0       	push   $0xf010732b
f0102dcd:	68 63 72 10 f0       	push   $0xf0107263
f0102dd2:	68 c7 04 00 00       	push   $0x4c7
f0102dd7:	68 3d 72 10 f0       	push   $0xf010723d
f0102ddc:	e8 5f d2 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102de1:	68 41 73 10 f0       	push   $0xf0107341
f0102de6:	68 63 72 10 f0       	push   $0xf0107263
f0102deb:	68 c8 04 00 00       	push   $0x4c8
f0102df0:	68 3d 72 10 f0       	push   $0xf010723d
f0102df5:	e8 46 d2 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102dfa:	68 57 73 10 f0       	push   $0xf0107357
f0102dff:	68 63 72 10 f0       	push   $0xf0107263
f0102e04:	68 c9 04 00 00       	push   $0x4c9
f0102e09:	68 3d 72 10 f0       	push   $0xf010723d
f0102e0e:	e8 2d d2 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e13:	52                   	push   %edx
f0102e14:	68 04 63 10 f0       	push   $0xf0106304
f0102e19:	6a 58                	push   $0x58
f0102e1b:	68 49 72 10 f0       	push   $0xf0107249
f0102e20:	e8 1b d2 ff ff       	call   f0100040 <_panic>
f0102e25:	52                   	push   %edx
f0102e26:	68 04 63 10 f0       	push   $0xf0106304
f0102e2b:	6a 58                	push   $0x58
f0102e2d:	68 49 72 10 f0       	push   $0xf0107249
f0102e32:	e8 09 d2 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102e37:	68 28 74 10 f0       	push   $0xf0107428
f0102e3c:	68 63 72 10 f0       	push   $0xf0107263
f0102e41:	68 ce 04 00 00       	push   $0x4ce
f0102e46:	68 3d 72 10 f0       	push   $0xf010723d
f0102e4b:	e8 f0 d1 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102e50:	68 68 71 10 f0       	push   $0xf0107168
f0102e55:	68 63 72 10 f0       	push   $0xf0107263
f0102e5a:	68 cf 04 00 00       	push   $0x4cf
f0102e5f:	68 3d 72 10 f0       	push   $0xf010723d
f0102e64:	e8 d7 d1 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102e69:	68 8c 71 10 f0       	push   $0xf010718c
f0102e6e:	68 63 72 10 f0       	push   $0xf0107263
f0102e73:	68 d1 04 00 00       	push   $0x4d1
f0102e78:	68 3d 72 10 f0       	push   $0xf010723d
f0102e7d:	e8 be d1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102e82:	68 4a 74 10 f0       	push   $0xf010744a
f0102e87:	68 63 72 10 f0       	push   $0xf0107263
f0102e8c:	68 d2 04 00 00       	push   $0x4d2
f0102e91:	68 3d 72 10 f0       	push   $0xf010723d
f0102e96:	e8 a5 d1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102e9b:	68 b4 74 10 f0       	push   $0xf01074b4
f0102ea0:	68 63 72 10 f0       	push   $0xf0107263
f0102ea5:	68 d3 04 00 00       	push   $0x4d3
f0102eaa:	68 3d 72 10 f0       	push   $0xf010723d
f0102eaf:	e8 8c d1 ff ff       	call   f0100040 <_panic>
f0102eb4:	52                   	push   %edx
f0102eb5:	68 04 63 10 f0       	push   $0xf0106304
f0102eba:	6a 58                	push   $0x58
f0102ebc:	68 49 72 10 f0       	push   $0xf0107249
f0102ec1:	e8 7a d1 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102ec6:	68 b0 71 10 f0       	push   $0xf01071b0
f0102ecb:	68 63 72 10 f0       	push   $0xf0107263
f0102ed0:	68 d5 04 00 00       	push   $0x4d5
f0102ed5:	68 3d 72 10 f0       	push   $0xf010723d
f0102eda:	e8 61 d1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102edf:	68 82 74 10 f0       	push   $0xf0107482
f0102ee4:	68 63 72 10 f0       	push   $0xf0107263
f0102ee9:	68 d7 04 00 00       	push   $0x4d7
f0102eee:	68 3d 72 10 f0       	push   $0xf010723d
f0102ef3:	e8 48 d1 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102ef8:	68 38 6b 10 f0       	push   $0xf0106b38
f0102efd:	68 63 72 10 f0       	push   $0xf0107263
f0102f02:	68 da 04 00 00       	push   $0x4da
f0102f07:	68 3d 72 10 f0       	push   $0xf010723d
f0102f0c:	e8 2f d1 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0102f11:	68 39 74 10 f0       	push   $0xf0107439
f0102f16:	68 63 72 10 f0       	push   $0xf0107263
f0102f1b:	68 dc 04 00 00       	push   $0x4dc
f0102f20:	68 3d 72 10 f0       	push   $0xf010723d
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
f0102fa0:	a3 3c 82 23 f0       	mov    %eax,0xf023823c
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
f0102fe9:	ff 35 3c 82 23 f0    	pushl  0xf023823c
f0102fef:	ff 73 48             	pushl  0x48(%ebx)
f0102ff2:	68 08 72 10 f0       	push   $0xf0107208
f0102ff7:	e8 d1 09 00 00       	call   f01039cd <cprintf>
		env_destroy(env);	// may not return
f0102ffc:	89 1c 24             	mov    %ebx,(%esp)
f0102fff:	e8 a4 06 00 00       	call   f01036a8 <env_destroy>
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
f0103060:	68 50 75 10 f0       	push   $0xf0107550
f0103065:	68 37 01 00 00       	push   $0x137
f010306a:	68 45 76 10 f0       	push   $0xf0107645
f010306f:	e8 cc cf ff ff       	call   f0100040 <_panic>
			panic("At region_alloc: Page allocation failed");
f0103074:	83 ec 04             	sub    $0x4,%esp
f0103077:	68 74 75 10 f0       	push   $0xf0107574
f010307c:	68 42 01 00 00       	push   $0x142
f0103081:	68 45 76 10 f0       	push   $0xf0107645
f0103086:	e8 b5 cf ff ff       	call   f0100040 <_panic>
		{
			panic("At region_alloc: Page insertion failed");
f010308b:	83 ec 04             	sub    $0x4,%esp
f010308e:	68 9c 75 10 f0       	push   $0xf010759c
f0103093:	68 4b 01 00 00       	push   $0x14b
f0103098:	68 45 76 10 f0       	push   $0xf0107645
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
f01030c8:	03 1d 48 82 23 f0    	add    0xf0238248,%ebx
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
f01030eb:	e8 76 2b 00 00       	call   f0105c66 <cpunum>
f01030f0:	6b c0 74             	imul   $0x74,%eax,%eax
f01030f3:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
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
f0103112:	e8 4f 2b 00 00       	call   f0105c66 <cpunum>
f0103117:	6b c0 74             	imul   $0x74,%eax,%eax
f010311a:	39 98 28 90 23 f0    	cmp    %ebx,-0xfdc6fd8(%eax)
f0103120:	74 bb                	je     f01030dd <envid2env+0x33>
f0103122:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0103125:	e8 3c 2b 00 00       	call   f0105c66 <cpunum>
f010312a:	6b c0 74             	imul   $0x74,%eax,%eax
f010312d:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
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
f0103181:	8b 35 48 82 23 f0    	mov    0xf0238248,%esi
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
f01031b0:	89 35 4c 82 23 f0    	mov    %esi,0xf023824c
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
f01031ca:	8b 1d 4c 82 23 f0    	mov    0xf023824c,%ebx
f01031d0:	85 db                	test   %ebx,%ebx
f01031d2:	0f 84 8e 01 00 00    	je     f0103366 <env_alloc+0x1a7>
	if (!(p = page_alloc(ALLOC_ZERO)))
f01031d8:	83 ec 0c             	sub    $0xc,%esp
f01031db:	6a 01                	push   $0x1
f01031dd:	e8 98 dd ff ff       	call   f0100f7a <page_alloc>
f01031e2:	83 c4 10             	add    $0x10,%esp
f01031e5:	85 c0                	test   %eax,%eax
f01031e7:	0f 84 80 01 00 00    	je     f010336d <env_alloc+0x1ae>
	return (pp - pages) << PGSHIFT;
f01031ed:	89 c2                	mov    %eax,%edx
f01031ef:	2b 15 90 8e 23 f0    	sub    0xf0238e90,%edx
f01031f5:	c1 fa 03             	sar    $0x3,%edx
f01031f8:	89 d1                	mov    %edx,%ecx
f01031fa:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f01031fd:	81 e2 ff ff 0f 00    	and    $0xfffff,%edx
f0103203:	3b 15 88 8e 23 f0    	cmp    0xf0238e88,%edx
f0103209:	0f 83 30 01 00 00    	jae    f010333f <env_alloc+0x180>
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
f0103236:	8b 15 8c 8e 23 f0    	mov    0xf0238e8c,%edx
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
f0103257:	0f 86 f4 00 00 00    	jbe    f0103351 <env_alloc+0x192>
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
f0103283:	2b 15 48 82 23 f0    	sub    0xf0238248,%edx
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
f01032ba:	e8 88 23 00 00       	call   f0105647 <memset>
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
	e->env_pgfault_upcall = 0;
f01032de:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)
	e->env_ipc_recving = 0;
f01032e5:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
	env_free_list = e->env_link;
f01032e9:	8b 43 44             	mov    0x44(%ebx),%eax
f01032ec:	a3 4c 82 23 f0       	mov    %eax,0xf023824c
	*newenv_store = e;
f01032f1:	8b 45 08             	mov    0x8(%ebp),%eax
f01032f4:	89 18                	mov    %ebx,(%eax)
	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01032f6:	8b 5b 48             	mov    0x48(%ebx),%ebx
f01032f9:	e8 68 29 00 00       	call   f0105c66 <cpunum>
f01032fe:	6b c0 74             	imul   $0x74,%eax,%eax
f0103301:	83 c4 10             	add    $0x10,%esp
f0103304:	ba 00 00 00 00       	mov    $0x0,%edx
f0103309:	83 b8 28 90 23 f0 00 	cmpl   $0x0,-0xfdc6fd8(%eax)
f0103310:	74 11                	je     f0103323 <env_alloc+0x164>
f0103312:	e8 4f 29 00 00       	call   f0105c66 <cpunum>
f0103317:	6b c0 74             	imul   $0x74,%eax,%eax
f010331a:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f0103320:	8b 50 48             	mov    0x48(%eax),%edx
f0103323:	83 ec 04             	sub    $0x4,%esp
f0103326:	53                   	push   %ebx
f0103327:	52                   	push   %edx
f0103328:	68 50 76 10 f0       	push   $0xf0107650
f010332d:	e8 9b 06 00 00       	call   f01039cd <cprintf>
	return 0;
f0103332:	83 c4 10             	add    $0x10,%esp
f0103335:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010333a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010333d:	c9                   	leave  
f010333e:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010333f:	51                   	push   %ecx
f0103340:	68 04 63 10 f0       	push   $0xf0106304
f0103345:	6a 58                	push   $0x58
f0103347:	68 49 72 10 f0       	push   $0xf0107249
f010334c:	e8 ef cc ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103351:	50                   	push   %eax
f0103352:	68 28 63 10 f0       	push   $0xf0106328
f0103357:	68 d3 00 00 00       	push   $0xd3
f010335c:	68 45 76 10 f0       	push   $0xf0107645
f0103361:	e8 da cc ff ff       	call   f0100040 <_panic>
		return -E_NO_FREE_ENV;
f0103366:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010336b:	eb cd                	jmp    f010333a <env_alloc+0x17b>
		return -E_NO_MEM;
f010336d:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0103372:	eb c6                	jmp    f010333a <env_alloc+0x17b>

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
f010338a:	e8 30 fe ff ff       	call   f01031bf <env_alloc>
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
f01033c9:	68 c4 75 10 f0       	push   $0xf01075c4
f01033ce:	68 c4 01 00 00       	push   $0x1c4
f01033d3:	68 45 76 10 f0       	push   $0xf0107645
f01033d8:	e8 63 cc ff ff       	call   f0100040 <_panic>
		panic("At load_icode: Invalid head magic number");
f01033dd:	83 ec 04             	sub    $0x4,%esp
f01033e0:	68 e8 75 10 f0       	push   $0xf01075e8
f01033e5:	68 8c 01 00 00       	push   $0x18c
f01033ea:	68 45 76 10 f0       	push   $0xf0107645
f01033ef:	e8 4c cc ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033f4:	50                   	push   %eax
f01033f5:	68 28 63 10 f0       	push   $0xf0106328
f01033fa:	68 8f 01 00 00       	push   $0x18f
f01033ff:	68 45 76 10 f0       	push   $0xf0107645
f0103404:	e8 37 cc ff ff       	call   f0100040 <_panic>
				panic("At load_icode: file size bigger than memory size");
f0103409:	83 ec 04             	sub    $0x4,%esp
f010340c:	68 14 76 10 f0       	push   $0xf0107614
f0103411:	68 9b 01 00 00       	push   $0x19b
f0103416:	68 45 76 10 f0       	push   $0xf0107645
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
f010343a:	e8 ca fb ff ff       	call   f0103009 <region_alloc>
			memcpy((void*)ph->p_va,binary+ph->p_offset,ph->p_filesz);
f010343f:	83 ec 04             	sub    $0x4,%esp
f0103442:	ff 73 10             	pushl  0x10(%ebx)
f0103445:	89 f0                	mov    %esi,%eax
f0103447:	03 43 04             	add    0x4(%ebx),%eax
f010344a:	50                   	push   %eax
f010344b:	ff 73 08             	pushl  0x8(%ebx)
f010344e:	e8 a6 22 00 00       	call   f01056f9 <memcpy>
			memset((void*)(ph->p_va+ph->p_filesz),0,ph->p_memsz-ph->p_filesz);
f0103453:	8b 43 10             	mov    0x10(%ebx),%eax
f0103456:	83 c4 0c             	add    $0xc,%esp
f0103459:	8b 53 14             	mov    0x14(%ebx),%edx
f010345c:	29 c2                	sub    %eax,%edx
f010345e:	52                   	push   %edx
f010345f:	6a 00                	push   $0x0
f0103461:	03 43 08             	add    0x8(%ebx),%eax
f0103464:	50                   	push   %eax
f0103465:	e8 dd 21 00 00       	call   f0105647 <memset>
f010346a:	83 c4 10             	add    $0x10,%esp
f010346d:	eb b1                	jmp    f0103420 <env_create+0xac>
	lcr3(PADDR(kern_pgdir));
f010346f:	a1 8c 8e 23 f0       	mov    0xf0238e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0103474:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103479:	76 37                	jbe    f01034b2 <env_create+0x13e>
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
f010349c:	e8 68 fb ff ff       	call   f0103009 <region_alloc>
	e->env_type = type;
f01034a1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01034a4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01034a7:	89 50 50             	mov    %edx,0x50(%eax)
}
f01034aa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01034ad:	5b                   	pop    %ebx
f01034ae:	5e                   	pop    %esi
f01034af:	5f                   	pop    %edi
f01034b0:	5d                   	pop    %ebp
f01034b1:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034b2:	50                   	push   %eax
f01034b3:	68 28 63 10 f0       	push   $0xf0106328
f01034b8:	68 a8 01 00 00       	push   $0x1a8
f01034bd:	68 45 76 10 f0       	push   $0xf0107645
f01034c2:	e8 79 cb ff ff       	call   f0100040 <_panic>

f01034c7 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01034c7:	f3 0f 1e fb          	endbr32 
f01034cb:	55                   	push   %ebp
f01034cc:	89 e5                	mov    %esp,%ebp
f01034ce:	57                   	push   %edi
f01034cf:	56                   	push   %esi
f01034d0:	53                   	push   %ebx
f01034d1:	83 ec 1c             	sub    $0x1c,%esp
f01034d4:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01034d7:	e8 8a 27 00 00       	call   f0105c66 <cpunum>
f01034dc:	6b c0 74             	imul   $0x74,%eax,%eax
f01034df:	39 b8 28 90 23 f0    	cmp    %edi,-0xfdc6fd8(%eax)
f01034e5:	74 48                	je     f010352f <env_free+0x68>
		lcr3(PADDR(kern_pgdir));

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01034e7:	8b 5f 48             	mov    0x48(%edi),%ebx
f01034ea:	e8 77 27 00 00       	call   f0105c66 <cpunum>
f01034ef:	6b c0 74             	imul   $0x74,%eax,%eax
f01034f2:	ba 00 00 00 00       	mov    $0x0,%edx
f01034f7:	83 b8 28 90 23 f0 00 	cmpl   $0x0,-0xfdc6fd8(%eax)
f01034fe:	74 11                	je     f0103511 <env_free+0x4a>
f0103500:	e8 61 27 00 00       	call   f0105c66 <cpunum>
f0103505:	6b c0 74             	imul   $0x74,%eax,%eax
f0103508:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f010350e:	8b 50 48             	mov    0x48(%eax),%edx
f0103511:	83 ec 04             	sub    $0x4,%esp
f0103514:	53                   	push   %ebx
f0103515:	52                   	push   %edx
f0103516:	68 65 76 10 f0       	push   $0xf0107665
f010351b:	e8 ad 04 00 00       	call   f01039cd <cprintf>
f0103520:	83 c4 10             	add    $0x10,%esp
f0103523:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010352a:	e9 a9 00 00 00       	jmp    f01035d8 <env_free+0x111>
		lcr3(PADDR(kern_pgdir));
f010352f:	a1 8c 8e 23 f0       	mov    0xf0238e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0103534:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103539:	76 0a                	jbe    f0103545 <env_free+0x7e>
	return (physaddr_t)kva - KERNBASE;
f010353b:	05 00 00 00 10       	add    $0x10000000,%eax
f0103540:	0f 22 d8             	mov    %eax,%cr3
}
f0103543:	eb a2                	jmp    f01034e7 <env_free+0x20>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103545:	50                   	push   %eax
f0103546:	68 28 63 10 f0       	push   $0xf0106328
f010354b:	68 d8 01 00 00       	push   $0x1d8
f0103550:	68 45 76 10 f0       	push   $0xf0107645
f0103555:	e8 e6 ca ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010355a:	56                   	push   %esi
f010355b:	68 04 63 10 f0       	push   $0xf0106304
f0103560:	68 e7 01 00 00       	push   $0x1e7
f0103565:	68 45 76 10 f0       	push   $0xf0107645
f010356a:	e8 d1 ca ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010356f:	83 ec 08             	sub    $0x8,%esp
f0103572:	89 d8                	mov    %ebx,%eax
f0103574:	c1 e0 0c             	shl    $0xc,%eax
f0103577:	0b 45 e4             	or     -0x1c(%ebp),%eax
f010357a:	50                   	push   %eax
f010357b:	ff 77 60             	pushl  0x60(%edi)
f010357e:	e8 5b dc ff ff       	call   f01011de <page_remove>
f0103583:	83 c4 10             	add    $0x10,%esp
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103586:	83 c3 01             	add    $0x1,%ebx
f0103589:	83 c6 04             	add    $0x4,%esi
f010358c:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103592:	74 07                	je     f010359b <env_free+0xd4>
			if (pt[pteno] & PTE_P)
f0103594:	f6 06 01             	testb  $0x1,(%esi)
f0103597:	74 ed                	je     f0103586 <env_free+0xbf>
f0103599:	eb d4                	jmp    f010356f <env_free+0xa8>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f010359b:	8b 47 60             	mov    0x60(%edi),%eax
f010359e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01035a1:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f01035a8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01035ab:	3b 05 88 8e 23 f0    	cmp    0xf0238e88,%eax
f01035b1:	73 65                	jae    f0103618 <env_free+0x151>
		page_decref(pa2page(pa));
f01035b3:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01035b6:	a1 90 8e 23 f0       	mov    0xf0238e90,%eax
f01035bb:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01035be:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01035c1:	50                   	push   %eax
f01035c2:	e8 6b da ff ff       	call   f0101032 <page_decref>
f01035c7:	83 c4 10             	add    $0x10,%esp
f01035ca:	83 45 e0 04          	addl   $0x4,-0x20(%ebp)
f01035ce:	8b 45 e0             	mov    -0x20(%ebp),%eax
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01035d1:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f01035d6:	74 54                	je     f010362c <env_free+0x165>
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01035d8:	8b 47 60             	mov    0x60(%edi),%eax
f01035db:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01035de:	8b 04 10             	mov    (%eax,%edx,1),%eax
f01035e1:	a8 01                	test   $0x1,%al
f01035e3:	74 e5                	je     f01035ca <env_free+0x103>
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01035e5:	89 c6                	mov    %eax,%esi
f01035e7:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	if (PGNUM(pa) >= npages)
f01035ed:	c1 e8 0c             	shr    $0xc,%eax
f01035f0:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01035f3:	39 05 88 8e 23 f0    	cmp    %eax,0xf0238e88
f01035f9:	0f 86 5b ff ff ff    	jbe    f010355a <env_free+0x93>
	return (void *)(pa + KERNBASE);
f01035ff:	81 ee 00 00 00 10    	sub    $0x10000000,%esi
f0103605:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103608:	c1 e0 14             	shl    $0x14,%eax
f010360b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010360e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103613:	e9 7c ff ff ff       	jmp    f0103594 <env_free+0xcd>
		panic("pa2page called with invalid pa");
f0103618:	83 ec 04             	sub    $0x4,%esp
f010361b:	68 dc 69 10 f0       	push   $0xf01069dc
f0103620:	6a 51                	push   $0x51
f0103622:	68 49 72 10 f0       	push   $0xf0107249
f0103627:	e8 14 ca ff ff       	call   f0100040 <_panic>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f010362c:	8b 47 60             	mov    0x60(%edi),%eax
	if ((uint32_t)kva < KERNBASE)
f010362f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103634:	76 49                	jbe    f010367f <env_free+0x1b8>
	e->env_pgdir = 0;
f0103636:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f010363d:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f0103642:	c1 e8 0c             	shr    $0xc,%eax
f0103645:	3b 05 88 8e 23 f0    	cmp    0xf0238e88,%eax
f010364b:	73 47                	jae    f0103694 <env_free+0x1cd>
	page_decref(pa2page(pa));
f010364d:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103650:	8b 15 90 8e 23 f0    	mov    0xf0238e90,%edx
f0103656:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103659:	50                   	push   %eax
f010365a:	e8 d3 d9 ff ff       	call   f0101032 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f010365f:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103666:	a1 4c 82 23 f0       	mov    0xf023824c,%eax
f010366b:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f010366e:	89 3d 4c 82 23 f0    	mov    %edi,0xf023824c
}
f0103674:	83 c4 10             	add    $0x10,%esp
f0103677:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010367a:	5b                   	pop    %ebx
f010367b:	5e                   	pop    %esi
f010367c:	5f                   	pop    %edi
f010367d:	5d                   	pop    %ebp
f010367e:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010367f:	50                   	push   %eax
f0103680:	68 28 63 10 f0       	push   $0xf0106328
f0103685:	68 f5 01 00 00       	push   $0x1f5
f010368a:	68 45 76 10 f0       	push   $0xf0107645
f010368f:	e8 ac c9 ff ff       	call   f0100040 <_panic>
		panic("pa2page called with invalid pa");
f0103694:	83 ec 04             	sub    $0x4,%esp
f0103697:	68 dc 69 10 f0       	push   $0xf01069dc
f010369c:	6a 51                	push   $0x51
f010369e:	68 49 72 10 f0       	push   $0xf0107249
f01036a3:	e8 98 c9 ff ff       	call   f0100040 <_panic>

f01036a8 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f01036a8:	f3 0f 1e fb          	endbr32 
f01036ac:	55                   	push   %ebp
f01036ad:	89 e5                	mov    %esp,%ebp
f01036af:	53                   	push   %ebx
f01036b0:	83 ec 04             	sub    $0x4,%esp
f01036b3:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01036b6:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f01036ba:	74 21                	je     f01036dd <env_destroy+0x35>
		e->env_status = ENV_DYING;
		return;
	}

	env_free(e);
f01036bc:	83 ec 0c             	sub    $0xc,%esp
f01036bf:	53                   	push   %ebx
f01036c0:	e8 02 fe ff ff       	call   f01034c7 <env_free>

	if (curenv == e) {
f01036c5:	e8 9c 25 00 00       	call   f0105c66 <cpunum>
f01036ca:	6b c0 74             	imul   $0x74,%eax,%eax
f01036cd:	83 c4 10             	add    $0x10,%esp
f01036d0:	39 98 28 90 23 f0    	cmp    %ebx,-0xfdc6fd8(%eax)
f01036d6:	74 1e                	je     f01036f6 <env_destroy+0x4e>
		curenv = NULL;
		sched_yield();
	}
}
f01036d8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01036db:	c9                   	leave  
f01036dc:	c3                   	ret    
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01036dd:	e8 84 25 00 00       	call   f0105c66 <cpunum>
f01036e2:	6b c0 74             	imul   $0x74,%eax,%eax
f01036e5:	39 98 28 90 23 f0    	cmp    %ebx,-0xfdc6fd8(%eax)
f01036eb:	74 cf                	je     f01036bc <env_destroy+0x14>
		e->env_status = ENV_DYING;
f01036ed:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01036f4:	eb e2                	jmp    f01036d8 <env_destroy+0x30>
		curenv = NULL;
f01036f6:	e8 6b 25 00 00       	call   f0105c66 <cpunum>
f01036fb:	6b c0 74             	imul   $0x74,%eax,%eax
f01036fe:	c7 80 28 90 23 f0 00 	movl   $0x0,-0xfdc6fd8(%eax)
f0103705:	00 00 00 
		sched_yield();
f0103708:	e8 00 0e 00 00       	call   f010450d <sched_yield>

f010370d <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f010370d:	f3 0f 1e fb          	endbr32 
f0103711:	55                   	push   %ebp
f0103712:	89 e5                	mov    %esp,%ebp
f0103714:	53                   	push   %ebx
f0103715:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103718:	e8 49 25 00 00       	call   f0105c66 <cpunum>
f010371d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103720:	8b 98 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%ebx
f0103726:	e8 3b 25 00 00       	call   f0105c66 <cpunum>
f010372b:	89 43 5c             	mov    %eax,0x5c(%ebx)
	asm volatile(
f010372e:	8b 65 08             	mov    0x8(%ebp),%esp
f0103731:	61                   	popa   
f0103732:	07                   	pop    %es
f0103733:	1f                   	pop    %ds
f0103734:	83 c4 08             	add    $0x8,%esp
f0103737:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103738:	83 ec 04             	sub    $0x4,%esp
f010373b:	68 7b 76 10 f0       	push   $0xf010767b
f0103740:	68 27 02 00 00       	push   $0x227
f0103745:	68 45 76 10 f0       	push   $0xf0107645
f010374a:	e8 f1 c8 ff ff       	call   f0100040 <_panic>

f010374f <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010374f:	f3 0f 1e fb          	endbr32 
f0103753:	55                   	push   %ebp
f0103754:	89 e5                	mov    %esp,%ebp
f0103756:	83 ec 08             	sub    $0x8,%esp
	
	// panic("env_run not yet implemented");

	// step 1
	// set the env_status field
	if(curenv)
f0103759:	e8 08 25 00 00       	call   f0105c66 <cpunum>
f010375e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103761:	83 b8 28 90 23 f0 00 	cmpl   $0x0,-0xfdc6fd8(%eax)
f0103768:	74 14                	je     f010377e <env_run+0x2f>
	{
		if(curenv->env_status == ENV_RUNNING)
f010376a:	e8 f7 24 00 00       	call   f0105c66 <cpunum>
f010376f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103772:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f0103778:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010377c:	74 7d                	je     f01037fb <env_run+0xac>
			curenv->env_status = ENV_RUNNABLE;
		}
	}

	// switch to new environment
	curenv = e;
f010377e:	e8 e3 24 00 00       	call   f0105c66 <cpunum>
f0103783:	6b c0 74             	imul   $0x74,%eax,%eax
f0103786:	8b 55 08             	mov    0x8(%ebp),%edx
f0103789:	89 90 28 90 23 f0    	mov    %edx,-0xfdc6fd8(%eax)
	curenv->env_status = ENV_RUNNING;
f010378f:	e8 d2 24 00 00       	call   f0105c66 <cpunum>
f0103794:	6b c0 74             	imul   $0x74,%eax,%eax
f0103797:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f010379d:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f01037a4:	e8 bd 24 00 00       	call   f0105c66 <cpunum>
f01037a9:	6b c0 74             	imul   $0x74,%eax,%eax
f01037ac:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f01037b2:	83 40 58 01          	addl   $0x1,0x58(%eax)
	// switch to user page directory
	lcr3(PADDR(curenv->env_pgdir));
f01037b6:	e8 ab 24 00 00       	call   f0105c66 <cpunum>
f01037bb:	6b c0 74             	imul   $0x74,%eax,%eax
f01037be:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f01037c4:	8b 40 60             	mov    0x60(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01037c7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01037cc:	76 47                	jbe    f0103815 <env_run+0xc6>
	return (physaddr_t)kva - KERNBASE;
f01037ce:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01037d3:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01037d6:	83 ec 0c             	sub    $0xc,%esp
f01037d9:	68 c0 33 12 f0       	push   $0xf01233c0
f01037de:	e8 a9 27 00 00       	call   f0105f8c <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01037e3:	f3 90                	pause  
	unlock_kernel();
	// step 2
	env_pop_tf(&curenv->env_tf);
f01037e5:	e8 7c 24 00 00       	call   f0105c66 <cpunum>
f01037ea:	83 c4 04             	add    $0x4,%esp
f01037ed:	6b c0 74             	imul   $0x74,%eax,%eax
f01037f0:	ff b0 28 90 23 f0    	pushl  -0xfdc6fd8(%eax)
f01037f6:	e8 12 ff ff ff       	call   f010370d <env_pop_tf>
			curenv->env_status = ENV_RUNNABLE;
f01037fb:	e8 66 24 00 00       	call   f0105c66 <cpunum>
f0103800:	6b c0 74             	imul   $0x74,%eax,%eax
f0103803:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f0103809:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
f0103810:	e9 69 ff ff ff       	jmp    f010377e <env_run+0x2f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103815:	50                   	push   %eax
f0103816:	68 28 63 10 f0       	push   $0xf0106328
f010381b:	68 57 02 00 00       	push   $0x257
f0103820:	68 45 76 10 f0       	push   $0xf0107645
f0103825:	e8 16 c8 ff ff       	call   f0100040 <_panic>

f010382a <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010382a:	f3 0f 1e fb          	endbr32 
f010382e:	55                   	push   %ebp
f010382f:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103831:	8b 45 08             	mov    0x8(%ebp),%eax
f0103834:	ba 70 00 00 00       	mov    $0x70,%edx
f0103839:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010383a:	ba 71 00 00 00       	mov    $0x71,%edx
f010383f:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103840:	0f b6 c0             	movzbl %al,%eax
}
f0103843:	5d                   	pop    %ebp
f0103844:	c3                   	ret    

f0103845 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103845:	f3 0f 1e fb          	endbr32 
f0103849:	55                   	push   %ebp
f010384a:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010384c:	8b 45 08             	mov    0x8(%ebp),%eax
f010384f:	ba 70 00 00 00       	mov    $0x70,%edx
f0103854:	ee                   	out    %al,(%dx)
f0103855:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103858:	ba 71 00 00 00       	mov    $0x71,%edx
f010385d:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010385e:	5d                   	pop    %ebp
f010385f:	c3                   	ret    

f0103860 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103860:	f3 0f 1e fb          	endbr32 
f0103864:	55                   	push   %ebp
f0103865:	89 e5                	mov    %esp,%ebp
f0103867:	56                   	push   %esi
f0103868:	53                   	push   %ebx
f0103869:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f010386c:	66 a3 a8 33 12 f0    	mov    %ax,0xf01233a8
	if (!didinit)
f0103872:	80 3d 50 82 23 f0 00 	cmpb   $0x0,0xf0238250
f0103879:	75 07                	jne    f0103882 <irq_setmask_8259A+0x22>
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
}
f010387b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010387e:	5b                   	pop    %ebx
f010387f:	5e                   	pop    %esi
f0103880:	5d                   	pop    %ebp
f0103881:	c3                   	ret    
f0103882:	89 c6                	mov    %eax,%esi
f0103884:	ba 21 00 00 00       	mov    $0x21,%edx
f0103889:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
f010388a:	66 c1 e8 08          	shr    $0x8,%ax
f010388e:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103893:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0103894:	83 ec 0c             	sub    $0xc,%esp
f0103897:	68 87 76 10 f0       	push   $0xf0107687
f010389c:	e8 2c 01 00 00       	call   f01039cd <cprintf>
f01038a1:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f01038a4:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f01038a9:	0f b7 f6             	movzwl %si,%esi
f01038ac:	f7 d6                	not    %esi
f01038ae:	eb 19                	jmp    f01038c9 <irq_setmask_8259A+0x69>
			cprintf(" %d", i);
f01038b0:	83 ec 08             	sub    $0x8,%esp
f01038b3:	53                   	push   %ebx
f01038b4:	68 5f 7b 10 f0       	push   $0xf0107b5f
f01038b9:	e8 0f 01 00 00       	call   f01039cd <cprintf>
f01038be:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f01038c1:	83 c3 01             	add    $0x1,%ebx
f01038c4:	83 fb 10             	cmp    $0x10,%ebx
f01038c7:	74 07                	je     f01038d0 <irq_setmask_8259A+0x70>
		if (~mask & (1<<i))
f01038c9:	0f a3 de             	bt     %ebx,%esi
f01038cc:	73 f3                	jae    f01038c1 <irq_setmask_8259A+0x61>
f01038ce:	eb e0                	jmp    f01038b0 <irq_setmask_8259A+0x50>
	cprintf("\n");
f01038d0:	83 ec 0c             	sub    $0xc,%esp
f01038d3:	68 1d 75 10 f0       	push   $0xf010751d
f01038d8:	e8 f0 00 00 00       	call   f01039cd <cprintf>
f01038dd:	83 c4 10             	add    $0x10,%esp
f01038e0:	eb 99                	jmp    f010387b <irq_setmask_8259A+0x1b>

f01038e2 <pic_init>:
{
f01038e2:	f3 0f 1e fb          	endbr32 
f01038e6:	55                   	push   %ebp
f01038e7:	89 e5                	mov    %esp,%ebp
f01038e9:	57                   	push   %edi
f01038ea:	56                   	push   %esi
f01038eb:	53                   	push   %ebx
f01038ec:	83 ec 0c             	sub    $0xc,%esp
	didinit = 1;
f01038ef:	c6 05 50 82 23 f0 01 	movb   $0x1,0xf0238250
f01038f6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01038fb:	bb 21 00 00 00       	mov    $0x21,%ebx
f0103900:	89 da                	mov    %ebx,%edx
f0103902:	ee                   	out    %al,(%dx)
f0103903:	b9 a1 00 00 00       	mov    $0xa1,%ecx
f0103908:	89 ca                	mov    %ecx,%edx
f010390a:	ee                   	out    %al,(%dx)
f010390b:	bf 11 00 00 00       	mov    $0x11,%edi
f0103910:	be 20 00 00 00       	mov    $0x20,%esi
f0103915:	89 f8                	mov    %edi,%eax
f0103917:	89 f2                	mov    %esi,%edx
f0103919:	ee                   	out    %al,(%dx)
f010391a:	b8 20 00 00 00       	mov    $0x20,%eax
f010391f:	89 da                	mov    %ebx,%edx
f0103921:	ee                   	out    %al,(%dx)
f0103922:	b8 04 00 00 00       	mov    $0x4,%eax
f0103927:	ee                   	out    %al,(%dx)
f0103928:	b8 03 00 00 00       	mov    $0x3,%eax
f010392d:	ee                   	out    %al,(%dx)
f010392e:	bb a0 00 00 00       	mov    $0xa0,%ebx
f0103933:	89 f8                	mov    %edi,%eax
f0103935:	89 da                	mov    %ebx,%edx
f0103937:	ee                   	out    %al,(%dx)
f0103938:	b8 28 00 00 00       	mov    $0x28,%eax
f010393d:	89 ca                	mov    %ecx,%edx
f010393f:	ee                   	out    %al,(%dx)
f0103940:	b8 02 00 00 00       	mov    $0x2,%eax
f0103945:	ee                   	out    %al,(%dx)
f0103946:	b8 01 00 00 00       	mov    $0x1,%eax
f010394b:	ee                   	out    %al,(%dx)
f010394c:	bf 68 00 00 00       	mov    $0x68,%edi
f0103951:	89 f8                	mov    %edi,%eax
f0103953:	89 f2                	mov    %esi,%edx
f0103955:	ee                   	out    %al,(%dx)
f0103956:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010395b:	89 c8                	mov    %ecx,%eax
f010395d:	ee                   	out    %al,(%dx)
f010395e:	89 f8                	mov    %edi,%eax
f0103960:	89 da                	mov    %ebx,%edx
f0103962:	ee                   	out    %al,(%dx)
f0103963:	89 c8                	mov    %ecx,%eax
f0103965:	ee                   	out    %al,(%dx)
	if (irq_mask_8259A != 0xFFFF)
f0103966:	0f b7 05 a8 33 12 f0 	movzwl 0xf01233a8,%eax
f010396d:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103971:	75 08                	jne    f010397b <pic_init+0x99>
}
f0103973:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103976:	5b                   	pop    %ebx
f0103977:	5e                   	pop    %esi
f0103978:	5f                   	pop    %edi
f0103979:	5d                   	pop    %ebp
f010397a:	c3                   	ret    
		irq_setmask_8259A(irq_mask_8259A);
f010397b:	83 ec 0c             	sub    $0xc,%esp
f010397e:	0f b7 c0             	movzwl %ax,%eax
f0103981:	50                   	push   %eax
f0103982:	e8 d9 fe ff ff       	call   f0103860 <irq_setmask_8259A>
f0103987:	83 c4 10             	add    $0x10,%esp
}
f010398a:	eb e7                	jmp    f0103973 <pic_init+0x91>

f010398c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010398c:	f3 0f 1e fb          	endbr32 
f0103990:	55                   	push   %ebp
f0103991:	89 e5                	mov    %esp,%ebp
f0103993:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103996:	ff 75 08             	pushl  0x8(%ebp)
f0103999:	e8 eb cd ff ff       	call   f0100789 <cputchar>
	*cnt++;
}
f010399e:	83 c4 10             	add    $0x10,%esp
f01039a1:	c9                   	leave  
f01039a2:	c3                   	ret    

f01039a3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01039a3:	f3 0f 1e fb          	endbr32 
f01039a7:	55                   	push   %ebp
f01039a8:	89 e5                	mov    %esp,%ebp
f01039aa:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01039ad:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01039b4:	ff 75 0c             	pushl  0xc(%ebp)
f01039b7:	ff 75 08             	pushl  0x8(%ebp)
f01039ba:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01039bd:	50                   	push   %eax
f01039be:	68 8c 39 10 f0       	push   $0xf010398c
f01039c3:	e8 28 15 00 00       	call   f0104ef0 <vprintfmt>
	return cnt;
}
f01039c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01039cb:	c9                   	leave  
f01039cc:	c3                   	ret    

f01039cd <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01039cd:	f3 0f 1e fb          	endbr32 
f01039d1:	55                   	push   %ebp
f01039d2:	89 e5                	mov    %esp,%ebp
f01039d4:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01039d7:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01039da:	50                   	push   %eax
f01039db:	ff 75 08             	pushl  0x8(%ebp)
f01039de:	e8 c0 ff ff ff       	call   f01039a3 <vcprintf>
	va_end(ap);

	return cnt;
}
f01039e3:	c9                   	leave  
f01039e4:	c3                   	ret    

f01039e5 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01039e5:	f3 0f 1e fb          	endbr32 
f01039e9:	55                   	push   %ebp
f01039ea:	89 e5                	mov    %esp,%ebp
f01039ec:	57                   	push   %edi
f01039ed:	56                   	push   %esi
f01039ee:	53                   	push   %ebx
f01039ef:	83 ec 1c             	sub    $0x1c,%esp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	uint8_t id = thiscpu->cpu_id;
f01039f2:	e8 6f 22 00 00       	call   f0105c66 <cpunum>
f01039f7:	6b c0 74             	imul   $0x74,%eax,%eax
f01039fa:	0f b6 b8 20 90 23 f0 	movzbl -0xfdc6fe0(%eax),%edi
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP-id*(KSTKSIZE+KSTKGAP);
f0103a01:	89 f8                	mov    %edi,%eax
f0103a03:	0f b6 d8             	movzbl %al,%ebx
f0103a06:	e8 5b 22 00 00       	call   f0105c66 <cpunum>
f0103a0b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a0e:	89 d9                	mov    %ebx,%ecx
f0103a10:	c1 e1 10             	shl    $0x10,%ecx
f0103a13:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0103a18:	29 ca                	sub    %ecx,%edx
f0103a1a:	89 90 30 90 23 f0    	mov    %edx,-0xfdc6fd0(%eax)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f0103a20:	e8 41 22 00 00       	call   f0105c66 <cpunum>
f0103a25:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a28:	66 c7 80 34 90 23 f0 	movw   $0x10,-0xfdc6fcc(%eax)
f0103a2f:	10 00 
	thiscpu->cpu_ts.ts_iomb = sizeof(struct Taskstate);
f0103a31:	e8 30 22 00 00       	call   f0105c66 <cpunum>
f0103a36:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a39:	66 c7 80 92 90 23 f0 	movw   $0x68,-0xfdc6f6e(%eax)
f0103a40:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+id] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
f0103a42:	83 c3 05             	add    $0x5,%ebx
f0103a45:	e8 1c 22 00 00       	call   f0105c66 <cpunum>
f0103a4a:	89 c6                	mov    %eax,%esi
f0103a4c:	e8 15 22 00 00       	call   f0105c66 <cpunum>
f0103a51:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103a54:	e8 0d 22 00 00       	call   f0105c66 <cpunum>
f0103a59:	66 c7 04 dd 40 33 12 	movw   $0x67,-0xfedccc0(,%ebx,8)
f0103a60:	f0 67 00 
f0103a63:	6b f6 74             	imul   $0x74,%esi,%esi
f0103a66:	81 c6 2c 90 23 f0    	add    $0xf023902c,%esi
f0103a6c:	66 89 34 dd 42 33 12 	mov    %si,-0xfedccbe(,%ebx,8)
f0103a73:	f0 
f0103a74:	6b 55 e4 74          	imul   $0x74,-0x1c(%ebp),%edx
f0103a78:	81 c2 2c 90 23 f0    	add    $0xf023902c,%edx
f0103a7e:	c1 ea 10             	shr    $0x10,%edx
f0103a81:	88 14 dd 44 33 12 f0 	mov    %dl,-0xfedccbc(,%ebx,8)
f0103a88:	c6 04 dd 46 33 12 f0 	movb   $0x40,-0xfedccba(,%ebx,8)
f0103a8f:	40 
f0103a90:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a93:	05 2c 90 23 f0       	add    $0xf023902c,%eax
f0103a98:	c1 e8 18             	shr    $0x18,%eax
f0103a9b:	88 04 dd 47 33 12 f0 	mov    %al,-0xfedccb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3)+id].sd_s = 0;
f0103aa2:	c6 04 dd 45 33 12 f0 	movb   $0x89,-0xfedccbb(,%ebx,8)
f0103aa9:	89 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0+(id<<3));
f0103aaa:	89 f8                	mov    %edi,%eax
f0103aac:	0f b6 f8             	movzbl %al,%edi
f0103aaf:	8d 3c fd 28 00 00 00 	lea    0x28(,%edi,8),%edi
	asm volatile("ltr %0" : : "r" (sel));
f0103ab6:	0f 00 df             	ltr    %di
	asm volatile("lidt (%0)" : : "r" (p));
f0103ab9:	b8 ac 33 12 f0       	mov    $0xf01233ac,%eax
f0103abe:	0f 01 18             	lidtl  (%eax)

	// Load the IDT
	lidt(&idt_pd);
}
f0103ac1:	83 c4 1c             	add    $0x1c,%esp
f0103ac4:	5b                   	pop    %ebx
f0103ac5:	5e                   	pop    %esi
f0103ac6:	5f                   	pop    %edi
f0103ac7:	5d                   	pop    %ebp
f0103ac8:	c3                   	ret    

f0103ac9 <trap_init>:
{
f0103ac9:	f3 0f 1e fb          	endbr32 
f0103acd:	55                   	push   %ebp
f0103ace:	89 e5                	mov    %esp,%ebp
f0103ad0:	83 ec 08             	sub    $0x8,%esp
    SETGATE(idt[T_DIVIDE], 0, GD_KT, DIVIDE, 0);
f0103ad3:	b8 c2 43 10 f0       	mov    $0xf01043c2,%eax
f0103ad8:	66 a3 60 82 23 f0    	mov    %ax,0xf0238260
f0103ade:	66 c7 05 62 82 23 f0 	movw   $0x8,0xf0238262
f0103ae5:	08 00 
f0103ae7:	c6 05 64 82 23 f0 00 	movb   $0x0,0xf0238264
f0103aee:	c6 05 65 82 23 f0 8e 	movb   $0x8e,0xf0238265
f0103af5:	c1 e8 10             	shr    $0x10,%eax
f0103af8:	66 a3 66 82 23 f0    	mov    %ax,0xf0238266
	SETGATE(idt[T_DEBUG], 0, GD_KT, DEBUG, 0);
f0103afe:	b8 c8 43 10 f0       	mov    $0xf01043c8,%eax
f0103b03:	66 a3 68 82 23 f0    	mov    %ax,0xf0238268
f0103b09:	66 c7 05 6a 82 23 f0 	movw   $0x8,0xf023826a
f0103b10:	08 00 
f0103b12:	c6 05 6c 82 23 f0 00 	movb   $0x0,0xf023826c
f0103b19:	c6 05 6d 82 23 f0 8e 	movb   $0x8e,0xf023826d
f0103b20:	c1 e8 10             	shr    $0x10,%eax
f0103b23:	66 a3 6e 82 23 f0    	mov    %ax,0xf023826e
	SETGATE(idt[T_NMI], 0, GD_KT, NMI, 0);
f0103b29:	b8 ce 43 10 f0       	mov    $0xf01043ce,%eax
f0103b2e:	66 a3 70 82 23 f0    	mov    %ax,0xf0238270
f0103b34:	66 c7 05 72 82 23 f0 	movw   $0x8,0xf0238272
f0103b3b:	08 00 
f0103b3d:	c6 05 74 82 23 f0 00 	movb   $0x0,0xf0238274
f0103b44:	c6 05 75 82 23 f0 8e 	movb   $0x8e,0xf0238275
f0103b4b:	c1 e8 10             	shr    $0x10,%eax
f0103b4e:	66 a3 76 82 23 f0    	mov    %ax,0xf0238276
	SETGATE(idt[T_BRKPT], 1, GD_KT, BRKPT, 3);
f0103b54:	b8 d4 43 10 f0       	mov    $0xf01043d4,%eax
f0103b59:	66 a3 78 82 23 f0    	mov    %ax,0xf0238278
f0103b5f:	66 c7 05 7a 82 23 f0 	movw   $0x8,0xf023827a
f0103b66:	08 00 
f0103b68:	c6 05 7c 82 23 f0 00 	movb   $0x0,0xf023827c
f0103b6f:	c6 05 7d 82 23 f0 ef 	movb   $0xef,0xf023827d
f0103b76:	c1 e8 10             	shr    $0x10,%eax
f0103b79:	66 a3 7e 82 23 f0    	mov    %ax,0xf023827e
	SETGATE(idt[T_OFLOW], 0, GD_KT, OFLOW, 0);
f0103b7f:	b8 da 43 10 f0       	mov    $0xf01043da,%eax
f0103b84:	66 a3 80 82 23 f0    	mov    %ax,0xf0238280
f0103b8a:	66 c7 05 82 82 23 f0 	movw   $0x8,0xf0238282
f0103b91:	08 00 
f0103b93:	c6 05 84 82 23 f0 00 	movb   $0x0,0xf0238284
f0103b9a:	c6 05 85 82 23 f0 8e 	movb   $0x8e,0xf0238285
f0103ba1:	c1 e8 10             	shr    $0x10,%eax
f0103ba4:	66 a3 86 82 23 f0    	mov    %ax,0xf0238286
	SETGATE(idt[T_BOUND], 0, GD_KT, BOUND, 0);
f0103baa:	b8 e0 43 10 f0       	mov    $0xf01043e0,%eax
f0103baf:	66 a3 88 82 23 f0    	mov    %ax,0xf0238288
f0103bb5:	66 c7 05 8a 82 23 f0 	movw   $0x8,0xf023828a
f0103bbc:	08 00 
f0103bbe:	c6 05 8c 82 23 f0 00 	movb   $0x0,0xf023828c
f0103bc5:	c6 05 8d 82 23 f0 8e 	movb   $0x8e,0xf023828d
f0103bcc:	c1 e8 10             	shr    $0x10,%eax
f0103bcf:	66 a3 8e 82 23 f0    	mov    %ax,0xf023828e
	SETGATE(idt[T_ILLOP], 0, GD_KT, ILLOP, 0);
f0103bd5:	b8 e6 43 10 f0       	mov    $0xf01043e6,%eax
f0103bda:	66 a3 90 82 23 f0    	mov    %ax,0xf0238290
f0103be0:	66 c7 05 92 82 23 f0 	movw   $0x8,0xf0238292
f0103be7:	08 00 
f0103be9:	c6 05 94 82 23 f0 00 	movb   $0x0,0xf0238294
f0103bf0:	c6 05 95 82 23 f0 8e 	movb   $0x8e,0xf0238295
f0103bf7:	c1 e8 10             	shr    $0x10,%eax
f0103bfa:	66 a3 96 82 23 f0    	mov    %ax,0xf0238296
	SETGATE(idt[T_DEVICE], 0, GD_KT, DEVICE, 0);
f0103c00:	b8 ec 43 10 f0       	mov    $0xf01043ec,%eax
f0103c05:	66 a3 98 82 23 f0    	mov    %ax,0xf0238298
f0103c0b:	66 c7 05 9a 82 23 f0 	movw   $0x8,0xf023829a
f0103c12:	08 00 
f0103c14:	c6 05 9c 82 23 f0 00 	movb   $0x0,0xf023829c
f0103c1b:	c6 05 9d 82 23 f0 8e 	movb   $0x8e,0xf023829d
f0103c22:	c1 e8 10             	shr    $0x10,%eax
f0103c25:	66 a3 9e 82 23 f0    	mov    %ax,0xf023829e
	SETGATE(idt[T_DBLFLT], 0, GD_KT, DBLFLT, 0);
f0103c2b:	b8 f2 43 10 f0       	mov    $0xf01043f2,%eax
f0103c30:	66 a3 a0 82 23 f0    	mov    %ax,0xf02382a0
f0103c36:	66 c7 05 a2 82 23 f0 	movw   $0x8,0xf02382a2
f0103c3d:	08 00 
f0103c3f:	c6 05 a4 82 23 f0 00 	movb   $0x0,0xf02382a4
f0103c46:	c6 05 a5 82 23 f0 8e 	movb   $0x8e,0xf02382a5
f0103c4d:	c1 e8 10             	shr    $0x10,%eax
f0103c50:	66 a3 a6 82 23 f0    	mov    %ax,0xf02382a6
	SETGATE(idt[T_TSS], 0, GD_KT, TSS, 0);
f0103c56:	b8 f6 43 10 f0       	mov    $0xf01043f6,%eax
f0103c5b:	66 a3 b0 82 23 f0    	mov    %ax,0xf02382b0
f0103c61:	66 c7 05 b2 82 23 f0 	movw   $0x8,0xf02382b2
f0103c68:	08 00 
f0103c6a:	c6 05 b4 82 23 f0 00 	movb   $0x0,0xf02382b4
f0103c71:	c6 05 b5 82 23 f0 8e 	movb   $0x8e,0xf02382b5
f0103c78:	c1 e8 10             	shr    $0x10,%eax
f0103c7b:	66 a3 b6 82 23 f0    	mov    %ax,0xf02382b6
	SETGATE(idt[T_SEGNP], 0, GD_KT, SEGNP, 0);
f0103c81:	b8 fa 43 10 f0       	mov    $0xf01043fa,%eax
f0103c86:	66 a3 b8 82 23 f0    	mov    %ax,0xf02382b8
f0103c8c:	66 c7 05 ba 82 23 f0 	movw   $0x8,0xf02382ba
f0103c93:	08 00 
f0103c95:	c6 05 bc 82 23 f0 00 	movb   $0x0,0xf02382bc
f0103c9c:	c6 05 bd 82 23 f0 8e 	movb   $0x8e,0xf02382bd
f0103ca3:	c1 e8 10             	shr    $0x10,%eax
f0103ca6:	66 a3 be 82 23 f0    	mov    %ax,0xf02382be
	SETGATE(idt[T_STACK], 0, GD_KT, STACK, 0);
f0103cac:	b8 fe 43 10 f0       	mov    $0xf01043fe,%eax
f0103cb1:	66 a3 c0 82 23 f0    	mov    %ax,0xf02382c0
f0103cb7:	66 c7 05 c2 82 23 f0 	movw   $0x8,0xf02382c2
f0103cbe:	08 00 
f0103cc0:	c6 05 c4 82 23 f0 00 	movb   $0x0,0xf02382c4
f0103cc7:	c6 05 c5 82 23 f0 8e 	movb   $0x8e,0xf02382c5
f0103cce:	c1 e8 10             	shr    $0x10,%eax
f0103cd1:	66 a3 c6 82 23 f0    	mov    %ax,0xf02382c6
	SETGATE(idt[T_GPFLT], 0, GD_KT, GPFLT, 0);
f0103cd7:	b8 02 44 10 f0       	mov    $0xf0104402,%eax
f0103cdc:	66 a3 c8 82 23 f0    	mov    %ax,0xf02382c8
f0103ce2:	66 c7 05 ca 82 23 f0 	movw   $0x8,0xf02382ca
f0103ce9:	08 00 
f0103ceb:	c6 05 cc 82 23 f0 00 	movb   $0x0,0xf02382cc
f0103cf2:	c6 05 cd 82 23 f0 8e 	movb   $0x8e,0xf02382cd
f0103cf9:	c1 e8 10             	shr    $0x10,%eax
f0103cfc:	66 a3 ce 82 23 f0    	mov    %ax,0xf02382ce
	SETGATE(idt[T_PGFLT], 0, GD_KT, PGFLT, 0);
f0103d02:	b8 06 44 10 f0       	mov    $0xf0104406,%eax
f0103d07:	66 a3 d0 82 23 f0    	mov    %ax,0xf02382d0
f0103d0d:	66 c7 05 d2 82 23 f0 	movw   $0x8,0xf02382d2
f0103d14:	08 00 
f0103d16:	c6 05 d4 82 23 f0 00 	movb   $0x0,0xf02382d4
f0103d1d:	c6 05 d5 82 23 f0 8e 	movb   $0x8e,0xf02382d5
f0103d24:	c1 e8 10             	shr    $0x10,%eax
f0103d27:	66 a3 d6 82 23 f0    	mov    %ax,0xf02382d6
	SETGATE(idt[T_FPERR], 0, GD_KT, FPERR, 0);
f0103d2d:	b8 0a 44 10 f0       	mov    $0xf010440a,%eax
f0103d32:	66 a3 e0 82 23 f0    	mov    %ax,0xf02382e0
f0103d38:	66 c7 05 e2 82 23 f0 	movw   $0x8,0xf02382e2
f0103d3f:	08 00 
f0103d41:	c6 05 e4 82 23 f0 00 	movb   $0x0,0xf02382e4
f0103d48:	c6 05 e5 82 23 f0 8e 	movb   $0x8e,0xf02382e5
f0103d4f:	c1 e8 10             	shr    $0x10,%eax
f0103d52:	66 a3 e6 82 23 f0    	mov    %ax,0xf02382e6
	SETGATE(idt[T_ALIGN], 0, GD_KT, ALIGN, 0);
f0103d58:	b8 10 44 10 f0       	mov    $0xf0104410,%eax
f0103d5d:	66 a3 e8 82 23 f0    	mov    %ax,0xf02382e8
f0103d63:	66 c7 05 ea 82 23 f0 	movw   $0x8,0xf02382ea
f0103d6a:	08 00 
f0103d6c:	c6 05 ec 82 23 f0 00 	movb   $0x0,0xf02382ec
f0103d73:	c6 05 ed 82 23 f0 8e 	movb   $0x8e,0xf02382ed
f0103d7a:	c1 e8 10             	shr    $0x10,%eax
f0103d7d:	66 a3 ee 82 23 f0    	mov    %ax,0xf02382ee
	SETGATE(idt[T_MCHK], 0, GD_KT, MCHK, 0);
f0103d83:	b8 14 44 10 f0       	mov    $0xf0104414,%eax
f0103d88:	66 a3 f0 82 23 f0    	mov    %ax,0xf02382f0
f0103d8e:	66 c7 05 f2 82 23 f0 	movw   $0x8,0xf02382f2
f0103d95:	08 00 
f0103d97:	c6 05 f4 82 23 f0 00 	movb   $0x0,0xf02382f4
f0103d9e:	c6 05 f5 82 23 f0 8e 	movb   $0x8e,0xf02382f5
f0103da5:	c1 e8 10             	shr    $0x10,%eax
f0103da8:	66 a3 f6 82 23 f0    	mov    %ax,0xf02382f6
	SETGATE(idt[T_SIMDERR], 0, GD_KT, SIMDERR, 0);
f0103dae:	b8 1a 44 10 f0       	mov    $0xf010441a,%eax
f0103db3:	66 a3 f8 82 23 f0    	mov    %ax,0xf02382f8
f0103db9:	66 c7 05 fa 82 23 f0 	movw   $0x8,0xf02382fa
f0103dc0:	08 00 
f0103dc2:	c6 05 fc 82 23 f0 00 	movb   $0x0,0xf02382fc
f0103dc9:	c6 05 fd 82 23 f0 8e 	movb   $0x8e,0xf02382fd
f0103dd0:	c1 e8 10             	shr    $0x10,%eax
f0103dd3:	66 a3 fe 82 23 f0    	mov    %ax,0xf02382fe
	SETGATE(idt[T_SYSCALL], 1, GD_KT, SYSCALL, 3);
f0103dd9:	b8 20 44 10 f0       	mov    $0xf0104420,%eax
f0103dde:	66 a3 e0 83 23 f0    	mov    %ax,0xf02383e0
f0103de4:	66 c7 05 e2 83 23 f0 	movw   $0x8,0xf02383e2
f0103deb:	08 00 
f0103ded:	c6 05 e4 83 23 f0 00 	movb   $0x0,0xf02383e4
f0103df4:	c6 05 e5 83 23 f0 ef 	movb   $0xef,0xf02383e5
f0103dfb:	c1 e8 10             	shr    $0x10,%eax
f0103dfe:	66 a3 e6 83 23 f0    	mov    %ax,0xf02383e6
	SETGATE(idt[T_DEFAULT], 0, GD_KT, DEFAULT, 0);
f0103e04:	b8 26 44 10 f0       	mov    $0xf0104426,%eax
f0103e09:	66 a3 00 92 23 f0    	mov    %ax,0xf0239200
f0103e0f:	66 c7 05 02 92 23 f0 	movw   $0x8,0xf0239202
f0103e16:	08 00 
f0103e18:	c6 05 04 92 23 f0 00 	movb   $0x0,0xf0239204
f0103e1f:	c6 05 05 92 23 f0 8e 	movb   $0x8e,0xf0239205
f0103e26:	c1 e8 10             	shr    $0x10,%eax
f0103e29:	66 a3 06 92 23 f0    	mov    %ax,0xf0239206
	trap_init_percpu();
f0103e2f:	e8 b1 fb ff ff       	call   f01039e5 <trap_init_percpu>
}
f0103e34:	c9                   	leave  
f0103e35:	c3                   	ret    

f0103e36 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103e36:	f3 0f 1e fb          	endbr32 
f0103e3a:	55                   	push   %ebp
f0103e3b:	89 e5                	mov    %esp,%ebp
f0103e3d:	53                   	push   %ebx
f0103e3e:	83 ec 0c             	sub    $0xc,%esp
f0103e41:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103e44:	ff 33                	pushl  (%ebx)
f0103e46:	68 9b 76 10 f0       	push   $0xf010769b
f0103e4b:	e8 7d fb ff ff       	call   f01039cd <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103e50:	83 c4 08             	add    $0x8,%esp
f0103e53:	ff 73 04             	pushl  0x4(%ebx)
f0103e56:	68 aa 76 10 f0       	push   $0xf01076aa
f0103e5b:	e8 6d fb ff ff       	call   f01039cd <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103e60:	83 c4 08             	add    $0x8,%esp
f0103e63:	ff 73 08             	pushl  0x8(%ebx)
f0103e66:	68 b9 76 10 f0       	push   $0xf01076b9
f0103e6b:	e8 5d fb ff ff       	call   f01039cd <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103e70:	83 c4 08             	add    $0x8,%esp
f0103e73:	ff 73 0c             	pushl  0xc(%ebx)
f0103e76:	68 c8 76 10 f0       	push   $0xf01076c8
f0103e7b:	e8 4d fb ff ff       	call   f01039cd <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103e80:	83 c4 08             	add    $0x8,%esp
f0103e83:	ff 73 10             	pushl  0x10(%ebx)
f0103e86:	68 d7 76 10 f0       	push   $0xf01076d7
f0103e8b:	e8 3d fb ff ff       	call   f01039cd <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103e90:	83 c4 08             	add    $0x8,%esp
f0103e93:	ff 73 14             	pushl  0x14(%ebx)
f0103e96:	68 e6 76 10 f0       	push   $0xf01076e6
f0103e9b:	e8 2d fb ff ff       	call   f01039cd <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103ea0:	83 c4 08             	add    $0x8,%esp
f0103ea3:	ff 73 18             	pushl  0x18(%ebx)
f0103ea6:	68 f5 76 10 f0       	push   $0xf01076f5
f0103eab:	e8 1d fb ff ff       	call   f01039cd <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103eb0:	83 c4 08             	add    $0x8,%esp
f0103eb3:	ff 73 1c             	pushl  0x1c(%ebx)
f0103eb6:	68 04 77 10 f0       	push   $0xf0107704
f0103ebb:	e8 0d fb ff ff       	call   f01039cd <cprintf>
}
f0103ec0:	83 c4 10             	add    $0x10,%esp
f0103ec3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103ec6:	c9                   	leave  
f0103ec7:	c3                   	ret    

f0103ec8 <print_trapframe>:
{
f0103ec8:	f3 0f 1e fb          	endbr32 
f0103ecc:	55                   	push   %ebp
f0103ecd:	89 e5                	mov    %esp,%ebp
f0103ecf:	56                   	push   %esi
f0103ed0:	53                   	push   %ebx
f0103ed1:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103ed4:	e8 8d 1d 00 00       	call   f0105c66 <cpunum>
f0103ed9:	83 ec 04             	sub    $0x4,%esp
f0103edc:	50                   	push   %eax
f0103edd:	53                   	push   %ebx
f0103ede:	68 68 77 10 f0       	push   $0xf0107768
f0103ee3:	e8 e5 fa ff ff       	call   f01039cd <cprintf>
	print_regs(&tf->tf_regs);
f0103ee8:	89 1c 24             	mov    %ebx,(%esp)
f0103eeb:	e8 46 ff ff ff       	call   f0103e36 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103ef0:	83 c4 08             	add    $0x8,%esp
f0103ef3:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103ef7:	50                   	push   %eax
f0103ef8:	68 86 77 10 f0       	push   $0xf0107786
f0103efd:	e8 cb fa ff ff       	call   f01039cd <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103f02:	83 c4 08             	add    $0x8,%esp
f0103f05:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103f09:	50                   	push   %eax
f0103f0a:	68 99 77 10 f0       	push   $0xf0107799
f0103f0f:	e8 b9 fa ff ff       	call   f01039cd <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103f14:	8b 43 28             	mov    0x28(%ebx),%eax
	if (trapno < ARRAY_SIZE(excnames))
f0103f17:	83 c4 10             	add    $0x10,%esp
f0103f1a:	83 f8 13             	cmp    $0x13,%eax
f0103f1d:	0f 86 da 00 00 00    	jbe    f0103ffd <print_trapframe+0x135>
		return "System call";
f0103f23:	ba 13 77 10 f0       	mov    $0xf0107713,%edx
	if (trapno == T_SYSCALL)
f0103f28:	83 f8 30             	cmp    $0x30,%eax
f0103f2b:	74 13                	je     f0103f40 <print_trapframe+0x78>
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103f2d:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
f0103f30:	83 fa 0f             	cmp    $0xf,%edx
f0103f33:	ba 1f 77 10 f0       	mov    $0xf010771f,%edx
f0103f38:	b9 2e 77 10 f0       	mov    $0xf010772e,%ecx
f0103f3d:	0f 46 d1             	cmovbe %ecx,%edx
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103f40:	83 ec 04             	sub    $0x4,%esp
f0103f43:	52                   	push   %edx
f0103f44:	50                   	push   %eax
f0103f45:	68 ac 77 10 f0       	push   $0xf01077ac
f0103f4a:	e8 7e fa ff ff       	call   f01039cd <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103f4f:	83 c4 10             	add    $0x10,%esp
f0103f52:	39 1d 60 8a 23 f0    	cmp    %ebx,0xf0238a60
f0103f58:	0f 84 ab 00 00 00    	je     f0104009 <print_trapframe+0x141>
	cprintf("  err  0x%08x", tf->tf_err);
f0103f5e:	83 ec 08             	sub    $0x8,%esp
f0103f61:	ff 73 2c             	pushl  0x2c(%ebx)
f0103f64:	68 cd 77 10 f0       	push   $0xf01077cd
f0103f69:	e8 5f fa ff ff       	call   f01039cd <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f0103f6e:	83 c4 10             	add    $0x10,%esp
f0103f71:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103f75:	0f 85 b1 00 00 00    	jne    f010402c <print_trapframe+0x164>
			tf->tf_err & 1 ? "protection" : "not-present");
f0103f7b:	8b 43 2c             	mov    0x2c(%ebx),%eax
		cprintf(" [%s, %s, %s]\n",
f0103f7e:	a8 01                	test   $0x1,%al
f0103f80:	b9 41 77 10 f0       	mov    $0xf0107741,%ecx
f0103f85:	ba 4c 77 10 f0       	mov    $0xf010774c,%edx
f0103f8a:	0f 44 ca             	cmove  %edx,%ecx
f0103f8d:	a8 02                	test   $0x2,%al
f0103f8f:	be 58 77 10 f0       	mov    $0xf0107758,%esi
f0103f94:	ba 5e 77 10 f0       	mov    $0xf010775e,%edx
f0103f99:	0f 45 d6             	cmovne %esi,%edx
f0103f9c:	a8 04                	test   $0x4,%al
f0103f9e:	b8 63 77 10 f0       	mov    $0xf0107763,%eax
f0103fa3:	be 98 78 10 f0       	mov    $0xf0107898,%esi
f0103fa8:	0f 44 c6             	cmove  %esi,%eax
f0103fab:	51                   	push   %ecx
f0103fac:	52                   	push   %edx
f0103fad:	50                   	push   %eax
f0103fae:	68 db 77 10 f0       	push   $0xf01077db
f0103fb3:	e8 15 fa ff ff       	call   f01039cd <cprintf>
f0103fb8:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103fbb:	83 ec 08             	sub    $0x8,%esp
f0103fbe:	ff 73 30             	pushl  0x30(%ebx)
f0103fc1:	68 ea 77 10 f0       	push   $0xf01077ea
f0103fc6:	e8 02 fa ff ff       	call   f01039cd <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103fcb:	83 c4 08             	add    $0x8,%esp
f0103fce:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103fd2:	50                   	push   %eax
f0103fd3:	68 f9 77 10 f0       	push   $0xf01077f9
f0103fd8:	e8 f0 f9 ff ff       	call   f01039cd <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103fdd:	83 c4 08             	add    $0x8,%esp
f0103fe0:	ff 73 38             	pushl  0x38(%ebx)
f0103fe3:	68 0c 78 10 f0       	push   $0xf010780c
f0103fe8:	e8 e0 f9 ff ff       	call   f01039cd <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103fed:	83 c4 10             	add    $0x10,%esp
f0103ff0:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103ff4:	75 4b                	jne    f0104041 <print_trapframe+0x179>
}
f0103ff6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103ff9:	5b                   	pop    %ebx
f0103ffa:	5e                   	pop    %esi
f0103ffb:	5d                   	pop    %ebp
f0103ffc:	c3                   	ret    
		return excnames[trapno];
f0103ffd:	8b 14 85 40 7a 10 f0 	mov    -0xfef85c0(,%eax,4),%edx
f0104004:	e9 37 ff ff ff       	jmp    f0103f40 <print_trapframe+0x78>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0104009:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010400d:	0f 85 4b ff ff ff    	jne    f0103f5e <print_trapframe+0x96>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0104013:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0104016:	83 ec 08             	sub    $0x8,%esp
f0104019:	50                   	push   %eax
f010401a:	68 be 77 10 f0       	push   $0xf01077be
f010401f:	e8 a9 f9 ff ff       	call   f01039cd <cprintf>
f0104024:	83 c4 10             	add    $0x10,%esp
f0104027:	e9 32 ff ff ff       	jmp    f0103f5e <print_trapframe+0x96>
		cprintf("\n");
f010402c:	83 ec 0c             	sub    $0xc,%esp
f010402f:	68 1d 75 10 f0       	push   $0xf010751d
f0104034:	e8 94 f9 ff ff       	call   f01039cd <cprintf>
f0104039:	83 c4 10             	add    $0x10,%esp
f010403c:	e9 7a ff ff ff       	jmp    f0103fbb <print_trapframe+0xf3>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0104041:	83 ec 08             	sub    $0x8,%esp
f0104044:	ff 73 3c             	pushl  0x3c(%ebx)
f0104047:	68 1b 78 10 f0       	push   $0xf010781b
f010404c:	e8 7c f9 ff ff       	call   f01039cd <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0104051:	83 c4 08             	add    $0x8,%esp
f0104054:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0104058:	50                   	push   %eax
f0104059:	68 2a 78 10 f0       	push   $0xf010782a
f010405e:	e8 6a f9 ff ff       	call   f01039cd <cprintf>
f0104063:	83 c4 10             	add    $0x10,%esp
}
f0104066:	eb 8e                	jmp    f0103ff6 <print_trapframe+0x12e>

f0104068 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0104068:	f3 0f 1e fb          	endbr32 
f010406c:	55                   	push   %ebp
f010406d:	89 e5                	mov    %esp,%ebp
f010406f:	57                   	push   %edi
f0104070:	56                   	push   %esi
f0104071:	53                   	push   %ebx
f0104072:	83 ec 1c             	sub    $0x1c,%esp
f0104075:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104078:	0f 20 d6             	mov    %cr2,%esi

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	// check low-bits of tf_cs
	if((tf->tf_cs & 3) == 0)
f010407b:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f010407f:	75 15                	jne    f0104096 <page_fault_handler+0x2e>
	{
		panic("At page_fault_handler: page fault at %08x.\n",fault_va);
f0104081:	56                   	push   %esi
f0104082:	68 e4 79 10 f0       	push   $0xf01079e4
f0104087:	68 6d 01 00 00       	push   $0x16d
f010408c:	68 3d 78 10 f0       	push   $0xf010783d
f0104091:	e8 aa bf ff ff       	call   f0100040 <_panic>
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	// no self-defined pgfault_upcall function
	if(curenv->env_pgfault_upcall == NULL)
f0104096:	e8 cb 1b 00 00       	call   f0105c66 <cpunum>
f010409b:	6b c0 74             	imul   $0x74,%eax,%eax
f010409e:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f01040a4:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f01040a8:	0f 84 92 00 00 00    	je     f0104140 <page_fault_handler+0xd8>
	
	struct UTrapframe* utf;
	uintptr_t addr;
	// determine utf address
	size_t size = sizeof(struct UTrapframe)+ sizeof(uint32_t);
	if (tf->tf_esp >= UXSTACKTOP-PGSIZE && tf->tf_esp < UXSTACKTOP)
f01040ae:	8b 43 3c             	mov    0x3c(%ebx),%eax
f01040b1:	8d 90 00 10 40 11    	lea    0x11401000(%eax),%edx
	{
		addr = tf->tf_esp - size;
	}
	else
	{
		addr = UXSTACKTOP - size;
f01040b7:	c7 45 e4 c8 ff bf ee 	movl   $0xeebfffc8,-0x1c(%ebp)
	if (tf->tf_esp >= UXSTACKTOP-PGSIZE && tf->tf_esp < UXSTACKTOP)
f01040be:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f01040c4:	77 06                	ja     f01040cc <page_fault_handler+0x64>
		addr = tf->tf_esp - size;
f01040c6:	83 e8 38             	sub    $0x38,%eax
f01040c9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	}
	// check the permission
	user_mem_assert(curenv,(void*)addr,size,PTE_P|PTE_W|PTE_U);
f01040cc:	e8 95 1b 00 00       	call   f0105c66 <cpunum>
f01040d1:	6a 07                	push   $0x7
f01040d3:	6a 38                	push   $0x38
f01040d5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01040d8:	57                   	push   %edi
f01040d9:	6b c0 74             	imul   $0x74,%eax,%eax
f01040dc:	ff b0 28 90 23 f0    	pushl  -0xfdc6fd8(%eax)
f01040e2:	e8 d2 ee ff ff       	call   f0102fb9 <user_mem_assert>

	// set the attributes
	utf = (struct UTrapframe*)addr;
	utf->utf_fault_va = fault_va;
f01040e7:	89 37                	mov    %esi,(%edi)
	utf->utf_eflags = tf->tf_eflags;
f01040e9:	8b 43 38             	mov    0x38(%ebx),%eax
f01040ec:	89 47 2c             	mov    %eax,0x2c(%edi)
	utf->utf_err = tf->tf_err;
f01040ef:	8b 43 2c             	mov    0x2c(%ebx),%eax
f01040f2:	89 47 04             	mov    %eax,0x4(%edi)
	utf->utf_esp = tf->tf_esp;
f01040f5:	8b 43 3c             	mov    0x3c(%ebx),%eax
f01040f8:	89 47 30             	mov    %eax,0x30(%edi)
	utf->utf_eip = tf->tf_eip;
f01040fb:	8b 43 30             	mov    0x30(%ebx),%eax
f01040fe:	89 47 28             	mov    %eax,0x28(%edi)
	utf->utf_regs = tf->tf_regs;
f0104101:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0104104:	8d 7f 08             	lea    0x8(%edi),%edi
f0104107:	b9 08 00 00 00       	mov    $0x8,%ecx
f010410c:	89 de                	mov    %ebx,%esi
f010410e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	// change the value in eip field of tf
	tf->tf_eip = (uintptr_t)curenv->env_pgfault_upcall;
f0104110:	e8 51 1b 00 00       	call   f0105c66 <cpunum>
f0104115:	6b c0 74             	imul   $0x74,%eax,%eax
f0104118:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f010411e:	8b 40 64             	mov    0x64(%eax),%eax
f0104121:	89 43 30             	mov    %eax,0x30(%ebx)
	tf->tf_esp = (uintptr_t)utf;
f0104124:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104127:	89 53 3c             	mov    %edx,0x3c(%ebx)
	env_run(curenv);
f010412a:	e8 37 1b 00 00       	call   f0105c66 <cpunum>
f010412f:	83 c4 04             	add    $0x4,%esp
f0104132:	6b c0 74             	imul   $0x74,%eax,%eax
f0104135:	ff b0 28 90 23 f0    	pushl  -0xfdc6fd8(%eax)
f010413b:	e8 0f f6 ff ff       	call   f010374f <env_run>
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0104140:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0104143:	e8 1e 1b 00 00       	call   f0105c66 <cpunum>
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0104148:	57                   	push   %edi
f0104149:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f010414a:	6b c0 74             	imul   $0x74,%eax,%eax
		cprintf("[%08x] user fault va %08x ip %08x\n",
f010414d:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f0104153:	ff 70 48             	pushl  0x48(%eax)
f0104156:	68 10 7a 10 f0       	push   $0xf0107a10
f010415b:	e8 6d f8 ff ff       	call   f01039cd <cprintf>
		print_trapframe(tf);
f0104160:	89 1c 24             	mov    %ebx,(%esp)
f0104163:	e8 60 fd ff ff       	call   f0103ec8 <print_trapframe>
		env_destroy(curenv);
f0104168:	e8 f9 1a 00 00       	call   f0105c66 <cpunum>
f010416d:	83 c4 04             	add    $0x4,%esp
f0104170:	6b c0 74             	imul   $0x74,%eax,%eax
f0104173:	ff b0 28 90 23 f0    	pushl  -0xfdc6fd8(%eax)
f0104179:	e8 2a f5 ff ff       	call   f01036a8 <env_destroy>
f010417e:	83 c4 10             	add    $0x10,%esp
f0104181:	e9 28 ff ff ff       	jmp    f01040ae <page_fault_handler+0x46>

f0104186 <trap>:
{
f0104186:	f3 0f 1e fb          	endbr32 
f010418a:	55                   	push   %ebp
f010418b:	89 e5                	mov    %esp,%ebp
f010418d:	57                   	push   %edi
f010418e:	56                   	push   %esi
f010418f:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::: "cc");
f0104192:	fc                   	cld    
	if (panicstr)
f0104193:	83 3d 80 8e 23 f0 00 	cmpl   $0x0,0xf0238e80
f010419a:	74 01                	je     f010419d <trap+0x17>
		asm volatile("hlt");
f010419c:	f4                   	hlt    
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f010419d:	e8 c4 1a 00 00       	call   f0105c66 <cpunum>
f01041a2:	6b d0 74             	imul   $0x74,%eax,%edx
f01041a5:	83 c2 04             	add    $0x4,%edx
	asm volatile("lock; xchgl %0, %1"
f01041a8:	b8 01 00 00 00       	mov    $0x1,%eax
f01041ad:	f0 87 82 20 90 23 f0 	lock xchg %eax,-0xfdc6fe0(%edx)
f01041b4:	83 f8 02             	cmp    $0x2,%eax
f01041b7:	74 6f                	je     f0104228 <trap+0xa2>
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01041b9:	9c                   	pushf  
f01041ba:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
f01041bb:	f6 c4 02             	test   $0x2,%ah
f01041be:	75 7d                	jne    f010423d <trap+0xb7>
	if ((tf->tf_cs & 3) == 3) {
f01041c0:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01041c4:	83 e0 03             	and    $0x3,%eax
f01041c7:	66 83 f8 03          	cmp    $0x3,%ax
f01041cb:	0f 84 85 00 00 00    	je     f0104256 <trap+0xd0>
	last_tf = tf;
f01041d1:	89 35 60 8a 23 f0    	mov    %esi,0xf0238a60
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f01041d7:	8b 46 28             	mov    0x28(%esi),%eax
f01041da:	83 f8 27             	cmp    $0x27,%eax
f01041dd:	0f 84 18 01 00 00    	je     f01042fb <trap+0x175>
	switch(tf->tf_trapno)
f01041e3:	83 f8 03             	cmp    $0x3,%eax
f01041e6:	0f 84 45 01 00 00    	je     f0104331 <trap+0x1ab>
f01041ec:	0f 86 23 01 00 00    	jbe    f0104315 <trap+0x18f>
f01041f2:	83 f8 0e             	cmp    $0xe,%eax
f01041f5:	0f 84 2d 01 00 00    	je     f0104328 <trap+0x1a2>
f01041fb:	83 f8 30             	cmp    $0x30,%eax
f01041fe:	0f 85 63 01 00 00    	jne    f0104367 <trap+0x1e1>
			int32_t ret = syscall(regs->reg_eax,regs->reg_edx,regs->reg_ecx,regs->reg_ebx,regs->reg_edi,regs->reg_esi);
f0104204:	83 ec 08             	sub    $0x8,%esp
f0104207:	ff 76 04             	pushl  0x4(%esi)
f010420a:	ff 36                	pushl  (%esi)
f010420c:	ff 76 10             	pushl  0x10(%esi)
f010420f:	ff 76 18             	pushl  0x18(%esi)
f0104212:	ff 76 14             	pushl  0x14(%esi)
f0104215:	ff 76 1c             	pushl  0x1c(%esi)
f0104218:	e8 a8 03 00 00       	call   f01045c5 <syscall>
			regs->reg_eax = (uint32_t)ret;
f010421d:	89 46 1c             	mov    %eax,0x1c(%esi)
			return;
f0104220:	83 c4 20             	add    $0x20,%esp
f0104223:	e9 15 01 00 00       	jmp    f010433d <trap+0x1b7>
	spin_lock(&kernel_lock);
f0104228:	83 ec 0c             	sub    $0xc,%esp
f010422b:	68 c0 33 12 f0       	push   $0xf01233c0
f0104230:	e8 b9 1c 00 00       	call   f0105eee <spin_lock>
}
f0104235:	83 c4 10             	add    $0x10,%esp
f0104238:	e9 7c ff ff ff       	jmp    f01041b9 <trap+0x33>
	assert(!(read_eflags() & FL_IF));
f010423d:	68 49 78 10 f0       	push   $0xf0107849
f0104242:	68 63 72 10 f0       	push   $0xf0107263
f0104247:	68 35 01 00 00       	push   $0x135
f010424c:	68 3d 78 10 f0       	push   $0xf010783d
f0104251:	e8 ea bd ff ff       	call   f0100040 <_panic>
	spin_lock(&kernel_lock);
f0104256:	83 ec 0c             	sub    $0xc,%esp
f0104259:	68 c0 33 12 f0       	push   $0xf01233c0
f010425e:	e8 8b 1c 00 00       	call   f0105eee <spin_lock>
		assert(curenv);
f0104263:	e8 fe 19 00 00       	call   f0105c66 <cpunum>
f0104268:	6b c0 74             	imul   $0x74,%eax,%eax
f010426b:	83 c4 10             	add    $0x10,%esp
f010426e:	83 b8 28 90 23 f0 00 	cmpl   $0x0,-0xfdc6fd8(%eax)
f0104275:	74 3e                	je     f01042b5 <trap+0x12f>
		if (curenv->env_status == ENV_DYING) {
f0104277:	e8 ea 19 00 00       	call   f0105c66 <cpunum>
f010427c:	6b c0 74             	imul   $0x74,%eax,%eax
f010427f:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f0104285:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0104289:	74 43                	je     f01042ce <trap+0x148>
		curenv->env_tf = *tf;
f010428b:	e8 d6 19 00 00       	call   f0105c66 <cpunum>
f0104290:	6b c0 74             	imul   $0x74,%eax,%eax
f0104293:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f0104299:	b9 11 00 00 00       	mov    $0x11,%ecx
f010429e:	89 c7                	mov    %eax,%edi
f01042a0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &curenv->env_tf;
f01042a2:	e8 bf 19 00 00       	call   f0105c66 <cpunum>
f01042a7:	6b c0 74             	imul   $0x74,%eax,%eax
f01042aa:	8b b0 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%esi
f01042b0:	e9 1c ff ff ff       	jmp    f01041d1 <trap+0x4b>
		assert(curenv);
f01042b5:	68 62 78 10 f0       	push   $0xf0107862
f01042ba:	68 63 72 10 f0       	push   $0xf0107263
f01042bf:	68 3d 01 00 00       	push   $0x13d
f01042c4:	68 3d 78 10 f0       	push   $0xf010783d
f01042c9:	e8 72 bd ff ff       	call   f0100040 <_panic>
			env_free(curenv);
f01042ce:	e8 93 19 00 00       	call   f0105c66 <cpunum>
f01042d3:	83 ec 0c             	sub    $0xc,%esp
f01042d6:	6b c0 74             	imul   $0x74,%eax,%eax
f01042d9:	ff b0 28 90 23 f0    	pushl  -0xfdc6fd8(%eax)
f01042df:	e8 e3 f1 ff ff       	call   f01034c7 <env_free>
			curenv = NULL;
f01042e4:	e8 7d 19 00 00       	call   f0105c66 <cpunum>
f01042e9:	6b c0 74             	imul   $0x74,%eax,%eax
f01042ec:	c7 80 28 90 23 f0 00 	movl   $0x0,-0xfdc6fd8(%eax)
f01042f3:	00 00 00 
			sched_yield();
f01042f6:	e8 12 02 00 00       	call   f010450d <sched_yield>
		cprintf("Spurious interrupt on irq 7\n");
f01042fb:	83 ec 0c             	sub    $0xc,%esp
f01042fe:	68 69 78 10 f0       	push   $0xf0107869
f0104303:	e8 c5 f6 ff ff       	call   f01039cd <cprintf>
		print_trapframe(tf);
f0104308:	89 34 24             	mov    %esi,(%esp)
f010430b:	e8 b8 fb ff ff       	call   f0103ec8 <print_trapframe>
		return;
f0104310:	83 c4 10             	add    $0x10,%esp
f0104313:	eb 28                	jmp    f010433d <trap+0x1b7>
	switch(tf->tf_trapno)
f0104315:	83 f8 01             	cmp    $0x1,%eax
f0104318:	75 4d                	jne    f0104367 <trap+0x1e1>
			monitor(tf);
f010431a:	83 ec 0c             	sub    $0xc,%esp
f010431d:	56                   	push   %esi
f010431e:	e8 51 c6 ff ff       	call   f0100974 <monitor>
			return;
f0104323:	83 c4 10             	add    $0x10,%esp
f0104326:	eb 15                	jmp    f010433d <trap+0x1b7>
			page_fault_handler(tf);
f0104328:	83 ec 0c             	sub    $0xc,%esp
f010432b:	56                   	push   %esi
f010432c:	e8 37 fd ff ff       	call   f0104068 <page_fault_handler>
			monitor(tf);
f0104331:	83 ec 0c             	sub    $0xc,%esp
f0104334:	56                   	push   %esi
f0104335:	e8 3a c6 ff ff       	call   f0100974 <monitor>
			return;
f010433a:	83 c4 10             	add    $0x10,%esp
	if (curenv && curenv->env_status == ENV_RUNNING)
f010433d:	e8 24 19 00 00       	call   f0105c66 <cpunum>
f0104342:	6b c0 74             	imul   $0x74,%eax,%eax
f0104345:	83 b8 28 90 23 f0 00 	cmpl   $0x0,-0xfdc6fd8(%eax)
f010434c:	74 14                	je     f0104362 <trap+0x1dc>
f010434e:	e8 13 19 00 00       	call   f0105c66 <cpunum>
f0104353:	6b c0 74             	imul   $0x74,%eax,%eax
f0104356:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f010435c:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104360:	74 4a                	je     f01043ac <trap+0x226>
		sched_yield();
f0104362:	e8 a6 01 00 00       	call   f010450d <sched_yield>
	print_trapframe(tf);
f0104367:	83 ec 0c             	sub    $0xc,%esp
f010436a:	56                   	push   %esi
f010436b:	e8 58 fb ff ff       	call   f0103ec8 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0104370:	83 c4 10             	add    $0x10,%esp
f0104373:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0104378:	74 1b                	je     f0104395 <trap+0x20f>
		env_destroy(curenv);
f010437a:	e8 e7 18 00 00       	call   f0105c66 <cpunum>
f010437f:	83 ec 0c             	sub    $0xc,%esp
f0104382:	6b c0 74             	imul   $0x74,%eax,%eax
f0104385:	ff b0 28 90 23 f0    	pushl  -0xfdc6fd8(%eax)
f010438b:	e8 18 f3 ff ff       	call   f01036a8 <env_destroy>
		return;
f0104390:	83 c4 10             	add    $0x10,%esp
f0104393:	eb a8                	jmp    f010433d <trap+0x1b7>
		panic("unhandled trap in kernel");
f0104395:	83 ec 04             	sub    $0x4,%esp
f0104398:	68 86 78 10 f0       	push   $0xf0107886
f010439d:	68 1b 01 00 00       	push   $0x11b
f01043a2:	68 3d 78 10 f0       	push   $0xf010783d
f01043a7:	e8 94 bc ff ff       	call   f0100040 <_panic>
		env_run(curenv);
f01043ac:	e8 b5 18 00 00       	call   f0105c66 <cpunum>
f01043b1:	83 ec 0c             	sub    $0xc,%esp
f01043b4:	6b c0 74             	imul   $0x74,%eax,%eax
f01043b7:	ff b0 28 90 23 f0    	pushl  -0xfdc6fd8(%eax)
f01043bd:	e8 8d f3 ff ff       	call   f010374f <env_run>

f01043c2 <DIVIDE>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(DIVIDE,T_DIVIDE)
f01043c2:	6a 00                	push   $0x0
f01043c4:	6a 00                	push   $0x0
f01043c6:	eb 67                	jmp    f010442f <_alltraps>

f01043c8 <DEBUG>:
TRAPHANDLER_NOEC(DEBUG,T_DEBUG)
f01043c8:	6a 00                	push   $0x0
f01043ca:	6a 01                	push   $0x1
f01043cc:	eb 61                	jmp    f010442f <_alltraps>

f01043ce <NMI>:
TRAPHANDLER_NOEC(NMI, T_NMI)
f01043ce:	6a 00                	push   $0x0
f01043d0:	6a 02                	push   $0x2
f01043d2:	eb 5b                	jmp    f010442f <_alltraps>

f01043d4 <BRKPT>:
TRAPHANDLER_NOEC(BRKPT, T_BRKPT)
f01043d4:	6a 00                	push   $0x0
f01043d6:	6a 03                	push   $0x3
f01043d8:	eb 55                	jmp    f010442f <_alltraps>

f01043da <OFLOW>:
TRAPHANDLER_NOEC(OFLOW, T_OFLOW)
f01043da:	6a 00                	push   $0x0
f01043dc:	6a 04                	push   $0x4
f01043de:	eb 4f                	jmp    f010442f <_alltraps>

f01043e0 <BOUND>:
TRAPHANDLER_NOEC(BOUND, T_BOUND)
f01043e0:	6a 00                	push   $0x0
f01043e2:	6a 05                	push   $0x5
f01043e4:	eb 49                	jmp    f010442f <_alltraps>

f01043e6 <ILLOP>:
TRAPHANDLER_NOEC(ILLOP, T_ILLOP)
f01043e6:	6a 00                	push   $0x0
f01043e8:	6a 06                	push   $0x6
f01043ea:	eb 43                	jmp    f010442f <_alltraps>

f01043ec <DEVICE>:
TRAPHANDLER_NOEC(DEVICE, T_DEVICE)
f01043ec:	6a 00                	push   $0x0
f01043ee:	6a 07                	push   $0x7
f01043f0:	eb 3d                	jmp    f010442f <_alltraps>

f01043f2 <DBLFLT>:
TRAPHANDLER(DBLFLT, T_DBLFLT)
f01043f2:	6a 08                	push   $0x8
f01043f4:	eb 39                	jmp    f010442f <_alltraps>

f01043f6 <TSS>:
TRAPHANDLER(TSS, T_TSS)
f01043f6:	6a 0a                	push   $0xa
f01043f8:	eb 35                	jmp    f010442f <_alltraps>

f01043fa <SEGNP>:
TRAPHANDLER(SEGNP, T_SEGNP)
f01043fa:	6a 0b                	push   $0xb
f01043fc:	eb 31                	jmp    f010442f <_alltraps>

f01043fe <STACK>:
TRAPHANDLER(STACK, T_STACK)
f01043fe:	6a 0c                	push   $0xc
f0104400:	eb 2d                	jmp    f010442f <_alltraps>

f0104402 <GPFLT>:
TRAPHANDLER(GPFLT, T_GPFLT)
f0104402:	6a 0d                	push   $0xd
f0104404:	eb 29                	jmp    f010442f <_alltraps>

f0104406 <PGFLT>:
TRAPHANDLER(PGFLT, T_PGFLT)
f0104406:	6a 0e                	push   $0xe
f0104408:	eb 25                	jmp    f010442f <_alltraps>

f010440a <FPERR>:
TRAPHANDLER_NOEC(FPERR, T_FPERR)
f010440a:	6a 00                	push   $0x0
f010440c:	6a 10                	push   $0x10
f010440e:	eb 1f                	jmp    f010442f <_alltraps>

f0104410 <ALIGN>:
TRAPHANDLER(ALIGN, T_ALIGN)
f0104410:	6a 11                	push   $0x11
f0104412:	eb 1b                	jmp    f010442f <_alltraps>

f0104414 <MCHK>:
TRAPHANDLER_NOEC(MCHK, T_MCHK)
f0104414:	6a 00                	push   $0x0
f0104416:	6a 12                	push   $0x12
f0104418:	eb 15                	jmp    f010442f <_alltraps>

f010441a <SIMDERR>:
TRAPHANDLER_NOEC(SIMDERR, T_SIMDERR)
f010441a:	6a 00                	push   $0x0
f010441c:	6a 13                	push   $0x13
f010441e:	eb 0f                	jmp    f010442f <_alltraps>

f0104420 <SYSCALL>:
TRAPHANDLER_NOEC(SYSCALL, T_SYSCALL)
f0104420:	6a 00                	push   $0x0
f0104422:	6a 30                	push   $0x30
f0104424:	eb 09                	jmp    f010442f <_alltraps>

f0104426 <DEFAULT>:
TRAPHANDLER_NOEC(DEFAULT, T_DEFAULT)
f0104426:	6a 00                	push   $0x0
f0104428:	68 f4 01 00 00       	push   $0x1f4
f010442d:	eb 00                	jmp    f010442f <_alltraps>

f010442f <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */
 .global _alltraps
 _alltraps:
 /* code below according to the guide */
pushl %ds
f010442f:	1e                   	push   %ds
pushl %es
f0104430:	06                   	push   %es
pushal
f0104431:	60                   	pusha  
movw $GD_KD, %ax
f0104432:	66 b8 10 00          	mov    $0x10,%ax
movw %ax, %ds
f0104436:	8e d8                	mov    %eax,%ds
movw %ax, %es
f0104438:	8e c0                	mov    %eax,%es
pushl %esp
f010443a:	54                   	push   %esp
call trap
f010443b:	e8 46 fd ff ff       	call   f0104186 <trap>

f0104440 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104440:	f3 0f 1e fb          	endbr32 
f0104444:	55                   	push   %ebp
f0104445:	89 e5                	mov    %esp,%ebp
f0104447:	83 ec 08             	sub    $0x8,%esp
f010444a:	a1 48 82 23 f0       	mov    0xf0238248,%eax
f010444f:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104452:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f0104457:	8b 02                	mov    (%edx),%eax
f0104459:	83 e8 01             	sub    $0x1,%eax
		if ((envs[i].env_status == ENV_RUNNABLE ||
f010445c:	83 f8 02             	cmp    $0x2,%eax
f010445f:	76 2d                	jbe    f010448e <sched_halt+0x4e>
	for (i = 0; i < NENV; i++) {
f0104461:	83 c1 01             	add    $0x1,%ecx
f0104464:	83 c2 7c             	add    $0x7c,%edx
f0104467:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f010446d:	75 e8                	jne    f0104457 <sched_halt+0x17>
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
		cprintf("No runnable environments in the system!\n");
f010446f:	83 ec 0c             	sub    $0xc,%esp
f0104472:	68 90 7a 10 f0       	push   $0xf0107a90
f0104477:	e8 51 f5 ff ff       	call   f01039cd <cprintf>
f010447c:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f010447f:	83 ec 0c             	sub    $0xc,%esp
f0104482:	6a 00                	push   $0x0
f0104484:	e8 eb c4 ff ff       	call   f0100974 <monitor>
f0104489:	83 c4 10             	add    $0x10,%esp
f010448c:	eb f1                	jmp    f010447f <sched_halt+0x3f>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f010448e:	e8 d3 17 00 00       	call   f0105c66 <cpunum>
f0104493:	6b c0 74             	imul   $0x74,%eax,%eax
f0104496:	c7 80 28 90 23 f0 00 	movl   $0x0,-0xfdc6fd8(%eax)
f010449d:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f01044a0:	a1 8c 8e 23 f0       	mov    0xf0238e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01044a5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01044aa:	76 4f                	jbe    f01044fb <sched_halt+0xbb>
	return (physaddr_t)kva - KERNBASE;
f01044ac:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01044b1:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f01044b4:	e8 ad 17 00 00       	call   f0105c66 <cpunum>
f01044b9:	6b d0 74             	imul   $0x74,%eax,%edx
f01044bc:	83 c2 04             	add    $0x4,%edx
	asm volatile("lock; xchgl %0, %1"
f01044bf:	b8 02 00 00 00       	mov    $0x2,%eax
f01044c4:	f0 87 82 20 90 23 f0 	lock xchg %eax,-0xfdc6fe0(%edx)
	spin_unlock(&kernel_lock);
f01044cb:	83 ec 0c             	sub    $0xc,%esp
f01044ce:	68 c0 33 12 f0       	push   $0xf01233c0
f01044d3:	e8 b4 1a 00 00       	call   f0105f8c <spin_unlock>
	asm volatile("pause");
f01044d8:	f3 90                	pause  
		// Uncomment the following line after completing exercise 13
		//"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f01044da:	e8 87 17 00 00       	call   f0105c66 <cpunum>
f01044df:	6b c0 74             	imul   $0x74,%eax,%eax
	asm volatile (
f01044e2:	8b 80 30 90 23 f0    	mov    -0xfdc6fd0(%eax),%eax
f01044e8:	bd 00 00 00 00       	mov    $0x0,%ebp
f01044ed:	89 c4                	mov    %eax,%esp
f01044ef:	6a 00                	push   $0x0
f01044f1:	6a 00                	push   $0x0
f01044f3:	f4                   	hlt    
f01044f4:	eb fd                	jmp    f01044f3 <sched_halt+0xb3>
}
f01044f6:	83 c4 10             	add    $0x10,%esp
f01044f9:	c9                   	leave  
f01044fa:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01044fb:	50                   	push   %eax
f01044fc:	68 28 63 10 f0       	push   $0xf0106328
f0104501:	6a 55                	push   $0x55
f0104503:	68 b9 7a 10 f0       	push   $0xf0107ab9
f0104508:	e8 33 bb ff ff       	call   f0100040 <_panic>

f010450d <sched_yield>:
{
f010450d:	f3 0f 1e fb          	endbr32 
f0104511:	55                   	push   %ebp
f0104512:	89 e5                	mov    %esp,%ebp
f0104514:	56                   	push   %esi
f0104515:	53                   	push   %ebx
	if(curenv)
f0104516:	e8 4b 17 00 00       	call   f0105c66 <cpunum>
f010451b:	6b c0 74             	imul   $0x74,%eax,%eax
	int begin = 0;
f010451e:	b9 00 00 00 00       	mov    $0x0,%ecx
	if(curenv)
f0104523:	83 b8 28 90 23 f0 00 	cmpl   $0x0,-0xfdc6fd8(%eax)
f010452a:	74 17                	je     f0104543 <sched_yield+0x36>
		begin = ENVX(curenv->env_id);
f010452c:	e8 35 17 00 00       	call   f0105c66 <cpunum>
f0104531:	6b c0 74             	imul   $0x74,%eax,%eax
f0104534:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f010453a:	8b 48 48             	mov    0x48(%eax),%ecx
f010453d:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
		idle = &envs[(i+begin)%NENV];
f0104543:	8b 1d 48 82 23 f0    	mov    0xf0238248,%ebx
f0104549:	89 ca                	mov    %ecx,%edx
f010454b:	81 c1 00 04 00 00    	add    $0x400,%ecx
f0104551:	89 d6                	mov    %edx,%esi
f0104553:	c1 fe 1f             	sar    $0x1f,%esi
f0104556:	c1 ee 16             	shr    $0x16,%esi
f0104559:	8d 04 32             	lea    (%edx,%esi,1),%eax
f010455c:	25 ff 03 00 00       	and    $0x3ff,%eax
f0104561:	29 f0                	sub    %esi,%eax
f0104563:	6b c0 7c             	imul   $0x7c,%eax,%eax
f0104566:	01 d8                	add    %ebx,%eax
		if(idle->env_status == ENV_RUNNABLE)
f0104568:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f010456c:	74 38                	je     f01045a6 <sched_yield+0x99>
f010456e:	83 c2 01             	add    $0x1,%edx
	for(int i = 0;i<NENV;i++)
f0104571:	39 ca                	cmp    %ecx,%edx
f0104573:	75 dc                	jne    f0104551 <sched_yield+0x44>
	if(!flag && curenv && curenv->env_status == ENV_RUNNING)
f0104575:	e8 ec 16 00 00       	call   f0105c66 <cpunum>
f010457a:	6b c0 74             	imul   $0x74,%eax,%eax
f010457d:	83 b8 28 90 23 f0 00 	cmpl   $0x0,-0xfdc6fd8(%eax)
f0104584:	74 14                	je     f010459a <sched_yield+0x8d>
f0104586:	e8 db 16 00 00       	call   f0105c66 <cpunum>
f010458b:	6b c0 74             	imul   $0x74,%eax,%eax
f010458e:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f0104594:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104598:	74 15                	je     f01045af <sched_yield+0xa2>
		sched_halt();
f010459a:	e8 a1 fe ff ff       	call   f0104440 <sched_halt>
}
f010459f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01045a2:	5b                   	pop    %ebx
f01045a3:	5e                   	pop    %esi
f01045a4:	5d                   	pop    %ebp
f01045a5:	c3                   	ret    
			env_run(idle);
f01045a6:	83 ec 0c             	sub    $0xc,%esp
f01045a9:	50                   	push   %eax
f01045aa:	e8 a0 f1 ff ff       	call   f010374f <env_run>
		env_run(curenv);
f01045af:	e8 b2 16 00 00       	call   f0105c66 <cpunum>
f01045b4:	83 ec 0c             	sub    $0xc,%esp
f01045b7:	6b c0 74             	imul   $0x74,%eax,%eax
f01045ba:	ff b0 28 90 23 f0    	pushl  -0xfdc6fd8(%eax)
f01045c0:	e8 8a f1 ff ff       	call   f010374f <env_run>

f01045c5 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01045c5:	f3 0f 1e fb          	endbr32 
f01045c9:	55                   	push   %ebp
f01045ca:	89 e5                	mov    %esp,%ebp
f01045cc:	57                   	push   %edi
f01045cd:	56                   	push   %esi
f01045ce:	53                   	push   %ebx
f01045cf:	83 ec 1c             	sub    $0x1c,%esp
f01045d2:	8b 45 08             	mov    0x8(%ebp),%eax
f01045d5:	83 f8 0d             	cmp    $0xd,%eax
f01045d8:	77 08                	ja     f01045e2 <syscall+0x1d>
f01045da:	3e ff 24 85 00 7b 10 	notrack jmp *-0xfef8500(,%eax,4)
f01045e1:	f0 
		{
			return sys_env_destroy((envid_t)a1);
		}
		case NSYSCALLS:
		{
			return 0;
f01045e2:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
			return sys_env_set_pgfault_upcall((envid_t)a1,(void*)a2);
		}
		default:
			return -E_INVAL;
	}
}
f01045e7:	89 d8                	mov    %ebx,%eax
f01045e9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01045ec:	5b                   	pop    %ebx
f01045ed:	5e                   	pop    %esi
f01045ee:	5f                   	pop    %edi
f01045ef:	5d                   	pop    %ebp
f01045f0:	c3                   	ret    
	user_mem_assert(curenv,s,len,0);
f01045f1:	e8 70 16 00 00       	call   f0105c66 <cpunum>
f01045f6:	6a 00                	push   $0x0
f01045f8:	ff 75 10             	pushl  0x10(%ebp)
f01045fb:	ff 75 0c             	pushl  0xc(%ebp)
f01045fe:	6b c0 74             	imul   $0x74,%eax,%eax
f0104601:	ff b0 28 90 23 f0    	pushl  -0xfdc6fd8(%eax)
f0104607:	e8 ad e9 ff ff       	call   f0102fb9 <user_mem_assert>
	cprintf("%.*s", len, s);
f010460c:	83 c4 0c             	add    $0xc,%esp
f010460f:	ff 75 0c             	pushl  0xc(%ebp)
f0104612:	ff 75 10             	pushl  0x10(%ebp)
f0104615:	68 c6 7a 10 f0       	push   $0xf0107ac6
f010461a:	e8 ae f3 ff ff       	call   f01039cd <cprintf>
}
f010461f:	83 c4 10             	add    $0x10,%esp
			return 0;
f0104622:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0104627:	eb be                	jmp    f01045e7 <syscall+0x22>
	return cons_getc();
f0104629:	e8 e6 bf ff ff       	call   f0100614 <cons_getc>
f010462e:	89 c3                	mov    %eax,%ebx
			return sys_cgetc();
f0104630:	eb b5                	jmp    f01045e7 <syscall+0x22>
	if ((r = envid2env(envid, &e, 1)) < 0)
f0104632:	83 ec 04             	sub    $0x4,%esp
f0104635:	6a 01                	push   $0x1
f0104637:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010463a:	50                   	push   %eax
f010463b:	ff 75 0c             	pushl  0xc(%ebp)
f010463e:	e8 67 ea ff ff       	call   f01030aa <envid2env>
f0104643:	89 c3                	mov    %eax,%ebx
f0104645:	83 c4 10             	add    $0x10,%esp
f0104648:	85 c0                	test   %eax,%eax
f010464a:	78 9b                	js     f01045e7 <syscall+0x22>
	if (e == curenv)
f010464c:	e8 15 16 00 00       	call   f0105c66 <cpunum>
f0104651:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104654:	6b c0 74             	imul   $0x74,%eax,%eax
f0104657:	39 90 28 90 23 f0    	cmp    %edx,-0xfdc6fd8(%eax)
f010465d:	74 3d                	je     f010469c <syscall+0xd7>
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010465f:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104662:	e8 ff 15 00 00       	call   f0105c66 <cpunum>
f0104667:	83 ec 04             	sub    $0x4,%esp
f010466a:	53                   	push   %ebx
f010466b:	6b c0 74             	imul   $0x74,%eax,%eax
f010466e:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f0104674:	ff 70 48             	pushl  0x48(%eax)
f0104677:	68 e6 7a 10 f0       	push   $0xf0107ae6
f010467c:	e8 4c f3 ff ff       	call   f01039cd <cprintf>
f0104681:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0104684:	83 ec 0c             	sub    $0xc,%esp
f0104687:	ff 75 e4             	pushl  -0x1c(%ebp)
f010468a:	e8 19 f0 ff ff       	call   f01036a8 <env_destroy>
	return 0;
f010468f:	83 c4 10             	add    $0x10,%esp
f0104692:	bb 00 00 00 00       	mov    $0x0,%ebx
			return sys_env_destroy((envid_t)a1);
f0104697:	e9 4b ff ff ff       	jmp    f01045e7 <syscall+0x22>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f010469c:	e8 c5 15 00 00       	call   f0105c66 <cpunum>
f01046a1:	83 ec 08             	sub    $0x8,%esp
f01046a4:	6b c0 74             	imul   $0x74,%eax,%eax
f01046a7:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f01046ad:	ff 70 48             	pushl  0x48(%eax)
f01046b0:	68 cb 7a 10 f0       	push   $0xf0107acb
f01046b5:	e8 13 f3 ff ff       	call   f01039cd <cprintf>
f01046ba:	83 c4 10             	add    $0x10,%esp
f01046bd:	eb c5                	jmp    f0104684 <syscall+0xbf>
	return curenv->env_id;
f01046bf:	e8 a2 15 00 00       	call   f0105c66 <cpunum>
f01046c4:	6b c0 74             	imul   $0x74,%eax,%eax
f01046c7:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f01046cd:	8b 58 48             	mov    0x48(%eax),%ebx
			return sys_getenvid();
f01046d0:	e9 12 ff ff ff       	jmp    f01045e7 <syscall+0x22>
	sched_yield();
f01046d5:	e8 33 fe ff ff       	call   f010450d <sched_yield>
	struct Env* store_env = NULL;
f01046da:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = env_alloc(&store_env,curenv->env_id);
f01046e1:	e8 80 15 00 00       	call   f0105c66 <cpunum>
f01046e6:	83 ec 08             	sub    $0x8,%esp
f01046e9:	6b c0 74             	imul   $0x74,%eax,%eax
f01046ec:	8b 80 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%eax
f01046f2:	ff 70 48             	pushl  0x48(%eax)
f01046f5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01046f8:	50                   	push   %eax
f01046f9:	e8 c1 ea ff ff       	call   f01031bf <env_alloc>
f01046fe:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104700:	83 c4 10             	add    $0x10,%esp
f0104703:	85 c0                	test   %eax,%eax
f0104705:	0f 88 dc fe ff ff    	js     f01045e7 <syscall+0x22>
	store_env->env_status = ENV_NOT_RUNNABLE;
f010470b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010470e:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	store_env->env_tf = curenv->env_tf;
f0104715:	e8 4c 15 00 00       	call   f0105c66 <cpunum>
f010471a:	6b c0 74             	imul   $0x74,%eax,%eax
f010471d:	8b b0 28 90 23 f0    	mov    -0xfdc6fd8(%eax),%esi
f0104723:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104728:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010472b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	store_env->env_tf.tf_regs.reg_eax = 0;
f010472d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104730:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return store_env->env_id;
f0104737:	8b 58 48             	mov    0x48(%eax),%ebx
			return sys_exofork();
f010473a:	e9 a8 fe ff ff       	jmp    f01045e7 <syscall+0x22>
	if(status != ENV_NOT_RUNNABLE && status!= ENV_RUNNABLE)
f010473f:	8b 45 10             	mov    0x10(%ebp),%eax
f0104742:	83 e8 02             	sub    $0x2,%eax
f0104745:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f010474a:	75 38                	jne    f0104784 <syscall+0x1bf>
	struct Env* e = NULL;
f010474c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f0104753:	83 ec 04             	sub    $0x4,%esp
f0104756:	6a 01                	push   $0x1
f0104758:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010475b:	50                   	push   %eax
f010475c:	ff 75 0c             	pushl  0xc(%ebp)
f010475f:	e8 46 e9 ff ff       	call   f01030aa <envid2env>
f0104764:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104766:	83 c4 10             	add    $0x10,%esp
f0104769:	85 c0                	test   %eax,%eax
f010476b:	0f 88 76 fe ff ff    	js     f01045e7 <syscall+0x22>
	e->env_status = status;
f0104771:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104774:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104777:	89 78 54             	mov    %edi,0x54(%eax)
	return 0;
f010477a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010477f:	e9 63 fe ff ff       	jmp    f01045e7 <syscall+0x22>
		return -E_INVAL;
f0104784:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
			return sys_env_set_status((envid_t)a1,(int)a2);
f0104789:	e9 59 fe ff ff       	jmp    f01045e7 <syscall+0x22>
	if((uintptr_t)va >= UTOP || (uintptr_t)va % PGSIZE)
f010478e:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104795:	0f 87 84 00 00 00    	ja     f010481f <syscall+0x25a>
	if((perm & ~(PTE_SYSCALL)) || ((perm & needed_perm) != needed_perm))
f010479b:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010479e:	81 e3 f8 f1 ff ff    	and    $0xfffff1f8,%ebx
	if((uintptr_t)va >= UTOP || (uintptr_t)va % PGSIZE)
f01047a4:	8b 45 10             	mov    0x10(%ebp),%eax
f01047a7:	25 ff 0f 00 00       	and    $0xfff,%eax
	if((perm & ~(PTE_SYSCALL)) || ((perm & needed_perm) != needed_perm))
f01047ac:	09 c3                	or     %eax,%ebx
f01047ae:	75 79                	jne    f0104829 <syscall+0x264>
f01047b0:	8b 45 14             	mov    0x14(%ebp),%eax
f01047b3:	83 e0 05             	and    $0x5,%eax
f01047b6:	83 f8 05             	cmp    $0x5,%eax
f01047b9:	75 78                	jne    f0104833 <syscall+0x26e>
	struct Env* e = NULL;
f01047bb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f01047c2:	83 ec 04             	sub    $0x4,%esp
f01047c5:	6a 01                	push   $0x1
f01047c7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01047ca:	50                   	push   %eax
f01047cb:	ff 75 0c             	pushl  0xc(%ebp)
f01047ce:	e8 d7 e8 ff ff       	call   f01030aa <envid2env>
	if(ret<0)
f01047d3:	83 c4 10             	add    $0x10,%esp
f01047d6:	85 c0                	test   %eax,%eax
f01047d8:	78 63                	js     f010483d <syscall+0x278>
	struct PageInfo* pg = page_alloc(ALLOC_ZERO);
f01047da:	83 ec 0c             	sub    $0xc,%esp
f01047dd:	6a 01                	push   $0x1
f01047df:	e8 96 c7 ff ff       	call   f0100f7a <page_alloc>
f01047e4:	89 c6                	mov    %eax,%esi
	if(!pg)
f01047e6:	83 c4 10             	add    $0x10,%esp
f01047e9:	85 c0                	test   %eax,%eax
f01047eb:	74 57                	je     f0104844 <syscall+0x27f>
	ret = page_insert(e->env_pgdir,pg,va,perm);
f01047ed:	ff 75 14             	pushl  0x14(%ebp)
f01047f0:	ff 75 10             	pushl  0x10(%ebp)
f01047f3:	50                   	push   %eax
f01047f4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01047f7:	ff 70 60             	pushl  0x60(%eax)
f01047fa:	e8 30 ca ff ff       	call   f010122f <page_insert>
f01047ff:	89 c7                	mov    %eax,%edi
	if(ret < 0)
f0104801:	83 c4 10             	add    $0x10,%esp
f0104804:	85 c0                	test   %eax,%eax
f0104806:	0f 89 db fd ff ff    	jns    f01045e7 <syscall+0x22>
		page_free(pg);
f010480c:	83 ec 0c             	sub    $0xc,%esp
f010480f:	56                   	push   %esi
f0104810:	e8 de c7 ff ff       	call   f0100ff3 <page_free>
		return ret;
f0104815:	83 c4 10             	add    $0x10,%esp
f0104818:	89 fb                	mov    %edi,%ebx
f010481a:	e9 c8 fd ff ff       	jmp    f01045e7 <syscall+0x22>
		return -E_INVAL;
f010481f:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104824:	e9 be fd ff ff       	jmp    f01045e7 <syscall+0x22>
		return -E_INVAL;
f0104829:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010482e:	e9 b4 fd ff ff       	jmp    f01045e7 <syscall+0x22>
f0104833:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104838:	e9 aa fd ff ff       	jmp    f01045e7 <syscall+0x22>
		return ret;
f010483d:	89 c3                	mov    %eax,%ebx
f010483f:	e9 a3 fd ff ff       	jmp    f01045e7 <syscall+0x22>
		return -E_NO_MEM;
f0104844:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
			return sys_page_alloc((envid_t)a1,(void*)a2,(int)a3);
f0104849:	e9 99 fd ff ff       	jmp    f01045e7 <syscall+0x22>
	if((uintptr_t)srcva>=UTOP || (uintptr_t)srcva % PGSIZE 
f010484e:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104855:	0f 87 d7 00 00 00    	ja     f0104932 <syscall+0x36d>
	|| (uintptr_t)dstva>=UTOP || (uintptr_t)dstva % PGSIZE)
f010485b:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104862:	0f 87 d4 00 00 00    	ja     f010493c <syscall+0x377>
	if((perm & ~(PTE_SYSCALL)) || ((perm & needed_perm) != needed_perm))
f0104868:	8b 45 10             	mov    0x10(%ebp),%eax
f010486b:	0b 45 18             	or     0x18(%ebp),%eax
f010486e:	25 ff 0f 00 00       	and    $0xfff,%eax
f0104873:	8b 55 1c             	mov    0x1c(%ebp),%edx
f0104876:	81 e2 f8 f1 ff ff    	and    $0xfffff1f8,%edx
f010487c:	09 d0                	or     %edx,%eax
f010487e:	0f 85 c2 00 00 00    	jne    f0104946 <syscall+0x381>
f0104884:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0104887:	83 e0 05             	and    $0x5,%eax
f010488a:	83 f8 05             	cmp    $0x5,%eax
f010488d:	0f 85 bd 00 00 00    	jne    f0104950 <syscall+0x38b>
	struct Env* srce = NULL, *dste = NULL;
f0104893:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f010489a:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	int ret = envid2env(srcenvid,&srce,true);
f01048a1:	83 ec 04             	sub    $0x4,%esp
f01048a4:	6a 01                	push   $0x1
f01048a6:	8d 45 dc             	lea    -0x24(%ebp),%eax
f01048a9:	50                   	push   %eax
f01048aa:	ff 75 0c             	pushl  0xc(%ebp)
f01048ad:	e8 f8 e7 ff ff       	call   f01030aa <envid2env>
f01048b2:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f01048b4:	83 c4 10             	add    $0x10,%esp
f01048b7:	85 c0                	test   %eax,%eax
f01048b9:	0f 88 28 fd ff ff    	js     f01045e7 <syscall+0x22>
	ret = envid2env(dstenvid,&dste,true);
f01048bf:	83 ec 04             	sub    $0x4,%esp
f01048c2:	6a 01                	push   $0x1
f01048c4:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01048c7:	50                   	push   %eax
f01048c8:	ff 75 14             	pushl  0x14(%ebp)
f01048cb:	e8 da e7 ff ff       	call   f01030aa <envid2env>
f01048d0:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f01048d2:	83 c4 10             	add    $0x10,%esp
f01048d5:	85 c0                	test   %eax,%eax
f01048d7:	0f 88 0a fd ff ff    	js     f01045e7 <syscall+0x22>
	pte_t* pte = NULL;
f01048dd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	struct PageInfo* pg = page_lookup(srce->env_pgdir,srcva,&pte);
f01048e4:	83 ec 04             	sub    $0x4,%esp
f01048e7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01048ea:	50                   	push   %eax
f01048eb:	ff 75 10             	pushl  0x10(%ebp)
f01048ee:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01048f1:	ff 70 60             	pushl  0x60(%eax)
f01048f4:	e8 43 c8 ff ff       	call   f010113c <page_lookup>
	if(!pg)
f01048f9:	83 c4 10             	add    $0x10,%esp
f01048fc:	85 c0                	test   %eax,%eax
f01048fe:	74 5a                	je     f010495a <syscall+0x395>
	if((!((*pte) & PTE_W)) && (perm & PTE_W))
f0104900:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104903:	f6 02 02             	testb  $0x2,(%edx)
f0104906:	75 06                	jne    f010490e <syscall+0x349>
f0104908:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f010490c:	75 56                	jne    f0104964 <syscall+0x39f>
	ret = page_insert(dste->env_pgdir,pg,dstva,perm);
f010490e:	ff 75 1c             	pushl  0x1c(%ebp)
f0104911:	ff 75 18             	pushl  0x18(%ebp)
f0104914:	50                   	push   %eax
f0104915:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104918:	ff 70 60             	pushl  0x60(%eax)
f010491b:	e8 0f c9 ff ff       	call   f010122f <page_insert>
f0104920:	83 c4 10             	add    $0x10,%esp
f0104923:	85 c0                	test   %eax,%eax
f0104925:	bb 00 00 00 00       	mov    $0x0,%ebx
f010492a:	0f 4e d8             	cmovle %eax,%ebx
f010492d:	e9 b5 fc ff ff       	jmp    f01045e7 <syscall+0x22>
		return -E_INVAL;
f0104932:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104937:	e9 ab fc ff ff       	jmp    f01045e7 <syscall+0x22>
f010493c:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104941:	e9 a1 fc ff ff       	jmp    f01045e7 <syscall+0x22>
		return -E_INVAL;
f0104946:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010494b:	e9 97 fc ff ff       	jmp    f01045e7 <syscall+0x22>
f0104950:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104955:	e9 8d fc ff ff       	jmp    f01045e7 <syscall+0x22>
		return -E_INVAL;
f010495a:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010495f:	e9 83 fc ff ff       	jmp    f01045e7 <syscall+0x22>
		return -E_INVAL;
f0104964:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
			return sys_page_map((envid_t)a1,(void*)a2,(envid_t)a3,(void*)a4,(int)a5);
f0104969:	e9 79 fc ff ff       	jmp    f01045e7 <syscall+0x22>
	if((uintptr_t)va >= UTOP || (uintptr_t)va % PGSIZE)
f010496e:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104975:	77 4c                	ja     f01049c3 <syscall+0x3fe>
f0104977:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f010497e:	75 4d                	jne    f01049cd <syscall+0x408>
	struct Env* e = NULL;
f0104980:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f0104987:	83 ec 04             	sub    $0x4,%esp
f010498a:	6a 01                	push   $0x1
f010498c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010498f:	50                   	push   %eax
f0104990:	ff 75 0c             	pushl  0xc(%ebp)
f0104993:	e8 12 e7 ff ff       	call   f01030aa <envid2env>
f0104998:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f010499a:	83 c4 10             	add    $0x10,%esp
f010499d:	85 c0                	test   %eax,%eax
f010499f:	0f 88 42 fc ff ff    	js     f01045e7 <syscall+0x22>
	page_remove(e->env_pgdir,va);
f01049a5:	83 ec 08             	sub    $0x8,%esp
f01049a8:	ff 75 10             	pushl  0x10(%ebp)
f01049ab:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01049ae:	ff 70 60             	pushl  0x60(%eax)
f01049b1:	e8 28 c8 ff ff       	call   f01011de <page_remove>
	return 0;
f01049b6:	83 c4 10             	add    $0x10,%esp
f01049b9:	bb 00 00 00 00       	mov    $0x0,%ebx
f01049be:	e9 24 fc ff ff       	jmp    f01045e7 <syscall+0x22>
		return -E_INVAL;
f01049c3:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01049c8:	e9 1a fc ff ff       	jmp    f01045e7 <syscall+0x22>
f01049cd:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
			return sys_page_unmap((envid_t)a1,(void*)a2);
f01049d2:	e9 10 fc ff ff       	jmp    f01045e7 <syscall+0x22>
	struct Env* e = NULL;
f01049d7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f01049de:	83 ec 04             	sub    $0x4,%esp
f01049e1:	6a 01                	push   $0x1
f01049e3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01049e6:	50                   	push   %eax
f01049e7:	ff 75 0c             	pushl  0xc(%ebp)
f01049ea:	e8 bb e6 ff ff       	call   f01030aa <envid2env>
f01049ef:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f01049f1:	83 c4 10             	add    $0x10,%esp
f01049f4:	85 c0                	test   %eax,%eax
f01049f6:	0f 88 eb fb ff ff    	js     f01045e7 <syscall+0x22>
	e->env_pgfault_upcall = func;
f01049fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01049ff:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104a02:	89 48 64             	mov    %ecx,0x64(%eax)
	return 0;
f0104a05:	bb 00 00 00 00       	mov    $0x0,%ebx
			return sys_env_set_pgfault_upcall((envid_t)a1,(void*)a2);
f0104a0a:	e9 d8 fb ff ff       	jmp    f01045e7 <syscall+0x22>
			return 0;
f0104a0f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104a14:	e9 ce fb ff ff       	jmp    f01045e7 <syscall+0x22>

f0104a19 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104a19:	55                   	push   %ebp
f0104a1a:	89 e5                	mov    %esp,%ebp
f0104a1c:	57                   	push   %edi
f0104a1d:	56                   	push   %esi
f0104a1e:	53                   	push   %ebx
f0104a1f:	83 ec 14             	sub    $0x14,%esp
f0104a22:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104a25:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104a28:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104a2b:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104a2e:	8b 1a                	mov    (%edx),%ebx
f0104a30:	8b 01                	mov    (%ecx),%eax
f0104a32:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104a35:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104a3c:	eb 23                	jmp    f0104a61 <stab_binsearch+0x48>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104a3e:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0104a41:	eb 1e                	jmp    f0104a61 <stab_binsearch+0x48>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104a43:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104a46:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104a49:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104a4d:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104a50:	73 46                	jae    f0104a98 <stab_binsearch+0x7f>
			*region_left = m;
f0104a52:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104a55:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104a57:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f0104a5a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0104a61:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104a64:	7f 5f                	jg     f0104ac5 <stab_binsearch+0xac>
		int true_m = (l + r) / 2, m = true_m;
f0104a66:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104a69:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f0104a6c:	89 d0                	mov    %edx,%eax
f0104a6e:	c1 e8 1f             	shr    $0x1f,%eax
f0104a71:	01 d0                	add    %edx,%eax
f0104a73:	89 c7                	mov    %eax,%edi
f0104a75:	d1 ff                	sar    %edi
f0104a77:	83 e0 fe             	and    $0xfffffffe,%eax
f0104a7a:	01 f8                	add    %edi,%eax
f0104a7c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104a7f:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0104a83:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f0104a85:	39 c3                	cmp    %eax,%ebx
f0104a87:	7f b5                	jg     f0104a3e <stab_binsearch+0x25>
f0104a89:	0f b6 0a             	movzbl (%edx),%ecx
f0104a8c:	83 ea 0c             	sub    $0xc,%edx
f0104a8f:	39 f1                	cmp    %esi,%ecx
f0104a91:	74 b0                	je     f0104a43 <stab_binsearch+0x2a>
			m--;
f0104a93:	83 e8 01             	sub    $0x1,%eax
f0104a96:	eb ed                	jmp    f0104a85 <stab_binsearch+0x6c>
		} else if (stabs[m].n_value > addr) {
f0104a98:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104a9b:	76 14                	jbe    f0104ab1 <stab_binsearch+0x98>
			*region_right = m - 1;
f0104a9d:	83 e8 01             	sub    $0x1,%eax
f0104aa0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104aa3:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104aa6:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f0104aa8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104aaf:	eb b0                	jmp    f0104a61 <stab_binsearch+0x48>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104ab1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104ab4:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0104ab6:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104aba:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f0104abc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104ac3:	eb 9c                	jmp    f0104a61 <stab_binsearch+0x48>
		}
	}

	if (!any_matches)
f0104ac5:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104ac9:	75 15                	jne    f0104ae0 <stab_binsearch+0xc7>
		*region_right = *region_left - 1;
f0104acb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104ace:	8b 00                	mov    (%eax),%eax
f0104ad0:	83 e8 01             	sub    $0x1,%eax
f0104ad3:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104ad6:	89 07                	mov    %eax,(%edi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0104ad8:	83 c4 14             	add    $0x14,%esp
f0104adb:	5b                   	pop    %ebx
f0104adc:	5e                   	pop    %esi
f0104add:	5f                   	pop    %edi
f0104ade:	5d                   	pop    %ebp
f0104adf:	c3                   	ret    
		for (l = *region_right;
f0104ae0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104ae3:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104ae5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104ae8:	8b 0f                	mov    (%edi),%ecx
f0104aea:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104aed:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0104af0:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
		for (l = *region_right;
f0104af4:	eb 03                	jmp    f0104af9 <stab_binsearch+0xe0>
		     l--)
f0104af6:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0104af9:	39 c1                	cmp    %eax,%ecx
f0104afb:	7d 0a                	jge    f0104b07 <stab_binsearch+0xee>
		     l > *region_left && stabs[l].n_type != type;
f0104afd:	0f b6 1a             	movzbl (%edx),%ebx
f0104b00:	83 ea 0c             	sub    $0xc,%edx
f0104b03:	39 f3                	cmp    %esi,%ebx
f0104b05:	75 ef                	jne    f0104af6 <stab_binsearch+0xdd>
		*region_left = l;
f0104b07:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104b0a:	89 07                	mov    %eax,(%edi)
}
f0104b0c:	eb ca                	jmp    f0104ad8 <stab_binsearch+0xbf>

f0104b0e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104b0e:	f3 0f 1e fb          	endbr32 
f0104b12:	55                   	push   %ebp
f0104b13:	89 e5                	mov    %esp,%ebp
f0104b15:	57                   	push   %edi
f0104b16:	56                   	push   %esi
f0104b17:	53                   	push   %ebx
f0104b18:	83 ec 4c             	sub    $0x4c,%esp
f0104b1b:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104b1e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104b21:	c7 03 38 7b 10 f0    	movl   $0xf0107b38,(%ebx)
	info->eip_line = 0;
f0104b27:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0104b2e:	c7 43 08 38 7b 10 f0 	movl   $0xf0107b38,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0104b35:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0104b3c:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0104b3f:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104b46:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0104b4c:	0f 86 32 01 00 00    	jbe    f0104c84 <debuginfo_eip+0x176>
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104b52:	c7 45 b4 54 80 11 f0 	movl   $0xf0118054,-0x4c(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0104b59:	c7 45 b8 b5 48 11 f0 	movl   $0xf01148b5,-0x48(%ebp)
		stab_end = __STAB_END__;
f0104b60:	be b4 48 11 f0       	mov    $0xf01148b4,%esi
		stabs = __STAB_BEGIN__;
f0104b65:	c7 45 bc 14 80 10 f0 	movl   $0xf0108014,-0x44(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104b6c:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f0104b6f:	39 4d b8             	cmp    %ecx,-0x48(%ebp)
f0104b72:	0f 83 62 02 00 00    	jae    f0104dda <debuginfo_eip+0x2cc>
f0104b78:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0104b7c:	0f 85 5f 02 00 00    	jne    f0104de1 <debuginfo_eip+0x2d3>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104b82:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104b89:	2b 75 bc             	sub    -0x44(%ebp),%esi
f0104b8c:	c1 fe 02             	sar    $0x2,%esi
f0104b8f:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0104b95:	83 e8 01             	sub    $0x1,%eax
f0104b98:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104b9b:	83 ec 08             	sub    $0x8,%esp
f0104b9e:	57                   	push   %edi
f0104b9f:	6a 64                	push   $0x64
f0104ba1:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0104ba4:	89 d1                	mov    %edx,%ecx
f0104ba6:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104ba9:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0104bac:	89 f0                	mov    %esi,%eax
f0104bae:	e8 66 fe ff ff       	call   f0104a19 <stab_binsearch>
	if (lfile == 0)
f0104bb3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104bb6:	83 c4 10             	add    $0x10,%esp
f0104bb9:	85 c0                	test   %eax,%eax
f0104bbb:	0f 84 27 02 00 00    	je     f0104de8 <debuginfo_eip+0x2da>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104bc1:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104bc4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104bc7:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104bca:	83 ec 08             	sub    $0x8,%esp
f0104bcd:	57                   	push   %edi
f0104bce:	6a 24                	push   $0x24
f0104bd0:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0104bd3:	89 d1                	mov    %edx,%ecx
f0104bd5:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104bd8:	89 f0                	mov    %esi,%eax
f0104bda:	e8 3a fe ff ff       	call   f0104a19 <stab_binsearch>

	if (lfun <= rfun) {
f0104bdf:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104be2:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104be5:	83 c4 10             	add    $0x10,%esp
f0104be8:	39 d0                	cmp    %edx,%eax
f0104bea:	0f 8f 34 01 00 00    	jg     f0104d24 <debuginfo_eip+0x216>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104bf0:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0104bf3:	8d 34 8e             	lea    (%esi,%ecx,4),%esi
f0104bf6:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f0104bf9:	8b 36                	mov    (%esi),%esi
f0104bfb:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f0104bfe:	2b 4d b8             	sub    -0x48(%ebp),%ecx
f0104c01:	39 ce                	cmp    %ecx,%esi
f0104c03:	73 06                	jae    f0104c0b <debuginfo_eip+0xfd>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104c05:	03 75 b8             	add    -0x48(%ebp),%esi
f0104c08:	89 73 08             	mov    %esi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104c0b:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104c0e:	8b 4e 08             	mov    0x8(%esi),%ecx
f0104c11:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0104c14:	29 cf                	sub    %ecx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0104c16:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104c19:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104c1c:	83 ec 08             	sub    $0x8,%esp
f0104c1f:	6a 3a                	push   $0x3a
f0104c21:	ff 73 08             	pushl  0x8(%ebx)
f0104c24:	e8 fe 09 00 00       	call   f0105627 <strfind>
f0104c29:	2b 43 08             	sub    0x8(%ebx),%eax
f0104c2c:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	info->eip_file = stabstr +stabs[lfile].n_strx;
f0104c2f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104c32:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104c35:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0104c38:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0104c3b:	03 0c 86             	add    (%esi,%eax,4),%ecx
f0104c3e:	89 0b                	mov    %ecx,(%ebx)
	stab_binsearch(stabs, &lline, &rline,N_SLINE,addr);
f0104c40:	83 c4 08             	add    $0x8,%esp
f0104c43:	57                   	push   %edi
f0104c44:	6a 44                	push   $0x44
f0104c46:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104c49:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104c4c:	89 f0                	mov    %esi,%eax
f0104c4e:	e8 c6 fd ff ff       	call   f0104a19 <stab_binsearch>
	if(lline>rline)
f0104c53:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0104c56:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104c59:	83 c4 10             	add    $0x10,%esp
f0104c5c:	39 c2                	cmp    %eax,%edx
f0104c5e:	0f 8f 8b 01 00 00    	jg     f0104def <debuginfo_eip+0x2e1>
	{
		return -1;
	}
	else
	{
		info->eip_line = stabs[rline].n_desc;
f0104c64:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104c67:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0104c6c:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104c6f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104c72:	89 d0                	mov    %edx,%eax
f0104c74:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104c77:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
f0104c7b:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0104c7f:	e9 be 00 00 00       	jmp    f0104d42 <debuginfo_eip+0x234>
		if(user_mem_check(curenv,usd,sizeof(struct UserStabData),PTE_P|PTE_U) != 0)
f0104c84:	e8 dd 0f 00 00       	call   f0105c66 <cpunum>
f0104c89:	6a 05                	push   $0x5
f0104c8b:	6a 10                	push   $0x10
f0104c8d:	68 00 00 20 00       	push   $0x200000
f0104c92:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c95:	ff b0 28 90 23 f0    	pushl  -0xfdc6fd8(%eax)
f0104c9b:	e8 8a e2 ff ff       	call   f0102f2a <user_mem_check>
f0104ca0:	83 c4 10             	add    $0x10,%esp
f0104ca3:	85 c0                	test   %eax,%eax
f0104ca5:	0f 85 21 01 00 00    	jne    f0104dcc <debuginfo_eip+0x2be>
		stabs = usd->stabs;
f0104cab:	a1 00 00 20 00       	mov    0x200000,%eax
f0104cb0:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stab_end = usd->stab_end;
f0104cb3:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f0104cb9:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f0104cbf:	89 4d b8             	mov    %ecx,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f0104cc2:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0104cc8:	89 55 b4             	mov    %edx,-0x4c(%ebp)
		if(user_mem_check(curenv,stabs,sizeof(struct Stab),PTE_P|PTE_U) != 0)
f0104ccb:	e8 96 0f 00 00       	call   f0105c66 <cpunum>
f0104cd0:	6a 05                	push   $0x5
f0104cd2:	6a 0c                	push   $0xc
f0104cd4:	ff 75 bc             	pushl  -0x44(%ebp)
f0104cd7:	6b c0 74             	imul   $0x74,%eax,%eax
f0104cda:	ff b0 28 90 23 f0    	pushl  -0xfdc6fd8(%eax)
f0104ce0:	e8 45 e2 ff ff       	call   f0102f2a <user_mem_check>
f0104ce5:	83 c4 10             	add    $0x10,%esp
f0104ce8:	85 c0                	test   %eax,%eax
f0104cea:	0f 85 e3 00 00 00    	jne    f0104dd3 <debuginfo_eip+0x2c5>
		if(user_mem_check(curenv,stabstr,stabstr_end-stabstr,PTE_P|PTE_U) != 0)
f0104cf0:	e8 71 0f 00 00       	call   f0105c66 <cpunum>
f0104cf5:	6a 05                	push   $0x5
f0104cf7:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f0104cfa:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0104cfd:	29 ca                	sub    %ecx,%edx
f0104cff:	52                   	push   %edx
f0104d00:	51                   	push   %ecx
f0104d01:	6b c0 74             	imul   $0x74,%eax,%eax
f0104d04:	ff b0 28 90 23 f0    	pushl  -0xfdc6fd8(%eax)
f0104d0a:	e8 1b e2 ff ff       	call   f0102f2a <user_mem_check>
f0104d0f:	83 c4 10             	add    $0x10,%esp
f0104d12:	85 c0                	test   %eax,%eax
f0104d14:	0f 84 52 fe ff ff    	je     f0104b6c <debuginfo_eip+0x5e>
			return -1;
f0104d1a:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104d1f:	e9 d7 00 00 00       	jmp    f0104dfb <debuginfo_eip+0x2ed>
		info->eip_fn_addr = addr;
f0104d24:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f0104d27:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104d2a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104d2d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104d30:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104d33:	e9 e4 fe ff ff       	jmp    f0104c1c <debuginfo_eip+0x10e>
f0104d38:	83 e8 01             	sub    $0x1,%eax
f0104d3b:	83 ea 0c             	sub    $0xc,%edx
	while (lline >= lfile
f0104d3e:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0104d42:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0104d45:	39 c7                	cmp    %eax,%edi
f0104d47:	7f 43                	jg     f0104d8c <debuginfo_eip+0x27e>
	       && stabs[lline].n_type != N_SOL
f0104d49:	0f b6 0a             	movzbl (%edx),%ecx
f0104d4c:	80 f9 84             	cmp    $0x84,%cl
f0104d4f:	74 19                	je     f0104d6a <debuginfo_eip+0x25c>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104d51:	80 f9 64             	cmp    $0x64,%cl
f0104d54:	75 e2                	jne    f0104d38 <debuginfo_eip+0x22a>
f0104d56:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0104d5a:	74 dc                	je     f0104d38 <debuginfo_eip+0x22a>
f0104d5c:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104d60:	74 11                	je     f0104d73 <debuginfo_eip+0x265>
f0104d62:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104d65:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104d68:	eb 09                	jmp    f0104d73 <debuginfo_eip+0x265>
f0104d6a:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104d6e:	74 03                	je     f0104d73 <debuginfo_eip+0x265>
f0104d70:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104d73:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104d76:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0104d79:	8b 04 87             	mov    (%edi,%eax,4),%eax
f0104d7c:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f0104d7f:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0104d82:	29 fa                	sub    %edi,%edx
f0104d84:	39 d0                	cmp    %edx,%eax
f0104d86:	73 04                	jae    f0104d8c <debuginfo_eip+0x27e>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104d88:	01 f8                	add    %edi,%eax
f0104d8a:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104d8c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104d8f:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104d92:	ba 00 00 00 00       	mov    $0x0,%edx
	if (lfun < rfun)
f0104d97:	39 f0                	cmp    %esi,%eax
f0104d99:	7d 60                	jge    f0104dfb <debuginfo_eip+0x2ed>
		for (lline = lfun + 1;
f0104d9b:	8d 50 01             	lea    0x1(%eax),%edx
f0104d9e:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104da1:	89 d0                	mov    %edx,%eax
f0104da3:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104da6:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0104da9:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
f0104dad:	eb 04                	jmp    f0104db3 <debuginfo_eip+0x2a5>
			info->eip_fn_narg++;
f0104daf:	83 43 14 01          	addl   $0x1,0x14(%ebx)
		for (lline = lfun + 1;
f0104db3:	39 c6                	cmp    %eax,%esi
f0104db5:	7e 3f                	jle    f0104df6 <debuginfo_eip+0x2e8>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104db7:	0f b6 0a             	movzbl (%edx),%ecx
f0104dba:	83 c0 01             	add    $0x1,%eax
f0104dbd:	83 c2 0c             	add    $0xc,%edx
f0104dc0:	80 f9 a0             	cmp    $0xa0,%cl
f0104dc3:	74 ea                	je     f0104daf <debuginfo_eip+0x2a1>
	return 0;
f0104dc5:	ba 00 00 00 00       	mov    $0x0,%edx
f0104dca:	eb 2f                	jmp    f0104dfb <debuginfo_eip+0x2ed>
			return -1;
f0104dcc:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104dd1:	eb 28                	jmp    f0104dfb <debuginfo_eip+0x2ed>
			return -1;
f0104dd3:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104dd8:	eb 21                	jmp    f0104dfb <debuginfo_eip+0x2ed>
		return -1;
f0104dda:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104ddf:	eb 1a                	jmp    f0104dfb <debuginfo_eip+0x2ed>
f0104de1:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104de6:	eb 13                	jmp    f0104dfb <debuginfo_eip+0x2ed>
		return -1;
f0104de8:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104ded:	eb 0c                	jmp    f0104dfb <debuginfo_eip+0x2ed>
		return -1;
f0104def:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104df4:	eb 05                	jmp    f0104dfb <debuginfo_eip+0x2ed>
	return 0;
f0104df6:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104dfb:	89 d0                	mov    %edx,%eax
f0104dfd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104e00:	5b                   	pop    %ebx
f0104e01:	5e                   	pop    %esi
f0104e02:	5f                   	pop    %edi
f0104e03:	5d                   	pop    %ebp
f0104e04:	c3                   	ret    

f0104e05 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104e05:	55                   	push   %ebp
f0104e06:	89 e5                	mov    %esp,%ebp
f0104e08:	57                   	push   %edi
f0104e09:	56                   	push   %esi
f0104e0a:	53                   	push   %ebx
f0104e0b:	83 ec 1c             	sub    $0x1c,%esp
f0104e0e:	89 c7                	mov    %eax,%edi
f0104e10:	89 d6                	mov    %edx,%esi
f0104e12:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e15:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104e18:	89 d1                	mov    %edx,%ecx
f0104e1a:	89 c2                	mov    %eax,%edx
f0104e1c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104e1f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104e22:	8b 45 10             	mov    0x10(%ebp),%eax
f0104e25:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104e28:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104e2b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0104e32:	39 c2                	cmp    %eax,%edx
f0104e34:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f0104e37:	72 3e                	jb     f0104e77 <printnum+0x72>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104e39:	83 ec 0c             	sub    $0xc,%esp
f0104e3c:	ff 75 18             	pushl  0x18(%ebp)
f0104e3f:	83 eb 01             	sub    $0x1,%ebx
f0104e42:	53                   	push   %ebx
f0104e43:	50                   	push   %eax
f0104e44:	83 ec 08             	sub    $0x8,%esp
f0104e47:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104e4a:	ff 75 e0             	pushl  -0x20(%ebp)
f0104e4d:	ff 75 dc             	pushl  -0x24(%ebp)
f0104e50:	ff 75 d8             	pushl  -0x28(%ebp)
f0104e53:	e8 28 12 00 00       	call   f0106080 <__udivdi3>
f0104e58:	83 c4 18             	add    $0x18,%esp
f0104e5b:	52                   	push   %edx
f0104e5c:	50                   	push   %eax
f0104e5d:	89 f2                	mov    %esi,%edx
f0104e5f:	89 f8                	mov    %edi,%eax
f0104e61:	e8 9f ff ff ff       	call   f0104e05 <printnum>
f0104e66:	83 c4 20             	add    $0x20,%esp
f0104e69:	eb 13                	jmp    f0104e7e <printnum+0x79>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104e6b:	83 ec 08             	sub    $0x8,%esp
f0104e6e:	56                   	push   %esi
f0104e6f:	ff 75 18             	pushl  0x18(%ebp)
f0104e72:	ff d7                	call   *%edi
f0104e74:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0104e77:	83 eb 01             	sub    $0x1,%ebx
f0104e7a:	85 db                	test   %ebx,%ebx
f0104e7c:	7f ed                	jg     f0104e6b <printnum+0x66>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104e7e:	83 ec 08             	sub    $0x8,%esp
f0104e81:	56                   	push   %esi
f0104e82:	83 ec 04             	sub    $0x4,%esp
f0104e85:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104e88:	ff 75 e0             	pushl  -0x20(%ebp)
f0104e8b:	ff 75 dc             	pushl  -0x24(%ebp)
f0104e8e:	ff 75 d8             	pushl  -0x28(%ebp)
f0104e91:	e8 fa 12 00 00       	call   f0106190 <__umoddi3>
f0104e96:	83 c4 14             	add    $0x14,%esp
f0104e99:	0f be 80 42 7b 10 f0 	movsbl -0xfef84be(%eax),%eax
f0104ea0:	50                   	push   %eax
f0104ea1:	ff d7                	call   *%edi
}
f0104ea3:	83 c4 10             	add    $0x10,%esp
f0104ea6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104ea9:	5b                   	pop    %ebx
f0104eaa:	5e                   	pop    %esi
f0104eab:	5f                   	pop    %edi
f0104eac:	5d                   	pop    %ebp
f0104ead:	c3                   	ret    

f0104eae <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104eae:	f3 0f 1e fb          	endbr32 
f0104eb2:	55                   	push   %ebp
f0104eb3:	89 e5                	mov    %esp,%ebp
f0104eb5:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104eb8:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104ebc:	8b 10                	mov    (%eax),%edx
f0104ebe:	3b 50 04             	cmp    0x4(%eax),%edx
f0104ec1:	73 0a                	jae    f0104ecd <sprintputch+0x1f>
		*b->buf++ = ch;
f0104ec3:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104ec6:	89 08                	mov    %ecx,(%eax)
f0104ec8:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ecb:	88 02                	mov    %al,(%edx)
}
f0104ecd:	5d                   	pop    %ebp
f0104ece:	c3                   	ret    

f0104ecf <printfmt>:
{
f0104ecf:	f3 0f 1e fb          	endbr32 
f0104ed3:	55                   	push   %ebp
f0104ed4:	89 e5                	mov    %esp,%ebp
f0104ed6:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0104ed9:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104edc:	50                   	push   %eax
f0104edd:	ff 75 10             	pushl  0x10(%ebp)
f0104ee0:	ff 75 0c             	pushl  0xc(%ebp)
f0104ee3:	ff 75 08             	pushl  0x8(%ebp)
f0104ee6:	e8 05 00 00 00       	call   f0104ef0 <vprintfmt>
}
f0104eeb:	83 c4 10             	add    $0x10,%esp
f0104eee:	c9                   	leave  
f0104eef:	c3                   	ret    

f0104ef0 <vprintfmt>:
{
f0104ef0:	f3 0f 1e fb          	endbr32 
f0104ef4:	55                   	push   %ebp
f0104ef5:	89 e5                	mov    %esp,%ebp
f0104ef7:	57                   	push   %edi
f0104ef8:	56                   	push   %esi
f0104ef9:	53                   	push   %ebx
f0104efa:	83 ec 3c             	sub    $0x3c,%esp
f0104efd:	8b 75 08             	mov    0x8(%ebp),%esi
f0104f00:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104f03:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104f06:	e9 8e 03 00 00       	jmp    f0105299 <vprintfmt+0x3a9>
		padc = ' ';
f0104f0b:	c6 45 d3 20          	movb   $0x20,-0x2d(%ebp)
		altflag = 0;
f0104f0f:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
		precision = -1;
f0104f16:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f0104f1d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0104f24:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0104f29:	8d 47 01             	lea    0x1(%edi),%eax
f0104f2c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104f2f:	0f b6 17             	movzbl (%edi),%edx
f0104f32:	8d 42 dd             	lea    -0x23(%edx),%eax
f0104f35:	3c 55                	cmp    $0x55,%al
f0104f37:	0f 87 df 03 00 00    	ja     f010531c <vprintfmt+0x42c>
f0104f3d:	0f b6 c0             	movzbl %al,%eax
f0104f40:	3e ff 24 85 00 7c 10 	notrack jmp *-0xfef8400(,%eax,4)
f0104f47:	f0 
f0104f48:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0104f4b:	c6 45 d3 2d          	movb   $0x2d,-0x2d(%ebp)
f0104f4f:	eb d8                	jmp    f0104f29 <vprintfmt+0x39>
		switch (ch = *(unsigned char *) fmt++) {
f0104f51:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104f54:	c6 45 d3 30          	movb   $0x30,-0x2d(%ebp)
f0104f58:	eb cf                	jmp    f0104f29 <vprintfmt+0x39>
f0104f5a:	0f b6 d2             	movzbl %dl,%edx
f0104f5d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0104f60:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f65:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f0104f68:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104f6b:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0104f6f:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0104f72:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0104f75:	83 f9 09             	cmp    $0x9,%ecx
f0104f78:	77 55                	ja     f0104fcf <vprintfmt+0xdf>
			for (precision = 0; ; ++fmt) {
f0104f7a:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0104f7d:	eb e9                	jmp    f0104f68 <vprintfmt+0x78>
			precision = va_arg(ap, int);
f0104f7f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f82:	8b 00                	mov    (%eax),%eax
f0104f84:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104f87:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f8a:	8d 40 04             	lea    0x4(%eax),%eax
f0104f8d:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104f90:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0104f93:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104f97:	79 90                	jns    f0104f29 <vprintfmt+0x39>
				width = precision, precision = -1;
f0104f99:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104f9c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104f9f:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0104fa6:	eb 81                	jmp    f0104f29 <vprintfmt+0x39>
f0104fa8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104fab:	85 c0                	test   %eax,%eax
f0104fad:	ba 00 00 00 00       	mov    $0x0,%edx
f0104fb2:	0f 49 d0             	cmovns %eax,%edx
f0104fb5:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104fb8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0104fbb:	e9 69 ff ff ff       	jmp    f0104f29 <vprintfmt+0x39>
		switch (ch = *(unsigned char *) fmt++) {
f0104fc0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0104fc3:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
			goto reswitch;
f0104fca:	e9 5a ff ff ff       	jmp    f0104f29 <vprintfmt+0x39>
f0104fcf:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0104fd2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104fd5:	eb bc                	jmp    f0104f93 <vprintfmt+0xa3>
			lflag++;
f0104fd7:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0104fda:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0104fdd:	e9 47 ff ff ff       	jmp    f0104f29 <vprintfmt+0x39>
			putch(va_arg(ap, int), putdat);
f0104fe2:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fe5:	8d 78 04             	lea    0x4(%eax),%edi
f0104fe8:	83 ec 08             	sub    $0x8,%esp
f0104feb:	53                   	push   %ebx
f0104fec:	ff 30                	pushl  (%eax)
f0104fee:	ff d6                	call   *%esi
			break;
f0104ff0:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0104ff3:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0104ff6:	e9 9b 02 00 00       	jmp    f0105296 <vprintfmt+0x3a6>
			err = va_arg(ap, int);
f0104ffb:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ffe:	8d 78 04             	lea    0x4(%eax),%edi
f0105001:	8b 00                	mov    (%eax),%eax
f0105003:	99                   	cltd   
f0105004:	31 d0                	xor    %edx,%eax
f0105006:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0105008:	83 f8 08             	cmp    $0x8,%eax
f010500b:	7f 23                	jg     f0105030 <vprintfmt+0x140>
f010500d:	8b 14 85 60 7d 10 f0 	mov    -0xfef82a0(,%eax,4),%edx
f0105014:	85 d2                	test   %edx,%edx
f0105016:	74 18                	je     f0105030 <vprintfmt+0x140>
				printfmt(putch, putdat, "%s", p);
f0105018:	52                   	push   %edx
f0105019:	68 75 72 10 f0       	push   $0xf0107275
f010501e:	53                   	push   %ebx
f010501f:	56                   	push   %esi
f0105020:	e8 aa fe ff ff       	call   f0104ecf <printfmt>
f0105025:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0105028:	89 7d 14             	mov    %edi,0x14(%ebp)
f010502b:	e9 66 02 00 00       	jmp    f0105296 <vprintfmt+0x3a6>
				printfmt(putch, putdat, "error %d", err);
f0105030:	50                   	push   %eax
f0105031:	68 5a 7b 10 f0       	push   $0xf0107b5a
f0105036:	53                   	push   %ebx
f0105037:	56                   	push   %esi
f0105038:	e8 92 fe ff ff       	call   f0104ecf <printfmt>
f010503d:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0105040:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0105043:	e9 4e 02 00 00       	jmp    f0105296 <vprintfmt+0x3a6>
			if ((p = va_arg(ap, char *)) == NULL)
f0105048:	8b 45 14             	mov    0x14(%ebp),%eax
f010504b:	83 c0 04             	add    $0x4,%eax
f010504e:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0105051:	8b 45 14             	mov    0x14(%ebp),%eax
f0105054:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f0105056:	85 d2                	test   %edx,%edx
f0105058:	b8 53 7b 10 f0       	mov    $0xf0107b53,%eax
f010505d:	0f 45 c2             	cmovne %edx,%eax
f0105060:	89 45 cc             	mov    %eax,-0x34(%ebp)
			if (width > 0 && padc != '-')
f0105063:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0105067:	7e 06                	jle    f010506f <vprintfmt+0x17f>
f0105069:	80 7d d3 2d          	cmpb   $0x2d,-0x2d(%ebp)
f010506d:	75 0d                	jne    f010507c <vprintfmt+0x18c>
				for (width -= strnlen(p, precision); width > 0; width--)
f010506f:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0105072:	89 c7                	mov    %eax,%edi
f0105074:	03 45 e0             	add    -0x20(%ebp),%eax
f0105077:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010507a:	eb 55                	jmp    f01050d1 <vprintfmt+0x1e1>
f010507c:	83 ec 08             	sub    $0x8,%esp
f010507f:	ff 75 d8             	pushl  -0x28(%ebp)
f0105082:	ff 75 cc             	pushl  -0x34(%ebp)
f0105085:	e8 2c 04 00 00       	call   f01054b6 <strnlen>
f010508a:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010508d:	29 c2                	sub    %eax,%edx
f010508f:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0105092:	83 c4 10             	add    $0x10,%esp
f0105095:	89 d7                	mov    %edx,%edi
					putch(padc, putdat);
f0105097:	0f be 45 d3          	movsbl -0x2d(%ebp),%eax
f010509b:	89 45 e0             	mov    %eax,-0x20(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f010509e:	85 ff                	test   %edi,%edi
f01050a0:	7e 11                	jle    f01050b3 <vprintfmt+0x1c3>
					putch(padc, putdat);
f01050a2:	83 ec 08             	sub    $0x8,%esp
f01050a5:	53                   	push   %ebx
f01050a6:	ff 75 e0             	pushl  -0x20(%ebp)
f01050a9:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f01050ab:	83 ef 01             	sub    $0x1,%edi
f01050ae:	83 c4 10             	add    $0x10,%esp
f01050b1:	eb eb                	jmp    f010509e <vprintfmt+0x1ae>
f01050b3:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f01050b6:	85 d2                	test   %edx,%edx
f01050b8:	b8 00 00 00 00       	mov    $0x0,%eax
f01050bd:	0f 49 c2             	cmovns %edx,%eax
f01050c0:	29 c2                	sub    %eax,%edx
f01050c2:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01050c5:	eb a8                	jmp    f010506f <vprintfmt+0x17f>
					putch(ch, putdat);
f01050c7:	83 ec 08             	sub    $0x8,%esp
f01050ca:	53                   	push   %ebx
f01050cb:	52                   	push   %edx
f01050cc:	ff d6                	call   *%esi
f01050ce:	83 c4 10             	add    $0x10,%esp
f01050d1:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01050d4:	29 f9                	sub    %edi,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01050d6:	83 c7 01             	add    $0x1,%edi
f01050d9:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01050dd:	0f be d0             	movsbl %al,%edx
f01050e0:	85 d2                	test   %edx,%edx
f01050e2:	74 4b                	je     f010512f <vprintfmt+0x23f>
f01050e4:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01050e8:	78 06                	js     f01050f0 <vprintfmt+0x200>
f01050ea:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f01050ee:	78 1e                	js     f010510e <vprintfmt+0x21e>
				if (altflag && (ch < ' ' || ch > '~'))
f01050f0:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01050f4:	74 d1                	je     f01050c7 <vprintfmt+0x1d7>
f01050f6:	0f be c0             	movsbl %al,%eax
f01050f9:	83 e8 20             	sub    $0x20,%eax
f01050fc:	83 f8 5e             	cmp    $0x5e,%eax
f01050ff:	76 c6                	jbe    f01050c7 <vprintfmt+0x1d7>
					putch('?', putdat);
f0105101:	83 ec 08             	sub    $0x8,%esp
f0105104:	53                   	push   %ebx
f0105105:	6a 3f                	push   $0x3f
f0105107:	ff d6                	call   *%esi
f0105109:	83 c4 10             	add    $0x10,%esp
f010510c:	eb c3                	jmp    f01050d1 <vprintfmt+0x1e1>
f010510e:	89 cf                	mov    %ecx,%edi
f0105110:	eb 0e                	jmp    f0105120 <vprintfmt+0x230>
				putch(' ', putdat);
f0105112:	83 ec 08             	sub    $0x8,%esp
f0105115:	53                   	push   %ebx
f0105116:	6a 20                	push   $0x20
f0105118:	ff d6                	call   *%esi
			for (; width > 0; width--)
f010511a:	83 ef 01             	sub    $0x1,%edi
f010511d:	83 c4 10             	add    $0x10,%esp
f0105120:	85 ff                	test   %edi,%edi
f0105122:	7f ee                	jg     f0105112 <vprintfmt+0x222>
			if ((p = va_arg(ap, char *)) == NULL)
f0105124:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0105127:	89 45 14             	mov    %eax,0x14(%ebp)
f010512a:	e9 67 01 00 00       	jmp    f0105296 <vprintfmt+0x3a6>
f010512f:	89 cf                	mov    %ecx,%edi
f0105131:	eb ed                	jmp    f0105120 <vprintfmt+0x230>
	if (lflag >= 2)
f0105133:	83 f9 01             	cmp    $0x1,%ecx
f0105136:	7f 1b                	jg     f0105153 <vprintfmt+0x263>
	else if (lflag)
f0105138:	85 c9                	test   %ecx,%ecx
f010513a:	74 63                	je     f010519f <vprintfmt+0x2af>
		return va_arg(*ap, long);
f010513c:	8b 45 14             	mov    0x14(%ebp),%eax
f010513f:	8b 00                	mov    (%eax),%eax
f0105141:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105144:	99                   	cltd   
f0105145:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105148:	8b 45 14             	mov    0x14(%ebp),%eax
f010514b:	8d 40 04             	lea    0x4(%eax),%eax
f010514e:	89 45 14             	mov    %eax,0x14(%ebp)
f0105151:	eb 17                	jmp    f010516a <vprintfmt+0x27a>
		return va_arg(*ap, long long);
f0105153:	8b 45 14             	mov    0x14(%ebp),%eax
f0105156:	8b 50 04             	mov    0x4(%eax),%edx
f0105159:	8b 00                	mov    (%eax),%eax
f010515b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010515e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105161:	8b 45 14             	mov    0x14(%ebp),%eax
f0105164:	8d 40 08             	lea    0x8(%eax),%eax
f0105167:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f010516a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010516d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0105170:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f0105175:	85 c9                	test   %ecx,%ecx
f0105177:	0f 89 ff 00 00 00    	jns    f010527c <vprintfmt+0x38c>
				putch('-', putdat);
f010517d:	83 ec 08             	sub    $0x8,%esp
f0105180:	53                   	push   %ebx
f0105181:	6a 2d                	push   $0x2d
f0105183:	ff d6                	call   *%esi
				num = -(long long) num;
f0105185:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0105188:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010518b:	f7 da                	neg    %edx
f010518d:	83 d1 00             	adc    $0x0,%ecx
f0105190:	f7 d9                	neg    %ecx
f0105192:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0105195:	b8 0a 00 00 00       	mov    $0xa,%eax
f010519a:	e9 dd 00 00 00       	jmp    f010527c <vprintfmt+0x38c>
		return va_arg(*ap, int);
f010519f:	8b 45 14             	mov    0x14(%ebp),%eax
f01051a2:	8b 00                	mov    (%eax),%eax
f01051a4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01051a7:	99                   	cltd   
f01051a8:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01051ab:	8b 45 14             	mov    0x14(%ebp),%eax
f01051ae:	8d 40 04             	lea    0x4(%eax),%eax
f01051b1:	89 45 14             	mov    %eax,0x14(%ebp)
f01051b4:	eb b4                	jmp    f010516a <vprintfmt+0x27a>
	if (lflag >= 2)
f01051b6:	83 f9 01             	cmp    $0x1,%ecx
f01051b9:	7f 1e                	jg     f01051d9 <vprintfmt+0x2e9>
	else if (lflag)
f01051bb:	85 c9                	test   %ecx,%ecx
f01051bd:	74 32                	je     f01051f1 <vprintfmt+0x301>
		return va_arg(*ap, unsigned long);
f01051bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01051c2:	8b 10                	mov    (%eax),%edx
f01051c4:	b9 00 00 00 00       	mov    $0x0,%ecx
f01051c9:	8d 40 04             	lea    0x4(%eax),%eax
f01051cc:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01051cf:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long);
f01051d4:	e9 a3 00 00 00       	jmp    f010527c <vprintfmt+0x38c>
		return va_arg(*ap, unsigned long long);
f01051d9:	8b 45 14             	mov    0x14(%ebp),%eax
f01051dc:	8b 10                	mov    (%eax),%edx
f01051de:	8b 48 04             	mov    0x4(%eax),%ecx
f01051e1:	8d 40 08             	lea    0x8(%eax),%eax
f01051e4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01051e7:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long long);
f01051ec:	e9 8b 00 00 00       	jmp    f010527c <vprintfmt+0x38c>
		return va_arg(*ap, unsigned int);
f01051f1:	8b 45 14             	mov    0x14(%ebp),%eax
f01051f4:	8b 10                	mov    (%eax),%edx
f01051f6:	b9 00 00 00 00       	mov    $0x0,%ecx
f01051fb:	8d 40 04             	lea    0x4(%eax),%eax
f01051fe:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0105201:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned int);
f0105206:	eb 74                	jmp    f010527c <vprintfmt+0x38c>
	if (lflag >= 2)
f0105208:	83 f9 01             	cmp    $0x1,%ecx
f010520b:	7f 1b                	jg     f0105228 <vprintfmt+0x338>
	else if (lflag)
f010520d:	85 c9                	test   %ecx,%ecx
f010520f:	74 2c                	je     f010523d <vprintfmt+0x34d>
		return va_arg(*ap, unsigned long);
f0105211:	8b 45 14             	mov    0x14(%ebp),%eax
f0105214:	8b 10                	mov    (%eax),%edx
f0105216:	b9 00 00 00 00       	mov    $0x0,%ecx
f010521b:	8d 40 04             	lea    0x4(%eax),%eax
f010521e:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0105221:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long);
f0105226:	eb 54                	jmp    f010527c <vprintfmt+0x38c>
		return va_arg(*ap, unsigned long long);
f0105228:	8b 45 14             	mov    0x14(%ebp),%eax
f010522b:	8b 10                	mov    (%eax),%edx
f010522d:	8b 48 04             	mov    0x4(%eax),%ecx
f0105230:	8d 40 08             	lea    0x8(%eax),%eax
f0105233:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0105236:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long long);
f010523b:	eb 3f                	jmp    f010527c <vprintfmt+0x38c>
		return va_arg(*ap, unsigned int);
f010523d:	8b 45 14             	mov    0x14(%ebp),%eax
f0105240:	8b 10                	mov    (%eax),%edx
f0105242:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105247:	8d 40 04             	lea    0x4(%eax),%eax
f010524a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010524d:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned int);
f0105252:	eb 28                	jmp    f010527c <vprintfmt+0x38c>
			putch('0', putdat);
f0105254:	83 ec 08             	sub    $0x8,%esp
f0105257:	53                   	push   %ebx
f0105258:	6a 30                	push   $0x30
f010525a:	ff d6                	call   *%esi
			putch('x', putdat);
f010525c:	83 c4 08             	add    $0x8,%esp
f010525f:	53                   	push   %ebx
f0105260:	6a 78                	push   $0x78
f0105262:	ff d6                	call   *%esi
			num = (unsigned long long)
f0105264:	8b 45 14             	mov    0x14(%ebp),%eax
f0105267:	8b 10                	mov    (%eax),%edx
f0105269:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010526e:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0105271:	8d 40 04             	lea    0x4(%eax),%eax
f0105274:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0105277:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f010527c:	83 ec 0c             	sub    $0xc,%esp
f010527f:	0f be 7d d3          	movsbl -0x2d(%ebp),%edi
f0105283:	57                   	push   %edi
f0105284:	ff 75 e0             	pushl  -0x20(%ebp)
f0105287:	50                   	push   %eax
f0105288:	51                   	push   %ecx
f0105289:	52                   	push   %edx
f010528a:	89 da                	mov    %ebx,%edx
f010528c:	89 f0                	mov    %esi,%eax
f010528e:	e8 72 fb ff ff       	call   f0104e05 <printnum>
			break;
f0105293:	83 c4 20             	add    $0x20,%esp
			if ((p = va_arg(ap, char *)) == NULL)
f0105296:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0105299:	83 c7 01             	add    $0x1,%edi
f010529c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01052a0:	83 f8 25             	cmp    $0x25,%eax
f01052a3:	0f 84 62 fc ff ff    	je     f0104f0b <vprintfmt+0x1b>
			if (ch == '\0')
f01052a9:	85 c0                	test   %eax,%eax
f01052ab:	0f 84 8b 00 00 00    	je     f010533c <vprintfmt+0x44c>
			putch(ch, putdat);
f01052b1:	83 ec 08             	sub    $0x8,%esp
f01052b4:	53                   	push   %ebx
f01052b5:	50                   	push   %eax
f01052b6:	ff d6                	call   *%esi
f01052b8:	83 c4 10             	add    $0x10,%esp
f01052bb:	eb dc                	jmp    f0105299 <vprintfmt+0x3a9>
	if (lflag >= 2)
f01052bd:	83 f9 01             	cmp    $0x1,%ecx
f01052c0:	7f 1b                	jg     f01052dd <vprintfmt+0x3ed>
	else if (lflag)
f01052c2:	85 c9                	test   %ecx,%ecx
f01052c4:	74 2c                	je     f01052f2 <vprintfmt+0x402>
		return va_arg(*ap, unsigned long);
f01052c6:	8b 45 14             	mov    0x14(%ebp),%eax
f01052c9:	8b 10                	mov    (%eax),%edx
f01052cb:	b9 00 00 00 00       	mov    $0x0,%ecx
f01052d0:	8d 40 04             	lea    0x4(%eax),%eax
f01052d3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01052d6:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long);
f01052db:	eb 9f                	jmp    f010527c <vprintfmt+0x38c>
		return va_arg(*ap, unsigned long long);
f01052dd:	8b 45 14             	mov    0x14(%ebp),%eax
f01052e0:	8b 10                	mov    (%eax),%edx
f01052e2:	8b 48 04             	mov    0x4(%eax),%ecx
f01052e5:	8d 40 08             	lea    0x8(%eax),%eax
f01052e8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01052eb:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long long);
f01052f0:	eb 8a                	jmp    f010527c <vprintfmt+0x38c>
		return va_arg(*ap, unsigned int);
f01052f2:	8b 45 14             	mov    0x14(%ebp),%eax
f01052f5:	8b 10                	mov    (%eax),%edx
f01052f7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01052fc:	8d 40 04             	lea    0x4(%eax),%eax
f01052ff:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0105302:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned int);
f0105307:	e9 70 ff ff ff       	jmp    f010527c <vprintfmt+0x38c>
			putch(ch, putdat);
f010530c:	83 ec 08             	sub    $0x8,%esp
f010530f:	53                   	push   %ebx
f0105310:	6a 25                	push   $0x25
f0105312:	ff d6                	call   *%esi
			break;
f0105314:	83 c4 10             	add    $0x10,%esp
f0105317:	e9 7a ff ff ff       	jmp    f0105296 <vprintfmt+0x3a6>
			putch('%', putdat);
f010531c:	83 ec 08             	sub    $0x8,%esp
f010531f:	53                   	push   %ebx
f0105320:	6a 25                	push   $0x25
f0105322:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105324:	83 c4 10             	add    $0x10,%esp
f0105327:	89 f8                	mov    %edi,%eax
f0105329:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f010532d:	74 05                	je     f0105334 <vprintfmt+0x444>
f010532f:	83 e8 01             	sub    $0x1,%eax
f0105332:	eb f5                	jmp    f0105329 <vprintfmt+0x439>
f0105334:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105337:	e9 5a ff ff ff       	jmp    f0105296 <vprintfmt+0x3a6>
}
f010533c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010533f:	5b                   	pop    %ebx
f0105340:	5e                   	pop    %esi
f0105341:	5f                   	pop    %edi
f0105342:	5d                   	pop    %ebp
f0105343:	c3                   	ret    

f0105344 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105344:	f3 0f 1e fb          	endbr32 
f0105348:	55                   	push   %ebp
f0105349:	89 e5                	mov    %esp,%ebp
f010534b:	83 ec 18             	sub    $0x18,%esp
f010534e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105351:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105354:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105357:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010535b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010535e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105365:	85 c0                	test   %eax,%eax
f0105367:	74 26                	je     f010538f <vsnprintf+0x4b>
f0105369:	85 d2                	test   %edx,%edx
f010536b:	7e 22                	jle    f010538f <vsnprintf+0x4b>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010536d:	ff 75 14             	pushl  0x14(%ebp)
f0105370:	ff 75 10             	pushl  0x10(%ebp)
f0105373:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105376:	50                   	push   %eax
f0105377:	68 ae 4e 10 f0       	push   $0xf0104eae
f010537c:	e8 6f fb ff ff       	call   f0104ef0 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0105381:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105384:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105387:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010538a:	83 c4 10             	add    $0x10,%esp
}
f010538d:	c9                   	leave  
f010538e:	c3                   	ret    
		return -E_INVAL;
f010538f:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105394:	eb f7                	jmp    f010538d <vsnprintf+0x49>

f0105396 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105396:	f3 0f 1e fb          	endbr32 
f010539a:	55                   	push   %ebp
f010539b:	89 e5                	mov    %esp,%ebp
f010539d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01053a0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01053a3:	50                   	push   %eax
f01053a4:	ff 75 10             	pushl  0x10(%ebp)
f01053a7:	ff 75 0c             	pushl  0xc(%ebp)
f01053aa:	ff 75 08             	pushl  0x8(%ebp)
f01053ad:	e8 92 ff ff ff       	call   f0105344 <vsnprintf>
	va_end(ap);

	return rc;
}
f01053b2:	c9                   	leave  
f01053b3:	c3                   	ret    

f01053b4 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01053b4:	f3 0f 1e fb          	endbr32 
f01053b8:	55                   	push   %ebp
f01053b9:	89 e5                	mov    %esp,%ebp
f01053bb:	57                   	push   %edi
f01053bc:	56                   	push   %esi
f01053bd:	53                   	push   %ebx
f01053be:	83 ec 0c             	sub    $0xc,%esp
f01053c1:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01053c4:	85 c0                	test   %eax,%eax
f01053c6:	74 11                	je     f01053d9 <readline+0x25>
		cprintf("%s", prompt);
f01053c8:	83 ec 08             	sub    $0x8,%esp
f01053cb:	50                   	push   %eax
f01053cc:	68 75 72 10 f0       	push   $0xf0107275
f01053d1:	e8 f7 e5 ff ff       	call   f01039cd <cprintf>
f01053d6:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01053d9:	83 ec 0c             	sub    $0xc,%esp
f01053dc:	6a 00                	push   $0x0
f01053de:	e8 cf b3 ff ff       	call   f01007b2 <iscons>
f01053e3:	89 c7                	mov    %eax,%edi
f01053e5:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01053e8:	be 00 00 00 00       	mov    $0x0,%esi
f01053ed:	eb 4b                	jmp    f010543a <readline+0x86>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01053ef:	83 ec 08             	sub    $0x8,%esp
f01053f2:	50                   	push   %eax
f01053f3:	68 84 7d 10 f0       	push   $0xf0107d84
f01053f8:	e8 d0 e5 ff ff       	call   f01039cd <cprintf>
			return NULL;
f01053fd:	83 c4 10             	add    $0x10,%esp
f0105400:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0105405:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105408:	5b                   	pop    %ebx
f0105409:	5e                   	pop    %esi
f010540a:	5f                   	pop    %edi
f010540b:	5d                   	pop    %ebp
f010540c:	c3                   	ret    
			if (echoing)
f010540d:	85 ff                	test   %edi,%edi
f010540f:	75 05                	jne    f0105416 <readline+0x62>
			i--;
f0105411:	83 ee 01             	sub    $0x1,%esi
f0105414:	eb 24                	jmp    f010543a <readline+0x86>
				cputchar('\b');
f0105416:	83 ec 0c             	sub    $0xc,%esp
f0105419:	6a 08                	push   $0x8
f010541b:	e8 69 b3 ff ff       	call   f0100789 <cputchar>
f0105420:	83 c4 10             	add    $0x10,%esp
f0105423:	eb ec                	jmp    f0105411 <readline+0x5d>
				cputchar(c);
f0105425:	83 ec 0c             	sub    $0xc,%esp
f0105428:	53                   	push   %ebx
f0105429:	e8 5b b3 ff ff       	call   f0100789 <cputchar>
f010542e:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0105431:	88 9e 80 8a 23 f0    	mov    %bl,-0xfdc7580(%esi)
f0105437:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f010543a:	e8 5e b3 ff ff       	call   f010079d <getchar>
f010543f:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0105441:	85 c0                	test   %eax,%eax
f0105443:	78 aa                	js     f01053ef <readline+0x3b>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105445:	83 f8 08             	cmp    $0x8,%eax
f0105448:	0f 94 c2             	sete   %dl
f010544b:	83 f8 7f             	cmp    $0x7f,%eax
f010544e:	0f 94 c0             	sete   %al
f0105451:	08 c2                	or     %al,%dl
f0105453:	74 04                	je     f0105459 <readline+0xa5>
f0105455:	85 f6                	test   %esi,%esi
f0105457:	7f b4                	jg     f010540d <readline+0x59>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105459:	83 fb 1f             	cmp    $0x1f,%ebx
f010545c:	7e 0e                	jle    f010546c <readline+0xb8>
f010545e:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0105464:	7f 06                	jg     f010546c <readline+0xb8>
			if (echoing)
f0105466:	85 ff                	test   %edi,%edi
f0105468:	74 c7                	je     f0105431 <readline+0x7d>
f010546a:	eb b9                	jmp    f0105425 <readline+0x71>
		} else if (c == '\n' || c == '\r') {
f010546c:	83 fb 0a             	cmp    $0xa,%ebx
f010546f:	74 05                	je     f0105476 <readline+0xc2>
f0105471:	83 fb 0d             	cmp    $0xd,%ebx
f0105474:	75 c4                	jne    f010543a <readline+0x86>
			if (echoing)
f0105476:	85 ff                	test   %edi,%edi
f0105478:	75 11                	jne    f010548b <readline+0xd7>
			buf[i] = 0;
f010547a:	c6 86 80 8a 23 f0 00 	movb   $0x0,-0xfdc7580(%esi)
			return buf;
f0105481:	b8 80 8a 23 f0       	mov    $0xf0238a80,%eax
f0105486:	e9 7a ff ff ff       	jmp    f0105405 <readline+0x51>
				cputchar('\n');
f010548b:	83 ec 0c             	sub    $0xc,%esp
f010548e:	6a 0a                	push   $0xa
f0105490:	e8 f4 b2 ff ff       	call   f0100789 <cputchar>
f0105495:	83 c4 10             	add    $0x10,%esp
f0105498:	eb e0                	jmp    f010547a <readline+0xc6>

f010549a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010549a:	f3 0f 1e fb          	endbr32 
f010549e:	55                   	push   %ebp
f010549f:	89 e5                	mov    %esp,%ebp
f01054a1:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01054a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01054a9:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01054ad:	74 05                	je     f01054b4 <strlen+0x1a>
		n++;
f01054af:	83 c0 01             	add    $0x1,%eax
f01054b2:	eb f5                	jmp    f01054a9 <strlen+0xf>
	return n;
}
f01054b4:	5d                   	pop    %ebp
f01054b5:	c3                   	ret    

f01054b6 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01054b6:	f3 0f 1e fb          	endbr32 
f01054ba:	55                   	push   %ebp
f01054bb:	89 e5                	mov    %esp,%ebp
f01054bd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01054c0:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01054c3:	b8 00 00 00 00       	mov    $0x0,%eax
f01054c8:	39 d0                	cmp    %edx,%eax
f01054ca:	74 0d                	je     f01054d9 <strnlen+0x23>
f01054cc:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01054d0:	74 05                	je     f01054d7 <strnlen+0x21>
		n++;
f01054d2:	83 c0 01             	add    $0x1,%eax
f01054d5:	eb f1                	jmp    f01054c8 <strnlen+0x12>
f01054d7:	89 c2                	mov    %eax,%edx
	return n;
}
f01054d9:	89 d0                	mov    %edx,%eax
f01054db:	5d                   	pop    %ebp
f01054dc:	c3                   	ret    

f01054dd <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01054dd:	f3 0f 1e fb          	endbr32 
f01054e1:	55                   	push   %ebp
f01054e2:	89 e5                	mov    %esp,%ebp
f01054e4:	53                   	push   %ebx
f01054e5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01054e8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01054eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01054f0:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f01054f4:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f01054f7:	83 c0 01             	add    $0x1,%eax
f01054fa:	84 d2                	test   %dl,%dl
f01054fc:	75 f2                	jne    f01054f0 <strcpy+0x13>
		/* do nothing */;
	return ret;
}
f01054fe:	89 c8                	mov    %ecx,%eax
f0105500:	5b                   	pop    %ebx
f0105501:	5d                   	pop    %ebp
f0105502:	c3                   	ret    

f0105503 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105503:	f3 0f 1e fb          	endbr32 
f0105507:	55                   	push   %ebp
f0105508:	89 e5                	mov    %esp,%ebp
f010550a:	53                   	push   %ebx
f010550b:	83 ec 10             	sub    $0x10,%esp
f010550e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105511:	53                   	push   %ebx
f0105512:	e8 83 ff ff ff       	call   f010549a <strlen>
f0105517:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f010551a:	ff 75 0c             	pushl  0xc(%ebp)
f010551d:	01 d8                	add    %ebx,%eax
f010551f:	50                   	push   %eax
f0105520:	e8 b8 ff ff ff       	call   f01054dd <strcpy>
	return dst;
}
f0105525:	89 d8                	mov    %ebx,%eax
f0105527:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010552a:	c9                   	leave  
f010552b:	c3                   	ret    

f010552c <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010552c:	f3 0f 1e fb          	endbr32 
f0105530:	55                   	push   %ebp
f0105531:	89 e5                	mov    %esp,%ebp
f0105533:	56                   	push   %esi
f0105534:	53                   	push   %ebx
f0105535:	8b 75 08             	mov    0x8(%ebp),%esi
f0105538:	8b 55 0c             	mov    0xc(%ebp),%edx
f010553b:	89 f3                	mov    %esi,%ebx
f010553d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105540:	89 f0                	mov    %esi,%eax
f0105542:	39 d8                	cmp    %ebx,%eax
f0105544:	74 11                	je     f0105557 <strncpy+0x2b>
		*dst++ = *src;
f0105546:	83 c0 01             	add    $0x1,%eax
f0105549:	0f b6 0a             	movzbl (%edx),%ecx
f010554c:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010554f:	80 f9 01             	cmp    $0x1,%cl
f0105552:	83 da ff             	sbb    $0xffffffff,%edx
f0105555:	eb eb                	jmp    f0105542 <strncpy+0x16>
	}
	return ret;
}
f0105557:	89 f0                	mov    %esi,%eax
f0105559:	5b                   	pop    %ebx
f010555a:	5e                   	pop    %esi
f010555b:	5d                   	pop    %ebp
f010555c:	c3                   	ret    

f010555d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010555d:	f3 0f 1e fb          	endbr32 
f0105561:	55                   	push   %ebp
f0105562:	89 e5                	mov    %esp,%ebp
f0105564:	56                   	push   %esi
f0105565:	53                   	push   %ebx
f0105566:	8b 75 08             	mov    0x8(%ebp),%esi
f0105569:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010556c:	8b 55 10             	mov    0x10(%ebp),%edx
f010556f:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105571:	85 d2                	test   %edx,%edx
f0105573:	74 21                	je     f0105596 <strlcpy+0x39>
f0105575:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0105579:	89 f2                	mov    %esi,%edx
		while (--size > 0 && *src != '\0')
f010557b:	39 c2                	cmp    %eax,%edx
f010557d:	74 14                	je     f0105593 <strlcpy+0x36>
f010557f:	0f b6 19             	movzbl (%ecx),%ebx
f0105582:	84 db                	test   %bl,%bl
f0105584:	74 0b                	je     f0105591 <strlcpy+0x34>
			*dst++ = *src++;
f0105586:	83 c1 01             	add    $0x1,%ecx
f0105589:	83 c2 01             	add    $0x1,%edx
f010558c:	88 5a ff             	mov    %bl,-0x1(%edx)
f010558f:	eb ea                	jmp    f010557b <strlcpy+0x1e>
f0105591:	89 d0                	mov    %edx,%eax
		*dst = '\0';
f0105593:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105596:	29 f0                	sub    %esi,%eax
}
f0105598:	5b                   	pop    %ebx
f0105599:	5e                   	pop    %esi
f010559a:	5d                   	pop    %ebp
f010559b:	c3                   	ret    

f010559c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010559c:	f3 0f 1e fb          	endbr32 
f01055a0:	55                   	push   %ebp
f01055a1:	89 e5                	mov    %esp,%ebp
f01055a3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01055a6:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01055a9:	0f b6 01             	movzbl (%ecx),%eax
f01055ac:	84 c0                	test   %al,%al
f01055ae:	74 0c                	je     f01055bc <strcmp+0x20>
f01055b0:	3a 02                	cmp    (%edx),%al
f01055b2:	75 08                	jne    f01055bc <strcmp+0x20>
		p++, q++;
f01055b4:	83 c1 01             	add    $0x1,%ecx
f01055b7:	83 c2 01             	add    $0x1,%edx
f01055ba:	eb ed                	jmp    f01055a9 <strcmp+0xd>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01055bc:	0f b6 c0             	movzbl %al,%eax
f01055bf:	0f b6 12             	movzbl (%edx),%edx
f01055c2:	29 d0                	sub    %edx,%eax
}
f01055c4:	5d                   	pop    %ebp
f01055c5:	c3                   	ret    

f01055c6 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01055c6:	f3 0f 1e fb          	endbr32 
f01055ca:	55                   	push   %ebp
f01055cb:	89 e5                	mov    %esp,%ebp
f01055cd:	53                   	push   %ebx
f01055ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01055d1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01055d4:	89 c3                	mov    %eax,%ebx
f01055d6:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01055d9:	eb 06                	jmp    f01055e1 <strncmp+0x1b>
		n--, p++, q++;
f01055db:	83 c0 01             	add    $0x1,%eax
f01055de:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01055e1:	39 d8                	cmp    %ebx,%eax
f01055e3:	74 16                	je     f01055fb <strncmp+0x35>
f01055e5:	0f b6 08             	movzbl (%eax),%ecx
f01055e8:	84 c9                	test   %cl,%cl
f01055ea:	74 04                	je     f01055f0 <strncmp+0x2a>
f01055ec:	3a 0a                	cmp    (%edx),%cl
f01055ee:	74 eb                	je     f01055db <strncmp+0x15>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01055f0:	0f b6 00             	movzbl (%eax),%eax
f01055f3:	0f b6 12             	movzbl (%edx),%edx
f01055f6:	29 d0                	sub    %edx,%eax
}
f01055f8:	5b                   	pop    %ebx
f01055f9:	5d                   	pop    %ebp
f01055fa:	c3                   	ret    
		return 0;
f01055fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0105600:	eb f6                	jmp    f01055f8 <strncmp+0x32>

f0105602 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105602:	f3 0f 1e fb          	endbr32 
f0105606:	55                   	push   %ebp
f0105607:	89 e5                	mov    %esp,%ebp
f0105609:	8b 45 08             	mov    0x8(%ebp),%eax
f010560c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105610:	0f b6 10             	movzbl (%eax),%edx
f0105613:	84 d2                	test   %dl,%dl
f0105615:	74 09                	je     f0105620 <strchr+0x1e>
		if (*s == c)
f0105617:	38 ca                	cmp    %cl,%dl
f0105619:	74 0a                	je     f0105625 <strchr+0x23>
	for (; *s; s++)
f010561b:	83 c0 01             	add    $0x1,%eax
f010561e:	eb f0                	jmp    f0105610 <strchr+0xe>
			return (char *) s;
	return 0;
f0105620:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105625:	5d                   	pop    %ebp
f0105626:	c3                   	ret    

f0105627 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105627:	f3 0f 1e fb          	endbr32 
f010562b:	55                   	push   %ebp
f010562c:	89 e5                	mov    %esp,%ebp
f010562e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105631:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105635:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0105638:	38 ca                	cmp    %cl,%dl
f010563a:	74 09                	je     f0105645 <strfind+0x1e>
f010563c:	84 d2                	test   %dl,%dl
f010563e:	74 05                	je     f0105645 <strfind+0x1e>
	for (; *s; s++)
f0105640:	83 c0 01             	add    $0x1,%eax
f0105643:	eb f0                	jmp    f0105635 <strfind+0xe>
			break;
	return (char *) s;
}
f0105645:	5d                   	pop    %ebp
f0105646:	c3                   	ret    

f0105647 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105647:	f3 0f 1e fb          	endbr32 
f010564b:	55                   	push   %ebp
f010564c:	89 e5                	mov    %esp,%ebp
f010564e:	57                   	push   %edi
f010564f:	56                   	push   %esi
f0105650:	53                   	push   %ebx
f0105651:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105654:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105657:	85 c9                	test   %ecx,%ecx
f0105659:	74 31                	je     f010568c <memset+0x45>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010565b:	89 f8                	mov    %edi,%eax
f010565d:	09 c8                	or     %ecx,%eax
f010565f:	a8 03                	test   $0x3,%al
f0105661:	75 23                	jne    f0105686 <memset+0x3f>
		c &= 0xFF;
f0105663:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105667:	89 d3                	mov    %edx,%ebx
f0105669:	c1 e3 08             	shl    $0x8,%ebx
f010566c:	89 d0                	mov    %edx,%eax
f010566e:	c1 e0 18             	shl    $0x18,%eax
f0105671:	89 d6                	mov    %edx,%esi
f0105673:	c1 e6 10             	shl    $0x10,%esi
f0105676:	09 f0                	or     %esi,%eax
f0105678:	09 c2                	or     %eax,%edx
f010567a:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010567c:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f010567f:	89 d0                	mov    %edx,%eax
f0105681:	fc                   	cld    
f0105682:	f3 ab                	rep stos %eax,%es:(%edi)
f0105684:	eb 06                	jmp    f010568c <memset+0x45>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105686:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105689:	fc                   	cld    
f010568a:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010568c:	89 f8                	mov    %edi,%eax
f010568e:	5b                   	pop    %ebx
f010568f:	5e                   	pop    %esi
f0105690:	5f                   	pop    %edi
f0105691:	5d                   	pop    %ebp
f0105692:	c3                   	ret    

f0105693 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105693:	f3 0f 1e fb          	endbr32 
f0105697:	55                   	push   %ebp
f0105698:	89 e5                	mov    %esp,%ebp
f010569a:	57                   	push   %edi
f010569b:	56                   	push   %esi
f010569c:	8b 45 08             	mov    0x8(%ebp),%eax
f010569f:	8b 75 0c             	mov    0xc(%ebp),%esi
f01056a2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01056a5:	39 c6                	cmp    %eax,%esi
f01056a7:	73 32                	jae    f01056db <memmove+0x48>
f01056a9:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01056ac:	39 c2                	cmp    %eax,%edx
f01056ae:	76 2b                	jbe    f01056db <memmove+0x48>
		s += n;
		d += n;
f01056b0:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01056b3:	89 fe                	mov    %edi,%esi
f01056b5:	09 ce                	or     %ecx,%esi
f01056b7:	09 d6                	or     %edx,%esi
f01056b9:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01056bf:	75 0e                	jne    f01056cf <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01056c1:	83 ef 04             	sub    $0x4,%edi
f01056c4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01056c7:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01056ca:	fd                   	std    
f01056cb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01056cd:	eb 09                	jmp    f01056d8 <memmove+0x45>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01056cf:	83 ef 01             	sub    $0x1,%edi
f01056d2:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01056d5:	fd                   	std    
f01056d6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01056d8:	fc                   	cld    
f01056d9:	eb 1a                	jmp    f01056f5 <memmove+0x62>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01056db:	89 c2                	mov    %eax,%edx
f01056dd:	09 ca                	or     %ecx,%edx
f01056df:	09 f2                	or     %esi,%edx
f01056e1:	f6 c2 03             	test   $0x3,%dl
f01056e4:	75 0a                	jne    f01056f0 <memmove+0x5d>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01056e6:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01056e9:	89 c7                	mov    %eax,%edi
f01056eb:	fc                   	cld    
f01056ec:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01056ee:	eb 05                	jmp    f01056f5 <memmove+0x62>
		else
			asm volatile("cld; rep movsb\n"
f01056f0:	89 c7                	mov    %eax,%edi
f01056f2:	fc                   	cld    
f01056f3:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01056f5:	5e                   	pop    %esi
f01056f6:	5f                   	pop    %edi
f01056f7:	5d                   	pop    %ebp
f01056f8:	c3                   	ret    

f01056f9 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01056f9:	f3 0f 1e fb          	endbr32 
f01056fd:	55                   	push   %ebp
f01056fe:	89 e5                	mov    %esp,%ebp
f0105700:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0105703:	ff 75 10             	pushl  0x10(%ebp)
f0105706:	ff 75 0c             	pushl  0xc(%ebp)
f0105709:	ff 75 08             	pushl  0x8(%ebp)
f010570c:	e8 82 ff ff ff       	call   f0105693 <memmove>
}
f0105711:	c9                   	leave  
f0105712:	c3                   	ret    

f0105713 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105713:	f3 0f 1e fb          	endbr32 
f0105717:	55                   	push   %ebp
f0105718:	89 e5                	mov    %esp,%ebp
f010571a:	56                   	push   %esi
f010571b:	53                   	push   %ebx
f010571c:	8b 45 08             	mov    0x8(%ebp),%eax
f010571f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105722:	89 c6                	mov    %eax,%esi
f0105724:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105727:	39 f0                	cmp    %esi,%eax
f0105729:	74 1c                	je     f0105747 <memcmp+0x34>
		if (*s1 != *s2)
f010572b:	0f b6 08             	movzbl (%eax),%ecx
f010572e:	0f b6 1a             	movzbl (%edx),%ebx
f0105731:	38 d9                	cmp    %bl,%cl
f0105733:	75 08                	jne    f010573d <memcmp+0x2a>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0105735:	83 c0 01             	add    $0x1,%eax
f0105738:	83 c2 01             	add    $0x1,%edx
f010573b:	eb ea                	jmp    f0105727 <memcmp+0x14>
			return (int) *s1 - (int) *s2;
f010573d:	0f b6 c1             	movzbl %cl,%eax
f0105740:	0f b6 db             	movzbl %bl,%ebx
f0105743:	29 d8                	sub    %ebx,%eax
f0105745:	eb 05                	jmp    f010574c <memcmp+0x39>
	}

	return 0;
f0105747:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010574c:	5b                   	pop    %ebx
f010574d:	5e                   	pop    %esi
f010574e:	5d                   	pop    %ebp
f010574f:	c3                   	ret    

f0105750 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105750:	f3 0f 1e fb          	endbr32 
f0105754:	55                   	push   %ebp
f0105755:	89 e5                	mov    %esp,%ebp
f0105757:	8b 45 08             	mov    0x8(%ebp),%eax
f010575a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010575d:	89 c2                	mov    %eax,%edx
f010575f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105762:	39 d0                	cmp    %edx,%eax
f0105764:	73 09                	jae    f010576f <memfind+0x1f>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105766:	38 08                	cmp    %cl,(%eax)
f0105768:	74 05                	je     f010576f <memfind+0x1f>
	for (; s < ends; s++)
f010576a:	83 c0 01             	add    $0x1,%eax
f010576d:	eb f3                	jmp    f0105762 <memfind+0x12>
			break;
	return (void *) s;
}
f010576f:	5d                   	pop    %ebp
f0105770:	c3                   	ret    

f0105771 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105771:	f3 0f 1e fb          	endbr32 
f0105775:	55                   	push   %ebp
f0105776:	89 e5                	mov    %esp,%ebp
f0105778:	57                   	push   %edi
f0105779:	56                   	push   %esi
f010577a:	53                   	push   %ebx
f010577b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010577e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105781:	eb 03                	jmp    f0105786 <strtol+0x15>
		s++;
f0105783:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0105786:	0f b6 01             	movzbl (%ecx),%eax
f0105789:	3c 20                	cmp    $0x20,%al
f010578b:	74 f6                	je     f0105783 <strtol+0x12>
f010578d:	3c 09                	cmp    $0x9,%al
f010578f:	74 f2                	je     f0105783 <strtol+0x12>

	// plus/minus sign
	if (*s == '+')
f0105791:	3c 2b                	cmp    $0x2b,%al
f0105793:	74 2a                	je     f01057bf <strtol+0x4e>
	int neg = 0;
f0105795:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f010579a:	3c 2d                	cmp    $0x2d,%al
f010579c:	74 2b                	je     f01057c9 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010579e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01057a4:	75 0f                	jne    f01057b5 <strtol+0x44>
f01057a6:	80 39 30             	cmpb   $0x30,(%ecx)
f01057a9:	74 28                	je     f01057d3 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01057ab:	85 db                	test   %ebx,%ebx
f01057ad:	b8 0a 00 00 00       	mov    $0xa,%eax
f01057b2:	0f 44 d8             	cmove  %eax,%ebx
f01057b5:	b8 00 00 00 00       	mov    $0x0,%eax
f01057ba:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01057bd:	eb 46                	jmp    f0105805 <strtol+0x94>
		s++;
f01057bf:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f01057c2:	bf 00 00 00 00       	mov    $0x0,%edi
f01057c7:	eb d5                	jmp    f010579e <strtol+0x2d>
		s++, neg = 1;
f01057c9:	83 c1 01             	add    $0x1,%ecx
f01057cc:	bf 01 00 00 00       	mov    $0x1,%edi
f01057d1:	eb cb                	jmp    f010579e <strtol+0x2d>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01057d3:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01057d7:	74 0e                	je     f01057e7 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01057d9:	85 db                	test   %ebx,%ebx
f01057db:	75 d8                	jne    f01057b5 <strtol+0x44>
		s++, base = 8;
f01057dd:	83 c1 01             	add    $0x1,%ecx
f01057e0:	bb 08 00 00 00       	mov    $0x8,%ebx
f01057e5:	eb ce                	jmp    f01057b5 <strtol+0x44>
		s += 2, base = 16;
f01057e7:	83 c1 02             	add    $0x2,%ecx
f01057ea:	bb 10 00 00 00       	mov    $0x10,%ebx
f01057ef:	eb c4                	jmp    f01057b5 <strtol+0x44>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f01057f1:	0f be d2             	movsbl %dl,%edx
f01057f4:	83 ea 30             	sub    $0x30,%edx
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01057f7:	3b 55 10             	cmp    0x10(%ebp),%edx
f01057fa:	7d 3a                	jge    f0105836 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01057fc:	83 c1 01             	add    $0x1,%ecx
f01057ff:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105803:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0105805:	0f b6 11             	movzbl (%ecx),%edx
f0105808:	8d 72 d0             	lea    -0x30(%edx),%esi
f010580b:	89 f3                	mov    %esi,%ebx
f010580d:	80 fb 09             	cmp    $0x9,%bl
f0105810:	76 df                	jbe    f01057f1 <strtol+0x80>
		else if (*s >= 'a' && *s <= 'z')
f0105812:	8d 72 9f             	lea    -0x61(%edx),%esi
f0105815:	89 f3                	mov    %esi,%ebx
f0105817:	80 fb 19             	cmp    $0x19,%bl
f010581a:	77 08                	ja     f0105824 <strtol+0xb3>
			dig = *s - 'a' + 10;
f010581c:	0f be d2             	movsbl %dl,%edx
f010581f:	83 ea 57             	sub    $0x57,%edx
f0105822:	eb d3                	jmp    f01057f7 <strtol+0x86>
		else if (*s >= 'A' && *s <= 'Z')
f0105824:	8d 72 bf             	lea    -0x41(%edx),%esi
f0105827:	89 f3                	mov    %esi,%ebx
f0105829:	80 fb 19             	cmp    $0x19,%bl
f010582c:	77 08                	ja     f0105836 <strtol+0xc5>
			dig = *s - 'A' + 10;
f010582e:	0f be d2             	movsbl %dl,%edx
f0105831:	83 ea 37             	sub    $0x37,%edx
f0105834:	eb c1                	jmp    f01057f7 <strtol+0x86>
		// we don't properly detect overflow!
	}

	if (endptr)
f0105836:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010583a:	74 05                	je     f0105841 <strtol+0xd0>
		*endptr = (char *) s;
f010583c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010583f:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0105841:	89 c2                	mov    %eax,%edx
f0105843:	f7 da                	neg    %edx
f0105845:	85 ff                	test   %edi,%edi
f0105847:	0f 45 c2             	cmovne %edx,%eax
}
f010584a:	5b                   	pop    %ebx
f010584b:	5e                   	pop    %esi
f010584c:	5f                   	pop    %edi
f010584d:	5d                   	pop    %ebp
f010584e:	c3                   	ret    
f010584f:	90                   	nop

f0105850 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0105850:	fa                   	cli    

	xorw    %ax, %ax
f0105851:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0105853:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105855:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105857:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105859:	0f 01 16             	lgdtl  (%esi)
f010585c:	74 70                	je     f01058ce <mpsearch1+0x3>
	movl    %cr0, %eax
f010585e:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0105861:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105865:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105868:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f010586e:	08 00                	or     %al,(%eax)

f0105870 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0105870:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105874:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105876:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105878:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f010587a:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f010587e:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0105880:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0105882:	b8 00 10 12 00       	mov    $0x121000,%eax
	movl    %eax, %cr3
f0105887:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f010588a:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f010588d:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0105892:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0105895:	8b 25 84 8e 23 f0    	mov    0xf0238e84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f010589b:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f01058a0:	b8 a9 01 10 f0       	mov    $0xf01001a9,%eax
	call    *%eax
f01058a5:	ff d0                	call   *%eax

f01058a7 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f01058a7:	eb fe                	jmp    f01058a7 <spin>
f01058a9:	8d 76 00             	lea    0x0(%esi),%esi

f01058ac <gdt>:
	...
f01058b4:	ff                   	(bad)  
f01058b5:	ff 00                	incl   (%eax)
f01058b7:	00 00                	add    %al,(%eax)
f01058b9:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f01058c0:	00                   	.byte 0x0
f01058c1:	92                   	xchg   %eax,%edx
f01058c2:	cf                   	iret   
	...

f01058c4 <gdtdesc>:
f01058c4:	17                   	pop    %ss
f01058c5:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f01058ca <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f01058ca:	90                   	nop

f01058cb <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f01058cb:	55                   	push   %ebp
f01058cc:	89 e5                	mov    %esp,%ebp
f01058ce:	57                   	push   %edi
f01058cf:	56                   	push   %esi
f01058d0:	53                   	push   %ebx
f01058d1:	83 ec 0c             	sub    $0xc,%esp
f01058d4:	89 c7                	mov    %eax,%edi
	if (PGNUM(pa) >= npages)
f01058d6:	a1 88 8e 23 f0       	mov    0xf0238e88,%eax
f01058db:	89 f9                	mov    %edi,%ecx
f01058dd:	c1 e9 0c             	shr    $0xc,%ecx
f01058e0:	39 c1                	cmp    %eax,%ecx
f01058e2:	73 19                	jae    f01058fd <mpsearch1+0x32>
	return (void *)(pa + KERNBASE);
f01058e4:	8d 9f 00 00 00 f0    	lea    -0x10000000(%edi),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f01058ea:	01 d7                	add    %edx,%edi
	if (PGNUM(pa) >= npages)
f01058ec:	89 fa                	mov    %edi,%edx
f01058ee:	c1 ea 0c             	shr    $0xc,%edx
f01058f1:	39 c2                	cmp    %eax,%edx
f01058f3:	73 1a                	jae    f010590f <mpsearch1+0x44>
	return (void *)(pa + KERNBASE);
f01058f5:	81 ef 00 00 00 10    	sub    $0x10000000,%edi

	for (; mp < end; mp++)
f01058fb:	eb 27                	jmp    f0105924 <mpsearch1+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01058fd:	57                   	push   %edi
f01058fe:	68 04 63 10 f0       	push   $0xf0106304
f0105903:	6a 57                	push   $0x57
f0105905:	68 21 7f 10 f0       	push   $0xf0107f21
f010590a:	e8 31 a7 ff ff       	call   f0100040 <_panic>
f010590f:	57                   	push   %edi
f0105910:	68 04 63 10 f0       	push   $0xf0106304
f0105915:	6a 57                	push   $0x57
f0105917:	68 21 7f 10 f0       	push   $0xf0107f21
f010591c:	e8 1f a7 ff ff       	call   f0100040 <_panic>
f0105921:	83 c3 10             	add    $0x10,%ebx
f0105924:	39 fb                	cmp    %edi,%ebx
f0105926:	73 30                	jae    f0105958 <mpsearch1+0x8d>
f0105928:	89 de                	mov    %ebx,%esi
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f010592a:	83 ec 04             	sub    $0x4,%esp
f010592d:	6a 04                	push   $0x4
f010592f:	68 31 7f 10 f0       	push   $0xf0107f31
f0105934:	53                   	push   %ebx
f0105935:	e8 d9 fd ff ff       	call   f0105713 <memcmp>
f010593a:	83 c4 10             	add    $0x10,%esp
f010593d:	85 c0                	test   %eax,%eax
f010593f:	75 e0                	jne    f0105921 <mpsearch1+0x56>
f0105941:	89 da                	mov    %ebx,%edx
	for (i = 0; i < len; i++)
f0105943:	83 c6 10             	add    $0x10,%esi
		sum += ((uint8_t *)addr)[i];
f0105946:	0f b6 0a             	movzbl (%edx),%ecx
f0105949:	01 c8                	add    %ecx,%eax
f010594b:	83 c2 01             	add    $0x1,%edx
	for (i = 0; i < len; i++)
f010594e:	39 f2                	cmp    %esi,%edx
f0105950:	75 f4                	jne    f0105946 <mpsearch1+0x7b>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105952:	84 c0                	test   %al,%al
f0105954:	75 cb                	jne    f0105921 <mpsearch1+0x56>
f0105956:	eb 05                	jmp    f010595d <mpsearch1+0x92>
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0105958:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f010595d:	89 d8                	mov    %ebx,%eax
f010595f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105962:	5b                   	pop    %ebx
f0105963:	5e                   	pop    %esi
f0105964:	5f                   	pop    %edi
f0105965:	5d                   	pop    %ebp
f0105966:	c3                   	ret    

f0105967 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105967:	f3 0f 1e fb          	endbr32 
f010596b:	55                   	push   %ebp
f010596c:	89 e5                	mov    %esp,%ebp
f010596e:	57                   	push   %edi
f010596f:	56                   	push   %esi
f0105970:	53                   	push   %ebx
f0105971:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105974:	c7 05 c0 93 23 f0 20 	movl   $0xf0239020,0xf02393c0
f010597b:	90 23 f0 
	if (PGNUM(pa) >= npages)
f010597e:	83 3d 88 8e 23 f0 00 	cmpl   $0x0,0xf0238e88
f0105985:	0f 84 a3 00 00 00    	je     f0105a2e <mp_init+0xc7>
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f010598b:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105992:	85 c0                	test   %eax,%eax
f0105994:	0f 84 aa 00 00 00    	je     f0105a44 <mp_init+0xdd>
		p <<= 4;	// Translate from segment to PA
f010599a:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f010599d:	ba 00 04 00 00       	mov    $0x400,%edx
f01059a2:	e8 24 ff ff ff       	call   f01058cb <mpsearch1>
f01059a7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01059aa:	85 c0                	test   %eax,%eax
f01059ac:	75 1a                	jne    f01059c8 <mp_init+0x61>
	return mpsearch1(0xF0000, 0x10000);
f01059ae:	ba 00 00 01 00       	mov    $0x10000,%edx
f01059b3:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f01059b8:	e8 0e ff ff ff       	call   f01058cb <mpsearch1>
f01059bd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if ((mp = mpsearch()) == 0)
f01059c0:	85 c0                	test   %eax,%eax
f01059c2:	0f 84 35 02 00 00    	je     f0105bfd <mp_init+0x296>
	if (mp->physaddr == 0 || mp->type != 0) {
f01059c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01059cb:	8b 58 04             	mov    0x4(%eax),%ebx
f01059ce:	85 db                	test   %ebx,%ebx
f01059d0:	0f 84 97 00 00 00    	je     f0105a6d <mp_init+0x106>
f01059d6:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f01059da:	0f 85 8d 00 00 00    	jne    f0105a6d <mp_init+0x106>
f01059e0:	89 d8                	mov    %ebx,%eax
f01059e2:	c1 e8 0c             	shr    $0xc,%eax
f01059e5:	3b 05 88 8e 23 f0    	cmp    0xf0238e88,%eax
f01059eb:	0f 83 91 00 00 00    	jae    f0105a82 <mp_init+0x11b>
	return (void *)(pa + KERNBASE);
f01059f1:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
f01059f7:	89 de                	mov    %ebx,%esi
	if (memcmp(conf, "PCMP", 4) != 0) {
f01059f9:	83 ec 04             	sub    $0x4,%esp
f01059fc:	6a 04                	push   $0x4
f01059fe:	68 36 7f 10 f0       	push   $0xf0107f36
f0105a03:	53                   	push   %ebx
f0105a04:	e8 0a fd ff ff       	call   f0105713 <memcmp>
f0105a09:	83 c4 10             	add    $0x10,%esp
f0105a0c:	85 c0                	test   %eax,%eax
f0105a0e:	0f 85 83 00 00 00    	jne    f0105a97 <mp_init+0x130>
f0105a14:	0f b7 7b 04          	movzwl 0x4(%ebx),%edi
f0105a18:	01 df                	add    %ebx,%edi
	sum = 0;
f0105a1a:	89 c2                	mov    %eax,%edx
	for (i = 0; i < len; i++)
f0105a1c:	39 fb                	cmp    %edi,%ebx
f0105a1e:	0f 84 88 00 00 00    	je     f0105aac <mp_init+0x145>
		sum += ((uint8_t *)addr)[i];
f0105a24:	0f b6 0b             	movzbl (%ebx),%ecx
f0105a27:	01 ca                	add    %ecx,%edx
f0105a29:	83 c3 01             	add    $0x1,%ebx
f0105a2c:	eb ee                	jmp    f0105a1c <mp_init+0xb5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105a2e:	68 00 04 00 00       	push   $0x400
f0105a33:	68 04 63 10 f0       	push   $0xf0106304
f0105a38:	6a 6f                	push   $0x6f
f0105a3a:	68 21 7f 10 f0       	push   $0xf0107f21
f0105a3f:	e8 fc a5 ff ff       	call   f0100040 <_panic>
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0105a44:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105a4b:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105a4e:	2d 00 04 00 00       	sub    $0x400,%eax
f0105a53:	ba 00 04 00 00       	mov    $0x400,%edx
f0105a58:	e8 6e fe ff ff       	call   f01058cb <mpsearch1>
f0105a5d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105a60:	85 c0                	test   %eax,%eax
f0105a62:	0f 85 60 ff ff ff    	jne    f01059c8 <mp_init+0x61>
f0105a68:	e9 41 ff ff ff       	jmp    f01059ae <mp_init+0x47>
		cprintf("SMP: Default configurations not implemented\n");
f0105a6d:	83 ec 0c             	sub    $0xc,%esp
f0105a70:	68 94 7d 10 f0       	push   $0xf0107d94
f0105a75:	e8 53 df ff ff       	call   f01039cd <cprintf>
		return NULL;
f0105a7a:	83 c4 10             	add    $0x10,%esp
f0105a7d:	e9 7b 01 00 00       	jmp    f0105bfd <mp_init+0x296>
f0105a82:	53                   	push   %ebx
f0105a83:	68 04 63 10 f0       	push   $0xf0106304
f0105a88:	68 90 00 00 00       	push   $0x90
f0105a8d:	68 21 7f 10 f0       	push   $0xf0107f21
f0105a92:	e8 a9 a5 ff ff       	call   f0100040 <_panic>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105a97:	83 ec 0c             	sub    $0xc,%esp
f0105a9a:	68 c4 7d 10 f0       	push   $0xf0107dc4
f0105a9f:	e8 29 df ff ff       	call   f01039cd <cprintf>
		return NULL;
f0105aa4:	83 c4 10             	add    $0x10,%esp
f0105aa7:	e9 51 01 00 00       	jmp    f0105bfd <mp_init+0x296>
	if (sum(conf, conf->length) != 0) {
f0105aac:	84 d2                	test   %dl,%dl
f0105aae:	75 22                	jne    f0105ad2 <mp_init+0x16b>
	if (conf->version != 1 && conf->version != 4) {
f0105ab0:	0f b6 56 06          	movzbl 0x6(%esi),%edx
f0105ab4:	80 fa 01             	cmp    $0x1,%dl
f0105ab7:	74 05                	je     f0105abe <mp_init+0x157>
f0105ab9:	80 fa 04             	cmp    $0x4,%dl
f0105abc:	75 29                	jne    f0105ae7 <mp_init+0x180>
f0105abe:	0f b7 4e 28          	movzwl 0x28(%esi),%ecx
f0105ac2:	01 d9                	add    %ebx,%ecx
	for (i = 0; i < len; i++)
f0105ac4:	39 d9                	cmp    %ebx,%ecx
f0105ac6:	74 38                	je     f0105b00 <mp_init+0x199>
		sum += ((uint8_t *)addr)[i];
f0105ac8:	0f b6 13             	movzbl (%ebx),%edx
f0105acb:	01 d0                	add    %edx,%eax
f0105acd:	83 c3 01             	add    $0x1,%ebx
f0105ad0:	eb f2                	jmp    f0105ac4 <mp_init+0x15d>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105ad2:	83 ec 0c             	sub    $0xc,%esp
f0105ad5:	68 f8 7d 10 f0       	push   $0xf0107df8
f0105ada:	e8 ee de ff ff       	call   f01039cd <cprintf>
		return NULL;
f0105adf:	83 c4 10             	add    $0x10,%esp
f0105ae2:	e9 16 01 00 00       	jmp    f0105bfd <mp_init+0x296>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105ae7:	83 ec 08             	sub    $0x8,%esp
f0105aea:	0f b6 d2             	movzbl %dl,%edx
f0105aed:	52                   	push   %edx
f0105aee:	68 1c 7e 10 f0       	push   $0xf0107e1c
f0105af3:	e8 d5 de ff ff       	call   f01039cd <cprintf>
		return NULL;
f0105af8:	83 c4 10             	add    $0x10,%esp
f0105afb:	e9 fd 00 00 00       	jmp    f0105bfd <mp_init+0x296>
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105b00:	02 46 2a             	add    0x2a(%esi),%al
f0105b03:	75 1c                	jne    f0105b21 <mp_init+0x1ba>
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
f0105b05:	c7 05 00 90 23 f0 01 	movl   $0x1,0xf0239000
f0105b0c:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105b0f:	8b 46 24             	mov    0x24(%esi),%eax
f0105b12:	a3 00 a0 27 f0       	mov    %eax,0xf027a000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105b17:	8d 7e 2c             	lea    0x2c(%esi),%edi
f0105b1a:	bb 00 00 00 00       	mov    $0x0,%ebx
f0105b1f:	eb 4d                	jmp    f0105b6e <mp_init+0x207>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105b21:	83 ec 0c             	sub    $0xc,%esp
f0105b24:	68 3c 7e 10 f0       	push   $0xf0107e3c
f0105b29:	e8 9f de ff ff       	call   f01039cd <cprintf>
		return NULL;
f0105b2e:	83 c4 10             	add    $0x10,%esp
f0105b31:	e9 c7 00 00 00       	jmp    f0105bfd <mp_init+0x296>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0105b36:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0105b3a:	74 11                	je     f0105b4d <mp_init+0x1e6>
				bootcpu = &cpus[ncpu];
f0105b3c:	6b 05 c4 93 23 f0 74 	imul   $0x74,0xf02393c4,%eax
f0105b43:	05 20 90 23 f0       	add    $0xf0239020,%eax
f0105b48:	a3 c0 93 23 f0       	mov    %eax,0xf02393c0
			if (ncpu < NCPU) {
f0105b4d:	a1 c4 93 23 f0       	mov    0xf02393c4,%eax
f0105b52:	83 f8 07             	cmp    $0x7,%eax
f0105b55:	7f 33                	jg     f0105b8a <mp_init+0x223>
				cpus[ncpu].cpu_id = ncpu;
f0105b57:	6b d0 74             	imul   $0x74,%eax,%edx
f0105b5a:	88 82 20 90 23 f0    	mov    %al,-0xfdc6fe0(%edx)
				ncpu++;
f0105b60:	83 c0 01             	add    $0x1,%eax
f0105b63:	a3 c4 93 23 f0       	mov    %eax,0xf02393c4
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105b68:	83 c7 14             	add    $0x14,%edi
	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105b6b:	83 c3 01             	add    $0x1,%ebx
f0105b6e:	0f b7 46 22          	movzwl 0x22(%esi),%eax
f0105b72:	39 d8                	cmp    %ebx,%eax
f0105b74:	76 4f                	jbe    f0105bc5 <mp_init+0x25e>
		switch (*p) {
f0105b76:	0f b6 07             	movzbl (%edi),%eax
f0105b79:	84 c0                	test   %al,%al
f0105b7b:	74 b9                	je     f0105b36 <mp_init+0x1cf>
f0105b7d:	8d 50 ff             	lea    -0x1(%eax),%edx
f0105b80:	80 fa 03             	cmp    $0x3,%dl
f0105b83:	77 1c                	ja     f0105ba1 <mp_init+0x23a>
			continue;
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105b85:	83 c7 08             	add    $0x8,%edi
			continue;
f0105b88:	eb e1                	jmp    f0105b6b <mp_init+0x204>
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105b8a:	83 ec 08             	sub    $0x8,%esp
f0105b8d:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0105b91:	50                   	push   %eax
f0105b92:	68 6c 7e 10 f0       	push   $0xf0107e6c
f0105b97:	e8 31 de ff ff       	call   f01039cd <cprintf>
f0105b9c:	83 c4 10             	add    $0x10,%esp
f0105b9f:	eb c7                	jmp    f0105b68 <mp_init+0x201>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105ba1:	83 ec 08             	sub    $0x8,%esp
		switch (*p) {
f0105ba4:	0f b6 c0             	movzbl %al,%eax
			cprintf("mpinit: unknown config type %x\n", *p);
f0105ba7:	50                   	push   %eax
f0105ba8:	68 94 7e 10 f0       	push   $0xf0107e94
f0105bad:	e8 1b de ff ff       	call   f01039cd <cprintf>
			ismp = 0;
f0105bb2:	c7 05 00 90 23 f0 00 	movl   $0x0,0xf0239000
f0105bb9:	00 00 00 
			i = conf->entry;
f0105bbc:	0f b7 5e 22          	movzwl 0x22(%esi),%ebx
f0105bc0:	83 c4 10             	add    $0x10,%esp
f0105bc3:	eb a6                	jmp    f0105b6b <mp_init+0x204>
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105bc5:	a1 c0 93 23 f0       	mov    0xf02393c0,%eax
f0105bca:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0105bd1:	83 3d 00 90 23 f0 00 	cmpl   $0x0,0xf0239000
f0105bd8:	74 2b                	je     f0105c05 <mp_init+0x29e>
		ncpu = 1;
		lapicaddr = 0;
		cprintf("SMP: configuration not found, SMP disabled\n");
		return;
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0105bda:	83 ec 04             	sub    $0x4,%esp
f0105bdd:	ff 35 c4 93 23 f0    	pushl  0xf02393c4
f0105be3:	0f b6 00             	movzbl (%eax),%eax
f0105be6:	50                   	push   %eax
f0105be7:	68 3b 7f 10 f0       	push   $0xf0107f3b
f0105bec:	e8 dc dd ff ff       	call   f01039cd <cprintf>

	if (mp->imcrp) {
f0105bf1:	83 c4 10             	add    $0x10,%esp
f0105bf4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105bf7:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105bfb:	75 2e                	jne    f0105c2b <mp_init+0x2c4>
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f0105bfd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105c00:	5b                   	pop    %ebx
f0105c01:	5e                   	pop    %esi
f0105c02:	5f                   	pop    %edi
f0105c03:	5d                   	pop    %ebp
f0105c04:	c3                   	ret    
		ncpu = 1;
f0105c05:	c7 05 c4 93 23 f0 01 	movl   $0x1,0xf02393c4
f0105c0c:	00 00 00 
		lapicaddr = 0;
f0105c0f:	c7 05 00 a0 27 f0 00 	movl   $0x0,0xf027a000
f0105c16:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105c19:	83 ec 0c             	sub    $0xc,%esp
f0105c1c:	68 b4 7e 10 f0       	push   $0xf0107eb4
f0105c21:	e8 a7 dd ff ff       	call   f01039cd <cprintf>
		return;
f0105c26:	83 c4 10             	add    $0x10,%esp
f0105c29:	eb d2                	jmp    f0105bfd <mp_init+0x296>
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105c2b:	83 ec 0c             	sub    $0xc,%esp
f0105c2e:	68 e0 7e 10 f0       	push   $0xf0107ee0
f0105c33:	e8 95 dd ff ff       	call   f01039cd <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105c38:	b8 70 00 00 00       	mov    $0x70,%eax
f0105c3d:	ba 22 00 00 00       	mov    $0x22,%edx
f0105c42:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0105c43:	ba 23 00 00 00       	mov    $0x23,%edx
f0105c48:	ec                   	in     (%dx),%al
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0105c49:	83 c8 01             	or     $0x1,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105c4c:	ee                   	out    %al,(%dx)
}
f0105c4d:	83 c4 10             	add    $0x10,%esp
f0105c50:	eb ab                	jmp    f0105bfd <mp_init+0x296>

f0105c52 <lapicw>:
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
	lapic[index] = value;
f0105c52:	8b 0d 04 a0 27 f0    	mov    0xf027a004,%ecx
f0105c58:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0105c5b:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105c5d:	a1 04 a0 27 f0       	mov    0xf027a004,%eax
f0105c62:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105c65:	c3                   	ret    

f0105c66 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0105c66:	f3 0f 1e fb          	endbr32 
	if (lapic)
f0105c6a:	8b 15 04 a0 27 f0    	mov    0xf027a004,%edx
		return lapic[ID] >> 24;
	return 0;
f0105c70:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lapic)
f0105c75:	85 d2                	test   %edx,%edx
f0105c77:	74 06                	je     f0105c7f <cpunum+0x19>
		return lapic[ID] >> 24;
f0105c79:	8b 42 20             	mov    0x20(%edx),%eax
f0105c7c:	c1 e8 18             	shr    $0x18,%eax
}
f0105c7f:	c3                   	ret    

f0105c80 <lapic_init>:
{
f0105c80:	f3 0f 1e fb          	endbr32 
	if (!lapicaddr)
f0105c84:	a1 00 a0 27 f0       	mov    0xf027a000,%eax
f0105c89:	85 c0                	test   %eax,%eax
f0105c8b:	75 01                	jne    f0105c8e <lapic_init+0xe>
f0105c8d:	c3                   	ret    
{
f0105c8e:	55                   	push   %ebp
f0105c8f:	89 e5                	mov    %esp,%ebp
f0105c91:	83 ec 10             	sub    $0x10,%esp
	lapic = mmio_map_region(lapicaddr, 4096);
f0105c94:	68 00 10 00 00       	push   $0x1000
f0105c99:	50                   	push   %eax
f0105c9a:	e8 12 b6 ff ff       	call   f01012b1 <mmio_map_region>
f0105c9f:	a3 04 a0 27 f0       	mov    %eax,0xf027a004
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105ca4:	ba 27 01 00 00       	mov    $0x127,%edx
f0105ca9:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105cae:	e8 9f ff ff ff       	call   f0105c52 <lapicw>
	lapicw(TDCR, X1);
f0105cb3:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105cb8:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105cbd:	e8 90 ff ff ff       	call   f0105c52 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105cc2:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105cc7:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105ccc:	e8 81 ff ff ff       	call   f0105c52 <lapicw>
	lapicw(TICR, 10000000); 
f0105cd1:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105cd6:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105cdb:	e8 72 ff ff ff       	call   f0105c52 <lapicw>
	if (thiscpu != bootcpu)
f0105ce0:	e8 81 ff ff ff       	call   f0105c66 <cpunum>
f0105ce5:	6b c0 74             	imul   $0x74,%eax,%eax
f0105ce8:	05 20 90 23 f0       	add    $0xf0239020,%eax
f0105ced:	83 c4 10             	add    $0x10,%esp
f0105cf0:	39 05 c0 93 23 f0    	cmp    %eax,0xf02393c0
f0105cf6:	74 0f                	je     f0105d07 <lapic_init+0x87>
		lapicw(LINT0, MASKED);
f0105cf8:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105cfd:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105d02:	e8 4b ff ff ff       	call   f0105c52 <lapicw>
	lapicw(LINT1, MASKED);
f0105d07:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105d0c:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105d11:	e8 3c ff ff ff       	call   f0105c52 <lapicw>
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105d16:	a1 04 a0 27 f0       	mov    0xf027a004,%eax
f0105d1b:	8b 40 30             	mov    0x30(%eax),%eax
f0105d1e:	c1 e8 10             	shr    $0x10,%eax
f0105d21:	a8 fc                	test   $0xfc,%al
f0105d23:	75 7c                	jne    f0105da1 <lapic_init+0x121>
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105d25:	ba 33 00 00 00       	mov    $0x33,%edx
f0105d2a:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105d2f:	e8 1e ff ff ff       	call   f0105c52 <lapicw>
	lapicw(ESR, 0);
f0105d34:	ba 00 00 00 00       	mov    $0x0,%edx
f0105d39:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105d3e:	e8 0f ff ff ff       	call   f0105c52 <lapicw>
	lapicw(ESR, 0);
f0105d43:	ba 00 00 00 00       	mov    $0x0,%edx
f0105d48:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105d4d:	e8 00 ff ff ff       	call   f0105c52 <lapicw>
	lapicw(EOI, 0);
f0105d52:	ba 00 00 00 00       	mov    $0x0,%edx
f0105d57:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105d5c:	e8 f1 fe ff ff       	call   f0105c52 <lapicw>
	lapicw(ICRHI, 0);
f0105d61:	ba 00 00 00 00       	mov    $0x0,%edx
f0105d66:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105d6b:	e8 e2 fe ff ff       	call   f0105c52 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105d70:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105d75:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105d7a:	e8 d3 fe ff ff       	call   f0105c52 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105d7f:	8b 15 04 a0 27 f0    	mov    0xf027a004,%edx
f0105d85:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105d8b:	f6 c4 10             	test   $0x10,%ah
f0105d8e:	75 f5                	jne    f0105d85 <lapic_init+0x105>
	lapicw(TPR, 0);
f0105d90:	ba 00 00 00 00       	mov    $0x0,%edx
f0105d95:	b8 20 00 00 00       	mov    $0x20,%eax
f0105d9a:	e8 b3 fe ff ff       	call   f0105c52 <lapicw>
}
f0105d9f:	c9                   	leave  
f0105da0:	c3                   	ret    
		lapicw(PCINT, MASKED);
f0105da1:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105da6:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105dab:	e8 a2 fe ff ff       	call   f0105c52 <lapicw>
f0105db0:	e9 70 ff ff ff       	jmp    f0105d25 <lapic_init+0xa5>

f0105db5 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105db5:	f3 0f 1e fb          	endbr32 
	if (lapic)
f0105db9:	83 3d 04 a0 27 f0 00 	cmpl   $0x0,0xf027a004
f0105dc0:	74 17                	je     f0105dd9 <lapic_eoi+0x24>
{
f0105dc2:	55                   	push   %ebp
f0105dc3:	89 e5                	mov    %esp,%ebp
f0105dc5:	83 ec 08             	sub    $0x8,%esp
		lapicw(EOI, 0);
f0105dc8:	ba 00 00 00 00       	mov    $0x0,%edx
f0105dcd:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105dd2:	e8 7b fe ff ff       	call   f0105c52 <lapicw>
}
f0105dd7:	c9                   	leave  
f0105dd8:	c3                   	ret    
f0105dd9:	c3                   	ret    

f0105dda <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105dda:	f3 0f 1e fb          	endbr32 
f0105dde:	55                   	push   %ebp
f0105ddf:	89 e5                	mov    %esp,%ebp
f0105de1:	56                   	push   %esi
f0105de2:	53                   	push   %ebx
f0105de3:	8b 75 08             	mov    0x8(%ebp),%esi
f0105de6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105de9:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105dee:	ba 70 00 00 00       	mov    $0x70,%edx
f0105df3:	ee                   	out    %al,(%dx)
f0105df4:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105df9:	ba 71 00 00 00       	mov    $0x71,%edx
f0105dfe:	ee                   	out    %al,(%dx)
	if (PGNUM(pa) >= npages)
f0105dff:	83 3d 88 8e 23 f0 00 	cmpl   $0x0,0xf0238e88
f0105e06:	74 7e                	je     f0105e86 <lapic_startap+0xac>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105e08:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105e0f:	00 00 
	wrv[1] = addr >> 4;
f0105e11:	89 d8                	mov    %ebx,%eax
f0105e13:	c1 e8 04             	shr    $0x4,%eax
f0105e16:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105e1c:	c1 e6 18             	shl    $0x18,%esi
f0105e1f:	89 f2                	mov    %esi,%edx
f0105e21:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105e26:	e8 27 fe ff ff       	call   f0105c52 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105e2b:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105e30:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105e35:	e8 18 fe ff ff       	call   f0105c52 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105e3a:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105e3f:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105e44:	e8 09 fe ff ff       	call   f0105c52 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105e49:	c1 eb 0c             	shr    $0xc,%ebx
f0105e4c:	80 cf 06             	or     $0x6,%bh
		lapicw(ICRHI, apicid << 24);
f0105e4f:	89 f2                	mov    %esi,%edx
f0105e51:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105e56:	e8 f7 fd ff ff       	call   f0105c52 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105e5b:	89 da                	mov    %ebx,%edx
f0105e5d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105e62:	e8 eb fd ff ff       	call   f0105c52 <lapicw>
		lapicw(ICRHI, apicid << 24);
f0105e67:	89 f2                	mov    %esi,%edx
f0105e69:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105e6e:	e8 df fd ff ff       	call   f0105c52 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105e73:	89 da                	mov    %ebx,%edx
f0105e75:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105e7a:	e8 d3 fd ff ff       	call   f0105c52 <lapicw>
		microdelay(200);
	}
}
f0105e7f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105e82:	5b                   	pop    %ebx
f0105e83:	5e                   	pop    %esi
f0105e84:	5d                   	pop    %ebp
f0105e85:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105e86:	68 67 04 00 00       	push   $0x467
f0105e8b:	68 04 63 10 f0       	push   $0xf0106304
f0105e90:	68 98 00 00 00       	push   $0x98
f0105e95:	68 58 7f 10 f0       	push   $0xf0107f58
f0105e9a:	e8 a1 a1 ff ff       	call   f0100040 <_panic>

f0105e9f <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105e9f:	f3 0f 1e fb          	endbr32 
f0105ea3:	55                   	push   %ebp
f0105ea4:	89 e5                	mov    %esp,%ebp
f0105ea6:	83 ec 08             	sub    $0x8,%esp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105ea9:	8b 55 08             	mov    0x8(%ebp),%edx
f0105eac:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105eb2:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105eb7:	e8 96 fd ff ff       	call   f0105c52 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105ebc:	8b 15 04 a0 27 f0    	mov    0xf027a004,%edx
f0105ec2:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105ec8:	f6 c4 10             	test   $0x10,%ah
f0105ecb:	75 f5                	jne    f0105ec2 <lapic_ipi+0x23>
		;
}
f0105ecd:	c9                   	leave  
f0105ece:	c3                   	ret    

f0105ecf <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105ecf:	f3 0f 1e fb          	endbr32 
f0105ed3:	55                   	push   %ebp
f0105ed4:	89 e5                	mov    %esp,%ebp
f0105ed6:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105ed9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105edf:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105ee2:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105ee5:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105eec:	5d                   	pop    %ebp
f0105eed:	c3                   	ret    

f0105eee <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105eee:	f3 0f 1e fb          	endbr32 
f0105ef2:	55                   	push   %ebp
f0105ef3:	89 e5                	mov    %esp,%ebp
f0105ef5:	56                   	push   %esi
f0105ef6:	53                   	push   %ebx
f0105ef7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	return lock->locked && lock->cpu == thiscpu;
f0105efa:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105efd:	75 07                	jne    f0105f06 <spin_lock+0x18>
	asm volatile("lock; xchgl %0, %1"
f0105eff:	ba 01 00 00 00       	mov    $0x1,%edx
f0105f04:	eb 34                	jmp    f0105f3a <spin_lock+0x4c>
f0105f06:	8b 73 08             	mov    0x8(%ebx),%esi
f0105f09:	e8 58 fd ff ff       	call   f0105c66 <cpunum>
f0105f0e:	6b c0 74             	imul   $0x74,%eax,%eax
f0105f11:	05 20 90 23 f0       	add    $0xf0239020,%eax
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105f16:	39 c6                	cmp    %eax,%esi
f0105f18:	75 e5                	jne    f0105eff <spin_lock+0x11>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105f1a:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105f1d:	e8 44 fd ff ff       	call   f0105c66 <cpunum>
f0105f22:	83 ec 0c             	sub    $0xc,%esp
f0105f25:	53                   	push   %ebx
f0105f26:	50                   	push   %eax
f0105f27:	68 68 7f 10 f0       	push   $0xf0107f68
f0105f2c:	6a 41                	push   $0x41
f0105f2e:	68 ca 7f 10 f0       	push   $0xf0107fca
f0105f33:	e8 08 a1 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105f38:	f3 90                	pause  
f0105f3a:	89 d0                	mov    %edx,%eax
f0105f3c:	f0 87 03             	lock xchg %eax,(%ebx)
	while (xchg(&lk->locked, 1) != 0)
f0105f3f:	85 c0                	test   %eax,%eax
f0105f41:	75 f5                	jne    f0105f38 <spin_lock+0x4a>

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105f43:	e8 1e fd ff ff       	call   f0105c66 <cpunum>
f0105f48:	6b c0 74             	imul   $0x74,%eax,%eax
f0105f4b:	05 20 90 23 f0       	add    $0xf0239020,%eax
f0105f50:	89 43 08             	mov    %eax,0x8(%ebx)
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0105f53:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f0105f55:	b8 00 00 00 00       	mov    $0x0,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105f5a:	83 f8 09             	cmp    $0x9,%eax
f0105f5d:	7f 21                	jg     f0105f80 <spin_lock+0x92>
f0105f5f:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105f65:	76 19                	jbe    f0105f80 <spin_lock+0x92>
		pcs[i] = ebp[1];          // saved %eip
f0105f67:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105f6a:	89 4c 83 0c          	mov    %ecx,0xc(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105f6e:	8b 12                	mov    (%edx),%edx
	for (i = 0; i < 10; i++){
f0105f70:	83 c0 01             	add    $0x1,%eax
f0105f73:	eb e5                	jmp    f0105f5a <spin_lock+0x6c>
		pcs[i] = 0;
f0105f75:	c7 44 83 0c 00 00 00 	movl   $0x0,0xc(%ebx,%eax,4)
f0105f7c:	00 
	for (; i < 10; i++)
f0105f7d:	83 c0 01             	add    $0x1,%eax
f0105f80:	83 f8 09             	cmp    $0x9,%eax
f0105f83:	7e f0                	jle    f0105f75 <spin_lock+0x87>
	get_caller_pcs(lk->pcs);
#endif
}
f0105f85:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105f88:	5b                   	pop    %ebx
f0105f89:	5e                   	pop    %esi
f0105f8a:	5d                   	pop    %ebp
f0105f8b:	c3                   	ret    

f0105f8c <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105f8c:	f3 0f 1e fb          	endbr32 
f0105f90:	55                   	push   %ebp
f0105f91:	89 e5                	mov    %esp,%ebp
f0105f93:	57                   	push   %edi
f0105f94:	56                   	push   %esi
f0105f95:	53                   	push   %ebx
f0105f96:	83 ec 4c             	sub    $0x4c,%esp
f0105f99:	8b 75 08             	mov    0x8(%ebp),%esi
	return lock->locked && lock->cpu == thiscpu;
f0105f9c:	83 3e 00             	cmpl   $0x0,(%esi)
f0105f9f:	75 35                	jne    f0105fd6 <spin_unlock+0x4a>
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105fa1:	83 ec 04             	sub    $0x4,%esp
f0105fa4:	6a 28                	push   $0x28
f0105fa6:	8d 46 0c             	lea    0xc(%esi),%eax
f0105fa9:	50                   	push   %eax
f0105faa:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105fad:	53                   	push   %ebx
f0105fae:	e8 e0 f6 ff ff       	call   f0105693 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105fb3:	8b 46 08             	mov    0x8(%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105fb6:	0f b6 38             	movzbl (%eax),%edi
f0105fb9:	8b 76 04             	mov    0x4(%esi),%esi
f0105fbc:	e8 a5 fc ff ff       	call   f0105c66 <cpunum>
f0105fc1:	57                   	push   %edi
f0105fc2:	56                   	push   %esi
f0105fc3:	50                   	push   %eax
f0105fc4:	68 94 7f 10 f0       	push   $0xf0107f94
f0105fc9:	e8 ff d9 ff ff       	call   f01039cd <cprintf>
f0105fce:	83 c4 20             	add    $0x20,%esp
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105fd1:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105fd4:	eb 4e                	jmp    f0106024 <spin_unlock+0x98>
	return lock->locked && lock->cpu == thiscpu;
f0105fd6:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105fd9:	e8 88 fc ff ff       	call   f0105c66 <cpunum>
f0105fde:	6b c0 74             	imul   $0x74,%eax,%eax
f0105fe1:	05 20 90 23 f0       	add    $0xf0239020,%eax
	if (!holding(lk)) {
f0105fe6:	39 c3                	cmp    %eax,%ebx
f0105fe8:	75 b7                	jne    f0105fa1 <spin_unlock+0x15>
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
	}

	lk->pcs[0] = 0;
f0105fea:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105ff1:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
	asm volatile("lock; xchgl %0, %1"
f0105ff8:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ffd:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0106000:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0106003:	5b                   	pop    %ebx
f0106004:	5e                   	pop    %esi
f0106005:	5f                   	pop    %edi
f0106006:	5d                   	pop    %ebp
f0106007:	c3                   	ret    
				cprintf("  %08x\n", pcs[i]);
f0106008:	83 ec 08             	sub    $0x8,%esp
f010600b:	ff 36                	pushl  (%esi)
f010600d:	68 f1 7f 10 f0       	push   $0xf0107ff1
f0106012:	e8 b6 d9 ff ff       	call   f01039cd <cprintf>
f0106017:	83 c4 10             	add    $0x10,%esp
f010601a:	83 c3 04             	add    $0x4,%ebx
		for (i = 0; i < 10 && pcs[i]; i++) {
f010601d:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0106020:	39 c3                	cmp    %eax,%ebx
f0106022:	74 40                	je     f0106064 <spin_unlock+0xd8>
f0106024:	89 de                	mov    %ebx,%esi
f0106026:	8b 03                	mov    (%ebx),%eax
f0106028:	85 c0                	test   %eax,%eax
f010602a:	74 38                	je     f0106064 <spin_unlock+0xd8>
			if (debuginfo_eip(pcs[i], &info) >= 0)
f010602c:	83 ec 08             	sub    $0x8,%esp
f010602f:	57                   	push   %edi
f0106030:	50                   	push   %eax
f0106031:	e8 d8 ea ff ff       	call   f0104b0e <debuginfo_eip>
f0106036:	83 c4 10             	add    $0x10,%esp
f0106039:	85 c0                	test   %eax,%eax
f010603b:	78 cb                	js     f0106008 <spin_unlock+0x7c>
					pcs[i] - info.eip_fn_addr);
f010603d:	8b 06                	mov    (%esi),%eax
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f010603f:	83 ec 04             	sub    $0x4,%esp
f0106042:	89 c2                	mov    %eax,%edx
f0106044:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0106047:	52                   	push   %edx
f0106048:	ff 75 b0             	pushl  -0x50(%ebp)
f010604b:	ff 75 b4             	pushl  -0x4c(%ebp)
f010604e:	ff 75 ac             	pushl  -0x54(%ebp)
f0106051:	ff 75 a8             	pushl  -0x58(%ebp)
f0106054:	50                   	push   %eax
f0106055:	68 da 7f 10 f0       	push   $0xf0107fda
f010605a:	e8 6e d9 ff ff       	call   f01039cd <cprintf>
f010605f:	83 c4 20             	add    $0x20,%esp
f0106062:	eb b6                	jmp    f010601a <spin_unlock+0x8e>
		panic("spin_unlock");
f0106064:	83 ec 04             	sub    $0x4,%esp
f0106067:	68 f9 7f 10 f0       	push   $0xf0107ff9
f010606c:	6a 67                	push   $0x67
f010606e:	68 ca 7f 10 f0       	push   $0xf0107fca
f0106073:	e8 c8 9f ff ff       	call   f0100040 <_panic>
f0106078:	66 90                	xchg   %ax,%ax
f010607a:	66 90                	xchg   %ax,%ax
f010607c:	66 90                	xchg   %ax,%ax
f010607e:	66 90                	xchg   %ax,%ax

f0106080 <__udivdi3>:
f0106080:	f3 0f 1e fb          	endbr32 
f0106084:	55                   	push   %ebp
f0106085:	57                   	push   %edi
f0106086:	56                   	push   %esi
f0106087:	53                   	push   %ebx
f0106088:	83 ec 1c             	sub    $0x1c,%esp
f010608b:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010608f:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0106093:	8b 74 24 34          	mov    0x34(%esp),%esi
f0106097:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f010609b:	85 d2                	test   %edx,%edx
f010609d:	75 19                	jne    f01060b8 <__udivdi3+0x38>
f010609f:	39 f3                	cmp    %esi,%ebx
f01060a1:	76 4d                	jbe    f01060f0 <__udivdi3+0x70>
f01060a3:	31 ff                	xor    %edi,%edi
f01060a5:	89 e8                	mov    %ebp,%eax
f01060a7:	89 f2                	mov    %esi,%edx
f01060a9:	f7 f3                	div    %ebx
f01060ab:	89 fa                	mov    %edi,%edx
f01060ad:	83 c4 1c             	add    $0x1c,%esp
f01060b0:	5b                   	pop    %ebx
f01060b1:	5e                   	pop    %esi
f01060b2:	5f                   	pop    %edi
f01060b3:	5d                   	pop    %ebp
f01060b4:	c3                   	ret    
f01060b5:	8d 76 00             	lea    0x0(%esi),%esi
f01060b8:	39 f2                	cmp    %esi,%edx
f01060ba:	76 14                	jbe    f01060d0 <__udivdi3+0x50>
f01060bc:	31 ff                	xor    %edi,%edi
f01060be:	31 c0                	xor    %eax,%eax
f01060c0:	89 fa                	mov    %edi,%edx
f01060c2:	83 c4 1c             	add    $0x1c,%esp
f01060c5:	5b                   	pop    %ebx
f01060c6:	5e                   	pop    %esi
f01060c7:	5f                   	pop    %edi
f01060c8:	5d                   	pop    %ebp
f01060c9:	c3                   	ret    
f01060ca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01060d0:	0f bd fa             	bsr    %edx,%edi
f01060d3:	83 f7 1f             	xor    $0x1f,%edi
f01060d6:	75 48                	jne    f0106120 <__udivdi3+0xa0>
f01060d8:	39 f2                	cmp    %esi,%edx
f01060da:	72 06                	jb     f01060e2 <__udivdi3+0x62>
f01060dc:	31 c0                	xor    %eax,%eax
f01060de:	39 eb                	cmp    %ebp,%ebx
f01060e0:	77 de                	ja     f01060c0 <__udivdi3+0x40>
f01060e2:	b8 01 00 00 00       	mov    $0x1,%eax
f01060e7:	eb d7                	jmp    f01060c0 <__udivdi3+0x40>
f01060e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01060f0:	89 d9                	mov    %ebx,%ecx
f01060f2:	85 db                	test   %ebx,%ebx
f01060f4:	75 0b                	jne    f0106101 <__udivdi3+0x81>
f01060f6:	b8 01 00 00 00       	mov    $0x1,%eax
f01060fb:	31 d2                	xor    %edx,%edx
f01060fd:	f7 f3                	div    %ebx
f01060ff:	89 c1                	mov    %eax,%ecx
f0106101:	31 d2                	xor    %edx,%edx
f0106103:	89 f0                	mov    %esi,%eax
f0106105:	f7 f1                	div    %ecx
f0106107:	89 c6                	mov    %eax,%esi
f0106109:	89 e8                	mov    %ebp,%eax
f010610b:	89 f7                	mov    %esi,%edi
f010610d:	f7 f1                	div    %ecx
f010610f:	89 fa                	mov    %edi,%edx
f0106111:	83 c4 1c             	add    $0x1c,%esp
f0106114:	5b                   	pop    %ebx
f0106115:	5e                   	pop    %esi
f0106116:	5f                   	pop    %edi
f0106117:	5d                   	pop    %ebp
f0106118:	c3                   	ret    
f0106119:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106120:	89 f9                	mov    %edi,%ecx
f0106122:	b8 20 00 00 00       	mov    $0x20,%eax
f0106127:	29 f8                	sub    %edi,%eax
f0106129:	d3 e2                	shl    %cl,%edx
f010612b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010612f:	89 c1                	mov    %eax,%ecx
f0106131:	89 da                	mov    %ebx,%edx
f0106133:	d3 ea                	shr    %cl,%edx
f0106135:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0106139:	09 d1                	or     %edx,%ecx
f010613b:	89 f2                	mov    %esi,%edx
f010613d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106141:	89 f9                	mov    %edi,%ecx
f0106143:	d3 e3                	shl    %cl,%ebx
f0106145:	89 c1                	mov    %eax,%ecx
f0106147:	d3 ea                	shr    %cl,%edx
f0106149:	89 f9                	mov    %edi,%ecx
f010614b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010614f:	89 eb                	mov    %ebp,%ebx
f0106151:	d3 e6                	shl    %cl,%esi
f0106153:	89 c1                	mov    %eax,%ecx
f0106155:	d3 eb                	shr    %cl,%ebx
f0106157:	09 de                	or     %ebx,%esi
f0106159:	89 f0                	mov    %esi,%eax
f010615b:	f7 74 24 08          	divl   0x8(%esp)
f010615f:	89 d6                	mov    %edx,%esi
f0106161:	89 c3                	mov    %eax,%ebx
f0106163:	f7 64 24 0c          	mull   0xc(%esp)
f0106167:	39 d6                	cmp    %edx,%esi
f0106169:	72 15                	jb     f0106180 <__udivdi3+0x100>
f010616b:	89 f9                	mov    %edi,%ecx
f010616d:	d3 e5                	shl    %cl,%ebp
f010616f:	39 c5                	cmp    %eax,%ebp
f0106171:	73 04                	jae    f0106177 <__udivdi3+0xf7>
f0106173:	39 d6                	cmp    %edx,%esi
f0106175:	74 09                	je     f0106180 <__udivdi3+0x100>
f0106177:	89 d8                	mov    %ebx,%eax
f0106179:	31 ff                	xor    %edi,%edi
f010617b:	e9 40 ff ff ff       	jmp    f01060c0 <__udivdi3+0x40>
f0106180:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0106183:	31 ff                	xor    %edi,%edi
f0106185:	e9 36 ff ff ff       	jmp    f01060c0 <__udivdi3+0x40>
f010618a:	66 90                	xchg   %ax,%ax
f010618c:	66 90                	xchg   %ax,%ax
f010618e:	66 90                	xchg   %ax,%ax

f0106190 <__umoddi3>:
f0106190:	f3 0f 1e fb          	endbr32 
f0106194:	55                   	push   %ebp
f0106195:	57                   	push   %edi
f0106196:	56                   	push   %esi
f0106197:	53                   	push   %ebx
f0106198:	83 ec 1c             	sub    $0x1c,%esp
f010619b:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010619f:	8b 74 24 30          	mov    0x30(%esp),%esi
f01061a3:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f01061a7:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01061ab:	85 c0                	test   %eax,%eax
f01061ad:	75 19                	jne    f01061c8 <__umoddi3+0x38>
f01061af:	39 df                	cmp    %ebx,%edi
f01061b1:	76 5d                	jbe    f0106210 <__umoddi3+0x80>
f01061b3:	89 f0                	mov    %esi,%eax
f01061b5:	89 da                	mov    %ebx,%edx
f01061b7:	f7 f7                	div    %edi
f01061b9:	89 d0                	mov    %edx,%eax
f01061bb:	31 d2                	xor    %edx,%edx
f01061bd:	83 c4 1c             	add    $0x1c,%esp
f01061c0:	5b                   	pop    %ebx
f01061c1:	5e                   	pop    %esi
f01061c2:	5f                   	pop    %edi
f01061c3:	5d                   	pop    %ebp
f01061c4:	c3                   	ret    
f01061c5:	8d 76 00             	lea    0x0(%esi),%esi
f01061c8:	89 f2                	mov    %esi,%edx
f01061ca:	39 d8                	cmp    %ebx,%eax
f01061cc:	76 12                	jbe    f01061e0 <__umoddi3+0x50>
f01061ce:	89 f0                	mov    %esi,%eax
f01061d0:	89 da                	mov    %ebx,%edx
f01061d2:	83 c4 1c             	add    $0x1c,%esp
f01061d5:	5b                   	pop    %ebx
f01061d6:	5e                   	pop    %esi
f01061d7:	5f                   	pop    %edi
f01061d8:	5d                   	pop    %ebp
f01061d9:	c3                   	ret    
f01061da:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01061e0:	0f bd e8             	bsr    %eax,%ebp
f01061e3:	83 f5 1f             	xor    $0x1f,%ebp
f01061e6:	75 50                	jne    f0106238 <__umoddi3+0xa8>
f01061e8:	39 d8                	cmp    %ebx,%eax
f01061ea:	0f 82 e0 00 00 00    	jb     f01062d0 <__umoddi3+0x140>
f01061f0:	89 d9                	mov    %ebx,%ecx
f01061f2:	39 f7                	cmp    %esi,%edi
f01061f4:	0f 86 d6 00 00 00    	jbe    f01062d0 <__umoddi3+0x140>
f01061fa:	89 d0                	mov    %edx,%eax
f01061fc:	89 ca                	mov    %ecx,%edx
f01061fe:	83 c4 1c             	add    $0x1c,%esp
f0106201:	5b                   	pop    %ebx
f0106202:	5e                   	pop    %esi
f0106203:	5f                   	pop    %edi
f0106204:	5d                   	pop    %ebp
f0106205:	c3                   	ret    
f0106206:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f010620d:	8d 76 00             	lea    0x0(%esi),%esi
f0106210:	89 fd                	mov    %edi,%ebp
f0106212:	85 ff                	test   %edi,%edi
f0106214:	75 0b                	jne    f0106221 <__umoddi3+0x91>
f0106216:	b8 01 00 00 00       	mov    $0x1,%eax
f010621b:	31 d2                	xor    %edx,%edx
f010621d:	f7 f7                	div    %edi
f010621f:	89 c5                	mov    %eax,%ebp
f0106221:	89 d8                	mov    %ebx,%eax
f0106223:	31 d2                	xor    %edx,%edx
f0106225:	f7 f5                	div    %ebp
f0106227:	89 f0                	mov    %esi,%eax
f0106229:	f7 f5                	div    %ebp
f010622b:	89 d0                	mov    %edx,%eax
f010622d:	31 d2                	xor    %edx,%edx
f010622f:	eb 8c                	jmp    f01061bd <__umoddi3+0x2d>
f0106231:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106238:	89 e9                	mov    %ebp,%ecx
f010623a:	ba 20 00 00 00       	mov    $0x20,%edx
f010623f:	29 ea                	sub    %ebp,%edx
f0106241:	d3 e0                	shl    %cl,%eax
f0106243:	89 44 24 08          	mov    %eax,0x8(%esp)
f0106247:	89 d1                	mov    %edx,%ecx
f0106249:	89 f8                	mov    %edi,%eax
f010624b:	d3 e8                	shr    %cl,%eax
f010624d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0106251:	89 54 24 04          	mov    %edx,0x4(%esp)
f0106255:	8b 54 24 04          	mov    0x4(%esp),%edx
f0106259:	09 c1                	or     %eax,%ecx
f010625b:	89 d8                	mov    %ebx,%eax
f010625d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106261:	89 e9                	mov    %ebp,%ecx
f0106263:	d3 e7                	shl    %cl,%edi
f0106265:	89 d1                	mov    %edx,%ecx
f0106267:	d3 e8                	shr    %cl,%eax
f0106269:	89 e9                	mov    %ebp,%ecx
f010626b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010626f:	d3 e3                	shl    %cl,%ebx
f0106271:	89 c7                	mov    %eax,%edi
f0106273:	89 d1                	mov    %edx,%ecx
f0106275:	89 f0                	mov    %esi,%eax
f0106277:	d3 e8                	shr    %cl,%eax
f0106279:	89 e9                	mov    %ebp,%ecx
f010627b:	89 fa                	mov    %edi,%edx
f010627d:	d3 e6                	shl    %cl,%esi
f010627f:	09 d8                	or     %ebx,%eax
f0106281:	f7 74 24 08          	divl   0x8(%esp)
f0106285:	89 d1                	mov    %edx,%ecx
f0106287:	89 f3                	mov    %esi,%ebx
f0106289:	f7 64 24 0c          	mull   0xc(%esp)
f010628d:	89 c6                	mov    %eax,%esi
f010628f:	89 d7                	mov    %edx,%edi
f0106291:	39 d1                	cmp    %edx,%ecx
f0106293:	72 06                	jb     f010629b <__umoddi3+0x10b>
f0106295:	75 10                	jne    f01062a7 <__umoddi3+0x117>
f0106297:	39 c3                	cmp    %eax,%ebx
f0106299:	73 0c                	jae    f01062a7 <__umoddi3+0x117>
f010629b:	2b 44 24 0c          	sub    0xc(%esp),%eax
f010629f:	1b 54 24 08          	sbb    0x8(%esp),%edx
f01062a3:	89 d7                	mov    %edx,%edi
f01062a5:	89 c6                	mov    %eax,%esi
f01062a7:	89 ca                	mov    %ecx,%edx
f01062a9:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01062ae:	29 f3                	sub    %esi,%ebx
f01062b0:	19 fa                	sbb    %edi,%edx
f01062b2:	89 d0                	mov    %edx,%eax
f01062b4:	d3 e0                	shl    %cl,%eax
f01062b6:	89 e9                	mov    %ebp,%ecx
f01062b8:	d3 eb                	shr    %cl,%ebx
f01062ba:	d3 ea                	shr    %cl,%edx
f01062bc:	09 d8                	or     %ebx,%eax
f01062be:	83 c4 1c             	add    $0x1c,%esp
f01062c1:	5b                   	pop    %ebx
f01062c2:	5e                   	pop    %esi
f01062c3:	5f                   	pop    %edi
f01062c4:	5d                   	pop    %ebp
f01062c5:	c3                   	ret    
f01062c6:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01062cd:	8d 76 00             	lea    0x0(%esi),%esi
f01062d0:	29 fe                	sub    %edi,%esi
f01062d2:	19 c3                	sbb    %eax,%ebx
f01062d4:	89 f2                	mov    %esi,%edx
f01062d6:	89 d9                	mov    %ebx,%ecx
f01062d8:	e9 1d ff ff ff       	jmp    f01061fa <__umoddi3+0x6a>
