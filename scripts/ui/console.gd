extends RichTextLabel
# Base
@export var console_size: Vector2 = Vector2(35,10)  # Even smaller grid for massive font
@export var USER_Name:String = "@USER"
@export var ShowTextArt:bool = true
@export var CanInput:bool = false
var CurrentMode:String = ""
# Data
@export var commands:Dictionary = {}
@export var fileDirectory:Dictionary = {
	"home":{},
	"config":{},
}
var current_path:String = "/home"
# Setup text art
var TextArt:Array[String] = [
	"┎┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┒",
	"┇                 ████████        ███◤                        ┇",
	"┇          ▓▓▓▓▓▓▓▓      ██       █                           ┇",
	"┇   ▒▒▒▒▒▒▒▒        ████████      ██◤  ◢██ ◢██ ◢██ ██◣ ◢██ ◢██┇",
	"┇    ▒▒      ▓▓▓▓▓▓▓▓          ██ █    ◥█◣ ◥█◣ █ ◤ █ █ █   █ ◤┇",
	"┇     ▒▒▒▒▒▒▒▒               ███  ███◤ ██◤ ██◤ ███ █ █ ██◤ ███┇",
	"┇   ░░░▒▒                  ███                                ┇",
	"┇ ░░░  ▒▒ ◥██▶   ▬▬▬▬▬ ██████                                 ┇",
	"┇░░     ▒▒ ◢◤      ▓▓▓▓▓    ██    ◢███                  █     ┇",
	"┇ ░░       ▒▒▒▒▒▓▓▓          ██   █                     █     ┇",
	"┇  ░░░░░░▒▒             ████████  █    ◢██ ██◣ ◢██ ◢██  █  ◢██┇",
	"┇        ▒▒      ▓▓▓▓▓▓▓▓         █    █ █ █ █ ◥█◣ █ █  █  █ ◤┇",
	"┇         ▒▒▒▒▒▒▒▒                ███◤ ██◤ █ █ ██◤ ██◤  █◤ ███┇",
	"┖┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┚"
]
var TextArtThin:Array[String] = [
	"┎┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┒",
	"┇                 ████████       ┇",
	"┇          ▓▓▓▓▓▓▓▓      ██      ┇",
	"┇   ▒▒▒▒▒▒▒▒        ████████     ┇",
	"┇    ▒▒      ▓▓▓▓▓▓▓▓          ██┇",
	"┇     ▒▒▒▒▒▒▒▒               ███ ┇",
	"┇   ░░░▒▒                  ███   ┇",
	"┇ ░░░  ▒▒ ◥██▶   ▬▬▬▬▬ ██████    ┇",
	"┇░░     ▒▒ ◢◤      ▓▓▓▓▓    ██   ┇",
	"┇ ░░       ▒▒▒▒▒▓▓▓          ██  ┇",
	"┇  ░░░░░░▒▒             ████████ ┇",
	"┇        ▒▒      ▓▓▓▓▓▓▓▓        ┇",
	"┇         ▒▒▒▒▒▒▒▒               ┇",
	"┖┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┚"
]
# Input content
var CurrentInputString: String = ""
var CurrentInputString_escaped: String = ""
var _current_cursor_pos: int = 0
# Page scroll
var _current_line: int = 0
# Input visual
var _flash: bool = false
var _flash_timer = Timer.new()
var _start_up:int = 0
var _just_enter: bool = false
var _PrefixText: String = ""
# History
var _send_history: Array[String] = []
var _current_history : int = -1
var _last_input: String = ""
# Edit mode
var current_file: String = ""
var current_file_type: String = "Text"
var _just_save: String = ""

@export var SetLocaleToEng: bool = false

# Audio players (will be set from computer scene)
var audio_press: AudioStreamPlayer
var audio_enter: AudioStreamPlayer
var audio_space: AudioStreamPlayer

var has_permission: bool = false
var inserted_disk: String = ""
var inserted_disk_node: Node = null
var _table_mode: bool = false # Track when we're displaying a table

func _ready() -> void:
	if SetLocaleToEng:
		TranslationServer.set_locale("en_US")
	size = Vector2(console_size.x * 35.0, console_size.y * 60.0)  # Even larger size
	
	# Create theme and use system font
	theme = Theme.new()
	
	# Load the custom font using the correct Godot 4 method
	# var custom_font = load("res://addons/essence_console/hailtotem_next.ttf") as FontFile
	
	# if custom_font:
		# Set the custom font for all font types
		# theme.set_font("normal_font", "RichTextLabel", custom_font)
		# theme.set_font("bold_font", "RichTextLabel", custom_font)
		# theme.set_font("italics_font", "RichTextLabel", custom_font)
		# theme.set_font("bold_italics_font", "RichTextLabel", custom_font)
		# theme.set_font("mono_font", "RichTextLabel", custom_font)
		
		# print("Custom font loaded successfully")
	# else:
		# print("Warning: Could not load custom font, using system font")
	
	# Set font sizes using add_theme_font_size_override (more direct method)
	add_theme_font_size_override("normal_font_size", 25)
	add_theme_font_size_override("bold_font_size", 25)
	add_theme_font_size_override("italics_font_size", 25)
	add_theme_font_size_override("bold_italics_font_size", 25)
	add_theme_font_size_override("mono_font_size", 25)
	
	# Also set in theme as backup
	theme.set_font_size("normal_font_size", "RichTextLabel", 25)
	theme.set_font_size("bold_font_size", "RichTextLabel", 25)
	theme.set_font_size("italics_font_size", "RichTextLabel", 25)
	theme.set_font_size("bold_italics_font_size", "RichTextLabel", 25)
	theme.set_font_size("mono_font_size", "RichTextLabel", 25)
	
	_built_in_command_init()
	add_child(_flash_timer)
	text = ""
	_flash_timer.set_one_shot(true)
	_flash_timer.start(1)
	var fake_disk = $"../../../FakeDisk"
	if fake_disk:
		fake_disk.visible = false
		print("FakeDisk hidden at startup")
	else:
		print("Warning: FakeDisk not found at startup")
		
