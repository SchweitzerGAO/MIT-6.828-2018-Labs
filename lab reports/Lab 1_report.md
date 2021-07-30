# Lab 1 Report——搭建环境&启动

[TOC]

## 实验内容

1. 拉取lab代码，编译
2. 使用gdb中的`si`命令单步调试代码
3. Boot Loader设置断点，追踪指令
4. 内核相关

## 实验步骤

### 1. 拉取代码，编译

拉取代码：

```shell
git clone https://pdos.csail.mit.edu/6.828/2018/jos.git lab
```

编译过程中需要注意，在/conf文件夹里的env.mk去掉最后一行的注释，添加qemu-system-i386的文件路径，否则会报错。如下：

```makefile
QEMU=/home/charles/qemu/bin/qemu-system-i386
```

### 2. 使用gdb中的`si`命令单步调试代码(1-2)

在使用`make qemu-gdb`以及`make gdb`之后，看到的第一条指令是

```assembly
1. [f000:fff0]    0xffff0:	ljmp   $0xf000,$0xe05b
```

左边方括号中是段基址和偏移量，由这两个数值计算出后面的`0xffff0`。同时由后面的`0xf000`和`0xe05b`计算出跳转的目标地址。这两个地址的计算方式是相同的——由于目前的虚拟机是运行在实模式下的，且CPU地址地址总线是20位，寄存器是16位，所以需要将段基址左移4位再与偏移量相加。则有`0xf000<<4+fff0=0xfff0`以及`0xf000<<4+0xe05b=0xfe05b`

下一条指令是

```assembly
2. [f000:e05b]    0xfe05b:	cmpl   $0x0,%cs:0x6ac8
```

这是将`0x0`与CS寄存器中地址为`0x6ac8`中的值做比较，看是否相等

下一条指令

```assembly
3. [f000:e062]    0xfe062:	jne    0xfd2e1
```

顺序执行，可以看到这一条指令为8位，占1个字节，若第2条指令比较相等，则跳转，否则不跳转

下一条指令

```assembly
4. [f000:e066]    0xfe066:	xor    %dx,%dx
```

可见没有跳转，且上一条指令为4位，此条指令清空`dx`寄存器，因为一个数与自己进行异或运算得到0

下面5-9指令进行一些赋值与跳转

第10条指令是关中断指令

```assembly
10. [f000:d15f]    0xfd15f:	cli  
```

作用是关闭中断，操作系统启动时是肯定不会中断的

下一条指令为cld指令

```assembly
11. [f000:d160]    0xfd160:	cld  
```

查阅资料得知这条指令可以将串操作（字符串的操作）的内存地址走向改为低地址到高地址。

下面一些指令涉及IO端口的操作

```assembly
12. [f000:d161]    0xfd161:	mov    $0x8f,%eax
13. [f000:d167]    0xfd167:	out    %al,$0x70
14. [f000:d169]    0xfd169:	in     $0x71,%al
```

其中out指令的格式是

```assembly
out PortAddress,%al ; 将寄存器al中的值读入端口号为PortAddress的端口
```

in指令与之相似

```assembly
in %al, PortAddress ; 将端口号为PortAddress中的值读入寄存器al中
```

这几条指令是把NMI终端给关掉，并访问0xF(0x8f=0b10001111，前四位关中断，后四位访问0xF)

接下去的3条指令操作I/O 0x92端口

```assembly
15. [f000:d16b]    0xfd16b:  in  $0x92, %al
16. [f000:d16d]    0xfd16d:  or  $0x2, %al
17. [f000:d16f]    0xfd16f:	out  %al,$0x92
```

查阅资料可知，这可以开启A20端口，工作在保护模式下

下面一条指令加载、读入中断向量表寄存器(IDTR)

```assembly
18. [f000:d171]    0xfd171:	lidtw  %cs:0x6ab8
```

下面一条指令将数据加载到GDTR中

```assembly
19. [f000:d177]    0xfd177：lgdtw  %cs:0x6a74
```

下面几条指令测试保护模式是否能够正常运行

```assembly
20. [f000:d17d]    0xfd17d:	mov    %cr0,%eax
21. [f000:d180]    0xfd180:	or     $0x1,%eax
22. [f000:d184]    0xfd184:	mov    %eax,%cr0
```

后面的指令重置一些寄存器的值，并且进入i386运行。

### 3.BootLoader设置断点，追踪指令(3-6)

1.

在GDB 中使用指令`b *0x7c00`在0x7c00处设置断点,然后使用`c`让指令执行到断点处。为了查看反汇编过后的指令，使用`x/30i 0x7c00`，这条指令输出从0x7c00开始，后面30字节的指令的反汇编，结果如下图

![image-20210722220611191](C:\Users\gaoyangfan\AppData\Roaming\Typora\typora-user-images\image-20210722220611191.png)

再与boot/boot.S 和 obj/boot/boot.asm进行对比，发现反汇编过后的代码是一致的。

2.回答部分问题

(1)`readsect()`中每句C代码对应的汇编：

首先是`readsect()`函数:

