class_name Village
extends Node
## Le Hameau de Brekka vit : une horloge (une journée ≈ 5 min), des familles, des métiers,
## deux gardes qui font leur ronde. Les maisons peuvent être fouillées… par un villageois
## dont on a pris l'esprit. Si un garde le voit, c'est l'alerte.

const HEURE_S := 12.0         ## secondes réelles par heure de jeu
const RESIDENTS := [
	# nom, métier, maison (index de MAISONS), poste, modèle, enfant
	["Sigurd", "Chef du hameau", 0, "place", "chevalier", false],
	["Brynja", "Fermière", 0, "champs", "marchand", false],
	["Eyvind", "Fils de Brynja", 0, "jeux", "marchand", true],
	["Ingrun", "Bûcheronne", 1, "scierie", "barbare", false],
	["Kári", "Bûcheron", 1, "scierie", "barbare", false],
	["Lif", "Fille d'Ingrun", 1, "jeux", "freya", true],
	["Bard", "Meunier", 2, "moulin", "marchand", false],
	["Åsa", "Meunière", 2, "moulin", "freya", false],
	["Dagny", "Tisserande", 3, "place", "freya", false],
	["Orm", "Charpentier", 3, "chantier", "barbare", false],
	["Tove", "Fils de Dagny", 3, "jeux", "barbare", true],
	["Gudrun", "Aubergiste", 4, "taverne", "freya", false],
	["Halli", "Commis de taverne", 4, "taverne", "marchand", false],
]
const MODELES := {"chevalier": "res://assets/personnages/chevalier.glb", "marchand": "res://assets/personnages/marchand.glb",
	"barbare": "res://assets/personnages/barbare.glb", "freya": "res://assets/personnages/freya.glb"}
const POSTES := {"place": Vector3(53, 0, 9), "champs": Vector3(33, 0, 30), "scierie": Vector3(71, 0, 11), "moulin": Vector3(34, 0, 10),
	"chantier": Vector3(60, 0, 26), "taverne": Vector3(53, 0, 1.5), "jeux": Vector3(53, 0, 18)}
const CACHOT := Vector3(127, 0, 30)   ## les voleurs sont menés au Bourg

static var moi: Village

var principale: Node
var heure := 9.0
var habitants: Array = []
var gardes: Array = []
var portes: Array = []
var _derniere_tranche := ""
var _ronde_t := 0.0

func _ready() -> void:
	moi = self

func _exit_tree() -> void:
	if moi == self:
		moi = null

func demarrer(p: Node) -> void:
	principale = p
	var familles: Array = []
	for m in CarteSurface.MAISONS:
		familles.append(m[3])
	for r in RESIDENTS:
		var v := Villageois.new()
		v.nom = r[0]
		v.metier = r[1]
		var mi: int = r[2]
		v.famille = familles[mi]
		v.maison = _porte(mi)
		v.travail = POSTES[r[3]]
		v.modele_chemin = MODELES[r[4]]
		v.enfant = r[5]
		v.teinte = Color.from_hsv(randf(), randf_range(0.35, 0.7), randf_range(0.6, 1.0))
		v.position = v.travail + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		p.add_child(v)
		habitants.append(v)
		if r[0] == "Sigurd":
			v.activer_parole(func(h):
				var ui := CanvasLayer.new()
				ui.set_script(load("res://scripts/interface/hameau_ui.gd"))
				p.add_child(ui)
				ui.ouvrir(h))
	for i in 2:
		var g := Villageois.new()
		g.nom = ["Hjalmar", "Sölvi"][i]
		g.metier = "Garde du hameau"
		g.modele_chemin = MODELES["chevalier"]
		g.teinte = Color(0.55, 0.15, 0.12)
		g.vitesse = 2.0
		g.position = CarteSurface.PLACE_VILLAGE + Vector3(-8 + i * 16, 0, 6)
		p.add_child(g)
		gardes.append(g)
	for i in CarteSurface.MAISONS.size():
		var porte := PorteMaison.new()
		porte.indice = i
		porte.nom_maison = ("Maison " + CarteSurface.MAISONS[i][3]) if i < 4 else CarteSurface.MAISONS[i][3]
		porte.position = _porte(i)
		p.add_child(porte)
		portes.append(porte)
	reassigner()
	Hameau.avancer()
	_annoncer_grenier()

