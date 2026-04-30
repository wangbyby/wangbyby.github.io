

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

// 矩阵转置
__global__ void trans(float *src, float *out, int rows, int cols) {

  int r = blockIdx.x * blockDim.x + threadIdx.x;
  int c = blockIdx.y * blockDim.y + threadIdx.y;

  if (r < cols && c < rows)
    out[r * rows + c] = src[c * cols + r];
}

template<const int X = BLOCK_SIZE>
__global__ void trans_shared(float *src, float *out, int rows, int cols){
    int r = blockIdx.x * BLOCK_SIZE + threadIdx.x;
    int c = blockIdx.y * BLOCK_SIZE + threadIdx.y;


    int local_r = threadIdx.x;  // 块内 x 坐标
    int local_c = threadIdx.y;  // 块内 y 坐标
    __shared__ float s_data[X][BLOCK_SIZE];
    if (r < cols && c < rows)
    s_data[local_c][local_r] = src[c*cols + r];
    __syncthreads();

// 1 2 3
// 4 5 6
/*
    1 4 
    2 5
    3 6
    out[x*rows+y] = src[y*cols+x]

    (x, y)
    0, 0  -> src[0] -> out[0]
    1, 0  -> src[1] -> out[1*2+0]
    1, 0 -> src[2]  -> out[0*2+1]
    ...

    x = blockIdx.x * BLOCK_SIZE + threadIdx.x
    y = blockIdx.y * BLOCK_SIZE + threadIdx.y
    abs_idx = (blockIdx.y * BLOCK_SIZE + threadIdx.y )*cols + blockIdx.x * BLOCK_SIZE + threadIdx.x
        = blockIdx.y * BLOCK_SIZE * cols + threadIdx.y * cols + blockIdx.x * BLOCK_SIZE + threadIdx.x

    tx = blockIdx.y * BLOCK_SIZE + threadIdx.x
    ty = blockIdx.x * BLOCK_SIZE + threadIdx.y
    abs_idx = (blockIdx.x * BLOCK_SIZE + threadIdx.y) * rows + blockIdx.y * BLOCK_SIZE + threadIdx.x
        = blockIdx.x * BLOCK_SIZE * rows + threadIdx.y * rows + blockIdx.y * BLOCK_SIZE + threadIdx.x

*/

    int t_r = blockIdx.y * BLOCK_SIZE + threadIdx.x;
    int t_c = blockIdx.x * BLOCK_SIZE + threadIdx.y;
    if(t_r < rows && t_c < cols)
        out[ t_c*rows + t_r] = s_data[local_r][local_c];

}

__global__ void trans_shared_2(float *src, float *out, int rows, int cols){
    int r = blockIdx.x * BLOCK_SIZE + threadIdx.x;
    int c = blockIdx.y * BLOCK_SIZE + threadIdx.y;


    int local_r = threadIdx.x;  // 块内 x 坐标
    int local_c = threadIdx.y;  // 块内 y 坐标
    __shared__ float s_data[BLOCK_SIZE][1+BLOCK_SIZE];
    if (r < cols && c < rows)
    s_data[local_c][local_r] = src[c*cols + r];
    __syncthreads();

    int t_r = blockIdx.y * BLOCK_SIZE + threadIdx.x;
    int t_c = blockIdx.x * BLOCK_SIZE + threadIdx.y;
    if(t_r < rows && t_c < cols)
        out[ t_c*rows + t_r] = s_data[local_r][local_c];

}

__global__ void trans_shared_vector(float *src, float *out, int rows, int cols){
    int r = blockIdx.x * BLOCK_SIZE + threadIdx.x *  4;
    int c = blockIdx.y * BLOCK_SIZE + threadIdx.y;


    int local_r = threadIdx.x;  // 块内 x 坐标
    int local_c = threadIdx.y;  // 块内 y 坐标
    __shared__ float s_data[BLOCK_SIZE][BLOCK_SIZE];
    if (r + 3 < cols && c < rows){
        float4 *src_ptr = (float4*)&src[c * cols + r];

    s_data[local_c][local_r*4 + 0] = src_ptr->x;
    s_data[local_c][local_r*4 + 1] = src_ptr->y;
    s_data[local_c][local_r*4 + 2] = src_ptr->z;
    s_data[local_c][local_r*4 + 3] = src_ptr->w;

    }
    __syncthreads();

    int t_r = blockIdx.y * BLOCK_SIZE + threadIdx.x * 4;
    int t_c = blockIdx.x * BLOCK_SIZE + threadIdx.y;
    if(t_r + 3 < rows && t_c < cols){
        out[ t_c*rows + t_r + 0] = s_data[local_r*4+0][local_c];
        out[ t_c*rows + t_r + 1] = s_data[local_r*4+1][local_c];
        out[ t_c*rows + t_r + 2] = s_data[local_r*4+2][local_c];
        out[ t_c*rows + t_r + 3] = s_data[local_r*4+3][local_c];

    }

}

int main() {
  int rows = 1024;
  int cols = 1024;
  const int input_size = rows * cols;

  float *A = (float *)calloc(input_size, sizeof(float));
  float *res = (float *)calloc((input_size), sizeof(float));

  for (int i = 0; i < input_size; i++) {
    A[i] = i;
  }

  float *gpu_input;
  float *gpu_out;
  cudaMalloc(&gpu_input, sizeof(float) * input_size);
  cudaMalloc(&gpu_out, sizeof(float) * input_size);

  cudaMemcpy(gpu_input, A, sizeof(float) * input_size, cudaMemcpyHostToDevice);

  dim3 block(BLOCK_SIZE, BLOCK_SIZE);
  dim3 grid((rows + BLOCK_SIZE - 1) / BLOCK_SIZE, (cols + BLOCK_SIZE-1) / BLOCK_SIZE);

  cudaMemset(gpu_out, 0, sizeof(float) * (input_size));
  LAUNCH(trans, grid, block, gpu_input, gpu_out, rows, cols);
  cudaMemcpy(res, gpu_out, sizeof(float) * (input_size),
             cudaMemcpyDeviceToHost);
  check_nth(res, 10);

    cudaMemset(gpu_out, 0, sizeof(float) * (input_size));
  LAUNCH(trans_shared, grid, block, gpu_input, gpu_out, rows, cols);
  cudaMemcpy(res, gpu_out, sizeof(float) * (input_size),
             cudaMemcpyDeviceToHost);
  check_nth(res, 10);

    cudaMemset(gpu_out, 0, sizeof(float) * (input_size));
  LAUNCH(trans_shared<33>, grid, block, gpu_input, gpu_out, rows, cols);
  cudaMemcpy(res, gpu_out, sizeof(float) * (input_size),
             cudaMemcpyDeviceToHost);
  check_nth(res, 10);

    cudaMemset(gpu_out, 0, sizeof(float) * (input_size));
  LAUNCH(trans_shared_2, grid, block, gpu_input, gpu_out, rows, cols);
  cudaMemcpy(res, gpu_out, sizeof(float) * (input_size),
             cudaMemcpyDeviceToHost);
  check_nth(res, 10);


    dim3 block2(BLOCK_SIZE/4, BLOCK_SIZE);  

    cudaMemset(gpu_out, 0, sizeof(float) * (input_size));
  LAUNCH(trans_shared_vector, grid, block2, gpu_input, gpu_out, rows, cols);
  cudaMemcpy(res, gpu_out, sizeof(float) * (input_size),
             cudaMemcpyDeviceToHost);
  check_nth(res, 10);


  return 0;
}
