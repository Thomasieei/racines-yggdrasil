class_name DragonVisuel
## Œufs et bébés dragons, construits en code (aucun modèle de dragon dans la banque d'assets pour l'instant).
## Le bébé dragon est PROVISOIRE : il sera remplacé par un vrai modèle animé dès qu'on l'aura
## (ex. Quaternius, licence CC0). Toute la logique (rareté, puissance, croissance) reste valable.

const COULEURS := {
	"commun": [Color(0.32, 0.72, 0.38), Color(0.6, 1.0, 0.65)],
	"rare": [Color(0.24, 0.5, 0.95), Color(0.55, 0.85, 1.0)],
	"epique": [Color(0.55, 0.3, 0.9), Color(0.85, 0.6, 1.0)],
	"legendaire": [Color(0.95, 0.55, 0.15), Color(1.0, 0.85, 0.4)],
	"mythique": [Color(0.85, 0.14, 0.16), Color(1.0, 0.5, 0.35)],
}

static func oeuf(rarete: String) -> Node3D:
	var n := Node3D.new()
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.32
	s.height = 0.84
	s.radial_segments = 24
	s.rings = 14
	m.mesh = s
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/oeuf_dragon.gdshader")
	mat.set_shader_parameter("couleur", COULEURS[rarete][0])
	mat.set_shader_parameter("veine", COULEURS[rarete][1])
	m.material_override = mat
	m.position.y = 0.42
	m.name = "Coque"
	n.add_child(m)
	return n

