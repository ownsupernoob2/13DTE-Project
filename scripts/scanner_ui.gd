extends Control

# 2D UI for the Medical Scanner - handles the scanning mini-game

# Node references
@onready var scan_area: ColorRect = $MainPanel/ScanArea
@onready var scan_line_vertical: ColorRect = $MainPanel/ScanArea/ScanLineVertical
@onready var scan_line_horizontal: ColorRect = $MainPanel/ScanArea/ScanLineHorizontal
@onready var target_zone: ColorRect = $MainPanel/ScanArea/TargetZone
@onready var frequency_slider: VSlider = $MainPanel/FrequencyPanel/FrequencySlider
@onready var frequency_display: Label = $MainPanel/FrequencyPanel/FrequencyDisplay
@onready var target_indicator: Label = $MainPanel/FrequencyPanel/TargetIndicator
@onready var scan_button: Button = $MainPanel/ControlPanel/ScanButton
@onready var status_label: Label = $MainPanel/ControlPanel/StatusLabel
@onready var results_panel: Panel = $MainPanel/ResultsPanel
@onready var eye_color_label: Label = $MainPanel/ResultsPanel/EyeColorLabel
@onready var blood_type_label: Label = $MainPanel/ResultsPanel/BloodTypeLabel
@onready var close_button: Button = $MainPanel/ResultsPanel/CloseButton
@onready var audio_player: AudioStreamPlayer = $AudioPlayer
@onready var beep_timer: Timer = $BeepTimer

# Scanner state
var is_scanning: bool = false
var scan_speed: float = 1.0
var target_frequency: float = 440.0
var current_frequency: float = 440.0
var frequency_tolerance: float = 10.0
var is_frequency_matched: bool = false

# New dynamic scanning modes
var scan_mode: String = "standard"  # standard, deep_tissue, neural_probe, contamination
var equipment_malfunction: bool = false
var scan_interference: float = 0.0
var requires_calibration: bool = false

# Audio system for proximity feedback
var scanning_audio_stream: AudioStream = null
var is_audio_playing: bool = false
var base_audio_volume: float = -20.0  # Base volume when far from target

# Scan line positions and movement
var scan_line_x: float = 0.0
var scan_line_y: float = 0.0
var scan_direction_x: int = 1
var scan_direction_y: int = 1

# Sequential scanning system - PSX style
var current_scan_phase: int = 0  # 0 = frequency, 1 = x-axis, 2 = y-axis, 3 = complete
var x_line_locked: bool = false
var y_line_locked: bool = false
var x_locked_position: float = 0.0
var y_locked_position: float = 0.0

# Target zone (hidden - random position each scan)
var target_zone_x: float = 0.0
var target_zone_y: float = 0.0
var zone_tolerance: float = 15.0  # Slightly more forgiving since it's hidden

# Game progression
var scan_level: int = 1
var scans_completed: int = 0

# Current scan data
var current_scan_data: Dictionary = {}

# Audio beeping - PSX style
var beep_frequency: float = 1.0
var base_beep_rate: float = 1.0

# Noise background animation
var noise_time: float = 0.0

signal scan_completed(results: Dictionary)
signal scan_failed()

func _ready() -> void:
	# Connect signals
	frequency_slider.value_changed.connect(_on_frequency_changed)
	scan_button.pressed.connect(_on_scan_pressed)
	close_button.pressed.connect(_on_close_results)
	# Note: Removed beep_timer connection since we're using continuous audio now
	
	# PSX-style UI setup
	_setup_psx_style()
	
	# Generate random target zone position (hidden from player)
	_randomize_target_zone()
	
	# Set initial state
	_reset_scanner()
	
	# Force UI to be visible and rendered
	visible = true
	modulate = Color.WHITE
	
	# IMPORTANT: Ensure this control can receive ALL input events with highest priority
	set_process_unhandled_input(true)
	set_process_input(true)
	process_mode = Node.PROCESS_MODE_ALWAYS  # Always process input
	
	# Focus settings for input - grab focus aggressively
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP  # Capture all mouse events
	
	print("Scanner UI initialized and ready for input")

