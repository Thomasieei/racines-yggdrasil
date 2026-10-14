class_name Heros
extends EntiteCombat
## Le héros barbare et sa hache à deux mains : déplacement, attaque automatique, 5 compétences, potion, esquive.

signal energie_change(e: float, e_max: float)
signal refus(id: String, raison: String)
signal mana_change(m: float, m_max: float)
var mana := 100.0
var mana_max := 100.0

const MODELE := "res://assets/personnages/barbare.glb"
const CACHES := ["1H_Axe_Offhand", "Barbarian_Round_Shield", "Mug", "1H_Axe"]
const CHEVALIER := "res://assets/personnages/chevalier.glb"
const CACHES_CHEVALIER := ["1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Round_Shield", "Spike_Shield", "1H_Sword"]

## Dans le donjon, le joueur peut frapper les autres aventuriers hors des zones sûres (JcJ ouvert).
static var jcj_actif := false

## Fiche des compétences (lue aussi par le HUD et les fiches d'objet).
const COMPETENCES := {
	"q": {"nom": "Fendoir", "cd": 4.0, "cout": 10.0, "visee": "direction"},
	"w": {"nom": "Bond du berserker", "cd": 8.0, "cout": 15.0, "visee": "direction"},
	"e": {"nom": "Ruée runique", "cd": 26.0, "cout": 35.0, "visee": "direction"},
	"r": {"nom": "Bulle de Freya", "cd": 16.0, "cout": 0.0, "visee": "aucune"},
	"f": {"nom": "Pas du vent", "cd": 12.0, "cout": 0.0, "visee": "aucune"},
	"p": {"nom": "Potion de soin", "cd": 10.0, "cout": 0.0, "visee": "aucune"},
	"d": {"nom": "Esquive", "cd": 1.5, "cout": 15.0, "visee": "direction"},
}

@export var energie_max := 100.0
@export var regen_energie := 8.0
@export var degats_arme := 3.0          ## multiplicateur (niveau de l'arme : Hache du Jarl IV)

var entree := Vector2.ZERO              ## joystick, x = est, y = sud
var energie := 100.0
var sac := Sac.new()
var potions: int:
	get: return sac.compter("potion")
var sac_neuf := true                    ## faux quand le sac vient de la carte précédente
var classe := ""                        ## voie de classe (le titre donne les compétences, pas l'arme)
static var en_epreuve := false          ## épreuve draconique : ni arme, ni reliques, ni talents
var ia := false                         ## joueur piloté par l'IA (bots) : ignore le clavier
var nom_joueur := "Thomas"
var hostiles: Array = []                ## héros que l'on combat (JcJ) : attaqués ou agresseurs
var dernier_agresseur: Node = null
var tueur: Node = null
var classe_modele := MODELE
var _canal := {}
var metier_mine := {"niveau": 1, "xp": 0}
var niveau := 12
var xp := 0
var acolyte_noeud: Node3D

## Équipe un dragon du sac (l'ancien retourne dans le sac).
func equiper_dragon(d: Dictionary) -> void:
	if not sac.acolyte.is_empty():
		sac.objets.append(sac.acolyte)
	sac.objets.erase(d)
	sac.acolyte = d
	sac.change.emit()
	if acolyte_noeud and is_instance_valid(acolyte_noeud):
		acolyte_noeud.queue_free()
	acolyte_noeud = Acolyte.invoquer(self, d)

func desequiper_dragon() -> void:
	if sac.acolyte.is_empty():
		return
	if sac.ajouter(sac.acolyte):
		sac.acolyte = {}
		sac.change.emit()
		if acolyte_noeud and is_instance_valid(acolyte_noeud):
			acolyte_noeud.queue_free()

func equiper_arme(a: Dictionary) -> void:
	if a.get("classe", "") != classe:
		return
	sac.objets.erase(a)
	if not sac.arme.is_empty():
		sac.objets.append(sac.arme)
	sac.arme = a
	sac.change.emit()

func xp_acolyte(n: int) -> void:
	var d: Dictionary = sac.acolyte
	if d.is_empty():
		return
	d["xp"] = d.get("xp", 0) + n
	var monte := false
	while d["xp"] >= Objets.xp_niveau(d["niveau"]):
		d["xp"] -= Objets.xp_niveau(d["niveau"])
		d["niveau"] += 1
		monte = true
	if monte:
		if acolyte_noeud and is_instance_valid(acolyte_noeud):
			acolyte_noeud.grandir()
		if self == Jeu.joueur:
			Jeu.notifier("%s passe niveau %d !" % [d["nom"], d["niveau"]], Objets.COULEURS[d["rarete"]])

func gagner_xp_mine(n: int) -> void:
	n = int(round(n * (1.0 + stat("fortune"))))
	metier_mine["xp"] += n
	var besoin: int = 40 + metier_mine["niveau"] * 30
	if self == Jeu.joueur:
		Jeu.notifier("+%d XP Mineur" % n, Color("#C9B7FF"))
	while metier_mine["xp"] >= besoin:
		metier_mine["xp"] -= besoin
		metier_mine["niveau"] += 1
		besoin = 40 + metier_mine["niveau"] * 30
		if self == Jeu.joueur:
			Jeu.notifier("Mineur niveau %d !" % metier_mine["niveau"], Color("#FFD34E"))
			Effets.onde(_scene(), global_position, 3.0, Color(0.8, 0.7, 1.0))
			Sons.jouer("pret", global_position, 0.0, 1.0)
