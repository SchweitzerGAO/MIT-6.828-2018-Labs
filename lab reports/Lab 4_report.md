# Lab 4 Report——抢占式多任务（进程管理）

[TOC]

## 实验内容

1. 多处理器支持
2. 轮转法调度
3. 创建环境的系统调用
4. 用户级缺页错误处理
5. 实现Copy-on-write-fork
6. 时钟中断和抢占
7. 进程间通信（IPC）

## 实验步骤

### 1. 多处理器支持

#### 1. AP(Application Processor)启动

就是实现`kern/pmap.c`中的`mmio_map_region()`函数，这个函数将LAPIC（Local Advanced Programmable Interrupt Controller）使用的MMIO（Memory-Mapped I/O）映射到虚拟地址上，同时要将新占用的页进行标记，实现如下：

```c
// in "kern/pmap.c"
void *
mmio_map_region(physaddr_t pa, size_t size)
{
	// Where to start the next region.  Initially, this is the
	// beginning of the MMIO region.  Because this is static, its
	// value will be preserved between calls to mmio_map_region
	// (just like nextfree in boot_alloc).
	static uintptr_t base = MMIOBASE;

	// Reserve size bytes of virtual memory starting at base and
	// map physical pages [pa,pa+size) to virtual addresses
	// [base,base+size).  Since this is device memory and not
	// regular DRAM, you'll have to tell the CPU that it isn't
	// safe to cache access to this memory.  Luckily, the page
	// tables provide bits for this purpose; simply create the
	// mapping with PTE_PCD|PTE_PWT (cache-disable and
	// write-through) in addition to PTE_W.  (If you're interested
	// in more details on this, see section 10.5 of IA32 volume
	// 3A.)
	//
	// Be sure to round size up to a multiple of PGSIZE and to
	// handle if this reservation would overflow MMIOLIM (it's
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	// panic("mmio_map_region not implemented");
	size = ROUNDUP(pa+size,PGSIZE);
	pa = ROUNDDOWN(pa,PGSIZE);
	size-=pa;
	if(size+base>=MMIOLIM)
	{
		panic("At mmio_map_region(): overflow MMIOLIM");
	}
	boot_map_region(kern_pgdir,base,size,pa,PTE_W|PTE_PCD|PTE_PWT);
	base+=size;
	return (void*)(base-size);
}

// in function page_init() add

// map MPENTRY_PADDR as used
	size_t mpentry = MPENTRY_PADDR/PGSIZE;
// map the MPENTRY as used
		else if(i == mpentry)
		{
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
		}
```

#### 2. 分CPU状态及初始化

这个部分把所有CPU的地址进行映射并处理多CPU状态下的陷阱(trap)，代码实现如下：

```c
// in "kern/pmap.c"
static void
mem_init_mp(void)
{
	// Map per-CPU stacks starting at KSTACKTOP, for up to 'NCPU' CPUs.
	//
	// For CPU i, use the physical memory that 'percpu_kstacks[i]' refers
	// to as its kernel stack. CPU i's kernel stack grows down from virtual
	// address kstacktop_i = KSTACKTOP - i * (KSTKSIZE + KSTKGAP), and is
	// divided into two pieces, just like the single stack you set up in
	// mem_init:
	//     * [kstacktop_i - KSTKSIZE, kstacktop_i)
	//          -- backed by physical memory
	//     * [kstacktop_i - (KSTKSIZE + KSTKGAP), kstacktop_i - KSTKSIZE)
	//          -- not backed; so if the kernel overflows its stack,
	//             it will fault rather than overwrite another CPU's stack.
	//             Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	for(int i = 0;i<NCPU;i++)
	{
		uintptr_t kstacktop_i = (KSTACKTOP-KSTKSIZE)-i*(KSTKSIZE+KSTKGAP);
		physaddr_t pa = PADDR(percpu_kstacks[i]);
		boot_map_region(kern_pgdir,kstacktop_i,KSTKSIZE,pa,PTE_W|PTE_P);
	}

}

// in "kern/trap.c"
// modified by the hint
// Hints:
	//   - The macro "thiscpu" always refers to the current CPU's
	//     struct CpuInfo;
	//   - The ID of the current CPU is given by cpunum() or
	//     thiscpu->cpu_id;
	//   - Use "thiscpu->cpu_ts" as the TSS for the current CPU,
	//     rather than the global "ts" variable;
	//   - Use gdt[(GD_TSS0 >> 3) + i] for CPU i's TSS descriptor;
	//   - You mapped the per-CPU kernel stacks in mem_init_mp()
	//   - Initialize cpu_ts.ts_iomb to prevent unauthorized environments
	//     from doing IO (0 is not the correct value!)
	//
	// ltr sets a 'busy' flag in the TSS selector, so if you
	// accidentally load the same TSS on more than one CPU, you'll
	// get a triple fault.  If you set up an individual CPU's TSS
	// wrong, you may not get a fault until you try to return from
	// user space on that CPU.
	//
	// LAB 4: Your code here:
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	uint8_t id = thiscpu->cpu_id;
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP-id*(KSTKSIZE+KSTKGAP);
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
	thiscpu->cpu_ts.ts_iomb = sizeof(struct Taskstate);

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+id] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3)+id].sd_s = 0;

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0+(id<<3));

	// Load the IDT
	lidt(&idt_pd);
```

