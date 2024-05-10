---
layout: post
title: "现代 C++"
date: 2024-04-15
last_modified_at: 2024-04-15
categories: [c++]
tags: [c++]
---

* 目录  
{:toc}
<br/>

关于现代 C++ 的书和文章遍地都是，但无论如何，每个人都应该自己归纳总结一下，故有此文。  

所谓现代 C++，指的是从 C++11 开始的 C++，从 C++11 开始，加入一些比较现代的语言特性和改进了的库实现，使得用 C++ 开发少了很多心智负担，程序也更加健壮，“看起来像一门新语言”。    

从 C++11 开始，每 3 年发布一个新版本，到今年（2024）已经有 5 个版本了，分别是 C++11、C++14、C++17、C++20、C++23，这 5 个版本引入了上百个新的语言特性和新的标准库特性。       

---

# C++11 ~ C++23 新特性汇总

## C++11 新特性

C++11 是一个 major 版本，现代 C++ 开天辟地的版本，有特别多新东西。     

新的语言特性[4]：  

* 内存模型——一个高效的为现代硬件设计的底层抽象，作为描述并发的基础
* auto 和 decltype——避免类型名称的不必要重复
* 范围 for——对范围的简单顺序遍历
* 移动语义和右值引用——减少数据拷贝
* 统一初始化—— 对所有类型都（几乎）完全一致的初始化语法和语义
* nullptr——给空指针一个名字
* constexpr 函数——在编译期进行求值的函数
* 用户定义字面量——为用户自定义类型提供字面量支持
* 原始字符串字面量——不需要转义字符的字面量，主要用在正则表达式中
* 属性——将任意信息同一个名字关联
* lambda 表达式——匿名函数对象
* 变参模板——可以处理任意个任意类型的参数的模板
* 模板别名——能够重命名模板并为新名称绑定一些模板参数
* noexcept——确保函数不会抛出异常的方法
* override 和 final——用于管理大型类层次结构的明确语法
* static_assert——编译期断言
* long long——更长的整数类型
* 默认成员初始化器——给数据成员一个默认值，这个默认值可以被构造函数中的初始化所取代
* enum class——枚举值带有作用域的强类型枚举


新的标准库特性[4]：  

* unique_ptr 和 shared_ptr——依赖 RAII 的资源管理指针
* 内存模型和 atomic 变量
* thread、mutex、condition_variable 等——为基本的系统层级的并发提供了类型安全、可移植的支持
* future、promise 和 packaged_task，等——稍稍更高级的并发
* tuple——匿名的简单复合类型
* 类型特征（type trait）——类型的可测试属性，用于元编程
* 正则表达式匹配
* 随机数——带有许多生成器（引擎）和多种分布
* 时间——time_point 和 duration
* unordered_map 等——哈希表
* forward_list——单向链表
* array——具有固定常量大小的数组，并且会记住自己的大小
* emplace 运算——在容器内直接构建对象，避免拷贝
* exception_ptr——允许在线程之间传递异常

---

## C++14 新特性

C++14 是一个 minor 版本，没什么重要的新特性，主要是在给 C++11 打补丁，为使用者 “带来极大方便”，实现 “对新手更为友好” 这一目标。  

新的语言特性[5]：  
* 泛型的lambda
* Lambda捕获部分中使用表达式
* 函数返回类型推导
* 另一种类型推断:decltype(auto)
* 放松的constexpr函数限制
* 变量模板
* 聚合类成员初始化
* 二进制字面量： 0b或0B 前缀
* 数字分位符
* deprecated 属性

新的标准库特性[5]：  
* 共享的互斥体和锁: std::shared_timed_mutex
* 元函数的别名
* 关联容器中的异构查找
* 标准自定义字面量
* 通过类型寻址多元组
* 较小的标准库特性: std::make_unique, std::is_final 等

---

## C++17 新特性

C++17 是一个 major 版本。  