func _setup_psx_style() -> void:
	# PSX-style colors and feel
	if target_indicator:
		target_indicator.modulate = Color(0.0, 1.0, 0.2, 1.0)  # Bright green
	if frequency_display:
		frequency_display.modulate = Color(1.0, 0.8, 0.0, 1.0)  # Amber
	if status_label:
		status_label.modulate = Color(0.8, 0.8, 0.8, 1.0)  # Light gray
	
	# Hide target zone - player must use audio cues only
	if target_zone:
		target_zone.visible = false
	
	# PSX-style scan line colors
	if scan_line_vertical:
		scan_line_vertical.color = Color(0.0, 1.0, 0.2, 0.8)  # Bright green
	if scan_line_horizontal:
		scan_line_horizontal.color = Color(0.0, 1.0, 0.2, 0.8)  # Bright green
	
	# Create pixelated noise background with green tunnels
	_create_noise_background()

func _create_noise_background() -> void:
	if not scan_area:
		print("Scan area not found for noise background")
		return
	
	# Create a TextureRect for the noise background
	var noise_background = TextureRect.new()
	noise_background.name = "NoiseBackground"
	noise_background.stretch_mode = TextureRect.STRETCH_TILE
	
	# Generate procedural noise texture
	var noise_texture = _generate_noise_texture(256, 256)  # 256x256 for pixelated look
	noise_background.texture = noise_texture
	
	# Position and size the background to fill the scan area
	noise_background.position = Vector2.ZERO
	noise_background.size = scan_area.size
	noise_background.modulate = Color(0.0, 0.8, 0.1, 0.3)  # Green tint with transparency
	
	# Add as the first child so it appears behind everything
	scan_area.add_child(noise_background)
	scan_area.move_child(noise_background, 0)
	
	print("Created noise background texture")

func _generate_noise_texture(width: int, height: int) -> ImageTexture:
	var image = Image.create(width, height, false, Image.FORMAT_RGB8)
	
	# Generate pixelated cloudy noise with tunnel-like patterns
	for y in range(height):
		for x in range(width):
			# Create multiple noise layers for complexity
			var noise1 = _simple_noise(x * 0.02, y * 0.02, 0.0)  # Large scale clouds
			var noise2 = _simple_noise(x * 0.05, y * 0.05, 100.0)  # Medium detail
			var noise3 = _simple_noise(x * 0.1, y * 0.1, 200.0)  # Fine detail
			
			# Create tunnel effect by using distance from center
			var center_x = width / 2.0
			var center_y = height / 2.0
			var distance = sqrt((x - center_x) * (x - center_x) + (y - center_y) * (y - center_y))
			var tunnel_factor = 1.0 - (distance / (width * 0.5))  # Fade towards edges
			tunnel_factor = max(0.0, tunnel_factor)
			
			# Combine noise layers with tunnel effect
			var combined_noise = (noise1 * 0.5 + noise2 * 0.3 + noise3 * 0.2) * tunnel_factor
			combined_noise = clamp(combined_noise, 0.0, 1.0)
			
			# Create pixelated effect by quantizing values
			var pixelated = floor(combined_noise * 8.0) / 8.0  # 8 levels for pixelated look
			
			# Set color (grayscale for now, will be tinted green by modulate)
			var color_value = pixelated
			image.set_pixel(x, y, Color(color_value, color_value, color_value))
	
	# Create texture from image
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture

func _simple_noise(x: float, y: float, seed_offset: float) -> float:
	# Simple pseudo-random noise function
	var hash = sin(x * 12.9898 + y * 78.233 + seed_offset) * 43758.5453
	return fmod(abs(hash), 1.0)

func _randomize_target_zone() -> void:
	# Generate random target position each scan
	var margin = 50.0  # Keep away from edges
	target_zone_x = randf_range(margin, scan_area.size.x - margin - target_zone.size.x)
	target_zone_y = randf_range(margin, scan_area.size.y - margin - target_zone.size.y)
	
	# Position the hidden target zone
	target_zone.position = Vector2(target_zone_x, target_zone_y)
	
	print("DEBUG: Hidden target at ", target_zone_x, ", ", target_zone_y)

