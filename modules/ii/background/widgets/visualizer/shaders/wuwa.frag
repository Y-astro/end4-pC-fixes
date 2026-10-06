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

float peakAt(int i) {
    i = clampBand(i);
    int k = i / 4;
    return peakBlocks[k][i - (k * 4)];
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

float peak(float x) {
    float f = clamp(x, 0.0, 1.0) * max(bandCount - 1.0, 0.0);
    int i = int(floor(f));
    return mix(peakAt(i), peakAt(i + 1), f - float(i));
}

// Concave gothic needle arch: sharp needle tip with wide hyperbolic base flare
float gothicFlare(float u, float u0, float w, float p) {
    float d = abs(u - u0) / w;
    if (d >= 1.0) return 0.0;
    return exp(-3.2 * pow(d, p)) * (1.0 - d * d);
}

// 4-pointed cruciform star for gap nodes
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

    // Scale factor based on height (desktop baseline is ~250px, topbar is ~28-40px)
    float scale = clamp(resolution.y / 250.0, 0.10, 2.0);

    // Dynamic frequency assignment per cluster:
    // Center: vocal & melody core (0.18) with high responsiveness
    // Inner cross: snare & mid instruments (0.32)
    // Outer cross: bass & punch (0.09)
    // Whiskers: sub-bass rumble (0.02)
    float audioCenter = spectrum(0.18) * 1.45;
    float audioInner = spectrum(0.32) * 1.35;
    float audioOuter = spectrum(0.09) * 1.15;
    float audioWhisker = spectrum(0.02) * 0.95;

    float audio = mix(audioCenter, audioInner, smoothstep(0.15, 0.38, u));
    audio = mix(audio, audioOuter, smoothstep(0.45, 0.68, u));
    audio = mix(audio, audioWhisker, smoothstep(0.75, 0.92, u));
    audio = clamp(audio, 0.0, 1.0);

    float peakCenter = peak(0.18) * 1.45;
    float peakInner = peak(0.32) * 1.35;
    float peakOuter = peak(0.09) * 1.15;
    float peakWhisker = peak(0.02) * 0.95;
    float pVal = mix(peakCenter, peakInner, smoothstep(0.15, 0.38, u));
    pVal = mix(pVal, peakOuter, smoothstep(0.45, 0.68, u));
    pVal = mix(pVal, peakWhisker, smoothstep(0.75, 0.92, u));
    pVal = clamp(pVal, 0.0, 1.0);

    // Scale-dependent dynamic range:
    // On desktop: staticBase = 0.36, audio drives 64%
    // On topbar: staticBase = 0.08, audio drives 92% so the small spires visibly dance!
    float staticBase = mix(0.08, 0.36, smoothstep(0.12, 1.0, scale));
    float reactiveMult = 1.0 - staticBase;
    float audioReactive = staticBase + reactiveMult * clamp(pow(audio, 0.82) * 1.25, 0.0, 1.0);

    float idleBreath = 0.025 * sin(time * 2.2 + u * 4.0);

    // =========================================================================
    // 5-Star WuWa Tacet Mark Formatting
    // =========================================================================

    // --- Cluster 1: Center Master Spire (u in [0.0, 0.22]) ---
    float n0_up = audioReactive * 0.95 * gothicFlare(u, 0.0, 0.082, 0.58);
    float n0_down = audioReactive * 0.98 * gothicFlare(u, 0.0, 0.075, 0.55);
    // Tier 1 stepped shoulders
    float sh0_up1 = (staticBase * 0.65 + reactiveMult * audio * 0.75) * 0.56 * gothicFlare(u, 0.075, 0.060, 0.68);
    float sh0_down1 = (staticBase * 0.55 + reactiveMult * audio * 0.70) * 0.42 * gothicFlare(u, 0.070, 0.055, 0.68);
    // Tier 2 stepped shoulders
    float sh0_up2 = (staticBase * 0.45 + reactiveMult * audio * 0.60) * 0.34 * gothicFlare(u, 0.145, 0.055, 0.72);
    float sh0_down2 = (staticBase * 0.40 + reactiveMult * audio * 0.55) * 0.26 * gothicFlare(u, 0.140, 0.052, 0.72);
    float flare0 = (0.03 + 0.06 * audio + idleBreath) * gothicFlare(u, 0.0, 0.21, 1.1);

    float c0_up = max(max(n0_up, sh0_up1), max(sh0_up2, flare0));
    float c0_down = max(max(n0_down, sh0_down1), max(sh0_down2, flare0));

    // --- Cluster 2: Inner Needle Cross (u in [0.27, 0.49], center 0.380) ---
    float n1_up = audioReactive * 0.78 * gothicFlare(u, 0.380, 0.068, 0.60);
    float n1_down = audioReactive * 0.82 * gothicFlare(u, 0.380, 0.062, 0.58);
    float sh1_l = (staticBase * 0.45 + reactiveMult * audio * 0.65) * 0.38 * gothicFlare(u, 0.310, 0.052, 0.72);
    float sh1_r = (staticBase * 0.45 + reactiveMult * audio * 0.65) * 0.36 * gothicFlare(u, 0.450, 0.052, 0.72);
    float flare1 = (0.02 + 0.05 * audio) * gothicFlare(u, 0.380, 0.11, 1.1);

    float c1_up = max(max(n1_up, sh1_l), max(sh1_r, flare1));
    float c1_down = max(max(n1_down, sh1_l * 0.85), max(sh1_r * 0.85, flare1));

    // --- Cluster 3: Outer Needle Cross (u in [0.57, 0.79], center 0.680) ---
    float n2_up = audioReactive * 0.62 * gothicFlare(u, 0.680, 0.062, 0.62);
    float n2_down = audioReactive * 0.66 * gothicFlare(u, 0.680, 0.056, 0.60);
    float sh2_l = (staticBase * 0.35 + reactiveMult * audio * 0.55) * 0.28 * gothicFlare(u, 0.615, 0.048, 0.72);
    float sh2_r = (staticBase * 0.35 + reactiveMult * audio * 0.55) * 0.26 * gothicFlare(u, 0.745, 0.048, 0.72);
    float flare2 = (0.02 + 0.04 * audio) * gothicFlare(u, 0.680, 0.10, 1.1);

    float c2_up = max(max(n2_up, sh2_l), max(sh2_r, flare2));
    float c2_down = max(max(n2_down, sh2_l * 0.85), max(sh2_r * 0.85, flare2));

    // --- Cluster 4: Outer Needle & Whisker (u in [0.85, 1.0], center 0.920) ---
    float n3_up = audioReactive * 0.40 * gothicFlare(u, 0.920, 0.048, 0.66);
    float n3_down = audioReactive * 0.42 * gothicFlare(u, 0.920, 0.045, 0.64);
    float sh3_l = (staticBase * 0.25 + reactiveMult * audio * 0.40) * 0.18 * gothicFlare(u, 0.875, 0.035, 0.75);
    float h_whisker = 0.03 * max(0.0, 1.0 - pow((u - 0.96) / 0.04, 2.0));

    float c3_up = max(max(n3_up, sh3_l), h_whisker);
    float c3_down = max(max(n3_down, sh3_l * 0.85), h_whisker);

    float totalUpper = max(max(c0_up, c1_up), max(c2_up, c3_up));
    float totalLower = max(max(c0_down, c1_down), max(c2_down, c3_down));

    float baseline = resolution.y * 0.50;
    float maxH_up = baseline * mix(0.72, 0.89, smoothstep(0.12, 1.0, scale));
    float maxH_down = baseline * mix(0.75, 0.89, smoothstep(0.12, 1.0, scale));

    float targetUp = totalUpper * maxH_up;
    float targetDown = totalLower * maxH_down;

    // Cluster mask: 1 inside clusters, 0 in the narrowed gaps
    float clusterMask = smoothstep(0.008, 0.025, totalUpper);

    float up = baseline - pos.y;
    float down = -up;

    // Equalizer Bar Grid (Mirror theme frequency ribs)
    float pitch = mix(5.5, 7.0, smoothstep(0.12, 1.0, scale));
    float halfW = mix(1.4, 2.1, smoothstep(0.12, 1.0, scale));
    float gx = (pos.x - mod(resolution.x, pitch) * 0.5) / pitch;
    float idX = floor(gx);
    float lx = (gx - idX - 0.5) * pitch;

    // Upward bar distance & coverage (solid gothic body + crisp rib texture)
    float barUp = 0.0;
    float bodyUp = 0.0;
    float contourUp = 0.0;
    if (up >= 0.0 && targetUp > 0.3) {
        float dBarUp = length(vec2(lx, max(0.0, up - max(0.0, targetUp - halfW)))) - halfW;
        barUp = (1.0 - smoothstep(-0.6, 0.6, dBarUp)) * step(0.0, up);
        bodyUp = (1.0 - smoothstep(-1.0, 1.0, up - targetUp)) * 0.55;
        contourUp = (1.0 - smoothstep(0.0, 1.5, abs(up - targetUp))) * 0.75;
    }

    // Downward reflection bar distance & coverage (sharp stiletto needles terminating cleanly)
    float barDown = 0.0;
    float bodyDown = 0.0;
    float contourDown = 0.0;
    if (down >= 0.0 && targetDown > 0.3) {
        float dBarDown = length(vec2(lx, max(0.0, down - max(0.0, targetDown - halfW)))) - halfW;
        barDown = (1.0 - smoothstep(-0.6, 0.6, dBarDown)) * step(0.0, down) * 0.90;
        bodyDown = (1.0 - smoothstep(-1.0, 1.0, down - targetDown)) * step(0.0, down) * 0.50;
        contourDown = (1.0 - smoothstep(0.0, 1.5, abs(down - targetDown))) * step(0.0, down) * 0.70;
    }

    // Dynamic Dashed Peak Wave Movement:
    float cap = 0.0;
    float capGlow = 0.0;
    if (up >= 0.0 && targetUp > 0.5 && clusterMask > 0.0) {
        float peakY = targetUp + mix(0.9, 3.5, smoothstep(0.12, 1.0, scale)) + mix(2.6, 32.0, smoothstep(0.12, 1.0, scale)) * pVal * clusterMask;
        float capH = mix(0.65, 1.25, smoothstep(0.12, 1.0, scale));
        vec2 qd = abs(vec2(lx, up - (peakY + 1.2 * scale))) - vec2(halfW, capH);
        float dPeak = length(max(qd, vec2(0.0))) + min(max(qd.x, qd.y), 0.0);
        cap = (1.0 - smoothstep(-0.45, 0.45, dPeak)) * clusterMask;
        capGlow = exp(-max(0.0, dPeak) / mix(1.2, 2.2, smoothstep(0.12, 1.0, scale))) * 0.35 * clusterMask;
    }

    // Subtle connecting baseline axis
    float baselineLine = (1.0 - smoothstep(0.0, 0.8, abs(up))) * (0.08 + 0.22 * clusterMask);

    // Floating 4-Pointed Diamond Stars in the narrowed gaps: u = 0.24, 0.53, 0.82
    float starR = mix(2.0, 4.2, smoothstep(0.12, 1.0, scale));
    float bob = mix(0.5, 1.6, smoothstep(0.12, 1.0, scale)) * sin(time * 2.2);
    float s1 = star4(pos, vec2(resolution.x * (0.5 - 0.24 * 0.5), baseline + bob), starR);
    float s2 = star4(pos, vec2(resolution.x * (0.5 + 0.24 * 0.5), baseline - bob), starR);
    float s3 = star4(pos, vec2(resolution.x * (0.5 - 0.53 * 0.5), baseline - bob), starR * 0.90);
    float s4 = star4(pos, vec2(resolution.x * (0.5 + 0.53 * 0.5), baseline + bob), starR * 0.90);
    float s5 = star4(pos, vec2(resolution.x * (0.5 - 0.82 * 0.5), baseline + bob), starR * 0.78);
    float s6 = star4(pos, vec2(resolution.x * (0.5 + 0.82 * 0.5), baseline - bob), starR * 0.78);
    float stars = max(max(max(s1, s2), max(s3, s4)), max(s5, s6));

    // Aura glow (tight halo at tips, NO vertical light beams)
    float glowUp = 0.0;
    if (scale > 0.3) {
        float dGlow = max(0.0, up - targetUp);
        float glowRadius = 6.0 + 8.0 * max(0.0, up / maxH_up);
        glowUp = exp(-dGlow / glowRadius) * 0.28 * clusterMask * step(0.0, up) * (1.0 - barUp);
    } else {
        float dGlow = max(0.0, up - targetUp);
        glowUp = exp(-dGlow / 1.0) * 0.30 * clusterMask * step(0.0, up) * (1.0 - barUp) * step(up, targetUp + 2.0);
    }

    // Color compositing with Material You palette
    float tUp = clamp(up / maxH_up, 0.0, 1.0);
    vec3 barColor = mix(color2.rgb, color1.rgb, tUp);
    float tDown = clamp(down / maxH_down, 0.0, 1.0);
    vec3 reflColor = mix(color2.rgb, color1.rgb * 0.85, tDown);

    vec4 col = vec4(0.0);

    // Primary upward bars
    col += vec4(barColor, 1.0) * barUp * 0.92;

    // Downward reflection bars (sharp stiletto needles terminating cleanly)
    col += vec4(reflColor, 1.0) * barDown * (1.0 - col.a);

    // Fluid body fill
    col += vec4(color2.rgb, 1.0) * bodyUp * (1.0 - col.a);
    col += vec4(color2.rgb, 1.0) * bodyDown * (1.0 - col.a);

    // Contour edges
    col += vec4(color1.rgb, 1.0) * contourUp * (1.0 - col.a);
    col += vec4(color1.rgb, 1.0) * contourDown * (1.0 - col.a);

    // Connecting baseline axis
    col += vec4(color1.rgb, 1.0) * baselineLine * (1.0 - col.a);

    // Aura glow
    col.rgb += barColor * glowUp * (1.0 + 0.8 * bass);

    // Dynamic dashed peak wave caps (in color3 accent) & cap glow
    col = mix(col, vec4(color3.rgb, 1.0), cap * 0.95);
    col.rgb += color3.rgb * capGlow;

    // Floating 4-pointed diamond stars (in color3 accent)
    col = mix(col, vec4(color3.rgb, 1.0), stars * 0.92);

    // Fade and opacity
    fragColor = col * fade * qt_Opacity;
}
