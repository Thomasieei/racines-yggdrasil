extends CanvasLayer
## Interface du récit : boîte de dialogue (portrait 3D vivant), bandeau d'entrée de zone, suivi de quête.

signal dialogue_fini

const UI := "res://assets/ui/"
const OR := Color("#F4C35A")
const ENCRE := Color("#2A1D0C")
const ENCRE2 := Color("#6B4C22")

var _boite: Control
var _nom: Label
var _texte: Label
var _suite: Label
var _portrait_vp: SubViewport
var _portrait_modele: Node3D
var _lignes: Array = []
var _i := 0
var _ecrit := 0.0
var _actif := false
var _progres := 0.0     ## part du texte affichée (le getter de visible_ratio n'atteint pas toujours 1)

var _bandeau: Control
var _bandeau_titre: Label
var _bandeau_sous: Label
var _bandeau_tw: Tween

var _quete: Control
var _quete_titre: Label
var _quete_obj: Label
var cible_quete := Vector3.INF
var heros: Node3D

func _ready() -> void:
	layer = 3
	_construire_dialogue()
	_construire_bandeau()
	_construire_quete()

# ================= dialogue =================

func _construire_dialogue() -> void:
	_boite = Control.new()
	_boite.position = Vector2(190, 418)
	_boite.size = Vector2(700, 140)
	_boite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_boite)
	var fond := _neuf(UI + "rpg/panel_beigeLight.png", 18, Vector2(640, 128), Vector2(60, 8), _boite)
	fond.modulate = Color(1, 0.98, 0.94, 0.97)
	# portrait rond qui déborde à gauche
	var cadre := TextureRect.new()
	cadre.texture = load(UI + "aventure/round_brown.png")
	cadre.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cadre.size = Vector2(124, 124)
	cadre.position = Vector2(0, 8)
	cadre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boite.add_child(cadre)
	_portrait_vp = SubViewport.new()
	_portrait_vp.size = Vector2i(256, 256)
	_portrait_vp.own_world_3d = true
	_portrait_vp.transparent_bg = true
	_portrait_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_portrait_vp)
	var portrait := TextureRect.new()
	portrait.texture = _portrait_vp.get_texture()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.size = Vector2(98, 98)
	portrait.position = Vector2(13, 21)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nvoid fragment(){ vec4 c = texture(TEXTURE, UV); float d = length(UV - 0.5); COLOR = vec4(mix(vec3(0.16,0.12,0.09), c.rgb, c.a), smoothstep(0.5, 0.48, d)); }"
	var m := ShaderMaterial.new()
	m.shader = sh
	portrait.material = m
	_boite.add_child(portrait)
	_nom = _label("", 20, Color("#8A5A12"), Vector2(140, 18), _boite)
	_texte = _label("", 16, ENCRE, Vector2(140, 48), _boite)
	_texte.size = Vector2(540, 70)
	_texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_suite = _label("Toucher pour continuer  ▸", 12, Color(ENCRE2.r, ENCRE2.g, ENCRE2.b, 0.8), Vector2(500, 110), _boite)
	_boite.visible = false

func _portrait(role: String) -> void:
	for c in _portrait_vp.get_children():
		c.queue_free()
	var fichier: String = {"freya": "freya.glb", "garde": "chevalier.glb", "marchand": "marchand.glb", "forgeron": "barbare.glb"}.get(role, "freya.glb")
	_portrait_modele = load("res://assets/personnages/" + fichier).instantiate()
	_portrait_vp.add_child(_portrait_modele)
	for n in ["Spellbook", "Spellbook_open", "1H_Wand", "2H_Staff", "Knife", "Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Throwable", "1H_Axe", "1H_Axe_Offhand", "2H_Axe", "Barbarian_Round_Shield", "Mug", "1H_Sword", "1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Spike_Shield", "Round_Shield", "2H_Sword"]:
		var x := _portrait_modele.find_child(n, true, false)
		if x:
			x.visible = false
	var ap: AnimationPlayer = _portrait_modele.find_child("AnimationPlayer", true, false)
	if ap and ap.has_animation("Idle"):
		ap.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
		ap.play("Idle")
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.95, 1.75)
	cam.rotation_degrees.x = -8
	cam.fov = 30
	_portrait_vp.add_child(cam)
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-30, 30, 0)
	l.light_energy = 1.3
	l.light_color = Color(1.0, 0.9, 0.75)
	_portrait_vp.add_child(l)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.65, 0.8)
	env.environment.ambient_light_energy = 0.7
	_portrait_vp.add_child(env)

## Lance un dialogue. lignes = textes. Attendre `dialogue_fini`.
func dire(nom: String, role: String, lignes: Array) -> void:
	_lignes = lignes
	_i = 0
	_nom.text = nom
	_portrait(role)
	_boite.visible = true
	_boite.modulate.a = 0.0
	create_tween().tween_property(_boite, "modulate:a", 1.0, 0.25)
	_actif = true
	_montrer_ligne()

func en_cours() -> bool:
	return _actif

func _montrer_ligne() -> void:
	_texte.text = _lignes[_i]
	_texte.visible_ratio = 0.0
	_ecrit = 0.0
	_progres = 0.0

