---
layout: post
title:  "prometheus pushgateway 性能差的解决办法"
date:   2023-09-14
last_modified_at: 2023-09-14
categories: [server, devops]
---

### 基本现状
我们是分区分服的游戏，生产环境会有几百上千个游戏服进程，这些进程都想接入 prometheus 做一些指标监控。优化前的做法是：  
1. 全局只部署一个 pushgateway。
2. 每个物理服会部署 50 个左右游戏服进程，每个进程定时打印指标到各自的指标 log。
3. 每个物理服部署一个定时脚本，每 10 秒串行的采集各个指标 log，并通过 curl  post 给 pushgateway。
4. prometheus 从 pushgateway pull 这些指标。

<br>

没有直接在游戏服进程中内置 exporter 的原因大致有两方面：     
1. 上线之后才考虑加上 prometheus 监控，不想做太多改动，毕竟还涉及端口暴露之类的问题，需要运维配合开服脚本。  
2. 进程量太多了，而且频繁开新服、合服，需要频繁修改 prometheus 配置。
3. 其实以上都是借口：），不过多年的经验告诉我，让 prometheus 从上千个进程 pull 指标，估计也会出现一些性能问题。

### 存在问题
pushgateway 性能太差，不足以支撑这样的并发量，每个 post 的延迟 5 秒左右，而定时脚本又是串行工作的，每一轮总耗时达到 250 秒左右，完全是不可用状态。

### 优化过程

于是我对 prometheus、pushgateway 做了一点研究，经过几次优化，达到可用状态。

#### 优化一：多个游戏服的指标合并发送。
具体做法：定时脚本每轮采集完本机上所有的指标 log，把内容合并后再一次性 post 给 pushgateway。  
优化效果：单轮总耗时从 250 秒下降到 6 秒左右。

prometheus 的指标是这样定义的
```
指标名{标签,...} 指标值
```
比如
```
memory{"server_id":1,"zone":1001,"service":"clusterd"} 10000
```
prometheus 会从多个 target pull 指标，但它并不是很关心一个指标是从哪个 target 来的（虽然可以配置不同 target 给指标附加一些特定的标签值），只要保证 “指标名+标签” 是唯一的就够了。我们的 server_id 是唯一的，能够保证唯一性。

#### 优化二：pushgateway 开启 gzip 支持
具体做法：
优化效果：

#### 优化三：每个物理部署 pushgateway
具体做法：
优化效果：

### 总结



