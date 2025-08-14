extends Node3D

@onready var handle: MeshInstance3D = $lever1/Handle
@onready var handle2: MeshInstance3D = $lever2/Handle2
@onready var handle3: MeshInstance3D = $lever3/Handle3
@onready var screen = $lever1/Quad/SubViewport/Control/RichTextLabel
@onready var screen2 = $lever2/Quad/SubViewport/Control/RichTextLabel
@onready var screen3 = $lever3/Quad/SubViewport/Control/RichTextLabel

# Counter values for each lever (0-100 system)
var counter1: int = 0
var counter2: int = 0
var counter3: int = 0

# Track which lever is being held
var is_holding_lever1: bool = false
var is_holding_lever2: bool = false
var is_holding_lever3: bool = false

# Sedation system
var is_sedated: bool = false
var sedation_button_pressed: bool = false

# Visual indicators
@onready var sedation_indicator: Node3D = null  # Will be set up for visual feedback
@onready var button_animation_player: AnimationPlayer = null
@onready var button_audio_player: AudioStreamPlayer3D = null

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
	
	# Try to get optional animation and audio players
	button_animation_player = get_node_or_null("SedateButton/ButtonAnimationPlayer")
	button_audio_player = get_node_or_null("SedateButton/ButtonAudioPlayer")
	
	# Verify node references
	if !screen or !screen2 or !screen3:
		push_error("One or more screen nodes are not found!")
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
	
	# Update font size based on value (smaller font for 100 to fit better)
	var font_size = BASE_FONT_SIZE
	if value == 100:
		font_size = int(BASE_FONT_SIZE * 0.75)  # 25% smaller for 100
	screen_node.add_theme_font_size_override("normal_font_size", font_size)
	
	# Update handle rotation (starts at MIN_ROTATION_DEGREES for 0, goes to MAX_ROTATION_DEGREES for 100)
	var rotation_range = MAX_ROTATION_DEGREES - MIN_ROTATION_DEGREES
	var rotation_z = MIN_ROTATION_DEGREES + (float(value) / MAX_VALUE) * rotation_range
	handle_node.rotation.z = deg_to_rad(rotation_z)
	
	# Update screen text
	screen_node.text = "[center]" + str(value) + "[/center]"
	
	print("Lever ", lever_index, " value updated to: ", value, " rotation: ", rad_to_deg(rotation_z), " degrees")

# Function to update all screens and handle rotations
func update_screens() -> void:
	# Update font sizes based on values (smaller font for 100)
	var font_size1 = BASE_FONT_SIZE if counter1 != 100 else int(BASE_FONT_SIZE * 0.75)
	var font_size2 = BASE_FONT_SIZE if counter2 != 100 else int(BASE_FONT_SIZE * 0.75)
	var font_size3 = BASE_FONT_SIZE if counter3 != 100 else int(BASE_FONT_SIZE * 0.75)
	
	screen.add_theme_font_size_override("normal_font_size", font_size1)
	screen2.add_theme_font_size_override("normal_font_size", font_size2)
	screen3.add_theme_font_size_override("normal_font_size", font_size3)
	
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
	is_sedated = false
	sedation_button_pressed = false

# Handle sedation button press
func press_sedation_button() -> void:
	if sedation_button_pressed:
		print("Sedation already administered!")
		return
	
	sedation_button_pressed = true
	print("💉 Sedation button pressed - administering sedation...")
	
	# Play button sound
	if button_audio_player:
		button_audio_player.play()
	
	# Play button press animation
	_animate_button_press()
	
	# Show visual indication that sedation is working
	_show_sedation_success()
	
	# Mark as sedated
	is_sedated = true
	print("✓ Sedation system activated!")
	print("✓ The player should now check if the combination is correct by looking at the monitor.")
	print("✓ If correct, success feedback will be shown. If wrong, the game will restart.")

# Animate the button press
func _animate_button_press() -> void:
	if button_animation_player:
		print("🎬 Playing button press animation")
		button_animation_player.play("ButtonPress")
	else:
		print("⚠️ Button animation player not found - using fallback tween")
		# Fallback to tween if AnimationPlayer not available
		var button_node = get_node_or_null("SedateButton/button")
		if not button_node:
			print("Button node not found for animation!")
			return
		
		# Create button press animation using tween
		var tween = create_tween()
		var original_position = button_node.position
		var pressed_position = original_position + Vector3(0, -0.02, 0)  # Move down 2cm
		
		# Press down
		tween.tween_property(button_node, "position", pressed_position, 0.1)
		# Hold briefly
		tween.tween_interval(0.1)
		# Release back up
		tween.tween_property(button_node, "position", original_position, 0.1)

# Show visual indication of successful sedation
func _show_sedation_success() -> void:
	print("💚 Sedation administered - awaiting validation...")
	
	# Flash all screens blue briefly to indicate sedation in progress
	for screen_node in [screen, screen2, screen3]:
		if screen_node:
			var original_color = screen_node.get_theme_color("default_color")
			screen_node.add_theme_color_override("default_color", Color.CYAN)
			
			# Create timer to restore original color
			var timer = Timer.new()
			timer.wait_time = 2.0
			timer.one_shot = true
			add_child(timer)
			timer.timeout.connect(func(): 
				if is_instance_valid(screen_node):
					screen_node.add_theme_color_override("default_color", original_color)
				if is_instance_valid(timer):
					timer.queue_free()
			)
			timer.start()

# Show success when sedation is validated as correct
func show_sedation_validated() -> void:
	print("💚 SEDATION SUCCESSFUL! Alien is properly sedated.")
	
	# Flash all screens green to indicate success
	for screen_node in [screen, screen2, screen3]:
		if screen_node:
			var original_color = screen_node.get_theme_color("default_color")
			screen_node.add_theme_color_override("default_color", Color.GREEN)
			
			# Create timer to restore original color
			var timer = Timer.new()
			timer.wait_time = 3.0
			timer.one_shot = true
			add_child(timer)
			timer.timeout.connect(func(): 
				if is_instance_valid(screen_node):
					screen_node.add_theme_color_override("default_color", original_color)
				if is_instance_valid(timer):
					timer.queue_free()
			)
			timer.start()

# Check if sedation has been administered
func is_alien_sedated() -> bool:
	return is_sedated
