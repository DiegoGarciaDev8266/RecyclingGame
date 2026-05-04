extends Node2D

const FONDO_LIMPIO = preload("res://Assets/fondo_limpio.png")
const FONDO_SUCIO = preload("res://Assets/fondo_contaminado.svg")

func _ready():
	var puntaje = GameState.puntaje
	var gano = GameState.gano

	$CanvasLayer/PuntajeFinal.text = "Puntuacion final: %d" % puntaje

	if GameState.modo_supervivencia:
		$CanvasLayer/FondoGameOver.texture = FONDO_SUCIO
		$CanvasLayer/TituloLabel.text = "¡Se acabó!"
		$CanvasLayer/TituloLabel.modulate = Color(1.0, 0.6, 0.0)
		$CanvasLayer/MensajeLabel.text = "Sobreviviste hasta\n%d puntos" % puntaje
		MusicManager.play_lose()
		return

	$CanvasLayer/FondoGameOver.texture = FONDO_LIMPIO if gano else FONDO_SUCIO
	if gano:
		$CanvasLayer/TituloLabel.text = "¡Ganaste!"
		$CanvasLayer/TituloLabel.modulate = Color(0.2, 0.9, 0.2)
		$CanvasLayer/MensajeLabel.text = "¡Excelente trabajo reciclando!\nEl planeta te lo agradece."
		MusicManager.play_victory()
	else:
		$CanvasLayer/TituloLabel.text = "Game Over"
		$CanvasLayer/TituloLabel.modulate = Color(0.9, 0.2, 0.2)
		$CanvasLayer/MensajeLabel.text = "El medio ambiente necesita tu ayuda.\n¡Intentalo de nuevo!"
		MusicManager.play_lose()

func _on_btn_reintentar_pressed():
	get_tree().paused = false
	MusicManager.stop()
	MusicManager.stop_sfx()
	GameState.resetear()
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_btn_menu_pressed():
	get_tree().paused = false
	MusicManager.stop()
	MusicManager.stop_sfx()
	GameState.resetear()
	get_tree().change_scene_to_file("res://Scenes/PantallaInicio.tscn")
