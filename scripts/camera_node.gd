extends Node3D

@export_group("Movement Settings")
@export var pan_speed: float = 0.05
@export var zoom_speed: float = 2.0
@export var min_zoom: float = 5.0
@export var max_zoom: float = 100.0

@export_group("Selection Settings")
@export var selection_box_path: NodePath = "../CanvasLayer/SelectionBox"

@onready var camera = $Camera3D
@onready var selection_box = get_node(selection_box_path)

# Selection State
var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var drag_end: Vector2 = Vector2.ZERO
var drag_threshold: float = 5.0 # Pixels moved before box appears

func _unhandled_input(event: InputEvent) -> void:
	# 1. ZOOMING (Check this first so it doesn't conflict with clicks)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.position.y = clamp(camera.position.y - zoom_speed, min_zoom, max_zoom)
			camera.position.z = clamp(camera.position.z - zoom_speed, min_zoom, max_zoom)
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.position.y = clamp(camera.position.y + zoom_speed, min_zoom, max_zoom)
			camera.position.z = clamp(camera.position.z + zoom_speed, min_zoom, max_zoom)
			return

	# 2. PANNING (Right Click Drag)
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var movement = Vector3(-event.relative.x, 0, -event.relative.y) * pan_speed
		translate(movement)

	# 3. SELECTION BOX (Left Click Drag)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_start = event.position
			drag_end = event.position
		else:
			# If we barely moved the mouse, treat it as a single click delete
			if drag_start.distance_to(event.position) < drag_threshold:
				raycast_delete(event.position)
			#else:
				#delete_selected_props()
			
			# Reset everything on release
			dragging = false
			selection_box.visible = false
			selection_box.size = Vector2.ZERO

	# 4. DRAWING THE BOX
	if event is InputEventMouseMotion and dragging:
		drag_end = event.position
		update_selection_box()

func update_selection_box() -> void:
	# Only show box if we've moved past the threshold
	if drag_start.distance_to(drag_end) > drag_threshold:
		selection_box.visible = true
		var pos = Vector2(min(drag_start.x, drag_end.x), min(drag_start.y, drag_end.y))
		var size = (drag_start - drag_end).abs()
		selection_box.position = pos
		selection_box.size = size
		
		# Optional: Highlight items while dragging
		highlight_items_in_rect(Rect2(pos, size))

func highlight_items_in_rect(rect: Rect2) -> void:
	for prop in get_tree().get_nodes_in_group("props"):
		if prop is Node3D:
			var screen_pos = camera.unproject_position(prop.global_position)
			if rect.has_point(screen_pos):
				if prop.has_method("set_highlight"): prop.set_highlight(true)
			else:
				if prop.has_method("set_highlight"): prop.set_highlight(false)

func delete_selected_props() -> void:
	var rect = Rect2(selection_box.position, selection_box.size)
	#for prop in get_tree().get_nodes_in_group("props"):
		#if prop is Node3D:
			#var screen_pos = camera.unproject_position(prop.global_position)
			#if rect.has_point(screen_pos):
				#prop.queue_free()

func raycast_delete(mouse_pos: Vector2) -> void:
	var ray_length = 1000
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_object = result.collider
		if hit_object.is_in_group("props"):
			hit_object.queue_free()
