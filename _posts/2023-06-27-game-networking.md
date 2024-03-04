---
layout: post
title: "游戏中的网络同步技术"
date: 2023-06-27
last_modified_at: 2023-06-27
categories: [game networking]
---

网游中的网络同步技术已经被研究很长时间了，有不少文章都在探讨这项技术，在拜读了一系列文章之后，打算自己做一次归纳总结。  

这项技术发展到至今，大体上可以归纳为三种做法，分别是 Deterministic LockStep, Snapshot Interpolation, State Synchronization。这个划分参考自 Glenn Fielder[1]。其实国内的韦易笑、Jerish 在各自文章中的所做的划分也是大同小异，韦易笑老师在他的文章中把网络同步归类为两大种:帧间同步、状态同步。  

gdc2017 overwatch 的这个分享 Replay-Technology-in-Overwatch-Kill ( https://gdcvault.com/play/1024053/Replay-Technology-in-Overwatch-Kill ) 也引用了 Glenn Fiedler，把主流的网络同步模型分为了以上三类。 

![gdc2017-overwatch-network-synchronization-models](https://blog.antsmallant.top/media/blog/2023-06-27-game-networking/gdc2017-overwatch-network-synchronization-models.png)  
<center>图1：overwatch 分享中对于网络同步模型的划分</center>


## LockStep 
这在国内大致相当于帧同步，帧同步按照韦易笑老师的说法，应该得叫帧间同步才对，它是一系列算法的集合，其共同特征是“确保每帧（逻辑帧）输入一致，传统实现有帧锁定，乐观帧锁定，lockstep，bucket 同步等等”[1]。   

韦易笑老师列举的几种实现，其中乐观帧锁定与 bucket 同步是类似的，就是一种超时不等待的策略，原始 lockstep 即 deterministic lockstep 是要求每个 turn 都要等待收到所有的输入才能推进到下一个 turn，而乐观帧锁定或者说 bucket 同步则是规定了每个 turn 有固定时长，超过这个时长的没接收到输入的就默认无输入，自动进入下一个 turn。但是帧锁定跟 lockstep 有何区别呢？一开始我以为是同一回事，但仔细看了韦老师的这篇文章[2]，才大致明白其中的小区别是：帧锁定是每 N 帧有一个 “关键帧”，锁的是关键帧，而 lockstep 是每帧都锁。   


## Snapshot Interpolation

## State Synchronization


## 推荐阅读



## 参考
[1] 
[2] 韦易笑. 关于 “帧同步”说法的历史由来 ( https://zhuanlan.zhihu.com/p/165293116 ). 2020.08.   
[3] 韦易笑. 帧锁定同步算法 ( https://www.skywind.me/blog/archives/131 ). 2007.2.   
