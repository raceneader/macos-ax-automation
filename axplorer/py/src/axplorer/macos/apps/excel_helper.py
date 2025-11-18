"""
Excel-specific helper functions for accessibility testing.
"""
from axplorer.common.yaml import filter_yaml
from axplorer.macos.explorer import AccessibilityExplorer
from axplorer.macos.lib import lib, get_string_from_pointer

def flatten_excel_cells(yaml_str: str) -> str:
    """
    Flattens Excel cell elements in a YAML hierarchy by merging child attributes
    into parents and removing the children. This is useful for Excel cells that
    may have nested structure but should be treated as a single element.
    
    Args:
        yaml_str: YAML string containing Excel cell elements
        
    Returns:
        Processed YAML string with flattened Excel cells, or empty string if processing fails
        
    Example:
        >>> yaml_str = '''
        ... element1:
        ...   attributes:
        ...     AXRole: AXCell
        ...     AXRoleDescription: cell
        ...   children:
        ...     child1:
        ...       attributes:
        ...         AXDescription: "Cell A1"
        ...         AXValue: 42
        ... '''
        >>> flattened = flatten_excel_cells(yaml_str)
        >>> print(flattened)
        element1:
          attributes:
            AXRole: AXCell
            AXRoleDescription: cell
            AXDescription: "Cell A1"
            AXValue: 42
    """
    yaml_bytes = yaml_str.encode('utf-8')
    result_ptr = lib.flattenExcelCells(yaml_bytes)
    return get_string_from_pointer(result_ptr)


def flatten_and_filter(excel_state):
    keys_to_remove = ["AXFrame", "AXPosition", "AXSize", "AXRectInParentSpace", "AXVisibleCharacterRange", "AXSharedCharacterRange", 
                        "AXSelectedTextRange", "AXNumberOfCharacters", "AXInsertionPointLineNumber", "AXFocused", "AXColumnIndexRange",
                        "AXRowIndexRange", "AXOrientation"]
    excel_state = filter_yaml(excel_state, keys_to_remove)
    return flatten_excel_cells(excel_state)


def get_compact_excel_yaml(explorer : AccessibilityExplorer)-> str | None:
    excel_state = explorer.get_main_window_yaml(50)
    if excel_state:
        return flatten_and_filter(excel_state)

    return None