class_name Interieur
extends Node3D
## L'intérieur d'un bâtiment du Val, bâti avec le kit du donjon (sol de bois, murs, meubles).
## Il est posé loin du monde, dans le noir ; on y entre par la porte, on en sort par « Sortir ».
## Chaque genre a son mobilier et sa raison d'y entrer :
##   maison : un coffre à fouiller (si personne n'est là) · taverne : une chope qui remet sur pied
##   temple : l'autel d'Odin · château : le trésor du Jarl… gardé · ta maison : ton coffre, ton lit, tes serviteurs

const DJ := "res://assets/donjon/"
const O := "res://assets/surface/outils/"

static var cache := {}          ## maison -> Interieur
static var _n := 0
static var actuel: Interieur
static var retour := Vector3.ZERO

var maison: Dictionary = {}
var colonie: Colonie
var largeur := 12.0
var profondeur := 9.0
var entree := Vector3.ZERO      ## où apparaît le héros (devant la sortie)
var a_moi := false

static func entrer(m: Dictionary, col: Colonie, h: Heros) -> void:
	var i: Interieur = cache.get(m)
	if i == null or not is_instance_valid(i):
		i = Interieur.new()
		i.maison = m
		i.colonie = col
		i.position = Vector3(1300.0 + (_n % 6) * 60.0, 0, 1300.0 + (_n / 6) * 60.0)
		_n += 1
		h.get_parent().add_child(i)
		cache[m] = i
	actuel = i
	retour = m["porte"] + m["dir"] * 0.8
	i._accueillir(h)

static func sortir(h: Heros) -> void:
	actuel = null
	_teleporter(h, retour)
	if Jeu.hud and Jeu.hud.has_method("regler_titre"):
		var l := CarteSurface.lieu_de(retour)
		Jeu.hud.regler_titre(l.get("nom", "Le Val des Racines"), "")

static func _teleporter(h: Heros, p: Vector3) -> void:
	h.global_position = p + Vector3(0, 0.1, 0)
	h.velocity = Vector3.ZERO
	var cam := h.get_viewport().get_camera_3d()
	if cam:
		cam.set("_focus", h.global_position)
	Sons.jouer("tissu", p, -4.0, 0.9)
	# les pantins qui suivent entrent et sortent avec toi
	for v in h.get_tree().get_nodes_in_group("pantin"):
		if v.ordre.get("id", "") == "suivre" and not v.est_mort:
			v.global_position = p + Vector3(randf_range(-1.5, 1.5), 0, 1.5)
			v._but = Vector3.INF

func est_a_moi() -> bool:
	return new_est_a_moi(maison, colonie)

static func new_est_a_moi(m: Dictionary, col: Colonie) -> bool:
	return col != null and col.id == "brekka" and Hameau.est_chef() and not col.maisons.is_empty() and col.maisons[0] == m

func _ready() -> void:
	a_moi = est_a_moi()
	match maison.get("genre", "maison"):
		"taverne", "chateau", "temple", "hall":
			largeur = 16.0
			profondeur = 12.0
	_coque()
	match maison.get("genre", "maison"):
		"taverne":
			_taverne()
		"forge":
			_forge()
		"temple":
			_temple()
		"chateau":
			_chateau()
		"hall":
			_hall()
		_:
			_maison()

func _accueillir(h: Heros) -> void:
	_teleporter(h, global_position + Vector3(0, 0, profondeur / 2.0 - 1.6))
	h.rotation.y = PI
	var nom: String = maison.get("nom", "")
	if nom == "":
		nom = "Maison " + maison.get("famille", "")
	if a_moi:
		nom = "Ta maison"
	if Jeu.hud and Jeu.hud.has_method("regler_titre"):
		Jeu.hud.regler_titre(nom, "à l'intérieur", Color("#FFE2A0"))
	var gens := _presents()
	if not gens.is_empty() and not a_moi:
		Jeu.notifier("%s est là. Mieux vaut ne rien toucher…" % gens[0].nom, Color("#FFE2A0"))

## Les habitants qui sont chez eux en ce moment (la nuit, surtout).
func _presents() -> Array:
	return maison.get("habitants", []).filter(func(v): return is_instance_valid(v) and v.cache and not v.est_mort)

# ---------------- coque : sol, murs, lumière, sortie ----------------

func _poser(nom: String, p: Vector3, rot := 0.0, ech = 1.0) -> Node3D:
	var n: Node3D = load(DJ + nom + ".glb").instantiate()
	n.position = p
	n.rotation_degrees.y = rot
	n.scale = ech if ech is Vector3 else Vector3.ONE * float(ech)
	add_child(n)
	return n

