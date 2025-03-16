---
layout: post
title: "c++ 工具：gdb 调试 c++"
date: 2025-03-16
last_modified_at: 2025-03-16
categories: [c++]
tags: [c++]
---

* 目录  
{:toc}
<br/>

之所以需要记录，是因为有些程序会使用 daemon 或 fork，这时候 gdb 可能没法 debug 到 fork 出来的子程序，需要做一点额外的工作。  

