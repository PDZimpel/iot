add_executable(openmp_fixed_di_mna)

target_sources(openmp_fixed_di_mna
  PRIVATE
  main.cpp
  PRIVATE
  # FILE_SET cxx_modules TYPE CXX_MODULES FILES
)
target_link_libraries(openmp_fixed_di_mna
  PRIVATE
  libMNA
  libdimna
)
