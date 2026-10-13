extends "res://scripts/interface/hud.gd"
## HUD de combat vivant : vie et énergie liées au héros, roue de compétences tactile, barre d'incantation,
## barres de vie des draugr, vignette rouge quand la vie baisse, fiche de compétence sur appui long.

const BOUTON := preload("res://scripts/interface/bouton_competence.gd")

## Disposition de la roue autour de l'ultime (coin bas droit, sous le pouce droit).
const IC := "res://assets/icones_sorts/"
const ROUE := [
	["e", IC + "ruee.svg", Vector2(0, 0), 100.0],
	["q", IC + "fendoir.svg", Vector2(-108, 24), 70.0],
	["w", IC + "bond.svg", Vector2(-96, -62), 70.0],
	["r", IC + "bulle.svg", Vector2(-12, -104), 62.0],
	["f", IC + "vent.svg", Vector2(-188, 30), 62.0],
	["d", IC + "esquive.svg", Vector2(-178, -58), 54.0],
	["p", IC + "potion.svg", Vector2(-262, 36), 52.0],
]

const FICHES := {
	"q": "Cône devant toi. Frappe tout ce qui s'y trouve et repousse un peu.",
	"w": "Saut jusqu'à 7 m. À l'atterrissage, dégâts en cercle et ralentissement 1,5 s.",
	"e": "Incantation 0,7 s (interruptible), puis ruée de 12 m qui étourdit 1,4 s.",
	"r": "Bulle qui absorbe les coups pendant 6 s. Elle se fissure, puis éclate.",
	"f": "Vitesse +60 % pendant 3 s et retire les ralentissements.",
	"p": "Rend 30 % de la vie en 4 s.",
	"d": "Roulade de 4 m. Invulnérable pendant 0,3 s.",
}

var heros: Heros
var _vie_plein: NinePatchRect
var _vie_texte: Label
var _vie_trainee: ColorRect
var _energie_plein: NinePatchRect
var _incant: Control
var _incant_plein: ColorRect
var _incant_nom: Label
var _barres: Control
var _vignette: ColorRect
var _fiche: Control
var _fiche_t := 0.0
var _trainee := 1.0
var _mort_ecran: Control

const LARG_VIE := 270.0
const LARG_ENERGIE := 210.0

var _titre: Label
var _sous_titre: Label
var minicarte: Control

func brancher(h: Heros) -> void:
	heros = h
	if minicarte:
		minicarte.heros = h
	heros.pv_change.connect(_sur_pv)
	heros.energie_change.connect(_sur_energie)
	heros.mort.connect(_sur_mort)
	_sur_pv(heros.pv, heros.pv_max)

func _ready() -> void:
	racine = Control.new()
	racine.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(racine)
	_vignette_basse()
	_barres = Control.new()
	_barres.set_anchors_preset(Control.PRESET_FULL_RECT)
	_barres.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barres.draw.connect(_dessiner_barres_ennemis)
	racine.add_child(_barres)
	var nombres := Control.new()
	nombres.set_script(load("res://scripts/interface/nombres.gd"))
	racine.add_child(nombres)
	_haut_gauche()
	_haut_centre()
	_haut_droite()
	_barre_incantation()

## La roue a besoin du héros : construite une fois branché.
func construire_roue() -> void:
	var o := Vector2(1280 - 82, 576 - 80)
	for b in ROUE:
		var bt: Control = BOUTON.new()
		racine.add_child(bt)
		bt.preparer(heros, b[0], b[1], Color.WHITE, b[3])
		bt.position = o + b[2] - Vector2(b[3], b[3]) / 2.0
		bt.appui_long.connect(_montrer_fiche)

# ---------- titre et minicarte ----------

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
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.add_child(plaque)
	_titre = texte("Étage 1 · Crypte des nains", 19, OR, Vector2(x, 12), null, true, largeur, HORIZONTAL_ALIGNMENT_CENTER)
	_sous_titre = texte("Seigneur draugr dans 14:52", 13, Color("#FFE2A0"), Vector2(x, 40), null, true, largeur, HORIZONTAL_ALIGNMENT_CENTER)

func regler_titre(t: String, st: String, couleur_st := Color("#FFE2A0")) -> void:
	_titre.text = t
	_sous_titre.text = st
	_sous_titre.add_theme_color_override("font_color", couleur_st)

func _haut_droite() -> void:
	var t := 150.0
	var pos := Vector2(1280 - t - 14, 8)
	minicarte = Control.new()
	minicarte.set_script(load("res://scripts/interface/minicarte.gd"))
	minicarte.position = pos
	minicarte.size = Vector2(t, t)
	racine.add_child(minicarte)
	image(UI + "aventure/minimap_ring_brown_detail.png", Vector2(t, t), pos)
	# l'or ne s'affiche jamais en jeu : seulement dans le sac et au coffre

# ---------- vie / énergie ----------

