"""
Goal and Step models for Excel LLM automation.
"""

from enum import Enum
from typing import List, Dict, Optional, Any
from dataclasses import dataclass, field
from datetime import datetime

class GoalStatus(Enum):
    """Status states for a goal."""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    NEEDS_REVIEW = "needs_review"

class StepStatus(Enum):
    """Status states for an individual step."""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    VALIDATION_FAILED = "validation_failed"

@dataclass
class Step:
    """Represents a single executable step within a goal."""
    description: str
    action: str  # The actual command to execute (e.g., move_to_element, type_text)
    parameters: Dict[str, Any]
    status: StepStatus = StepStatus.PENDING
    validation_criteria: Optional[Dict[str, Any]] = None
    error_message: Optional[str] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    element_keywords: Optional[List[str]] = None  # Optional list of keywords from element attributes for identification
    
    def start(self) -> None:
        """Mark the step as started."""
        self.status = StepStatus.IN_PROGRESS
        self.started_at = datetime.now()
    
    def complete(self) -> None:
        """Mark the step as completed."""
        self.status = StepStatus.COMPLETED
        self.completed_at = datetime.now()
    
    def fail(self, error_message: str) -> None:
        """Mark the step as failed with an error message."""
        self.status = StepStatus.FAILED
        self.error_message = error_message
        self.completed_at = datetime.now()
    
    def validation_failed(self, error_message: str) -> None:
        """Mark the step as failed validation with an error message."""
        self.status = StepStatus.VALIDATION_FAILED
        self.error_message = error_message
        self.completed_at = datetime.now()

@dataclass
class Goal:
    """Represents a high-level goal in the Excel automation process."""
    id: str
    description: str
    steps: List[Step] = field(default_factory=list)
    status: GoalStatus = GoalStatus.PENDING
    validation_criteria: Optional[Dict[str, Any]] = None
    error_message: Optional[str] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    dependencies: List[str] = field(default_factory=list)  # List of goal IDs that must be completed first
    
    def start(self) -> None:
        """Mark the goal as started."""
        self.status = GoalStatus.IN_PROGRESS
        self.started_at = datetime.now()
    
    def complete(self) -> None:
        """Mark the goal as completed."""
        self.status = GoalStatus.COMPLETED
        self.completed_at = datetime.now()
    
    def fail(self, error_message: str) -> None:
        """Mark the goal as failed with an error message."""
        self.status = GoalStatus.FAILED
        self.error_message = error_message
        self.completed_at = datetime.now()
    
    def needs_review(self, message: str) -> None:
        """Mark the goal as needing review with a message."""
        self.status = GoalStatus.NEEDS_REVIEW
        self.error_message = message
    
    def add_step(self, step: Step) -> None:
        """Add a step to the goal."""
        self.steps.append(step)
    
    def get_next_pending_step(self) -> Optional[Step]:
        """Get the next pending step in this goal."""
        for step in self.steps:
            if step.status == StepStatus.PENDING:
                return step
        return None
    
    def all_steps_completed(self) -> bool:
        """Check if all steps in this goal are completed."""
        return all(step.status == StepStatus.COMPLETED for step in self.steps)
    
    def any_steps_failed(self) -> bool:
        """Check if any steps in this goal have failed."""
        return any(step.status in [StepStatus.FAILED, StepStatus.VALIDATION_FAILED] 
                  for step in self.steps)
    
    def get_progress(self) -> float:
        """Get the progress of this goal as a percentage."""
        if not self.steps:
            return 0.0
        completed = sum(1 for step in self.steps 
                       if step.status == StepStatus.COMPLETED)
        return (completed / len(self.steps)) * 100
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert the goal to a dictionary representation."""
        return {
            "id": self.id,
            "description": self.description,
            "status": self.status.value,
            "progress": self.get_progress(),
            "error_message": self.error_message,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "steps": [
                {
                    "description": step.description,
                    "status": step.status.value,
                    "error_message": step.error_message,
                    "started_at": step.started_at.isoformat() if step.started_at else None,
                    "completed_at": step.completed_at.isoformat() if step.completed_at else None,
                    "element_keywords": step.element_keywords
                }
                for step in self.steps
            ],
            "dependencies": self.dependencies
        }
