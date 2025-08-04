extends Sprite2D

@export var dialogue_pngs : Array[Texture]
var current_texture : int = 0

func _ready() -> void:
	texture = dialogue_pngs[current_texture]

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("NextDialogue"):
		current_texture += 1
		if current_texture >= len(dialogue_pngs):
			GameManager.finish_scene()
		else:
			texture = dialogue_pngs[current_texture]
