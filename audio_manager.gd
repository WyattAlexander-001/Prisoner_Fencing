extends Node

@onready var TitleMusic: AudioStreamPlayer = $TitleMusic
@onready var GameMusic: AudioStreamPlayer = $GameMusic

func _ready():
	# Start playing title music automatically
	TitleMusic.play()

func play_title_music():
	if not TitleMusic.playing:
		TitleMusic.play()
	if GameMusic.playing:
		GameMusic.stop()

func play_game_music():
	if not GameMusic.playing:
		GameMusic.play()
	if TitleMusic.playing:
		TitleMusic.stop()

func stop_all_music():
	TitleMusic.stop()
	GameMusic.stop()
