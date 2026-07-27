#pragma once
#include <cstdint>

namespace mna::di::policy {
constexpr int64_t INF64 = 1LL << 40;
constexpr int INF32 = 1 << 30;
constexpr int t_c = 1;
constexpr int INVALID_NODE = -1;
constexpr int CHUNK_SIZE = 1000;
constexpr int NUM_ATTRIBUTES = 3; // number of attributes in a job
}
