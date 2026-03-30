extends Control

@onready var shop_panel = $ShopPanel

func _ready():
	# Make sure the shop is hidden when the game starts
	shop_panel.visible = false

# Connect this to your ShopButton's pressed() signal
func _on_shop_button_pressed():
	shop_panel.visible = true

# Connect this to your CloseShopButton's pressed() signal
func _on_close_shop_button_pressed():
	shop_panel.visible = false