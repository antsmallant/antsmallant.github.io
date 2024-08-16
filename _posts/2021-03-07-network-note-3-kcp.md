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

一套纯算法的ARQ可靠协议实现。ARQ 即是 

作者：skywind3000，真名：林伟，知乎账号：韦易笑。  

github： [https://github.com/skywind3000/kcp](https://github.com/skywind3000/kcp) 。   

---

# 2. kcp 的先进性

kcp 的作者韦易笑 (skywind3000) 在这篇知乎回答 [《MOBA类游戏是如何解决网络延迟同步的？》](https://www.zhihu.com/question/36258781/answer/98944369)[1] 中写道：   

>libenet的协议设计是非常落后的，基本上就是90年代教科书上那种标准ARQ协议实现，很难在复杂的网络条件下提供可靠的低延迟传输效果。而KCP具备更多现代传输协议的特点，诸如：流量换延迟，快速重传，流控优化，una/ack优化等。  

<br/>

[kcp github 主页上](https://github.com/skywind3000/kcp) 的介绍：  
>KCP是一个快速可靠协议，能以比 TCP 浪费 10%-20% 的带宽的代价，换取平均延迟降低 30%-40%，且最大延迟降低三倍的传输效果。  

<br/>

这个 issue [我司使用kcp制作上线的网络游戏，出现了比tcp更不稳定的网络状况](https://github.com/skywind3000/kcp/issues/100) 真是把我看笑了，怎么会有这么蠢的家伙。  

<br/>

     

---

# 3. kcp 的实现

主要参考这篇文章： [《KCP 协议介绍与业务优化》](https://www.cnblogs.com/moonwalk/p/18168164) [2] 。  


---

# 4. 若干问题

---

## 4.1 tcp 也有 sack 支持

sack 即 seletive acknowledgments 的缩写。tcp sack 的相关实现，具体的可参考这篇文章：[《Selective Acknowledgments (SACK) in TCP》](https://www.geeksforgeeks.org/selective-acknowledgments-sack-in-tcp/)。   

2017 年的这个 issue：[关于feature里一些特性与tcp的比较](https://github.com/skywind3000/kcp/issues/63) 有人问了相关的问题。  

issue 提的问题是：  

>对于 kcp feature 里面列出的三个特性：选择性重传 vs 全部重传、快速重传、UNA vs ACK+UNA，对于开启了 sack 选项的 tcp 来说，这三点 kcp 是不是和 tcp 基本一致了？   

韦老师的回答：  

>不一致，就这三点而言，需要发送端和接收端同时支持才行，就抓包情况而言，SACK的支持很不给力，超过80%的传输是没有SACK的，还有ACK延迟问题，新版本的 Linux(3.18?) 下的 TCP 多了这个选项，但是按文档说明，这个选项是一个建议，不一定会生效，或者会生效一段时间，当发生某些状态切换，又复原了。你可以发现不足以依靠。    
>
>KCP就是彻底可控，可以配置，包括快速重传的参数，内部时钟频率，tcp几乎是不可设置的，或者设置要改注册表或者sysctl（会影响其他类型的传输效果）。  
>
>KCP的彻底可控不仅体现在双端同时完整的支持较为先进的传输算法，参数和各种时钟彻底可以调节配置，还体现在你可以在KCP下面接一层 FEC 前向纠错，比如 RS 算法或者 xor 算法，来进一步增强传输效果，TCP 你是没法这么做的。  


之后又有一个叫 RuiHan2023 的人问了更专业的问题：   

>1.选择性重传的问题。定义在RFC 2018、2883 和 3517 定义，since 1996。我们国内现有的大多数服务器，kernel版本为2.6.32(centos 6u)，乃至更高的3.10(centos 7u)，是支持sack的。内核定义：int sysctl_tcp_sack __read_mostly = 1。目前的tcp变种，仅有reno不支持sack，而默认协议是cubic，since 2009，支持。我们日常的抓包，都能看到sack生效，wireshark可以看到这些。这里说百分之八十不支持，有类似的公开数据验证吗？   
>2.快速重传。3个重复ack，tcp就会进入，并不需要设置。这个特性支持也比较早了。wiki里对“快速重传”的举例似乎也有问题？并非Fast Recovery，而是sack的特性。   
>3.RTO。tcp并不经常进入RTO，仅当重传超时的时候，才进入。RTO比例较小。   
>4.关于NODELAY影响RTT计算，似乎也有问题？TCP rtt计算是根据包头的时间戳tval来的，滑动平均。此外，在数据连续的情况下，并不会delay。delay是为了等待上层应用的粘包，提高发包效率。此特性可以参数关闭。   
>补充一点：  
>UNA vs ACK+UNA。TCP ACK 本身是“累积确认”，即表示当前ackseq的包已经收到，也表示此前的所有包都收到了。这一点似乎还是在讲sack问题？   


这些问题我也很感兴趣，但韦老师没有回复，不知道是漏掉了，还是被问住了：）。这位兄台问得挺专业的，于是我特意查了一下，找到这个网页：https://livevideostack.cn/yellow_expert/%E9%9F%A9%E7%91%9E/ ，果然是专门研究计算机网络的，是鹅厂的专家工程师，中南大学本硕。   

---

## 4.2 kcp 如何接入 fec？ 

---

# 5. 参考

[1] 韦易笑. answer to MOBA类游戏是如何解决网络延迟同步的. Available at https://www.zhihu.com/question/36258781/answer/98944369, 2021-1-7.  

[2] 小夕nike. KCP 协议介绍与业务优化. Available at https://www.cnblogs.com/moonwalk/p/18168164, 2024-4-30.  