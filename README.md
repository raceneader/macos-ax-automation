# macOS AX Automation

> **LLM-powered macOS accessibility automation framework**

An attempt at automating applications through accessibility APIs, featuring LLM-powered natural language control, state machine-based execution, and a robust Swift/Python architecture.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.12+](https://img.shields.io/badge/python-3.12+-blue.svg)](https://www.python.org/downloads/)
[![macOS](https://img.shields.io/badge/macOS-10.15+-green.svg)](https://www.apple.com/macos/)

## ✨ Features

- 🤖 **LLM-Powered Automation** - Control applications using natural language with OpenAI integration
- 🎯 **Goal-Based Execution** - State machine architecture for reliable multi-step automation
- 🔍 **Accessibility Explorer** - Inspect and interact with any macOS application's UI elements
- 🐍 **Python & Swift** - Swift core with Python bindings
- 📊 **Excel Automation** - Pre-built examples for Microsoft Excel control
- 🎨 **Visual Feedback** - Built-in Tkinter UI for monitoring automation progress
- 🛠️ **Extensible** - Easy to add support for new applications

## 🚀 Quick Start

### Prerequisites

- macOS 10.15+
- Python 3.12+
- Xcode 15+ (for building Swift components)
- Accessibility permissions enabled

### Installation

```bash
# Clone the repository
git clone https://github.com/raceneader/macos-ax-automation.git
cd macos-ax-automation

# Install Python package
cd axplorer/py
pip install -e .
```

### Enable Accessibility Permissions

1. Go to **System Settings** → **Privacy & Security** → **Accessibility**
2. Add your terminal application or Python executable
3. Grant permissions when prompted

### Basic Example

```python
from axplorer import AccessibilityExplorer, launch_application

# Launch and control an application
launch_application("TextEdit")
explorer = AccessibilityExplorer("TextEdit")

# Get application structure as YAML
yaml_output = explorer.get_app_yaml(max_depth=2)
print(yaml_output)
```

## 🎓 LLM-Powered Automation Example

Control Excel with natural language:

```python
from axplorer.examples.excel_llm import ExcelLLMController
from openai import OpenAI

# Initialize with OpenAI
client = OpenAI(api_key="your-api-key")
controller = ExcelLLMController(client)

# Run the interactive controller
controller.run()
```

Then use natural language commands like:
- "Create a new spreadsheet with columns Name, Age, and City"
- "Fill in 5 rows of sample data"
- "Calculate the average age"
- "Make the headers bold"

## 📁 Project Structure

```
macos-ax-automation/
├── axplorer/                          # Main project directory
│   ├── lib/AXplorer/                 # Swift library (native macOS accessibility)
│   │   ├── Sources/AXplorer/         # Core Swift implementation
│   │   │   ├── Explorer.swift        # Main accessibility explorer
│   │   │   ├── Action.swift          # Action execution
│   │   │   ├── Capi.swift           # C API for Python bindings
│   │   │   └── Apps/                # Application-specific helpers
│   │   └── Tests/                   # Swift test suite
│   │
│   ├── py/                           # Python package
│   │   ├── src/axplorer/            # Python library source
│   │   │   ├── macos/               # macOS-specific implementations
│   │   │   │   ├── explorer.py      # Main explorer class
│   │   │   │   ├── action.py        # Action execution
│   │   │   │   ├── lib.py           # Swift library bindings
│   │   │   │   └── apps/            # App-specific helpers
│   │   │   └── common/              # Cross-platform utilities
│   │   │
│   │   ├── examples/                # Usage examples
│   │   │   ├── excel_llm.py         # LLM-powered Excel controller
│   │   │   ├── models/              # Data models (Goal, Step)
│   │   │   ├── states/              # State machine components
│   │   │   │   ├── goal_state_machine.py    # Goal planning FSM
│   │   │   │   ├── goal_executor.py         # Goal execution
│   │   │   │   └── step_executor.py         # Step-by-step execution
│   │   │   ├── ui/                  # User interface
│   │   │   │   └── tkinter_window.py       # Automation UI
│   │   │   └── utils/               # Helper utilities
│   │   │
│   │   ├── tests/                   # Python test suite
│   │   └── pyproject.toml           # Package configuration
│   │
│   ├── scripts/                      # Build and development scripts
│   └── docs/                        # Documentation
│
├── README.md                        # This file
└── CONTRIBUTING.md                  # Contribution guidelines
```

## 🎯 Use Cases

### Application Testing
```python
from axplorer import AccessibilityExplorer

# Test UI element presence and properties
explorer = AccessibilityExplorer("YourApp")
yaml = explorer.get_main_window_yaml(max_depth=3)
assert "Submit Button" in yaml
```

### Data Entry Automation
```python
# Automate form filling
explorer.set_attribute_value(
    context_type="Main",
    element_id=42,
    attribute="value",
    value="John Doe"
)
explorer.perform_action(
    context_type="Main",
    element_id=43,
    action="press"
)
```

### LLM-Driven Workflows
```python
from axplorer.examples import GoalExecutor, Goal

# Define goals with natural language
goals = [
    Goal(description="Open a new document", priority=1),
    Goal(description="Format the header as bold", priority=2),
    Goal(description="Save the document", priority=3)
]

# Execute with LLM-powered planning
executor = GoalExecutor(openai_client, goals=goals, explorer=explorer)
executor.execute_goals()
```

## 🏗️ Architecture

### State Machine Flow

```
User Request → High Level Planner (LLM) → Goal Creation
                                              ↓
                                         Goal Review
                                              ↓
                                    Goal State Machine
                                              ↓
                                        Goal Executor
                                              ↓
                        Steps Generated (LLM) → Step Executor
                                                      ↓
                                              Accessibility Actions
```

### Key Components

- **AccessibilityExplorer**: Core Swift library for macOS accessibility API access
- **GoalStateMachine**: Manages goal planning, review, and approval workflow
- **GoalExecutor**: Executes approved goals sequentially with retry logic
- **StepExecutor**: Breaks down goals into actionable steps and executes them
- **AutomationUI**: Real-time visualization of execution progress

## 🔧 Development

### Building from Source

```bash
# Build Swift library
cd axplorer/lib/AXplorer
swift build

# Install Python package in development mode
cd ../../py
pip install -e .
```

### Running Tests

```bash
# Swift tests
cd axplorer/lib/AXplorer
swift test

# Python tests
cd axplorer/py
pytest
```

### Running Examples

```bash
# Excel automation example
cd axplorer/py
python -m examples.excel

# LLM-powered Excel controller
python -m examples.excel_llm --api-key YOUR_OPENAI_API_KEY
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on:

- Code style and standards
- Development workflow
- Testing requirements
- Pull request process

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
