extends Control
## Minicarte ronde (nord en haut) : formes de la carte, lieux, cible de quête, flèche du joueur.
## Toucher la minicarte = se faire guider vers le lieu sûr le plus proche.

signal touchee

var formes: Array = []          ## [{type: ligne|rect|cercle, ...}]
var lieux: Array = []           ## [{c: Vector2, genre: sur|portail|sanctuaire|danger, nom}]
var cible := Vector2.INF
var heros: Node3D
var echelle := 0.95             ## pixels par mètre
var rayon_px := 58.0

var _dessin: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# le disque sert de masque : tout ce qui est dessiné dedans est découpé en rond
	clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_dessin = Control.new()
	_dessin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dessin.draw.connect(_dessiner)
	add_child(_dessin)

func _draw() -> void:
	draw_circle(size / 2.0, rayon_px, Color(0.07, 0.1, 0.08, 0.95))

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if event.position.distance_to(global_position + size / 2.0) < rayon_px + 10.0:
			touchee.emit()
			get_viewport().set_input_as_handled()

func _process(_d: float) -> void:
	_dessin.size = size
	_dessin.queue_redraw()

func _vers_ecran(p: Vector2, centre: Vector2) -> Vector2:
	return size / 2.0 + (p - centre) * echelle

func _dessiner() -> void:
	if heros == null:
		return
	var c := Vector2(heros.global_position.x, heros.global_position.z)
	var o := size / 2.0
	for f in formes:
		match f["type"]:
			"rect":
				var r: Rect2 = f["r"]
				var a := _vers_ecran(r.position, c)
				_poly_coupe([a, a + Vector2(r.size.x, 0) * echelle, a + r.size * echelle, a + Vector2(0, r.size.y) * echelle], f["couleur"], o)
			"poly":
				var pp := PackedVector2Array()
				for q in f["pts"]:
					pp.append(_vers_ecran(q, c))
				_dessin.draw_colored_polygon(pp, f["couleur"])
			"cercle":
				var ce := _vers_ecran(f["c"], c)
				if ce.distance_to(o) < rayon_px + f["r"] * echelle:
					_cercle_coupe(ce, f["r"] * echelle, f["couleur"], o)
			"ligne":
				var pts: Array = f["pts"]
				for i in pts.size() - 1:
					var a2 := _vers_ecran(pts[i], c)
					var b2 := _vers_ecran(pts[i + 1], c)
					_segment_coupe(a2, b2, f["couleur"], f["largeur"], o)
	for l in lieux:
		var p := _vers_ecran(l["c"], c)
		var d := p - o
		var dedans := d.length() < rayon_px - 8.0
		if not dedans:
			if l["genre"] not in ["sur", "portail", "elite", "retour"]:
				continue
			p = o + d.normalized() * (rayon_px - 8.0)   # les lieux importants restent épinglés au bord
		_icone(p, l["genre"], 1.0 if dedans else 0.75)
	if cible != Vector2.INF:
		var pc := _vers_ecran(cible, c)
		var dc := pc - o
		if dc.length() > rayon_px - 10.0:
			pc = o + dc.normalized() * (rayon_px - 10.0)
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
		_dessin.draw_arc(pc, 7.0 + pulse * 3.0, 0, TAU, 24, Color(1.0, 0.85, 0.4, 0.9 - pulse * 0.5), 2.0, true)
	# autres aventuriers (bleu ; rouge s'ils nous sont hostiles) — seulement à portée de vue
	for b in get_tree().get_nodes_in_group("joueur"):
		if b == heros or b.est_mort or not b.is_physics_processing():
			continue
		var pb := _vers_ecran(Vector2(b.global_position.x, b.global_position.z), c)
		if pb.distance_to(o) < rayon_px - 4.0:
			var hostile: bool = heros.get("hostiles") != null and heros.hostiles.has(b)
			_dessin.draw_circle(pb, 3.4, Color(0, 0, 0, 0.7))
			_dessin.draw_circle(pb, 2.5, Color("#FF4A3D") if hostile else Color("#6FB8FF"))
	# flèche du héros : orientée selon son regard
	var ang: float = heros.rotation.y
	var av := Vector2(sin(ang), cos(ang))
	var dr := Vector2(av.y, -av.x)
	var tri := PackedVector2Array([o + av * 7.0, o - av * 4.5 + dr * 4.5, o - av * 2.0, o - av * 4.5 - dr * 4.5])
	_dessin.draw_colored_polygon(tri, Color.WHITE)
	_dessin.draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[3], tri[0]]), Color(0, 0, 0, 0.7), 1.2, true)

func _dans(p: Vector2, o: Vector2) -> bool:
	return p.distance_to(o) <= rayon_px

func _poly_coupe(pts: Array, coul: Color, _o: Vector2) -> void:
	_dessin.draw_colored_polygon(PackedVector2Array(pts), coul)

func _cercle_coupe(ce: Vector2, r: float, coul: Color, _o: Vector2) -> void:
	_dessin.draw_circle(ce, r, coul)

func _segment_coupe(a: Vector2, b: Vector2, coul: Color, l: float, _o: Vector2) -> void:
	_dessin.draw_line(a, b, coul, l, true)

func _icone(p: Vector2, genre: String, alpha: float) -> void:
	match genre:
		"sur":
			# bouclier doré : lieu sûr
			var pts := PackedVector2Array([p + Vector2(-6, -6), p + Vector2(6, -6), p + Vector2(6, 1), p + Vector2(0, 7), p + Vector2(-6, 1)])
			_dessin.draw_colored_polygon(pts, Color(0.95, 0.76, 0.35, alpha))
			_dessin.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[4], pts[0]]), Color(0.2, 0.12, 0.04, alpha), 1.5, true)
		"portail":
			_dessin.draw_circle(p, 6.0, Color(0.1, 0.2, 0.3, alpha))
			_dessin.draw_arc(p, 6.0, 0, TAU, 20, Color(0.5, 0.85, 1.0, alpha), 2.2, true)
			_dessin.draw_circle(p, 2.2, Color(1.0, 0.85, 0.5, alpha))
		"sanctuaire":
			var e := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + TAU * i / 10.0
				e.append(p + Vector2(cos(a), sin(a)) * (6.0 if i % 2 == 0 else 2.6))
			_dessin.draw_colored_polygon(e, Color(1.0, 0.85, 0.45, alpha))
		"danger":
			_dessin.draw_circle(p, 3.5, Color(0.85, 0.2, 0.15, alpha))
		"retour":
			# racine de retour : anneau doré et flèche vers le haut (extraction)
			_dessin.draw_circle(p, 6.5, Color(0.12, 0.08, 0.03, alpha))
			_dessin.draw_arc(p, 6.5, 0, TAU, 20, Color(1.0, 0.8, 0.4, alpha), 2.0, true)
			_dessin.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -4.5), p + Vector2(3.5, 0.5), p + Vector2(-3.5, 0.5)]), Color(1.0, 0.85, 0.5, alpha))
			_dessin.draw_line(p + Vector2(0, 0), p + Vector2(0, 4), Color(1.0, 0.85, 0.5, alpha), 2.0)
		"elite":
			# couronne orange : un élite et son coffre
			var cr := PackedVector2Array([p + Vector2(-7, 4), p + Vector2(-7, -3), p + Vector2(-3.5, 0), p + Vector2(0, -6), p + Vector2(3.5, 0), p + Vector2(7, -3), p + Vector2(7, 4)])
			_dessin.draw_colored_polygon(cr, Color(1.0, 0.6, 0.18, alpha))
