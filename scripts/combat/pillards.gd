class_name Pillards
## Les lieux hostiles : le Fort de Hrafn (pillards) et le camp de Skarn (brigands).
## Leurs hommes attaquent à vue ; abats leur chef et le lieu tombe : son trésor est à toi
## et il ne se repeuple plus.

const CHEFS := {"hrafn": "hrafn", "skarn": "skarn"}
const NOMS := {"hrafn": "Fort de Hrafn", "skarn": "Camp de Skarn"}

static func conquis(id: String) -> bool:
	return Profil.p().vu("conquis_" + id)

static func peupler(p: Node, col: Colonie) -> Array:
	var l: Array = []
	if conquis(col.id):
		return l
	var c := col.place
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(col.id + "pillards")
	var troupe: Array = []
	if col.id == "hrafn":
		for i in 9:
			troupe.append("pillard")
		for i in 5:
			troupe.append("archer_pillard")
	else:
		for i in 7:
			troupe.append("brigand")
		for i in 2:
			troupe.append("archer_pillard")
	for t in troupe:
		var d := Draugr.new()
		d.configurer(t)
		var a := rng.randf() * TAU
		var r := rng.randf_range(4.0, col.rect.size.x * 0.32)
		d.position = NavMonde.point_libre(c + Vector3(cos(a) * r, 0, sin(a) * r * 0.8))
		d.aggro_rayon = 11.0
		p.add_child(d)
		l.append(d)
	# aux portes, deux sentinelles
	for k in col.postes.get("garde", []):
		var s := Draugr.new()
		s.configurer("pillard")
		s.position = k
		s.aggro_rayon = 13.0
		p.add_child(s)
		l.append(s)
	var chef := Draugr.new()
	chef.configurer(CHEFS[col.id])
	var hall: Array = col.maisons_de("hall")
	chef.position = (hall[0]["porte"] + Vector3(0, 0, 2)) if not hall.is_empty() else c
	chef.aggro_rayon = 12.0
	chef.set_meta("chef_de", col.id)
	p.add_child(chef)
	l.append(chef)
	return l

## Le chef est tombé : le lieu est conquis, ses hommes fuient, le trésor apparaît.
static func chef_tombe(chef: Node3D, id: String) -> void:
	Profil.p().marquer_vu("conquis_" + id)
	Profil.p().compter("conquetes")
	var nom: String = NOMS.get(id, "Le repaire")
	if Jeu.hud and Jeu.hud.has_method("celebrer"):
		Jeu.hud.celebrer({"rarete": "legendaire", "icone": "res://assets/icones_sorts/pouvoir_dechainement.svg"}, nom.to_upper() + " EST TOMBÉ",
			"Son chef gît à tes pieds", "Le trésor du chef est à toi. Ses hommes ne reviendront plus.")
	Sons.jouer("cloche", chef.global_position, 2.0, 0.7)
	var pos := chef.global_position
	var parent := chef.get_parent()
	Coffre.creer(parent, pos + Vector3(1.5, 0, -1.5), "legendaire", 180.0)
	Coffre.creer(parent, pos + Vector3(-1.5, 0, -1.5), "epique", 180.0)
	# les survivants jettent leurs armes et disparaissent dans les bois
	for d in chef.get_tree().get_nodes_in_group("monstre"):
		if d is Draugr and d != chef and not d.est_mort and d.fiche.get("humain", false) and d.global_position.distance_to(pos) < 70.0:
			Effets.poussiere(d.get_parent(), d.global_position, 10)
			d.queue_free()
