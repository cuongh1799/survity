class_name SophiaSkin extends Node3D

@onready var animation_tree = %AnimationTree
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
@onready var move_tilt_path : String = "parameters/StateMachine/Move/tilt/add_amount"

var run_tilt = 0.0 : set = _set_run_tilt

@export var blink = true : set = set_blink
@onready var blink_timer = %BlinkTimer
@onready var closed_eyes_timer = %ClosedEyesTimer
@onready var eye_mat = $sophia/rig/Skeleton3D/Sophia.get("surface_material_override/2")


const SPEED = 4.0 # for the speed of the npc
var velocity = Vector3.ZERO

# for the npc path
@onready var nav_agent = $NavigationRegion3D

func _ready():
	blink_timer.connect("timeout", func():
		eye_mat.set("uv1_offset", Vector3(0.0, 0.5, 0.0))
		closed_eyes_timer.start(0.2)
		)
		
	closed_eyes_timer.connect("timeout", func():
		eye_mat.set("uv1_offset", Vector3.ZERO)
		blink_timer.start(randf_range(1.0, 4.0))
		)
'''
func _process(delta: float) -> void:
	velocity = Vector3.ZERO
	 # Set target (e.g., player's position)
	#nav_agent.target_position = global_position
	
	# Calculate movement direction
	var current_pos = global_position
	var next_path_pos = nav_agent.get_next_path_position()
	var direction = (next_path_pos - current_pos).normalized()

	# Apply movement
	velocity = direction * SPEED
'''

func _physics_process(delta):
	# Define horizontal movement (X and Z axes)
	var direction = Vector3(1, 0, 0) # Example: moving along X axis
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	# Call the function with NO arguments
	#move_and_slide()

# All the animation set up
func set_blink(state : bool):
	if blink == state: return
	blink = state
	if blink:
		blink_timer.start(0.2)
	else:
		blink_timer.stop()
		closed_eyes_timer.stop()

func _set_run_tilt(value : float):
	run_tilt = clamp(value, -1.0, 1.0)
	animation_tree.set(move_tilt_path, run_tilt)

func idle():
	state_machine.travel("Idle")

func move():
	state_machine.travel("Move")

func fall():
	state_machine.travel("Fall")

func jump():
	state_machine.travel("Jump")

func edge_grab():
	state_machine.travel("EdgeGrab")

func wall_slide():
	state_machine.travel("WallSlide")
