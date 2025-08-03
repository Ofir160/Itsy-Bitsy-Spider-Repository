extends TextureButton

var muted : bool

func _on_pressed() -> void:
	muted = !muted
	if muted:
		var index = AudioServer.get_bus_index("Master")
		AudioServer.set_bus_mute(index, true)
	else:
		var index = AudioServer.get_bus_index("Master")
		AudioServer.set_bus_mute(index, false)
