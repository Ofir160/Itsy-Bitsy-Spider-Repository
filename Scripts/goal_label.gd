class_name GoalLabel
extends RichTextLabel

@export var color : Color
var goal : int


func _ready() -> void:
	modulate = color
	text = str(goal)
