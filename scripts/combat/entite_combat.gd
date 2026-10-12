class_name EntiteCombat
extends CharacterBody3D
## Base commune au héros et aux monstres : vie, contrôles, réception des coups, retours visuels, animations.

signal mort(entite: EntiteCombat)
signal pv_change(pv: float, pv_max: float)

@export var pv_max := 100.0
@export var vitesse := 4.0
@export var camp := "monstre"
@export var rayon := 0.55
@export var hauteur_barre := 2.6

var pv := 100.0
var est_mort := false
var etourdi_t := 0.0
var ralenti_t := 0.0
var immunite_controle_t := 0.0
var invulnerable_t := 0.0
var bulle: Node = null                 ## Bulle de Freya active (absorbe les coups)

var modele: Node3D
var anim: AnimationPlayer
var anim_courante := ""
var verrou_anim := 0.0                 ## tant qu'une action joue, la marche ne reprend pas la main
var _mat_flash: StandardMaterial3D
var _meshes: Array[MeshInstance3D] = []

const BOUCLES := ["Idle", "2H_Melee_Idle", "Running_A", "Running_B", "Walking_A", "Walking_Backwards", "Idle_Combat", "Walking_D_Skeletons", "Blocking", "Jump_Idle"]

func _ready() -> void:
	pv = pv_max
	add_to_group("combattants")
	add_to_group(camp)
	_mat_flash = StandardMaterial3D.new()
	_mat_flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_flash.albedo_color = Color(1, 1, 1, 0.0)
	_mat_flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_flash.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat_flash.disable_fog = true   # sinon le brouillard dessine un carré clair autour de l'effet

func installer_modele(scene: PackedScene, echelle := 1.0, caches: Array = []) -> void:
	modele = scene.instantiate()
	modele.scale = Vector3.ONE * echelle
	add_child(modele)
	for n in caches:
		var m := modele.find_child(n, true, false)
		if m:
			m.visible = false
	anim = modele.find_child("AnimationPlayer", true, false)
	if anim:
		for nom in BOUCLES:
			if anim.has_animation(nom):
				anim.get_animation(nom).loop_mode = Animation.LOOP_LINEAR
	for m in modele.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.visible:
			_meshes.append(mi)
			mi.material_overlay = _mat_flash

## Joue une animation. `verrou` = durée pendant laquelle la locomotion ne la remplace pas.
func jouer(nom: String, fondu := 0.12, vitesse_anim := 1.0, verrou := 0.0) -> void:
	if not anim or not anim.has_animation(nom):
		return
	if nom == anim_courante and verrou <= 0.0:
		return
	anim.play(nom, fondu, vitesse_anim)
	if verrou > 0.0:
		anim.seek(0.0, true)
	anim_courante = nom
	verrou_anim = maxf(verrou_anim, verrou)

func direction_vers(p: Vector3) -> Vector3:
	var d := p - global_position
	d.y = 0
	return d.normalized() if d.length() > 0.01 else -global_transform.basis.z

func regarder(direction: Vector3, delta := -1.0) -> void:
	if direction.length() < 0.01:
		return
	var cible := atan2(direction.x, direction.z)
	rotation.y = cible if delta < 0.0 else lerp_angle(rotation.y, cible, 1.0 - exp(-16.0 * delta))

func peut_agir() -> bool:
	return not est_mort and etourdi_t <= 0.0

## Point d'entrée unique des dégâts.
## d = { montant, source (EntiteCombat ou null), critique, etourdir (s), ralentir (s), recul (m), lourd (bool) }
func recevoir(d: Dictionary) -> void:
	if est_mort or invulnerable_t > 0.0:
		return
	var montant: float = d.get("montant", 0.0)
	var source: EntiteCombat = d.get("source", null)
	var crit: bool = d.get("critique", false)
	var origine: Vector3 = source.global_position if source else global_position + Vector3(0, 0, -1)
	if bulle and bulle.has_method("absorber"):
		var avant := montant
		montant = bulle.absorber(origine + Vector3(0, 1.2, 0), montant)
		if avant - montant > 0.5:
			Effets.nombre(get_parent(), global_position, str(int(avant - montant)), Color("#CFEFFF"), false, "absorbe")
			Sons.jouer("verre_leger", global_position, -4.0)
	if montant > 0.0:
		pv = maxf(0.0, pv - montant)
		pv_change.emit(pv, pv_max)
		_flash()
		var couleur := Color("#FF6A5A") if camp == "joueur" else (Color("#FFD36B") if crit else Color.WHITE)
		Effets.nombre(get_parent(), global_position, str(int(round(montant))) + ("!" if crit else ""), couleur, crit, "subi" if camp == "joueur" else "")
		Effets.etincelles(get_parent(), global_position + Vector3(0, 1.1, 0), (global_position - origine).normalized() + Vector3(0, 0.6, 0), Color(1.0, 0.85, 0.6) if camp != "joueur" else Color(1.0, 0.35, 0.3), 12 if not crit else 22)
		_reaction_coup(d)
	# contrôles, avec immunité courte après un étourdissement
	var etourdir: float = d.get("etourdir", 0.0)
	if etourdir > 0.0 and immunite_controle_t <= 0.0:
		etourdi_t = maxf(etourdi_t, etourdir)
		immunite_controle_t = etourdir + 1.5
		interrompre()
		Effets.nombre(get_parent(), global_position, "Étourdi", Color("#CFD6EE"), false, "etat")
	var ralentir: float = d.get("ralentir", 0.0)
	if ralentir > 0.0:
		ralenti_t = maxf(ralenti_t, ralentir)
	var recul: float = d.get("recul", 0.0)
	if recul > 0.0 and source:
		var dir := (global_position - source.global_position)
		dir.y = 0
		velocity += dir.normalized() * recul * 6.0
	if pv <= 0.0:
		_mourir()

func soigner(montant: float) -> void:
	if est_mort:
		return
	pv = minf(pv_max, pv + montant)
	pv_change.emit(pv, pv_max)

## À redéfinir : annule une préparation ou une incantation en cours.
func interrompre() -> void:
	pass

func _reaction_coup(_d: Dictionary) -> void:
	pass

func _flash() -> void:
	_mat_flash.albedo_color = Color(1, 1, 1, 0.75)
	var tw := create_tween()
	tw.tween_property(_mat_flash, "albedo_color:a", 0.0, 0.14)

func _mourir() -> void:
	est_mort = true
	collision_layer = 0
	velocity = Vector3.ZERO
	interrompre()
	mort.emit(self)

func _process_etats(delta: float) -> void:
	etourdi_t = maxf(0.0, etourdi_t - delta)
	ralenti_t = maxf(0.0, ralenti_t - delta)
	immunite_controle_t = maxf(0.0, immunite_controle_t - delta)
	invulnerable_t = maxf(0.0, invulnerable_t - delta)
	verrou_anim = maxf(0.0, verrou_anim - delta)

func facteur_vitesse() -> float:
	return 0.5 if ralenti_t > 0.0 else 1.0

## Freine les poussées (recul) et applique la gravité.
func appliquer_physique(delta: float) -> void:
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()
