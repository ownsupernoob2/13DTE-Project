# Gemini Project Context: 13DTE-Project

## Project Overview

This project is a first-person horror puzzle/simulation game developed with the Godot Engine (v4.4). The player takes on the role of a technician in an alien containment facility, tasked with analyzing and classifying alien specimens.

The core gameplay revolves around several interconnected systems:
*   **Computer & Disk System:** The player interacts with a terminal to read files from different floppy disks. These files progressively reveal a dark narrative about unethical experiments and a cover-up.
*   **Lever System:** A physical interface for mixing fluids to sedate the alien subjects.
*   **Medical Scanner:** A mini-game to determine the biological traits (eye color, blood type) of sedated aliens.
*   **Monitor System:** Used to finally classify the aliens as "accept" or "reject" based on the gathered data.

The game is structured in 5 stages of increasing difficulty, from a tutorial to a hard mode with added mechanics like pod integrity failure.

**Key Technologies:**
*   **Engine:** Godot 4.4
*   **Language:** GDScript (`.gd`)
*   **Scenes:** Godot's scene format (`.tscn`)
*   **Assets:** 3D models (`.glb`), textures (`.png`, `.jpg`), and shaders (`.gdshader`).

**Architecture:**
The project uses several singleton nodes (AutoLoads) for managing global state, including `Global`, `DiskManager`, `GameManager`, and `SaveSystem`. This provides a centralized way to handle game progression, disk data, and player state.

## Building and Running

This is a Godot project. To run it, you need the Godot Engine (version 4.4 or compatible).

1.  **Open the project:**
    *   Open the Godot Engine editor.
    *   Click "Import" or "Scan" and select the `D:\13DTE-Project` folder.
2.  **Run the game:**
    *   Once the project is open in the editor, press the "Play" button (or `F5`).

The main scene is `res://scenes/main_menu_new.tscn`.

The `.vscode/tasks.json` file also contains a task to run Godot from within Visual Studio Code.

## Development Conventions

*   **Scripting:** GDScript is used for all game logic. Scripts are generally attached to the nodes they control.
*   **Scene Structure:** Scenes are well-organized, with descriptive names for nodes. The main game logic appears to be in `scenes/demo.tscn`, which instances other components like the player, computer, and various machines.
*   **Asset Management:** Assets are organized into subdirectories within the `assets` folder (e.g., `bunker`, `disks`, `materials`, `tech`).
*   **Singletons:** Global state is managed through autoloaded singletons (`GameManager`, `DiskManager`, etc.), which is a common Godot pattern.
*   **Naming:** Scripts and scenes use `snake_case`. Nodes within scenes also appear to follow this convention.

## Important Rules
- **Do not modify `*.tscn` files directly.** These files define the scene structure and are best edited through the Godot editor. If a change to a scene file is needed, please describe the required change so I can perform it.
