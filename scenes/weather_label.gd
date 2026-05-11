extends Label


func _ready() -> void:
	PlayerManager.weather_changed.connect(_on_weather_changed)
	PlayerManager.next_weather_determined.connect(_on_next_weather_determined)
	_update_weather_text(PlayerManager.current_weather, PlayerManager.next_weather)


func _on_weather_changed(new_weather: String) -> void:
	_update_weather_text(new_weather, PlayerManager.next_weather)


func _on_next_weather_determined(next_weather: String) -> void:
	_update_weather_text(PlayerManager.current_weather, next_weather)


func _update_weather_text(current: String, next: String) -> void:
	var current_display = _weather_display_name(current)
	var next_display = _weather_display_name(next)
	text = "Weather: %s → %s" % [current_display, next_display]


func _weather_display_name(weather: String) -> String:
	match weather:
		"crimson":
			return "Crimson"
		"rain":
			return "Rain"
		"plague":
			return "Plague"
		"clear":
			return "Clear"
		var other:
			return other.capitalize()
