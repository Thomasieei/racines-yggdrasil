class_name Essaim
extends Node3D
## La Horde : des centaines de rampants squelettes qui déferlent, pour le plaisir de tout pulvériser.
## Tout passe par un seul MultiMesh (une seule image à dessiner, quel que soit le nombre) :
## le squelette est « cuit » une fois dans une pose de course, puis un shader le fait trottiner.
## Les coups du héros arrivent par l'événement « frappe » (cercle, cône, ligne).

const MODELE := "res://assets/personnages/squelette_minion.glb"
const MAX := 520
const PV := 46.0
const VITESSE := 3.6

static var moi: Essaim

var zone := Rect2()                 ## où la horde vit (x, z)
var cible_nombre := 320
var heros: Heros
var _mm: MultiMesh
var _pos: Array[Vector3] = []
var _pv: Array[float] = []
var _phase: Array[float] = []
var _flash: Array[float] = []
var _slot: Array[Vector2] = []
var _n := 0
var _spawn_t := 0.0
var _morts_cadence := 0
var tues := 0
var _or_reste := 0
var actif := false
var _contact_t := 0.0
var _buf := PackedFloat32Array()

func _ready() -> void:
	moi = self
	Jeu.ecouteurs.append(_sur_evenement)
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.use_custom_data = true
	_mm.mesh = _cuire()
	_mm.instance_count = MAX
	_mm.visible_instance_count = 0
	_buf.resize(MAX * 20)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-1000, -10, -1000), Vector3(2000, 30, 2000))
	add_child(mmi)

func _exit_tree() -> void:
	if moi == self:
		moi = null

# ---------------- cuisson du squelette dans une pose de course ----------------

