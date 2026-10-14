class_name CarteSurface
extends Node3D
## Carte de surface « Le Val des Racines » : sanctuaire de Freya, chemin forestier, clairière des draugr,
## Bourg de Skjold (zone sûre), Portail d'Yggdrasil. Tout est posé à la main, sauf la forêt de remplissage
## qui suit des règles (couloir dégagé, jamais d'arbre entre la caméra et le chemin).
##
## Repère : x vers l'est, z vers le sud, 1 unité = 1 m. Le nord (z petit) est en haut de l'écran.

const H := "res://assets/surface/hexa/"
const F := "res://assets/surface/foret/"
const O := "res://assets/surface/outils/"
const HW := "res://assets/halloween/"
const DJ := "res://assets/donjon/"
const R := "res://assets/surface/ressources/"

const LIMITES := PlanMonde.LIMITES                 ## zone jouable (x, z)
const CHEMIN := [
	Vector2(36, 104), Vector2(40, 96), Vector2(47, 88), Vector2(55, 80), Vector2(62, 70), Vector2(70, 62),
	Vector2(80, 57), Vector2(92, 53), Vector2(104, 48), Vector2(116, 42), Vector2(127, 37), Vector2(127, 16), Vector2(127, 3),
]
const SANCTUAIRE := Vector3(36, 0, 108)
const CLAIRIERE := Vector3(62, 0, 69)
const BOURG := Rect2(104, 16, 46, 42)
const PLACE := Vector3(127, 0, 37)
const PORTAIL := Vector3(127, 0, -5)
const PORTE_BOURG := Vector3(104, 0, 48)
const PLACE_VILLAGE := PlanMonde.PLACE_BREKKA
## Terres Gâtées : au sud-est du Bourg, une lande morte où la Horde se lève sans fin.
const TERRES := Rect2(134, 76, 34, 48)
const ROUTE_TERRES := [Vector2(127.5, 57), Vector2(129, 66), Vector2(139, 78)]

## Lieux nommés (bandeaux d'entrée de zone, minicarte, guidage)
const LIEUX := PlanMonde.LIEUX

const TEINTE_FORET := Color(0.7, 0.76, 0.68)     ## le pack Forest est très vif : on l'assourdit pour l'heure dorée

const TEINTE_BOIS_MORT := Color(0.5, 0.42, 0.38)  ## racines et arbres morts : bruns sombres, pas orange

var _rng := RandomNumberGenerator.new()

func teinter(n: Node, c: Color) -> void:
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		for k in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(k)
			if mat is StandardMaterial3D:
				var m2: StandardMaterial3D = mat.duplicate()
				m2.albedo_color = c
				mi.set_surface_override_material(k, m2)
var _cache := {}
var _decor: Node3D
var _colliders: Node3D

var _t_depart := 0

func _exit_tree() -> void:
	if courante == self:
		courante = null
	NavMonde.oublier()

func _ready() -> void:
	_t_depart = Time.get_ticks_msec()
	courante = self
	_rng.seed = 7741
	_decor = Node3D.new()
	_decor.name = "Decor"
	add_child(_decor)
	_colliders = Node3D.new()
	_colliders.name = "Collisions"
	add_child(_colliders)
	ZoneSure.vider()
	ZoneSure.ajouter("Bourg de Skjold", PLACE, 27.0)
	# 1. le plan : routes, villes, lac peints dans le masque du sol (la forêt les évitera)
	PlanMonde.preparer()
	PlanMonde.ligne(CHEMIN, 2.6, 0, 1.0, 6.0)
	PlanMonde.ligne(ROUTE_TERRES, 2.2, 0, 1.0, 4.0)
	PlanMonde.rect(BOURG, 0, 0.55, 7.0)
	PlanMonde.disque(Vector2(PLACE.x, PLACE.z), 15.0, 1)
	PlanMonde.disque(Vector2(PORTAIL.x, PORTAIL.z + 4.0), 10.0, 1, 0.75, 8.0)
	PlanMonde.reserver_disque(Vector2(SANCTUAIRE.x, SANCTUAIRE.z), 13.0)
	PlanMonde.reserver_disque(Vector2(CLAIRIERE.x, CLAIRIERE.z), 14.0)
	PlanMonde.reserver(TERRES.grow(5.0))
	PlanMonde.peindre_lac()
	bourgs = Bourgs.new()
	bourgs.construire(self)
	# 2. le reste du décor
	_sol()
	_bordures()
	_sanctuaire()
	_clairiere()
	_bourg()
	_portail()
	_lanternes_du_chemin()
	_lac()
	_montagnes()
	_foret()
	_herbes()
	_terres_gatees()
	# 3. la grille de marche des habitants
	var t0 := Time.get_ticks_msec()
	NavMonde.construire(self)
	print("Monde : décor %d ms, grille de marche %d ms, %d arbres moissonnables" % [t0 - _t_depart, Time.get_ticks_msec() - t0, recoltables.size()])

var bourgs: Bourgs

# =================== fondu des bâtiments qui cachent le héros ===================
## La caméra regarde du sud : une maison juste au sud du héros le cacherait. On la rend translucide.
var _fondus := {}            ## case 32 m -> [{n, l, m, v, vise}]
var _fondu_t := 0.0
var _fondus_actifs: Array = []

## Le rendu « compatibilité » ignore GeometryInstance3D.transparency : on passe par une copie translucide du matériau.
func _appliquer_fondu(e: Dictionary, v: float) -> void:
	for m in e["m"]:
		if not is_instance_valid(m) or not m is MeshInstance3D:
			continue
		var mi := m as MeshInstance3D
		if v <= 0.001:
			mi.material_override = null
			continue
		var mat: StandardMaterial3D = mi.get_meta("mat_fondu") if mi.has_meta("mat_fondu") else null
		if mat == null:
			var src := mi.get_active_material(0)
			mat = (src.duplicate() if src is StandardMaterial3D else StandardMaterial3D.new()) as StandardMaterial3D
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.cull_mode = BaseMaterial3D.CULL_BACK
			mi.set_meta("mat_fondu", mat)
		mat.albedo_color.a = 1.0 - v
		mi.material_override = mat

func fondu_ajouter(n: Node3D, demi_largeur: float) -> void:
	var cle := Vector2i(floori(n.position.x / 32.0), floori(n.position.z / 32.0))
	if not _fondus.has(cle):
		_fondus[cle] = []
	_fondus[cle].append({"n": n, "l": demi_largeur, "m": n.find_children("*", "GeometryInstance3D", true, false), "v": 0.0, "vise": 0.0})

