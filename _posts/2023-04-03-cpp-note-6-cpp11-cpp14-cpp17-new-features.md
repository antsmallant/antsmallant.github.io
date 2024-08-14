---
layout: post
title: "c++ 笔记六：c++11、c++14、c++17 的新特性"
date: 2023-04-03
last_modified_at: 2024-07-01
categories: [c++]
tags: [c++ cpp]
---

* 目录  
{:toc}
<br/>

本文记录 c++11、c++14、c++17 的新特性。  

* c++11 是一个 major 版本，带来了大量的新变化，在很多年的时间里，它也一直被称为 c++0x。  

* c++14 是一个 minor 版本，主要是对于 c++11 一些不完善之处的补充。  

* c++17 是一个 "中" 版本，它本来应该是一个 major 版本的，不过它也有不少的新变化。  

虽然每个版本单独一篇文章会更简练，但是有些特性在几个版本中会有演化和改进，放一起说会更集中一些，所以以下的描述并不一定会严格按照版本进行区分。    

而 c++20 又是一个 major 版本，变化太多了，所以另起一文记录。  

---

# 1. c++11 新的语言特性

**概览**  

参考自：[《c++11：感觉像是门新语言》](https://github.com/Cpp-Club/Cxx_HOPL4_zh/blob/main/04.md) [1]。   

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

---

## 强类型枚举 enum class

放在最前，这是我期待的特性，以前写 enum 的时候，就觉得特别不好，现在好了，非常对味。   

解决了 c style enum 的问题：隐式转换、无法指定基础类型、作用域污染。enum class 的用法是这样 [7]：  

```cpp
// 指定基础类型为 `unsigned int`
enum class Color : unsigned int { Red = 0xff0000, Green = 0xff00, Blue = 0xff };
// `Red` / `Green` 与 Color 中的定义不冲突
enum class Alert : bool { Red, Green };

Color c = Color::Red;  
```

---

## nullptr

`nullptr` 是 c++11 新引入的空指针字面值，用于代替 c style 的 `NULL` 宏，以解决 `NULL` 相关的歧义问题。    

`nullptr` 对应的类型是 `std::nullptr_t`，它可以隐性转换为任意指针类型，但不可隐性转换为整数类型或 `bool` 类型（`NULL` 可以，这也是它会造成歧义的原因）。  

比如这样： 

```cpp
void f(int);
void f(int*);

f(NULL);     // 错误，不确定调用哪个好
f(nullptr);  // 调用 f(int*)
```

值得指出的是，这篇文章 [《modern-cpp-features/CPP11.md》](https://github.com/AnthonyCalandra/modern-cpp-features/blob/master/CPP11.md#nullptr) 或 wikipedia 的词条 [《c++11/Null pointer constant and type》](https://en.wikipedia.org/wiki/C%2B%2B11#Null_pointer_constant) 都写到： "nullptr itself is of type std::nullptr_t and can be implicitly converted into pointer types, and unlike NULL, not convertible to integral types except bool"。  

但实际上，这与最终的标准 [《cppreference std::nullptr_t》](https://en.cppreference.com/w/cpp/types/nullptr_t) 是有出入的，`nullptr_t` 并不支持隐性转换到 `bool` 类型。    

>std::nullptr_t is the type of the null pointer literal `nullptr`. It is a distinct type that is not itself a pointer type or a pointer to member type. Prvalues of this type are null pointer constants, and may be implicitly converted to any pointer and pointer to member type.   

---

## initializer list

初始值列表，对应的标准库类型是 `std::initializer_list`，头文件是 `<initializer_list>`。  

它是一个代表数组的轻量级包装器，通常用于构造函数或函数参数中，以允许传递一个初始化元素列表。可以用花括号初始化来构造 `initializer_list`，比如 `{1,2,3}` 就创建了一个数字序列，它的类型为 `std::initializer_list<int>`。 

示例代码[7]：

```cpp
int sum(const std::initializer_list<int>& list) {
    int total = 0;
    for (auto& e : list) {
        total += e;
    }
    return total;
}

auto list = {1,2,3};  // list 推导出来的类型是 std::initializer_list<int>
sum(list);    // 结果是 6
sum({1,2,3}); // 结果是 6
sum({});      // 结果是 0
```

有了 `initializer_list` 之后，标准库的一些容器就可以支持使用这种类型来构造，比如 `std::vector`，在 c++11 后，加入了这样的构造函数，`vector( std::initializer_list<T> init, const Allocator& alloc = Allocator() )`。  

可以这样构造一个 `vector` ：`std::vector<int> v {1,2,3}` 或 `std::vector<int> v = {1,2,3}`，效果都一样。  

另外，要注意，`initializer_list` 中的值都是常量。  

---

## auto

auto 声明的变量的类型可以由编译器根据初化值进行类型推导(deduce)，这个是在编译期间决定的。  

示例[7]：   

```cpp
auto a = 3.14;  // double
auto b = 1; //int
auto& c = b; // int&
auto d = { 0 };  // std::initializer_list<int>
auto&& e = 1;  // int&&
auto&& f = b;  // int&
auto g = new auto(123); // int*
const auto h = 1; // const int
auto i = 1, j = 2, k = 3;  // int, int, int
auto l = 1, m = true, n = 1.61;  // 错误，`l` 推导为 int，但 `m` 是一个 bool，推导结果不一致
auto o;  // 错误，需要给出初始化值
```

可以用于声明容器的 iterator 变量，代码简洁很多[7]：   

```cpp
std::vector<int> vec {1,2,3};
std::vector<int>::iterator oldstyle_iter = vec.begin(); // 旧的方式
auto iter = vec.begin();  // 新的方式比旧的方式简洁特别多
```

也可以用于推导函数的返回值，比如这样： 

```cpp
// in c++11
auto f(int a, int b) -> decltype(a+b) {
    return a+b;
}
```

但看起来挺麻烦的，还不如不要这么写。不过，在 c++14 中，就可以省掉后面的 `decltype` 了，c++14 支持 "return value deduce" 了。直接这样就行： 

```cpp
// in c++14
auto f(int a, int b) {
    return a+b;
}
```

使用 `auto` 的原则：能一眼看出是什么类型的就用 `auto`，否则不用。比如 Stroustrup 举的这个例子[1]： 

```cpp
auto n = 1;  // 很好：n 是 int
auto x = make_unique<Gadget>(arg);  // 很好：x 是 std::unique_ptr<Gadget>
auto y = flopscomps(x, 3);          // 不好：flopscomps() 返回的是什么东西？  
```

---

## decltype

---

## noexcept

有两个用法，一个是作为标识符 (specifier)，一个是作为运算符 (operator)。作为标识符的时候是表明此函数不会抛出异常，作为运算符的时候是判断一个函数是否会抛出异常。   

1、作为标识符    

specification: [https://en.cppreference.com/w/cpp/language/noexcept_spec](https://en.cppreference.com/w/cpp/language/noexcept_spec) 。  

<br/>

2、作为运算符的   

specification: [https://en.cppreference.com/w/cpp/language/noexcept](https://en.cppreference.com/w/cpp/language/noexcept) 。 

---

## 显式指定虚函数 override

显式的指定此函数重写了基类的虚函数。用于确保：1）此函数是虚函数，2）正在重写基类对应的虚函数。  

示例[7]：  

```cpp
struct A {
    virtual void foo();
    void bar();
    virtual ~A(); 
};

struct B : A {
    void foo() override; // 正确，B::foo 重写了 A::foo
    void bar() override; // 错误，A::bar 不是一个虚函数
    void baz() override; // 错误，A::baz 不存在
    ~B() override;       // 正确，override 也可以特别的虚函数，比如虚析构
};
```

另外，`override` 不是关键字，所以可以用它作为变量名，比如 `int override = 40;`。  

---

## final 标识符

用于标识一个虚函数不能被重写 (override)，或者标识一个类不能被继承 (inherited from)。 

示例1，final 修改虚函数 [7]：

```cpp
struct A {
    virtual void f();
};

struct B {
    virtual void f() final;
};

struct C : public B {
    virtual void f(); // 报错，f 在 B 中被标识为 final，不能被重写
}
```

示例2，final 修改类 [7]:  

```cpp
struct A final {};
struct B : A {}; // 报错，A 已经标为 final 了，不能被继承
```

---

## long long

正式加入 long long，表示 (at leatst) 64 位的整数。整数类型及对应的宽度规定如下，参考自 [cppreference types](https://en.cppreference.com/w/cpp/language/types) [5]：  

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/cpp-integral-type-width.png"/>
</div>
<center>图x：整数类型及其宽度规定</center>
<br/>

LP32 / LP64 之类的代表 data model，规定如下，参考自 [wikipedia 64-bit data models](https://en.wikipedia.org/wiki/64-bit_computing#64-bit_applications) [6]:   

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/cpp-integral-64bit-data-model.png"/>
</div>
<center>图x：整数数据模型</center>
<br/>

I 表示 int，L 表示 long，LL 表示 long long，P 表示 pointer。  

LP32 表示 long、pointer 的宽度是 32 位。    
ILP32 表示 int、long、pointer 的宽度是 32 位。   
ILP64 表示 int、long、pointer 的宽度是 64 位。  
LLP64 表示 long long、pointer 的宽度是 64 位。  
LP64 表示 long、pointer 的宽度是 64 位。  

---

## 万能引用与完美转发

---

### 万能引用

万能引用 (universal reference) 是 c++11 才引入的，在 c++17 的标准里面已经将这种用法标准化为 “转发引用” (forwarding reference) [3]，引用如下：    

>In the absence of our giving this construct a distinct name, the community has been trying to make one. 
The one that is becoming popular is “universal reference.” Unfortunately, as discussed in §3.1 below, 
this is not an ideal name, and we need to give better guidance to a suitable name.   
>    
>The name that has the most support in informal discussions among committee members, including the 
authors, is “forwarding reference.” Interestingly, Meyers himself initially introduced the term “forward
ing reference” in his original “Universal References” talk, but decided to go with “universal references” 
because at the time he did not think that “forwarding references” reflected the fact that auto&& was also 
included; however, in §3.3 below we argue why auto&& is also a forwarding case and so is rightly included.   

<br/>

万能引用是一种特别的引用，它能够保留实参的 value category，使得可以通过 `std::forward` 转发实参的 value category[2]。不要以为 `&&` 只用于右值引用，它也被用于表示万能引用，理解这一点很关键，不然会被搞得很糊涂。   

万能引用目前有两种场景：       

* 场景一：作为函数模板的形参    

精确的定义是：“function parameter of a function template declared as rvalue reference to cv-unqualified type template parameter of that same function template”[2]。  

示例[2]：  

```cpp
template<class T>
int f(T&& x) {                     // x 是万能引用
    return g(std::forward<T>(x));  // 可以被转发
}

int main() {
    int i;
    f(i);    // 参数是左值，调用 f<int&>(int&)，std::forward<int&>(x) 是左值
    f(0);    // 参数是右值，调用 f<int>(int&&)，std::forward<int>(x) 是右值
}

template<class T>
int g(const T&& x);  // x 不是万能引用，因为 const T 不是 cv-unqualified（即无 const/volatile 修饰）的

template<class T>
struct A {
    template<class U>
    A(T&& x, U&& y, int* p);  // x 不是万能引用，因为 T 不是构造函数的模板参数
                              // y 是万能引用
}
```

万能引用的两个判断标准： 
1）必须是类型推导；   
2）形式上必须是 T&&； 

像这样就不是类型推导[4]:   

```cpp
void f(Widget&& param);
```

像这样就是严格的 `T&&` 形式[4]：   

```cpp
template<class T>
void f(std::vector<T>&& param); // param 不是万能引用，是右值引用
```

<br/>

* 场景二：`auto&&`     

`auto&&` 除了花括号初始化的情况之外都是万能引用。 

示例[2]：  

```cpp
auto && vec = foo();      // vec 是万能引用，foo() 可能是左值或右值
auto i = std::begin(vec); // 正常工作，无论 vec 最终是左值引用或是右值引用
(*i)++;                   // 正常工作，无论 vec 最终是左值引用或是右值引用

g(std::forward<decltype(vec)>(vec)); // 转发（保留了 vec 的值类别）

for (auto&& x : f()) {
    // x 是万能引用，这是使用 for range 遍历的通用形式
}

auto&& z = {1, 2, 3}; // 不是万能引用，这是初始值列表的特殊情况
```

<br/> 

**拓展阅读**   

* [《Universal References in C++11 -- Scott Meyers》](https://isocpp.org/blog/2012/11/universal-references-in-c11-scott-meyers)   
  
* [《C++中的万能引用和完美转发》](https://theonegis.github.io/cxx/C-%E4%B8%AD%E7%9A%84%E4%B8%87%E8%83%BD%E5%BC%95%E7%94%A8%E5%92%8C%E5%AE%8C%E7%BE%8E%E8%BD%AC%E5%8F%91/)   

---

### 完美转发 

完美转发是为了帮助撰写接受任意实参的函数模板，并将其转发到其他函数，目标函数会接受到与转发函数所接受的完全相同的实参[4]。也就是说，它能够转发形参的 value category。  

value category 是一个一直存在的概念，任何一个变量都有两大属性：1）basic type ；2）value category。 value category 经过 c++11 规范后，包括左值、右值、将亡值、纯右值、广义左值这些概念。   

实现完美转发依赖于函数 `std::forward`，它的工作逻辑是这样的：如果入参的 value category 是右值，它就强制转换为右值引用并返回，否则，它不做转换。  

理解这一点的前提是要知道，形参总是左值，只不过它的类型是右值引用。比如这样：   

```cpp
template<typename T>
void f(T&& t) {
    g(t);  // 此时调用的是 g(T& t) 版本; 因为 t 作为形参，它本身就是个左值。  
}

void g(T& t) {
    std::cout << "g 左值引用版本" << std::endl;
}

void g(T&& t) {
    std::cout << "g 右值引用版本" << std::endl;
}
```

要能够调用 `g(T&& t)`，需要这样：  

```cpp
template<typename T>
void f(T&& t) {
    g(std::forward(t));   // std::forward 转发了 t 的 value category，如果 t 确实是一个右值
}
```

`std::forward` 与 `std::move` 的行为很像，都是将表达式强制转换为右值引用。但前者是有条件的，只会把原本是右值引用的表达式强制转换为右值引用，而后者是无条件的。  

---

### 引用折叠

其实引用折叠才是最关键的，不知道或不理解引用折叠，永远无法理解 `std::forward` 是怎么工作的。   

实参在传递给函数模板的时候，如果形参是万能引用，那么在推导的时候，就会把实参是左值还是右值的信息编码到推导出来的模板形参中。  

编码的机制也很简单，如果实参是左值，则推导结果是左值引用类型；如果实参是右值，则推导结果是非引用类型。[4]      

比如对于这种形式：  

```cpp
template<class T>
inf f(T&& x) {
    return g(std::forward<T>(x));
}

int i = 10;
f(i);  
```

执行 `f(i)` 的时候，`i` 对应的形参 `x` 是一个万能引用，那么就需要把 `i` 是左值的信息编码到推导出来的 `x` 的推导结果中。此时，T 的推导结果是 `int&`，产生的模板实例是： `f<int&>(int& && x);`。   

但这种 "reference-to-reference" （引用的引用） 有意义吗？ `int& && x` 是合法的存在吗？  

c++ 是禁止这么使用的，不允许用户这么写，但却允许编译器在特定的场合产生这种 “引用的引用”，模板实例化就是这种场合之一。  

c++11 引入了对于 reference-to-reference 的处理，在模板实例化的时候，进行 "reference collasping"（引用折叠）。对 `int& && x` 进行处理后的结果是 `int& x`，即消除掉了 `&&`。   

实际上，左值与右值组合起来共用4种，`& &&`、`& &`、`&& &&`、`&& &`，上面是属于 `& &&`。引用折叠的规则是这样的，只有 `&& &&` 是折叠成 `&&` 的，其他三种都是折叠成 `&`。举例：  

`int& && x`  折叠成 `int & x`；    
`int& & x`   折叠成 `int & x`；   
`int&& & x`  折叠成 `int & x`；   
`int&& && x` 折叠成 `int && x`；      

引用折叠发生的四种情形[4]：模板实例化；auto 类型生成；创建和运用 `typedef` 和别名声明；`decltype`。    

关于 `auto&&` 的类型推导与引用折叠，举例如下[4]：  

```cpp

Widget getWidget();
Widget w;

auto&& w1 = w;    // w1 的类型是 Widget& 。由于 w 是左值，此时 auto 被推导为 Widget&，
                  // 代入得 Widget& && w1 = w;，引用折叠后是 Widget& w1 = w 。

auto&& w2 = getWidget(); // w2 的类型是 Widget&& 。由于 getWidget() 返回了右值，此时 auto 被推导为 Widget，
                         // 代入得 Widget&& w2 = w，不需要引用折叠。  
```

<br/>

**拓展阅读**  

* 《modern effective c++》[4] 的条款 28，此书有纸质版，也有网友翻译的版本，见：[条款二十八：理解引用折叠](https://github.com/CnTransGroup/EffectiveModernCppChinese/blob/master/src/5.RRefMovSemPerfForw/item28.md) 。    

---

# 2. c++11 新的库特性

**概览**  

---

## std::array


---

# 3. c++14 新的语言特性

---

# 4. c++14 新的库特性

---

# 5. c++17 新的语言特性

---

# 6. c++17 新的库特性

---

# 7. 拓展阅读

* [modern-cpp-features 11/14/17/20 by AnthonyCalandra](https://github.com/AnthonyCalandra/modern-cpp-features/tree/master)

---

# 8. 参考

[1] Bjarne Stroustrup. c++11：感觉像是门新语言. Cpp-Club. Available at : https://github.com/Cpp-Club/Cxx_HOPL4_zh/blob/main/04.md, 2023-6-11.   

[2] cppreference. Forwarding references. Available at https://en.cppreference.com/w/cpp/language/reference#Forwarding_references.   

[3] open-std. Forwarding References. https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2014/n4164.pdf.   

[4] [美]Scott Meyers. Effective Modern C++(中文版). 高博. 北京: 中国电力出版社, 2018-4.  

[5] cppreference. types. Available at https://en.cppreference.com/w/cpp/language/types.    

[6] wikipedia. 64-bit computing. Available at https://en.wikipedia.org/wiki/64-bit_computing#64-bit_data_models.    

[7] AnthonyCalandra. C++11. Available at https://github.com/AnthonyCalandra/modern-cpp-features/blob/master/CPP11.md.    