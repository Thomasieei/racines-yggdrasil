extends Node
## Le donjon du jour, vu du joueur : la crypte d'arrivée, le boyau, puis la Grande Caverne.
## Chaque zone a une identité (bandeau + titre), un danger lisible, et une récompense visible
## (le coffre du Jarl, éclairé en orange, se voit avant le Jarl lui-même).

var principale: Node
var heros: Heros
var hud: CanvasLayer
var recit: CanvasLayer
var _lieu := ""
var _vus := {}

## Camps de monstres de l'étage. Pensé pour une vingtaine de joueurs en même temps : environ 60 draugr
## répartis en 25 camps sur quatre ailes, et chaque camp vidé se repeuple (sans jamais apparaître sous les yeux d'un joueur).
## [identifiant, délai de repeuplement (s), [[type, position, aggro], ...]]
const CAMPS := [
	["boyau", 70.0, [["arbaletrier", Vector3(6.5, 0, -21), 10.0], ["minion", Vector3(11.5, 0, -12), 7.0], ["minion", Vector3(9.0, 0, -15), 7.0]]],
	["entree", 70.0, [["guerrier", Vector3(4, 0, -36), 10.0], ["minion", Vector3(8, 0, -38), 8.0]]],
	["nid", 75.0, [["minion", Vector3(-26, 0, -44), 9.0], ["minion", Vector3(-21, 0, -49), 9.0], ["minion", Vector3(-27, 0, -50), 9.0], ["minion", Vector3(-20, 0, -43), 9.0]]],
	["autel", 80.0, [["mage", Vector3(-27, 0, -76), 11.0], ["minion", Vector3(-24, 0, -70), 9.0], ["minion", Vector3(-31, 0, -69), 9.0]]],
	["gouffre", 80.0, [["arbaletrier", Vector3(18, 0, -55), 12.0], ["mage", Vector3(16, 0, -62), 12.0]]],
	["campement", 90.0, [["guerrier", Vector3(20, 0, -76), 11.0], ["arbaletrier", Vector3(14, 0, -83), 12.0], ["arbaletrier", Vector3(27, 0, -83), 12.0], ["minion", Vector3(22, 0, -72), 9.0]]],
	["jarl", 240.0, [["jarl", Vector3(74, 0, -59), 9.0]]],
	["centre", 70.0, [["guerrier", Vector3(-8, 0, -46), 10.0], ["arbaletrier", Vector3(-14, 0, -52), 11.0]]],
	["est", 60.0, [["minion", Vector3(40, 0, -40), 8.0], ["minion", Vector3(44, 0, -44), 8.0], ["minion", Vector3(38, 0, -47), 8.0]]],
	["nord", 75.0, [["arbaletrier", Vector3(-6, 0, -86), 11.0], ["mage", Vector3(0, 0, -80), 11.0]]],
	["descente", 80.0, [["guerrier", Vector3(19, 0, -92), 10.0], ["minion", Vector3(15, 0, -94), 8.0]]],
	["couloir_ouest", 70.0, [["arbaletrier", Vector3(-48, 0, -60), 11.0], ["minion", Vector3(-54, 0, -58), 8.0]]],
	["tombes", 75.0, [["minion", Vector3(-86, 0, -74), 9.0], ["minion", Vector3(-82, 0, -70), 9.0], ["minion", Vector3(-90, 0, -70), 9.0]]],
	["chapelle", 80.0, [["mage", Vector3(-96, 0, -46), 11.0], ["minion", Vector3(-100, 0, -51), 9.0]]],
	["garde_royale", 90.0, [["guerrier", Vector3(-98, 0, -67), 10.0], ["guerrier", Vector3(-98, 0, -56), 10.0]]],
	["reine", 240.0, [["reine", Vector3(-104, 0, -62), 10.0]]],
	["noyes", 70.0, [["minion", Vector3(-70, 0, -4), 9.0], ["minion", Vector3(-66, 0, 4), 9.0], ["minion", Vector3(-71, 0, 11), 9.0]]],
	["rive_ouest", 80.0, [["guerrier", Vector3(-106, 0, 4), 10.0], ["arbaletrier", Vector3(-103, 0, -7), 12.0]]],
	["rive_nord", 80.0, [["mage", Vector3(-92, 0, -13), 11.0], ["minion", Vector3(-84, 0, -15), 9.0]]],
	["couloir_lac", 70.0, [["arbaletrier", Vector3(-76, 0, -28), 11.0]]],
	["seuil_forges", 75.0, [["guerrier", Vector3(47, 0, -110), 10.0], ["arbaletrier", Vector3(45, 0, -118), 11.0]]],
	["halle", 90.0, [["guerrier", Vector3(52, 0, -127), 10.0], ["guerrier", Vector3(64, 0, -127), 10.0], ["arbaletrier", Vector3(58, 0, -119), 12.0]]],
	["coulees", 80.0, [["mage", Vector3(40, 0, -141), 11.0], ["minion", Vector3(46, 0, -144), 9.0], ["minion", Vector3(42, 0, -134), 9.0]]],
	["brokk", 240.0, [["brokk", Vector3(58, 0, -142), 9.0]]],
	["forges_est", 70.0, [["arbaletrier", Vector3(74, 0, -140), 11.0], ["minion", Vector3(72, 0, -130), 9.0]]],
	# densité supplémentaire : chaque passage entre deux zones a sa rencontre
	["ouest_gouffre", 70.0, [["minion", Vector3(-12, 0, -64), 9.0], ["minion", Vector3(-8, 0, -68), 9.0], ["arbaletrier", Vector3(-16, 0, -70), 11.0]]],
	["nord_ouest", 75.0, [["guerrier", Vector3(-20, 0, -84), 10.0], ["mage", Vector3(-14, 0, -90), 11.0]]],
	["est_central", 70.0, [["guerrier", Vector3(40, 0, -58), 10.0], ["minion", Vector3(44, 0, -62), 9.0], ["minion", Vector3(36, 0, -64), 9.0]]],
	["seuil_jarl", 80.0, [["guerrier", Vector3(58, 0, -66), 10.0], ["arbaletrier", Vector3(56, 0, -58), 11.0]]],
	["ossuaire_sud", 75.0, [["minion", Vector3(-104, 0, -40), 9.0], ["minion", Vector3(-110, 0, -48), 9.0], ["guerrier", Vector3(-112, 0, -56), 10.0]]],
	["ossuaire_nord", 75.0, [["arbaletrier", Vector3(-100, 0, -82), 11.0], ["minion", Vector3(-92, 0, -86), 9.0], ["minion", Vector3(-108, 0, -76), 9.0]]],
	["lac_sud", 75.0, [["minion", Vector3(-84, 0, 18), 9.0], ["minion", Vector3(-94, 0, 18), 9.0], ["mage", Vector3(-100, 0, 12), 11.0]]],
	["forges_ouest", 75.0, [["guerrier", Vector3(38, 0, -126), 10.0], ["minion", Vector3(36, 0, -134), 9.0], ["arbaletrier", Vector3(44, 0, -152), 11.0]]],
	["forges_nord", 80.0, [["guerrier", Vector3(64, 0, -156), 10.0], ["arbaletrier", Vector3(72, 0, -150), 11.0]]],
]

