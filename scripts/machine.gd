extends Node3D

@onready var rich_text_label = $Monitor/SubViewport/Control/RichTextLabel
@onready var up_button = $UpButton
@onready var down_button = $DownButton

var current_number: int = 0
var direction: int = 0 # 0: stopped, 1: up, -1: down
var timer: float = 0.0
const UPDATE_INTERVAL: float = 0.5
var is_active: bool = false

func _ready() -> void:
	# Validate nodes
	if rich_text_label == null:
		_debug_print_node_tree()
		return
	if up_button == null:
		push_error("UpButton not found at 'UpButton'. Ensure Area3D node exists.")
		return
	if down_button == null:
		push_error("DownButton not found at 'DownButton'. Ensure Area3D node exists.")
		return

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
		if timer >= UPDATE_INTERVAL:
			timer -= UPDATE_INTERVAL
			current_number += direction
			_update_display()

func _update_display() -> void:
	if rich_text_label == null:
		return
	# Update text
	rich_text_label.text = "[center][font_size=48]%d[/font_size][/center]" % current_number
	# Calculate color based on absolute value
	var redness = min(abs(current_number) / 100.0, 1.0)
	var color = Color(1.0, 1.0 - redness, 1.0 - redness, 1.0)
	rich_text_label.modulate = color

func _on_up_button_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if direction == 1 and is_active and not (Global.is_using_computer or Global.is_using_monitor):
			is_active = false
			current_number = 0
			direction = [-1, 1][randi() % 2] # New random direction
			is_active = true
			_update_display()

func _on_down_button_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if direction == -1 and is_active and not (Global.is_using_computer or Global.is_using_monitor):
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
