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
7. La sortie nord de la crypte ouvre sur le **Boyau des Murmures**, puis l'**étage 1 du donjon** : environ 15 000 m² de grottes sombres en quatre ailes, pensé pour une vingtaine de joueurs à la fois.
   - **Grande Caverne** : nid des rampants, autel du nécromant, gouffre sans fond, campement draugr, antre du **Jarl Hrafnkel** (élite), camp des Égarés (zone sûre), la Descente vers l'étage 2 (scellée).
   - **Ossuaire des Rois** (ouest) : allées de tombes, garde royale, trône de **Sigrid la Pâle** (élite qui relève les morts), **camp du Puits** (zone sûre et second point d'arrivée).
   - **Lac des Noyés** (sud-ouest) : lac noir infranchissable, noyés sur les rives, coffre sur la berge nord.
   - **Forges englouties** (nord-est) : ruines naines, coulées de lave, enclume de **Brokk le Déchu** (élite).
   - 25 camps, environ 60 draugr. Un camp vidé se repeuple après 1 à 4 minutes, jamais sous les yeux d'un joueur. Les draugr loin de tout joueur sont mis en sommeil (ni IA ni animation) pour garder le téléphone fluide.
8. Mourir ramène au sanctuaire.

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
- Carte de surface : `scripts/surface/` (carte, PNJ, scénario de Freya, guidage) ; donjon : `scripts/donjon/` (caverne, scénario) et `scripts/salle_entree.gd` (crypte).
- Interface : `scripts/interface/`.
- Options de lancement utiles (après `--`) : `--carte=crypte`, `--sans-intro`, `--depart=arche`, `--demo=combat`, `--demo=surface`, `--demo=donjon`, `--plan=fichier.png`.

Assets : packs KayKit et Kenney (CC0), détail dans `LICENCES.md`.