## Quêtes de Bjorn l'Égaré : courtes, claires, récompensées tout de suite.
const QUETES := [
	{"id": "rampants", "titre": "Chasse aux rampants", "texte": "Les rampants grouillent près du nid. Abats-en dix et je te paierai.", "evt": "tue", "filtre": "minion", "but": 10, "or": 150},
	{"id": "cuivre", "titre": "Le cuivre des nains", "texte": "Rapporte-moi huit minerais de cuivre. Les filons brillent orange dans le noir.", "evt": "mine", "filtre": "minerai_cuivre", "but": 8, "or": 110, "xp_mine": 40},
	{"id": "coffres", "titre": "Pilleur de tombes", "texte": "Les morts n'ont plus besoin de leurs coffres. Ouvres-en trois.", "evt": "coffre", "filtre": "", "but": 3, "or": 200},
	{"id": "elite", "titre": "Tête couronnée", "texte": "Un Jarl, une Reine, un Forgeron déchu… abats l'un d'eux. Je t'offrirai un œuf que j'ai trouvé.", "evt": "tue", "filtre": "elite", "but": 1, "or": 400, "oeuf": "rare"},
	{"id": "boss", "titre": "Le Roi sous la montagne", "texte": "Quand Ymir se lève, tout l'étage tremble. Aide à l'abattre.", "evt": "tue", "filtre": "boss", "but": 1, "or": 1200, "oeuf": "epique"},
]

const DELAI_BOSS := 180.0         ## premier réveil d'Ymir (prototype : 3 min ; en ligne : heure fixe)
const ARENE_BOSS := Vector3(30, 0, -60)

var _quete_i := 0
var _quete_prog := 0
var _quete_active := false
var _boss_t := DELAI_BOSS
var _boss: Node = null
var _egare: Pnj

const RAYON_ACTIF := 55.0          ## au-delà, un draugr ne pense ni ne s'anime (économie sur téléphone)
const RAYON_DISCRET := 30.0        ## un camp ne se repeuple pas si un joueur est plus près que ça

var _camps := {}
var nav: NavCaverne

## Aventuriers pilotés par l'IA (4 à 7) : pseudo, classe, tempérament (agressivité).
const BOTS := [
	["Ragnhild", "chevalier", 0.05], ["xX_Ulfr_Xx", "barbare", 0.55], ["Leif.le.Roux", "chevalier", 0.15],
	["Astrid_77", "chevalier", 0.1], ["SkaldNoir", "barbare", 0.4], ["Bjarki", "chevalier", 0.25],
	["Freydis", "barbare", 0.08], ["Toki42", "chevalier", 0.7],
]
var _horloge := 0.0
var _lod_t := 0.0

