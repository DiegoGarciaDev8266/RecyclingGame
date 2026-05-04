extends Node2D

const BasuraItemScene = preload("res://Scenes/BasuraItem.tscn")

const NOMBRE_CESTOS = {
	"Orga_Apro": 0,
	"Apro": 1,
	"No_Apro": 2
}

const TEXTURAS = {
	0: {
		0: preload("res://Assets/01-Egg.png"),
		1: preload("res://Assets/02-BananaSkin.png"),
		2: preload("res://Assets/03-Bone.png"),
		3: preload("res://Assets/04-FishBone.png"),
		4: preload("res://Assets/05-Apple.png")
	},
	1: {
		0: preload("res://Assets/11-Bottle.png"),
		1: preload("res://Assets/16-Paper.png"),
		2: preload("res://Assets/18-Box.png"),
		3: preload("res://Assets/22-Glass.png"),
		4: preload("res://Assets/10-Milk.png")
	},
	2: {
		0: preload("res://Assets/07-Styrofoam.png"),
		1: preload("res://Assets/09-Snack.png"),
		2: preload("res://Assets/20-Patchwork.png"),
		3: preload("res://Assets/25-FilterCigarette.png"),
		4: preload("res://Assets/12-Rope.png")
	}
}

const CONFIG = {
	1: {
		"cestos_activos": ["Orga_Apro", "No_Apro"],
		"max_objetos": 3,
		"velocidad_caida": 150.0,
		"spawn_time": 2.5,
		"meta": 150,
		"puntos_acierto": 10
	},
	2: {
		"cestos_activos": ["Orga_Apro", "Apro", "No_Apro"],
		"max_objetos": 5,
		"velocidad_caida": 250.0,
		"spawn_time": 1.8,
		"meta": 300,
		"puntos_acierto": 15
	},
	3: {
		"cestos_activos": ["Orga_Apro", "Apro", "No_Apro"],
		"max_objetos": 7,
		"velocidad_caida": 380.0,
		"spawn_time": 1.2,
		"meta": 500,
		"puntos_acierto": 20
	}
}

# Variables modo supervivencia
var surv_velocidad := 150.0
var surv_spawn_time := 2.5
var surv_max_objetos := 3
const SURV_INTERVALO_ESCALADO := 100
const SURV_VELOCIDAD_MAX := 500.0
const SURV_SPAWN_MIN := 0.4

var puntaje := 0
var vidas := 3
var nivel_contaminacion := 0.5
var material_fondo: ShaderMaterial
var item_arrastrado = null
var offset_arrastre := Vector2.ZERO
var objetos_activos: Array = []
var juego_activo := true

@onready var timer_spawn = $TimerSpawn
@onready var puntaje_label = $CanvasLayer/PuntajeLabel
@onready var nivel_label = $CanvasLayer/NivelLabel
@onready var feedback_label = $CanvasLayer/FeedbackLabel
@onready var barra_meta = $CanvasLayer/BarraMeta
@onready var fondo = $Fondo
@onready var corazones = [
	$CanvasLayer/Corazones/TextureRect,
	$CanvasLayer/Corazones/TextureRect2,
	$CanvasLayer/Corazones/TextureRect3
]

const CORAZON_VACIO = preload("res://Assets/corazon_vacio.svg")

func _ready():
	_configurar_nivel()
	timer_spawn.connect("timeout", _on_spawn_timeout)
	timer_spawn.wait_time = CONFIG[GameState.dificultad].spawn_time
	timer_spawn.start()
	feedback_label.visible = false
	actualizar_hud()
	material_fondo = fondo.material
	if material_fondo:
		var tex = preload("res://Assets/fondo_contaminado.svg")
		material_fondo.set_shader_parameter("fondo_contaminado", tex)
		material_fondo.set_shader_parameter("contaminacion", nivel_contaminacion)
	if GameState.modo_supervivencia:
		nivel_label.text = "♾ Supervivencia"
		barra_meta.visible = false
		timer_spawn.wait_time = surv_spawn_time

func _configurar_nivel():
	var config = CONFIG[GameState.dificultad]
	for cesto in $Cestos.get_children():
		cesto.visible = config.cestos_activos.has(cesto.name)
	barra_meta.max_value = config.meta
	barra_meta.value = 0
	nivel_label.text = ["", "Facil", "Normal", "Dificil"][GameState.dificultad]
	for cesto in $Cestos.get_children():
		if NOMBRE_CESTOS.has(cesto.name):
			cesto.set_meta("tipo", NOMBRE_CESTOS[cesto.name])

func _process(_delta):
	if not juego_activo:
		return
	if material_fondo:
		material_fondo.set_shader_parameter(
			"tiempo",
			Time.get_ticks_msec() / 1000.0
		)
	if item_arrastrado and is_instance_valid(item_arrastrado):
		item_arrastrado.global_position = get_global_mouse_position() + offset_arrastre
	_verificar_objetos_fuera()

