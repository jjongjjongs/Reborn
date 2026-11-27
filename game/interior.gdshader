// Fake interior behind a window quad ("interior mapping"): the ray from the camera is traced
// through a box-shaped room behind the glass, so side walls, floor, ceiling and one piece of
// furniture shift with the viewpoint instead of a flat picture. Every window gets its own room
// (depth, width, lit or dark, curtains / blinds, wall colour) from a hash of its corner.
// The tangent frame comes from screen derivatives, so any window quad with 0..1 UVs works.
shader_type spatial;
render_mode unshaded, cull_back;

uniform sampler2D wall_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D floor_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D back_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float lit_chance = 0.35;      // share of rooms with the lights on
uniform float shop = 0.0;             // 1 = ground floor shop front (always lit, deeper, no curtains)
uniform vec3 sky_tint : source_color = vec3(0.55, 0.60, 0.70);

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float h1(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }

// slab test against an axis-aligned box: entry distance or -1
float box_hit(vec3 ro, vec3 rd, vec3 bmin, vec3 bmax, out vec3 nrm) {
	vec3 inv = 1.0 / rd;
	vec3 t0 = (bmin - ro) * inv; vec3 t1 = (bmax - ro) * inv;
	vec3 tn = min(t0, t1); vec3 tf = max(t0, t1);
	float a = max(max(tn.x, tn.y), tn.z); float b = min(min(tf.x, tf.y), tf.z);
	nrm = vec3(0.0);
	if (b < max(a, 0.0)) return -1.0;
	nrm = (a == tn.x) ? vec3(-sign(rd.x), 0, 0) : ((a == tn.y) ? vec3(0, -sign(rd.y), 0) : vec3(0, 0, -sign(rd.z)));
	return a;
}

