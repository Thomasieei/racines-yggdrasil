# Génère les icônes vectorielles (talents, reliques, boutons) dans le style des icônes de sorts :
# contour brun-noir épais, remplissages en dégradé or / givre / vert / rouge.
import os
RACINE = os.path.join(os.path.dirname(__file__), "..", "assets")
DEFS = '''<defs>
<linearGradient id="or" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFF1C4"/><stop offset="0.55" stop-color="#F4C35A"/><stop offset="1" stop-color="#C77A22"/></linearGradient>
<linearGradient id="givre" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F2FCFF"/><stop offset="0.55" stop-color="#7FE3FF"/><stop offset="1" stop-color="#2E8FD0"/></linearGradient>
<linearGradient id="vert" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F0FFF6"/><stop offset="0.55" stop-color="#9CE07A"/><stop offset="1" stop-color="#3C8A3A"/></linearGradient>
<linearGradient id="rouge" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFB3A8"/><stop offset="0.5" stop-color="#E5383B"/><stop offset="1" stop-color="#8E1520"/></linearGradient>
<linearGradient id="acier" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#AFC0D6"/></linearGradient>
<linearGradient id="bois" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#D9A86A"/><stop offset="1" stop-color="#7A4A22"/></linearGradient>
<linearGradient id="nuit" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9AA6C8"/><stop offset="1" stop-color="#2C3150"/></linearGradient>
</defs>'''
N = "#1A120A"

def forme(d, fill="url(#or)", w=6, extra=""):
    # contour noir épais puis la forme
    return (f'<path d="{d}" fill="none" stroke="{N}" stroke-width="{w + 8}" stroke-linejoin="round" stroke-linecap="round"/>'
            f'<path d="{d}" fill="{fill}" stroke="{N}" stroke-width="{w}" stroke-linejoin="round" stroke-linecap="round" {extra}/>')

def trait(d, coul="url(#or)", w=8):
    return (f'<path d="{d}" fill="none" stroke="{N}" stroke-width="{w + 8}" stroke-linecap="round" stroke-linejoin="round"/>'
            f'<path d="{d}" fill="none" stroke="{coul}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>')

def reflet(d, w=4):
    return f'<path d="{d}" fill="none" stroke="#FFF8E2" stroke-width="{w}" stroke-linecap="round" opacity="0.85"/>'

def svg(corps):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 128 128">{DEFS}\n{corps}\n</svg>\n'

T = {}
# ---- Loup ----
T["morsure"] = forme("M22 40 Q64 18 106 40 Q100 52 92 54 L84 80 L76 56 L52 56 L44 80 L36 54 Q28 52 22 40 Z", "url(#acier)") + \
    forme("M28 88 Q64 110 100 88 Q94 80 88 80 L82 66 L76 82 L52 82 L46 66 L40 80 Q34 80 28 88 Z", "url(#acier)") + reflet("M34 40 Q64 26 94 40")
T["croc"] = forme("M50 14 Q86 30 78 74 Q72 100 56 116 Q60 88 52 64 Q44 40 50 14 Z", "url(#acier)") + reflet("M58 28 Q72 44 68 66") + \
    forme("M96 20 L100 32 L112 36 L100 40 L96 52 L92 40 L80 36 L92 32 Z", "url(#or)", 4)
T["hurlement"] = forme("M70 18 A44 44 0 1 0 112 76 A34 34 0 1 1 70 18 Z", "url(#or)") + \
    trait("M18 44 Q8 64 18 84", "url(#givre)", 6) + trait("M32 52 Q26 64 32 76", "url(#givre)", 6)
T["curee"] = forme("M64 14 Q92 56 92 78 A28 28 0 0 1 36 78 Q36 56 64 14 Z", "url(#rouge)") + reflet("M52 70 Q50 82 58 90") + \
    trait("M14 30 L40 56", "url(#acier)", 5) + trait("M96 18 L118 48", "url(#acier)", 5)
