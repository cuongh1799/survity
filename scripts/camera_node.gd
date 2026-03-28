extends Node3D

@export_group("Movement")
@export var pan_speed: float = 0.05
@export var zoom_speed: float = 2.0
@export var min_zoom: float = 5.0
@export var max_zoom: float = 100.0

@export_group("UI Nodes")
@export var selection_box_path: NodePath
@export var selection_label_path: NodePath
@export var removal_label_path: NodePath

@onready var camera = $Camera3D
@onready var selection_box = get_node(selection_box_path)
@onready var selection_label = get_node(selection_label_path)
@onready var removal_label = get_node(removal_label_path)

var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var drag_threshold: float = 5.0
var selected_props: Array[Node3D] = []

func _unhandled_input(event: InputEvent) -> void:
	# 1. Zoom Logic
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.position.y = clamp(camera.position.y - zoom_speed, min_zoom, max_zoom)
			camera.position.z = clamp(camera.position.z - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.position.y = clamp(camera.position.y + zoom_speed, min_zoom, max_zoom)
			camera.position.z = clamp(camera.position.z + zoom_speed, min_zoom, max_zoom)

	# 2. Pan Logic (Right Click)
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		translate(Vector3(-event.relative.x, 0, -event.relative.y) * pan_speed)

	# 3. Selection Box Logic (Left Click)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			clear_selection()
			dragging = true
			drag_start = event.position
		else:
			if drag_start.distance_to(event.position) < drag_threshold:
				raycast_delete(event.position)
			else:
				confirm_selection()
			dragging = false
			selection_box.visible = false

	# 4. Box Drawing
	if event is InputEventMouseMotion and dragging:
		update_selection_box(event.position)

	# 5. Delete Action
	if event.is_action_pressed("ui_text_delete") or (event is InputEventKey and event.keycode == KEY_DELETE):
		delete_selected_props()

func update_selection_box(drag_end: Vector2) -> void:
	if drag_start.distance_to(drag_end) > drag_threshold:
		selection_box.visible = true
		var pos = Vector2(min(drag_start.x, drag_end.x), min(drag_start.y, drag_end.y))
		var size = (drag_start - drag_end).abs()
		selection_box.global_position = pos
		selection_box.size = size
		highlight_items_in_rect(Rect2(pos, size))

func highlight_items_in_rect(rect: Rect2) -> void:
	var current_hovered: Array[Node3D] = []
	for prop in get_tree().get_nodes_in_group("props"):
		if prop is Node3D and not camera.is_position_behind(prop.global_position):
			var screen_pos = camera.unproject_position(prop.global_position)
			var is_inside = rect.has_point(screen_pos)
			prop.set_highlight(is_inside)
			if is_inside: current_hovered.append(prop)
	
	calculate_stats(current_hovered)

func confirm_selection() -> void:
	selected_props.clear()
	var rect = Rect2(selection_box.global_position, selection_box.size)
	for prop in get_tree().get_nodes_in_group("props"):
		if prop is Node3D and not camera.is_position_behind(prop.global_position):
			if rect.has_point(camera.unproject_position(prop.global_position)):
				selected_props.append(prop)
				prop.set_highlight(true)
	calculate_stats(selected_props)

func calculate_stats(list: Array[Node3D]) -> void:
	var price = 0
	for prop in list:
		# Using if/elif is safer and avoids the match constant error
		if prop is TreeClass:
			price += 2
		elif prop is RockClass:
			price += 1
	
	if selection_label: 
		selection_label.text = "Selected: " + str(list.size())
	if removal_label: 
		removal_label.text = "Removal Cost: $" + str(price)

func clear_selection() -> void:
	for prop in selected_props:
		if is_instance_valid(prop): prop.set_highlight(false)
	selected_props.clear()
	calculate_stats([])

func delete_selected_props() -> void:
	for prop in selected_props:
		if is_instance_valid(prop): prop.queue_free()
	selected_props.clear()
	calculate_stats([])

func raycast_delete(mouse_pos: Vector2) -> void:
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	
	if result and (result.collider.is_in_group("props") or result.collider.get_owner().is_in_group("props")):
		result.collider.queue_free()
