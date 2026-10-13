class_name Objets
## Catalogue des objets et règles de butin.
## Un objet en jeu est un dictionnaire : {id, nom, type, icone, rarete, qte, valeur, ...}.
## Types : "ressource", "arme", "potion", "oeuf", "dragon".

const ICO := "res://assets/icones/"
const ICO2 := "res://assets/icones_objets/"

const RARETES := ["commun", "rare", "epique", "legendaire", "mythique"]
const NOMS_RARETE := {"commun": "Commun", "rare": "Rare", "epique": "Épique", "legendaire": "Légendaire", "mythique": "Mythique"}
const COULEURS := {
	"commun": Color("#5DBB63"), "rare": Color("#3D8BFF"), "epique": Color("#A45CFF"),
	"legendaire": Color("#FF9A2E"), "mythique": Color("#E5383B"),
}
const MULT_VALEUR := {"commun": 1.0, "rare": 2.5, "epique": 6.0, "legendaire": 15.0, "mythique": 40.0}

const MODELES := {
	"minerai_cuivre": {"nom": "Minerai de cuivre", "type": "ressource", "icone": ICO2 + "minerai_cuivre.png", "valeur": 4, "pile": 99},
	"minerai_fer": {"nom": "Minerai de fer", "type": "ressource", "icone": ICO2 + "minerai_fer.png", "valeur": 7, "pile": 99},
	"minerai_argent": {"nom": "Minerai d'argent", "type": "ressource", "icone": ICO2 + "minerai_argent.png", "valeur": 14, "pile": 99},
	"minerai_or": {"nom": "Minerai d'or", "type": "ressource", "icone": ICO2 + "minerai_or.png", "valeur": 30, "pile": 99},
	"lingot_or": {"nom": "Lingots d'or nain", "type": "ressource", "icone": ICO2 + "lingots_or.png", "valeur": 120, "pile": 20},
	"tissu": {"nom": "Étoffe de draugr", "type": "ressource", "icone": ICO2 + "tissu.png", "valeur": 3, "pile": 99},
	"potion": {"nom": "Potion de soin", "type": "potion", "icone": "res://assets/icones_sorts/potion.svg", "valeur": 25, "pile": 10},
	"hache": {"nom": "Hache", "type": "arme", "icone": ICO + "000_axe_1handed.png", "valeur": 40},
	"grande_hache": {"nom": "Grande hache", "type": "arme", "icone": ICO + "001_axe_2handed.png", "valeur": 70},
	"epee": {"nom": "Épée", "type": "arme", "icone": ICO + "013_sword_1handed.png", "valeur": 45},
	"espadon": {"nom": "Espadon", "type": "arme", "icone": ICO + "014_sword_2handed.png", "valeur": 75},
	"dague": {"nom": "Dague", "type": "arme", "icone": ICO + "047_dagger.png", "valeur": 30},
	"baton": {"nom": "Bâton", "type": "arme", "icone": ICO + "052_staff.png", "valeur": 55},
	"bouclier": {"nom": "Bouclier rond", "type": "arme", "icone": ICO + "004_shield_round.png", "valeur": 35},
	"arbalete": {"nom": "Arbalète", "type": "arme", "icone": ICO + "045_crossbow_1handed.png", "valeur": 60},
	"oeuf": {"nom": "Œuf de dragon", "type": "oeuf", "valeur": 80},
	"dragon": {"nom": "Bébé dragon", "type": "dragon", "valeur": 60},
	"relique": {"nom": "Relique", "type": "relique", "valeur": 120},
}

## Reliques : six emplacements, un effet chacune. Vert ≈ +1,6 %, bleu +3 %, violet +6 à 8 %,
## orange +20 à 24 %, rouge +30 à 35 %. Une relique orange ou rouge change une partie.
const RELIQUES := {
	"sorts": {"nom": "Œil de Thor", "effet": "puissance des compétences"},
	"endurance": {"nom": "Cœur de chêne", "effet": "points de vie"},
	"energie": {"nom": "Larme de Freya", "effet": "énergie et régénération"},
	"recharge": {"nom": "Sablier des Nornes", "effet": "vitesse de recharge"},
}
const BONUS_RELIQUE := {"commun": [1.6, 1.6], "rare": [3.0, 3.0], "epique": [6.0, 8.0], "legendaire": [20.0, 24.0], "mythique": [30.0, 35.0]}