func _process(delta: float) -> void:
	_fondu_t -= delta
	var j = Jeu.joueur
	if j == null or not is_instance_valid(j):
		return
	var foyer: Vector3 = Pouvoirs.moi.controle.global_position if Pouvoirs.moi and Pouvoirs.moi.controle else j.global_position
	if _fondu_t <= 0.0:
		_fondu_t = 0.12
		for e in _fondus_actifs:
			e["vise"] = 0.0
		var c0 := Vector2i(floori(foyer.x / 32.0), floori(foyer.z / 32.0))
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				for e in _fondus.get(c0 + Vector2i(dx, dy), []):
					var p: Vector3 = e["n"].position
					var l: float = e["l"]
					if p.z + l * 0.4 > foyer.z + 0.5 and p.z - l < foyer.z + 11.0 and absf(p.x - foyer.x) < l + 2.5:
						e["vise"] = 0.62
						if not _fondus_actifs.has(e):
							_fondus_actifs.append(e)
	var restent: Array = []
	for e in _fondus_actifs:
		var v: float = move_toward(e["v"], e["vise"], delta * 3.0)
		if v != e["v"]:
			e["v"] = v
			_appliquer_fondu(e, v)
		if v > 0.0 or e["vise"] > 0.0:
			restent.append(e)
	_fondus_actifs = restent

## Accès publics pour les bâtisseurs (Bourgs).
func boite_collision(centre: Vector3, taille: Vector3, rot_y := 0.0) -> void:
	_boite_collision(centre, taille, rot_y)

func cylindre_collision(pos: Vector3, r: float, hauteur: float) -> StaticBody3D:
	return _cylindre_collision(pos, r, hauteur)

func feu_de_camp(p: Vector3) -> void:
	_feu_de_camp(p)

func feu(p: Vector3, taille: float) -> void:
	_feu(p, taille)

# =================== briques ===================

func _scene(chemin: String) -> PackedScene:
	if not _cache.has(chemin):
		_cache[chemin] = load(chemin)
	return _cache[chemin]

## Pose un modèle. collision : "" aucune, "boite" (d'après sa forme), "tronc" (cylindre étroit).
func poser(chemin: String, pos: Vector3, rot_deg := 0.0, echelle = 1.0, collision := "", parent: Node = null) -> Node3D:
	var s := _scene(chemin)
	if s == null:
		push_warning("modèle manquant : " + chemin)
		return null
	var n: Node3D = s.instantiate()
	n.position = pos
	n.rotation_degrees.y = rot_deg
	n.scale = echelle if echelle is Vector3 else Vector3.ONE * float(echelle)
	(parent if parent else _decor).add_child(n)
	if chemin.begins_with(F):
		teinter(n, TEINTE_BOIS_MORT if chemin.contains("Bare") else TEINTE_FORET)
	if collision == "boite":
		var b := boite_locale(n)
		if b.size.length() > 0.01:
			var centre := pos + Basis(Vector3.UP, n.rotation.y) * b.get_center()
			_boite_collision(centre, b.size * Vector3(0.9, 1.0, 0.9), n.rotation.y)
	elif collision == "tronc":
		_cylindre_collision(pos, 0.55 * (n.scale.x / 2.0 + 0.5), 4.0)
	return n

## Boîte englobante du modèle mis à l'échelle, sans position ni rotation (repère du modèle).
func boite_locale(n: Node3D) -> AABB:
	var acc: Array = [null]
	_aabb(n, Transform3D(Basis.from_scale(n.scale), Vector3.ZERO), acc, true)
	return acc[0] if acc[0] != null else AABB()

func _aabb(n: Node, xf: Transform3D, acc: Array, racine := false) -> void:
	var t := xf
	if not racine and n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D:
		var b: AABB = t * (n as MeshInstance3D).get_aabb()
		acc[0] = b if acc[0] == null else acc[0].merge(b)
	for c in n.get_children():
		_aabb(c, t, acc)

## Obstacles connus de la grille de marche : [centre, taille, rot_y] et [pos, rayon] pour les cylindres.
var obstacles: Array = []
var obstacles_ronds: Array = []

func _boite_collision(centre: Vector3, taille: Vector3, rot_y := 0.0) -> void:
	if taille.y > 0.4 and centre.y > -0.2:
		obstacles.append([centre, taille, rot_y])
	var corps := StaticBody3D.new()
	var f := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = taille
	f.shape = b
	corps.add_child(f)
	_colliders.add_child(corps)
	corps.position = centre
	corps.rotation.y = rot_y

func _cylindre_collision(pos: Vector3, rayon: float, hauteur: float) -> StaticBody3D:
	obstacles_ronds.append([pos, rayon])
	var corps := StaticBody3D.new()
	var f := CollisionShape3D.new()
	var c := CylinderShape3D.new()
	c.radius = rayon
	c.height = hauteur
	f.shape = c
	f.position.y = hauteur / 2.0
	corps.add_child(f)
	_colliders.add_child(corps)
	corps.position = pos
	return corps

func lumiere(pos: Vector3, couleur: Color, energie: float, portee: float, parent: Node = null) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = couleur
	l.light_energy = energie
	l.omni_range = portee
	l.omni_attenuation = 1.4
	l.position = pos
	(parent if parent else _decor).add_child(l)
	return l

## Premier maillage d'un modèle (pour les instances multiples : herbe, buissons, forêt).
func _maillage(chemin: String) -> Array:
	var n: Node3D = _scene(chemin).instantiate()
	var res := []
	var mis := n.find_children("*", "MeshInstance3D", true, false)
	if not mis.is_empty():
		var mi: MeshInstance3D = mis[0]
		var xf := Transform3D()
		var x: Node = mi
		while x != n and x is Node3D:
			xf = (x as Node3D).transform * xf
			x = x.get_parent()
		var mesh: Mesh = mi.mesh
		if chemin.begins_with(F):
			mesh = mesh.duplicate()
			for k in mesh.get_surface_count():
				var mat := mesh.surface_get_material(k)
				if mi.get_surface_override_material(k):
					mat = mi.get_surface_override_material(k)
				if mat is StandardMaterial3D:
					var m2: StandardMaterial3D = mat.duplicate()
					m2.albedo_color = TEINTE_BOIS_MORT if chemin.contains("Bare") else TEINTE_FORET
					mesh.surface_set_material(k, m2)
		res = [mesh, xf]
	n.free()
	return res

func _multimesh(chemin: String, transforms: Array, ombres := true, recolte := "") -> void:
	if transforms.is_empty():
		return
	var m := _maillage(chemin)
	if m.is_empty():
		return
	# découpage en cases de 64 m : la caméra ne dessine que les cases qu'elle voit
	var cases := {}
	for xf in transforms:
		var cle := Vector2i(floori(xf.origin.x / 64.0), floori(xf.origin.z / 64.0))
		if not cases.has(cle):
			cases[cle] = []
		cases[cle].append(xf)
	for cle in cases:
		var mm := _multimesh_lot(m, cases[cle], ombres)
		if recolte == "":
			continue
		# arbres et rochers moissonnables (Lames de moisson) : on garde leur place dans le multimesh
		var xfs: Array = cases[cle]
		for i in xfs.size():
			var o: Vector3 = xfs[i].origin
			if not LIMITES.has_point(Vector2(o.x, o.z)):
				continue
			recoltables.append({"genre": recolte, "pos": o, "mm": mm, "i": i, "xf": xfs[i] * m[1], "chemin": chemin,
				"corps": _troncs.get(Vector2i(roundi(o.x * 10.0), roundi(o.z * 10.0))), "abattu": false})
	return

