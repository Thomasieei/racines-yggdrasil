class_name NavCaverne
extends RefCounted
## Grille de déplacement de la caverne pour les aventuriers pilotés par l'IA.
## Une case de 1 m est praticable si elle est dans le contour de la grotte (ou la crypte)
## et qu'aucun obstacle physique (rochers, murs, colonnes) ne l'occupe.
## La construction est étalée sur plusieurs images pour ne pas faire sauter l'écran.

const CASE := 1.0

var astar := AStarGrid2D.new()
var origine := Vector2.ZERO
var pret := false

func construire(arbre: SceneTree, monde: World3D, lot := 2500) -> void:
	var poly := PackedVector2Array()
	var mini := Vector2(1e9, 1e9)
	var maxi := Vector2(-1e9, -1e9)
	for q in Caverne.CONTOUR:
		poly.append(q)
		mini = mini.min(q)
		maxi = maxi.max(q)
	var crypte := Rect2(0, 0, 28, 28)
	mini = mini.min(crypte.position)
	maxi = maxi.max(crypte.end)
	origine = mini
	var taille := Vector2i(int(ceil((maxi.x - mini.x) / CASE)) + 1, int(ceil((maxi.y - mini.y) / CASE)) + 1)
	astar.region = Rect2i(Vector2i.ZERO, taille)
	astar.cell_size = Vector2(CASE, CASE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()
	var espace := monde.direct_space_state
	var sphere := SphereShape3D.new()
	sphere.radius = 0.45
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = sphere
	q.collision_mask = 1
	var n := 0
	for x in taille.x:
		for y in taille.y:
			var p := mini + Vector2(x + 0.5, y + 0.5) * CASE
			var dedans := crypte.grow(-0.5).has_point(p) or Geometry2D.is_point_in_polygon(p, poly)
			if dedans:
				q.transform = Transform3D(Basis(), Vector3(p.x, 1.1, p.y))
				dedans = espace.intersect_shape(q, 1).is_empty()
			astar.set_point_solid(Vector2i(x, y), not dedans)
			n += 1
			if n % lot == 0:
				await arbre.physics_frame
	pret = true

func case_de(p: Vector3) -> Vector2i:
	return Vector2i(int(floor((p.x - origine.x) / CASE)), int(floor((p.z - origine.y) / CASE)))

func centre(c: Vector2i) -> Vector3:
	var v := origine + (Vector2(c) + Vector2(0.5, 0.5)) * CASE
	return Vector3(v.x, 0, v.y)

func praticable(c: Vector2i) -> bool:
	return astar.is_in_boundsv(c) and not astar.is_point_solid(c)

## Case praticable la plus proche (spirale), pour partir ou arriver hors d'un rocher.
func libre_pres(p: Vector3) -> Vector2i:
	var c := case_de(p)
	if praticable(c):
		return c
	for r in range(1, 12):
		for dx in range(-r, r + 1):
			for dy in [-r, r]:
				if praticable(c + Vector2i(dx, dy)):
					return c + Vector2i(dx, dy)
				if praticable(c + Vector2i(dy, dx)):
					return c + Vector2i(dy, dx)
	return c

## Chemin en points du monde (sans le point de départ), lissé : on saute les cases
## alignées pour que la marche ne zigzague pas.
func chemin(de: Vector3, vers: Vector3) -> PackedVector3Array:
	var res := PackedVector3Array()
	if not pret:
		res.append(vers)
		return res
	var a := libre_pres(de)
	var b := libre_pres(vers)
	if not praticable(a) or not praticable(b):
		return res
	var ids := astar.get_id_path(a, b)
	if ids.is_empty():
		return res
	var dir_prec := Vector2i.ZERO
	for i in range(1, ids.size()):
		var d: Vector2i = ids[i] - ids[i - 1]
		if d != dir_prec and i > 1:
			res.append(centre(ids[i - 1]))
		dir_prec = d
	res.append(centre(ids[ids.size() - 1]))
	return res
