class_name Pouvoirs
extends Node
## Les pouvoirs du monde : ils coûtent du mana, se canalisent (barre dorée, cercle runique au sol,
## héros qui incante) puis se déchaînent. Pensés pour le plaisir de se sentir surpuissant.
##   - Téléportation : grande carte, on touche un point, on y apparaît.
##   - Lames de moisson : des scies runiques rasent arbres, rochers et filons autour de soi.
##   - Déchaînement : une longue incantation qui pulvérise tout dans un grand rayon.

const LISTE := {
	"tp": {"nom": "Téléportation", "mana": 30.0, "canal": 1.6, "icone": "res://assets/icones_sorts/pouvoir_tp.svg",
		"fiche": "Ouvre la grande carte : touche un endroit, ton héros incante et y apparaît."},
	"lames": {"nom": "Lames de moisson", "mana": 35.0, "canal": 1.2, "icone": "res://assets/icones_sorts/pouvoir_lames.svg",
		"fiche": "Des scies runiques jaillissent et rasent tous les arbres, rochers et filons proches."},
	"dechainement": {"nom": "Déchaînement", "mana": 70.0, "canal": 2.6, "icone": "res://assets/icones_sorts/pouvoir_dechainement.svg",
		"fiche": "Longue incantation, puis une explosion qui pulvérise tout dans un rayon de 18 m."},
}

static var moi: Pouvoirs

var h: Heros
var principale: Node
var _cercle: MeshInstance3D
var _occupe := false

func _ready() -> void:
	moi = self

func _exit_tree() -> void:
	if moi == self:
		moi = null

func peut(id: String) -> String:
	if h == null or h.est_mort:
		return "Impossible maintenant"
	if Heros.en_epreuve:
		return "Tes pouvoirs sont scellés ici"
	if _occupe or h.action != "":
		return "Déjà en train d'incanter"
	if h.mana < LISTE[id]["mana"]:
		return "Pas assez de mana"
	return ""

func lancer(id: String) -> void:
	var r := peut(id)
	if r != "":
		Jeu.notifier(r, Color("#CFD6EE"))
		Sons.jouer("refus", h.global_position, -10.0)
		return
	match id:
		"tp":
			ouvrir_carte()
		"lames":
			_lames()
		"dechainement":
			_dechainement()

func ouvrir_carte() -> void:
	var c := CanvasLayer.new()
	c.set_script(load("res://scripts/pouvoirs/grande_carte.gd"))
	principale.add_child(c)
	c.ouvrir(self)

# ---------------- incantation commune ----------------

## Canalise avec le cercle runique au sol ; renvoie vrai si l'incantation va au bout.
func _incanter(id: String, couleur: Color) -> bool:
	var d: Dictionary = LISTE[id]
	_occupe = true
	h.canaliser(d["nom"], d["canal"], "Spellcast_Raise")
	_montrer_cercle(couleur, d["canal"])
	Sons.jouer("activation", h.global_position, -4.0, 0.7)
	var res: Array = await h.canal_fini
	_occupe = false
	if is_instance_valid(_cercle):
		_cercle.queue_free()
	if not res[1]:
		Jeu.notifier("Incantation interrompue", Color("#FFB37A"))
		return false
	h.mana -= d["mana"]
	h.mana_change.emit(h.mana, h.mana_max)
	return true

func _montrer_cercle(c: Color, duree: float) -> void:
	_cercle = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(5, 5)
	_cercle.mesh = pm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
uniform vec3 couleur : source_color;
uniform float k = 0.0;
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float anneau = smoothstep(0.05, 0.0, abs(r - 0.9 * k)) + smoothstep(0.03, 0.0, abs(r - 0.7 * k)) * 0.7;
	float runes = step(0.7 * k, r) * step(r, 0.9 * k) * step(0.5, fract(a * 5.0 / 3.14159 + TIME * 0.6)) * 0.5;
	float rayons = step(r, 0.7 * k) * smoothstep(0.02, 0.0, abs(fract(a * 3.0 / 3.14159 - TIME * 0.3) - 0.5) * r) * 0.4;
	vec3 col = couleur * (anneau + runes + rayons);
	ALBEDO = col;
	ALPHA = clamp(max(max(col.r, col.g), col.b), 0.0, 1.0);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("couleur", c)
	_cercle.material_override = m
	_cercle.position = Vector3(0, 0.06, 0)
	h.add_child(_cercle)
	var tw := _cercle.create_tween()
	tw.tween_method(func(v): m.set_shader_parameter("k", v), 0.15, 1.0, duree * 0.9).set_ease(Tween.EASE_OUT)
	# étincelles qui montent pendant l'incantation
	for i in int(duree / 0.35):
		get_tree().create_timer(i * 0.35).timeout.connect(func():
			if is_instance_valid(h) and _occupe:
				Effets.etincelles(h.get_parent(), h.global_position + Vector3(randf_range(-1.5, 1.5), 0.2, randf_range(-1.5, 1.5)), Vector3.UP, c, 6, 3.0, "star_06.png", 0.25))

