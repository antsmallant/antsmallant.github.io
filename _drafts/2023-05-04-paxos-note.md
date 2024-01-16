---
layout: post
title: "paxos 学习笔记"
date: 2023-05-04
last_modified_at: 2023-05-04
categories: [分布式]
tags: [paxos 分布式]
---

* 目录  
{:toc}
<br/>  

paxos 素来以难以理解著称，然而张炎泼(xp)的这篇文章 [可靠分布式系统-paxos的直观解释](https://blog.openacid.com/algo/paxos/) 却以特别易于理解的方式解释了 paxos 的工作原理，非常了不起。  

以下主要是我学习过程中的记录和理解。  

# 各种一致性模型


# 各种复制算法及其局限
## 同步复制
## 异步复制
## 半同步复制
## 多数派写（读）


# 多数派读写
* 以下用 Quorum 指代多数派读写
* Quorum 能达到的一致性是最终一致性，无法达到强一致性
* 


# paxos
paxos 是 Leslie Lamport 发明的算法，用于实现分布式系统的强一致性。它适用于网络延迟或不可达、节点崩溃，不适用于消息错误或存储错误。   


## classic paxos
classic paxos 是最原始的 paxos 算法。  

### 主要特点
* 使用两轮 rpc (多数派写) 来确定一个值
* 一个值确定之后就不再修改
* 算法过程通常划分为 phase_1, phase_2 
* 算法的角色包含 proposer 和 acceptor，proposer 可以理解为客户端，acceptor 可以理解为存储节点
* proposer 必须能够生成全局递增的唯一 id (这个是多数派读写的要求)
* phase_1 用于表明 proposer 即将写入一个值，此阶段可能会运行失败
* phase_2 是当 phase_1 运行成功的时候，确定的写

### 算法过程
假设 acceptor 总个数为 n  

phase_1: proposer 获得一个全局递增的 rnd，并向 n 个 acceptor 发送 phase_1 请求 phase_1 {rnd = rnd}，如果获得到超过 1/2*n 个返回，并且这些返回中的 v 与 vrnd 都是相同的，则表示


## multi paxos
classic paxos 必须使用两轮 rpc 来确定一个值，效率不高。multi paxos 的优化是：将多个 paxos 实例的 phase_1 合并在一轮 rpc 中执行，使得这些实例只需运行 phase_2。  

比如为这10个值 i1~i10 分别选取 1000~1009 这 10 个 rnd，合并运行一次 phase_1，然后 i1~i10 再依次以 1000~1009 的 rnd 运行 phase_2。  


## fast paxos


# 参考
* 张炎泼(xp): [可靠分布式系统-paxos的直观解释](https://blog.openacid.com/algo/paxos/). 2020-06-01.
* Martin Kleppmann: Designing Data-Intensive Applications. 2017.