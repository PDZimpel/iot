#include "../kernel.h"
#include <cstdio>
#include <cstdint>
#include <climits>

const int MAX_SIZE=3; // bounded by filter
// const int INVALID_NODE=-1;
const int BLOCK_SIZE=256;

struct 
BestPair
/*
    Holds best combination pair (of, index)
*/
{
    int64_t of;
    int64_t idx;
    int mutex; // Used in reductions
};

__host__ __device__ __forceinline__
int64_t 
binom(int n, int k)
/*
    Calculates binomial coefitient n! / (k! * (n-k)!)
    a.k.a number of combinations of n numbers, size k.
*/
{
    int64_t top = 1;
    int64_t bot = 1;
    for(int i=1; i<=k; i++){
        top *= n-i+1;
        bot *= i;
    }
    return top/bot;
}

__host__ __device__ __forceinline__
int64_t
combinatorial_range(int n, int k)
/*
    Calculates total number of combinations on multi-level 
    combinatorial space.
*/
{
    int64_t prefix=0;
    for(int i=1; i<=k; i++){
        prefix+=binom(n, i);
    }
    return prefix;
}

__host__ __device__ __forceinline__
int
infer_combination(
    const int64_t i,
    const int64_t n,
    const int k,
    int* comb
)
/*
    Infers combination from index
*/
{
    int64_t b;
    int size;

    // Calculate combination size
    int64_t prefix = 0; // start of 'level' or combination size
    for(b = 0; b < k; b++){
        int64_t calc = binom(n, b + 1);
        if(i < prefix + calc)
            break;
        prefix += calc;
    }
    size = b + 1;

    // If size one, item = idx
    if(b == 0){
        comb[0] = (int)(i - prefix);
        return 1;
    }

    // Combination inferral process, lexicographic unranking
    int64_t idx = i - prefix;
    int x = 0;
    for(int j = b + 1; j > 0; j--){
        for(int v = x; v < n; v++){
            int64_t c = binom(n - v - 1, j - 1);
            if(idx < c){
                comb[size - j] = v;
                x = v + 1;
                break;
            }else{
                idx -= c;
            }
        }
    }

    return size;
}

__device__
int gen_next(int* comb, int* size, int n, int k)
/*
    Generates next combination given present one,
    uses lexicographical generation ordering.
    Average case should be only changing last item on the combination
    returns index of first changed item 
*/
{
    for(int i = *size-1, idx = 0; i >= 0; i--, idx++){
        if(comb[i] < n - *size + i){
            comb[i]++;

            for(int j = i + 1; j < *size; j++){
                comb[j] = comb[j-1] + 1;
            }
            return i;
        }
    }

    if(*size >= k){
        return -1;
    }

    *size +=1;
    for(int i=0; i<*size; i++){
        comb[i] = i;
    }

    return 0;
}

__device__ __forceinline__
void 
update_buffers(
    int size, 
    int* comb, 
    int* r, 
    int* b, 
    int* l, 
    int pivot, 
    int* resources, 
    int* bandwidths, 
    int* latencies
)
/*
    Given pivot (last changed item index), 
    recalculates the Objective Function buffer,
*/
{
    if(pivot == 0){ // combination reset (altered size)
        r[0] = resources[comb[0]];
        b[0] = bandwidths[comb[0]];
        l[0] = latencies[comb[0]];

        for(int i=1; i<size; i++){
            r[i] = r[i-1] + resources[comb[i]];
            b[i] = b[i-1] + bandwidths[comb[i]];
            l[i] = l[i-1] + latencies[comb[i]];
        }
        return; 
    }

    // default
    for(int i=pivot; i<size; i++){
        r[i] = r[i-1] + resources[comb[i]];
        b[i] = b[i-1] + bandwidths[comb[i]];
        l[i] = l[i-1] + latencies[comb[i]];
    }
}

__device__ __forceinline__
int64_t calculate_of(
    int size,
    int* r,
    int* b,
    int* l,
    int jr,
    int jb,
    int jl
)
/*
    Given resource, bandwidth and latency buffers, calculate OF
*/
{
    int i = size - 1; // total sum is stored at the last position

    int64_t f0 = r[i] - jr;
    int64_t f1 = b[i] - jb;
    int64_t f2 = jl - l[i];

    return f0 * f0 + f1 * f1 - f2;
}