func _boite(c: Vector3, t: Vector3) -> void:
	var corps := StaticBody3D.new()
	var f := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = t
	f.shape = b
	corps.add_child(f)
	corps.position = c
	add_child(corps)

func _coque() -> void:
	var w := largeur
	var d := profondeur
	# le noir autour : on est dedans, rien d'autre n'existe
	var nuit := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(70, 70)
	nuit.mesh = pm
	var mn := StandardMaterial3D.new()
	mn.albedo_color = Color(0.03, 0.025, 0.02)
	mn.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	nuit.material_override = mn
	nuit.position.y = -0.05
	add_child(nuit)
	var x := -w / 2.0 + 2.0
	while x < w / 2.0:
		var z := -d / 2.0 + 2.0
		while z < d / 2.0 + 0.5:
			_poser("floor_wood_large" if (int(x + z) / 4) % 3 != 0 else "floor_wood_large_dark", Vector3(x, 0, z), 0.0, Vector3(1, 1, 1))
			z += 4.0
		x += 4.0
	_boite(Vector3(0, -0.5, 0), Vector3(w + 4, 1, d + 4))
	# murs : fond et côtés ; le devant reste ouvert (la caméra regarde de là)
	x = -w / 2.0 + 2.0
	var k := 0
	while x < w / 2.0:
		_poser("wall_window_closed" if k % 2 == 1 else "wall", Vector3(x, 0, -d / 2.0), 0.0)
		x += 4.0
		k += 1
	var z2 := -d / 2.0 + 2.0
	while z2 < d / 2.0:
		_poser("wall", Vector3(-w / 2.0, 0, z2), 90.0)
		_poser("wall", Vector3(w / 2.0, 0, z2), -90.0)
		z2 += 4.0
	_poser("wall_corner", Vector3(-w / 2.0, 0, -d / 2.0), 0.0)
	_poser("wall_corner", Vector3(w / 2.0, 0, -d / 2.0), -90.0)
	_boite(Vector3(0, 2, -d / 2.0 - 0.3), Vector3(w + 2, 4, 1))
	_boite(Vector3(-w / 2.0 - 0.3, 2, 0), Vector3(1, 4, d + 2))
	_boite(Vector3(w / 2.0 + 0.3, 2, 0), Vector3(1, 4, d + 2))
	_boite(Vector3(0, 2, d / 2.0 + 0.8), Vector3(w + 2, 4, 1))
	# seuil : bande de lumière au sol, et la sortie
	_poser("floor_tile_small", Vector3(0, 0.02, d / 2.0 + 0.2), 0.0, Vector3(1.2, 1, 0.6))
	var sortie := PorteSortie.new()
	sortie.position = Vector3(0, 0, d / 2.0 - 0.4)
	add_child(sortie)
	for p in [Vector3(-w / 2.0 + 0.6, 2.4, -1.0), Vector3(w / 2.0 - 0.6, 2.4, -1.0)]:
		var t := _poser("torch_mounted", p, 90.0 if p.x < 0 else -90.0)
		t.scale = Vector3.ONE
	_lumiere(Vector3(0, 3.2, -0.5), Color(1.0, 0.72, 0.42), 2.4, w * 0.9)
	_lumiere(Vector3(-w / 3.0, 2.5, -d / 4.0), Color(1.0, 0.6, 0.3), 1.2, 7.0)
	_lumiere(Vector3(w / 3.0, 2.5, -d / 4.0), Color(1.0, 0.6, 0.3), 1.2, 7.0)