signal canal_fini(nom: String, reussi: bool)
var cds := {}
var action := ""                        ## "", "saut", "incantation", "ruee", "esquive"
var _action_t := 0.0
var _action := {}
var _attaque_t := 0.0
var _vent_t := 0.0
var _soin_t := 0.0
var _vent_particules: CPUParticles3D
var _visee: Telegraphe
var _pas_t := 0.0

func _ready() -> void:
	camp = "joueur"
	pv_max = PV_BASE
	vitesse = 6.0
	super._ready()
	collision_layer = 4     # les monstres ne se bloquent pas sur le héros : séparation douce gérée par eux
	collision_mask = 1
	installer_modele(load(classe_modele), 1.0, CACHES_CHEVALIER if classe_modele == CHEVALIER else CACHES)
	if sac_neuf:
		sac.ajouter(Objets.creer("potion", "commun", 3))
	sac.change.connect(_maj_arme)
	sac.change.connect(_maj_stats)
	if not ia:
		classe = Profil.p().classe
		Profil.p().change.connect(_maj_stats)
	_armes_visibles()
	_maj_arme()
	_maj_stats()
	for id in COMPETENCES:
		cds[id] = 0.0
	var f := CollisionShape3D.new()
	var c := CapsuleShape3D.new()
	c.radius = 0.45
	c.height = 1.8
	f.shape = c
	f.position.y = 0.9
	add_child(f)
	bulle = Node3D.new()
	bulle.set_script(load("res://scripts/competences/bulle_freya.gd"))
	add_child(bulle)
	jouer("2H_Melee_Idle")

# ---------------- utilitaires ----------------

func ennemis_vivants() -> Array:
	var l := get_tree().get_nodes_in_group("monstre").filter(func(e): return not e.est_mort)
	for h in hostiles:
		if is_instance_valid(h) and not h.est_mort:
			l.append(h)
	return l

## Rend deux héros ennemis (JcJ). Jamais en zone sûre.
func declarer_hostile(autre: Node, riposte := false) -> void:
	if autre == self or not autre is Heros or autre.est_mort:
		return
	if not hostiles.has(autre) and autre == Jeu.joueur and ia:
		if riposte:
			Jeu.notifier("%s riposte !" % nom_joueur, Color("#FFB37A"))
		else:
			Jeu.notifier("%s t'attaque !" % nom_joueur, Color("#FF6A5A"))
	if not hostiles.has(autre):
		hostiles.append(autre)
	if not autre.hostiles.has(self):
		autre.hostiles.append(self)

## Ce que les sorts touchent : les monstres et les aventuriers déclarés hostiles. Jamais un
## aventurier neutre par accident : pour l'attaquer il faut le défier (bouton « Attaquer »).
func cibles_touchables() -> Array:
	return ennemis_vivants()

# ---------------- défi JcJ (le joueur s'approche d'un aventurier IA) ----------------

var rayon_action := 3.5
const MULT_JCJ := 3.0                   ## entre aventuriers les coups portent plus : un duel dure ~20 s, pas une minute

func texte_action() -> String:
	return "Attaquer"

func disponible() -> bool:
	var j = Jeu.joueur
	return ia and jcj_actif and not est_mort and j != null and is_instance_valid(j) and not hostiles.has(j) \
		and not ZoneSure.contient(global_position) and not ZoneSure.contient(j.global_position)

func interagir(h: Heros) -> void:
	h.declarer_hostile(self)
	Jeu.notifier("Tu attaques %s : le vainqueur prend le sac." % nom_joueur, Color("#FFB37A"))

# ---------------- statistiques (talents + reliques) ----------------

const PV_BASE := 2400.0
const ENERGIE_BASE := 100.0
var _t_sans_coup := 99.0
var _rempart_t := 0.0

## Bonus total d'une statistique : reliques portées, plus l'Arbre des Racines pour le joueur.
func stat(nom: String) -> float:
	var v: float = Classes.fiche(classe)["stats"].get(nom, 0.0)
	if en_epreuve and not ia:
		return v
	v += sac.bonus_relique(nom)
	if not ia:
		v += Profil.p().stat(nom)
	return v

## Fiche d'une compétence pour l'emplacement `id`, selon la classe.
func competence(id: String) -> Dictionary:
	var c: Dictionary = COMPETENCES[id].duplicate()
	var r: Dictionary = Classes.fiche(classe)["remplace"]
	if r.has(id):
		c.merge(r[id], true)
		c["de_classe"] = true
	return c

func _maj_stats() -> void:
	var ratio := pv / pv_max if pv_max > 0.0 else 1.0
	pv_max = roundf(PV_BASE * (1.0 + stat("endurance")))
	pv = clampf(ratio * pv_max, 1.0 if not est_mort else 0.0, pv_max)
	pv_change.emit(pv, pv_max)
	energie_max = ENERGIE_BASE * (1.0 + stat("energie") * 0.5)

## Dégâts d'une compétence (ou de l'attaque auto) sur une cible, avec les bonus.
func _degats(base: float, e: Node, auto := false) -> float:
	var m := base * degats_arme * (1.0 + (stat("auto") if auto else stat("sorts")))
	if e.pv < e.pv_max * 0.3:
		m *= 1.0 + stat("achever")
	return m

