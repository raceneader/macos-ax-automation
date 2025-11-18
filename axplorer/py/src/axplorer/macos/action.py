import ctypes
from typing import List
from axplorer.types import ContextType, ElementId
from axplorer.macos.lib import lib
from axplorer.macos.explorer import AccessibilityExplorer

def left_click() -> bool:
    """
    Perform a left mouse click at the current cursor position.
    
    Returns:
        bool: True if successful, False otherwise
    """
    return lib.leftClick()

def right_click() -> bool:
    """
    Perform a right mouse click at the current cursor position.
    
    Returns:
        bool: True if successful, False otherwise
    """
    return lib.rightClick()

def double_left_click() -> bool:
    """
    Perform a double left click at the current cursor position.
    
    Returns:
        bool: True if successful, False otherwise
    """
    return lib.doubleLeftClick()

def move_to_element(explorer: AccessibilityExplorer, context_type: ContextType, element_id: ElementId, position: str = "center") -> bool:
    """
    Move the mouse cursor to the specified position of an element.
    
    Args:
        explorer: The AccessibilityExplorer instance
        context_type: Type of context ("App", "Main", "Menu", "Focused", "Query")
        element_id: ID of the element to move to
        position: Where to move relative to the element ("center" or "bottomRight", default: "center")
        
    Returns:
        bool: True if successful, False otherwise
    """
    if position not in ["center", "bottomRight"]:
        print(f"Warning: Invalid position '{position}', defaulting to 'center'")
        position = "center"
        
    return lib.moveToElement(
        explorer.context,
        context_type.encode('utf-8'),
        element_id,
        position.encode('utf-8')
    )

def scroll_up(distance: float = 800.0) -> bool:
    """
    Perform a smooth scroll up action with natural easing.
    
    Args:
        distance: Scroll distance in pixels (default: 800.0)
        
    Returns:
        bool: True if successful, False otherwise
    """
    return lib.scrollUp(distance)

def scroll_down(distance: float = 800.0) -> bool:
    """
    Perform a smooth scroll down action with natural easing.
    
    Args:
        distance: Scroll distance in pixels (default: 800.0)
        
    Returns:
        bool: True if successful, False otherwise
    """
    return lib.scrollDown(distance)

def type_text(text: str) -> bool:
    """
    Type a string of text with natural timing between keystrokes.
    
    Args:
        text: The text to type (can include any Unicode characters, including emojis)
        
    Returns:
        bool: True if successful, False otherwise
        
    Note:
        This is the preferred method for typing any text, especially:
        - Multi-character strings
        - Emojis and other surrogate pair characters
        - International characters
        - Complex Unicode sequences
        - Special characters (newlines, tabs)
    """
    utf16_text = (text.encode("utf-16-le") + b"\x00\x00")
    utf16_ptr = ctypes.cast(ctypes.create_string_buffer(utf16_text), ctypes.POINTER(ctypes.c_uint16))
    return lib.typeText(utf16_ptr)

def press_key(key: str) -> bool:
    """
    Press a single key.
    
    Args:
        key: The key to press (e.g., "a", "return", "tab")
        Must be a single Basic Multilingual Plane (BMP) character or special key name.
        For emojis or surrogate pairs, use type_text() instead.
        
        Special keys: "return", "tab", "delete", "escape", "capslock",
        "right", "left", "down", "up", "home", "end", "pageup", "pagedown", "space"
        
    Returns:
        bool: True if successful, False otherwise
        
    Note:
        This function is designed for single-key input and special keys.
        For typing text or complex Unicode characters, use type_text() instead.
    """
    if not key:
        return False
        
    # Convert the key string to UTF-8 bytes for C
    key_bytes = key.encode('utf-8')
    return lib.pressKey(key_bytes)

def press_key_combo(key: str, modifiers: List[str]) -> bool:
    """
    Press a key combination with modifier keys.
    
    Args:
        key: The key to press (e.g., "c" for Command+C)
        Must be a single Basic Multilingual Plane (BMP) character or special key name.
        For emojis or surrogate pairs, use type_text() instead.
        
        modifiers: List of modifier key names (e.g., ["command", "shift"])
        Valid modifiers: "command", "shift", "option", "control", "function"
        
    Returns:
        bool: True if successful, False otherwise
        
    Note:
        This function is designed for keyboard shortcuts with modifier keys.
        For typing text or complex Unicode characters, use type_text() instead.
    """
    if not key:
        return False
        
    # Convert modifiers to UTF-8 since they're ASCII-only
    modifier_bytes = [m.encode('utf-8') for m in modifiers]
    arr = (ctypes.c_char_p * len(modifier_bytes))(*modifier_bytes)
    
    # Convert the key string to UTF-8 bytes for C
    key_bytes = key.encode('utf-8')
    return lib.pressKeyCombo(key_bytes, arr, len(modifiers))

def left_drag(to_x: float, to_y: float) -> bool:
    """
    Perform a drag operation with the left mouse button to the specified coordinates.
    
    Args:
        to_x: The target X coordinate
        to_y: The target Y coordinate
        
    Returns:
        bool: True if successful, False otherwise
        
    Note:
        This function assumes the mouse button is already pressed at the starting position.
        Use this for dragging from the current mouse position to absolute screen coordinates.
    """
    return lib.leftDrag(to_x, to_y)

def drag_to_element(explorer: AccessibilityExplorer, context_type: ContextType, element_id: ElementId) -> bool:
    """
    Perform a drag operation from the current mouse position to the center of a specific element.
    
    Args:
        explorer: The AccessibilityExplorer instance
        context_type: Type of context ("App", "Main", "Menu", "Focused", "Query")
        element_id: ID of the target element
        
    Returns:
        bool: True if successful, False otherwise
    """
    return lib.dragToElement(
        explorer.context,
        context_type.encode('utf-8'),
        element_id
    )

def get_mouse_location() -> tuple[float, float]:
    """
    Get the current mouse cursor position.
    
    Returns:
        tuple[float, float]: A tuple containing the (x, y) coordinates of the mouse cursor,
        or (0.0, 0.0) if the location could not be retrieved.
    """
    x = ctypes.c_double()
    y = ctypes.c_double()
    if lib.getMouseLocation(ctypes.byref(x), ctypes.byref(y)):
        return (x.value, y.value)
    return (0.0, 0.0)
