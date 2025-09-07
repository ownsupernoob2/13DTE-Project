extends Control

# Mail UI for displaying mail content

@onready var mail_background: ColorRect = $MailBackground
@onready var mail_text: RichTextLabel = $MailBackground/MailText

var is_mail_visible: bool = false

func _ready() -> void:
	# Hide mail initially
	visible = false
	# Ensure this control can receive input
	set_process_input(true)
	set_process_unhandled_input(true)
	# Add to group for easy finding
	add_to_group("mail_ui")
	# Set process mode to continue processing when paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	print("Mail UI ready and added to group")

func show_mail() -> void:
	if is_mail_visible:
		print("Mail already visible, skipping")
		return
	
	print("Showing mail UI")
	is_mail_visible = true
	visible = true
	
	# Set mail content
	if mail_text:
		mail_text.text = """[center][color=black][font_size=24]OFFICIAL CORRESPONDENCE[/font_size][/color][/center]

[color=black]Dear Agent,

Welcome to your new assignment at Research Facility 7-B.

Your duties include:
• Operating the alien specimen analysis equipment
• Monitoring containment systems
• Reporting any anomalous activity immediately

The laboratory is fully automated, but requires constant human oversight.
Trust the machines, but verify their results.

Good luck with your assignment.

[right]- Department Head[/right][/color]"""
	
	# Pause the game while reading mail
	get_tree().paused = true
	
	# Hide cursor while reading mail (keep mouse captured)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _close_mail() -> void:
	if not is_mail_visible:
		print("Mail not visible, cannot close")
		return
	
	print("Closing mail UI")
	is_mail_visible = false
	visible = false
	
	# Resume the game
	get_tree().paused = false
	
	# Keep mouse captured (don't change mouse mode)

func _input(event: InputEvent) -> void:
	if is_mail_visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			print("ESC pressed - closing mail")
			_close_mail()
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("Mouse clicked - closing mail")
			_close_mail()
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if is_mail_visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			print("Unhandled ESC - closing mail")
			_close_mail()
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("Unhandled mouse click - closing mail")
			_close_mail()
			get_viewport().set_input_as_handled()
