

## 寄存器分配推荐博客
- https://zhuanlan.zhihu.com/p/2069642225634514446
  特别是GPU相关的，更少的寄存器占用 -> 更多 occupany -> 更好的性能？ 未必。 可能会变成global memory bound

## Control Flow Management in Modern GPUs https://arxiv.org/pdf/2407.02944


AMDGPU用显示的exec/vcc管理。
NV方案就更加复杂了。
- pre-volta用类似于stack来管理divergence
- post-volta 使用了 independent thread scheduling, 和更多的SASS层级的控制流指令：BMOV, BSSY, BSYNC, YIELD等 还有Bx寄存器。
这里没太看懂这些指令作用，之后再看一下。

