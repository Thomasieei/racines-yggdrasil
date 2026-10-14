class_name Bourgs
extends RefCounted
## Bâtit les lieux habités du Val : Hameau de Brekka, Jarnborg la capitale, Vik du Lac,
## le Fort de Hrafn et le camp de Skarn (hostiles), la carrière, les Pierres d'Odin, la Tour du Guet.
## Chaque maison a sa porte tournée vers la rue ; les rues sont peintes dans le masque du sol.

const H := "res://assets/surface/hexa/"
const HW := "res://assets/halloween/"
const R := "res://assets/surface/ressources/"
const DJ := "res://assets/donjon/"
const F := "res://assets/surface/foret/"
const O := "res://assets/surface/outils/"

var c: CarteSurface
var rng := RandomNumberGenerator.new()
var colonies: Array = []
var _occupe: Array = []         ## [centre Vector2, rayon]

const PRENOMS_H := ["Arne", "Bjorn", "Einar", "Eirik", "Gorm", "Gunnar", "Halfdan", "Harald", "Ivar", "Knut", "Leif", "Magnus", "Njal", "Olaf",
	"Ragnar", "Rolf", "Sigvald", "Snorri", "Sten", "Svend", "Thorkel", "Toke", "Ulf", "Vidar", "Yngvar", "Asger", "Frode", "Grim", "Hakon", "Ketil"]
const PRENOMS_F := ["Astrid", "Bodil", "Dagmar", "Estrid", "Freydis", "Gyda", "Helga", "Inga", "Jorunn", "Ragna", "Ragnhild", "Signe", "Sigrun",
	"Solveig", "Thora", "Thyra", "Tove", "Ulfhild", "Valdis", "Yrsa", "Alfhild", "Borghild", "Eydis", "Gunnhild", "Hild", "Liv", "Ronja", "Sassa"]
const NOMS := ["Ulfsson", "Haraldsson", "Ketilsson", "Grimsson", "Bjarnason", "Ormsson", "Hallsson", "Thorsson", "Eiriksson", "Leifsson",
	"Gunnarsson", "Sveinsson", "Hakonsson", "Arnason", "Steinsson", "Ragnarsson", "Ivarsson", "Knutsson", "Olafsson", "Vidarsson"]

func construire(carte: CarteSurface) -> void:
	c = carte
	rng.seed = 90210
	_routes()
	_brekka()
	_jarnborg()
	_vik()
	_hrafn()
	_skarn()
	_carriere()
	_pierres()
	_tour()

# =================== briques ===================

func prenom(femme: bool) -> String:
	return (PRENOMS_F if femme else PRENOMS_H)[rng.randi() % (PRENOMS_F if femme else PRENOMS_H).size()]

func nom_famille() -> String:
	return NOMS[rng.randi() % NOMS.size()]

func libre(p: Vector2, r: float) -> bool:
	for o in _occupe:
		if p.distance_to(o[0]) < r + o[1]:
			return false
	return true

func occuper(p: Vector2, r: float) -> void:
	_occupe.append([p, r])

## Pose un bâtiment dont la porte regarde `dir` ; l'enregistre dans la colonie.
func batiment(col: Colonie, chemin: String, p: Vector2, dir: Vector2, ech: float, genre: String, nom := "", famille := "") -> Dictionary:
	dir = dir.normalized()
	var rot := rad_to_deg(atan2(dir.x, dir.y))
	var n := c.poser(chemin, Vector3(p.x, 0, p.y), rot, ech, "boite")
	var prof := 3.0
	var larg := 3.0
	if n:
		var b := c.boite_locale(n)
		prof = b.end.z
		larg = maxf(b.size.x, b.size.z) * 0.5
		c.fondu_ajouter(n, larg)
	occuper(p, larg)
	var porte := Vector3(p.x, 0, p.y) + Vector3(dir.x, 0, dir.y) * (prof + 1.1)
	var m := {"pos": Vector3(p.x, 0, p.y), "rot": rot, "porte": porte, "dir": Vector3(dir.x, 0, dir.y), "genre": genre,
		"nom": nom, "famille": famille, "habitants": [], "colonie": col.id, "chemin": chemin, "ech": ech}
	if col:
		col.maisons.append(m)
	return m

## Maisons alignées le long d'une rue (polyligne), d'un côté (+1 gauche / -1 droite), portes vers la rue.
func rangee(col: Colonie, pts: Array, cote: int, couleur: String, recul := 5.2, pas := 7.6, proba := 0.85, eviter: Array = []) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var l := a.distance_to(b)
		var u := (b - a) / l
		var nrm := Vector2(-u.y, u.x) * cote
		var t := pas * 0.6
		while t < l - pas * 0.4:
			var q := a + u * t + nrm * recul
			var ok := rng.randf() < proba and libre(q, 3.0)
			for e in eviter:
				if q.distance_to(e[0]) < e[1]:
					ok = false
			if ok:
				var mod := "building_home_%s_%s" % ["A" if rng.randf() < 0.55 else "B", couleur]
				var femme := rng.randf() < 0.5
				batiment(col, H + "buildings/%s/%s.gltf" % [couleur, mod], q, -nrm, rng.randf_range(5.6, 6.3), "maison", "", nom_famille())
				# un petit quelque chose devant certaines portes
				if rng.randf() < 0.35:
					var d := q - nrm * 1.2 + u * rng.randf_range(2.2, 2.8) * (1 if rng.randf() < 0.5 else -1)
					c.poser(H + "decoration/props/" + ["barrel", "crate_A_small", "sack", "bucket_water", "crate_B_small"][rng.randi() % 5] + ".gltf", Vector3(d.x, 0, d.y), rng.randf_range(0, 360), 5.0)
			t += pas