func _process(delta: float) -> void:
	set_prefix()
	if _flash_timer.time_left == 0:
		if _start_up == 0:
			# Skip text art display and go straight to console
			_start_up += 1
			_flash_timer.start()
		else:
			_flash = !_flash
			if !CanInput:
				clear()
				CanInput = true
				# Show initial commands on first boot
				_show_startup_commands()
				# Ensure we scroll to the bottom after startup commands
				scroll_to_line(get_line_count())
				_current_line = 0
			append_current_input_string()
			_flash_timer.start()

# Audio functions
func play_press_sound():
	if audio_press:
		audio_press.pitch_scale = randf_range(0.9, 1.2)
		audio_press.play()
	else:
		print("Warning: audio_press not set")

func play_enter_sound():
	if audio_enter:
		audio_enter.play()
	else:
		print("Warning: audio_enter not set")

func play_space_sound():
	if audio_space:
		audio_space.play()
	else:
		print("Warning: audio_space not set")

# Test function to verify audio setup
func test_audio_setup():
	print("Testing audio setup...")
	print("audio_press: ", audio_press)
	print("audio_enter: ", audio_enter)
	print("audio_space: ", audio_space)
	if audio_press:
		print("Press audio player is ready")
	if audio_enter:
		print("Enter audio player is ready")
	if audio_space:
		print("Space audio player is ready")

func _unhandled_key_input(event: InputEvent) -> void:
	if !Global.is_using_computer:
		return
	if event.is_pressed() and CanInput:
		match event.as_text():
			"A","B","C","D","E","F","G",\
			"H","I","J","K","L","M","N",\
			"O","P","Q","R","S","T","U",\
			"V","W","X","Y","Z":
				play_press_sound()
				insert_character(event.as_text().to_lower())
			"Shift+A","Shift+B","Shift+C","Shift+D","Shift+E","Shift+F","Shift+G",\
			"Shift+H","Shift+I","Shift+J","Shift+K","Shift+L","Shift+M","Shift+N",\
			"Shift+O","Shift+P","Shift+Q","Shift+R","Shift+S","Shift+T","Shift+U",\
			"Shift+V","Shift+W","Shift+X","Shift+Y","Shift+Z",\
			"Kp 1","Kp 2","Kp 3","Kp 4","Kp 5","Kp 6","Kp 7","Kp 8","Kp 9","Kp 0":
				play_press_sound()
				insert_character(event.as_text()[-1])
			"0","1","2","3","4","5","6","7","8","9":
				play_press_sound()
				insert_character(event.as_text())
			"Space","Shift_Space": 
				play_space_sound()
				insert_character(" ")
			"BracketLeft": 
				play_press_sound()
				insert_character("[")
			"BracketRight": 
				play_press_sound()
				insert_character("]")
			"Slash","Kp Divide": 
				play_press_sound()
				insert_character("/")
			"QuoteLeft": 
				play_press_sound()
				insert_character("`")
			"Shift+QuoteLeft": 
				play_press_sound()
				insert_character("~")
			"Shift+1": 
				play_press_sound()
				insert_character("!")
			"Shift+2": 
				play_press_sound()
				insert_character("@")
			"Shift+3": 
				play_press_sound()
				insert_character("#")
			"Shift+4": 
				play_press_sound()
				insert_character("$")
			"Shift+5": 
				play_press_sound()
				insert_character("%")
			"Shift+6": 
				play_press_sound()
				insert_character("^")
			"Shift+7": 
				play_press_sound()
				insert_character("&")
			"Shift+8","Kp Multiply": 
				play_press_sound()
				insert_character("*")
			"Shift+9": 
				play_press_sound()
				insert_character("(")
			"Shift+0": 
				play_press_sound()
				insert_character(")")
			"Minus","Kp Subtract": 
				play_press_sound()
				insert_character("-")
			"Shift+Minus": 
				play_press_sound()
				insert_character("_")
			"Equal": 
				play_press_sound()
				insert_character("=")
			"Shift+Equal","Kp Add": 
				play_press_sound()
				insert_character("+")
			"Shift+BracketLeft": 
				play_press_sound()
				insert_character("{")
			"Shift+BracketRight": 
				play_press_sound()
				insert_character("}")
			"BackSlash": 
				play_press_sound()
				insert_character("\\")
			"Shift+BackSlash": 
				play_press_sound()
				insert_character("|")
			"Semicolon": 
				play_press_sound()
				insert_character(";")
			"Shift+Semicolon": 
				play_press_sound()
				insert_character(":")
			"Apostrophe": 
				play_press_sound()
				insert_character("'")
			"Shift+Apostrophe": 
				play_press_sound()
				insert_character("\"")
			"Comma": 
				play_press_sound()
				insert_character(",")
			"Shift+Comma": 
				play_press_sound()
				insert_character("<")
			"Period","Kp Period": 
				play_press_sound()
				insert_character(".")
			"Shift+Period": 
				play_press_sound()
				insert_character(">")
			"Shift+Slash": 
				play_press_sound()
				insert_character("?")
			"Shift":
				pass
			"Backspace","Shift+Backspace":
				play_press_sound()
				scroll_to_line(get_line_count())
				_current_line = 0
				if _current_cursor_pos == 0:
					if CurrentInputString.right(1) == "\n":
						remove_paragraph(get_paragraph_count()-1)
					CurrentInputString = CurrentInputString.left(CurrentInputString.length()-1)
				elif _current_cursor_pos > 0 && _current_cursor_pos < CurrentInputString.length():
					if CurrentInputString[CurrentInputString.length() -_current_cursor_pos - 1] == "\n":
						remove_paragraph(get_paragraph_count()-1)
					CurrentInputString = CurrentInputString.erase(CurrentInputString.length() -_current_cursor_pos - 1)
			"Enter","Kp Enter":
				play_enter_sound()
				match CurrentMode:
					"","Default":
						append_current_input_string(true)
					"Edit":
						append_text("[p][/p]")
						insert_character("\n")
			"Left":
				scroll_to_line(get_line_count())
				_current_line = 0
				_flash = true
				if _current_cursor_pos < CurrentInputString.length():
					_current_cursor_pos += 1
			"Right":
				scroll_to_line(get_line_count())
				_current_line = 0
				_flash = true
				if _current_cursor_pos > 0:
					_current_cursor_pos -= 1
			"Up":
				if CurrentMode == "" or CurrentMode == "Default":
					append_history()
			"Down":
				if CurrentMode == "" or CurrentMode == "Default":
					append_history(false)
			"PageUp":
				scroll_page(false)
			"PageDown":
				scroll_page()
			"Ctrl+S":
				if CurrentMode == "Edit":
					_flash = true
					if match_file_type(current_file_type,CurrentInputString):
						match_file_type(current_file_type,CurrentInputString,false,true)
						_just_save = "Success"
					else:
						_just_save = "Fail"
			"Ctrl+X":
				if CurrentMode == "Edit":
					_flash = false
					_current_cursor_pos = 0
					append_current_input_string()
					newline()
					CurrentMode = ""
					CurrentInputString = ""
					set_prefix()
			"Escape":
				if _table_mode:
					_exit_table_mode()
				else:
					# Default escape behavior if needed
					pass
			_: print(event.as_text())
		CurrentInputString_escaped = CurrentInputString.replace("[", "[lb]").replace("\n", "\u2B92\n")
		append_current_input_string()
		_just_enter = false

