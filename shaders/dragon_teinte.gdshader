shader_type spatial;
// Dragon Evolved (Quaternius) recoloré selon la rareté : on garde la lumière et les ombres de
// l'atlas d'origine, on remplace la teinte. Peau -> couleur principale, membranes -> secondaire,
// cornes et dents (couleurs peu saturées) inchangées.

uniform sampler2D atlas : source_color, filter_nearest;
uniform vec3 peau : source_color = vec3(0.3, 0.7, 0.4);
uniform vec3 membrane : source_color = vec3(0.6, 1.0, 0.7);
uniform float lueur = 0.0;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}

void fragment() {
	vec3 o = texture(atlas, UV).rgb;
	vec3 hsv = rgb2hsv(o);
	vec3 c = o;
	if (hsv.y > 0.25) {
		bool mem = abs(hsv.x - 0.75) < 0.13;
		vec3 cible = mem ? membrane : peau;
		float lum = hsv.z / 0.85;
		c = cible * lum;
	}
	ALBEDO = c;
	ROUGHNESS = 0.6;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = membrane * rim * 0.35 * lueur;
}
