class_name Villageois
extends EntiteCombat
## Un habitant du Val. Il a une maison, une famille, un métier qu'il exerce pour de vrai
## (le bûcheron abat un arbre et rapporte la bûche, le forgeron frappe l'enclume, le pêcheur
## s'assoit au bout du ponton…), et sa journée : travail, repas, veillée au feu, sommeil.
##
## Le joueur peut en faire son Pantin : il reste lui-même, mais obéit aux ordres
## (suivre, couper du bois, miner, voler, piller, attaquer). On peut aussi prendre son corps.

const P := "res://assets/personnages/"
const MODELES := {"paysan": P + "paysan.glb", "barbare": P + "barbare.glb", "robe": P + "freya.glb", "garde": P + "chevalier.glb", "capuche": P + "marchand.glb"}
const CACHES := ["Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Knife", "Throwable", "Spellbook", "Spellbook_open", "1H_Wand", "2H_Staff",
	"1H_Axe_Offhand", "Barbarian_Round_Shield", "Mug", "1H_Axe", "2H_Axe", "1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Round_Shield", "Spike_Shield", "1H_Sword", "2H_Sword",
	"Mage_Hat", "Barbarian_Hat", "Rogue_Cape", "Mage_Cape", "Barbarian_Cape"]
const OUTILS := {
	"hache": ["res://assets/armes/axe_1handed.gltf", 1.0], "epee": ["res://assets/armes/sword_1handed.gltf", 1.0],
	"pioche": ["res://assets/surface/outils/pickaxe.gltf", 0.7], "marteau": ["res://assets/surface/outils/hammer.gltf", 0.8],
	"pelle": ["res://assets/surface/outils/shovel.gltf", 0.75], "torche": ["res://assets/surface/outils/torch.gltf", 0.8],
}
## Couleurs de vêtements : des teintes de lin, de laine et de cuir, jamais criardes.
const ETOFFES := [Color(0.86, 0.78, 0.62), Color(0.62, 0.46, 0.32), Color(0.55, 0.6, 0.4), Color(0.7, 0.42, 0.32), Color(0.5, 0.56, 0.66),
	Color(0.42, 0.52, 0.38), Color(0.82, 0.66, 0.4), Color(0.66, 0.64, 0.6), Color(0.58, 0.36, 0.38), Color(0.75, 0.7, 0.55)]

const PAROLES := {
	"bucheron": ["Celui-là tombera avant midi.", "Attention, ça tombe !", "Encore une bûche pour la scierie."],
	"mineur": ["La pierre de Dvalin est dure comme un roi.", "Un filon par-ci…", "Mes bras me lâchent."],
	"fermier": ["La terre est bonne, cette année.", "Si seulement il pleuvait.", "Encore un sillon."],
	"forgeron": ["Rien de tel que l'acier de Jarnborg.", "Repasse demain, ta lame sera prête.", "Chaud devant !"],
	"marchand": ["Approchez ! Du bon pain, du fromage !", "Des étoffes de Vik, presque données !", "Pour toi, prix d'ami."],
	"aubergiste": ["De l'hydromel, voyageur ?", "La soupe est chaude.", "On n'a pas vu le fond d'un tonneau depuis la Saint-Odin."],
	"pecheur": ["Ça mord pas.", "Chut… tu vas faire peur aux truites.", "Le lac est calme, aujourd'hui."],
	"garde": ["Circulez.", "Pas d'histoires, étranger.", "L'œil du Jarl est partout."],
	"passant": ["Tu as vu le château ? Il paraît que le Jarl ne dort jamais.", "Les pillards de Hrafn ont encore frappé.", "Belle journée.",
		"On dit qu'un dragon dort sous la montagne.", "Ma sœur s'est mariée à Vik.", "Les prix montent, les prix montent…"],
	"enfant": ["Attrape-moi !", "C'est moi le draugr !", "Hé ! Tu es un vrai guerrier ?"],
	"pretre": ["Qu'Odin te garde.", "Les corbeaux voient tout.", "Prie, voyageur."],
	"meunier": ["La farine ne se fait pas toute seule.", "Le vent est bon."],
	"chef": ["Bienvenue chez nous.", "Mes gens travaillent dur."],
}

# ---------------- identité ----------------
var nom := ""
var metier := ""                ## affiché sous le nom
var role := "passant"           ## comportement : bucheron, mineur, fermier, forgeron, marchand, aubergiste, pecheur, meunier, pretre, garde, enfant, passant, chef
var famille := ""
var colonie: Colonie
var maison: Dictionary = {}
var modele_id := "paysan"
var teinte := Color.WHITE
var enfant := false
var femme := false
var vitesse_marche := 1.7
var force := 40.0
var outil := ""
var maitre: Node = null         ## le joueur, si c'est son pantin

