---
layout: post
title: "现代 c++ 三：右值引用与移动语义"
date: 2024-04-03
last_modified_at: 2024-04-03
categories: [c++]
tags: [c++]
---

* 目录  
{:toc}
<br/>


c++11 为了提高效率，引入了右值引用及移动语义，这个概念不太好理解，需要仔细研究一下，下文会一并讲讲左值、右值、左值引用、右值引用、const 引用、移动构造、移动赋值运行符 .. 这些概念。      

---

# 左值和右值
左值和右值是表达式的属性。从 c 语言开始就有左值、右值这两个名词，当时的用途也很简单，就是帮助记忆：左值可以位于赋值语句的左侧，而右值不能。  

c++ 的表达式也只有左值和右值，大体也是相似的意思。简单的理解，有地址（内存位置）的对象就是一个左值，比如 `int i = 3`，i 是一个左值，它是有地址的，而 3 是右值，它是个字面值，没有地址。有时候左值可以作为右值，这时候用的是它的值，比如这样：`int i = 3; int j = i;`，当用 i 去初始化 j 的时候，它是作为右值出现的，这时候用的是 i 的值，而不是 i 的地址（内存位置）。  

所以，可以简单的归纳一下：当一个对象被用作右值时，用的是对象的值（内容）；当对象被用作左值时，用的是对象的地址（内存位置）。[1]  


# 运算符的运算对象和运算结果
* 赋值运算符：运算对象是左值，运算结果也是左值。  

* 取地址符：运算对象是左值，运算结果是右值。  

* 内置解引用运算符、下标运算符、迭代器解引用运算符、string&vector的下标运算符：运算对象是左值，运算结果也是左值。   

* 内置类型和迭代器的递增递减运算符：运算对象是左值，运算结果，前置版本是左值，后置版本是右值。  


解引用运行符就是 * 操作符，用于获得指针所指的对象，比如:   

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


# 左值引用
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


# const 引用
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


# 右值引用
右值引用是 c++11 引入的新概念，就是绑定到右值上的引用，用 `&&` 表示，按流行的说法，右值引用是绑定到“一些即将销毁的对象上”。  

右值引用只能绑定到右值上，不能绑定到左值上，举些例子：   

```cpp
int r = 100;
int&& r1 = r;            // 不合法，r 是一个左值
int&& r2 = 100;          // 合法，100 是一个右值
string&& s1 {"hello"};   // 合法，"hello" 是一个右值
string&& s2 {s1};        // 不合法，s1 是一个左值，"string 右值引用" 只是它的类型，它本质是上一个左值，它是有地址（内存位置）的，这点很容易犯错

int x = 100;
int&& x1 = ++x;          // 不合法，++x 返回的是左值
int&& x2 = x++;          // 合法，x++ 返回的是右值，虽然可以，但项目中不要这么写，容易被别人打：）
```

上面例子中，要特别注意的情况是：`string&& s1 {"hello"};`，在这里，s1 是一个类型为 "string 右值引用" 的左值，当我们把 右值引用 当成一种类型之后，就比较好理解 s1 是一个左值的事实了，它是地址（内存位置）的变量。再举一个例子：`void f(int&& p1);`，在这个函数声明中，p1 是一个类型为 `int 右值引用` 的左值。可归纳如下：     
1、变量都是左值。  
2、函数的形参都是左值。   
3、临时对象都是右值。   

下面是最重要的问题，为什么会需要右值引用？   

简单的说，右值引用的目的在于提高运行效率，把对象复制变成对象移动。   

这个过程是怎么发生的呢？下文接着讲。  


# 移动语义，移动构造函数、移动赋值运算符函数
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

oops，上面的测试可以说有 75% 成功了，关于移动构造的测试失败了，它压根没调用移动构造函数。怎么回事？  

这实际上是一种编译器优化，叫 RVO（Return Value Optimization），返回值优化，这个我们下文再具体讲讲，为了避免这种优化对于我们测试的影响，我们可以给编译器传递一个选项，暂时禁用这种优化，修改一下编译命令： `g++ -std=c++14 -fno-elide-constructors move_constructor_demo.cpp && ./a.out`，重新编译运行，移动构造的测试输出变成：   

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

最精准的分析需要看汇编代码，但汇编有点复杂，这里先不看，等下篇文章讲 RVO 的时候再一并用汇编分析。   


# 编译器默认生成的移动（构造/赋值运算符）函数
如果我们没有自己写拷贝构造函数或拷贝赋值运算符，那么编译器会帮我们生成默认的。   

编译器在特定条件下，也会帮我们生成默认的移动函数[2]：
1. 一个类没有定义任何版本的拷贝构造函数、拷贝赋值运算符、析构函数；
2. 类的每个非静态成员都可以移动
    * 内置类型（如整型、浮点型）
    * 定义了移动操作的类类型

第1点，应该是确保系统可以生成符合程序员需要的移动函数，如果代码中定义了那三种函数，说明程序员有自己控制复制或释放的倾向，这时候编译器就不默认生成了。   
第2点，只有确保成员都可移动，才能生成正确的移动函数。  


# std::move
上面讲移动构造和移动赋值运算符的时候，发现由于编译器的优化：RVO，导致即使我们构造了合适的场景，也没能验证移动构造的使用。 

接下来介绍的 std::move，即使不屏蔽 RVO，也可以验证移动构造的使用，只需要这样修改 

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

std::move 把 x 转换成了一个右值类型的变量，所以编译器使用移动构造函数来生成变量 a。  

特别注意，std::move **并不完成对象的移动**，它的作用只是把传递进去的**实参**转换成一个右值，可以理解它是某种 cast 封装，一种可能的实现如下[3]：   

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

std::move 只是完成**类型转换**，真正起作用的是移动构造函数或移动赋值运算符函数，在这两个函数中写移动逻辑。   

综上，std::move 是一种危险的操作，调用时必须确认源对象没有其他用户了，否则容易发生一些意外的难以理解的状况。 

---

# 参考

[1] [美] Stanley B. Lippman, Josée Lajoie, Barbara E. Moo. C++ Primer 中文版（第 5 版）. 王刚, 杨巨峰. 北京: 电子工业出版社, 2013-9: 120, 154, 182.   

[2] 王健伟. C++新经典. 北京: 清华大学出版社, 2020-08-01.   

[3] [美]Scott Meyers. Effective Modern C++(中文版). 高博. 北京: 中国电力出版社, 2018-4: 149, 151.  

