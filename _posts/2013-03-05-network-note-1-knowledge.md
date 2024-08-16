---
layout: post
title: "网络笔记一：常识"
date: 2013-3-5
last_modified_at: 2021-5-1
categories: [网络]
tags: [网络]
---

* 目录  
{:toc}
<br/>

**持续更新**   

记录网络相关的常识，以及使用过程中遇到的问题。    

# 1. 常识

---

## socket read/write 的返回值处理

参考：[socket读写返回值的处理](https://cloud.tencent.com/developer/article/1021456)    

1、返回值大于 0

read/write 返回值大于 0，表示从缓冲区读取或写入的实际字节数目。   

2、返回值等于 0

read 返回 0，表示对端已经关闭 socket，本端也需要相应关闭。有时候 select 结果 > 0，但是 read 却返回 0，这是正常现象，select > 0 表示有事件发生，而事件就是对端关闭 socket 了，所以 read 返回 0。   

write 返回 0，表示缓冲区写满了，等下次再写。   

3、返回值等于 -1

read/write 返回 -1，根据 errno 判断:
    3.1）EINTR，表示系统当前中断了，可以忽略；  
    3.2）EAGAIN / EWOULDBLOCK(两个的值是相等的)，

## 零拷贝

参考： [什么是零拷贝？](https://xiaolincoding.com/os/8_network_system/zero_copy.html#_9-1-%E4%BB%80%E4%B9%88%E6%98%AF%E9%9B%B6%E6%8B%B7%E8%B4%9D)

---

# 2. 参考