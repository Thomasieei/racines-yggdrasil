extends Node
## Qualité graphique adaptative. Le jeu mesure lui-même sa fluidité pendant les premières secondes
## et baisse la qualité tout seul si le téléphone peine. Le choix est retenu pour les parties suivantes.
##   2 = haute   : ombres, anticrénelage, pleine résolution
##   1 = moyenne : ombres proches seulement, pas d'anticrénelage, résolution 3D à 85 %
##   0 = fluide  : pas d'ombres, résolution 3D à 72 %

const FICHIER := "user://reglages.cfg"

var niveau := 2
var _mesures: Array[float] = []
var _t := 0.0
var _bas := 0
var _compteur: Label
var _verrou := false

func _ready() -> void:
	Engine.max_fps = 60
	var cfg := ConfigFile.new()
	if cfg.load(FICHIER) == OK:
		niveau = int(cfg.get_value("graphismes", "niveau", niveau))
		_verrou = bool(cfg.get_value("graphismes", "manuel", false))
	elif OS.has_feature("mobile"):
		niveau = 1
	appliquer()
	# petit compteur d'images par seconde dans le coin (utile pour les essais)
	var c := CanvasLayer.new()
	c.layer = 40
	add_child(c)
	_compteur = Label.new()
	_compteur.position = Vector2(8, 556)
	_compteur.add_theme_font_size_override("font_size", 11)
	_compteur.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	_compteur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(_compteur)

func appliquer() -> void:
	var vp := get_viewport()
	vp.msaa_3d = Viewport.MSAA_2X if niveau >= 2 else Viewport.MSAA_DISABLED
	vp.scaling_3d_scale = [0.72, 0.85, 1.0][niveau]
	for l in get_tree().get_nodes_in_group("soleil"):
		var d := l as DirectionalLight3D
		d.shadow_enabled = niveau >= 1
		d.directional_shadow_max_distance = 42.0 if niveau >= 2 else 26.0
		d.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if niveau >= 2 else DirectionalLight3D.SHADOW_ORTHOGONAL

func enregistrer(manuel := false) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("graphismes", "niveau", niveau)
	cfg.set_value("graphismes", "manuel", manuel)
	cfg.save(FICHIER)

func _process(delta: float) -> void:
	_t += delta
	var fps := Engine.get_frames_per_second()
	_compteur.text = "%d i/s · qualité %s" % [fps, ["fluide", "moyenne", "haute"][niveau]]
	if _verrou or _t < 4.0:
		return
	# toutes les 2 s : si on reste sous 45 images/s deux fois de suite, on baisse d'un cran
	if fmod(_t, 2.0) < delta:
		if fps < 45.0 and niveau > 0:
			_bas += 1
			if _bas >= 2:
				niveau -= 1
				_bas = 0
				appliquer()
				enregistrer()
		else:
			_bas = 0
