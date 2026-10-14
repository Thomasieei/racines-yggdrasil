class_name Pantins
extends CanvasLayer
## Tes pantins : des habitants qui obéissent à tes ordres sans que tu quittes ton corps.
## À gauche de l'écran, un médaillon par pantin ; on le touche pour donner un ordre.
##   Suis-moi · Coupe du bois · Mine · Cambriole… · Attaque… · Monte la garde · Prends son corps · Libère-le
## Ce qu'ils récoltent file dans ton coffre ; ce qu'ils volent, ils te l'apportent en mains propres.

const MAX := 3
const HUD := preload("res://scripts/interface/hud.gd")

static var moi: Pantins

var liste: Array = []
var racine: Control
var _medaillons: Control
var _panneau: Control
var _choisi: Villageois
var _depots := {}
var _depot_t := 0.0
var _ui: Node

func _ready() -> void:
	moi = self
	layer = 5
	racine = Control.new()
	racine.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(racine)
	_medaillons = Control.new()
	_medaillons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.add_child(_medaillons)
	_ui = HUD.new()

func _exit_tree() -> void:
	if moi == self:
		moi = null
	if _ui:
		_ui.free()

# ---------------- liste ----------------

func plein() -> bool:
	_nettoyer()
	return liste.size() >= MAX

func ajouter(v: Villageois, force := false) -> bool:
	_nettoyer()
	if liste.has(v):
		return true
	if liste.size() >= MAX and not force:
		return false
	v.devenir_pantin(Jeu.joueur)
	liste.append(v)
	_sauver()
	_maj()
	return true

func retirer(v: Villageois) -> void:
	liste.erase(v)
	if is_instance_valid(v) and v.pantin:
		v.liberer_pantin()
	_sauver()
	_maj()

static func perdu(v: Villageois) -> void:
	if moi:
		moi.liste.erase(v)
		moi._sauver()
		moi._maj()

func _nettoyer() -> void:
	liste = liste.filter(func(v): return is_instance_valid(v) and not v.est_mort and v.pantin)

func _sauver() -> void:
	var l: Array = []
	for v in liste:
		if is_instance_valid(v) and v.colonie:
			l.append([v.colonie.id, v.nom])
	Profil.p().vus["pantins"] = l
	Profil.p()._marquer()

## Au chargement : on retrouve ses pantins (par leur nom, dans leur village).
func restaurer() -> void:
	var l: Array = Profil.p().vus.get("pantins", [])
	if Village.moi == null:
		return
	for e in l:
		for v in Village.moi.habitants:
			if is_instance_valid(v) and v.colonie and v.colonie.id == e[0] and v.nom == e[1] and not v.pantin:
				ajouter(v, true)
				break
	_maj()

# ---------------- dépôts (récoltes des pantins) ----------------

static func deposer(v: Villageois, res: String, n: int) -> void:
	var c: Dictionary = Profil.p().coffre
	var fusion := false
	for o in c["objets"]:
		if o["id"] == res and o["qte"] < 999:
			o["qte"] += n
			fusion = true
			break
	if not fusion:
		var obj := Objets.creer(res, "commun", n)
		obj["pile"] = 999
		c["objets"].append(obj)
	Profil.p()._marquer()
	if moi:
		moi._depots[res] = moi._depots.get(res, 0) + n
		moi._depots["qui"] = v.nom

func _process(delta: float) -> void:
	_depot_t -= delta
	if _depot_t <= 0.0:
		_depot_t = 12.0
		var l: Array = []
		for r in ["bois", "pierre"]:
			if _depots.get(r, 0) > 0:
				l.append("+%d %s" % [_depots[r], r])
		if not l.is_empty():
			Jeu.notifier("Tes pantins ont rapporté %s (au coffre)" % ", ".join(l), Color("#D9B8FF"))
		_depots = {}
	if Engine.get_process_frames() % 20 == 0:
		_maj_textes()

# ---------------- ordres ----------------

