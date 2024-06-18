
# 1. 前言

bigworld 已经开源了它的代码，而我对于大世界的 scale 很感兴趣，所以就尝试把代码跑起来研究。但是，整个过程比我原先预想的复杂得多。   

虽然能找到一些官方的帮助文档，但这些文档要么过旧，要么过于详尽，并且写的大多是一些自动化的操作，依赖的工具链很多，所以对于手动搭建没啥帮助，反而带来了不少困惑。  

而网上，搜索不到其他人写的关于 bigworld 搭建的文章，所以只能结合官方文档一步步试探。整个安装过程，最 easy 的 part 是安装环境&编译，最烦的 part 是把 server 和 client 运行起来。    

本（水）文只包含以下粗浅的内容：    
1、编译 server & client。   
2、运行 server & client，把 fantasydemo 跑起来。    

fantasydemo 是官方自带的一个 demo，包含了 server 跟 client，算是一个可以运行的 mmo 游戏吧。   

国内的公司像网易，巨人等，都有引进过 bigworld，应该很熟悉 bigworld 整套框架的搭建，所以相关厉害人士完全可以不用看本（水）文。        

---

# 2. bigworld 源码下载

有几个版本，最新的是 14.4.1，更早的有 2.0.1，1.9.1。  

本文是基于 bigworld-14.4.1 搭建的，而文档是参考 bigworld-2.0.1 的，因为 14.4.1 里面几乎没啥文档。     

## 2.1 bigworld-14.4.1 
完整版（源码+资源）：  https://sourceforge.net/p/bigworld/code/HEAD/tree/  或者 https://drive.google.com/file/d/1hLm_Ox0v-xIen8c4MvwRHQhkutf9bIpK/view?usp=share_link    

源码版： https://github.com/v2v3v4/BigWorld-Engine-14.4.1   


## 2.2 bigworld-2.0.1 
完整版（源码+资源）： https://drive.google.com/file/d/1b1ZGpVFE2hMoDNC-mGQ4ldwgF8PWH3n7/view?usp=share_link   

源码版： https://github.com/v2v3v4/BigWorld-Engine-2.0.1


## 2.3 bigworld-1.9.1
源码版： https://github.com/v2v3v4/BigWorld-Engine-1.9.1


---

# 3. wsl2 编译 server 

## 3.1 wsl2 安装 centos7

官方的文档里说，bigworld 支持的操作系统是 redhat，centos，fedora，而我熟悉 centos，所以用 centos7，并且我也熟悉 wsl，所以用 wsl2。反正，用自己熟悉的方式即可。     

仓库所在地址： https://github.com/mishamosher/CentOS-WSL        

1、下载       
一个发行版，比如 centos7：  https://github.com/mishamosher/CentOS-WSL/releases/tag/7.9-2211      

2、安装      
解压后双击 CentOS7.exe       

3、运行      
双击 CentOS7.exe 启动即可，后续这个 CentOS7 也会出现在 WindowsTerminal 里面，可以直接运行。   

---

## 3.2 centos7 创建一个用户

1、创建用户      
```bash
useradd -m -d /home/ant -G adm -s /bin/bash ant
```     

2、创建密码     
```bash
passwd ant
```      

3、修改 sudoer    
1）如果当前不是 root 用户，su 到 root 用户      
2）运行 `visudo` 命令，进入编辑界面     
3）在 `root    ALL=(ALL)       ALL` 的下面加一行 `ant  ALL=(ALL)  ALL`     
4）保存退出   

---

## 3.3 wsl2 修改 centos7 的默认用户    

为什么？如果没修改，每次进入 centos7 都是 root 用户。      

1、以管理员身份运行 windows power shell  ，cd 到解压出来的 CentOS7.exe 的所在目录，执行命令    

```
CentOS7.exe config --default-user ant
```    

---

## 3.4 centos7 安装依赖的软件

1、以 root 用户运行，或用 sudo 运行     

```bash
yum install epel-release
yum install git
yum install vim
yum install make
yum install gcc
yum install gcc-c++
yum install patch
yum install python-pip
yum install wget
yum install unzip
yum install bzip2
yum install MySQL-python
yum install python-setuptools
yum install python-sqlobject
yum install TurboGears
yum install rpm-build
```

2、说明    
1）EPEL (Extra Packages for Enterprise Linux) 是基于 Fedora 的一个项目，为“红帽系”的操作系统提供额外的软件包，适用于 RHEL、CentOS 和 Scientific Linux。    

---

## 3.5 centos7 安装 scons

下面在编译 mongo_cxx_driver 的时候会用到 scons，需要提前安装，这个有好几种安装方法，但在 CentOS7 没法使用 python 的 pip 安装，只能从源码安装。   

1、scons 官网： https://scons.org/pages/download.html          
 
2、下载 scons-2.5.1.tar.gz，地址： https://sourceforge.net/projects/scons/files/scons/2.5.1/           

