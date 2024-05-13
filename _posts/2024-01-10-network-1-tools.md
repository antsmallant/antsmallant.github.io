---
layout: post
title: "游戏服务器网络常识一：工具"
date: 2024-01-10
last_modified_at: 2024-01-10
categories: [游戏开发]
tags: [game, net]
---

* 目录  
{:toc}
<br/>

作为后端开发，特别是网络游戏后端开发，经常需要处理各种现网问题，其中有不少是网络相关的。  

下面列举的工具主要是在 linux 下的，诊断线上服务器问题的时候，往往是分秒必争，所以这些工具都要用得很熟练，才能不耽误事。   

---

# 工具

---

## netstat

netstat 可以说是最常用的网络工具了，它的作用就是查看网络状态，tcp、udp、unix socket 都可以。一般是结合 grep 命令来筛选结果。具体如何使用，可以 man 一下： `man netstat`。  

比如查看 9999 这个端口的信息：  

```bash
netstat -anp | grep 9999
```

比如查看所有的 listen:   

```bash
netstat -l
```

netstat 在 windows 下也有相应的实现，不过命令参数与 linux 下略有不同，而且过滤结果也不能使用 grep，得使用 find。  

比如查看 9999 这个端口的相关信息：  

```bash
netstat -ano | find "9999"
```

或者查看所有的监听信息：   

```bash
netstat -ano | find "LISTEN"
```

---

## lsof

lsof 意为 list open files，可以显示被打开的文件以及打开这些文件的进程。unix 一切皆文件，socket 也是文件，所以通过显示文件信息，足以窥探系统的一些运行状态。  

如果足够熟练，lsof 可以替代 netstat 和 ps 这两个工具。  

### lsof 基本要点



### lsof 获取网络信息

先列举一些网络相关的用法，基础语法是：  

```bash
lsof -i [46][protocol][@hostname|hostaddr][:service|port]
```

要注意，这串东西 `[46][protocol][@hostname|hostaddr][:service|port]` 是根据需要填的，但要挨在一起，中间不要有空格。 比如 `4tcp:9999` 或者 `tcp@127.0.0.1` 或者 `4tcp@127.0.0.1:9999`。 


一些例子：  

|命令|作用|
|---|---|
|`lsof -i`|显示所有网络连接|
|`lsof -i 6`|仅显示 ipv6 连接|
|`lsof -i tcp`|仅显示所有 tcp 连接|
|`lsof -i udp`|仅显示所有 udp 连接|
|`lsof -i :9999`|仅显示端口为 9999 的连接|
|`lsof -i 4tcp@127.0.0.1:9999`|显示ipv4，tcp协议，连接信息为 127.0.0.1 9999 的连接|


---

## nc

nc 即 netcat，nc 太有用了，它支持 tcp、udp，它可以作为客户端，也可以作为服务端，非常全能。下面举一些使用场景。  

一、测试端口是否可以连通   

这应该是使用最频繁的用途了。  

```bash
nc -v 127.0.0.1 9999
```

-v 可以打印出连接的详情。  

连接得上是类似这样提示：“Connection to 127.0.0.1 9999 port [tcp/*] succeeded!”。     
连接不上是这样提示：“nc: connect to 127.0.0.1 port 9999 (tcp) failed: Connection refused”。        

如果是 udp，则加上 -u 参数：   

```bash
nc -uv 127.0.0.1 9999
```

二、监听特定端口   

```bash
nc -l 9999
```

这个的意义在于，有时候我们自己的服务端进程无法被远端的客户端连通，需要排除是我们的服务端进程逻辑有问题，还是物理机的网络端口由于硬件或防火墙之类的问题无法连通。  

如果是 udp，则加上 -u 参数：  

```bash
nc -lu 9999
```

三、传输文件    

nc 甚至可以拿来传输文件。  

接收端：  

```bash
nc -l 9999 > recv.txt
```

发送端：   

```bash
nc 127.0.0.1 9999 < send.txt
```

---

## tcpdump


---

# 工具的数据来源

netstat、nstat、ifconfig、ethtool 的数据来源[1]:   

>netstat、nstat 是来自 /proc/net/netstat 和 /proc/net/snmp 的数据；   
>ifconfig 是读取 /proc/net/dev 下的数据，而后者的数据是从设备在内核的数据结构 net_device 里的结构 rtnl_link_stats64 中获取的；    
>ethtool 是直接通过 ioctl 下放的方式从同样的结构（net_device 中的 rtnl_link_stats64 ）中获取数据；    
>因此可以认为 ifconfig 和 ethtool 两者看到的网卡相关数据来源是一样的，但是 /proc/net/dev 进行了一定程度的归档，因此 ifconfig 中的 RX dropped = rx_dropped + rx_missed_errors，RX errors = rx_errors。    



---

# 参考

[1] johnazhang. 关于以ethtool为主的网络指标统计工具之间统计数据关系的研究原创. Available at https://cloud.tencent.com/developer/article/2050526,  2022-07-18.   