func _input(event: InputEvent) -> void:
	if not is_scanning:
		return
		
	print("Scanner UI received input event: ", event)
	
	# Handle input with highest priority
	var handled = false
		
	# Space bar OR Enter to lock current scan line - use direct key detection
	if event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		print("Space/Enter detected - attempting to lock line")
		_lock_current_scan_line()
		handled = true
	
	# Mouse wheel for frequency adjustment (much more intuitive)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			print("Mouse wheel UP detected in scanner UI")
			_adjust_frequency(5.0)  # Smaller increments for precise control
			handled = true
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			print("Mouse wheel DOWN detected in scanner UI")
			_adjust_frequency(-5.0)  # Smaller increments for precise control
			handled = true
	
	# Arrow keys for frequency adjustment (backup method)
	elif event.is_action_pressed("ui_up"):
		_adjust_frequency(10.0)
		handled = true
	elif event.is_action_pressed("ui_down"):
		_adjust_frequency(-10.0)
		handled = true
	elif event.is_action("ui_up"):
		_adjust_frequency(1.0)  # Fine adjustment when held
		handled = true
	elif event.is_action("ui_down"):
		_adjust_frequency(-1.0)  # Fine adjustment when held
		handled = true
	
	# If we handled the event, mark it as consumed
	if handled:
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	# Backup input handler for space bar and enter
	if not is_scanning:
		return
		
	print("Scanner UI unhandled input: ", event)
		
	if event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		print("Space/Enter caught in _unhandled_input - attempting to lock line")
		_lock_current_scan_line()
		get_viewport().set_input_as_handled()
	
	# Also handle mouse wheel in unhandled input as backup
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			print("Mouse wheel UP caught in unhandled_input")
			_adjust_frequency(5.0)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			print("Mouse wheel DOWN caught in unhandled_input")
			_adjust_frequency(-5.0)
			get_viewport().set_input_as_handled()

# Handle input forwarded from the medical scanner node
func _handle_space_input() -> void:
	if not is_scanning:
		print("Space input received but scanner not active")
		return
	
	print("Scanner UI handling forwarded space input")
	_lock_current_scan_line()

func _handle_wheel_input(direction: int) -> void:
	if not is_scanning:
		print("Wheel input received but scanner not active")
		return
	
	print("Scanner UI handling forwarded wheel input: ", direction)
	var delta = 5.0 * direction  # 5 Hz per wheel step
	_adjust_frequency(delta)

func _adjust_frequency(delta: float) -> void:
	var old_value = frequency_slider.value
	frequency_slider.value = clamp(frequency_slider.value + delta, frequency_slider.min_value, frequency_slider.max_value)
	print("=== FREQUENCY ADJUSTMENT ===")
	print("Delta: ", delta)
	print("Old value: ", old_value)
	print("New value: ", frequency_slider.value)
	print("Slider range: ", frequency_slider.min_value, " to ", frequency_slider.max_value)
	print("===========================")
	_on_frequency_changed(frequency_slider.value)

func _lock_current_scan_line() -> void:
	print("=== LOCK ATTEMPT ===")
	print("Current phase: ", current_scan_phase)
	print("is_scanning: ", is_scanning)
	print("is_frequency_matched: ", is_frequency_matched)
	print("x_line_locked: ", x_line_locked)
	print("y_line_locked: ", y_line_locked)
	print("==================")
	
	match current_scan_phase:
		1:  # X-axis scanning
			if not x_line_locked:
				x_line_locked = true
				x_locked_position = scan_line_x
				current_scan_phase = 2  # Move to Y-axis
				status_label.text = "X-AXIS LOCKED - NOW SCANNING Y-AXIS"
				status_label.modulate = Color(1.0, 0.8, 0.0, 1.0)  # Amber
				print("SUCCESS: X-axis locked at position: ", x_locked_position)
			else:
				print("X-axis already locked")
		2:  # Y-axis scanning  
			if not y_line_locked:
				y_line_locked = true
				y_locked_position = scan_line_y
				current_scan_phase = 3  # Complete
				print("SUCCESS: Y-axis locked at position: ", y_locked_position)
				_complete_scan_attempt()
			else:
				print("Y-axis already locked")
		0:
			print("Cannot lock - frequency not matched yet")
			print("Current freq: ", current_frequency, " Target: ", target_frequency)
			print("Difference: ", abs(current_frequency - target_frequency))
			print("Tolerance: ", frequency_tolerance)
		3:
			print("Scan already complete")
		_:
			print("Unknown scan phase: ", current_scan_phase)

