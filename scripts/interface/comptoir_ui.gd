extends "res://scripts/interface/hud.gd"
## Comptoir du Bourg, deux usages :
## - « coffre » : ton coffre personnel. Ce qui y dort ne se perd jamais, même en mourant.
## - « marchand » : Halvard achète tout ce que tu remontes et vend des potions.
## À gauche le sac, à droite le coffre ou l'étal. Toucher un objet le déplace (ou le vend).

const T := 54.0
const G := 6.0

var heros: Heros
var mode := "coffre"
var _panneau: Control
var _contenu: Control

const ETAL := [
	{"id": "potion", "qte": 1, "prix": 30},
	{"id": "potion", "qte": 5, "prix": 135},
]

func ouvrir(h: Heros, m: String) -> void:
	heros = h
	mode = m
	layer = 8
	racine = Control.new()
	racine.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(racine)
	var voile := ColorRect.new()
	voile.color = Color(0.02, 0.02, 0.04, 0.7)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.add_child(voile)
	_panneau = neuf(UI + "rpg/panel_beige.png", 18, Vector2(1060, 520), Vector2(110, 28))
	_contenu = Control.new()
	_panneau.add_child(_contenu)
	Jeu.interface_bloquante = true
	heros.sac.change.connect(_rafraichir)
	_rafraichir()

func fermer() -> void:
	Jeu.interface_bloquante = false
	if heros.sac.change.is_connected(_rafraichir):
		heros.sac.change.disconnect(_rafraichir)
	Profil.p().sauver(true)
	queue_free()

func _clic(c: Control, f: Callable) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.gui_input.connect(func(ev):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			f.call())

func _bouton(t: String, pos: Vector2, taille: Vector2, f: Callable, clair := false) -> void:
	var b := neuf(UI + "rpg/" + ("buttonLong_beige" if clair else "buttonLong_brown") + ".png", 12, taille, pos, _contenu)
	texte(t, 14, ENCRE if clair else Color("#FFF4DC"), Vector2(0, taille.y / 2 - 10), b, not clair, taille.x, HORIZONTAL_ALIGNMENT_CENTER)
	_clic(b, f)

func _case(o: Dictionary, pos: Vector2, f: Callable) -> void:
	var creux := neuf(UI + "rpg/panelInset_beige.png", 12, Vector2(T, T), pos, _contenu)
	creux.modulate = Color(0.82, 0.74, 0.62)
	if o.is_empty():
		return
	var c := Objets.couleur(o)
	var fond := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(c.r, c.g, c.b, 0.24)
	sb.border_color = c
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	fond.add_theme_stylebox_override("panel", sb)
	fond.position = pos + Vector2(3, 3)
	fond.size = Vector2(T - 6, T - 6)
	_contenu.add_child(fond)
	if o.get("icone", "") != "":
		image(o["icone"], Vector2(T - 14, T - 14), pos + Vector2(7, 7), _contenu)
	if o.get("qte", 1) > 1:
		texte(str(o["qte"]), 12, Color.WHITE, pos + Vector2(0, T - 20), _contenu, true, T - 6, HORIZONTAL_ALIGNMENT_RIGHT)
	_clic(fond, f)

func _rafraichir() -> void:
	if not is_instance_valid(_contenu):
		return
	for x in _contenu.get_children():
		x.queue_free()
	var sac: Sac = heros.sac
	var titre := "Ton coffre" if mode == "coffre" else "Halvard, marchand"
	texte(titre, 26, ENCRE, Vector2(24, 16), _contenu, false)
	texte("Ce qui dort ici ne se perd jamais, même si tu tombes." if mode == "coffre" else "« Tout se vend, tout s'achète. Surtout ce que les morts n'emportent pas. »", 13, ENCRE2, Vector2(24, 50), _contenu, false)
	var x := neuf(UI + "rpg/buttonRound_brown.png", 10, Vector2(42, 42), Vector2(1004, 12), _contenu)
	texte("✕", 18, Color("#FFF4DC"), Vector2(0, 8), x, true, 42, HORIZONTAL_ALIGNMENT_CENTER)
	_clic(x, fermer)
	# sac à gauche
	texte("Ton sac · %d or" % sac.or_, 16, ENCRE, Vector2(24, 82), _contenu, false)
	for i in Sac.CAPACITE:
		var o: Dictionary = sac.objets[i] if i < sac.objets.size() else {}
		var pos := Vector2(24 + (i % 6) * (T + G), 110 + (i / 6) * (T + G))
		_case(o, pos, func(): _depuis_sac(o))
	texte("Touche un objet pour le %s." % ("ranger" if mode == "coffre" else "vendre"), 12, ENCRE2, Vector2(24, 412), _contenu, false)
	if mode == "coffre":
		_cote_coffre()
	else:
		_cote_marchand()

