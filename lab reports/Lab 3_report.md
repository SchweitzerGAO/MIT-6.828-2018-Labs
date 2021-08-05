# Lab 3 Report——用户环境

[TOC]

## 实验内容

1. 为`envs`分配存储空间并映射
2. 实现`kern/env.c`的一些函数——用户环境初始化

## 实验步骤

### 1. 为`envs`分配存储空间并映射

模仿Lab 2中为`pages`分配空间并映射的步骤，为`envs`分配空间并映射。在`mem_init()`中添加的代码为

```c
// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*)boot_alloc(NENV*sizeof(struct Env));
	memset(envs,0,NENV*sizeof(struct Env));
```

以及

```c
boot_map_region(kern_pgdir,UENVS,PTSIZE,PADDR(envs),PTE_U);	
```

这使得代码能够通过新的`check_kern_pgdir()`函数，结果如下：

![3-1](../images/3-1.png)

**从Lab2 合并之后出现的问题及解决：**

问题：在执行`mem_init()`函数的时候，会报奇怪的错误

`kernel panic at kern/pmap.c:162: PADDR called with invalid kva 00000000`

解决方案：参考了[这篇博客](https://blog.csdn.net/qq_42779423/article/details/108853781)，解决方法是将`kern/kernel.ld`的`.bss`部分改为

```
.bss : {
		PROVIDE(edata = .);
		*(.bss)
		BYTE(0)
	}
	PROVIDE(end = .);
```

就可以了

### 2. 实现`kern/env.c`的一些函数——用户环境初始化

#### 1. `env_init()`函数

这个函数是将`envs`中所有数组加入`env_free_list`链表中，由于要求链表的顺序与数组的顺序一样，要采用头插法，即从数组的最后一个元素开始，每个元素插入到链表的头部,实现如下：

```c
void
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list = NULL;
    // using head-insert to ensure the order in the same way
	for(int i = NENV - 1; i>=0 ;i--)
	{
		envs[i].env_id = 0;
		envs[i].env_status = ENV_FREE;
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}

	// Per-CPU part of the initialization
	env_init_percpu();
}
```

#### 2. `env_setup_vm()`函数

这个函数初始化新的用户环境的页目录表，并且仅设置与操作系统内核相关的页目录项，其中，`UTOP`之下的初始虚拟地址为空。实现如下：

```c
static int
env_setup_vm(struct Env *e)
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;

	// Now, set e->env_pgdir and initialize the page directory.
	//
	// Hint:
	//    - The VA space of all envs is identical above UTOP
	//	(except at UVPT, which we've set below).
	//	See inc/memlayout.h for permissions and layout.
	//	Can you use kern_pgdir as a template?  Hint: Yes.
	//	(Make sure you got the permissions right in Lab 2.)
	//    - The initial VA below UTOP is empty.
	//    - You do not need to make any more calls to page_alloc.
	//    - Note: In general, pp_ref is not maintained for
	//	physical pages mapped only above UTOP, but env_pgdir
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = (pde_t*)page2kva(p);
	p->pp_ref++;

	// below UTOP
	for(int i = 0;i<PDX(UTOP);i++)
	{
		e->env_pgdir[i] = 0;
	}

	// above UTOP
	for(int i = PDX(UTOP);i<NPDENTRIES;i++)
	{
		e->env_pgdir[i] = kern_pgdir[i];
	}
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;

	return 0;
}
```

#### 3. `region_alloc()`函数

这个函数为用户环境分配物理空间，可以逐页进行分配，并且在分配失败时要进行`panic`操作，实现如下：

```c
static void
region_alloc(struct Env *e, void *va, size_t len)
{
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void* start = (void*)ROUNDDOWN((uint32_t)va,PGSIZE);
	void* end = (void*)ROUNDUP((uint32_t)va+len,PGSIZE);

	// corner case 1: too large length
	if(start>end)
	{
		panic("At region_alloc: too large length\n");
	}
	struct PageInfo* p = NULL;

	// allocate PA by the size of a page
	for(void* v = start;v<end;v+=PGSIZE)
	{
		p = page_alloc(0);
		// corner case 2: page allocation failed
		if(p == NULL)
		{
			panic("At region_alloc: Page allocation failed");
		}

		// insert into page table
		int insert = page_insert(e->env_pgdir,p,v,PTE_W|PTE_U);

		// corner case 3: insertion failed
		if(insert!=0)
		{
			panic("At region_alloc: Page insertion failed");
		}
	}
}
```



## 实验收获