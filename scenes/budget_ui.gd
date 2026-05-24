extends Control

@onready var budget_label = $BudgetLabel
@onready var time_label = $TimeLabel # Create a Label named "TimeLabel" as a child of BudgetUI

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
		if budget_label:
				budget_label.text = "Budget: $" + str(PlayerManager.budget)
				
		if time_label:
				# Calculate game time to show MM:SS up to 5:00
				var total_seconds = PlayerManager.day_timer
				var mins = int(total_seconds) / 60
				var secs = int(total_seconds) % 60
				
				# Format to "Day X - 05:00"
				time_label.text = "Day %d - %02d:%02d" % [PlayerManager.current_day, mins, secs]
