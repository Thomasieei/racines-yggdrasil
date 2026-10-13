class_name Acolyte
extends Node3D
## Bébé dragon acolyte : vole à côté de son maître, crache des boules de feu sur l'ennemi le plus proche,
## gagne de l'expérience à chaque monstre tué et grandit en montant de niveau.

var maitre: Heros
var donnees: Dictionary
var _visuel: Node3D
var _tir_t := 0.0
var _angle := 0.0

static func invoquer(m: Heros, d: Dictionary) -> Acolyte:
	var a := Acolyte.new()
	a.maitre = m
	a.donnees = d
	m.get_parent().add_child(a)
	a.global_position = m.global_position + Vector3(1.2, 0, -0.8)
	return a

func _ready() -> void:
	_visuel = DragonVisuel.bebe(donnees["rarete"])
	add_child(_visuel)
	_appliquer_taille()
	var l := OmniLight3D.new()
	l.light_color = DragonVisuel.COULEURS[donnees["rarete"]][1]
	l.light_energy = 0.7
	l.omni_range = 4.0
	l.position.y = 1.2
	add_child(l)
	Effets.etincelles(get_parent(), global_position + Vector3(0, 1, 0), Vector3.UP, l.light_color, 20, 4.0, "star_06.png", 0.35)

func _appliquer_taille() -> void:
	var t: float = Objets.stats_dragon(donnees)["taille"]
	_visuel.scale = Vector3.ONE * t * 1.3

func grandir() -> void:
	_appliquer_taille()
	Effets.onde(get_parent(), global_position, 2.5, DragonVisuel.COULEURS[donnees["rarete"]][1])

func _process(delta: float) -> void:
	if maitre == null or not is_instance_valid(maitre):
		queue_free()
		return
	visible = not maitre.est_mort
	_angle += delta * 0.6
	# se tient un peu derrière l'épaule du maître, en orbite lente
	var cible := maitre.global_position + Vector3(cos(_angle) * 1.6, 0.9, sin(_angle) * 0.6 + 1.0)
	global_position = global_position.lerp(cible, 1.0 - exp(-4.0 * delta))
	var e := _ennemi()
	var regard := (e.global_position - global_position) if e else (maitre.global_position + maitre.velocity - global_position)
	regard.y = 0
	if regard.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(regard.x, regard.z), 1.0 - exp(-6.0 * delta))
	_tir_t -= delta
	if e and _tir_t <= 0.0 and not maitre.est_mort:
		_tir_t = Objets.stats_dragon(donnees)["cadence"]
		_cracher(e)

func _ennemi() -> Node3D:
	var meilleur: Node3D = null
	var d := 9.0
	for x in maitre.ennemis_vivants():
		if x.has_method("est_eveille") and not x.est_eveille():
			continue
		var l := maitre.global_position.distance_to(x.global_position)
		if l < d:
			d = l
			meilleur = x
	return meilleur

## Boule de feu : petite comète de la couleur du dragon, qui suit sa cible.
func _cracher(e: Node3D) -> void:
	if _visuel.has_method("attaquer"):
		_visuel.attaquer()
	var col: Color = DragonVisuel.COULEURS[donnees["rarete"]][1]
	var b := Node3D.new()
	get_parent().add_child(b)
	b.global_position = global_position + Vector3(0, 1.0, 0)
	var tr := Effets.trainee_lumineuse(b, col)
	var deg: int = Objets.stats_dragon(donnees)["degats"]
	Sons.jouer("activation", global_position, -14.0, 1.5)
	var t := 0.0
	while t < 1.2 and is_instance_valid(e) and is_instance_valid(b):
		await get_tree().process_frame
		t += get_process_delta_time()
		var vise: Vector3 = e.global_position + Vector3(0, 1.0, 0)
		b.global_position = b.global_position.move_toward(vise, 16.0 * get_process_delta_time())
		if b.global_position.distance_to(vise) < 0.5:
			if not e.est_mort:
				e.recevoir({"montant": float(deg), "source": maitre})
			Effets.etincelles(get_parent(), vise, Vector3.UP, col, 10, 3.0)
			break
	if is_instance_valid(b):
		if tr:
			tr.emitting = false
		b.queue_free()
