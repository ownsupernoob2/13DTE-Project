extends RichTextLabel

# Base
@export var console_size: Vector2 = Vector2(100, 30)

# Data generation - Using numeric system for aliens - Updated with overlapping weight ranges
var species_data: Dictionary = {
	"1": {
		"eye_colors": ["Yellow", "Orange", "White"],  # From DiskManager Class 1
		"weight_range": [120, 160],  # Updated range - overlaps with other classes
		"blood_types": ["X-Positive", "O-Negative", "Z-Flux"],  # From DiskManager Class 1
		"species_name": "Class 1"
	},
	"2": {
		"eye_colors": ["Green", "Cyan", "Amber"],  # From DiskManager Class 2
		"weight_range": [75, 125],  # Updated range - overlaps with Class 1 and 4
		"blood_types": ["A-Neutral", "B-Static"],  # From DiskManager Class 2
		"species_name": "Class 2"
	},
	"3": {
		"eye_colors": ["Blue", "Indigo", "Red"],  # From DiskManager Class 3
		"weight_range": [180, 280],  # Updated range - overlaps with Class 1
		"blood_types": ["B-Volatile", "C-Pulse"],  # From DiskManager Class 3
		"species_name": "Class 3"
	},
	"4": {
		"eye_colors": ["Purple", "Violet", "Magenta"],  # From DiskManager Class 4
		"weight_range": [45, 85],  # Updated range - overlaps with Class 1 and 2
		"blood_types": ["C-Stable", "D-Light"],  # From DiskManager Class 4
		"species_name": "Class 4"
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
	size = Vector2(console_size.x * 32.0, console_size.y * 64.0)  # Much much larger for excellent readability
	# Increase text size significantly
	theme = Theme.new()
	theme.set_font_size("normal_font_size", "RichTextLabel", 64)  # Very large text size for excellent readability
	add_child(_flash_timer)
	_flash_timer.set_one_shot(false)
	_flash_timer.start(0.1)  # Initial start
	
	# Wait a moment then start the game
	await get_tree().create_timer(1.0).timeout
	if GameManager:
		show_alien_info()
	else:
		append_text("[center][color=red]ERROR: GameManager not found[/color][/center]")
	_flash_timer.timeout.connect(_update_display)
	_update_display()  # Immediate initial display

func show_alien_info() -> void:
	if not GameManager or not GameManager.game_active:
		_update_display()
		return
	
	var alien = GameManager.current_alien
	if alien.is_empty():
		_update_display()
		return
	
	var stage_info = GameManager.get_current_stage_info()
	
	# Clear and build display
	clear()
	newline()
	
	# Header with stage info
	append_text("[center][color=cyan]STAGE " + str(stage_info.stage) + ": " + stage_info.stage_name + "[/color][/center]")
	newline()
	append_text("[center][color=white]PROGRESS: " + str(stage_info.progress) + "/" + str(stage_info.target) + " | ACCURACY: " + "%.1f" % stage_info.accuracy + "%[/color][/center]")
	newline()
	newline()
	
	# Specimen information
	append_text("[color=yellow]SPECIMEN ANALYSIS:[/color]")
	newline()
	append_text("[color=white]Species: " + alien.species + "[/color]")
	newline()
	append_text("[color=white]Weight: " + str(alien.weight) + " kg[/color]")
	newline()
	append_text("[color=white]Eye Color: " + alien.eye_color + "[/color]")
	newline()
	append_text("[color=white]Blood Type: " + alien.blood_type + "[/color]")
	newline()
	
	# Show complications if any
	var complications = alien.get("complications", [])
	if not complications.is_empty():
		newline()
		append_text("[color=red]COMPLICATIONS DETECTED:[/color]")
		newline()
		for complication in complications:
			var comp_text = complication.replace("_", " ").to_upper()
			append_text("[color=red]- " + comp_text + "[/color]")
			newline()
	
	newline()
	append_text("[color=cyan]Press LEFT ARROW to REJECT or RIGHT ARROW to ACCEPT[/color]")
	
	_can_input = true

func _unhandled_key_input(event: InputEvent) -> void:
	if not _can_input or not event.is_pressed():
		return
	
	if not GameManager or not GameManager.game_active:
		return
	
	var player_says_accept = false
	
	if event.keycode == KEY_LEFT:
		player_says_accept = false  # REJECT
		append_text("[color=red]REJECTED[/color]")
	elif event.keycode == KEY_RIGHT:
		player_says_accept = true   # ACCEPT  
		append_text("[color=green]ACCEPTED[/color]")
	else:
		return
	
	_can_input = false
	newline()
	
	# Send classification to GameManager
	var was_correct = await GameManager.classify_alien(player_says_accept)
	
	if was_correct:
		append_text("[color=green]✓ CORRECT CLASSIFICATION[/color]")
	else:
		append_text("[color=red]✗ INCORRECT CLASSIFICATION[/color]")
	
	newline()
	append_text("[color=yellow]Processing next specimen...[/color]")
	
	# Brief delay before showing next alien
	await get_tree().create_timer(2.0).timeout
	show_alien_info()
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
	
	# Check if alien has been sedated first
	if not ("sedated" in entry and entry.sedated):
		_feedback = "[color=YELLOW]Specimen must be sedated before classification![/color]"
		_update_display()
		return
	
	# Now process classification since sedation is complete
	var is_correct = entry.is_correct  # Always true now since weight matches species
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
		var status_text = "Status: Sedation Required"
		if "sedated" in entry and entry.sedated:
			status_text = "Status: Ready for Classification"
		
		var entry_text = (
			"[color=WHITE]Species:[/color] %s\n" +
			"[color=WHITE]Weight:[/color] %.1f kg\n" +
			"\n[color=YELLOW]%s[/color]\n" +
			"\n[color=GRAY]Use lever system to sedate before classification[/color]"
		) % [entry.species, entry.weight, status_text]
		
		# Only show classification options if sedated
		if "sedated" in entry and entry.sedated:
			entry_text += "\n[color=CYAN]Left Arrow: Reject | Right Arrow: Accept[/color]"
		
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
	var weight: float = 0.0
	var eye_color: String = ""
	var blood_type: String = ""

	# Get the correct weight range from our species_data (which matches DiskManager)
	var weight_range = data.weight_range
	
	# ALWAYS generate correct weight within the species range - no incorrect weights
	weight = randf_range(weight_range[0], weight_range[1])
	
	# Generate random eye color and blood type for liquid ratio calculation
	eye_color = data.eye_colors[randi() % data.eye_colors.size()]
	blood_type = data.blood_types[randi() % data.blood_types.size()]

	return {
		"species": data.species_name,
		"eye_color": eye_color,
		"weight": weight,
		"blood_type": blood_type,
		"is_correct": true,  # Always correct now since weight matches species
		"liquid_ratios": _get_liquid_ratios(species, weight, eye_color)  # [A, B, C] values 0-100
	}



# Function to get current liquid ratios for lever validation
func get_current_liquid_ratios() -> Array:
	if _current_entry < _entries.size():
		var entry = _entries[_current_entry]
		if "liquid_ratios" in entry:
			print("DEBUG Monitor: Returning liquid ratios: ", entry.liquid_ratios)
			return entry.liquid_ratios
	print("DEBUG Monitor: No current entry or liquid ratios, returning [0,0,0]")
	return [0, 0, 0]  # Default fallback

# Function to enable classification after successful sedation
func enable_classification() -> void:
	if _current_entry < _entries.size():
		_entries[_current_entry].sedated = true
		_feedback = "[color=GREEN]Sedation successful! You may now classify this specimen.[/color]"
		_update_display()

func _get_liquid_ratios(species_num: String, weight: float, eye_color: String) -> Array:
	"""
	Get the liquid ratios [A, B, C] based on species, weight, and eye color
	This matches the updated overlapping weight ranges in CSV files
	"""
	var weight_int = int(weight)
	var ratios = [0, 0, 0]
	
	print("DEBUG: Getting liquid ratios for species ", species_num, " weight ", weight_int)
	
	match species_num:
		"1":  # Class 1: 120-160 kg - Overlaps with other classes
			if weight_int >= 120 and weight_int <= 125:
				ratios = [31, 51, 18]
			elif weight_int >= 126 and weight_int <= 131:
				ratios = [28, 49, 23]
			elif weight_int >= 132 and weight_int <= 137:
				ratios = [33, 53, 14]
			elif weight_int >= 138 and weight_int <= 143:
				ratios = [19, 62, 19]
			elif weight_int >= 144 and weight_int <= 149:
				ratios = [25, 45, 30]
			elif weight_int >= 150 and weight_int <= 160:
				ratios = [35, 40, 25]
			else:
				print("WARNING: Weight ", weight_int, " not in any Class 1 range!")
		
		"2":  # Class 2: 75-125 kg - Overlaps with Class 1 and 4
			if weight_int >= 75 and weight_int <= 80:
				ratios = [42, 38, 20]
			elif weight_int >= 81 and weight_int <= 86:
				ratios = [38, 42, 20]
			elif weight_int >= 87 and weight_int <= 92:
				ratios = [32, 28, 40]
			elif weight_int >= 93 and weight_int <= 98:
				ratios = [22, 18, 60]
			elif weight_int >= 99 and weight_int <= 104:
				ratios = [45, 30, 25]
			elif weight_int >= 105 and weight_int <= 125:
				ratios = [50, 25, 25]
			else:
				print("WARNING: Weight ", weight_int, " not in any Class 2 range!")
		
		"3":  # Class 3: 180-280 kg - Overlaps with Class 1
			if weight_int >= 180 and weight_int <= 195:
				ratios = [50, 45, 15]
			elif weight_int >= 196 and weight_int <= 211:
				ratios = [45, 50, 15]
			elif weight_int >= 212 and weight_int <= 227:
				ratios = [40, 35, 35]
			elif weight_int >= 228 and weight_int <= 243:
				ratios = [30, 25, 55]
			elif weight_int >= 244 and weight_int <= 259:
				ratios = [35, 30, 35]
			elif weight_int >= 260 and weight_int <= 280:
				ratios = [25, 35, 40]
			else:
				print("WARNING: Weight ", weight_int, " not in any Class 3 range!")
		
		"4":  # Class 4: 45-85 kg - Overlaps with Class 1 and 2
			if weight_int >= 45 and weight_int <= 50:
				ratios = [60, 55, 10]
			elif weight_int >= 51 and weight_int <= 56:
				ratios = [55, 45, 25]
			elif weight_int >= 57 and weight_int <= 62:
				ratios = [50, 35, 45]
			elif weight_int >= 63 and weight_int <= 68:
				ratios = [45, 30, 50]
			elif weight_int >= 69 and weight_int <= 74:
				ratios = [40, 40, 20]
			elif weight_int >= 75 and weight_int <= 85:
				ratios = [35, 35, 30]
			else:
				print("WARNING: Weight ", weight_int, " not in any Class 4 range!")
		_:
			print("ERROR: Unknown species number: ", species_num)
	
	print("DEBUG: Calculated ratios: ", ratios)
	return ratios
