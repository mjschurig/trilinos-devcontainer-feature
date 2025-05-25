#!/bin/bash

set -e

# Import the specified key in a variable name passed in as 
USERNAME=${USERNAME:-"automatic"}

# Get the current script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Activating feature 'trilinos'"

# Parse input options
VERSION=${VERSION:-latest}
ENABLEMPI=${ENABLEMPI:-true}
ENABLEKOKKOS=${ENABLEKOKKOS:-true}
ENABLETPETRA=${ENABLETPETRA:-true}
ENABLEBELOS=${ENABLEBELOS:-true}
ENABLEIFPACK2=${ENABLEIFPACK2:-true}
ENABLEMUELU=${ENABLEMUELU:-false}
ENABLEZOLTAN=${ENABLEZOLTAN:-false}
ENABLEZOLTAN2=${ENABLEZOLTAN2:-false}
BUILDTYPE=${BUILDTYPE:-Release}
INSTALLPREFIX=${INSTALLPREFIX:-/usr/local}
ENABLESHAREDLIBS=${ENABLESHAREDLIBS:-true}
ENABLETESTS=${ENABLETESTS:-false}
ENABLEEXAMPLES=${ENABLEEXAMPLES:-false}
PARALLELJOBS=${PARALLELJOBS:-auto}
ENABLEFLOAT=${ENABLEFLOAT:-false}
ENABLECOMPLEX=${ENABLECOMPLEX:-false}

echo "Installing Trilinos with the following options:"
echo "  Version: $VERSION"
echo "  MPI: $ENABLEMPI"
echo "  Kokkos: $ENABLEKOKKOS"
echo "  Tpetra: $ENABLETPETRA"
echo "  Belos: $ENABLEBELOS"
echo "  Ifpack2: $ENABLEIFPACK2"
echo "  MueLu: $ENABLEMUELU"
echo "  Zoltan: $ENABLEZOLTAN"
echo "  Zoltan2: $ENABLEZOLTAN2"
echo "  Build Type: $BUILDTYPE"
echo "  Install Prefix: $INSTALLPREFIX"
echo "  Shared Libraries: $ENABLESHAREDLIBS"
echo "  Tests: $ENABLETESTS"
echo "  Examples: $ENABLEEXAMPLES"
echo "  Parallel Jobs: $PARALLELJOBS"
echo "  Float Support: $ENABLEFLOAT"
echo "  Complex Support: $ENABLECOMPLEX"

# Check if we are running as root
if [ "$(id -u)" -ne 0 ]; then
    echo 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Determine the non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u "${CURRENT_USER}" > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

# Get architecture
architecture="$(uname -m)"
case $architecture in
    x86_64) ARCH=amd64 ;;
    aarch64 | armv8*) ARCH=arm64 ;;
    aarch32 | armv7* | armvhf*) ARCH=arm ;;
    i?86) ARCH=386 ;;
    *) echo "(!) Architecture $architecture unsupported"; exit 1 ;;
esac

export DEBIAN_FRONTEND=noninteractive

# Function to check if packages are installed and install them if they aren't
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
            echo "Running apt update..."
            apt-get update -y
        fi
        apt-get -y install --no-install-recommends "$@"
    fi
}

# Install base development tools
echo "Installing base development tools..."
check_packages \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    ca-certificates \
    pkg-config \
    libtool \
    autotools-dev \
    autoconf \
    automake \
    ninja-build

# Install BLAS/LAPACK
echo "Installing BLAS/LAPACK..."
check_packages \
    libblas-dev \
    liblapack-dev \
    libblas3 \
    liblapack3

# Install MPI if enabled
if [ "$ENABLEMPI" = "true" ]; then
    echo "Installing MPI..."
    check_packages \
        libopenmpi-dev \
        openmpi-bin \
        openmpi-common \
        libopenmpi3
fi

# Install additional dependencies
echo "Installing additional dependencies..."
check_packages \
    libboost-all-dev \
    libhdf5-dev \
    libnetcdf-dev \
    zlib1g-dev \
    python3 \
    python3-dev \
    python3-numpy

# Determine number of parallel jobs
if [ "$PARALLELJOBS" = "auto" ]; then
    NPROC=$(nproc)
    # Use 75% of available cores, minimum 1, maximum 8
    JOBS=$(( NPROC * 3 / 4 ))
    if [ $JOBS -lt 1 ]; then
        JOBS=1
    elif [ $JOBS -gt 8 ]; then
        JOBS=8
    fi
else
    JOBS=$PARALLELJOBS
fi

echo "Using $JOBS parallel jobs for compilation"

# Determine Trilinos version and source
TRILINOS_SRC_DIR="/tmp/trilinos-source"
TRILINOS_BUILD_DIR="/tmp/trilinos-build"

if [ "$VERSION" = "latest" ]; then
    TRILINOS_VERSION="master"
    TRILINOS_URL="https://github.com/trilinos/Trilinos.git"
    echo "Cloning latest Trilinos from GitHub..."
    git clone --depth 1 --branch master "$TRILINOS_URL" "$TRILINOS_SRC_DIR"
