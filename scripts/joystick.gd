extends Control
## Joystick tactile : apparaît sous le pouce, dans la moitié gauche de l'écran.

signal vecteur_change(v: Vector2)

@export var rayon := 60.0
var _doigt := -1
var _origine := Vector2.ZERO
var _vecteur := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var moitie := get_viewport_rect().size.x * 0.45
		if event.pressed and _doigt == -1 and event.position.x < moitie:
			_doigt = event.index
			_origine = event.position
			_maj(event.position)
		elif not event.pressed and event.index == _doigt:
			_doigt = -1
			_vecteur = Vector2.ZERO
			vecteur_change.emit(_vecteur)
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _doigt:
		_maj(event.position)

func _maj(p: Vector2) -> void:
	var d := p - _origine
	if d.length() > rayon:
		d = d.normalized() * rayon
	_vecteur = d / rayon
	vecteur_change.emit(_vecteur)
	queue_redraw()

func _draw() -> void:
	if _doigt == -1:
		return
	draw_circle(_origine, rayon, Color(1, 1, 1, 0.08))
	draw_arc(_origine, rayon, 0, TAU, 48, Color(1, 1, 1, 0.3), 2.0, true)
	draw_circle(_origine + _vecteur * rayon, rayon * 0.42, Color(1, 1, 1, 0.35))
