class_name Village
extends Node
## Fait vivre tous les lieux habités du Val : une horloge commune (une journée ≈ 5 min),
## les habitants de chaque colonie (métiers, familles, gardes), la justice (vols, agressions),
## la mort et le retour des habitants. Les lieux hostiles reçoivent leurs pillards.

const HEURE_S := 12.0         ## secondes réelles par heure de jeu
## Brekka : les habitants que le chef dirige (voir Hameau). [nom, métier, maison, rôle, modèle, enfant, femme]
const RESIDENTS := [
	["Sigurd", "Chef du hameau", 0, "chef", "barbare", false, false],
	["Brynja", "Fermière", 0, "fermier", "robe", false, true],
	["Eyvind", "Fils de Brynja", 0, "enfant", "paysan", true, false],
	["Ingrun", "Bûcheronne", 1, "bucheron", "paysan", false, true],
	["Kári", "Bûcheron", 1, "bucheron", "barbare", false, false],
	["Lif", "Fille d'Ingrun", 1, "enfant", "robe", true, true],
	["Bard", "Meunier", 2, "meunier", "paysan", false, false],
	["Åsa", "Meunière", 2, "meunier", "robe", false, true],
	["Dagny", "Tisserande", 3, "passant", "robe", false, true],
	["Orm", "Mineur", 3, "mineur", "barbare", false, false],
	["Tove", "Fils de Dagny", 3, "enfant", "paysan", true, false],
	["Gudrun", "Aubergiste", 4, "aubergiste", "robe", false, true],
	["Halli", "Commis de taverne", 4, "aubergiste", "paysan", false, false],
]
const ROLE_DE_METIER := {"bucheron": "bucheron", "mineur": "mineur", "fermier": "fermier", "garde": "garde"}
const NOMS_ROLE := {"bucheron": ["Bûcheron", "Bûcheronne"], "mineur": ["Mineur", "Mineuse"], "fermier": ["Fermier", "Fermière"],
	"forgeron": ["Forgeron", "Forgeronne"], "marchand": ["Marchand", "Marchande"], "aubergiste": ["Aubergiste", "Aubergiste"],
	"pecheur": ["Pêcheur", "Pêcheuse"], "meunier": ["Meunier", "Meunière"], "pretre": ["Prêtre d'Odin", "Prêtresse d'Odin"],
	"passant": ["Habitant", "Habitante"]}
const ARTISANS := [["Tisserand", "Tisserande"], ["Potier", "Potière"], ["Cordonnier", "Cordonnière"], ["Tanneur", "Tanneuse"], ["Charpentier", "Charpentière"],
	["Boulanger", "Boulangère"], ["Barbier", "Barbière"], ["Scalde", "Scalde"], ["Porteur d'eau", "Porteuse d'eau"]]
const POPULATION := {"brekka": 6, "jarnborg": 54, "vik": 16}

static var moi: Village

var principale: Node
var heure := 9.0
var colonies: Array = []
var habitants: Array = []
var gardes: Array = []
var portes: Array = []
var pillards: Array = []
var brekka: Colonie
var _derniere_tranche := ""
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	moi = self

func _exit_tree() -> void:
	if moi == self:
		moi = null

func demarrer(p: Node) -> void:
	principale = p
	var carte := CarteSurface.courante
	if carte == null or carte.bourgs == null:
		return
	for col in carte.bourgs.colonies:
		if col.faction == "hostile":
			pillards.append_array(Pillards.peupler(p, col))
			continue
		colonies.append(col)
		if col.id == "brekka":
			brekka = col
			_peupler_brekka(col)
		_peupler(col)
		_gardes(col)
		_portes(col)
	reassigner()
	Hameau.avancer()
	_annoncer_grenier()
	if Pantins.moi:
		Pantins.moi.restaurer.call_deferred()

# ---------------- peuplement ----------------

