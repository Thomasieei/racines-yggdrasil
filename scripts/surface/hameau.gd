class_name Hameau
## Gestion du Hameau de Brekka, une fois devenu chef : chaque habitant adulte a un métier qui
## produit pour toi, en temps réel, même jeu fermé (jusqu'à 8 h). Les bâtiments s'améliorent
## avec ce que tu rapportes (bois, pierre, or). L'état vit dans le profil.

const METIERS := {
	"bucheron": {"nom": "Bûcheron", "produit": {"bois": 30.0}, "poste": "scierie", "batiment": "scierie"},
	"mineur": {"nom": "Mineur", "produit": {"pierre": 18.0, "minerai_fer": 4.0}, "poste": "chantier", "batiment": "carriere"},
	"fermier": {"nom": "Fermier", "produit": {"or": 45.0}, "poste": "champs", "batiment": "moulin"},
	"garde": {"nom": "Garde", "produit": {}, "poste": "place", "batiment": "palissade"},
}
## Niveaux 1 à 3 ; chaque niveau ajoute +50 % à la production du métier lié.
const BATIMENTS := {
	"scierie": {"nom": "Scierie", "effet": "bois des bûcherons", "couts": [{}, {"bois": 60, "or": 300}, {"bois": 160, "pierre": 80, "or": 900}]},
	"carriere": {"nom": "Carrière", "effet": "pierre et fer des mineurs", "couts": [{}, {"bois": 80, "or": 300}, {"bois": 120, "pierre": 140, "or": 900}]},
	"moulin": {"nom": "Moulin", "effet": "or des fermiers", "couts": [{}, {"bois": 70, "pierre": 40, "or": 250}, {"bois": 150, "pierre": 120, "or": 800}]},
	"palissade": {"nom": "Palissade", "effet": "gardes : vols mieux protégés, impôt +", "couts": [{}, {"bois": 100, "or": 200}, {"bois": 200, "pierre": 100, "or": 600}]},
}
const PRIX_CHEF := {"bois": 40, "pierre": 20, "or": 500}
const PLAFOND_H := 8.0

static func etat() -> Dictionary:
	var pr := Profil.p()
	if not pr.vus.has("hameau"):
		pr.vus["hameau"] = {"chef": false, "metiers": {}, "batiments": {"scierie": 1, "carriere": 1, "moulin": 1, "palissade": 1},
			"stock": {}, "dernier": Time.get_unix_time_from_system()}
	return pr.vus["hameau"]

static func est_chef() -> bool:
	return etat()["chef"]

static func metier_de(nom: String) -> String:
	return etat()["metiers"].get(nom, "")

## Production par heure réelle de tout le hameau.
static func production() -> Dictionary:
	var e := etat()
	var p := {}
	for nom in e["metiers"]:
		var m: String = e["metiers"][nom]
		if not METIERS.has(m):
			continue
		var niv: int = e["batiments"].get(METIERS[m]["batiment"], 1)
		for res in METIERS[m]["produit"]:
			p[res] = p.get(res, 0.0) + METIERS[m]["produit"][res] * (1.0 + 0.5 * (niv - 1))
	# impôt : chaque habitant rapporte un peu, plus avec des gardes et une palissade
	var gardes := 0
	for nom in e["metiers"]:
		if e["metiers"][nom] == "garde":
			gardes += 1
	p["or"] = p.get("or", 0.0) + 15.0 * (1.0 + gardes * 0.2) * (1.0 + 0.25 * (e["batiments"]["palissade"] - 1))
	return p

## Ajoute au grenier ce qui a été produit depuis la dernière fois (même jeu fermé, 8 h au plus).
static func avancer() -> void:
	var e := etat()
	if not e["chef"]:
		return
	var maintenant := Time.get_unix_time_from_system()
	var h := clampf((maintenant - float(e["dernier"])) / 3600.0, 0.0, PLAFOND_H)
	e["dernier"] = maintenant
	if h <= 0.0:
		return
	var p := production()
	for res in p:
		e["stock"][res] = e["stock"].get(res, 0.0) + p[res] * h
	Profil.p()._marquer()

static func peut_payer(cout: Dictionary, h: Heros) -> bool:
	for res in cout:
		if _dispo(res, h) < cout[res]:
			return false
	return true

## Ce qu'on a : l'or du sac, le reste dans le sac + le coffre + le grenier du hameau.
static func _dispo(res: String, h: Heros) -> int:
	if res == "or":
		return h.sac.or_
	var n := h.sac.compter(res)
	for o in Profil.p().coffre["objets"]:
		if o["id"] == res:
			n += o["qte"]
	n += int(etat()["stock"].get(res, 0.0))
	return n

static func payer(cout: Dictionary, h: Heros) -> void:
	for res in cout:
		var reste: int = cout[res]
		if res == "or":
			h.sac.or_ -= reste
			continue
		var stock: float = etat()["stock"].get(res, 0.0)
		var pris: int = mini(reste, int(stock))
		etat()["stock"][res] = stock - pris
		reste -= pris
		for o in h.sac.objets.duplicate():
			if reste > 0 and o["id"] == res:
				var k: int = mini(reste, o["qte"])
				h.sac.retirer(o, k)
				reste -= k
		for o in Profil.p().coffre["objets"].duplicate():
			if reste > 0 and o["id"] == res:
				var k2: int = mini(reste, o["qte"])
				o["qte"] -= k2
				reste -= k2
				if o["qte"] <= 0:
					Profil.p().coffre["objets"].erase(o)
	h.sac.change.emit()
	Profil.p()._marquer()

## Récupère le grenier : l'or dans le sac, les ressources dans le coffre personnel.
static func recolter(h: Heros) -> Dictionary:
	var e := etat()
	var bilan := {}
	for res in e["stock"].keys():
		var n := int(e["stock"][res])
		if n <= 0:
			continue
		e["stock"][res] -= n
		bilan[res] = n
		if res == "or":
			h.sac.ajouter_or(n)
		else:
			var fusion := false
			for o in Profil.p().coffre["objets"]:
				if o["id"] == res and o["qte"] < 999:
					o["qte"] += n
					fusion = true
					break
			if not fusion:
				var obj := Objets.creer(res, "commun", n)
				obj["pile"] = 999
				Profil.p().coffre["objets"].append(obj)
	Profil.p()._marquer()
	return bilan
