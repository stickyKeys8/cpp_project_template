from conan import ConanFile
from conan.tools.cmake import CMake, cmake_layout, CMakeToolchain, CMakeDeps

class BasicConanfile(ConanFile):
    name = "mypkg"
    version = "0.1"
    description = "A basic recipe"
    license = "<Your project license goes here>"
    homepage = "<Your project homepage goes here>"
    settings = "os", "compiler", "build_type", "arch"
    generators = "CMakeToolchain", "CMakeDeps"

    def requirements(self):
        self.requires("gtest/1.15.0")
        self.requires("boost/1.86.0")

    def build_requirements(self):
        pass
    
    def layout(self):
        cmake_layout(self)

    def generate(self):
        pass

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()
        pass

    def package(self):
        cmake = CMake(self)
        cmake.install()
