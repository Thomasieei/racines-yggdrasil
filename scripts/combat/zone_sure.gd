class_name ZoneSure
## Zones où l'on ne se bat pas (Bourg, camps du donjon). Les monstres n'y entrent pas,
## le héros n'y lance pas de sort offensif, les gardes abattent tout monstre qui s'y aventure.
## En multijoueur, frapper quelqu'un ici rendra hostile aux gardes (logique serveur, plus tard).

static var zones: Array = []        ## [{nom, centre: Vector3, rayon}]

static func ajouter(nom: String, centre: Vector3, rayon: float) -> void:
	zones.append({"nom": nom, "centre": centre, "rayon": rayon})

static func vider() -> void:
	zones.clear()

static func zone_de(p: Vector3) -> Dictionary:
	for z in zones:
		if Vector2(p.x - z["centre"].x, p.z - z["centre"].z).length() <= z["rayon"]:
			return z
	return {}

static func contient(p: Vector3, marge := 0.0) -> bool:
	for z in zones:
		if Vector2(p.x - z["centre"].x, p.z - z["centre"].z).length() <= z["rayon"] + marge:
			return true
	return false
