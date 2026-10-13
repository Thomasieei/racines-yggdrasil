class_name DragonVisuel
## Œufs et bébés dragons : modèles de la banque d'assets (œuf à écailles CC0, Dragon Evolved de
## Quaternius CC0), recolorés par shader selon la rareté.

const COULEURS := {
	"commun": [Color(0.32, 0.72, 0.38), Color(0.6, 1.0, 0.65)],
	"rare": [Color(0.24, 0.5, 0.95), Color(0.55, 0.85, 1.0)],
	"epique": [Color(0.55, 0.3, 0.9), Color(0.85, 0.6, 1.0)],
	"legendaire": [Color(0.95, 0.55, 0.15), Color(1.0, 0.85, 0.4)],
	"mythique": [Color(0.85, 0.14, 0.16), Color(1.0, 0.5, 0.35)],
}

## Œuf : modèle à écailles en relief (banque d'assets, CC0), recoloré selon la rareté.
## Les deux matières (coque, écailles) sont dans la méta « mats » pour animer l'éclosion.
static func oeuf(rarete: String) -> Node3D:
	var n := Node3D.new()
	var m: Node3D = load("res://assets/dragons/DragonEgg_Fire.glb").instantiate()
	m.scale = Vector3.ONE * 0.53
	n.add_child(m)
	var mats: Array = []
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/oeuf_modele.gdshader")
		mat.set_shader_parameter("couleur", COULEURS[rarete][0])
		mat.set_shader_parameter("veine", COULEURS[rarete][1])
		mat.set_shader_parameter("sombre", 1.0 if mi.name == "EggShell" else 0.0)
		mi.material_override = mat
		mats.append(mat)
	n.set_meta("mats", mats)
	return n

## Bébé dragon : Dragon Evolved de Quaternius (CC0, animé), recoloré selon la rareté.
## Racine orientée vers +z. Hauteur ~0,9 m à l'échelle 1 ; l'acolyte le fait grandir avec son niveau.
static func bebe(rarete: String) -> Node3D:
	var racine := Node3D.new()
	var pivot := Node3D.new()
	pivot.name = "Pivot"
	racine.add_child(pivot)
	var m: Node3D = load("res://assets/dragons/Dragon_Evolved.gltf").instantiate()
	m.scale = Vector3.ONE * 0.32
	m.name = "Modele"
	pivot.add_child(m)
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var src = mi.mesh.surface_get_material(0)
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/dragon_teinte.gdshader")
		if src is StandardMaterial3D:
			mat.set_shader_parameter("atlas", src.albedo_texture)
		mat.set_shader_parameter("peau", COULEURS[rarete][0])
		mat.set_shader_parameter("membrane", COULEURS[rarete][1].darkened(0.15))
		mat.set_shader_parameter("lueur", 0.6 + Objets.RARETES.find(rarete) * 0.35)
		mi.material_override = mat
	racine.set_script(load("res://scripts/objets/dragon_anime.gd"))
	return racine