func ordonner(v: Villageois, o: Dictionary) -> void:
	if not is_instance_valid(v) or v.est_mort:
		return
	v.ordre = o
	v.etat = "ordre"
	v.cible_combat = null
	v._but = Vector3.INF
	v._tache = ""
	v._deposer()
	v._maj_etiquette()
	match o["id"]:
		"suivre":
			v.dire("Je te suis.", 2.0)
		"bois":
			v._tenir("hache")
			v.dire("Je vais abattre ce qu'il faut.", 2.5)
		"pierre":
			v._tenir("pioche")
			v.dire("La pierre, ça me connaît.", 2.5)
		"voler":
			v._tenir("")
			v.dire("Personne ne me verra.", 2.5)
		"attaquer":
			v.dire("À tes ordres.", 2.0)
		"garder":
			v.dire("Rien ne passera.", 2.0)
	Sons.jouer("verre_leger", v.global_position, -6.0, 0.8)
	_maj()

## Une image de comportement pour un pantin (appelé par le pantin lui-même).
static func executer(v: Villageois, delta: float) -> void:
	var o: Dictionary = v.ordre
	var h = Jeu.joueur
	match o.get("id", "suivre"):
		"suivre":
			_suivre(v, h, delta)
		"bois", "pierre":
			if v.en_route():
				v._avancer(delta)
			elif v._tache == "abattre" or v._tache == "pause":
				v._faire(delta)
			else:
				v._recolter("arbre" if o["id"] == "bois" else "rocher", o.get("centre", v.global_position), 34.0, true)
		"voler":
			_voler(v, h, delta)
		"attaquer":
			v.cible_combat = o.get("cible")
			if not v._frapper_cible(delta):
				v.cible_combat = null
				var suite: Dictionary = o.get("retour", {"id": "suivre"})
				if suite.get("id", "") == "attaquer" or suite.is_empty():
					suite = {"id": "suivre"}
				v.ordre = suite
				v._maj_etiquette()
		"garder":
			var e := _ennemi_proche(v.global_position, 10.0, v)
			if e:
				v.ordre = {"id": "attaquer", "cible": e, "retour": o}
				return
			if v.global_position.distance_to(o["pos"]) > 1.5:
				if not v.en_route():
					v.aller(o["pos"])
				v._avancer(delta)
			else:
				v.jouer("2H_Melee_Idle" if v.outil != "" else "Idle", 0.3)

static func _ennemi_proche(p: Vector3, r: float, v: Villageois) -> Node3D:
	var meilleur: Node3D = null
	var dmin := r
	for e in v.get_tree().get_nodes_in_group("monstre"):
		if e.est_mort or (e is Draugr and e.etat == "dort" and e.fiche.get("enterre", false)):
			continue
		var d: float = e.global_position.distance_to(p)
		if d < dmin:
			dmin = d
			meilleur = e
	return meilleur

static func _suivre(v: Villageois, h, delta: float) -> void:
	if h == null or not is_instance_valid(h) or h.est_mort:
		v.jouer("Idle", 0.3)
		return
	# il défend son maître : le premier ennemi qui approche y passe
	var e := _ennemi_proche(h.global_position, 11.0, v)
	if e:
		v.ordre = {"id": "attaquer", "cible": e, "retour": {"id": "suivre"}}
		return
	var idx: int = moi.liste.find(v) if moi else 0
	var a: float = h.rotation.y + PI + (idx - 1) * 0.75
	var place: Vector3 = h.global_position + Vector3(sin(a), 0, cos(a)) * 2.6
	var d: float = v.global_position.distance_to(h.global_position)
	if d > 60.0:
		# trop loin (téléportation, autre bout du monde) : il te rejoint d'un bond d'âme
		Effets.onde(v.get_parent(), v.global_position, 2.0, Color(0.75, 0.45, 1.0))
		v.global_position = NavMonde.point_libre(place)
		v._but = Vector3.INF
		Effets.onde(v.get_parent(), v.global_position, 2.0, Color(0.75, 0.45, 1.0))
		return
	if v.global_position.distance_to(place) > 2.2:
		v._recal_t -= delta
		if not v.en_route() or v._recal_t <= 0.0:
			v._recal_t = 0.7
			v.aller(place, Callable(), d > 6.0)
		v._avancer(delta)
	else:
		v._but = Vector3.INF
		if v.verrou_anim <= 0.0:
			v.jouer("Idle", 0.3)

