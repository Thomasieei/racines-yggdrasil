extends "res://scripts/interface/hud.gd"
## L'Arbre des Racines. Fond noir chaud, racines dorées qui descendent du tronc d'Yggdrasil,
## quinze talents en trois racines et cinq paliers. Les chemins investis brillent doucement,
## une lueur court le long des racines. À droite, la fiche du talent touché (beige, lisible).

const NOIR := Color("#100C08")
const BEIGE := Color("#EBDDBB")
const OR_VIF := Color("#F6CF6A")
const OR_SOMBRE := Color("#8A6526")
const ETEINT := Color("#4A4036")

const COLONNES := [170.0, 430.0, 690.0]
const LIGNES := [150.0, 232.0, 314.0, 396.0, 482.0]
const TRONC := Vector2(430, 78)

var heros: Heros
var ouvert := false
var _toile: Control
var _fiche: Control
var _entete: Control
var _choix := "morsure"
var _t := 0.0
var _noeuds := {}       ## id -> centre

func _ready() -> void:
	layer = 8
	racine = Control.new()
	racine.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(racine)
	var fond := ColorRect.new()
	fond.color = NOIR
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.add_child(fond)
	_toile = Control.new()
	_toile.set_anchors_preset(Control.PRESET_FULL_RECT)
	_toile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toile.draw.connect(_dessiner)
	racine.add_child(_toile)
	_entete = Control.new()
	racine.add_child(_entete)
	_fiche = Control.new()
	_fiche.position = Vector2(880, 92)
	racine.add_child(_fiche)
	for t in Talents.LISTE:
		_noeuds[t["id"]] = Vector2(COLONNES[t["racine"]], LIGNES[t["palier"]])
	racine.visible = false
	Profil.p().change.connect(func(): if ouvert: _rafraichir())

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
	Sons.jouer("pret", heros.global_position if heros else Vector3.ZERO, -8.0, 0.8)

func fermer() -> void:
	ouvert = false
	Jeu.interface_bloquante = false
	racine.visible = false
	Profil.p().sauver()

func _process(delta: float) -> void:
	if ouvert:
		_t += delta
		_toile.queue_redraw()

# ---------------- construction ----------------

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
	# titre
	texte("Arbre des Racines", 26, BEIGE, Vector2(30, 18), _entete, true)
	texte("Chaque point compte : tes choix dessinent ton aventurier.", 13, Color(BEIGE.r, BEIGE.g, BEIGE.b, 0.6), Vector2(32, 52), _entete, false)
	# points
	image("res://assets/icones_sorts/point.svg", Vector2(30, 30), Vector2(880, 22), _entete)
	var libres := pr.points_libres()
	texte("%d point%s à placer" % [libres, "s" if libres > 1 else ""], 18, OR_VIF if libres > 0 else BEIGE, Vector2(916, 24), _entete, true)
	texte("%d investis" % pr.points_investis(), 12, Color(BEIGE.r, BEIGE.g, BEIGE.b, 0.55), Vector2(918, 50), _entete, false)
	var fermer_b := _bouton_simple("✕", Vector2(1220, 16), Vector2(42, 42), func(): fermer())
	fermer_b.get_child(0).add_theme_font_size_override("font_size", 18)
	if pr.points_investis() > 0:
		_bouton_simple("Réinitialiser · 200 or", Vector2(1040, 46), Vector2(168, 30), func(): _reinitialiser(), 12)
	# noms des racines
	for i in 3:
		var r: Dictionary = Talents.RACINES[i]
		texte(r["nom"], 15, r["couleur"], Vector2(COLONNES[i] + 40, LIGNES[0] - 22), _entete, true)
		texte(r["sous"], 11, Color(BEIGE.r, BEIGE.g, BEIGE.b, 0.55), Vector2(COLONNES[i] + 40, LIGNES[0] - 2), _entete, false)
	# seuils des paliers, à gauche
	for k in 5:
		var seuil: int = Talents.SEUILS[k]
		var ouvert_p: bool = pr.points_investis() >= seuil
		texte(("%d" % seuil) if k > 0 else "", 13, OR_VIF if ouvert_p else ETEINT, Vector2(18, LIGNES[k] - 9), _entete, false, 40, HORIZONTAL_ALIGNMENT_CENTER)
		if k > 0:
			texte("pts", 9, OR_SOMBRE if ouvert_p else ETEINT, Vector2(18, LIGNES[k] + 7), _entete, false, 40, HORIZONTAL_ALIGNMENT_CENTER)
	texte("ULTIME · un seul au choix", 10, Color(1, 0.75, 0.45, 0.7), Vector2(COLONNES[2] + 40, LIGNES[4] - 6), _entete, false)
	# talents
	for t in Talents.LISTE:
		_noeud(t)
	_remplir_fiche()

