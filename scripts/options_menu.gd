extends Control

# Options Menu Script - Matches main menu style

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var mouse_sensitivity_slider: HSlider = $VBoxContainer/OptionsContainer/MouseSensitivityContainer/MouseSensitivitySlider
@onready var mouse_sensitivity_label: Label = $VBoxContainer/OptionsContainer/MouseSensitivityContainer/MouseSensitivityLabel
@onready var mouse_sensitivity_value: Label = $VBoxContainer/OptionsContainer/MouseSensitivityContainer/MouseSensitivityValue
@onready var master_volume_slider: HSlider = $VBoxContainer/OptionsContainer/MasterVolumeContainer/MasterVolumeSlider
@onready var master_volume_label: Label = $VBoxContainer/OptionsContainer/MasterVolumeContainer/MasterVolumeLabel
@onready var master_volume_value: Label = $VBoxContainer/OptionsContainer/MasterVolumeContainer/MasterVolumeValue
@onready var music_volume_slider: HSlider = $VBoxContainer/OptionsContainer/MusicVolumeContainer/MusicVolumeSlider
@onready var music_volume_label: Label = $VBoxContainer/OptionsContainer/MusicVolumeContainer/MusicVolumeLabel
@onready var music_volume_value: Label = $VBoxContainer/OptionsContainer/MusicVolumeContainer/MusicVolumeValue
@onready var sfx_volume_slider: HSlider = $VBoxContainer/OptionsContainer/SFXVolumeContainer/SFXVolumeSlider
@onready var sfx_volume_label: Label = $VBoxContainer/OptionsContainer/SFXVolumeContainer/SFXVolumeLabel
@onready var sfx_volume_value: Label = $VBoxContainer/OptionsContainer/SFXVolumeContainer/SFXVolumeValue
@onready var background: ColorRect = $Background
@onready var selection_indicator: Label = $VBoxContainer/SelectionIndicator

# Horror-style colors matching main menu
var dark_brown = Color(0.15, 0.12, 0.08)
var gold = Color(0.9, 0.7, 0.3)
var red = Color(0.7, 0.2, 0.1)
var disabled_color = Color(0.5, 0.5, 0.5)
var selected_color = Color(1.0, 1.0, 1.0)  # Pure white for selected
var normal_color = Color(0.85, 0.85, 0.85)  # Light grey for normal

# Navigation
var current_option_index: int = 0
var option_controls: Array = []

# Settings storage
var settings: Dictionary = {
	"mouse_sensitivity": 1.0,
	"master_volume": 0.8,
	"music_volume": 0.8,
	"sfx_volume": 0.8
}

func _ready() -> void:
	# Hide mouse cursor to match main menu style
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	_setup_option_controls()
	_load_settings()
	_connect_signals()
	_update_ui_values()
	_apply_horror_styling()
	
	# Don't change background color - let scene handle it
	
	# Defer initial selection
	call_deferred("_update_selection")

func _setup_option_controls() -> void:
	# Array of controls that can be navigated
	option_controls = [
		mouse_sensitivity_slider,
		master_volume_slider,
		music_volume_slider,
		sfx_volume_slider,
		back_button
	]

func _connect_signals() -> void:
	# Connect sliders
	mouse_sensitivity_slider.value_changed.connect(_on_mouse_sensitivity_changed)
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Connect back button
	back_button.pressed.connect(_on_back_pressed)

func _apply_horror_styling() -> void:
	# Don't override fonts and colors - let the scene handle styling
	# This preserves the user's custom font and color choices
	pass

func _input(event: InputEvent) -> void:
	# Use same input handling as main menu to prevent multiple changes
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				_navigate_options(-1)
			KEY_DOWN:
				_navigate_options(1)
			KEY_LEFT:
				_adjust_current_option(-0.1)
			KEY_RIGHT:
				_adjust_current_option(0.1)
			KEY_ENTER, KEY_SPACE:
				_activate_current_option()

func _navigate_options(direction: int) -> void:
	current_option_index += direction
	current_option_index = clamp(current_option_index, 0, option_controls.size() - 1)
	_update_selection()

func _adjust_current_option(amount: float) -> void:
	var current_control = option_controls[current_option_index]
	if current_control is HSlider:
		var slider = current_control as HSlider
		slider.value = clamp(slider.value + amount, slider.min_value, slider.max_value)

func _activate_current_option() -> void:
	var current_control = option_controls[current_option_index]
	if current_control is Button:
		current_control.pressed.emit()

