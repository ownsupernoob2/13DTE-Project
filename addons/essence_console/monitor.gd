extends RichTextLabel

# Base
@export var console_size: Vector2 = Vector2(100, 30)

# Data generation - Using Class system for aliens
var species_data: Dictionary = {
	"Class 1": {
		"eye_colors": ["Yellow", "Orange", "White", "Red"],  # Some correct, some incorrect
		"weight_range": [120, 160],  # Slightly broader range to include edge cases
		"blood_types": ["X-Positive", "O-Negative", "Z-Flux", "A-Neutral"]  # Mix correct/incorrect
	},
	"Class 2": {
		"eye_colors": ["Green", "Cyan", "Amber", "Blue"],
		"weight_range": [75, 105],
		"blood_types": ["A-Neutral", "B-Static", "X-Positive"]
	},
	"Class 3": {
		"eye_colors": ["Blue", "Indigo", "Red", "Purple"],
		"weight_range": [190, 260],
		"blood_types": ["B-Volatile", "C-Pulse", "D-Heavy"]
	},
	"Class 4": {
		"eye_colors": ["Purple", "Violet", "Magenta", "Blue"],
		"weight_range": [45, 75],
		"blood_types": ["C-Stable", "D-Light", "A-Neutral"]
	}
}
var species_list: Array = ["Class 1", "Class 2", "Class 3", "Class 4"]
var all_eye_colors: Array = ["Yellow", "Orange", "White", "Green", "Cyan", "Amber", "Blue", "Indigo", "Red", "Purple", "Violet", "Magenta", "Crimson", "Scarlet"]
var all_blood_types: Array = ["X-Positive", "O-Negative", "Z-Flux", "A-Neutral", "B-Static", "B-Volatile", "C-Pulse", "C-Stable", "D-Light", "D-Heavy", "E-Dense"]  # All known blood types

# Display and input control
var _flash_timer = Timer.new()
var _update_interval: float = 5.0  # Update every 5 seconds
var _entries: Array[Dictionary] = []
var _current_entry: int = 0
var _can_input: bool = false
var _feedback: String = ""

func _ready() -> void:
	size = Vector2(console_size.x * 12.5, console_size.y * 23)
	# Increase text size
	theme = Theme.new()
	theme.set_font_size("normal_font_size", "RichTextLabel", 24)  # Larger text size
	add_child(_flash_timer)
	_flash_timer.set_one_shot(false)
	_flash_timer.start(0.1)  # Initial start
	_flash_timer.timeout.connect(_update_display)
	_update_display()  # Immediate initial display

func _unhandled_key_input(event: InputEvent) -> void:
	if not _can_input or not event.is_pressed():
		return
	match event.as_text():
		"Left":
			_evaluate_input(false)
		"Right":
			_evaluate_input(true)
		_:
			print("Key pressed: ", event.as_text())  # Debug to check key input

func _evaluate_input(user_says_correct: bool) -> void:
	if _entries.is_empty() or _current_entry >= _entries.size():
		return
	var entry = _entries[_current_entry]
	var is_correct = entry.is_correct
	var user_correct = (user_says_correct == is_correct)
	_feedback = "[color=%s]%s[/color]" % [
		"LIME_GREEN" if user_correct else "CRIMSON",
		"Correct!" if user_correct else "Incorrect!"
	]
	_current_entry += 1
	if _current_entry >= _entries.size():
		_current_entry = 0
		_entries = []
	_can_input = false
	_update_display()  # Refresh immediately after input

func _update_display() -> void:
	clear()
	# Header
	push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
	append_text("[color=DODGER_BLUE]=== Biological Monitor Data ===[/color]")
	pop()
	newline()
	newline()
	
	# Generate new entries if none exist or all have been evaluated
	if _entries.is_empty():
		_entries = []
		for i in 4:  # Generate exactly 4 aliens
			_entries.append(_generate_random_entry())
	
	# Display current entry
	if _current_entry < _entries.size():
		var entry = _entries[_current_entry]
		var entry_text = (
			"[color=WEB_GRAY]Species:[/color] %s\n" +
			"[color=WEB_GRAY]Eye Color:[/color] %s\n" +
			"[color=WEB_GRAY]Weight:[/color] %.1f kg\n" +
			"[color=WEB_GRAY]Blood Type:[/color] %s"
		) % [entry.species, entry.eye_color, entry.weight, entry.blood_type]
		push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
		append_text(entry_text)
		pop()
	
	# Display feedback
	if _feedback != "":
		newline()
		push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
		append_text(_feedback)
		pop()
	
	_can_input = true
	if _feedback != "":
		_flash_timer.start(_update_interval)
	else:
		_flash_timer.start(0.1)  # Keep display stable until input

func _generate_random_entry() -> Dictionary:
	var species = species_list[randi() % species_list.size()]
	var data = species_data[species]
	var is_correct = randi() % 2 == 0  
	var eye_color: String
	var weight: float
	var blood_type: String

	if is_correct:
		eye_color = data.eye_colors[randi() % data.eye_colors.size()]
		weight = randf_range(data.weight_range[0], data.weight_range[1])
		blood_type = data.blood_types[randi() % data.blood_types.size()]
	else:
		var wrong_field = randi() % 3
		eye_color = data.eye_colors[randi() % data.eye_colors.size()]
		weight = randf_range(data.weight_range[0], data.weight_range[1])
		blood_type = data.blood_types[randi() % data.blood_types.size()]
		if wrong_field == 0:
			eye_color = all_eye_colors[randi() % all_eye_colors.size()]
			while eye_color in data.eye_colors:
				eye_color = all_eye_colors[randi() % all_eye_colors.size()]
		elif wrong_field == 1:
			if randi() % 2 == 0:
				weight = randf_range(data.weight_range[0] - 20, data.weight_range[0] - 10)
			else:
				weight = randf_range(data.weight_range[1] + 10, data.weight_range[1] + 20)
		else:
			blood_type = all_blood_types[randi() % all_blood_types.size()]
			while blood_type in data.blood_types:
				blood_type = all_blood_types[randi() % all_blood_types.size()]

	return {
		"species": species,
		"eye_color": eye_color,
		"weight": weight,
		"blood_type": blood_type,
		"is_correct": is_correct
	}

func newline() -> void:
	append_text("\n")
