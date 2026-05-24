find_package(OpenMP REQUIRED)

add_executable(gradient_dimna main.cpp)

target_link_libraries(gradient_dimna
  PRIVATE
  libMNA
  libdimna
)

target_compile_options(gradient_dimna PRIVATE ${OpenMP_CXX_FLAGS})
target_link_options(gradient_dimna PRIVATE ${OpenMP_CXX_FLAGS})
