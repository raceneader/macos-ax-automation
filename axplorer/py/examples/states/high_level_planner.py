"""
High-level planner for Excel LLM automation.
Generates initial goal plans and handles user feedback.
"""

import json
from typing import List, Dict, Any, Optional
from datetime import datetime
import uuid
from openai import OpenAI

from examples.utils.llm_helper import clean_json_format

from ..models.goal import Goal, Step, GoalStatus, StepStatus

class HighLevelPlanner:
    """Plans high-level goals for Excel automation tasks."""
    
    def __init__(self, openai_client: OpenAI, llm_model : str):
        self.llm_model = llm_model
        self.client = openai_client
        self.system_prompt = """You are an Excel automation expert. Given a user request and Excel window state,
        create a high-level plan breaking down the task into clear, achievable goals.
        
        Each goal should be specific and independently verifiable. Goals should be sequenced logically,
        with any dependencies clearly identified. A goal should be high level, representing a change in Excel book, 
        such as completion of a set data entered, creation of a new sheet, insertion of a pivot table, etc.

        Goals should avoid actions that significantly alter the Excel state, such as switching ribbon tabs, creating new sheets, 
        or adding charts. This is because these changes modify the context, and the system needs the updated state to correctly 
        generate the next set of actions to achieve the goal.

        Analyze the Current Excel State, looking at existing sheets, and fields.
        
        Respond with a JSON array of goals, where each goal has:
        - "id": A unique string identifier
        - "description": Clear description of what needs to be accomplished
        - "validation_criteria": Dictionary of criteria to verify goal completion
        - "dependencies": Array of goal IDs that must be completed first (or empty array if none)
        
        Example response:
        [
            {
                "id": "g1",
                "description": "Select and format header row",
                "validation_criteria": {
                    "header_cells": ["A1", "B1", "C1"],
                    "expected_format": "bold"
                },
                "dependencies": []
            },
            {
                "id": "g2",
                "description": "Enter data in columns A through C",
                "validation_criteria": {
                    "filled_ranges": ["A2:A10", "B2:B10", "C2:C10"]
                },
                "dependencies": ["g1"]
            }
        ]
        """
    
    def generate_plan(self, user_request: str, excel_state: str) -> List[Goal]:
        """Generate a high-level plan from the user request and Excel state."""
        messages = [
            {"role": "system", "content": self.system_prompt},
            {"role": "user", "content": f"""
            User Request: {user_request}
            
            Current Excel State:
            {excel_state}
            
            Generate a plan of goals to accomplish this task.
            """}
        ]
        
        response = self.client.chat.completions.create(
            model=self.llm_model,
            messages=messages,
            temperature=0.7
        )
        
        try:
            # Parse the response into a list of goal dictionaries
            goals_data = json.loads(clean_json_format(response.choices[0].message.content))
            
            # Convert to Goal objects
            goals = []
            for goal_data in goals_data:
                goal = Goal(
                    id=goal_data["id"],
                    description=goal_data["description"],
                    validation_criteria=goal_data.get("validation_criteria"),
                    dependencies=goal_data.get("dependencies", [])
                )
                goals.append(goal)
            
            return goals
            
        except json.JSONDecodeError as e:
            raise ValueError(f"Failed to parse LLM response as JSON: {e}")
        except KeyError as e:
            raise ValueError(f"Missing required field in goal data: {e}")
    
    def incorporate_feedback(self, goals: List[Goal], feedback: str) -> List[Goal]:
        """Update the plan based on user feedback."""
        messages = [
            {"role": "system", "content": self.system_prompt},
            {"role": "user", "content": f"""
            Current Goals:
            {json.dumps([goal.to_dict() for goal in goals], indent=2)}
            
            User Feedback:
            {feedback}
            
            Generate an updated plan incorporating this feedback.
            """}
        ]
        
        response = self.client.chat.completions.create(
            model=self.llm_model,
            messages=messages,
            temperature=0.7
        )
        
        try:
            # Parse the updated goals
            updated_goals_data = json.loads(response.choices[0].message.content)
            
            # Convert to Goal objects while preserving progress of existing goals
            updated_goals = []
            existing_goals = {goal.id: goal for goal in goals}
            
            for goal_data in updated_goals_data:
                goal_id = goal_data["id"]
                if goal_id in existing_goals:
                    # Update existing goal while preserving its progress
                    existing_goal = existing_goals[goal_id]
                    existing_goal.description = goal_data["description"]
                    existing_goal.validation_criteria = goal_data.get("validation_criteria")
                    existing_goal.dependencies = goal_data.get("dependencies", [])
                    updated_goals.append(existing_goal)
                else:
                    # Create new goal
                    new_goal = Goal(
                        id=goal_id,
                        description=goal_data["description"],
                        validation_criteria=goal_data.get("validation_criteria"),
                        dependencies=goal_data.get("dependencies", [])
                    )
                    updated_goals.append(new_goal)
            
            return updated_goals
            
        except json.JSONDecodeError as e:
            raise ValueError(f"Failed to parse LLM response as JSON: {e}")
        except KeyError as e:
            raise ValueError(f"Missing required field in goal data: {e}")
    
    def validate_plan(self, goals: List[Goal]) -> bool:
        """Validate that the plan is properly structured."""
        # Check for duplicate IDs
        goal_ids = [goal.id for goal in goals]
        if len(goal_ids) != len(set(goal_ids)):
            return False
        
        # Check for circular dependencies
        for goal in goals:
            if not self._check_dependencies(goal, goals, set()):
                return False
        
        return True
    
    def _check_dependencies(self, goal: Goal, all_goals: List[Goal], visited: set) -> bool:
        """Check for circular dependencies starting from a goal."""
        if goal.id in visited:
            return False
        
        visited.add(goal.id)
        goal_dict = {g.id: g for g in all_goals}
        
        for dep_id in goal.dependencies:
            if dep_id not in goal_dict:
                return False
            if not self._check_dependencies(goal_dict[dep_id], all_goals, visited.copy()):
                return False
        
        return True
    
    def get_next_goal(self, goals: List[Goal]) -> Optional[Goal]:
        """Get the next goal that is ready to be worked on."""
        goal_dict = {goal.id: goal for goal in goals}
        
        for goal in goals:
            if goal.status != GoalStatus.PENDING:
                continue
                
            # Check if all dependencies are completed
            deps_completed = all(
                goal_dict[dep_id].status == GoalStatus.COMPLETED
                for dep_id in goal.dependencies
            )
            
            if deps_completed:
                return goal
        
        return None