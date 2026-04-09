extends HSlider
@export var sfx_bus_name: String

var sfx_bus_id

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sfx_bus_id = AudioServer.get_bus_index(sfx_bus_name)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_value_changed(value: float) -> void:
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(sfx_bus_id,value)
