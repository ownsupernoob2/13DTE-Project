extends Node3D

# Lever system for sedation validation
# This script manages the three levers and sedation button in demo.tscn

# Constants
const MAX_VALUE = 100
const MIN_ROTATION_DEGREES = -30.0
const MAX_ROTATION_DEGREES = 30.0
const BASE_FONT_SIZE = 48

# Lever values (0-100)
var counter1: int = 0
var counter2: int = 0
var counter3: int = 0

# State tracking
var is_sedated: bool = false
var sedation_button_pressed: bool = false

# Node references
@onready var screen: RichTextLabel = $"Screen"
@onready var screen2: RichTextLabel = $"Screen2"  
@onready var screen3: RichTextLabel = $"Screen3"
@onready var handle: MeshInstance3D = $"Handle"
@onready var handle2: MeshInstance3D = $"Handle2"
@onready var handle3: MeshInstance3D = $"Handle3"
@onready var button_audio_player: AudioStreamPlayer3D = $"SedateButton/AudioStreamPlayer3D"
@onready var button_animation_player: AnimationPlayer = $"SedateButton/AnimationPlayer"
@onready var steam_audio_player: AudioStreamPlayer3D = $"SteamAudioPlayer"
@onready var smoke_particles: GPUParticles3D = $"SmokeParticles"

func _ready():
	print("Lever system initialized")
	update_displays()
	
	# Reset sedation state
	is_sedated = false
	sedation_button_pressed = false
	
	# Test GameManager connection
	print("🔍 Testing GameManager connection...")
	if GameManager:
		print("✓ GameManager is available")
		print("GameManager type: ", GameManager.get_class())
		if GameManager.has_method("handle_game_failure"):
			print("✓ handle_game_failure method is available")
		else:
			print("❌ handle_game_failure method NOT available")
	else:
		print("❌ GameManager is NOT available")

# Function to set value directly (called by player)
func set_lever_value(lever_index: int, value: int) -> void:
	value = clamp(value, 0, MAX_VALUE)
	print("Lever.gd - set_lever_value called: index=", lever_index, " value=", value)
	
	var screen_node: RichTextLabel
	var handle_node: MeshInstance3D
	
	match lever_index:
		1:
			if counter1 == value:
				print("Lever 1: No change needed (already ", value, ")")
				return  # No change needed
			print("Lever 1: Updating from ", counter1, " to ", value)
			counter1 = value
			screen_node = screen
			handle_node = handle
		2:
			if counter2 == value:
				print("Lever 2: No change needed (already ", value, ")")
				return  # No change needed
			print("Lever 2: Updating from ", counter2, " to ", value)
			counter2 = value
			screen_node = screen2
			handle_node = handle2
		3:
			if counter3 == value:
				print("Lever 3: No change needed (already ", value, ")")
				return  # No change needed
			print("Lever 3: Updating from ", counter3, " to ", value)
			counter3 = value
			screen_node = screen3
			handle_node = handle3
		_:
			print("ERROR: Invalid lever index: ", lever_index)
			return

	# Update display and handle rotation
	update_displays()

# Update all displays and handle positions
func update_displays() -> void:
	# Handle null checks
	if not screen or not screen2 or not screen3:
		print("Warning: Screen nodes not found!")
		return
	if not handle or not handle2 or not handle3:
		print("Warning: Handle nodes not found!")
		return
	
	# Adjust font size based on values (smaller for 100)
	var font_size1 = BASE_FONT_SIZE if counter1 != 100 else int(BASE_FONT_SIZE * 0.75)
	var font_size2 = BASE_FONT_SIZE if counter2 != 100 else int(BASE_FONT_SIZE * 0.75)
	var font_size3 = BASE_FONT_SIZE if counter3 != 100 else int(BASE_FONT_SIZE * 0.75)
	
	screen.add_theme_font_size_override("normal_font_size", font_size1)
	screen2.add_theme_font_size_override("normal_font_size", font_size2)
	screen3.add_theme_font_size_override("normal_font_size", font_size3)
	
	screen.add_theme_color_override("default_color", get_color(counter1))
	screen2.add_theme_color_override("default_color", get_color(counter2))
	screen3.add_theme_color_override("default_color", get_color(counter3))
	
	# Set handle rotations based on current values
	var rotation_range = MAX_ROTATION_DEGREES - MIN_ROTATION_DEGREES
	handle.rotation.z = deg_to_rad(MIN_ROTATION_DEGREES + (float(counter1) / MAX_VALUE) * rotation_range)
	handle2.rotation.z = deg_to_rad(MIN_ROTATION_DEGREES + (float(counter2) / MAX_VALUE) * rotation_range)
	handle3.rotation.z = deg_to_rad(MIN_ROTATION_DEGREES + (float(counter3) / MAX_VALUE) * rotation_range)
	
	screen.text = "[center]" + str(counter1) + "[/center]"
	screen2.text = "[center]" + str(counter2) + "[/center]"
	screen3.text = "[center]" + str(counter3) + "[/center]"

