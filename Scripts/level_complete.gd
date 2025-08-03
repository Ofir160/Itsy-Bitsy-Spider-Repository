extends Node2D
	
func _on_replay_pressed() -> void:
	SceneSwitcher.switch_scene(GameManager.scenes[GameManager.current_scene])

func _on_continue_pressed() -> void:
	GameManager.finish_scene()
