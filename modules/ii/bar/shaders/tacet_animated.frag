#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    vec2 resolution;
    vec4 colorPrimary;
    vec4 colorAccent;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 uv = qt_TexCoord0;

    // Organic fluid undulation: energy ripples flexing the spires and daggers
    float dist = abs(uv.x - 0.5) * 2.0;
    float tipFactor = smoothstep(0.08, 0.65, abs(uv.y - 0.5));
    float flexY = sin(time * 4.2 - dist * 9.0) * 0.026 * tipFactor;
    float flexX = cos(time * 3.2 + uv.y * 12.0) * 0.010 * (1.0 - dist * 0.5);

    vec2 sampleUv = vec2(clamp(uv.x + flexX, 0.0, 1.0), clamp(uv.y + flexY, 0.0, 1.0));
    vec4 tex = texture(source, sampleUv);

    if (tex.a < 0.005) {
        fragColor = vec4(0.0);
        return;
    }

    // Resonant wave propagating outward from center with increased pace & definition
    float wave1 = sin(time * 4.0 - dist * 10.0);
    float highlight1 = smoothstep(0.28, 0.95, wave1);

    // Harmonic counter-wave for continuous lively energy shimmer
    float wave2 = sin(time * 2.6 + dist * 6.5);
    float highlight2 = smoothstep(0.42, 0.98, wave2) * 0.55;

    // Micro-sparkle traveling across the horizontal spine
    float sparkle = pow(0.5 + 0.5 * sin(time * 7.5 - dist * 16.0), 4.0) * 0.35;

    float shimmer = clamp(highlight1 * 0.75 + highlight2 + sparkle, 0.0, 1.0);

    // Vertical brightness profile (slight emphasis on horizontal spine)
    float vSpine = 1.0 - pow(abs(uv.y - 0.5) * 2.0, 1.8) * 0.20;

    // Colors:
    vec3 baseCol = colorPrimary.rgb;
    vec3 accentCol = mix(colorPrimary.rgb, colorAccent.rgb, 0.60);
    vec3 crestCol = mix(accentCol, vec3(1.0), 0.70);

    // Composite colors across wave
    vec3 litColor = mix(baseCol, accentCol, shimmer * 0.85);
    litColor = mix(litColor, crestCol, pow(shimmer, 2.0) * 0.85);
    litColor *= vSpine;

    // Luminous breathing modulation
    float breath = 0.82 + 0.18 * sin(time * 3.0);

    fragColor = vec4(litColor * tex.a, tex.a) * breath * qt_Opacity;
}
