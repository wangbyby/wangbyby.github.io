---
title: "alias analysis简介"

---

# 0. 写这个文档的原因

因为最近遇到几个问题
1. 在llvm ir上，如何分析一个global variable有没有在程序中变化？
2. 在llvm ir上，如何能分析出来指针的address space (stack, heap, global variable).？ 

前提条件简点，假设我们在full lto模式下，不考虑类，但有函数指针。


因为设计到指针+function call，所以我们需要一个全局分析。
如果我想构建一个call graph，就遇到几个问题
1. 递归函数的处理
2. 函数指针，特别是在参数中传递的函数指针。
3. 上下文敏感与否？ 特别是函数调用栈
4. 控制流敏感与否？ 


3决定了call graph的数据结构如何。

问题1就是AA分析（point to），store指令，memset call等会写入内存的操作的dst与 global variable是否会指向同一个地址。
问题2是分析指针的address space而不是point to集合，简单一些但也需要Whole program分析。




# alias analysis 简介
可以看这篇综述。
- https://www.cse.psu.edu/~gxt29/papers/ShengHsiuLin_thesis.pdf

- alias analysis
The purpose of alias analysis is to determine all possible ways a program may access some given memory locations. A set of pointers are said to be in an alias group if they all point to the same memory locations.

- points-to: a sub-problem of alias analysis. Points-to analysis
computes sets of memory locations that each pointer may point to

可以简单分下类
- field-sensitive : struct x {int a; int b;} x.a和x.b的空间不重叠，int arr[10]; a[0], a[1]等地址不重叠
- Intra-procedural 函数内部  vs Inter-procedural 关注函数调用
- Context-Sensitivity. Context-sensitivity governs how function calls are analyzed

- Flow-Sensitivity. take care of the order of code or not

## 算法

1. Anderson's Points-to analysis. Inter-procedural, flow-insensitive, context-insensitive
2. Steensgaard's Points-to, Inter-procedural, flow-insensitive, context-insensitive


3. Data Structure Analysis. flow-insensitive but context-sensitive and field-sensitiv

 DSA is able to achieve a scalable and fast context-sensitive
and field-sensitive pointer analysis by giving up context-sensitivity within strongly connected
components of the call graph

DSA can be performed in three phases:
 (1) local analysis phase, 
 (2) bottom-up analysis phase
 (3) top-bottom analysis phase.

- In the local analysis phase, a Local Data Structure Graph is computed for each function. It is a summary of the memory objects accessible within the function.
- The bottom-up analysis phase inlines the caller DS graph with the callee’s information.
- The top-bottom phase fills in incomplete argument information by merging caller DS graphs with callee DS graphs

# 参考

- https://github.com/svf-tools/SVF
-  https://github.com/svf-tools/SVF/wiki/Analyze-a-Simple-C-Program
-  https://research.cs.wisc.edu/wpis/papers/tr1386.pdf
-  https://tai-e.pascal-lab.net/lectures.html
-  https://yuleisui.github.io/publications/fse16.pdf
- https://www.cse.psu.edu/~gxt29/papers/ShengHsiuLin_thesis.pdf
- https://www.cs.utexas.edu/~lin/papers/cgo11.pdf