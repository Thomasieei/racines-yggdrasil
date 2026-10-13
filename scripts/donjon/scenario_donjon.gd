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

## Camps de monstres de l'étage. Pensé pour une vingtaine de joueurs en même temps : environ 60 draugr
## répartis en 25 camps sur quatre ailes, et chaque camp vidé se repeuple (sans jamais apparaître sous les yeux d'un joueur).
## [identifiant, délai de repeuplement (s), [[type, position, aggro], ...]]
const CAMPS := [
	["boyau", 70.0, [["arbaletrier", Vector3(6.5, 0, -21), 10.0], ["minion", Vector3(11.5, 0, -12), 7.0], ["minion", Vector3(9.0, 0, -15), 7.0]]],
	["entree", 70.0, [["guerrier", Vector3(4, 0, -36), 10.0], ["minion", Vector3(8, 0, -38), 8.0]]],
	["nid", 75.0, [["minion", Vector3(-26, 0, -44), 9.0], ["minion", Vector3(-21, 0, -49), 9.0], ["minion", Vector3(-27, 0, -50), 9.0], ["minion", Vector3(-20, 0, -43), 9.0]]],
	["autel", 80.0, [["mage", Vector3(-27, 0, -76), 11.0], ["minion", Vector3(-24, 0, -70), 9.0], ["minion", Vector3(-31, 0, -69), 9.0]]],
	["gouffre", 80.0, [["arbaletrier", Vector3(18, 0, -55), 12.0], ["mage", Vector3(16, 0, -62), 12.0]]],
	["campement", 90.0, [["guerrier", Vector3(20, 0, -76), 11.0], ["arbaletrier", Vector3(14, 0, -83), 12.0], ["arbaletrier", Vector3(27, 0, -83), 12.0], ["minion", Vector3(22, 0, -72), 9.0]]],
	["jarl", 240.0, [["jarl", Vector3(74, 0, -59), 9.0]]],
	["centre", 70.0, [["guerrier", Vector3(-8, 0, -46), 10.0], ["arbaletrier", Vector3(-14, 0, -52), 11.0]]],
	["est", 60.0, [["minion", Vector3(40, 0, -40), 8.0], ["minion", Vector3(44, 0, -44), 8.0], ["minion", Vector3(38, 0, -47), 8.0]]],
	["nord", 75.0, [["arbaletrier", Vector3(-6, 0, -86), 11.0], ["mage", Vector3(0, 0, -80), 11.0]]],
	["descente", 80.0, [["guerrier", Vector3(19, 0, -92), 10.0], ["minion", Vector3(15, 0, -94), 8.0]]],
	["couloir_ouest", 70.0, [["arbaletrier", Vector3(-48, 0, -60), 11.0], ["minion", Vector3(-54, 0, -58), 8.0]]],
	["tombes", 75.0, [["minion", Vector3(-86, 0, -74), 9.0], ["minion", Vector3(-82, 0, -70), 9.0], ["minion", Vector3(-90, 0, -70), 9.0]]],
	["chapelle", 80.0, [["mage", Vector3(-96, 0, -46), 11.0], ["minion", Vector3(-100, 0, -51), 9.0]]],
	["garde_royale", 90.0, [["guerrier", Vector3(-98, 0, -67), 10.0], ["guerrier", Vector3(-98, 0, -56), 10.0]]],
	["reine", 240.0, [["reine", Vector3(-104, 0, -62), 10.0]]],
	["noyes", 70.0, [["minion", Vector3(-70, 0, -4), 9.0], ["minion", Vector3(-66, 0, 4), 9.0], ["minion", Vector3(-71, 0, 11), 9.0]]],
	["rive_ouest", 80.0, [["guerrier", Vector3(-106, 0, 4), 10.0], ["arbaletrier", Vector3(-103, 0, -7), 12.0]]],
	["rive_nord", 80.0, [["mage", Vector3(-92, 0, -13), 11.0], ["minion", Vector3(-84, 0, -15), 9.0]]],
	["couloir_lac", 70.0, [["arbaletrier", Vector3(-76, 0, -28), 11.0]]],
	["seuil_forges", 75.0, [["guerrier", Vector3(47, 0, -110), 10.0], ["arbaletrier", Vector3(45, 0, -118), 11.0]]],
	["halle", 90.0, [["guerrier", Vector3(52, 0, -127), 10.0], ["guerrier", Vector3(64, 0, -127), 10.0], ["arbaletrier", Vector3(58, 0, -119), 12.0]]],
	["coulees", 80.0, [["mage", Vector3(40, 0, -141), 11.0], ["minion", Vector3(46, 0, -144), 9.0], ["minion", Vector3(42, 0, -134), 9.0]]],
	["brokk", 240.0, [["brokk", Vector3(58, 0, -142), 9.0]]],
	["forges_est", 70.0, [["arbaletrier", Vector3(74, 0, -140), 11.0], ["minion", Vector3(72, 0, -130), 9.0]]],
]

