class_name Spider
extends CharacterBody2D

@export var frames : Array[FrameThread]
@export var initial_frame : FrameThread
@export var origin_connection : Vector2
@onready var timer: Timer = $Timer

const SPEED = 200.0
const DEGREE_ERROR = 10 * PI / 180
const CONNECTION_ERROR = 20.0

var thread_scene = preload("res://Scenes/spiral_thread.tscn")
var current_frame : FrameThread
var current_thread : SpiralThread

var turning : bool
var desired_rotation : float
var starting_rotation : float

var spool_start : Vector2
var spool_thread : Line2D
var spooling : bool

func _ready() -> void:
	current_frame = initial_frame
	for frame in frames:
		frame.add_connection(origin_connection)

func _physics_process(delta: float) -> void:
	if not turning:
		if Input.is_action_pressed("MoveForward"):
			move(delta)
		if Input.get_axis("TurnLeft", "TurnRight") != 0:
			turn()
		if Input.is_action_just_pressed("Spool"):
			spool()
		if spooling:
			spool_thread.points[1].x = position.x
			spool_thread.points[1].y = position.y
			print(spool_thread.points)
		if Input.is_action_just_released("Spool"):
			if current_frame:
				# Finish the thread	
				pass
			else:
				# Delete the thread
				pass
	else:
		var t = (timer.wait_time - timer.time_left) / timer.wait_time
		rotation = lerp(starting_rotation, desired_rotation, t * t * (3 - 2 * t))

func move(delta : float) -> void:
	if current_frame:
		if correct_angle_frame(rotation) or correct_angle_frame(fmod(PI + rotation, 2.0 * PI)):
			var orientation : Vector2 = Vector2(cos(-rotation), sin(-rotation))
			position -= orientation * SPEED * delta
	else:
		pass
	 
func spool() -> void:
	spool_thread = Line2D.new()
	get_tree().current_scene.add_child(spool_thread)
	spool_start = position
	spool_thread.add_point(spool_start)
	spool_thread.add_point(position)
	spool_thread.default_color = Color.AQUA
	spool_thread.width = 2.5
	spool_thread.z_index = 4
	spooling = true
	
func turn() -> void:
	if current_frame:
		var chosen_connection : Vector2
		var connection_found : bool
		for connection in current_frame.connections:
			if (connection - position).length() < CONNECTION_ERROR:
				chosen_connection = connection
				connection_found = true
		if not connection_found:
			timer.start()
			turning = true
			if Input.get_axis("TurnLeft", "TurnRight") > 0:
				desired_rotation = PI + rotation
				starting_rotation = rotation
			else:
				desired_rotation = rotation - PI
				starting_rotation = rotation
		else:
			position = chosen_connection
			if Input.get_axis("TurnLeft", "TurnRight") > 0:
				# If we are turning right
				pass
			else:
				# If we are turning left
				pass

func change_thread() -> void:
	pass
	
func correct_angle_frame(angle : float) -> bool:
	return current_frame.rotation < (angle + DEGREE_ERROR)  and current_frame.rotation > angle - DEGREE_ERROR

func correct_angle_spiral() -> bool:
	return false

func _on_timer_timeout() -> void:
	turning = false
	timer.stop()
	rotation = fmod(desired_rotation, 2.0 * PI) 
	if rotation < 0:
		rotation += 2.0 * PI
