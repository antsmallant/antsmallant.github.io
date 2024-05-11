---
layout: post
title: "游戏开发之网络同步技术"
date: 2023-10-11
last_modified_at: 2023-10-11
categories: [游戏开发]
---

* 目录  
{:toc}
<br/>

---

## 快照同步的实现及优化手段

快照同步的优化措施，也就是 buffering 了，通过增加缓冲区来对抗网络延迟及抖动。另外，就是根据业务的特点，压缩快照的数据量，减少带宽压力，Glenn Fielder 的这篇文章《Snapshot Compression》[6]提供了一次很好的展示。   

这篇文章《Cocos 技术派｜实时竞技小游戏技术实现分享》[9]还讲到使用 DR 来对快照同步做优化，很奇怪，既然都已经选择快照同步了，为何还使用 DR？不应该是 buffering + 逻辑与显示分离+内插值吗？  

---

## 通用的优化手段

### udp 代替 tcp

用 udp 替代 tcp，是一种很有效的优化。可以使用可靠 udp (reliable udp) 比如 kcp，也可以使用带冗余信息的不可靠 udp。也可以把二者结合起来，比如这样的一个方案：kcp+fec。  


### 逻辑和显示的分离

这个主要是为了做插值使得视觉平滑，减少抖动感。客户端在实现上区分了“逻辑帧”与“显示帧”，比如玩家的位置会有个逻辑上的位置 position，会有个显示上的位置 view_position，显示帧 tick 的时候，通过插值算法，将 view_position 插值到 position，比如这样：  

```cs
player.view_pos = Vector3.Lerp(player.view_pos, player.pos, 0.5f);
player.view_rot = Quaternion.Slerp(player.view_rot, player.rot, 0.5f);
```

---

## 常见游戏的网络同步方案

### MMO 游戏的网络同步

一般的 MMO 对于网络同步的要求不高，最重要的是做好 AOI，因为场景里面需要同步的单位可能会特别多。  

### SLG 游戏的网络同步

SLG 这类游戏，对于网络同步的要求可以说是很低的，基本的 rpc 调用就够了，不需要复杂的网络同步。  

### MOBA 游戏的网络同步

MOBA 对于动作的同步的要求比较高，对于延迟也是相对敏感一些的。像王者荣耀使用的是帧同步，可以实现很精细的打击效果，更多的是使用带各种优化的状态同步，比如客户端先行，预测回滚、延迟补偿等。  

也有实现上很粗糙的，比如这款游戏 ( [https://github.com/tsymiar/TheLastBattle](https://github.com/tsymiar/TheLastBattle) )，它的客户端先行只是先简单的改变移动朝向，并不会真正的先移动。  

### FPS 游戏的网络同步

可以用帧同步，但没必要，用守望先锋的那种带各种优化的状态同步就可以达到很好的效果了。  

---

## 一些问题的探讨

### 客户端先行如何处理服务端同步过来的 “过时状态”

前面已经提到了，通过记录历史帧状态来做预测回滚，但是好多 MMO 在设计之初就没有使用这一套机制来做。所以现在就有一个问题，在一个老项目中，如何做到客户端先行。  

在前面也提到了，即使在 Moba 游戏中，也有使用障眼法来对付过去的，并没有真正的客户端先行，而是客户端先旋转方向。  

---

## todo

* mmo 关于同步粒度过于粗糙的问题，同步线段的问题
* mmo 中的预测回滚问题
* mmo 应该采用一个怎么样的相对适中的状态同步策略？
* 补充关于 buffering 的小节
* 处理过时状态的问题

---

## 总结

* 纸上谈兵容易，真做项目很难，会遇到各种各样的细节问题。自己多练手真正写写 demo 才更清楚其中的细节。  

---

## 参考

[1] Glenn Fiedler. Deterministic Lockstep. Available at https://gafferongames.com/post/deterministic_lockstep/, 2014-11.    

[2] Glenn Fiedler. Snapshot Interpolation. Available at https://gafferongames.com/post/snapshot_interpolation/, 2014-11.  

[3] Glenn Fiedler. State Synchronization. Available at https://gafferongames.com/post/state_synchronization/, 2015-1.   

[4] 韦易笑. 关于 “帧同步”说法的历史由来. Available at https://zhuanlan.zhihu.com/p/165293116, 2020-08.   

[5] 韦易笑. 帧锁定同步算法. Available at https://www.skywind.me/blog/archives/131, 2007-2.    

[6] Glenn Fiedler. Snapshot Compression. Available at https://gafferongames.com/post/snapshot_compression/, 2015-1.    

[7] Philip Orwig. Replay Technology in 'Overwatch': Kill Cam, Gameplay, and Highlights. Available at https://gdcvault.com/play/1024053/Replay-Technology-in-Overwatch-Kill, 2017.   

[8] kevinan. 《守望先锋》回放技术-阵亡镜头、全场最佳和亮眼表现. Available at https://www.sohu.com/a/162289484_483399, 2017-8.   

[9] 李清. Cocos 技术派｜实时竞技小游戏技术实现分享. Available at https://indienova.com/indie-game-development/real-time-mini-game-explained/, 2019-9.   

[10] 烟雨迷离半世殇. 基于行为树的MOBA技能系统：基于状态帧的战斗，技能编辑器与录像回放系统设计. Available at https://www.lfzxb.top/nkgmoba-framestepstate-architecture-battle-design/, 2021-11.   

[11] 邓君. 王者技术修炼之路. Available at https://youxiputao.com/articles/11842, 2017-5.   

[12] Jesse Aronson. Dead Reckoning: Latency Hiding for Networked Games. Available at https://www.gamedeveloper.com/programming/dead-reckoning-latency-hiding-for-networked-games#close-modal, 1997-9.        

[13] kevinan. 暴雪Tim Ford：《守望先锋》架构设计与网络同步. Available at https://www.sohu.com/a/148848770_466876, 2017-6.        

[14] 韦易笑. 帧同步游戏中使用 Run-Ahead 隐藏输入延迟. Available at https://www.skywind.me/blog/archives/2746, 2023-10.        

[15] Valve. Source Multiplayer Networking. Available at https://developer.valvesoftware.com/wiki/Source_Multiplayer_Networking.    

[16] Gabriel Gambetta. Fast-Paced Multiplayer (Part II): Client-Side Prediction and Server Reconciliation. Available at https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html.      

[17] 云风. 浅谈《守望先锋》中的 ECS 构架. Available at https://blog.codingnow.com/2017/06/overwatch_ecs.html, 2017-6-26.        

[18] co lin. 深入探索AOI算法. Available at https://zhuanlan.zhihu.com/p/201588990, 2020-8-28.        

[19] RiotGames. PEEKING INTO VALORANT'S NETCODE. Available at https://technology.riotgames.com/news/peeking-valorants-netcode, 2020-7-28.        

[20] 腾讯天美工作室群. FPS游戏中，在玩家的延时都不一样的情况下是如何做到游戏的同步性的. Available at https://www.zhihu.com/question/29076648/answer/1946885829, 2021-6-18.       

[21] David Aldridge. I Shot You First: Networking the Gameplay of Halo: Reach. Available at https://www.youtube.com/watch?v=h47zZrqjgLc, 2011.           

[22] [美]Joshua Glazer, Sanjay Madhav. 网络多人游戏架构与编程. 王晓慧, 张国鑫. 北京: 人民邮电出版社, 2017-10(1): 244-245.           