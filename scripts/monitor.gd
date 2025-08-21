extends Control

@onready var game_manager = GameManager
@onready var label = $RichTextLabel

func _ready():
	show_instructions()
	update_monitor()

func show_instructions():
	label.clear()
	label.append_text("[color=CYAN]ALIEN CLASSIFICATION MONITOR[/color]\n")
	label.append_text("[color=YELLOW]Press Left Arrow to reject (incorrect) or Right Arrow to accept (correct).\nCheck console data to confirm viability.\nAggression increases by 1 for mistakes (game over at 3).\n[/color]\n")

func update_monitor():
	var alien = game_manager.current_alien
	label.append_text("[color=WHITE]Species:[/color] " + alien["species"] + "\n")
	label.append_text("[color=WHITE]Weight:[/color] " + str(alien["weight"]) + " kg\n")
	label.append_text("[color=WHITE]Eye Color:[/color] " + alien["eye_color"] + "\n")
	label.append_text("[color=WHITE]Blood Type:[/color] " + alien["blood"] + "\n")
	label.append_text("[color=WHITE]Aggression Level:[/color] " + str(game_manager.aggression_level) + "/" + str(game_manager.max_aggression) + "\n")

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_LEFT:
			process_classification(false)
		elif event.keycode == KEY_RIGHT:
			process_classification(true)

func process_classification(accepted: bool):
	var valid = game_manager.validate_alien()
	if accepted == valid:
		label.append_text("[color=GREEN]Correct! Alien classified properly.\n[/color]")
		game_manager.generate_alien()
		update_monitor()
	else:
		label.append_text("[color=RED]Incorrect! Aggression increased.\n[/color]")
		var game_over = game_manager.increase_aggression()
		if game_over:
			label.append_text("[color=RED]GAME OVER! Press R to restart.\n[/color]")
		else:
			game_manager.generate_alien()
			update_monitor()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		game_manager.reset_game()
		label.clear()
		show_instructions()
		update_monitor()