3、解压后，进入 scons-2.5.1 目录，执行 `sudo python setup.py install`     

---

## 3.6 手动编译一些需要的库

1、安装 boost  

1）进入 `programming\bigworld\third_party\mongodb\boost`   
2）根据 README.BigWorld 编译 boost

2、安装 mongo_cxx_client   

1）进入 `programming\bigworld\third_party\mongodb\mongo_cxx_driver`    
2）根据 README.BigWorld 编译 mongo_cxx_driver     

3、出错处理
1） 使用 scons 编译&链接 mongo_cxx_driver 会总是报错，虽然已经正确指定了 boost 的 cpppath 和 libpath。一个 trick 就是根据报错，自己手动去拷贝文件到它的编译命令报错的目录。编译时报错就看看 -I 是指定哪些目录的，把 boost 拷贝过去。链接时报错就看看 -L 是指定哪些目录的，把 boost 的 lib 拷贝过去。  

---

## 3.7 编译 server

1、进入 `programming/bigworld`，执行 `make` 。             

2、报错解决           
1）比如一开始 platform_info.py 的报错，是因为它没执行权限，则 `chmod 755 platform_info.py` 即可，后续还会有其他的 bash 文件执行失败，也是 chmod 即可。    


---

# 4. windows 编译 client

## 4.1 安装 visual studio 2019 或其他版本（可选）

**可以等下面 cmake 生成 sln 的时候再判断是否需要安装 vs。**     

我本机安装了很多个 vs，有 vs2010，vs2013，vs2015，vs2017，vs2019，vs2022，但下面运行 `bigworld_cmake.bat` 的时候，只给了两个选项： vs2019 和 vs2022，所以我也不确定具体需要先安装哪个。    

---

## 4.2 编译 client  
 
1、生成 vs 的 sln 文件      

进入 `programming\bigworld\build`，运行 `bigworld_cmake.bat`，选择 3，再选择相应的 visual studio （比如我选了 visual studio 2019）。         

生成成功会显示 sln 生成到了什么目录，比如我是生成到 `programming\build_client_vc16_win32`。         

2、运行 vs 编译     

用 vs （比如我是 vs 2019）打开上面生成的 sln 文件，选择 Consumer_Release 进行生成，（这里就不使用 Debug 版本了）。   

编译成功后，文件会生成到 `game\bin\client\win32` 目录。   

3、报错解决       
1）提示 ”无法找到 v141_xp 的生成工具“，则打开 visual studio installer，安装这个组件 ”对 C++的 Windows XP 支持“      
2）提示找不到 atl 开头的头文件，则 visual studio installer 安装 atl    
3）提示找不到 afx 开头的头文件，则 visual studio installer 安装 mfc     

---

# 5. wsl 安装&运行 server

## 5.1 安装 mysql  并创建 bigworld 数据库&账号

1、安装 mysql

我是使用 docker compose 的，因为自己很熟悉，所以比较快。唯一的问题就是最近（2024-6-15 号之后） docker 官方 hub pull 不动了，得找国内的 hub，比较折腾。   

反正用自己熟悉的方式即可。   

2、创建数据库&账号   

```
CREATE DATABASE IF NOT EXISTS bigworld DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_general_ci;


create user 'bigworld'@'localhost' identified by 'bigworld';
grant all privileges on *.* to 'bigworld'@'localhost';
create user 'bigworld'@'%' identified by 'bigworld';
grant all privileges on *.* to 'bigworld'@'%';
flush privileges;

```

---

## 5.2 修改 res 目录的数据库配置     

1、打开文件 `game\res\bigworld\server\production_defaults.xml`，搜索到 mysql，
配置相关信息，比如我配置完是这样的：    

```
...
		<mysql>
			<host> 127.0.0.1 </host> <!-- Type: String -->
			<port> 3306 </port> <!-- Type: Integer -->
			<databaseName> bigworld </databaseName> <!-- Type: String -->
			<username> bigworld </username> <!-- Type: String -->
			<password> bigworld </password> <!-- Type: String -->
			...
		</mysql>
...
```

2、说明      
1）有个特别注意一下，在 wsl2 里面用 docker 跑 mysql，使用 localhost 是连不上 mysql 的，要用 127.0.0.1 。       

---

## 5.3 安装 bwmachined

1、把编译出来的 bwmachined2 拷贝到正确位置 
（以下都用的我机器上的绝对路径，具体视自己的情况而定）

```bash
cp /home/ant/bigworld/game/bin/server/el7/tools/bwmachined2 /home/ant/bigworld/game/tools/bigworld/server/bin/Hybrid64
```

2、安装

```bash
cd /home/ant/bigworld/game/tools/bigworld/server/install
sudo ./bwmachined2.sh install
```

3、运行或查看状态

```bash
sudo service bwmachined2 start
sudo service bwmachined2 status
```

4、平常如果没有开机自己运行，就自己运行

