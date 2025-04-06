---
layout: post
title: "linux 笔记：awk 输出对齐的技巧"
date: 2025-04-06
last_modified_at: 2025-04-06
categories: [linux]
tags: []
---

* 目录  
{:toc}
<br/>

最近的工作需要做很多性能优化，会需要打 log，然后用 awk 做一些统计分析。而这些分析也需要写到文档里，我希望这些分析结果尽量是格式优雅的，所以经常要在 awk 输出的时候做一些对齐。   

实际上我要的就是表头与数据项的对齐，比如这样：    

```
type  times  objcnt  cost(us)  avgcost(us)  备注
1     3900   1       33.430    33.430       xxx             
5     3901   696     2990.278  4.296        xxx             
9     3901   1       10.181    10.181       xxx             
10    3901   1       5.675     5.675        xxx          
12    3871   96      343.067   3.578        xxx           
14    3901   410     1351.222  3.296        xxx           
```

以前我没怎么好好研究过这个问题，就经常搞右对齐，然后手动增加一些空格，让结果最终看起来是比较对齐的。   

但这周我发现这样很费劲，就花了点时间琢磨了一下，终于悟到了怎么做才是最好的，就是全部都做成左对齐，数据项预留的宽度与表头字段的宽度对应保持一致，空格也保持一致，这样就很好的对齐了。  

比如这样的数据：  

```
[INFO ][32843][09:20:15.982] [LUA] [somefile] checkxxx, time_now = 1743556815956 idx = 0 some_type =  5 objCnt = 696 totalCost = 11530 avg_cost = 16.566 
[INFO ][32843][09:20:15.982] [LUA] [somefile] checkxxx, time_now = 1743556815956 idx = 0 some_type =  9 objCnt =   1 totalCost =    7 avg_cost = 7.000 
[INFO ][32843][09:20:15.982] [LUA] [somefile] checkxxx, time_now = 1743556815956 idx = 0 some_type = 10 objCnt =   1 totalCost =    6 avg_cost = 6.000 
[INFO ][32843][09:20:15.984] [LUA] [somefile] checkxxx, time_now = 1743556815956 idx = 0 some_type = 14 objCnt = 410 totalCost = 1503 avg_cost = 3.666 
[INFO ][32843][09:20:15.984] [LUA] [somefile] checkxxx, time_now = 1743556815956 idx = 0 some_type = 16 objCnt =  35 totalCost =  140 avg_cost = 4.000 
```

写这样的脚本：   

```
#!/bin/bash

echo "type  times  objcnt  cost(us)  avgcost(us)  备注"
cat aoiobj-time.txt | grep "some_type =  1" | awk '{totalcost += $20; avgcost += $23; objcnt += $17; times++} END {printf("%-4d  %-5d  %-6d  %-8.3f  %-11.3f  %-15s\n", 1, times, objcnt/times, totalcost/times, avgcost/times, "xxx")}'
cat aoiobj-time.txt | grep "some_type =  5" | awk '{totalcost += $20; avgcost += $23; objcnt += $17; times++} END {printf("%-4d  %-5d  %-6d  %-8.3f  %-11.3f  %-15s\n", 5, times, objcnt/times, totalcost/times, avgcost/times, "xxx")}'
```

表头是  `type  objcnt  cost(us)  avgcost(us)  备注`，那么awk 输出用这样的格式 `%-4d  %-6d  %-8.3f  %-11.3f  %-15s\n`，就可以让数据项与表头对齐了。   

在 awk 中， `%-4d` 其中 `-` 表示左对齐， `4` 表示输出宽度为 4， `d` 表示整数。   

type 的宽度是 4，那么数据项用 `%-4d`，而 objcnt 的宽度是 6，那么数据项项 `%-6d`。   

其他场景下，也都用这种方式就行了，不同语言的格式化输出基本上都是类似的。   