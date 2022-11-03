Shader "Siren/Sand Terrain"
{
    Properties
    {
        [Header(Color)]
        [Space(5)]
        _TerrainColor ("Terrain", Color) = (1, 0, 0, 1)
        _ShadowColor ("Shadow", Color) = (0.7, 0, 0, 1)

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
            "RenderType" = "Opaque"
        }
        
        Cull Back
        // LOD 100

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            
            CGPROGRAM

            #pragma target 5.0
            // #define FORWARD_BASE_PASS
            
            #pragma vertex vert
            #pragma fragment frag
            // #pragma multi_compile_fwdbase
            // #pragma multi_compile_fog

            #pragma multi_compile _ SHADOWS_SCREEN
            // #pragma multi_compile_fwdbase_fullshadows

            #include "Sand Terrain.cginc"
            
            ENDCG
        }
        
        Pass {
			Tags { "LightMode" = "ShadowCaster" }

			CGPROGRAM

			#pragma target 5.0

			#pragma vertex shadowVert
			#pragma fragment shadowFrag

			#include "Sand Terrain.cginc"

			ENDCG
		}
    }
}