# ---------------- état ----------------
var etat := "routine"           ## routine, ordre, combat, fuite, arrete, mort
var activite := ""              ## travail, repas, veillee, nuit, balade
var pantin := false
var ordre: Dictionary = {}
var controle := false           ## piloté par le joueur (corps pris)
var entree := Vector2.ZERO
var cache := false
var arrete := false
var butin: Dictionary = {}      ## ce qu'il porte (vol)
var reponse := 0.0              ## a été attaqué récemment

var _chemin := PackedVector3Array()
var _i := 0
var _but := Vector3.INF
var _arrivee := Callable()
var _attente := false
var _course := false
var _t := 0.0
var _tache := ""
var _tache_t := 0.0
var _recolte: Dictionary = {}
var _charge: Node3D
var _outil_noeud: Node3D
var _attache: BoneAttachment3D
var _etiquette: Label3D
var _bulle: Label3D
var _bulle_t := 0.0
var _parole_t := 0.0
var _aura: Node3D
var cible_combat: Node3D
var _cd := 0.0
var _loin := false
var _lod_acc := 0.0
var _recal_t := 0.0
var _ronde_i := 0

func _ready() -> void:
	camp = "villageois"
	rayon = 0.45
	hauteur_barre = 2.4
	if pv_max <= 100.0:
		pv_max = 520.0 if not enfant else 260.0
	super._ready()
	collision_layer = 0
	collision_mask = 0
	add_to_group("villageois")
	installer_modele(load(MODELES.get(modele_id, MODELES["paysan"])), 0.68 if enfant else 1.0, CACHES if modele_id != "garde" else CACHES.filter(func(n): return n != "Round_Shield"))
	if enfant:
		vitesse_marche = 2.0
	_vetir()
	if anim:
		for a in ["Walking_A", "Sit_Chair_Idle", "Sit_Floor_Idle", "Interact", "Use_Item", "1H_Melee_Attack_Chop", "Lie_Idle", "Cheer"]:
			if anim.has_animation(a):
				anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
	_etiquette = Label3D.new()
	_etiquette.font_size = 34
	_etiquette.outline_size = 8
	_etiquette.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_etiquette.pixel_size = 0.009
	_etiquette.position.y = 2.5 if not enfant else 1.8
	_etiquette.modulate = Color("#F2E6C8")
	_etiquette.no_depth_test = false
	_etiquette.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(_etiquette)
	_maj_etiquette()
	_bulle = Label3D.new()
	_bulle.font_size = 30
	_bulle.outline_size = 10
	_bulle.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bulle.pixel_size = 0.009
	_bulle.position.y = 3.1 if not enfant else 2.3
	_bulle.modulate = Color(1, 1, 1, 0)
	_bulle.width = 360
	_bulle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bulle.process_mode = Node.PROCESS_MODE_DISABLED
	_bulle.visible = false
	add_child(_bulle)
	if role == "garde":
		_tenir("epee")
	_parole_t = randf_range(4.0, 20.0)
	jouer("Idle")

## Tenue de villageois : pas de chapeau ni de cape ; étoffes sobres. Les gardes gardent casque et cape aux couleurs du lieu.
func _vetir() -> void:
	for m in modele.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var corps := mi.name.contains("Body")
		var cape := mi.name.contains("Cape")
		var jambes := mi.name.contains("Leg")
		if not (corps or cape or jambes):
			continue
		for k in mi.mesh.get_surface_count():
			var src = mi.get_active_material(k)
			if src is StandardMaterial3D:
				var c: StandardMaterial3D = src.duplicate()
				if cape:
					c.albedo_color = teinte
				elif corps:
					c.albedo_color = teinte if modele_id != "garde" else Color(0.85, 0.85, 0.88)
				else:
					c.albedo_color = teinte.lerp(Color(0.45, 0.36, 0.28), 0.6)
				mi.set_surface_override_material(k, c)

func _maj_etiquette() -> void:
	if _etiquette == null:
		return
	var t := nom + "\n" + metier
	if arrete:
		t = nom + "\n(arrêté)"
	elif pantin:
		t = nom + "\n" + _texte_ordre()
	_etiquette.text = t
	_etiquette.modulate = Color("#D9B8FF") if pantin else (Color("#FF9C8A") if etat == "combat" and not pantin else Color("#F2E6C8"))

func _texte_ordre() -> String:
	match ordre.get("id", ""):
		"suivre": return "pantin · te suit"
		"bois": return "pantin · coupe du bois"
		"pierre": return "pantin · mine"
		"voler": return "pantin · cambriole"
		"piller": return "pantin · pille"
		"attaquer": return "pantin · attaque"
		"garder": return "pantin · monte la garde"
	return "pantin"

# ---------------- outils et charges ----------------