func _process(delta: float) -> void:
	if not is_scanning:
		return
		
	# Update scan line animations
	_update_scan_lines(delta)
	
	# Update frequency matching
	_update_frequency_matching()
	
	# Update audio cues (now using continuous audio with volume)
	_update_audio_cues(delta)
	
	# Fill audio buffer for continuous scanning sound
	if is_audio_playing:
		_fill_scanning_audio_buffer()
	
	# Animate noise background
	_animate_noise_background()

func _update_scan_lines(delta: float) -> void:
	# Sequential scanning system - only one line moves at a time
	match current_scan_phase:
		1:  # X-axis scanning phase
			if not x_line_locked:
				# Move vertical scan line
				scan_line_x += scan_direction_x * scan_speed * 100 * delta
				if scan_line_x <= 0:
					scan_line_x = 0
					scan_direction_x = 1
				elif scan_line_x >= scan_area.size.x - scan_line_vertical.size.x:
					scan_line_x = scan_area.size.x - scan_line_vertical.size.x
					scan_direction_x = -1
				
				scan_line_vertical.position.x = scan_line_x
				scan_line_vertical.visible = true
			else:
				# Keep X line at locked position
				scan_line_vertical.position.x = x_locked_position
				scan_line_vertical.visible = true
			
			# Hide horizontal line during X scanning
			scan_line_horizontal.visible = false
			
		2:  # Y-axis scanning phase
			if not y_line_locked:
				# Move horizontal scan line
				scan_line_y += scan_direction_y * scan_speed * 80 * delta
				if scan_line_y <= 0:
					scan_line_y = 0
					scan_direction_y = 1
				elif scan_line_y >= scan_area.size.y - scan_line_horizontal.size.y:
					scan_line_y = scan_area.size.y - scan_line_horizontal.size.y
					scan_direction_y = -1
				
				scan_line_horizontal.position.y = scan_line_y
				scan_line_horizontal.visible = true
			else:
				# Keep Y line at locked position
				scan_line_horizontal.position.y = y_locked_position
				scan_line_horizontal.visible = true
			
			# Keep X line visible and locked
			scan_line_vertical.position.x = x_locked_position
			scan_line_vertical.visible = true
			
		3:  # Both lines locked - show intersection
			scan_line_vertical.position.x = x_locked_position
			scan_line_horizontal.position.y = y_locked_position
			scan_line_vertical.visible = true
			scan_line_horizontal.visible = true
			
		_:  # Phase 0 or other - hide lines
			scan_line_vertical.visible = false
			scan_line_horizontal.visible = false

func _update_frequency_matching() -> void:
	current_frequency = frequency_slider.value
	frequency_display.text = str(int(current_frequency)) + " Hz"
	
	var frequency_difference = abs(current_frequency - target_frequency)
	is_frequency_matched = frequency_difference <= frequency_tolerance
	
	# PSX-style visual feedback for frequency matching
	if is_frequency_matched:
		frequency_slider.modulate = Color(0.0, 1.0, 0.2, 1.0)  # Bright green
		if current_scan_phase == 0:
			current_scan_phase = 1  # Start X-axis scanning
			status_label.text = "FREQ LOCKED - SCANNING X-AXIS (SPACE TO LOCK)"
			status_label.modulate = Color(0.0, 1.0, 0.2, 1.0)
	else:
		frequency_slider.modulate = Color(1.0, 0.3, 0.3, 1.0)  # Red
		current_scan_phase = 0  # Reset to frequency matching
		var direction = "UP" if current_frequency < target_frequency else "DOWN"
		status_label.text = "ADJUST FREQ " + direction + " - TARGET: " + str(int(target_frequency)) + "Hz"
		status_label.modulate = Color(1.0, 0.8, 0.0, 1.0)  # Amber