T["fenrir"] = forme("M20 24 L44 42 L64 34 L84 42 L108 24 L100 62 Q100 92 64 112 Q28 92 28 62 Z", "url(#nuit)") + \
    forme("M44 62 L58 68 L46 72 Z", "url(#rouge)", 3) + forme("M84 62 L70 68 L82 72 Z", "url(#rouge)", 3) + \
    forme("M54 90 L64 98 L74 90 Z", "#1A120A", 2)
# ---- Chêne ----
T["ecorce"] = forme("M64 12 L104 26 Q106 78 64 116 Q22 78 24 26 Z", "url(#bois)") + \
    trait("M48 34 Q44 62 52 90 M64 30 V100 M80 34 Q84 62 76 90", "#5A3418", 4) + reflet("M34 32 L62 22")
T["seve"] = forme("M20 100 Q22 34 104 22 Q100 94 38 100 Z", "url(#vert)") + trait("M26 96 Q60 64 96 30", "#2E6A2C", 4) + \
    forme("M94 70 Q106 88 104 98 A10 10 0 0 1 84 98 Q84 88 94 70 Z", "url(#or)", 4)
T["racines"] = forme("M50 14 H78 V58 Q100 72 116 100 Q94 88 82 78 Q86 98 96 114 Q76 104 68 80 Q62 104 44 114 Q50 96 52 78 Q38 90 14 100 Q30 72 50 58 Z", "url(#bois)") + \
    reflet("M58 20 V54")
T["repos"] = forme("M64 14 Q92 44 86 70 Q84 86 64 92 Q44 86 42 70 Q38 50 54 36 Q56 52 64 56 Q60 34 64 14 Z", "url(#or)") + \
    trait("M24 108 L104 92 M24 92 L104 108", "url(#bois)", 9)
T["rempart"] = forme("M26 116 V40 H40 V26 H54 V40 H74 V26 H88 V40 H102 V116 Z", "url(#acier)") + \
    forme("M54 116 V86 A10 10 0 0 1 74 86 V116 Z", "#2A1E12", 4) + reflet("M34 48 V104")
# ---- Corbeau ----
T["vent"] = trait("M14 44 H74 A14 14 0 1 0 60 30", "url(#givre)", 8) + trait("M14 66 H98 A14 14 0 1 1 84 80", "url(#givre)", 8) + \
    trait("M24 88 H58 A10 10 0 1 1 48 100", "url(#givre)", 7)
T["memoire"] = forme("M64 12 A52 52 0 1 1 63.9 12 Z", "url(#nuit)") + \
    trait("M64 30 V98 M64 46 L86 30 M64 64 L42 48 M64 82 L86 66", "url(#or)", 6)
T["odin"] = forme("M10 64 Q64 10 118 64 Q64 118 10 64 Z", "#F6EED8") + forme("M64 44 A20 20 0 1 1 63.9 44 Z", "url(#givre)", 5) + \
    forme("M64 56 A8 8 0 1 1 63.9 56 Z", N, 2) + trait("M18 28 Q64 0 110 28", "url(#or)", 5)
T["huginn"] = forme("M98 12 Q114 48 76 92 L36 116 Q40 98 52 82 Q36 78 30 66 Q66 64 98 12 Z", "url(#nuit)") + \
    trait("M92 24 Q76 64 44 104", "#C8D2EE", 3) + forme("M18 18 A10 10 0 1 1 17.9 18 Z", "url(#or)", 4)
T["muninn"] = forme("M12 84 Q40 28 116 22 Q96 36 98 48 Q82 50 80 60 Q66 62 66 74 Q48 76 46 90 Q28 86 12 84 Z", "url(#nuit)") + \
    trait("M26 82 Q54 52 104 30", "#C8D2EE", 3) + trait("M30 106 H100", "url(#givre)", 5)

os.makedirs(os.path.join(RACINE, "icones_talents"), exist_ok=True)
for k, v in T.items():
    open(os.path.join(RACINE, "icones_talents", k + ".svg"), "w").write(svg(v))

