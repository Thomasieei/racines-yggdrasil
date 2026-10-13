extends Control
## Bouton de compétence tactile.
## Toucher court = lancer vers l'ennemi le plus proche. Glisser = viser (aperçu bleu au sol), relâcher = lancer.
## Glisser puis revenir sur le bouton = annuler. Recharge en balayage horaire, éclat quand le sort revient.

signal appui_long(id: String)

const UI := "res://assets/ui/"
const VFX := "res://assets/vfx/"
const GIVRE := Color("#7FE3FF")

var id := "q"
var icone := "slash_02.png"
var teinte := Color.WHITE
var diametre := 70.0
var heros: Heros

var _doigt := -1
var _depart := Vector2.ZERO
var _vise := false
var _dir := Vector3.ZERO
var _appui_t := 0.0
var _pret_avant := true
var _eclat := 0.0
var _enfonce := 0.0
var _img: TextureRect
var _cadre: TextureRect
var _chiffre: Label
var _compte: Label
var _fond: Control
var _voile: Control

const ZONE_MORTE := 26.0

func preparer(h: Heros, ident: String, ico: String, couleur: Color, d: float) -> void:
	heros = h
	id = ident
	icone = ico
	teinte = couleur
	diametre = d
	size = Vector2(d, d)
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cadre = _image(UI + "aventure/round_brown_dark.png", Vector2(d, d), Vector2.ZERO, Color.WHITE)
	_fond = _calque(_dessiner_fond)
	_img = _image(ico, Vector2(d, d) * 0.62, Vector2(d, d) * 0.19, couleur)
	_voile = _calque(_dessiner_voile)
	_chiffre = Label.new()
	_chiffre.size = Vector2(d, d)
	_chiffre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chiffre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_chiffre.add_theme_font_size_override("font_size", int(d * 0.34))
	_chiffre.add_theme_color_override("font_color", Color.WHITE)
	_chiffre.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_chiffre.add_theme_constant_override("outline_size", 6)
	_chiffre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_chiffre)
	if id == "p":
		_compte = Label.new()
		_compte.position = Vector2(d * 0.58, d * 0.62)
		_compte.add_theme_font_size_override("font_size", 13)
		_compte.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		_compte.add_theme_constant_override("outline_size", 5)
		_compte.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_compte)

## Calque de dessin (les enfants passent au-dessus du _draw du parent, d'où ces calques ordonnés).
func _calque(f: Callable) -> Control:
	var c := Control.new()
	c.size = size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(f)
	add_child(c)
	return c

func _image(chemin: String, t: Vector2, p: Vector2, c: Color) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load(chemin)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.size = t
	r.position = p
	r.modulate = c
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r

func centre_ecran() -> Vector2:
	return global_position + size / 2.0

func _contient(p: Vector2) -> bool:
	return p.distance_to(centre_ecran()) <= diametre * 0.56

func _input(event: InputEvent) -> void:
	if heros == null or Jeu.interface_bloquante:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _doigt == -1 and _contient(event.position):
			_doigt = event.index
			_depart = event.position
			_vise = false
			_appui_t = 0.0
			_enfonce = 1.0
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _doigt:
			_doigt = -1
			heros.cacher_visee()
			var annule := _vise and _contient(event.position)
			if not annule:
				heros.lancer(id, _dir if _vise else null)
			_vise = false
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _doigt:
		var d: Vector2 = event.position - _depart
		if d.length() > ZONE_MORTE and Heros.COMPETENCES[id]["visee"] == "direction":
			_vise = true
			# caméra sans lacet : l'écran et le sol partagent les mêmes axes
			_dir = Vector3(d.x, 0, d.y).normalized()
			if _contient(event.position):
				heros.cacher_visee()
			else:
				heros.montrer_visee(id, _dir)
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if heros == null:
		return
	if _doigt != -1:
		_appui_t += delta
		if _appui_t > 0.55 and not _vise:
			appui_long.emit(id)
			_appui_t = -999.0
	var cd: float = heros.cds[id]
	var total: float = Heros.COMPETENCES[id]["cd"]
	var cout: float = Heros.COMPETENCES[id]["cout"]
	var pret := cd <= 0.0
	if pret and not _pret_avant:
		_eclat = 1.0
		Sons.jouer("pret", heros.global_position, -16.0, 1.3)
	_pret_avant = pret
	_eclat = maxf(0.0, _eclat - delta * 2.2)
	_enfonce = maxf(0.0, _enfonce - delta * 6.0)
	var manque_energie := heros.energie < cout
	var vide := id == "p" and heros.potions <= 0
	if not pret:
		_chiffre.text = str(int(ceil(cd))) if cd >= 1.0 else ("%.1f" % maxf(cd, 0.1)).replace(".", ",")
	else:
		_chiffre.text = ""
	_img.modulate = teinte if (pret and not manque_energie and not vide) else Color(0.55, 0.55, 0.6, 0.75)
	if manque_energie and pret:
		_img.modulate = Color(0.5, 0.62, 1.0, 0.6)
	if _compte:
		_compte.text = "×" + str(heros.potions)
		_compte.add_theme_color_override("font_color", Color.WHITE if heros.potions > 0 else Color("#FF7B6B"))
	scale = Vector2.ONE * (1.0 - _enfonce * 0.08 + _eclat * 0.06)
	_avancement = 1.0 - cd / total if total > 0.0 else 1.0
	_pret = pret and not manque_energie and not vide
	_voile.queue_redraw()

var _avancement := 1.0
var _pret := true

func _dessiner_fond() -> void:
	# fond sombre derrière l'icône : elle ressort toujours
	_fond.draw_circle(size / 2.0, diametre * 0.38, Color(0.09, 0.07, 0.06, 0.95))

func _dessiner_voile() -> void:
	var c := size / 2.0
	var r := diametre * 0.38
	var v := _voile
	if _avancement < 1.0:
		# balayage : la part restante est voilée, dans le sens horaire depuis midi
		var pts := PackedVector2Array([c])
		var debut := -PI / 2.0 + TAU * _avancement
		var n := 40
		for i in n + 1:
			var a := lerpf(debut, -PI / 2.0 + TAU, float(i) / n)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		v.draw_colored_polygon(pts, Color(0, 0, 0, 0.62))
		v.draw_arc(c, r + 1.0, -PI / 2.0, -PI / 2.0 + TAU * _avancement, 48, Color(GIVRE.r, GIVRE.g, GIVRE.b, 0.55), 2.5, true)
	elif _pret:
		v.draw_arc(c, diametre * 0.47, 0, TAU, 64, Color(GIVRE.r, GIVRE.g, GIVRE.b, 0.85), 2.5, true)
	if _eclat > 0.0:
		v.draw_arc(c, diametre * (0.47 + (1.0 - _eclat) * 0.25), 0, TAU, 64, Color(1, 0.95, 0.75, _eclat), 4.0 * _eclat + 1.0, true)
