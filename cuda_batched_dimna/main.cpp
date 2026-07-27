#include <iostream>
#include <vector>
#include <memory>
#include <filesystem>
#include <string>
#include "libMNA/io/cli_parser.hpp"
#include "libMNA/io/directory_scanner.hpp"
#include "libMNA/io/ParquetReader.hpp"
#include "libMNA/model/iot_network.hpp"
#include "libMNA/model/job.hpp"
#include "libdimna/allocator/DiRunner.hpp"
#include "libdimna/model/Solution.hpp"
#include "libdimna/model/Options.hpp"
#include "libdimna/io/OutputWriter.hpp"
#include "libdimna/allocator/DiAllocator.hpp"
#include "libdimna/policy/searcher/CudaCombinatorialSearcher.hpp"

mna::di::Options setup_options(int argc, char* argv[]);
std::shared_ptr<mna::IoTNetwork> setup_network(mna::InstanceStructure& instance, mna::ParquetReader& pr);
mna::JobVector setup_jobs(std::filesystem::path& jobs_file, mna::ParquetReader& pr);
void run(std::shared_ptr<mna::IoTNetwork> network, mna::JobVector& jobs, mna::di::Options di_options);

int
main (int argc, char *argv[]) {
  
  mna::di::Options di_options = setup_options(argc, argv);
  mna::InstancesMap instances_map = mna::scan_input_dir(di_options.input_dir);
  
  mna::ParquetReader pr;

  
  constexpr int CUT_SOL = 2;
  
  // Looping on different networks present at the input folder
  for (auto& [key, instance] : instances_map){
  
    auto network = setup_network(instance, pr);

    // Looping through jobs configurantions (light and heavy)
    for (auto& jobs_file : instance.jobs){
      mna::JobVector jobs = setup_jobs(jobs_file, pr);
      
      run(network, jobs, di_options);
    }
  }
  return 0;
}

void 
run(std::shared_ptr<mna::IoTNetwork> network, mna::JobVector& jobs, mna::di::Options di_options){
 
  switch (di_options.cut_sol){
    case 1:{
      mna::di::DiRunner<mna::di::CudaAllocator<1>> runner(network, di_options);

      runner.run_mna_jobs_batch(jobs, di_options.sample_size);
    }
    break;
    case 2:{
      mna::di::DiRunner<mna::di::CudaAllocator<2>> runner(network, di_options);

      runner.run_mna_jobs_batch(jobs, di_options.sample_size);
    }  
    break;
    case 3:{
      mna::di::DiRunner<mna::di::CudaAllocator<3>> runner(network, di_options);

      runner.run_mna_jobs_batch(jobs, di_options.sample_size);
    }
      break;
 } 
}

mna::di::Options
setup_options(int argc, char* argv[]){
  
  std::string str_cs;
  std::string str_ccn;
  std::string str_nR;
  std::string str_ss;

  mna::OptionsMap map = {{"--cs", &str_cs},
                        {"--ccn", &str_ccn},
                        {"--runs", &str_nR},
                        {"--sample_size", &str_ss}};

  mna::Config config = mna::read_CLI(argc, argv, map);

  int cut_sol = std::stoi(str_cs);
  int cut_comb_nodes = std::stoi(str_ccn);
  int numRunnings = std::stoi(str_nR);
  int sample_size = std::stoi(str_ss);

  return {config.input_folder, config.output_folder, cut_sol, cut_comb_nodes, sample_size, numRunnings};
}

std::shared_ptr<mna::IoTNetwork>
setup_network(mna::InstanceStructure& instance, mna::ParquetReader& pr){

  int total_vertexes = *(pr.get_num_rows(instance.nodes));

  auto network = std::make_shared<mna::IoTNetwork>(total_vertexes);

  using vertex_type = decltype(network)::element_type::vertex_type;
  using edge_type = decltype(network)::element_type::edge_type;

  auto add_edge = [&](int32_t source, int32_t target, int32_t latency){
    network->add_edge(edge_type{target, latency}, source); 
  };
  auto add_vertex = [&](int64_t R, int64_t B, int64_t busy, int64_t inactive){
    network->add_vertex(vertex_type{R, B, busy, inactive});
  };
  
  pr.read_vertexes(instance.nodes, add_vertex);
  pr.read_edges(instance.edges, add_edge);

  return network;
}

mna::JobVector
setup_jobs(std::filesystem::path& jobs_file, mna::ParquetReader& pr){

  mna::JobVector jobsV;

  auto add_job = [&](int64_t jr, int64_t jb, int64_t jl, int64_t jo){
    jobsV.push_back(mna::Job{jr, jb, jl, jo});
  };

  pr.read_jobs(jobs_file, add_job);

  return jobsV;
}
