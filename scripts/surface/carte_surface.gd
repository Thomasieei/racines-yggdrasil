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

const LIMITES := Rect2(0, -20, 172, 150)           ## zone jouable (x, z)
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
## Hameau de Brekka : village de travailleurs au nord-ouest, relié au chemin par un sentier.
const VILLAGE := Rect2(28, -10, 50, 42)
const PLACE_VILLAGE := Vector3(53, 0, 12)
const ROUTE_VILLAGE := [Vector2(66, 64), Vector2(60, 46), Vector2(55, 30)]
## Maisons : [modèle, position, rotation, nom de famille]. Les portes regardent la place.
const MAISONS := [
	["building_home_A_blue", Vector3(40, 0, 2), 35.0, "Brekka"], ["building_home_B_blue", Vector3(66, 0, 2), -35.0, "Hallsdóttir"],
	["building_home_A_blue", Vector3(36, 0, 20), 75.0, "Ulfsson"], ["building_home_B_blue", Vector3(70, 0, 20), -75.0, "Dagny"],
	["building_tavern_blue", Vector3(53, 0, -4), 0.0, "Taverne du Hareng"],
]
## Terres Gâtées : au sud-est du Bourg, une lande morte où la Horde se lève sans fin.
const TERRES := Rect2(134, 76, 34, 48)
const ROUTE_TERRES := [Vector2(127.5, 57), Vector2(129, 66), Vector2(139, 78)]

## Lieux nommés (bandeaux d'entrée de zone, minicarte, guidage)
const LIEUX := [
	{"id": "sanctuaire", "nom": "Sanctuaire de Freya", "centre": Vector3(36, 0, 106), "rayon": 13.0},
	{"id": "clairiere", "nom": "Clairière des Tertres", "centre": Vector3(62, 0, 69), "rayon": 13.0},
	{"id": "bourg", "nom": "Bourg de Skjold", "centre": Vector3(127, 0, 37), "rayon": 27.0, "sur": true},
	{"id": "portail", "nom": "Portail d'Yggdrasil", "centre": Vector3(127, 0, 0), "rayon": 13.0},
	{"id": "village", "nom": "Hameau de Brekka", "centre": Vector3(53, 0, 10), "rayon": 24.0},
	{"id": "terres", "nom": "Terres Gâtées", "centre": Vector3(151, 0, 100), "rayon": 24.0},
	{"id": "bois", "nom": "Bois des Murmures", "centre": Vector3(80, 0, 70), "rayon": 999.0},
]

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

func _ready() -> void:
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
	_sol()
	_bordures()
	_sanctuaire()
	_clairiere()
	_bourg()
	_portail()
	_lanternes_du_chemin()
	_foret()
	_herbes()
	_terres_gatees()
	_village()

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

func _boite_collision(centre: Vector3, taille: Vector3, rot_y := 0.0) -> void:
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

# =================== Hameau de Brekka ===================

