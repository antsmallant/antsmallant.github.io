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

记录 golang 相关的常识，以及学习过程中遇到的问题，**持续更新**。    

---

# 1. 资料

---

## 1.1 官方资料

官网：[https://go.dev/](https://go.dev/)     

官方文档合集：[https://go.dev/doc/](https://go.dev/doc/)      

language specification: [https://go.dev/doc/](https://go.dev/doc/)     

library 文档: [https://pkg.go.dev/std](https://pkg.go.dev/std)    

a tour of go: [https://go.dev/tour/welcome/1](https://go.dev/tour/welcome/1)    

go by example: [https://gobyexample.com/](https://gobyexample.com/)    
 

---

# 2. 常识

---

## 2.1 数组

1、数组的长度是其类型的一部分，数组不能改变大小。    

2、基本格式是：`[n]type`，如 `var x = [6]int`。  

---

## 2.2 切片

参考： [Go Slices: usage and internals](https://go.dev/blog/slices-intro)   

1、切片就像数组的引用，它并不实际存储数据，它只是描述了底层数组的一段。   

2、更改切片的元素会修改其底层数组中对应的元素，和它共享此数组的其他切片也会观测到这些修改。  

3、基本形式：`[]type` 。  

4、切片字面量    
`s := []int{1,2,3,4}` 这样做的本质是，先创建了一个数组:`[4]int{1,2,3,4}`，再创建一个引用此数组的切片。   

5、容量缩小之后，重新切片的时候，长度不得超过此容量，有点像一个滑动窗口。       

6、nil 切片的长度和容量都为 0。  

7、切片的边界，下界的默认值是 0，上界的默认值是该切片的**长度**

要重点记住，是**长度**，而不是容量，在二次切片时，最好显式的给出上边界，避免出错，比如这样：    

```go
a := make([]int, 0, 5)
b := a[:2] // 此时 b 的长度是 2，容量是 5
c := b[3:] // not ok，会报错，相当于 c := b[3:2] 
c := b[3:cap(b)] // ok，相当于 c := b[3:5]
```

---

## 2.3 type 关键字

来自官方的定义："A type declaration binds an identifier, the type name, to a type. Type declarations come in two forms: alias declarations and type definitions." [1]    

翻译过来是：将一个类型名绑定到一个类型上，有两种形式，别名声明和类型定义。   

<br/>

**例子1：别名声明**   

`type MyFloat float64`，这里面 `MyFloat` 作为 `float64` 的别名。   
   
<br/>

**例子2：类型定义**    

`type Vertex struct { X, Y float }`， 这里面 `struct { X, Y float }` 定义了一种结构体，而 `type Vertex` 则用 `Vertex` 这个别名来指代它。    

实际上，类型名不是必须的，譬如可以这样定义一个 struct 切片。  

```go
	v := []struct{ X, Y float64 }{
		{2.1, 2.2},
		{3.1, 3.2},
	}
```

---

# 3. 术语

---

## 3.1 短变量声明

`:=` 是短变量声明。  

---

## 3.2 隐式解引用

`指针.字段名` 就是【隐式解引用】，正规的写法应该是 `(*指针).字段名`。    

---

## 3.3 方法与函数

方法是一类带特殊的 **接收者** 参数的函数。所以，方法是函数的一种。   

只能为同一个包中定义的接收者类型声明方法，不能为其他别的包中定义的类型声明方法。  

---

# 4. 用法

---

## 4.1 命令行转圈等待

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

# 5. 参考

[1] go.dev. Type declarations. Available ab https://go.dev/ref/spec#Type_declarations.     