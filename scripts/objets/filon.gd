class_name Filon
extends Node3D
## Filon de minerai : un rocher veiné de pépites qui brillent. Miner prend 2,2 s, rapporte du minerai
## et de l'expérience de Mineur. Trois coups de pioche puis le filon s'épuise et repousse plus tard.
## Les filons rares demandent un niveau de Mineur ; on y trouve parfois une gemme… ou un œuf de dragon.

const R := "res://assets/surface/ressources/"
const F := "res://assets/surface/foret/"

const TYPES := {
	"cuivre": {"nom": "Filon de cuivre", "pepites": "Copper_Nugget_Large", "minerai": "minerai_cuivre", "niveau": 1, "xp": 12, "couleur": Color(1.0, 0.55, 0.3)},
	"fer": {"nom": "Filon de fer", "pepites": "Iron_Nugget_Large", "minerai": "minerai_fer", "niveau": 3, "xp": 20, "couleur": Color(0.75, 0.82, 0.95)},
	"argent": {"nom": "Filon d'argent", "pepites": "Silver_Nugget_Large", "minerai": "minerai_argent", "niveau": 6, "xp": 34, "couleur": Color(0.85, 0.92, 1.0)},
	"or": {"nom": "Filon d'or", "pepites": "Gold_Nugget_Large", "minerai": "minerai_or", "niveau": 10, "xp": 55, "couleur": Color(1.0, 0.82, 0.3)},
}

var type := "cuivre"
var charges := 3
var rayon := 2.8
var _repousse := 0.0
var _pepites: Array[Node3D] = []
var _lueur: OmniLight3D

static func creer(parent: Node, pos: Vector3, t: String) -> Filon:
	var f := Filon.new()
	f.type = t
	f.position = pos
	f.rotation_degrees.y = randf() * 360.0
	parent.add_child(f)
	return f

func _ready() -> void:
	add_to_group("interactif")
	var d: Dictionary = TYPES[type]
	var roc: Node3D = load(F + "Rock_1_G_Color1.gltf").instantiate()
	roc.scale = Vector3(1.2, 0.9, 1.2)
	add_child(roc)
	for m in roc.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var mat := mi.get_active_material(0)
		if mat is StandardMaterial3D:
			var m2: StandardMaterial3D = mat.duplicate()
			m2.albedo_color = Color(0.36, 0.34, 0.36)
			mi.set_surface_override_material(0, m2)
	for i in 4:
		var p: Node3D = load(R + d["pepites"] + ".gltf").instantiate()
		var a := TAU * i / 4.0 + randf() * 0.6
		p.position = Vector3(cos(a) * 0.75, 0.35 + randf() * 0.9, sin(a) * 0.75)
		p.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		p.scale = Vector3.ONE * 1.6
		add_child(p)
		_pepites.append(p)
	_lueur = OmniLight3D.new()
	_lueur.light_color = d["couleur"]
	_lueur.light_energy = 0.9
	_lueur.omni_range = 4.5
	_lueur.position = Vector3(0, 1.2, 0)
	add_child(_lueur)
	var corps := StaticBody3D.new()
	var f := CollisionShape3D.new()
	var c := CylinderShape3D.new()
	c.radius = 1.0
	c.height = 2.0
	f.shape = c
	f.position.y = 1.0
	corps.add_child(f)
	add_child(corps)

func texte_action() -> String:
	return "Miner"

func disponible() -> bool:
	return charges > 0

func nom_affiche() -> String:
	return TYPES[type]["nom"]

func interagir(h: Heros) -> void:
	var d: Dictionary = TYPES[type]
	if h.metier_mine["niveau"] < d["niveau"]:
		if h == Jeu.joueur:
			Jeu.notifier("Mineur niveau %d requis" % d["niveau"], Color("#FFB37A"))
		return
	h.canaliser("Minage — " + d["nom"].to_lower(), 2.2, "2H_Melee_Attack_Chop")
	_coups(h)
	var res: Array = await h.canal_fini
	if not res[1] or charges <= 0:
		return
	charges -= 1
	var niv: int = h.metier_mine["niveau"]
	var qte := randi_range(2, 3) + niv / 4
	var gains: Array = [Objets.creer(d["minerai"], "commun", qte)]
	if randf() < 0.05 + niv * 0.005:
		gains.append(Objets.creer("lingot_or", "commun", 1))
	if randf() < 0.008:
		gains.append(Objets.creer("oeuf", Objets.tirer_rarete([0.55, 0.32, 0.1, 0.025, 0.005])))
	h.ramasser({"or": 0, "objets": gains}, d["nom"])
	h.gagner_xp_mine(d["xp"])
	if h == Jeu.joueur:
		Jeu.evenement("mine", {"minerai": d["minerai"], "qte": qte})
	Effets.etincelles(get_parent(), global_position + Vector3(0, 1.0, 0), Vector3.UP, d["couleur"], 16, 4.0, "spark_04.png", 0.3)
	if charges <= 0:
		_epuiser()

## Petits chocs de pioche pendant la canalisation (étincelles + son), tant qu'on n'est pas interrompu.
func _coups(h: Heros) -> void:
	for i in 3:
		await get_tree().create_timer(0.62).timeout
		if h.canal_en_cours() == "":
			return
		Sons.jouer("metal", global_position, -4.0, randf_range(0.9, 1.15))
		Effets.etincelles(get_parent(), global_position + Vector3(0, 0.9, 0), (h.global_position - global_position).normalized() + Vector3.UP, TYPES[type]["couleur"], 8, 4.0, "spark_04.png", 0.25)

func _epuiser() -> void:
	for p in _pepites:
		p.visible = false
	_lueur.visible = false
	_repousse = 150.0

func _process(delta: float) -> void:
	if charges > 0:
		return
	_repousse -= delta
	if _repousse <= 0.0:
		charges = 3
		for p in _pepites:
			p.visible = true
		_lueur.visible = true
