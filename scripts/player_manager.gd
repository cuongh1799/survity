extends Node

signal inventory_changed

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
const SECONDS_PER_DAY: float = 5 * 60.0
var current_day: int = 1
var day_timer: float = 0.0


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_handle_time(delta)


func _handle_time(delta: float) -> void:
	day_timer += delta
	if day_timer >= SECONDS_PER_DAY:
		day_timer -= SECONDS_PER_DAY
		current_day += 1
		_on_new_day()


func _on_new_day() -> void:
	print("A new day has started! Current Day: ", current_day)


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
