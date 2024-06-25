---
layout: post
title: "游戏服务器研究三：bigworld 的 load balance 算法"
date: 2024-06-20
last_modified_at: 2024-06-20
categories: [游戏后端]
tags: [gameserver]
---

bigworld 的 load balance 算法的大致思路是知道的，即动态区域分割+动态边界调整。但具体是怎么实现的，不清楚，网上也不找到相关的文章介绍，所以只能自己看代码进行分析。   

本文大致记录我所分析到的算法实现，基于 bigworld 的这个开源版本：[2014 BigWorld Open-Source Edition Code](https://sourceforge.net/p/bigworld/code/HEAD/tree/)，更具体的信息可在我另一篇文章找到 [《游戏服务器研究一：bigworld 开源代码的编译与运行》](https://zhuanlan.zhihu.com/p/704118722) 。   

本文应该会持续更新，因为算法有很多细节，看得越多，了解越多。而这些细节对于这类算法是很重要的，属于生产实践上的微调，离开这些微调，load balance 可能工作得不如预期，甚至在一些边角的情况下，可能会表现得特别差。    

如有错误，欢迎指出。  

---

# 基本算法

bigworld 的 load balance 的基本算法是动态区域分割+动态边界调整。  

一张地图，bigworld 用一个 Space 类来表示，根据负载情况，动态分割成 n 个 区域（cell），这些 cell 的面积是不固定的，会根据地图上的实体（entity）的 cpu 使用率（cpu load）分布情况来动态调整。   

Space 以及 cell 相关的分割信息，由全局唯一的 cellappmgr 服务器管理；具体的 cell 运行在 cellapp 服务器上，整个集群会有多个 cellapp。  

一个 space 可能会分割成多个 cell，但是在同一个 cellapp 上，只能运行这个 space 的一个 cell（否则负载均衡就没有意义了）。   

---

## 算法过程


1、一开始的时候，一个 Space 只包含一个 cell，这个 cell 占据了整个 space 的面积。    

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-load-balance-cell-single-1.drawio.png"/>
</div>
<br/>

2、当这个 cell 所在的 cellapp 的负载超过设定的阈值时，cellappmgr 决定增加一个 cell，并把这个 cell 放到另外的 cellapp 上运行，以此分担压力。    

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-load-balance-cell-split-2.drawio.png"/>
</div>
<br/>

3、如果可以通过调整边界来使得各个 cell 的负载在阈值之内，则直接调整边界。      

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-load-balance-cell-split-2-adjust.drawio.png"/>
</div>
<br/>

4、如果调整边界仍然无法解决负载过高的问题，则继续增加 cell，但 cell 是采取 geometric tessellation（几何镶嵌）的方式分割的，横向（Horizontal）与纵向（Vertical）交织着分割。  

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-load-balance-cell-split-3.drawio.png"/>
</div>
<br/>

5、依上述方法，经过多次分割后，可能演变成如下。   

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-load-balance-cell-split-10.drawio.png"/>
</div>
<br/>

---

# 代码分析 

bigworld 的代码质量很高，模块划分还是比较清晰的。但是如果不了解一些核心概念，那么看 load balance 相关的代码会很吃力。   




---

# 参考

