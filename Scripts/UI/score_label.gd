class_name ScoreLabel
extends RichTextLabel

@export var color : Color
var score : int

func _ready() -> void:
	modulate = color
	reset_score()

func update_score() -> void:
	text = str(score)

func change_score(amount : int) -> void:
	score += amount
	update_score()

func reset_score() -> void:
	score = 0
	update_score()
