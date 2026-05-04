extends CharacterBody3D

const MOVE_SPEED := 11.0
const HARVEST_RANGE := 6.0
## Same range as F: horizontal XZ distance (avoids Y mismatch vs tall meshes).
const PROMPT_SHOW_RANGE := 6.0
## Layer 8 (bit 128): grass floor only; rays skip props/trees.
const FLOOR_COLLISION_MASK := 128

var _world_prompt: Node3D
var _name_label_3d: Label3D
var _hint_label_3d: Label3D


func _ready() -> void:
	add_to_group("player_city")
	_bind_world_prompt()
	call_deferred("_snap_feet_to_floor")
	call_deferred("_bind_world_prompt")


func _bind_world_prompt() -> void:
	if _world_prompt and is_instance_valid(_world_prompt):
		return
	var root := get_parent()
	if root:
		_world_prompt = root.get_node_or_null("HarvestWorldPrompt") as Node3D
	if _world_prompt == null:
		_world_prompt = get_tree().get_first_node_in_group("world_harvest_prompt") as Node3D
	if _world_prompt:
		_name_label_3d = _world_prompt.get_node_or_null("MaterialName") as Label3D
		_hint_label_3d = _world_prompt.get_node_or_null("HarvestHint") as Label3D


func _snap_feet_to_floor() -> void:
	var ws := get_world_3d().direct_space_state
	var from := global_position + Vector3(0.0, 120.0, 0.0)
	var to := global_position + Vector3(0.0, -400.0, 0.0)
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = FLOOR_COLLISION_MASK
	q.exclude = [get_rid()]
	var hit := ws.intersect_ray(q)
	if hit:
		global_position.y = hit.position.y + 0.02


func _physics_process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var dir := Vector3.ZERO
	if cam:
		var f := cam.global_transform.basis.z
		f.y = 0
		var r := cam.global_transform.basis.x
		r.y = 0
		if f.length_squared() > 0.0001:
			f = f.normalized()
		if r.length_squared() > 0.0001:
			r = r.normalized()
		if Input.is_key_pressed(KEY_W):
			dir -= f
		if Input.is_key_pressed(KEY_S):
			dir += f
		if Input.is_key_pressed(KEY_A):
			dir -= r
		if Input.is_key_pressed(KEY_D):
			dir += r
	dir.y = 0
	
	var current_speed := MOVE_SPEED
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed *= 2.0
		
	if dir.length_squared() > 0.0001:
		dir = dir.normalized()
		velocity.x = dir.x * current_speed
		velocity.z = dir.z * current_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	velocity.y = 0.0
	move_and_slide()
	_correct_vertical_to_floor()
	_update_interaction_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		_try_harvest_nearest()


func _correct_vertical_to_floor() -> void:
	var ws := get_world_3d().direct_space_state
	var from := global_position + Vector3(0.0, 3.0, 0.0)
	var to := global_position + Vector3(0.0, -12.0, 0.0)
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = FLOOR_COLLISION_MASK
	q.exclude = [get_rid()]
	var hit := ws.intersect_ray(q)
	if not hit:
		return
	var target_feet_y: float = hit.position.y + 0.02
	if global_position.y > target_feet_y + 0.08:
		global_position.y = lerpf(global_position.y, target_feet_y, 0.5)
	elif global_position.y > target_feet_y + 0.003:
		global_position.y = target_feet_y


func _horizontal_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _nearest_prop(max_distance: float) -> Prop:
	var best: Prop = null
	var best_d := INF
	var gp := global_position
	for n in get_tree().get_nodes_in_group("props"):
		if n is Prop and is_instance_valid(n):
			var pp := (n as Node3D).global_position
			var d: float = _horizontal_distance(gp, pp)
			if d <= max_distance and d < best_d:
				best_d = d
				best = n
	return best


func _prop_display_name(prop: Prop) -> String:
	if prop.drop_type != "none":
		return PlayerManager.resource_display_name(prop.drop_type)
	return str(prop.name).replace("_", " ").capitalize()


func _prop_mesh_top_global_y(prop: Prop) -> float:
	var mi := prop.mesh_instance as MeshInstance3D
	if mi == null or mi.mesh == null:
		return prop.global_position.y + 1.0
	var world_aabb: AABB = mi.global_transform * mi.get_aabb()
	return world_aabb.position.y + world_aabb.size.y


func _update_interaction_prompt() -> void:
	_bind_world_prompt()
	if _world_prompt == null:
		return
	var prop := _nearest_prop(PROMPT_SHOW_RANGE)
	if prop and prop.has_method("harvest"):
		_world_prompt.visible = true
		var top_y := _prop_mesh_top_global_y(prop)
		_world_prompt.global_position = Vector3(
			prop.global_position.x,
			top_y + 0.06,
			prop.global_position.z
		)
		if _name_label_3d:
			_name_label_3d.text = "%s\nHarvest  [F]" % _prop_display_name(prop)
		if _hint_label_3d:
			_hint_label_3d.visible = false
			_hint_label_3d.text = ""
	else:
		_world_prompt.visible = false
		if _name_label_3d:
			_name_label_3d.text = ""
		if _hint_label_3d:
			_hint_label_3d.visible = false
			_hint_label_3d.text = ""


func _try_harvest_nearest() -> void:
	var best := _nearest_prop(HARVEST_RANGE)
	if best == null:
		return
	PlayerManager.budget += best.cost
	if best.has_method("harvest"):
		MissionManager.register_before_harvest(best)
		best.harvest()
	else:
		best.queue_free()
	var cam_ctrl := get_tree().get_first_node_in_group("camera_controller")
	if cam_ctrl and cam_ctrl.has_method("update_budget_ui"):
		cam_ctrl.update_budget_ui()
