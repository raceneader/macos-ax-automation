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
    prompt_accessibility_permissions,
    launch_application,
    raise_application,
)
from axplorer.common.yaml import filter_yaml, filter_yaml_nodes
from axplorer.macos.action import double_left_click, drag_to_element, left_click, move_to_element, press_key_combo, right_click, scroll_down, scroll_up, type_text
from axplorer.macos.apps.excel_helper import flatten_excel_cells, get_compact_excel_yaml

# UI Element IDs for iMovie interface
FONT_COMBO_BUTTON_ID = 36
FONT_COMBO_BUTTON2_ID = 37
TRAILER_BUTTON_ID = 37
FONT_BUTTON_ID = 246
CELL_ID = 720


def do_excel_demo() -> None:
    prompt_accessibility_permissions()

    # Launch and focus iMovie
    if not raise_application("Microsoft Excel"):
        print("Launching iMovie...")
        launch_application("Microsoft Excel")
        time.sleep(2)  # Wait for launch
        raise_application("Microsoft Excel")

    time.sleep(2)  # Wait for window to be ready

    # Create explorer instance
    try:
        with AccessibilityExplorer("Microsoft Excel") as explorer:
            # Get YAML for the main window
            yaml = explorer.get_main_window_yaml(50)
            if yaml:
                # Remove position-related attributes
                keys_to_remove = ["AXFrame", "AXPosition", "AXSize", "AXRectInParentSpace", "AXVisibleCharacterRange", "AXSharedCharacterRange", 
                                  "AXSelectedTextRange", "AXNumberOfCharacters", "AXInsertionPointLineNumber", "AXFocused", "AXColumnIndexRange",
                                  "AXRowIndexRange", "AXOrientation", "AXModal", "AXActivationPoint"]
                #yaml = filter_yaml(yaml, keys_to_remove)
                with open("output.yaml", "w") as file:
                    file.write(yaml)
                yaml = get_compact_excel_yaml(explorer)
                #yaml = filter_yaml_nodes(yaml, "AXRole", "AXCell")
                try:
                    with open("output1.yaml", "w") as file:
                        file.write(yaml)
                    print("Saved UI hierarchy to output.yaml")
                except IOError as e:
                    print(f"Failed to save YAML: {e}")
            else:
                print("Failed to get window hierarchy")

            # move mouse to cell and click
            move_to_element(explorer=explorer, context_type="Main", element_id=2036)
            right_click()

            time.sleep(10)

            # move mouse to font selection and click

            move_to_element(explorer=explorer, context_type="Main", element_id=FONT_COMBO_BUTTON_ID)
            left_click()


            explorer.get_main_window_yaml(50)

            explorer.perform_action(
                context_type="Main",
                element_id=FONT_BUTTON_ID,
                action="AXPick"
            )

            # move_to_element(explorer=explorer, context_type="Main", element_id=FONT_COMBO_BUTTON2_ID)
            # left_click()

            time.sleep(1)

            type_text("Hi Phil, this is a demo of automated font selection and typing!\n")

            type_text("And if the LLM is smart enough it should know to send a newline to get to the cell below\t")

            type_text("And a tab to go right\n")

            time.sleep(1)

            press_key_combo(key = "\t", modifiers=["shift"])

            type_text("... And SHIFT tab to go left... now watch me drag\n")

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

            time.sleep(2)

            move_to_element(explorer=explorer, context_type="Main", element_id=CELL_ID + 10)

            left_click()

            type_text("Ready")

            time.sleep(1)
            
            move_to_element(explorer=explorer, context_type="Main", element_id=CELL_ID + 10, position="bottomRight")

            time.sleep(2)

            drag_to_element(explorer=explorer, context_type="Main", element_id=CELL_ID + 20)

    except Exception as e:
        print(f"Error during iMovie automation: {e}")
        sys.exit(1)

if __name__ == "__main__":
    do_excel_demo()