运行结果如下：

![4-1](../images/4-1.png)

### 2. 轮转法调度

#### 1. 锁函数调用

这一部分在一些函数中调用`lock_kernel()`及`unlock_kernel()`来实现加锁以及释放锁，类似于理论课上的信号量机制，只不过这个锁只是一个互斥信号量，共4处调用如下：

```c
// in "kern/init.c" function i386_init()

// Acquire the big kernel lock before waking up APs
// Your code here:
	lock_kernel();
// Starting non-boot CPUs
	boot_aps();

// in "kern/init.c" function mp_main()

// Now that we have finished some basic setup, call sched_yield()
// to start running processes on this CPU.  But make sure that
// only one CPU can enter the scheduler at a time!
//
// Your code here:
	lock_kernel();
	sched_yield();

// in "kern/trap.c" function trap()

if ((tf->tf_cs & 3) == 3) {
	// Trapped from user mode.
	// Acquire the big kernel lock before doing any
	// serious kernel work.
	// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);

// in "kern/env.c" function env_run() the position of this function is vital

// switch to user page directory
	lcr3(PADDR(curenv->env_pgdir));
	unlock_kernel();
// step 2
	env_pop_tf(&curenv->env_tf);
```



#### 2. 轮转法调度(RR)函数实现

轮转法调度相较FCFS,SJF等方法，理论课上提得较少，实验正好弥补了这一块，这个函数的主要思想是从当前环境（如果存在）开始，循环地查找`envs`数组，直到找到一个可以运行的环境为止。实现如下：

```c
void
sched_yield(void)
{
	struct Env *idle;

	// Implement simple round-robin scheduling.
	//
	// Search through 'envs' for an ENV_RUNNABLE environment in
	// circular fashion starting just after the env this CPU was
	// last running.  Switch to the first such environment found.
	//
	// If no envs are runnable, but the environment previously
	// running on this CPU is still ENV_RUNNING, it's okay to
	// choose that environment.
	//
	// Never choose an environment that's currently running on
	// another CPU (env_status == ENV_RUNNING). If there are
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.
	// LAB 4: Your code here.
	// start point of searching
	int begin = 0;
	// flag
	bool flag = false;
	if(curenv)
	{
		begin = ENVX(curenv->env_id);
	}
	// search the next runnable env(R&R)
	for(int i = 0;i<NENV;i++)
	{
		idle = &envs[(i+begin)%NENV];
		if(idle->env_status == ENV_RUNNABLE)
		{
			flag = true;
			env_run(idle);
			break;
		}
	}
	if(!flag && curenv && curenv->env_status == ENV_RUNNING)
	{
		env_run(curenv);
	}
	// sched_halt never returns
	if(!flag)
	{
		sched_halt();
	}
}

```

测试成功，达到多用户环境互斥运行的效果：

![4-2](../images/4-2.png)

### 3. 创建环境的系统调用

这一部分实现一系列系统调用函数，实际除了前两个函数之外，都是Lab 2中有关页及页表管理函数的系统调用封装，写的时候主要进行一些边界条件判断（在注释中给出），调用Lab 2中实现的接口即可。各个函数实现如下：

**`sys_exofork()`函数**

```c
static envid_t
sys_exofork(void)
{
	// Create the new environment with env_alloc(), from kern/env.c.
	// It should be left as env_alloc created it, except that
	// status is set to ENV_NOT_RUNNABLE, and the register set is copied
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.

	// LAB 4: Your code here.
	// panic("sys_exofork not implemented");
	struct Env* store_env = NULL;
	// allocate environment
	int ret = env_alloc(&store_env,curenv->env_id);
	if(ret < 0)
	{
		return ret;
	}
	// set attributes according to hint
	store_env->env_status = ENV_NOT_RUNNABLE;
	store_env->env_tf = curenv->env_tf;
	store_env->env_tf.tf_regs.reg_eax = 0;
	return store_env->env_id;
}
```

