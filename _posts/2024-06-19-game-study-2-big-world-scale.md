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

单服大世界的 scale 是游戏服务器的经典难题，已经被很多人研究过了。我对 scale 类的问题很感兴趣，所以研究得也比较多。  

本文不会探讨 MMO 类的网游提升单服承载人数有没有意义，只单纯讨论技术上如何实现。        

像 moba、fps、棋牌、体育竞技等 “开房间类型的游戏”，scale 起来比较简单。此类游戏的 pvp 一般是相对较少的玩家在一个小场景里进行对战，以这种小场景为单位去做负载均衡就行了。所以，即使是千万级同时在线，也没啥特别的困难，我在另一篇文章 [《游戏服务器工程实践一：百万级同时在线的全区全服游戏》](https://zhuanlan.zhihu.com/p/702597017)  也描述过这方面的工程实践。             

而像 mmo 这种大量玩家在同个场景的（这里称为大世界），scale 起来就比较困难。大世界本身就是一个整体，很难对它进行分割（partition）。无论怎么分割，它的各个部分之间都需要有交互，这种交互会带来工程实现上的诸多麻烦。       

mmo 这里取广义的概念（ Massive Multiplayer Online ），不特指 mmorpg，所以像现在的各种 slg，也算是一种 mmo。   

下文将大致总结一些相关的技术点。   

---

# 1. 一些游戏的单服 pcu（最高同时在线）

坦克世界（world of tanks），自称是 mmo，但实际上并不是 mmo。它是 match based [1]，并不是一个大世界，相当于 moba 而已。官方说有 1M+ 的 pcu，但这也没啥特别的，毕竟这类游戏做负载均衡比较简单。另外，虽然它使用 bigworld engine 开发服务端，但并没有用到 bigworld 最拿手的动态负载能力。              

eve online，这么多年下来，单服 pcu 纪录大概是 65000 左右 [2]。     

wow，前段时间发了个测试数据，单服 pcu 能去到 12 万 [3]。   

看起来还是 wow 最强？   

---

# 2. scale 的方法

大致有两种方法，一种叫 zoning，一种叫 offloading。  

zoning 是空间上的分割，把地图分割成多个区域，分散到多个线程（进程）进行负载。优点是分割效果好，可以达到很高的承载能力；缺点是存在大量的异步编程，复杂度高，开发效率低。   

offloading 是逻辑上的分割，把相对独立的逻辑拆分到其他的线程（进程）去运算，主逻辑还是在一条线程上执行。优点是逻辑比较简单，开发效率较高；缺点是承载能力有限，主逻辑依然存在性能瓶颈。     

---

## 2.1 zoning 

zoning，即按地图区域进行分割。有两种方法进行分割：固定分割和动态分割。   

固定分割，即在服务器运行前，预先按一定方式把地图分割成 n 个区域（cell），由若干个线程（进程）承载这些 cell，服务器运行起来之后这种分割就不变了。   

动态分割，典型的实现是 bigworld，在服务器运行时进行动态分割，有一个全局的管理服务器（cellappmgr），根据整个地图上 entity（实体）的 cpu load 的分布情况，尽量平衡的对区域进行分割，分割出来的区域分散到各个 cell 服务器上（cellapp）。   

有些文章会说 bigworld 的实现是一种分布式 aoi，但看过代码就知道了，它就是对地图区域进行动态分割而已。     

---

### 2.1.1 zoning 固定分割

固定分割没什么好讲的，它的大体结构就是这样，下图取自韦易笑老师（ 知乎大佬：[https://www.zhihu.com/people/skywind3000](https://www.zhihu.com/people/skywind3000) ） 的这篇文章 [《游戏服务端架构发展史（中）》](https://www.skywind.me/blog/archives/1301) [4]。 

<br/>
<div align="center">
<img src="https://www.skywind.me/blog/wp-content/uploads/2015/04/image31.png"/>
</div>
<center>图1：zoning 固定分割的典型服务器架构[4]</center>
<br/>

node 是一个个的地图服务器，负责运行一块地图区域；nm 是 nodemanager，负责管理这些 node；world 是世界服务器，负责提供世界级别的服务。   

这种结构下，每个 node 承载的地图区域是固定的，玩家多的时候压力重，玩家少的时候压力轻，没有弹性可言。  

---

### 2.1.2 zoning 动态分割

典型的一种实现方式就是 bigworld engine。基本思路就是根据地图上 entity 的 cpu load 的分布情况进行分割，使用 bsptree 管理地图区域（cell），尽量保持 bsptree 子树的 cpu load 处于平衡状态。   

bigworld 的服务器架构是这样的：  

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-server-architecture.png"/>
</div>
<center>图2：bigworld 服务器架构[5]</center>
<br/>

动态区域分割 + 动态边界调整 的算法是这样：   

1、当出现过载的时，动态区域分割，尝试新增 cell，并把 cell 放到新的 cell 服务器（cellapp）去运行。  

2、当出现负载不均衡时，动态边界调整，尝试移动 cell 的边界，促使部分 entity 从一些 cell 移到另一些 cell。   

<br/>  

在 bigworld 中，用一个 space 代表一整张地图，分割出来的每个区域称为 cell，这些 cell 的面积不是固定的，边界会随着负载的变化进行移动，直至达到平衡。  

下图展示一种经过 动态区域分割 + 动态边界调整 之后的可能情况：   

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-load-balance-cell-split-10.drawio.png"/>
</div>
<center>图3：bigworld 动态分割的可能结果</center>
<br/>

bigworld 除了动态负载均衡，还做了下行消息优化来保证 scale，它会限制每个 client 的下行带宽，aoi 范围内有太多 entity 的时候，优先发送离自己比较近的 entity 的属性变化。   

bigworld 的整个 load balance 的算法实现略复杂，我会单独写一篇文章总结一下。   

---

### 2.1.3 无缝地图

提到 zoning，不得不说无缝地图。无论是固定分割还是动态分割，无缝都是可实现的，基本上都是用 ghosting 机制来处理边界问题。  

当玩家处于 cell 边界时，它要能通过 aoi 获取到相邻 cell 的 entity，并且可以无感的跨越 cell 的边界。   

Real Entity 是权威的 Entity。Ghost Entity 相邻 Cell 对应的 Real Entity 的数据拷贝。  

下图表示两个相邻的挨在一起的 cell。  

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/big-world-scale-ghosting-1.drawio.png"/>
</div>
<center>图4：相邻的两个 cell</center>
<br/>

下图表示这两个 cell 是怎么处理各自边界上的 entity 的。每个 cell 都会在边界处再延伸一段虚构的区域出来，这块区域就是对方的边界区域，且它的宽度跟 aoi 的半径相同。  

Cell1 的 entity 处于 cell1 自己的边界时，可以自己看到一些 ghost entity，这些 ghost entity 对应 cell2 边界区域上的 real entity。假如 cell1 上的 real entity 攻击了 ghost entity，则这些 ghost entity 会把相关事件转发给 cell2 上的 real entity，如果 real entity 发生属性变化，也会同步回对应的 ghost entity。  

所以 ghost entity 就相当于一个代理，方便了 cell1 对 cell2 边界上的 entity 进行操作，反之亦然。  

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/big-world-scale-ghosting-2.drawio.png"/>
</div>
<center>图5：相邻的两个 cell 如何处理边界</center>
<br/>

---

### 2.1.4 小结

固定分割的优点是实现简单；缺点是静态的对地图进行分割，无法适应玩家负载的动态变化，整体的适应能力较差。   

动态分割的优点是能动态适应玩家负载的变化；缺点是实现上复杂，很容易弄出 bug 来。  

无论是固定分割，还是动态分割，分割的粒度总是有限的，不可能无限小，所以，它们都无法解决小范围内有大量 entity 的问题，这种只能通过玩法规避，或者使用 offloading 的办法尽量的分割逻辑。   

---

## 2.2 offloading

玩家在小范围内聚集，导致局部负载过重，这里就称为同屏问题吧。同屏单位多的时候，假设有 M 个单位，彼此都在对方的 aoi 范围内，那么消息广播量就是 M 平方的量级，非常可怕。   

解决这个问题，有两种思路：1、玩法上彻底规避这种人群聚集的可能；2、提升单线程性能，把主线程的逻辑尽可能拆到其他线程去做。   

思路 1 是策划考虑的事，就不讲了，这里只说思路 2 即 offloading。   

offloading 的思路很简单，就是分拆逻辑，能够独立出去的逻辑尽量独立出去，让主线程只处理最核心的主逻辑。    

难点主要就在于分拆上，要分拆哪些逻辑，分拆了会不会性能更糟糕，都是要实际考虑跟量化的。要根据不同的项目情况使用不同的分拆策略，下面就举一些具体的例子。   

---

### 2.2.1 mmorpg offloading 的例子

网易的这个分享 [《游戏服务端高性能框架：来看《天谕》手游千人团战实例》](https://zhuanlan.zhihu.com/p/700231330) [6] 就是第二种思路，这种方式也叫 offloading。   

它干脆就不分割地图了，通过纵向拆分，提升单线程处理主逻辑的能力，最终用 60% ~ 80% （主线程40% ~ 50%，网络线程20% ~ 30%）的单进程 cpu 消耗，支撑 1150+ 人在同一地图团战 [6]。   

大体思路总结如下：  

1、视野同步优化   
把遍历实体上的所有属性进行打包序列化的逻辑拆分到网络线程，网络线程保存一份属性副本。    

2、消息广播优化    
消息广播也由网络线程来做，网络线程保存每个实体被哪些实体关注的列表。  

3、属性同步优化    
1）同一帧的多次改变合并为一次改变。   
2）复杂结构的改变，使用一种自定义的编码形式，比如有字典&数组的多重嵌套，则把 key、索引编码为一串字符串作为“改变key”，下发就只下发“改变key”+改变值即可。  

4、写库优化   
玩家属性也存一份副本在另外一个进程中，由这个进程负责写库，如果进程崩溃，还可以从另外这个进程中恢复数据。  
（点评：我觉得这样做只是增加了单点故障的风险，直接把写库逻辑拆到另外一个线程就行了）。  

5、技能同步优化    
技能的中间过程，改 “同步状态” 为 “同步指令”，减少需要下发的数据量。  

<br/>

可能有人会说大团战没啥意思，画面糊在一起，看都看不清楚。再一次指出，这里只讨论技术实现，好不好玩，策划跟玩家更有发言权。  

在过往的工作中，我也做过 mmo 的同屏优化，工作量也主要是集中在消息下行的优化上，整体思路大同小异，不过当时用的是 skynet。  

---

### 2.2.2 slg offloading 的例子

天美工作室的关于【重返帝国】这个游戏的分享 [《怎么解决大地图SLG的技术痛点？》](https://youxiputao.com/article/24673.html) [7] 挺不错的，具体的讲了他们是如何优化的。  

大体思路总结如下：   

一、流量优化     

1、降低向客户端同步的对象数量    

1）aoi 上，放弃九宫格算法，根据客户端的梯形视野精确的筛选视野内单位。     
2）根据客户端上报的实际负载能力，进行优先级裁剪，只向客户端同步最重要的对象。         

2、尽量降低单个对象向客户端同步的流量    

1）技能同步
根据各个客户端各自配置的流量限制进行同步（比如0.5秒内最多50个事件），可动态调整；按照优先级进行裁剪，规则有：玩家自己的事件优先级高，稀有事件优先级高，等。  

2）属性同步     
 a）字段级增量同步。   
 b）按需同步，当前场景不需要的字段就不同步了。   
 c）LOD 同步，每个属性在定义处可加上 LOD 标签，当玩家缩放时，根据 LOD 层数自动筛选必要的属性进行下发。   

3、属性存盘   

基于支持字段级增量的属性系统，采用 fulldata + deltadata 的存盘方式，减少存盘的 io 流量。   

<br/>

二、大地图优化   

1、视野拆到独立的线程，并且可以配置线程数。    
2、寻路拆到独立的线程，并且可以配置线程数。      

---

### 2.2.3 小结

offloading 的目标是尽可能的优化性能，优化是第一目标，所以它的做法基本上都很难说得上优雅。但是也没有其他更好的办法了，算是一种妥协吧。   

---

# 3. kbengine 与 bigworld

kbe （ [https://github.com/kbengine/kbengine](https://github.com/kbengine/kbengine) ） 是仿 bigworld 实现的一套游戏服务器引擎，代码是仿的，连文档也是仿的，比如 "KBEngine overview" （ [KBEngine overview(cn).pptx](https://github.com/kbengine/kbengine/blob/master/docs/KBEngine%20overview(cn).pptx) ）这份 ppt。   

但是最核心的动态分割部分，kbe 并没有实现。   

另外，kbe 没实现无缝地图，space 之间没有实现边界的管理。kbe 的 ghosting 机制，目前也只是用于 entity 在 space 之间传输，因为 “跳转不同的 space 在一瞬间也存在 ghost 状态” [8]。跨 space 传输，也就是将玩家从一张地图传送到另一张地图。      

所以，从完成度来看， kbe 只是一个普通的 mmorpg 实现，没有动态分割，也没实现无缝地图。    

有空的时候改一改 kbe，把动态分割跟无缝地图补充完整，应该会挺有意思的。   

---

# 4. 总结

本文讲了大世界 scale 的两大思路：zoning 和 offloading，简单描述了 bigworld engine 的 zoning 实现，也以一些公开的技术分享为例，总结了 offloading 的一般做法。   

新项目如果处于规划阶段，可以考虑 zoning 的思路，但是这个实现难度相对较高，如果不是精英团队，要慎重考虑。  
老项目或已经动工的项目，按照 offloading 的思路做优化会比较靠谱。     

---

# 5. 参考

[1] reddit. Why is this game considered an "MMO". Available at https://www.reddit.com/r/WorldofTanks/comments/uwsyj/why_is_this_game_considered_an_mmo/, 2012.      

[2] eve-offline. EVE-ONLINE STATUS MONITOR. Available at https://eve-offline.net/?server=tranquility.    

[3] 17173. 魔兽世界：官方公布测试首日数据，单服12W同时在线，世界第一. Available at http://news.17173.com/content/06132024/025402002.shtml, 2024-06-13.    

[4] 韦易笑. 游戏服务端架构发展史（中）. Available at https://www.skywind.me/blog/archives/1301, 2015-4-26.    

[5] bigworld. BigWorld Technology Server Whitepaper. Available at https://sourceforge.net/p/bigworld/code/HEAD/tree/trunk/docs/pdf/BigWorld%20Technology%20Server%20Whitepaper.pdf.    

[6] 网易游戏雷火事业群​.游戏服务端高性能框架：来看《天谕》手游千人团战实例》. Available at https://zhuanlan.zhihu.com/p/700231330, 2024-05-28.       

[7] 天美工作室. 怎么解决大地图SLG的技术痛点. Available at https://youxiputao.com/article/24673.html, 2023-03-01.       

[8] kbengine. ghost机制实现 #48. Available at https://github.com/kbengine/kbengine/issues/48, 2014-7-19.   

