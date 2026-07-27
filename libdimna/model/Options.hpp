#pragma once
#include <filesystem>

namespace mna::di {
struct Options{
  std::filesystem::path input_dir;
  std::filesystem::path output_dir;
  int cut_sol;
  int cut_comb_nodes;
  int sample_size;
  int numRunnings;
};
}
