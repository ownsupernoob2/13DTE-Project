extends CharacterBody3D

var speed: float
const WALK_SPEED: float = 5.0
const SPRINT_SPEED: float = 8.0
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

@onready var cursor1: TextureRect = $Cursor1 
@onready var cursor2: TextureRect = $Cursor2 

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

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if cursor1 and cursor2:
		cursor1.visible = true
		cursor2.visible = false
	else:
		print("Warning: Cursor1 or Cursor2 TextureRect not found")

func _process(_delta: float) -> void:
	if Global.is_using_computer:
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
		if result.collider.is_in_group("computer"):
			can_interact = true
			using_computer = result.collider
func insert_disk() -> void:
	#if held_object == null or not can_grab or Global.is_using_computer:
		#print("no?")
		#return
	#
		var terminal = $"../Node3D/Computer/SubViewport/Control/Console"
		if terminal and terminal.has_method("insert_disk"):
			print("yes?")
			terminal.insert_disk(held_object_name, held_object)
			held_object.visible = false
			var held_version: Node = camera.get_node_or_null(held_object_name + "_Held")
			var placeholder: Node = camera.get_node_or_null("Placeholder")
			if held_version:
				held_version.visible = false
			if placeholder:
				placeholder.visible = false
			held_object = null
			held_object_name = ""
			original_material = null
			original_position = Vector3.ZERO
			original_rotation = Vector3.ZERO
			#enter_computer_mode()

func return_disk_to_hand(disk_name: String, disk_node: Node) -> void:
	if disk_name == "Disk1" and disk_node and disk_node.is_in_group("disk"):
		held_object = disk_node
		held_object_name = disk_name
		var mesh: MeshInstance3D = held_object.get_node_or_null("MeshInstance3D")
		if mesh and mesh is MeshInstance3D:
			original_material = mesh.get_surface_override_material(0) if mesh.get_surface_override_material(0) else mesh.mesh.surface_get_material(0)
			mesh.set_surface_override_material(0, highlight_material)
		held_object.visible = false
		var held_version: Node = camera.get_node_or_null(held_object_name + "_Held")
		var placeholder: Node = camera.get_node_or_null("Placeholder")
		if held_version:
			held_version.visible = true
		elif placeholder:
			placeholder.visible = true
		exit_computer_mode()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not Global.is_using_computer:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-70), deg_to_rad(60))
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Global.is_using_computer:
			exit_computer_mode()
		elif held_object != null and held_object.is_in_group("disk") and can_interact and using_computer:
			insert_disk()
		elif can_interact and using_computer and not held_object:
			enter_computer_mode()
		elif held_object == null:
			if can_grab:
				grab_object()
		elif held_object != null and can_grab:
			drop_object()
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		using_computer = get_tree().get_first_node_in_group("computer")
		if using_computer:
			enter_computer_mode()

func enter_computer_mode() -> void:
	if using_computer and not Global.is_using_computer:
		active_computer_camera = $"../Node3D/ComputerCamera"
		if active_computer_camera and active_computer_camera is Camera3D:
			Global.is_using_computer = true
			player_camera.current = false
			active_computer_camera.current = true
			velocity = Vector3.ZERO
			var terminal = $"../Node3D/Computer/SubViewport/Control/Console"
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
	if Global.is_using_computer:
		Global.is_using_computer = false
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
	if Global.is_using_computer:
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
	if held_object != null or not can_grab or Global.is_using_computer:
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
		
		var mesh: MeshInstance3D = $"../Object1/Disk1/Disk1/floppy_disc_2"
		if mesh and mesh is MeshInstance3D:
			original_material = mesh.get_surface_override_material(0) if mesh.get_surface_override_material(0) else mesh.mesh.surface_get_material(0)
			if can_grab:
				mesh.set_surface_override_material(0, highlight_material)
		
		held_object.visible = can_grab
		
		var held_version: Node = camera.get_node_or_null(held_object_name + "_Held")
		var placeholder: Node = camera.get_node_or_null("Placeholder")
		
		if placeholder:
			placeholder.visible = false
		
		if held_version:
			held_version.visible = true
		elif placeholder:
			placeholder.visible = true

func drop_object() -> void:
	if held_object == null or not can_grab or Global.is_using_computer:
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
	
	for node in get_tree().get_nodes_in_group("grabbable"):
		var mesh: MeshInstance3D = $"../Object1/Disk1/Disk1/floppy_disc_2"
		if mesh and mesh is MeshInstance3D:
			mesh.set_surface_override_material(0, mesh.mesh.surface_get_material(0))
	
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
			held_object.visible = false
		else:
			for node in get_tree().get_nodes_in_group("grabbable"):
				var mesh: MeshInstance3D = node.get_node_or_null("MeshInstance3D")
				if mesh and mesh is MeshInstance3D:
					mesh.set_surface_override_material(0, mesh.mesh.surface_get_material(0))
		current_grab_area = null
