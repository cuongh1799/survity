extends Node3D

# ---- Player Stats ----
var inventory: Dictionary = {
	"wood": 0,
	"stone": 0,
	"food": 0
}
var budget: int = 1000
var total_city_attraction: int = 0

# ---- Time Tracking ----
# 15 real-life minutes = 1 in-game day (900 seconds)
const SECONDS_PER_DAY: float = 15.0 * 60.0
var current_day: int = 1
var day_timer: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_handle_time(delta)

func _handle_time(delta: float) -> void:
	day_timer += delta
	if day_timer >= SECONDS_PER_DAY:
		day_timer -= SECONDS_PER_DAY
		current_day += 1
		_on_new_day()

func _on_new_day() -> void:
	print("A new day has started! Current Day: ", current_day)
	# Add daily logic here (e.g., taxes, attraction events, upkeep)
