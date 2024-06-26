---
layout: post
title: "游戏服务器研究三：bigworld 的 load balance 算法"
date: 2024-06-20
last_modified_at: 2024-06-20
categories: [游戏后端]
tags: [gameserver]
---

系列文章：  

* [游戏服务器研究一：bigworld 开源代码的编译与运行](https://zhuanlan.zhihu.com/p/704118722)   
* [游戏服务器研究二：大世界的 scale 问题](https://zhuanlan.zhihu.com/p/705423006)

---

bigworld 的 load balance 算法的大致思路是知道的，即动态区域分割+动态边界调整。但具体是怎么实现的，不清楚，网上也不找到相关的文章介绍，所以只能自己看代码进行分析。   

本文大致记录我所分析到的算法实现，基于 bigworld 的这个开源版本：[2014 BigWorld Open-Source Edition Code](https://sourceforge.net/p/bigworld/code/HEAD/tree/)，更具体的信息可在我另一篇文章找到 [《游戏服务器研究一：bigworld 开源代码的编译与运行》](https://zhuanlan.zhihu.com/p/704118722) 。   

本文应该会持续更新，因为算法有很多细节，看得越多，了解越多。而这些细节对于这类算法是很重要的，属于生产实践上的微调，离开这些微调，load balance 可能工作得不如预期，甚至在一些边角的情况下，可能会表现得特别差。    

如有错误，欢迎指出。  

---

# bigworld 服务器架构

与 load balance 相关的服务器是 cellapp 和 cellappmgr，其中 cellapp 可以有很多个，而 cellappmgr 全局只有一个。   

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-server-architecture.png"/>
</div>
<center>图1：bigworld 服务器架构[1]</center>
<br/>

---

# load balance 基本算法

bigworld 的 load balance 的基本算法是动态区域分割+动态边界调整。  

一张地图，bigworld 用一个 Space 类来表示，根据负载情况，动态分割成 n 个 区域（cell），这些 cell 的面积不是固定的，会根据地图上的实体（entity）的 cpu 使用率（cpu load）的分布情况来动态调整。   

Space 以及 cell 相关的分割信息，由全局唯一的 cellappmgr 服务器管理；具体的 cell 运行在 cellapp 服务器上，整个集群会有多个 cellapp。  

一个 space 可能会分割成多个 cell，但是在同一个 cellapp 上，只能运行这个 space 的一个 cell（否则负载均衡就没有意义了）。   

---

## 算法过程

下面大致描述一种可能的分割情况。   

<br/>

1、一开始的时候，一个 Space 只包含一个 cell，这个 cell 占据了整个 space 的面积。    

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-load-balance-cell-single-1.drawio.png"/>
</div>
<br/>

2、当一个 space 所使用的一组 cellapp 的平均负载超过阈值时，cellappmgr 会决定增加一个 cell，并把这个 cell 放到组外的 cellapp 上运行，以此分担压力。    

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-load-balance-cell-split-2.drawio.png"/>
</div>
<br/>

3、如果可以通过调整边界来使得各个 cell 的负载在阈值之内，并且负载相差最小，则直接调整边界。  

值得指出的是，上面第 2 步中，新增的 cell3，一开始它的面积是 0，在动态的调整中，会慢慢增加它的占用面积，直到它上面运行的 entity 的负载之和与 cell2 相当。这个过程不是一步到位的，这样做的好处是整个过程变得很平滑，不会一下子需要从 cell2 迁移大量的 entity 到 cell3 上面。        

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

bigworld 的代码质量很高，模块划分比较清晰。但是如果不了解一些核心概念，那么看 load balance 相关的代码就会很吃力。我也是硬看了一段时间，才理清大致的脉络。     

下面的分析不会按照小白的方式，进行有条有理的叙述，只会点出一些核心的、对于理解整个逻辑最关键的要点，具体逻辑要自己看代码。    

---

## bsptree 的概念

bsptree 即 Binary Space Partioning Tree，实际上这里并不需要深入理解这种 tree，把它当成一棵二叉树即可，不会影响对整个算法的理解。   

---

## bsptree 相关的数据结构

在 cellappmgr 目录下

|类名|说明|文件|
|:--|:--|:--|
|BSPNode|bsp节点基类|bsp_node.cpp|
|CellData|bsp叶子节点类，继承自BSPNode|cell_data.cpp|
|InternalNode|bsp中间节点类，继承自BSPNode|internal_node.cpp|

---

## bsptree 的构造过程

以下讨论的都是 cellappmgr 里面的类。   

1、数据结构
bsptree 的根结点保存在 Space 类中，即 `CM::BSPNode * pRoot_`。  

2、根结点的初始化
根结点的初始化很容易找到，它的调用链路是：  

```cpp
CellAppMgr::createEntityInNewSpace 
-> Space::addCell() 
-> Space::addCell( CellApp & cellApp, CellData * pCellToSplit )
```

强调一下，此时创建出来的 `pRoot_` 是 `CellData` 类型的（即 bsptree 的叶子节点类型）。它需要等到第一次分裂之后，才会变成 `InternalNode` 类型（即 bsptree 的中间节点类型）。  

3、根节点的第一次分裂     
这是隐藏得很深的，我找了挺久才捋清楚。  

它的调用链路是： 

```cpp
CellAppMgr::metaLoadBalance()
-> CellAppGroups::checkForOverloaded( float addCellThreshold )
-> overloadedGroups.addCells();
-> CellAppGroup::addCell()
-> Space::addCell()
-> Space::addCell( CellApp & cellApp, CellData * pCellToSplit )
```

到此为止，看看 `Space::addCell( CellApp & cellApp, CellData * pCellToSplit )` 的内部，此时传递的参数 `pCellToSplit` 是 null 的。  

里面执行到这句的时候 `pRoot_ = (pRoot_ ? pRoot_->addCell( pCellData ) : pCellData);` ，由于 `pRoot_` 此前已经初始化过，所以非空，那么就会执行 `pRoot_->addCell( pCellData )`，也就是调用 `CellData::addCell( CellData * pCell, bool isHorizontal )`，这里面就产生了分裂。  

经过这次分裂，`pRoot_` 正式变为 `InternalNode` 类型。  

---

## cpu 负载（cpu load）的计算

负载不是简单的使用 entity 的数量来衡量的，而是精细到每个 entity 的 cpu load。每个 entity 上面都有一个 profiler，当 entity 处理消息（handle message）的时候，profiler 就会被触发。  


---

## 动态分割的逻辑

---

## 动态调整边界的逻辑


---

## smooth 的意义

有很多变量前都加了 smooth 作为前缀，比如 `smoothedLoad_`，它的意义就是数学上说的“平滑”。   

比如下面这个函数里面计算 `smoothedLoad_`，就是使用了指数平滑法，其中 bias 就是指数平滑法用的参数。平滑的作用就是让变量不会抖动的太厉害，相对平缓一些。  

```cpp
void CellApp::informOfLoad( const CellAppMgrInterface::informOfLoadArgs & args )
{
	lastReceivedLoad_ = args.load;

	float addedArtificialLoad = 0.f;
	for (Cells::const_iterator it = cells_.begin();
			it != cells_.end();
			++it)
	{
		addedArtificialLoad +=
				(*it)->space().artificialMinLoadCellShare( lastReceivedLoad_ );
	}

	currLoad_ = lastReceivedLoad_ + addedArtificialLoad;
	float bias = CellAppMgrConfig::loadSmoothingBias();
	smoothedLoad_ = ((1.f - bias) * smoothedLoad_) + (bias * currLoad_);
	estimatedLoad_ = smoothedLoad_;
	numEntities_ = args.numEntities;
}
```

指数平滑法的计算公式为 $𝑆_𝑡$ = 𝑎$𝑌_{𝑡−1}$+(1−𝑎)$𝑆_{𝑡−1}$ ，

$$
𝑆_𝑡 = 𝑎𝑌_{𝑡−1}+(1−𝑎)𝑆_{𝑡−1}
$$

其中 $$𝑆_𝑡$$ 是平滑值，$$𝑌_{𝑡−1}$$ 是上一期的实际值，$$𝑆_{𝑡−1}$$ 是上一期的平滑值，a是平滑常数。   

---

# 一些问题

## cellapp 是怎么找到 cellappmgr 的

通过本机的 bwmachined2 这个进程查询得到 cellappmgr 的地址，然后向 cellappmgr 注册。   

---

## cellapp 上面 entity 的消息是怎么处理的

1、消息是收到立即处理的，但如果下一帧即将到来（ `app.nextTickPending()` ），则不能因为处理这个消息导致下一帧被延迟执行，所以需要先把消息先放到 cellapp 的 buffered 队列中： bufferedEntityMessages，bufferedInputMessages。   

2、这些 buffered 队列里的消息，会在下一帧开头的函数 `CellApp::handleGameTickTimeSlice()` 中被处理，即  

```cpp
this->bufferedEntityMessages().playBufferedMessages( *this );
this->bufferedInputMessages().playBufferedMessages( *this );
```    

---

# 参考

[1] bigworld. BigWorld Technology Server Whitepaper. https://sourceforge.net/p/bigworld/code/HEAD/tree/trunk/docs/pdf/BigWorld%20Technology%20Server%20Whitepaper.pdf.    