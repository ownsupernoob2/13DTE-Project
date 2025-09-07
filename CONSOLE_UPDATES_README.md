# Console.gd Updates - Green Theme & Exit Instructions

## Changes Made

### 1. Exit Instructions (One-time Display)
- Added `_exit_instruction_shown` flag to track if instruction has been displayed
- Modified `_show_startup_commands()` to display "Click or press ESC to exit the computer" only once when opening the computer
- Exit instruction appears in bright lime green color at the top of the console

### 2. Exit Functionality 
- **Escape Key**: Modified escape key handling to exit computer mode when not in table mode
- **Mouse Click**: Added `_input()` function to handle left mouse button clicks for exiting computer mode
- Both methods call `player.exit_computer_mode()` to properly close the computer interface

### 3. Green Color Scheme
Converted all console colors to various green shades:

#### Color Mapping:
- **LIME_GREEN**: Primary headers, borders, command text in help
- **GREEN**: Section headers, warnings, informational text
- **DARK_GREEN**: Error messages, secondary informational text
- **FOREST_GREEN**: Used in edit mode prefix
- **BLACK**: Text color for cursor highlighting (unchanged)

#### Key Areas Updated:
- Startup commands and terminal header
- Help command reference
- Error messages (RED → DARK_GREEN)
- Warning messages (YELLOW → GREEN)
- Info headers (CYAN → LIME_GREEN)
- Command text (WHITE → LIME_GREEN)
- File listings and disk information
- Table headers and borders
- Prefix colors for user prompt

### 4. Prefix Theme Update
- User prefix background: DODGER_BLUE → GREEN
- Path background: WEB_GRAY → DARK_GREEN
- Edit mode background: BURLYWOOD → FOREST_GREEN
- All prefix accent colors updated to green variants

### 5. Cursor Colors
- Success cursor: LIME_GREEN → GREEN
- Error cursor: CRIMSON → DARK_GREEN
- Default cursor: WHITE → LIME_GREEN

## Technical Implementation

### New Variables:
```gdscript
var _exit_instruction_shown: bool = false
```

### New Functions:
```gdscript
func _input(event: InputEvent) -> void:
    # Handles mouse clicks for computer exit
```

### Modified Functions:
- `_show_startup_commands()`: Added exit instruction display logic
- `_unhandled_key_input()`: Enhanced escape key handling
- `set_prefix()`: Updated color scheme
- `append_current_input_string()`: Updated cursor colors

## Testing Notes

- All script syntax validated - no errors found
- Exit instruction appears only once per computer session
- Both escape key and mouse click properly exit computer mode
- Green color theme applied consistently throughout the interface
- Maintains all existing functionality while improving visual consistency

## Usage

1. **Opening Computer**: Exit instruction displays at top of console in lime green
2. **Exiting Computer**: Press ESC key or click anywhere in the console area
3. **Color Theme**: All text now uses green color variants for better visual coherence
4. **One-time Instructions**: Exit instructions won't repeat until computer is reopened

The console now provides a consistent green-themed interface with clear, one-time exit instructions that enhance user experience without being intrusive.
