# Contributing to macOS AX Automation

Thank you for your interest in contributing to macOS AX Automation! This document provides guidelines and instructions for contributing to the project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Testing](#testing)
- [Security](#security)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)

## 🤝 Code of Conduct

### Our Standards

- **Be respectful**: Treat everyone with respect and consideration
- **Be constructive**: Provide helpful, actionable feedback
- **Be collaborative**: Work together towards common goals
- **Be inclusive**: Welcome contributors of all skill levels and backgrounds

### Unacceptable Behavior

- Harassment, discrimination, or offensive comments
- Trolling, insulting, or derogatory remarks
- Publishing others' private information without consent
- Any conduct inappropriate in a professional setting

## 🚀 Getting Started

### Prerequisites

Before contributing, ensure you have:

- macOS 10.15 or later
- Xcode 15+ installed
- Python 3.12 or later
- Git configured with your name and email
- A GitHub account

### Fork and Clone

1. **Fork the repository** on GitHub
2. **Clone your fork locally**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/macos-ax-automation.git
   cd macos-ax-automation
   ```

3. **Add the upstream repository**:
   ```bash
   git remote add upstream https://github.com/raceneader/macos-ax-automation.git
   ```

4. **Verify remotes**:
   ```bash
   git remote -v
   ```

## 🛠️ Development Setup

### Python Environment

1. **Create a virtual environment**:
   ```bash
   cd axplorer/py
   python -m venv .venv
   source .venv/bin/activate
   ```

2. **Install development dependencies**:
   ```bash
   pip install -e ".[dev]"
   # or if using poetry:
   poetry install --with dev
   ```

3. **Install pre-commit hooks** (recommended):
   ```bash
   pre-commit install
   ```

### Swift Environment

1. **Navigate to Swift library**:
   ```bash
   cd axplorer/lib/AXplorer
   ```

2. **Build the library**:
   ```bash
   swift build
   ```

3. **Run tests**:
   ```bash
   swift test
   ```

### Enable Accessibility Permissions

Your development environment needs accessibility permissions:

1. Go to **System Settings** → **Privacy & Security** → **Accessibility**
2. Add your terminal, IDE, or Python executable
3. Enable the checkbox for each application

## 🔄 Development Workflow

### 1. Create a Feature Branch

```bash
git checkout main
git pull upstream main
git checkout -b feature/your-feature-name
```

Branch naming conventions:
- `feature/` - New features
- `bugfix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions or fixes

### 2. Make Your Changes

- Write clear, concise commit messages
- Keep commits focused and atomic
- Test your changes thoroughly
- Update documentation as needed

### 3. Commit Your Changes

```bash
git add .
git commit -m "feat: add new feature description"
```

#### Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(explorer): add support for keyboard navigation

fix(excel): resolve cell selection issue when merged cells present

docs(readme): update installation instructions for M1 Macs
```

### 4. Keep Your Branch Updated

```bash
git fetch upstream
git rebase upstream/main
```

### 5. Push Your Changes

```bash
git push origin feature/your-feature-name
```

## 📝 Code Standards

### Python Code Style

- Follow [PEP 8](https://peps.python.org/pep-0008/) style guide
- Use [Black](https://black.readthedocs.io/) for code formatting
- Use [isort](https://pycqa.github.io/isort/) for import sorting
- Use [mypy](https://mypy.readthedocs.io/) for type checking
- Maximum line length: 88 characters (Black default)

**Type Hints:**
```python
# Good - Modern Python typing (no imports needed for built-ins)
def process_data(items: list[str], max_count: int = 10) -> dict[str, int]:
    """Process items and return counts."""
    return {item: len(item) for item in items[:max_count]}

# Bad - Missing type hints
def process_data(items, max_count=10):
    return {item: len(item) for item in items[:max_count]}
```

**Documentation:**
```python
def perform_action(
    context_type: str,
    element_id: int,
    action: str
) -> bool:
    """
    Perform an accessibility action on an element.

    Args:
        context_type: The context type (e.g., "Main", "Menu")
        element_id: The unique identifier for the element
        action: The action to perform (e.g., "press", "click")

    Returns:
        True if the action was successful, False otherwise

    Raises:
        ValueError: If the action is not supported
        RuntimeError: If the element cannot be found

    Example:
        >>> explorer.perform_action("Main", 42, "press")
        True
    """
    pass
```

### Swift Code Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful, descriptive names
- Prefer `let` over `var` when possible
- Use guard statements for early returns
- Document public APIs with DocC comments

**Example:**
```swift
/// Performs an accessibility action on the specified element.
///
/// - Parameters:
///   - elementId: The unique identifier for the element
///   - action: The action to perform
/// - Returns: A boolean indicating success
/// - Throws: `ExplorerError.elementNotFound` if the element doesn't exist
public func performAction(elementId: Int, action: String) throws -> Bool {
    guard let element = findElement(byId: elementId) else {
        throw ExplorerError.elementNotFound(elementId)
    }
    
    return try element.performAction(action)
}
```

### Code Organization

- Keep functions focused and single-purpose
- Limit file length (prefer < 500 lines)
- Use clear, descriptive names
- Avoid deep nesting (max 3-4 levels)
- Extract complex logic into helper functions

## ✅ Testing

### Python Tests

**Running Tests:**
```bash
cd axplorer/py
pytest
pytest -v  # Verbose output
pytest tests/test_specific.py  # Run specific test file
pytest -k "test_name"  # Run tests matching pattern
```

**Test Coverage:**
```bash
pytest --cov=axplorer --cov-report=html
open htmlcov/index.html
```

**Writing Tests:**
```python
import pytest
from axplorer import AccessibilityExplorer

def test_explorer_initialization():
    """Test that explorer initializes correctly."""
    explorer = AccessibilityExplorer("TextEdit")
    assert explorer.app_name == "TextEdit"
    assert explorer.is_running()

def test_invalid_app_name():
    """Test that invalid app names raise appropriate errors."""
    with pytest.raises(ValueError):
        AccessibilityExplorer("")

@pytest.fixture
def excel_explorer():
    """Fixture providing an Excel explorer instance."""
    explorer = AccessibilityExplorer("Microsoft Excel")
    yield explorer
    explorer.cleanup()
```

### Swift Tests

**Running Tests:**
```bash
cd axplorer/lib/AXplorer
swift test
```

**Writing Tests:**
```swift
import XCTest
@testable import AXplorer

final class ExplorerTests: XCTestCase {
    func testExplorerInitialization() {
        let explorer = Explorer(appName: "TextEdit")
        XCTAssertNotNil(explorer)
        XCTAssertEqual(explorer.appName, "TextEdit")
    }
    
    func testInvalidAppName() {
        XCTAssertThrowsError(try Explorer(appName: ""))
    }
}
```

### Test Requirements

- All new features must include tests
- Bug fixes should include regression tests
- Aim for >80% code coverage
- Tests should be isolated and repeatable
- Mock external dependencies when possible

## 🔒 Security

### API Keys and Credentials

**NEVER commit sensitive information:**

❌ **Bad:**
```python
client = OpenAI(api_key="sk-proj-abc123...")  # NEVER DO THIS
```

✅ **Good:**
```python
import os
from openai import OpenAI

api_key = os.environ.get("OPENAI_API_KEY")
if not api_key:
    raise ValueError("OPENAI_API_KEY environment variable not set")

client = OpenAI(api_key=api_key)
```

### Environment Variables

Create a `.env` file (already in `.gitignore`):
```bash
OPENAI_API_KEY=your_key_here
ANTHROPIC_API_KEY=your_key_here
```

Load with python-dotenv:
```python
from dotenv import load_dotenv
load_dotenv()

api_key = os.environ.get("OPENAI_API_KEY")
```

### Security Best Practices

1. **Never hardcode secrets** in source code
2. **Use environment variables** for configuration
3. **Review code for exposed credentials** before committing
4. **Use `.gitignore`** to exclude sensitive files
5. **Run security linters** (e.g., `bandit` for Python)
6. **Report security issues** privately to maintainers

### Pre-commit Security Check

Add to `.pre-commit-config.yaml`:
```yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
```

## 🔍 Pull Request Process

### Before Submitting

- [ ] Code follows project style guidelines
- [ ] All tests pass locally
- [ ] New tests added for new features
- [ ] Documentation updated
- [ ] Commit messages follow conventions
- [ ] Branch is up to date with `main`
- [ ] No merge conflicts
- [ ] No API keys or secrets in code

### Creating a Pull Request

1. **Push your branch** to your fork
2. **Open a pull request** on GitHub
3. **Fill out the PR template** completely
4. **Link related issues** using keywords (Fixes #123)
5. **Request reviews** from maintainers
6. **Respond to feedback** promptly

### PR Title Format

Use the same format as commit messages:
```
feat(component): brief description of changes
```

### PR Description Template

```markdown
## Description
Brief description of what this PR does.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe how you tested your changes.

## Related Issues
Fixes #123
Related to #456

## Checklist
- [ ] Code follows style guidelines
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] All tests passing
- [ ] No new warnings
```

### Review Process

1. **Automated checks** run on all PRs
2. **Code review** by at least one maintainer
3. **Address feedback** and make requested changes
4. **Approval** from maintainer(s)
5. **Merge** by maintainer

### After Your PR is Merged

1. **Delete your feature branch**:
   ```bash
   git branch -d feature/your-feature-name
   git push origin --delete feature/your-feature-name
   ```

2. **Update your local main**:
   ```bash
   git checkout main
   git pull upstream main
   ```

3. **Celebrate** your contribution! 🎉

## 🐛 Reporting Issues

### Bug Reports

When reporting bugs, include:

1. **Clear title** describing the issue
2. **Environment details**:
   - macOS version
   - Python version
   - Xcode version (if relevant)
3. **Steps to reproduce**
4. **Expected behavior**
5. **Actual behavior**
6. **Error messages** or logs
7. **Code samples** (if applicable)

### Feature Requests

When requesting features, include:

1. **Clear description** of the feature
2. **Use case** explaining why it's needed
3. **Proposed solution** (if you have one)
4. **Alternatives considered**
5. **Additional context** or examples

## 💡 Tips for Success

### Good First Issues

Look for issues labeled `good first issue` or `help wanted` - these are great starting points for new contributors.

### Getting Help

- 💬 Ask questions in issue discussions
- 📖 Review existing documentation
- 🔍 Search closed issues for similar problems
- 📧 Reach out to maintainers if needed

### Best Practices

- Start small and build up
- Read existing code to understand patterns
- Test on real applications
- Document as you go
- Be patient with the review process
- Learn from feedback

## 📚 Additional Resources

- [Swift Documentation](https://swift.org/documentation/)
- [Python Documentation](https://docs.python.org/3/)
- [Apple Accessibility APIs](https://developer.apple.com/documentation/accessibility)
- [Git Best Practices](https://git-scm.com/book/en/v2)
- [GitHub Flow](https://guides.github.com/introduction/flow/)

## 🙌 Recognition

Contributors are recognized in:
- Repository contributors page
- Release notes
- Project documentation

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to macOS AX Automation! Your efforts help make this project better for everyone. 🎉
