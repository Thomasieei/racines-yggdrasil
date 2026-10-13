class_name Talents
## L'Arbre des Racines : trois racines, cinq paliers chacune, quinze talents.
## Un palier s'ouvre quand on a investi assez de points dans l'arbre (0, 5, 10, 15, 20).
## Les trois talents du dernier palier sont incompatibles : on n'en prend qu'un.
##
## Chaque talent : id, nom, racine (0 loup, 1 chêne, 2 corbeau), palier (0..4), rangs max,
## stat + valeur par rang (lus par Heros.stat), texte (avec {v} = valeur au rang suivant).

const RACINES := [
	{"nom": "Racine du Loup", "sous": "Force et férocité", "couleur": Color("#E8A25A")},
	{"nom": "Racine du Chêne", "sous": "Endurance et sève", "couleur": Color("#9CCB6E")},
	{"nom": "Racine du Corbeau", "sous": "Ruse et souffle", "couleur": Color("#8FB8E8")},
]

const SEUILS := [0, 5, 10, 15, 20]   ## points investis dans l'arbre pour ouvrir chaque palier

const LISTE := [
	# --- Loup ---
	{"id": "morsure", "nom": "Morsure", "racine": 0, "palier": 0, "rangs": 5, "stat": "sorts", "val": 0.03,
		"texte": "Tes compétences infligent +{v} de dégâts."},
	{"id": "croc", "nom": "Croc affûté", "racine": 0, "palier": 1, "rangs": 5, "stat": "critique", "val": 0.02,
		"texte": "+{v} de chances de coup critique."},
	{"id": "hurlement", "nom": "Hurlement", "racine": 0, "palier": 2, "rangs": 5, "stat": "auto", "val": 0.06,
		"texte": "Ton attaque automatique frappe +{v} plus fort."},
	{"id": "curee", "nom": "Curée", "racine": 0, "palier": 3, "rangs": 5, "stat": "achever", "val": 0.05,
		"texte": "+{v} de dégâts contre les ennemis sous 30 % de vie."},
	{"id": "fenrir", "nom": "Sang de Fenrir", "racine": 0, "palier": 4, "rangs": 1, "stat": "fenrir", "val": 0.02, "ultime": true,
		"texte": "Chaque coup critique te rend 2 % de ta vie. Incompatible avec les deux autres ultimes."},
	# --- Chêne ---
	{"id": "ecorce", "nom": "Écorce", "racine": 1, "palier": 0, "rangs": 5, "stat": "endurance", "val": 0.04,
		"texte": "+{v} de points de vie maximum."},
	{"id": "seve", "nom": "Sève de Freya", "racine": 1, "palier": 1, "rangs": 5, "stat": "soin", "val": 0.1,
		"texte": "Tes potions soignent +{v}."},
	{"id": "racines", "nom": "Racines profondes", "racine": 1, "palier": 2, "rangs": 5, "stat": "armure", "val": 0.03,
		"texte": "Tu subis {v} de dégâts en moins."},
	{"id": "repos", "nom": "Souffle du guerrier", "racine": 1, "palier": 3, "rangs": 5, "stat": "regen", "val": 0.003,
		"texte": "Hors combat (6 s sans coup reçu), tu regagnes {v} de ta vie par seconde."},
	{"id": "rempart", "nom": "Dernier rempart", "racine": 1, "palier": 4, "rangs": 1, "stat": "rempart", "val": 1.0, "ultime": true,
		"texte": "Une fois toutes les 90 s, un coup mortel te laisse à 1 PV et invulnérable 1,5 s. Incompatible avec les deux autres ultimes."},
	# --- Corbeau ---
	{"id": "vent", "nom": "Vent du nord", "racine": 2, "palier": 0, "rangs": 5, "stat": "vitesse", "val": 0.02,
		"texte": "Tu cours {v} plus vite."},
	{"id": "memoire", "nom": "Mémoire runique", "racine": 2, "palier": 1, "rangs": 5, "stat": "recharge", "val": 0.03,
		"texte": "Tes compétences se rechargent {v} plus vite."},
	{"id": "odin", "nom": "Souffle d'Odin", "racine": 2, "palier": 2, "rangs": 5, "stat": "energie", "val": 0.08,
		"texte": "+{v} de régénération d'énergie."},
	{"id": "huginn", "nom": "Œil de Huginn", "racine": 2, "palier": 3, "rangs": 5, "stat": "fortune", "val": 0.06,
		"texte": "+{v} d'or ramassé et d'expérience de Mineur."},
	{"id": "muninn", "nom": "Pas de Muninn", "racine": 2, "palier": 4, "rangs": 1, "stat": "muninn", "val": 1.0, "ultime": true,
		"texte": "L'esquive ne coûte plus d'énergie et se recharge en 0,8 s. Incompatible avec les deux autres ultimes."},
]

static func par_id(id: String) -> Dictionary:
	for t in LISTE:
		if t["id"] == id:
			return t
	return {}

static func icone(id: String) -> String:
	return "res://assets/icones_talents/%s.svg" % id

## Valeur affichée d'un talent (pourcentage lisible).
static func format_val(t: Dictionary, rang: int) -> String:
	var v: float = t["val"] * maxi(rang, 1)
	if t["stat"] == "regen":
		return ("%.1f %%" % (v * 100.0)).replace(".", ",")
	if t["stat"] in ["fenrir", "rempart", "muninn"]:
		return ""
	return "%d %%" % int(round(v * 100.0))

static func description(t: Dictionary, rang: int) -> String:
	return String(t["texte"]).replace("{v}", format_val(t, rang))
