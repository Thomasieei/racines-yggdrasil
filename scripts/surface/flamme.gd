extends OmniLight3D
## Lumière de feu qui vacille (deux sinus décalés + petit bruit : jamais de rythme mécanique).

var _base := 0.0
var _t := 0.0

func _ready() -> void:
	_base = light_energy
	_t = randf() * 10.0

func _process(delta: float) -> void:
	_t += delta
	light_energy = _base * (0.86 + 0.08 * sin(_t * 7.3) + 0.05 * sin(_t * 13.1 + 1.7) + randf_range(-0.03, 0.03))
