extends Node3D

@onready var rich_text_label = $Monitor/SubViewport/Control/RichTextLabel
@onready var up_button = $UpButton
@onready var down_button = $DownButton

var current_number: int = 0
var direction: int = 0 # 0: stopped, 1: up, -1: down
var timer: float = 0.0
const INITIAL_INTERVAL: float = 0.1 # Fast start
const MAX_INTERVAL: float = 1.0 # Slow at 100
var is_active: bool = false

func _ready() -> void:
	# Validate nodes
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

	# Configure RichTextLabel to fill the SubViewport and center text
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
		# Dynamically scale font size based on SubViewport size
		var sub_viewport = rich_text_label.get_node_or_null("../../../") # Monitor/SubViewport
		if sub_viewport and sub_viewport is SubViewport:
			var viewport_size = sub_viewport.size.y
			var font_size = max(48, int(viewport_size * 0.9)) # 90% of viewport height
			rich_text_label.text = "[center][valign center][font_size=%d]%d[/font_size][/valign][/center]" % [font_size, current_number]

	# Connect Area3D input event signals for raycast interaction
	up_button.input_event.connect(_on_up_button_input_event)
	down_button.input_event.connect(_on_down_button_input_event)
	# Start with random direction
	direction = [-1, 1][randi() % 2]
	is_active = true
	_update_display()

func _process(delta: float) -> void:
	if is_active and rich_text_label != null:
		timer += delta
		# Dynamic update interval based on current_number
		var update_interval = INITIAL_INTERVAL + (MAX_INTERVAL - INITIAL_INTERVAL) * (abs(current_number) / 100.0)
		if timer >= update_interval:
			timer -= update_interval
			current_number += direction
			# Check for |current_number| >= 100
			if abs(current_number) >= 100:
				is_active = false
				current_number = clamp(current_number, -100, 100) # Cap at ±100
				_update_display()
			else:
				_update_display()

func _update_display() -> void:
	if rich_text_label == null:
		return
	# Update text, preserving dynamic font size and centering
	var font_size = 400# Default
	var sub_viewport = rich_text_label.get_node_or_null("../../../") # Monitor/SubViewport
	if sub_viewport and sub_viewport is SubViewport:
		var viewport_size = sub_viewport.size.y
		font_size = max(48, int(viewport_size * 0.9)) # 90% of viewport height
	if abs(current_number) >= 100:
		rich_text_label.text = "[center][font_size=%d]goodbye[/font_size][/center]" % 200
	else:
		rich_text_label.text = "[center][font_size=%d]%d[/font_size][/center]" % [font_size, current_number]
	# Calculate color based on absolute value
	var redness = min(abs(current_number) / 100.0, 1.0)
	var color = Color(1.0, 1.0 - redness, 1.0 - redness, 1.0)
	rich_text_label.modulate = color

func _on_up_button_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if direction == 1 and not (Global.is_using_computer or Global.is_using_monitor):
			is_active = false
			current_number = 0
			direction = [-1, 1][randi() % 2] # New random direction
			is_active = true
			_update_display()

func _on_down_button_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if direction == -1 and not (Global.is_using_computer or Global.is_using_monitor):
			is_active = false
			current_number = 0
			direction = [-1, 1][randi() % 2] # New random direction
			is_active = true
			_update_display()

func _debug_print_node_tree() -> void:
	print("Debug: Node tree for ", get_path())
	_print_node_children(self, "")

func _print_node_children(node: Node, indent: String) -> void:
	print(indent, node.name, " (", node.get_class(), ")")
	for child in node.get_children():
		_print_node_children(child, indent + "  ")
