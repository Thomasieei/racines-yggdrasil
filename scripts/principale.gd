extends Node3D
## Scène principale de la tranche verticale : salle d'entrée, héros, caméra, commandes.
## Lancement avec capture : godot -- --capture=chemin.png [--frames=90] [--pos=x,z]

var joueur: Heros
var camera: Camera3D
var hud: CanvasLayer

## Meutes de la crypte d'entrée : un guerrier escorté au centre, des tireurs en retrait au fond.
const MEUTES := [
	["guerrier", Vector3(14, 0, 11.5)],
	["minion", Vector3(11.4, 0, 13.0)],
	["minion", Vector3(16.6, 0, 13.0)],
	["arbaletrier", Vector3(6.5, 0, 4.8)],
	["mage", Vector3(21.5, 0, 6.5)],
]

const TOUCHES := {KEY_1: "q", KEY_2: "w", KEY_3: "e", KEY_4: "r", KEY_5: "f", KEY_6: "p", KEY_SPACE: "d"}

var carte := "surface"
var joy: Control
## Passage d'une carte à l'autre (portail, mort) : on recharge la scène avec la carte demandée.
static var carte_suivante := ""
static var sans_intro_suivante := false
static var sac_suivant: Sac              ## le sac suit le joueur d'une carte à l'autre (pas à la mort)
var monde: Node3D

var chargement: CanvasLayer

func _ready() -> void:
	# écran de chargement d'abord : la construction du monde et la compilation des effets
	# se font derrière lui, le joueur ne voit jamais d'image figée ni d'à-coup
	chargement = CanvasLayer.new()
	chargement.set_script(load("res://scripts/chargement.gd"))
	add_child(chargement)
	await get_tree().process_frame
	await get_tree().process_frame
	_construire()
	if not "--sans-qualite-auto" in OS.get_cmdline_user_args() and not _enregistrement():
		var q := Node.new()
		q.set_script(load("res://scripts/qualite.gd"))
		q.name = "Qualite"
		add_child(q)
	await chargement.prechauffer(self)
	# grille de déplacement des aventuriers IA : calculée sous l'écran de chargement, pas en jouant
	var sd := get_node_or_null("ScenarioDonjon")
	if sd and sd.has_method("preparer"):
		await sd.preparer()
	chargement.disparaitre()
	if "--test-progression" in OS.get_cmdline_user_args():
		_test_progression()
	if "--test-objets" in OS.get_cmdline_user_args():
		_test_objets()

## Pendant un enregistrement vidéo ou une capture, on ne touche pas à la qualité (rendu lent mais voulu).
func _enregistrement() -> bool:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--capture") or a.begins_with("--tour") or a.begins_with("--plan") or a.begins_with("--demo") or a == "--survol":
			return true
	return OS.has_feature("movie")

