extends Node3D

# Used for checking if the mouse is inside the Area3D.
var is_mouse_inside = false
# The last processed input touch/mouse event. To calculate relative movement.
var last_event_pos2D = null
# The time of the last event in seconds since engine start.
var last_event_time: float = -1.0

# Disk management system
var inserted_disks: Dictionary = {}  # disk_name -> disk_data
var disk_slots: Array = ["slot1", "slot2", "slot3", "slot4"]  # Available slots
var current_disk_display: String = ""  # Currently displayed disk
var disk_interface_active: bool = false

@onready var node_viewport = $SubViewport
@onready var node_quad = $Quad
@onready var node_area = $Screen/Area3D

signal disk_inserted(disk_name: String, disk_data: Dictionary)
signal disk_ejected(disk_name: String)
signal disk_content_requested(disk_name: String)

func _ready():
	node_area.mouse_entered.connect(_mouse_entered_area)
	node_area.mouse_exited.connect(_mouse_exited_area)
	node_area.input_event.connect(_mouse_input_event)
	# Call audio setup after a brief delay to ensure console is ready
	call_deferred("setup_console_audio")

func setup_console_audio():
	# Set up the audio players for the console
	var terminal = node_viewport.get_node_or_null("Control/Console")
	if terminal:
		# Get the audio players from the root node
		var audio_press = get_parent().get_node_or_null("Press")
		var audio_enter = get_parent().get_node_or_null("Enter")
		var audio_space = get_parent().get_node_or_null("Space")
		
		# Set the audio players in the console
		if audio_press:
			terminal.audio_press = audio_press
		if audio_enter:
			terminal.audio_enter = audio_enter
		if audio_space:
			terminal.audio_space = audio_space
		
		print("Console audio setup complete")
		# Test the audio setup
		if terminal.has_method("test_audio_setup"):
			terminal.test_audio_setup()


func _mouse_entered_area():
	is_mouse_inside = true


func _mouse_exited_area():
	is_mouse_inside = false


func _unhandled_input(event):
	# Check if the event is a non-mouse/non-touch event
	for mouse_event in [InputEventMouseButton, InputEventMouseMotion, InputEventScreenDrag, InputEventScreenTouch]:
		if is_instance_of(event, mouse_event):
			# If the event is a mouse/touch event, then we can ignore it here, because it will be
			# handled via Physics Picking.
			return
	node_viewport.push_input(event)


func _mouse_input_event(_camera: Camera3D, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int):
	# Get mesh size to detect edges and make conversions. This code only support PlaneMesh and QuadMesh.
	var quad_mesh_size = node_quad.mesh.size

	# Event position in Area3D in world coordinate space.
	var event_pos3D = event_position

	# Current time in seconds since engine start.
	var now: float = Time.get_ticks_msec() / 1000.0

	# Convert position to a coordinate space relative to the Area3D node.
	# NOTE: affine_inverse accounts for the Area3D node's scale, rotation, and position in the scene!
	event_pos3D = node_quad.global_transform.affine_inverse() * event_pos3D

	# TODO: Adapt to bilboard mode or avoid completely.

	var event_pos2D: Vector2 = Vector2()

	if is_mouse_inside:
		# Convert the relative event position from 3D to 2D.
		event_pos2D = Vector2(event_pos3D.x, -event_pos3D.y)

		# Right now the event position's range is the following: (-quad_size/2) -> (quad_size/2)
		# We need to convert it into the following range: -0.5 -> 0.5
		event_pos2D.x = event_pos2D.x / quad_mesh_size.x
		event_pos2D.y = event_pos2D.y / quad_mesh_size.y
		# Then we need to convert it into the following range: 0 -> 1
		event_pos2D.x += 0.5
		event_pos2D.y += 0.5

		# Finally, we convert the position to the following range: 0 -> viewport.size
		event_pos2D.x *= node_viewport.size.x
		event_pos2D.y *= node_viewport.size.y
		# We need to do these conversions so the event's position is in the viewport's coordinate system.

	elif last_event_pos2D != null:
		# Fall back to the last known event position.
		event_pos2D = last_event_pos2D

	# Set the event's position and global position.
	event.position = event_pos2D
	if event is InputEventMouse:
		event.global_position = event_pos2D

	# Calculate the relative event distance.
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		# If there is not a stored previous position, then we'll assume there is no relative motion.
		if last_event_pos2D == null:
			event.relative = Vector2(0, 0)
		# If there is a stored previous position, then we'll calculate the relative position by subtracting
		# the previous position from the new position. This will give us the distance the event traveled from prev_pos.
		else:
			event.relative = event_pos2D - last_event_pos2D
			event.velocity = event.relative / (now - last_event_time)

	# Update last_event_pos2D with the position we just calculated.
	last_event_pos2D = event_pos2D

	# Update last_event_time to current time.
	last_event_time = now

	# Finally, send the processed input event to the viewport.
	node_viewport.push_input(event)

# Helper function to repeat strings (GDScript doesn't support string * int)
func repeat_string(text: String, count: int) -> String:
	var result = ""
	for i in range(count):
		result += text
	return result

