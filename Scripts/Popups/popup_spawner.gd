extends Node

const DISTANCE_ABOVE_PLAYER = 75.0

var fly_eaten_scene = preload("res://Scenes/Popups/fly_eaten.tscn")
var loop_completed_scene = preload("res://Scenes/Popups/loop_created.tscn")
var thread_built_scene = preload("res://Scenes/Popups/thread_built.tscn")

@onready var timer: Timer = $Timer
@export var spider : Spider

var instances : Array[Node2D]

func _ready() -> void:
	spider.InsectEaten.connect(insect_eaten)
	spider.LoopCreated.connect(loop_completed)
	spider.ThreadCreated.connect(thread_built)
	
func insect_eaten(insect : Insect) -> void:
	var instance = fly_eaten_scene.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.position = spider.position + Vector2.UP * DISTANCE_ABOVE_PLAYER
	instances.append(instance)
	timer.start()
	
func loop_completed() -> void:
	var instance = loop_completed_scene.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.position = spider.position + Vector2.UP * DISTANCE_ABOVE_PLAYER
	instances.append(instance)
	timer.start()
	
func thread_built(thread : SpiralThread) -> void:
	var instance = thread_built_scene.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.position = spider.position + Vector2.UP * DISTANCE_ABOVE_PLAYER
	instances.append(instance)
	timer.start()

func _on_timer_timeout() -> void:
	if len(instances) > 0:
		for instance in instances:
			instances.erase(instance)
			instance.queue_free()
