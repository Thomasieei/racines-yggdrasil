shader_type spatial;
// Lac des Noyés : eau noire presque immobile, rides lentes, reflets turquoise des cristaux de la rive.
render_mode unshaded, blend_mix, depth_draw_opaque, cull_disabled, shadows_disabled, fog_disabled;

float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float bruit(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), u.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), u.x), u.y);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) discard;
	vec2 q = UV * 14.0;
	float t = TIME * 0.25;
	float rides = bruit(q + vec2(t, t * 0.6)) * bruit(q * 1.7 - vec2(t * 0.8, -t * 0.3));
	vec3 c = vec3(0.01, 0.025, 0.035);
	c += vec3(0.15, 0.55, 0.55) * smoothstep(0.35, 0.6, rides) * 0.22;
	c += vec3(0.2, 0.6, 0.6) * smoothstep(0.85, 1.0, r) * 0.25;       // berge mouillée
	ALBEDO = c;
}
