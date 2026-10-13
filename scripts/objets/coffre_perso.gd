class_name CoffrePerso
extends Node3D
## Le coffre personnel du Bourg : ce qu'on y range survit à toutes les morts.

var rayon := 3.0

static func creer(parent: Node, pos: Vector3, rot := 0.0) -> CoffrePerso:
	var c := CoffrePerso.new()
	c.position = pos
	c.rotation_degrees.y = rot
	parent.add_child(c)
	return c

func _ready() -> void:
	add_to_group("interactif")
	var m: Node3D = load("res://assets/donjon/chest_gold.glb").instantiate()
	m.scale = Vector3.ONE * 1.2
	add_child(m)
	var corps := StaticBody3D.new()
	var f := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(1.8, 1.2, 1.4)
	f.shape = b
	f.position.y = 0.6
	corps.add_child(f)
	add_child(corps)
	var lab := Label3D.new()
	lab.text = "Ton coffre"
	lab.font_size = 40
	lab.outline_size = 10
	lab.modulate = Color("#FFE2A0")
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.position.y = 2.2
	lab.pixel_size = 0.01
	add_child(lab)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.8, 0.45)
	l.light_energy = 0.8
	l.omni_range = 4.0
	l.position.y = 1.5
	add_child(l)

func texte_action() -> String:
	return "Ouvrir"

func disponible() -> bool:
	return true

func interagir(h: Heros) -> void:
	if h != Jeu.joueur:
		return
	var ui := CanvasLayer.new()
	ui.set_script(load("res://scripts/interface/comptoir_ui.gd"))
	get_tree().current_scene.add_child(ui)
	ui.ouvrir(h, "coffre")
