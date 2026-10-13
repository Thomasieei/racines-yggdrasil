class_name Draugr
extends EntiteCombat
## Draugr (squelettes KayKit) : réveil, poursuite, attaques télégraphiées, temps de récupération punissable.
##
## Contrat de lisibilité : toute attaque qui fait mal s'annonce au sol en rouge, dans sa forme exacte,
## et la direction est figée au début de la préparation. Le joueur qui lit le sol ne se fait jamais toucher.

const P := "res://assets/personnages/"

## Fiches des types. Les durées de préparation sont volontairement longues (combat lent, lisible).
const TYPES := {
	"minion": {
		"nom": "Draugr rampant", "modele": "squelette_minion.glb", "arme_d": "skeleton_blade.glb", "arme_g": "",
		"pv": 160.0, "vitesse": 3.6, "echelle": 0.92, "portee": 1.9, "garde": 0.0, "armure": false, "enterre": true,
		"attaques": [
			{"id": "taille", "forme": "cone", "rayon": 2.3, "angle": 0.85, "prep": 0.75, "degats": 70.0,
			 "anim": "1H_Melee_Attack_Chop", "impact_anim": 0.42, "recup": 0.7, "cd": 1.6, "son": "coup_os"},
		],
	},
	"guerrier": {
		"nom": "Draugr guerrier", "modele": "squelette_warrior.glb", "arme_d": "skeleton_axe.glb", "arme_g": "skeleton_shield_large_a.glb",
		"pv": 520.0, "vitesse": 2.9, "echelle": 1.08, "portee": 2.4, "garde": 0.0, "armure": true,
		"attaques": [
			{"id": "fendre", "forme": "cone", "rayon": 3.0, "angle": 0.95, "prep": 0.95, "degats": 180.0,
			 "anim": "2H_Melee_Attack_Chop", "impact_anim": 0.62, "recup": 0.9, "cd": 2.2, "son": "coup_lourd"},
			{"id": "saut", "forme": "cercle", "rayon": 2.8, "angle": 0.0, "prep": 1.15, "degats": 240.0,
			 "anim": "1H_Melee_Attack_Jump_Chop", "impact_anim": 0.72, "recup": 1.3, "cd": 9.0, "son": "atterrissage",
			 "portee_min": 3.5, "portee_max": 8.0, "bond": true, "etourdir": 0.6},
		],
	},
	"arbaletrier": {
		"nom": "Draugr arbalétrier", "modele": "squelette_rogue.glb", "arme_d": "skeleton_crossbow.glb", "arme_g": "",
		"pv": 220.0, "vitesse": 3.1, "echelle": 1.0, "portee": 11.0, "garde": 6.5, "armure": false,
		"attaques": [
			{"id": "carreau", "forme": "ligne", "rayon": 14.0, "angle": 0.9, "prep": 1.05, "degats": 150.0,
			 "anim": "1H_Ranged_Shoot", "impact_anim": 0.45, "recup": 0.8, "cd": 3.2, "son": "metal", "projectile": true},
		],
	},
	"jarl": {
		"nom": "Jarl Hrafnkel", "modele": "squelette_warrior.glb", "arme_d": "skeleton_axe.glb", "arme_g": "skeleton_shield_large_a.glb",
		"pv": 1900.0, "vitesse": 3.1, "echelle": 1.5, "portee": 3.2, "garde": 0.0, "armure": true, "elite": true,
		"attaques": [
			{"id": "fendre", "forme": "cone", "rayon": 4.0, "angle": 1.0, "prep": 1.05, "degats": 260.0,
			 "anim": "2H_Melee_Attack_Chop", "impact_anim": 0.62, "recup": 0.9, "cd": 2.4, "son": "coup_lourd"},
			{"id": "tourbillon", "forme": "cercle", "rayon": 4.6, "angle": 0.0, "prep": 1.4, "degats": 300.0,
			 "anim": "2H_Melee_Attack_Spin", "impact_anim": 0.9, "recup": 1.4, "cd": 8.0, "son": "coup_lourd",
			 "sur_soi": true, "portee_min": 0.0, "portee_max": 4.5},
			{"id": "saut", "forme": "cercle", "rayon": 3.4, "angle": 0.0, "prep": 1.2, "degats": 280.0,
			 "anim": "1H_Melee_Attack_Jump_Chop", "impact_anim": 0.72, "recup": 1.3, "cd": 10.0, "son": "atterrissage",
			 "portee_min": 5.0, "portee_max": 10.0, "bond": true, "etourdir": 0.8},
		],
	},
	"mage": {
		"nom": "Draugr nécromant", "modele": "squelette_mage.glb", "arme_d": "skeleton_staff.glb", "arme_g": "",
		"pv": 240.0, "vitesse": 2.7, "echelle": 1.0, "portee": 10.0, "garde": 6.0, "armure": false,
		"attaques": [
			{"id": "gel", "forme": "cercle", "rayon": 2.4, "angle": 0.0, "prep": 1.35, "degats": 200.0,
			 "anim": "Spellcast_Shoot", "impact_anim": 0.42, "recup": 1.0, "cd": 4.2, "son": "verre_lourd",
			 "sur_cible": true, "ralentir": 2.0},
		],
	},
}

