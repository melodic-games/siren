Shader "Siren/Sand Terrain"
{
    Properties
    {
        [Header(Color)]
        [Space(5)]
        _TerrainColor ("Terrain", Color) = (1, 0, 0, 1)
        _ShadowColor ("Shadow", Color) = (1, 0, 0, 1)

        [Header(Rim)]
        [Space(5)]
        _RimColor ("Color", Color) = (1, 0.43921568989753725, 0.10980392247438431, 1)
        _RimStrength ("Strength", float) = 1
        _RimPower ("Power", float) = 8

        [Header(Ocean Specular)]
        [Space(5)]
        _OceanSpecularColor ("Color", Color) = (1.0, 0.7411764860153198, 0.5803921818733215, 1)
        _OceanSpecularStrength ("Threshold", float) = 0.5
        _OceanSpecularPower ("Power", float) = 64

        [Header(Grain)]
        [Space(5)]
        _GrainSize ("Size", float) = 16
        _GrainStrength ("Strength", float) = 0.1

        [Header(Ripple)]
        [Space(5)]
        _RippleSize ("Size", float) = 50
        _RippleStrength ("Strength", float) = 0.2
        _RippleSteepnessPower ("Steepness Power", float) = 1
        _RippleShallowNormal ("Shallow Normal", 2D) = "bump" {}
        _RippleSteepNormal ("Steep Normal", 2D) = "bump" {}
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "Snoise.cginc"

            struct v2f
            {
                // UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float4 tangent : TEXCOORD3;
                float3 viewDir : TEXCOORD4;
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
                o.vertex = UnityObjectToClipPos(v.vertex);
                // UNITY_TRANSFER_FOG(o, o.vertex);
                o.uv = v.texcoord.xy;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.normal = v.normal;
                o.tangent = v.tangent;
                o.viewDir = normalize(_WorldSpaceCameraPos - o.worldPos.xyz);
                return o;
            }

            // thank you so much to these wonderful articles
            // https://www.alanzucconi.com/2019/10/08/journey-sand-shader-1/

            float3 nlerp(float3 n1, float3 n2, float t)
            {
                return normalize(lerp(n1, n2, t));
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

            float3 LightingJourney(v2f i, float3 N)
            {
                float3 L = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                // float3 N = i.normal;
                float3 V = i.viewDir;

                float3 diffuseColor = DiffuseColor(N, L);
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

                UNITY_APPLY_FOG(i.fogCoord, col);
                return color;
            }
            ENDCG
        }
    }
}