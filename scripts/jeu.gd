class_name Jeu
## Références partagées (interface, joueur) pour les objets du monde qui doivent ouvrir une fenêtre
## ou prévenir le joueur (coffres, filons, dépouilles, quêtes).

static var hud: CanvasLayer
static var joueur: Node3D
static var interface_bloquante := false   ## un écran (sac, butin, éclosion) capte les touches : pas de joystick ni de sorts

static func notifier(texte: String, couleur := Color.WHITE, icone := "") -> void:
	if hud and is_instance_valid(hud) and hud.has_method("notifier"):
		hud.notifier(texte, couleur, icone)

static func ouvrir_butin(titre: String, contenu: Dictionary, h: Node, couleur := Color.WHITE) -> void:
	if hud and is_instance_valid(hud) and hud.has_method("ouvrir_butin"):
		hud.ouvrir_butin(titre, contenu, h, couleur)

## Événements de jeu pour les quêtes (« tue », « mine », « coffre », « elite », « boss »).
static var ecouteurs: Array = []

static func evenement(nom: String, donnees := {}) -> void:
	for e in ecouteurs.duplicate():
		if e.is_valid():
			e.call(nom, donnees)
		else:
			ecouteurs.erase(e)