else
    TRILINOS_VERSION="trilinos-release-${VERSION//./-}"
    TRILINOS_URL="https://github.com/trilinos/Trilinos.git"
    echo "Cloning Trilinos version $VERSION from GitHub..."
    git clone --depth 1 --branch "$TRILINOS_VERSION" "$TRILINOS_URL" "$TRILINOS_SRC_DIR" || {
        echo "Failed to clone specific version, trying without prefix..."
        git clone --depth 1 --branch "$VERSION" "$TRILINOS_URL" "$TRILINOS_SRC_DIR" || {
            echo "Failed to clone version $VERSION, falling back to master..."
            git clone --depth 1 --branch master "$TRILINOS_URL" "$TRILINOS_SRC_DIR"
        }
    }
fi

# Create build directory
mkdir -p "$TRILINOS_BUILD_DIR"
cd "$TRILINOS_BUILD_DIR"

# Build CMake configuration
CMAKE_ARGS=(
    "-DCMAKE_BUILD_TYPE=$BUILDTYPE"
    "-DCMAKE_INSTALL_PREFIX=$INSTALLPREFIX"
    "-DBUILD_SHARED_LIBS=$ENABLESHAREDLIBS"
    "-DTrilinos_ENABLE_ALL_PACKAGES=OFF"
    "-DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF"
    "-DTrilinos_ENABLE_TESTS=$ENABLETESTS"
    "-DTrilinos_ENABLE_EXAMPLES=$ENABLEEXAMPLES"
)

# Configure MPI
if [ "$ENABLEMPI" = "true" ]; then
    CMAKE_ARGS+=(
        "-DTPL_ENABLE_MPI=ON"
        "-DMPI_BASE_DIR=/usr"
    )
else
    CMAKE_ARGS+=("-DTPL_ENABLE_MPI=OFF")
fi

# Enable BLAS/LAPACK
CMAKE_ARGS+=(
    "-DTPL_ENABLE_BLAS=ON"
    "-DTPL_ENABLE_LAPACK=ON"
)

# Configure scalar types
if [ "$ENABLEFLOAT" = "true" ]; then
    CMAKE_ARGS+=("-DTrilinos_ENABLE_FLOAT=ON")
fi

if [ "$ENABLECOMPLEX" = "true" ]; then
    CMAKE_ARGS+=("-DTrilinos_ENABLE_COMPLEX=ON")
fi

# Enable core packages
CMAKE_ARGS+=("-DTrilinos_ENABLE_Teuchos=ON")

# Configure Kokkos
if [ "$ENABLEKOKKOS" = "true" ]; then
    CMAKE_ARGS+=(
        "-DTrilinos_ENABLE_Kokkos=ON"
        "-DTrilinos_ENABLE_KokkosKernels=ON"
    )
fi

# Configure Tpetra
if [ "$ENABLETPETRA" = "true" ]; then
    CMAKE_ARGS+=("-DTrilinos_ENABLE_Tpetra=ON")
fi

# Configure Belos
if [ "$ENABLEBELOS" = "true" ]; then
    CMAKE_ARGS+=("-DTrilinos_ENABLE_Belos=ON")
fi

# Configure Ifpack2
if [ "$ENABLEIFPACK2" = "true" ]; then
    CMAKE_ARGS+=("-DTrilinos_ENABLE_Ifpack2=ON")
fi

# Configure MueLu
if [ "$ENABLEMUELU" = "true" ]; then
    CMAKE_ARGS+=("-DTrilinos_ENABLE_MueLu=ON")
fi

# Configure Zoltan
if [ "$ENABLEZOLTAN" = "true" ]; then
    CMAKE_ARGS+=("-DTrilinos_ENABLE_Zoltan=ON")
fi

# Configure Zoltan2
if [ "$ENABLEZOLTAN2" = "true" ]; then
    CMAKE_ARGS+=("-DTrilinos_ENABLE_Zoltan2=ON")
fi

# Additional performance and compatibility options
CMAKE_ARGS+=(
    "-DTrilinos_ENABLE_EXPLICIT_INSTANTIATION=ON"
    "-DTrilinos_ENABLE_THREAD_SAFE=ON"
    "-DCMAKE_CXX_STANDARD=14"
)

echo "Configuring Trilinos with CMake..."
echo "CMake arguments: ${CMAKE_ARGS[*]}"

cmake "${CMAKE_ARGS[@]}" "$TRILINOS_SRC_DIR"

echo "Building Trilinos (this may take a while)..."
make -j$JOBS

echo "Installing Trilinos..."
make install

# Create environment setup script
ENV_SCRIPT="$INSTALLPREFIX/bin/trilinos-env.sh"
mkdir -p "$(dirname "$ENV_SCRIPT")"

cat > "$ENV_SCRIPT" << EOF
#!/bin/bash
# Trilinos environment setup script