# ---- boutons de l'interface ----
B = {}
B["arbre"] = forme("M64 12 Q96 14 100 40 Q116 46 110 66 Q104 82 84 80 L72 80 L72 92 Q86 104 104 110 L24 110 Q42 104 56 92 L56 80 L44 80 Q24 82 18 66 Q12 46 28 40 Q32 14 64 12 Z", "url(#or)") + \
    trait("M64 80 V54 M64 64 L50 50 M64 60 L80 46", "#7A4A22", 4)
B["codex"] = forme("M18 26 Q42 18 62 28 V108 Q42 98 18 106 Z", "#F2E6C8") + forme("M110 26 Q86 18 66 28 V108 Q86 98 110 106 Z", "#F2E6C8") + \
    trait("M28 44 H52 M28 58 H52 M28 72 H48 M76 44 H100 M76 58 H100", "#8A6A40", 4) + \
    forme("M86 64 L92 76 L104 78 L94 86 L98 98 L86 90 L74 98 L78 86 L68 78 L80 76 Z", "url(#or)", 3)
B["point"] = forme("M64 10 L78 50 L118 52 L86 76 L98 116 L64 92 L30 116 L42 76 L10 52 L50 50 Z", "url(#or)")
for k, v in B.items():
    open(os.path.join(RACINE, "icones_sorts", k + ".svg"), "w").write(svg(v))

# ---- reliques : une forme par effet, la gemme prend la couleur de la rareté ----
RAR = {"commun": ("#E6FFE0", "#5DBB63", "#2B6E30"), "rare": ("#E0EEFF", "#3D8BFF", "#1A4BA0"),
       "epique": ("#F3E6FF", "#A45CFF", "#5A2399"), "legendaire": ("#FFF1D6", "#FF9A2E", "#A6540E"),
       "mythique": ("#FFE0E0", "#E5383B", "#7E1018")}
def gemme(r):
    a, b, c = RAR[r]
    return f'<radialGradient id="g" cx="0.38" cy="0.32" r="0.75"><stop offset="0" stop-color="{a}"/><stop offset="0.45" stop-color="{b}"/><stop offset="1" stop-color="{c}"/></radialGradient>'
CHAINE = trait("M30 10 Q64 40 98 10", "url(#or)", 4)
R = {
    # puissance des sorts : pendentif en pointe, éclair gravé
    "sorts": CHAINE + forme("M64 26 L96 54 L64 120 L32 54 Z", "url(#or)") + forme("M64 40 L84 58 L64 102 L44 58 Z", "url(#g)", 4) +
             trait("M68 52 L58 70 L70 70 L60 90", "#FFF8E2", 3),
    # endurance : médaillon rond, feuille de chêne
    "endurance": CHAINE + forme("M64 28 A42 42 0 1 1 63.9 28 Z", "url(#or)") + forme("M64 42 A28 28 0 1 1 63.9 42 Z", "url(#g)", 4) +
             reflet("M50 58 Q54 50 62 48", 4),
    # énergie : larme
    "energie": CHAINE + forme("M64 24 Q100 72 96 90 A32 32 0 0 1 32 90 Q28 72 64 24 Z", "url(#or)") +
             forme("M64 44 Q86 76 84 88 A20 20 0 0 1 44 88 Q42 76 64 44 Z", "url(#g)", 4) + reflet("M54 80 Q52 90 58 96", 4),
    # recharge : sablier
    "recharge": CHAINE + forme("M34 28 H94 V36 Q94 60 72 72 Q94 84 94 108 V116 H34 V108 Q34 84 56 72 Q34 60 34 36 Z", "url(#or)") +
             forme("M46 40 H82 Q80 58 64 68 Q48 58 46 40 Z", "url(#g)", 3) + forme("M50 106 Q54 90 64 84 Q74 90 78 106 Z", "url(#g)", 3),
}
os.makedirs(os.path.join(RACINE, "icones_reliques"), exist_ok=True)
for s, corps in R.items():
    for r in RAR:
        txt = svg(corps).replace("</defs>", gemme(r) + "</defs>")
        open(os.path.join(RACINE, "icones_reliques", f"{s}_{r}.svg"), "w").write(txt)