func _haut_gauche() -> void:
	image(UI + "aventure/round_brown.png", Vector2(78, 78), Vector2(14, 10))
	image("res://assets/icones/001_axe_2handed.png", Vector2(50, 50), Vector2(28, 24))
	var p := Vector2(100, 18)
	_fond_barre(p, Vector2(LARG_VIE, 24), Color(0.12, 0.05, 0.05, 0.85))
	# traînée claire : la vie perdue reste visible un instant, on lit la taille du coup
	_vie_trainee = ColorRect.new()
	_vie_trainee.color = Color(1.0, 0.86, 0.7, 0.75)
	_vie_trainee.position = p + Vector2(3, 4)
	_vie_trainee.size = Vector2(LARG_VIE - 6, 16)
	_vie_trainee.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.add_child(_vie_trainee)
	_vie_plein = neuf(UI + "aventure/progress_red_border.png", 14, Vector2(LARG_VIE, 24), p)
	_vie_texte = texte("", 15, Color.WHITE, p + Vector2(0, 1), null, true, LARG_VIE, HORIZONTAL_ALIGNMENT_CENTER)
	var pe := Vector2(100, 48)
	_fond_barre(pe, Vector2(LARG_ENERGIE, 16), Color(0.04, 0.07, 0.14, 0.85))
	_energie_plein = neuf(UI + "aventure/progress_blue_border.png", 8, Vector2(LARG_ENERGIE, 16), pe)
	texte("Thomas · niv. 12", 15, OR, Vector2(102, 68))

func _fond_barre(pos: Vector2, taille: Vector2, c: Color) -> void:
	var fond := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(int(taille.y / 2))
	sb.border_color = Color(0, 0, 0, 0.6)
	sb.set_border_width_all(2)
	fond.add_theme_stylebox_override("panel", sb)
	fond.position = pos
	fond.size = taille
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.add_child(fond)

func _sur_pv(pv: float, pv_max: float) -> void:
	var k := clampf(pv / pv_max, 0.0, 1.0)
	_vie_plein.size.x = maxf(24.0, LARG_VIE * k)
	_vie_plein.visible = k > 0.0
	_vie_texte.text = _milliers(int(ceil(pv))) + " / " + _milliers(int(pv_max))

func _sur_energie(e: float, e_max: float) -> void:
	_energie_plein.size.x = maxf(16.0, LARG_ENERGIE * clampf(e / e_max, 0.0, 1.0))

func _milliers(n: int) -> String:
	var s := str(n)
	return s if s.length() <= 3 else s.substr(0, s.length() - 3) + " " + s.substr(s.length() - 3)

# ---------- incantation ----------

func _barre_incantation() -> void:
	_incant = Control.new()
	_incant.position = Vector2(640 - 120, 400)
	_incant.size = Vector2(240, 30)
	_incant.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.add_child(_incant)
	var f := ColorRect.new()
	f.color = Color(0.03, 0.05, 0.09, 0.8)
	f.size = Vector2(240, 10)
	f.position = Vector2(0, 18)
	_incant.add_child(f)
	_incant_plein = ColorRect.new()
	_incant_plein.color = GIVRE
	_incant_plein.size = Vector2(0, 6)
	_incant_plein.position = Vector2(2, 20)
	_incant.add_child(_incant_plein)
	_incant_nom = texte("", 14, Color("#DFF6FF"), Vector2.ZERO, _incant, true, 240, HORIZONTAL_ALIGNMENT_CENTER)
	_incant.visible = false

# ---------- barres des draugr ----------

