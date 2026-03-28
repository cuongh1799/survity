extends Node3D

func _ready():
	# This searches for the child named AnimationPlayer
	var anim = get_node_or_null("AnimationPlayer")
	if anim:
		anim.play("play")
	else:
		print("Error: Could not find AnimationPlayer node!")

	# Safety timer: delete after 0.5 seconds
	await get_tree().create_timer(0.5).timeout
	queue_free()
