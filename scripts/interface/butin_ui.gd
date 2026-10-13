extends "res://scripts/interface/hud.gd"
## Fenêtre de butin (coffre ouvert, dépouille fouillée) : chaque objet avec sa couleur de rareté,
## l'or, la valeur totale, « Tout prendre ». Toucher un objet le prend seul.

var heros: Heros
var contenu: Dictionary
var _p: Control

func _ready() -> void:
	layer = 9
	racine = Control.new()
	racine.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(racine)

func montrer(titre: String, c: Dictionary, h: Heros, couleur: Color) -> void:
	heros = h
	contenu = c
	Jeu.interface_bloquante = true
	_dessiner(titre, couleur)
	if h.has_meta("pilote_auto"):
		# démonstration filmée : le pilote prend tout après avoir montré la fenêtre
		await get_tree().create_timer(1.8).timeout
		if is_instance_valid(self) and (not contenu["objets"].is_empty() or contenu["or"] > 0):
			_prendre(contenu["objets"].duplicate(), titre, couleur, true)

func _dessiner(titre: String, couleur: Color) -> void:
	for x in racine.get_children():
		x.queue_free()
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.45)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.add_child(voile)
	_p = neuf(UI + "rpg/panel_beige.png", 18, Vector2(560, 330), Vector2(360, 110))
	texte(titre, 22, couleur.darkened(0.35), Vector2(24, 16), _p, false)
	var v := int(contenu["or"])
	for o in contenu["objets"]:
		v += o["valeur"] * o["qte"]
	texte("Valeur estimée : %d or" % v, 13, ENCRE2, Vector2(24, 48), _p, false)
	var x := 24.0
	var y := 78.0
	if contenu["or"] > 0:
		image("res://assets/icones_objets/pieces_or.png", Vector2(56, 56), Vector2(x, y), _p)
		texte("%d" % contenu["or"], 13, Color.WHITE, Vector2(x, y + 40), _p, true, 56, HORIZONTAL_ALIGNMENT_RIGHT)
		x += 66
	for o in contenu["objets"]:
		var zone := Control.new()
		zone.position = Vector2(x, y)
		zone.size = Vector2(60, 60)
		zone.mouse_filter = Control.MOUSE_FILTER_STOP
		_p.add_child(zone)
		var c := Objets.couleur(o)
		var fond := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(c.r, c.g, c.b, 0.26)
		sb.border_color = c
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(8)
		fond.add_theme_stylebox_override("panel", sb)
		fond.size = Vector2(60, 60)
		fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
		zone.add_child(fond)
		image(o["icone"], Vector2(48, 48), Vector2(6, 6), zone)
		if o["qte"] > 1:
			texte(str(o["qte"]), 12, Color.WHITE, Vector2(0, 40), zone, true, 54, HORIZONTAL_ALIGNMENT_RIGHT)
		zone.gui_input.connect(func(ev):
			if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
				_prendre([o], titre, couleur))
		x += 68
		if x > 500:
			x = 24.0
			y += 68
	if contenu["objets"].is_empty() and contenu["or"] <= 0:
		texte("Vide.", 15, ENCRE2, Vector2(24, 90), _p, false)
	_btn("Tout prendre", Vector2(24, 268), true, func(): _prendre(contenu["objets"].duplicate(), titre, couleur, true))
	_btn("Fermer", Vector2(296, 268), false, func(): fermer())

func _btn(t: String, pos: Vector2, principal: bool, f: Callable) -> void:
	var b := neuf(UI + "rpg/buttonLong_" + ("brown" if principal else "beige") + ".png", 12, Vector2(240, 44), pos, _p)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	texte(t, 16, Color("#FFF4DC") if principal else ENCRE, Vector2(0, 11), b, principal, 240, HORIZONTAL_ALIGNMENT_CENTER)
	b.gui_input.connect(func(ev):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			f.call())

func _prendre(liste: Array, titre: String, couleur: Color, avec_or := false) -> void:
	var b := {"or": contenu["or"] if avec_or or liste.size() == contenu["objets"].size() else 0, "objets": liste}
	var reste: Dictionary = heros.ramasser(b)
	if b["or"] > 0:
		contenu["or"] = 0
	for o in liste:
		if not reste["objets"].has(o):
			contenu["objets"].erase(o)
	if not reste["objets"].is_empty():
		Jeu.notifier("Sac plein !", Color("#FF8A7A"))
	if contenu["objets"].is_empty() and contenu["or"] <= 0:
		fermer()
	else:
		_dessiner(titre, couleur)

func fermer() -> void:
	Jeu.interface_bloquante = false
	queue_free()
