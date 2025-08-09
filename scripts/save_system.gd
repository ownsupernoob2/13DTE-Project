extends Node

# Save System - Tracks player progress and unlocked stages

const SAVE_FILE = "user://save_game.dat"

var player_data = {
	"highest_stage_reached": 1,
	"has_played_before": false,
	"stage_completion_times": [],
	"total_playtime": 0.0
}

func _ready() -> void:
	load_game()
	print("💾 SaveSystem initialized - Highest stage: ", player_data.highest_stage_reached)

func save_game() -> void:
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(player_data))
		file.close()
		print("💾 Game saved successfully")
	else:
		print("❌ Failed to save game")

func load_game() -> void:
	if FileAccess.file_exists(SAVE_FILE):
		var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var loaded_data = json.data
				# Merge loaded data with defaults
				for key in loaded_data:
					if key in player_data:
						player_data[key] = loaded_data[key]
				player_data.has_played_before = true
				print("💾 Game loaded successfully")
			else:
				print("❌ Failed to parse save file")
		else:
			print("❌ Failed to open save file")
	else:
		print("📝 No save file found - new player")

func unlock_stage(stage_number: int) -> void:
	if stage_number > player_data.highest_stage_reached:
		player_data.highest_stage_reached = stage_number
		print("🔓 Unlocked stage ", stage_number)
		save_game()

func complete_stage(stage_number: int, completion_time: float) -> void:
	# Ensure the completion times array is large enough
	while player_data.stage_completion_times.size() < stage_number:
		player_data.stage_completion_times.append(0.0)
	
	# Record best time for this stage
	if player_data.stage_completion_times[stage_number - 1] == 0.0 or completion_time < player_data.stage_completion_times[stage_number - 1]:
		player_data.stage_completion_times[stage_number - 1] = completion_time
	
	# Unlock next stage
	unlock_stage(stage_number + 1)
	
	print("🏆 Stage ", stage_number, " completed in ", completion_time, " seconds")

func can_continue() -> bool:
	return player_data.has_played_before

func get_highest_stage() -> int:
	return player_data.highest_stage_reached

func reset_progress() -> void:
	player_data = {
		"highest_stage_reached": 1,
		"has_played_before": false,
		"stage_completion_times": [],
		"total_playtime": 0.0
	}
	save_game()
	print("🗑️ Progress reset")