func rue(pts: Array, largeur: float, canal := 1) -> void:
	PlanMonde.ligne(pts, largeur, canal, 1.0, 2.0)

func lanterne(p: Vector3, lumineuse := true) -> void:
	c.poser(HW + "post_lantern.gltf", p, rng.randf_range(0, 360), 1.0, "tronc")
	if lumineuse:
		c.lumiere(p + Vector3(0, 3.1, 0.4), Color(1.0, 0.78, 0.45), 1.3, 9.0)

## Rempart de pierre entre a et b ; `portes` = positions (0..1) le long du mur, chaque porte fait 10 m.
func rempart(a: Vector3, b: Vector3, portes: Array, bas := false) -> void:
	var l := a.distance_to(b)
	var u := (b - a) / l
	var coupes: Array = [0.0]
	for pp in portes:
		coupes.append(pp * l - 5.0)
		coupes.append(pp * l + 5.0)
	coupes.append(l)
	for k in range(0, coupes.size() - 1):
		var est_porte := k % 2 == 1
		var d0: float = coupes[k]
		var d1: float = coupes[k + 1]
		if d1 - d0 < 0.5:
			continue
		var n := 1 if est_porte else maxi(1, int(round((d1 - d0) / 10.0)))
		var pas := (d1 - d0) / n
		for i in n:
			_mur(a + u * (d0 + pas * (i + 0.5)), u, pas, est_porte, bas)

func _mur(p: Vector3, u: Vector3, pas: float, porte: bool, bas: bool) -> void:
	var rot := rad_to_deg(atan2(u.z, u.x)) * -1.0
	var modele := "wall_straight_gate" if porte else "wall_straight"
	var bas_ici := bas and not porte
	var mur := c.poser(H + "buildings/neutral/%s.gltf" % modele, p, rot, Vector3(5.0 * pas / 10.0, 5.0 if not bas_ici else 2.3, 3.0))
	if mur and not bas_ici:
		c.fondu_ajouter(mur, pas * 0.5)
	var haut := 5.5 if not bas_ici else 2.5
	var basis := Basis(Vector3.UP, deg_to_rad(rot))
	if not porte:
		c.boite_collision(p + Vector3(0, haut / 2, 0), Vector3(pas, haut, 2.4), deg_to_rad(rot))
	else:
		for s in [-1.0, 1.0]:
			c.boite_collision(p + basis * Vector3(s * (pas / 2.0 - 1.0), haut / 2, 0), Vector3(2.0, haut, 2.4), deg_to_rad(rot))

func palissade(a: Vector3, b: Vector3, portes: Array) -> void:
	var l := a.distance_to(b)
	var n := maxi(1, int(round(l / 5.6)))
	var pas := l / n
	var u := (b - a) / l
	var rot := rad_to_deg(atan2(u.z, u.x)) * -1.0 + 90.0
	for i in n:
		var t := (i + 0.5) / n
		var porte := false
		for pp in portes:
			if absf(t - pp) < 0.75 / n:
				porte = true
		if porte:
			continue
		var p := a.lerp(b, t)
		# le modèle est posé sur le bord d'un hexagone : on le recentre sur la ligne
		var decal := Basis(Vector3.UP, deg_to_rad(rot)) * Vector3(1.05 * 5.0, 0, 0)
		c.poser(H + "buildings/neutral/fence_wood_straight.gltf", p + decal, rot, Vector3(5.0, 5.0, pas / 1.155))
		c.boite_collision(p + Vector3(0, 1.5, 0), Vector3(0.8, 3.0, pas), deg_to_rad(rot))

func tour(p: Vector3, couleur: String, modele := "tower_A", ech := 4.6) -> void:
	var t := c.poser(H + "buildings/%s/building_%s_%s.gltf" % [couleur, modele, couleur], p, rng.randf_range(0, 360), ech, "boite")
	if t:
		c.fondu_ajouter(t, 3.0)
	occuper(Vector2(p.x, p.z), 3.0)

## Bannière sur un poteau (les bannières du donjon, aux couleurs du lieu).
func drapeau(p: Vector3, couleur: String, ech := 1.0) -> void:
	var nom: String = {"blue": "banner_patternA_blue", "red": "banner_patternA_red", "green": "banner_patternA_green"}.get(couleur, "banner_blue")
	c.poser(DJ + nom + ".glb", p, 180.0, ech * 1.3)

func arbre(p: Vector2, ech := 5.5) -> void:
	if not libre(p, 1.5):
		return
	c.poser(H + "decoration/nature/" + ["tree_single_A", "tree_single_B"][rng.randi() % 2] + ".gltf", Vector3(p.x, 0, p.y), rng.randf_range(0, 360), ech, "tronc")
	occuper(p, 1.5)

