extends Node3D

# Pod control system - manages game start, filling effects, and sedation color changes
# Integrates with GameManager and Monitor system

# Game state
var game_started: bool = false
var pod_filling: bool = false
var alien_sedated: bool = false

# Node references
@onready var start_button_3d: StaticBody3D = $"StartButton3D"
@onready var button_mesh: MeshInstance3D = $"StartButton3D/ButtonMesh"
@onready var button_label: Label3D = $"StartButton3D/ButtonLabel"
@onready var fill_shader_material: ShaderMaterial = $"Shader".material_override
@onready var sedation_shader_material: ShaderMaterial = $"ShaderInner".material_override
@onready var inner_shader_material: ShaderMaterial = $"ShaderInnerner".material_override  # Third shader layer
@onready var steam_audio: AudioStreamPlayer3D = $"Ambience"  # Use existing audio node for steam sounds
@onready var health_bar: ProgressBar = $"PodHealthViewport/PodHealthUI/HealthBar"
@onready var health_text: Label = $"PodHealthViewport/PodHealthUI/HealthText"
@onready var health_display: MeshInstance3D = $"PodHealthDisplay"

# Button interaction
var button_original_material: StandardMaterial3D

# Shader animation properties
var fill_progress: float = 0.0
var sedation_intensity: float = 0.0

func _ready() -> void:
	print("🏺 Pod system initialized")
	
	# Initialize 3D button
	if start_button_3d:
		start_button_3d.input_event.connect(_on_start_button_clicked)
		# Store original material for button effects
		if button_mesh and button_mesh.get_surface_override_material(0):
			button_original_material = button_mesh.get_surface_override_material(0)
	else:
		print("❌ 3D Start button not found")
	
	# Initialize shader states
	_initialize_shaders()
	
	# Initialize health display
	_initialize_health_display()
	
	# Connect to GameManager pod health signals
	if GameManager:
		GameManager.pod_health_changed.connect(_on_pod_health_changed)
		GameManager.pod_destroyed.connect(_on_pod_destroyed)

func _initialize_health_display() -> void:
	print("💗 Initializing pod health display...")
	
	# Hide health display initially (only show after game starts)
	if health_display:
		health_display.visible = false
	
	# Set initial health values
	if health_bar:
		health_bar.value = 100.0
	if health_text:
		health_text.text = "100%"

# Start pod filling sequence with health degradation system

func _initialize_shaders() -> void:
	print("🔧 Initializing pod shaders...")
	
	# Set initial shader states - empty pod
	if fill_shader_material:
		fill_shader_material.set_shader_parameter("transparency_strength", 1.0)  # Fully transparent (empty)
		fill_shader_material.set_shader_parameter("animation_speed", 0.0)  # No animation
		print("✅ Fill shader initialized")
	else:
		print("⚠️ Fill shader material not found")
	
	if sedation_shader_material:
		sedation_shader_material.set_shader_parameter("transparency_strength", 1.0)  # Fully transparent
		sedation_shader_material.set_shader_parameter("color", Color(0.1, 0.2, 0.1, 1))  # Default green
		print("✅ Sedation shader initialized")
	else:
		print("⚠️ Sedation shader material not found")
		
	if inner_shader_material:
		inner_shader_material.set_shader_parameter("transparency_strength", 1.0)  # Fully transparent
		inner_shader_material.set_shader_parameter("color", Color(0.05, 0.15, 0.05, 1))  # Darker green
		print("✅ Inner shader initialized")
	else:
		print("⚠️ Inner shader material not found")

