---
title: "llvm寄存器分配2"
date: 2026-03-22

---

# greedy

greedy以RegallocBase为基础。
每个要被分配的虚拟寄存器有这几个阶段。
```cpp
enum LiveRangeStage {
  RS_New,       // 初始状态
  RS_Assign,    // 尝试分配一个物理寄存器
  RS_Split,     // 分配失败，拆分生命周期来尝试分配
  RS_Split2,    // Split分配失败，再次拆分尝试分配
  RS_Spill,     // 分配失败，溢出到memory
  RS_Done       // 结束
};
```
greedy核心就是细化live range分配，然后用高优先级抢占低优先级分配。


```cpp
selectOrSplitImpl
    tryAssign
    tryEvict
    trySplit
    tryLastChanceRecoloring
    spill
```

- tryEvict
```cpp
tryEvict
    tryFindEvictionCandidate // 尝试找到能被抢占的物理寄存器
    evictInterference        // 更新信息
```
实际由DefaultEvictionAdvisor实现在llvm/lib/CodeGen/RegAllocEvictionAdvisor.cpp中。

- trySplit分为几部分，
1. 寄存器仅在单个block中，使用tryLocalSplit+tryInstructionSplit处理
2. 在Split2阶段前，用tryRegionSplit。        
    - calculateRegionSplitCost
        calculateRegionSplitCostAroundReg
            addSplitConstraints构建hopfield网络
            grow Region中进行迭代
    - doRegionSplit

3. 最后用tryBlockSplit。将live range拆分为single block块。

- tryLastChanceRecoloring

todo

- spill。llvm/lib/CodeGen/InlineSpiller.cpp:InlineSpiller
    1. collectRegsToSpill
    2. reMaterializeAll 重物化，就是重新计算一遍该值。
    3. spillAll

