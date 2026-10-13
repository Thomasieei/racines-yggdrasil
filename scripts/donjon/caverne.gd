class_name Caverne
extends Node3D
## Étage 1 du donjon du jour : la crypte des nains (salle d'arrivée), puis un tunnel naturel
## qui débouche sur la Grande Caverne — un espace immense et sombre, découpé en zones lisibles :
## entrée, nid des rampants, autel du nécromant, gouffre, campement draugr, antre du Jarl,
## camp des Égarés (zone sûre) et la descente vers l'étage 2.
##
## Repère : x vers l'est, z vers le sud ; la crypte occupe x 0..28, z 0..28 ; la caverne s'étend au nord (z < 0).

const F := "res://assets/surface/foret/"
const DJ := "res://assets/donjon/"
const HW := "res://assets/halloween/"
const H := "res://assets/surface/hexa/"
const R := "res://assets/surface/ressources/"

## Contour de tout l'espace marchable (tunnel + caverne + alcôves), sens trigonométrique.
## La dernière arête (fermeture) passe sous l'arche de la crypte : pas de mur à cet endroit.
const CONTOUR := [
	Vector2(11.8, 0.6), Vector2(10.5, -6), Vector2(8, -12), Vector2(5, -18), Vector2(3.5, -24), Vector2(-6, -29), Vector2(-18, -33), Vector2(-30, -40),
	Vector2(-37, -52), Vector2(-50, -54), Vector2(-62, -50), Vector2(-70, -38), Vector2(-72, -24), Vector2(-66, -10), Vector2(-60, 2), Vector2(-66, 16),
	Vector2(-82, 24), Vector2(-100, 20), Vector2(-112, 6), Vector2(-110, -10), Vector2(-98, -20), Vector2(-86, -24), Vector2(-86, -30), Vector2(-104, -34),
	Vector2(-116, -46), Vector2(-120, -62), Vector2(-112, -80), Vector2(-96, -90), Vector2(-78, -86), Vector2(-66, -72), Vector2(-52, -66), Vector2(-39, -64),
	Vector2(-34, -77), Vector2(-22, -88), Vector2(-6, -95), Vector2(12, -96), Vector2(15, -106), Vector2(23, -106), Vector2(25, -96), Vector2(40, -92),
	Vector2(42, -104), Vector2(40, -116), Vector2(34, -124), Vector2(32, -140), Vector2(42, -154), Vector2(60, -160), Vector2(78, -150), Vector2(84, -134),
	Vector2(76, -118), Vector2(62, -112), Vector2(54, -102), Vector2(52, -90), Vector2(52, -84), Vector2(60, -74), Vector2(64, -66), Vector2(70, -72),
	Vector2(80, -68), Vector2(84, -58), Vector2(78, -48), Vector2(68, -50), Vector2(64, -56), Vector2(60, -46), Vector2(55, -31), Vector2(45, -27),
	Vector2(43, -20), Vector2(40, -10), Vector2(31, -7), Vector2(26, -12), Vector2(25, -20), Vector2(19, -24), Vector2(13.5, -22), Vector2(14, -16),
	Vector2(16, -10), Vector2(16.2, -4), Vector2(16.2, 0.6),
]

const GOUFFRE := Vector3(2, 0, -58)
const GOUFFRE_R := Vector2(10, 7)
const CAMP := Vector3(34, 0, -16)
const ANTRE := Vector3(74, 0, -59)
const DESCENTE := Vector3(19, 0, -103)
const CAMPEMENT := Vector3(20, 0, -78)
const AUTEL := Vector3(-27, 0, -72)
const NID := Vector3(-24, 0, -46)
## Ailes ajoutées pour accueillir une vingtaine de joueurs : chacune a son identité, ses camps, son élite ou son trésor.
const OSSUAIRE := Vector3(-94, 0, -60)        ## aile ouest : tombes royales, lumière verte
const TRONE_REINE := Vector3(-108, 0, -62)
const PUITS := Vector3(-76, 0, -46)           ## second camp sûr et second point d'arrivée
const LAC := Vector3(-88, 0, 3)               ## aile sud-ouest : lac noir
const LAC_R := Vector2(13, 8)
const FORGES := Vector3(58, 0, -134)          ## aile nord-est : forges naines englouties, lave
const ENCLUME_BROKK := Vector3(60, 0, -150)
const ARRIVEES := [Vector3(14, 0, 14), Vector3(-76, 0, -46)]

const LIEUX := [
	{"id": "crypte", "nom": "Crypte des nains", "centre": Vector3(14, 0, 14), "rect": Rect2(0, 0, 28, 28)},
	{"id": "camp", "nom": "Camp des Égarés", "centre": Vector3(34, 0, -16), "rayon": 10.0, "sur": true},
	{"id": "puits", "nom": "Camp du Puits", "centre": Vector3(-76, 0, -46), "rayon": 10.0, "sur": true},
	{"id": "tunnel", "nom": "Boyau des Murmures", "centre": Vector3(10, 0, -12), "rayon": 10.0},
	{"id": "antre", "nom": "Antre du Jarl", "centre": Vector3(74, 0, -59), "rayon": 11.0},
	{"id": "trone", "nom": "Trône de la Reine pâle", "centre": Vector3(-106, 0, -62), "rayon": 12.0},
	{"id": "enclume", "nom": "Enclume de Brokk", "centre": Vector3(60, 0, -148), "rayon": 12.0},
	{"id": "descente", "nom": "La Descente", "centre": Vector3(19, 0, -101), "rayon": 8.0},
	{"id": "nid", "nom": "Nid des rampants", "centre": Vector3(-24, 0, -46), "rayon": 12.0},
	{"id": "autel", "nom": "Autel du nécromant", "centre": Vector3(-27, 0, -72), "rayon": 11.0},
	{"id": "campement", "nom": "Campement draugr", "centre": Vector3(20, 0, -78), "rayon": 12.0},
	{"id": "gouffre", "nom": "Le Gouffre sans fond", "centre": Vector3(2, 0, -58), "rayon": 14.0},
	{"id": "lac", "nom": "Lac des Noyés", "centre": Vector3(-88, 0, 2), "rayon": 26.0},
	{"id": "ossuaire", "nom": "Ossuaire des Rois", "centre": Vector3(-94, 0, -60), "rayon": 30.0},
	{"id": "forges", "nom": "Forges englouties", "centre": Vector3(58, 0, -134), "rayon": 28.0},
	{"id": "caverne", "nom": "Grande Caverne", "centre": Vector3(14, 0, -60), "rayon": 999.0},
]

