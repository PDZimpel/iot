cmake_minimum_required(VERSION 4.0)

set(CMAKE_CXX_STANDARD 23)

# No GPU is required/present to compile (nvcc doesn't need one), so pick a
# broad set of real architectures rather than relying on device detection.
set(CMAKE_CUDA_ARCHITECTURES "all-major" CACHE STRING "CUDA architectures to build for")

project(graphs VERSION 0.0.1 LANGUAGES CXX CUDA)

include(CTest)

option(ENABLE_COVERAGE "Activate flags for gcov" OFF)
option(ENABLE_GPROG "Activate gprof" OFF)
if(ENABLE_COVERAGE)
    add_compile_options(--coverage -O0 -g)
    add_link_options(--coverage)
endif()

if(ENABLE_GPROF)  
    add_compile_options(-pg -O3 -g) 
    add_link_options(-pg)
else()
  add_compile_options(-O3)
endif()

# add_compile_options(-ftrapv)
add_link_options(-static-libgcc)
link_libraries(-Wl,-Bstatic -lgomp -Wl,-Bdynamic)

add_subdirectory(libgraphs)
add_subdirectory(libMNA)
add_subdirectory(libdimna)
# #add_subdirectory(dimna)
# add_subdirectory(canon_dimna)
add_subdirectory(openmp_gradient_dimna)
add_subdirectory(cuda_dimna)

# if (BUILD_TESTING)
  # add_subdirectory(test)
# endif()
