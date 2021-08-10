
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
f0100015:	b8 00 00 12 00       	mov    $0x120000,%eax
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
f0100034:	bc 00 00 12 f0       	mov    $0xf0120000,%esp

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
f010004c:	83 3d 80 2e 23 f0 00 	cmpl   $0x0,0xf0232e80
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
f0100064:	89 35 80 2e 23 f0    	mov    %esi,0xf0232e80
	asm volatile("cli; cld");
f010006a:	fa                   	cli    
f010006b:	fc                   	cld    
	va_start(ap, fmt);
f010006c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010006f:	e8 12 5b 00 00       	call   f0105b86 <cpunum>
f0100074:	ff 75 0c             	pushl  0xc(%ebp)
f0100077:	ff 75 08             	pushl  0x8(%ebp)
f010007a:	50                   	push   %eax
f010007b:	68 00 62 10 f0       	push   $0xf0106200
f0100080:	e8 48 39 00 00       	call   f01039cd <cprintf>
	vcprintf(fmt, ap);
f0100085:	83 c4 08             	add    $0x8,%esp
f0100088:	53                   	push   %ebx
f0100089:	56                   	push   %esi
f010008a:	e8 14 39 00 00       	call   f01039a3 <vcprintf>
	cprintf("\n");
f010008f:	c7 04 24 3d 74 10 f0 	movl   $0xf010743d,(%esp)
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
f01000b8:	68 6c 62 10 f0       	push   $0xf010626c
f01000bd:	e8 0b 39 00 00       	call   f01039cd <cprintf>
	mem_init();
f01000c2:	e8 66 12 00 00       	call   f010132d <mem_init>
	env_init();
f01000c7:	e8 ac 30 00 00       	call   f0103178 <env_init>
	trap_init();
f01000cc:	e8 f8 39 00 00       	call   f0103ac9 <trap_init>
	mp_init();
f01000d1:	e8 b1 57 00 00       	call   f0105887 <mp_init>
	lapic_init();
f01000d6:	e8 c5 5a 00 00       	call   f0105ba0 <lapic_init>
	pic_init();
f01000db:	e8 02 38 00 00       	call   f01038e2 <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000e0:	c7 04 24 c0 23 12 f0 	movl   $0xf01223c0,(%esp)
f01000e7:	e8 22 5d 00 00       	call   f0105e0e <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000ec:	83 c4 10             	add    $0x10,%esp
f01000ef:	83 3d 88 2e 23 f0 07 	cmpl   $0x7,0xf0232e88
f01000f6:	76 27                	jbe    f010011f <i386_init+0x7f>
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f01000f8:	83 ec 04             	sub    $0x4,%esp
f01000fb:	b8 ea 57 10 f0       	mov    $0xf01057ea,%eax
f0100100:	2d 70 57 10 f0       	sub    $0xf0105770,%eax
f0100105:	50                   	push   %eax
f0100106:	68 70 57 10 f0       	push   $0xf0105770
f010010b:	68 00 70 00 f0       	push   $0xf0007000
f0100110:	e8 9e 54 00 00       	call   f01055b3 <memmove>
	for (c = cpus; c < cpus + ncpu; c++) {
f0100115:	83 c4 10             	add    $0x10,%esp
f0100118:	bb 20 30 23 f0       	mov    $0xf0233020,%ebx
f010011d:	eb 53                	jmp    f0100172 <i386_init+0xd2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010011f:	68 00 70 00 00       	push   $0x7000
f0100124:	68 24 62 10 f0       	push   $0xf0106224
f0100129:	6a 4e                	push   $0x4e
f010012b:	68 87 62 10 f0       	push   $0xf0106287
f0100130:	e8 0b ff ff ff       	call   f0100040 <_panic>
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100135:	89 d8                	mov    %ebx,%eax
f0100137:	2d 20 30 23 f0       	sub    $0xf0233020,%eax
f010013c:	c1 f8 02             	sar    $0x2,%eax
f010013f:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100145:	c1 e0 0f             	shl    $0xf,%eax
f0100148:	8d 80 00 c0 23 f0    	lea    -0xfdc4000(%eax),%eax
f010014e:	a3 84 2e 23 f0       	mov    %eax,0xf0232e84
		lapic_startap(c->cpu_id, PADDR(code));
f0100153:	83 ec 08             	sub    $0x8,%esp
f0100156:	68 00 70 00 00       	push   $0x7000
f010015b:	0f b6 03             	movzbl (%ebx),%eax
f010015e:	50                   	push   %eax
f010015f:	e8 96 5b 00 00       	call   f0105cfa <lapic_startap>
		while(c->cpu_status != CPU_STARTED)
f0100164:	83 c4 10             	add    $0x10,%esp
f0100167:	8b 43 04             	mov    0x4(%ebx),%eax
f010016a:	83 f8 01             	cmp    $0x1,%eax
f010016d:	75 f8                	jne    f0100167 <i386_init+0xc7>
	for (c = cpus; c < cpus + ncpu; c++) {
f010016f:	83 c3 74             	add    $0x74,%ebx
f0100172:	6b 05 c4 33 23 f0 74 	imul   $0x74,0xf02333c4,%eax
f0100179:	05 20 30 23 f0       	add    $0xf0233020,%eax
f010017e:	39 c3                	cmp    %eax,%ebx
f0100180:	73 13                	jae    f0100195 <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100182:	e8 ff 59 00 00       	call   f0105b86 <cpunum>
f0100187:	6b c0 74             	imul   $0x74,%eax,%eax
f010018a:	05 20 30 23 f0       	add    $0xf0233020,%eax
f010018f:	39 c3                	cmp    %eax,%ebx
f0100191:	74 dc                	je     f010016f <i386_init+0xcf>
f0100193:	eb a0                	jmp    f0100135 <i386_init+0x95>
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100195:	83 ec 08             	sub    $0x8,%esp
f0100198:	6a 00                	push   $0x0
f010019a:	68 a0 2b 1a f0       	push   $0xf01a2ba0
f010019f:	e8 d0 31 00 00       	call   f0103374 <env_create>
	sched_yield();
f01001a4:	e8 bc 42 00 00       	call   f0104465 <sched_yield>

f01001a9 <mp_main>:
{
f01001a9:	f3 0f 1e fb          	endbr32 
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	83 ec 08             	sub    $0x8,%esp
	lcr3(PADDR(kern_pgdir));
f01001b3:	a1 8c 2e 23 f0       	mov    0xf0232e8c,%eax
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
f01001c7:	e8 ba 59 00 00       	call   f0105b86 <cpunum>
f01001cc:	83 ec 08             	sub    $0x8,%esp
f01001cf:	50                   	push   %eax
f01001d0:	68 93 62 10 f0       	push   $0xf0106293
f01001d5:	e8 f3 37 00 00       	call   f01039cd <cprintf>
	lapic_init();
f01001da:	e8 c1 59 00 00       	call   f0105ba0 <lapic_init>
	env_init_percpu();
f01001df:	e8 64 2f 00 00       	call   f0103148 <env_init_percpu>
	trap_init_percpu();
f01001e4:	e8 fc 37 00 00       	call   f01039e5 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f01001e9:	e8 98 59 00 00       	call   f0105b86 <cpunum>
f01001ee:	6b d0 74             	imul   $0x74,%eax,%edx
f01001f1:	83 c2 04             	add    $0x4,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f01001f4:	b8 01 00 00 00       	mov    $0x1,%eax
f01001f9:	f0 87 82 20 30 23 f0 	lock xchg %eax,-0xfdccfe0(%edx)
f0100200:	c7 04 24 c0 23 12 f0 	movl   $0xf01223c0,(%esp)
f0100207:	e8 02 5c 00 00       	call   f0105e0e <spin_lock>
	sched_yield();
f010020c:	e8 54 42 00 00       	call   f0104465 <sched_yield>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100211:	50                   	push   %eax
f0100212:	68 48 62 10 f0       	push   $0xf0106248
f0100217:	6a 65                	push   $0x65
f0100219:	68 87 62 10 f0       	push   $0xf0106287
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
f0100237:	68 a9 62 10 f0       	push   $0xf01062a9
f010023c:	e8 8c 37 00 00       	call   f01039cd <cprintf>
	vcprintf(fmt, ap);
f0100241:	83 c4 08             	add    $0x8,%esp
f0100244:	53                   	push   %ebx
f0100245:	ff 75 10             	pushl  0x10(%ebp)
f0100248:	e8 56 37 00 00       	call   f01039a3 <vcprintf>
	cprintf("\n");
f010024d:	c7 04 24 3d 74 10 f0 	movl   $0xf010743d,(%esp)
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
f0100293:	8b 0d 24 22 23 f0    	mov    0xf0232224,%ecx
f0100299:	8d 51 01             	lea    0x1(%ecx),%edx
f010029c:	88 81 20 20 23 f0    	mov    %al,-0xfdcdfe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002a2:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01002a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01002ad:	0f 44 d0             	cmove  %eax,%edx
f01002b0:	89 15 24 22 23 f0    	mov    %edx,0xf0232224
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
f01002ef:	8b 0d 00 20 23 f0    	mov    0xf0232000,%ecx
f01002f5:	f6 c1 40             	test   $0x40,%cl
f01002f8:	74 0e                	je     f0100308 <kbd_proc_data+0x4a>
		data |= 0x80;
f01002fa:	83 c8 80             	or     $0xffffff80,%eax
f01002fd:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01002ff:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100302:	89 0d 00 20 23 f0    	mov    %ecx,0xf0232000
	shift |= shiftcode[data];
f0100308:	0f b6 d2             	movzbl %dl,%edx
f010030b:	0f b6 82 20 64 10 f0 	movzbl -0xfef9be0(%edx),%eax
f0100312:	0b 05 00 20 23 f0    	or     0xf0232000,%eax
	shift ^= togglecode[data];
f0100318:	0f b6 8a 20 63 10 f0 	movzbl -0xfef9ce0(%edx),%ecx
f010031f:	31 c8                	xor    %ecx,%eax
f0100321:	a3 00 20 23 f0       	mov    %eax,0xf0232000
	c = charcode[shift & (CTL | SHIFT)][data];
f0100326:	89 c1                	mov    %eax,%ecx
f0100328:	83 e1 03             	and    $0x3,%ecx
f010032b:	8b 0c 8d 00 63 10 f0 	mov    -0xfef9d00(,%ecx,4),%ecx
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
f010034c:	83 0d 00 20 23 f0 40 	orl    $0x40,0xf0232000
		return 0;
f0100353:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0100358:	89 d8                	mov    %ebx,%eax
f010035a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010035d:	c9                   	leave  
f010035e:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010035f:	8b 0d 00 20 23 f0    	mov    0xf0232000,%ecx
f0100365:	89 cb                	mov    %ecx,%ebx
f0100367:	83 e3 40             	and    $0x40,%ebx
f010036a:	83 e0 7f             	and    $0x7f,%eax
f010036d:	85 db                	test   %ebx,%ebx
f010036f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100372:	0f b6 d2             	movzbl %dl,%edx
f0100375:	0f b6 82 20 64 10 f0 	movzbl -0xfef9be0(%edx),%eax
f010037c:	83 c8 40             	or     $0x40,%eax
f010037f:	0f b6 c0             	movzbl %al,%eax
f0100382:	f7 d0                	not    %eax
f0100384:	21 c8                	and    %ecx,%eax
f0100386:	a3 00 20 23 f0       	mov    %eax,0xf0232000
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
f01003af:	68 c3 62 10 f0       	push   $0xf01062c3
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
f01004dd:	0f b7 05 28 22 23 f0 	movzwl 0xf0232228,%eax
f01004e4:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004ea:	c1 e8 16             	shr    $0x16,%eax
f01004ed:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004f0:	c1 e0 04             	shl    $0x4,%eax
f01004f3:	66 a3 28 22 23 f0    	mov    %ax,0xf0232228
	if (crt_pos >= CRT_SIZE) {
f01004f9:	66 81 3d 28 22 23 f0 	cmpw   $0x7cf,0xf0232228
f0100500:	cf 07 
f0100502:	0f 87 8e 00 00 00    	ja     f0100596 <cons_putc+0x1bf>
	outb(addr_6845, 14);
f0100508:	8b 0d 30 22 23 f0    	mov    0xf0232230,%ecx
f010050e:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100513:	89 ca                	mov    %ecx,%edx
f0100515:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100516:	0f b7 1d 28 22 23 f0 	movzwl 0xf0232228,%ebx
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
f010053e:	0f b7 05 28 22 23 f0 	movzwl 0xf0232228,%eax
f0100545:	66 85 c0             	test   %ax,%ax
f0100548:	74 be                	je     f0100508 <cons_putc+0x131>
			crt_pos--;
f010054a:	83 e8 01             	sub    $0x1,%eax
f010054d:	66 a3 28 22 23 f0    	mov    %ax,0xf0232228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100553:	0f b7 d0             	movzwl %ax,%edx
f0100556:	b1 00                	mov    $0x0,%cl
f0100558:	83 c9 20             	or     $0x20,%ecx
f010055b:	a1 2c 22 23 f0       	mov    0xf023222c,%eax
f0100560:	66 89 0c 50          	mov    %cx,(%eax,%edx,2)
f0100564:	eb 93                	jmp    f01004f9 <cons_putc+0x122>
		crt_pos += CRT_COLS;
f0100566:	66 83 05 28 22 23 f0 	addw   $0x50,0xf0232228
f010056d:	50 
f010056e:	e9 6a ff ff ff       	jmp    f01004dd <cons_putc+0x106>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100573:	0f b7 05 28 22 23 f0 	movzwl 0xf0232228,%eax
f010057a:	8d 50 01             	lea    0x1(%eax),%edx
f010057d:	66 89 15 28 22 23 f0 	mov    %dx,0xf0232228
f0100584:	0f b7 c0             	movzwl %ax,%eax
f0100587:	8b 15 2c 22 23 f0    	mov    0xf023222c,%edx
f010058d:	66 89 0c 42          	mov    %cx,(%edx,%eax,2)
		break;
f0100591:	e9 63 ff ff ff       	jmp    f01004f9 <cons_putc+0x122>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100596:	a1 2c 22 23 f0       	mov    0xf023222c,%eax
f010059b:	83 ec 04             	sub    $0x4,%esp
f010059e:	68 00 0f 00 00       	push   $0xf00
f01005a3:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005a9:	52                   	push   %edx
f01005aa:	50                   	push   %eax
f01005ab:	e8 03 50 00 00       	call   f01055b3 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01005b0:	8b 15 2c 22 23 f0    	mov    0xf023222c,%edx
f01005b6:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01005bc:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01005c2:	83 c4 10             	add    $0x10,%esp
f01005c5:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01005ca:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005cd:	39 d0                	cmp    %edx,%eax
f01005cf:	75 f4                	jne    f01005c5 <cons_putc+0x1ee>
		crt_pos -= CRT_COLS;
f01005d1:	66 83 2d 28 22 23 f0 	subw   $0x50,0xf0232228
f01005d8:	50 
f01005d9:	e9 2a ff ff ff       	jmp    f0100508 <cons_putc+0x131>

f01005de <serial_intr>:
{
f01005de:	f3 0f 1e fb          	endbr32 
	if (serial_exists)
f01005e2:	80 3d 34 22 23 f0 00 	cmpb   $0x0,0xf0232234
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
f0100628:	a1 20 22 23 f0       	mov    0xf0232220,%eax
	return 0;
f010062d:	ba 00 00 00 00       	mov    $0x0,%edx
	if (cons.rpos != cons.wpos) {
f0100632:	3b 05 24 22 23 f0    	cmp    0xf0232224,%eax
f0100638:	74 1c                	je     f0100656 <cons_getc+0x42>
		c = cons.buf[cons.rpos++];
f010063a:	8d 48 01             	lea    0x1(%eax),%ecx
f010063d:	0f b6 90 20 20 23 f0 	movzbl -0xfdcdfe0(%eax),%edx
			cons.rpos = 0;
f0100644:	3d ff 01 00 00       	cmp    $0x1ff,%eax
f0100649:	b8 00 00 00 00       	mov    $0x0,%eax
f010064e:	0f 45 c1             	cmovne %ecx,%eax
f0100651:	a3 20 22 23 f0       	mov    %eax,0xf0232220
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
f0100688:	c7 05 30 22 23 f0 b4 	movl   $0x3b4,0xf0232230
f010068f:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100692:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
	outb(addr_6845, 14);
f0100697:	8b 3d 30 22 23 f0    	mov    0xf0232230,%edi
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
f01006be:	89 35 2c 22 23 f0    	mov    %esi,0xf023222c
	pos |= inb(addr_6845 + 1);
f01006c4:	0f b6 c0             	movzbl %al,%eax
f01006c7:	09 d8                	or     %ebx,%eax
	crt_pos = pos;
f01006c9:	66 a3 28 22 23 f0    	mov    %ax,0xf0232228
	kbd_intr();
f01006cf:	e8 2a ff ff ff       	call   f01005fe <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006d4:	83 ec 0c             	sub    $0xc,%esp
f01006d7:	0f b7 05 a8 23 12 f0 	movzwl 0xf01223a8,%eax
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
f010073f:	0f 95 05 34 22 23 f0 	setne  0xf0232234
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
f0100763:	c7 05 30 22 23 f0 d4 	movl   $0x3d4,0xf0232230
f010076a:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010076d:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f0100772:	e9 20 ff ff ff       	jmp    f0100697 <cons_init+0x3d>
		cprintf("Serial port does not exist!\n");
f0100777:	83 ec 0c             	sub    $0xc,%esp
f010077a:	68 cf 62 10 f0       	push   $0xf01062cf
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
f01007c6:	68 20 65 10 f0       	push   $0xf0106520
f01007cb:	68 3e 65 10 f0       	push   $0xf010653e
f01007d0:	68 43 65 10 f0       	push   $0xf0106543
f01007d5:	e8 f3 31 00 00       	call   f01039cd <cprintf>
f01007da:	83 c4 0c             	add    $0xc,%esp
f01007dd:	68 10 66 10 f0       	push   $0xf0106610
f01007e2:	68 4c 65 10 f0       	push   $0xf010654c
f01007e7:	68 43 65 10 f0       	push   $0xf0106543
f01007ec:	e8 dc 31 00 00       	call   f01039cd <cprintf>
f01007f1:	83 c4 0c             	add    $0xc,%esp
f01007f4:	68 55 65 10 f0       	push   $0xf0106555
f01007f9:	68 6b 65 10 f0       	push   $0xf010656b
f01007fe:	68 43 65 10 f0       	push   $0xf0106543
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
f0100819:	68 75 65 10 f0       	push   $0xf0106575
f010081e:	e8 aa 31 00 00       	call   f01039cd <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100823:	83 c4 08             	add    $0x8,%esp
f0100826:	68 0c 00 10 00       	push   $0x10000c
f010082b:	68 38 66 10 f0       	push   $0xf0106638
f0100830:	e8 98 31 00 00       	call   f01039cd <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100835:	83 c4 0c             	add    $0xc,%esp
f0100838:	68 0c 00 10 00       	push   $0x10000c
f010083d:	68 0c 00 10 f0       	push   $0xf010000c
f0100842:	68 60 66 10 f0       	push   $0xf0106660
f0100847:	e8 81 31 00 00       	call   f01039cd <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010084c:	83 c4 0c             	add    $0xc,%esp
f010084f:	68 fd 61 10 00       	push   $0x1061fd
f0100854:	68 fd 61 10 f0       	push   $0xf01061fd
f0100859:	68 84 66 10 f0       	push   $0xf0106684
f010085e:	e8 6a 31 00 00       	call   f01039cd <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100863:	83 c4 0c             	add    $0xc,%esp
f0100866:	68 00 20 23 00       	push   $0x232000
f010086b:	68 00 20 23 f0       	push   $0xf0232000
f0100870:	68 a8 66 10 f0       	push   $0xf01066a8
f0100875:	e8 53 31 00 00       	call   f01039cd <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010087a:	83 c4 0c             	add    $0xc,%esp
f010087d:	68 09 40 27 00       	push   $0x274009
f0100882:	68 09 40 27 f0       	push   $0xf0274009
f0100887:	68 cc 66 10 f0       	push   $0xf01066cc
f010088c:	e8 3c 31 00 00       	call   f01039cd <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100891:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100894:	b8 09 40 27 f0       	mov    $0xf0274009,%eax
f0100899:	2d 0d fc 0f f0       	sub    $0xf00ffc0d,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f010089e:	c1 f8 0a             	sar    $0xa,%eax
f01008a1:	50                   	push   %eax
f01008a2:	68 f0 66 10 f0       	push   $0xf01066f0
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
f01008cc:	68 8e 65 10 f0       	push   $0xf010658e
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
f01008f0:	68 a0 65 10 f0       	push   $0xf01065a0
f01008f5:	e8 d3 30 00 00       	call   f01039cd <cprintf>
f01008fa:	8d 5e 08             	lea    0x8(%esi),%ebx
f01008fd:	8d 7e 1c             	lea    0x1c(%esi),%edi
f0100900:	83 c4 10             	add    $0x10,%esp
            cprintf("%08x ", args[i]);
f0100903:	83 ec 08             	sub    $0x8,%esp
f0100906:	ff 33                	pushl  (%ebx)
f0100908:	68 bb 65 10 f0       	push   $0xf01065bb
f010090d:	e8 bb 30 00 00       	call   f01039cd <cprintf>
f0100912:	83 c3 04             	add    $0x4,%ebx
        for (int i = 0; i < 5; ++i) {
f0100915:	83 c4 10             	add    $0x10,%esp
f0100918:	39 fb                	cmp    %edi,%ebx
f010091a:	75 e7                	jne    f0100903 <mon_backtrace+0x50>
        cprintf("\n");
f010091c:	83 ec 0c             	sub    $0xc,%esp
f010091f:	68 3d 74 10 f0       	push   $0xf010743d
f0100924:	e8 a4 30 00 00       	call   f01039cd <cprintf>
        if(debuginfo_eip(eip,&info) == 0)
f0100929:	83 c4 08             	add    $0x8,%esp
f010092c:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010092f:	50                   	push   %eax
f0100930:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100933:	e8 f6 40 00 00       	call   f0104a2e <debuginfo_eip>
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
f0100955:	68 c1 65 10 f0       	push   $0xf01065c1
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
f0100981:	68 1c 67 10 f0       	push   $0xf010671c
f0100986:	e8 42 30 00 00       	call   f01039cd <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010098b:	c7 04 24 40 67 10 f0 	movl   $0xf0106740,(%esp)
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
f01009be:	68 d7 65 10 f0       	push   $0xf01065d7
f01009c3:	e8 5a 4b 00 00       	call   f0105522 <strchr>
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
f01009fb:	ff 34 85 80 67 10 f0 	pushl  -0xfef9880(,%eax,4)
f0100a02:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a05:	e8 b2 4a 00 00       	call   f01054bc <strcmp>
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
f0100a23:	68 f9 65 10 f0       	push   $0xf01065f9
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
f0100a51:	68 d7 65 10 f0       	push   $0xf01065d7
f0100a56:	e8 c7 4a 00 00       	call   f0105522 <strchr>
f0100a5b:	83 c4 10             	add    $0x10,%esp
f0100a5e:	85 c0                	test   %eax,%eax
f0100a60:	0f 85 71 ff ff ff    	jne    f01009d7 <monitor+0x63>
			buf++;
f0100a66:	83 c3 01             	add    $0x1,%ebx
f0100a69:	eb d8                	jmp    f0100a43 <monitor+0xcf>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a6b:	83 ec 08             	sub    $0x8,%esp
f0100a6e:	6a 10                	push   $0x10
f0100a70:	68 dc 65 10 f0       	push   $0xf01065dc
f0100a75:	e8 53 2f 00 00       	call   f01039cd <cprintf>
			return 0;
f0100a7a:	83 c4 10             	add    $0x10,%esp
	// cprintf("x %d, y %x, z %d\n", x, y, z);
	// unsigned int i = 0x00646c72;
 	// cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100a7d:	83 ec 0c             	sub    $0xc,%esp
f0100a80:	68 d3 65 10 f0       	push   $0xf01065d3
f0100a85:	e8 4a 48 00 00       	call   f01052d4 <readline>
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
f0100ab2:	ff 14 85 88 67 10 f0 	call   *-0xfef9878(,%eax,4)
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
f0100af1:	83 3d 38 22 23 f0 00 	cmpl   $0x0,0xf0232238
f0100af8:	74 36                	je     f0100b30 <boot_alloc+0x3f>
	// LAB 2: Your code here.

	// special case
	if(n == 0)
	{
		return nextfree;
f0100afa:	8b 15 38 22 23 f0    	mov    0xf0232238,%edx
	if(n == 0)
f0100b00:	85 c0                	test   %eax,%eax
f0100b02:	74 29                	je     f0100b2d <boot_alloc+0x3c>
	}

	// allocate memory 
	result = nextfree;
f0100b04:	8b 15 38 22 23 f0    	mov    0xf0232238,%edx
	nextfree = ROUNDUP(n,PGSIZE)+nextfree;
f0100b0a:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100b0f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b14:	01 d0                	add    %edx,%eax
f0100b16:	a3 38 22 23 f0       	mov    %eax,0xf0232238

	// out of memory panic
	if((uint32_t)nextfree-KERNBASE>(npages*PGSIZE))
f0100b1b:	05 00 00 00 10       	add    $0x10000000,%eax
f0100b20:	8b 0d 88 2e 23 f0    	mov    0xf0232e88,%ecx
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
f0100b30:	ba 08 50 27 f0       	mov    $0xf0275008,%edx
f0100b35:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b3b:	89 15 38 22 23 f0    	mov    %edx,0xf0232238
f0100b41:	eb b7                	jmp    f0100afa <boot_alloc+0x9>
{
f0100b43:	55                   	push   %ebp
f0100b44:	89 e5                	mov    %esp,%ebp
f0100b46:	83 ec 0c             	sub    $0xc,%esp
		panic("at pmap.c:boot_alloc(): out of memory");
f0100b49:	68 a4 67 10 f0       	push   $0xf01067a4
f0100b4e:	6a 7a                	push   $0x7a
f0100b50:	68 5d 71 10 f0       	push   $0xf010715d
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
f0100b71:	3b 05 88 2e 23 f0    	cmp    0xf0232e88,%eax
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
f0100ba3:	68 24 62 10 f0       	push   $0xf0106224
f0100ba8:	68 03 04 00 00       	push   $0x403
f0100bad:	68 5d 71 10 f0       	push   $0xf010715d
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
f0100bce:	83 3d 40 22 23 f0 00 	cmpl   $0x0,0xf0232240
f0100bd5:	74 0a                	je     f0100be1 <check_page_free_list+0x24>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bd7:	be 00 04 00 00       	mov    $0x400,%esi
f0100bdc:	e9 bf 02 00 00       	jmp    f0100ea0 <check_page_free_list+0x2e3>
		panic("'page_free_list' is a null pointer!");
f0100be1:	83 ec 04             	sub    $0x4,%esp
f0100be4:	68 cc 67 10 f0       	push   $0xf01067cc
f0100be9:	68 36 03 00 00       	push   $0x336
f0100bee:	68 5d 71 10 f0       	push   $0xf010715d
f0100bf3:	e8 48 f4 ff ff       	call   f0100040 <_panic>
f0100bf8:	50                   	push   %eax
f0100bf9:	68 24 62 10 f0       	push   $0xf0106224
f0100bfe:	6a 58                	push   $0x58
f0100c00:	68 69 71 10 f0       	push   $0xf0107169
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
f0100c12:	2b 05 90 2e 23 f0    	sub    0xf0232e90,%eax
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
f0100c2c:	3b 15 88 2e 23 f0    	cmp    0xf0232e88,%edx
f0100c32:	73 c4                	jae    f0100bf8 <check_page_free_list+0x3b>
			memset(page2kva(pp), 0x97, 128);
f0100c34:	83 ec 04             	sub    $0x4,%esp
f0100c37:	68 80 00 00 00       	push   $0x80
f0100c3c:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100c41:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c46:	50                   	push   %eax
f0100c47:	e8 1b 49 00 00       	call   f0105567 <memset>
f0100c4c:	83 c4 10             	add    $0x10,%esp
f0100c4f:	eb b9                	jmp    f0100c0a <check_page_free_list+0x4d>
	first_free_page = (char *) boot_alloc(0);
f0100c51:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c56:	e8 96 fe ff ff       	call   f0100af1 <boot_alloc>
f0100c5b:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c5e:	8b 15 40 22 23 f0    	mov    0xf0232240,%edx
		assert(pp >= pages);
f0100c64:	8b 0d 90 2e 23 f0    	mov    0xf0232e90,%ecx
		assert(pp < pages + npages);
f0100c6a:	a1 88 2e 23 f0       	mov    0xf0232e88,%eax
f0100c6f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100c72:	8d 34 c1             	lea    (%ecx,%eax,8),%esi
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c75:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c7a:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c7d:	e9 f9 00 00 00       	jmp    f0100d7b <check_page_free_list+0x1be>
		assert(pp >= pages);
f0100c82:	68 77 71 10 f0       	push   $0xf0107177
f0100c87:	68 83 71 10 f0       	push   $0xf0107183
f0100c8c:	68 50 03 00 00       	push   $0x350
f0100c91:	68 5d 71 10 f0       	push   $0xf010715d
f0100c96:	e8 a5 f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100c9b:	68 98 71 10 f0       	push   $0xf0107198
f0100ca0:	68 83 71 10 f0       	push   $0xf0107183
f0100ca5:	68 51 03 00 00       	push   $0x351
f0100caa:	68 5d 71 10 f0       	push   $0xf010715d
f0100caf:	e8 8c f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cb4:	68 f0 67 10 f0       	push   $0xf01067f0
f0100cb9:	68 83 71 10 f0       	push   $0xf0107183
f0100cbe:	68 52 03 00 00       	push   $0x352
f0100cc3:	68 5d 71 10 f0       	push   $0xf010715d
f0100cc8:	e8 73 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != 0);
f0100ccd:	68 ac 71 10 f0       	push   $0xf01071ac
f0100cd2:	68 83 71 10 f0       	push   $0xf0107183
f0100cd7:	68 55 03 00 00       	push   $0x355
f0100cdc:	68 5d 71 10 f0       	push   $0xf010715d
f0100ce1:	e8 5a f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ce6:	68 bd 71 10 f0       	push   $0xf01071bd
f0100ceb:	68 83 71 10 f0       	push   $0xf0107183
f0100cf0:	68 56 03 00 00       	push   $0x356
f0100cf5:	68 5d 71 10 f0       	push   $0xf010715d
f0100cfa:	e8 41 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cff:	68 24 68 10 f0       	push   $0xf0106824
f0100d04:	68 83 71 10 f0       	push   $0xf0107183
f0100d09:	68 57 03 00 00       	push   $0x357
f0100d0e:	68 5d 71 10 f0       	push   $0xf010715d
f0100d13:	e8 28 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d18:	68 d6 71 10 f0       	push   $0xf01071d6
f0100d1d:	68 83 71 10 f0       	push   $0xf0107183
f0100d22:	68 58 03 00 00       	push   $0x358
f0100d27:	68 5d 71 10 f0       	push   $0xf010715d
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
f0100d4b:	68 24 62 10 f0       	push   $0xf0106224
f0100d50:	6a 58                	push   $0x58
f0100d52:	68 69 71 10 f0       	push   $0xf0107169
f0100d57:	e8 e4 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d5c:	68 48 68 10 f0       	push   $0xf0106848
f0100d61:	68 83 71 10 f0       	push   $0xf0107183
f0100d66:	68 59 03 00 00       	push   $0x359
f0100d6b:	68 5d 71 10 f0       	push   $0xf010715d
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
f0100dda:	68 f0 71 10 f0       	push   $0xf01071f0
f0100ddf:	68 83 71 10 f0       	push   $0xf0107183
f0100de4:	68 5b 03 00 00       	push   $0x35b
f0100de9:	68 5d 71 10 f0       	push   $0xf010715d
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
f0100e01:	68 90 68 10 f0       	push   $0xf0106890
f0100e06:	e8 c2 2b 00 00       	call   f01039cd <cprintf>
}
f0100e0b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e0e:	5b                   	pop    %ebx
f0100e0f:	5e                   	pop    %esi
f0100e10:	5f                   	pop    %edi
f0100e11:	5d                   	pop    %ebp
f0100e12:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e13:	68 0d 72 10 f0       	push   $0xf010720d
f0100e18:	68 83 71 10 f0       	push   $0xf0107183
f0100e1d:	68 63 03 00 00       	push   $0x363
f0100e22:	68 5d 71 10 f0       	push   $0xf010715d
f0100e27:	e8 14 f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100e2c:	68 1f 72 10 f0       	push   $0xf010721f
f0100e31:	68 83 71 10 f0       	push   $0xf0107183
f0100e36:	68 64 03 00 00       	push   $0x364
f0100e3b:	68 5d 71 10 f0       	push   $0xf010715d
f0100e40:	e8 fb f1 ff ff       	call   f0100040 <_panic>
	if (!page_free_list)
f0100e45:	a1 40 22 23 f0       	mov    0xf0232240,%eax
f0100e4a:	85 c0                	test   %eax,%eax
f0100e4c:	0f 84 8f fd ff ff    	je     f0100be1 <check_page_free_list+0x24>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100e52:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100e55:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e58:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e5b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100e5e:	89 c2                	mov    %eax,%edx
f0100e60:	2b 15 90 2e 23 f0    	sub    0xf0232e90,%edx
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
f0100e96:	a3 40 22 23 f0       	mov    %eax,0xf0232240
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e9b:	be 01 00 00 00       	mov    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ea0:	8b 1d 40 22 23 f0    	mov    0xf0232240,%ebx
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
f0100ec2:	8b 0d 44 22 23 f0    	mov    0xf0232244,%ecx
	size_t num_used = ((uint32_t)boot_alloc(0)-EXTPHYSMEM-KERNBASE)/PGSIZE;
f0100ec8:	05 00 00 f0 0f       	add    $0xff00000,%eax
f0100ecd:	c1 e8 0c             	shr    $0xc,%eax
		else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_used)
f0100ed0:	8d 74 01 60          	lea    0x60(%ecx,%eax,1),%esi
f0100ed4:	8b 1d 40 22 23 f0    	mov    0xf0232240,%ebx
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
f0100eee:	8b 15 90 2e 23 f0    	mov    0xf0232e90,%edx
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
f0100f13:	03 3d 90 2e 23 f0    	add    0xf0232e90,%edi
f0100f19:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
			pages[i].pp_link = page_free_list;
f0100f1f:	89 1f                	mov    %ebx,(%edi)
			page_free_list = &pages[i];
f0100f21:	89 d3                	mov    %edx,%ebx
f0100f23:	03 1d 90 2e 23 f0    	add    0xf0232e90,%ebx
f0100f29:	bf 01 00 00 00       	mov    $0x1,%edi
	for(size_t i = 0;i<npages;i++)
f0100f2e:	83 c0 01             	add    $0x1,%eax
f0100f31:	39 05 88 2e 23 f0    	cmp    %eax,0xf0232e88
f0100f37:	76 2d                	jbe    f0100f66 <page_init+0xbb>
		if(i == 0)
f0100f39:	85 c0                	test   %eax,%eax
f0100f3b:	75 a9                	jne    f0100ee6 <page_init+0x3b>
			pages[i].pp_ref = 1;
f0100f3d:	8b 15 90 2e 23 f0    	mov    0xf0232e90,%edx
f0100f43:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
			pages[i].pp_link = NULL;
f0100f49:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
f0100f4f:	eb dd                	jmp    f0100f2e <page_init+0x83>
			pages[i].pp_ref = 1;
f0100f51:	8b 15 90 2e 23 f0    	mov    0xf0232e90,%edx
f0100f57:	66 c7 42 3c 01 00    	movw   $0x1,0x3c(%edx)
			pages[i].pp_link = NULL;
f0100f5d:	c7 42 38 00 00 00 00 	movl   $0x0,0x38(%edx)
f0100f64:	eb c8                	jmp    f0100f2e <page_init+0x83>
f0100f66:	89 f8                	mov    %edi,%eax
f0100f68:	84 c0                	test   %al,%al
f0100f6a:	74 06                	je     f0100f72 <page_init+0xc7>
f0100f6c:	89 1d 40 22 23 f0    	mov    %ebx,0xf0232240
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
f0100f85:	8b 1d 40 22 23 f0    	mov    0xf0232240,%ebx
f0100f8b:	85 db                	test   %ebx,%ebx
f0100f8d:	74 30                	je     f0100fbf <page_alloc+0x45>
	page_free_list = page_free_list->pp_link;
f0100f8f:	8b 03                	mov    (%ebx),%eax
f0100f91:	a3 40 22 23 f0       	mov    %eax,0xf0232240
	alloc->pp_link = NULL;
f0100f96:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
f0100f9c:	89 d8                	mov    %ebx,%eax
f0100f9e:	2b 05 90 2e 23 f0    	sub    0xf0232e90,%eax
f0100fa4:	c1 f8 03             	sar    $0x3,%eax
f0100fa7:	89 c2                	mov    %eax,%edx
f0100fa9:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0100fac:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0100fb1:	3b 05 88 2e 23 f0    	cmp    0xf0232e88,%eax
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
f0100fc7:	68 24 62 10 f0       	push   $0xf0106224
f0100fcc:	6a 58                	push   $0x58
f0100fce:	68 69 71 10 f0       	push   $0xf0107169
f0100fd3:	e8 68 f0 ff ff       	call   f0100040 <_panic>
		memset(head,0,PGSIZE);
f0100fd8:	83 ec 04             	sub    $0x4,%esp
f0100fdb:	68 00 10 00 00       	push   $0x1000
f0100fe0:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100fe2:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0100fe8:	52                   	push   %edx
f0100fe9:	e8 79 45 00 00       	call   f0105567 <memset>
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
f010100c:	8b 15 40 22 23 f0    	mov    0xf0232240,%edx
f0101012:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101014:	a3 40 22 23 f0       	mov    %eax,0xf0232240
}
f0101019:	c9                   	leave  
f010101a:	c3                   	ret    
		panic("at pmap.c:page_free(): Page double free or freeing a referenced page");
f010101b:	83 ec 04             	sub    $0x4,%esp
f010101e:	68 b4 68 10 f0       	push   $0xf01068b4
f0101023:	68 ae 01 00 00       	push   $0x1ae
f0101028:	68 5d 71 10 f0       	push   $0xf010715d
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
f0101097:	2b 05 90 2e 23 f0    	sub    0xf0232e90,%eax
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
f01010b5:	3b 05 88 2e 23 f0    	cmp    0xf0232e88,%eax
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
f01010d5:	68 24 62 10 f0       	push   $0xf0106224
f01010da:	68 fb 01 00 00       	push   $0x1fb
f01010df:	68 5d 71 10 f0       	push   $0xf010715d
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
f0101168:	39 15 88 2e 23 f0    	cmp    %edx,0xf0232e88
f010116e:	76 16                	jbe    f0101186 <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f0101170:	8b 0d 90 2e 23 f0    	mov    0xf0232e90,%ecx
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
f0101189:	68 fc 68 10 f0       	push   $0xf01068fc
f010118e:	6a 51                	push   $0x51
f0101190:	68 69 71 10 f0       	push   $0xf0107169
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
f01011af:	e8 d2 49 00 00       	call   f0105b86 <cpunum>
f01011b4:	6b c0 74             	imul   $0x74,%eax,%eax
f01011b7:	83 b8 28 30 23 f0 00 	cmpl   $0x0,-0xfdccfd8(%eax)
f01011be:	74 16                	je     f01011d6 <tlb_invalidate+0x31>
f01011c0:	e8 c1 49 00 00       	call   f0105b86 <cpunum>
f01011c5:	6b c0 74             	imul   $0x74,%eax,%eax
f01011c8:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
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
f0101260:	2b 1d 90 2e 23 f0    	sub    0xf0232e90,%ebx
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
f01012db:	8b 15 00 23 12 f0    	mov    0xf0122300,%edx
f01012e1:	8d 04 32             	lea    (%edx,%esi,1),%eax
f01012e4:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f01012e9:	77 2b                	ja     f0101316 <mmio_map_region+0x65>
	boot_map_region(kern_pgdir,base,size,pa,PTE_W|PTE_PCD|PTE_PWT);
f01012eb:	83 ec 08             	sub    $0x8,%esp
f01012ee:	6a 1a                	push   $0x1a
f01012f0:	53                   	push   %ebx
f01012f1:	89 f1                	mov    %esi,%ecx
f01012f3:	a1 8c 2e 23 f0       	mov    0xf0232e8c,%eax
f01012f8:	e8 f3 fd ff ff       	call   f01010f0 <boot_map_region>
	base+=size;
f01012fd:	89 f0                	mov    %esi,%eax
f01012ff:	03 05 00 23 12 f0    	add    0xf0122300,%eax
f0101305:	a3 00 23 12 f0       	mov    %eax,0xf0122300
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
f0101319:	68 1c 69 10 f0       	push   $0xf010691c
f010131e:	68 cf 02 00 00       	push   $0x2cf
f0101323:	68 5d 71 10 f0       	push   $0xf010715d
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
f010136f:	89 15 88 2e 23 f0    	mov    %edx,0xf0232e88
	npages_basemem = basemem / (PGSIZE / 1024);
f0101375:	89 da                	mov    %ebx,%edx
f0101377:	c1 ea 02             	shr    $0x2,%edx
f010137a:	89 15 44 22 23 f0    	mov    %edx,0xf0232244
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101380:	89 c2                	mov    %eax,%edx
f0101382:	29 da                	sub    %ebx,%edx
f0101384:	52                   	push   %edx
f0101385:	53                   	push   %ebx
f0101386:	50                   	push   %eax
f0101387:	68 44 69 10 f0       	push   $0xf0106944
f010138c:	e8 3c 26 00 00       	call   f01039cd <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101391:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101396:	e8 56 f7 ff ff       	call   f0100af1 <boot_alloc>
f010139b:	a3 8c 2e 23 f0       	mov    %eax,0xf0232e8c
	memset(kern_pgdir, 0, PGSIZE);
f01013a0:	83 c4 0c             	add    $0xc,%esp
f01013a3:	68 00 10 00 00       	push   $0x1000
f01013a8:	6a 00                	push   $0x0
f01013aa:	50                   	push   %eax
f01013ab:	e8 b7 41 00 00       	call   f0105567 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01013b0:	a1 8c 2e 23 f0       	mov    0xf0232e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01013b5:	83 c4 10             	add    $0x10,%esp
f01013b8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013bd:	0f 86 9c 00 00 00    	jbe    f010145f <mem_init+0x132>
	return (physaddr_t)kva - KERNBASE;
f01013c3:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01013c9:	83 ca 05             	or     $0x5,%edx
f01013cc:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages*sizeof(struct PageInfo));
f01013d2:	a1 88 2e 23 f0       	mov    0xf0232e88,%eax
f01013d7:	c1 e0 03             	shl    $0x3,%eax
f01013da:	e8 12 f7 ff ff       	call   f0100af1 <boot_alloc>
f01013df:	a3 90 2e 23 f0       	mov    %eax,0xf0232e90
	memset(pages,0,npages*sizeof(struct PageInfo));
f01013e4:	83 ec 04             	sub    $0x4,%esp
f01013e7:	8b 0d 88 2e 23 f0    	mov    0xf0232e88,%ecx
f01013ed:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01013f4:	52                   	push   %edx
f01013f5:	6a 00                	push   $0x0
f01013f7:	50                   	push   %eax
f01013f8:	e8 6a 41 00 00       	call   f0105567 <memset>
	envs = (struct Env*)boot_alloc(NENV*sizeof(struct Env));
f01013fd:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101402:	e8 ea f6 ff ff       	call   f0100af1 <boot_alloc>
f0101407:	a3 48 22 23 f0       	mov    %eax,0xf0232248
	memset(envs,0,NENV*sizeof(struct Env));
f010140c:	83 c4 0c             	add    $0xc,%esp
f010140f:	68 00 f0 01 00       	push   $0x1f000
f0101414:	6a 00                	push   $0x0
f0101416:	50                   	push   %eax
f0101417:	e8 4b 41 00 00       	call   f0105567 <memset>
	page_init();
f010141c:	e8 8a fa ff ff       	call   f0100eab <page_init>
	check_page_free_list(1);
f0101421:	b8 01 00 00 00       	mov    $0x1,%eax
f0101426:	e8 92 f7 ff ff       	call   f0100bbd <check_page_free_list>
	if (!pages)
f010142b:	83 c4 10             	add    $0x10,%esp
f010142e:	83 3d 90 2e 23 f0 00 	cmpl   $0x0,0xf0232e90
f0101435:	74 3d                	je     f0101474 <mem_init+0x147>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101437:	a1 40 22 23 f0       	mov    0xf0232240,%eax
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
f0101460:	68 48 62 10 f0       	push   $0xf0106248
f0101465:	68 a4 00 00 00       	push   $0xa4
f010146a:	68 5d 71 10 f0       	push   $0xf010715d
f010146f:	e8 cc eb ff ff       	call   f0100040 <_panic>
		panic("'pages' is a null pointer!");
f0101474:	83 ec 04             	sub    $0x4,%esp
f0101477:	68 30 72 10 f0       	push   $0xf0107230
f010147c:	68 77 03 00 00       	push   $0x377
f0101481:	68 5d 71 10 f0       	push   $0xf010715d
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
f01014e8:	8b 0d 90 2e 23 f0    	mov    0xf0232e90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014ee:	8b 15 88 2e 23 f0    	mov    0xf0232e88,%edx
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
f010152d:	a1 40 22 23 f0       	mov    0xf0232240,%eax
f0101532:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101535:	c7 05 40 22 23 f0 00 	movl   $0x0,0xf0232240
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
f01015e3:	2b 05 90 2e 23 f0    	sub    0xf0232e90,%eax
f01015e9:	c1 f8 03             	sar    $0x3,%eax
f01015ec:	89 c2                	mov    %eax,%edx
f01015ee:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01015f1:	25 ff ff 0f 00       	and    $0xfffff,%eax
f01015f6:	3b 05 88 2e 23 f0    	cmp    0xf0232e88,%eax
f01015fc:	0f 83 28 02 00 00    	jae    f010182a <mem_init+0x4fd>
	memset(page2kva(pp0), 1, PGSIZE);
f0101602:	83 ec 04             	sub    $0x4,%esp
f0101605:	68 00 10 00 00       	push   $0x1000
f010160a:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f010160c:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101612:	52                   	push   %edx
f0101613:	e8 4f 3f 00 00       	call   f0105567 <memset>
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
f010163f:	2b 05 90 2e 23 f0    	sub    0xf0232e90,%eax
f0101645:	c1 f8 03             	sar    $0x3,%eax
f0101648:	89 c2                	mov    %eax,%edx
f010164a:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010164d:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101652:	3b 05 88 2e 23 f0    	cmp    0xf0232e88,%eax
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
f010167d:	a3 40 22 23 f0       	mov    %eax,0xf0232240
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
f010169b:	a1 40 22 23 f0       	mov    0xf0232240,%eax
f01016a0:	83 c4 10             	add    $0x10,%esp
f01016a3:	85 c0                	test   %eax,%eax
f01016a5:	0f 84 ee 01 00 00    	je     f0101899 <mem_init+0x56c>
		--nfree;
f01016ab:	83 6d d4 01          	subl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016af:	8b 00                	mov    (%eax),%eax
f01016b1:	eb f0                	jmp    f01016a3 <mem_init+0x376>
	assert((pp0 = page_alloc(0)));
f01016b3:	68 4b 72 10 f0       	push   $0xf010724b
f01016b8:	68 83 71 10 f0       	push   $0xf0107183
f01016bd:	68 7f 03 00 00       	push   $0x37f
f01016c2:	68 5d 71 10 f0       	push   $0xf010715d
f01016c7:	e8 74 e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01016cc:	68 61 72 10 f0       	push   $0xf0107261
f01016d1:	68 83 71 10 f0       	push   $0xf0107183
f01016d6:	68 80 03 00 00       	push   $0x380
f01016db:	68 5d 71 10 f0       	push   $0xf010715d
f01016e0:	e8 5b e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01016e5:	68 77 72 10 f0       	push   $0xf0107277
f01016ea:	68 83 71 10 f0       	push   $0xf0107183
f01016ef:	68 81 03 00 00       	push   $0x381
f01016f4:	68 5d 71 10 f0       	push   $0xf010715d
f01016f9:	e8 42 e9 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f01016fe:	68 8d 72 10 f0       	push   $0xf010728d
f0101703:	68 83 71 10 f0       	push   $0xf0107183
f0101708:	68 84 03 00 00       	push   $0x384
f010170d:	68 5d 71 10 f0       	push   $0xf010715d
f0101712:	e8 29 e9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101717:	68 80 69 10 f0       	push   $0xf0106980
f010171c:	68 83 71 10 f0       	push   $0xf0107183
f0101721:	68 85 03 00 00       	push   $0x385
f0101726:	68 5d 71 10 f0       	push   $0xf010715d
f010172b:	e8 10 e9 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101730:	68 9f 72 10 f0       	push   $0xf010729f
f0101735:	68 83 71 10 f0       	push   $0xf0107183
f010173a:	68 86 03 00 00       	push   $0x386
f010173f:	68 5d 71 10 f0       	push   $0xf010715d
f0101744:	e8 f7 e8 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101749:	68 bc 72 10 f0       	push   $0xf01072bc
f010174e:	68 83 71 10 f0       	push   $0xf0107183
f0101753:	68 87 03 00 00       	push   $0x387
f0101758:	68 5d 71 10 f0       	push   $0xf010715d
f010175d:	e8 de e8 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101762:	68 d9 72 10 f0       	push   $0xf01072d9
f0101767:	68 83 71 10 f0       	push   $0xf0107183
f010176c:	68 88 03 00 00       	push   $0x388
f0101771:	68 5d 71 10 f0       	push   $0xf010715d
f0101776:	e8 c5 e8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f010177b:	68 f6 72 10 f0       	push   $0xf01072f6
f0101780:	68 83 71 10 f0       	push   $0xf0107183
f0101785:	68 8f 03 00 00       	push   $0x38f
f010178a:	68 5d 71 10 f0       	push   $0xf010715d
f010178f:	e8 ac e8 ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f0101794:	68 4b 72 10 f0       	push   $0xf010724b
f0101799:	68 83 71 10 f0       	push   $0xf0107183
f010179e:	68 96 03 00 00       	push   $0x396
f01017a3:	68 5d 71 10 f0       	push   $0xf010715d
f01017a8:	e8 93 e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01017ad:	68 61 72 10 f0       	push   $0xf0107261
f01017b2:	68 83 71 10 f0       	push   $0xf0107183
f01017b7:	68 97 03 00 00       	push   $0x397
f01017bc:	68 5d 71 10 f0       	push   $0xf010715d
f01017c1:	e8 7a e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01017c6:	68 77 72 10 f0       	push   $0xf0107277
f01017cb:	68 83 71 10 f0       	push   $0xf0107183
f01017d0:	68 98 03 00 00       	push   $0x398
f01017d5:	68 5d 71 10 f0       	push   $0xf010715d
f01017da:	e8 61 e8 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f01017df:	68 8d 72 10 f0       	push   $0xf010728d
f01017e4:	68 83 71 10 f0       	push   $0xf0107183
f01017e9:	68 9a 03 00 00       	push   $0x39a
f01017ee:	68 5d 71 10 f0       	push   $0xf010715d
f01017f3:	e8 48 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017f8:	68 80 69 10 f0       	push   $0xf0106980
f01017fd:	68 83 71 10 f0       	push   $0xf0107183
f0101802:	68 9b 03 00 00       	push   $0x39b
f0101807:	68 5d 71 10 f0       	push   $0xf010715d
f010180c:	e8 2f e8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101811:	68 f6 72 10 f0       	push   $0xf01072f6
f0101816:	68 83 71 10 f0       	push   $0xf0107183
f010181b:	68 9c 03 00 00       	push   $0x39c
f0101820:	68 5d 71 10 f0       	push   $0xf010715d
f0101825:	e8 16 e8 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010182a:	52                   	push   %edx
f010182b:	68 24 62 10 f0       	push   $0xf0106224
f0101830:	6a 58                	push   $0x58
f0101832:	68 69 71 10 f0       	push   $0xf0107169
f0101837:	e8 04 e8 ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010183c:	68 05 73 10 f0       	push   $0xf0107305
f0101841:	68 83 71 10 f0       	push   $0xf0107183
f0101846:	68 a1 03 00 00       	push   $0x3a1
f010184b:	68 5d 71 10 f0       	push   $0xf010715d
f0101850:	e8 eb e7 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101855:	68 23 73 10 f0       	push   $0xf0107323
f010185a:	68 83 71 10 f0       	push   $0xf0107183
f010185f:	68 a2 03 00 00       	push   $0x3a2
f0101864:	68 5d 71 10 f0       	push   $0xf010715d
f0101869:	e8 d2 e7 ff ff       	call   f0100040 <_panic>
f010186e:	52                   	push   %edx
f010186f:	68 24 62 10 f0       	push   $0xf0106224
f0101874:	6a 58                	push   $0x58
f0101876:	68 69 71 10 f0       	push   $0xf0107169
f010187b:	e8 c0 e7 ff ff       	call   f0100040 <_panic>
		assert(c[i] == 0);
f0101880:	68 33 73 10 f0       	push   $0xf0107333
f0101885:	68 83 71 10 f0       	push   $0xf0107183
f010188a:	68 a5 03 00 00       	push   $0x3a5
f010188f:	68 5d 71 10 f0       	push   $0xf010715d
f0101894:	e8 a7 e7 ff ff       	call   f0100040 <_panic>
	assert(nfree == 0);
f0101899:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f010189d:	0f 85 46 09 00 00    	jne    f01021e9 <mem_init+0xebc>
	cprintf("check_page_alloc() succeeded!\n");
f01018a3:	83 ec 0c             	sub    $0xc,%esp
f01018a6:	68 a0 69 10 f0       	push   $0xf01069a0
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
f0101912:	a1 40 22 23 f0       	mov    0xf0232240,%eax
f0101917:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f010191a:	c7 05 40 22 23 f0 00 	movl   $0x0,0xf0232240
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
f0101942:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
f0101948:	e8 ef f7 ff ff       	call   f010113c <page_lookup>
f010194d:	83 c4 10             	add    $0x10,%esp
f0101950:	85 c0                	test   %eax,%eax
f0101952:	0f 85 40 09 00 00    	jne    f0102298 <mem_init+0xf6b>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101958:	6a 02                	push   $0x2
f010195a:	6a 00                	push   $0x0
f010195c:	57                   	push   %edi
f010195d:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
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
f0101983:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
f0101989:	e8 a1 f8 ff ff       	call   f010122f <page_insert>
f010198e:	83 c4 20             	add    $0x20,%esp
f0101991:	85 c0                	test   %eax,%eax
f0101993:	0f 85 31 09 00 00    	jne    f01022ca <mem_init+0xf9d>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101999:	8b 35 8c 2e 23 f0    	mov    0xf0232e8c,%esi
	return (pp - pages) << PGSHIFT;
f010199f:	8b 0d 90 2e 23 f0    	mov    0xf0232e90,%ecx
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
f0101a1b:	a1 8c 2e 23 f0       	mov    0xf0232e8c,%eax
f0101a20:	e8 35 f1 ff ff       	call   f0100b5a <check_va2pa>
f0101a25:	89 c2                	mov    %eax,%edx
f0101a27:	89 d8                	mov    %ebx,%eax
f0101a29:	2b 05 90 2e 23 f0    	sub    0xf0232e90,%eax
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
f0101a65:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
f0101a6b:	e8 bf f7 ff ff       	call   f010122f <page_insert>
f0101a70:	83 c4 10             	add    $0x10,%esp
f0101a73:	85 c0                	test   %eax,%eax
f0101a75:	0f 85 30 09 00 00    	jne    f01023ab <mem_init+0x107e>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a7b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a80:	a1 8c 2e 23 f0       	mov    0xf0232e8c,%eax
f0101a85:	e8 d0 f0 ff ff       	call   f0100b5a <check_va2pa>
f0101a8a:	89 c2                	mov    %eax,%edx
f0101a8c:	89 d8                	mov    %ebx,%eax
f0101a8e:	2b 05 90 2e 23 f0    	sub    0xf0232e90,%eax
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
f0101ac2:	8b 0d 8c 2e 23 f0    	mov    0xf0232e8c,%ecx
f0101ac8:	8b 01                	mov    (%ecx),%eax
f0101aca:	89 c2                	mov    %eax,%edx
f0101acc:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101ad2:	c1 e8 0c             	shr    $0xc,%eax
f0101ad5:	3b 05 88 2e 23 f0    	cmp    0xf0232e88,%eax
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
f0101b15:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
f0101b1b:	e8 0f f7 ff ff       	call   f010122f <page_insert>
f0101b20:	83 c4 10             	add    $0x10,%esp
f0101b23:	85 c0                	test   %eax,%eax
f0101b25:	0f 85 12 09 00 00    	jne    f010243d <mem_init+0x1110>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b2b:	8b 35 8c 2e 23 f0    	mov    0xf0232e8c,%esi
f0101b31:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b36:	89 f0                	mov    %esi,%eax
f0101b38:	e8 1d f0 ff ff       	call   f0100b5a <check_va2pa>
f0101b3d:	89 c2                	mov    %eax,%edx
	return (pp - pages) << PGSHIFT;
f0101b3f:	89 d8                	mov    %ebx,%eax
f0101b41:	2b 05 90 2e 23 f0    	sub    0xf0232e90,%eax
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
f0101b7c:	a1 8c 2e 23 f0       	mov    0xf0232e8c,%eax
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
f0101bad:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
f0101bb3:	e8 a7 f4 ff ff       	call   f010105f <pgdir_walk>
f0101bb8:	83 c4 10             	add    $0x10,%esp
f0101bbb:	f6 00 02             	testb  $0x2,(%eax)
f0101bbe:	0f 84 0f 09 00 00    	je     f01024d3 <mem_init+0x11a6>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bc4:	83 ec 04             	sub    $0x4,%esp
f0101bc7:	6a 00                	push   $0x0
f0101bc9:	68 00 10 00 00       	push   $0x1000
f0101bce:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
f0101bd4:	e8 86 f4 ff ff       	call   f010105f <pgdir_walk>
f0101bd9:	83 c4 10             	add    $0x10,%esp
f0101bdc:	f6 00 04             	testb  $0x4,(%eax)
f0101bdf:	0f 85 07 09 00 00    	jne    f01024ec <mem_init+0x11bf>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101be5:	6a 02                	push   $0x2
f0101be7:	68 00 00 40 00       	push   $0x400000
f0101bec:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101bef:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
f0101bf5:	e8 35 f6 ff ff       	call   f010122f <page_insert>
f0101bfa:	83 c4 10             	add    $0x10,%esp
f0101bfd:	85 c0                	test   %eax,%eax
f0101bff:	0f 89 00 09 00 00    	jns    f0102505 <mem_init+0x11d8>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c05:	6a 02                	push   $0x2
f0101c07:	68 00 10 00 00       	push   $0x1000
f0101c0c:	57                   	push   %edi
f0101c0d:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
f0101c13:	e8 17 f6 ff ff       	call   f010122f <page_insert>
f0101c18:	83 c4 10             	add    $0x10,%esp
f0101c1b:	85 c0                	test   %eax,%eax
f0101c1d:	0f 85 fb 08 00 00    	jne    f010251e <mem_init+0x11f1>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c23:	83 ec 04             	sub    $0x4,%esp
f0101c26:	6a 00                	push   $0x0
f0101c28:	68 00 10 00 00       	push   $0x1000
f0101c2d:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
f0101c33:	e8 27 f4 ff ff       	call   f010105f <pgdir_walk>
f0101c38:	83 c4 10             	add    $0x10,%esp
f0101c3b:	f6 00 04             	testb  $0x4,(%eax)
f0101c3e:	0f 85 f3 08 00 00    	jne    f0102537 <mem_init+0x120a>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c44:	a1 8c 2e 23 f0       	mov    0xf0232e8c,%eax
f0101c49:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101c4c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c51:	e8 04 ef ff ff       	call   f0100b5a <check_va2pa>
f0101c56:	89 fe                	mov    %edi,%esi
f0101c58:	2b 35 90 2e 23 f0    	sub    0xf0232e90,%esi
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
f0101cb9:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
f0101cbf:	e8 1a f5 ff ff       	call   f01011de <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cc4:	8b 35 8c 2e 23 f0    	mov    0xf0232e8c,%esi
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
f0101cf2:	2b 05 90 2e 23 f0    	sub    0xf0232e90,%eax
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
f0101d51:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
f0101d57:	e8 82 f4 ff ff       	call   f01011de <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d5c:	8b 35 8c 2e 23 f0    	mov    0xf0232e8c,%esi
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
f0101dd7:	8b 0d 8c 2e 23 f0    	mov    0xf0232e8c,%ecx
f0101ddd:	8b 11                	mov    (%ecx),%edx
f0101ddf:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101de5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101de8:	2b 05 90 2e 23 f0    	sub    0xf0232e90,%eax
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
f0101e2c:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
f0101e32:	e8 28 f2 ff ff       	call   f010105f <pgdir_walk>
f0101e37:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101e3a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101e3d:	8b 0d 8c 2e 23 f0    	mov    0xf0232e8c,%ecx
f0101e43:	8b 41 04             	mov    0x4(%ecx),%eax
f0101e46:	89 c6                	mov    %eax,%esi
f0101e48:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	if (PGNUM(pa) >= npages)
f0101e4e:	8b 15 88 2e 23 f0    	mov    0xf0232e88,%edx
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
f0101e81:	2b 05 90 2e 23 f0    	sub    0xf0232e90,%eax
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
f0101eb0:	e8 b2 36 00 00       	call   f0105567 <memset>
	page_free(pp0);
f0101eb5:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101eb8:	89 34 24             	mov    %esi,(%esp)
f0101ebb:	e8 33 f1 ff ff       	call   f0100ff3 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101ec0:	83 c4 0c             	add    $0xc,%esp
f0101ec3:	6a 01                	push   $0x1
f0101ec5:	6a 00                	push   $0x0
f0101ec7:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
f0101ecd:	e8 8d f1 ff ff       	call   f010105f <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0101ed2:	89 f0                	mov    %esi,%eax
f0101ed4:	2b 05 90 2e 23 f0    	sub    0xf0232e90,%eax
f0101eda:	c1 f8 03             	sar    $0x3,%eax
f0101edd:	89 c2                	mov    %eax,%edx
f0101edf:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101ee2:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101ee7:	83 c4 10             	add    $0x10,%esp
f0101eea:	3b 05 88 2e 23 f0    	cmp    0xf0232e88,%eax
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
f0101f15:	a1 8c 2e 23 f0       	mov    0xf0232e8c,%eax
f0101f1a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101f20:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f23:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0101f29:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101f2c:	89 0d 40 22 23 f0    	mov    %ecx,0xf0232240

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
f0101fc3:	8b 3d 8c 2e 23 f0    	mov    0xf0232e8c,%edi
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
f010203c:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
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
f010205d:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
f0102063:	e8 f7 ef ff ff       	call   f010105f <pgdir_walk>
f0102068:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f010206e:	83 c4 0c             	add    $0xc,%esp
f0102071:	6a 00                	push   $0x0
f0102073:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102076:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
f010207c:	e8 de ef ff ff       	call   f010105f <pgdir_walk>
f0102081:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102087:	83 c4 0c             	add    $0xc,%esp
f010208a:	6a 00                	push   $0x0
f010208c:	56                   	push   %esi
f010208d:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
f0102093:	e8 c7 ef ff ff       	call   f010105f <pgdir_walk>
f0102098:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f010209e:	c7 04 24 26 74 10 f0 	movl   $0xf0107426,(%esp)
f01020a5:	e8 23 19 00 00       	call   f01039cd <cprintf>
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U);
f01020aa:	a1 90 2e 23 f0       	mov    0xf0232e90,%eax
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
f01020d2:	a1 8c 2e 23 f0       	mov    0xf0232e8c,%eax
f01020d7:	e8 14 f0 ff ff       	call   f01010f0 <boot_map_region>
	boot_map_region(kern_pgdir,UENVS,PTSIZE,PADDR(envs),PTE_U);
f01020dc:	a1 48 22 23 f0       	mov    0xf0232248,%eax
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
f0102104:	a1 8c 2e 23 f0       	mov    0xf0232e8c,%eax
f0102109:	e8 e2 ef ff ff       	call   f01010f0 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f010210e:	83 c4 10             	add    $0x10,%esp
f0102111:	b8 00 80 11 f0       	mov    $0xf0118000,%eax
f0102116:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010211b:	0f 86 b2 07 00 00    	jbe    f01028d3 <mem_init+0x15a6>
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f0102121:	83 ec 08             	sub    $0x8,%esp
f0102124:	6a 02                	push   $0x2
f0102126:	68 00 80 11 00       	push   $0x118000
f010212b:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102130:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102135:	a1 8c 2e 23 f0       	mov    0xf0232e8c,%eax
f010213a:	e8 b1 ef ff ff       	call   f01010f0 <boot_map_region>
f010213f:	c7 45 d0 00 40 23 f0 	movl   $0xf0234000,-0x30(%ebp)
f0102146:	83 c4 10             	add    $0x10,%esp
f0102149:	bb 00 40 23 f0       	mov    $0xf0234000,%ebx
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
f0102172:	a1 8c 2e 23 f0       	mov    0xf0232e8c,%eax
f0102177:	e8 74 ef ff ff       	call   f01010f0 <boot_map_region>
f010217c:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102182:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	for(int i = 0;i<NCPU;i++)
f0102188:	83 c4 10             	add    $0x10,%esp
f010218b:	81 fb 00 40 27 f0    	cmp    $0xf0274000,%ebx
f0102191:	75 c0                	jne    f0102153 <mem_init+0xe26>
	boot_map_region(kern_pgdir,KERNBASE,0xFFFFFFFF-KERNBASE,0,PTE_W);
f0102193:	83 ec 08             	sub    $0x8,%esp
f0102196:	6a 02                	push   $0x2
f0102198:	6a 00                	push   $0x0
f010219a:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010219f:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021a4:	a1 8c 2e 23 f0       	mov    0xf0232e8c,%eax
f01021a9:	e8 42 ef ff ff       	call   f01010f0 <boot_map_region>
	pgdir = kern_pgdir;
f01021ae:	a1 8c 2e 23 f0       	mov    0xf0232e8c,%eax
f01021b3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021b6:	a1 88 2e 23 f0       	mov    0xf0232e88,%eax
f01021bb:	89 45 c0             	mov    %eax,-0x40(%ebp)
f01021be:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021c5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021ca:	89 45 cc             	mov    %eax,-0x34(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021cd:	8b 35 90 2e 23 f0    	mov    0xf0232e90,%esi
f01021d3:	89 75 c8             	mov    %esi,-0x38(%ebp)
	return (physaddr_t)kva - KERNBASE;
f01021d6:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01021dc:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f01021df:	83 c4 10             	add    $0x10,%esp
f01021e2:	89 fb                	mov    %edi,%ebx
f01021e4:	e9 2f 07 00 00       	jmp    f0102918 <mem_init+0x15eb>
	assert(nfree == 0);
f01021e9:	68 3d 73 10 f0       	push   $0xf010733d
f01021ee:	68 83 71 10 f0       	push   $0xf0107183
f01021f3:	68 b2 03 00 00       	push   $0x3b2
f01021f8:	68 5d 71 10 f0       	push   $0xf010715d
f01021fd:	e8 3e de ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f0102202:	68 4b 72 10 f0       	push   $0xf010724b
f0102207:	68 83 71 10 f0       	push   $0xf0107183
f010220c:	68 18 04 00 00       	push   $0x418
f0102211:	68 5d 71 10 f0       	push   $0xf010715d
f0102216:	e8 25 de ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010221b:	68 61 72 10 f0       	push   $0xf0107261
f0102220:	68 83 71 10 f0       	push   $0xf0107183
f0102225:	68 19 04 00 00       	push   $0x419
f010222a:	68 5d 71 10 f0       	push   $0xf010715d
f010222f:	e8 0c de ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102234:	68 77 72 10 f0       	push   $0xf0107277
f0102239:	68 83 71 10 f0       	push   $0xf0107183
f010223e:	68 1a 04 00 00       	push   $0x41a
f0102243:	68 5d 71 10 f0       	push   $0xf010715d
f0102248:	e8 f3 dd ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f010224d:	68 8d 72 10 f0       	push   $0xf010728d
f0102252:	68 83 71 10 f0       	push   $0xf0107183
f0102257:	68 1d 04 00 00       	push   $0x41d
f010225c:	68 5d 71 10 f0       	push   $0xf010715d
f0102261:	e8 da dd ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0102266:	68 80 69 10 f0       	push   $0xf0106980
f010226b:	68 83 71 10 f0       	push   $0xf0107183
f0102270:	68 1e 04 00 00       	push   $0x41e
f0102275:	68 5d 71 10 f0       	push   $0xf010715d
f010227a:	e8 c1 dd ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f010227f:	68 f6 72 10 f0       	push   $0xf01072f6
f0102284:	68 83 71 10 f0       	push   $0xf0107183
f0102289:	68 25 04 00 00       	push   $0x425
f010228e:	68 5d 71 10 f0       	push   $0xf010715d
f0102293:	e8 a8 dd ff ff       	call   f0100040 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102298:	68 c0 69 10 f0       	push   $0xf01069c0
f010229d:	68 83 71 10 f0       	push   $0xf0107183
f01022a2:	68 28 04 00 00       	push   $0x428
f01022a7:	68 5d 71 10 f0       	push   $0xf010715d
f01022ac:	e8 8f dd ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01022b1:	68 f8 69 10 f0       	push   $0xf01069f8
f01022b6:	68 83 71 10 f0       	push   $0xf0107183
f01022bb:	68 2b 04 00 00       	push   $0x42b
f01022c0:	68 5d 71 10 f0       	push   $0xf010715d
f01022c5:	e8 76 dd ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01022ca:	68 28 6a 10 f0       	push   $0xf0106a28
f01022cf:	68 83 71 10 f0       	push   $0xf0107183
f01022d4:	68 2f 04 00 00       	push   $0x42f
f01022d9:	68 5d 71 10 f0       	push   $0xf010715d
f01022de:	e8 5d dd ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01022e3:	68 58 6a 10 f0       	push   $0xf0106a58
f01022e8:	68 83 71 10 f0       	push   $0xf0107183
f01022ed:	68 30 04 00 00       	push   $0x430
f01022f2:	68 5d 71 10 f0       	push   $0xf010715d
f01022f7:	e8 44 dd ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01022fc:	68 80 6a 10 f0       	push   $0xf0106a80
f0102301:	68 83 71 10 f0       	push   $0xf0107183
f0102306:	68 31 04 00 00       	push   $0x431
f010230b:	68 5d 71 10 f0       	push   $0xf010715d
f0102310:	e8 2b dd ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102315:	68 48 73 10 f0       	push   $0xf0107348
f010231a:	68 83 71 10 f0       	push   $0xf0107183
f010231f:	68 32 04 00 00       	push   $0x432
f0102324:	68 5d 71 10 f0       	push   $0xf010715d
f0102329:	e8 12 dd ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f010232e:	68 59 73 10 f0       	push   $0xf0107359
f0102333:	68 83 71 10 f0       	push   $0xf0107183
f0102338:	68 33 04 00 00       	push   $0x433
f010233d:	68 5d 71 10 f0       	push   $0xf010715d
f0102342:	e8 f9 dc ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102347:	68 b0 6a 10 f0       	push   $0xf0106ab0
f010234c:	68 83 71 10 f0       	push   $0xf0107183
f0102351:	68 36 04 00 00       	push   $0x436
f0102356:	68 5d 71 10 f0       	push   $0xf010715d
f010235b:	e8 e0 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102360:	68 ec 6a 10 f0       	push   $0xf0106aec
f0102365:	68 83 71 10 f0       	push   $0xf0107183
f010236a:	68 37 04 00 00       	push   $0x437
f010236f:	68 5d 71 10 f0       	push   $0xf010715d
f0102374:	e8 c7 dc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102379:	68 6a 73 10 f0       	push   $0xf010736a
f010237e:	68 83 71 10 f0       	push   $0xf0107183
f0102383:	68 38 04 00 00       	push   $0x438
f0102388:	68 5d 71 10 f0       	push   $0xf010715d
f010238d:	e8 ae dc ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0102392:	68 f6 72 10 f0       	push   $0xf01072f6
f0102397:	68 83 71 10 f0       	push   $0xf0107183
f010239c:	68 3b 04 00 00       	push   $0x43b
f01023a1:	68 5d 71 10 f0       	push   $0xf010715d
f01023a6:	e8 95 dc ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023ab:	68 b0 6a 10 f0       	push   $0xf0106ab0
f01023b0:	68 83 71 10 f0       	push   $0xf0107183
f01023b5:	68 3e 04 00 00       	push   $0x43e
f01023ba:	68 5d 71 10 f0       	push   $0xf010715d
f01023bf:	e8 7c dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01023c4:	68 ec 6a 10 f0       	push   $0xf0106aec
f01023c9:	68 83 71 10 f0       	push   $0xf0107183
f01023ce:	68 3f 04 00 00       	push   $0x43f
f01023d3:	68 5d 71 10 f0       	push   $0xf010715d
f01023d8:	e8 63 dc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01023dd:	68 6a 73 10 f0       	push   $0xf010736a
f01023e2:	68 83 71 10 f0       	push   $0xf0107183
f01023e7:	68 40 04 00 00       	push   $0x440
f01023ec:	68 5d 71 10 f0       	push   $0xf010715d
f01023f1:	e8 4a dc ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01023f6:	68 f6 72 10 f0       	push   $0xf01072f6
f01023fb:	68 83 71 10 f0       	push   $0xf0107183
f0102400:	68 44 04 00 00       	push   $0x444
f0102405:	68 5d 71 10 f0       	push   $0xf010715d
f010240a:	e8 31 dc ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010240f:	52                   	push   %edx
f0102410:	68 24 62 10 f0       	push   $0xf0106224
f0102415:	68 47 04 00 00       	push   $0x447
f010241a:	68 5d 71 10 f0       	push   $0xf010715d
f010241f:	e8 1c dc ff ff       	call   f0100040 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102424:	68 1c 6b 10 f0       	push   $0xf0106b1c
f0102429:	68 83 71 10 f0       	push   $0xf0107183
f010242e:	68 48 04 00 00       	push   $0x448
f0102433:	68 5d 71 10 f0       	push   $0xf010715d
f0102438:	e8 03 dc ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010243d:	68 5c 6b 10 f0       	push   $0xf0106b5c
f0102442:	68 83 71 10 f0       	push   $0xf0107183
f0102447:	68 4b 04 00 00       	push   $0x44b
f010244c:	68 5d 71 10 f0       	push   $0xf010715d
f0102451:	e8 ea db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102456:	68 ec 6a 10 f0       	push   $0xf0106aec
f010245b:	68 83 71 10 f0       	push   $0xf0107183
f0102460:	68 4c 04 00 00       	push   $0x44c
f0102465:	68 5d 71 10 f0       	push   $0xf010715d
f010246a:	e8 d1 db ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f010246f:	68 6a 73 10 f0       	push   $0xf010736a
f0102474:	68 83 71 10 f0       	push   $0xf0107183
f0102479:	68 4d 04 00 00       	push   $0x44d
f010247e:	68 5d 71 10 f0       	push   $0xf010715d
f0102483:	e8 b8 db ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102488:	68 9c 6b 10 f0       	push   $0xf0106b9c
f010248d:	68 83 71 10 f0       	push   $0xf0107183
f0102492:	68 4e 04 00 00       	push   $0x44e
f0102497:	68 5d 71 10 f0       	push   $0xf010715d
f010249c:	e8 9f db ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01024a1:	68 7b 73 10 f0       	push   $0xf010737b
f01024a6:	68 83 71 10 f0       	push   $0xf0107183
f01024ab:	68 4f 04 00 00       	push   $0x44f
f01024b0:	68 5d 71 10 f0       	push   $0xf010715d
f01024b5:	e8 86 db ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01024ba:	68 b0 6a 10 f0       	push   $0xf0106ab0
f01024bf:	68 83 71 10 f0       	push   $0xf0107183
f01024c4:	68 52 04 00 00       	push   $0x452
f01024c9:	68 5d 71 10 f0       	push   $0xf010715d
f01024ce:	e8 6d db ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01024d3:	68 d0 6b 10 f0       	push   $0xf0106bd0
f01024d8:	68 83 71 10 f0       	push   $0xf0107183
f01024dd:	68 53 04 00 00       	push   $0x453
f01024e2:	68 5d 71 10 f0       	push   $0xf010715d
f01024e7:	e8 54 db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01024ec:	68 04 6c 10 f0       	push   $0xf0106c04
f01024f1:	68 83 71 10 f0       	push   $0xf0107183
f01024f6:	68 54 04 00 00       	push   $0x454
f01024fb:	68 5d 71 10 f0       	push   $0xf010715d
f0102500:	e8 3b db ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102505:	68 3c 6c 10 f0       	push   $0xf0106c3c
f010250a:	68 83 71 10 f0       	push   $0xf0107183
f010250f:	68 57 04 00 00       	push   $0x457
f0102514:	68 5d 71 10 f0       	push   $0xf010715d
f0102519:	e8 22 db ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010251e:	68 74 6c 10 f0       	push   $0xf0106c74
f0102523:	68 83 71 10 f0       	push   $0xf0107183
f0102528:	68 5a 04 00 00       	push   $0x45a
f010252d:	68 5d 71 10 f0       	push   $0xf010715d
f0102532:	e8 09 db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102537:	68 04 6c 10 f0       	push   $0xf0106c04
f010253c:	68 83 71 10 f0       	push   $0xf0107183
f0102541:	68 5b 04 00 00       	push   $0x45b
f0102546:	68 5d 71 10 f0       	push   $0xf010715d
f010254b:	e8 f0 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102550:	68 b0 6c 10 f0       	push   $0xf0106cb0
f0102555:	68 83 71 10 f0       	push   $0xf0107183
f010255a:	68 5e 04 00 00       	push   $0x45e
f010255f:	68 5d 71 10 f0       	push   $0xf010715d
f0102564:	e8 d7 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102569:	68 dc 6c 10 f0       	push   $0xf0106cdc
f010256e:	68 83 71 10 f0       	push   $0xf0107183
f0102573:	68 5f 04 00 00       	push   $0x45f
f0102578:	68 5d 71 10 f0       	push   $0xf010715d
f010257d:	e8 be da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 2);
f0102582:	68 91 73 10 f0       	push   $0xf0107391
f0102587:	68 83 71 10 f0       	push   $0xf0107183
f010258c:	68 61 04 00 00       	push   $0x461
f0102591:	68 5d 71 10 f0       	push   $0xf010715d
f0102596:	e8 a5 da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010259b:	68 a2 73 10 f0       	push   $0xf01073a2
f01025a0:	68 83 71 10 f0       	push   $0xf0107183
f01025a5:	68 62 04 00 00       	push   $0x462
f01025aa:	68 5d 71 10 f0       	push   $0xf010715d
f01025af:	e8 8c da ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f01025b4:	68 0c 6d 10 f0       	push   $0xf0106d0c
f01025b9:	68 83 71 10 f0       	push   $0xf0107183
f01025be:	68 65 04 00 00       	push   $0x465
f01025c3:	68 5d 71 10 f0       	push   $0xf010715d
f01025c8:	e8 73 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01025cd:	68 30 6d 10 f0       	push   $0xf0106d30
f01025d2:	68 83 71 10 f0       	push   $0xf0107183
f01025d7:	68 69 04 00 00       	push   $0x469
f01025dc:	68 5d 71 10 f0       	push   $0xf010715d
f01025e1:	e8 5a da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01025e6:	68 dc 6c 10 f0       	push   $0xf0106cdc
f01025eb:	68 83 71 10 f0       	push   $0xf0107183
f01025f0:	68 6a 04 00 00       	push   $0x46a
f01025f5:	68 5d 71 10 f0       	push   $0xf010715d
f01025fa:	e8 41 da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01025ff:	68 48 73 10 f0       	push   $0xf0107348
f0102604:	68 83 71 10 f0       	push   $0xf0107183
f0102609:	68 6b 04 00 00       	push   $0x46b
f010260e:	68 5d 71 10 f0       	push   $0xf010715d
f0102613:	e8 28 da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102618:	68 a2 73 10 f0       	push   $0xf01073a2
f010261d:	68 83 71 10 f0       	push   $0xf0107183
f0102622:	68 6c 04 00 00       	push   $0x46c
f0102627:	68 5d 71 10 f0       	push   $0xf010715d
f010262c:	e8 0f da ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102631:	68 54 6d 10 f0       	push   $0xf0106d54
f0102636:	68 83 71 10 f0       	push   $0xf0107183
f010263b:	68 6f 04 00 00       	push   $0x46f
f0102640:	68 5d 71 10 f0       	push   $0xf010715d
f0102645:	e8 f6 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f010264a:	68 b3 73 10 f0       	push   $0xf01073b3
f010264f:	68 83 71 10 f0       	push   $0xf0107183
f0102654:	68 70 04 00 00       	push   $0x470
f0102659:	68 5d 71 10 f0       	push   $0xf010715d
f010265e:	e8 dd d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0102663:	68 bf 73 10 f0       	push   $0xf01073bf
f0102668:	68 83 71 10 f0       	push   $0xf0107183
f010266d:	68 71 04 00 00       	push   $0x471
f0102672:	68 5d 71 10 f0       	push   $0xf010715d
f0102677:	e8 c4 d9 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010267c:	68 30 6d 10 f0       	push   $0xf0106d30
f0102681:	68 83 71 10 f0       	push   $0xf0107183
f0102686:	68 75 04 00 00       	push   $0x475
f010268b:	68 5d 71 10 f0       	push   $0xf010715d
f0102690:	e8 ab d9 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102695:	68 8c 6d 10 f0       	push   $0xf0106d8c
f010269a:	68 83 71 10 f0       	push   $0xf0107183
f010269f:	68 76 04 00 00       	push   $0x476
f01026a4:	68 5d 71 10 f0       	push   $0xf010715d
f01026a9:	e8 92 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01026ae:	68 d4 73 10 f0       	push   $0xf01073d4
f01026b3:	68 83 71 10 f0       	push   $0xf0107183
f01026b8:	68 77 04 00 00       	push   $0x477
f01026bd:	68 5d 71 10 f0       	push   $0xf010715d
f01026c2:	e8 79 d9 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01026c7:	68 a2 73 10 f0       	push   $0xf01073a2
f01026cc:	68 83 71 10 f0       	push   $0xf0107183
f01026d1:	68 78 04 00 00       	push   $0x478
f01026d6:	68 5d 71 10 f0       	push   $0xf010715d
f01026db:	e8 60 d9 ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f01026e0:	68 b4 6d 10 f0       	push   $0xf0106db4
f01026e5:	68 83 71 10 f0       	push   $0xf0107183
f01026ea:	68 7b 04 00 00       	push   $0x47b
f01026ef:	68 5d 71 10 f0       	push   $0xf010715d
f01026f4:	e8 47 d9 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01026f9:	68 f6 72 10 f0       	push   $0xf01072f6
f01026fe:	68 83 71 10 f0       	push   $0xf0107183
f0102703:	68 7e 04 00 00       	push   $0x47e
f0102708:	68 5d 71 10 f0       	push   $0xf010715d
f010270d:	e8 2e d9 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102712:	68 58 6a 10 f0       	push   $0xf0106a58
f0102717:	68 83 71 10 f0       	push   $0xf0107183
f010271c:	68 81 04 00 00       	push   $0x481
f0102721:	68 5d 71 10 f0       	push   $0xf010715d
f0102726:	e8 15 d9 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f010272b:	68 59 73 10 f0       	push   $0xf0107359
f0102730:	68 83 71 10 f0       	push   $0xf0107183
f0102735:	68 83 04 00 00       	push   $0x483
f010273a:	68 5d 71 10 f0       	push   $0xf010715d
f010273f:	e8 fc d8 ff ff       	call   f0100040 <_panic>
f0102744:	56                   	push   %esi
f0102745:	68 24 62 10 f0       	push   $0xf0106224
f010274a:	68 8a 04 00 00       	push   $0x48a
f010274f:	68 5d 71 10 f0       	push   $0xf010715d
f0102754:	e8 e7 d8 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102759:	68 e5 73 10 f0       	push   $0xf01073e5
f010275e:	68 83 71 10 f0       	push   $0xf0107183
f0102763:	68 8b 04 00 00       	push   $0x48b
f0102768:	68 5d 71 10 f0       	push   $0xf010715d
f010276d:	e8 ce d8 ff ff       	call   f0100040 <_panic>
f0102772:	51                   	push   %ecx
f0102773:	68 24 62 10 f0       	push   $0xf0106224
f0102778:	6a 58                	push   $0x58
f010277a:	68 69 71 10 f0       	push   $0xf0107169
f010277f:	e8 bc d8 ff ff       	call   f0100040 <_panic>
f0102784:	52                   	push   %edx
f0102785:	68 24 62 10 f0       	push   $0xf0106224
f010278a:	6a 58                	push   $0x58
f010278c:	68 69 71 10 f0       	push   $0xf0107169
f0102791:	e8 aa d8 ff ff       	call   f0100040 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102796:	68 fd 73 10 f0       	push   $0xf01073fd
f010279b:	68 83 71 10 f0       	push   $0xf0107183
f01027a0:	68 95 04 00 00       	push   $0x495
f01027a5:	68 5d 71 10 f0       	push   $0xf010715d
f01027aa:	e8 91 d8 ff ff       	call   f0100040 <_panic>
	assert(mm1 >= MMIOBASE && mm1 + 8192 < MMIOLIM);
f01027af:	68 d8 6d 10 f0       	push   $0xf0106dd8
f01027b4:	68 83 71 10 f0       	push   $0xf0107183
f01027b9:	68 a5 04 00 00       	push   $0x4a5
f01027be:	68 5d 71 10 f0       	push   $0xf010715d
f01027c3:	e8 78 d8 ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8192 < MMIOLIM);
f01027c8:	68 00 6e 10 f0       	push   $0xf0106e00
f01027cd:	68 83 71 10 f0       	push   $0xf0107183
f01027d2:	68 a6 04 00 00       	push   $0x4a6
f01027d7:	68 5d 71 10 f0       	push   $0xf010715d
f01027dc:	e8 5f d8 ff ff       	call   f0100040 <_panic>
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f01027e1:	68 28 6e 10 f0       	push   $0xf0106e28
f01027e6:	68 83 71 10 f0       	push   $0xf0107183
f01027eb:	68 a8 04 00 00       	push   $0x4a8
f01027f0:	68 5d 71 10 f0       	push   $0xf010715d
f01027f5:	e8 46 d8 ff ff       	call   f0100040 <_panic>
	assert(mm1 + 8192 <= mm2);
f01027fa:	68 14 74 10 f0       	push   $0xf0107414
f01027ff:	68 83 71 10 f0       	push   $0xf0107183
f0102804:	68 aa 04 00 00       	push   $0x4aa
f0102809:	68 5d 71 10 f0       	push   $0xf010715d
f010280e:	e8 2d d8 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102813:	68 50 6e 10 f0       	push   $0xf0106e50
f0102818:	68 83 71 10 f0       	push   $0xf0107183
f010281d:	68 ac 04 00 00       	push   $0x4ac
f0102822:	68 5d 71 10 f0       	push   $0xf010715d
f0102827:	e8 14 d8 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f010282c:	68 74 6e 10 f0       	push   $0xf0106e74
f0102831:	68 83 71 10 f0       	push   $0xf0107183
f0102836:	68 ad 04 00 00       	push   $0x4ad
f010283b:	68 5d 71 10 f0       	push   $0xf010715d
f0102840:	e8 fb d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102845:	68 a4 6e 10 f0       	push   $0xf0106ea4
f010284a:	68 83 71 10 f0       	push   $0xf0107183
f010284f:	68 ae 04 00 00       	push   $0x4ae
f0102854:	68 5d 71 10 f0       	push   $0xf010715d
f0102859:	e8 e2 d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f010285e:	68 c8 6e 10 f0       	push   $0xf0106ec8
f0102863:	68 83 71 10 f0       	push   $0xf0107183
f0102868:	68 af 04 00 00       	push   $0x4af
f010286d:	68 5d 71 10 f0       	push   $0xf010715d
f0102872:	e8 c9 d7 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102877:	68 f4 6e 10 f0       	push   $0xf0106ef4
f010287c:	68 83 71 10 f0       	push   $0xf0107183
f0102881:	68 b1 04 00 00       	push   $0x4b1
f0102886:	68 5d 71 10 f0       	push   $0xf010715d
f010288b:	e8 b0 d7 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102890:	68 38 6f 10 f0       	push   $0xf0106f38
f0102895:	68 83 71 10 f0       	push   $0xf0107183
f010289a:	68 b2 04 00 00       	push   $0x4b2
f010289f:	68 5d 71 10 f0       	push   $0xf010715d
f01028a4:	e8 97 d7 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028a9:	50                   	push   %eax
f01028aa:	68 48 62 10 f0       	push   $0xf0106248
f01028af:	68 cb 00 00 00       	push   $0xcb
f01028b4:	68 5d 71 10 f0       	push   $0xf010715d
f01028b9:	e8 82 d7 ff ff       	call   f0100040 <_panic>
f01028be:	50                   	push   %eax
f01028bf:	68 48 62 10 f0       	push   $0xf0106248
f01028c4:	68 d3 00 00 00       	push   $0xd3
f01028c9:	68 5d 71 10 f0       	push   $0xf010715d
f01028ce:	e8 6d d7 ff ff       	call   f0100040 <_panic>
f01028d3:	50                   	push   %eax
f01028d4:	68 48 62 10 f0       	push   $0xf0106248
f01028d9:	68 df 00 00 00       	push   $0xdf
f01028de:	68 5d 71 10 f0       	push   $0xf010715d
f01028e3:	e8 58 d7 ff ff       	call   f0100040 <_panic>
f01028e8:	53                   	push   %ebx
f01028e9:	68 48 62 10 f0       	push   $0xf0106248
f01028ee:	68 1f 01 00 00       	push   $0x11f
f01028f3:	68 5d 71 10 f0       	push   $0xf010715d
f01028f8:	e8 43 d7 ff ff       	call   f0100040 <_panic>
f01028fd:	56                   	push   %esi
f01028fe:	68 48 62 10 f0       	push   $0xf0106248
f0102903:	68 ca 03 00 00       	push   $0x3ca
f0102908:	68 5d 71 10 f0       	push   $0xf010715d
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
f010293e:	68 6c 6f 10 f0       	push   $0xf0106f6c
f0102943:	68 83 71 10 f0       	push   $0xf0107183
f0102948:	68 ca 03 00 00       	push   $0x3ca
f010294d:	68 5d 71 10 f0       	push   $0xf010715d
f0102952:	e8 e9 d6 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102957:	a1 48 22 23 f0       	mov    0xf0232248,%eax
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
f01029be:	68 48 62 10 f0       	push   $0xf0106248
f01029c3:	68 cf 03 00 00       	push   $0x3cf
f01029c8:	68 5d 71 10 f0       	push   $0xf010715d
f01029cd:	e8 6e d6 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01029d2:	68 a0 6f 10 f0       	push   $0xf0106fa0
f01029d7:	68 83 71 10 f0       	push   $0xf0107183
f01029dc:	68 cf 03 00 00       	push   $0x3cf
f01029e1:	68 5d 71 10 f0       	push   $0xf010715d
f01029e6:	e8 55 d6 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01029eb:	68 d4 6f 10 f0       	push   $0xf0106fd4
f01029f0:	68 83 71 10 f0       	push   $0xf0107183
f01029f5:	68 d3 03 00 00       	push   $0x3d3
f01029fa:	68 5d 71 10 f0       	push   $0xf010715d
f01029ff:	e8 3c d6 ff ff       	call   f0100040 <_panic>
f0102a04:	c7 45 cc 00 40 24 00 	movl   $0x244000,-0x34(%ebp)
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
f0102a8d:	3d 00 40 27 f0       	cmp    $0xf0274000,%eax
f0102a92:	0f 85 7b ff ff ff    	jne    f0102a13 <mem_init+0x16e6>
f0102a98:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0102a9b:	e9 84 00 00 00       	jmp    f0102b24 <mem_init+0x17f7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102aa0:	ff 75 bc             	pushl  -0x44(%ebp)
f0102aa3:	68 48 62 10 f0       	push   $0xf0106248
f0102aa8:	68 db 03 00 00       	push   $0x3db
f0102aad:	68 5d 71 10 f0       	push   $0xf010715d
f0102ab2:	e8 89 d5 ff ff       	call   f0100040 <_panic>
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102ab7:	68 fc 6f 10 f0       	push   $0xf0106ffc
f0102abc:	68 83 71 10 f0       	push   $0xf0107183
f0102ac1:	68 da 03 00 00       	push   $0x3da
f0102ac6:	68 5d 71 10 f0       	push   $0xf010715d
f0102acb:	e8 70 d5 ff ff       	call   f0100040 <_panic>
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102ad0:	68 44 70 10 f0       	push   $0xf0107044
f0102ad5:	68 83 71 10 f0       	push   $0xf0107183
f0102ada:	68 dd 03 00 00       	push   $0x3dd
f0102adf:	68 5d 71 10 f0       	push   $0xf010715d
f0102ae4:	e8 57 d5 ff ff       	call   f0100040 <_panic>
			assert(pgdir[i] & PTE_P);
f0102ae9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102aec:	f6 04 b8 01          	testb  $0x1,(%eax,%edi,4)
f0102af0:	75 4e                	jne    f0102b40 <mem_init+0x1813>
f0102af2:	68 3f 74 10 f0       	push   $0xf010743f
f0102af7:	68 83 71 10 f0       	push   $0xf0107183
f0102afc:	68 e8 03 00 00       	push   $0x3e8
f0102b01:	68 5d 71 10 f0       	push   $0xf010715d
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
f0102b45:	68 3f 74 10 f0       	push   $0xf010743f
f0102b4a:	68 83 71 10 f0       	push   $0xf0107183
f0102b4f:	68 ec 03 00 00       	push   $0x3ec
f0102b54:	68 5d 71 10 f0       	push   $0xf010715d
f0102b59:	e8 e2 d4 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102b5e:	68 50 74 10 f0       	push   $0xf0107450
f0102b63:	68 83 71 10 f0       	push   $0xf0107183
f0102b68:	68 ed 03 00 00       	push   $0x3ed
f0102b6d:	68 5d 71 10 f0       	push   $0xf010715d
f0102b72:	e8 c9 d4 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] == 0);
f0102b77:	68 61 74 10 f0       	push   $0xf0107461
f0102b7c:	68 83 71 10 f0       	push   $0xf0107183
f0102b81:	68 ef 03 00 00       	push   $0x3ef
f0102b86:	68 5d 71 10 f0       	push   $0xf010715d
f0102b8b:	e8 b0 d4 ff ff       	call   f0100040 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102b90:	83 ec 0c             	sub    $0xc,%esp
f0102b93:	68 68 70 10 f0       	push   $0xf0107068
f0102b98:	e8 30 0e 00 00       	call   f01039cd <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102b9d:	a1 8c 2e 23 f0       	mov    0xf0232e8c,%eax
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
f0102c20:	2b 05 90 2e 23 f0    	sub    0xf0232e90,%eax
f0102c26:	c1 f8 03             	sar    $0x3,%eax
f0102c29:	89 c2                	mov    %eax,%edx
f0102c2b:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102c2e:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102c33:	83 c4 10             	add    $0x10,%esp
f0102c36:	3b 05 88 2e 23 f0    	cmp    0xf0232e88,%eax
f0102c3c:	0f 83 d1 01 00 00    	jae    f0102e13 <mem_init+0x1ae6>
	memset(page2kva(pp1), 1, PGSIZE);
f0102c42:	83 ec 04             	sub    $0x4,%esp
f0102c45:	68 00 10 00 00       	push   $0x1000
f0102c4a:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102c4c:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102c52:	52                   	push   %edx
f0102c53:	e8 0f 29 00 00       	call   f0105567 <memset>
	return (pp - pages) << PGSHIFT;
f0102c58:	89 d8                	mov    %ebx,%eax
f0102c5a:	2b 05 90 2e 23 f0    	sub    0xf0232e90,%eax
f0102c60:	c1 f8 03             	sar    $0x3,%eax
f0102c63:	89 c2                	mov    %eax,%edx
f0102c65:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102c68:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102c6d:	83 c4 10             	add    $0x10,%esp
f0102c70:	3b 05 88 2e 23 f0    	cmp    0xf0232e88,%eax
f0102c76:	0f 83 a9 01 00 00    	jae    f0102e25 <mem_init+0x1af8>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c7c:	83 ec 04             	sub    $0x4,%esp
f0102c7f:	68 00 10 00 00       	push   $0x1000
f0102c84:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102c86:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102c8c:	52                   	push   %edx
f0102c8d:	e8 d5 28 00 00       	call   f0105567 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c92:	6a 02                	push   $0x2
f0102c94:	68 00 10 00 00       	push   $0x1000
f0102c99:	57                   	push   %edi
f0102c9a:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
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
f0102ccb:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
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
f0102d0b:	2b 05 90 2e 23 f0    	sub    0xf0232e90,%eax
f0102d11:	c1 f8 03             	sar    $0x3,%eax
f0102d14:	89 c2                	mov    %eax,%edx
f0102d16:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102d19:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102d1e:	3b 05 88 2e 23 f0    	cmp    0xf0232e88,%eax
f0102d24:	0f 83 8a 01 00 00    	jae    f0102eb4 <mem_init+0x1b87>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d2a:	81 ba 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%edx)
f0102d31:	03 03 03 
f0102d34:	0f 85 8c 01 00 00    	jne    f0102ec6 <mem_init+0x1b99>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d3a:	83 ec 08             	sub    $0x8,%esp
f0102d3d:	68 00 10 00 00       	push   $0x1000
f0102d42:	ff 35 8c 2e 23 f0    	pushl  0xf0232e8c
f0102d48:	e8 91 e4 ff ff       	call   f01011de <page_remove>
	assert(pp2->pp_ref == 0);
f0102d4d:	83 c4 10             	add    $0x10,%esp
f0102d50:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102d55:	0f 85 84 01 00 00    	jne    f0102edf <mem_init+0x1bb2>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102d5b:	8b 0d 8c 2e 23 f0    	mov    0xf0232e8c,%ecx
f0102d61:	8b 11                	mov    (%ecx),%edx
f0102d63:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102d69:	89 f0                	mov    %esi,%eax
f0102d6b:	2b 05 90 2e 23 f0    	sub    0xf0232e90,%eax
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
f0102d9f:	c7 04 24 fc 70 10 f0 	movl   $0xf01070fc,(%esp)
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
f0102db4:	68 48 62 10 f0       	push   $0xf0106248
f0102db9:	68 f7 00 00 00       	push   $0xf7
f0102dbe:	68 5d 71 10 f0       	push   $0xf010715d
f0102dc3:	e8 78 d2 ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f0102dc8:	68 4b 72 10 f0       	push   $0xf010724b
f0102dcd:	68 83 71 10 f0       	push   $0xf0107183
f0102dd2:	68 c7 04 00 00       	push   $0x4c7
f0102dd7:	68 5d 71 10 f0       	push   $0xf010715d
f0102ddc:	e8 5f d2 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102de1:	68 61 72 10 f0       	push   $0xf0107261
f0102de6:	68 83 71 10 f0       	push   $0xf0107183
f0102deb:	68 c8 04 00 00       	push   $0x4c8
f0102df0:	68 5d 71 10 f0       	push   $0xf010715d
f0102df5:	e8 46 d2 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102dfa:	68 77 72 10 f0       	push   $0xf0107277
f0102dff:	68 83 71 10 f0       	push   $0xf0107183
f0102e04:	68 c9 04 00 00       	push   $0x4c9
f0102e09:	68 5d 71 10 f0       	push   $0xf010715d
f0102e0e:	e8 2d d2 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e13:	52                   	push   %edx
f0102e14:	68 24 62 10 f0       	push   $0xf0106224
f0102e19:	6a 58                	push   $0x58
f0102e1b:	68 69 71 10 f0       	push   $0xf0107169
f0102e20:	e8 1b d2 ff ff       	call   f0100040 <_panic>
f0102e25:	52                   	push   %edx
f0102e26:	68 24 62 10 f0       	push   $0xf0106224
f0102e2b:	6a 58                	push   $0x58
f0102e2d:	68 69 71 10 f0       	push   $0xf0107169
f0102e32:	e8 09 d2 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102e37:	68 48 73 10 f0       	push   $0xf0107348
f0102e3c:	68 83 71 10 f0       	push   $0xf0107183
f0102e41:	68 ce 04 00 00       	push   $0x4ce
f0102e46:	68 5d 71 10 f0       	push   $0xf010715d
f0102e4b:	e8 f0 d1 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102e50:	68 88 70 10 f0       	push   $0xf0107088
f0102e55:	68 83 71 10 f0       	push   $0xf0107183
f0102e5a:	68 cf 04 00 00       	push   $0x4cf
f0102e5f:	68 5d 71 10 f0       	push   $0xf010715d
f0102e64:	e8 d7 d1 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102e69:	68 ac 70 10 f0       	push   $0xf01070ac
f0102e6e:	68 83 71 10 f0       	push   $0xf0107183
f0102e73:	68 d1 04 00 00       	push   $0x4d1
f0102e78:	68 5d 71 10 f0       	push   $0xf010715d
f0102e7d:	e8 be d1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102e82:	68 6a 73 10 f0       	push   $0xf010736a
f0102e87:	68 83 71 10 f0       	push   $0xf0107183
f0102e8c:	68 d2 04 00 00       	push   $0x4d2
f0102e91:	68 5d 71 10 f0       	push   $0xf010715d
f0102e96:	e8 a5 d1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102e9b:	68 d4 73 10 f0       	push   $0xf01073d4
f0102ea0:	68 83 71 10 f0       	push   $0xf0107183
f0102ea5:	68 d3 04 00 00       	push   $0x4d3
f0102eaa:	68 5d 71 10 f0       	push   $0xf010715d
f0102eaf:	e8 8c d1 ff ff       	call   f0100040 <_panic>
f0102eb4:	52                   	push   %edx
f0102eb5:	68 24 62 10 f0       	push   $0xf0106224
f0102eba:	6a 58                	push   $0x58
f0102ebc:	68 69 71 10 f0       	push   $0xf0107169
f0102ec1:	e8 7a d1 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102ec6:	68 d0 70 10 f0       	push   $0xf01070d0
f0102ecb:	68 83 71 10 f0       	push   $0xf0107183
f0102ed0:	68 d5 04 00 00       	push   $0x4d5
f0102ed5:	68 5d 71 10 f0       	push   $0xf010715d
f0102eda:	e8 61 d1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102edf:	68 a2 73 10 f0       	push   $0xf01073a2
f0102ee4:	68 83 71 10 f0       	push   $0xf0107183
f0102ee9:	68 d7 04 00 00       	push   $0x4d7
f0102eee:	68 5d 71 10 f0       	push   $0xf010715d
f0102ef3:	e8 48 d1 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102ef8:	68 58 6a 10 f0       	push   $0xf0106a58
f0102efd:	68 83 71 10 f0       	push   $0xf0107183
f0102f02:	68 da 04 00 00       	push   $0x4da
f0102f07:	68 5d 71 10 f0       	push   $0xf010715d
f0102f0c:	e8 2f d1 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0102f11:	68 59 73 10 f0       	push   $0xf0107359
f0102f16:	68 83 71 10 f0       	push   $0xf0107183
f0102f1b:	68 dc 04 00 00       	push   $0x4dc
f0102f20:	68 5d 71 10 f0       	push   $0xf010715d
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
f0102fa0:	a3 3c 22 23 f0       	mov    %eax,0xf023223c
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
f0102fe9:	ff 35 3c 22 23 f0    	pushl  0xf023223c
f0102fef:	ff 73 48             	pushl  0x48(%ebx)
f0102ff2:	68 28 71 10 f0       	push   $0xf0107128
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
f0103060:	68 70 74 10 f0       	push   $0xf0107470
f0103065:	68 37 01 00 00       	push   $0x137
f010306a:	68 65 75 10 f0       	push   $0xf0107565
f010306f:	e8 cc cf ff ff       	call   f0100040 <_panic>
			panic("At region_alloc: Page allocation failed");
f0103074:	83 ec 04             	sub    $0x4,%esp
f0103077:	68 94 74 10 f0       	push   $0xf0107494
f010307c:	68 42 01 00 00       	push   $0x142
f0103081:	68 65 75 10 f0       	push   $0xf0107565
f0103086:	e8 b5 cf ff ff       	call   f0100040 <_panic>
		{
			panic("At region_alloc: Page insertion failed");
f010308b:	83 ec 04             	sub    $0x4,%esp
f010308e:	68 bc 74 10 f0       	push   $0xf01074bc
f0103093:	68 4b 01 00 00       	push   $0x14b
f0103098:	68 65 75 10 f0       	push   $0xf0107565
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
f01030c8:	03 1d 48 22 23 f0    	add    0xf0232248,%ebx
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
f01030eb:	e8 96 2a 00 00       	call   f0105b86 <cpunum>
f01030f0:	6b c0 74             	imul   $0x74,%eax,%eax
f01030f3:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
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
f0103112:	e8 6f 2a 00 00       	call   f0105b86 <cpunum>
f0103117:	6b c0 74             	imul   $0x74,%eax,%eax
f010311a:	39 98 28 30 23 f0    	cmp    %ebx,-0xfdccfd8(%eax)
f0103120:	74 bb                	je     f01030dd <envid2env+0x33>
f0103122:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0103125:	e8 5c 2a 00 00       	call   f0105b86 <cpunum>
f010312a:	6b c0 74             	imul   $0x74,%eax,%eax
f010312d:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
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
f010314c:	b8 20 23 12 f0       	mov    $0xf0122320,%eax
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
f0103181:	8b 35 48 22 23 f0    	mov    0xf0232248,%esi
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
f01031b0:	89 35 4c 22 23 f0    	mov    %esi,0xf023224c
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
f01031ca:	8b 1d 4c 22 23 f0    	mov    0xf023224c,%ebx
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
f01031ef:	2b 15 90 2e 23 f0    	sub    0xf0232e90,%edx
f01031f5:	c1 fa 03             	sar    $0x3,%edx
f01031f8:	89 d1                	mov    %edx,%ecx
f01031fa:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f01031fd:	81 e2 ff ff 0f 00    	and    $0xfffff,%edx
f0103203:	3b 15 88 2e 23 f0    	cmp    0xf0232e88,%edx
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
f0103236:	8b 15 8c 2e 23 f0    	mov    0xf0232e8c,%edx
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
f0103283:	2b 15 48 22 23 f0    	sub    0xf0232248,%edx
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
f01032ba:	e8 a8 22 00 00       	call   f0105567 <memset>
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
f01032ec:	a3 4c 22 23 f0       	mov    %eax,0xf023224c
	*newenv_store = e;
f01032f1:	8b 45 08             	mov    0x8(%ebp),%eax
f01032f4:	89 18                	mov    %ebx,(%eax)
	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01032f6:	8b 5b 48             	mov    0x48(%ebx),%ebx
f01032f9:	e8 88 28 00 00       	call   f0105b86 <cpunum>
f01032fe:	6b c0 74             	imul   $0x74,%eax,%eax
f0103301:	83 c4 10             	add    $0x10,%esp
f0103304:	ba 00 00 00 00       	mov    $0x0,%edx
f0103309:	83 b8 28 30 23 f0 00 	cmpl   $0x0,-0xfdccfd8(%eax)
f0103310:	74 11                	je     f0103323 <env_alloc+0x164>
f0103312:	e8 6f 28 00 00       	call   f0105b86 <cpunum>
f0103317:	6b c0 74             	imul   $0x74,%eax,%eax
f010331a:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
f0103320:	8b 50 48             	mov    0x48(%eax),%edx
f0103323:	83 ec 04             	sub    $0x4,%esp
f0103326:	53                   	push   %ebx
f0103327:	52                   	push   %edx
f0103328:	68 70 75 10 f0       	push   $0xf0107570
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
f0103340:	68 24 62 10 f0       	push   $0xf0106224
f0103345:	6a 58                	push   $0x58
f0103347:	68 69 71 10 f0       	push   $0xf0107169
f010334c:	e8 ef cc ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103351:	50                   	push   %eax
f0103352:	68 48 62 10 f0       	push   $0xf0106248
f0103357:	68 d3 00 00 00       	push   $0xd3
f010335c:	68 65 75 10 f0       	push   $0xf0107565
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
f01033c9:	68 e4 74 10 f0       	push   $0xf01074e4
f01033ce:	68 c4 01 00 00       	push   $0x1c4
f01033d3:	68 65 75 10 f0       	push   $0xf0107565
f01033d8:	e8 63 cc ff ff       	call   f0100040 <_panic>
		panic("At load_icode: Invalid head magic number");
f01033dd:	83 ec 04             	sub    $0x4,%esp
f01033e0:	68 08 75 10 f0       	push   $0xf0107508
f01033e5:	68 8c 01 00 00       	push   $0x18c
f01033ea:	68 65 75 10 f0       	push   $0xf0107565
f01033ef:	e8 4c cc ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033f4:	50                   	push   %eax
f01033f5:	68 48 62 10 f0       	push   $0xf0106248
f01033fa:	68 8f 01 00 00       	push   $0x18f
f01033ff:	68 65 75 10 f0       	push   $0xf0107565
f0103404:	e8 37 cc ff ff       	call   f0100040 <_panic>
				panic("At load_icode: file size bigger than memory size");
f0103409:	83 ec 04             	sub    $0x4,%esp
f010340c:	68 34 75 10 f0       	push   $0xf0107534
f0103411:	68 9b 01 00 00       	push   $0x19b
f0103416:	68 65 75 10 f0       	push   $0xf0107565
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
f010344e:	e8 c6 21 00 00       	call   f0105619 <memcpy>
			memset((void*)(ph->p_va+ph->p_filesz),0,ph->p_memsz-ph->p_filesz);
f0103453:	8b 43 10             	mov    0x10(%ebx),%eax
f0103456:	83 c4 0c             	add    $0xc,%esp
f0103459:	8b 53 14             	mov    0x14(%ebx),%edx
f010345c:	29 c2                	sub    %eax,%edx
f010345e:	52                   	push   %edx
f010345f:	6a 00                	push   $0x0
f0103461:	03 43 08             	add    0x8(%ebx),%eax
f0103464:	50                   	push   %eax
f0103465:	e8 fd 20 00 00       	call   f0105567 <memset>
f010346a:	83 c4 10             	add    $0x10,%esp
f010346d:	eb b1                	jmp    f0103420 <env_create+0xac>
	lcr3(PADDR(kern_pgdir));
f010346f:	a1 8c 2e 23 f0       	mov    0xf0232e8c,%eax
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
f01034b3:	68 48 62 10 f0       	push   $0xf0106248
f01034b8:	68 a8 01 00 00       	push   $0x1a8
f01034bd:	68 65 75 10 f0       	push   $0xf0107565
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
f01034d7:	e8 aa 26 00 00       	call   f0105b86 <cpunum>
f01034dc:	6b c0 74             	imul   $0x74,%eax,%eax
f01034df:	39 b8 28 30 23 f0    	cmp    %edi,-0xfdccfd8(%eax)
f01034e5:	74 48                	je     f010352f <env_free+0x68>
		lcr3(PADDR(kern_pgdir));

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01034e7:	8b 5f 48             	mov    0x48(%edi),%ebx
f01034ea:	e8 97 26 00 00       	call   f0105b86 <cpunum>
f01034ef:	6b c0 74             	imul   $0x74,%eax,%eax
f01034f2:	ba 00 00 00 00       	mov    $0x0,%edx
f01034f7:	83 b8 28 30 23 f0 00 	cmpl   $0x0,-0xfdccfd8(%eax)
f01034fe:	74 11                	je     f0103511 <env_free+0x4a>
f0103500:	e8 81 26 00 00       	call   f0105b86 <cpunum>
f0103505:	6b c0 74             	imul   $0x74,%eax,%eax
f0103508:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
f010350e:	8b 50 48             	mov    0x48(%eax),%edx
f0103511:	83 ec 04             	sub    $0x4,%esp
f0103514:	53                   	push   %ebx
f0103515:	52                   	push   %edx
f0103516:	68 85 75 10 f0       	push   $0xf0107585
f010351b:	e8 ad 04 00 00       	call   f01039cd <cprintf>
f0103520:	83 c4 10             	add    $0x10,%esp
f0103523:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010352a:	e9 a9 00 00 00       	jmp    f01035d8 <env_free+0x111>
		lcr3(PADDR(kern_pgdir));
f010352f:	a1 8c 2e 23 f0       	mov    0xf0232e8c,%eax
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
f0103546:	68 48 62 10 f0       	push   $0xf0106248
f010354b:	68 d8 01 00 00       	push   $0x1d8
f0103550:	68 65 75 10 f0       	push   $0xf0107565
f0103555:	e8 e6 ca ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010355a:	56                   	push   %esi
f010355b:	68 24 62 10 f0       	push   $0xf0106224
f0103560:	68 e7 01 00 00       	push   $0x1e7
f0103565:	68 65 75 10 f0       	push   $0xf0107565
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
f01035ab:	3b 05 88 2e 23 f0    	cmp    0xf0232e88,%eax
f01035b1:	73 65                	jae    f0103618 <env_free+0x151>
		page_decref(pa2page(pa));
f01035b3:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01035b6:	a1 90 2e 23 f0       	mov    0xf0232e90,%eax
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
f01035f3:	39 05 88 2e 23 f0    	cmp    %eax,0xf0232e88
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
f010361b:	68 fc 68 10 f0       	push   $0xf01068fc
f0103620:	6a 51                	push   $0x51
f0103622:	68 69 71 10 f0       	push   $0xf0107169
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
f0103645:	3b 05 88 2e 23 f0    	cmp    0xf0232e88,%eax
f010364b:	73 47                	jae    f0103694 <env_free+0x1cd>
	page_decref(pa2page(pa));
f010364d:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103650:	8b 15 90 2e 23 f0    	mov    0xf0232e90,%edx
f0103656:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103659:	50                   	push   %eax
f010365a:	e8 d3 d9 ff ff       	call   f0101032 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f010365f:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103666:	a1 4c 22 23 f0       	mov    0xf023224c,%eax
f010366b:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f010366e:	89 3d 4c 22 23 f0    	mov    %edi,0xf023224c
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
f0103680:	68 48 62 10 f0       	push   $0xf0106248
f0103685:	68 f5 01 00 00       	push   $0x1f5
f010368a:	68 65 75 10 f0       	push   $0xf0107565
f010368f:	e8 ac c9 ff ff       	call   f0100040 <_panic>
		panic("pa2page called with invalid pa");
f0103694:	83 ec 04             	sub    $0x4,%esp
f0103697:	68 fc 68 10 f0       	push   $0xf01068fc
f010369c:	6a 51                	push   $0x51
f010369e:	68 69 71 10 f0       	push   $0xf0107169
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
f01036c5:	e8 bc 24 00 00       	call   f0105b86 <cpunum>
f01036ca:	6b c0 74             	imul   $0x74,%eax,%eax
f01036cd:	83 c4 10             	add    $0x10,%esp
f01036d0:	39 98 28 30 23 f0    	cmp    %ebx,-0xfdccfd8(%eax)
f01036d6:	74 1e                	je     f01036f6 <env_destroy+0x4e>
		curenv = NULL;
		sched_yield();
	}
}
f01036d8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01036db:	c9                   	leave  
f01036dc:	c3                   	ret    
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01036dd:	e8 a4 24 00 00       	call   f0105b86 <cpunum>
f01036e2:	6b c0 74             	imul   $0x74,%eax,%eax
f01036e5:	39 98 28 30 23 f0    	cmp    %ebx,-0xfdccfd8(%eax)
f01036eb:	74 cf                	je     f01036bc <env_destroy+0x14>
		e->env_status = ENV_DYING;
f01036ed:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01036f4:	eb e2                	jmp    f01036d8 <env_destroy+0x30>
		curenv = NULL;
f01036f6:	e8 8b 24 00 00       	call   f0105b86 <cpunum>
f01036fb:	6b c0 74             	imul   $0x74,%eax,%eax
f01036fe:	c7 80 28 30 23 f0 00 	movl   $0x0,-0xfdccfd8(%eax)
f0103705:	00 00 00 
		sched_yield();
f0103708:	e8 58 0d 00 00       	call   f0104465 <sched_yield>

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
f0103718:	e8 69 24 00 00       	call   f0105b86 <cpunum>
f010371d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103720:	8b 98 28 30 23 f0    	mov    -0xfdccfd8(%eax),%ebx
f0103726:	e8 5b 24 00 00       	call   f0105b86 <cpunum>
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
f010373b:	68 9b 75 10 f0       	push   $0xf010759b
f0103740:	68 27 02 00 00       	push   $0x227
f0103745:	68 65 75 10 f0       	push   $0xf0107565
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
f0103759:	e8 28 24 00 00       	call   f0105b86 <cpunum>
f010375e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103761:	83 b8 28 30 23 f0 00 	cmpl   $0x0,-0xfdccfd8(%eax)
f0103768:	74 14                	je     f010377e <env_run+0x2f>
	{
		if(curenv->env_status == ENV_RUNNING)
f010376a:	e8 17 24 00 00       	call   f0105b86 <cpunum>
f010376f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103772:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
f0103778:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010377c:	74 7d                	je     f01037fb <env_run+0xac>
			curenv->env_status = ENV_RUNNABLE;
		}
	}

	// switch to new environment
	curenv = e;
f010377e:	e8 03 24 00 00       	call   f0105b86 <cpunum>
f0103783:	6b c0 74             	imul   $0x74,%eax,%eax
f0103786:	8b 55 08             	mov    0x8(%ebp),%edx
f0103789:	89 90 28 30 23 f0    	mov    %edx,-0xfdccfd8(%eax)
	curenv->env_status = ENV_RUNNING;
f010378f:	e8 f2 23 00 00       	call   f0105b86 <cpunum>
f0103794:	6b c0 74             	imul   $0x74,%eax,%eax
f0103797:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
f010379d:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f01037a4:	e8 dd 23 00 00       	call   f0105b86 <cpunum>
f01037a9:	6b c0 74             	imul   $0x74,%eax,%eax
f01037ac:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
f01037b2:	83 40 58 01          	addl   $0x1,0x58(%eax)
	// switch to user page directory
	lcr3(PADDR(curenv->env_pgdir));
f01037b6:	e8 cb 23 00 00       	call   f0105b86 <cpunum>
f01037bb:	6b c0 74             	imul   $0x74,%eax,%eax
f01037be:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
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
f01037d9:	68 c0 23 12 f0       	push   $0xf01223c0
f01037de:	e8 c9 26 00 00       	call   f0105eac <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01037e3:	f3 90                	pause  
	unlock_kernel();
	// step 2
	env_pop_tf(&curenv->env_tf);
f01037e5:	e8 9c 23 00 00       	call   f0105b86 <cpunum>
f01037ea:	83 c4 04             	add    $0x4,%esp
f01037ed:	6b c0 74             	imul   $0x74,%eax,%eax
f01037f0:	ff b0 28 30 23 f0    	pushl  -0xfdccfd8(%eax)
f01037f6:	e8 12 ff ff ff       	call   f010370d <env_pop_tf>
			curenv->env_status = ENV_RUNNABLE;
f01037fb:	e8 86 23 00 00       	call   f0105b86 <cpunum>
f0103800:	6b c0 74             	imul   $0x74,%eax,%eax
f0103803:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
f0103809:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
f0103810:	e9 69 ff ff ff       	jmp    f010377e <env_run+0x2f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103815:	50                   	push   %eax
f0103816:	68 48 62 10 f0       	push   $0xf0106248
f010381b:	68 57 02 00 00       	push   $0x257
f0103820:	68 65 75 10 f0       	push   $0xf0107565
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
f010386c:	66 a3 a8 23 12 f0    	mov    %ax,0xf01223a8
	if (!didinit)
f0103872:	80 3d 50 22 23 f0 00 	cmpb   $0x0,0xf0232250
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
f0103897:	68 a7 75 10 f0       	push   $0xf01075a7
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
f01038b4:	68 7f 7a 10 f0       	push   $0xf0107a7f
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
f01038d3:	68 3d 74 10 f0       	push   $0xf010743d
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
f01038ef:	c6 05 50 22 23 f0 01 	movb   $0x1,0xf0232250
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
f0103966:	0f b7 05 a8 23 12 f0 	movzwl 0xf01223a8,%eax
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
f01039c3:	e8 48 14 00 00       	call   f0104e10 <vprintfmt>
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
f01039f2:	e8 8f 21 00 00       	call   f0105b86 <cpunum>
f01039f7:	6b c0 74             	imul   $0x74,%eax,%eax
f01039fa:	0f b6 b8 20 30 23 f0 	movzbl -0xfdccfe0(%eax),%edi
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP-id*(KSTKSIZE+KSTKGAP);
f0103a01:	89 f8                	mov    %edi,%eax
f0103a03:	0f b6 d8             	movzbl %al,%ebx
f0103a06:	e8 7b 21 00 00       	call   f0105b86 <cpunum>
f0103a0b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a0e:	89 d9                	mov    %ebx,%ecx
f0103a10:	c1 e1 10             	shl    $0x10,%ecx
f0103a13:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0103a18:	29 ca                	sub    %ecx,%edx
f0103a1a:	89 90 30 30 23 f0    	mov    %edx,-0xfdccfd0(%eax)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f0103a20:	e8 61 21 00 00       	call   f0105b86 <cpunum>
f0103a25:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a28:	66 c7 80 34 30 23 f0 	movw   $0x10,-0xfdccfcc(%eax)
f0103a2f:	10 00 
	thiscpu->cpu_ts.ts_iomb = sizeof(struct Taskstate);
f0103a31:	e8 50 21 00 00       	call   f0105b86 <cpunum>
f0103a36:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a39:	66 c7 80 92 30 23 f0 	movw   $0x68,-0xfdccf6e(%eax)
f0103a40:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+id] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
f0103a42:	83 c3 05             	add    $0x5,%ebx
f0103a45:	e8 3c 21 00 00       	call   f0105b86 <cpunum>
f0103a4a:	89 c6                	mov    %eax,%esi
f0103a4c:	e8 35 21 00 00       	call   f0105b86 <cpunum>
f0103a51:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103a54:	e8 2d 21 00 00       	call   f0105b86 <cpunum>
f0103a59:	66 c7 04 dd 40 23 12 	movw   $0x67,-0xfeddcc0(,%ebx,8)
f0103a60:	f0 67 00 
f0103a63:	6b f6 74             	imul   $0x74,%esi,%esi
f0103a66:	81 c6 2c 30 23 f0    	add    $0xf023302c,%esi
f0103a6c:	66 89 34 dd 42 23 12 	mov    %si,-0xfeddcbe(,%ebx,8)
f0103a73:	f0 
f0103a74:	6b 55 e4 74          	imul   $0x74,-0x1c(%ebp),%edx
f0103a78:	81 c2 2c 30 23 f0    	add    $0xf023302c,%edx
f0103a7e:	c1 ea 10             	shr    $0x10,%edx
f0103a81:	88 14 dd 44 23 12 f0 	mov    %dl,-0xfeddcbc(,%ebx,8)
f0103a88:	c6 04 dd 46 23 12 f0 	movb   $0x40,-0xfeddcba(,%ebx,8)
f0103a8f:	40 
f0103a90:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a93:	05 2c 30 23 f0       	add    $0xf023302c,%eax
f0103a98:	c1 e8 18             	shr    $0x18,%eax
f0103a9b:	88 04 dd 47 23 12 f0 	mov    %al,-0xfeddcb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3)+id].sd_s = 0;
f0103aa2:	c6 04 dd 45 23 12 f0 	movb   $0x89,-0xfeddcbb(,%ebx,8)
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
f0103ab9:	b8 ac 23 12 f0       	mov    $0xf01223ac,%eax
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
f0103ad3:	b8 1a 43 10 f0       	mov    $0xf010431a,%eax
f0103ad8:	66 a3 60 22 23 f0    	mov    %ax,0xf0232260
f0103ade:	66 c7 05 62 22 23 f0 	movw   $0x8,0xf0232262
f0103ae5:	08 00 
f0103ae7:	c6 05 64 22 23 f0 00 	movb   $0x0,0xf0232264
f0103aee:	c6 05 65 22 23 f0 8e 	movb   $0x8e,0xf0232265
f0103af5:	c1 e8 10             	shr    $0x10,%eax
f0103af8:	66 a3 66 22 23 f0    	mov    %ax,0xf0232266
	SETGATE(idt[T_DEBUG], 0, GD_KT, DEBUG, 0);
f0103afe:	b8 20 43 10 f0       	mov    $0xf0104320,%eax
f0103b03:	66 a3 68 22 23 f0    	mov    %ax,0xf0232268
f0103b09:	66 c7 05 6a 22 23 f0 	movw   $0x8,0xf023226a
f0103b10:	08 00 
f0103b12:	c6 05 6c 22 23 f0 00 	movb   $0x0,0xf023226c
f0103b19:	c6 05 6d 22 23 f0 8e 	movb   $0x8e,0xf023226d
f0103b20:	c1 e8 10             	shr    $0x10,%eax
f0103b23:	66 a3 6e 22 23 f0    	mov    %ax,0xf023226e
	SETGATE(idt[T_NMI], 0, GD_KT, NMI, 0);
f0103b29:	b8 26 43 10 f0       	mov    $0xf0104326,%eax
f0103b2e:	66 a3 70 22 23 f0    	mov    %ax,0xf0232270
f0103b34:	66 c7 05 72 22 23 f0 	movw   $0x8,0xf0232272
f0103b3b:	08 00 
f0103b3d:	c6 05 74 22 23 f0 00 	movb   $0x0,0xf0232274
f0103b44:	c6 05 75 22 23 f0 8e 	movb   $0x8e,0xf0232275
f0103b4b:	c1 e8 10             	shr    $0x10,%eax
f0103b4e:	66 a3 76 22 23 f0    	mov    %ax,0xf0232276
	SETGATE(idt[T_BRKPT], 1, GD_KT, BRKPT, 3);
f0103b54:	b8 2c 43 10 f0       	mov    $0xf010432c,%eax
f0103b59:	66 a3 78 22 23 f0    	mov    %ax,0xf0232278
f0103b5f:	66 c7 05 7a 22 23 f0 	movw   $0x8,0xf023227a
f0103b66:	08 00 
f0103b68:	c6 05 7c 22 23 f0 00 	movb   $0x0,0xf023227c
f0103b6f:	c6 05 7d 22 23 f0 ef 	movb   $0xef,0xf023227d
f0103b76:	c1 e8 10             	shr    $0x10,%eax
f0103b79:	66 a3 7e 22 23 f0    	mov    %ax,0xf023227e
	SETGATE(idt[T_OFLOW], 0, GD_KT, OFLOW, 0);
f0103b7f:	b8 32 43 10 f0       	mov    $0xf0104332,%eax
f0103b84:	66 a3 80 22 23 f0    	mov    %ax,0xf0232280
f0103b8a:	66 c7 05 82 22 23 f0 	movw   $0x8,0xf0232282
f0103b91:	08 00 
f0103b93:	c6 05 84 22 23 f0 00 	movb   $0x0,0xf0232284
f0103b9a:	c6 05 85 22 23 f0 8e 	movb   $0x8e,0xf0232285
f0103ba1:	c1 e8 10             	shr    $0x10,%eax
f0103ba4:	66 a3 86 22 23 f0    	mov    %ax,0xf0232286
	SETGATE(idt[T_BOUND], 0, GD_KT, BOUND, 0);
f0103baa:	b8 38 43 10 f0       	mov    $0xf0104338,%eax
f0103baf:	66 a3 88 22 23 f0    	mov    %ax,0xf0232288
f0103bb5:	66 c7 05 8a 22 23 f0 	movw   $0x8,0xf023228a
f0103bbc:	08 00 
f0103bbe:	c6 05 8c 22 23 f0 00 	movb   $0x0,0xf023228c
f0103bc5:	c6 05 8d 22 23 f0 8e 	movb   $0x8e,0xf023228d
f0103bcc:	c1 e8 10             	shr    $0x10,%eax
f0103bcf:	66 a3 8e 22 23 f0    	mov    %ax,0xf023228e
	SETGATE(idt[T_ILLOP], 0, GD_KT, ILLOP, 0);
f0103bd5:	b8 3e 43 10 f0       	mov    $0xf010433e,%eax
f0103bda:	66 a3 90 22 23 f0    	mov    %ax,0xf0232290
f0103be0:	66 c7 05 92 22 23 f0 	movw   $0x8,0xf0232292
f0103be7:	08 00 
f0103be9:	c6 05 94 22 23 f0 00 	movb   $0x0,0xf0232294
f0103bf0:	c6 05 95 22 23 f0 8e 	movb   $0x8e,0xf0232295
f0103bf7:	c1 e8 10             	shr    $0x10,%eax
f0103bfa:	66 a3 96 22 23 f0    	mov    %ax,0xf0232296
	SETGATE(idt[T_DEVICE], 0, GD_KT, DEVICE, 0);
f0103c00:	b8 44 43 10 f0       	mov    $0xf0104344,%eax
f0103c05:	66 a3 98 22 23 f0    	mov    %ax,0xf0232298
f0103c0b:	66 c7 05 9a 22 23 f0 	movw   $0x8,0xf023229a
f0103c12:	08 00 
f0103c14:	c6 05 9c 22 23 f0 00 	movb   $0x0,0xf023229c
f0103c1b:	c6 05 9d 22 23 f0 8e 	movb   $0x8e,0xf023229d
f0103c22:	c1 e8 10             	shr    $0x10,%eax
f0103c25:	66 a3 9e 22 23 f0    	mov    %ax,0xf023229e
	SETGATE(idt[T_DBLFLT], 0, GD_KT, DBLFLT, 0);
f0103c2b:	b8 4a 43 10 f0       	mov    $0xf010434a,%eax
f0103c30:	66 a3 a0 22 23 f0    	mov    %ax,0xf02322a0
f0103c36:	66 c7 05 a2 22 23 f0 	movw   $0x8,0xf02322a2
f0103c3d:	08 00 
f0103c3f:	c6 05 a4 22 23 f0 00 	movb   $0x0,0xf02322a4
f0103c46:	c6 05 a5 22 23 f0 8e 	movb   $0x8e,0xf02322a5
f0103c4d:	c1 e8 10             	shr    $0x10,%eax
f0103c50:	66 a3 a6 22 23 f0    	mov    %ax,0xf02322a6
	SETGATE(idt[T_TSS], 0, GD_KT, TSS, 0);
f0103c56:	b8 4e 43 10 f0       	mov    $0xf010434e,%eax
f0103c5b:	66 a3 b0 22 23 f0    	mov    %ax,0xf02322b0
f0103c61:	66 c7 05 b2 22 23 f0 	movw   $0x8,0xf02322b2
f0103c68:	08 00 
f0103c6a:	c6 05 b4 22 23 f0 00 	movb   $0x0,0xf02322b4
f0103c71:	c6 05 b5 22 23 f0 8e 	movb   $0x8e,0xf02322b5
f0103c78:	c1 e8 10             	shr    $0x10,%eax
f0103c7b:	66 a3 b6 22 23 f0    	mov    %ax,0xf02322b6
	SETGATE(idt[T_SEGNP], 0, GD_KT, SEGNP, 0);
f0103c81:	b8 52 43 10 f0       	mov    $0xf0104352,%eax
f0103c86:	66 a3 b8 22 23 f0    	mov    %ax,0xf02322b8
f0103c8c:	66 c7 05 ba 22 23 f0 	movw   $0x8,0xf02322ba
f0103c93:	08 00 
f0103c95:	c6 05 bc 22 23 f0 00 	movb   $0x0,0xf02322bc
f0103c9c:	c6 05 bd 22 23 f0 8e 	movb   $0x8e,0xf02322bd
f0103ca3:	c1 e8 10             	shr    $0x10,%eax
f0103ca6:	66 a3 be 22 23 f0    	mov    %ax,0xf02322be
	SETGATE(idt[T_STACK], 0, GD_KT, STACK, 0);
f0103cac:	b8 56 43 10 f0       	mov    $0xf0104356,%eax
f0103cb1:	66 a3 c0 22 23 f0    	mov    %ax,0xf02322c0
f0103cb7:	66 c7 05 c2 22 23 f0 	movw   $0x8,0xf02322c2
f0103cbe:	08 00 
f0103cc0:	c6 05 c4 22 23 f0 00 	movb   $0x0,0xf02322c4
f0103cc7:	c6 05 c5 22 23 f0 8e 	movb   $0x8e,0xf02322c5
f0103cce:	c1 e8 10             	shr    $0x10,%eax
f0103cd1:	66 a3 c6 22 23 f0    	mov    %ax,0xf02322c6
	SETGATE(idt[T_GPFLT], 0, GD_KT, GPFLT, 0);
f0103cd7:	b8 5a 43 10 f0       	mov    $0xf010435a,%eax
f0103cdc:	66 a3 c8 22 23 f0    	mov    %ax,0xf02322c8
f0103ce2:	66 c7 05 ca 22 23 f0 	movw   $0x8,0xf02322ca
f0103ce9:	08 00 
f0103ceb:	c6 05 cc 22 23 f0 00 	movb   $0x0,0xf02322cc
f0103cf2:	c6 05 cd 22 23 f0 8e 	movb   $0x8e,0xf02322cd
f0103cf9:	c1 e8 10             	shr    $0x10,%eax
f0103cfc:	66 a3 ce 22 23 f0    	mov    %ax,0xf02322ce
	SETGATE(idt[T_PGFLT], 0, GD_KT, PGFLT, 0);
f0103d02:	b8 5e 43 10 f0       	mov    $0xf010435e,%eax
f0103d07:	66 a3 d0 22 23 f0    	mov    %ax,0xf02322d0
f0103d0d:	66 c7 05 d2 22 23 f0 	movw   $0x8,0xf02322d2
f0103d14:	08 00 
f0103d16:	c6 05 d4 22 23 f0 00 	movb   $0x0,0xf02322d4
f0103d1d:	c6 05 d5 22 23 f0 8e 	movb   $0x8e,0xf02322d5
f0103d24:	c1 e8 10             	shr    $0x10,%eax
f0103d27:	66 a3 d6 22 23 f0    	mov    %ax,0xf02322d6
	SETGATE(idt[T_FPERR], 0, GD_KT, FPERR, 0);
f0103d2d:	b8 62 43 10 f0       	mov    $0xf0104362,%eax
f0103d32:	66 a3 e0 22 23 f0    	mov    %ax,0xf02322e0
f0103d38:	66 c7 05 e2 22 23 f0 	movw   $0x8,0xf02322e2
f0103d3f:	08 00 
f0103d41:	c6 05 e4 22 23 f0 00 	movb   $0x0,0xf02322e4
f0103d48:	c6 05 e5 22 23 f0 8e 	movb   $0x8e,0xf02322e5
f0103d4f:	c1 e8 10             	shr    $0x10,%eax
f0103d52:	66 a3 e6 22 23 f0    	mov    %ax,0xf02322e6
	SETGATE(idt[T_ALIGN], 0, GD_KT, ALIGN, 0);
f0103d58:	b8 68 43 10 f0       	mov    $0xf0104368,%eax
f0103d5d:	66 a3 e8 22 23 f0    	mov    %ax,0xf02322e8
f0103d63:	66 c7 05 ea 22 23 f0 	movw   $0x8,0xf02322ea
f0103d6a:	08 00 
f0103d6c:	c6 05 ec 22 23 f0 00 	movb   $0x0,0xf02322ec
f0103d73:	c6 05 ed 22 23 f0 8e 	movb   $0x8e,0xf02322ed
f0103d7a:	c1 e8 10             	shr    $0x10,%eax
f0103d7d:	66 a3 ee 22 23 f0    	mov    %ax,0xf02322ee
	SETGATE(idt[T_MCHK], 0, GD_KT, MCHK, 0);
f0103d83:	b8 6c 43 10 f0       	mov    $0xf010436c,%eax
f0103d88:	66 a3 f0 22 23 f0    	mov    %ax,0xf02322f0
f0103d8e:	66 c7 05 f2 22 23 f0 	movw   $0x8,0xf02322f2
f0103d95:	08 00 
f0103d97:	c6 05 f4 22 23 f0 00 	movb   $0x0,0xf02322f4
f0103d9e:	c6 05 f5 22 23 f0 8e 	movb   $0x8e,0xf02322f5
f0103da5:	c1 e8 10             	shr    $0x10,%eax
f0103da8:	66 a3 f6 22 23 f0    	mov    %ax,0xf02322f6
	SETGATE(idt[T_SIMDERR], 0, GD_KT, SIMDERR, 0);
f0103dae:	b8 72 43 10 f0       	mov    $0xf0104372,%eax
f0103db3:	66 a3 f8 22 23 f0    	mov    %ax,0xf02322f8
f0103db9:	66 c7 05 fa 22 23 f0 	movw   $0x8,0xf02322fa
f0103dc0:	08 00 
f0103dc2:	c6 05 fc 22 23 f0 00 	movb   $0x0,0xf02322fc
f0103dc9:	c6 05 fd 22 23 f0 8e 	movb   $0x8e,0xf02322fd
f0103dd0:	c1 e8 10             	shr    $0x10,%eax
f0103dd3:	66 a3 fe 22 23 f0    	mov    %ax,0xf02322fe
	SETGATE(idt[T_SYSCALL], 1, GD_KT, SYSCALL, 3);
f0103dd9:	b8 78 43 10 f0       	mov    $0xf0104378,%eax
f0103dde:	66 a3 e0 23 23 f0    	mov    %ax,0xf02323e0
f0103de4:	66 c7 05 e2 23 23 f0 	movw   $0x8,0xf02323e2
f0103deb:	08 00 
f0103ded:	c6 05 e4 23 23 f0 00 	movb   $0x0,0xf02323e4
f0103df4:	c6 05 e5 23 23 f0 ef 	movb   $0xef,0xf02323e5
f0103dfb:	c1 e8 10             	shr    $0x10,%eax
f0103dfe:	66 a3 e6 23 23 f0    	mov    %ax,0xf02323e6
	SETGATE(idt[T_DEFAULT], 0, GD_KT, DEFAULT, 0);
f0103e04:	b8 7e 43 10 f0       	mov    $0xf010437e,%eax
f0103e09:	66 a3 00 32 23 f0    	mov    %ax,0xf0233200
f0103e0f:	66 c7 05 02 32 23 f0 	movw   $0x8,0xf0233202
f0103e16:	08 00 
f0103e18:	c6 05 04 32 23 f0 00 	movb   $0x0,0xf0233204
f0103e1f:	c6 05 05 32 23 f0 8e 	movb   $0x8e,0xf0233205
f0103e26:	c1 e8 10             	shr    $0x10,%eax
f0103e29:	66 a3 06 32 23 f0    	mov    %ax,0xf0233206
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
f0103e46:	68 bb 75 10 f0       	push   $0xf01075bb
f0103e4b:	e8 7d fb ff ff       	call   f01039cd <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103e50:	83 c4 08             	add    $0x8,%esp
f0103e53:	ff 73 04             	pushl  0x4(%ebx)
f0103e56:	68 ca 75 10 f0       	push   $0xf01075ca
f0103e5b:	e8 6d fb ff ff       	call   f01039cd <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103e60:	83 c4 08             	add    $0x8,%esp
f0103e63:	ff 73 08             	pushl  0x8(%ebx)
f0103e66:	68 d9 75 10 f0       	push   $0xf01075d9
f0103e6b:	e8 5d fb ff ff       	call   f01039cd <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103e70:	83 c4 08             	add    $0x8,%esp
f0103e73:	ff 73 0c             	pushl  0xc(%ebx)
f0103e76:	68 e8 75 10 f0       	push   $0xf01075e8
f0103e7b:	e8 4d fb ff ff       	call   f01039cd <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103e80:	83 c4 08             	add    $0x8,%esp
f0103e83:	ff 73 10             	pushl  0x10(%ebx)
f0103e86:	68 f7 75 10 f0       	push   $0xf01075f7
f0103e8b:	e8 3d fb ff ff       	call   f01039cd <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103e90:	83 c4 08             	add    $0x8,%esp
f0103e93:	ff 73 14             	pushl  0x14(%ebx)
f0103e96:	68 06 76 10 f0       	push   $0xf0107606
f0103e9b:	e8 2d fb ff ff       	call   f01039cd <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103ea0:	83 c4 08             	add    $0x8,%esp
f0103ea3:	ff 73 18             	pushl  0x18(%ebx)
f0103ea6:	68 15 76 10 f0       	push   $0xf0107615
f0103eab:	e8 1d fb ff ff       	call   f01039cd <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103eb0:	83 c4 08             	add    $0x8,%esp
f0103eb3:	ff 73 1c             	pushl  0x1c(%ebx)
f0103eb6:	68 24 76 10 f0       	push   $0xf0107624
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
f0103ed4:	e8 ad 1c 00 00       	call   f0105b86 <cpunum>
f0103ed9:	83 ec 04             	sub    $0x4,%esp
f0103edc:	50                   	push   %eax
f0103edd:	53                   	push   %ebx
f0103ede:	68 88 76 10 f0       	push   $0xf0107688
f0103ee3:	e8 e5 fa ff ff       	call   f01039cd <cprintf>
	print_regs(&tf->tf_regs);
f0103ee8:	89 1c 24             	mov    %ebx,(%esp)
f0103eeb:	e8 46 ff ff ff       	call   f0103e36 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103ef0:	83 c4 08             	add    $0x8,%esp
f0103ef3:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103ef7:	50                   	push   %eax
f0103ef8:	68 a6 76 10 f0       	push   $0xf01076a6
f0103efd:	e8 cb fa ff ff       	call   f01039cd <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103f02:	83 c4 08             	add    $0x8,%esp
f0103f05:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103f09:	50                   	push   %eax
f0103f0a:	68 b9 76 10 f0       	push   $0xf01076b9
f0103f0f:	e8 b9 fa ff ff       	call   f01039cd <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103f14:	8b 43 28             	mov    0x28(%ebx),%eax
	if (trapno < ARRAY_SIZE(excnames))
f0103f17:	83 c4 10             	add    $0x10,%esp
f0103f1a:	83 f8 13             	cmp    $0x13,%eax
f0103f1d:	0f 86 da 00 00 00    	jbe    f0103ffd <print_trapframe+0x135>
		return "System call";
f0103f23:	ba 33 76 10 f0       	mov    $0xf0107633,%edx
	if (trapno == T_SYSCALL)
f0103f28:	83 f8 30             	cmp    $0x30,%eax
f0103f2b:	74 13                	je     f0103f40 <print_trapframe+0x78>
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103f2d:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
f0103f30:	83 fa 0f             	cmp    $0xf,%edx
f0103f33:	ba 3f 76 10 f0       	mov    $0xf010763f,%edx
f0103f38:	b9 4e 76 10 f0       	mov    $0xf010764e,%ecx
f0103f3d:	0f 46 d1             	cmovbe %ecx,%edx
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103f40:	83 ec 04             	sub    $0x4,%esp
f0103f43:	52                   	push   %edx
f0103f44:	50                   	push   %eax
f0103f45:	68 cc 76 10 f0       	push   $0xf01076cc
f0103f4a:	e8 7e fa ff ff       	call   f01039cd <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103f4f:	83 c4 10             	add    $0x10,%esp
f0103f52:	39 1d 60 2a 23 f0    	cmp    %ebx,0xf0232a60
f0103f58:	0f 84 ab 00 00 00    	je     f0104009 <print_trapframe+0x141>
	cprintf("  err  0x%08x", tf->tf_err);
f0103f5e:	83 ec 08             	sub    $0x8,%esp
f0103f61:	ff 73 2c             	pushl  0x2c(%ebx)
f0103f64:	68 ed 76 10 f0       	push   $0xf01076ed
f0103f69:	e8 5f fa ff ff       	call   f01039cd <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f0103f6e:	83 c4 10             	add    $0x10,%esp
f0103f71:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103f75:	0f 85 b1 00 00 00    	jne    f010402c <print_trapframe+0x164>
			tf->tf_err & 1 ? "protection" : "not-present");
f0103f7b:	8b 43 2c             	mov    0x2c(%ebx),%eax
		cprintf(" [%s, %s, %s]\n",
f0103f7e:	a8 01                	test   $0x1,%al
f0103f80:	b9 61 76 10 f0       	mov    $0xf0107661,%ecx
f0103f85:	ba 6c 76 10 f0       	mov    $0xf010766c,%edx
f0103f8a:	0f 44 ca             	cmove  %edx,%ecx
f0103f8d:	a8 02                	test   $0x2,%al
f0103f8f:	be 78 76 10 f0       	mov    $0xf0107678,%esi
f0103f94:	ba 7e 76 10 f0       	mov    $0xf010767e,%edx
f0103f99:	0f 45 d6             	cmovne %esi,%edx
f0103f9c:	a8 04                	test   $0x4,%al
f0103f9e:	b8 83 76 10 f0       	mov    $0xf0107683,%eax
f0103fa3:	be b8 77 10 f0       	mov    $0xf01077b8,%esi
f0103fa8:	0f 44 c6             	cmove  %esi,%eax
f0103fab:	51                   	push   %ecx
f0103fac:	52                   	push   %edx
f0103fad:	50                   	push   %eax
f0103fae:	68 fb 76 10 f0       	push   $0xf01076fb
f0103fb3:	e8 15 fa ff ff       	call   f01039cd <cprintf>
f0103fb8:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103fbb:	83 ec 08             	sub    $0x8,%esp
f0103fbe:	ff 73 30             	pushl  0x30(%ebx)
f0103fc1:	68 0a 77 10 f0       	push   $0xf010770a
f0103fc6:	e8 02 fa ff ff       	call   f01039cd <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103fcb:	83 c4 08             	add    $0x8,%esp
f0103fce:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103fd2:	50                   	push   %eax
f0103fd3:	68 19 77 10 f0       	push   $0xf0107719
f0103fd8:	e8 f0 f9 ff ff       	call   f01039cd <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103fdd:	83 c4 08             	add    $0x8,%esp
f0103fe0:	ff 73 38             	pushl  0x38(%ebx)
f0103fe3:	68 2c 77 10 f0       	push   $0xf010772c
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
f0103ffd:	8b 14 85 60 79 10 f0 	mov    -0xfef86a0(,%eax,4),%edx
f0104004:	e9 37 ff ff ff       	jmp    f0103f40 <print_trapframe+0x78>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0104009:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010400d:	0f 85 4b ff ff ff    	jne    f0103f5e <print_trapframe+0x96>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0104013:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0104016:	83 ec 08             	sub    $0x8,%esp
f0104019:	50                   	push   %eax
f010401a:	68 de 76 10 f0       	push   $0xf01076de
f010401f:	e8 a9 f9 ff ff       	call   f01039cd <cprintf>
f0104024:	83 c4 10             	add    $0x10,%esp
f0104027:	e9 32 ff ff ff       	jmp    f0103f5e <print_trapframe+0x96>
		cprintf("\n");
f010402c:	83 ec 0c             	sub    $0xc,%esp
f010402f:	68 3d 74 10 f0       	push   $0xf010743d
f0104034:	e8 94 f9 ff ff       	call   f01039cd <cprintf>
f0104039:	83 c4 10             	add    $0x10,%esp
f010403c:	e9 7a ff ff ff       	jmp    f0103fbb <print_trapframe+0xf3>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0104041:	83 ec 08             	sub    $0x8,%esp
f0104044:	ff 73 3c             	pushl  0x3c(%ebx)
f0104047:	68 3b 77 10 f0       	push   $0xf010773b
f010404c:	e8 7c f9 ff ff       	call   f01039cd <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0104051:	83 c4 08             	add    $0x8,%esp
f0104054:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0104058:	50                   	push   %eax
f0104059:	68 4a 77 10 f0       	push   $0xf010774a
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
f0104072:	83 ec 0c             	sub    $0xc,%esp
f0104075:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104078:	0f 20 d6             	mov    %cr2,%esi

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	// check low-bits of tf_cs
	if((tf->tf_cs & 3) == 0)
f010407b:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f010407f:	74 49                	je     f01040ca <page_fault_handler+0x62>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0104081:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0104084:	e8 fd 1a 00 00       	call   f0105b86 <cpunum>
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0104089:	57                   	push   %edi
f010408a:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f010408b:	6b c0 74             	imul   $0x74,%eax,%eax
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010408e:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
f0104094:	ff 70 48             	pushl  0x48(%eax)
f0104097:	68 30 79 10 f0       	push   $0xf0107930
f010409c:	e8 2c f9 ff ff       	call   f01039cd <cprintf>
	print_trapframe(tf);
f01040a1:	89 1c 24             	mov    %ebx,(%esp)
f01040a4:	e8 1f fe ff ff       	call   f0103ec8 <print_trapframe>
	env_destroy(curenv);
f01040a9:	e8 d8 1a 00 00       	call   f0105b86 <cpunum>
f01040ae:	83 c4 04             	add    $0x4,%esp
f01040b1:	6b c0 74             	imul   $0x74,%eax,%eax
f01040b4:	ff b0 28 30 23 f0    	pushl  -0xfdccfd8(%eax)
f01040ba:	e8 e9 f5 ff ff       	call   f01036a8 <env_destroy>
}
f01040bf:	83 c4 10             	add    $0x10,%esp
f01040c2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01040c5:	5b                   	pop    %ebx
f01040c6:	5e                   	pop    %esi
f01040c7:	5f                   	pop    %edi
f01040c8:	5d                   	pop    %ebp
f01040c9:	c3                   	ret    
		panic("At page_fault_handler: page fault at %08x.\n",fault_va);
f01040ca:	56                   	push   %esi
f01040cb:	68 04 79 10 f0       	push   $0xf0107904
f01040d0:	68 6d 01 00 00       	push   $0x16d
f01040d5:	68 5d 77 10 f0       	push   $0xf010775d
f01040da:	e8 61 bf ff ff       	call   f0100040 <_panic>

f01040df <trap>:
{
f01040df:	f3 0f 1e fb          	endbr32 
f01040e3:	55                   	push   %ebp
f01040e4:	89 e5                	mov    %esp,%ebp
f01040e6:	57                   	push   %edi
f01040e7:	56                   	push   %esi
f01040e8:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::: "cc");
f01040eb:	fc                   	cld    
	if (panicstr)
f01040ec:	83 3d 80 2e 23 f0 00 	cmpl   $0x0,0xf0232e80
f01040f3:	74 01                	je     f01040f6 <trap+0x17>
		asm volatile("hlt");
f01040f5:	f4                   	hlt    
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f01040f6:	e8 8b 1a 00 00       	call   f0105b86 <cpunum>
f01040fb:	6b d0 74             	imul   $0x74,%eax,%edx
f01040fe:	83 c2 04             	add    $0x4,%edx
	asm volatile("lock; xchgl %0, %1"
f0104101:	b8 01 00 00 00       	mov    $0x1,%eax
f0104106:	f0 87 82 20 30 23 f0 	lock xchg %eax,-0xfdccfe0(%edx)
f010410d:	83 f8 02             	cmp    $0x2,%eax
f0104110:	74 58                	je     f010416a <trap+0x8b>
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0104112:	9c                   	pushf  
f0104113:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
f0104114:	f6 c4 02             	test   $0x2,%ah
f0104117:	75 63                	jne    f010417c <trap+0x9d>
	if ((tf->tf_cs & 3) == 3) {
f0104119:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f010411d:	83 e0 03             	and    $0x3,%eax
f0104120:	66 83 f8 03          	cmp    $0x3,%ax
f0104124:	74 6f                	je     f0104195 <trap+0xb6>
	last_tf = tf;
f0104126:	89 35 60 2a 23 f0    	mov    %esi,0xf0232a60
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f010412c:	8b 46 28             	mov    0x28(%esi),%eax
f010412f:	83 f8 27             	cmp    $0x27,%eax
f0104132:	0f 84 02 01 00 00    	je     f010423a <trap+0x15b>
	switch(tf->tf_trapno)
f0104138:	83 f8 0e             	cmp    $0xe,%eax
f010413b:	0f 84 39 01 00 00    	je     f010427a <trap+0x19b>
f0104141:	0f 87 0d 01 00 00    	ja     f0104254 <trap+0x175>
f0104147:	83 f8 01             	cmp    $0x1,%eax
f010414a:	0f 84 60 01 00 00    	je     f01042b0 <trap+0x1d1>
f0104150:	83 f8 03             	cmp    $0x3,%eax
f0104153:	0f 85 65 01 00 00    	jne    f01042be <trap+0x1df>
			monitor(tf);
f0104159:	83 ec 0c             	sub    $0xc,%esp
f010415c:	56                   	push   %esi
f010415d:	e8 12 c8 ff ff       	call   f0100974 <monitor>
			return;
f0104162:	83 c4 10             	add    $0x10,%esp
f0104165:	e9 1c 01 00 00       	jmp    f0104286 <trap+0x1a7>
	spin_lock(&kernel_lock);
f010416a:	83 ec 0c             	sub    $0xc,%esp
f010416d:	68 c0 23 12 f0       	push   $0xf01223c0
f0104172:	e8 97 1c 00 00       	call   f0105e0e <spin_lock>
}
f0104177:	83 c4 10             	add    $0x10,%esp
f010417a:	eb 96                	jmp    f0104112 <trap+0x33>
	assert(!(read_eflags() & FL_IF));
f010417c:	68 69 77 10 f0       	push   $0xf0107769
f0104181:	68 83 71 10 f0       	push   $0xf0107183
f0104186:	68 35 01 00 00       	push   $0x135
f010418b:	68 5d 77 10 f0       	push   $0xf010775d
f0104190:	e8 ab be ff ff       	call   f0100040 <_panic>
	spin_lock(&kernel_lock);
f0104195:	83 ec 0c             	sub    $0xc,%esp
f0104198:	68 c0 23 12 f0       	push   $0xf01223c0
f010419d:	e8 6c 1c 00 00       	call   f0105e0e <spin_lock>
		assert(curenv);
f01041a2:	e8 df 19 00 00       	call   f0105b86 <cpunum>
f01041a7:	6b c0 74             	imul   $0x74,%eax,%eax
f01041aa:	83 c4 10             	add    $0x10,%esp
f01041ad:	83 b8 28 30 23 f0 00 	cmpl   $0x0,-0xfdccfd8(%eax)
f01041b4:	74 3e                	je     f01041f4 <trap+0x115>
		if (curenv->env_status == ENV_DYING) {
f01041b6:	e8 cb 19 00 00       	call   f0105b86 <cpunum>
f01041bb:	6b c0 74             	imul   $0x74,%eax,%eax
f01041be:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
f01041c4:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f01041c8:	74 43                	je     f010420d <trap+0x12e>
		curenv->env_tf = *tf;
f01041ca:	e8 b7 19 00 00       	call   f0105b86 <cpunum>
f01041cf:	6b c0 74             	imul   $0x74,%eax,%eax
f01041d2:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
f01041d8:	b9 11 00 00 00       	mov    $0x11,%ecx
f01041dd:	89 c7                	mov    %eax,%edi
f01041df:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &curenv->env_tf;
f01041e1:	e8 a0 19 00 00       	call   f0105b86 <cpunum>
f01041e6:	6b c0 74             	imul   $0x74,%eax,%eax
f01041e9:	8b b0 28 30 23 f0    	mov    -0xfdccfd8(%eax),%esi
f01041ef:	e9 32 ff ff ff       	jmp    f0104126 <trap+0x47>
		assert(curenv);
f01041f4:	68 82 77 10 f0       	push   $0xf0107782
f01041f9:	68 83 71 10 f0       	push   $0xf0107183
f01041fe:	68 3d 01 00 00       	push   $0x13d
f0104203:	68 5d 77 10 f0       	push   $0xf010775d
f0104208:	e8 33 be ff ff       	call   f0100040 <_panic>
			env_free(curenv);
f010420d:	e8 74 19 00 00       	call   f0105b86 <cpunum>
f0104212:	83 ec 0c             	sub    $0xc,%esp
f0104215:	6b c0 74             	imul   $0x74,%eax,%eax
f0104218:	ff b0 28 30 23 f0    	pushl  -0xfdccfd8(%eax)
f010421e:	e8 a4 f2 ff ff       	call   f01034c7 <env_free>
			curenv = NULL;
f0104223:	e8 5e 19 00 00       	call   f0105b86 <cpunum>
f0104228:	6b c0 74             	imul   $0x74,%eax,%eax
f010422b:	c7 80 28 30 23 f0 00 	movl   $0x0,-0xfdccfd8(%eax)
f0104232:	00 00 00 
			sched_yield();
f0104235:	e8 2b 02 00 00       	call   f0104465 <sched_yield>
		cprintf("Spurious interrupt on irq 7\n");
f010423a:	83 ec 0c             	sub    $0xc,%esp
f010423d:	68 89 77 10 f0       	push   $0xf0107789
f0104242:	e8 86 f7 ff ff       	call   f01039cd <cprintf>
		print_trapframe(tf);
f0104247:	89 34 24             	mov    %esi,(%esp)
f010424a:	e8 79 fc ff ff       	call   f0103ec8 <print_trapframe>
		return;
f010424f:	83 c4 10             	add    $0x10,%esp
f0104252:	eb 32                	jmp    f0104286 <trap+0x1a7>
	switch(tf->tf_trapno)
f0104254:	83 f8 30             	cmp    $0x30,%eax
f0104257:	75 65                	jne    f01042be <trap+0x1df>
			int32_t ret = syscall(regs->reg_eax,regs->reg_edx,regs->reg_ecx,regs->reg_ebx,regs->reg_edi,regs->reg_esi);
f0104259:	83 ec 08             	sub    $0x8,%esp
f010425c:	ff 76 04             	pushl  0x4(%esi)
f010425f:	ff 36                	pushl  (%esi)
f0104261:	ff 76 10             	pushl  0x10(%esi)
f0104264:	ff 76 18             	pushl  0x18(%esi)
f0104267:	ff 76 14             	pushl  0x14(%esi)
f010426a:	ff 76 1c             	pushl  0x1c(%esi)
f010426d:	e8 ab 02 00 00       	call   f010451d <syscall>
			regs->reg_eax = (uint32_t)ret;
f0104272:	89 46 1c             	mov    %eax,0x1c(%esi)
			return;
f0104275:	83 c4 20             	add    $0x20,%esp
f0104278:	eb 0c                	jmp    f0104286 <trap+0x1a7>
			page_fault_handler(tf);
f010427a:	83 ec 0c             	sub    $0xc,%esp
f010427d:	56                   	push   %esi
f010427e:	e8 e5 fd ff ff       	call   f0104068 <page_fault_handler>
			return;
f0104283:	83 c4 10             	add    $0x10,%esp
	if (curenv && curenv->env_status == ENV_RUNNING)
f0104286:	e8 fb 18 00 00       	call   f0105b86 <cpunum>
f010428b:	6b c0 74             	imul   $0x74,%eax,%eax
f010428e:	83 b8 28 30 23 f0 00 	cmpl   $0x0,-0xfdccfd8(%eax)
f0104295:	74 14                	je     f01042ab <trap+0x1cc>
f0104297:	e8 ea 18 00 00       	call   f0105b86 <cpunum>
f010429c:	6b c0 74             	imul   $0x74,%eax,%eax
f010429f:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
f01042a5:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01042a9:	74 58                	je     f0104303 <trap+0x224>
		sched_yield();
f01042ab:	e8 b5 01 00 00       	call   f0104465 <sched_yield>
			monitor(tf);
f01042b0:	83 ec 0c             	sub    $0xc,%esp
f01042b3:	56                   	push   %esi
f01042b4:	e8 bb c6 ff ff       	call   f0100974 <monitor>
			return;
f01042b9:	83 c4 10             	add    $0x10,%esp
f01042bc:	eb c8                	jmp    f0104286 <trap+0x1a7>
	print_trapframe(tf);
f01042be:	83 ec 0c             	sub    $0xc,%esp
f01042c1:	56                   	push   %esi
f01042c2:	e8 01 fc ff ff       	call   f0103ec8 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01042c7:	83 c4 10             	add    $0x10,%esp
f01042ca:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01042cf:	74 1b                	je     f01042ec <trap+0x20d>
		env_destroy(curenv);
f01042d1:	e8 b0 18 00 00       	call   f0105b86 <cpunum>
f01042d6:	83 ec 0c             	sub    $0xc,%esp
f01042d9:	6b c0 74             	imul   $0x74,%eax,%eax
f01042dc:	ff b0 28 30 23 f0    	pushl  -0xfdccfd8(%eax)
f01042e2:	e8 c1 f3 ff ff       	call   f01036a8 <env_destroy>
		return;
f01042e7:	83 c4 10             	add    $0x10,%esp
f01042ea:	eb 9a                	jmp    f0104286 <trap+0x1a7>
		panic("unhandled trap in kernel");
f01042ec:	83 ec 04             	sub    $0x4,%esp
f01042ef:	68 a6 77 10 f0       	push   $0xf01077a6
f01042f4:	68 1b 01 00 00       	push   $0x11b
f01042f9:	68 5d 77 10 f0       	push   $0xf010775d
f01042fe:	e8 3d bd ff ff       	call   f0100040 <_panic>
		env_run(curenv);
f0104303:	e8 7e 18 00 00       	call   f0105b86 <cpunum>
f0104308:	83 ec 0c             	sub    $0xc,%esp
f010430b:	6b c0 74             	imul   $0x74,%eax,%eax
f010430e:	ff b0 28 30 23 f0    	pushl  -0xfdccfd8(%eax)
f0104314:	e8 36 f4 ff ff       	call   f010374f <env_run>
f0104319:	90                   	nop

f010431a <DIVIDE>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(DIVIDE,T_DIVIDE)
f010431a:	6a 00                	push   $0x0
f010431c:	6a 00                	push   $0x0
f010431e:	eb 67                	jmp    f0104387 <_alltraps>

f0104320 <DEBUG>:
TRAPHANDLER_NOEC(DEBUG,T_DEBUG)
f0104320:	6a 00                	push   $0x0
f0104322:	6a 01                	push   $0x1
f0104324:	eb 61                	jmp    f0104387 <_alltraps>

f0104326 <NMI>:
TRAPHANDLER_NOEC(NMI, T_NMI)
f0104326:	6a 00                	push   $0x0
f0104328:	6a 02                	push   $0x2
f010432a:	eb 5b                	jmp    f0104387 <_alltraps>

f010432c <BRKPT>:
TRAPHANDLER_NOEC(BRKPT, T_BRKPT)
f010432c:	6a 00                	push   $0x0
f010432e:	6a 03                	push   $0x3
f0104330:	eb 55                	jmp    f0104387 <_alltraps>

f0104332 <OFLOW>:
TRAPHANDLER_NOEC(OFLOW, T_OFLOW)
f0104332:	6a 00                	push   $0x0
f0104334:	6a 04                	push   $0x4
f0104336:	eb 4f                	jmp    f0104387 <_alltraps>

f0104338 <BOUND>:
TRAPHANDLER_NOEC(BOUND, T_BOUND)
f0104338:	6a 00                	push   $0x0
f010433a:	6a 05                	push   $0x5
f010433c:	eb 49                	jmp    f0104387 <_alltraps>

f010433e <ILLOP>:
TRAPHANDLER_NOEC(ILLOP, T_ILLOP)
f010433e:	6a 00                	push   $0x0
f0104340:	6a 06                	push   $0x6
f0104342:	eb 43                	jmp    f0104387 <_alltraps>

f0104344 <DEVICE>:
TRAPHANDLER_NOEC(DEVICE, T_DEVICE)
f0104344:	6a 00                	push   $0x0
f0104346:	6a 07                	push   $0x7
f0104348:	eb 3d                	jmp    f0104387 <_alltraps>

f010434a <DBLFLT>:
TRAPHANDLER(DBLFLT, T_DBLFLT)
f010434a:	6a 08                	push   $0x8
f010434c:	eb 39                	jmp    f0104387 <_alltraps>

f010434e <TSS>:
TRAPHANDLER(TSS, T_TSS)
f010434e:	6a 0a                	push   $0xa
f0104350:	eb 35                	jmp    f0104387 <_alltraps>

f0104352 <SEGNP>:
TRAPHANDLER(SEGNP, T_SEGNP)
f0104352:	6a 0b                	push   $0xb
f0104354:	eb 31                	jmp    f0104387 <_alltraps>

f0104356 <STACK>:
TRAPHANDLER(STACK, T_STACK)
f0104356:	6a 0c                	push   $0xc
f0104358:	eb 2d                	jmp    f0104387 <_alltraps>

f010435a <GPFLT>:
TRAPHANDLER(GPFLT, T_GPFLT)
f010435a:	6a 0d                	push   $0xd
f010435c:	eb 29                	jmp    f0104387 <_alltraps>

f010435e <PGFLT>:
TRAPHANDLER(PGFLT, T_PGFLT)
f010435e:	6a 0e                	push   $0xe
f0104360:	eb 25                	jmp    f0104387 <_alltraps>

f0104362 <FPERR>:
TRAPHANDLER_NOEC(FPERR, T_FPERR)
f0104362:	6a 00                	push   $0x0
f0104364:	6a 10                	push   $0x10
f0104366:	eb 1f                	jmp    f0104387 <_alltraps>

f0104368 <ALIGN>:
TRAPHANDLER(ALIGN, T_ALIGN)
f0104368:	6a 11                	push   $0x11
f010436a:	eb 1b                	jmp    f0104387 <_alltraps>

f010436c <MCHK>:
TRAPHANDLER_NOEC(MCHK, T_MCHK)
f010436c:	6a 00                	push   $0x0
f010436e:	6a 12                	push   $0x12
f0104370:	eb 15                	jmp    f0104387 <_alltraps>

f0104372 <SIMDERR>:
TRAPHANDLER_NOEC(SIMDERR, T_SIMDERR)
f0104372:	6a 00                	push   $0x0
f0104374:	6a 13                	push   $0x13
f0104376:	eb 0f                	jmp    f0104387 <_alltraps>

f0104378 <SYSCALL>:
TRAPHANDLER_NOEC(SYSCALL, T_SYSCALL)
f0104378:	6a 00                	push   $0x0
f010437a:	6a 30                	push   $0x30
f010437c:	eb 09                	jmp    f0104387 <_alltraps>

f010437e <DEFAULT>:
TRAPHANDLER_NOEC(DEFAULT, T_DEFAULT)
f010437e:	6a 00                	push   $0x0
f0104380:	68 f4 01 00 00       	push   $0x1f4
f0104385:	eb 00                	jmp    f0104387 <_alltraps>

f0104387 <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */
 .global _alltraps
 _alltraps:
 /* code below according to the guide */
pushl %ds
f0104387:	1e                   	push   %ds
pushl %es
f0104388:	06                   	push   %es
pushal
f0104389:	60                   	pusha  
movw $GD_KD, %ax
f010438a:	66 b8 10 00          	mov    $0x10,%ax
movw %ax, %ds
f010438e:	8e d8                	mov    %eax,%ds
movw %ax, %es
f0104390:	8e c0                	mov    %eax,%es
pushl %esp
f0104392:	54                   	push   %esp
call trap
f0104393:	e8 47 fd ff ff       	call   f01040df <trap>

f0104398 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104398:	f3 0f 1e fb          	endbr32 
f010439c:	55                   	push   %ebp
f010439d:	89 e5                	mov    %esp,%ebp
f010439f:	83 ec 08             	sub    $0x8,%esp
f01043a2:	a1 48 22 23 f0       	mov    0xf0232248,%eax
f01043a7:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f01043aa:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f01043af:	8b 02                	mov    (%edx),%eax
f01043b1:	83 e8 01             	sub    $0x1,%eax
		if ((envs[i].env_status == ENV_RUNNABLE ||
f01043b4:	83 f8 02             	cmp    $0x2,%eax
f01043b7:	76 2d                	jbe    f01043e6 <sched_halt+0x4e>
	for (i = 0; i < NENV; i++) {
f01043b9:	83 c1 01             	add    $0x1,%ecx
f01043bc:	83 c2 7c             	add    $0x7c,%edx
f01043bf:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f01043c5:	75 e8                	jne    f01043af <sched_halt+0x17>
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
		cprintf("No runnable environments in the system!\n");
f01043c7:	83 ec 0c             	sub    $0xc,%esp
f01043ca:	68 b0 79 10 f0       	push   $0xf01079b0
f01043cf:	e8 f9 f5 ff ff       	call   f01039cd <cprintf>
f01043d4:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f01043d7:	83 ec 0c             	sub    $0xc,%esp
f01043da:	6a 00                	push   $0x0
f01043dc:	e8 93 c5 ff ff       	call   f0100974 <monitor>
f01043e1:	83 c4 10             	add    $0x10,%esp
f01043e4:	eb f1                	jmp    f01043d7 <sched_halt+0x3f>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f01043e6:	e8 9b 17 00 00       	call   f0105b86 <cpunum>
f01043eb:	6b c0 74             	imul   $0x74,%eax,%eax
f01043ee:	c7 80 28 30 23 f0 00 	movl   $0x0,-0xfdccfd8(%eax)
f01043f5:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f01043f8:	a1 8c 2e 23 f0       	mov    0xf0232e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01043fd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104402:	76 4f                	jbe    f0104453 <sched_halt+0xbb>
	return (physaddr_t)kva - KERNBASE;
f0104404:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0104409:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f010440c:	e8 75 17 00 00       	call   f0105b86 <cpunum>
f0104411:	6b d0 74             	imul   $0x74,%eax,%edx
f0104414:	83 c2 04             	add    $0x4,%edx
	asm volatile("lock; xchgl %0, %1"
f0104417:	b8 02 00 00 00       	mov    $0x2,%eax
f010441c:	f0 87 82 20 30 23 f0 	lock xchg %eax,-0xfdccfe0(%edx)
	spin_unlock(&kernel_lock);
f0104423:	83 ec 0c             	sub    $0xc,%esp
f0104426:	68 c0 23 12 f0       	push   $0xf01223c0
f010442b:	e8 7c 1a 00 00       	call   f0105eac <spin_unlock>
	asm volatile("pause");
f0104430:	f3 90                	pause  
		// Uncomment the following line after completing exercise 13
		//"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104432:	e8 4f 17 00 00       	call   f0105b86 <cpunum>
f0104437:	6b c0 74             	imul   $0x74,%eax,%eax
	asm volatile (
f010443a:	8b 80 30 30 23 f0    	mov    -0xfdccfd0(%eax),%eax
f0104440:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104445:	89 c4                	mov    %eax,%esp
f0104447:	6a 00                	push   $0x0
f0104449:	6a 00                	push   $0x0
f010444b:	f4                   	hlt    
f010444c:	eb fd                	jmp    f010444b <sched_halt+0xb3>
}
f010444e:	83 c4 10             	add    $0x10,%esp
f0104451:	c9                   	leave  
f0104452:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104453:	50                   	push   %eax
f0104454:	68 48 62 10 f0       	push   $0xf0106248
f0104459:	6a 55                	push   $0x55
f010445b:	68 d9 79 10 f0       	push   $0xf01079d9
f0104460:	e8 db bb ff ff       	call   f0100040 <_panic>

f0104465 <sched_yield>:
{
f0104465:	f3 0f 1e fb          	endbr32 
f0104469:	55                   	push   %ebp
f010446a:	89 e5                	mov    %esp,%ebp
f010446c:	56                   	push   %esi
f010446d:	53                   	push   %ebx
	if(curenv)
f010446e:	e8 13 17 00 00       	call   f0105b86 <cpunum>
f0104473:	6b c0 74             	imul   $0x74,%eax,%eax
	int begin = 0;
f0104476:	b9 00 00 00 00       	mov    $0x0,%ecx
	if(curenv)
f010447b:	83 b8 28 30 23 f0 00 	cmpl   $0x0,-0xfdccfd8(%eax)
f0104482:	74 17                	je     f010449b <sched_yield+0x36>
		begin = ENVX(curenv->env_id);
f0104484:	e8 fd 16 00 00       	call   f0105b86 <cpunum>
f0104489:	6b c0 74             	imul   $0x74,%eax,%eax
f010448c:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
f0104492:	8b 48 48             	mov    0x48(%eax),%ecx
f0104495:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
		idle = &envs[(i+begin)%NENV];
f010449b:	8b 1d 48 22 23 f0    	mov    0xf0232248,%ebx
f01044a1:	89 ca                	mov    %ecx,%edx
f01044a3:	81 c1 00 04 00 00    	add    $0x400,%ecx
f01044a9:	89 d6                	mov    %edx,%esi
f01044ab:	c1 fe 1f             	sar    $0x1f,%esi
f01044ae:	c1 ee 16             	shr    $0x16,%esi
f01044b1:	8d 04 32             	lea    (%edx,%esi,1),%eax
f01044b4:	25 ff 03 00 00       	and    $0x3ff,%eax
f01044b9:	29 f0                	sub    %esi,%eax
f01044bb:	6b c0 7c             	imul   $0x7c,%eax,%eax
f01044be:	01 d8                	add    %ebx,%eax
		if(idle->env_status == ENV_RUNNABLE)
f01044c0:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f01044c4:	74 38                	je     f01044fe <sched_yield+0x99>
f01044c6:	83 c2 01             	add    $0x1,%edx
	for(int i = 0;i<NENV;i++)
f01044c9:	39 ca                	cmp    %ecx,%edx
f01044cb:	75 dc                	jne    f01044a9 <sched_yield+0x44>
	if(!flag && curenv && curenv->env_status == ENV_RUNNING)
f01044cd:	e8 b4 16 00 00       	call   f0105b86 <cpunum>
f01044d2:	6b c0 74             	imul   $0x74,%eax,%eax
f01044d5:	83 b8 28 30 23 f0 00 	cmpl   $0x0,-0xfdccfd8(%eax)
f01044dc:	74 14                	je     f01044f2 <sched_yield+0x8d>
f01044de:	e8 a3 16 00 00       	call   f0105b86 <cpunum>
f01044e3:	6b c0 74             	imul   $0x74,%eax,%eax
f01044e6:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
f01044ec:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01044f0:	74 15                	je     f0104507 <sched_yield+0xa2>
		sched_halt();
f01044f2:	e8 a1 fe ff ff       	call   f0104398 <sched_halt>
}
f01044f7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01044fa:	5b                   	pop    %ebx
f01044fb:	5e                   	pop    %esi
f01044fc:	5d                   	pop    %ebp
f01044fd:	c3                   	ret    
			env_run(idle);
f01044fe:	83 ec 0c             	sub    $0xc,%esp
f0104501:	50                   	push   %eax
f0104502:	e8 48 f2 ff ff       	call   f010374f <env_run>
		env_run(curenv);
f0104507:	e8 7a 16 00 00       	call   f0105b86 <cpunum>
f010450c:	83 ec 0c             	sub    $0xc,%esp
f010450f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104512:	ff b0 28 30 23 f0    	pushl  -0xfdccfd8(%eax)
f0104518:	e8 32 f2 ff ff       	call   f010374f <env_run>

f010451d <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f010451d:	f3 0f 1e fb          	endbr32 
f0104521:	55                   	push   %ebp
f0104522:	89 e5                	mov    %esp,%ebp
f0104524:	57                   	push   %edi
f0104525:	56                   	push   %esi
f0104526:	53                   	push   %ebx
f0104527:	83 ec 1c             	sub    $0x1c,%esp
f010452a:	8b 45 08             	mov    0x8(%ebp),%eax
f010452d:	83 f8 0d             	cmp    $0xd,%eax
f0104530:	77 08                	ja     f010453a <syscall+0x1d>
f0104532:	3e ff 24 85 20 7a 10 	notrack jmp *-0xfef85e0(,%eax,4)
f0104539:	f0 
		{
			return sys_env_destroy((envid_t)a1);
		}
		case NSYSCALLS:
		{
			return 0;
f010453a:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
			return sys_page_unmap((envid_t)a1,(void*)a2);
		}
		default:
			return -E_INVAL;
	}
}
f010453f:	89 d8                	mov    %ebx,%eax
f0104541:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104544:	5b                   	pop    %ebx
f0104545:	5e                   	pop    %esi
f0104546:	5f                   	pop    %edi
f0104547:	5d                   	pop    %ebp
f0104548:	c3                   	ret    
	user_mem_assert(curenv,s,len,0);
f0104549:	e8 38 16 00 00       	call   f0105b86 <cpunum>
f010454e:	6a 00                	push   $0x0
f0104550:	ff 75 10             	pushl  0x10(%ebp)
f0104553:	ff 75 0c             	pushl  0xc(%ebp)
f0104556:	6b c0 74             	imul   $0x74,%eax,%eax
f0104559:	ff b0 28 30 23 f0    	pushl  -0xfdccfd8(%eax)
f010455f:	e8 55 ea ff ff       	call   f0102fb9 <user_mem_assert>
	cprintf("%.*s", len, s);
f0104564:	83 c4 0c             	add    $0xc,%esp
f0104567:	ff 75 0c             	pushl  0xc(%ebp)
f010456a:	ff 75 10             	pushl  0x10(%ebp)
f010456d:	68 e6 79 10 f0       	push   $0xf01079e6
f0104572:	e8 56 f4 ff ff       	call   f01039cd <cprintf>
}
f0104577:	83 c4 10             	add    $0x10,%esp
			return 0;
f010457a:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f010457f:	eb be                	jmp    f010453f <syscall+0x22>
	return cons_getc();
f0104581:	e8 8e c0 ff ff       	call   f0100614 <cons_getc>
f0104586:	89 c3                	mov    %eax,%ebx
			return sys_cgetc();
f0104588:	eb b5                	jmp    f010453f <syscall+0x22>
	if ((r = envid2env(envid, &e, 1)) < 0)
f010458a:	83 ec 04             	sub    $0x4,%esp
f010458d:	6a 01                	push   $0x1
f010458f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104592:	50                   	push   %eax
f0104593:	ff 75 0c             	pushl  0xc(%ebp)
f0104596:	e8 0f eb ff ff       	call   f01030aa <envid2env>
f010459b:	89 c3                	mov    %eax,%ebx
f010459d:	83 c4 10             	add    $0x10,%esp
f01045a0:	85 c0                	test   %eax,%eax
f01045a2:	78 9b                	js     f010453f <syscall+0x22>
	if (e == curenv)
f01045a4:	e8 dd 15 00 00       	call   f0105b86 <cpunum>
f01045a9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01045ac:	6b c0 74             	imul   $0x74,%eax,%eax
f01045af:	39 90 28 30 23 f0    	cmp    %edx,-0xfdccfd8(%eax)
f01045b5:	74 3d                	je     f01045f4 <syscall+0xd7>
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f01045b7:	8b 5a 48             	mov    0x48(%edx),%ebx
f01045ba:	e8 c7 15 00 00       	call   f0105b86 <cpunum>
f01045bf:	83 ec 04             	sub    $0x4,%esp
f01045c2:	53                   	push   %ebx
f01045c3:	6b c0 74             	imul   $0x74,%eax,%eax
f01045c6:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
f01045cc:	ff 70 48             	pushl  0x48(%eax)
f01045cf:	68 06 7a 10 f0       	push   $0xf0107a06
f01045d4:	e8 f4 f3 ff ff       	call   f01039cd <cprintf>
f01045d9:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01045dc:	83 ec 0c             	sub    $0xc,%esp
f01045df:	ff 75 e4             	pushl  -0x1c(%ebp)
f01045e2:	e8 c1 f0 ff ff       	call   f01036a8 <env_destroy>
	return 0;
f01045e7:	83 c4 10             	add    $0x10,%esp
f01045ea:	bb 00 00 00 00       	mov    $0x0,%ebx
			return sys_env_destroy((envid_t)a1);
f01045ef:	e9 4b ff ff ff       	jmp    f010453f <syscall+0x22>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f01045f4:	e8 8d 15 00 00       	call   f0105b86 <cpunum>
f01045f9:	83 ec 08             	sub    $0x8,%esp
f01045fc:	6b c0 74             	imul   $0x74,%eax,%eax
f01045ff:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
f0104605:	ff 70 48             	pushl  0x48(%eax)
f0104608:	68 eb 79 10 f0       	push   $0xf01079eb
f010460d:	e8 bb f3 ff ff       	call   f01039cd <cprintf>
f0104612:	83 c4 10             	add    $0x10,%esp
f0104615:	eb c5                	jmp    f01045dc <syscall+0xbf>
	return curenv->env_id;
f0104617:	e8 6a 15 00 00       	call   f0105b86 <cpunum>
f010461c:	6b c0 74             	imul   $0x74,%eax,%eax
f010461f:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
f0104625:	8b 58 48             	mov    0x48(%eax),%ebx
			return sys_getenvid();
f0104628:	e9 12 ff ff ff       	jmp    f010453f <syscall+0x22>
	sched_yield();
f010462d:	e8 33 fe ff ff       	call   f0104465 <sched_yield>
	struct Env* store_env = NULL;
f0104632:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = env_alloc(&store_env,curenv->env_id);
f0104639:	e8 48 15 00 00       	call   f0105b86 <cpunum>
f010463e:	83 ec 08             	sub    $0x8,%esp
f0104641:	6b c0 74             	imul   $0x74,%eax,%eax
f0104644:	8b 80 28 30 23 f0    	mov    -0xfdccfd8(%eax),%eax
f010464a:	ff 70 48             	pushl  0x48(%eax)
f010464d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104650:	50                   	push   %eax
f0104651:	e8 69 eb ff ff       	call   f01031bf <env_alloc>
f0104656:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f0104658:	83 c4 10             	add    $0x10,%esp
f010465b:	85 c0                	test   %eax,%eax
f010465d:	0f 88 dc fe ff ff    	js     f010453f <syscall+0x22>
	store_env->env_status = ENV_NOT_RUNNABLE;
f0104663:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104666:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	store_env->env_tf = curenv->env_tf;
f010466d:	e8 14 15 00 00       	call   f0105b86 <cpunum>
f0104672:	6b c0 74             	imul   $0x74,%eax,%eax
f0104675:	8b b0 28 30 23 f0    	mov    -0xfdccfd8(%eax),%esi
f010467b:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104680:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104683:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	store_env->env_tf.tf_regs.reg_eax = 0;
f0104685:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104688:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return store_env->env_id;
f010468f:	8b 58 48             	mov    0x48(%eax),%ebx
			return sys_exofork();
f0104692:	e9 a8 fe ff ff       	jmp    f010453f <syscall+0x22>
	if(status != ENV_NOT_RUNNABLE && status!= ENV_RUNNABLE)
f0104697:	8b 45 10             	mov    0x10(%ebp),%eax
f010469a:	83 e8 02             	sub    $0x2,%eax
f010469d:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f01046a2:	75 38                	jne    f01046dc <syscall+0x1bf>
	struct Env* e = NULL;
f01046a4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f01046ab:	83 ec 04             	sub    $0x4,%esp
f01046ae:	6a 01                	push   $0x1
f01046b0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01046b3:	50                   	push   %eax
f01046b4:	ff 75 0c             	pushl  0xc(%ebp)
f01046b7:	e8 ee e9 ff ff       	call   f01030aa <envid2env>
f01046bc:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f01046be:	83 c4 10             	add    $0x10,%esp
f01046c1:	85 c0                	test   %eax,%eax
f01046c3:	0f 88 76 fe ff ff    	js     f010453f <syscall+0x22>
	e->env_status = status;
f01046c9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01046cc:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01046cf:	89 48 54             	mov    %ecx,0x54(%eax)
	return 0;
f01046d2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01046d7:	e9 63 fe ff ff       	jmp    f010453f <syscall+0x22>
		return -E_INVAL;
f01046dc:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
			return sys_env_set_status((envid_t)a1,(int)a2);
f01046e1:	e9 59 fe ff ff       	jmp    f010453f <syscall+0x22>
	if((uintptr_t)va >= UTOP || (uintptr_t)va % PGSIZE)
f01046e6:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01046ed:	0f 87 84 00 00 00    	ja     f0104777 <syscall+0x25a>
	if((perm & ~(PTE_SYSCALL)) || ((perm & needed_perm) != needed_perm))
f01046f3:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01046f6:	81 e3 f8 f1 ff ff    	and    $0xfffff1f8,%ebx
	if((uintptr_t)va >= UTOP || (uintptr_t)va % PGSIZE)
f01046fc:	8b 45 10             	mov    0x10(%ebp),%eax
f01046ff:	25 ff 0f 00 00       	and    $0xfff,%eax
	if((perm & ~(PTE_SYSCALL)) || ((perm & needed_perm) != needed_perm))
f0104704:	09 c3                	or     %eax,%ebx
f0104706:	75 79                	jne    f0104781 <syscall+0x264>
f0104708:	8b 45 14             	mov    0x14(%ebp),%eax
f010470b:	83 e0 05             	and    $0x5,%eax
f010470e:	83 f8 05             	cmp    $0x5,%eax
f0104711:	75 78                	jne    f010478b <syscall+0x26e>
	struct Env* e = NULL;
f0104713:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f010471a:	83 ec 04             	sub    $0x4,%esp
f010471d:	6a 01                	push   $0x1
f010471f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104722:	50                   	push   %eax
f0104723:	ff 75 0c             	pushl  0xc(%ebp)
f0104726:	e8 7f e9 ff ff       	call   f01030aa <envid2env>
	if(ret<0)
f010472b:	83 c4 10             	add    $0x10,%esp
f010472e:	85 c0                	test   %eax,%eax
f0104730:	78 63                	js     f0104795 <syscall+0x278>
	struct PageInfo* pg = page_alloc(ALLOC_ZERO);
f0104732:	83 ec 0c             	sub    $0xc,%esp
f0104735:	6a 01                	push   $0x1
f0104737:	e8 3e c8 ff ff       	call   f0100f7a <page_alloc>
f010473c:	89 c6                	mov    %eax,%esi
	if(!pg)
f010473e:	83 c4 10             	add    $0x10,%esp
f0104741:	85 c0                	test   %eax,%eax
f0104743:	74 57                	je     f010479c <syscall+0x27f>
	ret = page_insert(e->env_pgdir,pg,va,perm);
f0104745:	ff 75 14             	pushl  0x14(%ebp)
f0104748:	ff 75 10             	pushl  0x10(%ebp)
f010474b:	50                   	push   %eax
f010474c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010474f:	ff 70 60             	pushl  0x60(%eax)
f0104752:	e8 d8 ca ff ff       	call   f010122f <page_insert>
f0104757:	89 c7                	mov    %eax,%edi
	if(ret < 0)
f0104759:	83 c4 10             	add    $0x10,%esp
f010475c:	85 c0                	test   %eax,%eax
f010475e:	0f 89 db fd ff ff    	jns    f010453f <syscall+0x22>
		page_free(pg);
f0104764:	83 ec 0c             	sub    $0xc,%esp
f0104767:	56                   	push   %esi
f0104768:	e8 86 c8 ff ff       	call   f0100ff3 <page_free>
		return ret;
f010476d:	83 c4 10             	add    $0x10,%esp
f0104770:	89 fb                	mov    %edi,%ebx
f0104772:	e9 c8 fd ff ff       	jmp    f010453f <syscall+0x22>
		return -E_INVAL;
f0104777:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010477c:	e9 be fd ff ff       	jmp    f010453f <syscall+0x22>
		return -E_INVAL;
f0104781:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104786:	e9 b4 fd ff ff       	jmp    f010453f <syscall+0x22>
f010478b:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104790:	e9 aa fd ff ff       	jmp    f010453f <syscall+0x22>
		return ret;
f0104795:	89 c3                	mov    %eax,%ebx
f0104797:	e9 a3 fd ff ff       	jmp    f010453f <syscall+0x22>
		return -E_NO_MEM;
f010479c:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
			return sys_page_alloc((envid_t)a1,(void*)a2,(int)a3);
f01047a1:	e9 99 fd ff ff       	jmp    f010453f <syscall+0x22>
	if((uintptr_t)srcva>=UTOP || (uintptr_t)srcva % PGSIZE 
f01047a6:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01047ad:	0f 87 d7 00 00 00    	ja     f010488a <syscall+0x36d>
	|| (uintptr_t)dstva>=UTOP || (uintptr_t)dstva % PGSIZE)
f01047b3:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f01047ba:	0f 87 d4 00 00 00    	ja     f0104894 <syscall+0x377>
	if((perm & ~(PTE_SYSCALL)) || ((perm & needed_perm) != needed_perm))
f01047c0:	8b 45 10             	mov    0x10(%ebp),%eax
f01047c3:	0b 45 18             	or     0x18(%ebp),%eax
f01047c6:	25 ff 0f 00 00       	and    $0xfff,%eax
f01047cb:	8b 55 1c             	mov    0x1c(%ebp),%edx
f01047ce:	81 e2 f8 f1 ff ff    	and    $0xfffff1f8,%edx
f01047d4:	09 d0                	or     %edx,%eax
f01047d6:	0f 85 c2 00 00 00    	jne    f010489e <syscall+0x381>
f01047dc:	8b 45 1c             	mov    0x1c(%ebp),%eax
f01047df:	83 e0 05             	and    $0x5,%eax
f01047e2:	83 f8 05             	cmp    $0x5,%eax
f01047e5:	0f 85 bd 00 00 00    	jne    f01048a8 <syscall+0x38b>
	struct Env* srce = NULL, *dste = NULL;
f01047eb:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01047f2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	int ret = envid2env(srcenvid,&srce,true);
f01047f9:	83 ec 04             	sub    $0x4,%esp
f01047fc:	6a 01                	push   $0x1
f01047fe:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0104801:	50                   	push   %eax
f0104802:	ff 75 0c             	pushl  0xc(%ebp)
f0104805:	e8 a0 e8 ff ff       	call   f01030aa <envid2env>
f010480a:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f010480c:	83 c4 10             	add    $0x10,%esp
f010480f:	85 c0                	test   %eax,%eax
f0104811:	0f 88 28 fd ff ff    	js     f010453f <syscall+0x22>
	ret = envid2env(dstenvid,&dste,true);
f0104817:	83 ec 04             	sub    $0x4,%esp
f010481a:	6a 01                	push   $0x1
f010481c:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010481f:	50                   	push   %eax
f0104820:	ff 75 14             	pushl  0x14(%ebp)
f0104823:	e8 82 e8 ff ff       	call   f01030aa <envid2env>
f0104828:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f010482a:	83 c4 10             	add    $0x10,%esp
f010482d:	85 c0                	test   %eax,%eax
f010482f:	0f 88 0a fd ff ff    	js     f010453f <syscall+0x22>
	pte_t* pte = NULL;
f0104835:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	struct PageInfo* pg = page_lookup(srce->env_pgdir,srcva,&pte);
f010483c:	83 ec 04             	sub    $0x4,%esp
f010483f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104842:	50                   	push   %eax
f0104843:	ff 75 10             	pushl  0x10(%ebp)
f0104846:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104849:	ff 70 60             	pushl  0x60(%eax)
f010484c:	e8 eb c8 ff ff       	call   f010113c <page_lookup>
	if(!pg)
f0104851:	83 c4 10             	add    $0x10,%esp
f0104854:	85 c0                	test   %eax,%eax
f0104856:	74 5a                	je     f01048b2 <syscall+0x395>
	if((!((*pte) & PTE_W)) && (perm & PTE_W))
f0104858:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010485b:	f6 02 02             	testb  $0x2,(%edx)
f010485e:	75 06                	jne    f0104866 <syscall+0x349>
f0104860:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104864:	75 56                	jne    f01048bc <syscall+0x39f>
	ret = page_insert(dste->env_pgdir,pg,dstva,perm);
f0104866:	ff 75 1c             	pushl  0x1c(%ebp)
f0104869:	ff 75 18             	pushl  0x18(%ebp)
f010486c:	50                   	push   %eax
f010486d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104870:	ff 70 60             	pushl  0x60(%eax)
f0104873:	e8 b7 c9 ff ff       	call   f010122f <page_insert>
f0104878:	83 c4 10             	add    $0x10,%esp
f010487b:	85 c0                	test   %eax,%eax
f010487d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104882:	0f 4e d8             	cmovle %eax,%ebx
f0104885:	e9 b5 fc ff ff       	jmp    f010453f <syscall+0x22>
		return -E_INVAL;
f010488a:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010488f:	e9 ab fc ff ff       	jmp    f010453f <syscall+0x22>
f0104894:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104899:	e9 a1 fc ff ff       	jmp    f010453f <syscall+0x22>
		return -E_INVAL;
f010489e:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01048a3:	e9 97 fc ff ff       	jmp    f010453f <syscall+0x22>
f01048a8:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01048ad:	e9 8d fc ff ff       	jmp    f010453f <syscall+0x22>
		return -E_INVAL;
f01048b2:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01048b7:	e9 83 fc ff ff       	jmp    f010453f <syscall+0x22>
		return -E_INVAL;
f01048bc:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
			return sys_page_map((envid_t)a1,(void*)a2,(envid_t)a3,(void*)a4,(int)a5);
f01048c1:	e9 79 fc ff ff       	jmp    f010453f <syscall+0x22>
	if((uintptr_t)va >= UTOP || (uintptr_t)va % PGSIZE)
f01048c6:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01048cd:	77 4c                	ja     f010491b <syscall+0x3fe>
f01048cf:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01048d6:	75 4d                	jne    f0104925 <syscall+0x408>
	struct Env* e = NULL;
f01048d8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int ret = envid2env(envid,&e,true);
f01048df:	83 ec 04             	sub    $0x4,%esp
f01048e2:	6a 01                	push   $0x1
f01048e4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01048e7:	50                   	push   %eax
f01048e8:	ff 75 0c             	pushl  0xc(%ebp)
f01048eb:	e8 ba e7 ff ff       	call   f01030aa <envid2env>
f01048f0:	89 c3                	mov    %eax,%ebx
	if(ret < 0)
f01048f2:	83 c4 10             	add    $0x10,%esp
f01048f5:	85 c0                	test   %eax,%eax
f01048f7:	0f 88 42 fc ff ff    	js     f010453f <syscall+0x22>
	page_remove(e->env_pgdir,va);
f01048fd:	83 ec 08             	sub    $0x8,%esp
f0104900:	ff 75 10             	pushl  0x10(%ebp)
f0104903:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104906:	ff 70 60             	pushl  0x60(%eax)
f0104909:	e8 d0 c8 ff ff       	call   f01011de <page_remove>
	return 0;
f010490e:	83 c4 10             	add    $0x10,%esp
f0104911:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104916:	e9 24 fc ff ff       	jmp    f010453f <syscall+0x22>
		return -E_INVAL;
f010491b:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104920:	e9 1a fc ff ff       	jmp    f010453f <syscall+0x22>
f0104925:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
			return sys_page_unmap((envid_t)a1,(void*)a2);
f010492a:	e9 10 fc ff ff       	jmp    f010453f <syscall+0x22>
			return 0;
f010492f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104934:	e9 06 fc ff ff       	jmp    f010453f <syscall+0x22>

f0104939 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104939:	55                   	push   %ebp
f010493a:	89 e5                	mov    %esp,%ebp
f010493c:	57                   	push   %edi
f010493d:	56                   	push   %esi
f010493e:	53                   	push   %ebx
f010493f:	83 ec 14             	sub    $0x14,%esp
f0104942:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104945:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104948:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010494b:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f010494e:	8b 1a                	mov    (%edx),%ebx
f0104950:	8b 01                	mov    (%ecx),%eax
f0104952:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104955:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010495c:	eb 23                	jmp    f0104981 <stab_binsearch+0x48>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010495e:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0104961:	eb 1e                	jmp    f0104981 <stab_binsearch+0x48>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104963:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104966:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104969:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010496d:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104970:	73 46                	jae    f01049b8 <stab_binsearch+0x7f>
			*region_left = m;
f0104972:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104975:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104977:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f010497a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0104981:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104984:	7f 5f                	jg     f01049e5 <stab_binsearch+0xac>
		int true_m = (l + r) / 2, m = true_m;
f0104986:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104989:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f010498c:	89 d0                	mov    %edx,%eax
f010498e:	c1 e8 1f             	shr    $0x1f,%eax
f0104991:	01 d0                	add    %edx,%eax
f0104993:	89 c7                	mov    %eax,%edi
f0104995:	d1 ff                	sar    %edi
f0104997:	83 e0 fe             	and    $0xfffffffe,%eax
f010499a:	01 f8                	add    %edi,%eax
f010499c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010499f:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01049a3:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f01049a5:	39 c3                	cmp    %eax,%ebx
f01049a7:	7f b5                	jg     f010495e <stab_binsearch+0x25>
f01049a9:	0f b6 0a             	movzbl (%edx),%ecx
f01049ac:	83 ea 0c             	sub    $0xc,%edx
f01049af:	39 f1                	cmp    %esi,%ecx
f01049b1:	74 b0                	je     f0104963 <stab_binsearch+0x2a>
			m--;
f01049b3:	83 e8 01             	sub    $0x1,%eax
f01049b6:	eb ed                	jmp    f01049a5 <stab_binsearch+0x6c>
		} else if (stabs[m].n_value > addr) {
f01049b8:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01049bb:	76 14                	jbe    f01049d1 <stab_binsearch+0x98>
			*region_right = m - 1;
f01049bd:	83 e8 01             	sub    $0x1,%eax
f01049c0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01049c3:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01049c6:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f01049c8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01049cf:	eb b0                	jmp    f0104981 <stab_binsearch+0x48>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01049d1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01049d4:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f01049d6:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01049da:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f01049dc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01049e3:	eb 9c                	jmp    f0104981 <stab_binsearch+0x48>
		}
	}

	if (!any_matches)
f01049e5:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01049e9:	75 15                	jne    f0104a00 <stab_binsearch+0xc7>
		*region_right = *region_left - 1;
f01049eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01049ee:	8b 00                	mov    (%eax),%eax
f01049f0:	83 e8 01             	sub    $0x1,%eax
f01049f3:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01049f6:	89 07                	mov    %eax,(%edi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f01049f8:	83 c4 14             	add    $0x14,%esp
f01049fb:	5b                   	pop    %ebx
f01049fc:	5e                   	pop    %esi
f01049fd:	5f                   	pop    %edi
f01049fe:	5d                   	pop    %ebp
f01049ff:	c3                   	ret    
		for (l = *region_right;
f0104a00:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104a03:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104a05:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104a08:	8b 0f                	mov    (%edi),%ecx
f0104a0a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104a0d:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0104a10:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
		for (l = *region_right;
f0104a14:	eb 03                	jmp    f0104a19 <stab_binsearch+0xe0>
		     l--)
f0104a16:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0104a19:	39 c1                	cmp    %eax,%ecx
f0104a1b:	7d 0a                	jge    f0104a27 <stab_binsearch+0xee>
		     l > *region_left && stabs[l].n_type != type;
f0104a1d:	0f b6 1a             	movzbl (%edx),%ebx
f0104a20:	83 ea 0c             	sub    $0xc,%edx
f0104a23:	39 f3                	cmp    %esi,%ebx
f0104a25:	75 ef                	jne    f0104a16 <stab_binsearch+0xdd>
		*region_left = l;
f0104a27:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104a2a:	89 07                	mov    %eax,(%edi)
}
f0104a2c:	eb ca                	jmp    f01049f8 <stab_binsearch+0xbf>

f0104a2e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104a2e:	f3 0f 1e fb          	endbr32 
f0104a32:	55                   	push   %ebp
f0104a33:	89 e5                	mov    %esp,%ebp
f0104a35:	57                   	push   %edi
f0104a36:	56                   	push   %esi
f0104a37:	53                   	push   %ebx
f0104a38:	83 ec 4c             	sub    $0x4c,%esp
f0104a3b:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104a3e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104a41:	c7 03 58 7a 10 f0    	movl   $0xf0107a58,(%ebx)
	info->eip_line = 0;
f0104a47:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0104a4e:	c7 43 08 58 7a 10 f0 	movl   $0xf0107a58,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0104a55:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0104a5c:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0104a5f:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104a66:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0104a6c:	0f 86 32 01 00 00    	jbe    f0104ba4 <debuginfo_eip+0x176>
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104a72:	c7 45 b4 dc 7d 11 f0 	movl   $0xf0117ddc,-0x4c(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0104a79:	c7 45 b8 3d 46 11 f0 	movl   $0xf011463d,-0x48(%ebp)
		stab_end = __STAB_END__;
f0104a80:	be 3c 46 11 f0       	mov    $0xf011463c,%esi
		stabs = __STAB_BEGIN__;
f0104a85:	c7 45 bc 34 7f 10 f0 	movl   $0xf0107f34,-0x44(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104a8c:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f0104a8f:	39 4d b8             	cmp    %ecx,-0x48(%ebp)
f0104a92:	0f 83 62 02 00 00    	jae    f0104cfa <debuginfo_eip+0x2cc>
f0104a98:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0104a9c:	0f 85 5f 02 00 00    	jne    f0104d01 <debuginfo_eip+0x2d3>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104aa2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104aa9:	2b 75 bc             	sub    -0x44(%ebp),%esi
f0104aac:	c1 fe 02             	sar    $0x2,%esi
f0104aaf:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0104ab5:	83 e8 01             	sub    $0x1,%eax
f0104ab8:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104abb:	83 ec 08             	sub    $0x8,%esp
f0104abe:	57                   	push   %edi
f0104abf:	6a 64                	push   $0x64
f0104ac1:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0104ac4:	89 d1                	mov    %edx,%ecx
f0104ac6:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104ac9:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0104acc:	89 f0                	mov    %esi,%eax
f0104ace:	e8 66 fe ff ff       	call   f0104939 <stab_binsearch>
	if (lfile == 0)
f0104ad3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104ad6:	83 c4 10             	add    $0x10,%esp
f0104ad9:	85 c0                	test   %eax,%eax
f0104adb:	0f 84 27 02 00 00    	je     f0104d08 <debuginfo_eip+0x2da>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104ae1:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104ae4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104ae7:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104aea:	83 ec 08             	sub    $0x8,%esp
f0104aed:	57                   	push   %edi
f0104aee:	6a 24                	push   $0x24
f0104af0:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0104af3:	89 d1                	mov    %edx,%ecx
f0104af5:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104af8:	89 f0                	mov    %esi,%eax
f0104afa:	e8 3a fe ff ff       	call   f0104939 <stab_binsearch>

	if (lfun <= rfun) {
f0104aff:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104b02:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104b05:	83 c4 10             	add    $0x10,%esp
f0104b08:	39 d0                	cmp    %edx,%eax
f0104b0a:	0f 8f 34 01 00 00    	jg     f0104c44 <debuginfo_eip+0x216>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104b10:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0104b13:	8d 34 8e             	lea    (%esi,%ecx,4),%esi
f0104b16:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f0104b19:	8b 36                	mov    (%esi),%esi
f0104b1b:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f0104b1e:	2b 4d b8             	sub    -0x48(%ebp),%ecx
f0104b21:	39 ce                	cmp    %ecx,%esi
f0104b23:	73 06                	jae    f0104b2b <debuginfo_eip+0xfd>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104b25:	03 75 b8             	add    -0x48(%ebp),%esi
f0104b28:	89 73 08             	mov    %esi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104b2b:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104b2e:	8b 4e 08             	mov    0x8(%esi),%ecx
f0104b31:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0104b34:	29 cf                	sub    %ecx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0104b36:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104b39:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104b3c:	83 ec 08             	sub    $0x8,%esp
f0104b3f:	6a 3a                	push   $0x3a
f0104b41:	ff 73 08             	pushl  0x8(%ebx)
f0104b44:	e8 fe 09 00 00       	call   f0105547 <strfind>
f0104b49:	2b 43 08             	sub    0x8(%ebx),%eax
f0104b4c:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	info->eip_file = stabstr +stabs[lfile].n_strx;
f0104b4f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104b52:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104b55:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0104b58:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0104b5b:	03 0c 86             	add    (%esi,%eax,4),%ecx
f0104b5e:	89 0b                	mov    %ecx,(%ebx)
	stab_binsearch(stabs, &lline, &rline,N_SLINE,addr);
f0104b60:	83 c4 08             	add    $0x8,%esp
f0104b63:	57                   	push   %edi
f0104b64:	6a 44                	push   $0x44
f0104b66:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104b69:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104b6c:	89 f0                	mov    %esi,%eax
f0104b6e:	e8 c6 fd ff ff       	call   f0104939 <stab_binsearch>
	if(lline>rline)
f0104b73:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0104b76:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104b79:	83 c4 10             	add    $0x10,%esp
f0104b7c:	39 c2                	cmp    %eax,%edx
f0104b7e:	0f 8f 8b 01 00 00    	jg     f0104d0f <debuginfo_eip+0x2e1>
	{
		return -1;
	}
	else
	{
		info->eip_line = stabs[rline].n_desc;
f0104b84:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104b87:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0104b8c:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104b8f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104b92:	89 d0                	mov    %edx,%eax
f0104b94:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104b97:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
f0104b9b:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0104b9f:	e9 be 00 00 00       	jmp    f0104c62 <debuginfo_eip+0x234>
		if(user_mem_check(curenv,usd,sizeof(struct UserStabData),PTE_P|PTE_U) != 0)
f0104ba4:	e8 dd 0f 00 00       	call   f0105b86 <cpunum>
f0104ba9:	6a 05                	push   $0x5
f0104bab:	6a 10                	push   $0x10
f0104bad:	68 00 00 20 00       	push   $0x200000
f0104bb2:	6b c0 74             	imul   $0x74,%eax,%eax
f0104bb5:	ff b0 28 30 23 f0    	pushl  -0xfdccfd8(%eax)
f0104bbb:	e8 6a e3 ff ff       	call   f0102f2a <user_mem_check>
f0104bc0:	83 c4 10             	add    $0x10,%esp
f0104bc3:	85 c0                	test   %eax,%eax
f0104bc5:	0f 85 21 01 00 00    	jne    f0104cec <debuginfo_eip+0x2be>
		stabs = usd->stabs;
f0104bcb:	a1 00 00 20 00       	mov    0x200000,%eax
f0104bd0:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stab_end = usd->stab_end;
f0104bd3:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f0104bd9:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f0104bdf:	89 4d b8             	mov    %ecx,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f0104be2:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0104be8:	89 55 b4             	mov    %edx,-0x4c(%ebp)
		if(user_mem_check(curenv,stabs,sizeof(struct Stab),PTE_P|PTE_U) != 0)
f0104beb:	e8 96 0f 00 00       	call   f0105b86 <cpunum>
f0104bf0:	6a 05                	push   $0x5
f0104bf2:	6a 0c                	push   $0xc
f0104bf4:	ff 75 bc             	pushl  -0x44(%ebp)
f0104bf7:	6b c0 74             	imul   $0x74,%eax,%eax
f0104bfa:	ff b0 28 30 23 f0    	pushl  -0xfdccfd8(%eax)
f0104c00:	e8 25 e3 ff ff       	call   f0102f2a <user_mem_check>
f0104c05:	83 c4 10             	add    $0x10,%esp
f0104c08:	85 c0                	test   %eax,%eax
f0104c0a:	0f 85 e3 00 00 00    	jne    f0104cf3 <debuginfo_eip+0x2c5>
		if(user_mem_check(curenv,stabstr,stabstr_end-stabstr,PTE_P|PTE_U) != 0)
f0104c10:	e8 71 0f 00 00       	call   f0105b86 <cpunum>
f0104c15:	6a 05                	push   $0x5
f0104c17:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f0104c1a:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0104c1d:	29 ca                	sub    %ecx,%edx
f0104c1f:	52                   	push   %edx
f0104c20:	51                   	push   %ecx
f0104c21:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c24:	ff b0 28 30 23 f0    	pushl  -0xfdccfd8(%eax)
f0104c2a:	e8 fb e2 ff ff       	call   f0102f2a <user_mem_check>
f0104c2f:	83 c4 10             	add    $0x10,%esp
f0104c32:	85 c0                	test   %eax,%eax
f0104c34:	0f 84 52 fe ff ff    	je     f0104a8c <debuginfo_eip+0x5e>
			return -1;
f0104c3a:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104c3f:	e9 d7 00 00 00       	jmp    f0104d1b <debuginfo_eip+0x2ed>
		info->eip_fn_addr = addr;
f0104c44:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f0104c47:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104c4a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104c4d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104c50:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104c53:	e9 e4 fe ff ff       	jmp    f0104b3c <debuginfo_eip+0x10e>
f0104c58:	83 e8 01             	sub    $0x1,%eax
f0104c5b:	83 ea 0c             	sub    $0xc,%edx
	while (lline >= lfile
f0104c5e:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0104c62:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0104c65:	39 c7                	cmp    %eax,%edi
f0104c67:	7f 43                	jg     f0104cac <debuginfo_eip+0x27e>
	       && stabs[lline].n_type != N_SOL
f0104c69:	0f b6 0a             	movzbl (%edx),%ecx
f0104c6c:	80 f9 84             	cmp    $0x84,%cl
f0104c6f:	74 19                	je     f0104c8a <debuginfo_eip+0x25c>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104c71:	80 f9 64             	cmp    $0x64,%cl
f0104c74:	75 e2                	jne    f0104c58 <debuginfo_eip+0x22a>
f0104c76:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0104c7a:	74 dc                	je     f0104c58 <debuginfo_eip+0x22a>
f0104c7c:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104c80:	74 11                	je     f0104c93 <debuginfo_eip+0x265>
f0104c82:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104c85:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104c88:	eb 09                	jmp    f0104c93 <debuginfo_eip+0x265>
f0104c8a:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104c8e:	74 03                	je     f0104c93 <debuginfo_eip+0x265>
f0104c90:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104c93:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104c96:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0104c99:	8b 04 87             	mov    (%edi,%eax,4),%eax
f0104c9c:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f0104c9f:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0104ca2:	29 fa                	sub    %edi,%edx
f0104ca4:	39 d0                	cmp    %edx,%eax
f0104ca6:	73 04                	jae    f0104cac <debuginfo_eip+0x27e>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104ca8:	01 f8                	add    %edi,%eax
f0104caa:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104cac:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104caf:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104cb2:	ba 00 00 00 00       	mov    $0x0,%edx
	if (lfun < rfun)
f0104cb7:	39 f0                	cmp    %esi,%eax
f0104cb9:	7d 60                	jge    f0104d1b <debuginfo_eip+0x2ed>
		for (lline = lfun + 1;
f0104cbb:	8d 50 01             	lea    0x1(%eax),%edx
f0104cbe:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104cc1:	89 d0                	mov    %edx,%eax
f0104cc3:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104cc6:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0104cc9:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
f0104ccd:	eb 04                	jmp    f0104cd3 <debuginfo_eip+0x2a5>
			info->eip_fn_narg++;
f0104ccf:	83 43 14 01          	addl   $0x1,0x14(%ebx)
		for (lline = lfun + 1;
f0104cd3:	39 c6                	cmp    %eax,%esi
f0104cd5:	7e 3f                	jle    f0104d16 <debuginfo_eip+0x2e8>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104cd7:	0f b6 0a             	movzbl (%edx),%ecx
f0104cda:	83 c0 01             	add    $0x1,%eax
f0104cdd:	83 c2 0c             	add    $0xc,%edx
f0104ce0:	80 f9 a0             	cmp    $0xa0,%cl
f0104ce3:	74 ea                	je     f0104ccf <debuginfo_eip+0x2a1>
	return 0;
f0104ce5:	ba 00 00 00 00       	mov    $0x0,%edx
f0104cea:	eb 2f                	jmp    f0104d1b <debuginfo_eip+0x2ed>
			return -1;
f0104cec:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104cf1:	eb 28                	jmp    f0104d1b <debuginfo_eip+0x2ed>
			return -1;
f0104cf3:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104cf8:	eb 21                	jmp    f0104d1b <debuginfo_eip+0x2ed>
		return -1;
f0104cfa:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104cff:	eb 1a                	jmp    f0104d1b <debuginfo_eip+0x2ed>
f0104d01:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104d06:	eb 13                	jmp    f0104d1b <debuginfo_eip+0x2ed>
		return -1;
f0104d08:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104d0d:	eb 0c                	jmp    f0104d1b <debuginfo_eip+0x2ed>
		return -1;
f0104d0f:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0104d14:	eb 05                	jmp    f0104d1b <debuginfo_eip+0x2ed>
	return 0;
f0104d16:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104d1b:	89 d0                	mov    %edx,%eax
f0104d1d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104d20:	5b                   	pop    %ebx
f0104d21:	5e                   	pop    %esi
f0104d22:	5f                   	pop    %edi
f0104d23:	5d                   	pop    %ebp
f0104d24:	c3                   	ret    

f0104d25 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104d25:	55                   	push   %ebp
f0104d26:	89 e5                	mov    %esp,%ebp
f0104d28:	57                   	push   %edi
f0104d29:	56                   	push   %esi
f0104d2a:	53                   	push   %ebx
f0104d2b:	83 ec 1c             	sub    $0x1c,%esp
f0104d2e:	89 c7                	mov    %eax,%edi
f0104d30:	89 d6                	mov    %edx,%esi
f0104d32:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d35:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104d38:	89 d1                	mov    %edx,%ecx
f0104d3a:	89 c2                	mov    %eax,%edx
f0104d3c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104d3f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104d42:	8b 45 10             	mov    0x10(%ebp),%eax
f0104d45:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104d48:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104d4b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0104d52:	39 c2                	cmp    %eax,%edx
f0104d54:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f0104d57:	72 3e                	jb     f0104d97 <printnum+0x72>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104d59:	83 ec 0c             	sub    $0xc,%esp
f0104d5c:	ff 75 18             	pushl  0x18(%ebp)
f0104d5f:	83 eb 01             	sub    $0x1,%ebx
f0104d62:	53                   	push   %ebx
f0104d63:	50                   	push   %eax
f0104d64:	83 ec 08             	sub    $0x8,%esp
f0104d67:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104d6a:	ff 75 e0             	pushl  -0x20(%ebp)
f0104d6d:	ff 75 dc             	pushl  -0x24(%ebp)
f0104d70:	ff 75 d8             	pushl  -0x28(%ebp)
f0104d73:	e8 28 12 00 00       	call   f0105fa0 <__udivdi3>
f0104d78:	83 c4 18             	add    $0x18,%esp
f0104d7b:	52                   	push   %edx
f0104d7c:	50                   	push   %eax
f0104d7d:	89 f2                	mov    %esi,%edx
f0104d7f:	89 f8                	mov    %edi,%eax
f0104d81:	e8 9f ff ff ff       	call   f0104d25 <printnum>
f0104d86:	83 c4 20             	add    $0x20,%esp
f0104d89:	eb 13                	jmp    f0104d9e <printnum+0x79>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104d8b:	83 ec 08             	sub    $0x8,%esp
f0104d8e:	56                   	push   %esi
f0104d8f:	ff 75 18             	pushl  0x18(%ebp)
f0104d92:	ff d7                	call   *%edi
f0104d94:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0104d97:	83 eb 01             	sub    $0x1,%ebx
f0104d9a:	85 db                	test   %ebx,%ebx
f0104d9c:	7f ed                	jg     f0104d8b <printnum+0x66>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104d9e:	83 ec 08             	sub    $0x8,%esp
f0104da1:	56                   	push   %esi
f0104da2:	83 ec 04             	sub    $0x4,%esp
f0104da5:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104da8:	ff 75 e0             	pushl  -0x20(%ebp)
f0104dab:	ff 75 dc             	pushl  -0x24(%ebp)
f0104dae:	ff 75 d8             	pushl  -0x28(%ebp)
f0104db1:	e8 fa 12 00 00       	call   f01060b0 <__umoddi3>
f0104db6:	83 c4 14             	add    $0x14,%esp
f0104db9:	0f be 80 62 7a 10 f0 	movsbl -0xfef859e(%eax),%eax
f0104dc0:	50                   	push   %eax
f0104dc1:	ff d7                	call   *%edi
}
f0104dc3:	83 c4 10             	add    $0x10,%esp
f0104dc6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104dc9:	5b                   	pop    %ebx
f0104dca:	5e                   	pop    %esi
f0104dcb:	5f                   	pop    %edi
f0104dcc:	5d                   	pop    %ebp
f0104dcd:	c3                   	ret    

f0104dce <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104dce:	f3 0f 1e fb          	endbr32 
f0104dd2:	55                   	push   %ebp
f0104dd3:	89 e5                	mov    %esp,%ebp
f0104dd5:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104dd8:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104ddc:	8b 10                	mov    (%eax),%edx
f0104dde:	3b 50 04             	cmp    0x4(%eax),%edx
f0104de1:	73 0a                	jae    f0104ded <sprintputch+0x1f>
		*b->buf++ = ch;
f0104de3:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104de6:	89 08                	mov    %ecx,(%eax)
f0104de8:	8b 45 08             	mov    0x8(%ebp),%eax
f0104deb:	88 02                	mov    %al,(%edx)
}
f0104ded:	5d                   	pop    %ebp
f0104dee:	c3                   	ret    

f0104def <printfmt>:
{
f0104def:	f3 0f 1e fb          	endbr32 
f0104df3:	55                   	push   %ebp
f0104df4:	89 e5                	mov    %esp,%ebp
f0104df6:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0104df9:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104dfc:	50                   	push   %eax
f0104dfd:	ff 75 10             	pushl  0x10(%ebp)
f0104e00:	ff 75 0c             	pushl  0xc(%ebp)
f0104e03:	ff 75 08             	pushl  0x8(%ebp)
f0104e06:	e8 05 00 00 00       	call   f0104e10 <vprintfmt>
}
f0104e0b:	83 c4 10             	add    $0x10,%esp
f0104e0e:	c9                   	leave  
f0104e0f:	c3                   	ret    

f0104e10 <vprintfmt>:
{
f0104e10:	f3 0f 1e fb          	endbr32 
f0104e14:	55                   	push   %ebp
f0104e15:	89 e5                	mov    %esp,%ebp
f0104e17:	57                   	push   %edi
f0104e18:	56                   	push   %esi
f0104e19:	53                   	push   %ebx
f0104e1a:	83 ec 3c             	sub    $0x3c,%esp
f0104e1d:	8b 75 08             	mov    0x8(%ebp),%esi
f0104e20:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104e23:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104e26:	e9 8e 03 00 00       	jmp    f01051b9 <vprintfmt+0x3a9>
		padc = ' ';
f0104e2b:	c6 45 d3 20          	movb   $0x20,-0x2d(%ebp)
		altflag = 0;
f0104e2f:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
		precision = -1;
f0104e36:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f0104e3d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0104e44:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0104e49:	8d 47 01             	lea    0x1(%edi),%eax
f0104e4c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104e4f:	0f b6 17             	movzbl (%edi),%edx
f0104e52:	8d 42 dd             	lea    -0x23(%edx),%eax
f0104e55:	3c 55                	cmp    $0x55,%al
f0104e57:	0f 87 df 03 00 00    	ja     f010523c <vprintfmt+0x42c>
f0104e5d:	0f b6 c0             	movzbl %al,%eax
f0104e60:	3e ff 24 85 20 7b 10 	notrack jmp *-0xfef84e0(,%eax,4)
f0104e67:	f0 
f0104e68:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0104e6b:	c6 45 d3 2d          	movb   $0x2d,-0x2d(%ebp)
f0104e6f:	eb d8                	jmp    f0104e49 <vprintfmt+0x39>
		switch (ch = *(unsigned char *) fmt++) {
f0104e71:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104e74:	c6 45 d3 30          	movb   $0x30,-0x2d(%ebp)
f0104e78:	eb cf                	jmp    f0104e49 <vprintfmt+0x39>
f0104e7a:	0f b6 d2             	movzbl %dl,%edx
f0104e7d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0104e80:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e85:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f0104e88:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104e8b:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0104e8f:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0104e92:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0104e95:	83 f9 09             	cmp    $0x9,%ecx
f0104e98:	77 55                	ja     f0104eef <vprintfmt+0xdf>
			for (precision = 0; ; ++fmt) {
f0104e9a:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0104e9d:	eb e9                	jmp    f0104e88 <vprintfmt+0x78>
			precision = va_arg(ap, int);
f0104e9f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ea2:	8b 00                	mov    (%eax),%eax
f0104ea4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104ea7:	8b 45 14             	mov    0x14(%ebp),%eax
f0104eaa:	8d 40 04             	lea    0x4(%eax),%eax
f0104ead:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104eb0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0104eb3:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104eb7:	79 90                	jns    f0104e49 <vprintfmt+0x39>
				width = precision, precision = -1;
f0104eb9:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104ebc:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104ebf:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0104ec6:	eb 81                	jmp    f0104e49 <vprintfmt+0x39>
f0104ec8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104ecb:	85 c0                	test   %eax,%eax
f0104ecd:	ba 00 00 00 00       	mov    $0x0,%edx
f0104ed2:	0f 49 d0             	cmovns %eax,%edx
f0104ed5:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104ed8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0104edb:	e9 69 ff ff ff       	jmp    f0104e49 <vprintfmt+0x39>
		switch (ch = *(unsigned char *) fmt++) {
f0104ee0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0104ee3:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
			goto reswitch;
f0104eea:	e9 5a ff ff ff       	jmp    f0104e49 <vprintfmt+0x39>
f0104eef:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0104ef2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104ef5:	eb bc                	jmp    f0104eb3 <vprintfmt+0xa3>
			lflag++;
f0104ef7:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0104efa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0104efd:	e9 47 ff ff ff       	jmp    f0104e49 <vprintfmt+0x39>
			putch(va_arg(ap, int), putdat);
f0104f02:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f05:	8d 78 04             	lea    0x4(%eax),%edi
f0104f08:	83 ec 08             	sub    $0x8,%esp
f0104f0b:	53                   	push   %ebx
f0104f0c:	ff 30                	pushl  (%eax)
f0104f0e:	ff d6                	call   *%esi
			break;
f0104f10:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0104f13:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0104f16:	e9 9b 02 00 00       	jmp    f01051b6 <vprintfmt+0x3a6>
			err = va_arg(ap, int);
f0104f1b:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f1e:	8d 78 04             	lea    0x4(%eax),%edi
f0104f21:	8b 00                	mov    (%eax),%eax
f0104f23:	99                   	cltd   
f0104f24:	31 d0                	xor    %edx,%eax
f0104f26:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104f28:	83 f8 08             	cmp    $0x8,%eax
f0104f2b:	7f 23                	jg     f0104f50 <vprintfmt+0x140>
f0104f2d:	8b 14 85 80 7c 10 f0 	mov    -0xfef8380(,%eax,4),%edx
f0104f34:	85 d2                	test   %edx,%edx
f0104f36:	74 18                	je     f0104f50 <vprintfmt+0x140>
				printfmt(putch, putdat, "%s", p);
f0104f38:	52                   	push   %edx
f0104f39:	68 95 71 10 f0       	push   $0xf0107195
f0104f3e:	53                   	push   %ebx
f0104f3f:	56                   	push   %esi
f0104f40:	e8 aa fe ff ff       	call   f0104def <printfmt>
f0104f45:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0104f48:	89 7d 14             	mov    %edi,0x14(%ebp)
f0104f4b:	e9 66 02 00 00       	jmp    f01051b6 <vprintfmt+0x3a6>
				printfmt(putch, putdat, "error %d", err);
f0104f50:	50                   	push   %eax
f0104f51:	68 7a 7a 10 f0       	push   $0xf0107a7a
f0104f56:	53                   	push   %ebx
f0104f57:	56                   	push   %esi
f0104f58:	e8 92 fe ff ff       	call   f0104def <printfmt>
f0104f5d:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0104f60:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0104f63:	e9 4e 02 00 00       	jmp    f01051b6 <vprintfmt+0x3a6>
			if ((p = va_arg(ap, char *)) == NULL)
f0104f68:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f6b:	83 c0 04             	add    $0x4,%eax
f0104f6e:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0104f71:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f74:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f0104f76:	85 d2                	test   %edx,%edx
f0104f78:	b8 73 7a 10 f0       	mov    $0xf0107a73,%eax
f0104f7d:	0f 45 c2             	cmovne %edx,%eax
f0104f80:	89 45 cc             	mov    %eax,-0x34(%ebp)
			if (width > 0 && padc != '-')
f0104f83:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104f87:	7e 06                	jle    f0104f8f <vprintfmt+0x17f>
f0104f89:	80 7d d3 2d          	cmpb   $0x2d,-0x2d(%ebp)
f0104f8d:	75 0d                	jne    f0104f9c <vprintfmt+0x18c>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104f8f:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0104f92:	89 c7                	mov    %eax,%edi
f0104f94:	03 45 e0             	add    -0x20(%ebp),%eax
f0104f97:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104f9a:	eb 55                	jmp    f0104ff1 <vprintfmt+0x1e1>
f0104f9c:	83 ec 08             	sub    $0x8,%esp
f0104f9f:	ff 75 d8             	pushl  -0x28(%ebp)
f0104fa2:	ff 75 cc             	pushl  -0x34(%ebp)
f0104fa5:	e8 2c 04 00 00       	call   f01053d6 <strnlen>
f0104faa:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0104fad:	29 c2                	sub    %eax,%edx
f0104faf:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0104fb2:	83 c4 10             	add    $0x10,%esp
f0104fb5:	89 d7                	mov    %edx,%edi
					putch(padc, putdat);
f0104fb7:	0f be 45 d3          	movsbl -0x2d(%ebp),%eax
f0104fbb:	89 45 e0             	mov    %eax,-0x20(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0104fbe:	85 ff                	test   %edi,%edi
f0104fc0:	7e 11                	jle    f0104fd3 <vprintfmt+0x1c3>
					putch(padc, putdat);
f0104fc2:	83 ec 08             	sub    $0x8,%esp
f0104fc5:	53                   	push   %ebx
f0104fc6:	ff 75 e0             	pushl  -0x20(%ebp)
f0104fc9:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0104fcb:	83 ef 01             	sub    $0x1,%edi
f0104fce:	83 c4 10             	add    $0x10,%esp
f0104fd1:	eb eb                	jmp    f0104fbe <vprintfmt+0x1ae>
f0104fd3:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0104fd6:	85 d2                	test   %edx,%edx
f0104fd8:	b8 00 00 00 00       	mov    $0x0,%eax
f0104fdd:	0f 49 c2             	cmovns %edx,%eax
f0104fe0:	29 c2                	sub    %eax,%edx
f0104fe2:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0104fe5:	eb a8                	jmp    f0104f8f <vprintfmt+0x17f>
					putch(ch, putdat);
f0104fe7:	83 ec 08             	sub    $0x8,%esp
f0104fea:	53                   	push   %ebx
f0104feb:	52                   	push   %edx
f0104fec:	ff d6                	call   *%esi
f0104fee:	83 c4 10             	add    $0x10,%esp
f0104ff1:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104ff4:	29 f9                	sub    %edi,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104ff6:	83 c7 01             	add    $0x1,%edi
f0104ff9:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104ffd:	0f be d0             	movsbl %al,%edx
f0105000:	85 d2                	test   %edx,%edx
f0105002:	74 4b                	je     f010504f <vprintfmt+0x23f>
f0105004:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0105008:	78 06                	js     f0105010 <vprintfmt+0x200>
f010500a:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f010500e:	78 1e                	js     f010502e <vprintfmt+0x21e>
				if (altflag && (ch < ' ' || ch > '~'))
f0105010:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0105014:	74 d1                	je     f0104fe7 <vprintfmt+0x1d7>
f0105016:	0f be c0             	movsbl %al,%eax
f0105019:	83 e8 20             	sub    $0x20,%eax
f010501c:	83 f8 5e             	cmp    $0x5e,%eax
f010501f:	76 c6                	jbe    f0104fe7 <vprintfmt+0x1d7>
					putch('?', putdat);
f0105021:	83 ec 08             	sub    $0x8,%esp
f0105024:	53                   	push   %ebx
f0105025:	6a 3f                	push   $0x3f
f0105027:	ff d6                	call   *%esi
f0105029:	83 c4 10             	add    $0x10,%esp
f010502c:	eb c3                	jmp    f0104ff1 <vprintfmt+0x1e1>
f010502e:	89 cf                	mov    %ecx,%edi
f0105030:	eb 0e                	jmp    f0105040 <vprintfmt+0x230>
				putch(' ', putdat);
f0105032:	83 ec 08             	sub    $0x8,%esp
f0105035:	53                   	push   %ebx
f0105036:	6a 20                	push   $0x20
f0105038:	ff d6                	call   *%esi
			for (; width > 0; width--)
f010503a:	83 ef 01             	sub    $0x1,%edi
f010503d:	83 c4 10             	add    $0x10,%esp
f0105040:	85 ff                	test   %edi,%edi
f0105042:	7f ee                	jg     f0105032 <vprintfmt+0x222>
			if ((p = va_arg(ap, char *)) == NULL)
f0105044:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0105047:	89 45 14             	mov    %eax,0x14(%ebp)
f010504a:	e9 67 01 00 00       	jmp    f01051b6 <vprintfmt+0x3a6>
f010504f:	89 cf                	mov    %ecx,%edi
f0105051:	eb ed                	jmp    f0105040 <vprintfmt+0x230>
	if (lflag >= 2)
f0105053:	83 f9 01             	cmp    $0x1,%ecx
f0105056:	7f 1b                	jg     f0105073 <vprintfmt+0x263>
	else if (lflag)
f0105058:	85 c9                	test   %ecx,%ecx
f010505a:	74 63                	je     f01050bf <vprintfmt+0x2af>
		return va_arg(*ap, long);
f010505c:	8b 45 14             	mov    0x14(%ebp),%eax
f010505f:	8b 00                	mov    (%eax),%eax
f0105061:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105064:	99                   	cltd   
f0105065:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105068:	8b 45 14             	mov    0x14(%ebp),%eax
f010506b:	8d 40 04             	lea    0x4(%eax),%eax
f010506e:	89 45 14             	mov    %eax,0x14(%ebp)
f0105071:	eb 17                	jmp    f010508a <vprintfmt+0x27a>
		return va_arg(*ap, long long);
f0105073:	8b 45 14             	mov    0x14(%ebp),%eax
f0105076:	8b 50 04             	mov    0x4(%eax),%edx
f0105079:	8b 00                	mov    (%eax),%eax
f010507b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010507e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105081:	8b 45 14             	mov    0x14(%ebp),%eax
f0105084:	8d 40 08             	lea    0x8(%eax),%eax
f0105087:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f010508a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010508d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0105090:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f0105095:	85 c9                	test   %ecx,%ecx
f0105097:	0f 89 ff 00 00 00    	jns    f010519c <vprintfmt+0x38c>
				putch('-', putdat);
f010509d:	83 ec 08             	sub    $0x8,%esp
f01050a0:	53                   	push   %ebx
f01050a1:	6a 2d                	push   $0x2d
f01050a3:	ff d6                	call   *%esi
				num = -(long long) num;
f01050a5:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01050a8:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01050ab:	f7 da                	neg    %edx
f01050ad:	83 d1 00             	adc    $0x0,%ecx
f01050b0:	f7 d9                	neg    %ecx
f01050b2:	83 c4 10             	add    $0x10,%esp
			base = 10;
f01050b5:	b8 0a 00 00 00       	mov    $0xa,%eax
f01050ba:	e9 dd 00 00 00       	jmp    f010519c <vprintfmt+0x38c>
		return va_arg(*ap, int);
f01050bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01050c2:	8b 00                	mov    (%eax),%eax
f01050c4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01050c7:	99                   	cltd   
f01050c8:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01050cb:	8b 45 14             	mov    0x14(%ebp),%eax
f01050ce:	8d 40 04             	lea    0x4(%eax),%eax
f01050d1:	89 45 14             	mov    %eax,0x14(%ebp)
f01050d4:	eb b4                	jmp    f010508a <vprintfmt+0x27a>
	if (lflag >= 2)
f01050d6:	83 f9 01             	cmp    $0x1,%ecx
f01050d9:	7f 1e                	jg     f01050f9 <vprintfmt+0x2e9>
	else if (lflag)
f01050db:	85 c9                	test   %ecx,%ecx
f01050dd:	74 32                	je     f0105111 <vprintfmt+0x301>
		return va_arg(*ap, unsigned long);
f01050df:	8b 45 14             	mov    0x14(%ebp),%eax
f01050e2:	8b 10                	mov    (%eax),%edx
f01050e4:	b9 00 00 00 00       	mov    $0x0,%ecx
f01050e9:	8d 40 04             	lea    0x4(%eax),%eax
f01050ec:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01050ef:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long);
f01050f4:	e9 a3 00 00 00       	jmp    f010519c <vprintfmt+0x38c>
		return va_arg(*ap, unsigned long long);
f01050f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01050fc:	8b 10                	mov    (%eax),%edx
f01050fe:	8b 48 04             	mov    0x4(%eax),%ecx
f0105101:	8d 40 08             	lea    0x8(%eax),%eax
f0105104:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0105107:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long long);
f010510c:	e9 8b 00 00 00       	jmp    f010519c <vprintfmt+0x38c>
		return va_arg(*ap, unsigned int);
f0105111:	8b 45 14             	mov    0x14(%ebp),%eax
f0105114:	8b 10                	mov    (%eax),%edx
f0105116:	b9 00 00 00 00       	mov    $0x0,%ecx
f010511b:	8d 40 04             	lea    0x4(%eax),%eax
f010511e:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0105121:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned int);
f0105126:	eb 74                	jmp    f010519c <vprintfmt+0x38c>
	if (lflag >= 2)
f0105128:	83 f9 01             	cmp    $0x1,%ecx
f010512b:	7f 1b                	jg     f0105148 <vprintfmt+0x338>
	else if (lflag)
f010512d:	85 c9                	test   %ecx,%ecx
f010512f:	74 2c                	je     f010515d <vprintfmt+0x34d>
		return va_arg(*ap, unsigned long);
f0105131:	8b 45 14             	mov    0x14(%ebp),%eax
f0105134:	8b 10                	mov    (%eax),%edx
f0105136:	b9 00 00 00 00       	mov    $0x0,%ecx
f010513b:	8d 40 04             	lea    0x4(%eax),%eax
f010513e:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0105141:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long);
f0105146:	eb 54                	jmp    f010519c <vprintfmt+0x38c>
		return va_arg(*ap, unsigned long long);
f0105148:	8b 45 14             	mov    0x14(%ebp),%eax
f010514b:	8b 10                	mov    (%eax),%edx
f010514d:	8b 48 04             	mov    0x4(%eax),%ecx
f0105150:	8d 40 08             	lea    0x8(%eax),%eax
f0105153:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0105156:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long long);
f010515b:	eb 3f                	jmp    f010519c <vprintfmt+0x38c>
		return va_arg(*ap, unsigned int);
f010515d:	8b 45 14             	mov    0x14(%ebp),%eax
f0105160:	8b 10                	mov    (%eax),%edx
f0105162:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105167:	8d 40 04             	lea    0x4(%eax),%eax
f010516a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010516d:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned int);
f0105172:	eb 28                	jmp    f010519c <vprintfmt+0x38c>
			putch('0', putdat);
f0105174:	83 ec 08             	sub    $0x8,%esp
f0105177:	53                   	push   %ebx
f0105178:	6a 30                	push   $0x30
f010517a:	ff d6                	call   *%esi
			putch('x', putdat);
f010517c:	83 c4 08             	add    $0x8,%esp
f010517f:	53                   	push   %ebx
f0105180:	6a 78                	push   $0x78
f0105182:	ff d6                	call   *%esi
			num = (unsigned long long)
f0105184:	8b 45 14             	mov    0x14(%ebp),%eax
f0105187:	8b 10                	mov    (%eax),%edx
f0105189:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010518e:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0105191:	8d 40 04             	lea    0x4(%eax),%eax
f0105194:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0105197:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f010519c:	83 ec 0c             	sub    $0xc,%esp
f010519f:	0f be 7d d3          	movsbl -0x2d(%ebp),%edi
f01051a3:	57                   	push   %edi
f01051a4:	ff 75 e0             	pushl  -0x20(%ebp)
f01051a7:	50                   	push   %eax
f01051a8:	51                   	push   %ecx
f01051a9:	52                   	push   %edx
f01051aa:	89 da                	mov    %ebx,%edx
f01051ac:	89 f0                	mov    %esi,%eax
f01051ae:	e8 72 fb ff ff       	call   f0104d25 <printnum>
			break;
f01051b3:	83 c4 20             	add    $0x20,%esp
			if ((p = va_arg(ap, char *)) == NULL)
f01051b6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01051b9:	83 c7 01             	add    $0x1,%edi
f01051bc:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01051c0:	83 f8 25             	cmp    $0x25,%eax
f01051c3:	0f 84 62 fc ff ff    	je     f0104e2b <vprintfmt+0x1b>
			if (ch == '\0')
f01051c9:	85 c0                	test   %eax,%eax
f01051cb:	0f 84 8b 00 00 00    	je     f010525c <vprintfmt+0x44c>
			putch(ch, putdat);
f01051d1:	83 ec 08             	sub    $0x8,%esp
f01051d4:	53                   	push   %ebx
f01051d5:	50                   	push   %eax
f01051d6:	ff d6                	call   *%esi
f01051d8:	83 c4 10             	add    $0x10,%esp
f01051db:	eb dc                	jmp    f01051b9 <vprintfmt+0x3a9>
	if (lflag >= 2)
f01051dd:	83 f9 01             	cmp    $0x1,%ecx
f01051e0:	7f 1b                	jg     f01051fd <vprintfmt+0x3ed>
	else if (lflag)
f01051e2:	85 c9                	test   %ecx,%ecx
f01051e4:	74 2c                	je     f0105212 <vprintfmt+0x402>
		return va_arg(*ap, unsigned long);
f01051e6:	8b 45 14             	mov    0x14(%ebp),%eax
f01051e9:	8b 10                	mov    (%eax),%edx
f01051eb:	b9 00 00 00 00       	mov    $0x0,%ecx
f01051f0:	8d 40 04             	lea    0x4(%eax),%eax
f01051f3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01051f6:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long);
f01051fb:	eb 9f                	jmp    f010519c <vprintfmt+0x38c>
		return va_arg(*ap, unsigned long long);
f01051fd:	8b 45 14             	mov    0x14(%ebp),%eax
f0105200:	8b 10                	mov    (%eax),%edx
f0105202:	8b 48 04             	mov    0x4(%eax),%ecx
f0105205:	8d 40 08             	lea    0x8(%eax),%eax
f0105208:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010520b:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long long);
f0105210:	eb 8a                	jmp    f010519c <vprintfmt+0x38c>
		return va_arg(*ap, unsigned int);
f0105212:	8b 45 14             	mov    0x14(%ebp),%eax
f0105215:	8b 10                	mov    (%eax),%edx
f0105217:	b9 00 00 00 00       	mov    $0x0,%ecx
f010521c:	8d 40 04             	lea    0x4(%eax),%eax
f010521f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0105222:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned int);
f0105227:	e9 70 ff ff ff       	jmp    f010519c <vprintfmt+0x38c>
			putch(ch, putdat);
f010522c:	83 ec 08             	sub    $0x8,%esp
f010522f:	53                   	push   %ebx
f0105230:	6a 25                	push   $0x25
f0105232:	ff d6                	call   *%esi
			break;
f0105234:	83 c4 10             	add    $0x10,%esp
f0105237:	e9 7a ff ff ff       	jmp    f01051b6 <vprintfmt+0x3a6>
			putch('%', putdat);
f010523c:	83 ec 08             	sub    $0x8,%esp
f010523f:	53                   	push   %ebx
f0105240:	6a 25                	push   $0x25
f0105242:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105244:	83 c4 10             	add    $0x10,%esp
f0105247:	89 f8                	mov    %edi,%eax
f0105249:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f010524d:	74 05                	je     f0105254 <vprintfmt+0x444>
f010524f:	83 e8 01             	sub    $0x1,%eax
f0105252:	eb f5                	jmp    f0105249 <vprintfmt+0x439>
f0105254:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105257:	e9 5a ff ff ff       	jmp    f01051b6 <vprintfmt+0x3a6>
}
f010525c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010525f:	5b                   	pop    %ebx
f0105260:	5e                   	pop    %esi
f0105261:	5f                   	pop    %edi
f0105262:	5d                   	pop    %ebp
f0105263:	c3                   	ret    

f0105264 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105264:	f3 0f 1e fb          	endbr32 
f0105268:	55                   	push   %ebp
f0105269:	89 e5                	mov    %esp,%ebp
f010526b:	83 ec 18             	sub    $0x18,%esp
f010526e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105271:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105274:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105277:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010527b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010527e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105285:	85 c0                	test   %eax,%eax
f0105287:	74 26                	je     f01052af <vsnprintf+0x4b>
f0105289:	85 d2                	test   %edx,%edx
f010528b:	7e 22                	jle    f01052af <vsnprintf+0x4b>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010528d:	ff 75 14             	pushl  0x14(%ebp)
f0105290:	ff 75 10             	pushl  0x10(%ebp)
f0105293:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105296:	50                   	push   %eax
f0105297:	68 ce 4d 10 f0       	push   $0xf0104dce
f010529c:	e8 6f fb ff ff       	call   f0104e10 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01052a1:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01052a4:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01052a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01052aa:	83 c4 10             	add    $0x10,%esp
}
f01052ad:	c9                   	leave  
f01052ae:	c3                   	ret    
		return -E_INVAL;
f01052af:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01052b4:	eb f7                	jmp    f01052ad <vsnprintf+0x49>

f01052b6 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01052b6:	f3 0f 1e fb          	endbr32 
f01052ba:	55                   	push   %ebp
f01052bb:	89 e5                	mov    %esp,%ebp
f01052bd:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01052c0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01052c3:	50                   	push   %eax
f01052c4:	ff 75 10             	pushl  0x10(%ebp)
f01052c7:	ff 75 0c             	pushl  0xc(%ebp)
f01052ca:	ff 75 08             	pushl  0x8(%ebp)
f01052cd:	e8 92 ff ff ff       	call   f0105264 <vsnprintf>
	va_end(ap);

	return rc;
}
f01052d2:	c9                   	leave  
f01052d3:	c3                   	ret    

f01052d4 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01052d4:	f3 0f 1e fb          	endbr32 
f01052d8:	55                   	push   %ebp
f01052d9:	89 e5                	mov    %esp,%ebp
f01052db:	57                   	push   %edi
f01052dc:	56                   	push   %esi
f01052dd:	53                   	push   %ebx
f01052de:	83 ec 0c             	sub    $0xc,%esp
f01052e1:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01052e4:	85 c0                	test   %eax,%eax
f01052e6:	74 11                	je     f01052f9 <readline+0x25>
		cprintf("%s", prompt);
f01052e8:	83 ec 08             	sub    $0x8,%esp
f01052eb:	50                   	push   %eax
f01052ec:	68 95 71 10 f0       	push   $0xf0107195
f01052f1:	e8 d7 e6 ff ff       	call   f01039cd <cprintf>
f01052f6:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01052f9:	83 ec 0c             	sub    $0xc,%esp
f01052fc:	6a 00                	push   $0x0
f01052fe:	e8 af b4 ff ff       	call   f01007b2 <iscons>
f0105303:	89 c7                	mov    %eax,%edi
f0105305:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0105308:	be 00 00 00 00       	mov    $0x0,%esi
f010530d:	eb 4b                	jmp    f010535a <readline+0x86>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f010530f:	83 ec 08             	sub    $0x8,%esp
f0105312:	50                   	push   %eax
f0105313:	68 a4 7c 10 f0       	push   $0xf0107ca4
f0105318:	e8 b0 e6 ff ff       	call   f01039cd <cprintf>
			return NULL;
f010531d:	83 c4 10             	add    $0x10,%esp
f0105320:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0105325:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105328:	5b                   	pop    %ebx
f0105329:	5e                   	pop    %esi
f010532a:	5f                   	pop    %edi
f010532b:	5d                   	pop    %ebp
f010532c:	c3                   	ret    
			if (echoing)
f010532d:	85 ff                	test   %edi,%edi
f010532f:	75 05                	jne    f0105336 <readline+0x62>
			i--;
f0105331:	83 ee 01             	sub    $0x1,%esi
f0105334:	eb 24                	jmp    f010535a <readline+0x86>
				cputchar('\b');
f0105336:	83 ec 0c             	sub    $0xc,%esp
f0105339:	6a 08                	push   $0x8
f010533b:	e8 49 b4 ff ff       	call   f0100789 <cputchar>
f0105340:	83 c4 10             	add    $0x10,%esp
f0105343:	eb ec                	jmp    f0105331 <readline+0x5d>
				cputchar(c);
f0105345:	83 ec 0c             	sub    $0xc,%esp
f0105348:	53                   	push   %ebx
f0105349:	e8 3b b4 ff ff       	call   f0100789 <cputchar>
f010534e:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0105351:	88 9e 80 2a 23 f0    	mov    %bl,-0xfdcd580(%esi)
f0105357:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f010535a:	e8 3e b4 ff ff       	call   f010079d <getchar>
f010535f:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0105361:	85 c0                	test   %eax,%eax
f0105363:	78 aa                	js     f010530f <readline+0x3b>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105365:	83 f8 08             	cmp    $0x8,%eax
f0105368:	0f 94 c2             	sete   %dl
f010536b:	83 f8 7f             	cmp    $0x7f,%eax
f010536e:	0f 94 c0             	sete   %al
f0105371:	08 c2                	or     %al,%dl
f0105373:	74 04                	je     f0105379 <readline+0xa5>
f0105375:	85 f6                	test   %esi,%esi
f0105377:	7f b4                	jg     f010532d <readline+0x59>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105379:	83 fb 1f             	cmp    $0x1f,%ebx
f010537c:	7e 0e                	jle    f010538c <readline+0xb8>
f010537e:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0105384:	7f 06                	jg     f010538c <readline+0xb8>
			if (echoing)
f0105386:	85 ff                	test   %edi,%edi
f0105388:	74 c7                	je     f0105351 <readline+0x7d>
f010538a:	eb b9                	jmp    f0105345 <readline+0x71>
		} else if (c == '\n' || c == '\r') {
f010538c:	83 fb 0a             	cmp    $0xa,%ebx
f010538f:	74 05                	je     f0105396 <readline+0xc2>
f0105391:	83 fb 0d             	cmp    $0xd,%ebx
f0105394:	75 c4                	jne    f010535a <readline+0x86>
			if (echoing)
f0105396:	85 ff                	test   %edi,%edi
f0105398:	75 11                	jne    f01053ab <readline+0xd7>
			buf[i] = 0;
f010539a:	c6 86 80 2a 23 f0 00 	movb   $0x0,-0xfdcd580(%esi)
			return buf;
f01053a1:	b8 80 2a 23 f0       	mov    $0xf0232a80,%eax
f01053a6:	e9 7a ff ff ff       	jmp    f0105325 <readline+0x51>
				cputchar('\n');
f01053ab:	83 ec 0c             	sub    $0xc,%esp
f01053ae:	6a 0a                	push   $0xa
f01053b0:	e8 d4 b3 ff ff       	call   f0100789 <cputchar>
f01053b5:	83 c4 10             	add    $0x10,%esp
f01053b8:	eb e0                	jmp    f010539a <readline+0xc6>

f01053ba <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01053ba:	f3 0f 1e fb          	endbr32 
f01053be:	55                   	push   %ebp
f01053bf:	89 e5                	mov    %esp,%ebp
f01053c1:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01053c4:	b8 00 00 00 00       	mov    $0x0,%eax
f01053c9:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01053cd:	74 05                	je     f01053d4 <strlen+0x1a>
		n++;
f01053cf:	83 c0 01             	add    $0x1,%eax
f01053d2:	eb f5                	jmp    f01053c9 <strlen+0xf>
	return n;
}
f01053d4:	5d                   	pop    %ebp
f01053d5:	c3                   	ret    

f01053d6 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01053d6:	f3 0f 1e fb          	endbr32 
f01053da:	55                   	push   %ebp
f01053db:	89 e5                	mov    %esp,%ebp
f01053dd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01053e0:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01053e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01053e8:	39 d0                	cmp    %edx,%eax
f01053ea:	74 0d                	je     f01053f9 <strnlen+0x23>
f01053ec:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01053f0:	74 05                	je     f01053f7 <strnlen+0x21>
		n++;
f01053f2:	83 c0 01             	add    $0x1,%eax
f01053f5:	eb f1                	jmp    f01053e8 <strnlen+0x12>
f01053f7:	89 c2                	mov    %eax,%edx
	return n;
}
f01053f9:	89 d0                	mov    %edx,%eax
f01053fb:	5d                   	pop    %ebp
f01053fc:	c3                   	ret    

f01053fd <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01053fd:	f3 0f 1e fb          	endbr32 
f0105401:	55                   	push   %ebp
f0105402:	89 e5                	mov    %esp,%ebp
f0105404:	53                   	push   %ebx
f0105405:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105408:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010540b:	b8 00 00 00 00       	mov    $0x0,%eax
f0105410:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f0105414:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f0105417:	83 c0 01             	add    $0x1,%eax
f010541a:	84 d2                	test   %dl,%dl
f010541c:	75 f2                	jne    f0105410 <strcpy+0x13>
		/* do nothing */;
	return ret;
}
f010541e:	89 c8                	mov    %ecx,%eax
f0105420:	5b                   	pop    %ebx
f0105421:	5d                   	pop    %ebp
f0105422:	c3                   	ret    

f0105423 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105423:	f3 0f 1e fb          	endbr32 
f0105427:	55                   	push   %ebp
f0105428:	89 e5                	mov    %esp,%ebp
f010542a:	53                   	push   %ebx
f010542b:	83 ec 10             	sub    $0x10,%esp
f010542e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105431:	53                   	push   %ebx
f0105432:	e8 83 ff ff ff       	call   f01053ba <strlen>
f0105437:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f010543a:	ff 75 0c             	pushl  0xc(%ebp)
f010543d:	01 d8                	add    %ebx,%eax
f010543f:	50                   	push   %eax
f0105440:	e8 b8 ff ff ff       	call   f01053fd <strcpy>
	return dst;
}
f0105445:	89 d8                	mov    %ebx,%eax
f0105447:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010544a:	c9                   	leave  
f010544b:	c3                   	ret    

f010544c <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010544c:	f3 0f 1e fb          	endbr32 
f0105450:	55                   	push   %ebp
f0105451:	89 e5                	mov    %esp,%ebp
f0105453:	56                   	push   %esi
f0105454:	53                   	push   %ebx
f0105455:	8b 75 08             	mov    0x8(%ebp),%esi
f0105458:	8b 55 0c             	mov    0xc(%ebp),%edx
f010545b:	89 f3                	mov    %esi,%ebx
f010545d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105460:	89 f0                	mov    %esi,%eax
f0105462:	39 d8                	cmp    %ebx,%eax
f0105464:	74 11                	je     f0105477 <strncpy+0x2b>
		*dst++ = *src;
f0105466:	83 c0 01             	add    $0x1,%eax
f0105469:	0f b6 0a             	movzbl (%edx),%ecx
f010546c:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010546f:	80 f9 01             	cmp    $0x1,%cl
f0105472:	83 da ff             	sbb    $0xffffffff,%edx
f0105475:	eb eb                	jmp    f0105462 <strncpy+0x16>
	}
	return ret;
}
f0105477:	89 f0                	mov    %esi,%eax
f0105479:	5b                   	pop    %ebx
f010547a:	5e                   	pop    %esi
f010547b:	5d                   	pop    %ebp
f010547c:	c3                   	ret    

f010547d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010547d:	f3 0f 1e fb          	endbr32 
f0105481:	55                   	push   %ebp
f0105482:	89 e5                	mov    %esp,%ebp
f0105484:	56                   	push   %esi
f0105485:	53                   	push   %ebx
f0105486:	8b 75 08             	mov    0x8(%ebp),%esi
f0105489:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010548c:	8b 55 10             	mov    0x10(%ebp),%edx
f010548f:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105491:	85 d2                	test   %edx,%edx
f0105493:	74 21                	je     f01054b6 <strlcpy+0x39>
f0105495:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0105499:	89 f2                	mov    %esi,%edx
		while (--size > 0 && *src != '\0')
f010549b:	39 c2                	cmp    %eax,%edx
f010549d:	74 14                	je     f01054b3 <strlcpy+0x36>
f010549f:	0f b6 19             	movzbl (%ecx),%ebx
f01054a2:	84 db                	test   %bl,%bl
f01054a4:	74 0b                	je     f01054b1 <strlcpy+0x34>
			*dst++ = *src++;
f01054a6:	83 c1 01             	add    $0x1,%ecx
f01054a9:	83 c2 01             	add    $0x1,%edx
f01054ac:	88 5a ff             	mov    %bl,-0x1(%edx)
f01054af:	eb ea                	jmp    f010549b <strlcpy+0x1e>
f01054b1:	89 d0                	mov    %edx,%eax
		*dst = '\0';
f01054b3:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01054b6:	29 f0                	sub    %esi,%eax
}
f01054b8:	5b                   	pop    %ebx
f01054b9:	5e                   	pop    %esi
f01054ba:	5d                   	pop    %ebp
f01054bb:	c3                   	ret    

f01054bc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01054bc:	f3 0f 1e fb          	endbr32 
f01054c0:	55                   	push   %ebp
f01054c1:	89 e5                	mov    %esp,%ebp
f01054c3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01054c6:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01054c9:	0f b6 01             	movzbl (%ecx),%eax
f01054cc:	84 c0                	test   %al,%al
f01054ce:	74 0c                	je     f01054dc <strcmp+0x20>
f01054d0:	3a 02                	cmp    (%edx),%al
f01054d2:	75 08                	jne    f01054dc <strcmp+0x20>
		p++, q++;
f01054d4:	83 c1 01             	add    $0x1,%ecx
f01054d7:	83 c2 01             	add    $0x1,%edx
f01054da:	eb ed                	jmp    f01054c9 <strcmp+0xd>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01054dc:	0f b6 c0             	movzbl %al,%eax
f01054df:	0f b6 12             	movzbl (%edx),%edx
f01054e2:	29 d0                	sub    %edx,%eax
}
f01054e4:	5d                   	pop    %ebp
f01054e5:	c3                   	ret    

f01054e6 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01054e6:	f3 0f 1e fb          	endbr32 
f01054ea:	55                   	push   %ebp
f01054eb:	89 e5                	mov    %esp,%ebp
f01054ed:	53                   	push   %ebx
f01054ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01054f1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01054f4:	89 c3                	mov    %eax,%ebx
f01054f6:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01054f9:	eb 06                	jmp    f0105501 <strncmp+0x1b>
		n--, p++, q++;
f01054fb:	83 c0 01             	add    $0x1,%eax
f01054fe:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0105501:	39 d8                	cmp    %ebx,%eax
f0105503:	74 16                	je     f010551b <strncmp+0x35>
f0105505:	0f b6 08             	movzbl (%eax),%ecx
f0105508:	84 c9                	test   %cl,%cl
f010550a:	74 04                	je     f0105510 <strncmp+0x2a>
f010550c:	3a 0a                	cmp    (%edx),%cl
f010550e:	74 eb                	je     f01054fb <strncmp+0x15>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105510:	0f b6 00             	movzbl (%eax),%eax
f0105513:	0f b6 12             	movzbl (%edx),%edx
f0105516:	29 d0                	sub    %edx,%eax
}
f0105518:	5b                   	pop    %ebx
f0105519:	5d                   	pop    %ebp
f010551a:	c3                   	ret    
		return 0;
f010551b:	b8 00 00 00 00       	mov    $0x0,%eax
f0105520:	eb f6                	jmp    f0105518 <strncmp+0x32>

f0105522 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105522:	f3 0f 1e fb          	endbr32 
f0105526:	55                   	push   %ebp
f0105527:	89 e5                	mov    %esp,%ebp
f0105529:	8b 45 08             	mov    0x8(%ebp),%eax
f010552c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105530:	0f b6 10             	movzbl (%eax),%edx
f0105533:	84 d2                	test   %dl,%dl
f0105535:	74 09                	je     f0105540 <strchr+0x1e>
		if (*s == c)
f0105537:	38 ca                	cmp    %cl,%dl
f0105539:	74 0a                	je     f0105545 <strchr+0x23>
	for (; *s; s++)
f010553b:	83 c0 01             	add    $0x1,%eax
f010553e:	eb f0                	jmp    f0105530 <strchr+0xe>
			return (char *) s;
	return 0;
f0105540:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105545:	5d                   	pop    %ebp
f0105546:	c3                   	ret    

f0105547 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105547:	f3 0f 1e fb          	endbr32 
f010554b:	55                   	push   %ebp
f010554c:	89 e5                	mov    %esp,%ebp
f010554e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105551:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105555:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0105558:	38 ca                	cmp    %cl,%dl
f010555a:	74 09                	je     f0105565 <strfind+0x1e>
f010555c:	84 d2                	test   %dl,%dl
f010555e:	74 05                	je     f0105565 <strfind+0x1e>
	for (; *s; s++)
f0105560:	83 c0 01             	add    $0x1,%eax
f0105563:	eb f0                	jmp    f0105555 <strfind+0xe>
			break;
	return (char *) s;
}
f0105565:	5d                   	pop    %ebp
f0105566:	c3                   	ret    

f0105567 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105567:	f3 0f 1e fb          	endbr32 
f010556b:	55                   	push   %ebp
f010556c:	89 e5                	mov    %esp,%ebp
f010556e:	57                   	push   %edi
f010556f:	56                   	push   %esi
f0105570:	53                   	push   %ebx
f0105571:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105574:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105577:	85 c9                	test   %ecx,%ecx
f0105579:	74 31                	je     f01055ac <memset+0x45>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010557b:	89 f8                	mov    %edi,%eax
f010557d:	09 c8                	or     %ecx,%eax
f010557f:	a8 03                	test   $0x3,%al
f0105581:	75 23                	jne    f01055a6 <memset+0x3f>
		c &= 0xFF;
f0105583:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105587:	89 d3                	mov    %edx,%ebx
f0105589:	c1 e3 08             	shl    $0x8,%ebx
f010558c:	89 d0                	mov    %edx,%eax
f010558e:	c1 e0 18             	shl    $0x18,%eax
f0105591:	89 d6                	mov    %edx,%esi
f0105593:	c1 e6 10             	shl    $0x10,%esi
f0105596:	09 f0                	or     %esi,%eax
f0105598:	09 c2                	or     %eax,%edx
f010559a:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010559c:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f010559f:	89 d0                	mov    %edx,%eax
f01055a1:	fc                   	cld    
f01055a2:	f3 ab                	rep stos %eax,%es:(%edi)
f01055a4:	eb 06                	jmp    f01055ac <memset+0x45>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01055a6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01055a9:	fc                   	cld    
f01055aa:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01055ac:	89 f8                	mov    %edi,%eax
f01055ae:	5b                   	pop    %ebx
f01055af:	5e                   	pop    %esi
f01055b0:	5f                   	pop    %edi
f01055b1:	5d                   	pop    %ebp
f01055b2:	c3                   	ret    

f01055b3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01055b3:	f3 0f 1e fb          	endbr32 
f01055b7:	55                   	push   %ebp
f01055b8:	89 e5                	mov    %esp,%ebp
f01055ba:	57                   	push   %edi
f01055bb:	56                   	push   %esi
f01055bc:	8b 45 08             	mov    0x8(%ebp),%eax
f01055bf:	8b 75 0c             	mov    0xc(%ebp),%esi
f01055c2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01055c5:	39 c6                	cmp    %eax,%esi
f01055c7:	73 32                	jae    f01055fb <memmove+0x48>
f01055c9:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01055cc:	39 c2                	cmp    %eax,%edx
f01055ce:	76 2b                	jbe    f01055fb <memmove+0x48>
		s += n;
		d += n;
f01055d0:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01055d3:	89 fe                	mov    %edi,%esi
f01055d5:	09 ce                	or     %ecx,%esi
f01055d7:	09 d6                	or     %edx,%esi
f01055d9:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01055df:	75 0e                	jne    f01055ef <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01055e1:	83 ef 04             	sub    $0x4,%edi
f01055e4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01055e7:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01055ea:	fd                   	std    
f01055eb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01055ed:	eb 09                	jmp    f01055f8 <memmove+0x45>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01055ef:	83 ef 01             	sub    $0x1,%edi
f01055f2:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01055f5:	fd                   	std    
f01055f6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01055f8:	fc                   	cld    
f01055f9:	eb 1a                	jmp    f0105615 <memmove+0x62>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01055fb:	89 c2                	mov    %eax,%edx
f01055fd:	09 ca                	or     %ecx,%edx
f01055ff:	09 f2                	or     %esi,%edx
f0105601:	f6 c2 03             	test   $0x3,%dl
f0105604:	75 0a                	jne    f0105610 <memmove+0x5d>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105606:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0105609:	89 c7                	mov    %eax,%edi
f010560b:	fc                   	cld    
f010560c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010560e:	eb 05                	jmp    f0105615 <memmove+0x62>
		else
			asm volatile("cld; rep movsb\n"
f0105610:	89 c7                	mov    %eax,%edi
f0105612:	fc                   	cld    
f0105613:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105615:	5e                   	pop    %esi
f0105616:	5f                   	pop    %edi
f0105617:	5d                   	pop    %ebp
f0105618:	c3                   	ret    

f0105619 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105619:	f3 0f 1e fb          	endbr32 
f010561d:	55                   	push   %ebp
f010561e:	89 e5                	mov    %esp,%ebp
f0105620:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0105623:	ff 75 10             	pushl  0x10(%ebp)
f0105626:	ff 75 0c             	pushl  0xc(%ebp)
f0105629:	ff 75 08             	pushl  0x8(%ebp)
f010562c:	e8 82 ff ff ff       	call   f01055b3 <memmove>
}
f0105631:	c9                   	leave  
f0105632:	c3                   	ret    

f0105633 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105633:	f3 0f 1e fb          	endbr32 
f0105637:	55                   	push   %ebp
f0105638:	89 e5                	mov    %esp,%ebp
f010563a:	56                   	push   %esi
f010563b:	53                   	push   %ebx
f010563c:	8b 45 08             	mov    0x8(%ebp),%eax
f010563f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105642:	89 c6                	mov    %eax,%esi
f0105644:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105647:	39 f0                	cmp    %esi,%eax
f0105649:	74 1c                	je     f0105667 <memcmp+0x34>
		if (*s1 != *s2)
f010564b:	0f b6 08             	movzbl (%eax),%ecx
f010564e:	0f b6 1a             	movzbl (%edx),%ebx
f0105651:	38 d9                	cmp    %bl,%cl
f0105653:	75 08                	jne    f010565d <memcmp+0x2a>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0105655:	83 c0 01             	add    $0x1,%eax
f0105658:	83 c2 01             	add    $0x1,%edx
f010565b:	eb ea                	jmp    f0105647 <memcmp+0x14>
			return (int) *s1 - (int) *s2;
f010565d:	0f b6 c1             	movzbl %cl,%eax
f0105660:	0f b6 db             	movzbl %bl,%ebx
f0105663:	29 d8                	sub    %ebx,%eax
f0105665:	eb 05                	jmp    f010566c <memcmp+0x39>
	}

	return 0;
f0105667:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010566c:	5b                   	pop    %ebx
f010566d:	5e                   	pop    %esi
f010566e:	5d                   	pop    %ebp
f010566f:	c3                   	ret    

f0105670 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105670:	f3 0f 1e fb          	endbr32 
f0105674:	55                   	push   %ebp
f0105675:	89 e5                	mov    %esp,%ebp
f0105677:	8b 45 08             	mov    0x8(%ebp),%eax
f010567a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010567d:	89 c2                	mov    %eax,%edx
f010567f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105682:	39 d0                	cmp    %edx,%eax
f0105684:	73 09                	jae    f010568f <memfind+0x1f>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105686:	38 08                	cmp    %cl,(%eax)
f0105688:	74 05                	je     f010568f <memfind+0x1f>
	for (; s < ends; s++)
f010568a:	83 c0 01             	add    $0x1,%eax
f010568d:	eb f3                	jmp    f0105682 <memfind+0x12>
			break;
	return (void *) s;
}
f010568f:	5d                   	pop    %ebp
f0105690:	c3                   	ret    

f0105691 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105691:	f3 0f 1e fb          	endbr32 
f0105695:	55                   	push   %ebp
f0105696:	89 e5                	mov    %esp,%ebp
f0105698:	57                   	push   %edi
f0105699:	56                   	push   %esi
f010569a:	53                   	push   %ebx
f010569b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010569e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01056a1:	eb 03                	jmp    f01056a6 <strtol+0x15>
		s++;
f01056a3:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01056a6:	0f b6 01             	movzbl (%ecx),%eax
f01056a9:	3c 20                	cmp    $0x20,%al
f01056ab:	74 f6                	je     f01056a3 <strtol+0x12>
f01056ad:	3c 09                	cmp    $0x9,%al
f01056af:	74 f2                	je     f01056a3 <strtol+0x12>

	// plus/minus sign
	if (*s == '+')
f01056b1:	3c 2b                	cmp    $0x2b,%al
f01056b3:	74 2a                	je     f01056df <strtol+0x4e>
	int neg = 0;
f01056b5:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01056ba:	3c 2d                	cmp    $0x2d,%al
f01056bc:	74 2b                	je     f01056e9 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01056be:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01056c4:	75 0f                	jne    f01056d5 <strtol+0x44>
f01056c6:	80 39 30             	cmpb   $0x30,(%ecx)
f01056c9:	74 28                	je     f01056f3 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01056cb:	85 db                	test   %ebx,%ebx
f01056cd:	b8 0a 00 00 00       	mov    $0xa,%eax
f01056d2:	0f 44 d8             	cmove  %eax,%ebx
f01056d5:	b8 00 00 00 00       	mov    $0x0,%eax
f01056da:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01056dd:	eb 46                	jmp    f0105725 <strtol+0x94>
		s++;
f01056df:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f01056e2:	bf 00 00 00 00       	mov    $0x0,%edi
f01056e7:	eb d5                	jmp    f01056be <strtol+0x2d>
		s++, neg = 1;
f01056e9:	83 c1 01             	add    $0x1,%ecx
f01056ec:	bf 01 00 00 00       	mov    $0x1,%edi
f01056f1:	eb cb                	jmp    f01056be <strtol+0x2d>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01056f3:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01056f7:	74 0e                	je     f0105707 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01056f9:	85 db                	test   %ebx,%ebx
f01056fb:	75 d8                	jne    f01056d5 <strtol+0x44>
		s++, base = 8;
f01056fd:	83 c1 01             	add    $0x1,%ecx
f0105700:	bb 08 00 00 00       	mov    $0x8,%ebx
f0105705:	eb ce                	jmp    f01056d5 <strtol+0x44>
		s += 2, base = 16;
f0105707:	83 c1 02             	add    $0x2,%ecx
f010570a:	bb 10 00 00 00       	mov    $0x10,%ebx
f010570f:	eb c4                	jmp    f01056d5 <strtol+0x44>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f0105711:	0f be d2             	movsbl %dl,%edx
f0105714:	83 ea 30             	sub    $0x30,%edx
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0105717:	3b 55 10             	cmp    0x10(%ebp),%edx
f010571a:	7d 3a                	jge    f0105756 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f010571c:	83 c1 01             	add    $0x1,%ecx
f010571f:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105723:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0105725:	0f b6 11             	movzbl (%ecx),%edx
f0105728:	8d 72 d0             	lea    -0x30(%edx),%esi
f010572b:	89 f3                	mov    %esi,%ebx
f010572d:	80 fb 09             	cmp    $0x9,%bl
f0105730:	76 df                	jbe    f0105711 <strtol+0x80>
		else if (*s >= 'a' && *s <= 'z')
f0105732:	8d 72 9f             	lea    -0x61(%edx),%esi
f0105735:	89 f3                	mov    %esi,%ebx
f0105737:	80 fb 19             	cmp    $0x19,%bl
f010573a:	77 08                	ja     f0105744 <strtol+0xb3>
			dig = *s - 'a' + 10;
f010573c:	0f be d2             	movsbl %dl,%edx
f010573f:	83 ea 57             	sub    $0x57,%edx
f0105742:	eb d3                	jmp    f0105717 <strtol+0x86>
		else if (*s >= 'A' && *s <= 'Z')
f0105744:	8d 72 bf             	lea    -0x41(%edx),%esi
f0105747:	89 f3                	mov    %esi,%ebx
f0105749:	80 fb 19             	cmp    $0x19,%bl
f010574c:	77 08                	ja     f0105756 <strtol+0xc5>
			dig = *s - 'A' + 10;
f010574e:	0f be d2             	movsbl %dl,%edx
f0105751:	83 ea 37             	sub    $0x37,%edx
f0105754:	eb c1                	jmp    f0105717 <strtol+0x86>
		// we don't properly detect overflow!
	}

	if (endptr)
f0105756:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010575a:	74 05                	je     f0105761 <strtol+0xd0>
		*endptr = (char *) s;
f010575c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010575f:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0105761:	89 c2                	mov    %eax,%edx
f0105763:	f7 da                	neg    %edx
f0105765:	85 ff                	test   %edi,%edi
f0105767:	0f 45 c2             	cmovne %edx,%eax
}
f010576a:	5b                   	pop    %ebx
f010576b:	5e                   	pop    %esi
f010576c:	5f                   	pop    %edi
f010576d:	5d                   	pop    %ebp
f010576e:	c3                   	ret    
f010576f:	90                   	nop

f0105770 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0105770:	fa                   	cli    

	xorw    %ax, %ax
f0105771:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0105773:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105775:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105777:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105779:	0f 01 16             	lgdtl  (%esi)
f010577c:	74 70                	je     f01057ee <mpsearch1+0x3>
	movl    %cr0, %eax
f010577e:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0105781:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105785:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105788:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f010578e:	08 00                	or     %al,(%eax)

f0105790 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0105790:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105794:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105796:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105798:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f010579a:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f010579e:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f01057a0:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f01057a2:	b8 00 00 12 00       	mov    $0x120000,%eax
	movl    %eax, %cr3
f01057a7:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f01057aa:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f01057ad:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f01057b2:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f01057b5:	8b 25 84 2e 23 f0    	mov    0xf0232e84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f01057bb:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f01057c0:	b8 a9 01 10 f0       	mov    $0xf01001a9,%eax
	call    *%eax
f01057c5:	ff d0                	call   *%eax

f01057c7 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f01057c7:	eb fe                	jmp    f01057c7 <spin>
f01057c9:	8d 76 00             	lea    0x0(%esi),%esi

f01057cc <gdt>:
	...
f01057d4:	ff                   	(bad)  
f01057d5:	ff 00                	incl   (%eax)
f01057d7:	00 00                	add    %al,(%eax)
f01057d9:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f01057e0:	00                   	.byte 0x0
f01057e1:	92                   	xchg   %eax,%edx
f01057e2:	cf                   	iret   
	...

f01057e4 <gdtdesc>:
f01057e4:	17                   	pop    %ss
f01057e5:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f01057ea <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f01057ea:	90                   	nop

f01057eb <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f01057eb:	55                   	push   %ebp
f01057ec:	89 e5                	mov    %esp,%ebp
f01057ee:	57                   	push   %edi
f01057ef:	56                   	push   %esi
f01057f0:	53                   	push   %ebx
f01057f1:	83 ec 0c             	sub    $0xc,%esp
f01057f4:	89 c7                	mov    %eax,%edi
	if (PGNUM(pa) >= npages)
f01057f6:	a1 88 2e 23 f0       	mov    0xf0232e88,%eax
f01057fb:	89 f9                	mov    %edi,%ecx
f01057fd:	c1 e9 0c             	shr    $0xc,%ecx
f0105800:	39 c1                	cmp    %eax,%ecx
f0105802:	73 19                	jae    f010581d <mpsearch1+0x32>
	return (void *)(pa + KERNBASE);
f0105804:	8d 9f 00 00 00 f0    	lea    -0x10000000(%edi),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f010580a:	01 d7                	add    %edx,%edi
	if (PGNUM(pa) >= npages)
f010580c:	89 fa                	mov    %edi,%edx
f010580e:	c1 ea 0c             	shr    $0xc,%edx
f0105811:	39 c2                	cmp    %eax,%edx
f0105813:	73 1a                	jae    f010582f <mpsearch1+0x44>
	return (void *)(pa + KERNBASE);
f0105815:	81 ef 00 00 00 10    	sub    $0x10000000,%edi

	for (; mp < end; mp++)
f010581b:	eb 27                	jmp    f0105844 <mpsearch1+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010581d:	57                   	push   %edi
f010581e:	68 24 62 10 f0       	push   $0xf0106224
f0105823:	6a 57                	push   $0x57
f0105825:	68 41 7e 10 f0       	push   $0xf0107e41
f010582a:	e8 11 a8 ff ff       	call   f0100040 <_panic>
f010582f:	57                   	push   %edi
f0105830:	68 24 62 10 f0       	push   $0xf0106224
f0105835:	6a 57                	push   $0x57
f0105837:	68 41 7e 10 f0       	push   $0xf0107e41
f010583c:	e8 ff a7 ff ff       	call   f0100040 <_panic>
f0105841:	83 c3 10             	add    $0x10,%ebx
f0105844:	39 fb                	cmp    %edi,%ebx
f0105846:	73 30                	jae    f0105878 <mpsearch1+0x8d>
f0105848:	89 de                	mov    %ebx,%esi
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f010584a:	83 ec 04             	sub    $0x4,%esp
f010584d:	6a 04                	push   $0x4
f010584f:	68 51 7e 10 f0       	push   $0xf0107e51
f0105854:	53                   	push   %ebx
f0105855:	e8 d9 fd ff ff       	call   f0105633 <memcmp>
f010585a:	83 c4 10             	add    $0x10,%esp
f010585d:	85 c0                	test   %eax,%eax
f010585f:	75 e0                	jne    f0105841 <mpsearch1+0x56>
f0105861:	89 da                	mov    %ebx,%edx
	for (i = 0; i < len; i++)
f0105863:	83 c6 10             	add    $0x10,%esi
		sum += ((uint8_t *)addr)[i];
f0105866:	0f b6 0a             	movzbl (%edx),%ecx
f0105869:	01 c8                	add    %ecx,%eax
f010586b:	83 c2 01             	add    $0x1,%edx
	for (i = 0; i < len; i++)
f010586e:	39 f2                	cmp    %esi,%edx
f0105870:	75 f4                	jne    f0105866 <mpsearch1+0x7b>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105872:	84 c0                	test   %al,%al
f0105874:	75 cb                	jne    f0105841 <mpsearch1+0x56>
f0105876:	eb 05                	jmp    f010587d <mpsearch1+0x92>
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0105878:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f010587d:	89 d8                	mov    %ebx,%eax
f010587f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105882:	5b                   	pop    %ebx
f0105883:	5e                   	pop    %esi
f0105884:	5f                   	pop    %edi
f0105885:	5d                   	pop    %ebp
f0105886:	c3                   	ret    

f0105887 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105887:	f3 0f 1e fb          	endbr32 
f010588b:	55                   	push   %ebp
f010588c:	89 e5                	mov    %esp,%ebp
f010588e:	57                   	push   %edi
f010588f:	56                   	push   %esi
f0105890:	53                   	push   %ebx
f0105891:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105894:	c7 05 c0 33 23 f0 20 	movl   $0xf0233020,0xf02333c0
f010589b:	30 23 f0 
	if (PGNUM(pa) >= npages)
f010589e:	83 3d 88 2e 23 f0 00 	cmpl   $0x0,0xf0232e88
f01058a5:	0f 84 a3 00 00 00    	je     f010594e <mp_init+0xc7>
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f01058ab:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f01058b2:	85 c0                	test   %eax,%eax
f01058b4:	0f 84 aa 00 00 00    	je     f0105964 <mp_init+0xdd>
		p <<= 4;	// Translate from segment to PA
f01058ba:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f01058bd:	ba 00 04 00 00       	mov    $0x400,%edx
f01058c2:	e8 24 ff ff ff       	call   f01057eb <mpsearch1>
f01058c7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01058ca:	85 c0                	test   %eax,%eax
f01058cc:	75 1a                	jne    f01058e8 <mp_init+0x61>
	return mpsearch1(0xF0000, 0x10000);
f01058ce:	ba 00 00 01 00       	mov    $0x10000,%edx
f01058d3:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f01058d8:	e8 0e ff ff ff       	call   f01057eb <mpsearch1>
f01058dd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if ((mp = mpsearch()) == 0)
f01058e0:	85 c0                	test   %eax,%eax
f01058e2:	0f 84 35 02 00 00    	je     f0105b1d <mp_init+0x296>
	if (mp->physaddr == 0 || mp->type != 0) {
f01058e8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01058eb:	8b 58 04             	mov    0x4(%eax),%ebx
f01058ee:	85 db                	test   %ebx,%ebx
f01058f0:	0f 84 97 00 00 00    	je     f010598d <mp_init+0x106>
f01058f6:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f01058fa:	0f 85 8d 00 00 00    	jne    f010598d <mp_init+0x106>
f0105900:	89 d8                	mov    %ebx,%eax
f0105902:	c1 e8 0c             	shr    $0xc,%eax
f0105905:	3b 05 88 2e 23 f0    	cmp    0xf0232e88,%eax
f010590b:	0f 83 91 00 00 00    	jae    f01059a2 <mp_init+0x11b>
	return (void *)(pa + KERNBASE);
f0105911:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
f0105917:	89 de                	mov    %ebx,%esi
	if (memcmp(conf, "PCMP", 4) != 0) {
f0105919:	83 ec 04             	sub    $0x4,%esp
f010591c:	6a 04                	push   $0x4
f010591e:	68 56 7e 10 f0       	push   $0xf0107e56
f0105923:	53                   	push   %ebx
f0105924:	e8 0a fd ff ff       	call   f0105633 <memcmp>
f0105929:	83 c4 10             	add    $0x10,%esp
f010592c:	85 c0                	test   %eax,%eax
f010592e:	0f 85 83 00 00 00    	jne    f01059b7 <mp_init+0x130>
f0105934:	0f b7 7b 04          	movzwl 0x4(%ebx),%edi
f0105938:	01 df                	add    %ebx,%edi
	sum = 0;
f010593a:	89 c2                	mov    %eax,%edx
	for (i = 0; i < len; i++)
f010593c:	39 fb                	cmp    %edi,%ebx
f010593e:	0f 84 88 00 00 00    	je     f01059cc <mp_init+0x145>
		sum += ((uint8_t *)addr)[i];
f0105944:	0f b6 0b             	movzbl (%ebx),%ecx
f0105947:	01 ca                	add    %ecx,%edx
f0105949:	83 c3 01             	add    $0x1,%ebx
f010594c:	eb ee                	jmp    f010593c <mp_init+0xb5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010594e:	68 00 04 00 00       	push   $0x400
f0105953:	68 24 62 10 f0       	push   $0xf0106224
f0105958:	6a 6f                	push   $0x6f
f010595a:	68 41 7e 10 f0       	push   $0xf0107e41
f010595f:	e8 dc a6 ff ff       	call   f0100040 <_panic>
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0105964:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f010596b:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f010596e:	2d 00 04 00 00       	sub    $0x400,%eax
f0105973:	ba 00 04 00 00       	mov    $0x400,%edx
f0105978:	e8 6e fe ff ff       	call   f01057eb <mpsearch1>
f010597d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105980:	85 c0                	test   %eax,%eax
f0105982:	0f 85 60 ff ff ff    	jne    f01058e8 <mp_init+0x61>
f0105988:	e9 41 ff ff ff       	jmp    f01058ce <mp_init+0x47>
		cprintf("SMP: Default configurations not implemented\n");
f010598d:	83 ec 0c             	sub    $0xc,%esp
f0105990:	68 b4 7c 10 f0       	push   $0xf0107cb4
f0105995:	e8 33 e0 ff ff       	call   f01039cd <cprintf>
		return NULL;
f010599a:	83 c4 10             	add    $0x10,%esp
f010599d:	e9 7b 01 00 00       	jmp    f0105b1d <mp_init+0x296>
f01059a2:	53                   	push   %ebx
f01059a3:	68 24 62 10 f0       	push   $0xf0106224
f01059a8:	68 90 00 00 00       	push   $0x90
f01059ad:	68 41 7e 10 f0       	push   $0xf0107e41
f01059b2:	e8 89 a6 ff ff       	call   f0100040 <_panic>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01059b7:	83 ec 0c             	sub    $0xc,%esp
f01059ba:	68 e4 7c 10 f0       	push   $0xf0107ce4
f01059bf:	e8 09 e0 ff ff       	call   f01039cd <cprintf>
		return NULL;
f01059c4:	83 c4 10             	add    $0x10,%esp
f01059c7:	e9 51 01 00 00       	jmp    f0105b1d <mp_init+0x296>
	if (sum(conf, conf->length) != 0) {
f01059cc:	84 d2                	test   %dl,%dl
f01059ce:	75 22                	jne    f01059f2 <mp_init+0x16b>
	if (conf->version != 1 && conf->version != 4) {
f01059d0:	0f b6 56 06          	movzbl 0x6(%esi),%edx
f01059d4:	80 fa 01             	cmp    $0x1,%dl
f01059d7:	74 05                	je     f01059de <mp_init+0x157>
f01059d9:	80 fa 04             	cmp    $0x4,%dl
f01059dc:	75 29                	jne    f0105a07 <mp_init+0x180>
f01059de:	0f b7 4e 28          	movzwl 0x28(%esi),%ecx
f01059e2:	01 d9                	add    %ebx,%ecx
	for (i = 0; i < len; i++)
f01059e4:	39 d9                	cmp    %ebx,%ecx
f01059e6:	74 38                	je     f0105a20 <mp_init+0x199>
		sum += ((uint8_t *)addr)[i];
f01059e8:	0f b6 13             	movzbl (%ebx),%edx
f01059eb:	01 d0                	add    %edx,%eax
f01059ed:	83 c3 01             	add    $0x1,%ebx
f01059f0:	eb f2                	jmp    f01059e4 <mp_init+0x15d>
		cprintf("SMP: Bad MP configuration checksum\n");
f01059f2:	83 ec 0c             	sub    $0xc,%esp
f01059f5:	68 18 7d 10 f0       	push   $0xf0107d18
f01059fa:	e8 ce df ff ff       	call   f01039cd <cprintf>
		return NULL;
f01059ff:	83 c4 10             	add    $0x10,%esp
f0105a02:	e9 16 01 00 00       	jmp    f0105b1d <mp_init+0x296>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105a07:	83 ec 08             	sub    $0x8,%esp
f0105a0a:	0f b6 d2             	movzbl %dl,%edx
f0105a0d:	52                   	push   %edx
f0105a0e:	68 3c 7d 10 f0       	push   $0xf0107d3c
f0105a13:	e8 b5 df ff ff       	call   f01039cd <cprintf>
		return NULL;
f0105a18:	83 c4 10             	add    $0x10,%esp
f0105a1b:	e9 fd 00 00 00       	jmp    f0105b1d <mp_init+0x296>
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105a20:	02 46 2a             	add    0x2a(%esi),%al
f0105a23:	75 1c                	jne    f0105a41 <mp_init+0x1ba>
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
f0105a25:	c7 05 00 30 23 f0 01 	movl   $0x1,0xf0233000
f0105a2c:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105a2f:	8b 46 24             	mov    0x24(%esi),%eax
f0105a32:	a3 00 40 27 f0       	mov    %eax,0xf0274000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105a37:	8d 7e 2c             	lea    0x2c(%esi),%edi
f0105a3a:	bb 00 00 00 00       	mov    $0x0,%ebx
f0105a3f:	eb 4d                	jmp    f0105a8e <mp_init+0x207>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105a41:	83 ec 0c             	sub    $0xc,%esp
f0105a44:	68 5c 7d 10 f0       	push   $0xf0107d5c
f0105a49:	e8 7f df ff ff       	call   f01039cd <cprintf>
		return NULL;
f0105a4e:	83 c4 10             	add    $0x10,%esp
f0105a51:	e9 c7 00 00 00       	jmp    f0105b1d <mp_init+0x296>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0105a56:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0105a5a:	74 11                	je     f0105a6d <mp_init+0x1e6>
				bootcpu = &cpus[ncpu];
f0105a5c:	6b 05 c4 33 23 f0 74 	imul   $0x74,0xf02333c4,%eax
f0105a63:	05 20 30 23 f0       	add    $0xf0233020,%eax
f0105a68:	a3 c0 33 23 f0       	mov    %eax,0xf02333c0
			if (ncpu < NCPU) {
f0105a6d:	a1 c4 33 23 f0       	mov    0xf02333c4,%eax
f0105a72:	83 f8 07             	cmp    $0x7,%eax
f0105a75:	7f 33                	jg     f0105aaa <mp_init+0x223>
				cpus[ncpu].cpu_id = ncpu;
f0105a77:	6b d0 74             	imul   $0x74,%eax,%edx
f0105a7a:	88 82 20 30 23 f0    	mov    %al,-0xfdccfe0(%edx)
				ncpu++;
f0105a80:	83 c0 01             	add    $0x1,%eax
f0105a83:	a3 c4 33 23 f0       	mov    %eax,0xf02333c4
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105a88:	83 c7 14             	add    $0x14,%edi
	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105a8b:	83 c3 01             	add    $0x1,%ebx
f0105a8e:	0f b7 46 22          	movzwl 0x22(%esi),%eax
f0105a92:	39 d8                	cmp    %ebx,%eax
f0105a94:	76 4f                	jbe    f0105ae5 <mp_init+0x25e>
		switch (*p) {
f0105a96:	0f b6 07             	movzbl (%edi),%eax
f0105a99:	84 c0                	test   %al,%al
f0105a9b:	74 b9                	je     f0105a56 <mp_init+0x1cf>
f0105a9d:	8d 50 ff             	lea    -0x1(%eax),%edx
f0105aa0:	80 fa 03             	cmp    $0x3,%dl
f0105aa3:	77 1c                	ja     f0105ac1 <mp_init+0x23a>
			continue;
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105aa5:	83 c7 08             	add    $0x8,%edi
			continue;
f0105aa8:	eb e1                	jmp    f0105a8b <mp_init+0x204>
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105aaa:	83 ec 08             	sub    $0x8,%esp
f0105aad:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0105ab1:	50                   	push   %eax
f0105ab2:	68 8c 7d 10 f0       	push   $0xf0107d8c
f0105ab7:	e8 11 df ff ff       	call   f01039cd <cprintf>
f0105abc:	83 c4 10             	add    $0x10,%esp
f0105abf:	eb c7                	jmp    f0105a88 <mp_init+0x201>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105ac1:	83 ec 08             	sub    $0x8,%esp
		switch (*p) {
f0105ac4:	0f b6 c0             	movzbl %al,%eax
			cprintf("mpinit: unknown config type %x\n", *p);
f0105ac7:	50                   	push   %eax
f0105ac8:	68 b4 7d 10 f0       	push   $0xf0107db4
f0105acd:	e8 fb de ff ff       	call   f01039cd <cprintf>
			ismp = 0;
f0105ad2:	c7 05 00 30 23 f0 00 	movl   $0x0,0xf0233000
f0105ad9:	00 00 00 
			i = conf->entry;
f0105adc:	0f b7 5e 22          	movzwl 0x22(%esi),%ebx
f0105ae0:	83 c4 10             	add    $0x10,%esp
f0105ae3:	eb a6                	jmp    f0105a8b <mp_init+0x204>
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105ae5:	a1 c0 33 23 f0       	mov    0xf02333c0,%eax
f0105aea:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0105af1:	83 3d 00 30 23 f0 00 	cmpl   $0x0,0xf0233000
f0105af8:	74 2b                	je     f0105b25 <mp_init+0x29e>
		ncpu = 1;
		lapicaddr = 0;
		cprintf("SMP: configuration not found, SMP disabled\n");
		return;
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0105afa:	83 ec 04             	sub    $0x4,%esp
f0105afd:	ff 35 c4 33 23 f0    	pushl  0xf02333c4
f0105b03:	0f b6 00             	movzbl (%eax),%eax
f0105b06:	50                   	push   %eax
f0105b07:	68 5b 7e 10 f0       	push   $0xf0107e5b
f0105b0c:	e8 bc de ff ff       	call   f01039cd <cprintf>

	if (mp->imcrp) {
f0105b11:	83 c4 10             	add    $0x10,%esp
f0105b14:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105b17:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105b1b:	75 2e                	jne    f0105b4b <mp_init+0x2c4>
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f0105b1d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105b20:	5b                   	pop    %ebx
f0105b21:	5e                   	pop    %esi
f0105b22:	5f                   	pop    %edi
f0105b23:	5d                   	pop    %ebp
f0105b24:	c3                   	ret    
		ncpu = 1;
f0105b25:	c7 05 c4 33 23 f0 01 	movl   $0x1,0xf02333c4
f0105b2c:	00 00 00 
		lapicaddr = 0;
f0105b2f:	c7 05 00 40 27 f0 00 	movl   $0x0,0xf0274000
f0105b36:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105b39:	83 ec 0c             	sub    $0xc,%esp
f0105b3c:	68 d4 7d 10 f0       	push   $0xf0107dd4
f0105b41:	e8 87 de ff ff       	call   f01039cd <cprintf>
		return;
f0105b46:	83 c4 10             	add    $0x10,%esp
f0105b49:	eb d2                	jmp    f0105b1d <mp_init+0x296>
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105b4b:	83 ec 0c             	sub    $0xc,%esp
f0105b4e:	68 00 7e 10 f0       	push   $0xf0107e00
f0105b53:	e8 75 de ff ff       	call   f01039cd <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105b58:	b8 70 00 00 00       	mov    $0x70,%eax
f0105b5d:	ba 22 00 00 00       	mov    $0x22,%edx
f0105b62:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0105b63:	ba 23 00 00 00       	mov    $0x23,%edx
f0105b68:	ec                   	in     (%dx),%al
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0105b69:	83 c8 01             	or     $0x1,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105b6c:	ee                   	out    %al,(%dx)
}
f0105b6d:	83 c4 10             	add    $0x10,%esp
f0105b70:	eb ab                	jmp    f0105b1d <mp_init+0x296>

f0105b72 <lapicw>:
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
	lapic[index] = value;
f0105b72:	8b 0d 04 40 27 f0    	mov    0xf0274004,%ecx
f0105b78:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0105b7b:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105b7d:	a1 04 40 27 f0       	mov    0xf0274004,%eax
f0105b82:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105b85:	c3                   	ret    

f0105b86 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0105b86:	f3 0f 1e fb          	endbr32 
	if (lapic)
f0105b8a:	8b 15 04 40 27 f0    	mov    0xf0274004,%edx
		return lapic[ID] >> 24;
	return 0;
f0105b90:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lapic)
f0105b95:	85 d2                	test   %edx,%edx
f0105b97:	74 06                	je     f0105b9f <cpunum+0x19>
		return lapic[ID] >> 24;
f0105b99:	8b 42 20             	mov    0x20(%edx),%eax
f0105b9c:	c1 e8 18             	shr    $0x18,%eax
}
f0105b9f:	c3                   	ret    

f0105ba0 <lapic_init>:
{
f0105ba0:	f3 0f 1e fb          	endbr32 
	if (!lapicaddr)
f0105ba4:	a1 00 40 27 f0       	mov    0xf0274000,%eax
f0105ba9:	85 c0                	test   %eax,%eax
f0105bab:	75 01                	jne    f0105bae <lapic_init+0xe>
f0105bad:	c3                   	ret    
{
f0105bae:	55                   	push   %ebp
f0105baf:	89 e5                	mov    %esp,%ebp
f0105bb1:	83 ec 10             	sub    $0x10,%esp
	lapic = mmio_map_region(lapicaddr, 4096);
f0105bb4:	68 00 10 00 00       	push   $0x1000
f0105bb9:	50                   	push   %eax
f0105bba:	e8 f2 b6 ff ff       	call   f01012b1 <mmio_map_region>
f0105bbf:	a3 04 40 27 f0       	mov    %eax,0xf0274004
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105bc4:	ba 27 01 00 00       	mov    $0x127,%edx
f0105bc9:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105bce:	e8 9f ff ff ff       	call   f0105b72 <lapicw>
	lapicw(TDCR, X1);
f0105bd3:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105bd8:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105bdd:	e8 90 ff ff ff       	call   f0105b72 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105be2:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105be7:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105bec:	e8 81 ff ff ff       	call   f0105b72 <lapicw>
	lapicw(TICR, 10000000); 
f0105bf1:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105bf6:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105bfb:	e8 72 ff ff ff       	call   f0105b72 <lapicw>
	if (thiscpu != bootcpu)
f0105c00:	e8 81 ff ff ff       	call   f0105b86 <cpunum>
f0105c05:	6b c0 74             	imul   $0x74,%eax,%eax
f0105c08:	05 20 30 23 f0       	add    $0xf0233020,%eax
f0105c0d:	83 c4 10             	add    $0x10,%esp
f0105c10:	39 05 c0 33 23 f0    	cmp    %eax,0xf02333c0
f0105c16:	74 0f                	je     f0105c27 <lapic_init+0x87>
		lapicw(LINT0, MASKED);
f0105c18:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105c1d:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105c22:	e8 4b ff ff ff       	call   f0105b72 <lapicw>
	lapicw(LINT1, MASKED);
f0105c27:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105c2c:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105c31:	e8 3c ff ff ff       	call   f0105b72 <lapicw>
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105c36:	a1 04 40 27 f0       	mov    0xf0274004,%eax
f0105c3b:	8b 40 30             	mov    0x30(%eax),%eax
f0105c3e:	c1 e8 10             	shr    $0x10,%eax
f0105c41:	a8 fc                	test   $0xfc,%al
f0105c43:	75 7c                	jne    f0105cc1 <lapic_init+0x121>
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105c45:	ba 33 00 00 00       	mov    $0x33,%edx
f0105c4a:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105c4f:	e8 1e ff ff ff       	call   f0105b72 <lapicw>
	lapicw(ESR, 0);
f0105c54:	ba 00 00 00 00       	mov    $0x0,%edx
f0105c59:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105c5e:	e8 0f ff ff ff       	call   f0105b72 <lapicw>
	lapicw(ESR, 0);
f0105c63:	ba 00 00 00 00       	mov    $0x0,%edx
f0105c68:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105c6d:	e8 00 ff ff ff       	call   f0105b72 <lapicw>
	lapicw(EOI, 0);
f0105c72:	ba 00 00 00 00       	mov    $0x0,%edx
f0105c77:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105c7c:	e8 f1 fe ff ff       	call   f0105b72 <lapicw>
	lapicw(ICRHI, 0);
f0105c81:	ba 00 00 00 00       	mov    $0x0,%edx
f0105c86:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105c8b:	e8 e2 fe ff ff       	call   f0105b72 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105c90:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105c95:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c9a:	e8 d3 fe ff ff       	call   f0105b72 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105c9f:	8b 15 04 40 27 f0    	mov    0xf0274004,%edx
f0105ca5:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105cab:	f6 c4 10             	test   $0x10,%ah
f0105cae:	75 f5                	jne    f0105ca5 <lapic_init+0x105>
	lapicw(TPR, 0);
f0105cb0:	ba 00 00 00 00       	mov    $0x0,%edx
f0105cb5:	b8 20 00 00 00       	mov    $0x20,%eax
f0105cba:	e8 b3 fe ff ff       	call   f0105b72 <lapicw>
}
f0105cbf:	c9                   	leave  
f0105cc0:	c3                   	ret    
		lapicw(PCINT, MASKED);
f0105cc1:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105cc6:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105ccb:	e8 a2 fe ff ff       	call   f0105b72 <lapicw>
f0105cd0:	e9 70 ff ff ff       	jmp    f0105c45 <lapic_init+0xa5>

f0105cd5 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105cd5:	f3 0f 1e fb          	endbr32 
	if (lapic)
f0105cd9:	83 3d 04 40 27 f0 00 	cmpl   $0x0,0xf0274004
f0105ce0:	74 17                	je     f0105cf9 <lapic_eoi+0x24>
{
f0105ce2:	55                   	push   %ebp
f0105ce3:	89 e5                	mov    %esp,%ebp
f0105ce5:	83 ec 08             	sub    $0x8,%esp
		lapicw(EOI, 0);
f0105ce8:	ba 00 00 00 00       	mov    $0x0,%edx
f0105ced:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105cf2:	e8 7b fe ff ff       	call   f0105b72 <lapicw>
}
f0105cf7:	c9                   	leave  
f0105cf8:	c3                   	ret    
f0105cf9:	c3                   	ret    

f0105cfa <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105cfa:	f3 0f 1e fb          	endbr32 
f0105cfe:	55                   	push   %ebp
f0105cff:	89 e5                	mov    %esp,%ebp
f0105d01:	56                   	push   %esi
f0105d02:	53                   	push   %ebx
f0105d03:	8b 75 08             	mov    0x8(%ebp),%esi
f0105d06:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105d09:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105d0e:	ba 70 00 00 00       	mov    $0x70,%edx
f0105d13:	ee                   	out    %al,(%dx)
f0105d14:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105d19:	ba 71 00 00 00       	mov    $0x71,%edx
f0105d1e:	ee                   	out    %al,(%dx)
	if (PGNUM(pa) >= npages)
f0105d1f:	83 3d 88 2e 23 f0 00 	cmpl   $0x0,0xf0232e88
f0105d26:	74 7e                	je     f0105da6 <lapic_startap+0xac>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105d28:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105d2f:	00 00 
	wrv[1] = addr >> 4;
f0105d31:	89 d8                	mov    %ebx,%eax
f0105d33:	c1 e8 04             	shr    $0x4,%eax
f0105d36:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105d3c:	c1 e6 18             	shl    $0x18,%esi
f0105d3f:	89 f2                	mov    %esi,%edx
f0105d41:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105d46:	e8 27 fe ff ff       	call   f0105b72 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105d4b:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105d50:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105d55:	e8 18 fe ff ff       	call   f0105b72 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105d5a:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105d5f:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105d64:	e8 09 fe ff ff       	call   f0105b72 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105d69:	c1 eb 0c             	shr    $0xc,%ebx
f0105d6c:	80 cf 06             	or     $0x6,%bh
		lapicw(ICRHI, apicid << 24);
f0105d6f:	89 f2                	mov    %esi,%edx
f0105d71:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105d76:	e8 f7 fd ff ff       	call   f0105b72 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105d7b:	89 da                	mov    %ebx,%edx
f0105d7d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105d82:	e8 eb fd ff ff       	call   f0105b72 <lapicw>
		lapicw(ICRHI, apicid << 24);
f0105d87:	89 f2                	mov    %esi,%edx
f0105d89:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105d8e:	e8 df fd ff ff       	call   f0105b72 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105d93:	89 da                	mov    %ebx,%edx
f0105d95:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105d9a:	e8 d3 fd ff ff       	call   f0105b72 <lapicw>
		microdelay(200);
	}
}
f0105d9f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105da2:	5b                   	pop    %ebx
f0105da3:	5e                   	pop    %esi
f0105da4:	5d                   	pop    %ebp
f0105da5:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105da6:	68 67 04 00 00       	push   $0x467
f0105dab:	68 24 62 10 f0       	push   $0xf0106224
f0105db0:	68 98 00 00 00       	push   $0x98
f0105db5:	68 78 7e 10 f0       	push   $0xf0107e78
f0105dba:	e8 81 a2 ff ff       	call   f0100040 <_panic>

f0105dbf <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105dbf:	f3 0f 1e fb          	endbr32 
f0105dc3:	55                   	push   %ebp
f0105dc4:	89 e5                	mov    %esp,%ebp
f0105dc6:	83 ec 08             	sub    $0x8,%esp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105dc9:	8b 55 08             	mov    0x8(%ebp),%edx
f0105dcc:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105dd2:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105dd7:	e8 96 fd ff ff       	call   f0105b72 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105ddc:	8b 15 04 40 27 f0    	mov    0xf0274004,%edx
f0105de2:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105de8:	f6 c4 10             	test   $0x10,%ah
f0105deb:	75 f5                	jne    f0105de2 <lapic_ipi+0x23>
		;
}
f0105ded:	c9                   	leave  
f0105dee:	c3                   	ret    

f0105def <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105def:	f3 0f 1e fb          	endbr32 
f0105df3:	55                   	push   %ebp
f0105df4:	89 e5                	mov    %esp,%ebp
f0105df6:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105df9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105dff:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105e02:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105e05:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105e0c:	5d                   	pop    %ebp
f0105e0d:	c3                   	ret    

f0105e0e <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105e0e:	f3 0f 1e fb          	endbr32 
f0105e12:	55                   	push   %ebp
f0105e13:	89 e5                	mov    %esp,%ebp
f0105e15:	56                   	push   %esi
f0105e16:	53                   	push   %ebx
f0105e17:	8b 5d 08             	mov    0x8(%ebp),%ebx
	return lock->locked && lock->cpu == thiscpu;
f0105e1a:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105e1d:	75 07                	jne    f0105e26 <spin_lock+0x18>
	asm volatile("lock; xchgl %0, %1"
f0105e1f:	ba 01 00 00 00       	mov    $0x1,%edx
f0105e24:	eb 34                	jmp    f0105e5a <spin_lock+0x4c>
f0105e26:	8b 73 08             	mov    0x8(%ebx),%esi
f0105e29:	e8 58 fd ff ff       	call   f0105b86 <cpunum>
f0105e2e:	6b c0 74             	imul   $0x74,%eax,%eax
f0105e31:	05 20 30 23 f0       	add    $0xf0233020,%eax
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105e36:	39 c6                	cmp    %eax,%esi
f0105e38:	75 e5                	jne    f0105e1f <spin_lock+0x11>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105e3a:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105e3d:	e8 44 fd ff ff       	call   f0105b86 <cpunum>
f0105e42:	83 ec 0c             	sub    $0xc,%esp
f0105e45:	53                   	push   %ebx
f0105e46:	50                   	push   %eax
f0105e47:	68 88 7e 10 f0       	push   $0xf0107e88
f0105e4c:	6a 41                	push   $0x41
f0105e4e:	68 ea 7e 10 f0       	push   $0xf0107eea
f0105e53:	e8 e8 a1 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105e58:	f3 90                	pause  
f0105e5a:	89 d0                	mov    %edx,%eax
f0105e5c:	f0 87 03             	lock xchg %eax,(%ebx)
	while (xchg(&lk->locked, 1) != 0)
f0105e5f:	85 c0                	test   %eax,%eax
f0105e61:	75 f5                	jne    f0105e58 <spin_lock+0x4a>

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105e63:	e8 1e fd ff ff       	call   f0105b86 <cpunum>
f0105e68:	6b c0 74             	imul   $0x74,%eax,%eax
f0105e6b:	05 20 30 23 f0       	add    $0xf0233020,%eax
f0105e70:	89 43 08             	mov    %eax,0x8(%ebx)
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0105e73:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f0105e75:	b8 00 00 00 00       	mov    $0x0,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105e7a:	83 f8 09             	cmp    $0x9,%eax
f0105e7d:	7f 21                	jg     f0105ea0 <spin_lock+0x92>
f0105e7f:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105e85:	76 19                	jbe    f0105ea0 <spin_lock+0x92>
		pcs[i] = ebp[1];          // saved %eip
f0105e87:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105e8a:	89 4c 83 0c          	mov    %ecx,0xc(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105e8e:	8b 12                	mov    (%edx),%edx
	for (i = 0; i < 10; i++){
f0105e90:	83 c0 01             	add    $0x1,%eax
f0105e93:	eb e5                	jmp    f0105e7a <spin_lock+0x6c>
		pcs[i] = 0;
f0105e95:	c7 44 83 0c 00 00 00 	movl   $0x0,0xc(%ebx,%eax,4)
f0105e9c:	00 
	for (; i < 10; i++)
f0105e9d:	83 c0 01             	add    $0x1,%eax
f0105ea0:	83 f8 09             	cmp    $0x9,%eax
f0105ea3:	7e f0                	jle    f0105e95 <spin_lock+0x87>
	get_caller_pcs(lk->pcs);
#endif
}
f0105ea5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105ea8:	5b                   	pop    %ebx
f0105ea9:	5e                   	pop    %esi
f0105eaa:	5d                   	pop    %ebp
f0105eab:	c3                   	ret    

f0105eac <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105eac:	f3 0f 1e fb          	endbr32 
f0105eb0:	55                   	push   %ebp
f0105eb1:	89 e5                	mov    %esp,%ebp
f0105eb3:	57                   	push   %edi
f0105eb4:	56                   	push   %esi
f0105eb5:	53                   	push   %ebx
f0105eb6:	83 ec 4c             	sub    $0x4c,%esp
f0105eb9:	8b 75 08             	mov    0x8(%ebp),%esi
	return lock->locked && lock->cpu == thiscpu;
f0105ebc:	83 3e 00             	cmpl   $0x0,(%esi)
f0105ebf:	75 35                	jne    f0105ef6 <spin_unlock+0x4a>
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105ec1:	83 ec 04             	sub    $0x4,%esp
f0105ec4:	6a 28                	push   $0x28
f0105ec6:	8d 46 0c             	lea    0xc(%esi),%eax
f0105ec9:	50                   	push   %eax
f0105eca:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105ecd:	53                   	push   %ebx
f0105ece:	e8 e0 f6 ff ff       	call   f01055b3 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105ed3:	8b 46 08             	mov    0x8(%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105ed6:	0f b6 38             	movzbl (%eax),%edi
f0105ed9:	8b 76 04             	mov    0x4(%esi),%esi
f0105edc:	e8 a5 fc ff ff       	call   f0105b86 <cpunum>
f0105ee1:	57                   	push   %edi
f0105ee2:	56                   	push   %esi
f0105ee3:	50                   	push   %eax
f0105ee4:	68 b4 7e 10 f0       	push   $0xf0107eb4
f0105ee9:	e8 df da ff ff       	call   f01039cd <cprintf>
f0105eee:	83 c4 20             	add    $0x20,%esp
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105ef1:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105ef4:	eb 4e                	jmp    f0105f44 <spin_unlock+0x98>
	return lock->locked && lock->cpu == thiscpu;
f0105ef6:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105ef9:	e8 88 fc ff ff       	call   f0105b86 <cpunum>
f0105efe:	6b c0 74             	imul   $0x74,%eax,%eax
f0105f01:	05 20 30 23 f0       	add    $0xf0233020,%eax
	if (!holding(lk)) {
f0105f06:	39 c3                	cmp    %eax,%ebx
f0105f08:	75 b7                	jne    f0105ec1 <spin_unlock+0x15>
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
	}

	lk->pcs[0] = 0;
f0105f0a:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105f11:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
	asm volatile("lock; xchgl %0, %1"
f0105f18:	b8 00 00 00 00       	mov    $0x0,%eax
f0105f1d:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0105f20:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105f23:	5b                   	pop    %ebx
f0105f24:	5e                   	pop    %esi
f0105f25:	5f                   	pop    %edi
f0105f26:	5d                   	pop    %ebp
f0105f27:	c3                   	ret    
				cprintf("  %08x\n", pcs[i]);
f0105f28:	83 ec 08             	sub    $0x8,%esp
f0105f2b:	ff 36                	pushl  (%esi)
f0105f2d:	68 11 7f 10 f0       	push   $0xf0107f11
f0105f32:	e8 96 da ff ff       	call   f01039cd <cprintf>
f0105f37:	83 c4 10             	add    $0x10,%esp
f0105f3a:	83 c3 04             	add    $0x4,%ebx
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105f3d:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105f40:	39 c3                	cmp    %eax,%ebx
f0105f42:	74 40                	je     f0105f84 <spin_unlock+0xd8>
f0105f44:	89 de                	mov    %ebx,%esi
f0105f46:	8b 03                	mov    (%ebx),%eax
f0105f48:	85 c0                	test   %eax,%eax
f0105f4a:	74 38                	je     f0105f84 <spin_unlock+0xd8>
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105f4c:	83 ec 08             	sub    $0x8,%esp
f0105f4f:	57                   	push   %edi
f0105f50:	50                   	push   %eax
f0105f51:	e8 d8 ea ff ff       	call   f0104a2e <debuginfo_eip>
f0105f56:	83 c4 10             	add    $0x10,%esp
f0105f59:	85 c0                	test   %eax,%eax
f0105f5b:	78 cb                	js     f0105f28 <spin_unlock+0x7c>
					pcs[i] - info.eip_fn_addr);
f0105f5d:	8b 06                	mov    (%esi),%eax
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105f5f:	83 ec 04             	sub    $0x4,%esp
f0105f62:	89 c2                	mov    %eax,%edx
f0105f64:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105f67:	52                   	push   %edx
f0105f68:	ff 75 b0             	pushl  -0x50(%ebp)
f0105f6b:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105f6e:	ff 75 ac             	pushl  -0x54(%ebp)
f0105f71:	ff 75 a8             	pushl  -0x58(%ebp)
f0105f74:	50                   	push   %eax
f0105f75:	68 fa 7e 10 f0       	push   $0xf0107efa
f0105f7a:	e8 4e da ff ff       	call   f01039cd <cprintf>
f0105f7f:	83 c4 20             	add    $0x20,%esp
f0105f82:	eb b6                	jmp    f0105f3a <spin_unlock+0x8e>
		panic("spin_unlock");
f0105f84:	83 ec 04             	sub    $0x4,%esp
f0105f87:	68 19 7f 10 f0       	push   $0xf0107f19
f0105f8c:	6a 67                	push   $0x67
f0105f8e:	68 ea 7e 10 f0       	push   $0xf0107eea
f0105f93:	e8 a8 a0 ff ff       	call   f0100040 <_panic>
f0105f98:	66 90                	xchg   %ax,%ax
f0105f9a:	66 90                	xchg   %ax,%ax
f0105f9c:	66 90                	xchg   %ax,%ax
f0105f9e:	66 90                	xchg   %ax,%ax

f0105fa0 <__udivdi3>:
f0105fa0:	f3 0f 1e fb          	endbr32 
f0105fa4:	55                   	push   %ebp
f0105fa5:	57                   	push   %edi
f0105fa6:	56                   	push   %esi
f0105fa7:	53                   	push   %ebx
f0105fa8:	83 ec 1c             	sub    $0x1c,%esp
f0105fab:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0105faf:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0105fb3:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105fb7:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0105fbb:	85 d2                	test   %edx,%edx
f0105fbd:	75 19                	jne    f0105fd8 <__udivdi3+0x38>
f0105fbf:	39 f3                	cmp    %esi,%ebx
f0105fc1:	76 4d                	jbe    f0106010 <__udivdi3+0x70>
f0105fc3:	31 ff                	xor    %edi,%edi
f0105fc5:	89 e8                	mov    %ebp,%eax
f0105fc7:	89 f2                	mov    %esi,%edx
f0105fc9:	f7 f3                	div    %ebx
f0105fcb:	89 fa                	mov    %edi,%edx
f0105fcd:	83 c4 1c             	add    $0x1c,%esp
f0105fd0:	5b                   	pop    %ebx
f0105fd1:	5e                   	pop    %esi
f0105fd2:	5f                   	pop    %edi
f0105fd3:	5d                   	pop    %ebp
f0105fd4:	c3                   	ret    
f0105fd5:	8d 76 00             	lea    0x0(%esi),%esi
f0105fd8:	39 f2                	cmp    %esi,%edx
f0105fda:	76 14                	jbe    f0105ff0 <__udivdi3+0x50>
f0105fdc:	31 ff                	xor    %edi,%edi
f0105fde:	31 c0                	xor    %eax,%eax
f0105fe0:	89 fa                	mov    %edi,%edx
f0105fe2:	83 c4 1c             	add    $0x1c,%esp
f0105fe5:	5b                   	pop    %ebx
f0105fe6:	5e                   	pop    %esi
f0105fe7:	5f                   	pop    %edi
f0105fe8:	5d                   	pop    %ebp
f0105fe9:	c3                   	ret    
f0105fea:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105ff0:	0f bd fa             	bsr    %edx,%edi
f0105ff3:	83 f7 1f             	xor    $0x1f,%edi
f0105ff6:	75 48                	jne    f0106040 <__udivdi3+0xa0>
f0105ff8:	39 f2                	cmp    %esi,%edx
f0105ffa:	72 06                	jb     f0106002 <__udivdi3+0x62>
f0105ffc:	31 c0                	xor    %eax,%eax
f0105ffe:	39 eb                	cmp    %ebp,%ebx
f0106000:	77 de                	ja     f0105fe0 <__udivdi3+0x40>
f0106002:	b8 01 00 00 00       	mov    $0x1,%eax
f0106007:	eb d7                	jmp    f0105fe0 <__udivdi3+0x40>
f0106009:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106010:	89 d9                	mov    %ebx,%ecx
f0106012:	85 db                	test   %ebx,%ebx
f0106014:	75 0b                	jne    f0106021 <__udivdi3+0x81>
f0106016:	b8 01 00 00 00       	mov    $0x1,%eax
f010601b:	31 d2                	xor    %edx,%edx
f010601d:	f7 f3                	div    %ebx
f010601f:	89 c1                	mov    %eax,%ecx
f0106021:	31 d2                	xor    %edx,%edx
f0106023:	89 f0                	mov    %esi,%eax
f0106025:	f7 f1                	div    %ecx
f0106027:	89 c6                	mov    %eax,%esi
f0106029:	89 e8                	mov    %ebp,%eax
f010602b:	89 f7                	mov    %esi,%edi
f010602d:	f7 f1                	div    %ecx
f010602f:	89 fa                	mov    %edi,%edx
f0106031:	83 c4 1c             	add    $0x1c,%esp
f0106034:	5b                   	pop    %ebx
f0106035:	5e                   	pop    %esi
f0106036:	5f                   	pop    %edi
f0106037:	5d                   	pop    %ebp
f0106038:	c3                   	ret    
f0106039:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106040:	89 f9                	mov    %edi,%ecx
f0106042:	b8 20 00 00 00       	mov    $0x20,%eax
f0106047:	29 f8                	sub    %edi,%eax
f0106049:	d3 e2                	shl    %cl,%edx
f010604b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010604f:	89 c1                	mov    %eax,%ecx
f0106051:	89 da                	mov    %ebx,%edx
f0106053:	d3 ea                	shr    %cl,%edx
f0106055:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0106059:	09 d1                	or     %edx,%ecx
f010605b:	89 f2                	mov    %esi,%edx
f010605d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106061:	89 f9                	mov    %edi,%ecx
f0106063:	d3 e3                	shl    %cl,%ebx
f0106065:	89 c1                	mov    %eax,%ecx
f0106067:	d3 ea                	shr    %cl,%edx
f0106069:	89 f9                	mov    %edi,%ecx
f010606b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010606f:	89 eb                	mov    %ebp,%ebx
f0106071:	d3 e6                	shl    %cl,%esi
f0106073:	89 c1                	mov    %eax,%ecx
f0106075:	d3 eb                	shr    %cl,%ebx
f0106077:	09 de                	or     %ebx,%esi
f0106079:	89 f0                	mov    %esi,%eax
f010607b:	f7 74 24 08          	divl   0x8(%esp)
f010607f:	89 d6                	mov    %edx,%esi
f0106081:	89 c3                	mov    %eax,%ebx
f0106083:	f7 64 24 0c          	mull   0xc(%esp)
f0106087:	39 d6                	cmp    %edx,%esi
f0106089:	72 15                	jb     f01060a0 <__udivdi3+0x100>
f010608b:	89 f9                	mov    %edi,%ecx
f010608d:	d3 e5                	shl    %cl,%ebp
f010608f:	39 c5                	cmp    %eax,%ebp
f0106091:	73 04                	jae    f0106097 <__udivdi3+0xf7>
f0106093:	39 d6                	cmp    %edx,%esi
f0106095:	74 09                	je     f01060a0 <__udivdi3+0x100>
f0106097:	89 d8                	mov    %ebx,%eax
f0106099:	31 ff                	xor    %edi,%edi
f010609b:	e9 40 ff ff ff       	jmp    f0105fe0 <__udivdi3+0x40>
f01060a0:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01060a3:	31 ff                	xor    %edi,%edi
f01060a5:	e9 36 ff ff ff       	jmp    f0105fe0 <__udivdi3+0x40>
f01060aa:	66 90                	xchg   %ax,%ax
f01060ac:	66 90                	xchg   %ax,%ax
f01060ae:	66 90                	xchg   %ax,%ax

f01060b0 <__umoddi3>:
f01060b0:	f3 0f 1e fb          	endbr32 
f01060b4:	55                   	push   %ebp
f01060b5:	57                   	push   %edi
f01060b6:	56                   	push   %esi
f01060b7:	53                   	push   %ebx
f01060b8:	83 ec 1c             	sub    $0x1c,%esp
f01060bb:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f01060bf:	8b 74 24 30          	mov    0x30(%esp),%esi
f01060c3:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f01060c7:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01060cb:	85 c0                	test   %eax,%eax
f01060cd:	75 19                	jne    f01060e8 <__umoddi3+0x38>
f01060cf:	39 df                	cmp    %ebx,%edi
f01060d1:	76 5d                	jbe    f0106130 <__umoddi3+0x80>
f01060d3:	89 f0                	mov    %esi,%eax
f01060d5:	89 da                	mov    %ebx,%edx
f01060d7:	f7 f7                	div    %edi
f01060d9:	89 d0                	mov    %edx,%eax
f01060db:	31 d2                	xor    %edx,%edx
f01060dd:	83 c4 1c             	add    $0x1c,%esp
f01060e0:	5b                   	pop    %ebx
f01060e1:	5e                   	pop    %esi
f01060e2:	5f                   	pop    %edi
f01060e3:	5d                   	pop    %ebp
f01060e4:	c3                   	ret    
f01060e5:	8d 76 00             	lea    0x0(%esi),%esi
f01060e8:	89 f2                	mov    %esi,%edx
f01060ea:	39 d8                	cmp    %ebx,%eax
f01060ec:	76 12                	jbe    f0106100 <__umoddi3+0x50>
f01060ee:	89 f0                	mov    %esi,%eax
f01060f0:	89 da                	mov    %ebx,%edx
f01060f2:	83 c4 1c             	add    $0x1c,%esp
f01060f5:	5b                   	pop    %ebx
f01060f6:	5e                   	pop    %esi
f01060f7:	5f                   	pop    %edi
f01060f8:	5d                   	pop    %ebp
f01060f9:	c3                   	ret    
f01060fa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0106100:	0f bd e8             	bsr    %eax,%ebp
f0106103:	83 f5 1f             	xor    $0x1f,%ebp
f0106106:	75 50                	jne    f0106158 <__umoddi3+0xa8>
f0106108:	39 d8                	cmp    %ebx,%eax
f010610a:	0f 82 e0 00 00 00    	jb     f01061f0 <__umoddi3+0x140>
f0106110:	89 d9                	mov    %ebx,%ecx
f0106112:	39 f7                	cmp    %esi,%edi
f0106114:	0f 86 d6 00 00 00    	jbe    f01061f0 <__umoddi3+0x140>
f010611a:	89 d0                	mov    %edx,%eax
f010611c:	89 ca                	mov    %ecx,%edx
f010611e:	83 c4 1c             	add    $0x1c,%esp
f0106121:	5b                   	pop    %ebx
f0106122:	5e                   	pop    %esi
f0106123:	5f                   	pop    %edi
f0106124:	5d                   	pop    %ebp
f0106125:	c3                   	ret    
f0106126:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f010612d:	8d 76 00             	lea    0x0(%esi),%esi
f0106130:	89 fd                	mov    %edi,%ebp
f0106132:	85 ff                	test   %edi,%edi
f0106134:	75 0b                	jne    f0106141 <__umoddi3+0x91>
f0106136:	b8 01 00 00 00       	mov    $0x1,%eax
f010613b:	31 d2                	xor    %edx,%edx
f010613d:	f7 f7                	div    %edi
f010613f:	89 c5                	mov    %eax,%ebp
f0106141:	89 d8                	mov    %ebx,%eax
f0106143:	31 d2                	xor    %edx,%edx
f0106145:	f7 f5                	div    %ebp
f0106147:	89 f0                	mov    %esi,%eax
f0106149:	f7 f5                	div    %ebp
f010614b:	89 d0                	mov    %edx,%eax
f010614d:	31 d2                	xor    %edx,%edx
f010614f:	eb 8c                	jmp    f01060dd <__umoddi3+0x2d>
f0106151:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106158:	89 e9                	mov    %ebp,%ecx
f010615a:	ba 20 00 00 00       	mov    $0x20,%edx
f010615f:	29 ea                	sub    %ebp,%edx
f0106161:	d3 e0                	shl    %cl,%eax
f0106163:	89 44 24 08          	mov    %eax,0x8(%esp)
f0106167:	89 d1                	mov    %edx,%ecx
f0106169:	89 f8                	mov    %edi,%eax
f010616b:	d3 e8                	shr    %cl,%eax
f010616d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0106171:	89 54 24 04          	mov    %edx,0x4(%esp)
f0106175:	8b 54 24 04          	mov    0x4(%esp),%edx
f0106179:	09 c1                	or     %eax,%ecx
f010617b:	89 d8                	mov    %ebx,%eax
f010617d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106181:	89 e9                	mov    %ebp,%ecx
f0106183:	d3 e7                	shl    %cl,%edi
f0106185:	89 d1                	mov    %edx,%ecx
f0106187:	d3 e8                	shr    %cl,%eax
f0106189:	89 e9                	mov    %ebp,%ecx
f010618b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010618f:	d3 e3                	shl    %cl,%ebx
f0106191:	89 c7                	mov    %eax,%edi
f0106193:	89 d1                	mov    %edx,%ecx
f0106195:	89 f0                	mov    %esi,%eax
f0106197:	d3 e8                	shr    %cl,%eax
f0106199:	89 e9                	mov    %ebp,%ecx
f010619b:	89 fa                	mov    %edi,%edx
f010619d:	d3 e6                	shl    %cl,%esi
f010619f:	09 d8                	or     %ebx,%eax
f01061a1:	f7 74 24 08          	divl   0x8(%esp)
f01061a5:	89 d1                	mov    %edx,%ecx
f01061a7:	89 f3                	mov    %esi,%ebx
f01061a9:	f7 64 24 0c          	mull   0xc(%esp)
f01061ad:	89 c6                	mov    %eax,%esi
f01061af:	89 d7                	mov    %edx,%edi
f01061b1:	39 d1                	cmp    %edx,%ecx
f01061b3:	72 06                	jb     f01061bb <__umoddi3+0x10b>
f01061b5:	75 10                	jne    f01061c7 <__umoddi3+0x117>
f01061b7:	39 c3                	cmp    %eax,%ebx
f01061b9:	73 0c                	jae    f01061c7 <__umoddi3+0x117>
f01061bb:	2b 44 24 0c          	sub    0xc(%esp),%eax
f01061bf:	1b 54 24 08          	sbb    0x8(%esp),%edx
f01061c3:	89 d7                	mov    %edx,%edi
f01061c5:	89 c6                	mov    %eax,%esi
f01061c7:	89 ca                	mov    %ecx,%edx
f01061c9:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01061ce:	29 f3                	sub    %esi,%ebx
f01061d0:	19 fa                	sbb    %edi,%edx
f01061d2:	89 d0                	mov    %edx,%eax
f01061d4:	d3 e0                	shl    %cl,%eax
f01061d6:	89 e9                	mov    %ebp,%ecx
f01061d8:	d3 eb                	shr    %cl,%ebx
f01061da:	d3 ea                	shr    %cl,%edx
f01061dc:	09 d8                	or     %ebx,%eax
f01061de:	83 c4 1c             	add    $0x1c,%esp
f01061e1:	5b                   	pop    %ebx
f01061e2:	5e                   	pop    %esi
f01061e3:	5f                   	pop    %edi
f01061e4:	5d                   	pop    %ebp
f01061e5:	c3                   	ret    
f01061e6:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01061ed:	8d 76 00             	lea    0x0(%esi),%esi
f01061f0:	29 fe                	sub    %edi,%esi
f01061f2:	19 c3                	sbb    %eax,%ebx
f01061f4:	89 f2                	mov    %esi,%edx
f01061f6:	89 d9                	mov    %ebx,%ecx
f01061f8:	e9 1d ff ff ff       	jmp    f010611a <__umoddi3+0x6a>
