set(CMAKE_CXX_STANDARD 23)

add_library(libdimna)

find_package(tabulate CONFIG REQUIRED)
find_package(OpenMP REQUIRED)

target_sources(libdimna
  PRIVATE
    policy/searcher/kernel/comb_searcher.cu
  )

target_sources(libdimna
  PUBLIC
  FILE_SET HEADERS
  BASE_DIRS ${CMAKE_SOURCE_DIR}
  FILES
  allocator/DiAllocator.hpp
  allocator/DiRunner.hpp
  io/OutputWriter.hpp
  model/Solution.hpp
  model/Options.hpp
  model/Times.hpp
  policy/filter/FixedFilter.hpp
  policy/filter/CanonFixedFilter.hpp
  policy/filter/OpenMPFixedFilter.hpp
  policy/searcher/FixedSearcher.hpp
  policy/searcher/OpenMPFixedSearcher.hpp
  policy/searcher/CudaCombinatorialSearcher.hpp
)

target_link_libraries(libdimna
  PRIVATE
  libMNA
  PUBLIC
  OpenMP::OpenMP_CXX
)

target_link_libraries(libdimna PUBLIC
 tabulate::tabulate
)
# target_compile_options(libgraphs PRIVATE -Werror)

set_target_properties(libdimna PROPERTIES PREFIX "")