const RAYON_ACTIF := 55.0          ## au-delà, un draugr ne pense ni ne s'anime (économie sur téléphone)
const RAYON_DISCRET := 30.0        ## un camp ne se repeuple pas si un joueur est plus près que ça

var _camps := {}
var _horloge := 0.0
var _lod_t := 0.0

func demarrer(p: Node, h: Heros, hd: CanvasLayer) -> void:
	principale = p
	heros = h
	hud = hd
	recit = CanvasLayer.new()
	recit.set_script(load("res://scripts/interface/recit.gd"))
	add_child(recit)
	recit.heros = h
	var poly := PackedVector2Array()
	for q in Caverne.CONTOUR:
		poly.append(q)
	for c in CAMPS:
		var centre := Vector3.ZERO
		for m in c[2]:
			centre += m[1]
			if not Geometry2D.is_point_in_polygon(Vector2(m[1].x, m[1].z), poly):
				push_warning("draugr hors de la caverne : %s %s" % [c[0], m[1]])
		centre /= float(c[2].size())
		_camps[c[0]] = {"def": c, "centre": centre, "vivants": [], "vide_depuis": -1.0}
		_peupler(c[0], false)
	_gardienne(Caverne.PUITS + Vector3(4.5, 0, 4.0), "Hilde", 30.0)
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
	if "--test-repeuplement" in OS.get_cmdline_user_args():
		_test_repeuplement()
	hud.regler_titre("Étage 1 · Crypte des nains", "Donjon du jour · se referme dans 14:52")
	recit.quete("Le donjon du jour", "Trouve la sortie de la crypte, au nord")
	await get_tree().create_timer(1.5).timeout
	recit.voix("Freya", "Ici, je ne te vois presque plus. Reste près de la lumière.", 4.0)

func _gardienne(pos: Vector3, nom: String, rot: float) -> void:
	var g := Pnj.new()
	g.role = "garde"
	g.nom = nom
	g.titre = "Gardienne du camp"
	g.garde = true
	g.position = pos
	g.rotation_degrees.y = rot
	principale.add_child.call_deferred(g)

## Fait apparaître un camp. `reveil` : réapparition visible (les morts sortent de terre).
func _peupler(id: String, reveil: bool) -> void:
	var camp: Dictionary = _camps[id]
	camp["vivants"] = []
	camp["vide_depuis"] = -1.0
	for m in camp["def"][2]:
		var d := Draugr.new()
		d.configurer(m[0])
		d.position = m[1]
		d.aggro_rayon = m[2]
		d.camp_id = id
		principale.add_child.call_deferred(d)
		camp["vivants"].append(d)
		if reveil:
			Effets.poussiere.call_deferred(principale, m[1], 10, Color(0.5, 0.45, 0.4, 0.6))

func _heros_tous() -> Array:
	return get_tree().get_nodes_in_group("joueur").filter(func(x): return not x.est_mort)

func _repeupler(delta: float) -> void:
	_horloge += delta
	for id in _camps:
		var camp: Dictionary = _camps[id]
		camp["vivants"] = camp["vivants"].filter(func(d): return is_instance_valid(d) and not d.est_mort)
		if not camp["vivants"].is_empty():
			continue
		if camp["vide_depuis"] < 0.0:
			camp["vide_depuis"] = _horloge
			continue
		if _horloge - camp["vide_depuis"] < camp["def"][1]:
			continue
		var proche := false
		for hh in _heros_tous():
			if hh.global_position.distance_to(camp["centre"]) < RAYON_DISCRET:
				proche = true
		if not proche:
			_peupler(id, true)

