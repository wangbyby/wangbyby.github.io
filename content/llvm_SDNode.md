

+++
title = "llvm SDNode 介绍"

+++

>指令选择

## 1. 数据结构与内存布局

内存结构如下：

问题是指针指向关系是前向还是后向？


## 2. SelectionDAG 算法介绍

> 作用域：block level

以这段IR为例：(参考[^N.1])
```IR
then:
	%y = add i32 %a, 5
	%z = mul i32 %y, 3
	br label %join
```


内存占用有点过于大了。。。
[[llvm_SDNode_draw]]


N：参考

1.  [MacLean-Fargnoli-ABeginnersGuide-to-SelectionDAG.pdf](https://llvm.org/devmtg/2024-10/slides/tutorial/MacLean-Fargnoli-ABeginnersGuide-to-SelectionDAG.pdf)