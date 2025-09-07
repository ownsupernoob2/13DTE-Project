extends Node

# Game Manager for Alien Classification System
# Manages the 5-stage progression: Tutorial → Easy → Easy → Medium → Hard

signal alien_classified(correct: bool)
signal machine_speed_increased(speed_level: int)
signal game_over(reason: String)
signal stage_completed(stage: int)

# Failure Manager reference
var failure_manager: Node = null

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
var current_stage_completed: bool = false

# Pod health and degradation system
var pod_health: float = 100.0
var pod_health_degradation_active: bool = false
var banging_timer: Timer = null
var current_bang_pitch: float = 1.0
var current_bang_frequency: float = 20.0  # Start with 20 seconds
var bang_audio_player: AudioStreamPlayer3D = null

signal pod_health_changed(health: float)
signal pod_critical_health()
signal pod_destroyed()

# Pod integrity system (for medium/hard stages)
var pod_integrity: float = 100.0
var pod_breaking_active: bool = false
var caulk_available: bool = false
var caulk_fuel: float = 100.0  # Caulk has limited fuel

signal pod_integrity_changed(integrity: float)
signal pod_repaired()
signal caulk_depleted()

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
	print("GameManager initialized")
	
	# Create demo alien data but don't start the game yet
	# Wait for pod start button to be pressed
	_prepare_demo_alien()
	
	# Ensure monitors show the correct initial state after a brief delay
	await get_tree().create_timer(0.2).timeout
	_update_monitor_initial_state()

func _update_monitor_initial_state() -> void:
	print("📺 GameManager: Setting monitor to initial state...")
	
	# Find the monitor system and ensure it shows start message
	var monitor = _find_monitor_system()
	
	if monitor:
		# Test if monitor is responsive
		if monitor.has_method("ping"):
			var response = monitor.ping()
			print("📺 Monitor ping response: ", response)
		
		# Try to show start message
		if monitor.has_method("show_start_message"):
			monitor.show_start_message()
			print("📺 Monitor set to show start message")
		elif monitor.has_method("force_start_message"):
			monitor.force_start_message()
			print("📺 Monitor forced to show start message")
		else:
			print("⚠️ Monitor found but no start message method available")
			# Try a simple test instead
			if monitor.has_method("test_display"):
				monitor.test_display()
	else:
		print("❌ Monitor system not found for initial state")

# Start pod game - called from pod system
func start_pod_game() -> void:
	print("🏺 GameManager: Starting pod game sequence...")
	game_active = true
	
	# Ensure we have an alien ready
	if current_alien.is_empty():
		create_demo_alien()
	
	# Update monitor to show alien information
	_update_monitor_display()
	
	# Start pod health degradation system after pod fills (20 seconds)
	_start_pod_health_system()
	
	print("🎮 Pod game started with alien: ", current_alien)

func _update_monitor_display() -> void:
	print("📺 GameManager: Updating monitor display...")
	
	# Find the monitor system
	var monitor = _find_monitor_system()
	
	if monitor:
		if monitor.has_method("show_alien_information"):
			monitor.show_alien_information()
		elif monitor.has_method("start_game_display"):
			monitor.start_game_display()
		else:
			print("⚠️ Monitor found but no display update method available")
	else:
		print("❌ Monitor system not found")

func _show_processing_message() -> void:
	print("📺 GameManager: Showing processing message...")
	
	# Find the monitor system
	var monitor = _find_monitor_system()
	
	if monitor:
		if monitor.has_method("show_processing_message"):
			monitor.show_processing_message()
		else:
			print("⚠️ Monitor found but no processing message method available")
	else:
		print("❌ Monitor system not found")

func _find_monitor_system() -> Node:
	print("🔍 Searching for monitor system...")
	
	# First try direct search by script class
	var all_nodes = _get_all_nodes_in_scene(get_tree().current_scene)
	for node in all_nodes:
		if node.get_script() and node.get_script().get_path().ends_with("monitor.gd"):
			print("✓ Found monitor by script at: ", node.get_path())
			return node
	
	# Fallback: Search common monitor paths
	var scene_path = str(get_tree().current_scene.get_path())
	var monitor_paths = [
		scene_path + "/Monitor/SubViewport/Control/Console",  # Most likely path
		scene_path + "/Computer/Monitor/SubViewport/Control/Console", 
		scene_path + "/Computer/ComputerCamera/Monitor/Monitor/SubViewport/Control/Console"
	]
	
	for path in monitor_paths:
		var monitor = get_node_or_null(path)
		if monitor:
			print("✓ Found monitor at path: ", path)
			return monitor
	
	# Final fallback: search in scene tree for RichTextLabel with specific names
	return _find_monitor_in_tree(get_tree().current_scene)

