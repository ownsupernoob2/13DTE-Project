extends Node3D
class_name InstructionBooklet

# Minimal, well-formed instruction booklet controller.
# Exposes interact() for the player, safely finds pages in a
# SubViewport->PageContainer named "PageSystem/PageViewport/PageContainer",
# and provides simple keyboard/mouse navigation.

@export var booklet_title: String = "Operations Manual"
@export var pages_per_spread: int = 2
var total_pages: int = 0
var current_page_index: int = 0
var is_open: bool = false

@onready var page_container: Control = get_node_or_null("PageSystem/PageViewport/PageContainer")
@onready var ui_canvas: CanvasLayer = get_node_or_null("BookletUI")
@onready var page_counter: Label = null

var page_layers: Array = []
var player_node: Node = null

func _ready() -> void:
	add_to_group("manual")
	add_to_group("booklet")  # Add this group for consistency with player.gd
	find_page_layers()
	if ui_canvas:
		ui_canvas.visible = false
		page_counter = ui_canvas.get_node_or_null("PageCounter") as Label
	# Defer player lookup until scene is stable
	call_deferred("_find_player")

func _find_player() -> void:
	var nodes = get_tree().get_nodes_in_group("player")
	if nodes.size() > 0:
		player_node = nodes[0]

func find_page_layers() -> void:
	page_layers.clear()
	if not page_container:
		total_pages = 0
		return
	
	for child in page_container.get_children():
		if child is Control and child.name.begins_with("Page"):
			page_layers.append(child)
	
	# Use a Callable for sort_custom to match Godot 4 API
	page_layers.sort_custom(_sort_pages_by_name)
	total_pages = page_layers.size()

func _sort_pages_by_name(a, b) -> bool:
	return str(a.name) < str(b.name)

func interact() -> void:
	if is_open:
		close_booklet()
	else:
		open_booklet()

func open_booklet() -> void:
	if is_open:
		return
		
	is_open = true
	current_page_index = 0
	
	if ui_canvas:
		ui_canvas.visible = true
	
	# Best-effort notify global usage flag if present
	if Engine.has_singleton("Global"):
		var g = Engine.get_singleton("Global")
		if g and g.has_method("reload_settings"):
			# no-op; just ensure we don't crash if Global is missing
			pass
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	update_page_display()

func close_booklet() -> void:
	if not is_open:
		return
		
	is_open = false
	
	if ui_canvas:
		ui_canvas.visible = false
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func update_page_display() -> void:
	if total_pages == 0:
		return
	
	current_page_index = clamp(current_page_index, 0, max(0, total_pages - pages_per_spread))
	
	for i in range(page_layers.size()):
		page_layers[i].visible = (i >= current_page_index and i < current_page_index + pages_per_spread)
	
	if page_counter:
		page_counter.text = "%d / %d" % [current_page_index + 1, total_pages]

func next_page() -> void:
	if current_page_index + pages_per_spread < total_pages:
		current_page_index += pages_per_spread
		update_page_display()

func previous_page() -> void:
	if current_page_index - pages_per_spread >= 0:
		current_page_index -= pages_per_spread
		update_page_display()

func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				close_booklet()
				get_viewport().set_input_as_handled()
			KEY_RIGHT, KEY_D:
				next_page()
				get_viewport().set_input_as_handled()
			KEY_LEFT, KEY_A:
				previous_page()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			close_booklet()
			get_viewport().set_input_as_handled()

func get_current_page_index() -> int:
	return current_page_index

func get_total_pages() -> int:
	return total_pages

func refresh_pages() -> void:
	find_page_layers()
	if is_open:
		update_page_display()

# Add this method to check if booklet is open (used by player.gd)
func is_booklet_open() -> bool:
	return is_open
