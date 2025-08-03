extends Node2D

func _on_try_again_pressed() -> void:
	SceneSwitcher.switch_scene(GameManager.scenes[GameManager.current_scene])
