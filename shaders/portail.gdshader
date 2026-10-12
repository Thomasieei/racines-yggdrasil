shader_type spatial;
// Voile du Portail d'Yggdrasil : tourbillon bleu glacé qui aspire vers le centre, cœur doré, anneau de runes.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 bleu : source_color = vec3(0.35, 0.75, 1.0);
uniform vec3 or_coeur : source_color = vec3(1.0, 0.8, 0.45);
uniform float intensite = 1.0;

float h(vec2 p) { return fract(sin(dot(p, vec2(41.3, 289.1))) * 45758.5453); }
float bruit(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), u.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), u.x), u.y);
}

void fragment() {
	// ellipse haute : forme d'une arche
	vec2 p = (UV - vec2(0.5, 0.55)) * vec2(2.0, 2.0 * 1.25);
	float r = length(p);
	float bord = 1.0 - smoothstep(0.86, 1.0, r);
	float a = atan(p.y, p.x);
	float t = TIME;
	// spirale : l'angle tourne plus vite près du centre
	float spir = a + 3.5 / (r + 0.25) - t * 1.6;
	float bandes = bruit(vec2(spir * 2.2, r * 5.0 - t * 1.4));
	bandes = pow(bandes, 1.6);
	float profondeur = smoothstep(1.0, 0.0, r);
	vec3 c = bleu * (0.25 + bandes * 1.4) * (0.4 + profondeur);
	c += or_coeur * pow(profondeur, 4.0) * 1.8;
	// anneau de runes au bord : tirets qui défilent
	float anneau = smoothstep(0.08, 0.0, abs(r - 0.82));
	float runes = step(0.55, fract((a / 6.2831) * 24.0 + t * 0.05)) * step(0.3, h(vec2(floor((a / 6.2831) * 24.0 + t * 0.05), 3.0)));
	c += or_coeur * anneau * (0.35 + runes * 1.2);
	ALBEDO = c * bord * intensite;
	ALPHA = 1.0;
}
