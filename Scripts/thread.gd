extends Line2D

@export var physics_bodies : Array[PhysicsBody2D] = []

func _ready() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	for i in range(0, 11):
		var body = physics_bodies[i]
		points[i].x = body.position.x 
		points[i].y = body.position.y