func _bouton_simple(t: String, pos: Vector2, taille: Vector2, f: Callable, police := 16) -> Control:
	var b := neuf(UI + "rpg/buttonLong_brown.png", 12, taille, pos, _entete)
	texte(t, police, Color("#FFF4DC"), Vector2(0, taille.y / 2 - police * 0.75), b, true, taille.x, HORIZONTAL_ALIGNMENT_CENTER)
	_clic(b, f)
	return b

func _noeud(t: Dictionary) -> void:
	var pr := Profil.p()
	var c: Vector2 = _noeuds[t["id"]]
	var d := 66.0 if t.get("ultime", false) else 58.0
	var zone := Control.new()
	zone.position = c - Vector2(d, d) / 2.0
	zone.size = Vector2(d, d)
	_entete.add_child(zone)
	var r := pr.rang(t["id"])
	var accessible: bool = pr.points_investis() >= Talents.SEUILS[t["palier"]]
	var ico := image(Talents.icone(t["id"]), Vector2(d, d) * 0.66, Vector2(d, d) * 0.17, zone)
	if r == 0:
		ico.modulate = Color(1, 1, 1, 0.9) if accessible else Color(0.45, 0.42, 0.4, 0.55)
	# rang sous le nœud
	var coul := OR_VIF if r > 0 else (BEIGE if accessible else ETEINT)
	texte("%d/%d" % [r, t["rangs"]], 12, coul, Vector2(-10, d + 2), zone, true, d + 20, HORIZONTAL_ALIGNMENT_CENTER)
	_clic(zone, func():
		_choix = t["id"]
		Sons.jouer("tissu", heros.global_position if heros else Vector3.ZERO, -14.0, 1.4)
		_rafraichir())

