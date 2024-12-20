#include <iostream>
#include <boost/filesystem.hpp>

auto main(int argc, char **argv) -> int
{
  if (argc != 2)
  {
    std::cout << "usage: HelloWorld <File_Path>\n";
    return -1;
  }

  boost::filesystem::path path(argv[1]);

  if (boost::filesystem::exists(path) && boost::filesystem::is_regular_file(path))
  {
    std::cout << "File\n";
  }
  else
  {
    std::cout << "No File\n";
    return -1;
  }

  return 0;
}
