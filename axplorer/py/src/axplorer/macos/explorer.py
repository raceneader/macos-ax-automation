from typing import Optional, List
from ..types import ContextPointer, ElementId, ContextType, ActionName, AttributeName, AttributeValue
from .lib import lib, get_string_from_pointer, create_value_pointer

class AccessibilityExplorer:
    """
    A class to manage the lifecycle of an accessibility context.
    Automatically handles creation and cleanup of the context.
    """
    def __init__(self, app_name: str):
        """
        Initialize the AccessibilityExplorer for a specific application.
        
        Args:
            app_name: Name of the application to explore
        """
        self.context = lib.createAccessExplorer(app_name.encode('utf-8'))
        if not self.context:
            raise RuntimeError(f"Failed to create AccessibilityExplorer for {app_name}")
    
    def __enter__(self):
        """Context manager entry point."""
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit point."""
        self.cleanup()
        
    def __del__(self):
        """Destructor to ensure cleanup."""
        self.cleanup()
    
    def cleanup(self):
        """Clean up the explorer context."""
        if hasattr(self, 'context') and self.context:
            lib.destroyAccessExplorer(self.context)
            self.context = None

    def get_app_yaml(self, max_depth: int) -> Optional[str]:
        """
        Get YAML representation of the application.
        
        Args:
            max_depth: Maximum depth to traverse
            
        Returns:
            str: YAML string if successful, None otherwise
        """
        result = lib.getAppYAML(self.context, max_depth)
        return get_string_from_pointer(result) if result else None

    def get_main_window_yaml(self, max_depth: int) -> Optional[str]:
        """
        Get YAML representation of the main window.
        
        Args:
            max_depth: Maximum depth to traverse
            
        Returns:
            str: YAML string if successful, None otherwise
        """
        result = lib.getMainWindowYAML(self.context, max_depth)
        return get_string_from_pointer(result) if result else None

    def get_focused_window_yaml(self, max_depth: int) -> Optional[str]:
        """
        Get YAML representation of the focused window.
        
        Args:
            max_depth: Maximum depth to traverse
            
        Returns:
            str: YAML string if successful, None otherwise
        """
        result = lib.getFocusedWindowYAML(self.context, max_depth)
        return get_string_from_pointer(result) if result else None

    def get_menu_bar_yaml(self, max_depth: int) -> Optional[str]:
        """
        Get YAML representation of the menu bar.
        
        Args:
            max_depth: Maximum depth to traverse
            
        Returns:
            str: YAML string if successful, None otherwise
        """
        result = lib.getMenuBarYAML(self.context, max_depth)
        return get_string_from_pointer(result) if result else None

    def get_element_at_mouse_position_yaml(self, max_depth: int = 2) -> Optional[str]:
        """
        Get YAML representation of the UI element at the current mouse cursor position.
        
        Args:
            max_depth: Maximum depth to traverse in the accessibility hierarchy (default: 2)
            
        Returns:
            str: YAML string if successful, None otherwise
        """
        result = lib.getElementAtMousePositionYAML(self.context, max_depth)
        return get_string_from_pointer(result) if result else None

    def get_query_element_yaml(self, context_type: ContextType, idx: ElementId, max_depth: int) -> Optional[str]:
        """
        Get YAML representation of a specific element.
        
        Args:
            context_type: Type of context ("App", "Main", "Menu", "Focused", "Query")
            idx: Element ID in the context
            max_depth: Maximum depth to traverse
            
        Returns:
            str: YAML string if successful, None otherwise
        """
        result = lib.getQueryElementYAML(
            self.context,
            context_type.encode('utf-8'),
            idx,
            max_depth
        )
        return get_string_from_pointer(result) if result else None

    def perform_action(self, context_type: ContextType, element_id: ElementId, action: ActionName) -> bool:
        """
        Perform an accessibility action on an element.
        
        Args:
            context_type: Type of context ("App", "Main", "Menu", "Focused", "Query")
            element_id: ID of the element to act on
            action: Name of the action to perform
            
        Returns:
            bool: True if successful, False otherwise
        """
        return lib.performAction(
            self.context,
            context_type.encode('utf-8'),
            element_id,
            action.encode('utf-8')
        )

    def set_attribute_value(self, context_type: ContextType, element_id: ElementId, 
                          attribute: AttributeName, value: AttributeValue) -> bool:
        """
        Set an attribute value for an element.
        
        Args:
            context_type: Type of context ("App", "Main", "Menu", "Focused", "Query")
            element_id: ID of the element
            attribute: Name of the attribute to set
            value: Value to set
            
        Returns:
            bool: True if successful, False otherwise
        """
        value_ptr, value_type = create_value_pointer(value)
        
        return lib.setAttributeValue(
            self.context,
            context_type.encode('utf-8'),
            element_id,
            attribute.encode('utf-8'),
            value_ptr,
            value_type.encode('utf-8')
        )
