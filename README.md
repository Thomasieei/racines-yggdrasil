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
   - 34 camps, plus de 80 draugr. Un camp vidé se repeuple après 1 à 4 minutes, jamais sous les yeux d'un joueur. Les draugr loin de tout joueur sont mis en sommeil (ni IA ni animation) pour garder le téléphone fluide.
8. **Ymir, Roi des Draugr** (boss d'étage) se réveille au cœur de la Grande Caverne au bout de 3 minutes (compte à rebours sous le titre, alerte 30 s avant) : trois fois la taille d'un draugr, 14 000 PV, aura rouge, invoque des morts, entre en rage sous 50 %. Il revient 10 minutes après sa mort.
9. **Quêtes de Bjorn l'Égaré** (camp des Égarés, bouton « Parler ») : rampants, cuivre, coffres, un élite, puis Ymir. Récompenses en or et en œufs de dragon.
10. **Coffres** (commun → mythique) : on les ouvre (1,4 s), une fenêtre montre le vrai contenu (or, armes, minerais, potions, parfois un œuf). **Filons** (cuivre, fer, argent, or) : on mine (2,2 s), le métier **Mineur** monte de niveau et débloque les filons rares.
11. **Œufs de dragon** : rares. Dans le sac, « Faire éclore » : le bébé est commun, rare, épique, légendaire ou mythique (au-delà du bleu, c'est extrêmement rare) avec 1 à 5 étoiles de puissance. On l'équipe comme **acolyte** (il crache du feu et grandit en gagnant de l'expérience) ou on le revend au marchand.
12. **Sac** (bouton en haut à droite, ou B) : 30 cases, arme et acolyte équipés, valeur de ce qu'on risque. **Tout ce qu'on porte est perdu à la mort** : si un autre aventurier nous tue, il prend tout ; sinon tout reste sur la dépouille, que n'importe qui peut fouiller.
13. **Autres aventuriers (IA)** : 4 à 7 joueurs simulés en attendant le vrai multijoueur : pseudos et capes différents, certains déjà en voie draconique, arrivées étalées dans le temps, jamais à côté du joueur, et un petit canal de discussion. Ils farment les camps, minent, ouvrent les coffres, boivent leurs potions, partent parfois AFK… et certains attaquent quand on est affaibli. Pseudo bleu = neutre, rouge = hostile ; sous le pseudo, sa puissance : verte s'il est plus faible que toi, jaune s'il est de ta force, orange puis rouge s'il est plus fort. On peut aussi les attaquer (hors zones sûres) et leur prendre leur sac.
14. Le didacticiel de Freya ne se joue qu'une fois : après une mort, on repart directement vers le Portail.
15. **Arbre des Racines** (bouton arbre doré, ou T) : 15 talents en trois racines — Loup (force), Chêne (endurance), Corbeau (ruse). Les paliers s'ouvrent à 5, 10, 15 et 20 points investis ; un rang coûte 1 point au premier palier, puis 2, 3, 4, et 5 pour un ultime (incompatibles entre eux). Réinitialisation contre 200 or.
15. **Codex** (bouton livre, ou C) : les réalisations donnent les points de talent (1 à 10 chacune). Certaines sont des secrets : on n'en voit que l'indice.
16. **Reliques** : six emplacements dans le sac, de +1,6 % (vert) à +35 % (rouge) sur la puissance des compétences, les PV, l'énergie ou la recharge.
17. **Voies draconiques** : aucune indication sur la carte. Freya n'en dit qu'un mot. Ceux qui trouvent les trois fragments de rune les voient se rejoindre en un œuf runique ; briser le sceau mène à une épreuve solo où l'équipement ne compte plus, puis au choix définitif entre trois pouvoirs incompatibles (Souffle, Écailles, Ailes), chacun avec sa force et sa faiblesse. C'est le titre de classe qui donne les compétences ; l'arme n'ajoute que de la puissance, et chaque classe n'en manie qu'une famille : grande hache (Berserker), bâton (Souffle), épée et bouclier (Écailles), dagues (Ailes).
18. Mourir ramène au sanctuaire. Le sac suit le joueur d'une carte à l'autre, mais reste sur le corps à la mort.

**La boucle d'extraction** : on descend, on pille, et l'on remonte **vivant** par une **racine de retour** (camp des Égarés ou camp du Puits, 5 s sans se faire toucher) avec tout son sac. Au Bourg, **ton coffre** garde à l'abri ce qu'on y range (rien ne s'y perd, même en mourant) et **Halvard** rachète le butin et vend des potions. Le sac et le coffre sont sauvegardés sur le téléphone. **Ingrid** forge l'arme équipée jusqu'à +10 avec du minerai et de l'or. Chaque descente dure **20 minutes** : passé ce délai, la montagne se referme sur ceux qui n'ont pas pris de racine de retour.

Pas encore branché : vrai multijoueur en ligne.

Le bébé dragon est le Dragon Evolved de Quaternius (CC0, animé) et l'œuf un modèle à écailles de la banque d'assets (CC0), tous deux recolorés selon la rareté.

## Pouvoirs du monde (mana violet, boutons à droite)

- **Téléportation** (30 mana) : touche la minicarte (ou M) pour ouvrir la grande carte, touche un endroit : ton héros incante puis y apparaît. « Y aller à pied » marque la destination.
- **Lames de moisson** (35 mana, touche 7) : des scies runiques rasent jusqu'à 9 arbres, rochers ou filons autour de toi ; bois, pierre, minerais et expérience de Mineur d'un coup. Les arbres repoussent.
- **Déchaînement** (70 mana, touche 8) : incantation d'1 s que les coups n'interrompent pas, puis une explosion qui pulvérise tout dans un rayon de 18 m.
- **Pantin** (40 mana, touche 9) : l'habitant ou le garde le plus proche devient ton pantin (3 au plus), sans que tu quittes ton corps. Son médaillon apparaît à gauche ; touche-le pour lui donner un ordre : **Suis-moi** (il te défend, et descend au donjon avec toi), **Coupe du bois** / **Mine la pierre** (vrais arbres, vrais rochers ; la récolte va dans ton coffre), **Cambriole…** (maison, forge, étal, temple, château du Jarl : il entre, ressort et t'apporte le butin ; s'il est vu, les gardes le poursuivent et peuvent l'arrêter), **Attaque…** (habitant, garde, pillard), **Monte la garde**, **Prends son corps** (60 s : tu fouilles toi-même une maison), **Libère-le**. Un pantin mort se relève avec une **Robe de résurrection**, et reste à toi pour toujours.
- **Entrer dans les maisons** : chaque porte s'ouvre (« Entrer »). Intérieurs meublés ; coffre à fouiller si personne n'est là, chope à la taverne (soins), autel d'Odin au temple, **trésor du Jarl** au château… gardé par ses huscarls.
- **Ta maison** (Brekka, une fois chef) : ton coffre, ton lit (dormir jusqu'à l'aube) et l'intendante qui recrute des **serviteurs** (150 or, 3 au plus) qui t'obéissent comme des pantins, sans mana.
- **Devenir chef de Brekka** : parle à Sigurd, apporte 40 bois, 20 pierre et 500 or. Ensuite, donne un métier à chaque habitant (bûcheron, mineur, fermier, garde) : ils produisent pour toi en continu, même jeu fermé (8 h au plus). Améliore scierie, carrière, moulin et palissade (+50 % par niveau), puis vide le grenier : l'or dans ton sac, le reste dans ton coffre.
- **Terres Gâtées** (au sud-est du Bourg, par la porte sud) : la Horde, des centaines de rampants qui déferlent sans fin. Chaque rampant pulvérisé rend un peu de mana : on enchaîne les Déchaînements.

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
| Bouton main (à droite) : ouvrir, miner, fouiller, parler | E |
| Bouton sac | B ou I |

Sorts du barbare : Fendoir (cône), Bond du berserker (saut), Ruée runique (incantation puis ruée qui étourdit), Bulle de Freya, Pas du vent, Potion, Roulade.

## Pour le développement

- Scène principale : `scenes/principale.tscn` → `scripts/principale.gd`.
- Combat : `scripts/combat/` (héros, draugr, zones, télégraphes au sol, effets, sons, zones sûres).
- Carte de surface : `scripts/surface/` (carte, PNJ, scénario de Freya, guidage) ; donjon : `scripts/donjon/` (caverne, scénario) et `scripts/salle_entree.gd` (crypte).
- Interface : `scripts/interface/`.
- Objets, sac, coffres, filons, œufs : `scripts/objets/`. Aventuriers IA : `scripts/combat/bot.gd` (cerveau) et `scripts/donjon/nav_caverne.gd` (grille de déplacement).
- Options de lancement utiles (après `--`) : `--carte=crypte`, `--sans-intro`, `--depart=arche`, `--sans-bots`, `--demo=combat`, `--demo=surface`, `--demo=donjon`, `--demo=bots`, `--plan=fichier.png`.
- Progression : `scripts/progression/` (profil sauvegardé, talents, codex, classes, suivi des réalisations).
- Tests : `--test-bots`, `--test-jcj`, `--test-quetes`, `--test-objets`, `--test-repeuplement`, `--test-progression`, `--test-runes`, `--carte=epreuve --test-epreuve` ; `--profil-neuf`, `--classe=souffle|ecailles|ailes`.

Assets : packs KayKit et Kenney (CC0), détail dans `LICENCES.md`.
