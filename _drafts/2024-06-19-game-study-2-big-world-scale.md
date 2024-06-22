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

这是一个非常陈旧的话题了，没什么新鲜的，但本人对 scale 比较感兴趣，所以研究得比较多。   

本文不会探讨 MMO 类的网游提升单服承载人数有没有意义，只单纯讨论技术上如何实现。        

像 moba、fps、棋牌、体育竞技等 “开房间类型的游戏”，scale 起来比较简单。此类游戏的 pvp 一般是相对较少的玩家在一个小场景里进行对战，以这种小场景为单位去做负载均衡就行了。所以，即使是千万级同时在线，也没啥特别的困难，我在另一篇文章 [《游戏服务器工程实践一：百万级同时在线的全区全服游戏》](https://zhuanlan.zhihu.com/p/702597017)  也描述过这方面的工程实践。             

而像 mmo 这种大量玩家在同个场景的（这里称为大世界），scale 起来就比较困难。大世界本身就是一个整体，很难对它进行分割（partition）。无论怎么分割，它的各个部分之间都需要有交互，这种交互会带来工程实现上的诸多麻烦。       

mmo 这里取广义的概念（ Massive Multiplayer Online ），不特指 mmorpg，所以像现在的各种 slg，也算是一种 mmo。   

下文将大致总结一些相关的技术点。   

---

# 一些游戏的单服 pcu（最高同时在线）

坦克世界（world of tanks），自称是 mmo，但实际上并不是 mmo。它是 match based [1]，并不是一个大世界，相当于 moba 而已。官方说有 1M+ 的 pcu，但这也没啥特别的，毕竟这类游戏做负载均衡比较简单。另外，虽然它使用 bigworld engine 开发服务端，但并没有用到 bigworld 最拿手的大世界动态负载能力。              

eve online，这么多年下来，单服 pcu 纪录大概是 65000 左右 [2]。     

wow，前段时间发了个测试数据，单服 pcu 能去到 12 万 [3]。   

看起来还是 wow 最强？   

---

# scale 的大致方法

大致有两种方法，一种叫 zoning，一种叫 offloading。  

zoning 是空间上的分割，把地图分割成多个区域，分散到多个线程（进程）进行负载；优点是分割效果好，可以达到很高的承载能力；缺点是存在大量的异步编程，复杂度高，开发效率低。   

offloading 是逻辑上的分割，把相对独立的逻辑拆分到其他的线程（进程）去运算，主逻辑还是在一条线程上执行；优点是逻辑比较简单，开发效率较高；缺点是承载能力有上限，主逻辑依然存在性能瓶颈。     

---

## zoning 

zoning，即按地图区域进行分割。bigworld 在本质上也是这样的。    

有两种方法进行分割：固定分割和动态分割。   

固定分割，即在服务器运行前，预先按一定方式把地图分割成 n 个区域（cell），由若干个线程（进程）承载这些 cell，服务器运行起来之后这种分割就不变了。   

动态分割，典型的实现是 bigworld，在服务器运行时进行动态分割，有一个全局的服务器（cellappmgr），根据整个地图上 entity（实体）的分布情况，尽量平衡的对区域进行分割，分割出来的区域尽量平均的分散到各个地图服务器上（cellapp）。   

有些文章会说 bigworld 的实现是一种分布式 aoi，但是本质上，它就是对地图区域进行某种分割。    

至于无缝地图，无论是固定分割还是动态分割，都是可实现的，基本上都是使用 ghosting 机制来处理边界问题，让玩家处于 cell 边界时也能通过 aoi 获取到相邻 cell 的 entity，并且可以无感的跨越 cell 的边界。   

---

### zoning 固定分割

固定分割没什么好讲的，它的大体结构就是这样，下图取自韦易笑老师（ 知乎大佬：https://www.zhihu.com/people/skywind3000 ） 的这篇文章《游戏服务端架构发展史（中）》[4]。 

<br/>
<div align="center">
<img src="https://www.skywind.me/blog/wp-content/uploads/2015/04/image31.png"/>
</div>
<br/>

node 就是一个个的地图服务器，负责运行一小块地图；nm 就 nodemanager，负责管理这些 node；world 就是大世界地图服务器，管理整个大地图的全局信息。    

---

### zoning 动态分割

典型的一种实现方式就是 bigworld engine。基本思路就是根据区域内的 entity 数量来分割，entity 数量多就按照算法进行分割，数量少之后，再按算法重新合并，减少 cell。  

bigwold 有几个名词需要知道的，space 对应物理上一张连续的地图，cell 对应地图上的某个区域，就像这样：   

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-scale-cell-split.png"/>
</div>
<br/>

bigworld 是使用 bsptree 来管理区域的分割的，区域都是处理成矩形的，但区域的大小是各异的，比如这样：  

from: [无缝大地图-总体架构.pptx](https://github.com/yekoufeng/seamless-world/blob/master/无缝大地图-总体架构.pptx) 。   

bigworld 除了动态负载均衡，还做了下行消息优化来保证 scale，它会限制每个 client 的下行带宽，aoi 范围内有太多 entity 的时候，优先发送离自己比较近的 entity 的属性变化。   

---

### zoning 小结

无论是固定分割，还是动态分割，分割的粒度总是有限的，不可能无限小，所以，它们都无法解决小范围内有大量 entity 的问题，这种只能通过玩法去规避。  

---

## offloading

玩家在小范围内聚集，导致局部负载过重，这里就称为同屏问题吧。同屏单位多的时候，假设有 M 个单位，彼此都在对方的 aoi 范围内，那么消息广播量就是 M 平方的量级，非常可怕。   

解决这个问题，有两种思路：1、玩法上规避这种人群聚集的情况；2、提升单线程性能，把主线程的逻辑尽可能拆到其他线程去做。   

第二种思路就是 offloading 了。  

---

### mmorpg offloading 的例子

网易的这个分享 [《游戏服务端高性能框架：来看《天谕》手游千人团战实例》](https://zhuanlan.zhihu.com/p/700231330) [5] 就是第二种思路，这种方式也叫 offloading。它干脆就不分割地图了，通过纵向拆分，提升单线程处理主逻辑的能力，最终用 “60%~80% （主线程40%~50%，网络线程20%~30%）的单进程 cpu 消耗” [5]，支撑 1150+ 人在同一地图团战。   

可能有人会说大团战没啥意思，画面糊在一起，看都看不清楚。再一次指出，这里只讨论技术实现，好不好玩，策划跟玩家更有发言权。  

在过往的工作中，我也做过 MMO 的同屏优化，工作量也主要是集中在消息下行的优化上。  

---

### slg offloading 的例子

天美工作室的关于【重返帝国】这个游戏的分享 [《怎么解决大地图SLG的技术痛点？》](https://youxiputao.com/article/24673.html) 挺不错的，具体的讲了他们是如何优化的。  

有几个点在此简略复述一下，具体的可看原文：  

一、流量优化     
1、降低向客户端同步的对象数量
1）aoi 上，放弃九宫格算法，根据客户端的梯形视野精确的筛选视野内单位；    
2）根据客户端上报的实际负载能力，进行优先级裁剪，只向客户端同步最重要的对象；   

2、尽量降低单个对象向客户端同步的流量    
1）技能事件，根据各个客户端各自配置的流量限制进行同步（比如0.5秒内最多50个事件），可动态调整；按照优先级进行裁剪，规则：玩家自己的事件优先级高，稀有事件优先级高，...    
2）属性事件，a）字段级增量同步；b）按需同步，当前场景不需要的字段就不同步了；c）

二、大地图优化   
1、视野拆到独立的线程，并且可以配置线程数；    
2、寻路拆到独立的线程，并且可以配置线程数；   

---

# kbengine 与 bigworld

kbe （ [https://github.com/kbengine/kbengine](https://github.com/kbengine/kbengine) ） 是仿 bigworld 实现的一套游戏服务器引擎，代码是仿的，连文档也是仿的，比如 "KBEngine overview" （ [KBEngine overview(cn).pptx](https://github.com/kbengine/kbengine/blob/master/docs/KBEngine%20overview(cn).pptx) ）这份 ppt。   

但是最核心的动态分割部分，kbe 并没有实现。   

另外，kbe 也没实现无缝地图，space 之间没有实现边界的管理，它们都是独立存在的。kbe 的 ghosting 机制，目前也只是用于 entity 在 space 之间传输，因为 “跳转不同的 space 在一瞬间也存在 ghost 状态”[6]。跨 space 传输，也就是将玩家从一张地图传送到另一张地图。      

所以，从完成度来看， kbe 只是一个普通的 mmorpg 实现，没有动态分割，也没实现无缝地图。    

有空的时候改一改 kbe，把动态分割跟无缝地图补充完整，应该会挺有意思的。   

---

# 总结

本文讲了大世界 scale 的两大思路：zoning 和 offloading，重点描述了 bigworld engine 的 zoning 实现，也以一些公开的技术分享为例，总结了 offloading 的一般做法。   

新项目处于规划阶段，可以考虑一下 zoning 的思路。老项目或已经动工了的项目做优化，按照 offloading 的思路会比较靠谱。   

---

# 参考

[1] reddit. Why is this game considered an "MMO". Available at https://www.reddit.com/r/WorldofTanks/comments/uwsyj/why_is_this_game_considered_an_mmo/, 2012.      

[2] eve-offline. EVE-ONLINE STATUS MONITOR. Available at https://eve-offline.net/?server=tranquility.    

[3] 17173. 魔兽世界：官方公布测试首日数据，单服12W同时在线，世界第一. http://news.17173.com/content/06132024/025402002.shtml, 2024-06-13.    

[4] 韦易笑. 游戏服务端架构发展史（中）. Available at https://www.skywind.me/blog/archives/1301, 2015-4-26.    

[5] 网易游戏雷火事业群​.游戏服务端高性能框架：来看《天谕》手游千人团战实例》. Available at https://zhuanlan.zhihu.com/p/700231330, 2024-05-28.       

[6] kbengine. ghost机制实现 #48. Available at https://github.com/kbengine/kbengine/issues/48, 2014-7-19.   