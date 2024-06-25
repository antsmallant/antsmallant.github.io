---
layout: post
title: "游戏服务器研究三：bigworld 的 load balance 算法"
date: 2024-06-20
last_modified_at: 2024-06-20
categories: [游戏后端]
tags: [gameserver]
---

本文应该会持续更新，因为算法有很多细节，看得越多，了解到的细节越多，而这些细节对于这类算法是很重要的，属于生产实践上的微调，离开这些微调，load balance 可能工作得不如意，在一些边角的情况下，表现很差。   

本文基于 bigworld 的这个开源版本：[2014 BigWorld Open-Source Edition Code](https://sourceforge.net/p/bigworld/code/HEAD/tree/)，更具体的信息可在我另一篇文章找到 [《游戏服务器研究一：bigworld 开源代码的编译与运行》](https://zhuanlan.zhihu.com/p/704118722) 。   

bigworld 的 load balance 的基本算法是地图区域分割+动态的区域边界调整。一张地图，代码中用一个 Space 类来表示，根据负载情况，动态分割成 n 个 区域（cell），这些 cell 的面积不是固定的，而是根据地图上的实体（entity）的 cpu 使用率（cpu load）来动态决定的，有些 cell 面积大，有些 cell 面积小。   

space 以及分割相关的信息，由单点的 cellappmgr 服务器管理，具体的 cell 运行在 cellapp 上，整个集群会有多个 cellapp。一个 space 可能会分割成多个 cell，但是在一个 cellapp 上，只能运行这个 space 的一个 cell，否则就没有意义了。   


1、一开始的时候，一个 Space 只包含一个 cell，这个 cell 占据了整个 space 的面积。  

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-load-balance-cell-single-1.drawio.png"/>
</div>
<br/>

2、当这个 cell 所在的 cellapp 的负载超过设定的阈值时，cellappmgr 决定增加一个 cell，并把这个 cell 放到另外的 cellapp 上运行，以此分担压力。  

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-load-balance-cell-single-1.drawio.png"/>
</div>
<br/>



