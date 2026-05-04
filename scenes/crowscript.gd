extends Node3D


@export var fly_speed: float = 15.0
@export var max_lifetime: float = 30.0

var lifetime_timer: float = 0.0

func _ready() -> void:
	# Add some slight randomness to the pitch/yaw so they don't all fly perfectly straight
	rotation.x += randf_range(-0.1, 0.1)
	rotation.y += randf_range(-0.2, 0.2)

func _process(delta: float) -> void:
	# Move the crow forward in its local Z direction
	translate(Vector3(0, 0, -fly_speed * delta))
	
	# Simulate a slight bobbing motion to mimic wings flapping
	position.y += sin(Time.get_ticks_msec() * 0.005) * 0.05
	
	# Clean up the crow after a certain time to prevent memory leaks
	lifetime_timer += delta
	if lifetime_timer >= max_lifetime:
		queue_free()