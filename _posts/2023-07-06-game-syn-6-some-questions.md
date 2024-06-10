---
layout: post
title: "网络游戏同步技术六：若干问题探讨"
date: 2023-07-06
last_modified_at: 2023-07-06
categories: [网络游戏同步技术]
---

* 目录  
{:toc}
<br/>

本文探讨网络同步的几个问题。   

---

# 1. 王者荣耀使用帧同步明智吗？

这个很难评，成王败寇，它成功了，它就是明智的。但是帧同步带来的心智负担还是很重的，他们的分享里面也提到他们花了很大的功夫去解决不一致问题。   

个人更喜欢守望先锋的做法，虽然可能开发量更大，但至少没有埋下不一致这种大深坑。  

---

# 2. 服务端预测

在 FPS 游戏中，会采用服务端预测的技术，服务端在没有收到输入的情况下，依据客户端当前的状态作出预测。那么问题来了，与客户端预测相比，它有何不同？  

客户端预测是当状态冲突时，以服务端为权威。那服务端预测，也是一样的原则，要以服务端为权威，所以即使服务端预测的是错的，客户端也要以服务端为权威，修正客户端的状态。  

比如 《无畏契约》的这个分享里介绍的 [1]：  

>What do we do when the server and client get out of sync?
>
>When one client disagrees, our top priority is to minimize the impact to the other nine players. The server commits its prediction as truth, and that client is told to adjust their simulation state back to match the server. This usually means instantly adjusting the positions or state of mispredicted characters back to where they should be. These corrections are rare, small in magnitude, and only seen by the player who encountered the underlying network issues & misprediction. The other nine players continue to see smooth movement.  

<br/>

这种做法结果就是牺牲网络卡的那个玩家，让其他网络正常玩家的体验保持丝滑，而网络卡的玩家体验到拉扯感。不过上文也说了，这种情况并不多见。  

---

# 3. fps 中 Peeker’s advantage

资料主要参考自天美工作室的分享[2]，以及拳头游戏的这个文章[1]。  

玩家在转角处来回晃悠可以获得先手优势，这种优势是由于网络延迟造成的。静止不动的玩家，它在世界上的位置是相对不变的，而移动的玩家要被静止的玩家看到，至少要经历 RTT + 服务器缓存延迟 + 客户端缓存延迟，所以留给静止玩家的反应时间就要少得多。下面这张图很好的说明了问题。  

![valorant peeker's advantage](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/game-networking-valorant-peeker-advantage.png)  
<center>图1：valorant peeker's advantage[1]</center>

---

# 4. 参考

[1] RiotGames. PEEKING INTO VALORANT'S NETCODE. Available at https://technology.riotgames.com/news/peeking-valorants-netcode, 2020-7-28.        

[2] 腾讯天美工作室群. FPS游戏中，在玩家的延时都不一样的情况下是如何做到游戏的同步性的. Available at https://www.zhihu.com/question/29076648/answer/1946885829, 2021-6-18.    
