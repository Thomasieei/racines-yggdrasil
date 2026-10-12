class_name Telegraphe
extends MeshInstance3D
## Zone rouge au sol qui se remplit jusqu'à l'impact. Visible de tous : c'est le contrat de lisibilité du combat.

enum Forme { CERCLE, CONE, LIGNE }

var duree := 1.0
var _t := 0.0
var _mat: ShaderMaterial

static func creer(parent: Node, forme: Forme, position_sol: Vector3, direction: Vector3, taille: float, largeur_ou_angle: float, duree_s: float, couleur := Color(1.0, 0.18, 0.12)) -> Telegraphe:
	var t := Telegraphe.new()
	var pm := PlaneMesh.new()
	match forme:
		Forme.CERCLE, Forme.CONE:
			pm.size = Vector2(taille * 2.0, taille * 2.0)
		Forme.LIGNE:
			pm.size = Vector2(largeur_ou_angle, taille)
			pm.center_offset = Vector3(0, 0, -taille * 0.5)
	t.mesh = pm
	t._mat = ShaderMaterial.new()
	t._mat.shader = load("res://shaders/telegraphe.gdshader")
	t._mat.set_shader_parameter("forme", int(forme))
	t._mat.set_shader_parameter("couleur", couleur)
	if forme == Forme.CONE:
		t._mat.set_shader_parameter("demi_angle", largeur_ou_angle)
	t.material_override = t._mat
	t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	t.duree = duree_s
	parent.add_child(t)
	t.global_position = position_sol + Vector3(0, 0.05, 0)
	if direction.length() > 0.01:
		t.global_rotation.y = atan2(-direction.x, -direction.z)
	return t

func _process(delta: float) -> void:
	_t += delta
	_mat.set_shader_parameter("progression", clampf(_t / duree, 0.0, 1.0))

## Fin de la préparation : petit éclat puis disparition.
func terminer(annule := false) -> void:
	set_process(false)
	var tw := create_tween()
	if annule:
		tw.tween_method(func(v): _mat.set_shader_parameter("opacite", v), 1.0, 0.0, 0.15)
	else:
		_mat.set_shader_parameter("progression", 1.0)
		tw.tween_method(func(v): _mat.set_shader_parameter("opacite", v), 1.4, 0.0, 0.25)
	tw.tween_callback(queue_free)
