class_name Sons
extends Node
## Lecteur de bruitages : un nom de catégorie → plusieurs fichiers Kenney, joués avec une légère variation.

static var instance: Sons

const S := "res://assets/sons/"
const CATEGORIES := {
	"elan": ["rpg/drawKnife1.ogg", "rpg/drawKnife2.ogg", "rpg/drawKnife3.ogg"],
	"taille": ["rpg/knifeSlice.ogg", "rpg/knifeSlice2.ogg", "rpg/chop.ogg"],
	"coup_os": ["impacts/impactPlate_medium_000.ogg", "impacts/impactPlate_medium_001.ogg", "impacts/impactPlate_medium_002.ogg", "impacts/impactPlate_medium_003.ogg"],
	"coup_lourd": ["impacts/impactPunch_heavy_000.ogg", "impacts/impactPunch_heavy_001.ogg", "impacts/impactPunch_heavy_002.ogg", "impacts/impactPunch_heavy_003.ogg"],
	"coup_recu": ["impacts/impactSoft_heavy_000.ogg", "impacts/impactSoft_heavy_001.ogg", "impacts/impactSoft_heavy_002.ogg"],
	"metal": ["impacts/impactMetal_heavy_000.ogg", "impacts/impactMetal_heavy_001.ogg", "impacts/impactMetal_heavy_002.ogg"],
	"cloche": ["impacts/impactBell_heavy_000.ogg", "impacts/impactBell_heavy_001.ogg"],
	"verre_leger": ["impacts/impactGlass_light_000.ogg", "impacts/impactGlass_light_001.ogg", "impacts/impactGlass_light_002.ogg"],
	"verre_lourd": ["impacts/impactGlass_heavy_000.ogg", "impacts/impactGlass_heavy_001.ogg"],
	"atterrissage": ["impacts/impactWood_heavy_000.ogg", "impacts/impactWood_heavy_001.ogg"],
	"pas": ["impacts/footstep_concrete_000.ogg", "impacts/footstep_concrete_001.ogg", "impacts/footstep_concrete_002.ogg", "impacts/footstep_concrete_003.ogg"],
	"refus": ["interface/error_001.ogg", "interface/error_002.ogg"],
	"pret": ["interface/confirmation_001.ogg"],
	"activation": ["interface/maximize_003.ogg", "interface/maximize_006.ogg"],
	"potion": ["rpg/metalPot1.ogg", "rpg/metalPot2.ogg"],
	"tissu": ["rpg/cloth1.ogg", "rpg/cloth2.ogg", "rpg/cloth3.ogg"],
}

var _cache := {}
var _pool: Array[AudioStreamPlayer3D] = []

func _ready() -> void:
	instance = self
	for i in 16:
		var p := AudioStreamPlayer3D.new()
		p.unit_size = 12.0
		p.max_distance = 40.0
		add_child(p)
		_pool.append(p)

static func jouer(categorie: String, ou: Vector3, volume_db := 0.0, hauteur := 1.0) -> void:
	if instance:
		instance._jouer(categorie, ou, volume_db, hauteur)

func _jouer(categorie: String, ou: Vector3, volume_db: float, hauteur: float) -> void:
	if not CATEGORIES.has(categorie):
		return
	var liste: Array = CATEGORIES[categorie]
	var chemin: String = S + liste[randi() % liste.size()]
	if not _cache.has(chemin):
		_cache[chemin] = load(chemin)
	if _cache[chemin] == null:
		return
	var libre: AudioStreamPlayer3D = null
	for p in _pool:
		if not p.playing:
			libre = p
			break
	if libre == null:
		libre = _pool[0]
	libre.stream = _cache[chemin]
	libre.global_position = ou
	libre.volume_db = volume_db
	libre.pitch_scale = hauteur * randf_range(0.92, 1.08)
	libre.play()