## Taille réelle (largeur, hauteur) de chaque rocher du pack Forest : les variantes vont de 0,2 m à 5 m,
## on pose donc par taille voulue, jamais par facteur d'échelle aveugle.
const ROCHERS := {
	"Rock_1_D": Vector2(1.05, 1.13), "Rock_1_G": Vector2(1.7, 1.87), "Rock_1_J": Vector2(3.5, 3.36), "Rock_1_K": Vector2(3.4, 3.65),
	"Rock_1_L": Vector2(3.0, 3.4), "Rock_1_N": Vector2(2.27, 4.5), "Rock_1_O": Vector2(2.11, 4.58),
	"Rock_3_E": Vector2(1.17, 1.29), "Rock_3_G": Vector2(1.8, 2.0), "Rock_3_I": Vector2(1.8, 2.11), "Rock_3_K": Vector2(2.6, 2.22),
	"Rock_3_M": Vector2(3.1, 3.6), "Rock_3_N": Vector2(3.2, 3.53), "Rock_3_Q": Vector2(4.55, 3.72), "Rock_3_R": Vector2(4.7, 3.85),
	"Rock_2_A": Vector2(0.22, 0.22),
}
const MASSIFS := ["Rock_1_J", "Rock_1_K", "Rock_1_L", "Rock_3_M", "Rock_3_N", "Rock_3_Q", "Rock_3_R"]
const MOYENS := ["Rock_1_G", "Rock_3_G", "Rock_3_I", "Rock_3_K", "Rock_1_D", "Rock_3_E"]
const AIGUILLES := ["Rock_1_N", "Rock_1_O", "Rock_3_I", "Rock_3_G"]

const TEINTE_ROCHE := Color(0.42, 0.4, 0.43)
const TEINTE_ROCHE_SOMBRE := Color(0.26, 0.25, 0.29)

var _rng := RandomNumberGenerator.new()
var _cache := {}
var _decor: Node3D
var _colliders: Node3D
var _poly := PackedVector2Array()

func _ready() -> void:
	_rng.seed = 90210
	_decor = Node3D.new()
	add_child(_decor)
	_colliders = Node3D.new()
	add_child(_colliders)
	for p in CONTOUR:
		_poly.append(p)
	var crypte := Node3D.new()
	crypte.set_script(load("res://scripts/salle_entree.gd"))
	add_child(crypte)
	ZoneSure.vider()
	ZoneSure.ajouter("Camp des Égarés", CAMP, 9.0)
	ZoneSure.ajouter("Camp du Puits", PUITS, 9.0)
	_sol()
	_parois()
	_gouffre()
	_stalagmites()
	_cristaux()
	_tunnel()
	_camp_des_egares()
	_campement()
	_autel()
	_nid()
	_antre()
	_descente()
	_ossuaire()
	_camp_du_puits()
	_lac()
	_forges()
	_arrivees()
	_tresors()
	_vider_rochers()

# =================== briques ===================

func _scene(chemin: String) -> PackedScene:
	if not _cache.has(chemin):
		_cache[chemin] = load(chemin)
	return _cache[chemin]

func poser(chemin: String, pos: Vector3, rot_deg := 0.0, echelle = 1.0, teinte := Color(0, 0, 0, 0)) -> Node3D:
	var n: Node3D = _scene(chemin).instantiate()
	n.position = pos
	n.rotation_degrees.y = rot_deg
	n.scale = echelle if echelle is Vector3 else Vector3.ONE * float(echelle)
	_decor.add_child(n)
	if teinte.a > 0.0:
		for m in n.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			for k in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(k)
				if mat is StandardMaterial3D:
					var m2: StandardMaterial3D = mat.duplicate()
					m2.albedo_color = teinte
					mi.set_surface_override_material(k, m2)
	return n

## Pose un rocher à la taille voulue (largeur au sol, hauteur), quelle que soit la variante.
## Les rochers sont regroupés par modèle et teinte puis dessinés en instances multiples (MultiMesh) :
## des centaines de rochers pour le prix de quelques appels de dessin — indispensable sur téléphone.
var _lots := {}

func rocher(nom: String, pos: Vector3, largeur: float, hauteur: float, teinte := TEINTE_ROCHE) -> void:
	var t: Vector2 = ROCHERS[nom]
	# lots découpés aussi par zone de 32 m : chaque lot ne reçoit que les lumières proches (limite par objet)
	var cle := nom + "|" + teinte.to_html() + "|" + str(floori(pos.x / 32.0)) + "," + str(floori(pos.z / 32.0))
	if not _lots.has(cle):
		_lots[cle] = {"nom": nom, "teinte": teinte, "xf": []}
	var b := Basis(Vector3.UP, _rng.randf_range(0, TAU)).scaled(Vector3(largeur / t.x, hauteur / t.y, largeur / t.x))
	_lots[cle]["xf"].append(Transform3D(b, pos))

