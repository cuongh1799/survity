class_name SelectionController
extends RefCounted

var base_node: Node3D
var camera: Camera3D

func _init(node: Node3D, cam: Camera3D) -> void:
	base_node = node
	camera = cam

func update_selection_box(drag_end: Vector2) -> void:
	if base_node.drag_start.distance_to(drag_end) > base_node.drag_threshold:
		base_node.selection_box.visible = true
		var pos = Vector2(min(base_node.drag_start.x, drag_end.x), min(base_node.drag_start.y, drag_end.y))
		var size = (base_node.drag_start - drag_end).abs()
		base_node.selection_box.global_position = pos
		base_node.selection_box.size = size
		highlight_items_in_rect(Rect2(pos, size))

func highlight_items_in_rect(rect: Rect2) -> void:
	var current_hovered: Array = []
	for prop in base_node.get_tree().get_nodes_in_group("props"):
		if is_instance_valid(prop) and not camera.is_position_behind(prop.global_position):
			var screen_pos = camera.unproject_position(prop.global_position)
			if rect.has_point(screen_pos):
				if prop.has_method("set_highlight"): prop.set_highlight(true)
				current_hovered.append(prop)
			else:
				if prop.has_method("set_highlight"): prop.set_highlight(false)
	calculate_stats(current_hovered)

func confirm_selection() -> void:
	base_node.selected_props.clear()
	var rect = Rect2(base_node.selection_box.global_position, base_node.selection_box.size)
	for prop in base_node.get_tree().get_nodes_in_group("props"):
		if is_instance_valid(prop) and not camera.is_position_behind(prop.global_position):
			if rect.has_point(camera.unproject_position(prop.global_position)):
				base_node.selected_props.append(prop)
				if prop.has_method("set_highlight"): prop.set_highlight(true)
	calculate_stats(base_node.selected_props)

func calculate_stats(list: Array) -> void:
	var price = 0.0
	var total_collect_money = 0.0
	var collect_items = {}
	
	for prop in list:
		if "cost" in prop:
			price += prop.cost
		if "stored_budget" in prop:
			total_collect_money += prop.stored_budget
		if "stored_items" in prop and prop.stored_items > 0 and prop.generate_item_type != "none":
			if not collect_items.has(prop.generate_item_type):
				collect_items[prop.generate_item_type] = 0
			collect_items[prop.generate_item_type] += prop.stored_items

	if base_node.selection_label: base_node.selection_label.text = "Selected: " + str(list.size())
	
	var removal_text = "Removal Cost: $" + str(price)
	if total_collect_money > 0 or collect_items.size() > 0:
		removal_text += "\nCan Collect: "
		if total_collect_money > 0:
			removal_text += "$" + str(total_collect_money) + " "
		for item in collect_items:
			removal_text += str(collect_items[item]) + " " + item + " "
			
	if base_node.removal_label: base_node.removal_label.text = removal_text

func clear_selection() -> void:
	for prop in base_node.selected_props:
		if is_instance_valid(prop) and prop.has_method("set_highlight"):
			prop.set_highlight(false)
	base_node.selected_props.clear()
	calculate_stats([])

func collect_selected_props() -> void:
	for prop in base_node.selected_props:
		if is_instance_valid(prop) and prop.has_method("collect"):
			prop.collect()
	
	# Recalculate stats since items/budget have been collected
	calculate_stats(base_node.selected_props)

func delete_selected_props() -> void:
	var total_cost = 0.0
	for prop in base_node.selected_props:
		if is_instance_valid(prop):
			if "cost" in prop:
				total_cost += prop.cost
			if prop.has_method("harvest"):
				prop.harvest()
			else:
				prop.queue_free()
	# Assuming PlayerManager is a global singleton
	PlayerManager.budget -= total_cost # Refund the cost
	base_node.selected_props.clear()
	calculate_stats([])
	base_node.update_budget_ui()

func raycast_delete(mouse_pos: Vector2) -> void:
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = base_node.get_world_3d().direct_space_state.intersect_ray(query)
	if result:
		var target = result.collider
		var prop_node = target
		
		# In Godot, Prop might be the collider or the parent
		if target and not target.has_method("harvest") and 'cost' not in target:
			prop_node = target.get_parent()
			
		if prop_node and ('cost' in prop_node or prop_node.has_method("harvest")):
			if 'cost' in prop_node:
				PlayerManager.budget += prop_node.cost # Refund the cost
			if prop_node.has_method("harvest"):
				prop_node.harvest()
			else:
				prop_node.queue_free()
			base_node.update_budget_ui()
