---
layout: post
title: "操作系统笔记一：常识、用法"
date: 2018-03-15
last_modified_at: 2024-04-01
categories: [操作系统]
tags: [操作系统]
---

* 目录  
{:toc}
<br/>

**持续更新**   

记录操作系统相关的常识。    

---

# 1. 常识

---

## 1.1 cache 与 buffer

以下参考自：[《Cache 和 Buffer 都是缓存，主要区别是什么？》](https://www.zhihu.com/question/26190832/answer/32387918) [1]。  

cache 用于处理系统两端的速度不匹配，比如 cpu 和 memory 的速度差距越来越大，所以就利用局部性原理，通过 memory hierarchy （分级存储）的策略减少这种差距造成的影响。   

buffer 用于处理系统两端的速度不平衡，减少短时间内突发 I/O 的影响，起到流量整型的作用。   

---

## 1.2 linux 进程间通信（IPC）的方式 

总的包括：管道、消息队列、共享内存、信号量、socket、信号。  

1、管道、消息队列、共享内存、信号量，这几种可以在《UNIX 环境高级编程（第2版）》[2] 的第 15 章都可以找到详细论述。    

2、socket， 在第 16、17 章。     

3、信号，《UNIX 环境高级编程（第2版）》 并没有把信号归类为 IPC，但其实也可以算是一种 IPC 方式，可以在第 10 章可以找到详细论述。      

<br/>  

《UNIX 环境高级编程（第2版）》的英文名叫 Advanced Programming in the UNIX Environment，简称 APUE，下文都以 APUE 指代。  

---

### 1.2.1 管道

狭义上，管道指匿名管道（PIPE）。广义上，管道可分匿名管道、命名管道（FIFO）。   

<br/>

匿名管道的特点：  

1）历史上，管道都是半双工的模式，即数据只能在一个方向上流动，虽然有某些系统提供全双工的，但缺乏可移植性。[2]     

2）只能在具有公共祖先的进程间使用，通常的，一个管道由一个进程创建，然后父进程 fork 出子进程，然后父、子进程都可以使用此管道了。   

<br/>

命名管道与匿名管道不同之处：  

命名管道可以用于不相关的进程间交换数据。  

---

#### 1.2.1.1 匿名管道（PIPE）

匿名管道通过 `int pipe(int fd[2])` 系统调用创建，创建成功后，`fd[0]` 就表示读端，`fd[1]` 表示写端。   

shell 中类似于 `ps aux | grep mysql` 这样的命令，就是将 ps 的输出重定向为 grep 的输入，可以使用匿名管道来实现这样的效果。大体做法是： 

1、shell 创建一个匿名管道 fd[2]； 
2、shell fork 出 ps 子进程，利用 dup2 函数，用管道的写端 fd[1] 替换掉 ps 子进程的 stdout（同时也关闭管道的读端，因为用不上）；  
3、shell fork 出 grep 子进程，利用 dup2 函数，用管道的读端 fd[0] 替换掉 grep 子进程的 stdin（同时也关闭管道的写端，因为用不上）；    

下面例子（仅包含 fork 出 ps 子进程的逻辑）来自 [《进程间通信IPC》](https://www.colourso.top/linux-pipefifo/) [3]:  

```c
#include <unistd.h>
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wait.h>

int main(){

    int pipefd[2];
    int ret = pipe(pipefd);
    if(ret == -1){
        perror("pipe");
        exit(0);
    }

    pid_t pid = fork();

    if(pid == 0){
        //子进程
        close(pipefd[0]);

        //重定向 stdout_fileno -> pipefd[1]
        dup2(pipefd[1],STDOUT_FILENO);

        execlp("ps","ps","aux",NULL);

        //若执行失败
        perror("execlp");
        exit(0);
    }
    else if(pid > 0){
        //父进程
        close(pipefd[1]);

        char buf[1024] = {0};
        int len = -1;

        while((len = read(pipefd[0],buf,sizeof(buf))) > 0){
            printf("%s",buf);
            memset(buf,0,sizeof(buf));
        }

        //读完回收子进程
        wait(NULL);
    }

    return 0;
}

```

---

#### 1.2.1.2 命名管道（FIFO）

命名管道通过 `int mkfifo(const char *pathname, mode_t mode)` 系统调用创建。    

它有两个用途[2]：  

1、由 shell 命令使用以便将数据从一条管道线传送到另一条，为此无需创建中间临时文件。  
2、用于客户端进程与服务端进程结构中，在两者之间传递数据。     

<br/>

针对 1，APUE 举了一个例子，展示了 FIFO 可以在 shell 中做出非线性的连接。    

```bash
mkfifo fifo1
prog3 < fifo1 &
prog1 < infile | tee fifo1 | prog2
```

它实现了这样的效果：   

```
                         -> FIFO -> prog3
输入文件 -> prog1 -> tee 
                         -> prog2
```

---

### 1.2.2 消息队列

一些特点： 

1、消息队列是保存在内核中的数据链表，允许用户自定义数据结构，以一个个消息体为单位进行传输，不像管道那样是无格式的字节流。   

2、如果进程从消息队列中读取了消息，内核就会把该消息从队列中删除。   

3、消息队列不适合大数据传输：1、消息体的大小有限制；2、消息队列的长度（或总体大小）有限制。   

4、消息队列传输中，会需要切换用户态和内核态，这个与管道类似，是一种性能上的消耗。   

5、消息队列以全双工的方式工作。   

<br/>
 
存在的问题：  

APUE 经过测试发现，消息队列与 STREAMS 管道、UNIX 域套接字相比，在速度上没什么优势。而且，消息队列有比较严重的问题，就是如果进程终止，消息队列并不会被删除，它必须由进程调用 api 显式的删除，或者等到操作系统重启。   

所以，APUE 的结论是：新的应用程序不要再使用消息队列了。   

---

### 1.2.3 共享内存

共享内存的本质就是把不同进程的各自的一块虚拟内存空间映射到一块公共的物理内存上，这样一来，一个进程往这块内存写数据，另一个进程马上就可以读取。  

这是最快的一种 IPC 了，读写都不需要内核态和用户态的切换。  

不过，共享内存有一个 race condition 的问题，不同进程读写同一块内存的时候可能会出现冲突。要解决冲突，还是需要锁，可以使用进程间的锁：信号量。    

---

### 1.2.4 信号量

信号量（semaphore）本质上是一个计数器，用于多线程对共享数据对象的访问。所以，它就是一个进程间的锁。   

常用的信号量形式是二元信号量，只有 0 1 二值。进程在访问某资源前先测试信号量，若为 1，则将其减为 0，访问完资源后，释放此信号量，将它值置回 1。测试并置值的操作是原子的。  


---

### 1.2.5 socket 

这个可以使用通用的网络 socket，也可以使用 unix 域 socket。   

---

### 1.2.6 信号 

信号与信号量是两码事：  

1）信号量是一种进程间的锁，用于控制对于同一资源的互斥访问。   

2）信号是一种软件中断，比如 `kill <pid>`，就是向指定 pid 的进程发送了 SIGTERM 信号，如果进程没有自己捕捉并处理 SIGTERM 信号，则针对该信号的默认动作是终止，进程将退出。    

在 APUE 这本书里面，并没有把信号归类于 IPC，但它确实是可以作为一种进程间的通信方式来使用。   

---

## 1.3 XSI

XSI 是 X/Open 组织对 unix 接口定义的一套标准 (X/OPEN System Interface)。   

但目前使用得比较多的是 POSIX（POrtable Operating System Interface），它并不局限于 Unix，其他的一些操作系统也支持 Posix，包括 windows，dec。  

另外还有一个 SUS，即 Single UNIX Specification，它相当于 POSIX 的超集，定义了一些额外附加的接口。   


---

# 2. 参考  

[1] Quokka. Cache 和 Buffer 都是缓存，主要区别是什么. Available at https://www.zhihu.com/question/26190832/answer/32387918, 2017-02-15.   

[2] [美]W. Richard Stevens, Stephen A. Rago. UNIX环境高级编程(第2版). 尤晋元, 张亚英, 戚正伟. 北京: 人民邮电出版社, 2006-5(1): 397,233,413.  

[3] Colourso. 进程间通信IPC. Available at https://www.colourso.top/linux-pipefifo/, 2021-4-4.      