extends Node3D
## Bulle de Freya : bouclier qui absorbe les dégâts pendant quelques secondes.
## Apparition (anneau au sol, étincelles qui montent), ondes à chaque coup absorbé,
## fissures qui s'élargissent avec l'usure, éclatement en éclats dorés.

signal eclatee

@export var rayon := 1.45
@export var hauteur := 1.15
@export var pv_max := 80.0
@export var duree := 4.0

var pv := 0.0
var _t := 0.0
var _actif := false
var _apparition := 0.0
var _impacts: Array[Vector4] = [Vector4(0, 0, 1, -1), Vector4(0, 0, 1, -1), Vector4(0, 0, 1, -1), Vector4(0, 0, 1, -1)]
var _prochain_impact := 0
var _sphere: MeshInstance3D
var _mat: ShaderMaterial
var _lumiere: OmniLight3D

## Les éclats et ondes vivent dans le monde, pas sur le héros (sinon ils le suivraient).
func _monde() -> Node:
	var r := get_tree().current_scene
	return r if r else get_parent()

func _ready() -> void:
	_sphere = MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = rayon
	m.height = rayon * 2.0
	m.radial_segments = 48
	m.rings = 24
	_sphere.mesh = m
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/bulle_freya.gdshader")
	_sphere.material_override = _mat
	_sphere.position.y = hauteur
	_sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_sphere)
	_lumiere = OmniLight3D.new()
	_lumiere.light_color = Color(1.0, 0.82, 0.45)
	_lumiere.omni_range = 5.0
	_lumiere.light_energy = 0.0
	_lumiere.position.y = hauteur
	add_child(_lumiere)
	visible = false

func activer() -> void:
	pv = pv_max
	_t = 0.0
	_actif = true
	_apparition = 0.0
	visible = true
	for i in 4:
		_impacts[i].w = -1.0
	_onde_sol(Color(1.0, 0.8, 0.4), 0.55, 3.2)
	_etincelles_montantes()

## Absorbe un coup venant de `source` (position monde). Renvoie les dégâts non absorbés.
func absorber(source: Vector3, degats: float) -> float:
	if not _actif:
		return degats
	var centre := global_position + Vector3(0, hauteur, 0)
	var dir_monde := (source - centre).normalized()
	var dir_local := global_transform.basis.inverse() * dir_monde
	_impacts[_prochain_impact] = Vector4(dir_local.x, dir_local.y, dir_local.z, 0.0)
	_prochain_impact = (_prochain_impact + 1) % 4
	_etincelles_impact(centre + dir_monde * rayon, dir_monde)
	var absorbe := minf(pv, degats)
	pv -= absorbe
	if pv <= 0.0:
		eclater()
	return degats - absorbe

func eclater() -> void:
	if not _actif:
		return
	_actif = false
	_eclats()
	_onde_sol(Color(1.0, 0.7, 0.3), 0.85, 4.5)
	# dernier souffle : la bulle gonfle et s'embrase avant de disparaître
	_mat.set_shader_parameter("usure", 1.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_sphere, "scale", Vector3.ONE * 1.28, 0.16).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v): _mat.set_shader_parameter("intensite", v), 2.6, 0.0, 0.16)
	tw.chain().tween_callback(func(): visible = false; _mat.set_shader_parameter("intensite", 1.0))
	_lumiere.light_energy = 4.0
	var tl := create_tween()
	tl.tween_property(_lumiere, "light_energy", 0.0, 0.35)
	eclatee.emit()

func _process(delta: float) -> void:
	if not _actif:
		return
	_t += delta
	# apparition avec léger dépassement d'échelle
	_apparition = minf(1.0, _apparition + delta * 5.0)
	var e := _apparition
	var ech := 1.0 + 0.18 * sin(e * PI) * (1.0 - e * 0.5) if e < 1.0 else 1.0
	_sphere.scale = Vector3.ONE * lerpf(0.3, 1.0, ease(e, 0.4)) * ech
	var usure := 1.0 - pv / pv_max
	usure = maxf(usure, clampf((_t - (duree - 1.2)) / 1.2, 0.0, 1.0))   # la fin approche : ça se fissure aussi
	_mat.set_shader_parameter("apparition", e)
	_mat.set_shader_parameter("usure", usure)
	for i in 4:
		if _impacts[i].w >= 0.0:
			_impacts[i].w += delta
	_mat.set_shader_parameter("impact0", _impacts[0])
	_mat.set_shader_parameter("impact1", _impacts[1])
	_mat.set_shader_parameter("impact2", _impacts[2])
	_mat.set_shader_parameter("impact3", _impacts[3])
	_lumiere.light_energy = 1.3 + 0.25 * sin(_t * 6.0) + usure * 0.6 * sin(_t * 30.0)
	if _t >= duree:
		eclater()

