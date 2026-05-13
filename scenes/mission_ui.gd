extends Control

@onready var _list: RichTextLabel = %MissionText


func _ready() -> void:
	MissionManager.missions_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if _list == null:
		return
	var lines := MissionManager.get_mission_lines()
	var body := "[b]MISSIONS[/b]\n\n"
	for i in lines.size():
		if i > 0:
			body += "\n"
		body += lines[i]
	_list.text = body
