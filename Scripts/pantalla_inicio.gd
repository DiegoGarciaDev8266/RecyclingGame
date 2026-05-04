extends Node2D

func _ready():
	GameState.resetear()

func _on_btn_facil_pressed():
	GameState.dificultad = 1
	GameState.modo_supervivencia = false
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_btn_normal_pressed():
	GameState.dificultad = 2
	GameState.modo_supervivencia = false
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_btn_dificil_pressed():
	GameState.dificultad = 3
	GameState.modo_supervivencia = false
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_btn_supervivencia_pressed():  # ← nuevo botón
	GameState.dificultad = 3
	GameState.modo_supervivencia = true
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")
