extends Node
## Pilote pour filmer la caverne : sort de la crypte, traverse le boyau, se bat à l'entrée,
## souffle au camp des Égarés, longe le gouffre, attaque le campement draugr, puis va voir l'antre du Jarl.

var h: Heros
var principale: Node
var combat: Node
var _t := 0.0
var _i := 0
var _pause := 0.0
var _fin_t := -1.0

## [point, pause en secondes à l'arrivée]
const ETAPES := [
	[Vector3(14, 0, -2), 0.0], [Vector3(12, 0, -10), 0.0], [Vector3(7, 0, -20), 0.0], [Vector3(6, 0, -30), 0.0],
	[Vector3(8, 0, -36), 0.0], [Vector3(20, 0, -27), 0.0], [Vector3(31, 0, -16), 3.5], [Vector3(38, 0, -30), 0.0],
	[Vector3(30, 0, -46), 0.0], [Vector3(17, 0, -50), 0.0], [Vector3(22, 0, -64), 0.0], [Vector3(21, 0, -74), 0.0],
	[Vector3(40, 0, -72), 0.0], [Vector3(57, 0, -63), 0.0], [Vector3(62, 0, -61), 5.0],
]

func lancer(heros: Heros, p: Node) -> void:
	h = heros
	principale = p
	combat = Node.new()
	combat.set_script(load("res://scripts/demo_combat.gd"))
	combat.seulement_eveilles = true
	combat.fin_auto = false
	add_child(combat)
	combat.lancer(heros, get_viewport().get_camera_3d())

func _physics_process(delta: float) -> void:
	_t += delta
	if int(_t / 5) != int((_t - delta) / 5):
		printerr("t=", int(_t), " etape=", _i, " pos=", h.global_position.round(), " pv=", int(h.pv))
	if h.est_mort or _t > 140.0:
		get_tree().quit()
		return
	var eveilles := get_tree().get_nodes_in_group("monstre").filter(func(e): return not e.est_mort and e.etat not in ["dort", "retour"] and e.global_position.distance_to(h.global_position) < 18.0 and e.type != "jarl")
	combat.set_physics_process(not eveilles.is_empty())
	if not eveilles.is_empty():
		return
	if _pause > 0.0:
		_pause -= delta
		h.entree = Vector2.ZERO
		return
	if _i >= ETAPES.size():
		h.entree = Vector2.ZERO
		if _fin_t < 0.0:
			_fin_t = _t
		if _t - _fin_t > 1.0:
			get_tree().quit()
		return
	var but: Vector3 = ETAPES[_i][0]
	var v := but - h.global_position
	v.y = 0
	if v.length() < 1.6:
		_pause = ETAPES[_i][1]
		_i += 1
		return
	var d := v.normalized()
	h.entree = Vector2(d.x, d.z)
