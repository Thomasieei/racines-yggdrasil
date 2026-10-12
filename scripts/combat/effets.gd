class_name Effets
## Retours visuels du combat : chiffres de dégâts, étincelles texturées, tailles d'arme, ondes, micro-pause.

const VFX := "res://assets/vfx/"
static var calque_nombres: Node = null   ## calque 2D des chiffres (posé par le HUD)
static var _textures := {}

static func _tex(nom: String) -> Texture2D:
	if not _textures.has(nom):
		_textures[nom] = load(VFX + nom)
	return _textures[nom]

static func _mat_additif(texture: Texture2D, couleur: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.disable_fog = true   # sinon le brouillard dessine un carré clair autour de l'effet
	m.albedo_texture = texture
	m.albedo_color = couleur
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return m

## Chiffre flottant au-dessus d'une cible.
static func nombre(parent: Node, ou: Vector3, texte: String, couleur: Color, grand := false, genre := "") -> void:
	if calque_nombres and is_instance_valid(calque_nombres):
		calque_nombres.ajouter(ou, texte, couleur, genre if genre != "" else ("critique" if grand else "degat"))
		return
	var l := Label3D.new()
	l.text = texte
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.0018 if grand else 0.0013
	l.font_size = 64
	l.outline_size = 14
	l.modulate = couleur
	l.outline_modulate = Color(0, 0, 0, 0.9)
	l.render_priority = 10
	parent.add_child(l)
	var depart := ou + Vector3(randf_range(-0.8, 0.8), randf_range(2.2, 2.9), randf_range(-0.3, 0.3))
	l.global_position = depart
	l.scale = Vector3.ONE * (1.6 if grand else 1.3)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "scale", Vector3.ONE, 0.12).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "global_position", depart + Vector3(0, 1.1, 0), 0.75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.5)
	tw.chain().tween_callback(l.queue_free)

## Gerbe d'étincelles texturées (Kenney Particle Pack).
static func etincelles(parent: Node, ou: Vector3, direction: Vector3, couleur: Color, nombre_part := 14, vitesse := 6.0, texture := "spark_04.png", taille := 0.35) -> void:
	var p := CPUParticles3D.new()
	p.amount = nombre_part
	p.lifetime = 0.45
	p.one_shot = true
	p.explosiveness = 0.95
	var q := QuadMesh.new()
	q.size = Vector2(taille, taille)
	q.material = _mat_additif(_tex(texture), couleur)
	p.mesh = q
	p.particle_flag_align_y = true
	p.direction = direction.normalized() if direction.length() > 0.01 else Vector3.UP
	p.spread = 60.0
	p.initial_velocity_min = vitesse * 0.5
	p.initial_velocity_max = vitesse
	p.gravity = Vector3(0, -9, 0)
	var rampe := Gradient.new()
	rampe.set_color(0, Color(1, 1, 1, 1))
	rampe.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = rampe
	var c := Curve.new()
	c.add_point(Vector2(0, 1))
	c.add_point(Vector2(1, 0.2))
	p.scale_amount_curve = c
	parent.add_child(p)
	p.global_position = ou
	p.emitting = true
	parent.get_tree().create_timer(1.0).timeout.connect(p.queue_free)

## Éclair de lumière bref (impact, éclatement).
static func flash_lumiere(parent: Node, ou: Vector3, couleur: Color, energie := 3.0, portee := 6.0, duree := 0.18) -> void:
	var l := OmniLight3D.new()
	l.light_color = couleur
	l.light_energy = energie
	l.omni_range = portee
	parent.add_child(l)
	l.global_position = ou + Vector3(0, 1.2, 0)
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, duree)
	tw.tween_callback(l.queue_free)

