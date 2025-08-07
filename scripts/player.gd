extends CharacterBody3D

var speed: float
const WALK_SPEED: float = 3.0  # Reduced from 5.0
const SPRINT_SPEED: float = 5.0  # Reduced from 8.0
const JUMP_VELOCITY: float = 4.8
const SENSITIVITY: float = 0.004

const BOB_FREQ: float = 2.4
const BOB_AMP: float = 0.08
var t_bob: float = 0.0

const BASE_FOV: float = 75.0
const FOV_CHANGE: float = 1.5

var gravity: float = 9.8

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var player_camera: Camera3D = camera

@onready var cursor1: TextureRect = $CanvasLayer/Cursor1
@onready var cursor2: TextureRect = $CanvasLayer/Cursor2

var can_grab: bool = false
var current_grab_area: Node = null
var held_object: StaticBody3D = null
var original_position: Vector3
var original_rotation: Vector3
var held_object_name: String = ""
var original_material: Material = null
var highlight_material: Material = preload("res://assets/materials/highlight_material.tres")
var active_computer_camera: Camera3D = null
var can_interact: bool = false
var using_computer = null

# Disk system variables - now using DiskManager singleton

# Lever interaction variables
var is_holding_lever: bool = false
var current_lever_name: String = ""
var lever_node: Node = null
var lever_initial_value: int = 0
var lever_drag_center_y: float = 0.0  # Center point for drag calculations
var lever_accumulated_motion: float = 0.0  # Track mouse motion while dragging lever
var lever_validation_timer: float = 0.0  # Timer for periodic raycast validation

# Track lever values to prevent sedation without changes
var initial_lever_values: Array = [0, 0, 0]  # Store initial values when first checking levers
var have_lever_values_changed: bool = false  # Track if any lever has been modified

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if cursor1 and cursor2:
		cursor1.visible = true
		cursor2.visible = false

func _process(_delta: float) -> void:
	if Global.is_using_computer or Global.is_using_monitor:
		if cursor1:
			cursor1.visible = false
		if cursor2:
			cursor2.visible = false
	else:
		_update_interaction_raycast()
		if cursor1:
			cursor1.visible = !can_interact
		if cursor2:
			cursor2.visible = can_interact
	
	# Much less frequent validation for lever interaction to prevent interruptions
	if is_holding_lever:
		lever_validation_timer += _delta
		if lever_validation_timer >= 0.5:  # Check every 500ms instead of 100ms for stability
			lever_validation_timer = 0.0
			# Only validate if there's been no recent motion (don't interrupt active use)
			if abs(lever_accumulated_motion) < 5.0:  # Only check when not actively moving
				if not _validate_lever_raycast():
					print("Lever interaction stopped: Periodic validation failed")
					_stop_lever_interaction()
	
	# Lever dragging is now handled by mouse motion events in _unhandled_input

func _update_interaction_raycast() -> void:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_start: Vector3 = player_camera.project_ray_origin(mouse_pos)
	var ray_end: Vector3 = ray_start + player_camera.project_ray_normal(mouse_pos) * 2.0  # Reduced from 3.0 to 2.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	var result: Dictionary = space_state.intersect_ray(query)
	
	can_interact = false
	using_computer = null
	if result and result.collider:
		if result.collider.is_in_group("monitor"):
			can_interact = true
			using_computer = result.collider
		if result.collider.is_in_group("computer"):
			can_interact = true
			using_computer = result.collider
		if result.collider.is_in_group("grabbable"):
			can_interact = true
		# Add machine button detection
		if result.collider.name == "UpButton" or result.collider.name == "DownButton":
			can_interact = true
			using_computer = result.collider
		# Check if collision is with StaticBody3D child of a button
		elif result.collider.get_parent() and (result.collider.get_parent().name == "UpButton" or result.collider.get_parent().name == "DownButton"):
			can_interact = true
			using_computer = result.collider.get_parent()
		# Add lever detection
		if result.collider.is_in_group("lever"):
			can_interact = true
			using_computer = result.collider
		# Check for lever handles specifically
		elif result.collider.name in ["Handle", "Handle2", "Handle3"]:
			can_interact = true
			using_computer = result.collider
		# Check for injection button
		elif result.collider.name == "InjectButton" or result.collider.is_in_group("inject_button"):
			can_interact = true
			using_computer = result.collider

