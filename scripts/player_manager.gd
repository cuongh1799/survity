extends Node

signal inventory_changed
signal weather_changed(new_weather: String)
signal next_weather_determined(next_weather: String)

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
var next_weather: String = "clear"
var _crow_spawn_timer: float = 0.0
var _effect_timer: float = 0.0

const WEATHERS = ["clear", "rain", "plague", "crimson"]

func _ready() -> void:
	next_weather = WEATHERS[randi() % WEATHERS.size()]
	next_weather_determined.emit(next_weather)
	call_deferred("_apply_weather")

func _process(delta: float) -> void:
	_handle_time(delta)
	_update_weather_bars(delta)
	_effect_timer += delta
	if _effect_timer >= 1.0:
		_effect_timer -= 1.0
		_apply_building_effects()
		print("Applying effects")
	
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
	current_weather = next_weather
	next_weather = WEATHERS[randi() % WEATHERS.size()]
	weather_changed.emit(current_weather)
	next_weather_determined.emit(next_weather)
	_apply_weather()

func _apply_weather() -> void:
	var tree := get_tree()
	if not tree: return
	var main_scene = tree.current_scene
	if not main_scene: return
	
	# Handle fog via WorldEnvironment
	var we := main_scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
	var dl := main_scene.get_node_or_null("DirectionalLight3D") as DirectionalLight3D

	# Handle progress bar
	var corrosionBar := main_scene.get_node_or_null("CanvasLayer/corrosionBar") as ProgressBar
	var crimeBar := main_scene.get_node_or_null("CanvasLayer/crimebar") as ProgressBar
	var toxicBar := main_scene.get_node_or_null("CanvasLayer/toxicBar") as ProgressBar

	# Handle lost
	var youlostpanel := main_scene.get_node_or_null("CanvasLayer/youlostpanel") as Panel

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

func _update_weather_bars(delta: float) -> void:
	var tree := get_tree()
	if not tree: return
	var main_scene = tree.current_scene
	if not main_scene: return
	
	# Get progress bars
	var corrosionBar := main_scene.get_node_or_null("CanvasLayer/corrosionBar") as ProgressBar
	var crimeBar := main_scene.get_node_or_null("CanvasLayer/crimeBar") as ProgressBar
	var toxicBar := main_scene.get_node_or_null("CanvasLayer/toxicBar") as ProgressBar

	var INCREASE_VALUE = 1.0
	
	# Scale factor based on day (higher on matching weather day, lower on others)
	var day_scale: float = float(current_day)
	var off_day_scale: float = 0.1  # 10% of day scale when not the matching weather
	
	# Update corrosion bar
	if current_weather == "rain" and corrosionBar:
		corrosionBar.value += delta * INCREASE_VALUE
	elif corrosionBar:
		corrosionBar.value -= delta * INCREASE_VALUE * off_day_scale
	
	# Update crime bar
	if current_weather == "crimson" and crimeBar:
		crimeBar.value += delta * INCREASE_VALUE
	elif crimeBar:
		crimeBar.value -= delta * INCREASE_VALUE * off_day_scale
	
	# Update toxic bar
	if current_weather == "plague" and toxicBar:
		toxicBar.value += delta * INCREASE_VALUE
	elif toxicBar:
		toxicBar.value -= delta * INCREASE_VALUE * off_day_scale
	
	# Check if any progress bar reached 100%
	if (corrosionBar and corrosionBar.value >= 100) or \
	   (crimeBar and crimeBar.value >= 100) or \
	   (toxicBar and toxicBar.value >= 100):
		_trigger_game_over()

func _trigger_game_over() -> void:
	var tree := get_tree()
	if not tree: return
	var main_scene = tree.current_scene
	if not main_scene: return
	
	# Show the you lost panel
	var youlostpanel := main_scene.get_node_or_null("CanvasLayer/youlostpanel") as Panel
	if youlostpanel:
		youlostpanel.visible = true
	
	# Pause the game to stop all processing
	tree.paused = true

func _apply_building_effects() -> void:
	var tree := get_tree()
	if not tree: return
	var main_scene = tree.current_scene
	if not main_scene: return
	
	# Get progress bars
	var corrosionBar := main_scene.get_node_or_null("CanvasLayer/corrosionBar") as ProgressBar
	var crimeBar := main_scene.get_node_or_null("CanvasLayer/crimeBar") as ProgressBar
	var toxicBar := main_scene.get_node_or_null("CanvasLayer/toxicBar") as ProgressBar
	
	# Get building effects
	var building_effects = _calculate_building_effects()
	
	# Apply building effects every second
	if corrosionBar and building_effects["corrosion_decrease"] > 0:
		corrosionBar.value -= building_effects["corrosion_decrease"]
		print("Applying corrosion decrease: %.1f" % building_effects["corrosion_decrease"])
	
	if crimeBar and building_effects["crime_decrease"] > 0:
		crimeBar.value -= building_effects["crime_decrease"]
		print("Applying crime decrease: %.1f" % building_effects["crime_decrease"])
	
	if toxicBar and building_effects["toxic_decrease"] > 0:
		toxicBar.value -= building_effects["toxic_decrease"]
		print("Applying toxic decrease: %.1f" % building_effects["toxic_decrease"])

func _calculate_building_effects() -> Dictionary:
	var effects = {
		"crime_decrease": 0.0,
		"toxic_decrease": 0.0,
		"corrosion_decrease": 0.0
	}
	
	# Get all props/buildings in the scene
	var tree := get_tree()
	if not tree: return effects
	
	for prop in tree.get_nodes_in_group("props"):
		if prop is Prop:
			effects["crime_decrease"] += prop.crime_decrease
			effects["toxic_decrease"] += prop.toxic_decrease
			effects["corrosion_decrease"] += prop.corrosion_decrease
	
	return effects

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

