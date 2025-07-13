extends RichTextLabel
# Base
@export var console_size: Vector2 = Vector2(100,30)
@export var USER_Name:String = "@USER"
@export var ShowTextArt:bool = true
@export var CanInput:bool = false
var CurrentMode:String = ""
# Data
@export var commands:Dictionary = {}
@export var fileDirectory:Dictionary = {"home":{},"config":{}}
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

var has_permission: bool = false
var inserted_disk: String = ""
var inserted_disk_node: Node = null
var _table_mode: bool = false # Track when we're displaying a table

func _ready() -> void:
	if SetLocaleToEng:
		TranslationServer.set_locale("en_US")
	size = Vector2(console_size.x * 12.5, console_size.y * 23)
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
		if _start_up == 0 and ShowTextArt:
			for i in(console_size.y / 2 + 7):
				if i < console_size.y / 2 - 7:
					newline()
				else:
					if console_size.x >= 63:
						append_text(TextArt[i-console_size.y / 2 + 7])
					elif console_size.x >= 34:
						append_text(TextArtThin[i-console_size.y / 2 + 7])
					pop()
					newline()
			_start_up += 1
			_flash_timer.start()
		else:
			_flash = !_flash
			if !CanInput:
				clear()
				CanInput = true
				# Show initial commands on first boot
				_show_startup_commands()
			append_current_input_string()
			_flash_timer.start()

func _unhandled_key_input(event: InputEvent) -> void:
	if !Global.is_using_computer:
		return
	if event.is_pressed() and CanInput:
		match event.as_text():
			"A","B","C","D","E","F","G",\
			"H","I","J","K","L","M","N",\
			"O","P","Q","R","S","T","U",\
			"V","W","X","Y","Z":
				insert_character(event.as_text().to_lower())
			"Shift+A","Shift+B","Shift+C","Shift+D","Shift+E","Shift+F","Shift+G",\
			"Shift+H","Shift+I","Shift+J","Shift+K","Shift+L","Shift+M","Shift+N",\
			"Shift+O","Shift+P","Shift+Q","Shift+R","Shift+S","Shift+T","Shift+U",\
			"Shift+V","Shift+W","Shift+X","Shift+Y","Shift+Z",\
			"Kp 1","Kp 2","Kp 3","Kp 4","Kp 5","Kp 6","Kp 7","Kp 8","Kp 9","Kp 0":
				insert_character(event.as_text()[-1])
			"0","1","2","3","4","5","6","7","8","9":
				insert_character(event.as_text())
			"Space","Shift_Space": insert_character(" ")
			"BracketLeft": insert_character("[")
			"BracketRight": insert_character("]")
			"Slash","Kp Divide": insert_character("/")
			"QuoteLeft": insert_character("`")
			"Shift+QuoteLeft": insert_character("~")
			"Shift+1": insert_character("!")
			"Shift+2": insert_character("@")
			"Shift+3": insert_character("#")
			"Shift+4": insert_character("$")
			"Shift+5": insert_character("%")
			"Shift+6": insert_character("^")
			"Shift+7": insert_character("&")
			"Shift+8","Kp Multiply": insert_character("*")
			"Shift+9": insert_character("(")
			"Shift+0": insert_character(")")
			"Minus","Kp Subtract": insert_character("-")
			"Shift+Minus": insert_character("_")
			"Equal": insert_character("=")
			"Shift+Equal","Kp Add": insert_character("+")
			"Shift+BracketLeft": insert_character("{")
			"Shift+BracketRight": insert_character("}")
			"BackSlash": insert_character("\\")
			"Shift+BackSlash": insert_character("|")
			"Semicolon": insert_character(";")
			"Shift+Semicolon": insert_character(":")
			"Apostrophe": insert_character("'")
			"Shift+Apostrophe": insert_character("\"")
			"Comma": insert_character(",")
			"Shift+Comma": insert_character("<")
			"Period","Kp Period": insert_character(".")
			"Shift+Period": insert_character(">")
			"Shift+Slash": insert_character("?")
			"Shift":
				pass
			"Backspace","Shift+Backspace":
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