func demarrer(p: Node, h: Heros, hd: CanvasLayer) -> void:
	principale = p
	heros = h
	hud = hd
	recit = CanvasLayer.new()
	recit.set_script(load("res://scripts/interface/recit.gd"))
	add_child(recit)
	recit.heros = h
	var poly := PackedVector2Array()
	for q in Caverne.CONTOUR:
		poly.append(q)
	for c in CAMPS:
		var centre := Vector3.ZERO
		for m in c[2]:
			centre += m[1]
			if not Geometry2D.is_point_in_polygon(Vector2(m[1].x, m[1].z), poly):
				push_warning("draugr hors de la caverne : %s %s" % [c[0], m[1]])
		centre /= float(c[2].size())
		_camps[c[0]] = {"def": c, "centre": centre, "vivants": [], "vide_depuis": -1.0}
		_peupler(c[0], false)
	_gardienne(Caverne.PUITS + Vector3(4.5, 0, 4.0), "Hilde", 30.0)
	var garde := Pnj.new()
	garde.role = "garde"
	garde.nom = "Sigrun"
	garde.titre = "Gardienne du camp"
	garde.garde = true
	garde.position = Caverne.CAMP + Vector3(-1.5, 0, -6.5)
	garde.rotation_degrees.y = 200.0
	p.add_child.call_deferred(garde)
	var egare := Pnj.new()
	egare.role = "marchand"
	egare.nom = "Bjorn l'Égaré"
	egare.titre = "Marchand"
	egare.marqueur = "?"
	egare.position = Caverne.CAMP + Vector3(-3.5, 0, 1.0)
	egare.rotation_degrees.y = 60.0
	p.add_child.call_deferred(egare)
	egare.marqueur = "!"
	egare.activer_parole(_parler_bjorn)
	_egare = egare
	Jeu.ecouteurs.append(_sur_evenement)
	Jeu.ecouteurs.append(_rune_evenement)
	Heros.jcj_actif = true
	_runes()
	_minicarte()
	if not "--sans-bots" in OS.get_cmdline_user_args():
		_lancer_bots()
	if "--test-repeuplement" in OS.get_cmdline_user_args():
		_test_repeuplement()
	if "--test-bots" in OS.get_cmdline_user_args():
		_test_bots()
	if "--test-quetes" in OS.get_cmdline_user_args():
		_test_quetes()
	if "--demo=bots" in OS.get_cmdline_user_args():
		_demo_bots()
	if "--test-runes" in OS.get_cmdline_user_args():
		_test_runes()
	if "--test-jcj" in OS.get_cmdline_user_args():
		_test_jcj()
	hud.regler_titre("Étage 1 · Crypte des nains", "Donjon du jour · se referme dans 14:52")
	recit.quete("Le donjon du jour", "Trouve Bjorn au camp des Égarés (est de la caverne)")
	await get_tree().create_timer(1.5).timeout
	if not Profil.p().vu("tuto_donjon"):
		Profil.p().marquer_vu("tuto_donjon")
		recit.voix("Freya", "Ici, je ne te vois presque plus. Reste près de la lumière.", 4.0)

# ---------------- quêtes ----------------

func _parler_bjorn(_h) -> void:
	if _quete_active or _quete_i >= QUETES.size():
		var q0: Dictionary = QUETES[mini(_quete_i, QUETES.size() - 1)]
		recit.voix("Bjorn", "%s : %d / %d. Reviens quand c'est fait." % [q0["titre"], _quete_prog, q0["but"]] if _quete_active else "Je n'ai plus rien pour toi aujourd'hui. Le donjon change à minuit.", 3.5)
		return
	var q: Dictionary = QUETES[_quete_i]
	Jeu.interface_bloquante = true
	recit.dire("Bjorn l'Égaré", "marchand", [q["texte"]])
	await recit.dialogue_fini
	Jeu.interface_bloquante = false
	_quete_active = true
	_quete_prog = 0
	_egare.regler_marqueur("")
	recit.quete(q["titre"], "0 / %d" % q["but"])

func _sur_evenement(nom: String, d: Dictionary) -> void:
	if not _quete_active:
		return
	var q: Dictionary = QUETES[_quete_i]
	if nom != q["evt"]:
		return
	match q["filtre"]:
		"":
			_quete_prog += 1
		"elite":
			if d.get("elite", false) and not d.get("boss", false) and d.get("joueur", false):
				_quete_prog += 1
		"boss":
			if d.get("boss", false):
				_quete_prog += 1
		_:
			if nom == "tue" and d.get("type", "") == q["filtre"] and d.get("joueur", false):
				_quete_prog += 1
			elif nom == "mine" and d.get("minerai", "") == q["filtre"]:
				_quete_prog += d.get("qte", 1)
	_quete_prog = mini(_quete_prog, q["but"])
	recit.quete_objectif("%d / %d" % [_quete_prog, q["but"]])
	if _quete_prog >= q["but"]:
		_quete_active = false
		var r := {"or": q["or"], "objets": []}
		if q.has("oeuf"):
			r["objets"].append(Objets.creer("oeuf", q["oeuf"]))
		heros.ramasser(r, q["titre"])
		if q.has("xp_mine"):
			heros.gagner_xp_mine(q["xp_mine"])
		recit.bandeau("Quête accomplie", q["titre"] + " — %d or" % q["or"], Color("#FFD34E"))
		Sons.jouer("cloche", heros.global_position, 0.0, 1.2)
		_quete_i += 1
		Jeu.evenement("quete", {"id": q["id"]})
		if _quete_i < QUETES.size():
			_egare.regler_marqueur("!")
			recit.quete("Bjorn a autre chose pour toi", "Retourne au camp des Égarés")

