extends Node

# Failure Manager - Handles failure states, visual indicators, and scene transitions

signal failure_triggered(reason: String)

@onready var red_light: OmniLight3D = null
@onready var green_light: OmniLight3D = null
@onready var failure_overlay: ColorRect = null
@onready var failure_timer: Timer = null

var is_failure_active: bool = false
var failure_countdown: float = 0.0

# Stage scene paths
var stage_scenes: Array[String] = [
	"res://scenes/stage_1_tutorial.tscn",
	"res://scenes/stage_2_easy.tscn", 
	"res://scenes/stage_3_easy.tscn",
	"res://scenes/stage_4_medium.tscn",
	"res://scenes/stage_5_hard.tscn"
]

func _ready() -> void:
	# Use deferred calls to avoid "parent busy" errors
	call_deferred("_create_failure_overlay")
	call_deferred("_create_indicator_lights")
	call_deferred("_setup_timer")
	
	# Connect to failure events
	failure_triggered.connect(_handle_failure)
	
	print("🚨 FailureManager initialized")

func _setup_timer() -> void:
	# Create timer
	failure_timer = Timer.new()
	add_child(failure_timer)
	failure_timer.timeout.connect(_on_failure_timer_timeout)

func _create_failure_overlay() -> void:
	# Create a full-screen overlay for blackout effect
	failure_overlay = ColorRect.new()
	failure_overlay.name = "FailureOverlay"
	failure_overlay.color = Color.BLACK
	failure_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	failure_overlay.visible = false
	
	# Make it cover the entire screen
	failure_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Add to scene tree at root level so it's always on top using deferred
	get_tree().current_scene.call_deferred("add_child", failure_overlay)
	
	print("📺 Failure overlay created")

func _create_indicator_lights() -> void:
	# Create red failure light
	red_light = OmniLight3D.new()
	red_light.name = "RedFailureLight"
	red_light.light_color = Color.RED
	red_light.light_energy = 0.0  # Start dim
	red_light.omni_range = 10.0
	red_light.position = Vector3(0, 5, 0)  # Above player area
	get_tree().current_scene.call_deferred("add_child", red_light)
	
	# Create green success light
	green_light = OmniLight3D.new()
	green_light.name = "GreenSuccessLight"
	green_light.light_color = Color.GREEN
	green_light.light_energy = 0.0  # Start dim
	green_light.omni_range = 10.0
	green_light.position = Vector3(2, 5, 0)  # Next to red light
	get_tree().current_scene.call_deferred("add_child", green_light)
	
	print("💡 Indicator lights created")

func trigger_failure(reason: String) -> void:
	if is_failure_active:
		return  # Don't trigger multiple failures
		
	print("🚨 FAILURE TRIGGERED: ", reason)
	failure_triggered.emit(reason)

func trigger_success() -> void:
	if is_failure_active:
		return
		
	print("✅ SUCCESS!")
	_flash_green_light()

func _handle_failure(reason: String) -> void:
	is_failure_active = true
	
	# Step 1: Flash red light and exit from any active interfaces
	_flash_red_light()
	_force_exit_interfaces()
	
	# Step 2: Make everything untouchable for 3 seconds
	_disable_all_interactions()
	failure_countdown = 3.0
	failure_timer.wait_time = 0.1  # Update every 100ms
	failure_timer.start()
	
	print("🚫 Disabling interactions for 3 seconds...")

func _flash_red_light() -> void:
	if not red_light:
		return
		
	# Flash red light with tween
	var tween = create_tween()
	tween.set_loops(3)  # Flash 3 times
	tween.tween_property(red_light, "light_energy", 2.0, 0.2)
	tween.tween_property(red_light, "light_energy", 0.0, 0.2)

func _flash_green_light() -> void:
	if not green_light:
		return
		
	# Flash green light with tween
	var tween = create_tween()
	tween.set_loops(2)  # Flash 2 times
	tween.tween_property(green_light, "light_energy", 1.5, 0.3)
	tween.tween_property(green_light, "light_energy", 0.0, 0.3)

func _force_exit_interfaces() -> void:
	# Force exit from computer/monitor/scanner
	if Global.is_using_computer or Global.is_using_monitor:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("exit_computer_mode"):
			player.exit_computer_mode()
			print("🚪 Forced exit from computer/monitor/scanner")

func _disable_all_interactions() -> void:
	# Disable player input
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_process_unhandled_input(false)
		player.set_physics_process(false)
		print("🚫 Player interactions disabled")
	
	# Disable UI interactions
	get_tree().paused = true
	get_tree().set_pause_mode_on_nodes([failure_timer], Node.PROCESS_MODE_ALWAYS)

func _on_failure_timer_timeout() -> void:
	failure_countdown -= 0.1
	
	if failure_countdown <= 0:
		failure_timer.stop()
		_start_blackout()

func _start_blackout() -> void:
	print("🌑 Starting blackout phase...")
	
	# Show blackout overlay
	if failure_overlay:
		failure_overlay.visible = true
	
	# Wait 2 seconds then restart scene
	await get_tree().create_timer(2.0).timeout
	_restart_scene()

func _restart_scene() -> void:
	print("🔄 Restarting scene...")
	
	# Re-enable everything
	get_tree().paused = false
	
	# Determine which scene to restart to
	var current_stage = 1
	if GameManager and GameManager.current_stage:
		current_stage = GameManager.current_stage
	
	# Reset failure state
	is_failure_active = false
	
	# Load the appropriate stage scene
	if current_stage <= stage_scenes.size():
		get_tree().change_scene_to_file(stage_scenes[current_stage - 1])
	else:
		# Fallback to current scene
		get_tree().reload_current_scene()

func set_pause_mode_on_nodes(nodes: Array, mode: Node.ProcessMode) -> void:
	for node in nodes:
		if node:
			node.process_mode = mode

# Call this when sedation fails
func on_sedation_failure() -> void:
	trigger_failure("Incorrect sedation ratios")

# Call this when scanner analysis fails  
func on_scanner_failure() -> void:
	trigger_failure("Scanner analysis failed")

# Call this when classification is wrong
func on_classification_failure() -> void:
	trigger_failure("Incorrect alien classification")

# Call this when pod breaks completely
func on_pod_failure() -> void:
	trigger_failure("Pod integrity critical failure")
