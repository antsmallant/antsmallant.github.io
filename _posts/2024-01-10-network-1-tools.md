---
layout: post
title: "网络常识一：常用工具"
date: 2024-01-10
last_modified_at: 2024-01-10
categories: [网络]
tags: [game, net]
---

* 目录  
{:toc}
<br/>


作为后端开发，特别是网络游戏后端开发，经常需要处理各种现网问题，其中有不少是网络相关的。  

下面列举的工具主要是在 linux 下的，诊断线上服务器问题的时候，往往是分秒必争，所以这些工具都要用得很熟练，才能不耽误事。   

---

# 1. 工具

---

## 1.1 netstat

netstat 可以说是最常用的网络工具了，它的作用就是查看网络状态，tcp、udp、unix socket 都可以。一般是结合 grep 命令来筛选结果。具体如何使用，可以 man 一下： `man netstat`。  

linux 下的基础语法是： 

```
usage: netstat [-vWeenNcCF] [<Af>] -r         netstat {-V|--version|-h|--help}
       netstat [-vWnNcaeol] [<Socket> ...]
       netstat { [-vWeenNac] -i | [-cnNe] -M | -s [-6tuw] }

        -n, --numeric            don't resolve names
        -l, --listening          display listening server sockets
        -a, --all                display all sockets (default: connected)
        -p, --programs           display PID/Program name for sockets        

  <Socket>={-t|--tcp} {-u|--udp} {-U|--udplite} {-S|--sctp} {-w|--raw}
           {-x|--unix} --ax25 --ipx --netrom
  <AF>=Use '-6|-4' or '-A <af>' or '--<af>'; default: inet
```

经常会用的选项：   

* `-a` 指定所有类型的连接，`-t` 指定 tcp 连接，`-u` 指定 udp 连接。  
* `-n` 禁用解析，这个选项通常要带上，否则会把 ip 地址解析成主机名，反而看不到什么有用的
* `-p` 显示进程信息，这个选项通常也要带上
* `-l` 只显示 listen 的信息，如果只能查看监听信息，就用这个


linux 例子：  

|命令|作用|
|:---|:---|
|`netstat -anp \| grep 80`|查看端口号为 80 的所有连接信息|
|`netstat -tnp \| grep 80`|查看端口号为 80 的 tcp 连接信息|
|`netstat -l`|查看所有的 listen|


netstat 在 windows 下也有相应的实现，不过命令参数与 linux 下略有不同，而且过滤结果也不能使用 grep，得使用 find。    

windows 例子：  

|命令|作用|
|:---|:---|
|`netstat -ano \| find "80"`|查看端口号为 80 的所有连接信息|
|`netstat -ano \| find "LISTEN"`|查看所有的 listen|


---

## 1.2 lsof

lsof 意为 list open files，可以显示被打开的文件以及打开这些文件的进程。unix 一切皆文件，socket 也是文件，所以通过显示文件信息，足以窥探系统的一些运行状态。  

如果足够熟练，lsof 可以替代 netstat 和 ps 这两个工具。   

### 1.2.1 lsof 基本要点

* 没有任何选项时，lsof 会列出所有活跃进程的所有打开文件。  

* 有多个选项，默认执行 “或” 运算，比如同时传递 -i (获取网络信息) -p (获取进程信息)，会获得两者的结果。    

* 使用 -a 可以对结果进行 “与” 运算。   

关于 “或” 和 “与”，举个例子，想要获得进程 pid 为 191812 的 tcp 连接信息，需要这样写：`lsof -p 191812 -i tcp -a`，不能只写成 `lsof -p 191812 -i tcp`。如果没加 '-a'，结果将变成进程 pid 为 191812 的所有打开文件以及所有 tcp 连接信息的总和。 


### 1.2.2 lsof 获取网络信息

先列举一些网络相关的用法，基础语法是：  

```bash
lsof -i [46][protocol][@hostname|hostaddr][:service|port]
```

要注意，这串东西 `[46][protocol][@hostname|hostaddr][:service|port]` 是根据需要填的，但要挨在一起，中间不要有空格。 比如 `4tcp:9999` 或者 `tcp@127.0.0.1` 或者 `4tcp@127.0.0.1:9999`。 


一些例子：  

|命令|作用|
|:---|:---|
|`lsof -i`|显示所有网络连接|
|`lsof -i 6`|仅显示 ipv6 连接|
|`lsof -i tcp`|仅显示所有 tcp 连接|
|`lsof -i udp`|仅显示所有 udp 连接|
|`lsof -i :9999`|显示端口为 9999 的连接|
|`lsof -i :1000,2000`|显示端口号为 1000 或 2000 的连接|
|`lsof -i :1000-9999`|显示端口范围从 1000 到 9999 的连接|
|`lsof -i 4tcp@127.0.0.1:9999`|显示ipv4，tcp协议，连接信息为 127.0.0.1 9999 的连接|
|`lsof -i -s tcp:established`|显示已经建立的 tcp 连接|
|`lsof -i -s tcp:listen`|显示等待连接 (listen) 的 tcp 端口|