func _update_selection() -> void:
	# Reset all styling to normal without overriding fonts
	for i in range(option_controls.size()):
		var control = option_controls[i]
		if control is Button:
			control.add_theme_color_override("font_color", normal_color)
		elif control is HSlider:
			# Find the label for this slider and reset its color to normal
			var container = control.get_parent()
			if container.has_method("get_children"):
				for child in container.get_children():
					if child is Label and child.name.ends_with("Label"):
						child.add_theme_color_override("font_color", normal_color)
	
	# Highlight current selection
	var current_control = option_controls[current_option_index]
	if current_control is Button:
		current_control.add_theme_color_override("font_color", selected_color)
	elif current_control is HSlider:
		# Find and highlight the label for this slider
		var container = current_control.get_parent()
		if container.has_method("get_children"):
			for child in container.get_children():
				if child is Label and child.name.ends_with("Label"):
					child.add_theme_color_override("font_color", selected_color)
	
	# Update selection indicator position
	_update_selection_indicator()

func _update_selection_indicator() -> void:
	# Copy the positioning method from main menu
	if selection_indicator and current_option_index < option_controls.size():
		var current_control = option_controls[current_option_index]
		selection_indicator.text = ">"
		
		# Get the container that holds our current control
		var control_container = current_control.get_parent()
		var options_container = control_container.get_parent()  # This should be OptionsContainer
		
		# Calculate position similar to main menu method
		var control_height = 57  # Approximate height including spacing
		var separator_height = 25  # From theme_override_constants/separation in OptionsContainer
		
		# Calculate the position within the OptionsContainer
		var control_offset_in_container = current_option_index * (control_height + separator_height)
		
		# The SelectionIndicator needs to account for:
		# 1. The OptionsContainer position relative to the main VBoxContainer
		# 2. The selected control position within OptionsContainer
		var options_container_position = options_container.position.y
		var target_y = options_container_position + control_offset_in_container + (control_height / 2) - (selection_indicator.size.y / 2)
		
		# Position the indicator
		selection_indicator.position.y = target_y
		selection_indicator.position.x = -30  # Offset to the left
		selection_indicator.visible = true

# Settings management
func _load_settings() -> void:
	# Load from file or use defaults
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		settings["mouse_sensitivity"] = config.get_value("gameplay", "mouse_sensitivity", 1.0)
		settings["master_volume"] = config.get_value("audio", "master_volume", 0.8)
		settings["music_volume"] = config.get_value("audio", "music_volume", 0.8)
		settings["sfx_volume"] = config.get_value("audio", "sfx_volume", 0.8)

func _save_settings() -> void:
	var config = ConfigFile.new()
	
	config.set_value("gameplay", "mouse_sensitivity", settings["mouse_sensitivity"])
	config.set_value("audio", "master_volume", settings["master_volume"])
	config.set_value("audio", "music_volume", settings["music_volume"])
	config.set_value("audio", "sfx_volume", settings["sfx_volume"])
	
	config.save("user://settings.cfg")

func _update_ui_values() -> void:
	# Update sliders
	mouse_sensitivity_slider.value = settings["mouse_sensitivity"]
	master_volume_slider.value = settings["master_volume"]
	music_volume_slider.value = settings["music_volume"]
	sfx_volume_slider.value = settings["sfx_volume"]
	
	# Update value labels
	mouse_sensitivity_value.text = "%.2f" % settings["mouse_sensitivity"]
	master_volume_value.text = "%d%%" % (settings["master_volume"] * 100)
	music_volume_value.text = "%d%%" % (settings["music_volume"] * 100)
	sfx_volume_value.text = "%d%%" % (settings["sfx_volume"] * 100)

# Signal handlers
func _on_mouse_sensitivity_changed(value: float) -> void:
	settings["mouse_sensitivity"] = value
	mouse_sensitivity_value.text = "%.2f" % value
	_save_settings()
	# Immediately apply the new sensitivity
	Global.reload_settings()

func _on_master_volume_changed(value: float) -> void:
	settings["master_volume"] = value
	master_volume_value.text = "%d%%" % (value * 100)
	
	# Apply to master bus
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	_save_settings()

func _on_music_volume_changed(value: float) -> void:
	settings["music_volume"] = value
	music_volume_value.text = "%d%%" % (value * 100)
	
	# Apply to music bus (create if doesn't exist)
	var music_bus_index = AudioServer.get_bus_index("Music")
	if music_bus_index == -1:
		AudioServer.add_bus()
		music_bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(music_bus_index, "Music")
	AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(value))
	_save_settings()

func _on_sfx_volume_changed(value: float) -> void:
	settings["sfx_volume"] = value
	sfx_volume_value.text = "%d%%" % (value * 100)
	
	# Apply to SFX bus (create if doesn't exist)
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	if sfx_bus_index == -1:
		AudioServer.add_bus()
		sfx_bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_bus_index, "SFX")
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(value))
	_save_settings()

func _on_back_pressed() -> void:
	# Return to main menu and ensure mouse mode matches main menu
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().change_scene_to_file("res://scenes/main_menu_new.tscn")

# Public function to get mouse sensitivity for other scripts
static func get_mouse_sensitivity() -> float:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		return config.get_value("gameplay", "mouse_sensitivity", 1.0)
	return 1.0
