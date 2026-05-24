#ifndef __kernel_h__
#define __kernel_h__

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
);

#endif // __kernel_h__