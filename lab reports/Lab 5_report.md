# Lab 5 Report

[TOC]

## 实验内容

1. 开启硬盘访问
2. 块Cache
3. 块位图
4. 文件操作
5. 文件系统接口
6. 进程的spawn操作
7. 键盘接口
8. Shell

## 实验步骤

### 1. 开启硬盘访问

这一部分需要在`env_create()`函数中添加判断语句，具体如下：

```c
// in "kern/env.c"
// If this is the file server (type == ENV_TYPE_FS) give it I/O privileges.
	// LAB 5: Your code here.
	if(type == ENV_TYPE_FS)
	{
		e->env_tf.tf_eflags |= FL_IOPL_MASK;
	}
	e->env_type = type;
```

### 2.块Cache

这一部分实现在块Cache（Block Cache）上的缺页错误处理`bc_pgfault()`函数；以及对块Cache的刷新`flush_block()`函数，实现如下：

```c
static void
bc_pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t blockno = ((uint32_t)addr - DISKMAP) / BLKSIZE;
	int r;

	// Check that the fault was within the block cache region
	if (addr < (void*)DISKMAP || addr >= (void*)(DISKMAP + DISKSIZE))
		panic("page fault in FS: eip %08x, va %08x, err %04x",
		      utf->utf_eip, addr, utf->utf_err);

	// Sanity check the block number.
	if (super && blockno >= super->s_nblocks)
		panic("reading non-existent block %08x\n", blockno);

	// Allocate a page in the disk map region, read the contents
	// of the block from the disk into that page.
	// Hint: first round addr to page boundary. fs/ide.c has code to read
	// the disk.
	//
	// LAB 5: you code here:
	addr = (void*)ROUNDDOWN(addr,BLKSIZE);

	// allocate the page
	r = sys_page_alloc(0,addr,PTE_P|PTE_W|PTE_U);
	if(r < 0)
	{
		panic("At bc_pgfault sys_page_alloc:%e",r);
	}
	// read the block in (operate in sectors not blocks)
	r = ide_read(blockno*BLKSECTS,addr,BLKSECTS);
	if(r < 0)
	{
		panic("At bc_pgfault ide_read:%e",r);
	}
	// Clear the dirty bit for the disk block page since we just read the
	// block from disk
	if ((r = sys_page_map(0, addr, 0, addr, uvpt[PGNUM(addr)] & PTE_SYSCALL)) < 0)
		panic("in bc_pgfault, sys_page_map: %e", r);

	// Check that the block we read was allocated. (exercise for
	// the reader: why do we do this *after* reading the block
	// in?)
	if (bitmap && block_is_free(blockno))
		panic("reading free block %08x\n", blockno);
}


void
flush_block(void *addr)
{
	uint32_t blockno = ((uint32_t)addr - DISKMAP) / BLKSIZE;

	if (addr < (void*)DISKMAP || addr >= (void*)(DISKMAP + DISKSIZE))
		panic("flush_block of bad va %08x", addr);

	// LAB 5: Your code here.
	// panic("flush_block not implemented");
	addr = (void*)ROUNDDOWN(addr,BLKSIZE);
	if(!va_is_mapped(addr))
	{
		return;
	}
	if(!va_is_dirty(addr))
	{
		return;
	}
	int ret;

	// write into the block
	ret = ide_write(blockno<<3,addr,8);
	if(ret < 0)
	{
		panic("At flush_block ide_write:%e",ret);
	}
	// clear dirty flag in page table 
	ret = sys_page_map(0,addr,0,addr,uvpt[PGNUM(addr)]&PTE_SYSCALL);
	if(ret < 0)
	{
		panic("At flush_block sys_page_map:%e",ret);
	}
}
```

### 3. 块位图

这一部分实现FCB的分配，其中FCB的状态是以位图的形式存储的，实现如下：

