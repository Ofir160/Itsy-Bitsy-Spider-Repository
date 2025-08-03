extends Node2D

@onready var audio_stream_player: AudioStreamPlayer2D = $Exit/AudioStreamPlayer2D

func _on_exit_pressed() -> void:
	audio_stream_player.play()
	GameManager.finish_scene()
