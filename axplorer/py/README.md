# Axplorer

A cross-platform accessibility testing library with native platform implementations.

## Features

- Explore application accessibility interfaces
- Get YAML representations of UI elements
- Perform accessibility actions
- Set element attributes
- Filter YAML output
- Platform-specific utilities (currently macOS only)

## Installation

```bash
# Using pip
pip install axplorer

# Using poetry
poetry add axplorer
```

## Quick Start

```python
from axplorer import AccessibilityExplorer, launch_application

# Launch an application
launch_application("com.apple.Safari")

# Create an explorer instance
with AccessibilityExplorer("Safari") as explorer:
    # Get application structure
    yaml = explorer.get_app_yaml(max_depth=2)
    print(yaml)
```

## Requirements

- Python 3.12+
- macOS (currently the only supported platform)
- Accessibility permissions enabled

## Usage Examples

### Basic Application Exploration

```python
from axplorer import AccessibilityExplorer

with AccessibilityExplorer("Safari") as explorer:
    # Get main window structure
    window_yaml = explorer.get_main_window_yaml(max_depth=2)
    print(window_yaml)
    
    # Get menu bar
    menu_yaml = explorer.get_menu_bar_yaml(max_depth=1)
    print(menu_yaml)
```

### Performing Actions

```python
from axplorer import AccessibilityExplorer

with AccessibilityExplorer("Safari") as explorer:
    # Perform an action on an element
    explorer.perform_action(
        context_type="Main",
        element_id=42,
        action="press"
    )
```

### Setting Attributes

```python
from axplorer import AccessibilityExplorer

with AccessibilityExplorer("TextEdit") as explorer:
    # Set a value for an element
    explorer.set_attribute_value(
        context_type="Main",
        element_id=42,
        attribute="value",
        value="Hello, World!"
    )
```

### Filtering YAML Output

## Development

### Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   cd py
   poetry install
   ```

### Building

The package includes both Python and native components:

1. Build the Swift library:
   ```bash
   cd lib/axplorer-swift
   xcodebuild
   ```

2. Build the Python package:
   ```bash
   cd py
   poetry build
   ```

### Testing

```bash
poetry run pytest
```

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
