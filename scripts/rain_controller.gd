class_name RainController
extends RefCounted

var base_node: Node3D
var camera: Camera3D
var rain_node: GPUParticles3D

func _init(node: Node3D, cam: Camera3D) -> void:
	base_node = node
	camera = cam

func initialize() -> void:
	rain_node = base_node.get_node_or_null("Rain") as GPUParticles3D
	if not rain_node:
		return
		
	# Simulate in world space so rain drops don't move with the camera
	rain_node.local_coords = false
	rain_node.preprocess = 3.0 # Pre-simulate rain so it's already falling when game starts
	rain_node.visibility_aabb = AABB(Vector3(-100, -200, -100), Vector3(200, 300, 200)) # Ensure it's not culled early
	rain_node.amount = 4000 # Intense rain
	
	var material := rain_node.process_material as ParticleProcessMaterial
	if material:
		material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		material.emission_box_extents = Vector3(40, 0, 40)
		material.direction = Vector3(0, -1, 0)
		material.spread = 0.0 # Forces the rain to fall straight down (no cone spread)
		material.initial_velocity_min = 30.0
		material.initial_velocity_max = 35.0

func process(_delta: float) -> void:
	if not rain_node:
		return
		
	# Always keep the particle emitter above the camera's zoom level
	rain_node.position.y = camera.position.y + 60.0
	# Shift the rain center slightly to match where the camera points diagonally
	rain_node.position.z = camera.position.z * 0.5 
	
	# Dynamically scale the Rain box to match how far you have zoomed out
	var material := rain_node.process_material as ParticleProcessMaterial
	if material:
		var dynamic_size: float = max(camera.position.y * 1.5, 40.0)
		material.emission_box_extents = Vector3(dynamic_size, 0, dynamic_size)
