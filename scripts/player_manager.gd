extends Node

signal inventory_changed
signal weather_changed(new_weather: String)

# ---- Player Stats ----
var inventory: Dictionary = {
	"wood": 0,
	"stone": 0,
	"food": 0,
	"water": 0,
	"oil": 0,
	"dirt": 0,
	"sand": 0,
	"gold": 0,
	"silver": 0,
	"coal": 0,
	"iron": 0,
	"bricks": 0,
	"planks": 0,
	"tools": 0,
	"glass": 0,
	"concrete": 0,
	"electricity": 0,
}

const INVENTORY_UI_KEYS = [
	"wood", "stone", "oil", "water", "dirt", "sand", "gold", "silver", "coal",
	"food", "iron", "bricks", "planks", "tools", "glass", "concrete", "electricity",
]

var budget: int = 100
var total_city_attraction: int = 0

# ---- Time Tracking ----
const SECONDS_PER_DAY: float = 1 * 60.0
var current_day: int = 1
var day_timer: float = 0.0
var current_weather: String = "clear"
var _crow_spawn_timer: float = 0.0

const WEATHERS = ["clear", "rain", "plague", "crimson"]

func _ready() -> void:
	call_deferred("_apply_weather")

func _process(delta: float) -> void:
	_handle_time(delta)
	
	if current_weather == "plague":
		_crow_spawn_timer -= delta
		if _crow_spawn_timer <= 0.0:
			_crow_spawn_timer = randf_range(0.3, 1.5)
			_spawn_single_plague_crow()

func _spawn_single_plague_crow() -> void:
	var tree := get_tree()
	if not tree or not tree.current_scene: return
	
	var camera_node = tree.current_scene.get_node_or_null("CameraNode") as Node3D
	if not camera_node: return
	
	var crow = CROW_SCENE.instantiate()
	crow.add_to_group("plague_crows")
	tree.current_scene.add_child(crow)
	
	# Spawn crow around the camera's global focus point
	var base_pos = camera_node.global_position
	# Offset it so it starts a bit behind the camera view and flies across
	var offset_x = randf_range(-40, 40)
	var offset_z = randf_range(-30, 40)
	
	crow.global_position = base_pos + Vector3(offset_x, randf_range(5, 15), offset_z)
	
	# Random direction, generally flying across the screen
	crow.rotation.y = randf_range(0, TAU)

func _handle_time(delta: float) -> void:
	day_timer += delta
	if day_timer >= SECONDS_PER_DAY:
		day_timer -= SECONDS_PER_DAY
		current_day += 1
		_on_new_day()

func _on_new_day() -> void:
	print("A new day has started! Current Day: ", current_day)
	current_weather = WEATHERS[randi() % WEATHERS.size()]
	weather_changed.emit(current_weather)
	_apply_weather()

func _apply_weather() -> void:
	var tree := get_tree()
	if not tree: return
	var main_scene = tree.current_scene
	if not main_scene: return
	
	# Handle fog via WorldEnvironment
	var we := main_scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
	var dl := main_scene.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if we and we.environment:
		if current_weather == "rain":
			we.environment.volumetric_fog_enabled = false
			we.environment.fog_enabled = true
			we.environment.fog_density = 0.02
			we.environment.fog_light_color = Color(0.6, 0.6, 0.6)
			dl.light_color = Color8(255, 255, 255, 0.8)
		elif current_weather == "plague":
			we.environment.volumetric_fog_enabled = false
			we.environment.fog_enabled = true
			we.environment.fog_density = 0.03
			we.environment.fog_light_color = Color8(51, 151, 44, 204) # 204 is roughly 0.8 alpha # sickly green/gray
			dl.light_color = Color8(255, 255, 255, 0.8)
		elif current_weather == "crimson":
			we.environment.volumetric_fog_enabled = false
			we.environment.fog_enabled = true
			we.environment.fog_density = 0.03
			we.environment.fog_light_color = Color8(94, 15, 15, 0.8)
			dl.light_color = Color8(247, 0, 0, 0.8)
		elif current_weather == "clear":
			we.environment.volumetric_fog_enabled = false
			we.environment.fog_enabled = false
			dl.light_color = Color8(255, 255, 255, 0.8)
		# else:
		# 	dl.light_color = Color8(247, 0, 0, 0.8)
			
	# Handle Rain Node
	var rain_node = main_scene.get_node_or_null("CameraNode/Rain")
	if rain_node:
		rain_node.visible = (current_weather == "rain")
		
	# Handle Plague Crows - remove existing on state change
	for c in tree.get_nodes_in_group("plague_crows"):
		c.queue_free()

func has_ingredients(costs: Dictionary) -> bool:
	for k in costs.keys():
		var need := int(costs[k])
		if need <= 0:
			continue
		var have := int(inventory.get(k, 0))
		if have < need:
			return false
	return true


func consume_ingredients(costs: Dictionary) -> bool:
	if not has_ingredients(costs):
		return false
	for k in costs.keys():
		var need := int(costs[k])
		if need <= 0:
			continue
		inventory[k] = int(inventory.get(k, 0)) - need
	inventory_changed.emit()
	return true


func add_to_inventory(key: String, amount: int) -> void:
	if amount <= 0:
		return
	if not inventory.has(key):
		inventory[key] = 0
	inventory[key] = int(inventory[key]) + amount
	inventory_changed.emit()


func refund_ingredients(costs: Dictionary) -> void:
	for k in costs.keys():
		var amt := int(costs[k])
		if amt <= 0:
			continue
		if not inventory.has(k):
			inventory[k] = 0
		inventory[k] = int(inventory.get(k, 0)) + amt
	inventory_changed.emit()


static func resource_display_name(key: String) -> String:
	match key:
		"wood":
			return "Wood"
		"stone":
			return "Stone"
		"oil":
			return "Oil"
		"water":
			return "Water"
		"dirt":
			return "Dirt"
		"sand":
			return "Sand"
		"gold":
			return "Gold"
		"silver":
			return "Silver"
		"coal":
			return "Coal"
		"food":
			return "Food"
		"iron":
			return "Iron"
		"bricks":
			return "Bricks"
		"planks":
			return "Planks"
		"tools":
			return "Tools"
		"glass":
			return "Glass"
		"concrete":
			return "Concrete"
		"electricity":
			return "Electricity"
		_:
			return key.capitalize()

const CROW_SCENE = preload("res://scenes/crow.tscn")

