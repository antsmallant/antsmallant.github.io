---
layout: post
title: "游戏服务器工程实践四：可观测之prometheus+grafana+日志mcp"
date: 2026-04-25
last_modified_at: 2026-04-25
categories: [游戏后端]
tags: [gameserver]
---

* 目录  
{:toc}
<br/>

---

用 prometheus 做观测是大家都在做的事，关键是要对什么做观测，以及怎么做观测，以下总结一些实践。   


# 1. 常见数据的观测

## 1.1 请求延迟数据的观测

可以统计几个项：延迟分布，avg延迟，最近请求量（总/成功/失败），请求QPS。

**延迟分布**
需要的指标（分桶统计各个延迟区间的请求量）：
```
xx_latent_stat{serverid="xx", tag="latent_ngt_1ms_count"} xxxx
xx_latent_stat{serverid="xx", tag="latent_ngt_5ms_count"} xxxx
xx_latent_stat{serverid="xx", tag="latent_ngt_8ms_count"} xxxx
xx_latent_stat{serverid="xx", tag="latent_ngt_10ms_count"} xxxx
xx_latent_stat{serverid="xx", tag="latent_ngt_20ms_count"} xxxx
...
xx_latent_stat{serverid="x", tag="latent_ngt_100ms_count"} xxxx
xx_latent_stat{serverid="x", tag="latent_ngt_200ms_count"} xxxx
...
xx_latent_stat{serverid="x", tag="latent_ngt_1000ms_count"} xxxx
...
xx_latent_stat{serverid="x", tag="latent_ngt_10s_count"} xxxx
...
xx_latent_stat{serverid="x", tag="latent_ngt_80s_count"} xxxx
...
xx_latent_stat{serverid="x", tag="latent_gt_100s_count"} xxxx
```


grafana panel 的 Visualization 选择 pie chart。promsql 如下： 

```
sum by (tag) (increase (xxx_latent_stat{serverid=~"$serverid",tag=~"latent_.*s_count"} [$__range]))
```

说明：latent_ngt_20ms_count 表示延迟处于 (10ms, 20ms] 这一区间的请求量。


**avg 延迟** 
需要的指标（总延迟时间，总完成次数）：
```
xx_latent_stat{serverid="x", tag="total_latent_ms"} xxxx
xx_latent_stat{serverid="x", tag="total_done_count"} xxxx
```

grafana panel 的 Visualization 使用 Time Series。promsql 如下： 
```
sum(increase(xxx_latent_stat{serverid=~"$serverid", tag="total_latent_ms"}[$interval])) / (sum(increase(xxx_latent_stat{serverid=~"$serverid", tag="total_done_count"}[$interval])) or vector(1))
```


**最近请求量**     
需要的指标（总请求量、已完成量、成功量、失败量）：
```
xx_latent_stat{serverid="x", tag="total_call_count"} xxxx
xx_latent_stat{serverid="x", tag="total_done_count"} xxxx
xx_latent_stat{serverid="x", tag="total_suc_count"} xxxx
xx_latent_stat{serverid="x", tag="total_fail_count"} xxxx
```

grafana panel 的 Visualization 使用 Bar Gauge。  promsql 如下：
总请求量
```
sum (increase(xx_latent_stat{serverid=~"$serverid", tag="total_call_count"}[$__range]))
```
已完成量
```
sum (increase(xx_latent_stat{serverid=~"$serverid", tag="total_done_count"}[$__range]))
```
成功量
```
sum (increase(xx_latent_stat{serverid=~"$serverid", tag="total_suc_count"}[$__range]))
```
失败量
```
sum (increase(xx_latent_stat{serverid=~"$serverid", tag="total_fail_count"}[$__range]))
```


**请求QPS**
需要的指标（总请求量）：
```
xx_latent_stat{serverid="x", tag="total_call_count"} xxxx
```


grafana panel 的 Visualization 使用 Time Series。  promsql 如下：
```
sum(rate(redis_rank_cost_stat{serverid=~"$serverid", tag="total_call_count"}[$interval]))
```


# 2. grafana

## 2.1 几个关键点
1. dashboard 增加一个 datatype 为 Data Source 的 variable，比如叫它 ds，然后各个 panel 的数据源不要配死，要配为这个  variable：${ds}，这样 dashboard 导出的 json 文件就可以到处导入到各个环境去。 
2. dashboard 导出的 json 文件统一放到项目里面管理起来，提交 git/svn，并且要做到开发环境和生产环境通用。基本上就是把动态的东西都配置为 variable，比如上面说的数据源。  


## 2.2 利用 AI 快速生成 dashboard

不需要每个 dashboard 都手工配置，只需要配置好一个 dashboard，然后导出 json 文件。之后让 AI agent 参考这个 dashboard，就可以按你的意愿生成其他 dashboard 的 json 文件，再把这些 json 文件导入到 grafana 就行。    

实操下来，生成效果很好，agent 能充分理解你这些指标的内涵，以及与之匹配的最佳呈现方式。最近的一次，我让 agent 生成了 10 个面板，只有 2 个面板需要微调一下而已。   


# 3. prometheus/日志 mcp

生产环境的 prometheus / 日志，都应该暴露 mcp 接口，允许开发人员用 agent 访问，这样可以提高排查问题的速度。  

我们的运维就做了这样的 mcp，实际使用起来非常方便，现在生产环境的问题排查基本上都直接 agent 闭环了，不需要人介入去查日志，导日志。  


# 4. 小结
grafana 多少还有点前 AI 时代的感觉，在这个过渡阶段，还是有存在的必要的。  

prometheus 意义重大，它提供的观测可以直接通过 mcp 被 agent 查询。  

prometheus/日志系统一定要暴露 mcp，这是提效的关键。  