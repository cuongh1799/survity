extends Prop

func _ready() -> void:
	super._ready()
	cost = 0.0
	drop_type = "food"
	drop_amount = 10
	generates_budget_per_sec = 0.0
	generate_item_type = "none" # might update later
	generate_item_amount = 0
	selection_visual.visible = false
