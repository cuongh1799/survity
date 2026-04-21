extends ProgressBar

var time_passed: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var rain_node = get_tree().root.find_child("Rain", true, false)
	
	time_passed += delta
	if time_passed >= 2.0:
		time_passed -= 2.0
		
		# Alternatively, you might want to check `if rain_node and rain_node.emitting:`
		if rain_node:
			value += max_value * 0.01
		else:
			value -= max_value * 0.01