func etal(col: Colonie, p: Vector2, dir: Vector2, couleur: String) -> void:
	var m := batiment(col, H + "buildings/%s/building_market_%s.gltf" % [couleur, couleur], p, dir, 4.6, "marche", "Étal")
	col.poste("marche", m["porte"])

# =================== routes entre les lieux ===================

func _routes() -> void:
	for r in PlanMonde.ROUTES:
		PlanMonde.ligne(r[0], r[1], 0, 1.0, 4.5)
	# bornes et lanternes aux carrefours
	for p in [Vector2(-30, -6), Vector2(-70, 40)]:
		lanterne(Vector3(p.x + 3.5, 0, p.y - 3.5))
		c.poser(F + "Rock_1_D_Color1.gltf", Vector3(p.x - 3.4, 0, p.y + 3.0), 20.0, 1.6, "boite")

# =================== Hameau de Brekka ===================

func _brekka() -> void:
	var col := Colonie.new()
	col.id = "brekka"
	col.nom = "Hameau de Brekka"
	col.rect = PlanMonde.BREKKA
	col.place = PlanMonde.PLACE_BREKKA
	col.feu = col.place + Vector3(0, 0, 4)
	col.cachot = Vector3(127, 0, 30)
	col.nb_gardes = 2
	colonies.append(col)
	var B := H + "buildings/blue/"
	var P := H + "decoration/props/"
	var pl := Vector2(col.place.x, col.place.z)
	# rue principale est-ouest, place au milieu, sortie nord vers la carrière
	rue([Vector2(12, 12), Vector2(92, 12)], 2.4, 0)
	rue([Vector2(46.5, 12), Vector2(46.5, -14)], 2.0, 0)
	PlanMonde.disque(pl, 10.0, 1, 1.0, 3.0)
	PlanMonde.reserver(col.rect)
	occuper(pl, 9.0)
	# les cinq foyers d'origine (le chef Sigurd habite la première)
	var familles := [["building_home_B_blue", Vector2(40, 3), Vector2(0, 1), "Brekka"], ["building_home_A_blue", Vector2(66, 4), Vector2(0, 1), "Hallsdóttir"],
		["building_home_A_blue", Vector2(30, 20), Vector2(0, -1), "Ulfsson"], ["building_home_B_blue", Vector2(76, 20), Vector2(0, -1), "Dagny"]]
	for f in familles:
		batiment(col, B + f[0] + ".gltf", f[1], f[2], 6.4, "maison", "Maison " + f[3], f[3])
	batiment(col, B + "building_tavern_blue.gltf", Vector2(53, -1), Vector2(0, 1), 6.2, "taverne", "Taverne du Hareng", "Taverne")
	# d'autres familles le long de la rue
	for f2 in [[Vector2(22, 4), Vector2(0, 1)], [Vector2(78, 4), Vector2(0, 1)], [Vector2(20, 20), Vector2(0, -1)], [Vector2(86, 20), Vector2(0, -1)], [Vector2(31, 4), Vector2(0, 1)]]:
		batiment(col, B + "building_home_%s_blue.gltf" % ["A", "B"][rng.randi() % 2], f2[0], f2[1], 6.0, "maison", "", nom_famille())
	# travail : moulin et champs à l'ouest, scierie à l'est, chantier au sud
	var moulin := batiment(col, B + "building_windmill_blue.gltf", Vector2(16, -6), Vector2(1, 1), 6.0, "moulin", "Moulin")
	col.poste("moulin", moulin["porte"])
	PlanMonde.rect(Rect2(12, 25, 30, 12), 2, 1.0, 2.0)
	for k in 6:
		col.poste("champs", Vector3(rng.randf_range(15, 39), 0, rng.randf_range(27, 35)))
	occuper(Vector2(27, 31), 8.0)
	var scierie := batiment(col, B + "building_lumbermill_blue.gltf", Vector2(88, -4), Vector2(-1, 1), 6.0, "scierie", "Scierie")
	col.poste("scierie", scierie["porte"])
	col.depot = scierie["porte"]
	c.poser(R + "Wood_Log_Stack.gltf", Vector3(82, 0, -2), 30.0, 1.6, "boite")
	c.poser(R + "Wood_Log_Stack.gltf", Vector3(84.5, 0, 1), 80.0, 1.4, "boite")
	c.poser(H + "buildings/neutral/building_scaffolding.gltf", Vector3(66, 0, 29), 0.0, 5.5, "boite")
	occuper(Vector2(66, 29), 4.0)
	col.poste("chantier", Vector3(63, 0, 26))
	c.poser(B + "building_well_blue.gltf", Vector3(pl.x - 5, 0, pl.y - 3), 0.0, 4.2, "boite")
	c.poser(P + "crate_A_big.gltf", Vector3(58, 0, 4.5), 20.0, 6.0, "boite")
	c.poser(P + "sack.gltf", Vector3(48.5, 0, 4.0), 0.0, 6.0, "boite")
	c.poser(P + "wheelbarrow.gltf", Vector3(36, 0, 24.0), 40.0, 6.0, "boite")
	c.feu_de_camp(col.feu)
	for a in [0.4, 2.0, 3.6, 5.1]:
		var p := col.feu + Vector3(cos(a), 0, sin(a)) * 3.6
		c.poser(HW + "bench.gltf", p, rad_to_deg(-a) + 90.0, 0.9, "boite")
		col.poste("banc", p)
	for p in [Vector3(45, 0, 16), Vector3(61, 0, 16), Vector3(56, 0, 30), Vector3(24, 0, 15), Vector3(84, 0, 15)]:
		lanterne(p)
	c.lumiere(col.place + Vector3(0, 6, 0), Color(1.0, 0.85, 0.6), 1.2, 24.0)
	col.poste("jeux", col.place + Vector3(0, 0, 10))
	col.poste("place", col.place + Vector3(-4, 0, 6))
	col.poste("garde_porte", Vector3(14, 0, 9))
	col.poste("garde_porte", Vector3(90, 0, 9))
	col.rondes = [[Vector3(16, 0, 9), Vector3(53, 0, 9), Vector3(90, 0, 9), Vector3(56, 0, 24), Vector3(46.5, 0, -9)]]
	col.interets = [col.place, moulin["porte"], scierie["porte"], Vector3(53, 0, 4), Vector3(30, 0, 12), Vector3(76, 0, 12)]
	for p2 in [Vector2(14, -10), Vector2(26, -10), Vector2(70, -10), Vector2(92, 30), Vector2(44, 30)]:
		arbre(p2)

