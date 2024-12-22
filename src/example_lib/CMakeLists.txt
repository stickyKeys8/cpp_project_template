find_package(GTest)

add_library(ExampleLibrary SHARED)

target_sources(ExampleLibrary
  PRIVATE
    ${CMAKE_SOURCE_DIR}/src/example_lib/example_lib.cpp
)

target_include_directories(ExampleLibrary
  PRIVATE
    ${CMAKE_SOURCE_DIR}/include/example_lib
)

target_link_libraries(ExampleLibrary
  PRIVATE
    gtest::gtest
)

install(TARGETS ExampleLibrary RUNTIME DESTINATION bin)
include(CPack)
