

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

#define BLOCK_SIZE 32
#define TILE_SIZE 16

__global__ void gemm(float *out, float *A /*M*K*/, float *B /*K*N*/, int M,
                     int N, int K) {

  int col = blockIdx.x * blockDim.x + threadIdx.x;
  int row = blockIdx.y * blockDim.y + threadIdx.y;

  if (row < M && col < N) {
    float sum = 0.0f;
    for (int i = 0; i < K; i++) {
      sum += A[row * K + i] * B[i * N + col];
    }

    out[row * N + col] = sum;
  }
}

__global__ void gemm_shared(float *out, float *A /*M*K*/, float *B /*K*N*/, int M,
                          int N, int K) {

  __shared__ float s_a[TILE_SIZE][TILE_SIZE];
  __shared__ float s_b[TILE_SIZE][TILE_SIZE];

  int tx = threadIdx.x;
  int ty = threadIdx.y;
  int col = blockIdx.x * TILE_SIZE + threadIdx.x;
  int row = blockIdx.y * TILE_SIZE + threadIdx.y;

  float sum = 0.0f;
  for (int k = 0; k < K; k += TILE_SIZE) {
    if (row < M && k + tx < K) {
      s_a[ty][tx] = A[row * K + k + tx];
    }
    if (col < N && k + ty < K) {
      s_b[ty][tx] = B[(k + ty) * N + col];
    }
    __syncthreads();

    for (int i = 0; i < TILE_SIZE; i++) {
      sum += s_a[ty][i] * s_b[i][tx];
    }
    __syncthreads();
  }

  if (row < M && col < N) {
    out[row * N + col] = sum;
  }
}

__global__ void gemm_shared_bank(float *out, float *A /*M*K*/, float *B /*K*N*/, int M,
                          int N, int K) {

  __shared__ float s_a[TILE_SIZE][TILE_SIZE];
  __shared__ float s_b[TILE_SIZE][TILE_SIZE+1];

  int tx = threadIdx.x;
  int ty = threadIdx.y;
  int col = blockIdx.x * TILE_SIZE + threadIdx.x;
  int row = blockIdx.y * TILE_SIZE + threadIdx.y;

  float sum = 0.0f;
  for (int k = 0; k < K; k += TILE_SIZE) {
    if (row < M && k + tx < K) {
      s_a[ty][tx] = A[row * K + k + tx];
    }
    if (col < N && k + ty < K) {
      s_b[ty][tx] = B[(k + ty) * N + col];
    }
    __syncthreads();

    for (int i = 0; i < TILE_SIZE; i++) {
      sum += s_a[ty][i] * s_b[i][tx];
    }
    __syncthreads();
  }

  if (row < M && col < N) {
    out[row * N + col] = sum;
  }
}

__global__ void gemm_double_buffer(float *out, float *A, float *B, int M, int N, int K) {
    __shared__ float s_a[2][TILE_SIZE][TILE_SIZE];
    __shared__ float s_b[2][TILE_SIZE][TILE_SIZE];
    
    int tx = threadIdx.x, ty = threadIdx.y;
    int row = blockIdx.y * TILE_SIZE + ty;
    int col = blockIdx.x * TILE_SIZE + tx;
    
    float sum = 0.0f;
    
    // 预加载第一块
    int write_stage = 0;
    if (row < M && tx < K) s_a[write_stage][ty][tx] = A[row * K + tx];
    if (col < N && ty < K) s_b[write_stage][ty][tx] = B[ty * N + col];
    __syncthreads();
    
    for (int k = TILE_SIZE; k <= K; k += TILE_SIZE) {
        int read_stage = write_stage;
        write_stage ^= 1;  // 切换到下一块
        
        // 异步加载下一块
        if (row < M && k + tx < K) 
            s_a[write_stage][ty][tx] = A[row * K + k + tx];
        if (col < N && k + ty < K) 
            s_b[write_stage][ty][tx] = B[(k + ty) * N + col];
        
        // 计算当前块
        for (int i = 0; i < TILE_SIZE; i++) {
            sum += s_a[read_stage][ty][i] * s_b[read_stage][i][tx];
        }
        __syncthreads();  // 确保加载完成
    }
    
    // 处理最后一块（如果需要）
    if (row < M && col < N) out[row * N + col] = sum;
}

int main() {
  int rows = 1024;
  int cols = 1024;
  const int input_size = rows * cols;

  float *A = (float *)calloc(input_size, sizeof(float));
  float *B = (float *)calloc(input_size, sizeof(float));
  float *res = (float *)calloc((input_size), sizeof(float));

  for (int i = 0; i < input_size; i++) {
    A[i] = i;
    B[i] = i;
  }

  float *gpuA;
  float *gpuB;
  float *gpu_out;
  cudaMalloc(&gpuA, sizeof(float) * input_size);
  cudaMalloc(&gpuB, sizeof(float) * input_size);
  cudaMalloc(&gpu_out, sizeof(float) * input_size);

  cudaMemcpy(gpuA, A, sizeof(float) * input_size, cudaMemcpyHostToDevice);
  cudaMemcpy(gpuB, B, sizeof(float) * input_size, cudaMemcpyHostToDevice);

  dim3 block(BLOCK_SIZE, BLOCK_SIZE);
  dim3 grid((rows + BLOCK_SIZE - 1) / BLOCK_SIZE,
            (cols + BLOCK_SIZE - 1) / BLOCK_SIZE);

  cudaMemset(gpu_out, 0, sizeof(float) * (input_size));
  LAUNCH(gemm, grid, block, gpu_out, gpuA, gpuB, rows, cols, rows);
  cudaMemcpy(res, gpu_out, sizeof(float) * (input_size),
             cudaMemcpyDeviceToHost);
  check_nth(res, 10);

  dim3 block2(TILE_SIZE, TILE_SIZE);
  dim3 grid2( (rows+TILE_SIZE-1)/TILE_SIZE, (cols+TILE_SIZE-1)/TILE_SIZE );
  cudaMemset(gpu_out, 0, sizeof(float) * (input_size));
  LAUNCH(gemm_shared, grid2, block2, gpu_out, gpuA, gpuB, rows, cols, rows);
  cudaMemcpy(res, gpu_out, sizeof(float) * (input_size),
             cudaMemcpyDeviceToHost);
  check_nth(res, 10);

  cudaMemset(gpu_out, 0, sizeof(float) * (input_size));
  LAUNCH(gemm_shared_bank, grid2, block2, gpu_out, gpuA, gpuB, rows, cols, rows);
  cudaMemcpy(res, gpu_out, sizeof(float) * (input_size),
             cudaMemcpyDeviceToHost);
  check_nth(res, 10);

  cudaMemset(gpu_out, 0, sizeof(float) * (input_size));
  LAUNCH(gemm_double_buffer, grid2, block2, gpu_out, gpuA, gpuB, rows, cols, rows);
  cudaMemcpy(res, gpu_out, sizeof(float) * (input_size),
             cudaMemcpyDeviceToHost);
  check_nth(res, 10);

  return 0;
}