# =================== Jarnborg, la capitale ===================

func _jarnborg() -> void:
	var col := Colonie.new()
	col.id = "jarnborg"
	col.nom = "Jarnborg"
	col.rect = PlanMonde.JARNBORG
	col.place = PlanMonde.PLACE_JARNBORG
	col.feu = col.place + Vector3(10, 0, 8)
	col.nb_gardes = 8
	colonies.append(col)
	var r := col.rect
	var B := H + "buildings/blue/"
	var P := H + "decoration/props/"
	PlanMonde.reserver(r.grow(4.0))
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	# --- remparts : hauts au nord, à l'ouest et à l'est ; muret au sud (on voit par-dessus) ---
	rempart(Vector3(x0, 0, z0), Vector3(x1, 0, z0), [])
	rempart(Vector3(x0, 0, z0), Vector3(x0, 0, z1), [])
	rempart(Vector3(x1, 0, z0), Vector3(x1, 0, z1), [inverse_lerp(z0, z1, -150.0)])
	rempart(Vector3(x0, 0, z1), Vector3(x1, 0, z1), [inverse_lerp(x0, x1, -135.0)], true)
	for t in [Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(x0, 0, z1), Vector3(x1, 0, z1)]:
		tour(t, "blue", "tower_A", 5.4)
	for t2 in [Vector3(-143, 0, z1 + 0.5), Vector3(-127, 0, z1 + 0.5), Vector3(x1 + 0.5, 0, -158), Vector3(x1 + 0.5, 0, -142)]:
		tour(t2, "blue", "tower_B", 4.4)
	for t3 in [Vector3(x0, 0, -156), Vector3(-104, 0, z0), Vector3(-166, 0, z0)]:
		tour(t3, "blue", "tower_catapult", 4.6)
	for d in [Vector3(-143, 0, z1 + 3.5), Vector3(-127, 0, z1 + 3.5), Vector3(x1 + 3.5, 0, -158), Vector3(x1 + 3.5, 0, -142)]:
		lanterne(d)
	col.cachot = Vector3(-104, 0, -196)
	# --- rues ---
	var grand_rue := [Vector2(-135, z1 + 4), Vector2(-135, -180)]
	var avenue := [Vector2(x1 + 4, -150), Vector2(x0 + 4, -150)]
	var rue_basse := [Vector2(x0 + 4, -124), Vector2(x1 - 4, -124)]
	var rue_haute := [Vector2(x0 + 4, -178), Vector2(x1 - 4, -178)]
	var artisans := [Vector2(-104, z0 + 6), Vector2(-104, z1 - 4)]
	var temple := [Vector2(-166, z0 + 6), Vector2(-166, z1 - 4)]
	for ru in [grand_rue, avenue, rue_basse, rue_haute, artisans, temple]:
		rue(ru, 2.2 if ru != grand_rue and ru != avenue else 3.0)
	# grand-place pavée, parvis du château
	var pl := Vector2(col.place.x, col.place.z)
	PlanMonde.disque(pl, 15.0, 1, 1.0, 2.0)
	occuper(pl, 15.0)
	PlanMonde.rect(Rect2(-150, -198, 30, 22), 1, 1.0, 1.0)
	# --- le château du jarl et sa cour ---
	var chateau := batiment(col, B + "building_castle_blue.gltf", Vector2(-135, -199), Vector2(0, 1), 7.2, "chateau", "Château du Jarl")
	col.poste("chateau", chateau["porte"])
	drapeau(Vector3(-146, 0, -184), "blue")
	drapeau(Vector3(-124, 0, -184), "blue")
	var caserne := batiment(col, B + "building_barracks_blue.gltf", Vector2(-108, -199), Vector2(0, 1), 6.4, "caserne", "Caserne")
	col.poste("caserne", caserne["porte"])
	var tir := batiment(col, B + "building_archeryrange_blue.gltf", Vector2(-162, -198), Vector2(0, 1), 6.0, "tir", "Champ de tir")
	col.poste("tir", tir["porte"])
	for k in 3:
		c.poser(P + "target.gltf", Vector3(-176 + k * 4, 0, -190), 0.0, 5.0, "boite")
	c.poser(P + "weaponrack.gltf", Vector3(-117, 0, -186), 0.0, 5.5, "boite")
	c.poser(P + "bucket_arrows.gltf", Vector3(-152, 0, -186), 0.0, 5.0)
	# --- grand-place : étals tout autour, puits au centre, taverne au coin ---
	c.poser(B + "building_well_blue.gltf", Vector3(pl.x, 0, pl.y), 0.0, 5.0, "boite")
	for e in [[Vector2(-149, -162), Vector2(1, 1)], [Vector2(-121, -162), Vector2(-1, 1)], [Vector2(-149, -138), Vector2(1, -1)], [Vector2(-121, -138), Vector2(-1, -1)]]:
		etal(col, e[0], e[1], "blue")
	var taverne := batiment(col, B + "building_tavern_blue.gltf", Vector2(-118, -168), Vector2(0, 1), 6.6, "taverne", "Le Corbeau Ivre")
	col.poste("taverne", taverne["porte"])
	var taverne2 := batiment(col, B + "building_tavern_blue.gltf", Vector2(-150, -111), Vector2(1, 0), 6.0, "taverne", "L'Hydromel du Sud")
	col.poste("taverne", taverne2["porte"])
	var eglise := batiment(col, B + "building_church_blue.gltf", Vector2(-178, -136), Vector2(1, 0), 7.0, "temple", "Temple d'Odin")
	col.poste("temple", eglise["porte"])
	var forge := batiment(col, B + "building_blacksmith_blue.gltf", Vector2(-95, -137), Vector2(-1, 0), 6.2, "forge", "Forge royale")
	col.poste("forge", forge["porte"] + Vector3(0, 0, 2.5))
	c.poser(O + "anvil.gltf", forge["porte"] + Vector3(0.6, 0, 2.6), 30.0, 1.2, "boite")
	var forge2 := batiment(col, B + "building_blacksmith_blue.gltf", Vector2(-113, -112), Vector2(1, 0), 5.6, "forge", "Armurerie")
	col.poste("forge", forge2["porte"] + Vector3(0, 0, 2.5))
	var marche := batiment(col, B + "building_market_blue.gltf", Vector2(-95, -165), Vector2(-1, 0), 5.6, "marche", "Halle aux grains")
	col.poste("marche", marche["porte"])
	var scierie := batiment(col, B + "building_lumbermill_blue.gltf", Vector2(-80, -112), Vector2(0, -1), 6.0, "scierie", "Scierie du rempart")
	col.poste("scierie", scierie["porte"])
	col.depot = scierie["porte"]
	c.poser(R + "Wood_Log_Stack.gltf", Vector3(-88, 0, -109), 10.0, 1.6, "boite")
	occuper(Vector2(-88, -109), 2.0)
	# --- maisons le long de toutes les rues ---
	var eviter := [[Vector2(-135, -150), 19.0], [Vector2(-135, -124), 6.0], [Vector2(-104, -124), 6.0], [Vector2(-166, -124), 6.0],
		[Vector2(-104, -150), 6.0], [Vector2(-166, -150), 6.0], [Vector2(-135, -178), 6.0], [Vector2(-104, -178), 6.0], [Vector2(-166, -178), 6.0]]
	rangee(col, rue_basse, 1, "blue", 5.4, 7.6, 0.9, eviter)
	rangee(col, rue_basse, -1, "blue", 5.4, 7.6, 0.9, eviter)
	rangee(col, avenue, 1, "blue", 5.4, 7.6, 0.85, eviter)
	rangee(col, avenue, -1, "blue", 5.4, 7.6, 0.85, eviter)
	rangee(col, rue_haute, 1, "blue", 5.4, 7.6, 0.9, eviter)
	rangee(col, grand_rue, 1, "blue", 5.6, 7.8, 0.9, eviter)
	rangee(col, grand_rue, -1, "blue", 5.6, 7.8, 0.9, eviter)
	rangee(col, artisans, 1, "blue", 5.4, 7.6, 0.75, eviter)
	rangee(col, artisans, -1, "blue", 5.4, 7.6, 0.75, eviter)
	rangee(col, temple, 1, "blue", 5.4, 7.6, 0.75, eviter)
	rangee(col, temple, -1, "blue", 5.4, 7.6, 0.75, eviter)
	# jardins et arbres dans les cœurs d'îlots
	for k in 40:
		arbre(Vector2(rng.randf_range(x0 + 6, x1 - 6), rng.randf_range(z0 + 8, z1 - 6)), rng.randf_range(4.5, 6.0))
	# --- vie : lanternes, marchandises, bannières ---
	for p in [Vector2(-135, -165), Vector2(-135, -135), Vector2(-120, -150), Vector2(-150, -150), Vector2(-135, -112), Vector2(-90, -150), Vector2(-180, -150),
			Vector2(-104, -130), Vector2(-166, -130), Vector2(-135, -185)]:
		lanterne(Vector3(p.x + 2.6, 0, p.y + 2.6), p.distance_to(pl) < 20.0 or p.y < -180.0)
	c.lumiere(col.place + Vector3(0, 7, 0), Color(1.0, 0.85, 0.6), 1.4, 30.0)
	c.feu_de_camp(col.feu)
	for k in 14:
		var q := pl + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(9.0, 13.5)
		if libre(q, 1.0):
			c.poser(P + ["crate_A_big", "crate_B_big", "barrel", "sack", "crate_long_A", "crate_open"][rng.randi() % 6] + ".gltf", Vector3(q.x, 0, q.y), rng.randf_range(0, 360), 5.5, "boite")
			occuper(q, 1.0)
	# --- champs et moulins au pied des murs ---
	PlanMonde.rect(PlanMonde.CHAMPS_JARNBORG, 2, 1.0, 2.0)
	for k2 in 10:
		col.poste("champs", Vector3(rng.randf_range(-185, -95), 0, rng.randf_range(-92, -75)))
	for m in [Vector2(-182, -84), Vector2(-96, -84)]:
		var mo := batiment(col, B + "building_windmill_blue.gltf", m, Vector2(0, -1), 6.2, "moulin", "Moulin")
		col.poste("moulin", mo["porte"])
	# --- gardes : portes, remparts, ronde des rues ---
	col.poste("garde_porte", PlanMonde.PORTE_SUD_JARNBORG + Vector3(-3.5, 0, -3))
	col.poste("garde_porte", PlanMonde.PORTE_SUD_JARNBORG + Vector3(3.5, 0, -3))
	col.poste("garde_porte", PlanMonde.PORTE_EST_JARNBORG + Vector3(-3, 0, -3.5))
	col.poste("garde_porte", PlanMonde.PORTE_EST_JARNBORG + Vector3(-3, 0, 3.5))
	col.poste("garde_porte", chateau["porte"] + Vector3(-3, 0, 1))
	col.poste("garde_porte", chateau["porte"] + Vector3(3, 0, 1))
	col.rondes = [
		[Vector3(-135, 0, -106), Vector3(-135, 0, -124), Vector3(-104, 0, -124), Vector3(-104, 0, -150), Vector3(-135, 0, -150), Vector3(-135, 0, -124)],
		[Vector3(-166, 0, -178), Vector3(-104, 0, -178), Vector3(-104, 0, -150), Vector3(-166, 0, -150)],
		[Vector3(-190, 0, -124), Vector3(-166, 0, -124), Vector3(-166, 0, -178), Vector3(-190, 0, -178)],
	]
	col.interets = [col.place, chateau["porte"], eglise["porte"], taverne["porte"], marche["porte"], forge["porte"], Vector3(-135, 0, -124), Vector3(-104, 0, -150),
		Vector3(-166, 0, -150), Vector3(-90, 0, -124), Vector3(-185, 0, -124), Vector3(-135, 0, -110)]
	col.poste("jeux", col.place + Vector3(-8, 0, 10))
	col.poste("place", col.place + Vector3(0, 0, 10))

