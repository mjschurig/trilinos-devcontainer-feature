#!/bin/bash

echo "=== Trilinos Installation Debug Script ==="
echo "This script helps diagnose library detection issues"
echo ""

INSTALLPREFIX=${1:-/usr/local}

echo "Install prefix: $INSTALLPREFIX"
echo ""

echo "=== Checking directory structure ==="
echo "Contents of $INSTALLPREFIX:"
ls -la "$INSTALLPREFIX" 2>/dev/null || echo "Directory not found"
echo ""

echo "Contents of $INSTALLPREFIX/lib:"
ls -la "$INSTALLPREFIX/lib" 2>/dev/null || echo "Directory not found"
echo ""

echo "Contents of $INSTALLPREFIX/lib64:"
ls -la "$INSTALLPREFIX/lib64" 2>/dev/null || echo "Directory not found"
echo ""

echo "=== Searching for Trilinos libraries ==="
echo "Looking for any Trilinos libraries..."
find "$INSTALLPREFIX" -name "*.so*" -o -name "*.a" | grep -i trilinos 2>/dev/null || echo "No Trilinos libraries found"
echo ""

echo "Looking for teuchos libraries specifically..."
find "$INSTALLPREFIX" -name "*teuchos*" 2>/dev/null || echo "No teuchos libraries found"
echo ""

echo "Looking for any .so files in lib directories..."
find "$INSTALLPREFIX/lib" "$INSTALLPREFIX/lib64" -name "*.so*" 2>/dev/null | head -20 || echo "No .so files found"
echo ""

echo "=== Checking CMake configuration ==="
echo "Looking for TrilinosConfig.cmake..."
find "$INSTALLPREFIX" -name "TrilinosConfig.cmake" 2>/dev/null || echo "TrilinosConfig.cmake not found"
echo ""

echo "Looking for any Trilinos CMake files..."
find "$INSTALLPREFIX" -name "*Trilinos*" -name "*.cmake" 2>/dev/null || echo "No Trilinos CMake files found"
echo ""

echo "=== Checking headers ==="
echo "Looking for Trilinos headers..."
find "$INSTALLPREFIX/include" -name "*Teuchos*" 2>/dev/null | head -10 || echo "No Teuchos headers found"
echo ""

echo "=== Library linking information ==="
if [ -f "$INSTALLPREFIX/lib/libteuchos.so" ]; then
    echo "libteuchos.so found, checking dependencies:"
    ldd "$INSTALLPREFIX/lib/libteuchos.so" 2>/dev/null || echo "ldd failed"
elif [ -f "$INSTALLPREFIX/lib64/libteuchos.so" ]; then
    echo "libteuchos.so found in lib64, checking dependencies:"
    ldd "$INSTALLPREFIX/lib64/libteuchos.so" 2>/dev/null || echo "ldd failed"
else
    echo "libteuchos.so not found in expected locations"
fi
echo ""

echo "=== Environment variables ==="
echo "TRILINOS_DIR: $TRILINOS_DIR"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo "CMAKE_PREFIX_PATH: $CMAKE_PREFIX_PATH"
echo ""

echo "=== CMake test ==="
echo "Testing if CMake can find Trilinos..."
cd /tmp
cat > test_find_trilinos.cmake << 'EOF'
cmake_minimum_required(VERSION 3.10)
find_package(Trilinos QUIET)
if(Trilinos_FOUND)
    message(STATUS "Trilinos found!")
    message(STATUS "Trilinos_VERSION: ${Trilinos_VERSION}")
    message(STATUS "Trilinos_LIBRARIES: ${Trilinos_LIBRARIES}")
    message(STATUS "Trilinos_INCLUDE_DIRS: ${Trilinos_INCLUDE_DIRS}")
else()
    message(STATUS "Trilinos NOT found")
endif()
EOF

cmake -P test_find_trilinos.cmake 2>&1 || echo "CMake test failed"
rm -f test_find_trilinos.cmake
echo ""

echo "=== Debug complete ===" 