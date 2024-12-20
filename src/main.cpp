#include <iostream>
#include <boost/filesystem.hpp>
#include <opencv2/opencv.hpp>

auto main(int argc, char **argv) -> int
{
  if (argc != 2)
  {
    std::cout << "usage: HelloWorld <Image_Path>\n";
    return -1;
  }

  cv::Mat image;
  boost::filesystem::path path(argv[1]);

  if (boost::filesystem::exists(path) && boost::filesystem::is_regular_file(path))
  {
    image = cv::imread(argv[1], cv::IMREAD_COLOR);
  }
  else
  {
    std::cout << "No image data \n";
    return -1;
  }

  cv::namedWindow("Display Image", cv::WINDOW_AUTOSIZE);
  cv::imshow("Display Image", image);
  cv::waitKey(0);

  return 0;
}