# Get current combination as three 0-100 values
func get_combination() -> Array:
	return [counter1, counter2, counter3]

# Reset all levers to 0
func reset_levers() -> void:
	set_lever_value(1, 0)
	set_lever_value(2, 0)
	set_lever_value(3, 0)
	is_sedated = false
	sedation_button_pressed = false

# Main sedation button function - validates combination immediately
func press_sedation_button() -> void:
	if sedation_button_pressed:
		print("Sedation already administered!")
		return
	
	sedation_button_pressed = true
	print("💉 Sedation button pressed - validating combination...")
	
	# Play steam hissing sound effect
	_play_steam_sound()
	
	# Get current lever combination
	var combination = get_combination()
	print("Current lever combination: ", combination[0], "/", combination[1], "/", combination[2])
	
	# Get the correct ratios from monitor system
	var monitor_system = get_node_or_null("../Computer/ComputerCamera/Monitor/Monitor/SubViewport/Control/Console")
	if not monitor_system:
		monitor_system = get_node_or_null("../Monitor/Monitor/SubViewport/Control/Console")
	if not monitor_system:
		monitor_system = get_node_or_null("../../Monitor/Monitor/SubViewport/Control/Console")
	if not monitor_system:
		monitor_system = get_node_or_null("../Computer/Monitor/SubViewport/Control/Console")
	
	if monitor_system and monitor_system.has_method("get_current_liquid_ratios"):
		var correct_ratios = monitor_system.get_current_liquid_ratios()
		var tolerance = 3  # Allow 3 point tolerance for precision
		
		print("Expected ratios: ", correct_ratios)
		print("Player ratios: ", combination)
		
		# Check if combination is correct
		var liquid_a_correct = abs(combination[0] - correct_ratios[0]) <= tolerance
		var liquid_b_correct = abs(combination[1] - correct_ratios[1]) <= tolerance
		var liquid_c_correct = abs(combination[2] - correct_ratios[2]) <= tolerance
		
		if liquid_a_correct and liquid_b_correct and liquid_c_correct:
			print("✅ CORRECT COMBINATION! Sedation successful.")
			
			# Play button sound
			if button_audio_player:
				button_audio_player.play()
			
			# Play button press animation
			_animate_button_press()
			
			# Show visual indication that sedation is working
			_show_sedation_success()
			
			# Mark as sedated
			is_sedated = true
			print("✓ Sedation system activated!")
			
		else:
			print("❌ INCORRECT COMBINATION! Expected: ", correct_ratios, " Got: ", combination)
			print("FAILURE! Wrong sedation ratios. Expected: ", correct_ratios, " Got: ", combination)
			print("❌ SEDATION FAILED! Incorrect chemical combination. This will restart the game.")
			
			# Trigger failure system immediately with explicit checks
			print("🔍 Checking GameManager availability...")
			if GameManager:
				print("✓ GameManager found, checking for handle_game_failure method...")
				if GameManager.has_method("handle_game_failure"):
					print("✓ handle_game_failure method found, calling now...")
					print("🧪 Testing immediate failure first...")
					GameManager.immediate_failure_test()
					await get_tree().create_timer(1.0).timeout
					
					print("🚀 Now calling full failure sequence...")
					GameManager.handle_game_failure()
					print("🚀 GameManager.handle_game_failure() called!")
				else:
					print("❌ handle_game_failure method not found in GameManager")
					print("Available GameManager methods:")
					for method in GameManager.get_method_list():
						if not method.name.begins_with("_"):
							print("  - ", method.name)
					_fallback_failure_handling()
			else:
				print("❌ GameManager not found - cannot trigger failure sequence")
				_fallback_failure_handling()
	else:
		print("❌ Monitor system not found! Cannot validate combination.")
		print("Available nodes in scene:")
		_debug_print_scene_tree(get_tree().current_scene, 0)
		
		# For testing, assume correct and continue
		print("⚠️ Continuing without validation for testing...")
		
		# Play button sound
		if button_audio_player:
			button_audio_player.play()
		
		# Play button press animation
		_animate_button_press()
		
		# Show visual indication that sedation is working
		_show_sedation_success()
		
		# Mark as sedated
		is_sedated = true
		print("✓ Sedation system activated!")

