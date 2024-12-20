cmake_minimum_required(VERSION 3.31.2)

find_program(CCACHE_FOUND ccache)
if(CCACHE_FOUND)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
endif()

project(OpenCVProject LANGUAGES CXX)

find_package(OpenCV REQUIRED)
find_package(Boost REQUIRED)

add_executable(HelloWorld)

target_sources(HelloWorld
  PRIVATE
    ${CMAKE_SOURCE_DIR}/src/main.cpp
)

target_include_directories(HelloWorld
  PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${OpenCV_INCLUDE_DIRS}
    ${Boost_INCLUDE_DIR}
)

target_link_libraries(HelloWorld 
  PRIVATE
    ${OpenCV_LIBS}
    ${Boost_LIBRARIES}
)

enable_testing()
add_subdirectory(tests)