func _nouveau(col: Colonie, nom: String, metier: String, role: String, modele: String, enfant: bool, femme: bool, maison: Dictionary) -> Villageois:
	var v := Villageois.new()
	v.nom = nom
	v.metier = metier
	v.role = role
	v.colonie = col
	v.maison = maison
	v.famille = maison.get("famille", "")
	v.modele_id = modele
	v.enfant = enfant
	v.femme = femme
	v.teinte = Villageois.ETOFFES[_rng.randi() % Villageois.ETOFFES.size()].lerp(Color.WHITE, _rng.randf_range(0.0, 0.2))
	var depart: Vector3 = maison["porte"] if not maison.is_empty() else col.place
	v.position = NavMonde.point_libre(depart + Vector3(_rng.randf_range(-2, 2), 0, _rng.randf_range(-2, 2)))
	principale.add_child(v)
	habitants.append(v)
	col.habitants.append(v)
	if not maison.is_empty():
		maison["habitants"].append(v)
	return v

func _peupler_brekka(col: Colonie) -> void:
	for r in RESIDENTS:
		var m: Dictionary = col.maisons[r[2]] if r[2] < col.maisons.size() else {}
		var v := _nouveau(col, r[0], r[1], r[3], r[4], r[5], r[6], m)
		if r[0] == "Sigurd":
			v.activer_parole(func(h):
				var ui := CanvasLayer.new()
				ui.set_script(load("res://scripts/interface/hameau_ui.gd"))
				principale.add_child(ui)
				ui.ouvrir(h))

func _prenom(femme: bool) -> String:
	var l: Array = Bourgs.PRENOMS_F if femme else Bourgs.PRENOMS_H
	return l[_rng.randi() % l.size()]

func _modele(role: String, femme: bool) -> String:
	if femme:
		return "robe" if _rng.randf() < 0.6 else "paysan"
	if role in ["bucheron", "forgeron", "mineur"]:
		return "barbare" if _rng.randf() < 0.7 else "paysan"
	return "paysan" if _rng.randf() < 0.75 else "barbare"

func _peupler(col: Colonie) -> void:
	_rng.seed = hash(col.id)
	var reste: int = POPULATION.get(col.id, 10)
	var deja := {}
	# d'abord ceux qui tiennent un lieu : forge, étal, taverne, temple, moulin, scierie, château
	var tenanciers := {"forge": ["forgeron", 1], "marche": ["marchand", 1], "taverne": ["aubergiste", 2], "temple": ["pretre", 1], "moulin": ["meunier", 1], "scierie": ["bucheron", 2]}
	for m in col.maisons:
		var g: String = m["genre"]
		if col.id == "brekka" and g in ["taverne", "moulin", "scierie"]:
			continue
		if g == "chateau":
			var jarl := _nouveau(col, "Ragnvald", "Jarl de Jarnborg", "chef", "garde", false, false, m)
			jarl.pv_max = 4000.0
			jarl.force = 180.0
			jarl.teinte = Color(0.5, 0.18, 0.2)
			jarl.activer_parole(func(h): _audience(h, jarl))
			reste -= 1
			continue
		if not tenanciers.has(g):
			continue
		for k in tenanciers[g][1]:
			var femme := _rng.randf() < 0.4
			var role: String = tenanciers[g][0]
			var v := _nouveau(col, _prenom(femme), NOMS_ROLE[role][1 if femme else 0], role, _modele(role, femme), false, femme, m)
			if role == "marchand" or role == "forgeron":
				_commerce(v, role)
			reste -= 1
	for k2 in mini(3, col.postes.get("peche", []).size()):
		_nouveau(col, _prenom(false), "Pêcheur", "pecheur", "paysan", false, false, {})
		reste -= 1
	for k3 in mini(3, col.postes.get("champs", []).size() / 2):
		var f2 := _rng.randf() < 0.5
		_nouveau(col, _prenom(f2), NOMS_ROLE["fermier"][1 if f2 else 0], "fermier", _modele("fermier", f2), false, f2, {})
		reste -= 1
	# puis les familles, maison par maison
	var maisons := col.maisons_de("maison")
	if col.id == "brekka":
		maisons = maisons.slice(4)
	maisons.shuffle()
	for m2 in maisons:
		if reste <= 0:
			break
		var n := _rng.randi_range(1, 3)
		for i in n:
			if reste <= 0:
				break
			var enfant := i == 2 or (i == 1 and _rng.randf() < 0.3)
			var femme2 := (i == 1) if not enfant else _rng.randf() < 0.5
			var role2: String = "enfant" if enfant else ["passant", "passant", "fermier", "bucheron", "passant"][_rng.randi() % 5]
			if role2 == "bucheron" and not col.a_poste("scierie"):
				role2 = "passant"
			var metier: String
			if enfant:
				metier = ("Fille " if femme2 else "Fils ") + m2["famille"]
			elif role2 == "passant":
				metier = ARTISANS[_rng.randi() % ARTISANS.size()][1 if femme2 else 0]
			else:
				metier = NOMS_ROLE[role2][1 if femme2 else 0]
			_nouveau(col, _prenom(femme2), metier, role2, "paysan" if enfant else _modele(role2, femme2), enfant, femme2, m2)
			reste -= 1