```c
int
alloc_block(void)
{
	// The bitmap consists of one or more blocks.  A single bitmap block
	// contains the in-use bits for BLKBITSIZE blocks.  There are
	// super->s_nblocks blocks in the disk altogether.

	// LAB 5: Your code here.
	// panic("alloc_block not implemented");

	// search a free block
	for(uint32_t blkno = 0;blkno < super->s_nblocks;blkno++)
	{
		if(block_is_free(blkno))
		{
			// use free_block as template
			bitmap[blkno/32] &= ~(1<<(blkno%32));
			// immediately flush the bitmap block
			flush_block(&bitmap[blkno/32]);
			return blkno;
		}
	}

	return -E_NO_DISK;
}
```

### 4. 文件操作

这一部分实现文件查找功能，2个函数实现如下：

```c
static int
file_block_walk(struct File *f, uint32_t filebno, uint32_t **ppdiskbno, bool alloc)
{
       // LAB 5: Your code here.
       // panic("file_block_walk not implemented");
	   // check 
	   if(filebno >= NDIRECT + NINDIRECT)
	   {
		   return -E_INVAL;
	   }
	   uint32_t* ind;
	   int blkno;
	   // find and allocate block
	   // directly allocate the block
	  if(filebno < NDIRECT)
	  {
		  uint32_t tmp;
		  memcpy(&tmp,&(f->f_direct[filebno]),sizeof(uint32_t));
		  *ppdiskbno = &tmp;
	  }
	  else
	  {
		  if (f->f_indirect) {
			ind = diskaddr(f->f_indirect);
			*ppdiskbno = &(ind[filebno - NDIRECT]);
		} else {
			if (!alloc)
				return -E_NOT_FOUND;
			if ((blkno = alloc_block()) < 0)
				return blkno;
			f->f_indirect = blkno;
			flush_block(diskaddr(blkno));
			ind = diskaddr(blkno);
			*ppdiskbno = &(ind[filebno - NDIRECT]);
		}
	  }
	  return 0;

}

int
file_get_block(struct File *f, uint32_t filebno, char **blk)
{
       // LAB 5: Your code here.
       // panic("file_get_block not implemented");
	   uint32_t* addr = NULL;
	   int ret = file_block_walk(f,filebno,&addr,true);
	   if(ret < 0)
	   {
		   return ret;
	   }
	   // the case that needs allocate
	   if((*addr) == 0)
	   {
		   ret = alloc_block();
		   if(ret < 0)
		   {
			   return ret;
		   }
		   else
		   {
				*addr = ret;
		   }
	   }
	   uint32_t tmp = *addr;
	    *blk = diskaddr(tmp);
		flush_block(*blk);
	   return 0;
	   
```

### 5. 文件系统接口

#### 1. 实现`serve_read()`函数

由于文件系统无法调用底层的函数，故这一部分实现文件系统的接口，这个函数实现读文件的接口。实现如下：

```c
int
serve_read(envid_t envid, union Fsipc *ipc)
{
	struct Fsreq_read *req = &ipc->read;
	struct Fsret_read *ret = &ipc->readRet;

	if (debug)
		cprintf("serve_read %08x %08x %08x\n", envid, req->req_fileid, req->req_n);

	// Lab 5: Your code here:
	// find the openfile by openfile_lookup
	struct OpenFile* of;
	int r = openfile_lookup(envid,req->req_fileid,&of);
	if(r < 0)
	{
		return r;
	}
	// read a file
	r = file_read(of->o_file,ret->ret_buf,req->req_n,of->o_fd->fd_offset);
	if(r < 0)
	{
		return r;
	}
	// modify the offset
	of->o_fd->fd_offset += r;
	return r;
}
```

#### 2. 实现`serve_write()`函数

同上原因，需要实现一个文件写操作的函数，实现如下

```c
int
serve_write(envid_t envid, struct Fsreq_write *req)
{
	if (debug)
		cprintf("serve_write %08x %08x %08x\n", envid, req->req_fileid, req->req_n);

	// LAB 5: Your code here.
	// panic("serve_write not implemented");
	struct OpenFile* of;
	// find the file 
	int ret = openfile_lookup(envid,req->req_fileid,&of);
	if(ret < 0)
	{
		return ret;
	}
	// write the file 
	req->req_n = (req->req_n>PGSIZE)?PGSIZE:req->req_n;
	ret = file_write(of->o_file,req->req_buf,req->req_n,of->o_fd->fd_offset);
	if(ret < 0)
	{
		return ret;
	}
	// modify the offset
	of->o_fd->fd_offset += ret;
	return ret;
}
```

