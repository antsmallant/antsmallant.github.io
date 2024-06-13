---
layout: post
title: "游戏服务器工程实践二：prometheus pushgateway 性能差的解决办法"
date: 2023-09-14
last_modified_at: 2023-09-14
categories: [游戏后端]
tags: [server, devops]
---

* 目录  
{:toc}
<br/>

本文记录一次对 prometheus pushgateway 做性能优化的过程。  

prometheus 只允许拉取（pull）指标数据，不允许主动推给（push）它，所以要接入 prometheus，通常都需要实现一个 exporter 接口，其实就是一个 http 接口，允许 prometheus 主动来拉数据。  

但是我们的游戏已经上线了，所以同事不想再在游戏服上增加 http 接口，于是他就用 pushgateway 来实现，pushgateway 相当于一个中介，它接受外部的 push，提供 pull 接口给 prometheus 去拉取。  

一般情况下，一个物理服上我们会部署 50 个左右的区服（大部分都是老服，人很少的，所以不会有啥性能问题），所以整个实现看起来是这样的：   





但是对于分区分服的游戏来说，生产环境一般会有几百到上千个游戏服进程，这些进程都需要接入 prometheus 做一些指标监控。

优化前的状况是：  

* 全局只部署一个 pushgateway。

* 每个物理服会部署 50 个左右的游戏服进程，每个进程定时打印指标到各自的指标 log 文件。

* 每个物理服部署一个定时脚本，每 10 秒串行的采集各个指标 log，并通过 curl post 给 pushgateway。

* prometheus 从 pushgateway pull 指标。    

没有直接在游戏服进程中内置 exporter 的原因大致有：     

* 上线之后才考虑加上 prometheus 监控，不想做太多改动，毕竟还涉及端口暴露之类的问题，需要运维配合修改开服脚本。  

* 进程量太多了，而且频繁开新服、合服，需要频繁修改 prometheus 配置。   

其实以上都是借口，不过多年的经验告诉我，让 prometheus 从上千个进程 pull 指标，估计也会出现一些性能问题：）     

---

# 2. 存在的问题

pushgateway 性能太差，不足以支撑这样的并发量，每个 post 的延迟为 5 秒左右，而定时脚本是串行工作的，所以每一轮总耗时为 250 秒左右，完全是不可用状态。   

---

# 3. 优化措施

我对 prometheus、pushgateway 做了一些研究，经过几次优化，单轮延迟从 250 秒下降到 0.1 秒，达到可用状态。下面逐一介绍我使用过的优化手段，其中优化一跟优化三带来的效果是最明显的。   

## 3.1 优化一：多个游戏服的指标合并发送。

* 优化效果   
单轮延迟从 250 秒下降到 6 秒。    

* 具体做法  
定时脚本每轮采集完本机上所有的指标 log，把内容合并后再一次性 post 给 pushgateway。        
prometheus 的指标是这样定义的：   
```
指标名{标签,...} 指标值
```  

比如：   
```
memory{"server_id":1,"zone":1001,"service":"clusterd"} 10000
```   

prometheus 会从多个 target pull 指标，但它并不是很关心一个指标是从哪个 target 来的（虽然可以配置不同 target 给指标附加一些特定的标签值），只要保证 “指标名+标签” 是唯一的就够了。我们的 server_id 是唯一的，能够保证唯一性。     

---

## 3.2 优化二：pushgateway 开启 gzip 支持

* 优化效果   
单轮延迟从 6 秒降到 4 秒。文档的压缩率挺高，1.7MB 的 log 文件经过压缩后是 94KB。   

* 具体做法  
关于 gzip 使用的说明 [https://github.com/prometheus/pushgateway#request-compression](https://github.com/prometheus/pushgateway#request-compression)：   
>Request compression
>The body of a POST or PUT request may be gzip- or snappy-compressed. Add a header Content-Encoding: gzip or Content-Encoding: snappy to do so.
>
>```
>echo "some_metric 3.14" | gzip | curl -H 'Content-Encoding: gzip' --data-binary @- http://pushgateway.example.org:9091/metrics/job/some_job
>```      

---

## 3.3 优化三：每个物理服部署 pushgateway

* 优化效果  
单轮延迟从 4 秒下降到 0.1 秒。    

* 具体做法  
直接在每个物理服上部署一个 pushgateway，服务于本服上的所有游戏服进程；prometheus 修改配置，从多个 pushgateway pull 数据。虽然 pushgateway 数量增加了，但其实没增加多少，以 1000 个游戏服，每个物理服部署 50 个游戏服计算，也才 20 个 pushgateway，对 prometheus 来说压力不大。     

<br/>

以上优化完，整个拓扑大概是这样：  
![部署结构](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/prometheus-pushgateway.png)  
<center>图1：部署结构</center>   

---

# 4. 优化过程回顾

在 pushgateway 的 github 主页 ([https://github.com/prometheus/pushgateway](https://github.com/prometheus/pushgateway))，README.md 最开始就写了设计初衷：
>The Prometheus Pushgateway exists to allow ephemeral and batch jobs to expose their metrics to Prometheus. Since these kinds of jobs may not exist long enough to be scraped, they can instead push their metrics to a Pushgateway. The Pushgateway then exposes these metrics to Prometheus.    

而我并没有注意到这个，很多人也都没注意到这个。我花了不少时间在 github issues 搜索 performance 相关的 issue；在 google 搜索 "pushgateway 性能差"、"pushgateway bad performance"，但都没啥收获。   

唯一的收获是发现新版本的 pushgateway 支持 gzip 了，但这个带来的效果并不怎么明显。      

关于 performance，这个 issue "Feature request: Multi-thread support #402" ([https://github.com/prometheus/pushgateway/issues/402](https://github.com/prometheus/pushgateway/issues/402)) 说的内容跟我的场景有点类似。他提到他们有 1000 个 client 需要发指标给 pushgateway，当只有一个 pushgateway 时请求延迟是 4 分钟，当数量增加到三个之后，请求延迟下降到 12 秒，所以他问 pushgateway 是否能提供多线程支持。而项目维护者的回复是:    
>https://github.com/prometheus-community/PushProx may be helpful for your use case, but as said, details need to be discussed elsewhere.
>
>Also note that using the PGW to allow push with Prometheus is not just a performance problem. There are loads of semantic problems, too (like inability to deal with metric inconsistencies, up-monitoring, staleness handling, …). That's why I like to keep the PGW simple and focused on what it is meant for.    

pushgateway 的维护者说得也有道理，要 "keep the PGW simple and focusd on what it is meant for", blah blah ..。哎，反正他懒得优化的时候，这些都是说得过去的说辞。     

不过也没关系，通过这些优化手段：1.批量合并指标数据 2.多进程方式部署 pushgateway，我们也达到了优化目标，并且能扛住未来数据量的增长。    

---

# 5. 总结

* pushgateway 没有多线程支持，并发性能很差，并且未来也不考虑支持多线程，因为它的设计目标不在于此。

* pushgateway 在生产环境应该以多进程的方式进行部署，可以每个物理服部署一个进程。

* 往 pushgateway 发送指标数据的时候，尽量把数据合并起来发送，减少发送的次数，合并的时候想办法保证 “指标名+标签” 唯一就行了。

* 使用一个工具前，需要深入了解此工具的设计初衷、适用场景、性能局限等。

* 一个项目的文档，最关键的内容往往放在最开头，不妨花点时间好好读一读。