extends RichTextLabel

# New Monitor System - Simple and Reliable
# Displays: Start Message -> Processing -> Alien Information

# Configuration
@export var console_size: Vector2 = Vector2(100, 30)

# Display states
enum DisplayState {
	START_MESSAGE,
	PROCESSING,
	ALIEN_INFO
}

var current_state: DisplayState = DisplayState.START_MESSAGE
var alien_data: Dictionary = {}

# Species data for liquid ratio calculations
var species_data: Dictionary = {
	"Class 1": {
		"eye_colors": ["Yellow", "Orange", "White"],
		"weight_range": [120, 160],
		"blood_types": ["X-Positive", "O-Negative", "Z-Flux"]
	},
	"Class 2": {
		"eye_colors": ["Green", "Cyan", "Amber"],
		"weight_range": [75, 125],
		"blood_types": ["A-Neutral", "B-Static"]
	},
	"Class 3": {
		"eye_colors": ["Blue", "Indigo", "Red"],
		"weight_range": [180, 280],
		"blood_types": ["B-Volatile", "C-Pulse"]
	},
	"Class 4": {
		"eye_colors": ["Purple", "Violet", "Magenta"],
		"weight_range": [45, 85],
		"blood_types": ["C-Stable", "D-Light"]
	}
}

func _ready() -> void:
	print("🆕 New Monitor System initializing...")
	
	# Set up display properties
	size = Vector2(console_size.x * 32.0, console_size.y * 64.0)
	
	# Set large font size for readability
	if not theme:
		theme = Theme.new()
	theme.set_font_size("normal_font_size", "RichTextLabel", 1004)
	add_theme_font_size_override("normal_font_size", 60)
	
	# Ensure visibility
	visible = true
	modulate = Color(1, 1, 1, 1)
	
	# Show initial state
	display_start_message()
	
	print("✅ New Monitor System ready")

# ====================================
# PUBLIC INTERFACE METHODS
# ====================================

func display_start_message() -> void:
	print("📺 NEW: Displaying start message...")
	current_state = DisplayState.START_MESSAGE
	_render_display()

func display_processing_message() -> void:
	print("📺 NEW: Displaying processing message...")
	current_state = DisplayState.PROCESSING
	_render_display()

func display_alien_information(alien: Dictionary = {}) -> void:
	print("📺 NEW: Displaying alien information...")
	if not alien.is_empty():
		alien_data = alien
	else:
		# Get alien data from GameManager if available
		if GameManager and not GameManager.current_alien.is_empty():
			alien_data = GameManager.current_alien
		else:
			print("⚠️ No alien data available")
			return
	
	current_state = DisplayState.ALIEN_INFO
	_render_display()

# Test method for debugging
func ping() -> String:
	var response = "NEW Monitor responsive at: " + str(get_path())
	print("🏓 " + response)
	return response

# ====================================
# DISPLAY RENDERING
# ====================================

func _render_display() -> void:
	print("🎨 NEW: Rendering display state: ", DisplayState.keys()[current_state])
	
	# Clear existing content
	clear()
	
	match current_state:
		DisplayState.START_MESSAGE:
			_render_start_message()
		DisplayState.PROCESSING:
			_render_processing_message()
		DisplayState.ALIEN_INFO:
			_render_alien_info()

func _render_start_message() -> void:
	# Header
	_add_centered_text("ALIEN CLASSIFICATION SYSTEM", Color.GREEN)
	_add_spacing(2)
	
	# Main message
	_add_centered_text("PRESS THE BUTTON TO BEGIN", Color.YELLOW)
	_add_spacing(2)
	
	# Status
	_add_centered_text("System Status: READY", Color.CYAN)

func _render_processing_message() -> void:
	# Header
	_add_centered_text("ALIEN CLASSIFICATION SYSTEM", Color.GREEN)
	_add_spacing(2)
	
	# Processing message
	_add_centered_text("PROCESSING INFORMATION...", Color.ORANGE)
	_add_spacing(2)
	
	# Wait message
	_add_centered_text("Please wait...", Color.CYAN)

func _render_alien_info() -> void:
	if alien_data.is_empty():
		_add_centered_text("ERROR: NO ALIEN DATA", Color.RED)
		return
	
	# Get stage info if available
	var stage_info = {}
	if GameManager and GameManager.has_method("get_current_stage_info"):
		stage_info = GameManager.get_current_stage_info()
	
	# Header with stage info
	if not stage_info.is_empty():
		var stage_text = "STAGE %d: %s" % [stage_info.stage, stage_info.stage_name]
		_add_centered_text(stage_text, Color.CYAN)
		
		var progress_text = "PROGRESS: %d/%d | ACCURACY: %.1f%%" % [stage_info.progress, stage_info.target, stage_info.accuracy]
		_add_centered_text(progress_text, Color.WHITE)
		_add_spacing(2)
	
	# Specimen analysis
	_add_text("SPECIMEN ANALYSIS:", Color.YELLOW)
	_add_spacing(1)
	
	_add_text("Species: " + str(alien_data.get("species", "Unknown")), Color.WHITE)
	_add_text("Weight: " + str(alien_data.get("weight", "Unknown")) + " kg", Color.WHITE)
	
	# Show complications if any
	var complications = alien_data.get("complications", [])
	if not complications.is_empty():
		_add_spacing(1)
		_add_text("COMPLICATIONS DETECTED:", Color.RED)
		for complication in complications:
			var comp_text = complication.replace("_", " ").to_upper()
			_add_text("- " + comp_text, Color.RED)
	
	_add_spacing(2)
	_add_text("Use control panel to apply sedation", Color.ORANGE)

