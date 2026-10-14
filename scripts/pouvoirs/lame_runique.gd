extends Node3D
## Scie runique : disque doré qui tourne à toute vitesse, dents lumineuses, traînée de lumière.

var _disque: Node3D

func _ready() -> void:
	_disque = Node3D.new()
	add_child(_disque)
	var corps := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.55
	c.bottom_radius = 0.55
	c.height = 0.06
	c.radial_segments = 20
	corps.mesh = c
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.85, 0.45)
	m.metallic = 0.8
	m.roughness = 0.25
	m.emission_enabled = true
	m.emission = Color(1.0, 0.7, 0.3)
	m.emission_energy_multiplier = 1.4
	corps.material_override = m
	_disque.add_child(corps)
	# dents
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(1.0, 0.95, 0.8)
	dm.emission_enabled = true
	dm.emission = Color(1.0, 0.9, 0.6)
	dm.emission_energy_multiplier = 2.0
	for i in 10:
		var d := MeshInstance3D.new()
		var p := PrismMesh.new()
		p.size = Vector3(0.18, 0.22, 0.05)
		d.mesh = p
		d.material_override = dm
		var a := TAU * i / 10.0
		d.position = Vector3(cos(a), 0, sin(a)) * 0.62
		d.rotation = Vector3(PI / 2, -a + PI / 2, 0)
		_disque.add_child(d)
	_disque.rotation.x = deg_to_rad(70)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.75, 0.4)
	l.light_energy = 1.2
	l.omni_range = 3.5
	add_child(l)
	Effets.trainee_lumineuse(self, Color(1.0, 0.8, 0.4))

func _process(delta: float) -> void:
	_disque.rotate_object_local(Vector3.UP, delta * 28.0)
