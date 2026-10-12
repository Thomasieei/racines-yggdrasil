shader_type spatial;
// Onde lumineuse au sol (apparition et éclatement de la bulle, impacts lourds).
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, fog_disabled;

uniform vec3 couleur : source_color = vec3(1.0, 0.8, 0.4);
uniform float rayon : hint_range(0.0, 1.0) = 0.5;   // position de l'anneau (fraction du plan)
uniform float epaisseur = 0.06;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform float runes = 1.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float anneau = exp(-pow((d - rayon) / epaisseur, 2.0));
	float interieur = smoothstep(rayon, 0.0, d) * 0.18;
	// petites encoches régulières, comme des runes gravées dans l'anneau
	float ang = atan(p.y, p.x);
	float encoches = 0.65 + 0.35 * step(0.5, fract(ang * 24.0 / 6.2831853));
	float a = (anneau * encoches * runes + anneau * (1.0 - runes) + interieur) * alpha;
	ALBEDO = couleur * a;
}
