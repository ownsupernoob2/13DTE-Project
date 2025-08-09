extends Node3D

# Medical Scanner Machine - Analyzes alien biological data through audio-visual scanning

@onready var scanner_camera: Camera3D = $ScannerCamera
@onready var scanner_viewport: SubViewport = $Scanner/SubViewport
@onready var scanner_ui: Control = $Scanner/SubViewport/ScannerUI

# Scanner state
var is_active: bool = false
var current_scan_data: Dictionary = {}

func _ready() -> void:
	# Setup viewport
	if scanner_viewport:
		scanner_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
		scanner_viewport.size = Vector2i(600, 450)
	
	if scanner_ui:
		# Connect to UI signals
		scanner_ui.scan_completed.connect(_on_scan_completed)
		scanner_ui.scan_failed.connect(_on_scan_failed)
		print("Medical scanner initialized successfully")
	else:
		print("ERROR: Scanner UI not found!")
	
	# Enable input processing for this node
	set_process_unhandled_input(true)
	set_process_input(true)

# Handle input when scanner is active
func _input(event: InputEvent) -> void:
	if not is_active or not scanner_ui:
		return
	
	print("Medical Scanner received input: ", event)
	
	# Forward input events directly to the scanner UI
	var handled = false
	
	# Space/Enter key for locking scan lines
	if event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		print("Medical Scanner forwarding Space/Enter to UI")
		scanner_ui._handle_space_input()
		handled = true
	
	# Mouse wheel for frequency adjustment
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			print("Medical Scanner forwarding mouse wheel UP to UI")
			scanner_ui._handle_wheel_input(1)
			handled = true
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			print("Medical Scanner forwarding mouse wheel DOWN to UI")
			scanner_ui._handle_wheel_input(-1)
			handled = true
	
	if handled:
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active or not scanner_ui:
		return
	
	print("Medical Scanner unhandled input: ", event)
	
	# Backup input handling
	if event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		print("Medical Scanner backup Space/Enter handling")
		scanner_ui._handle_space_input()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			print("Medical Scanner backup mouse wheel UP handling")
			scanner_ui._handle_wheel_input(1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			print("Medical Scanner backup mouse wheel DOWN handling")
			scanner_ui._handle_wheel_input(-1)
			get_viewport().set_input_as_handled()

func start_scan(scan_data: Dictionary) -> void:
	if scan_data.is_empty():
		print("No scan data provided for scanning!")
		return
	
	if not scanner_ui:
		print("Scanner UI not available!")
		return
	
	if not scanner_ui.can_start_scan():
		print("Scanner is currently busy!")
		return
	
	current_scan_data = scan_data
	is_active = true
	
	print("Medical scan initiated with data:", scan_data)
	
	# Start the scanning process in the UI
	scanner_ui.start_scan(scan_data)

func _on_scan_completed(results: Dictionary) -> void:
	print("Scan completed successfully!")
	print("Results - Eye Color:", results.get("EYE_COLOR", "Unknown"), 
		  " Blood Type:", results.get("BLOOD_TYPE", "Unknown"))
	
	# The scanner stays active until the player closes the results
	# This allows them to review the data

func _on_scan_failed() -> void:
	print("Scan failed - try adjusting frequency and timing")

func can_use_scanner() -> bool:
	return not is_active or (scanner_ui and scanner_ui.can_start_scan())

func get_scan_results() -> Dictionary:
	if scanner_ui and scanner_ui.results_panel and scanner_ui.results_panel.visible:
		return current_scan_data
	return {}

func stop_scan() -> void:
	is_active = false
	if scanner_ui:
		scanner_ui._reset_scanner()

func _on_scanner_exit() -> void:
	# Handle scanner exit - signal to player to return to normal mode
	is_active = false
	print("Scanner exited by user")
	
	# Signal to the scene that scanner is being exited
	# This will be picked up by the player script
