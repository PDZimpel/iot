find_package(OpenMP REQUIRED)

add_executable(openmp_di_mna main.cpp)

target_link_libraries(openmp_di_mna
  PRIVATE
  libMNA
  libdimna
)

target_compile_options(openmp_di_mna PRIVATE ${OpenMP_CXX_FLAGS})
target_link_options(openmp_di_mna PRIVATE ${OpenMP_CXX_FLAGS})
