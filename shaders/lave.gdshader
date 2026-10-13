shader_type spatial;
// Lave des forges : croûte sombre qui se fend sur un cœur orange, pulsation lente.
render_mode unshaded, blend_mix, depth_draw_opaque, cull_disabled, shadows_disabled, fog_disabled;

float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float cellules(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	float d1 = 8.0; float d2 = 8.0;
	for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
		vec2 o = vec2(float(x), float(y));
		vec2 c = o + vec2(h(i + o), h(i + o + 4.1));
		float d = length(f - c);
		if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
	}
	return d2 - d1;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) discard;
	float t = TIME * 0.3;
	float fente = 1.0 - smoothstep(0.02, 0.14, cellules(UV * 5.0 + vec2(t * 0.2, 0.0)));
	float pouls = 0.8 + 0.2 * sin(TIME * 1.7);
	vec3 croute = vec3(0.09, 0.05, 0.04);
	vec3 feu = mix(vec3(1.0, 0.35, 0.05), vec3(1.0, 0.8, 0.3), fente);
	vec3 c = mix(croute, feu * pouls * 1.6, max(fente, smoothstep(0.75, 0.95, r) * 0.0 + (1.0 - r) * 0.25));
	c = mix(c, vec3(0.05, 0.03, 0.03), smoothstep(0.88, 1.0, r));
	ALBEDO = c;
}
