cmake_minimum_required(VERSION 3.31.2)

find_program(CCACHE_FOUND ccache)
if(CCACHE_FOUND)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
endif()

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

project(HelloWorldProject LANGUAGES CXX)

find_package(Boost REQUIRED)

add_executable(HelloWorld)

target_sources(HelloWorld
  PRIVATE
    ${CMAKE_SOURCE_DIR}/src/main.cpp
)

target_include_directories(HelloWorld
  PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${Boost_INCLUDE_DIR}
)

target_link_libraries(HelloWorld 
  PRIVATE
    ${Boost_LIBRARIES}
)

enable_testing()
add_subdirectory(tests)