func append_current_input_string(enter:bool=false) -> void:
	if !_just_enter:
		remove_paragraph(get_paragraph_count()-1)
		match CurrentMode:
			"Edit":
				for i in CurrentInputString.count("\n"):
					remove_paragraph(get_paragraph_count()-1)
	if !enter:
		if _flash:
			push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
			if _current_cursor_pos == 0:
				match _just_save:
					"Success":
						append_text(_PrefixText + CurrentInputString_escaped + "[color=LIME_GREEN]\u2581[/color]")
					"Fail":
						append_text(_PrefixText + CurrentInputString_escaped + "[color=CRIMSON]\u2581[/color]")
					_:
						append_text(_PrefixText + CurrentInputString_escaped + "\u2581")
			elif _current_cursor_pos > 0:
				var minus_num = (3 * CurrentInputString.right(_current_cursor_pos - 1).count("["))\
						+ (CurrentInputString.right(_current_cursor_pos - 1).count("\n"))
				var cis_left: String = _PrefixText + CurrentInputString_escaped.left(-_current_cursor_pos - minus_num)
				match CurrentInputString[-_current_cursor_pos]:
					"[":
						append_text(cis_left.trim_suffix("[lb"))
					"\n":
						append_text(cis_left.trim_suffix("\u2B92"))
					_:
						append_text(cis_left)
				match _just_save:
					"Success":
						push_bgcolor(Color("LIME_GREEN"))
					"Fail":
						push_bgcolor(Color("CRIMSON"))
					_:
						push_bgcolor(Color("WHITE"))
				push_color(Color("BLACK"))
				match CurrentInputString[-_current_cursor_pos]:
					"[":
						append_text("[")
					"\n":
						append_text("\u2B92\n")
					_:
						append_text(CurrentInputString_escaped[-_current_cursor_pos - minus_num])
				pop()
				pop()
				append_text(CurrentInputString_escaped.right(_current_cursor_pos - 1 + minus_num))
				if CurrentMode == "Edit":
					append_text(" ")
			pop()
		else:
			push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
			append_text(_PrefixText + CurrentInputString_escaped + " ")
			pop()
		# Auto-scroll to keep current input visible
		scroll_to_line(get_line_count())
		_current_line = 0
	else:
		_current_cursor_pos = 0
		push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
		append_text(_PrefixText + CurrentInputString_escaped)
		pop()
		newline()
		if CurrentInputString != "":
			_send_history.append(CurrentInputString)
		_current_history = -1
		_last_input = ""
		process(CurrentInputString)
		if current_path == "":
			current_path = "/"
		set_prefix()
		if CurrentMode == "" or CurrentMode == "Default":
			CurrentInputString = ""
			CurrentInputString_escaped = ""
		_just_enter = true
		scroll_to_line(get_line_count())
		_current_line = 0

func insert_character(character:String) -> void:
	scroll_to_line(get_line_count())
	_just_save = ""
	_current_line = 0
	if _current_cursor_pos == 0:
		CurrentInputString += character
	elif _current_cursor_pos > 0:
		CurrentInputString = CurrentInputString.insert(CurrentInputString.length() -_current_cursor_pos,character)

func scroll_page(down:bool = true) -> void:
	if down:
		if _current_line > 0:
			_current_line -= 1
	elif _current_line < get_line_count() - console_size.y:
		_current_line += 1
	scroll_to_line(get_line_count() - console_size.y - _current_line)

func append_history(up:bool = true) -> void:
	scroll_to_line(get_line_count())
	_current_cursor_pos = 0
	if _current_history == -1:
		_last_input = CurrentInputString
	if _send_history.size() != 0:
		if up:
			if _current_history == -1:
				_current_history = _send_history.size() -1
			elif _current_history != 0:
				_current_history -= 1
		else:
			if _current_history == -1:
				pass
			elif _current_history == _send_history.size() -1:
				_current_history = -1
			elif _current_history < _send_history.size() -1:
				_current_history += 1
	if _send_history.size() != 0 and _current_history != -1 and _current_history <= _send_history.size() -1:
		CurrentInputString = _send_history[_current_history]
	else:
		_current_history = -1
		CurrentInputString = _last_input

func set_prefix() -> void:
	match CurrentMode:
		"","Default":
			_PrefixText = "[bgcolor=DODGER_BLUE]" + USER_Name + "[/bgcolor][bgcolor=WEB_GRAY][color=DODGER_BLUE]\u25E3[/color]"\
				+ return_path_string(current_path) +"[/bgcolor][color=WEB_GRAY]\u25B6[/color]"
		"Edit":
			_PrefixText = "[bgcolor=DODGER_BLUE]" + USER_Name + "[/bgcolor][bgcolor=WEB_GRAY][color=DODGER_BLUE]\u25E3[/color]"\
				+ return_path_string(current_path) +"[/bgcolor][bgcolor=BURLYWOOD][color=WEB_GRAY]\u25B6[/color]"\
				+ "\U01F4DD" + current_file + "[/bgcolor][color=BURLYWOOD]\u25B6[/color]"
		_:
			append_text(tr("error.mode_undefined"))
			CurrentMode = ""

