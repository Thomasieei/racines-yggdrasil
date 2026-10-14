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
const LARG_MANA := 96.0
var _mana_plein: ColorRect
var _mana_texte: Label
var _boutons_pouvoir := {}

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
	Jeu.hud = self
	Jeu.joueur = h
	sac_ui = CanvasLayer.new()
	sac_ui.set_script(load("res://scripts/interface/sac_ui.gd"))
	add_child(sac_ui)
	sac_ui.brancher(h)
	talents_ui = CanvasLayer.new()
	talents_ui.set_script(load("res://scripts/interface/talents_ui.gd"))
	add_child(talents_ui)
	talents_ui.brancher(h)
	codex_ui = CanvasLayer.new()
	codex_ui.set_script(load("res://scripts/interface/codex_ui.gd"))
	add_child(codex_ui)
	codex_ui.brancher(h)
	heros.ramasse.connect(_sur_ramasse)
	heros.mana_change.connect(_sur_mana)
	_sur_mana(heros.mana, heros.mana_max)
	if minicarte:
		minicarte.touchee.connect(func(): if Pouvoirs.moi: Pouvoirs.moi.ouvrir_carte())
	_construire_boutons_monde()

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
		bt.preparer(heros, b[0], heros.competence(b[0]).get("icone", b[1]), Color.WHITE, b[3])
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
	if _titre.text == t and _sous_titre.text == st and _sous_titre.get_theme_color("font_color") == couleur_st:
		return
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
	# mana : violet, juste à droite de l'énergie
	var pm := Vector2(316, 48)
	_fond_barre(pm, Vector2(LARG_MANA, 16), Color(0.1, 0.04, 0.14, 0.85))
	_mana_plein = ColorRect.new()
	_mana_plein.color = Color("#A45CFF")
	_mana_plein.position = pm + Vector2(3, 3)
	_mana_plein.size = Vector2(LARG_MANA - 6, 10)
	_mana_plein.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.add_child(_mana_plein)
	_mana_texte = texte("", 11, Color("#F3E6FF"), pm + Vector2(0, 0), null, true, LARG_MANA, HORIZONTAL_ALIGNMENT_CENTER)
	var cl: Dictionary = Classes.fiche(Profil.p().classe)
	texte("Thomas · " + cl["titre"], 15, cl["couleur"].lerp(OR, 0.3), Vector2(102, 68))

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

func _sur_mana(m: float, m_max: float) -> void:
	if _mana_plein:
		_mana_plein.size.x = maxf(0.0, (LARG_MANA - 6) * clampf(m / m_max, 0.0, 1.0))
		_mana_texte.text = "%d mana" % int(m)
	for id in _boutons_pouvoir:
		var b: Control = _boutons_pouvoir[id]
		b.modulate = Color.WHITE if m >= Pouvoirs.LISTE[id]["mana"] else Color(0.55, 0.55, 0.62)

## Les trois pouvoirs du monde, en colonne à droite (au-dessus de la roue des sorts).
func construire_pouvoirs() -> void:
	var y := 200.0
	for id in ["tp", "lames", "esprit", "dechainement"]:
		var b := _rond(Vector2(1244, y), 52, Pouvoirs.LISTE[id]["icone"])
		var lab := texte("%d" % int(Pouvoirs.LISTE[id]["mana"]), 11, Color("#E6D2FF"), Vector2(36, 40), b, true)
		b.gui_input.connect(func(ev):
			if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
				if Pouvoirs.moi and not Jeu.interface_bloquante:
					Pouvoirs.moi.lancer(id))
		_boutons_pouvoir[id] = b
		y += 58.0

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
	_dessiner_aventuriers(cam, police)
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
			var rang := " — Boss du donjon" if e.fiche.get("boss", false) else " — Élite"
			_barres.draw_string_outline(police, Vector2(640 - 200, 80), e.nom_affiche() + rang, HORIZONTAL_ALIGNMENT_CENTER, 400, 15, 5, Color(0, 0, 0, 0.9))
			_barres.draw_string(police, Vector2(640 - 200, 80), e.nom_affiche() + rang, HORIZONTAL_ALIGNMENT_CENTER, 400, 15, Color("#FFB08A"))
		if e.fiche.get("boss", false) and e.est_eveille():
			continue   # le roi a sa grande barre en haut de l'écran ; sa tête sort souvent du cadre
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