新的语言特性[6]：  

* 构造函数模板参数推导——简化对象定义
* 推导指引——解决构造函数模板参数推导歧义的显式标注
* 结构化绑定——简化标注，并消除一种未初始化变量的来源
* inline 变量——简化了那些仅有头文件的库实现中的静态分配变量的使用
* 折叠表达式——简化变参模板的一些用法
* 条件中的显式测试——有点像 for 语句中的条件
* 保证的复制消除——去除了很多不必要的拷贝操作
* 更严格的表达式求值顺序——防止了一些细微的求值顺序错误
* auto 当作模板参数类型——值模板参数的类型推导
* 捕捉常见错误的标准属性——`[[maybe_unused]]、[[nodiscard]] 和 [[fallthrough]]`
* 十六进制浮点字面量
* 常量表达式 if——简化编译期求值的代码

新的标准库特性[6]：  
* optional、any 和 variant——用于表达“可选”的标准库类型
* shared_mutex 和 shared_lock（读写锁）和 scoped_lock
* 并行 STL——标准库算法的多线程及矢量化版本
* 文件系统——可移植地操作文件系统路径和目录的能力
* string_view——对不可变字符序列的非所有权引用
* 数学特殊函数——包括拉盖尔和勒让德多项式、贝塔函数、黎曼泽塔函数

---

## C++20 新特性

C++20 是一个 major 版本，有很重要的更新，"The Big Four"，即四个重要的特性，分别是：概念、范围、协程和模块。  

新的语言特性[7]：  

* coroutines
* concepts
* designated initializers
* template syntax for lambdas
* range-based for loop with initializer
* `[[likely]]` and `[[unlikely]]` attributes
* deprecate implicit capture of this
* class types in non-type template parameters
* constexpr virtual functions
* explicit(bool)
* immediate functions
* using enum
* lambda capture of parameter pack
* char8_t
* constinit

新的标准库特性[7]：  

* concepts library
* synchronized buffered outputstream
* std::span
* bit operations
* math constants
* std::is_constant_evaluated
* std::make_shared supports arrays
* starts_with and ends_with on strings
* check if associative container has element
* std::bit_cast
* std::midpoint
* std::to_array

---

## C++23 新特性

C++23 是一个 minor 版本。  

新的语言特性[8]：  

* 新语言功能特性测试宏
* 显式对象形参，显式对象成员函数（推导 this）
* if consteval / if not consteval
* 多维下标运算符（例如 v[1, 3, 7] = 42;）
* static operator()
* static operator[]
* auto(x)：语言中的衰退复制
* lambda 表达式上的属性
* 可选的扩展浮点类型：std::float{16|32|64|128}_t 和 std::bfloat16_t。
* （有符号）std::size_t 字面量的字面量后缀 'Z'/'z'
* 后缀
* #elifdef、#elifndef 与 #warning
* 通过新属性 [[assume(表达式)]] 进行假设
* 具名通用字符转义
* 可移植源文件编码为 UTF-8
* 行拼合之前修剪空白

新的标准库特性[8]：  

* 新的库功能特性测试宏
* 新的范围折叠算法
* 字符串格式化改进
* “平铺（flat）”容器适配器：std::flat_map、std::flat_multimap、std::flat_set、std::flat_multiset
* std::mdspan
* std::generator
* std::basic_string::contains, std::basic_string_view::contains
* 禁止从 nullptr 构造 std::string_view
* std::basic_string::resize_and_overwrite
* std::optional 的单子式操作：or_else、and_then、transform
* 栈踪迹（stacktrace）库
* 新的范围算法
* 新的范围适配器（视图）
* 对范围库的修改
* 对视图的修改
* 标记不可达代码：std::unreachable
* 新的词汇类型 std::expected
* std::move_only_function
* 新的带有程序提供的固定大小缓冲区的 I/O 流 std::spanstream
* std::byteswap
* std::to_underlying
* 关联容器的异质擦除

