---
layout: post
title: "c++ 笔记：常识"
date: 2013-02-15
last_modified_at: 2023-04-01
categories: [c++]
tags: [c++ cpp]
---

* 目录  
{:toc}
<br/>

**持续更新**   

记录 c++ 相关的常识，以及使用过程中遇到的问题。    

---

# 1. 常识

---

## 1.1 为什么需要引入 nullptr？

`nullptr` 是 c++11 引入的，用于代替 NULL，它也是有类型的，是 `std::nullptr_t`。  

在此之前，c++ 用 NULL 表示空值，但它实际上就是 0 。那么有些场合分不清楚是想传 空值 还是 数字0。   

比如这样：   

```cpp
void f(int* i) {}
void f(int i) {}

f(NULL);      // 编译报错，有歧义，不确定要调用哪个版本的 f
f(nullptr);   // ok
```

---

## 1.2 什么情况下编译器会对参数进行隐式类型转换以保证函数调用成功？   

编译器进行隐式类型转换，即是要生成一个临时对象，有两个前提：    

1、实参是可以隐式转换成目标类型的；   
2、参数是通过 by const reference 或 by value 的方式传递的；    

归结起来就是，函数调用时，编译器会为 by const reference 或 by value 这两种形式生成临时变量，但不会为 by reference 生成临时变量。     

比如 

```cpp
void f1(string s) {}
void f2(const string& s) {}
void f3(string& s) {}

int main() {
    const char* str = "hello, world";
    f1(str);  // ok
    f2(str);  // ok
    f3(str);  // not ok, compile error occurs
    return 0;
}
```

---

## 1.3 当实参是一个临时对象时，by value 方式传参的情况下，还会产生新的临时对象吗？ 

比如这样： 

```cpp
struct S {
    int a;
    S() { std::cout << "S 构造" << std::endl; }
    S(const S& other) { std::cout << "S 拷贝构造" << std::endl; this->a = other.a; }
    ~S() { std::cout << "S 析构" << std::endl; }
};

void f(S s) {(void)s;}

int main() {
    f(S());  // 这里会使用构造函数生成一个 S 对象，再通过拷贝构造生成另一个临时对象吗？
    return 0;
}
```

不会的，当实参本身就是临时对象时，不需要再生成临时对象。只有这样才需要：  

```cpp
S s;     // 构造一次，得到 s
f(s);    // 拷贝构造一次，得到临时对象
```

---

## 1.4 为什么 c++11 之后，`char* s = "hello, world";` 编译时会有 warning ？  

因为在 c++11 中，string literal 即这里的 "hello, world" 是 const char 数组类型的，不允许把 const char 数组转换成 char* 类型。   

要避免 warning，需要这样使用，`const char* = "hello, world";`。  

---

## 1.5 一个空类占用的空间是多少？ 

一个不继承自其他类的纯净的空类，占用的空间大小是 1 字节。  

这样做的目的是使得任何变量都有一个唯一的地址，假设占用 0 字节，这个空类就不会有一个唯一地址了。   


---

## 1.6 c++ 比较两个结构体，可以使用 `memcmp(void*, void*)` 吗？  

不可以，memcmp 是逐字节比较的，而 struct 存在字节对齐，字节对齐时，补的字节内容是垃圾，不能比较。   

---

## 1.7 数据对齐的意义是什么？如何做到数据对齐？    

国内的叫法：内存对齐、字节对齐，但准确的说应该是数据结构对齐（Data structure alignment），在 wikipedia [3] 上只有 Data structure alignment 的词条，并没有 memory alignment 或 byte alignment。 

在《深入理解计算机系统》里是写作 data alignment，译为数据对齐[4]。  

1、对齐的意义   

可以提高内存系统的性能。假设一个处理器总是从内存中取 8 个字节，对于一个 8 字节的 double 类型，如果它的存储地址是 8 的倍数，那么一次内存操作就可以把它取出来了，否则就需要 2 次，并且还需要对内存数据进行裁剪、拼凑，才能得到想要的这个数据。   

无论是否对齐，x86-64 硬件都能正常工作，但 intel 的建议是尽量对齐以提高内存系统的性能。[4]    

<br/>

2、c++ 对齐的原则    

对齐的基本原则是任何 K 字节的对象的起始地址必须是 K 的倍数。[4]   

在 c++ 中，各类型的对齐原则如下：  

|K|类型|
|:--|:--|
|1|char|
|2|short|
|4|int,float|
|8|long,double,char*|


在 struct 或 class 中，对齐原则可归纳为：  

