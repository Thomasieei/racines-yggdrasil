shader_type spatial;
// Le gouffre : un vide qui n'a pas de fond. Noir au centre, brume bleue qui tourne lentement,
// lueur froide qui remonte d'en bas, bord net de roche.
render_mode unshaded, blend_mix, depth_draw_opaque, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 lueur : source_color = vec3(0.25, 0.55, 1.0);

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
	float a = atan(p.y, p.x);
	float t = TIME * 0.12;
	float brume = bruit(vec2(a * 3.0 + t * 4.0, r * 4.0 - t * 2.0)) * bruit(vec2(a * 5.0 - t * 3.0, r * 7.0));
	float profondeur = smoothstep(1.0, 0.15, r);
	vec3 c = mix(vec3(0.05, 0.07, 0.11), vec3(0.0), profondeur);
	c += lueur * (0.06 + brume * 0.35) * (1.0 - profondeur * 0.6);
	c += lueur * pow(1.0 - r, 3.0) * 0.25;                 // lueur lointaine, tout au fond
	float levre = smoothstep(0.9, 1.0, r);
	c = mix(c, vec3(0.08, 0.08, 0.1), levre);
	ALBEDO = c;
	ALPHA = 1.0;
}
