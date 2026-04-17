extends "res://scripts/camera_node.gd"

@export var wood_logs_scene: PackedScene = preload("res://scenes/scene_test_env/wood_logs.tscn")
@export var gas_barrel_scene: PackedScene = preload("res://scenes/scene_test_env/gas_barrel.tscn")
@onready var game_manager: Node3D = $"../GameManager"

func _spawn_material_drop(prop: Prop) -> void:
	var drop_scene: PackedScene = null
	match prop.drop_type:
		"wood":
			drop_scene = wood_logs_scene
			game_manager.inventory.wood += 10
			
		"stone":
			drop_scene = gas_barrel_scene
			game_manager.inventory.stone += 10
		_:
			return

	if drop_scene:
		var drop = drop_scene.instantiate()
		get_tree().current_scene.add_child(drop)
		drop.global_position = prop.global_position + Vector3(0, 0.2, 0)
		
		await get_tree().create_timer(3.0).timeout # remove the materials
		get_tree().current_scene.remove_child(drop)

func delete_selected_props() -> void:
	var total_cost = 0.0
	for prop in selected_props:
		if is_instance_valid(prop):
			total_cost += prop.cost
			_spawn_material_drop(prop)
			if prop.has_method("harvest"):
				prop.harvest()
			else:
				prop.queue_free()
	PlayerManager.budget -= total_cost
	selected_props.clear()
	calculate_stats([])
	update_budget_ui()

func raycast_delete(mouse_pos: Vector2) -> void:
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result:
		var target = result.collider
		var prop_node = target if target is Prop else target.get_parent()
		if prop_node is Prop:
			_spawn_material_drop(prop_node)
			PlayerManager.budget += prop_node.cost
			if prop_node.has_method("harvest"):
				prop_node.harvest()
			else:
				prop_node.queue_free()
			update_budget_ui()
