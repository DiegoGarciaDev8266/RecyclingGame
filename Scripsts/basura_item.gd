extends Area2D

@export var tipo: int = 0
@export var variante: int = 0
var pickable := false
var dragging := false
var offset := Vector2.ZERO

signal dropped(item)

func _ready():
	input_pickable = true

func _on_input_event(_viewport, event, _shape_idx):
	if not pickable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			offset = global_position - get_global_mouse_position()
		else:
			dragging = false
			emit_signal("dropped", self)

func _process(_delta):
	if dragging:
		global_position = get_global_mouse_position() + offset