## Les draugr loin de tout joueur dorment vraiment : ni IA, ni animation, ni dessin.
func _economie() -> void:
	var hs := _heros_tous()
	for d in get_tree().get_nodes_in_group("monstre"):
		if d.est_mort or not d is Draugr:
			continue
		var dist := 1e9
		for hh in hs:
			dist = minf(dist, d.global_position.distance_to(hh.global_position))
		var actif: bool = dist < RAYON_ACTIF or d.etat not in ["dort"]
		if actif != d.is_physics_processing():
			d.set_physics_process(actif)
			if d.modele:
				d.modele.visible = actif and (d.etat != "dort" or not d.fiche.get("enterre", false))
			if d.anim:
				if actif:
					d.anim.play()
				else:
					d.anim.pause()

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
		{"type": "cercle", "c": Vector2(Caverne.LAC.x, Caverne.LAC.z), "r": 10.0, "couleur": Color(0.04, 0.12, 0.14)},
	]
	mc.lieux = [
		{"c": Vector2(Caverne.CAMP.x, Caverne.CAMP.z), "genre": "sur"},
		{"c": Vector2(Caverne.ANTRE.x, Caverne.ANTRE.z), "genre": "elite"},
		{"c": Vector2(Caverne.DESCENTE.x, Caverne.DESCENTE.z), "genre": "portail"},
		{"c": Vector2(Caverne.CAMPEMENT.x, Caverne.CAMPEMENT.z), "genre": "danger"},
		{"c": Vector2(Caverne.AUTEL.x, Caverne.AUTEL.z), "genre": "danger"},
		{"c": Vector2(Caverne.NID.x, Caverne.NID.z), "genre": "danger"},
		{"c": Vector2(Caverne.PUITS.x, Caverne.PUITS.z), "genre": "sur"},
		{"c": Vector2(Caverne.TRONE_REINE.x, Caverne.TRONE_REINE.z), "genre": "elite"},
		{"c": Vector2(Caverne.ENCLUME_BROKK.x, Caverne.ENCLUME_BROKK.z), "genre": "elite"},
		{"c": Vector2(Caverne.LAC.x, Caverne.LAC.z), "genre": "danger"},
	]

func _process(_d: float) -> void:
	if heros == null or not is_instance_valid(heros):
		return
	_lod_t -= _d
	if _lod_t <= 0.0:
		_lod_t = 0.4
		_repeupler(0.4)
		_economie()
	var l := Caverne.lieu_de(heros.global_position)
	var id: String = l.get("id", "")
	if id == "" or id == _lieu:
		return
	_lieu = id
	var nom: String = l["nom"]
	match id:
		"camp", "puits":
			recit.bandeau(nom, "Zone sûre — souffle, soigne-toi, repars", Color("#9DFFC8"))
			hud.regler_titre(nom, "Zone sûre", Color("#9DFFC8"))
			if id == "camp" and not _vus.has("camp"):
				recit.voix("Sigrun", "Pose ta hache, voyageur. Rien ne franchit ce cercle tant que je respire.", 4.5)
		"crypte":
			hud.regler_titre("Étage 1 · Crypte des nains", "Donjon du jour · se referme dans 14:52")
		"antre", "trone", "enclume":
			recit.bandeau(nom, "Élite — un coffre légendaire dort derrière lui", Color("#FF9A2E"))
			hud.regler_titre("Étage 1 · " + nom, "Élite", Color("#FF9A2E"))
		"lac", "ossuaire", "forges":
			var sous: String = {"lac": "Ceux qui sont tombés à l'eau ne dorment pas", "ossuaire": "Les rois morts gardent leurs tombes", "forges": "Le feu des nains brûle encore"}[id]
			if not _vus.has(id):
				recit.bandeau(nom, sous, Color("#FF9C8A"))
			hud.regler_titre("Étage 1 · " + nom, "Zone hostile", Color("#FF9C8A"))
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

func _test_repeuplement() -> void:
	await get_tree().create_timer(2.0).timeout
	for d in _camps["est"]["vivants"]:
		d.recevoir({"montant": 99999.0})
	for t in [5, 40, 70]:
		await get_tree().create_timer(t - (0 if t == 5 else 0)).timeout
		var n: int = _camps["est"]["vivants"].filter(func(d): return is_instance_valid(d) and not d.est_mort).size()
		var actifs := get_tree().get_nodes_in_group("monstre").filter(func(d): return not d.est_mort and d.is_physics_processing()).size()
		var total := get_tree().get_nodes_in_group("monstre").filter(func(d): return not d.est_mort).size()
		printerr("TEST t+", t, " camp est vivants=", n, " draugr actifs=", actifs, "/", total)
	get_tree().quit()
