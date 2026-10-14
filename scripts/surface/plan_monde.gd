class_name PlanMonde
## Le Val des Racines en grand : où sont les villes, les routes, le lac, les forts ennemis.
## Tout ce qui décide de la forme du monde vit ici ; CarteSurface et Bourgs le construisent.
##
## Repère : x vers l'est, z vers le sud, 1 unité = 1 m. Le nord (z petit) est en haut de l'écran.

const LIMITES := Rect2(-250, -235, 450, 365)

## Lieux habités. « rect » sert à garder la forêt dehors et à dessiner la carte.
const BREKKA := Rect2(12, -14, 80, 50)
const PLACE_BREKKA := Vector3(53, 0, 12)
const JARNBORG := Rect2(-200, -212, 130, 112)        ## la capitale, dans ses remparts
const PLACE_JARNBORG := Vector3(-135, 0, -150)
const PORTE_SUD_JARNBORG := Vector3(-135, 0, -100)
const PORTE_EST_JARNBORG := Vector3(-70, 0, -150)
const CHAMPS_JARNBORG := Rect2(-188, -94, 96, 22)
const VIK := Rect2(-128, -36, 52, 52)
const PLACE_VIK := Vector3(-100, 0, -8)
const LAC_CENTRE := Vector2(-170, -12)
const LAC_RAYONS := Vector2(40, 25)
const HRAFN := Rect2(92, -207, 72, 57)               ## Fort de Hrafn : pillards
const PORTE_HRAFN := Vector3(128, 0, -150)
const SKARN := Vector3(-192, 0, 74)                    ## camp de brigands
const CARRIERE := Vector3(40, 0, -102)
const PIERRES := Vector3(-18, 0, 50)
const TOUR := Vector3(-6, 0, -66)

## Routes de terre : [points, largeur]. Le chemin du sanctuaire au Bourg reste dans CarteSurface.CHEMIN.
const ROUTES := [
	[[Vector2(66, 64), Vector2(60, 46), Vector2(55, 30), Vector2(53, 20)], 2.3],                                       # Brekka ↔ chemin
	[[Vector2(14, 12), Vector2(-10, 6), Vector2(-30, -6)], 2.6],                                                       # Brekka → carrefour
	[[Vector2(-30, -6), Vector2(-55, -8), Vector2(-76, -8)], 2.6],                                                     # carrefour → Vik
	[[Vector2(-30, -6), Vector2(-40, -45), Vector2(-55, -95), Vector2(-60, -132), Vector2(-70, -150)], 3.0],           # carrefour → Jarnborg
	[[Vector2(-135, -100), Vector2(-131, -76), Vector2(-114, -52), Vector2(-104, -36)], 2.8],                          # Jarnborg ↔ Vik
	[[Vector2(29, 104), Vector2(0, 90), Vector2(-35, 72), Vector2(-70, 40), Vector2(-96, 16)], 2.4],                   # sanctuaire → Vik
	[[Vector2(-70, 40), Vector2(-120, 56), Vector2(-172, 70)], 2.0],                                                   # → camp de Skarn
	[[Vector2(92, 12), Vector2(102, -25), Vector2(116, -75), Vector2(126, -120), Vector2(128, -150)], 2.6],            # Brekka → Fort de Hrafn
	[[Vector2(46.5, -14), Vector2(46, -50), Vector2(42, -88)], 2.2],                                                     # Brekka → carrière
]

