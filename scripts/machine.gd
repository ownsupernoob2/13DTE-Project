extends Node3D

@onready var rich_text_label = $Monitor/SubViewport/Control/RichTextLabel
@onready var up_button = $UpButton
@onready var down_button = $DownButton

var current_number: int = 5
var up_button_held: bool = true
var down_button_held: bool = false
var timer: float = 0.0
var game_ended: bool = false

# Signal for game end
signal game_over(final_count: int)

# Speed level system
var speed_level: int = 1
var base_update_interval: float = 0.5
var current_update_interval: float = 0.5

func _ready() -> void:
	if rich_text_label == null:
		push_error("RichTextLabel not found at 'Monitor/SubViewport/Control/RichTextLabel'. Check scene structure.")
		_debug_print_node_tree()
		return
	if up_button == null:
		push_error("UpButton not found at 'UpButton'. Ensure Area3D node exists.")
		return
	if down_button == null:
		push_error("DownButton not found at 'DownButton'. Ensure Area3D node exists.")
		return

	# Configure RichTextLabel
	if rich_text_label:
		rich_text_label.anchor_left = 0.0
		rich_text_label.anchor_top = 0.0
		rich_text_label.anchor_right = 1.0
		rich_text_label.anchor_bottom = 1.0
		rich_text_label.offset_left = 0
		rich_text_label.offset_top = 0
		rich_text_label.offset_right = 0
		rich_text_label.offset_bottom = 0
		rich_text_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
		rich_text_label.grow_vertical = Control.GROW_DIRECTION_BOTH
		rich_text_label.fit_content = false
		rich_text_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		rich_text_label.clip_contents = false
		var sub_viewport = rich_text_label.get_node_or_null("../../../")
		if sub_viewport and sub_viewport is SubViewport:
			var viewport_size = sub_viewport.size.y
			var font_size = max(48, int(viewport_size * 0.9))
			rich_text_label.text = "[center][valign center][font_size=%d]%d[/font_size][/valign][/center]" % [font_size, current_number]

	# Connect button signals if they exist
	_setup_button_connections()

	# Start with random direction
	_update_display()

func _setup_button_connections() -> void:
	# Try to connect to button signals if buttons are Area3D nodes
	if up_button and up_button.has_signal("input_event"):
		if not up_button.is_connected("input_event", _on_up_button_input):
			up_button.connect("input_event", _on_up_button_input)
	
	if down_button and down_button.has_signal("input_event"):
		if not down_button.is_connected("input_event", _on_down_button_input):
			down_button.connect("input_event", _on_down_button_input)

func _on_up_button_input(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		up_button_held = event.pressed

func _on_down_button_input(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		down_button_held = event.pressed

func _process(delta: float) -> void:
	if rich_text_label == null or game_ended:
		return

	timer += delta
	if timer >= current_update_interval:
		timer -= current_update_interval

		var changed = false
		if up_button_held:
			current_number += 1
			changed = true
		elif down_button_held:
			current_number -= 1
			changed = true
		
		if changed:
			current_number = clamp(current_number, -100, 100)
			
			# Check for game end condition
			if abs(current_number) >= 100:
				_trigger_game_end()
				return
			
			_update_display()

func _trigger_game_end() -> void:
	if game_ended:
		return
		
	game_ended = true
	
	# Clamp the number to exactly 100 or -100
	current_number = 100 if current_number > 0 else -100
	_update_display()
	
	print("GAME OVER - Machine counter reached: ", current_number)
	emit_signal("game_over", current_number)
	
	# Display game over message
	if rich_text_label:
		await get_tree().create_timer(1.0).timeout # Brief pause
		var font_size = 200
		var sub_viewport = rich_text_label.get_node_or_null("../../../")
		if sub_viewport and sub_viewport is SubViewport:
			var viewport_size = sub_viewport.size.y
			font_size = max(32, int(viewport_size * 0.4))
		
		rich_text_label.text = "[center][font_size=%d]GAME OVER[/font_size]\n[font_size=%d]Final Count: %d[/font_size][/center]" % [font_size, font_size/2, current_number]
		rich_text_label.modulate = Color.RED
		
		# Optional: Restart the scene or show end screen after delay
		await get_tree().create_timer(3.0).timeout
		_show_end_screen()

func _update_display() -> void:
	if rich_text_label == null:
		return
	var font_size = 400
	var sub_viewport = rich_text_label.get_node_or_null("../../../")
	if sub_viewport and sub_viewport is SubViewport:
		var viewport_size = sub_viewport.size.y
		font_size = max(48, int(viewport_size * 0.9))
	rich_text_label.text = "[center][font_size=%d]%d[/font_size][/center]" % [font_size, current_number]
	var redness = min(abs(current_number) / 100.0, 1.0)
	var color = Color(1.0, 1.0 - redness, 1.0 - redness, 1.0)
	rich_text_label.modulate = color

func reset_counter() -> void:
	if game_ended:
		return
		
	current_number = 0
	_update_display()

func _show_end_screen() -> void:
	# You can customize this to show a proper end screen
	# For now, just restart the scene or show options
	print("Showing end screen...")
	
	# Option 1: Restart the current scene
	# get_tree().reload_current_scene()
	
	# Option 2: Load a different end screen scene
	# get_tree().change_scene_to_file("res://scenes/end_screen.tscn")
	
	# Option 3: Just reset the machine
	_reset_machine()

func _reset_machine() -> void:
	game_ended = false
	current_number = 0
	up_button_held = false
	down_button_held = false
	speed_level = 1
	current_update_interval = base_update_interval
	_update_display()
	print("Machine reset - game continues")

func set_speed_level(new_level: int) -> void:
	"""Set the machine speed level (1-10, higher = faster)"""
	speed_level = clamp(new_level, 1, 10)
	# Faster speeds mean shorter intervals
	current_update_interval = base_update_interval / speed_level
	print("Machine speed set to level ", speed_level, " (interval: ", current_update_interval, "s)")

func get_speed_level() -> int:
	return speed_level

func _debug_print_node_tree() -> void:
	print("Debug: Node tree for ", get_path())
	_print_node_children(self, "")

func _print_node_children(node: Node, indent: String) -> void:
	print(indent, node.name, " (", node.get_class(), ")")
	for child in node.get_children():
		_print_node_children(child, indent + "  ")
