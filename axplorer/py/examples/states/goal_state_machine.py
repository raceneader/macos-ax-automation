"""
Goal state machine for managing the lifecycle of goals in Excel automation.
"""

from enum import Enum
from typing import List, Optional, Dict, Any
from dataclasses import dataclass
from openai import OpenAI

from axplorer.macos.apps.excel_helper import get_compact_excel_yaml
from axplorer.macos.explorer import AccessibilityExplorer

from ..models.goal import Goal, GoalStatus
from .high_level_planner import HighLevelPlanner

class GoalState(Enum):
    """States for the goal state machine."""
    CREATING_GOALS = "creating_goals"
    REVIEWING_GOALS = "reviewing_goals"
    AWAITING_FEEDBACK = "awaiting_feedback"
    CONFIRMING_REJECTION = "confirming_rejection"
    GOALS_ACCEPTED = "goals_accepted"
    FAILED = "goals_failed"

class ReviewChoice(Enum):
    """User choices when reviewing a plan."""
    ACCEPT = "accept"
    MODIFY = "modify"
    REJECT = "reject"

class ConfirmChoice(Enum):
    """User choices when confirming an action."""
    YES = "yes"
    NO = "no"

class GoalEvent(Enum):
    """Events that can trigger state transitions."""
    PLAN_CREATED = "plan_created"
    REVIEW_CHOICE_MADE = "review_choice_made"
    FEEDBACK_PROVIDED = "feedback_provided"
    CONFIRM_REJECTION = "confirm_rejection"
    ERROR_OCCURRED = "error_occurred"
    GOALS_COMPLETED = "goals_completed"
    GOALS_FAILED = "goals_failed"

@dataclass
class GoalStateResult:
    """Result of a state machine transition."""
    new_state: GoalState
    goals: List[Goal]
    error: Optional[str] = None
    needs_input: bool = False
    input_prompt: Optional[str] = None

