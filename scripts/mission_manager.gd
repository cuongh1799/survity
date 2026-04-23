extends Node

signal missions_changed

var props_harvested_total: int = 0
var crafted_buildings_count: int = 0
var city_hall_completed: bool = false


func _ready() -> void:
	PlayerManager.inventory_changed.connect(_on_inventory_changed)


func _on_inventory_changed() -> void:
	missions_changed.emit()


func register_before_harvest(prop: Prop) -> void:
	if prop == null:
		return
	props_harvested_total += 1
	missions_changed.emit()


func on_building_placed(recipe_id: String) -> void:
	if recipe_id != "":
		crafted_buildings_count += 1
	if recipe_id == "city_hall":
		city_hall_completed = true
	missions_changed.emit()


func get_mission_lines() -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("━━ Main missions ━━")
	lines.append(_line(city_hall_completed, "City", "Place City Hall (Craft -> pick City Hall -> place on the map)."))
	lines.append("")
	lines.append("━━ Side missions ━━")
	lines.append(_line(_water_ok(), "Water supply", "Keep at least 5 water in inventory."))
	lines.append(_line(_budget_ok(), "Healthy budget", "Reach budget of at least 80."))
	lines.append(_line(props_harvested_total >= 20, "Harvest streak", "Harvest 20 times total (click or box-select + Harvest)."))
	lines.append(_line(crafted_buildings_count >= 3, "Expansion", "Craft and successfully place 3 buildings from the Craft menu."))
	lines.append(_line(int(PlayerManager.inventory.get("wood", 0)) >= 50, "Timber stockpile", "Keep at least 50 wood in inventory."))
	return lines


func _line(done: bool, title: String, desc: String) -> String:
	var mark := "✓ " if done else "○ "
	return mark + title + "\n   " + desc


func _water_ok() -> bool:
	return int(PlayerManager.inventory.get("water", 0)) >= 5


func _budget_ok() -> bool:
	return PlayerManager.budget >= 80
