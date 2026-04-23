extends Node3D

@export_group("Movement")
@export var pan_speed: float = 0.05
@export var zoom_speed: float = 2.0
@export var min_zoom: float = 5.0
@export var max_zoom: float = 30.0

# ==== UI Nodes (Auto-linked via Relative Paths) ====
@onready var selection_box: Control = get_node_or_null("../CanvasLayer/SelectionBox")
@onready var selection_label: Label = get_node_or_null("../CanvasLayer/BudgetUI/SelectionCount")
@onready var removal_label: Label = get_node_or_null("../CanvasLayer/BudgetUI/RemovalCost")
@onready var budget_label: Label = get_node_or_null("../CanvasLayer/BudgetUI/BudgetLabel")
@onready var coords_label: Label = get_node_or_null("../CanvasLayer/CoordsLabel")
@onready var button_top_down: Button = get_node_or_null("../CanvasLayer/TopViewButton")
@onready var harvest_button: Button = get_node_or_null("../CanvasLayer/HarvestButton")

@export_group("Follow")
@export var follow_player_path: NodePath = NodePath("../Player")

@export_group("Spawning")
@export var grid_size: float = 5.0 # Set this to 1.0 or 2.0 depending on your model size
@export var test_spawn: PackedScene
## After crafting from materials, next placed building skips budget (materials already spent).
var skip_next_budget_deduction: bool = false
var pending_craft_recipe: BuildingRecipe = null
@onready var spawn_parent: Node3D = get_node_or_null("../PropSpawner")

@onready var camera = $Camera3D

var top_down_mode: bool = false
var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var drag_threshold: float = 5.0
var selected_props: Array[Prop] = [] 

var ghost_instance: Node3D = null
var current_ghost_scene: PackedScene = null
var invalid_material: StandardMaterial3D

var _follow_player: Node3D = null


func _ready() -> void:
	add_to_group("camera_controller")
	invalid_material = StandardMaterial3D.new()
	invalid_material.albedo_color = Color(1.0, 0.0, 0.0, 0.5)
	invalid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	invalid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	update_budget_ui()
	if not spawn_parent:
		spawn_parent = self
	if harvest_button:
		harvest_button.visible = false
		harvest_button.pressed.connect(_on_harvest_button_pressed)
	_follow_player = get_node_or_null(follow_player_path) as Node3D


func _process(delta: float) -> void:
	if _follow_player and is_instance_valid(_follow_player):
		var t := _follow_player.global_position
		global_position.x = lerpf(global_position.x, t.x, 4.0 * delta)
		global_position.z = lerpf(global_position.z, t.z, 4.0 * delta)

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

	# Left Click Logic (Selection vs. Spawning)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			clear_selection()
			dragging = true
			drag_start = event.position
		else:
			# If mouse didn't move much, it's a CLICK, not a DRAG
			if drag_start.distance_to(event.position) < drag_threshold:
				# If we have a scene to spawn, spawn it. Otherwise, try to delete.
				if test_spawn:
					spawn_object_at_mouse(event.position)
				else:
					raycast_delete(event.position)
			else:
				confirm_selection()
				
			dragging = false
			selection_box.visible = false

	# Mouse Motion Logic
	if event is InputEventMouseMotion:
		update_mouse_coords(event.position)
		if dragging:
			update_selection_box(event.position)
			
		if test_spawn:
			update_ghost_preview(event.position)
		elif ghost_instance:
			ghost_instance.queue_free()
			ghost_instance = null
			current_ghost_scene = null

	if event.is_action_pressed("ui_text_delete") or (event is InputEventKey and event.is_pressed() and event.keycode == KEY_DELETE):
		harvest_selected_props()

func spawn_object_at_mouse(mouse_pos: Vector2):
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 10000
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	
	if result and test_spawn:
		var instance = test_spawn.instantiate()
		
		var current_grid_size = grid_size
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
		# We check if this grid slot is already taken
		if is_grid_slot_occupied(final_pos, current_grid_size):
			print("Forbidden: Space already occupied!")
			instance.free()
			_refund_pending_craft_if_any()
			return
		
		get_tree().current_scene.add_child(instance)
		
		instance.global_position = final_pos
		instance.rotation = Vector3.ZERO
		
		var recipe_id := ""
		if pending_craft_recipe:
			recipe_id = pending_craft_recipe.id
			pending_craft_recipe = null
		
		if instance is Prop:
			if skip_next_budget_deduction:
				skip_next_budget_deduction = false
			else:
				PlayerManager.budget -= instance.cost
			update_budget_ui()
		
		MissionManager.on_building_placed(recipe_id)

		test_spawn = null
		if ghost_instance:
			ghost_instance.queue_free()
			ghost_instance = null
		current_ghost_scene = null

