extends CanvasLayer
## HUD de la tranche verticale (proposition de direction artistique).
## Cadres Kenney UI Pack Adventure / RPG Expansion (CC0), icônes de compétence en textures Kenney Particle Pack (CC0).

const UI := "res://assets/ui/"
const VFX := "res://assets/vfx/"

const OR := Color("#F4C35A")
const ENCRE := Color("#2A1D0C")
const ENCRE2 := Color("#6B4C22")
const GIVRE := Color("#7FE3FF")

var racine: Control

func _ready() -> void:
	racine = Control.new()
	racine.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(racine)
	_haut_gauche()
	_haut_centre()
	_haut_droite()
	_competences()

# ---------- briques ----------

func tex(chemin: String) -> Texture2D:
	return load(chemin)

func neuf(chemin: String, marge: int, taille: Vector2, pos: Vector2, parent: Control = null) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = tex(chemin)
	n.patch_margin_left = marge
	n.patch_margin_right = marge
	n.patch_margin_top = marge
	n.patch_margin_bottom = marge
	n.size = taille
	n.position = pos
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else racine).add_child(n)
	return n

func image(chemin: String, taille: Vector2, pos: Vector2, parent: Control = null, teinte := Color.WHITE) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex(chemin)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.size = taille
	t.position = pos
	t.modulate = teinte
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else racine).add_child(t)
	return t

func texte(t: String, taille_police: int, couleur: Color, pos: Vector2, parent: Control = null, contour := true, largeur := 0.0, alignement := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.add_theme_font_size_override("font_size", taille_police)
	l.add_theme_color_override("font_color", couleur)
	if contour:
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		l.add_theme_constant_override("outline_size", 5)
	if largeur > 0.0:
		l.size.x = largeur
		l.horizontal_alignment = alignement
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else racine).add_child(l)
	return l

func barre(pos: Vector2, taille: Vector2, remplissage: float, fond_teinte: Color, chemin_plein: String, libelle: String) -> void:
	var fond := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = fond_teinte
	sb.set_corner_radius_all(int(taille.y / 2))
	sb.border_color = Color(0, 0, 0, 0.6)
	sb.set_border_width_all(2)
	fond.add_theme_stylebox_override("panel", sb)
	fond.position = pos
	fond.size = taille
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.add_child(fond)
	var plein := neuf(chemin_plein, 15, Vector2(maxf(taille.y, taille.x * remplissage), taille.y), pos)
	plein.patch_margin_top = 14
	plein.patch_margin_bottom = 14
	if libelle != "":
		texte(libelle, int(taille.y * 0.62), Color.WHITE, pos + Vector2(0, -2), null, true, taille.x, HORIZONTAL_ALIGNMENT_CENTER)

# ---------- zones ----------

func _haut_gauche() -> void:
	var cadre := image(UI + "aventure/round_brown.png", Vector2(78, 78), Vector2(14, 10))
	image("res://assets/icones/001_axe_2handed.png", Vector2(50, 50), Vector2(28, 24))
	barre(Vector2(100, 18), Vector2(270, 24), 0.82, Color(0.12, 0.05, 0.05, 0.85), UI + "aventure/progress_red_border.png", "1 968 / 2 400")
	barre(Vector2(100, 48), Vector2(210, 16), 0.64, Color(0.04, 0.07, 0.14, 0.85), UI + "aventure/progress_blue_border.png", "")
	texte("Thomas · niv. 12", 15, OR, Vector2(102, 68))

func _haut_centre() -> void:
	var largeur := 380.0
	var x := (1280.0 - largeur) / 2.0
	var plaque := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.043, 0.051, 0.078, 0.72)
	sb.border_color = Color(OR.r, OR.g, OR.b, 0.55)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	plaque.add_theme_stylebox_override("panel", sb)
	plaque.position = Vector2(x + 40, 8)
	plaque.size = Vector2(largeur - 80, 60)
	racine.add_child(plaque)
	texte("Étage 1 · Crypte des nains", 19, OR, Vector2(x, 12), null, true, largeur, HORIZONTAL_ALIGNMENT_CENTER)
	texte("Seigneur draugr dans 14:52", 13, Color("#FFE2A0"), Vector2(x, 40), null, true, largeur, HORIZONTAL_ALIGNMENT_CENTER)

