shader_type spatial;
// Œuf de dragon (modèle à écailles en relief) recoloré selon la rareté. La même matière sert à la
// coque (sombre) et aux plaques d'écailles (vives) ; liseré lumineux pour le lire dans le noir,
// fissures lumineuses qui gagnent l'œuf pendant l'éclosion.

uniform vec3 couleur : source_color = vec3(0.3, 0.8, 0.4);
uniform vec3 veine : source_color = vec3(0.6, 1.0, 0.7);
uniform float sombre = 0.0;          // 1 = coque (entre les écailles)
uniform float eclat = 1.0;
uniform float fissure = 0.0;         // 0 intact … 1 sur le point d'éclore

varying vec3 pl;

float h(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float bruit(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h(i), h(i + vec3(1,0,0)), u.x), mix(h(i + vec3(0,1,0)), h(i + vec3(1,1,0)), u.x), u.y),
	           mix(mix(h(i + vec3(0,0,1)), h(i + vec3(1,0,1)), u.x), mix(h(i + vec3(0,1,1)), h(i + vec3(1,1,1)), u.x), u.y), u.z);
}

void vertex() { pl = VERTEX; }

void fragment() {
	vec3 c = mix(couleur * 1.05, couleur * 0.22, sombre);
	ALBEDO = c;
	ROUGHNESS = mix(0.28, 0.5, sombre);
	SPECULAR = 0.75;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	float pouls = 0.75 + 0.25 * sin(TIME * 2.2);
	// fissures : lignes de bruit qui descendent du sommet à mesure que `fissure` monte
	float n = bruit(pl * 6.0) * 0.6 + bruit(pl * 13.0) * 0.4;
	float ligne = smoothstep(0.035, 0.0, abs(n - 0.5));
	float haut = smoothstep(1.6 - fissure * 1.9, 1.7 - fissure * 1.9, pl.y);
	float fi = ligne * haut * step(0.01, fissure);
	EMISSION = veine * (rim * 0.45 * pouls * (1.0 - sombre * 0.6)) * eclat + veine * fi * 4.0;
}