# =================== Vik du Lac ===================

func _vik() -> void:
	var col := Colonie.new()
	col.id = "vik"
	col.nom = "Vik du Lac"
	col.rect = PlanMonde.VIK
	col.place = PlanMonde.PLACE_VIK
	col.feu = col.place + Vector3(0, 0, 5)
	col.cachot = PlanMonde.PORTE_SUD_JARNBORG + Vector3(0, 0, -10)
	col.nb_gardes = 2
	colonies.append(col)
	var G := H + "buildings/green/"
	var P := H + "decoration/props/"
	PlanMonde.reserver(col.rect)
	var rue_lac := [Vector2(-76, -8), Vector2(-127, -8)]
	rue(rue_lac, 2.4, 0)
	rue([Vector2(-104, -36), Vector2(-102, -8), Vector2(-96, 16)], 2.0, 0)
	var pl := Vector2(col.place.x, col.place.z)
	PlanMonde.disque(pl, 8.0, 1, 1.0, 2.0)
	occuper(pl, 8.5)
	var taverne := batiment(col, G + "building_tavern_green.gltf", Vector2(-100, -21), Vector2(0, 1), 6.2, "taverne", "Taverne de l'Anguille")
	col.poste("taverne", taverne["porte"])
	etal(col, Vector2(-112, -1), Vector2(0, -1), "green")
	var moulin := batiment(col, G + "building_watermill_green.gltf", Vector2(-129, -25), Vector2(1, 1), 6.0, "moulin", "Moulin à eau")
	col.poste("moulin", moulin["porte"])
	rangee(col, [Vector2(-80, -8), Vector2(-122, -8)], 1, "green", 5.2, 7.4, 0.95, [[pl, 11.0]])
	rangee(col, [Vector2(-80, -8), Vector2(-122, -8)], -1, "green", 5.2, 7.4, 0.95, [[pl, 11.0]])
	# ponton sur le lac : les pêcheurs y passent la journée
	for k in 7:
		c.poser(DJ + "floor_wood_large.glb", Vector3(-129.5 - k * 2.6, 0.12, -8), 0.0, Vector3(0.65, 1.0, 0.75))
	for k2 in 4:
		c.poser(HW + "post_lantern.gltf", Vector3(-131 - k2 * 5.0, 0, -9.7 if k2 % 2 == 0 else -6.3), 0.0, 0.8)
	c.lumiere(Vector3(-140, 3.0, -8), Color(1.0, 0.8, 0.5), 1.4, 12.0)
	for k3 in 4:
		col.poste("peche", Vector3(-134 - k3 * 3.4, 0.12, -8 + (0.9 if k3 % 2 == 0 else -0.9)))
	c.poser(P + "crate_long_B.gltf", Vector3(-124, 0, -4), 10.0, 5.0, "boite")
	c.poser(P + "barrel.gltf", Vector3(-123, 0, -12), 0.0, 5.0, "boite")
	c.poser(P + "bucket_water.gltf", Vector3(-126, 0.12, -10), 0.0, 5.0)
	c.poser(G + "building_well_green.gltf", Vector3(pl.x + 4, 0, pl.y - 2), 0.0, 4.2, "boite")
	c.feu_de_camp(col.feu)
	for a in [0.5, 2.1, 3.7, 5.2]:
		var p := col.feu + Vector3(cos(a), 0, sin(a)) * 3.6
		c.poser(HW + "bench.gltf", p, rad_to_deg(-a) + 90.0, 0.9, "boite")
		col.poste("banc", p)
	for p2 in [Vector3(-88, 0, -5), Vector3(-112, 0, -11), Vector3(-104, 0, -30)]:
		lanterne(p2)
	PlanMonde.rect(Rect2(-92, 18, 18, 12), 2, 1.0, 2.0)
	for k4 in 4:
		col.poste("champs", Vector3(rng.randf_range(-90, -76), 0, rng.randf_range(20, 28)))
	col.poste("jeux", col.place + Vector3(0, 0, 8))
	col.poste("place", col.place)
	col.poste("garde_porte", Vector3(-78, 0, -11))
	col.rondes = [[Vector3(-78, 0, -8), Vector3(-100, 0, -8), Vector3(-124, 0, -8), Vector3(-104, 0, -32), Vector3(-96, 0, 12)]]
	col.interets = [col.place, taverne["porte"], Vector3(-128, 0, -8), moulin["porte"], Vector3(-86, 0, -8)]