static func _mat(c: Color, emission := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.65
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	return m

static func _piece(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO, ech := Vector3.ONE) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.position = pos
	m.rotation = rot
	m.scale = ech
	parent.add_child(m)
	return m

## Bébé dragon stylisé (proportions « chibi » : grosse tête, grands yeux, ailes de chauve-souris),
## couleur de rareté. Racine orientée vers +z (comme les personnages KayKit).
static func bebe(rarete: String) -> Node3D:
	var corps_c: Color = COULEURS[rarete][0]
	var lueur: Color = COULEURS[rarete][1]
	var peau := _mat(corps_c)
	var ventre := _mat(corps_c.lightened(0.5))
	var corne := _mat(Color(0.96, 0.92, 0.8))
	var blanc := _mat(Color(1, 1, 1))
	var pupille := _mat(lueur.darkened(0.2), 1.5)
	var noir := _mat(Color(0.05, 0.04, 0.06))
	var aile_m := _mat(corps_c.darkened(0.15))
	aile_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var membrane := _mat(lueur.lerp(corps_c, 0.4))
	membrane.cull_mode = BaseMaterial3D.CULL_DISABLED
	var racine := Node3D.new()
	var pivot := Node3D.new()
	pivot.name = "Pivot"
	racine.add_child(pivot)
	var sph := SphereMesh.new()
	sph.radius = 0.5
	sph.height = 1.0
	sph.radial_segments = 18
	sph.rings = 9
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	cyl.radial_segments = 10
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.5
	cone.height = 1.0
	cone.radial_segments = 8
	# corps en poire, ventre clair
	_piece(pivot, sph, peau, Vector3(0, 0.42, -0.02), Vector3.ZERO, Vector3(0.5, 0.52, 0.56))
	_piece(pivot, sph, ventre, Vector3(0, 0.38, 0.1), Vector3.ZERO, Vector3(0.36, 0.42, 0.4))
	# pattes trapues
	for p in [Vector3(-0.15, 0.12, 0.12), Vector3(0.15, 0.12, 0.12), Vector3(-0.17, 0.12, -0.14), Vector3(0.17, 0.12, -0.14)]:
		_piece(pivot, cyl, peau, p, Vector3.ZERO, Vector3(0.12, 0.2, 0.12))
		_piece(pivot, sph, ventre, p + Vector3(0, -0.1, 0.03), Vector3.ZERO, Vector3(0.14, 0.07, 0.16))
	# grosse tête
	var tete := Node3D.new()
	tete.name = "Tete"
	tete.position = Vector3(0, 0.86, 0.12)
	pivot.add_child(tete)
	_piece(tete, sph, peau, Vector3.ZERO, Vector3.ZERO, Vector3(0.56, 0.5, 0.52))
	_piece(tete, sph, ventre, Vector3(0, -0.09, 0.2), Vector3.ZERO, Vector3(0.32, 0.22, 0.26))
	_piece(tete, sph, noir, Vector3(-0.05, -0.06, 0.33), Vector3.ZERO, Vector3(0.03, 0.03, 0.02))
	_piece(tete, sph, noir, Vector3(0.05, -0.06, 0.33), Vector3.ZERO, Vector3(0.03, 0.03, 0.02))
	for sx in [-1.0, 1.0]:
		_piece(tete, sph, blanc, Vector3(0.13 * sx, 0.05, 0.2), Vector3.ZERO, Vector3(0.16, 0.18, 0.1))
		_piece(tete, sph, pupille, Vector3(0.14 * sx, 0.04, 0.25), Vector3.ZERO, Vector3(0.09, 0.12, 0.04))
		_piece(tete, sph, blanc, Vector3(0.16 * sx, 0.08, 0.27), Vector3.ZERO, Vector3(0.03, 0.03, 0.02))
		_piece(tete, cone, corne, Vector3(0.13 * sx, 0.25, -0.08), Vector3(-0.5, 0, 0.3 * sx), Vector3(0.09, 0.26, 0.09))
		# petites oreilles-collerette
		_piece(tete, cone, membrane, Vector3(0.26 * sx, 0.04, -0.06), Vector3(0, 0, -1.3 * sx), Vector3(0.1, 0.2, 0.05))
	# crête dorsale
	for i in 4:
		_piece(pivot, cone, corne, Vector3(0, 0.66 - i * 0.07, -0.12 - i * 0.1), Vector3(-0.5, 0, 0), Vector3(0.06, 0.12, 0.06) * (1.0 - i * 0.15))
	# queue en anneaux, pointe en flèche
	var queue := Node3D.new()
	queue.name = "Queue"
	queue.position = Vector3(0, 0.25, -0.3)
	pivot.add_child(queue)
	for i in 5:
		var k := 1.0 - i * 0.15
		_piece(queue, sph, peau, Vector3(0.0, -0.02 * i, -0.13 * i), Vector3.ZERO, Vector3(0.2, 0.18, 0.22) * k)
	_piece(queue, cone, membrane, Vector3(0, -0.08, -0.72), Vector3(-PI / 2, 0, 0), Vector3(0.14, 0.18, 0.04))
	# ailes de chauve-souris : bras + membrane en éventail, bien visibles de face
	for sx in [-1.0, 1.0]:
		var aile := Node3D.new()
		aile.name = "Aile_" + ("g" if sx < 0 else "d")
		aile.position = Vector3(0.16 * sx, 0.62, -0.12)
		aile.rotation.x = -0.35
		pivot.add_child(aile)
		var pts := [Vector3.ZERO, Vector3(0.35 * sx, 0.42, -0.05), Vector3(0.72 * sx, 0.38, -0.1), Vector3(0.78 * sx, 0.05, -0.12), Vector3(0.55 * sx, -0.08, -0.1), Vector3(0.28 * sx, -0.12, -0.06)]
		var v := PackedVector3Array()
		for j in range(1, pts.size() - 1):
			v.append(pts[0])
			v.append(pts[j])
			v.append(pts[j + 1])
		var am := ArrayMesh.new()
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		var nrm := PackedVector3Array()
		for j in v.size():
			nrm.append(Vector3(0, 0, 1))
		arr[Mesh.ARRAY_NORMAL] = nrm
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		_piece(aile, am, membrane, Vector3.ZERO)
		# os de l'aile
		for j in [1, 2, 3]:
			var o: Vector3 = pts[j]
			var os := _piece(aile, cyl, aile_m, o * 0.5, Vector3.ZERO, Vector3(0.035, o.length(), 0.035))
			os.basis = Basis.looking_at(o.normalized(), Vector3(0, 0, 1)) * Basis(Vector3.RIGHT, PI / 2) * Basis.from_scale(Vector3(0.035, o.length(), 0.035))
	racine.set_script(load("res://scripts/objets/dragon_anime.gd"))
	return racine
