#version 440

// ─────────────────────────────────────────────────────────────────────────────
// Sinuous Harmonic Wave & Particle Stream (Island Filler)
//
// Renders flowing, multi-harmonic sinusoidal ribbons that continuously drift,
// cross over, and breathe between floating bar islands.
// Features:
// - Multiple phase-offset harmonic sine waves
// - Translucent gradient sheer/ribbon fills between crossing wave envelopes
// - Glowing crest lines with exponential falloff and bright luminance cores
// - Floating stardust particle embers with soft pulsing glows
// - Adaptive smooth windowing (taper) to softly merge into island pill edges
// - Matugen color theming (colPrimary, colSecondary, colTertiary)
// - Audio-reactive amplitude and particle acceleration
// ─────────────────────────────────────────────────────────────────────────────

layout(location = 0) in  vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float time;          // continuous animation time (seconds)
    float aud;           // 0..1 audio energy / bass boost
    float gapX;          // this gap's left edge in global bar px
    float gapW;          // gap width in pixels
    float gapH;          // gap height in pixels
    float gapIndex;      // 0 = left gap, 1 = right gap
    float styleMode;     // 0 = default waves, 1 = calm ribbon, etc.
    vec4  colPrimary;    // Matugen primary color
    vec4  colSecondary;  // Matugen secondary / container color
    vec4  colTertiary;   // Matugen tertiary color
};

const float PI = 3.141592653589793;

float hash(float n) {
    float s = sin(n * 127.1) * 43758.5453;
    return s - floor(s);
}

void over(inout vec4 acc, vec3 c, float a) {
    a = clamp(a, 0.0, 1.0);
    acc = vec4(c * a, a) + acc * (1.0 - a);
}

