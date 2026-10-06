#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float bass;
    float fade;
    vec2 resolution;
    float bandCount;
    float hasCover;
    vec4 color1;
    vec4 color2;
    vec4 color3;
    vec4 b0;  vec4 b1;  vec4 b2;  vec4 b3;
    vec4 b4;  vec4 b5;  vec4 b6;  vec4 b7;
    vec4 b8;  vec4 b9;  vec4 b10; vec4 b11;
    vec4 b12;
    vec4 p0;  vec4 p1;  vec4 p2;  vec4 p3;
    vec4 p4;  vec4 p5;  vec4 p6;  vec4 p7;
    vec4 p8;  vec4 p9;  vec4 p10; vec4 p11;
    vec4 p12;
};

vec4 bandBlocks[13];
vec4 peakBlocks[13];

void loadSpectrum() {
    bandBlocks = vec4[](b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12);
    peakBlocks = vec4[](p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12);
}

int clampBand(int i) {
    return clamp(i, 0, max(int(bandCount) - 1, 0));
}

float bandAt(int i) {
    i = clampBand(i);
    int k = i / 4;
    return bandBlocks[k][i - (k * 4)];
}

float spectrum(float x) {
    float f = clamp(x, 0.0, 1.0) * max(bandCount - 1.0, 0.0);
    int i = int(floor(f));
    float t = f - float(i);
    float v0 = bandAt(i - 1);
    float v1 = bandAt(i);
    float v2 = bandAt(i + 1);
    float v3 = bandAt(i + 2);
    float v = v1 + 0.5 * t * (v2 - v0 + t * (2.0 * v0 - 5.0 * v1 + 4.0 * v2 - v3 + t * (3.0 * (v1 - v2) + v3 - v0)));
    return clamp(v, 0.0, 1.0);
}

// Concave gothic needle arch: sharp needle tip with wide hyperbolic base flare
float needle(float u, float u0, float w, float p) {
    float d = abs(u - u0) / w;
    if (d >= 1.0) return 0.0;
    return exp(-3.0 * pow(d, p)) * (1.0 - d * d);
}

// 4-pointed diamond star
float star4(vec2 p, vec2 c, float r) {
    vec2 d = abs(p - c);
    float d1 = (d.x + d.y) / r;
    float d2 = min(d.x + d.y * 3.5, d.y + d.x * 3.5) / (r * 1.35);
    return clamp(1.0 - min(d1, d2), 0.0, 1.0);
}

