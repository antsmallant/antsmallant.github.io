---
layout: post
title: "网络游戏同步技术二：状态同步的优化与实现"
date: 2023-07-02
last_modified_at: 2023-07-02
categories: [游戏开发]
---

* 目录  
{:toc}
<br/>

本文讲一讲 “状态同步” 的优化手段。  

---

# 优化手段

## 客户端预测回滚 (client-side predition and rollback)

客户端预测是为了更及时的反馈，如果玩家自己的每一个动作都要等待服务器的回应才执行，那么会严重受到延迟的影响，体验很糟糕，所以一般都会采取客户端预测，即客户端先行，客户端在把 input 发给服务器的同时，自己先执行动作，待等到服务器回包的时候再根据情况，如果状态不一致，则需要回滚（也称为和解），这个过程是这样的，客户端回滚到状态不一致的那一帧，然后再重新应用这一帧之后的所有 inputs，此为最新的预测状态，之后再通过插值平滑的过度到此状态。  

---

## 延迟补偿 (lag compensation)

这个是针对命中判断来说的，比如说 fps 类型的游戏，由于网络延迟以及一些优化手段，导致你在画面上看到的景象实际上是几帧之前发生的事情，这时候你进行射击，此刻出现在你画面中的玩家在服务器处可能已经跑远了，当你的射击指令到达服务器时，是不会被判断命中的，这时候服务器需要把画面回滚（rewind）到你射击时候播放的那一帧，然后再进行判断。用这张经典的图片来展示一下：  