# ---------- effets ----------

func _onde_sol(couleur: Color, largeur: float, taille: float) -> void:
	var plan := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(taille * 2.0, taille * 2.0)
	plan.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/anneau_sol.gdshader")
	mat.set_shader_parameter("couleur", couleur)
	plan.material_override = mat
	plan.position.y = 0.06
	plan.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_monde().add_child(plan)
	plan.global_position = global_position + Vector3(0, 0.06, 0)
	var tw := plan.create_tween().set_parallel(true)
	tw.tween_method(func(v): mat.set_shader_parameter("rayon", v), 0.15, 0.95, largeur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(func(v): mat.set_shader_parameter("alpha", v), 1.0, 0.0, largeur).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(plan.queue_free)

func _particules(nb: int, duree_vie: float, couleur: Color, taille: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = nb
	p.lifetime = duree_vie
	p.one_shot = true
	p.explosiveness = 0.9
	var mesh := SphereMesh.new()
	mesh.radius = taille
	mesh.height = taille * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = couleur
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.disable_fog = true   # sinon le brouillard dessine un carré clair autour de l'effet
	mat.vertex_color_use_as_albedo = true
	mesh.material = mat
	p.mesh = mesh
	var rampe := Gradient.new()
	rampe.set_color(0, Color(1, 1, 1, 1))
	rampe.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = rampe
	var courbe := Curve.new()
	courbe.add_point(Vector2(0, 1))
	courbe.add_point(Vector2(1, 0))
	p.scale_amount_curve = courbe
	_monde().add_child(p)
	var t := get_tree().create_timer(duree_vie + 0.5)
	t.timeout.connect(p.queue_free)
	return p

func _etincelles_montantes() -> void:
	var p := _particules(40, 1.1, Color(1.0, 0.85, 0.45), 0.05)
	p.global_position = global_position + Vector3(0, 0.1, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_radius = rayon
	p.emission_ring_inner_radius = rayon * 0.8
	p.emission_ring_height = 0.05
	p.emission_ring_axis = Vector3.UP
	p.direction = Vector3.UP
	p.spread = 12.0
	p.gravity = Vector3(0, 1.2, 0)
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.0
	p.explosiveness = 0.6
	p.emitting = true

func _etincelles_impact(pos: Vector3, normale: Vector3) -> void:
	var p := _particules(18, 0.45, Color(1.0, 0.9, 0.6), 0.04)
	p.global_position = pos
	p.direction = normale
	p.spread = 55.0
	p.gravity = Vector3(0, -6, 0)
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 6.5
	p.emitting = true

func _eclats() -> void:
	var p := CPUParticles3D.new()
	p.amount = 90
	p.lifetime = 1.0
	p.one_shot = true
	p.explosiveness = 1.0
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.24, 0.34, 0.04)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.85, 0.5)
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.disable_fog = true   # sinon le brouillard dessine un carré clair autour de l'effet
	mat.vertex_color_use_as_albedo = true
	mesh.material = mat
	p.mesh = mesh
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE_SURFACE
	p.emission_sphere_radius = rayon
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 7.0
	p.gravity = Vector3(0, -9, 0)
	p.angular_velocity_min = -540.0
	p.angular_velocity_max = 540.0
	p.particle_flag_rotate_y = true
	var rampe := Gradient.new()
	rampe.set_color(0, Color(1, 1, 1, 1))
	rampe.set_color(1, Color(1, 0.6, 0.3, 0))
	p.color_ramp = rampe
	_monde().add_child(p)
	p.global_position = global_position + Vector3(0, hauteur, 0)
	p.emitting = true
	var t := get_tree().create_timer(1.5)
	t.timeout.connect(p.queue_free)