func insert_disk() -> void:
	if held_object == null or not can_grab or Global.is_using_computer or Global.is_using_monitor:
		return
	
	# Get the computer node and its terminal
	var computer_node = get_node_or_null("../Computer")
	if not computer_node:
		print("Computer node not found!")
		return
		
	var terminal = computer_node.get_node_or_null("Computer/SubViewport/Control/Console")
	if terminal and terminal.has_method("insert_disk"):
		# Check if there's already a disk inserted
		if terminal.inserted_disk != "":
			print("Cannot insert disk - computer already has a disk inserted: ", terminal.inserted_disk)
			return
			
		# Get disk data from DiskManager
		var disk_data = DiskManager.get_disk_info(held_object_name)
		if not disk_data.is_empty():
			print("Inserting disk: ", held_object_name)
			terminal.insert_disk(held_object_name, held_object, disk_data)
		else:
			print("Unknown disk type: ", held_object_name)
			return
			
		# Hide the physical disk
		held_object.visible = false
		held_object.remove_from_group("grabbable") # Prevent grabbing while inserted
		
		# Hide the held version in player's hand
		var held_version: Node = camera.get_node_or_null(held_object_name + "_Held")
		var placeholder: Node = camera.get_node_or_null("Placeholder")
		if held_version:
			held_version.visible = false
		if placeholder:
			placeholder.visible = false
			
		# Clear held object references
		held_object = null
		held_object_name = ""
		original_material = null
		original_position = Vector3.ZERO
		original_rotation = Vector3.ZERO

func return_disk_to_hand(disk_name: String, disk_node: Node) -> void:
	var disk_info = DiskManager.get_disk_info(disk_name)
	if not disk_info.is_empty() and disk_node and disk_node.is_in_group("disk"):
		held_object = disk_node
		held_object_name = disk_name
		original_position = disk_node.global_position
		original_rotation = disk_node.global_rotation
		held_object.add_to_group("grabbable")
		for child in held_object.get_children():
			if child is MeshInstance3D:
				# Always store the base mesh material, not the override
				original_material = child.mesh.surface_get_material(0)
				child.set_surface_override_material(0, highlight_material)
				break
		held_object.visible = true
		var held_version: Node = camera.get_node_or_null(held_object_name + "_Held")
		var placeholder: Node = camera.get_node_or_null("Placeholder")
		if held_version:
			held_version.visible = true
		elif placeholder:
			placeholder.visible = true
		exit_computer_mode()

func press_machine_button() -> void:
	if not using_computer or Global.is_using_computer or Global.is_using_monitor:
		return
		
	# Find the machine that contains this button
	var machine_node = get_node_or_null("../Light/Machine")
	if not machine_node:
		print("Machine node not found!")
		return
	
	# Call the machine's button handler with the button name
	if machine_node.has_method("handle_button_press"):
		machine_node.handle_button_press(using_computer.name)
		print("Player pressed machine button: ", using_computer.name)
	else:
		print("Machine doesn't have handle_button_press method!")

