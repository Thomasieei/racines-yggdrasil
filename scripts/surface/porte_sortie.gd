class_name PorteSortie
extends Node3D
## La sortie d'un intérieur : une bande de lumière au seuil.

var rayon_action := 2.6
var rayon := 2.6

func _ready() -> void:
	add_to_group("interactif")
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.9, 0.7)
	l.light_energy = 1.2
	l.omni_range = 4.0
	l.position = Vector3(0, 1.2, 1.0)
	add_child(l)

func texte_action() -> String:
	return "Sortir"

func disponible() -> bool:
	return Pouvoirs.moi == null or Pouvoirs.moi.controle == null

func interagir(h) -> void:
	Interieur.sortir(h)
