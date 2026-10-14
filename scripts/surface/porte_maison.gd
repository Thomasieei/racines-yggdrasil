class_name PorteMaison
extends Node3D
## La porte d'une maison. Un villageois dont tu as pris le corps peut y entrer pour la fouiller (3 s).
## Si un garde (ou un voisin) le voit : « Au voleur ! ». Les pantins, eux, cambriolent sur ordre.

var maison: Dictionary = {}
var colonie: Colonie
var rayon_action := 2.8
var rayon := 2.8
var videe_t := 0.0

func _ready() -> void:
	add_to_group("interactif")
	add_to_group("portes")

func _process(delta: float) -> void:
	videe_t = maxf(0.0, videe_t - delta)

func nom_maison() -> String:
	if maison.get("nom", "") != "":
		return maison["nom"]
	return "Maison " + maison.get("famille", "")

func _corps_pris() -> bool:
	return Pouvoirs.moi != null and Pouvoirs.moi.controle != null

func texte_action() -> String:
	if _corps_pris():
		return "Fouiller"
	if Interieur.new_est_a_moi(maison, colonie):
		return "Entrer chez toi"
	return "Entrer"

func disponible() -> bool:
	if _corps_pris():
		return videe_t <= 0.0
	return maison.get("genre", "") in ["maison", "taverne", "forge", "temple", "chateau", "hall"]

func interagir(h) -> void:
	if not _corps_pris():
		Interieur.entrer(maison, colonie, h)
		return
	var v: Villageois = Pouvoirs.moi.controle
	if v == null or v.global_position.distance_to(global_position) > 3.4:
		return
	videe_t = 600.0
	v.controle = false
	v.jouer("Interact")
	Jeu.notifier("%s fouille %s…" % [v.nom, nom_maison().to_lower()], Color("#D9B8FF"))
	Sons.jouer("tissu", global_position, -2.0, 0.9)
	v._rentrer()
	var vu: Villageois = null
	for i in 6:
		await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(v):
		return
	v._sortir()
	vu = Village.moi.temoin(v.global_position, 12.0, v) if Village.moi else null
	v.controle = true
	var butin := Pantins.butin_maison(maison)
	if vu:
		Village.moi.alerte_vol(v, global_position, vu)
		Pouvoirs.moi.rompre_controle()
		return
	Pouvoirs.moi.butin_vol.append(butin)
	Profil.p().compter("vols")
	Jeu.notifier("%s a tout glissé sous sa veste : %d or%s. Rentre avant la fin du sort !" % [v.nom, butin["or"], (" + " + str(butin["objets"].size()) + " objet(s)") if not butin["objets"].is_empty() else ""], Color("#FFD36B"))
