extends Button
@onready var in_game_manual: Panel = $"../InGameManual"


func _on_pressed() -> void:
	in_game_manual.visible = true