# =================== Fort de Hrafn (pillards) ===================

func _hrafn() -> void:
	var col := Colonie.new()
	col.id = "hrafn"
	col.nom = "Fort de Hrafn"
	col.faction = "hostile"
	col.rect = PlanMonde.HRAFN
	col.place = Vector3(128, 0, -172)
	colonies.append(col)
	var Rd := H + "buildings/red/"
	var P := H + "decoration/props/"
	var r := col.rect
	PlanMonde.reserver(r.grow(4.0))
	PlanMonde.rect(r.grow(-2.0), 0, 0.55, 0.0)
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	palissade(Vector3(x0, 0, z0), Vector3(x1, 0, z0), [])
	palissade(Vector3(x0, 0, z0), Vector3(x0, 0, z1), [])
	palissade(Vector3(x1, 0, z0), Vector3(x1, 0, z1), [])
	palissade(Vector3(x0, 0, z1), Vector3(x1, 0, z1), [inverse_lerp(x0, x1, 128.0)])
	for t in [Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(x0, 0, z1), Vector3(x1, 0, z1), Vector3(123, 0, z1 + 1), Vector3(133, 0, z1 + 1)]:
		tour(t, "red", "tower_A", 4.2)
	var hall := batiment(col, Rd + "building_barracks_red.gltf", Vector2(128, -196), Vector2(0, 1), 7.4, "hall", "Hall de Hrafn")
	col.poste("hall", hall["porte"])
	batiment(col, Rd + "building_tavern_red.gltf", Vector2(150, -190), Vector2(-1, 1), 6.0, "taverne", "Beuverie")
	batiment(col, Rd + "building_blacksmith_red.gltf", Vector2(104, -190), Vector2(1, 1), 6.0, "forge", "Forge des pillards")
	for h in [[Vector2(104, -168), Vector2(1, 0)], [Vector2(152, -168), Vector2(-1, 0)], [Vector2(106, -158), Vector2(1, -0.3)], [Vector2(150, -158), Vector2(-1, -0.3)]]:
		batiment(col, Rd + "building_home_%s_red.gltf" % ["A", "B"][rng.randi() % 2], h[0], h[1], 6.0, "maison", "", "Pillards")
	tour(Vector3(140, 0, -178), "red", "tower_catapult", 4.4)
	c.feu_de_camp(col.place)
	for k in 8:
		var q := Vector2(col.place.x, col.place.z) + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(6.0, 12.0)
		if libre(q, 1.0):
			c.poser(P + ["crate_A_big", "barrel", "weaponrack", "crate_open", "sack"][rng.randi() % 5] + ".gltf", Vector3(q.x, 0, q.y), rng.randf_range(0, 360), 5.5, "boite")
			occuper(q, 1.0)
	for p in [Vector3(118, 0, -190), Vector3(138, 0, -190), Vector3(128, 0, -158)]:
		drapeau(p, "red")
	for p2 in [Vector3(122, 0, -146), Vector3(134, 0, -146)]:
		c.poser(HW + "post_skull.gltf", p2, 0.0, 1.5)
		c.feu(p2 + Vector3(0, 2.3, 0), 0.4)
		c.lumiere(p2 + Vector3(0, 2.6, 0), Color(1.0, 0.45, 0.2), 1.6, 10.0)
	c.lumiere(col.place + Vector3(0, 5, 0), Color(1.0, 0.5, 0.25), 1.5, 22.0)
	col.poste("garde", Vector3(124, 0, -154))
	col.poste("garde", Vector3(132, 0, -154))

