class_name Depouille
extends Node3D
## Ce qui reste au sol : la dépouille d'un aventurier (son sac entier, à fouiller) ou la bourse d'un
## monstre (ramassée en marchant dessus). Disparaît au bout d'un moment.

var butin: Dictionary = {}
var nom := ""
var corps := false             ## dépouille d'aventurier : il faut la fouiller (1 s)
var rayon := 2.6
var _vie := 180.0
var _etiquette: Label3D

static func creer(parent: Node, pos: Vector3, b: Dictionary, nom_mort := "") -> Depouille:
	var d := Depouille.new()
	d.butin = b
	d.nom = nom_mort
	d.corps = nom_mort != ""
	d.position = Vector3(pos.x, 0, pos.z)
	parent.add_child.call_deferred(d)
	return d

func _ready() -> void:
	var meilleure := -1
	var oeuf := false
	for o in butin["objets"]:
		meilleure = maxi(meilleure, Objets.RARETES.find(o["rarete"]))
		if o["type"] in ["oeuf", "dragon"]:
			oeuf = true
	var col: Color = Objets.COULEURS[Objets.RARETES[maxi(meilleure, 0)]] if meilleure >= 0 else Color("#F4C35A")
	if corps:
		add_to_group("interactif")
		_vie = 600.0
		var s: Node3D = load("res://assets/surface/hexa/decoration/props/sack.gltf").instantiate()
		s.scale = Vector3.ONE * 7.0
		add_child(s)
		var os_: Node3D = load("res://assets/halloween/skull.gltf").instantiate()
		os_.position = Vector3(0.7, 0, 0.3)
		add_child(os_)
		_etiquette = Label3D.new()
		_etiquette.text = "Dépouille de " + nom
		_etiquette.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_etiquette.fixed_size = true
		_etiquette.pixel_size = 0.0007
		_etiquette.font_size = 44
		_etiquette.outline_size = 12
		_etiquette.modulate = Color("#FFD9B0")
		_etiquette.no_depth_test = true
		_etiquette.position.y = 1.6
		add_child(_etiquette)
	elif oeuf:
		# un œuf se voit : il trône sur le sol, éclairé de sa couleur
		for o in butin["objets"]:
			if o["type"] == "oeuf":
				var e := DragonVisuel.oeuf(o["rarete"])
				add_child(e)
				break
	else:
		var p: Node3D = load("res://assets/donjon/coin_stack_small.glb").instantiate()
		p.scale = Vector3.ONE * 1.3
		add_child(p)
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = 1.2 if meilleure >= 1 or oeuf else 0.6
	l.omni_range = 3.5
	l.position.y = 0.8
	add_child(l)
	if meilleure >= 2 or oeuf:
		Effets.etincelles(get_parent(), global_position + Vector3(0, 0.6, 0), Vector3.UP, col, 18, 4.0, "star_06.png", 0.35)

func texte_action() -> String:
	return "Fouiller"

func disponible() -> bool:
	return corps

func interagir(h: Heros) -> void:
	h.canaliser("Fouille de la dépouille", 1.0, "PickUp")
	var res: Array = await h.canal_fini
	if not res[1] or not is_instance_valid(self):
		return
	if h == Jeu.joueur:
		Jeu.ouvrir_butin("Dépouille de " + nom, butin, h, Color("#FFD9B0"))
	else:
		butin = h.ramasser(butin, "la dépouille de " + nom)
	_verifier_vide()

func _verifier_vide() -> void:
	if butin["or"] <= 0 and butin["objets"].is_empty():
		queue_free()

func _process(delta: float) -> void:
	_vie -= delta
	if _vie <= 0.0:
		queue_free()
		return
	if corps:
		_verifier_vide()
		return
	# bourse de monstre : on la ramasse en passant dessus
	for h in get_tree().get_nodes_in_group("joueur"):
		if h.est_mort:
			continue
		if Vector2(h.global_position.x - global_position.x, h.global_position.z - global_position.z).length() < 1.6:
			butin = h.ramasser(butin)
			Sons.jouer("pret", global_position, -10.0, 1.4)
			_verifier_vide()
			return
