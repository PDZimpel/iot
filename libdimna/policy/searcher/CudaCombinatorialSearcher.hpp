#pragma once
#include <algorithm>
#include <vector>
#include <cstdint>
#include <memory>
#include <array>
#include "kernel.h"

#include "libdimna/model/Solution.hpp"
#include "libMNA/model/iot_network.hpp"
#include "libMNA/model/job.hpp"

#include "libdimna/policy/constants.hpp"

namespace mna::di::policy {

/* Defines the search-space exploration algorithm
*/
class CudaCombSearcher{

private:
  int _cs;
  std::vector<int> _bbs;

public:
  CudaCombSearcher(int cut_sol=0) : _cs{cut_sol} {}

  int64_t
  binom(int n, int k)
  {
    int64_t top = 1;
    int64_t bot = 1;
    for(int i=1; i<=k; i++){
      top *= n-i+1;
      bot *= i;
    }
    return top/bot;
  }

  std::vector<int> infer_combination(const int64_t i, const int64_t n, int k)
  {
    int64_t b;
    std::vector<int> comb;

    int64_t prefix = 0;
    for(b = 0; b < k; b++){
        int64_t calc = binom(n, b + 1);
        if(i < prefix + calc)
            break;
        prefix += calc;
    }

    int size = b + 1;
    comb.reserve(size);

    if(b == 0){
        comb.push_back((int)(i - prefix));
        return comb;
    }

    int64_t idx = i - prefix;
    int x = 0;

    for(int j = b + 1; j > 0; j--){
        for(int v = x; v < n; v++){
            int64_t c = binom(n - v - 1, j - 1);
            if(idx < c){
                comb.push_back(v);
                x = v + 1;
                break;
            }else{
                idx -= c;
            }
        }
    }

    return comb;
}

  int64_t
  combinatorial_range(int n, int k)
  {
    _bbs.resize(k);
    int64_t prefix=0;

    for(int i=1; i<=k; i++){
      prefix+=binom(n, i);
      _bbs[i-1] = prefix;
    }
    return prefix;
  }

  Solution
  find_best_comb(
    std::shared_ptr<IoTNetwork> network,
    mna::Job& job, std::vector<int>& valid_nodes,
    std::vector<int32_t>& latencies
  )
  {
    int num_nodes = valid_nodes.size();
    std::vector<int> resources, bandwidths, valid_latencies;
    resources.resize(num_nodes);
    bandwidths.resize(num_nodes);
    valid_latencies.resize(num_nodes);
    auto& nodes = network->vertexes();


    for(int i=0; i<valid_nodes.size(); i++){
      resources[i] = nodes[valid_nodes[i]].resource;
      bandwidths[i] = nodes[valid_nodes[i]].bandwidth;
      valid_latencies[i] = latencies[valid_nodes[i]];
    }

    int64_t best_comb;
    int64_t bof;
    search_comb_space(
  // Hyperparameters
    valid_nodes.size(),
    _cs,
    // Job Info
    job.resource,
    job.bandwidth,
    job.latency-1,
  // Network info
    resources.data(),
    bandwidths.data(),
    valid_latencies.data(),
  // Output
    &best_comb,
    &bof
  );

    //printf("BOF: %ld \t\n", bof);

    std::array<int, 3> bcomb;

    auto comb = infer_combination(best_comb, num_nodes, _cs);

    for(int i=0; i<comb.size(); i++){
      comb[i] = valid_nodes[comb[i]];
      //printf("%d ", comb[i]);
    }
    //printf("\n");

    return {bof, std::move(comb)};
  }

};

}
