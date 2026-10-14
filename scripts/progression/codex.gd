class_name Codex
## Codex des réalisations. Chaque réalisation suit un compteur et donne des points de talent.
## Certaines sont annoncées (on sait quoi faire), d'autres sont cachées : on ne voit qu'un indice
## jusqu'à ce qu'on les découvre. Personne ne doit pouvoir tout cocher en suivant une liste.

const CATEGORIES := ["Chasse", "Exploration", "Trésors", "Métier", "Secrets"]

## compteur : clé incrémentée par Profil.compter() ; but : valeur à atteindre ; pts : points gagnés.
const LISTE := [
	# Chasse
	{"id": "chasse_10", "cat": "Chasse", "nom": "Premier sang", "texte": "Abattre 10 draugr.", "compteur": "tues", "but": 10, "pts": 1},
	{"id": "chasse_20", "cat": "Chasse", "nom": "Chasseur", "texte": "Abattre 50 draugr.", "compteur": "tues", "but": 50, "pts": 1},
	{"id": "chasse_50", "cat": "Chasse", "nom": "Fléau des morts", "texte": "Abattre 150 draugr.", "compteur": "tues", "but": 150, "pts": 2},
	{"id": "chasse_150", "cat": "Chasse", "nom": "Moissonneur", "texte": "Abattre 400 draugr.", "compteur": "tues", "but": 400, "pts": 3},
	{"id": "chasse_500", "cat": "Chasse", "nom": "Légende des cavernes", "texte": "Abattre 1 000 draugr.", "compteur": "tues", "but": 1000, "pts": 5},
	{"id": "elite_1", "cat": "Chasse", "nom": "Tête couronnée", "texte": "Vaincre un élite (Jarl, Reine ou Brokk).", "compteur": "elites", "but": 1, "pts": 2},
	{"id": "elite_3", "cat": "Chasse", "nom": "Régicide", "texte": "Vaincre les trois élites différents.", "compteur": "elites_diff", "but": 3, "pts": 3},
	{"id": "ymir", "cat": "Chasse", "nom": "Le roi est mort", "texte": "Participer à la chute d'Ymir.", "compteur": "boss", "but": 1, "pts": 5},
	{"id": "duel", "cat": "Chasse", "nom": "Loi du plus fort", "texte": "Vaincre un autre aventurier dans le donjon.", "compteur": "jcj", "but": 1, "pts": 2},
	{"id": "horde_100", "cat": "Chasse", "nom": "Faucheur", "texte": "Pulvériser 100 rampants de la Horde.", "compteur": "horde", "but": 100, "pts": 1},
	{"id": "horde_1000", "cat": "Chasse", "nom": "Fléau de la Horde", "texte": "Pulvériser 1 000 rampants de la Horde.", "compteur": "horde", "but": 1000, "pts": 3},
	{"id": "horde_10000", "cat": "Chasse", "nom": "Cataclysme", "texte": "Pulvériser 10 000 rampants de la Horde.", "compteur": "horde", "but": 10000, "pts": 5},
	# Exploration
	{"id": "extraction_1", "cat": "Exploration", "nom": "Revenu vivant", "texte": "Remonter du donjon par une racine de retour.", "compteur": "extractions", "but": 1, "pts": 2},
	{"id": "extraction_10", "cat": "Exploration", "nom": "Pilleur aguerri", "texte": "Réussir 10 extractions.", "compteur": "extractions", "but": 10, "pts": 3},
	{"id": "pas_500", "cat": "Exploration", "nom": "Premiers pas", "texte": "Parcourir 1 km.", "compteur": "metres", "but": 1000, "pts": 1},
	{"id": "pas_2000", "cat": "Exploration", "nom": "Arpenteur", "texte": "Parcourir 5 km.", "compteur": "metres", "but": 5000, "pts": 2},
	{"id": "pas_10000", "cat": "Exploration", "nom": "Infatigable", "texte": "Parcourir 20 km.", "compteur": "metres", "but": 20000, "pts": 4},
	{"id": "zones_5", "cat": "Exploration", "nom": "Cartographe", "texte": "Découvrir 5 lieux de la caverne.", "compteur": "lieux", "but": 5, "pts": 1},
	{"id": "zones_12", "cat": "Exploration", "nom": "Rien ne m'échappe", "texte": "Découvrir 12 lieux de la caverne.", "compteur": "lieux", "but": 12, "pts": 2},
	{"id": "portail", "cat": "Exploration", "nom": "Au-delà du portail", "texte": "Franchir le portail d'Yggdrasil.", "compteur": "portail", "but": 1, "pts": 1},
	# Trésors
	{"id": "coffre_1", "cat": "Trésors", "nom": "Pilleur", "texte": "Ouvrir un coffre.", "compteur": "coffres", "but": 1, "pts": 1},
	{"id": "coffre_15", "cat": "Trésors", "nom": "Pilleur de tombes", "texte": "Ouvrir 30 coffres.", "compteur": "coffres", "but": 30, "pts": 2},
	{"id": "relique_1", "cat": "Trésors", "nom": "Porteur de relique", "texte": "Trouver une relique.", "compteur": "reliques", "but": 1, "pts": 1},
	{"id": "relique_6", "cat": "Trésors", "nom": "Collier complet", "texte": "Porter 6 reliques à la fois.", "compteur": "reliques_portees", "but": 6, "pts": 3},
	{"id": "eclosion", "cat": "Trésors", "nom": "Premier battement d'ailes", "texte": "Faire éclore un œuf de dragon.", "compteur": "eclosions", "but": 1, "pts": 2},
	{"id": "riche", "cat": "Trésors", "nom": "Bourse pleine", "texte": "Avoir 5 000 or sur soi.", "compteur": "or_max", "but": 5000, "pts": 2},
	# Métier
	{"id": "mine_10", "cat": "Métier", "nom": "Coup de pioche", "texte": "Extraire 25 minerais.", "compteur": "minerais", "but": 25, "pts": 1},
	{"id": "mine_100", "cat": "Métier", "nom": "Gueule noire", "texte": "Extraire 200 minerais.", "compteur": "minerais", "but": 200, "pts": 2},
	{"id": "mineur_5", "cat": "Métier", "nom": "Mineur confirmé", "texte": "Atteindre le niveau 5 de Mineur.", "compteur": "niveau_mineur", "but": 5, "pts": 2},
	{"id": "quetes_3", "cat": "Métier", "nom": "Homme de parole", "texte": "Accomplir 3 quêtes de Bjorn.", "compteur": "quetes", "but": 3, "pts": 2},
	{"id": "quetes_5", "cat": "Métier", "nom": "L'ami des égarés", "texte": "Accomplir toutes les quêtes de Bjorn.", "compteur": "quetes", "but": 5, "pts": 3},
	# Secrets : on ne voit que l'indice tant qu'ils ne sont pas trouvés
	{"id": "abime", "cat": "Secrets", "nom": "Ce qui regarde en retour", "indice": "Certains vides se contemplent longtemps.", "texte": "Rester 10 s au bord du gouffre.", "compteur": "abime", "but": 1, "pts": 3, "cache": true},
	{"id": "fil", "cat": "Secrets", "nom": "Sur le fil", "indice": "Frôler la mort sans y céder.", "texte": "Survivre à un combat avec moins de 5 % de vie.", "compteur": "fil", "but": 1, "pts": 3, "cache": true},
	{"id": "pacifique", "cat": "Secrets", "nom": "Main tendue", "indice": "Le camp sûr connaît la patience.", "texte": "Rester 60 s immobile au camp des Égarés.", "compteur": "patience", "but": 1, "pts": 2, "cache": true},
	{"id": "lac", "cat": "Secrets", "nom": "Les noyés chantent", "indice": "L'eau noire a une voix, pour qui s'approche.", "texte": "Toucher la rive du Lac des Noyés.", "compteur": "lac", "but": 1, "pts": 2, "cache": true},
	{"id": "rune", "cat": "Secrets", "nom": "Écaille de mémoire", "indice": "Les dragons n'ont pas tout emporté.", "texte": "Trouver un fragment de rune draconique.", "compteur": "runes", "but": 1, "pts": 3, "cache": true},
]

static func par_id(id: String) -> Dictionary:
	for r in LISTE:
		if r["id"] == id:
			return r
	return {}

static func total_points() -> int:
	var n := 0
	for r in LISTE:
		n += r["pts"]
	return n
