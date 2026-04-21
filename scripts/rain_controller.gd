class_name RainController
extends RefCounted

var base_node: Node3D
var rain_node: GPUParticles3D

# SETTINGS
var map_size: Vector2 = Vector2(1000, 1000) # Set this to the size of your map
var rain_amount: int = 100000             # Increased significantly for whole-map coverage
var rain_falling_height: float = 60.0    # How high the "clouds" are

func _init(node: Node3D, _cam: Camera3D) -> void:
	base_node = node

func initialize() -> void:
	rain_node = base_node.get_node_or_null("Rain") as GPUParticles3D
	if not rain_node: return
	
	# SETUP AMOUNT AND PERFORMANCE
	rain_node.amount = rain_amount
	rain_node.preprocess = 5.0 # Pre-fill the screen with rain
	
	# CRITICAL: The AABB must cover the whole map or rain will disappear when you look away
	rain_node.visibility_aabb = AABB(
		Vector3(-map_size.x, -100, -map_size.y), 
		Vector3(map_size.x * 2, 200, map_size.y * 2)
	)
	
	# POSITION AT CENTER OF MAP
	# Detach the rain node from the camera's transform so it stays fixed in the world
	rain_node.top_level = true
	# Reset scale back to 1.0 (some nodes may have a scaled transform from the editor)
	rain_node.scale = Vector3.ONE
	# If your map is centered at 0,0,0, use this:
	rain_node.global_position = Vector3(0, rain_falling_height, 0)
	
	var material := rain_node.process_material as ParticleProcessMaterial
	if material:
		material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		# Extents are half-widths (e.g. 200 covers a 400 unit area)
		material.emission_box_extents = Vector3(map_size.x / 2.0, 1, map_size.y / 2.0)
		
		material.direction = Vector3(0, -1, 0)
		material.spread = 0.0
		material.initial_velocity_min = 40.0
		material.initial_velocity_max = 55.0

	# FIX 3D RENDERING
	# Disable trails and use a stretched 3D mesh so rain is visible from all angles
	rain_node.trail_enabled = false
	var rain_mesh = BoxMesh.new()
	rain_mesh.size = Vector3(0.05, 1.5, 0.05) # Thin and tall to look like falling rain
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_color = Color(0.6, 0.8, 1.0, 0.6) # Light blue/white
	r_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED # Unlit so it stands out
	rain_mesh.material = r_mat
	rain_node.draw_pass_1 = rain_mesh

func process(_delta: float) -> void:
	# We no longer need to update position every frame!
	pass