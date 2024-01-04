---
layout: post
title:  "obsidian使用以及git多终端同步"
date:   2023-10-07
last_modified_at: 2023-10-07
categories: [工具]
tags: [tools]
---

* 目录  
{:toc}

<br>
<br>
<br>

## why
使用 evernote 已经好多年了，对它的持续可用性一直不放心，所以会定期对日志做备份。但最近我厌倦这么做了，于是打算试一下这两位老师提到的 obsidian，阮一峰：[最适合程序员的笔记软件](https://www.ruanyifeng.com/blog/2021/08/best-note-taking-software-for-programmers.html)，老C：[周刊（第18期）：网状的思考，线性的写作](https://www.codedump.info/post/20220612-weekly-18/)。

<br>
<br>

## 关于 obsidian
obsidian 的核心功能体验，可以参考这个：[玩转 Obsidian 01：打造知识循环利器](https://sspai.com/post/62414)。

<br>
<br>

## 安装步骤
#### 创建日志仓库   
在 github 或 gitee 创建私有仓库，比如命名为 obnote。

<br>

#### PC 同步
obsidian 安装这个插件: Obsidian Git，简单配置一下，就可以自动的进行 git 同步了。

<br>

#### iOS 同步   
* 参照这个文章 [42号笔记：iOS上使用iSH的git同步Obsidian](https://zhuanlan.zhihu.com/p/565028534)
* 下载一个名为 iSH 的 APP，运行之，执行以下命令安装需要的软件

    ```
    apk update
    apk add git
    apk add vim
    apk add openssh
    apk add openrc
    ```

* 打开 iSH，创建一个新的目录并执行 mount，执行时 iOS 会以交互的方式让你选择目录，选到 obsidian 这一级即可，脚本如下：
    ```
    cd ~ && mkdir obs
    mount -t ios-unsafe . obs
    ```

* 进入 iSH，git clone 日志仓库
    ```
    cd ~/obs
    git clone git@github.com:xxx/obnote.git
    ```

* 打开 obisidian，选择打开 obnote 这个日志库

<br>

#### 解决 iOS 上 iSH 执行 git 命令经常卡住的问题
这是一个普遍存在的问题。这个 issue：[Git Commands Stuck Forever #1640](https://github.com/ish-app/ish/issues/1640) 提到 mount 时使用 `ios-unsafe` 参数可以解决，实际使用之后，还是经常会卡住。   
后来，我在这个 issue [rsyncing into mount point from fileprovider doesn't quite work after iSH restart](https://github.com/ish-app/ish/issues/1581) 中找到一个终极解决办法：即每次 git 操作前都重新 mount。   
于是直接写了个小脚本放在 iSH 上，脚本里包含 mount + git pull 的逻辑，每次运行它就行。   

```
cd ~ && mount -t ios-unsafe . obs    
cd obs/obnote && git pull --rebase
git add . && git commit -m "sync" && git push
```

<br>

<br>
<br>
<br>