## Les autres aventuriers : pseudo, barre de vie, « AFK », en rouge s'ils nous sont hostiles.
func _dessiner_aventuriers(cam: Camera3D, police: Font) -> void:
	var moi = Jeu.joueur
	if moi == null or not is_instance_valid(moi):
		return
	for b in get_tree().get_nodes_in_group("joueur"):
		if b == moi or not b.is_physics_processing() or not b.get("ia"):
			continue
		var dist: float = b.global_position.distance_to(moi.global_position)
		if dist > 30.0:
			continue
		var monde: Vector3 = b.global_position + Vector3(0, 2.55, 0)
		if cam.is_position_behind(monde):
			continue
		var p := cam.unproject_position(monde)
		var hostile: bool = moi.hostiles.has(b)
		var alpha := clampf((30.0 - dist) / 6.0, 0.0, 1.0)
		var nom: String = b.nom_joueur
		var afk := false
		for c in get_tree().get_nodes_in_group("bot_cerveau"):
			if c.h == b:
				afk = c.afk
		if b.est_mort:
			nom += " (mort)"
		elif afk:
			nom += "  AFK"
		var coul := Color("#FF7A6A") if hostile else Color("#BFE0FF")
		coul.a = alpha
		# tranche de force : sa puissance comparée à la tienne
		var pb: int = b.puissance()
		var ratio := float(pb) / maxf(1.0, float(moi.puissance()))
		var cf := Color("#7FE07A") if ratio < 0.85 else (Color("#F4D35A") if ratio < 1.15 else (Color("#FF9A3D") if ratio < 1.4 else Color("#FF4A3D")))
		cf.a = alpha
		_barres.draw_string_outline(police, p + Vector2(-90, 22), "Puissance %d" % pb, HORIZONTAL_ALIGNMENT_CENTER, 180, 12, 4, Color(0, 0, 0, 0.85 * alpha))
		_barres.draw_string(police, p + Vector2(-90, 22), "Puissance %d" % pb, HORIZONTAL_ALIGNMENT_CENTER, 180, 12, cf)
		_barres.draw_string_outline(police, p + Vector2(-90, -8), nom, HORIZONTAL_ALIGNMENT_CENTER, 180, 13, 4, Color(0, 0, 0, 0.85 * alpha))
		_barres.draw_string(police, p + Vector2(-90, -8), nom, HORIZONTAL_ALIGNMENT_CENTER, 180, 13, coul)
		if b.est_mort:
			continue
		var l := 56.0
		var r := Rect2(p - Vector2(l / 2.0, 0), Vector2(l, 5))
		_barres.draw_rect(r.grow(1.5), Color(0, 0, 0, 0.7 * alpha))
		_barres.draw_rect(Rect2(r.position, Vector2(l * b.pv / b.pv_max, 5)), Color(0.85, 0.25, 0.2, alpha) if hostile else Color(0.35, 0.8, 0.45, alpha))

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
	var c: Dictionary = heros.competence(id)
	_fiche = neuf(UI + "rpg/panel_beigeLight.png", 18, Vector2(330, 132), Vector2(1280 - 330 - 300, 576 - 132 - 150))
	texte(c["nom"], 19, ENCRE, Vector2(18, 12), _fiche, false)
	var infos := "Recharge %s s" % _virgule(c["cd"])
	if c["cout"] > 0.0:
		infos += "  ·  %d énergie" % int(c["cout"])
	texte(infos, 13, ENCRE2, Vector2(18, 40), _fiche, false)
	var desc := texte(c.get("fiche", FICHES[id]), 14, ENCRE, Vector2(18, 64), _fiche, false, 294)
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

# ---------- sac, action contextuelle, notifications ----------

var sac_ui: CanvasLayer
var talents_ui: CanvasLayer
var codex_ui: CanvasLayer
var _badge: Control
var _badge_lab: Label
var _arbre_btn: Control
var _action_btn: Control
var _action_lab: Label
var _action_cible: Node = null
var _notes: Array = []

