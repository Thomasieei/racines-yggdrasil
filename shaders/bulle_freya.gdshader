shader_type spatial;
// Bulle de Freya : reflets de bord, motif de runes hexagonales, ondes d'impact, fissures d'usure.
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, fog_disabled;

uniform vec3 couleur_bord : source_color = vec3(1.0, 0.82, 0.42);
uniform vec3 couleur_coeur : source_color = vec3(1.0, 0.95, 0.8);
uniform vec3 couleur_fissure : source_color = vec3(1.0, 0.55, 0.2);
uniform float apparition : hint_range(0.0, 1.0) = 1.0;   // 0 = invisible, 1 = pleine
uniform float usure : hint_range(0.0, 1.0) = 0.0;        // 0 = intacte, 1 = sur le point d'éclater
uniform float intensite = 1.0;
// impacts : xyz = direction locale (normalisée), w = temps écoulé depuis l'impact (s), w < 0 = vide
uniform vec4 impact0 = vec4(0.0, 0.0, 1.0, -1.0);
uniform vec4 impact1 = vec4(0.0, 0.0, 1.0, -1.0);
uniform vec4 impact2 = vec4(0.0, 0.0, 1.0, -1.0);
uniform vec4 impact3 = vec4(0.0, 0.0, 1.0, -1.0);

varying vec3 n_local;
varying vec3 p_local;

void vertex() {
	n_local = normalize(NORMAL);
	p_local = VERTEX;
	// légère respiration de la sphère
	VERTEX *= 1.0 + 0.012 * sin(TIME * 3.0);
}

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

// distance aux arêtes d'un pavage de Voronoï 3D (sert aux fissures et aux runes)
vec2 voronoi(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	float d1 = 8.0, d2 = 8.0;
	for (int k = -1; k <= 1; k++)
	for (int j = -1; j <= 1; j++)
	for (int h = -1; h <= 1; h++) {
		vec3 b = vec3(float(h), float(j), float(k));
		vec3 r = b - f + vec3(hash(i + b), hash(i + b + 11.7), hash(i + b + 37.3));
		float d = dot(r, r);
		if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
	}
	return vec2(sqrt(d1), sqrt(d2));
}

float onde(vec4 imp, vec3 n) {
	if (imp.w < 0.0 || imp.w > 0.9) return 0.0;
	float ang = acos(clamp(dot(n, normalize(imp.xyz)), -1.0, 1.0));
	float front = imp.w * 3.6;                       // l'onde se propage sur la sphère
	float anneau = exp(-pow((ang - front) * 9.0, 2.0));
	float eclat = exp(-ang * 6.0) * exp(-imp.w * 9.0); // flash au point d'impact
	return (anneau * 1.2 + eclat * 2.5) * (1.0 - imp.w / 0.9);
}

void fragment() {
	vec3 n = normalize(n_local);
	float fres = pow(1.0 - abs(dot(NORMAL, VIEW)), 2.4);

	// motif de runes : arêtes de cellules qui défilent doucement
	vec2 v = voronoi(n * 4.5 + vec3(0.0, TIME * 0.15, 0.0));
	float arete = 1.0 - smoothstep(0.02, 0.09, v.y - v.x);
	float scintille = 0.55 + 0.45 * sin(TIME * 2.0 + v.x * 12.0);
	float runes = arete * scintille * 0.35;

	// ondes d'impact
	float ondes = onde(impact0, n) + onde(impact1, n) + onde(impact2, n) + onde(impact3, n);

	// fissures : arêtes d'un pavage plus fin qui apparaissent avec l'usure
	vec2 c = voronoi(n * 7.0 + 3.1);
	float largeur = mix(0.0, 0.06, usure);
	float fissure = (1.0 - smoothstep(largeur * 0.4, largeur, c.y - c.x)) * step(0.08, usure);
	fissure *= 0.7 + 0.3 * sin(TIME * 18.0 * usure);

	vec3 col = couleur_bord * (fres * 1.6 + runes) + couleur_coeur * ondes + couleur_fissure * fissure * 1.8;
	float a = (fres * 0.85 + runes * 0.6 + ondes + fissure) * apparition;
	ALBEDO = col * a * intensite;
}
