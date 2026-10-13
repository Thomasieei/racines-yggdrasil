class_name Bot
extends Node
## Cerveau d'un aventurier piloté par l'IA (en attendant le vrai multijoueur).
## Il farme les camps, mine, ouvre les coffres, boit ses potions, va parfois se reposer,
## reste de temps en temps AFK… et, selon son tempérament, s'en prend au joueur quand
## celui-ci est affaibli. Celui qui gagne prend tout le sac de l'autre.
##
## Économie : loin du joueur (> 60 m), le bot passe en « simulation » : plus de physique,
## plus d'animation, plus de modèle ; il avance de case en case et règle ses combats aux dés.

const DISTANCE_REELLE := 60.0

var h: Heros
var nav: NavCaverne
var scenario: Node
var agressivite := 0.2          ## 0 = pacifique, 1 = pillard
var prudence := 0.5             ## seuil de fuite
var adresse := 0.6              ## chance de lire une attaque au sol

var etat := "aller"             ## aller, combat, afk, interagir, repos, pillage, mort
var objectif := {}              ## {"genre": "camp"|"objet"|"repos", "pos": Vector3, ...}
var _chemin := PackedVector3Array()
var _chemin_i := 0
var _t_pense := 0.0
var _t_etat := 0.0
var _t_afk := 0.0
var _t_pillage := 0.0
var _t_simu := 0.0
var _t_bloque := 0.0
var _pos_bloque := Vector3.ZERO
var _reflexe := 0.0
var _lectures := {}
var reel := true
var afk := false

func _ready() -> void:
	_t_afk = randf_range(40.0, 140.0)
	_t_pillage = randf_range(25.0, 60.0)
	h.mort.connect(_sur_mort)

# ---------------- outils ----------------

func _joueur() -> Heros:
	var j = Jeu.joueur
	return j if j is Heros and is_instance_valid(j) else null

func _aller_vers(p: Vector3) -> void:
	_chemin = nav.chemin(h.global_position, p)
	_chemin_i = 0
	_t_bloque = 0.0
	_pos_bloque = h.global_position

func _suivre(delta: float) -> bool:
	## Avance sur le chemin ; renvoie vrai à l'arrivée.
	if _chemin_i >= _chemin.size():
		h.entree = Vector2.ZERO
		return true
	var cible := _chemin[_chemin_i]
	var v := cible - h.global_position
	v.y = 0
	if v.length() < 1.3:
		_chemin_i += 1
		return _chemin_i >= _chemin.size()
	var d := v.normalized()
	h.entree = Vector2(d.x, d.z)
	# coincé contre un obstacle : on recalcule, avec un pas de côté
	_t_bloque += delta
	if _t_bloque > 2.0:
		if h.global_position.distance_to(_pos_bloque) < 1.0:
			h.entree = Vector2(-d.z, d.x) * signf(randf() - 0.5)
			_aller_vers(_chemin[_chemin.size() - 1])
		_t_bloque = 0.0
		_pos_bloque = h.global_position
	return false

func _en_zone_sure() -> bool:
	return ZoneSure.contient(h.global_position)

func _menaces(rayon: float) -> Array:
	## Monstres éveillés (ou hostiles) assez proches pour nous concerner.
	var l: Array = []
	for e in h.ennemis_vivants():
		var d := h.global_position.distance_to(e.global_position)
		if d > (rayon * 2.2 if e is Heros else rayon):
			continue
		if e is Heros or (e.has_method("en_combat") and e.en_combat()):
			l.append(e)
	return l

func _plus_proche(liste: Array) -> Node3D:
	var m: Node3D = null
	var dmin := 1e9
	for e in liste:
		var d := h.global_position.distance_to(e.global_position)
		if d < dmin:
			dmin = d
			m = e
	return m

# ---------------- objectifs ----------------

