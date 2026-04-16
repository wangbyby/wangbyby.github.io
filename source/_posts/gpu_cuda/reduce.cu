

__global__ void reduce_naive(float*out, const float*in, int n) {
    int tid = threadIdx.x
    ;
    int id = blockDim.x* blockIdx.x + tid;

    __shared__ float sdata[256];

    sdata[tid] = (id< n)? in[id]:0.0f;

    __syncthreads();
    for(int s=1; s<blockDim.x;s*=2){
        if( tid % (2*s) == 0 ){
            sdata[tid] += sdata[tid+s];
        }
        __syncthreads();
    }

    if(tid ==0){
        out[blockIdx.x] = sdata[0];
    }

}


__global__ void reduce_v2(float*out, const float*in, int n){
    int tid = threadIdx.x;
    int id = blockDim.x * blockIdx.x *2 + tid;

    __shared__ float sdata[256];

    float sum = 0.0f;
    if(id<n) sum+=in[i];
    if(id+blockDim.x < n) sum+=in[i+blockDim.x];

    sdata[tid] = sum;
    __syncthreads();

    for(int s = blockDim.x/2; s>0;s>>=1){
        if(tid < s){
            sdata[tid] = sdata[tid+s];
        }
        __syncthreads();
    }
    if(tid == 0){
        out[blockIdx.x] = sdata[0];
    }

}

__inline__ __device__ 
float warpReduce(float val) {
    for(int off=16;off>0;off>>=1){
        val += __shfl_down_sync(0xffffffff, val, off);
    }
    return val;
}

__global__ void reduce_warp(float*out, float*in, int n){
    float sum = 0.0f;
    int i = blockIdx.x * blockDim.x * 2 + threadIdx.x;

    if (i < n) sum += in[i];
    if (i + blockDim.x < n) sum += in[i + blockDim.x];

    sum = warpReduce(sum);

    if( (threadIdx.x & 31) == 0){
        atomicAdd(out, sum);
    }

}


__global__ void reduce_warp_2(float*out, float*in, int n){
    float sum = 0.0f;
    int i = blockIdx.x * blockDim.x * 2 + threadIdx.x;

    if (i < n) sum += in[i];
    if (i + blockDim.x < n) sum += in[i + blockDim.x];

    sum = warpReduce(sum);

    __shared__ float warp_sum[32];

    int lane = threadIdx.x & 31;
    int wid = threadIdx.x >> 5;

    if(lane == 0){
        warp_sum[wid] = sum;
    }
    __syncthreads();

    float block_sum = 0.0f;
    if(wid == 0){
        block_sum = ( lane < ((blockDim.x) >> 5) ) ? warp_sum[lane] : 0.0f;
        block_sum = warpReduce(block_sum);
    }

    if(threadIdx.x == 0){
        out[blockDim.x] = block_sum;
    }


}


