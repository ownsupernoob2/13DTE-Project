extends RichTextLabel

# Configuration
@export var console_size: Vector2 = Vector2(100, 30)
@export var user_name: String = "@user"
@export var can_input: bool = false
var current_mode: String = "Default"
var current_path: String = "/home"
var file_system: Dictionary = {
	"/home": {
		"readme.txt": "Welcome to the terminal emulator!\nType 'help' for a list of commands.",
		"docs": {
			"guide.txt": "This is a user guide.\nUse 'ls' to list files, 'cd' to navigate, 'cat' to read files.",
			"tutorial": {
				"step1.txt": "Step 1: Use 'pwd' to see your current directory."
			}
		}
	},
	"/config": {
		"settings.conf": "theme=dark\nversion=1.0",
		"logs": {
			"system.log": "System started successfully."
		}
	}
}
var commands: Dictionary = {}

# ASCII art for startup
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
var startup_done: bool = false
var is_powered_on: bool = false
var art_timer: Timer = Timer.new()

# Input handling
var input_string: String = ""
var cursor_pos: int = 0
var history: Array[String] = []
var history_index: int = -1
var last_input: String = ""
var flash: bool = false
var flash_timer: Timer = Timer.new()
var display_text: String = ""

# Printable ASCII characters
const PRINTABLE_ASCII: String = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"

func _ready() -> void:
	size = Vector2(console_size.x * 12.5, console_size.y * 23)
	add_child(flash_timer)
	add_child(art_timer)
	flash_timer.set_one_shot(true)
	art_timer.set_one_shot(true)
	flash_timer.start(1)
	_setup_commands()
	visible = false
	can_input = false
	# Debug: Log initial file system
	print("Initial file system: ", file_system)

func power_on() -> void:
	if not is_powered_on:
		is_powered_on = true
		visible = true
		startup_done = false
		_display_ascii_art()
		can_input = true
		flash_timer.start(0.5)
		art_timer.start(2.0)
		# Debug: Log power on
		print("Terminal powered on")

func _process(_delta: float) -> void:
	if art_timer.time_left == 0 and not startup_done and is_powered_on:
		startup_done = true
		display_text = ""
		_update_display()
	if flash_timer.time_left == 0 and is_powered_on:
		flash = !flash
		_update_display()
		flash_timer.start(0.5)

func _display_ascii_art() -> void:
	display_text = ""
	if console_size.x >= 63:
		for line in TextArt:
			display_text += _center_text(line) + "\n"
	else:
		display_text = "[color=RED]Console too small for ASCII art[/color]\n"
	text = display_text
	# Debug: Log ASCII art display
	print("Displaying ASCII art: ", display_text)

func _center_text(line: String) -> String:
	var console_width = int(console_size.x)
	var line_length = line.length()
	var padding = max(0, (console_width - line_length) / 2)
	return " ".repeat(padding) + line

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and can_input:
		var key = event.as_text()
		# Debug: Log key press
		print("Key pressed: ", key)
		match key:
			_ when key.length() == 1 and PRINTABLE_ASCII.contains(key):
				_insert_char(key)
			"Space":
				_insert_char(" ")
			"Slash":
				_insert_char("/")
			"Minus":
				_insert_char("-")
			"Period":
				_insert_char(".")
			"Backspace":
				if cursor_pos < input_string.length():
					input_string = input_string.erase(input_string.length() - cursor_pos - 1, 1)
			"Enter":
				if current_mode == "Default":
					_execute_command()
			"Left":
				if cursor_pos < input_string.length():
					cursor_pos += 1
			"Right":
				if cursor_pos > 0:
					cursor_pos -= 1
			"Up":
				if current_mode == "Default":
					_cycle_history(true)
			"Down":
				if current_mode == "Default":
					_cycle_history(false)
		_update_display()

func _insert_char(char: String) -> void:
	if cursor_pos == 0:
		input_string += char
	else:
		input_string = input_string.insert(input_string.length() - cursor_pos, char)

func _cycle_history(up: bool) -> void:
	if history.is_empty():
		return
	if up:
		if history_index == -1:
			last_input = input_string
			history_index = history.size() - 1
		elif history_index > 0:
			history_index -= 1
	else:
		if history_index < history.size() - 1:
			history_index += 1
		else:
			history_index = -1
			input_string = last_input
			_update_display()
			return
	if history_index >= 0:
		input_string = history[history_index]
	cursor_pos = 0
	_update_display()

func _update_display() -> void:
	var current_display = display_text
	if current_mode == "Default":
		current_display += _get_prompt()
		var display_input = input_string
		if flash:
			if cursor_pos == 0:
				display_input += "_"
			else:
				display_input = display_input.insert(input_string.length() - cursor_pos, "[color=WHITE]_[/color]")
		current_display += display_input
	text = current_display
	# Debug: Log display update
	print("Display updated: ", current_display)