void fragment() {
	// tangent frame of the window quad from screen-space derivatives
	vec3 dpx = dFdx(wpos); vec3 dpy = dFdy(wpos);
	vec2 dux = dFdx(UV); vec2 duy = dFdy(UV);
	float det = dux.x * duy.y - dux.y * duy.x;
	if (abs(det) < 1e-12) det = 1e-12;
	vec3 T = (dpx * duy.y - dpy * dux.y) / det;      // world metres per unit u
	vec3 Bv = (dpy * dux.x - dpx * duy.x) / det;     // world metres per unit v
	float Wm = clamp(length(T), 0.3, 6.0);
	float Hm = clamp(length(Bv), 0.3, 6.0);
	vec3 R = normalize(T);
	vec3 U = vec3(0.0, 1.0, 0.0);
	vec3 nw = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 IN = -nw;                                     // into the building
	float vy = (dot(Bv, U) < 0.0) ? 1.0 - UV.y : UV.y; // v measured upward
	vec3 p = vec3(UV.x * Wm, vy * Hm, 0.0);
	// per-window randomness from its bottom-left corner
	vec3 corner = floor((wpos - R * p.x - U * p.y) * 2.0 + 0.5);
	float r1 = h1(corner); float r2 = h1(corner + 7.1); float r3 = h1(corner + 19.7); float r4 = h1(corner + 31.3);
	float lit = (shop > 0.5) ? 1.0 : step(1.0 - lit_chance, r1);
	// ray into room space (x along the wall, y up, z into the building)
	vec3 rdw = normalize(wpos - CAMERA_POSITION_WORLD);
	vec3 rd = vec3(dot(rdw, R), dot(rdw, U), max(dot(rdw, IN), 0.02));
	float depth = mix(2.4, 4.6, r2) + shop * 1.5;
	float side = mix(0.6, 1.6, r3) + shop * 0.6;
	vec3 bmin = vec3(-side, -0.95 + shop * 0.45, 0.0);
	vec3 bmax = vec3(Wm + side, Hm + 0.55, depth);
	vec3 tf = (mix(bmin, bmax, step(0.0, rd)) - p) / rd;
	float t = min(min(tf.x, tf.y), tf.z);
	vec3 hit = p + rd * t;
	vec3 col;
	float shade;
	// painted walls: a palette colour modulated by the texture's light/dark
	vec3 paint = r4 < 0.25 ? vec3(0.93, 0.88, 0.76) : (r4 < 0.5 ? vec3(0.76, 0.86, 0.78) : (r4 < 0.75 ? vec3(0.76, 0.82, 0.92) : vec3(0.92, 0.80, 0.78)));
	if (t == tf.z) {                                   // back wall
		float lum = dot(texture(back_tex, hit.xy * vec2(0.45, 0.45)).rgb, vec3(0.33));
		col = paint * (0.55 + 0.6 * lum);
		// a doorway or a shelf on some back walls
		float dx = fract(r3 * 5.0) * (Wm + side) ;
		if (r4 > 0.5 && hit.x > dx - 0.45 && hit.x < dx + 0.45 && hit.y < bmin.y + 2.05) col *= 0.35;
		shade = 0.85;
	} else if (t == tf.y) {
		if (rd.y < 0.0) { col = texture(floor_tex, hit.xz * 0.5).rgb * vec3(0.85, 0.72, 0.58); shade = 0.75; }
		else {                                         // ceiling + a light panel
			col = vec3(0.82, 0.82, 0.80);
			vec2 c = hit.xz - vec2(Wm * 0.5, depth * 0.5);
			col += lit * 1.6 * vec3(1.0, 0.95, 0.85) * step(abs(c.x), 0.5) * step(abs(c.y), 0.18);
			shade = 0.6;
		}
	} else {                                           // side walls
		float lum = dot(texture(wall_tex, hit.zy * 0.45).rgb, vec3(0.33));
		col = mix(paint * (0.55 + 0.6 * lum), texture(wall_tex, hit.zy * 0.45).rgb, step(0.6, r3));   // some rooms bare brick
		shade = 0.72;
	}
	// shops: shelves of products along the back and side walls
	if (shop > 0.5 && rd.y > -10.0 && t != tf.y) {
		float hy = hit.y - bmin.y;
		float along = (t == tf.z) ? hit.x : hit.z;
		if (hy > 0.25 && hy < 2.1) {
			float row = floor(hy / 0.42); float f = fract(hy / 0.42);
			if (f < 0.12) col = vec3(0.45, 0.42, 0.40);                                   // shelf board
			else if (f < 0.82) {
				float cell = floor(along / 0.16);
				float hc = h1(vec3(cell, row, r1 * 13.0));
				vec3 prod = mix(vec3(0.62), 0.5 + 0.5 * cos(6.2831 * (hc + vec3(0.0, 0.33, 0.67))), 0.55);
				col = mix(col, prod * 0.9, step(0.18, hc) * step(f, 0.42 + 0.4 * fract(hc * 9.1)));
			}
		}
	}
	// one piece of furniture against the back wall (cabinet / sofa / desk)
	vec3 fn;
	float fw = mix(0.8, 1.8, r3); float fh = mix(0.5, 1.6, r4);
	float fx = mix(bmin.x + 0.2, bmax.x - fw - 0.2, fract(r1 * 7.3));
	vec3 fmin = vec3(fx, bmin.y, depth - mix(0.5, 0.9, r2)); vec3 fmax = vec3(fx + fw, bmin.y + fh, depth - 0.02);
	float tb = box_hit(p, rd, fmin, fmax, fn);
	if (tb > 0.0 && tb < t) {
		col = mix(vec3(0.30, 0.22, 0.16), vec3(0.32, 0.36, 0.42), r2) * (0.75 + 0.25 * fn.y + 0.15 * abs(fn.x));
		shade = 0.8; t = tb;
	}
	// light: warm and bright when lit, dim and cool when not; darker further in
	vec3 light = lit > 0.5 ? vec3(1.4, 1.25, 1.02) : vec3(0.42, 0.44, 0.50);
	col *= light * shade * mix(1.0, 0.55, clamp(t / (depth + 2.0), 0.0, 1.0));
	// curtains (left/right) or half-down blinds on some windows
	if (shop < 0.5) {
		float u = UV.x;
		if (r4 < 0.45) {
			float cl = mix(0.12, 0.38, r2); float cr = mix(0.12, 0.38, r3);
			if (u < cl || u > 1.0 - cr) {
				vec3 cc = mix(vec3(0.62, 0.20, 0.18), vec3(0.78, 0.72, 0.58), step(0.5, r1));
				col = cc * (0.75 + 0.25 * sin(u * 70.0)) * (lit > 0.5 ? 1.0 : 0.45);
			}
		} else if (r4 > 0.8) {
			float down = mix(0.25, 0.6, r2);
			if (vy > 1.0 - down) col = vec3(0.80, 0.78, 0.72) * (0.8 + 0.2 * step(0.5, fract(vy * 18.0))) * (lit > 0.5 ? 0.95 : 0.4);
		}
	}
	// glass: a little sky reflection at grazing angles, mullions
	float fres = pow(1.0 - clamp(dot(-rdw, nw), 0.0, 1.0), 3.0);
	col = mix(col, sky_tint, 0.12 + 0.45 * fres);
	float mx = abs(UV.x - 0.5) * Wm; float my = abs(vy - 0.6) * Hm;
	if (shop < 0.5 && (mx < 0.025 || my < 0.025)) col = vec3(0.85, 0.84, 0.80) * 0.7;
	ALBEDO = col;
}
