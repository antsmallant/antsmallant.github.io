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

分区分服类型的游戏，其核心挑战是战斗逻辑、网络同步，但宏观架构也至关重要，这关系到：1、能不能撑得住上线后的疯狂导量；2、出问题之后能否快速定位。  

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

以 “玩家登录并进入选中的区服” 为场景，简单说明一下工作过程:   

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/gamesvr-multi-zone-cli-join-battle-seq.png"/>
</div>
<center>图2：玩家登录并进入选中的区服</center>
<br/>

用文字描述就是：  

1、客户端通过 sdksvr 完成 sdk 登录授权，成功获得一个 sdk token；    
2、客户端通过 sdksvr 获取区服列表；   
3、客户端选中一个区服请求进入，sdksvr 向该区服的 intfsvr（接口服务器）发起 “创角或登录” 请求，intfsvr 响应并返回一个 game token；  
4、客户端使用 game token 连接 gamesvr；   

---

# 2. 架构说明

---

## 2.1 网络负载层

---

## 2.2 游戏服务器层 

---

## 2.3 数据层

---