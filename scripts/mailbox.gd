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