func _multimesh_lot(m: Array, transforms: Array, ombres: bool) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = m[0]
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i] * m[1])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if ombres else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_decor.add_child(mmi)
	return mm

# =================== Terres Gâtées ===================

static func _dist_ligne(p: Vector2, pts: Array) -> float:
	var m := 1e9
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		m = minf(m, p.distance_to(a + ab * t))
	return m

static func _dist_route(p: Vector2) -> float:
	var m := 1e9
	for i in ROUTE_TERRES.size() - 1:
		var a: Vector2 = ROUTE_TERRES[i]
		var b: Vector2 = ROUTE_TERRES[i + 1]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		m = minf(m, p.distance_to(a + ab * t))
	return m

func _terres_gatees() -> void:
	var r := TERRES
	# sol brûlé, cendre et braises (le reste du monde est vert : on la repère de loin)
	var sol := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = r.size + Vector2(10, 10)
	sol.mesh = pm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
varying vec3 pm;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float b(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), u.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), u.x), u.y); }
void vertex() { pm = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 uvc = UV * 2.0 - 1.0;
	float bord = smoothstep(1.0, 0.82, max(abs(uvc.x), abs(uvc.y)));
	float n = b(pm.xz * 0.35) * 0.6 + b(pm.xz * 1.3) * 0.4;
	vec3 c = mix(vec3(0.16, 0.12, 0.1), vec3(0.3, 0.24, 0.2), n);
	float braise = smoothstep(0.78, 0.86, b(pm.xz * 0.9 + vec2(TIME * 0.05, 0.0)));
	ALBEDO = c;
	ROUGHNESS = 0.95;
	EMISSION = vec3(1.0, 0.35, 0.1) * braise * 0.9 * (0.7 + 0.3 * sin(TIME * 2.0 + pm.x));
	ALPHA = bord;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.render_priority = 1
	sol.material_override = mat
	sol.transparency = 0.0
	sol.position = Vector3(r.get_center().x, 0.03, r.get_center().y)
	_decor.add_child(sol)
	# chemin de terre depuis la porte sud du Bourg
	for i in ROUTE_TERRES.size() - 1:
		var a: Vector2 = ROUTE_TERRES[i]
		var b: Vector2 = ROUTE_TERRES[i + 1]
		var n := int(a.distance_to(b) / 2.6)
		for k in n + 1:
			var q := a.lerp(b, float(k) / maxf(n, 1))
			poser(HW + "floor_dirt_small.gltf", Vector3(q.x, 0.02, q.y), _rng.randf_range(0, 360), 1.5)
	# tombes et os éparpillés, arbres morts en lisière, deux braseros
	var morts: Array = []
	for i in 34:
		var t := float(i) / 34.0
		var p := Vector2.ZERO
		match i % 4:
			0: p = Vector2(lerpf(r.position.x, r.end.x, t), r.position.y - 2.0)
			1: p = Vector2(lerpf(r.position.x, r.end.x, t), r.end.y + 2.0)
			2: p = Vector2(r.position.x - 2.0, lerpf(r.position.y, r.end.y, t))
			3: p = Vector2(r.end.x + 2.0, lerpf(r.position.y, r.end.y, t))
		if _dist_route(p) < 6.0 or not LIMITES.grow(6).has_point(p):
			continue
		poser(HW + ["tree_dead_large", "tree_dead_medium", "tree_dead_small"][i % 3] + ".gltf", Vector3(p.x, 0, p.y), _rng.randf_range(0, 360), _rng.randf_range(1.6, 2.4))
	for i in 26:
		var p2 := Vector3(_rng.randf_range(r.position.x + 2, r.end.x - 2), 0, _rng.randf_range(r.position.y + 2, r.end.y - 2))
		var nom: String = ["grave_A", "grave_A_destroyed", "gravestone", "gravemarker_A", "bone_A", "bone_B", "ribcage", "skull"][i % 8]
		poser(HW + nom + ".gltf", p2, _rng.randf_range(0, 360), 1.6 if nom.begins_with("grave") else 1.2)
	for p3 in [Vector3(r.position.x + 3, 0, r.position.y + 3), Vector3(r.end.x - 3, 0, r.end.y - 3), Vector3(r.position.x + 3, 0, r.end.y - 3)]:
		poser(HW + "post_skull.gltf", p3, 0.0, 1.4)
		_feu(p3 + Vector3(0, 2.2, 0), 0.4)
		lumiere(p3 + Vector3(0, 2.6, 0), Color(1.0, 0.45, 0.2), 2.0, 12.0)
	poser(HW + "arch_gate.gltf", Vector3(139.5, 0, 77.5), 35.0, 1.8)
	lumiere(Vector3(151, 6, 100), Color(1.0, 0.4, 0.25), 1.2, 30.0)

# =================== moisson (pouvoir « Lames de moisson ») ===================

static var courante: CarteSurface
var recoltables: Array = []
var _troncs := {}
const REPOUSSE := 240.0

func cibles_recolte(p: Vector3, rayon: float, n: int) -> Array:
	var l: Array = []
	for r in recoltables:
		if not r["abattu"] and Vector2(r["pos"].x - p.x, r["pos"].z - p.z).length() < rayon:
			l.append(r)
	l.sort_custom(func(a, b): return a["pos"].distance_squared_to(p) < b["pos"].distance_squared_to(p))
	return l.slice(0, n)

## L'arbre (ou le rocher) disparaît du multimesh ; un vrai modèle tombe à sa place, puis il repousse.
func abattre(r: Dictionary) -> void:
	if r["abattu"]:
		return
	r["abattu"] = true
	var mm: MultiMesh = r["mm"]
	mm.set_instance_transform(r["i"], Transform3D().scaled(Vector3(0.001, 0.001, 0.001)))
	var corps = r["corps"]
	if corps and is_instance_valid(corps):
		corps.set_deferred("disabled", true)
	var vrai: Node3D = _scene(r["chemin"]).instantiate()
	teinter(vrai, TEINTE_BOIS_MORT if r["chemin"].contains("Bare") else TEINTE_FORET)
	vrai.transform = r["xf"]
	_decor.add_child(vrai)
	var tw := vrai.create_tween()
	if r["genre"] == "arbre":
		var axe := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
		var base: Basis = vrai.transform.basis
		tw.tween_method(func(k: float): vrai.transform.basis = Basis(axe, k * 1.45) * base, 0.0, 1.0, 0.9).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func(): Effets.poussiere(self, r["pos"] + axe.cross(Vector3.UP) * 3.0, 14, Color(0.55, 0.5, 0.35, 0.7)))
		tw.tween_property(vrai, "position:y", -2.5, 1.2).set_delay(0.6)
	else:
		Effets.poussiere(self, r["pos"], 12, Color(0.6, 0.6, 0.62, 0.7))
		tw.tween_property(vrai, "scale", Vector3.ZERO, 0.35)
	tw.tween_callback(vrai.queue_free)
	get_tree().create_timer(REPOUSSE).timeout.connect(func(): _repousser(r))

