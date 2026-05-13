extends Control

@onready var _container: SubViewportContainer = $Panel/SubViewportContainer
@onready var _sub: SubViewport = $Panel/SubViewportContainer/SubViewport
@onready var _cam: Camera3D = $Panel/SubViewportContainer/SubViewport/MinimapCamera
@onready var _dot: ColorRect = $Panel/SubViewportContainer/PlayerDot
@onready var _hint: Label = $Panel/HintLabel

var _expanded: bool = false
var _ortho_collapsed: float = 55.0
var _ortho_expanded: float = 170.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_container.gui_input.connect(_on_minimap_gui_input)


func _process(_delta: float) -> void:
	var p: Node3D = get_tree().get_first_node_in_group("player_city") as Node3D
	if p == null or _cam == null:
		return
	var pos := p.global_position
	_cam.global_position = Vector3(pos.x, 200.0, pos.z)
	_cam.global_rotation = Vector3(deg_to_rad(-90.0), 0.0, 0.0)
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = _ortho_expanded if _expanded else _ortho_collapsed
	if _dot:
		_dot.visible = true


func _input(event: InputEvent) -> void:
	if _expanded and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_set_expanded(false)
		get_viewport().set_input_as_handled()


func _on_minimap_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_set_expanded(not _expanded)


func _set_expanded(on: bool) -> void:
	_expanded = on
	var vs := get_viewport().get_visible_rect().size
	if on:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		offset_left = 0.0
		offset_top = 0.0
		offset_right = 0.0
		offset_bottom = 0.0
		_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		_container.offset_left = 32.0
		_container.offset_top = 48.0
		_container.offset_right = -32.0
		_container.offset_bottom = -32.0
		_container.custom_minimum_size = Vector2.ZERO
	else:
		set_anchors_preset(Control.PRESET_TOP_RIGHT)
		offset_left = -232.0
		offset_top = 8.0
		offset_right = -8.0
		offset_bottom = 232.0
		_container.set_anchors_preset(Control.PRESET_CENTER)
		_container.offset_left = -100.0
		_container.offset_top = -88.0
		_container.offset_right = 100.0
		_container.offset_bottom = 112.0
		_container.custom_minimum_size = Vector2(200, 200)
	if _sub:
		if on:
			_sub.size = Vector2i(int(vs.x * 0.94), int(vs.y * 0.86))
		else:
			_sub.size = Vector2i(200, 200)
	if _hint:
		_hint.text = "Minimap — click: full map | ESC: close" if on else "Minimap — click: overview | ESC: close"
