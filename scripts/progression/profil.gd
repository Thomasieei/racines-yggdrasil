class_name Profil
extends RefCounted
## Progression permanente du joueur (survit à la mort et aux changements de carte) :
## compteurs du codex, réalisations obtenues, points de talent, talents investis.
## Enregistrée dans user://profil.cfg.

signal change
signal realisation(r: Dictionary)

const FICHIER := "user://profil.cfg"
const VERSION := 2          ## 2 : points du codex rééquilibrés, coût des talents par palier

static var _moi: Profil

var compteurs := {}         ## clé -> valeur (tués, mètres, coffres…)
var obtenues := {}          ## id réalisation -> true
var talents := {}           ## id talent -> rang
var points_gagnes := 0
var vus := {}
var classe := ""            ## "" = Berserker ; "souffle", "ecailles", "ailes" = voies draconiques
var _sale := false
var _t_sauve := 0.0

static func p() -> Profil:
	if _moi == null:
		_moi = Profil.new()
		_moi._charger()
	return _moi

# ---------------- points ----------------

## Plus un talent est profond dans l'arbre, plus chaque rang coûte : 1, 2, 3, 4 points, ultime 5.
static func cout(id: String) -> int:
	var t := Talents.par_id(id)
	return 5 if t.get("ultime", false) else int(t.get("palier", 0)) + 1

func points_investis() -> int:
	var n := 0
	for k in talents:
		n += talents[k] * cout(k)
	return n

func points_libres() -> int:
	return points_gagnes - points_investis()

func rang(id: String) -> int:
	return talents.get(id, 0)

func investis_dans_arbre() -> int:
	return points_investis()

## Raison pour laquelle on ne peut pas investir (vide = possible).
func refus_talent(id: String) -> String:
	var t := Talents.par_id(id)
	if t.is_empty():
		return "?"
	if rang(id) >= t["rangs"]:
		return "Talent au maximum"
	var seuil: int = Talents.SEUILS[t["palier"]]
	if investis_dans_arbre() < seuil:
		return "Investis %d points dans l'arbre pour ouvrir ce palier" % seuil
	if t.get("ultime", false):
		for u in Talents.LISTE:
			if u.get("ultime", false) and u["id"] != id and rang(u["id"]) > 0:
				return "Tu as déjà choisi « %s »" % u["nom"]
	if points_libres() < cout(id):
		return "Il faut %d point%s (tu en as %d)" % [cout(id), "s" if cout(id) > 1 else "", points_libres()]
	return ""

func investir(id: String) -> bool:
	if refus_talent(id) != "":
		return false
	talents[id] = rang(id) + 1
	_marquer()
	change.emit()
	return true

## Remet tous les points dans la bourse (le prix en or est payé par l'interface).
func reinitialiser() -> void:
	talents.clear()
	_marquer()
	change.emit()

## Somme des bonus de talents pour une statistique.
func stat(nom: String) -> float:
	var v := 0.0
	for id in talents:
		var t := Talents.par_id(id)
		if not t.is_empty() and t["stat"] == nom:
			v += t["val"] * talents[id]
	return v

# ---------------- codex ----------------

func compter(cle: String, n := 1) -> void:
	compteurs[cle] = compteurs.get(cle, 0) + n
	_verifier(cle)
	_marquer()

func maximum(cle: String, v: int) -> void:
	if v > compteurs.get(cle, 0):
		compteurs[cle] = v
		_verifier(cle)
		_marquer()

func valeur(cle: String) -> int:
	return int(compteurs.get(cle, 0))

func _verifier(cle: String) -> void:
	for r in Codex.LISTE:
		if r["compteur"] != cle or obtenues.has(r["id"]):
			continue
		if valeur(cle) >= r["but"]:
			obtenues[r["id"]] = true
			points_gagnes += r["pts"]
			realisation.emit(r)
			change.emit()

func vu(cle: String) -> bool:
	return vus.has(cle)

func marquer_vu(cle: String) -> void:
	vus[cle] = true
	_marquer()

# ---------------- sauvegarde ----------------

func _marquer() -> void:
	_sale = true

## Appelé régulièrement (et à la sortie) : écrit le fichier s'il a changé.
func sauver(force := false) -> void:
	if not _sale and not force:
		return
	_sale = false
	var c := ConfigFile.new()
	c.set_value("p", "compteurs", compteurs)
	c.set_value("p", "obtenues", obtenues)
	c.set_value("p", "talents", talents)
	c.set_value("p", "points", points_gagnes)
	c.set_value("p", "vus", vus)
	c.set_value("p", "classe", classe)
	c.set_value("p", "version", VERSION)
	c.save(FICHIER)

func _charger() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--classe="):
			classe = a.substr(9)
	if "--profil-neuf" in OS.get_cmdline_user_args():
		return
	var c := ConfigFile.new()
	if c.load(FICHIER) != OK:
		return
	compteurs = c.get_value("p", "compteurs", {})
	obtenues = c.get_value("p", "obtenues", {})
	talents = c.get_value("p", "talents", {})
	points_gagnes = c.get_value("p", "points", 0)
	vus = c.get_value("p", "vus", {})
	classe = c.get_value("p", "classe", "")
	if c.get_value("p", "version", 1) < VERSION:
		# rééquilibrage : on recompte les réalisations avec les nouveaux paliers et on rend les talents
		obtenues.clear()
		points_gagnes = 0
		talents.clear()
		for r in Codex.LISTE:
			if valeur(r["compteur"]) >= r["but"]:
				obtenues[r["id"]] = true
				points_gagnes += r["pts"]
		_sale = true