func enter_monitor_mode() -> void:
	if using_computer and not Global.is_using_computer and not Global.is_using_monitor:
		active_computer_camera = get_node_or_null("../Monitor/MonitorCamera")
		if active_computer_camera and active_computer_camera is Camera3D:
			Global.is_using_monitor = true
			Global.is_using_computer = false
			player_camera.current = false
			active_computer_camera.current = true
			velocity = Vector3.ZERO
			if cursor1:
				cursor1.visible = false
			if cursor2:
				cursor2.visible = false
		else:
			push_error("Failed to switch to MonitorCamera: Node not found or invalid.")
			if cursor1:
				cursor1.visible = !can_interact
			if cursor2:
				cursor2.visible = can_interact

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Allow camera rotation unless using computer or monitor
		# When holding lever, allow limited camera movement while controlling lever
		var can_rotate_camera = not (Global.is_using_computer or Global.is_using_monitor)
		
		if is_holding_lever and lever_node:
			# DUAL FUNCTION: Both lever control AND limited camera movement
			# Horizontal mouse movement = NO camera rotation (locked)
			# Vertical mouse movement = both lever control AND camera rotation
			
			# Lever control (vertical motion) - increased speed
			var lever_motion_delta = -event.relative.y * 0.8  # Increased from 0.5 for faster response
			lever_accumulated_motion += lever_motion_delta
			lever_accumulated_motion = clamp(lever_accumulated_motion, -100, 100)
			
			if abs(lever_motion_delta) > 2.0:
				print("Lever Motion - Delta: ", lever_motion_delta, " Total: ", lever_accumulated_motion)
			_handle_lever_drag_motion()
			
			# Camera rotation - ONLY vertical movement (no horizontal when holding lever)
			# Increased vertical sensitivity to sync with lever movement
			camera.rotate_x(-event.relative.y * SENSITIVITY * 0.6)  # Increased from 0.3 for better sync
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-70), deg_to_rad(60))
			
		elif can_rotate_camera:
			# Full normal camera rotation when not using computer/monitor and not holding lever
			head.rotate_y(-event.relative.x * SENSITIVITY)
			camera.rotate_x(-event.relative.y * SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-70), deg_to_rad(60))
			
		else:
			# Debug: Show why camera rotation is blocked
			if abs(event.relative.y) > 1.0:
				print("Camera rotation blocked - Computer:", Global.is_using_computer, " Monitor:", Global.is_using_monitor)
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if Global.is_using_computer or Global.is_using_monitor:
				exit_computer_mode()
			elif can_interact and using_computer:
				if using_computer.is_in_group("monitor") and not held_object:
					enter_monitor_mode()
				elif using_computer.is_in_group("computer") and not held_object:
					enter_computer_mode()
				elif held_object and held_object.is_in_group("disk"):
					insert_disk()
				elif using_computer.name == "UpButton" or using_computer.name == "DownButton":
					press_machine_button()
				elif using_computer.name in ["Handle", "Handle2", "Handle3"] or using_computer.is_in_group("lever"):
					_start_lever_interaction()
				elif using_computer.name == "InjectButton" or using_computer.is_in_group("inject_button"):
					_inject_fluids()
			elif held_object == null and can_grab:
				grab_object()
			elif held_object and can_grab:
				drop_object()
		else:  # Mouse button released
			if is_holding_lever:
				_stop_lever_interaction()

func enter_computer_mode() -> void:
	if using_computer and not Global.is_using_computer and not Global.is_using_monitor:
		active_computer_camera = $"../Computer/ComputerCamera"
		if active_computer_camera and active_computer_camera is Camera3D:
			Global.is_using_computer = true
			Global.is_using_monitor = false
			player_camera.current = false
			active_computer_camera.current = true
			velocity = Vector3.ZERO
			var terminal = $"../Computer/Computer/SubViewport/Control/Console"
			if terminal and terminal.has_method("power_on"):
				terminal.power_on()
			if cursor1:
				cursor1.visible = false
			if cursor2:
				cursor2.visible = false
		else:
			if cursor1:
				cursor1.visible = !can_interact
			if cursor2:
				cursor2.visible = can_interact

func exit_computer_mode() -> void:
	if Global.is_using_computer or Global.is_using_monitor:
		Global.is_using_computer = false
		Global.is_using_monitor = false
		if active_computer_camera:
			active_computer_camera.current = false
		player_camera.current = true
		active_computer_camera = null
		_update_interaction_raycast()
		if cursor1:
			cursor1.visible = !can_interact
		if cursor2:
			cursor2.visible = can_interact

