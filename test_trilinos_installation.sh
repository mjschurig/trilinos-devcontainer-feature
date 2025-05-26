#!/bin/bash

echo "=== Trilinos Installation Test ==="
echo "This script tests the Trilinos devcontainer feature installation"
echo ""

# Set up test environment
INSTALL_PREFIX="/usr/local"
TEST_DIR="/tmp/trilinos_test_$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "Test directory: $TEST_DIR"
echo "Install prefix: $INSTALL_PREFIX"
echo ""

# Test 1: Check headers
echo "Test 1: Checking for Trilinos headers..."
if [ -f "$INSTALL_PREFIX/include/Teuchos_Version.hpp" ]; then
    echo "✓ Teuchos headers found"
else
    echo "✗ Teuchos headers not found"
    echo "Searching for any Trilinos headers..."
    find "$INSTALL_PREFIX/include" -name "*Teuchos*" 2>/dev/null | head -5 || echo "No Trilinos headers found"
fi
echo ""

# Test 2: Check libraries
echo "Test 2: Checking for Trilinos libraries..."
LIB_FOUND=false
for lib_dir in "$INSTALL_PREFIX/lib" "$INSTALL_PREFIX/lib64"; do
    if [ -d "$lib_dir" ]; then
        echo "Checking $lib_dir..."
        for pattern in "libteuchos*" "libteuchoscore*" "libteuchoscomm*"; do
            files=$(ls "$lib_dir"/$pattern 2>/dev/null)
            if [ -n "$files" ]; then
                echo "✓ Found libraries: $files"
                LIB_FOUND=true
                break
            fi
        done
    fi
done

if [ "$LIB_FOUND" = "false" ]; then
    echo "✗ No Trilinos libraries found in standard locations"
    echo "Searching entire install prefix..."
    find "$INSTALL_PREFIX" -name "*teuchos*" 2>/dev/null | head -10 || echo "No teuchos files found"
fi
echo ""

# Test 3: Check CMake configuration
echo "Test 3: Checking for CMake configuration..."
CMAKE_FOUND=false
for cmake_dir in "$INSTALL_PREFIX/lib/cmake/Trilinos" "$INSTALL_PREFIX/lib64/cmake/Trilinos" "$INSTALL_PREFIX/share/cmake/Trilinos"; do
    if [ -f "$cmake_dir/TrilinosConfig.cmake" ]; then
        echo "✓ Found TrilinosConfig.cmake in $cmake_dir"
        CMAKE_FOUND=true
        break
    fi
done

if [ "$CMAKE_FOUND" = "false" ]; then
    echo "✗ TrilinosConfig.cmake not found in standard locations"
    echo "Searching for CMake files..."
    find "$INSTALL_PREFIX" -name "TrilinosConfig.cmake" 2>/dev/null || echo "No TrilinosConfig.cmake found"
fi
echo ""

# Test 4: Test CMake find_package
echo "Test 4: Testing CMake find_package..."
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(TrilinosTest)

find_package(Trilinos QUIET)

if(Trilinos_FOUND)
    message(STATUS "SUCCESS: Trilinos found!")
    message(STATUS "Trilinos_VERSION: ${Trilinos_VERSION}")
    message(STATUS "Trilinos_LIBRARIES: ${Trilinos_LIBRARIES}")
    message(STATUS "Trilinos_INCLUDE_DIRS: ${Trilinos_INCLUDE_DIRS}")
    
    # Create a simple test program
    add_executable(test_program test.cpp)
    target_link_libraries(test_program ${Trilinos_LIBRARIES})
    target_include_directories(test_program PRIVATE ${Trilinos_INCLUDE_DIRS})
    target_compile_definitions(test_program PRIVATE ${Trilinos_CXX_COMPILER_FLAGS})
else()
    message(STATUS "FAILED: Trilinos not found by CMake")
    message(STATUS "CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}")
endif()
EOF

cat > test.cpp << 'EOF'
#include <iostream>

// Try to include Trilinos headers
#ifdef HAVE_TEUCHOS_CORE
#include "Teuchos_Version.hpp"
#define TRILINOS_AVAILABLE 1
#else
// Fallback - try direct include
#include <Teuchos_Version.hpp>
#define TRILINOS_AVAILABLE 1
#endif

int main() {
#ifdef TRILINOS_AVAILABLE
    try {
        std::cout << "Trilinos version: " << Teuchos::Teuchos_Version() << std::endl;
        std::cout << "✓ Trilinos test program: SUCCESS" << std::endl;
        return 0;
    } catch (const std::exception& e) {
        std::cout << "✗ Error running Trilinos test: " << e.what() << std::endl;
        return 1;
    }
#else
    std::cout << "✗ Trilinos headers not available" << std::endl;
    return 1;
#endif
}
EOF

# Try to configure with CMake
if cmake . 2>&1; then
    echo "✓ CMake configuration successful"
    
    # Try to build
    if make 2>&1; then
        echo "✓ Build successful"
        
        # Try to run the test program
        if [ -f "./test_program" ]; then
            echo "Running test program..."
            if ./test_program; then
                echo "✓ Test program execution successful"
            else
                echo "✗ Test program execution failed"
            fi
        else
            echo "✗ Test program not built"
        fi
    else
        echo "✗ Build failed"
    fi
else
    echo "✗ CMake configuration failed"
fi
echo ""

# Test 5: Check environment
echo "Test 5: Checking environment variables..."
echo "TRILINOS_DIR: ${TRILINOS_DIR:-not set}"
echo "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH:-not set}"
echo "CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH:-not set}"
echo ""

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo "=== Test Complete ===" 