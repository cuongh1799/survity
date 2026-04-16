extends Control

@onready var inventory_panel = $InventoryPanel
@onready var inventory_button = $InventoryButton
@onready var item_list = $InventoryPanel/inventoryContainer/ItemList

func _ready():
	# Make sure the inventory is hidden when the game starts
	inventory_panel.visible = false
	update_inventory_ui()

var _last_inventory_state: String = ""

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Constantly update the UI if the panel is open
	if inventory_panel.visible:
		var current_state = str(PlayerManager.inventory)
		if current_state != _last_inventory_state:
			_last_inventory_state = current_state
			update_inventory_ui()

func _on_inventory_button_pressed():
	inventory_panel.visible = true
	inventory_button.visible = false
	update_inventory_ui()
	# inventory_label.visible = false

# Connect this to your CloseinventoryButton's pressed() signal
func _on_close_inventory_button_pressed():
	inventory_panel.visible = false
	inventory_button.visible = true
	# inventory_label.visible = true

func update_inventory_ui() -> void:
	if not item_list: return
	
	# Clear the old list
	item_list.clear()
	
	# Add all items from PlayerManager.inventory
	for item_name in PlayerManager.inventory:
			var amount = PlayerManager.inventory[item_name]
			# To show only items you have, you would use: if amount > 0:
			var display_text = item_name.capitalize() + ": " + str(amount)
			item_list.add_item(display_text)