## Tire un critique ; Sang de Fenrir soigne à chaque critique.
func _crit(chance: float) -> bool:
	var c := randf() < chance + stat("critique")
	if c and stat("fenrir") > 0.0:
		soigner(pv_max * 0.02)
	return c

## Les coups du joueur atteignent aussi la Horde (rampants sans corps physique).
func _frappe_horde(d: Dictionary) -> void:
	if ia or Essaim.moi == null:
		return
	d["source"] = self
	Jeu.evenement("frappe", d)

func _micro_pause(t: float) -> void:
	if not ia:
		Effets.micro_pause(get_tree(), t)

func _maj_arme() -> void:
	var ok: bool = not sac.arme.is_empty() and not (en_epreuve and not ia) and sac.arme.get("classe", "") == classe
	degats_arme = sac.arme.get("degats", 90) * (1.0 + 0.06 * sac.arme.get("forge", 0)) / 30.0 if ok else 3.0

## L'arme tenue en main dépend de la classe (grande hache, bâton, épée et bouclier, dagues).
func _armes_visibles() -> void:
	if modele == null:
		return
	var f := Classes.fiche(classe)
	var hache := modele.find_child("2H_Axe", true, false)
	if hache:
		hache.visible = not f.has("main_d")
	for cote in [["main_d", "handslot.r"], ["main_g", "handslot.l"]]:
		if not f.has(cote[0]):
			continue
		var sk: Skeleton3D = modele.find_child("Skeleton3D", true, false)
		if sk == null or sk.find_bone(cote[1]) < 0:
			continue
		var ba := BoneAttachment3D.new()
		ba.bone_name = cote[1]
		sk.add_child(ba)
		ba.add_child(load(f[cote[0]]).instantiate())

## Puissance affichée (comme un « niveau d'équipement ») : arme, reliques, talents, classe.
func puissance() -> int:
	var p := 600.0 + degats_arme * 100.0
	p *= 1.0 + stat("sorts") * 0.8 + stat("endurance") * 0.6 + stat("recharge") * 0.6 + stat("energie") * 0.3 + stat("critique")
	if not ia:
		p += Profil.p().points_investis() * 12.0
	else:
		p += niveau * 15.0
	if acolyte_noeud and is_instance_valid(acolyte_noeud):
		p += 80.0 + Objets.RARETES.find(sac.acolyte.get("rarete", "commun")) * 60.0
	return int(round(p / 10.0)) * 10

## Action canalisée (miner, ouvrir un coffre, fouiller un corps) : barre de progression,
## annulée si l'on bouge, si l'on est frappé ou si l'on lance un sort.
func canaliser(nom: String, duree: float, anim_nom := "Interact", inebranlable := false) -> void:
	if action != "" or est_mort:
		return
	action = "canal"
	_action_t = 0.0
	_canal = {"nom": nom, "duree": duree, "inebranlable": inebranlable}
	_action = {"duree": duree}
	jouer(anim_nom, 0.1, 1.0, duree)

func canal_en_cours() -> String:
	return _canal.get("nom", "") if action == "canal" else ""

func _fin_canal(reussi: bool) -> void:
	var nom: String = _canal.get("nom", "")
	action = ""
	_canal = {}
	verrou_anim = 0.0
	canal_fini.emit(nom, reussi)

func ennemi_proche(portee: float) -> EntiteCombat:
	var meilleur: EntiteCombat = null
	var d := portee
	for e in ennemis_vivants():
		var l := global_position.distance_to(e.global_position)
		if l < d:
			d = l
			meilleur = e
	return meilleur

func direction_auto() -> Vector3:
	var e := ennemi_proche(14.0)
	return direction_vers(e.global_position) if e else -_avant()

func _avant() -> Vector3:
	return -global_transform.basis.z * -1.0   # le modèle KayKit regarde vers +z local

func direction_visee() -> Vector3:
	# pendant un bond ou une ruée la vitesse explose : la caméra ne doit pas anticiper 10 m d'un coup
	var v := Vector3(velocity.x, 0, velocity.z)
	return v.limit_length(vitesse) / vitesse if v.length() > 0.3 else Vector3.ZERO

func en_mouvement_rapide() -> bool:
	return action in ["saut", "ruee", "esquive"]

func _camera_secousse(f: float) -> void:
	if ia:
		return
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("secouer"):
		cam.secouer(f)

func _scene() -> Node:
	return get_parent()

# ---------------- lancement ----------------

func _cout(id: String) -> float:
	if id == "d" and stat("muninn") > 0.0:
		return 0.0
	var c: float = competence(id)["cout"]
	if id == "d":
		c *= 1.0 - stat("esquive")
	return c

func _recharge(id: String) -> float:
	if id == "d" and stat("muninn") > 0.0:
		return 0.8
	return competence(id)["cd"] * maxf(0.4, 1.0 - stat("recharge"))

