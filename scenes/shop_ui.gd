extends Control

@export var recipe_row_scene: PackedScene
@export var cameraPath: NodePath

@onready var shop_panel = $ShopPanel
@onready var shop_button = $ShopButton
@onready var shop_label = $ShopLabel
@onready var item_grid = $ShopPanel/ScrollContainer/ItemGrid

var _camera: Node


func _ready() -> void:
	_camera = get_node_or_null(cameraPath)
	shop_panel.visible = false
	PlayerManager.inventory_changed.connect(_on_inventory_changed)
	_populate_recipes()


func _on_inventory_changed() -> void:
	_refresh_all_rows()


func _populate_recipes() -> void:
	if recipe_row_scene == null:
		push_error("ShopUI: assign recipe_row_scene (recipe_row.tscn).")
		return
	for c in item_grid.get_children():
		c.queue_free()
	item_grid.columns = 1
	for recipe in RecipeBook.get_recipes():
		var row = recipe_row_scene.instantiate()
		item_grid.add_child(row)
		if row.has_method("setup"):
			row.setup(recipe)
		if row.has_signal("craft_requested"):
			row.craft_requested.connect(_on_craft_requested)


func _refresh_all_rows() -> void:
	for row in item_grid.get_children():
		if row.has_method("refresh_affordability"):
			row.refresh_affordability()


func _on_craft_requested(recipe: BuildingRecipe) -> void:
	if _camera == null:
		push_error("ShopUI: camera_path invalid.")
		return
	if not RecipeBook.try_begin_craft(recipe, _camera):
		return
	close_shop()


func _on_shop_button_pressed() -> void:
	shop_panel.visible = true
	shop_button.visible = false
	shop_label.visible = false
	_refresh_all_rows()


func _on_close_shop_button_pressed() -> void:
	close_shop()


func close_shop() -> void:
	shop_panel.visible = false
	shop_button.visible = true
	shop_label.visible = true


func toggle_shop_panel() -> void:
	if shop_panel.visible:
		close_shop()
	else:
		_on_shop_button_pressed()
