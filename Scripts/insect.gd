class_name Insect
extends Node2D

signal Eaten(insect : Insect)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 250.0
const CRASH_LAND_ERROR = 20.0
const ANGLE_AMPLITUDE = 5.0
const FLYING_FREQUENCY = 21.0

var camera_dimensions : Vector2
var distance : float
var desired_position : Vector2
var desired_rotation : float
var orientation : Vector2
var perpendicular : Vector2
var flying : bool
var time_taken : float
var time_elapsed : float

func _ready() -> void:
	camera_dimensions = get_viewport().size
	animated_sprite.play("Alive")

func init() -> void:
	distance = camera_dimensions.length()
	orientation = Vector2(cos(desired_rotation), sin(desired_rotation))
	perpendicular = Vector2(orientation.y, -orientation.x)
	var original_position = desired_position - orientation * distance
	position = original_position
	rotation = desired_rotation
	flying = true
	time_taken = distance / SPEED

func _process(delta: float) -> void:
	if flying:
		time_elapsed += delta
		var t = time_elapsed / time_taken
		position += orientation * delta * SPEED + perpendicular * sin(FLYING_FREQUENCY * PI * t)
		rotation = desired_rotation + ANGLE_AMPLITUDE * sin(FLYING_FREQUENCY * PI * t) * PI / 180
		if (desired_position - position).length() < CRASH_LAND_ERROR:
			position = desired_position
			flying = false
			animated_sprite.play("Dead")
			
func _on_body_entered(body: Node2D) -> void:
	Eaten.emit(self) # check body is player - don't know if this doesnt work
	
func destroy() -> void:
	queue_free()
