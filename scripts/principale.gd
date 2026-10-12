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
var monde: Node3D

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--carte="):
			carte = a.substr(8)
	if carte_suivante != "":
		carte = carte_suivante
	if carte == "crypte":
		_environnement()
		monde = Node3D.new()
		monde.set_script(load("res://scripts/salle_entree.gd"))
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
	add_child(joueur)

	# lumière portée par le héros : chaude, douce
	var lj := OmniLight3D.new()
	lj.light_color = Color(1.0, 0.78, 0.55)
	lj.light_energy = 1.1 if carte == "crypte" else 0.5
	lj.omni_range = 9.0
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

	if not "--sans-monstres" in args and carte == "crypte":
		_meutes()
	if carte == "surface":
		var sc := Node.new()
		sc.set_script(load("res://scripts/surface/scenario.gd"))
		sc.name = "Scenario"
		add_child(sc)
		sc.demarrer(self, joueur, hud, "--sans-intro" in args or sans_intro_suivante)
	joueur.mort.connect(func(_e): _apres_la_mort())
	_fondu_entree()

	for a in args:
		if a == "--demo=combat":
			var demo := Node.new()
			demo.set_script(load("res://scripts/demo_combat.gd"))
			add_child(demo)
			demo.lancer(joueur, camera)
		elif a == "--demo=surface":
			var demo2 := Node.new()
			demo2.set_script(load("res://scripts/demo_surface.gd"))
			add_child(demo2)
			demo2.lancer(joueur, camera, self)
	_capture_si_demandee()

## Freya ramène le héros au sanctuaire (le corps et l'équipement restent en bas : à venir).
func _apres_la_mort() -> void:
	await get_tree().create_timer(4.5).timeout
	changer_carte("surface", true)

func changer_carte(nom: String, sans_intro := true) -> void:
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
	# entrer dans le Portail = descendre dans le donjon du jour
	if carte == "surface" and joueur and not joueur.est_mort and carte_suivante != "crypte_en_cours":
		if joueur.global_position.distance_to(CarteSurface.PORTAIL + Vector3(0, 0, 1.6)) < 2.6:
			carte_suivante = "crypte_en_cours"
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
	if event is InputEventKey and event.pressed and not event.echo and TOUCHES.has(event.keycode):
		joueur.lancer(TOUCHES[event.keycode])

func _environnement() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.035, 0.055)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.38, 0.6)
	env.ambient_light_energy = 0.28
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.08
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.06, 0.1)
	env.fog_density = 0.02
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	# clair de lune froid, très faible, pour détacher les volumes
	var lune := DirectionalLight3D.new()
	lune.light_color = Color(0.55, 0.65, 1.0)
	lune.light_energy = 0.22
	lune.rotation_degrees = Vector3(-60, -30, 0)
	lune.shadow_enabled = true
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
	soleil.shadow_enabled = true
	soleil.directional_shadow_max_distance = 70.0
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
			c2.size = 112.0
			c2.position = Vector3(86, 120, 55)
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
