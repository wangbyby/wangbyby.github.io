---
title: "GVN-PRE简介"
date: 2026-04-08
---

>参考 https://cs.wheaton.edu/~tvandrun/writings/cc04.pdf
>只考虑表达式，基于SSA

GVN是将Global value numbering，而PRE是Partial redundancy elimination。一个是值编号，一个是部分冗余消除。

GVN的思路简单，按照domtree进行深度优先遍历，记录每个block中表达式的编号，如果重复就删除重复的。
对如下ir
```ir
define i32 @foo(i32 %a, i32 %cond){
bb0:
    %add = add i32 %a, %a
    %c = icmp eq %cond, 0
    br %c, %bb1, %bb2
bb1:
    %a2 = add i32 %a, %a
    br %bb3

bb2:
    %a3 = add i32 %a, 1
    br %bb3
bb3:
    %phia = phi(%a2, %a3)
    ret i32 %phia
}
```
按照domtree进行遍历，bb0,bb1,bb2,bb3，有以下结果。
%a: v0
%cond: v1
%add: v2
%c:  v3
%a2: v2 (same as %add)
%a3: v4
%phia: v5

所以说%a2是冗余的值，可以删除掉。

----

PRE更加复杂一些。

在这个例子2里面，%sa和%a2重复，但bb1不dom bb3. 单纯GVN没法处理。
```ir
define i32 @bar(i32 %a, i32 %cond){
bb0:
    %c = icmp eq %cond, 0
    br %c, %bb1, %bb2
bb1:
    %a2 = add i32 %a, %a
    br %bb3

bb2:
    %a3 = add i32 %a, 3
    br %bb3
bb3:
    %phia = phi(%a2, %a3)
    %sa = add i32 %a, %a
    ret i32 %phia
}
```

PRE的算法有些复杂，这里先不介绍了。


# GVN-PRE

结合二者的优点，GVN简单，PRE能力强。
针对上面的例子2，如果用逆向数据流分析，将%sa从bb3放到bb0底部，那么也就能消除%a2了。

不过首先需要确定可用集合。就是在每个block最后，有哪些表达式可用。
还是按照GVN的思路，根据domtree遍历。
所以数据流公式就是
```
AVAIL_IN[b] = AVAIL_OUT[dom(b)]
AVAIL_OUT[b] = AVAIL_IN[b] U PHI_GEN[b] U TMP_EXP[b]

PHI_GEN就是phinode，TMP_EXP是b中定义的非phi节点。
```

然后因为需要逆向数据流分析（回想下liveness），所以
```txt
ANTIC_OUT[b] = 
    - for i in succ(b) { ∧ ANTIC_IN[i] } if |succ(b)| > 1
    - phi_translate( ANTIC_IN[succ(b)] ) if |succ(b)| =1

ANTIC_IN[b] = clean(ANTIC_OUT[b] U EXP_GEN[b] - TMP_GEN[b])


EXP_GEN就是value和指令右侧表达式的集合。
clean会删除掉依赖被killed的值
```
所以算法就是
1. 计算avail和antic集合
2. 处理hoist
        for b in blocks{
            if preds(b) < 2 
                continue
            for e in ANTIC_IN[b]:
                if e is avaiable in at least one predcessor, then insert e into predecessors where not avaiable.
        }
    (还有sink和hoist相反，原理类似)
3. 删除冗余表达式
