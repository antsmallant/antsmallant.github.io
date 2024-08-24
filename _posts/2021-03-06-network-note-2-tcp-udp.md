---
layout: post
title: "计算机网络笔记：tcp 和 udp"
date: 2021-03-06
last_modified_at: 2021-5-1
categories: [计算机网络]
tags: [计算机网络]
---

* 目录  
{:toc}
<br/>

**持续更新**   

记录 tcp 和 udp 相关的知识。  

---

# 1. 常识

---

## tcp 容量

单个服务器可以支撑多少并发连接？经常听到 c10k，也就是单个服务器支持1万个客户端连接，但其实只要性能足够，c100k, c1000k, c10000k ... 都没有问题。  

因为每个 tcp 连接是四元组 (source_ip, source_port, target_ip, target_port) 确定一对连接的, 即使服务端侧的两个值 (target_ip, target_port) 是固定的，客户端侧 (source_ip, source_port) 的组合也几乎是无限的，在 ipv4 下，理论上限是 2^32 * 65535，即 2 的 48 次方，在 ipv6 下，就更夸张了。    

上面的计算只是为了说明理论上服务器可以支持超大的 tcp 连接数。实际中，服务器能建立的连接数取决于自身的配置，主要就是操作系统和内存。  

比如在 linux 下，每一条 tcp 连接都要消耗一些内存空间。     

---

## tcp 建立连接

tcp 为什么需要三次握手才能建立连接呢？为什么刚好三次就够了呢？  

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

---

## tcp 和 udp 可以监听同一个端口吗

可以。  

ipv4 包头有个 8 bit 的 protocol 字段 (ipv6 对应的字段名叫 Next header，大小也是 8 bit)，可以区分更上层的协议。其中 udp 的值是 17，tcp 的值是 6。  

![ipv4-head](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/network-ipv4-head.png)
<center>图2：ipv4包头 [2]</center>  

<br/>

在这里（ https://en.wikipedia.org/wiki/List_of_IP_protocol_numbers ）可以看到 100 多个其他的协议。  
![ip protocals](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/network-ip-protocols.png)
<center>图3：ip protocals [3]</center>  

---

## tcp 状态

tcp 状态是一个颇为复杂的知识点，tcp 连接总共有 11 种状态，下面这个图只是对于 tcp 状态机的一种简化，实际上还有很多细节的，具体可以看 rfc9293（ https://www.rfc-editor.org/rfc/rfc9293 ）。   

![tcp state machine](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/network-Tcp_state_diagram.png)
<center>图4：tcp state machine [4]</center>   

---

# 2. 参考

[1] Wikipedia. Transmission_Control_Protocol. Available at https://en.wikipedia.org/wiki/Transmission_Control_Protocol.     

[2] Wikipedia. Internet_Protocol_version_4. Available at https://en.wikipedia.org/wiki/Internet_Protocol_version_4.    

[3] Wikipedia. List_of_IP_protocol_numbers. Available at https://en.wikipedia.org/wiki/List_of_IP_protocol_numbers.   

[4] Wikipedia. Tcp_state_diagram. Available at https://upload.wikimedia.org/wikipedia/en/5/57/Tcp_state_diagram.png.       

[5] Wikipedia. Tcp-handshake. Available at https://upload.wikimedia.org/wikipedia/commons/9/98/Tcp-handshake.svg.  