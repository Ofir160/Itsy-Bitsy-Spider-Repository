extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var replay_sound: AudioStreamPlayer2D = $Replay/AudioStreamPlayer2D
@onready var continue_sound: AudioStreamPlayer2D = $Continue/AudioStreamPlayer2D

func _ready() -> void:
	var stars = GameManager.level_stars
	audio_stream_player.play()
	
	if stars == 1:
		animated_sprite.play("1 Star")
	elif stars == 2:
		animated_sprite.play("2 Star")
	elif stars == 3:
		animated_sprite.play("3 Star")
	
func _on_replay_pressed() -> void:
	replay_sound.play()
	SceneSwitcher.switch_scene(GameManager.scenes[GameManager.current_scene])

func _on_continue_pressed() -> void:
	continue_sound.play()
	GameManager.finish_scene()
