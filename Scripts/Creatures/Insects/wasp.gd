class_name Wasp
extends Area2D

signal HitSpider

@onready var timer: Timer = $Timer

const WALK_SPEED = 100.0
const DASH_SPEED = 500.0
const SPAWN_ERROR = 20.0
const DASH_ERROR = 20.0
const SPAWN_MULTIPLIER = 100.0
const TRACKING_TIME = 2.0
const WIGGLING_TIME = 3.0
const IDLE_TIME = 3.0
const DASH_LIMIT = 5.0
const WIGGLING_STRENGTH = 2.0
const WIGGLING_GROWTH = 2.0
const WIGGLING_FREQUENCY = 10.0

var spider : Spider
var camera_dimensions : Vector2
var starting_pos : Vector2
var starting_pos_norm : Vector2
var dashing_target : Vector2
var dash_orientation : Vector2
var dash_end : Vector2
var dash_count : int
var dash_rotation : float
var time_elapsed_wiggling : float

var current_time : float

var dashing : bool
var tracking : bool
var walking : bool
var idle : bool
var wiggling : bool
var dead : bool

func _ready() -> void:
	camera_dimensions = get_viewport().size
	
func init() -> void:
	var spawn_on_side : bool = randf() > 0.5
	var left_right : bool = randf() > 0.5
	var x : float
	var y : float
	if spawn_on_side:
		if left_right:
			x = camera_dimensions.x / 2
		else:
			x = -camera_dimensions.x / 2
		y = randf_range(camera_dimensions.y / 2, -camera_dimensions.y / 2)
	else:
		if left_right:
			y = -camera_dimensions.y / 2
		else:
			y = camera_dimensions.y / 2
		x = randf_range(-camera_dimensions.x , camera_dimensions.x / 2)
	starting_pos = Vector2(x, y)
	starting_pos_norm = starting_pos.normalized()
	position = starting_pos + starting_pos_norm * 100.0
	rotation = find_angle_from_two_positions(position, Vector2.ZERO)
	walking = true
	
func _process(delta: float) -> void:
	if spider:
		if walking:
			walk(delta)
		elif tracking:
			track()
		elif dashing:
			dash(delta)
		elif wiggling:
			time_elapsed_wiggling += delta
			wiggle()

func walk(delta : float) -> void:
	position -= starting_pos_norm * delta * WALK_SPEED
	if (position - (starting_pos - starting_pos_norm * 150.0)).length() < SPAWN_ERROR:
		walking = false
		
		# Start tracking
		tracking = true
		timer.wait_time = TRACKING_TIME
		timer.start()

func track() -> void:
	rotation = find_angle_from_two_positions(position, spider.position)
	# wiggle

func dash(delta : float) -> void:
	position += dash_orientation * delta * DASH_SPEED
	if (position - dash_end).length() < DASH_ERROR:
		dashing = false
		idle = true
		if dash_count >= DASH_LIMIT - 1:
			queue_free()
		dash_count += 1
		timer.wait_time = IDLE_TIME
		timer.start()
		
func wiggle() -> void:
	var t = time_elapsed_wiggling / WIGGLING_TIME
	rotation = find_angle_from_two_positions(position, spider.position)
	rotation += WIGGLING_STRENGTH * exp(WIGGLING_GROWTH * t) * sin(WIGGLING_FREQUENCY * PI * t) * PI / 180

func find_angle_from_two_positions(pointA : Vector2, pointB : Vector2) -> float:
	var offset : Vector2 = pointB - pointA
	var angle : float
	if  pointA.y > pointB.y:
		angle = PI - atan(offset.x / offset.y) + PI / 2
	else:
		angle = -atan(offset.x / offset.y) + PI / 2
	angle = fmod(angle, 2.0 * PI)
	return angle

func _on_timer_timeout() -> void:
	if wiggling:
		dashing = true
		wiggling = false
		dashing_target = spider.position
		dash_orientation = (dashing_target - position).normalized()
		if dash_count >= DASH_LIMIT - 1:
			dash_end = dash_orientation * 1000 + dashing_target
		else:
			dash_end = dash_orientation * 300 + dashing_target
	elif tracking:
		tracking = false
		wiggling = true
		time_elapsed_wiggling = 0
		dash_rotation = rotation
		timer.wait_time = WIGGLING_TIME
		timer.start()
	elif idle:
		idle = false
		tracking = true
	elif dead:
		HitSpider.emit()

func _on_body_entered(body: Node2D) -> void:
	dead = true
	timer.wait_time = GameManager.DYING_TIME
	timer.start()
