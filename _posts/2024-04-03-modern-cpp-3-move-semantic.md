---
layout: post
title: "现代 c++ 三：移动语义与右值引用"
date: 2024-04-03
last_modified_at: 2024-04-03
categories: [c++]
tags: [c++]
---

* 目录  
{:toc}
<br/>

移动语义很简单，但它相关联的术语很复杂。本文尝试从历史的角度解释清楚这些乱七八糟的术语及其关联：  

* 表达式 (expression)、类型（type）、值类别 (value categories)；    

* 左值 (lvalue)、右值 (rvalue)、广义左值 (glvalue aka "generalized" lvalue)、纯右值 (prvalue aka "pure" rvalue)、将亡值 (xvalue aka "eXpiring" value)；    

* 左值引用 (lvalue reference)、右值引用 (rvalue reference)、const 引用；    

* 移动构造 (move constructor)、移动赋值 (move assignment)；    

<br/>

关键在于搞清楚：    

* 为了实现移动语义，必须明确定义出哪些表达式是可以移动的。  

* 表达式有两个独立的属性：类型 (type)、值类别 (value categories)。（注意：变量和字面量是最简单的表达式。）  

  * 类型 (type)，包括基本类型 （int, float，void, null 等），复合类型（class，union，引用 等）等，具体参见 cppreference 的 specification[6]。  

  * 值类别 (value categories)，包括广义左值、右值、左值、将亡值、纯右值，具体参见 cppreference 的 specification[7]。   

<br/>

实际上，读过 Bjarne Stroustrup 的这篇文章 《“New” Value Terminology》[5]，就会知道 B. Stroustrup 和 c++ 委员会的人是怎么一步步折腾出这么复杂的值类别的。   

---

# 1. 移动语义

c++11 为了提高效率，引入了移动语义，移动语义很简单，它是相对于 “复制” 而言的，把一个对象里面的资源 “移动” 到另一个对象中，就是移动语义了。  

比如下面这样，用临时变量构造变量 a，在 c++11 之前，会触发拷贝构造 S(S& other) 拷贝 (memcpy) 数据。   

```cpp
struct S {
    char* p;
    int len;
    S(int _len) {len = _len; p = new char[len];}
    S(S& other) {len = other.len; p = new char[len]; memcpy(p, other.p, len);}
};

S a(S());
```

但在 c++11 后，不用拷贝数据了，可以增加一个移动拷贝构造函数 S(S&& other)，直接拿对方的指针来用，不用拷贝 (memcpy) 数据。   

```cpp
struct S {
    char* p;
    int len;
    S(int _len) {len = _len; p = new char[len];}
    S(S& other) {len = other.len; p = new char[len]; memcpy(p, other.p, len);}
    S(S&& other) {len = other.len; p = other.p; other.p = nullptr; }
};
```

---

# 什么表达式可以被移动？  

上面的例子看到了，移动语义是有破坏性的，被 “移动” 过的对象就废掉了，不应该再被使用。所以，从安全的角度讲，只有当一个对象不会再被使用到的时候，才可以被 “移动” 。     

---

# 关于表达式分类的讨论

所以，实现移动语义的关键就在于明确 c++ 哪些表达式是可以被移动的。为了搞清楚这个问题，就需要对表达式做出明确的、规范的分类。对此，Bjarne Stroustrup 和 c++ 委员会的人开会进行了仔细的讨论，讨论的内容被详细记录在这篇文章 《“New” Value Terminology》[5] 里。   


---

# 值类别（value categories） 详解

![](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/expression-value-categories.png)

<center>图1：c++ value categories[1]</center>    

<br/>

上图就是当前 c++ specification 对于值类别的精确分类。这实际上与 Bjarne Stroustrup 在讨论会上画的图是一致的，只不过是倒了过来。  

---

# 引用的分类

---

## 左值引用

左值引用就是绑定到左值上的引用，用 `&` 表示。c++11 之前，引用都是左值引用。左值引用就相当于给一个左值（对象）取一个别名。  

它与指针是有显著区别的，指针可以指向 NULL 对象，指针可以只声明不初始化，但左值引用都不行。左值引用必须引用一个已经存在的对象，必须定义时初始化，像这样:  

```cpp
int i = 100;
int& refi = i;  // 合法
int& refi2;     // 不合法
```

另外，左值引用不能绑定到临时对象上：        

