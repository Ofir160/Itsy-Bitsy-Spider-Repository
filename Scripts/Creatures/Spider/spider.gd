class_name Spider
extends CharacterBody2D

signal ThreadCreated(thread : SpiralThread)
signal InsectEaten(insect : Insect)
signal LoopCreated()

@export var frames : Array[FrameThread]
@export var initial_frame : FrameThread
@export var origin_intersection : Vector2
@onready var timer: Timer = $Timer
@export var spiral_threads : Array[SpiralThread]
@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 200.0
const DEGREE_ERROR = 10 * PI / 180
const intersection_ERROR = 20.0
const ORIGIN_TURN_TIME = 0.2
const FULL_TURN_TIME = 0.5
const SPOOL_ON_intersection = 0.15
const SPOOL_BORDER = 75.0

const EAT_FLY = preload("res://Assets/Audio/SFX/eat_fly.mp3")
const MAKE_CONNECTION = preload("res://Assets/Audio/SFX/make_connection.mp3")
const SPIDER_WALK = preload("res://Assets/Audio/SFX/spider_walk.mp3")

var thread_scene = preload("res://Scenes/Creatures/Spider/Threads/frame_thread.tscn")
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
var spool_created_complete : bool
var silk_left : bool = true

var intersection_found : bool
var chosen_intersection : Vector2

var on_intersection : bool
var intersection : Vector2

func _ready() -> void:
	current_frame_thread = initial_frame
	for frame in frames:
		frame.complete_connections.append(origin_intersection)
	camera_dimensions = get_viewport().size

func _physics_process(delta: float) -> void:
	turn_to_mouse()
	if Input.is_action_pressed("MoveForward"):
		move(delta)
	'''
	if not lerping:
		if Input.is_action_pressed("MoveForward"):
			move(delta)
		else:
			animated_sprite.play("Idle")
		if Input.get_axis("TurnLeft", "TurnRight") != 0:
			turn()
		if Input.is_action_just_pressed("Spool"):
			spool()
		if spooling:
			spool_thread.points[1].x = position.x
			spool_thread.points[1].y = position.y
		if Input.is_action_just_released("Spool") or lerping_spool_released:
			lerping_spool_released = false
			if current_frame_thread:
				# Finish the thread	
				end_spool()
			else:
				# Delete the thread	
				if spool_thread:
					spool_thread.queue_free()
				spooling = false
	else:
		if Input.is_action_just_released("Spool"):
			lerping_spool_released = true
		
		var t = (timer.wait_time - timer.time_left) / timer.wait_time
		rotation = lerp(starting_rotation, desired_rotation, t * t * (3 - 2 * t))
		position = lerp(starting_position, desired_position, t * t * (3 - 2 * t))
	'''

func move(delta : float) -> void:
	if on_spiral_thread:
		
		# Sets visuals and audio
		audio_stream_player.stream = SPIDER_WALK
		audio_stream_player.play()
		animated_sprite.play("Move")
		
		# Calculates player orientation and moves the player
		var orientation : Vector2 = Vector2(cos(-rotation), sin(rotation))
		position += orientation * SPEED * delta
		
		current_spiral_thread = turn_to_thread
		
		if (spiral_thread_end - position).length() < intersection_ERROR:
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
					if (thread.PointB.position - position).length() < intersection_ERROR:
						chosen_thread = thread
						thread_found = true
						break
				else:
					# If point A is closer
					if (thread.PointA.position - position).length() < intersection_ERROR:
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
	var mouse_pos = get_local_mouse_position()
	
	if on_intersection:
		if intersection == origin_intersection:
			pass
	else:
		if mouse_pos.x < 0:
			# Need to turn around
			rotation *= -1
			
func check_on_intersection() -> void:
	var results : Array = loop_intersections()
	on_intersection = results[1]
	intersection = results[0]