func _skarn() -> void:
	var col := Colonie.new()
	col.id = "skarn"
	col.nom = "Camp de Skarn"
	col.faction = "hostile"
	col.place = PlanMonde.SKARN
	col.rect = Rect2(col.place.x - 22, col.place.z - 22, 44, 44)
	colonies.append(col)
	var P := H + "decoration/props/"
	PlanMonde.reserver_disque(Vector2(col.place.x, col.place.z), 26.0)
	PlanMonde.disque(Vector2(col.place.x, col.place.z), 16.0, 0, 0.6, 0.0)
	c.feu_de_camp(col.place)
	for i in 7:
		var a := TAU * i / 7.0 + 0.3
		var p := col.place + Vector3(cos(a), 0, sin(a)) * 12.0
		c.poser(P + "tent.gltf", p, rad_to_deg(-a) - 90.0, 7.0, "boite")
	batiment(col, H + "buildings/red/building_home_B_red.gltf", Vector2(col.place.x - 4, col.place.z - 18), Vector2(0, 1), 6.0, "hall", "Cabane de Skarn")
	for p2 in [col.place + Vector3(-16, 0, 6), col.place + Vector3(16, 0, -4)]:
		c.poser(HW + "post_skull.gltf", p2, 0.0, 1.4)
	c.lumiere(col.place + Vector3(0, 4, 0), Color(1.0, 0.5, 0.25), 1.4, 18.0)
	drapeau(col.place + Vector3(6, 0, -14), "red")

