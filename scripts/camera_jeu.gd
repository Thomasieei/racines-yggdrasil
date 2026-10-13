extends Camera3D
## Caméra plongeante fixe façon Albion (voir « Caméra » dans la direction du jeu).
## Valeurs de départ : à régler sur captures et sur téléphone.

@export var cible: Node3D
@export_range(30.0, 80.0) var plongee_deg := 55.0      ## angle de plongée
@export var largeur_visible := 34.0                    ## mètres visibles en largeur, au niveau du héros
@export var decalage_avant := 1.0                      ## le héros un peu sous le centre (m vers le nord)
@export var anticipation := 1.6                        ## glissement vers la direction de déplacement (m)
@export var amorti := 7.0                              ## vitesse de rattrapage
@export var amorti_rapide := 16.0                      ## pendant un saut ou une ruée
@export var zoom_min := 0.8
@export var zoom_max := 1.6

var zoom := 1.0
var _zoom_situation := 1.0
var _focus := Vector3.ZERO
var _avance := Vector3.ZERO
var _secousse := 0.0
## Point d'intérêt : un lieu majeur (portail, boss) attire doucement le cadrage et élargit la vue.
var point_interet := Vector3.INF
var poids_interet := 0.0
var _poids := 0.0

func _ready() -> void:
	fov = 40.0
	# rien d'utile au-delà : le brouillard cache le lointain, autant ne pas le dessiner
	far = 110.0
	near = 1.0
	if cible:
		_focus = cible.global_position

func secouer(force: float) -> void:
	_secousse = max(_secousse, force)

func regler_zoom_situation(z: float) -> void:
	_zoom_situation = z

func _physics_process(delta: float) -> void:
	if not cible:
		return
	# anticipation : on regarde un peu là où le héros va
	var dir := Vector3.ZERO
	if cible.has_method("direction_visee"):
		dir = cible.direction_visee()
	_avance = _avance.lerp(dir * anticipation, 1.0 - exp(-3.0 * delta))
	var rapide: bool = cible.has_method("en_mouvement_rapide") and cible.en_mouvement_rapide()
	var k := amorti_rapide if rapide else amorti
	var voulu := cible.global_position + _avance + Vector3(0, 0, -decalage_avant)
	_poids = lerpf(_poids, poids_interet if point_interet != Vector3.INF else 0.0, 1.0 - exp(-1.5 * delta))
	if point_interet != Vector3.INF:
		voulu = voulu.lerp(point_interet, _poids)
	_focus = _focus.lerp(voulu, 1.0 - exp(-k * delta))

	# distance calculée pour voir `largeur_visible` mètres en largeur
	var aspect := get_viewport().get_visible_rect().size.aspect()
	var z := clampf(zoom * _zoom_situation * (1.0 + _poids * 0.6), zoom_min, zoom_max)
	var hauteur_vue := largeur_visible * z / aspect
	var dist := (hauteur_vue * 0.5) / tan(deg_to_rad(fov * 0.5))
	var a := deg_to_rad(plongee_deg)
	var pos := _focus + Vector3(0, sin(a), cos(a)) * dist
	if _secousse > 0.0:
		pos += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _secousse * 0.25
		_secousse = max(0.0, _secousse - delta * 2.5)
	global_position = pos
	look_at(_focus, Vector3.UP)