func _gardes(col: Colonie) -> void:
	for i in col.nb_gardes:
		var m: Dictionary = col.maisons_de("caserne")[0] if not col.maisons_de("caserne").is_empty() else {}
		var g := _nouveau(col, _prenom(false), "Garde de " + col.nom.replace("Hameau de ", ""), "garde", "garde", false, false, m)
		g.pv_max = 1500.0
		g.force = 95.0
		g.vitesse_marche = 1.9
		g.teinte = Color(0.2, 0.32, 0.6) if col.id != "vik" else Color(0.22, 0.45, 0.28)
		g.set_meta("porte", i % 2 == 0 and col.a_poste("garde_porte"))
		g.set_meta("ronde", i / 2)
		gardes.append(g)
		col.gardes.append(g)

func _portes(col: Colonie) -> void:
	for m in col.maisons:
		if m["genre"] in ["maison", "taverne", "forge", "marche", "chateau", "temple"]:
			var porte := PorteMaison.new()
			porte.maison = m
			porte.colonie = col
			porte.position = m["porte"]
			principale.add_child(porte)
			portes.append(porte)

## Marchands et forgerons des villes : on peut leur parler (achat, vente, forge).
func _commerce(v: Villageois, role: String) -> void:
	v.activer_parole(func(h):
		var ui := CanvasLayer.new()
		ui.set_script(load("res://scripts/interface/comptoir_ui.gd"))
		principale.add_child(ui)
		ui.ouvrir(h, "forge" if role == "forgeron" else "marchand"), "Commercer")

func _audience(h: Node, jarl: Villageois) -> void:
	jarl.dire("Un guerrier qui fait des pantins de mes sujets… Prends garde, étranger.", 5.0)
	if Jeu.hud and Jeu.hud.has_method("regler_titre"):
		Jeu.notifier("Le Jarl Ragnvald t'observe. Ses huscarls aussi.", Color("#FFE2A0"))

## Les métiers choisis par le chef de Brekka décident du travail de chacun.
func reassigner() -> void:
	if brekka == null:
		return
	for i in RESIDENTS.size():
		var r: Array = RESIDENTS[i]
		if i >= brekka.habitants.size():
			break
		var v: Villageois = brekka.habitants[i]
		if v.pantin:
			continue
		var m := Hameau.metier_de(r[0])
		if m != "" and ROLE_DE_METIER.has(m):
			v.role = ROLE_DE_METIER[m]
			v.metier = Hameau.METIERS[m]["nom"] + " (pour toi)"
		else:
			v.role = r[3]
			v.metier = r[1]
		v._maj_etiquette()
		v.routine(tranche())

func _annoncer_grenier() -> void:
	if not Hameau.est_chef():
		return
	await get_tree().create_timer(5.0).timeout
	var e := Hameau.etat()
	var o := int(e["stock"].get("or", 0.0))
	var b := int(e["stock"].get("bois", 0.0))
	if o + b > 0:
		Jeu.notifier("Brekka a produit pour toi : %d or, %d bois… Va voir Sigurd." % [o, b], Color("#FFE2A0"))