# Animate the button press
func _animate_button_press() -> void:
	if button_animation_player:
		print("🎬 Playing button press animation")
		button_animation_player.play("ButtonPress")
	else:
		print("⚠️ Button animation player not found - using fallback tween")
		# Fallback to tween if AnimationPlayer not available
		var button_node = get_node_or_null("SedateButton/button")
		if not button_node:
			print("Button node not found for animation!")
			return
		
		# Create button press animation using tween
		var tween = create_tween()
		var original_position = button_node.position
		var pressed_position = original_position + Vector3(0, -0.02, 0)  # Move down 2cm
		
		# Press down
		tween.tween_property(button_node, "position", pressed_position, 0.1)
		# Hold briefly
		tween.tween_interval(0.1)
		# Release back up
		tween.tween_property(button_node, "position", original_position, 0.1)

# Show sedation success visual feedback
func _show_sedation_success() -> void:
	print("💊 Showing sedation success indicators")
	
	# Play steam hissing sound for success
	_play_steam_sound()
	
	# Start smoke particles if available
	_activate_smoke_particles()
	
	# Trigger pod sedation color change
	_trigger_pod_sedation_effect()
	
	# Flash screens green briefly
	var success_color = Color.GREEN
	var original_color1 = get_color(counter1)
	var original_color2 = get_color(counter2)
	var original_color3 = get_color(counter3)
	
	# Flash green
	screen.add_theme_color_override("default_color", success_color)
	screen2.add_theme_color_override("default_color", success_color)
	screen3.add_theme_color_override("default_color", success_color)
	
	# Wait then restore colors
	await get_tree().create_timer(0.3).timeout
	screen.add_theme_color_override("default_color", original_color1)
	screen2.add_theme_color_override("default_color", original_color2)
	screen3.add_theme_color_override("default_color", original_color3)

# Check if alien is sedated
func is_alien_sedated() -> bool:
	return is_sedated

# Activate smoke particles for successful sedation
func _activate_smoke_particles() -> void:
	print("💨 Activating smoke particles...")
	
	# Try to find smoke particles node
	if not smoke_particles:
		# Try to find it by searching common paths
		smoke_particles = get_node_or_null("SmokeParticles")
		if not smoke_particles:
			smoke_particles = get_node_or_null("SedateButton/SmokeParticles")
		if not smoke_particles:
			smoke_particles = get_node_or_null("../SmokeParticles")
	
	if smoke_particles:
		print("✓ Found smoke particles, activating...")
		smoke_particles.emitting = true
		
		# Stop particles after a few seconds
		await get_tree().create_timer(3.0).timeout
		smoke_particles.emitting = false
		print("✓ Smoke particles deactivated")
	else:
		print("❌ No smoke particles node found - creating fallback effect...")
		# Create a simple fallback particle system
		_create_fallback_smoke_effect()

