extends StaticBody3D

# Mailbox interaction script
signal mail_taken

@onready var mail_paper: MeshInstance3D = $MailPaper
var mail_ui: Control = null

var has_mail: bool = true
var is_interacting: bool = false
var mail_was_taken: bool = false  # Prevents re-access

func _ready() -> void:
	# Add mailbox to interaction group
	add_to_group("mailbox")
	
	# Find the mail UI in the scene tree
	mail_ui = get_node("../MailUI")
	if not mail_ui:
		mail_ui = get_tree().get_first_node_in_group("mail_ui")
		if not mail_ui:
			print("Warning: Could not find MailUI node!")
	
	# Set up mail paper initial position (inside mailbox)
	if mail_paper:
		mail_paper.position = Vector3(0, -0.4, 0.1)  # Inside the mailbox
		mail_paper.visible = has_mail
	
	print("Mailbox ready - has mail: ", has_mail)

func take_mail() -> void:
	if not has_mail or is_interacting or mail_was_taken:
		print("Cannot take mail - has_mail: ", has_mail, " is_interacting: ", is_interacting, " already_taken: ", mail_was_taken)
		
		# Show "no mail" message if mail was already taken
		if mail_was_taken and not is_interacting:
			_show_no_mail_message()
		return
	
	is_interacting = true
	print("Taking mail from mailbox...")
	
	# Animate paper sliding out of mailbox
	if mail_paper:
		await _animate_paper_slide_out()
	
	# Mark mail as taken permanently
	has_mail = false
	mail_was_taken = true
	
	# Show mail UI
	_show_mail_ui()
	
	is_interacting = false
	mail_taken.emit()

func _animate_paper_slide_out() -> void:
	if not mail_paper:
		return
	
	# Create tween for smooth animation
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Slide paper out from mailbox (move forward and up)
	var start_pos = Vector3(0, -0.4, 0.1)  # Inside mailbox
	var end_pos = Vector3(0, -0.2, 0.5)    # Sliding out
	
	# Animate position
	tween.tween_property(mail_paper, "position", end_pos, 1.5)
	
	# Add slight rotation for realism
	var start_rotation = Vector3(0, 0, 0)
	var end_rotation = Vector3(-0.2, 0, 0.1)  # Slight tilt
	tween.tween_property(mail_paper, "rotation", end_rotation, 1.5)
	
	# Wait for animation to complete
	await tween.finished
	
	# Small delay before showing UI
	await get_tree().create_timer(0.5).timeout

func _show_mail_ui() -> void:
	# Hide the physical paper after animation
	if mail_paper:
		mail_paper.visible = false
	
	# Get the UI and show the mail
	if mail_ui and mail_ui.has_method("show_mail"):
		mail_ui.show_mail()
	else:
		# Fallback: print mail content to console
		print("Mail Content: Welcome to your new assignment. Report to the laboratory immediately.")

func refill_mail() -> void:
	# For testing - allows refilling the mailbox (resets everything)
	has_mail = true
	mail_was_taken = false
	if mail_paper:
		mail_paper.visible = true
		mail_paper.position = Vector3(0, -0.4, 0.1)
		mail_paper.rotation = Vector3(0, 0, 0)
	print("Mail refilled and mailbox reset!")

func _show_no_mail_message() -> void:
	# Create a temporary label to show "no mail" message
	var no_mail_label = Label.new()
	no_mail_label.text = "No recent mail"
	no_mail_label.add_theme_font_size_override("font_size", 24)
	no_mail_label.add_theme_color_override("font_color", Color.WHITE)
	no_mail_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	no_mail_label.add_theme_constant_override("shadow_offset_x", 2)
	no_mail_label.add_theme_constant_override("shadow_offset_y", 2)
	
	# Position the label in the center of the screen
	no_mail_label.anchor_left = 0.5
	no_mail_label.anchor_right = 0.5
	no_mail_label.anchor_top = 0.5
	no_mail_label.anchor_bottom = 0.5
	no_mail_label.pivot_offset = Vector2(no_mail_label.size.x / 2, no_mail_label.size.y / 2)
	
	# Add to the scene tree (find the main scene root)
	var main_scene = get_tree().current_scene
	if main_scene:
		main_scene.add_child(no_mail_label)
	
	# Animate the message: fade in, stay, fade out
	no_mail_label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(no_mail_label, "modulate:a", 1.0, 0.5)  # Fade in
	tween.tween_interval(2.0)  # Stay visible for 2 seconds
	tween.tween_property(no_mail_label, "modulate:a", 0.0, 1.0)  # Fade out
	
	# Remove the label when animation is complete
	tween.tween_callback(no_mail_label.queue_free)