func _get_all_nodes_in_scene(node: Node) -> Array:
	var nodes = [node]
	for child in node.get_children():
		nodes.append_array(_get_all_nodes_in_scene(child))
	return nodes

func _find_monitor_in_tree(node: Node) -> Node:
	# Look for RichTextLabel nodes that might be monitors
	if node is RichTextLabel and node.name.to_lower().contains("console"):
		return node
	
	for child in node.get_children():
		var result = _find_monitor_in_tree(child)
		if result:
			return result
	return null

func _start_pod_health_system() -> void:
	print("💀 Starting pod health degradation system...")
	pod_health = 100.0
	pod_health_degradation_active = true
	current_bang_pitch = 1.0
	current_bang_frequency = 20.0
	
	# Create banging timer
	if banging_timer:
		banging_timer.queue_free()
	
	banging_timer = Timer.new()
	banging_timer.name = "PodBangingTimer"
	banging_timer.wait_time = current_bang_frequency
	banging_timer.timeout.connect(_on_pod_banging)
	add_child(banging_timer)
	banging_timer.start()
	
	# Create audio player for banging sounds
	if not bang_audio_player:
		bang_audio_player = AudioStreamPlayer3D.new()
		bang_audio_player.name = "PodBangingAudio"
		add_child(bang_audio_player)
		
		# Load banging sound
		var bang_sound = load("res://assets/music/sfx/bang.mp3") as AudioStream
		if bang_sound:
			bang_audio_player.stream = bang_sound
			print("✓ Banging sound loaded")
		else:
			print("❌ Failed to load bang.mp3")
	
	print("✅ Pod health system initialized")

func _on_pod_banging() -> void:
	if not pod_health_degradation_active:
		return
	
	print("💥 Pod banging - health degrading...")
	
	# Play banging sound with varying pitch
	if bang_audio_player and bang_audio_player.stream:
		bang_audio_player.pitch_scale = current_bang_pitch
		bang_audio_player.play()
	
	# Degrade pod health
	var health_loss = randf_range(8.0, 15.0)  # Random health loss per bang
	pod_health -= health_loss
	pod_health = max(0.0, pod_health)
	
	print("🏺 Pod health: ", pod_health, "/100")
	emit_signal("pod_health_changed", pod_health)
	
	# Check if pod is destroyed
	if pod_health <= 0.0:
		print("💀 POD DESTROYED! Health reached zero!")
		_handle_pod_destruction()
		return
	
	# Vary pitch and frequency for next bang
	current_bang_pitch = randf_range(0.7, 1.4)  # Pitch variation
	current_bang_frequency = randf_range(15.0, 25.0)  # Frequency variation (not too fast)
	
	# Update timer for next bang
	banging_timer.wait_time = current_bang_frequency
	banging_timer.start()

func _handle_pod_destruction() -> void:
	print("💀 Handling pod destruction...")
	pod_health_degradation_active = false
	
	if banging_timer:
		banging_timer.stop()
	
	emit_signal("pod_destroyed")
	
	# Use the same failure sequence as incorrect lever combination
	print("🚨 Pod destroyed - triggering failure sequence...")
	handle_game_failure()

# Get current alien for monitor display
func get_current_alien() -> Dictionary:
	return current_alien

# Prepare demo alien data without starting the game
func _prepare_demo_alien() -> void:
	current_alien = {
		"species": "1",
		"weight": 150,
		"eye_color": "Yellow", 
		"blood_type": "X-Positive"
	}
	# Don't set game_active = true yet - wait for pod button press
	print("Demo alien prepared: ", current_alien)
	print("Expected liquid ratios should be: [35, 40, 25]")
	print("🎮 Game ready - press START button on pod to begin!")
	
	# Initialize failure manager but don't start stages yet
	_setup_failure_manager()

# Create a demo alien for testing the sedation system (used when game starts)
func create_demo_alien() -> void:
	# If alien data isn't prepared yet, prepare it
	if current_alien.is_empty():
		_prepare_demo_alien()
	
	# Now actually start the game
	game_active = true
	print("🎮 Demo game started with alien: ", current_alien)
	
	# Don't update monitor immediately - let Pod system handle the timing
	# The Pod system will call the monitor update functions at the right time
	
	start_new_stage()