# ---------------- boss d'étage ----------------

func _maj_boss(delta: float) -> void:
	if _boss != null and is_instance_valid(_boss) and not _boss.est_mort:
		hud.regler_titre(hud._titre.text, "Ymir est éveillé ! · %d %%" % int(100.0 * _boss.pv / _boss.pv_max), Color("#FF6A4A"))
		return
	if _boss != null:
		# vaincu : prochain réveil plus tard
		_boss = null
		_boss_t = 600.0
		recit.bandeau("Ymir est tombé", "Son trésor gît dans l'arène", Color("#FFD34E"))
	_boss_t -= delta
	var m := int(_boss_t) / 60
	var sec := int(_boss_t) % 60
	if _lieu == "crypte" or _lieu == "caverne" or _lieu == "":
		hud.regler_titre(hud._titre.text, "Ymir, Roi des Draugr dans %d:%02d" % [m, sec], Color("#FFE2A0"))
	if absf(_boss_t - 30.0) < delta:
		recit.bandeau("La montagne gronde…", "Ymir se lève dans 30 secondes — Grande Caverne", Color("#FF9C8A"))
		Sons.jouer("coup_lourd", heros.global_position, 2.0, 0.5)
	if _boss_t <= 0.0:
		_reveiller_boss()

func _reveiller_boss() -> void:
	var b := Draugr.new()
	b.configurer("roi")
	b.position = ARENE_BOSS
	b.aggro_rayon = 16.0
	b.camp_id = "boss"
	principale.add_child(b)
	_boss = b
	Effets.onde(principale, ARENE_BOSS, 14.0, Color(1.0, 0.25, 0.1), 1.0)
	Effets.poussiere(principale, ARENE_BOSS, 30)
	recit.bandeau("Ymir, Roi des Draugr", "s'est éveillé au cœur de la Grande Caverne !", Color("#FF6A4A"))
	Sons.jouer("cloche", heros.global_position, 4.0, 0.5)
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("secouer"):
		cam.secouer(1.2)
	if hud.minicarte:
		hud.minicarte.lieux.append({"c": Vector2(ARENE_BOSS.x, ARENE_BOSS.z), "genre": "elite"})

# ---------------- runes draconiques ----------------
## Trois fragments, trois façons de les trouver, rien sur la carte :
## 1) derrière le lac, là où personne ne va ; 2) le gouffre, à qui le contemple assez longtemps ;
## 3) l'enclume de Brokk, une fois le forgeron déchu tombé. Ils réapparaissent à chaque descente
## tant que la voie draconique n'est pas choisie (perdus à la mort avec le sac).
const RUNE_LAC := Vector3(-106, 0, 2)
var _rune_abime := false
var _rune_forge := false

func _a_le_fragment(n: int) -> bool:
	for o in heros.sac.objets:
		if o.get("type", "") == "rune" and o.get("numero", 0) == n:
			return true
	for o in heros.sac.objets:
		if o.get("type", "") == "oeuf_runique":
			return true
	return false

func _runes() -> void:
	if Profil.p().classe != "":
		return
	if not _a_le_fragment(1):
		RuneDraconique.creer.call_deferred(principale, RUNE_LAC, 1)

func _rune_evenement(nom: String, d: Dictionary) -> void:
	if Profil.p().classe != "":
		return
	if nom == "abime" and not _rune_abime and not _a_le_fragment(2):
		_rune_abime = true
		# la rune remonte du gouffre, au bord, devant le joueur
		var g: Vector3 = d["pos"] - Caverne.GOUFFRE
		g.y = 0
		var bord := Caverne.GOUFFRE + g.normalized() * (Caverne.GOUFFRE_R.x * 0.9 if absf(g.x) > absf(g.z) else Caverne.GOUFFRE_R.y * 1.2)
		var pos: Vector3 = (bord + d["pos"]) * 0.5
		pos.y = 0
		var r := RuneDraconique.creer(principale, pos + Vector3(0, -2.5, 0), 2)
		r.create_tween().tween_property(r, "position:y", 0.0, 2.5).set_ease(Tween.EASE_OUT)
		Effets.etincelles(principale, pos + Vector3(0, 0.5, 0), Vector3.UP, Color(0.7, 0.4, 1.0), 30, 6.0, "star_06.png", 0.4)
		Sons.jouer("activation", pos, 0.0, 0.5)
		recit.voix("???", "Le vide t'a regardé aussi longtemps que tu l'as regardé.", 4.0)
	if nom == "tue" and d.get("type", "") == "brokk" and not _rune_forge and not _a_le_fragment(3):
		_rune_forge = true
		await get_tree().create_timer(3.0).timeout
		var pos2 := Caverne.ENCLUME_BROKK + Vector3(0, 0, 2.5)
		RuneDraconique.creer(principale, pos2, 3)
		Effets.onde(principale, pos2, 4.0, Color(0.7, 0.4, 1.0))
		recit.voix("???", "L'enclume se souvient de ce qu'on y a forgé.", 4.0)

