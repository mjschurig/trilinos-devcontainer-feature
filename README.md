# Trilinos Dev Container Feature

A [Dev Container Feature](https://containers.dev/implementors/features/) for easily installing [Trilinos](https://trilinos.github.io/) - a collection of scientific computing libraries - into development containers.

## Usage

Add this feature to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/your-username/trilinos-devcontainer-feature/trilinos:1": {
      "version": "latest",
      "enableMPI": true,
      "enableKokkos": true,
      "buildType": "Release"
    }
  }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Trilinos version to install (`latest`, `15.0.0`, `14.4.0`, etc.) |
| `enableMPI` | boolean | `true` | Enable MPI support |
| `enableKokkos` | boolean | `true` | Enable Kokkos for parallel computing |
| `enableTpetra` | boolean | `true` | Enable Tpetra for linear algebra |
| `enableZoltan` | boolean | `false` | Enable Zoltan for load balancing |
| `buildType` | string | `Release` | CMake build type (`Release`, `Debug`, `RelWithDebInfo`) |
| `installPrefix` | string | `/usr/local` | Installation prefix path |
| `enableSharedLibs` | boolean | `true` | Build shared libraries |
| `enableTests` | boolean | `false` | Enable building tests |

## Requirements

- Debian-based container image (Ubuntu, Debian)
- At least 4GB RAM for compilation
- Sufficient disk space (~2GB for source + build)

## What's Installed

- Trilinos libraries and headers
- CMake configuration files for downstream projects
- Required system dependencies (compilers, MPI, BLAS/LAPACK)
- Environment variables for easy usage

## Example devcontainer.json

```json
{
  "name": "Trilinos Development Environment",
  "image": "mcr.microsoft.com/devcontainers/cpp:1-ubuntu-22.04",
  "features": {
    "ghcr.io/your-username/trilinos-devcontainer-feature/trilinos:1": {
      "version": "15.0.0",
      "enableMPI": true,
      "enableKokkos": true,
      "enableTpetra": true,
      "buildType": "Release"
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.cpptools",
        "ms-vscode.cmake-tools"
      ]
    }
  }
}
```

## Using Trilinos in Your Project

After installing this feature, you can use Trilinos in your CMake projects:

```cmake
find_package(Trilinos REQUIRED)
target_link_libraries(your_target ${Trilinos_LIBRARIES})
target_include_directories(your_target PRIVATE ${Trilinos_INCLUDE_DIRS})
```

## References

- [Trilinos Official Documentation](https://docs.trilinos.org/)
- [Trilinos Build Reference](https://docs.trilinos.org/files/TrilinosBuildReference.html)
- [Dev Container Features Specification](https://containers.dev/implementors/features/)

## License

MIT License - see [LICENSE](LICENSE) file for details.