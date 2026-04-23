extends Node


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var shop := get_parent().get_node_or_null("ShopUI") as Control
	var inv := get_parent().get_node_or_null("Inventory") as Control
	if event.keycode == KEY_R and not event.shift_pressed:
		if shop and shop.has_method("toggle_shop_panel"):
			shop.toggle_shop_panel()
	elif event.keycode == KEY_T:
		if inv and inv.has_method("toggle_inventory_panel"):
			inv.toggle_inventory_panel()