## Appelé par le HUD ou le clavier. `dir` = direction visée (null = automatique vers l'ennemi proche).
func lancer(id: String, dir = null) -> bool:
	var c: Dictionary = COMPETENCES[id]
	var raison := ""
	if est_mort:
		raison = "mort"
	elif etourdi_t > 0.0:
		raison = "Étourdi"
	elif action != "":
		raison = "Impossible maintenant"
	elif cds[id] > 0.0:
		raison = "En recharge"
	elif energie < _cout(id):
		raison = "Pas assez d'énergie"
	elif id == "p" and potions <= 0:
		raison = "Plus de potions"
	elif id in ["q", "w", "e"] and ZoneSure.contient(global_position):
		raison = "Pas d'arme tirée ici"
	if raison != "" and ia:
		return false
	if raison != "":
		refus.emit(id, raison)
		Effets.nombre(_scene(), global_position, raison, Color("#CFD6EE"), false, "etat")
		Sons.jouer("refus", global_position, -10.0)
		return false
	var d: Vector3 = dir if dir is Vector3 and dir.length() > 0.1 else direction_auto()
	if id == "d" and not (dir is Vector3 and dir.length() > 0.1):
		var m := Vector3(entree.x, 0, entree.y)
		d = m.normalized() if m.length() > 0.2 else -direction_auto()
	d.y = 0
	d = d.normalized()
	cds[id] = _recharge(id)
	energie -= _cout(id)
	energie_change.emit(energie, energie_max)
	var de_classe: bool = Classes.fiche(classe)["remplace"].has(id)
	match id if not de_classe else classe + ":" + id:
		"souffle:q": _souffle(d)
		"ecailles:r": _carapace()
		"ailes:w": _envol(d)
		"q": _fendoir(d)
		"w": _bond(d)
		"e": _ruee_incantation(d)
		"r": _bulle()
		"f": _pas_du_vent()
		"p": _potion()
		"d": _esquive(d)
	return true

func montrer_visee(id: String, dir: Vector3) -> void:
	var formes := {"q": [Telegraphe.Forme.CONE, 3.6, 0.95], "w": [Telegraphe.Forme.LIGNE, 7.0, 2.0], "e": [Telegraphe.Forme.LIGNE, 12.0, 2.6], "d": [Telegraphe.Forme.LIGNE, 4.2, 1.2]}
	if not formes.has(id):
		return
	if _visee == null:
		var f: Array = formes[id]
		_visee = Telegraphe.creer(_scene(), f[0], global_position, dir, f[1], f[2], 9999.0, Color(0.5, 0.88, 1.0))
		_visee.set_process(false)
	_visee.global_position = global_position + Vector3(0, 0.05, 0)
	_visee.global_rotation.y = atan2(-dir.x, -dir.z)

func cacher_visee() -> void:
	if _visee:
		_visee.queue_free()
		_visee = null

# ---------------- compétences ----------------

func _fendoir(d: Vector3) -> void:
	regarder(d)
	jouer("2H_Melee_Attack_Chop", 0.08, 1.45, 0.55)
	Sons.jouer("elan", global_position, -2.0)
	await get_tree().create_timer(0.24).timeout
	if est_mort:
		return
	Effets.taille(_scene(), global_position, d, 3.4, Color(1.0, 0.8, 0.45), "slash_02.png", 0.24, -0.9)
	var touche := false
	_frappe_horde({"centre": global_position, "rayon": 3.6, "angle": 0.95, "dir": d, "degats": 34.0 * degats_arme * (1.0 + stat("sorts"))})
	for e in cibles_touchables():
		if Zones.dans_cone(e.global_position, global_position, d, 3.6, 0.95, e.rayon):
			e.recevoir({"montant": _degats(34.0, e), "source": self, "critique": _crit(0.15), "recul": 0.6})
			touche = true
	if touche:
		Sons.jouer("coup_os", global_position, 0.0)
		_camera_secousse(0.25)
		_micro_pause(0.05)

func _bond(d: Vector3) -> void:
	var dist := Zones.distance_libre(get_world_3d(), global_position, d, 7.0, [get_rid()])
	regarder(d)
	action = "saut"
	_action_t = 0.0
	_action = {"dep": global_position, "dir": d, "dist": dist, "duree": 0.55}
	jouer("Jump_Full_Short", 0.06, 1.35, 0.6)
	Sons.jouer("tissu", global_position, -4.0)

# ---------------- compétences draconiques ----------------

var _carapace_t := 0.0
var _carapace_noeud: MeshInstance3D

## Souffle ardent : long cône de feu, brûlure 3 s.
func _souffle(d: Vector3) -> void:
	regarder(d)
	jouer("2H_Melee_Attack_Chop", 0.08, 1.3, 0.55)
	Sons.jouer("activation", global_position, -2.0, 0.7)
	Telegraphe.creer(_scene(), Telegraphe.Forme.CONE, global_position, d, 6.0, 1.1, 0.28, Color(1.0, 0.5, 0.15))
	await get_tree().create_timer(0.2).timeout
	if est_mort:
		return
	var o := global_position + Vector3(0, 1.1, 0) + d * 0.6
	for i in 3:
		Effets.etincelles(_scene(), o, d + Vector3(0, 0.05, 0), Color(1.0, 0.55 - i * 0.12, 0.15), 22, 10.0 + i * 2.0, "fire_01.png" if i == 0 else "spark_04.png", 0.6 - i * 0.12)
	Effets.flash_lumiere(_scene(), o + d * 2.0, Color(1.0, 0.5, 0.2), 4.0, 8.0, 0.35)
	_frappe_horde({"centre": global_position, "rayon": 6.0, "angle": 1.1, "dir": d, "degats": 30.0 * degats_arme * (1.0 + stat("sorts")) * 1.6})
	for e in cibles_touchables():
		if Zones.dans_cone(e.global_position, global_position, d, 6.0, 1.1, e.rayon):
			e.recevoir({"montant": _degats(30.0, e), "source": self, "critique": _crit(0.1)})
			_bruler(e, _degats(30.0, e) * 0.6, 3.0)

