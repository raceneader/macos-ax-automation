"""
Step executor for Excel LLM automation.
Handles execution and validation of individual automation steps.
"""

from typing import Dict, Any, Optional, Tuple, Callable
import time
from datetime import datetime

from axplorer import AccessibilityExplorer, raise_application
from axplorer.macos.action import (
    double_left_click,
    drag_to_element,
    left_click,
    move_to_element,
    press_key_combo,
    right_click,
    scroll_down,
    scroll_up,
    type_text
)
from axplorer.macos.apps.excel_helper import flatten_excel_cells, get_compact_excel_yaml

from ..models.goal import Step, StepStatus

class StepExecutor:
    """Executes and validates individual automation steps."""
    
    def __init__(self, explorer: AccessibilityExplorer):
        self.explorer = explorer
        
        # Map of action names to their execution functions
        self.action_handlers: Dict[str, Callable] = {
            'move_to_element': self._handle_move_to_element,
            'left_click': lambda _: left_click(),
            'right_click': lambda _: right_click(),
            'double_left_click': lambda _: double_left_click(),
            'type_text': self._handle_type_text,
            'press_key_combo': self._handle_key_combo,
            'scroll_up': lambda params: scroll_up(params.get('distance', 800)),
            'scroll_down': lambda params: scroll_down(params.get('distance', 800)),
            'drag_to_element': self._handle_drag_to_element
        }
    
    def execute_step(self, step: Step) -> Tuple[bool, Optional[str]]:
        """Execute a single automation step."""
        try:
            # Ensure Excel is in foreground
            raise_application("Microsoft Excel")
            time.sleep(0.5)  # Brief pause to ensure window is ready
            
            # Mark step as started
            step.start()
            
            # Get the handler for this action
            handler = self.action_handlers.get(step.action)
            if not handler:
                step.fail(f"Unknown action: {step.action}")
                return False, f"Unknown action: {step.action}"
            
            # Execute the action
            try:
                handler(step.parameters)
                time.sleep(0.5)  # Brief pause after action
                step.complete()
                return True, None
                
            except Exception as e:
                error_msg = f"Action execution failed: {str(e)}"
                step.fail(error_msg)
                return False, error_msg
                
        except Exception as e:
            error_msg = f"Step execution failed: {str(e)}"
            step.fail(error_msg)
            return False, error_msg
    
    def _handle_move_to_element(self, params: Dict[str, Any]) -> None:
        """Handle move_to_element action."""
        element_id = params.get('element_id')
        if not element_id:
            raise ValueError("element_id is required for move_to_element")
        
        try:
            element_id_int = int(element_id)
        except (ValueError, TypeError):
            raise ValueError("element_id must be a valid integer")
        
        move_to_element(self.explorer, "Main", element_id_int)
    
    def _handle_type_text(self, params: Dict[str, Any]) -> None:
        """Handle type_text action."""
        text = params.get('text')
        if not text:
            raise ValueError("text is required for type_text")
        
        type_text(text=text)
    
    def _handle_key_combo(self, params: Dict[str, Any]) -> None:
        """Handle press_key_combo action."""
        key = params.get('key')
        modifiers = params.get('modifiers', [])
        if not key:
            raise ValueError("key is required for press_key_combo")
        
        press_key_combo(key, modifiers)
    
    def _handle_drag_to_element(self, params: Dict[str, Any]) -> None:
        """Handle drag_to_element action."""
        element_id = params.get('element_id')
        if not element_id:
            raise ValueError("element_id is required for drag_to_element")
        
        try:
            element_id_int = int(element_id)
        except (ValueError, TypeError):
            raise ValueError("element_id must be a valid integer")
        
        drag_to_element(self.explorer, "Main", element_id_int)
    
    def get_current_state(self) -> Tuple[str, str]:
        """Get the current Excel window and mouse state."""
        # Get main window YAML
        excel_state = get_compact_excel_yaml(self.explorer)
        if not excel_state:
            raise RuntimeError("Failed to get Excel window state")
        
        # Get mouse position element info
        mouse_state = self.explorer.get_element_at_mouse_position_yaml(0)
        if not mouse_state:
            mouse_state = "Mouse position: Outside Excel window"
        mouse_state = flatten_excel_cells(mouse_state)
        
        return excel_state, mouse_state
    
    def verify_excel_foreground(self) -> bool:
        """Verify that Excel is in the foreground."""
        try:
            return raise_application("Microsoft Excel")
        except Exception:
            return False

    def query_element(self, idx) -> str:
        """Get the current Excel window and mouse state."""
        # Get main window YAML
        return self.explorer.get_query_element_yaml("Main", idx, 0)