void main() {
    float px = gapX + qt_TexCoord0.x * gapW;
    float py = qt_TexCoord0.y * gapH;
    float cy = gapH * 0.5;
    float u  = clamp(qt_TexCoord0.x, 0.0, 1.0);

    // Adaptive window: smoothly taper amplitude and opacity to 0 at the island edges
    float win = sin(u * PI);
    float winAmp = pow(win, 0.7);
    float winAlpha = pow(win, 0.5);

    // Color definitions from Matugen theme
    vec3 cPri = colPrimary.rgb;
    vec3 cSec = colSecondary.rgb;
    vec3 cTer = colTertiary.rgb;
    vec3 cWhite = vec3(1.0);

    // Wave parameters (harmonic frequencies, speeds, and phase offsets)
    float audioBoost = clamp(aud, 0.0, 1.0);
    float baseAmp = min(gapH * 0.36, 12.0) * (0.85 + audioBoost * 0.45) * winAmp;
    float t = time;

    // Harmonic wave 1: Dominant flowing ribbon
    float k1 = 0.028;
    float s1 = -1.45;
    float p1 = gapIndex * 1.5;
    float y1 = cy + baseAmp * sin(px * k1 + t * s1 + p1);

    // Harmonic wave 2: Counter wave (different frequency and opposite drift)
    float k2 = 0.042;
    float s2 = 1.75;
    float p2 = 2.1 + gapIndex * 0.9;
    float y2 = cy + (baseAmp * 0.88) * sin(px * k2 + t * s2 + p2);

    // Harmonic wave 3: Undulating mid-frequency wave
    float k3 = 0.019;
    float s3 = -0.95;
    float p3 = 4.2 + gapIndex * 2.2;
    float y3 = cy + (baseAmp * 0.75) * sin(px * k3 + t * s3 + p3);

    // Harmonic wave 4: Fine resonant ripple
    float k4 = 0.058;
    float s4 = 2.25;
    float p4 = 1.0 + gapIndex * 3.1;
    float y4 = cy + (baseAmp * 0.50) * cos(px * k4 + t * s4 + p4);

    vec4 acc = vec4(0.0);

    // ── 1. Sheer Translucent Ribbon Fills (between crossing waves) ──
    // Ribbon between Wave 1 and Wave 2
    float rMin1 = min(y1, y2);
    float rMax1 = max(y1, y2);
    float inRibbon1 = smoothstep(rMin1 - 1.5, rMin1 + 0.5, py) * (1.0 - smoothstep(rMax1 - 0.5, rMax1 + 1.5, py));
    float ribbonDist1 = abs(py - (rMin1 + rMax1) * 0.5) / max(1.0, (rMax1 - rMin1) * 0.5);
    float ribbonAlpha1 = inRibbon1 * (0.18 + 0.09 * (1.0 - ribbonDist1)) * winAlpha;
    over(acc, mix(cSec, cPri, 0.45), ribbonAlpha1);

    // Ribbon between Wave 2 and Wave 3
    float rMin2 = min(y2, y3);
    float rMax2 = max(y2, y3);
    float inRibbon2 = smoothstep(rMin2 - 1.5, rMin2 + 0.5, py) * (1.0 - smoothstep(rMax2 - 0.5, rMax2 + 1.5, py));
    float ribbonDist2 = abs(py - (rMin2 + rMax2) * 0.5) / max(1.0, (rMax2 - rMin2) * 0.5);
    float ribbonAlpha2 = inRibbon2 * (0.14 + 0.07 * (1.0 - ribbonDist2)) * winAlpha;
    over(acc, mix(cTer, cPri, 0.35), ribbonAlpha2);

    // ── 2. Glowing Crest Lines for each Wave ──
    // Wave 1 Crest
    float d1 = abs(py - y1);
    float glow1 = exp(-d1 / 3.8) * 0.30 * winAlpha;
    float core1 = exp(-d1 * d1 / 1.5) * 0.88 * winAlpha;
    over(acc, cPri, glow1);
    over(acc, mix(cPri, cWhite, 0.68), core1);

    // Wave 2 Crest
    float d2 = abs(py - y2);
    float glow2 = exp(-d2 / 3.4) * 0.25 * winAlpha;
    float core2 = exp(-d2 * d2 / 1.4) * 0.80 * winAlpha;
    over(acc, cSec, glow2);
    over(acc, mix(cSec, cWhite, 0.62), core2);

    // Wave 3 Crest
    float d3 = abs(py - y3);
    float glow3 = exp(-d3 / 3.0) * 0.20 * winAlpha;
    float core3 = exp(-d3 * d3 / 1.3) * 0.72 * winAlpha;
    over(acc, cTer, glow3);
    over(acc, mix(cTer, cWhite, 0.58), core3);

    // Wave 4 Crest (faint resonant wave)
    float d4 = abs(py - y4);
    float core4 = exp(-d4 * d4 / 1.2) * 0.50 * winAlpha;
    over(acc, mix(cPri, cTer, 0.5), core4);

    // ── 3. Drifting Stardust / Particle Embers ──
    // 16 particles spaced out across the gap, drifting with time
    for (int i = 0; i < 16; i++) {
        float fi = float(i);
        float pSpeed = 22.0 + hash(fi * 13.7) * 24.0 + audioBoost * 45.0;
        float pOffset = hash(fi * 71.3) * gapW;
        float partLocalX = mod(pOffset + t * pSpeed, gapW);
        float partU = partLocalX / max(gapW, 1.0);
        float partWin = pow(sin(partU * PI), 0.6);

        // Particle y-position rides between wave 1 and wave 2
        float waveMix = hash(fi * 33.1);
        float globalPartX = gapX + partLocalX;
        float waveY1 = cy + baseAmp * sin(globalPartX * k1 + t * s1 + p1);
        float waveY2 = cy + (baseAmp * 0.88) * sin(globalPartX * k2 + t * s2 + p2);
        float partY = mix(waveY1, waveY2, waveMix) + (hash(fi * 91.5) - 0.5) * 5.0;

        float pDist = length(vec2(px - globalPartX, py - partY));
        float pRadius = 1.0 + hash(fi * 47.9) * 0.9;
        float pPulse = 0.55 + 0.45 * sin(t * 3.5 + fi * 2.2);

        // Core dot and soft bloom
        float pCore = (1.0 - smoothstep(pRadius - 0.8, pRadius, pDist)) * 0.92 * pPulse * partWin;
        float pGlow = max(0.0, 1.0 - pDist / (pRadius * 3.5)) * 0.35 * pPulse * partWin;

        vec3 pCol = mix(cPri, cWhite, hash(fi * 19.3) * 0.75);
        over(acc, cPri, pGlow);
        over(acc, pCol, pCore);
    }

    fragColor = acc * qt_Opacity;
}
