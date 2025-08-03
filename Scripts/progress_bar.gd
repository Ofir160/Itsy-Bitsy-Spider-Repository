extends ProgressBar

const FLY_EATEN = 20
const THREAD_MADE = -20
var current_value : int = 100

@export var spider : Spider
@onready var timer: Timer = $Timer

func _ready() -> void:
	value = current_value

	
func _on_spider_insect_eaten(insect: Insect) -> void:
	current_value += FLY_EATEN
	update_value()


func _on_spider_thread_created(thread: SpiralThread) -> void:
	current_value += THREAD_MADE
	update_value()
	
func update_value() -> void:
	value = current_value
	if current_value <= 0:
		spider.silk_left = false
		timer.wait_time = GameManager.DYING_TIME
		timer.start()
	else:
		spider.silk_left = true

func _on_timer_timeout() -> void:
	GameManager.game_over()