func _construire() -> void:
	Heros.jcj_actif = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--carte="):
			carte = a.substr(8)
	if carte_suivante != "":
		carte = carte_suivante
	if carte == "donjon":
		carte = "crypte"
	Heros.en_epreuve = carte == "epreuve"
	if carte == "crypte":
		_environnement()
		monde = Caverne.new()
	elif carte == "epreuve":
		_environnement()
		monde = Epreuve.new()
	else:
		_environnement_surface()
		monde = CarteSurface.new()
	add_child(monde)

	var sons := Sons.new()
	sons.name = "Sons"
	add_child(sons)

	joueur = Heros.new()
	joueur.name = "Heros"
	joueur.position = Vector3(14, 0.1, 22) if carte == "crypte" else CarteSurface.SANCTUAIRE + Vector3(0, 0.1, 0)
	joueur.rotation.y = PI
	if carte == "epreuve":
		joueur.position = Epreuve.DEPART
	elif carte == "surface" and Epreuve.sac_garde != null:
		joueur.sac = Epreuve.sac_garde
		joueur.sac_neuf = false
		Epreuve.sac_garde = null
		if not Epreuve.oeuf_garde.is_empty():
			joueur.sac.ajouter(Epreuve.oeuf_garde)
			Epreuve.oeuf_garde = {}
	elif sac_suivant != null:
		joueur.sac = sac_suivant
		joueur.sac_neuf = false
	sac_suivant = null
	add_child(joueur)

	# lumière portée par le héros : chaude, douce
	var lj := OmniLight3D.new()
	lj.light_color = Color(1.0, 0.78, 0.55)
	lj.light_energy = 1.3 if carte == "crypte" else 0.5
	lj.omni_range = 11.0 if carte == "crypte" else 9.0
	lj.position = Vector3(0, 3.2, 0.6)
	joueur.add_child(lj)

	camera = Camera3D.new()
	camera.set_script(load("res://scripts/camera_jeu.gd"))
	camera.cible = joueur
	add_child(camera)
	camera.current = true

	var args := OS.get_cmdline_user_args()
	if "--inventaire" in args:
		var h2 := CanvasLayer.new()
		h2.set_script(load("res://scripts/interface/inventaire.gd"))
		add_child(h2)
	elif "--hud-statique" in args:
		var h := CanvasLayer.new()
		h.set_script(load("res://scripts/interface/hud.gd"))
		add_child(h)
	else:
		hud = CanvasLayer.new()
		hud.set_script(load("res://scripts/interface/hud_combat.gd"))
		add_child(hud)
		hud.brancher(joueur)
		hud.construire_roue()
	var couche_joy := CanvasLayer.new()
	add_child(couche_joy)
	joy = Control.new()
	joy.set_script(load("res://scripts/joystick.gd"))
	couche_joy.add_child(joy)
	joy.vecteur_change.connect(func(v): joueur.entree = v)

	if "--depart=arche" in args:
		joueur.position = Vector3(14, 0.1, 4.0)
	if not "--sans-monstres" in args and not "--depart=arche" in args and carte == "crypte":
		_meutes()
	if carte == "crypte" and not "--demo=combat" in args:
		var sd := Node.new()
		sd.set_script(load("res://scripts/donjon/scenario_donjon.gd"))
		sd.name = "ScenarioDonjon"
		add_child(sd)
		sd.demarrer(self, joueur, hud)
	if carte == "surface":
		var sc := Node.new()
		sc.set_script(load("res://scripts/surface/scenario.gd"))
		sc.name = "Scenario"
		add_child(sc)
		sc.demarrer(self, joueur, hud, "--sans-intro" in args or sans_intro_suivante)
	if carte == "epreuve":
		monde.demarrer(self, joueur, hud)
	if hud:
		var suivi := Node.new()
		suivi.set_script(load("res://scripts/progression/suivi.gd"))
		suivi.name = "Suivi"
		add_child(suivi)
		suivi.lancer(joueur, carte)
	joueur.mort.connect(func(_e): _apres_la_mort())
	_fondu_entree()

	for a in args:
		if a == "--demo=combat":
			var demo := Node.new()
			demo.set_script(load("res://scripts/demo_combat.gd"))
			add_child(demo)
			demo.lancer(joueur, camera)
		elif a == "--survol":
			var sv := Node.new()
			sv.set_script(load("res://scripts/survol.gd"))
			add_child(sv)
			sv.lancer.call_deferred(camera, hud)
		elif a == "--demo=donjon":
			var demo3 := Node.new()
			demo3.set_script(load("res://scripts/demo_donjon.gd"))
			add_child(demo3)
			demo3.lancer(joueur, self)
		elif a == "--demo=surface":
			var demo2 := Node.new()
			demo2.set_script(load("res://scripts/demo_surface.gd"))
			add_child(demo2)
			demo2.lancer(joueur, camera, self)
	_capture_si_demandee()

