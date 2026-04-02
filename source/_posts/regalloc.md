---
title: "寄存器分配简介"
---


> 寄存器分配简介

# 前置技术 Liveness Analysis， Live Interval, reaching define

## Liveness Analysis

经典的数据流分析, 后向(倒序)分析.

```txt

live_out[b] = ⋃ (live_in[s] for s ∈ succ(b))
live_in[b]  = use[b] ∪ (live_out[b] − def[b])

```

## live interval

llvm依赖这个，就是 def-use 分段.

## reaching define 到达定值

就是某个定义点可以到达什么地方，前向分析。
实现上可以用bitset或者set.

图着色会用到。每次define就生成一个新的ID。

```txt

b0:
  v1 = ...
  br b2

b1:
  v1 = ... 
  br b2

b2:
  print(v1)


```
对其进行def标号后就是
```txt

b0:
  v1 = ... ; {d1:v1, } bitset= <10>
  br b2

b1:
  v1 = ... ; {d2:v1, } bitset= <01>
  br b2

b2:
  print(v1)  ; {d1:v1, d2:v1} bitset= <11>

```

-----------

首先, 下面介绍的寄存器分配针对的IR都是非SSA的.
基于SSA来实现的寄存器分配, emm, 没见过. 
考虑以下问题: call中abi定义, two address inst, flag的隐式定义.


# 全局的图着色

参考"高级编译器设计与实现" 16章.

```txt

fn alloc_reg(){
    bool success = false;
    do{
        bool coalesce = false;
        do{
            make_web()
            build_adj_matrix()
            coalesce = coalesce_regs()
        }while(!coalesce);

        build_adj_list()
        compute_spill_costs()
        prune_graph()
        success = assign_regs()
        if(success){
            modify_code()
        }else{
            gen_spill_code()
        }

    }while(!success);
}

```

迭代到不动点. 

## 1. make web

web构造有两种方式
1. 基于 reaching def的结果来构造. 
    - 先构造duchain
    - 基于duchain构造web
2. 直接构造,每个虚拟寄存器就是一个web节点

```txt

b0:
2:  v1 = ...
4:  br b2

b1:
6:  v1 = ... 
8:  br b2

b2:
10:  print(v1)
12:  v1 = ...
14:  print(v1)

```

第一种方式: (参杂了live range信息)
name, defs,  uses
web1, {2, 6}, {10} 
web2, {12},   {14}

第二种方式:
web1: {2,6,12}, {10, 14}



## 2. build_adj_matrix

算法核心, 使用下三角邻接矩阵.
关键是如何判定两个web是否干涉. 
如果用 Reaching def会有很多假阳性出现. 所以需要liveness来判定.


## 3. coalesce_regs

会尝试消除一些 `a = copy b`的指令

## 4. build_adj_list

基于邻接表就行

## 5. compute_spill_costs

启发式算法
1. loop depth
2. block frequency
3. num of uses

## 6. prune_graph

算法的核心. 这一步是将web构成的冲突图排列到一个栈里面, 供`assign_regs`使用.
有`<R`的乐观算法, 选择 `<R`的节点开始染色. 或者用乐观的启发式算法,删除`度>=R`的节点推广 `<R`.

## 7. assign_regs
给web赋值颜色. 不是真正的修改指令.

```txt

success: bool = true
while !stack.empty()
    web = stack.pop()
    c = min_color(web)
    if c > 0
        adjList[web].color = c
    else
        adjList[web].spill = true
        success = false

return success
```

## 8. modify code
就是很直接的重写

## 9. gen_spill_code

简单来说在def 后生成 store, 在use之前生成load.
注意, 图着色这里是针对所有已经标记为 spill的web进行溢出.


## 总结

不难看出图着色还是比较耗时的. reaching define的计算, adj matrix的计算, 再加上迭代到不动点. 
生成的代码质量上, 对live range建模不太完善, spill判定也比较简单.

# linear scan

从live range出发看待寄存器分配问题. 参考Linear scan register allocation.


```txt

reg_alloc(){
  do_instruction_order()
  l =  do_live_intervals_calc()
  l.sort_by_start_point()
  linear_scan(l)

}

linear_scan(live_intervals l){
  active = []
  for live_interval i : l{
    expireOld(i)
    if active.size() == R {
      spillAt(i)
    }else{
      register[i] = free_register.pop()
      active.push(i)
    }
  }
}

expireOld(i){
  for live_interval j in ( active in order of increasing end point ) {
    if j.end >= i.start {
      return 
    }
    remove j from active
    free_register.push(add j.register)
  }
}

spillAt(i){ // 启发式算法
  spill = active.last()
  if spill.end > i.end {
    i.register = spill.register
    spill.location = new stack location

    active.remove(spill)

    active.push(i)
    active.sort_by_end()
  }else{
    i.location = new stack location
  }
}

```

1. instruction order 不影响结果正确性,可能影响代码质量
2. active最大长度是R
3. spill的依据是启发式算法, 论文里面就是根据live range长度进行判定

改进点:
1. live intervals太宽泛,可以利用某些空洞
2. spill计算太简陋, 可以结合更多信息
3. copy coalescing, 尝试删除`a = copy b`这样的复制指令


# 参考

1. 高级编译器设计与实现
2. https://www.cnblogs.com/AANA/p/16315859.html
3. https://www.cnblogs.com/hsyluxiaoguo/p/18902335
4. Massimiliano Poletto and Vivek Sarkar. 1999. Linear scan register allocation. ACM Trans. Program. Lang. Syst. 21, 5 (Sept. 1999), 895–913. https://doi.org/10.1145/330249.330250, https://web.cs.ucla.edu/~palsberg/course/cs132/linearscan.pdf