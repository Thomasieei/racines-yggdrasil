extends "res://scripts/interface/hud.gd"
## Grande carte : tout le monde connu, les lieux nommés, toi. Touche un endroit pour t'y téléporter
## (ou pour t'y faire guider à pied).

var pouvoirs: Pouvoirs
var _zone: Control
var _cible := Vector2.INF
var _bornes := Rect2()
var _cadre := Rect2(140, 70, 1000, 440)
var _bas: Control

func ouvrir(p: Pouvoirs) -> void:
	pouvoirs = p
	layer = 9
	racine = Control.new()
	racine.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(racine)
	var voile := ColorRect.new()
	voile.color = Color(0.02, 0.02, 0.03, 0.88)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.add_child(voile)
	var cave: bool = p.principale.get("carte") == "crypte"
	texte("Grande carte · " + ("Étage 1, la caverne" if cave else "Le Val des Racines"), 24, Color("#F6CF6A"), Vector2(0, 18), racine, true, 1280, HORIZONTAL_ALIGNMENT_CENTER)
	texte("Touche un endroit pour t'y téléporter (%d mana)." % int(Pouvoirs.LISTE["tp"]["mana"]), 14, Color("#EBDDBB"), Vector2(0, 48), racine, false, 1280, HORIZONTAL_ALIGNMENT_CENTER)
	if cave:
		var mini := Vector2(1e9, 1e9)
		var maxi := Vector2(-1e9, -1e9)
		for v in Caverne.CONTOUR:
			mini = mini.min(v)
			maxi = maxi.max(v)
		_bornes = Rect2(mini, maxi - mini).merge(Rect2(0, 0, 28, 28)).grow(6)
	else:
		_bornes = CarteSurface.LIMITES
	# garder les proportions
	var e := minf(_cadre.size.x / _bornes.size.x, _cadre.size.y / _bornes.size.y)
	var taille := _bornes.size * e
	_cadre = Rect2(Vector2(640, 290) - taille / 2.0, taille)
	_zone = Control.new()
	_zone.position = _cadre.position
	_zone.size = _cadre.size
	_zone.mouse_filter = Control.MOUSE_FILTER_STOP
	_zone.draw.connect(_dessiner)
	_zone.gui_input.connect(_entree)
	racine.add_child(_zone)
	_bas = Control.new()
	racine.add_child(_bas)
	var x := neuf(UI + "rpg/buttonRound_brown.png", 10, Vector2(46, 46), Vector2(1214, 14), racine)
	texte("✕", 20, Color("#FFF4DC"), Vector2(0, 9), x, true, 46, HORIZONTAL_ALIGNMENT_CENTER)
	x.mouse_filter = Control.MOUSE_FILTER_STOP
	x.gui_input.connect(func(ev): if _appui(ev): fermer())
	Jeu.interface_bloquante = true

func fermer() -> void:
	Jeu.interface_bloquante = false
	queue_free()

func _appui(ev) -> bool:
	return (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed)

func _vers_ecran(p: Vector2) -> Vector2:
	return (p - _bornes.position) / _bornes.size * _cadre.size

func _vers_monde(e: Vector2) -> Vector2:
	return _bornes.position + e / _cadre.size * _bornes.size

func _entree(ev) -> void:
	if _appui(ev):
		_cible = _vers_monde(ev.position)
		_zone.queue_redraw()
		_boutons()

func _boutons() -> void:
	for c in _bas.get_children():
		c.queue_free()
	var ok := neuf(UI + "rpg/buttonLong_brown.png", 12, Vector2(260, 48), Vector2(640 - 270, 516), _bas)
	texte("Se téléporter ici", 17, Color("#FFF4DC"), Vector2(0, 12), ok, true, 260, HORIZONTAL_ALIGNMENT_CENTER)
	ok.mouse_filter = Control.MOUSE_FILTER_STOP
	ok.gui_input.connect(func(ev):
		if _appui(ev):
			var c := _cible
			fermer()
			pouvoirs.teleporter(Vector3(c.x, 0, c.y)))
	var guide := neuf(UI + "rpg/buttonLong_beige.png", 12, Vector2(260, 48), Vector2(640 + 10, 516), _bas)
	texte("Y aller à pied", 17, ENCRE, Vector2(0, 12), guide, false, 260, HORIZONTAL_ALIGNMENT_CENTER)
	guide.mouse_filter = Control.MOUSE_FILTER_STOP
	guide.gui_input.connect(func(ev):
		if _appui(ev):
			if Jeu.hud and Jeu.hud.minicarte:
				Jeu.hud.minicarte.cible = _cible
			Jeu.notifier("Destination marquée sur la minicarte", Color("#FFE2A0"))
			fermer())

