class_name ObjetInterieur
extends Node3D
## Ce qu'on peut faire dans un intérieur : fouiller un coffre, boire une chope, dormir,
## parler à l'intendante (recruter des serviteurs), voler le trésor du Jarl… à ses risques.

const PRIX_SERVITEUR := 150
const MAX_SERVITEURS := 3

var genre := "coffre"
var interieur: Interieur
var rayon_action := 2.4
var rayon := 2.4
var _vide_t := 0.0

func _ready() -> void:
	add_to_group("interactif")

func _process(delta: float) -> void:
	_vide_t = maxf(0.0, _vide_t - delta)

func texte_action() -> String:
	match genre:
		"coffre": return "Fouiller le coffre"
		"tresor": return "Voler le trésor"
		"chope": return "Boire une chope (20 or)"
		"lit": return "Dormir jusqu'à l'aube"
		"intendant": return "Serviteurs"
	return "…"

func disponible() -> bool:
	if Jeu.joueur == null:
		return false
	match genre:
		"coffre", "tresor":
			return _vide_t <= 0.0
		"chope":
			return Jeu.joueur.sac.or_ >= 20 and Jeu.joueur.pv < Jeu.joueur.pv_max
	return true

func interagir(h) -> void:
	match genre:
		"coffre":
			_fouiller(h)
		"tresor":
			_tresor(h)
		"chope":
			h.sac.or_ -= 20
			h.sac.change.emit()
			h.soigner(h.pv_max)
			h.jouer("Cheer", 0.1, 1.0, 1.0)
			Sons.jouer("potion", h.global_position, 0.0, 0.9)
			Jeu.notifier("Une bonne chope d'hydromel : te voilà requinqué.", Color("#FFD36B"))
		"lit":
			h.soigner(h.pv_max)
			h.mana = h.mana_max
			h.mana_change.emit(h.mana, h.mana_max)
			if Village.moi:
				Village.moi.heure = 6.5
			Jeu.notifier("Tu dors d'une traite. L'aube se lève sur Brekka.", Color("#FFE2A0"))
		"intendant":
			_serviteurs(h)

func _fouiller(h) -> void:
	var gens: Array = interieur._presents() if interieur else []
	if not gens.is_empty():
		var v: Villageois = gens[0]
		Jeu.notifier("« Hé ! Sors de chez moi, voleur ! » — %s te met dehors." % v.nom, Color("#FF9C8A"))
		Sons.jouer("cloche", h.global_position, -4.0, 1.3)
		Interieur.sortir(h)
		return
	_vide_t = 600.0
	h.canaliser("Fouille", 1.6)
	var res: Array = await h.canal_fini
	if not res[1]:
		_vide_t = 0.0
		return
	var b := Pantins.butin_maison(interieur.maison if interieur else {})
	h.ramasser(b, "le coffre")
	Profil.p().compter("vols")

## Le trésor du Jarl : tout le monde rêve d'y toucher. Les huscarls veillent.
func _tresor(h) -> void:
	_vide_t = 900.0
	h.canaliser("Crochetage", 3.0)
	await get_tree().create_timer(1.2).timeout
	if not is_instance_valid(h):
		return
	Jeu.notifier("« Aux armes ! Un voleur dans la salle du trône ! »", Color("#FF6A5A"))
	Sons.jouer("cloche", h.global_position, 2.0, 1.0)
	for i in 2:
		var d := Draugr.new()
		d.configurer("huscarl")
		d.position = global_position + Vector3(-3.0 - i * 2.0, 0, 2.0)
		d.aggro_rayon = 20.0
		get_parent().add_child(d)
		d.reveiller.call_deferred(h)
	var res: Array = await h.canal_fini
	if not res[1]:
		_vide_t = 30.0
		return
	var b := Pantins.butin_maison({"genre": "chateau"})
	h.ramasser(b, "le trésor du Jarl")
	Profil.p().compter("vols")

func _serviteurs(h) -> void:
	var l: Array = Profil.p().vus.get("serviteurs", [])
	if l.size() >= MAX_SERVITEURS:
		Jeu.notifier("Ta maison a déjà %d serviteurs. Donne-leur des ordres (médaillons à gauche)." % MAX_SERVITEURS, Color("#FFE2A0"))
		return
	if h.sac.or_ < PRIX_SERVITEUR:
		Jeu.notifier("Un serviteur coûte %d or (gages de l'année)." % PRIX_SERVITEUR, Color("#CFD6EE"))
		return
	h.sac.or_ -= PRIX_SERVITEUR
	h.sac.change.emit()
	var femme := randf() < 0.5
	var noms: Array = Bourgs.PRENOMS_F if femme else Bourgs.PRENOMS_H
	var s := {"nom": noms[randi() % noms.size()], "femme": femme, "modele": ("robe" if femme else ["paysan", "barbare"][randi() % 2]),
		"teinte": Villageois.ETOFFES[randi() % Villageois.ETOFFES.size()].to_html()}
	l.append(s)
	Profil.p().vus["serviteurs"] = l
	Profil.p()._marquer()
	if Village.moi:
		var v := Village.moi.ajouter_serviteur(s)
		if v:
			v.global_position = h.global_position + Vector3(1.2, 0, 1.0)
	Jeu.notifier("%s entre à ton service. Il obéit comme un pantin, sans te coûter de mana." % s["nom"], Color("#D9B8FF"))
