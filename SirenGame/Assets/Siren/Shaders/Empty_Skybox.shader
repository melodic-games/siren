Shader "Siren/Skybox"
{
    Properties {
        _UpperColor("Upper Color", Color) = (.25, .5, .5, 1)
        _LowerColor("Lower Color", Color) = (.5, .5, .5, 1)
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Background"
            "RenderType" = "Background"
            "PreviewType" = "Skybox"
        }

        Cull Off
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
            float4 _UpperColor;
            float4 _LowerColor;
            
            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 dir : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.dir = normalize(mul((float3x3)unity_ObjectToWorld, v.vertex.xyz));
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float t = dot(i.dir.y,float3(0,1,0));
                float3 col = lerp(_LowerColor,_UpperColor,t);

                float3 power = pow(col, 2.2);
                
                return float4(col, 1.0);
            }
            ENDCG
        }
    }
}