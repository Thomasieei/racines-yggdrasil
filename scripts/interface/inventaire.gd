extends "res://scripts/interface/hud.gd"
## Écran d'inventaire (proposition de direction artistique) : parchemin beige, cases d'équipement,
## bord à la couleur de rareté, sac en grille, fiche de l'objet touché à droite.

const ICO := "res://assets/icones/"
const RARETES := {
	"commun": Color("#5DBB63"), "rare": Color("#3D8BFF"), "epique": Color("#A45CFF"),
	"legendaire": Color("#FF9A2E"), "mythique": Color("#E5383B"),
}

func _ready() -> void:
	racine = Control.new()
	racine.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(racine)
	var voile := ColorRect.new()
	voile.color = Color(0.02, 0.02, 0.04, 0.62)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.add_child(voile)
	_fenetre()

func _case(pos: Vector2, taille: float, icone: String, rarete: String, niveau: String, quantite: String, parent: Control, libelle := "") -> void:
	var creux := neuf(UI + "rpg/panelInset_beige.png", 14, Vector2(taille, taille), pos, parent)
	creux.modulate = Color(0.8, 0.72, 0.6)
	if rarete != "":
		var c: Color = RARETES[rarete]
		var fond := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(c.r, c.g, c.b, 0.22)
		sb.border_color = c
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(8)
		fond.add_theme_stylebox_override("panel", sb)
		fond.position = pos + Vector2(4, 4)
		fond.size = Vector2(taille - 8, taille - 8)
		parent.add_child(fond)
	if icone != "":
		image(ICO + icone, Vector2(taille - 18, taille - 18), pos + Vector2(9, 9), parent)
	elif libelle != "":
		texte(libelle, 12, Color(ENCRE2.r, ENCRE2.g, ENCRE2.b, 0.7), pos + Vector2(0, taille / 2 - 9), parent, false, taille, HORIZONTAL_ALIGNMENT_CENTER)
	if niveau != "":
		var pastille := Panel.new()
		var sp := StyleBoxFlat.new()
		sp.bg_color = Color("#2A1D0C")
		sp.set_corner_radius_all(9)
		pastille.add_theme_stylebox_override("panel", sp)
		pastille.position = pos + Vector2(5, 5)
		pastille.size = Vector2(26, 18)
		parent.add_child(pastille)
		texte(niveau, 11, OR, pos + Vector2(5, 5), parent, false, 26, HORIZONTAL_ALIGNMENT_CENTER)
	if quantite != "":
		texte(quantite, 13, Color.WHITE, pos + Vector2(0, taille - 22), parent, true, taille - 8, HORIZONTAL_ALIGNMENT_RIGHT)

