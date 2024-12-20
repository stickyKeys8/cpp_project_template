find_package(GTest)

add_executable(UnitTest)

target_sources(UnitTest
  PRIVATE
    ${CMAKE_SOURCE_DIR}/tests/unit_test.cpp
)

target_include_directories(UnitTest
  PRIVATE
    ${CMAKE_SOURCE_DIR}/include
)

target_link_libraries(UnitTest
  PRIVATE
    gtest::gtest
)

include(CTest)
include(GoogleTest)
gtest_discover_tests(UnitTest)