func _vider_rochers() -> void:
	for cle in _lots:
		var lot: Dictionary = _lots[cle]
		var n: Node3D = _scene(F + lot["nom"] + "_Color1.gltf").instantiate()
		var mis := n.find_children("*", "MeshInstance3D", true, false)
		if mis.is_empty():
			n.free()
			continue
		var mi: MeshInstance3D = mis[0]
		var local := Transform3D()
		var x: Node = mi
		while x != n and x is Node3D:
			local = (x as Node3D).transform * local
			x = x.get_parent()
		var mesh: Mesh = mi.mesh.duplicate()
		for k in mesh.get_surface_count():
			var mat := mi.get_active_material(k)
			if mat is StandardMaterial3D:
				var m2: StandardMaterial3D = mat.duplicate()
				m2.albedo_color = lot["teinte"]
				mesh.surface_set_material(k, m2)
		n.free()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		var xfs: Array = lot["xf"]
		mm.instance_count = xfs.size()
		for i in xfs.size():
			mm.set_instance_transform(i, xfs[i] * local)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		_decor.add_child(mmi)
	_lots.clear()

func boite(centre: Vector3, taille: Vector3, rot_y := 0.0) -> void:
	var corps := StaticBody3D.new()
	var f := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = taille
	f.shape = b
	corps.add_child(f)
	_colliders.add_child(corps)
	corps.position = centre
	corps.rotation.y = rot_y

func cylindre(pos: Vector3, rayon: float, hauteur := 4.0) -> void:
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

func lumiere(pos: Vector3, couleur: Color, energie: float, portee: float, vacille := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = couleur
	l.light_energy = energie
	l.omni_range = portee
	l.omni_attenuation = 1.6
	l.position = pos
	if vacille:
		l.set_script(load("res://scripts/surface/flamme.gd"))
	_decor.add_child(l)
	return l

func dedans(p: Vector2, marge := 0.0) -> bool:
	if not Geometry2D.is_point_in_polygon(p, _poly):
		return false
	if marge <= 0.0:
		return true
	for i in _poly.size():
		var a := _poly[i]
		var b := _poly[(i + 1) % _poly.size()]
		if Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) < marge:
			return false
	return true

static func lieu_de(p: Vector3) -> Dictionary:
	for l in LIEUX:
		if l.has("rect"):
			if (l["rect"] as Rect2).has_point(Vector2(p.x, p.z)):
				return l
		elif Vector2(p.x - l["centre"].x, p.z - l["centre"].z).length() <= l["rayon"]:
			return l
	return {}

# =================== sol et parois ===================

## Sol en tuiles de 2 m regroupées par blocs de 16 m : chaque bloc reçoit ses propres lumières
## (le moteur limite le nombre de lumières par objet), les bords dentelés disparaissent sous les rochers.
func _sol() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/sol_caverne.gdshader")
	mat.set_shader_parameter("gouffre_centre", Vector2(GOUFFRE.x, GOUFFRE.z))
	mat.set_shader_parameter("gouffre_rayons", GOUFFRE_R)
	var r := Rect2(_poly[0], Vector2.ZERO)
	for p in _poly:
		r = r.expand(p)
	var blocs := {}
	var pas := 2.0
	var x := floorf(r.position.x / pas) * pas
	while x < r.end.x:
		var z := floorf(r.position.y / pas) * pas
		while z < r.end.y:
			var c := Vector2(x + pas / 2, z + pas / 2)
			if Geometry2D.is_point_in_polygon(c, _poly):
				var cle := Vector2i(floori(x / 16.0), floori(z / 16.0))
				if not blocs.has(cle):
					blocs[cle] = []
				blocs[cle].append(Vector2(x, z))
			z += pas
		x += pas
	for cle in blocs:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_normal(Vector3.UP)
		for o in blocs[cle]:
			var a := Vector3(o.x, -0.02, o.y)
			var b := a + Vector3(pas, 0, 0)
			var c2 := a + Vector3(pas, 0, pas)
			var d := a + Vector3(0, 0, pas)
			for v in [a, b, c2, a, c2, d]:
				st.set_normal(Vector3.UP)
				st.add_vertex(v)
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = mat
		# boîte englobante avec un peu d'épaisseur : un sol parfaitement plat échappe au tri des lumières
		var aabb := mi.mesh.get_aabb()
		mi.custom_aabb = AABB(aabb.position - Vector3(0, 1, 0), aabb.size + Vector3(0, 2, 0))
		add_child(mi)
	boite(Vector3(r.get_center().x, -0.5, r.get_center().y), Vector3(r.size.x + 20, 1, r.size.y + 20))

## Parois : rochers sombres posés serrés le long du contour, une deuxième rangée plus massive derrière.
## Collisions : un mur droit par arête, la face intérieure exactement sur le contour.
func _parois() -> void:
	var n := _poly.size()
	for i in n:
		var a := _poly[i]
		var b := _poly[(i + 1) % n]
		var ab := b - a
		var l := ab.length()
		var dir := ab / l
		var ext := Vector2(dir.y, -dir.x)        # extérieur (contour dans le sens trigonométrique, z vers le bas)
		if i == n - 1:
			continue                              # arête de l'arche : passage vers la crypte
		var centre := (a + b) / 2.0 + ext * 0.6
		boite(Vector3(centre.x, 3, centre.y), Vector3(l + 0.6, 6, 1.2), -atan2(ab.y, ab.x))
		# côté caméra (paroi dont l'extérieur est au sud) : rochers bas, pour ne jamais cacher le héros
		var cote_camera := ext.y > 0.35
		var t := 0.0
		while t < l:
			var p := a + dir * t
			var la := _rng.randf_range(3.2, 5.0)
			var ha := _rng.randf_range(1.4, 2.4) if cote_camera else _rng.randf_range(3.0, 6.0)
			var nom: String = MOYENS[_rng.randi() % MOYENS.size()] if cote_camera else MASSIFS[_rng.randi() % MASSIFS.size()]
			rocher(nom, Vector3(p.x, -0.3, p.y) + Vector3(ext.x, 0, ext.y) * 1.3, la, ha)
			# rangée arrière : la masse de la montagne (jamais côté caméra)
			if not cote_camera and _rng.randf() < 0.8:
				var p2 := p + ext * _rng.randf_range(4.5, 6.5)
				rocher(MASSIFS[_rng.randi() % MASSIFS.size()], Vector3(p2.x, -0.4, p2.y), _rng.randf_range(6.0, 9.0), _rng.randf_range(6.0, 10.0), TEINTE_ROCHE_SOMBRE)
			t += _rng.randf_range(2.4, 3.4)