# Helper function to repeat strings (GDScript doesn't support string * int)
func repeat_string(text: String, count: int) -> String:
	var result = ""
	for i in range(count):
		result += text
	return result

# Helper function to pad strings to the right (GDScript doesn't have pad_right)
func pad_string_right(text: String, width: int) -> String:
	if text.length() >= width:
		return text.substr(0, width)
	var padding_needed = width - text.length()
	return text + repeat_string(" ", padding_needed)

# Helper function to center text within a given width
func pad_string_center(text: String, width: int) -> String:
	if text.length() >= width:
		return text.substr(0, width)
	var padding_needed = width - text.length()
	var left_padding = padding_needed / 2
	var right_padding = padding_needed - left_padding
	return repeat_string(" ", left_padding) + text + repeat_string(" ", right_padding)

func insert_disk(disk_name: String, disk_node: Node, disk_data: Dictionary = {}) -> void:
	var valid_disks = ["Disk1", "Disk2", "Disk3", "Disk4"]
	if not disk_name in valid_disks:
		append_text("[color=RED]Error: Invalid disk name. Supported: " + str(valid_disks) + "[/color]")
		newline()
		return

	if inserted_disk != "":
		append_text("[color=RED]Error: Computer already has a disk inserted (" + inserted_disk + ").[/color]")
		newline()
		append_text("[color=YELLOW]Use 'eject' command to remove current disk first.[/color]")
		newline()
		return

	var fake_disk = get_node_or_null("../../../" + disk_name)
	if not fake_disk:
		append_text("[color=RED]Error: " + disk_name + " node not found.[/color]")
		newline()
		return

	var animation_player = fake_disk.get_node_or_null("AnimationPlayer")
	if not animation_player:
		animation_player = fake_disk.get_parent().get_node_or_null("AnimationPlayer")
	
	if animation_player and animation_player.has_animation("insert"):
		fake_disk.visible = true
		animation_player.play("insert")
		await animation_player.animation_finished
	else:
		append_text("[color=YELLOW]Warning: No insertion animation found, proceeding with insertion.[/color]")
		newline()

	inserted_disk = disk_name
	inserted_disk_node = disk_node
	var home_path_instance = get_path_instance("/home")
	if !home_path_instance.has(disk_name):
		var disk_files = {
			"weight_classes.csv": generate_csv_content(disk_name, "weight_classes.csv"),
			"eye_color": {
				"eye_color_data1.csv": generate_csv_content(disk_name, "eye_color_data1.csv"),
				"eye_color_data2.csv": generate_csv_content(disk_name, "eye_color_data2.csv"),
				"eye_color_data3.csv": generate_csv_content(disk_name, "eye_color_data3.csv")
			}
		}
		home_path_instance[disk_name] = disk_files
		append_text("[color=GREEN]Disk '" + disk_name + "' inserted successfully.[/color]")
		newline()
		display_disk_info(disk_name, disk_data)
	else:
		append_text("[color=YELLOW]Warning: Disk already exists in /home.[/color]")
		newline()

	if disk_node is Node3D:
		disk_node.visible = false

func generate_file_content(disk_name: String, filename: String, disk_data: Dictionary) -> String:
	var content = ""
	
	# Use DiskManager to get file content
	if DiskManager:
		content = DiskManager.get_file_content(disk_name, filename)
		
		# Special handling for CSV files
		if filename.ends_with(".csv"):
			if content == "CSV_TABLE":
				content = generate_csv_content(disk_name, filename)
		
		return content
	
	# Fallback content if DiskManager not available
	return "ERROR: Unable to access file content"

func generate_csv_content(disk_name: String, filename: String) -> String:
	if filename == "weight_classes.csv":
		if disk_name == "Disk1":  # Class 1: 120-160 kg - Overlaps with Disk2 and Disk4
			return """WEIGHT_RANGE,LIQUID_A,LIQUID_B,LIQUID_C
120-125,31,51,18
126-131,28,49,23
132-137,33,53,14
138-143,19,62,19
144-149,25,45,30
150-160,35,40,25"""
		elif disk_name == "Disk2":  # Class 2: 75-125 kg - Overlaps with Disk1 and Disk4
			return """WEIGHT_RANGE,LIQUID_A,LIQUID_B,LIQUID_C
75-80,42,38,20
81-86,38,42,20
87-92,32,28,40
93-98,22,18,60
99-104,45,30,25
105-125,50,25,25"""
		elif disk_name == "Disk3":  # Class 3: 180-280 kg - Overlaps with Disk1
			return """WEIGHT_RANGE,LIQUID_A,LIQUID_B,LIQUID_C
180-195,50,45,15
196-211,45,50,15
212-227,40,35,35
228-243,30,25,55
244-259,35,30,35
260-280,25,35,40"""
		elif disk_name == "Disk4":  # Class 4: 45-85 kg - Overlaps with Disk1 and Disk2
			return """WEIGHT_RANGE,LIQUID_A,LIQUID_B,LIQUID_C
45-50,60,55,10
51-56,55,45,25
57-62,50,35,45
63-68,45,30,50
69-74,40,40,20
75-85,35,35,30"""
		else:
			return "CSV_ERROR: Unable to generate table for " + disk_name + " " + filename
	return "CSV_ERROR: Unable to generate table for " + disk_name + " " + filename