func _village() -> void:
	var B := H + "buildings/blue/"
	var N := H + "buildings/neutral/"
	var P := H + "decoration/props/"
	for m in MAISONS:
		poser(B + m[0] + ".gltf", m[1], m[2], 6.2 if m[0].contains("tavern") else 6.4, "boite")
	# moulin, scierie, champs de blé, puits : chacun a son travail
	poser(B + "building_windmill_blue.gltf", Vector3(31, 0, 6), 20.0, 6.0, "boite")
	poser(B + "building_lumbermill_blue.gltf", Vector3(75, 0, 8), -60.0, 6.0, "boite")
	poser(B + "building_well_blue.gltf", PLACE_VILLAGE + Vector3(0, 0, -1.5), 0.0, 4.2, "boite")
	for c in [Vector3(30, 0, 27), Vector3(37, 0, 30), Vector3(30, 0, 34)]:
		poser(N + "building_grain.gltf", c, 0.0, 5.0)
	poser(R + "Wood_Log_Stack.gltf", Vector3(71, 0, 13), 30.0, 1.6, "boite")
	poser(R + "Wood_Log_Stack.gltf", Vector3(73.5, 0, 15), 80.0, 1.4, "boite")
	poser(P + "crate_A_big.gltf", Vector3(57, 0, 2.5), 20.0, 6.0, "boite")
	poser(P + "sack.gltf", Vector3(48.5, 0, 2.0), 0.0, 6.0, "boite")
	poser(P + "wheelbarrow.gltf", Vector3(33.5, 0, 24.0), 40.0, 6.0, "boite")
	poser(N + "building_scaffolding.gltf", Vector3(62, 0, 28), 0.0, 5.5, "boite")
	_feu_de_camp(PLACE_VILLAGE + Vector3(0, 0, 6))
	for a in [0.4, 2.0, 3.6, 5.1]:
		var p := PLACE_VILLAGE + Vector3(0, 0, 6) + Vector3(cos(a), 0, sin(a)) * 3.6
		poser(HW + "bench.gltf", p, rad_to_deg(-a) + 90.0, 0.9, "boite")
	# sentier vers le chemin principal
	for i in ROUTE_VILLAGE.size() - 1:
		var a: Vector2 = ROUTE_VILLAGE[i]
		var b: Vector2 = ROUTE_VILLAGE[i + 1]
		var n := int(a.distance_to(b) / 2.6)
		for k in n + 1:
			var q := a.lerp(b, float(k) / maxf(n, 1))
			poser(HW + "floor_dirt_small.gltf", Vector3(q.x, 0.02, q.y), _rng.randf_range(0, 360), 1.5)
	for p in [PLACE_VILLAGE + Vector3(-7, 0, 9), PLACE_VILLAGE + Vector3(7, 0, 9), Vector3(57, 0, 32)]:
		poser(HW + "post_lantern.gltf", p, 0.0, 1.0, "tronc")
		lumiere(p + Vector3(0, 3.1, 0.6), Color(1.0, 0.78, 0.45), 1.3, 9.0)
	lumiere(PLACE_VILLAGE + Vector3(0, 6, 0), Color(1.0, 0.85, 0.6), 1.2, 24.0)

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
		corps.collision_layer = 0
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
			corps.collision_layer = 1)

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
	for l in LIEUX:
		if Vector2(p.x - l["centre"].x, p.z - l["centre"].z).length() <= l["rayon"]:
			return l
	return {}

# =================== sol et bords ===================

func _sol() -> void:
	var plan := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(LIMITES.size.x + 120, LIMITES.size.y + 120)
	plan.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/sol_surface.gdshader")
	var pts := PackedVector2Array()
	for p in CHEMIN:
		pts.append(p)
	mat.set_shader_parameter("chemin", pts)
	mat.set_shader_parameter("nb_points", pts.size())
	mat.set_shader_parameter("place", Vector4(PLACE.x, PLACE.z, 15.0, 0))
	mat.set_shader_parameter("sanctuaire", Vector4(SANCTUAIRE.x, SANCTUAIRE.z, 8.5, 0))
	mat.set_shader_parameter("parvis_portail", Vector4(PORTAIL.x, PORTAIL.z + 4.0, 10.0, 0))
	mat.set_shader_parameter("bourg", Vector4(BOURG.position.x, BOURG.position.y, BOURG.end.x, BOURG.end.y))
	plan.material_override = mat
	plan.position = Vector3(LIMITES.get_center().x, 0, LIMITES.get_center().y)
	add_child(plan)
	_boite_collision(Vector3(LIMITES.get_center().x, -0.5, LIMITES.get_center().y), Vector3(LIMITES.size.x + 120, 1, LIMITES.size.y + 120))

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
			poser(H + "buildings/neutral/fence_wood_straight.gltf", abs_t, rot, 5.0)
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

## Libre pour un arbre ? Couloir du chemin dégagé, rien au sud du chemin à moins de 12 m (la caméra regarde du sud).
func _libre(p: Vector2, marge := 0.0) -> bool:
	var dc := distance_chemin(p)
	var proj: Vector2 = dc[1]
	var mini := 7.5 if p.y < proj.y else 12.5
	if dc[0] < mini + marge:
		return false
	if Rect2(BOURG.position - Vector2(7, 7), BOURG.size + Vector2(14, 14)).has_point(p):
		return false
	if TERRES.grow(5.0 + marge).has_point(p) or _dist_route(p) < 5.0 + marge:
		return false
	if VILLAGE.grow(4.0 + marge).has_point(p) or _dist_ligne(p, ROUTE_VILLAGE) < 5.0 + marge:
		return false
	for z in [[SANCTUAIRE, 13.0], [CLAIRIERE, 14.0], [PORTAIL + Vector3(0, 0, 3), 17.0]]:
		if p.distance_to(Vector2(z[0].x, z[0].z)) < z[1] + marge:
			return false
	return true

