extends Control

@onready var inventory_panel = $InventoryPanel
@onready var inventory_button = $InventoryButton
@onready var inventory_label = $InventoryLabel

func _ready():
	# Make sure the inventory is hidden when the game starts
	inventory_panel.visible = false

# Connect this to your inventoryButton's pressed() signal
func _on_inventory_button_pressed():
	inventory_panel.visible = true
	inventory_button.visible = false
	# inventory_label.visible = false

# Connect this to your CloseinventoryButton's pressed() signal
func _on_close_inventory_button_pressed():
	inventory_panel.visible = false
	inventory_button.visible = true
	# inventory_label.visible = true
