extends Panel

@onready var settings_panel = $"."
@onready var volume_slider = $VolumeSlider
@onready var mute_toggle = $MuteToggle
@onready var volume_label = $VolumeLabel
@onready var settings_button = get_parent().get_node("SettingsButton")

var is_muted: bool = false
var original_volume: float = 80.0

func _ready() -> void:
	# Hide the panel initially
	visible = false
	
	# Connect slider changes
	volume_slider.value_changed.connect(_on_volume_changed)
	mute_toggle.toggled.connect(_on_mute_toggled)
	
	# Load saved settings if they exist
	_load_settings()
	
	# Update UI with loaded values
	_update_volume_display()


func _unhandled_input(event: InputEvent) -> void:
	# Toggle settings panel with ESC key
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		visible = !visible
		get_tree().root.set_input_as_handled()


func _on_settings_button_pressed() -> void:
	visible = !visible


func _on_close_button_pressed() -> void:
	visible = false
	_save_settings()


func _on_volume_changed(value: float) -> void:
	# Convert slider value (0-100) to dB (-80 to 0)
	var db = linear_to_db(value / 100.0)
	
	# Set master bus volume
	var master_bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus_idx, db)
	
	_update_volume_display()


func _on_mute_toggled(pressed: bool) -> void:
	is_muted = pressed
	
	# Get master bus
	var master_bus_idx = AudioServer.get_bus_index("Master")
	
	if is_muted:
		# Mute by setting volume to very low
		AudioServer.set_bus_mute(master_bus_idx, true)
		volume_label.text = "Master Volume: MUTED"
	else:
		# Unmute and restore volume
		AudioServer.set_bus_mute(master_bus_idx, false)
		_on_volume_changed(volume_slider.value)


func _on_restart_button_pressed() -> void:
	# Save settings before restart
	_save_settings()
	
	# Reload the current scene
	get_tree().reload_current_scene()


func _update_volume_display() -> void:
	if not is_muted:
		volume_label.text = "Master Volume: %.0f%%" % volume_slider.value
	else:
		volume_label.text = "Master Volume: MUTED"


func _save_settings() -> void:
	# Save to a config file
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", volume_slider.value)
	config.set_value("audio", "is_muted", is_muted)
	config.save("user://settings.cfg")


func _load_settings() -> void:
	var config = ConfigFile.new()
	var error = config.load("user://settings.cfg")
	
	if error == OK:
		var saved_volume = config.get_value("audio", "master_volume", 80.0)
		var saved_muted = config.get_value("audio", "is_muted", false)
		
		volume_slider.value = saved_volume
		mute_toggle.button_pressed = saved_muted
		is_muted = saved_muted
		
		# Apply the saved settings
		_on_volume_changed(saved_volume)
		if saved_muted:
			var master_bus_idx = AudioServer.get_bus_index("Master")
			AudioServer.set_bus_mute(master_bus_idx, true)
	else:
		# Default values if no config exists
		volume_slider.value = 80.0
		mute_toggle.button_pressed = false