func _tenir(o: String) -> void:
	if outil == o:
		return
	outil = o
	if _outil_noeud:
		_outil_noeud.queue_free()
		_outil_noeud = null
	if o == "" or not OUTILS.has(o):
		return
	if _attache == null:
		var sk: Skeleton3D = modele.find_child("Skeleton3D", true, false)
		if sk == null or sk.find_bone("handslot.r") < 0:
			return
		_attache = BoneAttachment3D.new()
		_attache.bone_name = "handslot.r"
		sk.add_child(_attache)
	_outil_noeud = load(OUTILS[o][0]).instantiate()
	_outil_noeud.scale = Vector3.ONE * OUTILS[o][1]
	_attache.add_child(_outil_noeud)

func _porter(chemin: String) -> void:
	_deposer()
	_charge = load(chemin).instantiate()
	_charge.position = Vector3(0, 1.75 if not enfant else 1.2, -0.05)
	_charge.rotation_degrees = Vector3(0, 90, 0)
	_charge.scale = Vector3.ONE * 0.9
	add_child(_charge)

func _deposer() -> void:
	if _charge:
		_charge.queue_free()
		_charge = null

# ---------------- déplacement ----------------

## Va jusqu'à p par les rues ; f est appelée à l'arrivée.
func aller(p: Vector3, f := Callable(), courir := false) -> void:
	_but = p
	_arrivee = f
	_course = courir
	_chemin = PackedVector3Array()
	_i = 0
	_attente = true
	if cache:
		_sortir()

func _avancer(delta: float) -> void:
	if _but == Vector3.INF:
		return
	if _attente:
		if not NavMonde.peut_calculer():
			return
		_attente = false
		if global_position.distance_to(_but) < 2.5 or not NavMonde.pret():
			_chemin = PackedVector3Array([_but])
		else:
			_chemin = NavMonde.chemin(global_position, _but)
			if _chemin.is_empty():
				_chemin = PackedVector3Array([_but])
		_i = 0
	if _i >= _chemin.size():
		_arrive()
		return
	var cible: Vector3 = _chemin[_i]
	var v := cible - global_position
	v.y = 0
	var l := v.length()
	var vit := (4.3 if _course else vitesse_marche) * facteur_vitesse() * (1.25 if arrete else 1.0)
	if l <= maxf(0.25, vit * delta):
		global_position = Vector3(cible.x, global_position.y, cible.z)
		_i += 1
		if _i >= _chemin.size():
			_arrive()
		return
	global_position += v / l * vit * delta
	if not _loin:
		rotation.y = lerp_angle(rotation.y, atan2(v.x, v.z), 1.0 - exp(-8.0 * delta))
		if verrou_anim <= 0.0:
			jouer("Running_A" if _course else "Walking_A", 0.2, 1.0 if not enfant else 1.25)

func _arrive() -> void:
	_but = Vector3.INF
	_chemin = PackedVector3Array()
	var f := _arrivee
	_arrivee = Callable()
	if not _loin:
		jouer("Idle", 0.25)
	if f.is_valid():
		f.call()

func en_route() -> bool:
	return _but != Vector3.INF

func regarder_vers(p: Vector3) -> void:
	var d := p - global_position
	d.y = 0
	if d.length() > 0.05:
		rotation.y = atan2(d.x, d.z)

func _rentrer() -> void:
	cache = true
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 0.01, 0.4)
	tw.tween_callback(func(): visible = false)

func _sortir() -> void:
	cache = false
	visible = true
	scale = Vector3.ONE

# ---------------- paroles ----------------

func dire(t: String, duree := 3.5) -> void:
	if _bulle == null:
		return
	_bulle.text = t
	_bulle_t = duree
	_bulle.visible = not _loin

func _paroles(delta: float, d_joueur: float) -> void:
	_parole_t -= delta
	if _bulle_t > 0.0:
		_bulle_t -= delta
		var a := snappedf(clampf(minf(_bulle_t, 1.0), 0.0, 1.0) * clampf((16.0 - d_joueur) / 4.0, 0.0, 1.0), 0.2)
		if absf(_bulle.modulate.a - a) > 0.01:
			_bulle.modulate.a = a
	elif _bulle.visible:
		_bulle.modulate.a = 0.0
		_bulle.visible = false
	if _parole_t <= 0.0:
		_parole_t = randf_range(14.0, 34.0)
		if d_joueur < 13.0 and etat == "routine" and not cache:
			var l: Array = PAROLES.get(role, PAROLES["passant"])
			dire(l[randi() % l.size()])

# ---------------- la journée ----------------

