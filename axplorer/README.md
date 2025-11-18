# Axplorer Project

A comprehensive accessibility testing toolkit with native platform implementations and Python bindings.

## Project Structure

```
axplorer/
├── lib/                        # Native library implementations
│   └── axplorer-swift/        # Swift implementation for macOS
│       ├── Sources/           # Swift source files
│       │   ├── Capi.swift     # C API interface
│       │   ├── Explorer.swift # Core explorer implementation
│       │   ├── Helper.swift   # Helper utilities
│       │   └── main.swift     # Entry point
│       └── axplorer.xcodeproj/
│
├── py/                        # Python package
│   ├── src/axplorer/         # Main package source
│   ├── tests/                # Test suite
│   ├── examples/             # Usage examples
│   └── README.md             # Python package documentation
│
├── scripts/                   # Build and development scripts
├── docs/                     # Documentation
└── README.md                 # This file
```

## Components

### Native Library (lib/axplorer-swift)

The core functionality is implemented in Swift, providing:
- Direct access to macOS accessibility APIs
- High-performance YAML generation
- Memory-safe C API interface
- Comprehensive error handling

### Python Package (py/)

Python bindings providing:
- High-level, Pythonic API
- Cross-platform compatibility layer
- Type hints and documentation
- Example code and utilities

## Building

### Prerequisites

- Xcode 15+ (for macOS/Swift development)
- Python 3.12+
- Poetry (Python dependency management)

### Build Steps

1. Build the Swift library:
   ```bash
   cd lib/axplorer-swift
   xcodebuild
   ```

2. Build the Python package:
   ```bash
   cd py
   poetry install
   poetry build
   ```

## Development

See the README.md files in each component directory for specific development instructions:
- [Swift Library](lib/axplorer-swift/README.md)
- [Python Package](py/README.md)

## Testing

Each component has its own test suite:

### Swift Tests
```bash
cd lib/axplorer-swift
xcodebuild test
```

### Python Tests
```bash
cd py
poetry run pytest
```

## Documentation

- [Swift API Documentation](docs/swift.md)
- [Python API Documentation](docs/python.md)
- [Development Guide](docs/dev.md)

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Apple Accessibility APIs
- PyObjC project
- Python ctypes library
