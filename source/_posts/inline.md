---
title: "inline"
---

内联,重要性不必多说。

基本思路不是很难，

1. module层面构建call graph
2. 根据call graph根据SCC（强连通分量
3. 遍历SCC尝试内联（注意递归函数） 在同一个SCC里面就是一个递归链
4. 决定内联时候：
   1. clone被内联函数，用valuemap[old] = new记录映射情况。
   2. 被clone内容加入caller中
   3. 更新下ssa的def use chain。

主要是各种cost和gain的评估，各种启发式。

