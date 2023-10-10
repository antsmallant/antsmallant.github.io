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

使用 evernote 已经好多年了，对它的持续可用性一直不放心，所以会定期对日志做备份。但最近我厌倦这么做了，于是打算试一下这两位老师提到的 obsidian，阮一峰：[最适合程序员的笔记软件](https://www.ruanyifeng.com/blog/2021/08/best-note-taking-software-for-programmers.html)，老C：[周刊（第18期）：网状的思考，线性的写作](https://www.codedump.info/post/20220612-weekly-18/) 。

<br>

记一下安装步骤：
1. 创建日志仓库，我分别在 github、gitee 创了私有仓库，取名为 obnote，多年的后端经验，始终考虑冗余备份：）。
2. iOS 同步，参照这个文章 [42号笔记：iOS上使用iSH的git同步Obsidian](https://zhuanlan.zhihu.com/p/565028534) 实现了 iOS 上的 git 同步。“iSH是一个模拟器，用来在ARM架构的iOS设备上模拟x86架构，让iOS设备在本地运行Linux Shell环境。”。
3. pc 同步，obsidian 安装这个插件: Obsidian Git，简单配置一下，就可以自动的完成 git 同步了。

<br>

然后我就开始日志迁移了，好在 evernote 上我一直用 markdown 格式写文章，所以手动迁移起来并不是特别费劲。需要自我吐槽的是，之前写日志太随便了，什么垃圾都往里面丢，这是极不好的。所以重新给自己立了规矩：1、要写有用的日志；2、格式要简洁有序；3、知识密度要高。

<br>

obsidian 的核心功能体验，可以参考这个：[玩转 Obsidian 01：打造知识循环利器](https://sspai.com/post/62414)。

<br>
<br>
<br>