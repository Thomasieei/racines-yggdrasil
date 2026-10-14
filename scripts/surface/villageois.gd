class_name Villageois
extends Node3D
## Un habitant du hameau : il a une maison, un métier, une famille, et sa journée
## (travail, repas à la taverne, veillée autour du feu, sommeil). On peut aussi en prendre
## le contrôle (pouvoir « Contrôle d'esprit ») : il marche alors au doigt du joueur.

var nom := ""
var metier := ""
var famille := ""
var maison: Vector3          ## devant sa porte
var travail: Vector3         ## son poste
var modele_chemin := "res://assets/personnages/marchand.glb"
var teinte := Color.WHITE
var enfant := false
var vitesse := 1.7
var controle := false        ## piloté par le joueur
var arrete := false          ## pris la main dans le sac : il file au cachot pour un moment
var entree := Vector2.ZERO   ## joystick quand contrôlé

var modele: Node3D
var anim: AnimationPlayer
var _but := Vector3.ZERO
var _activite := ""
var _t := 0.0
var _anim_courante := ""
var _etiquette: Label3D
var _aura: Node3D
var cache := false           ## dans sa maison (la nuit)
var _etapes: Array = []

const CACHES := ["Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Knife", "Throwable", "Spellbook", "Spellbook_open", "1H_Wand", "2H_Staff",
	"1H_Axe_Offhand", "Barbarian_Round_Shield", "Mug", "1H_Axe", "2H_Axe", "1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Round_Shield", "Spike_Shield", "1H_Sword", "2H_Sword"]

func _ready() -> void:
	add_to_group("villageois")
	modele = load(modele_chemin).instantiate()
	add_child(modele)
	if enfant:
		modele.scale = Vector3.ONE * 0.68
		vitesse = 2.1
	for n in CACHES:
		var m := modele.find_child(n, true, false)
		if m:
			m.visible = false
	# vêtements teintés : personne ne se ressemble
	for m in modele.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if not (mi.name.contains("Cape") or mi.name.contains("Hat") or mi.name.contains("Body") or mi.name.contains("Hood")):
			continue
		for k in mi.mesh.get_surface_count():
			var src = mi.get_active_material(k)
			if src is StandardMaterial3D:
				var c: StandardMaterial3D = src.duplicate()
				c.albedo_color = teinte if not mi.name.contains("Body") else teinte.lerp(Color.WHITE, 0.55)
				mi.set_surface_override_material(k, c)
	anim = modele.find_child("AnimationPlayer", true, false)
	if anim:
		for a in ["Idle", "Walking_A", "Running_A", "Interact"]:
			if anim.has_animation(a):
				anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
	_etiquette = Label3D.new()
	_etiquette.text = nom + "\n" + metier
	_etiquette.font_size = 34
	_etiquette.outline_size = 8
	_etiquette.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_etiquette.pixel_size = 0.009
	_etiquette.position.y = 2.5 if not enfant else 1.8
	_etiquette.modulate = Color("#F2E6C8")
	add_child(_etiquette)
	_but = global_position

func jouer(n: String, vit := 1.0) -> void:
	if anim and anim.has_animation(n) and _anim_courante != n:
		_anim_courante = n
		anim.play(n, 0.2, vit)

## Le village lui dit quoi faire selon l'heure.
func activite(a: String, ou: Vector3) -> void:
	if controle or arrete:
		return
	_activite = a
	var but := ou + Vector3(randf_range(-1.6, 1.6), 0, randf_range(-1.6, 1.6))
	# on passe par la place quand c'est loin : les maisons ne se traversent pas
	var place := CarteSurface.PLACE_VILLAGE + Vector3(randf_range(-3, 3), 0, randf_range(3, 8))
	if global_position.distance_to(but) > 9.0 and global_position.distance_to(place) > 4.0:
		_etapes = [place, but]
	else:
		_etapes = [but]
	_but = _etapes[0]

func _process(delta: float) -> void:
	_t += delta
	# l'étiquette n'apparaît que de près
	var j = Jeu.joueur
	if j and is_instance_valid(j):
		var cam_p: Vector3 = Pouvoirs.moi.controle.global_position if Pouvoirs.moi and Pouvoirs.moi.controle else j.global_position
		var d := global_position.distance_to(cam_p)
		_etiquette.modulate.a = clampf((11.0 - d) / 4.0, 0.0, 1.0) if not controle else 1.0
	if controle:
		var v := Vector3(entree.x, 0, entree.y)
		if v.length() > 0.15:
			v = v.limit_length(1.0)
			global_position += v * 4.2 * delta
			rotation.y = lerp_angle(rotation.y, atan2(v.x, v.z), 1.0 - exp(-10.0 * delta))
			jouer("Running_A", 1.0)
		elif _anim_courante != "Interact":
			jouer("Idle")
		return
	var vv := _but - global_position
	vv.y = 0
	if vv.length() <= 0.4 and _etapes.size() > 1:
		_etapes.pop_front()
		_but = _etapes[0]
		vv = _but - global_position
		vv.y = 0
	if vv.length() > 0.4:
		var pas := vv.normalized() * vitesse * (1.6 if arrete else 1.0) * delta
		global_position += pas
		rotation.y = lerp_angle(rotation.y, atan2(vv.x, vv.z), 1.0 - exp(-8.0 * delta))
		jouer("Running_A" if arrete else "Walking_A", 1.0)
		if cache:
			_sortir()
	else:
		match _activite:
			"travail":
				jouer("Interact" if fmod(_t, 6.0) < 4.0 else "Idle")
			"maison":
				if not cache:
					_rentrer()
			_:
				jouer("Idle")

func _rentrer() -> void:
	cache = true
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 0.01, 0.4)
	tw.tween_callback(func(): visible = false)

func _sortir() -> void:
	cache = false
	visible = true
	scale = Vector3.ONE

# ---------------- contrôle d'esprit ----------------

func prendre_controle() -> void:
	controle = true
	_sortir()
	if _aura == null:
		_aura = Node3D.new()
		add_child(_aura)
		var p := CPUParticles3D.new()
		p.amount = 18
		p.lifetime = 1.4
		var q := QuadMesh.new()
		q.size = Vector2(0.16, 0.16)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.albedo_color = Color(0.75, 0.45, 1.0, 0.8)
		m.disable_fog = true
		q.material = m
		p.mesh = q
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.5
		p.direction = Vector3.UP
		p.gravity = Vector3(0, 0.6, 0)
		p.initial_velocity_min = 0.3
		p.initial_velocity_max = 0.8
		p.position.y = 1.2
		_aura.add_child(p)
		var l := OmniLight3D.new()
		l.light_color = Color(0.7, 0.45, 1.0)
		l.light_energy = 1.0
		l.omni_range = 3.5
		l.position.y = 1.6
		_aura.add_child(l)
	_aura.visible = true
	_etiquette.modulate = Color("#D9B8FF")

func liberer() -> void:
	controle = false
	entree = Vector2.ZERO
	if _aura:
		_aura.visible = false
	_etiquette.modulate = Color("#F2E6C8")
	jouer("Idle")
	# il se demande ce qu'il fait là, puis reprend sa journée
	_activite = "perdu"
	_but = global_position

func arreter_voleur(cachot: Vector3) -> void:
	arrete = true
	_activite = "cachot"
	_etapes = [cachot]
	_but = cachot
	_etiquette.text = nom + "\n(arrêté)"
	get_tree().create_timer(120.0).timeout.connect(func():
		if is_instance_valid(self):
			arrete = false
			_etiquette.text = nom + "\n" + metier)
