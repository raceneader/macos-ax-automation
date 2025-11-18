"""
Goal executor for Excel LLM automation.
Breaks down goals into executable steps and manages their execution.
"""

import json
import time
import yaml
from typing import Callable, List, Dict, Any, Optional, Tuple
from datetime import datetime
from pathlib import Path
from examples.states.step_executor import StepExecutor
from openai import OpenAI

from examples.utils.llm_helper import clean_json_format

from axplorer.macos.apps.excel_helper import flatten_and_filter
from axplorer.macos.explorer import AccessibilityExplorer

from ..models.goal import Goal, Step, GoalStatus, StepStatus

class GoalExecutor:
    """Executes goals by breaking them down into steps and managing their execution."""
    
    def __init__(self, openai_client: OpenAI, llm_model : str, goals: List[Goal],
                 explorer : AccessibilityExplorer,
                 on_goal_update: Callable[[Goal], None],
                 on_steps_update: Callable[[List[Step], Optional[Step]], None],
                 on_step_failure: Callable[[Step, str], bool]):
        self.llm_model = llm_model
        self.client = openai_client
        self.goals = goals
        self.explorer = explorer
        self.current_goal_index = 0
        self.step_executor = StepExecutor(explorer)
        self.on_goal_update = on_goal_update
        self.on_steps_update = on_steps_update
        self.on_step_failure = on_step_failure  # Callback to ask user about replanning
        
        # Create debug directory
        debug_dir = Path("debug")
        debug_dir.mkdir(exist_ok=True)
        self.system_prompt = """You are an Excel automation expert. Given a specific goal and the current Excel state,
        break down the goal into concrete, executable steps. Ensure each step is clear and achievable.
        
        Available actions for steps:
        - move_to_element(element_id, element_keywords): Move mouse to element. element_keywords should be an array of 1-2 exact values from the element's attributes (e.g. ["Sheet1", "A1"] or ["addSheetTabButton"])
        - left_click(): Click where the mouse is
        - right_click(): Right click where the mouse is
        - double_left_click(): Double click where the mouse is
        - type_text(text): Type text (can include \\n and \\t)
        - press_key_combo(key, modifiers): Press key with modifiers
        - scroll_up(distance): Scroll up by pixels
        - scroll_down(distance): Scroll down by pixels
        - drag_to_element(element_id, element_keywords): Drag from current position to element. element_keywords should be an array of 1-2 exact values from the element's attributes (e.g. ["Sheet1", "A1"] or ["addSheetTabButton"])
        
        Important Rules to always follow:
            - Always left_click or right_click after move_to_element to trigger a button or focus or a cell.
            - When entering text, ending with a \n will cause the cell below to be selected, \t will cause the cell to the right to be selected
            - press_key_combo can move to adjacent cells. Use \n to move down, \t to move right, \n modifier shift for up, \t modifier shift for let
            - Ending text with a \n or \t, then using press_key_combo in the next step is a duplicate move. Avoid this.
            - Inserting a sheet is performed using the addSheetTabButton
            - Renaming a sheet is performed by double clicking on the sheet name
            - AXValue 0 means that a button is not selected, 1 is selected. For instance Italic
            - When selecting Number Format, first click its "children" element" to open the dropdown as a goal. Then the next goal should be to click the desired format.

        Respond with a JSON array of steps, where each step has:
        - "description": Human-readable description of the step
        - "action": Name of the action to execute
        - "parameters": Dictionary of parameters for the action
        - "validation_criteria": Dictionary describing expected state after step
        
        Ensure this is a valid JSON array or otherwise the process will fail.

        Example response:
        [
            {
                "description": "Move to cell A1",
                "action": "move_to_element",
                "parameters": {
                    "element_id": 123,
                    "element_keywords": ["Sheet1", "A1"]
                },
                "validation_criteria": {
                    "mouse_over_element": 123
                }
            },
            {
                "description": "Enter header text",
                "action": "type_text",
                "parameters": {"text": "Header\\n"},
                "validation_criteria": {
                    "cell_value": "Header",
                    "cell_address": "A1"
                }
            }
        ]
        """
    
    def plan_goal_execution(
        self, 
        goal: Goal, 
        completed_goals: List[Goal],
        excel_state: str,
        mouse_state: str
    ) -> List[Step]:
        """Plan the execution steps for a goal."""
        messages = [
            {"role": "system", "content": self.system_prompt},
            {"role": "user", "content": f"""
            Goal to accomplish:
            {json.dumps(goal.to_dict(), indent=2)}
            
            Previously completed goals:
            {json.dumps([g.to_dict() for g in completed_goals], indent=2)}
            
            Current Excel State:
            {excel_state}
            
            Mouse Position:
            {mouse_state}
            """}
        ]
        
        response = self.client.chat.completions.create(
            model=self.llm_model,
            messages=messages,
            temperature=0.4
        )
        
        try:
            # Parse the response into a list of step dictionaries
            steps_data = json.loads(clean_json_format(response.choices[0].message.content))
            
            # Convert to Step objects
            steps = []
            for step_data in steps_data:
                step = Step(
                    description=step_data["description"],
                    action=step_data["action"],
                    parameters=step_data["parameters"],
                    validation_criteria=step_data.get("validation_criteria"),
                    element_keywords=step_data["parameters"].get("element_keywords")
                )
                steps.append(step)
            
            return steps
            
        except json.JSONDecodeError as e:
            raise ValueError(f"Failed to parse LLM response as JSON: {e}")
        except KeyError as e:
            raise ValueError(f"Missing required field in step data: {e}")
    
    def validate_step_result(
        self,
        step: Step,
        excel_state: str,
        mouse_state: str
    ) -> Tuple[bool, Optional[str]]:
        """Validate the result of a step execution."""
        if not step.validation_criteria:
            return True, None

        return True, None   
        messages = [
            {"role": "system", "content": """You are an Excel automation expert.
            Validate whether a step's execution resulted in the expected state.
            
            Compare the validation criteria against the current Excel and mouse state.
            
            Respond with a JSON object:
            {
                "valid": true/false,
                "error": "Description of what's wrong" (if valid is false)
            }
            """},
            {"role": "user", "content": f"""
            Step executed:
            {json.dumps({
                "description": step.description,
                "action": step.action,
                "parameters": step.parameters,
                "validation_criteria": step.validation_criteria
            }, indent=2)}
            
            Current Excel State:
            {excel_state}
            
            Mouse Position:
            {mouse_state}
            
            Validate if the step execution was successful.
            """}
        ]
        
        response = self.client.chat.completions.create(
            model=self.llm_model,
            messages=messages,
            temperature=0.2
        )
        
        try:
            result = json.loads(clean_json_format(response.choices[0].message.content))
            return result["valid"], result.get("error")
            
        except (json.JSONDecodeError, KeyError) as e:
            return False, f"Failed to validate step: {e}"
    
    def handle_step_failure(
        self,
        step: Step,
        error: str,
        excel_state: str,
        mouse_state: str
    ) -> Optional[Step]:
        """Try to generate a recovery step when a step fails."""
        messages = [
            {"role": "system", "content": """You are an Excel automation expert.
            When a step fails, analyze the error and current state to determine a recovery step.
            
            Respond with either:
            1. A JSON object describing a recovery step (same format as normal steps)
            2. The string "ABORT" if recovery is not possible
            """},
            {"role": "user", "content": f"""
            Failed Step:
            {json.dumps({
                "description": step.description,
                "action": step.action,
                "parameters": step.parameters,
                "validation_criteria": step.validation_criteria
            }, indent=2)}
            
            Error:
            {error}
            
            Current Excel State:
            {excel_state}
            
            Mouse Position:
            {mouse_state}
            
            Determine if and how we can recover from this failure.
            """}
        ]
        
        response = self.client.chat.completions.create(
            model=self.llm_model,
            messages=messages,
            temperature=0.2
        )
        
        content = response.choices[0].message.content.strip()
        if content == "ABORT":
            return None
            
        try:
            recovery_data = json.loads(content)
            return Step(
                description=f"Recovery: {recovery_data['description']}",
                action=recovery_data["action"],
                parameters=recovery_data["parameters"],
                validation_criteria=recovery_data.get("validation_criteria"),
                element_keywords=recovery_data["parameters"].get("element_keywords")
            )
            
        except (json.JSONDecodeError, KeyError) as e:
            return None
    
    def execute_goals(self) -> bool:
        """Main execution loop for processing all goals."""
        while self.current_goal_index < len(self.goals):
            if not self.execute_current_goal():
                return False
        return True

    def save_debug_info(self, excel_state: str, goal: Goal, step: Optional[Step] = None) -> None:
        """Save debug information to a unique file for each event."""
        # Determine event type based on context
        if step is None:
            event_type = "goal_state"
            if goal.status == GoalStatus.IN_PROGRESS:
                event_type = "pre_planning" if not hasattr(self, '_planning_done') else "post_planning"
                if not hasattr(self, '_planning_done'):
                    self._planning_done = True
        else:
            event_type = "step_state"
            if step.status == StepStatus.IN_PROGRESS:
                event_type = "pre_step"
            elif step.status in [StepStatus.COMPLETED, StepStatus.FAILED]:
                event_type = "post_step"

        # Create unique filename with timestamp and event type
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
        debug_file = Path("debug") / f"debug_{timestamp}_{event_type}.yaml"

        # Build debug info dictionary
        debug_info = {
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "event_type": event_type,
            "goal": goal.to_dict()
        }

        # Add step info if present
        if step:
            debug_info["step"] = {
                "description": step.description,
                "action": step.action,
                "parameters": step.parameters,
                "status": step.status.value,
                "error_message": step.error_message
            }

        # Format excel state
        try:
            # Try to parse and reformat the excel state as YAML
            excel_data = yaml.safe_load(excel_state)
            debug_info["excel_state"] = excel_data
        except Exception:
            # If parsing fails, store as raw string
            debug_info["excel_state"] = excel_state

        # Write debug info to unique file
        with open(debug_file, 'w') as f:
            yaml.dump(debug_info, f, sort_keys=False, allow_unicode=True, default_flow_style=False)

    def execute_current_goal(self) -> bool:
        """Execute current goal and manage its lifecycle."""
        current_goal = self.goals[self.current_goal_index]
        current_goal.status = GoalStatus.IN_PROGRESS
        self.on_goal_update(current_goal)

        try:
            excel_state, mouse_state = self.step_executor.get_current_state()
            # Save initial state before planning
            self.save_debug_info(excel_state, current_goal)
            # Plan steps for current goal
            steps = self.plan_goal_execution(
                current_goal,
                self.goals[:self.current_goal_index],
                excel_state,
                mouse_state
            )
            # Save state after planning
            self.save_debug_info(excel_state, current_goal)
            self.on_steps_update(steps, None)  # No current step yet when first planned

            # Execute and validate each step
            for step in steps:
                step.status = StepStatus.IN_PROGRESS
                print(f"Executing step: {step.description}")
                print(f"Action: {step.action}")
                print(f"Parameters: {step.parameters}")
                if step.element_keywords:
                    print(f"Element Keywords: {step.element_keywords}")

                if eid := step.parameters.get("element_id"):
                    print(f"{eid}: {flatten_and_filter(self.step_executor.query_element(eid))}")
                
                self.on_steps_update(steps, step)

                # Save state before step execution
                excel_state, mouse_state = self.step_executor.get_current_state()
                self.save_debug_info(excel_state, current_goal, step)
                
                # Execute the step
                success, error = self.step_executor.execute_step(step)
                if not success:
                    step.status = StepStatus.FAILED
                    self.on_steps_update(steps, step)
                    if self.on_step_failure(step, error or "Step execution failed"):
                        return self.execute_current_goal()  # Restart with new plan
                    return False

                # Get fresh state for validation and save post-execution state
                excel_state, mouse_state = self.step_executor.get_current_state()
                self.save_debug_info(excel_state, current_goal, step)
                
                # Validate the step result
                success, error = self.validate_step_result(step, excel_state, mouse_state)
                if not success:
                    step.status = StepStatus.FAILED
                    self.on_steps_update(steps, step)
                    if self.on_step_failure(step, error or "Step validation failed"):
                        return self.execute_current_goal()  # Restart with new plan
                    return False

                step.status = StepStatus.COMPLETED
                self.on_steps_update(steps, step)
                # Save state after step completion
                excel_state, mouse_state = self.step_executor.get_current_state()
                self.save_debug_info(excel_state, current_goal, step)

            # Mark goal as complete and move to next
            current_goal.status = GoalStatus.COMPLETED
            self.on_goal_update(current_goal)
            # Save final state after goal completion
            excel_state, mouse_state = self.step_executor.get_current_state()
            self.save_debug_info(excel_state, current_goal)
            self.current_goal_index += 1
            return True

        except Exception as e:
            current_goal.status = GoalStatus.FAILED
            self.on_goal_update(current_goal)
            raise e

    def validate_goal_completion(
        self,
        goal: Goal,
        excel_state: str
    ) -> Tuple[bool, Optional[str]]:
        """Validate that a goal has been fully completed."""
        if not goal.validation_criteria:
            return True, None
            
        messages = [
            {"role": "system", "content": """You are an Excel automation expert.
            Validate whether a goal has been fully completed by checking its validation criteria
            against the current Excel state.
            
            Respond with a JSON object:
            {
                "completed": true/false,
                "error": "Description of what's missing" (if completed is false)
            }
            """},
            {"role": "user", "content": f"""
            Goal:
            {json.dumps(goal.to_dict(), indent=2)}
            
            Current Excel State:
            {excel_state}
            
            Validate if the goal has been fully completed.
            """}
        ]
        
        response = self.client.chat.completions.create(
            model=self.llm_model,
            messages=messages,
            temperature=0.2
        )
        
        try:
            result = json.loads(response.choices[0].message.content)
            return result["completed"], result.get("error")
            
        except (json.JSONDecodeError, KeyError) as e:
            return False, f"Failed to validate goal completion: {e}"
