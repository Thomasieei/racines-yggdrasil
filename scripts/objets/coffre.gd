class_name Coffre
extends Node3D
## Coffre à ouvrir. Sa couleur dit sa rareté avant même d'approcher (lueur au sol, rayon de lumière),
## une étiquette annonce la valeur estimée. L'ouverture prend 1,4 s : on peut se faire interrompre.

const DJ := "res://assets/donjon/"

var rarete := "commun"
var ouvert := false
var contenu: Dictionary = {}
var rayon := 2.8
var _couvercle: Node3D
var _lueur: OmniLight3D
var _etiquette: Label3D
var _anneau: MeshInstance3D

static func creer(parent: Node, pos: Vector3, rar: String, rot_deg := 0.0) -> Coffre:
	var c := Coffre.new()
	c.rarete = rar
	c.position = pos
	c.rotation_degrees.y = rot_deg
	parent.add_child(c)
	return c

func _ready() -> void:
	add_to_group("interactif")
	contenu = Objets.contenu_coffre(rarete)
	var gros := Objets.RARETES.find(rarete) >= 2
	var m: Node3D = load(DJ + ("chest_gold.glb" if gros else "chest.glb")).instantiate()
	m.scale = Vector3.ONE * (1.25 if gros else 1.1)
	add_child(m)
	_couvercle = m.find_child("*lid", true, false)
	var col: Color = Objets.COULEURS[rarete]
	# lueur de rareté : lumière, anneau au sol, rayon vertical — lisible de loin dans le noir
	_lueur = OmniLight3D.new()
	_lueur.light_color = col
	_lueur.light_energy = 1.4 + Objets.RARETES.find(rarete) * 0.35
	_lueur.omni_range = 5.0 + Objets.RARETES.find(rarete)
	_lueur.position = Vector3(0, 1.4, 0.6)
	add_child(_lueur)
	_anneau = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(3.4, 3.4)
	_anneau.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/anneau_sol.gdshader")
	mat.set_shader_parameter("couleur", col)
	mat.set_shader_parameter("rayon", 0.9)
	mat.set_shader_parameter("alpha", 0.55)
	_anneau.material_override = mat
	_anneau.position.y = 0.05
	add_child(_anneau)
	var corps := StaticBody3D.new()
	var f := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(1.6, 1.2, 1.2)
	f.shape = b
	f.position.y = 0.6
	corps.add_child(f)
	add_child(corps)
	_etiquette = Label3D.new()
	_etiquette.text = "Coffre %s · ~%d or" % [Objets.NOMS_RARETE[rarete].to_lower(), estimation()]
	_etiquette.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_etiquette.fixed_size = true
	_etiquette.pixel_size = 0.0007
	_etiquette.font_size = 44
	_etiquette.outline_size = 12
	_etiquette.modulate = col.lightened(0.25)
	_etiquette.outline_modulate = Color(0, 0, 0, 0.9)
	_etiquette.no_depth_test = true
	_etiquette.position.y = 2.0
	add_child(_etiquette)

func estimation() -> int:
	var v: int = contenu["or"]
	for o in contenu["objets"]:
		v += o["valeur"] * o["qte"]
	return int(round(v / 10.0)) * 10

func _process(_d: float) -> void:
	if ouvert:
		return
	_lueur.light_energy = (1.4 + Objets.RARETES.find(rarete) * 0.35) * (0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.004))
	# l'étiquette n'apparaît que de près : la caverne reste lisible
	var h := Jeu.joueur
	if h:
		var d := global_position.distance_to(h.global_position)
		_etiquette.modulate.a = clampf((16.0 - d) / 5.0, 0.0, 1.0)
		_etiquette.outline_modulate.a = _etiquette.modulate.a * 0.9

func texte_action() -> String:
	return "Ouvrir"

func disponible() -> bool:
	return not ouvert

func interagir(h: Heros) -> void:
	h.canaliser("Ouverture du coffre", 1.4, "Interact")
	var res: Array = await h.canal_fini
	if not res[1] or ouvert:
		return
	ouvrir(h)
	if h == Jeu.joueur:
		Jeu.evenement("coffre", {"rarete": rarete})
		Jeu.ouvrir_butin("Coffre " + Objets.NOMS_RARETE[rarete].to_lower(), contenu, h, Objets.COULEURS[rarete])
	else:
		h.ramasser(contenu)

## Appelé quand la canalisation réussit.
func ouvrir(h: Heros) -> Dictionary:
	ouvert = true
	remove_from_group("interactif")
	_etiquette.visible = false
	if _couvercle:
		create_tween().tween_property(_couvercle, "rotation:x", -1.9, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	var col: Color = Objets.COULEURS[rarete]
	Effets.etincelles(get_parent(), global_position + Vector3(0, 1.0, 0), Vector3.UP, col, 30, 6.0, "star_06.png", 0.4)
	Effets.flash_lumiere(get_parent(), global_position, col, 5.0, 10.0, 0.6)
	Effets.onde(get_parent(), global_position, 3.0, col)
	Sons.jouer("pret", global_position, 0.0, 0.9)
	var tw := create_tween()
	tw.tween_property(_lueur, "light_energy", 0.3, 1.5)
	_anneau.visible = false
	return contenu