## Lieux nommés : bandeaux, minicarte, grande carte. Le premier qui contient le joueur gagne.
const LIEUX := [
	{"id": "sanctuaire", "nom": "Sanctuaire de Freya", "centre": Vector3(36, 0, 106), "rayon": 13.0},
	{"id": "clairiere", "nom": "Clairière des Tertres", "centre": Vector3(62, 0, 69), "rayon": 13.0},
	{"id": "bourg", "nom": "Bourg de Skjold", "centre": Vector3(127, 0, 37), "rayon": 27.0, "sur": true},
	{"id": "portail", "nom": "Portail d'Yggdrasil", "centre": Vector3(127, 0, 0), "rayon": 13.0},
	{"id": "village", "nom": "Hameau de Brekka", "centre": Vector3(53, 0, 10), "rayon": 36.0},
	{"id": "terres", "nom": "Terres Gâtées", "centre": Vector3(151, 0, 100), "rayon": 24.0},
	{"id": "jarnborg", "nom": "Jarnborg, la capitale", "centre": Vector3(-135, 0, -156), "rayon": 70.0},
	{"id": "vik", "nom": "Vik du Lac", "centre": Vector3(-100, 0, -10), "rayon": 30.0},
	{"id": "lac", "nom": "Lac des Brumes", "centre": Vector3(-170, 0, -12), "rayon": 42.0},
	{"id": "hrafn", "nom": "Fort de Hrafn", "centre": Vector3(128, 0, -178), "rayon": 40.0, "hostile": true},
	{"id": "skarn", "nom": "Camp de Skarn", "centre": Vector3(-192, 0, 74), "rayon": 26.0, "hostile": true},
	{"id": "carriere", "nom": "Carrière de Dvalin", "centre": Vector3(40, 0, -102), "rayon": 18.0},
	{"id": "pierres", "nom": "Pierres d'Odin", "centre": Vector3(-18, 0, 50), "rayon": 12.0},
	{"id": "tour", "nom": "Tour du Guet", "centre": Vector3(-6, 0, -66), "rayon": 12.0},
	{"id": "bois", "nom": "Bois des Murmures", "centre": Vector3(80, 0, 70), "rayon": 999.0},
]

# =================== masque du sol ===================
## Une image de 1 px par mètre sur tout le monde :
##   R = terre battue (routes, cours), G = pavés, B = champs labourés, A = eau (fond du lac).
## Le shader du sol la lit, la forêt l'évite, la grille de marche en tire ses routes.

static var masque: Image
static var interdit: Image     ## où la forêt ne pousse pas (L8 : 255 = interdit)

static func taille() -> Vector2i:
	return Vector2i(int(LIMITES.size.x), int(LIMITES.size.y))

static func vers_px(p: Vector2) -> Vector2:
	return p - LIMITES.position

static func preparer() -> void:
	var t := taille()
	masque = Image.create(t.x, t.y, false, Image.FORMAT_RGBA8)
	masque.fill(Color(0, 0, 0, 0))
	interdit = Image.create(t.x, t.y, false, Image.FORMAT_L8)
	interdit.fill(Color(0, 0, 0))

## Valeur du masque (0..1) au point du monde.
static func lire(p: Vector2) -> Color:
	var q := vers_px(p)
	var x := int(q.x)
	var y := int(q.y)
	if x < 0 or y < 0 or x >= masque.get_width() or y >= masque.get_height():
		return Color(0, 0, 0, 0)
	return masque.get_pixel(x, y)

static func est_interdit(p: Vector2) -> bool:
	var q := vers_px(p)
	var x := int(q.x)
	var y := int(q.y)
	if x < 0 or y < 0 or x >= interdit.get_width() or y >= interdit.get_height():
		return false
	return interdit.get_pixel(x, y).r > 0.5

## Peint un canal (0 R, 1 G, 2 B, 3 A) le long d'un segment, bord adouci.
static func segment(a: Vector2, b: Vector2, largeur: float, canal: int, force := 1.0, marge_foret := 4.0) -> void:
	var mini := a.min(b) - Vector2.ONE * (largeur + marge_foret + 1.0)
	var maxi := a.max(b) + Vector2.ONE * (largeur + marge_foret + 1.0)
	var p0 := vers_px(mini)
	var p1 := vers_px(maxi)
	var ab := b - a
	var l2 := maxf(ab.length_squared(), 0.0001)
	for y in range(maxi(0, int(p0.y)), mini(masque.get_height(), int(p1.y) + 1)):
		for x in range(maxi(0, int(p0.x)), mini(masque.get_width(), int(p1.x) + 1)):
			var p := Vector2(x + 0.5, y + 0.5) + LIMITES.position
			var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
			var d := p.distance_to(a + ab * t)
			if d < largeur + 1.0:
				_ecrire(x, y, canal, clampf((largeur + 1.0 - d) / 1.5, 0.0, 1.0) * force)
			if d < largeur + marge_foret:
				interdit.set_pixel(x, y, Color(1, 1, 1))

static func ligne(pts: Array, largeur: float, canal := 0, force := 1.0, marge_foret := 4.0) -> void:
	for i in pts.size() - 1:
		segment(pts[i], pts[i + 1], largeur, canal, force, marge_foret)

