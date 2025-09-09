extends Node3D
class_name ElevatorController

@onready var elevator_area: Area3D = $ElevatorArea
@onready var door_proximity_area: Area3D = $DoorProximityArea
@onready var door_left: MeshInstance3D = $ElevatorDoors/DoorLeft
@onready var door_right: MeshInstance3D = $ElevatorDoors/DoorRight
@onready var elevator_platform: StaticBody3D = $ElevatorPlatform
@onready var elevator_sound: AudioStreamPlayer3D = $ElevatorSounds
@onready var door_sound: AudioStreamPlayer3D = $DoorSounds
@onready var transition_overlay: ColorRect = $TransitionUI/TransitionOverlay

var player_ref: CharacterBody3D
var is_transitioning: bool = false
var doors_open: bool = false
var player_near_doors: bool = false
var player_inside_elevator: bool = false

var door_open_position_left: Vector3
var door_open_position_right: Vector3
var door_closed_position_left: Vector3
var door_closed_position_right: Vector3

# Camera persistence for smooth transitions
var saved_camera_rotation: Vector3
var saved_head_rotation: Vector3

signal transition_complete()

func _ready() -> void:
	_setup_elevator()
	_connect_signals()

func _setup_elevator() -> void:
	# Store door positions for animation
	if door_left and door_right:
		door_closed_position_left = door_left.position
		door_closed_position_right = door_right.position
		# Calculate open positions (doors slide apart horizontally)
		door_open_position_left = door_closed_position_left + Vector3(-1.2, 0, 0)
		door_open_position_right = door_closed_position_right + Vector3(1.2, 0, 0)
	
	# Setup transition overlay
	if transition_overlay:
		transition_overlay.color = Color.BLACK
		transition_overlay.modulate.a = 0.0
		transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _connect_signals() -> void:
	if elevator_area:
		elevator_area.body_entered.connect(_on_player_entered_elevator)
		elevator_area.body_exited.connect(_on_player_exited_elevator)
	
	if door_proximity_area:
		door_proximity_area.body_entered.connect(_on_player_near_doors)
		door_proximity_area.body_exited.connect(_on_player_left_doors)

func _on_player_near_doors(body: Node3D) -> void:
	if body.is_in_group("player") and not is_transitioning:
		player_near_doors = true
		player_ref = body as CharacterBody3D
		print("Player near elevator doors - opening doors")
		if not doors_open:
			_open_doors()

func _on_player_left_doors(body: Node3D) -> void:
	if body.is_in_group("player") and not player_inside_elevator:
		player_near_doors = false
		print("Player left door area - closing doors")
		if doors_open and not is_transitioning:
			_close_doors()

func _on_player_entered_elevator(body: Node3D) -> void:
	if body.is_in_group("player") and not is_transitioning:
		player_inside_elevator = true
		player_ref = body as CharacterBody3D
		print("Player entered elevator - starting transition sequence")
		await get_tree().create_timer(1.0).timeout  # Small delay before starting
		if player_inside_elevator:  # Check if player is still inside
			start_elevator_transition()

