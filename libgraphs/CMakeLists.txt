
set(CMAKE_CXX_STANDARD 23)

# Header-only now that modules are gone (Graph.hpp has no compiled sources).
add_library(libgraphs INTERFACE)

target_sources(libgraphs
  INTERFACE
  FILE_SET HEADERS
  BASE_DIRS ${CMAKE_SOURCE_DIR}
  FILES
  model/Graph.hpp
)