func _update_audio_cues(delta: float) -> void:
	if not is_scanning:
		_stop_scanning_audio()
		return
		
	if not is_frequency_matched:
		_stop_scanning_audio()
		return
		
	var proximity = 0.0
	
	# Calculate proximity based on current scan phase
	match current_scan_phase:
		1:  # X-axis scanning
			if not x_line_locked:
				proximity = 1.0 - abs(scan_line_x + scan_line_vertical.size.x/2 - (target_zone_x + target_zone.size.x/2)) / (scan_area.size.x / 2)
			else:
				proximity = 0.0  # No audio when locked
		2:  # Y-axis scanning
			if not y_line_locked:
				proximity = 1.0 - abs(scan_line_y + scan_line_horizontal.size.y/2 - (target_zone_y + target_zone.size.y/2)) / (scan_area.size.y / 2)
			else:
				proximity = 0.0  # No audio when locked
		_:
			proximity = 0.0
	
	proximity = max(0.0, proximity)  # Clamp to positive
	
	# Start scanning audio if frequency is matched and we're in scanning phase
	if proximity > 0.0:
		_start_scanning_audio()
		_update_audio_volume_by_proximity(proximity)
	else:
		_stop_scanning_audio()

func _start_scanning_audio() -> void:
	if not audio_player or is_audio_playing:
		return
		
	# Try to load an MP3 scanning sound (you can replace this path with your actual MP3)
	if scanning_audio_stream == null:
		# For now, create a simple looping tone - replace with MP3 loading later
		var generator = AudioStreamGenerator.new()
		generator.mix_rate = 22050.0
		generator.buffer_length = 1.0  # 1 second buffer for smooth looping
		scanning_audio_stream = generator
	
	audio_player.stream = scanning_audio_stream
	audio_player.volume_db = base_audio_volume
	audio_player.play()
	is_audio_playing = true
	print("Started scanning audio")

func _stop_scanning_audio() -> void:
	if audio_player and is_audio_playing:
		audio_player.stop()
		is_audio_playing = false
		print("Stopped scanning audio")

func _update_audio_volume_by_proximity(proximity: float) -> void:
	if not audio_player or not is_audio_playing:
		return
		
	# Convert proximity (0.0 to 1.0) to volume (-40dB to 0dB)
	var target_volume = base_audio_volume + (proximity * (0.0 - base_audio_volume))
	
	# Extra boost when very close to target
	if proximity > 0.8:
		target_volume = min(target_volume + 5.0, 0.0)  # Extra loud when very close
	elif proximity > 0.6:
		target_volume = min(target_volume + 2.0, 0.0)  # Louder when close
	
	audio_player.volume_db = target_volume
	
	# Debug output for proximity and volume
	if proximity > 0.1:
		var volume_percent = int((target_volume - base_audio_volume) / (0.0 - base_audio_volume) * 100)
		print("Proximity: ", int(proximity * 100), "% - Volume: ", int(target_volume), "dB (", volume_percent, "%)")

# Fill audio buffer for AudioStreamGenerator if needed
func _fill_scanning_audio_buffer() -> void:
	if not audio_player or not is_audio_playing:
		return
		
	if not audio_player.stream is AudioStreamGenerator:
		return
		
	var playback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		return
		
	# Fill with a scanning beep pattern
	var frequency = 440.0  # Base scanning frequency
	var sample_rate = 22050.0
	var frames_available = playback.get_frames_available()
	
	if frames_available > 0:
		var frames_to_fill = min(frames_available, 512)  # Fill small chunks
		
		for i in range(frames_to_fill):
			var t = float(i) / sample_rate
			# Create a pulsing tone that sounds like a medical scanner
			var pulse = sin(t * 3.0 * 2.0 * PI) * 0.5 + 0.5  # 3Hz pulse rate
			var tone = sin(t * frequency * 2.0 * PI) * 0.3 * pulse  # Modulated tone
			playback.push_frame(Vector2(tone, tone))  # Stereo

