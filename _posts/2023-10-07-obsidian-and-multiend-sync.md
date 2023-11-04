---
layout: post
title:  "obsidian及多端同步小记"
date:   2023-10-07
last_modified_at: 2023-10-07
categories: [tools]
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
### 创建日志仓库   
在 github 或 gitee 创建私有仓库，比如命名为 obnote。

<br>

### iOS 同步   
* 参照这个文章 [42号笔记：iOS上使用iSH的git同步Obsidian](https://zhuanlan.zhihu.com/p/565028534)
* 下载一个叫 iSH 的 APP
* 运行 iSH，执行命令安装需要的软件

    ```
    apk update
    apk add git
    apk add vim
    apk add openssh
    apk add openrc
    ```

* 打开 obsidian，创建一个新的仓库，比如命名为 obnote
* 打开 iSH，创建一个新的目录并执行 mount
    - 命令

        ```
        cd ~ && mkdir obs
        mount -t ios-unsafe . obs
        ```

    - mount 执行时，iOS 会以交互式的方式让你选择要 mount 具体哪个 APP 的目录，选择 obsidian
    - 特别注意，这里要使用 `ios-unsafe` 参数来 mount，参考教程使用的 `ios` 参数会导致使用 git 的过程中经常卡死，比如这样：[Git Commands Stuck Forever #1640](https://github.com/ish-app/ish/issues/1640)
* 之后就是正常的在上面 mount 的目录下 git 操作

<br>

### PC 同步   
obsidian 安装这个插件: Obsidian Git，简单配置一下，就可以自动的完成 git 同步了。

<br>
<br>

<br>
<br>
<br>