func _dessiner() -> void:
	_zone.draw_rect(Rect2(Vector2.ZERO, _cadre.size), Color(0.08, 0.1, 0.08) if pouvoirs.principale.get("carte") != "crypte" else Color(0.03, 0.03, 0.05))
	var mc = Jeu.hud.minicarte if Jeu.hud else null
	if mc:
		for f in mc.formes:
			match f["type"]:
				"rect":
					var r: Rect2 = f["r"]
					var a := _vers_ecran(r.position)
					var b := _vers_ecran(r.end)
					_zone.draw_rect(Rect2(a, b - a).intersection(Rect2(Vector2.ZERO, _cadre.size)), f["couleur"])
				"poly":
					var pp := PackedVector2Array()
					for q in f["pts"]:
						pp.append(_vers_ecran(q))
					_zone.draw_colored_polygon(pp, f["couleur"])
				"cercle":
					_zone.draw_circle(_vers_ecran(f["c"]), f["r"] / _bornes.size.x * _cadre.size.x, f["couleur"])
				"ligne":
					var pts: Array = f["pts"]
					for i in pts.size() - 1:
						_zone.draw_line(_vers_ecran(pts[i]), _vers_ecran(pts[i + 1]), f["couleur"], f["largeur"] * 2.0, true)
		for l in mc.lieux:
			var p := _vers_ecran(l["c"])
			var col: Color = {"sur": Color("#F4C35A"), "portail": Color("#7FE3FF"), "elite": Color("#FF9A2E"), "danger": Color("#E5383B"), "sanctuaire": Color("#FFE9A0"), "retour": Color("#FFD36B")}.get(l["genre"], Color.WHITE)
			_zone.draw_circle(p, 9.0, Color(0, 0, 0, 0.7))
			_zone.draw_circle(p, 6.0, col)
	# noms des lieux
	var police := ThemeDB.fallback_font
	var lieux: Array = Caverne.LIEUX if pouvoirs.principale.get("carte") == "crypte" else CarteSurface.LIEUX
	for l in lieux:
		if l.get("rayon", 0.0) > 200.0:
			continue
		var c: Vector3 = l["centre"]
		var p2 := _vers_ecran(Vector2(c.x, c.z)) + Vector2(-90, -14)
		_zone.draw_string_outline(police, p2, l["nom"], HORIZONTAL_ALIGNMENT_CENTER, 180, 13, 4, Color(0, 0, 0, 0.9))
		_zone.draw_string(police, p2, l["nom"], HORIZONTAL_ALIGNMENT_CENTER, 180, 13, Color("#EBDDBB"))
	# toi
	var h: Heros = pouvoirs.h
	var ph := _vers_ecran(Vector2(h.global_position.x, h.global_position.z))
	_zone.draw_circle(ph, 8.0, Color(0, 0, 0, 0.8))
	_zone.draw_circle(ph, 5.5, Color.WHITE)
	# destination
	if _cible != Vector2.INF:
		var pc := _vers_ecran(_cible)
		_zone.draw_arc(pc, 14.0, 0, TAU, 32, Color(0.55, 0.85, 1.0), 3.0, true)
		_zone.draw_circle(pc, 4.0, Color(0.55, 0.85, 1.0))
		_zone.draw_line(ph, pc, Color(0.55, 0.85, 1.0, 0.5), 2.0, true)

func _process(_d: float) -> void:
	if _zone:
		_zone.queue_redraw()
