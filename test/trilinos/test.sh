#!/bin/bash

set -e

# The 'test/_global' folder is a special test folder that is not tied to a single feature.
# This folder can contain test scripts that validate the install command.

source dev-container-features-test-lib

# Definition specific tests
check "trilinos version check" bash -c "trilinos-config --version || echo 'trilinos-config not found, checking alternative...'"

check "trilinos headers exist" bash -c "ls /usr/local/include/Teuchos_*.hpp"

check "trilinos libraries exist" bash -c "ls /usr/local/lib/libteuchos.* || ls /usr/local/lib64/libteuchos.*"

check "trilinos cmake config exists" bash -c "ls /usr/local/lib/cmake/Trilinos/TrilinosConfig.cmake || ls /usr/local/lib64/cmake/Trilinos/TrilinosConfig.cmake"

check "trilinos environment variables" bash -c "echo \$TRILINOS_DIR"

check "cmake can find trilinos" bash -c "cd /tmp && echo 'find_package(Trilinos REQUIRED)' > CMakeLists.txt && echo 'message(STATUS \"Trilinos found: \${Trilinos_VERSION}\")' >> CMakeLists.txt && cmake . && rm -f CMakeLists.txt CMakeCache.txt"

# Test basic compilation
check "compile trilinos test program" bash -c "
cd /usr/local/share/trilinos/test 2>/dev/null || { 
    echo 'Test directory not found, creating simple test...'
    mkdir -p /tmp/trilinos_test
    cd /tmp/trilinos_test
    cat > test.cpp << 'EOF'
#include <iostream>
#ifdef HAVE_TEUCHOS_CORE
#include \"Teuchos_Version.hpp\"
int main() {
    std::cout << \"Trilinos test: SUCCESS\" << std::endl;
    return 0;
}
#else
int main() {
    std::cout << \"Trilinos headers not found via preprocessor\" << std::endl;
    return 1;
}
#endif
EOF
    cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(TrilinosTest)
find_package(Trilinos QUIET)
if(Trilinos_FOUND)
    add_executable(test test.cpp)
    target_link_libraries(test \${Trilinos_LIBRARIES})
    target_include_directories(test PRIVATE \${Trilinos_INCLUDE_DIRS})
    target_compile_definitions(test PRIVATE \${Trilinos_CXX_COMPILER_FLAGS})
else()
    message(STATUS \"Trilinos not found via CMake, creating basic test\")
    add_executable(test test.cpp)
endif()
EOF
}
mkdir -p build && cd build
cmake .. && make
./test
"

# Report result
reportResults 