extends Button

var item_scene: PackedScene

func setup(scene: PackedScene):
    item_scene = scene
    # Set the button text to the filename of the scene (e.g., "House")
    text = scene.resource_path.get_file().get_basename()

func _on_pressed():
    # Signal your PropSpawner or Building Manager to start placing this item
    print("Selected to build: ", item_scene.resource_path)
    # GlobalSignal.emit_signal("item_selected", item_scene)