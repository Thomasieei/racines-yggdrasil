class_name PorteMaison
extends Node3D
## La porte d'une maison du hameau. Seul un villageois sous contrôle d'esprit peut y entrer
## pour la fouiller (3 s). Si un garde passe à moins de 9 m pendant la fouille : « Au voleur ! ».

var indice := 0
var nom_maison := ""
var rayon_action := 2.6
var rayon := 2.6
var _videe_t := 0.0

func _ready() -> void:
	add_to_group("interactif")

func _process(delta: float) -> void:
	_videe_t = maxf(0.0, _videe_t - delta)

func texte_action() -> String:
	return "Fouiller"

func disponible() -> bool:
	return Pouvoirs.moi != null and Pouvoirs.moi.controle != null and _videe_t <= 0.0

func interagir(_h) -> void:
	var v: Villageois = Pouvoirs.moi.controle
	if v == null or v.global_position.distance_to(global_position) > 3.2:
		return
	_videe_t = 600.0
	v.controle = false
	v.jouer("Interact")
	Jeu.notifier("%s fouille %s…" % [v.nom, nom_maison.to_lower()], Color("#D9B8FF"))
	Sons.jouer("tissu", global_position, -2.0, 0.9)
	var vu: Villageois = null
	for i in 6:
		await get_tree().create_timer(0.5).timeout
		vu = Village.moi.garde_proche(v.global_position) if Village.moi else null
		if vu:
			break
	if not is_instance_valid(v):
		return
	v.controle = true
	if vu:
		Jeu.notifier("« Au voleur ! » — %s a vu %s." % [vu.nom, v.nom], Color("#FF6A5A"))
		Sons.jouer("cloche", global_position, 2.0, 1.4)
		Pouvoirs.moi.rompre_controle()
		v.arreter_voleur(Village.CACHOT)
		vu.activite("poursuite", Village.CACHOT)
		return
	# butin de maison : surtout de l'or, parfois un objet précieux
	var butin := {"or": randi_range(25, 140) * (2 if indice == 4 else 1), "objets": []}
	if randf() < 0.35:
		butin["objets"].append(Objets.creer("potion", "commun", randi_range(1, 2)))
	if randf() < 0.25:
		butin["objets"].append(Objets.creer(["tissu", "bois", "lingot_or"].pick_random(), "commun", randi_range(1, 3)))
	if randf() < 0.08:
		butin["objets"].append(Objets.creer("robe_resurrection", "legendaire"))
	if randf() < 0.06:
		butin["objets"].append(Objets.creer("relique", Objets.tirer_rarete([0.6, 0.3, 0.09, 0.01, 0])))
	if randf() < 0.02:
		butin["objets"].append(Objets.creer("oeuf", Objets.tirer_rarete([0.6, 0.3, 0.08, 0.02, 0])))
	Pouvoirs.moi.butin_vol.append(butin)
	Profil.p().compter("vols")
	Jeu.notifier("%s a tout glissé sous sa cape : %d or%s. Ramène-le avant la fin du sort !" % [v.nom, butin["or"], (" + " + str(butin["objets"].size()) + " objet(s)") if not butin["objets"].is_empty() else ""], Color("#FFD36B"))