# =================== décor naturel ===================

func _gouffre() -> void:
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = GOUFFRE_R * 2.0
	m.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/gouffre.gdshader")
	m.material_override = mat
	m.position = GOUFFRE + Vector3(0, 0.01, 0)
	add_child(m)
	# on ne tombe pas : une ceinture de collisions suit l'ellipse
	for i in 24:
		var a := TAU * i / 24.0
		var p := GOUFFRE + Vector3(cos(a) * GOUFFRE_R.x, 0, sin(a) * GOUFFRE_R.y) * 0.95
		cylindre(p, 1.6, 3.0)
		if i % 3 == 0:
			rocher(MOYENS[i % MOYENS.size()], Vector3(p.x, -0.2, p.z), _rng.randf_range(1.2, 2.0), _rng.randf_range(0.8, 1.4), TEINTE_ROCHE_SOMBRE)
	# brume froide qui remonte du vide
	var pa := CPUParticles3D.new()
	pa.amount = 30
	pa.lifetime = 5.0
	var q := QuadMesh.new()
	q.size = Vector2(4, 4)
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.albedo_texture = load("res://assets/vfx/smoke_07.png")
	mm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mm.vertex_color_use_as_albedo = true
	mm.disable_fog = true
	mm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	q.material = mm
	pa.mesh = q
	pa.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	pa.emission_box_extents = Vector3(GOUFFRE_R.x * 0.6, 0.1, GOUFFRE_R.y * 0.6)
	pa.direction = Vector3.UP
	pa.gravity = Vector3(0, 0.3, 0)
	pa.initial_velocity_min = 0.2
	pa.initial_velocity_max = 0.6
	pa.color = Color(0.45, 0.65, 1.0, 0.18)
	var rampe := Gradient.new()
	rampe.set_color(0, Color(1, 1, 1, 0))
	rampe.add_point(0.4, Color(1, 1, 1, 1))
	rampe.set_color(1, Color(1, 1, 1, 0))
	pa.color_ramp = rampe
	pa.position = GOUFFRE
	_decor.add_child(pa)
	lumiere(GOUFFRE + Vector3(0, 1.0, 0), Color(0.3, 0.55, 1.0), 1.4, 16.0)

func _stalagmites() -> void:
	# groupes de colonnes de roche : ils cassent les lignes de vue et donnent des abris pendant les combats
	var groupes := [Vector2(-12, -42), Vector2(42, -70), Vector2(-20, -62), Vector2(6, -84), Vector2(-4, -36), Vector2(48, -40), Vector2(-30, -82),
			Vector2(-84, -72), Vector2(-100, -44), Vector2(-80, -36), Vector2(-70, 6), Vector2(-104, 10), Vector2(44, -128), Vector2(70, -124), Vector2(48, -146)]
	for g in groupes:
		for k in _rng.randi_range(2, 4):
			var p: Vector2 = g + Vector2(_rng.randf_range(-3.5, 3.5), _rng.randf_range(-3.5, 3.5))
			if not dedans(p, 3.0):
				continue
			var e := _rng.randf_range(1.4, 2.2)
			rocher(AIGUILLES[_rng.randi() % AIGUILLES.size()], Vector3(p.x, 0.0, p.y), e, _rng.randf_range(3.5, 6.0))
			cylindre(Vector3(p.x, 0, p.y), e * 0.42)
	# éboulis au sol, partout, peu denses
	for i in 320:
		var p := Vector2(_rng.randf_range(-120, 85), _rng.randf_range(-160, 24))
		if not dedans(p, 1.5):
			continue
		rocher("Rock_2_A", Vector3(p.x, 0, p.y), _rng.randf_range(0.3, 0.9), _rng.randf_range(0.3, 0.9))

## Cristaux : prismes lumineux faits ici (aucun pack n'en fournit dans le style). Ils sont les vraies
## sources de lumière de la caverne : on lit l'espace grâce à eux.
func _cristal(p: Vector3, couleur: Color, taille := 1.0) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = couleur.darkened(0.3)
	mat.emission_enabled = true
	mat.emission = couleur
	mat.emission_energy_multiplier = 1.6
	mat.roughness = 0.25
	mat.metallic_specular = 0.9
	for k in _rng.randi_range(3, 5):
		var m := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = _rng.randf_range(0.22, 0.4) * taille
		c.height = _rng.randf_range(1.2, 2.6) * taille
		c.radial_segments = 5
		c.rings = 1
		m.mesh = c
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var o := Vector3(_rng.randf_range(-0.6, 0.6), 0, _rng.randf_range(-0.6, 0.6)) * taille
		m.position = p + o + Vector3(0, c.height * 0.4, 0)
		m.rotation = Vector3(_rng.randf_range(-0.45, 0.45), _rng.randf_range(0, TAU), _rng.randf_range(-0.45, 0.45))
		_decor.add_child(m)
	lumiere(p + Vector3(0, 1.6, 0), couleur, 1.5 * taille, 9.0 * taille)

