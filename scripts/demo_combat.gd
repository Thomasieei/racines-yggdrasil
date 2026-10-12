extends Node
## Pilote automatique pour filmer le combat : il lit les télégraphes comme un joueur attentif
## (sort de la zone à pied s'il a le temps, esquive sinon) et enchaîne les compétences.

var h: Heros
var cam: Camera3D
var _t := 0.0
var _fin_t := -1.0
var _visee_t := 0.0
var _visee_id := ""
var _visee_dir := Vector3.ZERO
var _reflexe := 0.0
var _lectures := {}
var seulement_eveilles := false   ## sur la carte : ignorer les monstres endormis au loin
var fin_auto := true     ## attaque vue -> lue ou ratée (le pilote n'est pas parfait)

func lancer(heros: Heros, c: Camera3D) -> void:
	h = heros
	cam = c

func _draugrs() -> Array:
	var l := get_tree().get_nodes_in_group("monstre").filter(func(e): return not e.est_mort)
	if seulement_eveilles:
		l = l.filter(func(e): return e.etat not in ["dort", "retour"] and e.global_position.distance_to(h.global_position) < 18.0)
	return l

func _plus_proche(liste: Array) -> Draugr:
	var m: Draugr = null
	var d := 1e9
	for e in liste:
		var l: float = h.global_position.distance_to(e.global_position)
		if l < d:
			d = l
			m = e
	return m

## Si une attaque annoncée va nous toucher : direction de sortie et temps restant.
func _danger() -> Dictionary:
	var p := h.global_position
	for e in _draugrs():
		if e.etat != "prepare":
			continue
		var a: Dictionary = e._attaque
		var reste: float = a["prep"] - e._etat_t
		var marge := 0.9
		var dedans := false
		var sortie := Vector3.ZERO
		match a["forme"]:
			"cone":
				dedans = Zones.dans_cone(p, e.global_position, e._dir_attaque, a["rayon"], a["angle"], marge)
				var lat := Vector3(-e._dir_attaque.z, 0, e._dir_attaque.x)
				sortie = lat if lat.dot(p - e.global_position) >= 0.0 else -lat
				sortie = (sortie + e._dir_attaque * 0.15).normalized()
			"ligne":
				dedans = Zones.dans_ligne(p, e.global_position, e._dir_attaque, a["rayon"], a["angle"], marge)
				var lat2 := Vector3(-e._dir_attaque.z, 0, e._dir_attaque.x)
				sortie = lat2 if lat2.dot(p - e.global_position) >= 0.0 else -lat2
			"cercle":
				dedans = Zones.dans_cercle(p, e._point_attaque, a["rayon"], marge)
				var v: Vector3 = p - e._point_attaque
				v.y = 0
				sortie = v.normalized() if v.length() > 0.2 else Vector3(1, 0, 0)
		var cle := str(e.get_instance_id()) + ":" + str(e.attaques_lancees)
		if not _lectures.has(cle):
			_lectures[cle] = randf() > 0.3
		if dedans and _lectures[cle]:
			return {"sortie": sortie, "reste": reste}
	return {}

func _physics_process(delta: float) -> void:
	if h == null:
		return
	_t += delta
	if h.est_mort:
		_finir(3.0)
		return
	var vivants := _draugrs()
	if vivants.is_empty():
		h.entree = Vector2.ZERO
		if _fin_t < 0.0:
			h.jouer("Cheer", 0.2, 1.0, 2.0)
		_finir(3.2)
		return
	if _t > 48.0:
		_finir(0.1)
		return

	# visée en cours (montrée à l'écran avant de lâcher)
	if _visee_id != "":
		_visee_t -= delta
		var cible := _plus_proche(vivants)
		if cible:
			_visee_dir = h.direction_vers(cible.global_position)
		h.montrer_visee(_visee_id, _visee_dir)
		h.entree = Vector2.ZERO
		if _visee_t <= 0.0:
			h.cacher_visee()
			h.lancer(_visee_id, _visee_dir)
			_visee_id = ""
		return

	# 1) lire le sol
	var dg := _danger()
	_reflexe -= delta
	if not dg.is_empty():
		var s: Vector3 = dg["sortie"]
		if dg["reste"] < 0.42 and h.cds["d"] <= 0.0 and h.energie >= 15.0 and h.action == "":
			h.lancer("d", s)
		else:
			h.entree = Vector2(s.x, s.z)
		return

	var e := _plus_proche(vivants)
	var dist := h.global_position.distance_to(e.global_position)
	var eveilles := vivants.filter(func(x): return x.etat != "dort")
	var proches := eveilles.filter(func(x): return h.global_position.distance_to(x.global_position) < 5.0)

	# 2) compétences
	if h.action == "" and _reflexe <= 0.0:
		if h.pv < h.pv_max * 0.5 and h.cds["p"] <= 0.0 and h.potions > 0:
			_appui("p")
			return
		var en_prepa := eveilles.filter(func(x): return x.etat == "prepare" and h.global_position.distance_to(x.global_position) < 9.0)
		if en_prepa.size() >= 2 and h.cds["r"] <= 0.0:
			_appui("r")
			return
		# ruée runique sur le guerrier qui prépare : on l'interrompt par l'étourdissement
		for x in eveilles:
			if x.type == "guerrier" and x.etat in ["prepare", "recup", "poursuite"] and h.cds["e"] <= 0.0 and h.energie >= 35.0:
				var dx := h.global_position.distance_to(x.global_position)
				if dx > 3.0 and dx < 10.5:
					_visee_id = "e"
					_visee_t = 0.45
					_visee_dir = h.direction_vers(x.global_position)
					return
		if dist > 3.6 and dist < 7.0 and e.etat != "dort" and h.cds["w"] <= 0.0 and h.energie >= 15.0:
			_appui("w", h.direction_vers(e.global_position))
			return
		if dist < 3.3 and h.cds["q"] <= 0.0 and h.energie >= 10.0:
			_appui("q", h.direction_vers(e.global_position))
			return
		var loin := eveilles.filter(func(x): return x.fiche["garde"] > 0.0 and h.global_position.distance_to(x.global_position) > 7.0)
		if proches.is_empty() and not loin.is_empty() and h.cds["f"] <= 0.0:
			_appui("f")
			return

	# 3) se placer
	var voulu := Vector3.ZERO
	if dist > 2.3:
		voulu = h.direction_vers(e.global_position)
	h.entree = Vector2(voulu.x, voulu.z)

func _appui(id: String, dir = null) -> void:
	h.lancer(id, dir)
	_reflexe = randf_range(0.15, 0.35)   # un humain ne lance pas tout dans la même image

func _finir(attente: float) -> void:
	if not fin_auto:
		return
	if _fin_t < 0.0:
		_fin_t = _t
	if _t - _fin_t > attente:
		get_tree().quit()