func _on_start_button_clicked(camera: Node, event: InputEvent, click_position: Vector3, click_normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("🚀 3D Start button clicked!")
		_on_start_button_pressed()

func _on_start_button_pressed() -> void:
	print("🚀 Start button activated!")
	
	if game_started:
		print("⚠️ Game already started - button press ignored")
		return
	
	# Button press animation
	_animate_button_press()
	
	game_started = true
	# Keep the button visible - don't hide it
	# start_button_3d.visible = false  # Commented out - button stays visible
	
	# Tell GameManager to start the game (but delay monitor update)
	if GameManager:
		GameManager.create_demo_alien()  # This starts the game but we'll handle monitor timing
		print("✅ GameManager started")
	else:
		print("❌ GameManager not found!")
	
	# Start the delayed monitor display sequence
	_start_delayed_monitor_sequence()
	
	print("✅ Game started immediately, monitor display will show in a few seconds...")
	print("💡 Button remains visible but further presses will be ignored")

func _start_delayed_monitor_sequence() -> void:
	print("🎬 Starting delayed monitor sequence...")
	
	# First show "Processing information" message
	if GameManager:
		GameManager._show_processing_message()
		print("📺 Processing message displayed")
	
	# Start shader color transition from white to dark green
	_animate_shader_color_change()
	
	# Wait 3 seconds then show alien information
	await get_tree().create_timer(3.0).timeout
	
	# Now update the monitor with alien information
	if GameManager:
		GameManager._update_monitor_display()
		print("📺 Alien information now displayed after processing delay")

func _animate_button_press() -> void:
	print("🎬 Animating 3D button press...")
	
	if not button_mesh:
		return
	
	# Create button press animation
	var press_tween = create_tween()
	press_tween.set_parallel(true)
	
	# Scale down slightly
	press_tween.tween_property(button_mesh, "scale", Vector3(0.95, 0.8, 0.95), 0.1)
	# Change to pressed color
	if button_original_material:
		var pressed_material = button_original_material.duplicate()
		pressed_material.albedo_color = Color(0.8, 0.2, 0.2, 1)  # Red when pressed
		pressed_material.emission = Color(0.4, 0.1, 0.1, 1)
		button_mesh.set_surface_override_material(0, pressed_material)
	
	# Scale back up
	await press_tween.finished
	var release_tween = create_tween()
	release_tween.tween_property(button_mesh, "scale", Vector3(1, 1, 1), 0.1)

func _start_pod_filling_sequence() -> void:
	print("💧 Starting pod filling sequence...")
	pod_filling = true
	
	# Create filling animation
	var fill_tween = create_tween()
	fill_tween.set_parallel(true)
	
	# Animate filling progress (transparency goes from 1.0 to 0.0 = empty to full)
	fill_tween.tween_method(_update_fill_shader, 1.0, 0.2, 3.0)
	
	# Start animation effects
	if fill_shader_material:
		fill_tween.tween_method(_update_animation_speed, 0.0, 0.5, 1.0)
	
	await fill_tween.finished
	
	pod_filling = false
	print("✅ Pod filling completed!")
	
	# Show health display after pod is filled
	if health_display:
		health_display.visible = true
		print("💗 Pod health display activated")

func _on_pod_health_changed(health: float) -> void:
	print("💗 Pod health changed to: ", health)
	
	# Update health bar
	if health_bar:
		health_bar.value = health
	
	# Update health text
	if health_text:
		health_text.text = str(int(health)) + "%"
	
	# Change health bar color based on health level
	if health_bar:
		if health > 66:
			health_bar.modulate = Color.GREEN
		elif health > 33:
			health_bar.modulate = Color.YELLOW
		else:
			health_bar.modulate = Color.RED

func _on_pod_destroyed() -> void:
	print("💀 Pod destroyed - updating display...")
	
	if health_text:
		health_text.text = "CRITICAL FAILURE"
		health_text.modulate = Color.RED
	
	if health_bar:
		health_bar.modulate = Color.RED

func _update_fill_shader(transparency: float) -> void:
	if fill_shader_material:
		fill_shader_material.set_shader_parameter("transparency_strength", transparency)

func _update_animation_speed(speed: float) -> void:
	if fill_shader_material:
		fill_shader_material.set_shader_parameter("animation_speed", speed)

# Called by lever system when sedation is applied
func apply_sedation_effect() -> void:
	print("💊 Applying sedation effect to pod...")
	alien_sedated = true
	
	# Play steam hissing sound effect
	if steam_audio:
		steam_audio.pitch_scale = 1.5  # Higher pitch for hissing effect
		steam_audio.play()
		print("💨 Steam hissing sound playing...")
	
	# Change sedation shader color to indicate sedation
	_start_sedation_color_change()

func _start_sedation_color_change() -> void:
	print("🎨 Starting sedation color change...")
	
	if not sedation_shader_material:
		print("❌ No sedation shader material found")
		return
	
	# Create sedation effect animation
	var sedation_tween = create_tween()
	sedation_tween.set_parallel(true)
	
	# Make sedation layer visible
	sedation_tween.tween_method(_update_sedation_transparency, 1.0, 0.3, 1.0)
	
	# Change color to indicate sedation (blue/purple tint)
	var sedated_color = Color(0.5, 0.3, 0.8, 1.0)  # Purple/blue sedation color
	sedation_tween.tween_method(_update_sedation_color, Color(0.1, 0.2, 0.1, 1), sedated_color, 1.5)
	
	# Also change the fill shader during sedation for extra visual impact
	if fill_shader_material:
		var fill_sedated_color = Color(0.3, 0.2, 0.6, 0.8)  # Darker purple for fill shader
		sedation_tween.tween_method(_update_fill_color, Color(0.05, 0.2, 0.06, 0.8), fill_sedated_color, 1.5)
		print("🟣 Both sedation and fill shaders changing color during injection")
	
	# Animate inner shader for additional depth effect
	if inner_shader_material:
		var inner_sedated_color = Color(0.2, 0.1, 0.4, 0.6)  # Deep purple for inner layer
		sedation_tween.tween_method(_update_inner_color, Color(0.05, 0.15, 0.05, 1), inner_sedated_color, 1.5)
		sedation_tween.tween_method(_update_inner_transparency, 1.0, 0.4, 1.0)
		print("🔮 All three shader layers animating during sedation")
	
	await sedation_tween.finished
	print("✅ Sedation color effect completed!")

func _update_sedation_transparency(transparency: float) -> void:
	if sedation_shader_material:
		sedation_shader_material.set_shader_parameter("transparency_strength", transparency)

func _update_sedation_color(color: Color) -> void:
	if sedation_shader_material:
		sedation_shader_material.set_shader_parameter("color", color)

func _animate_shader_color_change() -> void:
	print("🎨 Starting shader color animation from white to dark green...")
	
	# Animate the fill shader from clear white to dark green over 3 seconds
	if fill_shader_material:
		var color_tween = create_tween()
		color_tween.set_parallel(true)
		
		# Start from clear/white color
		var start_color = Color(1.0, 1.0, 1.0, 0.3)  # Clear white
		var end_color = Color(0.05, 0.2, 0.06, 0.8)  # Dark green
		
		# Set initial color
		fill_shader_material.set_shader_parameter("color", start_color)
		
		# Animate to dark green over 3 seconds
		color_tween.tween_method(_update_fill_color, start_color, end_color, 3.0)
		print("🟢 Shader color transition started")
	else:
		print("⚠️ Fill shader material not found for color animation")

func _update_fill_color(color: Color) -> void:
	if fill_shader_material:
		fill_shader_material.set_shader_parameter("color", color)

func _update_inner_color(color: Color) -> void:
	if inner_shader_material:
		inner_shader_material.set_shader_parameter("color", color)

func _update_inner_transparency(transparency: float) -> void:
	if inner_shader_material:
		inner_shader_material.set_shader_parameter("transparency_strength", transparency)

# Public methods for external control
func is_game_started() -> bool:
	return game_started

func is_pod_full() -> bool:
	return game_started and not pod_filling

func is_alien_sedated() -> bool:
	return alien_sedated

func reset_pod() -> void:
	print("🔄 Resetting pod to initial state...")
	game_started = false
	pod_filling = false
	alien_sedated = false
	
	if start_button_3d:
		start_button_3d.visible = true
	
	# Reset button material
	if button_mesh and button_original_material:
		button_mesh.set_surface_override_material(0, button_original_material)
		button_mesh.scale = Vector3(1, 1, 1)
	
	_initialize_shaders()