# ---------------- téléportation ----------------

## Appelé par la grande carte avec le point touché.
func teleporter(cible: Vector3) -> void:
	var dest := _point_libre(cible)
	if dest == Vector3.INF:
		Jeu.notifier("Impossible d'apparaître là", Color("#FFB37A"))
		return
	if not await _incanter("tp", Color(0.55, 0.85, 1.0)):
		return
	var dep := h.global_position
	Effets.onde(h.get_parent(), dep, 3.0, Color(0.55, 0.85, 1.0))
	Effets.etincelles(h.get_parent(), dep + Vector3(0, 1, 0), Vector3.UP, Color(0.6, 0.9, 1.0), 40, 7.0, "star_06.png", 0.4)
	Effets.flash_lumiere(h.get_parent(), dep, Color(0.6, 0.9, 1.0), 5.0, 10.0, 0.3)
	Sons.jouer("verre_lourd", dep, 0.0, 1.4)
	h.modele.visible = false
	await get_tree().create_timer(0.25).timeout
	h.global_position = dest + Vector3(0, 0.1, 0)
	h.velocity = Vector3.ZERO
	var cam := get_viewport().get_camera_3d()
	if cam:
		cam.set("_focus", h.global_position)
	await get_tree().create_timer(0.15).timeout
	h.modele.visible = true
	Effets.onde(h.get_parent(), dest, 3.5, Color(0.55, 0.85, 1.0))
	Effets.etincelles(h.get_parent(), dest + Vector3(0, 0.3, 0), Vector3.UP, Color(0.6, 0.9, 1.0), 40, 6.0, "star_06.png", 0.4)
	Effets.flash_lumiere(h.get_parent(), dest, Color(0.6, 0.9, 1.0), 5.0, 10.0, 0.3)
	Sons.jouer("atterrissage", dest, 0.0, 1.3)
	h.jouer("Cheer", 0.1, 1.2, 0.5)

## Endroit libre le plus proche (pas dans un mur, un rocher ou un tronc).
func _point_libre(p: Vector3) -> Vector3:
	var espace := h.get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.6
	q.shape = s
	q.collision_mask = 1
	for r in [0.0, 1.0, 2.0, 3.0, 4.5, 6.0]:
		for k in (1 if r == 0.0 else 10):
			var a := TAU * k / 10.0
			var c: Vector3 = p + Vector3(cos(a), 0, sin(a)) * r
			if not _dans_le_monde(c):
				continue
			q.transform = Transform3D(Basis(), c + Vector3(0, 1.0, 0))
			if espace.intersect_shape(q, 1).is_empty():
				return c
	return Vector3.INF

func _dans_le_monde(p: Vector3) -> bool:
	if principale.get("carte") == "crypte":
		var poly := PackedVector2Array()
		for v in Caverne.CONTOUR:
			poly.append(v)
		return Geometry2D.is_point_in_polygon(Vector2(p.x, p.z), poly) or Rect2(1, 1, 26, 26).has_point(Vector2(p.x, p.z))
	return CarteSurface.LIMITES.grow(-1.0).has_point(Vector2(p.x, p.z))

# ---------------- lames de moisson ----------------

func _lames() -> void:
	var cibles := _cibles_recolte(16.0, 9)
	if cibles.is_empty():
		Jeu.notifier("Rien à moissonner ici (arbres, rochers, filons)", Color("#CFD6EE"))
		return
	if not await _incanter("lames", Color(1.0, 0.82, 0.4)):
		return
	h.jouer("Spellcast_Shoot", 0.1, 1.0, 0.5)
	Sons.jouer("activation", h.global_position, 0.0, 1.3)
	var i := 0
	_moisson = {"objets": [], "xp": 0}
	for c in cibles:
		_lame_vers(c, i * 0.12)
		i += 1
	# un seul récapitulatif quand toutes les lames sont revenues
	await get_tree().create_timer(0.12 * cibles.size() + 1.9).timeout
	if not _moisson["objets"].is_empty():
		h.ramasser({"or": 0, "objets": _moisson["objets"]}, "la moisson")
	if _moisson["xp"] > 0:
		h.gagner_xp_mine(_moisson["xp"])
	_moisson = {}

var _moisson := {}

## Arbres et rochers de la surface, filons du donjon, à portée.
func _cibles_recolte(rayon: float, n: int) -> Array:
	var res: Array = []
	var carte_s = CarteSurface.courante
	if carte_s and is_instance_valid(carte_s):
		res = carte_s.cibles_recolte(h.global_position, rayon, n)
	for f in get_tree().get_nodes_in_group("interactif"):
		if f is Filon and f.disponible() and f.global_position.distance_to(h.global_position) < rayon and res.size() < n:
			res.append({"genre": "filon", "pos": f.global_position, "noeud": f})
	return res

