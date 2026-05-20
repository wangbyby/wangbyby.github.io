
---
title: "LLVM Inst Schedule"
date: 2026-03-10
---

# LLVM 指令调度

有作用在SelectionDAG和MachineInstr的指令调度。并将调度策略和调度框架分离。

## 结构
1. SDep代表一个依赖关系
2. SUnit代表一个基本单元。
3. ScheduleDAG，调度DAG的基类。https://llvm.org/doxygen/classllvm_1_1ScheduleDAG.html
use-def

## ScheduleDAGSDNodes
作用在SelectionDAG上的。
主要在SelectionDAGISel::CodeGenAndEmitDAG()中使用。

## MachineScheduler/ScheduleDAGInstrs
>作用域：MachineBasicBlock。

伪代码如下：
```cpp

for(MBB:Func){
    calc MBBRegions 
    for(region: MBBRegions){
        schedule()
    }
}
schedule(){
    buildSchedGraph()
    initQueues()
    while(true){
        SUit * SU = SchedImpl->pickNode();
        moveInstruction()
        SchedImpl->schedNode()
        updateQueues()
    }
}

```
`std::unique_ptr<MachineSchedStrategy> SchedImpl;`
策略通过命令行MachineSchedOpt指定，例如`-misched=converge`，重写了pickNode等函数。

而Topdown，BottomUp等方向是在pickNode中使用，通过命令行`llvm::PreRADirection`等指定。