func _dessiner_barres_ennemis() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var police := ThemeDB.fallback_font
	for e in get_tree().get_nodes_in_group("monstre"):
		if e.est_mort or not e.has_method("en_combat") or not e.en_combat():
			continue
		if e.fiche.get("elite", false) and e.est_eveille():
			# barre de chef, sous le titre : on sait à qui on a affaire
			var lb := 420.0
			var rb := Rect2(Vector2(640 - lb / 2.0, 84), Vector2(lb, 12))
			_barres.draw_rect(rb.grow(3.0), Color(0, 0, 0, 0.8))
			_barres.draw_rect(Rect2(rb.position, Vector2(lb * e.pv / e.pv_max, 12)), Color("#C2302A"))
			_barres.draw_rect(Rect2(rb.position, Vector2(lb * e.pv / e.pv_max, 3)), Color(1, 0.75, 0.6, 0.6))
			_barres.draw_string_outline(police, Vector2(640 - 200, 80), e.nom_affiche() + " — Élite", HORIZONTAL_ALIGNMENT_CENTER, 400, 15, 5, Color(0, 0, 0, 0.9))
			_barres.draw_string(police, Vector2(640 - 200, 80), e.nom_affiche() + " — Élite", HORIZONTAL_ALIGNMENT_CENTER, 400, 15, Color("#FFB08A"))
		var monde: Vector3 = e.global_position + Vector3(0, e.hauteur_barre, 0)
		if cam.is_position_behind(monde):
			continue
		var p := cam.unproject_position(monde)
		var elite: bool = e.fiche.get("armure", false)
		var l := 84.0 if elite else 62.0
		var h := 8.0 if elite else 6.0
		var r := Rect2(p - Vector2(l / 2.0, 0), Vector2(l, h))
		_barres.draw_rect(r.grow(2.0), Color(0, 0, 0, 0.75))
		_barres.draw_rect(Rect2(r.position, Vector2(l * e.pv / e.pv_max, h)), Color("#D8423A"))
		_barres.draw_rect(Rect2(r.position, Vector2(l * e.pv / e.pv_max, 2.0)), Color(1, 0.7, 0.6, 0.6))
		if elite:
			_barres.draw_string_outline(police, p + Vector2(-90, -6), e.nom_affiche(), HORIZONTAL_ALIGNMENT_CENTER, 180, 12, 4, Color(0, 0, 0, 0.85))
			_barres.draw_string(police, p + Vector2(-90, -6), e.nom_affiche(), HORIZONTAL_ALIGNMENT_CENTER, 180, 12, Color("#FFD9B0"))
		if e.etourdi_t > 0.0:
			_barres.draw_string_outline(police, p + Vector2(-60, h + 15), "étourdi", HORIZONTAL_ALIGNMENT_CENTER, 120, 11, 4, Color(0, 0, 0, 0.85))
			_barres.draw_string(police, p + Vector2(-60, h + 15), "étourdi", HORIZONTAL_ALIGNMENT_CENTER, 120, 11, Color("#CFE3FF"))

# ---------- vignette ----------

func _vignette_basse() -> void:
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform float force = 0.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	p.x *= 1.25;
	float d = smoothstep(0.75, 1.55, length(p));
	COLOR = vec4(0.55, 0.02, 0.02, d * force);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	_vignette.material = m
	racine.add_child(_vignette)

# ---------- fiche de compétence (appui long) ----------

func _montrer_fiche(id: String) -> void:
	if _fiche:
		_fiche.queue_free()
	var c: Dictionary = Heros.COMPETENCES[id]
	_fiche = neuf(UI + "rpg/panel_beigeLight.png", 18, Vector2(330, 132), Vector2(1280 - 330 - 300, 576 - 132 - 150))
	texte(c["nom"], 19, ENCRE, Vector2(18, 12), _fiche, false)
	var infos := "Recharge %s s" % _virgule(c["cd"])
	if c["cout"] > 0.0:
		infos += "  ·  %d énergie" % int(c["cout"])
	texte(infos, 13, ENCRE2, Vector2(18, 40), _fiche, false)
	var desc := texte(FICHES[id], 14, ENCRE, Vector2(18, 64), _fiche, false, 294)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fiche_t = 3.0

func _virgule(v: float) -> String:
	return str(v).replace(".", ",").trim_suffix(",0")

# ---------- mort ----------

func _sur_mort(_e) -> void:
	_mort_ecran = Control.new()
	_mort_ecran.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mort_ecran.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mort_ecran.modulate.a = 0.0
	racine.add_child(_mort_ecran)
	var voile := ColorRect.new()
	voile.color = Color(0.02, 0.02, 0.05, 0.55)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mort_ecran.add_child(voile)
	texte("Tu es tombé", 40, Color("#F2E6D0"), Vector2(0, 220), _mort_ecran, true, 1280, HORIZONTAL_ALIGNMENT_CENTER)
	texte("Freya t'a vu. Ton corps garde ton équipement : retrouve-le avant les autres.", 16, Color("#FFE2A0"), Vector2(0, 276), _mort_ecran, true, 1280, HORIZONTAL_ALIGNMENT_CENTER)
	create_tween().tween_property(_mort_ecran, "modulate:a", 1.0, 1.2).set_delay(0.8)

# ---------- boucle ----------

func _process(delta: float) -> void:
	if heros == null:
		return
	# traînée de vie
	var k := clampf(heros.pv / heros.pv_max, 0.0, 1.0)
	_trainee = k if k > _trainee else move_toward(_trainee, k, delta * 0.45)
	_vie_trainee.size.x = maxf(0.0, (LARG_VIE - 6) * _trainee)
	# vignette sous 35 % de vie, avec un battement
	var f := clampf((0.35 - k) / 0.35, 0.0, 1.0)
	(_vignette.material as ShaderMaterial).set_shader_parameter("force", f * (0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.008)))
	# incantation
	if heros.action == "incantation":
		_incant.visible = true
		_incant_nom.text = Heros.COMPETENCES["e"]["nom"]
		_incant_plein.size.x = 236.0 * clampf(heros._action_t / heros._action["duree"], 0.0, 1.0)
	else:
		_incant.visible = false
	if _fiche:
		_fiche_t -= delta
		if _fiche_t <= 0.0:
			_fiche.queue_free()
			_fiche = null
	_barres.queue_redraw()
