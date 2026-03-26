extends Node3D

@export var tree_scene: PackedScene
@export var rock_scene: PackedScene
@export var spawn_count: int = 50
@export var area_size: float = 40.0

func _ready():
	spawn_props()

func spawn_props():
	for i in range(spawn_count):
		# Randomly choose between tree and rock
		var prop_type = [tree_scene, rock_scene].pick_random()
		
		if prop_type:
			var instance = prop_type.instantiate()
			add_child(instance)
			
			# Random position on the floor
			var random_pos = Vector3(
				randf_range(-area_size, area_size),
				0,
				randf_range(-area_size, area_size)
			)
			instance.global_position = random_pos
			
			# Force it into the "props" group so the camera script sees it
			instance.add_to_group("props")

# Press 'R' while playing to reset and spawn more
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		for child in get_children():
			child.queue_free()
		spawn_props()
		
		
# THIS IS FOR TUTORIAL
func survival_days(food_stockpile:int, no_of_people:int) -> int:
	var day_survive = 0
	var food_consume = 2
	while(food_stockpile > 0):
		if(day_survive % 3 == 0):
			food_consume += 1
		food_stockpile -= food_consume * no_of_people
	return food_consume
	
