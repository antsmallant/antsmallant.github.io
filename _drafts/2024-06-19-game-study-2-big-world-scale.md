---
layout: post
title: "游戏服务器研究二：大世界的 scale 问题"
date: 2024-06-19
last_modified_at: 2024-06-19
categories: [游戏后端]
tags: [gameserver]
---

* 目录  
{:toc}
<br/>

---

这是一个非常陈旧的话题了，不过也挺有意思的。本人对 scale 问题比较感兴趣，所以研究得比较多。本（水）文不会探讨现在 MMO 类的网游提升单服承载人数有没有意义，只单纯讨论技术上如何实现。        

像 moba，fps，棋牌，体育竞技等 “开房间类型的游戏”，scale 起来比较简单，pvp 一般是相对较少的玩家在一个小场景里面对战，以这种小场景为单位去做负载均衡就行了。所以，即使是千万级同时在线，也没啥特别的困难。          

而像 mmo 这种大量玩家在同个场景的（这里称为大世界），scale 起来就比较困难，大世界本身就是一个整体，很难对它进行分割（partition）。无论怎么分割，它的各个小块之间都需要有交互，这种交互会带来工程实现上的诸多麻烦。       

mmo 这里取广义的概念（ Massive Multiplayer Online ），不特指 mmorpg，所以像现在各种 slg，其实也算是一种 mmo 。   

本文大致总结一下相关的一些技术点，如有错误，请指出，谢谢。   

---

# 一些游戏的单服 pcu（最高同时在线）

坦克世界（world of tanks），自称是 MMO，但实际上并不是 mmo，它是 match based [1]，并不是一个大世界的，相当于一个 moba 而已。官网自称有 1M+ 的 pcu，但实际上没啥特别的。另外，虽然它用 bigworld 做服务端，但其实也没用上 bigworld 最牛的技术。           

eve online，这么多年下来，单服 pcu 记录大概是 65000 人左右 [2]。     

wow，前段时间发了个测试数据，单服能去到 12 万 [3]。   

看起来还是 wow 最强？   

---

# mmo 的 scale

mmo 的 scale，无非就是找到一种方式进行分割，实际上，我觉得目前就只有一种方式，即按地图区域进行分割，bigworld 在本质上也是这样的。   

这里面有两种做法，即固定分割和动态分割。   

固定分割，即在服务器运行前，就预先按一定的方式把地图分割成 n 块，由 n 个服务（器）承载这 n 块地图，服务器运行起来之后这种分割就不变了。   

动态分割，典型实现是 bigworld，在服务器运行时才动态分割，有一个全局的服务器（cellappmgr），根据整个地图上 entity（实体）的分布情况，尽量平衡的对区域进行分割，分割出来的小块尽量平均的分散到各个地图服务器上（cellapp）。   

有些文章会说 bigworld 的实现是一种分布式 aoi，但是本质上，它还是对地图区域进行了某种分割，分而治之。    

至于无缝地图，无论是固定分割还是动态分割，都是可实现的，只是代价问题。   

---

## 固定分割的实现

固定分割没什么好讲的，它的大体结构就是这样，下图取自韦易笑老师（ 知乎大佬：https://www.zhihu.com/people/skywind3000 ） 的这篇文章《游戏服务端架构发展史（中）》[4]。 

<br/>
<div align="center">
<img src="https://www.skywind.me/blog/wp-content/uploads/2015/04/image31.png"/>
</div>
<br/>

node 就是一个个的地图服务器，负责运行一小块地图；nm 就 nodemanager，负责管理这些 node；world 就是大世界地图服务器，管理整个大地图的全局信息。    

---

## 动态分割的实现

其实就是讲一下 bigworld 的实现。基本思路就是根据区域内的 entity 数量来分割，entity 数量多就按照算法进行分割，数量少之后，再按算法重新合并，减少 cell。  

bigwold 有几个名词需要知道的，space 就代表一整张大地图，cell 就代表地图上的某块区域，就像这样：   

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-scale-cell-split.png"/>
</div>
<br/>

bigworld 是使用 bsptree 来管理区域的分割的，区域都是处理成矩形的，但区域的大小是各异的，比如这样：  

from: [无缝大地图-总体架构.pptx](https://github.com/yekoufeng/seamless-world/blob/master/无缝大地图-总体架构.pptx) 。   

---

## 小结

无论是固定分割，还是动态分割，分割的粒度总是有限的，不可能无限小，所以，它们都无法解决小范围内有大量 entity 的问题，这种只能通过玩法去规避。  

---

# mmo 的同屏优化

玩家在小范围内聚集，导致局部负载过重，这里就称为同屏问题吧。同屏单位多的时候，假设有 M 个单位，彼此都在对方的 aoi 范围内，那么消息广播量就是 M 平方的量级，非常可怕。   

解决这个问题，也是两种思路，要么就是玩法上规避这种人群聚集的情况，要么就是提升单线程性能，把主线程的逻辑尽可能拆到其他线程去做，就像网易的这个分享
 [《游戏服务端高性能框架：来看《天谕》手游千人团战实例》](https://zhuanlan.zhihu.com/p/700231330) [5]讲到的。干脆就不分割地图了，而是通过纵向拆分，提升单线程处理主逻辑的能力，最终用 60%~80% （主线程40%~50%，网络线程20%~30%）的单进程 cpu 消耗，支撑 1150+人 在同一地图团战。   


---

# kbengine 与 bigworld

kbe 就是仿 bigworld 的，代码仿，连 "KBEngine overview" 这份 ppt 也是仿的，但是最核心的动态分割部分，kbe 没有实现。   

并且，cell 或 space 边界的 ghosting 机制也没实现，entity 的代码里面倒是有些 ghost 相关的代码，但是 cell，space 这一层都没有 ghost 管理的实现，所以等于是没有实现。   

所以，从完成度来看， kbe 只是一个非常普通的 mmorpg 实现，没有动态分割，也做不了无缝地图，除非对它进行魔改。   

不过，有空的时候改一改 kbe，把动态分割跟 ghosting 都补充完整，应该会挺有意思的。   

---

# slg 的 scale 问题

slg 跟常规的 mmorpg 有很多不同，需要单独研究一下它的 scale 问题，以及 aoi 问题。  

单独讲一下 slg 的 scale 问题，slg 的 aoi 跟 mmorpg 相比，有一些不同之处。像 rok 这种，是做了几个层次的 aoi 的。地图放大缩小，aoi 关注的点是不一样的。  


---

# 参考

[1] reddit. Why is this game considered an "MMO". Available at https://www.reddit.com/r/WorldofTanks/comments/uwsyj/why_is_this_game_considered_an_mmo/, 2012.      

[2] eve-offline. EVE-ONLINE STATUS MONITOR. Available at https://eve-offline.net/?server=tranquility.    

[3] 17173. 魔兽世界：官方公布测试首日数据，单服12W同时在线，世界第一. http://news.17173.com/content/06132024/025402002.shtml, 2024-06-13.  

[4] 韦易笑. 游戏服务端架构发展史（中）. Available at https://www.skywind.me/blog/archives/1301, 2015-4-26.    

[5] 网易游戏雷火事业群​.游戏服务端高性能框架：来看《天谕》手游千人团战实例》. Available at https://zhuanlan.zhihu.com/p/700231330, 2024-05-28.       