class GoalStateMachine:
    """
    State machine for managing the lifecycle of goals.
    Handles all LLM interactions and goal state transitions.
    """
    
    def __init__(self, openai_client: OpenAI, llm_model : str, explorer: AccessibilityExplorer):
        self.client = openai_client
        self.state = GoalState.CREATING_GOALS
        self.goals: List[Goal] = []
        self.high_level_planner = HighLevelPlanner(openai_client, llm_model=llm_model)
        self.error: Optional[str] = None
        self.feedback_history: List[str] = []  # Track feedback history
        self.original_request: Optional[str] = None  # Store original request
        self.explorer = explorer
    
    def handle_event(self, event: GoalEvent, **kwargs) -> GoalStateResult:
        """
        Handle an event and return the new state result.
        
        Args:
            event: The event to handle
            **kwargs: Additional arguments needed for handling the event
                     - user_request: str (for PLAN_CREATED)
                     - choice: str (for REVIEW_CHOICE_MADE)
                     - feedback: str (for FEEDBACK_PROVIDED)
                     - confirm: str (for CONFIRM_REJECTION)
        
        Returns:
            GoalStateResult containing new state and goals
        """
        try:
            match (self.state, event):
                case (GoalState.CREATING_GOALS, GoalEvent.PLAN_CREATED):
                    # Store original request when first creating plan
                    self.original_request = kwargs['user_request']
                    self.feedback_history = []  # Reset feedback history
                    return self._handle_plan_creation(kwargs['user_request'])
                    
                case (GoalState.REVIEWING_GOALS, GoalEvent.REVIEW_CHOICE_MADE):
                    return self._handle_review_choice(kwargs.get('choice'))
                    
                case (GoalState.AWAITING_FEEDBACK, GoalEvent.FEEDBACK_PROVIDED):
                    return self._handle_plan_feedback(kwargs['feedback'])
                    
                case (GoalState.CONFIRMING_REJECTION, GoalEvent.CONFIRM_REJECTION):
                    return self._handle_rejection_confirmation(kwargs.get('confirm', ''))

                case (GoalState.GOALS_ACCEPTED, GoalEvent.GOALS_COMPLETED) | (GoalState.GOALS_ACCEPTED, GoalEvent.GOALS_FAILED):
                    self.state = GoalState.CREATING_GOALS
                    return GoalStateResult(self.state, [])
                    
                case (_, GoalEvent.ERROR_OCCURRED):
                    return self._handle_error(kwargs.get('error', 'Unknown error occurred'))
                    
                case _:
                    return self._handle_error(f"Invalid event {event} for state {self.state}")
        
        except Exception as e:
            return self._handle_error(str(e))
    
    def _handle_plan_creation(self, user_request: str) -> GoalStateResult:
        """Handle plan creation and transition to reviewing state."""
        try:
            excel_state = get_compact_excel_yaml(self.explorer)
            # Generate new goals using high level planner
            self.goals = self.high_level_planner.generate_plan(user_request, excel_state)
            
            # Validate plan structure
            if not self.high_level_planner.validate_plan(self.goals):
                return self._handle_error("Generated plan has invalid structure")
            
            # Transition to reviewing state
            self.state = GoalState.REVIEWING_GOALS
            return GoalStateResult(
                new_state=self.state,
                goals=self.goals
            )
            
        except Exception as e:
            return self._handle_error(f"Error generating plan: {str(e)}")
    
    def _transition_to_accepted(self) -> GoalStateResult:
        """Handle user acceptance of goals."""
        self.state = GoalState.GOALS_ACCEPTED
        return GoalStateResult(
            new_state=self.state,
            goals=self.goals
        )
    
    def _handle_review_choice(self, choice: Optional[ReviewChoice]) -> GoalStateResult:
        """Handle user's choice during plan review."""
        if not choice:
            return GoalStateResult(
                new_state=self.state,
                goals=self.goals,
                needs_input=True
            )
        
        match choice:
            case ReviewChoice.ACCEPT:
                self.state = GoalState.GOALS_ACCEPTED
                return GoalStateResult(
                    new_state=self.state,
                    goals=self.goals,
                    needs_input=False
                )
            
            case ReviewChoice.MODIFY:
                self.state = GoalState.AWAITING_FEEDBACK
                return GoalStateResult(
                    new_state=self.state,
                    goals=self.goals,
                    needs_input=True
                )
            
            case ReviewChoice.REJECT:
                self.state = GoalState.CONFIRMING_REJECTION
                return GoalStateResult(
                    new_state=self.state,
                    goals=self.goals,
                    needs_input=True
                )
    
    def _handle_rejection_confirmation(self, confirm: Optional[ConfirmChoice]) -> GoalStateResult:
        """Handle confirmation of plan rejection."""
        if not confirm:
            return GoalStateResult(
                new_state=self.state,
                goals=self.goals,
                needs_input=True
            )
            
        match confirm:
            case ConfirmChoice.YES:
                # Reset feedback history when starting fresh
                self.feedback_history = []
                self.original_request = None
                self.state = GoalState.CREATING_GOALS
                return GoalStateResult(
                    new_state=self.state,
                    goals=[],
                    needs_input=True
                )
            
            case ConfirmChoice.NO:
                # Go back to reviewing the current plan
                self.state = GoalState.REVIEWING_GOALS
                return GoalStateResult(
                    new_state=self.state,
                    goals=self.goals,
                    needs_input=True
                )
    
    def _handle_plan_feedback(self, feedback: str) -> GoalStateResult:
        """Handle user feedback and regenerate plan."""
        try:
            # Add new feedback to history
            self.feedback_history.append(feedback)
            excel_state = get_compact_excel_yaml(self.explorer)
            
            # Combine original request with all feedback
            enhanced_request = self.original_request or ""
            for idx, fb in enumerate(self.feedback_history, 1):
                enhanced_request += f"\nFeedback {idx}: {fb}"
            
            # Generate new plan with accumulated feedback
            return self._handle_plan_creation(enhanced_request)
            
        except Exception as e:
            return self._handle_error(str(e))
    
    def _handle_error(self, error_msg: str) -> GoalStateResult:
        """Handle errors by transitioning to failed state."""
        self.state = GoalState.FAILED
        self.error = error_msg
        return GoalStateResult(
            new_state=self.state,
            goals=self.goals,
            error=error_msg
        )
    
    def get_current_state(self) -> GoalState:
        """Get the current state of the machine."""
        return self.state
    
    def get_goals(self) -> List[Goal]:
        """Get the current list of goals."""
        return self.goals
    
    def get_error(self) -> Optional[str]:
        """Get the current error message if any."""
        return self.error