---

# 若干重要概念与坑
可能有多年 c++ 编程经验，但回过头来发现，对于一些基础概念却并不怎么熟悉，比如表达式、语句这些。   

## 表达式 (expression)
表达式是由一个或多个运算对象（operand）组成，对表达式求值将得到一个结果。字面值和变量是最简单的表达式（expression），其结果就是字面值和变量的值。把一个运算符（operator）和一个或多个运算对象组合起来可以生成较复杂的表达式 (expression)。[3]  


## 语句 (statement)
C++语言中的大多数语句都以分号结束，一个表达式，比如 ival + 5，末尾加上分号就变成了表达式语句（expression statement）。表达式语句的作用是执行表达式并丢弃掉求值结果。[3] 

空语句是最简单的语句，空语句中只含有一个单独的分号：`;`。空语句的作用是，如果语法上需要一条语句但逻辑上不需要，此时应该使用空语句，比如：  

```c++
while (cin >> s && s != sought)
    ;
```

复合语句（compound statement）是指用花括号括起来的（可能为空的）语句和声明的序列，复合语句也被称作块（block）。复合语句的作用是，如果在程序的某个地方，语法上需要一条件语句，但逻辑上需要多条语句，比如：  

```c++
while (val <= 10) {
    sum += val;
    ++val;
}
```

注意：块不以分号作为结束。  


## 容易搞错的赋值表达式

* 什么是赋值表达式       
`int a = 100` 是赋值表达式吗？   
不是的，这是**定义时初始化**，赋值表达式不能以类型名开头，`a = 100` 这才是赋值表达式。   

* 赋值表达式的结果    
赋值表达式本身是有结果的，它的结果就是 = 号左侧的运算对象，是一个左值。比如 `a = 100`，它的结果就是 a，可以这样验证：   

```c++
int a;
printf("%d\n", (a = 5));    // 输出 5
printf("0x%x\n", &a);       // 在我本机上输出 0x500d58
printf("0x%x\n", &(a=5));   // 在我本机上输出 0x500d58
```

* 赋值表达式的运算顺序   
右结合的，从右到左，所以这样的一个语句：`a = b = c = 5;`，会把 a、b、c 都赋值为 5，它相当于这样：`a = (b = (c = 5))`。     
先是 5 赋值给 c，然后 c = 5 的值是 5，5 赋值给 b，然后 b = 5 的值是 5，5 再赋给 a。    


## 定义时初始化 vs 赋值
上面讲赋值表达式的时候已经提及了，定义时初始化与赋值是不同的，不能混为一谈。这个很重要，因为不同场景调用的函数是不同的，定义时初始化调用的是拷贝构造函数，而赋值调用的是赋值运算符函数。    

```c++
class Dt {
private:
    int a;
public:

    Dt() {a=100;}
    Dt(int v) {a = v;}
    Dt(const Dt& other) {cout << "copy constuct" << endl; this->a = other.a;}  // 拷贝构造函数
    Dt& operator = (const Dt& other) {cout << "operator = " << endl; this->a = other.a;} // 赋值运算符函数
};

int main() {
    Dt b(1);
    Dt c(2);
    Dt a = b;  // 定义时初始化，调用的是拷贝构造函数
    a = c;     // 赋值，调用的是赋值运算符函数，如果有重载则使用重载的，否则使用系统默认生成的（只会做浅拷贝）
    return 0;
}
```

如果我们没有显式的重载赋值运算符函数，那么编译器会生成一个默认的赋值运算符函数，而默认的只能完成浅拷贝，是比较危险的！   
 

## 函数 (function)
函数是一个**命名了的代码块**，我们通过调用函数执行相应的代码。函数可以有 0 个或多个参数，而且（通常）会产生一个结果。可以重载函数，也就是说，同一个名字可以对应几个不同的函数。[3]     


## 类型转换
TODO

