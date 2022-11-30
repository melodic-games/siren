// Made with Amplify Shader Editor v1.9.0.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Maki/Water"
{
	Properties
	{
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" }
		Cull Back
		GrabPass{ }
		CGPROGRAM
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#pragma target 3.0
		#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
		#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex);
		#else
		#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex)
		#endif
		#include "Assets/Siren/Shaders/Snoise.cginc"
		#pragma surface surf StandardCustomLighting alpha:fade keepalpha noshadow 
		struct Input
		{
			float3 worldPos;
			float4 screenPos;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		ASE_DECLARE_SCREENSPACE_TEXTURE( _GrabTexture )


		inline float snoise_external43( float4 In )
		{
			return snoise(In);
		}


		inline float4 ASE_ComputeGrabScreenPos( float4 pos )
		{
			#if UNITY_UV_STARTS_AT_TOP
			float scale = -1.0;
			#else
			float scale = 1.0;
			#endif
			float4 o = pos;
			o.y = pos.w * 0.5f;
			o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
			return o;
		}


		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			float3 ase_worldPos = i.worldPos;
			float mulTime42 = _Time.y * 0.2;
			float4 appendResult44 = (float4(( ase_worldPos * 0.5 ) , mulTime42));
			float4 In43 = appendResult44;
			float localsnoise_external43 = snoise_external43( In43 );
			float smoothstepResult82 = smoothstep( 0.0 , 1E-05 , localsnoise_external43);
			float smoothstepResult83 = smoothstep( 0.1 , ( 0.1 + 1E-05 ) , localsnoise_external43);
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( ase_screenPos );
			float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
			float4 screenColor32 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture,( ( localsnoise_external43 * 0.02 ) + ase_grabScreenPosNorm ).xy);
			float4 color91 = IsGammaSpace() ? float4(1,1,1,0.1019608) : float4(1,1,1,0.1019608);
			c.rgb = ( ( ( smoothstepResult82 - smoothstepResult83 ) * 0.5 ) + screenColor32 + ( color91 * color91.a ) ).rgb;
			c.a = 1;
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
		}

		ENDCG
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19002
480;911;1633;488;366.9324;228.7121;1.079613;True;False
Node;AmplifyShaderEditor.RangedFloatNode;46;-311.5184,335.1529;Inherit;False;Constant;_Scale;Scale;0;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;40;-328.9487,155.2022;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleTimeNode;42;-317.9487,433.2019;Inherit;False;1;0;FLOAT;0.2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;45;-113.5185,234.1532;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;85;197.0195,-79.08655;Inherit;False;Constant;_smol;smol;2;0;Create;True;0;0;0;False;0;False;1E-05;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;87;55.01953,46.91345;Inherit;False;Constant;_RippleWidth;Ripple Width;2;0;Create;True;0;0;0;False;0;False;0.1;0;0;0.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;44;47.05103,335.202;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;47;501.2065,286.0137;Inherit;False;Constant;_Intensity;Intensity;0;0;Create;True;0;0;0;False;0;False;0.02;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;43;219.299,336.994;Inherit;False;snoise(In);1;Create;1;True;In;FLOAT4;0,0,0,0;In;;Inherit;False;snoise_external;True;False;0;;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;86;418.0195,13.91345;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GrabScreenPosition;35;514.0286,441.6012;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;677.1761,339.9626;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.01;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;82;599.0195,-65.08655;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1E-05;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;83;603.0195,54.91345;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.1;False;2;FLOAT;0.10001;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;90;755.0503,175.1411;Inherit;False;Constant;_RippleOpacity;Ripple Opacity;2;0;Create;True;0;0;0;False;0;False;0.5;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;91;948.0503,603.1411;Inherit;False;Constant;_Color0;Color 0;2;0;Create;True;0;0;0;False;0;False;1,1,1,0.1019608;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;38;859.0599,381.3468;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;84;803.0195,2.913452;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;32;1040.746,360.797;Inherit;False;Global;_GrabScreen0;Grab Screen 0;1;0;Create;True;0;0;0;False;0;False;Object;-1;False;False;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;92;1235.05,525.1411;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;63;-331.3966,-926.53;Inherit;False;646;407;Half direction;4;67;66;65;64;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;89;1089.05,96.14114;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;88;1459.05,329.1411;Inherit;False;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;79;1209.674,-602.4045;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;66;-8.396605,-776.5301;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldNormalVector;77;147.5135,-1089.229;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalizeNode;67;139.6035,-780.5301;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;72;588.6035,-864.5301;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;64;-246.3966,-876.53;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;68;428.6035,-887.53;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;69;499.2623,-765.5301;Inherit;False;Property;_OceanSpecularPower;Ocean Specular Power;0;0;Create;True;0;0;0;False;0;False;64;64;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;71;945.6035,-767.5301;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;65;-281.3966,-702.5301;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;73;573.6035,-669.5301;Inherit;False;Property;_OceanSpecularStrength;Ocean Specular Strength;1;0;Create;True;0;0;0;False;0;False;0.5;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;70;762.6035,-838.5301;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1746.391,36.59945;Float;False;True;-1;2;ASEMaterialInspector;0;0;CustomLighting;Maki/Water;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Transparent;0.5;True;False;0;False;Transparent;;Transparent;All;18;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;False;2;5;False;;10;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;1;Include;;True;5b3053a266504e9e9de4870a5e515f88;Custom;0;0;False;0.1;False;;0;False;;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;45;0;40;0
WireConnection;45;1;46;0
WireConnection;44;0;45;0
WireConnection;44;3;42;0
WireConnection;43;0;44;0
WireConnection;86;0;87;0
WireConnection;86;1;85;0
WireConnection;41;0;43;0
WireConnection;41;1;47;0
WireConnection;82;0;43;0
WireConnection;82;2;85;0
WireConnection;83;0;43;0
WireConnection;83;1;87;0
WireConnection;83;2;86;0
WireConnection;38;0;41;0
WireConnection;38;1;35;0
WireConnection;84;0;82;0
WireConnection;84;1;83;0
WireConnection;32;0;38;0
WireConnection;92;0;91;0
WireConnection;92;1;91;4
WireConnection;89;0;84;0
WireConnection;89;1;90;0
WireConnection;88;0;89;0
WireConnection;88;1;32;0
WireConnection;88;2;92;0
WireConnection;79;0;71;0
WireConnection;66;0;64;0
WireConnection;66;1;65;0
WireConnection;67;0;66;0
WireConnection;72;0;68;0
WireConnection;68;0;77;0
WireConnection;68;1;67;0
WireConnection;71;0;70;0
WireConnection;71;1;73;0
WireConnection;70;0;72;0
WireConnection;70;1;69;0
WireConnection;0;13;88;0
ASEEND*/
//CHKSM=AB8845F64C08BD654F95780C0A559F8B918F038B