func _complete_scan_attempt() -> void:
	print("=== SCAN ATTEMPT COMPLETE ===")
	print("X locked position: ", x_locked_position)
	print("Y locked position: ", y_locked_position)
	print("Target zone center X: ", target_zone_x + target_zone.size.x/2)
	print("Target zone center Y: ", target_zone_y + target_zone.size.y/2)
	
	# Calculate distances from locked positions to target center
	var x_distance = abs(x_locked_position + scan_line_vertical.size.x/2 - (target_zone_x + target_zone.size.x/2))
	var y_distance = abs(y_locked_position + scan_line_horizontal.size.y/2 - (target_zone_y + target_zone.size.y/2))
	
	print("X distance from target: ", x_distance)
	print("Y distance from target: ", y_distance)
	
	# Calculate accuracy percentages (80% tolerance means 20% margin of error)
	var scan_area_width = scan_area.size.x
	var scan_area_height = scan_area.size.y
	
	# 80% accuracy = within 20% of the scan area dimensions from the target
	var x_tolerance = scan_area_width * 0.2  # 20% of width
	var y_tolerance = scan_area_height * 0.2  # 20% of height
	
	var x_accurate = x_distance <= x_tolerance
	var y_accurate = y_distance <= y_tolerance
	
	print("X tolerance: ", x_tolerance, " - X accurate: ", x_accurate)
	print("Y tolerance: ", y_tolerance, " - Y accurate: ", y_accurate)
	
	if x_accurate and y_accurate:
		# SUCCESS! Both lines are within 80% accuracy
		print("SUCCESS! Scan completed with 80%+ accuracy!")
		status_label.text = "SCAN SUCCESSFUL - TARGET ACQUIRED"
		status_label.modulate = Color(0.0, 1.0, 0.2, 1.0)  # Bright green
		
		# Flash success
		_flash_success()
		
		# Complete the scan
		await get_tree().create_timer(1.0).timeout  # Show success message for 1 second
		_complete_scan()
	else:
		# FAILURE! Not accurate enough - trigger failure system
		print("FAILURE! Accuracy below 80% threshold")
		
		var x_accuracy_percent = int((1.0 - (x_distance / x_tolerance)) * 100)
		var y_accuracy_percent = int((1.0 - (y_distance / y_tolerance)) * 100)
		
		status_label.text = "ACCURACY TOO LOW - X:" + str(max(0, x_accuracy_percent)) + "% Y:" + str(max(0, y_accuracy_percent)) + "% (NEED 80%)"
		status_label.modulate = Color(1.0, 0.3, 0.3, 1.0)  # Red
		
		emit_signal("scan_failed")
		_flash_error()
		
		# Trigger failure system for scanner failure
		var failure_manager = get_node_or_null("/root/FailureManager")
		if not failure_manager:
			failure_manager = get_tree().current_scene.get_node_or_null("FailureManager")
		if failure_manager and failure_manager.has_method("trigger_failure"):
			failure_manager.trigger_failure("Scanner accuracy below threshold")
		else:
			# Fallback behavior - reset for retry
			# Generate new random target for next attempt
			_randomize_target_zone()
			
			# Reset for another attempt after showing error
			await get_tree().create_timer(2.0).timeout  # Show error message for 2 seconds
			_reset_scan_lines()

func _flash_success() -> void:
	# PSX-style success flash
	scan_area.modulate = Color(0.0, 1.0, 0.2, 1.0)  # Bright green flash
	var tween = create_tween()
	tween.tween_property(scan_area, "modulate", Color(0.9, 0.9, 0.9, 1.0), 0.5)  # Back to light gray

func _reset_scan_lines() -> void:
	# Reset scan state for new attempt
	current_scan_phase = 0
	x_line_locked = false
	y_line_locked = false
	x_locked_position = 0.0
	y_locked_position = 0.0
	scan_line_x = 0
	scan_line_y = 0
	scan_direction_x = 1
	scan_direction_y = 1
	
	status_label.text = "SCANNING RESET - ADJUST FREQUENCY"
	status_label.modulate = Color(1.0, 0.8, 0.0, 1.0)  # Amber

func _on_frequency_changed(value: float) -> void:
	current_frequency = value

func _on_scan_pressed() -> void:
	# Scan button is now used to exit/cancel
	print("Scanner cancelled by user")
	_exit_scanner()

