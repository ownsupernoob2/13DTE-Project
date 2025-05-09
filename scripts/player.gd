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

var can_grab: bool = false
var held_object: StaticBody3D = null
var original_position: Vector3
var original_rotation: Vector3
var held_object_name: String = ""
var original_material: Material = null
var highlight_material: Material = preload("res://assets/materials/highlight_material.tres")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if held_object == null and can_grab:
			grab_object()
		elif held_object != null and can_grab:
			drop_object()

func _physics_process(delta):
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

func grab_object():
	if held_object != null or not can_grab:
		return
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_start = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_start + camera.project_ray_normal(mouse_pos) * 10.0
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
		if held_object:
			held_object.visible = false
		else:
			for node in get_tree().get_nodes_in_group("grabbable"):
				#node.visible = false
				var mesh = node.get_node_or_null("MeshInstance3D")
				if mesh and mesh is MeshInstance3D:
					mesh.set_surface_override_material(0, mesh.mesh.surface_get_material(0))