func _rond(centre: Vector2, d: float, icone: String) -> Control:
	var c := Control.new()
	c.position = centre - Vector2(d, d) / 2.0
	c.size = Vector2(d, d)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	racine.add_child(c)
	image(UI + "aventure/round_brown_dark.png", Vector2(d, d), Vector2.ZERO, c)
	disque(Vector2(d, d) * 0.12, d * 0.76, Color(0.09, 0.07, 0.06, 0.95), c)
	image(icone, Vector2(d, d) * 0.6, Vector2(d, d) * 0.2, c)
	return c

func _construire_boutons_monde() -> void:
	var sac_btn := _rond(Vector2(1046, 46), 60, "res://assets/icones_sorts/sac.svg")
	sac_btn.gui_input.connect(func(ev):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			sac_ui.basculer())
	_arbre_btn = _rond(Vector2(982, 46), 60, "res://assets/icones_sorts/arbre.svg")
	_arbre_btn.gui_input.connect(func(ev):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			talents_ui.basculer())
	var cx := _rond(Vector2(918, 46), 60, "res://assets/icones_sorts/codex.svg")
	cx.gui_input.connect(func(ev):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			codex_ui.basculer())
	# pastille dorée : points de talent à placer
	_badge = Control.new()
	_badge.position = Vector2(38, -4)
	_badge.size = Vector2(26, 26)
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arbre_btn.add_child(_badge)
	disque(Vector2.ZERO, 26, Color("#E0A93A"), _badge)
	_badge_lab = texte("", 13, Color("#2A1D0C"), Vector2(0, 3), _badge, false, 26, HORIZONTAL_ALIGNMENT_CENTER)
	Profil.p().change.connect(_maj_badge)
	_maj_badge()
	_action_btn = _rond(Vector2(1076, 300), 74, "res://assets/icones_sorts/main.svg")
	_action_lab = texte("", 14, Color("#FFF4DC"), Vector2(-30, 74), _action_btn, true, 134, HORIZONTAL_ALIGNMENT_CENTER)
	_action_btn.gui_input.connect(func(ev):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			_agir())
	_action_btn.visible = false

func _agir() -> void:
	if _action_cible and is_instance_valid(_action_cible) and heros.action == "":
		_action_cible.interagir(heros)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B or event.keycode == KEY_I:
			sac_ui.basculer()
		elif event.keycode == KEY_T:
			talents_ui.basculer()
		elif event.keycode == KEY_C:
			codex_ui.basculer()
		elif event.keycode == KEY_M and Pouvoirs.moi:
			Pouvoirs.moi.ouvrir_carte()
		elif event.keycode == KEY_7 and Pouvoirs.moi:
			Pouvoirs.moi.lancer("lames")
		elif event.keycode == KEY_9 and Pouvoirs.moi:
			Pouvoirs.moi.lancer("esprit")
		elif event.keycode == KEY_8 and Pouvoirs.moi:
			Pouvoirs.moi.lancer("dechainement")
		elif event.keycode == KEY_E:
			_agir()

## Objet du monde le plus proche avec lequel on peut agir (coffre, filon, dépouille).
func _chercher_action() -> void:
	var meilleur: Node = null
	var d := 99.0
	for o in get_tree().get_nodes_in_group("interactif"):
		if not o.disponible():
			continue
		var acteur: Node3D = Pouvoirs.moi.controle if Pouvoirs.moi and Pouvoirs.moi.controle else heros
		var l: float = Vector2(o.global_position.x - acteur.global_position.x, o.global_position.z - acteur.global_position.z).length()
		var portee: float = o.get("rayon_action") if o.get("rayon_action") != null else o.rayon
		if l < portee and l < d:
			d = l
			meilleur = o
	_action_cible = meilleur
	_action_btn.visible = meilleur != null and not heros.est_mort and not Jeu.interface_bloquante
	if meilleur:
		var c := heros.canal_en_cours()
		_action_lab.text = meilleur.texte_action() if c == "" else "…"

