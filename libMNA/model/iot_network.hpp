#pragma once
#include "libgraphs/model/Graph.hpp"

namespace mna {

struct IoTNode{
  int resource;
  int bandwidth;
  int busy;
  int inactive;
};

struct IoTEdge{
  int target;
  int latency;
};

using IoTNetwork = graphs::Graph<graphs::VertexVector<IoTNode>, graphs::EdgeAdjacencyList<IoTEdge>>;

} // namespace mna
