class_name Spider
extends CharacterBody2D

@export var frames : Array[FrameThread]
@export var initial_frame : FrameThread
@export var origin_connection : Vector2
@onready var timer: Timer = $Timer
@export var spiral_threads : Array[SpiralThread]

const SPEED = 200.0
const DEGREE_ERROR = 10 * PI / 180
const CONNECTION_ERROR = 20.0
const ORIGIN_TURN_TIME = 0.2
const FULL_TURN_TIME = 0.5
const SPOOL_ON_CONNECTION = 0.15
const SPOOL_BORDER = 50.0

var thread_scene = preload("res://Scenes/spiral_thread.tscn")
var current_frame : FrameThread
var current_thread : SpiralThread

var lerping : bool
var desired_rotation : float
var starting_rotation : float
var desired_position : Vector2
var starting_position : Vector2
var camera_dimensions: Vector2i
var spool_start : Vector2
var spool_thread : Line2D
var spooling : bool
var create_spool : bool
var spool_start_frame : FrameThread
var spool_created_complete : bool

var connection_found : bool
var chosen_connection : Vector2

func _ready() -> void:
	current_frame = initial_frame
	for frame in frames:
		frame.complete_connections.append(origin_connection)
	camera_dimensions = get_viewport().size	
	

func _physics_process(delta: float) -> void:
	if not lerping:
		if Input.is_action_pressed("MoveForward"):
			move(delta)
		if Input.get_axis("TurnLeft", "TurnRight") != 0:
			turn()
		if Input.is_action_just_pressed("Spool"):
			spool()
		if spooling:
			spool_thread.points[1].x = position.x
			spool_thread.points[1].y = position.y
		if Input.is_action_just_released("Spool"):
			if current_frame:
				# Finish the thread	
				print("Hiii")
				end_spool()
				pass
			else:
				# Delete the thread
				pass
	else:
		var t = (timer.wait_time - timer.time_left) / timer.wait_time
		rotation = lerp(starting_rotation, desired_rotation, t * t * (3 - 2 * t))
		position = lerp(starting_position, desired_position, t * t * (3 - 2 * t))

func move(delta : float) -> void:
	if current_frame:
		if correct_angle_frame(rotation) or correct_angle_frame(fmod(PI + rotation, 2.0 * PI)):
			var orientation : Vector2 = Vector2(cos(-rotation), sin(rotation))
			position += orientation * SPEED * delta
	else:
		pass
	 
func spool() -> void:
	if len(current_frame.incomplete_connections) == 0:# If there are no incomplete connections
		if (position - origin_connection).length() > SPOOL_BORDER:# Cant create too close to the origin
			if within_borders():# Cant create too close to other threads
				print("within camera borders")
				for connection in current_frame.complete_connections:
					if (position - connection).length() > CONNECTION_ERROR:
						print("far enough from other connections")
						spool_created_complete = false
						create_new_spool()
						break
					
			
	else:
		# create spool from incomplete connection
		var results = loop_connections()
		chosen_connection = results[0]
		connection_found = results[1]
		if connection_found:
			lerping = true
			starting_rotation = rotation
			desired_rotation = rotation
			starting_position = position
			desired_position = chosen_connection
			timer.wait_time = SPOOL_ON_CONNECTION
			timer.start()
			spool_created_complete = true
			create_spool = true
	
func turn() -> void:
	if current_frame:
		var results = loop_connections()
		chosen_connection = results[0]
		connection_found = results[1]
		if not connection_found: # If not near origin and turning
			timer.wait_time = FULL_TURN_TIME
			timer.start()
			lerping = true
			if Input.get_axis("TurnLeft", "TurnRight") > 0:
				desired_rotation = PI + rotation
				starting_rotation = rotation
				desired_position = position
				starting_position = position
			else:
				desired_rotation = rotation - PI
				starting_rotation = rotation
				desired_position = position
				starting_position = position
		elif chosen_connection == origin_connection: # if near origin and turning 
			if Input.get_axis("TurnLeft", "TurnRight") > 0:				
				var frame_index = frames.find(current_frame)
				
				if correct_angle_frame(fmod(PI + rotation, 2.0 * PI)):
					frame_index += 3
				
				frame_index += 1
				frame_index %= len(frames)
				
				desired_rotation = frames[frame_index].rotation
				starting_rotation = rotation
				if desired_rotation < starting_rotation:
					starting_rotation -= 2.0 * PI
				desired_position = origin_connection
				starting_position = position
				current_frame = frames[frame_index]
				lerping = true
				timer.wait_time = ORIGIN_TURN_TIME
				timer.start()
			else:
				var frame_index = frames.find(current_frame)
				
				if correct_angle_frame(fmod(PI + rotation, 2.0 * PI)):
					frame_index += 3
				
				frame_index -= 1
				frame_index %= len(frames)
				if frame_index < 0:
					frame_index = 5
				
				desired_rotation = frames[frame_index].rotation
				starting_rotation = rotation
				if desired_rotation > starting_rotation:
					desired_rotation -= 2.0 * PI
				desired_position = origin_connection
				starting_position = position
				current_frame = frames[frame_index]
				lerping = true
				timer.wait_time = ORIGIN_TURN_TIME
				timer.start()
		else:
			position = chosen_connection #snap
			
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
	lerping = false
	timer.stop()
	rotation = fmod(desired_rotation, 2.0 * PI) 
	if rotation < 0:
		rotation += 2.0 * PI
	if create_spool:
		create_new_spool()

