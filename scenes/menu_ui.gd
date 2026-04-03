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


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://city_building_game.tscn")


func _on_setting_button_pressed() -> void:
	$MainButton.visible = false
	$SettingMenu.visible = true


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_back_button_pressed() -> void:
	$MainButton.visible = true
	$SettingMenu.visible = false