```c
void
readsect(void *dst, uint32_t offset)
{
	// wait for disk to be ready
	waitdisk(); 

	outb(0x1F2, 1);		// count = 1
	outb(0x1F3, offset);
	outb(0x1F4, offset >> 8);
	outb(0x1F5, offset >> 16);
	outb(0x1F6, (offset >> 24) | 0xE0);
	outb(0x1F7, 0x20);	// cmd 0x20 - read sectors

	// wait for disk to be ready
	waitdisk();

	// read a sector
	insl(0x1F0, dst, SECTSIZE/4);
}
```
从上至下对应的汇编代码分别为：(/obj/kern/boot.asm)
```assembly
; waitdisk()
7c88:	e8 dd ff ff ff       	call   7c6a <waitdisk> 

; outb(0x1F2, 1)
7c8d:	b0 01                	mov    $0x1,%al
7c8f:	ba f2 01 00 00       	mov    $0x1f2,%edx
7c94:	ee                   	out    %al,(%dx)

; outb(0x1F3, offset)
7c95:	ba f3 01 00 00       	mov    $0x1f3,%edx
7c9a:	89 c8                	mov    %ecx,%eax
7c9c:	ee                   	out    %al,(%dx)

; outb(0x1F4, offset >> 8)
7c9d:	89 c8                	mov    %ecx,%eax
7c9f:	ba f4 01 00 00       	mov    $0x1f4,%edx
7ca4:	c1 e8 08             	shr    $0x8,%eax
7ca7:	ee                   	out    %al,(%dx)

; outb(0x1F5, offset >> 16)
7ca8:	89 c8                	mov    %ecx,%eax
7caa:	ba f5 01 00 00       	mov    $0x1f5,%edx
7caf:	c1 e8 10             	shr    $0x10,%eax
7cb2:	ee                   	out    %al,(%dx)

; outb(0x1F6, (offset >> 24) | 0xE0)
7cb3:	89 c8                	mov    %ecx,%eax
7cb5:	ba f6 01 00 00       	mov    $0x1f6,%edx
7cba:	c1 e8 18             	shr    $0x18,%eax
7cbd:	83 c8 e0             	or     $0xffffffe0,%eax
7cc0:	ee                   	out    %al,(%dx)

; outb(0x1F7, 0x20)
7cc1:	b0 20                	mov    $0x20,%al
7cc3:	ba f7 01 00 00       	mov    $0x1f7,%edx
7cc8:	ee                   	out    %al,(%dx)

; waitdisk()
7cc9:	e8 9c ff ff ff       	call   7c6a <waitdisk>

; insl(0x1F0, dst, SECTSIZE/4)
7cce:	8b 7d 08             	mov    0x8(%ebp),%edi
7cd1:	b9 80 00 00 00       	mov    $0x80,%ecx
7cd6:	ba f0 01 00 00       	mov    $0x1f0,%edx
7cdb:	fc                   	cld    
7cdc:	f2 6d                	repnz insl (%dx),%es:(%edi)
```

(2) `bootmain()`中`for`循环的起止以及循环完成之后第一条指令

```assembly
; loop start
7d66:	39 f3                	cmp    %esi,%ebx  ; stop condition
7d68:	73 17                	jae    7d81 <bootmain+0x5c> ; stop and jump to next                                                                   ; instruction
; loop body

; jump to the condition judgement
7d7f:	eb e5                	jmp    7d66 <bootmain+0x41>

; the first instruction after loop
7d81:	ff 15 18 00 01 00    	call   *0x10018

```

(3) 引导指令与内核的切换

```assembly
; last instruction of booter
0x7d81:	call   *0x10018

; first instruction of kernel
0x10000c:	movw   $0x1234,0x472
```

### 4. 内核相关(7-12)

1. 虚拟地址映射

按照Exercise7的步骤，执行到指令`movl %eax, %cr0`处停止，查看`0x00100000`处和`0x0f100000`处的内容，执行这条指令之后再次查看，结果如下

![image-20210726105732313](C:\Users\gaoyangfan\AppData\Roaming\Typora\typora-user-images\image-20210726105732313.png)

可见在执行了movl指令之后，虚拟地址被成功映射到物理地址上。

若将这条指令注释掉，重新编译，则在此处会出现错误

![image-20210726111102485](C:\Users\gaoyangfan\AppData\Roaming\Typora\typora-user-images\image-20210726111102485.png)

这是因为注释掉的指令执行的是虚拟地址到物理地址的转换，缺少了这部分，程序就无法正确执行。

2. 格式化控制台输出（类似C中的`printf()`函数）

主要是分析`/kern/printf.c`,`/kern/console.c`及`/lib/printfmt.c`三个文件中的函数，寻找并且补充缺失的代码。经过分析，缺失的代码位于`/lib/printfmt.c`中，是用于处理"%o"也就是八进制格式化输出的代码，可以模仿已经写好的十进制或十六进制输出来写这部分代码，代码如下:

```c
case 'o':
		// Replace this with your code.
		putch('0',putdat);
		num = getuint(&ap, lflag);
		base = 8;
		goto number;
```

