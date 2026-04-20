class_name PropPlacementController
extends RefCounted

var base_node: Node3D
var camera: Camera3D

func _init(node: Node3D, cam: Camera3D) -> void:
	base_node = node
	camera = cam

func spawn_object_at_mouse(mouse_pos: Vector2) -> void:
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 10000
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = base_node.get_world_3d().direct_space_state.intersect_ray(query)
	
	if result and base_node.test_spawn:
		var instance = base_node.test_spawn.instantiate()
		
		var current_grid_size = base_node.grid_size
		# Try to auto-scale grid size based on model limits
		if instance.has_node("MeshInstance3D"):
			var mesh = instance.get_node("MeshInstance3D")
			if mesh is MeshInstance3D and mesh.mesh:
				var aabb = mesh.get_aabb()
				# Use max of X/Z dimension, default to at least 1.0 to avoid 0 div
				var mesh_scale = mesh.scale
				current_grid_size = max(max(aabb.size.x * mesh_scale.x, aabb.size.z * mesh_scale.z), 1.0)
				# Snap the grid size to the nearest whole number to keep grid clean
				current_grid_size = ceil(current_grid_size)
				
		# Calculate the Snapped Position
		var snapped_x = round(result.position.x / current_grid_size) * current_grid_size
		var snapped_z = round(result.position.z / current_grid_size) * current_grid_size
		var final_pos = Vector3(snapped_x, 0, snapped_z)
		
		# THE ANTI-CLIPPING CHECK
		if is_grid_slot_occupied(final_pos, current_grid_size):
			print("Forbidden: Space already occupied!")
			instance.free()
			return # STOP HERE - Don't spawn anything
		
		# Spawn the object
		base_node.get_tree().current_scene.add_child(instance)
		
		instance.global_position = final_pos
		instance.rotation = Vector3.ZERO # Keep them straight like Endfield
		
		if instance is Prop:
			PlayerManager.budget -= instance.cost
			base_node.update_budget_ui()

		base_node.test_spawn = null
		if base_node.ghost_instance:
			base_node.ghost_instance.queue_free()
			base_node.ghost_instance = null
		base_node.current_ghost_scene = null

func is_grid_slot_occupied(target_pos: Vector3, current_grid_size: float) -> bool:
	for prop in base_node.get_tree().get_nodes_in_group("props"):
		if is_instance_valid(prop) and prop is Node3D:
			var distance = prop.global_position.distance_to(target_pos)
			if distance < (current_grid_size * 0.9):
				return true
	return false

func update_ghost_preview(mouse_pos: Vector2) -> void:
	if base_node.current_ghost_scene != base_node.test_spawn:
		if base_node.ghost_instance:
			base_node.ghost_instance.queue_free()
		base_node.ghost_instance = base_node.test_spawn.instantiate()
		
		base_node.add_child(base_node.ghost_instance)
		base_node.current_ghost_scene = base_node.test_spawn
		make_ghost_recursive(base_node.ghost_instance)
		
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 10000
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = base_node.get_world_3d().direct_space_state.intersect_ray(query)
	
	if result:
		base_node.ghost_instance.visible = true
		
		var current_grid_size = base_node.grid_size
		if base_node.ghost_instance.has_node("MeshInstance3D"):
			var mesh = base_node.ghost_instance.get_node("MeshInstance3D")
			if mesh is MeshInstance3D and mesh.mesh:
				var aabb = mesh.get_aabb()
				var mesh_scale = mesh.scale
				current_grid_size = max(max(aabb.size.x * mesh_scale.x, aabb.size.z * mesh_scale.z), 1.0)
				current_grid_size = ceil(current_grid_size)
				
		var snapped_x = round(result.position.x / current_grid_size) * current_grid_size
		var snapped_z = round(result.position.z / current_grid_size) * current_grid_size
		var final_pos = Vector3(snapped_x, 0, snapped_z)
		
		base_node.ghost_instance.global_position = final_pos
		base_node.ghost_instance.rotation = Vector3.ZERO
		
		var is_occupied = is_grid_slot_occupied(final_pos, current_grid_size)
		set_ghost_color(base_node.ghost_instance, not is_occupied)
	else:
		base_node.ghost_instance.visible = false

func make_ghost_recursive(node: Node) -> void:
	if node.is_in_group("props"):
		node.remove_from_group("props")
		
	if node is CollisionObject3D:
		node.collision_layer = 0
		node.collision_mask = 0
		node.process_mode = Node.PROCESS_MODE_DISABLED
	elif node is MeshInstance3D:
		node.transparency = 0.5
		
	for child in node.get_children():
		make_ghost_recursive(child)

func set_ghost_color(node: Node, is_valid: bool) -> void:
	if node is MeshInstance3D:
		if is_valid:
			node.material_overlay = null
		else:
			node.material_overlay = base_node.invalid_material
	for child in node.get_children():
		set_ghost_color(child, is_valid)