### 1.2.3 lsof 文件和目录

查看正在使用指定文件和目录的用户或进程。  

`lsof 文件路径` 可以找出打开这个文件的资源信息，比如 `lsof /root/a.txt`。  

特别的，如果是用 vim 打开了文件，比如：root/a.txt，则通过 `lsof /root/.a.txt.swp` 可以找出来。通过 a.txt 是找不到的，因为 vim 打开的是一个 .swp 后缀的临时文件。  


### 1.2.4 lsof 命令、进程、用户

通过 `-c` 选项可以找出使用指定命令的进程，比如：`lsof -c 'sshd'` 找出命令为 sshd 的进程打开的所有文件。   

如果要配合其实工具使用，可以指定 `-t` 选项，只打印进程 id 出来。      

通过 `-p` 选项可以找出指定 pid 的进程，比如 `lsof -p 2341` 找出 pid 为 2341 的进程打开的所有文件。   

通过 `-u` 选项可以找出指定用户打开的文件，比如 `lsof -u root` 可以找出 root 用户打开的所有文件。  


### 1.2.5 lsof 各列的意义

各列的意义[2]，如下：  

```
COMMAND：进程的名称

PID：进程标识符

PPID：父进程标识符（需要指定-R参数）

USER：进程所有者

PGID：进程所属组

FD：文件描述符，应用程序通过文件描述符识别该文件。如 cwd、txt 等

TYPE：文件类型，如DIR、REG等，常见的文件类型

    REG ：常规文件，即普通文件
    DIR ：目录
    CHR ：字符类型
    BLK ：块设备类型
    UNIX：UNIX 域套接字
    FIFO：先进先出 (FIFO) 队列
    IPv4：网际协议 (IP) 套接字

DEVICE：指定磁盘的名称

SIZE：文件的大小

NODE：索引节点（文件在磁盘上的标识）

NAME：打开文件的确切名称
```

FD 的详细信息[2][3]，如下：  

```
数字：文件的描述符 id，其中有3个是特别的：0 表示标准输出，1 表示标准输入，2 表示标准错误
cwd ：current work dirctory，即应用程序的当前工作目录
txt ：program text (code and data)，即程序代码
lnn ：library references (AIX)
er  ：FD information error (see NAME column)
jld ：jail directory (FreeBSD)
ltx ：shared library text (code and data)
mxx ：hex memory-mapped type number xx
m86 ：DOS Merge mapped file
mem ：memory-mapped file
mmap：memory-mapped device
pd  ：parent directory
rtd ：root directory
tr  ：kernel trace file (OpenBSD)
v86 ：VP/ix mapped file


一般在标准输出、标准错误、标准输入后还跟着文件状态模式：r、w、u等，如下： 

u    ：表示该文件被打开并处于读取/写入模式
r    ：表示该文件被打开并处于只读模式
w    ：表示该文件被打开并处于
space：表示该文件的状态模式为unknow，且没有锁定
-    ：表示该文件的状态模式为unknow，且被锁定


同时在文件状态模式后面，还跟着相关的锁，如下：  

N    ：for a Solaris NFS lock of unknown type;
r    ：for read lock on part of the file;
R    ：for a read lock on the entire file;
w    ：for a write lock on part of the file;（文件的部分写锁）
W    ：for a write lock on the entire file;（整个文件的写锁）
u    ：for a read and write lock of any length;
U    ：for a lock of unknown type;
x    ：for an SCO OpenServer Xenix lock on part of the file;
X    ：for an SCO OpenServer Xenix lock on the entire file;
space：if there is no lock.

```


---

## 1.3 nc

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

# 2. 工具的数据来源

## 2.1 netstat、nstat、ifconfig、ethtool 

数据来源[1]:   

>netstat、nstat 是来自 /proc/net/netstat 和 /proc/net/snmp 的数据；   
>ifconfig 是读取 /proc/net/dev 下的数据，而后者的数据是从设备在内核的数据结构 net_device 里的结构 rtnl_link_stats64 中获取的；    
>ethtool 是直接通过 ioctl 下放的方式从同样的结构（net_device 中的 rtnl_link_stats64 ）中获取数据；    
>因此可以认为 ifconfig 和 ethtool 两者看到的网卡相关数据来源是一样的，但是 /proc/net/dev 进行了一定程度的归档，因此 ifconfig 中的 RX dropped = rx_dropped + rx_missed_errors，RX errors = rx_errors。    



---

# 3. 参考

[1] johnazhang. 关于以ethtool为主的网络指标统计工具之间统计数据关系的研究原创. Available at https://cloud.tencent.com/developer/article/2050526,  2022-07-18.   

[2] 琦彦. lsof：获取网络信息、用户操作、进程信息、文件信息. Available at https://blog.csdn.net/fly910905/article/details/88551497, 2019-03-14.  

[3] man7. lsof. Available at https://man7.org/linux/man-pages/man8/lsof.8.html.   