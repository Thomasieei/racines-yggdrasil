# Racines d'Yggdrasil

Donjon d'extraction mobile (Godot 4.3, paysage). Un donjon du jour partagé, Freya qui ressuscite sans l'équipement, des zones sûres, un combat lent et lisible à recharges.

## Tester

**Sur téléphone Android.** Ouvre la page *Releases* du dépôt, version **« essai »**, télécharge `racines-yggdrasil.apk` et installe-le (autorise l'installation depuis cette source). L'APK est reconstruit automatiquement à chaque envoi sur `main` (onglet *Actions*).

**Sur PC.** Même page : `RacinesYggdrasil-windows.zip`, décompresser, lancer `RacinesYggdrasil.exe`. Ou ouvrir le dossier dans **Godot 4.3** (moteur « Compatibility ») et appuyer sur F5.

## Ce qu'on peut faire aujourd'hui

1. Réveil au **Sanctuaire de Freya** : elle raconte le donjon et la mort.
2. Suivre la **traînée dorée** dans le Bois des Murmures.
3. **Clairière des Tertres** : trois draugr sortent de terre, premier combat.
4. Un guerrier et un arbalétrier draugr gardent le chemin.
5. **Bourg de Skjold**, zone sûre : gardes, marchand, forgeronne, feu de camp. Les sorts offensifs y sont refusés, les monstres n'y entrent pas.
6. **Portail d'Yggdrasil** au nord du Bourg : entrer dedans fait descendre dans la **Crypte des nains** (le donjon du jour, cinq draugr).
7. Mourir ramène au sanctuaire.

Pas encore branchés : menus du marchand et de la forge, sac et inventaire en jeu, coffres et butin, corps à récupérer, multijoueur.

## Commandes

| Tactile | Clavier / souris |
|---|---|
| Moitié gauche de l'écran : joystick | Flèches |
| Toucher un sort : lancé vers l'ennemi le plus proche | 1 à 6 |
| Glisser depuis un sort : viser (aperçu bleu), relâcher pour lancer ; revenir sur le bouton annule | — |
| Appui long sur un sort : sa fiche | — |
| Bouton de roulade | Espace |
| Toucher la minicarte : guidage vers le Bourg | clic sur la minicarte |
| Toucher le dialogue : continuer | Entrée |

Sorts du barbare : Fendoir (cône), Bond du berserker (saut), Ruée runique (incantation puis ruée qui étourdit), Bulle de Freya, Pas du vent, Potion, Roulade.

## Pour le développement

- Scène principale : `scenes/principale.tscn` → `scripts/principale.gd`.
- Combat : `scripts/combat/` (héros, draugr, zones, télégraphes au sol, effets, sons, zones sûres).
- Carte de surface : `scripts/surface/` (carte, PNJ, scénario de Freya, guidage) ; crypte : `scripts/salle_entree.gd`.
- Interface : `scripts/interface/`.
- Options de lancement utiles (après `--`) : `--carte=crypte`, `--sans-intro`, `--demo=combat`, `--demo=surface`, `--plan=fichier.png`.

Assets : packs KayKit et Kenney (CC0), détail dans `LICENCES.md`.
