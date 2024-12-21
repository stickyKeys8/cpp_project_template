Usage:

conan install . --build missing

Delete build folder before switching profiles.

conan install . --build missing --profile clang

Override settings from profiles.

conan install . --build missing -s build_type=Release

Then use the cmake presets conan generated.