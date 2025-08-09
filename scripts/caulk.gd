extends StaticBody3D

# Caulk item - used to repair pod integrity during medium/hard stages

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var is_being_used: bool = false
var repair_amount: float = 25.0  # How much it repairs per use

func _ready() -> void:
	# Add to grabbable group so player can pick it up
	add_to_group("grabbable")
	add_to_group("caulk")
	
	# Set up visual appearance
	if mesh_instance:
		# Create a simple cylinder mesh for the caulk tube
		var cylinder_mesh = CylinderMesh.new()
		cylinder_mesh.top_radius = 0.05
		cylinder_mesh.bottom_radius = 0.05
		cylinder_mesh.height = 0.3
		mesh_instance.mesh = cylinder_mesh
		
		# Create material - yellow/orange for caulk
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.ORANGE
		material.metallic = 0.2
		material.roughness = 0.7
		mesh_instance.material_override = material
	
	print("Caulk spawned - grab to repair pod!")

func use_caulk() -> bool:
	if is_being_used:
		print("Caulk already in use!")
		return false
	
	if not GameManager or not GameManager.caulk_available:
		print("Caulk not available!")
		return false
	
	is_being_used = true
	
	# Trigger repair in GameManager
	GameManager.repair_pod_with_caulk()
	
	# Visual feedback
	_play_repair_effect()
	
	# Check if caulk is depleted
	if GameManager.caulk_fuel <= 0:
		_deplete_caulk()
	
	is_being_used = false
	return true

func _play_repair_effect() -> void:
	# Simple visual effect - make it glow briefly
	if mesh_instance:
		var original_scale = mesh_instance.scale
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", original_scale * 1.2, 0.2)
		tween.tween_property(mesh_instance, "scale", original_scale, 0.2)
	
	print("🔧 *PSSSSHHHH* Caulk applied!")

func _deplete_caulk() -> void:
	print("🔋 Caulk depleted - removing from scene")
	
	# Fade out effect
	if mesh_instance:
		var tween = create_tween()
		tween.tween_property(mesh_instance, "modulate:a", 0.0, 1.0)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func get_fuel_remaining() -> float:
	if GameManager:
		return GameManager.caulk_fuel
	return 0.0

func can_use() -> bool:
	return not is_being_used and GameManager and GameManager.caulk_available and GameManager.caulk_fuel > 0
