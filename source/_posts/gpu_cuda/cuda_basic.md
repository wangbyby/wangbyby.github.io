---
title: "[WIP]基础cuda"
date: 2026-04-13
---

- 线程组织 grid，block，thread。
    一个kernel启动的所有线程称为grid。block是调度单元。`<<<网格大小，线程块大小>>>`
- 实际硬件：GPU，SM （stream multiprocessor），SP。
    SM： local register file + shared memory+L1 cache+ a number of functional units that perform computations
    一个block的所有thread都在一个SM上执行。

CUDA要求以任意顺序执行blocks，即一个thread block不应该依赖其他block（同grid）。
- warp
block内部，threads以32个为一warp组织起来。warp是以SIMT模型执行kernel。该warp的线程执行相同的kernel code，但可以有不同branch。
When different threads in a warp follow different code paths, this is sometimes called warp divergence。 

- 内存层次
    - DRAM，global memory 可被所有块所有线程访问， HBM
        coalesced global memory access：
        global memory以32bytes为单位访问称为memory transaction。
        warp会将内部线程的内存访问映射为memory transactions。
    - 同一个block内的线程访问，on chip memory，每个SM独占的。
        - shared memory
            32banks x 32bits/cycle
            bank confilct：multi threads in the same warp attempt to access different elements in the same bank.

        - L1 cache
        - register file
        如果某个thread block需要的寄存器大于寄存器个数，该kernel不可启动
        - 常量内存
    - local memory 每个thread独有的。实际上在global memory上面。
        - 特别是register spilling

- thread hierarchy


>The threads of a block are linearized predictably: the first index x moves the fastest,
>followed by y and then z. This means that in the linearization of a thread indices, consecutive values of threadIdx.x indicate consecutive threads, threadIdx.y has a stride of blockDim.x, and threadIdx.z has a stride of blockDim.x * blockDim.y. 

`linear_id = threadIdx.x + threadIdx.y * blockDim.x + threadId.z * blockDim.x * blockDim.y`

从threadid到 memory address的方式是自己选择的。

 
```cpp
__global__ void transpose_shared(float* out, const float* in, int w, int h) {

    __shared__ float tile[TILE][TILE + 1];  // +1 避免 bank conflict

    // ===== 1. 全局坐标 =====
    int x = blockIdx.x * TILE + threadIdx.x;
    int y = blockIdx.y * TILE + threadIdx.y;

    // ===== 2. global → shared（连续读）=====
    if (x < w && y < h) {
        tile[threadIdx.y][threadIdx.x] = in[y * w + x];
    }

    __syncthreads();

    // ===== 3. 交换 blockIdx（关键！！！）=====
    int new_x = blockIdx.y * TILE + threadIdx.x;
    int new_y = blockIdx.x * TILE + threadIdx.y;

    // ===== 4. shared → global（连续写）=====
    if (new_x < h && new_y < w) {
        out[new_y * h + new_x] = tile[threadIdx.x][threadIdx.y];
    }
}
```
