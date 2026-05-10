extends Control
@onready var main_button: VBoxContainer = $Main_button
@onready var option_setting: Panel = $Option_Setting
@onready var game_manual: Panel = $GameManual
@onready var title: Label = $Title

@onready var budget_ui: Control = $"../BudgetUI"
@onready var mission_ui: Control = $"../MissionUI"
@onready var shop_ui: Control = $"../ShopUI"
@onready var inventory: Control = $"../Inventory"
@onready var coords_label: Label = $"../CoordsLabel"
@onready var top_view_button: Button = $"../TopViewButton"
@onready var harvest_button: Button = $"../HarvestButton"
@onready var interaction_prompt: Control = $"../InteractionPrompt"
@onready var minimap_ui: Control = $"../MinimapUI"
@onready var quit_button: Button = $"../Quit_button"
@onready var in_game_manual: Panel = $"../InGameManual"
@onready var game_manual_button: Button = $"../Game_manual_button"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	option_setting.visible = false
	game_manual.visible = false
	main_button.visible = true
	title.visible = true
	
	budget_ui.visible = false
	mission_ui.visible = false
	shop_ui.visible = false
	inventory.visible = false
	coords_label.visible = false
	top_view_button.visible = false
	interaction_prompt.visible = false
	minimap_ui.visible = false
	quit_button.visible = false
	in_game_manual.visible = false
	game_manual_button.visible = false


func _on_play_button_pressed() -> void:
	main_button.visible = false
	title.visible = false
	
	budget_ui.visible = true
	mission_ui.visible = true
	shop_ui.visible = true
	inventory.visible = true
	coords_label.visible = true
	top_view_button.visible = true
	interaction_prompt.visible = true
	minimap_ui.visible = true
	quit_button.visible = true
	game_manual_button.visible = true


func _on_option_button_pressed() -> void:
	option_setting.visible = true
	main_button.visible = false


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_back_buton_pressed() -> void:
	option_setting.visible = false
	main_button.visible = true


func _on_manual_pressed() -> void:
	game_manual.visible = true
	main_button.visible = false

func _on_back_button_manual_pressed() -> void:
	main_button.visible = true
	game_manual.visible = false
