extends Node3D
## Outil : rend les icônes d'objets (256 px, fond transparent, vue 3/4) à partir des modèles 3D,
## dans le style des icônes d'inventaire 3D déjà présentes. Lancer : godot --path . res://outils/rendu_icones.tscn

const R := "res://assets/surface/ressources/"
const DJ := "res://assets/donjon/"
const SORTIE := "res://assets/icones_objets/"

var vp: SubViewport
var cam: Camera3D

func _ready() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(256, 256)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.78, 0.9)
	env.environment.ambient_light_energy = 0.75
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	vp.add_child(env)
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-45, 35, 0)
	l.light_energy = 1.4
	vp.add_child(l)
	var l2 := DirectionalLight3D.new()
	l2.rotation_degrees = Vector3(-20, -140, 0)
	l2.light_energy = 0.5
	vp.add_child(l2)
	cam = Camera3D.new()
	cam.fov = 30
	vp.add_child(cam)
	var liste := [
		["minerai_cuivre", R + "Copper_Nuggets.gltf", 1.0], ["minerai_fer", R + "Iron_Nuggets.gltf", 1.0],
		["minerai_argent", R + "Silver_Nuggets.gltf", 1.0], ["minerai_or", R + "Gold_Nuggets.gltf", 1.0],
		["lingots_or", R + "Gold_Bars.gltf", 1.0], ["pieces_or", DJ + "coin_stack_medium.glb", 1.0],
		["pierre", R + "Stone_Chunks_Small.gltf", 1.0], ["tissu", R + "Textiles_A.gltf", 1.0],
	]
	for e in liste:
		var n: Node3D = load(e[1]).instantiate()
		await _rendre(n, e[0])
	for r in DragonVisuel.COULEURS:
		await _rendre(DragonVisuel.oeuf(r), "oeuf_" + r, Vector3(0, 0, 0))
		var d := DragonVisuel.bebe(r)
		d.rotation_degrees.y = -8
		await _rendre(d, "dragon_" + r)
	get_tree().quit()

## Cadre automatiquement l'objet (boîte englobante) et enregistre l'image.
func _rendre(n: Node3D, nom: String, rot := Vector3(0, 30, 0)) -> void:
	vp.add_child(n)
	if rot != Vector3.ZERO:
		n.rotation_degrees += rot
	await get_tree().process_frame
	var acc: Array = [null]
	_aabb(n, n.global_transform, acc)
	var b: AABB = acc[0]
	var c := b.get_center()
	var r := b.size.length() * 0.5
	var dist := r / sin(deg_to_rad(cam.fov * 0.5)) * 1.02
	cam.global_position = c + Vector3(0, 0.55, 1.0).normalized() * dist
	cam.look_at(c, Vector3.UP)
	for i in 3:
		await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(SORTIE + nom + ".png"))
	print("icône : ", nom)
	n.queue_free()
	await get_tree().process_frame

func _aabb(n: Node, xf: Transform3D, acc: Array) -> void:
	if n is MeshInstance3D:
		var bb: AABB = (n as MeshInstance3D).global_transform * (n as MeshInstance3D).get_aabb()
		acc[0] = bb if acc[0] == null else acc[0].merge(bb)
	for ch in n.get_children():
		_aabb(ch, xf, acc)
