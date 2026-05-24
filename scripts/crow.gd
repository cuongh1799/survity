extends Node3D

@export var fly_speed: float = 15.0
@export var max_lifetime: float = 10.0

var lifetime_timer: float = 0.0

func _ready() -> void:
	rotation.x += randf_range(-0.1, 0.1)

func _process(delta: float) -> void:
	# Move the crow forward in its local Z direction like before
	translate(Vector3(0, 0, -fly_speed * delta))
	
	# Simulate a slight bobbing motion to mimic wings flapping
	position.y += sin(Time.get_ticks_msec() * 0.005) * 0.05
	
	# Since it is a continuous stream, just delete it after its lifetime expires
	lifetime_timer += delta
	if lifetime_timer >= max_lifetime:
		queue_free()
