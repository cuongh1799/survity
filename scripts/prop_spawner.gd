extends Node3D

# Use Arrays so you can drag multiple .tscn files in the Inspector
@export var tree_scenes: Array[PackedScene] = []
@export var rock_scenes: Array[PackedScene] = []
@export var spawn_count: int = 50
@export var area_size: float = 40.0

func _ready():
	spawn_props()

func spawn_props():
	# Combine all scenes into one big list of possibilities
	var all_possible_props = tree_scenes + rock_scenes
	
	if all_possible_props.is_empty():
		print("Warning: No scenes added to the PropSpawner arrays!")
		return

	for i in range(spawn_count):
		# Pick a random scene from the combined list
		var random_scene = all_possible_props.pick_random()
		
		if random_scene:
			var instance = random_scene.instantiate()
			add_child(instance)
			
			# Random position on the floor
			var random_pos = Vector3(
				randf_range(-area_size, area_size),
				0,
				randf_range(-area_size, area_size)
			)
			instance.global_position = random_pos
			
			# Random Rotation (Makes the city look more natural)
			instance.rotation.y = randf_range(0, TAU) # TAU is 360 degrees in radians
			
			# Force it into the "props" group
			instance.add_to_group("props")

# Press 'R' while playing to reset and spawn more
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		for child in get_children():
			child.queue_free()
		# Use 'call_deferred' to ensure old props are deleted before spawning new ones
		spawn_props.call_deferred()
