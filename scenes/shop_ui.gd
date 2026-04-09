extends Control

@export var shop_items: Array[PackedScene] = []
@export var button_template: PackedScene

@onready var shop_panel = $ShopPanel
@onready var shop_button = $ShopButton
@onready var shop_label = $ShopLabel
@onready var item_grid = $ShopPanel/ScrollContainer/ItemGrid

@export var cameraPath: NodePath
@onready var camera = get_node(cameraPath)

func _ready():
	shop_panel.visible = false
	populate_shop()

func populate_shop():
	for scene in shop_items:
		if scene:
			# Temporarily instantiate to grab the "Prop" data (cost, name)
			var temp_instance = scene.instantiate()
			
			if temp_instance is Prop:
				var new_btn = button_template.instantiate()
				item_grid.add_child(new_btn)
				
				# Format button text: "House ($10)"
				var building_name = scene.resource_path.get_file().get_basename().capitalize()
				new_btn.text = "%s ($%d)" % [building_name, temp_instance.cost]
				
				# Connect click signal
				new_btn.pressed.connect(_on_item_selected.bind(scene))
			
			# Clean up the temporary instance
			temp_instance.free()

func _on_item_selected(item_scene: PackedScene):
	if camera:
		# Assign the building scene to the camera's @export variable
		camera.test_spawn = item_scene
		print("Camera test_spawn set to: ", item_scene.resource_path)
	else:
		push_error("ShopUI: Camera node not found! Check your cameraPath.")

	# Optional: Close the shop after selecting an item
	close_shop()

func _on_shop_button_pressed():
	shop_panel.visible = true
	shop_button.visible = false
	shop_label.visible = false

func _on_close_shop_button_pressed():
	close_shop()

func close_shop():
	shop_panel.visible = false
	shop_button.visible = true
	shop_label.visible = true
