class_name FrameThread
extends Line2D

var complete_connections : Array[Vector2]
var incomplete_connections : Array[Vector2]
var threads_left : Dictionary[Vector2, SpiralThread] = {}
var threads_right : Dictionary[Vector2, SpiralThread] = {}
