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

NOTE: **还没写完，要处理的信息量太大了。**

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

Scott Meyers 在他那本《Effective Modern C++》的条款40[13]说到：“可怜的 volatile。被误解到如此地步。它甚至不应该出现在本章中，因为它与并发程序设计毫无关系。”。

要了解清楚 volatile 是如何被误解和滥用的，需要先了解一下它的历史。下文主要参考自这篇文章：《C++11 volatile》[9]。  

### volatile 的原始用途
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

```cpp
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

<br/>

小结一下:  
* volatile 不能解决多线程编程的问题，多线程编程不应该依赖它。  
* 内存顺序是多线程编程中难以察觉，但又很致命的问题。  


### 某些编译器赋予 volatile 额外的能力
上文提到 volatile 无法阻止 reordering，但并不是所有 volatile 的实现都无法阻止，这取决于不同的编译器实现，有些编译器实现就通过插入屏障（barrier）的方向来阻止 reordering，比如说 Microsoft 的编译器。  

microsoft 在这篇文章《volatile (C++)》[11] 介绍了 volatile 的两个编译器选项：。  
当使用 `/volatile:iso` 选项的时候，volatile 就只能用于硬件访问 (hardware access)，即 memory mapped i/o，不应该把它用于跨线程编程。    

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

这样一来确实可以解决上面的问题二，也就是说微软编译器通过增强 volatile，把问题一、二都解决了。  

但是，尽管有这种额外实现，我们仍然不应该依赖它，因为这样会严重制约我们代码的可移植性。   

除了 Microsoft 的编译器，其他编译器对于 volatile 的处理也有其他问题，比如以下帖子和文章讲的：    
* [Curious thing about the volatile keyword in C++](https://www.reddit.com/r/cpp/comments/592sui/curious_thing_about_the_volatile_keyword_in_c/)
* [A note about the volatile keyword in C++](https://componenthouse.com/2016/10/21/a-note-about-the-volatile-keyword-in-cpp/)


### C++11 完善的多线程支持
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

pthread 库 对 barrier 也做了封装，支持 pthread_barrier_t 数据类型，并且提供了pthread_barrier_init, pthread_barrier_destroy, pthread_barrier_wait API, 为了使用 pthread 的 barrier。

参考：[pthread_barrier_wait， 内存屏障](https://www.cnblogs.com/my_life/articles/5310793.html)

* C++11 之前是如何使用多线程编程的？
    * [Multithreaded programming in C++](https://www.incredibuild.com/blog/multithreaded-programming-in-c)
    * [Is there any cross-platform threading library in C++?](https://stackoverflow.com/questions/2561471/is-there-any-cross-platform-threading-library-in-c)
    * [Threading before C++11](https://bajamircea.github.io/coding/cpp/2019/10/29/threading-before-cpp11.html)


* 内存模型 & reordering 参考：
    * [Memory Model and Synchronization Primitive - Part 1: Memory Barrier](https://www.alibabacloud.com/blog/memory-model-and-synchronization-primitive---part-1-memory-barrier_597460)

    * [Memory Model and Synchronization Primitive - Part 2: Memory Model](https://www.alibabacloud.com/blog/memory-model-and-synchronization-primitive---part-2-memory-model_597461)

    * [C++ and Beyond 2012: Herb Sutter - atomic Weapons 1 of 2](https://www.youtube.com/watch?v=A8eCGOqgvH4&t=620s)

    * [Compiler reordering](https://bajamircea.github.io/coding/cpp/2019/10/23/compiler-reordering.html)

    * [CPU流水线与指令重排序](https://cloud.tencent.com/developer/article/2195759)

    * [Memory ordering](https://en.wikipedia.org/wiki/Memory_ordering)

    * [大白话C++之：一文搞懂C++多线程内存模型(Memory Order)](https://blog.csdn.net/sinat_38293503/article/details/134612152)     

* atmoic  

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


* wikipedia 的 volatile 定义   

[volatile (computer programming)](https://en.wikipedia.org/wiki/Volatile_(computer_programming)#cite_note-7)


## c 没有明确规定的内存模型，是如何在多线程下工作的？
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

# 什么时候应该使用多线程编程？

* [CppCon 2017: Ansel Sermersheim “Multithreading is the answer. What is the question? (part 1 of 2)”](https://www.youtube.com/watch?v=GNw3RXr-VJk)

* [CppCon 2017: Ansel Sermersheim “Multithreading is the answer. What is the question? (part 2 of 2)”](https://www.youtube.com/watch?v=sDLQWivf1-I)

* [Multithreading is the answer.What is the question](https://www.copperspice.com/pdf/ACCU-Multi-Threading.pdf)

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
* 从《modern effective c++》补充一些知识点

---

# 拓展阅读
* Vincent Gramoli. More than You Ever Wanted to Know about Synchronization
 Synchrobench, Measuring the Impact of the Synchronization on Concurrent Algorithms. Available at https://perso.telecom-paristech.fr/kuznetso/INF346-2015/slides/gramoli-ppopp15.pdf, 2015.  

* Bryan Cantrill, Jeff Bonwick. Real-world Concurrency. Available at https://queue.acm.org/detail.cfm?id=1454462, 2008-10-24.   

* [英]Anthony Williams. C++并发编程实战（第2版）. 吴天明. 北京: 人民邮电出版社, 2021-11-1.  
 
* Mark John Batty, Wolfson College. The C11 and C++11 Concurrency Model. Available at https://www.cs.kent.ac.uk/people/staff/mjb211/docs/toc.pdf, 2014-11-29.     


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

[12] 余华兵. Linux内核深度解析. 北京: 人民邮电出版社, 2019-05-01.  

[13] [美]Scott Meyers. Effective Modern C++(中文版). 高博. 北京: 中国电力出版社, 2018-4: 254.  