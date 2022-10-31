Shader "Siren/Sand Terrain"
{
    Properties
    {
        [Header(Color)]
        _TerrainColor ("Terrain", Color) = (1, 0, 0, 1)
        _ShadowColor ("Shadow", Color) = (1, 0, 0, 1)

        [Header(Rim)]
        _RimColor ("Color", Color) = (1, 0.43921568989753725, 0.10980392247438431, 1)
        _RimStrength ("Strength", float) = 1
        _RimPower ("Power", float) = 10

        [Header(Grain)]
        _GrainSize ("Size", float) = 8
        _GrainStrength ("Strength", float) = 0.15

        [Header(Ocean Specular)]
        _OceanSpecularColor ("Color", Color) = (1.0, 0.7411764860153198, 0.5803921818733215, 1)
        _OceanSpecularStrength ("Threshold", float) = 0.2
        _OceanSpecularPower ("Power", float) = 128

        [Header(Ripple)]
        _RippleSize ("Size", float) = 50
        _RippleStrength ("Strength", float) = 1
        _RippleSteepnessPower ("Steepness Power", float) = 1
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct v2f
            {
                // float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
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

            v2f vert(appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                // o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.normal = v.normal;
                o.viewDir = normalize(_WorldSpaceCameraPos - o.worldPos.xyz);
                return o;
            }

            // thank you so much to these wonderful articles
            // https://www.alanzucconi.com/2019/10/08/journey-sand-shader-1/
            
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

            float3 LightingJourney(v2f i)
            {
                float3 L = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                float3 N = i.normal;
                float3 V = i.viewDir;

                float3 diffuseColor = DiffuseColor(N, L);
                float3 rimColor = RimLighting(N, V);
                float3 oceanColor = OceanSpecular(N, L, V);
                
                float3 specularColor = saturate(max(rimColor, oceanColor));
                float3 color = diffuseColor + specularColor;

                return color;
            }

            fixed OrenNayarDiffuse( fixed3 light, fixed3 view, fixed3 norm, fixed roughness )
			{
			    half VdotN = dot( view , norm );


			    half LdotN = saturate( 4 * dot( light, norm * float3( 1 , 0.5 , 1 ) )); // the function is modifed here 
			    																		// the original one is LdotN = saturate( dot ( light , norm ))

			    half cos_theta_i = LdotN;
			    half theta_r = acos( VdotN );
			    half theta_i = acos( cos_theta_i );
			    half cos_phi_diff = dot( normalize( view - norm * VdotN ),
			                             normalize( light - norm * LdotN ) );
			    half alpha = max( theta_i, theta_r ) ;
			    half beta = min( theta_i, theta_r ) ;
			    half sigma2 = roughness * roughness;
			    half A = 1.0 - 0.5 * sigma2 / (sigma2 + 0.33);
			    half B = 0.45 * sigma2 / (sigma2 + 0.09);
			    
			    return saturate( cos_theta_i ) *
			        (A + (B * saturate( cos_phi_diff ) * sin(alpha) * tan(beta)));
			}

            float3 nlerp(float3 n1, float3 n2, float t)
            {
                return normalize(lerp(n1, n2, t));
            }

            #include "Snoise.cginc"
            
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
                        
            #include "Lighting.cginc"

            fixed4 frag(v2f i) : SV_Target
            {
                float3 normal = SandNormal(i.normal, i.worldPos);
                
                fixed4 color = fixed4(
                    LightingJourney(i) *
                    OrenNayarDiffuse(
                        normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz),
                        i.viewDir,
                        normal,
                        1
                    ),
                    0.5
                );


                
                

                UNITY_APPLY_FOG(i.fogCoord, col);
                return color;
            }
            ENDCG
        }
    }
}