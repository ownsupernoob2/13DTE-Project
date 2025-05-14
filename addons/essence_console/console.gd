extends RichTextLabel

# Base
@export var console_size: Vector2 = Vector2(100,30)
@export var USER_Name: String = "@USER"
@export var ShowTextArt: bool = true
@export var CanInput: bool = false
var CurrentMode: String = ""

# Data
@export var commands: Dictionary = {}
@export var fileDirectory: Dictionary = {"home":{},"config":{}}
var current_path: String = "/home"

# Setup text art
var TextArt: Array[String] = [
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
var TextArtThin: Array[String] = [
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
	"┖┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┚"
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
var _start_up: int = 0
var _just_enter: bool = false
var _PrefixText: String = ""

# History
var _send_history: Array[String] = []
var _current_history: int = -1
var _last_input: String = ""

# Edit mode
var current_file: String = ""
var current_file_type: String = "Text"
var _just_save: String = ""

@export var SetLocaleToEng: bool = false

func _ready() -> void:
	if SetLocaleToEng:
		TranslationServer.set_locale("en_US")
	size = Vector2(console_size.x * 12.5, console_size.y * 23)
	_built_in_command_init()
	add_child(_flash_timer)
	text = ""
	_flash_timer.set_one_shot(true)
	_flash_timer.start(1)
	# Connect to player signal
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("interact_with_computer", _on_player_interact)

func _on_player_interact():
	CanInput = true
	_flash = true
	append_current_input_string()

func _process(delta: float) -> void:
	set_prefix()
	if _flash_timer.time_left == 0:
		if _start_up == 0 and ShowTextArt:
			for i in(console_size.y / 2 + 7):
				if i < console_size.y / 2 - 7:
					newline()
				else:
					push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
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
			if CanInput:
				append_current_input_string()
			_flash_timer.start()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and CanInput:
		match event.as_text():
			# Main character
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
			# BBCode
			"BracketLeft": insert_character("[")
			"BracketRight": insert_character("]")
			"Slash","Kp Divide": insert_character("/")
			# Other character
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
			# Special action
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
			# File edit
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
			# Unpatched
			_: print(event.as_text())
		CurrentInputString_escaped = CurrentInputString.replace("[", "[lb]").replace("\n", "\u2B92\n")
		if CanInput:
			append_current_input_string()
		_just_enter = false

func append_current_input_string(enter: bool = false) -> void:
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

func insert_character(character: String) -> void:
	scroll_to_line(get_line_count())
	_just_save = ""
	_current_line = 0
	if _current_cursor_pos == 0:
		CurrentInputString += character
	elif _current_cursor_pos > 0:
		CurrentInputString = CurrentInputString.insert(CurrentInputString.length() -_current_cursor_pos,character)

func scroll_page(down: bool = true) -> void:
	if down:
		if _current_line > 0:
			_current_line -= 1
	elif _current_line < get_line_count() - console_size.y:
		_current_line += 1
	scroll_to_line(get_line_count() - console_size.y - _current_line)

func append_history(up: bool = true) -> void:
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
			append_text("Error: Undefined mode")
			CurrentMode = ""

func process(command):
	command = command.replace("\\,", "[comma]")
	command = command.replace("\\(", "[lp]")
	command = command.replace("\\)", "[rp]")
	if !commands.keys().has(command.get_slice("(",0)):
		push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
		append_text("[color=RED]Command not found: [/color] " + command.get_slice("(",0))
		pop()
		newline()
	else:
		var commandData = commands[command.get_slice("(",0)]
		var argu_in: Array[String] = []
		var argu_in_unesc: Array[String] = []
		if command.contains("("):
			argu_in.append_array(command.trim_prefix(command.get_slice("(",0)+"(").trim_suffix(")").split(","))
			for i in argu_in:
				i = i.replace("[comma]", ",")
				i = i.replace("[lp]", "(")
				i = i.replace("[rp]", ")")
				argu_in_unesc.append(i)
		if commandData.function.get_argument_count() != argu_in.size():
			push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
			append_text("[color=RED]Parameter count mismatch: [/color] Expected " + str(commandData.function.get_argument_count()) + ", got " + str(argu_in_unesc))
			pop()
		else:
			commandData.function.callv(argu_in_unesc)

func add_command(id: String, function: Callable, functionInstance: Object, helpText: String = "", helpDetail: String = ""):
	commands[id] = EC_CommandClass.new(id, function, functionInstance, helpText, helpDetail)

func _built_in_command_init():
	# Help command
	add_command(
		"help",
		func(id: String):
			if id == "":
				var command_list = commands.keys()
				command_list.sort()
				append_text(command_list.join(", "))
			elif commands.keys().has(id):
				append_text(commands[id].helpDetail)
			else:
				append_text("[color=RED]Command not found: [/color] " + id)
			pop_all()
			newline(),
		self,
		"Show available commands or help for a specific command",
		"help: Show all commands\nhelp(command): Show detailed help for 'command'"
	)
	# Clear screen
	add_command(
		"clear",
		func():
			clear()
			return,
		self,
		"Clear the terminal screen",
		"clear: Clear the terminal display"
	)
	# Echo input
	add_command(
		"echo",
		func(input: String):
			append_text(input)
			pop_all(),
		self,
		"Display a line of text",
		"echo(text): Print 'text' to the terminal"
	)
	# Print working directory
	add_command(
		"pwd",
		func():
			var path_instance = get_path_instance(current_path)
			if !path_instance.has(null):
				append_text(current_path)
			else:
				append_text(path_instance.get(null))
				current_path = "/home"
			pop_all(),
		self,
		"Print current working directory",
		"pwd: Display the current directory path"
	)
	# Show current user
	add_command(
		"whoami",
		func():
			append_text(USER_Name)
			pop_all(),
		self,
		"Print the current user name",
		"whoami: Display the current user"
	)
	# List directory contents
	add_command(
		"ls",
		func():
			var path_instance = get_path_instance(current_path)
			if !path_instance.has(null):
				for i in path_instance:
					var icon = "\uFFFD"
					if path_instance[i] == null:
						icon = "\u2613"
					elif path_instance[i] is String:
						if path_instance[i] != "":
							icon = "\U01F5CE"
						else:
							icon = "\U01F5CB"
					elif path_instance[i] is Dictionary:
						if path_instance[i].is_empty():
							icon = "\U01F4C2"
						else:
							icon = "\U01F5C1"
					elif path_instance[i] is bool:
						if path_instance[i]:
							icon = "\u2705"
						else:
							icon = "\u274E"
					elif path_instance[i] is int or path_instance[i] is float:
						if path_instance[i] == 0:
							icon = "\U01F5D2"
						else:
							icon = "\U01F5D3"
					elif path_instance[i] is StringName:
						icon = "\U01F524"
					elif path_instance[i] is NodePath:
						icon = "\U01F517"
					elif path_instance[i] is Object:
						match path_instance[i].get_class():
							"GDScript":
								icon = "\U01F4C3"
							_:
								icon = "\U01F4E6"
					elif path_instance[i] is Array:
						icon = "\U01F4DA"
					elif path_instance[i] is PackedByteArray\
					or path_instance[i] is PackedInt32Array\
					or path_instance[i] is PackedInt64Array\
					or path_instance[i] is PackedFloat32Array\
					or path_instance[i] is PackedFloat64Array:
						if path_instance[i].is_empty():
							icon = "\U01F5C7"
						else:
							icon = "\U01F5CA"
					elif path_instance[i] is PackedStringArray:
						if path_instance[i].is_empty():
							icon = "\U01F5CD"
						else:
							icon = "\U01F5D0"
					if i is String:
						if i.is_valid_filename():
							append_text(icon + i)
						else:
							append_text("[color=RED]" + icon + i + "[/color]")
					else:
						append_text("[color=RED]" + icon + str(i) + "[/color]")
					pop_all()
					newline()
			else:
				append_text(path_instance.get(null))
				current_path = "/home"
			pop_all(),
		self,
		"List directory contents",
		"ls: Show files and directories in the current directory"
	)
	add_command(
		"dir",
		func():
			var path_instance = get_path_instance(current_path)
			if !path_instance.has(null):
				for i in path_instance:
					var icon = "\uFFFD"
					if path_instance[i] == null:
						icon = "\u2613"
					elif path_instance[i] is String:
						if path_instance[i] != "":
							icon = "\U01F5CE"
						else:
							icon = "\U01F5CB"
					elif path_instance[i] is Dictionary:
						if path_instance[i].is_empty():
							icon = "\U01F4C2"
						else:
							icon = "\U01F5C1"
					elif path_instance[i] is bool:
						if path_instance[i]:
							icon = "\u2705"
						else:
							icon = "\u274E"
					elif path_instance[i] is int or path_instance[i] is float:
						if path_instance[i] == 0:
							icon = "\U01F5D2"
						else:
							icon = "\U01F5D3"
					elif path_instance[i] is StringName:
						icon = "\U01F524"
					elif path_instance[i] is NodePath:
						icon = "\U01F517"
					elif path_instance[i] is Object:
						match path_instance[i].get_class():
							"GDScript":
								icon = "\U01F4C3"
							_:
								icon = "\U01F4E6"
					elif path_instance[i] is Array:
						icon = "\U01F4DA"
					elif path_instance[i] is PackedByteArray\
					or path_instance[i] is PackedInt32Array\
					or path_instance[i] is PackedInt64Array\
					or path_instance[i] is PackedFloat32Array\
					or path_instance[i] is PackedFloat64Array:
						if path_instance[i].is_empty():
							icon = "\U01F5C7"
						else:
							icon = "\U01F5CA"
					elif path_instance[i] is PackedStringArray:
						if path_instance[i].is_empty():
							icon = "\U01F5CD"
						else:
							icon = "\U01F5D0"
					if i is String:
						if i.is_valid_filename():
							append_text(icon + i)
						else:
							append_text("[color=RED]" + icon + i + "[/color]")
					else:
						append_text("[color=RED]" + icon + str(i) + "[/color]")
					pop_all()
					newline()
			else:
				append_text(path_instance.get(null))
				current_path = "/home"
			pop_all(),
		self,
		"List directory contents",
		"dir: Show files and directories in the current directory"
	)
	# Change directory
	add_command(
		"cd",
		func(path: String):
			if !get_path_instance(path,true).has(null):
				pass
			else:
				append_text(get_path_instance(path).get(null))
			pop_all(),
		self,
		"Change current directory",
		"cd(path): Change to directory 'path'"
	)
	add_command(
		"changeDir",
		func(path: String):
			if !get_path_instance(path,true).has(null):
				pass
			else:
				append_text(get_path_instance(path).get(null))
			pop_all(),
		self,
		"Change current directory",
		"changeDir(path): Change to directory 'path'"
	)
	# Make directory
	add_command(
		"mkdir",
		func(folder_name: String):
			if folder_name.is_valid_filename():
				var path_instance = get_path_instance(current_path)
				if !path_instance.has(null):
					if !path_instance.has(folder_name):
						path_instance.get_or_add(folder_name,{})
					else:
						append_text("Error: " + folder_name + " already exists")
				else:
					append_text(path_instance.get(null))
			else:
				append_text("[color=RED]Invalid filename: [/color] " + folder_name + " (Avoid: :/\\?*|%<>")
			pop_all(),
		self,
		"Create a new directory",
		"mkdir(name): Create directory 'name'"
	)
	add_command(
		"makeDir",
		func(folder_name: String):
			if folder_name.is_valid_filename():
				var path_instance = get_path_instance(current_path)
				if !path_instance.has(null):
					if !path_instance.has(folder_name):
						path_instance.get_or_add(folder_name,{})
					else:
						append_text("Error: " + folder_name + " already exists")
				else:
					append_text(path_instance.get(null))
			else:
				append_text("[color=RED]Invalid filename: [/color] " + folder_name + " (Avoid: :/\\?*|%<>")
			pop_all(),
		self,
		"Create a new directory",
		"makeDir(name): Create directory 'name'"
	)
	# Create file
	add_command(
		"makeFile",
		func(file_name: String, type: String, content: String):
			if file_name.is_valid_filename():
				var path_instance = get_path_instance(current_path)
				if !path_instance.has(null):
					if !path_instance.has(file_name):
						path_instance.get_or_add(file_name,"")
						match_file_type(type,content,true,true,path_instance,file_name)
					else:
						append_text("Error: " + file_name + " already exists")
				else:
					append_text(path_instance.get(null))
			else:
				append_text("[color=RED]Invalid filename: [/color] " + file_name + " (Avoid: :/\\?*|%<>")
			pop_all(),
		self,
		"Create a new file",
		"makeFile(name,type,content): Create file 'name' of 'type' with 'content'"
	)
	# Read file
	add_command(
		"cat",
		func(file_name: String):
			var path_instance = get_path_instance(current_path)
			if !path_instance.has(null):
				if path_instance.has(file_name):
					append_text(str(path_instance[file_name]))
				else:
					append_text("Error: " + file_name + " does not exist")
				else:
					append_text(path_instance.get(null))
			pop_all(),
		self,
		"Display file contents",
		"cat(file): Print contents of 'file'"
	)
	add_command(
		"read",
		func(file_name: String):
			var path_instance = get_path_instance(current_path)
			if !path_instance.has(null):
				if path_instance.has(file_name):
					append_text(str(path_instance[file_name]))
				else:
					append_text("Error: " + file_name + " does not exist")
				else:
					append_text(path_instance.get(null))
			pop_all(),
		self,
		"Display file contents",
		"read(file): Print contents of 'file'"
	)
	# Remove file or directory
	add_command(
		"rm",
		func(file_name: String):
			var path_instance = get_path_instance(current_path)
			if !path_instance.has(null):
				if path_instance.has(file_name):
					path_instance.erase(file_name)
				else:
					append_text("Error: " + file_name + " does not exist")
			else:
				append_text(path_instance.get(null))
			pop_all(),
		self,
		"Remove a file or directory",
		"rm(name): Delete file or directory 'name'"
	)
	add_command(
		"remove",
		func(file_name: String):
			var path_instance = get_path_instance(current_path)
			if !path_instance.has(null):
				if path_instance.has(file_name):
					path_instance.erase(file_name)
				else:
					append_text("Error: " + file_name + " does not exist")
			else:
				append_text(path_instance.get(null))
			pop_all(),
		self,
		"Remove a file or directory",
		"remove(name): Delete file or directory 'name'"
	)
	# Rename file or directory
	add_command(
		"rename",
		func(file_name: String, to_name: String):
			var path_instance = get_path_instance(current_path)
			if !path_instance.has(null):
				if path_instance.has(file_name):
					if to_name.is_valid_filename():
						if !path_instance.has(to_name):
							path_instance.get_or_add(to_name,path_instance.get(file_name).duplicate(true))
							path_instance.erase(file_name)
						else:
							append_text("Error: " + to_name + " already exists")
					else:
						append_text("[color=RED]Invalid filename: [/color] " + to_name + " (Avoid: :/\\?*|%<>")
				else:
					append_text("Error: " + file_name + " does not exist")
			else:
				append_text(path_instance.get(null))
			pop_all(),
		self,
		"Rename a file or directory",
		"rename(old,new): Rename 'old' to 'new'"
	)
	# Copy file or directory
	add_command(
		"cp",
		func(file_name: String, to_path: String, to_name: String):
			var path_instance = get_path_instance(current_path)
			var result_path_instance = get_path_instance(to_path)
			if !path_instance.has(null):
				if path_instance.has(file_name):
					if !result_path_instance.has(null):
						if to_name == "":
							to_name = file_name
						if to_name.is_valid_filename():
							if !result_path_instance.has(to_name):
								result_path_instance.get_or_add(to_name,path_instance.get(file_name).duplicate(true))
							else:
								append_text("Error: " + to_name + " already exists")
						else:
							append_text("[color=RED]Invalid filename: [/color] " + to_name + " (Avoid: :/\\?*|%<>")
					else:
						append_text(result_path_instance.get(null))
				else:
					append_text("Error: " + file_name + " does not exist")
			else:
				append_text(path_instance.get(null))
			pop_all(),
		self,
		"Copy a file or directory",
		"cp(src,dest,newname): Copy 'src' to 'dest' as 'newname' (optional)"
	)
	add_command(
		"copy",
		func(file_name: String, to_path: String, to_name: String):
			var path_instance = get_path_instance(current_path)
			var result_path_instance = get_path_instance(to_path)
			if !path_instance.has(null):
				if path_instance.has(file_name):
					if !result_path_instance.has(null):
						if to_name == "":
							to_name = file_name
						if to_name.is_valid_filename():
							if !result_path_instance.has(to_name):
								result_path_instance.get_or_add(to_name,path_instance.get(file_name).duplicate(true))
							else:
								append_text("Error: " + to_name + " already exists")
						else:
							append_text("[color=RED]Invalid filename: [/color] " + to_name + " (Avoid: :/\\?*|%<>")
					else:
						append_text(result_path_instance.get(null))
				else:
					append_text("Error: " + file_name + " does not exist")
			else:
				append_text(path_instance.get(null))
			pop_all(),
		self,
		"Copy a file or directory",
		"copy(src,dest,newname): Copy 'src' to 'dest' as 'newname' (optional)"
	)
	# Move file or directory
	add_command(
		"mv",
		func(file_name: String, to_path: String):
			var path_instance = get_path_instance(current_path)
			var result_path_instance = get_path_instance(to_path)
			if !path_instance.has(null):
				if path_instance.has(file_name):
					if !result_path_instance.has(null):
						if !result_path_instance.has(file_name):
							result_path_instance.get_or_add(file_name,path_instance.get(file_name).duplicate(true))
							path_instance.erase(file_name)
						else:
							append_text("Error: " + file_name + " already exists")
					else:
						append_text(result_path_instance.get(null))
				else:
					append_text("Error: " + file_name + " does not exist")
			else:
				append_text(path_instance.get(null))
			pop_all(),
		self,
		"Move a file or directory",
		"mv(src,dest): Move 'src' to 'dest'"
	)
	add_command(
		"move",
		func(file_name: String, to_path: String):
			var path_instance = get_path_instance(current_path)
			var result_path_instance = get_path_instance(to_path)
			if !path_instance.has(null):
				if path_instance.has(file_name):
					if !result_path_instance.has(null):
						if !result_path_instance.has(file_name):
							result_path_instance.get_or_add(file_name,path_instance.get(file_name).duplicate(true))
							path_instance.erase(file_name)
						else:
							append_text("Error: " + file_name + " already exists")
					else:
						append_text(result_path_instance.get(null))
				else:
					append_text("Error: " + file_name + " does not exist")
			else:
				append_text(path_instance.get(null))
			pop_all(),
		self,
		"Move a file or directory",
		"move(src,dest): Move 'src' to 'dest'"
	)
	# Edit file
	add_command(
		"edit",
		func(file_name: String):
			var path_instance = get_path_instance(current_path)
			if !path_instance.has(null):
				if path_instance.has(file_name):
					if path_instance[file_name] is String:
						current_file_type = "Text"
					elif path_instance[file_name] is int or path_instance[file_name] is float:
						current_file_type = "Number"
					elif path_instance[file_name] is bool:
						current_file_type = "Boolean"
					else:
						append_text("Error: Cannot edit this file type")
						pop_all()
						return
					CurrentMode = "Edit"
					current_file = file_name
					CurrentInputString = str(path_instance[file_name])
				else:
					append_text("Error: " + file_name + " does not exist")
			else:
				append_text(path_instance.get(null))
			pop_all(),
		self,
		"Edit a file",
		"edit(file): Open 'file' for editing (Ctrl+S to save, Ctrl+X to exit)"
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
				return {null: "Error: " + path + " does not exist"}
			elif current_path_instance.get(i) is Dictionary:
				current_path_instance = current_path_instance[i]
			else:
				return {null: "Error: " + path + " is not a directory"}
	if goto:
		current_path = ""
		for i in path_array:
			if i != "" and i != ".":
				current_path += "/" + i
	return current_path_instance

func match_file_type(type: String = "Text", content: String = "", append_error: bool = false, apply: bool = false, path: Dictionary = get_path_instance(current_path), file: String = current_file) -> bool:
	match type:
		"","Text":
			if content != "":
				if apply:
					path[file] = content
				return true
			else:
				if apply:
					path[file] = ""
				return false
		"Number":
			if content != "":
				if content.is_valid_int():
					if apply:
						path[file] = int(content)
					return true
				elif content.is_valid_float():
					if apply:
						path[file] = float(content)
					return true
				else:
					if append_error:
						append_text("[color=RED]Type mismatch: [/color] Expected number, got " + content + ", using 0")
					if apply:
						path[file] = 0
				return false
			else:
				if apply:
					path[file] = 0
				return false
		"Boolean":
			if content != "":
				if content == "true":
					if apply:
						path[file] = true
					return true
				elif content == "false":
					if apply:
						path[file] = false
					return true
				else:
					if append_error:
						append_text("[color=RED]Type mismatch: [/color] Expected boolean, got " + content + ", using false")
					if apply:
						path[file] = false
					return false
			else:
				if apply:
					path[file] = false
				return false
		_:
			if append_error:
				append_text("Error: Unknown file type: " + type)
			return false