func _remplir_fiche() -> void:
	_vider(_fiche)
	var pr := Profil.p()
	var t := Talents.par_id(_choix)
	var f := neuf(UI + "rpg/panel_beigeLight.png", 16, Vector2(380, 464), Vector2.ZERO, _fiche)
	var rac: Dictionary = Talents.RACINES[t["racine"]]
	# médaillon
	disque(Vector2(18, 18), 92, Color(0.07, 0.055, 0.04), f)
	image(Talents.icone(t["id"]), Vector2(70, 70), Vector2(29, 29), f)
	var nom := texte(t["nom"], 22, ENCRE, Vector2(124, 20), f, false, 240)
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texte(rac["nom"] + (" · Ultime" if t.get("ultime", false) else " · palier %d" % (t["palier"] + 1)), 13, rac["couleur"].darkened(0.35), Vector2(124, 52), f, false)
	var r := pr.rang(t["id"])
	texte("Rang %d / %d" % [r, t["rangs"]], 15, Color("#7A4F0C"), Vector2(124, 74), f, false)
	# pastilles de rang
	for i in t["rangs"]:
		var p := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#E0A93A") if i < r else Color(0.55, 0.45, 0.32, 0.25)
		sb.border_color = Color("#6B4C22")
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(5)
		p.add_theme_stylebox_override("panel", sb)
		p.position = Vector2(124 + i * 22, 98)
		p.size = Vector2(16, 10)
		f.add_child(p)
	var y := 136.0
	var desc := texte(Talents.description(t, maxi(r, 1)), 15, ENCRE, Vector2(22, y), f, false, 336)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	y += 70.0
	if t["rangs"] > 1:
		if r > 0:
			texte("Actuel : " + Talents.format_val(t, r), 14, Color("#2E6A2C"), Vector2(22, y), f, false)
			y += 22.0
		if r < t["rangs"]:
			texte("Rang suivant : " + Talents.format_val(t, r + 1), 14, ENCRE2, Vector2(22, y), f, false)
			y += 22.0
	var refus := pr.refus_talent(t["id"])
	if refus != "" and refus != "Talent au maximum":
		var l := texte(refus, 13, Color("#A04030"), Vector2(22, y + 8), f, false, 336)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# bouton
	var possible := refus == ""
	var b := neuf(UI + "rpg/" + ("buttonLong_brown" if possible else "buttonLong_grey") + ".png", 12, Vector2(336, 50), Vector2(22, 392), f)
	var ct := Profil.cout(t["id"])
	texte(("Investir %d point%s" % [ct, "s" if ct > 1 else ""]) if r < t["rangs"] else "Maîtrisé", 18, Color("#FFF4DC") if possible else Color("#E4E4E4"), Vector2(0, 13), b, true, 336, HORIZONTAL_ALIGNMENT_CENTER)
	if possible:
		_clic(b, func(): _investir(t["id"]))

func _investir(id: String) -> void:
	if Profil.p().investir(id):
		Sons.jouer("cloche", heros.global_position if heros else Vector3.ZERO, -6.0, 1.5)
		_eclat(_noeuds[id])

func _reinitialiser() -> void:
	if heros == null or heros.sac.or_ < 200:
		Jeu.notifier("Il faut 200 or pour réinitialiser l'arbre.", Color("#FFB37A"))
		return
	heros.sac.ajouter_or(-200)
	Profil.p().reinitialiser()

## Petit éclat doré sur le nœud investi.
func _eclat(c: Vector2) -> void:
	var e := Control.new()
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	e.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.add_child(e)
	var k := {"t": 0.0}
	e.draw.connect(func():
		var a: float = 1.0 - k["t"]
		for i in 3:
			e.draw_arc(c, 30.0 + k["t"] * 50.0 + i * 6.0, 0, TAU, 48, Color(1.0, 0.85, 0.45, a * (0.6 - i * 0.18)), 3.0 - i, true))
	var tw := e.create_tween()
	tw.tween_method(func(v): k["t"] = v; e.queue_redraw(), 0.0, 1.0, 0.55)
	tw.tween_callback(e.queue_free)

# ---------------- dessin : racines, anneaux, lueurs ----------------

