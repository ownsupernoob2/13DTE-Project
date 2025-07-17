extends Node3D

@onready var rich_text_label = $Monitor/SubViewport/Control/RichTextLabel
@onready var start_button = $StartButton

var total_seconds: int = 300 # 5 minutes default
var timer: float = 0.0
var game_ended: bool = false
var is_running: bool = false # Tracks if timer is running

# Signal for game end
signal game_over

func _ready() -> void:
	if rich_text_label == null:
		push_error("RichTextLabel not found at 'Monitor/SubViewport/Control/RichTextLabel'. Check scene structure.")
		_debug_print_node_tree()
		return
	if start_button == null:
		push_error("StartButton not found at 'StartButton'. Ensure Area3D node exists.")
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
		_update_display()

	# Connect button signals
	_setup_button_connections()

func _setup_button_connections() -> void:
	if start_button and start_button.has_signal("input_event"):
		if not start_button.is_connected("input_event", _on_start_button_input):
			start_button.connect("input_event", _on_start_button_input)

func _on_start_button_input(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_running and not game_ended and total_seconds > 0:
			is_running = true
			var monitor_node = get_node_or_null("Monitor")
			if monitor_node and monitor_node.has_method("show_alien_info"):
				monitor_node.show_alien_info()

func _process(delta: float) -> void:
	if rich_text_label == null or game_ended or not is_running:
		return

	if total_seconds > 0:
		timer += delta
		if timer >= 1.0:
			timer -= 1.0
			total_seconds -= 1
			_update_display()
			
			if total_seconds <= 0:
				_trigger_game_end()

func _trigger_game_end() -> void:
	if game_ended:
		return
		
	game_ended = true
	is_running = false
	_update_display()
	
	emit_signal("game_over")
	
	if rich_text_label:
		await get_tree().create_timer(1.0).timeout
		var font_size = 200
		var sub_viewport = rich_text_label.get_node_or_null("../../../")
		if sub_viewport and sub_viewport is SubViewport:
			var viewport_size = sub_viewport.size.y
			font_size = max(32, int(viewport_size * 0.4))
		
		rich_text_label.text = "[center][font_size=%d]TIME'S UP[/font_size][/center]" % font_size
		rich_text_label.modulate = Color.RED
		
		await get_tree().create_timer(3.0).timeout
		_reset_timer()

func _update_display() -> void:
	if rich_text_label == null:
		return
		
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	var font_size = 400
	var sub_viewport = rich_text_label.get_node_or_null("../../../")
	if sub_viewport and sub_viewport is SubViewport:
		var viewport_size = sub_viewport.size.y
		font_size = max(48, int(viewport_size * 0.9))
	
	rich_text_label.text = "[center][font_size=%d]%02d:%02d[/font_size][/center]" % [font_size, minutes, seconds]
	
	# Color transition from white to red as timer approaches 0
	var redness = 1.0 - clamp(float(total_seconds) / 30.0, 0.0, 1.0) # Full red in last 30 seconds
	var color = Color(1.0, 1.0 - redness, 1.0 - redness, 1.0)
	rich_text_label.modulate = color

func _reset_timer() -> void:
	game_ended = false
	is_running = false
	total_seconds = 300 # Reset to 5 minutes
	timer = 0.0
	_update_display()

func _debug_print_node_tree() -> void:
	_print_node_children(self, "")

func _print_node_children(node: Node, indent: String) -> void:
	for child in node.get_children():
		_print_node_children(child, indent + "  ")
