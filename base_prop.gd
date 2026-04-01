# extends StaticBody3D
# class_name Prop

# @export var cost: float = 10.0
# @onready var selection_visual = $SelectionVisual
# @onready var mesh_instance = $MeshInstance3D

# func _ready():
# 	# Automatically join the group so the camera script can find it
# 	add_to_group("props")
	
# 	if selection_visual:
# 		selection_visual.visible = false
# 		# Wait one frame to ensure the mesh is fully loaded before measuring it
# 		setup_selection_box.call_deferred()

# func setup_selection_box():
# 	if not mesh_instance or not mesh_instance.mesh:
# 		return
		
# 	# 1. Get the local bounding box of the mesh
# 	var aabb: AABB = mesh_instance.get_aabb()
	
# 	# 2. Scale the yellow box to match the model + a tiny bit of padding (0.1)
# 	selection_visual.scale = aabb.size + Vector3(0.1, 0.1, 0.1)
	
# 	# 3. Center the box (crucial if the mesh origin is at the feet/base)
# 	selection_visual.position = aabb.get_center()

# func set_highlight(active: bool):
# 	if selection_visual:
# 		selection_visual.visible = active
extends StaticBody3D
class_name Prop

@export var cost: float = 10.0
@export var profitPerSecond: float = 0

@onready var selection_visual = $SelectionVisual
@onready var mesh_instance = $MeshInstance3D

func _ready():
	add_to_group("props")
	
	if selection_visual:
		selection_visual.visible = false
		# We wait until the end of the frame to make sure the mesh is fully loaded
# 		setup_selection_box.call_deferred()

# func setup_selection_box():
# 	# Safety check: if there is no mesh, we can't calculate a box
# 	if not mesh_instance or not mesh_instance.mesh:
# 		return
		
# 	# 1. Get the AABB (The total rectangular area the mesh occupies)
# 	var aabb: AABB = mesh_instance.get_aabb()
	
# 	# 2. Scale the SelectionVisual to match the AABB size
# 	# We multiply by 1.02 to give it a tiny bit of "breathing room" 
# 	# so the yellow lines don't touch the leaves directly.
# 	selection_visual.scale = aabb.size * 1.02
	
# 	# 3. Align the SelectionVisual to the center of that volume
# 	# This fixes the "floating" issue by moving the box from the floor (0,0,0)
# 	# to the actual physical center of the tree/object.
# 	selection_visual.position = mesh_instance.position + aabb.get_center()

func set_highlight(active: bool):
	if selection_visual:
		selection_visual.visible = active