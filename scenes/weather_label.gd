extends Label


func _ready() -> void:
	PlayerManager.weather_changed.connect(_on_weather_changed)
	_update_weather_text(PlayerManager.current_weather)


func _on_weather_changed(new_weather: String) -> void:
	_update_weather_text(new_weather)


func _update_weather_text(weather: String) -> void:
	match weather:
		"crimson":
			text = "Weather: crimson"
		"rain":
			text = "Weather: Rain"
		"plague":
			text = "Weather: Plague"
		var other:
			text = "Weather: " + other