func _foret() -> void:
	var types := ["Tree_1_A", "Tree_1_B", "Tree_2_A", "Tree_2_C", "Tree_3_A", "Tree_3_B", "Tree_4_A", "Tree_4_B"]
	var par_type := {}
	for t in types:
		par_type[t] = []
	var morts := []
	var pas := 6.2
	var x := LIMITES.position.x - 30.0
	while x < LIMITES.end.x + 40.0:
		var z := LIMITES.position.y - 34.0
		while z < LIMITES.end.y + 30.0:
			var p := Vector2(x + _rng.randf_range(-2.2, 2.2), z + _rng.randf_range(-2.2, 2.2))
			z += pas
			if not _libre(p):
				continue
			# clairsemé au bord du couloir, dense au loin
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
			# troncs solides seulement là où l'on peut marcher
			if LIMITES.has_point(p) and dc < 30.0:
				_troncs[Vector2i(roundi(p.x * 10.0), roundi(p.y * 10.0))] = _cylindre_collision(Vector3(p.x, 0, p.y), 0.6, 4.0)
		x += pas
	for t in types:
		_multimesh(F + t + "_Color1.gltf", par_type[t], true, "arbre")
	_multimesh(F + "Tree_Bare_1_A_Color1.gltf", morts, true, "arbre")

func _herbes() -> void:
	var touffes := {"Grass_1_A": [], "Grass_2_B": [], "Grass_1_C": []}
	var buissons := {"Bush_1_A": [], "Bush_2_B": [], "Bush_4_A": [], "Bush_3_A": []}
	var rochers := {"Rock_1_A": [], "Rock_1_J": []}
	var cles_t := touffes.keys()
	var cles_b := buissons.keys()
	var cles_r := rochers.keys()
	for i in 1500:
		var p := Vector2(_rng.randf_range(LIMITES.position.x, LIMITES.end.x), _rng.randf_range(LIMITES.position.y, LIMITES.end.y))
		var dc: float = distance_chemin(p)[0]
		if dc < 3.3:
			continue
		if BOURG.grow(-2).has_point(p) and p.distance_to(Vector2(PLACE.x, PLACE.z)) < 17.0:
			continue
		if p.distance_to(Vector2(PORTAIL.x, PORTAIL.z + 4.0)) < 12.0:
			continue
		if TERRES.grow(3.0).has_point(p) or _dist_route(p) < 3.0:
			continue
		if _dist_ligne(p, ROUTE_VILLAGE) < 3.0 or (VILLAGE.has_point(p) and p.distance_to(Vector2(PLACE_VILLAGE.x, PLACE_VILLAGE.z)) < 12.0):
			continue
		var base := Transform3D(Basis(Vector3.UP, _rng.randf_range(0, TAU)), Vector3(p.x, 0, p.y))
		var r := _rng.randf()
		# herbe surtout le long du chemin : c'est là que le joueur regarde
		if r < 0.7 and (dc < 14.0 or _rng.randf() < 0.3):
			touffes[cles_t[_rng.randi() % cles_t.size()]].append(base.scaled_local(Vector3.ONE * _rng.randf_range(1.5, 2.3)))
		elif r < 0.9:
			if dc > 4.5:
				buissons[cles_b[_rng.randi() % cles_b.size()]].append(base.scaled_local(Vector3.ONE * _rng.randf_range(3.0, 4.6)))
		else:
			rochers[cles_r[_rng.randi() % cles_r.size()]].append(base.scaled_local(Vector3.ONE * _rng.randf_range(1.0, 1.8)))
	for k in touffes:
		_multimesh(F + k + "_Color1.gltf", touffes[k], false)
	for k in buissons:
		_multimesh(F + k + "_Color1.gltf", buissons[k], false)
	for k in rochers:
		_multimesh(F + k + "_Color1.gltf", rochers[k], false, "rocher")