func _repousser(r: Dictionary) -> void:
	if not is_instance_valid(self):
		return
	var mm: MultiMesh = r["mm"]
	var xf: Transform3D = r["xf"]
	var tw := create_tween()
	tw.tween_method(func(k: float): mm.set_instance_transform(r["i"], Transform3D(xf.basis.scaled(Vector3.ONE * maxf(k, 0.001)), xf.origin)), 0.0, 1.0, 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(func():
		r["abattu"] = false
		var corps = r["corps"]
		if corps and is_instance_valid(corps):
			corps.set_deferred("disabled", false))

static func distance_chemin(p: Vector2) -> Array:
	var meilleur := 1e9
	var proj := Vector2.ZERO
	for i in CHEMIN.size() - 1:
		var a: Vector2 = CHEMIN[i]
		var b: Vector2 = CHEMIN[i + 1]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var q := a + ab * t
		var d := p.distance_to(q)
		if d < meilleur:
			meilleur = d
			proj = q
	return [meilleur, proj]

static func lieu_de(p: Vector3) -> Dictionary:
	return PlanMonde.lieu_de(p)

# =================== sol et bords ===================

func _sol() -> void:
	var plan := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(LIMITES.size.x + 160, LIMITES.size.y + 160)
	pm.subdivide_width = 8
	pm.subdivide_depth = 8
	plan.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/sol_surface.gdshader")
	mat.set_shader_parameter("masque", ImageTexture.create_from_image(PlanMonde.masque))
	mat.set_shader_parameter("monde", Vector4(LIMITES.position.x, LIMITES.position.y, LIMITES.size.x, LIMITES.size.y))
	mat.set_shader_parameter("sanctuaire", Vector4(SANCTUAIRE.x, SANCTUAIRE.z, 8.5, 0))
	plan.material_override = mat
	plan.position = Vector3(LIMITES.get_center().x, 0, LIMITES.get_center().y)
	add_child(plan)
	_boite_collision(Vector3(LIMITES.get_center().x, -0.5, LIMITES.get_center().y), Vector3(LIMITES.size.x + 160, 1, LIMITES.size.y + 160))

func _bordures() -> void:
	# murs invisibles : la forêt dense et les montagnes font le bord visible
	var r := LIMITES
	var e := 2.0
	_boite_collision(Vector3(r.get_center().x, 3, r.position.y - e / 2), Vector3(r.size.x + 4, 6, e))
	_boite_collision(Vector3(r.get_center().x, 3, r.end.y + e / 2), Vector3(r.size.x + 4, 6, e))
	_boite_collision(Vector3(r.position.x - e / 2, 3, r.get_center().y), Vector3(e, 6, r.size.y + 4))
	_boite_collision(Vector3(r.end.x + e / 2, 3, r.get_center().y), Vector3(e, 6, r.size.y + 4))
	# au-delà des limites, la forêt continue (voir _foret) : le monde ne s'arrête pas net

# =================== sanctuaire de Freya ===================

func _sanctuaire() -> void:
	var c := SANCTUAIRE
	# pierres levées en cercle, ouvertes vers le chemin (nord-est)
	var n := 9
	for i in n:
		var a := TAU * i / n + 0.35
		var dir := Vector3(cos(a), 0, sin(a))
		var ouverture := dir.dot(Vector3(0.45, 0, -0.9).normalized())
		if ouverture > 0.8:
			continue
		var p := c + dir * 8.2
		var ech := Vector3(2.6, _rng.randf_range(4.4, 5.6), 2.4)
		poser(F + "Rock_3_" + ["A", "C", "E", "G"][i % 4] + "_Color1.gltf", p + Vector3(0, 1.2, 0), rad_to_deg(-a), ech, "")
		_cylindre_collision(p, 1.1, 4.0)
	# autel : colonne du donjon tronquée, bougies, lumière dorée
	poser(DJ + "column.glb", c + Vector3(0, 0, -6.0), 0.0, 0.55, "boite")
	poser(DJ + "candle_triple.glb", c + Vector3(-1.4, 0, -5.4), 0.0, 1.3)
	poser(DJ + "candle_triple.glb", c + Vector3(1.5, 0, -5.6), 40.0, 1.3)
	poser(HW + "shrine_candles.gltf", c + Vector3(0, 0, -7.6), 0.0, 1.4)
	lumiere(c + Vector3(0, 3.0, -4.0), Color(1.0, 0.8, 0.45), 2.2, 13.0)
	# fleurs et herbes plus denses à l'intérieur du cercle (sol sacré)
	poser(F + "Bush_4_A_Color1.gltf", c + Vector3(-5.5, 0, 2.5), 10.0, 3.5)
	poser(F + "Bush_4_C_Color1.gltf", c + Vector3(5.2, 0, 3.4), 80.0, 3.5)

# =================== clairière des Tertres ===================

func _clairiere() -> void:
	var c := CLAIRIERE
	# tertres funéraires : pierres basses, souches, un arbre mort couché
	poser(H + "decoration/nature/tree_single_A_cut.gltf", c + Vector3(-8, 0, -4), 20.0, 6.0, "tronc")
	poser(H + "decoration/nature/tree_single_B_cut.gltf", c + Vector3(7.5, 0, 6.5), 70.0, 6.0, "tronc")
	var mort := poser(F + "Tree_Bare_2_A_Color1.gltf", c + Vector3(-6.5, 0.6, 7.5), 0.0, 1.8)
	if mort:
		mort.rotation_degrees = Vector3(0, 35, 84)
		_boite_collision(c + Vector3(-5.0, 0.8, 6.4), Vector3(6.5, 1.6, 1.6), deg_to_rad(35))
	for p in [Vector3(9, 0, -5), Vector3(-9.5, 0, 3), Vector3(3, 0, 9.5), Vector3(-2, 0, -9.5)]:
		poser(F + "Rock_1_" + ["B", "D", "F", "H"][_rng.randi() % 4] + "_Color1.gltf", c + p, _rng.randf_range(0, 360), 1.7, "boite")
	poser(HW + "gravemarker_A.gltf", c + Vector3(-3.5, 0, -2.0), 15.0, 1.5)
	poser(HW + "gravemarker_B.gltf", c + Vector3(4.2, 0, -1.0), -20.0, 1.5)
	poser(HW + "grave_A_destroyed.gltf", c + Vector3(1.0, 0, 3.2), 0.0, 1.4)
	poser(HW + "skull.gltf", c + Vector3(-1.2, 0, 1.0), 40.0, 1.3)
	poser(HW + "bone_B.gltf", c + Vector3(2.5, 0, -3.0), 120.0, 1.3)

# =================== Bourg de Skjold ===================

func _bourg() -> void:
	var r := BOURG
	var B := H + "buildings/blue/"
	var N := H + "buildings/neutral/"
	var P := H + "decoration/props/"
	# --- enceinte ---
	# nord : rempart de pierre (ne masque rien : la caméra regarde vers le nord)
	for i in 5:
		var x := r.position.x + 3.0 + i * 10.0
		var gate := i == 2
		poser(N + ("wall_straight_gate" if gate else "wall_straight") + ".gltf", Vector3(x, 0, r.position.y), 0.0, Vector3(5, 5, 3))
		if not gate:
			_boite_collision(Vector3(x, 2.7, r.position.y), Vector3(10, 5.5, 2.4))
		else:
			_boite_collision(Vector3(x - 4.0, 2.7, r.position.y), Vector3(2.0, 5.5, 2.4))
			_boite_collision(Vector3(x + 4.0, 2.7, r.position.y), Vector3(2.0, 5.5, 2.4))
	# ouest, sud, est : palissade basse en bois (on voit par-dessus)
	_palissade(Vector3(r.position.x, 0, r.position.y + 2), Vector3(r.position.x, 0, r.end.y), [Vector2(44.0, 52.5)])
	_palissade(Vector3(r.end.x, 0, r.position.y + 2), Vector3(r.end.x, 0, r.end.y), [])
	_palissade(Vector3(r.position.x, 0, r.end.y), Vector3(r.end.x, 0, r.end.y), [Vector2(123.5, 131.5)])
	# tours : coins nord et porte principale (repères visibles de loin)
	for t in [Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, 0, r.position.y)]:
		poser(B + "building_tower_A_blue.gltf", t, 0.0, 5.0, "boite")
	for t in [Vector3(r.position.x, 0, 41.5), Vector3(r.position.x, 0, 55.0)]:
		poser(B + "building_tower_B_blue.gltf", t, 90.0, 4.2, "boite")
	# --- bâtiments, tournés vers la place ---
	# l'axe place → porte nord → portail reste dégagé : le temple se tient à côté, pas devant
	poser(B + "building_church_blue.gltf", Vector3(136.5, 0, 22.5), -20.0, 6.5, "boite")     # temple de Freya
	poser(B + "building_tavern_blue.gltf", Vector3(145, 0, 34.5), -90.0, 6.2, "boite")       # auberge
	poser(B + "building_blacksmith_blue.gltf", Vector3(111, 0, 26), 60.0, 6.2, "boite")      # forge
	poser(B + "building_market_blue.gltf", Vector3(140, 0, 51), 180.0, 5.6, "boite")         # comptoir
	poser(B + "building_home_A_blue.gltf", Vector3(145, 0, 44), -60.0, 6.5, "boite")
	poser(B + "building_home_B_blue.gltf", Vector3(113, 0, 53.5), 150.0, 6.5, "boite")
	poser(B + "building_home_A_blue.gltf", Vector3(146.5, 0, 21.5), -120.0, 5.6, "boite")
	poser(B + "building_well_blue.gltf", Vector3(135.5, 0, 33.5), 0.0, 4.5, "boite")
	# tentes de voyageurs près de la porte
	poser(P + "tent.gltf", Vector3(118.5, 0, 52.5), 200.0, 7.0, "boite")
	poser(P + "tent.gltf", Vector3(125.5, 0, 54.5), 160.0, 7.0, "boite")
	# --- forge : enclume, meule, râtelier, braise ---
	poser(O + "anvil.gltf", Vector3(115.6, 0, 32.2), 30.0, 1.2, "boite")
	poser(O + "grindstone.gltf", Vector3(112.2, 0, 33.6), -20.0, 1.2, "boite")
	poser(O + "tongs.gltf", Vector3(116.3, 1.0, 32.0), 70.0, 1.2)
	poser(O + "hammer.gltf", Vector3(115.0, 1.0, 32.5), 10.0, 1.2)
	poser(P + "weaponrack.gltf", Vector3(109.0, 0, 34.5), 90.0, 6.0, "boite")
	poser(P + "barrel.gltf", Vector3(108.5, 0, 31.0), 0.0, 6.0, "boite")
	lumiere(Vector3(114.0, 1.6, 30.0), Color(1.0, 0.45, 0.15), 2.4, 9.0)
	_feu(Vector3(113.2, 0.2, 29.6), 0.55)
	# --- comptoir du marchand : caisses, sacs, chariot ---
	for d in [[Vector3(135.2, 0, 47.2), "crate_A_big", 15.0], [Vector3(133.6, 0, 48.6), "crate_B_small", 40.0], [Vector3(144.6, 0, 47.0), "sack", 0.0],
			[Vector3(145.6, 0, 48.4), "sack", 50.0], [Vector3(146.5, 0, 53.5), "wheelbarrow", -30.0], [Vector3(134.0, 0, 52.5), "crate_long_A", 90.0]]:
		poser(P + d[1] + ".gltf", d[0], d[2], 6.0, "boite")
	# --- place : feu de camp et bancs ---
	_feu_de_camp(PLACE)
	for a in [0.6, 2.2, 3.8, 5.3]:
		var p := PLACE + Vector3(cos(a), 0, sin(a)) * 4.4
		poser(HW + "bench.gltf", p, rad_to_deg(-a) + 90.0, 0.95, "boite")
	# marchandises sur la place : un bourg qui vit
	poser(R + "Textiles_Stack_Large_Colored.gltf", Vector3(141.2, 0, 46.0), 30.0, 1.3, "boite")
	poser(R + "Pallet_Wood_Covered_A.gltf", Vector3(143.0, 0, 48.6), -15.0, 1.3, "boite")
	poser(R + "Iron_Bars_Stack_Medium.gltf", Vector3(110.6, 0, 30.0), 10.0, 1.3, "boite")
	poser(R + "Wood_Log_Stack.gltf", Vector3(108.6, 0, 37.5), 80.0, 1.4, "boite")
	# --- lumières chaudes du bourg (contraste avec le froid du bois) ---
	lumiere(Vector3(135, 5.0, 27.0), Color(1.0, 0.82, 0.5), 2.0, 14.0)
	lumiere(Vector3(141, 3.0, 35), Color(1.0, 0.7, 0.4), 1.4, 10.0)
	lumiere(Vector3(138, 3.0, 46.5), Color(1.0, 0.75, 0.45), 1.2, 9.0)
	for p in [Vector3(101.5, 0, 42.0), Vector3(101.5, 0, 54.5), Vector3(123.0, 0, 18.5), Vector3(131.0, 0, 18.5)]:
		poser(HW + "post_lantern.gltf", p, 0.0, 1.0, "tronc")
		lumiere(p + Vector3(0, 3.1, 0.6), Color(1.0, 0.78, 0.45), 1.3, 8.0)