func _physics_process(delta: float) -> void:
	if Global.is_using_computer or Global.is_using_monitor:
		velocity = Vector3.ZERO
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	speed = WALK_SPEED

	var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down")
	var direction: Vector3 = (head.transform.basis * transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	var velocity_clamped: float = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov: float = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()

func _headbob(time: float) -> Vector3:
	var pos: Vector3 = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func grab_object() -> void:
	if held_object != null or not can_grab or Global.is_using_computer or Global.is_using_monitor:
		return

	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_start: Vector3 = player_camera.project_ray_origin(mouse_pos)
	var ray_end: Vector3 = ray_start + player_camera.project_ray_normal(mouse_pos) * 20.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	var result: Dictionary = space_state.intersect_ray(query)

	if result and result.collider and result.collider.is_in_group("grabbable"):
		held_object = result.collider
		held_object_name = held_object.name
		original_position = held_object.global_position
		original_rotation = held_object.global_rotation

		# Restore all disks' materials
		for node in get_tree().get_nodes_in_group("grabbable"):
			for child in node.get_children():
				if child is MeshInstance3D:
					child.set_surface_override_material(0, child.mesh.surface_get_material(0))

		# Highlight the held disk
		for child in held_object.get_children():
			if child is MeshInstance3D:
				original_material = child.mesh.surface_get_material(0) # Use base material
				child.set_surface_override_material(0, highlight_material)
				break

		var held_version: Node = camera.get_node_or_null(held_object_name + "_Held")
		var placeholder: Node = camera.get_node_or_null("Placeholder")

		if placeholder:
			placeholder.visible = false

		if held_version:
			held_version.visible = true
		elif placeholder:
			placeholder.visible = true
			
func drop_object() -> void:
	if held_object == null or not can_grab or Global.is_using_computer or Global.is_using_monitor:
		return

	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_start: Vector3 = player_camera.project_ray_origin(mouse_pos)
	var ray_end: Vector3 = ray_start + player_camera.project_ray_normal(mouse_pos) * 20.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	var result: Dictionary = space_state.intersect_ray(query)

	var can_drop: bool = false
	if result and result.collider == held_object:
		can_drop = true
	elif result and result.position.distance_to(original_position) < 0.5:
		can_drop = true

	if not can_drop:
		return

	# Restore the held disk's material
	for child in held_object.get_children():
		if child is MeshInstance3D and original_material:
			child.set_surface_override_material(0, original_material)
			break  # Only need to process the first MeshInstance3D

	held_object.visible = true

	var held_version: Node = camera.get_node_or_null(held_object_name + "_Held")
	var placeholder: Node = camera.get_node_or_null("Placeholder")

	if held_version:
		held_version.visible = false
	if placeholder:
		placeholder.visible = false

	held_object.global_position = original_position
	held_object.global_rotation = original_rotation

	held_object = null
	held_object_name = ""
	original_material = null


func _on_grab_area_body_entered(body: Node) -> void:
	if body == self:
		can_grab = true
		current_grab_area = body.get_parent() if body.get_parent().has_method("get_groups") else body
		if held_object:
			held_object.visible = true
			var mesh: MeshInstance3D = held_object.get_node_or_null("MeshInstance3D")
			if mesh and mesh is MeshInstance3D:
				mesh.set_surface_override_material(0, highlight_material)
		else:
			for node in get_tree().get_nodes_in_group("grabbable"):
				node.visible = true
				var mesh: MeshInstance3D = node.get_node_or_null("MeshInstance3D")
				if mesh and mesh is MeshInstance3D:
					mesh.set_surface_override_material(0, mesh.mesh.surface_get_material(0))

func _on_grab_area_body_exited(body: Node) -> void:
	if body == self:
		can_grab = false
		if held_object:
			held_object.visible = false # Hide held disk when leaving area
		else:
			for node in get_tree().get_nodes_in_group("grabbable"):
				var mesh: MeshInstance3D = node.get_node_or_null("MeshInstance3D")
				if mesh and mesh is MeshInstance3D:
					mesh.set_surface_override_material(0, mesh.mesh.surface_get_material(0))
		current_grab_area = null

# Lever interaction functions
func _start_lever_interaction() -> void:
	if not using_computer:
		return
		
	is_holding_lever = true
	# Reset accumulated motion for fresh start
	lever_accumulated_motion = 0.0
	lever_validation_timer = 0.0  # Reset validation timer
	print("Lever interaction started. Precise control enabled for ", current_lever_name)
	print("Use small mouse movements for precise value setting.")
	
	# Find the lever node and determine which lever we're interacting with
	var lever_system = get_node_or_null("../LeverGutentagPosition")
	if not lever_system:
		print("Lever system not found!")
		is_holding_lever = false
		return
		
	lever_node = lever_system
	print("Lever system found: ", lever_system)
	
	# Determine which lever based on the handle path first
	var handle_path = using_computer.get_path()
	print("Handle path: ", handle_path)
	
	if "lever1" in str(handle_path):
		current_lever_name = "lever1"
		lever_initial_value = lever_system.counter1
	elif "lever2" in str(handle_path):
		current_lever_name = "lever2" 
		lever_initial_value = lever_system.counter2
	elif "lever3" in str(handle_path):
		current_lever_name = "lever3"
		lever_initial_value = lever_system.counter3
	else:
		# Fallback: check using_computer name and parent structure
		print("Using fallback detection method")
		match using_computer.name:
			"Handle":
				current_lever_name = "lever1"
				lever_initial_value = lever_system.counter1
			"Handle2":
				current_lever_name = "lever2" 
				lever_initial_value = lever_system.counter2
			"Handle3":
				current_lever_name = "lever3"
				lever_initial_value = lever_system.counter3
			_:
				# If it's a lever group member, try to find which one
				var parent = using_computer.get_parent()
				if parent and parent.name in ["lever1", "lever2", "lever3"]:
					current_lever_name = parent.name
					match parent.name:
						"lever1":
							lever_initial_value = lever_system.counter1
						"lever2":
							lever_initial_value = lever_system.counter2
						"lever3":
							lever_initial_value = lever_system.counter3
				else:
					print("Could not determine lever type")
					is_holding_lever = false
					return
	
	print("Started holding ", current_lever_name, " with initial value: ", lever_initial_value)

func _validate_lever_raycast() -> bool:
	# More lenient validation - check a larger area around the lever
	if not is_holding_lever:
		return false
	
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_start: Vector3 = player_camera.project_ray_origin(mouse_pos)
	var ray_end: Vector3 = ray_start + player_camera.project_ray_normal(mouse_pos) * 8.0  # Longer range
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	var result: Dictionary = space_state.intersect_ray(query)
	
	if result and result.collider:
		var hit_object = result.collider
		# Check if we're still hitting a lever handle or any lever-related object
		if hit_object.name in ["Handle", "Handle2", "Handle3"] or hit_object.is_in_group("lever"):
			return true
		# Also check parent nodes for lever group membership
		var parent = hit_object.get_parent()
		if parent and parent.is_in_group("lever"):
			return true
		# Also check grandparent for lever systems
		if parent and parent.get_parent() and parent.get_parent().name == "LeverGutentagPosition":
			return true
	
	# Additional check: Test multiple raycast points around the center for more tolerance
	var viewport_size = get_viewport().get_visible_rect().size
	var center_offset = 50.0  # pixels around center
	var test_positions = [
		mouse_pos + Vector2(-center_offset, 0),
		mouse_pos + Vector2(center_offset, 0),
		mouse_pos + Vector2(0, -center_offset),
		mouse_pos + Vector2(0, center_offset)
	]
	
	for test_pos in test_positions:
		ray_start = player_camera.project_ray_origin(test_pos)
		ray_end = ray_start + player_camera.project_ray_normal(test_pos) * 8.0
		query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		result = space_state.intersect_ray(query)
		
		if result and result.collider:
			var hit_object = result.collider
			if hit_object.name in ["Handle", "Handle2", "Handle3"] or hit_object.is_in_group("lever"):
				return true
			var parent = hit_object.get_parent()
			if parent and (parent.is_in_group("lever") or (parent.get_parent() and parent.get_parent().name == "LeverGutentagPosition")):
				return true
	
	return false

func _handle_lever_drag_motion() -> void:
	if not is_holding_lever or not lever_node:
		return
	
	# Less frequent validation to prevent interruptions during precise control
	# Only validate when there's no recent motion (prevents interruption during active use)
	var time_since_last_motion = Time.get_time_dict_from_system()
	if lever_accumulated_motion == 0 and _validate_lever_raycast() == false:
		print("Lever interaction stopped: Lost contact with lever")
		_stop_lever_interaction()
		return
	
	# Precise motion control for accurate number setting
	var motion_sensitivity = 3.0  # Higher sensitivity for more precision
	var motion_deadzone = 2.0  # Minimum motion before registering change
	
	# Only process if motion is above deadzone
	if abs(lever_accumulated_motion) < motion_deadzone:
		return
	
	# Calculate new value based on accumulated motion only (no camera influence for precision)
	var motion_value = lever_accumulated_motion / motion_sensitivity
	
	# Apply motion with precise control
	var new_value = clamp(lever_initial_value + int(motion_value), 0, 100)
	
	# Reduced debug output for cleaner experience
	if abs(lever_accumulated_motion) > 10:  # Only print significant changes
		print("Precise Lever Control - Value: ", new_value)
	
	# Update the lever
	var lever_index = 0
	match current_lever_name:
		"lever1":
			lever_index = 1
		"lever2":
			lever_index = 2  
		"lever3":
			lever_index = 3
	
	if lever_index > 0:
		lever_node.set_lever_value(lever_index, new_value)

func _handle_lever_drag(current_mouse_y: float) -> void:
	# This function is now deprecated in favor of _handle_lever_drag_motion()
	# but keeping it for compatibility
	return

func _stop_lever_interaction() -> void:
	if is_holding_lever:
		print("Stopped holding ", current_lever_name)
		is_holding_lever = false
		current_lever_name = ""
		lever_node = null
		lever_drag_center_y = 0.0
		lever_initial_value = 0
		lever_accumulated_motion = 0.0  # Reset accumulated motion
		lever_validation_timer = 0.0  # Reset validation timer
		
		# Don't auto-adjust camera when stopping - let player maintain their view
		# This prevents the camera from jumping when they finish setting a precise value

func _inject_fluids() -> void:
	var lever_system = get_node_or_null("../LeverGutentagPosition")
	if not lever_system:
		print("Lever system not found!")
		return
	
	var combination = lever_system.get_combination()
	
	# Check if lever values have been changed from initial state
	if initial_lever_values.is_empty():
		# First time checking - store current values as initial
		initial_lever_values = combination.duplicate()
		have_lever_values_changed = false
		print("Initial lever values stored: ", initial_lever_values)
	
	# Check if current values differ from initial values
	var values_changed = false
	for i in range(3):
		if combination[i] != initial_lever_values[i]:
			values_changed = true
			break
	
	if not values_changed:
		print("SEDATION BLOCKED: Lever values have not been changed from initial state!")
		print("Current values: ", combination, " Initial values: ", initial_lever_values)
		return
	
	print("Injecting fluids with combination: ", combination[0], "/", combination[1], "/", combination[2])
	
	# Get the current alien's liquid ratios from monitor
	var monitor_system = get_node_or_null("../Monitor/Monitor/SubViewport/Control/Console")
	if monitor_system and monitor_system.has_method("get_current_liquid_ratios"):
		var correct_ratios = monitor_system.get_current_liquid_ratios()
		var tolerance = 3  # Allow 3 point tolerance for precision
		
		print("DEBUG: Expected ratios: ", correct_ratios)
		print("DEBUG: Player ratios: ", combination)
		print("DEBUG: Difference A: ", abs(combination[0] - correct_ratios[0]))
		print("DEBUG: Difference B: ", abs(combination[1] - correct_ratios[1]))
		print("DEBUG: Difference C: ", abs(combination[2] - correct_ratios[2]))
		
		# Check if player's values are within tolerance of correct ratios
		var liquid_a_correct = abs(combination[0] - correct_ratios[0]) <= tolerance
		var liquid_b_correct = abs(combination[1] - correct_ratios[1]) <= tolerance
		var liquid_c_correct = abs(combination[2] - correct_ratios[2]) <= tolerance
		
		print("DEBUG: A correct: ", liquid_a_correct, " B correct: ", liquid_b_correct, " C correct: ", liquid_c_correct)
		
		if liquid_a_correct and liquid_b_correct and liquid_c_correct:
			print("SUCCESS! Correct sedation ratios!")
			# Mark that lever values have been successfully used
			have_lever_values_changed = true
			# Reset initial values for next alien
			initial_lever_values = [0, 0, 0]
			# Enable accept/reject buttons on monitor
			if monitor_system.has_method("enable_classification"):
				monitor_system.enable_classification()
		else:
			print("FAILURE! Wrong sedation ratios. Expected: ", correct_ratios, " Got: ", combination)
			print("FAILURE! Tolerance: ", tolerance, " points")
			# Reset levers for another attempt
			lever_system.reset_levers()
			# Reset tracking values since levers were reset
			initial_lever_values = [0, 0, 0]
			have_lever_values_changed = false
	else:
		print("Monitor system not found or missing method!")
