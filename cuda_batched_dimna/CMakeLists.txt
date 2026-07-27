add_executable(cuda_dimna)

target_sources(cuda_dimna
  PRIVATE
  main.cpp
  PRIVATE
  # FILE_SET cxx_modules TYPE CXX_MODULES FILES
)
target_link_libraries(cuda_dimna
  PRIVATE
  libMNA
  libdimna
)