#### 3.实现`devfile_write()`函数

这个函数是一个客户端的包装函数，实现如下：

```c
static ssize_t
devfile_write(struct Fd *fd, const void *buf, size_t n)
{
	// Make an FSREQ_WRITE request to the file system server.  Be
	// careful: fsipcbuf.write.req_buf is only so large, but
	// remember that write is always allowed to write *fewer*
	// bytes than requested.
	// LAB 5: Your code here
	// panic("devfile_write not implemented");
	int ret;
	fsipcbuf.write.req_fileid = fd->fd_file.id;
	fsipcbuf.write.req_n = n;
	assert(n <= PGSIZE - (sizeof(int) + sizeof(size_t)));
	memcpy(fsipcbuf.write.req_buf,buf,n);
	ret = fsipc(FSREQ_WRITE,NULL);
	if(ret < 0)
	{
		return ret;
	}
	assert(ret <= n);
	assert(ret <= PGSIZE);
	return ret;

}
```

### 6. 进程的spawn操作

由于spawn操作依赖`sys_env_set_trapframe()`函数进行新创建环境的初始化，所以要实现这个函数并进行分发，代码如下：

```c
static int
sys_env_set_trapframe(envid_t envid, struct Trapframe *tf)
{
	// LAB 5: Your code here.
	// Remember to check whether the user has supplied us with a good
	// address!
	// panic("sys_env_set_trapframe not implemented");
	// check the user access to memory
	user_mem_assert(curenv,(const void*)tf,sizeof(struct Trapframe),PTE_U|PTE_P);
	struct Env* e = NULL;
	if(envid2env(envid,&e,1) < 0)
	{
		return -E_BAD_ENV;
	}
	// set the trapframe 
	e->env_tf = *tf;
	return 0;

}

// in function "syscall()" add this
case SYS_env_set_trapframe:
{
	return sys_env_set_trapframe((envid_t)a1,(struct Trapframe*)a2);
}

```

#### 1. 在`fork`和`spawn`之间共享库状态

这就是要复制这两个状态之间共享的页，函数实现如下：

```c
// Copy the mappings for shared pages into the child address space.
static int
copy_shared_pages(envid_t child)
{
	for(unsigned i = 0;i<PGNUM(USTACKTOP);i++)
	{
		if(i == PGNUM(UXSTACKTOP - PGSIZE))
		{
			continue;
		}
		void* addr = (void*)(i * PGSIZE);
		pte_t pte;
		if((uvpd[PDX((uintptr_t)addr)] & PTE_P) == 0)
		{
			pte = 0;
		}
		else
		{
			pte = uvpt[PGNUM((uintptr_t)addr)];
		}
		if((pte & PTE_P) && (pte & PTE_SHARE))
		{
			int ret = sys_page_map(0,addr,child,addr,pte & PTE_SYSCALL);
			if(ret < 0)
			{
				return ret;
			}
		}
	}
	
	return 0;
}
```

### 7. 键盘接口

只需要在分发中断时加上处理键盘的中断即可

```c
// in "kern/trap.c" function trap_dispatch()
case (IRQ_OFFSET+IRQ_KBD):
		{
			kbd_intr();
			return;
		}
		case (IRQ_OFFSET+IRQ_SERIAL):
		{
			serial_intr();
			return;
		}
```

### 8. Shell

最后一部分实现一个'<'重定向的功能，代码如下：

```c
// in "user/sh.c" function runcmd()
if ((fd = open(t, O_RDONLY)) < 0) 
{
	cprintf("open %s for write: %e", t, fd);
	exit();
}
if(fd != 0)
{
	dup(fd, 0);
	close(fd);
}
break;

```



## 实验收获