func display_disk_info(disk_name: String, disk_data: Dictionary) -> void:
	append_text("[color=CYAN]" + repeat_string("=", 80) + "[/color]")
	newline()
	append_text("[color=CYAN]              ALIEN CLASSIFICATION DATA DISK INSERTED[/color]")
	newline()
	append_text("[color=CYAN]" + repeat_string("=", 80) + "[/color]")
	newline()
	
	append_text("[color=YELLOW]Disk:[/color] " + disk_name)
	newline()
	newline()
	
	append_text("[color=GREEN]COMMANDS TO GET STARTED:[/color]")
	newline()
	append_text("  [color=WHITE]ls[/color]                        - List all files on disk")
	newline()
	append_text("  [color=WHITE]cd folder_name[/color]            - Enter directory folder")
	newline()
	append_text("  [color=WHITE]table weight_classes.csv[/color] - View weight/liquid ratio data")
	newline()
	append_text("  [color=WHITE]eject[/color]                     - Remove this disk")
	newline()
	newline()
	
	append_text("[color=YELLOW]WORKFLOW:[/color]")
	newline()
	append_text("1. Check alien weight on monitor system")
	newline()
	append_text("2. Find matching weight range in CSV data")
	newline()
	append_text("3. Set lever values to match liquid ratios")
	newline()
	append_text("5. Accept/Reject alien classification")
	newline()
	newline()
	
	append_text("[color=CYAN]" + repeat_string("=", 80) + "[/color]")
	newline()
		
func check_permission() -> bool:
	return has_permission

func process(command: String) -> void:
	var parts: PackedStringArray = command.strip_edges().split(" ", false)
	var cmd: String = parts[0] if parts.size() > 0 else command.strip_edges()
	var args: Array[String] = []
	if parts.size() > 1:
		args.append_array(parts.slice(1))
	
	if !commands.keys().has(cmd):
		push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
		append_text("[color=RED]" + tr("error.command_not_found") + "[/color] " + cmd)
		pop()
		newline()
		# Auto-scroll after error message
		scroll_to_line(get_line_count())
		_current_line = 0
		return
	
	var commandData = commands[cmd]
	var expected_arg_count: int = commandData.function.get_argument_count()
	
	if expected_arg_count != args.size():
		push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
		append_text("[color=RED]" + tr("error.parameter_count_mismatch") + "[/color] " + tr("error.parameter_count_mismatch.expect_got") \
						% [str(expected_arg_count), args])
		pop()
		newline()
		# Auto-scroll after error message
		scroll_to_line(get_line_count())
		_current_line = 0
		return
	
	if cmd in ["mkdir", "touch", "rm", "mv", "cp", "nano"] and not check_permission():
		push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
		append_text("[color=RED]Insufficient permissions.[/color]")
		pop()
		newline()
		# Auto-scroll after permission error
		scroll_to_line(get_line_count())
		_current_line = 0
		return
	
	commandData.function.callv(args)
	
	# Auto-scroll after command execution (unless in table mode)
	if not _table_mode:
		scroll_to_line(get_line_count())
		_current_line = 0

func add_command(id: String, function: Callable, functionInstance: Object, helpText: String = "", helpDetail: String = ""):
	commands[id] = EC_CommandClass.new(id, function, functionInstance, helpText, helpDetail)

