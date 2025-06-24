extends Node3D

@onready var rich_text_label = $Monitor/SubViewport/Control/RichTextLabel
@onready var up_button = $UpButton
@onready var down_button = $DownButton

var current_number: int = 0
var direction: int = 0 # 0: stopped, 1: up, -1: down
var timer: float = 0.0
var restart_timer: float = 0.0
const UPDATE_INTERVAL: float = 0.5 # Update every 0.5 seconds
const RESTART_INTERVAL: float = 2.0 # Check for restart every 2 seconds
var is_active: bool = false

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

	# Start with random direction
	direction = [-1, 1][randi() % 2]
	is_active = true
	_update_display()

func _process(delta: float) -> void:
	if rich_text_label == null:
		return

	if is_active:
		timer += delta
		if timer >= UPDATE_INTERVAL:
			timer -= UPDATE_INTERVAL
			current_number += direction
			if current_number == 0:
				is_active = false
				restart_timer = 0.0
			_update_display()
	else:
		restart_timer += delta
		if restart_timer >= RESTART_INTERVAL:
			restart_timer = 0.0
			if randf() < 0.7: # 70% chance to restart
				direction = [-1, 1][randi() % 2]
				is_active = true
				_update_display()

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

func handle_button_press(button_name: String) -> void:
	if Global.is_using_computer or Global.is_using_monitor:
		return
	if button_name == "UpButton" and direction == 1:
		reset_counter()
	elif button_name == "DownButton" and direction == -1:
		reset_counter()

func reset_counter() -> void:
	is_active = false
	current_number = 0
	direction = [-1, 1][randi() % 2]
	is_active = true
	_update_display()

func _debug_print_node_tree() -> void:
	print("Debug: Node tree for ", get_path())
	_print_node_children(self, "")

func _print_node_children(node: Node, indent: String) -> void:
	print(indent, node.name, " (", node.get_class(), ")")
	for child in node.get_children():
		_print_node_children(child, indent + "  ")
