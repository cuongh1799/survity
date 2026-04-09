extends Node3D

@export_group("Movement")
@export var pan_speed: float = 0.05
@export var zoom_speed: float = 2.0
@export var min_zoom: float = 5.0
@export var max_zoom: float = 300.0

@export_group("UI Nodes")
@export var selection_box_path: NodePath
@export var selection_label_path: NodePath
@export var removal_label_path: NodePath
@export var budget_label_path: NodePath
@export var coords_label_path: NodePath
@export var button_top_down_path: NodePath

@export_group("Spawning")
@export var grid_size: float = 5.0
@export var test_spawn: PackedScene:
	set(value):
		test_spawn = value
		setup_ghost_preview() # Update ghost whenever the scene changes
@export var spawn_parent_path: NodePath 

@export_group("Player Info")
@export var player_budget: float = 1000.0

@onready var camera = $Camera3D
@onready var selection_box = get_node(selection_box_path)
@onready var selection_label = get_node(selection_label_path)
@onready var removal_label = get_node(removal_label_path)
@onready var budget_label = get_node(budget_label_path)
@onready var coords_label = get_node(coords_label_path)
@onready var spawn_parent = get_node_or_null(spawn_parent_path)
@onready var button_top_down = get_node_or_null(button_top_down_path)

var top_down_mode: bool = false
var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var drag_threshold: float = 5.0
var selected_props: Array[Prop] = [] 

# Ghost Preview Variables
var ghost_preview: Node3D = null
var ghost_rotation: float = 0.0

func _ready() -> void:
	update_budget_ui()
	if not spawn_parent:
		spawn_parent = self
	setup_ghost_preview()

func _process(_delta: float) -> void:
	update_ghost_preview()