# ---------------- horloge ----------------

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
	var t := tranche()
	if t != _derniere_tranche:
		_derniere_tranche = t
		for v in habitants:
			if is_instance_valid(v) and not v.est_mort:
				# chacun à son rythme : pas tous au même instant
				get_tree().create_timer(_rng.randf_range(0.0, 4.0)).timeout.connect(func():
					if is_instance_valid(v):
						v.routine(t))

func texte_heure() -> String:
	var h := int(heure)
	var noms := {"travail": "au travail", "repas": "à table", "veillee": "veillée au feu", "nuit": "tout le monde dort"}
	return "%d h · %s" % [h, noms[tranche()]]

# ---------------- justice ----------------

## Un garde voit-il ce point ?
func garde_proche(p: Vector3, r := 12.0) -> Villageois:
	for g in gardes:
		if is_instance_valid(g) and not g.est_mort and not g.pantin and not g.controle and not g.cache and g.global_position.distance_to(p) < r:
			return g
	return null

## Quelqu'un (pas un pantin) a-t-il vu ce point ? Les gardes voient loin, les autres crient.
func temoin(p: Vector3, r_garde: float, voleur: Node) -> Villageois:
	var g := garde_proche(p, r_garde)
	if g:
		return g
	for v in habitants:
		if is_instance_valid(v) and v != voleur and not v.est_mort and not v.pantin and not v.cache and not v.enfant and v.global_position.distance_to(p) < 7.0:
			return v
	return null

## Vol découvert : les gardes proches se lancent à la poursuite du voleur.
func alerte_vol(voleur: Villageois, p: Vector3, vu_par: Villageois) -> void:
	voleur.set_meta("recherche", true)
	if vu_par:
		vu_par.dire(["Au voleur !", "Arrêtez-le !", "Gardes ! Un voleur !"][randi() % 3], 3.0)
	Sons.jouer("cloche", p, 0.0, 1.4)
	for g in gardes:
		if is_instance_valid(g) and not g.est_mort and not g.pantin and g.global_position.distance_to(p) < 34.0:
			g.attaquer(voleur)
			g.dire("Halte, voleur !", 2.5)

## Une agression : les gardes du coin défendent la victime (pas les pillards entre eux).
func agression(auteur: Node, victime: Node) -> void:
	if auteur is Heros:
		return
	for g in gardes:
		if not is_instance_valid(g) or g.est_mort or g.pantin or g.controle or g == auteur or g.etat == "combat":
			continue
		if g.global_position.distance_to(victime.global_position) < 26.0:
			g.attaquer(auteur)
			g.dire("Halte !", 2.0)
	for v in habitants:
		if is_instance_valid(v) and v != victime and v != auteur and not v.est_mort and not v.pantin and v.role != "garde" and v.etat == "routine" \
				and v.global_position.distance_to(victime.global_position) < 9.0:
			v.fuir(auteur.global_position)

func deces(v: Villageois) -> void:
	if v.colonie:
		for o in v.colonie.habitants:
			if is_instance_valid(o) and o != v and not o.est_mort and o.famille == v.famille and o.famille != "" and o.global_position.distance_to(v.global_position) < 20.0:
				o.dire("Nooon ! " + v.nom + " !", 3.0)

## Le corps est emporté ; l'habitant revient chez lui un peu plus tard (la vie continue au village).
func renaitre_plus_tard(v: Villageois) -> void:
	v.visible = false
	v.remove_from_group("interactif")
	v.remove_from_group("depouilles_villageois")
	await get_tree().create_timer(240.0).timeout
	if not is_instance_valid(v) or not v.est_mort:
		return
	v.est_mort = false
	v.pv = v.pv_max
	v.etat = "routine"
	v.arrete = false
	v.visible = true
	v.global_position = v._porte_maison()
	v.add_to_group("villageois")
	v._maj_etiquette()
	v.routine(tranche())
