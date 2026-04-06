extends Control
@onready var button_container: VBoxContainer = $MainButton
@onready var setting_menu: Panel = $SettingMenu


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$MainButton.visible = true
	$SettingMenu.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#change the scene to main play menu
func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://city_building_game.tscn")

#change to the setting pannel and hide the main button
func _on_setting_button_pressed() -> void:
	$MainButton.visible = false
	$SettingMenu.visible = true

# quit the game
func _on_quit_button_pressed() -> void:
	get_tree().quit()

# change back to the main menu, hide setting pannel
func _on_back_button_pressed() -> void:
	$MainButton.visible = true
	$SettingMenu.visible = false
