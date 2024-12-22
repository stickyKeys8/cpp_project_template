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

# Packaging support
set(CPACK_PACKAGE_VENDOR "Vendor name")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Some summary")
set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.md")

set(CPACK_SOURCE_GENERATOR "TGZ;ZIP")
set(CPACK_SOURCE_IGNORE_FILES
    /.git
    /build
)

install(TARGETS ExampleLibrary RUNTIME DESTINATION lib)
install (DIRECTORY ${CMAKE_SOURCE_DIR}/include/example_lib DESTINATION include) 

include(CPack)