# ====================================
# HELPER METHODS FOR DISPLAY
# ====================================

func _add_centered_text(text: String, color: Color) -> void:
	push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	push_color(color)
	add_text(text)
	pop() # color
	pop() # alignment
	newline()

func _add_text(text: String, color: Color) -> void:
	push_color(color)
	add_text(text)
	pop()
	newline()

func _add_spacing(lines: int) -> void:
	for i in lines:
		newline()

# ====================================
# LIQUID RATIO CALCULATIONS
# ====================================

func get_current_liquid_ratios() -> Array:
	if alien_data.is_empty():
		# Fallback for demo/testing
		print("📺 NEW: No alien data, providing demo ratios: [35, 40, 25]")
		return [35, 40, 25]
	
	var species = str(alien_data.get("species", ""))
	var weight = float(alien_data.get("weight", 0))
	var eye_color = str(alien_data.get("eye_color", ""))
	
	var ratios = _calculate_liquid_ratios(species, weight, eye_color)
	print("📺 NEW: Calculated liquid ratios: ", ratios)
	return ratios

func _calculate_liquid_ratios(species: String, weight: float, _eye_color: String) -> Array:
	var weight_int = int(weight)
	var ratios = [0, 0, 0]
	
	# Determine ratios based on species and weight ranges
	match species:
		"Class 1":
			if weight_int >= 120 and weight_int <= 125:
				ratios = [31, 51, 18]
			elif weight_int >= 126 and weight_int <= 131:
				ratios = [28, 49, 23]
			elif weight_int >= 132 and weight_int <= 137:
				ratios = [33, 53, 14]
			elif weight_int >= 138 and weight_int <= 143:
				ratios = [19, 62, 19]
			elif weight_int >= 144 and weight_int <= 149:
				ratios = [25, 45, 30]
			elif weight_int >= 150 and weight_int <= 160:
				ratios = [35, 40, 25]
		
		"Class 2":
			if weight_int >= 75 and weight_int <= 80:
				ratios = [42, 38, 20]
			elif weight_int >= 81 and weight_int <= 86:
				ratios = [38, 42, 20]
			elif weight_int >= 87 and weight_int <= 92:
				ratios = [32, 28, 40]
			elif weight_int >= 93 and weight_int <= 98:
				ratios = [22, 18, 60]
			elif weight_int >= 99 and weight_int <= 104:
				ratios = [45, 30, 25]
			elif weight_int >= 105 and weight_int <= 125:
				ratios = [50, 25, 25]
		
		"Class 3":
			if weight_int >= 180 and weight_int <= 195:
				ratios = [50, 45, 15]
			elif weight_int >= 196 and weight_int <= 211:
				ratios = [45, 50, 15]
			elif weight_int >= 212 and weight_int <= 227:
				ratios = [40, 35, 35]
			elif weight_int >= 228 and weight_int <= 243:
				ratios = [30, 25, 55]
			elif weight_int >= 244 and weight_int <= 259:
				ratios = [35, 30, 35]
			elif weight_int >= 260 and weight_int <= 280:
				ratios = [25, 35, 40]
		
		"Class 4":
			if weight_int >= 45 and weight_int <= 50:
				ratios = [60, 55, 10]
			elif weight_int >= 51 and weight_int <= 56:
				ratios = [55, 45, 25]
			elif weight_int >= 57 and weight_int <= 62:
				ratios = [50, 35, 45]
			elif weight_int >= 63 and weight_int <= 68:
				ratios = [45, 30, 50]
			elif weight_int >= 69 and weight_int <= 74:
				ratios = [40, 40, 20]
			elif weight_int >= 75 and weight_int <= 85:
				ratios = [35, 35, 30]
		_:
			print("⚠️ Unknown species: ", species)
			ratios = [35, 40, 25]  # Default fallback
	
	return ratios

# ====================================
# LEGACY COMPATIBILITY METHODS
# ====================================

# These methods maintain compatibility with existing code
func show_start_message() -> void:
	display_start_message()

func show_processing_message() -> void:
	display_processing_message()

func show_alien_info() -> void:
	display_alien_information()

func show_alien_information() -> void:
	display_alien_information()

func enable_classification() -> void:
	print("📺 NEW: Classification enabled (no-op in new system)")

func test_display() -> void:
	print("🧪 NEW: Testing monitor display...")
	clear()
	_add_centered_text("MONITOR TEST", Color.RED)
	_add_text("This is a test message", Color.WHITE)
	_add_text("New Monitor is working correctly!", Color.YELLOW)
	print("🧪 NEW: Test display complete")
