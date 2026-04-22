
---
title: "llvm寄存器分配1"
date: 2026-03-22

---

接上一篇。
列举下RABasic需要的数据结构

- LiveRegMatrix， LiveIntervals， VirtRegMap， LiveIntervalUnion


- LiveIntervals

核心的查询接口。
1. VirtRegIntervals `Map<reg, LiveIntervals> `
2. RegMaskSlots 是用来储存哪些指令用了regmask（基本是call），在判断干涉时用到，按照slotindex排序
3. RegMaskBits，查询的cache
4. RegMaskBlocks： `Map<block, {begin, size}>` 这里的begin是RegMaskSlots的下标，即某个block对应哪些使用regmask的指令

```cpp

class LiveIntervals {
  MachineFunction *MF = nullptr;
  MachineRegisterInfo *MRI = nullptr;
  const TargetRegisterInfo *TRI = nullptr;
  const TargetInstrInfo *TII = nullptr;
  SlotIndexes *Indexes = nullptr;
  MachineDominatorTree *DomTree = nullptr;
  std::unique_ptr<LiveIntervalCalc> LICalc;

  /// Live interval pointers for all the virtual registers.
  IndexedMap<LiveInterval *, VirtReg2IndexFunctor> VirtRegIntervals;

  /// Sorted list of instructions with register mask operands. Always use the
  /// 'r' slot, RegMasks are normal clobbers, not early clobbers.
  SmallVector<SlotIndex, 8> RegMaskSlots;

  /// This vector is parallel to RegMaskSlots, it holds a pointer to the
  /// corresponding register mask.  This pointer can be recomputed as:
  ///
  ///   MI = Indexes->getInstructionFromIndex(RegMaskSlot[N]);
  ///   unsigned OpNum = findRegMaskOperand(MI);
  ///   RegMaskBits[N] = MI->getOperand(OpNum).getRegMask();
  ///
  /// This is kept in a separate vector partly because some standard
  /// libraries don't support lower_bound() with mixed objects, partly to
  /// improve locality when searching in RegMaskSlots.
  /// Also see the comment in LiveInterval::find().
  SmallVector<const uint32_t *, 8> RegMaskBits;

  /// For each basic block number, keep (begin, size) pairs indexing into the
  /// RegMaskSlots and RegMaskBits arrays.
  /// Note that basic block numbers may not be layout contiguous, that's why
  /// we can't just keep track of the first register mask in each basic
  /// block.
  SmallVector<std::pair<unsigned, unsigned>, 8> RegMaskBlocks;

  /// Keeps a live range set for each register unit to track fixed physreg
  /// interference.
  SmallVector<LiveRange *, 0> RegUnitRanges;
}

```

- LiveIntervalUnion， llvm/include/llvm/CodeGen/LiveIntervalUnion.h
IntervalMap的包装类。

```cpp

class LiveIntervalUnion{

  IntervalMap<SlotIndex, const LiveInterval *> Segments;

  class Array {
    unsigned Size = 0;
    LiveIntervalUnion *LIUs = nullptr;
  }
};

```


-  LiveRegMatrix

`llvm/include/llvm/CodeGen/LiveRegMatrix.h`

用来追踪虚拟寄存器的干涉情况，是一个二维结构， `slot index` x `reg units`.
- 用`LiveIntervalUnion::Array Matrix;`表示这个二维结构.
- `InterferenceKind`作为干涉查询结果。`InterferenceKind checkInterference(const LiveInterval &VirtReg, MCRegister PhysReg)`
  - IK_Free 没干涉
  - IK_VirtReg， 虚拟寄存器和物理寄存器干涉。
  - IK_RegUnit, 不太清楚
  - IK_RegMask，主要是call里面的regmask

