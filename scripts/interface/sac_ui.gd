extends "res://scripts/interface/hud.gd"
## Écran du sac : parchemin beige, équipement à gauche, cases du sac au centre, fiche de l'objet touché
## à droite avec ses actions (équiper, faire éclore, boire, vendre près d'un marchand, jeter).
## L'or n'apparaît qu'ici. En bas : la valeur de tout ce qu'on risque de perdre en mourant.

const ICO_SORTS := "res://assets/icones_sorts/"

var heros: Heros
var _panneau: Control
var _grille: Control
var _equip: Control
var _fiche: Control
var _entete: Control
var _choix: Dictionary = {}
var ouvert := false

func _ready() -> void:
	layer = 8
	racine = Control.new()
	racine.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(racine)
	var voile := ColorRect.new()
	voile.color = Color(0.02, 0.02, 0.04, 0.66)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.add_child(voile)
	_panneau = neuf(UI + "rpg/panel_beige.png", 18, Vector2(1060, 520), Vector2(110, 28))
	_entete = Control.new()
	_panneau.add_child(_entete)
	_equip = Control.new()
	_equip.position = Vector2(24, 76)
	_panneau.add_child(_equip)
	_grille = Control.new()
	_grille.position = Vector2(232, 76)
	_panneau.add_child(_grille)
	_fiche = Control.new()
	_fiche.position = Vector2(672, 22)
	_panneau.add_child(_fiche)
	var fermer := _bouton("✕", Vector2(1010, 10), Vector2(40, 40), func(): fermer_sac(), "buttonRound_brown")
	fermer.add_theme_font_size_override("font_size", 18)
	racine.visible = false

func brancher(h: Heros) -> void:
	heros = h
	heros.sac.change.connect(func(): if ouvert: _rafraichir())

func ouvrir_sac() -> void:
	ouvert = true
	Jeu.interface_bloquante = true
	racine.visible = true
	_choix = {}
	_rafraichir()
	Sons.jouer("tissu", heros.global_position, -6.0, 1.1)

func fermer_sac() -> void:
	ouvert = false
	Jeu.interface_bloquante = false
	racine.visible = false

func basculer() -> void:
	if ouvert:
		fermer_sac()
	else:
		ouvrir_sac()

# ---------------- briques ----------------

func _vider(c: Control) -> void:
	for x in c.get_children():
		x.queue_free()

func _bouton(t: String, pos: Vector2, taille: Vector2, action: Callable, fond := "buttonLong_brown", parent: Control = null) -> Label:
	var b := neuf(UI + "rpg/" + fond + ".png", 12, taille, pos, parent if parent else _panneau)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.gui_input.connect(func(ev):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			Sons.jouer("tissu", heros.global_position if heros else Vector3.ZERO, -12.0, 1.3)
			action.call())
	var clair := fond.contains("beige")
	var l := texte(t, 15, ENCRE if clair else Color("#FFF4DC"), Vector2(0, taille.y / 2 - 11), b, not clair, taille.x, HORIZONTAL_ALIGNMENT_CENTER)
	return l

## Case d'objet : creux beige, bord et fond teintés de la rareté, icône, quantité.
func _case(o: Dictionary, pos: Vector2, t: float, parent: Control, libelle := "") -> Control:
	var creux := neuf(UI + "rpg/panelInset_beige.png", 12, Vector2(t, t), pos, parent)
	creux.modulate = Color(0.82, 0.74, 0.62)
	var zone := Control.new()
	zone.position = pos
	zone.size = Vector2(t, t)
	zone.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(zone)
	if not o.is_empty():
		var c := Objets.couleur(o)
		var fond := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(c.r, c.g, c.b, 0.24)
		sb.border_color = c
		sb.set_border_width_all(3 if _choix != o else 5)
		sb.set_corner_radius_all(8)
		fond.add_theme_stylebox_override("panel", sb)
		fond.position = Vector2(3, 3)
		fond.size = Vector2(t - 6, t - 6)
		fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
		zone.add_child(fond)
		if o.get("icone", "") != "":
			image(o["icone"], Vector2(t - 14, t - 14), Vector2(7, 7), zone)
		if o["qte"] > 1:
			texte(str(o["qte"]), 13, Color.WHITE, Vector2(0, t - 22), zone, true, t - 7, HORIZONTAL_ALIGNMENT_RIGHT)
		if o["type"] == "dragon":
			texte("niv. %d" % o.get("niveau", 1), 11, Color("#FFE9B0"), Vector2(5, 3), zone, true)
		zone.gui_input.connect(func(ev):
			if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
				_choix = o
				_rafraichir())
	elif libelle != "":
		texte(libelle, 11, Color(ENCRE2.r, ENCRE2.g, ENCRE2.b, 0.7), Vector2(0, t / 2 - 8), zone, false, t, HORIZONTAL_ALIGNMENT_CENTER)
	return zone

