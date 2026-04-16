
#include <cmath>
__global__ void softmax_basic(float*out, const float*in, int rows, int cols){
    int row = blockIdx.x;
    int t = threadIdx.x;

    if(row >= rows) return ;

    const float*row_in = in + row*cols;
    float* row_out = out + row*cols;

    float max_val = -FLT_MAX;
    for(int i=tid;i<cols;i+=blockDim.x){
        max_val = fmaxf( max_val, row_in[i]);
    }

    __shared__ float smax[256];
    smax[tid] = max_val;
    __syncthreads();
    
}