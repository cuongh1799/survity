extends Panel

func _ready() -> void:
	# Connect the buttons
	get_node("RestartButton").pressed.connect(_on_restart_button_pressed)
	get_node("MainMenuButton").pressed.connect(_on_main_menu_button_pressed)


func _on_restart_button_pressed() -> void:
	# Reset the game state
	get_tree().paused = false
	
	# Reload the game scene
	get_tree().reload_current_scene()


func _on_main_menu_button_pressed() -> void:
	# Reset the game state
	get_tree().paused = false
	
	# Go back to main menu
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
