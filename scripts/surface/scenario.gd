extends Node
## Le premier quart d'heure du joueur, vu de sa place :
## 1. Il se réveille au sanctuaire ; Freya lui parle (qui elle est, ce qu'est le donjon, ce que coûte la mort).
## 2. Une traînée dorée l'emmène dans le bois ; dans la clairière, trois draugr sortent de terre : premier combat.
## 3. Il atteint le Bourg de Skjold : chaleur, lumière, gardes. « Ici tu es en sécurité. »
## 4. Le Portail d'Yggdrasil, au nord du Bourg, lui montre le donjon du jour.

var principale: Node
var heros: Heros
var hud: CanvasLayer
var recit: CanvasLayer
var guide: Guide
var etape := 0
var _lieu_actuel := ""
var _draugr_clairiere: Array = []
var freya: Pnj
var _pnjs: Array = []
var _bandeaux_vus := {}

const NOM_JOUR := "Crypte des nains"

func demarrer(p: Node, h: Heros, hd: CanvasLayer, sans_intro := false) -> void:
	principale = p
	heros = h
	hud = hd
	recit = CanvasLayer.new()
	recit.set_script(load("res://scripts/interface/recit.gd"))
	add_child(recit)
	recit.heros = h
	guide = Guide.new()
	guide.heros = h
	p.add_child.call_deferred(guide)
	_pnj_et_monstres()
	_minicarte()
	# la Horde des Terres Gâtées (le squelette est « cuit » pendant le chargement)
	essaim = Essaim.new()
	essaim.name = "Horde"
	p.add_child.call_deferred(essaim)
	village = Village.new()
	village.name = "Hameau"
	p.add_child.call_deferred(village)
	village.demarrer.call_deferred(p)
	_annoncer_pouvoirs()
	if "--depart=bourg" in OS.get_cmdline_user_args():
		# reprise de tournage : le joueur arrive à la porte du Bourg après le combat du chemin
		etape = 3
		for d in _draugr_clairiere:
			d.queue_free()
		_draugr_clairiere.clear()
		h.position = Vector3(95.0, 0.1, 46.5)
		h.pv = 2250.0
		h.pv_change.emit(h.pv, h.pv_max)
		_quete_bourg()
	elif Profil.p().vu("tuto_bourg"):
		# didacticiel déjà vu (une seule fois par joueur) : on repart directement vers le Portail
		_vers_portail()
	elif sans_intro or Profil.p().vu("tuto_intro"):
		etape = 1
		_quete_bourg()
	else:
		_intro.call_deferred()

# ---------------- mise en place ----------------

func _pnj(role: String, nom: String, titre: String, pos: Vector3, rot_deg: float, garde := false) -> Pnj:
	var n := Pnj.new()
	n.role = role
	n.nom = nom
	n.titre = titre
	n.garde = garde
	n.position = pos
	n.rotation_degrees.y = rot_deg
	principale.add_child.call_deferred(n)
	_pnjs.append(n)
	return n

func _pnj_et_monstres() -> void:
	var s := CarteSurface.SANCTUAIRE
	freya = _pnj("freya", "Freya", "Dame des Vanes", s + Vector3(0, 0, -3.6), 0.0)
	freya.marqueur = "!"
	_pnj("garde", "Garde de Skjold", "", Vector3(101.2, 0, 44.6), -90.0, true)
	_pnj("garde", "Garde de Skjold", "", Vector3(101.2, 0, 51.6), -90.0, true)
	_pnj("garde", "Garde de Skjold", "", Vector3(123.4, 0, 19.6), 180.0, true)
	_pnj("garde", "Garde de Skjold", "", Vector3(130.6, 0, 19.6), 180.0, true)
	var m := _pnj("marchand", "Halvard", "Marchand", Vector3(137.2, 0, 44.6), 200.0)
	m.marqueur = "$"
	m.activer_parole(func(h):
		var ui := CanvasLayer.new()
		ui.set_script(load("res://scripts/interface/comptoir_ui.gd"))
		principale.add_child(ui)
		ui.ouvrir(h, "marchand"))
	CoffrePerso.creer.call_deferred(principale, Vector3(140.5, 0, 41.5), 200.0)
	var f := _pnj("forgeron", "Ingrid", "Forgeronne", Vector3(117.2, 0, 30.2), 240.0)
	f.marqueur = "!"
	f.activer_parole(func(h):
		var ui := CanvasLayer.new()
		ui.set_script(load("res://scripts/interface/comptoir_ui.gd"))
		principale.add_child(ui)
		ui.ouvrir(h, "forge"))
	# clairière : trois rampants enterrés, autour du chemin
	var c := CarteSurface.CLAIRIERE
	for d in [Vector3(-2.5, 0, -3.0), Vector3(3.5, 0, 1.5), Vector3(-1.0, 0, 4.5)]:
		var dr := Draugr.new()
		dr.configurer("minion")
		dr.position = c + d
		dr.aggro_rayon = 8.0
		principale.add_child.call_deferred(dr)
		_draugr_clairiere.append(dr)
	# sur le chemin, plus loin : un guerrier qui monte la garde, escorté d'un tireur
	if "--depart=bourg" in OS.get_cmdline_user_args():
		return
	for d in [["guerrier", Vector3(86, 0, 50.5)], ["arbaletrier", Vector3(92.0, 0, 45.5)]]:
		var dr2 := Draugr.new()
		dr2.configurer(d[0])
		dr2.position = d[1]
		principale.add_child.call_deferred(dr2)