func _lame_vers(c: Dictionary, delai: float) -> void:
	if delai > 0.0:
		await get_tree().create_timer(delai).timeout
	var parent := h.get_parent()
	var lame := _creer_lame()
	parent.add_child(lame)
	var dep := h.global_position + Vector3(0, 1.6, 0)
	var cible: Vector3 = c["pos"] + Vector3(0, 1.0, 0)
	lame.global_position = dep
	var tw := lame.create_tween()
	var duree := 0.35 + dep.distance_to(cible) * 0.03
	tw.tween_method(func(k: float):
		if is_instance_valid(lame):
			var p := dep.lerp(cible, k)
			p.y += sin(k * PI) * 3.0
			lame.global_position = p, 0.0, 1.0, duree).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	if not is_instance_valid(lame):
		return
	# la lame mord : copeaux, étincelles, puis l'arbre tombe
	var couleur := Color(0.55, 0.38, 0.2) if c["genre"] == "arbre" else Color(0.7, 0.7, 0.75)
	for k in 4:
		Effets.etincelles(parent, cible, Vector3.UP + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)), couleur, 8, 4.0, "spark_04.png", 0.3)
		Sons.jouer("metal" if c["genre"] != "arbre" else "coup_os", cible, -8.0, randf_range(1.2, 1.6))
		await get_tree().create_timer(0.18).timeout
	_recolter(c)
	var tw2 := lame.create_tween()
	tw2.tween_property(lame, "scale", Vector3.ZERO, 0.25)
	tw2.tween_callback(lame.queue_free)

func _creer_lame() -> Node3D:
	var n := Node3D.new()
	n.set_script(load("res://scripts/pouvoirs/lame_runique.gd"))
	return n

func _recolter(c: Dictionary) -> void:
	var gains: Array = []
	match c["genre"]:
		"arbre":
			CarteSurface.courante.abattre(c)
			gains.append(Objets.creer("bois", "commun", randi_range(2, 4)))
		"rocher":
			CarteSurface.courante.abattre(c)
			gains.append(Objets.creer("pierre", "commun", randi_range(1, 3)))
			if randf() < 0.35:
				gains.append(Objets.creer(["minerai_cuivre", "minerai_fer"].pick_random(), "commun", randi_range(1, 2)))
		"filon":
			var f: Filon = c["noeud"]
			if is_instance_valid(f):
				f.recolter_magie(h)
			return
	# on regroupe : une pile de bois, une pile de pierre, un seul gain d'expérience
	if _moisson.is_empty():
		h.ramasser({"or": 0, "objets": gains}, "la moisson")
		return
	for g in gains:
		var fusion := false
		for x in _moisson["objets"]:
			if x["id"] == g["id"]:
				x["qte"] += g["qte"]
				fusion = true
		if not fusion:
			_moisson["objets"].append(g)
	_moisson["xp"] += 4

# ---------------- déchaînement ----------------

const RAYON_DECHAINEMENT := 18.0

func _dechainement() -> void:
	if not await _incanter("dechainement", Color(1.0, 0.4, 0.2)):
		return
	var parent := h.get_parent()
	var o := h.global_position
	h.jouer("Spellcast_Shoot", 0.05, 0.9, 0.6)
	Effets.micro_pause(get_tree(), 0.12)
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("secouer"):
		cam.secouer(1.4)
	Sons.jouer("coup_lourd", o, 4.0, 0.5)
	Sons.jouer("verre_lourd", o, 2.0, 0.6)
	for i in 4:
		Effets.onde(parent, o, RAYON_DECHAINEMENT * (0.4 + i * 0.2), Color(1.0, 0.45 + i * 0.1, 0.2), 0.5 + i * 0.12)
	Effets.flash_lumiere(parent, o + Vector3(0, 2, 0), Color(1.0, 0.55, 0.25), 12.0, 30.0, 0.6)
	for i in 3:
		Effets.etincelles(parent, o + Vector3(0, 0.5, 0), Vector3.UP, Color(1.0, 0.6 - i * 0.15, 0.2), 40, 14.0, "fire_01.png" if i == 0 else "spark_04.png", 0.7)
	# tout ce qui est dans le rayon prend de plein fouet
	for e in h.cibles_touchables():
		var d: float = e.global_position.distance_to(o)
		if d < RAYON_DECHAINEMENT:
			var montant: float = (2600.0 if not e.get("fiche") or not e.fiche.get("boss", false) else 900.0) * (1.0 - d / RAYON_DECHAINEMENT * 0.4)
			e.recevoir({"montant": montant, "source": h, "critique": true, "recul": 3.0, "lourd": true})
	Jeu.evenement("frappe", {"centre": o, "rayon": RAYON_DECHAINEMENT, "degats": 99999.0, "source": h})
