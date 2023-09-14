---
layout: post
title:  "pushgateway 性能差的解决办法"
date:   2023-09-14
last_modified_at: 2023-09-14
categories: [server]
---

我们是分区分服的游戏，生产环境会有几百上千个游戏服进程，这些进程都想接入 prometheus 做一些指标监控。做法是游戏服进程定时打印指标到一个 log 文件，定时脚本定时采集 log 并发送给 pushgateway，prometheus 通过 pushgateway pull 这些指标。

没有直接在游戏服进程中内置 exporter 的原因大致有两方面：1）上线之后才考虑加上 prometheus 监控的，不想做太多改动，毕竟还涉及端口暴露之类的问题，要让运维改脚本规划 exporter 的端口；2）进程量实在太多了，而且频繁开新服、合服，不想老是去修改 prometheus 配置。

我接手这一块的优化之前，他们是这么做的：
1）全局只部署一个 pushgateway；
2）每个物理机定时脚本每10秒从各个游戏服进程采集 log 并直接 curl post 给 pushgateway；
3）