extends Node3D
class_name InstructionBooklet

# Instruction Booklet System with layered 2D pages
# Each page is a Control layer that can be edited in the 2D editor

@export var booklet_title: String = "Operations Manual"
@export var page_flip_duration: float = 0.8
@export var camera_transition_duration: float = 0.6
@export var pages_per_spread: int = 2  # How many pages to show at once (left and right)

# Page management
var total_pages: int = 0
var current_page_index: int = 0
var is_open: bool = false
var is_flipping: bool = false

# 3D References
@onready var booklet_mesh: MeshInstance3D = $BookletMesh
@onready var left_page_mesh: MeshInstance3D = $BookletMesh/LeftPageMesh
@onready var right_page_mesh: MeshInstance3D = $BookletMesh/RightPageMesh
@onready var booklet_camera: Camera3D = $BookletCamera
@onready var page_flip_audio: AudioStreamPlayer3D = $PageFlipAudio

# 2D Page System
@onready var page_viewport: SubViewport = $PageSystem/PageViewport
@onready var page_container: Control = $PageSystem/PageViewport/PageContainer

# UI Elements
@onready var ui_canvas: CanvasLayer = $BookletUI
@onready var page_counter: Label = $BookletUI/PageCounter
@onready var close_hint: Label = $BookletUI/CloseHint
@onready var nav_hints: Label = $BookletUI/NavHints

# Materials
var left_page_material: StandardMaterial3D
var right_page_material: StandardMaterial3D
var photocopy_material: ShaderMaterial

# Player reference
var player_node: Node3D = null

# Page nodes - these will be automatically found
var page_layers: Array[Control] = []

func _ready() -> void:
	# Initialize the booklet
	setup_booklet()
	setup_materials()
	find_page_layers()
	setup_ui()
	update_page_display()
	
	# Hide UI initially
	ui_canvas.visible = false
	
	# Find player node
	call_deferred("find_player")

func find_player() -> void:
	# Try to find player node in common locations
	player_node = get_node_or_null("../Player")
	if not player_node:
		player_node = get_tree().get_first_node_in_group("player")
	if not player_node:
		# Try to find in scene tree
		var scene_root = get_tree().current_scene
		if scene_root:
			player_node = scene_root.find_child("Player", true, false)
	
	if not player_node:
		print("Warning: Player node not found for booklet interaction")

func setup_booklet() -> void:
	# Add to interactive groups for player detection
	add_to_group("manual")
	add_to_group("booklet")
	
	# Ensure collision body is in the right group
	var static_body = $StaticBody3D
	if static_body:
		static_body.add_to_group("manual")
		static_body.add_to_group("booklet")

func find_page_layers() -> void:
	# Find all page layers in the PageContainer
	page_layers.clear()
	
	if not page_container:
		print("Error: PageContainer not found!")
		return
	
	# Get all Control children that start with "Page"
	for child in page_container.get_children():
		if child is Control and child.name.begins_with("Page"):
			page_layers.append(child)
			child.visible = false  # Hide all pages initially
	
	# Sort pages by name to ensure correct order
	page_layers.sort_custom(func(a, b): return a.name < b.name)
	
	total_pages = page_layers.size()
	print("Found ", total_pages, " pages in booklet")

