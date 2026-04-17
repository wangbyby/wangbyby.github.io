
/*
    C(m,n) = A(m,k) * B(k,n)

    block(32, 32)
    grid( (m+31)/32, (n+31)/32 )

*/

#include <chrono>
#include <cmath>
#include <cstdio>
#include <mma.h>
#include <cuda_fp16.h>
#include <cstdlib>

using namespace nvcuda;

#define TILE 32

__global__ void gemm_naive(float *C, float *A, float *B, int M, int N, int K) {
  int col = blockIdx.x * blockDim.x + threadIdx.x;
  int row = blockIdx.y * blockDim.y + threadIdx.y;

  if (row < M && col < N) {
    float sum = 0.0f;
    for (int i = 0; i < K; i++) {
      sum += A[K * row + i] * B[N * i + col];
    }
    C[N * row + col] = sum;
  }
}

// 3ms for float sB[TILE][TILE];

template<const int TILING = TILE>
__global__ void gemm_sharedmem(float *C, float *A, float *B, int M, int N,
                               int K) {
  int tx = threadIdx.x;
  int ty = threadIdx.y;

  int col = blockIdx.x * blockDim.x + tx;
  int row = blockIdx.y * blockDim.y + ty;

  __shared__ float sB[TILE][TILING];
  __shared__ float sA[TILE][TILING];

  float sum = 0.0f;
  for(int t=0; t< (K+TILE-1)/TILE;t++ ){
    if(row<M && (t*TILE + tx) < K ){
      sA[ty][tx] = A[row*K+t*TILE+ tx];
    }else{
      sA[ty][tx] = 0.0f;
    }

    if(col <N && (t*TILE+ty) < K ){
      sB[ty][tx] = B[ (t*TILE+ty)*N + col];
    }else{
      sB[ty][tx] = 0.0f;
    }
    __syncthreads();
    for(int i=0;i<TILE;i++){
      sum += sA[ty][i]* sB[i][tx];
    }
    __syncthreads();

  }                         

  if (row < M && col < N) {
    C[row*N + col] = sum;
  }

}



__global__ void gemm_register(float *C, float *A, float *B,
                              int M, int N, int K) {

    int tx = threadIdx.x;
    int ty = threadIdx.y;

    // 每个线程负责 2×2
    int row = blockIdx.y * TILE + ty * 2;
    int col = blockIdx.x * TILE + tx * 2;

    __shared__ float sA[TILE][TILE+1];
    __shared__ float sB[TILE][TILE+1];

    float sum00 = 0, sum01 = 0;
    float sum10 = 0, sum11 = 0;

    for (int t = 0; t < K; t += TILE) {

        // load A（每线程加载2行）
        if (row < M && t + tx < K)
            sA[ty*2][tx] = A[row * K + (t + tx)];
        else
            sA[ty*2][tx] = 0;

        if (row+1 < M && t + tx < K)
            sA[ty*2+1][tx] = A[(row+1) * K + (t + tx)];
        else
            sA[ty*2+1][tx] = 0;

        // load B（每线程加载2列）
        if (col < N && t + ty < K)
            sB[ty][tx*2] = B[(t + ty) * N + col];
        else
            sB[ty][tx*2] = 0;

        if (col+1 < N && t + ty < K)
            sB[ty][tx*2+1] = B[(t + ty) * N + col+1];
        else
            sB[ty][tx*2+1] = 0;

        __syncthreads();

        for (int i = 0; i < TILE; i++) {
            float a0 = sA[ty*2][i];
            float a1 = sA[ty*2+1][i];

            float b0 = sB[i][tx*2];
            float b1 = sB[i][tx*2+1];

            sum00 += a0 * b0;
            sum01 += a0 * b1;
            sum10 += a1 * b0;
            sum11 += a1 * b1;
        }

        __syncthreads();
    }

    // 写回
    if (row < M && col < N)
        C[row * N + col] = sum00;

    if (row < M && col+1 < N)
        C[row * N + col+1] = sum01;

    if (row+1 < M && col < N)
        C[(row+1) * N + col] = sum10;

    if (row+1 < M && col+1 < N)
        C[(row+1) * N + col+1] = sum11;
}


#define TILE 32
#define WARP_SIZE 32