func _haut_droite() -> void:
	var t := 150.0
	var pos := Vector2(1280 - t - 14, 8)
	var disque := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.09, 0.82)
	sb.set_corner_radius_all(int(t / 2))
	disque.add_theme_stylebox_override("panel", sb)
	disque.position = pos + Vector2(14, 14)
	disque.size = Vector2(t - 28, t - 28)
	racine.add_child(disque)
	# salles déjà vues (aperçu stylisé)
	for r in [Rect2(46, 52, 34, 30), Rect2(80, 62, 24, 8), Rect2(104, 50, 26, 34), Rect2(58, 82, 8, 22), Rect2(48, 104, 30, 18)]:
		var c := ColorRect.new()
		c.color = Color("#5A4C3A")
		c.position = pos + r.position
		c.size = r.size
		racine.add_child(c)
	var moi := ColorRect.new()
	moi.color = Color.WHITE
	moi.size = Vector2(6, 6)
	moi.position = pos + Vector2(60, 64)
	racine.add_child(moi)
	image(UI + "aventure/minimap_ring_brown_detail.png", Vector2(t, t), pos)
	# l'or ne s'affiche jamais en jeu : seulement dans le sac et au coffre

func disque(pos: Vector2, d: float, couleur: Color, parent: Control = null) -> void:
	var pn := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = couleur
	sb.set_corner_radius_all(int(d / 2))
	pn.add_theme_stylebox_override("panel", sb)
	pn.position = pos
	pn.size = Vector2(d, d)
	pn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else racine).add_child(pn)

func icone_sort(pos: Vector2, d: float, icone: String, teinte: Color, parent: Control = null) -> void:
	# cadre bois + fond sombre : l'icône lumineuse ressort toujours
	image(UI + "aventure/round_brown_dark.png", Vector2(d, d), pos, parent)
	disque(pos + Vector2(d, d) * 0.12, d * 0.76, Color(0.09, 0.07, 0.06, 0.95), parent)
	image(VFX + icone, Vector2(d * 0.6, d * 0.6), pos + Vector2(d, d) * 0.2, parent, teinte)

func _bouton_competence(centre: Vector2, diametre: float, icone: String, teinte: Color, libelle: String, cd: int, pret: bool) -> void:
	var p := centre - Vector2(diametre, diametre) / 2.0
	icone_sort(p, diametre, icone, teinte)
	if false: image(VFX + icone, Vector2(diametre * 0.62, diametre * 0.62), p + Vector2(diametre * 0.19, diametre * 0.19), null, teinte)
	if cd > 0:
		var voile := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.55)
		sb.set_corner_radius_all(int(diametre / 2))
		voile.add_theme_stylebox_override("panel", sb)
		voile.position = p + Vector2(8, 8)
		voile.size = Vector2(diametre - 16, diametre - 16)
		racine.add_child(voile)
		texte(str(cd), int(diametre * 0.36), Color.WHITE, p + Vector2(0, diametre * 0.26), null, true, diametre, HORIZONTAL_ALIGNMENT_CENTER)
	elif pret:
		var anneau := Panel.new()
		var sb2 := StyleBoxFlat.new()
		sb2.bg_color = Color(0, 0, 0, 0)
		sb2.border_color = GIVRE
		sb2.set_border_width_all(3)
		sb2.set_corner_radius_all(int(diametre / 2))
		anneau.add_theme_stylebox_override("panel", sb2)
		anneau.position = p + Vector2(3, 3)
		anneau.size = Vector2(diametre - 6, diametre - 6)
		racine.add_child(anneau)
	if libelle != "":
		texte(libelle, 11, Color("#FFF4DC"), p + Vector2(0, diametre - 2), null, true, diametre, HORIZONTAL_ALIGNMENT_CENTER)

func _competences() -> void:
	# roue serrée dans le coin bas droit, sous le pouce : l'ultime dans l'angle, le reste en arc bas
	var o := Vector2(1280 - 82, 576 - 80)   # centre du bouton ultime
	_bouton_competence(o, 100, "twirl_02.png", OR, "", 0, true)
	_bouton_competence(o + Vector2(-108, 24), 70, "slash_02.png", Color("#FFD9A0"), "", 0, true)
	_bouton_competence(o + Vector2(-96, -62), 70, "trace_03.png", Color("#FFC27A"), "", 6, false)
	_bouton_competence(o + Vector2(-12, -104), 62, "circle_03.png", Color("#FFE7A8"), "", 0, true)
	_bouton_competence(o + Vector2(-188, 30), 62, "smoke_05.png", Color("#9DFFC8"), "", 0, true)
	_bouton_competence(o + Vector2(-262, 36), 52, "magic_02.png", Color("#FF8A8A"), "", 0, false)
	texte("×3", 13, Color.WHITE, o + Vector2(-262, 36) + Vector2(4, 8), null, true)
