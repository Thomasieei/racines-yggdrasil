shader_type spatial;
// Zone d'attaque au sol : bord net + remplissage qui avance jusqu'à l'impact.
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, shadows_disabled, fog_disabled;

uniform int forme = 0;                 // 0 cercle, 1 cône, 2 ligne
uniform vec3 couleur : source_color = vec3(1.0, 0.18, 0.12);
uniform float progression : hint_range(0.0, 1.0) = 0.0;
uniform float demi_angle = 0.8;        // cône, radians
uniform float opacite = 1.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;           // cercle / cône : centre au milieu
	float a = 0.0;
	if (forme == 2) {
		// ligne : UV.y = 0 à l'origine, 1 au bout
		float bord_x = 1.0 - smoothstep(0.80, 0.98, abs(p.x));
		float bords = smoothstep(0.84, 0.97, abs(p.x)) + smoothstep(0.985, 1.0, UV.y) * 0.0;
		float rempli = step(1.0 - UV.y, progression);
		float fond = 0.16;
		a = (fond + rempli * 0.34) * bord_x + bords * 0.9;
	} else {
		float d = length(p);
		if (d > 1.0) discard;
		float masque = 1.0;
		if (forme == 1) {
			float ang = atan(p.x, -p.y);
			if (abs(ang) > demi_angle) discard;
			float cote = smoothstep(demi_angle - 0.06, demi_angle, abs(ang));
			masque = 1.0;
			a += cote * 0.9;
		}
		float bord = smoothstep(0.93, 0.985, d);
		float rempli = step(d, progression);
		float front = smoothstep(progression - 0.04, progression, d) * step(d, progression) * 0.6;
		a += 0.16 + rempli * 0.30 + bord * 0.9 + front;
		a *= masque;
	}
	ALBEDO = couleur;
	ALPHA = clamp(a, 0.0, 1.0) * opacite;
}
