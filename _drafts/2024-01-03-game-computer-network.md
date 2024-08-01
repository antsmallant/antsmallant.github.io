---
layout: post
title: "游戏开发之网络常识"
date: 2024-01-03
last_modified_at: 2024-01-03
categories: [游戏开发]
tags: [game, net]
---

* 目录  
{:toc}
<br/>


作为后端开发，特别是网游后端开发，需要频繁跟网络打交道，写这篇文章主要是记录：网络基础知识，网络问题的诊断思路，网络相关的工具。  

---

# tcp

## tcp 容量

单个服务器可以支撑多少并发连接？经常听到 c10k，也就是单个服务器支持1万个客户端连接，但其实只要性能足够，c100k, c1000k, c10000k ... 都没有问题。  

因为每个 tcp 连接是四元组 (source_ip, source_port, target_ip, target_port) 确定一对连接的, 即使服务端侧的两个值 (target_ip, target_port) 是固定的，客户端侧 (source_ip, source_port) 的组合也几乎是无限的，在 ipv4 下，理论上限是 2^32 * 65535，即 2 的 48 次方，在 ipv6 下，就更夸张了。    

上面的计算只是为了说明理论上服务器可以支持超大的 tcp 连接数。实际中，服务器能建立的连接数取决于自身的配置，主要就是操作系统和内存。  

比如在 linux 下，每一条 tcp 连接都要消耗一些内存空间。     


## tcp 建立连接

tcp 为什么需要三次握手才能建立连接呢？为什么刚好三次就够了呢？  

先直接说结论：

* 防止重复历史连接的初始化
* 确定好双方的初始序列号

![tcp-head](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/network-tcp-head.png)
<center>图1：tcp包头 [1]</center>

这个跟 tcp 的目标有关，tcp 是一个保证消息包可靠有序到达的协议，在设计上为了达到这个目标，在包头加了两个字段，一个叫 **序列号码**，另一个叫 **确认号码**，通过这一对数字来实现可靠有序的特性。  

tcp 握手就是为了协商双方的初始序列号，要完成这个过程，至少也要两次握手：  

* 第一次：A -> B 一个SYN包（seq=a）。  
* 第二次：B -> A 一个SYN-ACK包（seq=b,ack=a+1）。

以上如果网络一切正常，也是能 work 的，双方互相发送了自己的初始 seq 号码。  

但如果发生这样的情况，就会出问题了：第一次握手的包隔了好久才到达 B，以至于 A 以为握手不成功，把连接断开了，但 B 不知道连接断开了，它回了一个 SYN-ACK 包之后yi

![tcp connect handshake](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/network-tcp-3-handshake.png)
<center>图2：tcp connect handshake [5]</center>   

值得注意的是，第三次握手的数据包是可以携带数据的。  

## tcp 释放连接


## 黏包问题


## tcp 和 udp 可以监听同一个端口吗

可以。  

ipv4 包头有个 8 bit 的 protocol 字段 (ipv6 对应的字段名叫 Next header，大小也是 8 bit)，可以区分更上层的协议。其中 udp 的值是 17，tcp 的值是 6。  

![ipv4-head](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/network-ipv4-head.png)
<center>图2：ipv4包头 [2]</center>  

<br/>

在这里（ https://en.wikipedia.org/wiki/List_of_IP_protocol_numbers ）可以看到 100 多个其他的协议。  
![ip protocals](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/network-ip-protocols.png)
<center>图3：ip protocals [3]</center>  


## tcp 状态

tcp 状态是一个颇为复杂的知识点，tcp 连接总共有 11 种状态，下面这个图只是对于 tcp 状态机的一种简化，实际上还有很多细节的，具体可以看 rfc9293（ https://www.rfc-editor.org/rfc/rfc9293 ）。   

![tcp state machine](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/network-Tcp_state_diagram.png)
<center>图4：tcp state machine [4]</center>   

### tcp 之 close_wait

### tcp 之 time_wait


## tcp 重传、滑动窗口、拥塞控制、流量控制

---

# udp

## kcp

游戏里面经常用到 kcp，下面讲讲它的性能以及工作原理。  


---

# io 模型之 epoll

## 一个 demo

demo 地址： [https://github.com/antsmallant/antsmallant_blog_demo/tree/main/blog_demo/epoll_demo](https://github.com/antsmallant/antsmallant_blog_demo/tree/main/blog_demo/epoll_demo)

## epoll 注意事项

这篇文章写的不错：[Epoll在LT和ET模式下的读写方式](https://kimi.pub/515.html)

### LT vs ET

这是 epoll 的两种工作模式，LT 代表水平触发，ET 代表边缘触发，默认模式是 LT。  

LT 表示 epoll_wait 获得该句柄的事件通知后，可以不处理该事件，下次 epoll_wait 时还能获得该事件通知，直到应用程序处理了该事件。      

ET 表示 epoll_wait 获得该句柄的事件通知后，必须立即处理，下次 epoll_wait 不会再收此事件通知。  

通俗的理解就是：LT 模式下，一个 socket 处于可读或可写时，epoll_wait 都会返回该 socket；ET 模式下，一个 socket 从不可读变为可读或从不可写变为可写时，epoll_wait 才会返回该 socket。  

ET 模式看起来高效一些，但实际上编程复杂度更高很多，容易出现一些错误，所以实现上采用 LT 是一种更稳妥的做法。  


### LT 模式下写的问题

LT 模式下，当 socket 可写，会不停的触发可写事件，应该怎么办?   

这个问题有两种策略：    

* 策略 1：需要写的时候，才注册 socket 的 epollout 事件，等写完的时候，反注册 epollout 事件。    

* 策略 2：先写，遇到 EAGAIN 错误的时候再注册 socket 的 epollout 事件，等写完的时候，反注册 epollout 事件。  

策略 2 更好一些，可以避免写一点点数据也要注册并等待 epollout 事件。  


### EAGAIN and EWOULDBLOCK 的意义

ET 模式处理下处理 EPOLLIN 事件时，对于非阻塞 IO，如果返回结果小于 0，则要判断 errno，如果 errno 是 EAGAIN 或 EWOULDBLOCK，则表示此次数据已经读取完毕了，可以放心的结束本次读取，下次 epoll_wait 可以重新获得该事件通知。     

那么 EAGAIN, EWOULDBLOCK 表示什么意思？  
实际上，EWOULDBLOCK 的值与 EAGAIN 相等，EAGAIN 表示当前内核还没准备好（不可读或不可写），需要等待。   


### ET 模式下 accept 的问题


---

# 一些 socket 问题

## socket read 返回 0

当对端正常的关闭之后，read 就会返回 0。   

有时候 select 返回可读，但是 read 得到的结果是 0。这并不矛盾，select > 0 表示套接字有东西，read = 0 表示这东西是对方关闭连接。  

---

# IO 复用

## reactor 和 proactor


---

# 参考

[1] Wikipedia. Transmission_Control_Protocol. Available at https://en.wikipedia.org/wiki/Transmission_Control_Protocol.     

[2] Wikipedia. Internet_Protocol_version_4. Available at https://en.wikipedia.org/wiki/Internet_Protocol_version_4.    

[3] Wikipedia. List_of_IP_protocol_numbers. Available at https://en.wikipedia.org/wiki/List_of_IP_protocol_numbers.   

[4] Wikipedia. Tcp_state_diagram. Available at https://upload.wikimedia.org/wikipedia/en/5/57/Tcp_state_diagram.png.       

[5] Wikipedia. Tcp-handshake. Available at https://upload.wikimedia.org/wikipedia/commons/9/98/Tcp-handshake.svg.      