class_name GoalLabel
extends RichTextLabel

@export var color : Color
var goal : int


func _ready() -> void:
	modulate = color
	
func init(min_star : int) -> void:
	goal = min_star
	text = str(goal)
