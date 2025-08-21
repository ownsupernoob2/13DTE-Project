extends Node

var is_using_computer: bool = false
var is_using_monitor: bool = false
var in_presentation: bool = false  # Simple global flag for presentation mode
var mouse_sensitivity: float = 1.2

# Function to get current mouse sensitivity setting
func get_mouse_sensitivity() -> float:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		return config.get_value("gameplay", "mouse_sensitivity", 1.0)
	return 1.0

# Function to reload all settings across the game
func reload_settings() -> void:
	# Find player and reload mouse sensitivity
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("_load_mouse_sensitivity"):
		player._load_mouse_sensitivity()
	
	# Apply audio settings
	call_deferred("_apply_audio_settings")

func _apply_audio_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		# Apply master volume
		var master_volume = config.get_value("audio", "master_volume", 0.8)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
		
		# Apply music volume
		var music_volume = config.get_value("audio", "music_volume", 0.8)
		var music_bus_index = AudioServer.get_bus_index("Music")
		if music_bus_index != -1:
			AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(music_volume))
		
		# Apply SFX volume
		var sfx_volume = config.get_value("audio", "sfx_volume", 0.8)
		var sfx_bus_index = AudioServer.get_bus_index("SFX")
		if sfx_bus_index != -1:
			AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(sfx_volume))

func _ready() -> void:
	# Apply settings when game starts
	_apply_audio_settings()
