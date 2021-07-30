# Lab 3 Report——用户环境

[TOC]

## 实验内容

1. 为`envs`分配存储空间并映射

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

![image-20210730165124571](C:\Users\gaoyangfan\AppData\Roaming\Typora\typora-user-images\image-20210730165124571.png)

## 实验收获