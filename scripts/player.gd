extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.8
const SENSITIVITY = 0.004

const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

var gravity = 9.8

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var player_camera = camera

@onready var cursor1 = $Cursor1 # Default cursor (cannot interact)
@onready var cursor2 = $Cursor2 # Interact cursor (can interact)

var can_grab: bool = false
var current_grab_area: Node = null
var held_object: StaticBody3D = null
var original_position: Vector3
var original_rotation: Vector3
var held_object_name: String = ""
var original_material: Material = null
var highlight_material: Material = preload("res://assets/materials/highlight_material.tres")
var is_using_computer: bool = false
var active_computer_camera: Camera3D = null
var can_interact: bool = false
var can_use_computer: bool = false
var current_computer_area: Node = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Initialize cursor visibility
	if cursor1 and cursor2:
		cursor1.visible = true
		cursor2.visible = false
	else:
		print("Warning: Cursor1 or Cursor2 TextureRect not found")

func _process(_delta):
	# Update cursor visibility based on interactable state
	if not is_using_computer:
		check_interactable()
		if cursor1 and cursor2:
			cursor1.visible = !can_interact
			cursor2.visible = can_interact
	else:
		# Hide both cursors in computer mode
		if cursor1 and cursor2:
			cursor1.visible = false
			cursor2.visible = false

# SHARED INPUT HANDLING
func _unhandled_input(event):
	if event is InputEventMouseMotion and not is_using_computer:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_using_computer:
			return
		if held_object == null:
			if can_use_computer:
				var clicked_computer = try_click_computer()
				if clicked_computer:
					enter_computer_mode(clicked_computer)
			if can_grab:
				grab_object()
		elif held_object != null and can_grab:
			drop_object()
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and is_using_computer:
		exit_computer_mode()

# MOVEMENT MECHANICS
func _physics_process(delta):
	if is_using_computer:
		velocity = Vector3.ZERO
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	speed = WALK_SPEED

	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
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

	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

# GRABBING MECHANICS
func grab_object():
	if held_object != null or not can_grab:
		return
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_start = player_camera.project_ray_origin(mouse_pos)
	var ray_end = ray_start + player_camera.project_ray_normal(mouse_pos) * 20.0
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	var result = space_state.intersect_ray(query)
	
	if result and result.collider and result.collider.is_in_group("grabbable"):
		held_object = result.collider
		held_object_name = held_object.name
		original_position = held_object.global_position
		original_rotation = held_object.global_rotation
		
		var mesh = held_object.get_node_or_null("MeshInstance3D")
		if mesh and mesh is MeshInstance3D:
			original_material = mesh.get_surface_override_material(0) if mesh.get_surface_override_material(0) else mesh.mesh.surface_get_material(0)
			if can_grab:
				mesh.set_surface_override_material(0, highlight_material)
		
		held_object.visible = can_grab
		
		var held_version = camera.get_node_or_null(held_object_name + "_Held")
		var placeholder = camera.get_node_or_null("Placeholder")
		
		if placeholder:
			placeholder.visible = false
		
		if held_version:
			held_version.visible = true
		elif placeholder:
			placeholder.visible = true

func drop_object():
	if held_object == null or not can_grab:
		return
	
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_start = player_camera.project_ray_origin(mouse_pos)
	var ray_end = ray_start + player_camera.project_ray_normal(mouse_pos) * 20.0
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	var result = space_state.intersect_ray(query)
	
	var can_drop = false
	if result and result.collider == held_object:
		can_drop = true
	elif result and result.position.distance_to(original_position) < 0.5:
		can_drop = true
	
	if not can_drop:
		return
	
	for node in get_tree().get_nodes_in_group("grabbable"):
		var mesh = node.get_node_or_null("MeshInstance3D")
		if mesh and mesh is MeshInstance3D:
			mesh.set_surface_override_material(0, mesh.mesh.surface_get_material(0))
	
	held_object.visible = true
	
	var held_version = camera.get_node_or_null(held_object_name + "_Held")
	var placeholder = camera.get_node_or_null("Placeholder")
	
	if held_version:
		held_version.visible = false
	if placeholder:
		placeholder.visible = false
	
	held_object.global_position = original_position
	held_object.global_rotation = original_rotation
	
	held_object = null
	held_object_name = ""
	original_material = null