func _cristaux() -> void:
	var bleu := Color(0.35, 0.7, 1.0)
	for d in [[Vector2(2, -30), 1.0], [Vector2(-14, -36), 0.9], [Vector2(-36, -58), 1.2], [Vector2(-12, -58), 0.8], [Vector2(16, -56), 0.9],
			[Vector2(-10, -90), 1.1], [Vector2(36, -88), 1.0], [Vector2(56, -76), 0.9], [Vector2(50, -34), 0.8], [Vector2(30, -62), 1.0], [Vector2(-28, -38), 0.9]]:
		var p: Vector2 = d[0]
		if dedans(p, 1.0):
			_cristal(Vector3(p.x, 0, p.y), bleu, d[1])
	cylindre(Vector3(2, 0, -30), 0.8)

func _tunnel() -> void:
	# torches plantées par les premiers explorateurs : la seule chaleur avant la caverne
	for p in [Vector3(9.5, 0, -5), Vector3(14.6, 0, -13), Vector3(6.0, 0, -19)]:
		poser(DJ + "torch_lit.glb", p, 0.0, 1.4)
		lumiere(p + Vector3(0, 2.2, 0), Color(1.0, 0.6, 0.3), 1.6, 8.0, true)
		cylindre(p, 0.3, 2.0)
	poser(DJ + "rubble_half.glb", Vector3(7.5, 0, -9), 30.0, 1.0)
	poser(HW + "skull.gltf", Vector3(12.5, 0, -18), 50.0, 1.2)

# =================== zones ===================

func _feu(pos: Vector3, taille: float) -> void:
	var p := CPUParticles3D.new()
	p.amount = int(24 * taille) + 8
	p.lifetime = 0.9
	var q := QuadMesh.new()
	q.size = Vector2(1.1, 1.1) * taille
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.disable_fog = true
	m.albedo_texture = load("res://assets/vfx/flame_03.png")
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	q.material = m
	p.mesh = q
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.3 * taille
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
	p.position = pos
	_decor.add_child(p)

func _camp_des_egares() -> void:
	var c := CAMP
	# un îlot de chaleur : feu, tente, sacs, un garde. Le joueur comprend avant de lire : ici on souffle.
	for i in 10:
		var a := TAU * i / 10.0
		poser(F + "Rock_2_A_Color1.gltf", c + Vector3(cos(a), 0, sin(a)) * 1.0, rad_to_deg(a) * 3.0, 2.2)
	for d in [[0.0, Vector3(0, 0.12, 0)], [70.0, Vector3(0.05, 0.3, 0)], [135.0, Vector3(-0.05, 0.2, 0.05)]]:
		var b := poser(R + "Wood_Log_A.gltf", c + d[1], d[0], 1.1)
		b.rotation_degrees.z = 12.0
	_feu(c + Vector3(0, 0.35, 0), 1.2)
	lumiere(c + Vector3(0, 2.3, 0), Color(1.0, 0.58, 0.25), 3.2, 15.0, true)
	cylindre(c, 1.2, 1.0)
	var tente := poser(H + "decoration/props/tent.gltf", c + Vector3(-5.5, 0, 3.5), 140.0, 7.0)
	boite(c + Vector3(-5.5, 1.5, 3.5), Vector3(3.2, 3, 3.2), deg_to_rad(140))
	poser(R + "Wood_Log_Stack.gltf", c + Vector3(5.0, 0, -3.0), 20.0, 1.2)
	boite(c + Vector3(5.0, 0.6, -3.0), Vector3(2.2, 1.2, 1.4), deg_to_rad(20))
	poser(HW + "bench.gltf", c + Vector3(2.8, 0, 2.6), 40.0, 0.95)
	poser(HW + "bench.gltf", c + Vector3(-2.6, 0, -2.6), -130.0, 0.95)
	poser(H + "decoration/props/sack.gltf", c + Vector3(4.2, 0, 4.0), 0.0, 6.0)
	poser(H + "decoration/props/crate_A_big.gltf", c + Vector3(6.0, 0, 2.0), 25.0, 6.0)
	boite(c + Vector3(6.0, 0.6, 2.0), Vector3(1.2, 1.2, 1.2), deg_to_rad(25))
	# anneau doré au sol : la limite de la zone sûre, visible et nette
	var anneau := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(19, 19)
	anneau.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/anneau_sol.gdshader")
	mat.set_shader_parameter("couleur", Color(1.0, 0.78, 0.4))
	mat.set_shader_parameter("rayon", 0.95)
	mat.set_shader_parameter("alpha", 0.35)
	anneau.material_override = mat
	anneau.position = c + Vector3(0, 0.05, 0)
	_decor.add_child(anneau)

func _campement() -> void:
	var c := CAMPEMENT
	# braseros, barricades, butin entassé : un vrai point de danger lisible de loin
	for p in [c + Vector3(-5, 0, 3), c + Vector3(5, 0, 2)]:
		poser(DJ + "barrel_large.glb", p, 0.0, 1.0)
		_feu(p + Vector3(0, 1.8, 0), 0.8)
		lumiere(p + Vector3(0, 2.8, 0), Color(1.0, 0.5, 0.22), 2.4, 12.0, true)
		cylindre(p, 0.9, 2.0)
	poser(DJ + "barrier.glb", c + Vector3(-7, 0, -4), 30.0, 1.0)
	poser(DJ + "barrier_half.glb", c + Vector3(7, 0, -5), -20.0, 1.0)
	boite(c + Vector3(-7, 1, -4), Vector3(4, 2, 0.6), deg_to_rad(30))
	poser(DJ + "crates_stacked.glb", c + Vector3(3, 0, -6), 15.0, 1.0)
	boite(c + Vector3(3, 1, -6), Vector3(2.1, 2.1, 2.2), deg_to_rad(15))
	poser(DJ + "banner_patternC_red.glb", c + Vector3(0, 0, -7.5), 0.0, 1.2)
	poser(DJ + "sword_shield_broken.glb", c + Vector3(-2, 0, 4), 70.0, 1.0)
	Coffre.creer(self, c + Vector3(-1.5, 0, -6.0), "rare", 0.0)