__global__ void gemm_warp(float *C, const float *A, const float *B,
                          int M, int N, int K) {

    // 一个 block 256 threads → 8 warps
    int warp_id = threadIdx.x / WARP_SIZE;
    int lane = threadIdx.x % WARP_SIZE;

    // block tile 起点
    int block_row = blockIdx.y * TILE;
    int block_col = blockIdx.x * TILE;

    // 每个 warp 负责 16×16
    int warp_row = warp_id / 2; // 0~3
    int warp_col = warp_id % 2; // 0~1

    int row = block_row + warp_row * 16;
    int col = block_col + warp_col * 16;

    // lane 映射到 4×4 子块
    int lane_row = lane / 8;   // 0~3
    int lane_col = lane % 8;   // 0~7

    float regC[4][2] = {0}; // 每线程算 4×2

    __shared__ float sA[TILE][TILE];
    __shared__ float sB[TILE][TILE];

    for (int t = 0; t < K; t += TILE) {

        // load shared memory
        int tx = threadIdx.x % TILE;
        int ty = threadIdx.x / TILE;

        if (block_row + ty < M && t + tx < K)
            sA[ty][tx] = A[(block_row + ty) * K + (t + tx)];
        else
            sA[ty][tx] = 0;

        if (t + ty < K && block_col + tx < N)
            sB[ty][tx] = B[(t + ty) * N + (block_col + tx)];
        else
            sB[ty][tx] = 0;

        __syncthreads();

        // compute
        for (int k = 0; k < TILE; k++) {

            float a[4];
            float b[2];

            #pragma unroll
            for (int i = 0; i < 4; i++)
                a[i] = sA[warp_row * 16 + lane_row * 4 + i][k];

            #pragma unroll
            for (int j = 0; j < 2; j++)
                b[j] = sB[k][warp_col * 16 + lane_col * 2 + j];

            #pragma unroll
            for (int i = 0; i < 4; i++)
                for (int j = 0; j < 2; j++)
                    regC[i][j] += a[i] * b[j];
        }

        __syncthreads();
    }

    // write back
    #pragma unroll
    for (int i = 0; i < 4; i++) {
        int r = row + lane_row * 4 + i;

        #pragma unroll
        for (int j = 0; j < 2; j++) {
            int c = col + lane_col * 2 + j;

            if (r < M && c < N)
                C[r * N + c] = regC[i][j];
        }
    }
}


void cpu_gemm(float *C, float *A, float *B, int M, int N, int K) {
  for (int r = 0; r < M; r++) {
    for (int col = 0; col < N; col++) {
      float sum = 0.0f;
      for (int k = 0; k < K; k++) {
        sum += A[r * K + k] * B[N * k + col];
      }
      C[r * N + col] = sum;
    }
  }
}

