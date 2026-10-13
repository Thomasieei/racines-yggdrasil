class_name Sac
extends RefCounted
## Sac d'un aventurier : cases d'objets + or. L'or ne se voit que dans le sac.
## Ce qui est dans le sac est perdu à la mort : il reste sur le corps, et le tueur peut le prendre.

signal change

const CAPACITE := 30

var objets: Array = []
var or_ := 0
var arme: Dictionary = {}       ## arme équipée (vide = hache du Jarl de départ)
var acolyte: Dictionary = {}    ## dragon équipé
var reliques: Array = [{}, {}, {}, {}, {}, {}]   ## six emplacements de reliques

func reliques_portees() -> int:
	return reliques.filter(func(r): return not r.is_empty()).size()

## Somme des bonus des reliques portées pour un effet.
func bonus_relique(stat: String) -> float:
	var v := 0.0
	for r in reliques:
		if not r.is_empty() and r.get("stat", "") == stat:
			v += r["bonus"]
	return v

## Porte une relique du sac (premier emplacement libre, sinon à la place de la moins précieuse).
func porter_relique(o: Dictionary) -> void:
	var i := -1
	for k in reliques.size():
		if reliques[k].is_empty():
			i = k
			break
	if i < 0:
		i = 0
		for k in reliques.size():
			if reliques[k]["valeur"] < reliques[i]["valeur"]:
				i = k
		objets.append(reliques[i])
	objets.erase(o)
	reliques[i] = o
	change.emit()

func retirer_relique(i: int) -> bool:
	if reliques[i].is_empty() or objets.size() >= CAPACITE:
		return false
	objets.append(reliques[i])
	reliques[i] = {}
	change.emit()
	return true

func ajouter(o: Dictionary) -> bool:
	# empile avec un objet identique (même modèle, même rareté)
	if o.get("pile", 1) > 1:
		for x in objets:
			if x["id"] == o["id"] and x["rarete"] == o["rarete"] and x["qte"] < x["pile"]:
				var place: int = x["pile"] - x["qte"]
				var n: int = mini(place, o["qte"])
				x["qte"] += n
				o["qte"] -= n
				if o["qte"] <= 0:
					change.emit()
					return true
	if objets.size() >= CAPACITE:
		change.emit()
		return false
	objets.append(o)
	change.emit()
	return true

func retirer(o: Dictionary, qte := -1) -> void:
	if qte < 0 or qte >= o["qte"]:
		objets.erase(o)
	else:
		o["qte"] -= qte
	change.emit()

func compter(id: String) -> int:
	var n := 0
	for x in objets:
		if x["id"] == id:
			n += x["qte"]
	return n

func valeur() -> int:
	var v := or_
	for x in objets:
		v += x["valeur"] * x["qte"]
	for e in [arme, acolyte] + reliques:
		if not e.is_empty():
			v += e["valeur"]
	return v

func ajouter_or(n: int) -> void:
	or_ += n
	change.emit()

## Tout ce que le sac contient (objets + équipement), pour le corps laissé à la mort.
func tout_vider() -> Dictionary:
	var butin := {"or": or_, "objets": objets.duplicate()}
	for e in [arme, acolyte] + reliques:
		if not e.is_empty():
			butin["objets"].append(e)
	reliques = [{}, {}, {}, {}, {}, {}]
	objets.clear()
	or_ = 0
	arme = {}
	acolyte = {}
	change.emit()
	return butin