func _exit_scanner() -> void:
	is_scanning = false
	_stop_scanning_audio()
	
	# Emit signal to player to exit scanner mode
	if get_parent() and get_parent().get_parent() and get_parent().get_parent().has_method("_on_scanner_exit"):
		get_parent().get_parent()._on_scanner_exit()
	
	_reset_scanner()

func _complete_scan() -> void:
	print("Scan successful!")
	is_scanning = false
	_stop_scanning_audio()
	
	# Show results
	_show_scan_results()
	
	# Update progression
	scans_completed += 1
	_update_difficulty()
	
	emit_signal("scan_completed", current_scan_data)

func _show_scan_results() -> void:
	if "EYE_COLOR" in current_scan_data and "BLOOD_TYPE" in current_scan_data:
		eye_color_label.text = "EYE COLOR: " + str(current_scan_data["EYE_COLOR"])
		blood_type_label.text = "BLOOD TYPE: " + str(current_scan_data["BLOOD_TYPE"])
		
		# PSX-style results display
		eye_color_label.modulate = Color(0.0, 1.0, 0.2, 1.0)  # Bright green
		blood_type_label.modulate = Color(0.0, 1.0, 0.2, 1.0)  # Bright green
		
		results_panel.visible = true
		
		# PSX-style success flash
		results_panel.modulate = Color(0.0, 1.0, 0.2, 1.0)  # Bright green flash
		var tween = create_tween()
		tween.tween_property(results_panel, "modulate", Color(0.8, 0.8, 0.8, 1.0), 0.5)  # Fade to gray

func _flash_error() -> void:
	# PSX-style error flash
	scan_area.modulate = Color(1.0, 0.3, 0.3, 1.0)  # Red flash
	var tween = create_tween()
	tween.tween_property(scan_area, "modulate", Color(0.9, 0.9, 0.9, 1.0), 0.3)  # Back to light gray

func _on_close_results() -> void:
	results_panel.visible = false
	_reset_scanner()

func _reset_scanner() -> void:
	is_scanning = false
	current_scan_phase = 0
	x_line_locked = false
	y_line_locked = false
	x_locked_position = 0.0
	y_locked_position = 0.0
	scan_line_x = 0
	scan_line_y = 0
	scan_direction_x = 1
	scan_direction_y = 1
	frequency_slider.value = 440.0
	current_frequency = 440.0
	results_panel.visible = false
	
	# Stop audio system
	_stop_scanning_audio()
	is_audio_playing = false
	
	# PSX-style reset
	scan_button.text = "EXIT"  # Change button to exit function
	scan_button.disabled = false
	scan_button.modulate = Color(1.0, 0.3, 0.3, 1.0)  # Red for exit
	status_label.text = "SYSTEM READY - ACTIVATE SCANNER"
	status_label.modulate = Color(0.8, 0.8, 0.8, 1.0)  # Light gray

func _update_difficulty() -> void:
	# Increase difficulty based on completed scans
	if scans_completed >= 2:
		scan_level = 2
		status_label.text = "Difficulty increased: Enhanced precision required!"
		print("Scanner difficulty increased - tighter tolerances")
	
	if scans_completed >= 4:
		scan_speed = min(scan_speed + 0.2, 2.5)
		frequency_tolerance = max(frequency_tolerance - 2.0, 5.0)
		zone_tolerance = max(zone_tolerance - 3.0, 10.0)
		scan_level = 3
		print("Scanner difficulty increased - faster scanning, tighter tolerances")

