class_name Spider
extends CharacterBody2D

signal ThreadCreated(thread : SpiralThread)
signal InsectEaten(insect : Insect)
signal LoopCreated()

@export var frames : Array[FrameThread]
@export var initial_frame : FrameThread
@export var origin_intersection : Vector2
@export var origin_area : Area2D

@onready var timer: Timer = $Timer
@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var spiral_threads : Array[SpiralThread]

const SPEED = 200.0
const DEGREE_ERROR = 10 * PI / 180
const INTERSECTION_ERROR = 20.0
const ORIGIN_TURN_TIME = 0.2
const FULL_TURN_TIME = 0.5
const SPOOL_ON_intersection = 0.15
const SPOOL_BORDER = 75.0

const EAT_FLY = preload("res://Assets/Audio/SFX/eat_fly.mp3")
const MAKE_CONNECTION = preload("res://Assets/Audio/SFX/make_connection.mp3")
const SPIDER_WALK = preload("res://Assets/Audio/SFX/spider_walk.mp3")

var spiral_thread_scene = preload("res://Scenes/Universal/Threads/spiral_thread.tscn")

var current_frame_thread : FrameThread
var current_spiral_thread : SpiralThread

var lerping : bool
var lerping_spool_released : bool

var turning_on_thread : bool
var on_spiral_thread : bool
var turn_to_thread : SpiralThread
var approaching_frame_thread : FrameThread
var previous_frame_thread : FrameThread
var spiral_thread_end : Vector2

var moving_right : bool

# Lerping variables
var desired_rotation : float
var starting_rotation : float
var desired_position : Vector2
var starting_position : Vector2

var camera_dimensions: Vector2i

# Spooling variables
var spool_start : Vector2
var spool_thread : Line2D
var spooling : bool
var create_spool : bool
var spool_start_frame_thread : FrameThread
var spool_start_on_incomplete_connection : bool
var silk_left : bool = true

var intersection_found : bool
var chosen_intersection : Vector2

var intersection : Vector2
var on_intersection : bool
var complete_intersection : bool

func _ready() -> void:
	current_frame_thread = initial_frame
	origin_area.body_exited.connect(exited_origin)
	for frame in frames:
		frame.complete_connections.append(origin_intersection)
	camera_dimensions = get_viewport().size

func _physics_process(delta: float) -> void:
	turn_to_mouse()
	if Input.is_action_pressed("MoveForward"):
		move(delta)
	else:
		animated_sprite.play("Idle")
	if Input.is_action_just_pressed("Spool"):
		if spooling:
			end_spool()
		else:
			start_spool()
	# Check if the blue line connecting the player to the intersection needs to be updated
	if spooling:
		spool_thread.points[1].x = position.x
		spool_thread.points[1].y = position.y

func move(delta : float) -> void:
	if on_spiral_thread:
		'''
		# Sets visuals and audio
		audio_stream_player.stream = SPIDER_WALK
		audio_stream_player.play()
		animated_sprite.play("Move")
		
		# Calculates player orientation and moves the player
		var orientation : Vector2 = Vector2(cos(-rotation), sin(rotation))
		position += orientation * SPEED * delta
		
		current_spiral_thread = turn_to_thread
		
		if (spiral_thread_end - position).length() < INTERSECTION_ERROR:
			# Close to the end snap
			var frame_dict : Dictionary[Vector2, SpiralThread]
			var chosen_thread : SpiralThread
			var thread_found : bool
			if moving_right:
				frame_dict = approaching_frame_thread.threads_right
			else:
				frame_dict = approaching_frame_thread.threads_left
			for thread in frame_dict.values():
				if (thread.PointA.position - position).length() > (thread.PointB.position - position).length():
					# If point B is closer
					if (thread.PointB.position - position).length() < INTERSECTION_ERROR:
						chosen_thread = thread
						thread_found = true
						break
				else:
					# If point A is closer
					if (thread.PointA.position - position).length() < INTERSECTION_ERROR:
						chosen_thread = thread
						thread_found = true
						break
			if thread_found:
				# Turn on to next thread
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
				desired_position = spiral_thread_end
				starting_position = position
				lerping = true
				turning_on_thread = true
				turn_to_thread = chosen_thread
				
				var next_frame_index
				if moving_right:
					next_frame_index = frames.find(approaching_frame_thread) + 1
					next_frame_index %= len(frames)
				else:
					next_frame_index = frames.find(approaching_frame_thread) - 1
					if next_frame_index < 0:
						next_frame_index = len(frames) - 1
				
				current_frame_thread = approaching_frame_thread
				approaching_frame_thread = frames[next_frame_index]
				spiral_thread_end = pointB
				timer.wait_time = ORIGIN_TURN_TIME
				timer.start()
			else:
				# Turn on to the approached frame
				current_spiral_thread = null
				on_spiral_thread = false
				current_frame_thread = approaching_frame_thread
				
				if moving_right:
					# When moving right the new angle should always be bigger than your current
					if current_frame_thread.rotation > rotation:
						rotation += 2.0 * PI
				else:
					# When moving left the new angle should always be smaller than your current
					if current_frame_thread.rotation < rotation:
						rotation -= 2.0 * PI
				
				desired_rotation = current_frame_thread.rotation
				starting_rotation = rotation
				desired_position = spiral_thread_end
				starting_position = position
				lerping = true
				timer.wait_time = ORIGIN_TURN_TIME
				timer.start()
				# Lerp to the frames angle
				
			pass
		'''
		pass
	else:
		
		# Sets audio and visuals
		animated_sprite.play("Move")
		audio_stream_player.stream = SPIDER_WALK
		audio_stream_player.play()
		
		# If we are on a frame
		current_spiral_thread = null
		var orientation : Vector2 = Vector2(cos(-rotation), sin(rotation))
		position += orientation * SPEED * delta
		
		check_on_intersection()

