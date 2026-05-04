extends Node

var puntaje := 0
var nivel := 1
var dificultad := 1
var gano := false
var modo_supervivencia := false  # ← nuevo

func resetear():
	puntaje = 0
	nivel = 1
	gano = false
	modo_supervivencia = false
