extends Control

const ICON_PATHS := {
	"wood": "res://assets/ui/png/res_wood.png",
	"stone": "res://assets/ui/png/res_stone.png",
	"oil": "res://assets/ui/png/res_oil.png",
	"water": "res://assets/ui/png/res_water.png",
	"dirt": "res://assets/ui/png/res_dirt.png",
	"sand": "res://assets/ui/png/res_sand.png",
	"gold": "res://assets/ui/png/res_gold.png",
	"silver": "res://assets/ui/png/res_silver.png",
	"coal": "res://assets/ui/png/res_coal.png",
	"food": "res://assets/ui/png/res_food.png",
	"iron": "res://assets/ui/png/res_iron.png",
	"bricks": "res://assets/ui/png/res_bricks.png",
	"planks": "res://assets/ui/png/res_planks.png",
	"tools": "res://assets/ui/png/res_tools.png",
	"glass": "res://assets/ui/png/res_glass.png",
	"concrete": "res://assets/ui/png/res_concrete.png",
	"electricity": "res://assets/ui/png/res_electricity.png",
}

@onready var inventory_panel = $InventoryPanel
@onready var inventory_button = $InventoryButton
@onready var resource_grid: GridContainer = $InventoryPanel/InventoryScroll/ResourceGrid


func _ready() -> void:
	inventory_panel.visible = false
	PlayerManager.inventory_changed.connect(_on_inventory_changed)


func _on_inventory_changed() -> void:
	if inventory_panel.visible:
		_refresh_grid()


func _refresh_grid() -> void:
	for c in resource_grid.get_children():
		c.queue_free()
	for key in PlayerManager.INVENTORY_UI_KEYS:
		var slot := _make_slot(str(key))
		resource_grid.add_child(slot)


func _make_slot(res_key: String) -> Control:
	var wrap := MarginContainer.new()
	wrap.custom_minimum_size = Vector2(100, 110)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_child(v)
	var tex := TextureRect.new()
	tex.custom_minimum_size = Vector2(48, 48)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var path: String = ICON_PATHS.get(res_key, "res://assets/ui/png/res_stone.png")
	var loaded = load(path)
	if loaded is Texture2D:
		tex.texture = loaded
	v.add_child(tex)
	var lbl := Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.text = "%s\n%d" % [PlayerManager.resource_display_name(res_key), int(PlayerManager.inventory.get(res_key, 0))]
	v.add_child(lbl)
	return wrap


func _on_inventory_button_pressed() -> void:
	inventory_panel.visible = true
	inventory_button.visible = false
	_refresh_grid()


func _on_close_inventory_button_pressed() -> void:
	inventory_panel.visible = false
	inventory_button.visible = true


func toggle_inventory_panel() -> void:
	if inventory_panel.visible:
		_on_close_inventory_button_pressed()
	else:
		_on_inventory_button_pressed()
