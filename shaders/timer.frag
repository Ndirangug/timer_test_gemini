#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uProgress;
uniform vec3 uColorGreen;
uniform vec3 uColorRingBg;
uniform vec3 uColorOuter;
uniform vec3 uColorInner;

out vec4 fragColor;

#define PI 3.14159265359

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    uv = uv * 2.0 - 1.0;

    float dist = length(uv);

    // Geometry
    float rOuterEdge = 0.98;
    float rRingOuter = 0.80; 
    float rRingInner = 0.72; 
    float smoothEdge = 0.01;

    // 1. Outer Bezel
    float alphaOuter = 1.0 - smoothstep(rOuterEdge, rOuterEdge + smoothEdge, dist);
    vec3 finalColor = uColorOuter;

    // 2. Progress Ring
    float ringMask = smoothstep(rRingInner, rRingInner + smoothEdge, dist) 
                   - smoothstep(rRingOuter, rRingOuter + smoothEdge, dist);

    // --- FIX IS HERE ---
    // We use -uv.y to flip the vertical orientation.
    // Now (0, -1) becomes (0, 1) inside atan, setting the start to Top.
    float angleCCW = atan(-uv.x, -uv.y);
    float radialCCW = fract((angleCCW / (2.0 * PI))); 
    
    vec3 ringColor = mix(uColorGreen, uColorRingBg, step(uProgress, radialCCW));

    finalColor = mix(finalColor, ringColor, ringMask);

    // 3. Inner Glossy Body
    float bodyMask = 1.0 - smoothstep(rRingInner - smoothEdge, rRingInner, dist);
    vec2 lightPos = vec2(-0.3, 0.3);
    float glossDist = length(uv - lightPos);
    float gloss = exp(-glossDist * 3.5) * 0.4;
    float shadow = smoothstep(-1.0, 1.0, uv.y + uv.x) * 0.2;
    vec3 bodyColor = uColorInner + gloss - (shadow * 0.3);
    
    finalColor = mix(finalColor, bodyColor, bodyMask);

    fragColor = vec4(finalColor, alphaOuter);
}
