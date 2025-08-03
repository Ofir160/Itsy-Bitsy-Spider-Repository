class_name InsectSpawner
extends Node

signal InsectCreated(insect : Insect)
signal WaspCreated(wasp : Wasp)

@export var frames : Array[FrameThread]
@export var Level_1 : Array[float]
@export var Level_2 : Array[float]
@export var Level_3 : Array[float]

@onready var insect_timer: Timer = $InsectTimer
@onready var wasp_timer: Timer = $WaspTimer

const MINIMUM_TIME : float = 2
const MAXIMUM_TIME : float = 60
const FRAME_LENGTH : float = 350.0

var threads : Array[SpiralThread]
var insects : Array[Insect]
var wasps : Array[Wasp]
var chosen_wasp_array : Array[float]
var wasp_number : int = 0

var current_time : float = 0

var waiting : bool
var insect_scene = preload("res://Scenes/insect.tscn")
var wasp_scene = preload("res://Scenes/wasp.tscn")

func _ready() -> void:
	if GameManager.playing:
		match GameManager.current_scene:
			1:
				chosen_wasp_array = Level_1
			4:
				chosen_wasp_array = Level_2
			8:
				chosen_wasp_array = Level_3
	wasp_timer.wait_time = chosen_wasp_array[0]
	wasp_timer.start()

func _on_spider_thread_created(thread: SpiralThread) -> void:
	threads.append(thread)
	
func _process(delta: float) -> void:
	current_time += delta
	if not waiting:
		var time_to_wait = randf_range(MINIMUM_TIME, MAXIMUM_TIME / (len(threads) + 1))
		insect_timer.wait_time = time_to_wait
		insect_timer.start()
		waiting = true
		
func create_insect(position : Vector2, rotation : float) -> void:
	var insect_instance = insect_scene.instantiate()
	get_tree().current_scene.add_child(insect_instance)
	insect_instance.desired_position = position
	insect_instance.desired_rotation = rotation
	insect_instance.init()
	insects.append(insect_instance)
	InsectCreated.emit(insect_instance)
	
func _on_spider_insect_eaten(insect: Insect) -> void:
	insect.destroy()
	insects.erase(insect)

func _on_insect_timer_timeout() -> void:
	# Make insect
	waiting = false
	var total_length : int = len(frames) + len(threads)
	var chosen_number = randi_range(0, total_length - 1)
	var chosen_point : Vector2
	var chosen_rotation : float = randf_range(0.0, 2.0 * PI)
	if chosen_number < len(frames):
		var pointA = Vector2(0.0, 0.0)
		var angle = frames[chosen_number].rotation
		var pointB = Vector2(FRAME_LENGTH * cos(angle), FRAME_LENGTH * sin(angle))
		var t : float = randf_range(0.0, 1.0)
		chosen_point = (1 - t) * pointA + t * pointB
	else:
		var thread : SpiralThread = threads[chosen_number - len(frames)]
		var t : float = randf_range(0.0, 1.0)
		chosen_point = (1 - t) * thread.PointA.position + t * thread.PointB.position
	create_insect(chosen_point, chosen_rotation)
	
func _on_wasp_timer_timeout() -> void:
	# Create wasp
	var wasp_instance = wasp_scene.instantiate()
	get_tree().current_scene.add_child(wasp_instance)
	WaspCreated.emit(wasp_instance)
	wasp_instance.init()
	wasp_instance.HitSpider.connect(spider_eaten)
	wasp_number += 1
	wasp_timer.wait_time = chosen_wasp_array[wasp_number]
	wasp_timer.start()

func spider_eaten() -> void:
	GameManager.game_over()
