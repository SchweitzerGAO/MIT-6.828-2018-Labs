# MIT-6.828-2018-Labs
2021 Tongji University SSE OS Course Project option 2

[TOC]

## File Structure

`lab`文件结构：

```
lab
├─boot ---- 启动文件
├─conf ---- 配置文件
├─fs ----文件系统函数
├─inc ----头文件
├─kern ----内核函数
├─lib ----用户函数
├─obj ----编译文件
│  ├─boot
│  ├─fs
│  ├─kern
│  ├─lib
│  └─user
└─user ----测试函数
```



## TODOS

- [x] Tools & Lab Guide 
- [x] Lab 1 Environment & Boot a PC
- [x] Lab 2 Memory Management
- [x] Lab 3 User Environments
- [x] Lab 4 Preemptive Multitask
- [x] Lab 5 File System & Spawn & Shell
- [ ] Lab 5 Debug

## Lab 1

1. 拉取lab代码，编译
2. 使用gdb中的`si`命令单步调试代码
3. Boot Loader设置断点，追踪指令
4. 内核相关

## Lab 2

1. 获取新代码
2. 实现`/kern/pmap.c`一些函数——内存分配初始化
3. 实现`/kern/pmap.c`一些函数——页表管理
4. 完善`/kern/pmap.c`中`mem_init()`函数

## Lab 3

1. 为`envs`分配存储空间并映射
2. 实现`kern/env.c`的一些函数——用户环境初始化及运行
3. 中断初始化
4. 分发中断
5. 系统调用
6. 用户环境准备
7. 缺页错误及内存保护

## Lab 4

1. 多处理器支持
2. 轮转法调度
3. 创建环境的系统调用
4. 用户级缺页错误处理
5. 实现"Copy-on-write-fork"
6. 时钟中断和抢占
7. 进程间通信（IPC）

## Lab 5

1. 开启硬盘访问
2. 块Cache
3. 块位图
4. 文件操作
5. 文件系统接口
6. 进程的spawn操作
7. 键盘接口
8. Shell

## Lab 5 Debug

虽然答辩结束了，但是lab5还是有问题。这个问题可能涉及之前的代码，debug的话工作量应该不小（主要是找bug，IDE调试用不成，backtrace有时候也掉链子，我得手动找）这再开一个report吧。
