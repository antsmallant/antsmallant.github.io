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

本文讨论的内容，可以说是游戏服务器最难的问题之一：如何对大世界进行 scale。  

分区分服类型的游戏，本人只做过 mmo 的，并且不是单服人数特别夸张的 mmo，能支持到的同屏人数就是 200 人而已（我跟前端主程花了一周多时间老板说这样就够了）。  

---

# mmo scale 的一些方法

大体结构上是这样：  

<br/>
<div align="center">
<img src="https://www.skywind.me/blog/wp-content/uploads/2015/04/image31.png"/>
</div>
<br/>

from: [游戏服务端架构发展史（中）](https://www.skywind.me/blog/archives/1301)

## 有缝地图

玩法设计上就不要大地图，地图直接拆成多个小地图，玩家从一个地图到另一个地图要 “传送”。   

但这种做法仍然有性能风险，如果大量玩家都挤到同张小地图上，负载也可能过重。  

---

## 无缝地图

大致上有 2 种拆分方式，一种是按地图拆分，另一种是按 aoi 拆分。  


### 按地图拆分

每个 cell 负责运行一块地图，各个 cell 处理好各自的边界，


### 按 aoi 拆分

这是 bigworld 的做法，不是物理上拆分地图，而是动态的虚拟的把地图分成 n 个区域，每个区域上的所有 entity（实体，包括玩家，npc等等）指定由某一个子进程管辖。这种方式也有人称为分布式 aoi。  

当某个区域聚集的 entity 数量超过设定的阈值时，就根据算法动态的把区域再次划分，拆给到负载更轻的进程上。  

bigworld 是使用 bsptree 来管理区域的划分的，区域都是处理成矩形的，但区域的大小是各异的，比如这样：  

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-scale-cell-split.png"/>
</div>
<br/>

from: [无缝大地图-总体架构.pptx](https://github.com/yekoufeng/seamless-world/blob/master/无缝大地图-总体架构.pptx) 。   

bigworld 的效果很虎的，world of tanks（坦克世界）的服务端是用 bigworld 开发的，在这个视频分享里面 （ []() ）讲到，world of tanks 在 2014 年的时候，ccu （即 concurrent user，同时在线用户）去到了 1M+（即一百万以上），这种单一世界的承载能力，太虎了。  

---

# mmo 的同屏性能问题

上面的，无论有缝，还是无缝，当玩家聚集的时候，始终会性能问题的，因为已经没法再拆分了。这种时候，就不是 scale out 能解决的了，需要 scale up 了。  

有不少方法可以使用，这篇文章 [《游戏服务端高性能框架：来看《天谕》手游千人团战实例》](https://zhuanlan.zhihu.com/p/700231330) 就换了一种思路，不切分地图，而是通过纵向拆分，提升单线程处理主逻辑的能力，最终用 60%~80% （主线程40%~50%，网络线程20%~30%）的单进程 cpu 消耗，支撑 1150+人 在同一地图团战。   

---

# slg scale 的方法


---

# 夹带一些其他问题

## 相位技术

魔兽的相位技术的实现，云风的这篇文章 [《相位技术的实现》](https://blog.codingnow.com/2012/11/phasing_technology.html) [1]考虑了一种可行的实现。  

本质上还是同一张地图拆分成多个场景服务去处理，这些场景都用同一张地图，但是上面布置的 npc 不一样，通过把玩家 agent 放到不同的场景服务来切换它的可见物。这种方式用他的 skynet 引擎去处理很简单，比在 C++ 里用多个线程去负载多个不同的场景简单得多，在 skynet 里，一切都是 actor，一个场景服务就是一个 actor（serivice），把一个玩家从一个 service 放到另一个 service，实现上很简单，性能上很快。  

---

# 参考

[1] 云风. 相位技术的实现. Avilable at https://blog.codingnow.com/2012/11/phasing_technology.html, 2012-11-23.   