# New helper function to scan for nearby objects
func is_grid_slot_occupied(target_pos: Vector3, current_grid_size: float = grid_size) -> bool:
	# Look at every object in the "props" group
	for prop in get_tree().get_nodes_in_group("props"):
		if is_instance_valid(prop) and prop is Node3D:
			# Calculate distance between the click and existing props
			var distance = prop.global_position.distance_to(target_pos)
			
			# If distance is smaller than the grid size, they are overlapping
			# We use current_grid_size * 0.9 to be safe with floating point math
			if distance < (current_grid_size * 0.9):
				return true
	return false

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
	_update_harvest_button_visibility()

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
	if harvest_button:
		harvest_button.visible = false

func harvest_selected_props() -> void:
	for prop in selected_props.duplicate():
		if is_instance_valid(prop):
			PlayerManager.budget += prop.cost
			if prop.has_method("harvest"):
				MissionManager.register_before_harvest(prop)
				prop.harvest()
			else:
				prop.queue_free()
	selected_props.clear()
	for p in get_tree().get_nodes_in_group("props"):
		if p is Prop and is_instance_valid(p):
			(p as Prop).set_highlight(false)
	calculate_stats([])
	update_budget_ui()
	if harvest_button:
		harvest_button.visible = false


func raycast_delete(mouse_pos: Vector2) -> void:
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result:
		var target = result.collider
		var prop_node = target if target is Prop else target.get_parent()
		if prop_node is Prop:
			PlayerManager.budget += prop_node.cost
			if prop_node.has_method("harvest"):
				MissionManager.register_before_harvest(prop_node)
				prop_node.harvest()
			else:
				prop_node.queue_free()
			update_budget_ui()

func update_budget_ui() -> void:
	if budget_label:
		budget_label.text = "Budget: $" + str(PlayerManager.budget)

func begin_crafted_spawn(scene: PackedScene, recipe: BuildingRecipe = null) -> void:
	skip_next_budget_deduction = recipe != null
	test_spawn = scene
	pending_craft_recipe = recipe


func _refund_pending_craft_if_any() -> void:
	if pending_craft_recipe:
		PlayerManager.refund_ingredients(pending_craft_recipe.ingredients)
		pending_craft_recipe = null


func _update_harvest_button_visibility() -> void:
	if harvest_button:
		harvest_button.visible = selected_props.size() > 0


func _on_harvest_button_pressed() -> void:
	harvest_selected_props()


func toggle_top_down_mode() -> void:
	# TOP DOWN MODE
	if top_down_mode == false:
		button_top_down.text = "MODE: TOP DOWN"
		top_down_mode = true
		print("Change from classic to top")
		camera.rotation = Vector3(deg_to_rad(-90), 0, 0)
	# CLASSIC MODE
	elif top_down_mode == true:
		button_top_down.text = "MODE: CLASSIC"
		top_down_mode = false
		print("Change from top to classic")
		camera.rotation = Vector3(deg_to_rad(-60), 0, 0)
		


func _on_close_inventory_button_pressed() -> void:
	pass # Replace with function body.

func update_ghost_preview(mouse_pos: Vector2) -> void:
	# Keep ghost updated if the test_spawn scene changes
	if current_ghost_scene != test_spawn:
		if ghost_instance:
			ghost_instance.queue_free()
		ghost_instance = test_spawn.instantiate()
		
		# Add to the current scene so it displays correctly, but outside of 'props'
		add_child(ghost_instance)
		current_ghost_scene = test_spawn
		make_ghost_recursive(ghost_instance)
		
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 10000
	var query = PhysicsRayQueryParameters3D.create(from, to)
	# Exclude layer or mask if you use one, but the ghost has collisions disabled so it shouldn't block
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	
	if result:
		ghost_instance.visible = true
		
		var current_grid_size = grid_size
		if ghost_instance.has_node("MeshInstance3D"):
			var mesh = ghost_instance.get_node("MeshInstance3D")
			if mesh is MeshInstance3D and mesh.mesh:
				var aabb = mesh.get_aabb()
				var mesh_scale = mesh.scale
				current_grid_size = max(max(aabb.size.x * mesh_scale.x, aabb.size.z * mesh_scale.z), 1.0)
				current_grid_size = ceil(current_grid_size)
				
		var snapped_x = round(result.position.x / current_grid_size) * current_grid_size
		var snapped_z = round(result.position.z / current_grid_size) * current_grid_size
		var final_pos = Vector3(snapped_x, 0, snapped_z)
		
		ghost_instance.global_position = final_pos
		ghost_instance.rotation = Vector3.ZERO
		
		var is_occupied = is_grid_slot_occupied(final_pos, current_grid_size)
		set_ghost_color(ghost_instance, not is_occupied)
	else:
		ghost_instance.visible = false

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
			node.material_overlay = invalid_material
	for child in node.get_children():
		set_ghost_color(child, is_valid)
