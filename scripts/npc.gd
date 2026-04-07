extends CharacterBody2D


const SPEED = 30.0

var dir = Vector2.RIGHT #direction of player
var start_pos #start position

var current_state = IDLE #get the state of the npc
var is_entering_building = false #check if npc enter building or not
var is_roaming = true #check for player roaming around the map

var npc # might change later on
var npc_in_building_zone = false #check if in the zone of the building or not

enum {
	IDLE, #stand still
	NEW_DIR, #change direction
	MOVE #move
}

#randomize an array
func choose(array):
	array.shuffle() #shuffle the array
	return array.front() # return the first one in the list

#call to move the npc
func move(delta):
	if !is_entering_building:
		position += dir * SPEED * delta

func _ready() -> void:
	randomize()
	start_pos = position

func _process(delta: float) -> void:
	#rendering the animation of the npc
	if current_state == 0 or current_state == 1:
		$animation_frame.play("idle")
	elif current_state == 2 and !is_entering_building:
		if dir.x == 1:
			$animation_frame.play("walk_e")
		if dir.x == -1:
			$animation_frame.play('walk_w')
		if dir.y == 1:
			$animation_frame.play("walk_s")
		if dir.y == -1:
			$animation_frame.play('walk_n')
	
	#checking the state of the npc
	if is_roaming:
		match current_state:
			IDLE:
				pass
			NEW_DIR:
				dir = choose([Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN])
			MOVE:
				move(delta)

#check if npc in the zone for building
func _on_building_detection_body_entered(body: Node2D) -> void:
	if body.has_method('npc'):
		npc = body
		npc_in_building_zone = true


func _on_building_detection_body_exited(body: Node2D) -> void:
	if body.has_method('npc'):
		npc_in_building_zone = false

# add random
func _on_timer_timeout() -> void:
	$Timer.wait_time = choose([0.5, 1, 1.5])
	current_state = choose([IDLE, NEW_DIR, MOVE])