func _choisir_objectif() -> void:
	var pv := h.pv / h.pv_max
	# blessé sans potion : on rentre souffler au camp sûr le plus proche
	if pv < 0.45 and h.potions == 0:
		var meilleur := Caverne.CAMP
		if h.global_position.distance_to(Caverne.PUITS) < h.global_position.distance_to(Caverne.CAMP):
			meilleur = Caverne.PUITS
		objectif = {"genre": "repos", "pos": meilleur + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))}
		_aller_vers(objectif["pos"])
		etat = "aller"
		return
	# près du joueur : coffres, filons et dépouilles qui traînent attirent l'œil
	if reel:
		var o := _objet_interessant(22.0)
		if o:
			objectif = {"genre": "objet", "noeud": o, "pos": o.global_position}
			_aller_vers(o.global_position)
			etat = "aller"
			return
	# sinon un camp à farmer : peuplé, pas trop loin, pas déjà pris par trois autres
	var camps: Dictionary = scenario._camps
	var choix := ""
	var meilleur_score := -1e9
	for id in camps:
		var c: Dictionary = camps[id]
		var vivants: Array = c["vivants"].filter(func(x): return is_instance_valid(x) and not x.est_mort)
		if vivants.is_empty():
			continue
		var elite := false
		for d in vivants:
			if d.fiche.get("elite", false) or d.fiche.get("boss", false):
				elite = true
		if elite and randf() > 0.12:
			continue
		var dist := h.global_position.distance_to(c["centre"])
		var occupes := 0
		for b in get_tree().get_nodes_in_group("bot_cerveau"):
			if b != self and b.objectif.get("camp", "") == id:
				occupes += 1
		var score := -absf(dist - 35.0) - occupes * 40.0 + randf_range(0, 25)
		if score > meilleur_score:
			meilleur_score = score
			choix = id
	if choix == "":
		objectif = {"genre": "errer", "pos": h.global_position + Vector3(randf_range(-20, 20), 0, randf_range(-20, 20))}
	else:
		objectif = {"genre": "camp", "camp": choix, "pos": camps[choix]["centre"]}
	_aller_vers(objectif["pos"])
	etat = "aller"

func _objet_interessant(rayon: float) -> Node3D:
	var meilleur: Node3D = null
	var dmin := rayon
	for o in get_tree().get_nodes_in_group("interactif"):
		if not o is Node3D or not o.has_method("disponible") or not o.disponible():
			continue
		if o is Pnj or o is Heros or o is RuneDraconique:
			continue
		if o is Filon and h.metier_mine["niveau"] < Filon.TYPES[o.type]["niveau"]:
			continue
		var d := h.global_position.distance_to(o.global_position)
		if d < dmin:
			dmin = d
			meilleur = o
	return meilleur

# ---------------- boucle ----------------

func _physics_process(delta: float) -> void:
	if h == null or not is_instance_valid(h) or h.est_mort:
		return
	_basculer_reel()
	if not reel:
		_simuler(delta)
		return
	_t_etat += delta
	_t_pense -= delta
	_reflexe -= delta
	# AFK de temps en temps (téléphone posé, café…)
	_t_afk -= delta
	if _t_afk <= 0.0 and etat != "combat":
		afk = not afk
		_t_afk = randf_range(12.0, 40.0) if afk else randf_range(70.0, 200.0)
		h.entree = Vector2.ZERO
	if afk:
		h.entree = Vector2.ZERO
		# s'il se fait frapper, il « revient » au bout d'un moment
		if not _menaces(4.0).is_empty() and h.pv < h.pv_max * 0.8:
			_t_afk = minf(_t_afk, 1.5)
		return
	if h.canal_en_cours() != "":
		h.entree = Vector2.ZERO
		return
	# potion
	if h.pv < h.pv_max * prudence and h.cds["p"] <= 0.0 and h.potions > 0 and h.action == "":
		h.lancer("p")
	# fuite : très blessé, plus de potion
	var menaces := _menaces(11.0)
	if h.pv < h.pv_max * 0.25 and h.potions == 0 and not menaces.is_empty() and objectif.get("genre", "") != "repos":
		_choisir_objectif()
		if h.cds["f"] <= 0.0:
			h.lancer("f")
	_pillage(delta)
	var au_contact := menaces.filter(func(x): return x is Heros or h.global_position.distance_to(x.global_position) < 5.0)
	if not menaces.is_empty() and (objectif.get("genre", "") != "repos" or not au_contact.is_empty()):
		etat = "combat"
		_combattre(menaces)
		return
	if etat == "combat":
		etat = "aller"
		_t_pense = 0.0
	# en route
	if _chemin_i < _chemin.size():
		if _suivre(delta):
			_t_pense = 0.0
	elif _t_pense <= 0.0:
		_t_pense = 0.5
		h.entree = Vector2.ZERO
		_arrive()