func turn_to_mouse() -> void:
	var local_mouse_pos = get_local_mouse_position()
	var global_mouse_pos = get_global_mouse_position()
	
	if on_intersection:
		if intersection == origin_intersection:
			
			var frame_index = frames.find(current_frame_thread)
			var left_index = modulo_frame_index(frame_index - 1)
			var right_index = modulo_frame_index(frame_index + 1)
			
			var distance_to_current = distance_to_frame(global_mouse_pos, current_frame_thread)
			var distance_to_frame_left = distance_to_frame(global_mouse_pos, frames[left_index])
			var distance_to_frame_right = distance_to_frame(global_mouse_pos, frames[right_index])
			
			# If the mouse position is closest to the frame to the left
			if distance_to_frame_left < distance_to_current and distance_to_frame_left < distance_to_frame_right:
				position = origin_intersection
				rotation = frames[left_index].rotation
				current_frame_thread = frames[left_index]
			# If the mouse position is closest to the frame to the right
			elif distance_to_frame_right < distance_to_current and distance_to_frame_right < distance_to_frame_left:
				position = origin_intersection
				rotation = frames[right_index].rotation
				current_frame_thread = frames[right_index]
		else:
			var distance_to_current = distance_to_frame(global_mouse_pos, current_frame_thread)
			if complete_intersection:
				var spiral_left = current_frame_thread.threads_left[intersection]
				var spiral_right = current_frame_thread.threads_right[intersection]
				
				var distance_to_spiral_left = distance_to_spiral(global_mouse_pos, spiral_left)
				var distance_to_spiral_right = distance_to_spiral(global_mouse_pos, spiral_right)
				
				if distance_to_spiral_left < distance_to_current and distance_to_spiral_left < distance_to_spiral_right:
					position = intersection
					
					turn_to_spiral(spiral_left)
					
					current_spiral_thread = spiral_left
				elif distance_to_spiral_right < distance_to_current and distance_to_spiral_right < distance_to_spiral_left:
					position = intersection
					
					turn_to_spiral(spiral_right)
						
					current_spiral_thread = spiral_right
				else:
					turn_to_current_frame()
			else:
				if current_frame_thread.threads_left.has(intersection):
					var spiral_left = current_frame_thread.threads_left[intersection]
					var distance_to_spiral_left = distance_to_spiral(global_mouse_pos, spiral_left)
					
					if distance_to_spiral_left < distance_to_current:
						turn_to_spiral(spiral_left)
						current_spiral_thread = spiral_left
					else:
						turn_to_current_frame()
						if local_mouse_pos.x < 0:
							# Need to turn around
							rotation = rotation - PI
						
				elif current_frame_thread.threads_right.has(intersection):
					var spiral_right = current_frame_thread.threads_right[intersection]
					var distance_to_spiral_right = distance_to_spiral(global_mouse_pos, spiral_right)
					
					if distance_to_spiral_right < distance_to_current:
						turn_to_spiral(spiral_right)
						current_spiral_thread = spiral_right
					else:
						turn_to_current_frame()
						if local_mouse_pos.x < 0:
							# Need to turn around
							rotation = rotation - PI
			
	else:
		if local_mouse_pos.x < -20:
			# Need to turn around
			rotation = rotation - PI
			
func distance_to_frame(point : Vector2, frame : FrameThread) -> float:
	var magnitude = frame.points[1].length()
	var frame_end_point = Vector2(magnitude * cos(2 * PI - frame.rotation), -magnitude * sin(2 * PI - frame.rotation))
	#var frame_end_point = frame.points[1].global_position

	# Projects the point on to the frame then maps it to a value between 0 and 1
	# The first / magnitude normalizes the frame_end_point vector, the second maps the value to 0 to 1
	var t = frame_end_point.dot(point) / magnitude / magnitude
	
	if t < 1 and t > 0:
		var numerator = abs(frame_end_point.y * point.x - frame_end_point.x * point.y)
		return numerator / magnitude
	elif t < 0:
		return point.length()
	else:
		return (frame_end_point - point).length()
		