* struct 内部成员的 offset 必须为 min(成员size, 对齐系数) 的整数倍
* struct 总体大小必须为 min(最宽成员size, 对齐系数) 的整数倍
* struct 自身的 offset 必须为 min(最宽成员size, 对齐系数) 的整数倍

<br/>

3、设置对齐系数   

在 gcc 中可以使用 `#pragma pack(n)` 设置对齐系数，比如设置为 4，`#pragma pack(4)`。   

<br/>

4、获取类型的对齐值    

c 可以使用 `_Alignof`，c++ 可以使用 `alignof`。  

比如这样：  

```cpp
#include <iostream>

struct A {
    char c;
    int a;
    double X;
};

int main() {
    std::cout << sizeof(A) << std::endl;
    std::cout << alignof(A) << std::endl;
    return 0;
}
```

<br/>

5、拓展阅读

[《C/C++内存对齐详解》](https://zhuanlan.zhihu.com/p/30007037)    

---

## 1.8 什么是运行时多态？是怎么实现的？  

c++ 的运行时多态是使用虚函数表实现的，有一篇文章总结得不错：[《C++中虚函数、虚继承内存模型》](https://zhuanlan.zhihu.com/p/41309205) [2]。   

---

## 1.9 什么是编译时多态？  

参考自：[《编译期多态》](https://xie.infoq.cn/article/829d74dcd8d19aa613f8da059) [1]。   

编译时多态又称静态多态或类型安全多态，是指在编译期就可以确定函数的实际类型的多态。  

实现手段包括函数重载和函数模板：  

* 函数重载，是指同一作用域中，函数名相同，但参数列表不同的函数，编译时可以根据传入的参数类型确定要调用哪个函数。  

* 函数模板，是一种特殊函数，可以接受一个或多个模板参数作为函数的参数，编译时会将类型参数替换为实际类型。     

---

## 1.10 auto 对于运行速度有影响吗？ 

不会有影响，auto 是编译时推导的。auto 依赖于值的类型进行类型推导，所以使用 auto 声明时必须同时进行初始化。  

---

## 1.11 std::vector 的扩容和缩容策略各是什么？  

1、扩容策略    

空间不够时，vector 会主动扩容。  

gcc 是按 2 倍的容量扩容，据说 vs 是按 1.5 倍的。  
另外，gcc 的 resize 也是按 2 倍的策略扩容的，网上有文章说是按需扩容，但实测并不是，仍然是按 2 倍的策略扩的。  


2、缩容策略    

vector 不会主动缩容，需要使用某些技巧来释放。  

一个技巧是创建一个匿名 vector 对象来承接现有的数据，然后再 swap。这样的好处是：  
1）匿名对象只会根据现有数据的 size 分配内存；   
2）swap 是交换存储，代价小；  
3）匿名对象在这一句执行完后就析构了；      

示例如下：  

```cpp
// vector_shrink.cpp
#include <iostream>
#include <vector>

int main() {
    std::vector<int> a(100, 1);
    printf("before, size:%ld, cap:%ld\n", a.size(), a.capacity());
    
    a.resize(5);
    printf("after resize, size:%ld, cap:%ld\n", a.size(), a.capacity());
    
    std::vector<int>(a).swap(a);
    printf("after shrink, size:%ld, cap:%ld\n", a.size(), a.capacity());
    return 0;
}
```

---

## 1.12 声明 (declaration) 与定义 (definition)

以下引用（或参考）自《C++ Primer 中文版（第 5 版）》[6]。  

为了支持分离式编译(separate compilation)，c++ 需要把声明(declaration)与定义(definition)分开。一个程序若想使用在别处定义的名字，则必须包含对那个名字的声明。而定义则负责创建与名字关联的实体。  

### 变量的声明和定义

变量声明和定义都规定了变量的类型和名字，除此之外，定义还申请存储空间，也可能会为变量赋一个初始值。   

如果想要声明变量而非定义它，就在变量名前添加关键字 extern，而且不要显式地初始化变量，任何显式初始化的声明即成为定义。  

示例：  

```cpp
extern int i;      // 声明 i
int j;             // 定义 j
int k = 1;         // 定义 k 并赋初始值 1

extern int m = 10; // 定义 m 并赋初始值 10，给 extern 标记的变量赋初始值是 ok 的，但会抵消 extern 的作用，
                   // 并且，在函数体内这么做会报错
```

如果要在多个文件中使用同一个变量，就必须将声明和定义分离，变量的定义必须且只能出现在一个文件中，而其他用到该变量的文件必须对其进行声明，绝对不能重复定义。   

归纳一下：  

1、相同点    
都规定了类型和名字。    

2、不同点    
1）声明不申请存储空间；定义申请存储空间，并且可以选择赋初始值。     
2）声明不可以赋初始值；定义可以选择赋或不赋初始值。 
3）声明要加 extern 标记；定义不用。     
4）声明可以出现在多个文件；定义只能且必须出现在一个文件。     


### 函数的声明和定义    

与变量声明类似，但不需要加上 extern 关键字。  

相同点：  
都包含函数的三要素（返回类型、函数名、形参类型）。  

不同点： 
1）声明不包含函数体，用一个分号替代即可；定义要包含函数体。  
2）声明可以只给出形参类型，不必给出形参名称；定义需要给出形参类型和名称。  
3）声明可以出现在多个文件中；定义必须且只能出现在一个文件。  

函数声明也称作函数原型。   

虽然在声明中，不包含函数体，可以省略形参的名称，但是写上还是有好处的，可以让调用者更好的理解函数的用途。   

虽然把函数声明直接放进源文件中是合法的，但这样可能很烦琐且容易出错，而把函数声明放在头文件中，则能确保同一函数的所有声明保持一致。  

特殊情况下，如果我们只有库，而没有对应的头文件，但知道函数原型，那么可以直接在我们的源文件中写出函数原型，这样也可以通过编译，最终在链接环节从库文件中找到符号并链接即可。  


### 为什么可以分离式编译呢？   

因为编译时，若使用了在别处定义的名字，只需要知道名字跟类型信息就行了，不需要具体的定义；在链接的时候，再通过名字去别处搜寻定义所在的位置，用这个位置替换掉名字即可（只是大概描述，具体的静态链接与动态链接的处理手法是不同的）。   


---

## 1.13 初始化与赋值

初始化不是赋值，初始化是创建变量时赋予其一个初始值，而赋值的含义是把对象的当前值擦除，而以一个新值来替代。[6]

---

## 1.14 宏实现 sizeof

只是尝试一下模拟，并无实际意义。    

可以利用指针的加减来近似实现，也只能适应简单的情况。     

示例：  

```cpp

#include <iostream>

#define sizeof_var(v) reinterpret_cast<size_t>( (decltype(v)*)0 + 1 )

#define sizeof_type(T) reinterpret_cast<size_t>( (T*)0 + 1 )

int main() {
    int a = 10;
    std::cout << sizeof_var(a) << std::endl;
    
    int b[5];
    std::cout << sizeof_var(b) << std::endl;
    
    std::string str;
    std::cout << sizeof_var(str) << std::endl;


    std::cout << sizeof_type(int) << std::endl;

    return 0;
}

```

输出：  

```
4
20
32
4
```

---

## 1.15 打印当前时间

参考自百度ai智答。  

方法一：time + ctime      

```cpp
#include <iostream>
#include <ctime>

int main() {
    std::time_t t = std::time(nullptr);
    std::cout << std::ctime(&t) << std::endl;
    return 0;
}
```

<br/>

方法二：chrono + system_clock    

```cpp
#include <iostream>
#include <chrono>

int main() {
    auto now = std::chrono::system_clock::now();
    std::time_t t = std::chrono::system_clock::to_time_t(now);
    std::cout << std::ctime(&t) << std::endl;
    return 0;
}
```

<br/>

方法三：chrono + localtime (since c++17)    

```cpp
#include <iostream>
#include <chrono>
#include <ctime>

int main() {
    auto now = std::chrono::system_clock::now();
    std::time_t t = std::chrono::system_clock::to_time_t(now);
    struct std::tm* tm = std::localtime(&t);
    std::cout << tm->tm_year+1900 << "-" << tm->tm_mon+1 << "-" << tm->tm_mday << " "
              << tm->tm_hour << ":" << tm->tm_min << ":" << tm->tm_sec << std::endl;
    return 0;
}
```

<br/>

方法四：time + strftime + localtime     

```cpp
#include <iostream>
#include <ctime>

int main() {
    std::time_t now = std::time(nullptr);
    char timeString[100];
    std::strftime(timeString, sizeof(timeString), "%Y-%m-%d %X", std::localtime(&now));
    std::cout << timeString << std::endl;
    return 0;
}
```

---

## 1.16 cv-unqualified

cv-unqualified 指没有被 const 或 volatile 修饰的类型[5]，比如基础类型 int / float/ double / nullptr_t，或复合类型 enum / struct / class 等。  

除了 function type 和 reference type 之外的类型，基本上都属于以下中的一种：   

cv-unqualified            ：没有 const 或 volatile 修饰的    
const-qualified           ：被 const 修饰的     
volatile-qualified        ：被 volatile 修饰的    
const-volatile-qualified  ：同时被 const / volatile 修饰的      

---

## 1.17 c++ 的几种初始化方式

参考：[《C++中常见的几种初始化方法》](https://zhuanlan.zhihu.com/p/696384646)    

有几种不同的初始化方法：    
* 默认初始化 (default initialization)
* 直接初始化 (direct initialization)
* 拷贝初始化 (copy initialization)
* 统一初始化 (uniform initialization)
* 值初始化 (value initialization)

---

### 默认初始化 (default initialization)

创建一个变量的时候，未提供任何初始值的做法，叫做默认初始化。默认初始化得到的变量值是不确定的，可能造成未定义的行为。   

```cpp
A a;    // 默认初始化
int a;  // 默认初始化
```

---

### 直接初始化 (direct initialization)

使用圆括号进行初始化叫做直接初始化。   

```cpp
int a(10);
double b(13.2);
char c('x');

int d();       // 这是函数声明，不是定义变量 d
int e(3.14);   // 不对类型进行检查，能够通过编译 e == 1
```

要点：   
1. 直接初始化的初始值不能为空，否则变成函数声明；  
2. 直接初始化不对类型进行检查，会进行精度截断；   
3. 直接初始化可以更高效的初始化某些复杂的对象；   

---

### 拷贝初始化 (copy initialization)

用等号对变量进行初始化的方法是拷贝初始化。  

```cpp
int a = 10;
double b = 20.3;
char c = 'm';

int a  = 3.14;  // a == 3，没有类型检查 
```

要点：  
1. 对于某些复杂对象的初始化效率较低；   
2. 没有类型检查，会进行精度截断；    

---

### 统一初始化 (uniform initialization)

也叫列表初始化 (list initialization)，c++ 为了统一各种初始化形式，创造了统一初始化，用大括号 `{}` 表示。   

```cpp
int a {20};        // a == 20
double b {3.14};   // b == 3.14
int c = {30};      // c == 30
double d = {2.17}; // d == 2.17

int arr[] { 1,2,3 };  // arr == [3]{1,2,3}

std::vector<int> vec { 1,3,5 };  // vec = {1,3,5}
std::vector<std::string> svec{ "dog", "cat" }; // svec = {"dog", "cat"}

std::map<int, std::string> m{ {1, "A"}, {2, "B"} }; // m[1] == "A", m[2] == "B"

int i1 {10.1};   // 报错，double 不能赋值给 int，会发生精度截断
int i2 {};       // ok，是值初始化

```

要点：   
1. 不会也不允许发生精度截断 (narrowing conversion)，如果初始值的类型不符，则编译报错；     
2. 形式统一，大多数情况下都可使用统一初始化或值初始化；    

原理：  
1. 使用统一初始化，系统首先会调用值初始化(value initialization)，将初始值转化为 `std::initializer_list`；   
2. 使用得到的 `std::initializer_list` 对象来初始化变量；  
3. 对于对象的初始化：
    - 如果定义了参数为 `std::initializer_list` 的构造函数，优先使用该构造函数；   
    - 如果没有参数为 `std::initializer_list` 的构造函数，调用与 `std::initializer_list` 元素个数相同的构造函数；
    - 如果没有参数为 `std::initializer_list` 的构造函数，且对应的构造函数定义为 `explict` 时，不能使用 `std::initializer_list` 进行隐式赋值，必须显式调用;  

示例1：  

```cpp
#include <iostream>
#include <vector>

class A {
public:
    A(int _a, int _b) {
        std::cout << "call A::A(int, int)" << std::endl;
    }
    A(std::initializer_list<int> lst) {
        std::cout << "call A::A(initializer_list)" << std::endl;
    }
};

int main() {
    // 直接初始化
    A a1(1,2);          // call A::A(int, int)

    // 统一初始化
    A a2{1,2,3};        // call A::A(initializer_list)
    A a3{1,2};          // call A::A(initializer_list)
    A a4 = {1,2,3,4,5}; // call A::A(initializer_list)
}
```

示例2：  

```cpp
#include <iostream>
#include <vector>

class A{
public:
    A(int _x, int _y){
        std::cout << "call A::A(int, int)" << std::endl;
    }
    explicit A(int _x, int _y, int _z){
        std::cout << "call A::A(int, int, int)" << std::endl;
    }
};

int main(){
    // 统一初始化
    A p1(2, 3);             // call A(int, int)
    A p2{1, 2, 3};          // call A(int, int, int)
    A p3{1, 2};             // call A(int, int)
    A p4 = {1, 2};          // call A(int, int)
    A p5 = {1, 2, 3};       // 报错，A(int, int, int) 被 explict 修饰了，不能隐式转换
}
```

---

### 值初始化 (value initialization)

当大括号中的初始化值为空的时候，是值初始化，往往会直接初始化为 0 （也叫零初始化，zero initialization）或 空。   

值初始化确保了那些没有定义默认构造函数的类对象也能够被正确的初始化。  

```cpp
int a {};    // a == 0
float b {};  // b == 0
double c {}; // c == 0
char d {};   // (int) d == 0

// 按照以下方式初始化类对象也算是值初始化
A a1 = A();
A a2 = A{};
A* a3 = new A();
A* a4 = new A{};
```

要点：  
1. 如果类型 A 是数组类型，则数组的每个元素都是值初始化；   
2. 局部静态对象在没有显式初始化时会进行值初始化；   
3. 类对象进行值初始化的规则： 
    - 如果类有用户自定义的默认构造函数，调用之；   
    - 如果类有编译器生成的默认构造函数，先0值初始化再调用之；   
    - 没有默认构造函数，报错；   
4. 对聚合类进行值初始化相当于对类中的每个变量进行值初始化；   

---

## 1.18 c++ 的类型系统

参考：[《【C++ 类型系统】了解C++ 中 标量、复合、标准布局、平凡和聚合类型》](https://blog.csdn.net/qq_21438461/article/details/131604404)    

---

## 1.19 C++ 的类型转换

参考：[《C++的类型转换》](https://zhuanlan.zhihu.com/p/575121995)    

---

## 1.20 explicit

通常表示不允许进行隐式转换。   

---

## 1.21 C++ 非虚多态

参考：
* [《C++ 非虚多态（std::any, std::variant, std::tuple）》](https://zhuanlan.zhihu.com/p/690920999)    
* [《A Journey Into Non-Virtual Polymorphism in C++ - Rudyard Merriam - CppCon 2023》](https://github.com/CppCon/CppCon2023/blob/main/Presentations/A_Journey_into_Non_Virtual_Polymorphism_Rud_Merriam.pdf)     

---

## 1.22 翻译单元

translation unit。一个程序包括一个或多个翻译单元。一个翻译单元由一个实现文件及其直接或间接包含的所有头文件组成。实现文件的扩展名通常是 `.cpp` 或 `.cxx`，头文件的扩展名通常是 `.h` 或 `.hpp`。  

---

# todo

* 安全的格式化与字符串操作


* 异常

参考：[《【C++】异常+智能指针+特殊类和类型转换》](https://cloud.tencent.com/developer/article/2344734)    


* 什么是 trivial，什么是 non-trivial ？


* extern 的作用是什么？  

参考：[c++全局变量extern](https://zhuanlan.zhihu.com/p/658392228)    


* static 的作用是什么？

参考：[C/C++ 中的static关键字](https://zhuanlan.zhihu.com/p/37439983)    


* xvalue 具体是怎么形成的？


* 返回右值引用意味着什么？


* 为什么 string literal 是一种 lvalue？


* 什么是 emplace_back ？它的作用是什么？ 


* type_traits 的作用是什么？  


* constexpr 与 const 的区别是什么？


* const 相对于 define 有何好处？


* c99 支持 VLA，那么 c++ 支持吗？ 

[Why aren't variable-length arrays part of the C++ standard?](https://stackoverflow.com/questions/1887097/why-arent-variable-length-arrays-part-of-the-c-standard)   


* 为什么要定义纯虚函数？  


* 什么是别名声明？  

即 using。可以代替 typedef，用起来更直观，可以省掉不少麻烦。  

https://www.cnblogs.com/wickedpriest/p/14696909.html


* c++17 中对于 value categories 做了哪些修改？  

---

# 2. 参考

[1] SkyFire. 编译期多态. Available at https://xie.infoq.cn/article/829d74dcd8d19aa613f8da059, 2023-01-28.    

[2] Holy Chen. C++中虚函数、虚继承内存模型. Available at https://zhuanlan.zhihu.com/p/41309205, 2018-08-07.    

[3] wikipedia. Data structure alignment. Available at https://en.wikipedia.org/wiki/Data_structure_alignment.  

[4] [美]Randal E. Bryant, David R. O'Hallaron. 深入理解计算机系统(原书第3版). 龚奕利, 贺莲. 北京: 机械工业出版社, 2022-6(1): 189.      

[5] cppreference. cv (const and volatile) type qualifiers. Available at https://en.cppreference.com/w/cpp/language/cv.   

[6] [美] Stanley B. Lippman, Josée Lajoie, Barbara E. Moo. C++ Primer 中文版（第 5 版）. 王刚, 杨巨峰. 北京: 电子工业出版社, 2013-9: 120, 144, 154, 182, 730.     

