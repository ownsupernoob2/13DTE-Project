extends RichTextLabel

# Base
@export var console_size: Vector2 = Vector2(100, 30)

# Data generation - Using numeric system for aliens
var species_data: Dictionary = {
	"1": {
		#"eye_colors": ["Yellow", "Orange", "Red"],  # Limited to 3, commented out
		"weight_range": [130, 150],  # Matches Disk1 weight_classes.csv
		#"blood_types": ["X-Positive", "O-Negative", "A-Neutral"]
	},
	"2": {
		#"eye_colors": ["Green", "Cyan", "Blue"],  # Limited to 3, commented out
		"weight_range": [130, 160],  # Matches Disk2 weight_classes.csv
		#"blood_types": ["A-Neutral", "B-Static", "X-Positive"]
	},
	"3": {
		#"eye_colors": ["Blue", "Indigo", "Purple"],  # Limited to 3, commented out
		"weight_range": [140, 170],  # Matches Disk3 weight_classes.csv
		#"blood_types": ["B-Volatile", "C-Pulse", "D-Heavy"]
	},
	"4": {
		#"eye_colors": ["Purple", "Violet", "Magenta"],  # Limited to 3, commented out
		"weight_range": [151, 180],  # Matches Disk4 weight_classes.csv
		#"blood_types": ["C-Stable", "D-Light", "A-Neutral"]
	}
}
var species_list: Array = ["1", "2", "3", "4"]
var all_eye_colors: Array = ["Yellow", "Orange", "White", "Green", "Cyan", "Amber", "Blue", "Indigo", "Red", "Purple", "Violet", "Magenta", "Crimson", "Scarlet"]
var all_blood_types: Array = ["X-Positive", "O-Negative", "Z-Flux", "A-Neutral", "B-Static", "B-Volatile", "C-Pulse", "C-Stable", "D-Light", "D-Heavy", "E-Dense"]

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

func show_alien_info() -> void:
	var alien_label = get_node_or_null("SubViewport/Control/RichTextLabel")
	if alien_label:
		alien_label.text = "[center][font_size=200]Alien Data: Classified[/font_size][/center]"
	else:
		print("Warning: Alien label not found at SubViewport/Control/RichTextLabel")

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
			var entry = _generate_random_entry()
			if entry.species != "" and entry.weight > 0:  # Ensure valid entry
				_entries.append(entry)
			else:
				print("Warning: Invalid entry generated, skipping")
	
	# Display current entry
	if _current_entry < _entries.size():
		var entry = _entries[_current_entry]
		var entry_text = (
			"[color=WEB_GRAY]Species:[/color] %s\n" +
			"[color=WEB_GRAY]Weight:[/color] %.1f kg"
		) % [entry.species, entry.weight]
		push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
		append_text(entry_text)
		pop()
	else:
		append_text("[color=RED]No valid entries to display.[/color]")
	
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
	var weight: float = 0.0

	# Reference console.gd's inserted_disk to align weight ranges
	var console_node = get_node_or_null("/Computer/Computer/SubViewport/Control/Console")
	var disk_name = console_node.inserted_disk if console_node and console_node.inserted_disk != "" else "Disk1"
	var weight_range = data.weight_range

	# Adjust weight range based on disk_name to match console.gd's CSV
	match disk_name:
		"Disk1":
			weight_range = [130, 150]
		"Disk2":
			weight_range = [130, 160]
		"Disk3":
			weight_range = [140, 170]
		"Disk4":
			weight_range = [151, 180]
		_:
			print("Warning: Unknown disk_name '", disk_name, "', defaulting to Disk1")
			weight_range = [130, 150]

	if is_correct:
		weight = randf_range(weight_range[0], weight_range[1])
	else:
		var wrong_field = randi() % 3
		if wrong_field == 1:
			if randi() % 2 == 0:
				weight = randf_range(weight_range[0] - 20, weight_range[0] - 10)
			else:
				weight = randf_range(weight_range[1] + 10, weight_range[1] + 20)
		else:
			weight = randf_range(weight_range[0], weight_range[1])

	return {
		"species": species,
		"eye_color": "",
		"weight": weight,
		"blood_type": "",
		"is_correct": is_correct
	}

func newline() -> void:
	append_text("\n")
