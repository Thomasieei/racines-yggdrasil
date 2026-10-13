extends Node
## Survol filmé de l'étage : la caméra quitte le héros et parcourt les quatre ailes,
## pour montrer l'échelle de la carte (prévue pour une vingtaine de joueurs).

const POINTS := [
	# [centre visé, distance, durée du trajet vers ce point, titre]
	[Vector3(14, 0, 8), 40.0, 0.0, "Crypte des nains — arrivée"],
	[Vector3(10, 0, -20), 45.0, 3.5, "Boyau des Murmures"],
	[Vector3(12, 0, -58), 110.0, 4.5, "Grande Caverne"],
	[Vector3(-92, 0, -58), 80.0, 5.0, "Ossuaire des Rois"],
	[Vector3(-86, 0, 2), 70.0, 4.0, "Lac des Noyés"],
	[Vector3(58, 0, -134), 75.0, 6.5, "Forges englouties"],
	[Vector3(-18, 0, -66), 230.0, 5.0, "Étage 1 — vue d'ensemble"],
]

var cam: Camera3D
var hud: CanvasLayer
var _t := 0.0
var _i := 0
var _depart: Array
var _titre: Label

func lancer(c: Camera3D, h: CanvasLayer) -> void:
	cam = c
	hud = h
	cam.set_physics_process(false)
	if hud:
		hud.visible = false
	var couche := CanvasLayer.new()
	add_child(couche)
	_titre = Label.new()
	_titre.add_theme_font_size_override("font_size", 30)
	_titre.add_theme_color_override("font_color", Color("#F4C35A"))
	_titre.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_titre.add_theme_constant_override("outline_size", 8)
	_titre.position = Vector2(0, 26)
	_titre.size = Vector2(1280, 40)
	_titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	couche.add_child(_titre)
	_depart = [POINTS[0][0], POINTS[0][1]]
	_titre.text = POINTS[0][3]
	_placer(POINTS[0][0], POINTS[0][1])

func _placer(centre: Vector3, dist: float) -> void:
	var a := deg_to_rad(58.0)
	cam.global_position = centre + Vector3(0, sin(a), cos(a)) * dist
	cam.look_at(centre, Vector3.UP)
	cam.far = 600.0

func _process(delta: float) -> void:
	if cam == null:
		return
	_t += delta
	if _i + 1 >= POINTS.size():
		if _t > 4.0:
			get_tree().quit()
		return
	var cible: Array = POINTS[_i + 1]
	var k := clampf(_t / cible[2], 0.0, 1.0)
	var e := k * k * (3.0 - 2.0 * k)
	_placer(_depart[0].lerp(cible[0], e), lerpf(_depart[1], cible[1], e))
	if k > 0.5:
		_titre.text = cible[3]
	if k >= 1.0 and _t > cible[2] + 1.2:
		_i += 1
		_t = 0.0
		_depart = [cible[0], cible[1]]
