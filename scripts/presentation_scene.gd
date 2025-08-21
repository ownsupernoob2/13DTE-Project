extends Node3D

@onready var instruction_label: Label = $UI/InstructionLabel
@onready var presentation_ui: Control = $UI/PresentationUI
@onready var narration_text: RichTextLabel = $UI/PresentationUI/NarrationText
@onready var timer: Timer = $Timer
@onready var screen_light: OmniLight3D = $PresentationScreen/ScreenLight
@onready var player: CharacterBody3D = $Player
@onready var fade_overlay: ColorRect = $UI/FadeOverlay
@onready var trigger_area: Area3D = $TriggerArea

var presentation_texts: Array[String] = [
	"Hello, 54th Divison",
	"This is the 43th week, heavy news came in",
	"5 employees have died after attempted escape",
	"You are required to do your job, work doesn't slow down",
	"Remember, humanity is at stake",
	"Your freedom is due soon, be paitent",
	"You're dismissed"
]

var current_message_index: int = 0
var current_char_index: int = 0
var current_message: String = ""
var is_typing: bool = false
var typing_speed: float = 0.04  # Faster typing effect
var presentation_active: bool = false
var can_exit: bool = false

func _ready() -> void:
	_cleanup_overlays()  # Clean up any leftover overlays from previous scenes
	_setup_scene()
	_connect_signals()
	_start_presentation_sequence()

func _setup_scene() -> void:
	# Set global flag for presentation mode
	Global.in_presentation = true
	
	## Ensure mouse is captured for camera movement
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Set up screen lighting effect
	if screen_light:
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	if trigger_area:
		trigger_area.body_entered.connect(_on_trigger_area_entered)

func _start_presentation_sequence() -> void:
	# Start with black screen, then fade in
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.color = Color.BLACK
	fade_overlay.modulate.a = 1.0  # Ensure it starts fully opaque
	fade_overlay.visible = true
	
	# Wait a moment, then fade in
	await get_tree().create_timer(1.0).timeout
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(fade_overlay, "modulate:a", 0.0, 3.0)
	await fade_in_tween.finished
	
	# Keep the overlay but make it transparent and invisible for later reuse
	# Don't hide it completely to avoid flicker when we need it again
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
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	Global.in_presentation = false
	presentation_ui.visible = false
	instruction_label.visible = true
	instruction_label.text = "Walk to exit"
	

func _start_exit_sequence() -> void:
	print("🎬 Starting exit sequence...")
	
	# Clear global presentation flag immediately
	Global.in_presentation = false
	# Reuse the existing fade overlay instead of creating a new one
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.color = Color.BLACK
		fade_overlay.z_index = 1000  # Ensure it's on top
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Fade to black using the existing overlay
		var fade_out_tween = create_tween()
		fade_out_tween.tween_property(fade_overlay, "modulate:a", 1.0, 2.0)
		await fade_out_tween.finished
	else:
		var exit_overlay = ColorRect.new()
		exit_overlay.name = "ExitFadeOverlay"
		exit_overlay.color = Color.BLACK
		exit_overlay.modulate.a = 0.0
		exit_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		exit_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		exit_overlay.z_index = 1000
		get_tree().root.add_child(exit_overlay)
		
		var fade_out_tween = create_tween()
		fade_out_tween.tween_property(exit_overlay, "modulate:a", 1.0, 2.0)
		await fade_out_tween.finished
	
	print("🎬 Fade complete, loading scene...")
	
	# Small delay to ensure fade is complete
	await get_tree().process_frame
	
	# Final cleanup before transition
	_cleanup_overlays()
	
	# Transition to game
	var result = get_tree().change_scene_to_file("res://scenes/stage_1_tutorial.tscn")
	if result != OK:
		print("❌ Failed to load tutorial - Error code: ", result)
		print("🔄 Loading demo as fallback...")
		result = get_tree().change_scene_to_file("res://scenes/demo.tscn")
		if result != OK:
			print("❌ Failed to load demo - Error code: ", result)
			# If both fail, keep the overlay visible to show error state
			print("❌ Scene transition failed completely")
	else:
		print("✅ Tutorial loaded successfully")

# Cleanup function to ensure no overlay remains
func _cleanup_overlays() -> void:
	# Clean up any remaining overlays in the root
	for child in get_tree().root.get_children():
		if child.name.contains("FadeOverlay") or child.name.contains("ExitFadeOverlay"):
			print("🧹 Cleaning up remaining overlay: ", child.name)
			child.queue_free()

func _on_trigger_area_entered(body: Node3D) -> void:
	# Check if it's the player and if they can exit
	if body == player and can_exit:
		print("🎬 Player reached exit trigger - starting transition...")
		_start_exit_sequence()

func _input(event: InputEvent) -> void:
	# Only handle keyboard input for skipping, don't interfere with mouse
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if presentation_active and is_typing:
				_skip_current_message()
				# Make sure we don't consume the event for other systems
				get_viewport().set_input_as_handled()