```bash
sudo service bwmachined2 start
```

---

## 5.4 创建 ~/.bwmachined.conf 文件

1、在当前用户的 home 目录 (~/) 下创建一个名为 .bwmachined.conf 的文本文件，要注意，文件名是以 . 号开头，内容如下： 

```
/home/ant/mf/bigworld;/home/ant/bigworld2014/game/res/bigworld:/home/ant/bigworld2014/game/res/fantasydemo

[Components]
cellApp
baseApp
serviceApp
dbApp
cellAppMgr
baseAppMgr
dbAppMgr
loginApp
bots

[Groups]
dev

[TimingMethod]
gettime

#[architecture]
#32

#[InternalInterface]
#eth0

#[MaxPacketDelay]
#100
```

2、说明     

1）在官方的 install 文档里会说使用 bw_configure 脚本来创建这个文件，但会各种报错，根本搞不了，还不如手动创建。   

2）此文件有个范本在此 `game\tools\bigworld\server\rpm\bwmachined\bwmachined.conf`，里面有注释说明，具体可参考。      

3）要点            
文件的第一行分两部分，第一部分是 bigworld 的 server 可执行文件的目录，第二部分是 res 目录。  
第一、二部分之间使用 ; 号隔开。  
第二部分的 res 之间使用 : 号 隔开。        

第一部分的目录有这样的存放要求，比如我这是这样的：     
```
~/mf/bigworld/bin/server
```

server 目录就放编译出来的服务器二进制文件，baseapp, cellapp, baseappmgr ...  这些   

4）install 文档会有一点误导性，它里面说 `.bwmachined.conf` 的第一行是 `UID;MF_ROOT;MF_RES`，实践证明，并不是的，参照上面说的搞即可。     

---

## 5.5 运行 server

（说明：server 的运行不需要什么参数，它是读取 ~/.bwmachined.conf 文件去加载相应的东西的）

1、进入 server 的目录 `game/bin/server/el7/server`

2、现写两个脚本负责启动和关闭 server

start-all-server.sh

```bash
#!/bin/bash

nohup ./baseapp > baseapp.log 2>&1 &
nohup ./baseappmgr > baseappmgr.log 2>&1 &
nohup ./cellapp > cellapp.log 2>&1 &
nohup ./cellappmgr > cellappmgr.log 2>&1 &
nohup ./dbapp > dbapp.log 2>&1 &
nohup ./dbappmgr > dbappmgr.log 2>&1 &
nohup ./loginapp > loginapp.log 2>&1 &
nohup ./serviceapp > serviceapp.log 2>&1 &
```

stop-all-server.sh

```bash
#!/bin/bash

pkill baseapp
pkill baseappmgr
pkill dbapp
pkill dbappmgr
pkill cellapp
pkill cellappmgr
pkill loginapp
pkill -9 serviceapp
```

3、运行 start-all-server.sh 启动服务器

---

# 6. windows 运行 client

## 6.1 修改 fantasydemo 的连接地址

1、client 修改 `game\res\fantasydemo\scripts_config.xml`，搜索到 `<login>`，把其中的 host 改为 loginapp 的地址和端口，我的是 wsl 地址是 172.22.36.110，而 loginapp 的默认登录端口是 20013。  

所以，我的改完是这样：   

```
...
	<login>
	<!-- This login data is used by the scripts to connect to the server. -->

		<host> 172.22.36.110:20013 </host>
...
```

---

## 6.2 创建一个运行 client 的脚本

1、在 `game` 目录创建一个名为 `run-client.bat` 的脚本，脚本内容如下：     

```
@ECHO OFF

start bin\client\win32\bwclient.exe --res %~dp0\res\fantasydemo;%~dp0\res\bigworld
```

2、说明    
1）关键之处在于 `--res` 参数，要先指定 fantasydemo，再指定 bigworld 。     

2）上面 `%~dp0` 表示当前目录，用的是相对路径，也可以改成绝对路径。比如这样：     

```
@ECHO OFF

start bin\client\win32\bwclient.exe --res D:\code\game-src\bigworld\bigworld2014-git-repo\game\res\fantasydemo;D:\code\game-src\bigworld\bigworld2014-git-repo\game\res\bigworld
```

---

## 6.3 运行 client

1、执行上面的 run-client.bat 就跑起来了

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-fantasydemo-pic1.png"/>
</div>
<br/>

2、选择 "Connect to Standard Server"，就看到之前配置的自己的服务器地址了

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-fantasydemo-pic2.png"/>
</div>
<br/>

3、创建游戏账号

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-fantasydemo-pic3.png"/>
</div>
<br/>

4、选择一个区

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-fantasydemo-pic4.png"/>
</div>
<br/>

5、创建区账号

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-fantasydemo-pic5.png"/>
</div>
<br/>

6、进入游戏

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/bigworld-fantasydemo-pic6.png"/>
</div>
<br/>

---

正文完。  