extends Control
## Chiffres de dégâts et mots d'état, dessinés en 2D au-dessus du monde projeté :
## toujours nets, jamais assombris par le brouillard, même taille près ou loin.


var _items: Array = []
var _police: Font

func _ready() -> void:
	Effets.calque_nombres = self
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Noto Sans", "DejaVu Sans", "Sans-Serif"])
	f.font_weight = 800
	_police = f

func _exit_tree() -> void:
	if Effets.calque_nombres == self:
		Effets.calque_nombres = null

## genre : "degat", "critique", "subi", "absorbe", "etat"
func ajouter(ou: Vector3, texte: String, couleur: Color, genre := "degat") -> void:
	# les chiffres d'une même cible s'écartent en éventail au lieu de s'empiler
	var voisins := 0
	for it in _items:
		if it["ou"].distance_to(ou) < 1.0 and it["t"] < 0.6 and it["genre"] != "etat":
			voisins += 1
	var dx: float = [0.0, 34.0, -34.0, 60.0, -60.0][voisins % 5] + randf_range(-6.0, 6.0)
	var dy := 0.0
	if genre == "etat":
		# les mots d'état s'empilent verticalement, centrés
		dx = 0.0
		for it in _items:
			if it["genre"] == "etat" and it["ou"].distance_to(ou) < 1.5 and it["t"] < 0.8:
				dy -= 22.0
	_items.append({"ou": ou, "texte": texte, "couleur": couleur, "genre": genre, "t": 0.0, "dx": dx, "dy": dy})

func _process(delta: float) -> void:
	for it in _items:
		it["t"] += delta
	_items = _items.filter(func(it): return it["t"] < (1.1 if it["genre"] == "etat" else 0.9))
	queue_redraw()

func _draw() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	for it in _items:
		var ou: Vector3 = it["ou"] + Vector3(0, 2.3 if it["genre"] != "etat" else 2.9, 0)
		if cam.is_position_behind(ou):
			continue
		var p := cam.unproject_position(ou)
		var t: float = it["t"]
		var taille := 26
		match it["genre"]:
			"critique": taille = 38
			"subi": taille = 28
			"absorbe": taille = 22
			"etat": taille = 17
		# pop : grossit vite puis se pose ; monte en ralentissant ; s'efface à la fin
		var pop := 1.0 + 0.45 * maxf(0.0, 1.0 - t / 0.12)
		var montee := 46.0 * (1.0 - pow(1.0 - minf(t / 0.75, 1.0), 3.0))
		var a := clampf(1.0 - (t - 0.55) / 0.35, 0.0, 1.0) if it["genre"] != "etat" else clampf(1.0 - (t - 0.75) / 0.35, 0.0, 1.0)
		var tp := int(taille * pop)
		var largeur := _police.get_string_size(it["texte"], HORIZONTAL_ALIGNMENT_LEFT, -1, tp).x
		var pos := p + Vector2(it["dx"] - largeur / 2.0, it["dy"] - montee)
		var c: Color = it["couleur"]
		c.a *= a
		draw_string_outline(_police, pos, it["texte"], HORIZONTAL_ALIGNMENT_LEFT, -1, tp, maxi(4, tp / 5), Color(0.05, 0.03, 0.02, 0.92 * a))
		draw_string(_police, pos, it["texte"], HORIZONTAL_ALIGNMENT_LEFT, -1, tp, c)