```cpp
int& i = 100;           // 不合法
string& s {"hello"};    // 不合法
```

---

## const 引用

const 引用是一种特殊的左值引用，与常规左值引用的区别在于，它可以绑定到临时对象：  

```cpp
const int& i1 = 100;        // 合法，相当于：int temp = 100; const int& i1 = temp;
const string& s1 {"hello"}; // 合法，相当于：string temp {"hello"}; const string& s1 {temp};
```

c++ 只会为 const 引用产生临时对象，不会对非 const 引用产生临时对象，这一特性导致了一些容易让人困惑的现象：  

```cpp
void f1(const string& s) {
    cout << s << endl;
}

void f2(string& s) {
    cout << s << endl;
}

f1("hello");   // 正常，"hello" 转换成 string 类型的临时对象，临时对象可以被 const 引用 引用
f2("hello");   // 编译报错，"hello" 转换成 string 类型的临时对象，临时对象不可以被 左值引用 引用
               // 会报类似这样的编译错误：no known conversion from 'const char[6]' to 'string &'

string s = "hello";
f1(s);         // 正常，一个左值可以被 左值引用 所引用
f2(s);         // 正常一个左值可以被 const引用 所引用
```

---

## 右值引用

右值引用是 c++11 引入的新概念，就是绑定到右值上的引用，用 `&&` 表示，右值引用只能绑定到右值上，不能绑定到左值上，举些例子：   

```cpp
int r = 100;
int&& r1 = r;            // 不合法，r 是一个左值
int&& r2 = 100;          // 合法，100 是一个右值
string&& s1 {"hello"};   // 合法，"hello" 是一个右值
string&& s2 {s1};        // 不合法，s1 是一个左值，"string 右值引用" 只是它的类型，它本质是上一个左值，它是有地址（内存位置）的，这点很容易犯错

int x = 100;
int&& x1 = ++x;          // 不合法，++x 返回的是左值
int&& x2 = x++;          // 合法，x++ 返回的是右值，虽然可以，但项目中不要这么写
```

上面例子中，要特别注意的情况是：`string&& s1 {"hello"};`，在这里，s1 是一个类型为 "string 右值引用" 的左值，当把 右值引用 当成一种类型之后，就比较好理解 s1 是一个左值的事实了。再举一个例子：`void f(int&& p1);`，在这个函数声明中，p1 是一个类型为 `int 右值引用` 的左值。

---

# 移动构造函数、移动赋值运算符函数

对象的移动是如何发生的？在 c++11 中，是通过移动构造函数和移动赋值运算符来实现的，这两个函数与拷贝构造函数和拷贝赋值运算符是相对的。前者的参数是右值引用，而后者的参数是左值引用。  

如果没有定义移动函数或者源对象不是右值，用一个对象给另一个对象初始化或赋值，调用的都是拷贝函数。    
如果定义了移动函数并且源对象是右值，用一个对象给另一个对象初始化或赋值，调用的都是移动函数。  

复制对象的基本模式是，目标对象往往需要 new 一块内存出来，然后从源对象那里复制内存数据。   
移动对象的基本模式是，直接挪用内存，不 new 内存也不拷贝数据，直接把源对象的内存数据拿来用，其代价往往只是一些指针变量的赋值。 

显而易见，如果有比较多的内存需要拷贝，移动对象的效率是更高很多的。  

下面举个例子证明以上的说法：   
源码可在此找到：https://github.com/antsmallant/antsmallant_blog_demo/tree/main/blog_demo/modern-cpp 。

