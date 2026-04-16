
/*
    C(m,n) = A(m,k) * B(k,n)

    block(32, 32)
    grid( (m+31)/32, (n+31)/32 )

*/

#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>

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

  COUNT_TIME(cpu_gemm, { cpu_gemm(CPU_RES, A, B, M, N, K); });

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

  cudaFree(GA);
  cudaFree(GB);
  cudaFree(GC);

  free(A);
  free(B);
  free(CPU_RES);
  return 0;
}
