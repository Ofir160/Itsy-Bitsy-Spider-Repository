class_name Spider
extends CharacterBody2D

@export var frames : Array[FrameThread]
@export var initial_frame : FrameThread
@export var origin_connection : Vector2
@onready var timer: Timer = $Timer
@export var spiral_threads : Array[SpiralThread]

const SPEED = 200.0
const DEGREE_ERROR = 10 * PI / 180
const CONNECTION_ERROR = 10.0
const ORIGIN_TURN_TIME = 0.2
const FULL_TURN_TIME = 0.5
const SPOOL_ON_CONNECTION = 0.15
const SPOOL_BORDER = 75.0

var thread_scene = preload("res://Scenes/spiral_thread.tscn")
var current_frame : FrameThread
var current_thread : SpiralThread

var lerping : bool

var turning_on_thread : bool
var approaching_thread : SpiralThread
var approaching_frame : FrameThread
var thread_end : Vector2
var moving_right : bool

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
				end_spool()
			else:
				# Delete the thread	
				if spool_thread:
					spool_thread.queue_free()
				spooling = false
	else:
		var t = (timer.wait_time - timer.time_left) / timer.wait_time
		rotation = lerp(starting_rotation, desired_rotation, t * t * (3 - 2 * t))
		position = lerp(starting_position, desired_position, t * t * (3 - 2 * t))

func move(delta : float) -> void:
	if current_thread:
		# If we are on a thread
		current_frame = null
		var orientation : Vector2 = Vector2(cos(-rotation), sin(rotation))
		position += orientation * SPEED * delta
		if (thread_end - position).length() < CONNECTION_ERROR:
			# Close to the end snap
			var frame_dict : Dictionary[Vector2, SpiralThread]
			var chosen_thread : SpiralThread
			var thread_found : bool
			if moving_right:
				frame_dict = approaching_frame.threads_right
			else:
				frame_dict = approaching_frame.threads_left
			for thread in frame_dict.values():
				if (thread.PointA.position - position).length() > (thread.PointB.position - position).length():
					# If point B is closer
					if (thread.PointB.position - position).length() < CONNECTION_ERROR:
						chosen_thread = thread
						thread_found = true
						break
				else:
					# If point A is closer
					if (thread.PointA.position - position).length() < CONNECTION_ERROR:
						chosen_thread = thread
						thread_found = true
						break
			if thread_found:
				var pointA : Vector2
				var pointB : Vector2
				# Lerp to the threads angle
				if (chosen_thread.PointA.position - position).length() > (chosen_thread.PointB.position - position).length():
					# Closer to point B
					pointA = chosen_thread.PointB.position
					pointB = chosen_thread.PointA.position
				else:
					# Closet to point A
					pointA = chosen_thread.PointA.position
					pointB = chosen_thread.PointB.position
				var angle = find_angle_from_two_positions(pointA, pointB)
				if moving_right:
					# When moving right the new angle should always be bigger than your current
					if angle < rotation:
						rotation -= 2.0 * PI
				else:
					# When moving left the new angle should always be smaller than your current
					if angle > rotation:
						rotation += 2.0 * PI
				desired_rotation = angle
				starting_rotation = rotation
				desired_position = thread_end
				starting_position = position
				lerping = true
				turning_on_thread = true
				approaching_thread = chosen_thread
				
				var next_frame_index
				if moving_right:
					next_frame_index = frames.find(approaching_frame) + 1
					next_frame_index %= len(frames)
				else:
					next_frame_index = frames.find(approaching_frame) - 1
					if next_frame_index < 0:
						next_frame_index = len(frames) - 1
				
				approaching_frame = frames[next_frame_index]
				thread_end = pointB
				timer.wait_time = ORIGIN_TURN_TIME
				timer.start()
			else:
				current_thread = null
				current_frame = approaching_frame
				
				if moving_right:
					# When moving right the new angle should always be bigger than your current
					if current_frame.rotation > rotation:
						rotation += 2.0 * PI
				else:
					# When moving left the new angle should always be smaller than your current
					if current_frame.rotation < rotation:
						rotation -= 2.0 * PI
				
				desired_rotation = current_frame.rotation
				starting_rotation = rotation
				desired_position = thread_end
				starting_position = position
				lerping = true
				timer.wait_time = ORIGIN_TURN_TIME
				timer.start()
				# Lerp to the frames angle
				
			pass
	elif current_frame:
		# If we are on a frame
		if correct_angle_frame(rotation) or correct_angle_frame(fmod(PI + rotation, 2.0 * PI)):
			current_thread = null
			var orientation : Vector2 = Vector2(cos(-rotation), sin(rotation))
			position += orientation * SPEED * delta
	 
