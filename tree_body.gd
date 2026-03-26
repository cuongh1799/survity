extends StaticBody3D

@onready var mesh = $TreeShape/tree_oak2 # Adjust this to match your child mesh name

#func set_highlight(active: bool):
	## This looks for the first MeshInstance3D inside the object
	#var mesh_node = find_child("*", true, false)
#
	## We check if it exists and is actually a MeshInstance3D
	#if mesh_node and mesh_node is MeshInstance3D:
		#mesh_node.transparency = 0.5 if active else 0.0
	#else:
		## If it's a Node3D 'wrapper', search one level deeper
		#for child in get_children():
			#var deep_mesh = child.find_child("*", true, false)
			#if deep_mesh is MeshInstance3D:
				#deep_mesh.transparency = 0.5 if active else 0.0
				#break
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
