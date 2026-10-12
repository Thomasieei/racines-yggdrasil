shader_type spatial;
// Sol de la surface, peint à la main en code : herbe nuancée, chemin de terre aux bords irréguliers,
// place pavée du Bourg, cercle sacré du sanctuaire. Tout en coordonnées monde : aucun motif répété visible.
render_mode diffuse_lambert, specular_disabled;

uniform vec2 chemin[24];
uniform int nb_points = 0;
uniform float largeur_chemin = 2.6;
uniform vec4 place = vec4(127.0, 37.0, 17.0, 0.0);       // xz centre, rayon
uniform vec4 sanctuaire = vec4(36.0, 108.0, 8.5, 0.0);
uniform vec4 parvis_portail = vec4(127.0, -2.0, 11.0, 0.0);
uniform vec4 bourg = vec4(104.0, 16.0, 150.0, 58.0);      // rectangle xmin zmin xmax zmax

uniform vec3 herbe_a : source_color = vec3(0.27, 0.40, 0.19);
uniform vec3 herbe_b : source_color = vec3(0.38, 0.49, 0.22);
uniform vec3 herbe_sombre : source_color = vec3(0.16, 0.27, 0.13);
uniform vec3 terre : source_color = vec3(0.50, 0.38, 0.25);
uniform vec3 terre_sombre : source_color = vec3(0.36, 0.27, 0.18);
uniform vec3 pave : source_color = vec3(0.56, 0.52, 0.47);
uniform vec3 or_sacre : source_color = vec3(1.0, 0.78, 0.35);

varying vec3 pm;

float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float bruit(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), u.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * bruit(p); p *= 2.03; a *= 0.5; }
	return v;
}
float dist_segment(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a; vec2 ba = b - a;
	float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * t);
}
// pavés : cellules de Voronoï, le joint est là où deux pierres se touchent (F2 - F1 petit)
vec2 paves(vec2 p) {
	vec2 g = p * 0.85;
	vec2 i = floor(g); vec2 f = fract(g);
	float d1 = 8.0; float d2 = 8.0; vec2 id = vec2(0.0);
	for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
		vec2 o = vec2(float(x), float(y));
		vec2 c = o + vec2(h(i + o), h(i + o + 7.3)) * 0.75 + 0.125;
		float d = length(f - c);
		if (d < d1) { d2 = d1; d1 = d; id = i + o; } else if (d < d2) { d2 = d; }
	}
	return vec2(d2 - d1, h(id));
}

void vertex() { pm = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }

void fragment() {
	vec2 p = pm.xz;
	// herbe : grandes taches + grain fin
	float n1 = fbm(p * 0.045);
	float n2 = fbm(p * 0.35 + 3.0);
	vec3 c = mix(herbe_a, herbe_b, smoothstep(0.35, 0.7, n1));
	c = mix(c, herbe_sombre, smoothstep(0.55, 0.8, fbm(p * 0.09 + 11.0)) * 0.55);
	c *= 0.88 + n2 * 0.24;

	// chemin
	float d = 1e5;
	for (int i = 0; i < 23; i++) {
		if (i + 1 >= nb_points) break;
		d = min(d, dist_segment(p, chemin[i], chemin[i + 1]));
	}
	float bord = largeur_chemin + (fbm(p * 0.6) - 0.5) * 1.6;
	float m_chemin = 1.0 - smoothstep(bord - 0.5, bord + 0.4, d);
	vec3 c_terre = mix(terre, terre_sombre, fbm(p * 0.8 + 5.0));
	c_terre *= 0.9 + 0.2 * bruit(p * 3.0);
	// ornières : deux traces un peu plus sombres
	c_terre *= 1.0 - 0.12 * (1.0 - smoothstep(0.15, 0.5, abs(d - 0.9)));
	c = mix(c, c_terre, m_chemin);

	// sol du Bourg : terre battue, puis pavés autour de la place
	float dans_bourg = step(bourg.x, p.x) * step(p.x, bourg.z) * step(bourg.y, p.y) * step(p.y, bourg.w);
	float bourg_doux = smoothstep(0.0, 4.0, min(min(p.x - bourg.x, bourg.z - p.x), min(p.y - bourg.y, bourg.w - p.y)));
	c = mix(c, mix(c_terre, herbe_a * 0.9, fbm(p * 0.2) * 0.35), dans_bourg * bourg_doux * 0.75);
	float dp = length(p - place.xy);
	float m_place = 1.0 - smoothstep(place.z - 1.5, place.z + 0.5 + (bruit(p * 0.5) - 0.5) * 2.0, dp);
	vec2 pv = paves(p);
	float joint = smoothstep(0.03, 0.11, pv.x);
	vec3 c_pave = pave * (0.8 + 0.28 * pv.y) * (0.92 + 0.12 * bruit(p * 2.0));
	c_pave = mix(c_terre * 0.7, c_pave, joint);
	c = mix(c, c_pave, m_place);

	// parvis du portail : dalles plus sombres, comme usées par des milliers de pas
	float dpo = length(p - parvis_portail.xy);
	float m_po = 1.0 - smoothstep(parvis_portail.z - 1.0, parvis_portail.z + 1.0, dpo);
	c = mix(c, c_pave * vec3(0.7, 0.75, 0.85), m_po);

	// sanctuaire : cercle de mousse claire et anneau doré gravé
	float ds = length(p - sanctuaire.xy);
	float m_s = 1.0 - smoothstep(sanctuaire.z - 1.0, sanctuaire.z + 1.5, ds);
	c = mix(c, herbe_b * 1.15, m_s * 0.6);
	float anneau = 1.0 - smoothstep(0.08, 0.28, abs(ds - sanctuaire.z * 0.55));
	c = mix(c, or_sacre, anneau * 0.65);
	EMISSION = or_sacre * anneau * 0.35;

	ALBEDO = c;
	ROUGHNESS = 0.95;
}
