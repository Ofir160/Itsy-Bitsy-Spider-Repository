extends Node2D

@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	audio_stream_player.play()

func _on_try_again_pressed() -> void:
	SceneSwitcher.switch_scene(GameManager.scenes[GameManager.current_scene])