func _setup_failure_manager() -> void:
	# Create failure manager if it doesn't exist
	failure_manager = get_node_or_null("/root/FailureManager")
	if not failure_manager:
		# Create and add failure manager
		var failure_script = preload("res://scripts/failure_manager.gd")
		failure_manager = Node.new()
		failure_manager.set_script(failure_script)
		failure_manager.name = "FailureManager"
		get_tree().current_scene.add_child(failure_manager)
		print("🚨 FailureManager created and initialized")
	else:
		print("🚨 FailureManager found and connected")

func start_new_stage() -> void:
	aliens_processed_this_stage = 0
	correct_classifications = 0
	current_stage_completed = false
	game_active = true
	
	# Initialize pod system for medium+ stages
	if current_stage >= 4:  # Medium and Hard stages
		_initialize_pod_system()
	else:
		pod_breaking_active = false
		pod_integrity = 100.0
	
	print("=== STAGE ", current_stage, ": ", stage_names[current_stage - 1], " ===")
	print("Target: ", aliens_required_per_stage[current_stage - 1], " aliens")
	print("Description: ", stage_descriptions[current_stage - 1])
	
	# Generate first alien for this stage
	generate_new_alien()

func _initialize_pod_system() -> void:
	pod_integrity = 100.0
	pod_breaking_active = true
	caulk_available = true
	caulk_fuel = 100.0
	
	print("⚠️ POD INTEGRITY SYSTEM ACTIVE ⚠️")
	print("Pod will deteriorate over time - use caulk to repair!")
	
	# Spawn caulk item in the scene
	_spawn_caulk_item()
	
	# Start pod degradation timer
	_start_pod_degradation()

func _spawn_caulk_item() -> void:
	# Create caulk as a grabbable item
	var caulk_scene = preload("res://scenes/components/caulk.tscn")  # We'll create this
	if not caulk_scene:
		print("Warning: Caulk scene not found - creating placeholder")
		return
	
	var caulk_instance = caulk_scene.instantiate()
	var main_scene = get_tree().current_scene
	if main_scene:
		# Position caulk near the pod
		caulk_instance.global_position = Vector3(2, 1, -1)  # Adjust position as needed
		main_scene.add_child(caulk_instance)
		print("✓ Caulk spawned - grab it to repair the pod!")

func _start_pod_degradation() -> void:
	# Create timer for pod degradation
	var degradation_timer = Timer.new()
	degradation_timer.wait_time = 2.0  # Degrade every 2 seconds
	degradation_timer.autostart = true
	degradation_timer.timeout.connect(_degrade_pod)
	add_child(degradation_timer)

func _degrade_pod() -> void:
	if not pod_breaking_active or current_stage_completed:
		return
	
	# Degrade pod integrity
	var degradation_rate = 3.0  # Lose 3% every 2 seconds
	if current_stage == 5:  # Hard mode - faster degradation
		degradation_rate = 5.0
	
	pod_integrity -= degradation_rate
	pod_integrity = max(0.0, pod_integrity)
	
	pod_integrity_changed.emit(pod_integrity)
	
	if pod_integrity <= 0:
		_pod_critical_failure()
	elif pod_integrity <= 25:
		print("🚨 CRITICAL: Pod integrity at ", "%.1f" % pod_integrity, "%!")
	elif pod_integrity <= 50:
		print("⚠️ WARNING: Pod integrity at ", "%.1f" % pod_integrity, "%")

func _pod_critical_failure() -> void:
	print("💥 POD FAILURE - GAME OVER!")
	game_active = false
	game_over.emit("Pod integrity failure - containment breached!")
	
	# Trigger failure system for pod critical failure
	if failure_manager and failure_manager.has_method("trigger_failure"):
		failure_manager.trigger_failure("Pod integrity critical failure - containment breached")

func repair_pod_with_caulk() -> void:
	if not caulk_available or caulk_fuel <= 0:
		print("No caulk available or caulk depleted!")
		return
	
	# Repair amount depends on caulk fuel
	var repair_amount = min(25.0, caulk_fuel * 0.5)  # Up to 25% repair
	caulk_fuel -= repair_amount * 2  # Caulk fuel depletes
	caulk_fuel = max(0.0, caulk_fuel)
	
	pod_integrity += repair_amount
	pod_integrity = min(100.0, pod_integrity)
	
	print("🔧 Pod repaired! Integrity: ", "%.1f" % pod_integrity, "% | Caulk fuel: ", "%.1f" % caulk_fuel, "%")
	
	pod_repaired.emit()
	
	if caulk_fuel <= 0:
		print("🔋 Caulk depleted!")
		caulk_available = false
		caulk_depleted.emit()

