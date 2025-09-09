extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var arrival_elevator: Node3D = $ArrivalElevator

func _ready() -> void:
	print("Level 0 starting...")
	
	# Hide cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Debug info
	print("Player exists: ", player != null)
	print("Arrival elevator exists: ", arrival_elevator != null)
	
	# Check if coming from elevator
	if Global.coming_from_elevator:
		print("Handling elevator arrival...")
		_handle_elevator_arrival()
	else:
		print("Normal level_0 start")
		# Make sure screen is visible for normal start
		await get_tree().process_frame
		_ensure_visible()

func _handle_elevator_arrival() -> void:
	if not arrival_elevator or not player:
		print("ERROR: Missing elevator or player!")
		Global.coming_from_elevator = false
		return
	
	print("Starting elevator arrival sequence...")
	
	# Get original elevator position
	var original_pos = arrival_elevator.global_position
	print("Original elevator position: ", original_pos)
	
	# Move elevator up 10 meters
	arrival_elevator.global_position.y += 10.0
	print("Moved elevator to: ", arrival_elevator.global_position)
	
	# Position player in elevator
	player.global_position = arrival_elevator.global_position + Vector3(0, 1.0, 0)
	print("Player positioned at: ", player.global_position)
	
	# Restore camera if needed
	_restore_camera()
	
	# Start descent
	await _descent_sequence(original_pos)
	
	# Clear flag
	Global.coming_from_elevator = false
	print("Elevator arrival complete")

func _descent_sequence(target_pos: Vector3) -> void:
	print("Starting descent sequence...")
	
	# Create simple fade overlay
	var overlay = ColorRect.new()
	overlay.color = Color.BLACK
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	
	# Start black, then fade out during descent
	overlay.modulate.a = 1.0
	
	# Descent animation
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Move elevator and player down together
	tween.tween_property(arrival_elevator, "global_position", target_pos, 4.0)
	tween.tween_property(player, "global_position", target_pos + Vector3(0, 1.0, 0), 4.0)
	
	# Fade out overlay
	tween.tween_property(overlay, "modulate:a", 0.0, 3.0)
	
	await tween.finished
	
	# Clean up
	overlay.queue_free()
	
	# Open doors if elevator has the method
	if arrival_elevator.has_method("open_doors"):
		await arrival_elevator.open_doors()
	
	print("Descent complete")

func _restore_camera() -> void:
	if not player:
		return
		
	var head = player.get_node_or_null("Head")
	var camera = player.get_node_or_null("Head/Camera3D")
	
	if head and camera and Global.saved_head_rotation != Vector3.ZERO:
		head.rotation = Global.saved_head_rotation
		camera.rotation = Global.saved_camera_rotation
		print("Camera restored")
		
		# Clear saved state
		Global.saved_head_rotation = Vector3.ZERO
		Global.saved_camera_rotation = Vector3.ZERO

func _ensure_visible() -> void:
	print("Ensuring scene is visible...")
	# Simple function to make sure we can see the scene
	# Remove any potential overlays
	for child in get_children():
		if child is ColorRect and child.color == Color.BLACK:
			child.queue_free()
			print("Removed black overlay")
