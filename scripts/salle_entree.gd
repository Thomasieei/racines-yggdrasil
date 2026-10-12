extends Node3D
## Salle faite main n°1 : « Crypte d'entrée des nains ».
## Chaque objet est placé volontairement (point focal au nord, grappes logiques, chemins dégagés).
## Repère : x vers l'est, z vers le sud, salle de 28 x 28 m (7 x 7 dalles de 4 m), nord en z = 0.

const D := "res://assets/donjon/"
const TAILLE := 7

# Boîtes de collision approximatives par pièce : taille (x, y, z), décalage du centre.
const COLLISIONS := {
	"wall": [Vector3(4, 4, 1), Vector3(0, 2, 0)],
	"wall_arched": [Vector3(4, 4, 1), Vector3(0, 2, 0)],
	"wall_cracked": [Vector3(4, 4, 1), Vector3(0, 2, 0)],
	"pillar_decorated": [Vector3(2.0, 4, 1.6), Vector3(0, 2, 0)],
	"pillar": [Vector3(1.5, 4, 1.5), Vector3(0, 2, 0)],
	"barrel_large": [Vector3(1.7, 2, 1.7), Vector3(0, 1, 0)],
	"crates_stacked": [Vector3(2.1, 2.1, 2.2), Vector3(0, 1.05, 0)],
	"barrel_small_stack": [Vector3(1.6, 1.4, 1.6), Vector3(0, 0.7, 0)],
	"keg_decorated": [Vector3(1.4, 1.4, 1.4), Vector3(0, 0.7, 0)],
	"chest_gold": [Vector3(1.7, 1.0, 1.5), Vector3(0, 0.5, 0.3)],
	"rubble_large": [Vector3(7.5, 2.5, 3.0), Vector3(0, 1.2, 0)],
	"table_long_decorated_A": [Vector3(4.0, 1.2, 1.6), Vector3(0, 0.6, 0)],
	"shelf_large": [Vector3(4.0, 3.0, 1.0), Vector3(0, 1.5, 0)],
}

func _ready() -> void:
	_sol()
	_murs()
	_decor()
	_lumieres()

func _poser(nom: String, pos: Vector3, rot_deg := 0.0, echelle := 1.0, collision := true) -> Node3D:
	var scene: PackedScene = load(D + nom + ".glb")
	if scene == null:
		push_warning("pièce manquante : " + nom)
		return null
	var n: Node3D = scene.instantiate()
	n.position = pos
	n.rotation_degrees.y = rot_deg
	n.scale = Vector3.ONE * echelle
	add_child(n)
	if collision and COLLISIONS.has(nom):
		var c: Array = COLLISIONS[nom]
		var corps := StaticBody3D.new()
		var forme := CollisionShape3D.new()
		var boite := BoxShape3D.new()
		boite.size = c[0] * echelle
		forme.shape = boite
		forme.position = c[1] * echelle
		corps.add_child(forme)
		n.add_child(corps)
	return n

func _sol() -> void:
	# dalles : surtout lisses, quelques dalles abîmées, motif voulu (pas d'aléatoire)
	var abimees := [Vector2i(1, 5), Vector2i(2, 6), Vector2i(5, 4), Vector2i(0, 3), Vector2i(6, 1), Vector2i(4, 6)]
	for i in TAILLE:
		for j in TAILLE:
			var nom := "floor_tile_large_rocks" if Vector2i(i, j) in abimees else "floor_tile_large"
			var d := _poser(nom, Vector3(2 + 4 * i, 0, 2 + 4 * j), 90.0 * ((i + j) % 4), 1.0, false)
			_assombrir(d, Color(0.55, 0.55, 0.62))
	# grande dalle de collision du sol
	var corps := StaticBody3D.new()
	var forme := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = Vector3(4 * TAILLE, 1, 4 * TAILLE)
	forme.shape = boite
	forme.position = Vector3(2 * TAILLE, -0.5, 2 * TAILLE)
	corps.add_child(forme)
	add_child(corps)
	# bord sud invisible : la salle s'ouvre sur l'obscurité sans qu'on puisse tomber
	var bord := StaticBody3D.new()
	var f2 := CollisionShape3D.new()
	var b2 := BoxShape3D.new()
	b2.size = Vector3(4 * TAILLE, 4, 1)
	f2.shape = b2
	f2.position = Vector3(2 * TAILLE, 2, 4 * TAILLE + 0.5)
	bord.add_child(f2)
	add_child(bord)

