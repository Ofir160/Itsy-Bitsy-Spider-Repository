class_name FrameThread
extends Line2D

var complete_connections : int
var connections : Array[Vector2] 
var thread_left = {}
var thread_right = {}

func add_connection(connection : Vector2) -> void:
	connections.append(connection)