func start_scan(scan_data: Dictionary) -> void:
	if scan_data.is_empty():
		print("No scan data provided!")
		return
	
	current_scan_data = scan_data
	
	# Set scanning parameters from data
	if "AUDIO_FREQUENCY" in scan_data:
		target_frequency = float(scan_data["AUDIO_FREQUENCY"])
		target_indicator.text = "TARGET: " + str(int(target_frequency)) + " Hz"
	
	if "SCAN_SPEED" in scan_data:
		scan_speed = float(scan_data["SCAN_SPEED"])
	
	# Start scanning
	is_scanning = true
	current_scan_phase = 0  # Start with frequency matching
	
	# PSX-style UI updates
	scan_button.text = "EXIT"
	scan_button.modulate = Color(1.0, 0.3, 0.3, 1.0)  # Red for cancel
	status_label.text = "ADJUST FREQUENCY TO MATCH TARGET"
	status_label.modulate = Color(1.0, 0.8, 0.0, 1.0)  # Amber
	
	# Randomize target zone for this scan
	_randomize_target_zone()
	
	# FORCE input focus and processing aggressively
	await get_tree().process_frame  # Wait one frame for everything to settle
	grab_focus()
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_unhandled_input(true)
	set_process_input(true)
	
	# Double-check that we have focus
	if not has_focus():
		print("WARNING: Scanner UI doesn't have focus, trying to grab it again")
		call_deferred("grab_focus")
	
	print("=== SCANNER STARTED ===")
	print("Target frequency: ", target_frequency, "Hz")
	print("Current frequency: ", current_frequency, "Hz")
	print("Scanner active: ", is_scanning)
	print("UI has focus: ", has_focus())
	print("Use mouse wheel to adjust frequency, Space/Enter to lock scan lines")
	print("======================")
	
	# Test input immediately
	print("Testing direct input handling...")
	_test_input_system()
	
	# Generate new random target position for this scan
	_randomize_target_zone()
	
	# Reset and start scanning
	_reset_scanner()
	is_scanning = true
	
	# Initialize audio system
	is_audio_playing = false
	scanning_audio_stream = null
	
	status_label.text = "USE MOUSE WHEEL TO ADJUST FREQUENCY"
	status_label.modulate = Color(1.0, 0.8, 0.0, 1.0)  # Amber
	print("Medical scan started - Target frequency:", target_frequency, "Hz")
	print("Hidden target zone at:", target_zone_x, ",", target_zone_y)
	print("Controls: Mouse Wheel = Frequency, Space = Lock Line, Click = Exit")

func _test_input_system() -> void:
	print("Input system test:")
	print("- is_scanning: ", is_scanning)
	print("- has_focus(): ", has_focus())
	print("- mouse_filter: ", mouse_filter)
	print("- process_mode: ", process_mode)
	print("- visible: ", visible)
	print("- modulate: ", modulate)
	
	# Try to manually adjust frequency to test the system
	print("Testing frequency adjustment...")
	_adjust_frequency(10.0)  # Should increase by 10Hz
	
func can_start_scan() -> bool:
	return not is_scanning and not results_panel.visible

# Note: Replaced old beep system with continuous audio system
# Old _play_beep(), _play_simple_beep(), and _fill_audio_buffer() functions
# have been replaced with the new proximity-based continuous audio system

func _animate_noise_background():
	if not has_node("Background/NoiseTexture"):
		return
	
	# Update animation time
	noise_time += get_process_delta_time() * 0.3  # Slow animation speed
	
	var noise_texture_rect = get_node("Background/NoiseTexture")
	var texture = noise_texture_rect.texture as ImageTexture
	
	if texture and texture.get_image():
		# Create animated offset by shifting texture coordinates
		var material = noise_texture_rect.material as ShaderMaterial
		if not material:
			# Create a simple material for texture animation
			var shader = Shader.new()
			shader.code = """
shader_type canvas_item;

uniform float time_offset : hint_range(0.0, 10.0) = 0.0;
uniform float tunnel_depth : hint_range(0.1, 2.0) = 1.0;

void fragment() {
	vec2 uv = UV;
	
	// Create tunnel effect with time-based movement
	vec2 center = vec2(0.5, 0.5);
	vec2 offset = (uv - center) * tunnel_depth;
	vec2 animated_uv = uv + offset * sin(time_offset) * 0.1;
	
	// Sample the texture with animated coordinates
	vec4 color = texture(TEXTURE, animated_uv);
	
	// Add green tint and enhance contrast
	color.rgb = color.rgb * vec3(0.3, 1.2, 0.4);
	color.a *= 0.6;
	
	COLOR = color;
}
"""
			material = ShaderMaterial.new()
			material.shader = shader
			noise_texture_rect.material = material
		
		# Update shader parameters
		if material:
			material.set_shader_parameter("time_offset", noise_time)
			material.set_shader_parameter("tunnel_depth", 1.5)