func _minicarte() -> void:
	var mc: Control = hud.minicarte
	if mc == null:
		return
	mc.echelle = 0.85
	var pts: Array = []
	for p in CarteSurface.CHEMIN:
		pts.append(p)
	var lac: Array = []
	for i in 28:
		var a := TAU * i / 28.0
		lac.append(PlanMonde.LAC_CENTRE + Vector2(cos(a) * PlanMonde.LAC_RAYONS.x, sin(a) * PlanMonde.LAC_RAYONS.y) * (1.0 + 0.08 * sin(a * 3.0 + 0.6) + 0.05 * sin(a * 7.0)))
	mc.formes = [
		{"type": "rect", "r": PlanMonde.LIMITES.grow(60), "couleur": Color(0.11, 0.18, 0.11)},
		{"type": "poly", "pts": lac, "couleur": Color(0.16, 0.32, 0.38)},
		{"type": "rect", "r": PlanMonde.CHAMPS_JARNBORG, "couleur": Color(0.42, 0.38, 0.2)},
		{"type": "cercle", "c": Vector2(CarteSurface.SANCTUAIRE.x, CarteSurface.SANCTUAIRE.z), "r": 11.0, "couleur": Color(0.22, 0.32, 0.18)},
		{"type": "cercle", "c": Vector2(CarteSurface.CLAIRIERE.x, CarteSurface.CLAIRIERE.z), "r": 12.0, "couleur": Color(0.22, 0.32, 0.18)},
		{"type": "rect", "r": CarteSurface.BOURG, "couleur": Color(0.36, 0.29, 0.2)},
		{"type": "cercle", "c": Vector2(CarteSurface.PLACE.x, CarteSurface.PLACE.z), "r": 14.0, "couleur": Color(0.48, 0.44, 0.38)},
		{"type": "rect", "r": PlanMonde.JARNBORG, "couleur": Color(0.42, 0.4, 0.36)},
		{"type": "rect", "r": PlanMonde.BREKKA, "couleur": Color(0.34, 0.3, 0.22)},
		{"type": "rect", "r": PlanMonde.VIK, "couleur": Color(0.3, 0.33, 0.24)},
		{"type": "rect", "r": PlanMonde.HRAFN, "couleur": Color(0.36, 0.15, 0.12)},
		{"type": "cercle", "c": Vector2(PlanMonde.SKARN.x, PlanMonde.SKARN.z), "r": 18.0, "couleur": Color(0.36, 0.15, 0.12)},
		{"type": "rect", "r": CarteSurface.TERRES, "couleur": Color(0.28, 0.13, 0.1)},
		{"type": "ligne", "pts": pts, "couleur": Color(0.78, 0.66, 0.46), "largeur": 3.0},
		{"type": "ligne", "pts": CarteSurface.ROUTE_TERRES, "couleur": Color(0.6, 0.45, 0.35), "largeur": 2.0},
	]
	for r in PlanMonde.ROUTES:
		mc.formes.append({"type": "ligne", "pts": r[0], "couleur": Color(0.72, 0.6, 0.42), "largeur": 2.4})
	mc.formes.append({"type": "ligne", "pts": [Vector2(-135, -103), Vector2(-135, -180)], "couleur": Color(0.6, 0.58, 0.54), "largeur": 2.4})
	mc.formes.append({"type": "ligne", "pts": [Vector2(-72, -150), Vector2(-196, -150)], "couleur": Color(0.6, 0.58, 0.54), "largeur": 2.4})
	mc.lieux = [
		{"c": Vector2(CarteSurface.SANCTUAIRE.x, CarteSurface.SANCTUAIRE.z), "genre": "sanctuaire"},
		{"c": Vector2(CarteSurface.PLACE.x, CarteSurface.PLACE.z), "genre": "sur"},
		{"c": Vector2(CarteSurface.PORTAIL.x, CarteSurface.PORTAIL.z), "genre": "portail"},
		{"c": Vector2(CarteSurface.CLAIRIERE.x, CarteSurface.CLAIRIERE.z), "genre": "danger"},
		{"c": Vector2(151, 100), "genre": "elite"},
		{"c": Vector2(PlanMonde.PLACE_JARNBORG.x, PlanMonde.PLACE_JARNBORG.z), "genre": "sur"},
	]
	if not Pillards.conquis("hrafn"):
		mc.lieux.append({"c": Vector2(128, -180), "genre": "elite"})
	if not Pillards.conquis("skarn"):
		mc.lieux.append({"c": Vector2(PlanMonde.SKARN.x, PlanMonde.SKARN.z), "genre": "elite"})

