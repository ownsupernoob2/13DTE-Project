extends Node

# Game Manager for Alien Classification System
# Manages the 5-stage progression: Tutorial → Easy → Easy → Medium → Hard

signal alien_classified(correct: bool)
signal machine_speed_increased(speed_level: int)
signal game_over(reason: String)
signal stage_completed(stage: int)

# Core progression system - 5 stages total
var current_stage: int = 1  # 1=Tutorial, 2=Easy, 3=Easy, 4=Medium, 5=Hard
var aliens_processed_this_stage: int = 0
var aliens_required_per_stage: Array = [5, 8, 10, 12, 15]  # Quota per stage
var correct_classifications: int = 0
var total_classifications: int = 0
var stage_accuracy: float = 0.0

# Stage configuration
var stage_names: Array = ["TUTORIAL", "EASY", "EASY", "MEDIUM", "HARD"]
var stage_descriptions: Array = [
	"Learn the basics - 5 simple aliens",
	"Standard processing - 8 aliens", 
	"Increased volume - 10 aliens",
	"Complex specimens - 12 aliens with complications",
	"Maximum difficulty - 15 aliens with all hazards"
]

# Current alien and game state
var current_alien: Dictionary = {}
var game_active: bool = false
var stage_completed: bool = false

# Game balance settings
const MAX_SPEED_LEVEL: int = 10
const SPEED_INCREASE_THRESHOLD: int = 3 # Increase speed every 3 mistakes
const MAX_MISTAKES: int = 30 # Game over after 30 total mistakes

# Alien data for verification - Now using Class system
var alien_species_data: Dictionary = {
	"Class 1": {
		"eye_colors": ["Yellow", "Orange", "White"],
		"blood_types": ["X-Positive", "O-Negative", "Z-Flux"],
		"weight_range": [130, 150]
	},
	"Class 2": {
		"eye_colors": ["Green", "Cyan", "Amber"],
		"blood_types": ["A-Neutral", "B-Static"],
		"weight_range": [151, 180]
	},
	"Class 3": {
		"eye_colors": ["Blue", "Indigo", "Red"],
		"blood_types": ["B-Volatile", "C-Pulse"],
		"weight_range": [181, 220]
	},
	"Class 4": {
		"eye_colors": ["Purple", "Violet", "Magenta", "Crimson", "Scarlet"],
		"blood_types": ["C-Stable", "D-Light", "D-Heavy", "E-Dense"],
		"weight_range": [221, 280]
	}
}

func _ready() -> void:
	print("GameManager initialized - Starting Stage 1: TUTORIAL")
	start_new_stage()

func start_new_stage() -> void:
	aliens_processed_this_stage = 0
	correct_classifications = 0
	stage_completed = false
	game_active = true
	
	print("=== STAGE ", current_stage, ": ", stage_names[current_stage - 1], " ===")
	print("Target: ", aliens_required_per_stage[current_stage - 1], " aliens")
	print("Description: ", stage_descriptions[current_stage - 1])
	
	# Generate first alien for this stage
	generate_new_alien()

func generate_new_alien() -> void:
	if stage_completed or not game_active:
		return
		
	# Generate alien based on current stage difficulty
	current_alien = _create_alien_for_stage(current_stage)
	
	print("\n--- NEW ALIEN ---")
	print("Species: ", current_alien.species)
	print("Weight: ", current_alien.weight, " kg")  
	print("Eye Color: ", current_alien.eye_color)
	print("Blood Type: ", current_alien.blood_type)
	print("Progress: ", aliens_processed_this_stage + 1, "/", aliens_required_per_stage[current_stage - 1])

func classify_alien(player_says_accept: bool) -> bool:
	if not game_active or stage_completed:
		return false
		
	var is_correct = _validate_alien_classification(player_says_accept)
	
	total_classifications += 1
	aliens_processed_this_stage += 1
	
	if is_correct:
		correct_classifications += 1
		print("✓ CORRECT classification!")
	else:
		print("✗ INCORRECT classification!")
	
	# Calculate stage accuracy
	stage_accuracy = float(correct_classifications) / float(aliens_processed_this_stage) * 100.0
	print("Stage accuracy: ", "%.1f" % stage_accuracy, "%")
	
	# Check if stage is complete
	if aliens_processed_this_stage >= aliens_required_per_stage[current_stage - 1]:
		_complete_current_stage()
	else:
		# Generate next alien after brief delay
		await get_tree().create_timer(1.0).timeout
		generate_new_alien()
	
	alien_classified.emit(is_correct)
	return is_correct

