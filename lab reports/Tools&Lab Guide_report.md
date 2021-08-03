# Tools & Lab Guide Report

[TOC]

## Tools

这一部分主要是进行QEMU的安装以及配置。我这里用的是VMWare虚拟机以及Ubuntu 20.04系统。前期配置好之后对于Compile Toolchain的检查应该是没有问题的。对于Ubuntu来说，下面的一行命令是比较重要的

```shell
sudo apt-get install gcc-multilib
```

不执行这个命令的话，后面编译就会出错

从Github上克隆仓库之后进行配置，配置方法是

```shell
./configure --disable-kvm --disable-werror [--prefix=PFX] [--target-list="i386-softmmu x86_64-softmmu"]
```

其中`PFX`指定了QEMU安装的位置，需要自己定义。最后`make & make install`一下，qemu就装好了。

## Lab Guide

给出了lab中常用的终端命令，现整理如下，以便后续查阅，随实验更新

`make qemu`:运行QEMU虚拟机，打开虚拟机界面

`make qemu-nox`:仅在Linux终端运行QEMU(Optional)

`make qemu-gdb`:在GDB中调试QEMU(开2个终端，配合`make gdb`使用)

`si`:即step instruction 单步执行指令

`b *addr`：在addr所指示的地址上设置断点

`c` :继续执行到断点处

`x/{Num}i addr`:从addr开始显示之后Num字节指令的反汇编

`x/{Num}x addr`:显示从addr开始Num字的内存内容。​

`make clean`:删除之前的make版本
