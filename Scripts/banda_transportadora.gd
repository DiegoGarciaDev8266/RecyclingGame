extends Node2D

signal item_listo(item)

const BasuraItemScene = preload("res://Scenes/BasuraItem.tscn")

@export var velocidad: float = 80.0
@export var punto_recogida_x: float = -200.0
@export var punto_salida_rodillo_x: float = 900.0
@export var max_items_banda: int = 3

var items_en_banda: Array = []

const TEXTURAS = {
	0: {
		0: preload("res://Assets/carton_caja.svg"),
		1: preload("res://Assets/carton_periodico.svg"),
		2: preload("res://Assets/carton_rollo.svg")
	},
	1: {
		0: preload("res://Assets/vidrio_botella.svg"),
		1: preload("res://Assets/vidrio_frasco.svg"),
		2: preload("res://Assets/vidrio_vaso.svg")
	},
	2: {
		0: preload("res://Assets/plastico_botella.svg"),
		1: preload("res://Assets/plastico_vaso.svg"),
		2: preload("res://Assets/plastico_bolsa.svg")
	}
}

func spawn_siguiente(tipo: int, variante: int):
	var activos = items_en_banda.filter(func(i): return is_instance_valid(i))
	if activos.size() >= max_items_banda:
		return
	var item = BasuraItemScene.instantiate()
	item.tipo = tipo
	item.variante = variante
	item.get_node("Sprite2D").texture = TEXTURAS[tipo][variante]
	get_parent().add_child(item)
	item.global_position = Vector2(
		$SpawnPoint.global_position.x + 100,
		$SpawnPoint.global_position.y
	)
	item.pickable = false
	item.en_banda = true
	item.senal_emitida = false
	items_en_banda.append(item)

func liberar_banda():
	pass

func _process(delta):
	items_en_banda = items_en_banda.filter(
		func(i): return is_instance_valid(i)
	)
	var items_activos = items_en_banda.filter(
		func(i): return i.en_banda and not i.dragging
	)
	items_activos.sort_custom(
		func(a, b): return a.global_position.x > b.global_position.x
	)
	for i in range(items_activos.size()):
		var item = items_activos[i]
		if not is_instance_valid(item):
			continue
		item.global_position.x -= velocidad * delta
		if item.global_position.x < punto_salida_rodillo_x:
			item.pickable = true
		var banda_inicio_x = global_position.x + punto_recogida_x
		var pos_minima = banda_inicio_x + (i * 70.0)
		if item.global_position.x <= pos_minima:
			item.global_position.x = pos_minima
			if not item.senal_emitida:
				item.senal_emitida = true
				emit_signal("item_listo", item)
