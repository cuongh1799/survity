extends Node

var _recipes: Array[BuildingRecipe] = []


func _ready() -> void:
	_build_recipes()


func get_recipes() -> Array[BuildingRecipe]:
	return _recipes


func can_afford(recipe: BuildingRecipe) -> bool:
	if recipe == null:
		return false
	return PlayerManager.has_ingredients(recipe.ingredients)


func try_begin_craft(recipe: BuildingRecipe, camera: Node) -> bool:
	if not can_afford(recipe):
		return false
	if not PlayerManager.consume_ingredients(recipe.ingredients):
		return false
	if camera and camera.has_method("begin_crafted_spawn"):
		camera.begin_crafted_spawn(recipe.result_scene, recipe)
	elif camera:
		camera.test_spawn = recipe.result_scene
	return true


func format_ingredients(ing: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var keys := ing.keys()
	keys.sort()
	for k in keys:
		var amount = int(ing[k])
		if amount <= 0:
			continue
		parts.append("%s: %d" % [PlayerManager.resource_display_name(str(k)), amount])
	return ", ".join(parts)


func _build_recipes() -> void:
	_recipes.clear()
	_recipes.append_array([
		_recipe(
			"hut",
			"Housing",
			"res://assets/ui/png/house.png",
			"res://scenes/building_scene.tscn",
			{"wood": 8, "stone": 4, "dirt": 3}
		),
		_recipe(
			"lodge",
			"Wood lodge",
			"res://assets/ui/png/cabin.png",
			"res://scenes/buildingb.tscn",
			{"wood": 14, "sand": 6, "dirt": 2}
		),
		_recipe(
			"workshop",
			"Small workshop",
			"res://assets/ui/png/mechanics.png",
			"res://scenes/buildingc.tscn",
			{"wood": 10, "stone": 10, "coal": 5}
		),
		_recipe(
			"mine_station",
			"Mining station",
			"res://assets/ui/png/coal-factory.png",
			"res://scenes/building_scene.tscn",
			{"gold": 4, "silver": 4, "stone": 12, "wood": 8}
		),
		_recipe(
			"oil_tower",
			"Oil refinery tower",
			"res://assets/ui/png/oil-industry.png",
			"res://scenes/buildingc.tscn",
			{"oil": 8, "water": 10, "coal": 6, "stone": 8}
		),
		_recipe(
			"city_hall",
			"City Hall",
			"res://assets/ui/png/town-hall.png",
			"res://scenes/buildingb.tscn",
			{"gold": 6, "silver": 6, "wood": 18, "stone": 16, "coal": 8, "oil": 4, "sand": 8}
		),
	])


func _recipe(p_id: String, p_name: String, icon_path: String, scene_path: String, ing: Dictionary) -> BuildingRecipe:
	var r := BuildingRecipe.new()
	r.id = p_id
	r.display_name = p_name
	r.icon = load(icon_path) as Texture2D
	r.result_scene = load(scene_path) as PackedScene
	r.ingredients = ing.duplicate()
	return r