## Cambriolage : aller à la porte, entrer, fouiller, ressortir… et te rapporter le butin sans se faire voir.
static func _voler(v: Villageois, h, delta: float) -> void:
	var o: Dictionary = v.ordre
	var m: Dictionary = o.get("maison", {})
	match o.get("phase", "aller"):
		"aller":
			if not o.get("parti", false):
				o["parti"] = true
				v.aller(m["porte"], func():
					o["phase"] = "dedans"
					o["t"] = 5.0 if m["genre"] != "marche" else 3.5
					if m["genre"] != "marche":
						v._rentrer()
					else:
						v.jouer("Interact", 0.2))
			v._avancer(delta)
		"dedans":
			o["t"] -= delta
			if o["t"] <= 0.0:
				v._sortir()
				v.butin = butin_maison(m)
				m["videe"] = Time.get_ticks_msec() + 600000
				var r_vue := 13.0 if m["genre"] != "marche" else 18.0
				if m["genre"] == "chateau":
					r_vue = 26.0
				var vu: Villageois = Village.moi.temoin(v.global_position, r_vue, v) if Village.moi else null
				if vu:
					Village.moi.alerte_vol(v, v.global_position, vu)
					v.dire("Oups…", 1.5)
					Jeu.notifier("%s s'est fait repérer ! Qu'il te rejoigne vite…" % v.nom, Color("#FF9C8A"))
				else:
					Jeu.notifier("%s a cambriolé %s sans être vu. Il te rapporte le butin." % [v.nom, _nom_lieu(m)], Color("#D9B8FF"))
				o["phase"] = "retour"
				o["parti"] = false
		"retour":
			if h == null or not is_instance_valid(h):
				return
			var d: float = v.global_position.distance_to(h.global_position)
			if d < 3.2:
				var b: Dictionary = v.butin
				v.butin = {}
				if v.has_meta("recherche"):
					v.remove_meta("recherche")
				if not b.is_empty():
					h.ramasser(b, "le vol de " + v.nom)
					Profil.p().compter("vols")
				v.dire("Pour toi, maître.", 2.0)
				v.ordre = {"id": "suivre"}
				v._maj_etiquette()
				if moi:
					moi._maj()
				return
			if d > 140.0:
				# trop loin : il cache le butin dans ton coffre
				for ob in v.butin.get("objets", []):
					Profil.p().coffre["objets"].append(ob)
				h.sac.ajouter_or(v.butin.get("or", 0))
				v.butin = {}
				v.ordre = {"id": "suivre"}
				return
			v._recal_t -= delta
			if not v.en_route() or v._recal_t <= 0.0:
				v._recal_t = 1.0
				v.aller(h.global_position, Callable(), true)
			v._avancer(delta)

static func _nom_lieu(m: Dictionary) -> String:
	if m.get("nom", "") != "":
		return m["nom"]
	return "la maison " + m.get("famille", "")

## Ce qu'on trouve dans un lieu, selon ce qu'il est.
static func butin_maison(m: Dictionary) -> Dictionary:
	var g: String = m.get("genre", "maison")
	var b := {"or": 0, "objets": []}
	match g:
		"chateau":
			b["or"] = randi_range(600, 1500)
			b["objets"].append(Objets.creer("relique", Objets.tirer_rarete([0.1, 0.35, 0.35, 0.16, 0.04])))
			if randf() < 0.5:
				b["objets"].append(Objets.creer("lingot_or", "commun", randi_range(3, 8)))
			if randf() < 0.25:
				b["objets"].append(Objets.creer("robe_resurrection", "legendaire"))
		"forge":
			b["or"] = randi_range(40, 160)
			b["objets"].append(Objets.creer(Objets.ARMES[randi() % Objets.ARMES.size()], Objets.tirer_rarete([0.4, 0.4, 0.16, 0.04, 0])))
		"marche":
			b["or"] = randi_range(120, 380)
			if randf() < 0.5:
				b["objets"].append(Objets.creer(["tissu", "potion", "lingot_or"].pick_random(), "commun", randi_range(1, 4)))
		"taverne":
			b["or"] = randi_range(60, 220)
			b["objets"].append(Objets.creer("potion", "commun", randi_range(1, 3)))
		"temple":
			b["or"] = randi_range(100, 300)
			if randf() < 0.3:
				b["objets"].append(Objets.creer("robe_resurrection", "legendaire"))
		_:
			b["or"] = randi_range(25, 140)
			if randf() < 0.35:
				b["objets"].append(Objets.creer("potion", "commun", randi_range(1, 2)))
			if randf() < 0.25:
				b["objets"].append(Objets.creer(["tissu", "bois", "lingot_or"].pick_random(), "commun", randi_range(1, 3)))
			if randf() < 0.08:
				b["objets"].append(Objets.creer("robe_resurrection", "legendaire"))
			if randf() < 0.06:
				b["objets"].append(Objets.creer("relique", Objets.tirer_rarete([0.6, 0.3, 0.09, 0.01, 0])))
			if randf() < 0.02:
				b["objets"].append(Objets.creer("oeuf", Objets.tirer_rarete([0.6, 0.3, 0.08, 0.02, 0])))
	return b

