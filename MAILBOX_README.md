# Mailbox System

This mailbox system allows players to interact with a mailbox to retrieve mail with a realistic paper sliding animation and A4-sized UI display.

## Files Created

1. **scripts/mailbox.gd** - Main mailbox script that handles interaction and animation
2. **scripts/mail_ui.gd** - UI script for displaying mail content (A4 proportions)
3. **scenes/mailbox_demo.tscn** - Simple mailbox scene (component)
4. **scenes/mailbox_complete_demo.tscn** - Complete demo scene with player and environment

## How It Works

### Player Interaction
- The player script (`player.gd`) has been updated to detect mailbox interactions
- When the player looks at the mailbox, the interaction cursor appears
- Left-clicking on the mailbox triggers the `take_mail()` function

### Mailbox Functionality
- **has_mail**: Boolean that tracks if the mailbox contains mail
- **mail_was_taken**: Prevents re-access after mail is taken (one-time only)
- **take_mail()**: Main interaction function that:
  - Checks if mail is available and not already taken
  - Animates paper sliding out of the mailbox (1.5 second tween)
  - Displays the A4-sized mail UI
  - Marks mail as permanently taken
- **_animate_paper_slide_out()**: Creates realistic paper extraction animation
- **refill_mail()**: Testing function to reset the mailbox completely

### Mail UI
- Displays as an A4-proportioned paper overlay (594×840 pixels)
- Does NOT unlock mouse cursor (stays captured)
- Pauses the game while reading
- Can be closed by:
  - **Left-clicking anywhere**
  - **Pressing Escape**
- No close button - cleaner interface

### Animation Details
- Paper starts inside mailbox (position: 0, -0.4, 0.1)
- Slides out smoothly to (position: 0, -0.2, 0.5)
- Includes subtle rotation for realism
- Paper disappears when UI shows
- 1.5-second animation + 0.5-second delay

## Usage

1. **Load the complete demo scene**: `scenes/mailbox_complete_demo.tscn`
2. **Play the scene** and walk up to the blue mailbox
3. **Look at the mailbox** - crosshair will indicate interaction is possible
4. **Left-click** to take the mail and watch the paper slide out
5. **Read the mail** in the A4-sized display
6. **Click anywhere or press Escape** to close
7. **Try interacting again** - mail is now permanently taken

## Key Features

- ✅ **Realistic paper sliding animation** with rotation
- ✅ **A4-proportioned UI** (594×840 pixels)
- ✅ **One-time interaction** - prevents re-access
- ✅ **Mouse stays captured** - no cursor unlock
- ✅ **Click or Escape to exit** - no close button
- ✅ **Game pauses while reading**
- ✅ **Integrated with player interaction system**

## Customization

### Changing Mail Content
Edit the mail text in `scripts/mail_ui.gd` in the `show_mail()` function.

### Adjusting Animation
Modify the `_animate_paper_slide_out()` function in `mailbox.gd`:
- Change duration (currently 1.5 seconds)
- Adjust start/end positions
- Modify rotation angles

### UI Sizing
The current A4 proportions are 594×840 pixels. To change:
- Update `offset_left/right/top/bottom` in the scene
- Maintain the 1:√2 ratio for true A4 proportions

## Integration

To add this mailbox system to existing scenes:
1. Instance the mailbox scene in your level
2. Ensure the player script includes the mailbox interaction code
3. Position the mailbox where appropriate in your game world

The system is fully integrated with the existing player interaction system and follows the same patterns used for other interactive objects in the game.
