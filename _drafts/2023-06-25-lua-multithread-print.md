---
layout: post
title:  "lua 多线程环境下可以使用 print 吗？"
date:   2023-06-25
last_modified_at: 2023-06-25
categories: [lua]
---

# 原由
新公司的框架（基于 skynet) 没有使用正经的 log 库，到处都使用 print，那么在多线程环境下使用 print 安全吗？会有什么副作用？如果有副作用，那有什么办法可以比较无痛的解决？
