# Excel LLM Assistant

An intelligent Excel automation assistant that uses natural language processing and accessibility APIs to control Excel based on user commands.

## Architecture

The system uses a state-based architecture with distinct processing stages:

1. **High-Level Planning**
   - Generates a high-level list of goals based on the user's request
   - Each goal is independently verifiable and has clear validation criteria
   - Goals can have dependencies on other goals
   - Users can provide feedback to refine the plan

2. **Goal Execution Planning**
   - Each goal is broken down into concrete, executable steps
   - Steps are planned using current Excel state and completed goals as context
   - Includes validation criteria for each step
   - Supports recovery steps for handling failures

3. **Step Execution**
   - Executes individual steps with proper validation
   - Verifies Excel state after each step
   - Handles failures and attempts recovery
   - Ensures Excel is in foreground before actions

## Components

### Models
- `Goal`: Represents a high-level goal with steps and validation criteria
- `Step`: Represents a single executable action with parameters
- `GoalStatus`: Tracks goal states (pending, in_progress, completed, etc.)
- `StepStatus`: Tracks step states (pending, in_progress, completed, etc.)

### States
- `HighLevelPlanner`: Generates and manages high-level goal plans
- `GoalExecutor`: Breaks down goals into executable steps
- `StepExecutor`: Handles actual execution of steps

### UI
- `AutomationUI`: Enhanced Tkinter interface showing:
  - Current goals and their status
  - Active task and step details
  - Output log
  - User input prompt

## Usage

1. Install dependencies:
```bash
poetry install
```

2. Run the assistant:
```bash
python -m examples.excel_llm --api-key YOUR_OPENAI_API_KEY
```

Optional flags:
- `--debug`: Enable debug mode (saves state information)

3. Enter your request when prompted. For example:
```
> Create a sales report with monthly totals in columns A through C
```

4. The system will:
   - Generate a plan with specific goals
   - Break down each goal into steps
   - Execute steps with validation
   - Ask for confirmation when needed

5. Type 'quit' to exit.

## Available Actions

The system can perform these Excel actions:
- Moving to specific cells/elements
- Clicking (left, right, double)
- Typing text and formulas
- Using keyboard shortcuts
- Scrolling
- Dragging (e.g., for fill handles)

## Error Handling

The system includes robust error handling:
- Step validation after execution
- Automatic recovery attempts
- Debug information saving
- User confirmation for uncertain states

## Requirements

- Python 3.8+
- OpenAI API key
- Microsoft Excel
- tkinter (for GUI)
- macOS (for accessibility features)

## Development

To extend the system:

1. Add new actions in `step_executor.py`
2. Update validation logic in `goal_executor.py`
3. Enhance planning capabilities in `high_level_planner.py`
4. Add UI features in `tkinter_window.py`

## Debug Mode

When running with `--debug`, the system saves:
- Excel window state (YAML)
- Goal and step information
- Error details
- Recovery attempts

Debug files are saved in the `debug/` directory with timestamps.