func _bloquer(b: bool) -> void:
	heros.set_physics_process(not b)
	if principale.joy:
		principale.joy.set_process_input(not b)
	heros.entree = Vector2.ZERO
	for bt in hud.racine.get_children():
		if bt.has_method("preparer"):
			bt.set_process_input(not b)

# ---------------- étapes ----------------

func _intro() -> void:
	_bloquer(true)
	# couché dans l'herbe sacrée, Freya penchée au-dessus de lui
	heros.jouer("Lie_StandUp", 0.0, 0.0)
	if heros.anim:
		heros.anim.seek(0.0, true)
		heros.anim.pause()
	heros.rotation.y = PI
	hud.regler_titre("Le Val des Racines", "Sanctuaire de Freya")
	await get_tree().create_timer(1.2).timeout
	recit.dire("Freya", "freya", [
		"Respire, guerrier. Les racines d'Yggdrasil t'ont recraché… et c'est moi, Freya, qui t'ai rattrapé.",
		"Chaque jour, l'Arbre ouvre un donjon nouveau sous Midgard. Tous les guerriers du Val y descendent. Peu en remontent chargés.",
		"Quand tu tomberas là-dessous — et tu tomberas — je te ramènerai. Mais nu : ton équipement restera sur ton corps, et d'autres voudront le prendre.",
		"Suis la lumière dorée jusqu'au Bourg de Skjold. Là-bas, personne ne lèvera son arme contre toi.",
	])
	await recit.dialogue_fini
	freya.regler_marqueur("")
	if heros.anim:
		heros.anim.play("Lie_StandUp", 0.0, 1.2)
	await get_tree().create_timer(1.9).timeout
	heros.verrou_anim = 0.0
	heros.jouer("2H_Melee_Idle", 0.3)
	_bloquer(false)
	Profil.p().marquer_vu("tuto_intro")
	etape = 1
	_quete_bourg()

var essaim: Essaim
var village: Village
var _t_village := 0.0
var _dans_terres := false

func _terres(dans: bool) -> void:
	if dans == _dans_terres or essaim == null:
		return
	_dans_terres = dans
	if dans:
		essaim.demarrer(heros, CarteSurface.TERRES, 260)
		if not Profil.p().vu("terres_vues"):
			Profil.p().marquer_vu("terres_vues")
			recit.bandeau("Terres Gâtées", "La Horde se lève sans fin. Montre-leur ta puissance.", Color("#FF9C8A"))
		else:
			recit.bandeau("Terres Gâtées", "La Horde se lève", Color("#FF9C8A"))
	else:
		essaim.arreter()

func _quete_bourg() -> void:
	recit.quete("Rejoindre le Bourg de Skjold", "Suis la lumière dorée", CarteSurface.PORTE_BOURG)
	guide.viser(CarteSurface.PORTE_BOURG)
	hud.minicarte.cible = Vector2(CarteSurface.PORTE_BOURG.x, CarteSurface.PORTE_BOURG.z)