func generate_new_alien() -> void:
	if current_stage_completed or not game_active:
		return
		
	# Generate alien based on current stage difficulty
	current_alien = _create_alien_for_stage(current_stage)
	
	print("\n--- NEW ALIEN ---")
	print("Species: ", current_alien.species)
	print("Weight: ", current_alien.weight, " kg")  
	print("Eye Color: ", current_alien.eye_color)
	print("Blood Type: ", current_alien.blood_type)
	print("Progress: ", aliens_processed_this_stage + 1, "/", aliens_required_per_stage[current_stage - 1])
	
	# Show pod status if active
	if pod_breaking_active:
		print("Pod Integrity: ", "%.1f" % pod_integrity, "%")

func classify_alien(player_says_accept: bool) -> bool:
	if not game_active or current_stage_completed:
		return false
		
	var is_correct = _validate_alien_classification(player_says_accept)
	
	total_classifications += 1
	aliens_processed_this_stage += 1
	
	if is_correct:
		correct_classifications += 1
		print("✓ CORRECT classification!")
		# Trigger success indicator
		if failure_manager:
			failure_manager.trigger_success()
	else:
		print("✗ INCORRECT classification!")
		# Trigger failure for incorrect classification
		if failure_manager:
			failure_manager.trigger_failure("Incorrect alien classification")
	
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
	current_stage_completed = true
	
	# Stop pod degradation
	if pod_breaking_active:
		pod_breaking_active = false
		print("🛡️ Pod systems stabilized")
	
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
	current_stage_completed = false
	game_active = false
	current_alien = {}
	
	# Reset pod system
	pod_integrity = 100.0
	pod_breaking_active = false
	caulk_available = false
	caulk_fuel = 100.0
	
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
		"game_active": game_active,
		"pod_integrity": pod_integrity,
		"pod_active": pod_breaking_active,
		"caulk_available": caulk_available,
		"caulk_fuel": caulk_fuel
	}

# ========================
# SEDATION FAILURE SYSTEM
# ========================

var is_game_over: bool = false
var glitch_overlay: ColorRect = null

# Main failure handler - called when incorrect lever combination is used
func handle_game_failure() -> void:
	print("🚨 GameManager.handle_game_failure() called!")
	
	if is_game_over:
		print("⚠️ Failure already in progress, ignoring duplicate call")
		return  # Prevent multiple calls
	
	is_game_over = true
	print("💀 GAME FAILURE: Incorrect lever combination detected")
	print("🎬 Starting failure sequence execution...")
	
	# Start the failure sequence in background (don't await to avoid blocking)
	_execute_failure_sequence_async()

# Async wrapper to run failure sequence without blocking
func _execute_failure_sequence_async() -> void:
	await _execute_failure_sequence()

# Simple immediate failure for testing
func immediate_failure_test() -> void:
	print("🧪 IMMEDIATE FAILURE TEST - Resetting scene now!")
	is_game_over = false  # Reset state
	var result = get_tree().change_scene_to_file("res://scenes/demo.tscn")
	if result != OK:
		print("❌ Immediate scene reset failed: ", result)
	else:
		print("✅ Immediate scene reset successful!")

# Main failure sequence: freeze → silence → red flash → blackout → reset
func _execute_failure_sequence() -> void:
	print("🔇 Starting failure sequence - stopping all audio...")
	
	# Step 1: Stop all audio immediately
	_stop_all_audio()
	
	# Step 2: Freeze camera and player movement for 3 seconds
	print("🧊 Freezing camera and player movement for 3 seconds...")
	_freeze_player_and_camera(true)
	await get_tree().create_timer(3.0).timeout
	
	# Step 3: Red flash effect
	print("📺 Starting red flash effect...")
	await _create_red_flash_effect()
	
	# Step 4: Black out effect
	print("⚫ Starting blackout effect...")
	await _create_blackout_effect()
	
	# Step 5: Reset the scene
	print("🔄 Resetting scene...")
	await _reset_scene()