# =================== carrière, pierres levées, tour ===================

func _carriere() -> void:
	var p := PlanMonde.CARRIERE
	PlanMonde.reserver_disque(Vector2(p.x, p.z), 20.0)
	PlanMonde.disque(Vector2(p.x, p.z), 14.0, 0, 0.7, 0.0)
	c.poser(H + "buildings/blue/building_mine_blue.gltf", p + Vector3(2, 0, -12), 0.0, 6.4, "boite")
	c.poser(H + "decoration/props/resource_stone.gltf", p + Vector3(-8, 0, -6), 20.0, 5.0, "boite")
	c.poser(H + "decoration/props/wheelbarrow.gltf", p + Vector3(8, 0, 2), 60.0, 5.5, "boite")
	c.poser(O + "pickaxe.gltf", p + Vector3(-5, 0.1, 3), 40.0, 1.3)
	c.lumiere(p + Vector3(2, 3, -6), Color(1.0, 0.7, 0.4), 1.2, 10.0)
	c.zone_rochers(p, 13.0, 26)

func _pierres() -> void:
	var p := PlanMonde.PIERRES
	PlanMonde.reserver_disque(Vector2(p.x, p.z), 12.0)
	for i in 9:
		var a := TAU * i / 9.0
		var q := p + Vector3(cos(a), 0, sin(a)) * 7.5
		c.poser(F + "Rock_3_" + ["A", "C", "E", "G"][i % 4] + "_Color1.gltf", q + Vector3(0, 1.1, 0), rad_to_deg(-a), Vector3(2.2, rng.randf_range(3.8, 5.2), 2.0))
		c.cylindre_collision(q, 1.0, 4.0)
	c.poser(DJ + "column.glb", p, 0.0, 1.1, "boite")
	c.poser(DJ + "candle_triple.glb", p + Vector3(1.2, 0, 1.0), 0.0, 1.4)
	c.poser(DJ + "candle_triple.glb", p + Vector3(-1.1, 0, 1.1), 50.0, 1.4)
	var autel := Autel.new()
	autel.position = p + Vector3(0, 0, 1.6)
	c.add_child(autel)
	c.lumiere(p + Vector3(0, 3, 0), Color(0.6, 0.8, 1.0), 2.0, 12.0)

func _tour() -> void:
	var p := PlanMonde.TOUR
	PlanMonde.reserver_disque(Vector2(p.x, p.z), 12.0)
	c.poser(H + "buildings/blue/building_tower_base_blue.gltf", p, 20.0, 6.0, "boite")
	c.poser(H + "buildings/neutral/building_destroyed.gltf", p + Vector3(7, 0, 4), 60.0, 5.5, "boite")
	c.poser(DJ + "rubble_large.glb", p + Vector3(-5, 0, 5), 10.0, 1.0)
	c.poser(DJ + "rubble_half.glb", p + Vector3(4, 0, -6), 80.0, 1.0)