## Peau calculée à la main (skinning CPU) une seule fois : pas besoin de squelette animé par créature.
func _cuire() -> Mesh:
	var n: Node3D = load(MODELE).instantiate()
	add_child(n)
	var ap: AnimationPlayer = n.find_child("AnimationPlayer", true, false)
	var sk: Skeleton3D = n.find_child("Skeleton3D", true, false)
	if ap:
		var anim := "Running_A" if ap.has_animation("Running_A") else ap.get_animation_list()[0]
		ap.play(anim)
		ap.seek(0.25, true)
		ap.advance(0.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mat: Material = null
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if not m.visible or m.mesh == null:
			continue
		var skin := m.skin
		for s in m.mesh.get_surface_count():
			var a := m.mesh.surface_get_arrays(s)
			if mat == null:
				mat = m.mesh.surface_get_material(s)
			var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var nr: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
			var uv: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
			var os = a[Mesh.ARRAY_BONES]
			var ps = a[Mesh.ARRAY_WEIGHTS]
			var idx = a[Mesh.ARRAY_INDEX]
			var cache := {}
			var res_v := PackedVector3Array()
			var res_n := PackedVector3Array()
			res_v.resize(v.size())
			res_n.resize(v.size())
			var par_os: int = (os.size() / v.size()) if os != null and v.size() > 0 else 0
			for i in v.size():
				if skin == null or sk == null or par_os == 0:
					var xf: Transform3D = sk.global_transform.affine_inverse() * m.global_transform if sk else m.transform
					res_v[i] = xf * v[i]
					res_n[i] = (xf.basis * nr[i]).normalized()
					continue
				var acc := Vector3.ZERO
				var accn := Vector3.ZERO
				for k in par_os:
					var w: float = ps[i * par_os + k]
					if w <= 0.0:
						continue
					var b: int = os[i * par_os + k]
					if not cache.has(b):
						var bone := skin.get_bind_bone(b)
						if bone < 0:
							bone = sk.find_bone(skin.get_bind_name(b))
						cache[b] = sk.get_bone_global_pose(bone) * skin.get_bind_pose(b)
					var t: Transform3D = cache[b]
					acc += (t * v[i]) * w
					accn += (t.basis * nr[i]) * w
				res_v[i] = acc
				res_n[i] = accn.normalized()
			var liste: Array = idx if idx != null and idx.size() > 0 else range(v.size())
			for j in liste:
				st.set_normal(res_n[j])
				if uv.size() > 0:
					st.set_uv(uv[j])
				st.add_vertex(res_v[j] * 0.9)
	n.queue_free()
	var mesh := st.commit()
	# matière : la texture du squelette, un trot et un éclat blanc quand il est touché
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
uniform sampler2D tex : source_color, filter_nearest;
varying float flash;
void vertex() {
	float ph = INSTANCE_CUSTOM.x * 6.2831;
	float t = TIME * 11.0 + ph;
	VERTEX.y += abs(sin(t)) * 0.16;
	VERTEX.x += sin(t) * 0.05 * VERTEX.y;
	flash = COLOR.r;
}
void fragment() {
	vec3 c = texture(tex, UV).rgb;
	ALBEDO = mix(c, vec3(1.0, 0.95, 0.85), flash);
	EMISSION = vec3(1.0, 0.6, 0.3) * flash * 0.8;
	ROUGHNESS = 0.8;
}
"""
	sm.shader = sh
	if mat is StandardMaterial3D:
		sm.set_shader_parameter("tex", mat.albedo_texture)
	mesh.surface_set_material(0, sm)
	return mesh

# ---------------- vie de la horde ----------------

func demarrer(h: Heros, z: Rect2, nombre := 320) -> void:
	heros = h
	zone = z
	cible_nombre = nombre
	actif = true

func arreter() -> void:
	actif = false

func _ajouter(p: Vector3) -> void:
	if _n >= MAX:
		return
	if _pos.size() <= _n:
		_pos.append(p)
		_pv.append(PV)
		_phase.append(randf())
		_flash.append(0.0)
		_slot.append(Vector2.ZERO)
	_pos[_n] = p
	_pv[_n] = PV
	_phase[_n] = randf()
	_flash[_n] = 0.0
	var a := randf() * TAU
	_slot[_n] = Vector2(cos(a), sin(a)) * randf_range(1.0, 3.4)
	_n += 1
	_mm.visible_instance_count = _n

func _retirer(i: int) -> void:
	_n -= 1
	_pos[i] = _pos[_n]
	_pv[i] = _pv[_n]
	_phase[i] = _phase[_n]
	_flash[i] = _flash[_n]
	_slot[i] = _slot[_n]
	_mm.visible_instance_count = _n

func _bord() -> Vector3:
	# ils sortent de terre sur les bords de la zone, jamais sous les pieds du joueur
	for essai in 6:
		var p := Vector3(randf_range(zone.position.x, zone.end.x), 0, randf_range(zone.position.y, zone.end.y))
		if randf() < 0.7:
			match randi() % 4:
				0: p.x = zone.position.x + 1.0
				1: p.x = zone.end.x - 1.0
				2: p.z = zone.position.y + 1.0
				3: p.z = zone.end.y - 1.0
		if heros == null or p.distance_to(heros.global_position) > 9.0:
			return p
	return Vector3(zone.position.x, 0, zone.position.y)

func _process(delta: float) -> void:
	if heros == null or not is_instance_valid(heros):
		return
	var hp := heros.global_position
	var dans := zone.grow(4.0).has_point(Vector2(hp.x, hp.z)) and not heros.est_mort
	# apparitions
	if actif and dans and _n < cible_nombre:
		_spawn_t += delta * 30.0
		while _spawn_t > 1.0 and _n < cible_nombre:
			_spawn_t -= 1.0
			var p := _bord()
			_ajouter(p)
			if randf() < 0.15:
				Effets.poussiere(self, p, 4, Color(0.5, 0.45, 0.4, 0.5))
	# déplacement : chacun vise une place autour du héros (encerclement naturel, sans calcul de foule).
	# Tout est écrit d'un bloc dans le tampon du MultiMesh : beaucoup moins cher qu'un appel par créature.
	var contact := 0
	var t_ms := Time.get_ticks_msec() * 0.0005
	for i in _n:
		var p: Vector3 = _pos[i]
		var bx: float
		var bz: float
		if dans:
			bx = hp.x + _slot[i].x
			bz = hp.z + _slot[i].y
		else:
			bx = p.x + sin(_phase[i] * 40.0 + t_ms)
			bz = p.z
		var vx := bx - p.x
		var vz := bz - p.z
		var d := sqrt(vx * vx + vz * vz)
		if d > 0.05:
			var pas := minf(d, VITESSE * (0.8 + _phase[i] * 0.4) * delta) / d
			p.x = clampf(p.x + vx * pas, zone.position.x - 3.0, zone.end.x + 3.0)
			p.z = clampf(p.z + vz * pas, zone.position.y - 3.0, zone.end.y + 3.0)
			_pos[i] = p
		var rx := hp.x - p.x
		var rz := hp.z - p.z
		var dh := sqrt(rx * rx + rz * rz)
		if dh < 1.5:
			contact += 1
		var c := rz / maxf(dh, 0.001)
		var sn := rx / maxf(dh, 0.001)
		if _flash[i] > 0.0:
			_flash[i] = maxf(0.0, _flash[i] - delta * 5.0)
		var o := i * 20
		_buf[o] = c; _buf[o + 1] = 0.0; _buf[o + 2] = sn; _buf[o + 3] = p.x
		_buf[o + 4] = 0.0; _buf[o + 5] = 1.0; _buf[o + 6] = 0.0; _buf[o + 7] = 0.0
		_buf[o + 8] = -sn; _buf[o + 9] = 0.0; _buf[o + 10] = c; _buf[o + 11] = p.z
		_buf[o + 12] = _flash[i]; _buf[o + 13] = 0.0; _buf[o + 14] = 0.0; _buf[o + 15] = 1.0
		_buf[o + 16] = _phase[i]
	if _n > 0:
		_mm.buffer = _buf
	# morsures : petites, mais nombreuses
	_contact_t -= delta
	if contact > 0 and dans and _contact_t <= 0.0:
		_contact_t = 0.5
		heros.recevoir({"montant": minf(contact, 12) * 7.0})
	_morts_cadence = 0

## Le joueur frappe : cercle, cône ou ligne. Renvoie le nombre de rampants pulvérisés.
func frapper(centre: Vector3, rayon: float, degats: float, dir := Vector3.ZERO, angle := 0.0, longueur := 0.0) -> int:
	var morts := 0
	var i := 0
	while i < _n:
		var p: Vector3 = _pos[i]
		var touche := false
		if longueur > 0.0:
			touche = Zones.dans_ligne(p, centre, dir, longueur, rayon, 0.4)
		elif angle > 0.0:
			touche = Zones.dans_cone(p, centre, dir, rayon, angle, 0.4)
		else:
			touche = Vector2(p.x - centre.x, p.z - centre.z).length() < rayon + 0.4
		if touche:
			_pv[i] -= degats
			_flash[i] = 1.0
			if _pv[i] <= 0.0:
				_mourir(i)
				morts += 1
				continue
		i += 1
	if morts > 0:
		tues += morts
		Profil.p().compter("horde", morts)
		heros.mana = minf(heros.mana_max, heros.mana + morts * 0.6)
		heros.mana_change.emit(heros.mana, heros.mana_max)
		_or_reste += morts
		if _or_reste >= 10:
			heros.sac.ajouter_or(_or_reste / 10 * 3)
			_or_reste %= 10
		if Jeu.hud and Jeu.hud.has_method("combo_horde"):
			Jeu.hud.combo_horde(morts, tues)
	return morts

func _mourir(i: int) -> void:
	var p: Vector3 = _pos[i]
	if _morts_cadence < 14:
		_morts_cadence += 1
		Effets.etincelles(self, p + Vector3(0, 0.7, 0), Vector3.UP, Color(0.9, 0.92, 0.85), 6, 4.0, "spark_04.png", 0.3)
	_retirer(i)

## Y a-t-il un rampant à portée (pour l'attaque automatique) ?
func proche(p: Vector3, portee: float) -> Vector3:
	var meilleur := Vector3.INF
	var dmin := portee
	for i in _n:
		var d := Vector2(_pos[i].x - p.x, _pos[i].z - p.z).length()
		if d < dmin:
			dmin = d
			meilleur = _pos[i]
	return meilleur

func _sur_evenement(nom: String, d: Dictionary) -> void:
	if nom == "frappe" and _n > 0:
		frapper(d["centre"], d.get("rayon", 2.0), d.get("degats", 50.0), d.get("dir", Vector3.ZERO), d.get("angle", 0.0), d.get("longueur", 0.0))
