extends Control

# UI Elements
@onready var selection_indicator: Label = $VBoxContainer/SelectionIndicator
@onready var mouse_sensitivity_slider: HSlider = $VBoxContainer/OptionsContainer/MouseSensitivityContainer/MouseSensitivitySlider
@onready var mouse_sensitivity_value: Label = $VBoxContainer/OptionsContainer/MouseSensitivityContainer/MouseSensitivityValue
@onready var master_volume_slider: HSlider = $VBoxContainer/OptionsContainer/MasterVolumeContainer/MasterVolumeSlider
@onready var master_volume_value: Label = $VBoxContainer/OptionsContainer/MasterVolumeContainer/MasterVolumeValue
@onready var music_volume_slider: HSlider = $VBoxContainer/OptionsContainer/MusicVolumeContainer/MusicVolumeSlider
@onready var music_volume_value: Label = $VBoxContainer/OptionsContainer/MusicVolumeContainer/MusicVolumeValue
@onready var sfx_volume_slider: HSlider = $VBoxContainer/OptionsContainer/SfxVolumeContainer/SfxVolumeSlider
@onready var sfx_volume_value: Label = $VBoxContainer/OptionsContainer/SfxVolumeContainer/SfxVolumeValue
@onready var back_button: Button = $VBoxContainer/OptionsContainer/BackButton
@onready var ambient_sound: AudioStreamPlayer = $AmbientSound

# Settings data
var settings_data = {
	"mouse_sensitivity": 1.0,
	"master_volume": 70.0,
	"music_volume": 50.0,
	"sfx_volume": 80.0
}

# Menu navigation
var current_option_index: int = 0
var option_controls: Array = []

# Audio bus indices
var master_bus_index: int
var music_bus_index: int
var sfx_bus_index: int

func _ready() -> void:
	# Hide mouse cursor for keyboard-only navigation
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Set up audio buses
	_setup_audio_buses()
	
	# Set up navigation controls
	_setup_option_controls()
	
	# Load saved settings
	_load_settings()
	
	# Connect signals
	_connect_signals()
	
	# Apply initial settings
	_apply_all_settings()
	
	# Start ambient sound progression
	_start_ambient_effects()
	
	# Update initial selection
	call_deferred("_update_selection")

func _setup_audio_buses() -> void:
	# Get or create audio buses
	master_bus_index = AudioServer.get_bus_index("Master")
	
	# Create Music bus if it doesn't exist
	music_bus_index = AudioServer.get_bus_index("Music")
	if music_bus_index == -1:
		AudioServer.add_bus()
		music_bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(music_bus_index, "Music")
		AudioServer.set_bus_send(music_bus_index, "Master")
	
	# Create SFX bus if it doesn't exist
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	if sfx_bus_index == -1:
		AudioServer.add_bus()
		sfx_bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_bus_index, "SFX")
		AudioServer.set_bus_send(sfx_bus_index, "Master")

func _setup_option_controls() -> void:
	option_controls = [
		mouse_sensitivity_slider,
		master_volume_slider,
		music_volume_slider,
		sfx_volume_slider,
		back_button
	]

