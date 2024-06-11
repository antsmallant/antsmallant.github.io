---
layout: post
title: "游戏服务器工程实践三：分服分区游戏的常规架构"
date: 2024-05-02
last_modified_at: 2024-05-02
categories: [游戏后端]
tags: [gameserver]
---

* 目录  
{:toc}
<br/>


全区全服和分区分服这两大类游戏的服务器我都开发过，宏观架构上，分区分服要简单得多，需要水平扩容的地方不多。   

分区分服游戏范指那种登录注册后，有很多个区服可以选择，选择其中一个之后才能进入游戏的，并且各个区服的角色数据是不互通的（转服、合服、跨服在本质上也都是数据不互通的）。市面上大部分的游戏都是分区分服的。  

分区分服类型的游戏，其核心挑战是战斗逻辑、网络同步，但宏观架构也至关重要，这关系到能不能撑得住上线后的突然的疯狂导量，出问题之后能否快速定位。  

本文将主要介绍分区分服类型游戏的常规架构，以及如何保证它的高可用&容灾。  

---

# 1. 总体架构

## 1.1 架构图

以下是一个实际可用的服务器架构：      

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/gamesvr-multi-zone-architecture.drawio.png"/>
</div>
<center>图1：分区分服游戏服务器总体架构</center>
<br/>

---

## 1.2 工作过程

以 “玩家登录并战斗” 为场景，简单说明一下工作过程:  

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/gamesvr-big-region-cli-join-battle-seq.png"/>
</div>
<center>图2：玩家登录并战斗流程</center>
<br/>

用文字描述就是：  

1、客户端通过 sdksvr 完成 sdk 登录授权，获得一个 token；  
2、客户端以 token 作为凭证连接上 plazasvr，拉取游戏数据；  
3、客户端发送加入战斗请求到 plazasvr，plazasvr 转发给 matchsvr，matchsvr 完成匹配后，从 battlesvr 集群中选择一台 battlesvr 来承担这局战斗；  
4、客户端连上分配下来的 battlesvr 进行战斗；  

---

# 2. 架构说明

---

## 2.1 网络负载层

---

## 2.2 游戏服务器层 

---

## 2.3 数据层

---