extends "res://scripts/interface/hud.gd"
## Le Hameau de Brekka, vu par son chef : qui fait quoi, ce que ça rapporte, ce qu'on construit.
## Tout tient sur un parchemin : habitants à gauche, bâtiments au centre, grenier à droite.

var heros: Heros
var _p: Control
var _c: Control

func ouvrir(h: Heros) -> void:
	heros = h
	layer = 8
	racine = Control.new()
	racine.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(racine)
	var voile := ColorRect.new()
	voile.color = Color(0.02, 0.02, 0.04, 0.72)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.add_child(voile)
	_p = neuf(UI + "rpg/panel_beige.png", 18, Vector2(1180, 540), Vector2(50, 18))
	_c = Control.new()
	_p.add_child(_c)
	Jeu.interface_bloquante = true
	Hameau.avancer()
	_rafraichir()

func fermer() -> void:
	Jeu.interface_bloquante = false
	Profil.p().sauver(true)
	queue_free()

func _clic(c: Control, f: Callable) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.gui_input.connect(func(ev):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			f.call())

func _bouton(t: String, pos: Vector2, taille: Vector2, f: Callable, actif := true, clair := false, parent: Control = null) -> void:
	var fond := "buttonLong_grey" if not actif else ("buttonLong_beige" if clair else "buttonLong_brown")
	var b := neuf(UI + "rpg/" + fond + ".png", 12, taille, pos, parent if parent else _c)
	texte(t, 13, ENCRE if clair and actif else Color("#FFF4DC"), Vector2(0, taille.y / 2 - 10), b, not (clair and actif), taille.x, HORIZONTAL_ALIGNMENT_CENTER)
	if actif:
		_clic(b, f)

func _rafraichir() -> void:
	for x in _c.get_children():
		x.queue_free()
	var x := neuf(UI + "rpg/buttonRound_brown.png", 10, Vector2(42, 42), Vector2(1124, 12), _c)
	texte("✕", 18, Color("#FFF4DC"), Vector2(0, 8), x, true, 42, HORIZONTAL_ALIGNMENT_CENTER)
	_clic(x, fermer)
	if not Hameau.est_chef():
		_offre()
	else:
		_gestion()

func _nom_res(r: String) -> String:
	return {"bois": "bois", "pierre": "pierre", "or": "or", "minerai_fer": "minerai de fer"}.get(r, r)

func _cout_texte(cout: Dictionary) -> String:
	var l: Array = []
	for r in cout:
		l.append("%d %s" % [cout[r], _nom_res(r)])
	return ", ".join(l)

# ---------------- avant d'être chef ----------------

func _offre() -> void:
	texte("Sigurd, chef du hameau", 26, ENCRE, Vector2(28, 18), _c, false)
	var l := texte("« Je suis vieux, et Brekka a besoin d'un protecteur. Apporte de quoi relever la palissade et remplir le grenier : %s. Alors le hameau sera à toi : ses gens travailleront pour toi, et tu décideras de tout. »" % _cout_texte(Hameau.PRIX_CHEF), 16, ENCRE, Vector2(28, 64), _c, false, 1100)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var y := 170.0
	for r in Hameau.PRIX_CHEF:
		var a := Hameau._dispo(r, heros)
		var ok: bool = a >= Hameau.PRIX_CHEF[r]
		texte("%s : %d / %d" % [_nom_res(r).capitalize(), a, Hameau.PRIX_CHEF[r]], 17, Color("#2E6A2C") if ok else Color("#A04030"), Vector2(40, y), _c, false)
		y += 32.0
	texte("Astuce : les Lames de moisson rasent arbres et rochers ; le bois et la pierre du coffre comptent aussi.", 13, ENCRE2, Vector2(40, y + 8), _c, false)
	var possible := Hameau.peut_payer(Hameau.PRIX_CHEF, heros)
	_bouton("Devenir chef du hameau", Vector2(40, 420), Vector2(300, 52), func():
		Hameau.payer(Hameau.PRIX_CHEF, heros)
		var e := Hameau.etat()
		e["chef"] = true
		e["dernier"] = Time.get_unix_time_from_system()
		Profil.p().compter("chef")
		Sons.jouer("cloche", heros.global_position, 2.0, 0.8)
		if Jeu.hud and Jeu.hud.has_method("celebrer"):
			Jeu.hud.celebrer({"rarete": "legendaire", "icone": "res://assets/icones_sorts/arbre.svg"}, "CHEF DE BREKKA", "Le hameau est à toi", "Donne un métier à chacun : ils travailleront pour toi, même quand tu n'es pas là.")
		_rafraichir(), possible)

# ---------------- gestion ----------------

