---
layout: post
title: "多线程编程二：对 volatile 的误解"
date: 2024-03-03
last_modified_at: 2024-03-03
categories: [并发与多线程]
tags: [并发 同步 多线程]
---

* 目录  
{:toc}
<br/>

本文总结 c++ 中 volatile 相关的一些知识。在多线程领域，它是被误解得最严重的，实际上，它对于多线程编程一点帮助都没有。   

---

# 1. 被误解的 volatile

先说一下结论：  

* volatile 只能阻止编译器优化，应该只把它用于 Memory Mapped I/O 的场景中，不应该将它用于解决多线程下的诸入原子读写之类的问题。    

* C++11 引入的 memory model，可以很好的解决多线程下的内存顺序问题，应该使用相关的机制。   

Scott Meyers 在《Effective Modern C++》的条款40[1]说到：“可怜的 volatile。被误解到如此地步。它甚至不应该出现在本章中，因为它与并发程序设计毫无关系。”。    

要了解清楚 volatile 是如何被误解和滥用的，需要先了解一下它的历史。下文主要参考自这篇文章：[《C++11 volatile》](https://bajamircea.github.io/coding/cpp/2019/11/05/cpp11-volatile.html) [2]。  

---

# 2. volatile 的原始用途

最开始是 C 语言引入的，用在 Memory Mapped I/O 中，避免编译器优化导致的错误。  

Memory Mapped I/O 是把 I/O 设备的读写映射到一段内存区域中，假设一个最简单的设备，这个设备只有一个写接口，映射到了内存中的变量 A。每次给变量 A 赋值，相当于向设备写一次。   

如果我们想向这个设备分别写两次值，第一次写入 1，第二次写入 1000，将会这样写逻辑：  

```cpp
B = 1;
B = 1000;
```

但是，由于编译器优化，可能会把第一句：` B = 1; ` 优化掉，只保留 `B = 1000;` ，这显然不符合我们的意图。  

为了解决这种问题，C 引入了 volatile 关键字，用它这样修饰变量：`volatile int B;`，可以阻止编译器针对此变量的优化，编译器将不会再 “吞掉” `B = 1;` 这句代码了。   

<br/>

小结一下:  
* C 引入 volatile 是为了解决 Memory Mapped I/O 场景下的编译器错误优化问题。  

---

# 3. volatile 在 C++ 中的使用

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

![multithread-producer-consumer-expect-order](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/multithread-producer-consumer-expect-order.png)   
<center>图1：生产者消费者期望工作状态</center>

但实际上编译器优化过后，可能是这样的工作过程：生产者先写了 flag，消费者判断到 flag 为 true，开始读 a 和 b，之后生产者才开始写 a 和 b。大致如下图：  

![multithread-producer-consumer-unexpect-order](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/multithread-producer-consumer-unexpect-order.png)   
<center>图2：生产者消费者乱序状态</center>

如果按以上顺序执行，消费者可能会读到不正确的 a 和 b 值。  

这个问题出在 volatile 只控制 flag 不被编译器优化，不能约束 a 和 b 的写入顺序，所以编译器优化可能导致执行顺序与意图不一致，这种问题就是内存顺序问题。    

但实际上，除了编译器优化会导致指令重排（compiler reordering），cpu 也可能乱序执行。几十年前，cpu 为了提高效率就发展出动态调度机制，在执行过程中可能交换指令的顺序（cpu reordering）。所以，cpu 的乱序执行能力也会导致相同的问题。   

<br/>

小结一下:   

* volatile 不能解决多线程编程的问题，多线程编程不应该依赖它。  

* 内存顺序是多线程编程中难以察觉，但又很致命的问题。  

---

# 4. 某些编译器赋予 volatile 额外的能力

上文提到 volatile 无法阻止 reordering，但并不是所有 volatile 的实现都无法阻止，这取决于不同的编译器实现，有些编译器实现就通过插入屏障（barrier）的方式来阻止 reordering，比如说 Microsoft 的编译器。  

microsoft 在这篇文章[《volatile (C++)》](https://learn.microsoft.com/en-us/cpp/cpp/volatile-cpp?view=msvc-170&viewFallbackFrom=vs-2019) [3] 介绍了 volatile 的两个编译器选项：   

* 当使用 `/volatile:iso` 选项的时候，volatile 就只能用于硬件访问 (hardware access)，即 memory mapped i/o，不应该把它用于跨线程编程。    

* 当使用 `/volatile:ms` 选项的时候，正如文章所说的，它能够实现这样的效果：    

>When the /volatile:ms compiler option is used—by default when architectures other than ARM are targeted—the compiler generates extra code to maintain ordering among references to volatile objects in addition to maintaining ordering to references to other global objects. In particular:  
> 
>A write to a volatile object (also known as volatile write) has Release semantics; that is, a reference to a global or static object that occurs before a write to a volatile object in the instruction sequence will occur before that volatile write in the compiled binary.
>
>A read of a volatile object (also known as volatile read) has Acquire semantics; that is, a reference to a global or static object that occurs after a read of volatile memory in the instruction sequence will occur after that volatile read in the compiled binary.   
>
>This enables volatile objects to be used for memory locks and releases in multithreaded applications.


翻译过来就是：   

1、写一个 volatile 修饰的变量时，在写之前对其他 global 或 static 变量的访问确保发生在此之前。   
2、读一个 volatile 修改的变量时，在读之前对其他 global 或 static 变量的访问确保发生在此之前。  

这样一来确实可以解决上面的问题二，也就是说微软编译器通过增强 volatile，把问题一、二都解决了。  

但是，尽管有这种额外实现，我们仍然不应该依赖它，因为这样会严重制约我们代码的可移植性。   

<br/>

除了 Microsoft 的编译器，其他编译器对于 volatile 的处理也有其他问题，比如以下帖子和文章讲的：    

* [《Curious thing about the volatile keyword in C++》](https://www.reddit.com/r/cpp/comments/592sui/curious_thing_about_the_volatile_keyword_in_c/) [4]  

* [《A note about the volatile keyword in C++》](https://componenthouse.com/2016/10/21/a-note-about-the-volatile-keyword-in-cpp/) [5]   

---

# 5. 总结

* 多线程编程中，不要依赖 volatile。  

---

# 6. 参考

[1] [美]Scott Meyers. Effective Modern C++(中文版). 高博. 北京: 中国电力出版社, 2018-4: 254.    

[2] bajamircea. C++11 volatile. Available at https://bajamircea.github.io/coding/cpp/2019/11/05/cpp11-volatile.html, 2019-11-5.    

[3] Microsoft. volatile (C++). Available at https://learn.microsoft.com/en-us/cpp/cpp/volatile-cpp?view=msvc-170&viewFallbackFrom=vs-2019, 2021-9-21.  

[4] reddit. Curious thing about the volatile keyword in C++. Available at https://www.reddit.com/r/cpp/comments/592sui/curious_thing_about_the_volatile_keyword_in_c/, 2016.     

[5] HUGO V. TEIXEIRA. A note about the volatile keyword in C++. Available at https://componenthouse.com/2016/10/21/a-note-about-the-volatile-keyword-in-cpp/, 2016-10-21.    