class_name PortailRetour
extends Node3D
## Racine de retour, dans les camps sûrs : on remonte à la surface AVEC son sac.
## C'est l'extraction : 5 s de canalisation, interrompues si l'on est frappé.

var rayon := 3.4
var _anneau: MeshInstance3D
var _lueur: OmniLight3D
var _t := 0.0

static func creer(parent: Node, pos: Vector3) -> PortailRetour:
	var p := PortailRetour.new()
	p.position = pos
	parent.add_child(p)
	return p

func _ready() -> void:
	add_to_group("interactif")
	# cercle runique doré au sol
	_anneau = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(4.2, 4.2)
	_anneau.mesh = pm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float anneau = smoothstep(0.05, 0.0, abs(r - 0.88)) + smoothstep(0.03, 0.0, abs(r - 0.72)) * 0.6;
	float runes = step(0.72, r) * step(r, 0.88) * step(0.55, fract(a * 4.0 / 3.14159 - TIME * 0.08)) * 0.4;
	float coeur = smoothstep(0.7, 0.0, r) * 0.25;
	vec3 c = vec3(1.0, 0.78, 0.4) * (anneau + runes + coeur) * (0.8 + 0.2 * sin(TIME * 2.0));
	ALBEDO = c;
	ALPHA = clamp(max(c.r, c.g), 0.0, 1.0);
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	_anneau.material_override = sm
	_anneau.position.y = 0.04
	add_child(_anneau)
	# colonne de lumière montante
	var colonne := MeshInstance3D.new()
	var cy := CylinderMesh.new()
	cy.top_radius = 1.1
	cy.bottom_radius = 1.4
	cy.height = 7.0
	cy.cap_top = false
	cy.cap_bottom = false
	colonne.mesh = cy
	var cm := StandardMaterial3D.new()
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	cm.cull_mode = BaseMaterial3D.CULL_DISABLED
	cm.disable_fog = true
	cm.albedo_color = Color(1.0, 0.8, 0.45, 0.08)
	colonne.material_override = cm
	colonne.position.y = 3.5
	add_child(colonne)
	_lueur = OmniLight3D.new()
	_lueur.light_color = Color(1.0, 0.8, 0.45)
	_lueur.omni_range = 7.0
	_lueur.light_energy = 1.6
	_lueur.position.y = 1.5
	add_child(_lueur)
	var p := CPUParticles3D.new()
	p.amount = 20
	p.lifetime = 2.5
	var q := QuadMesh.new()
	q.size = Vector2(0.14, 0.14)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.albedo_color = Color(1.0, 0.85, 0.5, 0.8)
	qm.disable_fog = true
	q.material = qm
	p.mesh = q
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_radius = 1.6
	p.emission_ring_inner_radius = 1.2
	p.emission_ring_height = 0.1
	p.emission_ring_axis = Vector3.UP
	p.direction = Vector3.UP
	p.spread = 5.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 2.2
	add_child(p)
	var lab := Label3D.new()
	lab.text = "Racine de retour"
	lab.font_size = 44
	lab.outline_size = 10
	lab.modulate = Color("#FFE2A0")
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.position.y = 3.2
	lab.pixel_size = 0.01
	lab.no_depth_test = true
	add_child(lab)

func _process(delta: float) -> void:
	_t += delta
	_lueur.light_energy = 1.4 + 0.4 * sin(_t * 2.0)

func texte_action() -> String:
	return "Remonter"

func disponible() -> bool:
	return true

func interagir(h: Heros) -> void:
	if h != Jeu.joueur:
		return
	Jeu.notifier("Remontée… ne te fais pas toucher.", Color("#FFE2A0"))
	h.canaliser("Remontée vers la surface", 5.0, "Interact")
	var res: Array = await h.canal_fini
	if not res[1]:
		Jeu.notifier("Remontée interrompue.", Color("#FFB37A"))
		return
	Effets.onde(get_parent(), global_position, 4.0, Color(1.0, 0.8, 0.45))
	Sons.jouer("activation", global_position, 0.0, 0.8)
	var p := get_tree().current_scene
	if p.has_method("extraire"):
		p.extraire()