func _built_in_command_init():
	add_command(
		"man",
		func(id: String = ""):
			if id == "":
				for i in commands:
					append_text(i + ": " + commands[i].helpText)
					newline()
			elif commands.keys().has(id):
				append_text(commands[id].helpDetail)
			else:
				append_text("[color=RED]" + tr("error.command_not_found") + "[/color] " + id)
			newline(),
		self,
		tr("help.man"),
		tr("help.man.detail")
	)
	add_command(
		"clear",
		func():
			if _table_mode:
				_exit_table_mode()
			else:
				clear(),
		self,
		tr("help.clear"),
		tr("help.clear.detail")
	)
	add_command(
		"echo",
		func(input: String):
			append_text(input)
			newline(),
		self,
		tr("help.echo"),
		tr("help.echo.detail")
	)
	add_command(
		"pwd",
		func():
			var path_instance = get_path_instance(current_path)
			if !path_instance.has(null):
				append_text(current_path)
			else:
				append_text(path_instance.get(null))
				current_path = "/home"
			newline(),
		self,
		tr("help.pwd"),
		tr("help.pwd.detail")
	)
	add_command(
		"ls",
		func():
			var path_instance = get_path_instance(current_path)
			if !path_instance.has(null):
				for i in path_instance:
					var icon = "\uFFFD"
					if path_instance[i] is String:
						icon = "\U01F5CE"
					elif path_instance[i] is Dictionary:
						icon = "\U01F5C1"
					append_text(icon + i)
					newline()
			else:
				append_text(path_instance.get(null))
				current_path = "/home"
			newline(),
		self,
		tr("help.ls"),
		tr("help.ls.detail")
	)
	add_command(
		"cd",
		func(path: String):
			if !get_path_instance(path, true).has(null):
				pass
			else:
				append_text(get_path_instance(path).get(null))
			newline(),
		self,
		tr("help.cd"),
		tr("help.cd.detail")
	)
	add_command(
		"auth",
		func(password: String):
			if password == "123":
				has_permission = true
				append_text("Permission granted.")
			else:
				has_permission = false
				append_text("[color=RED]Incorrect password.[/color]")
			newline(),
		self,
		"Authenticate to gain write permissions",
		"Grants write permissions for file system commands with correct password"
	)
	add_command(
		"help",
		func():
			append_text("[color=CYAN]" + repeat_string("═", 90) + "[/color]")
			newline()
			append_text("[color=CYAN]                    ALIEN CLASSIFICATION TERMINAL - COMMAND REFERENCE[/color]")
			newline()
			append_text("[color=CYAN]" + repeat_string("═", 90) + "[/color]")
			newline()
			newline()
			append_text("[color=YELLOW]NAVIGATION COMMANDS:[/color]")
			newline()
			append_text("  [color=WHITE]ls[/color]         - List contents of current directory")
			newline()
			append_text("  [color=WHITE]cd[/color]         - Change to specified directory")
			newline()
			append_text("  [color=WHITE]pwd[/color]        - Show current directory path")
			newline()
			newline()
			append_text("[color=YELLOW]FILE OPERATIONS:[/color]")
			newline()
			append_text("  [color=WHITE]cat[/color]        - Display contents of a text file")
			newline()
			append_text("  [color=WHITE]table[/color]      - View CSV data in formatted table")
			newline()
			newline()
			append_text("[color=YELLOW]DISK OPERATIONS:[/color]")
			newline()
			append_text("  [color=WHITE]eject[/color]      - Remove currently inserted disk")
			newline()
			newline()
			append_text("[color=YELLOW]UTILITY:[/color]")
			newline()
			append_text("  [color=WHITE]clear[/color]      - Clear the terminal screen")
			newline()
			append_text("  [color=WHITE]help[/color]       - Show this command reference")
			newline()
			newline()
			append_text("[color=CYAN]" + repeat_string("═", 90) + "[/color]")
			newline()
			append_text("[color=GRAY]Insert a data disk and use these commands to analyze alien specimens[/color]")
			newline(),
		self,
		"Show list of commands",
		"Displays all available commands with their descriptions"
	)
	add_command(
		"mkdir",
		func(folder_name: String):
			if folder_name.is_valid_filename():
				var path_instance = get_path_instance(current_path)
				if !path_instance.has(null):
					if !path_instance.has(folder_name):
						path_instance[folder_name] = {}
					else:
						append_text("[i]" + folder_name + "[/i] " + tr("error.already_exist"))
				else:
					append_text(path_instance.get(null))
			else:
				append_text("[color=RED]" + tr("error.invalid_file_name") + "[/color] [i]" + folder_name + "[/i]")
			newline(),
		self,
		tr("help.mkdir"),
		tr("help.mkdir.detail")
	)
	add_command(
		"touch",
		func(file_name: String):
			if file_name.is_valid_filename():
				var path_instance = get_path_instance(current_path)
				if !path_instance.has(null):
					if !path_instance.has(file_name):
						path_instance[file_name] = ""
					else:
						append_text("[i]" + file_name + "[/i] " + tr("error.already_exist"))
				else:
					append_text(path_instance.get(null))
			else:
				append_text("[color=RED]" + tr("error.invalid_file_name") + "[/color] [i]" + file_name + "[/i]")
			newline(),
		self,
		tr("help.touch"),
		tr("help.touch.detail")
	)
	add_command(
		"rm",
		func(file_name: String):
			var path_instance = get_path_instance(current_path)
			if !path_instance.has(null):
				if path_instance.has(file_name):
					path_instance.erase(file_name)
				else:
					append_text("[i]" + file_name + "[/i] " + tr("error.not_exist"))
			else:
				append_text(path_instance.get(null))
			newline(),
		self,
		tr("help.rm"),
		tr("help.rm.detail")
	)
	add_command(
		"mv",
		func(file_name: String, to_name: String):
			var path_instance = get_path_instance(current_path)
			if !path_instance.has(null):
				if path_instance.has(file_name):
					if to_name.is_valid_filename():
						if !path_instance.has(to_name):
							path_instance[to_name] = path_instance[file_name]
							path_instance.erase(file_name)
						else:
							append_text("[i]" + to_name + "[/i] " + tr("error.already_exist"))
					else:
						append_text("[color=RED]" + tr("error.invalid_file_name") + "[/color] [i]" + to_name + "[/i]")
				else:
					append_text("[i]" + file_name + "[/i] " + tr("error.not_exist"))
			else:
				append_text(path_instance.get(null))
			newline(),
		self,
		tr("help.mv"),
		tr("help.mv.detail")
	)
	add_command(
		"cp",
		func(file_name: String, to_name: String):
			var path_instance = get_path_instance(current_path)
			if !path_instance.has(null):
				if path_instance.has(file_name):
					if to_name.is_valid_filename():
						if !path_instance.has(to_name):
							path_instance[to_name] = path_instance[file_name].duplicate(true)
						else:
							append_text("[i]" + to_name + "[/i] " + tr("error.already_exist"))
					else:
						append_text("[color=RED]" + tr("error.invalid_file_name") + "[/color] [i]" + to_name + "[/i]")
				else:
					append_text("[i]" + file_name + "[/i] " + tr("error.not_exist"))
			else:
				append_text(path_instance.get(null))
			newline(),
		self,
		tr("help.cp"),
		tr("help.cp.detail")
	)
	add_command(
		"cat",
		func(file_name: String):
			var path_instance = get_path_instance(current_path)
			if !path_instance.has(null):
				if path_instance.has(file_name):
					append_text(str(path_instance[file_name]))
				else:
					append_text("[i]" + file_name + "[/i] " + tr("error.not_exist"))
			else:
				append_text(path_instance.get(null))
			newline(),
		self,
		tr("help.cat"),
		tr("help.cat.detail")
	)
	add_command(
		"nano",
		func(file_name: String):
			var path_instance = get_path_instance(current_path)
			if !path_instance.has(null):
				if path_instance.has(file_name):
					if path_instance[file_name] is String:
						current_file_type = "Text"
						CurrentMode = "Edit"
						current_file = file_name
						CurrentInputString = str(path_instance[file_name])
					else:
						append_text(tr("error.cant_edit"))
				else:
					append_text("[i]" + file_name + "[/i] " + tr("error.not_exist"))
			else:
				append_text(path_instance.get(null))
			newline(),
		self,
		tr("help.nano"),
		tr("help.nano.detail")
	)
	add_command(
		"expr",
		func(command: String):
			var expression = Expression.new()
			var error = expression.parse(command)
			if error != OK:
				append_text("[color=RED]" + tr("error.parse") + "[/color] " + expression.get_error_text())
			else:
				var result = expression.execute()
				if not expression.has_execute_failed() and result:
					append_text(str(result))
			newline(),
		self,
		tr("help.expr"),
		tr("help.expr.detail")
	)
	add_command(
	"eject",
	func():
		# Simple eject command - works from any directory
		if inserted_disk == "":
			append_text("[color=YELLOW]No disk currently inserted.[/color]")
			newline()
			return

		var path_instance = get_path_instance(current_path)
		if path_instance.has(null):
			append_text("[color=RED]Error: Cannot access current directory.[/color]")
			newline()
			return
		if not path_instance.has(inserted_disk):
			append_text("[color=RED]Error: Disk not found in current directory.[/color]")
			newline()
			return

		# Immediately exit computer mode
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("exit_computer_mode"):
			player.exit_computer_mode()
			print("Exited computer mode for eject")
		else:
			append_text("[color=RED]Error: Player not found.[/color]")
			newline()
			return

		# Use the correct disk node based on inserted_disk (dynamic path)
		var disk_node = get_node_or_null("../../../" + inserted_disk)
		if not disk_node:
			append_text("[color=RED]Error: " + inserted_disk + " node not found.[/color]")
			newline()
			return
		print(inserted_disk + " found, initial visible: ", disk_node.visible)

		var animation_player = disk_node.get_node_or_null("AnimationPlayer")
		if not animation_player:
			animation_player = disk_node.get_parent().get_node_or_null("AnimationPlayer")
		if not animation_player:
			append_text("[color=RED]Error: AnimationPlayer not found for " + inserted_disk + ".[/color]")
			newline()
			return
		print("AnimationPlayer found for " + inserted_disk + ": ", animation_player)

		if animation_player.has_animation("eject"):
			disk_node.visible = true
			print(inserted_disk + " set visible for eject animation")
			animation_player.play("eject")
			await animation_player.animation_finished
			disk_node.visible = false
			print("Eject animation finished, " + inserted_disk + " hidden")
		else:
			append_text("[color=YELLOW]Warning: No ejection animation found for " + inserted_disk + ", proceeding with ejection.[/color]")
			newline()

		path_instance.erase(inserted_disk)
		append_text("[color=GREEN]Disk '" + inserted_disk + "' ejected successfully.[/color]")
		newline()

		if player and player.has_method("return_disk_to_hand"):
			inserted_disk_node.add_to_group("grabbable")
			player.return_disk_to_hand(inserted_disk, inserted_disk_node)
			print("Disk returned to player’s hand")
		else:
			append_text("[color=RED]Error: Player not found for disk return.[/color]")
			newline()

		inserted_disk = ""
		inserted_disk_node = null
		,
	self,
	"Eject the inserted disk",
	"Ejects the inserted disk from the computer, returning it to the player’s hand"
)
	add_command(
		"e",
		func():
			# Quick shortcut for eject
			if inserted_disk == "":
				append_text("[color=YELLOW]No disk currently inserted.[/color]")
				newline()
				return
			# Call the main eject function - simplified approach
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_method("exit_computer_mode"):
				player.exit_computer_mode()
			if player and player.has_method("return_disk_to_hand") and inserted_disk_node:
				inserted_disk_node.add_to_group("grabbable")
				player.return_disk_to_hand(inserted_disk, inserted_disk_node)
			var home_path_instance = get_path_instance("/home")
			if home_path_instance.has(inserted_disk):
				home_path_instance.erase(inserted_disk)
			append_text("[color=GREEN]Disk '" + inserted_disk + "' ejected.[/color]")
			newline()
			inserted_disk = ""
			inserted_disk_node = null,
		self,
		"Quick eject shortcut",
		"Same as 'eject' command - quickly remove the current disk"
	)
	add_command(
		"disks",
		func():
			if inserted_disk == "":
				append_text("[color=YELLOW]No disks currently inserted.[/color]")
			else:
				append_text("[color=GREEN]Currently inserted disk: " + inserted_disk + "[/color]")
			newline(),
		self,
		"Show inserted disks",
		"Lists all currently inserted disks"
	)
	add_command(
		"diskinfo",
		func():
			if inserted_disk == "":
				append_text("[color=RED]No disk inserted.[/color]")
				newline()
				return
			
			var path_instance = get_path_instance(current_path)
			if path_instance.has(inserted_disk):
				append_text("[color=CYAN]Disk: " + inserted_disk + "[/color]")
				newline()
				append_text("[color=YELLOW]Files:[/color]")
				newline()
				var disk_data = path_instance[inserted_disk]
				for file_name in disk_data.keys():
					append_text("  - " + file_name)
					newline()
			else:
				append_text("[color=RED]Disk data not found.[/color]")
				newline(),
		self,
		"Show disk information",
		"Displays information about the currently inserted disk"
	)
	add_command(
		"table",
		func(filename: String = ""):
			append_text("[color=GRAY]Current path: " + current_path + "[/color]")
			newline()
			var path_instance = get_path_instance(current_path)
			if not path_instance.has(inserted_disk):
				# Try /home as fallback
				var home_path_instance = get_path_instance("/home")
				if home_path_instance.has(inserted_disk):
					path_instance = home_path_instance
					append_text("[color=YELLOW]Disk found in /home.[/color]")
					newline()
				else:
					append_text("[color=RED]Disk data not found in current path or /home.[/color]")
					newline()
					append_text("[color=GRAY]fileDirectory: " + str(fileDirectory) + "[/color]")
					newline()
					return
			var disk_data = path_instance[inserted_disk]
			var csv_files = []
			for file_name in disk_data.keys():
				if file_name.ends_with(".csv"):
					csv_files.append(file_name)
			if csv_files.is_empty():
				append_text("[color=YELLOW]No CSV files found on this disk.[/color]")
				newline()
				return
			if filename != "" and filename in disk_data:
				if filename.ends_with(".csv"):
					show_csv_table(filename)
				else:
					append_text("[color=RED]File '" + filename + "' is not a CSV file.[/color]")
					newline()
			else:
				append_text("[color=CYAN]Available CSV files:[/color]")
				newline()
				for csv_file in csv_files:
					append_text("  - " + csv_file)
					newline()
				append_text("[color=GRAY]Use 'table filename.csv' to view a specific table[/color]")
				newline(),
		self,
		"View CSV tables",
		"Display CSV files in table format. Usage: table [filename.csv]"
	)

