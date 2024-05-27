---
layout: post
title: "网络游戏同步技术一：分类及差异"
date: 2023-07-01
last_modified_at: 2023-07-01
categories: [游戏开发]
---

* 目录  
{:toc}
<br/>


网游中的网络同步技术已经被研究很长时间了，有不少文章都在探讨这项技术，在拜读了一系列文章之后，打算自己做一次归纳总结。  

游戏中的网络同步相对于普通互联网应用更复杂很多，因为它要实现的不单是数据上的同步，还有表现上的同步，另外，高互动需求导致对于延迟极其敏感，可以说，游戏中的网络同步的大部分优化都是在于延迟对抗。  

这项技术发展至今，大体上可以归类为三种做法，分别是 Deterministic LockStep, Snapshot Interpolation, State Synchronization。   

这个划分参考自 Glenn Fielder[1-3]。韦易笑、Jerish 在各自文章中的所做的划分也是大同小异，韦易笑老师在他的文章中把网络同步归类为两大种:帧间同步、状态同步。gdc2017 overwatch 的这个分享 Replay-Technology-in-Overwatch-Kill 也引用了 Glenn Fiedler，把主流的网络同步模型分为了以上三类，这个视频的文字翻译版在此[4]。    

![gdc2017-overwatch-network-synchronization-models](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/game-networking-gdc2017-overwatch-network-synchronization-models.png)  
<center>图1：overwatch 分享中对于网络同步模型的划分</center>

---

# 同步方式的核心差异

开门见山，直接把差异写出来，国内有不少文章，会把传输的数据是 “玩家操作” 还是 “状态数据” 作为差异，然而这并不是真正的差异的，而是因为工作方式的不同，导致的一种表象而已。  

|同步方式|国内叫法|核心特点|
|--|--|--|
|Deterministic LockStep|帧同步|客户端各自模拟，并且假定在相同初始状态，相同每帧输入的情况下，所有端的每帧模拟结果都相同；客户端画面可以做到每帧完全一致|
|State Synchronization|状态同步|服务端模拟，客户端也可以模拟（预测先行）；服务端结果是权威结果，服务端在合适时间向各个客户端同步差异化的结果；客户端画面不保证一致|
|Snapshot Interpolation|快照同步|服务端模拟，客户端（基本）不模拟；服务端固定时间同步完整的结果给每个客户端|

注1：帧同步的时候，服务端也可以运行模拟用于防作弊。  
注2：状态同步的时候，客户端运行模拟，可以做预测先行。  

---

# 同步方式的分类

## Deterministic LockStep

Deterministic LockStep，对应到国内，勉强对得上的是帧同步。Deterministic lockstep 最重要的是 Deterministic，它的要求是：给定相同的初始状态，加上一系列相同的输入，可以计算得出相同的结果，不是差不多相同，而是完全相同。   

要求很严格，缺点也很明显，即网络卡的玩家会拖累其他玩家。而国内谈论的帧同步，可以说是应用了各种优化手段之后的 lockstep。下面就直接用帧同步来代替了。帧同步按照韦易笑（ 知乎大佬： https://www.zhihu.com/people/skywind3000 ，博客： https://www.skywind.me/blog/ ）的说法，应该叫帧间同步才对，它是一系列算法的集合，其共同特征是 “确保每帧（逻辑帧）输入一致”[5]。     

韦易笑列举了几种实现：“传统实现有帧锁定，乐观帧锁定，lockstep，bucket 同步等等”[5]。其中乐观帧锁定与 bucket 同步是类似的，都是：1、每个turn（帧）固定时长；2、超时不等待。原始 lockstep 即 deterministic lockstep，要求每个 turn 都要等待收到所有的输入才能推进到下一个 turn，而乐观帧锁定或者说 bucket 同步则是规定了每个 turn 有固定时长，超过这个时长的没接收到输入的就默认无输入，自动进入下一个 turn。但是帧锁定跟 lockstep 有何区别呢？一开始我以为是同一回事，但仔细看了韦易笑的这篇文章[2]，才大致明白其中的小区别是：帧锁定是每 N 帧有一个 “关键帧”，锁的是关键帧，而 lockstep 是每帧都锁。   

有一种说法是：帧同步就是服务器只转发玩家的操作。这个说法只说到了帧同步的表象，帧同步的核心是 “确保每帧（逻辑帧）输入一致”[1]，它的核心是一种确定性，是要求每个玩家画面上呈现的东西是一模一样的，这就是确定性。当然，由于网络延迟、计算机性能等导致的播放时间有先后是不可避免的，但能够保证的是播放的内容一样的，在视觉上是一致的。   