func _get_prompt() -> String:
	var path = "~" if current_path == "/home" else current_path
	return "[color=BLUE]" + user_name + "[/color]:" + path + "$ "

func _execute_command() -> void:
	if input_string.strip_edges() == "":
		display_text += "\n"
		_update_display()
		return
	history.append(input_string)
	history_index = -1
	display_text += _get_prompt() + input_string + "\n"
	var parts = input_string.split(" ", false)
	var cmd = parts[0].to_lower()
	parts.remove_at(0)
	# Debug: Log command execution
	print("Executing command: ", cmd, " with args: ", parts)
	if commands.has(cmd):
		var output = commands[cmd].callv(parts)
		# Debug: Log command output
		print("Command output: ", output)
		# Append output if it's a string, even if empty
		if output is String:
			display_text += output
			if output != "" and not output.ends_with("\n"):
				display_text += "\n"
		else:
			display_text += "[color=RED]Error: Invalid command output[/color]\n"
	else:
		display_text += "[color=RED]Command not found: " + cmd + "[/color]\n"
	input_string = ""
	cursor_pos = 0
	_update_display()

func _setup_commands() -> void:
	commands = {
		"help": func(_args: Array[String]) -> String:
			var output = "Available commands:\n"
			for cmd in commands.keys():
				output += cmd + "\n"
			# Debug: Log help output
			print("Help command output: ", output)
			return output,
		"clear": func(_args: Array[String]) -> String:
			display_text = ""
			# Debug: Log clear
			print("Clear command executed")
			return "",
		"echo": func(args: Array[String]) -> String:
			var output = _array_to_string(args, " ")
			# Debug: Log echo output
			print("Echo command output: ", output)
			return output,
		"pwd": func(_args: Array[String]) -> String:
			# Debug: Log pwd output
			print("PWD command output: ", current_path)
			return current_path,
		"ls": func(_args: Array[String]) -> String:
			var dir = _get_dir(current_path)
			var output = ""
			if dir is Dictionary:
				for item in dir.keys():
					var icon = "📁" if dir[item] is Dictionary else "📄"
					output += icon + " " + item + "\n"
			else:
				output = "[color=RED]Error: Invalid directory[/color]\n"
			# Debug: Log ls output
			print("LS command output: ", output)
			return output,
		"cd": func(args: Array[String]) -> String:
			if args.is_empty():
				current_path = "/home"
				# Debug: Log cd
				print("CD to /home")
				return ""
			var new_path = _resolve_path(args[0])
			var dir = _get_dir(new_path)
			if dir is Dictionary:
				current_path = new_path
				# Debug: Log cd
				print("CD to ", new_path)
				return ""
			# Debug: Log cd error
			print("CD failed: No such directory: ", args[0])
			return "[color=RED]No such directory: " + args[0] + "[/color]",
		"cat": func(args: Array[String]) -> String:
			if args.is_empty():
				# Debug: Log cat error
				print("Cat failed: missing operand")
				return "[color=RED]cat: missing operand[/color]"
			var dir = _get_dir(current_path)
			if dir is Dictionary and dir.has(args[0]) and dir[args[0]] is String:
				# Debug: Log cat output
				print("Cat command output: ", dir[args[0]])
				return dir[args[0]]
			# Debug: Log cat error
			print("Cat failed: No such file or not readable: ", args[0])
			return "[color=RED]No such file or not readable: " + args[0] + "[/color]",
		"whoami": func(_args: Array[String]) -> String:
			# Debug: Log whoami output
			print("Whoami command output: ", user_name)
			return user_name
	}

func _array_to_string(arr: Array[String], separator: String) -> String:
	var result = ""
	for i in range(arr.size()):
		result += arr[i]
		if i < arr.size() - 1:
			result += separator
	return result

func _resolve_path(path: String) -> String:
	if path.begins_with("/"):
		return path
	var resolved = current_path + "/" + path
	var parts = resolved.split("/", false)
	var result: Array[String] = []
	for part in parts:
		if part == "..":
			if not result.is_empty():
				result.pop_back()
		elif part != ".":
			result.append(part)
	return "/" + _array_to_string(result, "/")

func _get_dir(path: String) -> Variant:
	var current = file_system
	var parts = path.split("/", false)
	for part in parts:
		if current.has(part) and current[part] is Dictionary:
			current = current[part]
		else:
			# Debug: Log directory failure
			print("Failed to find directory: ", path, " at part: ", part)
			return null
	# Debug: Log directory found
	print("Directory found: ", path, " contents: ", current)
	return current