func _dessiner() -> void:
	var pr := Profil.p()
	var investis := pr.points_investis()
	# tronc et halo du haut
	for i in 6:
		_toile.draw_circle(TRONC, 90.0 - i * 13.0, Color(0.95, 0.72, 0.3, 0.018 + i * 0.006))
	_toile.draw_line(TRONC + Vector2(0, -40), TRONC + Vector2(0, 8), Color("#2A2014"), 14.0)
	_toile.draw_line(TRONC + Vector2(0, -40), TRONC + Vector2(0, 8), OR_SOMBRE, 4.0)
	# racines : du tronc vers le premier palier de chaque colonne, puis d'un palier à l'autre
	for col in 3:
		var prec := TRONC + Vector2(0, 8)
		for k in 5:
			var t: Dictionary = _talent_a(col, k)
			var p: Vector2 = _noeuds[t["id"]]
			var allume := pr.rang(t["id"]) > 0
			var ouvert_p: bool = investis >= Talents.SEUILS[k]
			_racine(prec, p - Vector2(0, 31), allume, ouvert_p, col * 5 + k)
			prec = p + Vector2(0, 33)
	# séparation discrète de la fiche
	_toile.draw_line(Vector2(860, 92), Vector2(860, 556), Color(0.92, 0.85, 0.7, 0.08), 1.0)
	# anneaux des nœuds
	for t in Talents.LISTE:
		var c: Vector2 = _noeuds[t["id"]]
		var rr := (33.0 if t.get("ultime", false) else 29.0)
		var r := pr.rang(t["id"])
		var accessible: bool = investis >= Talents.SEUILS[t["palier"]]
		var choisi: bool = t["id"] == _choix
		if r > 0:
			# lueur douce qui respire
			var b := 0.5 + 0.5 * sin(_t * 2.2 + c.x * 0.03)
			for i in 5:
				_toile.draw_circle(c, rr + 16.0 - i * 3.0, Color(1.0, 0.78, 0.35, 0.025 + 0.015 * b))
		_toile.draw_circle(c, rr, Color("#1C150E"))
		var anneau := OR_VIF if r > 0 else (BEIGE.darkened(0.25) if accessible else ETEINT)
		if t.get("ultime", false):
			_toile.draw_arc(c, rr + 5.0, 0, TAU, 48, Color(anneau.r, anneau.g, anneau.b, 0.55), 1.5, true)
		_toile.draw_arc(c, rr, 0, TAU, 48, Color("#0A0705"), 7.0, true)
		_toile.draw_arc(c, rr, 0, TAU, 48, anneau, 3.0 if r > 0 else 2.0, true)
		# progression du rang sur l'anneau
		if r > 0 and r < t["rangs"]:
			_toile.draw_arc(c, rr + 2.5, -PI / 2, -PI / 2 + TAU * r / t["rangs"], 40, Color(1, 0.95, 0.75, 0.9), 2.0, true)
		if choisi:
			var pulse := 0.5 + 0.5 * sin(_t * 4.0)
			_toile.draw_arc(c, rr + 9.0 + pulse * 2.0, 0, TAU, 48, Color(0.95, 0.9, 0.75, 0.55 + pulse * 0.3), 2.0, true)

func _talent_a(col: int, palier: int) -> Dictionary:
	for t in Talents.LISTE:
		if t["racine"] == col and t["palier"] == palier:
			return t
	return {}

## Une racine : courbe légèrement ondulée ; dorée si le talent du bas est pris, avec une lueur
## qui la parcourt ; beige pâle si le palier est ouvert ; brun éteint sinon.
func _racine(a: Vector2, b: Vector2, allume: bool, ouvert_p: bool, graine: int) -> void:
	var pts := PackedVector2Array()
	var n := 18
	var ondule := 7.0 + (graine % 3) * 2.0
	for i in n + 1:
		var k := float(i) / n
		var p := a.lerp(b, k)
		# départ vers la colonne en S quand on vient du tronc
		if absf(a.x - b.x) > 20.0:
			var e := k * k * (3.0 - 2.0 * k)
			p.x = lerpf(a.x, b.x, e)
		p.x += sin(k * PI) * sin(graine * 1.7 + k * 5.0) * ondule * 0.4
		pts.append(p)
	_toile.draw_polyline(pts, Color("#241A10"), 9.0, true)
	var coul := OR_VIF if allume else (Color(0.92, 0.85, 0.7, 0.32) if ouvert_p else Color(0.35, 0.29, 0.22, 0.6))
	_toile.draw_polyline(pts, coul, 3.0 if allume else 2.0, true)
	if allume:
		# filet clair au centre + perle de lumière qui descend
		_toile.draw_polyline(pts, Color(1, 0.96, 0.8, 0.45), 1.0, true)
		var k2 := fmod(_t * 0.45 + graine * 0.13, 1.0)
		var idx := int(k2 * n)
		var p2: Vector2 = pts[idx].lerp(pts[mini(idx + 1, n)], k2 * n - idx)
		for i in 4:
			_toile.draw_circle(p2, 7.0 - i * 1.6, Color(1.0, 0.88, 0.55, 0.08 + i * 0.12))