func notifier(t: String, couleur := Color.WHITE, icone := "") -> void:
	var n := Control.new()
	n.position = Vector2(1280 - 330, 188)
	n.size = Vector2(316, 30)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.add_child(n)
	var fond := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.08, 0.7)
	sb.border_color = Color(couleur.r, couleur.g, couleur.b, 0.8)
	sb.border_width_right = 3
	sb.set_corner_radius_all(5)
	fond.add_theme_stylebox_override("panel", sb)
	fond.size = Vector2(316, 30)
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.add_child(fond)
	var x := 8.0
	if icone != "":
		image(icone, Vector2(26, 26), Vector2(4, 2), n)
		x = 34.0
	# message long : coupé en deux lignes au mot le plus proche du milieu
	var largeur := 316.0 - x - 12.0
	var tt := t
	if ThemeDB.fallback_font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x > largeur:
		var mi := t.length() / 2
		var coupe := -1
		for k in range(0, mi):
			if mi + k < t.length() and t[mi + k] == " ":
				coupe = mi + k
				break
			if mi - k > 0 and t[mi - k] == " ":
				coupe = mi - k
				break
		if coupe > 0:
			tt = t.substr(0, coupe) + "\n" + t.substr(coupe + 1)
			fond.size.y = 50
			n.size.y = 50
	texte(tt, 14, couleur, Vector2(x, 5), n, true, 316 - x - 8, HORIZONTAL_ALIGNMENT_RIGHT)
	_notes.push_front({"n": n, "t": 0.0})
	if _notes.size() > 6:
		var vieux = _notes.pop_back()
		vieux["n"].queue_free()

func _maj_notes(delta: float) -> void:
	var y := 188.0
	for e in _notes.duplicate():
		e["t"] += delta
		var n: Control = e["n"]
		n.position.y = lerpf(n.position.y, y, 1.0 - exp(-12.0 * delta))
		n.modulate.a = clampf(1.0 - (e["t"] - 3.2) / 0.6, 0.0, 1.0)
		if e["t"] > 3.8:
			n.queue_free()
			_notes.erase(e)
		y += n.size.y + 4.0

# ---------- minuteur (fermeture du donjon) ----------

var _minuteur: Label

func regler_minuteur(t: String, couleur: Color) -> void:
	if _minuteur == null:
		_minuteur = texte("", 14, couleur, Vector2(1116, 160), null, true, 150, HORIZONTAL_ALIGNMENT_CENTER)
	_minuteur.text = t
	_minuteur.add_theme_color_override("font_color", couleur)

# ---------- compteur de la Horde ----------

var _combo: Control
var _combo_lab: Label
var _combo_sous: Label
var _combo_t := 0.0
var _combo_n := 0

func combo_horde(morts: int, total: int) -> void:
	if _combo == null:
		_combo = Control.new()
		_combo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		racine.add_child(_combo)
		_combo_lab = texte("", 40, Color("#FFD34E"), Vector2(0, 92), _combo, true, 1280, HORIZONTAL_ALIGNMENT_CENTER)
		_combo_sous = texte("", 14, Color("#FFE2C0"), Vector2(0, 142), _combo, true, 1280, HORIZONTAL_ALIGNMENT_CENTER)
	if _combo_t <= 0.0:
		_combo_n = 0
	_combo_n += morts
	_combo_t = 2.5
	_combo.modulate.a = 1.0
	_combo_lab.text = "× %d" % _combo_n
	_combo_sous.text = "pulvérisés  ·  %s depuis ton arrivée" % _milliers(total)
	_combo_lab.pivot_offset = Vector2(640, 24)
	_combo_lab.scale = Vector2.ONE * (1.0 + minf(morts, 30) * 0.02)
	create_tween().tween_property(_combo_lab, "scale", Vector2.ONE, 0.2)

func _maj_combo(delta: float) -> void:
	if _combo == null or _combo_t <= 0.0:
		return
	_combo_t -= delta
	_combo.modulate.a = clampf(_combo_t / 0.6, 0.0, 1.0)

# ---------- canal du donjon ----------

var _canal: VBoxContainer
var _canal_lignes: Array = []

