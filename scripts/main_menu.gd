extends Control

# Dark Horror-Style Main Menu with Arrow Key Navigation

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var continue_button: Button = $VBoxContainer/MenuButtons/ContinueButton
@onready var new_game_button: Button = $VBoxContainer/MenuButtons/NewGameButton
@onready var options_button: Button = $VBoxContainer/MenuButtons/OptionsButton
@onready var quit_button: Button = $VBoxContainer/MenuButtons/QuitButton
@onready var background: ColorRect = $Background
@onready var ambient_sound: AudioStreamPlayer = $AmbientSound
@onready var selection_indicator: Label = $VBoxContainer/SelectionIndicator

# Presentation overlay - no longer needed with 3D presentation scene
# var presentation_overlay: Control = null

# Horror-style colors and effects
var dark_brown = Color(0.15, 0.12, 0.08)
var gold = Color(0.9, 0.7, 0.3)
var red = Color(0.7, 0.2, 0.1)
var disabled_color = Color(0.5, 0.5, 0.5)  # Updated to lighter grey
var selected_color = Color(1.0, 1.0, 1.0)  # Pure white for selected
var normal_color = Color(0.85, 0.85, 0.85)  # Light grey for normal buttons

# Menu navigation
var current_button_index: int = 0
var menu_buttons: Array[Button] = []

func _ready() -> void:
	# Hide mouse cursor for keyboard-only navigation
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Ensure we always start on NEW GAME
	current_button_index = 0
	
	_setup_button_array()
	_setup_button_styles()
	_check_continue_availability()
	_connect_buttons()
	_start_ambient_effects()
	
	# Defer the initial selection update until after the UI layout is complete
	call_deferred("_update_button_selection")
	# Add a small additional delay to ensure proper positioning
	get_tree().create_timer(0.1).timeout.connect(_update_selection_indicator)
	

func _setup_button_array() -> void:
	menu_buttons = [new_game_button, continue_button, options_button, quit_button]

func _setup_button_styles() -> void:
	# Apply bold, bigger text styling to all buttons
	for button in menu_buttons:
		_style_horror_button(button)

func _navigate_menu(direction: int) -> void:
	# Find next valid button
	var attempts = 0
	
	while attempts < menu_buttons.size():
		current_button_index += direction
		current_button_index = current_button_index % menu_buttons.size()
		if current_button_index < 0:
			current_button_index = menu_buttons.size() - 1
		
		# Skip disabled buttons
		if not menu_buttons[current_button_index].disabled:
			break
			
		attempts += 1
	
	_update_button_selection()

func _update_button_selection() -> void:
	# Keep button text consistent - no arrows or prefixes
	for i in range(menu_buttons.size()):
		var button = menu_buttons[i]
		var base_text = ""
		
		# Get base text without any prefixes
		match i:
			0: base_text = "NEW GAME"
			1: base_text = "CONTINUE"
			2: base_text = "OPTIONS"
			3: base_text = "QUIT"
		
		# Set clean text without any arrows or spaces
		button.text = base_text
		
		# Ensure left alignment
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		if button.disabled:
			button.add_theme_color_override("font_color", disabled_color)
		else:
			button.add_theme_color_override("font_color", normal_color)
		
		# Keep all buttons at normal scale
		button.scale = Vector2(1.0, 1.0)
	
	# Highlight selected button (but don't scale it)
	var selected_button = menu_buttons[current_button_index]
	if not selected_button.disabled:
		selected_button.add_theme_color_override("font_color", selected_color)
	
	# Update selection indicator if it exists
	_update_selection_indicator()

func _update_selection_indicator() -> void:
	# Update the selection indicator position and visibility
	if selection_indicator and current_button_index < menu_buttons.size():
		var selected_button = menu_buttons[current_button_index]
		
		# Set the indicator text
		selection_indicator.text = ">"
		
		# The SelectionIndicator is in the main VBoxContainer, but we need to align it
		# with buttons in the MenuButtons sub-container
		var menu_buttons_container = selected_button.get_parent()
		
		# Get the actual button size and position
		var button_height = selected_button.size.y if selected_button.size.y > 0 else 40
		var separator_height = 8  # From theme_override_constants/separation in MenuButtons
		
		# Calculate the position within the MenuButtons container
		var button_offset_in_menu_container = current_button_index * (button_height + separator_height)
		
		# The SelectionIndicator needs to account for:
		# 1. The MenuButtons container position relative to the main VBoxContainer
		# 2. The selected button position within MenuButtons
		var menu_buttons_position = menu_buttons_container.position.y
		var target_y = menu_buttons_position + button_offset_in_menu_container + (button_height / 2) - (selection_indicator.size.y / 2)
		
		# Position the indicator
		selection_indicator.position.y = target_y
		selection_indicator.position.x = -30  # Offset to the left of the buttons
		
		# Always show the indicator for enabled buttons
		selection_indicator.visible = not selected_button.disabled

