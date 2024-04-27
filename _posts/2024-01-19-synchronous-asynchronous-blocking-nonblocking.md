---
layout: post
title: "几个概念的含义：同步、异步、阻塞、非阻塞"
date: 2024-01-19
last_modified_at: 2024-01-19
categories: [计算机理论]
tags: [网络 同步 异步 阻塞 非阻塞]
---

* 目录  
{:toc}
<br/>

同步、异步、阻塞、非阻塞，这几个概念挺要命的，容易把人搞糊涂。网上可以找到巨量的解释文章，stackoverflow、知乎、quora 上面都有，但没有一篇让我感到满意。有时候作者想通过白话一点的语言解释清楚这些概念，反而由于啰嗦导致解释不清。  

经过一番研究，我得出如下结论：  

阻塞和非阻塞，一般只用于 I/O 场景， 区别在于数据还没准备好从内核复制到用户空间的时，阻塞 I/O 会导致线程挂起，非阻塞则不会。   

同步和异步，不同场景有不同含义，在 I/O 场景，区别在于内核准备好数据时，同步 I/O 需要主动调用函数完成操作，异步则不需要。  

<br/>

以上就是本文全部的要点了，下面只是展开说说。   


## 详说阻塞和非阻塞
《Unix网络编程》里提到： 
>套接字的默认状态是阻塞的。这意味着当发出一个不能立即完成的套接字调用时，其进程将被投入睡眠，等待相应操作完成。[1]    
>
>进程把一个套接字设置成非阻塞是在通知内核：当所请求的I/O操作非得把本进程投入睡眠才能完成时，不要把要进程投入睡眠，而是返回一个错误。[1]    


![blocking io model](https://blog.antsmallant.top/media/blog/2024-01-19-synchronous-asynchronous-blocking-nonblocking/blocking-io-model.png)   
<center>图1：阻塞式I/O模型 [1]</center>

图1是阻塞型 I/O 的工作过程，“一个不能立即完成的套接字调用” 的意思就是数据还没有准备好从内核复制到用户空间，需要 “等待数据”，比如 socket read，就需要先等待网络数据从对端发到我端。   

![non blocking io model](https://blog.antsmallant.top/media/blog/2024-01-19-synchronous-asynchronous-blocking-nonblocking/non-blocking-io-model.png)   
<center>图2：非阻塞式I/O模型 [1]</center>  

图2是非阻塞型 I/O 的工作过程，它跟阻塞型的区别在于如果需要等待内核准备数据，则立即返回一个错误码，不挂起线程。实际上它应该是 “部分阻塞”，“将数据从内核复制到用户空间” 也算是一个阻塞的过程。   


## 详说同步和异步
同步和异步这两个术语，在很多场景都会被使用到，但有不同的含义。    


### I/O 模型
I/O 模型中包含同步 I/O 和异步 I/O，区别在于当内核数据准备好的时候，是否需要主动调用函数完成操作。   

在 《Unix网络编程》[1]里提到
>同步I/O操作（synchronous I/O operation）导致请求进程阻塞，直到I/O操作完成；  
>异步I/O操作（asynchronous I/O operation）不导致请求进程阻塞。   

上面说的进程，在实际的操作系统，比如 linux 中可以理解为线程，不过其实 linux 中的线程本质上就是轻量级的进程。**这里的阻塞可以理解为同步这个行为的代价，因为它要自己等待结果返回，所以不得不被阻塞。**       

![5种I/O模型的比较](https://blog.antsmallant.top/media/blog/2024-01-19-synchronous-asynchronous-blocking-nonblocking/comparison-of-5-io-model.png)  
<center>图3：5种I/O模型的比较 [1]</center>

>根据上述定义，我们的前4种模型--阻塞式I/O模型、非阻塞式I/O模型、I/O复用模型和信号驱动式I/O模型都是同步I/O模型，因为其中真正的I/O操作（recvfrom）将阻塞进程。只有异步I/O模型与POSIX定义的异步I/O相匹配。[1]  

系统提供的各种 I/O 操作包含同步 I/O 和异步 I/O 。同步 I/O 比较常见，如：read、write、select、poll、epoll 等。异步 I/O 比较少见，如 windows 下的 IOCP，linux下的 aio。  


### 数据库主从复制
数据库主从复制分了好几种：同步复制、半同步复制、异步复制。区别在于等待多少个结果返回。   

* 同步复制：等待所有副本的结果返回。
* 半同步复制：等待部分副本的结果返回。
* 异步复制：不等待。   

<br/>

### 分布式网络模型
分布式网络模型包含同步网络和异步网络。  
* 同步网络是指所有节点的时钟漂移有上限，网络的传输时间有上限，所有节点的计算速度一样。[2]   
* 异步网络是指节点的时钟漂移无上限, 消息的传输延迟无上限, 节点计算的速度不可预料。[2]   

<br/>

### 中断
中断通常分为同步中断和异步中断。  
* 同步中断是当指令执行时由 CPU 控制单元产生的，之所以称为同步，是因为只有在一条指令终止执行后 CPU 才会发出中断。[3]  
* 异步中断是由其他硬件设备按照 CPU 时钟信号随机产生的。[3]     

<br/>

## 参考
[1] W.Richard Stevens, Bill Fenner, Andrew M. Rudoff. UNIX网络编程 卷1：套接字联网API 第3版. 人民邮电出版社. p123,p124,p126,p341. 2010.   
[2] Daniel Wu. 分布式系统中的网络模型和故障模型 ( https://danielw.cn/network-failure-models ). 2015.   
[3] Daniel P.Bovet, Marco Cesati. 深入理解 Linux 内核 第三版. p135. 2007.   