参考：https://weread.qq.com/web/reader/55f32d30813ab6ea1g017832k3c5327902153c59dc0488e1?


## 列表初始化
是 c++11 引入的一种新的初始化方式，使用花括号 {} 来初始化变量，其目的是为了实现一种通用的初始化方式。   

这两个语句 `int c = {100};`，`int c {100};` 在多数时候被编译器同等处理。 

这种初始化形式的一个重要特点：当初始值存在丢失信息的风险时，编译器会报错，比如用 double 初始化 int 变量：`int c {200.45};`。  


## 无参数构造函数的小坑
假设一个类 A，它的构造函数是无参数的，那么要这样写来定义一个实例：`A a;`，不能写成这样：`A a();`，因为后者会被编译器当成是函数声明。   


## 实参与形参
例子：

```c++
int a = 100;     
void f(int b);   // b 是形参
f(a);            // a 是实参
```


## 右值引用、移动语义

### 左值和右值
左值和右值是表达式的属性。从 c 语言开始就有左值、右值这两个名词，当时的用途也很简单，就是帮助记忆：左值可以位于赋值语句的左侧，而右值不能。  

C++ 的表达式也只有左值和右值，大体也是相似的意思。简单的理解，有地址（内存位置）的对象就是一个左值，比如 `int i = 3`，i 是一个左值，它是有地址的，而 3 是右值，它是个字面值，没有地址。有时候左值可以作为右值，这时候用的是它的值，比如这样：`int i = 3; int j = i;`，当用 i 去初始化 j 的时候，它是作为右值出现的，这时候用的是 i 的值，而不是 i 的地址（内存位置）。  

所以，可以简单的归纳一下：当一个对象被用作右值时，用的是对象的值（内容）；当对象被用作左值时，用的是对象的地址（内存位置）。[3]  


### 运算符的运算对象和运算结果
* 赋值运算符：运算对象是左值，运算结果也是左值。  

* 取地址符：运算对象是左值，运算结果是右值。  

* 内置解引用运算符、下标运算符、迭代器解引用运算符、string&vector的下标运算符：运算对象是左值，运算结果也是左值。   

* 内置类型和迭代器的递增递减运算符：运算对象是左值，运算结果，前置版本是左值，后置版本是右值。  


解引用运行符就是 * 操作符，用于获得指针所指的对象，比如:   

```c++
int v = 100;
int* p = &v;
*p = 200;
```

p 是一个指向了对象的指针，则 *p 就是获得指针 p 所指的对象，比如 `*p = 100;`     


递增递减的前置和后置版本的具体区别：   
* 前置版本，比如： ++i 返回的是左值，过程是直接把 i 加 1，然后返回 i。     
* 后置版本，比如： i++ 返回的是右值，过程是先用一个临时变量保存 i 的值，然后把 i 值加1，然后返回临时变量。    
所以，建议是：除非必须，不要使用递增递减的后置版本，它们生成了临时变量，是一种浪费。  


### 左值引用
左值引用就是绑定到左值上的引用，用 `&` 表示。c++11 之前，引用都是左值引用。左值引用就相当于给一个左值（对象）取一个别名。  

它与指针是有显著区别的，指针可以指向 NULL 对象，指针可以只声明不初始化，但左值引用都不行。左值引用必须引用一个已经存在的对象，必须定义时初始化，像这样:  

```c++
int i = 100;
int& refi = i;  // 合法
int& refi2;     // 不合法
```

另外，左值引用不能绑定到临时对象上：        

```c++
int& i = 100;           // 不合法
string& s {"hello"};    // 不合法
```


### const 引用
const 引用是一种特殊的左值引用，与常规左值引用的区别在于，它可以绑定到临时对象：  

```c++
const int& i1 = 100;        // 合法，相当于：int temp = 100; const int& i1 = temp;
const string& s1 {"hello"}; // 合法，相当于：string temp {"hello"}; const string& s1 {temp};
```

