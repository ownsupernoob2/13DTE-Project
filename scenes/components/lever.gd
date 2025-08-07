extends Node3D

@onready var handle: MeshInstance3D = $lever1/Handle
@onready var handle2: MeshInstance3D = $lever2/Handle2
@onready var handle3: MeshInstance3D = $lever3/Handle3
@onready var screen = $lever1/Quad/SubViewport/Control/RichTextLabel
@onready var screen2 = $lever2/Quad/SubViewport/Control/RichTextLabel
@onready var screen3 = $lever3/Quad/SubViewport/Control/RichTextLabel

# Counter values for each lever
var counter1: int = 0
var counter2: int = 0
var counter3: int = 0

# Track which lever is being held
var is_holding_lever1: bool = false
var is_holding_lever2: bool = false
var is_holding_lever3: bool = false

# Total counter limit
const TOTAL_MAX_COUNT: int = 100 # Total limit for all counters combined

# Font size settings
const BASE_FONT_SIZE: int = 500 # Base font size for single-digit numbers
const FONT_SCALE_FACTOR: float = 0.8 # Reduce font size by 80% per additional digit

# Color settings
const BASE_COLOR: Color = Color(1, 1, 1, 1) # White
const TARGET_COLOR: Color = Color(1, 0, 0, 1) # Red

# Handle rotation settings
const MAX_ROTATION_DEGREES: float = 90.0 # Maximum X rotation for 100% fullness

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
	if !handle or !handle2 or !handle3:
		push_error("One or more handle nodes are not found!")

func _process(_delta: float) -> void:
	# Check if the player is still hovering over the lever handle
	var player = get_node_or_null("../Player")
	var current_lever = null
	if player and player.has_method("_update_interaction_raycast"):
		var player_using_computer = player.get("using_computer")
		if player_using_computer and player_using_computer.name in ["lever1", "lever2", "lever3"]:
			current_lever = player_using_computer.name

	# Stop holding if the mouse moves off the lever
	if is_holding_lever1 and current_lever != "lever1":
		stop_holding_lever("lever1")
	if is_holding_lever2 and current_lever != "lever2":
		stop_holding_lever("lever2")
	if is_holding_lever3 and current_lever != "lever3":
		stop_holding_lever("lever3")

# Function to get number of digits in a number
func get_digit_count(number: int) -> int:
	if number == 0:
		return 1
	return int(log(number) / log(10)) + 1

# Function to calculate font size based on digit count
func get_font_size(digit_count: int) -> int:
	return int(BASE_FONT_SIZE * pow(FONT_SCALE_FACTOR, digit_count - 1))

# Function to calculate color based on counter value
func get_color(counter: int) -> Color:
	var t = float(counter) / TOTAL_MAX_COUNT
	return BASE_COLOR.lerp(TARGET_COLOR, t)

# Function to set counter based on handle X rotation
func set_counter(lever_index: int, handle_rotation_z: float) -> void:
	var counter: int
	var screen_node: RichTextLabel
	var handle_node: MeshInstance3D
	match lever_index:
		1:
			counter = counter1
			screen_node = screen
			handle_node = handle
		2:
			counter = counter2
			screen_node = screen2
			handle_node = handle2
		3:
			counter = counter3
			screen_node = screen3
			handle_node = handle3
		_:
			return

	# Map handle rotation (0 to 90 degrees) to counter (0 to 100)
	var t = inverse_lerp(0, deg_to_rad(MAX_ROTATION_DEGREES), handle_rotation_z)
	var proposed_counter = round(100 * t)
	var old_digit_count = get_digit_count(counter)
	var total_before = counter1 + counter2 + counter3
	proposed_counter = clamp(proposed_counter, 0, TOTAL_MAX_COUNT)
	var proposed_total = total_before - counter + proposed_counter
	if proposed_total > TOTAL_MAX_COUNT:
		proposed_counter = 0
	# Update counter
	match lever_index:
		1:
			counter1 = proposed_counter
		2:
			counter2 = proposed_counter
		3:
			counter3 = proposed_counter
	# Update font size if digit count changed
	var new_digit_count = get_digit_count(proposed_counter)
	if new_digit_count != old_digit_count:
		screen_node.add_theme_font_size_override("normal_font_size", get_font_size(new_digit_count))
	# Update color based on counter value
	screen_node.add_theme_color_override("default_color", get_color(proposed_counter))
	# Update handle rotation (X-axis)
	handle_node.rotation.z = handle_rotation_z
	# Update screen text
	screen_node.text = "[center]" + str(proposed_counter) + "[/center]"
	print("Lever ", lever_index, " counter updated to: ", proposed_counter, " with font size: ", screen_node.get_theme_font_size("normal_font_size"), " rotation: ", rad_to_deg(handle_node.rotation.z))

# Function to update all screens and handle rotations
func update_screens() -> void:
	var digit_count1 = get_digit_count(counter1)
	var digit_count2 = get_digit_count(counter2)
	var digit_count3 = get_digit_count(counter3)
	screen.add_theme_font_size_override("normal_font_size", get_font_size(digit_count1))
	screen2.add_theme_font_size_override("normal_font_size", get_font_size(digit_count2))
	screen3.add_theme_font_size_override("normal_font_size", get_font_size(digit_count3))
	screen.add_theme_color_override("default_color", get_color(counter1))
	screen2.add_theme_color_override("default_color", get_color(counter2))
	screen3.add_theme_color_override("default_color", get_color(counter3))
	# Set handle rotations based on current counters
	handle.rotation.z = (float(counter1) / TOTAL_MAX_COUNT) * deg_to_rad(MAX_ROTATION_DEGREES)
	handle2.rotation.z = (float(counter2) / TOTAL_MAX_COUNT) * deg_to_rad(MAX_ROTATION_DEGREES)
	handle3.rotation.z = (float(counter3) / TOTAL_MAX_COUNT) * deg_to_rad(MAX_ROTATION_DEGREES)
	screen.text = "[center]" + str(counter1) + "[/center]"
	screen2.text = "[center]" + str(counter2) + "[/center]"
	screen3.text = "[center]" + str(counter3) + "[/center]"

# Functions to be called by player script
func start_holding_lever(lever_name: String) -> void:
	print("yo gurt: ", lever_name)
	match lever_name:
		"lever1":
			is_holding_lever1 = true
		"lever2":
			is_holding_lever2 = true
		"lever3":
			is_holding_lever3 = true

func stop_holding_lever(lever_name: String) -> void:
	print("no gurt: ", lever_name)
	match lever_name:
		"lever1":
			is_holding_lever1 = false
		"lever2":
			is_holding_lever2 = false
		"lever3":
			is_holding_lever3 = false
