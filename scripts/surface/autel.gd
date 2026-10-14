class_name Autel
extends Node3D
## Les Pierres d'Odin : on y prie, et le mana revient d'un coup (une fois toutes les 3 minutes).

var rayon_action := 3.5
var rayon := 3.5
var _pret_t := 0.0

func _ready() -> void:
	add_to_group("interactif")

func _process(delta: float) -> void:
	_pret_t = maxf(0.0, _pret_t - delta)

func texte_action() -> String:
	return "Prier Odin"

func disponible() -> bool:
	return _pret_t <= 0.0 and Jeu.joueur != null and Jeu.joueur.mana < Jeu.joueur.mana_max - 1.0

func interagir(h) -> void:
	_pret_t = 180.0
	h.mana = h.mana_max
	h.mana_change.emit(h.mana, h.mana_max)
	h.jouer("Cheer", 0.1, 1.0, 1.0)
	Effets.onde(get_parent(), global_position, 8.0, Color(0.6, 0.8, 1.0))
	Effets.etincelles(get_parent(), h.global_position + Vector3(0, 1, 0), Vector3.UP, Color(0.6, 0.85, 1.0), 30, 6.0, "star_06.png", 0.4)
	Sons.jouer("cloche", global_position, 0.0, 1.1)
	Jeu.notifier("Odin t'entend : ton mana est plein.", Color("#BFD8FF"))