func _complete_current_stage() -> void:
	stage_completed = true
	
	print("\n=== STAGE ", current_stage, " COMPLETED ===")
	print("Accuracy: ", "%.1f" % stage_accuracy, "%")
	print("Correct: ", correct_classifications, "/", aliens_processed_this_stage)
	
	# Check if player passed the stage (need 60% accuracy)
	if stage_accuracy >= 60.0:
		print("✓ STAGE PASSED!")
		
		stage_completed.emit(current_stage)
		
		# Move to next stage or end game
		if current_stage < 5:
			current_stage += 1
			await get_tree().create_timer(3.0).timeout  # Brief break between stages
			start_new_stage()
		else:
			_game_completed()
	else:
		print("✗ STAGE FAILED - Need 60% accuracy minimum")
		print("Restarting current stage...")
		await get_tree().create_timer(3.0).timeout
		start_new_stage()  # Restart same stage

func _game_completed() -> void:
	game_active = false
	print("\n🎉 GAME COMPLETED! 🎉")
	print("You have successfully completed all 5 stages!")
	print("Final Statistics:")
	print("- Stages Completed: 5/5")
	print("- Total Aliens Processed: ", total_classifications)
	print("- Overall Accuracy: ", "%.1f" % (float(correct_classifications) / float(total_classifications) * 100.0), "%")

func reset_game() -> void:
	current_stage = 1
	aliens_processed_this_stage = 0
	correct_classifications = 0
	total_classifications = 0
	stage_accuracy = 0.0
	stage_completed = false
	game_active = false
	current_alien = {}
	
	print("Game reset - Returning to Tutorial")
	start_new_stage()

func _create_alien_for_stage(stage: int) -> Dictionary:
	var species_names = alien_species_data.keys()
	var species_name = ""
	
	# Stage-based species selection
	match stage:
		1: # Tutorial - Only Class 1 (easiest)
			species_name = "Class 1"
		2: # Easy - Class 1 and 2
			species_name = ["Class 1", "Class 1", "Class 2"][randi() % 3]  # 66% Class 1
		3: # Easy - Class 1, 2, 3
			species_name = ["Class 1", "Class 2", "Class 2", "Class 3"][randi() % 4]  # Mixed
		4: # Medium - All classes, some complications
			species_name = species_names[randi() % species_names.size()]
		5: # Hard - All classes, maximum complications
			species_name = species_names[randi() % species_names.size()]
	
	var species_data = alien_species_data[species_name]
	var weight = randi_range(species_data["weight_range"][0], species_data["weight_range"][1])
	var blood = species_data["blood_types"][randi() % species_data["blood_types"].size()]
	var eye = species_data["eye_colors"][randi() % species_data["eye_colors"].size()]
	
	var alien = {
		"species": species_name,
		"weight": weight,
		"blood_type": blood,
		"eye_color": eye,
		"stage": stage,
		"complications": []
	}
	
	# Add stage-specific complications
	match stage:
		1: # Tutorial - No complications
			pass
		2: # Easy - Very rare complications
			if randf() < 0.1:
				alien.complications.append("minor_contamination")
		3: # Easy - Rare complications  
			if randf() < 0.2:
				alien.complications.append(["minor_contamination", "slight_resistance"][randi() % 2])
		4: # Medium - Some complications
			if randf() < 0.4:
				alien.complications.append(["contamination", "sedation_resistance", "scanner_interference"][randi() % 3])
		5: # Hard - Frequent complications
			if randf() < 0.6:
				alien.complications.append(["severe_contamination", "high_resistance", "hybrid_characteristics"][randi() % 3])
			if randf() < 0.3:  # Chance of multiple complications
				alien.complications.append(["equipment_malfunction", "time_pressure"][randi() % 2])
	
	return alien

func _validate_alien_classification(player_says_accept: bool) -> bool:
	if current_alien.is_empty():
		return false
	
	# Check if alien should be accepted based on species data
	var species_name = current_alien.species
	var actual_weight = current_alien.weight
	var actual_blood = current_alien.blood_type
	var actual_eye = current_alien.eye_color
	
	if not species_name in alien_species_data:
		return false
	
	var species_data = alien_species_data[species_name]
	
	# Check if characteristics match species requirements
	var weight_valid = actual_weight >= species_data["weight_range"][0] and actual_weight <= species_data["weight_range"][1]
	var blood_valid = actual_blood in species_data["blood_types"]
	var eye_valid = actual_eye in species_data["eye_colors"]
	
	# Apply complications that might affect classification
	var should_reject_due_to_complications = false
	for complication in current_alien.get("complications", []):
		match complication:
			"severe_contamination", "high_resistance":
				should_reject_due_to_complications = true
			"hybrid_characteristics":
				should_reject_due_to_complications = true
	
	# Alien should be accepted if all characteristics are valid AND no serious complications
	var should_accept = weight_valid and blood_valid and eye_valid and not should_reject_due_to_complications
	
	# Player is correct if their decision matches what should happen
	return player_says_accept == should_accept

func get_current_stage_info() -> Dictionary:
	return {
		"stage": current_stage,
		"stage_name": stage_names[current_stage - 1] if current_stage <= 5 else "UNKNOWN",
		"progress": aliens_processed_this_stage,
		"target": aliens_required_per_stage[current_stage - 1] if current_stage <= 5 else 0,
		"accuracy": stage_accuracy,
		"game_active": game_active
	}