![valve-Lag_compensation](https://blog.antsmallant.top/media/blog/2023-06-27-game-networking/valve-Lag_compensation.jpg)  
<center>图1：延迟补偿[1]</center>

关于延迟补偿，在《网络多人游戏架构与编程》[2]中有具体的实现指导:  

>* 远程玩家使用客户端插值，而不是航位推测。  
>* 使用本地客户端移动预测和移动重放。 
>* 发送给服务器的每个移动数据包中保存客户端视角。客户端应该在每个发送的数据包中记录客户端当前插值的两个帧的ID，以及插值进度百分比。这给服务器提供了客户端当时所感知世界的精确指示。 
>* 在服务器端，存储每个相关对象最近几帧的位置。  

---

## Dead Reckning

缩写为 DR，中文叫导航预测算法，这篇文章[3]对 DR 下了一个定义：  
>Using a predetermined set of algorithms to extrapolate entity behavior, you can hide some of the effects that latency has on fast-action games.   

翻译过来就是使用一系列算法去 extrapolate，是在特定场景下进行 extrapolate，是对 extrapolate 的一种特定应用。extrapolate 就是外插值，在游戏中就是根据已知的离散点，去推测出未来的点，也就是推算出未来的路径。与外插值相对的是内插值(interpolation), 内插在游戏中的应用就是根据已经的离散的点，在此范围内拟合出一条曲线，即移动路径。    

DR 实际上就是对于本玩家之外的其他物体进行预测的一种手段，本玩家直接使用预测回滚的方式进行预测了。  

---

## 区域裁剪

比如通过 AOI 算法，裁剪需要下发给客户端的消息包。  

AOI 是 area of interest 的缩写，它代表的是游戏单位的视野，可以大到整个场景，也可以小到相当于屏幕大小的场景范围，主要目的就是减少需要广播的消息量，游戏单位只需要接收它当前视野范围的其他单位的变化信息。当然，这只是一种尽力而为的优化措施，当同屏有大量单位的时候，这个算法是起不了作用的，此时需要考虑其他的优化手段来减少消息广播量。     

常见的 aoi 算法有九宫格和十字链表，这两个都对应的是 2D 地图，3D 地图的话相对应的就是二十七宫格和三轴十字链表了，但其实原理类似，没有多大不同。     

九宫格的思路大概是这样:   

* 把场景地图分成 n 个小方格，每个小方格大约四分之一屏幕大小，九个格子刚好是比一个屏幕大一些
* 进入场景时，计算所处的格子，将自己加入该格子，给周围9个格子的单位广播 enter 消息
* 离开场景时，将自己从格子删除，给周围9个格子的单位广播 leave 消息
* 属性变化时，给周围9个格子的单位广播 change 消息
* 移动时
    * 如果没跨越，则只给周围9个格子的单位广播 move 消息；
    * 如果跨越了，则需要：1、给旧9格与新9格的差集广播 leave 消息；2、给新9格与旧9格的差集广播 enter 消息；3、给旧9格与新9格的交集广播 move 消息；

![aoi-九宫格](https://blog.antsmallant.top/media/blog/2023-06-27-game-networking/aoi-9-grid.webp)
<center>图2：aoi-九宫格算法[4] </center>

九宫格相当于在场景中创建了一个全局变量来记录每个格子中的单位，这样一来每个单位就不需要自己维护一个观察者列表或被观察者列表了。九宫格实现起来很简单，但是如果想要做到不同单位可变视野，就会很费劲了，需要很多额外的遍历，这时候可以考虑使用十字链表法。  

十字链表法的思路大概是这样：   

* X、Y 轴各维护一个按坐标值大小排列的有序链表；
* 进入场景时，游戏单位根据自己的坐标值，分别遍历X轴、Y轴，找到自己的位置把自己插入进去链表中；
* 每个单位在同一条轴上也插入两个哨兵节点，这两个哨兵节点到自己的距离刚好是视野半径；
* 单位移动的时候，哨兵节点也跟着移动，保持相对距离不变；
* 每个游戏单位维护一个观察者集合，被观察者集合，当有其他单位越过哨兵节点或自己的时候，就根据距离判断是加入观察者集合，还是移出观察者集合；

十字链表法看起来挺巧妙的，利用了两个哨兵节点来感应周围的变化，并且由于两个哨兵间的距离可以随自己的需要进行调整，所以可以很方便的做成可变视野的。  

源码方面，kbengine 的 aoi 实现是三轴十字链表，可以参考一下。   

AOI 算法还可以参考以下两篇文章，写得挺好的：   

* [游戏服务器AOI的实现](https://www.cnblogs.com/coding-my-life/p/14256640.html)
* [深入探索AOI算法](https://zhuanlan.zhihu.com/p/201588990)

---

## 障眼法-隐藏延迟的 trick

通过前摇之类的方式来隐藏网络延迟的做法，我这里统称为障眼法。下面举一些实战的例子

halo 2011 年的这个 GDC 分享，展示一种如何让扔手雷看起来更流畅的做法，这里面的关键是：在合适的地方隐藏网络延迟。  

尝试一，按下按键，等待服务器回应之后再播放扔的动画，这种体验非常差：
![](https://blog.antsmallant.top/media/blog/2023-06-27-game-networking/halo-grenade-throw-attempt-1.png)  
<center>图3：halo-grenade-throw-attempt-1[5]</center>

尝试二，按下按键，播放扔的动画，同时发消息给服务器，客户端播放完动画不等服务器响应直接扔出手雷，这种做法虽然没有延迟，但是违背了服务器权威的原则：
![halo-grenade-throw-attempt-2](https://blog.antsmallant.top/media/blog/2023-06-27-game-networking/halo-grenade-throw-attempt-2.png)  
<center>图4：halo-grenade-throw-attempt-2[5]</center>

尝试三，这也是 halo 的最终实现方案，按下按键立即播放扔的动画，同时发消息给服务器，等收到回包再实际扔出手雷：  
![halo-grenade-throw-attempt-3](https://blog.antsmallant.top/media/blog/2023-06-27-game-networking/halo-grenade-throw-attempt-3.png)  
<center>图5：halo-grenade-throw-attempt-3[5]</center>

---

# 具体实现

预测回滚跟延迟补偿，对于客户端管理数据的能力提出了很高的要求，客户端要能够记录最近n帧的快照（世界状态），然后在检测到自身与服务端数据有冲突时进行和解，所谓和解，即回滚到发生冲突的那一帧，先把状态修改为服务端的权威状态，然后再应用本地的预测 input。   

守望先锋团队抱着试一试的心态采用的 ECS 架构，恰好可以很好的 “管理快速增长的代码复杂性” [6]，并且由于数据与逻辑完全分离，对于做数据回滚特别的方便。云风也分析到 ECS 架构对于做预测回滚会有很大帮助 [7]。

有精细的实现，也有粗糙的实现，我在 github 上看过一份源码（ [https://github.com/tsymiar/TheLastBattle](https://github.com/tsymiar/TheLastBattle) ），这款 moba 游戏里面也实现了客户端“预测先行”，但它只是把 local player 的朝向修改了，并没有真正的先移动。代码在此：
[https://github.com/tsymiar/TheLastBattle/blob/main/Client/Assets/Scripts/GameEntity/Iselfplayer.cs](https://github.com/tsymiar/TheLastBattle/blob/main/Client/Assets/Scripts/GameEntity/Iselfplayer.cs):     

```cs
public override void OnExecuteEntityAdMove()
{
    base.OnExecuteEntityAdMove();
    Quaternion DestQuaternion = Quaternion.LookRotation(EntityFSMDirection);
    Quaternion sMidQuater = Quaternion.Lerp(RealEntity.GetTransform().rotation, DestQuaternion, 10 * Time.deltaTime);
    RealEntity.GetTransform().rotation = sMidQuater;
    this.RealEntity.PlayerRunAnimation();
}
```  

这做法算是一种很经济的实现了 ：），应用范围也很广，比如在释放技能的时候，经常会搞一段很长时间的前摇，比如说 100 毫秒，等前摇完的时候，服务器回包也基本上收到了（当然，这里也要求服务端以比较高的帧率运行，否则 100 毫秒还不足以覆盖 RTT + 服务器帧时长），然后就可以播放真正的技能特效了。    

---

# 参考

[1] Valve. Source Multiplayer Networking. Available at https://developer.valvesoftware.com/wiki/Source_Multiplayer_Networking.    

[2] [美]Joshua Glazer, Sanjay Madhav. 网络多人游戏架构与编程. 王晓慧, 张国鑫. 北京: 人民邮电出版社, 2017-10(1): 244-245.           

[3] Jesse Aronson. Dead Reckoning: Latency Hiding for Networked Games. Available at https://www.gamedeveloper.com/programming/dead-reckoning-latency-hiding-for-networked-games#close-modal, 1997-9.        

[4] co lin. 深入探索AOI算法. Available at https://zhuanlan.zhihu.com/p/201588990, 2020-8-28.        

[5] David Aldridge. I Shot You First: Networking the Gameplay of Halo: Reach. Available at https://www.youtube.com/watch?v=h47zZrqjgLc, 2011.      

[6] kevinan. 暴雪Tim Ford：《守望先锋》架构设计与网络同步. Available at https://www.sohu.com/a/148848770_466876, 2017-6.        

[7] 云风. 浅谈《守望先锋》中的 ECS 构架. Available at https://blog.codingnow.com/2017/06/overwatch_ecs.html, 2017-6-26.        