func avancer() -> void:
	if not _actif:
		return
	if _progres < 1.0:
		_progres = 1.0
		_texte.visible_ratio = 1.0
		return
	_i += 1
	Sons.jouer("tissu", heros.global_position if heros else Vector3.ZERO, -14.0, 1.4)
	if _i >= _lignes.size():
		_actif = false
		var tw := create_tween()
		tw.tween_property(_boite, "modulate:a", 0.0, 0.2)
		tw.tween_callback(func(): _boite.visible = false)
		dialogue_fini.emit()
	else:
		_montrer_ligne()

func _input(event: InputEvent) -> void:
	if not _actif:
		return
	if event is InputEventScreenTouch and event.pressed and event.position.x > 190 and event.position.x < 900:
		avancer()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_SPACE]:
		avancer()
		get_viewport().set_input_as_handled()

# ================= voix (sous-titre qui ne bloque pas le jeu) =================

var _voix: Control
var _voix_texte: Label
var _voix_tw: Tween

func voix(nom: String, t: String, duree := 4.0) -> void:
	if _voix == null:
		_voix = Control.new()
		_voix.position = Vector2(0, 360)
		_voix.size = Vector2(1280, 40)
		_voix.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_voix)
		_voix_texte = _label("", 17, Color("#FFF4DC"), Vector2(0, 0), _voix, true)
		_voix_texte.size.x = 1280
		_voix_texte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_voix_texte.text = nom + " : « " + t + " »"
	_voix_texte.add_theme_color_override("font_color", Color("#FFF4DC"))
	if _voix_tw:
		_voix_tw.kill()
	_voix.modulate.a = 0.0
	_voix_tw = create_tween()
	_voix_tw.tween_property(_voix, "modulate:a", 1.0, 0.3)
	_voix_tw.tween_property(_voix, "modulate:a", 0.0, 0.6).set_delay(duree)

# ================= bandeau de zone =================

func _construire_bandeau() -> void:
	_bandeau = Control.new()
	_bandeau.position = Vector2(0, 118)
	_bandeau.size = Vector2(1280, 90)
	_bandeau.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bandeau)
	var ligne := ColorRect.new()
	ligne.color = Color(OR.r, OR.g, OR.b, 0.65)
	ligne.position = Vector2(440, 50)
	ligne.size = Vector2(400, 2)
	_bandeau.add_child(ligne)
	_bandeau_titre = _label("", 34, Color("#FFF1D0"), Vector2(0, 4), _bandeau, true)
	_bandeau_titre.size.x = 1280
	_bandeau_titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bandeau_sous = _label("", 15, OR, Vector2(0, 58), _bandeau, true)
	_bandeau_sous.size.x = 1280
	_bandeau_sous.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bandeau.modulate.a = 0.0

func bandeau(titre: String, sous: String, couleur_sous := OR) -> void:
	_bandeau_titre.text = titre
	_bandeau_sous.text = sous
	_bandeau_sous.add_theme_color_override("font_color", couleur_sous)
	if _bandeau_tw:
		_bandeau_tw.kill()
	_bandeau.position.y = 128
	_bandeau_tw = create_tween()
	_bandeau_tw.set_parallel(true)
	_bandeau_tw.tween_property(_bandeau, "modulate:a", 1.0, 0.6)
	_bandeau_tw.tween_property(_bandeau, "position:y", 118.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_bandeau_tw.chain().tween_property(_bandeau, "modulate:a", 0.0, 0.9).set_delay(2.6)

# ================= suivi de quête =================

func _construire_quete() -> void:
	_quete = Control.new()
	_quete.position = Vector2(16, 96)
	_quete.size = Vector2(300, 60)
	_quete.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_quete)
	var fond := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.08, 0.62)
	sb.border_color = Color(OR.r, OR.g, OR.b, 0.35)
	sb.border_width_left = 3
	sb.set_corner_radius_all(6)
	fond.add_theme_stylebox_override("panel", sb)
	fond.size = Vector2(290, 52)
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quete.add_child(fond)
	_quete_titre = _label("", 15, OR, Vector2(12, 5), _quete, true)
	_quete_obj = _label("", 13, Color("#E9E2D2"), Vector2(12, 27), _quete, true)
	_quete.visible = false

func quete(titre: String, objectif: String, cible := Vector3.INF) -> void:
	_quete.visible = true
	_quete_titre.text = "◆ " + titre
	_quete_obj.text = objectif
	cible_quete = cible
	_quete.modulate = Color(1.6, 1.4, 1.0)
	create_tween().tween_property(_quete, "modulate", Color.WHITE, 0.8)
	Sons.jouer("pret", heros.global_position if heros else Vector3.ZERO, -8.0, 0.9)

var _objectif_base := ""
func quete_objectif(t: String) -> void:
	_quete_obj.text = t

func _process(_d: float) -> void:
	if _actif and _progres < 1.0:
		_ecrit += _d
		_progres = minf(1.0, _ecrit * 55.0 / maxf(1.0, _texte.text.length()))
		_texte.visible_ratio = _progres
	_suite.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005) if _progres >= 1.0 else 0.0

# ================= briques =================

func _neuf(chemin: String, marge: int, taille: Vector2, pos: Vector2, parent: Control) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = load(chemin)
	n.patch_margin_left = marge
	n.patch_margin_right = marge
	n.patch_margin_top = marge
	n.patch_margin_bottom = marge
	n.size = taille
	n.position = pos
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(n)
	return n

func _label(t: String, taille: int, c: Color, pos: Vector2, parent: Control, contour := false) -> Label:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", c)
	if contour:
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l
