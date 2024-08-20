---
layout: post
title: "skynet 笔记：sharedata 与 sharetable 对比"
date: 2021-01-01
last_modified_at: 2024-7-2
categories: [skynet]
tags: [skynet]
---

* 目录  
{:toc}
<br/>

---

# 1. 简单对比

sharetable 在 2019 年就做出来了，见云风的这篇文章 [《不同虚拟机间共享不变的 Table》](https://blog.codingnow.com/2019/04/share_table.html) ，现在基本上都是使用这个的，而更早的，基本上都是使用 sharedata 的，中间还有一个叫 datasheet，但用的人可能不多。  

对比 sharedata 与 sharetable 是有意义的，从中可以看到 userdata + metatable 这种方案，在于性能要求的特殊场景下，并非一个好的设计选择，因为访问配置数据的代码占了游戏服务端逻辑的很大一部分比例，这里稍微有性能提升，对于整体的性能提升是很大的。这也就是 sharetable 存在的意义，虽然打破了 lua 的 vm 不直接 share 原生数据的原则，但却带了较大的性能提升。   

我在开发中实测过，使用 sharetable 代替 sharedata，性能的提升大约是 5 ~ 25 倍，这是一个比较大的提升（忘记当时具体的测量方法了，有空再重新测试一番）。   

sharedata 的实现是这样的，sharedatad 把一个 table 序列化成 c userdata，同个进程内的其他服务 query 这个名称的 table，sharedatad 就返回这个 userdata 的指针。各个服务的 vm 使用 metatable 的方式从这个 userdata 查询数据，而为了避免总是这样查数据，会创建 proxy，查过的就 cache 到 proxy 了。    

这样实现的好处是：惰性展开了，内存消耗上会少一些；其他服务 query 的时候也很快，因为只需要返回一个指针而已。  

缺点也就是：
1. 通过 metatable 访问，慢；  
2. 查询过程中，各个 vm 最终也是创建了 proxy，内存消耗会上来；    
3. 创建出来的 proxy 需要参与 gc。     

而反观 sharetable，它直接就修改了 lua vm 的实现，允许在不同的 vm share 只读的原生的 lua table，而且这些 table 不参与 gc。   

这完全就是碾压式的性能提升了：  
1. 不需要 metatable 访问，速度快；   
2. 不需要创建 proxy，内存占用少；   
3. 配置数据不参与 gc，速度快。      

所以，如果没有升级到 sharetable 的，都可以尝试升级一下，对性能的提升是很明显的。  

---

# 2. sharetable 的底层实现 

todo

---

# 3. sharedata 的底层实现

todo

---

# 4. 参考