# ---------------- contenu ----------------

func _rafraichir() -> void:
	if heros == null:
		return
	var sac: Sac = heros.sac
	_vider(_entete)
	_vider(_equip)
	_vider(_grille)
	_vider(_fiche)
	texte("Sac", 26, ENCRE, Vector2(24, 16), _entete, false)
	image("res://assets/icones_objets/pieces_or.png", Vector2(34, 34), Vector2(232, 20), _entete)
	texte(_milliers(sac.or_) + " or", 20, Color("#7A4F0C"), Vector2(270, 24), _entete, false)
	texte("Valeur portée : %s or" % _milliers(sac.valeur()), 13, ENCRE2, Vector2(420, 18), _entete, false)
	texte("perdue si tu meurs", 12, Color("#A04030"), Vector2(420, 36), _entete, false)
	# équipement
	texte("Équipement", 15, ENCRE, Vector2(0, -2), _equip, false)
	_case(sac.arme, Vector2(0, 22), 84, _equip, "" if sac.arme.is_empty() else "Arme")
	texte("Arme", 12, ENCRE2, Vector2(0, 108), _equip, false, 84, HORIZONTAL_ALIGNMENT_CENTER)
	if sac.arme.is_empty():
		image("res://assets/icones/001_axe_2handed.png", Vector2(70, 70), Vector2(7, 29), _equip)
	_case(sac.acolyte, Vector2(96, 22), 84, _equip, "Acolyte")
	texte("Acolyte", 12, ENCRE2, Vector2(96, 108), _equip, false, 84, HORIZONTAL_ALIGNMENT_CENTER)
	# métier
	var m: Dictionary = heros.metier_mine
	texte("Métier", 15, ENCRE, Vector2(0, 140), _equip, false)
	image("res://assets/icones/042_pickaxe.png", Vector2(40, 40), Vector2(0, 164), _equip)
	texte("Mineur · niv. %d" % m["niveau"], 15, ENCRE, Vector2(46, 166), _equip, false)
	var besoin: int = 40 + m["niveau"] * 30
	var fond := ColorRect.new()
	fond.color = Color(0.3, 0.22, 0.12, 0.35)
	fond.position = Vector2(46, 192)
	fond.size = Vector2(134, 8)
	_equip.add_child(fond)
	var plein := ColorRect.new()
	plein.color = Color("#8E6AD8")
	plein.position = Vector2(46, 192)
	plein.size = Vector2(134.0 * m["xp"] / besoin, 8)
	_equip.add_child(plein)
	texte("%d / %d XP" % [m["xp"], besoin], 11, ENCRE2, Vector2(46, 202), _equip, false)
	# grille du sac
	var t := 64.0
	var g := 6.0
	for i in Sac.CAPACITE:
		var o: Dictionary = sac.objets[i] if i < sac.objets.size() else {}
		_case(o, Vector2((i % 6) * (t + g), (i / 6) * (t + g)), t, _grille)
	texte("%d / %d places" % [sac.objets.size(), Sac.CAPACITE], 12, ENCRE2, Vector2(0, 5 * (t + g) + 4), _grille, false)
	_remplir_fiche()

func _pres_marchand() -> bool:
	for p in get_tree().get_nodes_in_group("pnj"):
		if p.role == "marchand" and p.global_position.distance_to(heros.global_position) < 7.0:
			return true
	return false

