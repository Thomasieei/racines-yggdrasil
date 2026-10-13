shader_type spatial;
// Sol de la caverne : roche sombre et inégale, flaques qui renvoient la lumière des cristaux et des braseros,
// fissures, éboulis fins. Tout en coordonnées monde.
render_mode diffuse_lambert;

uniform vec3 roche_a : source_color = vec3(0.21, 0.2, 0.2);
uniform vec3 roche_b : source_color = vec3(0.31, 0.28, 0.26);
uniform vec3 terre : source_color = vec3(0.26, 0.21, 0.17);
uniform vec2 gouffre_centre = vec2(2.0, -58.0);
uniform vec2 gouffre_rayons = vec2(10.0, 7.0);

varying vec3 pm;

float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float bruit(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), u.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * bruit(p); p *= 2.07; a *= 0.5; }
	return v;
}
// fissures : bords de cellules de Voronoï
float fissures(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	float d1 = 8.0; float d2 = 8.0;
	for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
		vec2 o = vec2(float(x), float(y));
		vec2 c = o + vec2(h(i + o), h(i + o + 3.1));
		float d = length(f - c);
		if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
	}
	return d2 - d1;
}

void vertex() { pm = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }

void fragment() {
	vec2 p = pm.xz;
	float n = fbm(p * 0.08);
	vec3 c = mix(roche_a, roche_b, smoothstep(0.3, 0.75, n));
	c = mix(c, terre, smoothstep(0.55, 0.8, fbm(p * 0.05 + 9.0)) * 0.7);
	c *= 0.82 + 0.3 * bruit(p * 2.2);
	// grandes dalles naturelles fissurées
	float fi = 1.0 - smoothstep(0.0, 0.04, fissures(p * 0.42));
	c *= 1.0 - fi * 0.45 * smoothstep(0.35, 0.6, bruit(p * 0.15));
	// flaques : sombres, lisses, elles accrochent les reflets
	float flaque = smoothstep(0.66, 0.72, fbm(p * 0.07 + 31.0));
	c = mix(c, vec3(0.05, 0.06, 0.08), flaque * 0.8);
	// abords du gouffre : la roche noircit et bleuit en descendant vers le vide
	vec2 g = (p - gouffre_centre) / gouffre_rayons;
	float dg = length(g);
	float bord = 1.0 - smoothstep(0.85, 1.6, dg);
	c = mix(c, vec3(0.03, 0.05, 0.09), bord * 0.7);
	ALBEDO = c;
	ROUGHNESS = mix(0.92, 0.12, flaque);
	SPECULAR = mix(0.3, 0.8, flaque);
}
