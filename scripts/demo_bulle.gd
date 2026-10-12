extends Node
## Démo filmée de la Bulle de Freya : deux draugr frappent le héros, la bulle absorbe, se fissure, éclate.

var joueur: CharacterBody3D
var camera: Camera3D
var bulle: Node3D
var draugrs: Array[Node3D] = []

func lancer(j: CharacterBody3D, c: Camera3D) -> void:
	joueur = j
	camera = c
	camera.largeur_visible = 15.0
	camera.decalage_avant = 0.0
	joueur.position = Vector3(14, 0.05, 14)
	joueur.rotation.y = PI
	joueur.set_physics_process(false)
	bulle = Node3D.new()
	bulle.set_script(load("res://scripts/competences/bulle_freya.gd"))
	joueur.add_child(bulle)
	# deux draugr face au héros
	for d in [[Vector3(12.3, 0, 12.6), 0.0], [Vector3(15.9, 0, 12.8), 0.0]]:
		var m: Node3D = load("res://assets/personnages/squelette_warrior.glb").instantiate()
		var arme: Node3D = load("res://assets/personnages/skeleton_axe.glb").instantiate()
		var main := m.find_child("handslotr", true, false)
		if main:
			main.add_child(arme)
		m.position = d[0]
		m.rotation.y = d[1]
		joueur.get_parent().add_child(m)
		var vers := joueur.position - m.position
		m.rotation.y = atan2(vers.x, vers.z)
		var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
		ap.get_animation("Idle_Combat").loop_mode = Animation.LOOP_LINEAR
		ap.play("Idle_Combat")
		draugrs.append(m)
	_sequence()

func _attente(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _frappe(i: int, degats: float) -> void:
	var m := draugrs[i]
	var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	ap.play("1H_Melee_Attack_Chop", 0.1)
	ap.queue("Idle_Combat")
	await _attente(0.38)
	bulle.absorber(m.global_position + Vector3(0, 1.2, 0), degats)
	camera.secouer(0.25)

func _sequence() -> void:
	await _attente(0.6)
	joueur.jouer("Block", 0.1)
	bulle.activer()
	await _attente(0.9)
	joueur.jouer("2H_Melee_Idle")
	_frappe(0, 18)
	await _attente(0.65)
	_frappe(1, 18)
	await _attente(0.65)
	_frappe(0, 18)
	await _attente(0.6)
	_frappe(1, 18)
	await _attente(0.7)
	_frappe(0, 22)
	await _attente(1.6)
	get_tree().quit()
