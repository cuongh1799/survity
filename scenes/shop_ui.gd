extends Control

@onready var shop_panel = $ShopPanel
@onready var shop_button = $ShopButton
@onready var shop_label = $ShopLabel

func _ready():
	# Make sure the shop is hidden when the game starts
	shop_panel.visible = false

# Connect this to your ShopButton's pressed() signal
func _on_shop_button_pressed():
	shop_panel.visible = true
	shop_button.visible = false
	shop_label.visible = false

# Connect this to your CloseShopButton's pressed() signal
func _on_close_shop_button_pressed():
	shop_panel.visible = false
	shop_button.visible = true
	shop_label.visible = true