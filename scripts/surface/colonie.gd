class_name Colonie
extends RefCounted
## Un lieu habité : ses maisons (avec leur porte), ses postes de travail, ses rondes de garde,
## ses lieux de promenade. Construit par Bourgs, peuplé par Village.

var id := ""
var nom := ""
var faction := "libre"          ## libre, hostile
var rect := Rect2()
var place := Vector3.ZERO
var feu := Vector3.INF          ## veillée autour du feu
var cachot := Vector3.ZERO      ## où les gardes mènent les voleurs
var maisons: Array = []         ## {pos, rot, porte, dir, genre, nom, famille, habitants}
var postes := {}                ## genre -> Array[Vector3]
var rondes: Array = []          ## Array[Array[Vector3]] (boucles de patrouille)
var interets: Array = []        ## points de promenade
var nb_gardes := 2
var habitants: Array = []
var gardes: Array = []
var depot := Vector3.INF        ## où l'on rapporte bois et pierre
var stock := {}

func poste(genre: String, p: Vector3) -> void:
	if not postes.has(genre):
		postes[genre] = []
	postes[genre].append(p)

func un_poste(genre: String) -> Vector3:
	var l: Array = postes.get(genre, [])
	if l.is_empty():
		return place
	return l[randi() % l.size()]

func a_poste(genre: String) -> bool:
	return postes.has(genre) and not postes[genre].is_empty()

func interet() -> Vector3:
	if interets.is_empty():
		return place
	return interets[randi() % interets.size()]

func maisons_de(genre: String) -> Array:
	return maisons.filter(func(m): return m["genre"] == genre)
