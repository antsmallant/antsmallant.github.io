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

paxos 素来以难以理解著称，然而这篇文章 [可靠分布式系统-paxos的直观解释](https://blog.openacid.com/algo/paxos/) 却以特别易于理解的方式解释了 paxos 的工作原理，非常了不起。  

以下主要是我学习过程中的记录和理解。  

# 一致性模型


# paxos
## classic paxos
classic paxos 是最原始的 paxos 算法，它的主要特点是：  
* 使用两轮 rpc (多数派写) 来确定一个值
* 一个值确定之后就不再修改
* 算法过程通常划分为 phase_1, phase_2 
* 算法的角色包含 proposer 和 acceptor，proposer 可以理解为客户端，acceptor 可以理解为存储节点
* proposer 必须能够生成全局递增的唯一 id
* phase_1 用于表明 proposer 即将写入一个值，此阶段可能会运行失败
* phase_2 是当 phase_1 运行成功的时候，确定的写

## multi paxos
classic paxos 必须使用两轮 rpc 来确定一个值，效率不高。multi paxos 的优化是：将多个 paxos 实例的 phase_1 合并在一轮 rpc 中执行，使得这些实例只需运行 phase_2。  

比如为这10个值 i1~i10 分别选取 1000~1009 这 10 个 rnd，合并运行一次 phase_1，然后 i1~i10 再依次以 1000~1009 的 rnd 运行 phase_2。  

## fast paxos



# 参考
* 张炎泼(xp): [可靠分布式系统-paxos的直观解释](https://blog.openacid.com/algo/paxos/). 2020-06-01.
* Martin Kleppmann: Designing Data-Intensive Applications. 2017.