func distance_to_spiral(point : Vector2, spiral : SpiralThread) -> float:
	var pointA = spiral.PointA.global_position
	var pointB = spiral.PointB.global_position
	
	var ab = pointB - pointA
	var magnitude = ab.length()
	
	# Projects the point on to the frame then maps it to a value between 0 and 1
	# The first / magnitude normalizes the ab vector, the second maps the value to 0 to 1
	var t = ab.dot(point - spiral.PointA.position) / magnitude / magnitude
	
	if t < 1 and t > 0:
		var numerator = abs(ab.y * point.x - ab.x * point.y + pointB.x * pointA.y - pointA.x * pointB.y)
		return numerator / magnitude
	elif t < 0:
		return (spiral.PointA.position - point).length()
	else:
		return (spiral.PointB.position - point).length()

func turn_to_current_frame() -> void:
	# Just some black magic to rotate to the frame thread but only once.
	if current_spiral_thread:
		rotation = current_frame_thread.rotation
		if get_local_mouse_position().x < 0:
			rotation = rotation - PI
		current_spiral_thread = null
		
func turn_to_spiral(spiral : SpiralThread) -> void:
	var pointA = spiral.PointA.global_position
	var pointB = spiral.PointB.global_position
					
	# Look at the point furthest away
	if (position - pointA).length() > (position - pointB).length():
		look_at(pointA)
	else:
		look_at(pointB)


func check_on_intersection() -> void:
	var results : Array = loop_intersections()
	intersection = results[0]
	on_intersection = results[1]
	complete_intersection = results[2]

## Returns the frame index
func modulo_frame_index(index : int) -> int:
	if index < 0:
		index += len(frames)
	return index % len(frames)
	
## Returns true if indexA is to the right of indexB
func index_is_to_the_right(indexA : int, indexB : int) -> bool:
	if indexA == 0 and indexB == len(frames) - 1:
		return true
	if indexB == 0 and indexA == len(frames) - 1:
		return false
	return indexA > indexB

func start_spool() -> void:
	'''
	if silk_left:
		if len(current_frame_thread.incomplete_intersections) == 0:# If there are no incomplete intersections
			print("there are no incomplete intersections")
			# Cant create too close to the origin
			if (position - origin_intersection).length() > SPOOL_BORDER and within_borders():
				# Cant create too close to other threads
				for intersection in current_frame_thread.complete_intersections:
					if (position - intersection).length() < INTERSECTION_ERROR:
						return
						
				print("Spool Created!")
				spool_created_complete = false
				create_new_spool()
			else:
				print("Outside Borders")
		else:
			# Create spool from incomplete intersection
			print("Incomplete intersection, attempting to snap")
			var results = loop_intersections()
			chosen_intersection = results[0]
			intersection_found = results[1]
			
			if intersection_found:
				lerping = true
				starting_rotation = rotation
				desired_rotation = rotation
				starting_position = position
				desired_position = chosen_intersection
				
				timer.wait_time = SPOOL_ON_intersection
				spool_created_complete = true
				create_spool = true
				timer.start()
			else:
				print("Incomplete intersection too far away!")
	'''
	# Cant create too close to the origin
	if (position - origin_intersection).length() > SPOOL_BORDER and within_borders():
		# Cant create too close to other threads
		for intersection in current_frame_thread.complete_connections:
			if (position - intersection).length() < INTERSECTION_ERROR:
				return
		
		spool_start_on_incomplete_connection = false
		var result = loop_incomplete_intersections()
		if result[1]:
			position = result[0]
			spool_start_on_incomplete_connection = true
				
		create_new_spool()
			
## Checks if the players rotation is close to the rotation of the current frame thread
func correct_angle_frame(angle : float) -> bool:
	return (current_frame_thread.rotation < (angle + DEGREE_ERROR) 
	 and current_frame_thread.rotation > (angle - DEGREE_ERROR))

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
		on_spiral_thread = true

func exited_origin(_body: Node2D) -> void:
	var frame_index = frames.find(current_frame_thread)
	if not correct_angle_frame(rotation):
		modulo_frame_index(frame_index + len(frames) / 2)
		current_frame_thread = frames[frame_index]
		
## Loops over all intersections on the current frame thread and returns the first one that is close enough. 
## Returns the intersection, whether and intersection was found and whether it is a complete or incomplete intersection
func loop_intersections() -> Array:
	var complete = loop_complete_intersections()
	var incomplete = loop_incomplete_intersections()
	if complete[1]:
		return [complete[0], true, true]
	elif incomplete[1]:
		return [incomplete[0], true, false]
	return [Vector2.ZERO, false, false]
	
## Loops over all complete intersections on the current frame thread and returns the first one that is close enough
func loop_complete_intersections() -> Array:
	var _chosen_intersection : Vector2 
	var _intersection_found : bool
	for intersection in current_frame_thread.complete_connections:
		if (intersection - position).length() < INTERSECTION_ERROR:
			_chosen_intersection = intersection
			_intersection_found = true
	return [_chosen_intersection, _intersection_found]

