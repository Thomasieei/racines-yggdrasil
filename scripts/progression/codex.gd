class_name Codex
## Codex des réalisations. Chaque réalisation suit un compteur et donne des points de talent.
## Certaines sont annoncées (on sait quoi faire), d'autres sont cachées : on ne voit qu'un indice
## jusqu'à ce qu'on les découvre. Personne ne doit pouvoir tout cocher en suivant une liste.

const CATEGORIES := ["Chasse", "Exploration", "Trésors", "Métier", "Secrets"]

## compteur : clé incrémentée par Profil.compter() ; but : valeur à atteindre ; pts : points gagnés.
const LISTE := [
	# Chasse
	{"id": "chasse_10", "cat": "Chasse", "nom": "Premier sang", "texte": "Abattre 10 draugr.", "compteur": "tues", "but": 10, "pts": 1},
	{"id": "chasse_20", "cat": "Chasse", "nom": "Chasseur", "texte": "Abattre 20 draugr.", "compteur": "tues", "but": 20, "pts": 1},
	{"id": "chasse_50", "cat": "Chasse", "nom": "Fléau des morts", "texte": "Abattre 50 draugr.", "compteur": "tues", "but": 50, "pts": 3},
	{"id": "chasse_150", "cat": "Chasse", "nom": "Moissonneur", "texte": "Abattre 150 draugr.", "compteur": "tues", "but": 150, "pts": 5},
	{"id": "chasse_500", "cat": "Chasse", "nom": "Légende des cavernes", "texte": "Abattre 500 draugr.", "compteur": "tues", "but": 500, "pts": 10},
	{"id": "elite_1", "cat": "Chasse", "nom": "Tête couronnée", "texte": "Vaincre un élite (Jarl, Reine ou Brokk).", "compteur": "elites", "but": 1, "pts": 3},
	{"id": "elite_3", "cat": "Chasse", "nom": "Régicide", "texte": "Vaincre les trois élites différents.", "compteur": "elites_diff", "but": 3, "pts": 5},
	{"id": "ymir", "cat": "Chasse", "nom": "Le roi est mort", "texte": "Participer à la chute d'Ymir.", "compteur": "boss", "but": 1, "pts": 10},
	{"id": "duel", "cat": "Chasse", "nom": "Loi du plus fort", "texte": "Vaincre un autre aventurier dans le donjon.", "compteur": "jcj", "but": 1, "pts": 3},
	# Exploration
	{"id": "pas_500", "cat": "Exploration", "nom": "Premiers pas", "texte": "Parcourir 500 m.", "compteur": "metres", "but": 500, "pts": 1},
	{"id": "pas_2000", "cat": "Exploration", "nom": "Arpenteur", "texte": "Parcourir 2 km.", "compteur": "metres", "but": 2000, "pts": 3},
	{"id": "pas_10000", "cat": "Exploration", "nom": "Infatigable", "texte": "Parcourir 10 km.", "compteur": "metres", "but": 10000, "pts": 10},
	{"id": "zones_5", "cat": "Exploration", "nom": "Cartographe", "texte": "Découvrir 5 lieux de la caverne.", "compteur": "lieux", "but": 5, "pts": 1},
	{"id": "zones_12", "cat": "Exploration", "nom": "Rien ne m'échappe", "texte": "Découvrir 12 lieux de la caverne.", "compteur": "lieux", "but": 12, "pts": 5},
	{"id": "portail", "cat": "Exploration", "nom": "Au-delà du portail", "texte": "Franchir le portail d'Yggdrasil.", "compteur": "portail", "but": 1, "pts": 1},
	# Trésors
	{"id": "coffre_1", "cat": "Trésors", "nom": "Pilleur", "texte": "Ouvrir un coffre.", "compteur": "coffres", "but": 1, "pts": 1},
	{"id": "coffre_15", "cat": "Trésors", "nom": "Pilleur de tombes", "texte": "Ouvrir 15 coffres.", "compteur": "coffres", "but": 15, "pts": 5},
	{"id": "relique_1", "cat": "Trésors", "nom": "Porteur de relique", "texte": "Trouver une relique.", "compteur": "reliques", "but": 1, "pts": 3},
	{"id": "relique_6", "cat": "Trésors", "nom": "Collier complet", "texte": "Porter 6 reliques à la fois.", "compteur": "reliques_portees", "but": 6, "pts": 5},
	{"id": "eclosion", "cat": "Trésors", "nom": "Premier battement d'ailes", "texte": "Faire éclore un œuf de dragon.", "compteur": "eclosions", "but": 1, "pts": 3},
	{"id": "riche", "cat": "Trésors", "nom": "Bourse pleine", "texte": "Avoir 2 000 or sur soi.", "compteur": "or_max", "but": 2000, "pts": 3},
	# Métier
	{"id": "mine_10", "cat": "Métier", "nom": "Coup de pioche", "texte": "Extraire 10 minerais.", "compteur": "minerais", "but": 10, "pts": 1},
	{"id": "mine_100", "cat": "Métier", "nom": "Gueule noire", "texte": "Extraire 100 minerais.", "compteur": "minerais", "but": 100, "pts": 5},
	{"id": "mineur_5", "cat": "Métier", "nom": "Mineur confirmé", "texte": "Atteindre le niveau 5 de Mineur.", "compteur": "niveau_mineur", "but": 5, "pts": 3},
	{"id": "quetes_3", "cat": "Métier", "nom": "Homme de parole", "texte": "Accomplir 3 quêtes de Bjorn.", "compteur": "quetes", "but": 3, "pts": 3},
	{"id": "quetes_5", "cat": "Métier", "nom": "L'ami des égarés", "texte": "Accomplir toutes les quêtes de Bjorn.", "compteur": "quetes", "but": 5, "pts": 5},
	# Secrets : on ne voit que l'indice tant qu'ils ne sont pas trouvés
	{"id": "abime", "cat": "Secrets", "nom": "Ce qui regarde en retour", "indice": "Certains vides se contemplent longtemps.", "texte": "Rester 10 s au bord du gouffre.", "compteur": "abime", "but": 1, "pts": 5, "cache": true},
	{"id": "fil", "cat": "Secrets", "nom": "Sur le fil", "indice": "Frôler la mort sans y céder.", "texte": "Survivre à un combat avec moins de 5 % de vie.", "compteur": "fil", "but": 1, "pts": 5, "cache": true},
	{"id": "pacifique", "cat": "Secrets", "nom": "Main tendue", "indice": "Le camp sûr connaît la patience.", "texte": "Rester 60 s immobile au camp des Égarés.", "compteur": "patience", "but": 1, "pts": 3, "cache": true},
	{"id": "lac", "cat": "Secrets", "nom": "Les noyés chantent", "indice": "L'eau noire a une voix, pour qui s'approche.", "texte": "Toucher la rive du Lac des Noyés.", "compteur": "lac", "but": 1, "pts": 3, "cache": true},
	{"id": "rune", "cat": "Secrets", "nom": "Écaille de mémoire", "indice": "Les dragons n'ont pas tout emporté.", "texte": "Trouver un fragment de rune draconique.", "compteur": "runes", "but": 1, "pts": 10, "cache": true},
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