# Stop all audio in the game
func _stop_all_audio() -> void:
	print("🔇 Stopping all audio sources...")
	
	# Mute all audio buses
	var master_bus = AudioServer.get_bus_index("Master")
	var music_bus = AudioServer.get_bus_index("Music")
	var sfx_bus = AudioServer.get_bus_index("SFX")
	
	if master_bus != -1:
		AudioServer.set_bus_volume_db(master_bus, -80.0)  # Effectively mute
		print("🔇 Master bus muted")
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, -80.0)
		print("🔇 Music bus muted")
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(sfx_bus, -80.0)
		print("🔇 SFX bus muted")
	
	# Stop all audio players in the scene tree
	_stop_all_audio_players_in_tree(get_tree().root)

# Recursively find and stop all AudioStreamPlayer nodes
func _stop_all_audio_players_in_tree(node: Node) -> void:
	# Check current node
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		if node.has_method("stop"):
			node.stop()
			print("🔇 Stopped audio player: ", node.name)
	
	# Check children recursively
	for child in node.get_children():
		_stop_all_audio_players_in_tree(child)

# Freeze or unfreeze player and camera movement + ALL INPUT (including mouse)
func _freeze_player_and_camera(freeze: bool) -> void:
	print("🧊 Setting complete input freeze state: ", freeze)
	
	# Block ALL input processing globally
	if freeze:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # Lock mouse
		get_tree().paused = false  # Don't pause, just disable input
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # Restore mouse
	
	# Find and freeze the player
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		# Try alternative ways to find player
		player = get_tree().current_scene.get_node_or_null("Player")
		if not player:
			player = get_tree().current_scene.get_node_or_null("FPSController") 
			if not player:
				print("🔍 Searching for player in scene tree...")
				player = _find_player_in_tree(get_tree().current_scene)
	
	if player:
		print("✓ Player found: ", player.name)
		
		# Completely disable ALL player processing
		if freeze:
			if player.has_method("set_physics_process"):
				player.set_physics_process(false)
			if player.has_method("set_process"):
				player.set_process(false)
			if player.has_method("set_process_input"):
				player.set_process_input(false)
			if player.has_method("set_process_unhandled_input"):
				player.set_process_unhandled_input(false)
			if player.has_method("set_process_unhandled_key_input"):
				player.set_process_unhandled_key_input(false)
		else:
			# Re-enable all processing
			if player.has_method("set_physics_process"):
				player.set_physics_process(true)
			if player.has_method("set_process"):
				player.set_process(true)
			if player.has_method("set_process_input"):
				player.set_process_input(true)
			if player.has_method("set_process_unhandled_input"):
				player.set_process_unhandled_input(true)
			if player.has_method("set_process_unhandled_key_input"):
				player.set_process_unhandled_key_input(true)
	else:
		print("❌ Player not found - cannot freeze movement")
	
	# Find and freeze camera (including mouse look)
	var camera = get_tree().get_first_node_in_group("camera")
	if not camera:
		# Try to find camera3d nodes
		camera = _find_camera_in_tree(get_tree().current_scene)
	
	if camera:
		print("✓ Camera found: ", camera.name)
		# Disable ALL camera input processing (including mouse look)
		if freeze:
			if camera.has_method("set_process_input"):
				camera.set_process_input(false)
			if camera.has_method("set_process"):
				camera.set_process(false)
			if camera.has_method("set_process_unhandled_input"):
				camera.set_process_unhandled_input(false)
		else:
			if camera.has_method("set_process_input"):
				camera.set_process_input(true)
			if camera.has_method("set_process"):
				camera.set_process(true)
			if camera.has_method("set_process_unhandled_input"):
				camera.set_process_unhandled_input(true)
	else:
		print("❌ Camera not found")

# Helper function to find player in scene tree
func _find_player_in_tree(node: Node) -> Node:
	if node.name.to_lower().contains("player") or node.name.to_lower().contains("fps"):
		if node.has_method("_physics_process") or node.has_method("_process"):
			return node
	
	for child in node.get_children():
		var result = _find_player_in_tree(child)
		if result:
			return result
	return null

# Helper function to find camera in scene tree  
func _find_camera_in_tree(node: Node) -> Node:
	if node is Camera3D:
		return node
	
	for child in node.get_children():
		var result = _find_camera_in_tree(child)
		if result:
			return result
	return null