func _autel() -> void:
	var c := AUTEL
	# lumière verte malade, bougies et crânes : on sait que ça incante ici
	poser(HW + "shrine_candles.gltf", c + Vector3(0, 0, -3), 20.0, 1.6)
	cylindre(c + Vector3(0, 0, -3), 1.2, 2.0)
	for p in [Vector3(-2.5, 0, -1.5), Vector3(2.5, 0, -1.8), Vector3(0, 0, 2.5)]:
		poser(HW + "skull_candle.gltf", c + p, _rng.randf_range(0, 360), 0.8)
	poser(HW + "ribcage.gltf", c + Vector3(3.5, 0, 2.5), 30.0, 1.3)
	poser(HW + "bone_A.gltf", c + Vector3(-3.0, 0, 3.0), 70.0, 1.3)
	lumiere(c + Vector3(0, 2.0, -1), Color(0.35, 1.0, 0.5), 2.2, 12.0, true)
	_cristal(c + Vector3(-6, 0, -5), Color(0.4, 1.0, 0.55), 1.0)

func _nid() -> void:
	var c := NID
	# ossements partout, terre retournée : les rampants dorment sous le sol
	for i in 12:
		var p := c + Vector3(_rng.randf_range(-8, 8), 0, _rng.randf_range(-7, 7))
		poser(HW + ["bone_A", "bone_B", "bone_C", "skull"][i % 4] + ".gltf", p, _rng.randf_range(0, 360), 1.2)
	for p in [Vector3(-4, 0, 2), Vector3(3, 0, -3), Vector3(5, 0, 4)]:
		poser(HW + "grave_A_destroyed.gltf", c + p, _rng.randf_range(0, 360), 1.3)

func _antre() -> void:
	var c := ANTRE
	# l'antre du Jarl : trône de pierre, bannières, et le coffre légendaire qu'il garde (lumière orange)
	poser(DJ + "pillar_decorated.glb", c + Vector3(-3, 0, -6), 0.0, 1.0)
	poser(DJ + "pillar_decorated.glb", c + Vector3(5, 0, -6), 0.0, 1.0)
	cylindre(c + Vector3(-3, 0, -6), 1.0)
	cylindre(c + Vector3(5, 0, -6), 1.0)
	poser(DJ + "banner_shield_red.glb", c + Vector3(1, 0, -8.5), 0.0, 1.3)
	Coffre.creer(self, c + Vector3(1, 0, -5), "legendaire", 0.0)
	poser(DJ + "coin_stack_large.glb", c + Vector3(-1, 0, -4), 0.0, 1.4)
	poser(DJ + "coin_stack_medium.glb", c + Vector3(3, 0, -3.6), 40.0, 1.4)
	for p in [Vector3(-6, 0, 2), Vector3(6, 0, 3)]:
		poser(DJ + "torch_lit.glb", c + p, 0.0, 1.6)
		lumiere(c + p + Vector3(0, 2.5, 0), Color(1.0, 0.55, 0.25), 1.8, 9.0, true)
		cylindre(c + p, 0.3, 2.0)

func _descente() -> void:
	var c := DESCENTE
	# l'escalier qui s'enfonce : lumière bleue froide qui monte d'en bas. Promesse de l'étage suivant.
	poser(DJ + "stairs_wide.glb", c + Vector3(0, -2.0, -0.5), 180.0, 1.0)
	lumiere(c + Vector3(0, 0.5, -1.5), Color(0.35, 0.6, 1.0), 2.4, 10.0)
	boite(c + Vector3(0, 1.5, -1.0), Vector3(7, 3, 1))   # fermé pour l'instant
	for p in [Vector3(-3.5, 0, 1.5), Vector3(3.5, 0, 1.5)]:
		poser(DJ + "torch_lit.glb", c + p, 0.0, 1.4)
		lumiere(c + p + Vector3(0, 2.2, 0), Color(0.5, 0.75, 1.0), 1.2, 7.0, true)

# =================== ailes pour vingt joueurs ===================

func _disque(centre: Vector3, rayons: Vector2, shader: String, y := 0.01) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = rayons * 2.0
	m.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = load(shader)
	m.material_override = mat
	m.position = centre + Vector3(0, y, 0)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	return m

## Ceinture de collisions autour d'une ellipse (lac, gouffre, lave) : on longe, on ne tombe pas.
func _ceinture(centre: Vector3, rayons: Vector2, n := 20) -> void:
	for i in n:
		var a := TAU * i / n
		cylindre(centre + Vector3(cos(a) * rayons.x, 0, sin(a) * rayons.y) * 0.93, minf(rayons.x, rayons.y) * 0.32 + 0.6, 3.0)

