#!/usr/bin/env python3
"""
Test script demonstrating the Excel LLM Assistant's state-based architecture.
"""

import os
import time
from openai import OpenAI

from examples.models import Goal, Step, GoalStatus, StepStatus
from examples.states import HighLevelPlanner, GoalExecutor, StepExecutor
from examples.ui import AutomationUI

def test_high_level_planning():
    """Test the high-level planning functionality."""
    # Set up OpenAI client (using test API key)
    client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    
    # Initialize planner
    planner = HighLevelPlanner(client)
    
    # Example Excel state (simplified for testing)
    excel_state = """
    AXApplication "Microsoft Excel":
        AXWindow "Book1":
            AXSheet "Sheet1":
                AXCell "A1":
                    AXValue: ""
                AXCell "B1":
                    AXValue: ""
                AXCell "C1":
                    AXValue: ""
    """
    
    # Test plan generation
    print("\nTesting plan generation...")
    goals = planner.generate_plan(
        "Create a simple sales report with headers in row 1 and data in rows 2-5",
        excel_state
    )
    
    print(f"\nGenerated {len(goals)} goals:")
    for goal in goals:
        print(f"\n- {goal.description}")
        if goal.validation_criteria:
            print("  Validation criteria:", goal.validation_criteria)
        if goal.dependencies:
            print("  Dependencies:", goal.dependencies)
    
    # Test plan validation
    print("\nValidating plan structure...")
    is_valid = planner.validate_plan(goals)
    print(f"Plan is {'valid' if is_valid else 'invalid'}")
    
    # Test plan modification with feedback
    print("\nTesting plan modification with feedback...")
    updated_goals = planner.incorporate_feedback(
        goals,
        "Add totals in row 6 for each column"
    )
    
    print(f"\nUpdated plan now has {len(updated_goals)} goals:")
    for goal in updated_goals:
        print(f"\n- {goal.description}")
        if goal.validation_criteria:
            print("  Validation criteria:", goal.validation_criteria)
        if goal.dependencies:
            print("  Dependencies:", goal.dependencies)

def test_ui():
    """Test the enhanced Tkinter UI."""
    # Create UI
    ui = AutomationUI()
    
    # Create some test goals
    goals = [
        Goal(
            id="g1",
            description="Add headers to row 1",
            validation_criteria={"cells": ["A1", "B1", "C1"]}
        ),
        Goal(
            id="g2",
            description="Enter sales data",
            validation_criteria={"ranges": ["A2:C5"]},
            dependencies=["g1"]
        ),
        Goal(
            id="g3",
            description="Add totals row",
            validation_criteria={"formulas": ["A6", "B6", "C6"]},
            dependencies=["g2"]
        )
    ]
    
    # Add some steps to first goal
    steps = [
        Step(
            description="Move to cell A1",
            action="move_to_element",
            parameters={"element_id": 123}
        ),
        Step(
            description="Enter 'Month' header",
            action="type_text",
            parameters={"text": "Month\n"}
        )
    ]
    
    for step in steps:
        goals[0].add_step(step)
    
    # Update UI with goals
    ui.update_goals(goals)
    
    # Simulate some goal progress
    goals[0].start()
    ui.update_current_task(goals[0], steps[0])
    ui.log_message("Starting first goal", "info")
    
    time.sleep(2)
    
    steps[0].complete()
    ui.update_current_task(goals[0], steps[1])
    ui.log_message("First step completed", "success")
    
    time.sleep(2)
    
    steps[1].complete()
    goals[0].complete()
    ui.update_goals(goals)
    ui.log_message("First goal completed", "success")
    
    # Start UI event loop
    ui.run()

if __name__ == "__main__":
    # Test high-level planning
    test_high_level_planning()
    
    # Test UI (comment out high-level planning test to see UI)
    # test_ui()