## Dégâts sur la durée (feu) : quelques petits coups espacés.
func _bruler(e: Node, total: float, duree: float) -> void:
	var n := int(duree / 0.5)
	for i in n:
		await get_tree().create_timer(0.5).timeout
		if not is_instance_valid(self) or not is_instance_valid(e) or e.est_mort:
			return
		e.recevoir({"montant": total / n, "source": self})
		Effets.etincelles(_scene(), e.global_position + Vector3(0, 1.0, 0), Vector3.UP, Color(1.0, 0.5, 0.15), 5, 2.0, "spark_04.png", 0.3)

## Carapace d'écailles : 4 s de protection, renvoie une part des coups.
func _carapace() -> void:
	jouer("Block", 0.08, 1.0, 0.5)
	_carapace_t = 4.0
	Sons.jouer("metal", global_position, 0.0, 0.6)
	Effets.onde(_scene(), global_position, 2.4, Color(0.4, 1.0, 0.75))
	if _carapace_noeud == null:
		var m := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 1.05
		sp.height = 2.3
		m.mesh = sp
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.25, 0.9, 0.6, 0.18)
		mat.disable_fog = true
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.material_override = mat
		m.position.y = 1.0
		add_child(m)
		_carapace_noeud = m
	_carapace_noeud.visible = true

## Envol : grand bond, anneau de feu à l'arrivée.
func _envol(d: Vector3) -> void:
	var dist := Zones.distance_libre(get_world_3d(), global_position, d, 11.0, [get_rid()])
	regarder(d)
	action = "saut"
	_action_t = 0.0
	_action = {"dep": global_position, "dir": d, "dist": dist, "duree": 0.75, "envol": true}
	jouer("Jump_Full_Long", 0.06, 1.2, 0.8)
	Sons.jouer("tissu", global_position, 0.0, 0.8)
	Effets.poussiere(_scene(), global_position, 10, Color(0.7, 0.85, 1.0, 0.5))

func _fin_envol() -> void:
	action = ""
	Effets.onde(_scene(), global_position, 3.8, Color(1.0, 0.55, 0.2))
	Effets.flash_lumiere(_scene(), global_position, Color(1.0, 0.55, 0.2), 4.0, 8.0, 0.3)
	Effets.etincelles(_scene(), global_position + Vector3(0, 0.3, 0), Vector3.UP, Color(1.0, 0.6, 0.2), 26, 7.0, "fire_01.png", 0.5)
	Sons.jouer("atterrissage", global_position, 2.0, 0.8)
	_camera_secousse(0.5)
	_frappe_horde({"centre": global_position, "rayon": 3.8, "degats": 32.0 * degats_arme * (1.0 + stat("sorts")) * 1.4})
	for e in cibles_touchables():
		if Zones.dans_cercle(e.global_position, global_position, 3.6, e.rayon):
			e.recevoir({"montant": _degats(32.0, e), "source": self, "critique": _crit(0.1), "recul": 1.6})
			_bruler(e, _degats(32.0, e) * 0.4, 2.0)

func _fin_bond() -> void:
	if _action.get("envol", false):
		_fin_envol()
		return
	action = ""
	Effets.onde(_scene(), global_position, 2.8, Color(1.0, 0.75, 0.4))
	Effets.poussiere(_scene(), global_position, 12)
	Sons.jouer("atterrissage", global_position, 0.0)
	_camera_secousse(0.4)
	var touche := false
	_frappe_horde({"centre": global_position, "rayon": 3.0, "degats": 26.0 * degats_arme * (1.0 + stat("sorts"))})
	for e in cibles_touchables():
		if Zones.dans_cercle(e.global_position, global_position, 2.6, e.rayon):
			e.recevoir({"montant": _degats(26.0, e), "source": self, "critique": _crit(0.05), "ralentir": 1.5, "recul": 1.2})
			touche = true
	if touche:
		Sons.jouer("coup_lourd", global_position)
		_micro_pause(0.06)

func _ruee_incantation(d: Vector3) -> void:
	regarder(d)
	action = "incantation"
	_action_t = 0.0
	_action = {"dir": d, "duree": 0.7}
	_action["tele"] = Telegraphe.creer(_scene(), Telegraphe.Forme.LIGNE, global_position, d, 12.0, 2.6, 0.7, Color(0.35, 0.8, 1.0))
	jouer("Spellcast_Raise", 0.08, 1.2, 0.75)
	Sons.jouer("activation", global_position, -4.0, 0.8)

func _ruee_depart() -> void:
	var d: Vector3 = _action["dir"]
	var t: Telegraphe = _action["tele"]
	if is_instance_valid(t):
		t.terminer()
	var dist := Zones.distance_libre(get_world_3d(), global_position, d, 12.0, [get_rid()])
	action = "ruee"
	_action_t = 0.0
	_action = {"dep": global_position, "dir": d, "dist": dist, "duree": 0.22, "touches": []}
	jouer("2H_Melee_Attack_Spin", 0.05, 1.6, 0.5)
	Sons.jouer("elan", global_position, 2.0, 0.8)
	_trainee_ruee(global_position, d, dist)