func chat(nom: String, t: String) -> void:
	if _canal == null:
		_canal = VBoxContainer.new()
		_canal.position = Vector2(16, 162)
		_canal.size = Vector2(380, 120)
		_canal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_canal.add_theme_constant_override("separation", 1)
		racine.add_child(_canal)
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.custom_minimum_size = Vector2(380, 18)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("normal_font_size", 13)
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	if nom == "":
		l.text = "[color=#9AA3B8][i]%s[/i][/color]" % t
	else:
		var c := Color.from_hsv(float(hash(nom) % 360) / 360.0, 0.45, 1.0)
		l.text = "[color=#%s]%s[/color] [color=#E8E4DA]%s[/color]" % [c.to_html(false), nom, t]
	_canal.add_child(l)
	_canal_lignes.append({"l": l, "t": 0.0})
	if _canal_lignes.size() > 5:
		_canal_lignes.pop_front()["l"].queue_free()

func _maj_canal(delta: float) -> void:
	for e in _canal_lignes.duplicate():
		e["t"] += delta
		e["l"].modulate.a = clampf((14.0 - e["t"]) / 2.0, 0.0, 1.0)
		if e["t"] > 14.0:
			e["l"].queue_free()
			_canal_lignes.erase(e)

func _maj_badge() -> void:
	if _badge == null:
		return
	var n := Profil.p().points_libres()
	_badge.visible = n > 0
	_badge_lab.text = str(n)