# ---------------- interface ----------------

func _maj() -> void:
	_nettoyer()
	for c in _medaillons.get_children():
		c.queue_free()
	var y := 232.0
	for v in liste:
		var b: Control = _ui.neuf(HUD.UI + "rpg/panel_brown.png", 10, Vector2(176, 50), Vector2(10, y), _medaillons)
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		b.modulate = Color(0.95, 0.88, 1.0)
		_ui.disque(Vector2(6, 7), 36, Color(0.45, 0.25, 0.65), b)
		_ui.texte(v.nom.left(1), 20, Color("#F6E9FF"), Vector2(6, 11), b, true, 36, HORIZONTAL_ALIGNMENT_CENTER)
		_ui.texte(v.nom, 14, Color("#FFF4DC"), Vector2(48, 5), b, true, 124)
		var l: Label = _ui.texte(v._texte_ordre().replace("pantin · ", ""), 11, Color("#E2CCFF"), Vector2(48, 25), b, true, 124)
		l.name = "Ordre"
		b.set_meta("v", v)
		var vv: Villageois = v
		b.gui_input.connect(func(ev):
			if _appui(ev):
				ouvrir(vv))
		y += 56.0

func _maj_textes() -> void:
	for b in _medaillons.get_children():
		var v = b.get_meta("v") if b.has_meta("v") else null
		var l = b.get_node_or_null("Ordre")
		if l and is_instance_valid(v):
			l.text = v._texte_ordre().replace("pantin · ", "")

func _appui(ev) -> bool:
	return (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed)

func fermer() -> void:
	if _panneau:
		_panneau.queue_free()
		_panneau = null
	Jeu.interface_bloquante = false

func ouvrir(v: Villageois) -> void:
	fermer()
	if not is_instance_valid(v) or v.est_mort:
		return
	_choisi = v
	Jeu.interface_bloquante = true
	_panneau = Control.new()
	_panneau.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panneau.mouse_filter = Control.MOUSE_FILTER_STOP
	racine.add_child(_panneau)
	var voile := ColorRect.new()
	voile.color = Color(0.03, 0.01, 0.06, 0.6)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panneau.add_child(voile)
	voile.gui_input.connect(func(ev): if _appui(ev): fermer())
	var p: Control = _ui.neuf(HUD.UI + "rpg/panel_beige.png", 18, Vector2(700, 420), Vector2(290, 70), _panneau)
	_ui.texte("Ton pantin : " + v.nom, 24, HUD.ENCRE, Vector2(24, 16), p, false)
	_ui.texte(v.metier + (" · " + v.colonie.nom if v.colonie else "") + "  ·  PV %d / %d" % [int(v.pv), int(v.pv_max)], 13, HUD.ENCRE2, Vector2(24, 50), p, false)
	var ordres := [
		["Suis-moi", "Il te suit et te défend.", func(): ordonner(v, {"id": "suivre"})],
		["Coupe du bois", "Abat les arbres d'ici : le bois va dans ton coffre.", func(): ordonner(v, {"id": "bois", "centre": v.global_position})],
		["Mine la pierre", "Casse les rochers d'ici : la pierre va dans ton coffre.", func(): ordonner(v, {"id": "pierre", "centre": v.global_position})],
		["Cambriole…", "Choisis une maison, une échoppe, le château…", func(): _choix_vol(v)],
		["Attaque…", "Choisis qui il doit frapper.", func(): _choix_cible(v)],
		["Monte la garde", "Il reste ici et défend l'endroit.", func(): ordonner(v, {"id": "garder", "pos": v.global_position})],
		["Prends son corps", "Tu marches à sa place (60 s).", func():
			fermer()
			if Pouvoirs.moi:
				Pouvoirs.moi.prendre_corps(v)],
		["Libère-le", "Il redevient lui-même.", func(): retirer(v)],
	]
	var i := 0
	for o in ordres:
		var col := i % 2
		var lig := i / 2
		var b: Control = _ui.neuf(HUD.UI + "rpg/buttonLong_" + ("brown" if i < 6 else "beige") + ".png", 12, Vector2(318, 62), Vector2(24 + col * 334, 82 + lig * 74), p)
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		_ui.texte(o[0], 17, Color("#FFF4DC") if i < 6 else HUD.ENCRE, Vector2(14, 8), b, i < 6, 290)
		_ui.texte(o[1], 11, Color("#F2DFC0") if i < 6 else HUD.ENCRE2, Vector2(14, 34), b, false, 296)
		var f: Callable = o[2]
		b.gui_input.connect(func(ev):
			if _appui(ev):
				f.call()
				if _panneau and o[0] != "Cambriole…" and o[0] != "Attaque…":
					fermer())
		i += 1

