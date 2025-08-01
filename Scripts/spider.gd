class_name Spider
extends CharacterBody2D

@export var frames : Array[FrameThread]

const SPEED = 200.0

var correct_anlge : bool
var thread_scene = preload("res://Scenes/spiral_thread.tscn")
var current_frame : FrameThread
var current_thread : SpiralThread
