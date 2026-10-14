class_name NavMonde
extends RefCounted
## Grille de marche des habitants sur toute la surface (1 case = 1 m). Les murs, maisons, troncs
## et le lac sont bloquants ; les routes et les pavés coûtent moins cher : les gens les suivent.

static var grille: AStarGrid2D
static var _taille := Vector2i.ZERO
static var _image_frame := -1
static var _calculs := 0
const CALCULS_PAR_IMAGE := 3

static func pret() -> bool:
	return grille != null

static func construire(c: CarteSurface) -> void:
	var r := PlanMonde.LIMITES
	_taille = Vector2i(int(r.size.x), int(r.size.y))
	grille = AStarGrid2D.new()
	grille.region = Rect2i(Vector2i.ZERO, _taille)
	grille.cell_size = Vector2.ONE
	grille.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grille.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grille.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	# saut de points (JPS) : beaucoup plus rapide sur une grande grille ouverte
	grille.jumping_enabled = true
	grille.update()
	var m := PlanMonde.masque
	for y in _taille.y:
		for x in _taille.x:
			var px := m.get_pixel(x, y)
			if px.a > 0.55 and not CarteSurface.PONTON.has_point(Vector2(x + 0.5, y + 0.5) + r.position):
				grille.set_point_solid(Vector2i(x, y), true)
	for o in c.obstacles:
		_boite(o[0], o[1], o[2])
	for o2 in c.obstacles_ronds:
		_rond(o2[0], o2[1] + 0.35)
	_zones()

## Zones connexes : deux cases de zones différentes ne se rejoignent pas — inutile de chercher
## (une recherche sans issue parcourrait toute la grille).
static var zone := PackedInt32Array()

static func _zones() -> void:
	var w := _taille.x
	var h := _taille.y
	zone.resize(w * h)
	zone.fill(0)
	var n := 0
	var pile := PackedInt32Array()
	for y in h:
		for x in w:
			var i := y * w + x
			if zone[i] != 0 or grille.is_point_solid(Vector2i(x, y)):
				continue
			n += 1
			zone[i] = n
			pile.clear()
			pile.append(i)
			while not pile.is_empty():
				var k := pile[pile.size() - 1]
				pile.remove_at(pile.size() - 1)
				var kx := k % w
				var ky := k / w
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var qx: int = kx + d.x
					var qy: int = ky + d.y
					if qx < 0 or qy < 0 or qx >= w or qy >= h:
						continue
					var j := qy * w + qx
					if zone[j] == 0 and not grille.is_point_solid(Vector2i(qx, qy)):
						zone[j] = n
						pile.append(j)

static func _zone(c: Vector2i) -> int:
	return zone[c.y * _taille.x + c.x] if _dedans(c) and not zone.is_empty() else 0

static func _cellule(p: Vector3) -> Vector2i:
	return Vector2i(int(floor(p.x - PlanMonde.LIMITES.position.x)), int(floor(p.z - PlanMonde.LIMITES.position.y)))

static func _centre(c: Vector2i) -> Vector3:
	return Vector3(c.x + 0.5 + PlanMonde.LIMITES.position.x, 0, c.y + 0.5 + PlanMonde.LIMITES.position.y)

static func _dedans(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < _taille.x and c.y < _taille.y

static func _boite(centre: Vector3, taille: Vector3, rot: float) -> void:
	var demi := Vector2(taille.x, taille.z) * 0.5 + Vector2(0.4, 0.4)
	var rayon := demi.length()
	var c0 := _cellule(centre - Vector3(rayon, 0, rayon))
	var c1 := _cellule(centre + Vector3(rayon, 0, rayon))
	var co := cos(rot)
	var si := sin(rot)
	for y in range(maxi(0, c0.y), mini(_taille.y, c1.y + 1)):
		for x in range(maxi(0, c0.x), mini(_taille.x, c1.x + 1)):
			var p := _centre(Vector2i(x, y)) - centre
			# repère local de la boîte (rotation inverse autour de y)
			var lx := p.x * co - p.z * si
			var lz := p.x * si + p.z * co
			if absf(lx) < demi.x and absf(lz) < demi.y:
				grille.set_point_solid(Vector2i(x, y), true)

static func _rond(p: Vector3, r: float) -> void:
	var c0 := _cellule(p - Vector3(r, 0, r))
	var c1 := _cellule(p + Vector3(r, 0, r))
	for y in range(maxi(0, c0.y), mini(_taille.y, c1.y + 1)):
		for x in range(maxi(0, c0.x), mini(_taille.x, c1.x + 1)):
			if _centre(Vector2i(x, y)).distance_to(Vector3(p.x, 0, p.z)) < r:
				grille.set_point_solid(Vector2i(x, y), true)

static func est_libre(p: Vector3) -> bool:
	var c := _cellule(p)
	return _dedans(c) and not grille.is_point_solid(c)

## Case libre la plus proche (spirale), ou (-1, -1).
static func _libre_proche(c: Vector2i) -> Vector2i:
	if _dedans(c) and not grille.is_point_solid(c):
		return c
	for r in range(1, 9):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var q := c + Vector2i(dx, dy)
				if _dedans(q) and not grille.is_point_solid(q):
					return q
	return Vector2i(-1, -1)

static func point_libre(p: Vector3) -> Vector3:
	var c := _libre_proche(_cellule(p))
	return p if c.x < 0 else _centre(c)

## Peut-on calculer un chemin maintenant ? (quelques-uns par image, pas plus)
static func peut_calculer() -> bool:
	var f := Engine.get_process_frames()
	if f != _image_frame:
		_image_frame = f
		_calculs = 0
	return _calculs < CALCULS_PAR_IMAGE

## Chemin lissé de a vers b (points au sol), vide si impossible.
static var mesure_us := 0
static var mesure_n := 0
static var mesure_astar_us := 0

static func chemin(a: Vector3, b: Vector3) -> PackedVector3Array:
	var t0 := Time.get_ticks_usec()
	var r := _chemin(a, b)
	mesure_us += Time.get_ticks_usec() - t0
	mesure_n += 1
	return r

static func _chemin(a: Vector3, b: Vector3) -> PackedVector3Array:
	var res := PackedVector3Array()
	if grille == null:
		res.append(b)
		return res
	_calculs += 1
	var ca := _libre_proche(_cellule(a))
	var cb := _libre_proche(_cellule(b))
	if ca.x < 0 or cb.x < 0:
		return res
	if _zone(ca) != _zone(cb):
		return res
	var t1 := Time.get_ticks_usec()
	var ids := grille.get_id_path(ca, cb)
	mesure_astar_us += Time.get_ticks_usec() - t1
	if ids.is_empty():
		return res
	# on tire la ficelle : on saute les cases tant qu'on voit plus loin en ligne droite
	var i := 0
	while i < ids.size() - 1:
		var j := i + 1
		for saut in [48, 24, 12, 6, 3]:
			var k := mini(ids.size() - 1, i + saut)
			if k > i + 1 and _vue(ids[i], ids[k]):
				j = k
				break
		res.append(_centre(ids[j]))
		i = j
	if res.size() > 0 and est_libre(b):
		res[res.size() - 1] = Vector3(b.x, 0, b.z)
	return res

## Ligne droite libre entre deux cases.
static func _vue(a: Vector2i, b: Vector2i) -> bool:
	var d := b - a
	var n := maxi(absi(d.x), absi(d.y))
	for k in range(1, n):
		var q := Vector2i(roundi(a.x + d.x * float(k) / n), roundi(a.y + d.y * float(k) / n))
		if grille.is_point_solid(q):
			return false
	return true
