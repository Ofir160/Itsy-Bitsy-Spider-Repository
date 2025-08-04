class_name Scoreboard
extends Sprite2D

@onready var score_label: ScoreLabel = $ScoreLabel
@onready var goal_label: GoalLabel = $GoalLabel
@export var one_star : int
@export var two_star : int
@export var three_star : int

func _ready() -> void:
	goal_label.init(one_star)

func _on_spider_insect_eaten(insect: Insect) -> void:
	score_label.change_score(10)

func _on_spider_thread_created(thread: SpiralThread) -> void:
	score_label.change_score(100)

func _on_spider_loop_created() -> void:
	score_label.change_score(200)

func check_stars() -> int:
	if score_label.score > one_star:
		if score_label.score > two_star:
			if score_label.score > three_star:
				return 3
			else:
				return 2
		else:
			return 1
	else:
		return 0