要使得各个客户端每帧计算出来的结果都相同，就需要注意可能导致不确定计算的东西：浮点数，随机数，执行顺序，排序的稳定性，物理引擎。    

---

## Snapshot Interpolation 

Snapshot Interpolation 相当于国内的快照同步，服务端定期的产生整个世界的瞬时快照（就是整个世界所有物体的状态集合），发送给所有客户端，而客户端相当于一个播放器，通过插值的方式来使得视觉变得平滑。快照同步在早期出现的时候用的多，但太占带宽了，现在挺少游戏会使用这种方式了。快照同步带宽的优化问题，Glenn Fiedler 专门写了一篇文章[6]来论述各种方法。    

目前会用到快照同步的主要就是云游戏，以及一些小游戏，比如这篇文章[7]介绍了一款实时竞技小游戏《保卫豆豆-欢乐枪战》的技术实现，一开始这个游戏采用的是状态同步，但由于是小游戏，受限于这几个原因：“运算性能较差，客户端计算量不能太大；Javascript 代码很容易被破解，玩家想要作弊的话很容易；网络连接只能使用 TCP，所以带宽占用不能太高”，最终采用了 “优化了带宽占用的快照插值”。对此我有些怀疑，除了 “运算性能较差” 这个原因，另外两个原因感觉都不太成立。anyway，经过带宽优化的快照同步，在游戏领域都还是有人使用的。       

---

## State Synchronization

State Synchronization 相当于国内的状态同步。状态同步可以说是快照同步的演进，服务器会运行游戏世界，但它同时也允许客户端运行，以服务器的状态为权威，服务器（定时）向客户端发送定制化的、差异化的状态变化，这点与快照同步很不同，快照同步下发给各个客户端的世界状态可以说是一模一样的。    

---

## 状态帧？

这种叫法我是在 烟雨迷离半世殇 ( 知乎大佬： https://www.zhihu.com/people/gu-gao-de-wang-1 ，博客： https://www.lfzxb.top/ ) 的文章[8]里看到的。在对网络同步有足够多的研究之前，看到 “状态帧” 这种叫法是有点懵的。在了解了足够多之后，我才搞清楚 “状态帧” 其实就是守望先锋里面用到的状态同步。    
  
实际上守望先锋的开发人员在技术分享[9]里面也说了，他们用的就是状态同步而已，只不过综合运用了一系列的优化手段[10]，包括：可靠udp(reliable udp)、客户端预测回滚(Client-side prediction and Rollback)、延迟补偿(Lag Compensation)、导航预测(Dead Reckoning)。     

所以，我觉得 “状态帧” 这一说法会增加困惑，不将它加入分类中。  

---

# 参考

[1] Glenn Fiedler. Deterministic Lockstep. Available at https://gafferongames.com/post/deterministic_lockstep/, 2014-11.    

[2] Glenn Fiedler. Snapshot Interpolation. Available at https://gafferongames.com/post/snapshot_interpolation/, 2014-11.  

[3] Glenn Fiedler. State Synchronization. Available at https://gafferongames.com/post/state_synchronization/, 2015-1.   

[4] Philip Orwig. Replay Technology in 'Overwatch': Kill Cam, Gameplay, and Highlights. Available at https://gdcvault.com/play/1024053/Replay-Technology-in-Overwatch-Kill, 2017.   

[5] 韦易笑. 关于 “帧同步”说法的历史由来. Available at https://zhuanlan.zhihu.com/p/165293116, 2020-08.   

[6] Glenn Fiedler. Snapshot Compression. Available at https://gafferongames.com/post/snapshot_compression/, 2015-1.    

[7] 李清. Cocos 技术派｜实时竞技小游戏技术实现分享. Available at https://indienova.com/indie-game-development/real-time-mini-game-explained/, 2019-9.   

[8] 烟雨迷离半世殇. 基于行为树的MOBA技能系统：基于状态帧的战斗，技能编辑器与录像回放系统设计. Available at https://www.lfzxb.top/nkgmoba-framestepstate-architecture-battle-design/, 2021-11.   

[9] kevinan. 《守望先锋》回放技术-阵亡镜头、全场最佳和亮眼表现. Available at https://www.sohu.com/a/162289484_483399, 2017-8.   

[10] kevinan. 暴雪Tim Ford：《守望先锋》架构设计与网络同步. Available at https://www.sohu.com/a/148848770_466876, 2017-6.        