```cpp
// move_constructor_demo.cpp
// 编译&执行：g++ -std=c++14 move_constructor_demo.cpp && ./a.out
// 屏蔽rvo的编译&执行：g++ -std=c++14 -fno-elide-constructors move_constructor_demo.cpp && ./a.out

#include <iostream>
#include <vector>
using namespace std;

class A {
private:
    vector<int>* p;
public:
    A() {
        cout << "A 构造函数，无参数" << endl;
        p = new vector<int>();
    }
    // 构造函数
    A(int cnt, int val) {
        cout << "A 构造函数，带参数" << endl;
        p = new vector<int>(cnt, val);
    }
    // 析构函数
    ~A() {
        if (p != nullptr) {
            delete p;
            p = nullptr;
            cout << "A 析构函数，释放 p" << endl;
        } else {
            cout << "A 析构函数，不需要释放 p" << endl;
        }
    }
    // 拷贝构造函数
    A(const A& other) {
        cout << "A 拷贝构造函数" << endl;
        p = new vector<int>(other.p->begin(), other.p->end());
    }
    // 拷贝赋值运算符
    A& operator = (const A& other) {
        cout << "A 拷贝赋值运算符" << endl;
        if (p != nullptr) {
            cout << "A 拷贝赋值前释放旧内存" << endl;
            delete p;
            p = nullptr;
        }
        p = new vector<int>(other.p->begin(), other.p->end());       
        return *this;
    }
    // 移动构造函数
    A(A&& other) noexcept {
        cout << "A 移动构造函数" << endl;
        this->p = other.p;  // 挪用别人的
        other.p = nullptr;  // 置空别人的
    }
    // 移动赋值运算符
    A& operator = (A&& other) noexcept {
        cout << "A 移动赋值运算符" << endl;
        this->p = other.p; 
        other.p = nullptr;  
        return *this;
    }
};

void test_copy_constructor() {
    A a(10, 100);
    A b(a);
}

void test_copy_assign_operator() {
    A a(10, 100);
    A b;
    b = a;
}

A getA(int cnt, int val) {
    return A(cnt, val);
}

void test_move_constructor() {
    A a(getA(10, 200));
}

void test_move_assign_operator() {
    A a;
    a = getA(10, 200);
}

int main() {
    cout << "测试拷贝构造: " << endl;
    test_copy_constructor();

    cout << endl << "测试拷贝赋值运算符: " << endl;
    test_copy_assign_operator();

    cout << endl << "测试移动构造: " << endl;
    test_move_constructor();

    cout << endl << "测试移动赋值运算符: " << endl;
    test_move_assign_operator();

    return 0;
}
```

输出是：  

```
测试拷贝构造: 
A 构造函数，带参数
A 拷贝构造函数
A 析构函数，释放 p
A 析构函数，释放 p

测试拷贝赋值运算符: 
A 构造函数，带参数
A 构造函数，无参数
A 拷贝赋值运算符
A 拷贝赋值前释放旧内存
A 析构函数，释放 p
A 析构函数，释放 p

测试移动构造: 
A 构造函数，带参数
A 析构函数，释放 p

测试移动赋值运算符: 
A 构造函数，无参数
A 构造函数，带参数
A 移动赋值运算符
A 析构函数，不需要释放 p
A 析构函数，释放 p
```

上面的测试可以说有 75% 成功了，关于移动构造的测试失败了，它没调用移动构造函数。怎么回事？  

这实际上是一种编译器优化，叫 RVO（Return Value Optimization），返回值优化，这个暂且不展开讲。为了避免这种优化对于测试的影响，可以给编译器传递一个选项，暂时禁用这种优化，修改一下编译命令： `g++ -std=c++14 -fno-elide-constructors move_constructor_demo.cpp && ./a.out`，重新编译运行，移动构造的测试输出变成：   

```
测试移动构造: 
A 构造函数，带参数
A 移动构造函数
A 析构函数，不需要释放 p
A 移动构造函数
A 析构函数，不需要释放 p
A 析构函数，释放 p
```

虽然如愿输出了 “A 移动构造函数”，但输出有点多。把代码列出来，简单分析一下：  

```cpp
A getA(int cnt, int val) {
    // 1、用带参数的构造函数 A(10, 200) 生成一个局部对象 x
    // 2、return 的时候，用移动构造函数 A(x) 生成一个临时对象 t
    return A(cnt, val);
}

void test_move_constructor() {
    // 3、用移动构造函数 A(t) 生成局部对象 a
    A a(getA(10, 200));
}
```

---

# 编译器默认生成的移动（构造/赋值运算符）函数

如果没有自己写拷贝构造函数或拷贝赋值运算符，那么编译器会帮生成默认的。   

编译器在特定条件下，也会帮生成默认的移动函数[2]：
1. 一个类没有定义任何版本的拷贝构造函数、拷贝赋值运算符、析构函数；
2. 类的每个非静态成员都可以移动
    * 内置类型（如整型、浮点型）
    * 定义了移动操作的类类型

第1点，应该是确保系统可以生成符合程序员需要的移动函数，如果代码中定义了那三种函数，说明程序员有自己控制复制或释放的倾向，这时候编译器就不默认生成了。   
第2点，只有确保成员都可移动，才能生成正确的移动函数。  

