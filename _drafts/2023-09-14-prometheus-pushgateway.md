---
layout: post
title:  "pushgateway 性能差的解决办法"
date:   2023-09-14
last_modified_at: 2023-09-14
categories: [server]
---

我们是分区分服的游戏，生产环境会有几百上千个游戏服进程，这些进程都想接入 prometheus 做一些指标监控。大致做法是：  
1）游戏服进程定时打印指标到 log 文件；  
2）定时脚本定时采集 log 发送给 pushgateway；  
3）prometheus 通过 pushgateway pull 这些指标。

没有直接在游戏服进程中内置 exporter 的原因大致有两方面：  
1）上线之后才考虑加上 prometheus 监控，不想做太多改动，毕竟还涉及端口暴露之类的问题，需要运维配合开服脚本；  
2）进程量实在太多了，而且频繁开新服、合服，不想老是去修改 prometheus 配置。

我接手这一块的优化之前，具体是这样做的：
1）全局只部署一个 pushgateway；
2）每个物理机上的定时脚本每10秒从各个游戏服进程采集 log 并直接 curl post 给 pushgateway；

这样做存在的问题是，pushgateway性能太差，不足以支撑这样的并发量，导致每个post 请求的延迟差不多 5 秒左右，定时脚本是串行的处理本物理服上的各个游戏服进程的，通常一个物理服上部署 50 多个游戏服进程，这样一来，采集完一轮要花 250 秒以上的时间，基本上处于不可用状态。

我需要做出优化，于是对 prometheus 及 pushgateway 做了一点研究。

prometheus 的指标是这样定义的
```
指标名{标签,...} 指标值
```
prometheus 会去多个不同的 target pull 指标，但 prometheus 并不关心一个指标是从哪个 target 来的（尽管可以在配置target的地方加上一些附加的标签值）只要保证指标名+标签是唯一的就够了。我们可以简单的在标签里面加上服id来区分不同的游戏服，所以我们可以做出第一个优化，定时脚本采集完本物理服上的所有log文件，汇总起来一次性post给pushgateway，这样就减少了几十次post，一轮的总耗时也从250秒下降到6秒左右。


