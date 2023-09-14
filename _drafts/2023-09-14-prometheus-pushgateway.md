---
layout: post
title:  "pushgateway 性能差的解决办法"
date:   2023-09-14
last_modified_at: 2023-09-14
categories: [server]
---

我们是分区分服的游戏，生产环境会有几百上千个游戏服进程，这些进程都想接入 prometheus 做一些指标监控。大致做法是：  
1）全局只部署一个 pushgateway；
2）每个物理服会部署50个左右游戏服进程，每个游戏服进程定时打印指标到 log 文件； 
3）每个物理服部署一个定时脚本，每 10 秒串行的采集各个游戏服的 log， 并发送给 pushgateway； 
4）prometheus 从 pushgateway pull 这些指标；

没有直接在游戏服进程中内置 exporter 的原因大致有两方面：  
1）上线之后才考虑加上 prometheus 监控，不想做太多改动，毕竟还涉及端口暴露之类的问题，需要运维配合开服脚本；
2）进程量实在太多了，而且频繁开新服、合服，不想老是去修改 prometheus 配置。

上面的做法存在的问题是，pushgateway 性能太差，不足以支撑这样的并发量，每个 post 请求的延迟差不多 5 秒左右，定时脚本是串行工作的，这样一来，每一轮耗时 250 秒以上，基本处于不可用状态。

必须做出优化，于是我对 prometheus、pushgateway 做了一点研究。

prometheus 的指标是这样定义的
```
指标名{标签,...} 指标值
```
prometheus 会去多个不同的 target pull 指标，但 prometheus 并不关心一个指标是从哪个 target 来的（尽管可以在配置target的地方加上一些附加的标签值）只要保证指标名+标签是唯一的就够了。由于我们的服id是保证唯一的，只要简单的将服id作为其中一个标签值即可。

基于以上知识，做出第一个优化。定时脚本每轮采集完本机上所有游戏服的log，汇总起来后再post一次，优化效果是单轮耗时从 250 秒降到 6 秒左右。




