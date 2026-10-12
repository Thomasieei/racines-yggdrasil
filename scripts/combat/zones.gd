class_name Zones
## Tests géométriques des zones d'effet, sur le plan du sol (x, z).

static func dans_cercle(p: Vector3, centre: Vector3, rayon: float, marge := 0.0) -> bool:
	return Vector2(p.x - centre.x, p.z - centre.z).length() <= rayon + marge

static func dans_cone(p: Vector3, origine: Vector3, direction: Vector3, rayon: float, demi_angle: float, marge := 0.0) -> bool:
	var d := Vector2(p.x - origine.x, p.z - origine.z)
	var l := d.length()
	if l > rayon + marge:
		return false
	if l < 0.6:
		return true
	var dir := Vector2(direction.x, direction.z).normalized()
	var ang := absf(dir.angle_to(d / l))
	return ang <= demi_angle + atan2(marge, l)

static func dans_ligne(p: Vector3, origine: Vector3, direction: Vector3, longueur: float, largeur: float, marge := 0.0) -> bool:
	var dir := Vector2(direction.x, direction.z).normalized()
	var d := Vector2(p.x - origine.x, p.z - origine.z)
	var t := d.dot(dir)
	if t < -marge or t > longueur + marge:
		return false
	var perp := absf(d.cross(dir))
	return perp <= largeur * 0.5 + marge

## Distance libre devant soi (s'arrête avant un mur ou un pilier), pour les sauts et les ruées.
static func distance_libre(monde: World3D, depart: Vector3, direction: Vector3, maxi: float, exclure: Array[RID] = []) -> float:
	var espace := monde.direct_space_state
	var a := depart + Vector3(0, 0.9, 0)
	var b := a + Vector3(direction.x, 0, direction.z).normalized() * maxi
	var q := PhysicsRayQueryParameters3D.create(a, b)
	q.exclude = exclure
	q.collision_mask = 1
	var r := espace.intersect_ray(q)
	if r.is_empty():
		return maxi
	return maxf(0.0, a.distance_to(r.position) - 0.7)
