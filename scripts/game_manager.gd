extends Node

# Game Manager for Alien Classification System
# Manages the gameplay loop of checking aliens, fact-checking, and machine speed

signal alien_classified(correct: bool)
signal machine_speed_increased(speed_level: int)
signal game_over(reason: String)

var machine_speed_level: int = 1
var classification_streak: int = 0
var total_classifications: int = 0
var incorrect_classifications: int = 0
var current_alien: Dictionary = {}

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
	# Connect to machine signals if available
	var machine = get_node_or_null("../Light/Machine")
	if machine:
		machine.connect("game_over", _on_machine_game_over)
	
	print("GameManager initialized - Ready for alien classification!")

func classify_alien(claimed_species: String, actual_weight: int, actual_blood: String, actual_eye: String) -> bool:
	"""
	Check if the claimed species matches the actual alien characteristics
	Returns true if classification is correct, false otherwise
	"""
	total_classifications += 1
	
	if not claimed_species in alien_species_data:
		print("Unknown species: ", claimed_species)
		return false
	
	var species_data = alien_species_data[claimed_species]
	
	# Check weight range
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
	
	return {
		"species": species_name,
		"weight": weight,
		"blood_type": blood,
		"eye_color": eye
	}