## Loops over all incomplete intersections on the current frame thread and returns the first one that is close enough
func loop_incomplete_intersections() -> Array:
	var _chosen_intersection : Vector2 
	var _intersection_found : bool
	for intersection in current_frame_thread.incomplete_connections:
		if (intersection - position).length() < INTERSECTION_ERROR:
			_chosen_intersection = intersection
			_intersection_found = true
	return [_chosen_intersection, _intersection_found]
	
## Creates a blue line that will connect the player to the intersection point
func create_new_spool() -> void:
	# Create a blue line from the player to the intersection point
	spool_thread = Line2D.new()
	get_tree().current_scene.add_child(spool_thread)
	spool_start = position
	
	# Initialize points of line
	spool_thread.add_point(spool_start)
	spool_thread.add_point(position)
	
	# Set the properties of the line
	spool_thread.default_color = Color.AQUA
	spool_thread.width = 2.5
	spool_thread.z_index = 4
	
	# Set some variables to track the spool
	spooling = true
	spool_start_frame_thread = current_frame_thread
	
func end_spool() -> void:
	var starting_index = frames.find(spool_start_frame_thread)
	var end_index = frames.find(current_frame_thread)
	
	# Can't end the spool unless the starting frame thread is adjacent to the ending frame thread
	if modulo_frame_index(starting_index + 1) != end_index and modulo_frame_index(starting_index - 1) != end_index:
		delete_spool()
		return
	
	# Can't end the spool too close to the origin
	if (position - origin_intersection).length() < SPOOL_BORDER and not within_borders():
		delete_spool()
		return
		
	# Can't end the spool too close to a complete intersection
	var complete = loop_complete_intersections()
	if complete[1]:
		delete_spool()
		return
	
	var end_right_of_start = index_is_to_the_right(end_index, starting_index)
	
	# If the spool is ended close to an incomplete connection
	var spool_end_on_incomplete_intersection = false
	var incomplete = loop_incomplete_intersections()
	if incomplete[1]:
		position = incomplete[0]
		spool_end_on_incomplete_intersection = true
		
		# If the spool connects an incomplete connection on the wrong side 
		if end_right_of_start:
			if current_frame_thread.threads_left.has(position):
				delete_spool()
				return
		else:
			if current_frame_thread.threads_right.has(position):
				delete_spool()
				return
	
	# Create the two nodes on either side of the spiral thread
	var nodeA : Node2D = Node2D.new()
	nodeA.position = spool_start
	get_tree().current_scene.add_child(nodeA)
	
	var nodeB : Node2D = Node2D.new()
	nodeB.position = position
	get_tree().current_scene.add_child(nodeB)
	
	# Create the spiral thread and initialize it
	var thread_instance = spiral_thread_scene.instantiate()
	thread_instance.PointA = nodeA
	thread_instance.PointB = nodeB
	get_tree().current_scene.add_child(thread_instance)
	
	# Emit the Thread Created signal
	ThreadCreated.emit(thread_instance)
	
	# If the start of the spool was created on an incomplete intersection that intersection must now become complete
	if spool_start_on_incomplete_connection:
		erase_nearby(spool_start_frame_thread.incomplete_connections, spool_start)
		spool_start_frame_thread.complete_connections.append(spool_start)
	# Otherwise the spool has created an incomplete intersection
	else:
		spool_start_frame_thread.incomplete_connections.append(spool_start)
	
	# If the end of the spool was created on an incomplete intersection that intersection must now become complete
	if spool_end_on_incomplete_intersection:
		erase_nearby(current_frame_thread.incomplete_connections, position)
		current_frame_thread.complete_connections.append(position)
	# Otherwise the spool has created an incomplete intersection
	else:
		current_frame_thread.incomplete_connections.append(position)
		
	# If the current frame thread is to the right of the spool start frame thread
	if end_right_of_start:
		print("Ended the spool to the right of where the spool was started")
		spool_start_frame_thread.threads_right[spool_start] = thread_instance
		current_frame_thread.threads_left[position] = thread_instance
	else:
		print("Ended the spool to the left of where the spool was started")
		spool_start_frame_thread.threads_left[spool_start] = thread_instance
		current_frame_thread.threads_right[position] = thread_instance
	
	# Delete the blue line connecting the player to the intersection point
	delete_spool()

## Safely deletes the spool
func delete_spool() -> void:
	if spool_thread:
		spool_thread.queue_free()
		spool_thread = null
	spooling = false
	spool_start_frame_thread = null

