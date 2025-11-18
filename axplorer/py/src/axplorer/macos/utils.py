import ctypes
from AppKit import NSWorkspace
from axplorer.macos.lib import lib

def is_accessibility_enabled() -> bool:
    """
    Check if Accessibility permissions are enabled for this process.
    
    Returns:
        bool: True if accessibility is enabled, False otherwise
    """
    try:
        # Load ApplicationServices Framework
        app_services = ctypes.CDLL("/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices")
        
        # Check AXIsProcessTrusted
        app_services.AXIsProcessTrusted.restype = ctypes.c_bool
        return bool(app_services.AXIsProcessTrusted())
    except Exception as e:
        print(f"Error checking accessibility permissions: {e}")
        return False

def prompt_accessibility_permissions():
    """
    Prompt the user to enable Accessibility permissions by opening System Settings.
    """
    if not is_accessibility_enabled():
        print("This application needs Accessibility permissions to function.")
        print("Go to System Settings > Privacy & Security > Accessibility and enable permissions for this application.")
        # Open System Settings to the Security & Privacy pane
        NSWorkspace.sharedWorkspace().openFile_("/System/Library/PreferencePanes/Security.prefPane")
    else:
        print("Accessibility permissions are already granted.")

def raise_application(app_name: str) -> bool:
    """
    Raise (bring to front) an application with the specified name.
    
    Args:
        app_name: The name of the application (e.g., 'Safari')
        
    Returns:
        bool: True if the application was successfully raised, False otherwise
        
    Example:
        >>> raise_application('Safari')
        True
    """
    try:
        return lib.raiseApplication(app_name.encode('utf-8'))
    except Exception as e:
        print(f"Error raising application: {e}")
        return False

def launch_application(app_name: str, timeout: float = 30.0) -> bool:
    """
    Launch an application with the specified name and wait for it to be ready.
    
    Args:
        app_name: The name of the application (e.g., 'Safari')
        timeout: Maximum time to wait for the application to launch (in seconds)
        
    Returns:
        bool: True if the application was successfully launched and ready, False otherwise
        
    Example:
        >>> launch_application('Safari')
        True
    """
    try:
        # The Swift implementation now handles the waiting internally
        result = lib.launchApplication(app_name.encode('utf-8'))
        if not result:
            print(f"Failed to launch application '{app_name}'")
            return False
    except Exception as e:
        print(f"Error launching application: {e}")
        return False
