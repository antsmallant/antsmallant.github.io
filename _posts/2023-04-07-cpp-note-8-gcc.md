---
layout: post
title: "c++ 笔记八：gcc 与 g++"
date: 2023-04-07
last_modified_at: 2024-07-01
categories: [c++]
tags: [c++ cpp gcc g++]
---

* 目录  
{:toc}
<br/>

本文记录 gcc 与 g++ 的相关信息。  

---

# 1. gcc

---

# 2. g++

---

## 2.1 g++ 查看当前支持的 c++ 版本信息

```bash
g++ -dM -E -x c++ /dev/null | grep -F __cplusplus
```

---

# 3. 参考