# ---------------- aventuriers IA ----------------

func preparer() -> void:
	if nav != null:
		return
	nav = NavCaverne.new()
	await nav.construire(get_tree(), principale.get_world_3d(), 6000)

func _lancer_bots() -> void:
	await get_tree().create_timer(1.0).timeout
	if nav == null:
		await preparer()
	while not nav.pret:
		await get_tree().process_frame
	var noms := BOTS.duplicate()
	noms.shuffle()
	var n := randi_range(4, 7)
	# deux qui arrivent avec le joueur (on les voit tout de suite), les autres déjà dans la grotte
	var departs: Array = [Vector3(10, 0, 12), Vector3(18, 0, 16)]
	var ailleurs: Array = [Caverne.CAMP, Caverne.PUITS, Vector3(-20, 0, -40), Vector3(40, 0, -100), Vector3(-60, 0, -10), Vector3(0, 0, -70), Vector3(60, 0, -60)]
	ailleurs.shuffle()
	for i in n:
		var pos: Vector3 = departs[i] if i < departs.size() else ailleurs[(i - departs.size()) % ailleurs.size()]
		_creer_bot(noms[i], pos, i == 3)
		await get_tree().create_timer(0.35).timeout

func _creer_bot(fiche: Array, pos: Vector3, avec_dragon := false) -> Bot:
	var b := Heros.new()
	b.ia = true
	b.nom_joueur = fiche[0]
	b.classe_modele = Heros.CHEVALIER if fiche[1] == "chevalier" else Heros.MODELE
	b.name = "Bot_" + str(fiche[0]).validate_node_name()
	var c := nav.centre(nav.libre_pres(pos))
	b.position = c + Vector3(randf_range(-0.4, 0.4), 0.1, randf_range(-0.4, 0.4))
	principale.add_child(b)
	b.add_to_group("interactif")
	# équipement de départ : une arme, un peu d'or, des potions, parfois un dragon
	var arme := Objets.creer("grande_hache", Objets.tirer_rarete([0.6, 0.32, 0.07, 0.01, 0]))
	b.sac.arme = arme
	b.sac.ajouter_or(randi_range(20, 260))
	b.sac.ajouter(Objets.creer("potion", "commun", randi_range(0, 2)))
	if randf() < 0.5:
		b.sac.ajouter(Objets.creer(["minerai_cuivre", "minerai_fer", "tissu"][randi() % 3], "commun", randi_range(2, 8)))
	b.metier_mine["niveau"] = randi_range(1, 7)
	b.niveau = randi_range(8, 16)
	if avec_dragon:
		var d := Objets.eclore(Objets.creer("oeuf", "commun"))
		b.equiper_dragon(d)
	var cerveau := Bot.new()
	cerveau.h = b
	cerveau.nav = nav
	cerveau.scenario = self
	cerveau.agressivite = fiche[2]
	cerveau.prudence = randf_range(0.35, 0.6)
	cerveau.adresse = randf_range(0.45, 0.85)
	cerveau.add_to_group("bot_cerveau")
	cerveau.set_meta("fiche", fiche)
	add_child(cerveau)
	return cerveau

## Un aventurier IA est tombé : il revient du sanctuaire un peu plus tard, les poches vides.
func bot_mort(cerveau: Bot) -> void:
	var fiche: Array = cerveau.get_meta("fiche")
	var ancien := cerveau.h
	await get_tree().create_timer(randf_range(35.0, 80.0)).timeout
	if is_instance_valid(cerveau):
		cerveau.queue_free()
	if is_instance_valid(ancien):
		ancien.queue_free()
	if not is_inside_tree():
		return
	_creer_bot(fiche, Caverne.ARRIVEES[randi() % Caverne.ARRIVEES.size()])

func _gardienne(pos: Vector3, nom: String, rot: float) -> void:
	var g := Pnj.new()
	g.role = "garde"
	g.nom = nom
	g.titre = "Gardienne du camp"
	g.garde = true
	g.position = pos
	g.rotation_degrees.y = rot
	principale.add_child.call_deferred(g)

## Fait apparaître un camp. `reveil` : réapparition visible (les morts sortent de terre).
func _peupler(id: String, reveil: bool) -> void:
	var camp: Dictionary = _camps[id]
	camp["vivants"] = []
	camp["vide_depuis"] = -1.0
	for m in camp["def"][2]:
		var d := Draugr.new()
		d.configurer(m[0])
		d.position = m[1]
		d.aggro_rayon = m[2]
		d.camp_id = id
		principale.add_child.call_deferred(d)
		camp["vivants"].append(d)
		if reveil:
			Effets.poussiere.call_deferred(principale, m[1], 10, Color(0.5, 0.45, 0.4, 0.6))

func _heros_tous() -> Array:
	return get_tree().get_nodes_in_group("joueur").filter(func(x): return not x.est_mort)

