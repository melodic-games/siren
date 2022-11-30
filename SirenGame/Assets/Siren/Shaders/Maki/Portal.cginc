#ifndef MAKI_PORTAL_INCLUDE
#define MAKI_PORTAL_INCLUDE

#include "../Snoise.cginc"

#define maxSteps 48
#define accuracy 0.01

float sphere(float3 p, float s) { return length(p) - s; }

float portal(float3 p, float time)
{
    float n = snoise(
        float3(p.xy * 12, (sin(time) + (time * 3)) * 0.2)
    );

    p.xz += lerp(0, n * 0.12, length(p.xy));

    float portal = sphere(p, 0.5);
    portal = max(-sphere(p - float3(0, 0, 0.7), 0.5), portal);
    portal = max(-sphere(p - float3(0, 0, -0.7), 0.5), portal);
    return portal;
}

float scene(float3 p, float time)
{
    // p /= iWorldScale;

    return max(
        portal(p, time),
        sphere(p, 1 - clamp(1 - time * 0.5, 0, 1))
    );
}

float4 raymarch(float3 rayOrigin, float3 rayDir, float time)
{
    int raySteps = 0;
    float3 rayPos = rayOrigin;

    // make slightly smaller
    rayPos *= 1.1;
    // moving up and down
    rayPos.y += sin(time * 2) * 0.05;
    // fit to bounding box
    // rayPos.z *= 0.8;

    for (raySteps = 0; raySteps < maxSteps; raySteps++)
    {
        float dist = scene(rayPos, time);
        rayPos += rayDir * dist;
        if (dist < accuracy) break;
    }

    float c = (maxSteps - float(raySteps)) / maxSteps;
    if (c < accuracy) return float4(0, 0, 0, 0);

    return float4(rayPos, 1);
}

#endif
