extends CharacterBody3D

@export var speed: float = 8.0
@export var click_effect_scene: PackedScene 

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready():
	await get_tree().physics_frame
	# Allow the player to be a bit further from the exact point to stop jitter
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5

func _physics_process(_delta: float):
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return

	var next_path_pos = nav_agent.get_next_path_position()
	var direction = (next_path_pos - global_position)
	direction.y = 0 
	
	if direction.length() > 0.1:
		velocity = direction.normalized() * speed
		
		# Rotation safety
		var look_target = global_position + Vector3(direction.x, 0, direction.z)
		if not global_position.is_equal_approx(look_target):
			look_at(look_target, Vector3.UP)
			
		move_and_slide()
	else:
		velocity = Vector3.ZERO

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var target_pos = _get_click_position()
		if target_pos != Vector3.INF:
			nav_agent.set_target_position(target_pos)
			_spawn_indicator(target_pos)
			
			# DEBUG CHECK:
			await get_tree().physics_frame # Wait for path to calculate
			if nav_agent.is_target_reachable():
				print("Path found! Moving to: ", target_pos)
			else:
				print("Path is UNREACHABLE! Check your NavMesh.")

func _get_click_position() -> Vector3:
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()
	if not camera: return Vector3.INF
	
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	
	# Try 0.8 (your floor height). 
	var ground_plane = Plane(Vector3.UP, 0.8)
	var intersection = ground_plane.intersects_ray(ray_origin, ray_direction)
	return intersection if intersection else Vector3.INF

func _spawn_indicator(pos: Vector3):
	if click_effect_scene:
		var effect = click_effect_scene.instantiate()
		get_tree().root.add_child(effect)
		effect.global_position = pos + Vector3(0, 0.1, 0)
