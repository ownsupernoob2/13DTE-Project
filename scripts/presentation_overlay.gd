extends Control

signal presentation_finished

@onready var background: ColorRect = $Background
@onready var screen_rect: ColorRect = $ScreenRect
@onready var text_label: RichTextLabel = $TextContainer/NarrationText
@onready var timer: Timer = $Timer

var presentation_texts: Array[String] = [
	"Welcome to the Alien Containment Facility",
	"Your mission is to process alien specimens",
	"Use the medical scanner to identify threats",
	"Follow sedation protocols carefully", 
	"Failure to comply will result in containment breach",
	"Good luck, Agent"
]

var current_message_index: int = 0
var current_char_index: int = 0
var current_message: String = ""
var is_typing: bool = false
var typing_speed: float = 0.05

func _ready() -> void:
	visible = false
	_setup_ui()
	_connect_signals()

func _setup_ui() -> void:
	# Set up the presentation screen appearance
	background.color = Color(0.1, 0.05, 0.05, 0.9)
	screen_rect.color = Color(0.8, 0.1, 0.1, 1)
	
	# Set up text
	text_label.bbcode_enabled = true
	text_label.text = ""

func _connect_signals() -> void:
	timer.timeout.connect(_on_timer_timeout)

func start_presentation() -> void:
	print("🎬 Starting presentation overlay...")
	visible = true
	current_message_index = 0
	await get_tree().create_timer(1.0).timeout
	_show_next_message()

func _show_next_message() -> void:
	if current_message_index >= presentation_texts.size():
		_end_presentation()
		return
	
	current_message = presentation_texts[current_message_index]
	current_char_index = 0
	is_typing = true
	
	# Clear text and start typing
	text_label.text = ""
	timer.wait_time = typing_speed
	timer.start()

func _on_timer_timeout() -> void:
	if not is_typing:
		return
	
	if current_char_index < current_message.length():
		# Add next character
		var display_text = current_message.substr(0, current_char_index + 1)
		text_label.text = "[center]" + display_text + "[/center]"
		current_char_index += 1
	else:
		# Message complete, pause then next
		is_typing = false
		timer.stop()
		await get_tree().create_timer(2.0).timeout
		current_message_index += 1
		_show_next_message()

func _end_presentation() -> void:
	print("🎬 Presentation complete, transitioning to game...")
	visible = false
	presentation_finished.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_skip_current_message()
		elif event.keycode == KEY_ESCAPE:
			_skip_presentation()

func _skip_current_message() -> void:
	if is_typing:
		# Complete current message instantly
		is_typing = false
		timer.stop()
		text_label.text = "[center]" + current_message + "[/center]"
		
		# Short pause then move to next
		await get_tree().create_timer(0.5).timeout
		current_message_index += 1
		_show_next_message()

func _skip_presentation() -> void:
	print("⏭️ Skipping presentation...")
	is_typing = false
	timer.stop()
	_end_presentation()