func return_path_string(path: String) -> String:
	if current_path == "/home":
		return "\u2302"
	else:
		return current_path

func get_path_instance(path: String, goto: bool = false) -> Dictionary:
	if !path.begins_with("/"):
		path = current_path + "/" + path
	var current_path_instance = fileDirectory
	var path_array: PackedStringArray = path.split("/")
	if path_array.has(".."):
		while path_array.find("..") != -1:
			path_array.remove_at(path_array.find("..") - 1)
			path_array.remove_at(path_array.find(".."))
	for i in path_array:
		if i != "":
			if !current_path_instance.has(i):
				return {null:"[i]" + path + "[/i] " + tr("error.not_exist")}
			elif current_path_instance.get(i) is Dictionary:
				current_path_instance = current_path_instance[i]
			else:
				return {null:"[i]" + path + "[/i] " + tr("error.not.valid_directory")}
	if goto:
		current_path = ""
		for i in path_array:
			if i != "" and i != ".":
				current_path += "/" + i
	return current_path_instance

func match_file_type(type: String = "Text", content: String = "", append_error: bool = false, apply: bool = false, path: Dictionary = get_path_instance(current_path), file: String = current_file) -> bool:
	match type:
		"","Text":
			if apply:
				path[file] = content
			return content != ""
		_:
			if append_error:
				append_text(tr("error.unknown_file_type") % [type])
			return false