## Appelé par le Village quand la tranche horaire change (ou quand une tâche se termine).
func routine(tranche: String) -> void:
	if etat != "routine" or controle or arrete:
		return
	activite = tranche
	_tache = ""
	_deposer()
	match tranche:
		"travail":
			_travailler()
		"repas":
			_tenir("" if role != "garde" else "epee")
			var ou: Vector3 = colonie.un_poste("taverne") if colonie.a_poste("taverne") and randf() < 0.6 else _porte_maison()
			aller(_autour(ou, 2.2), func(): _tache = "repas")
		"veillee":
			_tenir("" if role != "garde" else "epee")
			if enfant:
				_jouer_enfant()
			elif colonie.a_poste("banc") and randf() < 0.55:
				var b: Vector3 = colonie.un_poste("banc")
				aller(b, func():
					regarder_vers(colonie.feu)
					_tache = "assis")
			elif colonie.feu != Vector3.INF:
				var a := randf() * TAU
				aller(colonie.feu + Vector3(cos(a), 0, sin(a)) * randf_range(3.2, 5.0), func():
					regarder_vers(colonie.feu)
					_tache = "veillee")
			else:
				_balade()
		"nuit":
			_tenir("" if role != "garde" else "torche")
			if role == "garde" and randf() < 0.6:
				_garder()
			else:
				aller(_porte_maison(), func(): _rentrer())

func _porte_maison() -> Vector3:
	if maison.is_empty():
		return colonie.place
	return maison["porte"]

func _autour(p: Vector3, r: float) -> Vector3:
	return p + Vector3(randf_range(-r, r), 0, randf_range(-r, r))

func _travailler() -> void:
	match role:
		"bucheron":
			_tenir("hache")
			_recolter("arbre", colonie.depot if colonie.depot != Vector3.INF else colonie.place, 55.0)
		"mineur":
			_tenir("pioche")
			_recolter("rocher", PlanMonde.CARRIERE, 18.0)
		"fermier":
			_tenir("pelle")
			_poste_anime("champs", "Interact", 7.0, 2.5)
		"forgeron":
			_tenir("marteau")
			_poste_anime("forge", "1H_Melee_Attack_Chop", 30.0, 0.4)
		"marchand":
			_tenir("")
			_poste_anime("marche", "Idle", 30.0, 1.2)
		"aubergiste":
			_tenir("")
			_poste_anime("taverne", "Interact", 12.0, 2.0)
		"pecheur":
			_tenir("")
			_poste_anime("peche", "Sit_Floor_Idle", 40.0, 0.0)
		"meunier":
			_tenir("")
			_poste_anime("moulin", "PickUp", 8.0, 2.0)
		"pretre":
			_tenir("")
			_poste_anime("temple", "Idle", 25.0, 1.5)
		"chef":
			_tenir("")
			_poste_anime("place", "Idle", 25.0, 2.0)
		"garde":
			_garder()
		"enfant":
			_jouer_enfant()
		_:
			_balade()

## Va au poste, joue l'animation du métier un moment, puis recommence (autre poste du même genre).
func _poste_anime(genre: String, a: String, duree: float, dispersion: float) -> void:
	if not colonie.a_poste(genre):
		_balade()
		return
	var p := _autour(colonie.un_poste(genre), dispersion)
	aller(p, func():
		_tache = "metier"
		_tache_t = duree
		set_meta("anim_metier", a)
		if genre == "peche":
			rotation.y = -PI / 2.0
		elif genre == "marche" or genre == "forge" or genre == "temple" or genre == "taverne":
			for m in colonie.maisons:
				if m["porte"].distance_to(p) < 4.0:
					rotation.y = atan2(m["dir"].x, m["dir"].z)
					break)

func _balade() -> void:
	_tenir("")
	var p := _autour(colonie.interet(), 4.0)
	aller(p, func():
		_tache = "pause"
		_tache_t = randf_range(5.0, 14.0)
		# une connaissance passe ? on discute
		for v in get_tree().get_nodes_in_group("villageois"):
			if v != self and not v.cache and v.etat == "routine" and v.global_position.distance_to(global_position) < 4.0:
				regarder_vers(v.global_position)
				_tache = "discute"
				break)

func _jouer_enfant() -> void:
	var c: Vector3 = colonie.un_poste("jeux") if colonie.a_poste("jeux") else colonie.place
	aller(_autour(c, 6.0), func():
		_tache = "pause"
		_tache_t = randf_range(1.0, 3.5), randf() < 0.7)

func _garder() -> void:
	if colonie.rondes.is_empty() or (colonie.a_poste("garde_porte") and get_meta("porte", false)):
		var p: Vector3 = colonie.un_poste("garde_porte") if not has_meta("poste_fixe") else get_meta("poste_fixe")
		set_meta("poste_fixe", p)
		aller(p, func():
			_tache = "faction"
			rotation.y = PI)
		return
	var ronde: Array = colonie.rondes[get_meta("ronde", 0) % colonie.rondes.size()]
	_ronde_i = (_ronde_i + 1) % ronde.size()
	aller(_autour(ronde[_ronde_i], 1.0), func():
		_tache = "pause"
		_tache_t = randf_range(2.0, 6.0))

