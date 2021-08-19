// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;

	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
		addr = ROUNDDOWN(addr,PGSIZE);
		if(!(err & FEC_WR))
		{
			panic("At pgfault:Page fault not write fault");
		}
		if(!(uvpt[(uintptr_t)PGNUM(addr)]&(PTE_COW|PTE_W)))
		{
			panic("At pgfault:Page fault not Copy-on-write");
		}
	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.
	// panic("pgfault not implemented");
	int perm = PTE_P|PTE_W|PTE_U;
	//system call #1 get the id
	envid_t id = sys_getenvid();
	// #2 allocate page 
	r = sys_page_alloc(id,(void*)PFTEMP,perm);
	if(r < 0)
	{
		panic("At pagefault page_alloc:%e",r);
	}
	// move the new to the old
	memcpy((void*)PFTEMP,(void*)addr,PGSIZE);
	// #3 map the page to itself but different address
	r = sys_page_map(id,(void*)PFTEMP,id,addr,perm);
	if(r < 0)
	{
		panic("At pagefault page_map:%e",r);
	}
	// #4 unmap the temporary page fault
	r = sys_page_unmap(id,(void*)PFTEMP);
	if(r < 0)
	{
		panic("At pagefault page_unmap:%e",r);
	}

}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	// panic("duppage not implemented");
	envid_t id = sys_getenvid();
	uintptr_t va = pn*PGSIZE;
	int perm = PTE_P|PTE_U;
	if((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW))
	{
		// mappint to envid
		r = sys_page_map(id,(void*)va,envid,(void*)va,perm|PTE_COW);
		if(r < 0)
		{
			return r;
		}
		// re-claim the COW permission of current env
		r = sys_page_map(id,(void*)va,id,(void*)va,perm|PTE_COW);
		if(r < 0)
		{
			return r;
		}
	}
	else if(uvpt[pn] & PTE_SHARE)
	{
		r = sys_page_map(id,(void*)va,envid,(void*)va,uvpt[pn] & PTE_SYSCALL);
		if(r < 0)
		{
			return r;
		}
	}
	// without PTE_COW permission
	else
	{
		r = sys_page_map(id,(void*)va,envid,(void*)va,perm);
		if(r < 0)
		{
			return r;
		}
	}
	return 0;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
	// LAB 4: Your code here.
	// panic("fork not implemented");
	int ret;
	set_pgfault_handler(pgfault);
	envid_t child_id = sys_exofork();
	// unsuccessful fork
	if(child_id < 0)
	{
		return child_id;
	}
	// returns child function
	if(child_id == 0)
	{
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}
	// copy and map
	for(uintptr_t i = 0;i<USTACKTOP;i+=PGSIZE)
	{
		uintptr_t pn = PGNUM(i);
		// not fully understand
		if(!(uvpd[i>>PDXSHIFT] & PTE_P) || !(uvpt[pn] & PTE_P))
		{
			continue;
		}
		ret = duppage(child_id,(unsigned)pn);
		if(ret < 0)
		{
			return ret;
		}
		
	}
	// allocate new page to the user exception stack of child process
	int perm = PTE_P|PTE_W|PTE_U;
	ret = sys_page_alloc(child_id,(void*)(UXSTACKTOP-PGSIZE),perm);
	if(ret < 0)
	{
		return ret;
	}
	// set the page fault entrypoint of child process
	extern void _pgfault_upcall(void);
	ret = sys_env_set_pgfault_upcall(child_id,_pgfault_upcall);
	if(ret < 0)
	{
		return ret;
	}
	// set child process to status RUNNABLE
	ret = sys_env_set_status(child_id,ENV_RUNNABLE);
	if(ret < 0)
	{
		return ret;
	}
	return child_id;

}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
