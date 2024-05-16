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

# epoll demo

demo 参考自《Linux高性能服务器编程》[1]，这个 demo 分别展示了 et 模式以及 lt 模式的用法。  

demo 地址： [https://github.com/antsmallant/antsmallant_blog_demo/tree/main/blog_demo/epoll_demo](https://github.com/antsmallant/antsmallant_blog_demo/tree/main/blog_demo/epoll_demo)   

---

# epoll 概念及注意事项

---

## 阻塞vs非阻塞、同步vs异步

这里再明确一下这几个概念的本质区别：     

* 阻塞和非阻塞的差别在于，内核没有准备好数据时（比如可读或可写），调用 api 是否会导致线程挂起，阻塞是会挂起。   

* 同步和异步的差别在于，内核准备好数据时（比如可读或可写），是否需要主动调用 api 去读写，同步是需要。   

另外有一点要注意的，阻塞与非阻塞是设置在文件描述符上的属性，而不是 api (比如 accept, read, write) 本身，api 本身没分阻塞与非阻塞，当 api 操作的是阻塞的文件描述符，那它就以阻塞的方式工作。   

## epoll 的本质

epoll 是一种同步阻塞的 I/O 复用模型：  

* 阻塞体现在内核数据没准备好时，会把你挂起在 epoll_wait 上。 

* 同步体现在它只通知你有连接了、有数据可读了、缓存有空间可写了，不会帮你把这些事都做了，你需要自己去 accept，去 read，去 write。只不过这些 socket 描述符可以都设成非阻塞的，当 accept 不到新连接，read 到没数据，写到没 buffer 时，不会挂起来等待，会返回 -1 之类的值，然后错误码设置为 EAGAIN（EWOULDBLOCK）之类的。   

看起来，epoll 没啥厉害的，又是阻塞，又是同步的。事实上，它的优势体现在于可以同时等待多个描述符就绪。有了它，即使有上万条连接，也不需要每条连接都阻塞的调用 read 等待数据了，可以用 epoll 等待，收到就绪通知后，再非阻塞的调用 read 去读数据。  

这就引出另一种 I/O 模型，即在多线程中使用阻塞式 I/O，每个文件描述符一个线程，每个线程里可以自由的调用阻塞式 I/O。这里不做展开了。  

--- 

## epoll 与阻塞

既然 epoll 可以帮 socket 等待是否就绪的通知，socket 可以以非阻塞的方式工作。那反过来想一下，socket 偏偏要用阻塞的方式工作，可以吗？  

就比如 socket1 没有设置非阻塞，保持默认的阻塞属性。 epoll 等待到 socket1 可读了，这时候开一条线程，以阻塞方式去 read 这个 socket1 可以吗？  

答案是：没问题，阻塞的 read socket1，如果 read 到没数据就挂起在那里。等到内核有数据可读时，如果还没有被 read，那么 epoll 也是会等待掉就绪通知的。当 epoll 通知的时候，你再去 read，也是一样的，就阻塞 read 而已。  

这个脑洞其实是比较偏的，只是为了说明这种做法的可能性，而不是真的建议这么做，这么做很愚蠢。   

代码验证： [https://github.com/antsmallant/antsmallant_blog_demo/blob/main/blog_demo/epoll_blocking_demo/epoll_blocking_demo.cpp](https://github.com/antsmallant/antsmallant_blog_demo/blob/main/blog_demo/epoll_blocking_demo/epoll_blocking_demo.cpp)  

---

## LT vs ET

这是 epoll 的两种工作模式，LT 代表水平触发，ET 代表边缘触发，默认模式是 LT。  

LT 表示 epoll_wait 获得该句柄的事件通知后，可以不处理该事件，下次 epoll_wait 时还能获得该事件通知，直到应用程序处理了该事件。      

ET 表示 epoll_wait 获得该句柄的事件通知后，必须立即处理，下次 epoll_wait 不会再收此事件通知。  

通俗的理解就是：LT 模式下，一个 socket 处于可读或可写时，epoll_wait 都会返回该 socket；ET 模式下，一个 socket 从不可读变为可读或从不可写变为可写时，epoll_wait 才会返回该 socket。  

ET 模式看起来高效一些，但实际上编程复杂度更高很多，容易出现一些错误，所以实现上采用 LT 是一种更稳妥的做法。  

---

## LT 模式下写的问题

LT 模式下，当 socket 可写，会不停的触发可写事件，应该怎么办?   

这个问题有两种策略：  

* 策略 1 ：需要写的时候，才注册 socket 的 epollout 事件，等写完的时候，反注册 epollout 事件。    

* 策略 2 ：先写，遇到 EAGAIN 错误的时候再注册 socket 的 epollout 事件，等写完的时候，反注册 epollout 事件。  

策略 2 更好一些，可以避免写一点点数据也要注册并等待 epollout 事件。   

---

## EAGAIN and EWOULDBLOCK 的意义

ET 模式处理下处理 EPOLLIN 事件时，对于非阻塞 I/O，如果返回结果小于 0，则要判断 errno，如果 errno 是 EAGAIN 或 EWOULDBLOCK，则表示此次数据已经读取完毕了，可以放心的结束本次读取，下次 epoll_wait 可以重新获得该事件通知。     

那么 EAGAIN, EWOULDBLOCK 表示什么意思？  
实际上，EWOULDBLOCK 的值与 EAGAIN 相等，EAGAIN 表示当前内核还没准备好（不可读或不可写），需要等待。   

---

## accept 的问题

### 阻塞模式下的 accpet[2]



### ET 模式下 accept[2]

多个连接同时到达的时候，tcp 的就绪队列堆积多个就绪连接，这时候 ET 模式下只通知一次，而 accept 每次只处理一个

---

## epoll 与 select、poll 的区别

---

# 参考

[1] 游双. Linux高性能服务器编程. 北京: 机械工业出版社, 2013-5.   

[2] Kimi. Epoll在LT和ET模式下的读写方式. Available at https://kimi.pub/515.html, 2012-7-10.   