func _trainee_ruee(depart: Vector3, d: Vector3, dist: float) -> void:
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2.4, maxf(dist, 1.0))
	pm.center_offset = Vector3(0, 0, -maxf(dist, 1.0) * 0.5)
	m.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.disable_fog = true   # sinon le brouillard dessine un carré clair autour de l'effet
	mat.albedo_texture = load("res://assets/vfx/trace_04.png")
	mat.albedo_color = Color(0.55, 0.9, 1.0, 0.9)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_scene().add_child(m)
	m.global_position = depart + Vector3(0, 0.15, 0)
	m.global_rotation.y = atan2(-d.x, -d.z)
	var tw := m.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.7).set_delay(0.15)
	tw.tween_callback(m.queue_free)

func _bulle() -> void:
	jouer("Block", 0.08, 1.2, 0.4)
	bulle.activer()
	Sons.jouer("activation", global_position, -2.0, 1.2)

func _pas_du_vent() -> void:
	_vent_t = 3.0
	ralenti_t = 0.0
	Sons.jouer("tissu", global_position, 0.0, 1.3)
	if _vent_particules == null:
		var p := CPUParticles3D.new()
		p.amount = 24
		p.lifetime = 0.6
		var q := QuadMesh.new()
		q.size = Vector2(0.7, 0.7)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.disable_fog = true   # sinon le brouillard dessine un carré clair autour de l'effet
		m.albedo_texture = load("res://assets/vfx/twirl_01.png")
		m.albedo_color = Color(0.6, 1.0, 0.8, 0.6)
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.vertex_color_use_as_albedo = true
		q.material = m
		p.mesh = q
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.5
		p.gravity = Vector3(0, 0.5, 0)
		p.initial_velocity_min = 0.2
		p.initial_velocity_max = 0.8
		p.local_coords = false
		p.position.y = 0.6
		var r := Gradient.new()
		r.set_color(0, Color(1, 1, 1, 0.8))
		r.set_color(1, Color(1, 1, 1, 0))
		p.color_ramp = r
		add_child(p)
		_vent_particules = p
	_vent_particules.emitting = true

func _potion() -> void:
	for o in sac.objets:
		if o["id"] == "potion":
			sac.retirer(o, 1)
			break
	_soin_t = 4.0
	jouer("Use_Item", 0.08, 1.4, 0.5)
	Sons.jouer("potion", global_position)
	Effets.etincelles(_scene(), global_position + Vector3(0, 0.5, 0), Vector3.UP, Color(0.55, 1.0, 0.6), 18, 2.5, "star_06.png", 0.3)

func _esquive(d: Vector3) -> void:
	action = "esquive"
	_action_t = 0.0
	var dist := Zones.distance_libre(get_world_3d(), global_position, d, 4.2, [get_rid()])
	_action = {"dep": global_position, "dir": d, "dist": dist, "duree": 0.32}
	invulnerable_t = 0.3
	# animation selon la direction par rapport au regard
	var avant := Vector3(sin(rotation.y), 0, cos(rotation.y))
	var droite := Vector3(avant.z, 0, -avant.x)
	var fwd := d.dot(avant)
	var lat := d.dot(droite)
	var nom := "Dodge_Forward"
	if absf(lat) > absf(fwd):
		nom = "Dodge_Right" if lat > 0 else "Dodge_Left"
	elif fwd < 0:
		nom = "Dodge_Backward"
	jouer(nom, 0.05, 1.5, 0.35)
	Effets.poussiere(_scene(), global_position, 6)
	Sons.jouer("tissu", global_position, -2.0, 1.2)

func interrompre() -> void:
	if action == "canal":
		_fin_canal(false)
		return
	if action == "incantation":
		var t = _action.get("tele")
		if is_instance_valid(t):
			t.terminer(true)
		action = ""
		Effets.nombre(_scene(), global_position, "Interrompu", Color("#FFB37A"), false, "etat")

func recevoir(d: Dictionary) -> void:
	var src = d.get("source", null)
	if src != null and is_instance_valid(src):
		dernier_agresseur = src
		if src is Heros:
			declarer_hostile(src, true)
			d = d.duplicate()
			d["montant"] = d.get("montant", 0.0) * MULT_JCJ
	if action == "canal" and d.get("montant", 0.0) > 0.0 and invulnerable_t <= 0.0 and not est_mort and not _canal.get("inebranlable", false):
		_fin_canal(false)
	if d.get("montant", 0.0) > 0.0 and invulnerable_t <= 0.0 and not est_mort:
		_t_sans_coup = 0.0
		var arm := clampf(stat("armure"), -0.5, 0.5)
		if _carapace_t > 0.0:
			arm = maxf(arm, 0.0) + 0.6
			var src2 = d.get("source", null)
			if src2 != null and is_instance_valid(src2) and src2 is EntiteCombat and not d.get("reflet", false) and not src2.est_mort:
				src2.recevoir({"montant": d["montant"] * 0.25, "source": self, "reflet": true})
		var m: float = d["montant"] * (1.0 - arm)
		# Dernier rempart : un coup mortel laisse à 1 PV, une fois toutes les 90 s
		if m >= pv and stat("rempart") > 0.0 and _rempart_t <= 0.0:
			m = pv - 1.0
			_rempart_t = 90.0
			d = d.duplicate()
			d["montant"] = m
			super.recevoir(d)
			invulnerable_t = 1.5
			Effets.onde(_scene(), global_position, 3.5, Color(0.6, 1.0, 0.5))
			Effets.nombre(_scene(), global_position, "Dernier rempart !", Color("#B8FF9A"), true, "etat")
			return
		if arm != 0.0:
			d = d.duplicate()
			d["montant"] = m
	super.recevoir(d)