**`sys_env_set_status()`函数**

```c
static int
sys_env_set_status(envid_t envid, int status)
{
	// Hint: Use the 'envid2env' function from kern/env.c to translate an
	// envid to a struct Env.
	// You should set envid2env's third argument to 1, which will
	// check whether the current environment has permission to set
	// envid's status.

	// LAB 4: Your code here.
	// panic("sys_env_set_status not implemented");
	if(status != ENV_NOT_RUNNABLE && status!= ENV_RUNNABLE)
	{
		return -E_INVAL;
	}
	struct Env* e = NULL;
	int ret = envid2env(envid,&e,true);
	if(ret < 0)
	{
		return ret;
	}
	e->env_status = status;
	return 0;
}
```

**`sys_page_alloc()`函数**

```c
static int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	// Hint: This function is a wrapper around page_alloc() and
	//   page_insert() from kern/pmap.c.
	//   Most of the new code you write should be to check the
	//   parameters for correctness.
	//   If page_insert() fails, remember to free the page you
	//   allocated!

	// LAB 4: Your code here.
	// panic("sys_page_alloc not implemented");
	// -E_INVAL if va >= UTOP, or va is not page-aligned.
	if((uintptr_t)va >= UTOP || (uintptr_t)va % PGSIZE)
	{
		return -E_INVAL;
	}
	
	// -E_INVAL if perm is inappropriate
	int needed_perm = PTE_U|PTE_P;
	if((perm & ~(PTE_SYSCALL)) || ((perm & needed_perm) != needed_perm))
	{
		return -E_INVAL;
	}

	struct Env* e = NULL;
	int ret = envid2env(envid,&e,true);
	if(ret<0)
	{
		return ret;
	}
	struct PageInfo* pg = page_alloc(ALLOC_ZERO);
    
	// -E_NO_MEM if there's no memory to allocate the new page
	if(!pg)
	{
		return -E_NO_MEM;
	}

	// or to allocate any necessary page tables
	ret = page_insert(e->env_pgdir,pg,va,perm);
	if(ret < 0)
	{
		page_free(pg);
		return ret;
	}
	return 0;

}
```

**`sys_page_map()`函数**

```c
sys_page_map(envid_t srcenvid, void *srcva,
	     envid_t dstenvid, void *dstva, int perm)
{
	// Hint: This function is a wrapper around page_lookup() and
	//   page_insert() from kern/pmap.c.
	//   Again, most of the new code you write should be to check the
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.
	// LAB 4: Your code here.
	// panic("sys_page_map not implemented");
	if((uintptr_t)srcva>=UTOP || (uintptr_t)srcva % PGSIZE 
	|| (uintptr_t)dstva>=UTOP || (uintptr_t)dstva % PGSIZE)
	{
		return -E_INVAL;
	}

	int needed_perm = PTE_U|PTE_P;
	if((perm & ~(PTE_SYSCALL)) || ((perm & needed_perm) != needed_perm))
	{
		return -E_INVAL;
	}

	struct Env* srce = NULL, *dste = NULL;
	int ret = envid2env(srcenvid,&srce,true);
	if(ret < 0)
	{
		return ret;
	}
	ret = envid2env(dstenvid,&dste,true);
	if(ret < 0)
	{
		return ret;
	}
	// -E_INVAL is srcva is not mapped in srcenvid's address space
	pte_t* pte = NULL;
	struct PageInfo* pg = page_lookup(srce->env_pgdir,srcva,&pte);
	if(!pg)
	{
		return -E_INVAL;
	}

	// -E_INVAL if (perm & PTE_W), but srcva is read-only in srcenvid's
    //		address space.
	if((!((*pte) & PTE_W)) && (perm & PTE_W))
	{
		return -E_INVAL;
	}

	ret = page_insert(dste->env_pgdir,pg,dstva,perm);
	if(ret < 0)
	{
		return ret;
	}
	return 0;
}
```

**`sys_page_unmap()`函数**

```c
static int
sys_page_unmap(envid_t envid, void *va)
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	// panic("sys_page_unmap not implemented");
	if((uintptr_t)va >= UTOP || (uintptr_t)va % PGSIZE)
	{
		return -E_INVAL;
	}
	struct Env* e = NULL;

	int ret = envid2env(envid,&e,true);
	if(ret < 0)
	{
		return ret;
	}
	page_remove(e->env_pgdir,va);
	return 0;
}
```



## 实验收获