static func disque(c: Vector2, r: float, canal: int, force := 1.0, marge_foret := 4.0) -> void:
	segment(c, c + Vector2(0.01, 0), r, canal, force, marge_foret)

static func rect(r: Rect2, canal: int, force := 1.0, marge_foret := 3.0) -> void:
	var p0 := vers_px(r.position - Vector2.ONE * marge_foret)
	var p1 := vers_px(r.end + Vector2.ONE * marge_foret)
	for y in range(maxi(0, int(p0.y)), mini(masque.get_height(), int(p1.y) + 1)):
		for x in range(maxi(0, int(p0.x)), mini(masque.get_width(), int(p1.x) + 1)):
			var p := Vector2(x + 0.5, y + 0.5) + LIMITES.position
			if canal >= 0 and r.has_point(p):
				var bord := minf(minf(p.x - r.position.x, r.end.x - p.x), minf(p.y - r.position.y, r.end.y - p.y))
				_ecrire(x, y, canal, clampf(bord / 1.5, 0.0, 1.0) * force)
			interdit.set_pixel(x, y, Color(1, 1, 1))

## Interdit la forêt sans rien peindre.
static func reserver(r: Rect2) -> void:
	rect(r, -1, 0.0, 0.0)

static func reserver_disque(c: Vector2, r: float) -> void:
	var p0 := vers_px(c - Vector2.ONE * r)
	var p1 := vers_px(c + Vector2.ONE * r)
	for y in range(maxi(0, int(p0.y)), mini(interdit.get_height(), int(p1.y) + 1)):
		for x in range(maxi(0, int(p0.x)), mini(interdit.get_width(), int(p1.x) + 1)):
			if (Vector2(x + 0.5, y + 0.5) + LIMITES.position).distance_to(c) < r:
				interdit.set_pixel(x, y, Color(1, 1, 1))

static func _ecrire(x: int, y: int, canal: int, v: float) -> void:
	var c := masque.get_pixel(x, y)
	match canal:
		0: c.r = maxf(c.r, v)
		1: c.g = maxf(c.g, v)
		2: c.b = maxf(c.b, v)
		3: c.a = maxf(c.a, v)
	masque.set_pixel(x, y, c)

## Le lac : une ellipse un peu bosselée.
static func dans_lac(p: Vector2, marge := 0.0) -> bool:
	return lac_k(p) < 1.0 - marge / LAC_RAYONS.y

static func lac_k(p: Vector2) -> float:
	var d := (p - LAC_CENTRE) / LAC_RAYONS
	var a := atan2(d.y, d.x)
	return d.length() / (1.0 + 0.08 * sin(a * 3.0 + 0.6) + 0.05 * sin(a * 7.0))

static func peindre_lac() -> void:
	var r := Rect2(LAC_CENTRE - LAC_RAYONS * 1.25, LAC_RAYONS * 2.5)
	var p0 := vers_px(r.position)
	var p1 := vers_px(r.end)
	for y in range(maxi(0, int(p0.y)), mini(masque.get_height(), int(p1.y) + 1)):
		for x in range(maxi(0, int(p0.x)), mini(masque.get_width(), int(p1.x) + 1)):
			var p := Vector2(x + 0.5, y + 0.5) + LIMITES.position
			var k := lac_k(p)
			if k < 1.12:
				_ecrire(x, y, 3, clampf((1.12 - k) / 0.25, 0.0, 1.0))
			if k < 1.2:
				interdit.set_pixel(x, y, Color(1, 1, 1))

## Distance à la route la plus proche (toutes routes confondues).
static func distance_routes(p: Vector2) -> float:
	var m := 1e9
	for r in ROUTES:
		var pts: Array = r[0]
		for i in pts.size() - 1:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var ab := b - a
			var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			m = minf(m, p.distance_to(a + ab * t))
	return m

## [distance, point projeté] sur la route la plus proche.
static func proj_routes(p: Vector2) -> Array:
	var m := 1e9
	var proj := p
	for r in ROUTES:
		var pts: Array = r[0]
		for i in pts.size() - 1:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var ab := b - a
			var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			var q := a + ab * t
			var d := p.distance_to(q)
			if d < m:
				m = d
				proj = q
	return [m, proj]

static func lieu_de(p: Vector3) -> Dictionary:
	for l in LIEUX:
		if Vector2(p.x - l["centre"].x, p.z - l["centre"].z).length() <= l["rayon"]:
			return l
	return {}