func _cote_coffre() -> void:
	var c: Dictionary = Profil.p().coffre
	var objs: Array = c["objets"]
	texte("Coffre · %d or · %d / 48" % [c["or"], objs.size()], 16, ENCRE, Vector2(420, 82), _contenu, false)
	for i in 48:
		var o: Dictionary = objs[i] if i < objs.size() else {}
		var pos := Vector2(420 + (i % 8) * (T + G), 110 + (i / 8) * (T + G))
		_case(o, pos, func(): _depuis_coffre(o))
	_bouton("Déposer tout l'or", Vector2(24, 440), Vector2(180, 40), func():
		c["or"] += heros.sac.or_
		heros.sac.or_ = 0
		heros.sac.change.emit())
	_bouton("Ranger les ressources", Vector2(212, 440), Vector2(190, 40), func(): _ranger_ressources(), true)
	_bouton("Reprendre 500 or", Vector2(420, 470), Vector2(180, 40), func():
		var n: int = mini(500, c["or"])
		c["or"] -= n
		heros.sac.ajouter_or(n), true)

func _depuis_sac(o: Dictionary) -> void:
	if mode == "marchand":
		_vendre(o)
		return
	var c: Dictionary = Profil.p().coffre
	if c["objets"].size() >= 48:
		Jeu.notifier("Ton coffre est plein.", Color("#FF8A7A"))
		return
	heros.sac.objets.erase(o)
	c["objets"].append(o)
	Sons.jouer("tissu", heros.global_position, -8.0, 1.2)
	heros.sac.change.emit()

func _depuis_coffre(o: Dictionary) -> void:
	var c: Dictionary = Profil.p().coffre
	if heros.sac.objets.size() >= Sac.CAPACITE:
		Jeu.notifier("Ton sac est plein.", Color("#FF8A7A"))
		return
	c["objets"].erase(o)
	heros.sac.ajouter(o)

func _ranger_ressources() -> void:
	var c: Dictionary = Profil.p().coffre
	for o in heros.sac.objets.duplicate():
		if o["type"] == "ressource" and c["objets"].size() < 48:
			heros.sac.objets.erase(o)
			c["objets"].append(o)
	heros.sac.change.emit()

func _cote_marchand() -> void:
	texte("Étal", 16, ENCRE, Vector2(420, 82), _contenu, false)
	var y := 110.0
	for e in ETAL:
		var m: Dictionary = Objets.MODELES[e["id"]]
		var ligne := neuf(UI + "rpg/panelInset_beigeLight.png", 12, Vector2(600, 64), Vector2(420, y), _contenu)
		image(m["icone"], Vector2(44, 44), Vector2(10, 10), ligne)
		texte("%s ×%d" % [m["nom"], e["qte"]], 16, ENCRE, Vector2(66, 10), ligne, false)
		texte("Rend 30 % de la vie en 4 s", 12, ENCRE2, Vector2(66, 34), ligne, false)
		var prix: int = e["prix"]
		var assez: bool = heros.sac.or_ >= prix
		var b := neuf(UI + "rpg/" + ("buttonLong_brown" if assez else "buttonLong_grey") + ".png", 12, Vector2(150, 42), Vector2(436, 11), ligne)
		texte("Acheter · %d or" % prix, 14, Color("#FFF4DC"), Vector2(0, 11), b, true, 150, HORIZONTAL_ALIGNMENT_CENTER)
		if assez:
			var ee: Dictionary = e
			_clic(b, func(): _acheter(ee))
		y += 72.0
	# vente en gros
	var total := 0
	for o in heros.sac.objets:
		if o["type"] == "ressource":
			total += o["valeur"] * o["qte"]
	texte("Vendre en gros", 16, ENCRE, Vector2(420, y + 12), _contenu, false)
	_bouton("Toutes les ressources · +%d or" % total, Vector2(420, y + 40), Vector2(300, 42), func(): _vendre_ressources())
	var armes := 0
	for o in heros.sac.objets:
		if o["type"] == "arme" and o.get("classe", "") != heros.classe:
			armes += o["valeur"]
	_bouton("Armes d'autres classes · +%d or" % armes, Vector2(420, y + 90), Vector2(300, 42), func(): _vendre_armes(), true)

func _acheter(e: Dictionary) -> void:
	if heros.sac.or_ < e["prix"]:
		return
	if not heros.sac.ajouter(Objets.creer(e["id"], "commun", e["qte"])):
		Jeu.notifier("Ton sac est plein.", Color("#FF8A7A"))
		return
	heros.sac.ajouter_or(-e["prix"])
	Sons.jouer("potion", heros.global_position, -4.0, 1.3)

func _vendre(o: Dictionary) -> void:
	var v: int = o["valeur"] * o.get("qte", 1)
	heros.sac.objets.erase(o)
	heros.sac.ajouter_or(v)
	Sons.jouer("potion", heros.global_position, -6.0, 1.5)
	Jeu.notifier("Vendu : %s · +%d or" % [o["nom"], v], Color("#FFD36B"), "res://assets/icones_objets/pieces_or.png")

func _vendre_ressources() -> void:
	var v := 0
	for o in heros.sac.objets.duplicate():
		if o["type"] == "ressource":
			v += o["valeur"] * o["qte"]
			heros.sac.objets.erase(o)
	if v > 0:
		heros.sac.ajouter_or(v)
		Sons.jouer("potion", heros.global_position, -4.0, 1.5)

func _vendre_armes() -> void:
	var v := 0
	for o in heros.sac.objets.duplicate():
		if o["type"] == "arme" and o.get("classe", "") != heros.classe:
			v += o["valeur"]
			heros.sac.objets.erase(o)
	if v > 0:
		heros.sac.ajouter_or(v)
		Sons.jouer("potion", heros.global_position, -4.0, 1.5)
