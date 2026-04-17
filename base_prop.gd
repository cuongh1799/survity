extends StaticBody3D
class_name Prop

@export var cost: float = 10.0
@export var profitPerSecond: float = 0
@export var attraction: float = 0

@export_group("Harvesting / Drops")
# We match the spelling of the keys in PlayerManager.inventory
@export_enum("none", "wood", "stone", "food", "water", "iron", "gold", "bricks", "planks", "tools", "glass", "concrete", "electricity", "oil") var drop_type: String = "none"
@export var drop_amount: int = 0

@export_group("Over Time Generation")
@export var generates_budget_per_sec: float = 0.0 # How much money it makes
@export_enum("none", "wood", "stone", "food", "water", "iron", "gold", "bricks", "planks", "tools", "glass", "concrete", "electricity", "oil") var generate_item_type: String = "none"
@export var generate_item_amount: int = 0
@export var generation_interval_sec: float = 1.0 # How often it generates items/budget

@onready var selection_visual = $SelectionVisual
@onready var mesh_instance = $MeshInstance3D

var _generation_timer: float = 0.0
var stored_budget: float = 0.0
var stored_items: int = 0

func _ready():
		add_to_group("props")

		if selection_visual:
				selection_visual.visible = false

func _process(delta: float) -> void:
		# Only run the timer if this prop actually generates something
		if generates_budget_per_sec != 0.0 or (generate_item_type != "none" and generate_item_amount > 0):
				_generation_timer += delta
				if _generation_timer >= generation_interval_sec:
						_generation_timer -= generation_interval_sec
						_generate_resources()

func _generate_resources() -> void:
		# 1. Store Money Locally
		if generates_budget_per_sec != 0.0:
				stored_budget += generates_budget_per_sec 

		# 2. Store Items Locally
		if generate_item_type != "none" and generate_item_amount > 0:
				stored_items += generate_item_amount

# Call this when the player actively clicks/interacts to extract the stored items
func collect() -> void:
		var collected_anything: bool = false
		
		if stored_budget > 0:
				PlayerManager.budget += stored_budget
				print("Collected $", stored_budget, " from building.")
				stored_budget = 0.0
				collected_anything = true
				
		if stored_items > 0 and generate_item_type != "none":
				PlayerManager.inventory[generate_item_type] += stored_items
				print("Collected ", stored_items, " ", generate_item_type, " from building.")
				stored_items = 0
				collected_anything = true
				
		if not collected_anything:
				print("Nothing to collect yet.")

func set_highlight(active: bool):
		if selection_visual:
				selection_visual.visible = active

# Call this instead of queue_free() when "breaking" naturally spanning resources
func harvest() -> void:
		if drop_type != "none" and drop_amount > 0:
				PlayerManager.inventory[drop_type] += drop_amount
				print("Harvested ", drop_amount, " ", drop_type, "!")
		queue_free()
