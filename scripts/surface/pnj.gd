class_name Pnj
extends Node3D
## Personnage non joueur : modèle animé, nom doré, marqueur de quête qui flotte, zone de parole.
## Les gardes invincibles sont des Pnj avec `garde = true` : ils abattent tout monstre entrant dans la zone sûre.

signal approche(p: Pnj)
signal eloigne(p: Pnj)

const P := "res://assets/personnages/"
const MODELES := {
	"freya": ["freya.glb", ["Spellbook", "Spellbook_open", "1H_Wand"], "Idle"],
	"garde": ["chevalier.glb", ["1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Spike_Shield", "1H_Sword", "Round_Shield"], "2H_Melee_Idle"],
	"marchand": ["marchand.glb", ["Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Knife", "Throwable"], "Idle"],
	"forgeron": ["barbare.glb", ["1H_Axe_Offhand", "Barbarian_Round_Shield", "Mug", "1H_Axe", "2H_Axe"], "Idle"],
}

@export var role := "freya"
@export var nom := "Freya"
@export var titre := ""
@export var marqueur := ""            ## "!" quête, "?" à rendre, "" rien
@export var rayon_parole := 4.0
@export var garde := false

var modele: Node3D
var anim: AnimationPlayer
var _etiquette: Label3D
var _sous: Label3D
var _marque: Label3D
var _proche := false
var _t := 0.0
var _frappe_t := 0.0

func _ready() -> void:
	add_to_group("pnj")
	var m: Array = MODELES[role]
	modele = load(P + m[0]).instantiate()
	add_child(modele)
	for n in m[1]:
		var x := modele.find_child(n, true, false)
		if x:
			x.visible = false
	anim = modele.find_child("AnimationPlayer", true, false)
	if anim:
		for a in anim.get_animation_list():
			if a in ["Idle", "2H_Melee_Idle", "Unarmed_Idle", "Spellcasting"]:
				anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		anim.play(m[2])
		anim.seek(randf() * 1.0, true)
	_etiquette = _texte(nom, 0.00072, Color("#F4C35A"), 2.75)
	if titre != "":
		_sous = _texte(titre, 0.00056, Color("#E8DCC4"), 2.75)
		_sous.offset = Vector2(0, -44)
	_marque = _texte(marqueur, 0.0016, Color("#FFD34E"), 3.4)
	_marque.outline_size = 18
	_marque.visible = marqueur != ""
	var corps := StaticBody3D.new()
	var f := CollisionShape3D.new()
	var c := CylinderShape3D.new()
	c.radius = 0.5
	c.height = 2.0
	f.shape = c
	f.position.y = 1.0
	corps.add_child(f)
	add_child(corps)

func _texte(t: String, px: float, c: Color, y: float) -> Label3D:
	var l := Label3D.new()
	l.text = t
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.fixed_size = true
	l.pixel_size = px
	l.font_size = 48
	l.outline_size = 12
	l.modulate = c
	l.outline_modulate = Color(0.06, 0.04, 0.02, 0.9)
	l.no_depth_test = true
	l.render_priority = 5
	l.position.y = y
	add_child(l)
	return l

func regler_marqueur(m: String) -> void:
	marqueur = m
	_marque.text = m
	_marque.visible = m != ""

func joueur_proche() -> bool:
	return _proche

func _process(delta: float) -> void:
	_t += delta
	_marque.position.y = 3.5 + sin(_t * 3.0) * 0.12
	var h := _heros()
	if h == null:
		return
	var d := global_position.distance_to(h.global_position)
	# les noms n'apparaissent qu'à portée de regard : la place reste lisible
	var a := clampf((14.0 - d) / 4.0, 0.0, 1.0)
	_etiquette.modulate.a = a
	_etiquette.outline_modulate.a = a * 0.9
	if _sous:
		_sous.modulate.a = a
		_sous.outline_modulate.a = a * 0.9
	var proche := d < rayon_parole
	if proche != _proche:
		_proche = proche
		if proche:
			approche.emit(self)
		else:
			eloigne.emit(self)
	# regarde le héros quand il s'approche
	if d < rayon_parole * 2.0 and not garde:
		var v := h.global_position - global_position
		modele.rotation.y = lerp_angle(modele.rotation.y, atan2(v.x, v.z) - rotation.y, 1.0 - exp(-4.0 * delta))
	if garde:
		_garder(delta)

## Garde invincible : un monstre en zone sûre est tranché net.
func _garder(delta: float) -> void:
	_frappe_t -= delta
	if _frappe_t > 0.0:
		return
	for e in get_tree().get_nodes_in_group("monstre"):
		if e.est_mort or not ZoneSure.contient(e.global_position):
			continue
		if global_position.distance_to(e.global_position) > 16.0:
			continue
		_frappe_t = 1.2
		var v: Vector3 = e.global_position - global_position
		modele.rotation.y = atan2(v.x, v.z) - rotation.y
		anim.play("2H_Melee_Attack_Chop", 0.05, 1.6)
		anim.queue("2H_Melee_Idle")
		Effets.taille(get_parent(), e.global_position - v.normalized() * 1.2, v.normalized(), 3.0, Color(1.0, 0.9, 0.6))
		e.recevoir({"montant": 99999.0, "source": null, "critique": true})
		Sons.jouer("cloche", e.global_position, 0.0, 1.2)
		return

func _heros() -> Node3D:
	var l := get_tree().get_nodes_in_group("joueur")
	return l[0] if not l.is_empty() else null
