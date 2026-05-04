extends Node

const MENU_MUSIC = preload("res://Music/Main.ogg")
const CORRECT_SFX = preload("res://Music/Correct.wav")
const ERROR_SFX = preload("res://Music/Error.ogg")
const VICTORY_MUSIC = preload("res://Music/Victory.ogg")
const LOSE_MUSIC = preload("res://Music/You_Lose.mp3")

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	add_child(sfx_player)

func play_menu():
	_play_music(MENU_MUSIC)

func play_game():
	_play_music(MENU_MUSIC)

func play_victory():
	_play_music(VICTORY_MUSIC, false)

func play_lose():
	_play_music(LOSE_MUSIC, false)

func play_correct():
	sfx_player.stream = CORRECT_SFX
	sfx_player.play()

func play_error():
	sfx_player.stream = ERROR_SFX
	sfx_player.play()

func stop():
	music_player.stop()

func stop_sfx():
	sfx_player.stop()

func _play_music(stream: AudioStream, loop: bool = true):
	if music_player.stream == stream and music_player.playing:
		return
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	elif stream is AudioStreamOggVorbis:
		stream.loop = loop
	music_player.stream = stream
	music_player.play()
