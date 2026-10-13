extends "res://scripts/interface/hud.gd"
## Choix de la voie draconique : trois cartes beige, force en vert, faiblesse en rouge.
## Le choix est définitif : un premier toucher sélectionne, un second confirme.

signal choisi(id: String)

var _cartes: Control
var _selection := ""

func _ready() -> void:
	layer = 9
	racine = Control.new()
	racine.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(racine)
	var voile := ColorRect.new()
	voile.color = Color(0.03, 0.02, 0.04, 0.9)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.add_child(voile)
	texte("Le sang du dragon coule en toi", 28, Color("#F6CF6A"), Vector2(0, 22), racine, true, 1280, HORIZONTAL_ALIGNMENT_CENTER)
	texte("Trois voies, une seule pour toujours. Aucune n'est la meilleure : chacune a son prix.", 15, Color("#EBDDBB"), Vector2(0, 62), racine, false, 1280, HORIZONTAL_ALIGNMENT_CENTER)
	_cartes = Control.new()
	racine.add_child(_cartes)
	Jeu.interface_bloquante = true
	_dessiner()

func _dessiner() -> void:
	for x in _cartes.get_children():
		x.queue_free()
	for i in Classes.DRACONIQUES.size():
		var id: String = Classes.DRACONIQUES[i]
		var c: Dictionary = Classes.LISTE[id]
		var x := 70.0 + i * 390.0
		var sel := id == _selection
		var carte := neuf(UI + "rpg/panel_beigeLight.png", 16, Vector2(360, 430), Vector2(x, 100 if not sel else 92), _cartes)
		if sel:
			var cadre := Panel.new()
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0, 0, 0, 0)
			sb.border_color = c["couleur"]
			sb.set_border_width_all(4)
			sb.set_corner_radius_all(12)
			cadre.add_theme_stylebox_override("panel", sb)
			cadre.position = Vector2(-6, -6)
			cadre.size = Vector2(372, 442)
			cadre.mouse_filter = Control.MOUSE_FILTER_IGNORE
			carte.add_child(cadre)
		disque(Vector2(130, 14), 100, Color(0.08, 0.06, 0.05), carte)
		image(c["embleme"], Vector2(76, 76), Vector2(142, 26), carte)
		texte(c["titre"], 21, c["couleur"].darkened(0.35), Vector2(0, 124), carte, false, 360, HORIZONTAL_ALIGNMENT_CENTER)
		texte("« " + c["devise"] + " »", 13, ENCRE2, Vector2(0, 154), carte, false, 360, HORIZONTAL_ALIGNMENT_CENTER)
		var y := 188.0
		for f in c["forces"]:
			var l := texte("+  " + f, 14, Color("#2E6A2C"), Vector2(22, y), carte, false, 320)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			y += 42.0
		for f in c["faiblesses"]:
			var l2 := texte("−  " + f, 14, Color("#A04030"), Vector2(22, y), carte, false, 320)
			l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			y += 30.0
		var b := neuf(UI + "rpg/buttonLong_brown.png", 12, Vector2(316, 48), Vector2(22, 366), carte)
		texte("Confirmer ce choix" if sel else "Choisir cette voie", 17, Color("#FFF4DC"), Vector2(0, 12), b, true, 316, HORIZONTAL_ALIGNMENT_CENTER)
		carte.mouse_filter = Control.MOUSE_FILTER_STOP
		carte.gui_input.connect(func(ev):
			if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
				_toucher(id))

func _toucher(id: String) -> void:
	if _selection != id:
		_selection = id
		Sons.jouer("tissu", Vector3.ZERO, -8.0, 1.2)
		_dessiner()
		return
	Profil.p().classe = id
	Profil.p().sauver(true)
	Sons.jouer("cloche", Vector3.ZERO, 2.0, 0.8)
	Jeu.interface_bloquante = false
	var c: Dictionary = Classes.LISTE[id]
	for x in _cartes.get_children():
		x.queue_free()
	texte("Tu es désormais " + c["titre"], 30, c["couleur"], Vector2(0, 250), racine, true, 1280, HORIZONTAL_ALIGNMENT_CENTER)
	texte("Freya t'attend au sanctuaire.", 16, Color("#EBDDBB"), Vector2(0, 300), racine, false, 1280, HORIZONTAL_ALIGNMENT_CENTER)
	choisi.emit(id)
