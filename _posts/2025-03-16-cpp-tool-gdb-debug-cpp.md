---
layout: post
title: "c++ 工具：gdb 调试 c++"
date: 2025-03-16
last_modified_at: 2025-03-16
categories: [c++]
tags: [c++]
---

* 目录  
{:toc}
<br/>

之所以需要记录，是因为有些程序会使用 daemon 或 fork，这时候 gdb 可能没法 debug 到 fork 出来的子程序，需要做一点额外的工作。  

---

# 1. gdb 的常规使用

## gdb attach 进程

### 步骤  

1、附加，`gdb attach $pid` 或 `gdb -p $pid` 。   

2、设断点，b xxx.cpp:行号。  

3、继续执行，输入 continue 或 c 。  


### 注意  

1、对于不是在后台运行的进程，附加是更好的做法，比如 lua，它需要在命令行输出。   

2、如果要退出 debug，则先 ctrl + c 中断执行，然后输入 `detach`。   

3、运行中要加断点，则先 ctrl + c 中断执行，然后输入 `b xxx.cpp:行号`，再输入 `c` 继续执行。   


---

## gdb launch 进程

### 步骤

1、启动gdb，`$ gdb 进程文件`，比如 `gdb xxxserver`。    

2、设置参数，`set args arg1 arg2 arg3 ...`，比如 `set args ../conf/xxxserver.conf arg1 arg2 arg3` 。  

3、运行进程，`start` 或 `run` 。  

### 注意

1、start 和 run 的区别，start 后会自动停在 main 函数的第一行，方便单步调试；run 则不会。    

---

# 2. gdb debug 子进程的问题

程序中使用 daemon 或者 fork 函数，会出现 debug 不了子进程的问题，像这样：       

```
[Detaching after fork from child process 42918]
[Inferior 1 (process 42891) exited normally]  
```

这种情况，原因是进程启动时通过 fork 出了子进程。典型的就是使用了 daemon 函数，它会 fork 子进程，然后父进程退出。   

解决方法大致如下几个：   


## 方法1：不用 daemon    

如果可以不使用 daemon，则调试时不使用 daemon，像我们自己的服务端程序，就是可以在启动的时候选择不要使用 daemon 的，skynet 记得也是。  

---

## 方法2：只 attach 子进程

run 之前 `set follow-fork-mode child`，设置之后，在 fork 子进程之后，gdb 就会跟着进入子进程的调试了。  

使用这个方法的前提是确保 `detach-on-fork` 使用的是默认配置 `on`。要查看 `detach-on-fork` 配置，可以 `show detach-on-fork`；要设置 on，可以 `set detach-on-fork on`；要设置 off，可以 `set detach-on-fork off`，具体参考：[set detach-on-fork command](https://visualgdb.com/gdbreference/commands/set_detach-on-fork)。   

另外一个注意点，需要提前在子进程的逻辑中加个断点（确保是在 daemon 或 fork 之后的逻辑），否则没法中途中断执行（ctrl+c）来设置断点，具体原因，暂时没有去考究。   

---

## 方法3：同时 attach 父进程和子进程

方法2的做法是只能 attach 子进程，但如果要当时 attach 父进程或子进程，也是 ok 的。先设置 `set detach-on-fork off`，这样即使有 fork，那么 gdb 也能同时 attach 父进程和子进程。之后再通过 `info inferiors` 查看有哪些可以切换的，再通过 `inferior xxx` 切换到想要 debug 的进程。       

---

# 3. 参考

* [set detach-on-fork command](https://visualgdb.com/gdbreference/commands/set_detach-on-fork)     

* [GDB的那些奇淫技巧](https://www.cnblogs.com/xuanbjut/p/14534507.html)  