static var _uid := 0

static func creer(id: String, rarete := "commun", qte := 1) -> Dictionary:
	var m: Dictionary = MODELES[id]
	_uid += 1
	var o := {"uid": _uid, "id": id, "nom": m["nom"], "type": m["type"], "rarete": rarete, "qte": qte,
		"icone": m.get("icone", ""), "valeur": int(m["valeur"] * MULT_VALEUR[rarete]), "pile": m.get("pile", 1)}
	match m["type"]:
		"arme":
			var niv := RARETES.find(rarete)
			o["degats"] = int(round((90 + randi_range(-10, 10)) * (1.0 + niv * 0.22)))
			o["nom"] = m["nom"] + " " + ["de draugr", "runique", "du Jarl", "d'Yggdrasil", "de Freya"][niv]
		"oeuf":
			o["icone"] = ICO2 + "oeuf_" + rarete + ".png"
			o["nom"] = "Œuf de dragon " + NOMS_RARETE[rarete].to_lower()
		"dragon":
			o["icone"] = ICO2 + "dragon_" + rarete + ".png"
		"relique":
			var st: String = RELIQUES.keys()[randi() % RELIQUES.size()]
			var b: Array = BONUS_RELIQUE[rarete]
			var pct: float = snappedf(randf_range(b[0], b[1]), 0.1)
			o["stat"] = st
			o["bonus"] = pct / 100.0
			o["nom"] = RELIQUES[st]["nom"]
			o["icone"] = "res://assets/icones_reliques/%s_%s.svg" % [st, rarete]
	return o

## « +3 % de points de vie », « +6,4 % de puissance des compétences »…
static func texte_relique(o: Dictionary) -> String:
	var v: float = o.get("bonus", 0.0) * 100.0
	var t := ("%.1f" % v).replace(".", ",").trim_suffix(",0")
	return "+%s %% de %s" % [t, RELIQUES[o["stat"]]["effet"]]

## Bébé dragon tiré d'un œuf. La rareté de l'œuf fixe les chances ; au-delà du bleu c'est extrêmement rare.
## Puissance de 1 à 5 étoiles, niveau 1, xp 0. Un dragon faible se revend mal, un très fort vaut une fortune.
static func eclore(oeuf: Dictionary) -> Dictionary:
	var tables := {
		# probabilités [commun, rare, épique, légendaire, mythique] selon la rareté de l'œuf
		"commun": [0.88, 0.115, 0.004, 0.0009, 0.0001],
		"rare": [0.55, 0.43, 0.017, 0.0025, 0.0005],
		"epique": [0.25, 0.62, 0.11, 0.017, 0.003],
		"legendaire": [0.05, 0.55, 0.30, 0.09, 0.01],
		"mythique": [0.0, 0.25, 0.45, 0.24, 0.06],
	}
	var t: Array = tables[oeuf["rarete"]]
	var r := randf()
	var acc := 0.0
	var rar := "commun"
	for i in t.size():
		acc += t[i]
		if r <= acc:
			rar = RARETES[i]
			break
	var d := creer("dragon", rar)
	# puissance : 1 à 5 étoiles, plutôt basse ; les étoiles hautes multiplient la valeur
	var p := 1
	var rp := randf()
	if rp > 0.97:
		p = 5
	elif rp > 0.88:
		p = 4
	elif rp > 0.65:
		p = 3
	elif rp > 0.35:
		p = 2
	d["puissance"] = p
	d["niveau"] = 1
	d["xp"] = 0
	d["valeur"] = int(d["valeur"] * [0.4, 0.8, 1.5, 3.0, 7.0][p - 1])
	d["nom"] = "Bébé dragon " + NOMS_RARETE[rar].to_lower()
	return d

## Statistiques d'un dragon à son niveau : il grandit avec le joueur.
static func stats_dragon(d: Dictionary) -> Dictionary:
	var niv: int = d.get("niveau", 1)
	var base: float = 1.0 + RARETES.find(d["rarete"]) * 0.6 + (d.get("puissance", 1) - 1) * 0.35
	return {"degats": int(round(18.0 * base * (1.0 + (niv - 1) * 0.12))), "cadence": 1.6, "taille": 0.75 + minf(niv, 20) * 0.04}