## Freya ramène le héros au sanctuaire (le corps et l'équipement restent en bas : à venir).
## L'œuf runique est brisé : on part seul dans l'épreuve ; le sac attend dehors.
func lancer_epreuve(oeuf: Dictionary) -> void:
	joueur.sac.retirer(oeuf)
	Epreuve.oeuf_garde = oeuf
	Epreuve.sac_garde = joueur.sac
	sac_suivant = null
	changer_carte("epreuve", true, false)

func _apres_la_mort() -> void:
	await get_tree().create_timer(4.5).timeout
	changer_carte("surface", true)

func changer_carte(nom: String, sans_intro := true, garder_sac := true) -> void:
	if garder_sac and joueur and is_instance_valid(joueur) and not joueur.est_mort:
		sac_suivant = joueur.sac
	carte_suivante = nom
	sans_intro_suivante = sans_intro
	var voile := _voile()
	var tw := create_tween()
	tw.tween_property(voile, "color:a", 1.0, 0.6)
	await tw.finished
	get_tree().reload_current_scene()

func _voile() -> ColorRect:
	var c := CanvasLayer.new()
	c.layer = 10
	add_child(c)
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.color = Color(0.82, 0.93, 1.0, 0.0) if carte == "surface" else Color(0.02, 0.02, 0.04, 0.0)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(r)
	return r

func _fondu_entree() -> void:
	if carte_suivante == "":
		return
	var v := _voile()
	v.color.a = 1.0
	create_tween().tween_property(v, "color:a", 0.0, 0.9)

func _physics_process(_d: float) -> void:
	if joueur == null:
		return
	# entrer dans le Portail = descendre dans le donjon du jour
	if carte == "surface" and joueur and not joueur.est_mort and carte_suivante != "crypte_en_cours":
		if joueur.global_position.distance_to(CarteSurface.PORTAIL + Vector3(0, 0, 1.6)) < 2.6:
			carte_suivante = "crypte_en_cours"
			Jeu.evenement("portail")
			Sons.jouer("activation", joueur.global_position, 0.0, 0.7)
			changer_carte("crypte")

func _meutes() -> void:
	for m in MEUTES:
		var d := Draugr.new()
		d.configurer(m[0])
		d.position = m[1]
		add_child(d)
		d.regarder(d.direction_vers(joueur.position))

func _unhandled_input(event: InputEvent) -> void:
	if joueur == null:
		return
	if event is InputEventKey and event.pressed and not event.echo and TOUCHES.has(event.keycode):
		joueur.lancer(TOUCHES[event.keycode])

func _environnement() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.035, 0.055)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.36, 0.6)
	env.ambient_light_energy = 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.08
	env.fog_enabled = true
	env.fog_light_color = Color(0.012, 0.016, 0.03)
	env.fog_density = 0.012
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	# sous terre : une lueur froide très faible pour détacher les volumes, sans ombres
	# (une ombre directionnelle redessine toute la caverne une seconde fois à chaque image)
	var lune := DirectionalLight3D.new()
	lune.light_color = Color(0.55, 0.65, 1.0)
	lune.light_energy = 0.18
	lune.rotation_degrees = Vector3(-60, -30, 0)
	lune.shadow_enabled = false
	add_child(lune)

## Fin d'après-midi dans le Val : soleil doré rasant, ombres longues, ciel froid dans les ombres.
func _environnement_surface() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.09, 0.13, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.62, 0.8)
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.92
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.05
	env.fog_enabled = true
	env.fog_light_color = Color(0.62, 0.66, 0.72)
	env.fog_density = 0.0045
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.92
	env.adjustment_contrast = 1.08
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var soleil := DirectionalLight3D.new()
	soleil.light_color = Color(1.0, 0.84, 0.62)
	soleil.light_energy = 0.85
	soleil.rotation_degrees = Vector3(-38, -58, 0)
	soleil.shadow_enabled = not "--sans-ombres" in OS.get_cmdline_user_args()
	soleil.add_to_group("soleil")
	soleil.directional_shadow_max_distance = 42.0
	soleil.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	soleil.shadow_blur = 1.5
	add_child(soleil)