## Les métiers choisis par le chef décident où chacun travaille.
func reassigner() -> void:
	for i in RESIDENTS.size():
		var r: Array = RESIDENTS[i]
		var v: Villageois = habitants[i]
		var m := Hameau.metier_de(r[0])
		v.travail = POSTES[Hameau.METIERS[m]["poste"]] if m != "" else POSTES[r[3]]
		if m != "":
			v.metier = Hameau.METIERS[m]["nom"] + " (pour toi)"
		v._etiquette.text = v.nom + "\n" + v.metier
	_appliquer_heure(true)

func _annoncer_grenier() -> void:
	if not Hameau.est_chef():
		return
	await get_tree().create_timer(5.0).timeout
	var e := Hameau.etat()
	var o := int(e["stock"].get("or", 0.0))
	var b := int(e["stock"].get("bois", 0.0))
	if o + b > 0:
		Jeu.notifier("Brekka a produit pour toi : %d or, %d bois… Va voir Sigurd." % [o, b], Color("#FFE2A0"))

## Devant la porte d'une maison (côté place).
func _porte(i: int) -> Vector3:
	var m: Array = CarteSurface.MAISONS[i]
	var c: Vector3 = m[1]
	var vers := (CarteSurface.PLACE_VILLAGE - c)
	vers.y = 0
	return c + vers.normalized() * 4.6

func tranche() -> String:
	if heure >= 6.0 and heure < 12.0:
		return "travail"
	if heure >= 12.0 and heure < 13.5:
		return "repas"
	if heure >= 13.5 and heure < 18.0:
		return "travail"
	if heure >= 18.0 and heure < 21.5:
		return "veillee"
	return "nuit"

func _process(delta: float) -> void:
	heure = fmod(heure + delta / HEURE_S, 24.0)
	_appliquer_heure(false)
	# rondes des gardes autour de la place
	_ronde_t -= delta
	if _ronde_t <= 0.0:
		_ronde_t = randf_range(6.0, 12.0)
		for g in gardes:
			if not g.controle:
				var a := randf() * TAU
				g.activite("ronde", CarteSurface.PLACE_VILLAGE + Vector3(cos(a) * 13.0, 0, sin(a) * 11.0 + 4.0))

func _appliquer_heure(force: bool) -> void:
	var t := tranche()
	if t == _derniere_tranche and not force:
		return
	_derniere_tranche = t
	for v in habitants:
		match t:
			"travail":
				v.activite("travail", v.travail if not v.enfant else POSTES["jeux"] + Vector3(randf_range(-6, 6), 0, randf_range(-3, 3)))
			"repas":
				v.activite("repas", POSTES["taverne"] + Vector3(randf_range(-4, 4), 0, randf_range(0, 3)))
			"veillee":
				var a := randf() * TAU
				v.activite("veillee", CarteSurface.PLACE_VILLAGE + Vector3(0, 0, 6) + Vector3(cos(a), 0, sin(a)) * 4.5)
			"nuit":
				v.activite("maison", v.maison)

func texte_heure() -> String:
	var h := int(heure)
	var noms := {"travail": "au travail", "repas": "à table", "veillee": "veillée au feu", "nuit": "tout le monde dort"}
	return "%d h · %s" % [h, noms[tranche()]]

## Un garde voit-il ce point (pour les vols) ?
func garde_proche(p: Vector3, rayon := 9.0) -> Villageois:
	for g in gardes:
		if not g.controle and g.global_position.distance_to(p) < rayon:
			return g
	return null