func insert_disk(disk_name: String, disk_node: Node, disk_data: Dictionary = {}) -> void:
	var valid_disks = ["Disk1", "Disk2", "Disk3", "Disk4"]
	if not disk_name in valid_disks:
		append_text("[color=RED]Error: Invalid disk name. Supported: " + str(valid_disks) + "[/color]")
		newline()
		return

	# Check if any disk is already inserted
	if inserted_disk != "":
		append_text("[color=RED]Error: Computer already has a disk inserted (" + inserted_disk + ").[/color]")
		newline()
		append_text("[color=YELLOW]Use 'eject' command to remove current disk first.[/color]")
		newline()
		return

	# Reference the FakeDisk node in the scene (adjust path as needed)
	var fake_disk = $"../../../FakeDisk"
	if not fake_disk:
		append_text("[color=RED]Error: FakeDisk node not found.[/color]")
		newline()
		return

	# Check for AnimationPlayer on FakeDisk or its parent
	var animation_player = $"../../../AnimationPlayer"
	if not animation_player:
		animation_player = fake_disk.get_parent().get_node_or_null("AnimationPlayer")
	
	if animation_player and animation_player.has_animation("insert"):
		# Make FakeDisk visible if hidden
		if fake_disk:
			fake_disk.visible = true
		# Play the disk insertion animation
		animation_player.play("insert")
		# Wait for the animation to finish
		await animation_player.animation_finished
	else:
		append_text("[color=YELLOW]Warning: No insertion animation found, proceeding with insertion.[/color]")
		newline()

	# Update the file system with disk-specific content
	inserted_disk = disk_name
	inserted_disk_node = disk_node # Store original disk_node for eject
	
	# Always add disk data to /home
	var home_path_instance = get_path_instance("/home")
	if !home_path_instance.has(disk_name):
		if disk_data.has("files") and disk_data["files"] is Array:
			var disk_files = {}
			for file in disk_data["files"]:
				disk_files[file] = generate_file_content(disk_name, file, disk_data)
			home_path_instance[disk_name] = disk_files
		else:
			home_path_instance[disk_name] = {"data.txt": "Contents of " + disk_name}
		append_text("[color=GREEN]Disk '" + disk_name + "' inserted successfully.[/color]")
		newline()
		
		# Display disk information
		display_disk_info(disk_name, disk_data)
	else:
		append_text("[color=YELLOW]Warning: Disk already exists in /home.[/color]")
	newline()

	# Hide the disk node after insertion (optional, depending on your animation)
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
		return """WEIGHT_RANGE,LIQUID_A,LIQUID_B,LIQUID_C
130-139,31,51,18
130-139,28,49,23
130-139,33,53,14
140-145,19,62,19
140-145,21,58,21
140-145,18,64,18
146-150,11,38,51
146-150,9,42,49
146-150,12,36,52"""
	return "CSV_ERROR: Unable to generate table for " + disk_name + " " + filename