func _on_grab_area_body_entered(body):
	if body == self:
		can_grab = true
		current_grab_area = body.get_parent() if body.get_parent().has_method("get_groups") else body
		print("Entered grab area, can_grab: ", can_grab)
		if held_object:
			held_object.visible = true
			var mesh = held_object.get_node_or_null("MeshInstance3D")
			if mesh and mesh is MeshInstance3D:
				mesh.set_surface_override_material(0, highlight_material)
		else:
			for node in get_tree().get_nodes_in_group("grabbable"):
				node.visible = true
				var mesh = node.get_node_or_null("MeshInstance3D")
				if mesh and mesh is MeshInstance3D:
					mesh.set_surface_override_material(0, mesh.mesh.surface_get_material(0))

func _on_grab_area_body_exited(body):
	if body == self:
		can_grab = false
		print("Exited grab area, can_grab: ", can_grab)
		if held_object:
			held_object.visible = false
		else:
			for node in get_tree().get_nodes_in_group("grabbable"):
				var mesh = node.get_node_or_null("MeshInstance3D")
				if mesh and mesh is MeshInstance3D:
					mesh.set_surface_override_material(0, mesh.mesh.surface_get_material(0))
		current_grab_area = null

func _on_computer_area_body_entered(body):
	if body == self:
		can_use_computer = true
		current_computer_area = body.get_parent() if body.get_parent().has_method("get_groups") else body
		print("Entered computer area, can_use_computer: ", can_use_computer)

func _on_computer_area_body_exited(body):
	if body == self:
		can_use_computer = false
		print("Exited computer area, can_use_computer: ", can_use_computer)
		current_computer_area = null

# INTERACTION CHECK FOR CURSOR
func check_interactable():
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_start = player_camera.project_ray_origin(mouse_pos)
	var ray_end = ray_start + player_camera.project_ray_normal(mouse_pos) * 20.0
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	var result = space_state.intersect_ray(query)
	
	can_interact = false
	if result and result.collider:
		if result.collider.is_in_group("grabbable") and can_grab and held_object == null:
			can_interact = true
		elif result.collider.is_in_group("computer") and can_use_computer:
			can_interact = true

# COMPUTER INTERACTION MECHANICS
func try_click_computer() -> Node:
	if not can_use_computer or not current_computer_area:
		print("Cannot click computer: can_use_computer is ", can_use_computer, ", current_computer_area is ", current_computer_area)
		return null
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_start = player_camera.project_ray_origin(mouse_pos)
	var ray_end = ray_start + player_camera.project_ray_normal(mouse_pos) * 20.0
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	var result = space_state.intersect_ray(query)
	
	if result and result.collider:
		print("Raycast hit: ", result.collider.name, " in group computer: ", result.collider.is_in_group("computer"))
		if result.collider.is_in_group("computer"):
			return result.collider
	else:
		print("Raycast hit nothing")
	return null

func enter_computer_mode(computer: Node):
	var computer_camera = computer.get_node_or_null("ComputerCamera")
	if computer_camera and computer_camera is Camera3D:
		print("Entering computer mode with camera: ", computer_camera.name)
		is_using_computer = true
		active_computer_camera = computer_camera
		player_camera.current = false
		active_computer_camera.current = true
	else:
		print("Failed to find ComputerCamera in ", computer.name)

func exit_computer_mode():
	is_using_computer = false
	if active_computer_camera:
		active_computer_camera.current = false
	player_camera.current = true
	print("Switched back to player camera: ", player_camera.current)
	active_computer_camera = null