c++ 只会为 const 引用产生临时对象，不会对非 const 引用产生临时对象，这一特性导致了一些容易让人困惑的现象：  

```c++
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


### 右值引用
右值引用是 c++11 引入的新概念，就是绑定到右值上的引用，用 `&&` 表示，按流行的说法，右值引用是绑定到“一些即将销毁的对象上”。  

右值引用只能绑定到右值上，不能绑定到左值上，举些例子：   

```c++
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


### 移动语义，移动构造函数、移动赋值运算符函数
对象的移动是如何发生的？在 c++11 中，是通过移动构造函数和移动赋值运算符来实现的，这两个函数与拷贝构造函数和拷贝赋值运算符是相对的。前者的参数是右值引用，而后者的参数是左值引用。  

如果没有定义移动函数或者源对象不是右值，用一个对象给另一个对象初始化或赋值，调用的都是拷贝函数。    
如果定义了移动函数并且源对象是右值，用一个对象给另一个对象初始化或赋值，调用的都是移动函数。  

复制对象的基本模式是，目标对象往往需要 new 一块内存出来，然后从源对象那里复制内存数据。   
移动对象的基本模式是，直接挪用内存，不 new 内存也不拷贝数据，直接把源对象的内存数据拿来用，其代价往往只是一些指针变量的赋值。 

显而易见，如果有比较多的内存需要拷贝，移动对象的效率是更高很多的。  

下面举个例子证明以上的说法：   
源码可在此找到：https://github.com/antsmallant/antsmallant_blog_demo/tree/main/blog_demo/modern-cpp 。

```c++
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

```c++
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

最精准的分析需要看汇编代码，但汇编有点复杂，这里先不看，等下面描述 RVO 的时候再一并用汇编分析。   


## 返回值优化 RVO、NRVO
这是一种编译器优化

参考：编译器优化之 Copy Elison、RVO



### 编译器默认生成的移动（构造/赋值运算符）函数
如果我们没有自己写拷贝构造函数或拷贝赋值运算符，那么编译器会帮我们生成默认的。   

编译器在特定条件下，也会帮我们生成默认的移动函数[1]：
1. 一个类没有定义任何版本的拷贝构造函数、拷贝赋值运算符、析构函数；
2. 类的每个非静态成员都可以移动
    * 内置类型（如整型、浮点型）
    * 定义了移动操作的类类型

第1点，应该是确保系统可以生成符合程序员需要的移动函数，如果代码中定义了那三种函数，说明程序员有自己控制复制或释放的倾向，这时候编译器就不默认生成了。   
第2点，只有确保成员都可移动，才能生成正确的移动函数。  


### std::move
上面讲移动构造和移动赋值运算符的时候，发现由于编译器的优化：RVO，导致即使我们构造了合适的场景，也没能验证移动构造的使用。 

接下来介绍的 std::move，即使不屏蔽 RVO，也可以验证移动构造的使用，只需要这样修改 

```c++
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

特别注意，std::move **并不完成对象的移动**，它的作用只是把传递进去的**实参**转换成一个右值，可以理解它是某种 cast 封装，一种可能的实现如下[2]：   

```c++
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

```c++
int a = 100;
int&& r1 = std::move(a);    // 合法
int&& r2 = std::move(200);  // 合法
```

std::move 只是完成**类型转换**，真正起作用的是移动构造函数或移动赋值运算符函数，在这两个函数中写移动逻辑。   

综上，std::move 是一种危险的操作，调用时必须确认源对象没有其他用户了，否则容易发生一些意外的难以理解的状况。    

---

## 智能指针
指针太危险了，要写出安全的代码，我们必须花时间好好总结一下，有哪些特性可以帮助我们规避指针的危险。  

---

## const
const 在各个位置的意义？
成员函数末尾的 const
开头的 const

---

## constexpr

为何 constexpr 重要？ 

