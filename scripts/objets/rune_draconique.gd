class_name RuneDraconique
extends Node3D
## Fragment de rune draconique posé dans le monde : une pierre sombre, une rune violette qui flotte
## et respire. Rien ne l'annonce de loin (pas d'icône sur la carte) : il faut tomber dessus.
## On la déchiffre (2,5 s) et le fragment rejoint le sac… où il peut être perdu à la mort.

const NOMS := {1: "Mémoire", 2: "Abîme", 3: "Forge"}

var numero := 1
var rayon := 3.2
var pris := false
var _rune: Sprite3D
var _lueur: OmniLight3D
var _t := 0.0

static func creer(parent: Node, pos: Vector3, n: int) -> RuneDraconique:
	var r := RuneDraconique.new()
	r.numero = n
	r.position = pos
	parent.add_child(r)
	return r

func _ready() -> void:
	add_to_group("interactif")
	var pierre := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = 0.35
	m.bottom_radius = 0.6
	m.height = 1.1
	m.radial_segments = 6
	pierre.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.14, 0.2)
	mat.roughness = 0.9
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.15, 0.6)
	mat.emission_energy_multiplier = 0.25
	pierre.material_override = mat
	pierre.position.y = 0.55
	add_child(pierre)
	_rune = Sprite3D.new()
	var img := Image.new()
	img.load_svg_from_string(FileAccess.get_file_as_string("res://assets/icones_sorts/fragment.svg"), 0.5)
	_rune.texture = ImageTexture.create_from_image(img)
	_rune.pixel_size = 0.006
	_rune.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_rune.shaded = false
	_rune.no_depth_test = false
	_rune.position.y = 1.7
	_rune.modulate = Color(1, 1, 1, 0.95)
	add_child(_rune)
	_lueur = OmniLight3D.new()
	_lueur.light_color = Color(0.7, 0.4, 1.0)
	_lueur.omni_range = 5.0
	_lueur.light_energy = 1.2
	_lueur.position.y = 1.6
	add_child(_lueur)
	var p := CPUParticles3D.new()
	p.amount = 14
	p.lifetime = 2.2
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	pm.albedo_color = Color(0.75, 0.5, 1.0, 0.8)
	pm.disable_fog = true
	q.material = pm
	p.mesh = q
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.8
	p.direction = Vector3.UP
	p.spread = 30.0
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.6
	p.gravity = Vector3(0, 0.15, 0)
	p.position.y = 0.8
	add_child(p)
	var c := StaticBody3D.new()
	var f := CollisionShape3D.new()
	var cy := CylinderShape3D.new()
	cy.radius = 0.55
	cy.height = 1.2
	f.shape = cy
	f.position.y = 0.6
	c.add_child(f)
	add_child(c)

func _process(delta: float) -> void:
	_t += delta
	_rune.position.y = 1.7 + sin(_t * 1.6) * 0.12
	_lueur.light_energy = 1.0 + 0.5 * sin(_t * 2.1)

func texte_action() -> String:
	return "Déchiffrer"

func disponible() -> bool:
	return not pris

func interagir(h: Heros) -> void:
	if h != Jeu.joueur:
		return
	h.canaliser("Déchiffrer la rune", 2.5, "Interact")
	var res: Array = await h.canal_fini
	if not res[1] or pris:
		return
	pris = true
	remove_from_group("interactif")
	var o := Objets.creer("fragment", "epique")
	o["numero"] = numero
	o["nom"] = "Fragment de rune · " + NOMS[numero]
	h.ramasser({"or": 0, "objets": [o]}, "une rune draconique")
	Profil.p().compter("runes")
	Effets.onde(get_parent(), global_position, 4.0, Color(0.7, 0.4, 1.0))
	Effets.etincelles(get_parent(), global_position + Vector3(0, 1.5, 0), Vector3.UP, Color(0.8, 0.55, 1.0), 30, 5.0, "star_06.png", 0.4)
	Sons.jouer("cloche", global_position, 0.0, 0.7)
	if Jeu.hud and Jeu.hud.has_method("celebrer"):
		Jeu.hud.celebrer(o, "RUNE DRACONIQUE", o["nom"], "Les dragons n'ont pas tout emporté…")
	var tw := create_tween()
	tw.tween_property(_lueur, "light_energy", 0.0, 1.2)
	tw.parallel().tween_property(_rune, "modulate:a", 0.0, 1.2)
	tw.tween_callback(queue_free)