## Réalisation du Codex : bandeau doux en haut, points gagnés, la pastille de l'arbre s'allume.
func annoncer_realisation(r: Dictionary) -> void:
	var n := Control.new()
	n.position = Vector2(640 - 200, 96)
	n.size = Vector2(400, 64)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.modulate.a = 0.0
	racine.add_child(n)
	var f := neuf(UI + "rpg/panel_beigeLight.png", 14, Vector2(400, 64), Vector2.ZERO, n)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image("res://assets/icones_sorts/point.svg", Vector2(40, 40), Vector2(14, 12), n)
	texte("Réalisation · " + r["nom"], 16, ENCRE, Vector2(64, 10), n, false, 320)
	texte("+%d point%s de talent — Arbre des Racines" % [r["pts"], "s" if r["pts"] > 1 else ""], 13, Color("#7A4F0C"), Vector2(64, 34), n, false, 320)
	Sons.jouer("cloche", heros.global_position if heros else Vector3.ZERO, -4.0, 1.6)
	var tw := n.create_tween()
	tw.tween_property(n, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(n, "position:y", 106.0, 0.25).from(86.0)
	tw.tween_interval(3.2)
	tw.tween_property(n, "modulate:a", 0.0, 0.5)
	tw.tween_callback(n.queue_free)
	if not Profil.p().vu("tuto_points"):
		Profil.p().marquer_vu("tuto_points")
		notifier("Touche l'arbre doré en haut pour placer tes points.", Color("#FFD36B"), "res://assets/icones_sorts/arbre.svg")

## Une relique ! Le moment doit se sentir : rayons dorés, grande icône, nom dans la couleur.
func celebrer_relique(o: Dictionary) -> void:
	celebrer(o, "RELIQUE !", o["nom"] + " · " + Objets.NOMS_RARETE[o["rarete"]], Objets.texte_relique(o) + " — à porter depuis le sac")

var _file_celebrations: Array = []
var _celebration_en_cours := false

## Grand moment : rayons, grande icône, trois lignes. Les célébrations se suivent, jamais l'une sur l'autre.
func celebrer(o: Dictionary, titre: String, ligne1: String, ligne2: String) -> void:
	_file_celebrations.append([o, titre, ligne1, ligne2])
	if _celebration_en_cours:
		return
	_celebration_en_cours = true
	while not _file_celebrations.is_empty():
		var e: Array = _file_celebrations.pop_front()
		_celebrer(e[0], e[1], e[2], e[3])
		await get_tree().create_timer(3.5).timeout
	_celebration_en_cours = false

func _celebrer(o: Dictionary, titre: String, ligne1: String, ligne2: String) -> void:
	var c := Objets.couleur(o)
	var n := Control.new()
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.add_child(n)
	var centre := Vector2(640, 250)
	var k := {"t": 0.0}
	n.draw.connect(func():
		var a: float = clampf(k["t"] * 4.0, 0.0, 1.0) * clampf((3.4 - k["t"]) / 0.6, 0.0, 1.0)
		for i in 14:
			var ang: float = i * TAU / 14.0 + k["t"] * 0.35
			var p1: Vector2 = centre + Vector2(cos(ang), sin(ang)) * 40.0
			var p2: Vector2 = centre + Vector2(cos(ang), sin(ang)) * (150.0 + 20.0 * sin(k["t"] * 3.0 + i))
			n.draw_line(p1, p2, Color(c.r, c.g, c.b, 0.22 * a), 10.0, true)
		for i in 6:
			n.draw_circle(centre, 90.0 - i * 12.0, Color(c.r, c.g, c.b, 0.05 * a)))
	var ic := image(o["icone"], Vector2(120, 120), centre - Vector2(60, 60), n)
	ic.pivot_offset = Vector2(60, 60)
	var t1 := texte(titre, 30, c.lightened(0.25), Vector2(0, 330), n, true, 1280, HORIZONTAL_ALIGNMENT_CENTER)
	var t2 := texte(ligne1, 20, c.lightened(0.15), Vector2(0, 370), n, true, 1280, HORIZONTAL_ALIGNMENT_CENTER)
	var t3 := texte(ligne2, 15, Color("#FFF4DC"), Vector2(0, 400), n, true, 1280, HORIZONTAL_ALIGNMENT_CENTER)
	Sons.jouer("cloche", heros.global_position if heros else Vector3.ZERO, 0.0, 1.25)
	Sons.jouer("pret", heros.global_position if heros else Vector3.ZERO, -2.0, 0.8)
	var tw := n.create_tween()
	tw.tween_method(func(v): k["t"] = v; n.queue_redraw(); ic.scale = Vector2.ONE * (0.6 + 0.4 * minf(v * 3.0, 1.0) + 0.04 * sin(v * 6.0)); ic.modulate.a = clampf((3.4 - v) / 0.6, 0.0, 1.0); t1.modulate.a = ic.modulate.a; t2.modulate.a = ic.modulate.a; t3.modulate.a = ic.modulate.a, 0.0, 3.4, 3.4)
	tw.tween_callback(n.queue_free)

func _sur_ramasse(or_: int, objets: Array, origine: String) -> void:
	for o in objets:
		if o.get("type", "") == "relique":
			celebrer_relique(o)
			break
	if or_ > 0:
		notifier("+%d or" % or_, Color("#FFD36B"), "res://assets/icones_objets/pieces_or.png")
	for o in objets:
		var c := Objets.couleur(o)
		var t: String = o["nom"] + (" ×%d" % o["qte"] if o["qte"] > 1 else "")
		if o["type"] == "oeuf":
			t = "✦ " + o["nom"] + " ✦"
			Sons.jouer("cloche", heros.global_position, 0.0, 1.3)
		notifier(t, c, o["icone"])

func ouvrir_butin(titre: String, contenu: Dictionary, h: Node, couleur := Color.WHITE) -> void:
	var b := CanvasLayer.new()
	b.set_script(load("res://scripts/interface/butin_ui.gd"))
	add_child(b)
	b.montrer(titre, contenu, h, couleur)

func _process(delta: float) -> void:
	if heros:
		_chercher_action()
		_maj_notes(delta)
		_maj_canal(delta)
		_maj_combo(delta)
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
	if heros.action == "incantation" or heros.action == "canal":
		_incant.visible = true
		_incant_nom.text = Heros.COMPETENCES["e"]["nom"] if heros.action == "incantation" else heros.canal_en_cours()
		_incant_plein.color = GIVRE if heros.action == "incantation" else Color("#F4C35A")
		_incant_plein.size.x = 236.0 * clampf(heros._action_t / heros._action["duree"], 0.0, 1.0)
	else:
		_incant.visible = false
	if _fiche:
		_fiche_t -= delta
		if _fiche_t <= 0.0:
			_fiche.queue_free()
			_fiche = null
	_barres.queue_redraw()
