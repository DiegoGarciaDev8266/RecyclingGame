extends Node2D

func _ready():
	var label = get_node_or_null("CanvasLayer/PuntajeFinal")
	if label:
		label.text = "Puntuación: %d" % GameState.puntaje

func _on_btn_reintentar_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_btn_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/PantallaInicio.tscn")