signal reveille(d: Draugr)

var type := "minion"
var fiche: Dictionary
var etat := "dort"          ## dort, eveil, poursuite, prepare, frappe, recup
var cible: EntiteCombat
var aggro_rayon := 9.0
var _etat_t := 0.0
var _attaque: Dictionary = {}
var _dir_attaque := Vector3.FORWARD
var _point_attaque := Vector3.ZERO
var _tele: Telegraphe
var _cds := {}
var _flottement := 0.0       ## petit décalage latéral pour que la meute encercle au lieu de s'empiler
var _base_vitesse_anim := 1.0
var _hit_t := 0.0
var attaques_lancees := 0
var _foyer := Vector3.ZERO

func configurer(t: String) -> void:
	type = t
	fiche = TYPES[t]

func _ready() -> void:
	if fiche.is_empty():
		fiche = TYPES[type]
	camp = "monstre"
	pv_max = fiche["pv"]
	vitesse = fiche["vitesse"]
	rayon = 0.55 * fiche["echelle"]
	hauteur_barre = 2.5 * fiche["echelle"]
	super._ready()
	collision_layer = 2
	collision_mask = 1
	installer_modele(load(P + fiche["modele"]), fiche["echelle"])
	_armer("handslot.r", fiche["arme_d"])
	_armer("handslot.l", fiche["arme_g"])
	var f := CollisionShape3D.new()
	var c := CapsuleShape3D.new()
	c.radius = 0.4 * fiche["echelle"]
	c.height = 1.7 * fiche["echelle"]
	f.shape = c
	f.position.y = c.height * 0.5
	add_child(f)
	for a in fiche["attaques"]:
		_cds[a["id"]] = randf_range(0.2, 0.8)
	_flottement = randf_range(-1.0, 1.0)
	_foyer = global_position
	if fiche.get("enterre", false):
		# les rampants dorment sous terre : ils surgiront quand la meute s'éveille
		jouer("Spawn_Ground_Skeletons", 0.0, 0.0)
		if anim:
			anim.seek(0.0, true)
			anim.pause()
		modele.visible = false
	else:
		# les autres montent la garde, figés, presque immobiles : on les voit de loin
		jouer("Idle_Combat", 0.0, 0.35)

func _armer(os: String, glb: String) -> void:
	if glb == "":
		return
	var sq := modele.find_child("Skeleton3D", true, false) as Skeleton3D
	if sq == null:
		return
	var nom_os := os
	if sq.find_bone(nom_os) < 0:
		nom_os = os.replace(".", "_")
	if sq.find_bone(nom_os) < 0:
		return
	var at := BoneAttachment3D.new()
	at.bone_name = nom_os
	sq.add_child(at)
	var arme: Node3D = load(P + glb).instantiate()
	at.add_child(arme)
	for m in arme.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).material_overlay = _mat_flash
		_meshes.append(m)