func spool() -> void:
	if silk_left:
		if len(current_frame_thread.incomplete_intersections) == 0:# If there are no incomplete intersections
			print("there are no incomplete intersections")
			if (position - origin_intersection).length() > SPOOL_BORDER and within_borders():# Cant create too close to the original
				# Cant create too close to other threads
				for intersection in current_frame_thread.complete_intersections:
					if (position - intersection).length() < intersection_ERROR:
						return
				print("Spool Created!")
				spool_created_complete = false
				create_new_spool()
			else:
				print("Outside Borders")
		else:
			# create spool from incomplete intersection
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
							if (thread_position - position).length() < intersection_ERROR:
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
							if (thread_position - position).length() < intersection_ERROR:
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
				
				if (spiral_thread_end - current_spiral_thread.PointA.position).length() < intersection_ERROR:
					spiral_thread_end = current_spiral_thread.PointB.position
				elif (spiral_thread_end - current_spiral_thread.PointB.position).length() < intersection_ERROR:
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
				
				if (spiral_thread_end - current_spiral_thread.PointA.position).length() < intersection_ERROR:
					spiral_thread_end = current_spiral_thread.PointB.position
				elif (spiral_thread_end - current_spiral_thread.PointB.position).length() < intersection_ERROR:
					spiral_thread_end = current_spiral_thread.PointA.position
					
				timer.start()

func change_thread() -> void:
	pass
	
func correct_angle_frame(angle : float) -> bool:
	return current_frame_thread.rotation < (angle + DEGREE_ERROR)  and current_frame_thread.rotation > angle - DEGREE_ERROR

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
		on_spiral_thread = true

func _on_origin_snap_zone_body_exited(_body: Node2D) -> void:
	var frame_index = frames.find(current_frame_thread)
	if not correct_angle_frame(rotation):
		@warning_ignore("integer_division")
		frame_index += int(len(frames) / 2)
		frame_index %= len(frames)
		current_frame_thread = frames[frame_index]

func loop_intersections() -> Array:
	var _chosen_intersection : Vector2 
	var _intersection_found : bool
	for intersection in current_frame_thread.complete_connections + current_frame_thread.incomplete_connections:
		if (intersection - position).length() < intersection_ERROR:
			_chosen_intersection = intersection
			_intersection_found = true
	return [_chosen_intersection, _intersection_found]
	
func create_new_spool() -> void:
	#create spool from wherever since there are no incomplete intersections
	spool_thread = Line2D.new()
	get_tree().current_scene.add_child(spool_thread)
	spool_start = position
	spool_thread.add_point(spool_start)
	spool_thread.add_point(position)
	spool_thread.default_color = Color.AQUA
	spool_thread.width = 2.5
	spool_thread.z_index = 4
	spooling = true
	spool_start_frame_thread = current_frame_thread
	
func end_spool()-> void:
	var starting_index = frames.find(spool_start_frame_thread)
	var end_index = frames.find(current_frame_thread)
	
	if spool_thread:
		if absi(end_index - starting_index) == 1 or (starting_index == len(frames) - 1 and end_index == 0) or (end_index == len(frames)-1 and starting_index == 0):# Cant end if you arent on an adjacent frame DOESNT WORK FOR thread 5 and 0
			if (position - origin_intersection).length() > SPOOL_BORDER and within_borders():# Cant create too close to the origin
				if len(current_frame_thread.incomplete_intersections) < 1: # If no incomplete
					if left_right_overlap_check(starting_index, end_index):
						for intersection in current_frame_thread.complete_intersections: #too close to completed
							if (position - intersection).length() > intersection_ERROR:
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
	
func within_borders():
	return position.x > (- camera_dimensions[0]/2) and position.x < (camera_dimensions[0]/2) and position.y > (-camera_dimensions[1]/2) and position.y < ( camera_dimensions[1]/2)

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
				if (thread.PointA.position - spool_start).length() < intersection_ERROR:
					result = false
					break
				if (thread.PointB.position - position).length() < intersection_ERROR:
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
				if (thread.PointA.position - spool_start).length() < intersection_ERROR:
					result = false
					break
				if (thread.PointB.position - position).length() < intersection_ERROR:
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
			
func erase_nearby(intersections : Array[Vector2], position : Vector2) -> void:
	for intersection in intersections:
		if (intersection - position).length() < intersection_ERROR:
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
				if (key - pos).length() < intersection_ERROR:
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
				if (pos - thread.PointB.position).length() < intersection_ERROR:
					pos = thread.PointA.position
				else:
					print("Not close enough to point")
					return false
			else:
				if (pos - thread.PointA.position).length() < intersection_ERROR:
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
	if (pos - starting_position).length() < intersection_ERROR:
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
