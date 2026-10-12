extends Node
## Pilote pour filmer la carte de surface : écoute Freya, suit la traînée, se bat dans la clairière,
## entre au Bourg, traverse la place et va jusqu'au Portail.

var h: Heros
var cam: Camera3D
var principale: Node
var combat: Node
var _t := 0.0
var _dial_t := 0.0
var _visite := 0
var _fin_t := -1.0

## Détour dans le Bourg pour le montrer : la forge, la place, le marchand, puis le nord.
const VISITE := [Vector3(109, 0, 48.5), Vector3(118, 0, 43), Vector3(124, 0, 43.5), Vector3(133, 0, 45.5), Vector3(133.5, 0, 38), Vector3(131, 0, 31), Vector3(127, 0, 28), Vector3(127, 0, 20), Vector3(127, 0, 4.5)]

func lancer(heros: Heros, c: Camera3D, p: Node) -> void:
	h = heros
	cam = c
	principale = p
	combat = Node.new()
	combat.set_script(load("res://scripts/demo_combat.gd"))
	combat.seulement_eveilles = true
	combat.fin_auto = false
	add_child(combat)
	combat.lancer(heros, c)

func _recit() -> CanvasLayer:
	var sc := principale.get_node_or_null("Scenario")
	return sc.recit if sc else null

func _physics_process(delta: float) -> void:
	_t += delta
	var r := _recit()
	if int(_t / 5) != int((_t - delta) / 5):
		printerr("t=", int(_t), " etape=", principale.get_node("Scenario").etape, " pos=", h.global_position.round(), " pv=", int(h.pv))
	# dialogues : on lit à un rythme humain
	if r and r.en_cours():
		h.entree = Vector2.ZERO
		combat.set_physics_process(false)
		_dial_t += delta
		if _dial_t > 2.9:
			_dial_t = 0.0
			r.avancer()
			r.avancer()
		return
	_dial_t = 0.0
	if not h.is_physics_processing():
		return
	# combat si des draugr éveillés sont proches
	var eveilles := get_tree().get_nodes_in_group("monstre").filter(func(e): return not e.est_mort and e.etat not in ["dort", "retour"] and e.global_position.distance_to(h.global_position) < 18.0)
	combat.set_physics_process(not eveilles.is_empty())
	if not eveilles.is_empty():
		return
	var sc := principale.get_node_or_null("Scenario")
	var but := Vector3.INF
	if sc.etape >= 5:
		if _visite < VISITE.size():
			but = VISITE[_visite]
			if Vector2(h.global_position.x - but.x, h.global_position.z - but.z).length() < 2.0:
				_visite += 1
		else:
			h.entree = Vector2.ZERO
			if _fin_t < 0.0:
				_fin_t = _t
			if _t - _fin_t > 7.0:
				get_tree().quit()
			return
	else:
		but = _prochain_point_guide(sc)
	if but == Vector3.INF:
		h.entree = Vector2.ZERO
		return
	var v := but - h.global_position
	v.y = 0
	var d := v.normalized() if v.length() > 0.3 else Vector3.ZERO
	h.entree = Vector2(d.x, d.z)
	if _t > 150.0:
		get_tree().quit()

func _prochain_point_guide(sc) -> Vector3:
	var g: Guide = sc.guide
	# on vise un point de la traînée à ~6 m devant
	var meilleur := Vector3.INF
	for p in g._points:
		if p.visible and p.position.distance_to(h.global_position) > 5.0:
			meilleur = p.position
			break
	if meilleur == Vector3.INF:
		# pas de traînée (combat terminé, ou arrivée) : suivre le chemin vers l'est
		var proj: Array = CarteSurface.distance_chemin(Vector2(h.global_position.x, h.global_position.z))
		var ch: Array = CarteSurface.CHEMIN
		var i := 0
		var dmin := 1e9
		for k in ch.size():
			var dd: float = (ch[k] as Vector2).distance_to(proj[1])
			if dd < dmin:
				dmin = dd
				i = k
		var cible: Vector2 = ch[mini(i + 1, ch.size() - 1)]
		meilleur = Vector3(cible.x, 0, cible.y)
	return meilleur