func _lumiere(p: Vector3, c: Color, e: float, r: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = e
	l.omni_range = r
	l.position = p
	add_child(l)

# ---------------- mobilier ----------------

func _maison() -> void:
	var w := largeur
	var d := profondeur
	var lits := clampi(maison.get("habitants", []).size(), 1, 3)
	for i in lits:
		_poser("bed_decorated" if i == 0 else "bed_frame", Vector3(-w / 2.0 + 1.6 + i * 2.2, 0, -d / 2.0 + 2.2), 0.0)
	_poser("table_medium", Vector3(1.8, 0, -0.6), 15.0)
	_poser("chair", Vector3(0.5, 0, -0.4), 90.0)
	_poser("chair", Vector3(3.1, 0, -0.9), -80.0)
	_poser("plate_food_A", Vector3(1.8, 1.0, -0.6), 0.0, 0.8)
	_poser("candle_triple", Vector3(2.3, 1.0, -0.9), 0.0)
	_poser("shelves", Vector3(w / 2.0 - 2.0, 0, -d / 2.0 + 0.8), 0.0)
	_poser("barrel_small_stack", Vector3(w / 2.0 - 1.2, 0, 1.0), 30.0)
	_poser("box_small_decorated", Vector3(-w / 2.0 + 1.0, 0, 1.6), 10.0)
	_boite(Vector3(1.8, 0.5, -0.6), Vector3(2, 1, 2))
	if a_moi:
		_poser("banner_patternA_blue", Vector3(0, 0, -d / 2.0 + 0.6), 0.0)
		CoffrePerso.creer(self, Vector3(-1.6, 0, -d / 2.0 + 1.4), 0.0)
		var lit := ObjetInterieur.new()
		lit.genre = "lit"
		lit.position = Vector3(-w / 2.0 + 1.6, 0, -d / 2.0 + 2.8)
		add_child(lit)
		var intendant := ObjetInterieur.new()
		intendant.genre = "intendant"
		intendant.position = Vector3(w / 2.0 - 2.4, 0, 0.6)
		add_child(intendant)
		_figurant("Ase l'intendante", "robe", Color(0.55, 0.36, 0.3), intendant.position + Vector3(0.8, 0, -0.4), 200.0)
	else:
		var coffre := ObjetInterieur.new()
		coffre.genre = "coffre"
		coffre.interieur = self
		coffre.position = Vector3(-w / 2.0 + 1.4 + lits * 2.2, 0, -d / 2.0 + 1.4)
		add_child(coffre)
		_poser("trunk_large_A", coffre.position, 0.0)

func _taverne() -> void:
	var w := largeur
	var d := profondeur
	for z in [-1.5, 2.0]:
		_poser("table_long_tablecloth_decorated_A", Vector3(-2.5, 0, z), 90.0)
		_boite(Vector3(-2.5, 0.5, z), Vector3(4, 1, 2))
		for k in 3:
			_poser("stool", Vector3(-4.0 + k * 1.5, 0, z - 1.4), 0.0)
			_poser("stool", Vector3(-4.0 + k * 1.5, 0, z + 1.4), 0.0)
	_poser("table_long", Vector3(w / 2.0 - 3.0, 0, -1.0), 0.0)
	_boite(Vector3(w / 2.0 - 3.0, 0.5, -1.0), Vector3(2, 1, 4))
	for k2 in 3:
		_poser("keg_decorated" if k2 == 1 else "keg", Vector3(-w / 2.0 + 2.0 + k2 * 2.4, 0, -d / 2.0 + 1.4), 0.0)
	_poser("barrel_large", Vector3(w / 2.0 - 1.2, 0, -d / 2.0 + 1.3), 0.0)
	_poser("shelf_small_candles", Vector3(2.0, 2.2, -d / 2.0 + 0.6), 0.0)
	var chope := ObjetInterieur.new()
	chope.genre = "chope"
	chope.position = Vector3(w / 2.0 - 4.2, 0, -1.0)
	add_child(chope)
	_figurant("Tavernier", "barbare", Color(0.6, 0.42, 0.3), Vector3(w / 2.0 - 1.6, 0, -1.2), -90.0)
	_figurant("Buveur", "paysan", Color(0.5, 0.56, 0.4), Vector3(-4.0, 0, -0.1), 180.0, "Sit_Chair_Idle")
	_figurant("Buveuse", "robe", Color(0.7, 0.42, 0.32), Vector3(-1.0, 0, 3.4), 0.0, "Sit_Chair_Idle")

func _forge() -> void:
	var w := largeur
	_poser("barrel_large", Vector3(-w / 2.0 + 1.2, 0, -2.0), 0.0)
	var a: Node3D = load(O + "anvil.gltf").instantiate()
	a.position = Vector3(0.5, 0, -1.0)
	a.scale = Vector3.ONE * 1.2
	add_child(a)
	_poser("sword_shield", Vector3(-2.0, 0, -profondeur / 2.0 + 0.8), 0.0)
	_poser("sword_shield_gold", Vector3(2.4, 0, -profondeur / 2.0 + 0.8), 0.0)
	_poser("box_stacked", Vector3(w / 2.0 - 2.0, 0, -1.0), 0.0, 0.7)
	_lumiere(Vector3(0.5, 1.5, -1.6), Color(1.0, 0.45, 0.15), 2.0, 6.0)

func _temple() -> void:
	var w := largeur
	var d := profondeur
	for x in [-4.5, 4.5]:
		for z in [-2.5, 1.5]:
			_poser("pillar_decorated", Vector3(x, 0, z), 0.0)
			_boite(Vector3(x, 2, z), Vector3(1.4, 4, 1.4))
	_poser("column", Vector3(0, 0, -d / 2.0 + 2.0), 0.0, 1.4)
	for x2 in [-1.4, 1.4]:
		_poser("candle_triple", Vector3(x2, 0, -d / 2.0 + 2.4), 0.0, 1.4)
	_poser("banner_patternB_white", Vector3(-3.0, 0, -d / 2.0 + 0.6), 0.0)
	_poser("banner_patternB_white", Vector3(3.0, 0, -d / 2.0 + 0.6), 0.0)
	var autel := Autel.new()
	autel.position = Vector3(0, 0, -d / 2.0 + 3.6)
	add_child(autel)
	_lumiere(Vector3(0, 3, -d / 2.0 + 2.0), Color(0.6, 0.8, 1.0), 2.0, 9.0)

func _chateau() -> void:
	var w := largeur
	var d := profondeur
	for x in [-5.0, 5.0]:
		for z in [-3.5, 0.5]:
			_poser("pillar_decorated", Vector3(x, 0, z), 0.0)
			_boite(Vector3(x, 2, z), Vector3(1.4, 4, 1.4))
	for x2 in [-3.0, 3.0]:
		_poser("banner_patternA_blue", Vector3(x2, 0, -d / 2.0 + 0.6), 0.0)
	_poser("table_long_tablecloth_decorated_A", Vector3(0, 0, 0.5), 90.0)
	_boite(Vector3(0, 0.5, 0.5), Vector3(4, 1, 2))
	var trone := _poser("chair", Vector3(0, 0, -d / 2.0 + 1.8), 180.0, 1.7)
	trone.rotation_degrees.y = 0.0
	var tresor := ObjetInterieur.new()
	tresor.genre = "tresor"
	tresor.interieur = self
	tresor.position = Vector3(w / 2.0 - 2.0, 0, -d / 2.0 + 1.6)
	add_child(tresor)
	_poser("chest_gold", tresor.position, 0.0, 1.3)
	_poser("coin_stack_large", tresor.position + Vector3(-1.4, 0, 0.6), 0.0)
	_poser("coin_stack_medium", tresor.position + Vector3(-1.0, 0, 1.2), 0.0)
	_figurant("Huscarl", "garde", Color(0.2, 0.32, 0.6), Vector3(w / 2.0 - 4.0, 0, -d / 2.0 + 2.6), 180.0)
	_figurant("Huscarl", "garde", Color(0.2, 0.32, 0.6), Vector3(-w / 2.0 + 3.0, 0, -d / 2.0 + 2.6), 180.0)

func _hall() -> void:
	var w := largeur
	var d := profondeur
	_poser("table_long_broken", Vector3(-2.0, 0, 0.0), 90.0)
	_poser("barrel_large_decorated", Vector3(w / 2.0 - 1.5, 0, -d / 2.0 + 1.4), 0.0)
	_poser("banner_patternA_red", Vector3(0, 0, -d / 2.0 + 0.6), 0.0)
	var coffre := ObjetInterieur.new()
	coffre.genre = "coffre"
	coffre.interieur = self
	coffre.position = Vector3(3.0, 0, -d / 2.0 + 1.6)
	add_child(coffre)
	_poser("chest", coffre.position, 0.0)

## Un personnage de décor (pas un habitant qui vit sa journée).
func _figurant(nom: String, modele: String, teinte: Color, p: Vector3, rot: float, a := "Idle") -> void:
	var f: Node3D = load(Villageois.MODELES.get(modele, Villageois.MODELES["paysan"])).instantiate()
	for n in Villageois.CACHES:
		if modele == "garde" and n == "Round_Shield":
			continue
		var x := f.find_child(n, true, false)
		if x:
			x.visible = false
	for m in f.find_children("*Body*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var src = mi.get_active_material(0)
		if src is StandardMaterial3D:
			var c: StandardMaterial3D = src.duplicate()
			c.albedo_color = teinte
			mi.set_surface_override_material(0, c)
	f.position = p
	f.rotation_degrees.y = rot
	add_child(f)
	var ap: AnimationPlayer = f.find_child("AnimationPlayer", true, false)
	if ap and ap.has_animation(a):
		ap.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		ap.play(a)
	var l := Label3D.new()
	l.text = nom
	l.font_size = 30
	l.outline_size = 8
	l.pixel_size = 0.009
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = p + Vector3(0, 2.5, 0)
	l.modulate = Color("#F2E6C8")
	add_child(l)
