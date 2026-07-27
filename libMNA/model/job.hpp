#pragma once
#include <vector>

namespace mna {

struct Job{
  int resource;
  int bandwidth;
  int latency;
  int origin;
};

using JobVector = std::vector<Job>;
}