func _repeupler(delta: float) -> void:
	_horloge += delta
	for id in _camps:
		var camp: Dictionary = _camps[id]
		camp["vivants"] = camp["vivants"].filter(func(d): return is_instance_valid(d) and not d.est_mort)
		if not camp["vivants"].is_empty():
			continue
		if camp["vide_depuis"] < 0.0:
			camp["vide_depuis"] = _horloge
			continue
		if _horloge - camp["vide_depuis"] < camp["def"][1]:
			continue
		var proche := false
		for hh in _heros_tous():
			if hh.global_position.distance_to(camp["centre"]) < RAYON_DISCRET:
				proche = true
		if not proche:
			_peupler(id, true)

## Les draugr loin de tout joueur dorment vraiment : ni IA, ni animation, ni dessin.
func _economie() -> void:
	var hs := _heros_tous().filter(func(x): return x.is_physics_processing())
	for d in get_tree().get_nodes_in_group("monstre"):
		if d.est_mort or not d is Draugr:
			continue
		var dist := 1e9
		for hh in hs:
			dist = minf(dist, d.global_position.distance_to(hh.global_position))
		var actif: bool = dist < RAYON_ACTIF or d.etat not in ["dort"]
		if actif != d.is_physics_processing():
			d.set_physics_process(actif)
			if d.modele:
				d.modele.visible = actif and (d.etat != "dort" or not d.fiche.get("enterre", false))
			if d.anim:
				if actif:
					d.anim.play()
				else:
					d.anim.pause()

func _minicarte() -> void:
	var mc: Control = hud.minicarte
	if mc == null:
		return
	mc.echelle = 0.75
	var pts := PackedVector2Array()
	for q in Caverne.CONTOUR:
		pts.append(q)
	mc.formes = [
		{"type": "poly", "pts": pts, "couleur": Color(0.24, 0.23, 0.25)},
		{"type": "rect", "r": Rect2(0, 0, 28, 28), "couleur": Color(0.3, 0.27, 0.24)},
		{"type": "cercle", "c": Vector2(Caverne.GOUFFRE.x, Caverne.GOUFFRE.z), "r": 8.0, "couleur": Color(0.02, 0.03, 0.06)},
		{"type": "cercle", "c": Vector2(Caverne.LAC.x, Caverne.LAC.z), "r": 10.0, "couleur": Color(0.04, 0.12, 0.14)},
	]
	mc.lieux = [
		{"c": Vector2(Caverne.CAMP.x, Caverne.CAMP.z), "genre": "sur"},
		{"c": Vector2(Caverne.ANTRE.x, Caverne.ANTRE.z), "genre": "elite"},
		{"c": Vector2(Caverne.DESCENTE.x, Caverne.DESCENTE.z), "genre": "portail"},
		{"c": Vector2(Caverne.CAMPEMENT.x, Caverne.CAMPEMENT.z), "genre": "danger"},
		{"c": Vector2(Caverne.AUTEL.x, Caverne.AUTEL.z), "genre": "danger"},
		{"c": Vector2(Caverne.NID.x, Caverne.NID.z), "genre": "danger"},
		{"c": Vector2(Caverne.PUITS.x, Caverne.PUITS.z), "genre": "sur"},
		{"c": Vector2(Caverne.TRONE_REINE.x, Caverne.TRONE_REINE.z), "genre": "elite"},
		{"c": Vector2(Caverne.ENCLUME_BROKK.x, Caverne.ENCLUME_BROKK.z), "genre": "elite"},
		{"c": Vector2(Caverne.LAC.x, Caverne.LAC.z), "genre": "danger"},
	]

func _process(_d: float) -> void:
	if heros == null or not is_instance_valid(heros):
		return
	_maj_boss(_d)
	_lod_t -= _d
	if _lod_t <= 0.0:
		_lod_t = 0.4
		_repeupler(0.4)
		_economie()
	var l := Caverne.lieu_de(heros.global_position)
	var id: String = l.get("id", "")
	if id == "" or id == _lieu:
		return
	_lieu = id
	Jeu.evenement("lieu", {"id": id})
	var nom: String = l["nom"]
	match id:
		"camp", "puits":
			recit.bandeau(nom, "Zone sûre — souffle, soigne-toi, repars", Color("#9DFFC8"))
			hud.regler_titre(nom, "Zone sûre", Color("#9DFFC8"))
			if id == "camp" and not _vus.has("camp"):
				recit.voix("Sigrun", "Pose ta hache, voyageur. Rien ne franchit ce cercle tant que je respire.", 4.5)
		"crypte":
			hud.regler_titre("Étage 1 · Crypte des nains", "Donjon du jour · se referme dans 14:52")
		"antre", "trone", "enclume":
			recit.bandeau(nom, "Élite — un coffre légendaire dort derrière lui", Color("#FF9A2E"))
			hud.regler_titre("Étage 1 · " + nom, "Élite", Color("#FF9A2E"))
		"lac", "ossuaire", "forges":
			var sous: String = {"lac": "Ceux qui sont tombés à l'eau ne dorment pas", "ossuaire": "Les rois morts gardent leurs tombes", "forges": "Le feu des nains brûle encore"}[id]
			if not _vus.has(id):
				recit.bandeau(nom, sous, Color("#FF9C8A"))
			hud.regler_titre("Étage 1 · " + nom, "Zone hostile", Color("#FF9C8A"))
		"descente":
			recit.bandeau(nom, "Étage 2 — scellé pour l'instant", Color("#9FE6FF"))
			hud.regler_titre("Étage 1 · " + nom, "Vers l'étage 2", Color("#9FE6FF"))
		"caverne":
			if not _vus.has("caverne"):
				recit.bandeau(nom, "Étage 1 — zone hostile", Color("#FF9C8A"))
				recit.quete("La Grande Caverne", "Explore — un camp sûr se cache à l'est")
			hud.regler_titre("Étage 1 · " + nom, "Zone hostile", Color("#FF9C8A"))
		_:
			if not _vus.has(id):
				recit.bandeau(nom, "Zone hostile", Color("#FF9C8A"))
			hud.regler_titre("Étage 1 · " + nom, "Zone hostile", Color("#FF9C8A"))
	_vus[id] = true