func nom_affiche() -> String:
	return fiche["nom"]

func est_eveille() -> bool:
	return etat != "dort" and etat != "eveil" and not est_mort

func en_combat() -> bool:
	return etat != "dort" and not est_mort

# ---------------- réveil et aggro ----------------

func reveiller(c: EntiteCombat) -> void:
	if etat != "dort" or est_mort:
		return
	cible = c
	etat = "eveil"
	_etat_t = 0.0
	regarder(direction_vers(c.global_position))
	if not modele.visible:
		modele.visible = true
		jouer("Spawn_Ground_Skeletons", 0.0, 2.2, 1.7)
		Effets.poussiere(get_parent(), global_position, 10, Color(0.55, 0.5, 0.45, 0.6))
		Sons.jouer("coup_os", global_position, -10.0, 0.7)
	else:
		jouer("Taunt", 0.15, 1.4, 0.8)
		_etat_t = 0.85   # le cri est plus court que la sortie de terre
		Sons.jouer("metal", global_position, -12.0, 0.6)
	reveille.emit(self)

## Le héros entre dans le rayon, ou un allié proche s'éveille, ou on se fait frapper.
func _verifier_aggro() -> void:
	for h in get_tree().get_nodes_in_group("joueur"):
		if not h.est_mort and global_position.distance_to(h.global_position) < aggro_rayon and not ZoneSure.contient(h.global_position):
			reveiller(h)
			return

# ---------------- attaques ----------------

func _choisir_attaque(dist: float) -> Dictionary:
	var meilleure := {}
	for a in fiche["attaques"]:
		if _cds[a["id"]] > 0.0:
			continue
		if a.has("portee_min") and (dist < a["portee_min"] or dist > a["portee_max"]):
			continue
		if not a.has("portee_min") and dist > fiche["portee"]:
			continue
		# les attaques spéciales (à portée) passent avant l'attaque de base
		if meilleure.is_empty() or a.has("portee_min"):
			meilleure = a
	return meilleure

func _preparer(a: Dictionary) -> void:
	_attaque = a
	attaques_lancees += 1
	etat = "prepare"
	_etat_t = 0.0
	velocity = Vector3.ZERO
	_dir_attaque = direction_vers(cible.global_position)
	regarder(_dir_attaque)
	var couleur := Color(1.0, 0.16, 0.1)
	match a["forme"]:
		"cone":
			_point_attaque = global_position
			_tele = Telegraphe.creer(get_parent(), Telegraphe.Forme.CONE, global_position, _dir_attaque, a["rayon"], a["angle"], a["prep"], couleur)
		"ligne":
			_point_attaque = global_position
			_tele = Telegraphe.creer(get_parent(), Telegraphe.Forme.LIGNE, global_position + _dir_attaque * 0.5, _dir_attaque, a["rayon"], a["angle"], a["prep"], couleur)
		"cercle":
			if a.get("sur_soi", false):
				_point_attaque = global_position
			elif a.get("sur_cible", false):
				_point_attaque = cible.global_position
			else:
				# saut : point d'arrivée devant la cible, figé
				var d := global_position.distance_to(cible.global_position)
				var libre := Zones.distance_libre(get_world_3d(), global_position, _dir_attaque, d, [get_rid()])
				_point_attaque = global_position + _dir_attaque * maxf(0.0, minf(libre, d - 0.6))
			_tele = Telegraphe.creer(get_parent(), Telegraphe.Forme.CERCLE, _point_attaque, Vector3.ZERO, a["rayon"], 0.0, a["prep"], couleur)
	# l'animation est ralentie pour que le coup tombe pile à la fin du télégraphe
	var lente: float = a["impact_anim"] / a["prep"]
	jouer(a["anim"], 0.12, lente, a["prep"] + 0.2)
	_base_vitesse_anim = lente
	if a.get("bond", false):
		Sons.jouer("tissu", global_position, -2.0, 0.8)
	elif a.has("sur_cible") or a["forme"] == "ligne":
		Sons.jouer("activation", global_position, -8.0, 0.7)
	else:
		Sons.jouer("elan", global_position, -6.0, 0.8)

