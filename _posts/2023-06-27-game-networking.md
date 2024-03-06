---
layout: post
title: "游戏中的网络同步技术"
date: 2023-06-27
last_modified_at: 2023-06-27
categories: [game networking]
---

网游中的网络同步技术已经被研究很长时间了，有不少文章都在探讨这项技术，在拜读了一系列文章之后，打算自己做一次归纳总结。  

这项技术发展至今，大体上可以归类为三种做法，分别是 Deterministic LockStep, Snapshot Interpolation, State Synchronization。这个划分参考自 Glenn Fielder[1][2][3]。其实国内的韦易笑、Jerish 在各自文章中的所做的划分也是大同小异，韦易笑老师在他的文章中把网络同步归类为两大种:帧间同步、状态同步。gdc2017 overwatch 的这个分享 Replay-Technology-in-Overwatch-Kill  也引用了 Glenn Fiedler，把主流的网络同步模型分为了以上三类，这个视频的文字翻译版在此[7]。

![gdc2017-overwatch-network-synchronization-models](https://blog.antsmallant.top/media/blog/2023-06-27-game-networking/gdc2017-overwatch-network-synchronization-models.png)  
<center>图1：overwatch 分享中对于网络同步模型的划分</center>


## Deterministic LockStep
Deterministic LockStep 是最原始的 lockstep，要求很严格，缺点也很明显，即网络卡的玩家会拖累其他玩家。而国内谈论的帧同步，可以说是应该了各种优化手段之后的 lockstep。下面就直接用帧同步来代替了。帧同步按照韦易笑（ 知乎大佬： https://www.zhihu.com/people/skywind3000 ，博客： https://www.skywind.me/blog/ ）的说法，应该叫帧间同步才对，它是一系列算法的集合，其共同特征是 “确保每帧（逻辑帧）输入一致”[4]。     

韦易笑列举了几种实现：“传统实现有帧锁定，乐观帧锁定，lockstep，bucket 同步等等”[4]。其中乐观帧锁定与 bucket 同步是类似的，都是：1、每个turn（帧）的时长固定；2、超时不等待输入。原始 lockstep 即 deterministic lockstep 是要求每个 turn 都要等待收到所有的输入才能推进到下一个 turn，而乐观帧锁定或者说 bucket 同步则是规定了每个 turn 有固定时长，超过这个时长的没接收到输入的就默认无输入，自动进入下一个 turn。但是帧锁定跟 lockstep 有何区别呢？一开始我以为是同一回事，但仔细看了韦易笑的这篇文章[2]，才大致明白其中的小区别是：帧锁定是每 N 帧有一个 “关键帧”，锁的是关键帧，而 lockstep 是每帧都锁。   

有一种说法是：帧同步就是服务器只转发玩家的操作。这个说法只说到了帧同步的表象，帧同步的核心是 “确保每帧（逻辑帧）输入一致”[1]，它的核心是一种确定性，是要求每个玩家画面上呈现的东西是一模一样的，这就是确定性。当然，由于网络延迟、计算机性能等导致的播放时间有先后是不可避免的，但能够保证的是播放的内容一样的，在视觉上是一致的。  

帧同步的确定性是建立在这样的假设之上的，给定一个相同的初始状态，加上一系列相同的输入，最终可以获得一个相同的终止状态。那么使得各个客户端每帧计算出来的状态都相同，我们就不能使用那些会带来误差的东西，包括浮点数，随机数。浮点数在不同的平台上可能会有不同的计算结果，尽管差距很细微，但累积之后就会变成很大很大的误差，可以使用定点数来替代。随机数如果种子不同，那之后结果都将不同，所以要使用相同的随机数种子。物理引擎也必须是确定的，一般就使用采用定点数的引擎。  


## Snapshot Interpolation 
Snapshot Interpolation 相当于国内的快照同步，服务端定期的产生整个世界的瞬时快照（就是整个世界所有物体的状态集合），发送给所有客户端，而客户端相当于一个播放器，通过插值的方式来使得视觉变得平滑。快照同步在早期出现的时候用的多，但太占带宽了，现在挺少游戏会使用这种方式了。快照同步带宽的优化问题，Glenn Fiedler 专门写了一篇文章[6]来论述各种方法。  

目前会用到快照同步的主要就是云游戏，以及一些小游戏，比如这篇文章[9]介绍了一款实时竞技小游戏《保卫豆豆-欢乐枪战》的技术实现，一开始这个游戏采用的是状态同步，但由于是小游戏，受限于这几个原因：“运算性能较差，客户端计算量不能太大；Javascript 代码很容易被破解，玩家想要作弊的话很容易；网络连接只能使用 TCP，所以带宽占用不能太高”，最终采用了 “优化了带宽占用的快照插值”。对此我有些怀疑，除了 “运算性能较差” 这个原因，另外两个原因感觉都不太成立。anyway，经过带宽优化的快照同步，在游戏领域都还是有人使用的。     


## State Synchronization
State Synchronization 相当于国内的状态同步。状态同步可以说是快照同步的演进，服务器会运行游戏世界，但它同时也允许客户端运行，以服务器的状态为权威，服务器（定时）向客户端发送定制化的、差异化的状态变化，这点与快照同步很不同，快照同步下发给各个客户端的世界状态可以说是一模一样的。  


## 状态帧？
这种叫法我是在 烟雨迷离半世殇 ( 知乎大佬： https://www.zhihu.com/people/gu-gao-de-wang-1 ，博客： https://www.lfzxb.top/ ) 的文章[10]里看到的。在对网络同步有足够多的研究之前，看到 “状态帧” 这种叫法是有点懵的。在了解了足够多之后，我才搞清楚 “状态帧” 其实就是守望先锋里面用到的状态同步。  

实际上守望先锋的开发人员在技术分享[8]里面也说了，他们用的就是状态同步而已，只不过综合运用了一系列的优化手段[13]，包括：可靠udp(reliable udp)、客户端预测回滚(Client-side prediction and Rollback)、延迟补偿(Lag Compensation)、导航预测(Dead Reckoning)。   

所以，“状态帧” 的说法，在我看来，只是增加了理解负担而已。当然，每个人都有表达和创作的自由，respect。  


## 适用范围
帧同步与状态同步的区别，我觉得可以打这么一个粗略的比方：帧同步是所有客户端播放同一部电影，视觉上完全一样；状态同步是所有客户端拿着相同的剧本（状态一样），但是电影画面略有差异。而快照同步，由于所有的仿真都发生在服务器，所以各个客户端视觉上是一致的，也是在播放同一部电影。  

弱客户端，像小游戏，云游戏，都可以使用快照同步。  

对于面画有精确要求的，比如格斗类游戏，玩家的出招强依赖于对手的出招动作，所以保持双方视觉上的一致很有必要，此时就适用帧同步，此外，体育类、rts 等需要精细操作的也都得用帧同步。  

其他类型的，基本上都可以使用状态同步。  

王者荣耀使用的是帧同步，这个分享里[11]说明了理由：   
>第一，它的开发效率比较高。如果你开发思路的整体框架是验证可行的，如果你把它的缺点解决了，那么你的开发思路完全就跟写单机一样，你只需要遵从这样的思路，尽量保证性能，程序该怎么写就怎么写。比如我们以前要在状态同步下面做一个复杂的技能，有很多段位的技能，可能要开发好几天，才能有一个稍微过得去的结果，而在帧同步下面，英雄做多段位技能很可能半天就搞定了。   
第二，它能实现更强的打击感，打击感强除了我们说的各种反馈、特效、音效外，还有它的准确性。利用帧同步，游戏里面看到这些挥舞的动作，就能做到在比较准确的时刻产生反馈，以及动作本身的密度也可以做到很高的频率，这在状态同步下是比较难做的。   
第三，它的流量消耗是稳定的。    

moba 类型游戏其实是可以使用状态同步的，王者荣耀采用帧同步算是一种个性化的选择，也付出了很多努力来克服帧同步的弱点。      

守望先锋使用的是状态同步，在这个分享里[8]说明了理由:   
>Overwatch最终没有选择确定性帧同步方案，原因如下：首先，我们不希望程序员和策划的因为偶现的不确定性而产生心理负担；除此之外，要支持中途加入游戏也不简单。模拟操作本身就已经很耗了，如果5分钟的游戏过程，每次都需要重头开始模拟的话，计算量太大。   
最后，实现一个阵亡镜头也会很困难，因为需要客户端快照以及快播机制。按理说如果游戏支持录像文件的话，快播自然就能做到，不过Overwatch并没有这一点。


## 帧同步的优化手段


## 快照同步的优化手段


## 状态同步的优化手段


## 何为 Dead Reckning
缩写为 DR，中文叫导航预测算法，这篇文章[12]对 DR 下了一个定义：  
>Using a predetermined set of algorithms to extrapolate entity behavior, you can hide some of the effects that latency has on fast-action games.   

翻译过来就是使用一系列算法去 extrapolate，是在特定场景下进行 extrapolate，是对 extrapolate 的一种特定应用。extrapolate 就是外插值，在这里的意义是根据已经的离散的点，去推测出未来的点，即根据当前的状态推算出未来的路径。   

与外插值相对的是内插值(interpolation), 内插在游戏中的应用就是根据已经的离散的点，在此范围内拟合出一条曲线，即移动路径。    



## 推荐阅读
韦易笑对网络同步有深入研究，非常有洞察力，他 N 年前的文章放到现在都完全不过时：  
* [关于 “帧同步” 说法的历史由来](https://zhuanlan.zhihu.com/p/165293116)
* [再谈网游同步技术](https://www.skywind.me/blog/archives/1343)
* [服务端十二小时](https://pan.baidu.com/s/1oBvmdQgsUWKrmU8g9o3u5Q)  （提取码:2j9b）   
* [帧锁定同步算法](http://www.skywind.me/blog/archives/131)
* [帧同步游戏中使用 Run-Ahead 隐藏输入延迟](https://www.skywind.me/blog/archives/2746)
* [影子跟随算法（2007年老文一篇）](https://www.skywind.me/blog/archives/1145)
* [网络游戏同步法则](http://www.skywind.me/blog/archives/112)
* [体育竞技游戏的团队AI](http://www.skywind.me/blog/archives/1216)


Jerish 关于网络同步的发展史，考察得很深入，很不错：   
* [细谈网络同步在游戏历史中的发展变化（上）](https://zhuanlan.zhihu.com/p/130702310)
* [细谈网络同步在游戏历史中的发展变化（中）](https://zhuanlan.zhihu.com/p/164686867)
* [细谈网络同步在游戏历史中的发展变化（下）](https://zhuanlan.zhihu.com/p/336869551)


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
[6] Glenn Fiedler. Snapshot Compression ( https://gafferongames.com/post/snapshot_compression/ ). 2015.1.       
[7] Philip Orwig. Replay Technology in 'Overwatch': Kill Cam, Gameplay, and Highlights ( https://gdcvault.com/play/1024053/Replay-Technology-in-Overwatch-Kill ). 2017.       
[8] kevinan.《守望先锋》回放技术-阵亡镜头、全场最佳和亮眼表现 ( https://www.sohu.com/a/162289484_483399 ). 2017.8.      
[9] 李清. Cocos 技术派｜实时竞技小游戏技术实现分享 ( https://indienova.com/indie-game-development/real-time-mini-game-explained/ ). 2019.9.   
[10] 烟雨迷离半世殇. 基于行为树的MOBA技能系统：基于状态帧的战斗，技能编辑器与录像回放系统设计 ( https://www.lfzxb.top/nkgmoba-framestepstate-architecture-battle-design/ ). 2021.11   
[11] 邓君. 王者技术修炼之路 ( https://youxiputao.com/articles/11842 ). 2017.5.  
[12] Jesse Aronson. Dead Reckoning: Latency Hiding for Networked Games ( https://www.gamedeveloper.com/programming/dead-reckoning-latency-hiding-for-networked-games#close-modal ). 1997.9    
[13] kevinan. 暴雪Tim Ford：《守望先锋》架构设计与网络同步 ( https://www.sohu.com/a/148848770_466876 ). 2017.6