func _test_repeuplement() -> void:
	await get_tree().create_timer(2.0).timeout
	for d in _camps["est"]["vivants"]:
		d.recevoir({"montant": 99999.0})
	for t in [5, 40, 70]:
		await get_tree().create_timer(t - (0 if t == 5 else 0)).timeout
		var n: int = _camps["est"]["vivants"].filter(func(d): return is_instance_valid(d) and not d.est_mort).size()
		var actifs := get_tree().get_nodes_in_group("monstre").filter(func(d): return not d.est_mort and d.is_physics_processing()).size()
		var total := get_tree().get_nodes_in_group("monstre").filter(func(d): return not d.est_mort).size()
		printerr("TEST t+", t, " camp est vivants=", n, " draugr actifs=", actifs, "/", total)
	get_tree().quit()

func _test_bots() -> void:
	heros.invulnerable_t = 1e9
	var t0 := Time.get_ticks_msec()
	while nav == null or not nav.pret:
		await get_tree().process_frame
	printerr("TEST nav prête en ", Time.get_ticks_msec() - t0, " ms (dont 1 s d'attente)")
	for i in 8:
		await get_tree().create_timer(13.0).timeout
		var somme := 0.0
		var pire := 0.0
		for f in 120:
			await get_tree().physics_frame
			var v := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
			somme += v
			pire = maxf(pire, v)
		printerr("TEST physique moyenne=", snappedf(somme / 120.0, 0.01), " ms pire=", snappedf(pire, 0.01), " ms")
		var tues := 0
		for c in get_tree().get_nodes_in_group("bot_cerveau"):
			var b: Heros = c.h
			printerr("TEST t=", (i + 1) * 15, " ", b.nom_joueur, " reel=", c.reel, " etat=", c.etat, " obj=", c.objectif.get("genre", "-"), "/", c.objectif.get("camp", ""), " pos=", Vector3i(b.global_position), " pv=", int(b.pv), " sac=", b.sac.valeur(), " mort=", b.est_mort, " afk=", c.afk)
		var actifs := get_tree().get_nodes_in_group("monstre").filter(func(d): return not d.est_mort and d.is_physics_processing()).size()
		printerr("TEST draugr actifs=", actifs, " fps=", Engine.get_frames_per_second(), " ms_phys=", snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.01), " ms_proc=", snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.01))
	get_tree().quit()

