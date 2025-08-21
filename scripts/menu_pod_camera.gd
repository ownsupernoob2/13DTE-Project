extends Node3D
# Cinematic camera controller for the main menu pod display

@onready var camera: Camera3D = $CinematicCamera
@onready var animation_player: AnimationPlayer = $CameraAnimationPlayer
@onready var pod: Node3D = $Pod
@onready var fog_spheres: Array[Node3D] = []

# Camera movement parameters
var camera_orbit_radius: float = 8.0
var camera_height: float = 6.5
var orbit_speed: float = 0.008
var height_oscillation: float = 0
var height_speed: float = 0.8

# Time tracking
var time_elapsed: float = 0.0

func _ready() -> void:
	# Collect fog spheres for animation
	fog_spheres = [
		$FogSphere1,
		$FogSphere2, 
		$FogSphere3,
		$FogSphere4
	]
	
	# Start the cinematic camera movement
	set_process(true)
	create_camera_animation()
	
	print("Menu pod camera initialized")

func _process(delta: float) -> void:
	time_elapsed += delta
	
	# Smooth orbital camera movement
	var angle = time_elapsed * orbit_speed
	var x = sin(angle) * camera_orbit_radius
	var z = cos(angle) * camera_orbit_radius
	var y = camera_height + sin(time_elapsed * height_speed) * height_oscillation
	
	# Set camera position
	camera.position = Vector3(x, y, z)
	
	# Always look at the pod
	camera.look_at(pod.global_position, Vector3.UP)
	
	# Animate fog spheres for atmospheric effect
	animate_fog()

func animate_fog() -> void:
	for i in range(fog_spheres.size()):
		var fog = fog_spheres[i]
		if not fog:
			continue
			
		# Rotate each fog sphere at different speeds
		var rotation_speed = 0.2 + i * 0.1
		fog.rotation.y += rotation_speed * get_process_delta_time()
		
		# Slight vertical movement
		var offset = sin(time_elapsed * (1.0 + i * 0.3)) * 0.2
		fog.position.y = fog.position.y + offset * get_process_delta_time()

func create_camera_animation() -> void:
	# Create an animation resource if it doesn't exist
	var animation = Animation.new()
	animation.resource_name = "camera_movement"
	animation.length = 20.0  # 20 second loop
	animation.loop_mode = Animation.LOOP_LINEAR
	
	# Add the animation to the player
	var library = AnimationLibrary.new()
	library.add_animation("camera_movement", animation)
	animation_player.add_animation_library("default", library)
	
	print("Camera animation created")

func reset_camera() -> void:
	# Reset camera to starting position
	time_elapsed = 0.0
	camera.position = Vector3(4, 2, 6)
	camera.look_at(pod.global_position, Vector3.UP)
