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

这是一个很陈旧的话题了，不过也挺有意思的。   

像 moba，fps，棋牌，体育竞技等 “开房间类型的游戏”，scale 起来比较简单，pvp 一般是相对较少的玩家在一个小场景里面对战，以这种小场景为单位去做负载均衡就行了。所以，即使是千万级同时在线，也没啥特别的困难。          

像 mmo 这种大量玩家同服的，这里称为大世界，scale 起来就很困难，大世界本身就是一个整体，因此很难对它进行 partition。    

mmo 这里取广义的概念（ Massive Multiplayer Online ），不特指 mmorpg，所以像现在各种 slg，其实也算是一种 mmo 。   

有些人会觉得提高单服的同时在线人数没啥意义，因为策划或玩家可能不怎么需要这种大世界。但单纯作为技术来探究，这个问题还是很有意思的。            

本（水）文大致总结一下相关的一些技术点，如有错误，请指出，谢谢。   

---

# 一些游戏的单服 pcu（最高同时在线）

坦克世界（world of tanks），自称是 MMO，但实际上并不是 mmo，它是 match based [1]，并不是一个大世界的，相当于一个 moba 而已。官网自称有 1M+ 的 pcu，但实际上没啥特别的。另外，虽然它用 bigworld 做服务端，但其实也没用上 bigworld 最牛的技术。           

eve online，这么多年下来，单服 pcu 记录大概是 65000 人左右 [2]。     

wow，前段时间发了个测试数据，单服能去到 12 万 [3]。   

看起来还是 wow 最强？   

---

# mmo 的 scale

mmo 的 scale，无非就是找到一种方式进行 partition，实际上，我觉得目前就只有一种方式，即按地图区域划分，bigworld 在本质上也是这样的。   

这里面有两种做法，即固定切分和动态划分。  

普通的方式是固定划分，即预先按一定的方式把地图切割成 n 块，由 n 个服务（器）承载这 n 块地图，服务器运行起来之后这种切分就不变了。   

bigworld 的方式是动态划分，它并不提前切割，而是动态切割，有一个全局的服务器（cellappmgr），根据整个地图上 entity（实体）的分布情况，尽量平衡的对区域进行切割，切割出来的小块尽量平均的分散到各个地图服务器上（cellapp）。   

普通的方式在实现上可能真的会把地图切成 n 个小块，每个服务器只保存一小块的地图数据。而 bigworld 是不切地图的，每个 cellapp 拥有完整的地图数据，它只通过分割区域的坐标范围来确定自己的管辖范围。    

至于无缝地图，无论是固定切分还是动态划分，都是可实现的，只是代价问题。   

## 按地图拆分

按地图拆分的思路就是大地图拆成小地图，小地图分散到多个进程去跑着，各自承担一部分玩家。玩家在地图间位移，又分两种做法，一种是通过“传送”的方式把玩家从地图 a 送到地图b，另一种是做成“无缝地图”，玩家基本上感知不到小地图边界的存在。  

大体结构上就是这样的了：  

<br/>
<div align="center">
<img src="https://www.skywind.me/blog/wp-content/uploads/2015/04/image31.png"/>
</div>
<br/>

from: [游戏服务端架构发展史（中）](https://www.skywind.me/blog/archives/1301)

## 按 aoi 拆分

这是 bigworld 的做法，不是物理上拆分地图，而是动态的虚拟的把地图分成 n 个区域，每个区域上的所有 entity（实体，包括玩家，npc等等）指定由某一个子进程管辖。这种方式也有人称为分布式 aoi。  

当某个区域聚集的 entity 数量超过设定的阈值时，就根据算法动态的把区域再次划分，拆给到负载更轻的进程上。  

bigworld 是使用 bsptree 来管理区域的划分的，区域都是处理成矩形的，但区域的大小是各异的，比如这样：  

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-scale-cell-split.png"/>
</div>
<br/>

from: [无缝大地图-总体架构.pptx](https://github.com/yekoufeng/seamless-world/blob/master/无缝大地图-总体架构.pptx) 。   

---

## 小结

无论是按地图拆分，还是按 aoi 拆分，都是为了避免小范围内人群聚集，引起的大量消息广播，所以对于人群聚集的场景，都是无能为力的。 

---

# mmo 同屏性能问题

人群在小范围聚集，这里就称为同屏问题吧。同屏单位多的时候，假设 M 个单位，那么消息广播就是 M 平方的消息量，会很可怕。  

解决这个问题，也是两种思路，要么就是玩法上规避这种人群聚集的情况，要么就是卷单线程性能，把主线程的逻辑尽可能猜到其他线程去做，就像网易的这个分享
 [《游戏服务端高性能框架：来看《天谕》手游千人团战实例》](https://zhuanlan.zhihu.com/p/700231330) 讲到的。它这里干脆就不切分地图了，而是通过纵向拆分，提升单线程处理主逻辑的能力，最终用 60%~80% （主线程40%~50%，网络线程20%~30%）的单进程 cpu 消耗，支撑 1150+人 在同一地图团战。   

 这已经挺了不起的了。  

---

# slg 的 scale

单独讲一下 slg 的 scale 问题，slg 的 aoi 跟 mmorpg 相比，有一些不同之处。像 rok 这种，是做了几个层次的 aoi 的。地图放大缩小，aoi 关注的点是不一样的。  


---

# 参考

[1] reddit. Why is this game considered an "MMO". Available at https://www.reddit.com/r/WorldofTanks/comments/uwsyj/why_is_this_game_considered_an_mmo/.      

[2] eve-offline. EVE-ONLINE STATUS MONITOR. Available at https://eve-offline.net/?server=tranquility.    

[3] 17173. 魔兽世界：官方公布测试首日数据，单服12W同时在线，世界第一. http://news.17173.com/content/06132024/025402002.shtml.    