func _assombrir(n: Node, teinte: Color) -> void:
	# la pierre du sol est trop claire par défaut : on la fonce pour que la lumière dessine la salle
	if n == null:
		return
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		for k in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(k)
			if mat is StandardMaterial3D:
				var c := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
				c.albedo_color = c.albedo_color * teinte
				mi.set_surface_override_material(k, c)

func _murs() -> void:
	for i in TAILLE:
		var x := 2 + 4 * i
		# mur nord : arche centrale = sortie vers la suite du donjon
		_poser("wall_arched" if i == 3 else "wall", Vector3(x, 0, 0))
		_poser("wall_cracked" if i in [2, 5] else "wall", Vector3(0, 0, x), 90.0)            # ouest
		_poser("wall_cracked" if i in [1, 4] else "wall", Vector3(4 * TAILLE, 0, x), -90.0)  # est
	for c in [Vector3(0, 0, 0), Vector3(4 * TAILLE, 0, 0)]:
		_poser("pillar", c)
	# enceinte de sécurité : rien ne doit jamais sortir de la salle, quelle que soit la pièce posée
	var l := 4.0 * TAILLE
	for b in [[Vector3(l / 2, 2, -0.4), Vector3(l + 2, 4, 1)], [Vector3(l / 2, 2, l + 0.9), Vector3(l + 2, 4, 1)],
			[Vector3(-0.4, 2, l / 2), Vector3(1, 4, l + 2)], [Vector3(l + 0.4, 2, l / 2), Vector3(1, 4, l + 2)]]:
		var corps := StaticBody3D.new()
		var forme := CollisionShape3D.new()
		var boite := BoxShape3D.new()
		boite.size = b[1]
		forme.shape = boite
		corps.position = b[0]
		corps.add_child(forme)
		add_child(corps)

func _decor() -> void:
	# point focal : coffre doré sur l'axe de la sortie, encadré de bannières et de bougies
	_poser("chest_gold", Vector3(14, 0, 5.2), 0.0, 1.15)
	_poser("candle_triple", Vector3(11.4, 0, 4.2), 0.0, 1.2, false)
	_poser("candle_triple", Vector3(16.6, 0, 4.2), 0.0, 1.2, false)
	_poser("banner_patternA_red", Vector3(9, 0, 0.5), 0.0, 1.0, false)
	_poser("banner_patternA_red", Vector3(19, 0, 0.5), 0.0, 1.0, false)
	# quatre piliers qui structurent la salle et laissent l'allée centrale libre
	for p in [Vector3(7, 0, 9), Vector3(21, 0, 9), Vector3(7, 0, 20), Vector3(21, 0, 20)]:
		_poser("pillar_decorated", p)
	# grappe nord-est : réserve des nains (tonneaux, caisses, étagère)
	_poser("barrel_large", Vector3(25.2, 0, 3.0))
	_poser("barrel_small_stack", Vector3(23.0, 0, 2.6), 20.0)
	_poser("crates_stacked", Vector3(25.4, 0, 6.6), 12.0)
	_poser("keg_decorated", Vector3(22.8, 0, 5.4), -30.0)
	_poser("shelf_large", Vector3(4.5, 0, 1.0), 0.0)
	# grappe sud-ouest : éboulement et vestiges d'un combat
	_poser("rubble_large", Vector3(4.5, 0, 25.8), 25.0, 0.8)
	_poser("sword_shield_broken", Vector3(9.0, 0, 24.5), 40.0, 1.0, false)
	_poser("rubble_half", Vector3(11.0, 0, 26.5), -15.0, 1.0, false)
	# table de veille à l'est, à mi-salle
	_poser("table_long_decorated_A", Vector3(25.0, 0, 15.0), 90.0)
	_poser("stool", Vector3(23.4, 0, 14.0), 10.0, 1.0, false)
	_crypte()