func spool() -> void:
	if len(current_frame.incomplete_connections) == 0:# If there are no incomplete connections
		print("there are no incomplete connections")
		if (position - origin_connection).length() > SPOOL_BORDER and within_borders():# Cant create too close to the origin
			# Cant create too close to other threads
			for connection in current_frame.complete_connections:
				if (position - connection).length() < CONNECTION_ERROR:
					return
			print("Spool Created!")
			spool_created_complete = false
			create_new_spool()
		else:
			print("Outside Borders")
	else:
		# create spool from incomplete connection
		print("Incomplete connection, attempting to snap")
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
			spool_created_complete = true
			create_spool = true
			timer.start()
		else:
			print("Incomplete connection too far away!")
			
func turn() -> void:
	if current_frame:
		var results = loop_connections()
		chosen_connection = results[0]
		connection_found = results[1]
		if not connection_found: # If not near origin and turning
			if Input.get_axis("TurnLeft", "TurnRight") > 0:
				# If turning right
				desired_rotation = PI + rotation
				starting_rotation = rotation
				desired_position = position
				starting_position = position
			else:
				# If turning left
				desired_rotation = rotation - PI
				starting_rotation = rotation
				desired_position = position
				starting_position = position
			timer.wait_time = FULL_TURN_TIME
			timer.start()
			lerping = true
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
					frame_index = len(frames) - 1
				
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
		else: # If not near the origin but near a thread intsersection
			if Input.get_axis("TurnLeft", "TurnRight") > 0:
				# If we are turning right
				if correct_angle_frame(rotation) or correct_angle_frame(fmod(PI + rotation, 2.0 * PI)):
					# Turning on frame thread
					var frame_dict : Dictionary[Vector2, SpiralThread]
					var current_frame_index : int = frames.find(current_frame)
					var approaching_frame_index : int
					if correct_angle_frame(rotation):
						frame_dict = current_frame.threads_right
						approaching_frame_index = current_frame_index + 1
						approaching_frame_index %= len(frames)
						moving_right = true
					else:
						frame_dict = current_frame.threads_left
						approaching_frame_index = current_frame_index - 1
						if approaching_frame_index < 0:
							approaching_frame_index = len(frames) - 1
						moving_right = false
					if len(frame_dict.keys()) > 0:
						# If there is a spiral thread to turn to
						for thread_position in frame_dict.keys():
							if (thread_position - position).length() < CONNECTION_ERROR:
								var thread = frame_dict[thread_position]
								var pointA : Vector2
								var pointB : Vector2
								if (thread.PointA.position - position).length() > (thread.PointB.position - position).length():
									# Closer to point B
									pointA = thread.PointB.position
									pointB = thread.PointA.position
								else:
									# Closet to point A
									pointA = thread.PointA.position
									pointB = thread.PointB.position
								
								var angle = find_angle_from_two_positions(pointA, pointB)
								if angle < rotation:
									rotation -= 2.0 * PI
								desired_rotation = angle
								starting_rotation = rotation
								desired_position = pointA
								starting_position = position
								lerping = true
								turning_on_thread = true
								approaching_thread = thread
								approaching_frame = frames[approaching_frame_index]
								thread_end = pointB
								timer.wait_time = ORIGIN_TURN_TIME
								timer.start()
								break
					else:
						print("No Keys")
						desired_rotation = PI + rotation
						starting_rotation = rotation
						desired_position = position
						starting_position = position
						timer.wait_time = FULL_TURN_TIME
						timer.start()
						lerping = true
				else:
					# Turning on spiral thread
					if moving_right:
						var angle : float = fmod(PI + current_frame.rotation, 2.0 * PI)
						if angle < rotation:
							rotation -= 2.0 * PI
						desired_rotation = angle
						starting_rotation = rotation
						desired_position = position
						starting_position = position
						lerping = true
						timer.wait_time = ORIGIN_TURN_TIME
						timer.start()
						current_thread = null
					else:
						var angle : float = current_frame.rotation
						if angle < rotation:
							rotation -= 2.0 * PI
						desired_rotation = angle
						starting_rotation = rotation
						desired_position = position
						starting_position = position
						lerping = true
						timer.wait_time = ORIGIN_TURN_TIME
						timer.start()
						current_thread = null
			else:
				# If we are turning left
				if correct_angle_frame(rotation) or correct_angle_frame(fmod(PI + rotation, 2.0 * PI)):
					# Turning on frame thread
					var frame_dict : Dictionary[Vector2, SpiralThread]
					var current_frame_index : int = frames.find(current_frame)
					var approaching_frame_index : int
					if correct_angle_frame(rotation):
						frame_dict = current_frame.threads_left
						approaching_frame_index = current_frame_index - 1
						if approaching_frame_index < 0:
							approaching_frame_index = len(frames) - 1
						moving_right = false
					else:
						frame_dict = current_frame.threads_right
						approaching_frame_index = current_frame_index + 1
						approaching_frame_index %= len(frames)
						moving_right = true
					if len(frame_dict.keys()) > 0:
						for thread_position in frame_dict.keys():
							if (thread_position - position).length() < CONNECTION_ERROR:
								var thread = frame_dict[thread_position]
								var pointA : Vector2
								var pointB : Vector2
								if (thread.PointA.position - position).length() > (thread.PointB.position - position).length():
									# Closer to point B
									pointA = thread.PointB.position
									pointB = thread.PointA.position
								else:
									# Closet to point A
									pointA = thread.PointA.position
									pointB = thread.PointB.position
								
								var angle = find_angle_from_two_positions(pointA, pointB)
								if angle > rotation:
									rotation += 2.0 * PI
								desired_rotation = angle
								starting_rotation = rotation
								desired_position = pointA
								starting_position = position
								lerping = true
								turning_on_thread = true
								approaching_thread = thread
								approaching_frame = frames[approaching_frame_index]
								thread_end = pointB
								timer.wait_time = ORIGIN_TURN_TIME
								timer.start()
								break
					else:
						print("No Keys")
						desired_rotation = rotation - PI
						starting_rotation = rotation
						desired_position = position
						starting_position = position
						timer.wait_time = FULL_TURN_TIME
						timer.start()
						lerping = true
				else:
					# Turning on spiral thread
					if moving_right:
						var angle : float = current_frame.rotation
						if angle > rotation:
							rotation += 2.0 * PI
						desired_rotation = angle
						starting_rotation = rotation
						desired_position = position
						starting_position = position
						lerping = true
						timer.wait_time = ORIGIN_TURN_TIME
						timer.start()
						current_thread = null
					else:
						var angle : float = fmod(PI + current_frame.rotation, 2.0 * PI)
						if angle > rotation:
							rotation += 2.0 * PI
						desired_rotation = angle
						starting_rotation = rotation
						desired_position = position
						starting_position = position
						lerping = true
						timer.wait_time = ORIGIN_TURN_TIME
						timer.start()
						current_thread = null
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
		print("Spool Created after snapping!")
		create_new_spool()
		spooling = true
		create_spool = false
	if turning_on_thread:
		turning_on_thread = false
		current_thread = approaching_thread
		

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
		if absi(end_index - starting_index) == 1 or (starting_index == len(frames) - 1 and end_index == 0) or (end_index == len(frames)-1 and starting_index == 0):# Cant end if you arent on an adjacent frame DOESNT WORK FOR thread 5 and 0
			if (position - origin_connection).length() > SPOOL_BORDER and within_borders():# Cant create too close to the origin
				if len(current_frame.incomplete_connections) < 1: # If no incomplete
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
								# update lists
								current_frame.incomplete_connections.append(position)
								if spool_created_complete:
									print("Created a new complete connection")
									spool_start_frame.complete_connections.append(spool_start)
									erase_nearby(spool_start_frame.incomplete_connections, spool_start)
								else:
									print("Created a new incomplete connection")
									spool_start_frame.incomplete_connections.append(spool_start)
								# update dicts
								if (end_index > starting_index or (starting_index == len(frames)-1 and end_index == 0)) and not (starting_index == 0 and end_index == len(frames) - 1):
									# Right of start. Left of end
									spool_start_frame.threads_right[spool_start] = thread_instance
									current_frame.threads_left[position] = thread_instance
								else:
									spool_start_frame.threads_left[spool_start] = thread_instance
									current_frame.threads_right[position] = thread_instance
							else:
								print("too close to complete connection")
					else:
						print("Overlap") # SNAPPPP
						spool_thread.queue_free()
						spooling = false
						
				else:
					print("There is an incomplete connection on ending_frame")
					if left_right_overlap_check(starting_index, end_index):
						var results = loop_connections()
						if results[1]:
							position = results[0]
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
							# update lists
							current_frame.complete_connections.append(position)
							erase_nearby(current_frame.incomplete_connections, position)
							if spool_created_complete:
								print("Created a new complete connection")
								spool_start_frame.complete_connections.append(spool_start)
								erase_nearby(spool_start_frame.incomplete_connections, spool_start)
							else:
								print("Created a new incomplete connection")
								spool_start_frame.incomplete_connections.append(spool_start)
							# update dicts
							if end_index > starting_index or (starting_index == len(frames)-1 and end_index == 0):
								# Right of start. Left of end
								spool_start_frame.threads_right[spool_start] = thread_instance
								current_frame.threads_left[position] = thread_instance
							else:
								spool_start_frame.threads_left[spool_start] = thread_instance
								current_frame.threads_right[position] = thread_instance
						else:
							print("Incomplete Connection too far away!")
							spool_thread.queue_free()
							spooling = false
					else:
						print("Overlap")
						spool_thread.queue_free()
						spooling = false
						
			else: # if incomplete (HAVE TO SNAP)
				print("Out of bounds")
				spool_thread.queue_free()
				spooling = false
		else:
			print("not on adject frame")
			spool_thread.queue_free()
			spooling = false
	else:
		print("thread doesnt exist")
	# set endpoint of line
	