'''
func end_spool()-> void:
	var starting_index = frames.find(spool_start_frame_thread)
	var end_index = frames.find(current_frame_thread)
	
	if spool_thread:
		if absi(end_index - starting_index) == 1 or (starting_index == len(frames) - 1 and end_index == 0) or (end_index == len(frames)-1 and starting_index == 0):# Cant end if you arent on an adjacent frame DOESNT WORK FOR thread 5 and 0
			if (position - origin_intersection).length() > SPOOL_BORDER and within_borders():# Cant create too close to the origin
				if len(current_frame_thread.incomplete_intersections) < 1: # If no incomplete
					if left_right_overlap_check(starting_index, end_index):
						for intersection in current_frame_thread.complete_intersections: #too close to completed
							if (position - intersection).length() > INTERSECTION_ERROR:
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
								ThreadCreated.emit(thread_instance)
								
								audio_stream_player.stream = MAKE_CONNECTION
								audio_stream_player.play()
								
								spool_thread.queue_free()
								spooling = false
								# update lists
								current_frame_thread.incomplete_intersections.append(position)
								if spool_created_complete:
									#print("Created a new complete intersection")
									spool_start_frame_thread.complete_intersections.append(spool_start)
									erase_nearby(spool_start_frame_thread.incomplete_intersections, spool_start)
								else:
									#print("Created a new incomplete intersection")
									spool_start_frame_thread.incomplete_intersections.append(spool_start)
								# update dicts
								if (end_index > starting_index or (starting_index == len(frames)-1 and end_index == 0)) and not (starting_index == 0 and end_index == len(frames) - 1):
									# Right of start. Left of end
									spool_start_frame_thread.threads_right[spool_start] = thread_instance
									current_frame_thread.threads_left[position] = thread_instance
								else:
									spool_start_frame_thread.threads_left[spool_start] = thread_instance
									current_frame_thread.threads_right[position] = thread_instance
								if loop_created(position):
									LoopCreated.emit()
								break
							else:
								print("too close to complete intersection")
								spool_thread.queue_free()
								spooling = false
					else:
						print("Overlap") # SNAPPPP
						spool_thread.queue_free()
						spooling = false
						
				else:
					print("There is an incomplete intersection on ending_frame")
					if left_right_overlap_check(starting_index, end_index):
						var results = loop_intersections()
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
							ThreadCreated.emit(thread_instance)
							
							audio_stream_player.stream = MAKE_CONNECTION
							audio_stream_player.play()
							
							spool_thread.queue_free()
							spooling = false
							# update lists
							current_frame_thread.complete_intersections.append(position)
							erase_nearby(current_frame_thread.incomplete_intersections, position)
							
							if spool_created_complete:
								#print("Created a new complete intersection")
								spool_start_frame_thread.complete_intersections.append(spool_start)
								erase_nearby(spool_start_frame_thread.incomplete_intersections, spool_start)
							else:
								#print("Created a new incomplete intersection")
								spool_start_frame_thread.incomplete_intersections.append(spool_start)
								
							# update dicts					
							if end_index > starting_index or (starting_index == len(frames)-1 and end_index == 0):
								# Right of start. Left of end
								spool_start_frame_thread.threads_right[spool_start] = thread_instance
								current_frame_thread.threads_left[position] = thread_instance
							else:
								spool_start_frame_thread.threads_left[spool_start] = thread_instance
								current_frame_thread.threads_right[position] = thread_instance
								
							if loop_created(position):
								LoopCreated.emit()
						else:
							print("Incomplete intersection too far away!")
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
'''

func within_borders():
	return (position.x > (- camera_dimensions[0]/2) 
			and position.x < (camera_dimensions[0]/2) 
			and position.y > (-camera_dimensions[1]/2) 
			and position.y < ( camera_dimensions[1]/2))

func left_right_overlap_check(s_i, e_i) -> bool:
	var _starting_index = s_i
	var _end_index = e_i
	var result : bool
	if (_end_index > _starting_index or (_starting_index == len(frames)-1 and _end_index == 0)) and not (_starting_index == 0 and _end_index == len(frames) - 1): 
		# Right of start. Left of end
		if len(spool_start_frame_thread.threads_right.values()) > 0:
			print("Right of start left of end")
			print(spool_start_frame_thread.threads_right)
			for thread in spool_start_frame_thread.threads_right.values():
				if (thread.PointA.position - spool_start).length() < INTERSECTION_ERROR:
					result = false
					break
				if (thread.PointB.position - position).length() < INTERSECTION_ERROR:
					result = false
					break
				var pointa_closer : bool = (thread.PointA.position - origin_intersection).length() > (spool_start - origin_intersection).length()
				var pointb_closer : bool = (thread.PointB.position - origin_intersection).length() > (position - origin_intersection).length()
				if pointa_closer and pointb_closer:
					result = true
				elif not pointa_closer and not pointb_closer:
					result = true
				else:
					result = false
					break
		else:
			result = true
	else:
		# Right of end. Left of start
		if len(spool_start_frame_thread.threads_left.values()) > 0:
			print("Right of end left of start")
			print(spool_start_frame_thread.threads_left)
			for thread in spool_start_frame_thread.threads_left.values():
				if (thread.PointA.position - spool_start).length() < INTERSECTION_ERROR:
					result = false
					break
				if (thread.PointB.position - position).length() < INTERSECTION_ERROR:
					result = false
					break
				var pointa_closer : bool = (thread.PointA.position - origin_intersection).length() > (spool_start - origin_intersection).length()
				var pointb_closer : bool = (thread.PointB.position - origin_intersection).length() > (position - origin_intersection).length()
				if pointa_closer and pointb_closer:
					result = true
				elif not pointa_closer and not pointb_closer:
					result = true
				else:
					result = false
					break
		else:
			result = true
	return result