func _activate_current_button() -> void:
	var button = menu_buttons[current_button_index]
	if not button.disabled:
		button.pressed.emit()
	# Dark background
	background.color = dark_brown
	



func _style_horror_button(button: Button) -> void:
	# Horror-style button appearance with bold, bigger text
	button.add_theme_color_override("font_color", normal_color)
	button.add_theme_font_size_override("font_size", 54)  # Bigger text
	
	# Create a bold font theme if possible
	var theme = button.get_theme()
	if theme == null:
		theme = Theme.new()
		button.theme = theme
	
	# Try to set bold font (you may need to load a bold font resource)
	# For now, we'll increase the font size and use theme overrides
	button.flat = true  # Remove button background
	
	# Remove mouse interaction
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _check_continue_availability() -> void:
	if SaveSystem.can_continue():
		continue_button.disabled = false
		continue_button.text = "CONTINUE"
	else:
		continue_button.disabled = true
		continue_button.text = "CONTINUE"

func _connect_buttons() -> void:
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_pressed)
	if options_button:
		options_button.pressed.connect(_on_options_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _start_ambient_effects() -> void:
	# Set up ambient sound pitch to stay at 0.6 for 4 seconds, then increase over 2 seconds
	if ambient_sound:
		ambient_sound.pitch_scale = 0.6
		
		# Wait 4 seconds, then start a 2-second pitch increase
		await get_tree().create_timer(4.0).timeout  # Stay at 0.6 for 4 seconds
		
		# Now create the pitch increase tween
		var pitch_tween = create_tween()
		pitch_tween.tween_property(ambient_sound, "pitch_scale", 0.9, 3.5)  # Increase over 2 seconds
		# No looping - pitch will stay at 0.9 after this completes
		
	# Start the flickering effect immediately
	_start_flickering_effect()
		
func _start_flickering_effect() -> void:
	# Renamed function to be more specific - handles title flickering
	if title_label:
		var flicker_tween = create_tween()
		flicker_tween.set_loops()
		flicker_tween.tween_property(title_label, "modulate:a", 0.7, 3.0)
		flicker_tween.tween_property(title_label, "modulate:a", 1.0, 2.0)



func _on_continue_pressed() -> void:
	if SaveSystem.can_continue():
		var stage = SaveSystem.get_highest_stage()
		print("📁 Loading stage ", stage)
		
		var stage_scenes = [
			"res://scenes/stage_1_tutorial.tscn",
			"res://scenes/stage_2_easy.tscn", 
			"res://scenes/stage_3_easy.tscn",
			"res://scenes/stage_4_medium.tscn",
			"res://scenes/stage_5_hard.tscn"
		]
		
		if stage <= stage_scenes.size():
			get_tree().change_scene_to_file(stage_scenes[stage - 1])
		else:
			# Fallback to demo scene
			get_tree().change_scene_to_file("res://scenes/demo.tscn")

func _on_new_game_pressed() -> void:
	print("🆕 Starting new game")
	
	# For debugging: Always start new game directly
	print("🆕 Bypassing confirmation dialog for testing")
	_start_new_game()
	
	# Original logic - re-enable after testing:
	# if SaveSystem.can_continue():
	#     _show_new_game_confirmation()
	# else:
	#     _start_new_game()

func _show_new_game_confirmation() -> void:
	# Create custom confirmation dialog with arrow key navigation
	var confirmation_overlay = ColorRect.new()
	confirmation_overlay.name = "ConfirmationOverlay"
	confirmation_overlay.anchors_preset = Control.PRESET_FULL_RECT
	confirmation_overlay.color = Color(0, 0, 0, 0.8)  # Dark overlay
	add_child(confirmation_overlay)
	
	# Main container
	var dialog_container = VBoxContainer.new()
	dialog_container.anchors_preset = Control.PRESET_CENTER
	dialog_container.position = Vector2(-200, -100)
	dialog_container.size = Vector2(400, 200)
	confirmation_overlay.add_child(dialog_container)
	
	# Background panel
	var panel = Panel.new()
	panel.size = Vector2(400, 200)
	panel.position = Vector2(0, 0)
	dialog_container.add_child(panel)
	
	# Title label
	var dialog_title = Label.new()
	dialog_title.text = "CONFIRM NEW GAME"
	dialog_title.add_theme_font_size_override("font_size", 20)
	dialog_title.add_theme_color_override("font_color", gold)
	dialog_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_title.size = Vector2(400, 40)
	dialog_title.position = Vector2(0, 20)
	dialog_container.add_child(dialog_title)
	
	# Message label
	var message_label = Label.new()
	message_label.text = "Starting a new game will erase your current progress.\nAre you sure you want to continue?"
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.size = Vector2(380, 80)
	message_label.position = Vector2(10, 60)
	dialog_container.add_child(message_label)
	
	# Button container
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 40)
	button_container.size = Vector2(400, 40)
	button_container.position = Vector2(0, 150)
	dialog_container.add_child(button_container)
	
	# Yes button
	var yes_button = Label.new()
	yes_button.name = "YesButton"
	yes_button.text = "  YES"
	yes_button.add_theme_font_size_override("font_size", 18)  # Bigger text
	yes_button.add_theme_color_override("font_color", normal_color)
	button_container.add_child(yes_button)
	
	# No button
	var no_button = Label.new()
	no_button.name = "NoButton"
	no_button.text = "  NO"
	no_button.add_theme_font_size_override("font_size", 18)  # Bigger text
	no_button.add_theme_color_override("font_color", normal_color)
	button_container.add_child(no_button)
	
	# Set up confirmation dialog state
	confirmation_overlay.set_meta("selected_index", 0)  # Start with "YES" selected
	confirmation_overlay.set_meta("buttons", [yes_button, no_button])
	_update_confirmation_selection(confirmation_overlay)
	
	# Connect input handling
	confirmation_overlay.set_process_input(true)

