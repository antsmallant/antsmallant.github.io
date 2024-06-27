---
layout: post
title: "游戏服务器工程实践二：prometheus pushgateway 的性能优化"
date: 2023-09-14
last_modified_at: 2023-09-14
categories: [游戏后端]
tags: [server, devops]
---

* 目录  
{:toc}
<br/>

本文记录一次对 prometheus pushgateway 做性能优化的过程，推送延迟从 200 秒下降到 0.1 秒。      

---

# 1. 概况 

prometheus 只允许拉取（pull）指标数据，不允许主动推给（push）它，所以要接入 prometheus，通常都需要实现一个 exporter 接口，也就是一个 http 接口，允许 prometheus 主动来拉数据。  

但是我们的游戏（一款 mmoarpg ）已经上线了，所以同事不想再在游戏服上增加 http 接口，于是他就用 pushgateway 来实现。pushgateway 相当于一个中介，它接受游戏服务器 push 指标数据，提供 pull 接口给 prometheus 去拉取。  

在开发环境，同事用几个游戏服务器推指标数据，都挺正常的，所以就上线了。但是，上线后表现很糟糕，指标数据推送到 pushgateway 的延迟特别高，每个物理服单轮延迟高达 200 秒左右，而推送又是串行的，延迟不断累积，这样一来，推送出去的指标数据都没有连续性可言了，所以整套 prometheus 监控的工作都不正常。  

而且由于上线后工作都很忙，同事也没时间再做优化，就搁置不管了。当我被安排来为这个项目做各种优化的时候，发现没有 prometheus 监控，各种优化都很难下手，于是我就开始尝试优化它。   

---

# 2. 优化

## 2.1 优化分析

这款游戏的游戏服进程很多，大概有 25 个物理服，每个物理服部署 40 个游戏服进程，所以总的大概有 1000 个游戏服进程。  

但全局只部署了一个 pushgateway 进程，而 pushgateway 内部是单线程的，并发多的时候，性能就会很差。   

游戏服进程到 pushgateway 的推送是这样工作的：  

1、每个游戏服进程每隔 5 秒 dump 一份指标数据到自己目录下的一个 log 文件；   
2、每个物理服上运行一个定时脚本，定时采集当前物理服上的所有游戏服进程的 log 文件，每采集一个就 push 给 pushgateway；  

<br/>

现在的问题是，定时脚本工作一轮下来耗时大概是 200 秒左右，相当于 push 每个游戏服的指标数据的延迟是 5 秒左右，非常高。  

<br/>

补充解释一下，单个物理服部署这么多游戏服进程，有几个原因：1、物理服的配置够高；2、小服生态，单个游戏服的同时在线人数不多；3、导量的时候，用户是相对平均的被分流到多个游戏服的，所以比较少出现用户集中到某个物理服的情况。   

---

## 2.2 优化过程

### 2.2.1 阶段一：批量推送

首先想到的优化手段是，推送脚本应该改为批量发送的。也就是，不要一个个 push 给 pushgateway，而应该在每一轮工作的时候，先把当前物理服上所有游戏服的指标数据汇总起来，再一次性 push 给 pushgateway，这样一来，pushgateway 的并发量就少了很多，可以下降 40 倍左右。  

而这样汇总实际上是没问题的，因为 prometheus 的指标是这样定义的：   

```
指标名{标签,...} 指标值
```  

比如：   
```
memory{"server_id":1,"zone":1001,"service":"clusterd"} 10000
```   

prometheus 会从多个 target pull 指标，但它并不是很关心一个指标是从哪个 target 来的（虽然可以配置不同 target 给指标附加一些特定的标签值），只要保证 “指标名+标签” 是唯一的就够了。而我们的 server_id 是唯一的，所以能够保证唯一性。     

**优化效果**     

按照这个思路优化之后，单轮的延迟从 200 秒下降到了 6 秒。  

效果不错，但还不够好，于是就继续优化。  

---

### 2.2.2 阶段二：pushgateway 开启 gzip 支持

定时脚本 push 的时候，指标数据是裸的 push 的，没做任何压缩，单次 push 的数据量可以达到 1.7 MB 左右，于是考虑是否可以通过压缩来进行优化。  

pushgateway 高一点的版本也支持了 gzip 优化，具体可以参考这个 [https://github.com/prometheus/pushgateway#request-compression](https://github.com/prometheus/pushgateway#request-compression)：   

>Request compression
>The body of a POST or PUT request may be gzip- or snappy-compressed. Add a header Content-Encoding: gzip or Content-Encoding: snappy to do so.
>
>```
>echo "some_metric 3.14" | gzip | curl -H 'Content-Encoding: gzip' --data-binary @- http://pushgateway.example.org:9091/metrics/job/some_job
>```

**优化效果**     

按照这个思路优化之后，单轮延迟从 6 秒降到 4 秒。文档的压缩率挺高，1.7MB 的 log 文件经过压缩后是 94KB。   

效果很不明显，于是就继续优化。  


---

### 2.2.3 阶段三：增加 pushgateway 的数量

想来想去，瓶颈还是出在 pushgateway 上，既然它性能这么差，那干脆就每个物理服部署 pushgateway，只服务于本物理服上的游戏服进程。而 prometheus 也修改配置，从多个 pushgateway pull 数据。虽然 pushgateway 数量增加了，但其实没增加多少，原先是 1 个，现在是 25 个，才增加 24 个，这对于 prometheus 来说压力不大。  

以上优化完，整个拓扑大概是这样：  

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/prometheus-pushgateway.png" />
</div>
<center>图1：阶段三优化后的部署结构</center>   
<br/>

**优化效果**   

按照这个思路优化之后，单轮延迟从 4 秒下降到 0.1 秒。    

感觉已经挺完美了，优化完毕。   

---

# 3. 优化反思

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

# 4. 总结

* pushgateway 没有多线程支持，并发性能很差，并且未来也不考虑支持多线程，因为它的设计目标不在于此。   

* pushgateway 在生产环境应该以多进程的方式进行部署，可以每个物理服部署一个进程。    

* 往 pushgateway 发送指标数据的时候，尽量把数据合并起来发送，减少发送的次数，合并的时候想办法保证 “指标名+标签” 唯一就行了。   

* 使用一个工具前，需要深入了解此工具的设计初衷、适用场景、性能局限等。

* 一个项目的文档，最关键的内容往往放在最开头，不妨花点时间好好读一读。   

---

正文完