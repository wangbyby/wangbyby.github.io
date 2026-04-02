TODO

+++
title = "LLVM Schedule"

+++

# LLVM 指令调度

有作用在SelectionDAG和MachineInstr的指令调度。并将调度策略和调度框架分离。

## 结构
1. SDep代表一个依赖关系
2. SUnit代表一个基本单元。
3. ScheduleDAG，调度DAG的基类。https://llvm.org/doxygen/classllvm_1_1ScheduleDAG.html

## ScheduleDAGSDNodes
作用在SelectionDAG上的。
主要在SelectionDAGISel::CodeGenAndEmitDAG()中使用。

## MachineScheduler
>作用域：MachineBasicBlock。


以AArch64 O2下的pipeline为例。
>Pass Arguments:  -tti -targetlibinfo -assumption-cache-tracker -targetpassconfig -machinemoduleinfo -profile-summary-info -tbaa -scoped-noalias-aa -collector-metadata -machine-branch-prob -regalloc-evict -regalloc-priority -domtree -basic-aa -aa -objc-arc-contract -pre-isel-intrinsic-lowering -expand-large-div-rem -expand-large-fp-convert -atomic-expand -simplifycfg -domtree -loops -loop-simplify -lazy-branch-prob -lazy-block-freq -opt-remark-emitter -scalar-evolution -loop-data-prefetch -aarch64-falkor-hwpf-fix -basic-aa -loop-simplify -canon-freeze -iv-users -loop-reduce -basic-aa -aa -mergeicmps -loops -lazy-branch-prob -lazy-block-freq -expand-memcmp -gc-lowering -shadow-stack-gc-lowering -lower-constant-intrinsics -unreachableblockelim -loops -postdomtree -branch-prob -block-freq -consthoist -replace-with-veclib -partially-inline-libcalls -expandvp -post-inline-ee-instrument -scalarize-masked-mem-intrin -expand-reductions -loops -tlshoist -aarch64-globals-tagging -stack-safety -domtree -basic-aa -aa -aarch64-stack-tagging -complex-deinterleaving -aa -memoryssa -interleaved-load-combine -domtree -interleaved-access -aarch64-sme-abi -domtree -loops -type-promotion -codegenprepare -domtree -dwarf-eh-prepare -aarch64-promote-const -global-merge -callbrprepare -safe-stack -stack-protector -domtree -basic-aa -aa -loops -postdomtree -branch-prob -debug-ata -lazy-branch-prob -lazy-block-freq -aarch64-isel -machinedomtree -aarch64-local-dynamic-tls-cleanup -finalize-isel -lazy-machine-block-freq -early-tailduplication -opt-phis -slotindexes -stack-coloring -localstackalloc -dead-mi-elimination -machinedomtree -aarch64-condopt -machine-loops -machine-trace-metrics -aarch64-ccmp -lazy-machine-block-freq -machine-combiner -aarch64-cond-br-tuning -machine-trace-metrics -early-ifcvt -aarch64-stp-suppress -aarch64-simdinstr-opt -aarch64-stack-tagging-pre-ra -machinedomtree -machine-loops -machine-block-freq -early-machinelicm -machinedomtree -machine-block-freq -machine-cse -machinepostdomtree -machine-cycles -machine-sink -peephole-opt -dead-mi-elimination -aarch64-mi-peephole-opt -aarch64-dead-defs -detect-dead-lanes -init-undef -processimpdefs -unreachable-mbb-elimination -livevars -phi-node-elimination -twoaddressinstruction -machinedomtree -slotindexes -liveintervals -register-coalescer -rename-independent-subregs -machine-scheduler -aarch64-post-coalescer-pass -machine-block-freq -livedebugvars -livestacks -virtregmap -liveregmatrix -edge-bundles -spill-code-placement -lazy-machine-block-freq -machine-opt-remark-emitter -greedy -virtregrewriter -regallocscoringpass -stack-slot-coloring -machine-cp -machinelicm -aarch64-copyelim -aarch64-a57-fp-load-balancing -removeredundantdebugvalues -fixup-statepoint-caller-saved -postra-machine-sink -machinedomtree -machine-loops -machine-block-freq -machinepostdomtree -lazy-machine-block-freq -machine-opt-remark-emitter -shrink-wrap -prologepilog -machine-latecleanup -branch-folder -lazy-machine-block-freq -tailduplication -machine-cp -postrapseudos -aarch64-expand-pseudo -aarch64-ldst-opt -kcfi -aarch64-speculation-hardening -machinedomtree -machine-loops -aarch64-falkor-hwpf-fix-late -postmisched -gc-analysis -machine-block-freq -machinepostdomtree -block-placement -fentry-insert -xray-instrumentation -patchable-function -aarch64-fix-cortex-a53-835769-pass -funclet-layout -stackmap-liveness -livedebugvalues -machine-sanmd -machine-outliner -aarch64-sls-hardening -aarch64-ptrauth -aarch64-branch-targets -branch-relaxation -aarch64-jump-tables -cfi-fixup -lazy-machine-block-freq -machine-opt-remark-emitter -stack-frame-layout -unpack-mi-bundles -lazy-machine-block-freq -machine-opt-remark-emitter
>只有一个machine-scheduler，源码在llvm/lib/CodeGen/MachineScheduler.cpp

将Block划分为SchedRegion，每个SchedRegion对应N条MachineInstr，然后在Region中有scheduler进行指令调度。

而AArch64后端中使用createPostMachineScheduler创建了AArch64PostRASchedStrategy作为scheduler。
>其继承体系如下：https://llvm.org/doxygen/classllvm_1_1MachineSchedStrategy.html


>好复杂的算法和实现。但奇怪的是之前测试CPU2017，各种调度算法影响不大。当然了设置sched.td还是必要的。

