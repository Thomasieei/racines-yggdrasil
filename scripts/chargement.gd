extends CanvasLayer
## Écran de chargement + préchauffage.
## Le moteur compile chaque effet (shader) la première fois qu'il apparaît à l'écran : sur téléphone,
## c'est ce qui fait « laguer » les premières secondes. Ici on fait apparaître une fois chaque effet,
## chaque monstre et chaque matériau derrière l'écran de chargement, pour que tout soit prêt avant de jouer.

const PHRASES := [
	"Freya rassemble tes os…",
	"Les racines d'Yggdrasil s'ouvrent…",
	"Les draugr se lèvent dans le noir…",
]

var _fond: ColorRect
var _titre: Label
var _texte: Label
var _barre: ColorRect
var _progres := 0.0

func _ready() -> void:
	layer = 50
	_fond = ColorRect.new()
	_fond.color = Color(0.03, 0.035, 0.06)
	_fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fond.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fond)
	var icone := TextureRect.new()
	icone.texture = load("res://icone.png")
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.size = Vector2(140, 140)
	icone.position = Vector2(640 - 70, 150)
	_fond.add_child(icone)
	_titre = _label("Racines d'Yggdrasil", 34, Color("#F4C35A"), 306)
	_texte = _label(PHRASES[randi() % PHRASES.size()], 16, Color("#CFD6EE"), 352)
	var cadre := ColorRect.new()
	cadre.color = Color(0, 0, 0, 0.6)
	cadre.position = Vector2(440, 400)
	cadre.size = Vector2(400, 8)
	_fond.add_child(cadre)
	_barre = ColorRect.new()
	_barre.color = Color("#F4C35A")
	_barre.position = Vector2(441, 401)
	_barre.size = Vector2(0, 6)
	_fond.add_child(_barre)

func _label(t: String, taille: int, c: Color, y: float) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", c)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.position = Vector2(0, y)
	l.size = Vector2(1280, 40)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fond.add_child(l)
	return l

func _avancer(k: float) -> void:
	_progres = maxf(_progres, k)
	_barre.size.x = 398.0 * _progres

## Fait apparaître une fois chaque effet devant la caméra (caché par l'écran), puis nettoie.
func prechauffer(p: Node) -> void:
	_avancer(0.4)
	var h: Node3D = p.joueur
	if h == null:
		return
	var o: Vector3 = h.global_position + Vector3(0, 0, -3)
	var temp := Node3D.new()
	p.add_child(temp)
	var d := Vector3(0, 0, -1)
	var telegs := [
		Telegraphe.creer(temp, Telegraphe.Forme.CERCLE, o, Vector3.ZERO, 2.0, 0.0, 1.0),
		Telegraphe.creer(temp, Telegraphe.Forme.CONE, o, d, 2.0, 0.8, 1.0),
		Telegraphe.creer(temp, Telegraphe.Forme.LIGNE, o, d, 4.0, 1.0, 1.0, Color(0.5, 0.88, 1.0)),
	]
	Effets.taille(temp, o, d, 2.0, Color(1, 0.8, 0.5))
	Effets.onde(temp, o, 2.0, Color(1, 0.7, 0.4))
	Effets.etincelles(temp, o + Vector3(0, 1, 0), Vector3.UP, Color.WHITE, 6)
	Effets.etincelles(temp, o + Vector3(0, 1, 0), Vector3.UP, Color.WHITE, 6, 3.0, "magic_03.png")
	Effets.etincelles(temp, o + Vector3(0, 1, 0), Vector3.UP, Color.WHITE, 6, 3.0, "star_06.png")
	Effets.poussiere(temp, o, 4)
	Effets.flash_lumiere(temp, o, Color.WHITE, 1.0, 4.0, 0.5)
	Effets.trainee_lumineuse(temp, Color.WHITE)
	Effets.nombre(temp, o, "0", Color.WHITE)
	# un exemplaire de chaque monstre (modèles, armes, animations)
	for t in Draugr.TYPES:
		var dr := Draugr.new()
		dr.configurer(t)
		dr.position = o + Vector3(randf_range(-3, 3), -50, randf_range(-2, 2))
		temp.add_child(dr)
		dr.modele.visible = true
		dr.position.y = 0.0
		dr.set_physics_process(false)
		dr.remove_from_group("monstre")
		dr.remove_from_group("combattants")
	# le chevalier des autres aventuriers et un bébé dragon (acolytes)
	if p.carte == "crypte":
		var ch: Node3D = load("res://assets/personnages/chevalier.glb").instantiate()
		temp.add_child(ch)
		ch.position = o + Vector3(2, 0, 0)
		var bb: Node3D = DragonVisuel.bebe("rare")
		temp.add_child(bb)
		bb.position = o + Vector3(-2, 1, 0)
	# la bulle de Freya (shader le plus lourd)
	if h.get("bulle") and h.bulle.has_method("activer"):
		h.bulle.visible = true
	for i in 4:
		_avancer(0.4 + 0.15 * i)
		await get_tree().process_frame
	if h.get("bulle") and h.bulle.has_method("activer"):
		h.bulle.visible = false
	for t in telegs:
		if is_instance_valid(t):
			t.queue_free()
	temp.queue_free()
	_avancer(1.0)
	await get_tree().process_frame

func disparaitre() -> void:
	var tw := create_tween()
	tw.tween_property(_fond, "modulate:a", 0.0, 0.45)
	tw.tween_callback(queue_free)
