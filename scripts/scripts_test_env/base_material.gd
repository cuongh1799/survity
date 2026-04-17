extends StaticBody3D
class_name Materials

enum MATERIAL_TYPE{
	LOGS, GAS, STEEL
}

@export var quantity: float = 10.0
@export var material_type: MATERIAL_TYPE

@onready var selection_visual = $SelectionVisual
@onready var mesh_instance = $MeshInstance3D

func _ready():
	add_to_group("material")
	
	if selection_visual:
		selection_visual.visible = false

func set_highlight(active: bool):
	if selection_visual:
		selection_visual.visible = active
