---
layout: post
title:  "分区分服场景下的db设计"
date:   2023-07-11
last_modified_at: 2023-07-11
categories: [gameserver]
---

## 摘要
分区分服场景下，db 保存数据，用什么方式最佳？是否用 blob 是最优的？什么情况下应该用 blob，什么情况下不该用？以及为什么？