func _capture_si_demandee() -> void:
	var chemin := ""
	var images := 90
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--capture="):
			chemin = a.substr(10)
		elif a.begins_with("--frames="):
			images = int(a.substr(9))
		elif a.begins_with("--pos="):
			var p := a.substr(6).split(",")
			joueur.position = Vector3(float(p[0]), 0.1, float(p[1]))
		elif a.begins_with("--plan="):
			# vue d'ensemble orthographique, nord en haut
			var c2 := Camera3D.new()
			c2.projection = Camera3D.PROJECTION_ORTHOGONAL
			c2.size = 112.0 if carte == "surface" else 200.0
			c2.position = Vector3(86, 120, 55) if carte == "surface" else Vector3(-18, 160, -66)
			c2.rotation_degrees.x = -90
			add_child(c2)
			c2.current = true
			for k in 40:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(a.substr(7))
			get_tree().quit()
			return
		elif a.begins_with("--tour="):
			# visite photo : plusieurs positions, une capture chacune
			var lieux := a.substr(7).split(";")
			joueur.invulnerable_t = 99999.0   # visite photo : le héros ne doit pas mourir entre deux clichés
			for i in lieux.size():
				var c := lieux[i].split(",")
				joueur.global_position = Vector3(float(c[0]), 0.1, float(c[1]))
				var sort := ""
				if c.size() > 2:
					if c[2].is_valid_float():
						joueur.rotation.y = deg_to_rad(float(c[2]))
					else:
						sort = c[2]
				camera.set("_focus", joueur.global_position)
				for k in 45:
					await get_tree().process_frame
				if sort != "":
					joueur.cds[sort] = 0.0
					joueur.lancer(sort, Vector3(0, 0, -1))
					for k in 7:
						await get_tree().process_frame
				get_viewport().get_texture().get_image().save_png("/tmp/claude-0/scr/tour_%d.png" % i)
				if "--mesure" in OS.get_cmdline_user_args():
					printerr("MESURE ", lieux[i], " appels=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
						" objets=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
						" triangles=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
						" noeuds=", get_tree().get_node_count(), " ms_process=", snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.1),
						" ms_physique=", snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.1))
			get_tree().quit()
			return
		elif a.begins_with("--marche="):
			var m := a.substr(9).split(",")
			joueur.entree = Vector2(float(m[0]), float(m[1]))
	if chemin == "":
		return
	for i in images:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(chemin)
	print("capture : ", chemin)
	get_tree().quit()