# Create red flash effect
func _create_red_flash_effect() -> void:
	print("📺 Creating red flash effect...")
	
	# Create red flash overlay
	glitch_overlay = ColorRect.new()
	glitch_overlay.name = "RedFlashOverlay"
	glitch_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glitch_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glitch_overlay.z_index = 999
	
	# Load the failure glitch shader for red tint effect
	var glitch_shader = load("res://assets/shaders/failure_glitch.gdshader") as Shader
	var shader_material = ShaderMaterial.new()
	shader_material.shader = glitch_shader
	
	# Set shader parameters for intense red flash
	shader_material.set_shader_parameter("saturation_intensity", 4.0)
	shader_material.set_shader_parameter("red_tint", 3.0)
	shader_material.set_shader_parameter("visibility", 0.0)
	shader_material.set_shader_parameter("noise_amount", 0.2)
	shader_material.set_shader_parameter("distortion_strength", 0.05)
	
	glitch_overlay.material = shader_material
	
	# Add to root so it appears over everything
	get_tree().root.add_child(glitch_overlay)
	
	# Create fast, intense red flash animation
	var flash_tween = create_tween()
	
	# Very quick flash sequence: rapid in → brief hold → rapid out
	flash_tween.tween_method(_update_flash_visibility, 0.0, 1.0, 0.05)  # Flash in (faster)
	flash_tween.tween_interval(0.1)  # Brief hold
	flash_tween.tween_method(_update_flash_visibility, 1.0, 0.0, 0.05)  # Flash out (faster)
	
	await flash_tween.finished
	print("📺 Red flash effect completed")

# Create blackout effect
func _create_blackout_effect() -> void:
	print("⚫ Creating blackout effect...")
	
	# Remove red flash overlay first
	if glitch_overlay:
		glitch_overlay.queue_free()
		glitch_overlay = null
	
	# Create black overlay
	var blackout_overlay = ColorRect.new()
	blackout_overlay.name = "BlackoutOverlay"
	blackout_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blackout_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blackout_overlay.z_index = 1000
	blackout_overlay.color = Color(0, 0, 0, 0)  # Start transparent
	
	# Add to root
	get_tree().root.add_child(blackout_overlay)
	
	# Create fast blackout animation
	var blackout_tween = create_tween()
	blackout_tween.tween_property(blackout_overlay, "color:a", 1.0, 0.15)  # Faster fade to black
	blackout_tween.tween_interval(0.2)  # Brief hold black screen
	
	await blackout_tween.finished
	
	# Clean up
	blackout_overlay.queue_free()
	print("⚫ Blackout effect completed")

# Update flash visibility
func _update_flash_visibility(value: float) -> void:
	if glitch_overlay and glitch_overlay.material:
		glitch_overlay.material.set_shader_parameter("visibility", value)

# Play glitch sound effect
func _play_glitch_sound() -> void:
	print("🔊 Playing safe glitch sound effect...")
	
	# Create audio player for glitch sound
	var glitch_audio = AudioStreamPlayer.new()
	get_tree().root.add_child(glitch_audio)
	
	# Create a simple sine wave glitch sound (safe, no random noise)
	var glitch_stream = AudioStreamGenerator.new()
	glitch_stream.mix_rate = 22050
	glitch_stream.buffer_length = 0.5
	glitch_audio.stream = glitch_stream
	glitch_audio.volume_db = -10.0  # Not too loud
	
	# Play the sound
	glitch_audio.play()
	
	# Remove audio player after sound finishes
	await get_tree().create_timer(0.6).timeout
	if glitch_audio:
		glitch_audio.queue_free()

# Reset the current scene
func _reset_scene() -> void:
	print("🔄 Resetting demo scene...")
	
	# Unfreeze player and camera before scene change
	_freeze_player_and_camera(false)
	
	# Clean up glitch overlay
	if glitch_overlay:
		glitch_overlay.queue_free()
		glitch_overlay = null
	
	# Restore audio levels
	_restore_audio()
	
	# Reset game state
	is_game_over = false
	
	# Reload the demo scene
	var result = get_tree().change_scene_to_file("res://scenes/demo.tscn")
	if result != OK:
		print("❌ Failed to reset scene, error: ", result)

# Restore audio levels after failure
func _restore_audio() -> void:
	print("🔊 Restoring audio levels...")
	
	var master_bus = AudioServer.get_bus_index("Master")
	var music_bus = AudioServer.get_bus_index("Music")
	var sfx_bus = AudioServer.get_bus_index("SFX")
	
	if master_bus != -1:
		AudioServer.set_bus_volume_db(master_bus, 0.0)
		print("🔊 Master bus restored")
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, 0.0)
		print("🔊 Music bus restored")
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(sfx_bus, 0.0)
		print("🔊 SFX bus restored")
