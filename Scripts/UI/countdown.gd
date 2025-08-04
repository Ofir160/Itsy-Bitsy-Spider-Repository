extends RichTextLabel

const TIME_PER_LEVEL = 180

@onready var scoreboard: Scoreboard = $"../Scoreboard"
@export var color : Color
@onready var timer: Timer = $Timer
var time_left : int

func _ready() -> void:
	modulate = color
	timer.start()
	time_left = TIME_PER_LEVEL

func _on_timer_timeout() -> void:
	timer.start()
	time_left -= 1
	if time_left <= 0:
		var stars = scoreboard.check_stars()  
		if stars == 0:
			SceneSwitcher.switch_scene(GameManager.game_over_scene)
		else:
			GameManager.complete_level(stars)
	var seconds = time_left % 60
	if seconds < 10:
		text = str(floor(time_left / 60)) + ":" + "0" + str(seconds)
	else:
		text = str(floor(time_left / 60)) + ":" + str(seconds)