## Palissade le long d'un bord, avec des ouvertures [debut, fin] mesurées le long du bord.
func _palissade(a: Vector3, b: Vector3, ouvertures: Array) -> void:
	var dir := (b - a)
	var longueur := dir.length()
	dir = dir.normalized()
	var pas := 5.6
	var rot := 0.0 if absf(dir.z) > 0.5 else 90.0
	var t := pas / 2.0
	while t < longueur:
		var abs_t := (a + dir * t)
		var coord := abs_t.z if absf(dir.z) > 0.5 else abs_t.x
		var ouvert := false
		for o in ouvertures:
			if coord > o.x and coord < o.y:
				ouvert = true
		if not ouvert:
			# le modèle est posé sur le bord d'un hexagone : on le recentre sur la ligne
			poser(H + "buildings/neutral/fence_wood_straight.gltf", abs_t + Basis(Vector3.UP, deg_to_rad(rot)) * Vector3(5.25, 0, 0), rot, Vector3(5.0, 5.0, pas / 1.155))
			var taille := Vector3(0.8, 3.0, pas) if rot == 0.0 else Vector3(pas, 3.0, 0.8)
			_boite_collision(abs_t + Vector3(0, 1.5, 0), taille)
		t += pas

func _feu_de_camp(c: Vector3) -> void:
	# cercle de petites pierres, bûches croisées, braises
	for i in 11:
		var a := TAU * i / 11.0
		poser(F + "Rock_2_A_Color1.gltf", c + Vector3(cos(a), 0, sin(a)) * 1.05, rad_to_deg(a) * 3.0, _rng.randf_range(2.0, 2.6))
	for d in [[0.0, Vector3(0, 0.12, 0)], [70.0, Vector3(0.05, 0.3, 0)], [135.0, Vector3(-0.05, 0.2, 0.05)]]:
		var b := poser(R + "Wood_Log_A.gltf", c + d[1], d[0], 1.1)
		if b:
			b.rotation_degrees.z = 12.0
	poser(R + "Wood_Log_Stack.gltf", c + Vector3(3.2, 0, -2.4), 20.0, 1.2, "boite")
	_cylindre_collision(c, 1.3, 1.0)
	_feu(c + Vector3(0, 0.35, 0), 1.25)
	var l := lumiere(c + Vector3(0, 2.2, 0), Color(1.0, 0.55, 0.22), 3.0, 14.0)
	l.set_script(load("res://scripts/surface/flamme.gd"))

