---
layout: post
title: "并发、多线程、同步"
date: 2024-03-08
last_modified_at: 2024-03-08
categories: [计算机理论]
tags: [并发 同步 多线程]
---

* 目录  
{:toc}
<br/>

多线程编程的水特别特别深，并且网上充斥着大量陈旧或者错误的文章，于是，我觉得有必要自己收集最新资料，做一次总结，故有本文。本文力求观点准确，知识点足够新。   

以下讨论大体基于 c++。java / C# 也有功能类似的机制，此处不作讨论。  

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

实际上，我翻遍了涉及线程同步的几本书：《现代操作系统》[2]、《深入理解计算机系统》[3]，《UNIX环境高级编程》[4] 都找不到有任何地方，会像上面提到的文章[1]那样去解释 “同步” 和 “互斥”，所以我很想知道那些文章的作者是从哪里看到的，亦或者是人云亦云？    

同步这个词在很多场合都有用到，表达的意思各不相同，我在另一篇文章《几个概念的含义：同步、异步、阻塞、非阻塞》[5] 已经做了一些介绍。  

回到这个词本身，在 Wikipedia[6]里，是这么介绍它的：   
>Thread synchronization is defined as a mechanism which ensures that two or more concurrent processes or threads do not simultaneously execute some particular program segment known as critical section. Processes' access to critical section is controlled by using synchronization techniques.   

词条里还提到，两种需要同步的场景：1、相互排斥的资源访问；2、需要顺序控制的资源访问，这两种场合大概就是中文互联网老是提到的 “互斥” 与 “同步” 吧。  

以前我也没这么较真的，但看过 Martin Kleppmann 的那篇《Please stop calling databases CP or AP》[7]之后，觉得人云亦云是要不得的，要坚定的把基本事实弄清楚，才能建立正确的认知。   


## 同步机制
下面介绍一些常用的同步机制，实际上都可以称为锁。锁是一种非强制机制，线程在访问前尝试获取锁，在访问结束后释放锁。下面各种锁的介绍参考自《程序员的自我修养：链接、装载与库》[8]。  

### 二元信号量 (binary semaphore)
是一种最简单的锁，它只有两种状态：占用与非占用，适合于只能被唯一一条线程独占访问的资源。  

访问资源前：  
尝试获取信号量，如果信号量处于非占用状态，则获取成功，信号量变为占用状态，线程继续执行；否则线程进入等待。  

访问资源后：  
释放信号量，信号量变为非占用状态，如果此时有线程在等待，则唤醒等待中的一条线程。  


### 多元信号量 (semaphore)
简称信号量，一个初始值为 N 的信号量，允许 N 个线程并发访问。  

访问资源前：  
尝试获取信号量，将信号量减 1，如果信号量的值小于 0，则进入等待状态，否则继续执行。  

访问资源后：  
释放信号量，信号量加 1，如果信号量的值小于 1，唤醒一条等待中的线程。  


### 互斥量 (mutex)
类似于二元信号量，仅允许同时被一条线程访问。  

不同之处在于，信号量可以在线程1获取但交给线程2去释放；而互斥量则要求哪个线程获取，哪个线程就要负责释放，其他线程不能帮忙。  


### 临界区 (critical section)
是比互斥量更严格的同步手段。  

把临界区的锁的获取称为进入临界区，而把锁的释放称为离开临界区。  

临界区与信号量、互斥量的区别在于，信号量、互斥量在系统的任何进程里都是可见的，即一个进程创建了信号量或互斥量，在另一个进程试图去获取是合法的。而临界区的作用范围仅限于本进程，其他进程无法获取。  


### 读写锁 (read-write lock)
用于特定场合的一种同步手段。对于一段数据，多线程同时读取是没问题的，但多线程边读边写可能就会出问题。这种情况虽然用信号量、互斥量、临界区都可以做到同步。但是对于那种读多写少的场景，效率就比较差了，而这种情况，用读写锁就很合适。  

读写锁一般会有三种状态：自由、共享、独占，对应两种获取方式：共享的（shared）、独占的（Exclusive）。  

