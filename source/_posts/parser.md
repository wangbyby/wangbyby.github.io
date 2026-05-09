
---
title: "cpp template parser"
date: 2026-05-09

---


众所周知c/cpp的parser是上下文相关，边语义边语法。
cpp11之前经典parser笑话`A<A<int>> a`.

```cpp
template<typename T>
struct Container {};

int main() {
    Container<Container<int>> obj;  // 错误!
}
```
看下clang的输出`clang++ test-struct.cpp -Xclang -dump-tokens -v`
```txt
clang -cc1 version 17.0.0 (clang-1700.0.13.5) default target arm64-apple-darwin24.6.0
template 'template'      [StartOfLine]  Loc=<test-struct.cpp:33:1>
less '<'                Loc=<test-struct.cpp:33:9>
typename 'typename'             Loc=<test-struct.cpp:33:10>
identifier 'T'   [LeadingSpace] Loc=<test-struct.cpp:33:19>
greater '>'             Loc=<test-struct.cpp:33:20>
struct 'struct'  [StartOfLine]  Loc=<test-struct.cpp:34:1>
identifier 'Container'   [LeadingSpace] Loc=<test-struct.cpp:34:8>
l_brace '{'      [LeadingSpace] Loc=<test-struct.cpp:34:18>
r_brace '}'             Loc=<test-struct.cpp:34:19>
semi ';'                Loc=<test-struct.cpp:34:20>
int 'int'        [StartOfLine]  Loc=<test-struct.cpp:36:1>
identifier 'main'        [LeadingSpace] Loc=<test-struct.cpp:36:5>
l_paren '('             Loc=<test-struct.cpp:36:9>
r_paren ')'             Loc=<test-struct.cpp:36:10>
l_brace '{'      [LeadingSpace] Loc=<test-struct.cpp:36:12>
identifier 'Container'   [StartOfLine] [LeadingSpace]   Loc=<test-struct.cpp:37:5>
less '<'                Loc=<test-struct.cpp:37:14>
identifier 'Container'          Loc=<test-struct.cpp:37:15>
less '<'                Loc=<test-struct.cpp:37:24>
int 'int'               Loc=<test-struct.cpp:37:25>
greatergreater '>>'             Loc=<test-struct.cpp:37:28>
identifier 'obj'         [LeadingSpace] Loc=<test-struct.cpp:37:31>
semi ';'                Loc=<test-struct.cpp:37:34>
r_brace '}'      [StartOfLine]  Loc=<test-struct.cpp:38:1>
eof ''          Loc=<test-struct.cpp:38:2>
```
哦`>>`是一个整体

在叠加一下，如果是三个`>>>`会是什么样子
`Container<Container<Container<int>>> obj`
```txt
greatergreater '>>'		Loc=<test-struct.cpp:37:38>
greater '>'		Loc=<test-struct.cpp:37:40>
```
所以clang用了贪心策略。
> clang里面还会有greatergreatergreater，是cuda的'>>>'

但是明显'>>'在parser里面是不合适的.
clang是在`clang/lib/Parse/ParseTemplate.cpp:ParseGreaterThanInTemplateList`里处理，
将'>>'拆分为'>','>'然后塞回去一个。如果是'>>>'就拆为'>>','>' 然后将'>>'入队列，'>'是peeking。
