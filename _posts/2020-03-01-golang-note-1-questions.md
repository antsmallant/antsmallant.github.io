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

# 1. 常识

---

## 1.1 数组

数组的长度是其类型的一部分，数组不能改变大小。  

基本格式是：`[n]type`，如 `var x = [6]int`。  

---

## 1.2 切片

切片就像数组的引用，切片并不存储任何数据，它只是描述了底层数组中的一段。    

基本形式：`[]type`。  

---

# 2. 术语

---

## 2.1 短变量声明

`:=` 是短变量声明。  

---

## 2.2 隐式解引用

`指针.字段名` 就是【隐式解引用】，正规的写法应该是 `(*指针).字段名`。    

---

# 3. 用法

---

## 3.1 命令行转圈等待

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

---

# 4. 参考