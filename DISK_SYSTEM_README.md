# Multi-Disk System for Horror Game

This implementation adds support for 4 different disks with unique horror-themed content for your Godot 4.4 horror game.

## Features

- **4 Unique Disks**: Each with different content and horror themes
- **Interactive Terminal**: Console interface for disk management
- **Horror Content**: Each disk contains disturbing files and messages
- **Visual Feedback**: Disk insertion/ejection animations
- **Player Interaction**: Pick up, hold, insert, and eject disks

## Disk Types

### Disk1 - SYSTEM_BOOT
- **Theme**: Corrupted system files
- **Files**: boot.exe, kernel.sys, config.ini, drivers.dat
- **Horror Message**: "SYSTEM CORRUPTED... SOMETHING IS WRONG..."
- **Color**: Green (System)

### Disk2 - DATA_LOG  
- **Theme**: Research experiment logs
- **Files**: experiment_001.log, subject_data.txt, results.csv, anomaly_report.doc
- **Horror Message**: "THE SUBJECTS ARE SCREAMING... THEY WON'T STOP..."
- **Color**: Blue (Data)

### Disk3 - SECURITY_CAM
- **Theme**: Security footage and incident reports
- **Files**: cam01_footage.avi, incident_report.pdf, emergency.wav, breach_log.txt
- **Horror Message**: "THEY'RE IN THE WALLS... WATCHING... ALWAYS WATCHING..."
- **Color**: Yellow (Security)

### Disk4 - CLASSIFIED
- **Theme**: Top secret documents and termination orders
- **Files**: project_omega.doc, classified.txt, termination_order.pdf, witness_list.dat
- **Horror Message**: "YOU SHOULDN'T HAVE SEEN THIS... THEY KNOW YOU'RE HERE..."
- **Color**: Red (Classified)

## How to Use

### Player Controls
1. **Look at a disk** - Cursor changes to indicate interaction
2. **Left-click** - Pick up disk (appears in hand)
3. **Approach computer** - Look at computer screen
4. **Left-click on computer** - Enter computer mode
5. **Insert disk** - Left-click while holding disk near computer
6. **Use terminal** - Type commands in the console

### Console Commands
- `disks` - Show currently inserted disk
- `diskinfo` - Display information about inserted disk
- `ls` - List files on the disk
- `cat [filename]` - Read file contents
- `eject` - Remove the current disk
- `help` - Show all available commands

### File Reading
Each disk contains multiple files with detailed horror content:
- Read files using `cat filename.ext`
- Files contain increasingly disturbing content
- Some files reveal the dark story behind the facility

## Technical Details

### Scripts Modified
- **player.gd** - Enhanced to handle multiple disk types
- **computer.gd** - Added disk management system
- **console.gd** - Extended to support all 4 disk types
- **disk_manager.gd** - New singleton for disk data management

### Scene Changes
- **demo.tscn** - Added Disk2, Disk3, Disk4 objects to the scene
- **player.tscn** - Added held versions for all disk types
- **project.godot** - Added DiskManager to autoload

### Key Features
- **DiskManager Singleton**: Centralized disk data management
- **Horror Content Generation**: Dynamic file content creation
- **Visual Feedback**: Color-coded security levels
- **Immersive Terminal**: Retro computer interface
- **Progressive Horror**: Content gets more disturbing per disk

## Story Integration

The disks tell a connected horror story:
1. **System corruption** hints at something wrong
2. **Research logs** reveal unethical experiments
3. **Security footage** shows paranormal activity  
4. **Classified files** expose the full conspiracy

Players must read files in sequence to understand the complete horror narrative about failed experiments, deceased subjects returning, and a cover-up gone wrong.

## Customization

To add more disks or modify content:
1. Edit `disk_manager.gd` - Add new disk entries
2. Update `_get_[type]_file_content()` functions
3. Add physical disk objects to scene
4. Create held versions in player scene

The system is designed to be easily expandable for additional horror content and disk types.
