extends Node3D

@onready var instruction_label: Label = $UI/InstructionLabel
@onready var presentation_ui: Control = $UI/PresentationUI
@onready var narration_text: RichTextLabel = $UI/PresentationUI/NarrationText
@onready var timer: Timer = $Timer
@onready var screen_light: OmniLight3D = $PresentationScreen/ScreenLight
@onready var player: CharacterBody3D = $Player
@onready var fade_overlay: ColorRect = $UI/FadeOverlay

var presentation_texts: Array[String] = [
	"Welcome to Site-47 Processing Division.",
	"Your job: Classify each specimen for resource allocation.",
	"This isn't for the weak, if you can't handle death...",
	"Leave."
]

var current_message_index: int = 0
var current_char_index: int = 0
var current_message: String = ""
var is_typing: bool = false
var typing_speed: float = 0.08  # Slower for more dramatic effect
var presentation_active: bool = false
var can_exit: bool = false

func _ready() -> void:
	_setup_scene()
	_connect_signals()
	_start_presentation_sequence()

func _setup_scene() -> void:
	# Disable player movement initially but keep camera active
	if player:
		player.set_physics_process(false)
		# Don't disable input - let camera work
	
	# Set up screen lighting effect
	if screen_light:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(screen_light, "light_energy", 3.0, 3.0)
		tween.tween_property(screen_light, "light_energy", 1.5, 3.0)
	
	# Hide instruction label and presentation UI initially
	instruction_label.visible = false
	presentation_ui.visible = false
	narration_text.text = ""
	
	print("🎬 Presentation hall ready - fade in starting...")

func _connect_signals() -> void:
	if timer:
		timer.timeout.connect(_on_timer_timeout)

func _start_presentation_sequence() -> void:
	# Start with black screen, then fade in
	fade_overlay.color = Color.BLACK
	fade_overlay.modulate.a = 1.0  # Ensure it starts fully opaque
	fade_overlay.visible = true
	
	# Wait a moment, then fade in
	await get_tree().create_timer(1.0).timeout
	
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(fade_overlay, "modulate:a", 0.0, 3.0)
	await fade_in_tween.finished
	
	# Completely hide and disable the fade overlay
	fade_overlay.visible = false
	fade_overlay.modulate.a = 0.0
	
	# Wait another moment for atmosphere, then start presentation
	await get_tree().create_timer(2.0).timeout
	_start_presentation()

func _start_presentation() -> void:
	print("🎬 Starting corporate presentation...")
	presentation_active = true
	presentation_ui.visible = true
	
	current_message_index = 0
	await get_tree().create_timer(1.0).timeout
	_show_next_message()

func _show_next_message() -> void:
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
	if not is_typing or not presentation_active:
		return
	
	if current_char_index < current_message.length():
		# Add next character - no background
		var display_text = current_message.substr(0, current_char_index + 1)
		narration_text.text = "[center]" + display_text + "[/center]"
		current_char_index += 1
	else:
		# Message complete, pause then next
		is_typing = false
		timer.stop()
		await get_tree().create_timer(3.0).timeout  # Longer pause for dramatic effect
		if presentation_active:  # Check if still active
			current_message_index += 1
			_show_next_message()

func _skip_current_message() -> void:
	if is_typing and presentation_active:
		# Complete current message instantly
		is_typing = false
		timer.stop()
		narration_text.text = "[center]" + current_message + "[/center]"
		
		# Short pause then move to next
		await get_tree().create_timer(0.5).timeout
		if presentation_active:  # Check if still active
			current_message_index += 1
			_show_next_message()

func _end_presentation() -> void:
	print("🎬 Presentation complete - enabling player exit...")
	presentation_active = false
	can_exit = true
	
	# Re-enable player movement and ensure camera is working
	if player:
		player.set_physics_process(true)
		# Make sure input is enabled
		player.set_process_input(true)
		player.set_process_unhandled_input(true)
	
	# Clear presentation UI
	presentation_ui.visible = false
	
	# Show exit instruction
	instruction_label.visible = true
	instruction_label.text = "Walk to the exit to begin your assignment"
	
	# Wait for player to move away, then transition
	await get_tree().create_timer(2.0).timeout
	_start_exit_sequence()

func _start_exit_sequence() -> void:
	print("🎬 Starting exit sequence...")
	
	# Ensure our scene's fade overlay is completely hidden
	if fade_overlay:
		fade_overlay.visible = false
		fade_overlay.modulate.a = 0.0
	
	# Create a fresh fade overlay for exit
	var exit_overlay = ColorRect.new()
	exit_overlay.name = "ExitFadeOverlay"
	exit_overlay.color = Color.BLACK
	exit_overlay.modulate.a = 0.0
	exit_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	exit_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input
	get_tree().root.add_child(exit_overlay)
	
	# Fade to black
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(exit_overlay, "modulate:a", 1.0, 2.0)
	await fade_out_tween.finished
	
	print("🎬 Fade complete, loading scene...")
	
	# Transition to game - scene change will clean up this overlay automatically
	var result = get_tree().change_scene_to_file("res://scenes/stage_1_tutorial.tscn")
	if result != OK:
		print("❌ Failed to load tutorial - Error code: ", result)
		print("🔄 Loading demo as fallback...")
		result = get_tree().change_scene_to_file("res://scenes/demo.tscn")
		if result != OK:
			print("❌ Failed to load demo - Error code: ", result)
	else:
		print("✅ Tutorial loaded successfully")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if presentation_active and is_typing:
				_skip_current_message()