func _gestion() -> void:
	var e := Hameau.etat()
	texte("Hameau de Brekka", 26, ENCRE, Vector2(28, 14), _c, false)
	texte("Tu en es le chef. Ce que produisent tes gens s'entasse au grenier, même quand tu n'es pas là (8 h au plus).", 13, ENCRE2, Vector2(28, 48), _c, false)
	# --- habitants ---
	texte("Habitants", 17, ENCRE, Vector2(28, 76), _c, false)
	var y := 104.0
	var ids := ["bucheron", "mineur", "fermier", "garde"]
	for r in Village.RESIDENTS:
		if r[5]:
			continue
		var nom: String = r[0]
		var m := Hameau.metier_de(nom)
		texte(nom, 14, ENCRE, Vector2(28, y + 6), _c, false)
		var bx := 104.0
		for id in ids:
			var actif: bool = m == id
			var b := neuf(UI + "rpg/" + ("buttonLong_brown" if actif else "buttonLong_beige") + ".png", 10, Vector2(78, 30), Vector2(bx, y), _c)
			texte(Hameau.METIERS[id]["nom"], 12, Color("#FFF4DC") if actif else ENCRE, Vector2(0, 6), b, actif, 78, HORIZONTAL_ALIGNMENT_CENTER)
			var nn: String = nom
			var ii: String = id
			_clic(b, func():
				Hameau.avancer()
				Hameau.etat()["metiers"][nn] = "" if Hameau.metier_de(nn) == ii else ii
				Profil.p()._marquer()
				if Village.moi:
					Village.moi.reassigner()
				_rafraichir())
			bx += 82.0
		y += 38.0
	# --- bâtiments ---
	var bx2 := 470.0
	texte("Bâtiments", 17, ENCRE, Vector2(bx2, 76), _c, false)
	var by := 104.0
	for id in Hameau.BATIMENTS:
		var bat: Dictionary = Hameau.BATIMENTS[id]
		var niv: int = e["batiments"].get(id, 1)
		var carte := neuf(UI + "rpg/panelInset_beigeLight.png", 12, Vector2(380, 92), Vector2(bx2, by), _c)
		texte("%s · niveau %d" % [bat["nom"], niv], 16, ENCRE, Vector2(14, 8), carte, false)
		texte(("+%d %% : %s" % [50 * (niv - 1), bat["effet"]]) if niv > 1 else "Améliore : " + bat["effet"], 12, ENCRE2, Vector2(14, 32), carte, false)
		if niv < 3:
			var cout: Dictionary = bat["couts"][niv]
			texte(_cout_texte(cout), 12, Color("#7A4F0C"), Vector2(14, 56), carte, false, 220)
			var possible := Hameau.peut_payer(cout, heros)
			var ii2: String = id
			_bouton("Améliorer", Vector2(244, 48), Vector2(122, 34), func():
				Hameau.avancer()
				Hameau.payer(cout, heros)
				Hameau.etat()["batiments"][ii2] = niv + 1
				Sons.jouer("metal", heros.global_position, 0.0, 0.8)
				Jeu.notifier("%s passe niveau %d !" % [bat["nom"], niv + 1], Color("#FFD34E"))
				_rafraichir(), possible, false, carte)
		else:
			texte("Au maximum", 13, Color("#2E6A2C"), Vector2(14, 56), carte, false)
		by += 100.0
	# --- grenier ---
	var gx := 870.0
	texte("Grenier", 17, ENCRE, Vector2(gx, 76), _c, false)
	var prod := Hameau.production()
	var gy := 108.0
	for r in ["or", "bois", "pierre", "minerai_fer"]:
		var stock := int(e["stock"].get(r, 0.0))
		texte("%s : %d" % [_nom_res(r).left(1).to_upper() + _nom_res(r).substr(1), stock], 16, ENCRE, Vector2(gx, gy), _c, false)
		texte("+%d / h" % int(prod.get(r, 0.0)), 13, Color("#2E6A2C"), Vector2(gx + 170, gy + 2), _c, false)
		gy += 34.0
	_bouton("Tout récupérer", Vector2(gx, gy + 14), Vector2(260, 48), func():
		var bilan := Hameau.recolter(heros)
		var l: Array = []
		for r in bilan:
			l.append("%d %s" % [bilan[r], _nom_res(r)])
		Jeu.notifier("Grenier vidé : " + (", ".join(l) if not l.is_empty() else "rien pour l'instant"), Color("#FFD36B"))
		Sons.jouer("potion", heros.global_position, 0.0, 1.2)
		_rafraichir())
	var note := texte("L'or va dans ton sac, le reste dans ton coffre du Bourg.", 12, ENCRE2, Vector2(gx, gy + 70), _c, false, 270)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
