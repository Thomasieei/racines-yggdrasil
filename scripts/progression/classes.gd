class_name Classes
## Classes. Le Berserker est la classe de départ. Les voies draconiques s'obtiennent par le
## parcours des runes (trois fragments, l'œuf runique, l'épreuve) et un choix définitif entre
## trois pouvoirs incompatibles. Aucune n'est « meilleure » : chacune ouvre un style et se paie.
##
## C'est la classe (le titre) qui donne les compétences ; l'arme n'ajoute que de la puissance.
## remplace : emplacement de la roue -> compétence de la classe.
## stats : bonus et malus permanents, lus par Heros.stat().

const IC := "res://assets/icones_sorts/"

const LISTE := {
	"": {"titre": "Berserker", "couleur": Color("#F4C35A"), "remplace": {}, "stats": {}},
	"souffle": {
		"titre": "Drakonide du Souffle", "couleur": Color("#FF7A3D"), "embleme": IC + "classe_souffle.svg",
		"devise": "Brûler avant d'être touché.",
		"remplace": {"q": {"nom": "Souffle ardent", "icone": IC + "souffle.svg", "cd": 5.0, "cout": 14.0, "visee": "direction",
			"fiche": "Long cône de feu (6 m). Brûle tout ce qu'il touche pendant 3 s."}},
		"stats": {"sorts": 0.15, "endurance": -0.15},
		"forces": ["Souffle ardent : grand cône de feu qui brûle", "+15 % de puissance des compétences"],
		"faiblesses": ["−15 % de points de vie", "Fragile au corps à corps"],
	},
	"ecailles": {
		"titre": "Drakonide des Écailles", "couleur": Color("#5FD0A0"), "embleme": IC + "classe_ecailles.svg",
		"devise": "Encaisser, puis rendre.",
		"remplace": {"r": {"nom": "Carapace d'écailles", "icone": IC + "carapace.svg", "cd": 18.0, "cout": 0.0, "visee": "aucune",
			"fiche": "4 s : −60 % de dégâts subis, et 25 % des coups reçus sont renvoyés."}},
		"stats": {"armure": 0.15, "vitesse": -0.12, "energie": -0.15},
		"forces": ["Carapace : −60 % de dégâts, renvoie les coups", "−15 % de dégâts subis en permanence"],
		"faiblesses": ["−12 % de vitesse de course", "−15 % d'énergie"],
	},
	"ailes": {
		"titre": "Drakonide des Ailes", "couleur": Color("#7FC8FF"), "embleme": IC + "classe_ailes.svg",
		"devise": "N'être jamais là où l'on frappe.",
		"remplace": {"w": {"nom": "Envol", "icone": IC + "envol.svg", "cd": 6.0, "cout": 12.0, "visee": "direction",
			"fiche": "Bond de 11 m. À l'atterrissage, un anneau de feu repousse et brûle."}},
		"stats": {"vitesse": 0.10, "armure": -0.15, "esquive": 0.5},
		"forces": ["Envol : bond de 11 m qui brûle à l'arrivée", "+10 % de vitesse, esquive moitié prix"],
		"faiblesses": ["+15 % de dégâts subis", "Peu de marge si l'on se fait coincer"],
	},
}

const DRACONIQUES := ["souffle", "ecailles", "ailes"]

static func fiche(id: String) -> Dictionary:
	return LISTE.get(id, LISTE[""])