## Arrivé à l'objectif : on agit, puis on en choisit un autre.
func _arrive() -> void:
	match objectif.get("genre", ""):
		"objet":
			var o = objectif.get("noeud")
			if is_instance_valid(o) and o.disponible():
				var dist_o := h.global_position.distance_to(o.global_position)
				if dist_o < 2.4:
					h.entree = Vector2.ZERO
					h.regarder(h.direction_vers(o.global_position))
					o.interagir(h)
					objectif = {}
					return
				if dist_o < 7.0 and objectif.get("essais", 0) < 6:
					objectif["essais"] = objectif.get("essais", 0) + 1
					var dv := h.direction_vers(o.global_position)
					h.entree = Vector2(dv.x, dv.z)
					return
		"camp":
			# des monstres endormis encore là : on va les chercher
			var c: Dictionary = scenario._camps.get(objectif["camp"], {})
			var vivants: Array = c.get("vivants", []).filter(func(x): return is_instance_valid(x) and not x.est_mort)
			if not vivants.is_empty():
				var e := _plus_proche(vivants)
				if h.global_position.distance_to(e.global_position) > 2.5:
					_aller_vers(e.global_position)
					return
		"attente":
			h.entree = Vector2.ZERO
			return
		"repos":
			if h.pv < h.pv_max * 0.95:
				h.entree = Vector2.ZERO
				if _en_zone_sure():
					h.soigner(h.pv_max * 0.025)
				return
	_choisir_objectif()

# ---------------- combat ----------------

func _danger() -> Dictionary:
	var p := h.global_position
	for e in get_tree().get_nodes_in_group("monstre"):
		if e.est_mort or not e is Draugr or e.etat != "prepare":
			continue
		if e.global_position.distance_to(p) > 16.0:
			continue
		var a: Dictionary = e._attaque
		var reste: float = a["prep"] - e._etat_t
		var dedans := false
		var sortie := Vector3.ZERO
		match a["forme"]:
			"cone":
				dedans = Zones.dans_cone(p, e.global_position, e._dir_attaque, a["rayon"], a["angle"], 0.9)
				var lat := Vector3(-e._dir_attaque.z, 0, e._dir_attaque.x)
				sortie = lat if lat.dot(p - e.global_position) >= 0.0 else -lat
			"ligne":
				dedans = Zones.dans_ligne(p, e.global_position, e._dir_attaque, a["rayon"], a["angle"], 0.9)
				var lat2 := Vector3(-e._dir_attaque.z, 0, e._dir_attaque.x)
				sortie = lat2 if lat2.dot(p - e.global_position) >= 0.0 else -lat2
			"cercle":
				dedans = Zones.dans_cercle(p, e._point_attaque, a["rayon"], 0.9)
				var v: Vector3 = p - e._point_attaque
				v.y = 0
				sortie = v.normalized() if v.length() > 0.2 else Vector3(1, 0, 0)
		var cle := str(e.get_instance_id()) + ":" + str(e.attaques_lancees)
		if not _lectures.has(cle):
			_lectures[cle] = randf() < adresse
		if dedans and _lectures[cle]:
			return {"sortie": sortie, "reste": reste}
	return {}

func _combattre(menaces: Array) -> void:
	var dg := _danger()
	if not dg.is_empty():
		var s: Vector3 = dg["sortie"]
		if dg["reste"] < 0.42 and h.cds["d"] <= 0.0 and h.energie >= 15.0 and h.action == "":
			h.lancer("d", s)
		else:
			h.entree = Vector2(s.x, s.z)
		return
	var e := _plus_proche(menaces)
	if e == null:
		return
	var dist := h.global_position.distance_to(e.global_position)
	var dir := h.direction_vers(e.global_position)
	if h.action == "" and _reflexe <= 0.0:
		_reflexe = randf_range(0.25, 0.6)
		var proches := menaces.filter(func(x): return h.global_position.distance_to(x.global_position) < 5.0)
		if proches.size() >= 3 and h.cds["r"] <= 0.0:
			h.lancer("r")
			return
		if dist > 3.6 and dist < 7.0 and h.cds["w"] <= 0.0 and h.energie >= 15.0 and not _en_zone_sure():
			h.lancer("w", dir)
			return
		if dist < 3.3 and h.cds["q"] <= 0.0 and h.energie >= 10.0 and not _en_zone_sure():
			h.lancer("q", dir)
			return
		if e is Heros and dist > 4.0 and dist < 10.0 and h.cds["e"] <= 0.0 and h.energie >= 35.0:
			h.lancer("e", dir)
			return
	h.entree = Vector2(dir.x, dir.z) if dist > 2.3 else Vector2.ZERO