## Loops over the array and searches for an intersection close enough. If there is it will delete it
func erase_nearby(intersections : Array[Vector2], pos : Vector2) -> void:
	for intersection in intersections:
		if (intersection - pos).length() < INTERSECTION_ERROR:
			intersections.erase(intersection)

func find_angle_from_two_positions(pointA : Vector2, pointB : Vector2) -> float:
	var offset : Vector2 = pointB - pointA
	var angle : float
	if  pointA.y > pointB.y:
		angle = PI - atan(offset.x / offset.y) + PI / 2
	else:
		angle = -atan(offset.x / offset.y) + PI / 2
	angle = fmod(angle, 2.0 * PI)
	return angle

func loop_created(starting_position : Vector2) -> bool:
	var frame = current_frame_thread
	var pos : Vector2 = starting_position
	for i in range(0, len(frames)):
		if len(frame.threads_right.keys()) > 0:
			var chosen_key : Vector2
			var key_found : bool
			for key in frame.threads_right.keys():
				if (key - pos).length() < INTERSECTION_ERROR:
					chosen_key = key
					key_found = true
			var thread : SpiralThread
			if key_found:
				thread = frame.threads_right[chosen_key]
			else:
				print("No keys nearby")
				return false
			if (pos - thread.PointA.position).length() > (pos - thread.PointB.position).length():
				# Closer to point B
				if (pos - thread.PointB.position).length() < INTERSECTION_ERROR:
					pos = thread.PointA.position
				else:
					print("Not close enough to point")
					return false
			else:
				if (pos - thread.PointA.position).length() < INTERSECTION_ERROR:
					pos = thread.PointB.position
				else:
					print("Not close enough to point")
					return false
			var frame_index = frames.find(frame)
			frame_index += 1
			frame_index %= len(frames)
			frame = frames[frame_index]
		else:
			print("No Keys")
			return false
	if (pos - starting_position).length() < INTERSECTION_ERROR:
		return true
	else:
		return false

func _on_insect_spawner_insect_created(insect: Insect) -> void:
	insect.Eaten.connect(_on_insect_eaten)
	
func _on_insect_eaten(insect : Insect) -> void:
	InsectEaten.emit(insect)
	audio_stream_player.stream = EAT_FLY
	audio_stream_player.play()

func _on_insect_spawner_wasp_created(wasp: Wasp) -> void:
	wasp.spider = self

func turn() -> void:
	var results = loop_intersections()
	chosen_intersection = results[0]
	intersection_found = results[1]
	if not current_spiral_thread:
# --------------------------------------------------------If not near origin and turning

		if not intersection_found: 
			'''
		# ------------------------------------ 180 DEGREE TURN ON A FRAME
		
			if Input.get_axis("TurnLeft", "TurnRight") > 0:
				#  --------------------- If turning right
				desired_rotation = PI + rotation
				starting_rotation = rotation
				desired_position = position
				starting_position = position
				
			else:
				# --------------------- If turning left
				desired_rotation = rotation - PI
				starting_rotation = rotation
				desired_position = position
				starting_position = position
			timer.wait_time = FULL_TURN_TIME
			timer.start()
			lerping = true
			'''
			pass
			
			
		elif chosen_intersection == origin_intersection: 
# -------------------------------------------------------- If near origin and turning  
			if Input.get_axis("TurnLeft", "TurnRight") > 0:
				#  --------------------- If turning right
				var frame_index = frames.find(current_frame_thread)
				
				if correct_angle_frame(fmod(PI + rotation, 2.0 * PI)):
					frame_index += 3
				
				frame_index += 1
				frame_index %= len(frames)
				
				desired_rotation = frames[frame_index].rotation
				starting_rotation = rotation
				if desired_rotation < starting_rotation:
					starting_rotation -= 2.0 * PI
				desired_position = origin_intersection
				starting_position = position
				current_frame_thread = frames[frame_index]
				lerping = true
				timer.wait_time = ORIGIN_TURN_TIME
				timer.start()
			else:
				#  --------------------- If turning left
				var frame_index = frames.find(current_frame_thread)
				
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
				desired_position = origin_intersection
				starting_position = position
				current_frame_thread = frames[frame_index]
				lerping = true
				timer.wait_time = ORIGIN_TURN_TIME
				timer.start()
		else: 
