#pragma once
#include <cstdint>
#include <vector>
#include <memory>
#include <queue>
#include <set>
#include <algorithm>
#include <iterator>
#include <utility>
#include <iostream>
#include <chrono>
#include <random>
#include <algorithm>

#include <faiss/IndexFlat.h>
#include <faiss/IndexFlat.h>
#include <faiss/gpu/StandardGpuResources.h>

#include "libMNA/model/iot_network.hpp"
#include "libMNA/model/job.hpp"
#include "libdimna/model/JobEmbedding.hpp"
#include "libdimna/model/Solution.hpp"
#include "libdimna/model/Times.hpp"

#include "libdimna/policy/filter/FixedFilter.hpp"
#include "libdimna/policy/filter/CanonFixedFilter.hpp"
#include "libdimna/policy/filter/OpenMPFixedFilter.hpp"

#include "libdimna/policy/searcher/FixedSearcher.hpp"
#include "libdimna/policy/searcher/OpenMPFixedSearcher.hpp"
#include "libdimna/policy/searcher/CudaCombinatorialSearcher.hpp"
#include "libdimna/policy/constants.hpp"

namespace mna::di {

using policy::INF64;
using policy::INF32;
using policy::t_c;
using policy::INVALID_NODE;
using policy::NUM_ATTRIBUTES;

struct Result{
  std::vector<Solution> solutions;
  Times times;
};

inline int 
bounded_rand(int bound)
{
    return rand() % bound;
}

class 
BatchedAllocator{
private:

    int _cs;                                // Cut Sol
    int _ccn;                               // Cut Comb Nodes
    int _d;                                 // Dimension of Dataset
    int _nb;                                // Dataset Size
    std::shared_ptr<mna::IoTNetwork> _n;    // Network
    faiss::IndexFlatL2 _db;                 // Index Database
    std::set<int> _l;                       // landmarks
    std::vector<mna::di::JobEmbedding> _j;  // Embeddings

public:

    BatchedAllocator(
        int cut_sol, 
        int cut_comb_nodes, 
        int num_landmarks, 
        int db_size, 
        std::shared_ptr<mna::IoTNetwork> network,
        std::vector<mna::JobVector> jobs,
        float attribute_weight = 1.0f,
        float landmark_weight = 1.0f
    ):
        _cs{cut_sol},
        _ccn{cut_comb_nodes},
        _d{num_landmarks + NUM_ATTRIBUTES},
        _nb{db_size},
        _db{_d},
        _n{network}
    {
        // Assign jobs to embeddings
        _j = std::vector<mna::di::JobEmbedding>(jobs.size(), {attribute_weight, landmark_weight});
        for(int i=0; i<jobs.size(); i++){
            _j[i].job = std::make_shared<Job>(jobs[i]);
        }

        // Process and inserts embeddings
        _process_embeddings(num_landmarks);
        _db = faiss::IndexFlatL2(_d);
        for(auto& emb : _j){
            _db.add(1, emb.data());
        }
        
    }

private:
    void
    _process_embeddings(int nl)
    {
        auto vc = _n->vertex_count();
        assert(nl < vc);

        // Elects first landmark randomly
        int origin = bounded_rand(vc);
        _l.insert(origin);

        // Minimal Distance vector, will keep the smaller distance to all landmarks
        std::vector<int> md(vc, INT_MAX);

        // Calculates Distances from landmark and elects next based on biggest distance
        std::vector<int32_t> cl{};
        for(int i=0; i<nl; i++){
            // Calculates Distances
            _get_latencies(origin, cl);

            // Updates Minimal Distance Vector
            for(int j = 0; j < vc; j++){
                md[j] = std::min(cl[j], md[j]);
            }

            // Fills Embedding
            for(auto& embedding: _j){
                embedding.add_landmark(cl[embedding.job->origin]);
            }

            // Generates next origin that was not already used
            auto next = std::max_element(md.begin(), md.end());
            origin = std::distance(md.begin(), next);
            _l.insert(origin);
        } 

        for(auto& emb: _j){
            emb.finalize();
        }
    }

    struct nodePair{
        int32_t latency;
        int32_t node;
    };

    void
    _get_latencies(int origin, std::vector<int32_t>& latencies){
        auto cmp = [](nodePair a, nodePair b){return a.latency > b.latency;};
        std::priority_queue<nodePair, std::vector<nodePair>, decltype(cmp)> heap(cmp);

        // Resets the latencies vector
        std::fill(latencies.begin(), latencies.end(), INF32);

        // Inclusion of origin node
        latencies[origin] = 0;

        heap.push(nodePair{0, origin});

        while (!heap.empty()) {
            auto [curr_lat, node] = heap.top();
            heap.pop();

            if (curr_lat > latencies[node])
            continue;

            // Getting all adjacent nodes
            const auto& edges = _n->get_vertex_edges(node);

            for (auto [target, weight] : edges){
            // Adds node back into the heap if the path is cheaper or includes it for the first time
                if (latencies[target] > curr_lat + weight){
                    latencies[target] = curr_lat + weight;
                    heap.push(nodePair{latencies[target], target});
                }
            }
        }
    }

};
}