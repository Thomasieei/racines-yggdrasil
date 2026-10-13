class_name Epreuve
extends Node3D
## Épreuve du Sang-Dragon : une arène ronde hors du monde, seul, sans arme, sans relique, sans talent.
## Trois vagues, puis le Gardien de la rune. Vaincre = choisir sa voie draconique. Tomber = l'œuf
## retourne au sac, on pourra retenter.

const D := "res://assets/donjon/"
const RAYON := 15.0
const DEPART := Vector3(0, 0.1, 10)

var principale: Node
var heros: Heros
var hud: CanvasLayer
var recit: CanvasLayer
var _vague := 0
var _vivants: Array = []
var _fini := false

## Garde le sac du joueur pendant l'épreuve, et l'œuf s'il échoue.
static var sac_garde: Sac
static var oeuf_garde: Dictionary = {}

func _ready() -> void:
	_sol()
	_enceinte()
	_lumieres()

func _sol() -> void:
	for i in range(-4, 4):
		for j in range(-4, 4):
			var c := Vector3(i * 4 + 2, 0, j * 4 + 2)
			var n: Node3D = load(D + ("floor_tile_large_rocks" if (i * 7 + j * 3) % 5 == 0 else "floor_tile_large") + ".glb").instantiate()
			n.position = c
			n.rotation_degrees.y = 90.0 * ((i + j) % 4)
			add_child(n)
			for m in n.find_children("*", "MeshInstance3D", true, false):
				for k in m.mesh.get_surface_count():
					var mat = m.mesh.surface_get_material(k)
					if mat is StandardMaterial3D:
						var c2: StandardMaterial3D = mat.duplicate()
						c2.albedo_color = c2.albedo_color * Color(0.42, 0.4, 0.5)
						m.set_surface_override_material(k, c2)
	var corps := StaticBody3D.new()
	var f := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(40, 1, 40)
	f.shape = b
	f.position.y = -0.5
	corps.add_child(f)
	add_child(corps)
	# cercle runique au sol
	var cercle := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(RAYON * 2.0, RAYON * 2.0)
	cercle.mesh = pm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
uniform float t = 0.0;
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float anneau = smoothstep(0.03, 0.0, abs(r - 0.93)) + smoothstep(0.02, 0.0, abs(r - 0.86)) * 0.6;
	float runes = step(0.86, r) * step(r, 0.93) * step(0.5, fract(a * 6.0 / 3.14159 + TIME * 0.05)) * 0.35;
	float centre = smoothstep(0.02, 0.0, abs(r - 0.25)) * 0.7 + smoothstep(0.015, 0.0, abs(r - 0.18)) * 0.4;
	float rayons = step(r, 0.86) * step(0.25, r) * smoothstep(0.012, 0.0, abs(fract(a * 4.0 / 3.14159) - 0.5) * r) * 0.25;
	float puls = 0.75 + 0.25 * sin(TIME * 1.5);
	vec3 c = vec3(0.65, 0.35, 1.0) * (anneau + runes + centre + rayons) * puls;
	ALBEDO = c;
	ALPHA = clamp(max(max(c.r, c.g), c.b), 0.0, 1.0);
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	cercle.material_override = sm
	cercle.position.y = 0.03
	add_child(cercle)

func _enceinte() -> void:
	# huit piliers et une barrière invisible tout autour
	for i in 8:
		var a := TAU * i / 8.0 + PI / 8.0
		var p := Vector3(cos(a), 0, sin(a)) * (RAYON + 1.5)
		var n: Node3D = load(D + "pillar_decorated.glb").instantiate()
		n.position = p
		n.rotation.y = -a
		add_child(n)
		var bougie: Node3D = load(D + "candle_triple.glb").instantiate()
		bougie.position = p + (Vector3.ZERO - p).normalized() * 1.4
		add_child(bougie)
		var l := OmniLight3D.new()
		l.light_color = Color(0.75, 0.45, 1.0) if i % 2 == 0 else Color(1.0, 0.65, 0.35)
		l.omni_range = 9.0
		l.light_energy = 1.4
		l.position = bougie.position + Vector3(0, 1.2, 0)
		add_child(l)
	for i in 24:
		var a := TAU * i / 24.0
		var corps := StaticBody3D.new()
		var f := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = Vector3(4.4, 4, 1)
		f.shape = b
		corps.add_child(f)
		corps.position = Vector3(cos(a), 0, sin(a)) * (RAYON + 0.6) + Vector3(0, 2, 0)
		corps.rotation.y = -a + PI / 2.0
		add_child(corps)

