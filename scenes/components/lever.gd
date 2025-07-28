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

# Increment speed (adjustable)
const INCREMENT_SPEED: float = 10.0 # Counters per second
const MAX_COUNT: int = 100

func _ready() -> void:
	# Initialize screen displays and set font size
	update_screens()
	# Set font size to 34 (110% increase from assumed default of 16)
	screen.add_theme_font_size_override("normal_font_size", 500)
	screen2.add_theme_font_size_override("normal_font_size", 500)
	screen3.add_theme_font_size_override("normal_font_size", 500)
	# Enable BBCode and set text alignment to center
	screen.bbcode_enabled = true
	screen2.bbcode_enabled = true
	screen3.bbcode_enabled = true

func _process(delta: float) -> void:
	# Increment counters while levers are held
	if is_holding_lever1:
		increment_counter(1, delta)
	if is_holding_lever2:
		increment_counter(2, delta)
	if is_holding_lever3:
		increment_counter(3, delta)

# Function to increment counter and update screen
func increment_counter(lever_index: int, delta: float) -> void:
	match lever_index:
		1:
			counter1 = update_counter(counter1, delta)
			screen.text = "[center]" + str(counter1) + "[/center]"
		2:
			counter2 = update_counter(counter2, delta)
			screen2.text = "[center]" + str(counter2) + "[/center]"
		3:
			counter3 = update_counter(counter3, delta)
			screen3.text = "[center]" + str(counter3) + "[/center]"

# Helper function to update counter value
func update_counter(counter: int, delta: float) -> int:
	var new_counter = counter + int(INCREMENT_SPEED * delta)
	if new_counter >= MAX_COUNT:
		new_counter = 0
	return new_counter

# Function to update all screens
func update_screens() -> void:
	screen.text = "[center]" + str(counter1) + "[/center]"
	screen2.text = "[center]" + str(counter2) + "[/center]"
	screen3.text = "[center]" + str(counter3) + "[/center]"

# Functions to be called by player script
func start_holding_lever(lever_name: String) -> void:
	print("yo gurt")
	match lever_name:
		"lever1":
			is_holding_lever1 = true
		"lever2":
			is_holding_lever2 = true
		"lever3":
			is_holding_lever3 = true

func stop_holding_lever(lever_name: String) -> void:
	print('no gurt')
	match lever_name:
		"lever1":
			is_holding_lever1 = false
		"lever2":
			is_holding_lever2 = false
		"lever3":
			is_holding_lever3 = false