func setup_materials() -> void:
	# Create photocopy shader material
	photocopy_material = ShaderMaterial.new()
	
	var photocopy_shader = Shader.new()
	photocopy_shader.code = """
shader_type canvas_item;

uniform float brightness : hint_range(0.0, 3.0) = 1.6;
uniform float contrast : hint_range(0.0, 4.0) = 2.2;
uniform float noise_amount : hint_range(0.0, 0.5) = 0.15;
uniform float grain_size : hint_range(1.0, 20.0) = 8.0;

float noise(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec4 tex_color = texture(TEXTURE, uv);
	
	// Skip processing for transparent areas
	if (tex_color.a < 0.1) {
		COLOR = tex_color;
		return;
	}
	
	// Convert to grayscale for images only
	// Detect if this is likely text (high contrast areas)
	float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
	
	// Check if this pixel is likely text (very dark or very light)
	bool is_text = (gray < 0.2 || gray > 0.8);
	
	if (!is_text) {
		// Apply photocopy effect to images
		gray = (gray - 0.5) * contrast + 0.5;
		gray += (brightness - 1.0);
		
		// Add grain
		float grain = (noise(uv * grain_size * 50.0) - 0.5) * noise_amount;
		gray += grain;
		
		// High contrast threshold
		gray = step(0.4, gray);
		
		COLOR = vec4(vec3(gray), tex_color.a);
	} else {
		// Keep text as-is for readability
		COLOR = tex_color;
	}
}
"""
	
	photocopy_material.shader = photocopy_shader
	
	# Create standard materials for the 3D pages
	left_page_material = StandardMaterial3D.new()
	left_page_material.flags_unshaded = true
	left_page_material.flags_do_not_receive_shadows = true
	left_page_material.flags_disable_ambient_light = true
	
	right_page_material = StandardMaterial3D.new()
	right_page_material.flags_unshaded = true
	right_page_material.flags_do_not_receive_shadows = true
	right_page_material.flags_disable_ambient_light = true

func setup_ui() -> void:
	# Page counter styling
	if page_counter:
		page_counter.add_theme_font_size_override("font_size", 18)
		page_counter.add_theme_color_override("font_color", Color.WHITE)
	
	# Close hint styling
	if close_hint:
		close_hint.add_theme_font_size_override("font_size", 14)
		close_hint.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		close_hint.text = "Press ESC or Click to Close"
	
	# Navigation hints styling
	if nav_hints:
		nav_hints.add_theme_font_size_override("font_size", 14)
		nav_hints.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		nav_hints.text = "← → Arrow Keys to Turn Pages"

func open_booklet() -> void:
	if is_open or is_flipping:
		return
	
	is_open = true
	current_page_index = 0
	
	# Switch to booklet camera
	if player_node and player_node.has_method("exit_computer_mode"):
		player_node.exit_computer_mode()
	
	# Set camera and global flags
	if booklet_camera:
		booklet_camera.current = true
		Global.is_using_computer = true
		Global.is_using_monitor = false
	
	# Show UI
	ui_canvas.visible = true
	
	# Update page display
	update_page_display()
	
	# Set mouse mode for interaction
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	print("Booklet opened - Use arrow keys to navigate, ESC to close")

func close_booklet() -> void:
	if not is_open:
		return
	
	is_open = false
	
	# Hide all pages
	for page in page_layers:
		page.visible = false
	
	# Hide UI
	ui_canvas.visible = false
	
	# Return camera control to player
	if booklet_camera:
		booklet_camera.current = false
	
	# Return to player control
	if player_node:
		if player_node.has_method("exit_computer_mode"):
			player_node.exit_computer_mode()
		# Restore player camera
		var player_camera = player_node.get_node_or_null("Head/Camera3D")
		if player_camera:
			player_camera.current = true
	
	# Reset global flags
	Global.is_using_computer = false
	Global.is_using_monitor = false
	
	# Return mouse capture
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	print("Booklet closed")

func next_page() -> void:
	if is_flipping or current_page_index >= total_pages - pages_per_spread:
		return
	
	current_page_index += pages_per_spread
	flip_page(true)

func previous_page() -> void:
	if is_flipping or current_page_index <= 0:
		return
	
	current_page_index -= pages_per_spread
	flip_page(false)