func _remplir_fiche() -> void:
	var f := neuf(UI + "rpg/panel_beigeLight.png", 16, Vector2(366, 478), Vector2(0, 0), _fiche)
	var o := _choix
	if o.is_empty():
		texte("Touche un objet pour voir sa fiche.", 14, ENCRE2, Vector2(20, 24), f, false)
		texte("Les œufs de dragon s'ouvrent d'ici.", 13, ENCRE2, Vector2(20, 50), f, false)
		if _pres_marchand():
			texte("Un marchand est proche : tu peux vendre.", 13, Color("#2E7D32"), Vector2(20, 76), f, false)
		return
	var c := Objets.couleur(o)
	_case(o, Vector2(16, 16), 84, f)
	var nom := texte(o["nom"], 18, c.darkened(0.3), Vector2(110, 18), f, false, 240)
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texte(Objets.NOMS_RARETE[o["rarete"]] + " · " + {"ressource": "ressource", "arme": "arme", "potion": "consommable", "oeuf": "œuf", "dragon": "acolyte"}[o["type"]], 13, ENCRE2, Vector2(110, 62), f, false)
	texte("Valeur : %s or%s" % [_milliers(o["valeur"]), (" (×%d)" % o["qte"]) if o["qte"] > 1 else ""], 13, Color("#7A4F0C"), Vector2(110, 80), f, false)
	var y := 116.0
	var lignes: Array = []
	match o["type"]:
		"arme":
			lignes = ["Dégâts %d (hache de départ : 90)" % o["degats"], "Équipée, elle remplace la Hache du Jarl."]
		"oeuf":
			lignes = ["Un œuf chaud, il bouge parfois.", "En l'ouvrant : un bébé dragon, de faible à très fort.", "Au-delà du bleu, c'est extrêmement rare."]
		"dragon":
			var st := Objets.stats_dragon(o)
			lignes = ["Puissance " + "★".repeat(o.get("puissance", 1)) + "☆".repeat(5 - o.get("puissance", 1)), "Niveau %d · %d / %d XP" % [o.get("niveau", 1), o.get("xp", 0), Objets.xp_niveau(o.get("niveau", 1))], "Boule de feu : %d dégâts toutes les %.1f s" % [st["degats"], st["cadence"]], "Il grandit en tuant des monstres avec toi."]
		"potion":
			lignes = ["Rend 30 % de la vie en 4 s.", "Aussi utilisable depuis la roue des sorts."]
		"ressource":
			lignes = ["Se vend au marchand, sert à la forge."]
	for l in lignes:
		var lab := texte(l, 14, ENCRE, Vector2(20, y), f, false, 330)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		y += 26.0 if l.length() < 42 else 44.0
	# actions
	var bx := 18.0
	var by := 360.0
	var actions: Array = []
	var dans_sac := heros.sac.objets.has(o)
	match o["type"]:
		"oeuf":
			actions.append(["Faire éclore", func(): _eclore(o)])
		"dragon":
			if heros.sac.acolyte == o:
				actions.append(["Ranger", func(): heros.desequiper_dragon(); _choix = {}; _rafraichir()])
			else:
				actions.append(["Équiper", func(): heros.equiper_dragon(o); _rafraichir()])
		"arme":
			if dans_sac:
				actions.append(["Équiper", func(): heros.equiper_arme(o); _rafraichir()])
		"potion":
			actions.append(["Boire", func(): fermer_sac(); heros.lancer("p")])
	if _pres_marchand() and dans_sac:
		actions.append(["Vendre +%s" % _milliers(o["valeur"] * o["qte"]), func(): _vendre(o)])
	if dans_sac:
		actions.append(["Jeter", func(): heros.sac.retirer(o); _choix = {}; _rafraichir()])
	for i in actions.size():
		var a: Array = actions[i]
		_bouton(a[0], Vector2(bx + (i % 2) * 168, by + (i / 2) * 50), Vector2(160, 42), a[1], "buttonLong_brown" if i == 0 else "buttonLong_beige", f)

func _vendre(o: Dictionary) -> void:
	heros.sac.ajouter_or(o["valeur"] * o["qte"])
	heros.sac.retirer(o)
	Sons.jouer("potion", heros.global_position, 0.0, 1.4)
	_choix = {}
	_rafraichir()

func _eclore(o: Dictionary) -> void:
	heros.sac.retirer(o)
	var d := Objets.eclore(o)
	heros.sac.ajouter(d)
	_choix = d
	var e := CanvasLayer.new()
	e.set_script(load("res://scripts/interface/eclosion_ui.gd"))
	add_child(e)
	e.lancer(o, d, func(equiper: bool):
		if equiper:
			heros.equiper_dragon(d)
		_rafraichir())

func _milliers(n: int) -> String:
	var s := str(n)
	var r := ""
	while s.length() > 3:
		r = " " + s.substr(s.length() - 3) + r
		s = s.substr(0, s.length() - 3)
	return s + r
