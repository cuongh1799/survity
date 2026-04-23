extends StaticBody3D
class_name Prop

@export var cost: float = 10.0
@export var profitPerSecond: float = 0
@export var attraction: float = 0

@export_group("Harvesting / Drops")
# We match the spelling of the keys in PlayerManager.inventory
@export_enum(
	"none",
	"wood",
	"stone",
	"food",
	"water",
	"oil",
	"dirt",
	"sand",
	"gold",
	"silver",
	"coal",
	"iron",
	"bricks",
	"planks",
	"tools",
	"glass",
	"concrete",
	"electricity"
) var drop_type: String = "none"
@export var drop_amount: int = 0

@onready var selection_visual = $SelectionVisual
@onready var mesh_instance = $MeshInstance3D

func _ready():
	add_to_group("props")

	if selection_visual:
		selection_visual.visible = false

func set_highlight(active: bool):
	if selection_visual:
		selection_visual.visible = active

# Call this instead of queue_free() when "breaking" naturally spanning resources
func harvest() -> void:
	if drop_type != "none" and drop_amount > 0:
		PlayerManager.add_to_inventory(drop_type, drop_amount)
		print("Harvested ", drop_amount, " ", drop_type, "!")
	queue_free()