func _ossuaire() -> void:
	var c := OSSUAIRE
	var vert := Color(0.35, 1.0, 0.55)
	# allées de tombes royales : rangées régulières qui guident vers le trône au fond
	for rangee in 3:
		for k in 5:
			var p := c + Vector3(-6 + k * 7.0, 0, -14 + rangee * 12.0)
			if not dedans(Vector2(p.x, p.z), 2.5):
				continue
			poser(HW + ["grave_A", "grave_B", "gravestone", "grave_A_destroyed"][(k + rangee) % 4] + ".gltf", p, 90.0 + _rng.randf_range(-8, 8), 1.5)
			cylindre(p, 0.6, 1.6)
	# deux mausolées au fond de l'aile (loin du camp du Puits, jamais sur un passage)
	var poses := 0
	for p in [c + Vector3(4, 0, -24), c + Vector3(-12, 0, -22), c + Vector3(-14, 0, 18), c + Vector3(8, 0, 22)]:
		if poses >= 2 or not dedans(Vector2(p.x, p.z), 5.0) or p.distance_to(PUITS) < 16.0:
			continue
		poser(HW + "crypt.gltf", p, 90.0, 1.3)
		boite(p + Vector3(0, 2, 0), Vector3(4.2, 4, 5.0))
		poses += 1
	for p in [c + Vector3(4, 0, -22), c + Vector3(-12, 0, 20), c + Vector3(20, 0, 2)]:
		poser(HW + "coffin_decorated.gltf", p, _rng.randf_range(0, 360), 1.2)
	# trône de la Reine pâle : colonnes, bannières, autel de bougies, coffre épique (violet)
	var t := TRONE_REINE
	for p in [t + Vector3(-2, 0, -7), t + Vector3(-2, 0, 7)]:
		poser(DJ + "column.glb", p, 0.0, 1.0)
		cylindre(p, 0.9)
	poser(HW + "shrine_candles.gltf", t + Vector3(-6, 0, 0), 90.0, 2.0)
	cylindre(t + Vector3(-6, 0, 0), 1.6, 2.0)
	Coffre.creer(self, t + Vector3(-3.5, 0, 3.5), "legendaire", 90.0)
	lumiere(t + Vector3(0, 2.5, 0), vert, 2.6, 16.0, true)
	for d in [[c + Vector3(-4, 0, -24), 1.1], [c + Vector3(8, 0, 24), 1.0], [c + Vector3(-20, 0, 18), 0.9], [c + Vector3(22, 0, -10), 0.9], [c + Vector3(-8, 0, 6), 0.8]]:
		if dedans(Vector2(d[0].x, d[0].z), 1.0):
			_cristal(d[0], vert, d[1])
	for i in 18:
		var p := c + Vector3(_rng.randf_range(-22, 22), 0, _rng.randf_range(-24, 24))
		if dedans(Vector2(p.x, p.z), 1.5):
			poser(HW + ["skull", "bone_A", "bone_B", "bone_C", "ribcage"][i % 5] + ".gltf", p, _rng.randf_range(0, 360), 1.2)

func _camp_du_puits() -> void:
	var c := PUITS
	# deuxième refuge : un vieux puits de lumière tombe du plafond, un feu, une tente, une gardienne
	for i in 10:
		var a := TAU * i / 10.0
		poser(F + "Rock_2_A_Color1.gltf", c + Vector3(cos(a), 0, sin(a)) * 1.0, rad_to_deg(a) * 3.0, 2.2)
	for d in [[0.0, Vector3(0, 0.12, 0)], [70.0, Vector3(0.05, 0.3, 0)], [135.0, Vector3(-0.05, 0.2, 0.05)]]:
		var b := poser(R + "Wood_Log_A.gltf", c + d[1], d[0], 1.1)
		b.rotation_degrees.z = 12.0
	_feu(c + Vector3(0, 0.35, 0), 1.2)
	lumiere(c + Vector3(0, 2.3, 0), Color(1.0, 0.58, 0.25), 3.0, 15.0, true)
	cylindre(c, 1.2, 1.0)
	poser(H + "decoration/props/tent.gltf", c + Vector3(5.5, 0, -3.0), 220.0, 7.0)
	boite(c + Vector3(5.5, 1.5, -3.0), Vector3(3.2, 3, 3.2), deg_to_rad(220))
	poser(HW + "bench.gltf", c + Vector3(-2.8, 0, 2.4), -40.0, 0.95)
	poser(H + "decoration/props/barrel.gltf", c + Vector3(-5.0, 0, -3.5), 0.0, 6.0)
	cylindre(c + Vector3(-5.0, 0, -3.5), 0.6, 1.4)
	# le puits de lumière : un cône pâle venu d'en haut, visible de loin dans l'aile ouest
	var rayon := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.2
	cm.bottom_radius = 3.2
	cm.height = 16.0
	cm.cap_top = false
	cm.cap_bottom = false
	rayon.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.disable_fog = true
	mat.albedo_color = Color(0.75, 0.85, 1.0, 0.07)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	rayon.material_override = mat
	rayon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rayon.position = c + Vector3(-4, 8, 4)
	_decor.add_child(rayon)
	lumiere(c + Vector3(-4, 4, 4), Color(0.7, 0.8, 1.0), 1.6, 12.0)
	_anneau(c, 9.5, Color(1.0, 0.78, 0.4), 0.35)

func _anneau(c: Vector3, rayon: float, couleur: Color, alpha: float) -> void:
	var anneau := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(rayon * 2.0, rayon * 2.0)
	anneau.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/anneau_sol.gdshader")
	mat.set_shader_parameter("couleur", couleur)
	mat.set_shader_parameter("rayon", 0.95)
	mat.set_shader_parameter("alpha", alpha)
	anneau.material_override = mat
	anneau.position = c + Vector3(0, 0.05, 0)
	_decor.add_child(anneau)

func _lac() -> void:
	var c := LAC
	_disque(c, LAC_R, "res://shaders/lac.gdshader")
	_ceinture(c, LAC_R, 22)
	var turquoise := Color(0.3, 0.95, 0.85)
	# champignons-cristaux turquoise sur les rives : la seule lumière de l'aile
	for i in 7:
		var a := TAU * i / 7.0 + 0.3
		var p := c + Vector3(cos(a) * (LAC_R.x + 4.5), 0, sin(a) * (LAC_R.y + 4.0))
		if dedans(Vector2(p.x, p.z), 1.5):
			_cristal(p, turquoise, 0.8)
	# une barque échouée et un coffre rare sur la rive nord : on le voit de l'autre côté de l'eau
	poser(HW + "coffin.gltf", c + Vector3(6, 0, -12.5), 20.0, 1.2)
	Coffre.creer(self, c + Vector3(-4, 0, -13), "epique", 10.0)
	lumiere(c + Vector3(0, 1.5, 0), Color(0.25, 0.7, 0.8), 1.5, 18.0)