## Flammes : particules texturées Kenney, additives, qui montent et rétrécissent.
func _feu(pos: Vector3, taille: float) -> void:
	var p := CPUParticles3D.new()
	p.amount = int(26 * taille) + 8
	p.lifetime = 0.9
	var q := QuadMesh.new()
	q.size = Vector2(1.1, 1.1) * taille
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.disable_fog = true   # sinon le brouillard dessine un carré clair autour de l'effet
	m.albedo_texture = load("res://assets/vfx/flame_03.png")
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	q.material = m
	p.mesh = q
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.35 * taille
	p.direction = Vector3.UP
	p.spread = 12.0
	p.gravity = Vector3(0, 1.5, 0)
	p.initial_velocity_min = 0.6 * taille
	p.initial_velocity_max = 1.4 * taille
	var rampe := Gradient.new()
	rampe.set_color(0, Color(1.0, 0.8, 0.35, 0.95))
	rampe.add_point(0.5, Color(1.0, 0.42, 0.12, 0.7))
	rampe.set_color(1, Color(0.6, 0.12, 0.05, 0.0))
	p.color_ramp = rampe
	var c := Curve.new()
	c.add_point(Vector2(0, 1.0))
	c.add_point(Vector2(1, 0.25))
	p.scale_amount_curve = c
	p.position = pos
	_decor.add_child(p)
	# étincelles
	var e := CPUParticles3D.new()
	e.amount = int(10 * taille) + 4
	e.lifetime = 1.6
	var q2 := QuadMesh.new()
	q2.size = Vector2(0.12, 0.12)
	var m2 := m.duplicate()
	m2.albedo_texture = load("res://assets/vfx/spark_05.png")
	q2.material = m2
	e.mesh = q2
	e.direction = Vector3.UP
	e.spread = 25.0
	e.gravity = Vector3(0.3, 0.8, 0)
	e.initial_velocity_min = 1.5
	e.initial_velocity_max = 3.0
	e.color = Color(1.0, 0.6, 0.25)
	e.position = pos + Vector3(0, 0.3, 0)
	_decor.add_child(e)

# =================== Portail d'Yggdrasil ===================

func _portail() -> void:
	var c := PORTAIL
	var arche := poser(HW + "arch.gltf", c, 0.0, 2.6)
	_boite_collision(c + Vector3(-5.0, 3, 0), Vector3(1.6, 6, 2.0))
	_boite_collision(c + Vector3(5.0, 3, 0), Vector3(1.6, 6, 2.0))
	_boite_collision(c + Vector3(0, 3, -1.5), Vector3(8.4, 6, 1.0))   # on n'entre pas encore : le donjon se charge par l'interaction
	var voile := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(8.6, 10.5)
	voile.mesh = q
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/portail.gdshader")
	voile.material_override = mat
	voile.position = c + Vector3(0, 5.3, 0.1)
	voile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_decor.add_child(voile)
	lumiere(c + Vector3(0, 4.0, 3.5), Color(0.45, 0.8, 1.0), 4.0, 20.0)
	lumiere(c + Vector3(0, 1.0, 6.0), Color(1.0, 0.8, 0.5), 1.0, 8.0)
	# racines géantes qui enserrent l'arche
	for d in [[Vector3(-8.5, 0, 1.0), 25.0, Vector3(0, 0, -28)], [Vector3(8.8, 0, 0.5), 200.0, Vector3(0, 0, 26)],
			[Vector3(-6.0, 0, -4.5), 80.0, Vector3(-18, 0, -12)], [Vector3(6.5, 0, -4.0), 140.0, Vector3(-16, 0, 14)]]:
		var r := poser(F + "Tree_Bare_1_" + ["A", "B", "C"][_rng.randi() % 3] + "_Color1.gltf", c + d[0], d[1], 4.2)
		if r:
			r.rotation_degrees += d[2]
		_cylindre_collision(c + d[0], 1.2, 5.0)
	# particules de givre qui montent du parvis
	var p := CPUParticles3D.new()
	p.amount = 40
	p.lifetime = 3.0
	var qq := QuadMesh.new()
	qq.size = Vector2(0.25, 0.25)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.disable_fog = true   # sinon le brouillard dessine un carré clair autour de l'effet
	m.albedo_texture = load("res://assets/vfx/star_06.png")
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	qq.material = m
	p.mesh = qq
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(5, 0.2, 3)
	p.direction = Vector3.UP
	p.spread = 10.0
	p.gravity = Vector3(0, 0.6, 0)
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 1.2
	p.color = Color(0.6, 0.9, 1.0, 0.8)
	var rampe := Gradient.new()
	rampe.set_color(0, Color(1, 1, 1, 0))
	rampe.add_point(0.3, Color(1, 1, 1, 1))
	rampe.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = rampe
	p.position = c + Vector3(0, 0.2, 4.0)
	_decor.add_child(p)

# =================== chemin, forêt, herbes ===================