# Disk Management Functions
func insert_disk(disk_name: String, disk_node: Node, disk_data: Dictionary) -> bool:
	# Check if we have available slots
	if inserted_disks.size() >= 4:
		print("All disk slots occupied!")
		show_disk_error("ERROR: ALL DISK SLOTS OCCUPIED")
		return false
	
	# Check if disk is already inserted
	if disk_name in inserted_disks:
		print("Disk already inserted!")
		show_disk_error("ERROR: DISK ALREADY INSERTED")
		return false
	
	# Insert the disk
	inserted_disks[disk_name] = {
		"node": disk_node,
		"data": disk_data,
		"slot": get_available_slot()
	}
	
	print("Disk ", disk_name, " inserted successfully into ", inserted_disks[disk_name]["slot"])
	emit_signal("disk_inserted", disk_name, disk_data)
	update_disk_interface()
	
	# Show insertion success and disk content
	show_disk_content(disk_name)
	return true

func eject_disk(disk_name: String) -> bool:
	if not disk_name in inserted_disks:
		print("Disk not found!")
		show_disk_error("ERROR: DISK NOT FOUND")
		return false
	
	var disk_info = inserted_disks[disk_name]
	var disk_node = disk_info["node"]
	
	# Return disk to player
	var player = get_node_or_null("../Player")
	if player and player.has_method("return_disk_to_hand"):
		player.return_disk_to_hand(disk_name, disk_node)
	
	# Remove from inserted disks
	inserted_disks.erase(disk_name)
	emit_signal("disk_ejected", disk_name)
	
	print("Disk ", disk_name, " ejected successfully")
	update_disk_interface()
	return true

func get_available_slot() -> String:
	var used_slots = []
	for disk in inserted_disks.values():
		used_slots.append(disk["slot"])
	
	for slot in disk_slots:
		if not slot in used_slots:
			return slot
	
	return "no_slot"

func show_disk_content(disk_name: String) -> void:
	if not disk_name in inserted_disks:
		return
	
	var disk_data = inserted_disks[disk_name]["data"]
	current_disk_display = disk_name
	
	# Create horror-themed interface
	var content = create_disk_interface(disk_data)
	display_content_to_viewport(content)

func create_disk_interface(disk_data: Dictionary) -> String:
	var content = ""
	content += "[color=green]" + repeat_string("=", 50) + "[/color]\n"
	content += "[color=green]SYSTEM DISK INTERFACE v2.1[/color]\n" 
	content += "[color=green]" + repeat_string("=", 50) + "[/color]\n\n"
	
	content += "[color=yellow]DISK NAME:[/color] " + disk_data["name"] + "\n"
	content += "[color=yellow]DESCRIPTION:[/color] " + disk_data["content"] + "\n\n"
	
	content += "[color=cyan]FILES DETECTED:[/color]\n"
	for file in disk_data["files"]:
		content += "  > " + file + "\n"
	
	content += "\n[color=red]" + repeat_string("-", 50) + "[/color]\n"
	content += "[color=red]WARNING: ANOMALOUS DATA DETECTED[/color]\n"
	content += "[color=red]" + disk_data["horror_message"] + "[/color]\n"
	content += "[color=red]" + repeat_string("-", 50) + "[/color]\n\n"
	
	# Show all inserted disks
	content += "[color=white]INSERTED DISKS (" + str(inserted_disks.size()) + "/4):[/color]\n"
	for disk_name in inserted_disks.keys():
		var slot = inserted_disks[disk_name]["slot"]
		content += "  [" + slot + "] " + disk_name + "\n"
	
	content += "\n[color=gray]Commands: [eject disk_name] to remove disk[/color]"
	
	return content

func show_disk_error(error_message: String) -> void:
	var content = "[color=red]" + error_message + "[/color]\n"
	content += "[color=red]SYSTEM ERROR - CONTACT ADMINISTRATOR[/color]"
	display_content_to_viewport(content)

func display_content_to_viewport(content: String) -> void:
	# Find the terminal/console in the viewport
	var terminal = node_viewport.get_node_or_null("Control/Console")
	if terminal and terminal.has_method("display_text"):
		terminal.display_text(content)
	else:
		# Fallback - try to find RichTextLabel directly
		var rich_text = node_viewport.get_node_or_null("Control/RichTextLabel")
		if rich_text and rich_text is RichTextLabel:
			rich_text.text = content

func update_disk_interface() -> void:
	disk_interface_active = true
	if inserted_disks.size() == 0:
		var content = "[color=yellow]NO DISKS INSERTED[/color]\n"
		content += "[color=gray]Insert a disk to access data[/color]"
		display_content_to_viewport(content)
	else:
		# Show summary of all disks
		var content = "[color=green]DISK MANAGEMENT SYSTEM[/color]\n\n"
		content += "[color=white]INSERTED DISKS (" + str(inserted_disks.size()) + "/4):[/color]\n"
		for disk_name in inserted_disks.keys():
			var slot = inserted_disks[disk_name]["slot"]
			var disk_data = inserted_disks[disk_name]["data"]
			content += "  [" + slot + "] " + disk_name + " - " + disk_data["name"] + "\n"
		
		content += "\n[color=gray]Click on a disk name to view contents[/color]"
		display_content_to_viewport(content)

# Handle terminal commands for disk management
func handle_terminal_command(command: String) -> void:
	var parts = command.split(" ")
	if parts.size() < 2:
		return
		
	var cmd = parts[0].to_lower()
	var disk_name = parts[1]
	
	match cmd:
		"eject":
			eject_disk(disk_name)
		"view":
			if disk_name in inserted_disks:
				show_disk_content(disk_name)
		"list":
			update_disk_interface()