当处于自由状态时，试图以任一种方式获取都会成功，并将锁置为对应状态。  
当处于共享状态时，以共享方式获取会成功，以独占方式获取会进入等待。  
当处于独占状态时，试图以任一种方式获取都会进入等待。  

可总结如下：  

|读写锁状态|以共享方式获取|以独占方式获取|
|---------|-------------|------------|
|  自由   |   成功       |    成功    |
|  共享   |   成功       |    等待    |
|  独占   |   等待       |    等待    |


btw，在数据库里，这种锁很常见，并且会更复杂一些。  


### 条件变量 (condition variable)
首先，这不是一种锁。  




### 自旋锁 (spin lock)


总结一下： 

|锁|范围|
|--|--|
|信号量|多进程间|
|互斥量|多进程间|
|临界区|单进程内|
|读写锁|单进程内|
|条件变量|单进程内|
|自旋锁|单进程内|

---

# 同步原语的性能对比

* 性能对比的论文
[More Than You Ever Wanted to Know about Synchronization: Synchrobench, Measuring the Impact of the Synchronization on Concurrent Algorithms](https://www.researchgate.net/profile/Vincent-Gramoli/publication/282921226_More_Than_You_Ever_Wanted_to_Know_about_Synchronization_Synchrobench_Measuring_the_Impact_of_the_Synchronization_on_Concurrent_Algorithms/links/573c005308ae9ace840eb23a/More-Than-You-Ever-Wanted-to-Know-about-Synchronization-Synchrobench-Measuring-the-Impact-of-the-Synchronization-on-Concurrent-Algorithms.pdf)


---

# 多线程编程的陷阱

## 从 volatile 说到 memory order
先说一下结论：  
* volatile 只能阻止编译器优化，应该只把它用于 Memory Mapped I/O 的场景中，不应该将它用于解决多线程下的诸入原子读写之类的问题。    
* C++11 开始引入的 atomic、memory order 机制，可以很好的解决多线程下的内存顺序问题，应该使用它们。  

### volatile 的历史
要了解清楚 volatile 是如何被误解和滥用的，需要先了解一下它的历史。下文主要参考自这篇文章：《C++11 volatile》[9]。  

#### volatile 的原始用途
最开始是 C 语言引入的，用在 Memory Mapped I/O 中，避免编译器优化导致的错误。  

Memory Mapped I/O 是把 I/O 设备的读写映射到一段内存区域中，假设一个最简单的设备，这个设备只有一个写接口，映射到了内存中的变量 A。每次给变量 A 赋值，相当于向设备写一次。   

如果我们想向这个设备分别写两次值，第一次写入 1，第二次写入 1000，将会这样写逻辑：  

```
B = 1;
B = 1000;
```

但是，由于编译器优化，可能会把第一句：` B = 1; ` 优化掉，只保留 ` B = 1000; `，这显然不符合我们的意图。  

为了解决这种问题，C 引入了 volatile 关键字，用它这样修饰变量：`volatile int B;`，可以阻止编译器针对此变量的优化，编译器将不会再 “吞掉” `B = 1;` 这句代码了。   

<br/>

小结一下:  
* C 引入 volatile 是为了解决 Memory Mapped I/O 场景下的编译器错误优化问题。  


### volatile 在 C++ 中的使用
C++ 保留了 volatile 这个关键字，除了继续用于 Memory Mapped I/O 之外，随着多线程的发展，在一些厂商或者书本的鼓励下，volatile 被推荐用于解决一些多线程编程的问题。比如这样的：    

```C++
int a = 0;
int b = 0;
bool flag = false;

void producer_thread()
{
  // 先写 a 和 b
  a = 42;
  b = 43;
  // 最后设置 flag 标志位为 true
  flag = true;
}

void consumer_thread()
{
  // 等待 flag 被设为 true
  while (!flag) continue;
  // 接着使用 a 和 b
  ...
}
```

上面这段代码展示的是生产者/消费者的逻辑：生产者&消费者通过 flag 变量协调工作，当生产者设置 flag 为 true 后，消费者接着工作。这段代码有时候能正常工作，但有时候不行，因为它存在一些问题。  

* 问题一：可能会死循环。  

在上一节中，我们已经见识了编译器优化，在 consumer_thread 的代码中，编译器看到 flag 变量只被使用一次，它可能只读一次 flag 到寄存器中，之后就不再重新读了。假如这时 flag 还未被设置为 true，它会一直等待在 while 循环中。这看起来挺愚蠢的，但确实可能发生。  

如果我们用 volatile 修饰 flag 变量，那么编译器就不会对它进行优化了，consumer_thread 的 while 逻辑会每次从内存中把它读出来判断，也就不会死循环了。  


* 问题二：不按顺序执行
虽然我们使用 volatile 解决了问题一，但仍然有其他问题：不按代码顺序执行。这个问题不太容易察觉。这个问题主要是指令重排（reordering）导致的。

程序的意图是：生产者先写 a 和 b，再写 flag；消费者先判断 flag 后，再读 a 和 b。大致如下图：   

![multithread-producer-consumer-expect-order](https://blog.antsmallant.top/media/blog/2024-03-08-multi-threads/multithread-producer-consumer-expect-order.png)   
<center>图1：生产者消费者期望工作状态</center>

但实际上编译器优化过后，可能是这样的工作过程：生产者先写了 flag，消费者判断到 flag 为 true，开始读 a 和 b，之后生产者才开始写 a 和 b。大致如下图：  

![multithread-producer-consumer-unexpect-order](https://blog.antsmallant.top/media/blog/2024-03-08-multi-threads/multithread-producer-consumer-unexpect-order.png)   
<center>图2：生产者消费者乱序状态</center>

如果按以上顺序执行，消费者可能会读到不正确的 a 和 b 值。  

这个问题出在 volatile 只控制 flag 不被编译器优化，不能约束 a 和 b 的写入顺序，所以编译器优化可能导致执行顺序与意图不一致，这种问题就是内存顺序问题。    

但实际上，除了编译器优化会导致指令重排（compiler reordering），cpu 也可能乱序执行。几十年前，cpu 为了提高效率就发展出动态调度机制，在执行过程中可能交换指令的顺序（cpu reordering）。所以，cpu 的乱序执行能力也会导致相同的问题。   


参考：
* [Memory Model and Synchronization Primitive - Part 1: Memory Barrier](https://www.alibabacloud.com/blog/memory-model-and-synchronization-primitive---part-1-memory-barrier_597460)

* [Memory Model and Synchronization Primitive - Part 2: Memory Model](https://www.alibabacloud.com/blog/memory-model-and-synchronization-primitive---part-2-memory-model_597461)

* [Compiler reordering](https://bajamircea.github.io/coding/cpp/2019/10/23/compiler-reordering.html)

* [CPU流水线与指令重排序](https://cloud.tencent.com/developer/article/2195759)

* [Memory ordering](https://en.wikipedia.org/wiki/Memory_ordering)

<br/>

小结一下:  
* volatile 不能解决多线程编程的问题，多线程编程不应该依赖它。  
* 内存顺序是多线程编程中难以察觉，但又很致命的问题。  


### 某些编译器赋予 volatile 额外的能力
上文提到 volatile 无法阻止 reordering，但并不是所有 volatile 的实现都无法阻止，这取决于不同的编译器实现，有些编译器实现就通过插入屏障（barrier）的方向来阻止 reordering，比如说 Microsoft 的编译器。  

microsoft 在这篇文章《volatile (C++)》[11] 介绍了 volatile 的两个编译器选项：。  
当使用 `/volatile:iso`选项的时候，volatile 就只能用于硬件访问 (hardware access)，即 memory mapped i/o，不能把它用于跨线程编程。  

当使用 `/volatile:ms` 选项的时候，正如文章所说的，它能够实现这样的效果：   
>When the /volatile:ms compiler option is used—by default when architectures other than ARM are targeted—the compiler generates extra code to maintain ordering among references to volatile objects in addition to maintaining ordering to references to other global objects. In particular:  
> 
>A write to a volatile object (also known as volatile write) has Release semantics; that is, a reference to a global or static object that occurs before a write to a volatile object in the instruction sequence will occur before that volatile write in the compiled binary.
>
>A read of a volatile object (also known as volatile read) has Acquire semantics; that is, a reference to a global or static object that occurs after a read of volatile memory in the instruction sequence will occur after that volatile read in the compiled binary.   
>
>This enables volatile objects to be used for memory locks and releases in multithreaded applications.


翻译过来就是：   
写一个 volatile 修饰的变量时，在写之前对其他 global 或 static 变量的访问确保发生在此之前。  
读一个 volatile 修改的变量时，在读之前对其他 global 或 static 变量的访问确保发生在此之前。  

这样实际上是可以解决上面问题二的，也就是说，微软编译器通过修改 volatile 把问题一、二都解决了。  

尽管有这种额外实现，我们仍然不应该依赖它，因为这样会严重制约我们代码的可移植性。   



### C++11 memory order  和 atomic
上文中我们把问题暴露出来了，接下来需要探讨一下解决办法了。  

volatile 实际上只能阻止编译器优化，就不要让它再来帮忙多线程编程了，它应该只做 memory mapped i/o 的工作。  

那么现在需要一套完善的方案能同时解决问题一和问题二。   

针对问题二，我们是需要确保在 flag 设置之前，a 和 b 都设置了，实际上就是需要某种屏障，能确保 flag 之前的代码在 flag 之前运行。操作系统底层就有提供这种 barrier，比如 linux 提供的：  

```c
#define barrier() __asm__ __volatile__("" ::: "memory")
```

c++11 之前，使用的是一些多线程库，比如 wikipedia [11]这里展示了各种库：    

![multithread-wikipedia-list-of-cpp-multi-threading-libraries](https://blog.antsmallant.top/media/blog/2024-03-08-multi-threads/multithread-wikipedia-list-of-cpp-multi-threading-libraries.png)   
<center>图3：c++线程库列表</center>

这些多线程库依赖的是一些编译器扩展，或者具体操作系统提供的底层 api，如 barrier。

pthread 库 对 barrier 也做了封装，支持 pthread_barrier_t 数据类型，并且提供了pthread_barrier_init, pthread_barrier_destroy, pthread_barrier_wait API, 为了使用 pthread 的 barrier,



* [Multithreaded programming in C++](https://www.incredibuild.com/blog/multithreaded-programming-in-c)

* Is there any cross-platform threading library in C++?
[Is there any cross-platform threading library in C++?](https://stackoverflow.com/questions/2561471/is-there-any-cross-platform-threading-library-in-c)

* c++11 之前是如何做多线程编程的？
[Threading before C++11](https://bajamircea.github.io/coding/cpp/2019/10/29/threading-before-cpp11.html)


[大白话C++之：一文搞懂C++多线程内存模型(Memory Order)](https://blog.csdn.net/sinat_38293503/article/details/134612152)
[What exactly is std::atomic?](https://stackoverflow.com/questions/31978324/what-exactly-is-stdatomic)


* intel 论坛上的这篇文章了：  Volatile: Almost Useless for Multi-Threaded Programming
[Volatile: Almost Useless for Multi-Threaded Programming](https://blog.csdn.net/qianlong4526888/article/details/17551725)

[Should volatile Acquire Atomicity and Thread Visibility Semantics?](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2006/n2016.html)


* Since C++11, atomic variables (std::atomic<T>) give us all of the relevant guarantees.
[Why is volatile not considered useful in multithreaded C or C++ programming?](https://stackoverflow.com/questions/2484980/why-is-volatile-not-considered-useful-in-multithreaded-c-or-c-programming)


* That conclusion was accurate at the time the article was written (2004); now C++ is a thread and multiprocessor aware language.   
[volatile keyword and multiprocessors ](https://www.daniweb.com/programming/software-development/threads/389799/volatile-keyword-and-multiprocessors) 

pdf: [C++ and the Perils of Double-Checked Locking](https://www.aristeia.com/Papers/DDJ_Jul_Aug_2004_revised.pdf)
quote: [http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2007/n2427.html#DiscussOrder](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2007/n2427.html#DiscussOrder)


* Why do we use the volatile keyword?
[Why do we use the volatile keyword? ](https://stackoverflow.com/questions/4437527/why-do-we-use-the-volatile-keyword)


* 关于 volatile 会插入内存屏障的这个说法是对的吗？ 
https://www.zhihu.com/question/329746124/answer/718600236


* volatile 只和阻止编译器优化有关：
https://www.zhihu.com/question/67231941/answer/2436335772


* 微软的 volatile 文档
[volatile (C++)](https://learn.microsoft.com/en-us/cpp/cpp/volatile-cpp?view=msvc-170)


* wikipedia 的 volatile 定义
[volatile (computer programming)](https://en.wikipedia.org/wiki/Volatile_(computer_programming)#cite_note-7)


网络上有大量关于 volatile 的文章，但基本上都是人云亦云，已经是一些陈旧的认识了。  

[C++11 volatile](https://bajamircea.github.io/coding/cpp/2019/11/05/cpp11-volatile.html)
在 C++11 中，引入了 memory order 解决多线程环境下，变量读写的原子性问题，但保留了 volatile 用于 memory mapped i/o。   



## c 没有 memory order，如果解决问题？
可以使用内存屏障吗？


## 陈硕关于线程同步的建议


## 多线程的初衷
是快。  

但是加了一系列限制之后，它还够快吗？这是一个值得思考的问题。  

from：[Volatile: Almost Useless for Multi-Threaded Programming](https://blog.csdn.net/qianlong4526888/article/details/17551725)

> None of these mention multi-threading. Indeed, Boehm's paper points to a 1997 comp.programming.threads discussionwhere two experts said it bluntly:
>
>   "Declaring your variables volatile will have no useful effect, and will simply cause your code to run a *lot* slower when you turn on optimisation in your compiler." - Bryan O' Sullivan
>
>   "...the use of volatile accomplishes nothing but to prevent the compiler from making useful and desirable optimizations, providing no help whatsoever in making code "thread safe". " - David Butenhof
>
> If you are multi-threading for the sake of speed, slowing down code is definitely not what you want. For multi-threaded programming, there two key issues that volatile is often mistakenly thought to address:
> * atomicity
> * memory consistency, i.e. the order of a thread's operations as seen by another thread.



## java or C# 中的内存模型
何为 JMM ？ 

[如何理解java中的volatile、happen-before、以及重排序的关系？](https://www.zhihu.com/question/499586720/answer/2350034212)

[CPU memory model](https://bajamircea.github.io/coding/cpp/2019/10/25/cpu-memory-model.html)

[Weak vs. Strong Memory Models](https://preshing.com/20120930/weak-vs-strong-memory-models/)

---

# 并发

[Real-world Concurrency](https://queue.acm.org/detail.cfm?id=1454462)   

* wikipedia 关于 Concurrency control 的词条
[Concurrency control](https://en.wikipedia.org/wiki/Concurrency_control)

---

# todo
* 补充完整条件变量以及自旋锁
* 补充 linux 下各种原语的 pthread 版本
* 搞清楚锁的作用域范围的描述是否准确
* 重新寻找权威的关于同步原语的描述
* 经典问题的论述：哲学家就餐问题、读者-写者问题
* 补充陈硕关于线程同步的建议

---

# 拓展阅读
* Vincent Gramoli. More than You Ever Wanted to Know about Synchronization
 Synchrobench, Measuring the Impact of the Synchronization on Concurrent Algorithms. Available at https://perso.telecom-paristech.fr/kuznetso/INF346-2015/slides/gramoli-ppopp15.pdf, 2015.  

* Bryan Cantrill, Jeff Bonwick. Real-world Concurrency. Available at https://queue.acm.org/detail.cfm?id=1454462, 2008-10-24.   

---

# 总结
* 多线程编程简直是个屎坑，除非你掌握了足够多并且足够新的知识，轻易不要挑战它。   

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

[9] bajamircea. C++11 volatile. Available at https://bajamircea.github.io/coding/cpp/2019/11/05/cpp11-volatile.html, 2019-11-5.    

[10] Wikipedia. List of C++ multi-threading libraries. Available at https://en.wikipedia.org/wiki/List_of_C%2B%2B_multi-threading_libraries.    

[11] Microsoft. volatile (C++). Available at https://learn.microsoft.com/en-us/cpp/cpp/volatile-cpp?view=msvc-170&viewFallbackFrom=vs-2019, 2021-9-21.