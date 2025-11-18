from typing import Any, Callable, Optional, TypeAlias

# Type aliases for common types used throughout the package
ContextPointer: TypeAlias = Any  # Represents a C void pointer to the context
ElementId: TypeAlias = int
ContextType: TypeAlias = str  # "App", "Main", "Menu", "Focused", "Query"
ActionName: TypeAlias = str
AttributeName: TypeAlias = str
AttributeValue: TypeAlias = Any
