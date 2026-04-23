extends PanelContainer

signal craft_requested(recipe: BuildingRecipe)

var _recipe: BuildingRecipe

@onready var _icon: TextureRect = %Icon
@onready var _name_label: Label = %NameLabel
@onready var _ingredients_label: Label = %IngredientsLabel
@onready var _craft_btn: Button = %CraftButton


func setup(recipe: BuildingRecipe) -> void:
	_recipe = recipe
	if recipe == null:
		return
	_icon.texture = recipe.icon
	_name_label.text = recipe.display_name
	_ingredients_label.text = RecipeBook.format_ingredients(recipe.ingredients)
	_refresh_button()


func refresh_affordability() -> void:
	_refresh_button()


func _refresh_button() -> void:
	if _recipe == null:
		return
	var ok := RecipeBook.can_afford(_recipe)
	_craft_btn.disabled = not ok
	_craft_btn.modulate = Color(1, 1, 1, 1) if ok else Color(1, 1, 1, 0.42)


func _on_craft_button_pressed() -> void:
	if _recipe == null or not RecipeBook.can_afford(_recipe):
		return
	craft_requested.emit(_recipe)
