extends CharacterBody3D
## Héros : déplacement au joystick (ou ZQSD/WASD), orientation, animations KayKit.

@export var vitesse := 6.0
@export var acceleration := 40.0
@export var modele_scene: PackedScene

var entree := Vector2.ZERO          ## fourni par le joystick tactile
var _anim: AnimationPlayer
var _modele: Node3D
var _anim_courante := ""

const MESHES_CACHES := ["1H_Axe_Offhand", "Barbarian_Round_Shield", "Mug", "1H_Axe"]

func _ready() -> void:
	if modele_scene:
		_modele = modele_scene.instantiate()
		add_child(_modele)
		for n in MESHES_CACHES:
			var m := _modele.find_child(n, true, false)
			if m:
				m.visible = false
		_anim = _modele.find_child("AnimationPlayer", true, false)
		if _anim:
			for nom in ["2H_Melee_Idle", "Running_A", "Walking_A"]:
				if _anim.has_animation(nom):
					_anim.get_animation(nom).loop_mode = Animation.LOOP_LINEAR
	jouer("2H_Melee_Idle")

func jouer(nom: String, fondu := 0.15) -> void:
	if _anim and nom != _anim_courante and _anim.has_animation(nom):
		_anim.play(nom, fondu)
		_anim_courante = nom

func direction_visee() -> Vector3:
	var v := Vector3(velocity.x, 0, velocity.z)
	return v / vitesse if v.length() > 0.1 else Vector3.ZERO

func en_mouvement_rapide() -> bool:
	return false

func _physics_process(delta: float) -> void:
	var clavier := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	for t in [[KEY_Q, Vector2.LEFT], [KEY_A, Vector2.LEFT], [KEY_D, Vector2.RIGHT], [KEY_Z, Vector2.UP], [KEY_W, Vector2.UP], [KEY_S, Vector2.DOWN]]:
		if Input.is_physical_key_pressed(t[0]):
			clavier += t[1]
	var e := entree + clavier
	if e.length() > 1.0:
		e = e.normalized()
	var voulu := Vector3(e.x, 0, e.y) * vitesse
	var h := Vector3(velocity.x, 0, velocity.z).move_toward(voulu, acceleration * delta)
	velocity.x = h.x
	velocity.z = h.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()
	if h.length() > 0.3:
		var ang := atan2(h.x, h.z)
		rotation.y = lerp_angle(rotation.y, ang, 1.0 - exp(-14.0 * delta))
		jouer("Running_A")
		if _anim:
			_anim.speed_scale = clampf(h.length() / vitesse, 0.6, 1.1)
	else:
		jouer("2H_Melee_Idle")
		if _anim:
			_anim.speed_scale = 1.0
