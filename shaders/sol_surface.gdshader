shader_type spatial;
// Sol de la surface, peint en code d'après un masque (1 px = 1 m) : herbe nuancée, terre battue des routes,
// pavés des villes, champs labourés, fond du lac. Les bords sont déformés par du bruit : rien de carré.
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D masque : filter_linear, repeat_disable;
uniform vec4 monde = vec4(-250.0, -235.0, 450.0, 365.0);   // x, z, largeur, profondeur
uniform vec4 sanctuaire = vec4(36.0, 108.0, 8.5, 0.0);

uniform vec3 herbe_a : source_color = vec3(0.27, 0.40, 0.19);
uniform vec3 herbe_b : source_color = vec3(0.38, 0.49, 0.22);
uniform vec3 herbe_sombre : source_color = vec3(0.16, 0.27, 0.13);
uniform vec3 terre : source_color = vec3(0.50, 0.38, 0.25);
uniform vec3 terre_sombre : source_color = vec3(0.36, 0.27, 0.18);
uniform vec3 pave : source_color = vec3(0.56, 0.52, 0.47);
uniform vec3 ble : source_color = vec3(0.78, 0.66, 0.32);
uniform vec3 fond_lac : source_color = vec3(0.18, 0.2, 0.17);
uniform vec3 sable : source_color = vec3(0.66, 0.6, 0.45);
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

	// masque lu avec un léger tremblé : bords organiques
	vec2 tremble = vec2(fbm(p * 0.5) - 0.5, fbm(p * 0.5 + 17.0) - 0.5) * 1.6;
	vec4 m = texture(masque, (p + tremble - monde.xy) / monde.zw);

	// terre battue
	vec3 c_terre = mix(terre, terre_sombre, fbm(p * 0.8 + 5.0));
	c_terre *= 0.9 + 0.2 * bruit(p * 3.0);
	float m_terre = smoothstep(0.25, 0.6, m.r);
	c = mix(c, c_terre, m_terre);

	// champs : sillons alignés, blé doré ou terre retournée selon la parcelle
	float parcelle = step(0.5, h(floor(p / vec2(9.0, 7.0))));
	float sillon = 0.5 + 0.5 * sin(p.x * 3.4 + fbm(p * 0.3) * 2.0);
	vec3 c_champ = mix(terre_sombre * 1.1, mix(ble * 0.8, ble, n2), parcelle);
	c_champ *= 0.78 + 0.3 * sillon;
	c = mix(c, c_champ, smoothstep(0.3, 0.7, m.b));

	// pavés des villes
	vec2 pv = paves(p);
	float joint = smoothstep(0.03, 0.11, pv.x);
	vec3 c_pave = pave * (0.8 + 0.28 * pv.y) * (0.92 + 0.12 * bruit(p * 2.0));
	c_pave = mix(c_terre * 0.7, c_pave, joint);
	c = mix(c, c_pave, smoothstep(0.3, 0.65, m.g));

	// berges et fond du lac (l'eau elle-même est un plan au-dessus)
	c = mix(c, sable * (0.9 + 0.15 * bruit(p * 2.5)), smoothstep(0.0, 0.25, m.a) * (1.0 - smoothstep(0.35, 0.7, m.a)));
	c = mix(c, fond_lac, smoothstep(0.35, 0.9, m.a));

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
