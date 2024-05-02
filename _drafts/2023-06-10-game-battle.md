---
layout: post
title: "游戏开发之战斗系统"
date: 2023-06-10
last_modified_at: 2023-06-10
categories: [游戏开发]
tags: [game, battle]
---

* 目录  
{:toc}
<br/>

游戏中的战斗系统是游戏中的核心功能，属于 gameplay 下的核心子系统，本文总结一些实现要点。   

# 战斗系统是干什么的？

# 战斗系统的构成
* 技能系统
* buff系统


# 如何实现一个拓展性强的战斗系统？


# ECS
关于 ECS 的定义[1]
>ECS架构看起来就是这样子的。先有个World，它是系统（译注，这里的系统指的是ECS中的S，不是一般意义上的系统，为了方便阅读，下文统称System）和实体(Entity)的集合。而实体就是一个ID，这个ID对应了组件(Component)的集合。组件用来存储游戏状态并且没有任何的行为(Behavior)。System有行为但是没有状态。

---

# todo
* 基于行为树的战斗系统应该是什么样的？
* nkgmoba 是怎么做战斗系统的？
* 什么是 timeline
* 了解战斗系统的基本逻辑
* 命中判断什么时候放在前端，什么时候放在后端
* p7 的技能系统是怎么做的，以及 buf 是怎么实现的？  
* finalfight or rok 的战斗系统是怎么做的？
* ECS 具体是怎么一回事？
* 搜索关键词：游戏服务器 战斗系统



---

# 参考
[1] kevinan. 暴雪Tim Ford：《守望先锋》架构设计与网络同步. Available at https://www.sohu.com/a/148848770_466876, 2017-6.    
