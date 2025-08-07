extends Node3D

@onready var handle: MeshInstance3D = $lever1/Handle
@onready var handle2: MeshInstance3D = $lever2/Handle2
@onready var handle3: MeshInstance3D = $lever3/Handle3
@onready var screen = $lever1/Quad/SubViewport/Control/RichTextLabel
@onready var screen2 = $lever2/Quad/SubViewport/Control/RichTextLabel
@onready var screen3 = $lever3/Quad/SubViewport/Control/RichTextLabel

# Sedate button
var sedate_button: StaticBody3D

# Counter values for each lever (0-100 system)
var counter1: int = 0
var counter2: int = 0
var counter3: int = 0

# Track which lever is being held
var is_holding_lever1: bool = false
var is_holding_lever2: bool = false
var is_holding_lever3: bool = false

# Value limit (0-100)
const MAX_VALUE: int = 100

# Font size settings
const BASE_FONT_SIZE: int = 400 # Base font size for 0-100 numbers

# Color settings
const BASE_COLOR: Color = Color(1, 1, 1, 1) # White
const TARGET_COLOR: Color = Color(0, 1, 0, 1) # Green when set

# Handle rotation settings
const MAX_ROTATION_DEGREES: float = 60.0 # Maximum Z rotation for value 100
const MIN_ROTATION_DEGREES: float = -30.0 # Starting Z rotation for value 0 (lower position)

func _ready() -> void:
	# Initialize screen displays, font size, color, and handle rotation
	update_screens()
	screen.add_theme_font_size_override("normal_font_size", BASE_FONT_SIZE)
	screen2.add_theme_font_size_override("normal_font_size", BASE_FONT_SIZE)
	screen3.add_theme_font_size_override("normal_font_size", BASE_FONT_SIZE)
	# Set initial color to white
	screen.add_theme_color_override("default_color", BASE_COLOR)
	screen2.add_theme_color_override("default_color", BASE_COLOR)
	screen3.add_theme_color_override("default_color", BASE_COLOR)
	# Enable BBCode and set text alignment to center
	screen.bbcode_enabled = true
	screen2.bbcode_enabled = true
	screen3.bbcode_enabled = true
	# Verify node references
	if !screen or !screen2 or !screen3:
		push_error("One or more screen nodes are not found!")
	
	# Create sedate button
	_create_sedate_button()
	if !handle or !handle2 or !handle3:
		push_error("One or more handle nodes are not found!")
	
	# Add levers to groups for player interaction
	$lever1.add_to_group("lever")
	$lever2.add_to_group("lever") 
	$lever3.add_to_group("lever")
	
	# Also add handle StaticBody3D nodes to lever group for interaction
	if $lever1/Handle/Handle:
		$lever1/Handle/Handle.add_to_group("lever")
	if $lever2/Handle2/Handle2:
		$lever2/Handle2/Handle2.add_to_group("lever")
	if $lever3/Handle3/Handle3:
		$lever3/Handle3/Handle3.add_to_group("lever")

func _process(_delta: float) -> void:
	# Simple process loop - most interaction is now handled by player.gd
	pass

# Function to calculate color based on value
func get_color(value: int) -> Color:
	if value > 0:
		return TARGET_COLOR  # Green when value is set
	else:
		return BASE_COLOR    # White when value is 0