func _fenetre() -> void:
	var f := neuf(UI + "rpg/panel_beige.png", 18, Vector2(1000, 500), Vector2(140, 40))
	texte("Inventaire", 26, ENCRE, Vector2(28, 14), f, false)
	texte("Puissance d'objet 1 126 · Charge 34 %", 14, ENCRE2, Vector2(30, 50), f, false)
	# équipement (3 colonnes, 4 rangées)
	var t := 78.0
	var x0 := 28.0
	var y0 := 80.0
	var g := 8.0
	var cases := [
		[0, 0, "", "", "", "Sac"], [1, 0, "", "", "", "Tête"], [2, 0, "", "", "", "Cape"],
		[0, 1, "001_axe_2handed.png", "legendaire", "IV", "Arme"], [1, 1, "", "", "", "Torse"], [2, 1, "005_shield_round_barbarian.png", "rare", "III", "Main g."],
		[0, 2, "", "", "", "Potion"], [1, 2, "", "", "", "Bottes"], [2, 2, "049_mug_full.png", "commun", "II", "Repas"],
	]
	for c in cases:
		_case(Vector2(x0 + c[0] * (t + g), y0 + c[1] * (t + g)), t, c[2], c[3], c[4], "", f, c[5])
	_case(Vector2(x0 + (t + g), y0 + 3 * (t + g)), t, "", "", "", "", f, "Monture")
	# sac
	texte("Sac", 16, ENCRE, Vector2(300, 80), f, false)
	var sac := [
		["014_sword_2handed.png", "epique", "V", ""], ["062_Copper_Bar.png", "commun", "", "12"], ["024_Stone_Brick.png", "commun", "", "30"],
		["044_arrow_bundle.png", "rare", "", "48"], ["047_dagger.png", "rare", "III", ""], ["052_staff.png", "mythique", "VI", ""],
		["030_Wood_Log_A.png", "commun", "", "8"], ["007_shield_spikes.png", "epique", "IV", ""], ["", "", "", ""], ["", "", "", ""],
		["", "", "", ""], ["", "", "", ""],
	]
	var ts := 64.0
	for i in sac.size():
		var s: Array = sac[i]
		_case(Vector2(300 + (i % 4) * (ts + 6), 106 + (i / 4) * (ts + 6)), ts, s[0], s[1], s[2], s[3], f)
	texte("Valeur du sac : 2 840 or", 14, ENCRE2, Vector2(300, 320), f, false)
	texte("Ce que tu risques si tu meurs", 12, Color(ENCRE2.r, ENCRE2.g, ENCRE2.b, 0.75), Vector2(300, 340), f, false)
	# boutons de tenues
	var b1 := neuf(UI + "rpg/buttonLong_brown.png", 14, Vector2(130, 40), Vector2(300, 420), f)
	texte("Tenues", 15, Color("#FFF4DC"), Vector2(0, 9), b1, true, 130, HORIZONTAL_ALIGNMENT_CENTER)
	var b2 := neuf(UI + "rpg/buttonLong_brown.png", 14, Vector2(130, 40), Vector2(440, 420), f)
	texte("Garde-robe", 15, Color("#FFF4DC"), Vector2(0, 9), b2, true, 130, HORIZONTAL_ALIGNMENT_CENTER)
	_fiche(f)

func _fiche(f: Control) -> void:
	var d := neuf(UI + "rpg/panel_beigeLight.png", 18, Vector2(390, 440), Vector2(590, 30), f)
	var c: Color = RARETES["legendaire"]
	_case(Vector2(18, 18), 70, "001_axe_2handed.png", "legendaire", "IV", "", d)
	texte("Hache du Jarl", 20, c.darkened(0.25), Vector2(100, 20), d, false)
	texte("Légendaire · niveau IV · 412 or", 13, ENCRE2, Vector2(100, 48), d, false)
	texte("Dégâts 186 (+24)   Vitesse 0,9 s", 13, Color("#2E7D32"), Vector2(100, 66), d, false)
	var lignes := [
		["slash_02.png", "Fendoir", "Cône devant soi, 34 dégâts · 4 s · 10 énergie"],
		["trace_03.png", "Bond du berserker", "Saut de 7 m, ralentit à l'impact · 8 s"],
		["twirl_02.png", "Ruée runique", "Ruée de 12 m, étourdit 1,4 s · 26 s"],
		["star_06.png", "Passif : Rage", "+15 % de dégâts sous 30 % de vie"],
	]
	for i in lignes.size():
		var y := 108.0 + i * 62.0
		icone_sort(Vector2(18, y), 46, lignes[i][0], OR, d)
		texte(lignes[i][1], 15, ENCRE, Vector2(74, y + 2), d, false)
		texte(lignes[i][2], 12, ENCRE2, Vector2(74, y + 24), d, false)
	var noms := ["Déséquiper", "Comparer", "Vendre"]
	for i in 3:
		var b := neuf(UI + "rpg/buttonLong_beige.png", 14, Vector2(110, 40), Vector2(18 + i * 120, 380), d)
		texte(noms[i], 14, ENCRE, Vector2(0, 10), b, false, 110, HORIZONTAL_ALIGNMENT_CENTER)
