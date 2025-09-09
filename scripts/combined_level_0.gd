extends Node3D

# This script manages the combined presentation/level_0 scene
# The elevator starts in the presentation area and moves down to the tutorial area

@onready var elevator: Node3D = $Elevator
@onready var player: CharacterBody3D = $Player

# Tutorial area components (positioned lower in the scene)
@onready var tutorial_area: Node3D = $TutorialArea

func _ready() -> void:
	print("Combined Level 0 scene loaded")
	
	# Connect elevator signals
	if elevator:
		elevator.movement_complete.connect(_on_elevator_arrived)
	
	# Ensure player starts in the right position
	_setup_initial_positions()

func _setup_initial_positions() -> void:
	# Player should start in the presentation area (higher up)
	if player:
		player.position = Vector3(0, 10, 0)  # Adjust as needed
	
	# Tutorial area should be positioned below
	if tutorial_area:
		tutorial_area.position = Vector3(0, -15, 0)  # 15 units below

func _on_elevator_arrived() -> void:
	print("Elevator has arrived at tutorial area")
	# Here you can add any logic that should happen when the elevator reaches the bottom
	# For example, starting tutorial narration, enabling certain objects, etc.
