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

language specification: [https://go.dev/ref/spec](https://go.dev/ref/spec)     

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

## 2.4 接口值

接口值可以看做包含值和具体类型的元组 (value, type)，它保存了一个具体类型的具体值，接口值调用方法时，也会执行其底层类型的同名方法。  

---

## 2.5 nil 接口值与底层值为 nil 的接口是不同的

假设有这样定义的接口和结构体：  

```go
type I interface {
    M()
}
type T struct {
    S string
}
```

1、nil 接口值是指这个接口值既无具体值，也无类型。比如底下的 i 就是一个 nil 接口值：   
```go
var i I
```

2、底层值为 nil 的接口是的指无具体值，但有类型。比如底下的 i 就是一个无具体值的接口，此时 i 的底层值是 nil，但底层类型是 T：   
```go
var i I
var t T
i = t
```

---

## 2.6 空接口

空接口可以保存任何类型的值，这样就可以声明一个空接口类型的变量了： `var i interface{}`，不需要特意用 `type` 写这个的别名。   

---

## 2.7 fmt print 的基本格式

参照： [https://pkg.go.dev/fmt@go1.22.5#hdr-Printing](https://pkg.go.dev/fmt@go1.22.5#hdr-Printing)   

General:
```
%v	the value in a default format
	when printing structs, the plus flag (%+v) adds field names
%#v	a Go-syntax representation of the value
%T	a Go-syntax representation of the type of the value
%%	a literal percent sign; consumes no value
```

The default format for %v is:
```
bool:                    %t
int, int8 etc.:          %d
uint, uint8 etc.:        %d, %#x if printed with %#v
float32, complex64, etc: %g
string:                  %s
chan:                    %p
pointer:                 %p
```

---

## 2.8 基本类型 

```
bool

string

int  int8  int16  int32  int64
uint uint8 uint16 uint32 uint64 uintptr

byte // alias for uint8

rune // alias for int32
     // represents a Unicode code point

float32 float64

complex64 complex128
```

# 3. 术语

---

## 3.1 短变量声明

`:=` 是短变量声明。  

1、只能在函数内使用。  

2、使用时，左侧必须至少有一个未声明过的变量，比如：  

```go
f := 3.14
f, yy := 4.0, true // ok，左侧的 yy 是未声明过的
f := 5.0           // not ok，左侧只有一个 f，且 f 已经声明过了
```

---

## 3.2 隐式解引用

`指针.字段名` 就是【隐式解引用】，正规的写法应该是 `(*指针).字段名`。    

---

## 3.3 方法与函数

1、方法是一类带特殊的 **接收者** 参数的函数。所以，方法是函数的一种。    

2、可以将 struct 作为接收者，也可以将类型别名作为接收者，比如 `type MyFloat float64`，这里的 `MyFloat` 就可以作为接收者。  

3、只能为同一个包中定义的接收者类型声明方法，不能为其他别的包中定义的类型声明方法。  

所以不能直接为 `float64` 声明方法，因为它不在当前这个包里。只能通过定义别名的方式来实现这样的效果。   

4、方法与指针重定向
类似于隐式解引用，当方法的接收者是指针，使用 `值.方法名` 时，go 会自动的解释为 `(&值).方法名`。   

反过来也一样，当方法的接收者是值，使用 `指针.方法名` 时，go 会自动解释为 `(*指针).方法名`。  

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

[1] go.dev. Type declarations. Available at https://go.dev/ref/spec#Type_declarations.     