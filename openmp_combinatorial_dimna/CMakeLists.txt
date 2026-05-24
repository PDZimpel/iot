find_package(OpenMP REQUIRED)

add_executable(combinatorial_dimna main.cpp)

target_link_libraries(combinatorial_dimna
  PRIVATE
  libMNA
  libdimna
)

target_compile_options(combinatorial_dimna PRIVATE ${OpenMP_CXX_FLAGS})
target_link_options(combinatorial_dimna PRIVATE ${OpenMP_CXX_FLAGS})