func _forges() -> void:
	var c := FORGES
	var lave := Color(1.0, 0.45, 0.12)
	# ruines d'une forge naine : murs écroulés, piliers, enclumes, rivières de lave
	for d in [[c + Vector3(-14, 0, -6), 0.0], [c + Vector3(-14, 0, 2), 0.0], [c + Vector3(16, 0, -10), 90.0], [c + Vector3(10, 0, 12), 30.0]]:
		poser(DJ + "wall_broken.glb", d[0], d[1], 1.0)
		boite(d[0] + Vector3(0, 2, 0), Vector3(4, 4, 1), deg_to_rad(d[1]))
	for p in [c + Vector3(-6, 0, -10), c + Vector3(6, 0, -10), c + Vector3(-6, 0, 8), c + Vector3(6, 0, 8)]:
		poser(DJ + "pillar.glb", p, 0.0, 1.0)
		cylindre(p, 0.8)
	for d in [[c + Vector3(-20, 0, -16), Vector2(4, 3)], [c + Vector3(18, 0, 2), Vector2(3.5, 5)], [c + Vector3(0, 0, -20), Vector2(5, 3)]]:
		if dedans(Vector2(d[0].x, d[0].z), 3.0):
			_disque(d[0], d[1], "res://shaders/lave.gdshader", 0.02)
			_ceinture(d[0], d[1], 12)
			lumiere(d[0] + Vector3(0, 1.5, 0), lave, 2.6, 12.0, true)
	for p in [c + Vector3(-2, 0, 0), c + Vector3(3, 0, -3)]:
		poser("res://assets/surface/outils/anvil.gltf", p, _rng.randf_range(0, 360), 1.3)
		boite(p + Vector3(0, 0.5, 0), Vector3(1.8, 1.0, 0.9))
	for p in [c + Vector3(-10, 0, 14), c + Vector3(14, 0, -18), c + Vector3(-18, 0, 4)]:
		poser(DJ + ["barrel_large", "crates_stacked", "keg_decorated"][_rng.randi() % 3] + ".glb", p, _rng.randf_range(0, 360), 1.0)
		cylindre(p, 1.0, 2.0)
	poser(R + "Iron_Bars_Stack_Medium.gltf", c + Vector3(-4, 0, 4), 20.0, 1.4)
	poser(R + "Gold_Bars_Stack_Small.gltf", ENCLUME_BROKK + Vector3(3, 0, -3), 0.0, 1.6)
	# l'enclume de Brokk : un brasier géant et un coffre légendaire
	var e := ENCLUME_BROKK
	poser("res://assets/surface/outils/anvil.gltf", e, 0.0, 2.2)
	boite(e + Vector3(0, 0.8, 0), Vector3(3.4, 1.6, 1.6))
	_feu(e + Vector3(-4, 0.4, -2), 1.6)
	lumiere(e + Vector3(-4, 2.5, -2), lave, 3.2, 16.0, true)
	Coffre.creer(self, e + Vector3(4, 0, -4), "mythique", 0.0)

## Points d'arrivée : là où le Portail dépose les joueurs. Deux points éloignés pour que vingt joueurs
## ne s'entassent pas dans la même salle.
func _arrivees() -> void:
	for p in ARRIVEES:
		_anneau(p, 4.0, Color(0.5, 0.85, 1.0), 0.5)
		lumiere(p + Vector3(0, 2.0, 0), Color(0.5, 0.8, 1.0), 1.0, 7.0)

## Coffres communs et rares éparpillés, filons de minerai : de quoi occuper vingt joueurs.
## Les filons rares sont au fond des ailes dangereuses (l'or près des forges).
func _tresors() -> void:
	for d in [[Vector3(-14, 0, -32), "commun"], [Vector3(46, 0, -36), "commun"], [Vector3(-34, 0, -60), "rare"], [Vector3(30, 0, -90), "rare"],
			[Vector3(-108, 0, -40), "rare"], [Vector3(-84, 0, -84), "commun"], [Vector3(-100, 0, 14), "commun"], [Vector3(-64, 0, 10), "rare"],
			[Vector3(36, 0, -130), "rare"], [Vector3(76, 0, -122), "commun"], [Vector3(6, 0, -70), "commun"], [Vector3(56, 0, -52), "epique"]]:
		if dedans(Vector2(d[0].x, d[0].z), 2.0):
			Coffre.creer(self, d[0], d[1], randf() * 360.0)
	for d in [[Vector3(-2, 0, -32), "cuivre"], [Vector3(26, 0, -40), "cuivre"], [Vector3(-36, 0, -46), "cuivre"], [Vector3(10, 0, -88), "cuivre"],
			[Vector3(-30, 0, -86), "fer"], [Vector3(48, 0, -78), "fer"], [Vector3(-76, 0, -66), "fer"], [Vector3(-108, 0, -74), "fer"],
			[Vector3(-62, 0, -2), "fer"], [Vector3(-108, 0, -2), "argent"], [Vector3(-90, 0, -84), "argent"], [Vector3(40, 0, -100), "argent"],
			[Vector3(72, 0, -146), "or"], [Vector3(36, 0, -146), "or"], [Vector3(70, 0, -116), "argent"], [Vector3(-48, 0, -64), "cuivre"]]:
		if dedans(Vector2(d[0].x, d[0].z), 2.0):
			Filon.creer(self, d[0], d[1])
