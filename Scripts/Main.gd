extends Node2D

const BasuraItemScene = preload("res://Scenes/BasuraItem.tscn")

var puntaje := 0
var vidas := 3
var nivel := 1
var nivel_contaminacion := 0.5
var material_fondo: ShaderMaterial
var item_arrastrado = null
var offset_arrastre := Vector2.ZERO

@onready var timer_spawn = $TimerSpawn
@onready var puntaje_label = $CanvasLayer/PuntajeLabel
@onready var nivel_label = $CanvasLayer/NivelLabel
@onready var feedback_label = $CanvasLayer/FeedbackLabel
@onready var fondo = $ColorRect
@onready var corazones = [
	$CanvasLayer/Corazones/TextureRect,
	$CanvasLayer/Corazones/TextureRect2,
	$CanvasLayer/Corazones/TextureRect3
]

const CORAZON_VACIO = preload("res://Assets/corazon_vacio.svg")

func _ready():
	timer_spawn.wait_time = 5.0
	timer_spawn.connect("timeout", _on_spawn_timeout)
	timer_spawn.start()
	actualizar_hud()
	$BandaTransportadora.connect("item_listo", _on_item_listo_en_banda)
	feedback_label.visible = false
	_pedir_siguiente_item()
	material_fondo = fondo.material
	if material_fondo:
		material_fondo.set_shader_parameter("contaminacion", nivel_contaminacion)

func _process(_delta):
	if material_fondo:
		material_fondo.set_shader_parameter(
			"tiempo",
			Time.get_ticks_msec() / 1000.0
		)
	if item_arrastrado and is_instance_valid(item_arrastrado):
		item_arrastrado.global_position = get_global_mouse_position() + offset_arrastre

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_intentar_agarrar(get_global_mouse_position())
		else:
			if item_arrastrado:
				_soltar_item()

func _intentar_agarrar(mouse_pos: Vector2):
	var items = $BandaTransportadora.items_en_banda
	for item in items:
		if not is_instance_valid(item):
			continue
		if not item.pickable:
			continue
		var distancia = mouse_pos.distance_to(item.global_position)
		if distancia < 40.0:
			item_arrastrado = item
			item_arrastrado.dragging = true
			item_arrastrado.en_banda = false
			item_arrastrado.pos_en_banda = item.global_position
			offset_arrastre = item.global_position - mouse_pos
			return

func _soltar_item():
	if not is_instance_valid(item_arrastrado):
		item_arrastrado = null
		return
	item_arrastrado.dragging = false
	var cesto = _cesto_mas_cercano(item_arrastrado)
	if cesto == null:
		_devolver_a_banda(item_arrastrado)
		mostrar_feedback("Sueltalo en un cesto!", Color.WHITE)
	else:
		var tipo_cesto = cesto.get_meta("tipo")
		if item_arrastrado.tipo == tipo_cesto:
			puntaje += 10 * nivel
			accion_correcta()
			mostrar_feedback("Correcto! +%d" % (10 * nivel), Color.GREEN)
			$BandaTransportadora.items_en_banda.erase(item_arrastrado)
			item_arrastrado.queue_free()
			_revisar_nivel()
			actualizar_hud()
		else:
			accion_incorrecta()
			mostrar_feedback("Error! Tipo equivocado", Color.RED)
			perder_vida()
			_devolver_a_banda(item_arrastrado)
	item_arrastrado = null

func _on_spawn_timeout():
	_pedir_siguiente_item()

func _pedir_siguiente_item():
	var tipo = randi() % 3
	var variante = randi() % 3
	$BandaTransportadora.spawn_siguiente(tipo, variante)

func _on_item_listo_en_banda(_item):
	pass

func _cesto_mas_cercano(item) -> Node:
	var cesto_cercano = null
	var distancia_minima = 150.0
	for cesto in $Cestos.get_children():
		var distancia = item.global_position.distance_to(cesto.global_position)
		if distancia < distancia_minima:
			distancia_minima = distancia
			cesto_cercano = cesto
	return cesto_cercano

func _devolver_a_banda(item):
	if not is_instance_valid(item):
		return
	var tween = create_tween()
	tween.tween_property(
		item,
		"global_position",
		item.pos_en_banda,
		0.4
	).set_ease(Tween.EASE_OUT)
	item.en_banda = true
	item.senal_emitida = false

func accion_correcta():
	nivel_contaminacion = clamp(nivel_contaminacion - 0.08, 0.0, 1.0)
	if material_fondo:
		material_fondo.set_shader_parameter("contaminacion", nivel_contaminacion)

func accion_incorrecta():
	nivel_contaminacion = clamp(nivel_contaminacion + 0.15, 0.0, 1.0)
	if material_fondo:
		material_fondo.set_shader_parameter("contaminacion", nivel_contaminacion)

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
		$BandaTransportadora.velocidad += 15.0
		timer_spawn.wait_time = max(2.0, timer_spawn.wait_time - 0.5)
		nivel_contaminacion = clamp(nivel_contaminacion - 0.2, 0.0, 1.0)
		if material_fondo:
			material_fondo.set_shader_parameter("contaminacion", nivel_contaminacion)
		mostrar_feedback("Nivel %d" % nivel, Color.YELLOW)

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
