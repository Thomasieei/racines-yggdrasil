extends CanvasLayer
## Éclosion d'un œuf de dragon : l'œuf tremble de plus en plus, se fissure, éclate dans la couleur
## du dragon obtenu, puis le bébé apparaît en tournant, avec sa rareté et ses étoiles.
## Le suspense compte : on ne connaît la couleur qu'à l'éclat final.

var _vp: SubViewport
var _oeuf: Node3D
var _dragon: Node3D
var _mats: Array = []
var _titre: Label
var _sous: Label
var _boutons: Control
var _flash: ColorRect
var _rappel: Callable

func lancer(oeuf: Dictionary, dragon: Dictionary, rappel: Callable) -> void:
	layer = 20
	_rappel = rappel
	var fond := ColorRect.new()
	fond.color = Color(0.02, 0.02, 0.05, 0.92)
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	fond.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fond)
	_vp = SubViewport.new()
	_vp.size = Vector2i(420, 420)
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.72, 0.85)
	env.environment.ambient_light_energy = 0.7
	env.environment.glow_enabled = false
	_vp.add_child(env)
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-35, 30, 0)
	l.light_energy = 1.3
	_vp.add_child(l)
	var cam := Camera3D.new()
	cam.fov = 32
	cam.position = Vector3(0, 0.9, 3.9)
	cam.rotation_degrees.x = -6
	_vp.add_child(cam)
	var tex := TextureRect.new()
	tex.texture = _vp.get_texture()
	tex.size = Vector2(420, 420)
	tex.position = Vector2(640 - 210, 40)
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fond.add_child(tex)
	_oeuf = DragonVisuel.oeuf(oeuf["rarete"])
	_oeuf.position.y = 0.2
	_vp.add_child(_oeuf)
	_mats = _oeuf.get_meta("mats")
	_titre = _lab("", 30, Color.WHITE, 446, fond)
	_sous = _lab("L'œuf s'agite…", 17, Color("#CFD6EE"), 488, fond)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	_boutons = Control.new()
	fond.add_child(_boutons)
	_sequence(oeuf, dragon)

func _lab(t: String, taille: int, c: Color, y: float, parent: Control) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", c)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.position = Vector2(0, y)
	l.size = Vector2(1280, 40)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _sequence(oeuf: Dictionary, d: Dictionary) -> void:
	# 1. tremblements qui s'accélèrent, fissures qui gagnent
	var duree := 2.6
	var t := 0.0
	while t < duree:
		await get_tree().process_frame
		var dt := get_process_delta_time()
		t += dt
		var k := t / duree
		var amp := 0.03 + k * k * 0.22
		_oeuf.rotation.z = sin(t * (14.0 + k * 30.0)) * amp
		_oeuf.position.y = 0.2 + absf(sin(t * 9.0)) * 0.04 * k
		for m in _mats:
			m.set_shader_parameter("fissure", k * 0.9)
			m.set_shader_parameter("eclat", 0.8 + k * 0.8)
		if fmod(t, 0.5) < dt:
			Sons.jouer("verre_leger", Vector3.ZERO, -8.0 + k * 6.0, 0.8 + k * 0.6)
	# 2. éclat dans la couleur du dragon
	var c: Color = Objets.COULEURS[d["rarete"]]
	Sons.jouer("verre_lourd", Vector3.ZERO, 2.0, 0.8)
	_flash.color = Color(c.r, c.g, c.b, 0.9)
	create_tween().tween_property(_flash, "color:a", 0.0, 0.9)
	_oeuf.queue_free()
	_dragon = DragonVisuel.bebe(d["rarete"])
	_dragon.scale = Vector3.ONE * 0.05
	_vp.add_child(_dragon)
	var tw := create_tween()
	tw.tween_property(_dragon, "scale", Vector3.ONE * 0.85, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	var lum := OmniLight3D.new()
	lum.light_color = c
	lum.light_energy = 3.0
	lum.position = Vector3(0, 1.0, 1.0)
	_vp.add_child(lum)
	# 3. révélation
	var rare := Objets.RARETES.find(d["rarete"]) >= 2
	_titre.text = d["nom"] + ("  !!!" if rare else "")
	_titre.add_theme_color_override("font_color", c.lightened(0.2))
	var p: int = d.get("puissance", 1)
	_sous.text = "Puissance " + "★".repeat(p) + "☆".repeat(5 - p) + "   ·   " + ["faible", "correct", "fort", "très fort", "exceptionnel"][p - 1] + "   ·   valeur %d or" % d["valeur"]
	if rare:
		Sons.jouer("cloche", Vector3.ZERO, 0.0, 1.2)
	await get_tree().create_timer(0.6).timeout
	_bouton("Équiper comme acolyte", Vector2(640 - 250, 524), true)
	_bouton("Garder dans le sac", Vector2(640 + 10, 524), false)

func _process(delta: float) -> void:
	if _dragon and is_instance_valid(_dragon):
		_dragon.rotation.y += delta * 0.8

func _bouton(t: String, pos: Vector2, equiper: bool) -> void:
	var b := NinePatchRect.new()
	b.texture = load("res://assets/ui/rpg/buttonLong_" + ("brown" if equiper else "beige") + ".png")
	for m in ["patch_margin_left", "patch_margin_right", "patch_margin_top", "patch_margin_bottom"]:
		b.set(m, 12)
	b.position = pos
	b.size = Vector2(240, 44)
	_boutons.add_child(b)
	var l := Label.new()
	l.text = t
	l.size = Vector2(240, 44)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color("#FFF4DC") if equiper else Color("#2A1D0C"))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l)
	b.gui_input.connect(func(ev):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			_rappel.call(equiper)
			queue_free())