func _cap(nom: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/scr/jcj_%s.png" % nom)

func _test_jcj() -> void:
	while nav == null or not nav.pret:
		await get_tree().process_frame
	await get_tree().create_timer(4.0).timeout
	heros.global_position = Vector3(14, 0.1, -6)
	var cerveaux := get_tree().get_nodes_in_group("bot_cerveau")
	var i := 0
	for c in cerveaux:
		if i < 3:
			c.h.global_position = Vector3(11 + i * 3, 0.1, -9 - i)
			c.objectif = {}
		i += 1
	await get_tree().create_timer(1.0).timeout
	_cap("1_voisins")
	var pillard: Bot = cerveaux[0]
	pillard.h.declarer_hostile(heros)
	var pv0 := heros.pv
	await get_tree().create_timer(5.0).timeout
	_cap("2_attaque")
	printerr("TEST pv joueur ", int(pv0), " -> ", int(heros.pv), " ; pillard à ", snappedf(pillard.h.global_position.distance_to(heros.global_position), 0.1), " m")
	var avant := heros.sac.valeur()
	pillard.h.recevoir({"montant": 1e6, "source": heros})
	await get_tree().create_timer(1.5).timeout
	printerr("TEST sac joueur avant=", avant, " après=", heros.sac.valeur(), " (butin du pillard)")
	_cap("3_pillard_tombe")
	# boss
	heros.invulnerable_t = 1e9
	heros.global_position = ARENE_BOSS + Vector3(0, 0.1, 13)
	_boss_t = 0.3
	await get_tree().create_timer(4.0).timeout
	_cap("4_boss")
	if _boss:
		_boss.cible = heros
		_boss.reveiller(heros)
		await get_tree().create_timer(4.0).timeout
		_cap("5_boss_attaque")
		_boss.pv = _boss.pv_max * 0.45
		_boss.recevoir({"montant": 10.0, "source": heros})
		await get_tree().create_timer(2.0).timeout
		_cap("6_boss_rage")
		printerr("TEST boss pv=", int(_boss.pv), "/", int(_boss.pv_max), " etat=", _boss.etat)
	get_tree().quit()

func _test_quetes() -> void:
	await get_tree().create_timer(2.0).timeout
	printerr("TEST Bjorn interactif=", _egare.is_in_group("interactif"), " action=", _egare.texte_action())
	var evts := [["tue", {"type": "minion", "joueur": true}, 10], ["mine", {"minerai": "minerai_cuivre", "qte": 3}, 3],
		["coffre", {}, 3], ["tue", {"type": "jarl", "joueur": true, "elite": true}, 1], ["tue", {"type": "roi", "boss": true, "elite": true}, 1]]
	for e in evts:
		_quete_active = true
		_quete_prog = 0
		var i0 := _quete_i
		var or0 := heros.sac.or_
		for k in e[2]:
			Jeu.evenement(e[0], e[1])
		printerr("TEST quête ", QUETES[i0]["id"], " finie=", _quete_i > i0, " or +", heros.sac.or_ - or0, " oeufs=", heros.sac.compter("oeuf"))
	get_tree().quit()

## Démonstration filmée : le héros joue tout seul (farm, coffres, filons) au milieu des autres aventuriers ;
## un pillard l'attaque, puis Ymir se réveille.
func _demo_bots() -> void:
	_boss_t = 999.0
	while nav == null or not nav.pret:
		await get_tree().process_frame
	heros.sac.ajouter(Objets.creer("potion", "commun", 6))
	heros.set_meta("pilote_auto", true)
	var pilote := Bot.new()
	pilote.h = heros
	pilote.nav = nav
	pilote.scenario = self
	pilote.agressivite = 0.0
	pilote.adresse = 0.9
	add_child(pilote)
	pilote._t_afk = 1e9
	pilote.objectif = {"genre": "objet", "noeud": null, "pos": Vector3(12, 0, -12)}
	pilote._aller_vers(Vector3(12, 0, -12))
	await get_tree().create_timer(38.0).timeout
	var proche: Bot = null
	for c in get_tree().get_nodes_in_group("bot_cerveau"):
		if not c.h.est_mort and (proche == null or c.h.global_position.distance_to(heros.global_position) < proche.h.global_position.distance_to(heros.global_position)):
			proche = c
	if proche:
		proche.h.global_position = nav.centre(nav.libre_pres(heros.global_position + Vector3(6, 0, 4)))
		proche.h.declarer_hostile(heros)
	await get_tree().create_timer(24.0).timeout
	# fondu vers l'arène : Ymir se lève
	heros.global_position = nav.centre(nav.libre_pres(ARENE_BOSS + Vector3(0, 0, 13)))
	pilote.objectif = {"genre": "attente", "pos": heros.global_position}
	pilote._chemin = PackedVector3Array()
	_boss_t = 2.5
	await get_tree().create_timer(5.0).timeout
	pilote.objectif = {"genre": "camp", "camp": "", "pos": ARENE_BOSS}
	pilote._aller_vers(ARENE_BOSS)
	await get_tree().create_timer(22.0).timeout
	get_tree().quit()

func _test_runes() -> void:
	heros.invulnerable_t = 1e9
	while nav == null or not nav.pret:
		await get_tree().process_frame
	var ch := nav.chemin(Vector3(14, 0, 10), RUNE_LAC)
	printerr("TEST chemin crypte -> rune du lac : ", ch.size(), " points, fin ", ch[ch.size() - 1] if ch.size() > 0 else "aucun")
	for n in [1, 2, 3]:
		if n == 2:
			Jeu.evenement("abime", {"pos": Caverne.GOUFFRE + Vector3(0, 0, 9)})
			await get_tree().create_timer(3.0).timeout
		if n == 3:
			Jeu.evenement("tue", {"type": "brokk", "elite": true, "joueur": true})
			await get_tree().create_timer(3.5).timeout
		var rune: RuneDraconique = null
		for r in get_tree().get_nodes_in_group("interactif"):
			if r is RuneDraconique and r.numero == n:
				rune = r
		if rune == null:
			printerr("TEST rune ", n, " ABSENTE")
			continue
		heros.global_position = rune.global_position + Vector3(0, 0.1, 2.0)
		await get_tree().create_timer(1.0).timeout
		if n == 1:
			await _cap("rune")
		rune.interagir(heros)
		await get_tree().create_timer(3.0).timeout
		printerr("TEST rune ", n, " prise=", rune == null or not is_instance_valid(rune) or rune.pris)
	await get_tree().create_timer(0.5).timeout
	await _cap("fusion")
	var oeufs := heros.sac.objets.filter(func(o): return o["type"] == "oeuf_runique")
	printerr("TEST oeuf runique=", oeufs.size(), " fragments restants=", heros.sac.objets.filter(func(o): return o["type"] == "rune").size(), " runes codex=", Profil.p().valeur("runes"))
	get_tree().quit()
