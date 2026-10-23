#version 440
// Opal lock screen core: an obsidian field with a living ring of pearl
// "ink". Compile with scripts/build-shaders.sh (qsb) after editing.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;      // seconds
    float spin;      // accumulated rotation of the ring's pattern (radians)
    float energy;    // typing impulse, 0..1
    float verify;    // 0..1 while the password is being checked
    float fail;      // 0..1, decays after a wrong password
    float success;   // 0..1 while unlocking
    float birth;     // 0..1 as the lock screen appears
    float radius;    // ring radius as a fraction of the shorter screen side
    vec2 resolution;
    vec4 tintA;
    vec4 tintB;
    vec4 tintC;
};

layout(binding = 1) uniform sampler2D backdrop;

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p, int octaves) {
    float v = 0.0;
    float a = 0.5;
    mat2 m = mat2(1.6, 1.2, -1.2, 1.6);
    for (int i = 0; i < 6; i++) {
        if (i >= octaves) break;
        v += a * vnoise(p);
        p = m * p;
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 res = resolution;
    float s = min(res.x, res.y);
    vec2 uv = (qt_TexCoord0 * res - 0.5 * res) / s;
    float r = length(uv);
    float ang = atan(uv.y, uv.x);
    float t = time;
    float born = smoothstep(0.0, 1.0, birth);

    // ---- obsidian field --------------------------------------------------------
    vec3 wall = texture(backdrop, qt_TexCoord0).rgb;
    float wl = dot(wall, vec3(0.299, 0.587, 0.114));
    vec3 col = vec3(0.016, 0.014, 0.024);
    col += mix(vec3(wl), wall, 0.3) * 0.085;                     // ghost of the wallpaper

    float sheenN = fbm(uv * 1.25 + vec2(t * 0.011, -t * 0.008), 4);
    col += mix(tintA.rgb, tintC.rgb, sheenN) * 0.04 * smoothstep(0.35, 0.85, sheenN);

    // contour lines, like a field map, bent by slow noise
    float field = fbm(uv * 1.8 + vec2(-t * 0.015, t * 0.01), 3);
    float contour = abs(fract((r + field * 0.09) * 20.0 - t * 0.025) - 0.5);
    float lines = smoothstep(0.04, 0.0, contour) * smoothstep(1.05, 0.38, r) * smoothstep(0.0, 0.25, abs(r - radius));
    col += vec3(0.86, 0.84, 0.93) * lines * 0.045 * born;

    col *= smoothstep(1.4, 0.2, r);                              // vignette

    // ---- the ring ------------------------------------------------------------------
    float R = radius * mix(0.35, 1.0, born);
    R *= 1.0 - 0.15 * verify;
    R += success * success * 1.7;

    float c = cos(spin);
    float sn = sin(spin);
    vec2 dir = vec2(cos(ang), sin(ang));
    vec2 rd = mat2(c, -sn, sn, c) * dir;                         // seamless angular coordinate

    // near-perfect circle: slow breathing plus fine ripples that typing excites
    float n1 = fbm(rd * 1.6 + vec2(t * 0.03, -t * 0.024), 4);
    float n2 = fbm(rd * 7.0 + vec2(-t * 0.07, t * 0.05) + n1 * 1.4, 4);
    // a wrong password makes the rim shudder with fine, fast ripples
    float shudder = (fbm(rd * 26.0 + vec2(t * 9.0, -t * 7.0), 3) - 0.5) * fail * fail * 0.07;
    float disp = (n1 - 0.5) * 0.022 + (n2 - 0.5) * 0.010 * (1.0 + energy * 3.5) + shudder;
    float edge = R + disp;
    float d = r - edge;

    // rim profile: razor-sharp on the inside, a short soft falloff outside
    float thIn = 0.0028 * (1.0 + success * 4.0);
    float thOut = (0.010 + 0.008 * n2 + 0.010 * energy) * (1.0 + success * 4.0);
    float rim = d < 0.0 ? exp(-(d * d) / (thIn * thIn)) : exp(-(d * d) / (thOut * thOut));
    float halo = exp(-max(d, 0.0) / 0.06) * smoothstep(-0.004, 0.004, d);

    // filaments: two layers of fine radial strands, brightest at the root
    float fa = fbm(rd * 64.0 + (r - edge) * vec2(1.6, -1.2) - vec2(t * 0.16, t * 0.12), 3);
    float fb = fbm(rd * 23.0 + (r - edge) * vec2(-0.9, 1.4) + vec2(t * 0.09, -t * 0.07) + n1, 3);
    float reach = 0.075 + 0.11 * energy + 0.04 * verify;
    float out_ = smoothstep(-0.002, 0.006, d);
    float strands = (pow(smoothstep(0.5, 0.96, fa), 2.4) * 1.0 + pow(smoothstep(0.55, 0.95, fb), 2.0) * 0.6)
                  * exp(-max(d, 0.0) / reach) * out_;

    // beads of light drifting along the rim
    float beads = pow(max(0.0, sin(ang * 3.0 + t * 0.31 + n1 * 3.0)), 90.0)
                + pow(max(0.0, sin(-ang * 2.0 + t * 0.19 + n2 * 2.0)), 120.0) * 0.8;

    // the inner lens: black glass with a faint inner reflection and caustic
    float inside = smoothstep(edge + 0.002, edge - 0.03, r);
    float innerRim = exp(-pow((d + 0.016) / 0.0025, 2.0)) * 0.12;
    vec2 luv = uv / max(R, 0.001);
    float spec = smoothstep(0.75, 0.0, length(luv - vec2(-0.38, -0.42))) * 0.05;
    float caustic = pow(fbm(uv * 5.0 + vec2(t * 0.03, t * 0.02) + n1, 4), 5.0) * 0.16;

    // pearl colour: bone at the rim, thin-film interference shifting along it
    float phase = ang / 6.28318 * 2.0 + n1 * 0.9 + t * 0.01 + d * 14.0;
    vec3 film = 0.5 + 0.5 * cos(6.28318 * (vec3(0.0, 0.33, 0.67) + phase));
    vec3 tint = mix(mix(tintA.rgb, tintB.rgb, film.r), tintC.rgb, film.b * 0.7);
    vec3 pearl = mix(vec3(0.95, 0.93, 0.97), tint, 0.30);
    vec3 strandCol = mix(vec3(0.90, 0.88, 0.95), tint, 0.55);
    vec3 emberC = vec3(0.92, 0.52, 0.42);
    pearl = mix(pearl, emberC, fail * 0.55);
    strandCol = mix(strandCol, emberC, fail * 0.55);

    col *= 1.0 - inside * 0.6 * born;
    col += (caustic * mix(vec3(0.8), tint, 0.5) + spec * vec3(0.9, 0.9, 1.0) + innerRim * pearl) * inside * born;

    // the rim: bone core, iridescent where it falls off outward
    float outer = smoothstep(0.0, thOut * 1.5, d);
    col += mix(pearl, tint * 1.1, outer * 0.7) * rim * (0.95 + 0.25 * energy) * born;
    col += vec3(1.0, 0.98, 1.0) * rim * beads * 0.65 * born;
    col += tint * halo * (0.06 + 0.08 * energy) * born;
    col += strandCol * strands * (0.75 + 0.4 * energy) * born;

    // ...and sends a faint shockwave outward
    float shockR = edge + (1.0 - fail) * 0.32;
    float shock = exp(-pow((r - shockR) / 0.006, 2.0)) * fail * smoothstep(0.0, 0.3, 1.0 - fail);
    col += emberC * shock * 0.35;

    // while verifying, a slow bright wave travels round the rim
    col += pearl * rim * verify * 0.6 * (0.5 + 0.5 * sin(ang * 3.0 - t * 5.0));

    // unlocking: everything gives way to the wallpaper
    col = mix(col, wall, smoothstep(0.3, 1.0, success));

    // film grain
    col += (hash12(qt_TexCoord0 * res + fract(t * 0.37) * 113.0) - 0.5) * 0.016;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0) * qt_Opacity;
}