```cpp

class LiveRegMatrix : public MachineFunctionPass {
  const TargetRegisterInfo *TRI = nullptr;
  LiveIntervals *LIS = nullptr;
  VirtRegMap *VRM = nullptr;

  // UserTag changes whenever virtual registers have been modified.
  unsigned UserTag = 0;

  // The matrix is represented as a LiveIntervalUnion per register unit.
  LiveIntervalUnion::Array Matrix;

  // Cached queries per register unit.
  std::unique_ptr<LiveIntervalUnion::Query[]> Queries;

  // Cached register mask interference info.
  unsigned RegMaskTag = 0;
  unsigned RegMaskVirtReg = 0;
  BitVector RegMaskUsable;

public:
  enum InterferenceKind {
    /// No interference, go ahead and assign.
    IK_Free = 0,

    /// Virtual register interference. There are interfering virtual registers
    /// assigned to PhysReg or its aliases. This interference could be resolved
    /// by unassigning those other virtual registers.
    IK_VirtReg,

    /// Register unit interference. A fixed live range is in the way, typically
    /// argument registers for a call. This can't be resolved by unassigning
    /// other virtual registers.
    IK_RegUnit,

    /// RegMask interference. The live range is crossing an instruction with a
    /// regmask operand that doesn't preserve PhysReg. This typically means
    /// VirtReg is live across a call, and PhysReg isn't call-preserved.
    IK_RegMask
  };

  /// Check for interference before assigning VirtReg to PhysReg.
  /// If this function returns IK_Free, it is legal to assign(VirtReg, PhysReg).
  /// When there is more than one kind of interference, the InterferenceKind
  /// with the highest enum value is returned.
  InterferenceKind checkInterference(const LiveInterval &VirtReg,
                                     MCRegister PhysReg);

  /// Check for interference in the segment [Start, End) that may prevent
  /// assignment to PhysReg. If this function returns true, there is
  /// interference in the segment [Start, End) of some other interval already
  /// assigned to PhysReg. If this function returns false, PhysReg is free at
  /// the segment [Start, End).
  bool checkInterference(SlotIndex Start, SlotIndex End, MCRegister PhysReg);

  /// Assign VirtReg to PhysReg.
  /// This will mark VirtReg's live range as occupied in the LiveRegMatrix and
  /// update VirtRegMap. The live range is expected to be available in PhysReg.
  void assign(const LiveInterval &VirtReg, MCRegister PhysReg);

  /// Unassign VirtReg from its PhysReg.
  /// Assuming that VirtReg was previously assigned to a PhysReg, this undoes
  /// the assignment and updates VirtRegMap accordingly.
  void unassign(const LiveInterval &VirtReg);

  /// Returns true if the given \p PhysReg has any live intervals assigned.
  bool isPhysRegUsed(MCRegister PhysReg) const;

  //===--------------------------------------------------------------------===//
  // Low-level interface.
  //===--------------------------------------------------------------------===//
  //
  // Provide access to the underlying LiveIntervalUnions.
  //

  /// Check for regmask interference only.
  /// Return true if VirtReg crosses a regmask operand that clobbers PhysReg.
  /// If PhysReg is null, check if VirtReg crosses any regmask operands.
  bool checkRegMaskInterference(const LiveInterval &VirtReg,
                                MCRegister PhysReg = MCRegister::NoRegister);

  /// Check for regunit interference only.
  /// Return true if VirtReg overlaps a fixed assignment of one of PhysRegs's
  /// register units.
  bool checkRegUnitInterference(const LiveInterval &VirtReg,
                                MCRegister PhysReg);

  /// Query a line of the assigned virtual register matrix directly.
  /// Use MCRegUnitIterator to enumerate all regunits in the desired PhysReg.
  /// This returns a reference to an internal Query data structure that is only
  /// valid until the next query() call.
  LiveIntervalUnion::Query &query(const LiveRange &LR, MCRegister RegUnit);

  /// Directly access the live interval unions per regunit.
  /// This returns an array indexed by the regunit number.
  LiveIntervalUnion *getLiveUnions() { return &Matrix[0]; }

  Register getOneVReg(unsigned PhysReg) const;
};

```


- vregmap, rewriter时候使用
即寄存器分配的内容不是立即改写mir，而是在rewriter pass时候才会改写mir。

```cpp

class VirtRegMap : public MachineFunctionPass {
  MachineRegisterInfo *MRI = nullptr;
  const TargetInstrInfo *TII = nullptr;
  const TargetRegisterInfo *TRI = nullptr;
  MachineFunction *MF = nullptr;

  /// Virt2PhysMap - This is a virtual to physical register
  /// mapping. Each virtual register is required to have an entry in
  /// it; even spilled virtual registers (the register mapped to a
  /// spilled register is the temporary used to load it from the
  /// stack).
  IndexedMap<MCRegister, VirtReg2IndexFunctor> Virt2PhysMap;

  /// Virt2StackSlotMap - This is virtual register to stack slot
  /// mapping. Each spilled virtual register has an entry in it
  /// which corresponds to the stack slot this register is spilled
  /// at.
  IndexedMap<int, VirtReg2IndexFunctor> Virt2StackSlotMap;

  /// Virt2SplitMap - This is virtual register to splitted virtual register
  /// mapping.
  IndexedMap<Register, VirtReg2IndexFunctor> Virt2SplitMap;

  /// Virt2ShapeMap - For X86 AMX register whose register is bound shape
  /// information.
  DenseMap<Register, ShapeT> Virt2ShapeMap;
};

```



# regalloc 算法实现

## regalloc base

llvm/lib/CodeGen/RegAllocBase.cpp

线性扫描+优先队列的思路. 
该文件里定义了一系列接口
RegAllocBase 核心是: enqueueImpl, dequeue, selectOrSplit

