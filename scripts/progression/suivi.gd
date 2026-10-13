extends Node
## Observe la partie et nourrit le Codex : monstres abattus, mètres parcourus, coffres, minerais,
## reliques, lieux découverts… et les secrets (bord du gouffre, rive du lac, patience au camp,
## survivre de justesse). Enregistre le profil régulièrement.

var heros: Heros
var carte := "surface"
var _derniere_pos := Vector3.INF
var _metres := 0.0
var _t := 0.0
var _t_sauve := 0.0
var _abime := 0.0
var _patience := 0.0
var _fil := -1.0

func lancer(h: Heros, c: String) -> void:
	heros = h
	carte = c
	Jeu.ecouteurs.append(_sur_evenement)
	heros.ramasse.connect(_sur_ramasse)
	heros.sac.change.connect(_sur_sac)
	Profil.p().realisation.connect(_sur_realisation)

func _sur_evenement(nom: String, d: Dictionary) -> void:
	var pr := Profil.p()
	match nom:
		"tue":
			if d.get("joueur", false):
				pr.compter("tues")
				if d.get("elite", false) and not d.get("boss", false):
					pr.compter("elites")
					var cle := "elite_" + str(d.get("type", ""))
					if not pr.vu(cle):
						pr.marquer_vu(cle)
						pr.compter("elites_diff")
			if d.get("boss", false) and heros and heros.global_position.distance_to(Vector3(30, 0, -60)) < 45.0:
				pr.compter("boss")
		"coffre":
			pr.compter("coffres")
		"mine":
			pr.compter("minerais", d.get("qte", 1))
		"quete":
			pr.compter("quetes")
		"jcj":
			pr.compter("jcj")
		"portail":
			pr.compter("portail")
		"lieu":
			var cle2 := "lieu_" + str(d.get("id", ""))
			if not pr.vu(cle2):
				pr.marquer_vu(cle2)
				pr.compter("lieux")

func _sur_ramasse(_or: int, objets: Array, _origine: String) -> void:
	for o in objets:
		if o.get("type", "") == "relique":
			Profil.p().compter("reliques")

func _sur_sac() -> void:
	if heros == null:
		return
	Profil.p().maximum("or_max", heros.sac.or_)
	Profil.p().maximum("reliques_portees", heros.sac.reliques_portees())
	Profil.p().maximum("niveau_mineur", heros.metier_mine["niveau"])

func _sur_realisation(r: Dictionary) -> void:
	if Jeu.hud and is_instance_valid(Jeu.hud) and Jeu.hud.has_method("annoncer_realisation"):
		Jeu.hud.annoncer_realisation(r)

func _process(delta: float) -> void:
	if heros == null or not is_instance_valid(heros):
		return
	var pr := Profil.p()
	_t += delta
	# distance parcourue (on ignore les téléportations)
	var p := heros.global_position
	if _derniere_pos != Vector3.INF and not heros.est_mort:
		var pas := Vector2(p.x - _derniere_pos.x, p.z - _derniere_pos.z).length()
		if pas < 2.0:
			_metres += pas
	_derniere_pos = p
	if _metres >= 10.0:
		pr.compter("metres", int(_metres))
		_metres -= int(_metres)
	# secrets de la caverne
	if carte == "crypte" and not heros.est_mort:
		var g := Vector2(p.x - Caverne.GOUFFRE.x, p.z - Caverne.GOUFFRE.z)
		var r := Vector2(g.x / Caverne.GOUFFRE_R.x, g.y / Caverne.GOUFFRE_R.y).length()
		_abime = _abime + delta if r < 1.45 else 0.0
		if _abime > 10.0 and pr.valeur("abime") == 0:
			pr.compter("abime")
		if p.distance_to(Caverne.LAC) < 15.0 and pr.valeur("lac") == 0:
			pr.compter("lac")
		var immobile: bool = heros.velocity.length() < 0.2 and heros.action == ""
		_patience = _patience + delta if p.distance_to(Caverne.CAMP) < 9.0 and immobile else 0.0
		if _patience > 60.0 and pr.valeur("patience") == 0:
			pr.compter("patience")
	# sur le fil : tomber sous 5 % puis tenir 10 s
	if not heros.est_mort and heros.pv < heros.pv_max * 0.05 and _fil < 0.0:
		_fil = 0.0
	if _fil >= 0.0:
		if heros.est_mort:
			_fil = -1.0
		else:
			_fil += delta
			if _fil > 10.0:
				_fil = -1.0
				if pr.valeur("fil") == 0:
					pr.compter("fil")
	# sauvegarde
	_t_sauve += delta
	if _t_sauve > 5.0:
		_t_sauve = 0.0
		pr.sauver()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_EXIT_TREE:
		Profil.p().sauver()