# Create fallback smoke effect if no particle node exists
func _create_fallback_smoke_effect() -> void:
	print("🆘 Creating fallback smoke particle system...")
	
	var particles = GPUParticles3D.new()
	particles.name = "FallbackSmokeParticles"
	add_child(particles)
	
	# Configure smoke-like particle system
	particles.emitting = true
	particles.amount = 50
	particles.lifetime = 3.0
	
	# Create process material for smoke effect
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3.UP
	material.initial_velocity_min = 1.0
	material.initial_velocity_max = 3.0
	material.gravity = Vector3(0, -1, 0)
	material.scale_min = 0.5
	material.scale_max = 1.5
	
	particles.process_material = material
	
	# Auto-remove after effect ends
	await get_tree().create_timer(4.0).timeout
	particles.queue_free()

# Trigger pod sedation visual effect
func _trigger_pod_sedation_effect() -> void:
	print("🏺 Triggering pod sedation effect...")
	
	# Find the pod system
	var pod = _find_pod_system()
	
	if pod:
		if pod.has_method("apply_sedation_effect"):
			pod.apply_sedation_effect()
			print("✓ Pod sedation effect triggered")
		else:
			print("⚠️ Pod found but no sedation effect method available")
	else:
		print("❌ Pod system not found")

func _find_pod_system() -> Node:
	# Search common pod paths
	var pod_paths = [
		"../Pod11",
		"../../Pod11", 
		"../pod_11",
		"../../pod_11",
		"../../scenes/components/Pod11",
		"../../../Pod11"
	]
	
	for path in pod_paths:
		var pod = get_node_or_null(path)
		if pod:
			print("✓ Found pod at: ", path)
			return pod
	
	# Try searching in current scene
	var scene_root = get_tree().current_scene
	if scene_root:
		var pod = _find_node_by_name(scene_root, "Pod11")
		if not pod:
			pod = _find_node_by_name(scene_root, "pod_11")
		if pod:
			print("✓ Found pod in scene: ", pod.name)
			return pod
	
	return null

func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name.to_lower().contains(target_name.to_lower()):
		return node
	
	for child in node.get_children():
		var result = _find_node_by_name(child, target_name)
		if result:
			return result
	return null

# Debug helper to print scene tree
func _debug_print_scene_tree(node: Node, depth: int) -> void:
	var indent = ""
	for i in range(depth):
		indent += "  "
	print(indent + node.name + " (" + node.get_class() + ")")
	
	if depth < 4:  # Limit depth to prevent spam
		for child in node.get_children():
			_debug_print_scene_tree(child, depth + 1)

# Play steam hissing sound effect
func _play_steam_sound() -> void:
	print("🎵 Playing steam hissing sound effect...")
	
	# Create steam audio player if not exist as child node
	if not steam_audio_player:
		steam_audio_player = AudioStreamPlayer3D.new()
		steam_audio_player.name = "SteamAudioPlayer"
		add_child(steam_audio_player)
		
		# Load steam hissing audio
		var steam_sound = load("res://assets/music/sfx/steam_hissing.mp3") as AudioStream
		if steam_sound:
			steam_audio_player.stream = steam_sound
			print("✓ Steam sound loaded successfully")
		else:
			print("❌ Failed to load steam sound")
			return
	
	# Play the steam sound
	if steam_audio_player and steam_audio_player.stream:
		steam_audio_player.play()
		print("✓ Steam hissing sound played")
	else:
		print("❌ Steam audio player not available or no stream")

# Fallback failure handling if GameManager fails
func _fallback_failure_handling() -> void:
	print("🔧 Using fallback failure handling...")
	print("Resetting levers as fallback...")
	await get_tree().create_timer(1.0).timeout
	reset_levers()
	
	# Try to reload scene manually
	print("Attempting manual scene reload...")
	await get_tree().create_timer(0.5).timeout
	var result = get_tree().change_scene_to_file("res://scenes/demo.tscn")
	if result != OK:
		print("❌ Manual scene reload failed: ", result)

# Get color based on value (green for higher values)
func get_color(value: int) -> Color:
	if value >= 80:
		return Color(0.0, 1.0, 0.0)  # Bright green
	elif value >= 60:
		return Color(0.5, 1.0, 0.0)  # Yellow-green
	elif value >= 40:
		return Color(1.0, 1.0, 0.0)  # Yellow
	elif value >= 20:
		return Color(1.0, 0.5, 0.0)  # Orange
	else:
		return Color(1.0, 0.0, 0.0)  # Red
