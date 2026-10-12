class_name Guide
extends Node3D
## Traînée dorée au sol qui mène le joueur à sa destination en suivant le chemin.
## Des points lumineux espacés de 2,4 m ; une vague de lumière court vers la cible.

const ESPACEMENT := 2.4
const MAX_POINTS := 70

var heros: Node3D
var cible := Vector3.INF
var _points: Array[MeshInstance3D] = []
var _mat: StandardMaterial3D
var _maj_t := 0.0
var _t := 0.0
var _chemin_pts: Array = []

func _ready() -> void:
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat.disable_fog = true   # sinon le brouillard dessine un carré clair autour de l'effet
	_mat.albedo_texture = load("res://assets/vfx/circle_05.png")
	_mat.vertex_color_use_as_albedo = true
	_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	var q := QuadMesh.new()
	q.size = Vector2(0.9, 0.9)
	q.orientation = PlaneMesh.FACE_Y
	for i in MAX_POINTS:
		var m := MeshInstance3D.new()
		m.mesh = q
		m.material_override = _mat.duplicate()
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.visible = false
		add_child(m)
		_points.append(m)

func viser(c: Vector3) -> void:
	cible = c
	_maj_t = 0.0

func arreter() -> void:
	cible = Vector3.INF
	for p in _points:
		p.visible = false

## Trajet : depuis la projection du héros sur le chemin, en suivant le chemin, jusqu'au point du chemin
## le plus proche de la cible, puis tout droit vers la cible.
func _trajet() -> Array:
	var h := Vector2(heros.global_position.x, heros.global_position.z)
	var c := Vector2(cible.x, cible.z)
	var ch: Array = CarteSurface.CHEMIN
	var i_h := _indice_segment(h)
	var i_c := _indice_segment(c)
	var pts: Array = [h]
	var proj_h: Vector2 = _proj(h, i_h)
	if h.distance_to(proj_h) > 1.0:
		pts.append(proj_h)
	if i_c > i_h:
		for i in range(i_h + 1, i_c + 1):
			pts.append(ch[i])
	elif i_c < i_h:
		for i in range(i_h, i_c, -1):
			pts.append(ch[i])
	pts.append(_proj(c, i_c))
	pts.append(c)
	return pts

func _indice_segment(p: Vector2) -> int:
	var ch: Array = CarteSurface.CHEMIN
	var meilleur := 0
	var d := 1e9
	for i in ch.size() - 1:
		var q := _proj(p, i)
		var l := p.distance_to(q)
		if l < d:
			d = l
			meilleur = i
	return meilleur

func _proj(p: Vector2, i: int) -> Vector2:
	var ch: Array = CarteSurface.CHEMIN
	var a: Vector2 = ch[i]
	var b: Vector2 = ch[i + 1]
	var ab := b - a
	return a + ab * clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)

func _process(delta: float) -> void:
	if heros == null or cible == Vector3.INF:
		return
	_t += delta
	_maj_t -= delta
	if _maj_t <= 0.0:
		_maj_t = 0.4
		_chemin_pts = _trajet()
		_placer()
	# vague lumineuse qui file vers la cible
	for i in _points.size():
		var p := _points[i]
		if not p.visible:
			continue
		var onde := 0.5 + 0.5 * sin(i * 0.55 - _t * 5.0)
		var m: StandardMaterial3D = p.material_override
		var fondu := clampf(float(i) / 3.0, 0.0, 1.0)
		m.albedo_color = Color(1.0, 0.82, 0.42, (0.25 + onde * 0.6) * fondu)
		p.scale = Vector3.ONE * (0.75 + onde * 0.35)

func _placer() -> void:
	var n := 0
	var reste := 1.6     # on ne pose rien sous les pieds du héros
	for i in _chemin_pts.size() - 1:
		var a: Vector2 = _chemin_pts[i]
		var b: Vector2 = _chemin_pts[i + 1]
		var l := a.distance_to(b)
		var t := reste
		while t < l and n < MAX_POINTS:
			var q := a.lerp(b, t / l)
			_points[n].position = Vector3(q.x, 0.08, q.y)
			_points[n].visible = true
			n += 1
			t += ESPACEMENT
		reste = t - l
	for j in range(n, MAX_POINTS):
		_points[j].visible = false