#define COUNT_TIME(name, code)                                                 \
  do {                                                                         \
    auto start = std::chrono::high_resolution_clock::now();                    \
    code;                                                                      \
    auto end = std::chrono::high_resolution_clock::now();                      \
    double time_ms =                                                           \
        std::chrono::duration<double, std::milli>(end - start).count();        \
    printf(#name " using time %fms\n", time_ms);                               \
  } while (0)

bool nearly_equal(float a, float b) {
  float abs_err = fabs(a - b);
  float rel_err = abs_err / fmaxf(1.0f, fmaxf(fabs(a), fabs(b)));
  return abs_err < 1e-5f || rel_err < 1e-5f;
}

bool check(const float *A, const float *B, const int len) {
  for (int i = 0; i < len; i++) {
    if (!nearly_equal(A[i], B[i])) {
      printf("Found diff value at %d, %f vs %f ", i, A[i], B[i]);
      return false;
    }
  }
  return true;
}

__global__ void gemm_tensorcore(half *A, half *B, float *C,
                               int M, int N, int K) {

    // warp id
    int warpId = (blockIdx.x * blockDim.x + threadIdx.x) / 32;
    int laneId = threadIdx.x % 32;

    // 每个 warp 负责 16×16 tile
    int warpM = (blockIdx.y * blockDim.y + threadIdx.y);
    int warpN = (blockIdx.x * blockDim.x + threadIdx.x) / 32;

    int row = warpM * 16;
    int col = warpN * 16;

    // fragments
    wmma::fragment<wmma::matrix_a, 16, 16, 16, half, wmma::row_major> a_frag;
    wmma::fragment<wmma::matrix_b, 16, 16, 16, half, wmma::row_major> b_frag;
    wmma::fragment<wmma::accumulator, 16, 16, 16, float> c_frag;

    wmma::fill_fragment(c_frag, 0.0f);

    for (int k = 0; k < K; k += 16) {

        if (row < M && col < N) {
            wmma::load_matrix_sync(a_frag, A + row * K + k, K);
            wmma::load_matrix_sync(b_frag, B + k * N + col, N);

            wmma::mma_sync(c_frag, a_frag, b_frag, c_frag);
        }
    }

    if (row < M && col < N) {
        wmma::store_matrix_sync(C + row * N + col,
                                c_frag, N, wmma::mem_row_major);
    }
}


int main() {
  const int M = 1024;
  const int N = M;
  const int K = N;

  float *A = (float *)calloc(M * K, sizeof(float));
  float *B = (float *)calloc(N * K, sizeof(float));
  float *CPU_RES = (float *)calloc(M * N, sizeof(float));

  // init these value.

  for (int i = 0; i < M * K; i++) {
    A[i] = i;
  }
  for (int i = 0; i < N * K; i++) {
    B[i] = i;
  }

  // COUNT_TIME(cpu_gemm, { cpu_gemm(CPU_RES, A, B, M, N, K); });

  float *GA;
  float *GB;
  float *GC;

  cudaMalloc(&GA, sizeof(float) * M * K);
  cudaMalloc(&GB, sizeof(float) * N * K);
  cudaMalloc(&GC, sizeof(float) * M * N);

  cudaMemcpy(GA, A, sizeof(float) * M * K, cudaMemcpyHostToDevice);
  cudaMemcpy(GB, B, sizeof(float) * K * N, cudaMemcpyHostToDevice);
  float *GPU_RES = (float *)malloc(sizeof(float) * M * N);

  dim3 block(32, 32);
  dim3 grid((N + 31) / 32, (M + 31) / 32);
  {
    auto start = std::chrono::high_resolution_clock::now();
    gemm_naive<<<grid, block>>>(GC, GA, GB, M, N, K);
    cudaDeviceSynchronize();
    auto end = std::chrono::high_resolution_clock::now();

    double time_ms =
        std::chrono::duration<double, std::milli>(end - start).count();
    printf("gemm naive using time %fms\n", time_ms);

    // 26ms

    cudaMemcpy(GPU_RES, GC, sizeof(float) * M * N, cudaMemcpyDeviceToHost);
    check(GPU_RES, CPU_RES, M * N);
  }

  {
    cudaMemset(GC, 0, sizeof(float) * M * N);
    auto start = std::chrono::high_resolution_clock::now();
    gemm_sharedmem<<<grid, block>>>(GC, GA, GB, M, N, K);
    cudaDeviceSynchronize();
    auto end = std::chrono::high_resolution_clock::now();

    double time_ms =
        std::chrono::duration<double, std::milli>(end - start).count();
    printf("gemm naive using time %fms\n", time_ms);

    // 26ms

    cudaMemcpy(GPU_RES, GC, sizeof(float) * M * N, cudaMemcpyDeviceToHost);
    check(GPU_RES, CPU_RES, M * N);
  }

  {
    cudaMemset(GC, 0, sizeof(float) * M * N);
    auto start = std::chrono::high_resolution_clock::now();
    gemm_sharedmem<TILE+1><<<grid, block>>>(GC, GA, GB, M, N, K);
    cudaDeviceSynchronize();
    auto end = std::chrono::high_resolution_clock::now();

    double time_ms =
        std::chrono::duration<double, std::milli>(end - start).count();
    printf("gemm naive using time %fms\n", time_ms);

    // 26ms

    cudaMemcpy(GPU_RES, GC, sizeof(float) * M * N, cudaMemcpyDeviceToHost);
    check(GPU_RES, CPU_RES, M * N);
  }


  {
    dim3 block(16, 16);
    dim3 grid((N + 31) / 32, (M + 31) / 32);

    cudaMemset(GC, 0, sizeof(float) * M * N);
    auto start = std::chrono::high_resolution_clock::now();
    gemm_register<<<grid, block>>>(GC, GA, GB, M, N, K);
    cudaDeviceSynchronize();
    auto end = std::chrono::high_resolution_clock::now();

    double time_ms =
        std::chrono::duration<double, std::milli>(end - start).count();
    printf("gemm register using time %fms\n", time_ms);

    // 26ms

    cudaMemcpy(GPU_RES, GC, sizeof(float) * M * N, cudaMemcpyDeviceToHost);
    check(GPU_RES, CPU_RES, M * N);
  }

  {
   dim3 block(256); // 8 warps
  dim3 grid((N+31)/32, (M+31)/32);


    cudaMemset(GC, 0, sizeof(float) * M * N);
    auto start = std::chrono::high_resolution_clock::now();
    gemm_warp<<<grid, block>>>(GC, GA, GB, M, N, K);
    cudaDeviceSynchronize();
    auto end = std::chrono::high_resolution_clock::now();

    double time_ms =
        std::chrono::duration<double, std::milli>(end - start).count();
    printf("gemm warp using time %fms\n", time_ms);

    // 26ms

    cudaMemcpy(GPU_RES, GC, sizeof(float) * M * N, cudaMemcpyDeviceToHost);
    check(GPU_RES, CPU_RES, M * N);
  }

  {
     {
    half *hA, *hB;
    cudaMalloc(&hA, sizeof(half) * M * K);
    cudaMalloc(&hB, sizeof(half) * K * N);

    int totalA = M * K;
    int totalB = K * N;

    float2half_kernel<<<(totalA+255)/256, 256>>>(hA, GA, totalA);
    float2half_kernel<<<(totalB+255)/256, 256>>>(hB, GB, totalB);

    dim3 block(32, 4);
    dim3 grid(N / 16, M / 16);

    cudaMemset(GC, 0, sizeof(float) * M * N);

    auto start = std::chrono::high_resolution_clock::now();

    gemm_tensorcore<<<grid, block>>>(hA, hB, GC, M, N, K);

    cudaDeviceSynchronize();

    auto end = std::chrono::high_resolution_clock::now();

    double time_ms =
        std::chrono::duration<double, std::milli>(end - start).count();

    printf("gemm tensor core using time %fms\n", time_ms);

    cudaMemcpy(GPU_RES, GC, sizeof(float) * M * N, cudaMemcpyDeviceToHost);

    check(GPU_RES, CPU_RES, M * N);

    cudaFree(hA);
    cudaFree(hB);
}


  }

  cudaFree(GA);
  cudaFree(GB);
  cudaFree(GC);

  free(A);
  free(B);
  free(CPU_RES);
  return 0;
}