## Bûcheron, mineur (et pantins) : choisit un arbre ou un rocher, l'abat, rapporte la charge.
func _recolter(genre: String, centre: Vector3, rayon_r: float, pour_joueur := false) -> void:
	var carte := CarteSurface.courante
	if carte == null:
		_balade()
		return
	var choix: Dictionary = {}
	var meilleur := 1e9
	for r in carte.recoltables:
		if r["abattu"] or r["genre"] != genre or r.get("reserve", false):
			continue
		var d: float = Vector2(r["pos"].x - centre.x, r["pos"].z - centre.z).length()
		if d < rayon_r:
			var cout := d + randf() * 12.0
			if cout < meilleur:
				meilleur = cout
				choix = r
	if choix.is_empty():
		_tache = "pause"
		_tache_t = 10.0
		return
	choix["reserve"] = true
	_recolte = choix
	var vers: Vector3 = global_position - choix["pos"]
	vers.y = 0
	var poste: Vector3 = choix["pos"] + (vers.normalized() if vers.length() > 0.1 else Vector3(0, 0, 1)) * 1.5
	aller(NavMonde.point_libre(poste), func():
		regarder_vers(choix["pos"])
		_tache = "abattre"
		_tache_t = 6.0 if genre == "arbre" else 5.0
		set_meta("pour_joueur", pour_joueur))

func _fin_abattage() -> void:
	var r := _recolte
	_recolte = {}
	if r.is_empty():
		return
	r["reserve"] = false
	if r["abattu"]:
		_tache = ""
		return
	CarteSurface.courante.abattre(r)
	var bois: bool = r["genre"] == "arbre"
	_porter("res://assets/surface/ressources/" + ("Wood_Log_A.gltf" if bois else "Stone_Chunks_Small.gltf"))
	if get_meta("pour_joueur", false):
		# un pantin travaille pour toi : la récolte file droit dans ton coffre
		var res := "bois" if bois else "pierre"
		var n := randi_range(2, 4) if bois else randi_range(1, 3)
		Pantins.deposer(self, res, n)
		_tache = ""
		get_tree().create_timer(1.2).timeout.connect(func():
			if is_instance_valid(self):
				_deposer())
		return
	var depot: Vector3 = colonie.depot if colonie and colonie.depot != Vector3.INF else (colonie.place if colonie else global_position)
	aller(depot, func():
		_deposer()
		if colonie:
			var k := "bois" if bois else "pierre"
			colonie.stock[k] = colonie.stock.get(k, 0) + 1
		_tache = "")

# ---------------- boucle ----------------

func _process(delta: float) -> void:
	_process_etats(delta)
	_t += delta
	if est_mort:
		return
	var j = Jeu.joueur
	var foyer: Vector3 = global_position
	if j and is_instance_valid(j):
		foyer = Pouvoirs.moi.controle.global_position if Pouvoirs.moi and Pouvoirs.moi.controle else j.global_position
	var d := global_position.distance_to(foyer)
	_lod(global_position - foyer)
	_animer(delta, d)
	if not _loin:
		# un Label3D se reconstruit à chaque changement de couleur : on ne touche que si ça change vraiment
		var a := 1.0 if (controle or pantin) else snappedf(clampf((11.0 - d) / 4.0, 0.0, 1.0), 0.25)
		if absf(_etiquette.modulate.a - a) > 0.01:
			_etiquette.modulate.a = a
			_etiquette.visible = a > 0.01
		_paroles(delta, d)
	if controle:
		_piloter(delta)
		return
	# loin du joueur : on avance par à-coups, sans animer (économie) ; à mi-distance, une image sur deux
	if _loin or d > 14.0:
		_lod_acc += delta
		if _lod_acc < (0.25 if _loin else 0.033):
			return
		delta = _lod_acc
		_lod_acc = 0.0
	reponse = maxf(0.0, reponse - delta)
	_cd = maxf(0.0, _cd - delta)
	match etat:
		"combat":
			_combattre(delta)
		"fuite":
			_avancer(delta)
			_tache_t -= delta
			if _tache_t <= 0.0 or not en_route():
				etat = "routine" if not pantin else "ordre"
				_reprendre()
		"ordre":
			Pantins.executer(self, delta)
		"arrete":
			_avancer(delta)
		_:
			if en_route():
				_avancer(delta)
			else:
				_faire(delta)

## Les animations coûtent cher : pleine cadence de près, une image sur trois à mi-distance.
var _anim_acc := 0.0
var _lod_fait := false
var _anim_k := 0