func _on_origin_snap_zone_body_exited(_body: Node2D) -> void:
	var frame_index = frames.find(current_frame)
	if not correct_angle_frame(rotation):
		@warning_ignore("integer_division")
		frame_index += int(len(frames) / 2)
		frame_index %= len(frames)
		current_frame = frames[frame_index]

func loop_connections() -> Array:
	var _chosen_connection : Vector2 
	var _connection_found : bool
	for connection in current_frame.complete_connections + current_frame.incomplete_connections:
		if (connection - position).length() < CONNECTION_ERROR:
			_chosen_connection = connection
			_connection_found = true
	return [_chosen_connection, _connection_found]
	
func create_new_spool() -> void:
	#create spool from wherever since there are no incomplete connections
	spool_thread = Line2D.new()
	get_tree().current_scene.add_child(spool_thread)
	spool_start = position
	spool_thread.add_point(spool_start)
	spool_thread.add_point(position)
	spool_thread.default_color = Color.AQUA
	spool_thread.width = 2.5
	spool_thread.z_index = 4
	spooling = true
	spool_start_frame = current_frame
	
func end_spool()-> void:
	var starting_index = frames.find(spool_start_frame)
	var end_index = frames.find(current_frame)
	
	if spool_thread:
		if absi(end_index - starting_index) == 1:# Cant end if you arent on an adjacent frame
			if len(current_frame.incomplete_connections) < 1: # If no incomplete
				if (position - origin_connection).length() > SPOOL_BORDER and within_borders():# Cant create too close to the origin
					if left_right_overlap_check(starting_index, end_index):
						for connection in current_frame.complete_connections: #too close to completed
							if (position - connection).length() > CONNECTION_ERROR:
								var nodeA : Node2D = Node2D.new()
								nodeA.position = spool_start
								get_tree().current_scene.add_child(nodeA)
								var nodeB : Node2D = Node2D.new()
								nodeB.position = position
								get_tree().current_scene.add_child(nodeB)
								# make thread
								var thread_instance = thread_scene.instantiate()
								thread_instance.PointA = nodeA
								thread_instance.PointB = nodeB
								get_tree().current_scene.add_child(thread_instance)
								spool_thread.queue_free()
								spooling = false
								# dict update
								current_frame.incomplete_connections.append(position)
								if spool_created_complete:
									spool_start_frame.complete_connections.append(spool_start)
									spool_start_frame.incomplete_connections.erase(spool_start)
								else:
									spool_start_frame.incomplete_connections.append(spool_start)
								
								
							else:
								pass
					else:
						pass # SNAPPPP
							
							
			else: # if incomplete (HAVE TO SNAP)
				pass
	
	# set endpoint of line
	
	
func within_borders():
	print(position.y,"should be smaller than than than", camera_dimensions[0]/2)
	
	return position.x > (- camera_dimensions[0]/2) and position.x < (camera_dimensions[0]/2) and position.y > (-camera_dimensions[1]/2) and position.y < ( camera_dimensions[1]/2)

func left_right_overlap_check(s_i, e_i):
	var _starting_index = s_i
	var _end_index = e_i
	if _end_index > _starting_index or (_starting_index == len(frames)-1 and _end_index == 0): 
		for thread in spool_start_frame.threads_right.values():
			var pointa_closer : bool = (thread.PointA.position - origin_connection).length() > (spool_start - origin_connection).length()
			var pointb_closer : bool = (thread.PointB.position - origin_connection).length() > (position - origin_connection).length()
			if pointa_closer and pointb_closer:
				return true
			else:
				return false
	else:
		for thread in spool_start_frame.threads_left.values():
			var pointa_closer : bool = (thread.PointA.position - origin_connection).length() > (spool_start - origin_connection).length()
			var pointb_closer : bool = (thread.PointB.position - origin_connection).length() > (position - origin_connection).length()
			if pointa_closer and pointb_closer:
				return true
			else:
				return false
