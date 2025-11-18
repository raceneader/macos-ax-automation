import ctypes
import os
from typing import Any, List
from ..types import AttributeValue

# Load the Swift library
# TODO: Update path to use proper library location after build
lib = ctypes.CDLL(os.path.join(os.path.dirname(__file__), 'lib/libAXplorer.dylib'))

# Load libc for memory management
libc = ctypes.CDLL("libc.dylib")
free = libc.free
free.argtypes = [ctypes.c_void_p]

# Configure function signatures
def _configure_lib():
    """Configure the function signatures for the Swift library."""
    
    # Application management
    lib.raiseApplication.argtypes = [ctypes.c_char_p]
    lib.raiseApplication.restype = ctypes.c_int

    lib.launchApplication.argtypes = [ctypes.c_char_p]
    lib.launchApplication.restype = ctypes.c_int

    # Explorer management
    lib.createAccessExplorer.argtypes = [ctypes.c_char_p]
    lib.createAccessExplorer.restype = ctypes.c_void_p

    lib.destroyAccessExplorer.argtypes = [ctypes.c_void_p]
    lib.destroyAccessExplorer.restype = None

    # YAML operations
    lib.getAppYAML.argtypes = [ctypes.c_void_p, ctypes.c_int]
    lib.getAppYAML.restype = ctypes.POINTER(ctypes.c_char)

    lib.getMainWindowYAML.argtypes = [ctypes.c_void_p, ctypes.c_int]
    lib.getMainWindowYAML.restype = ctypes.POINTER(ctypes.c_char)

    lib.getFocusedWindowYAML.argtypes = [ctypes.c_void_p, ctypes.c_int]
    lib.getFocusedWindowYAML.restype = ctypes.POINTER(ctypes.c_char)

    lib.getMenuBarYAML.argtypes = [ctypes.c_void_p, ctypes.c_int]
    lib.getMenuBarYAML.restype = ctypes.POINTER(ctypes.c_char)

    lib.getQueryElementYAML.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int, ctypes.c_int]
    lib.getQueryElementYAML.restype = ctypes.POINTER(ctypes.c_char)

    # Actions and attributes
    lib.performAction.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int, ctypes.c_char_p]
    lib.performAction.restype = ctypes.c_bool

    lib.setAttributeValue.argtypes = [
        ctypes.c_void_p,
        ctypes.c_char_p,
        ctypes.c_int,
        ctypes.c_char_p,
        ctypes.c_void_p,
        ctypes.c_char_p
    ]
    lib.setAttributeValue.restype = ctypes.c_bool

    # YAML filtering
    lib.filterYAML.argtypes = [ctypes.c_char_p, ctypes.POINTER(ctypes.c_char_p), ctypes.c_size_t]
    lib.filterYAML.restype = ctypes.POINTER(ctypes.c_char)

    lib.filterYAMLNodes.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p]
    lib.filterYAMLNodes.restype = ctypes.POINTER(ctypes.c_char)

    # Mouse movement
    lib.moveToElement.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int, ctypes.c_char_p]
    lib.moveToElement.restype = ctypes.c_bool

    # Keyboard input
    lib.typeText.argtypes = [ctypes.POINTER(ctypes.c_uint16)]  # Array of UTF-16 code units for text
    lib.typeText.restype = ctypes.c_bool

    lib.pressKey.argtypes = [ctypes.c_char_p]  # UTF-8 string for key
    lib.pressKey.restype = ctypes.c_bool

    lib.pressKeyCombo.argtypes = [ctypes.c_char_p, ctypes.POINTER(ctypes.c_char_p), ctypes.c_int32]
    lib.pressKeyCombo.restype = ctypes.c_bool

    # Scrolling
    lib.scrollUp.argtypes = [ctypes.c_double]
    lib.scrollUp.restype = ctypes.c_bool

    lib.scrollDown.argtypes = [ctypes.c_double]
    lib.scrollDown.restype = ctypes.c_bool

    # Mouse dragging
    lib.leftDrag.argtypes = [ctypes.c_double, ctypes.c_double]
    lib.leftDrag.restype = ctypes.c_bool
    
    lib.dragToElement.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int]
    lib.dragToElement.restype = ctypes.c_bool

    # Mouse location
    lib.getMouseLocation.argtypes = [ctypes.POINTER(ctypes.c_double), ctypes.POINTER(ctypes.c_double)]
    lib.getMouseLocation.restype = ctypes.c_bool

    # Element at mouse position
    lib.getElementAtMousePositionYAML.argtypes = [ctypes.c_void_p, ctypes.c_int]
    lib.getElementAtMousePositionYAML.restype = ctypes.POINTER(ctypes.c_char)

    # Excel operations
    lib.flattenExcelCells.argtypes = [ctypes.c_char_p]
    lib.flattenExcelCells.restype = ctypes.POINTER(ctypes.c_char)


# Configure library on import
_configure_lib()

def get_string_from_pointer(ptr: ctypes.POINTER) -> str:
    """Convert a C string pointer to a Python string and free the memory."""
    if not ptr:
        return ""
    result = ctypes.string_at(ptr).decode('utf-8')
    free(ptr)
    return result

def create_value_pointer(value: AttributeValue) -> tuple[Any, str]:
    """Create a ctypes pointer for a value based on its type."""
    if isinstance(value, str):
        return ctypes.create_string_buffer(value.encode('utf-8')), "string"
    elif isinstance(value, bool):
        return ctypes.pointer(ctypes.c_bool(value)), "bool"
    elif isinstance(value, (int, float)):
        return ctypes.pointer(ctypes.c_double(value)), "double"
    else:
        raise ValueError(f"Unsupported value type: {type(value)}")