func _connect_signals() -> void:
	# Connect slider signals
	mouse_sensitivity_slider.value_changed.connect(_on_mouse_sensitivity_changed)
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Connect button signal
	back_button.pressed.connect(_on_back_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		_navigate_options(-1)
	elif event.is_action_pressed("ui_down"):
		_navigate_options(1)
	elif event.is_action_pressed("ui_left"):
		_adjust_current_option(-1)
	elif event.is_action_pressed("ui_right"):
		_adjust_current_option(1)
	elif event.is_action_pressed("ui_accept"):
		_activate_current_option()
	elif event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _navigate_options(direction: int) -> void:
	current_option_index += direction
	current_option_index = current_option_index % option_controls.size()
	if current_option_index < 0:
		current_option_index = option_controls.size() - 1
	
	_update_selection()

func _adjust_current_option(direction: int) -> void:
	var current_control = option_controls[current_option_index]
	
	if current_control is HSlider:
		var slider = current_control as HSlider
		var step_size = slider.step
		var new_value = slider.value + (direction * step_size)
		new_value = clamp(new_value, slider.min_value, slider.max_value)
		slider.value = new_value

func _activate_current_option() -> void:
	var current_control = option_controls[current_option_index]
	
	if current_control is Button:
		current_control.pressed.emit()

func _update_selection() -> void:
	if not selection_indicator or current_option_index >= option_controls.size():
		return
	
	var selected_control = option_controls[current_option_index]
	var target_position = selected_control.global_position
	
	# Convert global position to local position relative to the indicator's parent
	var local_position = selection_indicator.get_parent().to_local(target_position)
	
	# Position the indicator to the left of the selected control
	selection_indicator.position.x = local_position.x - 40
	selection_indicator.position.y = local_position.y + (selected_control.size.y / 2) - (selection_indicator.size.y / 2)
	
	selection_indicator.visible = true

func _start_ambient_effects() -> void:
	if ambient_sound:
		# Start with low pitch and gradually increase like main menu
		ambient_sound.pitch_scale = 0.6
		ambient_sound.play()
		
		# Create tween for pitch progression
		var tween = create_tween()
		tween.tween_interval(4.0)  # Stay at 0.6 for 4 seconds
		tween.tween_property(ambient_sound, "pitch_scale", 0.9, 3.0)  # Increase to 0.9 over 3 seconds

# Settings management
func _load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		settings_data.mouse_sensitivity = config.get_value("settings", "mouse_sensitivity", 1.0)
		settings_data.master_volume = config.get_value("settings", "master_volume", 70.0)
		settings_data.music_volume = config.get_value("settings", "music_volume", 50.0)
		settings_data.sfx_volume = config.get_value("settings", "sfx_volume", 80.0)
	
	# Update UI to reflect loaded settings
	mouse_sensitivity_slider.value = settings_data.mouse_sensitivity
	master_volume_slider.value = settings_data.master_volume
	music_volume_slider.value = settings_data.music_volume
	sfx_volume_slider.value = settings_data.sfx_volume

func _save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("settings", "mouse_sensitivity", settings_data.mouse_sensitivity)
	config.set_value("settings", "master_volume", settings_data.master_volume)
	config.set_value("settings", "music_volume", settings_data.music_volume)
	config.set_value("settings", "sfx_volume", settings_data.sfx_volume)
	
	config.save("user://settings.cfg")
	
	# Also update Global script if it exists
	if Global:
		Global.mouse_sensitivity = settings_data.mouse_sensitivity

func _apply_all_settings() -> void:
	_apply_mouse_sensitivity()
	_apply_master_volume()
	_apply_music_volume()
	_apply_sfx_volume()

func _apply_mouse_sensitivity() -> void:
	# Update Global script if it exists
	if Global:
		Global.mouse_sensitivity = settings_data.mouse_sensitivity

func _apply_master_volume() -> void:
	var db_value = linear_to_db(settings_data.master_volume / 100.0)
	if settings_data.master_volume <= 0:
		db_value = -80.0  # Effectively mute
	AudioServer.set_bus_volume_db(master_bus_index, db_value)

func _apply_music_volume() -> void:
	var db_value = linear_to_db(settings_data.music_volume / 100.0)
	if settings_data.music_volume <= 0:
		db_value = -80.0  # Effectively mute
	AudioServer.set_bus_volume_db(music_bus_index, db_value)

func _apply_sfx_volume() -> void:
	var db_value = linear_to_db(settings_data.sfx_volume / 100.0)
	if settings_data.sfx_volume <= 0:
		db_value = -80.0  # Effectively mute
	AudioServer.set_bus_volume_db(sfx_bus_index, db_value)

# Signal handlers
func _on_mouse_sensitivity_changed(value: float) -> void:
	settings_data.mouse_sensitivity = value
	mouse_sensitivity_value.text = "%.1f" % value
	_apply_mouse_sensitivity()
	_save_settings()

func _on_master_volume_changed(value: float) -> void:
	settings_data.master_volume = value
	master_volume_value.text = "%d%%" % int(value)
	_apply_master_volume()
	_save_settings()

func _on_music_volume_changed(value: float) -> void:
	settings_data.music_volume = value
	music_volume_value.text = "%d%%" % int(value)
	_apply_music_volume()
	_save_settings()

func _on_sfx_volume_changed(value: float) -> void:
	settings_data.sfx_volume = value
	sfx_volume_value.text = "%d%%" % int(value)
	_apply_sfx_volume()
	_save_settings()

func _on_back_pressed() -> void:
	# Fade out ambient sound
	if ambient_sound:
		var tween = create_tween()
		tween.tween_property(ambient_sound, "volume_db", -80.0, 0.5)
		tween.tween_callback(ambient_sound.stop)
	
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/main_menu_new.tscn")
