
set(CMAKE_CXX_STANDARD 23)

add_library(libMNA)

find_package(Arrow CONFIG REQUIRED)
find_package(Parquet CONFIG REQUIRED)

target_sources(libMNA
  PUBLIC
  FILE_SET HEADERS
  BASE_DIRS ${CMAKE_SOURCE_DIR}
  FILES
  model/iot_network.hpp
  model/job.hpp
  io/cli_parser.hpp
  io/ParquetReader.hpp
  io/directory_scanner.hpp

  PRIVATE
  io/ParquetReader.cpp
)
target_link_libraries(libMNA PUBLIC
  Arrow::arrow_static
  Parquet::parquet_static)

target_link_libraries(libMNA
  PRIVATE
  libgraphs
)

set_target_properties(libMNA PROPERTIES PREFIX "")
