extends Control
@onready var main_button: VBoxContainer = $Main_button
@onready var option_setting: Panel = $Option_Setting
@onready var game_manual: Panel = $GameManual
@onready var title: Label = $Title


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	option_setting.visible = false
	main_button.visible = true
	game_manual.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_play_button_pressed() -> void:
	option_setting.visible = false
	main_button.visible = false
	title.visible = false
	game_manual.visible = false
	get_tree().change_scene_to_file("res://scenes/city_building_game.tscn")

func _on_option_button_pressed() -> void:
	option_setting.visible = true
	main_button.visible = false
	game_manual.visible = false


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_back_buton_pressed() -> void:
	option_setting.visible = false
	main_button.visible = true


func _on_manual_pressed() -> void:
	game_manual.visible = true
	option_setting.visible = false
	main_button.visible = false

func _on_back_button_manual_pressed() -> void:
	option_setting.visible = false
	main_button.visible = true
	game_manual.visible = false
