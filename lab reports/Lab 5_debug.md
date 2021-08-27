# Lab 5 Debug

[TOC]

答辩虽然结束了，但是lab5 还是有一点问题，想着解决一下

## Bugs & Solutions

### start-8.23

#### 1. `Werror-address-of-packed-member`

原因：由于源码中的某些结构体使用了GNU C`__attribute__((packed))`特性，这将会使变量存储时以最小对齐方式对齐，取地址时GCC 9会报错

解决方案：

1. 把`((packed))`改成`((aligned(uint32_t)))`，[参考](https://stackoverflow.com/questions/28859127/compiler-warning-when-using-pointers-to-packed-structure-members)
2. 将GNUMakefile中`CFLAGS+=...`这一行中的`-Werror`一项去掉即可

#### 2. `[user, write, not-present]`

这是在exercise 7之后才遇到的问题

原因：目前位置，有很多迷惑的东西。最开始猜测是哪里的`PTE_P`权限忘了加，但是我检查了所有的代码，除了不需要的，并没有忘了加的情况。后面又出了一些问题，经我检测出在这两个地方：

1. 

```c
// in "lib/fd.c" function fd_lookup()
if (!(uvpd[PDX(fd)] & PTE_P) || !(uvpt[PGNUM(fd)] & PTE_P)) {
		if (debug)
			cprintf("[%08x] closed fd %d\n", thisenv->env_id, fdnum);
		return -E_INVAL;
	}
```

这里的条件判断有误，但是找了半天不知道问题出在哪了，甚至`uvpt`和`uvpd`的赋值操作都没有找到。

2. （用了Dorothy的`copy_shared_pages()`函数之后）

```c
// in "kern/syscall.c" function sys_page_map()
if((uintptr_t)srcva>=UTOP || (uintptr_t)srcva % PGSIZE 
	|| (uintptr_t)dstva>=UTOP || (uintptr_t)dstva % PGSIZE)
	{
    	// debug lines
		// cprintf("%08x\n",srcva);
		// cprintf("%08x\n",UTOP);
		// cprintf("return here\n");
		return -E_INVAL;
	}
```

存储溢出了？？？还是我映射错误？他同时还报了存储权限检查错误，是我映射的问题吗？明天从这个地方下手再看看

### 8.24-8.27

又对着网上的博客排查了一遍代码，发现没啥问题啊。现在有这么几种可能：

1. 变量类型的问题
2. 配置的问题
3. 在merge的过程中部分代码丢失的问题。

准备先从第3个开始排查。顺序3->1->2
