extends Node2D

const BasuraItemScene = preload("res://Scenes/BasuraItem.tscn")

var puntaje := 0
var vidas := 3
var nivel := 1

@onready var timer_spawn = $TimerSpawn
@onready var puntaje_label = $CanvasLayer/PuntajeLabel
@onready var nivel_label = $CanvasLayer/NivelLabel
@onready var feedback_label = $CanvasLayer/FeedbackLabel
@onready var corazones = [
	$CanvasLayer/Corazones/TextureRect,
	$CanvasLayer/Corazones/TextureRect2,
	$CanvasLayer/Corazones/TextureRect3
]

func _ready():
	timer_spawn.wait_time = 2.5
	timer_spawn.connect("timeout", _on_spawn_timeout)
	timer_spawn.start()
	actualizar_hud()
	$BandaTransportadora.connect("item_listo", _on_item_listo_en_banda)
	_pedir_siguiente_item()

func _on_spawn_timeout():
	pass

func _pedir_siguiente_item():
	var tipo = randi() % 3
	var variante = randi() % 3
	$BandaTransportadora.spawn_siguiente(tipo, variante)

func _on_item_listo_en_banda(item):
	if not is_instance_valid(item):
		return
	item.connect("dropped", _on_item_dropped)
	await get_tree().create_timer(5.0, false).timeout
	if not is_inside_tree() or not is_instance_valid(self):
		return
	if is_instance_valid(item) and item.get_parent() == $BandaTransportadora:
		perder_vida()
		mostrar_feedback("¡Se escapó!", Color.ORANGE)
		item.queue_free()
		$BandaTransportadora.liberar_banda()
		_pedir_siguiente_item()

func _on_item_dropped(item):
	var cestos = $Cestos.get_children()
	var acertó = false
	for cesto in cestos:
		if cesto.get_overlapping_areas().has(item):
			var tipo_cesto = cesto.get_meta("tipo")
			if item.tipo == tipo_cesto:
				puntaje += 10 * nivel
				mostrar_feedback("¡Correcto! +%d" % (10 * nivel), Color.GREEN)
				acertó = true
			else:
				mostrar_feedback("¡Error! Tipo equivocado", Color.RED)
				perder_vida()
			break
	if not acertó and not _sobre_algun_cesto(item):
		item.global_position = $BandaTransportadora/SpawnPoint.global_position
		return
	item.queue_free()
	$BandaTransportadora.liberar_banda()
	_revisar_nivel()
	actualizar_hud()
	_pedir_siguiente_item()

func _sobre_algun_cesto(item) -> bool:
	for cesto in $Cestos.get_children():
		if cesto.get_overlapping_areas().has(item):
			return true
	return false
	
const CORAZON_VACIO = preload("res://Assets/corazon_vacio.svg")
func perder_vida():
	if vidas <= 0:
		return
	corazones[vidas - 1].texture = CORAZON_VACIO
	vidas -= 1
	actualizar_hud()
	if vidas <= 0:
		game_over()

func _revisar_nivel():
	var nuevo = 1 + puntaje / 100.0
	if nuevo > nivel:
		nivel = int(nuevo)
		$BandaTransportadora.velocidad += 20.0
		mostrar_feedback("⬆ Nivel %d" % nivel, Color.YELLOW)

func mostrar_feedback(texto: String, color: Color):
	if not is_instance_valid(feedback_label):
		return
	if not is_inside_tree():
		return
	feedback_label.text = texto
	feedback_label.modulate = color
	feedback_label.visible = true
	await get_tree().create_timer(1.2, false).timeout
	if is_instance_valid(feedback_label):
		feedback_label.visible = false

func actualizar_hud():
	puntaje_label.text = "Puntos: %d" % puntaje
	nivel_label.text = "Nivel %d" % nivel

func game_over():
	GameState.puntaje = puntaje
	GameState.nivel = nivel
	get_tree().paused = true
	get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")
