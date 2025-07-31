extends Line2D

@export var NodeA : PhysicsBody2D
@export var NodeB : PhysicsBody2D

@onready var thread_segment: RigidBody2D = $ThreadSegment
@onready var thread_segment_10: RigidBody2D = $ThreadSegment10

@onready var pin_joint_2d: PinJoint2D = $PinJoint2D
@onready var pin_joint_2d_11: PinJoint2D = $PinJoint2D11

@export var rigidbodies : Array[RigidBody2D] = []
@export var joints : Array[PinJoint2D] = []

var length : float
var angle : float

func _ready() -> void:
	pin_joint_2d.node_a = NodeA.get_path()
	pin_joint_2d_11.node_b = NodeB.get_path()
	points[0].x = NodeA.position.x
	points[0].y = NodeA.position.y
	points[11].x = NodeB.position.x
	points[11].y = NodeB.position.y
	length = (NodeA.position - NodeB.position).length()
	var offset : Vector2 = NodeB.position - NodeA.position
	if NodeA.position.y > NodeB.position.y:
		angle = 180 - atan(offset.x / offset.y) * 180.0 / PI
	else:
		angle = -atan(offset.x / offset.y) * 180.0 / PI
	if angle < 0:
		angle += 360
	#print(angle)
	for joint in joints:
		joint.global_position += NodeA.position
		print(joint.global_position)
		#print(joint.global_position)
	for rigidbody in rigidbodies:
		rigidbody.global_position += NodeA.position
	
func _physics_process(delta: float) -> void:
	for i in range(0, 10):
		var body = rigidbodies[i]
		points[i + 1].x = body.global_position.x
		points[i + 1].y = body.global_position.y
#func rotate_vector(input : Vector2, angle : float) -> Vector2:
	