func _verificar_objetos_fuera():
	var pantalla_h = get_viewport().get_visible_rect().size.y
	for item in objetos_activos.duplicate():
		if not is_instance_valid(item):
			objetos_activos.erase(item)
			continue
		if item.cayendo and item.global_position.y > pantalla_h + 50:
			objetos_activos.erase(item)
			item.queue_free()
			accion_incorrecta()
			mostrar_feedback("Se escapo!", Color.ORANGE)
			perder_vida()
			_spawnear_objeto()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_intentar_agarrar(get_global_mouse_position())
		else:
			if item_arrastrado:
				_soltar_item()

func _intentar_agarrar(mouse_pos: Vector2):
	for item in objetos_activos:
		if not is_instance_valid(item):
			continue
		if not item.pickable:
			continue
		if mouse_pos.distance_to(item.global_position) < 40.0:
			item_arrastrado = item
			item_arrastrado.iniciar_arrastre()
			item_arrastrado.cayendo = false
			offset_arrastre = item.global_position - mouse_pos
			return

func _soltar_item():
	if not is_instance_valid(item_arrastrado):
		item_arrastrado = null
		return
	item_arrastrado.soltar()
	item_arrastrado.dragging = false
	var cesto = _cesto_mas_cercano(item_arrastrado)
	if cesto == null:
		item_arrastrado.cayendo = true
		item_arrastrado = null
		return
	var tipo_cesto = cesto.get_meta("tipo")
	if item_arrastrado.tipo == tipo_cesto:
		var pts = CONFIG[GameState.dificultad].puntos_acierto
		puntaje += pts
		accion_correcta()
		mostrar_feedback("Correcto! +%d" % pts, Color.GREEN)
		item_arrastrado.emitir_particulas_acierto()
		item_arrastrado.get_node("Sprite2D").visible = false  # ← oculta el sprite inmediato
		item_arrastrado.get_node("CollisionShape2D").disabled = true  # ← desactiva colision
		objetos_activos.erase(item_arrastrado)
		var item_a_borrar = item_arrastrado
		item_arrastrado = null  # suelta el mouse de inmediato
		actualizar_hud()
		if GameState.modo_supervivencia:
			_actualizar_dificultad_supervivencia()
		_verificar_victoria()
		_spawnear_objeto()
		await get_tree().create_timer(0.6).timeout  # espera que terminen partículas
		if is_instance_valid(item_a_borrar):
			item_a_borrar.queue_free()
	else:
		accion_incorrecta()
		mostrar_feedback("Error! Tipo equivocado", Color.RED)
		item_arrastrado.emitir_particulas_error()
		perder_vida()
		item_arrastrado.cayendo = true
		item_arrastrado = null

func _actualizar_dificultad_supervivencia():
	var nivel_actual = int(puntaje) / int(SURV_INTERVALO_ESCALADO)
	surv_velocidad = min(SURV_VELOCIDAD_MAX, 150.0 + nivel_actual * 35.0)
	surv_spawn_time = max(SURV_SPAWN_MIN, 2.5 - nivel_actual * 0.2)
	surv_max_objetos = min(10, 3 + nivel_actual)
	timer_spawn.wait_time = surv_spawn_time

func _on_spawn_timeout():
	objetos_activos = objetos_activos.filter(func(i): return is_instance_valid(i))
	var max_obj = surv_max_objetos if GameState.modo_supervivencia else CONFIG[GameState.dificultad].max_objetos
	if objetos_activos.size() >= max_obj:
		return
	_spawnear_objeto()

func _spawnear_objeto():
	if not juego_activo:
		return
	if not is_instance_valid(get_viewport()):
		return
	var tipos_disponibles = []
	for cesto in $Cestos.get_children():
		if cesto.visible:
			tipos_disponibles.append(cesto.get_meta("tipo"))
	if tipos_disponibles.is_empty():
		return
	var tipo = tipos_disponibles[randi() % tipos_disponibles.size()]
	var variante = randi() % 5
	var item = BasuraItemScene.instantiate()
	item.tipo = tipo
	item.variante = variante
	if GameState.modo_supervivencia:
		item.velocidad_caida = surv_velocidad
	else:
		item.velocidad_caida = CONFIG[GameState.dificultad].velocidad_caida
	item.get_node("Sprite2D").texture = TEXTURAS[tipo][variante]
	item.global_position = Vector2(
		randf_range(60, get_viewport().get_visible_rect().size.x - 60),
		-50
	)
	item.pickable = true
	item.cayendo = true
	add_child(item)
	objetos_activos.append(item)

func _cesto_mas_cercano(item) -> Node:
	var cesto_cercano = null
	var distancia_minima = 150.0
	for cesto in $Cestos.get_children():
		if not cesto.visible:
			continue
		var dist = cesto.global_position.distance_to(item.global_position)
		if dist < distancia_minima:
			distancia_minima = dist
			cesto_cercano = cesto
	return cesto_cercano

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

func _verificar_victoria():
	if GameState.modo_supervivencia:
		return
	var meta = CONFIG[GameState.dificultad].meta
	if puntaje >= meta:
		juego_activo = false
		GameState.puntaje = puntaje
		GameState.gano = true
		get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")

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
	if not GameState.modo_supervivencia:
		barra_meta.value = puntaje

func game_over():
	juego_activo = false
	GameState.puntaje = puntaje
	GameState.gano = false
	get_tree().paused = true
	get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")
