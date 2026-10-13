extends Node3D
## Animation du bébé dragon (modèle Quaternius) : vol sur place en boucle, léger flottement,
## et un coup de tête / de griffe quand il attaque.

var _t := 0.0
var _anim: AnimationPlayer

func _ready() -> void:
	_anim = find_child("AnimationPlayer", true, false)
	if _anim:
		for n in ["Flying_Idle", "Fast_Flying"]:
			if _anim.has_animation(n):
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		_anim.play("Flying_Idle")
		_anim.seek(randf() * 1.0, true)
		_anim.animation_finished.connect(func(_n): _anim.play("Flying_Idle", 0.2))

func _process(delta: float) -> void:
	_t += delta
	var pivot := get_node_or_null("Pivot")
	if pivot:
		pivot.position.y = 0.08 * sin(_t * 2.6)

## Petite attaque visible (l'acolyte crache au même moment).
func attaquer() -> void:
	if _anim and _anim.has_animation("Headbutt"):
		_anim.play("Headbutt" if randf() < 0.5 else "Punch", 0.1, 1.6)