func _lanternes_du_chemin() -> void:
	# une lanterne tous les ~22 m, toujours du même côté (nord) : elles guident sans gêner la vue
	var cumul := 0.0
	var prochain := 14.0
	for i in 8:
		var a: Vector2 = CHEMIN[i]
		var b: Vector2 = CHEMIN[i + 1]
		var l := a.distance_to(b)
		while prochain < cumul + l:
			var t := (prochain - cumul) / l
			var q := a.lerp(b, t)
			var n := (b - a).normalized()
			var cote := Vector2(n.y, -n.x)
			if cote.y > 0.0:
				cote = -cote
			var pos := Vector3(q.x + cote.x * 4.2, 0, q.y + cote.y * 4.2)
			poser(HW + "post_lantern.gltf", pos, rad_to_deg(atan2(-cote.x, -cote.y)), 1.0, "tronc")
			lumiere(pos + Vector3(0, 3.0, 0), Color(1.0, 0.76, 0.42), 1.5, 9.0)
			prochain += 22.0
		cumul += l

## Libre pour un arbre ? Rien sur les routes, les villes, le lac ; et jamais juste au sud d'une route
## (la caméra regarde du sud : un arbre là cacherait le héros).
func _libre(p: Vector2, marge := 0.0) -> bool:
	var dc := distance_chemin(p)
	var proj: Vector2 = dc[1]
	var mini := 7.5 if p.y < proj.y else 12.5
	if dc[0] < mini + marge:
		return false
	if PlanMonde.est_interdit(p):
		return false
	var dr := PlanMonde.proj_routes(p)
	if dr[0] < 4.5 + marge or (p.y > dr[1].y and dr[0] < 9.5 + marge):
		return false
	if Rect2(BOURG.position - Vector2(7, 7), BOURG.size + Vector2(14, 14)).has_point(p):
		return false
	if p.distance_to(Vector2(PORTAIL.x, PORTAIL.z + 3)) < 17.0 + marge:
		return false
	return true

## Troncs solides : une forme de collision par arbre, regroupées par case de 64 m (un seul corps par case).
var _corps_cases := {}

func _tronc(p: Vector2, r := 0.6) -> CollisionShape3D:
	var cle := Vector2i(floori(p.x / 64.0), floori(p.y / 64.0))
	if not _corps_cases.has(cle):
		var corps := StaticBody3D.new()
		_colliders.add_child(corps)
		_corps_cases[cle] = corps
	var f := CollisionShape3D.new()
	var cy := CylinderShape3D.new()
	cy.radius = r
	cy.height = 4.0
	f.shape = cy
	f.position = Vector3(p.x, 2.0, p.y)
	_corps_cases[cle].add_child(f)
	obstacles_ronds.append([Vector3(p.x, 0, p.y), r])
	_troncs[Vector2i(roundi(p.x * 10.0), roundi(p.y * 10.0))] = f
	return f

func _foret() -> void:
	var types := ["Tree_1_A", "Tree_1_B", "Tree_2_A", "Tree_2_C", "Tree_3_A", "Tree_3_B", "Tree_4_A", "Tree_4_B"]
	var par_type := {}
	for t in types:
		par_type[t] = []
	var morts := []
	var bruit := FastNoiseLite.new()
	bruit.seed = 1717
	bruit.frequency = 0.011
	var pas := 6.0
	var x := LIMITES.position.x - 40.0
	while x < LIMITES.end.x + 40.0:
		var z := LIMITES.position.y - 40.0
		while z < LIMITES.end.y + 34.0:
			var p := Vector2(x + _rng.randf_range(-2.2, 2.2), z + _rng.randf_range(-2.2, 2.2))
			z += pas
			if not _libre(p):
				continue
			var dedans := LIMITES.has_point(p)
			# prairies et lisières : le monde respire entre les bois
			var n := bruit.get_noise_2d(p.x, p.y)
			if dedans and (n > 0.2 or (n > 0.05 and _rng.randf() < 0.55)):
				continue
			var dc: float = distance_chemin(p)[0]
			if dc < 16.0 and _rng.randf() < 0.35:
				continue
			var ech := _rng.randf_range(1.7, 2.3)
			if dc < 20.0:
				ech = minf(ech, 2.0)
			var xf := Transform3D(Basis(Vector3.UP, _rng.randf_range(0, TAU)).scaled(Vector3.ONE * ech), Vector3(p.x, 0, p.y))
			if _rng.randf() < 0.06:
				morts.append(xf)
			else:
				par_type[types[_rng.randi() % types.size()]].append(xf)
			if dedans:
				_tronc(p)
		x += pas
	for t in types:
		_multimesh(F + t + "_Color1.gltf", par_type[t], true, "arbre")
	_multimesh(F + "Tree_Bare_1_A_Color1.gltf", morts, true, "arbre")

## Rochers moissonnables (carrière) : ils tombent sous les lames et les pioches, puis repoussent.
func zone_rochers(c: Vector3, r: float, n: int) -> void:
	var l := {"Rock_1_A": [], "Rock_1_J": [], "Rock_2_A": []}
	var cles := l.keys()
	for i in n:
		var a := _rng.randf() * TAU
		var d := sqrt(_rng.randf()) * r
		var p := Vector2(c.x, c.z) + Vector2(cos(a), sin(a)) * d
		if p.distance_to(Vector2(c.x + 2, c.z - 12)) < 7.0:
			continue
		var ech := _rng.randf_range(1.8, 2.8)
		l[cles[i % cles.size()]].append(Transform3D(Basis(Vector3.UP, _rng.randf_range(0, TAU)).scaled(Vector3.ONE * ech), Vector3(p.x, 0, p.y)))
		_tronc(p, 0.9)
	for k in l:
		_multimesh(F + k + "_Color1.gltf", l[k], true, "rocher")

func _herbes() -> void:
	var touffes := {"Grass_1_A": [], "Grass_2_B": [], "Grass_1_C": []}
	var buissons := {"Bush_1_A": [], "Bush_2_B": [], "Bush_4_A": [], "Bush_3_A": []}
	var rochers := {"Rock_1_A": [], "Rock_1_J": []}
	var cles_t := touffes.keys()
	var cles_b := buissons.keys()
	var cles_r := rochers.keys()
	for i in 7000:
		var p := Vector2(_rng.randf_range(LIMITES.position.x, LIMITES.end.x), _rng.randf_range(LIMITES.position.y, LIMITES.end.y))
		var dc: float = distance_chemin(p)[0]
		if dc < 3.3:
			continue
		var m := PlanMonde.lire(p)
		if m.r > 0.15 or m.g > 0.1 or m.a > 0.05 or m.b > 0.3:
			continue
		if p.distance_to(Vector2(PORTAIL.x, PORTAIL.z + 4.0)) < 12.0:
			continue
		if TERRES.grow(3.0).has_point(p) or _dist_route(p) < 3.0:
			continue
		var bati := PlanMonde.est_interdit(p)
		var base := Transform3D(Basis(Vector3.UP, _rng.randf_range(0, TAU)), Vector3(p.x, 0, p.y))
		var r := _rng.randf()
		# herbe surtout le long des chemins et dans les villages : c'est là que le joueur regarde
		if r < 0.7 and (dc < 14.0 or bati or _rng.randf() < 0.35):
			touffes[cles_t[_rng.randi() % cles_t.size()]].append(base.scaled_local(Vector3.ONE * _rng.randf_range(1.5, 2.3)))
		elif r < 0.9:
			if dc > 4.5 and not bati:
				buissons[cles_b[_rng.randi() % cles_b.size()]].append(base.scaled_local(Vector3.ONE * _rng.randf_range(3.0, 4.6)))
		elif not bati:
			rochers[cles_r[_rng.randi() % cles_r.size()]].append(base.scaled_local(Vector3.ONE * _rng.randf_range(1.0, 1.8)))
	for k in touffes:
		_multimesh(F + k + "_Color1.gltf", touffes[k], false)
	for k in buissons:
		_multimesh(F + k + "_Color1.gltf", buissons[k], false)
	for k in rochers:
		_multimesh(F + k + "_Color1.gltf", rochers[k], false, "rocher")

