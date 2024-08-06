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

## 1.2 linux 下进程间通信（IPC）的方式 

管道、消息队列、共享内存、信号量。这几种方式在《UNIX 环境高级编程（第2版）》[2] 的第 15 章都可以找到详细的论述。socket 相关的在第 16、17 章。   

另外，信号其实也可以算是一种 IPC 方式，这个在《UNIX 环境高级编程（第2版）》[2] 的第 10 章可以找到详细的论述。  

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

<br/>

**1、匿名管道**   

匿名管道通过 `int pipe(int fd[2])` 系统调用创建，创建成功后，`fd[0]` 就表示读端，`fd[1]` 表示写端。   

shell 中类似于 `ps aux | grep mysql` 这样的命令，就是将 ps 的输出重定向为 grep 的输入，可以使用匿名管道来实现这样的效果。大体做法是： 

1、shell 创建一个匿名管道 fd[2]； 
2、shell fork 出 ps 子进程，利用 dup2 函数，用管道的写端 fd[1] 替换掉 ps 子进程的 stdout；  
3、shell fork 出 grep 子进程，利用 dup2 函数，用管道的读端 fd[0] 替换掉 grep 子进程的 stdin；    

下面例子来自 [《进程间通信IPC》](https://www.colourso.top/linux-pipefifo/) [3]:  

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

**2、命名管道**   

命名管道通过 `int mkfifo(const char *pathname, mode_t mode)` 系统调用创建。  

---

### 1.2.2 消息队列

---

### 1.2.3 共享内存

---

### 1.2.4 信号量跟信号   

这是两码事：    
1）信号量是一种进程间的锁，用于控制对于同一资源的互斥访问。   
2）信号是一种软件中断，比如 `kill <pid>`，就是向指定 pid 的进程发送了 SIGTERM 信号，如果进程没有自己捕捉并处理 SIGTERM 信号，则针对该信号的默认动作是终止，进程将退出。    

在 《UNIX 环境高级编程》这本书里面，并没有把信号归类于 IPC，但它确实是可以作为一种进程间的通信方式来使用。   

---

### 

---

# 2. 参考  

[1] Quokka. Cache 和 Buffer 都是缓存，主要区别是什么. Available at https://www.zhihu.com/question/26190832/answer/32387918. 2017-02-15.   

[2] [美]W. Richard Stevens, Stephen A. Rago. UNIX环境高级编程(第2版). 尤晋元, 张亚英, 戚正伟. 北京: 人民邮电出版社, 2006-5(1): 397,233.  

[3] Colourso. 进程间通信IPC. Available at https://www.colourso.top/linux-pipefifo/. 2021-4-4.      