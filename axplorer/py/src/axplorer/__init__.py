"""
Axplorer: Cross-platform accessibility testing library with native platform implementations.

This package provides tools for exploring and interacting with application accessibility
interfaces across different platforms.
"""

import platform
from typing import List, Optional

# Re-export common types
from .types import (
    ElementId,
    ContextType,
    ActionName,
    AttributeName,
    AttributeValue,
)

# Platform-specific imports
if platform.system() == "Darwin":
    from .macos.explorer import AccessibilityExplorer
    from .macos.utils import (
        is_accessibility_enabled,
        prompt_accessibility_permissions,
        raise_application,
        launch_application,
    )
else:
    raise NotImplementedError(
        f"Platform {platform.system()} is not currently supported"
    )

# Common functionality
from .common.yaml import filter_yaml

__version__ = "0.1.0"

__all__ = [
    # Main classes
    "AccessibilityExplorer",
    
    # Platform utilities
    "is_accessibility_enabled",
    "prompt_accessibility_permissions",
    "raise_application",
    "launch_application",
    
    # Common utilities
    "filter_yaml",
    
    # Types
    "ElementId",
    "ContextType",
    "ActionName",
    "AttributeName",
    "AttributeValue",
]
