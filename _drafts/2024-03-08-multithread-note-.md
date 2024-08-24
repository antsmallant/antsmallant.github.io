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