---

## 模板

---

## noexcept

---

# 常用优化手段

## Pimpl
Pimpl 惯用法通过降低类的客户和类实现者之间的依赖性，减少了构建的遍数。[2]  

## 减少临时对象
这是一个比较庞大的话题，前面介绍过的右值引用，移动语义，其目的都是为了减少临时对象。


---

# 内存安全的代码
TODO

---

# 内存越界、内存泄漏的解决方法

一方面我们要尽可能写出内存安全的方法，另一方面我们也要有手段来解决内存问题。有时候不是我们自己写的代码有内存问题，而是一些历史遗留代码或是粗心同事的代码。   

## 洞察的方法


---

# todo
* const / constexpr
* 写一写智能指针
* 写一写thread / future / 协程 
详细阅读《modern effective c++》条款7的列表初始化



---

# 拓展阅读

* Bjarne Stroustrup 的 HOPL4 论文原文： BJARNE STROUSTRUP. Thriving in a Crowded and Changing World: C++ 2006–2020. Available at: https://www.stroustrup.com/hopl20main-p5-p-bfc9cd4--final.pdf, 2021.       

* Bjarne Stroustrup 的 HOPL4 论文中文翻译：BJARNE STROUSTRUP. 在纷繁多变的世界里茁壮成长：C++ 2006–2020. Cpp-Club. Available at: https://github.com/Cpp-Club/Cxx_HOPL4_zh, 2021.    


---

# 总结
* c++ 太复杂了，好多人因为这个原因放弃了它，但依然很多人在使用它，说明它有独特的价值。   

* 在我看来，c++ 存在的价值在于弹性：它既有原始的部分，也有高级的部分；它能比其他语言让你更靠近机器去编程，去榨干机器的性能，也能让你在高一层的抽象维度去编程，忽略机器的细节。  

* c++ 的内存、指针都是危险的，所以我们很有必要花时间归纳总结如何写出安全的代码。  

* c++ 跟其他语言一样，完成一件事有好几种写法，但有些写法效率是很高的，所以我们也有必要花时间归纳总结如何写出高效的代码。  

* 要真正掌握 c++ 的精髓，必然是要了解它的底层实现（比如看透这本书《inside the c++ object model》），要能读懂一段代码翻译成汇编是什么样子的，是怎么工作起来的，了解了这些，也就差不多了解了计算机是怎么工作的。  

* 不清楚一个特性的时候先不要使用它，否则反而坑到自己，但也不要固步自封，要积极去学习和掌握 c++ 新版本的新特性，这些都可能带来生产力的提升。   



---

# 参考
[1] 王健伟. C++新经典. 北京: 清华大学出版社, 2020-08-01.   

[2] [美]Scott Meyers. Effective Modern C++(中文版). 高博. 北京: 中国电力出版社, 2018-4: 149, 151.  

[3] [美] Stanley B. Lippman, Josée Lajoie, Barbara E. Moo. C++ Primer 中文版（第 5 版）. 王刚, 杨巨峰. 北京: 电子工业出版社, 2013-9: 120, 154, 182.   

[4] Bjarne Stroustrup. C++11：感觉像是门新语言. Cpp-Club. Available at : https://github.com/Cpp-Club/Cxx_HOPL4_zh/blob/main/04.md, 2023-6-11.    

[5] Wikipedia. C++14. Available at: https://zh.wikipedia.org/wiki/C++14.   

[6] 玩转Linux内核. 快速入门C++17：了解最新的语言特性和功能. Available at: https://zhuanlan.zhihu.com/p/664746128, 2023-11-06.    

[7] AnthonyCalandra. modern-cpp-features:CPP20. Available at: https://github.com/AnthonyCalandra/modern-cpp-features/blob/master/CPP20.md, 2023-3-19.   

[8] cppreference. C++23. Available at: https://zh.cppreference.com/w/cpp/23, 2024-3-3.   