# Function to set value directly (called by player)
func set_lever_value(lever_index: int, value: int) -> void:
	value = clamp(value, 0, MAX_VALUE)
	print("Lever.gd - set_lever_value called: index=", lever_index, " value=", value)
	
	var screen_node: RichTextLabel
	var handle_node: MeshInstance3D
	
	match lever_index:
		1:
			if counter1 == value:
				print("Lever 1: No change needed (already ", value, ")")
				return  # No change needed
			print("Lever 1: Updating from ", counter1, " to ", value)
			counter1 = value
			screen_node = screen
			handle_node = handle
		2:
			if counter2 == value:
				print("Lever 2: No change needed (already ", value, ")")
				return  # No change needed
			print("Lever 2: Updating from ", counter2, " to ", value)
			counter2 = value
			screen_node = screen2
			handle_node = handle2
		3:
			if counter3 == value:
				print("Lever 3: No change needed (already ", value, ")")
				return  # No change needed
			print("Lever 3: Updating from ", counter3, " to ", value)
			counter3 = value
			screen_node = screen3
			handle_node = handle3
		_:
			print("Invalid lever index: ", lever_index)
			return

	# Update color based on value
	screen_node.add_theme_color_override("default_color", get_color(value))
	
	# Update handle rotation (starts at MIN_ROTATION_DEGREES for 0, goes to MAX_ROTATION_DEGREES for 100)
	var rotation_range = MAX_ROTATION_DEGREES - MIN_ROTATION_DEGREES
	var rotation_z = MIN_ROTATION_DEGREES + (float(value) / MAX_VALUE) * rotation_range
	handle_node.rotation.z = deg_to_rad(rotation_z)
	
	# Update screen text
	screen_node.text = "[center]" + str(value) + "[/center]"
	
	print("Lever ", lever_index, " value updated to: ", value, " rotation: ", rad_to_deg(rotation_z), " degrees")

# Function to update all screens and handle rotations
func update_screens() -> void:
	screen.add_theme_font_size_override("normal_font_size", BASE_FONT_SIZE)
	screen2.add_theme_font_size_override("normal_font_size", BASE_FONT_SIZE)
	screen3.add_theme_font_size_override("normal_font_size", BASE_FONT_SIZE)
	
	screen.add_theme_color_override("default_color", get_color(counter1))
	screen2.add_theme_color_override("default_color", get_color(counter2))
	screen3.add_theme_color_override("default_color", get_color(counter3))
	
	# Set handle rotations based on current values
	var rotation_range = MAX_ROTATION_DEGREES - MIN_ROTATION_DEGREES
	handle.rotation.z = deg_to_rad(MIN_ROTATION_DEGREES + (float(counter1) / MAX_VALUE) * rotation_range)
	handle2.rotation.z = deg_to_rad(MIN_ROTATION_DEGREES + (float(counter2) / MAX_VALUE) * rotation_range)
	handle3.rotation.z = deg_to_rad(MIN_ROTATION_DEGREES + (float(counter3) / MAX_VALUE) * rotation_range)
	
	screen.text = "[center]" + str(counter1) + "[/center]"
	screen2.text = "[center]" + str(counter2) + "[/center]"
	screen3.text = "[center]" + str(counter3) + "[/center]"

# Get current combination as three 0-100 values
func get_combination() -> Array:
	return [counter1, counter2, counter3]

# Reset all levers to 0
func reset_levers() -> void:
	set_lever_value(1, 0)
	set_lever_value(2, 0)
	set_lever_value(3, 0)

func _create_sedate_button() -> void:
	# Create sedate button as a clickable 3D object
	sedate_button = StaticBody3D.new()
	sedate_button.name = "SedateButton"
	
	# Create mesh for the button
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.3, 0.1, 0.15)  # Button size
	mesh_instance.mesh = box_mesh
	
	# Create material for the button
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.2, 0.2, 1.0)  # Red color
	material.emission_enabled = true
	material.emission = Color(0.3, 0.0, 0.0, 1.0)  # Slight red glow
	mesh_instance.set_surface_override_material(0, material)
	
	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = box_mesh.size
	collision_shape.shape = box_shape
	
	# Add components to button
	sedate_button.add_child(mesh_instance)
	sedate_button.add_child(collision_shape)
	
	# Position the button (to the right of the levers)
	sedate_button.position = Vector3(0.6, 0.0, 0.0)
	
	# Add button to the lever group so it can be interacted with
	sedate_button.add_to_group("inject_button")
	
	# Add button to scene
	add_child(sedate_button)
	
	# Create a label for the button
	var label_3d = Label3D.new()
	label_3d.text = "SEDATE"
	label_3d.font_size = 64
	label_3d.position = Vector3(0, 0.15, 0)  # Above the button
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sedate_button.add_child(label_3d)
	
	print("Sedate button created and positioned")