func within_borders():
	return position.x > (- camera_dimensions[0]/2) and position.x < (camera_dimensions[0]/2) and position.y > (-camera_dimensions[1]/2) and position.y < ( camera_dimensions[1]/2)

func left_right_overlap_check(s_i, e_i):
	var _starting_index = s_i
	var _end_index = e_i
	if _end_index > _starting_index or (_starting_index == len(frames)-1 and _end_index == 0): 
		# Right of start. Left of end
		if len(spool_start_frame.threads_right.values()) > 0:
			print("Right of start left of end")
			for thread in spool_start_frame.threads_right.values():
				if (thread.PointA.position - position).length() < CONNECTION_ERROR:
					return false
				if (thread.PointB.position - position).length() < CONNECTION_ERROR:
					return false
				var pointa_closer : bool = (thread.PointA.position - origin_connection).length() > (spool_start - origin_connection).length()
				var pointb_closer : bool = (thread.PointB.position - origin_connection).length() > (position - origin_connection).length()
				if pointa_closer and pointb_closer:
					return true
				elif not pointa_closer and not pointb_closer:
					return true
				else:
					return false
		else:
			return true
	else:
		# Right of end. Left of start
		if len(spool_start_frame.threads_left.values()) > 0:
			print("Right of end left of start")
			for thread in spool_start_frame.threads_left.values():
				if (thread.PointA.position - position).length() < CONNECTION_ERROR:
					return false
				if (thread.PointB.position - position).length() < CONNECTION_ERROR:
					return false
				var pointa_closer : bool = (thread.PointA.position - origin_connection).length() > (spool_start - origin_connection).length()
				var pointb_closer : bool = (thread.PointB.position - origin_connection).length() > (position - origin_connection).length()
				if pointa_closer and pointb_closer:
					return true
				elif not pointa_closer and not pointb_closer:
					return true
				else:
					return false
		else:
			return true
			
func erase_nearby(connections : Array[Vector2], position : Vector2) -> void:
	for connection in connections:
		if (connection - position).length() < CONNECTION_ERROR:
			connections.erase(connection)

func find_angle_from_two_positions(pointA : Vector2, pointB : Vector2) -> float:
	var offset : Vector2 = pointB - pointA
	var angle : float
	if  pointA.y > pointB.y:
		angle = PI - atan(offset.x / offset.y) + PI / 2
	else:
		angle = -atan(offset.x / offset.y) + PI / 2
	angle = fmod(angle, 2.0 * PI)
	return angle
