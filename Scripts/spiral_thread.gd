class_name SpiralThread
extends Line2D

@export var PointA : Node2D
@export var PointB : Node2D

@export var physics_bodies : Array[PhysicsBody2D] = []

func _ready() -> void:
	position = PointA.position
	var offset : Vector2 = PointB.position - PointA.position
	var length : float = offset.length()
	scale.y = length / 100
	var angle : float
	if PointA.position.y > PointB.position.y:
		angle = PI - atan(offset.x / offset.y)
	else:
		angle = -atan(offset.x / offset.y) 
	rotation = angle
	
func _physics_process(delta: float) -> void:
	for i in range(0, 11):
		var body = physics_bodies[i]
		points[i].x = body.position.x 
		points[i].y = body.position.y
