---
layout: post
title: "网络笔记三：kcp"
date: 2021-03-07
last_modified_at: 2021-5-1
categories: [网络]
tags: [网络]
---

* 目录  
{:toc}
<br/> 

记录 kcp 相关的信息。  

---

# 1. kcp 基本信息

一套纯算法的ARQ可靠协议实现。   

作者：skywind3000，真名：林伟，知乎账号：韦易笑。  

github： [https://github.com/skywind3000/kcp](https://github.com/skywind3000/kcp) 。   

---

# 2. kcp 的先进性

kcp 的作者韦易笑 (skywind3000) 在这篇知乎回答 [《MOBA类游戏是如何解决网络延迟同步的？》](https://www.zhihu.com/question/36258781/answer/98944369)[1] 中写道：   

>libenet的协议设计是非常落后的，基本上就是90年代教科书上那种标准ARQ协议实现，很难在复杂的网络条件下提供可靠的低延迟传输效果。而KCP具备更多现代传输协议的特点，诸如：流量换延迟，快速重传，流控优化，una/ack优化等。  

<br/>

[kcp github 主页上](https://github.com/skywind3000/kcp) 的介绍：  
>KCP是一个快速可靠协议，能以比 TCP 浪费 10%-20% 的带宽的代价，换取平均延迟降低 30%-40%，且最大延迟降低三倍的传输效果。  

---

# 2. kcp 的实现

---

# 3. 参考

[1] 韦易笑. answer to MOBA类游戏是如何解决网络延迟同步的. Available at https://www.zhihu.com/question/36258781/answer/98944369, 2021-1-7.  