func _reaction_coup(d: Dictionary) -> void:
	Sons.jouer("coup_recu", global_position, -2.0)
	_camera_secousse(0.2 if not d.get("lourd", false) else 0.45)
	if action == "" and verrou_anim <= 0.0:
		jouer("Hit_A", 0.05, 1.6, 0.22)

func _mourir() -> void:
	# Robe de résurrection : tant qu'elle est dans le sac, la mort ne prend pas (une fois)
	if not ia and sac.compter("robe_resurrection") > 0:
		for o in sac.objets:
			if o["id"] == "robe_resurrection":
				sac.retirer(o, 1)
				break
		pv = pv_max * 0.5
		pv_change.emit(pv, pv_max)
		invulnerable_t = 2.5
		Effets.onde(_scene(), global_position, 4.0, Color(1.0, 0.9, 0.5))
		Effets.etincelles(_scene(), global_position + Vector3(0, 1, 0), Vector3.UP, Color(1.0, 0.9, 0.5), 40, 6.0, "star_06.png", 0.45)
		Sons.jouer("cloche", global_position, 2.0, 0.8)
		Jeu.notifier("La Robe de résurrection se consume : tu te relèves !", Color("#FFE9A0"))
		return
	tueur = dernier_agresseur if is_instance_valid(dernier_agresseur) else null
	super._mourir()
	cacher_visee()
	jouer("Death_A", 0.1, 1.0, 99.0)
	# tout ce qu'on porte reste au sol ; si un autre joueur nous a tués, il se sert d'abord
	var butin := sac.tout_vider()
	if acolyte_noeud and is_instance_valid(acolyte_noeud):
		acolyte_noeud.queue_free()
	if tueur is Heros and not tueur.est_mort:
		butin = tueur.ramasser(butin, "la dépouille de " + nom_joueur)
		if tueur == Jeu.joueur:
			Jeu.evenement("jcj", {"nom": nom_joueur})
	if not butin["objets"].is_empty() or butin["or"] > 0:
		Depouille.creer(_scene(), global_position, butin, nom_joueur)

## Prend tout ce qui rentre dans le sac ; renvoie ce qui reste.
func ramasser(butin: Dictionary, origine := "") -> Dictionary:
	var reste: Array = []
	if butin["or"] > 0:
		var gain := int(round(butin["or"] * (1.0 + stat("fortune"))))
		sac.ajouter_or(gain)
		butin = butin.duplicate()
		butin["or"] = gain
	var pris: Array = []
	for o in butin["objets"]:
		if sac.ajouter(o):
			pris.append(o)
		else:
			reste.append(o)
	ramasse.emit(butin["or"], pris, origine)
	return {"or": 0, "objets": reste}

signal ramasse(or_: int, objets: Array, origine: String)

# ---------------- boucle ----------------

