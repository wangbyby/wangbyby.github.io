---
title: "rpo"
date: 2026-04-28

---



这里首先需要区分下树和图的遍历，只考虑dfs方式

# 树

以二叉树为例子：
dfs有pre-order，in-order，post-order。

# 图

>只考虑有向图，一个start节点

## 拓扑排序

考虑到图可能存在环，问题会有些复杂。

1. 先考虑拓扑排序，有两种情况
- DAG情况（无环），不断删除入度为0的节点或者用 reverse post order方式。

```txt

图1:
    Entry
    /    \
    A    B
    \   /
    Exit

```

pre-order: [Entry, A, Exit, B]
post-order: [Exit, A, B, Entry]
reverse-post-order（RPO）：[Entry, B, A, Exit]就是这个DAG的拓扑排序。
>RPO还是和pre-order不一样的。

- 有环（loop）：其实就没拓扑排序的概念了，这个循环是绕不开的。

```txt
图2:
        Entry
          │
          ▼
          A ◄────┐
        ↙   ↘    │
       B     C   │
       │     │   │
       │     ▼   │
       │     D   │
       │     │   │
       │     ▼   │
       │     E   │
        ↘   ↙    │
          F ─────┘ (back edge F → A)
          │
          ▼
         Exit
```

pre-order: [Entry, A, B, F, Exit, C, D, E]
post-order: [Exit, F, B, E, D, C, A, Entry]
reverser-post-order: [Entry, A, C, D, E, B, F, Exit]

# 数据流分析

有两种信息的流向
1. 前向，从entry到exit，例如图2从A->B, A->C
2. 后向，从exit到entry, 例如图2从B->A, C->A


对于图1，一次RPO就能完成前向分析。对于图2，一次RPO不能迭代到不动点，所以还是需要多次迭代。
至于后向分析，有两种思路1.对原图进行post order；2.对源图求逆，然后进行rpo[1](https://eli.thegreenplace.net/2015/directed-graph-traversal-orderings-and-applications-to-data-flow-analysis/)。

```txt
图3:

A  --> B --> D
      | ^
      v |
       C


---------------------

图4：

A  <-- B <--- D
      ^ |
      | v
       C

```

图4是图3的逆, 
对图3进行post-order：D，C，B，A。
对图4进行RPO：D，B，C，A     

## 性能

不管前向后向，顺序遍历肯定是可行方法。
```cpp
bool changed = false;
do{
    chaneged = false;
    for(auto block: func) {
        changed |= ...
    }
}while(changed)
```

对于前向分析，DAG情况下RPO肯定块，loop情况下我没实测过，但考虑到分支众多，RPO`应该`比顺序遍历要快吧。
逆向分析下，我也没测试过。。。


# 参考

https://eli.thegreenplace.net/2015/directed-graph-traversal-orderings-and-applications-to-data-flow-analysis/