func _process(_d: float) -> void:
	if heros == null or not is_instance_valid(heros):
		return
	_lieux()
	_t_village -= _d
	if _lieu_actuel in ["village", "jarnborg", "vik"] and village and _t_village <= 0.0:
		_t_village = 2.0
		hud.regler_titre(CarteSurface.lieu_de(heros.global_position).get("nom", ""), village.texte_heure(), Color("#FFE2A0"))
	_terres(CarteSurface.TERRES.grow(2.0).has_point(Vector2(heros.global_position.x, heros.global_position.z)))
	# le Portail se montre : la caméra s'ouvre vers lui quand on approche
	var cam := get_viewport().get_camera_3d()
	if cam and "point_interet" in cam:
		var dp := heros.global_position.distance_to(CarteSurface.PORTAIL)
		if dp < 20.0:
			cam.point_interet = CarteSurface.PORTAIL + Vector3(0, 0, 0.5)
			cam.poids_interet = clampf((20.0 - dp) / 10.0, 0.0, 1.0) * 0.85
		else:
			cam.poids_interet = 0.0
	match etape:
		1:
			var reste := heros.global_position.distance_to(CarteSurface.PORTE_BOURG)
			recit.quete_objectif("Suis la lumière dorée · %d m" % int(reste))
			if heros.global_position.distance_to(CarteSurface.CLAIRIERE) < 13.0:
				etape = 2
				for d in _draugr_clairiere:
					d.reveiller(heros)
				guide.arreter()
				recit.voix("Freya", "Des draugr ! Touche un sort pour frapper, glisse le doigt pour viser.", 4.5)
				recit.quete("Les Tertres s'éveillent", "Vaincs les draugr (0/3)")
		2:
			var morts := _draugr_clairiere.filter(func(d): return not is_instance_valid(d) or d.est_mort).size()
			recit.quete_objectif("Vaincs les draugr (%d/3)" % morts)
			if morts >= 3:
				etape = 3
				recit.voix("Freya", "Bien. Le Bourg n'est plus loin : continue vers l'est.", 3.5)
				_quete_bourg()
		3:
			var reste2 := heros.global_position.distance_to(CarteSurface.PORTE_BOURG)
			recit.quete_objectif("Suis la lumière dorée · %d m" % int(reste2))
			if ZoneSure.contient(heros.global_position):
				etape = 4
				_arrivee_bourg()
		5:
			var reste3 := heros.global_position.distance_to(CarteSurface.PORTAIL)
			recit.quete_objectif("Au nord du Bourg · %d m" % int(reste3))
			if reste3 < 12.0:
				etape = 6
				guide.arreter()
				hud.minicarte.cible = Vector2.INF
				if not Profil.p().vu("tuto_portail"):
					Profil.p().marquer_vu("tuto_portail")
					recit.voix("Freya", "Le donjon du jour : la Crypte des nains. Il se refermera à minuit… avec ceux qui y seront encore.", 5.5)
				recit.quete("Le donjon du jour", "Entre dans le Portail quand tu es prêt")

func _vers_portail() -> void:
	etape = 5
	recit.quete("Le Portail d'Yggdrasil", "Au nord du Bourg", CarteSurface.PORTAIL)
	guide.viser(CarteSurface.PORTAIL + Vector3(0, 0, 6))
	hud.minicarte.cible = Vector2(CarteSurface.PORTAIL.x, CarteSurface.PORTAIL.z)

func _arrivee_bourg() -> void:
	if Profil.p().vu("tuto_bourg"):
		_vers_portail()
		return
	guide.arreter()
	hud.minicarte.cible = Vector2.INF
	await get_tree().create_timer(1.2).timeout
	_bloquer(true)
	recit.dire("Freya", "freya", [
		"Te voilà au Bourg de Skjold. Ici, tu es en sécurité : les gardes tranchent quiconque tire son arme dans l'enceinte.",
		"Halvard achète ce que tu remontes, Ingrid forge et répare. Garde toujours de quoi te rééquiper : le donjon ne rend jamais ce qu'il prend.",
		"Tout ce que tu accomplis là-dessous s'inscrit dans ton Codex. Chaque exploit te donne des points à planter dans l'Arbre des Racines : ce que tu y fais pousser, toi seul le décides.",
		"Et cherche des reliques. Même la plus modeste te rendra plus fort, et celles qui brillent orange ou rouge… on se bat pour elles.",
		"Une dernière chose. On dit que les dragons d'autrefois ont laissé leurs runes à qui regarde là où personne ne regarde. Je n'en dirai pas plus : certaines voies ne s'enseignent pas.",
		"Quand tu seras prêt, le Portail d'Yggdrasil t'attend au nord du Bourg.",
	])
	await recit.dialogue_fini
	_bloquer(false)
	Profil.p().marquer_vu("tuto_bourg")
	Profil.p().sauver()
	Jeu.notifier("Codex et Arbre des Racines : en haut à droite.", Color("#FFD36B"), "res://assets/icones_sorts/codex.svg")
	etape = 5
	recit.quete("Le Portail d'Yggdrasil", "Au nord du Bourg", CarteSurface.PORTAIL)
	guide.viser(CarteSurface.PORTAIL + Vector3(0, 0, 6))
	hud.minicarte.cible = Vector2(CarteSurface.PORTAIL.x, CarteSurface.PORTAIL.z)

