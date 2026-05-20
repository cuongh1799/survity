extends AudioStreamPlayer

func _ready() -> void:
	# Ensure the music loops infinitely
	bus = "BackgroundMusic"
	if not playing:
		play()

func _process(_delta: float) -> void:
	# Make sure music keeps playing
	# If stream finished, restart it
	if not playing and stream:
		play()
