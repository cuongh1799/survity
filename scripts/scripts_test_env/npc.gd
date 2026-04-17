extends CharacterBody3D

# for speed
const SPEED = 3.0

#State
enum State{ IDLE, WAITING_TO_MOVE, MOVE }
var state: State = State.IDLE

#Timer
var idle_wait_time: float = 3 #wait time
var idle_timer_count: float = 0 #internal countdown timer

#Node preferences
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var sophia_skin: SophiaSkin = $SophiaSkin


func _on_idle():
	sophia_skin.idle() #set up animation state
	velocity = Vector3.ZERO
	idle_timer_count = idle_wait_time
	state = State.WAITING_TO_MOVE

func _on_waiting(delta):
	sophia_skin.set_blink(false) #if the player wait to move, it blink
	#set timer to wait 
	idle_timer_count -= delta
	#time_out
	if idle_timer_count < 0:
		idle_timer_count = 0 #stop the timer
		
		var target = get_new_target_location()
		navigation_agent_3d.target_position = target
		
		state = State.MOVE

#Helper method to choose new location
func get_new_target_location() -> Vector3:
	# random location nearby
	var offset_x = randf_range(1.5, 3.5) * (-1 if randf() < 0.5 else 1)
	var offset_z = randf_range(1.5, 3.5) * (-1 if randf() < 0.5 else 1)
	# offset y = 0 to stop it from float
	
	#Vector3(offset_x, 0, offset_z)
	var target_loc = global_transform.origin + Vector3(offset_x, 0, offset_z)
	return target_loc
	
func _on_move():
	'''
	var current_pos = global_transform.origin
	var next_pos = navigation_agent_3d.get_next_path_position()
	var direction = (next_pos - current_pos).normalized()
	
	velocity = direction * SPEED
	#move_and_slide()
	sophia_skin.move()
	'''
	var current_pos = global_transform.origin
	var next_pos = navigation_agent_3d.get_next_path_position()

	var direction = next_pos - current_pos
	direction.y = 0

	if direction.length() > 0.1:
		direction = direction.normalized()
		velocity = direction * SPEED
		sophia_skin.move()
		#move_and_slide()
	else:
		velocity = Vector3.ZERO
	

func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			_on_idle()
		State.WAITING_TO_MOVE:
			_on_waiting(delta)
		State.MOVE:
			_on_move()
			
	

func _on_navigation_agent_3d_target_reached() -> void:
	print('success')