# ---------------------------------------------------- Near a THREAD intersection
			if Input.get_axis("TurnLeft", "TurnRight") > 0:
				# -------------------If we are turning right
				if correct_angle_frame(rotation) or correct_angle_frame(fmod(PI + rotation, 2.0 * PI)):
					# --------------- finding the threads on the right side
					# Turning on frame thread
					
					var frame_dict : Dictionary[Vector2, SpiralThread]
					var current_frame_thread_index : int = frames.find(current_frame_thread)
					var approaching_frame_thread_index : int
					if correct_angle_frame(rotation): # IF AWAY FROM ORIGIN - WANT THREADS ON RIGHT
						frame_dict = current_frame_thread.threads_right
						approaching_frame_thread_index = current_frame_thread_index + 1
						approaching_frame_thread_index %= len(frames)
						moving_right = true
					else: # IF TO ORIGIN - WANT THREADS ON LEFT
						frame_dict = current_frame_thread.threads_left
						approaching_frame_thread_index = current_frame_thread_index - 1
						if approaching_frame_thread_index < 0:
							approaching_frame_thread_index = len(frames) - 1
						moving_right = false
						
						
					if len(frame_dict.keys()) > 0:
						# If there is a spiral thread in dict
						# Find closest point on the thread that is closest
						var nearby_intersection : bool
						for thread_position in frame_dict.keys():
							if (thread_position - position).length() < INTERSECTION_ERROR:
								nearby_intersection = true
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
								
								# LERP to intersection
								var angle = find_angle_from_two_positions(pointA, pointB)
								if angle < rotation:
									rotation -= 2.0 * PI
								desired_rotation = angle # -------- LERP ONTO THREAD
								starting_rotation = rotation
								desired_position = pointA
								starting_position = position
								lerping = true
								turning_on_thread = true
								turn_to_thread = thread
								current_spiral_thread = null
								approaching_frame_thread = frames[approaching_frame_thread_index]
								spiral_thread_end = pointB
								timer.wait_time = ORIGIN_TURN_TIME
								timer.start()
								break
							
						if not nearby_intersection:
							desired_rotation = PI + rotation # ------- LERP 180
							starting_rotation = rotation 
							desired_position = position
							starting_position = position
							timer.wait_time = FULL_TURN_TIME
							timer.start()
							lerping = true
							
					else:
						# --------- LERP 180
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
						var angle : float = fmod(PI + current_frame_thread.rotation, 2.0 * PI)
						if angle < rotation:
							rotation -= 2.0 * PI
						desired_rotation = angle # ------- LERP ONTO FRAME
						starting_rotation = rotation
						desired_position = position
						starting_position = position
						lerping = true
						timer.wait_time = ORIGIN_TURN_TIME
						timer.start()
						current_spiral_thread = null
						on_spiral_thread = false
					else:
						var angle : float = current_frame_thread.rotation
						if angle < rotation:
							rotation -= 2.0 * PI
						desired_rotation = angle # ------- LERP ONTO FRAME
						starting_rotation = rotation
						desired_position = position
						starting_position = position
						lerping = true
						timer.wait_time = ORIGIN_TURN_TIME
						timer.start()
						current_spiral_thread = null
						on_spiral_thread = false
			else:
				# If we are turning left
				if correct_angle_frame(rotation) or correct_angle_frame(fmod(PI + rotation, 2.0 * PI)):
					# Turning on frame thread
					var frame_dict : Dictionary[Vector2, SpiralThread]
					var current_frame_thread_index : int = frames.find(current_frame_thread)
					var approaching_frame_thread_index : int
					if correct_angle_frame(rotation):
						frame_dict = current_frame_thread.threads_left
						approaching_frame_thread_index = current_frame_thread_index - 1
						if approaching_frame_thread_index < 0:
							approaching_frame_thread_index = len(frames) - 1
						moving_right = false
					else:
						frame_dict = current_frame_thread.threads_right
						approaching_frame_thread_index = current_frame_thread_index + 1
						approaching_frame_thread_index %= len(frames)
						moving_right = true
						
						
					if len(frame_dict.keys()) > 0:
						var nearby_intersection : bool
						for thread_position in frame_dict.keys():
							if (thread_position - position).length() < INTERSECTION_ERROR:
								nearby_intersection = true
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
								desired_rotation = angle # ------- LERP ONTO THREAD
								starting_rotation = rotation
								desired_position = pointA
								starting_position = position
								lerping = true
								turning_on_thread = true
								turn_to_thread = thread
								current_spiral_thread = null
								approaching_frame_thread = frames[approaching_frame_thread_index]
								spiral_thread_end = pointB
								timer.wait_time = ORIGIN_TURN_TIME
								timer.start()
								break
						if not nearby_intersection: # ---
							desired_rotation = rotation - PI  # ------- LERP 180
							starting_rotation = rotation
							desired_position = position
							starting_position = position
							timer.wait_time = FULL_TURN_TIME
							timer.start()
							lerping = true
					else:
						desired_rotation = rotation - PI # ------- LERP 180
						starting_rotation = rotation
						desired_position = position
						starting_position = position
						timer.wait_time = FULL_TURN_TIME
						timer.start()
						lerping = true
				else:
					# Turning on spiral thread
					if moving_right:
						var angle : float = current_frame_thread.rotation
						if angle > rotation:
							rotation += 2.0 * PI
						desired_rotation = angle  # ------- LERP ONTO FRAME
						starting_rotation = rotation
						desired_position = position
						starting_position = position
						lerping = true
						timer.wait_time = ORIGIN_TURN_TIME
						timer.start()
						current_spiral_thread = null
						on_spiral_thread = false
					else:
						var angle : float = fmod(PI + current_frame_thread.rotation, 2.0 * PI)
						if angle > rotation:
							rotation += 2.0 * PI
						desired_rotation = angle # ------ LERP ONTO FRAME
						starting_rotation = rotation
						desired_position = position
						starting_position = position
						lerping = true
						timer.wait_time = ORIGIN_TURN_TIME
						timer.start()
						current_spiral_thread = null
						on_spiral_thread = false
					pass
	elif current_spiral_thread:
		if intersection_found:
			if moving_right:
				if Input.get_axis("TurnLeft", "TurnRight") > 0:
					# Turning right
					var angle : float
					angle = fmod(PI + current_frame_thread.rotation, 2.0 * PI)
					if angle < rotation:
						rotation -= 2.0 * PI
					desired_rotation = angle
					starting_rotation = rotation
					desired_position = chosen_intersection
					starting_position = position
					lerping = true
					timer.wait_time = ORIGIN_TURN_TIME
					timer.start()
					current_spiral_thread = null
					on_spiral_thread = false
				else:
					# Turning left
					var angle : float
					angle = current_frame_thread.rotation
					if angle > rotation:
						rotation += 2.0 * PI
					desired_rotation = angle
					starting_rotation = rotation
					desired_position = chosen_intersection
					starting_position = position
					lerping = true
					timer.wait_time = ORIGIN_TURN_TIME
					timer.start()
					current_spiral_thread = null
					on_spiral_thread = false
			else:
				if Input.get_axis("TurnLeft", "TurnRight") > 0:
					# Turning right
					var angle : float
					angle = current_frame_thread.rotation
					if angle < rotation:
						rotation -= 2.0 * PI
					desired_rotation = angle
					starting_rotation = rotation
					desired_position = chosen_intersection
					starting_position = position
					lerping = true
					timer.wait_time = ORIGIN_TURN_TIME
					timer.start()
					current_spiral_thread = null
					on_spiral_thread = false
				else:
					# Turning left
					var angle : float
					angle = fmod(PI + current_frame_thread.rotation, 2.0 * PI)
					if angle > rotation:
						rotation += 2.0 * PI
					desired_rotation = angle
					starting_rotation = rotation
					desired_position = chosen_intersection
					starting_position = position
					lerping = true
					timer.wait_time = ORIGIN_TURN_TIME
					timer.start()
					current_spiral_thread = null
					on_spiral_thread = false
		else:
			if Input.get_axis("TurnLeft", "TurnRight") > 0:
				
				# Turn right 180
				# if close snap to frame, facing outwards
				desired_rotation = PI + rotation # ----------- LERP 180
				starting_rotation = rotation
				desired_position = position
				starting_position = position
				timer.wait_time = FULL_TURN_TIME
				lerping = true
				moving_right = not moving_right
				
				var approaching_frame_thread_index : int
				
				if moving_right:
					approaching_frame_thread_index = frames.find(approaching_frame_thread) + 1
					approaching_frame_thread_index %= len(frames)
				else:
					approaching_frame_thread_index = frames.find(approaching_frame_thread) - 1
					if approaching_frame_thread_index < 0:
						approaching_frame_thread_index = len(frames) - 1
						
				approaching_frame_thread = frames[approaching_frame_thread_index]
				
				if (spiral_thread_end - current_spiral_thread.PointA.position).length() < INTERSECTION_ERROR:
					spiral_thread_end = current_spiral_thread.PointB.position
				elif (spiral_thread_end - current_spiral_thread.PointB.position).length() < INTERSECTION_ERROR:
					spiral_thread_end = current_spiral_thread.PointA.position
				
				timer.start()
			else:
				# Turn left 180
				#if close snap to frame, facing inwards
				desired_rotation =  rotation - PI # ---------- LERP 180
				starting_rotation = rotation
				desired_position = position
				starting_position = position
				timer.wait_time = FULL_TURN_TIME
				lerping = true
				moving_right = not moving_right
				
				var approaching_frame_thread_index : int
				
				if moving_right:
					approaching_frame_thread_index = frames.find(approaching_frame_thread) + 1
					approaching_frame_thread_index %= len(frames)
				else:
					approaching_frame_thread_index = frames.find(approaching_frame_thread) - 1
					if approaching_frame_thread_index < 0:
						approaching_frame_thread_index = len(frames) - 1
				
				approaching_frame_thread = frames[approaching_frame_thread_index]
				
				if (spiral_thread_end - current_spiral_thread.PointA.position).length() < INTERSECTION_ERROR:
					spiral_thread_end = current_spiral_thread.PointB.position
				elif (spiral_thread_end - current_spiral_thread.PointB.position).length() < INTERSECTION_ERROR:
					spiral_thread_end = current_spiral_thread.PointA.position
					
				timer.start()