func _impact() -> void:
	var a := _attaque
	etat = "frappe"
	_etat_t = 0.0
	if anim:
		anim.play(a["anim"], 0.0, 1.0)
		anim.seek(a["impact_anim"], true)
	if is_instance_valid(_tele):
		_tele.terminer()
	_tele = null
	_cds[a["id"]] = a["cd"]
	var degats := {"montant": a["degats"], "source": self, "ralentir": a.get("ralentir", 0.0), "etourdir": a.get("etourdir", 0.0), "lourd": a["degats"] >= 180.0}
	match a["forme"]:
		"cone":
			Effets.taille(get_parent(), global_position, _dir_attaque, a["rayon"], Color(1.0, 0.35, 0.25, 0.9), "slash_02.png", 0.2, -0.8)
			if _cible_touchable() and Zones.dans_cone(cible.global_position, global_position, _dir_attaque, a["rayon"], a["angle"], cible.rayon):
				cible.recevoir(degats)
				Sons.jouer(a["son"], cible.global_position, 0.0)
			else:
				Sons.jouer("taille", global_position, -6.0, 0.8)
		"cercle":
			if a.get("bond", false):
				global_position = Vector3(_point_attaque.x, global_position.y, _point_attaque.z)
				Effets.onde(get_parent(), _point_attaque, a["rayon"], Color(1.0, 0.35, 0.2))
				Effets.poussiere(get_parent(), _point_attaque, 14)
			elif a.get("sur_soi", false):
				Effets.onde(get_parent(), _point_attaque, a["rayon"], Color(1.0, 0.4, 0.2), 0.5)
				Effets.taille(get_parent(), global_position, _dir_attaque, a["rayon"], Color(1.0, 0.45, 0.3, 0.9), "slash_02.png", 0.3, -3.0)
				Effets.poussiere(get_parent(), _point_attaque, 10)
			else:
				_explosion_givre(_point_attaque, a["rayon"])
			Sons.jouer(a["son"], _point_attaque, 0.0)
			if _cible_touchable() and Zones.dans_cercle(cible.global_position, _point_attaque, a["rayon"], cible.rayon):
				cible.recevoir(degats)
		"ligne":
			_tirer_carreau(degats, a["rayon"])
			Sons.jouer("elan", global_position, -2.0, 1.4)

func _cible_touchable() -> bool:
	return is_instance_valid(cible) and not cible.est_mort

func _explosion_givre(ou: Vector3, r: float) -> void:
	var c := Color(0.55, 1.0, 0.75)
	Effets.onde(get_parent(), ou, r, c, 0.5)
	Effets.etincelles(get_parent(), ou + Vector3(0, 0.2, 0), Vector3.UP, c, 26, 7.0, "magic_03.png", 0.5)
	Effets.flash_lumiere(get_parent(), ou, c, 4.0, 7.0, 0.3)

## Carreau d'arbalète : un projectile visible qui suit la ligne annoncée. L'esquive passe à travers.
func _tirer_carreau(degats: Dictionary, longueur: float) -> void:
	var c := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.08, 0.08, 0.9)
	c.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.55, 0.35)
	c.material_override = mat
	get_parent().add_child(c)
	var depart := global_position + _dir_attaque * 0.8 + Vector3(0, 1.2, 0)
	c.global_position = depart
	c.global_rotation.y = atan2(_dir_attaque.x, _dir_attaque.z)
	var trace := Effets.trainee_lumineuse(c, Color(1.0, 0.45, 0.3))
	var dir := _dir_attaque
	var parcouru := 0.0
	var vitesse_p := 30.0
	var libre := Zones.distance_libre(get_world_3d(), global_position, dir, longueur, [get_rid()]) + 0.7
	while parcouru < libre and is_instance_valid(c):
		await get_tree().physics_frame
		var pas := vitesse_p * get_physics_process_delta_time()
		parcouru += pas
		c.global_position = depart + dir * parcouru
		if _cible_touchable() and Zones.dans_cercle(cible.global_position, c.global_position, 0.45, cible.rayon):
			if cible.invulnerable_t <= 0.0:
				cible.recevoir(degats)
				Sons.jouer("metal", cible.global_position, -2.0)
				break
	if is_instance_valid(c):
		Effets.etincelles(get_parent(), c.global_position, -dir, Color(1.0, 0.6, 0.4), 8, 3.0)
		if trace:
			trace.emitting = false
		c.visible = false
		get_tree().create_timer(0.6).timeout.connect(c.queue_free)

