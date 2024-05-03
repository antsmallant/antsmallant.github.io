---
layout: post
title: "并发、多线程、同步"
date: 2024-03-08
last_modified_at: 2024-03-08
categories: [计算机理论]
tags: []
---

* 目录  
{:toc}
<br/>

多线程太难了，有很多问题甚至是都没意识到的。   

现代 c++ 的一些特性也是在帮助写出工作正常的多线程代码，比如 c++ 新增的特性 memory order。  

---

# 线程同步

## 多线程语境下 “同步” 一词的内含
先说我的结论：线程同步是一种约束（或机制），即一个线程还没访问完一个数据的时候，其他线程不能对这一个数据进行访问。  

中文互联网上有很多文章在讲 “同步与互斥的区别”，典型的说法是类似这样的[1]：   

>【同步】：是指散步在不同任务之间的若干程序片断，它们的运行必须严格按照规定的某种先后次序来运行，这种先后次序依赖于要完成的特定的任务。最基本的场景就是：两个或两个以上的进程或线程在运行过程中协同步调，按预定的先后次序运行。比如 A 任务的运行依赖于 B 任务产生的数据。  
>【互斥】：是指散步在不同任务之间的若干程序片断，当某个任务运行其中一个程序片段时，其它任务就不能运行它们之中的任一程序片段，只能等到该任务运行完这个程序片段后才可以运行。最基本的场景就是：一个公共资源同一时刻只能被一个进程或线程使用，多个进程或线程不能同时使用公共资源。   

我对这个说法很怀疑，为何把同步跟互斥放在一起比较呢？很奇怪。在我的认知里，线程同步是一种约束，即一个线程还没访问完一个数据的时候，其他线程不能对这一个数据进行访问。它是为了避免多线程并发访问共享资源导致的竞争或死锁等问题。  

有不少同步机制可以实现这种约束，互斥量只是其中的一种，另外的机制还包括：二元信号量，多元信号量，临界区，读写锁，条件变量。   

而那些文章中所说的 “同步”，更准确的说应该是利用某些同步机制来协调线程，以完成某些具有先后顺序的工作。但使用 “同步” 来描述这种做法，只会增加混淆。   

实际上，我翻遍了涉及线程同步的书：《现代操作系统》[2]、《深入理解计算机系统》[3]，《UNIX环境高级编程》[4] 都找不到有任何地方，会像上面提到的文章[1]那样去解释 “同步” 和 “互斥”，所以我很想知道那些文章的作者是从哪里看到的，亦或者是人云亦云？    

同步这个词在很多场合都有用到，表达的意思各不相同，我在另一篇文章《几个概念的含义：同步、异步、阻塞、非阻塞》[5] 已经做了一些介绍。  

回到这个词本身，在 Wikipedia[6]里，是这么介绍它的：   
>Thread synchronization is defined as a mechanism which ensures that two or more concurrent processes or threads do not simultaneously execute some particular program segment known as critical section. Processes' access to critical section is controlled by using synchronization techniques.   

词条里还提到，两种需要同步的场景：1、相互排斥的资源访问；2、需要顺序控制的资源访问，这两种场合大概就是中文互联网老是提到的 “互斥” 与 “同步” 吧。  

以前我也没这么较真的，但看过 Martin Kleppmann 的这篇文章《Please stop calling databases CP or AP》[7]之后，觉得人云亦云是要不得的，要坚定的把基本事实弄清楚，才能建立正确的认知。   


## 同步机制
下面介绍一些常用的同步机制，实际上都可以称为锁。锁是一种非强制机制，线程在访问前尝试获取锁，在访问结束后释放锁。下面各种锁的介绍参考自《程序员的自我修养：链接、装载与库》[8]。

### 二元信号量
是一种最简单的锁，它只有两种状态：占用与非占用。


### 多元信号量
简称信号量，


### 互斥量


### 临界区


### 读写锁


### 条件变量


### 自旋锁


---

# 并发

[Real-world Concurrency](https://queue.acm.org/detail.cfm?id=1454462)

---

# todo
* 经典问题的论述：哲学家就餐问题、读者-写者问题

---

# 拓展阅读
* Vincent Gramoli. More than You Ever Wanted to Know about Synchronization
 Synchrobench, Measuring the Impact of the Synchronization on Concurrent Algorithms. Available at https://perso.telecom-paristech.fr/kuznetso/INF346-2015/slides/gramoli-ppopp15.pdf, 2015.  
* Bryan Cantrill, Jeff Bonwick. Real-world Concurrency. Available at https://queue.acm.org/detail.cfm?id=1454462, 2008-10-24.  

---

# 总结

---

# 参考
[1] ~青萍之末~. 多线程的同步与互斥（互斥锁、条件变量、读写锁、自旋锁、信号量）. Available at https://blog.csdn.net/daaikuaichuan/article/details/82950711, 2018-10-06.   

[2] [荷]Andrew S. Tanenbaum, Herbert Bos. 现代操作系统(原书第4版). 陈向群, 马洪兵, 等. 北京: 机械工业出版社, 2020-3(1).   

[3] [美]Randal E. Bryant, David R. O'Hallaron. 深入理解计算机系统(原书第3版). 龚奕利, 贺莲. 北京: 机械工业出版社, 2022-6(1).  

[4] [美]W. Richard Stevens, Stephen A. Rago. UNIX环境高级编程(第2版). 尤晋元, 张亚英, 戚正伟. 北京: 人民邮电出版社, 2006-5(1).  

[5] antsmallant. 几个概念的含义：同步、异步、阻塞、非阻塞. Available at https://blog.antsmallant.top/2024/01/19/synchronous-asynchronous-blocking-nonblocking, 2024-01-19.    

[6] Wikipedia. Synchronization (computer science). Available at https://en.wikipedia.org/wiki/Synchronization_(computer_science).   

[7] Martin Kleppmann. Please stop calling databases CP or AP. https://martin.kleppmann.com/2015/05/11/please-stop-calling-databases-cp-or-ap.html, 2015-5-11.  

[8] 俞甲子, 石凡, 潘爱民. 程序员的自我修养：链接、装载与库. 北京: 电子工业出版社, 2009-4.    