#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uFreezeProgress; // 0.0 (no ice) -> 1.0 (fully frozen)

out vec4 fragColor;

// --- NOISE FUNCTIONS ---
// Simple pseudo-random hash
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// 2D Value Noise for icy texture
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f); // Smoothstep
    float a = hash(i + vec2(0.0, 0.0));
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion (layering noise for detail)
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 centeredUV = uv * 2.0 - 1.0;
    // Correct aspect ratio if necessary (assuming square for now)
    
    float dist = length(centeredUV);

    // --- ICE GROWTH LOGIC ---
    // uFreezeProgress goes 0.0 -> 1.0.
    // We want ice to grow from outside (radius 1.0) inwards to center (radius 0.0).
    // The "freeze threshold" moves from infinity down to 0.0.
    // We multiply by 1.4 to ensure it starts well outside the bounds.
    float freezeThreshold = (1.0 - uFreezeProgress) * 1.4;

    // Add noise to the distance field to make the growing edge jagged
    float edgeNoise = noise(centeredUV * 5.0) * 0.1;
    float noisyDist = dist - edgeNoise;

    // If the noisy distance is greater than the threshold, it's not frozen yet.
    float iceMask = 1.0 - smoothstep(freezeThreshold, freezeThreshold + 0.05, noisyDist);

    // --- ICE TEXTURE & COLOR ---
    // Base whitish-blue colors
    vec3 iceColorDark = vec3(0.7, 0.85, 1.0); // Deep Blue-white
    vec3 iceColorLight = vec3(0.9, 0.95, 1.0); // Bright White

    // Generate texture pattern
    float n = fbm(centeredUV * 8.0); // Scale up for fine texture
    
    // Create "cracks" by taking absolute difference from mid-grey
    float cracks = smoothstep(0.45, 0.55, abs(n - 0.5) * 2.0);
    
    // Mix colors based on texture
    vec3 finalIceColor = mix(iceColorDark, iceColorLight, n);
    // Add bright white cracks
    finalIceColor += vec3(cracks) * 0.3;

    // Final composite: Color with alpha based on the growth mask.
    // We give the ice a slight overall transparency (0.85) so we can faintly see the timer below.
    fragColor = vec4(finalIceColor, iceMask * 0.85);
}