func _animer(delta: float, d: float) -> void:
	if anim == null or _loin:
		return
	if anim.callback_mode_process != AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL:
		anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_anim_acc += delta
	_anim_k += 1
	var pas := 1 if (d < 14.0 or controle or pantin) else 3
	if _anim_k % pas == 0 or _anim_acc > 0.2:
		anim.advance(_anim_acc)
		_anim_acc = 0.0

## Hors du champ de la caméra (une ellipse un peu plus large que l'écran) : ni dessin ni animation.
func _lod(ecart: Vector3) -> void:
	var e := Vector2(ecart.x / 25.0, ecart.z / (17.0 if ecart.z < 0.0 else 19.0))
	var loin := e.length_squared() > 1.0 and not pantin
	if loin == _loin and _lod_fait:
		return
	_lod_fait = true
	_loin = loin
	modele.visible = not loin
	# hors champ : le modèle entier (squelette, attaches d'armes, animation) cesse de tourner
	modele.process_mode = Node.PROCESS_MODE_DISABLED if loin else Node.PROCESS_MODE_INHERIT
	if anim:
		anim.active = not loin
	if loin:
		_etiquette.visible = false
		_bulle.visible = false

## Sur place : l'animation de la tâche en cours.
func _faire(delta: float) -> void:
	match _tache:
		"abattre":
			_tache_t -= delta
			if not _loin:
				jouer("1H_Melee_Attack_Chop", 0.15, 0.9)
				if fmod(_t, 0.95) < delta and is_instance_valid(Jeu.joueur) and global_position.distance_to(Jeu.joueur.global_position) < 22.0:
					Sons.jouer("coup_os" if outil == "hache" else "metal", global_position, -14.0, randf_range(1.2, 1.6))
					Effets.etincelles(get_parent(), global_position + global_transform.basis.z * 1.1 + Vector3(0, 1.0, 0), Vector3.UP, Color(0.6, 0.45, 0.25) if outil == "hache" else Color(0.7, 0.7, 0.72), 5, 2.5, "spark_04.png", 0.2)
			if _tache_t <= 0.0:
				_fin_abattage()
		"metier":
			_tache_t -= delta
			var a: String = get_meta("anim_metier", "Idle")
			if not _loin:
				if a == "1H_Melee_Attack_Chop":
					jouer(a, 0.15, 0.7)
					if fmod(_t, 1.4) < delta and is_instance_valid(Jeu.joueur) and global_position.distance_to(Jeu.joueur.global_position) < 18.0:
						Sons.jouer("metal", global_position, -12.0, randf_range(1.3, 1.6))
						Effets.etincelles(get_parent(), global_position + global_transform.basis.z * 0.9 + Vector3(0, 0.9, 0), Vector3.UP, Color(1.0, 0.7, 0.3), 8, 3.0, "spark_04.png", 0.2)
				elif a == "Idle" and fmod(_t, 9.0) < 2.5:
					jouer("Interact", 0.25)
				else:
					jouer(a, 0.3)
			if _tache_t <= 0.0:
				_tache = ""
				routine(activite)
		"pause", "discute":
			_tache_t -= delta
			if not _loin:
				jouer("Interact" if _tache == "discute" and fmod(_t, 5.0) < 2.0 else "Idle", 0.3)
			if _tache_t <= 0.0:
				_tache = ""
				routine(activite)
		"assis":
			if not _loin:
				jouer("Sit_Chair_Idle", 0.3)
		"veillee", "repas":
			if not _loin:
				jouer("Idle" if fmod(_t + get_instance_id() % 7, 8.0) < 6.0 else "Cheer", 0.3)
		"faction":
			if not _loin:
				jouer("Idle", 0.3)
		"":
			if activite != "":
				routine(activite)

# ---------------- corps pris (contrôle direct) ----------------

func _piloter(delta: float) -> void:
	var v := Vector3(entree.x, 0, entree.y)
	if v.length() > 0.15:
		v = v.limit_length(1.0)
		var dest := global_position + v * 4.4 * delta
		if NavMonde.est_libre(dest) or not NavMonde.pret():
			global_position = dest
		rotation.y = lerp_angle(rotation.y, atan2(v.x, v.z), 1.0 - exp(-10.0 * delta))
		jouer("Running_A", 0.15)
	elif anim_courante != "Interact":
		jouer("Idle", 0.2)

func prendre_controle() -> void:
	controle = true
	_but = Vector3.INF
	_sortir()
	_montrer_aura(true)

func liberer() -> void:
	controle = false
	entree = Vector2.ZERO
	jouer("Idle")
	if pantin:
		etat = "ordre"
	else:
		_montrer_aura(false)
		_reprendre()

