---
layout: post
title: "golang 笔记一：常识、术语、用法"
date: 2020-03-01
last_modified_at: 2020-03-01
categories: [golang]
tags: [golang]
---

* 目录  
{:toc}
<br/>

记录一些平常学习到的常识问题，**持续更新**。  

---

# 常识

---

# 术语

---

## 短变量声明

`:=` 是短变量声明。  

---

## 隐式解引用

`指针.字段名` 就是【隐式解引用】，正规的写法应该是 `*指针.字段名`。    

---

# 用法

---

## 命令行转圈等待

```go
package main
import (
	"fmt"
	"time"
)
func spinner(delay time.Duration) {
	for {
		for _, r := range `-\|/` {
			fmt.Printf("\r%c", r)
			time.Sleep(delay)
		}
	}
}
func main() {
	go spinner(100 * time.Millisecond)
	// do some other things
}

```
