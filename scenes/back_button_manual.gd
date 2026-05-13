extends Button
@onready var in_game_manual: Panel = $".."


func _on_pressed() -> void:
	in_game_manual.visible = false