func flip_page(forward: bool) -> void:
	if is_flipping:
		return
	
	is_flipping = true
	
	# Play page flip sound
	if page_flip_audio and page_flip_audio.stream:
		page_flip_audio.play()
	
	# Create page flip animation
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Animate both page meshes for flip effect
	var pages_to_flip = [left_page_mesh, right_page_mesh]
	
	for page_mesh in pages_to_flip:
		if not page_mesh:
			continue
			
		var start_rotation = page_mesh.rotation_degrees
		var mid_rotation = Vector3(start_rotation.x, start_rotation.y + (180 if forward else -180), start_rotation.z)
		
		# First half of flip - rotate up
		tween.tween_method(
			func(rot): page_mesh.rotation_degrees = rot,
			start_rotation,
			mid_rotation,
			page_flip_duration * 0.5
		)
		
		# Second half of flip - rotate down with new content
		tween.tween_method(
			func(rot): page_mesh.rotation_degrees = rot,
			mid_rotation,
			start_rotation,
			page_flip_duration * 0.5
		).tween_delay(page_flip_duration * 0.5)
	
	# Update content at midpoint
	tween.tween_callback(update_page_display).tween_delay(page_flip_duration * 0.5)
	
	# End flipping state
	tween.tween_callback(func(): is_flipping = false).tween_delay(page_flip_duration)

func update_page_display() -> void:
	if total_pages == 0:
		return
	
	# Clamp current page index
	current_page_index = clamp(current_page_index, 0, max(0, total_pages - pages_per_spread))
	
	# Hide all pages first
	for page in page_layers:
		page.visible = false
	
	# Show current page(s)
	var pages_to_show = []
	
	# Left page (even pages or single page mode)
	if current_page_index < total_pages:
		page_layers[current_page_index].visible = true
		pages_to_show.append(current_page_index)
	
	# Right page (odd pages in spread mode)
	if pages_per_spread > 1 and current_page_index + 1 < total_pages:
		page_layers[current_page_index + 1].visible = true
		pages_to_show.append(current_page_index + 1)
	
	# Update page counter
	if page_counter:
		var display_page = current_page_index + 1
		var end_page = min(current_page_index + pages_per_spread, total_pages)
		if pages_per_spread > 1 and end_page > display_page:
			page_counter.text = "Pages %d-%d / %d" % [display_page, end_page, total_pages]
		else:
			page_counter.text = "Page %d / %d" % [display_page, total_pages]
	
	# Update viewport textures
	call_deferred("update_viewport_textures")
	
	print("Displaying page(s): ", pages_to_show)

func update_viewport_textures() -> void:
	# Force viewport update
	if page_viewport:
		page_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		
		# Wait a frame for rendering
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Get the viewport texture
		var viewport_texture = page_viewport.get_texture()
		
		if viewport_texture:
			# Apply to left page
			if left_page_mesh and left_page_material:
				left_page_material.albedo_texture = viewport_texture
				left_page_mesh.material_override = left_page_material
			
			# Apply to right page (same texture for now, could be split)
			if right_page_mesh and right_page_material:
				right_page_material.albedo_texture = viewport_texture
				right_page_mesh.material_override = right_page_material

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

# Function to be called by player interaction system
func interact() -> void:
	if not is_open:
		open_booklet()
	else:
		close_booklet()

# Utility functions for external access
func is_booklet_open() -> bool:
	return is_open

func get_current_page_index() -> int:
	return current_page_index

func get_total_pages() -> int:
	return total_pages

func jump_to_page(page_index: int) -> void:
	if page_index < 0 or page_index >= total_pages:
		return
	
	current_page_index = page_index
	if is_open:
		update_page_display()

# Function to refresh pages if they're added/removed at runtime
func refresh_pages() -> void:
	find_page_layers()
	if is_open:
		update_page_display()

# Apply photocopy shader to specific page elements
func apply_photocopy_effect_to_page(page_index: int, element_name: String = "") -> void:
	if page_index < 0 or page_index >= page_layers.size():
		return
	
	var page = page_layers[page_index]
	var target_node = page
	
	if element_name != "":
		target_node = page.find_child(element_name, true, false)
	
	if target_node and target_node.has_method("set_material"):
		target_node.material = photocopy_material
