extends Node3D
## Animation du bébé dragon : battements d'ailes, flottement, queue qui ondule, tête qui suit.

var _t := 0.0
var vol := true

func _process(delta: float) -> void:
	_t += delta
	var pivot := get_node_or_null("Pivot")
	if pivot == null:
		return
	var b := sin(_t * (12.0 if vol else 3.0))
	pivot.position.y = (0.55 + 0.12 * sin(_t * 3.0)) if vol else 0.0
	for n in ["Aile_g", "Aile_d"]:
		var a := pivot.get_node_or_null(n)
		if a:
			var s := -1.0 if n == "Aile_g" else 1.0
			a.rotation.z = s * (0.25 + 0.65 * b) if vol else s * 0.9
	var q := pivot.get_node_or_null("Queue")
	if q:
		q.rotation.y = 0.35 * sin(_t * 2.4)
	var tete := pivot.get_node_or_null("Tete")
	if tete:
		tete.rotation.x = 0.08 * sin(_t * 1.7)
