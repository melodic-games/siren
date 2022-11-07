// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#ifndef SAND_TERRAIN_INCLUDE
#define SAND_TERRAIN_INCLUDE

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "Snoise.cginc"
#include "AutoLight.cginc"

struct v2f
{
    // UNITY_FOG_COORDS(1)
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 worldPos : TEXCOORD1;
    float3 normal : TEXCOORD2;
    float4 tangent : TEXCOORD3;
    float3 viewDir : TEXCOORD4;
    // UNITY_SHADOW_COORDS(5)
    SHADOW_COORDS(5)
    // #if defined(SHADOWS_SCREEN)
    // float4 shadowCoordinates : TEXCOORD5;
    // #endif
};

float4 _TerrainColor;
float4 _ShadowColor;

float4 _RimColor;
float _RimStrength;
float _RimPower;

float _GrainSize;
float _GrainStrength;

float4 _OceanSpecularColor;
float _OceanSpecularStrength;
float _OceanSpecularPower;

float _RippleSize;
float _RippleStrength;
float _RippleSteepnessPower;
sampler2D _RippleShallowNormal;
sampler2D _RippleSteepNormal;

v2f vert(appdata_full v)
{
    v2f o;

    UNITY_INITIALIZE_OUTPUT(v2f, o);
    
    o.pos = UnityObjectToClipPos(v.vertex);
    // UNITY_TRANSFER_FOG(o, o.vertex);
    o.uv = v.texcoord.xy;
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    o.normal = v.normal;
    o.tangent = v.tangent;
    o.viewDir = normalize(_WorldSpaceCameraPos - o.worldPos.xyz);

    // UNITY_TRANSFER_SHADOW(o, o.uv.xy);

// #if defined(SHADOWS_SCREEN)
//     o.shadowCoordinates = i.position;
// #endif
    TRANSFER_SHADOW(o);
    // #if defined(SHADOWS_SCREEN)
    // o.shadowCoordinates = ComputeScreenPos(o.pos);
    // #endif
    //
    // UNITY_TRANSFER_SHADOW(o, o.uv.xy);
    // SHADOW_COORDS(5)
    
    return o;
}

// thank you so much to these wonderful articles
// https://www.alanzucconi.com/2019/10/08/journey-sand-shader-1/

float3 nlerp(float3 n1, float3 n2, float t)
{
    return normalize(lerp(n1, n2, t));
}

float3 DiffuseColor(float3 N, float3 L, float attenuation)
{
    N.y *= 0.3;
    //float NdotL = saturate(4 * dot(N, L));
    float NdotL = saturate(4 * dot(N, L));
    
    float3 color = lerp(_ShadowColor, _TerrainColor, NdotL * attenuation);
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

float3 LightingJourney(v2f i, float3 N)
{
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
    
    //float3 L = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
    float3 L = normalize(_WorldSpaceLightPos0.xyz);
    // float3 N = i.normal;
    float3 V = i.viewDir;

    float3 diffuseColor = DiffuseColor(N, L, attenuation);
    float3 rimColor = RimLighting(N, V);
    float3 oceanColor = OceanSpecular(N, L, V);
    // float3 glitterColor = GlitterSpecular(N, L, V, i);

    float3 specularColor = saturate(max(rimColor, oceanColor));
    float3 color = diffuseColor + specularColor; // + glitterColor

    return color;
}

float3 RipplesNormal(float3 N, v2f i)
{
    // float3 Up = float3(0, 1, 0);
    float3 Z = float3(0, 0, 1);

    float steepness = saturate(dot(N, Z));
    steepness = pow(steepness, _RippleSteepnessPower);

    float2 uv = i.uv * _RippleSize;

    float3 shallow = UnpackNormal(tex2D(_RippleShallowNormal, uv));
    float3 steep = UnpackNormal(tex2D(_RippleSteepNormal, uv));

    float3 ripplesTangent = nlerp(steep, shallow, steepness);

    // convert tangent to world normal
    half3 ripplesNormal;
    half3 wNormal = UnityObjectToWorldNormal(i.normal);
    half3 wTangent = UnityObjectToWorldDir(i.tangent.xyz);
    half tangentSign = i.tangent.w * unity_WorldTransformParams.w;
    half3 wBitangent = cross(wNormal, wTangent) * tangentSign;
    half3 tspace0 = half3(wTangent.x, wBitangent.x, wNormal.x);
    half3 tspace1 = half3(wTangent.y, wBitangent.y, wNormal.y);
    half3 tspace2 = half3(wTangent.z, wBitangent.z, wNormal.z);
    ripplesNormal.x = dot(tspace0, ripplesTangent);
    ripplesNormal.y = dot(tspace1, ripplesTangent);
    ripplesNormal.z = dot(tspace2, ripplesTangent);

    return nlerp(
        N,
        ripplesNormal,
        _RippleStrength
    );
}

float3 SandNormal(float3 N, float3 worldPos)
{
    // -1 to 1
    float3 random = float3(
        snoise(worldPos * _GrainSize + float3(1349, 6391, 2465)),
        snoise(worldPos * _GrainSize + float3(7827, 2945, 5698)),
        snoise(worldPos * _GrainSize + float3(5282, 4216, 3212))
    );

    float3 S = normalize(random);

    float3 Ns = nlerp(N, S, _GrainStrength);

    return Ns;
}

fixed4 frag(v2f i) : SV_Target
{    
    float3 N = i.normal;    
    N = RipplesNormal(N, i);
    N = SandNormal(N, i.worldPos);
    
    fixed4 color = fixed4(LightingJourney(i, N), 1);
    
    
    UNITY_APPLY_FOG(i.fogCoord, color);
    return color;
}

// shadow caster

struct ShadowVertexData {
    float4 position : POSITION;
    float3 normal : NORMAL;
};

half4 shadowFrag() : SV_TARGET {
    return 0;
}

float4 shadowVert(ShadowVertexData v) : SV_POSITION {
    float4 position = UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);
    return UnityApplyLinearShadowBias(position);
}


#endif