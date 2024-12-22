#include <gtest/gtest.h>
#include <example_lib.hpp>

TEST(ExampleLibrary, AddNumbers)
{
    ASSERT_EQ(6, add(3, 3));
}