回答部分问题:

(1) 在`console.c`中除了被static修饰的函数之外，其他的函数都可以被外部调用。其中`printf.c`中调用的函数是`cputchar()`

(2) 在`console.c`中的`cga_putc()`函数中有这样一段代码，解释作用

```c
// What is the purpose of this?
    // if output over 1 page
	if (crt_pos >= CRT_SIZE) {  // CRT_SIZE = 80*25
		int i;
        // move up 1 
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
        // change the last line to ' '
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
        // modify crt_pos 
		crt_pos -= CRT_COLS;
	}
```

作用已在注释中给出

(3) 执行下面的代码：

```c
int x = 1, y = 3, z = 4;
cprintf("x %d, y %x, z %d\n", x, y, z);
```

运行结果：

![image-20210726131441681](C:\Users\gaoyangfan\AppData\Roaming\Typora\typora-user-images\image-20210726131441681.png)

a. `cprintf()`中 `fmt`指向字符串`"x %d, y %x, z %d\n"`，`ap`指向所有可变参数，更准确地，`ap`指向可变参数的第一个字节

b. 每次运行到"%"之后就会从`ap`中取出一个变量，`ap`的长度也相应改变

(4) 执行下面的代码:

```c
 unsigned int i = 0x00646c72;
 cprintf("H%x Wo%s", 57616, &i);
```

运行结果：

![image-20210726135806356](C:\Users\gaoyangfan\AppData\Roaming\Typora\typora-user-images\image-20210726135806356.png)

解释：

a.`%x`为16进制输出，57616转换为16进制是`e110`,

b. `%s`为字符串输出，由于x86是小端模式，也就是从低位向高位读数据，故将变量`i`拆开，首先是`0x72='r'`,以及`0x6c='l'`,`0x64='d'`,`0x00=''`故输出是'rld'（如果是大端模式，就将`i`颠倒过来，即`i=0x726c6400`）

3. 栈

**初始化:**

栈的初始化是通过以下指令实现的

```assembly
movl	$(bootstacktop),%esp
```

并且初始指针指向栈顶

`mon_backtrace()`**函数的实现**

这个函数打印函数调用，返回的地址以及传给参数的函数，有一个API`read_ebp()`用来读取ebp的值，也就是当前函数调用的地址。实现如下：

```c
uint32_t ebp = read_ebp();                     // call address
int *ebp_base_ptr = (int *)ebp;                // return address
uint32_t eip = ebp_base_ptr[1];   		  
cprintf("ebp %x, eip %x, args ", ebp, eip);

int *args = ebp_base_ptr + 2;                 // go down the stack

for (int i = 0; i < 5; ++i) {             
    cprintf("%x ", args[i]);                 // output arguments
}
cprintf("\n");
```

**注册`backtrace`命令**

在`/kern/monitor.c`中注册命令如下：

```c
static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
	{ "backtrace", "Trace back call stack", mon_backtrace },
};
```

还要显示文件信息，故`mon_backtrace()`还要增加以下代码：

```c
 struct Eipdebuginfo info;                   // debug info
        int ret = debuginfo_eip(eip, &info); 
        cprintf("    at %s: %d: %.*s+%d\n",
                info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);  // output the values
        // update the values
        ebp = *ebp_base_ptr;
        ebp_base_ptr = (int*)ebp;
        eip = ebp_base_ptr[1];
	
```

`mon_backtrace()`完整代码如下:

```c
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
    typedef int (*this_func_type)(int, char **, struct Trapframe *);
	// Your code here.
	uint32_t ebp = read_ebp();
	int *ebp_base_ptr = (int *)ebp;           
	uint32_t eip = ebp_base_ptr[1];   
	while (1) {
        // print address and arguments info
        cprintf("ebp %x, eip %x, args ", ebp, eip);

        int *args = ebp_base_ptr + 2;

        for (int i = 0; i < 5; ++i) {
            cprintf("%x ", args[i]);
        }
        cprintf("\n");
        
        // print file line info 
        struct Eipdebuginfo info;
        
        // there aren't any info?
        int ret = debuginfo_eip(eip, &info);
        cprintf("    at %s: %d: %.*s+%d\n",
                info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
        if (ret) {
            break;
        }
        // update the values
        ebp = *ebp_base_ptr;
        ebp_base_ptr = (int*)ebp;
        eip = ebp_base_ptr[1];
	}

	return 0;
}
```

运行结果如下：

![image-20210726173221539](C:\Users\gaoyangfan\AppData\Roaming\Typora\typora-user-images\image-20210726173221539.png)

至此Lab 1 结束

## 实验收获

1. 基本的汇编代码阅读能力
2. OS引导程序的运行过程
3. OS内核地址映射过程
4. OS中字符输出至控制台函数的实现过程（类似`printf()`函数）
5. OS内核栈的相关知识以及栈回追（backtrack）的方法

**参考资料**

[[1]](https://zhuanlan.zhihu.com/p/168787600)

[[2]](https://www.cnblogs.com/fatsheep9146/p/5079930.html)

