extends "res://scripts/interface/hud.gd"
## Codex des réalisations : parchemin beige, encre noire, une ligne par réalisation avec sa
## progression et les points qu'elle rapporte. Les secrets ne montrent qu'un indice.

var heros: Heros
var ouvert := false
var _panneau: Control
var _liste: VBoxContainer
var _onglets: Control
var _entete: Control
var _cat := "Chasse"

func _ready() -> void:
	layer = 8
	racine = Control.new()
	racine.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(racine)
	var voile := ColorRect.new()
	voile.color = Color(0.02, 0.02, 0.03, 0.72)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.add_child(voile)
	_panneau = neuf(UI + "rpg/panel_beige.png", 18, Vector2(1000, 528), Vector2(140, 24))
	_entete = Control.new()
	_panneau.add_child(_entete)
	_onglets = Control.new()
	_onglets.position = Vector2(24, 70)
	_panneau.add_child(_onglets)
	var creux := neuf(UI + "rpg/panelInset_beigeLight.png", 14, Vector2(952, 400), Vector2(24, 112), _panneau)
	var defile := ScrollContainer.new()
	defile.position = Vector2(8, 8)
	defile.size = Vector2(936, 384)
	defile.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	creux.add_child(defile)
	_liste = VBoxContainer.new()
	_liste.custom_minimum_size = Vector2(920, 0)
	_liste.add_theme_constant_override("separation", 6)
	defile.add_child(_liste)
	racine.visible = false

func brancher(h: Heros) -> void:
	heros = h

func basculer() -> void:
	if ouvert:
		fermer()
	else:
		ouvrir()

func ouvrir() -> void:
	ouvert = true
	Jeu.interface_bloquante = true
	racine.visible = true
	_rafraichir()
	Sons.jouer("tissu", heros.global_position if heros else Vector3.ZERO, -6.0, 0.9)

func fermer() -> void:
	ouvert = false
	Jeu.interface_bloquante = false
	racine.visible = false

func _vider(c: Control) -> void:
	for x in c.get_children():
		x.queue_free()

func _clic(c: Control, f: Callable) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.gui_input.connect(func(ev):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			f.call())

func _rafraichir() -> void:
	var pr := Profil.p()
	_vider(_entete)
	_vider(_onglets)
	_vider(_liste)
	image("res://assets/icones_sorts/codex.svg", Vector2(44, 44), Vector2(22, 14), _entete)
	texte("Codex", 26, ENCRE, Vector2(76, 18), _entete, false)
	var faites := pr.obtenues.size()
	texte("%d réalisations accomplies · %d points gagnés" % [faites, pr.points_gagnes], 14, ENCRE2, Vector2(190, 28), _entete, false)
	texte("Les points se placent dans l'Arbre des Racines.", 12, Color("#7A4F0C"), Vector2(190, 48), _entete, false)
	var x := neuf(UI + "rpg/buttonRound_brown.png", 10, Vector2(42, 42), Vector2(944, 12), _entete)
	texte("✕", 18, Color("#FFF4DC"), Vector2(0, 8), x, true, 42, HORIZONTAL_ALIGNMENT_CENTER)
	_clic(x, func(): fermer())
	# onglets
	for i in Codex.CATEGORIES.size():
		var c: String = Codex.CATEGORIES[i]
		var actif := c == _cat
		var b := neuf(UI + "rpg/" + ("buttonLong_brown" if actif else "buttonLong_beige") + ".png", 12, Vector2(172, 36), Vector2(i * 182, 0), _onglets)
		var n := 0
		var tot := 0
		for r in Codex.LISTE:
			if r["cat"] == c:
				tot += 1
				if pr.obtenues.has(r["id"]):
					n += 1
		texte("%s  %d/%d" % [c, n, tot] if c != "Secrets" else "%s  %d/?" % [c, n], 14, Color("#FFF4DC") if actif else ENCRE, Vector2(0, 8), b, actif, 172, HORIZONTAL_ALIGNMENT_CENTER)
		_clic(b, func(): _cat = c; _rafraichir())
	# lignes : accomplies en bas, les plus proches du but en haut
	var lignes: Array = Codex.LISTE.filter(func(r): return r["cat"] == _cat)
	lignes.sort_custom(func(a, b):
		var fa := pr.obtenues.has(a["id"])
		var fb := pr.obtenues.has(b["id"])
		if fa != fb:
			return fb
		return float(pr.valeur(a["compteur"])) / a["but"] > float(pr.valeur(b["compteur"])) / b["but"])
	for r in lignes:
		_ligne(r)

func _ligne(r: Dictionary) -> void:
	var pr := Profil.p()
	var fait := pr.obtenues.has(r["id"])
	var cache: bool = r.get("cache", false) and not fait
	var l := Control.new()
	l.custom_minimum_size = Vector2(920, 66)
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	_liste.add_child(l)
	var fond := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.93, 0.80, 0.9) if fait else Color(1, 1, 1, 0.35)
	sb.border_color = Color("#C9A24A") if fait else Color(0.55, 0.42, 0.25, 0.35)
	sb.set_border_width_all(2 if fait else 1)
	sb.set_corner_radius_all(8)
	fond.add_theme_stylebox_override("panel", sb)
	fond.size = Vector2(920, 66)
	fond.mouse_filter = Control.MOUSE_FILTER_PASS
	l.add_child(fond)
	# médaille
	disque(Vector2(10, 9), 48, Color("#2A1E12") if fait else Color(0.35, 0.28, 0.2, 0.5), l)
	if cache:
		texte("?", 26, Color("#E8D9B5"), Vector2(10, 16), l, false, 48, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		var ic := image("res://assets/icones_sorts/point.svg", Vector2(32, 32), Vector2(18, 17), l)
		ic.modulate = Color.WHITE if fait else Color(0.6, 0.55, 0.5, 0.6)
	texte("Secret" if cache else r["nom"], 17, ENCRE, Vector2(72, 8), l, false)
	texte(r.get("indice", "") if cache else r["texte"], 13, ENCRE2, Vector2(72, 32), l, false)
	# progression
	if not cache:
		var v: int = mini(pr.valeur(r["compteur"]), r["but"])
		var bx := 560.0
		var bar := ColorRect.new()
		bar.color = Color(0.35, 0.25, 0.12, 0.25)
		bar.position = Vector2(bx, 28)
		bar.size = Vector2(220, 10)
		bar.mouse_filter = Control.MOUSE_FILTER_PASS
		l.add_child(bar)
		var plein := ColorRect.new()
		plein.color = Color("#D9A33A") if not fait else Color("#5E9E4A")
		plein.position = Vector2(bx, 28)
		plein.size = Vector2(220.0 * v / r["but"], 10)
		plein.mouse_filter = Control.MOUSE_FILTER_PASS
		l.add_child(plein)
		var txt := "Accompli" if fait else ("%d / %d" % [v, r["but"]] if r["but"] > 1 else "À faire")
		texte(txt, 12, Color("#2E6A2C") if fait else ENCRE2, Vector2(bx, 42), l, false, 220, HORIZONTAL_ALIGNMENT_CENTER)
	# récompense
	var pts := neuf(UI + "rpg/buttonRound_beige.png", 10, Vector2(56, 44), Vector2(846, 11), l)
	pts.mouse_filter = Control.MOUSE_FILTER_PASS
	texte("+%d" % r["pts"], 17, Color("#8A5A10") if not fait else Color("#5A7A3A"), Vector2(0, 10), pts, false, 56, HORIZONTAL_ALIGNMENT_CENTER)
