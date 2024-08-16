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

---

# 同步原语的性能对比

* 性能对比的论文
[More Than You Ever Wanted to Know about Synchronization: Synchrobench, Measuring the Impact of the Synchronization on Concurrent Algorithms](https://www.researchgate.net/profile/Vincent-Gramoli/publication/282921226_More_Than_You_Ever_Wanted_to_Know_about_Synchronization_Synchrobench_Measuring_the_Impact_of_the_Synchronization_on_Concurrent_Algorithms/links/573c005308ae9ace840eb23a/More-Than-You-Ever-Wanted-to-Know-about-Synchronization-Synchrobench-Measuring-the-Impact-of-the-Synchronization-on-Concurrent-Algorithms.pdf)


---

# 多线程编程的陷阱

## C++11 完善的多线程支持

上文中我们把问题暴露出来了，接下来需要探讨一下解决办法了。  

volatile 实际上只能阻止编译器优化，就不要让它再来帮忙多线程编程了，它应该只做 memory mapped i/o 的工作。  

那么现在需要一套完善的方案能同时解决问题一和问题二。   

针对问题二，我们是需要确保在 flag 设置之前，a 和 b 都设置了，实际上就是需要某种屏障，能确保 flag 之前的代码在 flag 之前运行。操作系统底层就有提供这种 barrier，比如 linux 提供的：  

```c
#define barrier() __asm__ __volatile__("" ::: "memory")
```

c++11 之前，使用的是一些多线程库，比如 wikipedia [11]这里展示了各种库：    

![multithread-wikipedia-list-of-cpp-multi-threading-libraries](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/multithread-wikipedia-list-of-cpp-multi-threading-libraries.png)   
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

# 拓展阅读

* Vincent Gramoli. More than You Ever Wanted to Know about Synchronization
 Synchrobench, Measuring the Impact of the Synchronization on Concurrent Algorithms. Available at https://perso.telecom-paristech.fr/kuznetso/INF346-2015/slides/gramoli-ppopp15.pdf, 2015.  

* Bryan Cantrill, Jeff Bonwick. Real-world Concurrency. Available at https://queue.acm.org/detail.cfm?id=1454462, 2008-10-24.   

* [英]Anthony Williams. C++并发编程实战（第2版）. 吴天明. 北京: 人民邮电出版社, 2021-11-1.  
 
* Mark John Batty, Wolfson College. The C11 and C++11 Concurrency Model. Available at https://www.cs.kent.ac.uk/people/staff/mjb211/docs/toc.pdf, 2014-11-29.     

---

# 参考

[1] ~青萍之末~. 多线程的同步与互斥（互斥锁、条件变量、读写锁、自旋锁、信号量）. Available at https://blog.csdn.net/daaikuaichuan/article/details/82950711, 2018-10-06.   

[2] [荷]Andrew S. Tanenbaum, Herbert Bos. 现代操作系统(原书第4版). 陈向群, 马洪兵, 等. 北京: 机械工业出版社, 2020-3(1).   

[3] [美]Randal E. Bryant, David R. O'Hallaron. 深入理解计算机系统(原书第3版). 龚奕利, 贺莲. 北京: 机械工业出版社, 2022-6(1).  

[4] [美]W. Richard Stevens, Stephen A. Rago. UNIX环境高级编程(第2版). 尤晋元, 张亚英, 戚正伟. 北京: 人民邮电出版社, 2006-5(1).  

[5] antsmallant. 网络常识二：同步、异步、阻塞、非阻塞. Available at https://blog.antsmallant.top/2024/01/19/synchronous-asynchronous-blocking-nonblocking, 2024-01-19.    

[6] Wikipedia. Synchronization (computer science). Available at https://en.wikipedia.org/wiki/Synchronization_(computer_science).   

[7] Martin Kleppmann. Please stop calling databases CP or AP. https://martin.kleppmann.com/2015/05/11/please-stop-calling-databases-cp-or-ap.html, 2015-5-11.  

[8] 俞甲子, 石凡, 潘爱民. 程序员的自我修养：链接、装载与库. 北京: 电子工业出版社, 2009-4.    

[9] bajamircea. C++11 volatile. Available at https://bajamircea.github.io/coding/cpp/2019/11/05/cpp11-volatile.html, 2019-11-5.    

[10] Wikipedia. List of C++ multi-threading libraries. Available at https://en.wikipedia.org/wiki/List_of_C%2B%2B_multi-threading_libraries.    

[11] Microsoft. volatile (C++). Available at https://learn.microsoft.com/en-us/cpp/cpp/volatile-cpp?view=msvc-170&viewFallbackFrom=vs-2019, 2021-9-21.  

[12] 余华兵. Linux内核深度解析. 北京: 人民邮电出版社, 2019-05-01.  

[13] [美]Scott Meyers. Effective Modern C++(中文版). 高博. 北京: 中国电力出版社, 2018-4: 254.  