# Trilinos (trilinos)

Installs [Trilinos](https://trilinos.github.io/) - a collection of scientific computing libraries for engineering and science applications.

## Example Usage

```json
"features": {
    "ghcr.io/maxschurig/trilinos-devcontainer-feature/trilinos:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the Trilinos version to install | string | latest |
| enableMPI | Enable MPI support | boolean | true |
| enableKokkos | Enable Kokkos for parallel computing and performance portability | boolean | true |
| enableTpetra | Enable Tpetra for next-generation linear algebra | boolean | true |
| enableBelos | Enable Belos for iterative linear solvers | boolean | true |
| enableIfpack2 | Enable Ifpack2 for algebraic preconditioners | boolean | true |
| enableMueLu | Enable MueLu for multigrid preconditioning | boolean | false |
| enableZoltan | Enable Zoltan for load balancing and partitioning | boolean | false |
| enableZoltan2 | Enable Zoltan2 for next-generation partitioning | boolean | false |
| buildType | CMake build type | string | Release |
| installPrefix | Installation prefix path | string | /usr/local |
| enableSharedLibs | Build shared libraries instead of static | boolean | true |
| enableTests | Enable building and running tests (increases build time significantly) | boolean | false |
| enableExamples | Enable building examples | boolean | false |
| parallelJobs | Number of parallel jobs for compilation (auto, or number like 4) | string | auto |
| enableFloat | Enable float scalar type support | boolean | false |
| enableComplex | Enable complex scalar type support | boolean | false |
| cxxStandard | C++ standard version (latest Trilinos requires 17+) | string | 23 |

## Supported Trilinos Versions

- `latest` (master branch)
- `15.0.0`
- `14.4.0`
- `14.2.0`
- `14.0.0`
- `13.4.1`

## What's Installed

- **Trilinos libraries**: Core scientific computing libraries
- **Development headers**: C++ headers for development
- **CMake configuration**: For easy integration with CMake projects
- **Environment setup**: Automatic environment variable configuration
- **Test programs**: Sample programs to verify installation

## Core Packages

### Always Enabled
- **Teuchos**: Tools for writing portable object-oriented software

### Optional Packages (configurable)
- **Kokkos**: Performance portable programming model
- **Tpetra**: Next-generation sparse linear algebra
- **Belos**: Iterative linear solver collection
- **Ifpack2**: Algebraic preconditioner collection
- **MueLu**: Multigrid framework
- **Zoltan**: Load balancing and partitioning toolkit
- **Zoltan2**: Next-generation partitioning and load balancing

## System Requirements

- **Base Image**: Debian-based Linux (Ubuntu, Debian)
- **CMake**: 3.23.0+ (automatically installed if needed)
- **Compiler**: C++23 capable compiler (GCC 11+, Clang 12+) - C++17 minimum
- **RAM**: At least 4GB for compilation
- **Disk Space**: ~2GB for source code and build artifacts
- **Time**: 20-60 minutes depending on enabled packages and system specs

> **Note**: The feature automatically installs a newer version of CMake (3.25.0+) if the system version is too old. Latest Trilinos versions require CMake 3.23.0+ and C++17. The feature automatically adjusts C++ standard requirements based on the Trilinos version.

## Quick Start

### Basic Installation
```json
{
  "features": {
    "ghcr.io/maxschurig/trilinos-devcontainer-feature/trilinos:1": {
      "version": "15.0.0"
    }
  }
}
```

### Development Setup
```json
{
  "features": {
    "ghcr.io/maxschurig/trilinos-devcontainer-feature/trilinos:1": {
      "version": "latest",
      "enableMPI": true,
      "enableKokkos": true,
      "enableTpetra": true,
      "buildType": "Debug"
    }
  }
}
```

### Minimal Installation (faster build)
```json
{
  "features": {
    "ghcr.io/maxschurig/trilinos-devcontainer-feature/trilinos:1": {
      "enableMPI": false,
      "enableKokkos": false,
      "enableTpetra": false,
      "enableBelos": false,
      "enableIfpack2": false
    }
  }
}
```

## Using Trilinos in Your Project

### CMake Integration
```cmake
find_package(Trilinos REQUIRED)

# Create your executable
add_executable(my_app main.cpp)

# Link against Trilinos
target_link_libraries(my_app ${Trilinos_LIBRARIES})
target_include_directories(my_app PRIVATE ${Trilinos_INCLUDE_DIRS})
target_compile_definitions(my_app PRIVATE ${Trilinos_CXX_COMPILER_FLAGS})
```

### Environment Variables
After installation, the following environment variables are automatically set:
- `TRILINOS_DIR`: Points to the Trilinos installation directory
- `CMAKE_PREFIX_PATH`: Updated to include Trilinos
- `LD_LIBRARY_PATH`: Updated to include Trilinos libraries (if needed)
- `PATH`: Updated to include Trilinos binaries

### Testing Your Installation
```bash
# Run the built-in test program
cd /usr/local/share/trilinos/test
mkdir build && cd build
cmake .. && make && ./test_trilinos
```

## Build Configuration Examples

### High-Performance Computing
```json
{
  "enableMPI": true,
  "enableKokkos": true,
  "enableTpetra": true,
  "enableBelos": true,
  "enableIfpack2": true,
  "enableMueLu": true,
  "buildType": "Release"
}
```

### Scientific Computing Research
```json
{
  "enableMPI": true,
  "enableKokkos": true,
  "enableTpetra": true,
  "enableBelos": true,
  "enableIfpack2": true,
  "enableZoltan": true,
  "enableZoltan2": true,
  "enableFloat": true,
  "enableComplex": true,
  "buildType": "RelWithDebInfo",
  "cxxStandard": "20"
}
```

## Troubleshooting

### Build Issues
- If compilation fails due to memory constraints, try reducing `parallelJobs`
- For containers with limited resources, consider using minimal package selection
- Debug builds require significantly more memory than Release builds

### Runtime Issues
- Ensure `LD_LIBRARY_PATH` includes the Trilinos library directory
- Check that `TRILINOS_DIR` is properly set
- Verify CMake can find Trilinos with `find_package(Trilinos REQUIRED)`

### Common Problems
1. **"Cannot find Trilinos"**: Check that `CMAKE_PREFIX_PATH` includes your installation
2. **Linking errors**: Ensure you're linking against `${Trilinos_LIBRARIES}`
3. **Header not found**: Include `${Trilinos_INCLUDE_DIRS}` in your target

## Performance Notes

- **Shared vs Static**: Shared libraries are faster to link and use less disk space
- **Build Type**: Release builds are significantly faster than Debug builds
- **Package Selection**: Only enable packages you need to reduce build time and binary size
- **Parallel Jobs**: Auto-detected based on available CPU cores with reasonable limits

## Additional Resources

- [Trilinos Website](https://trilinos.github.io/)
- [Trilinos Documentation](https://docs.trilinos.org/)
- [Trilinos Build Reference](https://docs.trilinos.org/files/TrilinosBuildReference.html)
- [Trilinos GitHub Repository](https://github.com/trilinos/trilinos)
- [Trilinos User Guide](https://docs.trilinos.org/files/TrilinosUsersGuide.html)

---

_Note: This is a community-maintained feature. For issues related to the feature itself, please report them in this repository. For Trilinos-specific issues, please use the official Trilinos channels._ 