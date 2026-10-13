shader_type spatial;
// Œuf de dragon : écailles en losanges, plus sombres entre elles, veines lumineuses de la couleur
// de la rareté qui pulsent doucement, liseré clair sur les bords (on le distingue dans le noir).

uniform vec3 couleur : source_color = vec3(0.3, 0.8, 0.4);
uniform vec3 veine : source_color = vec3(0.6, 1.0, 0.7);
uniform float eclat = 1.0;
uniform float fissure = 0.0;            // 0 intact … 1 sur le point d'éclore

varying vec3 pl;

float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float bruit(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), u.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), u.x), u.y);
}

void vertex() { pl = VERTEX; }

void fragment() {
	// coordonnées cylindriques : écailles qui s'enroulent autour de l'œuf
	float a = atan(pl.x, pl.z) / 6.2831 + 0.5;
	vec2 g = vec2(a * 14.0, pl.y * 9.0);
	g.x += floor(g.y) * 0.5;                     // rangées décalées
	vec2 f = fract(g) - 0.5;
	float ecaille = abs(f.x) + abs(f.y);         // losange
	float bord = smoothstep(0.32, 0.5, ecaille);
	vec3 c = mix(couleur * 1.1, couleur * 0.35, bord);
	c *= 0.85 + 0.3 * h(floor(g));
	// veines : fines lignes lumineuses entre certaines écailles
	float v = smoothstep(0.46, 0.5, ecaille) * step(0.55, bruit(floor(g) * 0.7));
	float pouls = 0.6 + 0.4 * sin(TIME * 2.2);
	// fissures d'éclosion : réseau qui s'étend du sommet
	float fi = step(1.0 - fissure, bruit(vec2(a * 30.0, pl.y * 20.0))) * smoothstep(0.02, 0.0, abs(fract(a * 8.0 + pl.y * 3.0) - 0.5) - 0.48);
	ALBEDO = c;
	ROUGHNESS = 0.35;
	SPECULAR = 0.7;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = veine * (v * pouls * 1.6 + rim * 0.5) * eclat + veine * fi * 3.0;
}
