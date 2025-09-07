# Level 0 - Tutorial Level

This is the tutorial level (`level_0.tscn`) that teaches players the basic game mechanics through in-universe correspondence and interactions.

## Tutorial Overview

### 🎯 **Learning Objectives:**
1. **Mail System** - How to interact with mailboxes and read correspondence
2. **Mail Controls** - ESC key or mouse click to close mail
3. **Operations Manual** - Introduction to the booklet system (when implemented)
4. **Pod Controls** - Hold the START button to begin specimen analysis

### 📧 **Tutorial Mail Content:**
The mail is written in an in-game style as official correspondence from the "Training Division":

```
TRAINING FACILITY - ORIENTATION BRIEFING

Agent [CLASSIFIED],

You have been assigned to Training Pod Alpha-7 for equipment familiarization.

STANDARD OPERATING PROCEDURES:
• All correspondence must be properly reviewed and filed
• Consult your issued Operations Manual before beginning any procedures  
• Specimen analysis requires sustained activation of the initiation sequence
• Hold the START control until the system confirms activation

Your supervisor will monitor this training session remotely.

Complete all orientation tasks before proceeding to active duty.

Department of Xenobiological Research
Training Division
```

## Scene Structure

### **Key Components Added:**
- **TutorialMailbox** - Blue mailbox positioned near player spawn
- **TutorialMailUI** - A4-sized mail display with tutorial content
- **Mail Paper Animation** - Realistic paper sliding out of mailbox

### **Location:**
- **Player Spawn**: (11.77, 3.40, -1.22)
- **Mailbox Position**: (10.0, 3.6, -1.5) - Right next to player

## Custom Scripts

### 1. **tutorial_mailbox.gd**
- Extends the base mailbox functionality
- Finds the TutorialMailUI specifically
- Same paper sliding animation as base mailbox
- One-time interaction (mail cannot be re-read)

### 2. **tutorial_mail_ui.gd** 
- Tutorial-specific mail content
- Same input handling (ESC/click to close)
- Proper pause handling
- A4-sized display

## Integration with Existing Demo

The tutorial level is based on `demo.tscn` with these additions:
- ✅ **All existing demo content preserved**
- ✅ **Mailbox system added**
- ✅ **Tutorial-specific mail content**
- ✅ **Player interaction system compatible**

## Usage

1. **Load the scene**: `scenes/level_0.tscn`
2. **Player spawns** near the blue mailbox
3. **Look at mailbox** - interaction cursor appears
4. **Left-click** to take mail and see animation
5. **Read the briefing** in A4-sized display
6. **ESC or click** to close and continue

## Tutorial Flow

### **Intended Player Experience:**
1. **Start** → Player sees mailbox immediately
2. **Interact** → Learn mail system controls
3. **Read** → Get in-universe tutorial instructions
4. **Close** → Practice ESC/click controls
5. **Explore** → Find Operations Manual (when implemented)
6. **Use Pod** → Practice holding START button

## Future Enhancements

When the booklet/manual system is implemented:
- Mail references will become functional
- Players can find and read the Operations Manual
- More detailed procedures for specimen analysis

The mail content is designed to remain relevant and in-character even as new systems are added to the game.
