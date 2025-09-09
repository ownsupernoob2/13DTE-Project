extends Node3D
class_name NewElevatorController

@onready var elevator_area: Area3D = $ElevatorArea
@onready var door_proximity_area: Area3D = $DoorProximityArea
@onready var door_left: MeshInstance3D = $ElevatorDoors/DoorLeft
@onready var door_right: MeshInstance3D = $ElevatorDoors/DoorRight
@onready var elevator_platform: StaticBody3D = $ElevatorPlatform
@onready var elevator_sound: AudioStreamPlayer3D = $ElevatorSounds
@onready var door_sound: AudioStreamPlayer3D = $DoorSounds
@onready var shake_timer: Timer = $ShakeTimer

var player_ref: CharacterBody3D
var is_moving: bool = false
var doors_open: bool = false
var player_near_doors: bool = false
var player_inside_elevator: bool = false

var door_open_position_left: Vector3
var door_open_position_right: Vector3
var door_closed_position_left: Vector3
var door_closed_position_right: Vector3

# Physical movement properties
var target_position: Vector3
var start_position: Vector3
var movement_duration: float = 8.0  # How long the elevator takes to move down
var movement_distance: float = 15.0  # How far down to move

signal movement_complete()

func _ready() -> void:
	_setup_elevator()
	_connect_signals()

func _setup_elevator() -> void:
	# Store initial positions
	start_position = position
	target_position = start_position + Vector3(0, -movement_distance, 0)
	
	# Store door positions for animation
	if door_left and door_right:
		door_closed_position_left = door_left.position
		door_closed_position_right = door_right.position
		# Calculate open positions (doors slide apart horizontally)
		door_open_position_left = door_closed_position_left + Vector3(-1.2, 0, 0)
		door_open_position_right = door_closed_position_right + Vector3(1.2, 0, 0)
	
	# Setup shake timer
	if shake_timer:
		shake_timer.wait_time = 0.1
		shake_timer.timeout.connect(_apply_shake)

func _connect_signals() -> void:
	if elevator_area:
		elevator_area.body_entered.connect(_on_player_entered_elevator)
		elevator_area.body_exited.connect(_on_player_exited_elevator)
	
	if door_proximity_area:
		door_proximity_area.body_entered.connect(_on_player_near_doors)
		door_proximity_area.body_exited.connect(_on_player_left_doors)

func _on_player_near_doors(body: Node3D) -> void:
	if body.is_in_group("player") and not is_moving:
		player_near_doors = true
		player_ref = body as CharacterBody3D
		print("Player near elevator doors - opening doors")
		if not doors_open:
			_open_doors()

func _on_player_left_doors(body: Node3D) -> void:
	if body.is_in_group("player") and not player_inside_elevator:
		player_near_doors = false
		print("Player left door area - closing doors")
		if doors_open and not is_moving:
			_close_doors()

func _on_player_entered_elevator(body: Node3D) -> void:
	if body.is_in_group("player") and not is_moving:
		player_inside_elevator = true
		player_ref = body as CharacterBody3D
		print("Player entered elevator - starting movement sequence")
		await get_tree().create_timer(1.0).timeout  # Small delay before starting
		if player_inside_elevator:  # Check if player is still inside
			start_elevator_movement()

func _on_player_exited_elevator(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside_elevator = false
		print("Player exited elevator")

func _open_doors() -> void:
	if doors_open or is_moving:
		return
		
	print("Opening elevator doors...")
	doors_open = true
	
	# Play door sound
	if door_sound:
		door_sound.play()
	
	# Animate doors opening with smooth easing
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	if door_left:
		tween.tween_property(door_left, "position", door_open_position_left, 1.0)
	if door_right:
		tween.tween_property(door_right, "position", door_open_position_right, 1.0)
	
	await tween.finished
	print("Doors opened")

func _close_doors() -> void:
	if not doors_open:
		return
		
	print("Closing elevator doors...")
	doors_open = false
	
	# Play door sound
	if door_sound:
		door_sound.play()
	
	# Animate doors closing with smooth easing
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	if door_left:
		tween.tween_property(door_left, "position", door_closed_position_left, 1.0)
	if door_right:
		tween.tween_property(door_right, "position", door_closed_position_right, 1.0)
	
	await tween.finished
	print("Doors closed")

func start_elevator_movement() -> void:
	if is_moving:
		return
	
	is_moving = true
	print("Starting elevator movement sequence...")
	
	# Disable player movement but KEEP camera movement
	if player_ref and player_ref.has_method("set_can_move"):
		player_ref.set_can_move(false)
	
	# Ensure doors are closed before movement
	if doors_open:
		await _close_doors()
	
	# Start the elevator sequence
	await _elevator_movement_sequence()

func _elevator_movement_sequence() -> void:
	print("Starting elevator movement...")
	
	# Play elevator sound
	if elevator_sound:
		elevator_sound.play()
	
	# Start shaking effect
	shake_timer.start()
	
	# Start smooth movement down
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Move the entire elevator (including player) down
	tween.tween_property(self, "position", target_position, movement_duration)
	
	# Wait for movement to complete
	await tween.finished
	
	# Stop shaking and ensure we're at the exact target position
	shake_timer.stop()
	position = target_position
	
	print("Elevator movement complete - opening doors")
	
	# Wait a moment, then open doors
	await get_tree().create_timer(1.0).timeout
	await _open_doors()
	
	# Re-enable player movement
	if player_ref and player_ref.has_method("set_can_move"):
		player_ref.set_can_move(true)
	
	# Reset for potential future use
	is_moving = false
	movement_complete.emit()

func _apply_shake() -> void:
	if is_moving:
		# Apply random small shake
		var shake_strength = 0.05
		var shake_offset = Vector3(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		position += shake_offset

# Reset elevator to starting position (for testing/debugging)
func reset_elevator() -> void:
	if is_moving:
		return
	
	position = start_position
	is_moving = false
	doors_open = false
	player_inside_elevator = false
	player_near_doors = false
	
	# Reset door positions
	if door_left and door_right:
		door_left.position = door_closed_position_left
		door_right.position = door_closed_position_right
	
	print("Elevator reset to starting position")
