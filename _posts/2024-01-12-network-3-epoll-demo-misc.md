---
layout: post
title: "网络常识三：epoll 概念、demo 以及注意事项"
date: 2024-01-11
last_modified_at: 2024-01-11
categories: [网络]
tags: [网络 epoll]
---

* 目录  
{:toc}
<br/>

这又是一篇关于 epoll 的文章，附有一个 demo，以及一些注意事项。  

---

# demo

demo 参考自《Linux高性能服务器编程》[1]，地址： [https://github.com/antsmallant/antsmallant_blog_demo/tree/main/blog_demo/epoll_demo](https://github.com/antsmallant/antsmallant_blog_demo/tree/main/blog_demo/epoll_demo)   

---

# 概念及注意事项

---

## 阻塞vs非阻塞、同步vs异步

这里再明确一下这几个概念的本质区别：     

* 阻塞和非阻塞的差别在于，内核没有准备好数据时（比如可读或可写），调用 api 是否会导致线程挂起，阻塞是会挂起。   

* 同步和异步的差别在于，内核准备好数据时（比如可读或可写），是否需要主动调用 api 去读写，同步是需要。   


epoll 是一种同步非阻塞的 IO 模型。非阻塞体现在内核数据没准备好时，不会把你的线程挂起。同步体现在它只通知你有连接了、有数据可读了、缓存有空间可写了，不会帮你把这些事都做了，你需要自己去 accept，去 read，去 write。  
只不过这些 socket 描述符可以都设成非阻塞的，当你 accept 不到新连接，read 到没数据，写到没 buffer 时，不会把你挂起来等待，会返回 -1 之类的值，并且错误码设置为 EAGAIN（EWOULDBLOCK）之类的。   

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

## 

---

## EAGAIN and EWOULDBLOCK 的意义

ET 模式处理下处理 EPOLLIN 事件时，对于非阻塞 IO，如果返回结果小于 0，则要判断 errno，如果 errno 是 EAGAIN 或 EWOULDBLOCK，则表示此次数据已经读取完毕了，可以放心的结束本次读取，下次 epoll_wait 可以重新获得该事件通知。     

那么 EAGAIN, EWOULDBLOCK 表示什么意思？  
实际上，EWOULDBLOCK 的值与 EAGAIN 相等，EAGAIN 表示当前内核还没准备好（不可读或不可写），需要等待。   

---

## accept 的问题

### 阻塞模式下的 accpet[2]



### ET 模式下 accept[2]

多个连接同时到达的时候，tcp 的就绪队列堆积多个就绪连接，这时候 ET 模式下只通知一次，而 accept 每次只处理一个

---

# 参考

[1] 游双. Linux高性能服务器编程. 北京: 机械工业出版社, 2013-5.   

[2] Kimi. Epoll在LT和ET模式下的读写方式. Available at https://kimi.pub/515.html, 2012-7-10.   