void main() {
    loadSpectrum();

    vec2 pos = qt_TexCoord0 * resolution;
    float xNorm = clamp(pos.x / resolution.x, 0.0, 1.0);
    float u = abs(xNorm - 0.5) * 2.0;

    // Audio reactivity per cluster:
    float audioCenter = spectrum(0.18) * 1.5;
    float audioInner = spectrum(0.32) * 1.4;
    float audioOuter = spectrum(0.09) * 1.2;
    float audioWhisker = spectrum(0.02) * 1.0;

    float audio = mix(audioCenter, audioInner, smoothstep(0.15, 0.38, u));
    audio = mix(audio, audioOuter, smoothstep(0.45, 0.68, u));
    audio = mix(audio, audioWhisker, smoothstep(0.75, 0.92, u));
    audio = clamp(audio, 0.0, 1.0);

    // Audio reactive expansion: 10% dormant base, 90% dynamic bounce
    float audioReactive = 0.10 + 0.90 * clamp(pow(audio, 0.80) * 1.25, 0.0, 1.0);
    float idleBreath = 0.03 * sin(time * 2.2 + u * 4.0);

    // =========================================================================
    // Fluid 5-Star WuWa Tacet Mark Silhouette (Authentic reference match)
    // =========================================================================

    // --- Cluster 0: Center Master Spire (u in [0.0, 0.22]) ---
    // Towering needle upper (0.95) and razor-thin stiletto dagger downward (0.98)
    float n0_up = audioReactive * 0.95 * needle(u, 0.0, 0.080, 0.55);
    float n0_down = audioReactive * 0.98 * needle(u, 0.0, 0.070, 0.52);
    // Stepped shoulders
    float sh0_up1 = (0.08 + 0.65 * audio) * 0.58 * needle(u, 0.075, 0.055, 0.68);
    float sh0_down1 = (0.07 + 0.60 * audio) * 0.42 * needle(u, 0.070, 0.050, 0.68);
    float sh0_up2 = (0.06 + 0.50 * audio) * 0.36 * needle(u, 0.145, 0.052, 0.72);
    float sh0_down2 = (0.05 + 0.45 * audio) * 0.26 * needle(u, 0.140, 0.048, 0.72);
    // Smooth connecting web
    float web0 = (0.04 + 0.10 * audio + idleBreath) * needle(u, 0.0, 0.21, 1.1);

    float c0_up = max(max(n0_up, sh0_up1), max(sh0_up2, web0));
    float c0_down = max(max(n0_down, sh0_down1), max(sh0_down2, web0));

    // --- Cluster 1: Inner Needle Cross (u in [0.27, 0.50], center 0.380) ---
    float n1_up = audioReactive * 0.76 * needle(u, 0.380, 0.065, 0.58);
    float n1_down = audioReactive * 0.80 * needle(u, 0.380, 0.058, 0.55);
    float sh1_l = (0.06 + 0.50 * audio) * 0.38 * needle(u, 0.315, 0.048, 0.70);
    float sh1_r = (0.06 + 0.50 * audio) * 0.36 * needle(u, 0.445, 0.048, 0.70);
    float web1 = (0.03 + 0.08 * audio) * needle(u, 0.380, 0.11, 1.1);

    float c1_up = max(max(n1_up, sh1_l), max(sh1_r, web1));
    float c1_down = max(max(n1_down, sh1_l * 0.85), max(sh1_r * 0.85, web1));

    // --- Cluster 2: Outer Needle Cross (u in [0.58, 0.80], center 0.680) ---
    float n2_up = audioReactive * 0.58 * needle(u, 0.680, 0.058, 0.60);
    float n2_down = audioReactive * 0.62 * needle(u, 0.680, 0.052, 0.58);
    float sh2_l = (0.05 + 0.40 * audio) * 0.28 * needle(u, 0.620, 0.044, 0.72);
    float sh2_r = (0.05 + 0.40 * audio) * 0.26 * needle(u, 0.740, 0.044, 0.72);
    float web2 = (0.02 + 0.06 * audio) * needle(u, 0.680, 0.10, 1.1);

    float c2_up = max(max(n2_up, sh2_l), max(sh2_r, web2));
    float c2_down = max(max(n2_down, sh2_l * 0.85), max(sh2_r * 0.85, web2));

    // --- Cluster 3: Outer Whisker (u in [0.86, 1.0], center 0.925) ---
    float n3_up = audioReactive * 0.36 * needle(u, 0.925, 0.045, 0.65);
    float n3_down = audioReactive * 0.38 * needle(u, 0.925, 0.042, 0.62);
    float sh3_l = (0.04 + 0.30 * audio) * 0.18 * needle(u, 0.880, 0.035, 0.75);
    float h_whisker = 0.03 * max(0.0, 1.0 - pow((u - 0.96) / 0.04, 2.0));

    float c3_up = max(max(n3_up, sh3_l), h_whisker);
    float c3_down = max(max(n3_down, sh3_l * 0.85), h_whisker);

    float totalUpper = max(max(c0_up, c1_up), max(c2_up, c3_up));
    float totalLower = max(max(c0_down, c1_down), max(c2_down, c3_down));

    // Vertical Headroom: inside 28px height, baseline is at 14.0px
    float baseline = resolution.y * 0.50;
    float maxH_up = baseline * 0.85;   // ~11.9px max spire height
    float maxH_down = baseline * 0.88; // ~12.3px max dagger depth

    float targetUp = totalUpper * maxH_up;
    float targetDown = totalLower * maxH_down;

    float up = baseline - pos.y;
    float down = -up;

    // =========================================================================
    // SOLID FLUID SILHOUETTE (No ribs, no bars, smooth vector contour)
    // =========================================================================
    float fillUp = 0.0;
    if (up >= 0.0 && targetUp > 0.2) {
        float dUp = up - targetUp;
        fillUp = 1.0 - smoothstep(-0.6, 0.6, dUp);
    }

    float fillDown = 0.0;
    if (down >= 0.0 && targetDown > 0.2) {
        float dDown = down - targetDown;
        fillDown = 1.0 - smoothstep(-0.6, 0.6, dDown);
    }

    float fluidSilhouette = max(fillUp, fillDown);

    // Subtle connecting baseline axis
    float clusterMask = smoothstep(0.008, 0.025, totalUpper);
    float axisLine = (1.0 - smoothstep(0.0, 0.75, abs(up))) * 0.35;

    // Floating 4-pointed diamond stars in the gaps: u = 0.245, 0.540, 0.830
    float bob = 0.6 * sin(time * 2.5);
    float s1 = star4(pos, vec2(resolution.x * (0.5 - 0.245 * 0.5), baseline + bob), 2.2);
    float s2 = star4(pos, vec2(resolution.x * (0.5 + 0.245 * 0.5), baseline - bob), 2.2);
    float s3 = star4(pos, vec2(resolution.x * (0.5 - 0.540 * 0.5), baseline - bob), 2.0);
    float s4 = star4(pos, vec2(resolution.x * (0.5 + 0.540 * 0.5), baseline + bob), 2.0);
    float s5 = star4(pos, vec2(resolution.x * (0.5 - 0.830 * 0.5), baseline + bob), 1.7);
    float s6 = star4(pos, vec2(resolution.x * (0.5 + 0.830 * 0.5), baseline - bob), 1.7);
    float stars = max(max(max(s1, s2), max(s3, s4)), max(s5, s6));

    // Subtle edge glow (soft gothic aura along the contour)
    float edgeGlow = 0.0;
    if (up >= 0.0 && targetUp > 0.5) {
        float d = max(0.0, up - targetUp);
        edgeGlow = exp(-d / 1.2) * 0.25 * clusterMask * (1.0 - fillUp);
    }

    // Color compositing:
    // Main fluid body in color1 (bright theme primary)
    // Stars in color3 (accent)
    vec4 col = vec4(color1.rgb, 1.0) * fluidSilhouette;
    col += vec4(color1.rgb, 1.0) * axisLine * (1.0 - col.a);
    col.rgb += color1.rgb * edgeGlow;
    col = mix(col, vec4(color3.rgb, 1.0), stars * 0.95);

    fragColor = col * fade * qt_Opacity;
}
