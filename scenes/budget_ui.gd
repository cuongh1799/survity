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
                # Calculate game time based on the day_timer (900 seconds = 24 hours)
                var progress_ratio = PlayerManager.day_timer / PlayerManager.SECONDS_PER_DAY
                var total_minutes = progress_ratio * 24.0 * 60.0
                
                var hours = int(total_minutes) / 60
                var minutes = int(total_minutes) % 60
                
                # Format to "Day X - 08:30"
                time_label.text = "Day %d - %02d:%02d" % [PlayerManager.current_day, hours, minutes]