## Tempérament : un pillard guette le joueur affaibli, loin des zones sûres.
func _pillage(delta: float) -> void:
	_t_pillage -= delta
	if _t_pillage > 0.0:
		return
	_t_pillage = randf_range(6.0, 14.0)
	var j := _joueur()
	if j == null or j.est_mort or h.hostiles.has(j) or not Heros.jcj_actif:
		return
	if _en_zone_sure() or ZoneSure.contient(j.global_position, 4.0):
		return
	var d := h.global_position.distance_to(j.global_position)
	if d > 16.0 or h.pv < h.pv_max * 0.6:
		return
	# plus le joueur est faible ou occupé, plus la tentation est forte
	var tentation := agressivite * (1.0 - j.pv / j.pv_max) * 1.6
	var occupe := 0
	for m in get_tree().get_nodes_in_group("monstre"):
		if not m.est_mort and m.get("cible") == j and m.en_combat():
			occupe += 1
	tentation += agressivite * minf(occupe, 3) * 0.12
	tentation += j.sac.valeur() / 4000.0 * agressivite
	if randf() < tentation:
		h.declarer_hostile(j)
		etat = "combat"

# ---------------- simulation hors champ ----------------

func _basculer_reel() -> void:
	var j := _joueur()
	var voulu := true
	if j != null:
		voulu = h.global_position.distance_to(j.global_position) < DISTANCE_REELLE or h.hostiles.has(j)
	if voulu == reel:
		return
	reel = voulu
	if h.action == "canal":
		h._fin_canal(false)
	h.action = ""
	h.modele.position.y = 0.0
	h.set_physics_process(reel)
	h.modele.visible = reel
	if h.anim:
		if reel:
			h.anim.play()
		else:
			h.anim.pause()
	if h.acolyte_noeud and is_instance_valid(h.acolyte_noeud):
		h.acolyte_noeud.visible = reel
		h.acolyte_noeud.process_mode = Node.PROCESS_MODE_INHERIT if reel else Node.PROCESS_MODE_DISABLED
	h.entree = Vector2.ZERO
	h.velocity = Vector3.ZERO
	if reel:
		h.action = ""
		afk = false
		_aller_vers(objectif.get("pos", h.global_position))

## Une seconde de vie résumée : marche le long du chemin, combats tirés aux dés.
func _simuler(delta: float) -> void:
	_t_simu -= delta
	if _t_simu > 0.0:
		return
	_t_simu = 1.0
	if objectif.is_empty() or _chemin_i >= _chemin.size():
		if objectif.get("genre", "") == "camp":
			_combat_simule()
			return
		if objectif.get("genre", "") == "repos":
			h.soigner(h.pv_max * 0.06)
			if h.pv >= h.pv_max * 0.95:
				objectif = {}
			return
		_choisir_objectif()
		return
	var reste := h.vitesse * 0.85
	while reste > 0.0 and _chemin_i < _chemin.size():
		var cible := _chemin[_chemin_i]
		var v := cible - h.global_position
		v.y = 0
		if v.length() <= reste:
			h.global_position = Vector3(cible.x, h.global_position.y, cible.z)
			reste -= v.length()
			_chemin_i += 1
		else:
			h.global_position += v.normalized() * reste
			h.rotation.y = atan2(v.x, v.z)
			reste = 0.0

func _combat_simule() -> void:
	var c: Dictionary = scenario._camps.get(objectif.get("camp", ""), {})
	var vivants: Array = c.get("vivants", []).filter(func(x): return is_instance_valid(x) and not x.est_mort)
	if vivants.is_empty():
		objectif = {}
		return
	if randf() > 0.4:
		return
	var d: Draugr = vivants[randi() % vivants.size()]
	h.global_position = d.global_position + Vector3(0.6, 0, 0.6)
	var coup: float = h.pv_max * randf_range(0.03, 0.1) * (3.0 if d.fiche.get("elite", false) else 1.0)
	h.pv -= coup
	if h.pv < h.pv_max * prudence and h.potions > 0:
		for o in h.sac.objets:
			if o["id"] == "potion":
				h.sac.retirer(o, 1)
				break
		h.soigner(h.pv_max * 0.3)
	if h.pv <= 0.0:
		h.pv = 1.0
		h.recevoir({"montant": 9999.0, "source": d})
		return
	d.recevoir({"montant": 999999.0, "source": h})
	if h.pv < h.pv_max * 0.35 and h.potions == 0:
		objectif = {}

# ---------------- mort ----------------

func _sur_mort(_e) -> void:
	etat = "mort"
	h.entree = Vector2.ZERO
	if not reel:
		h.modele.visible = false
	if scenario and scenario.has_method("bot_mort") and has_meta("fiche"):
		scenario.bot_mort(self)
