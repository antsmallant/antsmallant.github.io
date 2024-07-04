---
layout: post
title: "golang 笔记一：常识、术语、用法"
date: 2021-04-15
last_modified_at: 2021-04-15
categories: [golang]
tags: [golang]
---

* 目录  
{:toc}
<br/>

---

# 常识

---

# 术语

---

## 短变量声明

`:=` 是短变量声明。  

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
