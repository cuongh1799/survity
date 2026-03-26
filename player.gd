extends StaticBody3D

#func _input(event: InputEvent) -> void:
	#if(Input.is_action_pressed("click")):
		#var position2D = get_viewport().get_mouse_position()
		#var dropPlane  = Plane(Vector3(0, 0, 10), z)
		#var position3D = dropPlane.intersects_ray(camera.project_ray_origin(position2D),camera.project_ray_normal(position2D))
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