func _update_confirmation_selection(overlay: ColorRect) -> void:
	var buttons = overlay.get_meta("buttons") as Array
	var selected_index = overlay.get_meta("selected_index") as int
	
	# Reset all buttons
	for i in range(buttons.size()):
		var button = buttons[i] as Label
		if i == selected_index:
			button.add_theme_color_override("font_color", selected_color)
			button.scale = Vector2(1.1, 1.1)
			# Add selection arrow
			if i == 0:
				button.text = "> YES"
			else:
				button.text = "> NO"
		else:
			button.add_theme_color_override("font_color", normal_color)
			button.scale = Vector2(1.0, 1.0)
			# Remove arrow
			if i == 0:
				button.text = "  YES"
			else:
				button.text = "  NO"

func _input(event: InputEvent) -> void:
	# Check if confirmation dialog is active
	var confirmation_overlay = get_node_or_null("ConfirmationOverlay")
	if confirmation_overlay:
		_handle_confirmation_input(event, confirmation_overlay)
		return  # Don't handle normal menu input while dialog is open
	
	# Normal menu input handling
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				_navigate_menu(-1)
			KEY_DOWN:
				_navigate_menu(1)
			KEY_ENTER, KEY_SPACE:
				_activate_current_button()

func _handle_confirmation_input(event: InputEvent, overlay: ColorRect) -> void:
	if event is InputEventKey and event.pressed:
		var selected_index = overlay.get_meta("selected_index") as int
		
		match event.keycode:
			KEY_LEFT, KEY_RIGHT:
				# Toggle between YES and NO
				selected_index = 1 - selected_index  # Switch between 0 and 1
				overlay.set_meta("selected_index", selected_index)
				_update_confirmation_selection(overlay)
			
			KEY_ENTER, KEY_SPACE:
				# Confirm selection
				if selected_index == 0:  # YES
					_confirm_new_game(overlay)
				else:  # NO
					_cancel_new_game(overlay)
			
			KEY_ESCAPE:
				# Cancel
				_cancel_new_game(overlay)

func _confirm_new_game(overlay: ColorRect) -> void:
	overlay.queue_free()
	_start_new_game()

func _cancel_new_game(overlay: ColorRect) -> void:
	overlay.queue_free()
	# Return focus to menu
	_update_button_selection()

func _start_new_game() -> void:
	print("🎮 _start_new_game called - starting scene transition...")
	SaveSystem.reset_progress()
	print("🎮 Save system reset complete")
	
	# First try the fixed scene, then fallback to original
	var scene_paths = [
		"res://scenes/presentation_scene_fixed.tscn",
		"res://scenes/presentation_scene.tscn"
	]
	
	var scene_loaded = false
	for scene_path in scene_paths:
		print("🔄 Attempting to load: ", scene_path)
		var result = get_tree().change_scene_to_file(scene_path)
		print("🔄 change_scene_to_file returned: ", result)
		if result == OK:
			print("✅ Successfully loaded: ", scene_path)
			scene_loaded = true
			break
	if not scene_loaded:
		var fallback_result = get_tree().change_scene_to_file("res://scenes/stage_1_tutorial.tscn")
		if fallback_result != OK:
			get_tree().change_scene_to_file("res://scenes/demo.tscn")

func _on_options_pressed() -> void:
	# Fade out ambient sound
	if ambient_sound:
		var tween = create_tween()
		tween.tween_property(ambient_sound, "volume_db", -80.0, 0.5)
		tween.tween_callback(ambient_sound.stop)
	
	# Navigate to options menu
	get_tree().change_scene_to_file("res://scenes/options_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
