extends Node

# Game Manager for Alien Classification System
# Manages the gameplay loop of checking aliens, fact-checking, and machine speed

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
		"weight_range": [130, 150],
		"blood_types": ["X-Positive", "O-Negative", "Z-Flux"],
		"eye_colors": ["Yellow", "Orange", "White"]
	},
	"Class 2": {
		"weight_range": [80, 100],
		"blood_types": ["A-Neutral", "B-Static"],
		"eye_colors": ["Green", "Cyan", "Amber"]
	},
	"Class 3": {
		"weight_range": [200, 250],
		"blood_types": ["B-Volatile", "C-Pulse"],
		"eye_colors": ["Blue", "Indigo", "Red"]
	},
	"Class 4": {
		"weight_range": [50, 70],
		"blood_types": ["C-Stable", "D-Light"],
		"eye_colors": ["Purple", "Violet", "Magenta"]
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
	var weight_correct = actual_weight >= species_data["weight_range"][0] and actual_weight <= species_data["weight_range"][1]
	
	# Check blood type
	var blood_correct = actual_blood in species_data["blood_types"]
	
	# Check eye color
	var eye_correct = actual_eye in species_data["eye_colors"]
	
	var is_correct = weight_correct and blood_correct and eye_correct
	
	if is_correct:
		classification_streak += 1
		print("CORRECT classification! Streak: ", classification_streak)
	else:
		classification_streak = 0
		incorrect_classifications += 1
		_handle_incorrect_classification()
		print("INCORRECT classification! Total mistakes: ", incorrect_classifications)
	
	emit_signal("alien_classified", is_correct)
	return is_correct

func _handle_incorrect_classification() -> void:
	"""Handle the consequences of an incorrect classification"""
	
	# Increase machine speed every few mistakes
	if incorrect_classifications % SPEED_INCREASE_THRESHOLD == 0:
		machine_speed_level = min(machine_speed_level + 1, MAX_SPEED_LEVEL)
		_increase_machine_speed()
		emit_signal("machine_speed_increased", machine_speed_level)
		print("Machine speed increased to level: ", machine_speed_level)
	
	# Check for game over condition
	if incorrect_classifications >= MAX_MISTAKES:
		emit_signal("game_over", "Too many incorrect classifications!")
		print("GAME OVER: Too many mistakes!")

func _increase_machine_speed() -> void:
	"""Increase the machine's update speed based on current speed level"""
	var machine = get_node_or_null("../Light/Machine")
	if machine and machine.has_method("set_speed_level"):
		machine.set_speed_level(machine_speed_level)
	else:
		print("Machine not found or doesn't support speed changes")

func _on_machine_game_over(final_count: int) -> void:
	"""Handle game over from machine reaching limit"""
	emit_signal("game_over", "Machine counter reached critical level: " + str(final_count))
	print("GAME OVER: Machine critical failure!")

func get_classification_stats() -> Dictionary:
	"""Return current game statistics"""
	return {
		"total_classifications": total_classifications,
		"incorrect_classifications": incorrect_classifications,
		"correct_classifications": total_classifications - incorrect_classifications,
		"current_streak": classification_streak,
		"machine_speed_level": machine_speed_level,
		"accuracy": 0.0 if total_classifications == 0 else float(total_classifications - incorrect_classifications) / float(total_classifications) * 100.0
	}

func reset_game() -> void:
	"""Reset the game state"""
	machine_speed_level = 1
	classification_streak = 0
	total_classifications = 0
	incorrect_classifications = 0
	current_alien = {}
	
	# Reset machine speed
	var machine = get_node_or_null("../Light/Machine")
	if machine and machine.has_method("_reset_machine"):
		machine._reset_machine()
	
	print("Game reset - Ready for new session!")

# Utility function to generate test alien data
func generate_test_alien(species_name: String = "") -> Dictionary:
	"""Generate a test alien with random characteristics"""
	var species_names = alien_species_data.keys()
	if species_name == "":
		species_name = species_names[randi() % species_names.size()]
	
	var species_data = alien_species_data[species_name]
	var weight = randi_range(species_data["weight_range"][0], species_data["weight_range"][1])
	var blood = species_data["blood_types"][randi() % species_data["blood_types"].size()]
	var eye = species_data["eye_colors"][randi() % species_data["eye_colors"].size()]
	
	var alien = {
		"species": species_name,
		"weight": weight,
		"blood_type": blood,
		"eye_color": eye
	}
	
	# Progressive complexity based on day
	if current_day > 3:
		alien["requires_decontamination"] = randf() < 0.3
	if current_day > 5:
		alien["psychological_evaluation_needed"] = randf() < 0.25
	if current_day > 7:
		alien["quarantine_protocols"] = ["standard", "enhanced", "maximum"][randi() % 3]
	
	# Hybrid aliens (unlocked later)
	if hybrid_aliens_unlocked and randf() < 0.15:
		alien["is_hybrid"] = true
		alien["primary_species"] = species_name
		alien["secondary_species"] = species_names[randi() % species_names.size()]
		# Hybrid aliens have mixed characteristics
		alien["eye_color"] = _get_hybrid_eye_color(alien.primary_species, alien.secondary_species)
		alien["blood_type"] = _get_hybrid_blood_type(alien.primary_species, alien.secondary_species)
	
	# Equipment-dependent aliens
	if current_day > 4:
		alien["requires_special_equipment"] = randf() < 0.2
		if alien.get("requires_special_equipment", false):
			alien["special_equipment_type"] = ["UV_SCANNER", "DEEP_TISSUE", "NEURAL_PROBE"][randi() % 3]
	
	# Trigger random events
	trigger_random_event()
	
	return alien

func _get_hybrid_eye_color(primary: String, secondary: String) -> String:
	# Mixed eye colors for hybrids
	var hybrid_colors = ["Amber-Green", "Blue-Yellow", "Purple-Red", "Cyan-Orange"]
	return hybrid_colors[randi() % hybrid_colors.size()]

func _get_hybrid_blood_type(primary: String, secondary: String) -> String:
	# Mixed blood types for hybrids  
	var hybrid_types = ["XA-Flux", "BC-Variable", "ZO-Unstable", "CD-Compound"]
	return hybrid_types[randi() % hybrid_types.size()]

func _apply_event_effect(effect: String) -> void:
	match effect:
		"scanner_unreliable":
			# Scanner may give false readings
			equipment_malfunction_chance = 0.3
		"sedation_difficult":
			# Aliens resist sedation more
			alien_resistance_level = 2
		"time_pressure":
			# Reduce available time
			var machine = get_node_or_null("../Light/Machine")
			if machine:
				machine.total_seconds = max(60, machine.total_seconds - 120)  # 2 minutes less
		"hybrid_alien":
			# Enable hybrid aliens
			hybrid_aliens_unlocked = true
		"lever_drift":
			# Levers slowly drift from set values
			_start_lever_drift()

func _start_lever_drift() -> void:
	var lever_system = get_node_or_null("../LeverGutentagPosition")
	if lever_system:
		# Create a timer to randomly adjust lever values
		var drift_timer = Timer.new()
		drift_timer.wait_time = 5.0
		drift_timer.timeout.connect(_apply_lever_drift)
		add_child(drift_timer)
		drift_timer.start()

func _apply_lever_drift() -> void:
	var lever_system = get_node_or_null("../LeverGutentagPosition")
	if lever_system:
		# Randomly drift one lever by ±1-3 points
		var lever_to_drift = randi() % 3 + 1
		var drift_amount = randi_range(-3, 3)
		var current_value = 0
		
		match lever_to_drift:
			1: current_value = lever_system.counter1
			2: current_value = lever_system.counter2  
			3: current_value = lever_system.counter3
		
		var new_value = clamp(current_value + drift_amount, 0, 100)
		lever_system.set_lever_value(lever_to_drift, new_value)
		print("POWER FLUCTUATION: Lever ", lever_to_drift, " drifted to ", new_value)
