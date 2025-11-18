"""
Enhanced Tkinter UI for Excel LLM automation.
Displays goals, tasks, and handles user interaction.
"""

import tkinter as tk
from tkinter import ttk, messagebox
from typing import List, Optional, Callable, Dict
from threading import Lock, Thread
import time
from datetime import datetime

from ..models.goal import Goal, Step, GoalStatus, StepStatus

class AutomationUI:
    """Enhanced Tkinter UI for Excel automation."""
    
    def __init__(self):
        # Create the window
        self.root = tk.Tk()
        self.root.title("Excel LLM Assistant")
        
        # Store historical tasks
        self.historical_tasks = []
        
        # Make window stay on top
        self.root.attributes('-topmost', True)
        
        # Set window size and position (right side of screen)
        width = 500
        height = 800
        screen_width = self.root.winfo_screenwidth()
        screen_height = self.root.winfo_screenheight()
        x = screen_width - width - 20
        y = (screen_height - height) // 2
        self.root.geometry(f"{width}x{height}+{x}+{y}")
        
        # Thread safety
        self.lock = Lock()
        self.thread_lock = Lock()
        self.active_thread = None
        
        self._setup_ui()
        
        # Update GUI periodically
        self.root.after(100, self._process_events)
    
    def _setup_ui(self):
        """Set up the UI components."""
        # Main container with padding
        self.main_frame = ttk.Frame(self.root, padding="10")
        self.main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Goals section
        self._setup_goals_section()
        
        # Current task section
        self._setup_task_section()
        
        # Output log section
        self._setup_log_section()
        
        # Input section
        self._setup_input_section()
    
    def _setup_goals_section(self):
        """Set up the goals display section."""
        goals_frame = ttk.LabelFrame(self.main_frame, text="Goals", padding="5")
        goals_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.goals_text = tk.Text(goals_frame, wrap=tk.WORD, height=8)
        self.goals_text.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        goals_scrollbar = ttk.Scrollbar(goals_frame, command=self.goals_text.yview)
        goals_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.goals_text.config(yscrollcommand=goals_scrollbar.set)
    
    def _setup_task_section(self):
        """Set up the current task display section."""
        task_frame = ttk.LabelFrame(self.main_frame, text="Task List", padding="5")
        task_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.task_text = tk.Text(task_frame, wrap=tk.WORD, height=10)
        self.task_text.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        task_scrollbar = ttk.Scrollbar(task_frame, command=self.task_text.yview)
        task_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.task_text.config(yscrollcommand=task_scrollbar.set)
    
    def _setup_log_section(self):
        """Set up the output log section."""
        log_frame = ttk.LabelFrame(self.main_frame, text="Output Log", padding="5")
        log_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 10))
        
        self.log_text = tk.Text(log_frame, wrap=tk.WORD)
        self.log_text.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        log_scrollbar = ttk.Scrollbar(log_frame, command=self.log_text.yview)
        log_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.log_text.config(yscrollcommand=log_scrollbar.set)
    
    def _setup_input_section(self):
        """Set up the input section."""
        input_frame = ttk.Frame(self.main_frame)
        input_frame.pack(fill=tk.X)
        
        self.input_entry = ttk.Entry(input_frame)
        self.input_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        submit_button = ttk.Button(
            input_frame,
            text="Submit",
            command=self._handle_input
        )
        submit_button.pack(side=tk.RIGHT, padx=(5, 0))
        
        # Bind Enter key to submit
        self.input_entry.bind('<Return>', lambda e: self._handle_input())
    
    def _process_events(self):
        """Process GUI events to keep window responsive."""
        try:
            self.root.update()
            self.root.after(50, self._process_events)
        except tk.TclError:
            # Window was closed
            pass
    
    def _handle_input(self):
        """Handle user input submission."""
        text = self.input_entry.get().strip()
        if text and self.input_callback:
            with self.thread_lock:
                if self.active_thread and self.active_thread.is_alive():
                    self.log_message("Please wait for current operation to complete", "warning")
                    return
                
                # Start new thread
                self.active_thread = Thread(target=self._run_callback, args=(text,))
                self.active_thread.start()
        
        self.input_entry.delete(0, tk.END)
    
    def _run_callback(self, text: str):
        """Run callback in thread with cleanup."""
        try:
            self.input_callback(text)
        except Exception as e:
            self.log_message(f"Error in operation: {str(e)}", "error")
        finally:
            # Clear active thread when done
            with self.thread_lock:
                self.active_thread = None
    
    def _format_goal_status(self, status: GoalStatus) -> str:
        """Format goal status for display."""
        status_symbols = {
            GoalStatus.PENDING: "⭕",
            GoalStatus.IN_PROGRESS: "🔄",
            GoalStatus.COMPLETED: "✅",
            GoalStatus.FAILED: "❌",
            GoalStatus.NEEDS_REVIEW: "❓"
        }
        return status_symbols.get(status, "⚪")
    
    def _format_step_status(self, status: StepStatus) -> str:
        """Format step status for display."""
        status_symbols = {
            StepStatus.PENDING: "⭕",
            StepStatus.IN_PROGRESS: "🔄",
            StepStatus.COMPLETED: "✅",
            StepStatus.FAILED: "❌",
            StepStatus.VALIDATION_FAILED: "⚠️"
        }
        return status_symbols.get(status, "⚪")
    
    def update_goals(self, goals: List[Goal]):
        """Update the goals display."""
        try:
            with self.lock:
                self.goals_text.delete(1.0, tk.END)
                for goal in goals:
                    status = self._format_goal_status(goal.status)
                    progress = f"{goal.get_progress():.1f}%"
                    self.goals_text.insert(tk.END, 
                        f"{status} [{progress}] {goal.description}\n")
                    if goal.error_message:
                        self.goals_text.insert(tk.END,
                            f"   ⚠️ {goal.error_message}\n")
        except tk.TclError:
            # Window was closed
            pass
    
    def update_tasks(self, goal: Optional[Goal], steps: List[Step], current_step: Optional[Step] = None):
        """Update the task list display."""
        try:
            with self.lock:
                # Update display
                self.task_text.delete(1.0, tk.END)
                
                # Display goal and steps
                if goal:
                    self.task_text.insert(tk.END, f"Goal: {goal.description}\n")
                    self.task_text.insert(tk.END, "Steps:\n")

                    # Find current step index
                    current_step_index = -1
                    if current_step:
                        for i, step in enumerate(steps):
                            if step == current_step:
                                current_step_index = i
                                break

                    # Display all steps with appropriate status
                    for i, step in enumerate(steps):
                        if i < current_step_index:
                            # Steps before current are completed
                            status = self._format_step_status(StepStatus.COMPLETED)
                        elif i == current_step_index:
                            # Current step keeps its actual status (In Progress or Failed)
                            status = self._format_step_status(step.status)
                        else:
                            # Steps after current are pending
                            status = self._format_step_status(StepStatus.PENDING)
                            
                        self.task_text.insert(tk.END, f"{status} {step.description}\n")
                        if step.error_message and i == current_step_index:
                            self.task_text.insert(tk.END, f"⚠️ {step.error_message}\n")
        except tk.TclError:
            # Window was closed
            pass
    
    def log_message(self, message: str, level: str = "info"):
        """Add a message to the output log."""
        try:
            with self.lock:
                timestamp = time.strftime("%I:%M:%S %p")
                level_symbols = {
                    "info": "ℹ️",
                    "success": "✅",
                    "warning": "⚠️",
                    "error": "❌"
                }
                symbol = level_symbols.get(level, "•")
                
                self.log_text.insert(tk.END,
                    f"{timestamp} {symbol} {message}\n")
                self.log_text.see(tk.END)
        except tk.TclError:
            # Window was closed
            pass
    
    def set_input_callback(self, callback: Callable[[str], None]):
        """Set the callback for handling user input."""
        self.input_callback = callback
    
    def run(self):
        """Start the UI."""
        self.root.mainloop()
    
    def ask_yes_no(self, question: str) -> bool:
        """Display a yes/no dialog and return the user's choice."""
        try:
            with self.lock:
                result = messagebox.askyesno("Question", question)
                return result
        except tk.TclError:
            # Window was closed
            return False

    def cleanup(self):
        """Clean up resources."""
        try:
            self.root.destroy()
        except tk.TclError:
            # Window was already closed
            pass
