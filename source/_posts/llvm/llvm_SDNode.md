---
title: "llvm SDNode 介绍"
date: 2025-05-10

---

>指令选择

## 1. 数据结构与内存布局


问题是指针指向关系是前向还是后向？
后向，其实是双向。
operands指向def。但是SDUse其实是个双向链表。


## 2. SelectionDAG 结构介绍

> 作用域：block level

以这段IR为例：(参考[^1])
```IR
then:
	%y = add i32 %a, 5
	%z = mul i32 %y, 3
	br label %join
```


内存占用有点过于大了。。。
[[llvm_SDNode_draw.excalidraw]]
>SDUse和llvm::Use同理

- chain：用于规定执行顺序
- glue：表示紧密耦合，不能被调度分开。比如ADC进位。
- EntryToken 作为block开始
- `-mllvm -debug-only=isel`打印文本形态的DAG
- `-mllvm -view-isel-dags`打印dot格式的DAG，GraphRoot节点其实是Printer添加的。

N：参考

[^1]: [MacLean-Fargnoli-ABeginnersGuide-to-SelectionDAG.pdf](https://llvm.org/devmtg/2024-10/slides/tutorial/MacLean-Fargnoli-ABeginnersGuide-to-SelectionDAG.pdf)