print(len(T), "talents,", len(B), "boutons,", len(R) * len(RAR), "reliques")

# ---- voies draconiques : compétences, emblèmes, fragments, œuf runique ----
FEU = '<linearGradient id="feu" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#8E1520"/><stop offset="0.45" stop-color="#FF7A2E"/><stop offset="1" stop-color="#FFE9A0"/></linearGradient>'
ECAILLE = '<linearGradient id="ecaille" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#C8FFE6"/><stop offset="0.5" stop-color="#4FC898"/><stop offset="1" stop-color="#1E6A54"/></linearGradient>'
CIEL = '<linearGradient id="ciel" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F2FAFF"/><stop offset="0.5" stop-color="#8FCBFF"/><stop offset="1" stop-color="#3A7BC8"/></linearGradient>'
RUNE = '<radialGradient id="rune" cx="0.5" cy="0.45" r="0.6"><stop offset="0" stop-color="#F8E8FF"/><stop offset="0.5" stop-color="#B07CFF"/><stop offset="1" stop-color="#4A1E8A"/></radialGradient>'
def svg2(corps):
    return svg(corps).replace("</defs>", FEU + ECAILLE + CIEL + RUNE + "</defs>")
D = {}
D["souffle"] = forme("M18 64 Q50 30 112 20 Q96 44 116 60 Q94 66 112 92 Q60 88 18 64 Z", "url(#feu)") + \
    forme("M10 56 Q4 64 10 72 L24 64 Z", "url(#or)", 4) + reflet("M40 58 Q70 42 100 34", 4)
D["carapace"] = forme("M64 12 L104 30 L104 72 Q100 100 64 118 Q28 100 24 72 L24 30 Z", "url(#ecaille)") + \
    trait("M64 12 V118 M24 50 Q64 70 104 50 M30 84 Q64 102 98 84", "#1E5A48", 4) + reflet("M34 34 L58 22")
D["envol"] = forme("M64 70 Q40 30 8 24 Q26 44 22 56 Q8 56 12 70 Q30 64 40 76 Q30 86 36 96 Q52 84 64 92 Q76 84 92 96 Q98 86 88 76 Q98 64 116 70 Q120 56 106 56 Q102 44 120 24 Q88 30 64 70 Z", "url(#ciel)") + \
    forme("M54 104 Q64 92 74 104 Q70 116 64 120 Q58 116 54 104 Z", "url(#feu)", 4)
D["classe_souffle"] = forme("M64 8 Q100 40 96 76 Q92 108 64 120 Q36 108 32 76 Q28 40 64 8 Z", "url(#feu)") + \
    forme("M64 44 Q80 64 76 82 Q72 96 64 100 Q56 96 52 82 Q48 64 64 44 Z", "url(#or)", 4)
D["classe_ecailles"] = forme("M64 10 L110 34 L110 78 Q104 106 64 120 Q24 106 18 78 L18 34 Z", "url(#ecaille)") + \
    forme("M44 50 Q64 40 84 50 Q80 66 64 70 Q48 66 44 50 Z", "url(#or)", 4) + forme("M44 76 Q64 66 84 76 Q80 92 64 96 Q48 92 44 76 Z", "url(#or)", 4)
D["classe_ailes"] = D["envol"].replace("url(#feu)", "url(#or)")
D["fragment"] = forme("M50 10 L96 28 L110 74 L72 118 L26 96 L18 44 Z", "url(#nuit)") + \
    trait("M64 30 V94 M64 46 L82 34 M64 62 L46 50 M64 78 L82 66", "url(#rune)", 6)
D["oeuf_runique"] = forme("M64 8 Q104 40 104 78 A40 40 0 0 1 24 78 Q24 40 64 8 Z", "url(#rune)") + \
    trait("M64 34 V96 M64 50 L80 40 M64 66 L48 56 M64 82 L80 72", "url(#or)", 5) + reflet("M42 46 Q48 30 60 22", 5)
for k, v in D.items():
    open(os.path.join(RACINE, "icones_sorts", k + ".svg"), "w").write(svg2(v))
print(len(D), "icônes draconiques")