func _liste_choix(titre: String, elements: Array, quoi: Callable) -> void:
	if _panneau:
		_panneau.queue_free()
	_panneau = Control.new()
	_panneau.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panneau.mouse_filter = Control.MOUSE_FILTER_STOP
	racine.add_child(_panneau)
	var voile := ColorRect.new()
	voile.color = Color(0.03, 0.01, 0.06, 0.6)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panneau.add_child(voile)
	voile.gui_input.connect(func(ev): if _appui(ev): fermer())
	var p: Control = _ui.neuf(HUD.UI + "rpg/panel_beige.png", 18, Vector2(700, 440), Vector2(290, 60), _panneau)
	_ui.texte(titre, 22, HUD.ENCRE, Vector2(24, 16), p, false)
	if elements.is_empty():
		_ui.texte("Rien à portée.", 15, HUD.ENCRE2, Vector2(24, 70), p, false)
	var y := 58.0
	for e in elements.slice(0, 6):
		var b: Control = _ui.neuf(HUD.UI + "rpg/buttonLong_beige.png", 12, Vector2(652, 54), Vector2(24, y), p)
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		_ui.texte(e[0], 16, HUD.ENCRE, Vector2(16, 7), b, false, 620)
		_ui.texte(e[1], 11, HUD.ENCRE2, Vector2(16, 31), b, false, 620)
		var cible = e[2]
		b.gui_input.connect(func(ev):
			if _appui(ev):
				fermer()
				quoi.call(cible))
		y += 60.0

func _choix_vol(v: Villageois) -> void:
	var l: Array = []
	for porte in get_tree().get_nodes_in_group("portes"):
		var m: Dictionary = porte.maison
		if v.maison == m:
			continue
		var d: float = v.global_position.distance_to(m["porte"])
		if d > 140.0:
			continue
		var vide: bool = m.get("videe", 0) > Time.get_ticks_msec()
		var risque: String = {"chateau": "très gardé !", "marche": "risqué : on te voit de loin", "forge": "armes", "temple": "offrandes", "taverne": "la caisse"}.get(m["genre"], "")
		l.append([_nom_lieu(m).capitalize() + "  ·  %d m" % int(d), ("déjà vidé" if vide else risque), m, d + (500.0 if vide else 0.0)])
	l.sort_custom(func(a, b): return a[3] < b[3])
	_liste_choix("Que doit cambrioler " + v.nom + " ?", l, func(m): ordonner(v, {"id": "voler", "maison": m, "phase": "aller"}))

func _choix_cible(v: Villageois) -> void:
	var l: Array = []
	for e in get_tree().get_nodes_in_group("combattants"):
		if e == v or e == Jeu.joueur or e.est_mort or e.get("pantin") == true:
			continue
		if not (e is Villageois or e is Draugr):
			continue
		var d: float = v.global_position.distance_to(e.global_position)
		if d > 45.0:
			continue
		var nom_e: String = e.nom + " · " + e.metier if e is Villageois else e.nom_affiche()
		l.append([nom_e, "%d m · PV %d" % [int(d), int(e.pv)], e, d])
	l.sort_custom(func(a, b): return a[3] < b[3])
	_liste_choix("Qui doit attaquer " + v.nom + " ?", l, func(e): ordonner(v, {"id": "attaquer", "cible": e, "retour": {"id": "suivre"}}))