func _on_player_exited_elevator(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside_elevator = false
		print("Player exited elevator")

func _open_doors() -> void:
	if doors_open or is_transitioning:
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
func start_elevator_transition() -> void:
	if is_transitioning:
		return
	
	is_transitioning = true
	print("Starting elevator transition sequence...")
	
	# Save camera rotation for smooth transition
	_save_camera_state()
	
	# DON'T disable player movement - let them walk freely
	# Player can walk around in the elevator during descent
	
	# Ensure doors are closed before transition
	if doors_open:
		await _close_doors()
	
	# Start the elevator sequence (20 meters down)
	await _elevator_movement_sequence()
	
	# After 20 meters, start loading overlay and transition
	await _show_loading_overlay()
	
	# Change to level_0 scene while overlay is visible
	_change_to_level_0()

func _save_camera_state() -> void:
	if player_ref:
		# Get the head node and camera
		var head = player_ref.get_node_or_null("Head")
		var camera = player_ref.get_node_or_null("Head/Camera3D")
		
		if head and camera:
			saved_head_rotation = head.rotation
			saved_camera_rotation = camera.rotation
			
			# Store in Global for persistence across scenes
			Global.saved_head_rotation = saved_head_rotation
			Global.saved_camera_rotation = saved_camera_rotation
			print("Camera state saved: Head=", saved_head_rotation, " Camera=", saved_camera_rotation)

func _elevator_movement_sequence() -> void:
	print("Starting elevator movement...")
	
	# Play elevator sound
	if elevator_sound:
		elevator_sound.play()
	
	# Create smooth downward movement over 8 seconds (longer for 20 meters)
	var movement_distance = 20.0  # Move down 20 meters as requested
	var movement_duration = 8.0   # Longer duration for more realistic feel
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	# Move the entire elevator down smoothly
	tween.tween_property(self, "global_position", 
		global_position + Vector3(0, -movement_distance, 0), movement_duration)
	
	await tween.finished
	
	print("Elevator movement complete - descended 20 meters")

func _show_loading_overlay() -> void:
	print("Showing loading overlay...")
	
	if transition_overlay:
		# Make sure overlay covers the entire screen and is completely black
		transition_overlay.color = Color.BLACK
		transition_overlay.anchors_preset = Control.PRESET_FULL_RECT
		transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Fade to complete black instantly
		var tween = create_tween()
		tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.5)
		await tween.finished
		
		# Keep the overlay black for loading duration
		# This overlay will persist during scene transition
		await get_tree().create_timer(2.0).timeout
	
	print("Loading overlay complete - scene will change now")

func _fade_to_black() -> void:
	print("Fading to black...")
	
	if transition_overlay:
		var tween = create_tween()
		tween.tween_property(transition_overlay, "modulate:a", 1.0, 1.0)
		await tween.finished
	
	print("Fade complete")

func _change_to_level_0() -> void:
	print("Changing to level_0 scene...")
	
	# Clean up global states
	Global.in_presentation = false
	Global.coming_from_elevator = true  # Flag for level_0 to know we're arriving
	
	# Change scene
	get_tree().change_scene_to_file("res://scenes/level_0.tscn")

# Method to open doors (for when elevator arrives at destination)
func open_doors() -> void:
	print("Opening elevator doors...")
	
	# Play door sound
	if door_sound:
		door_sound.play()
	
	# Animate doors opening
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	if door_left:
		tween.tween_property(door_left, "position", door_open_position_left, 1.5)
	if door_right:
		tween.tween_property(door_right, "position", door_open_position_right, 1.5)
	
	await tween.finished
	doors_open = true
	print("Doors opened")

# Method to be called when transitioning TO this scene (arriving)
func arrive_from_presentation() -> void:
	print("Arriving from presentation scene...")
	
	# Start with doors closed
	doors_open = false
	if door_left:
		door_left.position = door_closed_position_left
	if door_right:
		door_right.position = door_closed_position_right
	
	# Fade in from black
	if transition_overlay:
		transition_overlay.modulate.a = 1.0
		var tween = create_tween()
		tween.tween_property(transition_overlay, "modulate:a", 0.0, 1.0)
		await tween.finished
	
	# Wait a moment, then open doors
	await get_tree().create_timer(1.0).timeout
	await open_doors()
	
	# Player movement remains enabled throughout
	# No need to re-enable since we never disabled it
	
	# Restore camera state if available
	_restore_camera_state()
	
	transition_complete.emit()

func _restore_camera_state() -> void:
	# Get the player in the new scene
	await get_tree().process_frame  # Wait a frame to ensure scene is loaded
	var player = get_tree().get_first_node_in_group("player")
	
	if player and Global.has_method("get") and Global.get("saved_head_rotation") != null:
		var head = player.get_node_or_null("Head")
		var camera = player.get_node_or_null("Head/Camera3D")
		
		if head and camera:
			head.rotation = Global.saved_head_rotation
			camera.rotation = Global.saved_camera_rotation
			print("Camera state restored: Head=", Global.saved_head_rotation, " Camera=", Global.saved_camera_rotation)
			
			# Clear the saved state
			Global.saved_head_rotation = Vector3.ZERO
			Global.saved_camera_rotation = Vector3.ZERO

# Helper method to play elevator sound (can be called from other scripts)
func play_elevator_sound() -> void:
	if elevator_sound:
		elevator_sound.play()
		print("Playing elevator sound")