static func xp_niveau(niv: int) -> int:
	return 60 + niv * 40

## Rareté au hasard selon une table de chances [commun, rare, épique, légendaire, mythique].
static func tirer_rarete(chances: Array) -> String:
	var r := randf()
	var acc := 0.0
	for i in chances.size():
		acc += chances[i]
		if r <= acc:
			return RARETES[i]
	return "commun"

const ARMES := ["hache", "grande_hache", "epee", "espadon", "dague", "baton", "bouclier", "arbalete"]

## Contenu d'un coffre selon sa rareté : or, objets, et parfois un œuf.
static func contenu_coffre(rarete: String) -> Dictionary:
	var niv := RARETES.find(rarete)
	var objets: Array = []
	var nb := 2 + niv + randi_range(0, 1)
	for i in nb:
		var r := randf()
		if r < 0.45:
			var ids := ["minerai_cuivre", "minerai_fer", "minerai_argent", "minerai_or", "tissu"]
			objets.append(creer(ids[mini(randi_range(0, 2) + niv / 2, ids.size() - 1)], "commun", randi_range(2, 6)))
		elif r < 0.8:
			var chances: Array = [[0.7, 0.25, 0.05, 0, 0], [0.35, 0.45, 0.17, 0.03, 0], [0.1, 0.4, 0.38, 0.11, 0.01], [0, 0.2, 0.45, 0.3, 0.05], [0, 0, 0.35, 0.45, 0.2]][niv]
			objets.append(creer(ARMES[randi() % ARMES.size()], tirer_rarete(chances)))
		else:
			objets.append(creer("potion", "commun", randi_range(1, 2)))
	if niv >= 3:
		objets.append(creer("lingot_or", "commun", randi_range(1, 2 + niv)))
	# œuf de dragon : rare, plus probable dans les grands coffres
	if randf() < [0.01, 0.03, 0.07, 0.15, 0.35][niv]:
		objets.append(creer("oeuf", tirer_rarete([0.6, 0.3, 0.08, 0.018, 0.002])))
	# relique : la vraie récompense des grands coffres
	if randf() < [0.05, 0.12, 0.28, 0.55, 0.9][niv]:
		objets.append(creer("relique", tirer_rarete([[0.75, 0.22, 0.03, 0, 0], [0.5, 0.38, 0.11, 0.01, 0], [0.2, 0.45, 0.3, 0.05, 0], [0.05, 0.35, 0.42, 0.16, 0.02], [0, 0.15, 0.45, 0.32, 0.08]][niv])))
	var or_ := int(randi_range(15, 40) * (1.0 + niv * 1.8))
	return {"or": or_, "objets": objets}

## Butin d'un monstre (souvent rien, un peu d'or, rarement un œuf).
static func butin_monstre(type: String) -> Dictionary:
	var elite := type in ["jarl", "reine", "brokk", "roi"]
	var objets: Array = []
	if elite:
		objets.append(creer(ARMES[randi() % ARMES.size()], tirer_rarete([0, 0.3, 0.45, 0.2, 0.05])))
		if randf() < 0.18:
			objets.append(creer("oeuf", tirer_rarete([0.35, 0.4, 0.18, 0.06, 0.01])))
		if randf() < 0.3:
			objets.append(creer("relique", tirer_rarete([0.2, 0.45, 0.28, 0.06, 0.01])))
	else:
		if randf() < 0.25:
			objets.append(creer("tissu", "commun", randi_range(1, 2)))
		if randf() < 0.06:
			objets.append(creer(ARMES[randi() % ARMES.size()], tirer_rarete([0.75, 0.22, 0.03, 0, 0])))
		if randf() < 0.004:
			objets.append(creer("oeuf", tirer_rarete([0.7, 0.25, 0.045, 0.004, 0.001])))
		if randf() < 0.006:
			objets.append(creer("relique", tirer_rarete([0.7, 0.25, 0.045, 0.004, 0.001])))
	return {"or": randi_range(2, 9) * (12 if elite else 1), "objets": objets}

static func couleur(o: Dictionary) -> Color:
	return COULEURS.get(o.get("rarete", "commun"), Color.WHITE)