```cpp

class RegAllocBase {
  virtual void anchor();
protected:
  const TargetRegisterInfo *TRI = nullptr;
  MachineRegisterInfo *MRI = nullptr;
  VirtRegMap *VRM = nullptr;
  LiveIntervals *LIS = nullptr;
  LiveRegMatrix *Matrix = nullptr;
  RegisterClassInfo RegClassInfo;

private:
  /// Private, callees should go through shouldAllocateRegister
  const RegAllocFilterFunc shouldAllocateRegisterImpl;
protected:
  /// Inst which is a def of an original reg and whose defs are already all
  /// dead after remat is saved in DeadRemats. The deletion of such inst is
  /// postponed till all the allocations are done, so its remat expr is
  /// always available for the remat of all the siblings of the original reg.
  SmallPtrSet<MachineInstr *, 32> DeadRemats;


  // The top-level driver. The output is a VirtRegMap that us updated with
  // physical register assignments.
  void allocatePhysRegs();

  // Include spiller post optimization and removing dead defs left because of
  // rematerialization.
  virtual void postOptimization();

  // Get a temporary reference to a Spiller instance.
  virtual Spiller &spiller() = 0;

  virtual void enqueueImpl(const LiveInterval *LI) = 0;

  /// enqueue - Add VirtReg to the priority queue of unassigned registers.
  void enqueue(const LiveInterval *LI);

  /// dequeue - Return the next unassigned register, or NULL.
  virtual const LiveInterval *dequeue() = 0;

  virtual MCRegister selectOrSplit(const LiveInterval &VirtReg,
                                   SmallVectorImpl<Register> &splitLVRs) = 0;
};

// 结构精简后:
void RegAllocBase::allocatePhysRegs(){
    while (const LiveInterval *VirtReg = dequeue()) {
        VirtRegVec SplitVRegs;
        MCRegister AvailablePhysReg = selectOrSplit(*VirtReg, SplitVRegs);
        if(AvailablePhysReg == ~0u){
            report_error
        }else if (AvailablePhysReg){
            Matrix->assign(*VirtReg, AvailablePhysReg);
        }
        for (Register Reg : SplitVRegs) {

            LiveInterval *SplitVirtReg = &LIS->getInterval(Reg);

            enqueue(SplitVirtReg);
            ++NumNewQueued;
        }
    }
}

```


## RegAllocBasic
llvm/lib/CodeGen/RegAllocBasic.cpp 
很简易的实现. 还是先看selectOrSplit的实现
1. 先检测有没有可用物理寄存器。 有就直接返回
2. 没有则尝试将更低weight的已分配寄存器溢出
3. 还是不行就将自己溢出。

```cpp

void enqueueImpl(const LiveInterval *LI) override { Queue.push(LI); }
const LiveInterval *dequeue() override {
  if (Queue.empty())
    return nullptr;
  const LiveInterval *LI = Queue.top();
  Queue.pop();
  return LI;
}

MCRegister RABasic::selectOrSplit(const LiveInterval &VirtReg,
                                  SmallVectorImpl<Register> &SplitVRegs) {
  // Populate a list of physical register spill candidates.
  SmallVector<MCRegister, 8> PhysRegSpillCands;

  // Check for an available register in this class.
  auto Order =
      AllocationOrder::create(VirtReg.reg(), *VRM, RegClassInfo, Matrix);
  for (MCRegister PhysReg : Order) {
    assert(PhysReg.isValid());
    // Check for interference in PhysReg
    switch (Matrix->checkInterference(VirtReg, PhysReg)) {
    case LiveRegMatrix::IK_Free:
      // PhysReg is available, allocate it.
      return PhysReg;

    case LiveRegMatrix::IK_VirtReg:
      // Only virtual registers in the way, we may be able to spill them.
      PhysRegSpillCands.push_back(PhysReg);
      continue;

    default:
      // RegMask or RegUnit interference.
      continue;
    }
  }

  // Try to spill another interfering reg with less spill weight.
  for (MCRegister &PhysReg : PhysRegSpillCands) {
    if (!spillInterferences(VirtReg, PhysReg, SplitVRegs))
      continue;

    assert(!Matrix->checkInterference(VirtReg, PhysReg) &&
           "Interference after spill.");
    // Tell the caller to allocate to this newly freed physical register.
    return PhysReg;
  }

  // No other spill candidates were found, so spill the current VirtReg.
  LLVM_DEBUG(dbgs() << "spilling: " << VirtReg << '\n');
  if (!VirtReg.isSpillable())
    return ~0u;
  LiveRangeEdit LRE(&VirtReg, SplitVRegs, *MF, *LIS, VRM, this, &DeadRemats);
  spiller().spill(LRE);

  // The live virtual register requesting allocation was spilled, so tell
  // the caller not to allocate anything during this round.
  return 0;
}

```

