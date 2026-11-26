shader_type spatial;
// Procedural skins for guns and uniforms (no textures needed, works on the mobile
// compatibility renderer). pattern: 0 solid, 1 woodland camo, 2 digital, 3 tiger,
// 4 damascus, 5 carbon, 6 neon lines (animated), 7 fade (two-colour gradient).
// space: 0 = object position (guns: pattern stays put on the model), 1 = UV (skinned uniforms).

uniform int pattern = 0;
uniform int space = 0;
uniform float scale = 6.0;          // pattern repeats over the object
uniform vec3 obj_size = vec3(1.0);   // model AABB size (object space) -> normalised coords
uniform vec4 c1 : source_color = vec4(0.40, 0.50, 0.30, 1.0);
uniform vec4 c2 : source_color = vec4(0.25, 0.30, 0.18, 1.0);
uniform vec4 c3 : source_color = vec4(0.55, 0.50, 0.35, 1.0);
uniform vec4 c4 : source_color = vec4(0.12, 0.12, 0.10, 1.0);
uniform float metal = 0.2;
uniform float rough = 0.6;
uniform vec4 glow : source_color = vec4(0.1, 0.9, 1.0, 1.0);

varying vec3 p;

float hash(vec3 q) { return fract(sin(dot(q, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float noise(vec3 x) {
	vec3 i = floor(x); vec3 f = fract(x); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
	           mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}
float fbm(vec3 x) { float a = 0.5, s = 0.0; for (int k = 0; k < 4; k++) { s += a * noise(x); x *= 2.03; a *= 0.5; } return s; }

void vertex() {
	if (space == 1) p = vec3(UV * vec2(1.0, 1.0), 0.0) * scale;
	else p = VERTEX / max(max(obj_size.x, obj_size.y), max(obj_size.z, 0.0001)) * scale;
}

void fragment() {
	vec3 col = c1.rgb; float m = metal; float r = rough; vec3 em = vec3(0.0);
	if (pattern == 1) {                       // woodland: layered blobs
		float n = fbm(p * 1.3);
		col = n < 0.40 ? c2.rgb : (n < 0.52 ? c1.rgb : (n < 0.62 ? c3.rgb : c4.rgb));
	} else if (pattern == 2) {                // digital: blocky
		float n = fbm(floor(p * 4.0) / 4.0 * 1.4);
		col = n < 0.42 ? c2.rgb : (n < 0.55 ? c1.rgb : (n < 0.65 ? c3.rgb : c4.rgb));
	} else if (pattern == 3) {                // tiger stripes
		float s = sin(p.x * 3.0 + fbm(p * 1.5) * 5.0 + p.y * 1.2);
		col = s > 0.55 ? c2.rgb : c1.rgb;
	} else if (pattern == 4) {                // damascus ripples (folded steel)
		float s = sin((p.x + p.y * 0.6 + p.z * 0.3) * 5.0 + fbm(p * 1.2) * 9.0);
		col = mix(c1.rgb, c2.rgb, smoothstep(-0.25, 0.25, s));
		m = 0.85; r = 0.28;
	} else if (pattern == 5) {                // carbon weave
		vec3 q = p * 9.0;
		float w = mod(floor(q.x) + floor(q.y) + floor(q.z), 2.0);
		float g = abs(fract((w > 0.5 ? q.x : q.y)) - 0.5);
		col = mix(c1.rgb, c2.rgb, smoothstep(0.1, 0.45, g));
		m = 0.3; r = 0.35;
	} else if (pattern == 6) {                // neon lines running along the gun
		col = c1.rgb;
		float band = fract(p.x * 1.5 - TIME * 0.6);
		float line = smoothstep(0.0, 0.04, band) * (1.0 - smoothstep(0.06, 0.10, band));
		float edge = step(0.92, fract(p.y * 4.0 + fbm(p) * 0.5));
		em = glow.rgb * (line * 2.5 + edge * 0.8);
		m = 0.5; r = 0.3;
	} else if (pattern == 7) {                // fade
		col = mix(c1.rgb, c2.rgb, smoothstep(-0.4, 0.6, p.x / scale + p.y / scale));
		m = 0.6; r = 0.3;
	}
	ALBEDO = col; METALLIC = m; ROUGHNESS = r; EMISSION = em;
}
