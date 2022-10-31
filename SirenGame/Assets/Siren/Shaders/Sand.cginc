#ifndef MAKI_SAND
#define MAKI_SAND

// thank you so much to these wonderful articles
// https://www.alanzucconi.com/2019/10/08/journey-sand-shader-1/

#ifndef SHADERGRAPH_PREVIEW
#include "Snoise.cginc"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/NormalBuffer.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightDefinition.cs.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Shadow/HDShadowManager.cs.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Shadow/HDShadowSampling.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoopDef.hlsl"
#endif

struct Input
{
    float2 TerrainUV;
    float3 WorldPos;
    float3 SurfaceNormal;
    float3 ViewDir;
    UnityTexture2D SandShallowTexture;
    UnityTexture2D SandSteepTexture;
};

float3 nlerp(float3 n1, float3 n2, float t)
{
    return normalize(lerp(n1, n2, t));
}

float3 GetMainLightDir()
{
    if (_DirectionalLightCount > 0)
    {
        DirectionalLightData light = _DirectionalLightDatas[0];
        return -light.forward.xyz;
    }
    // TODO: if there is no light this is bad
    return float3(0, 0, 0);
}

float3 DiffuseColor(float3 N, float3 L)
{
    N.y *= 0.3;
    float NdotL = saturate(4 * dot(N, L));
    
    float3 color = lerp(_ShadowColor, _TerrainColor, NdotL);
    return color;
}

float3 RimLighting(float3 N, float3 V)
{
    float rim = 1.0 - saturate(dot(N, V));
    rim = saturate(pow(rim, _RimPower) * _RimStrength);
    rim = max(rim, 0); // never negative
    return rim * _RimColor;
}

float3 OceanSpecular(float3 N, float3 L, float3 V)
{
    // Blinn-Phong
    float3 H = normalize(V + L); // Half direction
    float NdotH = max(0, dot(N, H));
    float specular = pow(NdotH, _OceanSpecularPower) * _OceanSpecularStrength;
    return specular * _OceanSpecularColor;
}

// float3 GlitterSpecular(float3 N, float3 L, float3 V, Input i)
// {
//     // random glitter direction
//     float3 G = normalize(float3(
//         snoise(i.WorldPos * _GlitterSize + float3(1349, 6391, 2465)),
//         snoise(i.WorldPos * _GlitterSize + float3(7827, 2945, 5698)),
//         snoise(i.WorldPos * _GlitterSize + float3(5282, 4216, 3212))
//     ));
//
//     // light that reflects on the glitter and hits the eye
//     float3 R = reflect(L, G);
//     float RdotV = max(0, dot(R, V));
//
//     // only the strong ones (= small RdotV)
//     if (RdotV > _GlitterThreshold)
//     {
//         return 0;
//     }
//
//     return (1 - RdotV) * _GlitterColor;
// }

float3 LightingJourney(Input i)
{
    float3 L = GetMainLightDir();
    float3 N = i.SurfaceNormal;
    float3 V = i.ViewDir;

    float3 diffuseColor = DiffuseColor(N, L);
    float3 rimColor = RimLighting(N, V);
    float3 oceanColor = OceanSpecular(N, L, V);
    // float3 glitterColor = GlitterSpecular(N, L, V, i);
    
    float3 specularColor = saturate(max(rimColor, oceanColor));
    // float3 color = diffuseColor + specularColor + glitterColor;
    float3 color = diffuseColor + specularColor;

    return color;
}

float3 RipplesNormal(float3 N, Input i)
{
    float3 Up = float3(0, 1, 0);
    // float3 Z = float3(0, 0, 1);

    float steepness = saturate(dot(N, Up));
    steepness = pow(steepness, _RipplesSteepnessPower);

    float2 uv = i.TerrainUV * _RipplesSize;
    float3 shallow = UnpackNormal(tex2D(i.SandShallowTexture, uv));
    float3 steep = UnpackNormal(tex2D(i.SandSteepTexture, uv));
    
    float3 S = nlerp(
        N,
        nlerp(steep, shallow, steepness),
        _RippleStrength
    );

    // _RipplesSize
    // _RippleStrength

    return S;
}

float3 SandNormal(float3 N, Input i)
{
    // -1 to 1
    float3 random = float3(
        snoise(i.WorldPos * _GrainSize + float3(1349, 6391, 2465)),
        snoise(i.WorldPos * _GrainSize + float3(7827, 2945, 5698)),
        snoise(i.WorldPos * _GrainSize + float3(5282, 4216, 3212))
    );

    float3 S = normalize(random);

    float3 Ns = nlerp(N, S, _GrainStrength);
    
    return Ns;
}

void GetSandShader_float(
    float2 TerrainUV,
    float3 WorldPos,
    float3 SurfaceNormal,
    float3 ViewDir,
    UnityTexture2D SandShallowTexture,
    UnityTexture2D SandSteepTexture,
    out float3 Color,
    out float3 Normal
)
{
#if SHADERGRAPH_PREVIEW
    Color = 1;
    Normal = float3(0,0,1);
    return;
#endif

    Input i;
    i.TerrainUV = TerrainUV;
    i.WorldPos = WorldPos;
    i.SurfaceNormal = SurfaceNormal;
    i.ViewDir = ViewDir;
    i.SandShallowTexture = SandShallowTexture;
    i.SandSteepTexture = SandSteepTexture;

    Color = LightingJourney(i);
    
    float3 N = float3(0, 0, 1);
    N = RipplesNormal(N, i);
    N = SandNormal(N, i);
    Normal = N;
}

#endif