func parse_csv_line(line):
	var result = []
	var current = ""
	var in_quotes = false
	for c in line:
		if c == '"':
			in_quotes = !in_quotes
		elif c == ',' and !in_quotes:
			result.append(current)
			current = ""
		else:
			current += c
	result.append(current)
	return result

func show_csv_table(filename: String) -> void:
	var csv_content = generate_csv_content(inserted_disk, filename)
	if csv_content.begins_with("CSV_ERROR"):
		append_text("[color=RED]" + csv_content + "[/color]")
		newline()
		return
	
	# Parse CSV content
	var lines = csv_content.split("\n")
	if lines.is_empty():
		append_text("[color=RED]Empty CSV file.[/color]")
		newline()
		return
	
	var headers = parse_csv_line(lines[0])
	var data_rows = []
	for i in range(1, lines.size()):
		if lines[i].strip_edges() != "":
			data_rows.append(parse_csv_line(lines[i]))
	
	# Calculate column widths to fill entire screen
	var available_width = int(console_size.x) - (headers.size() - 1) * 3  # Account for separators
	var min_column_width = 8
	var column_widths = []
	
	# First pass: calculate minimum required widths
	var min_widths = []
	for i in range(headers.size()):
		var max_len = headers[i].strip_edges().length()
		for row in data_rows:
			if i < row.size():
				max_len = max(max_len, row[i].strip_edges().length())
		min_widths.append(max(max_len + 2, min_column_width))
	
	# Calculate total minimum width needed
	var total_min_width = 0
	for width in min_widths:
		total_min_width += width
	
	# If we have extra space, distribute it proportionally
	if total_min_width < available_width:
		var extra_space = available_width - total_min_width
		var space_per_column = extra_space / headers.size()
		for i in range(headers.size()):
			column_widths.append(min_widths[i] + space_per_column)
	else:
		# Use minimum widths if screen is too small
		column_widths = min_widths
	
	# Enter table mode and hide terminal UI
	_table_mode = true
	clear()
	_hide_terminal_ui()
	
	# Table title with full width border-to-border
	var title_width = 64
	append_text("[color=CYAN]" + repeat_string("═", title_width) + "[/color]")
	newline()
	append_text("[color=CYAN]" + pad_string_center("ALIEN SPECIES CLASSIFICATION DATA TABLE", title_width) + "[/color]")
	newline()
	append_text("[color=CYAN]" + pad_string_center("FILE: " + filename.to_upper(), title_width) + "[/color]")
	newline()
	append_text("[color=CYAN]" + pad_string_center("DISK: " + inserted_disk.to_upper(), title_width) + "[/color]")
	newline()
	append_text("[color=CYAN]" + repeat_string("═", title_width) + "[/color]")
	newline()
	newline()
	
	# Display headers
	var header_line = ""
	for i in range(headers.size()):
		var width = column_widths[i]
		header_line += "[color=YELLOW][b]" + pad_string_right(headers[i].strip_edges(), width) + "[/b][/color]"
		if i < headers.size() - 1:
			header_line += " │ "
	append_text(header_line)
	newline()
	
	# Separator line
	var separator = ""
	for i in range(headers.size()):
		var width = column_widths[i]
		separator += repeat_string("─", width)
		if i < headers.size() - 1:
			separator += "─┼─"
	append_text("[color=GRAY]" + separator + "[/color]")
	newline()
	
	# Display data rows
	for row in data_rows:
		var row_line = ""
		for i in range(headers.size()):
			var cell_value = row[i].strip_edges() if i < row.size() else ""
			var width = column_widths[i]
			var colored_value = "[color=WHITE]" + pad_string_right(cell_value, width) + "[/color]"
			row_line += colored_value
			if i < headers.size() - 1:
				row_line += " │ "
		append_text(row_line)
		newline()
	
	# Table footer with full width border-to-border
	newline()
	append_text("[color=CYAN]" + repeat_string("═", title_width) + "[/color]")
	newline()
	

func _exit_table_mode() -> void:
	_table_mode = false
	_restore_terminal_ui()
	
	newline()
	append_text("[color=GREEN]Returned to terminal.[/color]")
	newline()
	set_prefix()

func _hide_terminal_ui() -> void:
	# This function can be used to hide terminal UI elements during table display
	# Implementation depends on your UI structure
	pass

func _restore_terminal_ui() -> void:
	# This function can be used to restore terminal UI elements after table display
	# Implementation depends on your UI structure
	pass

func _show_startup_commands() -> void:
	append_text("[color=CYAN]ALIEN CLASSIFICATION TERMINAL[/color]")
	newline()
	append_text("[color=YELLOW]Basic Commands:[/color]")
	newline()
	append_text("  help     - Show all available commands")
	newline()
	append_text("  ls       - List files and directories")
	newline()
	append_text("  cd       - Change directory")
	newline()
	append_text("  cat      - Display file contents")
	newline()
	append_text("  table    - View CSV data tables")
	newline()
	append_text("  eject    - Remove inserted disk")
	newline()
	append_text("[color=GRAY]Insert a data disk to begin analysis...[/color]")
	newline()
	newline()