func _montrer_aura(oui: bool) -> void:
	if oui and _aura == null:
		_aura = Node3D.new()
		add_child(_aura)
		var p := CPUParticles3D.new()
		p.amount = 14
		p.lifetime = 1.4
		var q := QuadMesh.new()
		q.size = Vector2(0.16, 0.16)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.albedo_color = Color(0.75, 0.45, 1.0, 0.8)
		m.disable_fog = true
		q.material = m
		p.mesh = q
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.5
		p.direction = Vector3.UP
		p.gravity = Vector3(0, 0.6, 0)
		p.initial_velocity_min = 0.3
		p.initial_velocity_max = 0.8
		p.position.y = 1.2
		_aura.add_child(p)
		# fil d'âme : un mince anneau violet au sol
		var anneau := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.55
		tm.outer_radius = 0.65
		anneau.mesh = tm
		var m2 := m.duplicate()
		m2.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
		anneau.material_override = m2
		anneau.position.y = 0.05
		anneau.scale = Vector3(1, 0.1, 1)
		_aura.add_child(anneau)
	if _aura:
		_aura.visible = oui
	_maj_etiquette()

# ---------------- pantin ----------------

func devenir_pantin(j: Node) -> void:
	pantin = true
	maitre = j
	add_to_group("pantin")
	etat = "ordre"
	ordre = {"id": "suivre"}
	_montrer_aura(true)
	_sortir()

func liberer_pantin() -> void:
	pantin = false
	maitre = null
	remove_from_group("pantin")
	ordre = {}
	etat = "routine"
	_montrer_aura(false)
	_deposer()
	dire("…Où suis-je ?", 3.0)
	_reprendre()

func _reprendre() -> void:
	_tache = ""
	_but = Vector3.INF
	if Village.moi:
		routine(Village.moi.tranche())

# ---------------- combat ----------------

## S'en prend à e (un autre habitant, un pillard…).
func attaquer(e: Node3D) -> void:
	if e == null or e == self or est_mort:
		return
	cible_combat = e
	if etat != "ordre":
		etat = "combat"
	_cache_combat()
	_maj_etiquette()

func _cache_combat() -> void:
	if role == "garde":
		_tenir("epee")
	elif role == "bucheron" or outil == "hache":
		_tenir("hache")

func _combattre(delta: float) -> void:
	if not _frapper_cible(delta):
		cible_combat = null
		etat = "routine" if not pantin else "ordre"
		_maj_etiquette()
		_reprendre()

## Une passe de combat contre cible_combat ; renvoie faux quand le combat est fini.
func _frapper_cible(delta: float) -> bool:
	var e := cible_combat
	if e == null or not is_instance_valid(e) or e.get("est_mort") or (e.get("cache") == true):
		return false
	var d := global_position.distance_to(e.global_position)
	if d > 45.0:
		return false
	var portee: float = 1.5 + (e.get("rayon") if e.get("rayon") != null else 0.5)
	if d > portee:
		if not en_route() or _recal_t <= 0.0:
			_recal_t = 0.6
			aller(e.global_position, Callable(), true)
		_recal_t -= delta
		_avancer(delta)
		return true
	_but = Vector3.INF
	regarder_vers(e.global_position)
	if _cd <= 0.0:
		_cd = 1.15 if role != "garde" else 0.95
		jouer("1H_Melee_Attack_Chop" if outil != "" else "Unarmed_Melee_Attack_Punch_A", 0.08, 1.2, 0.6)
		var cible_e := e
		get_tree().create_timer(0.35).timeout.connect(func():
			if is_instance_valid(cible_e) and is_instance_valid(self) and not est_mort and not cible_e.get("est_mort") and global_position.distance_to(cible_e.global_position) < portee + 1.0:
				cible_e.recevoir({"montant": force * randf_range(0.8, 1.2), "source": self})
				if not _loin:
					Sons.jouer("coup_os" if outil == "" else "taille", cible_e.global_position, -6.0, randf_range(0.9, 1.2)))
	elif verrou_anim <= 0.0:
		jouer("2H_Melee_Idle" if outil != "" else "Idle", 0.2)
	return true

func recevoir(d: Dictionary) -> void:
	if est_mort or cache or arrete:
		return
	var s = d.get("source", null)
	# un voleur recherché que les gardes rattrapent n'est pas tué : il est arrêté
	if s is Villageois and s.role == "garde" and has_meta("recherche") and pv - d.get("montant", 0.0) < pv_max * 0.35:
		arreter(s.colonie.cachot if s.colonie else global_position)
		return
	super.recevoir(d)
	if est_mort or s == null or not is_instance_valid(s) or s == self:
		return
	reponse = 6.0
	if Village.moi:
		Village.moi.agression(s, self)
	if controle:
		return
	if role == "garde" or pantin or (s is Villageois and randf() < 0.35 and not enfant):
		if etat != "combat" and not (pantin and ordre.get("id", "") == "attaquer"):
			if pantin:
				ordre = {"id": "attaquer", "cible": s, "retour": ordre.duplicate()}
				cible_combat = s
			else:
				attaquer(s)
	elif etat != "fuite":
		fuir(s.global_position)

