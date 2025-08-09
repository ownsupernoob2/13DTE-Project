extends Node3D

# Presentation Room Script with Typing Animation

@onready var narration_text: RichTextLabel = $UI/TextContainer/NarrationText
@onready var timer: Timer = $Timer
@onready var big_screen: MeshInstance3D = $BigScreen
@onready var screen_light: OmniLight3D = $BigScreen/ScreenLight
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

# Text messages to display (easy to modify)
var presentation_texts: Array[String] = [
	"Welcome to the Alien Containment Facility",
	"Your mission is critical to humanity's survival",
	"You will be responsible for analyzing and classifying alien specimens",
	"Follow all safety protocols at all times",
	"Failure to comply may result in containment breach",
	"Good luck, Agent..."
]

# Current message being displayed
var current_message_index: int = 0
var current_char_index: int = 0
var current_message: String = ""
var is_typing: bool = false
var typing_speed: float = 0.05  # Seconds between characters

# Screen material for red glow effect
var screen_material: StandardMaterial3D

func _ready() -> void:
	# Set mouse to visible for presentation
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	_setup_screen_material()
	_setup_text_styling()
	_connect_signals()
	_start_presentation()

func _setup_screen_material() -> void:
	# Create glowing red screen material
	screen_material = StandardMaterial3D.new()
	screen_material.albedo_color = Color(0.8, 0.1, 0.1, 1.0)  # Dark red
	screen_material.emission_enabled = true
	screen_material.emission = Color(1.0, 0.2, 0.2, 1.0)  # Bright red glow
	screen_material.emission_energy = 2.0
	screen_material.metallic = 0.1
	screen_material.roughness = 0.3
	
	big_screen.material_override = screen_material
	
	# Add screen flickering effect
	_start_screen_flicker()

func _setup_text_styling() -> void:
	# Style the narration text
	narration_text.add_theme_font_size_override("normal_font_size", 24)
	narration_text.add_theme_color_override("default_color", Color(0.9, 0.9, 0.9, 1.0))
	
	# Center align text
	narration_text.text = ""

func _connect_signals() -> void:
	timer.timeout.connect(_on_timer_timeout)

func _start_presentation() -> void:
	print("🎬 Starting presentation...")
	print("Presentation texts count: ", presentation_texts.size())
	await get_tree().create_timer(1.0).timeout  # Brief pause before starting
	_show_next_message()

func _show_next_message() -> void:
	print("📝 Showing message index: ", current_message_index, " of ", presentation_texts.size())
	
	if current_message_index >= presentation_texts.size():
		_end_presentation()
		return
	
	current_message = presentation_texts[current_message_index]
	current_char_index = 0
	is_typing = true
	
	# Clear text and start typing
	narration_text.text = ""
	timer.wait_time = typing_speed
	timer.start()
	
	print("📝 Displaying message: ", current_message)

func _on_timer_timeout() -> void:
	if not is_typing:
		return
	
	if current_char_index < current_message.length():
		# Add next character
		var display_text = current_message.substr(0, current_char_index + 1)
		narration_text.text = "[center]" + display_text + "[/center]"
		current_char_index += 1
		
		# Optional: Add typing sound effect here
		# _play_typing_sound()
	else:
		# Message complete
		is_typing = false
		timer.stop()
		
		# Wait before showing next message
		await get_tree().create_timer(2.0).timeout  # Pause between messages
		current_message_index += 1
		_show_next_message()

func _start_screen_flicker() -> void:
	# Create subtle screen flicker effect
	var flicker_tween = create_tween()
	flicker_tween.set_loops()
	flicker_tween.tween_property(screen_light, "light_energy", 1.8, 0.8)
	flicker_tween.tween_property(screen_light, "light_energy", 2.2, 1.2)
	flicker_tween.tween_property(screen_light, "light_energy", 2.0, 0.5)

func _end_presentation() -> void:
	print("🎬 Presentation complete!")
	
	# Fade out effect
	var fade_tween = create_tween()
	fade_tween.parallel().tween_property(narration_text, "modulate:a", 0.0, 1.0)
	fade_tween.parallel().tween_property(screen_light, "light_energy", 0.0, 1.0)
	
	await fade_tween.finished
	
	# Wait a moment then transition to main game
	await get_tree().create_timer(1.0).timeout
	_transition_to_game()

func _transition_to_game() -> void:
	print("🚀 Transitioning to game...")
	print("About to load: res://scenes/stage_1_tutorial.tscn")
	
	# Make sure mouse is captured for gameplay
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Load the first stage/tutorial
	var result = get_tree().change_scene_to_file("res://scenes/stage_1_tutorial.tscn")
	if result != OK:
		print("❌ Failed to load stage_1_tutorial.tscn - Error code: ", result)
		# Fallback to demo scene if tutorial doesn't exist
		print("🔄 Trying fallback to demo scene...")
		var fallback_result = get_tree().change_scene_to_file("res://scenes/demo.tscn")
		if fallback_result != OK:
			print("❌ Fallback also failed - Error code: ", fallback_result)
			print("🏠 Returning to main menu...")
			get_tree().change_scene_to_file("res://scenes/main_menu_new.tscn")
	else:
		print("✅ Successfully loading stage_1_tutorial.tscn")

# Input handling for skipping
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_skip_current_message()
		elif event.keycode == KEY_ESCAPE:
			_skip_presentation()

func _skip_current_message() -> void:
	if is_typing:
		# Complete current message instantly
		is_typing = false
		timer.stop()
		narration_text.text = "[center]" + current_message + "[/center]"
		
		# Short pause then move to next
		await get_tree().create_timer(0.5).timeout
		current_message_index += 1
		_show_next_message()

func _skip_presentation() -> void:
	print("⏭️ Skipping presentation...")
	is_typing = false
	timer.stop()
	_transition_to_game()

# Function to easily add more text messages
func add_presentation_text(new_text: String) -> void:
	presentation_texts.append(new_text)

# Function to modify existing text
func set_presentation_texts(new_texts: Array[String]) -> void:
	presentation_texts = new_texts

# Optional: Add typing sound effect
func _play_typing_sound() -> void:
	# TODO: Add a subtle typing sound effect
	# audio_player.play()
	pass