---

# std::move

上面讲移动构造和移动赋值运算符的时候，发现由于编译器的 RVO 优化，导致即使构造了合适的场景，也没能验证移动构造的使用。    

接下来介绍的 std::move，能够做到即使不屏蔽 RVO，也可以验证移动构造的使用，只需要这样修改：   

```cpp
// g++ -std=c++14 move_constructor_demo.cpp && ./a.out

void test_move_constructor_use_stdmove() {
    A x(10, 200);
    A a(std::move(x));
}

int main() {
    cout << endl << "使用 std::move 测试移动构造：" << endl;
    test_move_constructor_use_stdmove();
}
```

输出:   

```
A 构造函数，带参数
A 移动构造函数
A 析构函数，释放 p
A 析构函数，不需要释放 p
```

std::move 强制产生一个绑定到左值（即x）的右值引用，所以编译器匹配到右值引用，就相对应的调用移动构造函数。   

特别注意，std::move **并不完成对象的移动**，它的作用只是强制产生一个右值引用，真正起移动作用的是移动构造函数或移动赋值运算符函数，要在这两个函数中写移动逻辑。   

std::move 的一种可能实现如下[3]：   

```cpp
template<typename T>
typename remove_reference<T>::type&&
move(T&& param)
{
    using ReturnType = 
      typename remove_reference<T>::type&&;

    return static_cast<ReturnType>(param);
}
```

**实参**可以是左值，也可以是右值:    

```cpp
int a = 100;
int&& r1 = std::move(a);    // 合法
int&& r2 = std::move(200);  // 合法
```

<br/>

综上，std::move 是一种危险操作，调用时必须确认源对象没有其他用户了，否则容易发生一些意外的难以理解的状况。  

---

# 运算符的运算对象和运算结果

* 赋值运算符：运算对象是左值，运算结果也是左值。  

* 取地址符：运算对象是左值，运算结果是右值。  

* 内置解引用运算符、下标运算符、迭代器解引用运算符、string&vector的下标运算符：运算对象是左值，运算结果也是左值。   

* 内置类型和迭代器的递增递减运算符：运算对象是左值，运算结果，前置版本是左值，后置版本是右值。  


解引用运算符就是 * 操作符，用于获得指针所指的对象，比如:   

```cpp
int v = 100;
int* p = &v;
*p = 200;
```

p 是一个指向了对象的指针，则 *p 就是获得指针 p 所指的对象，比如 `*p = 100;`     


递增递减的前置和后置版本的具体区别：   

* 前置版本，比如： ++i 返回的是左值，过程是直接把 i 加 1，然后返回 i。     

* 后置版本，比如： i++ 返回的是右值，过程是先用一个临时变量保存 i 的值，然后把 i 值加1，然后返回临时变量。    
所以，建议是：除非必须，不要使用递增递减的后置版本，它们生成了临时变量，是一种浪费。  

---

# 拓展阅读

* [C++的复杂，C是原罪：从值类别说开去](https://cloud.tencent.com/developer/article/2352089)  这篇文章从 C 语言、汇编和 C++ 设计发展的角度，分析了为什么 c++ 搞了这么复杂的值类别：左值、右值、纯右值、广义左值、将亡值。  

---

# 参考

[1] [美] Stanley B. Lippman, Josée Lajoie, Barbara E. Moo. C++ Primer 中文版（第 5 版）. 王刚, 杨巨峰. 北京: 电子工业出版社, 2013-9: 120, 154, 182.   

[2] 王健伟. C++新经典. 北京: 清华大学出版社, 2020-08-01.   

[3] [美]Scott Meyers. Effective Modern C++(中文版). 高博. 北京: 中国电力出版社, 2018-4: 149, 151.  

[4] wg21. Working Draft, Standard for Programming Language C++ (N4878). Available at https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2020/n4878.pdf, 2020-12-15: 91.    

[5] Bjarne Stroustrup. “New” Value Terminology. Available at https://www.stroustrup.com/terminology.pdf.    

[6] cppreference. Type. Available at https://en.cppreference.com/w/cpp/language/type.    

[7] cppreference. Value categories. Available at https://en.cppreference.com/w/cpp/language/value_category.   


---

其实资料：

[C++ value categories and decltype demystified](https://www.scs.stanford.edu/~dm/blog/decltype.html)     