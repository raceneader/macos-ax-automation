#!/usr/bin/env python3
"""
Excel LLM Chatbot that uses AXplorer to control Excel based on natural language commands.
Uses a state-based architecture for better control and validation.
"""

import sys
import time
import json
import yaml
import argparse
from typing import List, Optional, Dict, Any, Tuple
from pathlib import Path
from openai import OpenAI

from axplorer import (
    AccessibilityExplorer,
    prompt_accessibility_permissions,
    launch_application,
    raise_application,
)

from examples.models import Goal, Step, StepStatus
from examples.states import GoalExecutor
from examples.states.goal_state_machine import ConfirmChoice, GoalStateMachine, GoalState, GoalEvent, GoalStateResult, ReviewChoice
from examples.ui import AutomationUI

class ExcelLLMController:
    """Main controller for Excel LLM automation."""
    
    # User input prompts
    REVIEW_PROMPT = "Please review the plan:\nEnter 'y' to accept, 'm' to modify, or 'n' to reject"
    FEEDBACK_PROMPT = "Please provide additional feedback:"
    CONFIRM_REJECTION_PROMPT = "Are you sure you want to start over? (y/n):"
    NEW_REQUEST_PROMPT = "Enter your request or 'quit' to exit:"
    INVALID_CHOICE_PROMPT = "Invalid choice. Please try again."
    
    def __init__(self, openai_client: OpenAI, debug: bool = True):
        self.client = openai_client
        self.llm_model = 'gpt-4o'
        self.debug = debug
        self.explorer: Optional[AccessibilityExplorer] = None
        
        # Create debug directory by default
        Path("debug").mkdir(exist_ok=True)

        self.launch_excel() 
        self.explorer = AccessibilityExplorer("Microsoft Excel")
        # Initialize components
        self.ui = AutomationUI()
        self.goal_state_machine = GoalStateMachine(openai_client=openai_client, llm_model=self.llm_model, explorer=self.explorer)
        self.goal_executor = None  # Initialized when goals are accepted
        self.step_executor = None
        
        # Set up UI callback
        self.ui.set_input_callback(self._handle_user_input)

        self._update_ui_for_result(GoalStateResult(self.goal_state_machine.state, []))
    
    def launch_excel(self) -> None:
        """Launch and focus Microsoft Excel."""
        prompt_accessibility_permissions()
        
        if not raise_application("Microsoft Excel"):
            self.ui.log_message("Launching Excel...", "info")
            launch_application("Microsoft Excel")
            time.sleep(2)
            raise_application("Microsoft Excel")
        
        time.sleep(2)  # Wait for window to be ready
    
    def instantiate_goal_executor(self, goals : list[Goal]) -> None:
        """Initialize goal executor."""
        self.goal_executor = GoalExecutor(
            self.client,
            llm_model=self.llm_model,
            goals=goals,
            explorer=self.explorer,
            on_goal_update=self._handle_goal_update,
            on_steps_update=self._handle_steps_update,
            on_step_failure=self._handle_step_failure
        )

    def _map_review_input(self, text: str) -> Optional[ReviewChoice]:
        """Map user input to ReviewChoice enum."""
        mapping = {
            'y': ReviewChoice.ACCEPT,
            'm': ReviewChoice.MODIFY,
            'n': ReviewChoice.REJECT
        }
        return mapping.get(text.lower())
    
    def _map_confirm_input(self, text: str) -> Optional[ConfirmChoice]:
        """Map user input to ConfirmChoice enum."""
        mapping = {
            'y': ConfirmChoice.YES,
            'n': ConfirmChoice.NO
        }
        return mapping.get(text.lower())
    
    def _handle_user_input(self, text: str) -> None:
        """Handle user input from the UI."""
        text = text.strip()
        
        if text.lower() == 'quit':
            self.cleanup()
            sys.exit(0)

        # Get current state and handle accordingly
        current_state = self.goal_state_machine.get_current_state()
        
        try:            
            match current_state:
                case GoalState.REVIEWING_GOALS:
                    choice = self._map_review_input(text)
                    if choice is None:
                        self.ui.update_goals([]) # clear out goal window
                        self.ui.update_tasks(None, [], None) # clear out task window
                        self.ui.log_message(self.REVIEW_PROMPT)
                        return
                        
                    result = self.goal_state_machine.handle_event(
                        GoalEvent.REVIEW_CHOICE_MADE,
                        choice=choice
                    )

                    self._update_ui_for_result(result)

                    self.instantiate_goal_executor(self.goal_state_machine.get_goals())  # Initialize goal_executor
                    # Execute goals and handle result
                    if self.goal_executor.execute_goals():
                        # Goals completed successfully
                        self.ui.log_message("All goals completed successfully!", "success")
                        self.ui.log_message(self.NEW_REQUEST_PROMPT)
                        result = self.goal_state_machine.handle_event(
                            GoalEvent.GOALS_COMPLETED,
                            user_request=""  # Empty request to transition to CREATING_GOALS
                        )
                    else:
                        self.ui.log_message("Failed to complete all goals", "error")
                        self.ui.log_message(self.NEW_REQUEST_PROMPT)
                        result = self.goal_state_machine.handle_event(
                            GoalEvent.GOALS_FAILED,
                            user_request=""  # Empty request to transition to CREATING_GOALS
                        )
                    
                    self._update_ui_for_result(result)
                
                case GoalState.AWAITING_FEEDBACK:
                    result = self.goal_state_machine.handle_event(
                        GoalEvent.FEEDBACK_PROVIDED,
                        feedback=text
                    )
                    self._update_ui_for_result(result)
                
                case GoalState.CONFIRMING_REJECTION:
                    choice = self._map_confirm_input(text)
                    if choice is None:
                        self.ui.log_message("Please enter 'y' or 'n'", "error")
                        return
                        
                    result = self.goal_state_machine.handle_event(
                        GoalEvent.CONFIRM_REJECTION,
                        confirm=choice
                    )
                    self._update_ui_for_result(result)
                
                case GoalState.CREATING_GOALS:
                    # New task request
                    self.ui.log_message(f"Generating plan for: {text}", "info")
                    result = self.goal_state_machine.handle_event(
                        GoalEvent.PLAN_CREATED,
                        user_request=text
                    )
                    self._update_ui_for_result(result)
                
                case GoalState.FAILED:
                    self.ui.log_message(
                        f"System is in failed state. Error: {self.goal_state_machine.get_error()}",
                        "error"
                    )
                
                case _:
                    self.ui.log_message(f"Cannot process input in current state: {current_state}", "error")
            
        except Exception as e:
            self.ui.log_message(f"Error handling input: {str(e)}", "error")
            self.goal_state_machine.handle_event(GoalEvent.ERROR_OCCURRED, error=str(e))
    
    def _update_ui_for_result(self, result: GoalStateResult) -> None:
        """Update UI based on state machine result."""
        if result.error:
            self.ui.log_message(result.error, "error")
            return
            
        match result.new_state:
                case GoalState.REVIEWING_GOALS:
                    self.ui.update_goals(result.goals)
                    prompt = self.INVALID_CHOICE_PROMPT if result.needs_input else self.REVIEW_PROMPT
                    self.ui.log_message(prompt, "info")
            
                case GoalState.GOALS_ACCEPTED:
                    # Start execution of accepted goals
                    self.ui.log_message("All goals accepted!", "success")
            
                case GoalState.CREATING_GOALS:
                    self.ui.log_message("Excel LLM Assistant ready", "info")
                    self.ui.log_message(self.NEW_REQUEST_PROMPT, "info")
            
                case GoalState.AWAITING_FEEDBACK:
                    if result.needs_input:
                        self.ui.log_message(self.FEEDBACK_PROMPT, "info")
            
                case GoalState.CONFIRMING_REJECTION:
                    if result.needs_input:
                        self.ui.log_message(self.CONFIRM_REJECTION_PROMPT, "info")
    
    def run(self) -> None:
        """Run the main application loop."""
        try:
            self.ui.run()
        except KeyboardInterrupt:
            self.cleanup()
    
    def _handle_goal_update(self, goal: Goal) -> None:
        """Handle updates to goal status."""
        self.ui.update_goals(self.goal_executor.goals)


    def _handle_steps_update(self, steps: List[Step], current_step: Optional[Step]) -> None:
        """Handle updates to steps."""
        current_goal = self.goal_executor.goals[self.goal_executor.current_goal_index]
        self.ui.update_tasks(current_goal, steps, current_step)

    def _handle_step_failure(self, step: Step, error: str) -> bool:
        """Handle step execution failures."""
        self.ui.log_message(f"Step failed: {error}", "error")
        # Ask user via UI if they want to replan
        return self.ui.ask_yes_no("Would you like to replan the current goal?")

    def cleanup(self) -> None:
        """Clean up resources."""
        if self.explorer:
            self.explorer.cleanup()
        self.ui.cleanup()

def main():
    parser = argparse.ArgumentParser(description="Excel LLM Controller")
    parser.add_argument("--api-key", help="OpenAI API key", default="")
    args = parser.parse_args()
    
    try:
        client = OpenAI(api_key=args.api_key)
        controller = ExcelLLMController(client)
        controller.run()
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
