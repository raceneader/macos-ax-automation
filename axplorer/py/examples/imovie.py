#!/usr/bin/env python3
"""
Example demonstrating iMovie automation using the Axplorer library.
This script shows how to:
1. Launch and focus iMovie
2. Navigate through the interface
3. Perform actions on UI elements
"""

import sys
import time
from typing import List, Optional

from axplorer import (
    AccessibilityExplorer,
    is_accessibility_enabled,
    prompt_accessibility_permissions,
    launch_application,
    raise_application,
)
from axplorer.common.yaml import filter_yaml
from axplorer.macos.action import left_click, move_to_element, scroll_down, scroll_up

# UI Element IDs for iMovie interface
FIRST_BUTTON_ID = 24
TRAILER_BUTTON_ID = 37
FINAL_BUTTON_ID = 22

def do_imovie_demo() -> None:
    """
    Demonstrates accessibility automation with iMovie.
    
    This function:
    1. Launches iMovie if not running
    2. Captures the UI hierarchy
    3. Performs a sequence of button clicks
    
    Raises:
        RuntimeError: If accessibility permissions are not granted
    """
    prompt_accessibility_permissions()

    # Launch and focus iMovie
    if not raise_application("iMovie"):
        print("Launching iMovie...")
        launch_application("iMovie")
        time.sleep(2)  # Wait for launch
        raise_application("iMovie")

    time.sleep(2)  # Wait for window to be ready
    
    # Create explorer instance
    try:
        with AccessibilityExplorer("iMovie") as explorer:
            # Get YAML for the main window
            yaml = explorer.get_main_window_yaml(50)
            if yaml:
                # Remove position-related attributes
                # keys_to_remove = ["AXFrame", "AXPosition", "AXSize", "AXRectInParentSpace"]
                # yaml = filter_yaml(yaml, keys_to_remove)
                try:
                    with open("output.yaml", "w") as file:
                        file.write(yaml)
                    print("Saved UI hierarchy to output.yaml")
                except IOError as e:
                    print(f"Failed to save YAML: {e}")
            else:
                print("Failed to get window hierarchy")
            
            time.sleep(2)  # Wait for iMovie to fully focus

            # Perform sequence of actions
            actions = [
                ("First button", FIRST_BUTTON_ID),
                ("Trailer button", TRAILER_BUTTON_ID),
                ("Final button", FINAL_BUTTON_ID)
            ]

            move_to_element(explorer=explorer, context_type="Main", element_id=FIRST_BUTTON_ID)

            left_click()
            # success = explorer.perform_action(
            #     context_type="Main",
            #     element_id=FIRST_BUTTON_ID,
            #     action="AXPress"
            # )

            time.sleep(2)

            explorer.get_main_window_yaml(50)

            move_to_element(explorer=explorer, context_type="Main", element_id=TRAILER_BUTTON_ID)

            time.sleep(1)

            left_click()

            time.sleep(2)

            explorer.get_main_window_yaml(50)

            move_to_element(explorer=explorer, context_type="Main", element_id=FINAL_BUTTON_ID)
            
            left_click()

            scroll_down(800)

            time.sleep(2)

            scroll_up(800)

            time.sleep(1)

            yaml = explorer.get_main_window_yaml(50)
            if yaml:
                # Remove position-related attributes
                # keys_to_remove = ["AXFrame", "AXPosition", "AXSize", "AXRectInParentSpace"]
                # yaml = filter_yaml(yaml, keys_to_remove)
                try:
                    with open("output.yaml", "w") as file:
                        file.write(yaml)
                    print("Saved UI hierarchy to output.yaml")
                except IOError as e:
                    print(f"Failed to save YAML: {e}")
            else:
                print("Failed to get window hierarchy")

            move_to_element(explorer=explorer, context_type="Main", element_id=4)

            # left_click()

    except Exception as e:
        print(f"Error during iMovie automation: {e}")
        sys.exit(1)

if __name__ == "__main__":
    do_imovie_demo()
