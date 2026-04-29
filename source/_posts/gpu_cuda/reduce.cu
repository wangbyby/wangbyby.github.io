

#include <chrono>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <sys/cdefs.h>

#define LAUNCH(name, grid, block, ...)                                         \
  do {                                                                         \
    auto start = std::chrono::high_resolution_clock::now();                    \
    {                                                                          \
      name<<<grid, block>>>(__VA_ARGS__);                                      \
      cudaDeviceSynchronize();                                                 \
    }                                                                          \
    auto end = std::chrono::high_resolution_clock::now();                      \
    auto time_ms =                                                             \
        std::chrono::duration<double, std::milli>(end - start).count();        \
    printf(#name " using time %fms\n", time_ms);                               \
  } while (0)

void check_nth(const float *A, size_t n) {
  for (int i = 0; i < n; i++) {
    printf("%f, ", A[i]);
  }
  printf("\n");
}

#define ThreadDim 512
#define BlockDim(N) (((N) + ThreadDim - 1) / ThreadDim)

// block level reduce
__global__ void reduce_naive(float *A, float *dst, int N) {

  int idx = blockDim.x * blockIdx.x + threadIdx.x;

  __shared__ float s_data[ThreadDim];

  s_data[threadIdx.x] = (idx < N) ? A[idx] : 0.0f;
  __syncthreads();

  for (int offset = ThreadDim / 2; offset > 0; offset >>= 1) {
    if (threadIdx.x < offset)
      s_data[threadIdx.x] += s_data[threadIdx.x + offset];
    __syncthreads();
  }

  if (threadIdx.x == 0) {
    dst[blockIdx.x] = s_data[0];
  }
}

__inline__ __device__ float wardpShuffle(float val) {
  for (int offset = 16; offset > 0; offset >>= 1) {
    val += __shfl_down_sync(0xffffffff, val, offset);
  }
  return val;
}

__global__ void reduce_warp(float *A, float *dst, int N) {

  int tid = threadIdx.x;
  int idx = blockDim.x * blockIdx.x + threadIdx.x;

  float sum = 0.0f;
  if (idx < N) {
    sum = A[idx];
  }
  sum = wardpShuffle(sum);

  __shared__ float s_data[32];
  int warp_id = tid / 32;
  int lane = tid % 32;
  if (lane == 0)
    s_data[warp_id] = sum;
  __syncthreads();

  // first warp to reduce s_data
  if (warp_id == 0) {
    int warp_count = (blockDim.x + 31) / 32;  // block 中的 warp 数量

    float sum =  (lane< warp_count)   ?s_data[lane]:0.0f;
    sum = wardpShuffle(sum);

    if (lane == 0) {
      dst[blockIdx.x] = sum;
    }
  }
}

int main() {
  const int N = 1024 * 1024;

  float *A = (float *)calloc(N, sizeof(float));
  float *B = (float *)calloc(N, sizeof(float));

  for (int i = 0; i < N; i++) {
    A[i] = 1.0f + i / ThreadDim;
  }

  float *res = (float *)calloc(BlockDim(N), sizeof(float));

  float *GA;
  float *Res;
  cudaMalloc(&GA, sizeof(float) * N);
  cudaMalloc(&Res, sizeof(float) * BlockDim(N));

  cudaMemcpy(GA, A, sizeof(float) * N, cudaMemcpyHostToDevice);

  dim3 block(512);
  dim3 grid((N + 511) / 512);

  cudaMemset(Res, 0, sizeof(float) * BlockDim(N));
  LAUNCH(reduce_naive, grid, block, GA, Res, N);
  cudaMemcpy(res, Res, sizeof(float) * BlockDim(N), cudaMemcpyDeviceToHost);
  check_nth(res, 10);

  cudaMemset(Res, 0, sizeof(float) * BlockDim(N));
  LAUNCH(reduce_warp, grid, block, GA, Res, N);
  cudaMemcpy(res, Res, sizeof(float) * BlockDim(N), cudaMemcpyDeviceToHost);
  check_nth(res, 10);

  return 0;
}