export TRILINOS_DIR="$INSTALLPREFIX"
export CMAKE_PREFIX_PATH="\$TRILINOS_DIR:\$CMAKE_PREFIX_PATH"

# Add Trilinos libraries to library path
if [ -d "\$TRILINOS_DIR/lib" ]; then
    export LD_LIBRARY_PATH="\$TRILINOS_DIR/lib:\$LD_LIBRARY_PATH"
fi

if [ -d "\$TRILINOS_DIR/lib64" ]; then
    export LD_LIBRARY_PATH="\$TRILINOS_DIR/lib64:\$LD_LIBRARY_PATH"
fi

# Add Trilinos binaries to PATH
if [ -d "\$TRILINOS_DIR/bin" ]; then
    export PATH="\$TRILINOS_DIR/bin:\$PATH"
fi

echo "Trilinos environment configured:"
echo "  TRILINOS_DIR=\$TRILINOS_DIR"
echo "  Version: $VERSION"
echo "  Build Type: $BUILDTYPE"
EOF

chmod +x "$ENV_SCRIPT"

# Source the environment script in common shell initialization files
echo "# Trilinos environment" >> /etc/bash.bashrc
echo "if [ -f \"$ENV_SCRIPT\" ]; then" >> /etc/bash.bashrc
echo "    source \"$ENV_SCRIPT\"" >> /etc/bash.bashrc
echo "fi" >> /etc/bash.bashrc

# Create a simple test program
TEST_PROGRAM_DIR="$INSTALLPREFIX/share/trilinos/test"
mkdir -p "$TEST_PROGRAM_DIR"

cat > "$TEST_PROGRAM_DIR/test_trilinos.cpp" << 'EOF'
#include <iostream>
#include "Teuchos_Version.hpp"

int main() {
    std::cout << "Trilinos version: " << Teuchos::Teuchos_Version() << std::endl;
    std::cout << "Trilinos installation test: SUCCESS" << std::endl;
    return 0;
}
EOF

cat > "$TEST_PROGRAM_DIR/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(TrilinosTest)

find_package(Trilinos REQUIRED)

add_executable(test_trilinos test_trilinos.cpp)
target_link_libraries(test_trilinos ${Trilinos_LIBRARIES})
target_include_directories(test_trilinos PRIVATE ${Trilinos_INCLUDE_DIRS})
target_compile_definitions(test_trilinos PRIVATE ${Trilinos_CXX_COMPILER_FLAGS})
EOF

cat > "$TEST_PROGRAM_DIR/README.md" << EOF
# Trilinos Test Program

This directory contains a simple test program to verify your Trilinos installation.

## Building and Running the Test

\`\`\`bash
cd $TEST_PROGRAM_DIR
mkdir build && cd build
cmake ..
make
./test_trilinos
\`\`\`

If Trilinos is installed correctly, you should see the version information and a success message.
EOF

# Clean up temporary directories
echo "Cleaning up temporary files..."
cd /
rm -rf "$TRILINOS_SRC_DIR" "$TRILINOS_BUILD_DIR"

# Test the installation
echo "Testing Trilinos installation..."
if [ -f "$INSTALLPREFIX/include/Teuchos_Version.hpp" ]; then
    echo "✓ Trilinos headers found"
else
    echo "✗ Trilinos headers not found"
    exit 1
fi

if [ -f "$INSTALLPREFIX/lib/libteuchos.so" ] || [ -f "$INSTALLPREFIX/lib64/libteuchos.so" ]; then
    echo "✓ Trilinos libraries found"
else
    echo "✗ Trilinos libraries not found"
    exit 1
fi

if [ -f "$INSTALLPREFIX/lib/cmake/Trilinos/TrilinosConfig.cmake" ] || [ -f "$INSTALLPREFIX/lib64/cmake/Trilinos/TrilinosConfig.cmake" ]; then
    echo "✓ Trilinos CMake configuration found"
else
    echo "✗ Trilinos CMake configuration not found"
    exit 1
fi

echo ""
echo "🎉 Trilinos installation completed successfully!"
echo ""
echo "Installation details:"
echo "  Install prefix: $INSTALLPREFIX"
echo "  Version: $VERSION"
echo "  Build type: $BUILDTYPE"
echo "  MPI enabled: $ENABLEMPI"
echo "  Kokkos enabled: $ENABLEKOKKOS"
echo "  Shared libraries: $ENABLESHAREDLIBS"
echo ""
echo "To use Trilinos in your CMake projects:"
echo "  find_package(Trilinos REQUIRED)"
echo "  target_link_libraries(your_target \${Trilinos_LIBRARIES})"
echo "  target_include_directories(your_target PRIVATE \${Trilinos_INCLUDE_DIRS})"
echo ""
echo "Environment script: $ENV_SCRIPT"
echo "Test program: $TEST_PROGRAM_DIR"
echo ""
echo "The Trilinos environment will be automatically configured in new shell sessions." 