## Pris par les gardes : il lâche son butin et file au cachot ; un pantin arrêté est perdu.
func arreter(cachot: Vector3) -> void:
	arrete = true
	remove_meta("recherche")
	butin = {}
	_deposer()
	etat = "arrete"
	cible_combat = null
	if pantin:
		Jeu.notifier("%s, ton pantin, a été arrêté ! Le lien est rompu." % nom, Color("#FF6A5A"))
		Pantins.perdu(self)
		pantin = false
		maitre = null
		remove_from_group("pantin")
		_montrer_aura(false)
	if controle and Pouvoirs.moi:
		Pouvoirs.moi.rompre_controle()
	for g in get_tree().get_nodes_in_group("villageois"):
		if g.role == "garde" and g.cible_combat == self:
			g.cible_combat = null
			g.etat = "routine"
			g._reprendre()
	dire("Je me rends !", 2.5)
	_maj_etiquette()
	aller(cachot, func():
		_rentrer()
		get_tree().create_timer(120.0).timeout.connect(func():
			if is_instance_valid(self):
				arrete = false
				etat = "routine"
				_sortir()
				global_position = _porte_maison()
				_maj_etiquette()
				_reprendre()))

func fuir(depuis: Vector3) -> void:
	if est_mort or controle or arrete:
		return
	var v := global_position - depuis
	v.y = 0
	v = v.normalized() if v.length() > 0.1 else Vector3(1, 0, 0)
	etat = "fuite"
	_tache_t = 7.0
	_deposer()
	dire(["À l'aide !", "Au secours !", "Gardes ! Gardes !"][randi() % 3], 2.5)
	aller(NavMonde.point_libre(global_position + v * 14.0), Callable(), true)

func _mourir() -> void:
	super._mourir()
	etat = "mort"
	_but = Vector3.INF
	_deposer()
	if _recolte:
		_recolte["reserve"] = false
	if not _loin:
		jouer("Death_A", 0.1, 1.0, 999.0)
	_etiquette.text = nom + "\n(mort)"
	_etiquette.modulate = Color("#B0A090")
	if _aura:
		_aura.visible = false
	remove_from_group("villageois")
	add_to_group("depouilles_villageois")
	add_to_group("interactif")
	parle = Callable()
	if Village.moi:
		Village.moi.deces(self)
	if pantin:
		Jeu.notifier("%s, ton pantin, est mort. Une Robe de résurrection peut le ramener." % nom, Color("#D9B8FF"))
		Pantins.perdu(self)
	# le corps reste un moment, puis la famille l'emporte
	get_tree().create_timer(150.0).timeout.connect(func():
		if is_instance_valid(self) and est_mort:
			if Village.moi:
				Village.moi.renaitre_plus_tard(self)
			else:
				queue_free())

# --- parler (chef, marchands) ; un mort peut être ramené (Robe de résurrection) : il devient ton pantin fidèle ---

var parle := Callable()
var rayon_action := 3.2
var texte_parole := "Parler"

func activer_parole(f: Callable, texte := "Parler") -> void:
	parle = f
	texte_parole = texte
	add_to_group("interactif")

func texte_action() -> String:
	return "Ressusciter" if est_mort else texte_parole

func disponible() -> bool:
	if Jeu.joueur == null:
		return false
	if not est_mort:
		return parle.is_valid() and not controle and not cache and etat != "combat" and (Pouvoirs.moi == null or Pouvoirs.moi.controle == null)
	return Jeu.joueur.sac.compter("robe_resurrection") > 0

func interagir(h) -> void:
	if not est_mort:
		if parle.is_valid():
			regarder_vers(h.global_position)
			parle.call(h)
		return
	for o in h.sac.objets.duplicate():
		if o["id"] == "robe_resurrection":
			h.sac.retirer(o, 1)
			break
	ressusciter(h)

func ressusciter(h) -> void:
	est_mort = false
	pv = pv_max
	remove_from_group("depouilles_villageois")
	remove_from_group("interactif")
	add_to_group("villageois")
	_maj_etiquette()
	Effets.onde(get_parent(), global_position, 3.0, Color(1.0, 0.85, 0.5))
	Effets.etincelles(get_parent(), global_position + Vector3(0, 1, 0), Vector3.UP, Color(1.0, 0.85, 0.5), 30, 5.0, "star_06.png", 0.4)
	Sons.jouer("cloche", global_position, 0.0, 1.2)
	jouer("Lie_StandUp", 0.1, 1.0, 1.6)
	verrou_anim = 1.6
	Jeu.notifier("%s se relève, et te doit la vie. Il sera ton pantin à jamais." % nom, Color("#FFE2A0"))
	if Pantins.moi:
		Pantins.moi.ajouter(self, true)