func _physics_process(delta: float) -> void:
	_process_etats(delta)
	for id in cds:
		cds[id] = maxf(0.0, cds[id] - delta)
	if est_mort:
		velocity = Vector3.ZERO
		appliquer_physique(delta)
		return
	energie = minf(energie_max, energie + regen_energie * (1.0 + stat("energie")) * delta)
	if mana < mana_max:
		mana = minf(mana_max, mana + 2.5 * delta)
		mana_change.emit(mana, mana_max)
	_rempart_t = maxf(0.0, _rempart_t - delta)
	if _carapace_t > 0.0:
		_carapace_t -= delta
		if _carapace_t <= 0.0 and _carapace_noeud:
			_carapace_noeud.visible = false
	_t_sans_coup += delta
	if _t_sans_coup > 6.0 and pv < pv_max:
		var rg := stat("regen")
		if rg > 0.0:
			soigner(pv_max * rg * delta)
	energie_change.emit(energie, energie_max)
	if _soin_t > 0.0:
		_soin_t -= delta
		soigner(pv_max * 0.3 / 4.0 * (1.0 + stat("soin")) * delta)
	if _vent_t > 0.0:
		_vent_t -= delta
		if _vent_t <= 0.0 and _vent_particules:
			_vent_particules.emitting = false

	match action:
		"saut":
			_action_t += delta
			var k := clampf(_action_t / _action["duree"], 0.0, 1.0)
			var cible: Vector3 = _action["dep"] + _action["dir"] * _action["dist"] * k
			velocity = (cible - global_position) / maxf(delta, 0.001)
			velocity.y = 0
			move_and_slide()
			if modele:
				modele.position.y = sin(k * PI) * (3.0 if _action.get("envol", false) else 1.6)
			if k >= 1.0:
				if modele:
					modele.position.y = 0.0
				_fin_bond()
			return
		"canal":
			_action_t += delta
			velocity = Vector3.ZERO
			appliquer_physique(delta)
			var e2 := entree + (Vector2.ZERO if ia else Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down"))
			if e2.length() > 0.5:
				_fin_canal(false)
			elif _action_t >= _canal["duree"]:
				_fin_canal(true)
			return
		"incantation":
			_action_t += delta
			velocity = Vector3.ZERO
			if _action_t >= _action["duree"]:
				_ruee_depart()
			return
		"ruee":
			_action_t += delta
			var k2 := clampf(_action_t / _action["duree"], 0.0, 1.0)
			var cible2: Vector3 = _action["dep"] + _action["dir"] * _action["dist"] * k2
			velocity = (cible2 - global_position) / maxf(delta, 0.001)
			velocity.y = 0
			move_and_slide()
			var dep: Vector3 = _action["dep"]
			for e in cibles_touchables():
				if e in _action["touches"]:
					continue
				if Zones.dans_ligne(e.global_position, dep, _action["dir"], _action["dist"] * k2 + 0.5, 2.6, e.rayon):
					_action["touches"].append(e)
					e.recevoir({"montant": _degats(78.0, e), "source": self, "etourdir": 1.4, "critique": _crit(0.25), "lourd": true})
					Sons.jouer("cloche", e.global_position, -2.0)
					Effets.flash_lumiere(_scene(), e.global_position, Color(0.6, 0.9, 1.0), 3.0, 6.0)
			if k2 >= 1.0:
				action = ""
				velocity = Vector3.ZERO
				_frappe_horde({"centre": _action["dep"], "dir": _action["dir"], "longueur": _action["dist"] + 0.5, "rayon": 2.6, "degats": 78.0 * degats_arme})
				Effets.poussiere(_scene(), global_position, 10)
				if not _action["touches"].is_empty():
					_camera_secousse(0.5)
					_micro_pause(0.07)
			return
		"esquive":
			_action_t += delta
			var k3 := clampf(_action_t / _action["duree"], 0.0, 1.0)
			var e3 := 1.0 - pow(1.0 - k3, 2.0)
			var cible3: Vector3 = _action["dep"] + _action["dir"] * _action["dist"] * e3
			velocity = (cible3 - global_position) / maxf(delta, 0.001)
			velocity.y = 0
			move_and_slide()
			if k3 >= 1.0:
				action = ""
				velocity = Vector3.ZERO
			return

	if etourdi_t > 0.0:
		velocity = velocity.move_toward(Vector3.ZERO, 30.0 * delta)
		appliquer_physique(delta)
		return

	# déplacement
	var clavier := Vector2.ZERO if ia else Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var e_in := entree + clavier
	if e_in.length() > 1.0:
		e_in = e_in.normalized()
	var v_max := vitesse * (1.0 + stat("vitesse")) * facteur_vitesse() * (1.6 if _vent_t > 0.0 else 1.0)
	var voulu := Vector3(e_in.x, 0, e_in.y) * v_max
	var h := Vector3(velocity.x, 0, velocity.z).move_toward(voulu, 45.0 * delta)
	velocity.x = h.x
	velocity.z = h.z
	appliquer_physique(delta)
	var bouge := h.length() > 0.4
	if bouge:
		regarder(h, delta)
		_pas_t -= delta * h.length() / vitesse
		if _pas_t <= 0.0:
			_pas_t = 0.34
			Sons.jouer("pas", global_position, -18.0)

	# attaque automatique sur l'ennemi proche
	_attaque_t -= delta
	var cible_auto := ennemi_proche(3.0)
	if cible_auto is Heros and (ZoneSure.contient(global_position) or ZoneSure.contient(cible_auto.global_position)):
		cible_auto = null
	if cible_auto == null and not ia and Essaim.moi and _attaque_t <= 0.0 and verrou_anim <= 0.0:
		var pr := Essaim.moi.proche(global_position, 2.8)
		if pr != Vector3.INF:
			_attaque_t = 0.75
			var da := direction_vers(pr)
			if not bouge:
				regarder(da)
			jouer("2H_Melee_Attack_Slice", 0.06, 1.7, 0.35)
			Sons.jouer("elan", global_position, -6.0, 1.15)
			Effets.taille(_scene(), global_position, da, 2.8, Color(1.0, 0.72, 0.4, 0.8), "slash_03.png", 0.18, -0.5)
			_frappe_horde({"centre": global_position, "rayon": 3.0, "angle": 1.2, "dir": da, "degats": 22.0 * degats_arme * (1.0 + stat("auto"))})
	if cible_auto and _attaque_t <= 0.0 and verrou_anim <= 0.0:
		_attaque_t = 0.95
		var dir_a := direction_vers(cible_auto.global_position)
		if not bouge:
			regarder(dir_a)
		jouer("2H_Melee_Attack_Slice", 0.06, 1.7, 0.4)
		Sons.jouer("elan", global_position, -6.0, 1.15)
		_frappe_auto(cible_auto, dir_a)

	if verrou_anim <= 0.0:
		if bouge:
			jouer("Running_A", 0.12, clampf(h.length() / vitesse, 0.7, 1.2))
		else:
			jouer("2H_Melee_Idle", 0.15)

func _frappe_auto(cible: EntiteCombat, d: Vector3) -> void:
	await get_tree().create_timer(0.17).timeout
	if est_mort or not is_instance_valid(cible) or cible.est_mort:
		return
	Effets.taille(_scene(), global_position, d, 2.6, Color(1.0, 0.72, 0.4, 0.8), "slash_03.png", 0.18, -0.5)
	if global_position.distance_to(cible.global_position) <= 3.4:
		cible.recevoir({"montant": _degats(14.0, cible, true), "source": self, "critique": _crit(0.1)})
		Sons.jouer("coup_os", cible.global_position, -4.0)
