extends Node

var level_stars : int
@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

const DYING_TIME = 0.5

var cutscene_1 = "res://Scenes/cutscene_1.tscn"
var introduction = "res://Scenes/introduction.tscn"
var level_1 = "res://Scenes/level_1.tscn"
var cutscene_2 = "res://Scenes/cutscene_2.tscn"
var cutscene_3 = "res://Scenes/cutscene_3.tscn"
var level_2 = "res://Scenes/level_2.tscn"
var cutscene_4 = "res://Scenes/cutscene_4.tscn"
var cutscene_5 = "res://Scenes/cutscene_5.tscn"
var cutscene_6 = "res://Scenes/cutscene_6.tscn"
var level_3 = "res://Scenes/level_3.tscn"
var cutscene_7 = "res://Scenes/cutscene_7.tscn"
var cutscene_8 = "res://Scenes/cutscene_8.tscn"
var cutscene_9 = "res://Scenes/cutscene_9.tscn"
var cutscene_10 = "res://Scenes/cutscene_10.tscn"

var scenes
var music

var game_over_scene = "res://Scenes/game_over.tscn"
var level_selector = "res://Scenes/level_select.tscn"
var level_complete = "res://Scenes/level_complete.tscn"

# First cutscene and eight cutscene
const morning = preload("res://Assets/Audio/Music/Morning.mp3")

# First level and second cutscene and third cutscene
const carpe_diem = preload("res://Assets/Audio/Music/Carpe Diem.mp3")

# Second level
const mischief_maker = preload("res://Assets/Audio/Music/Mischief Maker.mp3")

# Fourth cutscene and fifth cutscene
const montauk_point = preload("res://Assets/Audio/Music/Montauk Point.mp3")

# Sixth cutsence
const intrepid = preload("res://Assets/Audio/Music/Intrepid.mp3")

# Third level
const satiate = preload("res://Assets/Audio/Music/Satiate.mp3")

# Seventh cutscene
const royal_coupling = preload("res://Assets/Audio/Music/Royal Coupling.mp3")

const off_to_osaka = preload("res://Assets/Audio/Music/Off to Osaka.mp3")

var playing : bool
var current_scene : int 
var scene_progress : int

func _ready() -> void:
	scenes = [cutscene_1, introduction, level_1, cutscene_2, cutscene_3, level_2, cutscene_4, cutscene_5, cutscene_6, level_3, cutscene_7, cutscene_8, cutscene_9, cutscene_10]
	music = [morning, morning, carpe_diem, carpe_diem, carpe_diem, mischief_maker, montauk_point, montauk_point, intrepid, satiate, royal_coupling, morning, morning, off_to_osaka]
	current_scene = 0
	playing = true
	audio_stream_player.stream = music[current_scene]
	audio_stream_player.play()
	SceneSwitcher.switch_scene(scenes[current_scene])

func game_over() -> void:
	SceneSwitcher.switch_scene(game_over_scene)
	
func finish_scene() -> void:
	current_scene += 1
	if current_scene >= len(scenes):
		get_tree().quit()
	else:
		if audio_stream_player.stream != music[current_scene]:
			audio_stream_player.stream = music[current_scene]
			audio_stream_player.play()
		SceneSwitcher.switch_scene(scenes[current_scene])
	
func complete_level(stars : int) -> void:
	level_stars = stars
	SceneSwitcher.switch_scene(level_complete)