# ---------------- réactions ----------------

func interrompre() -> void:
	if etat == "prepare":
		if is_instance_valid(_tele):
			_tele.terminer(true)
		_tele = null
		if not _attaque.is_empty():
			_cds[_attaque["id"]] = _attaque["cd"] * 0.5
		etat = "recup"
		_etat_t = 0.0
		_attaque = {}
		if anim:
			anim.speed_scale = 1.0

func recevoir(d: Dictionary) -> void:
	if etat == "dort":
		var s = d.get("source", null)
		if s:
			reveiller(s)
	super.recevoir(d)

func _reaction_coup(d: Dictionary) -> void:
	if etat == "dort" or etat == "eveil":
		return
	# les guerriers en armure ne bronchent pas pendant leur préparation : il faut les étourdir
	if etat == "prepare":
		if not fiche["armure"] and d.get("lourd", false):
			interrompre()
		else:
			return
	if etat in ["poursuite", "recup"] and _hit_t <= 0.0:
		_hit_t = 0.5
		jouer("Hit_A", 0.04, 1.6, 0.25)
		if not fiche["armure"]:
			velocity *= 0.2

func _mourir() -> void:
	if is_instance_valid(_tele):
		_tele.terminer(true)
	_tele = null
	super._mourir()
	if anim:
		anim.speed_scale = 1.0
	jouer("Death_C_Skeletons", 0.08, 1.0, 99.0)
	Sons.jouer("coup_os", global_position, 0.0, 0.6)
	Effets.etincelles(get_parent(), global_position + Vector3(0, 1.0, 0), Vector3.UP, Color(0.85, 0.95, 1.0), 16, 3.5, "magic_02.png", 0.35)
	for e in get_children():
		if e is CollisionShape3D:
			e.disabled = true
	await get_tree().create_timer(2.6).timeout
	var tw := create_tween()
	tw.tween_property(modele, "position:y", -1.6, 1.4).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)

# ---------------- boucle ----------------

func _physics_process(delta: float) -> void:
	_process_etats(delta)
	_hit_t = maxf(0.0, _hit_t - delta)
	for k in _cds:
		_cds[k] = maxf(0.0, _cds[k] - delta)
	if est_mort:
		return
	_etat_t += delta
	if etourdi_t > 0.0:
		if anim and anim.speed_scale != 1.0:
			anim.speed_scale = 1.0
		velocity = velocity.move_toward(Vector3.ZERO, 25.0 * delta)
		if verrou_anim <= 0.0:
			jouer("Hit_A", 0.1, 0.35)
		appliquer_physique(delta)
		return
	match etat:
		"dort":
			_verifier_aggro()
			return
		"eveil":
			if _etat_t >= 1.6:
				etat = "poursuite"
				_alerter_meute()
			return
		"prepare":
			velocity = velocity.move_toward(Vector3.ZERO, 30.0 * delta)
			appliquer_physique(delta)
			if _etat_t >= _attaque["prep"]:
				_impact()
			return
		"frappe":
			velocity = Vector3.ZERO
			if _etat_t >= 0.25:
				etat = "recup"
				_etat_t = 0.0
			return
		"recup":
			velocity = velocity.move_toward(Vector3.ZERO, 30.0 * delta)
			appliquer_physique(delta)
			var duree: float = _attaque.get("recup", 0.6)
			if _etat_t >= duree:
				etat = "poursuite"
				_attaque = {}
			if verrou_anim <= 0.0:
				jouer("Idle_Combat", 0.2)
			return
		"poursuite":
			_poursuivre(delta)
		"retour":
			_retourner(delta)

