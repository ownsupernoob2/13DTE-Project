extends CharacterBody3D

var speed: float
const WALK_SPEED: float = 3.0
const SPRINT_SPEED: float = 8.0
const JUMP_VELOCITY: float = 4.8
const SENSITIVITY: float = 0.004
const BOB_FREQ: float = 2.4
const BOB_AMP: float = 0.02
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

# Lever interaction variables
var is_holding_lever: bool = false
var current_lever: String = ""
var lever_rotation_z: float = 0.0 # Tracks lever handle's Z rotation

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
		# Make camera look at the lever handle while holding
		if is_holding_lever and using_computer and using_computer.name in ["lever1", "lever2", "lever3"]:
			var levers_node = get_node_or_null("../LeverGutentagPosition")
			if levers_node:
				var handle_node = null
				match using_computer.name:
					"lever1":
						handle_node = levers_node.get_node_or_null("lever1/Handle")
					"lever2":
						handle_node = levers_node.get_node_or_null("lever2/Handle2")
					"lever3":
						handle_node = levers_node.get_node_or_null("lever3/Handle3")
				if handle_node:
					var target_position = handle_node.global_position
					var camera_position = camera.global_position
					# Adjust target position to prevent camera from aligning directly along the up vector
					if abs(target_position.y - camera_position.y) < 0.01:
						target_position.y += 0.01
					camera.look_at(target_position, Vector3.UP)
					# Ensure head aligns with camera's yaw
					head.global_rotation.y = camera.global_rotation.y

func _update_interaction_raycast() -> void:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_start: Vector3 = player_camera.project_ray_origin(mouse_pos)
	var ray_end: Vector3 = ray_start + player_camera.project_ray_normal(mouse_pos) * 3.0
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
			# Do not set using_computer for grabbable objects to preserve disk insertion logic
		if result.collider.name == "StartButton":
			can_interact = true
			using_computer = result.collider
		# Check for lever handles
		if result.collider.name in ["Handle", "Handle2", "Handle3"]:
			can_interact = true
			using_computer = result.collider.get_parent().get_parent()
		elif result.collider.get_parent() and (result.collider.get_parent().name == "StartButton"):
			can_interact = true
			using_computer = result.collider.get_parent()

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

	# Simulate the input event for the StartButton
	if using_computer.name == "StartButton":
		var input_event = InputEventMouseButton.new()
		input_event.button_index = MOUSE_BUTTON_LEFT
		input_event.pressed = true
		machine_node._on_start_button_input(null, input_event, Vector3.ZERO, Vector3.ZERO, 0)
		print("Player pressed machine button: ", using_computer.name)
	else:
		print("No valid button detected!")

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
	if event is InputEventMouseMotion and not (Global.is_using_computer or Global.is_using_monitor):
		if is_holding_lever and using_computer and using_computer.name in ["lever1", "lever2", "lever3"]:
			# Update lever rotation based on mouse vertical motion
			lever_rotation_z -= event.relative.y * SENSITIVITY
			lever_rotation_z = clamp(lever_rotation_z, 0, deg_to_rad(90))
			var levers_node = get_node_or_null("../LeverGutentagPosition")
			if levers_node and levers_node.has_method("set_counter"):
				var lever_index = {"lever1": 1, "lever2": 2, "lever3": 3}[using_computer.name]
				levers_node.set_counter(lever_index, lever_rotation_z)
		else:
			# Update camera rotation only when not holding a lever
			head.rotate_y(-event.relative.x * SENSITIVITY)
			camera.rotate_x(-event.relative.y * SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if Global.is_using_computer or Global.is_using_monitor:
			if event.pressed:
				exit_computer_mode()
		elif can_interact and using_computer:
			if using_computer.is_in_group("monitor") and not held_object:
				if event.pressed:
					enter_monitor_mode()
			elif using_computer.is_in_group("computer") and not held_object:
				if event.pressed:
					enter_computer_mode()
			elif using_computer.is_in_group("computer") and held_object and held_object.is_in_group("disk"):
				if event.pressed:
					insert_disk()
			elif using_computer.name == "StartButton":
				if event.pressed:
					press_machine_button()
			elif using_computer.name in ["lever1", "lever2", "lever3"] and not held_object:
				var levers_node = get_node_or_null("../LeverGutentagPosition")
				if levers_node and levers_node.has_method("start_holding_lever") and levers_node.has_method("stop_holding_lever"):
					if event.pressed:
						is_holding_lever = true
						current_lever = using_computer.name
						# Initialize lever rotation based on current counter
						var lever_index = {"lever1": 1, "lever2": 2, "lever3": 3}[current_lever]
						var current_counter = levers_node.get("counter" + str(lever_index))
						lever_rotation_z = (float(current_counter) / 100) * deg_to_rad(90)
						levers_node.start_holding_lever(using_computer.name)
						print("Starting lever hold: ", using_computer.name)
					else:
						is_holding_lever = false
						current_lever = ""
						levers_node.stop_holding_lever(using_computer.name)
						print("Stopping lever hold: ", using_computer.name)
		elif held_object == null and can_grab:
			if event.pressed:
				grab_object()
		elif held_object and can_grab:
			if event.pressed:
				drop_object()

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
		held_object_name = result.collider.name
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
			break # Only need to process the first MeshInstance3D

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