func _lumieres() -> void:
	var l := OmniLight3D.new()
	l.light_color = Color(0.7, 0.5, 1.0)
	l.omni_range = 22.0
	l.light_energy = 0.8
	l.position = Vector3(0, 7, 0)
	add_child(l)

func demarrer(p: Node, h: Heros, hd: CanvasLayer) -> void:
	principale = p
	heros = h
	hud = hd
	recit = CanvasLayer.new()
	recit.set_script(load("res://scripts/interface/recit.gd"))
	add_child(recit)
	recit.heros = h
	hud.regler_titre("Épreuve du Sang-Dragon", "Seul. Sans arme, sans relique, sans talent.", Color("#C9A2FF"))
	heros.mort.connect(func(_e): _echec())
	await get_tree().create_timer(1.5).timeout
	recit.bandeau("Épreuve du Sang-Dragon", "Ici, ton équipement ne compte pas. Seulement toi.", Color("#C9A2FF"))
	await get_tree().create_timer(3.0).timeout
	_lancer_vague()
	if "--test-epreuve" in OS.get_cmdline_user_args():
		_test()

const VAGUES := [
	[["minion", 6]],
	[["guerrier", 2], ["arbaletrier", 2], ["mage", 1]],
	[["gardien", 1], ["minion", 3]],
]

func _lancer_vague() -> void:
	if _vague >= VAGUES.size():
		_victoire()
		return
	var v: Array = VAGUES[_vague]
	recit.bandeau("Vague %d / 3" % (_vague + 1) if _vague < 2 else "Le Gardien de la rune", "" if _vague < 2 else "Il garde le sang des dragons depuis mille hivers.", Color("#FF9C8A"))
	_vivants.clear()
	var k := 0
	for g in v:
		for i in g[1]:
			var d := Draugr.new()
			if g[0] == "gardien":
				d.configurer("brokk")
				d.fiche = d.fiche.duplicate(true)
				d.fiche["nom"] = "Gardien de la rune"
				d.fiche["pv"] = 2600.0
				d.type = "gardien"
			else:
				d.configurer(g[0])
			var a := TAU * k / 7.0 + 0.4
			d.position = Vector3(cos(a), 0, sin(a)) * 9.0 + Vector3(0, 0, -2)
			d.aggro_rayon = 40.0
			add_child(d)
			d.reveiller(heros)
			_vivants.append(d)
			Effets.poussiere(self, d.position, 10, Color(0.6, 0.45, 0.8, 0.6))
			k += 1
	_vague += 1

func _process(_d: float) -> void:
	if _fini or _vague == 0 or heros == null or heros.est_mort:
		return
	_vivants = _vivants.filter(func(x): return is_instance_valid(x) and not x.est_mort)
	if _vivants.is_empty():
		_fini = true
		await get_tree().create_timer(2.0).timeout
		_fini = false
		_lancer_vague()

func _victoire() -> void:
	_fini = true
	oeuf_garde = {}
	Sons.jouer("cloche", heros.global_position, 2.0, 0.7)
	recit.bandeau("Le sang du dragon t'a reconnu", "Choisis ta voie", Color("#FFD34E"))
	await get_tree().create_timer(2.5).timeout
	var c := CanvasLayer.new()
	c.set_script(load("res://scripts/interface/choix_classe_ui.gd"))
	add_child(c)
	c.choisi.connect(func(_id):
		await get_tree().create_timer(2.5).timeout
		principale.changer_carte("surface", true))

func _echec() -> void:
	_fini = true
	recit.bandeau("L'épreuve t'a rejeté", "L'œuf runique retourne dans ton sac. Reviens plus fort.", Color("#FF9C8A"))

func _cap(nom: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/scr/epreuve_%s.png" % nom)

func _test() -> void:
	heros.invulnerable_t = 1e9
	await get_tree().create_timer(2.5).timeout
	await _cap("vague1")
	for i in 3:
		await get_tree().create_timer(1.0).timeout
		if i == 2:
			await get_tree().create_timer(2.0).timeout
			await _cap("gardien")
		for d in _vivants.duplicate():
			if is_instance_valid(d):
				d.recevoir({"montant": 1e6, "source": heros})
		await get_tree().create_timer(3.0).timeout
	await get_tree().create_timer(3.5).timeout
	await _cap("choix")
	var ui = null
	for c in get_children():
		if c.has_signal("choisi"):
			ui = c
	ui._toucher("ailes")
	await get_tree().create_timer(0.3).timeout
	await _cap("choix_ailes")
	ui._toucher("ailes")
	await get_tree().create_timer(0.5).timeout
	printerr("TEST classe=", Profil.p().classe)
	get_tree().quit()
