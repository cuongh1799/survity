extends StaticBody3D

@onready var mesh = $RockShape/stone_tallA2 # Adjust this to match your child mesh name

@onready var selection_visual = $SelectionVisual

func _ready():
	# Make sure we are in the group for the camera script to find us
	add_to_group("props")
	# Start hidden
	if selection_visual:
		selection_visual.visible = false

func set_highlight(active: bool):
	if selection_visual:
		selection_visual.visible = active
## Called when the node enters the scene tree for the first time.