__global__
void find_best_comb(  
    int n,
    int k,
    int* resources,
    int* bandwidths, 
    int* latencies,
    int jr, 
    int jb, 
    int jl,
    BestPair* best
)
/*
    Finds best combination on combinatorial space bounded by n and k.
    1. Infers first combination within the assigned block (lexicographic unranking)
    2. Generates next combination until space is exhausted (lexicographic generator)
    3. Block reducion of generated BestPair 
*/
{
    int comb[MAX_SIZE];

    int64_t range = combinatorial_range(n, k);

    int global_thread_idx = blockIdx.x * blockDim.x + threadIdx.x;
    int num_threads = blockDim.x * gridDim.x;
    int64_t count = (range + num_threads - 1) / num_threads;
    int64_t idx = global_thread_idx * count;
    int64_t end = min(idx + count, range);
    bool active = idx < range;

    int64_t bof = INT64_MAX;
    int64_t bcomb = INT64_MAX;

    if(active){ // number of blocks can be bigger than number of combinations
        int size = infer_combination(idx, n, k, comb);
        int r[MAX_SIZE], b[MAX_SIZE], l[MAX_SIZE];
        update_buffers(size, comb, r, b, l, 0, resources, bandwidths, latencies);
        int pivot = 0;

        for (int64_t i = idx; i < end; ++i) {
            if (r[size-1] >= jr && b[size-1] >= jb && l[size-1] <= jl) {
                int64_t of = calculate_of(size, r, b, l, jr, jb, jl);
                if (of < bof) {
                    bof = of;
                    bcomb = i;
                } else if (of == bof && i < bcomb) {
                    bcomb = i;
                }
            }
            if (i + 1 < end) {
                pivot = gen_next(comb, &size, n, k);
                if (pivot == -1) break;
                update_buffers(size, comb, r, b, l, pivot, resources, bandwidths, latencies);
            }
        }
    }

    // Shared reduction
    __shared__ int64_t s_of[BLOCK_SIZE];
    __shared__ int64_t s_comb[BLOCK_SIZE];

    int tid = threadIdx.x;
    s_of[tid] = bof;
    s_comb[tid] = bcomb;
    __syncthreads();

    for(int stride = BLOCK_SIZE / 2; stride > 0; stride >>= 1){
        if(tid < stride){
            if(s_of[tid + stride] < s_of[tid]){
                s_of[tid] = s_of[tid + stride];
                s_comb[tid] = s_comb[tid + stride];
            }else if(s_of[tid + stride] == s_of[tid]){
                if(s_comb[tid + stride] < s_comb[tid]){
                    s_comb[tid] = s_comb[tid + stride];
                }
            }
        }
        __syncthreads();
    }

    // global reduction with mutex
    if(tid == 0 && active){
        // wait for mutex
        while (atomicCAS(&best->mutex, 0, 1) != 0);
        
        // update best comb
        if (s_of[0] < best->of || 
            (s_of[0] == best->of && s_comb[0] < best->idx)) {
            best->of = s_of[0];
            best->idx = s_comb[0];
        }
        
        // releases
        atomicExch(&best->mutex, 0);
    }
}

extern "C" void search_comb_space(
// Hyperparameters
    int n,
    int k,
// Job Info
    int jr,
    int jb,
    int jl,
// Network info
    int* resources, 
    int* bandwidths, 
    int* latencies,
// Output
    int64_t* best_comb,
    int64_t* best_of
)
{
    if (k > MAX_SIZE) {
        printf("Input k should be <= %d\n", MAX_SIZE);
        return;
    }

    // /* !!! Removed this for better performance, if overflow the results will be just wrong
    int64_t range = combinatorial_range(n, k);
    if (range < 0) {
        printf("ERROR: Range overflow\n");
        *best_of = INT64_MAX;
        *best_comb = -1;
        return;
    }
    // */

    int* d_resources = nullptr;
    int* d_bandwidths = nullptr;
    int* d_latencies = nullptr;
    BestPair* d_best = nullptr;

    cudaMalloc(&d_resources, n * sizeof(int));
    cudaMalloc(&d_bandwidths, n * sizeof(int));
    cudaMalloc(&d_latencies, n * sizeof(int));
    cudaMalloc(&d_best, sizeof(BestPair));

    cudaMemcpy(d_resources, resources, n * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_bandwidths, bandwidths, n * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_latencies, latencies, n * sizeof(int), cudaMemcpyHostToDevice);

    BestPair init_best;
    init_best.of = INT64_MAX;
    init_best.idx = INT64_MAX;
    init_best.mutex = 0;
    cudaMemcpy(d_best, &init_best, sizeof(BestPair), cudaMemcpyHostToDevice);

    // Trying to use max number of threads... so far this is what I think might be correct
    int threads = BLOCK_SIZE;
    cudaDeviceProp prop;
    cudaGetDeviceProperties(&prop, 0);
    int blocks = prop.multiProcessorCount * 32;

    //printf("Launching with %d blocks, %d threads\n", blocks, threads);

    find_best_comb<<<blocks, threads>>>(
        n, k,
        d_resources, d_bandwidths, d_latencies,
        jr, jb, jl,
        d_best
    );

    /* Error Checking
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) {
        printf("Kernel launch error: %s\n", cudaGetErrorString(err));
        return;
    }
    cudaDeviceSynchronize();
    err = cudaGetLastError();
    if (err != cudaSuccess) {
        printf("Kernel execution error: %s\n", cudaGetErrorString(err));
        return;
    }
    */
    cudaDeviceSynchronize();

    // copy back to host
    BestPair host_best;
    cudaMemcpy(&host_best, d_best, sizeof(BestPair), cudaMemcpyDeviceToHost);

    *best_of = host_best.of;
    *best_comb = host_best.idx;

    cudaFree(d_resources);
    cudaFree(d_bandwidths);
    cudaFree(d_latencies);
    cudaFree(d_best);
}