func _unhandled_input(event: InputEvent) -> void:
	# Zoom Logic
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.position.y = clamp(camera.position.y - zoom_speed, min_zoom, max_zoom)
			camera.position.z = clamp(camera.position.z - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.position.y = clamp(camera.position.y + zoom_speed, min_zoom, max_zoom)
			camera.position.z = clamp(camera.position.z + zoom_speed, min_zoom, max_zoom)

	# Pan Logic (Right Click)
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		translate(Vector3(-event.relative.x, 0, -event.relative.y) * pan_speed)

	# Rotation Logic (Press R to rotate preview)
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		ghost_rotation += 90.0

	# Left Click Logic
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			clear_selection()
			dragging = true
			drag_start = event.position
		else:
			if drag_start.distance_to(event.position) < drag_threshold:
				if test_spawn:
					spawn_object_at_mouse(event.position)
				else:
					raycast_delete(event.position)
			else:
				confirm_selection()
				
			dragging = false
			selection_box.visible = false

	if event is InputEventMouseMotion:
		update_mouse_coords(event.position)
		if dragging:
			update_selection_box(event.position)

	if event.is_action_pressed("ui_text_delete") or (event is InputEventKey and event.is_pressed() and event.keycode == KEY_DELETE):
		delete_selected_props()

# --- GHOST PREVIEW LOGIC ---

func setup_ghost_preview() -> void:
	if ghost_preview:
		ghost_preview.queue_free()
	
	if test_spawn:
		ghost_preview = test_spawn.instantiate()
		add_child(ghost_preview)
		# Ensure ghost doesn't have collisions or it will break the raycast
		recursive_cleanup_ghost(ghost_preview)
		set_ghost_transparency(ghost_preview, 0.5)

func update_ghost_preview() -> void:
	if not ghost_preview: return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 10000
	var query = PhysicsRayQueryParameters3D.create(from, to)
	# IMPORTANT: Exclude the ghost itself from raycasting if you didn't disable collisions correctly
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	
	if result:
		ghost_preview.visible = true
		var current_grid_size = get_calculated_grid_size(ghost_preview)
		
		var snapped_x = round(result.position.x / current_grid_size) * current_grid_size
		var snapped_z = round(result.position.z / current_grid_size) * current_grid_size
		var final_pos = Vector3(snapped_x, 0, snapped_z)
		
		ghost_preview.global_position = final_pos
		ghost_preview.rotation_degrees.y = ghost_rotation
		
		# Visual feedback if blocked
		if is_grid_slot_occupied(final_pos, current_grid_size):
			# You could swap materials here to a red "forbidden" shader
			pass 
	else:
		ghost_preview.visible = false

func recursive_cleanup_ghost(node: Node) -> void:
	if node is CollisionShape3D or node is CollisionPolygon3D:
		node.disabled = true
	if node is PhysicsBody3D:
		node.input_ray_pickable = false
		node.collision_layer = 0
		node.collision_mask = 0
	for child in node.get_children():
		recursive_cleanup_ghost(child)

func set_ghost_transparency(node: Node, alpha: float) -> void:
	if node is MeshInstance3D:
		for i in range(node.get_surface_override_material_count() if node.get_surface_override_material_count() > 0 else node.mesh.get_surface_count()):
			var mat = node.get_active_material(i)
			if mat:
				var ghost_mat = mat.duplicate()
				ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				ghost_mat.albedo_color.a = alpha
				node.set_surface_override_material(i, ghost_mat)
	for child in node.get_children():
		set_ghost_transparency(child, alpha)

# --- SPAWNING LOGIC ---

func get_calculated_grid_size(instance: Node3D) -> float:
	var size = grid_size
	if instance.has_node("MeshInstance3D"):
		var mesh = instance.get_node("MeshInstance3D")
		if mesh is MeshInstance3D and mesh.mesh:
			var aabb = mesh.get_aabb()
			size = max(max(aabb.size.x * mesh.scale.x, aabb.size.z * mesh.scale.z), 1.0)
			size = ceil(size)
	return size

func spawn_object_at_mouse(mouse_pos: Vector2):
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 10000
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	
	if result and test_spawn:
		var instance = test_spawn.instantiate()
		var current_grid_size = get_calculated_grid_size(instance)
		
		var snapped_x = round(result.position.x / current_grid_size) * current_grid_size
		var snapped_z = round(result.position.z / current_grid_size) * current_grid_size
		var final_pos = Vector3(snapped_x, 0, snapped_z)
		
		if is_grid_slot_occupied(final_pos, current_grid_size):
			print("Forbidden: Space already occupied!")
			instance.free()
			return 
		
		spawn_parent.add_child(instance)
		instance.global_position = final_pos
		instance.rotation_degrees.y = ghost_rotation # Match the preview rotation
		
		if instance is Prop:
			player_budget -= instance.cost
			update_budget_ui()

func is_grid_slot_occupied(target_pos: Vector3, current_grid_size: float) -> bool:
	for prop in get_tree().get_nodes_in_group("props"):
		if is_instance_valid(prop) and prop is Node3D:
			var distance = prop.global_position.distance_to(target_pos)
			if distance < (current_grid_size * 0.9):
				return true
	return false

# --- UI & SELECTION LOGIC ---

func update_mouse_coords(mouse_pos: Vector2) -> void:
	if not coords_label: return
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 10000
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	
	if result:
		var pos = result.position
		coords_label.text = "x: %.1f\ny: %.1f\nz: %.1f" % [pos.x, pos.y, pos.z]
	else:
		coords_label.text = "x: --\ny: --\nz: --"

func update_selection_box(drag_end: Vector2) -> void:
	if drag_start.distance_to(drag_end) > drag_threshold:
		selection_box.visible = true
		var pos = Vector2(min(drag_start.x, drag_end.x), min(drag_start.y, drag_end.y))
		var size = (drag_start - drag_end).abs()
		selection_box.global_position = pos
		selection_box.size = size
		highlight_items_in_rect(Rect2(pos, size))

func highlight_items_in_rect(rect: Rect2) -> void:
	var current_hovered: Array[Prop] = []
	for prop in get_tree().get_nodes_in_group("props"):
		if prop is Prop and not camera.is_position_behind(prop.global_position):
			var screen_pos = camera.unproject_position(prop.global_position)
			if rect.has_point(screen_pos):
				prop.set_highlight(true)
				current_hovered.append(prop)
			else:
				prop.set_highlight(false)
	calculate_stats(current_hovered)

func confirm_selection() -> void:
	selected_props.clear()
	var rect = Rect2(selection_box.global_position, selection_box.size)
	for prop in get_tree().get_nodes_in_group("props"):
		if prop is Prop and not camera.is_position_behind(prop.global_position):
			if rect.has_point(camera.unproject_position(prop.global_position)):
				selected_props.append(prop)
				prop.set_highlight(true)
	calculate_stats(selected_props)

func calculate_stats(list: Array[Prop]) -> void:
	var price = 0.0
	for prop in list: price += prop.cost
	if selection_label: selection_label.text = "Selected: " + str(list.size())
	if removal_label: removal_label.text = "Removal Cost: $" + str(price)

func clear_selection() -> void:
	for prop in selected_props:
		if is_instance_valid(prop): prop.set_highlight(false)
	selected_props.clear()
	calculate_stats([])

func delete_selected_props() -> void:
	var total_cost = 0.0
	for prop in selected_props:
		if is_instance_valid(prop):
			total_cost += prop.cost
			prop.queue_free()
	player_budget -= total_cost
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
			player_budget -= prop_node.cost
			prop_node.queue_free()
			update_budget_ui()

func update_budget_ui() -> void:
	if budget_label: budget_label.text = "Budget: $" + str(player_budget)

func toggle_top_down_mode() -> void:
	if not top_down_mode:
		button_top_down.text = "MODE: TOP DOWN"
		top_down_mode = true
		camera.rotation = Vector3(deg_to_rad(-90), 0, 0)
	else:
		button_top_down.text = "MODE: CLASSIC"
		top_down_mode = false
		camera.rotation = Vector3(deg_to_rad(-60), 0, 0)

func _on_close_inventory_button_pressed() -> void:
	pass