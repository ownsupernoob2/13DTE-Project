extends Control

# Tutorial Mail UI for level_0.tscn

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
	print("Tutorial Mail UI ready and added to group")

func show_mail() -> void:
	if is_mail_visible:
		print("Mail already visible, skipping")
		return
	
	print("Showing tutorial mail UI")
	is_mail_visible = true
	visible = true
	
	# Set tutorial-specific mail content
	if mail_text:
		mail_text.text = """[center][color=black][font_size=24]TRAINING FACILITY - ORIENTATION BRIEFING[/font_size][/color][/center]

[color=black]Agent [CLASSIFIED],

You have been assigned to Training Pod Alpha-7 for equipment familiarization.

STANDARD OPERATING PROCEDURES:
• All correspondence must be properly reviewed and filed
• Consult your issued Operations Manual before beginning any procedures  
• Specimen analysis requires sustained activation of the initiation sequence
• Hold the START control until the system confirms activation

Your supervisor will monitor this training session remotely.

Complete all orientation tasks before proceeding to active duty.

[right]Department of Xenobiological Research
Training Division[/right][/color]"""
	
	# Pause the game while reading mail
	get_tree().paused = true
	
	# Hide cursor while reading mail (keep mouse captured)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _close_mail() -> void:
	if not is_mail_visible:
		print("Mail not visible, cannot close")
		return
	
	print("Closing tutorial mail UI")
	is_mail_visible = false
	visible = false
	
	# Resume the game
	get_tree().paused = false
	
	# Keep mouse captured (don't change mouse mode)

func _input(event: InputEvent) -> void:
	if is_mail_visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			print("ESC pressed - closing tutorial mail")
			_close_mail()
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("Mouse clicked - closing tutorial mail")
			_close_mail()
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if is_mail_visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			print("Unhandled ESC - closing tutorial mail")
			_close_mail()
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("Unhandled mouse click - closing tutorial mail")
			_close_mail()
			get_viewport().set_input_as_handled()