func display_disk_info(disk_name: String, disk_data: Dictionary) -> void:
	if disk_data.is_empty():
		return
		
	append_text("[color=CYAN]" + repeat_string("=", 40) + "[/color]")
	newline()
	append_text("[color=CYAN]ALIEN SPECIES DATABASE[/color]")
	newline()
	append_text("[color=CYAN]" + repeat_string("=", 40) + "[/color]")
	newline()
	
	if disk_data.has("species"):
		append_text("[color=YELLOW]Species:[/color] " + disk_data["species"])
		newline()
	
	if disk_data.has("weight_range"):
		append_text("[color=YELLOW]Weight Range:[/color] " + disk_data["weight_range"])
		newline()
	
	if disk_data.has("blood_types"):
		append_text("[color=YELLOW]Blood Types:[/color] " + str(disk_data["blood_types"]))
		newline()
	
	if disk_data.has("eye_colors"):
		append_text("[color=YELLOW]Eye Colors:[/color] " + str(disk_data["eye_colors"]))
		newline()
	
	if disk_data.has("files"):
		append_text("[color=YELLOW]Available Files:[/color]")
		newline()
		for file in disk_data["files"]:
			append_text("  - " + file)
			newline()
	
	append_text("[color=CYAN]" + repeat_string("=", 40) + "[/color]")
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
		return
	
	var commandData = commands[cmd]
	var expected_arg_count: int = commandData.function.get_argument_count()
	
	if expected_arg_count != args.size():
		push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
		append_text("[color=RED]" + tr("error.parameter_count_mismatch") + "[/color] " + tr("error.parameter_count_mismatch.expect_got") \
						% [str(expected_arg_count), args])
		pop()
		newline()
		return
	
	if cmd in ["mkdir", "touch", "rm", "mv", "cp", "nano"] and not check_permission():
		push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
		append_text("[color=RED]Insufficient permissions. Use 'auth' to gain access.[/color]")
		pop()
		newline()
		return
	
	commandData.function.callv(args)

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
			append_text("[color=CYAN]" + repeat_string("═", 79) + "[/color]")
			newline()
			append_text("[color=CYAN]                    ALIEN CLASSIFICATION TERMINAL - COMMAND REFERENCE[/color]")
			newline()
			append_text("[color=CYAN]" + repeat_string("═", 79) + "[/color]")
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
			append_text("[color=YELLOW]CLASSIFICATION:[/color]")
			newline()
			append_text("  [color=WHITE]classify[/color]   - Classify alien specimen")
			newline()
			append_text("             Usage: classify <class> <weight> <blood> <eye_color>")
			newline()
			append_text("             Example: classify 'Class 1' 145 'X-Positive' 'Yellow'")
			newline()
			newline()
			append_text("[color=YELLOW]UTILITY:[/color]")
			newline()
			append_text("  [color=WHITE]clear[/color]      - Clear the terminal screen")
			newline()
			append_text("  [color=WHITE]help[/color]       - Show this command reference")
			newline()
			newline()
			append_text("[color=CYAN]" + repeat_string("═", 79) + "[/color]")
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
			# Support ejecting any disk type
			var valid_disks = ["Disk1", "Disk2", "Disk3", "Disk4"]
			if inserted_disk == "" or not inserted_disk in valid_disks or not inserted_disk_node:
				append_text("[color=RED]Error: No disk inserted or invalid disk.[/color]")
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
				print("Exited computer mode") # Debug
			else:
				append_text("[color=RED]Error: Player not found.[/color]")
				newline()
				return

			var fake_disk = $"../../../FakeDisk"
			if not fake_disk:
				append_text("[color=RED]Error: FakeDisk node not found.[/color]")
				newline()
				return
			print("FakeDisk found, initial visible: ", fake_disk.visible) 

			var animation_player = $"../../../AnimationPlayer"
			if not animation_player:
				animation_player = fake_disk.get_parent().get_node_or_null("AnimationPlayer")
			if not animation_player:
				append_text("[color=RED]Error: AnimationPlayer not found.[/color]")
				newline()
				return
			print("AnimationPlayer found: ", animation_player)

			if animation_player.has_animation("eject"):
				fake_disk.visible = true
				print("FakeDisk set visible for eject animation") 
				animation_player.play("eject")
				await animation_player.animation_finished
				fake_disk.visible = false
				print("Eject animation finished, FakeDisk hidden")
			else:
				append_text("[color=YELLOW]Warning: No ejection animation found, proceeding with ejection.[/color]")
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
	add_command(
		"classify",
		func(species: String, weight: String, blood: String, eye: String):
			if not GameManager:
				append_text("[color=RED]Error: GameManager not available.[/color]")
				newline()
				return
			
			# Convert weight to int
			var weight_int = weight.to_int()
			if weight_int <= 0:
				append_text("[color=RED]Error: Invalid weight. Please enter a positive number.[/color]")
				newline()
				return
			
			# Perform classification
			var is_correct = GameManager.classify_alien(species, weight_int, blood, eye)
			
			if is_correct:
				append_text("[color=GREEN]CLASSIFICATION CORRECT![/color]")
				newline()
				append_text("The alien is indeed a " + species + ".")
				newline()
			else:
				append_text("[color=RED]CLASSIFICATION INCORRECT![/color]")
				newline()
				append_text("The alien is NOT a " + species + ". Check the data again!")
				newline()
				append_text("[color=YELLOW]Warning: Machine speed may have increased.[/color]")
				newline()
			
			# Show current game stats
			var stats = GameManager.get_classification_stats()
			append_text("[color=CYAN]Current Stats:[/color]")
			newline()
			append_text("Total Classifications: " + str(stats["total_classifications"]))
			newline()
			append_text("Correct: " + str(stats["correct_classifications"]))
			newline()
			append_text("Incorrect: " + str(stats["incorrect_classifications"]))
			newline()
			append_text("Machine Speed Level: " + str(stats["machine_speed_level"]))
			newline()
			append_text("Accuracy: " + str(stats["accuracy"]).substr(0, 5) + "%")
			newline(),
		self,
		"Classify an alien species",
		"Usage: classify <class> <weight> <blood_type> <eye_color>\nExample: classify 'Class 1' 145 'X-Positive' 'Yellow'"
	)
	# Other commands unchanged

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
	
	# Dynamically calculate column widths
	var column_widths = []
	for i in range(headers.size()):
		var max_len = headers[i].strip_edges().length()
		for row in data_rows:
			if i < row.size():
				max_len = max(max_len, row[i].strip_edges().length())
		column_widths.append(max(max_len + 2, 10))
	
	# Enter table mode and hide terminal UI
	_table_mode = true
	clear()
	_hide_terminal_ui()
	
	# Table title
	append_text("[color=CYAN]" + repeat_string("=", 80) + "[/color]")
	newline()
	append_text("[color=CYAN]          ALIEN SPECIES CLASSIFICATION DATA TABLE[/color]")
	newline()
	append_text("[color=CYAN]          FILE: " + filename.to_upper() + "[/color]")
	newline()
	append_text("[color=CYAN]          DISK: " + inserted_disk.to_upper() + "[/color]")
	newline()
	append_text("[color=CYAN]" + repeat_string("=", 80) + "[/color]")
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
	
	newline()
	append_text("[color=GRAY]" + repeat_string("=", 80) + "[/color]")
	newline()
	append_text("[color=ORANGE][b]LIQUID RATIOS TOTAL TO 100 FOR CLASSIFICATION[/b][/color]")
	newline()
	append_text("[color=GRAY]• High values (50+): [color=RED]Critical levels[/color]")
	newline()
	append_text("[color=GRAY]• Medium values (30-49): [color=YELLOW]Caution required[/color]")
	newline()
	append_text("[color=GRAY]• Low values (<30): [color=GREEN]Safe levels[/color]")
	newline()
	newline()
	append_text("[color=GRAY]Press [color=WHITE]ESC[/color] to return to terminal, or type [color=WHITE]'clear'[/color] to clear table[/color]")
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
	append_text("  classify - Classify alien species")
	newline()
	append_text("  eject    - Remove inserted disk")
	newline()
	append_text("[color=GRAY]Insert a data disk to begin analysis...[/color]")
	newline()
	newline()
