---
layout: post
title: "网络常识三：epoll demo、概念及注意事项"
date: 2024-01-11
last_modified_at: 2024-01-11
categories: [网络]
tags: [网络 epoll]
---

* 目录  
{:toc}
<br/>


这是一篇关于 epoll 的文章，包含一个展示 et 模式和 lt 模式的 demo，以及一些注意事项。   

---

# 1. epoll demo

demo 参考自《Linux高性能服务器编程》[1]，这个 demo 分别展示了 et 模式以及 lt 模式的用法。  

demo 地址： [https://github.com/antsmallant/antsmallant_blog_demo/tree/main/blog_demo/epoll_demo](https://github.com/antsmallant/antsmallant_blog_demo/tree/main/blog_demo/epoll_demo)   

---

# 2. epoll 概念及注意事项

---

## 2.1 阻塞vs非阻塞、同步vs异步

这里再明确一下这几个概念的本质区别：     

* 阻塞和非阻塞的差别在于，内核没有准备好数据时（比如可读或可写），调用 api 是否会导致线程挂起，阻塞是会挂起。   

* 同步和异步的差别在于，内核准备好数据时（比如可读或可写），是否需要主动调用 api 去读写，同步是需要。   

另外有一点要注意的，阻塞与非阻塞是设置在文件描述符上的属性，而不是 api (比如 accept, read, write) 本身，api 本身没分阻塞与非阻塞，当 api 操作的是阻塞的文件描述符，那它就以阻塞的方式工作。   

---

## 2.2 epoll 的本质

epoll 是一种同步阻塞的 I/O 复用模型：  

* 阻塞体现在内核数据没准备好时，会把你挂起在 epoll_wait 上。   

* 同步体现在 epoll_wait 到内核有就绪事件的时候，是 epoll_wait 自己（也就是调用者）把数据从内核空间拷贝到用户空间。   

看起来，epoll 没啥厉害的，又是阻塞，又是同步的。事实上，它的优势体现在于可以同时等待多个描述符就绪。有了它，即使有上万条连接，也不需要每条连接都阻塞的调用 read 等待数据可读，可以用 epoll 等待，收到就绪通知后，再非阻塞的调用 read 去读数据。   

这就引出另一种 I/O 模型，即在多线程中使用阻塞式 I/O，每个文件描述符一个线程，每个线程里可以自由的调用阻塞式 I/O。这里不做展开了。  

--- 

## 2.3 epoll 与阻塞

既然 epoll 可以帮 socket 等待是否就绪的通知，socket 可以以非阻塞的方式工作。那反过来想一下，socket 偏偏要用阻塞的方式工作，可以吗？  

就比如 socket1 没有设置非阻塞，保持默认的阻塞属性。 epoll 等待到 socket1 可读了，这时候开一条线程，以阻塞方式去 read 这个 socket1 可以吗？  

答案是：没问题，阻塞的 read socket1，如果 read 到没数据就挂起在那里。等到内核有数据可读时，如果还没有被 read，那么 epoll 也是会等待掉就绪通知的。当 epoll 通知的时候，你再去 read，也是一样的，就阻塞 read 而已。  

这个脑洞其实是比较偏的，只是为了说明这种做法的可能性，而不是真的建议这么做，这么做很愚蠢。   

代码验证： [https://github.com/antsmallant/antsmallant_blog_demo/blob/main/blog_demo/epoll_blocking_demo/epoll_blocking_demo.cpp](https://github.com/antsmallant/antsmallant_blog_demo/blob/main/blog_demo/epoll_blocking_demo/epoll_blocking_demo.cpp)  

代码里，我在 recv 线程里做了 sleep 1 秒，否则 epoll_wait 很慢捕捉到读就绪通知。因为 epoll_wait 的内部实现是醒一下睡一下（schedule_timeout），直到获取到就绪事件，而线程阻塞在 recv 时，只要有数据可读就会立即被唤醒，所以它的反应往往是比 epoll_wait 快一点点。   

---

## 2.4 LT vs ET

这是 epoll 的两种工作模式，LT 代表水平触发，ET 代表边缘触发，默认模式是 LT。  

LT 表示 epoll_wait 获得该句柄的事件通知后，可以不处理该事件，下次 epoll_wait 时还能获得该事件通知，直到应用程序处理了该事件。      

ET 表示 epoll_wait 获得该句柄的事件通知后，必须立即处理，下次 epoll_wait 不会再收此事件通知。  

通俗的理解就是：LT 模式下，一个 socket 处于可读或可写时，epoll_wait 都会返回该 socket；ET 模式下，一个 socket 从不可读变为可读或从不可写变为可写时，epoll_wait 才会返回该 socket。  

ET 模式看起来高效一些，但实际上编程复杂度更高很多，容易出现一些错误，所以实现上采用 LT 是一种更稳妥的做法。  

---

## 2.5 LT 模式下写的问题

LT 模式下，当 socket 可写，会不停的触发可写事件，应该怎么办?   

这个问题有两种策略：  

* 策略 1 ：需要写的时候，才注册 socket 的 epollout 事件，等写完的时候，反注册 epollout 事件。    

* 策略 2 ：先写，遇到 EAGAIN 错误的时候再注册 socket 的 epollout 事件，等写完的时候，反注册 epollout 事件。  

策略 2 更好一些，可以避免写一点点数据也要注册并等待 epollout 事件。   

---

## 2.6 EAGAIN and EWOULDBLOCK 的意义

ET 模式处理下处理 EPOLLIN 事件时，对于非阻塞 I/O，如果返回结果小于 0，则要判断 errno，如果 errno 是 EAGAIN 或 EWOULDBLOCK，则表示此次数据已经读取完毕了，可以放心的结束本次读取，下次 epoll_wait 可以重新获得该事件通知。     

那么 EAGAIN, EWOULDBLOCK 表示什么意思？  
实际上，EWOULDBLOCK 的值与 EAGAIN 相等，EAGAIN 表示当前内核还没准备好（不可读或不可写），需要等待。   

---

## 2.7 accept 的问题

这个问题其实不是 epoll 特定问题，在其他情况下 (比如 select, poll) 也都可能发生。  

首先假设 listen 的 fd 没有设置为非阻塞模式，然后无论是 epoll / select / poll 收到这个 fd 上有新连接就绪的通知，这时候代码逻辑开始执行 accept，我们知道，accept 每次只处理一条连接，而此时又刚好有连接，那么即使这个 fd 现在是阻塞模式，也依然是可以非阻塞的处理成功的。   

然而，还是会有意外的情况，就是在 accept 之前，如果对面客户端发了个 RST 把连接中断了，这时内核也连带把这条连接从连接就绪队列移除掉了，并且，这时连接就绪队列空了。悲剧就发生了，要 accept 的时候，没有就绪连接了，于是，accept 就挂起了，阻塞起来了。  

要解决这个问题，很简单，老老实实把 listen 的 fd 设置为非阻塞模式就好了。  

至于在 epoll 的 ET 模式，还需要做的就是，每次收到有连接就绪的通知，就 while 循环 accept，直到 accept 不到新连接再收手就 ok 了[2]。  

---

## 2.8 epoll 与 select、poll 的区别

可以说，有三大区别：   

* 调用方式上，select 跟 poll 每次都需要把所有的 FD 集合传给内核去获取事件通知，返回后，再一个个判断有没有事件发生；而 epoll 已经通过 epoll_ctl 把所有 FD 都注册到内核了，每次 epoll_wait 会获得一份只有事件发生的 FD 集合。  

* 调用限制上，select 有 FD_SETSIZE 个数限制，每次轮循只能传 FD_SETSIZE 个 FD 进去，在多数系统，这个值是 1024，至于为啥是 1024，可以参照这篇文章《A history of the fd_set, FD_SETSIZE, and how it relates to WinSock》[3]；poll 和 epoll 约等于没限制，它们的上限是系统的最大文件描述符，可通过 `cat /proc/sys/fs/file-max` 查看。  

* 实现方式上，select 跟 poll 每次都需要重新把当前进程挂到各个文件描述符的等待队列上，而 epoll 在 epoll_ctl 的时候就一次性挂好了。     

无论从调用方式还是实现方式上看，epoll 都比 select 和 poll 要高效很多。   

具体的关于 select 和 epoll 的实现，可以参考这两篇文章，分析得很深入：《图解 | 深入揭秘 epoll 是如何实现 IO 多路复用的》[4]，《深入学习IO多路复用 select/poll/epoll 实现原理》[5]。  


---

# 3. 参考

[1] 游双. Linux高性能服务器编程. 北京: 机械工业出版社, 2013-5.   

[2] Kimi. Epoll在LT和ET模式下的读写方式. Available at https://kimi.pub/515.html, 2012-7-10.   

[3] Raymond Chen. A history of the fd_set, FD_SETSIZE, and how it relates to WinSock. Available at https://devblogs.microsoft.com/oldnewthing/20221102-00/?p=107343, 2022-11-2.  

[4] 张彦飞. 深入揭秘 epoll 是如何实现 IO 多路复用的！. Available at https://mp.weixin.qq.com/s?__biz=MjM5Njg5NDgwNA==&mid=2247484905&idx=1&sn=a74ed5d7551c4fb80a8abe057405ea5e, 2021-03-17.    

[5] mingguangtu. 深入学习IO多路复用 select/poll/epoll 实现原理. Available at https://mp.weixin.qq.com/s?__biz=MjM5ODYwMjI2MA==&mid=2649774761&idx=1&sn=cd93afad37fecb2071d72d7e0dfebf5e, 2022-12-07.   