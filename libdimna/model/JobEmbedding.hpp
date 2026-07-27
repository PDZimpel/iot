#pragma once
#include "libMNA/model/job.hpp"
#include <memory>
#include <vector>
#include "faiss/Index.h"

namespace mna::di{
struct JobEmbedding
{
    std::shared_ptr<mna::Job> job;
    std::vector<float> embedding;

    JobEmbedding(float attr_mult = 1.0, float landmark_mult = 1.0):
        _attr{attr_mult},
        _l{landmark_mult},
        job{nullptr},
        embedding{}
    {
        // do nothing
    }

    
    void
    add_landmark(float dist)
    {
        embedding.emplace_back(dist * _l);
    }

    void
    finalize()
    {
        embedding.push_back(job->bandwidth * _attr);
        embedding.push_back(job->resource * _attr);
        embedding.push_back(job->latency * _attr);
    }

    float* data(){
        return embedding.data();
    }

private:

    float _attr;
    float _l;

};

}