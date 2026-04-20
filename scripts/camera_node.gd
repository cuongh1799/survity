extends Node3D

const RainCtrl = preload("res://scripts/rain_controller.gd")
const PropPlacementCtrl = preload("res://scripts/prop_placement_controller.gd")
const SelectionCtrl = preload("res://scripts/selection_controller.gd")

@export_group("Movement")
@export var pan_speed: float = 0.05
@export var zoom_speed: float = 2.0
@export var min_zoom: float = 5.0
@export var max_zoom: float = 300.0

# ==== UI Nodes (Auto-linked via Relative Paths) ====
@onready var selection_box: Control = get_node_or_null("../CanvasLayer/SelectionBox")
@onready var selection_label: Label = get_node_or_null("../CanvasLayer/BudgetUI/SelectionCount")
@onready var removal_label: Label = get_node_or_null("../CanvasLayer/BudgetUI/RemovalCost")
@onready var budget_label: Label = get_node_or_null("../CanvasLayer/BudgetUI/BudgetLabel")
@onready var coords_label: Label = get_node_or_null("../CanvasLayer/CoordsLabel")
@onready var button_top_down: Button = get_node_or_null("../CanvasLayer/TopViewButton")

@export_group("Spawning")
@export var grid_size: float = 5.0 # Set this to 1.0 or 2.0 depending on your model size
@export var test_spawn: PackedScene
@onready var spawn_parent: Node3D = get_node_or_null("../PropSpawner")

@onready var camera = $Camera3D

var top_down_mode: bool = false
var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var drag_threshold: float = 5.0
var selected_props: Array = [] 

var ghost_instance: Node3D = null
var current_ghost_scene: PackedScene = null
var invalid_material: StandardMaterial3D

var rain_controller
var prop_placement_controller
var selection_controller

func _ready() -> void:
	invalid_material = StandardMaterial3D.new()
	invalid_material.albedo_color = Color(1.0, 0.0, 0.0, 0.5)
	invalid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	invalid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	update_budget_ui()
	# Default spawn parent to this node if not set
	if not spawn_parent:
		spawn_parent = self
		
	rain_controller = RainCtrl.new(self, camera)
	rain_controller.initialize()
	
	prop_placement_controller = PropPlacementCtrl.new(self, camera)
	selection_controller = SelectionCtrl.new(self, camera)

func _process(delta: float) -> void:
	if rain_controller:
		rain_controller.process(delta)

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
			selection_controller.clear_selection()
			dragging = true
			drag_start = event.position
		else:
			# If mouse didn't move much, it's a CLICK, not a DRAG
			if drag_start.distance_to(event.position) < drag_threshold:
				# If we have a scene to spawn, spawn it. Otherwise, try to delete.
				if test_spawn:
					prop_placement_controller.spawn_object_at_mouse(event.position)
				else:
					selection_controller.raycast_delete(event.position)
			else:
				selection_controller.confirm_selection()
				
			dragging = false
			selection_box.visible = false

	# Mouse Motion Logic
	if event is InputEventMouseMotion:
		update_mouse_coords(event.position)
		if dragging:
			selection_controller.update_selection_box(event.position)
			
		if test_spawn:
			prop_placement_controller.update_ghost_preview(event.position)
		elif ghost_instance:
			ghost_instance.queue_free()
			ghost_instance = null
			current_ghost_scene = null

	# Delete Action
	if event.is_action_pressed("ui_text_delete") or (event is InputEventKey and event.is_pressed() and event.keycode == KEY_DELETE):
		selection_controller.delete_selected_props()
		
	# Collect Action (Enter)
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.is_pressed() and event.keycode == KEY_ENTER):
		selection_controller.collect_selected_props()

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

func update_budget_ui() -> void:
	if budget_label:
		budget_label.text = "Budget: $" + str(PlayerManager.budget)

func toggle_top_down_mode() -> void:
	if top_down_mode == false:
		button_top_down.text = "MODE: TOP DOWN"
		top_down_mode = true
		camera.rotation = Vector3(deg_to_rad(-90), 0, 0)
	else:
		button_top_down.text = "MODE: CLASSIC"
		top_down_mode = false
		camera.rotation = Vector3(deg_to_rad(-60), 0, 0)

