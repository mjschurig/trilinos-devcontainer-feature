# Trilinos Dev Container Feature - Development Guide

This document provides information for developers working on this Trilinos Dev Container Feature.

## Project Structure

```
trilinos-devcontainer-feature/
├── src/
│   └── trilinos/                    # Main feature directory
│       ├── devcontainer-feature.json   # Feature metadata
│       ├── install.sh                  # Installation script
│       └── README.md                   # Feature documentation
├── test/
│   └── trilinos/                    # Test directory
│       ├── test.sh                     # Main test script
│       └── scenarios.json              # Test scenarios
├── examples/
│   └── devcontainer.json              # Example usage
├── .github/
│   └── workflows/
│       └── release.yml                 # CI/CD pipeline
├── devcontainer-collection.json       # Collection metadata
├── README.md                          # Main documentation
├── LICENSE                            # MIT License
└── .gitignore                         # Git ignore rules
```

## Local Development

### Prerequisites

1. [Dev Container CLI](https://github.com/devcontainers/cli):
   ```bash
   npm install -g @devcontainers/cli
   ```

2. Docker or compatible container runtime

### Testing Locally

#### Test Feature Installation
```bash
# Test against Ubuntu base image
devcontainer features test --skip-scenarios -f trilinos -i mcr.microsoft.com/devcontainers/base:ubuntu-22.04 .

# Test against C++ development image
devcontainer features test --skip-scenarios -f trilinos -i mcr.microsoft.com/devcontainers/cpp:1-ubuntu-22.04 .
```

#### Test Specific Scenarios
```bash
# Test all scenarios
devcontainer features test -f trilinos .

# Test specific scenario
devcontainer features test -f trilinos --scenario basic_installation .
```

#### Interactive Testing
Create a test `devcontainer.json`:
```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu-22.04",
    "features": {
        "./src/trilinos": {
            "version": "latest",
            "enableMPI": true,
            "enableKokkos": true
        }
    }
}
```

Build and test:
```bash
devcontainer build --workspace-folder .
devcontainer exec --workspace-folder . bash
```

### Making Changes

1. **Update Feature Metadata**: Modify `src/trilinos/devcontainer-feature.json`
2. **Update Installation Logic**: Modify `src/trilinos/install.sh`
3. **Update Tests**: Modify `test/trilinos/test.sh` and `test/trilinos/scenarios.json`
4. **Update Documentation**: Update READMEs and examples

### Version Management

When releasing a new version:

1. Update the `version` field in `src/trilinos/devcontainer-feature.json`
2. Update the collection file `devcontainer-collection.json`
3. Tag the release: `git tag v1.x.x`
4. Push changes and tags: `git push && git push --tags`

## Publishing

### Automatic Publishing (Recommended)

The GitHub Actions workflow in `.github/workflows/release.yml` automatically:
1. Tests the feature against multiple base images
2. Publishes to GitHub Container Registry
3. Generates documentation

Publishing happens on:
- Push to `main` branch
- Manual workflow dispatch

### Manual Publishing

```bash
# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Publish features
devcontainer features publish ./src \
  --registry ghcr.io \
  --namespace your-username/trilinos-devcontainer-feature
```

### Package Visibility

After publishing, make packages public:
1. Go to your GitHub profile
2. Navigate to "Packages"
3. Find the trilinos feature package
4. Change visibility to "Public"

## Usage Examples

### Basic Usage
```json
{
  "features": {
    "ghcr.io/your-username/trilinos-devcontainer-feature/trilinos:1": {}
  }
}
```

### Custom Configuration
```json
{
  "features": {
    "ghcr.io/your-username/trilinos-devcontainer-feature/trilinos:1": {
      "version": "15.0.0",
      "enableMPI": true,
      "enableKokkos": true,
      "buildType": "Debug",
      "parallelJobs": "4"
    }
  }
}
```

### Complete Development Environment
```json
{
  "name": "Trilinos Dev Environment",
  "image": "mcr.microsoft.com/devcontainers/cpp:1-ubuntu-22.04",
  "features": {
    "ghcr.io/your-username/trilinos-devcontainer-feature/trilinos:1": {
      "version": "latest",
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

## Troubleshooting

### Common Issues

1. **Build Timeouts**: Trilinos compilation can take 30-60 minutes
2. **Memory Issues**: Ensure adequate RAM (4GB+) for compilation
3. **Permission Issues**: Install script runs as root, ensure proper user handling

### Debug Mode

Enable debug output in install script:
```bash
# Add to top of install.sh
set -x  # Enable debug output
```

### Container Resource Limits

For testing with limited resources:
```json
{
  "features": {
    "trilinos": {
      "enableMPI": false,
      "enableKokkos": false,
      "parallelJobs": "1"
    }
  }
}
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/improvement`
3. Make changes and test thoroughly
4. Commit changes: `git commit -m "Description of changes"`
5. Push to branch: `git push origin feature/improvement`
6. Create a Pull Request

### Code Style

- Use bash best practices in shell scripts
- Add comments for complex operations
- Follow JSON formatting standards
- Update documentation for any changes

### Testing Requirements

All changes must:
1. Pass existing tests
2. Include new tests if adding functionality
3. Work with supported base images
4. Maintain backward compatibility when possible

## Additional Resources

- [Dev Container Features Specification](https://containers.dev/implementors/features/)
- [Dev Container CLI Documentation](https://github.com/devcontainers/cli)
- [Trilinos Documentation](https://docs.trilinos.org/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

## Support

For issues related to:
- **This feature**: Open an issue in this repository
- **Trilinos software**: Use [Trilinos GitHub issues](https://github.com/trilinos/trilinos/issues)
- **Dev Container specification**: Use [Dev Container spec issues](https://github.com/devcontainers/spec/issues) 