## Bandeau et titre quand on change de lieu.
func _lieux() -> void:
	var l := CarteSurface.lieu_de(heros.global_position)
	var id: String = l.get("id", "")
	if id == _lieu_actuel or id == "":
		return
	_lieu_actuel = id
	match id:
		"terres":
			hud.regler_titre("Terres Gâtées", "La Horde ne s'arrête jamais", Color("#FF9C8A"))
		"village":
			if not Profil.p().vu("village_vu"):
				Profil.p().marquer_vu("village_vu")
				recit.bandeau("Hameau de Brekka", "Treize habitants, deux gardes, et des maisons pleines…", Color("#FFE2A0"))
			hud.regler_titre("Hameau de Brekka", village.texte_heure() if village else "", Color("#FFE2A0"))
		"jarnborg":
			if not Profil.p().vu("jarnborg_vu"):
				Profil.p().marquer_vu("jarnborg_vu")
				recit.bandeau("Jarnborg, la capitale", "Le Jarl, ses huscarls, ses marchés… et des maisons pleines", Color("#FFE2A0"))
			hud.regler_titre("Jarnborg, la capitale", village.texte_heure() if village else "", Color("#FFE2A0"))
		"vik":
			recit.bandeau("Vik du Lac", "Pêcheurs, moulin à eau, et la taverne de l'Anguille", Color("#BFF0D0"))
			hud.regler_titre("Vik du Lac", village.texte_heure() if village else "", Color("#BFF0D0"))
		"lac":
			hud.regler_titre("Le Val des Racines", "Lac des Brumes")
		"hrafn", "skarn":
			var conq := Pillards.conquis(id)
			recit.bandeau(l["nom"], "Conquis — le repaire est à toi" if conq else "Repaire ennemi : ils attaquent à vue", Color("#9DFFC8") if conq else Color("#FF9C8A"))
			hud.regler_titre(l["nom"], "conquis" if conq else "zone hostile", Color("#9DFFC8") if conq else Color("#FF9C8A"))
		"carriere":
			hud.regler_titre("Carrière de Dvalin", "Pierre et minerai")
		"pierres":
			recit.bandeau("Pierres d'Odin", "Un vieux cercle. L'air y vibre.", Color("#BFD8FF"))
			hud.regler_titre("Pierres d'Odin", "")
		"tour":
			hud.regler_titre("Tour du Guet", "ruines")
		"bourg":
			recit.bandeau("Bourg de Skjold", "Zone sûre — les armes restent au fourreau", Color("#9DFFC8"))
			hud.regler_titre("Bourg de Skjold", "Zone sûre", Color("#9DFFC8"))
		"portail":
			recit.bandeau("Portail d'Yggdrasil", "Donjon du jour : " + NOM_JOUR + " · se referme dans 14:52", Color("#9FE6FF"))
			hud.regler_titre("Portail d'Yggdrasil", "Donjon du jour : " + NOM_JOUR, Color("#9FE6FF"))
		"clairiere":
			recit.bandeau("Clairière des Tertres", "Les morts y dorment mal", Color("#FF9C8A"))
			hud.regler_titre("Le Val des Racines", "Clairière des Tertres · zone hostile", Color("#FF9C8A"))
		"sanctuaire":
			hud.regler_titre("Le Val des Racines", "Sanctuaire de Freya")
		"bois":
			if etape >= 1 and not _bandeaux_vus.has("bois"):
				_bandeaux_vus["bois"] = true
				recit.bandeau("Bois des Murmures", "Zone hostile", Color("#FF9C8A"))
			hud.regler_titre("Le Val des Racines", "Bois des Murmures · zone hostile", Color("#FF9C8A"))


## Une seule fois : Freya annonce l'éveil du mana et des pouvoirs du monde.
func _annoncer_pouvoirs() -> void:
	if Profil.p().vu("tuto_pouvoirs"):
		return
	await get_tree().create_timer(6.0).timeout
	if Profil.p().vu("tuto_pouvoirs") or not is_inside_tree():
		return
	Profil.p().marquer_vu("tuto_pouvoirs")
	recit.voix("Freya", "Le mana coule en toi. Regarde à droite : tes pouvoirs t'attendent. La minicarte ouvre le monde entier.", 6.0)
	Jeu.notifier("Pouvoirs : téléportation, moisson, contrôle d'esprit, déchaînement.", Color("#D9B8FF"), "res://assets/icones_sorts/pouvoir_dechainement.svg")