func _poser_h(nom: String, pos: Vector3, rot_deg := 0.0, echelle := 1.0) -> Node3D:
	# pièces KayKit Halloween Bits (glTF + bin + texture gardés ensemble)
	var scene: PackedScene = load("res://assets/halloween/" + nom + ".gltf")
	if scene == null:
		push_warning("pièce manquante : " + nom)
		return null
	var n: Node3D = scene.instantiate()
	n.position = pos
	n.rotation_degrees.y = rot_deg
	n.scale = Vector3.ONE * echelle
	add_child(n)
	return n

func _crypte() -> void:
	# mur ouest : rangée de cercueils veillés par des bougies spectrales (lumière verte froide)
	_poser_h("coffin", Vector3(2.4, 0, 11.0), 90.0, 1.1)
	_poser_h("coffin_decorated", Vector3(2.4, 0, 15.0), 90.0, 1.1)
	_poser_h("coffin", Vector3(2.4, 0, 19.0), 90.0, 1.1)
	_poser_h("skull_candle", Vector3(2.6, 0, 13.0), 0.0, 0.75)
	_poser_h("skull_candle", Vector3(2.6, 0, 17.0), 0.0, 0.75)
	_poser_h("shrine_candles", Vector3(4.0, 0, 5.8), 30.0, 1.2)
	# restes d'aventuriers près de l'éboulement
	_poser_h("ribcage", Vector3(8.2, 0, 22.4), 30.0, 1.2)
	_poser_h("skull", Vector3(10.6, 0, 23.4), -40.0, 1.2)
	_poser_h("bone_A", Vector3(12.8, 0, 24.6), 70.0, 1.2)
	_poser_h("bone_C", Vector3(6.6, 0, 21.2), 10.0, 1.2)
	# lanterne près de la table de veille
	_poser_h("lantern_standing", Vector3(25.6, 0, 11.6), 0.0, 1.2)

func _lumieres() -> void:
	# torches murales : elles guident vers la sortie nord
	for x in [6.0, 22.0]:
		_poser("torch_mounted", Vector3(x, 2.2, 0.5), 0.0, 1.0, false)
		_lumiere(Vector3(x, 3.0, 1.4), Color(1.0, 0.58, 0.25), 2.4, 11.0)
	# lueur dorée du coffre : point focal
	_lumiere(Vector3(14, 1.6, 6.4), Color(1.0, 0.78, 0.35), 1.6, 6.0)
	# bougies spectrales des cercueils : accent vert froid, comme dans les cryptes d'Albion
	for z in [13.0, 17.0]:
		_lumiere(Vector3(3.2, 1.3, z), Color(0.45, 1.0, 0.62), 1.6, 6.5)
	_lumiere(Vector3(4.6, 1.2, 6.4), Color(0.45, 1.0, 0.62), 1.0, 5.0)
	# souffle froid de la sortie nord : on a envie d'aller voir
	_lumiere(Vector3(14, 2.4, 1.2), Color(0.5, 0.7, 1.0), 2.2, 8.0)
	_lumiere(Vector3(25.6, 2.0, 11.6), Color(1.0, 0.7, 0.35), 1.2, 6.0)
	# torches sur pied près des piliers sud (le joueur arrive par le sud)
	for x in [7.0, 21.0]:
		_poser("torch_lit", Vector3(x, 0, 22.6), 0.0, 1.4, false)
		_lumiere(Vector3(x, 2.2, 22.6), Color(1.0, 0.6, 0.28), 1.8, 9.0)

func _lumiere(pos: Vector3, couleur: Color, energie: float, portee: float) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = couleur
	l.light_energy = energie
	l.omni_range = portee
	l.omni_attenuation = 1.4
	add_child(l)
