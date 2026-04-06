extends HSlider

@export var sfx_bus_name: String #easier to chose bus name
var sfx_bus_id

func _ready() -> void:
	# get the id of the bus
	sfx_bus_id = AudioServer.get_bus_index(sfx_bus_name)

# When the value of the slider change, change the volume
func _on_value_changed(value: float) -> void:
	var db = linear_to_db(value) #change to db
	AudioServer.set_bus_volume_db(sfx_bus_id, db)
