import ctypes
from typing import List, Optional, Any
import yaml
from axplorer.macos.lib import lib, get_string_from_pointer

def filter_yaml_nodes(yaml_string: str, key: str, value: Optional[Any] = None) -> Optional[str]:
    """
    Filter a YAML string to remove nodes and their children that match a key or key-value pair.
    
    Args:
        yaml_string: The original YAML string
        key: The key to match
        value: Optional value to match along with the key
        
    Returns:
        Optional[str]: Filtered YAML string, or None if filtering failed
        
    Example:
        >>> yaml = '''
        ... element1:
        ...   aid: 1
        ...   attributes:
        ...     name: Button1
        ...     role: button
        ...   children:
        ...     element2:
        ...       aid: 2
        ...       attributes:
        ...         name: Label
        ...         role: text
        ... element3:
        ...   aid: 3
        ...   attributes:
        ...     name: Button2
        ...     role: button
        ... '''
        >>> filter_yaml_nodes(yaml, 'role', 'button')  # Removes nodes with role=button and their children
    """
    if not yaml_string or not key:
        return None

    try:
        # Convert Python strings to C strings
        yaml_c_string = yaml_string.encode('utf-8')
        key_c_string = key.encode('utf-8')
        value_c_string = value.encode('utf-8') if value is not None else None

        # Call the Swift function
        result = lib.filterYAMLNodes(yaml_c_string, key_c_string, value_c_string)
        return get_string_from_pointer(result) if result else None

    except Exception as e:
        print(f"Error filtering YAML nodes: {e}")
        return None

def filter_yaml(yaml_string: str, keys: List[str]) -> Optional[str]:
    """
    Filter a YAML string to only include specified keys.
    
    Args:
        yaml_string: The original YAML string
        keys: List of keys to keep in the filtered output
        
    Returns:
        Optional[str]: Filtered YAML string, or None if filtering failed
        
    Example:
        >>> yaml = '''
        ... element1:
        ...   aid: 1
        ...   attributes:
        ...     name: Button
        ...     role: button
        ...     position: {x: 100, y: 200}
        ...     size: {width: 50, height: 30}
        ... '''
        >>> filter_yaml(yaml, ['name', 'role'])
        'name: Button\\nrole: button\\n'
    """
    if not yaml_string or not keys:
        return None

    try:
        # Convert Python strings to C strings
        yaml_c_string = yaml_string.encode('utf-8')
        keys_c_array = (ctypes.c_char_p * len(keys))(*[key.encode('utf-8') for key in keys])
        key_count = len(keys)

        # Call the Swift function
        result = lib.filterYAML(yaml_c_string, keys_c_array, key_count)
        return get_string_from_pointer(result) if result else None

    except Exception as e:
        print(f"Error filtering YAML: {e}")
        return None