## Taille d'arme dessinée au sol (arc lumineux qui suit la direction du coup).
static func taille(parent: Node, ou: Vector3, direction: Vector3, rayon: float, couleur: Color, texture := "slash_02.png", duree := 0.22, angle_debut := -0.6) -> void:
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(rayon * 2.0, rayon * 2.0)
	q.orientation = PlaneMesh.FACE_Y
	m.mesh = q
	var mat := _mat_additif(_tex(texture), couleur)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(m)
	m.global_position = ou + Vector3(0, 1.0, 0)
	var base := atan2(-direction.x, -direction.z)
	m.global_rotation.y = base + angle_debut
	m.scale = Vector3.ONE * 0.85
	var tw := m.create_tween().set_parallel(true)
	tw.tween_property(m, "global_rotation:y", base - angle_debut * 0.3, duree).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "scale", Vector3.ONE * 1.05, duree)
	tw.tween_property(mat, "albedo_color:a", 0.0, duree).set_delay(duree * 0.4)
	tw.chain().tween_callback(m.queue_free)

## Onde lumineuse au sol (réutilise le shader d'anneau).
static func onde(parent: Node, ou: Vector3, rayon: float, couleur: Color, duree := 0.45) -> void:
	var plan := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(rayon * 2.2, rayon * 2.2)
	plan.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/anneau_sol.gdshader")
	mat.set_shader_parameter("couleur", couleur)
	mat.set_shader_parameter("runes", 0.0)
	plan.material_override = mat
	plan.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(plan)
	plan.global_position = ou + Vector3(0, 0.07, 0)
	var tw := plan.create_tween().set_parallel(true)
	tw.tween_method(func(v): mat.set_shader_parameter("rayon", v), 0.2, 0.92, duree).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(func(v): mat.set_shader_parameter("alpha", v), 1.0, 0.0, duree).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(plan.queue_free)

## Fumée/poussière au sol (atterrissage, ruée).
static func poussiere(parent: Node, ou: Vector3, nombre_part := 10, couleur := Color(0.75, 0.7, 0.65, 0.55)) -> void:
	var p := CPUParticles3D.new()
	p.amount = nombre_part
	p.lifetime = 0.8
	p.one_shot = true
	p.explosiveness = 0.9
	var q := QuadMesh.new()
	q.size = Vector2(1.2, 1.2)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = _tex("smoke_04.png")
	m.albedo_color = couleur
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	q.material = m
	p.mesh = q
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.8
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 2.2
	p.gravity = Vector3(0, 0.4, 0)
	var rampe := Gradient.new()
	rampe.set_color(0, Color(1, 1, 1, 0.8))
	rampe.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = rampe
	var c := Curve.new()
	c.add_point(Vector2(0, 0.6))
	c.add_point(Vector2(1, 1.4))
	p.scale_amount_curve = c
	parent.add_child(p)
	p.global_position = ou + Vector3(0, 0.3, 0)
	p.emitting = true
	parent.get_tree().create_timer(1.4).timeout.connect(p.queue_free)

## Traînée lumineuse attachée à un projectile (les particules restent dans le monde).
static func trainee_lumineuse(porteur: Node3D, couleur: Color) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 24
	p.lifetime = 0.25
	p.local_coords = false
	var q := QuadMesh.new()
	q.size = Vector2(0.35, 0.35)
	var m := _mat_additif(_tex("spark_05.png"), couleur)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = m
	p.mesh = q
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.2
	var rampe := Gradient.new()
	rampe.set_color(0, Color(1, 1, 1, 0.9))
	rampe.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = rampe
	var c := Curve.new()
	c.add_point(Vector2(0, 1))
	c.add_point(Vector2(1, 0.1))
	p.scale_amount_curve = c
	porteur.add_child(p)
	p.emitting = true
	return p

## Micro-pause sur les coups lourds : le temps ralentit une fraction de seconde.
static var _pause_en_cours := false
static func micro_pause(arbre: SceneTree, duree := 0.05, echelle := 0.05) -> void:
	if _pause_en_cours:
		return
	_pause_en_cours = true
	Engine.time_scale = echelle
	await arbre.create_timer(duree, true, false, true).timeout
	Engine.time_scale = 1.0
	_pause_en_cours = false
