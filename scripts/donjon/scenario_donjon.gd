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

## [type, position, aggro]
const MONSTRES := [
	# boyau : un tireur posté au coude, deux rampants sous les éboulis
	["arbaletrier", Vector3(6.5, 0, -21), 10.0], ["minion", Vector3(11.5, 0, -12), 7.0], ["minion", Vector3(9.0, 0, -15), 7.0],
	# entrée de la caverne
	["guerrier", Vector3(4, 0, -36), 10.0], ["minion", Vector3(8, 0, -38), 8.0],
	# nid des rampants : quatre sous terre
	["minion", Vector3(-26, 0, -44), 9.0], ["minion", Vector3(-21, 0, -49), 9.0], ["minion", Vector3(-27, 0, -50), 9.0], ["minion", Vector3(-20, 0, -43), 9.0],
	# autel du nécromant
	["mage", Vector3(-27, 0, -76), 11.0], ["minion", Vector3(-24, 0, -70), 9.0], ["minion", Vector3(-31, 0, -69), 9.0],
	# bord du gouffre : des tireurs de l'autre côté du vide
	["arbaletrier", Vector3(18, 0, -55), 12.0], ["mage", Vector3(16, 0, -62), 12.0],
	# campement draugr
	["guerrier", Vector3(20, 0, -76), 11.0], ["arbaletrier", Vector3(14, 0, -83), 12.0], ["arbaletrier", Vector3(27, 0, -83), 12.0], ["minion", Vector3(22, 0, -72), 9.0],
	# antre du Jarl
	["jarl", Vector3(74, 0, -59), 9.0],
]

func demarrer(p: Node, h: Heros, hd: CanvasLayer) -> void:
	principale = p
	heros = h
	hud = hd
	recit = CanvasLayer.new()
	recit.set_script(load("res://scripts/interface/recit.gd"))
	add_child(recit)
	recit.heros = h
	for m in MONSTRES:
		var d := Draugr.new()
		d.configurer(m[0])
		d.position = m[1]
		d.aggro_rayon = m[2]
		p.add_child.call_deferred(d)
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
	_minicarte()
	hud.regler_titre("Étage 1 · Crypte des nains", "Donjon du jour · se referme dans 14:52")
	recit.quete("Le donjon du jour", "Trouve la sortie de la crypte, au nord")
	await get_tree().create_timer(1.5).timeout
	recit.voix("Freya", "Ici, je ne te vois presque plus. Reste près de la lumière.", 4.0)

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
	]
	mc.lieux = [
		{"c": Vector2(Caverne.CAMP.x, Caverne.CAMP.z), "genre": "sur"},
		{"c": Vector2(Caverne.ANTRE.x, Caverne.ANTRE.z), "genre": "elite"},
		{"c": Vector2(Caverne.DESCENTE.x, Caverne.DESCENTE.z), "genre": "portail"},
		{"c": Vector2(Caverne.CAMPEMENT.x, Caverne.CAMPEMENT.z), "genre": "danger"},
		{"c": Vector2(Caverne.AUTEL.x, Caverne.AUTEL.z), "genre": "danger"},
		{"c": Vector2(Caverne.NID.x, Caverne.NID.z), "genre": "danger"},
	]

func _process(_d: float) -> void:
	if heros == null or not is_instance_valid(heros):
		return
	var l := Caverne.lieu_de(heros.global_position)
	var id: String = l.get("id", "")
	if id == "" or id == _lieu:
		return
	_lieu = id
	var nom: String = l["nom"]
	match id:
		"camp":
			recit.bandeau(nom, "Zone sûre — souffle, soigne-toi, repars", Color("#9DFFC8"))
			hud.regler_titre(nom, "Zone sûre", Color("#9DFFC8"))
			if not _vus.has("camp"):
				recit.voix("Sigrun", "Pose ta hache, voyageur. Rien ne franchit ce cercle tant que je respire.", 4.5)
		"crypte":
			hud.regler_titre("Étage 1 · Crypte des nains", "Donjon du jour · se referme dans 14:52")
		"antre":
			recit.bandeau(nom, "Élite — un coffre légendaire dort derrière lui", Color("#FF9A2E"))
			hud.regler_titre("Étage 1 · " + nom, "Élite", Color("#FF9A2E"))
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
