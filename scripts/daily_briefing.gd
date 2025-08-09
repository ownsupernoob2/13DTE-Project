extends Control

# Daily Briefing System - Shows objectives, threats, and special procedures

@onready var briefing_text: RichTextLabel = $Background/BriefingPanel/BriefingText
@onready var continue_button: Button = $Background/BriefingPanel/ContinueButton

var current_day: int = 1
var briefings: Dictionary = {}

signal briefing_completed()

func _ready() -> void:
	_setup_briefings()
	continue_button.pressed.connect(_on_continue_pressed)

func _setup_briefings() -> void:
	briefings = {
		1: {
			"title": "DAY 1 - ORIENTATION",
			"content": """[color=cyan]WELCOME TO FACILITY ALPHA-7[/color]

[color=yellow]OBJECTIVES:[/color]
• Learn basic alien classification procedures
• Process 10 specimens using computer database
• Sedate aliens using lever system (A/B/C ratios)
• Scan for biological data confirmation

[color=red]THREATS:[/color] Minimal - Standard specimens only

[color=green]EQUIPMENT:[/color] All systems operational"""
		},
		2: {
			"title": "DAY 2 - INCREASED VOLUME", 
			"content": """[color=cyan]FACILITY ALPHA-7 - DAY 2[/color]

[color=yellow]OBJECTIVES:[/color]
• Process 15 specimens (increased quota)
• Watch for Class 3/4 specimens - more dangerous
• Maintain 85% accuracy rating

[color=red]THREATS:[/color] Low - Some resistance to sedation expected

[color=green]EQUIPMENT:[/color] Scanner sensitivity increased"""
		},
		3: {
			"title": "DAY 3 - CONTAMINATION PROTOCOLS",
			"content": """[color=cyan]FACILITY ALPHA-7 - DAY 3[/color]

[color=yellow]OBJECTIVES:[/color]
• Process 20 specimens
• Some may require decontamination procedures
• Use UV scanner for contaminated specimens

[color=red]THREATS:[/color] Medium - Biological contamination possible

[color=green]EQUIPMENT:[/color] UV decontamination scanner available"""
		},
		4: {
			"title": "DAY 4 - SYSTEM MALFUNCTIONS",
			"content": """[color=cyan]FACILITY ALPHA-7 - DAY 4[/color]

[color=yellow]OBJECTIVES:[/color]
• Process 18 specimens
• Equipment may malfunction randomly
• Recalibrate systems when necessary

[color=red]THREATS:[/color] Medium - False scanner readings possible

[color=green]EQUIPMENT:[/color] All systems - reliability 75%"""
		},
		5: {
			"title": "DAY 5 - PSYCHOLOGICAL EVALUATION",
			"content": """[color=cyan]FACILITY ALPHA-7 - DAY 5[/color]

[color=yellow]OBJECTIVES:[/color]
• Process 22 specimens
• Some require psychological evaluation before classification
• Use neural probe scanner for mental assessment

[color=red]THREATS:[/color] High - Psychic interference possible

[color=green]EQUIPMENT:[/color] Neural probe scanner available"""
		},
		6: {
			"title": "DAY 6 - HYBRID SPECIMENS",
			"content": """[color=cyan]FACILITY ALPHA-7 - DAY 6[/color]

[color=yellow]OBJECTIVES:[/color]
• Process 25 specimens
• Hybrid species detected - mixed characteristics
• Cross-reference database for hybrid protocols

[color=red]THREATS:[/color] High - Unpredictable hybrid behavior

[color=green]EQUIPMENT:[/color] Deep tissue scanner required for hybrids"""
		},
		7: {
			"title": "DAY 7 - CRITICAL PHASE",
			"content": """[color=cyan]FACILITY ALPHA-7 - DAY 7[/color]

[color=yellow]OBJECTIVES:[/color]
• Process 30 specimens
• Maximum security protocols active
• All quarantine levels may be required

[color=red]THREATS:[/color] MAXIMUM - All known complications possible

[color=green]EQUIPMENT:[/color] All scanner types available"""
		}
	}

func show_daily_briefing(day: int) -> void:
	current_day = day
	visible = true
	
	var briefing = briefings.get(day, briefings[7])  # Use day 7 format for days beyond 7
	
	if day > 7:
		briefing = {
			"title": "DAY " + str(day) + " - SURVIVAL MODE",
			"content": """[color=cyan]FACILITY ALPHA-7 - DAY """ + str(day) + """[/color]

[color=yellow]OBJECTIVES:[/color]
• Process """ + str(25 + (day - 7) * 5) + """ specimens
• All threat levels active
• Maintain facility integrity at all costs

[color=red]THREATS:[/color] EXTREME - Maximum difficulty

[color=green]EQUIPMENT:[/color] All systems - condition unknown"""
		}
	
	briefing_text.text = "[center][font_size=48]" + briefing.title + "[/font_size][/center]\n\n" + briefing.content

func _on_continue_pressed() -> void:
	visible = false
	briefing_completed.emit()
