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

## 帧同步的实现及优化手段

帧同步的确定性，要求各种平台之上的客户端计算都是确定的，这些都可能导致不确定计算：浮点数，随机数，执行顺序，调用时序，排序的稳定性，物理引擎。 
浮点数可以使用定点数替代。  
随机数可以统一随机数种子。  
执行顺序，要保持一致，需要所有的逻辑要有一个统一的入口，每次 tick update 进入一个统一的入口，依次调用各个模块的逻辑。   
排序的稳定性，可以指定统一的稳定排序算法。  
物理引擎，要求确定性的模拟，需要选用保证确定性的物理引擎。  

帧同步的挑战很大，由于误差累积会变大，基本上只要有一次计算不一致，那后续结果就都不一致了，游戏也就玩不下去了，王者荣耀的这个分享[11]就讲了很多这一方面的努力。   

可以使用的优化手段包括以下这些：     

#### 乐观帧

现在事实意义上的帧同步算法都是用的乐观帧了，即每帧固定时长，超时不等待。  

但这里有个细节问题，客户端发送给服务端的 input 数据包都是带有客户端帧号的，那么服务端是否要抛弃客户端过时的 input 数据包，即客户端帧号小于当前服务端帧号的数据包？   

比如这个 demo 项目（[https://github.com/JiepengTan/Lockstep-Tutorial](https://github.com/JiepengTan/Lockstep-Tutorial)）就是会抛弃客户端 input 数据包的。 [https://github.com/JiepengTan/Lockstep-Tutorial/blob/master/Server/Src/SimpleServer/Src/Server/Game.cs](https://github.com/JiepengTan/Lockstep-Tutorial/blob/master/Server/Src/SimpleServer/Src/Server/Game.cs):    

```cs
void C2G_PlayerInput(Player player, BaseMsg data){
    ...
    if (input.Tick < Tick) {
        return;
    }
    ...
}
```

这样抛弃是否会带来问题？似乎是有问题的，即一个延迟高的客户端，它的 input 永远不会被服务端应用。我认为这样是不妥的，那么如何实现才是好的呢？   

参考另一个 demo ( [https://github.com/Enanyy/Frame](https://github.com/Enanyy/Frame) )，这个实现不会抛弃客户端过时的 input 数据包，代码在此（ [https://github.com/Enanyy/Frame/blob/master/FrameServer/FrameServer/Program.cs](https://github.com/Enanyy/Frame/blob/master/FrameServer/FrameServer/Program.cs) ）：

```cs
private void OnOptimisticFrame(Session client, GM_Frame recvData)
{

    int roleId = recvData.roleId;

    long frame = recvData.frame;

    Debug.Log(string.Format("Receive roleid={0} serverframe:{1} clientframe:{2} command:{3}", roleId, mCurrentFrame, frame,recvData.command.Count),ConsoleColor.DarkYellow);
    
    if (mFrameDic.ContainsKey(mCurrentFrame) == false)
    {
        mFrameDic[mCurrentFrame] = new Dictionary<int, List<Command>>();
    }
    for (int i = 0; i < recvData.command.Count; ++i)
    {
        //乐观模式以服务器收到的时间为准
        Command frameData = new Command(recvData.command[i].frame, recvData.command[i].type, recvData.command[i].data, mFrameTime);
        if (mFrameDic[mCurrentFrame].ContainsKey(roleId) == false)
        {
            mFrameDic[mCurrentFrame].Add(roleId, new List<Command>());
        }
        mFrameDic[mCurrentFrame][roleId].Add(frameData);
    }
}
```


#### buffering

针对延迟以及网络抖动，可以通过增加缓冲区的方式来对抗：
输入 -> 缓冲区 -> 渲染   
缓冲区的问题在于会增加延迟。  


#### 预测回滚

不止是状态同步，帧同步也是可以 “预测回滚” 的，但叫法是 timewarp。大体做法都是记录快照，然后出现冲突的时候回滚到快照点。韦易笑的这篇文章《帧同步游戏中使用 Run-Ahead 隐藏输入延迟》[14]介绍过这种做法。   

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

### 王者荣耀使用帧同步明智吗？

这个很难评，成王败寇，它成功了，它就是明智的。但是帧同步带来的心智负担还是很重的，他们的分享里面也提到他们花了很大的功夫去解决不一致问题。   

个人更喜欢守望先锋的做法，虽然可能开发量更大，但至少没有埋下不一致这种大深坑。  

### 服务端预测

在 FPS 游戏中，会采用服务端预测的技术，服务端在没有收到输入的情况下，依据客户端当前的状态作出预测。那么问题来了，与客户端预测相比，它有何不同？  

客户端预测是当状态冲突时，以服务端为权威。那服务端预测，也是一样的原则，要以服务端为权威，所以即使服务端预测的是错的，客户端也要以服务端为权威，修正客户端的状态。  

比如 《无畏契约》的这个分享里介绍的 [19]：  
>What do we do when the server and client get out of sync?
>
>When one client disagrees, our top priority is to minimize the impact to the other nine players. The server commits its prediction as truth, and that client is told to adjust their simulation state back to match the server. This usually means instantly adjusting the positions or state of mispredicted characters back to where they should be. These corrections are rare, small in magnitude, and only seen by the player who encountered the underlying network issues & misprediction. The other nine players continue to see smooth movement.  

<br/>

这种做法结果就是牺牲网络卡的那个玩家，让其他网络正常玩家的体验保持丝滑，而网络卡的玩家体验到拉扯感。不过上文也说了，这种情况并不多见。  


### fps 中 Peeker’s advantage

资料主要参考自天美工作室的分享[20]，以及拳头游戏的这个文章[19]。  

玩家在转角处来回晃悠可以获得先手优势，这种优势是由于网络延迟造成的。静止不动的玩家，它在世界上的位置是相对不变的，而移动的玩家要被静止的玩家看到，至少要经历 RTT + 服务器缓存延迟 + 客户端缓存延迟，所以留给静止玩家的反应时间就要少得多。下面这张图很好的说明了问题。  

![valorant peeker's advantage](https://blog.antsmallant.top/media/blog/2023-06-27-game-networking/valorant-peeker-advantage.png)  
<center>图4：valorant peeker's advantage[19]</center>



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