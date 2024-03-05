---
layout: post
title: "游戏中的网络同步技术"
date: 2023-06-27
last_modified_at: 2023-06-27
categories: [game networking]
---

网游中的网络同步技术已经被研究很长时间了，有不少文章都在探讨这项技术，在拜读了一系列文章之后，打算自己做一次归纳总结。  

这项技术发展到至今，大体上可以归纳为三种做法，分别是 Deterministic LockStep, Snapshot Interpolation, State Synchronization。这个划分参考自 Glenn Fielder[1][2][3]。其实国内的韦易笑、Jerish 在各自文章中的所做的划分也是大同小异，韦易笑老师在他的文章中把网络同步归类为两大种:帧间同步、状态同步。gdc2017 overwatch 的这个分享 Replay-Technology-in-Overwatch-Kill  也引用了 Glenn Fiedler，把主流的网络同步模型分为了以上三类，这个视频的文字翻译版在此[7]。

![gdc2017-overwatch-network-synchronization-models](https://blog.antsmallant.top/media/blog/2023-06-27-game-networking/gdc2017-overwatch-network-synchronization-models.png)  
<center>图1：overwatch 分享中对于网络同步模型的划分</center>


## LockStep 
大致相当于国内的帧同步。下面就直接用帧同步来代替了。帧同步按照韦易笑老师的说法，应该得叫帧间同步才对，它是一系列算法的集合，其共同特征是 “确保每帧（逻辑帧）输入一致”[4]。     

韦易笑老师列举了几种实现：“传统实现有帧锁定，乐观帧锁定，lockstep，bucket 同步等等”[4]。其中乐观帧锁定与 bucket 同步是类似的，就是一种超时不等待的策略，原始 lockstep 即 deterministic lockstep 是要求每个 turn 都要等待收到所有的输入才能推进到下一个 turn，而乐观帧锁定或者说 bucket 同步则是规定了每个 turn 有固定时长，超过这个时长的没接收到输入的就默认无输入，自动进入下一个 turn。但是帧锁定跟 lockstep 有何区别呢？一开始我以为是同一回事，但仔细看了韦老师的这篇文章[2]，才大致明白其中的小区别是：帧锁定是每 N 帧有一个 “关键帧”，锁的是关键帧，而 lockstep 是每帧都锁。   

有一种说法是：帧同步就是服务器只转发玩家的操作。这个说法只说到了帧同步的表象，帧同步的核心是 “确保每帧（逻辑帧）输入一致”[1]，它的核心是一种确定性，是要求每个玩家画面上呈现的东西是一模一样的，这就是确定性。当然，由于网络延迟、计算机性能等导致的播放时间有先后是不可避免的，但能够保证的是播放的内容一样的，在视觉上是一致的。  

帧同步的确定性是建立在这样的假设之上的，给定一个相同的初始状态，加上一系列相同的输入，最终可以获得一个相同的终止状态。那么使得各个客户端每帧计算出来的状态都相同，我们就不能使用那些会带来误差的东西，包括浮点数，随机数。浮点数在不同的平台上可能会有不同的计算结果，尽管差距很细微，但累积之后就会变成很大很大的误差，可以使用定点数来替代。随机数如果种子不同，那之后结果都将不同，所以要使用相同的随机数种子。物理引擎也必须是确定的，一般就使用采用定点数的引擎。  

帧同步与状态同步的区别，我觉得可以打这么一个粗略的比方：帧同步相当于所有的客户端播放同样一部电影，视觉上是完全一样的，而状态同步是所有客户端拿着相同的剧本（状态一样），但是电影画面略有差异。  

这就决定了帧同步与状态同步的适用范围不同，对于面画有精确


## Snapshot Interpolation
这在国内称为快照同步，相当于服务端定期给所有客户端发送整个世界的快照，即整个世界的状态，而客户端相当于一个播放器，通过插值的方式来使得视觉变得平滑。这实际上跟下面说的 state synchronization 是同一类做法。   

快照同步在早期出现的时候用的多，到后面就很少使用了，太占带宽了，基本上改成使用状态同步了。快照同步带宽的优化问题，Glenn Fiedler 专门写了一篇文章[6]来论述各种方法。

## State Synchronization
这在国内称为状态同步，

## 状态帧？
这个说法我在此博主的文章里 （ [基于行为树的MOBA技能系统：基于状态帧的战斗，技能编辑器与录像回放系统设计](https://www.lfzxb.top/nkgmoba-framestepstate-architecture-battle-design/) ）看到的，在我对网络同步有足够多的研究之前，看到 “状态帧” 这种叫法是有点懵的。在了解了更多之后，我才搞清楚，此原来所谓 “状态帧” 其实就是守望先锋里面用到的同步技术。但实际上守望先锋自己的技术分享里面也说了，他们用的就是状态同步而已，只不过采用了多种优化手段，包括：。所以，此博主 “状态帧” 的说法，在我看来，只是增加了理解负担而已。当然，每个人都有表达和创作的自由。  


## Dead Reckoning
一般缩写作 DR，DR 实际上就是一种外插值应用。


## 推荐阅读
韦易笑老师高屋建瓴，对网络同步有深入研究，非常有洞察力，他N年前的文章在现在看都完全不过时：  
* [韦易笑 关于 “帧同步” 说法的历史由来](https://zhuanlan.zhihu.com/p/165293116)
* [韦易笑 再谈网游同步技术](https://www.skywind.me/blog/archives/1343)
* [韦易笑 服务端十二小时](https://pan.baidu.com/s/1oBvmdQgsUWKrmU8g9o3u5Q)  （提取码:2j9b）   
* [韦易笑 帧锁定同步算法](http://www.skywind.me/blog/archives/131)
* [韦易笑 帧同步游戏中使用 Run-Ahead 隐藏输入延迟](https://www.skywind.me/blog/archives/2746)
* [韦易笑 影子跟随算法（2007年老文一篇）](https://www.skywind.me/blog/archives/1145)
* [韦易笑 网络游戏同步法则](http://www.skywind.me/blog/archives/112)
* [韦易笑 体育竞技游戏的团队AI](http://www.skywind.me/blog/archives/1216)


Jerish 关于网络同步的发展史，考察得很深入，很不错：   
* [Jerish 细谈网络同步在游戏历史中的发展变化（上）](https://zhuanlan.zhihu.com/p/130702310)
* [Jerish 细谈网络同步在游戏历史中的发展变化（中）](https://zhuanlan.zhihu.com/p/164686867)
* [Jerish 细谈网络同步在游戏历史中的发展变化（下）](https://zhuanlan.zhihu.com/p/336869551)


Gabriel Gambetta 这几篇文章关于状态同步的文章写得很好，甚至还在文章里内嵌里一个 js 写的 demo：  
* [Fast-Paced Multiplayer (Part I): Client-Server Game Architecture](https://www.gabrielgambetta.com/client-server-game-architecture.html)
* [Fast-Paced Multiplayer (Part II): Client-Side Prediction and Server Reconciliation](https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html)
* [Fast-Paced Multiplayer (Part III): Entity Interpolation](https://www.gabrielgambetta.com/entity-interpolation.html)
* [Fast-Paced Multiplayer (Part IV): Lag Compensation](https://www.gabrielgambetta.com/lag-compensation.html)
* [Fast-Paced Multiplayer: Sample Code and Live Demo](https://www.gabrielgambetta.com/client-side-prediction-live-demo.html)



## 参考
[1] Glenn Fiedler. Deterministic Lockstep ( https://gafferongames.com/post/deterministic_lockstep/ ). 2014.11.   
[2] Glenn Fiedler. Snapshot Interpolation ( https://gafferongames.com/post/snapshot_interpolation/ ). 2014.11.   
[3] Glenn Fiedler. State Synchronization ( https://gafferongames.com/post/state_synchronization/ ). 2015.1.    
[4] 韦易笑. 关于 “帧同步”说法的历史由来 ( https://zhuanlan.zhihu.com/p/165293116 ). 2020.08.     
[5] 韦易笑. 帧锁定同步算法 ( https://www.skywind.me/blog/archives/131 ). 2007.2.     
[6] Glenn Fiedler. Snapshot Compression ( https://gafferongames.com/post/snapshot_compression/ ). 2015.1    
[7] Philip Orwig. Replay Technology in 'Overwatch': Kill Cam, Gameplay, and Highlights ( https://gdcvault.com/play/1024053/Replay-Technology-in-Overwatch-Kill ). 2017    
[8] kevinan.《守望先锋》回放技术-阵亡镜头、全场最佳和亮眼表现 ( https://www.sohu.com/a/162289484_483399 ). 2017.8.    