## La cible s'est réfugiée en zone sûre : on rentre au foyer et on se refait une santé.
func _retourner(delta: float) -> void:
	var v := _foyer - global_position
	v.y = 0
	soigner(pv_max * 0.25 * delta)
	if v.length() < 0.8:
		etat = "dort"
		cible = null
		velocity = Vector3.ZERO
		jouer("Idle_Combat", 0.3, 0.35)
		return
	var h := v.normalized() * vitesse
	velocity.x = h.x
	velocity.z = h.z
	appliquer_physique(delta)
	regarder(h, delta)
	if verrou_anim <= 0.0:
		jouer("Walking_D_Skeletons", 0.2, 1.0)

func _alerter_meute() -> void:
	for a in get_tree().get_nodes_in_group("monstre"):
		if a != self and a is Draugr and a.etat == "dort" and a.global_position.distance_to(global_position) < 8.0:
			a.reveiller(cible)

func _poursuivre(delta: float) -> void:
	if not _cible_touchable():
		velocity = Vector3.ZERO
		jouer("Idle_Combat", 0.2)
		appliquer_physique(delta)
		return
	if ZoneSure.contient(cible.global_position, 3.0):
		etat = "retour"
		return
	var vers := cible.global_position - global_position
	vers.y = 0
	var dist := vers.length()
	var dir := vers / maxf(dist, 0.001)
	var a := _choisir_attaque(dist)
	if not a.is_empty():
		_preparer(a)
		return
	var voulu := Vector3.ZERO
	var garde: float = fiche["garde"]
	if garde > 0.0:
		# tireurs : gardent leurs distances, reculent si on les colle, contournent un peu
		if dist > fiche["portee"] - 1.0:
			voulu = dir
		elif dist < garde:
			# recule, mais jamais dos au mur : il glisse alors sur le côté
			var dos := Zones.distance_libre(get_world_3d(), global_position, -dir, 2.0, [get_rid()])
			voulu = -dir if dos > 1.2 else Vector3(-dir.z, 0, dir.x) * signf(_flottement + 0.01)
		voulu += Vector3(-dir.z, 0, dir.x) * _flottement * 0.35
	else:
		if dist > fiche["portee"] * 0.85:
			voulu = dir + Vector3(-dir.z, 0, dir.x) * _flottement * 0.25 * clampf(dist / 6.0, 0.0, 1.0)
	voulu += _separation() * 1.2
	if voulu.length() > 1.0:
		voulu = voulu.normalized()
	var v := voulu * vitesse * facteur_vitesse()
	var h := Vector3(velocity.x, 0, velocity.z).move_toward(v, 20.0 * delta)
	velocity.x = h.x
	velocity.z = h.z
	appliquer_physique(delta)
	regarder(dir if dist < 6.0 or h.length() < 0.3 else h, delta)
	if verrou_anim <= 0.0:
		if h.length() > 0.4:
			var marche := h.length() < 3.2
			jouer("Walking_D_Skeletons" if marche else "Running_A", 0.15, clampf(h.length() / (1.6 if marche else 4.0), 0.6, 1.4))
		else:
			jouer("Idle_Combat", 0.2)

## Évite que la meute s'empile : poussée douce loin des voisins et du héros.
func _separation() -> Vector3:
	var s := Vector3.ZERO
	for o in get_tree().get_nodes_in_group("combattants"):
		if o == self or o.est_mort:
			continue
		var d: Vector3 = global_position - o.global_position
		d.y = 0
		var l := d.length()
		var mini: float = rayon + o.rayon + 0.35
		if l < mini and l > 0.001:
			s += d / l * (mini - l) / mini
	return s