# =================== Lac des Brumes ===================

const PONTON := Rect2(-147, -9.7, 21, 3.4)    ## le ponton de Vik avance sur l'eau

func _lac() -> void:
	var c := PlanMonde.LAC_CENTRE
	var rr := PlanMonde.LAC_RAYONS
	var eau := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = rr * 2.6
	eau.mesh = pm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx, cull_disabled;
uniform vec2 centre;
uniform vec2 rayons;
varying vec3 pm;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float b(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), u.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), u.x), u.y); }
void vertex() { pm = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 d = (pm.xz - centre) / rayons;
	float a = atan(d.y, d.x);
	float k = length(d) / (1.0 + 0.08 * sin(a * 3.0 + 0.6) + 0.05 * sin(a * 7.0));
	if (k > 1.04) { discard; }
	float t = TIME * 0.35;
	float vague = b(pm.xz * 0.35 + vec2(t, t * 0.6)) * 0.6 + b(pm.xz * 1.2 - vec2(t * 1.3, t)) * 0.4;
	vec3 profond = vec3(0.07, 0.2, 0.26);
	vec3 clair = vec3(0.22, 0.42, 0.45);
	float rive = smoothstep(0.78, 1.0, k);
	vec3 col = mix(profond, clair, rive * 0.8 + vague * 0.25);
	float ecume = smoothstep(0.94, 1.0, k) * (0.6 + 0.4 * sin(TIME * 1.5 + a * 9.0));
	col = mix(col, vec3(0.85, 0.9, 0.88), ecume * 0.6);
	float reflet = pow(vague, 6.0) * 1.4;
	ALBEDO = col + vec3(reflet) * 0.35;
	ROUGHNESS = 0.08;
	METALLIC = 0.0;
	SPECULAR = 0.7;
	NORMAL_MAP = vec3(0.5 + (vague - 0.5) * 0.25, 0.5 + (b(pm.xz * 0.9 + t) - 0.5) * 0.25, 1.0);
	ALPHA = clamp((1.04 - k) / 0.08, 0.0, 0.92);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("centre", c)
	mat.set_shader_parameter("rayons", rr)
	eau.material_override = mat
	eau.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	eau.position = Vector3(c.x, 0.07, c.y)
	_decor.add_child(eau)
	# on ne marche pas sur l'eau : des boîtes qui remplissent le lac, sauf sous le ponton
	var z := c.y - rr.y * 1.2
	while z < c.y + rr.y * 1.2:
		var xs: Array = []
		var x := c.x - rr.x * 1.2
		while x < c.x + rr.x * 1.2:
			if PlanMonde.dans_lac(Vector2(x, z + 1.0), 1.4):
				xs.append(x)
			x += 1.0
		if not xs.is_empty():
			var bande := Rect2(xs.front(), z, xs.back() - xs.front() + 1.0, 2.0)
			for morceau in _soustraire(bande, PONTON):
				_boite_collision(Vector3(morceau.get_center().x, 1.0, morceau.get_center().y), Vector3(morceau.size.x, 2.0, morceau.size.y))
		z += 2.0
	# roseaux et nénuphars sur les berges
	var plantes := ["waterplant_A", "waterplant_B", "waterplant_C"]
	for i in 70:
		var a := _rng.randf() * TAU
		var k := _rng.randf_range(0.86, 1.02)
		var q := c + Vector2(cos(a) * rr.x, sin(a) * rr.y) * k * (1.0 + 0.08 * sin(a * 3.0 + 0.6) + 0.05 * sin(a * 7.0))
		if PONTON.grow(2.0).has_point(q):
			continue
		poser(H + "decoration/nature/" + plantes[i % 3] + ".gltf", Vector3(q.x, 0.05, q.y), _rng.randf_range(0, 360), _rng.randf_range(3.0, 4.5))
	for i in 22:
		var a2 := _rng.randf() * TAU
		var q2 := c + Vector2(cos(a2) * rr.x, sin(a2) * rr.y) * _rng.randf_range(0.3, 0.8)
		poser(H + "decoration/nature/" + ["waterlily_A", "waterlily_B"][i % 2] + ".gltf", Vector3(q2.x, 0.09, q2.y), _rng.randf_range(0, 360), _rng.randf_range(3.0, 4.0))
	lumiere(Vector3(c.x, 8, c.y), Color(0.6, 0.75, 0.9), 0.8, 40.0)

## Rectangle moins un autre : jusqu'à quatre morceaux.
func _soustraire(r: Rect2, trou: Rect2) -> Array:
	if not r.intersects(trou):
		return [r]
	var res: Array = []
	var i := r.intersection(trou)
	if i.position.y > r.position.y:
		res.append(Rect2(r.position.x, r.position.y, r.size.x, i.position.y - r.position.y))
	if i.end.y < r.end.y:
		res.append(Rect2(r.position.x, i.end.y, r.size.x, r.end.y - i.end.y))
	if i.position.x > r.position.x:
		res.append(Rect2(r.position.x, i.position.y, i.position.x - r.position.x, i.size.y))
	if i.end.x < r.end.x:
		res.append(Rect2(i.end.x, i.position.y, r.end.x - i.end.x, i.size.y))
	return res.filter(func(q): return q.size.x > 0.2 and q.size.y > 0.2)

# =================== montagnes au bout du monde ===================

func _montagnes() -> void:
	var modeles := ["mountain_A_grass_trees", "mountain_B_grass_trees", "mountain_C_grass_trees", "mountain_A_grass", "mountain_B_grass"]
	var r := LIMITES
	var bords := [[Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y), Vector2(0, -1)],
		[Vector2(r.position.x, r.position.y), Vector2(r.position.x, r.end.y), Vector2(-1, 0)],
		[Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.end.y), Vector2(1, 0)]]
	for b in bords:
		var a: Vector2 = b[0]
		var e: Vector2 = b[1]
		var n: Vector2 = b[2]
		var l := a.distance_to(e)
		var t := 0.0
		while t < l + 40.0:
			var p: Vector2 = a.lerp(e, t / l) + n * _rng.randf_range(48.0, 70.0)
			var ech := _rng.randf_range(18.0, 26.0)
			poser(H + "decoration/nature/" + modeles[_rng.randi() % modeles.size()] + ".gltf", Vector3(p.x, -1.0, p.y), _rng.randf_range(0, 360), ech)
			t += _rng.randf_range(26.0, 38.0)
