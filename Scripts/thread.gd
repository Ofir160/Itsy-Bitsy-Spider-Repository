extends Line2D

@export var NodeA : PhysicsBody2D
@export var NodeB : PhysicsBody2D

@onready var thread_segment: RigidBody2D = $ThreadSegment
@onready var thread_segment_10: RigidBody2D = $ThreadSegment10

@onready var pin_joint_2d: PinJoint2D = $PinJoint2D
@onready var pin_joint_2d_11: PinJoint2D = $PinJoint2D11

@export var physics_bodies : Array[RigidBody2D] = []

func _ready() -> void:
	pin_joint_2d.node_a = NodeA.get_path()
	pin_joint_2d_11.node_b = NodeB.get_path()
	points[0].x = NodeA.global_position.x
	points[0].y = NodeA.global_position.y
	points[11].x = NodeB.global_position.x
	points[11].y = NodeB.global_position.y
	
func _physics_process(delta: float) -> void:
	
	print(physics_bodies[0].linear_velocity)
	for i in range(0, 10):
		var body = physics_bodies[i]
		points[i + 1].x = body.global_position.x + NodeA.position.x
		#print(body.linear_velocity)
		points[i + 1].y = body.global_position.y + NodeA.position.y