func _test_objets() -> void:
	var h := joueur
	h.invulnerable_t = 9999.0
	await get_tree().create_timer(1.0).timeout
	# coffre de la crypte
	var c: Coffre = null
	for o in get_tree().get_nodes_in_group("interactif"):
		if o is Coffre and o.global_position.distance_to(Vector3(14, 0, 5.2)) < 1.0:
			c = o
	h.global_position = Vector3(14, 0.1, 7.5)
	c.interagir(h)
	await get_tree().create_timer(0.8).timeout
	await _cap("canal")
	await get_tree().create_timer(1.2).timeout
	await _cap("butin")
	printerr("TEST coffre ouvert=", c.ouvert, " fenetre=", get_tree().get_nodes_in_group("x").size(), " or=", h.sac.or_, " objets=", h.sac.objets.size())
	# prendre tout via la fenêtre
	for n in hud.get_children():
		if n.has_method("montrer"):
			n._prendre(n.contenu["objets"].duplicate(), "t", Color.WHITE, true)
	printerr("TEST apres prise or=", h.sac.or_, " objets=", h.sac.objets.map(func(o): return o["nom"] + "x" + str(o["qte"])))
	# filon
	var f: Filon = null
	for o in get_tree().get_nodes_in_group("interactif"):
		if o is Filon and o.type == "cuivre":
			f = o
			break
	h.global_position = f.global_position + Vector3(1.8, 0.1, 0)
	f.interagir(h)
	await get_tree().create_timer(2.8).timeout
	printerr("TEST minage cuivre=", h.sac.compter("minerai_cuivre"), " mineur=", h.metier_mine)
	# œuf et éclosion
	var stats := {}
	for i in 2000:
		var d := Objets.eclore(Objets.creer("oeuf", "rare"))
		stats[d["rarete"]] = stats.get(d["rarete"], 0) + 1
	printerr("TEST 2000 oeufs rares -> ", stats)
	var oeuf := Objets.creer("oeuf", "epique")
	h.sac.ajouter(oeuf)
	h.sac.ajouter(Objets.creer("oeuf", "legendaire"))
	h.sac.ajouter(Objets.creer("espadon", "epique"))
	hud.sac_ui.ouvrir_sac()
	hud.sac_ui._choix = h.sac.objets[h.sac.objets.size() - 1]
	hud.sac_ui._rafraichir()
	await _cap("sac")
	hud.sac_ui._eclore(oeuf)
	await get_tree().create_timer(1.5).timeout
	await _cap("eclosion1")
	await get_tree().create_timer(2.5).timeout
	await _cap("eclosion2")
	var dr: Dictionary = {}
	for o in h.sac.objets:
		if o["type"] == "dragon":
			dr = o
	h.equiper_dragon(dr)
	printerr("TEST dragon=", dr["nom"], " puissance=", dr["puissance"], " acolyte=", is_instance_valid(h.acolyte_noeud))
	for n in hud.sac_ui.get_children():
		if n.has_method("lancer"):
			n.queue_free()
	hud.sac_ui.fermer_sac()
	await get_tree().create_timer(1.5).timeout
	await _cap("acolyte")
	get_tree().quit()

func _test_progression() -> void:
	var pr := Profil.p()
	await get_tree().create_timer(1.0).timeout
	for k in ["tues", "tues", "coffres"]:
		pr.compter(k, 10)
	pr.compter("metres", 600)
	pr.points_gagnes += 12
	for id in ["morsure", "morsure", "morsure", "croc", "croc", "ecorce", "ecorce", "memoire", "vent", "hurlement", "repos"]:
		pr.investir(id)
	await get_tree().create_timer(3.5).timeout
	hud.talents_ui.ouvrir()
	hud.talents_ui._choix = "hurlement"
	hud.talents_ui._rafraichir()
	await get_tree().create_timer(1.2).timeout
	await _cap("arbre")
	hud.talents_ui.fermer()
	hud.codex_ui.ouvrir()
	await get_tree().create_timer(0.5).timeout
	await _cap("codex")
	hud.codex_ui._cat = "Secrets"
	hud.codex_ui._rafraichir()
	await get_tree().create_timer(0.5).timeout
	await _cap("codex_secrets")
	hud.codex_ui.fermer()
	var rel: Array = []
	for r in ["commun", "rare", "epique", "legendaire", "mythique"]:
		var o := Objets.creer("relique", r)
		joueur.sac.ajouter(o)
		rel.append(o)
	for o in rel.slice(0, 4):
		joueur.sac.porter_relique(o)
	printerr("TEST pv_max=", joueur.pv_max, " sorts=", joueur.stat("sorts"), " recharge=", joueur.stat("recharge"), " endurance=", joueur.stat("endurance"))
	hud.sac_ui.ouvrir_sac()
	hud.sac_ui._choix = rel[4]
	hud.sac_ui._rafraichir()
	await get_tree().create_timer(0.5).timeout
	await _cap("sac_reliques")
	hud.sac_ui.fermer_sac()
	hud.celebrer_relique(rel[3])
	await get_tree().create_timer(0.9).timeout
	await _cap("relique")
	hud.annoncer_realisation(Codex.LISTE[0])
	await get_tree().create_timer(0.6).timeout
	await _cap("realisation")
	get_tree().quit()

func _cap(nom: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/scr/ui_%s.png" % nom)
