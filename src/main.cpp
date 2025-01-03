#include <boost/filesystem.hpp>
#include <iostream>

auto main(int argc, char **argv) -> int {
  int blah = 123;

  boost::filesystem::path path(argv[1]);

  if (boost::filesystem::exists(path) &&
      boost::filesystem::is_regular_file(path)) {
    std::cout << "File\n";
  } else {
    std::cout << "No File\n";
    return -1;
  }

  return 0;
}
